-- Glass Chests — MC mod parity (cpw/ironchest "Crystal Chest" is the
-- canonical glass chest; MC vanilla has no glass chests at all).
--
-- Checked 2026-08: NO glass chest exists anywhere in the Luanti ecosystem
-- (ContentDB, both clone trees, Bettercraft, GitHub code search). Unique
-- work. Delivered:
--   glass chest        — transparent chest, 27 slots (VL: full register_chest
--                        variant incl. double chest + lid entity; Mineclonia:
--                        static nodebox variant, same storage)
--   glass ender chest  — (semi)transparent ender chest sharing the player's
--                        ender inventory (VL: with lid entity; Mineclonia:
--                        static, no lid animation)
-- Textures are the game's own chest textures + alpha/colorize modifiers
-- (no new media needed): mcl_chests_normal / mcl_chests_ender ^[opacity.

local S = minetest.get_translator("mc_parity")

local function glassify(tex)
	-- see-through with a subtle glass tint
	return tex .. "^[colorize:#cfe8ff:40^[opacity:120"
end

local CHEST_BOX = { -0.4375, -0.5, -0.4375, 0.4375, 0.375, 0.4375 }

-- ---------------------------------------------------------------------------
-- VoxeLibre branch: manual registration under OUR prefix. (register_chest
-- would create mcl_chests:* ids, which Luanti 5.16 blocks from other mods —
-- "Name does not follow naming conventions"; the game's own example.lua
-- works only because it lives INSIDE mcl_chests.) The chest entity helpers
-- (mcl_chests.create_entity / player_chest_open) are public — used here.
-- v1: single chest only (double-chest linking needs the API internals).
-- ---------------------------------------------------------------------------
if mcl_chests and mcl_chests.create_entity and mcl_chests.tiles then
	local NODE = "mc_parity:glass_chest"
	local NODE_SMALL = "mc_parity:glass_chest_small"
	local GLASS_SMALL = glassify(mcl_chests.tiles.chest_normal_small[1])
	local CHEST_SOUND = "default_chest"

	local function glass_fs(pos, title)
		return table.concat({
			"formspec_version[4]",
			"size[11.75,10.425]",
			"label[0.375,0.375;" .. title .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
			"list[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
				.. ";main;0.375,0.75;9,3;]",
			"label[0.375,4.7;Inventory]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
			"list[current_player;main;0.375,5.1;9,3;9]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
			"list[current_player;main;0.375,9.05;9,1;]",
			"listring[current_player;main]",
			"listring[nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z .. ";main]",
		})
	end

	-- dummy node (placed, instantly converts to the small variant)
	minetest.register_node(NODE, {
		description = S("Glass Chest"),
		_tt_help = S("27 inventory slots") .. "\n" .. S("Transparent: you can see what's inside!"),
		drawtype = "mesh",
		mesh = "mcl_chests_chest.b3d",
		tiles = { GLASS_SMALL },
		use_texture_alpha = "blend",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = { choppy = 1, material_glass = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_glass_defaults(),
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.name = NODE_SMALL
			minetest.set_node(pos, node)
		end,
	})

	minetest.register_node(NODE_SMALL, {
		description = S("Glass Chest"),
		_tt_help = S("27 inventory slots") .. "\n" .. S("Transparent: you can see what's inside!"),
		drawtype = "nodebox",
		node_box = { type = "fixed", fixed = CHEST_BOX },
		tiles = { "blank.png^[resize:16x16" },
		use_texture_alpha = "blend",
		_chest_entity_textures = { GLASS_SMALL },
		_chest_entity_sound = CHEST_SOUND,
		_chest_entity_mesh = "mcl_chests_chest",
		_chest_entity_animation_type = "chest",
		paramtype = "light",
		paramtype2 = "facedir",
		drop = NODE,
		groups = {
			choppy = 1, material_glass = 1, container = 1, chest_entity = 1,
			deco_block = 1, not_in_creative_inventory = 1,
		},
		is_ground_content = false,
		sounds = mcl_sounds.node_sound_glass_defaults(),
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			-- chest-machinery workarounds (see mcl_chests/api.lua)
			meta:set_string("workaround", "ignore_me")
			meta:set_string("workaround", "")
			local inv = meta:get_inventory()
			inv:set_size("main", 9 * 3)
			inv:set_size("input", 1)
			mcl_chests.create_entity(pos, NODE_SMALL, { GLASS_SMALL },
				minetest.get_node(pos).param2, false, CHEST_SOUND, "mcl_chests_chest", "chest")
		end,
		after_dig_node = function(pos)
			local inv = minetest.get_meta(pos):get_inventory()
			for i = 1, inv:get_size("main") do
				local stack = inv:get_stack("main", i)
				if not stack:is_empty() then
					minetest.add_item(pos, stack)
				end
			end
		end,
		on_rightclick = function(pos, node, clicker)
			local top = minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name]
			if top and top.groups.opaque == 1 then
				return false
			end
			minetest.show_formspec(clicker:get_player_name(),
				"mc_parity:glass_chest_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
				glass_fs(pos, S("Glass Chest")))
			mcl_chests.player_chest_open(clicker, pos, NODE_SMALL, { GLASS_SMALL },
				node.param2, false, CHEST_SOUND, "mcl_chests_chest")
		end,
		_mcl_blast_resistance = 0.3,
		_mcl_hardness = 0.3,
	})

	minetest.register_craft({
		output = NODE,
		recipe = {
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_chests:chest", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
		},
	})

	-- Glass ender chest — full pattern (with lid entity), ender.lua style
	local GLASSY_ENDER = glassify("mcl_chests_ender")

	minetest.register_node("mc_parity:ender_chest_glass", {
		description = S("Glass Ender Chest"),
		_tt_help = S("27 interdimensional inventory slots") .. "\n" ..
			S("Put items inside, retrieve them from any ender chest"),
		drawtype = "mesh",
		mesh = "mcl_chests_chest.b3d",
		tiles = { GLASSY_ENDER },
		use_texture_alpha = "blend",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = { deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_construct = function(pos)
			local node = minetest.get_node(pos)
			node.name = "mc_parity:ender_chest_glass_small"
			minetest.set_node(pos, node)
		end,
	})

	minetest.register_node("mc_parity:ender_chest_glass_small", {
		description = S("Glass Ender Chest"),
		_tt_help = S("27 interdimensional inventory slots") .. "\n" ..
			S("Put items inside, retrieve them from any ender chest"),
		drawtype = "nodebox",
		node_box = { type = "fixed", fixed = CHEST_BOX },
		_chest_entity_textures = { GLASSY_ENDER },
		_chest_entity_sound = "mcl_chests_enderchest",
		_chest_entity_mesh = "mcl_chests_chest",
		_chest_entity_animation_type = "chest",
		tiles = { "blank.png^[resize:16x16" },
		use_texture_alpha = "blend",
		groups = {
			pickaxey = 1, deco_block = 1, material_stone = 1,
			chest_entity = 1, not_in_creative_inventory = 1,
		},
		is_ground_content = false,
		paramtype = "light",
		light_source = 7,
		paramtype2 = "facedir",
		sounds = mcl_sounds.node_sound_stone_defaults(),
		drop = "mcl_core:glass 8",
		on_construct = function(pos)
			mcl_chests.create_entity(pos, "mc_parity:ender_chest_glass_small",
				{ GLASSY_ENDER }, minetest.get_node(pos).param2, false,
				"mcl_chests_enderchest", "mcl_chests_chest", "chest")
		end,
		on_rightclick = function(pos, node, clicker)
			local def = minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name]
			if not def or def.groups.opaque == 1 then
				return false
			end
			minetest.show_formspec(clicker:get_player_name(),
				"mc_parity:ender_chest_glass_" .. clicker:get_player_name(),
				mcl_chests.formspec_ender_chest)
			mcl_chests.player_chest_open(clicker, pos, "mc_parity:ender_chest_glass_small",
				{ GLASSY_ENDER }, node.param2, false, "mcl_chests_enderchest", "mcl_chests_chest")
		end,
		on_receive_fields = function(pos, formname, fields, sender)
			if fields.quit then
				mcl_chests.player_chest_close(sender)
			end
		end,
		_mcl_blast_resistance = 600,
		_mcl_hardness = 22.5,
		_mcl_silk_touch_drop = { "mc_parity:ender_chest_glass" },
		on_rotate = mcl_chests.simple_rotate,
	})

	minetest.register_craft({
		output = "mc_parity:ender_chest_glass",
		recipe = {
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_end:ender_eye", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
		},
	})

	minetest.log("action", "[mc_parity] glass chests: VoxeLibre (full)")

-- ---------------------------------------------------------------------------
-- Mineclonia branch: no register_chest API and its entity helpers are local —
-- static nodebox variants (same storage; no lid animation).
-- ---------------------------------------------------------------------------
elseif mcl_chests then
	local function chest_fs(pos, title)
		local p = minetest.pos_to_string(pos)
		return table.concat({
			"formspec_version[4]",
			"size[11.75,10.425]",
			"label[0.375,0.375;" .. title .. "]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
			"list[nodemeta:" .. p .. ";main;0.375,0.75;9,3;]",
			"label[0.375,4.7;Inventory]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
			"list[current_player;main;0.375,5.1;9,3;9]",
			mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
			"list[current_player;main;0.375,9.05;9,1;]",
			"listring[current_player;main]",
			"listring[nodemeta:" .. p .. ";main]",
		})
	end

	local GLASS_TILES = {
		glassify("mcl_chests_normal.png"),
		glassify("mcl_chests_normal.png"),
		glassify("mcl_chests_normal.png"),
		glassify("mcl_chests_normal.png"),
		glassify("mcl_chests_normal.png"),
		glassify("mcl_chests_normal.png"),
	}

	minetest.register_node("mc_parity:glass_chest", {
		description = S("Glass Chest"),
		drawtype = "nodebox",
		node_box = { type = "fixed", fixed = CHEST_BOX },
		selection_box = { type = "fixed", fixed = CHEST_BOX },
		collision_box = { type = "fixed", fixed = CHEST_BOX },
		tiles = GLASS_TILES,
		use_texture_alpha = "blend",
		paramtype = "light",
		paramtype2 = "facedir",
		groups = { choppy = 1, material_glass = 1, container = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_glass_defaults(),
		on_construct = function(pos)
			minetest.get_meta(pos):get_inventory():set_size("main", 27)
		end,
		on_rightclick = function(pos, node, clicker)
			local def = minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name]
			if not def or def.groups.opaque == 1 then
				return false
			end
			minetest.show_formspec(clicker:get_player_name(),
				"mc_parity:glass_chest_" .. minetest.pos_to_string(pos),
				chest_fs(pos, S("Glass Chest")))
			minetest.sound_play("default_chest_open", { pos = pos, gain = 0.5 }, true)
		end,
		on_metadata_inventory_take = function(pos)
			minetest.sound_play("default_chest_close", { pos = pos, gain = 0.5 }, true)
		end,
		_mcl_hardness = 0.3,
	})

	minetest.register_craft({
		output = "mc_parity:glass_chest",
		recipe = {
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_chests:chest", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
		},
	})

	-- glass ender chest: static, opens the shared ender inventory
	local ENDER_FS = table.concat({
		"formspec_version[4]",
		"size[11.75,10.425]",
		"label[0.375,0.375;" .. S("Glass Ender Chest") .. "]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 0.75, 9, 3),
		"list[current_player;enderchest;0.375,0.75;9,3;]",
		"label[0.375,4.7;Inventory]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 5.1, 9, 3),
		"list[current_player;main;0.375,5.1;9,3;9]",
		mcl_formspec.get_itemslot_bg_v4(0.375, 9.05, 9, 1),
		"list[current_player;main;0.375,9.05;9,1;]",
		"listring[current_player;enderchest]",
		"listring[current_player;main]",
	})
	local ENDER_TILES = {}
	for i = 1, 6 do
		ENDER_TILES[i] = glassify("mcl_chests_ender.png")
	end

	minetest.register_node("mc_parity:ender_chest_glass", {
		description = S("Glass Ender Chest"),
		drawtype = "nodebox",
		node_box = { type = "fixed", fixed = CHEST_BOX },
		selection_box = { type = "fixed", fixed = CHEST_BOX },
		collision_box = { type = "fixed", fixed = CHEST_BOX },
		tiles = ENDER_TILES,
		use_texture_alpha = "blend",
		paramtype = "light",
		light_source = 7,
		paramtype2 = "facedir",
		groups = { pickaxey = 1, deco_block = 1, material_stone = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_rightclick = function(pos, node, clicker)
			local def = minetest.registered_nodes[minetest.get_node(vector.offset(pos, 0, 1, 0)).name]
			if not def or def.groups.opaque == 1 then
				return false
			end
			minetest.show_formspec(clicker:get_player_name(),
				"mc_parity:ender_chest_glass_" .. clicker:get_player_name(), ENDER_FS)
		end,
		_mcl_blast_resistance = 600,
		_mcl_hardness = 22.5,
	})

	minetest.register_craft({
		output = "mc_parity:ender_chest_glass",
		recipe = {
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_end:ender_eye", "mcl_core:glass" },
			{ "mcl_core:glass", "mcl_core:glass", "mcl_core:glass" },
		},
	})

	minetest.log("action", "[mc_parity] glass chests: Mineclonia (static)")
end
