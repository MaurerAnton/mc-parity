-- ---------------------------------------------------------------------------
-- PRE-1.13 CLOSERS: the woodland mansion (full), end city towers (for
-- VoxeLibre — Mineclonia already has small_end_city), and the 4 missing
-- pre-1.13 music discs (cat, stal, ward, 11).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

-- dual-game dark oak (VL legacy names vs Mineclonia modern names)
local PICK = {}
local function pick(...)
	for i = 1, select("#", ...) do
		local n = select(i, ...)
		if minetest.registered_nodes[n] then return n end
	end
	return ...
end
local PLANKS = pick("mcl_core:darkwood", "mcl_trees:wood_dark_oak")
local LOG = pick("mcl_core:darktree", "mcl_trees:tree_dark_oak")
local FENCE = pick("mcl_fences:dark_oak_fence", "mcl_fences:dark_oak_fence")

-- ------------------------------------------------------------ wood mansion --
local MANOR_LOOT = {
	"mcl_mobitems:bone 4", "mcl_mobitems:gunpowder 4", "mcl_mobitems:string 4",
	"mcl_core:gold_ingot 2", "mcl_core:iron_ingot 3", "mcl_core:emerald 2",
	"mcl_mobitems:nametag 1", "mcl_farming:bread 2", "mcl_books:book 1",
	"mcl_mobitems:saddle 1", "mcl_core:diamond 1",
}

local function make_area_legacy(pos, size)
	local ok, vm = pcall(function()
		return minetest.get_mapgen_object("voxelmanip")
	end)
	if ok and vm then
		local a = VoxelArea:new({ MinEdge = pos, MaxEdge = vector.offset(pos, size.x, size.y, size.z) })
		a:set_data_from_map(vm)
		return a
	end
	return {
		set_node = function(_, p, n) minetest.set_node(p, n) end,
		write_to_map = function() end,
	}
end

local function set_box(area, a, b, node)
	for x = a.x, b.x do
		for y = a.y, b.y do
			for z = a.z, b.z do
				area:set_node({ x = x, y = y, z = z }, { name = node })
			end
		end
	end
end

local function room(area, a, b, wall, floor, ceiling)
	set_box(area, a, b, wall)                    -- solid shell
	set_box(area, vector.offset(a, 1, 1, 1), vector.offset(b, -1, -1, -1), "air")
	set_box(area, a, vector.offset(b, 0, 0, 0), "air")  -- (unused fallback)
	for x = a.x + 1, b.x - 1 do
		for z = a.z + 1, b.z - 1 do
			area:set_node({ x = x, y = a.y, z = z }, { name = floor })
		end
	end
end

local function chest(area, p, pr)
	area:set_node(p, { name = "mcl_chests:chest_small" })
	local meta = minetest.get_meta(p)
	local inv = meta:get_inventory()
	inv:set_size("main", 27)
	local n = pr:next(2, 4)
	for i = 1, n do
		local item = MANOR_LOOT[pr:next(1, #MANOR_LOOT)]
		local slot = pr:next(1, 26)
		local s = inv:get_stack("main", slot)
		if s:is_empty() then
			inv:set_stack("main", slot, item)
		end
	end
end

function mc_parity.build_woodland_mansion(pos, def, pr, blockseed)
	local pr = pr or PseudoRandom(pos.x + pos.y + pos.z)
	-- 27x27 floor, up to y+12; centre at pos
	local area = make_area_legacy(vector.offset(pos, -14, 0, -14), { x = 29, y = 13, z = 29 })
	local a = vector.offset(pos, -13, 0, -13)   -- outer wall min
	local b = vector.offset(pos, 13, 3, 13)     -- floor 1 shell (4 tall)
	local b2 = vector.offset(pos, 13, 7, 13)    -- floor 2 shell
	local roof = vector.offset(pos, 13, 9, 13)

	-- exterior shell (2 floors) + flat roof base
	set_box(area, a, b, PLANKS)
	set_box(area, vector.offset(a, 0, 4, 0), vector.offset(b, 0, 4, 0), PLANKS)  -- floor 2 slab
	set_box(area, vector.offset(a, 0, 4, 0), b2, PLANKS)
	set_box(area, vector.offset(a, 0, 8, 0), roof, LOG)  -- roof band
	-- hollow the interior (floors 1+2), leave the floor slabs
	for y = 1, 3 do
		for x = a.x + 1, b.x - 1 do
			for z = a.z + 1, b.z - 1 do
				area:set_node({ x = x, y = a.y + y, z = z }, { name = "air" })
			end
		end
	end
	for y = 5, 7 do
		for x = a.x + 1, b.x - 1 do
			for z = a.z + 1, b.z - 1 do
				area:set_node({ x = x, y = a.y + y, z = z }, { name = "air" })
			end
		end
	end
	-- door
	area:set_node(vector.offset(pos, 0, 1, -13), { name = "air" })
	area:set_node(vector.offset(pos, 0, 2, -13), { name = "air" })

	-- log corner pillars
	for _, o in ipairs({ { -13, -13 }, { 13, -13 }, { -13, 13 }, { 13, 13 } }) do
		for y = 0, 9 do
			area:set_node(vector.offset(pos, o[1], y, o[2]), { name = LOG })
		end
	end

	-- central hall + stairs (floor 1)
	for x = -4, 4 do
		for y = 1, 3 do
			area:set_node(vector.offset(pos, x, y, -6), { name = "air" })
			area:set_node(vector.offset(pos, x, y, -4), { name = "air" })
		end
	end
	area:set_node(vector.offset(pos, 0, 1, -5), { name = "mcl_stairs:stair_wood" })
	area:set_node(vector.offset(pos, 0, 2, -5), { name = "mcl_stairs:stair_wood" })

	-- floor 1 rooms: library (books), dining (carpet), farm (wheat)
	set_box(area, vector.offset(pos, -10, 1, -10), vector.offset(pos, -6, 3, -2), "air")
	for i = -9, -7 do
		area:set_node(vector.offset(pos, i, 1, -9), { name = "mcl_books:bookshelf" })
		area:set_node(vector.offset(pos, i, 2, -9), { name = "mcl_books:bookshelf" })
	end
	set_box(area, vector.offset(pos, -10, 1, 2), vector.offset(pos, -6, 3, 10), "air")
	area:set_node(vector.offset(pos, -9, 1, 8), { name = "mcl_wool:red_carpet" })
	area:set_node(vector.offset(pos, -7, 1, 8), { name = "mcl_wool:red_carpet" })
	-- farm room
	set_box(area, vector.offset(pos, 6, 1, 2), vector.offset(pos, 10, 3, 10), "air")
	for x = 7, 9 do
		for z = 4, 8 do
			if (x + z) % 2 == 0 then
				area:set_node(vector.offset(pos, x, 1, z), { name = "mcl_farming:wheat_7" })
			end
		end
	end
	-- lava room
	set_box(area, vector.offset(pos, 6, 1, -10), vector.offset(pos, 10, 3, -2), "air")
	area:set_node(vector.offset(pos, 8, 1, -6), { name = "mcl_core:lava_source" })
	-- allay cage (MC 1.19 mansion room): fence cage with a trapped allay
	set_box(area, vector.offset(pos, -2, 1, 6), vector.offset(pos, 2, 3, 10), "air")
	for x = -2, 2 do
		area:set_node(vector.offset(pos, x, 1, 6), { name = FENCE })
		area:set_node(vector.offset(pos, x, 1, 10), { name = FENCE })
		area:set_node(vector.offset(pos, x, 3, 6), { name = FENCE })
		area:set_node(vector.offset(pos, x, 3, 10), { name = FENCE })
	end
	for z = 6, 10 do
		area:set_node(vector.offset(pos, -2, 1, z), { name = FENCE })
		area:set_node(vector.offset(pos, 2, 1, z), { name = FENCE })
		area:set_node(vector.offset(pos, -2, 3, z), { name = FENCE })
		area:set_node(vector.offset(pos, 2, 3, z), { name = FENCE })
	end
	local allay = minetest.add_entity(vector.offset(pos, 0, 2, 8), "mc_parity:allay")
	if allay and allay:get_luaentity() then allay:get_luaentity()._mca_cage = true end

	-- floor 2: bedrooms (beds), obsidian room, arena (vindicator/evoker)
	local F2 = vector.offset(pos, 0, 4, 0)
	set_box(area, vector.offset(F2, -10, 1, -10), vector.offset(F2, -6, 3, -2), "air")
	area:set_node(vector.offset(F2, -9, 1, -9), { name = "mcl_beds:bed_red_bottom" })
	area:set_node(vector.offset(F2, -7, 1, -9), { name = "mcl_beds:bed_red_top" })
	set_box(area, vector.offset(F2, 6, 1, -10), vector.offset(F2, 10, 3, -2), "air")
	area:set_node(vector.offset(F2, 8, 1, -6), { name = "mcl_core:obsidian" })
	area:set_node(vector.offset(F2, 8, 2, -6), { name = "mcl_core:obsidian" })
	area:set_node(vector.offset(F2, 8, 3, -6), { name = "mcl_core:obsidian" })
	-- arena: open floor 2 centre with the vindicator + evoker
	set_box(area, vector.offset(F2, -3, 1, -3), vector.offset(F2, 3, 3, 3), "air")
	chest(area, vector.offset(F2, 3, 1, -3), pr)
	chest(area, vector.offset(F2, -3, 1, 3), pr)
	chest(area, vector.offset(F2, 3, 1, 3), pr)
	minetest.add_entity(vector.offset(F2, 1, 2, 0), "mobs_mc:vindicator")
	minetest.add_entity(vector.offset(F2, -1, 2, 0), "mobs_mc:vindicator")
	minetest.add_entity(vector.offset(F2, 0, 2, 1), "mobs_mc:evoker")
	-- chests on floor 1
	chest(area, vector.offset(pos, -10, 1, -2), pr)
	chest(area, vector.offset(pos, 10, 1, -2), pr)
	chest(area, vector.offset(pos, -10, 1, 10), pr)

	area:write_to_map()
	minetest.log("action", "[mc_parity] woodland mansion built @ " .. minetest.pos_to_string(pos))
end

if mcl_structures and mcl_structures.register_structure then
	mcl_structures.register_structure("mc_parity:woodland_mansion", {
		place_on = { "group:grass_block", "group:dirt", "mcl_core:dirt_with_grass" },
		-- Mineclonia lacks the RoofedForestM (mutated) variant — VL keeps both
		biomes = mcl_mobs.register_spawner and { "RoofedForest" }
			or { "RoofedForest", "RoofedForestM" },
		y_min = 1,
		y_max = 40,
		place_func = mc_parity.build_woodland_mansion,
		flags = "place_center_x, place_center_z",
		chunk_probability = 700,
	})
end

-- ------------------------------------------------------------ end city ----
function mc_parity.build_end_city_tower(pos, def, pr, blockseed)
	local pr = pr or PseudoRandom(pos.x * 3 + pos.y * 7 + pos.z)
	local PURPUR = pick("mcl_end:purpur_block")
	local PURPUR_PILLAR = pick("mcl_end:purpur_pillar")
	local END_STONE = pick("mcl_end:end_stone")
	local area = make_area_legacy(vector.offset(pos, -6, 0, -6), { x = 13, y = 15, z = 13 })
	-- tower: 9x9 base, 12 tall — hollow shaft + 2 rooms + roof
	local a = vector.offset(pos, -4, 0, -4)
	local b = vector.offset(pos, 4, 11, 4)
	set_box(area, a, b, PURPUR)
	for y = 1, 10 do
		for x = a.x + 1, b.x - 1 do
			for z = a.z + 1, b.z - 1 do
				area:set_node({ x = x, y = a.y + y, z = z }, { name = "air" })
			end
		end
	end
	-- floors at y=4 and y=8
	for x = a.x + 1, b.x - 1 do
		for z = a.z + 1, b.z - 1 do
			area:set_node({ x = x, y = a.y + 4, z = z }, { name = PURPUR })
			area:set_node({ x = x, y = a.y + 8, z = z }, { name = PURPUR })
		end
	end
	-- openings (windows) + the entrance
	area:set_node(vector.offset(pos, 0, 1, -4), { name = "air" })
	area:set_node(vector.offset(pos, 0, 2, -4), { name = "air" })
	for _, o in ipairs({ { 4, 5, 0 }, { -4, 5, 0 }, { 0, 5, 4 }, { 0, 5, -4 },
		{ 4, 9, 0 }, { -4, 9, 0 }, { 0, 9, 4 }, { 0, 9, -4 } }) do
		area:set_node(vector.offset(pos, o[1], o[2], o[3]), { name = "air" })
	end
	-- purpur pillars in the corners + the roof spire
	for _, o in ipairs({ { -3, -3 }, { 3, -3 }, { -3, 3 }, { 3, 3 } }) do
		for y = 0, 11 do
			area:set_node(vector.offset(pos, o[1], y, o[2]), { name = PURPUR_PILLAR })
		end
	end
	for y = 12, 14 do
		area:set_node(vector.offset(pos, 0, y, 0), { name = PURPUR_PILLAR })
	end
	-- chests (the tower loot) + the shulkers
	chest(area, vector.offset(pos, -3, 5, -3), pr)
	chest(area, vector.offset(pos, 3, 5, 3), pr)
	chest(area, vector.offset(pos, -3, 9, -3), pr)
	minetest.add_entity(vector.offset(pos, 0, 6, 0), "mobs_mc:shulker")
	minetest.add_entity(vector.offset(pos, 0, 10, 0), "mobs_mc:shulker")

	area:write_to_map()
	minetest.log("action", "[mc_parity] end city tower built @ " .. minetest.pos_to_string(pos))
end

if mcl_structures and mcl_structures.register_structure then
	mcl_structures.register_structure("mc_parity:end_city_tower", {
		place_on = { "mcl_end:end_stone" },
		biomes = { "End", "EndHighlands", "EndMidlands", "EndBarrens", "EndSmallIslands" },
		y_min = -40,
		y_max = -10,
		place_func = mc_parity.build_end_city_tower,
		flags = "place_center_x, place_center_z",
		chunk_probability = 800,
	})
end

-- ------------------------------------------------------- missing discs ----
-- the 4 pre-1.13 discs absent from both games' jukebox. The tracks reuse
-- the games' own CC BY-SA jukebox recordings (compatible with our media
-- license); the labels are painted.
if mcl_jukebox and mcl_jukebox.register_record then
	mcl_jukebox.register_record("Cat", "Jordach", "cat",
		"mc_parity_record_cat.png", "mcl_jukebox_track_3")
	mcl_jukebox.register_record("Stal", "Jordach", "stal",
		"mc_parity_record_stal.png", "mcl_jukebox_track_6")
	mcl_jukebox.register_record("Ward", "Tom Peter", "ward",
		"mc_parity_record_ward.png", "mcl_jukebox_track_5")
	mcl_jukebox.register_record("11", "SoundHelix", "11",
		"mc_parity_record_11.png", "mcl_jukebox_track_8")
end

minetest.log("action", "[mc_parity] legacy closers: mansion + end city + discs")
