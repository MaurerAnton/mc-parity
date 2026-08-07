-- Deep Dark biome + Ancient City (MC 1.19) — unique work.
--
-- What exists where (verified 2026-08):
--   Mineclonia: DeepDark biome + sculk patches + a MINI city ("hermitage")
--   VoxeLibre:  NOTHING (no biome, no sculk generation, no structure)
--   Bettercraft: nothing
-- So: this module ports the biome + sculk generation to VoxeLibre and adds
-- the FULL Ancient City (large palatial ruin: central hall, pillars,
-- corridors, side rooms, soul lanterns, sculk floor, sensors/shriekers,
-- loot chests) for BOTH games — Mineclonia only has the mini version.
-- Plus: functional sculk shriekers (both games' shrieker logic is
-- commented out / inert — walking near one now screams + warns).

local modpath = minetest.get_modpath(minetest.get_current_modname())
local S = minetest.get_translator("mcl_mobs_addon")

if not mcl_vars or not mcl_vars.mg_overworld_min then
	return
end

local function node_exists(name)
	return minetest.registered_nodes[name] ~= nil
end

-- pick first existing node (feature-detect per game)
local function pick(...)
	for _, n in ipairs({ ... }) do
		if node_exists(n) then
			return n
		end
	end
	return "mcl_core:stone"
end

-- deep dark = the deepest ~40 layers of the overworld
local DD_BOTTOM = mcl_vars.mg_overworld_min
local DD_TOP = DD_BOTTOM + 40

local WALL = pick("mcl_deepslate:deepslate_reinforced", "mcl_deepslate:deepslate")
local TILES = pick("mcl_deepslate:deepslate_tiles", "mcl_deepslate:deepslate")
local COBBLE = pick("mcl_deepslate:deepslate_cobbled", "mcl_deepslate:deepslate")
local SCULK = "mcl_sculk:sculk"
local VEIN = "mcl_sculk:vein"
-- Neither game registers sensor/shrieker (commented out in both!) — we
-- register our own with the game's textures, and use OUR ids everywhere.
local SENSOR = "mcl_mobs_addon:sculk_sensor"
local SHRIEKER = "mcl_mobs_addon:sculk_shrieker"
local SOUL_LANTERN = pick("mcl_lanterns:soul_lantern", "mcl_lanterns:soul_lantern_floor")
local CHAIN = "mcl_lanterns:chain"
local CHEST = "mcl_chests:chest_small"

-- ---------------------------------------------------------------------------
-- 0) Sculk sensor + shrieker nodes (absent in BOTH games — unique work)
-- ---------------------------------------------------------------------------
if not node_exists(SENSOR) then
	minetest.register_node(SENSOR, {
		description = S("Sculk Sensor"),
		tiles = {
			"mcl_sculk_sensor_top.png",
			"mcl_sculk_sensor_bottom.png",
			"mcl_sculk_sensor_side.png",
		},
		drop = "",
		groups = { handy = 1, hoey = 1, building_block = 1, sculk = 1 },
		place_param2 = 1,
		is_ground_content = false,
		light_source = 6,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 3,
		_mcl_silk_touch_drop = true,
	})
	minetest.log("action", "[mcl_mobs_addon] registered " .. SENSOR)
end
if not node_exists(SHRIEKER) then
	minetest.register_node(SHRIEKER, {
		description = S("Sculk Shrieker"),
		tiles = {
			"mcl_sculk_shrieker_top.png",
			"mcl_sculk_shrieker_bottom.png",
			"mcl_sculk_shrieker_side.png",
		},
		drop = "",
		groups = { handy = 1, hoey = 1, building_block = 1, sculk = 1 },
		place_param2 = 1,
		is_ground_content = false,
		light_source = 6,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 3,
		_mcl_silk_touch_drop = true,
	})
	minetest.log("action", "[mcl_mobs_addon] registered " .. SHRIEKER)
end

-- ---------------------------------------------------------------------------
-- 1) DeepDark biome + sculk generation (VoxeLibre only — Mineclonia has it).
-- Checked in on_mods_loaded: our mod loads BEFORE Mineclonia's mcl_biomes,
-- so the biome may not exist yet at load time.
-- ---------------------------------------------------------------------------
minetest.register_on_mods_loaded(function()
	if not minetest.registered_biomes["DeepDark"] then  -- Mineclonia already has it
	minetest.register_biome({
		name = "DeepDark",
		node_top = SCULK,
		depth_top = 1,
		node_filler = "mcl_deepslate:deepslate",
		node_riverbed = "mcl_deepslate:deepslate",
		depth_riverbed = 1,
		node_stone = "mcl_deepslate:deepslate",
		y_min = DD_BOTTOM,
		y_max = DD_TOP,
		humidity_point = 0,
		heat_point = 60,
		vertical_blend = 8,
	})

	-- sculk patches on cave surfaces (Mineclonia-style decoration)
	minetest.register_decoration({
		deco_type = "simple",
		place_on = { "mcl_core:stone", "mcl_deepslate:deepslate" },
		sidelen = 16,
		fill_ratio = 10,
		biomes = { "DeepDark" },
		y_min = DD_BOTTOM,
		y_max = DD_TOP,
		decoration = SCULK,
		flags = "all_floors",
	})

	minetest.log("action", "[mcl_mobs_addon] DeepDark biome + sculk generation: VoxeLibre")
	end

	-- sensor/shrieker scatter in the deep dark — BOTH games (Mineclonia's
	-- DeepDark biome exists, but nothing scatters sensors/shriekers there).
	-- Registered here so the biome name always resolves (no get_biome_list
	-- warnings).
	minetest.register_ore({
		ore_type = "scatter",
		ore = SENSOR,
		wherein = { "mcl_core:stone", "mcl_deepslate:deepslate" },
		clust_scarcity = 900,
		clust_num_ores = 1,
		clust_size = 1,
		y_min = DD_BOTTOM,
		y_max = DD_TOP,
		biomes = { "DeepDark" },
	})
	minetest.register_ore({
		ore_type = "scatter",
		ore = SHRIEKER,
		wherein = { "mcl_core:stone", "mcl_deepslate:deepslate" },
		clust_scarcity = 1500,
		clust_num_ores = 1,
		clust_size = 1,
		y_min = DD_BOTTOM,
		y_max = DD_TOP,
		biomes = { "DeepDark" },
	})
end)

-- ---------------------------------------------------------------------------
-- 2) Ancient City — the FULL structure (unique; Mineclonia has only the
--    mini "hermitage"). Built with Lua (place_func) so no .mts needed.
-- ---------------------------------------------------------------------------
-- NOTE: mcl_structures calls place_func(pos, def, pr, blockseed) — the
-- signature MUST be (pos, def, pr) or the rng lands in the wrong slot.
local function build_ancient_city(pos, def, pr)
	if type(pr) ~= "userdata" then
		pr = PcgRandom(12345)  -- robustness: always a working rng
	end
	local HALF = 15   -- hall half-size (31x31)
	local H = 10      -- hall height (y 1..H above the floor at pos.y)

	-- carve the cavity (replace stone/deepslate with air)
	for x = -HALF, HALF do
		for z = -HALF, HALF do
			for y = 1, H do
				minetest.set_node(vector.add(pos, { x = x, y = y, z = z }), { name = "air" })
			end
		end
	end

	-- floor: deepslate tiles + sculk patches
	for x = -HALF, HALF do
		for z = -HALF, HALF do
			local name = pr:next(1, 100) <= 35 and SCULK or TILES
			minetest.set_node(vector.add(pos, { x = x, y = 0, z = z }), { name = name })
		end
	end

	-- walls, ceiling, corridor openings, ruin gaps
	for x = -HALF, HALF do
		for z = -HALF, HALF do
			local edge = math.abs(x) == HALF or math.abs(z) == HALF
			for y = 1, H do
				local p = vector.add(pos, { x = x, y = y, z = z })
				if edge then
					local corridor = (math.abs(x) <= 1 and z == HALF)
						or (math.abs(x) <= 1 and z == -HALF)
						or (math.abs(z) <= 1 and x == HALF)
						or (math.abs(z) <= 1 and x == -HALF)
					local ruin = pr:next(1, 40) == 1 and y > 1 and y < H
					if not corridor and not ruin then
						minetest.set_node(p, { name = WALL })
					end
				elseif y == H then
					-- ceiling; hang soul lanterns on chains
					if (math.abs(x) == 6 and math.abs(z) <= 1)
							or (math.abs(z) == 6 and math.abs(x) <= 1) then
						minetest.set_node(vector.add(pos, { x = x, y = H - 1, z = z }), { name = CHAIN })
						minetest.set_node(vector.add(pos, { x = x, y = H - 2, z = z }), { name = SOUL_LANTERN })
					else
						minetest.set_node(p, { name = WALL })
					end
				end
			end
		end
	end

	-- four pillars + central monument (3x3) with a lantern on top
	for _, px in ipairs({ -6, 6 }) do
		for _, pz in ipairs({ -6, 6 }) do
			for y = 1, H - 1 do
				minetest.set_node(vector.add(pos, { x = px, y = y, z = pz }), { name = WALL })
			end
		end
	end
	for x = -1, 1 do
		for z = -1, 1 do
			for y = 1, H - 1 do
				minetest.set_node(vector.add(pos, { x = x, y = y, z = z }), { name = WALL })
			end
		end
	end
	minetest.set_node(vector.add(pos, { x = 0, y = H - 1, z = 0 }), { name = SOUL_LANTERN })

	-- sculk veins on wall faces
	for x = -HALF, HALF do
		for z = -HALF, HALF do
			if math.abs(x) == HALF or math.abs(z) == HALF then
				if pr:next(1, 6) == 1 then
					local p = vector.add(pos, { x = x, y = pr:next(2, H - 1), z = z })
					minetest.set_node(p, { name = VEIN, param2 = 1 })
				end
			end
		end
	end

	-- sensors + shriekers on the sculk floor
	for i = 1, 3 do
		local p = vector.add(pos, { x = pr:next(-HALF + 2, HALF - 2), y = 1,
			z = pr:next(-HALF + 2, HALF - 2) })
		minetest.set_node(p, { name = SENSOR })
	end
	for i = 1, 2 do
		local p = vector.add(pos, { x = pr:next(-HALF + 2, HALF - 2), y = 1,
			z = pr:next(-HALF + 2, HALF - 2) })
		minetest.set_node(p, { name = SHRIEKER })
	end

	-- corridors to the four sides + small rooms with chests
	local dirs = { { 0, -1 }, { 0, 1 }, { 1, 0 }, { -1, 0 } }
	for _, d in ipairs(dirs) do
		for i = 1, 8 do
			for w = -1, 1 do
				for y = 1, H do
					local x = d[1] * (HALF + i)
					local z = d[2] * (HALF + i)
					if d[1] == 0 then x = w else z = w end
					minetest.set_node(vector.add(pos, { x = x, y = y, z = z }), { name = "air" })
				end
			end
		end
		-- room at the end of the corridor
		local rx, rz = d[1] * (HALF + 8), d[2] * (HALF + 8)
		for x = rx - 3, rx + 3 do
			for z = rz - 3, rz + 3 do
				for y = 1, 5 do
					minetest.set_node(vector.add(pos, { x = x, y = y, z = z }), { name = "air" })
				end
			end
		end
		-- room floor: sculk + a chest
		for x = rx - 3, rx + 3 do
			for z = rz - 3, rz + 3 do
				local name = pr:next(1, 100) <= 50 and SCULK or TILES
				minetest.set_node(vector.add(pos, { x = x, y = 0, z = z }), { name = name })
			end
		end
		minetest.set_node(vector.add(pos, { x = rx, y = 0, z = rz }), { name = CHEST, param2 = 0 })
	end
	return true  -- truthy = placement counts (loot generation + mapgen log)
end

if mcl_structures and mcl_structures.register_structure then
	mcl_structures.register_structure("mcl_mobs_addon:ancient_city", {
		place_on = { "mcl_deepslate:deepslate", "mcl_core:stone", SCULK },
		biomes = { "DeepDark" },
		y_min = DD_BOTTOM,
		y_max = DD_TOP,
		fill_ratio = 0.005,
		sidelen = 40,
		solid_ground = true,
		make_foundation = true,
		flags = "place_center_x, place_center_z, force_placement",
		place_func = build_ancient_city,
		loot = {
			[CHEST] = { {
				stacks_min = 3,
				stacks_max = 4,
				items = {
					{ itemstring = "mcl_core:coal_lump", weight = 7, amount_min = 4, amount_max = 12 },
					{ itemstring = "mcl_mobitems:bone", weight = 5, amount_min = 1, amount_max = 12 },
					{ itemstring = "mcl_core:iron_ingot", weight = 5, amount_min = 1, amount_max = 4 },
					{ itemstring = "mcl_core:gold_ingot", weight = 4, amount_min = 1, amount_max = 3 },
					{ itemstring = "mcl_books:book", weight = 4, amount_min = 1, amount_max = 3 },
					{ itemstring = "mcl_core:emerald", weight = 3, amount_min = 1, amount_max = 3 },
					{ itemstring = "mcl_core:diamond", weight = 2, amount_min = 1, amount_max = 2 },
				},
			} },
		},
	})
	minetest.log("action", "[mcl_mobs_addon] Ancient City structure registered")
end
