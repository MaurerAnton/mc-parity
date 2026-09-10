-- ---------------------------------------------------------------------------
-- PALE GARDEN (MC 1.21.4) — the full pale oak wood set + biome for
-- VoxeLibre. Mineclonia ships this as `mcl_pale_oak` (mcl_trees API);
-- VoxeLibre has nothing, so this module ports it via VL's mcl_core wood
-- APIs. Skipped automatically when the running game already provides
-- pale oak (Mineclonia) or lacks the VL wood API.
--
-- Assets (textures + tree schematics) are ported from Mineclonia
-- (GPLv3 code / CC BY-SA 4.0 media, based on Pixel Perfection) and
-- rewritten to our node ids by tools/port_pale_oak.py.
--
-- Scope: wood set (log/wood/stripped/planks/leaves/sapling/door/
-- trapdoor/fence/gate/stairs/slab/sign), pale moss + carpet, hanging
-- moss, block of resin, PaleGarden biome with pale oak trees and
-- eyeblossom/moss decorations. The creaking/heart tie-in stays in
-- mobs_pale.lua (it now also scatters in PaleGarden).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")
local modpath = minetest.get_modpath(minetest.get_current_modname())

-- VL-only: need the mcl_core wood API and no pre-existing pale oak
local function game_has_pale_oak()
	for name in pairs(minetest.registered_items) do
		if name:find("^mcl_pale_oak:") then return true end
	end
	return false
end

if not (mcl_core and mcl_core.register_tree_trunk) or game_has_pale_oak() then
	minetest.log("action", "[mc_parity] pale oak: skipped (game provides it or no VL wood API)")
	return
end

local TEX = {
	log = "mc_parity_pale_oak_log.png",
	log_top = "mc_parity_pale_oak_log_top.png",
	stripped = "mc_parity_pale_oak_log_stripped.png",
	stripped_top = "mc_parity_pale_oak_log_top_stripped.png",
	planks = "mc_parity_pale_oak_planks.png",
	leaves = "mc_parity_pale_oak_leaves.png",
	sapling = "mc_parity_pale_oak_sapling.png",
	moss = "mc_parity_pale_oak_moss.png",
	hanging = "mc_parity_pale_oak_hanging_moss.png",
	hanging_tip = "mc_parity_pale_oak_hanging_moss_tip.png",
	door_bottom = "mc_parity_pale_oak_door_bottom.png",
	door_top = "mc_parity_pale_oak_door_top.png",
	door_inv = "mc_parity_pale_oak_door_inv.png",
	trapdoor = "mc_parity_pale_oak_trapdoor.png",
	trapdoor_side = "mc_parity_pale_oak_trapdoor_side.png",
}

-- ------------------------------------------------------------- wood set --
mcl_core.register_tree_trunk("pale_oak_tree", S("Pale Oak Log"),
	S("Pale Oak Wood"), S("The trunk of a pale oak tree."),
	TEX.log_top, TEX.log, "mc_parity:pale_oak_stripped_tree")

mcl_core.register_stripped_trunk("pale_oak_stripped_tree",
	S("Stripped Pale Oak Log"), S("Stripped Pale Oak Wood"),
	S("The stripped trunk of a pale oak tree."),
	S("The stripped wood of a pale oak tree."),
	TEX.stripped_top, TEX.stripped)

mcl_core.register_wooden_planks("pale_oak_planks", S("Pale Oak Planks"),
	{ TEX.planks })

mcl_core.register_leaves("pale_oak_leaves", S("Pale Oak Leaves"),
	S("Pale oak leaves are grown from pale oak trees."),
	{ TEX.leaves }, nil, "none", nil, "mc_parity:pale_oak_sapling", false,
	{ 20, 16, 12, 10 })

mcl_core.register_sapling("pale_oak_sapling", S("Pale Oak Sapling"),
	S("Pale oak sapling can be planted to grow pale oak trees."),
	nil, TEX.sapling, { -4 / 16, -0.5, -4 / 16, 4 / 16, 0.25, 4 / 16 })

-- door / trapdoor (VL API)
if mcl_doors and mcl_doors.register_door then
	mcl_doors:register_door("mc_parity:pale_oak_door", {
		description = S("Pale Oak Door"),
		inventory_image = TEX.door_inv,
		groups = { handy = 1, axey = 1, material_wood = 1, flammable = -1 },
		_mcl_hardness = 3,
		_mcl_blast_resistance = 3,
		tiles_bottom = TEX.door_bottom,
		tiles_top = TEX.door_top,
		sounds = mcl_sounds.node_sound_wood_defaults(),
	})
	mcl_doors:register_trapdoor("mc_parity:pale_oak_trapdoor", {
		description = S("Pale Oak Trapdoor"),
		tile_front = TEX.trapdoor,
		tile_side = TEX.trapdoor_side,
		wield_image = TEX.trapdoor,
		groups = { handy = 1, axey = 1, mesecon_effector_on = 1,
			material_wood = 1, flammable = -1 },
		_mcl_hardness = 3,
		_mcl_blast_resistance = 3,
		sounds = mcl_sounds.node_sound_wood_defaults(),
	})
end

-- stairs / slabs
if mcl_stairs and mcl_stairs.register_stair then
	local groups = { handy = 1, axey = 1, flammable = 3, material_wood = 1,
		fire_encouragement = 5, fire_flammability = 20 }
	mcl_stairs.register_stair("pale_oak_planks", "mc_parity:pale_oak_planks",
		table.merge(groups, { wood_stairs = 1 }), { TEX.planks },
		S("Pale Oak Stairs"), mcl_sounds.node_sound_wood_defaults(),
		nil, nil, "woodlike")
	mcl_stairs.register_slab("pale_oak_planks", "mc_parity:pale_oak_planks",
		table.merge(groups, { wood_slab = 1 }), { TEX.planks },
		S("Pale Oak Slab"), mcl_sounds.node_sound_wood_defaults(),
		nil, nil, S("Double Pale Oak Slab"))
end

-- fence + gate
if mcl_fences and mcl_fences.register_fence_and_fence_gate then
	local wood = minetest.registered_nodes["mcl_core:wood"]
	mcl_fences.register_fence_and_fence_gate("pale_oak_fence",
		S("Pale Oak Fence"), S("Pale Oak Fence Gate"), TEX.planks,
		{ handy = 1, axey = 1, flammable = 2, fence_wood = 1,
			fire_encouragement = 5, fire_flammability = 20 },
		wood and wood._mcl_hardness or 2,
		wood and wood._mcl_blast_resistance or 3,
		{ "group:fence_wood" })
end

-- sign (registers in the mcl_signs namespace, like the game's own woods;
-- Mineclonia ships no sign texture, so the planks texture is used)
if mcl_signs and mcl_signs.register_sign then
	mcl_signs.register_sign("pale_oak", "#c3c3bd", {
		description = S("Pale Oak Sign"),
		tiles = { TEX.planks },
		inventory_image = TEX.planks,
		wield_image = TEX.planks,
	})
	minetest.register_craft({
		output = "mcl_signs:wall_sign_pale_oak 3",
		recipe = {
			{ "mc_parity:pale_oak_planks", "mc_parity:pale_oak_planks", "mc_parity:pale_oak_planks" },
			{ "mc_parity:pale_oak_planks", "mc_parity:pale_oak_planks", "mc_parity:pale_oak_planks" },
			{ "", "mcl_core:stick", "" },
		},
	})
end

-- crafting (MC recipes; the mcl_core helpers already add bark + log->planks)
minetest.register_craft({
	output = "mc_parity:pale_oak_planks 4",
	recipe = { { "mc_parity:pale_oak_stripped_tree" } },
})
minetest.register_craft({
	output = "mc_parity:pale_oak_planks 4",
	recipe = { { "mc_parity:pale_oak_stripped_tree_bark" } },
})

-- --------------------------------------------------------- sapling growth --
local function grow_pale_oak(pos)
	local r = math.random(1, 3)
	local off = (r == 3) and -3 or -2
	minetest.place_schematic(vector.offset(pos, off, 0, off),
		modpath .. "/schematics/mc_parity_pale_oak_" .. r .. ".mts",
		"random", nil, false)
end

minetest.register_abm({
	label = "Pale oak growth",
	nodenames = { "mc_parity:pale_oak_sapling" },
	neighbors = { "group:soil_sapling" },
	interval = 30,
	chance = 3,
	action = function(pos)
		grow_pale_oak(pos)
	end,
})

-- bone meal: mcl_core.grow_sapling has no pale oak branch — patch the
-- registered sapling (the turtle-armor pattern: runtime node def patch)
do
	local sap = minetest.registered_nodes["mc_parity:pale_oak_sapling"]
	if sap then
		sap._on_bone_meal = function(itemstack, placer, pointed_thing)
			if pointed_thing and pointed_thing.under
					and math.random(1, 100) <= 45 then
				grow_pale_oak(pointed_thing.under)
			end
		end
	end
end

-- ------------------------------------------------------------ pale moss --
minetest.register_node("mc_parity:pale_oak_moss", {
	description = S("Pale Moss"),
	tiles = { TEX.moss },
	groups = { handy = 1, hoey = 2, dirt = 1, soil = 1, soil_sapling = 2,
		soil_flower = 1, soil_generic_plant = 1, building_block = 1,
		grass_block_no_snow = 1, compostability = 65 },
	sounds = mcl_sounds.node_sound_dirt_defaults(),
	_mcl_hardness = 0.1,
})

minetest.register_node("mc_parity:pale_oak_moss_carpet", {
	description = S("Pale Moss Carpet"),
	is_ground_content = false,
	tiles = { TEX.moss },
	wield_image = TEX.moss,
	wield_scale = { x = 1, y = 1, z = 0.5 },
	groups = { handy = 1, carpet = 1, supported_node = 1, deco_block = 1,
		compostability = 30 },
	sounds = mcl_sounds.node_sound_wool_defaults(),
	paramtype = "light",
	sunlight_propagates = true,
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { { -8 / 16, -8 / 16, -8 / 16, 8 / 16, -7 / 16, 8 / 16 } },
	},
	_mcl_hardness = 0.1,
})
minetest.register_craft({
	output = "mc_parity:pale_oak_moss_carpet 3",
	recipe = { { "mc_parity:pale_oak_moss", "mc_parity:pale_oak_moss" } },
})

-- hanging moss: plantlike strands (the tree schematics place them under
-- leaves). Growth: bone meal elongates the strand by one node (max 8),
-- breaking a segment removes the floating tail below it (Mineclonia
-- behavior, adapted to VL APIs).
local MOSS_NODE = "mc_parity:pale_oak_hanging_moss"
local TIP_NODE = "mc_parity:pale_oak_hanging_moss_tip"
local MOSS_MAX = 8

local function moss_len_below(pos)
	local n = 0
	local p = vector.offset(pos, 0, -1, 0)
	while n < MOSS_MAX and minetest.get_item_group(
			minetest.get_node(p).name, "pale_hanging_moss") > 0 do
		n = n + 1
		p = vector.offset(p, 0, -1, 0)
	end
	return n, p  -- strand length below pos + first non-moss position
end

local function grow_hanging_moss(pos)
	local len, below = moss_len_below(pos)
	-- len counts the strand below pos; pos itself is the +1
	if len + 1 >= MOSS_MAX then return false end
	if minetest.get_node(below).name ~= "air" then return false end
	local tip_pos = vector.offset(below, 0, 1, 0)
	if minetest.get_node(tip_pos).name == TIP_NODE then
		minetest.swap_node(tip_pos, { name = MOSS_NODE })
	end
	minetest.set_node(below, { name = TIP_NODE })
	return true
end

local hanging_tpl = {
	description = S("Pale Hanging Moss"),
	tiles = { TEX.hanging },
	inventory_image = TEX.hanging,
	drawtype = "plantlike",
	sunlight_propagates = true,
	paramtype = "light",
	walkable = false,
	groups = { dig_immediate = 3, shearsy = 1, deco_block = 1,
		attached_node = 1, pale_hanging_moss = 1 },
	sounds = mcl_sounds.node_sound_leaves_defaults(),
	_mcl_hardness = 0,
	-- bone meal elongates the strand (3-arg VL / 4-arg MCLN signatures)
	_on_bone_meal = function(_, _, pointed_thing, pos4)
		local pos = pos4
		if type(pos) ~= "table" and type(pointed_thing) == "table" then
			pos = pointed_thing.under
		end
		if pos then grow_hanging_moss(pos) end
	end,
	on_construct = function(pos)
		local above = vector.offset(pos, 0, 1, 0)
		if minetest.get_node(above).name == TIP_NODE then
			minetest.swap_node(above, { name = MOSS_NODE })
		end
		minetest.swap_node(pos, { name = TIP_NODE })
	end,
	on_destruct = function(pos)
		local above = vector.offset(pos, 0, 1, 0)
		if minetest.get_item_group(minetest.get_node(above).name,
				"pale_hanging_moss") > 0 then
			minetest.swap_node(above, { name = TIP_NODE })
		end
		-- drop the tail below (would otherwise float)
		local p = vector.offset(pos, 0, -1, 0)
		while minetest.get_item_group(minetest.get_node(p).name,
				"pale_hanging_moss") > 0 do
			minetest.swap_node(p, { name = "air" })
			p = vector.offset(p, 0, -1, 0)
		end
	end,
}
minetest.register_node(MOSS_NODE, hanging_tpl)
minetest.register_node(TIP_NODE,
	table.merge(hanging_tpl, {
		description = S("Pale Hanging Moss Tip"),
		tiles = { TEX.hanging_tip },
		inventory_image = TEX.hanging_tip,
		groups = table.merge(hanging_tpl.groups,
			{ not_in_creative_inventory = 1 }),
	}))

-- ---------------------------------------------------------------- biome --
-- PaleGarden sits a hair off RoofedForest's heat/humidity point (94/27)
-- so it stays a rare dark-forest variant (MC parity).
if not minetest.registered_biomes["PaleGarden"]
		and minetest.registered_biomes["RoofedForest"]
		and mcl_vars and mcl_vars.mg_overworld_max then
	minetest.register_biome({
		name = "PaleGarden",
		node_top = "mc_parity:pale_oak_moss",
		depth_top = 1,
		node_filler = "mcl_core:dirt",
		depth_filler = 2,
		node_riverbed = "mcl_core:sand",
		depth_riverbed = 2,
		y_min = 1,
		y_max = mcl_vars.mg_overworld_max,
		humidity_point = 96,
		heat_point = 28,
		_mcl_biome_type = "medium",
		_mcl_grass_palette_index = 18,
		_mcl_foliage_palette_index = 7,
		_mcl_water_palette_index = 0,
		_mcl_waterfogcolor = "#3F76E4",
		_mcl_skycolor = "#79A6FF",
		_mcl_fogcolor = "#C0D8FF",
	})

	local place_on = { "mc_parity:pale_oak_moss", "mcl_core:dirt_with_grass" }
	for i = 1, 3 do
		minetest.register_decoration({
			name = "mc_parity:pale_oak_tree_" .. i,
			deco_type = "schematic",
			place_on = place_on,
			sidelen = 16,
			fill_ratio = 0.012,
			biomes = { "PaleGarden" },
			y_min = 1,
			y_max = mcl_vars.mg_overworld_max,
			schematic = modpath .. "/schematics/mc_parity_pale_oak_" .. i .. ".mts",
			rotation = "random",
			flags = "place_center_x, place_center_z, force_placement",
		})
	end
	minetest.register_decoration({
		name = "mc_parity:pale_moss_patch",
		deco_type = "simple",
		place_on = place_on,
		sidelen = 16,
		fill_ratio = 0.1,
		biomes = { "PaleGarden" },
		decoration = "mc_parity:pale_oak_moss",
	})
	minetest.register_decoration({
		name = "mc_parity:pale_moss_carpet_patch",
		deco_type = "simple",
		place_on = { "mc_parity:pale_oak_moss" },
		sidelen = 16,
		fill_ratio = 0.03,
		biomes = { "PaleGarden" },
		decoration = "mc_parity:pale_oak_moss_carpet",
	})
	minetest.register_decoration({
		name = "mc_parity:pale_eyeblossom_patch",
		deco_type = "simple",
		place_on = place_on,
		sidelen = 16,
		fill_ratio = 0.02,
		biomes = { "PaleGarden" },
		decoration = "mc_parity:eyeblossom_closed",
	})
end

minetest.log("action", "[mc_parity] pale garden ported (wood set + biome)")
