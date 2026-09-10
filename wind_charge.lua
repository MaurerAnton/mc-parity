-- ---------------------------------------------------------------------------
-- WIND CHARGE (MC 1.21) — the throwable projectile + wind burst.
-- The item used to be a dead craftitem (registered in mobs_trial.lua);
-- this module gives it MC behavior: right-click to throw, fly straight,
-- burst on impact — knockback + 1 damage in a 3-block radius, extinguish
-- lit candles/candle cakes (the _on_wind_charge_hit hooks ported in
-- port_items.lua), shatter decorated pots, ring bells. Aiming down gives
-- the thrower the classic wind-charge jump (knockback includes them).
--
-- Entity model + entity/burst textures ported from Mineclonia
-- (mcl_charges, GPLv3 / CC BY-SA 4.0 media — see README provenance).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

local THROW_SPEED = 30
local COOLDOWN_S = 0.5
local LIFETIME_S = 3
local BURST_RADIUS = 3
local ENTITY = "mc_parity:wind_charge_flying"

local cooldowns = {}

-- burst: knockback everything in range, 1 damage to non-throwers
local function wind_burst(pos, shooter_name)
	if not (mcl_util and mcl_util.deal_damage) then return end
	for obj in minetest.objects_inside_radius(pos, BURST_RADIUS) do
		local opos = obj:get_pos()
		if opos then
			local dist = math.max(1, vector.distance(pos, opos))
			local dir = vector.normalize(vector.subtract(opos, pos))
			if obj:is_player() then
				-- MC: players get a velocity push (thrower included)
				obj:add_velocity(vector.multiply(dir,
					2.2 / dist * BURST_RADIUS))
				if obj:get_player_name() ~= shooter_name then
					mcl_util.deal_damage(obj, 1, { type = "wind_charge" })
				end
			else
				local le = obj:get_luaentity()
				if le and (le.is_mob or le.name == "__builtin:item") then
					local vel = vector.multiply(dir, 8 / dist)
					vel.y = vel.y + 2  -- gust lifts entities (MC)
					obj:set_velocity(vector.add(obj:get_velocity(), vel))
					if le.is_mob then
						mcl_util.deal_damage(obj, 1, { type = "wind_charge" })
					end
				end
			end
		end
	end
end

local function burst_at(pos)
	minetest.sound_play("tnt_explode",
		{ pos = pos, gain = 0.5, max_hear_distance = 30, pitch = 2.5 }, true)
	minetest.add_particlespawner({
		amount = 24,
		time = 0.35,
		minpos = vector.offset(pos, -0.8, 0.2, -0.8),
		maxpos = vector.offset(pos, 0.8, 1.0, 0.8),
		minvel = { x = -2, y = -1, z = -2 },
		maxvel = { x = 2, y = 2, z = 2 },
		minacc = { x = 0, y = -6, z = 0 },
		maxacc = { x = 0, y = -6, z = 0 },
		minexptime = 0.4,
		maxexptime = 1.0,
		minsize = 0.5,
		maxsize = 1.5,
		texture = "mc_parity_wind_burst_1.png",
	})
end

minetest.register_entity(ENTITY, {
	initial_properties = {
		visual = "mesh",
		mesh = "mc_parity_wind_charge.obj",
		visual_size = { x = 2, y = 1.5 },
		textures = { "mc_parity_wind_charge_entity.png" },
		hp_max = 20,
		collisionbox = { -0.1, -0.1, -0.1, 0.1, 0.0, 0.1 },
		physical = true,
		collide_with_objects = true,
		pointable = false,
	},
	_shooter_name = nil,
	_t = 0,

	on_activate = function(self, staticdata, dtime_s)
		self.object:set_armor_groups({ immortal = 1 })
		self._t = dtime_s or 0
	end,

	on_step = function(self, dtime)
		self._t = (self._t or 0) + dtime
		if self._t > LIFETIME_S then
			self.object:remove()
			return
		end
		local pos = self.object:get_pos()
		if not pos then return end

		-- node impact
		local node = minetest.get_node(pos)
		if node.name ~= "air" and node.name ~= "ignore" then
			local dpos = vector.round(pos)
			if node.name == "mc_parity:decorated_pot" then
				minetest.dig_node(dpos)  -- MC: the pot shatters
			end
			local bdef = minetest.registered_nodes[node.name]
			if bdef and bdef._on_wind_charge_hit then
				bdef._on_wind_charge_hit(dpos, self)
			end
			if minetest.get_item_group(node.name, "bell") >= 1
					and mcl_bells and mcl_bells.ring_once then
				mcl_bells.ring_once(dpos)
			end
			wind_burst(pos, self._shooter_name)
			burst_at(pos)
			self.object:remove()
			return
		end

		-- entity impact (players + mobs; charges pass through each other)
		for obj in minetest.objects_inside_radius(pos, 0.6) do
			local le = obj:get_luaentity()
			if le ~= self then
				local hit = obj:is_player()
					or (le and le.is_mob)
				if hit then
					wind_burst(pos, self._shooter_name)
					burst_at(pos)
					self.object:remove()
					return
				end
			end
		end
	end,
})

local function throw_charge(itemstack, placer)
	if not (placer and placer:is_player()) then return itemstack end
	local name = placer:get_player_name()
	local now = minetest.get_gametime()
	if (cooldowns[name] or -COOLDOWN_S) + COOLDOWN_S > now then
		return itemstack
	end
	local dir = placer:get_look_dir()
	local ppos = placer:get_pos()
	if not (dir and ppos) then return itemstack end
	cooldowns[name] = now
	local obj = minetest.add_entity(
		{ x = ppos.x + dir.x, y = ppos.y + 1.3 + dir.y, z = ppos.z + dir.z },
		ENTITY)
	if obj then
		obj:set_velocity(vector.multiply(dir, THROW_SPEED))
		obj:set_acceleration({ x = 0, y = 0, z = 0 })
		local le = obj:get_luaentity()
		if le then le._shooter_name = name end
	end
	if not minetest.is_creative_enabled(name) then
		itemstack:take_item()
	end
	return itemstack
end

minetest.register_craftitem("mc_parity:wind_charge", {
	description = S("Wind Charge"),
	inventory_image = "mc_parity_wind_charge.png",
	groups = { craftitem = 1 },
	-- right-click a node (on_place) or the air (on_secondary_use)
	on_place = function(itemstack, placer, pointed_thing)
		return throw_charge(itemstack, placer)
	end,
	on_secondary_use = function(itemstack, placer, pointed_thing)
		return throw_charge(itemstack, placer)
	end,
})

-- MC 1.21: 1 breeze rod -> 4 wind charges (breeze rods also drop from the
-- breeze itself, mobs_121.lua — trial loot is not the only source)
if minetest.registered_items["mc_parity:breeze_rod"] then
	minetest.register_craft({
		type = "shapeless",
		output = "mc_parity:wind_charge 4",
		recipe = { "mc_parity:breeze_rod" },
	})
end

minetest.log("action", "[mc_parity] wind charge registered (throwable)")
