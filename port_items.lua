-- ---------------------------------------------------------------------------
-- PORTED ITEM BLOCKS (GPLv3, from Mineclonia): conduit, dripstone,
-- candles, powder snow, echo shard, mace — the items VoxeLibre lacked.
-- Plus the chain (from VoxeLibre, for Mineclonia).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

-- dual-game: Mineclonia calls its dye mod mcl_dyes, VoxeLibre mcl_dye
local mcl_dyes = mcl_dyes or mcl_dye

-- Mineclonia's table.merge is missing in VoxeLibre — shim it
if not table.merge then
	function table.merge(t1, t2)
		local r = {}
		if t1 then for k, v in pairs(t1) do r[k] = v end end
		if t2 then for k, v in pairs(t2) do r[k] = v end end
		return r
	end
end

-- ======================= CONDUIT (1.13) =======================
mcl_conduits = {}
local modname = core.get_current_modname()
local S = core.get_translator(modname)

local check_interval = 5
local conduit_nodes = { "mcl_ocean:prismarine",  "mcl_ocean:prismarine_brick", "mcl_ocean:prismarine_dark", "mcl_ocean:sea_lantern" }

local frame_offsets = {
	vector.new(1, 2, 0),
	vector.new(2, 2, 0),
	vector.new(-1, 2, 0),
	vector.new(-2, 2, 0),
	vector.new(0, 2, 0),
	vector.new(0, 2, 1),
	vector.new(0, 2, 2),
	vector.new(0, 2, -1),
	vector.new(0, 2, -2),

	vector.new(2, 1, 0),
	vector.new(-2, 1, 0),
	vector.new(0, 1, 2),
	vector.new(0, 1, -2),

	vector.new(2, 0, 0),
	vector.new(2, 0, 1),
	vector.new(2, 0, 2),

	vector.new(-2, 0, 0),
	vector.new(-2, 0, 1),
	vector.new(-2, 0, 2),

	vector.new(2, 0, -1),
	vector.new(2, 0, -2),
	vector.new(-2, 0, -1),
	vector.new(-2, 0, -2),

	vector.new(0, 0, 2),
	vector.new(1, 0, 2),

	vector.new(0, 0, -2),
	vector.new(1, 0, -2),

	vector.new(-1, 0, 2),
	vector.new(-1, 0, -2),

	vector.new(2, -1, 0),
	vector.new(-2, -1, 0),
	vector.new(0, -1, 2),
	vector.new(0, -1, -2),

	vector.new(1, -2, 0),
	vector.new(2, -2, 0),
	vector.new(-1, -2, 0),
	vector.new(-2, -2, 0),
	vector.new(0, -2, 0),
	vector.new(0, -2, 1),
	vector.new(0, -2, 2),
	vector.new(0, -2, -1),
	vector.new(0, -2, -2),
}

local entity_pos_offset = vector.new(0, -1.25, 0)

local function check_conduit(pos)
	local water = core.find_nodes_in_area(vector.offset(pos, -1,-1,-1), vector.offset(pos, 1, 1, 1), {"group:water"})
	local cname = core.get_node(pos).name
	if #water < 26 or ( cname ~= "mc_parity:conduit" and #water < 27 ) then return false end
	local pn = 0
	for _, v in pairs(frame_offsets) do
		if table.indexof(conduit_nodes, core.get_node(vector.add(pos, v)).name) ~= -1 then
			pn = pn + 1
		end
	end
	if pn < 16 then return false end
	return math.floor(pn / 7) * 16
end

function mcl_conduits.player_effect(player)
    if (mcl_player.players and mcl_player.players[player] and mcl_player.players[player].nodes) then
	if core.get_item_group(mcl_player.players[player].nodes.feet, "water") == 0 then return end
end
    mcl_potions.give_effect_by_level ("conduit_power", player, 1, 17)
end

function mcl_conduits.conduit_damage(ent)
	if core.get_item_group(core.get_node(ent.object:get_pos()).name, "water") == 0 then return end
	mcl_util.deal_damage(ent.object, 4, {type = "magic"})
end

core.register_entity("mc_parity:conduit", {
	initial_properties = {
		physical = true,
		visual = "mesh",
		visual_size = {x = 4, y = 4},
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		mesh = "mcl_end_crystal.b3d",
		textures = {"mcl_conduit_conduit.png"},
		collide_with_objects = false,
	},
	on_activate = function(self, staticdata)
		local d = core.deserialize(staticdata)
		if d then
			self._pos = d._pos
		end
		self.object:set_armor_groups({immortal = 1})
		self.object:set_animation({x = 0, y = 120}, 3)
	end,
	get_staticdata = function(self)
		return core.serialize({ _pos = self._pos })
	end,
	on_step = function(self, dtime)
		self._timer = (self._timer or check_interval) - dtime
		if self._timer > 0 then return end
		self._timer = check_interval
		if not self._pos then
			self.object:remove()
			return
		end
		local lvl = check_conduit(self._pos)
		if not lvl then
			core.set_node(self._pos, {name = "mc_parity:conduit"})
			self.object:remove()
			return
		end

		for pl in (mcl_util.connected_players or function() return {} end)(self._pos, lvl * 2) do
			mcl_conduits.player_effect(pl)
		end

		for _, ent in pairs(core.luaentities) do
			if ent.is_mob and ent.type == "monster" and ent.object and ent.object:get_pos() and vector.distance(self._pos, ent.object:get_pos()) < 9 then
				mcl_conduits.conduit_damage(ent)
			end
		end
	end
})
local conduit_box = { -0.25, -0.25, -0.25, 0.25, 0.25, 0.25, }
core.register_node("mc_parity:conduit", {
	description = S("Conduit"),
	_doc_longdesc = S("A conduit provides certain status effects to nearby players much like a beacon but under water"),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = conduit_box,
	},
	collisionbox = conduit_box,
	selectionbox = conduit_box,
	groups = { pickaxey = 1, deco_block = 1, rarity = 1 },
	light_source = core.LIGHT_MAX,
	tiles = { "mcl_conduit_conduit_node.png", },
	_mcl_hardness = 3,
})

core.register_abm({
	label = "Conduit Activation",
	nodenames = { "mc_parity:conduit" },
	interval = check_interval,
	chance = 1,
	action = function(pos, _)
		for v in core.objects_inside_radius(vector.subtract(pos, entity_pos_offset), 0.5) do
			if v.name == "mc_parity:conduit" then return end
		end
		if check_conduit(pos) then
			core.remove_node(pos)
			local o = core.add_entity(vector.add(pos, entity_pos_offset) , "mc_parity:conduit")
			if o then
				local l = o:get_luaentity()
				l._pos = pos
			end
		end
	end
})

core.register_craft({
	output = "mc_parity:conduit",
	recipe = {
		{"mcl_mobitems:nautilus_shell", "mcl_mobitems:nautilus_shell", "mcl_mobitems:nautilus_shell"},
		{"mcl_mobitems:nautilus_shell", "mcl_mobitems:heart_of_the_sea", "mcl_mobitems:nautilus_shell"},
		{"mcl_mobitems:nautilus_shell", "mcl_mobitems:nautilus_shell", "mcl_mobitems:nautilus_shell"},
	},
})


-- ======================= DRIPSTONE (1.17) =======================
local S = core.get_translator(core.get_current_modname())

local dripstone_directions =
{
	[-1] = "bottom",
	[1] = "top",
}

local dripstone_stages =
{
	"tip_merge",
	"tip",
	"frustum",
	"middle",
	"base",
}

local function dripstone_hit_func(self, object)
	-- the number 1.125 comes from: (nodes fallen / timer increase) * damage per node fallen
	-- which comes out to be: (1.5 / 8) * 6 = 1.125
	mcl_util.deal_damage(object, math.min(40, self.timer * 1.125), {type = "falling_node"})
end

mcl_mobs.register_arrow("mc_parity:vengeful_dripstone",
{
	visual = "upright_sprite",
	textures = {"pointed_dripstone_tip.png"},
	visual_size = {x = 1, y = 1},
	velocity = 20,
	hit_player = dripstone_hit_func,
	hit_mob = dripstone_hit_func,
	hit_object = dripstone_hit_func,
	hit_node = function(self, pos)
		core.add_item(pos, ItemStack("mc_parity:pointed_dripstone"))
	end,
	drop = "mc_parity:pointed_dripstone",
})

local function spawn_dripstone_entity(pos)
	local vengeful_dripstone = core.add_entity(pos, "mc_parity:vengeful_dripstone")
	vengeful_dripstone:add_velocity(vector.new(0, -12, 0))
	local ent = vengeful_dripstone:get_luaentity()
	ent.switch = 1
end

core.register_node("mc_parity:dripstone_block", {
	description = S("Dripstone block"),
	_doc_items_longdesc = S("Dripstone is type of stone that allows stalagmites and stalagtites to grow on it"),
	_doc_items_hidden = false,
	tiles = {"dripstone_block.png"},
	groups = {pickaxey=1, stone=1, building_block=1, material_stone=1, stonecuttable = 1, converts_to_moss = 1},
	sounds = mcl_sounds.node_sound_stone_defaults(),
	_mcl_blast_resistance = 6,
	_mcl_hardness = 1.5,
})


-- returns the name of pointed dripstone node with that stage and direction
local function get_dripstone_node(stage, direction)
	return "mc_parity:dripstone_" .. dripstone_directions[direction] .. "_" .. dripstone_stages[stage]
end

-- extracts the direction from dripstone's name
local function extract_direction(name)
	return string.sub(name, 26, 31) == "bottom" and -1 or 1
end

-- it is assumed pos is at the tip of the dripstone
local function get_dripstone_length(pos, direction)
	local offset_pos = vector.copy(pos)
	local stage
	local length = 0
	repeat
		length = length + 1
		offset_pos = vector.offset(offset_pos, 0, direction, 0)
		stage = core.get_item_group(core.get_node(offset_pos).name, "dripstone_stage")
	until(stage == 0)
	return length
end

local function place_dripstone(pos, length, direction)
	if length == 0 then return end
	-- create the base
	if length >= 3 then
		core.swap_node(vector.offset(pos, 0, 0, 0), {name = get_dripstone_node(5, direction)})
	end

	-- create the middle
	if length >= 4 then
		for i = 0, length - 4 do
			core.swap_node(vector.offset(pos, 0, (i + 1) * -direction, 0), {name = get_dripstone_node(4, direction)})
		end
	end

	-- create the frustum
	if length >= 2 then
		core.swap_node(vector.offset(pos, 0, (length - 2)  * -direction, 0), {name = get_dripstone_node(3, direction)})
	end

	-- if a dripstone column should be created
	-- ".[^l]" is in the pattern to prevent dripstone blocks from being matched
	if string.find(core.get_node(vector.offset(pos, 0, length * -direction, 0)).name, "^mcl_dripstone:dripstone_.[^l]") then
		core.swap_node(vector.offset(pos, 0, (length - 1) * -direction, 0), {name = "mc_parity:dripstone_" .. dripstone_directions[direction] .. "_tip_merge"})
		core.swap_node(vector.offset(pos, 0, length * -direction, 0), {name = "mc_parity:dripstone_" .. dripstone_directions[-direction] .. "_tip_merge"})
	else
		core.swap_node(vector.offset(pos, 0, (length - 1) * -direction, 0), {name = get_dripstone_node(2, direction)})
	end
end

local function break_dripstone(pos, direction)
	local offset_pos = vector.copy(pos)
	while true do
		offset_pos = vector.offset(offset_pos, 0, -direction, 0)
		local stage = core.get_item_group(core.get_node(offset_pos).name, "dripstone_stage")
		if stage == 1 and extract_direction(core.get_node(offset_pos).name) == -direction then
			core.swap_node(offset_pos, {name = get_dripstone_node(2, -direction)})
			break
		elseif stage == 0 then
			break
		else
			if direction == -1 then
				core.add_item(offset_pos, ItemStack("mc_parity:pointed_dripstone"))
			else
				spawn_dripstone_entity(offset_pos)
			end
			core.swap_node(offset_pos, {name = "air"})
		end
	end
end

local function update_dripstone(pos, direction)
	-- if a dripstone column should be created
	-- ".[^l]" is in the pattern to prevent dripstone blocks from being matched
	if string.find(core.get_node(vector.offset(pos, 0, -direction, 0)).name, "^mcl_dripstone:dripstone_.[^l]") then
		core.swap_node(pos, {name = "mc_parity:dripstone_" .. dripstone_directions[direction] .. "_tip_merge"})
		core.swap_node(vector.offset(pos, 0, -direction, 0), {name = "mc_parity:dripstone_" .. dripstone_directions[-direction] .. "_tip_merge"})
	end

	local stage
	local previous_stage
	while true do
		pos = vector.offset(pos, 0, direction, 0)
		previous_stage = stage
		stage = core.get_item_group(core.get_node(pos).name, "dripstone_stage")
		if stage == 4 or stage == 5 then
			break
		elseif stage == 0 then
			if previous_stage == 3 then
				core.swap_node(vector.offset(pos, 0, -direction, 0), {name = "mc_parity:dripstone_" .. dripstone_directions[direction] .. "_base"})
			end
			break
		end
		core.swap_node(pos, {name = get_dripstone_node(stage + 1, direction)})
	end
end

local function on_dripstone_place(itemstack, player, pointed_thing)
	local rc = mcl_util.call_on_rightclick(itemstack, player, pointed_thing)
	if rc then return rc end
	if pointed_thing.type ~= "node" then return itemstack end

	local under_node = core.get_node(pointed_thing.under)

	if core.get_item_group(under_node.name, "solid") == 0 and core.get_item_group(under_node.name, "dripstone_stage") == 0 then return itemstack end
	if pointed_thing.above.x ~= pointed_thing.under.x or pointed_thing.above.z ~= pointed_thing.under.z then return itemstack end

	local direction = pointed_thing.under.y - pointed_thing.above.y
	if direction == 0 then
		return
	end

	local above = pointed_thing.above
	local above_node = core.get_node(above)
	local above_def = core.registered_nodes[above_node.name]
	if above_def and above_def.buildable_to then
		if not core.is_creative_enabled(player:get_player_name()) then
			itemstack:take_item()
		end
		core.set_node(above, {name = get_dripstone_node(2, direction)})
		update_dripstone(pointed_thing.above, direction)
	end
	return itemstack
end

local on_dripstone_destruct = function(pos)
	local direction = extract_direction(core.get_node(pos).name)
	break_dripstone(pos, direction)

	local offset_pos = vector.copy(vector.offset(pos, 0, direction, 0))
	if core.get_item_group(core.get_node(offset_pos).name, "dripstone_stage") ~= 0 then
		core.swap_node(offset_pos, {name = get_dripstone_node(2, direction)})

		while true do
			offset_pos = vector.offset(offset_pos, 0, direction, 0)
			local stage = core.get_item_group(core.get_node(offset_pos).name, "dripstone_stage")
			if stage == 3 then
				core.swap_node(offset_pos, {name = get_dripstone_node(2, direction)})
			elseif stage == 4 or stage == 5 then
				core.swap_node(offset_pos, {name = get_dripstone_node(3, direction)})
				break
			else
				break
			end
		end
	end
end

core.register_craftitem("mc_parity:pointed_dripstone", {
	description = S("Pointed dripstone"),
	_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
	_doc_items_hidden = false,
	inventory_image = "pointed_dripstone_tip.png",
	on_place = on_dripstone_place,
	on_secondary_use = on_dripstone_place,
	_mcl_crafting_output = {square2 = {output = "mc_parity:dripstone_block"}}
})

for i = 1, #dripstone_stages do
	local stage = dripstone_stages[i]
	local add = ( i - 1 ) / 16
	local box_top = {
		type = "fixed",
		fixed = { math.max(-0.5, -3/16 - add), -0.5, math.max(-0.5, -3/16 - add), math.min(0.5, 3/16 + add), 0.5, math.min(3/16 + add) },
	}
	local box_bottom = {
		type = "fixed",
		fixed = { math.max(-0.5, -3/16 - add), -0.5, math.max(-0.5, -3/16 - add), math.min(0.5, 3/16 + add), 0.5, math.min(0.5, 3/16 + add) },
	}

	core.register_node("mc_parity:dripstone_top_" .. stage, {
		description = S("Pointed dripstone (@1/@2)", i, #dripstone_stages),
		_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
		_doc_items_hidden = true,
		drawtype = "plantlike",
		tiles = {"pointed_dripstone_" .. stage .. ".png"},
		drop = "mc_parity:pointed_dripstone",
		groups = {
			pickaxey = 1,
			not_in_creative_inventory = 1,
			dripstone_stage = i,
			pathfinder_partial = 2,
			dig_by_trident = 1,
		},
		sunlight_propagates = true,
		paramtype = "light",
		is_ground_content = false,
		selection_box = box_top,
		collision_box = box_top,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_destruct = on_dripstone_destruct,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 1.5,
	})

	core.register_node("mc_parity:dripstone_bottom_" .. stage, {
		description = S("Pointed dripstone (@1/@2)", i, #dripstone_stages),
		_doc_items_longdesc = S("Pointed dripstone is what stalagmites and stalagtites are made of"),
		_doc_items_hidden = true,
		drawtype = "plantlike",
		tiles = {"pointed_dripstone_" .. stage .. ".png^[transform6"},
		drop = "mc_parity:pointed_dripstone",
		groups = {
			pickaxey = 1,
			not_in_creative_inventory = 1,
			fall_damage_add_percent = 100,
			dripstone_stage = i,
			pathfinder_partial = 2,
			dig_by_trident = 1,
		},
		sunlight_propagates = true,
		paramtype = "light",
		is_ground_content = false,
		selection_box = box_bottom,
		collision_box = box_bottom,
		sounds = mcl_sounds.node_sound_stone_defaults(),
		on_destruct = on_dripstone_destruct,
		_mcl_blast_resistance = 3,
		_mcl_hardness = 1.5,
	})
end

core.register_on_dignode(function(pos)
	local offset_pos = vector.copy(vector.offset(pos, 0, -1, 0))
	local nn = core.get_node(offset_pos).name
	if core.get_item_group(nn, "dripstone_stage") ~= 0 and extract_direction(nn) == 1 then
		if core.get_item_group(core.get_node(offset_pos).name, "dripstone_stage") ~= 0 then
			break_dripstone(offset_pos, 1)
			spawn_dripstone_entity(offset_pos)
			core.swap_node(offset_pos, {name = "air"})
		end
	end
end)

core.register_abm({
	label = "Dripstone growth",
	nodenames = {"mc_parity:dripstone_top_tip"},
	interval = 69,
	chance = 88,
	action = function(pos)
		-- checking if can grow
		local stalagtite_length = get_dripstone_length(pos, 1)
		if core.get_node(vector.offset(pos, 0, stalagtite_length, 0)).name ~= "mc_parity:dripstone_block"
		or core.get_item_group(core.get_node(vector.offset(pos, 0, stalagtite_length + 1, 0)).name, "water") == 0 then
			return
		end

		-- randomly chose to either grow the stalagmite or stalagtites
		if math.random(2) == 1 then
			-- stalagmite growth
			local groups
			local node
			local length
			for i = 1, 10 do
				node = core.get_node(vector.offset(pos, 0, -i, 0))
				groups = core.registered_nodes[node.name].groups
				if (groups["solid"] or 0) > 0 or (groups["dripstone_stage"] or 0) > 0 then
					length = get_dripstone_length(pos, 1)

					if length < 7 then
						core.set_node(vector.offset(pos, 0, -i + 1, 0), {name = get_dripstone_node(2, -1)})
						update_dripstone(vector.offset(pos, 0, -i + 1, 0), -1)
					end
					return
				elseif node.name ~= "air" then
					return
				end
			end
		else
			-- stalagtite growth
			if stalagtite_length > 7 then return end

			if core.get_node(vector.offset(pos, 0, -1, 0)).name == "air" then
				core.set_node(vector.offset(pos, 0, -1, 0), {name = get_dripstone_node(2, 1)})
				update_dripstone(vector.offset(pos, 0, -1, 0), 1)
			end
		end
	end,
})

core.register_abm({
	label = "Dripstone filling water cauldrons, conversion from mud to clay",
	nodenames = {"mc_parity:dripstone_top_tip"},
	interval = 69,
	chance = 5.5,
	action = function(pos)
		local stalagtite_length = get_dripstone_length(pos, 1)
		local wpos = vector.offset(pos, 0, stalagtite_length + 1, 0)
		local wnode = core.get_node(wpos)

		if core.get_item_group(core.get_node(wpos).name, "water") == 0
		or stalagtite_length > 10 then
			-- reusing the ABM for converting mud to clay, since the chances are the same
			if wnode.name == "mcl_mud:mud"
			and mcl_worlds.pos_to_dimension(wpos) ~= "nether" then
				core.set_node(wpos, {name = "mcl_core:clay"})
			end
			return
		end

		local water_type = "water"
		if core.get_item_group(wnode.name, "river_water") > 0 then
			water_type = "river_water"
		end
		for i = 1, 10 do
			local cpos = vector.offset(pos, 0, -i, 0)
			local node = core.get_node(cpos)
			if core.get_item_group(node.name, "cauldron") == 1 or core.get_item_group(node.name, "cauldron_water") > 0 then
				mcl_cauldrons.add_level(cpos, 1, water_type)
				return
			elseif node.name ~= "air" then
				return
			end
		end
	end,
})

core.register_abm({
	label = "Dripstone filling lava cauldrons",
	nodenames = {"mc_parity:dripstone_top_tip"},
	interval = 69,
	chance = 17,
	action = function(pos)
		local stalagtite_length = get_dripstone_length(pos, 1)

		if core.get_item_group(core.get_node(vector.offset(pos, 0, stalagtite_length + 1, 0)).name, "lava") == 0
		or stalagtite_length > 10 then
			return
		end

		for i = 1, 10 do
			local cpos = vector.offset(pos, 0, -i, 0)
			local node = core.get_node(cpos)
			if node.name == "mcl_cauldrons:cauldron" then
				mcl_cauldrons.add_level(cpos, 3, "lava")
			elseif node.name ~= "air" then
				return
			end
		end
	end,
})

mcl_structures.register_structure("dripstone_stalagmite", {
	place_on = {"mc_parity:dripstone_block"},
	spawn_by = "air",
	check_offset = 1,
	num_spawn_by = 5,
	biomes = {"DripstoneCave"},
	fill_ratio = 0.8,
	y_min = mcl_vars.mg_overworld_min,
	y_max = 0,
	place_offset_y = 1,
	terrain_feature = true,
	place_func = function(pos)
		local max_length = 0
		local offset_pos = vector.copy(pos)
		while true do
			offset_pos = vector.offset(offset_pos, 0, 1, 0)
			if core.get_node(offset_pos).name ~= "air" then
				break
			end
			max_length = max_length + 1
		end
		place_dripstone(pos, math.min(math.random(2, 5), max_length), -1)
		return true
	end,
})

mcl_structures.register_structure("dripstone_stalagtite", {
	place_on = {"mc_parity:dripstone_block"},
	spawn_by = "air",
	check_offset = 1,
	num_spawn_by = 5,
	biomes = {"DripstoneCave"},
	fill_ratio = 0.8,
	y_min = mcl_vars.mg_overworld_min + 1,
	y_max = 0,
	flags = "all_ceilings",
	terrain_feature = true,
	place_func = function(pos)
		pos = vector.offset(pos, 0, -2, 0)
		local max_length = 0
		local offset_pos = vector.copy(pos)
		while true do
			offset_pos = vector.offset(offset_pos, 0, -1, 0)
			if core.get_node(offset_pos).name ~= "air" then
				break
			end
			max_length = max_length + 1
		end

		place_dripstone(pos, math.min(math.random(2, 5), max_length), 1)
		return true
	end,
})

local modpath = core.get_modpath (core.get_current_modname ())
-- (the MCLN-only async worldgen script lg_register.lua is not ported)


-- ======================= CANDLES (1.17) =======================
mcl_candles = {}

local S = core.get_translator(core.get_current_modname())
local D = (mcl_util.get_dynamic_translator and mcl_util.get_dynamic_translator(core.get_current_modname()))
	or function(_) return "" end

local candle_boxes = {
	{-0.0625, -0.5, -0.0625, 0.0625, -0.125, 0.0625},
	{-0.1875, -0.5, -0.0625, 0.1875, -0.125, 0.125},
	{-0.1875, -0.5, -0.1875, 0.125, -0.125, 0.125},
	{-0.1875, -0.5, -0.125, 0.1875, -0.125, 0.1875}
}

local function set_candle_properties(stack, color)
	if type(color) ~= "string" and color == "" then return end

	local color_defs = mcl_dyes.colors[color]
	local image = "mc_parity_item_".. color .. ".png"

	if color_defs then
		stack:get_meta():set_int("palette_index", color_defs.palette_index + 1)
		stack:get_meta():set_string("inventory_overlay", image)
		stack:get_meta():set_string("wield_overlay", image)
	end
end
mcl_candles.set_candle_properties = set_candle_properties

local function drop_candles(pos, node, _, digger)
	if digger and digger:is_player() and core.is_creative_enabled(digger:get_player_name()) then return end

	if not node then node = core.get_node(pos) end

	local group = core.get_item_group(node.name, "candles")

	if node.name:find("mc_parity:candle_cake") then group = 1 end

	local item = ItemStack("mc_parity:candle_1 " .. group)
	local color_index = node.param2 > 0 and node.param2
	local color = color_index and mcl_dyes.palette_index_to_color(color_index - 1)

	if color then set_candle_properties(item, color) end

	tt.reload_itemstack_description(item)

	return core.add_item(pos, item)
end

local function ignite_candle(pos)
	local n = core.get_node(pos)
	local g = core.get_item_group(n.name, "candles")
	if g > 0 then
		n.name = "mc_parity:candle_lit_"..tostring(g)
		core.swap_node(pos, n)
		return true
	end
end

local function get_candle_item(pos)
	local stack = ItemStack("mc_parity:candle_1")
	local node = core.get_node(pos)
	local color_index = node.param2 > 0 and node.param2
	local color = color_index and mcl_dyes.palette_index_to_color(color_index - 1)

	if color then set_candle_properties(stack, color) end

	tt.reload_itemstack_description(stack)

	return stack
end

local tpl_candle = {
	_doc_items_longdesc = S("A candle is a block that emits light when lit with a flint and steel. It comes in the sixteen dye colors. Up to four of the same color of candle can be placed in one block space, which affects the amount of light produced."),
	_mcl_baseitem = get_candle_item,
	_mcl_hardness = 0.1,
	_on_dye_place = function(pos, color)
		local node = core.get_node(pos)
		node.param2 = mcl_dyes.colors[color].palette_index
		core.swap_node(pos, node)
	end,
	_on_ignite = function(_, pointed_thing)
		return ignite_candle(pointed_thing.under)
	end,
	_on_arrow_hit = function(pos, arrow_luaentity)
		if not mcl_burning.is_burning(arrow_luaentity.object) then return end
		return ignite_candle(pos)
	end,
	_on_set_item_entity = function (stack)
		return stack, {wield_item = stack:to_string()}
	end,
	_mcl_generate_description = function(itemstack)
		-- palette_index_to_color is Mineclonia-only — VoxeLibre's mcl_dye
		-- lacks it; the candles still work, only the colored name is lost
		if not mcl_dyes.palette_index_to_color then return end
		local m = itemstack:get_meta()
		local color = mcl_dyes.palette_index_to_color(m:get_int("palette_index") - 1)
		local c = ""
		if mcl_dyes.colors[color] then
			c = mcl_dyes.colors[color].readable_name .. " "
		end
		m:set_string("description", D(c .. "Candle"))
	end,
	on_destruct = drop_candles,
	description = S("Candle"),
	drawtype = "mesh",
	drop = "",
	groups = {
		axey = 1, candles = 1, deco_block = 1, dig_by_piston = 1, handy = 1, not_solid = 1,
		pickaxey = 1, shearsy = 1, shovely = 1, swordy = 1, unlit_candles = 1
	},
	inventory_image = "mc_parity_item.png",
	is_ground_content = false,
	node_placement_prediction = "",
	palette = "mc_parity_palette.png",
	paramtype = "light",
	paramtype2 = "color",
	sounds = mcl_sounds.node_sound_defaults(),
	sunlight_propagates = true,
	tiles = {"mc_parity_candle.png", "blank.png"},
	use_texture_alpha = "clip",
	wield_image = "mc_parity_item.png"
}

local tpl_lit_candle = {
	_doc_items_create_entry = false,
	description = S("Lit Candle"),
	groups = {
		axey = 1, candles = 1, dig_by_piston = 1, handy = 1, lit_candles = 1,
		not_in_creative_inventory = 1, not_solid = 1, pickaxey = 1, shearsy = 1,
		shovely = 1, swordy = 1
	},
    tiles = {
        "mc_parity_candle.png",
        {
            animation = {
                aspect_h = 16,
				aspect_w = 16,
				length = 1,
				type = "vertical_frames"
            },
			color = "white",
			name = "mc_parity_flames.png"
        }
    }
}

function tpl_candle.on_place(itemstack, placer, pointed_thing)
	if not placer then return end

	if mcl_util.check_position_protection(pointed_thing.under, placer) then return end

	local unode = core.get_node(pointed_thing.under)
	local group = core.get_item_group(unode.name, "candles")
	local param2 = tonumber(itemstack:get_meta():get("palette_index")) or 0

	if unode.name == "mcl_cake:cake" then
		core.swap_node(pointed_thing.under, {name = "mc_parity:candle_cake", param2 = param2})

		if not core.is_creative_enabled(placer:get_player_name()) then
			itemstack:take_item()
		end

		return itemstack
	end

	local rc = mcl_util.call_on_rightclick(itemstack, placer, pointed_thing)

	if rc ~= nil then return rc end

	if group > 0 then
		if group < #candle_boxes then
			unode.name = "mc_parity:candle_" .. math.min(4, group + 1)
			if param2 == unode.param2 then
				core.swap_node(pointed_thing.under, unode)
			end

			if not core.is_creative_enabled(placer:get_player_name()) then
				itemstack:take_item()
			end
		end
	else
		return core.item_place_node(itemstack, placer, pointed_thing)
	end

	return itemstack
end

local function extinguish(pos, node, clicker, _, _)
	if not clicker then
		return
	end

	if mcl_util.check_position_protection(pos, clicker) then
		return
	end

	local group = core.get_item_group(node.name, "lit_candles")
	if group > 0 then
		node.name = "mc_parity:candle_" .. group
		core.swap_node(pos, node)
	end
end

for i = 1, #candle_boxes do
	local creative_group
	local candle_n = {
		collision_box = {fixed = candle_boxes[i], type = "fixed"},
		selection_box = {fixed = candle_boxes[i], type = "fixed"}
	}

	if i ~= 1 then
		tpl_candle._doc_items_create_entry = false
		creative_group = {not_in_creative_inventory = 1}
	end

	core.register_node("mc_parity:candle_" .. i, table.merge(tpl_candle, candle_n, {
		_get_all_virtual_items = function ()
			local output = {deco = {}}

			if i == 1 then
				for color, _ in pairs(mcl_dyes.colors) do
					local stack = ItemStack("mc_parity:candle_1")

					set_candle_properties(stack, color)

					tt.reload_itemstack_description(stack)

					table.insert(output.deco, stack:to_string())
				end
			end

			return output
		end,
		groups = table.merge(tpl_candle.groups, {candles = i, unlit_candles = i}, creative_group),
		mesh = "mc_parity_candle_" .. i .. ".obj",
	}))
	local lit_candle = table.merge(tpl_candle, tpl_lit_candle, candle_n, {
		_on_wind_charge_hit = function (pos)
			local node = core.get_node(pos)
			local group = core.get_item_group(node.name, "lit_candles")
			node.name = "mc_parity:candle_" .. group
			core.swap_node(pos, node)
		end,
		groups = table.merge(tpl_lit_candle.groups, {candles = i, lit_candles = i}),
		light_source = 3 * i,
		mesh = "mc_parity_candle_lit_" .. i .. ".obj",
		on_rightclick = extinguish
	})
	lit_candle._on_ignite = nil
	lit_candle._on_arrow_hit = nil
	core.register_node("mc_parity:candle_lit_" .. i, lit_candle)

	doc.add_entry_alias("nodes", "mc_parity:candle_1", "nodes", "mc_parity:candle_" .. i)
	doc.add_entry_alias("nodes", "mc_parity:candle_1", "nodes", "mc_parity:candle_lit_" .. i)
end

local function candle_craft(output, _, old_craft_grid, _)
	if not (output and output:get_name() == "mc_parity:candle_1") then return end

	local i = 0
	local dye, candle

	for _, stack in pairs(old_craft_grid) do
		if core.get_item_group(stack:get_name(), "candles") > 0 then
			candle = stack
			i = i + 1
		elseif core.get_item_group(stack:get_name(), "dye") > 0 then
			dye = stack
			i = i + 1
		end
	end

	if dye and candle and i == 2 then
		local color = dye:get_definition()._color
		local cdef = mcl_dyes.colors[color]
		local result = ItemStack(core.itemstring_with_palette(candle, cdef.palette_index + 1))

		result:set_count(1)

		set_candle_properties(result, color)

		tt.reload_itemstack_description(result)

		return result
	end
end

core.register_craft_predict(candle_craft)
core.register_on_craft(candle_craft)

core.register_craft({
	output = "mc_parity:candle_1",
	recipe = {
		{"mcl_mobitems:string"},
		{"mcl_honey:honeycomb"}
	}
})

core.register_craft({
	type = "shapeless",
	output = "mc_parity:candle_1",
	recipe = {
		"group:candles",
		"group:dye",
	}
})

local cake_box = {
	fixed = {
		{-0.4375, -0.5, -0.4375, 0.4375, 0, 0.4375},
		{-0.0625, 0, -0.0625, 0.0625, 0.375, 0.0625}
	},
	type = "fixed"
}

local function looking_at_candle(pointer, pointed_thing)
	if not pointer then return end

	local pt_above = pointed_thing.above
	local pt_under = pointed_thing.under

	if pt_above.y > pt_under.y then
		local f_pos_x = core.pointed_thing_to_face_pos(pointer, pointed_thing).x - pt_above.x
		local f_pos_z = core.pointed_thing_to_face_pos(pointer, pointed_thing).z - pt_above.z

		if f_pos_x * f_pos_x + f_pos_z * f_pos_z < 0.0062 then
			return true
		end
	end

	local f_pos = core.pointed_thing_to_face_pos(pointer, pointed_thing).y - pt_above.y

	return (f_pos > 0.05)
end

local tpl_cake = {
	_mcl_spawn_food_particles = false,
	_mcl_baseitem = get_candle_item,
	on_destruct = drop_candles,
	collision_box = cake_box,
	description = S("Cake"),
	drawtype = "mesh",
	drop = "",
	groups = {
		attached_node = 1, dig_by_piston = 1, food = 2, handy = 1,
		not_in_creative_inventory = 1, unsticky = 1
	},
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		if not looking_at_candle(clicker, pointed_thing) then
			drop_candles(pos, node, nil, clicker)
			core.do_item_eat(2, ItemStack(), ItemStack("mcl_cake:cake"), clicker, {type = "nothing"})
			core.swap_node(pos, {name = "mcl_cake:cake_6"})
		else
			if core.get_item_group(node.name, "lit_cake") > 0 then
				core.swap_node(pos, {name = node.name:gsub("_lit", ""), param2 = node.param2})
			else
				if core.get_item_group(itemstack:get_name(), "flint_and_steel") > 0 then
					core.swap_node(pos, {name = node.name .. "_lit", param2 = node.param2})
					if not core.is_creative_enabled(clicker:get_player_name()) then
						itemstack:add_wear()
					end
				end
			end
		end
	end,
	palette = "mc_parity_palette.png",
	paramtype = "light",
	paramtype2 = "color",
	selection_box = cake_box,
	tiles = {
		{
			color = "white",
			name = "[combine:32x32:0,0=cake_top.png:16,0=cake_bottom.png:0,16=cake_side.png"
		},
		"mc_parity_candle.png",
		"blank.png"
	},
	use_texture_alpha = "clip"
}

core.register_node("mc_parity:candle_cake", table.merge(tpl_cake, {
	mesh = "mc_parity_cake.obj",
	tiles = {
		{
			color = "white",
			name = "cake_top.png"
		},
		{
			color = "white",
			name = "cake_bottom.png"
		},
		{
			color = "white",
			name = "cake_side.png"
		},
		"mc_parity_candle.png"
	}
}))
core.register_node("mc_parity:candle_cake_lit", table.merge(tpl_cake, {
	_on_wind_charge_hit = function (pos)
		local node = core.get_node(pos)
		node.name = "mc_parity:candle_cake"
		core.swap_node(pos, node)
	end,
	_on_bottle_place = function(itemstack, placer, pointed_thing)
		local def = itemstack:get_definition()
		if def._mcl_cauldrons_liquid then
			local node = core.get_node(pointed_thing.under)
			mcl_potions.set_node_empty_bottle(itemstack, placer, pointed_thing, "mc_parity:candle_cake", node.param2)
			core.sound_play("fire_extinguish_flame", {gain = 0.1, max_hear_distance = 16, pos = pointed_thing.under}, true)
		end
	end,
	light_source = 3,
	groups = table.merge(tpl_cake.groups, {lit_cake = 1}),
	mesh = "mc_parity_cake_lit.obj",
	tiles = {
		{
			color = "white",
			name = "cake_top.png"
		},
		{
			color = "white",
			name = "cake_bottom.png"
		},
		{
			color = "white",
			name = "cake_side.png"
		},
		"mc_parity_candle.png",
		{
            animation = {
                aspect_h = 16,
				aspect_w = 16,
				length = 1,
				type = "vertical_frames"
            },
			color = "white",
			name = "mc_parity_flames.png"
        }
	}
}))


-- ======================= POWDER SNOW (1.17) =======================
local S = core.get_translator(core.get_current_modname())

core.register_node("mc_parity:powder_snow", {
	description = S("Powder Snow"),
	_doc_items_longdesc = S("This is a block of snow thats extra fluffy, this means players can sink in it"),
	_doc_items_hidden = false,
	tiles = {"powder_snow.png"},
	groups = {shovely=2, snow_cover=1, not_in_creative_inventory = 1, disable_suffocation = 1,no_spawning_inside = 1,},
	sounds = mcl_sounds.node_sound_snow_defaults(),
	post_effect_color = "#CFD7DBFF",
	walkable = false,
	move_resistance = 3,
	is_ground_content = false, -- set to false to potentially create huge drops into caves >:)
	on_construct = mcl_core.on_snow_construct,
	after_destruct = mcl_core.after_snow_destruct,
	on_rightclick = function(pos, _, clicker, itemstack, pointed_thing)
		if itemstack:get_name() ==  "mcl_buckets:bucket_empty" then
			core.set_node(pos, {name = "air"})
			if not core.is_creative_enabled(clicker:get_player_name()) then
				if itemstack:get_count() == 1 then
					itemstack = ItemStack("mc_parity:bucket_powder_snow")
				else
					local inv = clicker:get_inventory()
					if inv:room_for_item("main", "mc_parity:bucket_powder_snow") then
						inv:add_item("main", "mc_parity:bucket_powder_snow")
					else
						core.add_item(clicker:get_pos(), "mc_parity:bucket_powder_snow")
					end
					itemstack:take_item()
				end
			end
		elseif itemstack:get_definition().type == "node" then
			core.item_place_node(itemstack, clicker, pointed_thing)
		end

		return itemstack
	end,
	_mcl_hardness = 0.1,
	_mcl_silk_touch_drop = false,
})

mcl_buckets.register_liquid({
	id = "powder_snow",
	source_take = {"mc_parity:powder_snow"},
	source_place = "mc_parity:powder_snow",
	bucketname = "mc_parity:bucket_powder_snow",
	inventory_image = "bucket_powder_snow.png",
	name = S("Powder Snow Bucket"),
	longdesc = S("This bucket is filled powder snow"),
	usagehelp = S("Place it to empty the bucket and place powder snow. Obtain by right clicking on a block of powder snow with an empty bucket."),
	tt_help = S("Places a powder snow block"),
})

local freezing_stages =
{
	"freezing_1.png",
	"freezing_2.png",
	"freezing_3.png",
}

-- key value pair
-- key: ObjectRef of the player
-- value: list of hud ids
local freezing_players = {}

local function remove_freezing_hud(player)
	local freezing_data = freezing_players[player]
	if freezing_data and #freezing_data > 0 then
		for _, hud_id in pairs(freezing_data) do
			player:hud_remove(hud_id)
		end
	end

	freezing_players[player] = nil
end

local function show_freezing_hud(player, level)
	remove_freezing_hud(player)
	if not freezing_players[player] then
		freezing_players[player] = {}
	end
	local freezing_data = freezing_players[player]

	freezing_data[1] = player:hud_add({
		type = "image",
		position = {x = 0, y = 0},
		scale = {x = 2, y = 2},
		text = freezing_stages[level],
		alignment = {x = 1, y = 1},
		offset = {x = 0, y = 0},
		z_index = 4,
	})

	freezing_data[2] = player:hud_add({
		type = "image",
		position = {x = 1, y = 0},
		scale = {x = 2, y = 2},
		text = freezing_stages[level] .. "^[transform4",
		alignment = {x = -1, y = 1},
		offset = {x = 0, y = 0},
		z_index = 4,
	})

	freezing_data[3] = player:hud_add({
		type = "image",
		position = {x = 0, y = 1},
		scale = {x = 2, y = 2},
		text = freezing_stages[level] .. "^[transform6",
		alignment = {x = 1, y = -1},
		offset = {x = 0, y = 0},
		z_index = 4,
	})

	freezing_data[4] = player:hud_add({
		type = "image",
		position = {x = 1, y = 1},
		scale = {x = 2, y = 2},
		text = freezing_stages[level] .. "^[transform6^[transform4",
		alignment = {x = -1, y = -1},
		offset = {x = 0, y = 0},
		z_index = 4,
	})
end

local function player_has_leather_armor(player)
	local armor_list = player:get_inventory():get_list("armor")
	for i = 2, 5 do
		if core.get_item_group(armor_list[i]:get_name(), "armor_leather") == 1 then
			return true
		end
	end
	return false
end

local freeze_hurts_extra_types = {
	"mobs_mc:strider",
	"mobs_mc:blaze",
	"mobs_mc:magma_cube",
}

mcl_damage.register_modifier (function (obj, damage, reason)
	local entity = obj:get_luaentity ()
	if entity
		and table.indexof (freeze_hurts_extra_types, entity.name) ~= -1
		and reason.type == "freeze" then
		return damage * 5.0
	end
	return damage
end, 200)

local _powder_gs
if mcl_player.register_globalstep_slow then
	_powder_gs = function(f) mcl_player.register_globalstep_slow(f) end
else
	-- the standard globalstep has no player param — emulate the slow loop
	_powder_gs = function(f)
		minetest.register_globalstep(function(dtime)
			for _, _p in ipairs(minetest.get_connected_players()) do
				f(_p, dtime)
			end
		end)
	end
end
_powder_gs(function(player, dtime)
	local player_pos = player:get_pos()
	local player_meta = player:get_meta()
	local time_in_snow = tonumber(player_meta:get("time_in_snow"))

	if core.get_node(player_pos).name == "mc_parity:powder_snow" and not player_has_leather_armor(player) then
		if not time_in_snow then
			time_in_snow = 0
		end

		time_in_snow = math.min(time_in_snow + 0.5, 7)

		if time_in_snow > 5 then
			show_freezing_hud(player, 3)
			mcl_damage.damage_player(player, 0.5, {type = "freeze"})
			hb.change_hudbar(player, "health", nil, nil, "frozen_heart.png")
		elseif time_in_snow == 3 then
			show_freezing_hud(player, 2)
		elseif time_in_snow == 1 then
			show_freezing_hud(player, 1)
		end

		player_meta:set_string("time_in_snow", tostring(time_in_snow))
	elseif time_in_snow then
		time_in_snow = time_in_snow - 0.5

		if time_in_snow <= 0 then
			remove_freezing_hud(player)
			player_meta:set_string("time_in_snow", "")
			return
		else
			if time_in_snow == 1 then
				show_freezing_hud(player, 1)
			elseif time_in_snow == 3 then
				hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png")
				show_freezing_hud(player, 2)
			end
		end

		player_meta:set_string("time_in_snow", tostring(time_in_snow))
	end
end)

core.register_on_joinplayer(function(player)
	local time_in_snow = tonumber(player:get_meta():get("time_in_snow"))

	if not time_in_snow then return end

	if time_in_snow > 5 then
		show_freezing_hud(player, 3)
		core.after(0, function() hb.change_hudbar(player, "health", nil, nil, "frozen_heart.png") end)
	elseif time_in_snow > 3 then
		show_freezing_hud(player, 2)
	elseif time_in_snow > 1 then
		show_freezing_hud(player, 1)
	end
end)

core.register_on_leaveplayer(function(player)
	freezing_players[player] = nil
end)

core.register_on_respawnplayer(function(player)
	remove_freezing_hud(player)
	hb.change_hudbar(player, "health", nil, nil, "hudbars_icon_health.png")
end)


-- ======================= ECHO SHARD (1.19) =======================
minetest.register_craftitem("mc_parity:echo_shard", {
	description = S("Echo Shard"),
	groups = {craftitem = 1, rarity = 1},
	inventory_image = "mc_parity_echo_shard.png",
	wield_image = "mc_parity_echo_shard.png"
})


-- ======================= MACE (1.21) =======================
local S = core.get_translator("mc_parity")
mc_parity.mace_cooldown = {}

--Mace Cooldown
local cooldown_time = 1.6
local heavy_core_longdesc = S("Solid Blocks of Steel. These are only forged if those that are brave enough can defeat the trials that await them.")
local mace_longdesc = S("The mace is a slow melee weapon that deals incredible damage. “dig” key to use it. This weapon has a cooldown of 1.6 seconds, but if you fall the mace will deal more damage than if you are on the ground. The further you fall the more damage done. If you hit a mob or player then you will receive no fall damage, but beware. If you miss you will die. ")

core.register_node("mc_parity:heavy_core", {
    description = S("Heavy Core"),
	paramtype = "light",
    _doc_items_longdesc = heavy_core_longdesc,
    tiles = {"mc_parity_heavy_core_top.png", "mc_parity_heavy_core_bottom.png", "mc_parity_heavy_core_side.png"},
    is_ground_content = false,
    groups = {pickaxey = 1, deco_block = 1, rarity = 3},
    sounds = mcl_sounds.node_sound_stone_defaults(),
    paramtype2 = "facedir",
    drawtype = "nodebox",
    use_texture_alpha = "clip",
    node_box = {
        type = "fixed",
            fixed = {
              {-0.25, -0.5, -0.25, 0.25, 0.0, 0.25},
        },
    },
    _mcl_hardness = 10,
    _mcl_blast_resistance = 30,
})

local WIND_BURST_BOUNCE_MULTIPLIER = 8

--Mace
core.register_tool("mc_parity:mace", {
	description = S("Mace"),
	_doc_items_longdesc = mace_longdesc,
	inventory_image = "mc_parity_mace.png",
	groups = { weapon=1, mace=1, dig_speed_class=1, enchantability=10, rarity = 3 },
	wield_scale = mcl_vars.tool_wield_scale,
	tool_capabilities = {
		full_punch_interval = 1.6,
		max_drop_level = 1,
		groupcaps = {
			snappy = {times = {1.5, 0.9, 0.4}, uses = 50, maxlevel = 3},
		},
		damage_groups = {fleshy = 5},
	},
	_repair_material = "mcl_mobitems:breeze_rod",
	_mcl_toollike_wield = true,

	on_use = function(itemstack, user, pointed_thing)
		local user_velocity = user:get_velocity()
		mc_parity.mace_entity = pointed_thing.ref
		if pointed_thing.type == "object" then
			local current_time = core.get_gametime()
			mc_parity.mace_cooldown[user] = mc_parity.mace_cooldown[user] or 0
			if current_time - mc_parity.mace_cooldown[user] >= cooldown_time then
				mc_parity.mace_cooldown[user] = current_time
				-- Define blocks based on laws of physics (an non-perfect solution for defining "blocks" based on velocity):
				-- E(h) = mgh
				-- E(k) = (mv^2)/2
				-- E(h) = E(k) so:
				-- mgh = (mv^2)/2
				-- h = (v^2)/2g
				-- based on experiment g = 20
				local blocks = -1*math.abs(user_velocity.y)*user_velocity.y/40
				local enchantments = mcl_enchanting.get_enchantments(itemstack)
				if mc_parity.mace_entity:is_player() or mc_parity.mace_entity:get_luaentity() then
					if blocks > 1 then
						user:add_velocity(vector.new(0, -user_velocity.y, 0))
						if enchantments.wind_burst then
							local pos = core.get_pointed_thing_position(pointed_thing)
							local user_pos = user:get_pos()
							if vector.distance(user_pos, pos) < 3 then
								user:add_velocity(vector.new(0, WIND_BURST_BOUNCE_MULTIPLIER * enchantments.wind_burst, 0))
							end
						core.sound_play("tnt_explode", { pos = pos, gain = 0.4, max_hear_distance = 30, pitch = 2.5 }, true)
						core.add_particlespawner(table.merge(mcl_charges.wind_burst_spawner, {
							minpos = vector.offset(pos, -0.8, 0.6, -0.8),
							maxpos = vector.offset(pos, 0.8, 0.8, 0.8),
						}))
						end
					end
					--damage calculation from https://minecraft.wiki/w/Mace
					local damage = 0
					local enchantments = mcl_enchanting.get_enchantments(itemstack)
					if blocks > 1.5 and enchantments.density then
						damage =  damage + enchantments.density * blocks/2
					end
					if blocks > 8 then
						damage = damage + 23 + blocks
					elseif blocks > 3 then
						damage = damage + blocks * 2 + 18
					elseif blocks > 1.5 then
						damage = damage + blocks * 4 + 9
					elseif blocks > 0 then
						damage = damage + 9
					else
						damage = 6
					end

					mc_parity.mace_entity:punch(user, 1.6, {
						full_punch_interval = 1.6,
						damage_groups = {fleshy = damage},
					}, nil)

					if not core.is_creative_enabled(user:get_player_name()) then
						itemstack:add_wear(65535 / 500)
						return mcl_util.return_itemstack_if_alive(user, itemstack)
					end
				end
			end
		end
	end,
})

core.register_on_leaveplayer(function(player)
	mc_parity.mace_cooldown[player] = nil
end)

-- By Cora
mcl_damage.register_modifier(function(obj, damage, reason)
	if reason.type == "fall" and mc_parity.mace_cooldown[obj] and core.get_gametime() - mc_parity.mace_cooldown[obj] < 2 then
			return 0
	end
end)

--Crafting recipe for mace
core.register_craft({
	output = "mc_parity:mace",
	recipe = {
		{ "", "mc_parity:heavy_core" },
		{ "", "mcl_mobitems:breeze_rod" },
	}
})


-- ======================= CHAIN (1.16, VL -> MCLN) =======================
minetest.register_node("mc_parity:chain", {
	description = S("Chain"),
	_doc_items_longdesc = S("Chains are metallic decoration blocks."),
	inventory_image = "mc_parity_chain_inv.png",
	tiles = {"mc_parity_chain.png"},
	drawtype = "mesh",
	paramtype = "light",
	paramtype2 = "facedir",
	use_texture_alpha = "clip",
	mesh = "mc_parity_chain.obj",
	is_ground_content = false,
	sunlight_propagates = true,
	collision_box = {
		type = "fixed",
		fixed = {
			{-0.0625, -0.5, -0.0625, 0.0625, 0.5, 0.0625},
		}
	},
	selection_box = {
		type = "fixed",
		fixed = {
			{-0.0625, -0.5, -0.0625, 0.0625, 0.5, 0.0625},
		}
	},
	groups = {pickaxey = 1, deco_block = 1},
	sounds = mcl_sounds.node_sound_metal_defaults(),
	on_place = place_chain,
	_mcl_blast_resistance = 6,
	_mcl_hardness = 5,
})

