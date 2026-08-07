-- Imported mobs from Bettercraft (wrxxnch/luanti-bettercraft, GPLv3 +
-- free media — LEGAL.md verified): frog, turtle, phantom, sniffer.
--
-- Adaptations:
--   * mcl_mobs_addon: prefix + mcl_mobs_addon_ media prefix
--   * hp in initial_properties (VoxeLibre) + base patch for Mineclonia
--   * Mineclonia-only mob_class methods (feed_tame, go_home) feature-detected
--   * natural spawns only where BOTH games' spawn systems can express the
--     MC conditions (phantom = night-only and sniffer = rare ruins: egg-only
--     for now, TODO) — the spawn systems have no time-of-day filter
--
-- NOT imported yet: allay (uses Mineclonia-only motion_step/run_ai hooks —
-- needs a VoxeLibre-compatible movement rewrite; TODO).

local S = minetest.get_translator("mcl_mobs_addon")

-- hatchling registry: egg_pos -> baby turtle (see the turtle egg on_timer)
mcl_mobs_addon = rawget(_G, "mcl_mobs_addon") or {}
mcl_mobs_addon.turtle_babies = mcl_mobs_addon.turtle_babies or {}

local function mcln_base_hp(name, hp_min, hp_max)
	-- Mineclonia's mob activate reads hp from the def base (math.random(
	-- self.hp_min, ...)); VoxeLibre from initial_properties. See warden.lua.
	if mcl_mobs.register_spawner then
		local def = mcl_mobs.registered_mobs[name]
		if def then
			def.hp_min = hp_min
			def.hp_max = hp_max
		end
	end
end

-- ---------------------------------------------------------------------------
-- FROG  (MC 1.19; eats slimes, drops froglight from magma cubes, biome
-- textures via the game's _mcl_biome_type field)
-- ---------------------------------------------------------------------------
local frog_textures = {
	cold = 1,
	snowy = 1,
	medium = 2,
	hot = 3,
}
local frog_texture_list = {
	{ "mcl_mobs_addon_frog.png" },
	{ "mcl_mobs_addon_frog_temperate.png" },
	{ "mcl_mobs_addon_frog_warm.png" },
}

mcl_mobs.register_mob("mcl_mobs_addon:frog", {
	description = S("Frog"),
	type = "animal",
	spawn_class = "passive",
	passive = true,
	group_attack = true,
	initial_properties = {
		hp_min = 10,
		hp_max = 10,
		collisionbox = { -0.3, 0, -0.3, 0.3, 0.4, 0.3 },
	},
	armor = 100,
	walk_velocity = 1.5,
	run_velocity = 3.0,
	pace_bonus = 0.3,
	jump = true,
	jump_height = 1.5,
	stepheight = 1.1,
	fly = false,
	water_damage = 0,
	lava_damage = 4,
	fall_damage = 0,
	fear_height = 4,
	attack_type = "melee",
	damage = 1,
	reach = 2,
	attack_monsters = true,
	attack_animals = false,
	specific_attack = {
		"mobs_mc:slime_tiny",
		"mobs_mc:magma_cube_tiny",
	},
	visual = "mesh",
	mesh = "mcl_mobs_addon_frog.b3d",
	visual_size = { x = 10, y = 10 },
	texture_list = frog_texture_list,
	textures = { "mcl_mobs_addon_frog_temperate.png" },
	animation = {
		speed_normal = 15,
		stand_start = 1, stand_end = 80,
		walk_start = 90, walk_end = 105,
		jump_start = 90, jump_end = 105,
	},
	on_spawn = function(self)
		local pos = self.object:get_pos()
		if not pos then return end
		local bd = minetest.get_biome_data(pos)
		if not bd then return end
		local bname = minetest.get_biome_name(bd.biome)
		local bdef = minetest.registered_biomes[bname]
		if not bdef then return end
		local idx = frog_textures[bdef._mcl_biome_type] or frog_textures.medium
		self.texture_selected = idx
		self.object:set_properties({ textures = frog_texture_list[idx] })
	end,
	do_custom = function(self, dtime)
		if not self.object then return end
		local pos = self.object:get_pos()
		if not pos then return end

		-- hop forward every 1-3 s
		self._frog_timer = (self._frog_timer or 0) - dtime
		if self._frog_timer <= 0 then
			local vel = self.object:get_velocity()
			if vel and math.abs(vel.y) < 0.1 then
				self._frog_timer = 1 + math.random() * 2
				if self.state == "walk" or self.state == "attack" then
					local yaw = self.object:get_yaw()
					if yaw then
						local dir = { x = -math.sin(yaw), y = 0, z = math.cos(yaw) }
						self.object:set_velocity({ x = dir.x * 3, y = 4, z = dir.z * 3 })
						self:set_animation("walk")
					end
				end
			end
		end

		-- eat tiny slimes / magma cubes; magma cube -> froglight drop
		if self.state == "attack" and self.attack then
			local tpos = self.attack:get_pos()
			if tpos and vector.distance(pos, tpos) <= 1.5 then
				local ent = self.attack:get_luaentity()
				if ent and (ent.name == "mobs_mc:slime_tiny"
						or ent.name == "mobs_mc:magma_cube_tiny") then
					local is_magma = ent.name == "mobs_mc:magma_cube_tiny"
					self.attack:remove()
					self.attack = nil
					self.state = "stand"
					self:set_animation("stand")
					if is_magma then
						local drops = {
							[frog_textures.cold] = "mcl_mobitems:froglight_verdant",
							[frog_textures.medium] = "mcl_mobitems:froglight_pearlescent",
							[frog_textures.hot] = "mcl_mobitems:froglight_ochre",
						}
						local drop = drops[self.texture_selected or frog_textures.medium]
						if drop then
							minetest.add_item(pos, drop)
						end
					end
				end
			end
		end
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:frog", S("Frog"), "#00AA00", "#db635f", 0)
mcl_mobs_addon.register_spawn("mcl_mobs_addon:frog",
	{ "Swampland", "MangroveSwamp" },
	{ "Swampland", "MangroveSwamp" }, 30)
mcln_base_hp("mcl_mobs_addon:frog", 10, 10)

-- ---------------------------------------------------------------------------
-- TURTLE  (MC 1.13; beach walker, seagrass-breedable — egg-laying TODO:
-- Bettercraft's go_home/_has_egg chain needs the nest block)
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mcl_mobs_addon:turtle", {
	description = S("Turtle"),
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	attacks_monsters = true,
	specific_attack = {
		"mobs_mc:slime_small",
		"mobs_mc:magma_cube_small",
	},
	damage = 8,
	initial_properties = {
		hp_min = 10,
		hp_max = 10,
		collisionbox = { -0.6, -0.05, -0.6, 0.6, 0.5, 0.6 },
	},
	xp_min = 1,
	xp_max = 3,
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	visual = "mesh",
	mesh = "mcl_mobs_addon_turtle.b3d",
	visual_size = { x = 1, y = 1 },
	texture_list = { { "mcl_mobs_addon_turtle.png" } },
	textures = { "mcl_mobs_addon_turtle.png" },
	makes_footstep_sound = true,
	view_range = 16,
	stepheight = 1.1,
	jump = false,
	jump_height = 0,
	fear_height = 4,
	swims = true,
	spawn_in_group = 5,
	breath_max = -1,
	follow = { "mcl_ocean:seagrass" },
	sounds = {},
	drops = {},
	walk_velocity = 0.2,
	pace_bonus = 0.3,
	animation = {
		stand_start = 1, stand_end = 20, stand_speed = 10,
		walk_start = 30, walk_end = 85, speed_normal = 10,
		fly_start = 1.45, fly_end = 1.65, fly_speed = 1.5, -- swimming
	},
	on_rightclick = function(self, clicker)
		local it = clicker:get_wielded_item()
		if it:get_name() == "mcl_ocean:seagrass" and self.feed_tame then
			-- feed_tame is Mineclonia mob_class only; VoxeLibre: no breeding
			self:feed_tame(clicker, 4, true, false, true)
			if not minetest.is_creative_enabled(clicker:get_player_name()) then
				it:take_item()
				clicker:set_wielded_item(it)
			end
		end
	end,
	on_breed = function(self, _)
		-- pregnant: walk back to the home beach, then lay eggs on sand
		-- (handled in do_custom — both games)
		self._mca_has_egg = true
		self._mca_home = self.object:get_pos()
		return false
	end,
	on_spawn = function(self)
		-- hatched from an egg? (the egg's on_timer marks the spawn pos in
		-- the registry — VoxeLibre does NOT call def.on_activate for mobs,
		-- so the baby flag must come through on_spawn)
		local p = self.object:get_pos()
		local key = p and minetest.pos_to_string(p)
		if key and mcl_mobs_addon.turtle_babies[key] then
			mcl_mobs_addon.turtle_babies[key] = nil
			self._mca_baby = true
			self.object:set_properties({ visual_size = { x = 0.6, y = 0.6 } })
		end
	end,
	do_custom = function(self, dtime)
		-- baby turtles grow to full size after ~5 minutes; the growth
		-- drops a scute (MC parity — missed in the original port)
		if self._mca_baby then
			self._mca_grow = (self._mca_grow or 300) - dtime
			if self._mca_grow <= 0 then
				self._mca_baby = nil
				self.object:set_properties({ visual_size = { x = 1, y = 1 } })
				minetest.add_item(self.object:get_pos(), "mcl_mobs_addon:scute")
			end
		end
		-- breeding: go home, then lay the egg on a nearby sand block
		if self._mca_has_egg then
			local pos = self.object:get_pos()
			if not pos then return true end
			if vector.distance(pos, self._mca_home) > 4 then
				self:gopath(self._mca_home, 0.5)
				return true
			end
			local sand = minetest.find_nodes_in_area_under_air(
				vector.offset(self._mca_home, -32, -5, -32),
				vector.offset(self._mca_home, 32, 5, 32),
				{ "mcl_core:sand", "mcl_core:red_sand" })
			if sand and #sand > 0 then
				local p = sand[math.random(#sand)]
				if vector.distance(pos, p) > 1.5 then
					self:gopath(p, 0.5)
				else
					local egg_pos = vector.offset(p, 0, 1, 0)
					if minetest.get_node(egg_pos).name == "air" then
						minetest.set_node(egg_pos, { name = "mcl_mobs_addon:turtle_egg" })
						self._mca_has_egg = nil
						self._mca_home = nil
					end
				end
			end
		end
		return true
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:turtle", S("Turtle"), "#516720", "#ded88f", 0)
mcl_mobs_addon.register_spawn("mcl_mobs_addon:turtle",
	{ "StoneBeach" },
	{ "StoneBeach" }, 40)
mcln_base_hp("mcl_mobs_addon:turtle", 10, 10)

-- turtle egg block: laid on sand by breeding turtles, hatches after
-- 2-5 minutes into a baby turtle (MC parity: nests on the home beach)
minetest.register_node("mcl_mobs_addon:turtle_egg", {
	description = S("Turtle Egg"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.22, -0.5, -0.22, 0.22, -0.32, 0.22 },
	},
	selection_box = {
		type = "fixed",
		fixed = { -0.22, -0.5, -0.22, 0.22, -0.32, 0.22 },
	},
	tiles = { "mcl_mobs_addon_turtle_egg.png" },
	paramtype = "light",
	groups = { dig_immediate = 3, deco_block = 1, oddly_breakable_by_hand = 1 },
	sounds = mcl_sounds.node_sound_defaults(),
	_tt_help = S("Hatches into a baby turtle"),
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(120 + math.random(0, 180))
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(120 + math.random(0, 180))
	end,
	on_timer = function(pos)
		minetest.set_node(pos, { name = "air" })
		local baby_pos = vector.offset(pos, 0, 1, 0)
		-- mark the spawn pos as a hatchling (VoxeLibre never calls
		-- def.on_activate for mobs — on_spawn reads this registry)
		mcl_mobs_addon.turtle_babies[minetest.pos_to_string(baby_pos)] = true
		minetest.add_entity(baby_pos, "mcl_mobs_addon:turtle")
		return false
	end,
})

-- turtle scute (MC 1.13; neither game has it — turtles are ours)
minetest.register_craftitem("mcl_mobs_addon:scute", {
	description = S("Scute"),
	inventory_image = "mcl_mobs_addon_scute.png",
	groups = { craftitem = 1 },
	stack_max = 64,
})

-- turtle shell helmet (MC: crafted from 5 scute; grants water breathing)
if mcl_armor and mcl_armor.register_set then
	-- VoxeLibre / Mineclonia armor API: full set, but only the head piece
	-- has armor points (the others are harmless placeholders)
	mcl_armor.register_set({
		name = "turtle",
		description = S("Turtle Shell"),
		points = { head = 2, torso = 0, legs = 0, feet = 0 },
		toughness = 0,
		durability = 275,
		enchantability = 9,
		textures = { head = "mcl_mobs_addon_turtle_helmet.png" },
		groups = { armor = 1, mcl_armor = 1, mcl_armor_turtle = 1 },
	})
	minetest.register_craft({
		output = "mcl_mobs_addon:helmet_turtle",
		recipe = {
			{ "mcl_mobs_addon:scute", "mcl_mobs_addon:scute", "mcl_mobs_addon:scute" },
			{ "mcl_mobs_addon:scute", "", "mcl_mobs_addon:scute" },
		},
	})
	-- water breathing while the shell is worn and the head is underwater
	local HELMET = "mcl_mobs_addon:helmet_turtle"
	local head_index = mcl_armor.elements and mcl_armor.elements.head
		and mcl_armor.elements.head.index or 2
	minetest.register_globalstep(function(dtime)
		for _, player in ipairs(minetest.get_connected_players()) do
			local inv = player:get_inventory()
			local worn = inv and inv:get_stack("armor", head_index)
			if worn and worn:get_name() == HELMET and worn:get_wear() < 65535 then
				local ppos = player:get_pos()
				local head = ppos and vector.offset(ppos, 0, 1.5, 0)
				if head then
					local n = minetest.get_node(head)
					if minetest.get_item_group(n.name, "water") ~= 0 then
						if mcl_potions and mcl_potions.give_effect_by_level then
							mcl_potions.give_effect_by_level("water_breathing", player, 1, 15)
						end
					end
				end
			end
		end
	end)
else
	-- no armor API (unlikely): plain wearable helmet without the effect
	minetest.register_craftitem("mcl_mobs_addon:helmet_turtle", {
		description = S("Turtle Shell"),
		inventory_image = "mcl_mobs_addon_turtle_helmet.png",
		groups = { armor_head = 1, armor = 1 },
	})
	minetest.register_craft({
		output = "mcl_mobs_addon:helmet_turtle",
		recipe = {
			{ "mcl_mobs_addon:scute", "mcl_mobs_addon:scute", "mcl_mobs_addon:scute" },
			{ "mcl_mobs_addon:scute", "", "mcl_mobs_addon:scute" },
		},
	})
end

-- ---------------------------------------------------------------------------
-- PHANTOM  (MC 1.13; circles high above, dives on non-creative players,
-- retreats upward when damaged, burns in daylight — Bettercraft's full AI)
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mcl_mobs_addon:phantom", {
	description = S("Phantom"),
	type = "monster",
	spawn_class = "hostile",
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		collisionbox = { -0.6, -0.3, -0.6, 0.6, 0.3, 0.6 },
	},
	damage = 4,
	reach = 3,
	armor = 10,
	damage_groups = { fleshy = 100 },
	view_range = 64,
	visual = "mesh",
	mesh = "mcl_mobs_addon_phantom.b3d",
	textures = { { "mcl_mobs_addon_phantom.png" } },
	visual_size = { x = 1, y = 1 },
	glow = 6,
	fly = true,
	fly_in = { "air" },
	floats = 1,
	jump = false,
	stepheight = 0,
	pathfinding = false,
	fall_damage = false,
	fear_height = 0,
	walk_velocity = 6,
	pace_bonus = 0.3,
	run_velocity = 8,
	fly_velocity = 8,
	animation = {
		stand_start = 1, stand_end = 160, stand_speed = 20,
		walk_start = 1, walk_end = 160, speed_normal = 20,
		run_start = 1, run_end = 160, speed_run = 25,
	},
	drops = {
		{ name = "mcl_mobitems:phantom_membrane", chance = 2, min = 0, max = 1 },
	},
	on_attack = function(self, hitter)
		if not hitter or not hitter:is_player() then
			return
		end
		self.phantom_state = "retreat"
		self.retreat_timer = 2.0
	end,
	do_custom = function(self, dtime)
		if not self.object or not self.object:get_pos() then
			return
		end
		self.object:set_acceleration({ x = 0, y = 0, z = 0 })
		local pos = self.object:get_pos()

		if not self._last_health then
			self._last_health = self.health
		end
		if self.health < self._last_health then
			self.phantom_state = "retreat"
			self.retreat_timer = 2.0
		end
		self._last_health = self.health

		-- burns in daylight (MC: only attacks sleepless players; burning
		-- approximation: any daylight above light 12)
		local light = minetest.get_node_light(pos) or 0
		local time = minetest.get_timeofday()
		if time > 0.2 and time < 0.8 and light > 12 then
			local node_above = minetest.get_node_or_nil({ x = pos.x, y = pos.y + 1, z = pos.z })
			if node_above and node_above.name == "air" then
				self.object:set_hp(self.object:get_hp() - dtime * 2)
			end
		end

		-- nearest non-creative, non-spectator player within 64
		local target = nil
		local min_dist = 64
		for _, player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local is_creative = minetest.settings:get_bool("creative_mode")
				or minetest.check_player_privs(name, { creative = true })
			local is_spec = mcl_mobs_addon.is_spectator and mcl_mobs_addon.is_spectator(player)
			if not is_creative and not is_spec then
				local ppos = player:get_pos()
				if ppos then
					local dist = vector.distance(pos, ppos)
					if dist < min_dist then
						target = player
						min_dist = dist
					end
				end
			end
		end

		local tpos
		if not target then
			if not self.idle_center then
				self.idle_center = pos
			end
			tpos = self.idle_center
		else
			tpos = target:get_pos()
			self.idle_center = nil
		end

		if not self.phantom_state then
			self.phantom_state = "circle"
			self.circle_angle = 0
		end

		if self.phantom_state == "retreat" then
			self.retreat_timer = (self.retreat_timer or 2) - dtime
			self.object:set_velocity({ x = 0, y = 8, z = 0 })
			if self.retreat_timer <= 0 then
				self.phantom_state = "circle"
			end
			return false
		end

		if self.phantom_state == "circle" then
			self.circle_angle = (self.circle_angle or 0) + dtime * 1.2
			local radius = 18
			local max_height = 20
			local desired_y = tpos.y + max_height
			local offset = {
				x = math.cos(self.circle_angle) * radius,
				y = desired_y - pos.y,
				z = math.sin(self.circle_angle) * radius,
			}
			local goal = vector.add(pos, offset)
			local dir = vector.direction(pos, goal)
			local v = vector.multiply(dir, 9)
			self.object:set_velocity(v)
			self.object:set_yaw(minetest.dir_to_yaw(dir))
			if target and math.random(1, 160) == 1 then
				self.phantom_state = "dive"
			end
		elseif self.phantom_state == "dive" and target then
			local dir = vector.direction(pos, tpos)
			local v = vector.multiply(dir, 13)
			self.object:set_velocity(v)
			self.object:set_yaw(minetest.dir_to_yaw(dir))
			if vector.distance(pos, tpos) < 2.5 then
				target:punch(self.object, 1.0, {
					full_punch_interval = 1.0,
					damage_groups = { fleshy = 6 },
				})
				self.phantom_state = "circle"
			end
			if pos.y < tpos.y - 1 then
				self.phantom_state = "circle"
			end
		elseif self.phantom_state == "dive" then
			self.phantom_state = "circle"
		end

		return false
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:phantom", S("Phantom"), "#162328", "#a078db", 0)
-- MC-parity night spawn: neither spawn system has a time-of-day filter, so
-- a lightweight globalstep spawns phantoms at night near players who have
-- NOT SLEPT for 3+ in-game days (MC parity). Sleep is tracked by patching
-- the game's bed nodes at runtime: entering a bed marks the player; at
-- every noon, players who slept since the previous noon reset to 0 days,
-- others increment.
local ph_timer = 0
local function player_slept(player)
	local meta = player:get_meta()
	meta:set_string("mcl_mobs_addon:slept", "true")
end
-- patch the game's bed nodes so entering one marks the player
minetest.register_on_mods_loaded(function()
	for name, def in pairs(minetest.registered_nodes) do
		if name:find("^mcl_beds:") and def.on_rightclick then
			local orig = def.on_rightclick
			def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
				local r = orig(pos, node, clicker, itemstack, pointed_thing)
				if clicker and clicker:is_player() and clicker:is_in_bed() then
					player_slept(clicker)
				end
				return r
			end
		end
	end
end)
-- noon tracker: day boundary -> sleepless counters
local prev_t = nil  -- lazily set (get_timeofday can be nil during startup)
minetest.register_globalstep(function(dtime)
	ph_timer = ph_timer + dtime
	if ph_timer < 2 then return end
	ph_timer = 0
	if not minetest.get_connected_players() then return end
	local t = minetest.get_timeofday()
	if not t then return end
	if prev_t and prev_t <= 0.5 and t > 0.5 then
		-- new day (noon passed): update sleepless counters
		for _, player in ipairs(minetest.get_connected_players()) do
			local meta = player:get_meta()
			local slept = meta:get_string("mcl_mobs_addon:slept") == "true"
			local days = tonumber(meta:get_string("mcl_mobs_addon:sleepless")) or 0
			days = slept and 0 or (days + 1)
			meta:set_string("mcl_mobs_addon:sleepless", tostring(days))
			meta:set_string("mcl_mobs_addon:slept", "")
		end
	end
	prev_t = t
	if t > 0.25 and t < 0.75 then return end  -- daytime: no phantoms
	for _, player in ipairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local is_creative = minetest.settings:get_bool("creative_mode")
			or minetest.check_player_privs(name, { creative = true })
		local is_spec = mcl_mobs_addon.is_spectator and mcl_mobs_addon.is_spectator(player)
		if not is_creative and not is_spec then
			local days = tonumber(player:get_meta():get_string("mcl_mobs_addon:sleepless")) or 0
			if days >= 3 and math.random(60) == 1 then
				local ppos = player:get_pos()
				if ppos then
					local exists = false
					for _, o in ipairs(minetest.get_objects_inside_radius(ppos, 32)) do
						local le = o:get_luaentity()
						if le and le.name == "mcl_mobs_addon:phantom" then
							exists = true
							break
						end
					end
					if not exists then
						local sp = vector.offset(ppos, 0, 20 + math.random(0, 10), 0)
						if minetest.get_node(sp).name == "air" then
							minetest.add_entity(sp, "mcl_mobs_addon:phantom")
						end
					end
				end
			end
		end
	end
end)
mcln_base_hp("mcl_mobs_addon:phantom", 20, 20)

-- ---------------------------------------------------------------------------
-- SNIFFER  (MC 1.23; peaceful relic hunter — eggs only until the ruins
-- spawn condition is portable; drops TODO: sniffable seeds)
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mcl_mobs_addon:sniffer", {
	description = S("Sniffer"),
	type = "animal",
	spawn_class = "passive",
	attack_type = "dogfight",
	damage = 3,
	initial_properties = {
		hp_min = 14,
		hp_max = 14,
		collisionbox = { -0.7, 0, -0.7, 0.7, 1.6, 0.7 },
	},
	xp_min = 1,
	xp_max = 3,
	double_melee_attack = false,
	reach = 2,
	armor = 5,
	visual = "mesh",
	mesh = "mcl_mobs_addon_sniffer.b3d",
	visual_size = { x = 1, y = 1 },
	textures = { "mcl_mobs_addon_sniffer.png" },
	makes_footstep_sound = true,
	walk_velocity = 1,
	pace_bonus = 0.3,
	run_velocity = 4,
	view_range = 16,
	stepheight = 1.1,
	jump = true,
	jump_height = 10,
	suffocation = true,
	fear_height = 4,
	sounds = {},
	drops = {},
	animation = {
		stand_start = 140, stand_end = 150, stand_speed = 10,
		walk_start = 40, walk_end = 120, speed_normal = 10,
	},
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:sniffer", S("Sniffer"), "#872618", "#254017", 0)
mcln_base_hp("mcl_mobs_addon:sniffer", 14, 14)

minetest.log("action", "[mcl_mobs_addon] imported Bettercraft mobs: frog, turtle, phantom, sniffer")
