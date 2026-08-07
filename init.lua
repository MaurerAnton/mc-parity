--[[
mcl_mobs_addon — Extra Minecraft-style mobs for VoxeLibre / Mineclonia.

Implemented (retexture of existing game models, assets from
Pixel-Perfection-Legacy, CC BY-SA 4.0):
  fox            (mesh base: mobs_mc_wolf.b3d)      — hunts chickens/rabbits
  panda          (mesh base: mobs_mc_polarbear.b3d) — 7 personalities
  camel          (mesh base: mobs_mc_llama.b3d)     — rideable (1 driver)
  skeleton_horse (mesh base: mobs_mc_horse.b3d)     — lightning skeleton trap

WIP (need new .b3d models in Blender — no model exists anywhere in Luanti):
  allay, frog, warden, phantom, turtle, sniffer, goat

API notes (verified 2026-08):
  - registration: mcl_mobs.register_mob("<mod>:<name>", def) — both games;
    the id MUST use this mod's own prefix (mcl_mobs_addon:)
  - spawn: VoxeLibre = mcl_mobs:spawn_setup{...}; Mineclonia =
    mcl_mobs.register_spawner(table.merge(mobs_mc.animal_spawner, {...}))
    with "#is_*" biome tags (no is_desert tag — use "Desert" name there)
  - egg: mcl_mobs.register_egg(id, desc, c1, c2, 0)
  - riding: mcl_mobs.attach(self, player) / mcl_mobs.detach(player, offset)
    / mcl_mobs.drive(self, walk_anim, stand_anim, reverse, dtime)
  - skeleton trap: lightning.register_on_strike(pos, pos2, objects) (VL only)
]]

local S = minetest.get_translator("mcl_mobs_addon")

local pr = PseudoRandom(os.time() * 2)

-- ---------------------------------------------------------------------------
-- Helpers (dual-game)
-- ---------------------------------------------------------------------------

local function register_egg(id, desc, c1, c2)
	if mcl_mobs.register_egg then
		mcl_mobs.register_egg(id, desc, c1, c2, 0)
	end
end

-- Registers natural spawning on both games.
-- vl_biomes: VoxeLibre biome names; mcln_biomes: Mineclonia names/#is_* tags.
-- NOTE: Mineclonia keeps spawn_setup only as a deprecated shim, so
-- register_spawner must be preferred when present.
local function register_spawn(name, vl_biomes, mcln_biomes, weight)
	if mcl_mobs.register_spawner and mobs_mc and mobs_mc.animal_spawner then
		-- Mineclonia style
		mcl_mobs.register_spawner(table.merge(mobs_mc.animal_spawner, {
			name = name,
			biomes = mcln_biomes,
			weight = weight,
		}))
	elseif mcl_mobs.spawn_setup then
		-- VoxeLibre style
		mcl_mobs:spawn_setup({
			name = name,
			dimension = "overworld",
			type_of_spawning = "ground",
			biomes = vl_biomes,
			min_light = 0,
			max_light = minetest.LIGHT_MAX + 1,
			chance = weight,
			interval = 30,
			aoc = 7,
			min_height = mobs_mc.water_level + 3,
			max_height = mcl_vars.mg_overworld_max,
		})
	else
		minetest.log("warning", "[mcl_mobs_addon] no spawn API available for " .. name)
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
	damage = 2, -- MC fox attack damage
	reach = 2,
	attack_animals = true, -- MC foxes hunt chickens and rabbits
	specific_attack = { "mobs_mc:chicken", "mobs_mc:rabbit" },
	fear_height = 4,
	jump = true,
	floats = 1,
	-- Placeholder: game's wolf sounds (free, CC BY-SA). TODO: CC0 fox barks.
	sounds = {
		random = "mobs_mc_wolf_bark",
		damage = {name = "mobs_mc_wolf_hurt", gain = 0.6},
		death = {name = "mobs_mc_wolf_death", gain = 0.6},
		distance = 16,
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 50,
		run_start = 0, run_end = 40, run_speed = 100,
	},
}

mcl_mobs.register_mob("mcl_mobs_addon:fox", fox)
register_egg("mcl_mobs_addon:fox", S("Fox"), "#d98245", "#f2e9dc", 0)
register_spawn("mcl_mobs_addon:fox",
	{"Taiga", "ColdTaiga", "MegaTaiga", "MegaSpruceTaiga"},
	{"#is_taiga"}, 60)

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
	sounds = {
		random = "mobs_mc_bear_random",
		attack = "mobs_mc_bear_attack",
		damage = {name = "mobs_mc_bear_hurt", gain = 0.6},
		death = {name = "mobs_mc_bear_death", gain = 0.6},
		distance = 16,
	},
	on_spawn = function(self)
		-- MC panda personalities (approximate genetics weights).
		-- Variant textures are shipped in textures/.
		local r = pr:next(1, 100)
		local tex
		if r <= 40 then
			tex = "mcl_mobs_addon_panda.png" -- normal
		elseif r <= 55 then
			tex = "mcl_mobs_addon_panda_playful.png"
		elseif r <= 65 then
			tex = "mcl_mobs_addon_panda_lazy.png"
		elseif r <= 75 then
			tex = "mcl_mobs_addon_panda_worried.png"
		elseif r <= 85 then
			tex = "mcl_mobs_addon_panda_weak.png"
		elseif r <= 95 then
			tex = "mcl_mobs_addon_panda_aggressive.png"
		else
			tex = "mcl_mobs_addon_panda_brown.png"
		end
		self.base_texture[1] = tex
		self.object:set_properties({ textures = self.base_texture })
	end,
}

mcl_mobs.register_mob("mcl_mobs_addon:panda", panda)
register_egg("mcl_mobs_addon:panda", S("Panda"), "#f0f0f0", "#222222", 0)
register_spawn("mcl_mobs_addon:panda",
	{"BambooJungle", "BambooJungleM", "Jungle"},
	{"#is_jungle"}, 30)

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
	sounds = {
		random = "mobs_mc_llama",
		eat = "mobs_mc_animal_eat_generic",
		distance = 16,
	},
	-- Riding (llama driver pattern; MC camels seat 2 — TODO: second seat)
	do_custom = function(self, dtime)
		if not self.v3 then
			self.v3 = 0
			self.max_speed_forward = 3.5
			self.max_speed_reverse = 1.5
			self.accel = 3
			self.driver_attach_at = {x = 0, y = 12.7, z = -5}
			self.driver_eye_offset = {x = 0, y = 6, z = 0}
			self.driver_scale = {
				x = 1 / self.initial_properties.visual_size.x,
				y = 1 / self.initial_properties.visual_size.y,
			}
		end
		if self.driver then
			mcl_mobs.drive(self, "walk", "stand", false, dtime)
			return false -- skip rest of mob functions
		end
		return true
	end,
	on_die = function(self, pos)
		if self.driver then
			mcl_mobs.detach(self.driver, {x = 1, y = 0, z = 1})
		end
	end,
	on_rightclick = function(self, clicker)
		if not clicker or not clicker:is_player() then
			return
		end
		if mcl_mobs:protect(self, clicker) then
			return
		end
		if self.driver and clicker == self.driver then
			-- Dismount
			mcl_mobs.detach(clicker, {x = 1, y = 0, z = 1})
		elseif not self.driver then
			-- Mount
			self.object:set_properties({stepheight = 1.1})
			mcl_mobs.attach(self, clicker)
		end
	end,
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40, walk_speed = 35,
		run_start = 0, run_end = 40, run_speed = 70,
	},
}

mcl_mobs.register_mob("mcl_mobs_addon:camel", camel)
register_egg("mcl_mobs_addon:camel", S("Camel"), "#c89b5a", "#e8d5a8", 0)
register_spawn("mcl_mobs_addon:camel",
	{"Desert"},
	{"Desert"}, 20)

-- ---------------------------------------------------------------------------
-- GOAT  (model: procedurally generated b3d — tools/gen_b3d.py, unique:
-- no goat exists in VoxeLibre, Mineclonia, Bettercraft or ContentDB)
-- ---------------------------------------------------------------------------
local goat = {
	description = S("Goat"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 10,
		hp_max = 10,
		collisionbox = {-0.45, -0.01, -0.45, 0.45, 1.3, 0.45},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mcl_mobs_addon_goat.b3d",
	textures = {
		{"mcl_mobs_addon_goat.png"},
	},
	visual_size = {x = 1.0, y = 1.0},
	makes_footstep_sound = true,
	pathfinding = 1,
	view_range = 16,
	walk_chance = 50,
	walk_velocity = 1.5,
	run_velocity = 2.5,
	damage = 0,
	reach = 2,
	fear_height = 4,
	jump = true,
	floats = 1,
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 0,
		run_start = 0, run_end = 0,
	},
	-- TODO(sounds): CC0 goat sounds; TODO: MC goat ramming + horns drop
}

mcl_mobs.register_mob("mcl_mobs_addon:goat", goat)
register_egg("mcl_mobs_addon:goat", S("Goat"), "#f2e2d0", "#9a8a7a", 0)
register_spawn("mcl_mobs_addon:goat",
	{"ExtremeHills", "ExtremeHillsM"},
	{"#is_mountain"}, 30)

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
	sounds = {
		random = "mobs_mc_skeleton_random",
		damage = {name = "mobs_mc_skeleton_hurt", gain = 0.6},
		death = {name = "mobs_mc_skeleton_death", gain = 0.6},
		distance = 16,
	},
	-- No natural spawn on purpose (MC: skeleton trap via lightning only)
}

mcl_mobs.register_mob("mcl_mobs_addon:skeleton_horse", skeleton_horse)
register_egg("mcl_mobs_addon:skeleton_horse", S("Skeleton Horse"), "#8a8a8a", "#e8e8e8", 0)

-- Skeleton trap (MC 1.11): lightning converts the horse and summons 4
-- skeletons. Approximation: horse turns hostile, skeletons spawn around it.
-- VoxeLibre only (Mineclonia has its own weather/lightning — TODO).
if minetest.get_modpath("lightning") and lightning and lightning.register_on_strike then
	lightning.register_on_strike(function(pos, pos2, objects)
		for _, obj in pairs(objects or {}) do
			local ent = obj:get_luaentity()
			if ent and ent.name == "mcl_mobs_addon:skeleton_horse" and not ent._trap then
				ent._trap = true
				ent.damage = 2
				local p = obj:get_pos()
				for i = 1, 4 do
					local sp = {
						x = p.x + math.random(-2, 2),
						y = p.y + 1,
						z = p.z + math.random(-2, 2),
					}
					if minetest.get_node(sp).name == "air" then
						minetest.add_entity(sp, "mobs_mc:skeleton")
					end
				end
				break
			end
		end
	end)
end

minetest.log("action", "[mcl_mobs_addon] loaded: fox, panda, camel, skeleton_horse, goat registered")

-- ---------------------------------------------------------------------------
-- BUNDLE  (MC 1.17 item — no implementation exists in VoxeLibre/Mineclonia/
-- Bettercraft/ContentDB). Contents travel with the item (serialized in item
-- metadata), so a dropped bundle keeps its items — the MC bundle property.
-- v1: craft, view, take items out. TODO: shift-click insert (MC parity).
-- ---------------------------------------------------------------------------
local BUNDLE_MAX_ITEMS = 64
local BUNDLE_SLOTS = 16

local function bundle_get_inv(itemstack)
	local raw = itemstack:get_meta():get_string("inv")
	if raw == "" then
		return {}
	end
	local ok, list = pcall(minetest.deserialize, raw)
	return ok and type(list) == "table" and list or {}
end

local function bundle_set_inv(itemstack, list)
	itemstack:get_meta():set_string("inv", minetest.serialize(list))
end

local function bundle_count(list)
	local n = 0
	for _, s in pairs(list) do
		n = n + ItemStack(s):get_count()
	end
	return n
end

local function bundle_formspec(list)
	local parts = {"size[7.2,3.2]", "label[0,0;Bundle (" .. bundle_count(list) .. "/" .. BUNDLE_MAX_ITEMS .. ")]"}
	for i = 0, BUNDLE_SLOTS - 1 do
		local x, y = (i % 8) * 0.9, math.floor(i / 8) * 0.9 + 0.5
		local s = list[i]
		local img = "blank.png"
		if s then
			img = ItemStack(s):get_name()
		end
		parts[#parts + 1] = "item_image[" .. x .. "," .. y .. ";0.85,0.85;" .. img .. "]"
		parts[#parts + 1] = "button[" .. x .. "," .. y .. ";0.85,0.85;" .. tostring(i) .. ";take]"
	end
	parts[#parts + 1] = "button[2.9,2.3;1.4,0.7;close;Close]"
	return table.concat(parts)
end

minetest.register_craftitem("mcl_mobs_addon:bundle", {
	description = S("Bundle"),
	inventory_image = "mcl_mobs_addon_bundle.png",
	stack_max = 1,
	groups = { bundle = 1 },
	on_use = function(itemstack, user)
		minetest.show_formspec(user:get_player_name(), "mcl_mobs_addon:bundle",
			bundle_formspec(bundle_get_inv(itemstack)))
		return itemstack
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mcl_mobs_addon:bundle" then
		return
	end
	local itemstack = player:get_wielded_item()
	if itemstack:get_name() ~= "mcl_mobs_addon:bundle" then
		return
	end
	local list = bundle_get_inv(itemstack)
	for i = 0, BUNDLE_SLOTS - 1 do
		if fields[tostring(i)] then
			local s = list[i]
			if s then
				local leftover = player:get_inventory():add_item("main", s)
				if leftover:is_empty() then
					list[i] = nil
					bundle_set_inv(itemstack, list)
					player:set_wielded_item(itemstack)
				end
			end
			break
		end
	end
end)

-- MC recipe: 6 rabbit hide + 2 string (VL: rabbit hide = leather_piece)
minetest.register_craft({
	output = "mcl_mobs_addon:bundle",
	recipe = {
		{"mcl_mobitems:leather_piece", "mcl_mobitems:leather_piece", "mcl_mobitems:leather_piece"},
		{"mcl_mobitems:leather_piece", "mcl_mobitems:string", "mcl_mobitems:leather_piece"},
		{"mcl_mobitems:leather_piece", "mcl_mobitems:string", "mcl_mobitems:leather_piece"},
	},
})

-- ---------------------------------------------------------------------------
-- SHULKER UPGRADE — MC-parity face attachment + the 900-degree spin quirk.
-- Patches the game's own mobs_mc:shulker at runtime (works on both games):
--   VoxeLibre: adds 6-face attachment + rotation + spin (was static)
--   Mineclonia: adds the spin animation (was instant rotation)
-- See shulker_upgrade.lua.
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/shulker_upgrade.lua")

-- ---------------------------------------------------------------------------
-- DEEP DARK + ANCIENT CITY — MC 1.19. Ports the DeepDark biome + sculk
-- generation to VoxeLibre (Mineclonia has it), adds the FULL Ancient City
-- for both games (Mineclonia has only the mini hermitage), and makes
-- sculk shriekers functional. See deepdark.lua.
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/deepdark.lua")

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
-- Model pipeline docs: https://docs.luanti.org/for-creators/models/
--   Using Blender:      https://docs.luanti.org/for-creators/models/using-blender/
--   Using Blockbench:   https://docs.luanti.org/for-creators/models/using-blockbench/
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
-- mcl_mobs.register_mob("mcl_mobs_addon:warden", warden)
-- register_egg("mcl_mobs_addon:warden", S("Warden"), "#0a3b2e", "#7ef0c8", 0)
-- ---------------------------------------------------------------------------
