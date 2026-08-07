-- Warden (MC 1.19) — mob imported from Bettercraft (GPLv3, plain melee there)
-- + our UNIQUE AI on top:
--   - summoned ONLY by sculk shriekers (no natural spawn — MC parity),
--     warning level: 2nd scream within 60 s summons it
--   - HEARING: the warden is blind — it reacts to vibrations (the addon's
--     vibration system, vibrations.lua) within 24 nodes and targets the
--     player who caused them; target decays after 60 s without stimuli
--   - SONIC BOOM: ranged attack at 4-15 blocks (VL: vl_projectile; the
--     Bettercraft arrow existed but was dead code — attack_type was melee)

local S = minetest.get_translator("mcl_mobs_addon")

mcl_mobs.register_mob("mcl_mobs_addon:warden", {
	description = S("Warden"),
	type = "monster",
	spawn_class = "hostile",
	passive = false,
	initial_properties = {
		hp_min = 500,
		hp_max = 500,
		collisionbox = { -0.6, 0, -0.6, 0.6, 2, 0.6 },
	},
	damage = 45,
	armor = 10,
	reach = 3,
	attack_player = true,
	specific_attack = {
		"mobs_mc:iron_golem", "mobs_mc:pig", "mobs_mc:snow_golem",
		"mobs_mc:cow", "mobs_mc:sheep", "mobs_mc:chicken",
	},
	attack_npcs = true,
	attack_type = "melee",
	runaway_from = { "mobs_mc:frog", "mobs_mc:axolotl" },
	pathfinding = 1,
	makes_footstep_sound = true,
	fear_height = 4,
	movement_speed = 5.0,
	pace_bonus = 0.6,
	run_velocity = 2,
	stepheight = 1.1,
	view_range = 16,
	knock_back = false,
	visual = "mesh",
	mesh = "mcl_mobs_addon_warden.b3d",
	textures = { "mcl_mobs_addon_warden.png" },
	visual_size = { x = 1, y = 1 },
	glow = 4,
	fire_resistant = true,
	suffocation = false,
	drops = {
		{ name = "mcl_sculk:catalyst", chance = 1, min = 1, max = 2 },
	},
	animation = {
		stand_start = 0, stand_end = 60, stand_speed = 25,
		walk_start = 300, walk_end = 380, speed_normal = 25,
		run_start = 300, run_end = 380, speed_run = 50,
		punch_start = 558, punch_end = 574, punch_speed = 50,
		die_start = 690, die_end = 960, die_speed = 25, die_loop = false,
	},
	on_spawn = function(self)
		-- emerge animation (from underground)
		self.object:set_animation({ x = 80, y = 260 }, 50, 0, false)
	end,
	do_custom = function(self, dtime)
		-- vibration-anger: target decays after 60 s without stimuli
		if self._mca_target or self._mca_target_pos then
			self._mca_target_t = (self._mca_target_t or 60) - dtime
			if self._mca_target_t <= 0 then
				self._mca_target = nil
				self._mca_target_pos = nil
				self._mca_target_t = nil
			end
		end

		local target = self._mca_target
		local tpos = self._mca_target_pos
		if target and target:is_valid() then
			self.attack = target
			local sp = self.object:get_pos()
			local tp = target:get_pos()
			if sp and tp then
				local dist = vector.distance(sp, tp)
				-- sonic boom at 4-15 blocks (VoxeLibre; Mineclonia = melee v1)
				if dist > 4 and dist < 15 and vl_projectile then
					self._mca_boom_t = (self._mca_boom_t or 1) - dtime
					if self._mca_boom_t <= 0 then
						self._mca_boom_t = 2
						local p = vector.offset(sp, 0, 2, 0)
						local arrow = vl_projectile.create("mcl_mobs_addon:sonic_boom", {
							pos = p,
							owner = self,
						})
						local ent = arrow and arrow:get_luaentity()
						if ent then
							ent._shooter = self.object
							ent._saved_shooter_pos = sp
							ent.velocity = 14
							ent.switch = 1
						end
					end
				elseif dist > 3 then
					-- close the distance (Bettercraft's chase logic)
					self:gopath(tp, 0.9)
				end
			end
		elseif tpos then
			-- investigating a vibration source (no player to attack yet)
			self.attack = nil
			self:gopath(tpos, 0.6)
		else
			self.attack = nil
		end
	end,
})

mcl_mobs.register_egg("mcl_mobs_addon:warden", S("Warden"), "#061118", "#b6a180", 0)

-- Mineclonia's mob activate reads hp_min/hp_max from the DEF BASE
-- (mcl_mobs/api.lua:429 math.random(self.hp_min, ...)); VoxeLibre reads them
-- from initial_properties (api.lua:216) and warns if they are in the base.
-- Register with initial_properties only, then add the base fields for
-- Mineclonia (register_spawner is the Mineclonia marker).
if mcl_mobs.register_spawner then
	local def = mcl_mobs.registered_mobs["mcl_mobs_addon:warden"]
	if def then
		def.hp_min = 500
		def.hp_max = 500
	end
end

-- sonic boom projectile (dead code in Bettercraft — wired up here)
mcl_mobs.register_arrow("mcl_mobs_addon:sonic_boom", {
	description = S("Sonic Boom"),
	visual = "sprite",
	visual_size = { x = 1, y = 1 },
	textures = { "mcl_mobs_addon_sonic_boom.png" },
	velocity = 14,
	tail = 1,
	tail_texture = "mcl_mobs_addon_sonic_boom.png",
	tail_size = 10,
	glow = 5,
	expire = 1,
	collisionbox = { -0.5, -0.5, -0.5, 0.5, 0.5, 0.5 },
	redirectable = true,
	hit_player = mcl_mobs.get_arrow_damage_func(25),
	hit_mob = mcl_mobs.get_arrow_damage_func(25),
	hit_node = function() end,
})

-- hearing: the blind warden reacts to vibrations within 24 nodes
if mcl_mobs_addon.vibrations and mcl_mobs_addon.vibrations.register_listener then
	mcl_mobs_addon.vibrations.register_listener(function(vpos, freq, player)
		for _, obj in ipairs(minetest.get_objects_inside_radius(vpos, 24)) do
			local le = obj:get_luaentity()
			if le and le.name == "mcl_mobs_addon:warden" then
				le._mca_target = player
				le._mca_target_pos = vpos
				le._mca_target_t = 60
			end
		end
	end)
	minetest.log("action", "[mcl_mobs_addon] warden hearing: vibration listener attached")
end

minetest.log("action", "[mcl_mobs_addon] warden registered (shrieker-summoned, hears vibrations, sonic boom)")
