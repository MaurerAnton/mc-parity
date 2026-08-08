--[[
mc_parity — Extra Minecraft-style mobs for VoxeLibre / Mineclonia.

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
    the id MUST use this mod's own prefix (mc_parity:)
  - spawn: VoxeLibre = mcl_mobs:spawn_setup{...}; Mineclonia =
    mcl_mobs.register_spawner(table.merge(mobs_mc.animal_spawner, {...}))
    with "#is_*" biome tags (no is_desert tag — use "Desert" name there)
  - egg: mcl_mobs.register_egg(id, desc, c1, c2, 0)
  - riding: mcl_mobs.attach(self, player) / mcl_mobs.detach(player, offset)
    / mcl_mobs.drive(self, walk_anim, stand_anim, reverse, dtime)
  - skeleton trap: lightning.register_on_strike(pos, pos2, objects) (VL only)
]]

local S = minetest.get_translator("mc_parity")

local pr = PseudoRandom(os.time() * 2)

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/config.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/legacy.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/legacy_items.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_final.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/port_items.lua")

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
		minetest.log("warning", "[mc_parity] no spawn API available for " .. name)
	end
end

-- Expose the helpers on the global table so dofile'd modules can use them
-- (dofile chunks only see globals, never the caller's locals).
mc_parity = rawget(_G, "mc_parity") or {}
mc_parity.register_egg = register_egg
mc_parity.register_spawn = register_spawn

-- Mineclonia's mob activate reads hp from the DEF BASE (math.random(
-- self.hp_min, ...) at mcl_mobs/api.lua:429); VoxeLibre from
-- initial_properties (and warns on base placement). Register with hp in
-- initial_properties, then add the base fields for Mineclonia.
-- (register_spawner = the Mineclonia marker)
local function mcln_base_hp(name, hp_min, hp_max)
	if mcl_mobs.register_spawner then
		local def = mcl_mobs.registered_mobs[name]
		if def then
			def.hp_min = hp_min
			def.hp_max = hp_max
		end
	end
end
mc_parity.mcln_base_hp = mcln_base_hp  -- for dofile'd modules

-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("fox") then
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
	mesh = "mc_parity_fox.b3d",
	textures = {
		{"mc_parity_fox.png"},
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

mcl_mobs.register_mob("mc_parity:fox", fox)
mcln_base_hp("mc_parity:fox", 10, 10)
register_egg("mc_parity:fox", S("Fox"), "#d98245", "#f2e9dc", 0)
register_spawn("mc_parity:fox",
	{"Taiga", "ColdTaiga", "MegaTaiga", "MegaSpruceTaiga"},
	{"#is_taiga"}, 60)

end
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("panda") then
-- retexture; personality textures stay ours)
-- ---------------------------------------------------------------------------
local panda = {
	description = S("Panda"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		collisionbox = {-0.6, 0, -0.6, 0.6, 1.4, 0.6},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mc_parity_panda.b3d",
	textures = {
		{"mc_parity_panda.png"},
	},
	visual_size = {x = 1, y = 1},
	animation = {
		stand_start = 0, stand_end = 25, stand_speed = 10,
		walk_start = 30, walk_end = 70, speed_normal = 10,
		run_start = 30, run_end = 70, speed_run = 15,
		punch_start = 30, punch_end = 70, punch_speed = 15,
	},
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
			tex = "mc_parity_panda.png" -- normal
		elseif r <= 55 then
			tex = "mc_parity_panda_playful.png"
		elseif r <= 65 then
			tex = "mc_parity_panda_lazy.png"
		elseif r <= 75 then
			tex = "mc_parity_panda_worried.png"
		elseif r <= 85 then
			tex = "mc_parity_panda_weak.png"
		elseif r <= 95 then
			tex = "mc_parity_panda_aggressive.png"
		else
			tex = "mc_parity_panda_brown.png"
		end
		self.base_texture[1] = tex
		self.object:set_properties({ textures = self.base_texture })
	end,
}

mcl_mobs.register_mob("mc_parity:panda", panda)
mcln_base_hp("mc_parity:panda", 20, 20)
register_egg("mc_parity:panda", S("Panda"), "#f0f0f0", "#222222", 0)
register_spawn("mc_parity:panda",
	{"BambooJungle", "BambooJungleM", "Jungle"},
	{"#is_jungle"}, 30)

end
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("camel") then
-- retexture; our riding logic stays)
-- ---------------------------------------------------------------------------
local camel = {
	description = S("Camel"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 32,
		hp_max = 32,
		collisionbox = {-0.6, 0, -0.6, 0.6, 1.8, 0.6},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mc_parity_camel.b3d",
	textures = {
		{"mc_parity_camel.png"},
	},
	visual_size = {x = 1, y = 1},
	animation = {
		stand_start = 1, stand_end = 40, stand_speed = 10,
		walk_start = 70, walk_end = 100, speed_normal = 10,
		run_start = 130, run_end = 146, speed_run = 10,
	},
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
			self.driver_attach_at = {x = 0, y = 22, z = 0}  -- camel hump top is 24.7 model units
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
		if self.passenger and self.passenger:is_valid() then
			mcl_mobs.detach(self.passenger, {x = 1, y = 0, z = 1})
			self.passenger = nil
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
			-- Dismount (driver + any passenger)
			mcl_mobs.detach(clicker, {x = 1, y = 0, z = 1})
			if self.passenger and self.passenger:is_valid() then
				mcl_mobs.detach(self.passenger, {x = 1, y = 0, z = 1})
				self.passenger = nil
			end
		elseif self.driver then
			-- Second seat (MC: camels seat 2)
			if not self.passenger or not self.passenger:is_valid() then
				self.passenger = clicker
				clicker:set_attach(self.object, "", {x = 0, y = 19, z = 6}, {x = 0, y = 0, z = 0})  -- behind the hump
			end
		elseif not self.driver then
			-- Mount
			self.object:set_properties({stepheight = 1.1})
			mcl_mobs.attach(self, clicker)
		end
	end,
}

mcl_mobs.register_mob("mc_parity:camel", camel)
mcln_base_hp("mc_parity:camel", 32, 32)
register_egg("mc_parity:camel", S("Camel"), "#c89b5a", "#e8d5a8", 0)
register_spawn("mc_parity:camel",
	{"Desert"},
	{"Desert"}, 20)

end
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("goat") then
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
	mesh = "mc_parity_goat.b3d",
	textures = {
		{"mc_parity_goat.png"},
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
	sounds = {
		random = "mobs_mc_llama",
		damage = { name = "mobs_mc_cow_hurt", gain = 0.6 },
		death = { name = "mobs_mc_cow_hurt", gain = 0.6 },
		distance = 16,
	},
	-- MC parity: horns come ONLY from charged rams (1-2), never on death
	drops = {},
	-- MC goat ramming: provoked goats wind up ~0.7s then charge, knocking
	-- back and damaging; charged rams drop horns
	on_attack = function(self, hitter)
		if hitter and hitter:is_player() then
			self.attack = hitter
			self._ram_cooldown = 0
		end
	end,
	do_custom = function(self, dtime)
		self._ram_cooldown = (self._ram_cooldown or 0) - dtime
		if self._ramming then
			if not self.attack or not self.attack:is_valid() then
				self._ramming = nil
				return true
			end
			local pos = self.object:get_pos()
			local tpos = self.attack:get_pos()
			if pos and tpos then
				local dist = vector.distance(pos, tpos)
				self.object:set_velocity(vector.multiply(self._ram_dir, 6))
				if dist < 1.8 then
					-- impact: damage + knockback + 1-2 horns (MC: charged
					-- rams ALWAYS drop 1-2 horns)
					self.attack:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = { fleshy = 2 },
					})
					for _ = 1, math.random(1, 2) do
						minetest.add_item(pos, "mc_parity:goat_horn")
					end
					self._ramming = nil
					self._ram_cooldown = 8
				elseif dist > 16 then
					self._ramming = nil
				end
			end
			return false  -- full control while charging
		end
		if self.attack and self.attack:is_valid() and self._ram_cooldown <= 0 then
			local pos = self.object:get_pos()
			local tpos = self.attack:get_pos()
			if pos and tpos and vector.distance(pos, tpos) < 8 then
				-- wind up, then charge
				self._ram_windup = (self._ram_windup or 0) - dtime
				if self._ram_windup <= 0 then
					self._ramming = true
					self._ram_dir = vector.direction(pos, tpos)
				end
				return false  -- stand still while winding up
			end
		end
		self._ram_windup = 0.7
		return true
	end,
}

-- Goat horn (MC: dropped by charged rams; an instrument — plays notes)
minetest.register_craftitem("mc_parity:goat_horn", {
	description = S("Goat Horn"),
	inventory_image = "mc_parity_goat_horn.png",
	groups = { craftitem = 1 },
	stack_max = 64,
	on_use = function(itemstack, user, pointed_thing)
		local notes = {
			"mesecons_noteblock_a", "mesecons_noteblock_b", "mesecons_noteblock_c",
			"mesecons_noteblock_d", "mesecons_noteblock_e", "mesecons_noteblock_f",
			"mesecons_noteblock_g", "mesecons_noteblock_asharp",
			"mesecons_noteblock_csharp", "mesecons_noteblock_fsharp",
		}
		local pos = user and user:get_pos()
		if pos then
			minetest.sound_play(notes[math.random(#notes)],
				{ pos = pos, gain = 1.0, max_hear_distance = 24 }, true)
		end
		return itemstack
	end,
})

mcl_mobs.register_mob("mc_parity:goat", goat)
mcln_base_hp("mc_parity:goat", 10, 10)
register_egg("mc_parity:goat", S("Goat"), "#f2e2d0", "#9a8a7a", 0)
register_spawn("mc_parity:goat",
	{"ExtremeHills", "ExtremeHillsM"},
	{"#is_mountain"}, 30)

end
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("skeleton_horse") then
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
	mesh = "mc_parity_skeleton_horse.b3d",
	textures = {
		{"mc_parity_skeleton_horse.png"},
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

mcl_mobs.register_mob("mc_parity:skeleton_horse", skeleton_horse)
mcln_base_hp("mc_parity:skeleton_horse", 15, 15)
register_egg("mc_parity:skeleton_horse", S("Skeleton Horse"), "#8a8a8a", "#e8e8e8", 0)

-- Skeleton trap (MC 1.11): lightning converts the horse and summons 4
-- skeleton horses WITH skeleton riders (jockeys), which despawn after a
-- while. Works on BOTH games: Mineclonia ships a COMPAT "lightning" shim
-- whose metatable resolves lightning.* to mcl_lightning (same API as VL).
if minetest.get_modpath("lightning") and lightning and lightning.register_on_strike then
	lightning.register_on_strike(function(pos, pos2, objects)
		for _, obj in pairs(objects or {}) do
			local ent = obj:get_luaentity()
			if ent and ent.name == "mc_parity:skeleton_horse" and not ent._trap then
				ent._trap = true
				ent.damage = 2
				local p = obj:get_pos()
				-- the struck horse + 3 more around (MC parity)
				local horses = { obj }
				for i = 1, 3 do
					local hp = {
						x = p.x + math.random(-3, 3),
						y = p.y,
						z = p.z + math.random(-3, 3),
					}
					local n = minetest.get_node(hp)
					local n2 = minetest.get_node(vector.offset(hp, 0, 1, 0))
					if (n.name == "air" or n.name:find("grass"))
							and n2.name == "air" then
						local ho = minetest.add_entity(hp, "mc_parity:skeleton_horse")
						if ho then
							local he = ho:get_luaentity()
							if he then he._trap = true end
							table.insert(horses, ho)
						end
					end
				end
				-- riders (jockey): VL = horse:jock_to(name, rel);
				-- Mineclonia = rider:jock_to_existing(horse, bone, rel)
				for _, ho in ipairs(horses) do
					local he = ho:get_luaentity()
					if he then
						if he.jock_to then
							he:jock_to("mobs_mc:skeleton", { x = 0, y = 1.6, z = 0 })
						elseif he.jock_to_existing then
							local sk = minetest.add_entity(p, "mobs_mc:skeleton")
							if sk then
								local sle = sk:get_luaentity()
								if sle then
									sle:jock_to_existing(ho, "", { x = 0, y = 1.6, z = 0 }, vector.zero())
								end
							end
						end
					end
				end
				break
			end
		end
	end)
end

minetest.log("action", "[mc_parity] loaded: fox, panda, camel, skeleton_horse, goat registered")

end
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("bundle") then
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

minetest.register_craftitem("mc_parity:bundle", {
	description = S("Bundle"),
	inventory_image = "mc_parity_bundle.png",
	stack_max = 1,
	groups = { bundle = 1 },
	on_use = function(itemstack, user)
		minetest.show_formspec(user:get_player_name(), "mc_parity:bundle",
			bundle_formspec(bundle_get_inv(itemstack)))
		return itemstack
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname ~= "mc_parity:bundle" then
		return
	end
	local itemstack = player:get_wielded_item()
	if itemstack:get_name() ~= "mc_parity:bundle" then
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

-- MC recipe: 6 rabbit hide + 2 string (VL: rabbit hide = leather_piece,
-- Mineclonia: plain mcl_mobitems:leather)
local hide = minetest.registered_items["mcl_mobitems:leather_piece"]
	and "mcl_mobitems:leather_piece"
	or (minetest.registered_items["mcl_mobitems:leather"]
		and "mcl_mobitems:leather")
if hide then
	minetest.register_craft({
		output = "mc_parity:bundle",
		recipe = {
			{hide, hide, hide},
			{hide, "mcl_mobitems:string", hide},
			{hide, "mcl_mobitems:string", hide},
		},
	})
end

-- ---------------------------------------------------------------------------
-- SHULKER UPGRADE — MC-parity face attachment + the 900-degree spin quirk.
-- Patches the game's own mobs_mc:shulker at runtime (works on both games):
--   VoxeLibre: adds 6-face attachment + rotation + spin (was static)
--   Mineclonia: adds the spin animation (was instant rotation)
end
-- See shulker_upgrade.lua.
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("shulker_upgrade") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/shulker_upgrade.lua")
end

-- ---------------------------------------------------------------------------
-- DEEP DARK + ANCIENT CITY — MC 1.19. Ports the DeepDark biome + sculk
-- generation to VoxeLibre (Mineclonia has it), adds the FULL Ancient City
-- for both games (Mineclonia has only the mini hermitage), and makes
-- sculk shriekers functional. See deepdark.lua.
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/deepdark.lua")

-- ---------------------------------------------------------------------------
-- VIBRATION SYSTEM + WARDEN — MC 1.19 sculk mechanics + the warden (imported
-- from Bettercraft, with unique AI: hearing, shrieker-summon, sonic boom).
-- Order matters: vibrations.lua (event bus) must load before warden.lua
-- (registers a vibration listener). See vibrations.lua / warden.lua.
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("sculk") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/vibrations.lua")
end
if mc_parity.feature_enabled("warden") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/warden.lua")
end

-- ---------------------------------------------------------------------------
-- IMPORTED MOBS (Bettercraft, GPLv3): frog, turtle, phantom, sniffer —
-- see mobs_import.lua. Must load AFTER register_spawn helper + register_egg.
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_import.lua")

-- ---------------------------------------------------------------------------
-- ALLAY (Bettercraft import + movement rewrite for both games) — allay.lua
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("allay") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/allay.lua")
end

-- ---------------------------------------------------------------------------
-- SPECTATOR MODE + NETHER LAVA (see spectator.lua / nether_lava.lua)
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("spectator") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/spectator.lua")
end
if mc_parity.feature_enabled("nether_lava") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/nether_lava.lua")
end

-- ---------------------------------------------------------------------------
-- MC 1.20.5/1.21: ARMADILLO + WOLF VARIANTS + WOLF ARMOR (see mobs_121.lua)
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_121.lua")
if mc_parity.feature_enabled("bee") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_bee.lua")
end
if mc_parity.feature_enabled("trial_chambers") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_trial.lua")
end
if mc_parity.feature_enabled("trail_ruins") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_ruins.lua")
end

-- ---------------------------------------------------------------------------
-- PORTED MC MOBS: creeper, enderman, blaze, pufferfish, ravager,
-- wandering trader (from Mineclonia, GPLv3 — see mobs_port.lua)
-- ---------------------------------------------------------------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mobs_port.lua")

-- ---------------------------------------------------------------------------
-- GLASS CHESTS — MC mod parity (Iron Chests "Crystal Chest"); unique for
-- Luanti. Glass chest (27 slots, transparent) + semi-transparent glass
-- ender chest (shared ender inventory). See glass_chests.lua.
-- ---------------------------------------------------------------------------
if mc_parity.feature_enabled("glass_chests") then
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/glass_chests.lua")
end

-- ---------------------------------------------------------------------------
-- ITEM SOURCE TOOLTIPS — every item's hover tooltip gets a "From: ..." line
-- showing which mod/game it belongs to (the game's tt mod turns snippets
-- into extra tooltip lines).
-- Registration-order pitfall (verified 2026-08): tt's append pass runs in
-- ITS on_mods_loaded callback. If tt loads BEFORE this mod (Mineclonia does),
-- registering the snippet from OUR on_mods_loaded is TOO LATE — the pass
-- already iterated tt.registered_snippets. Fix: register immediately at
-- load time when tt exists (its append always runs after all mods load), and
-- fall back to on_mods_loaded only when tt is not loaded yet (VL order).
-- ---------------------------------------------------------------------------
local function register_source_snippet()
	if not (tt and tt.register_snippet) then return end
	local game_label = mcl_mobs.register_spawner and "Mineclonia" or "VoxeLibre"
	tt.register_snippet(function(itemstring)
		local mod = itemstring:match("^([^:]+)")
		if not mod or mod == "" then return end
		local label
		if mod == "mc_parity" then
			label = "MC Parity addon (mc_parity)"
		elseif mod:find("^mcl_", 1) or mod == "mobs_mc" then
			label = game_label .. " (" .. mod .. ")"
		else
			label = mod
		end
		return "From: " .. label
	end)
end
if tt and tt.register_snippet then
	register_source_snippet()
else
	minetest.register_on_mods_loaded(register_source_snippet)
end

-- ---------------------------------------------------------------------------
-- WIP — need new .b3d models (Blender, VL cuboid style). Textures are already
-- shipped in textures/:
--   allay     mc_parity_allay.png
--   frog      mc_parity_frog_{temperate,cold,warm}.png
--   warden    mc_parity_warden.png (+ _glow, _ears)
--   phantom   mc_parity_phantom.png (+ _eyes)
--   turtle    mc_parity_turtle.png
--   sniffer   mc_parity_sniffer.png
--   goat      mc_parity_goat.png
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
--     mesh = "mc_parity_warden.b3d",
--     textures = {{"mc_parity_warden.png"}},
--     visual_size = {x = 3.0, y = 3.0},
--     -- TODO: vibration sensing via mcl_sculk sensor events
-- }
-- mcl_mobs.register_mob("mc_parity:warden", warden)
-- register_egg("mc_parity:warden", S("Warden"), "#0a3b2e", "#7ef0c8", 0)
-- ---------------------------------------------------------------------------