--[[
mcl_mobs_addon — Extra Minecraft-style mobs for VoxeLibre / Mineclonia.

Implemented (retexture of existing game models, assets from
Pixel-Perfection-Legacy, CC BY-SA 4.0):
  fox           (mesh base: mobs_mc_wolf.b3d)
  panda         (mesh base: mobs_mc_polarbear.b3d)
  camel         (mesh base: mobs_mc_llama.b3d)
  skeleton_horse(mesh base: mobs_mc_horse.b3d)

WIP (need new .b3d models in Blender — no model exists anywhere in Luanti):
  allay, frog, warden, phantom, turtle, sniffer, goat

API notes (verified 2026-08):
  - registration: mcl_mobs.register_mob("mobs_mc:<name>", def)  (both games)
  - spawn: VoxeLibre uses mcl_mobs:spawn_setup{...}; Mineclonia uses
    mcl_mobs.register_spawner{...} (different shape) — Mineclonia spawn
    support is TODO.
  - egg: mcl_mobs.register_egg(id, desc, c1, c2, 0)
]]

local S = minetest.get_translator("mcl_mobs_addon")

-- ---------------------------------------------------------------------------
-- Helpers (dual-game)
-- ---------------------------------------------------------------------------

local function register_egg(id, desc, c1, c2)
	if mcl_mobs.register_egg then
		mcl_mobs.register_egg(id, desc, c1, c2, 0)
	end
end

local function register_spawn(def)
	if mcl_mobs.spawn_setup then
		-- VoxeLibre style
		mcl_mobs:spawn_setup(def)
	else
		-- Mineclonia style: needs a spawner table (name, spawn_placement,
		-- pack_min/max, weight, biomes with "#is_*" tags) — TODO(port)
		minetest.log("warning", "[mcl_mobs_addon] Mineclonia spawn API not "
			.. "implemented yet, skipping natural spawn for " .. def.name)
	end
end

-- ---------------------------------------------------------------------------
-- FOX  (base model: wolf)
-- ---------------------------------------------------------------------------
local fox = {
	description = S("Fox"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 10,
		hp_max = 10,
		collisionbox = {-0.3, -0.01, -0.3, 0.3, 0.62, 0.3},
	},
	xp_min = 1,
	xp_max = 2,
	passive = true,
	visual = "mesh",
	mesh = "mcl_mobs_addon_fox.b3d",
	textures = {
		{"mcl_mobs_addon_fox.png"},
	},
	visual_size = {x = 0.8, y = 0.8},
	makes_footstep_sound = true,
	head_swivel = "head.control",
	head_eye_height = 0.42,
	head_bone_position = vector.new(0, 3.5, 0),
	horizontal_head_height = 0,
	head_yaw = "z",
	curiosity = 3,
	pathfinding = 1,
	view_range = 16,
	walk_chance = 50,
	walk_velocity = 2,
	run_velocity = 3.4, -- foxes are fast
	damage = 0,
	reach = 2,
	fear_height = 4,
	jump = true,
	floats = 1,
	-- TODO: MC foxes hunt chickens (attack_animals = true, specific_attack chicken)
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 50,
		run_start = 0, run_end = 40, run_speed = 100,
	},
	-- TODO(sounds): CC0 fox sounds from freesound.org
}

mcl_mobs.register_mob("mcl_mobs_addon:fox", fox)
register_egg("mcl_mobs_addon:fox", S("Fox"), "#d98245", "#f2e9dc", 0)
register_spawn({
	name = "mcl_mobs_addon:fox",
	dimension = "overworld",
	type_of_spawning = "ground",
	biomes = {
		"Taiga", "ColdTaiga", "MegaTaiga", "MegaSpruceTaiga",
	},
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	chance = 60,
	interval = 30,
	aoc = 7,
	min_height = mobs_mc.water_level + 3,
	max_height = mcl_vars.mg_overworld_max,
})

-- ---------------------------------------------------------------------------
-- PANDA  (base model: polar bear)
-- ---------------------------------------------------------------------------
local panda = {
	description = S("Panda"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		collisionbox = {-0.6, -0.01, -0.6, 0.6, 1.2, 0.6},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mcl_mobs_addon_panda.b3d",
	textures = {
		{"mcl_mobs_addon_panda.png"},
	},
	visual_size = {x = 2.4, y = 2.4}, -- polar bear base is 3.0
	makes_footstep_sound = true,
	head_swivel = "head.control",
	head_eye_height = 1.0,
	head_bone_position = vector.new(0, 3.5, 0),
	horizontal_head_height = 0,
	head_yaw = "z",
	pathfinding = 1,
	view_range = 16,
	walk_chance = 50,
	walk_velocity = 1.6,
	run_velocity = 2.4,
	damage = 0,
	reach = 2,
	fear_height = 4,
	jump = true,
	floats = 1,
	follow = { "mcl_bamboo:bamboo" },
	-- TODO: panda personalities (aggressive/lazy/playful/weak/worried) use
	-- the variant textures already shipped: mcl_mobs_addon_panda_*.png
	-- TODO(sounds): CC0
}

mcl_mobs.register_mob("mcl_mobs_addon:panda", panda)
register_egg("mcl_mobs_addon:panda", S("Panda"), "#f0f0f0", "#222222", 0)
register_spawn({
	name = "mcl_mobs_addon:panda",
	dimension = "overworld",
	type_of_spawning = "ground",
	biomes = {
		"BambooJungle", "BambooJungleM", "Jungle",
	},
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	chance = 30,
	interval = 30,
	aoc = 7,
	min_height = mobs_mc.water_level + 3,
	max_height = mcl_vars.mg_overworld_max,
})

-- ---------------------------------------------------------------------------
-- CAMEL  (base model: llama)
-- ---------------------------------------------------------------------------
local camel = {
	description = S("Camel"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 32,
		hp_max = 32,
		collisionbox = {-0.5, -0.01, -0.5, 0.5, 2.0, 0.5},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mcl_mobs_addon_camel.b3d",
	textures = {
		{"mcl_mobs_addon_camel.png"},
	},
	visual_size = {x = 1.15, y = 1.15},
	makes_footstep_sound = true,
	head_swivel = "head.control",
	head_eye_height = 1.6,
	head_bone_position = vector.new(0, 3.5, 0),
	horizontal_head_height = 0,
	head_yaw = "z",
	pathfinding = 1,
	view_range = 16,
	walk_chance = 50,
	walk_velocity = 1.8,
	run_velocity = 2.6,
	damage = 0,
	reach = 2,
	fear_height = 4,
	jump = true,
	floats = 1,
	-- TODO: MC camels are rideable by 2 players (llama has driver logic to copy)
	-- TODO(sounds): CC0
}

mcl_mobs.register_mob("mcl_mobs_addon:camel", camel)
register_egg("mcl_mobs_addon:camel", S("Camel"), "#c89b5a", "#e8d5a8", 0)
register_spawn({
	name = "mcl_mobs_addon:camel",
	dimension = "overworld",
	type_of_spawning = "ground",
	biomes = {
		"Desert",
	},
	min_light = 0,
	max_light = minetest.LIGHT_MAX + 1,
	chance = 20,
	interval = 30,
	aoc = 7,
	min_height = mobs_mc.water_level + 3,
	max_height = mcl_vars.mg_overworld_max,
})

-- ---------------------------------------------------------------------------
-- SKELETON HORSE  (base model: horse)
-- ---------------------------------------------------------------------------
local skeleton_horse = {
	description = S("Skeleton Horse"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 15,
		hp_max = 15,
		collisionbox = {-0.7, -0.01, -0.7, 0.7, 1.59, 0.7},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mcl_mobs_addon_skeleton_horse.b3d",
	textures = {
		{"mcl_mobs_addon_skeleton_horse.png"},
	},
	visual_size = {x = 3.0, y = 3.0},
	makes_footstep_sound = true,
	head_swivel = "head.control",
	head_eye_height = 1.5,
	head_bone_position = vector.new(0, 3.5, 0),
	horizontal_head_height = 0,
	head_yaw = "z",
	pathfinding = 1,
	view_range = 16,
	walk_chance = 50,
	walk_velocity = 2,
	run_velocity = 3,
	damage = 0,
	reach = 2,
	fear_height = 4,
	jump = true,
	floats = 1,
	drops = {
		{name = "mcl_mobitems:bone", chance = 1, min = 0, max = 2},
	},
	-- TODO: MC skeleton trap (lightning converts to skeleton riders) —
	-- no natural spawn on purpose; egg only for now
	-- TODO(sounds): reuse game skeleton sounds (mobs_mc_skeleton_*)
}

mcl_mobs.register_mob("mcl_mobs_addon:skeleton_horse", skeleton_horse)
register_egg("mcl_mobs_addon:skeleton_horse", S("Skeleton Horse"), "#8a8a8a", "#e8e8e8", 0)
-- No natural spawn (MC: skeleton trap only)

minetest.log("action", "[mcl_mobs_addon] loaded: fox, panda, camel, skeleton_horse registered")

-- ---------------------------------------------------------------------------
-- WIP — need new .b3d models (Blender, VL cuboid style). Textures are already
-- shipped in textures/:
--   allay     mcl_mobs_addon_allay.png
--   frog      mcl_mobs_addon_frog_{temperate,cold,warm}.png
--   warden    mcl_mobs_addon_warden.png (+ _glow, _ears)
--   phantom   mcl_mobs_addon_phantom.png (+ _eyes)
--   turtle    mcl_mobs_addon_turtle.png
--   sniffer   mcl_mobs_addon_sniffer.png
--   goat      mcl_mobs_addon_goat.png
-- Registration template (uncomment once the model exists):
--
-- local warden = {
--     description = S("Warden"),
--     type = "monster",
--     spawn_class = "hostile",
--     can_despawn = true,
--     initial_properties = {
--         hp_min = 500, hp_max = 500,
--         collisionbox = {-0.6, -0.01, -0.6, 0.6, 2.9, 0.6},
--     },
--     visual = "mesh",
--     mesh = "mcl_mobs_addon_warden.b3d",
--     textures = {{"mcl_mobs_addon_warden.png"}},
--     visual_size = {x = 3.0, y = 3.0},
--     -- TODO: vibration sensing via mcl_sculk sensor events
-- }
-- mcl_mobs.register_mob("mobs_mc:warden", warden)
-- register_egg("mobs_mc:warden", S("Warden"), "#0a3b2e", "#7ef0c8", 0)
-- ---------------------------------------------------------------------------
