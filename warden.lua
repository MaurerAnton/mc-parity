-- Warden (MC 1.19) — mob imported from Bettercraft (GPLv3, plain melee there)
-- + our UNIQUE AI on top:
--   - summoned ONLY by sculk shriekers (no natural spawn — MC parity),
--     warning level: 2nd scream within 60 s summons it
--   - HEARING: the warden is blind — it reacts to vibrations (the addon's
--     vibration system, vibrations.lua) within 24 nodes and targets the
--     player who caused them; target decays after 60 s without stimuli
--   - SONIC BOOM: ranged attack at 4-15 blocks. MC parity: the boom is a
--     shockwave that PASSES THROUGH WALLS — implemented as a ray (damage
--     along the facing cone) instead of a projectile, so it works
--     identically on both games (Bettercraft's arrow was dead code)
--   - DARKNESS: an angry warden darkens the sky for its target (the addon
--     registers the mcl_potions "darkness" effect; VoxeLibre's skycolor
--     has a handler for it, Mineclonia applies the effect without the
--     sky change)
--   - HEARTBEAT: while agitated the warden plays a heartbeat (synthesized
--     CC0 sound, tools/gen_sounds.py)

local S = minetest.get_translator("mc_parity")
local BOOM_SOUND = "mc_parity_warden_boom"
local HEARTBEAT = "mc_parity_warden_heartbeat"

-- MC: the sonic boom is a shockwave along the warden's facing direction,
-- 4-15 nodes, IGNORING blocks (no line-of-sight check). Aimed at the
-- TARGET (not the current yaw — a freshly summoned warden's yaw is
-- arbitrary; the framework only rotates mobs while moving)
local function sonic_boom(self, target_pos)
	local sp = self.object:get_pos()
	if not sp or not target_pos then return end
	local dir = vector.normalize(vector.subtract(target_pos, sp))
	dir.y = 0
	minetest.sound_play(BOOM_SOUND, { pos = sp, gain = 0.9, max_hear_distance = 24 }, true)
	for _, obj in ipairs(minetest.get_objects_inside_radius(sp, 15)) do
		local op = obj:get_pos()
		if op then
			local rel = vector.subtract(op, sp)
			local dist = vector.length(rel)
			if dist > 4 and dist <= 15 then
				local nd = vector.normalize(rel)
				if nd.x * dir.x + nd.z * dir.z > 0.7 then  -- ~45 deg cone
					-- framework damage: no knockback (mcl_util, both games)
					if obj ~= self.object and mcl_util and mcl_util.deal_damage then
						mcl_util.deal_damage(obj, 10, { type = "sonic_boom" })
					end
				end
			end
		end
	end
end

-- darkness effect: registered once mcl_potions is available (both games
-- ship the same API). VoxeLibre's skycolor applies the visual darkness.
local function register_darkness_effect()
	if not mcl_potions or not mcl_potions.register_effect then return end
	if mcl_potions.registered_effects and mcl_potions.registered_effects.darkness then return end
	pcall(mcl_potions.register_effect, {
		name = "darkness",
		description = S("Darkness"),
		icon = "mc_parity_effect_darkness.png",
	})
	minetest.log("action", "[mc_parity] darkness effect registered")
end
minetest.register_on_mods_loaded(register_darkness_effect)

mcl_mobs.register_mob("mc_parity:warden", {
	description = S("Warden"),
	type = "monster",
	spawn_class = "hostile",
	passive = false,
	initial_properties = {
		hp_min = 500,
		hp_max = 500,
		collisionbox = { -0.6, 0, -0.6, 0.6, 2, 0.6 },
	},
	damage = 30,  -- MC parity (was 45 from Bettercraft)
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
	mesh = "mc_parity_warden.b3d",
	textures = { "mc_parity_warden.png" },
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
				-- sonic boom at 4-15 blocks (ray through walls — MC parity)
				if dist > 4 and dist < 15 then
					self._mca_boom_t = (self._mca_boom_t or 1) - dtime
					if self._mca_boom_t <= 0 then
						self._mca_boom_t = 2
						sonic_boom(self, tp)
					end
				elseif dist > 3 then
					-- close the distance (Bettercraft's chase logic)
					self:gopath(tp, 0.9)
				end
				-- DARKNESS: an angry warden darkens its target (MC parity);
				-- re-applied every 3s, 5s duration (VL skycolor darkens the sky)
				if target:is_player() then
					self._mca_dark_t = (self._mca_dark_t or 0) - dtime
					if self._mca_dark_t <= 0 and mcl_potions and mcl_potions.give_effect_by_level then
						self._mca_dark_t = 3
						pcall(mcl_potions.give_effect_by_level, "darkness", target, 1, 5)
					end
				end
				-- HEARTBEAT: audible while the warden is agitated (MC parity)
				self._mca_hb_t = (self._mca_hb_t or 0) - dtime
				if self._mca_hb_t <= 0 then
					self._mca_hb_t = 1.1
					minetest.sound_play(HEARTBEAT, { pos = sp, gain = 0.7, max_hear_distance = 24 }, true)
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

mcl_mobs.register_egg("mc_parity:warden", S("Warden"), "#061118", "#b6a180", 0)

-- Mineclonia's mob activate reads hp_min/hp_max from the DEF BASE
-- (mcl_mobs/api.lua:429 math.random(self.hp_min, ...)); VoxeLibre reads them
-- from initial_properties (api.lua:216) and warns if they are in the base.
-- Register with initial_properties only, then add the base fields for
-- Mineclonia (register_spawner is the Mineclonia marker).
if mcl_mobs.register_spawner then
	local def = mcl_mobs.registered_mobs["mc_parity:warden"]
	if def then
		def.hp_min = 500
		def.hp_max = 500
	end
end

-- sonic boom: ray-based (see sonic_boom above) — the Bettercraft arrow
-- was dead code and the vl_projectile variant stopped at walls; the ray
-- passes through blocks like MC and works on both games.

-- hearing: the blind warden reacts to vibrations within 24 nodes
if mc_parity.vibrations and mc_parity.vibrations.register_listener then
	mc_parity.vibrations.register_listener(function(vpos, freq, player)
		for _, obj in ipairs(minetest.get_objects_inside_radius(vpos, 24)) do
			local le = obj:get_luaentity()
			if le and le.name == "mc_parity:warden" then
				le._mca_target = player
				le._mca_target_pos = vpos
				le._mca_target_t = 60
			end
		end
	end)
	minetest.log("action", "[mc_parity] warden hearing: vibration listener attached")
end

minetest.log("action", "[mc_parity] warden registered (shrieker-summoned, hears vibrations, sonic boom)")
