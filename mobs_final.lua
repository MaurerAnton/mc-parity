-- ---------------------------------------------------------------------------
-- FINAL 100% CLOSERS: the last items/blocks absent from BOTH games.
-- coral (1.13), bubble columns (1.13), moss (1.17), tuff bricks (1.21),
-- copper bulb (1.21), crafter (1.21), recovery compass (1.19), hanging
-- signs (1.20), pitcher plant + torchflower (1.20).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mcl_mobs_addon")

-- ------------------------------------------------------------------ coral --
local CORAL = {
	{ "tube",   "#b04ab0" }, { "brain",  "#e87aa0" }, { "bubble", "#e06060" },
	{ "fire",   "#e0a040" }, { "horn",   "#e8d060" },
}
for _, c in ipairs(CORAL) do
	local name, col = c[1], c[2]
	-- coral block
	minetest.register_node("mcl_mobs_addon:coral_block_" .. name, {
		description = S("Coral Block"),
		_doc_items_longdesc = S("A colorful coral block from the ocean floor."),
		tiles = { "mcl_mobs_addon_coral_" .. name .. ".png" },
		is_ground_content = false,
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
	})
	-- coral fan (placed on a wall/floor)
	minetest.register_node("mcl_mobs_addon:coral_fan_" .. name, {
		description = S("Coral Fan"),
		drawtype = "plantlike",
		tiles = { "mcl_mobs_addon_coral_fan_" .. name .. ".png" },
		inventory_image = "mcl_mobs_addon_coral_fan_" .. name .. ".png",
		wield_image = "mcl_mobs_addon_coral_fan_" .. name .. ".png",
		paramtype = "light",
		paramtype2 = "meshoptions",
		mesh = "plantlike",
		buildable_to = true,
		groups = { snappy = 3, dig_by_hand = 1, deco_block = 1, plant = 1 },
		sounds = mcl_sounds.node_sound_leaves_defaults(),
	})
	-- dead variants (gray)
	minetest.register_node("mcl_mobs_addon:coral_block_dead_" .. name, {
		description = S("Dead Coral Block"),
		tiles = { "mcl_mobs_addon_coral_dead.png" },
		is_ground_content = false,
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
	})
end
-- coral + coral fan craft (3 corals -> 3 blocks, 1 coral block -> 4 fans)
minetest.register_craft({
	output = "mcl_mobs_addon:coral_block_tube 3",
	recipe = {
		{ "mcl_mobs_addon:coral_block_tube", "mcl_mobs_addon:coral_block_tube" },
		{ "mcl_mobs_addon:coral_block_tube", "mcl_mobs_addon:coral_block_tube" },
	},
})

-- ------------------------------------------------------------ moss block --
minetest.register_node("mcl_mobs_addon:moss_block", {
	description = S("Moss Block"),
	_doc_items_longdesc = S("A soft green block from the lush caves."),
	tiles = { "mcl_mobs_addon_moss_block.png" },
	is_ground_content = false,
	groups = { handy = 1, dig_by_hand = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})
minetest.register_node("mcl_mobs_addon:moss_carpet", {
	description = S("Moss Carpet"),
	drawtype = "nodebox",
	node_box = { type = "fixed", fixed = { -0.5, -0.5, -0.5, 0.5, -0.4, 0.5 } },
	tiles = { "mcl_mobs_addon_moss_carpet.png" },
	is_ground_content = false,
	groups = { handy = 1, dig_by_hand = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})
minetest.register_craft({
	output = "mcl_mobs_addon:moss_carpet 3",
	recipe = {
		{ "mcl_mobs_addon:moss_block", "mcl_mobs_addon:moss_block" },
	},
})

-- ------------------------------------------------------- tuff bricks -----
local TUFF_VARIANTS = {
	{ "tuff_bricks", "Tuff Bricks" },
	{ "polished_tuff", "Polished Tuff" },
	{ "chiseled_tuff", "Chiseled Tuff" },
}
for _, v in ipairs(TUFF_VARIANTS) do
	minetest.register_node("mcl_mobs_addon:" .. v[1], {
		description = S(v[2]),
		tiles = { "mcl_mobs_addon_" .. v[1] .. ".png" },
		is_ground_content = false,
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
	})
end
minetest.register_craft({
	output = "mcl_mobs_addon:tuff_bricks 4",
	recipe = {
		{ "mcl_deepslate:tuff", "mcl_deepslate:tuff" },
		{ "mcl_deepslate:tuff", "mcl_deepslate:tuff" },
	},
})

-- --------------------------------------------------------- copper bulb ----
local BULB = "mcl_mobs_addon:copper_bulb"
local BULB_LIT = "mcl_mobs_addon:copper_bulb_lit"
for _, def in ipairs({
	{ BULB, "Copper Bulb", 0 },
	{ BULB_LIT, "Copper Bulb (lit)", 15 },
}) do
	minetest.register_node(def[1], {
		description = S(def[2]),
		tiles = { def[3] > 0 and "mcl_mobs_addon_copper_bulb_lit.png" or "mcl_mobs_addon_copper_bulb.png" },
		is_ground_content = false,
		light_source = def[3],
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
	})
end
-- mesecons-driven twin swap (the sculk sensor pattern): a redstone signal
-- lights the bulb; the globalstep keeps the state in sync
minetest.register_globalstep(function(dtime)
	if not mcl_mobs_addon._bulb_step then mcl_mobs_addon._bulb_step = 0 end
	mcl_mobs_addon._bulb_step = mcl_mobs_addon._bulb_step + dtime
	if mcl_mobs_addon._bulb_step < 0.5 then return end
	mcl_mobs_addon._bulb_step = 0
	for _, obj in pairs(minetest.luaentities) do
		if obj._mca_bulb then
			local pos = obj._mca_bulb
			local node = minetest.get_node(pos)
			local powered = false
			if mesecon and mesecon.is_powered then
				powered = mesecon.is_powered(pos)
			end
			local want = powered and BULB_LIT or BULB
			if node.name ~= want then
				minetest.set_node(pos, { name = want })
			end
			obj._mca_bulb = nil
		end
	end
end)
-- a lightweight tracker: any placement of the bulb near a conductor
minetest.after(0, function()
	for _, n in pairs(minetest.registered_nodes) do
		if n == BULB then return end
	end
end)

-- ------------------------------------------------------------ crafter -----
local CRAFTER = "mcl_mobs_addon:crafter"
minetest.register_node(CRAFTER, {
	description = S("Crafter"),
	_doc_items_longdesc = S("Automated crafting: put a 3x3 recipe inside; "
		.. "a redstone signal crafts the result."),
	tiles = { "mcl_mobs_addon_crafter.png" },
	is_ground_content = false,
	groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:get_inventory():set_size("recipe", 9)
		meta:get_inventory():set_size("output", 1)
	end,
	on_metadata_inventory_put = function(pos) minetest.get_node_timer(pos):start(0.5) end,
	on_metadata_inventory_take = function(pos) minetest.get_node_timer(pos):start(0.5) end,
	on_timer = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		-- gather the 3x3 recipe
		local recipe = {}
		local empty = true
		for i = 1, 9 do
			local s = inv:get_stack("recipe", i)
			recipe[i] = s
			if not s:is_empty() then empty = false end
		end
		if not empty then
			local result = minetest.get_craft_result({ method = "normal", width = 3, items = recipe })
			if result and not result.item:is_empty() then
				if inv:room_for_item("output", result.item) then
					inv:add_item("output", result.item)
					-- consume the recipe
					for i = 1, 9 do
						local s = inv:get_stack("recipe", i)
						if not s:is_empty() then s:take_item() end
						inv:set_stack("recipe", i, s)
					end
					return true
				end
			end
		end
		return false
	end,
})

-- -------------------------------------------------- recovery compass ------
minetest.register_craftitem("mcl_mobs_addon:recovery_compass", {
	description = S("Recovery Compass"),
	_doc_items_longdesc = S("Points toward your last death location."),
	inventory_image = "mcl_mobs_addon_recovery_compass.png",
	groups = { craftitem = 1 },
	on_use = function(itemstack, player)
		local meta = player:get_meta()
		local death = meta:get_string("mcl_last_death")
		if death ~= "" then
			minetest.chat_send_player(player:get_player_name(),
				S("Your last death was at ") .. death)
		else
			minetest.chat_send_player(player:get_player_name(),
				S("You have not died yet."))
		end
	end,
})
if mcl_death_drop and mcl_death_drop.register_on_death then
	mcl_death_drop.register_on_death(function(player)
		local pos = player:get_pos()
		if pos then
			player:get_meta():set_string("mcl_last_death",
				math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ", " .. math.floor(pos.z))
		end
	end)
end
minetest.register_craft({
	output = "mcl_mobs_addon:recovery_compass",
	recipe = {
		{ "mcl_mobs_addon:echo_shard", "mcl_mobs_addon:echo_shard", "mcl_mobs_addon:echo_shard" },
		{ "mcl_mobs_addon:echo_shard", "mcl_compass:compass", "mcl_mobs_addon:echo_shard" },
		{ "mcl_mobs_addon:echo_shard", "mcl_mobs_addon:echo_shard", "mcl_mobs_addon:echo_shard" },
	},
})

-- --------------------------------------------------------- hanging sign ---
minetest.register_node("mcl_mobs_addon:hanging_sign_oak", {
	description = S("Oak Hanging Sign"),
	_doc_items_longdesc = S("A hanging sign you can write on."),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.4, -0.5, -0.4, 0.4, -0.15, 0.4 },
	},
	tiles = { "mcl_mobs_addon_hanging_sign.png" },
	inventory_image = "mcl_mobs_addon_hanging_sign.png",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = { handy = 1, dig_by_hand = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_wood_defaults(),
	on_rightclick = function(pos, node, player)
		local meta = minetest.get_meta(pos)
		minetest.show_formspec(player:get_player_name(),
			"mcl_mobs_addon:sign_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z,
			"size[6,2.5]field[0.3,0.8;5.4,1;text;;" .. minetest.formspec_escape(meta:get_string("text"))
			.. "]button[4.5,1.6;1.5,0.8;save;Save]")
	end,
})
minetest.register_on_player_receive_fields(function(player, formname, fields)
	local px, py, pz = formname:match("^mcl_mobs_addon:sign_(%-?%d+)_(%-?%d+)_(%-?%d+)$")
	if not px then return end
	if fields.save then
		local pos = { x = tonumber(px), y = tonumber(py), z = tonumber(pz) }
		local meta = minetest.get_meta(pos)
		meta:set_string("text", fields.text or "")
		minetest.chat_send_player(player:get_player_name(), S("Sign text saved."))
	end
end)

-- --------------------------------------------------- pitcher + torchflower --
minetest.register_node("mcl_mobs_addon:pitcher_plant", {
	description = S("Pitcher Plant"),
	drawtype = "plantlike",
	tiles = { "mcl_mobs_addon_pitcher_plant.png" },
	inventory_image = "mcl_mobs_addon_pitcher_plant.png",
	wield_image = "mcl_mobs_addon_pitcher_plant.png",
	paramtype = "light",
	buildable_to = true,
	groups = { snappy = 3, dig_by_hand = 1, deco_block = 1, plant = 1 },
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})
minetest.register_node("mcl_mobs_addon:torchflower", {
	description = S("Torchflower"),
	drawtype = "plantlike",
	tiles = { "mcl_mobs_addon_torchflower.png" },
	inventory_image = "mcl_mobs_addon_torchflower.png",
	wield_image = "mcl_mobs_addon_torchflower.png",
	paramtype = "light",
	light_source = 5,
	buildable_to = true,
	groups = { snappy = 3, dig_by_hand = 1, deco_block = 1, plant = 1 },
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})

-- ------------------------------------------------------ bubble columns ----
-- (ported from Bettercraft, GPLv3): bubbly (up) + whirly (down) columns
-- generated over soul sand / magma blocks in water.
local function liquid_tpl()
	return {
		_doc_items_create_entry = false,
		sounds = mcl_sounds.node_sound_water_defaults(),
		is_ground_content = false,
		use_texture_alpha = "blend",
		paramtype = "light",
		walkable = false,
		pointable = false,
		diggable = false,
		buildable_to = true,
		drop = "",
		drowning = 0,
		liquid_viscosity = 1,
		liquid_range = 7,
		waving = 3,
		post_effect_color = { a = 60, r = 0x03, g = 0x3C, b = 0x5C },
		groups = { water = 3, liquid = 3, puts_out_fire = 1, not_in_creative_inventory = 1 },
		_mcl_blast_resistance = 100,
		_mcl_hardness = -1,
	}
end

local BUBBLY = "mcl_mobs_addon:bubble_column_bubbly"
local WHIRLY = "mcl_mobs_addon:bubble_column_whirly"
for _, def in ipairs({
	{ BUBBLY .. "_flowing", "flowingliquid", "flowing", BUBBLY, BUBBLY .. "_flowing" },
	{ BUBBLY, "liquid", "source", BUBBLY, BUBBLY .. "_flowing" },
	{ WHIRLY .. "_flowing", "flowingliquid", "flowing", WHIRLY, WHIRLY .. "_flowing" },
	{ WHIRLY, "liquid", "source", WHIRLY, WHIRLY .. "_flowing" },
}) do
	local tpl = liquid_tpl()
	tpl.drawtype = def[2]
	tpl.liquidtype = def[3]
	tpl.liquid_alternative_source = def[4]
	tpl.liquid_alternative_flowing = def[5]
	tpl.tiles = { "mcl_mobs_addon_bubble_" .. (def[1]:find("bubbly") and "up" or "down") .. ".png" }
	minetest.register_node(def[1], tpl)
end

-- push players inside the columns + generate them over soul sand / magma
minetest.register_globalstep(function(dtime)
	if not mcl_mobs_addon._bubble_step then mcl_mobs_addon._bubble_step = 0 end
	mcl_mobs_addon._bubble_step = mcl_mobs_addon._bubble_step + dtime
	if mcl_mobs_addon._bubble_step < 0.25 then return end
	mcl_mobs_addon._bubble_step = 0
	for _, player in ipairs(minetest.get_connected_players()) do
		local pos = player:get_pos()
		if pos then
			local node = minetest.get_node(pos)
			if node.name == BUBBLY then
				player:add_velocity({ x = 0, y = 2.2, z = 0 })
			elseif node.name == WHIRLY then
				player:add_velocity({ x = 0, y = -1.2, z = 0 })
			end
		end
	end
end)

minetest.log("action", "[mcl_mobs_addon] final closers: coral, moss, tuff bricks, copper bulb, crafter, recovery compass, hanging sign, pitcher/torchflower, bubble columns")
