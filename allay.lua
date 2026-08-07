-- Allay (MC 1.19) — imported from Bettercraft (GPLv3) with a movement
-- rewrite: Bettercraft used Mineclonia-only motion_step/run_ai hooks;
-- both games call do_custom (and return false skips the framework's own
-- step logic — VoxeLibre mcl_mobs/api.lua:403, Mineclonia api.lua:705),
-- so a single do_custom with the smooth-velocity movement works on both.
--
-- Behavior (MC parity): give it an item — it flies off to collect
-- matching dropped items within 32 nodes and returns them to you.
-- No natural spawn (MC: pillager outposts/woodland mansions only — not
-- expressible in either spawn system): creative egg only.

local S = minetest.get_translator("mcl_mobs_addon")

-- forward declarations (the def table's closures below reference them;
-- they are NOT def fields — VoxeLibre's register_mob whitelist drops
-- unknown fields)
local allay_drop_items
local allay_motion

local allay = {
	description = S("Allay"),
	type = "animal",
	spawn_class = "passive",
	passive = true,
	glow = 5,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		collisionbox = { -0.2, -0.2, -0.2, 0.2, 0.6, 0.2 },
	},
	visual = "mesh",
	mesh = "mcl_mobs_addon_allay.b3d",
	textures = { { "mcl_mobs_addon_allay.png" } },
	visual_size = { x = 1, y = 1 },
	fly = true,
	fall_damage = 0,
	pushable = false,
	makes_footstep_sound = false,
	gravity_drag = 0,
	_apply_gravity_drag_on_ground = false,
	movement_speed = 3.0,
	view_range = 16,
	lifetimer = -1,
	static_save = true,
	despawn = false,

	-- persistence for the delivered/given item state
	on_activate = function(self, staticdata, dtime_s)
		if staticdata and staticdata ~= "" then
			local data = minetest.deserialize(staticdata)
			if data then
				self._given_item = data._given_item
				self._given_stack = data._given_stack
				self._picked_up_item = data._picked_up_item
				self._player = data._player
			end
		end
	end,

	get_staticdata = function(self)
		return minetest.serialize({
			_given_item = self._given_item,
			_given_stack = self._given_stack,
			_picked_up_item = self._picked_up_item,
			_player = self._player,
		})
	end,

	-- give an item (or collect the delivered one back)
	on_rightclick = function(self, clicker)
		local wi = clicker:get_wielded_item()
		if not self._given_item and not wi:is_empty() then
			self._player = clicker:get_player_name()
			self._given_item = wi:get_name()
			self._given_stack = wi:to_string()
			if not minetest.settings:get_bool("creative_mode") then
				wi:take_item()
				clicker:set_wielded_item(wi)
			end
			return
		end
		allay_drop_items(self)
	end,

	on_die = function(self, pos)
		allay_drop_items(self)
	end,
}

-- local (NOT a def field — VoxeLibre's whitelist drops unknown fields)
allay_drop_items = function(self, only_picked_up)
	local pos = self.object:get_pos()
	if not pos then return end
	if self._picked_up_item then
		local item_obj = minetest.add_item(pos, self._picked_up_item)
		if item_obj then
			item_obj:set_velocity({ x = math.random(-1, 1), y = 2, z = math.random(-1, 1) })
		end
		self._picked_up_item = nil
	end
	if not only_picked_up and self._given_stack then
		minetest.add_item(pos, self._given_stack)
		self._given_stack = nil
		self._given_item = nil
		self._player = nil
	end
end

-- Movement: a LOCAL function captured by the hook closures. It must NOT be
-- a def field — VoxeLibre's register_mob builds a whitelisted final_def and
-- drops unknown fields. Mineclonia calls motion_step/run_ai (native hooks);
-- VoxeLibre calls do_custom (returning false skips the framework's own
-- step logic — mcl_mobs/api.lua:403).
allay_motion = function(self, dtime)
	local self_pos = self.object:get_pos()
	if not self_pos then return end

		local target_pos = nil
		local player = self._player and minetest.get_player_by_name(self._player)
		local found_item = false

		-- look for the requested item on the ground (priority)
		if self._given_item then
			for _, o in ipairs(minetest.get_objects_inside_radius(self_pos, 32)) do
				local entity = o:get_luaentity()
				if entity and entity.name == "__builtin:item" then
					local itemstack = ItemStack(entity.itemstring)
					if itemstack:get_name() == self._given_item then
						local opos = o:get_pos()
						found_item = true
						if vector.distance(self_pos, opos) < 1.5 then
							self._picked_up_item = entity.itemstring
							o:remove()
						else
							target_pos = opos
						end
						break
					end
				end
			end
		end

		-- follow the player unless an item was found
		if player and not found_item then
			local ppos = player:get_pos()
			ppos.y = ppos.y + 1.2
			local dist = vector.distance(self_pos, ppos)
			if dist > 40 then
				self.object:set_pos(vector.offset(ppos, math.random(-1, 1), 0, math.random(-1, 1)))
				return false
			end
			if self._picked_up_item then
				if dist > 2.0 then target_pos = ppos end
			elseif self._given_item then
				if dist > 4.0 then target_pos = ppos end
			end
		end

		-- wander
		if not target_pos then
			if not self._wander_pos
					or vector.distance(self_pos, self._wander_pos) < 1.5
					or math.random(100) == 1 then
				local base_pos = player and player:get_pos() or self_pos
				self._wander_pos = vector.offset(base_pos,
					math.random(-6, 6), math.random(1, 3), math.random(-6, 6))
				local node_at_pos = minetest.get_node_or_nil(self._wander_pos)
				if node_at_pos and minetest.registered_nodes[node_at_pos.name]
						and minetest.registered_nodes[node_at_pos.name].walkable then
					self._wander_pos = nil
				end
			end
			target_pos = self._wander_pos
		end

		-- smooth velocity interpolation
		if target_pos then
			local dir = vector.direction(self_pos, target_pos)
			local target_vel = vector.multiply(dir, 3.5)
			local current_vel = self.object:get_velocity()
			local smooth = 0.1
			self.object:set_velocity({
				x = current_vel.x + (target_vel.x - current_vel.x) * smooth,
				y = current_vel.y + (target_vel.y - current_vel.y) * smooth,
				z = current_vel.z + (target_vel.z - current_vel.z) * smooth,
			})
			local vlen = vector.length(self.object:get_velocity())
			if vlen > 0.1 then
				self:set_yaw(math.atan2(self.object:get_velocity().z, self.object:get_velocity().x) - math.pi / 2)
			end
		else
			self.object:set_velocity(vector.multiply(self.object:get_velocity(), 0.9))
		end
end

-- Movement hook wiring: Mineclonia -> motion_step/run_ai (native hooks);
-- VoxeLibre -> do_custom (false = skip the framework's own step logic).
if mcl_mobs.register_spawner then
	allay.motion_step = function(self, dtime)
		allay_motion(self, dtime)
	end
	allay.run_ai = function() end
else
	allay.do_custom = function(self, dtime)
		allay_motion(self, dtime)
		return false
	end
end

mcl_mobs.register_mob("mcl_mobs_addon:allay", allay)
mcl_mobs_addon.register_egg("mcl_mobs_addon:allay", S("Allay"), "#8cbfe0", "#ffffff", 0)

if mcl_mobs.register_spawner then
	local def = mcl_mobs.registered_mobs["mcl_mobs_addon:allay"]
	if def then
		def.hp_min = 20
		def.hp_max = 20
	end
end

minetest.log("action", "[mcl_mobs_addon] allay registered (delivery AI, both games)")
