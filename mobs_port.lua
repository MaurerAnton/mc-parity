-- MC mobs ported from Mineclonia (GPLv3 — same license as the addon):
-- creeper (+charged), enderman, blaze, pufferfish, ravager,
-- wandering trader. These close the LAST ecosystem gaps: VoxeLibre
-- 0.92 lacks creeper/enderman/blaze/pufferfish/wandering_trader
-- entirely; Mineclonia has them but NOT ravager-friendly targeting here.
-- Adapted: ids -> mcl_mobs_addon:*, Mineclonia-only spawn API ->
-- dual-game register_monster_spawn, raid/targeting-rule machinery ->
-- standard framework aggro (the targeting-rule API is Mineclonia-only).
-- Media (models/textures) keeps the mobs_mc_* names (the media namespace
-- is global; on Mineclonia our identical copies simply shadow the game's).

local S = minetest.get_translator("mcl_mobs_addon")

-- Mineclonia's table.merge is missing in VoxeLibre — shim it
if not table.merge then
	function table.merge(t1, t2)
		local r = {}
		if t1 then for k, v in pairs(t1) do r[k] = v end end
		if t2 then for k, v in pairs(t2) do r[k] = v end end
		return r
	end
end

-- shared biome lists (verified valid in BOTH games' registries)
local OW_MONSTERS = {
	"Plains", "Forest", "SunflowerPlains", "FlowerForest", "BirchForest",
	"BirchForestM", "RoofedForest", "Taiga", "MegaTaiga", "MegaSpruceTaiga",
	"ColdTaiga", "Desert", "Savanna", "SavannaM", "Swampland", "Jungle",
	"JungleM", "BambooJungle", "ExtremeHills", "Mesa", "MesaBryce",
	"MesaPlateauF", "MesaPlateauFM", "IcePlains", "IcePlainsSpikes",
}
local NETHER_BIOMES = { "Nether", "CrimsonForest", "WarpedForest" }
local END_BIOMES = {
	"End", "EndBarrens", "EndBorder", "EndHighlands", "EndIsland",
	"EndMidlands", "EndSmallIslands",
}
local OCEAN_BIOMES = {
	"Jungle_ocean", "Savanna_ocean", "Desert_ocean", "Swampland_ocean",
	"Plains_ocean", "Forest_ocean", "BirchForest_ocean", "FlowerForest_ocean",
	"Taiga_ocean", "ColdTaiga_ocean",
}

-- dual-game monster spawn (the animal variant in init.lua is for passives;
-- monsters use the game's monster_spawner template + pack sizes)
local function register_monster_spawn(name, biomes, weight, pack_min, pack_max, dimension)
	dimension = dimension or "overworld"
	local ok, err = pcall(function()
	if mcl_mobs.register_spawner and mobs_mc and mobs_mc.monster_spawner then
		mcl_mobs.register_spawner(table.merge(mobs_mc.monster_spawner, {
			name = name,
			biomes = biomes,
			weight = weight,
			pack_min = pack_min or 1,
			pack_max = pack_max or 1,
		}))
	elseif mcl_mobs.spawn_setup then
		mcl_mobs:spawn_setup({
			name = name,
			dimension = dimension,
			biomes = biomes,
			weight = weight,
		})
	end
	end)
	if not ok then
		minetest.log("action", "[mcl_mobs_addon] spawn FAIL " .. tostring(name) .. ": " .. tostring(err))
	end
end

-- ---------------------------------------------------------------------------
-- CREEPER (+charged)
-- ---------------------------------------------------------------------------
--License for code WTFPL and otherwise stated in readmes

local S = core.get_translator("mobs_mc")
local is_valid = mcl_util.is_valid_objectref

local mobs_griefing = (mobs_mc and mobs_mc.is_mob_griefing_enabled)
	and mobs_mc.is_mob_griefing_enabled("creeper") or true

--###################
--################### CREEPER
--###################

local creeper_defs = {
	type = "monster",
	spawn_class = "hostile",
	attack_player = true,
	_spawn_category = "monster",
	hp_min = 20,
	hp_max = 20,
	xp_min = 5,
	xp_max = 5,
	collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3},
	visual = "mesh",
	mesh = "mobs_mc_creeper.b3d",
	visual_size = { x = 3, y = 3 },
	makes_footstep_sound = true,
	movement_speed = 5.0,
	runaway = true,
	runaway_from = { "mobs_mc:ocelot", "mobs_mc:cat", },
	attack_type = "melee",
	sounds = {
		attack = "tnt_ignite",
		death = "mobs_mc_creeper_death",
		damage = "mobs_mc_creeper_hurt",
		fuse = "tnt_ignite",
		explode = "tnt_explode",
		distance = 16,
	},
	drops = {
		{
			name = "mcl_mobitems:gunpowder",
			chance = 1,
			min = 0,
			max = 2,
			looting = "common",
		},
		{
			name = "mcl_heads:creeper",
			chance = 1,
			min = 0,
			max = 0,
			mob_head = true,
		},
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 48,
		run_start = 0, run_end = 40, run_speed = 48,
		hurt_start = 110, hurt_end = 139,
		death_start = 140, death_end = 189,
		look_start = 50, look_end = 108,
	},
	floats = 1,
	reach = 3,
	pace_bonus = 0.8,
	_unplaceable_by_default = true,
}

---------------------------------------------------------------
-- Creeper mechanics.
---------------------------------------------------------------

local CREEPER_SWELL_TIME = 30/20

function creeper_defs:on_rightclick (clicker)
	local item = clicker:get_wielded_item()
	if core.get_item_group(item:get_name(), "flint_and_steel") > 0 then
		if not core.is_creative_enabled(clicker:get_player_name()) then
			-- Wear tool
			local wdef = item:get_definition()
			item:add_wear(1000)
			-- Tool break sound
			if item:get_count() == 0 and wdef.sound and wdef.sound.breaks then
				core.sound_play(wdef.sound.breaks, {pos = clicker:get_pos(), gain = 0.5}, true)
			end
			clicker:set_wielded_item(item)
		end
		self.attack = self.object
		self:custom_attack ()
	end
end

function creeper_defs:update_swell ()
	local self_pos = self.object:get_pos ()
	local visual_size = self.initial_properties.visual_size
	self:cancel_navigation ()
	self:halt_in_tracks ()

	if not self.attack
		or not is_valid (self.attack)
		or self._swell_time <= 0 then
		self._swell_dir = -1
	else
		local target_pos
			= mcl_attachments.get_attachment_pos (self.attack)
		if vector.distance (self_pos, target_pos) > 7.0
			or not self:target_visible (self_pos, self.attack) then
			-- Cancel swelling if the target is no longer valid.
			self._swell_dir = -1
		end
	end

	if self._swell_time >= CREEPER_SWELL_TIME then
		self:creeper_explode (mcl_util.get_object_center (self.object),
				      self.explosion_strength)
		return
	end

	local swell = self._swell_time / CREEPER_SWELL_TIME
	local interpolated = 1 + math.sin (swell * 100) * swell * 0.01
	swell = swell * swell * swell
	local xz = (1.0 + swell * 0.4) * interpolated
	local y = (1.0 + swell * 0.1) / interpolated
	self:set_properties ({
		visual_size = {
			x = visual_size.x * xz,
			y = visual_size.y * y,
		},
	})

	local t = math.floor (self._swell_time * 20)
	if t % 12 == 6 or self._swell_dir == -1 then
		self:remove_texture_mod ("^[brighten")
	elseif t % 12 == 0 then
		self:add_texture_mod ("^[brighten")
	end
end

function creeper_defs:creeper_explode (pos, strength)
	-- Prevent any further damage from being dealt to this mob
	-- by the explosion by removing it now.
	self:safe_remove ()
	mcl_explosions.explode (pos, strength, {
		griefing = mobs_griefing,
	}, self.object)
	-- Dissipate active status effects.
	for name, val in pairs (mcl_potions.all_effects (self.object)) do
		local level = mcl_potions.get_effect_level (self.object,
							    name)
		mcl_potions.add_lingering_effect (pos, name, val.dur / 2,
						  level, 2.5)
	end
end

function creeper_defs:do_custom (dtime)
	local swell_time = self._swell_time
	local swell_dir  = self._swell_dir
	if swell_dir == 1 then
		self._swell_time = swell_time + dtime
		self:update_swell ()
		return false
	elseif swell_dir == -1 then
		local t = swell_time - dtime
		self._swell_time = t
		if t <= 0 then
			self._swell_time = 0
		end
		self:update_swell ()
		-- Clear this after update_swell is called, to
		-- override any value it might set.
		if t <= 0 then
			self._swell_dir = nil
		end
		return false
	end
end

function creeper_defs:on_die (pos, mcl_reason)
	-- Drop a random music disc when killed by skeleton or stray
	if mcl_reason and mcl_reason.type == "arrow" then
		if mcl_reason.mob_name == "mobs_mc:skeleton"
			or mcl_reason.mob_name == "mobs_mc:stray" then
			local loot = mcl_jukebox.get_random_creeper_loot()
			if loot then
				core.add_item({x=pos.x, y=pos.y+1, z=pos.z}, loot)
			end
		end
	end
end

function creeper_defs:damage_mob (reason, damage)
	mcl_mobs.mob_class.damage_mob(self, reason, damage)
	if reason == "fall" then
		self._swell_time
			= ((self._swell_time or 0)
				+ math.floor (damage * 1.5) / 20)
		if self._swell_time > CREEPER_SWELL_TIME - 0.25 then
			self._swell_time = CREEPER_SWELL_TIME - 0.25
		end
	end
end

---------------------------------------------------------------
-- Creeper AI.
---------------------------------------------------------------

function creeper_defs:custom_attack ()
	-- Begin swelling.
	self:mob_sound ("attack")
	self._swell_time = self._swell_time or 0
	self._swell_dir = 1
	self:cancel_navigation ()
	self:halt_in_tracks ()
end



---------------------------------------------------------------
-- Creeper registration and spawning.
---------------------------------------------------------------

local regular_creeper = table.merge (creeper_defs, {
	description = S("Creeper"),
	head_swivel = "Head_Control",
	bone_eye_height = 2.35,
	curiosity = 2,
	textures = {
		{
			"mobs_mc_creeper.png",
			"mobs_mc_empty.png",
		},
	},
	explosion_strength = 3,
	explosion_radius = 3.5,
	explosion_damage_radius = 3.5,
})

function regular_creeper:_on_lightning_strike ()
	mcl_util.replace_mob(self.object, "mcl_mobs_addon:creeper_charged")
	return true
end

mcl_mobs.register_mob ("mcl_mobs_addon:creeper", regular_creeper)

local charged_creeper = table.merge (creeper_defs, {
	description = S("Charged Creeper"),
	textures = {
		{
			"mobs_mc_creeper.png",
			"mobs_mc_creeper_charge.png^[opacity:95",
		},
	},
	explosion_strength = 6,
	explosion_radius = 8,
	explosion_damage_radius = 8,
	explosion_timer = 1.5,
	use_texture_alpha = true,
})

mcl_mobs.register_mob ("mcl_mobs_addon:creeper_charged", charged_creeper)

-- spawn eggs
mcl_mobs.register_egg("mcl_mobs_addon:creeper", S("Creeper"), "#0da70a", "#000000", 0)

---------------------------------------------------------------
-- Modern Creeper spawning.
---------------------------------------------------------------

register_monster_spawn("mcl_mobs_addon:creeper", OW_MONSTERS, 100, 4, 4)

-- ---------------------------------------------------------------------------
-- BLAZE
-- ---------------------------------------------------------------------------
-- daufinsyd
-- My work is under the LGPL terms
-- Model and mobs_blaze.png see https://github.com/22i/minecraft-voxel-blender-models -hi 22i ~jordan4ibanez
-- blaze.lua partial copy of mobs_mc/ghast.lua

local S = core.get_translator("mobs_mc")

--###################
--################### BLAZE
--###################

local blaze = {
	description = S("Blaze"),
	type = "monster",
	spawn_class = "hostile",
	attack_player = true,
	_spawn_category = "monster",
	hp_min = 20,
	hp_max = 20,
	xp_min = 10,
	xp_max = 10,
	collisionbox = {-0.3, -0.01, -0.3, 0.3, 1.79, 0.3},
	visual = "mesh",
	mesh = "mobs_mc_blaze.b3d",
	head_swivel = "head.control",
	bone_eye_height = 4,
	textures = {
		{"mobs_mc_blaze.png"},
	},
	armor = {
		fleshy = 100,
		snowball_vulnerable = 100,
		water_vulnerable = 100,
	},
	visual_size = {x=3, y=3},
	sounds = {
		shoot_attack = "mobs_fireball",
		random = "mobs_mc_blaze_breath",
		death = "mobs_mc_blaze_died",
		damage = "mobs_mc_blaze_hurt",
		distance = 16,
	},
	movement_speed = 4.6,
	damage = 6,
	reach = 2,
	drops = {
		{
			name = "mcl_mobitems:blaze_rod",
			chance = 1,
			min = 0,
			max = 1,
			looting = "common",
		},
	},
	animation = {
		stand_speed = 25,
		stand_start = 0,
	        stand_end = 100,
	},
	_water_sensitive = true,
	_fire_resistant = true,
	_no_fall_damage = true,
	fire_damage_resistant = true,
	gravity_drag = 0.6,
	attack_type = "null",
	arrow = "mcl_mobs_addon:blaze_fireball",
	makes_footstep_sound = false,
	glow = 14,
	view_range = 48.0,
	tracking_distance = 48.0,
	_projectile_gravity = false,
}

------------------------------------------------------------------------
-- Blaze visuals.
------------------------------------------------------------------------

local function blaze_set_charged (self, charged)
	if charged then
		mcl_burning.set_on_fire (self.object, math.huge)
	else
		mcl_burning.extinguish (self.object)
	end
end

function blaze:mob_activate (staticdata, dtime)
	if not mcl_mobs.mob_class.mob_activate(self, staticdata, dtime) then
		return false
	end
	self.object:set_animation ({
		x = self.animation.stand_start,
		y = self.animation.stand_end,
	})
	return true
end

function blaze:set_animation (anim, fixed_frame)
	return
end

function blaze:do_custom (dtime)
	local pos = self.object:get_pos()

	if not self._height_diff_tolerance or self._height_diff_tolerance_age >= 5 then
		self._height_diff_tolerance = mcl_util.dist_triangular (0.5, 6.891)
		self._height_diff_tolerance_age = 0
	end
	self._height_diff_tolerance_age = self._height_diff_tolerance_age + dtime

	if not self:check_timer("blaze_particles", mcl_util.float_random(0.5, 2)) then return end

	core.add_particle({
			pos = {x = pos.x+mcl_util.float_random(-0.7,0.7) * math.random()/2, y = pos.y+mcl_util.float_random(0.7,1.2), z = pos.z+mcl_util.float_random(-0.7,0.7) * math.random()/2},
			velocity = {x=0, y = mcl_util.float_random(0.5, 2), z=0},
			expirationtime = math.random(),
			size = mcl_util.float_random(1, 4),
			collisiondetection = true,
			vertical = false,
			texture = "mcl_particles_smoke_anim.png^[colorize:#2c2c2c:255",
			animation = {
				type = "vertical_frames",
				aspect_w = 8,
				aspect_h = 8,
				length = 2.05,
			},
	})
	core.add_particle({
			pos = {x = pos.x+mcl_util.float_random(-0.7,0.7)* math.random()/2, y = pos.y+mcl_util.float_random(0.7,1.2), z = pos.z+mcl_util.float_random(-0.7,0.7) * math.random()/2},
			velocity = {x=0, y = mcl_util.float_random(0.5, 2), z=0},
			expirationtime = math.random(),
			size = mcl_util.float_random(1, 4),
			collisiondetection = true,
			vertical = false,
			texture = "mcl_particles_smoke_anim.png^[colorize:#424242:255",
			animation = {
				type = "vertical_frames",
				aspect_w = 8,
				aspect_h = 8,
				length = 2.05,
			},
	})
	core.add_particle({
			pos = {x = pos.x+mcl_util.float_random(-0.7,0.7)*math.random()/2, y = pos.y+mcl_util.float_random(0.7,1.2), z = pos.z+mcl_util.float_random(-0.7,0.7)*math.random()/2},
			velocity = {x=0, y = mcl_util.float_random(0.5,2), z=0},
			expirationtime = math.random(),
			size = mcl_util.float_random(1, 4),
			collisiondetection = true,
			vertical = false,
			texture = "mcl_particles_smoke_anim.png^[colorize:#0f0f0f:255",
			animation = {
				type = "vertical_frames",
				aspect_w = 8,
				aspect_h = 8,
				length = 2.05,
			},
	})

	if not self.attack then
		blaze_set_charged (self, false)
	end
end

function blaze:set_animation_speed (custom_speed)
	self.object:set_animation_frame_speed (25)
end

------------------------------------------------------------------------
-- Blaze AI.
------------------------------------------------------------------------

local TICKS_PER_SEC = 20
local mathpow = math.pow

local function lerp1d_scaled (u, dtime, s1, s2)
	local x = dtime * TICKS_PER_SEC
	local v = -(s2 * mathpow (1 - u, x))
		+ s1 * mathpow (1 - u, x) + s2
	return v
end

function blaze:attack_null (attach_pos, self_pos, dtime, target_pos, line_of_sight)
	if not self.attacking then
		-- Initialize fields used during the attack.
		self._visible_for = 0
		self._phase_remaining = 0
		self._phase = 0 -- 1: charging; 2 to 4: shooting; 5/0: recharge.
		blaze_set_charged (self, false)
		self.attacking = true
	end

	if line_of_sight then
		self._visible_for = self._visible_for + dtime
	else
		self._visible_for = 0
	end
	self._phase_remaining
		= self._phase_remaining - dtime

	-- Move above target if necessary
	local target_eye_height
		= target_pos.y + mcl_util.target_eye_height (self.attack)
	local self_eye_height
		= attach_pos.y + self:get_eye_height ()
	if target_eye_height > self_eye_height + self._height_diff_tolerance then
		local v = self.object:get_velocity ()
		v.y = lerp1d_scaled (0.3, dtime, v.y, 6.0)
		self.object:set_velocity (v)
	end

	local distance = vector.distance (attach_pos, target_pos)
	-- Resort to melee attacks if the target has approached too
	-- near.
	if distance < 2.0 then
		if not line_of_sight then
			return
		end

		if self._phase_remaining <= 0 then
			self._phase_remaining = 1
			self.attack:punch (self.object, 1.0, {
				full_punch_interval = 1.0,
				damage_groups = {
					fleshy = self.damage,
				},
			}, vector.direction (attach_pos, target_pos))
		end
		self:go_to_pos (target_pos)
	elseif distance < self.tracking_distance and line_of_sight then
		if self._phase_remaining > 0 then
			return
		end

		-- Proceeed to next phase.
		self._phase = self._phase + 1
		if self._phase == 1 then
			-- Charge for three seconds.
			blaze_set_charged (self, true)
			self._phase_remaining = 3
		elseif self._phase <= 4 then
			-- Shoot fireballs.
			local dx, dy, dz
			local props = self.attack:get_properties ()
			local cbox = props.collisionbox
			dx = target_pos.x - attach_pos.x
			dy = (target_pos.y + cbox[2] + (cbox[5] - cbox[2]) / 2)
				- (attach_pos.y + 0.9)
			dz = target_pos.z - attach_pos.z

			local scatter = math.sqrt (distance) / 2
			local vec = vector.normalize ({
				x = mcl_util.dist_triangular (dx, 2.297 * scatter),
				y = dy,
				z = mcl_util.dist_triangular (dz, 2.297 * scatter),
			})
			local pos = vector.offset (attach_pos, 0, 0.9, 0)
			local arrow = core.add_entity (pos, self.arrow)
			if arrow then
				local luaentity = arrow:get_luaentity ()
				self:mob_sound ("shoot_attack")
				arrow:set_velocity (vector.multiply (vec, luaentity.velocity))
				luaentity.switch = 1
				luaentity.owner_id = tostring (self.object)
				luaentity._shooter = self.object
				luaentity._saved_shooter_pos = vector.copy (attach_pos)
			end
			self._phase_remaining = 0.3
		else
			-- 5 second timeout.
			self._phase_remaining = 5
			self._phase = 0
			blaze_set_charged (self, false)
		end
	elseif self._visible_for < 0.25 then
		-- Shift around slightly if the target was in view
		-- only briefly.
		self:go_to_pos (target_pos)
	end
end




mcl_mobs.register_mob ("mcl_mobs_addon:blaze", blaze)

------------------------------------------------------------------------
-- Blaze spawning.
------------------------------------------------------------------------

register_monster_spawn("mcl_mobs_addon:blaze", NETHER_BIOMES, 20, 1, 2, "nether")
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:blaze", 20, 20)

-- ---------------------------------------------------------------------------
-- ENDERMAN
-- ---------------------------------------------------------------------------
--MCmobs v0.4
--maikerumine
--made for MC like Survival game
--License for code WTFPL and otherwise stated in readmes

-- Rootyjr
-----------------------------
-- implemented ability to detect when seen / break eye contact and aggressive response
-- implemented teleport to avoid arrows.
-- implemented teleport to avoid rain.
-- implemented teleport to chase.
-- added enderman particles.
-- drew mcl_portal_particle1.png
-- drew mcl_portal_particle2.png
-- drew mcl_portal_particle3.png
-- drew mcl_portal_particle4.png
-- drew mcl_portal_particle5.png
-- added rain damage.
-- fixed the grass_with_dirt issue.

core.register_entity ("mcl_mobs_addon:ender_eyes", {
	initial_properties = {
		visual = "mesh",
		mesh = "mobs_mc_spider.b3d",
		visual_size = {x=1.01/3, y=1.01/3},
		glow = 50,
		textures = {
			"mobs_mc_enderman_eyes.png",
		},
		selectionbox = {
			0, 0, 0, 0, 0, 0,
		},
	},
	on_step = function(self)
		if self and self.object then
			if not self.object:get_attach() then
				self.object:remove()
			end
		end
	end,
})

local S = core.get_translator("mobs_mc")

local telesound = function(pos, is_source)
	local snd
	if is_source then
		snd = "mobs_mc_enderman_teleport_src"
	else
		snd = "mobs_mc_enderman_teleport_dst"
	end
	core.sound_play(snd, {pos=pos, max_hear_distance=16}, true)
end

--###################
--################### ENDERMAN
--###################

local pr = PcgRandom (os.time () * (-334))

-- Texuture overrides for enderman block. Required for cactus because it's original is a nodebox
-- and the textures have tranparent pixels.
local block_texture_overrides
do
	local cbackground = "mobs_mc_enderman_cactus_background.png"
	local ctiles = core.registered_nodes["mcl_core:cactus"].tiles

	local ctable = {}
	local last
	for i=1, 6 do
		if ctiles[i] then
			last = ctiles[i]
		end
		table.insert(ctable, cbackground .. "^" .. last)
	end

	block_texture_overrides = {
		["mcl_core:cactus"] = ctable,
		-- FIXME: replace colorize colors with colors from palette
		["mcl_core:dirt_with_grass"] =
		{
		"mcl_core_grass_block_top.png^[colorize:green:90",
		"default_dirt.png",
		"default_dirt.png^(mcl_core_grass_block_side_overlay.png^[colorize:green:90)",
		"default_dirt.png^(mcl_core_grass_block_side_overlay.png^[colorize:green:90)",
		"default_dirt.png^(mcl_core_grass_block_side_overlay.png^[colorize:green:90)",
		"default_dirt.png^(mcl_core_grass_block_side_overlay.png^[colorize:green:90)"}
	}
end

-- Create the textures table for the enderman, depending on which kind of block
-- the enderman holds (if any).
local create_enderman_textures = function(block_type, itemstring)
	local base = "mobs_mc_enderman.png^mobs_mc_enderman_eyes.png"

	--[[ Order of the textures in the texture table:
		Flower, 90 degrees
		Flower, 45 degrees
		Held block, backside
		Held block, bottom
		Held block, front
		Held block, left
		Held block, right
		Held block, top
		Enderman texture (base)
	]]
	-- Regular cube
	if block_type == "cube" then
		local tiles = core.registered_nodes[itemstring].tiles
		local textures = {}
		local last
		if block_texture_overrides[itemstring] then
			-- Texture override available? Use these instead!
			textures = block_texture_overrides[itemstring]
		else
			-- Extract the texture names
			for i = 1, 6 do
				if type(tiles[i]) == "string" then
					last = tiles[i]
				elseif type(tiles[i]) == "table" then
					if tiles[i].name then
						last = tiles[i].name
					end
				end
				table.insert(textures, last)
			end
		end
		return {
			"blank.png",
			"blank.png",
			textures[5],
			textures[2],
			textures[6],
			textures[3],
			textures[4],
			textures[1],
			base, -- Enderman texture
		}
	-- Node of plantlike drawtype, 45° (recommended)
	elseif block_type == "plantlike45" then
		local textures = core.registered_nodes[itemstring].tiles
		return {
			"blank.png",
			textures[1],
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			base,
		}
	-- Node of plantlike drawtype, 90°
	elseif block_type == "plantlike90" then
		local textures = core.registered_nodes[itemstring].tiles
		return {
			textures[1],
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			base,
		}
	elseif block_type == "unknown" then
		return {
			"blank.png",
			"blank.png",
			"unknown_node.png",
			"unknown_node.png",
			"unknown_node.png",
			"unknown_node.png",
			"unknown_node.png",
			"unknown_node.png",
			base, -- Enderman texture
		}
	-- No block held (for initial texture)
	elseif block_type == "nothing" or block_type == nil then
		return {
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			"blank.png",
			base, -- Enderman texture
		}
	end
end

-- Select a new animation definition.
local select_enderman_animation = function(animation_type)
	-- Enderman holds a block
	if animation_type == "block" then
		return {
			stand_start = 200, stand_end = 200,
			walk_start = 161, walk_end = 200, walk_speed = 25,
			attack_start = 81, attack_end = 120, attack_speed = 50,
		}
	-- Enderman doesn't hold a block
	elseif animation_type == "normal" or animation_type == nil then
		return {
			stand_start = 40, stand_end = 80, stand_speed = 25,
			walk_start = 0, walk_end = 40, walk_speed = 25,
			attack_start = 81, attack_end = 120, attack_speed = 50,
		}
	end
end

local mobs_griefing = (mobs_mc and mobs_mc.is_mob_griefing_enabled)
	and mobs_mc.is_mob_griefing_enabled("enderman") or true
local psdefs = {{
	amount = 5,
	minpos = vector.new(-0.6,0,-0.6),
	maxpos = vector.new(0.6,3,0.6),
	minvel = vector.new(-0.25,-0.25,-0.25),
	maxvel = vector.new(0.25,0.25,0.25),
	minacc = vector.new(-0.5,-0.5,-0.5),
	maxacc = vector.new(0.5,0.5,0.5),
	minexptime = 0.2,
	maxexptime = 3,
	minsize = 0.2,
	maxsize = 1.2,
	collisiondetection = true,
	vertical = false,
	time = 0,
	texture = "mcl_portals_particle"..math.random(1, 5)..".png",
}}

local enderman = {
	description = S("Enderman"),
	type = "monster",
	spawn_class = "hostile",
	attack_player = true,
	_spawn_category = "monster",
	hp_min = 40,
	hp_max = 40,
	xp_min = 5,
	xp_max = 5,
	collisionbox = {-0.3, 0, -0.3, 0.3, 2.9, 0.3},
	doll_size_override = { x = 0.8, y = 0.8 },
	visual = "mesh",
	mesh = "mobs_mc_enderman.b3d",
	textures = create_enderman_textures(),
	visual_size = {x=3, y=3},
	makes_footstep_sound = true,
	can_despawn = true,
	head_eye_height = 2.55,
	sounds = {
		death = {name="mobs_mc_enderman_death", gain=0.7},
		damage = {name="mobs_mc_enderman_hurt", gain=0.5},
		random = {name="mobs_mc_enderman_random", gain=0.5},
		distance = 16,
	},
	movement_speed = 6.0,
	damage = 7,
	stepheight = 1.01,
	reach = 2,
	particlespawners = psdefs,
	drops = {
		{
			name = "mcl_throwing:ender_pearl",
			chance = 1,
			min = 0,
			max = 1,
			looting = "common",
		},
	},
	animation = select_enderman_animation("normal"),
	_taken_node = "",
	armor = {
		fleshy = 100,
		water_vulnerable = 100,
	},
	_water_sensitive = true,
	view_range = 64,
	tracking_distance = 64,
	attack_type = "melee",
	pursuit_bonus = 1.15,
}

------------------------------------------------------------------------
-- Enderman visuals and mechanics.
------------------------------------------------------------------------

function enderman:despawn_allowed ()
	return (self._taken_node == "" or not self._taken_node)
		and mcl_mobs.mob_class.despawn_allowed(self)
end

function enderman:set_animation (anim, custom_speed)
	if self.attack then
		anim = "attack"
	end
	mcl_mobs.mob_class.set_animation(self, anim, custom_speed)
end

function enderman:mob_activate (staticdata, dtime)
	if not mcl_mobs.mob_class.mob_activate(self, staticdata, dtime) then
		return false
	end
	core.add_entity (self.object:get_pos(), "mcl_mobs_addon:ender_eyes")
		:set_attach(self.object, "head.top", vector.new(0,2.54,-1.99), vector.new(90,0,180))
	core.add_entity (self.object:get_pos(), "mcl_mobs_addon:ender_eyes")
		:set_attach(self.object, "head.top", vector.new(1,2.54,-1.99), vector.new(90,0,180))
	return true
end

function enderman:on_die (self_pos)
	-- Drop carried node on death
	if self._taken_node ~= nil and self._taken_node ~= "" then
		core.add_item (self_pos, self._taken_node)
	end
end

function enderman:do_custom (dtime)
	-- ARROW / DAYTIME PEOPLE AVOIDANCE BEHAVIOUR HERE.
	-- Check for arrows and people nearby.

	local enderpos = self.object:get_pos()
	enderpos.y = enderpos.y + 1.5
	for obj in core.objects_inside_radius(enderpos, 2) do
		if not core.is_player(obj) then
			local lua = obj:get_luaentity()
			if lua then
				if lua.name == "mcl_bows:arrow_entity" or lua.name == "mcl_throwing:snowball_entity" then
					self:teleport(nil)
				end
			end
		end
	end
end

function enderman:do_teleport (target)
	if target ~= nil then
		local target_pos = target:get_pos()
		-- Find all solid nodes below air in a 10×10×10 cuboid centered on the target
		local nodes = core.find_nodes_in_area_under_air(vector.subtract(target_pos, 5), vector.add(target_pos, 5), {"group:solid", "group:cracky", "group:crumbly"})
		local telepos
		if nodes ~= nil then
			if #nodes > 0 then
				-- Up to 64 attempts to teleport
				for _ = 1, math.min(64, #nodes) do
					local r = pr:next(1, #nodes)
					local nodepos = nodes[r]
					local node_ok = true
					-- Selected node needs to have 3 nodes of free space above
					for u=1, 3 do
						local node = core.get_node({x=nodepos.x, y=nodepos.y+u, z=nodepos.z})
						local ndef = core.registered_nodes[node.name]
						if ndef and ndef.walkable then
							node_ok = false
							break
						end
					end
					if node_ok then
						telepos = {x=nodepos.x, y=nodepos.y+1, z=nodepos.z}
					end
				end
				if telepos then
					telesound(self.object:get_pos(), false)
					self:halt_in_tracks (true)
					self:cancel_navigation ()
					self:teleport_safely (telepos)
					telesound(telepos, true)
				end
			end
		end
	else
		-- Attempt to randomly teleport enderman
		local pos = self.object:get_pos()
		-- Up to 8 top-level attempts to teleport
		for _ = 1, 8 do
			local node_ok = false
			-- We need to add (or subtract) different random numbers to each vector component, so it couldn't be done with a nice single vector.add() or .subtract():
			local randomCube = vector.new( pos.x + 8*(pr:next(0,8)-4), pos.y + 8*(pr:next(0,8)-4), pos.z + 8*(pr:next(0,8)-4) )
			local nodes = core.find_nodes_in_area_under_air(vector.subtract(randomCube, 4), vector.add(randomCube, 4), {"group:solid", "group:cracky", "group:crumbly"})
			if nodes ~= nil then
				if #nodes > 0 then
					-- Up to 8 low-level (in total up to 8*8 = 64) attempts to teleport
					for _ = 1, math.min(8, #nodes) do
						local r = pr:next(1, #nodes)
						local nodepos = nodes[r]
						node_ok = true
						for u=1, 3 do
							local node = core.get_node({x=nodepos.x, y=nodepos.y+u, z=nodepos.z})
							local ndef = core.registered_nodes[node.name]
							if ndef and ndef.walkable then
								node_ok = false
								break
							end
						end
						if node_ok then
							telesound(self.object:get_pos(), false)
							local telepos = {x=nodepos.x, y=nodepos.y+1, z=nodepos.z}
							self:teleport_safely (telepos)
							self:halt_in_tracks (true)
							self:cancel_navigation ()
							telesound(telepos, true)
							break
						end
					end
				end
			end
			if node_ok then
				break
			end
		end
	end
end

------------------------------------------------------------------------
-- Enderman AI
------------------------------------------------------------------------

local function is_living_damage_source (source)
	if source and source:is_player () then
		return true
	elseif source then
		local entity = source:get_luaentity ()
		return entity and entity.is_mob
	end
	return nil
end

function enderman:receive_damage (mcl_reason, damage)
	local result = mcl_mobs.mob_class.receive_damage(self, mcl_reason, damage)
	if result and not is_living_damage_source (mcl_reason.source) then
		self:teleport ()
	end
	return result
end

local function enderman_grief (self, self_pos, dtime)
	if not mobs_griefing or (self._taken_node and self._taken_node ~= "") then
		return false
	end

	local chance = math.round (20 * (dtime / 0.05))
	if pr:next (1, math.max (1, chance)) == 1 then
		local self_node_pos = {
			x = math.floor (self_pos.x + 0.5),
			y = math.floor (self_pos.y + 0.5),
			z = math.floor (self_pos.z + 0.5),
		}
		local take_pos = {
			x = math.floor (self_pos.x + 0.5 + pr:next (-2, 2)),
			y = math.floor (self_pos.y + 0.5 + pr:next (0, 3)),
			z = math.floor (self_pos.z + 0.5 + pr:next (-2, 2)),
		}
		local node = core.get_node (take_pos)
		-- Now verify that this is takable and that there is
		-- line of sight.
		if core.get_item_group (node.name, "enderman_takable") == 0 then
			return false
		end
		local los, hit_pos = self:line_of_sight (self_node_pos, take_pos)
		if los or not vector.equals (hit_pos, take_pos) then
			return false
		end
		-- Don't destroy protected stuff.
		if not core.is_protected(take_pos, "") then
			core.remove_node(take_pos)
			local dug = core.get_node_or_nil(take_pos)
			if dug and dug.name == "air" then
				self._taken_node = node.name
				local def = core.registered_nodes[self._taken_node]
				-- Update animation and texture accordingly (adds visibly carried block)
				local block_type
				-- Cube-shaped
				if def.drawtype == "normal" or
					def.drawtype == "nodebox" or
					def.drawtype == "liquid" or
					def.drawtype == "flowingliquid" or
					def.drawtype == "glasslike" or
					def.drawtype == "glasslike_framed" or
					def.drawtype == "glasslike_framed_optional" or
					def.drawtype == "allfaces" or
					def.drawtype == "allfaces_optional" or
					def.drawtype == nil then
					block_type = "cube"
				elseif def.drawtype == "plantlike" then
					-- Flowers and stuff
					block_type = "plantlike45"
				elseif def.drawtype == "airlike" then
					-- Just air
					block_type = nil
				else
					-- Fallback for complex drawtypes
					block_type = "unknown"
				end
				self.base_texture = create_enderman_textures(block_type, self._taken_node)
				self:set_textures (self.base_texture)
				self.animation = select_enderman_animation("block")
				self._current_animation = nil
				self:set_animation ("stand")
				if def.sounds and def.sounds.dug then
					core.sound_play(def.sounds.dug, {pos = take_pos, max_hear_distance = 16}, true)
				end
			end
		end
	end
	return false
end

local function enderman_ungrief (self, self_pos, dtime)
	if not mobs_griefing or not self._taken_node
		or self._taken_node == "" then
		return false
	end

	local chance = math.round (2000 * (dtime / 0.05))
	if pr:next (1, math.max (1, chance)) == 1 then
		-- Select a random position around self_pos in which
		-- to attempt to place the carried block.
		local self_x = math.floor (self_pos.x + 0.5)
		local self_z = math.floor (self_pos.z + 0.5)
		local place_pos
		repeat
			place_pos = {
				x = math.floor (self_pos.x + 0.5 + pr:next (-1, 1)),
				y = math.floor (self_pos.y + 0.5 + pr:next (0, 2)),
				z = math.floor (self_pos.z + 0.5 + pr:next (-1, 1)),
			}
		until place_pos.x ~= self_x or place_pos.z ~= self_z

		local node_below = vector.offset (place_pos, 0, -1, 0)

		-- Also check to see if protected.
		if core.get_node (place_pos).name == "air"
			and not core.is_protected (place_pos, "")
		-- and whether the node below is sturdy.
			and self:is_up_face_sturdy (node_below)
		-- and that the node below is not bedrock.
			and core.get_node (node_below).name ~= "mcl_core:bedrock" then
			-- ... but only if there's a free space
			local success = core.place_node (place_pos, {name = self._taken_node})
			if success then
				local def = core.registered_nodes[self._taken_node]
				-- Update animation accordingly (removes visible block)
				self.persistent = false
				self.animation = select_enderman_animation("normal")
				self._current_animation = nil
				self:set_animation ("stand")
				if def.sounds and def.sounds.place then
					core.sound_play(def.sounds.place, {pos = place_pos, max_hear_distance = 16}, true)
				end
				self._taken_node = ""
			end
		end
	end

	return false
end

function enderman:attack_melee (attach_pos, self_pos, dtime, target_pos,
				line_of_sight)
	local self_eye_pos = {
		x = attach_pos.x,
		y = attach_pos.y + self:get_eye_height (),
		z = attach_pos.z,
	}
	-- Freeze if the target is looking directly at this enderman.
	if self.attack:is_player ()
		and self:eye_contact (self_eye_pos, self.attack, line_of_sight) then
		self:cancel_navigation ()
		self:halt_in_tracks ()
	else
		mcl_mobs.mob_class.attack_melee(self, attach_pos, self_pos, dtime, target_pos,
					line_of_sight)
	end
end

function enderman:check_attack (self_pos, dtime, moveresult)
	local attack = mcl_mobs.mob_class.check_attack(self, self_pos, dtime, moveresult)
	if attack then
		self:set_animation ("attack")
	end
	if attack and self.attack and self.attack:is_player () then
		local target_pos = mcl_attachments.get_attachment_pos (self.attack)
		local distance = vector.distance (self_pos, target_pos)
		local self_eye_pos = {
			x = self_pos.x,
			y = self_pos.y + self:get_eye_height (),
			z = self_pos.z,
		}
		-- Attempt to break eye contact.
		if distance < 4 then
			local eye_contact = self:eye_contact (self_eye_pos, self.attack)
			if eye_contact then
				self._time_since_teleport = self._time_since_teleport + dtime
				if self._time_since_teleport > 0.25 then
					self:do_teleport ()
					self._time_since_teleport = 0
				end
			end
		elseif distance > 16 then
			self._time_since_teleport = self._time_since_teleport + dtime
			if self._time_since_teleport >= 1.5 then
				self:do_teleport (self.attack)
				self._time_since_teleport = 0
			end
		end
	end
	return attack
end


------------------------------------------------------------------------
-- Enderman target selection
------------------------------------------------------------------------

function enderman:eye_contact (eye_pos, object, line_of_sight)
	local inventory = object:get_inventory ()
	local stack = inventory:get_stack ("armor", 2)
	if stack:get_name () == "mcl_farming:pumpkin_face" then
		return false
	end

	local player_look_dir = object:get_look_dir ()
	local player_pos = mcl_util.target_eye_pos (object)
	local direction = vector.direction (player_pos, eye_pos)
	local distance = vector.distance (eye_pos, player_pos)

	if line_of_sight == nil then
		line_of_sight = self:line_of_sight (eye_pos, player_pos)
	end

	local dot = vector.dot (player_look_dir, direction)
	return dot > 1.0 - 0.025 / distance and line_of_sight
end

local dist_sqr = mcl_mobs.dist_sqr
local tmp = vector.new ()
local huge = math.huge

local function enderman_player_rule (self, self_pos, dtime, obj, is_current)
	if is_current then
		local dist = self.tracking_distance * self.tracking_distance
		return self:track_current_target (self_pos, dtime, obj, dist, 3.0)
	end

	local eye_pos = tmp
	eye_pos.x = self_pos.x
	eye_pos.y = self_pos.y + self:get_eye_height ()
	eye_pos.z = self_pos.z

	if not self._pending_target then
		local view_range = self.view_range * self.view_range
		local d = huge
		local target = nil
		for player, pos1 in mcl_player.iterate_connected_players () do
			local d1 = dist_sqr (self_pos, pos1)
			local m = self:detection_multiplier_for_object (player)
			if d1 <= view_range * m * m and d1 < d
				and self:target_visible (self_pos, player)
				and self:test_object_and_restriction (player, pos1)
				and self:eye_contact (eye_pos, player, nil) then
				d = d1
				target = player
			end
		end
		if target then
			self._pending_target = target
			self._targeting_delay = 0.25
		end
		return nil
	-- A target has been selected; if the targeting delay has also
	-- elapsed and it continues to maintain eye contact, select
	-- it, or abandon it otherwise.
	elseif not self._pending_target:is_valid ()
		or not self:eye_contact (eye_pos, self._pending_target) then
		self._pending_target = nil
		self._targeting_delay = nil
		return nil
	else
		local t = self._targeting_delay
		if t <= dtime then
			local target = self._pending_target
			self._pending_target = nil
			self._targeting_delay = nil
			return target
		end
		self._targeting_delay = t - dtime
		return nil
	end
end

function enderman:switch_targeting_rule (fn_old, fn_new)
	if not fn_old and fn_new then
		self._time_since_teleport = 0
	end
	mcl_mobs.mob_class.switch_targeting_rule(self, fn_old, fn_new)
end


------------------------------------------------------------------------
-- Enderman sundries
------------------------------------------------------------------------

local function mc_light_value (self, self_pos)
	local brightness, value
	local pos = self_pos
	brightness = (core.get_node_light (pos) or 0) / 15.0
	value = brightness / (4 - 3 * brightness)
	return value
end

function enderman:init_ai ()
	mcl_mobs.mob_class.init_ai(self)
end

function enderman:ai_step (dtime)
	mcl_mobs.mob_class.ai_step(self, dtime)
	local self_pos = self.object:get_pos ()
	if mcl_worlds.pos_to_dimension (self_pos) == "overworld"
		and core.get_timeofday () > 0.25 then
		local light = mc_light_value (self, self_pos)
		if light > 0.5 and mcl_weather.is_outdoor (self_pos)
			and math.random () * 30 < (light - 0.4) * 2.0 then
			if self.attack then
				self.attack = nil
				self:replace_activity (nil)
			end
			self:teleport ()
		end
	end
end

-- Prevent endermen from crossing water.

mcl_mobs.register_mob ("mcl_mobs_addon:enderman", enderman)

------------------------------------------------------------------------
-- Enderman spawning.
------------------------------------------------------------------------

-- spawn eggs
mcl_mobs.register_egg("mcl_mobs_addon:enderman", S("Enderman"), "#252525", "#151515", 0)

------------------------------------------------------------------------
-- Modern Enderman spawning.
------------------------------------------------------------------------

register_monster_spawn("mcl_mobs_addon:enderman", OW_MONSTERS, 1, 1, 4)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:enderman", 40, 40)
register_monster_spawn("mcl_mobs_addon:enderman", NETHER_BIOMES, 1, 1, 4, "nether")
register_monster_spawn("mcl_mobs_addon:enderman", END_BIOMES, 10, 4, 4, "end")

-- ---------------------------------------------------------------------------
-- PUFFERFISH
-- ---------------------------------------------------------------------------
local S = core.get_translator ("mobs_mc")

------------------------------------------------------------------------
-- Pufferfish.
------------------------------------------------------------------------

local pufferfish_ignored_mobs = {
	-- TODO: "mobs_mc:turtle",
	-- TODO: "mobs_mc:tadpole",
	"mobs_mc:cod",
	"mobs_mc:dolphin",
	"mobs_mc:glow_squid",
	"mobs_mc:guardian",
	"mobs_mc:guardian_elder",
	"mcl_mobs_addon:pufferfish",
	"mobs_mc:salmon",
	"mobs_mc:squid",
	"mobs_mc:tropical_fish",
}

local small_collision_box = {
	-0.175, 0, -0.175,
	0.175, 0.35, 0.175,
}

local medium_collision_box = {
	-0.245, 0, -0.245,
	0.245, 0.49, 0.245,
}

local large_collision_box = {
	-0.45, 0, -0.45,
	0.45, 0.7, 0.45,
}

local pufferfish = {
	description = S ("Pufferfish"),
	type = "animal",
	spawn_class = "passive",
	_spawn_category = "water_ambient",
	can_despawn = true,
	hp_min = 3,
	hp_max = 3,
	xp_min = 1,
	xp_max = 3,
	armor = 100,
	rotate = 0,
	collisionbox = small_collision_box,
	visual_size = { x = 1, y = 1, },
	visual = "mesh",
	head_eye_height = 0.455,
	mesh = "mobs_mc_pufferfish_small.b3d",
	textures = {
		{"mobs_mc_pufferfish.png",},
	},
	sounds = {
	},
	animation = {
		stand_start = 10,
		stand_end = 530,
	},
	drops = {
		{
			name = "mcl_fishing:pufferfish_raw",
			chance = 1,
			min = 1,
			max = 1,
		},
		{
			name = "mcl_bone_meal:bone_meal",
			chance = 20,
			min = 1,
			max = 1,
		},
	},
	runaway_from = {"players"},
	runaway_bonus_near = 1.6,
	runaway_bonus_far = 1.4,
	runaway_view_range = 8,
	makes_footstep_sound = false,
	swims = true,
	pace_height = 1.0,
	flops = true,
	breathes_in_water = true,
	runaway = true,
	_puff_state = 0,
	_puff_time = 0,
	_unpuff_time = 0,
}

------------------------------------------------------------------------
-- Pufferfish interaction.
------------------------------------------------------------------------

function pufferfish:on_rightclick (clicker)
	local bn = clicker:get_wielded_item ():get_name ()
	if bn == "mcl_buckets:bucket_water" or bn == "mcl_buckets:bucket_river_water" then
		self:safe_remove ()
		clicker:set_wielded_item ("mcl_buckets:bucket_pufferfish")
		awards.unlock (clicker:get_player_name (), "mcl:tacticalFishing")
	end
end

------------------------------------------------------------------------
-- Pufferfish visuals.
------------------------------------------------------------------------

function pufferfish:apply_puff_state (puff_state, prevent_phasing)
	local cbox, mesh
	if puff_state == 0 then
		cbox = small_collision_box
		mesh = "mobs_mc_pufferfish_small.b3d"
	elseif puff_state == 1 then
		cbox = medium_collision_box
		mesh = "mobs_mc_pufferfish_medium.b3d"
	elseif puff_state == 2 then
		cbox = large_collision_box
		mesh = "mobs_mc_pufferfish_big.b3d"
	end
	if prevent_phasing then
		self:prevent_phasing (cbox, 2.0)
	end
	self.object:set_properties ({
		collisionbox = cbox,
		mesh = mesh,
	})
	self.collisionbox = cbox
	self.base_colbox = cbox
	self.base_mesh = mesh
end

function pufferfish:update_textures ()
	self:apply_puff_state (self._puff_state, false)
	self.base_texture = {
		"mobs_mc_pufferfish.png",
	}
	self:set_textures (self.base_texture)
end

function pufferfish:do_custom (dtime)
	if self.dead then
		return
	end

	local puff = self._puff_time
	if puff > 0 then
		local next_state = 1
		if self._puff_time > 2.0 then
			next_state = 2
		end
		if next_state ~= self._puff_state then
			self._puff_state = next_state
			self:apply_puff_state (next_state, true)
		end
		self._puff_time = puff + dtime
	else
		local state = self._puff_state
		if state > 0 then
			local unpuff = self._unpuff_time
			local next_state = state
			if unpuff > 5.0 then
				next_state = 0
			elseif unpuff > 3.0 then
				next_state = 1
			end
			if next_state ~= self._puff_state then
				self._puff_state = next_state
				self:apply_puff_state (next_state, false)
			end
			self._unpuff_time = unpuff + dtime
		end
	end
end

function pufferfish:get_staticdata_table ()
	local tbl = mcl_mobs.mob_class.get_staticdata_table(self)
	if tbl then
		tbl._puff_time = 0
		tbl._unpuff_time = 0
	end
	return tbl
end

------------------------------------------------------------------------
-- Pufferfish AI.
------------------------------------------------------------------------

local indexof = table.indexof

local function valid_pufferish_target_p (self, object)
	if object == self.object then
		return false
	elseif object:is_player () then
		local name = object:get_player_name ()
		return not core.is_creative_enabled (name)
	else
		local entity = object:get_luaentity ()
		return entity and entity.is_mob
			and indexof (pufferfish_ignored_mobs, entity.name) == -1
	end
end

function pufferfish:ai_step (dtime)
	mcl_mobs.mob_class.ai_step(self, dtime)
	if self._puff_state >= 1
		and self:check_timer ("check_damage", 0.5) then
		local damage = self._puff_state + 1
		local duration = 3 * self._puff_state
		local self_pos = self.object:get_pos ()
		for object in core.objects_inside_radius (self_pos, 1.5) do
			if valid_pufferish_target_p (self, object) then
				local reason = {
					source = self.object,
					type = "mob",
				}
				mcl_damage.finish_reason (reason)
				mcl_util.deal_damage (object, damage, reason)
				mcl_potions.give_effect_by_level ("poison", object, 1, duration)
			end
		end
	end
end

local mathmax = math.max

local function pufferfish_defend_self (self, self_pos, dtime)
	if self:check_timer ("pufferfish_survey", 0.5) then
		local located = false
		for object in core.objects_inside_radius (self_pos, 2.5) do
			if valid_pufferish_target_p (self, object) then
				located = true
				break
			end
		end

		if located then
			self._puff_time = mathmax (self._puff_time, 0.05)
			self._unpuff_time = 0.0
		else
			self._puff_time = 0.0
		end
	end
end


mcl_mobs.register_mob ("mcl_mobs_addon:pufferfish", pufferfish)

------------------------------------------------------------------------
-- Modern Pufferfish spawning.
------------------------------------------------------------------------

register_monster_spawn("mcl_mobs_addon:pufferfish", OCEAN_BIOMES, 10, 1, 3)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:pufferfish", 6, 6)

-- ---------------------------------------------------------------------------
-- RAVAGER
-- ---------------------------------------------------------------------------
local S = core.get_translator ("mobs_mc")
local raid_mob = {}  -- raid system not ported (Mineclonia-only)

local ipairs = ipairs

------------------------------------------------------------------------
-- Ravager.
-- TODO:
-- [X] Pathfinding rules.
-- [X] Animations & particle effects.
-- [X] Roar attacks and additional knockback.
-- [X] Mounting.
-- [X] Drops.
-- [X] Raid spawning.
------------------------------------------------------------------------

local ravager = table.merge (raid_mob, {
	description = S ("Ravager"),
	type = "monster",
	spawn_class = "hostile",
	attack_player = true,
	_spawn_category = "monster",
	hp_min = 100,
	hp_max = 100,
	xp_min = 20,
	xp_max = 20,
	visual = "mesh",
	mesh = "mobs_mc_ravager.b3d",
	textures = {
		{
			"mobs_mc_ravager.png",
		},
	},
	collisionbox = {
		-0.975, 0, -0.975,
		0.975, 2.2, 0.975,
	},
	sounds = {},
	movement_speed = 6.0,
	knockback_resistance = 0.75,
	damage = 12.0,
	attack_type = "melee",
	_attack_knockback = 1.5,
	view_range = 32,
	tracking_distance = 32,
	stepheight = 1.02,
	can_ride_boat = false,
	reach = 2.0,
	pace_bonus = 0.4,
	animation = {
		stand_start = 0,
		stand_end = 0,
		walk_start = 20,
		walk_end = 40,
		walk_speed = 20,
	},
	drops = {
		{
			name = "mcl_mobitems:saddle",
			chance = 1,
			min = 1,
			max = 1,
		},
	},

	-- Patrolling mob parameters.
	_can_serve_as_captain = false,

	-- Ravager parameters.
	_roar_time = 0,
	_attack_time = 0,
	_stunned_time = 0,
})

------------------------------------------------------------------------
-- Ravager visuals.
------------------------------------------------------------------------

local HEAD_BONE_OVERRIDE = {
	rotation = {
		vec = vector.new (),
		interpolation = 0.1,
	},
	position = {
		vec = vector.new (),
		interpolation = 0,
	},
}

local mathatan2 = math.atan2
local mathsqrt = math.sqrt

local NINETY_DEG = math.pi / 2
local SEVENTY_DEG = math.rad (70)
local norm_radians = mcl_util.norm_radians
local mathmax = math.max
local mathmin = math.min
local mathabs = math.abs
local mathsin = math.sin

local TICKS_PER_SEC = 20
local mathpow = math.pow

local function lerp1d_scaled (u, dtime, s1, s2)
	local x = dtime * TICKS_PER_SEC
	local v = -(s2 * mathpow (1 - u, x))
		+ s1 * mathpow (1 - u, x) + s2
	return v
end

local function lerp_rotation_scaled (u, dtime, s1, s2)
	local diff = norm_radians (s2 - s1)
	local s = lerp1d_scaled (u, dtime, s1, s1 + diff)
	return norm_radians (s)
end

function ravager:check_head_swivel (attach_pos, dtime, clear)
	if clear then
		self._locked_object = nil
	else
		self:who_are_you_looking_at ()
	end

	local object = self._locked_object
	local tbl = HEAD_BONE_OVERRIDE
	local zrot
	local xrot

	if not object or not object:is_valid ()
		or object:get_hp () == 0 then
		zrot = 0
		xrot = 0
	else
		local pos = mcl_util.target_eye_pos (object)
		local dx = pos.x - attach_pos.x
		local dz = pos.z - attach_pos.z
		local dy = pos.y - attach_pos.y
		local yaw = mathatan2 (dz, dx)
			- NINETY_DEG - self:get_yaw ()
		local yaw = norm_radians (-yaw)
		local pitch = mathatan2 (dy, mathsqrt (dx * dx + dz * dz))
		if mathabs (yaw) > NINETY_DEG then
			zrot = 0
			xrot = 0
		else
			xrot = mathmin (mathmax (pitch * 0.5, -SEVENTY_DEG), SEVENTY_DEG)
			zrot = mathmin (mathmax (yaw, -SEVENTY_DEG), SEVENTY_DEG)
		end
	end
	local last_z = self._ravager_zrot or zrot
	local last_x = self._ravager_xrot or xrot
	xrot = lerp_rotation_scaled (0.2, dtime, last_x, xrot)
	zrot = lerp_rotation_scaled (0.2, dtime, last_z, zrot)
	tbl.rotation.vec.z = zrot
	tbl.rotation.vec.x = xrot
	if self:animate_head (tbl)
		or self._ravager_zrot ~= zrot
		or self._ravager_xrot ~= xrot then
		self._ravager_zrot = zrot
		self._ravager_xrot = xrot
		self.object:set_bone_override ("head", tbl)
	end
end

function ravager:get_staticdata_table ()
	local tbl = mcl_mobs.mob_class.get_staticdata_table(self)
	if tbl then
		tbl._ravager_zrot = nil
		tbl._ravager_yrot = nil
	end
	return tbl
end

function ravager:ravager_fumes ()
	core.add_particlespawner ({
		amount = 20,
		time = 2.0,
		size = 1.4,
		texture = "mcl_particles_effect.png^[colorize:#a9a9a9:255",
		pos = {
			min = vector.new (-1.0, -2.0, -1.0),
			max = vector.new (1.0, 2.0, 1.0),
		},
		vel = {
			min = vector.new (-0.8, 0.8, -0.8),
			max = vector.new (0.8, 1.2, 0.8),
		},
		exptime = {
			min = 3.0,
			max = 3.0,
		},
		attached = self.object,
	})
end

function ravager:ravager_explosion ()
	core.add_particlespawner ({
		amount = 32,
		time = 0.1,
		size = {
			min = 1.2,
			max = 2.0,
		},
		texture = "mcl_particles_mob_death.png^[colorize:#c5c5c5c5:255",
		pos = {
			min = vector.new (-2, 0, -2),
			max = vector.new (2, 0, 2),
		},
		vel = {
			min = vector.new (-4.0, -4.0, -4.0),
			max = vector.new (4.0, 4.0, 4.0),
		},
		exptime = {
			min = 2.0,
			max = 2.0,
		},
		attached = self.object,
	})
end

local THIRTY_DEG = math.rad (30)

local RAVAGER_MOUTH_OPEN_OVERRIDE = {
	rotation = {
		vec = vector.new (-THIRTY_DEG, 0, 0),
		interpolation = 0.25,
	}
}
local RAVAGER_MOUTH_DEFAULT_OVERRIDE = {
	rotation = {
		vec = vector.zero (),
		interpolation = 0.25,
	},
}

function ravager:animate_bite ()
	self.object:set_bone_override ("mouth", RAVAGER_MOUTH_OPEN_OVERRIDE)
end

function ravager:animate_mouth (dtime)
	if self._attack_time >= 0.25
		and self._attack_time - dtime < 0.25 then
		self.object:set_bone_override ("mouth", RAVAGER_MOUTH_DEFAULT_OVERRIDE)
	end
end

local pi = math.pi

function ravager:animate_head (transform)
	if self._stunned_time > 0.0 then
		local t = mathmin (2.0, 2.0 - self._stunned_time)
		local x_pos = mathsin (t * pi)
		transform.rotation.vec.z = 0.0
		transform.rotation.vec.x = -THIRTY_DEG
		transform.position.vec.x = x_pos * 3.0
		return true
	else
		transform.position.vec.x = 0.0
		return false
	end
end

------------------------------------------------------------------------
-- Ravager AI.
------------------------------------------------------------------------

local floor = math.floor

function ravager:ravager_no_movement ()
	return self._roar_time > 0
		or self._attack_time > 0
		or self._stunned_time > 0
end

function ravager:ravager_knockback (self_pos, object)
	local pos = object:get_pos ()
	local dx = pos.x - self_pos.x
	local dz = pos.z - self_pos.z
	if mcl_util.object_has_mc_physics (object) then
		local d_sqr = mathmax (dx * dx + dz * dz, 0.001)
		local v = vector.new (dx / d_sqr * 80.0, 4.0,
				      dz / d_sqr * 80.0)
		object:add_velocity (v)
	else
		local d = mathsqrt (dx * dx + dz * dz)
		local v = vector.new (dx / d * 10.0, 4.0,
				      dz / d * 10.0)
		object:add_velocity (v)
	end
end

function ravager:ravager_attack ()
	local self_pos = self.object:get_pos ()
	local v1 = vector.new (self.collisionbox[1] - 4.0 + self_pos.x,
			       self.collisionbox[2] - 4.0 + self_pos.y,
			       self.collisionbox[3] - 4.0 + self_pos.z)
	local v2 = vector.new (self.collisionbox[4] + 4.0 + self_pos.x,
			       self.collisionbox[5] + 4.0 + self_pos.y,
			       self.collisionbox[6] + 4.0 + self_pos.z)
	for object in core.objects_in_area (v1, v2) do
		local entity = object:get_luaentity ()
		local is_alive = false

		if (entity and entity ~= self and entity.is_mob)
			or object:is_player () then
			is_alive = true
			if not entity or not entity._is_illager then
				local mcl_reason = {
					type = "mob",
					direct = self.object,
				}
				mcl_damage.finish_reason (mcl_reason)
				mcl_util.deal_damage (object, 6.0, mcl_reason)
			end
		end

		if is_alive
		-- The object may have been deleted.
			and object:is_valid () then
			self:ravager_knockback (self_pos, object)
		end
	end

	self:ravager_explosion ()
end

function ravager:ai_step (dtime)
	raid_mob.ai_step (self, dtime)
	if self.dead then
		return
	end

	if self:ravager_no_movement () then
		-- Velocity rescaling can't adapt to a movement_speed
		-- of 0.
		self:set_physics_factor_base ("movement_speed", 0.001)
	else
		local target = self.attack and 7.0 or 6.0
		local speed = self:stock_value ("movement_speed")
		local value = lerp1d_scaled (0.1, dtime, speed, target)
		self:set_physics_factor_base ("movement_speed", value)
	end

	self:animate_mouth (dtime)
	if self._roar_time > 0 then
		local t = self._roar_time
		self._roar_time = self._roar_time - dtime
		if t >= 0.5 and t - dtime < 0.5 then
			self:ravager_attack ()
		end
	end
	if self._attack_time > 0 then
		self._attack_time = self._attack_time - dtime
	end
	if self._stunned_time > 0 then
		self._stunned_time = self._stunned_time - dtime
		if self._stunned_time < 0 then
			self._roar_time = 1.0
		end
	end
end

local mathsqrt = math.sqrt

function ravager:shield_impact (object, mcl_reason)
	if self._roar_time <= 0 then
		if math.random (2) == 1 then
			self._stunned_time = 2.0
			self:ravager_fumes ()
			local pos = object:get_pos ()
			local self_pos = self.object:get_pos ()
			if pos then
				local dir = vector.direction (pos, self_pos)
				local dist = vector.distance (pos, self_pos)
				local v = vector.multiply (dir, 10.0 / mathsqrt (dist))
				self.object:add_velocity (v)
			end
		else
			local self_pos = self.object:get_pos ()
			-- Otherwise the default knockback is more
			-- than adequate to repulse the player.
			if mcl_util.object_has_mc_physics (object) then
				self:ravager_knockback (self_pos, object)
			end
		end
	end
end

function ravager:pre_melee_attack (distance, delay, line_of_sight)
	return self._stunned_time <= 0
		and self._roar_time <= 0
		and mcl_mobs.mob_class.pre_melee_attack(self, distance, delay,
						line_of_sight)
end

function ravager:custom_attack ()
	mcl_mobs.mob_class.custom_attack(self)
	self._attack_time = 0.5
	self:animate_bite ()
end


local function adult_villager_p (self, self_pos, obj, entity)
	return entity
		and (entity.name == "mobs_mc:villager"
		     or entity.name == "mobs_mc:wandering_trader")
		and not entity.child
end


------------------------------------------------------------------------
-- Ravager pathfinding & navigation.
------------------------------------------------------------------------



local function any_horiz_collision (moveresult)
	for _, item in ipairs (moveresult.collisions) do
		if item.axis == "x" or item.axis == "z" then
			-- Exclude ignore nodes from collision detection.
			if item.type == "node"
				and core.get_node_or_nil (item.node_pos) then
				return true
			end
		end
	end
	return false
end

local LEAVES = {
	"group:leaves",
}

function ravager:destroy_colliding_leaves ()
	local cbox = self.collisionbox
	local self_pos = self.object:get_pos ()
	local v1 = vector.new (floor (cbox[1] - 0.2 + self_pos.x + 0.5),
			       floor (cbox[2] - 0.2 + self_pos.y + 0.5),
			       floor (cbox[3] - 0.2 + self_pos.z + 0.5))
	local v2 = vector.new (floor (cbox[4] + 0.2 + self_pos.x + 0.5),
			       floor (cbox[5] + 1.5 + self_pos.y + 0.5),
			       floor (cbox[6] + 0.2 + self_pos.z + 0.5))
	local any_dug = false
	for _, pos in ipairs (core.find_nodes_in_area (v1, v2, LEAVES)) do
		if not core.is_protected (pos, "") then
			core.dig_node (pos, self.object)
			any_dug = true
		end
	end

	return any_dug
end

function ravager:movement_step (dtime, moveresult)
	if self:ravager_no_movement () then
		self:halt_in_tracks (nil, true)
		return
	end
	if not self.dead
	-- If there is a horizontal collision...
		and any_horiz_collision (moveresult)
	-- ... don't process movement for another step, in order to
	-- decide whether the deletion of the leaves has sufficed to
	-- eliminate the obstruction.
		and self:destroy_colliding_leaves () then
		return
	end
	mcl_mobs.mob_class.movement_step(self, dtime, moveresult)
end

function ravager:gwp_initialize (targets, range, tolerance, penalties)
	local context = mcl_mobs.mob_class.gwp_initialize(self, targets, range,
						  tolerance, penalties)
	if context then
		-- Offset positions of all nodes so that they reside
		-- within their centers, to prevent ravagers from
		-- spinning endlessly if they find themselves above
		-- leaves which have been ignored by the pathfinder.
		context.y_offset = 0
		return context
	end
	return nil
end

------------------------------------------------------------------------
-- Ravager spawning.
------------------------------------------------------------------------

mcl_mobs.register_mob ("mcl_mobs_addon:ravager", ravager)

-- Spawn eggs.
mcl_mobs.register_egg ("mcl_mobs_addon:ravager", S ("Ravager"), "#757470", "#5b5049")

------------------------------------------------------------------------
-- Modern Ravager spawning.
------------------------------------------------------------------------
-- no natural spawn (MC: raid-only); egg only

-- ---------------------------------------------------------------------------
-- WANDERING TRADER
-- ---------------------------------------------------------------------------
local modname = core.get_current_modname ()
local S = core.get_translator (modname)
local villager_base = {}
local is_valid = mcl_util.is_valid_objectref

------------------------------------------------------------------------
-- Wandering Trader.
------------------------------------------------------------------------

local wandering_trader = table.merge (villager_base, {
	type = "animal",
	spawn_class = "passive",
       description = S ("Wandering Trader"),
       textures = {
	       "mobs_mc_villager_wandering_trader.png",
       },
       runaway_from = {
	       "mobs_mc:zombie",
	       "mobs_mc:baby_zombie",
	       "mobs_mc:husk",
	       "mobs_mc:baby_husk",
	       "mobs_mc:drowned",
	       "mobs_mc:baby_drowned",
	       "mobs_mc:evoker",
	       "mobs_mc:vindicator",
	       "mobs_mc:vex",
	       "mobs_mc:pillager",
	       "mobs_mc:illusioner",
	       "mobs_mc:zoglin",
       },
       runaway = true,
       runaway_bonus_near = 0.5,
       runaway_bonus_far = 0.5,
       run_bonus = 0.5,
       restriction_bonus = 0.35,
       pace_bonus = 0.35,
       movement_speed = 14.0,
       wielditem_drop_probability = 0.085,
       _life_timer = nil,
})

------------------------------------------------------------------------
-- Wandering Trader trading.
------------------------------------------------------------------------

local function get_random_color ()
	local _, color = table.random_element (mcl_dyes.colors)
	return color
end

local function get_random_dye ()
	return "mcl_dyes:"..get_random_color ()
end

local function get_wood_sapling (wood, p)
	return p.saplingdrop or ("mcl_trees:sapling_" .. wood)
end

local function is_trading_wood (wood, p)
	local sap = get_wood_sapling (wood, p)
	local def = core.registered_nodes[sap]
	return def and not def._unobtainable
end

local function get_random_tree ()
	local _, wood = table.random_element (mcl_trees.woods, is_trading_wood)
	return "mcl_trees:tree_" .. wood
end

local function get_random_sapling ()
	local p, wood = table.random_element (mcl_trees.woods, is_trading_wood)
	return get_wood_sapling (wood, p)
end

local function get_random_flower ()
	local _, flower
		= table.random_element (mcl_flowers.registered_simple_flowers)
	return flower
end

local function E (f, t)
	return { "mcl_core:emerald", f or 1, t or f or 1 }
end

local trades_purchasing_table = {
	{ { "mcl_potions:water", 1, 1, }, E(), 1, 0 },
	{ { "mcl_buckets:bucket_water", 1, 1, }, E(2), 1, 0 },
	{ { "mcl_mobitems:milk_bucket", 1, 1, }, E(2), 1, 0 },
	{ { "mcl_potions:fermented_spider_eye", 1, 1, }, E(3), 1, 0 },
	{ { "mcl_farming:potato_item_baked", 1, 1, }, E(1), 1, 0 },
	{ { "mcl_farming:hay_block", 1, 1, }, E(1), 1, 0 },
}

local trades_special_table = {
	{ E(), { "mcl_core:packed_ice", 1, 1, }, 6, 0 },
	{ E(6), { "mcl_core:blue_ice", 1, 1, }, 6, 0 },
	{ E(), { "mcl_mobitems:gunpowder", 4, 4, }, 2, 0 },
	{ E(), { get_random_tree, 8, 8, }, 6, 0 },
	{ E(3), { "mcl_core:podzol", 3, 3, }, 6, 0 },
	{ E(5), { "mcl_core:ice", 1, 1, }, 6, 0 },
	{ E(6), { "mcl_potions:invisibility", 1, 1, }, 1, 0 },
	{ E(6, 20), { "mcl_tools:pick_iron_enchanted", 1, 1 } },
}

local trades_ordinary_table = {
	{ E(), { "mcl_flowers:fern", 1, 1, }, 12, 0 },
	{ E(), { "mcl_core:reeds", 1, 1, }, 8, 0 },
	{ E(), { "mcl_farming:pumpkin", 1, 1, }, 4, 0 },
	{ E(), { get_random_flower, 1, 1, }, 12, 0 },

	{ E(), { "mcl_pale_oak:hanging_moss", 1, 1, }, 4, 0 },
	{ E(), { "mcl_farming:wheat_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:beetroot_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:pumpkin_seeds", 1, 1, }, 12, 0 },
	{ E(), { "mcl_farming:melon_seeds", 1, 1, }, 12, 0 },
	{ E(), { get_random_dye, 1, 1, }, 12, 0 },
	{ E(), { "mcl_core:vine", 3, 3, }, 4, 0 },
	{ E(), { "mcl_flowers:waterlily", 3, 3, }, 2, 0 },
	{ E(), { "mcl_core:sand", 3, 3, }, 8, 0 },
	{ E(), { "mcl_core:redsand", 3, 3, }, 6, 0 },
	{ E(), { "mcl_lush_caves:dripleaf_small", 2, 2, }, 5, 0 },
	{ E(), { "mcl_mushrooms:mushroom_brown", 3, 3, }, 4, 0 },
	{ E(), { "mcl_mushrooms:mushroom_red", 3, 3, }, 4, 0 },
	{ E(), { "mcl_dripstone:pointed_dripstone", 2, 5, }, 5, 0 },
	{ E(), { "mcl_lush_caves:rooted_dirt", 2, 2, }, 5, 0 },
	{ E(), { "mcl_lush_caves:moss", 2, 2, }, 5, 0 },
	{ E(2), { "mcl_ocean:sea_pickle_1_dead_brain_coral_block", 1, 1, }, 5, 0 },
	{ E(2), { "mcl_nether:glowstone", 1, 5, }, 5, 0 },
	{ E(3), { "mcl_buckets:bucket_tropical_fish", 1, 1, }, 4, 0 },
	{ E(3), { "mcl_buckets:bucket_pufferfish", 1, 1, }, 4, 0 },
	{ E(3), { "mcl_ocean:kelp", 1, 1, }, 12, 0 },
	{ E(3), { "mcl_core:cactus", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:brain_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:tube_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:bubble_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:fire_coral_block", 1, 1, }, 8, 0 },
	{ E(3), { "mcl_ocean:horn_coral_block", 1, 1, }, 8, 0 },
	{ E(4), { "mcl_mobitems:slimeball", 1, 1, }, 5, 0 },
	{ E(5), { get_random_sapling, 8, 8, }, 8, 0 },
	{ E(5), { "mcl_mobitems:nautilus_shell", 1, 1, }, 5, 0 },
}

local pr = PcgRandom (os.time () + 593)

local function get_wandering_trades ()
	if not (mobs_mc and mobs_mc.trade_from_table) then return {} end
	local purch = table.copy (trades_purchasing_table)
	local speci = table.copy (trades_special_table)
	local ordin = table.copy (trades_ordinary_table)
	local t = {}
	for _ = 1, 2 do
		local trade = table.remove (purch, math.random (#purch))
		table.insert (t, mobs_mc.trade_from_table (pr, trade, false))
		local trade = table.remove (speci, math.random (#speci))
		table.insert (t, mobs_mc.trade_from_table (pr, trade, false))
	end
	for _ = 1, 5 do
		local trade = table.remove (ordin, math.random (#ordin))
		table.insert (t, mobs_mc.trade_from_table (pr, trade, false))
	end
	return t
end

function wandering_trader:on_spawn ()
	if self.update_trades then
		self:update_trades (get_wandering_trades ())
	end
end

function wandering_trader:on_rightclick (clicker)
	local clicker_pos = clicker:get_pos ()
	local self_pos = self.object:get_pos ()

	if vector.distance (clicker_pos, self_pos) < 16 then
		self:show_trade_formspec (clicker, 0)
	end
end

function wandering_trader:show_trade_progress_bar ()
	return false
end

function wandering_trader:actionable_on_rightclick (player)
	return true
end

------------------------------------------------------------------------
-- Wandering Trader AI.
------------------------------------------------------------------------

function wandering_trader:mob_activate (staticdata, dtime)
	if not mcl_mobs.mob_class.mob_activate (self, staticdata, dtime) then
		return false
	end
	self._llamas = {}
	self._provide_owner = function ()
		return is_valid (self.object) and self.object
	end
	return true
end

function wandering_trader:get_staticdata_table ()
	if not villager_base.get_staticdata_table then return {} end
	local supertable = villager_base.get_staticdata_table (self)
	if supertable then
		supertable._llamas = nil
	end
	return supertable
end

function wandering_trader:ai_step (dtime)
	mcl_mobs.mob_class.ai_step(self, dtime)
	if self._life_timer then
		self._life_timer = self._life_timer - dtime
		if self._life_timer <= 0 then
			self:safe_remove ()
		end
	end
	local is_day = mcl_util.is_daytime ()
	if not self._mob_invisible and not is_day then
		local wielditem = self:get_wielditem ()
		if not self._using_wielditem
			or wielditem:get_name () ~= "mcl_potions:invisibility" then
			self:set_wielditem (ItemStack ("mcl_potions:invisibility"))
			self:use_wielditem ()
		elseif self._using_wielditem > 1.0 then
			mcl_hunger.play_drinking_sound(self.object)
			mcl_potions.give_effect ("invisibility", self.object,
						 0, math.huge)
			self:set_wielditem (ItemStack ())
		end
	elseif self._mob_invisible and is_day then
		local wielditem = self:get_wielditem ()
		if not self._using_wielditem
			or wielditem:get_name () ~= "mcl_mobitems:milk_bucket" then
			self:set_wielditem (ItemStack ("mcl_mobitems:milk_bucket"))
			self:use_wielditem ()
		elseif self._using_wielditem > 1.0 then
			mcl_potions._reset_effects (self.object)
			mcl_hunger.play_drinking_sound(self.object)
			self:set_wielditem (ItemStack ())
		end
	end

	local valid_llamas = {}
	-- Delete invalid llamas.
	for _, llama in pairs (self._llamas) do
		if is_valid (llama) then
			table.insert (valid_llamas, llama)
		end
	end
	-- Search within a 16 node radius for llamas belonging to this
	-- trader.  TODO: revisit this once leashes are available.
	if #valid_llamas < 2
		and self:check_timer ("locate_llamas", 0.5) then
		local self_pos = self.object:get_pos ()
		for object in core.objects_inside_radius (self_pos, 16) do
			local entity = object:get_luaentity ()
			if entity and entity.name == "mcl_mobs_addon:trader_llama"
				and entity._trader_id == self._trader_id then
				entity._get_owner = self._provide_owner
				table.insert (valid_llamas, object)
			end
		end
	end
	self._llamas = valid_llamas
end

local function is_mob (source)
	local entity = source:get_luaentity ()
	return entity and entity.is_mob
end

function wandering_trader:receive_damage (mcl_reason, damage)
	if mcl_mobs.mob_class.receive_damage(self, mcl_reason, damage) then
		if mcl_reason.source
			and (mcl_reason.source:is_player ()
			     or is_mob (mcl_reason.source)) then
			-- Call llamas to retaliate.
			for _, llama in pairs (self._llamas) do
				local entity = llama:get_luaentity ()
				if entity then
					entity:receive_attack (mcl_reason.source)
				end
			end
		end
		return true
	end
	return false
end

local function wandering_trader_check_trading (self, self_pos, dtime, moveresult)
	if self._halted_for_trading then
		if self._immersion_depth >= 1
			or (not moveresult.touching_ground
				and not moveresult.standing_on_object
				and not self.object:get_attach ())
			or self.runaway_timer >= 4.5 then
			self:stop_trading ()
			self._halted_for_trading = false
			return false
		elseif not self:is_trading () then
			self._halted_for_trading = false
			return false
		else
			local dist_min = math.huge
			for player, _ in pairs (self._trading_with) do
				if is_valid (player) then
					local pos = player:get_pos ()
					local d = vector.distance (pos, self_pos)
					if d > 16 then
						local name = player:get_player_name ()
						local formname = "mobs_mc:trading_formspec"
						mobs_mc.return_trading_fields (player)
						core.close_formspec (name, formname)
						self._trading_with[player] = nil
					end
					dist_min = math.min (d, dist_min)
				end
			end
			if dist_min > 16 then
				self._halted_for_trading = false
				return false
			end
			return true
		end
	elseif self:is_trading () then
		self:cancel_navigation ()
		self:halt_in_tracks ()
		self._halted_for_trading = true
		return "_halted_for_trading"
	end
	return false
end

local function wandering_trader_check_wander (self, self_pos, dtime)
	if self._wandering_to_target then
		if self:navigation_finished () then
			local distance
				= vector.distance (self_pos, self._wander_last_pos)
			local target_dist
				= vector.distance (self_pos, self._wander_to)
			if target_dist <= 2.0 then
				self:cancel_navigation ()
				self:halt_in_tracks ()
				self._wander_to = nil
				self._wander_last_pos = nil
				self._wandering_to_target = false
				return false
			end
			if distance < 1.0 then
				self._wander_retries
					= (self._wander_retries or 0) + 1

				-- Give up.
				if self._wander_retries > 3 then
					self._wander_to = nil
					self._wander_last_pos = nil
					self._wandering_to_target = false
					return false
				end
			end
			self._wander_last_pos = self_pos
			self:gopath (self._wander_to, 0.35)
		end
		return true
	elseif self._wander_to then
		self:gopath (self._wander_to, 0.35)
		self._wandering_to_target = true
		self._wander_last_pos = self_pos
		self._wander_retries = 0
		return true
	end
	return false
end


------------------------------------------------------------------------
-- Upgrading old traders.
------------------------------------------------------------------------

local function convert_old_trades (tradestring)
	if type (tradestring) ~= "string" then
		return {}
	end
	local trades = core.deserialize (tradestring)
	local new_trades = {}
	for _, trade in ipairs (trades) do
		local trade_object = mobs_mc.make_villager_trade ({
			wanted1 = trade.wanted[1],
			wanted2 = trade.wanted[2] or "",
			offered = ItemStack (trade.offered):to_string (),
			uses = trade.trade_counter or 0,
			max_uses = trade.max_uses or 12,
			reward_xp = false,
		})
		table.insert (new_trades, trade_object)
	end
	return new_trades
end

function wandering_trader:post_load_staticdata ()
	mcl_mobs.mob_class.post_load_staticdata(self)
	if self._trades and type (self._trades) ~= "table" then
		self._trades = convert_old_trades (self._trades, self._tier)
	end
end

mcl_mobs.register_mob ("mcl_mobs_addon:wandering_trader", wandering_trader)

------------------------------------------------------------------------
-- Wandering Trader spawning.
------------------------------------------------------------------------

local storage = core.get_mod_storage ()

local function spawn_one_llama (around, entity)
	for i = 1, 10 do
		local dx = pr:next (-4, 4)
		local dz = pr:next (-4, 4)
		local pos = vector.offset (around, dx, 0, dz)
		local surface = mobs_mc.find_surface_position (pos)
		local llama = mcl_mobs.spawn_abnormally (surface, "mcl_mobs_addon:trader_llama",
							 nil, "trader_spawning")
		if llama then
			local llama = llama:get_luaentity ()
			llama._trader_id = entity._trader_id
			llama._get_owner = entity._provide_owner
			llama._life_timer = entity._life_timer
			table.insert (entity._llamas, llama.object)
			return
		end
	end
end

local function spawn_llamas (surface, entity)
	entity._llamas = {}
	spawn_one_llama (surface, entity)
	spawn_one_llama (surface, entity)
end

local function spawn_wandering_trader ()
	-- Select a random player in the overworld.
	local players_in_overworld = {}
	for player in mcl_util.connected_players () do
		local pos = player:get_pos ()
		local dim = mcl_worlds.pos_to_dimension (pos)

		if dim == "overworld" then
			table.insert (players_in_overworld, player)
		end
	end
	local nplayers = #players_in_overworld
	if nplayers == 0 then
		return true
	elseif pr:next (1, 10) ~= 1 then
		return false
	end
	local player = players_in_overworld[pr:next (1, nplayers)]

	-- Find nearby bells.
	local player_pos = mcl_util.get_nodepos (player:get_pos ())
	local aa = vector.offset (player_pos, -48, -48, -48)
	local bb = vector.offset (player_pos, 48, 48, 48)

	-- Try to spawn beside a meeting point POI, if any.
	local poi = nil
	local pois = mcl_villages.get_pois_in_by_nodepos (aa, bb)
	table.shuffle (pois)
	for _, poi1 in pairs (pois) do
		if poi1.data == "mcl_villages:bell"
			or poi1.data == "mcl_villages:demo_poi" then
			poi = poi1.min
			break
		end
	end

	-- Locate a valid surface spawn position.
	local base_position = poi or player_pos
	for i = 1, 10 do
		local dx = pr:next (-48, 48)
		local dz = pr:next (-48, 48)
		local pos = vector.offset (base_position, dx, 0, dz)
		local surface = mobs_mc.find_surface_position (pos)

		-- Spawn a trader and attempt to link llamas to the
		-- same.
		local trader = mcl_mobs.spawn_abnormally (surface,
							  "mcl_mobs_addon:wandering_trader",
							  nil, "trader_spawning")
		if trader then
			local trader_id = storage:get_int ("last_trader_id") + 1
			storage:set_int ("last_trader_id", trader_id)
			local entity = trader:get_luaentity ()
			entity._life_timer = 1200
			entity._trader_id = trader_id
			entity._wander_to = base_position
			entity:restrict_to (base_position, 16)
			spawn_llamas (surface, entity)
			return true
		end
	end
	return false
end

mobs_mc.spawn_wandering_trader = spawn_wandering_trader

if core.settings:get_bool ("mobs_spawn", true) then

local local_spawn_counter = 60

core.register_globalstep (function (dtime)
	local_spawn_counter = local_spawn_counter - dtime
	if local_spawn_counter < 0 then
		local_spawn_counter = 60
		local level_spawn_counter
			= storage:get_int ("trader_spawn_delay") - 60
		local level_spawn_chance
			= storage:get_int ("trader_spawn_chance") + 25
		if level_spawn_chance > 75 then
			level_spawn_chance = 75
		elseif level_spawn_chance < 25 then
			level_spawn_chance = 25
		end

		if level_spawn_counter <= -1200 then
			level_spawn_counter = 0

			if pr:next (1, 100) < level_spawn_chance then
				if spawn_wandering_trader () then
					level_spawn_chance = 25
				end
			end
		end

		storage:set_int ("trader_spawn_chance", level_spawn_chance)
		storage:set_int ("trader_spawn_delay", level_spawn_counter)
	end
end)

end

mcl_mobs.register_egg ("mcl_mobs_addon:wandering_trader", S("Wandering Trader"), "#1E90FF", "#bc8b72", 0)


------------------------------------------------------------------------------
-- Trader Llama.
------------------------------------------------------------------------------

local llama = mobs_mc.llama

local trader_llama = table.merge (llama, {
	type = "animal",
	spawn_class = "passive",
	description = S ("Trader Llama"),
	textures = {
		{
			"blank.png",
			"mobs_mc_llama_decor_wandering_trader.png",
			"mobs_mc_llama_brown.png",
		},
		{
			"blank.png",
			"mobs_mc_llama_decor_wandering_trader.png",
			"mobs_mc_llama_creamy.png",
		},
		{
			"blank.png",
			"mobs_mc_llama_decor_wandering_trader.png",
			"mobs_mc_llama_gray.png",
		},
		{
			"blank.png",
			"mobs_mc_llama_decor_wandering_trader.png",
			"mobs_mc_llama_white.png",
		},
		{
			"blank.png",
			"mobs_mc_llama_decor_wandering_trader.png",
			"mobs_mc_llama.png",
		},
	},
	persistent = true,
	_default_decor_texture = "mobs_mc_llama_decor_wandering_trader.png",
})

function trader_llama:allow_mount ()
	return self:_get_owner () == nil
end

function trader_llama:_get_owner ()
	return nil
end

function trader_llama:is_leashed ()
	-- TODO: revise this once leashes are introduced.
	return self:_get_owner () ~= nil
end

-- XXX: revisit this function once leashes are implemented.
local function trader_llama_follow_owner (self, self_pos, dtime)
	if self._following_owner then
		local owner = self:_get_owner ()
		if not owner then
			self._following_owner = false
			return false
		end
		local owner_pos = owner:get_pos ()
		if vector.distance (self_pos, owner_pos) < 6.0 then
			self._following_owner = false
			self:look_at (owner_pos)
			return false
		end

		if self:check_timer ("follow_owner", 0.5) then
			self:gopath (owner_pos, 1.4, nil, 3.0)
		end
		return true
	else
		local owner = self:_get_owner ()
		if not owner then
			return
		end
		local owner_pos = owner:get_pos ()
		if vector.distance (self_pos, owner_pos) <= 20 then
			if vector.distance (self_pos, owner_pos) >= 6.0 then
				self._following_owner = true
				self:gopath (owner_pos, 1.4, nil, 3.0)
				return "_following_owner"
			end
		elseif owner then
			self._trader_id = nil
			self._get_owner = trader_llama._get_owner
		end
	end
	return false
end

function trader_llama:ai_step (dtime)
	llama.ai_step (self, dtime)

	if not self.tamed and not self.driver then
		local owner = self:_get_owner ()
		if owner then
			self._life_timer = owner:get_luaentity ()._life_timer
		elseif self._life_timer then
			self._life_timer = self._life_timer - dtime
		end
	end

	if self._life_timer and self._life_timer <= 0 then
		self:safe_remove ()
	end
end


------------------------------------------------------------------------
-- Trader Llama spawning & registration.
------------------------------------------------------------------------

mcl_mobs.register_mob ("mcl_mobs_addon:trader_llama", trader_llama)
mcl_mobs.register_egg ("mcl_mobs_addon:trader_llama", S("Trader Llama"), "#eaa430", "#456296", 0)
mcl_entity_invs.register_inv ("mcl_mobs_addon:trader_llama", S ("Trader Llama"), nil, true)

-- natural spawn: rare, like MC; traders wander with their llamas.
-- Mineclonia branch FIRST (their spawn_setup is a broken compat shim).
if mcl_mobs.register_spawner and mobs_mc and mobs_mc.animal_spawner then
	mcl_mobs.register_spawner(table.merge(mobs_mc.animal_spawner, {
		name = "mcl_mobs_addon:wandering_trader", biomes = OW_MONSTERS, weight = 5,
	}))
elseif mcl_mobs.spawn_setup then
	mcl_mobs:spawn_setup({ name = "mcl_mobs_addon:wandering_trader", dimension = "overworld", biomes = OW_MONSTERS, weight = 5 })
end

minetest.log("action", "[mcl_mobs_addon] ported mobs registered (creeper/enderman/blaze/pufferfish/ravager/trader)")

-- Mineclonia reads hp from the def base (math.random at activate) — the
-- same latent crash as the other addon mobs; patch after registration.
for _name, _hp in pairs({
	["mcl_mobs_addon:creeper"] = {20, 20},
	["mcl_mobs_addon:creeper_charged"] = {20, 20},
	["mcl_mobs_addon:blaze"] = {20, 20},
	["mcl_mobs_addon:enderman"] = {40, 40},
	["mcl_mobs_addon:pufferfish"] = {6, 6},
	["mcl_mobs_addon:ravager"] = {100, 100},
	["mcl_mobs_addon:wandering_trader"] = {20, 20},
	["mcl_mobs_addon:trader_llama"] = {30, 30},
}) do
	mcl_mobs_addon.mcln_base_hp(_name, _hp[1], _hp[2])
end

minetest.log("action", "[mcl_mobs_addon] ported mobs registered (creeper/enderman/blaze/pufferfish/ravager/trader)")
