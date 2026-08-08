-- ---------------------------------------------------------------------------
-- TRAIL RUINS (MC 1.20) — archaeology: suspicious sand/gravel (hidden loot
-- inside), a brush tool, pottery sherds + decorated pot, the Relic music
-- disc, and a small buried ruin structure.
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

-- pottery sherds (9 of the 20 MC designs)
local SHERDS = {
	{ "angler", "#5a7a5a" }, { "archer", "#7a5a4a" }, { "arms_up", "#5a4a7a" },
	{ "blade", "#7a7a5a" }, { "brewer", "#4a5a7a" }, { "burn", "#8a5a4a" },
	{ "danger", "#7a4a4a" }, { "friend", "#6a7a4a" }, { "heart", "#8a4a5a" },
}
local SHERD_NAMES = {}
for _, s in ipairs(SHERDS) do
	SHERD_NAMES["mc_parity:pottery_sherd_" .. s[1]] = true
	minetest.register_craftitem("mc_parity:pottery_sherd_" .. s[1], {
		description = S("Pottery Sherd"),
		inventory_image = "mc_parity_sherd_" .. s[1] .. ".png",
		groups = { craftitem = 1 },
	})
end

-- decorated pot: 4 sherds in a square (any sherd combination)
minetest.register_node("mc_parity:decorated_pot", {
	description = S("Decorated Pot"),
	_doc_items_longdesc = S("A decorative pot made of four pottery sherds."),
	tiles = { "mc_parity_decorated_pot.png" },
	is_ground_content = false,
	groups = { handy = 1, dig_by_hand = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "mc_parity:decorated_pot 1",
	recipe = {
		{ "group:craftitem", "group:craftitem" },
		{ "group:craftitem", "group:craftitem" },
	},
})

-- ------------------------------------------------------------------ brush --
minetest.register_tool("mc_parity:brush", {
	description = S("Brush"),
	inventory_image = "mc_parity_brush.png",
	groups = { tool = 1 },
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps = {},
		damage_groups = { fleshy = 1 },
	},
})

-- -------------------------------------------- suspicious sand/gravel ----
local BRUSHING_TIME = 8

local function suspicious_blocks(pos, base, brush_use)
	local node = minetest.get_node(pos)
	local meta = minetest.get_meta(pos)
	local loot = meta:get_string("loot")
	if loot == "" then return true end  -- already emptied
	meta:set_int("progress", meta:get_int("progress") + 1)
	-- brushing particles
	minetest.add_particlespawner({
		amount = 6,
		time = 0.1,
		minpos = vector.offset(pos, -0.3, 0.1, -0.3),
		maxpos = vector.offset(pos, 0.3, 0.6, 0.3),
		minvel = { x = -1, y = 2, z = -1 }, maxvel = { x = 1, y = 4, z = 1 },
		minacc = { x = 0, y = -9, z = 0 }, maxacc = { x = 0, y = -9, z = 0 },
		texture = "mc_parity_brush_particle.png",
	})
	if meta:get_int("progress") >= BRUSHING_TIME then
		minetest.add_item(vector.offset(pos, 0, 0.8, 0), loot)
		minetest.set_node(pos, { name = base })
		meta:set_string("loot", "")
		minetest.log("action", "[mc_parity] brushed @ " .. minetest.pos_to_string(pos)
			.. " -> " .. loot)
	end
	if brush_use then brush_use() end
end

minetest.register_node("mc_parity:suspicious_sand", {
	description = S("Suspicious Sand"),
	_doc_items_longdesc = S("Sand with something hidden inside. Brush it to "
		.. "carefully reveal the loot."),
	tiles = { "mc_parity_suspicious_sand.png" },
	is_ground_content = true,
	groups = { sand = 1, dig_by_hand = 1, falling_node = 1 },
	sounds = mcl_sounds.node_sound_sand_defaults(),
	on_rightclick = function(pos, node, player, itemstack)
		if itemstack:get_name() ~= "mc_parity:brush" then return itemstack end
		local name = player:get_player_name()
		if not minetest.is_creative_enabled(name) then
			itemstack:add_wear(65535 / 64)  -- 64 uses
		end
		suspicious_blocks(pos, "mcl_core:sand", function() end)
		return itemstack
	end,
})

minetest.register_node("mc_parity:suspicious_gravel", {
	description = S("Suspicious Gravel"),
	_doc_items_longdesc = S("Gravel with something hidden inside. Brush it to "
		.. "carefully reveal the loot."),
	tiles = { "mc_parity_suspicious_gravel.png" },
	is_ground_content = true,
	groups = { dig_by_hand = 1, falling_node = 1 },
	sounds = mcl_sounds.node_sound_gravel_defaults(),
	on_rightclick = function(pos, node, player, itemstack)
		if itemstack:get_name() ~= "mc_parity:brush" then return itemstack end
		local name = player:get_player_name()
		if not minetest.is_creative_enabled(name) then
			itemstack:add_wear(65535 / 64)
		end
		suspicious_blocks(pos, "mcl_core:gravel", function() end)
		return itemstack
	end,
})

-- Relic music disc (plays a game track — CC BY-SA, compatible)
if mcl_jukebox and mcl_jukebox.register_record then
	mcl_jukebox.register_record({
		title = "Relic", author = "Aaron Cherof", id = "relic",
		texture = "mc_parity_disc_relic.png", sound = "mcl_jukebox_track_1.ogg",
	})
end

-- ------------------------------------------------------------ structure --
local RUIN_LOOT = {
	"mc_parity:pottery_sherd_angler 1",
	"mc_parity:pottery_sherd_archer 1",
	"mc_parity:pottery_sherd_arms_up 1",
	"mc_parity:pottery_sherd_blade 1",
	"mc_parity:pottery_sherd_brewer 1",
	"mc_parity:pottery_sherd_burn 1",
	"mc_parity:pottery_sherd_danger 1",
	"mc_parity:pottery_sherd_friend 1",
	"mc_parity:pottery_sherd_heart 1",
	"mcl_core:emerald 2",
	"mcl_core:coal_lump 4",
	"mcl_core:iron_ingot 2",
	"mcl_mobitems:bone 3",
	"mcl_jukebox:record_relic 1",
}

local function make_area_local(pos, size)
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

function mc_parity.build_trail_ruins(pos, def, pr, blockseed)
	local area = make_area_local(pos, { x = 9, y = 4, z = 9 })

	local MB = "mcl_mud:mud_bricks"
	local PM = "mcl_mud:packed_mud"
	local GR = "mcl_core:gravel"
	local SG = "mc_parity:suspicious_gravel"
	local SS = "mc_parity:suspicious_sand"

	local function set(p, name)
		area:set_node(p, { name = name })
	end

	-- ground pad (gravel) + walls (mud bricks) + buried fill
	for x = 0, 9 do
		for z = 0, 9 do
			set({ x = pos.x + x, y = pos.y, z = pos.z + z }, GR)
		end
	end
	for x = 0, 9 do
		for y = 1, 4 do
			set({ x = pos.x + x, y = pos.y + y, z = pos.z }, MB)
			set({ x = pos.x + x, y = pos.y + y, z = pos.z + 9 }, MB)
		end
	end
	for x = 0, 9 do
		for y = 1, 4 do
			for z = 0, 9 do
				set({ x = pos.x, y = pos.y + y, z = pos.z + z }, MB)
				set({ x = pos.x + 9, y = pos.y + y, z = pos.z + z }, MB)
			end
		end
	end
	-- inner partitions (partly collapsed) + packed-mud columns
	for x = 3, 6 do
		set({ x = pos.x + x, y = pos.y + 1, z = pos.z + 3 }, MB)
		set({ x = pos.x + x, y = pos.y + 2, z = pos.z + 3 }, MB)
		set({ x = pos.x + x, y = pos.y + 1, z = pos.z + 6 }, MB)
	end
	set(vector.offset(pos, 2, 0, 2), PM)
	set(vector.offset(pos, 7, 0, 7), PM)
	set(vector.offset(pos, 7, 1, 7), PM)
	set(vector.offset(pos, 2, 0, 7), PM)
	-- partially buried: fill the top layer with gravel
	for x = 2, 7 do
		for z = 2, 7 do
			if (x + z) % 3 ~= 0 then
				set({ x = pos.x + x, y = pos.y + 4, z = pos.z + z }, GR)
			end
		end
	end
	-- suspicious blocks with the loot
	local r = PseudoRandom(pos.x * 3 + pos.y * 7 + pos.z * 11)
	for i = 1, 4 do
		local sx, sz = r:next(1, 8), r:next(1, 8)
		local sp = { x = pos.x + sx, y = pos.y + 1, z = pos.z + sz }
		local node = (r:next(1, 2) == 1) and SG or SS
		set(sp, node)
		minetest.get_meta(sp):set_string("loot", RUIN_LOOT[r:next(1, #RUIN_LOOT)])
	end

	area:write_to_map()
	minetest.log("action", "[mc_parity] trail ruins built @ " .. minetest.pos_to_string(pos))
end

if mcl_structures and mcl_structures.register_structure then
	mcl_structures.register_structure("mc_parity:trail_ruins", {
		place_on = { "mcl_core:grass_block", "mcl_core:podzol" },
		biomes = {
			"Taiga", "ColdTaiga", "MegaTaiga", "MegaSpruceTaiga",
			"IcePlains", "IcePlainsSpikes",
		},
		y_min = -2,
		y_max = 8,
		place_func = mc_parity.build_trail_ruins,
		flags = "place_center_x, place_center_z",
	})
end

minetest.log("action", "[mc_parity] trail ruins registered")
