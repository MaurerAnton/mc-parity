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
		if self.go_home then
			self._has_egg = true
			self:go_home()
		end
		return false
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:turtle", S("Turtle"), "#516720", "#ded88f", 0)
mcl_mobs_addon.register_spawn("mcl_mobs_addon:turtle",
	{ "StoneBeach" },
	{ "StoneBeach" }, 40)
mcln_base_hp("mcl_mobs_addon:turtle", 10, 10)

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

		-- nearest non-creative player within 64
		local target = nil
		local min_dist = 64
		for _, player in ipairs(minetest.get_connected_players()) do
			local name = player:get_player_name()
			local is_creative = minetest.settings:get_bool("creative_mode")
				or minetest.check_player_privs(name, { creative = true })
			if not is_creative then
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
-- no natural spawn: the spawn systems have no time-of-day filter, so a
-- night-only phantom spawn (MC parity) isn't expressible — TODO
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
