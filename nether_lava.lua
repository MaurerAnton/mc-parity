-- Nether lava (MC parity, unique): in Minecraft the Nether's lava flows
-- like water — fast and spreading 7 blocks — unlike overworld lava (slow,
-- 3 blocks). Neither game has this distinction.
--
-- Implementation: a NEW liquid pair (engine-simulated — Luanti's liquid
-- system handles viscosity/range natively): liquid_viscosity = 1 (water),
-- liquid_range = 7. The nether's existing lava lakes (mcl_core:lava_source
-- sitting on netherrack) are converted to the fast variant by an ABM —
-- overworld lava (on stone) is untouched.

local S = minetest.get_translator("mc_parity")

-- Derive the lava tile names from the game's OWN lava node (the games name
-- them "default_lava_*_animated.png"; hardcoding "mcl_core_lava_*" produced
-- dummy textures on the client). Fallbacks keep the node registrable if
-- mcl_core is ever absent.
local function lava_tex(node_name, fallback)
	local n = minetest.registered_nodes[node_name]
	if n then
		local t = n.special_tiles and n.special_tiles[1]
		if t then
			if type(t) == "table" then return t.name or fallback end
			return t:match("^([^%^]+)") or fallback
		end
		t = n.tiles and n.tiles[1]
		if t then
			if type(t) == "table" then return t.name or fallback end
			return t:match("^([^%^]+)") or fallback
		end
	end
	return fallback
end
local LAVA_TILE = lava_tex("mcl_core:lava_source", "default_lava_source_animated.png")
local LAVA_FLOW = lava_tex("mcl_core:lava_flowing", "default_lava_flowing_animated.png")

minetest.register_node("mc_parity:nether_lava_source", {
	description = S("Nether Lava Source"),
	drawtype = "liquid",
	tiles = {
		{ name = LAVA_TILE, animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.0 } },
	},
	special_tiles = {
		{
			name = LAVA_TILE,
			animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 3.0 },
			backface_culling = false,
		},
	},
	paramtype = "light",
	light_source = minetest.LIGHT_MAX - 1,
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_lava_defaults(),
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 4,
	liquidtype = "source",
	liquid_alternative_flowing = "mc_parity:nether_lava_flowing",
	liquid_alternative_source = "mc_parity:nether_lava_source",
	liquid_viscosity = 1,  -- water-like: fast (MC nether lava)
	liquid_renewable = false,
	liquid_range = 7,      -- spreads like water (MC nether lava)
	damage_per_second = 4 * 2,
	post_effect_color = { a = 245, r = 208, g = 73, b = 10 },
	stack_max = 64,
	groups = { lava = 3, lava_source = 1, liquid = 2, destroys_items = 1,
		not_in_creative_inventory = 1, dig_by_piston = 1, set_on_fire = 15, fire_damage = 1 },
	_mcl_blast_resistance = 100,
	_mcl_hardness = -1,
})

minetest.register_node("mc_parity:nether_lava_flowing", {
	description = S("Flowing Nether Lava"),
	_doc_items_create_entry = false,
	wield_image = LAVA_FLOW .. "^[verticalframe:64:0",
	drawtype = "flowingliquid",
	tiles = { LAVA_FLOW .. "^[verticalframe:64:0" },
	special_tiles = {
		{ name = LAVA_FLOW, backface_culling = false,
			animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 6.6 } },
		{ name = LAVA_FLOW, backface_culling = false,
			animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 6.6 } },
	},
	paramtype = "light",
	paramtype2 = "flowingliquid",
	light_source = minetest.LIGHT_MAX - 1,
	is_ground_content = false,
	sounds = mcl_sounds.node_sound_lava_defaults(),
	walkable = false,
	pointable = false,
	diggable = false,
	buildable_to = true,
	drop = "",
	drowning = 4,
	liquidtype = "flowing",
	liquid_alternative_flowing = "mc_parity:nether_lava_flowing",
	liquid_alternative_source = "mc_parity:nether_lava_source",
	liquid_viscosity = 1,
	liquid_renewable = false,
	liquid_range = 7,
	damage_per_second = 4 * 2,
	post_effect_color = { a = 245, r = 208, g = 73, b = 10 },
	stack_max = 64,
	groups = { lava = 3, liquid = 2, destroys_items = 1,
		not_in_creative_inventory = 1, dig_by_piston = 1, set_on_fire = 15, fire_damage = 1 },
	_mcl_blast_resistance = 100,
	_mcl_hardness = -1,
})

-- Convert the nether's lava lakes to the fast variant: lava sitting on
-- netherrack is nether lava (overworld lava sits on stone — untouched).
-- Extracted so it can be called directly (ABMs don't run headless).
function mc_parity.convert_nether_lava(pos, node)
	local below = minetest.get_node(vector.offset(pos, 0, -1, 0)).name
	if below == "mcl_nether:netherrack" then
		local nn = "mc_parity:nether_lava_source"
		if node.name == "mcl_core:lava_flowing" then
			nn = "mc_parity:nether_lava_flowing"
		end
		minetest.set_node(pos, { name = nn, param2 = node.param2 })
		return true
	end
	return false
end

minetest.register_abm({
	label = "nether lava conversion",
	nodenames = { "mcl_core:lava_source", "mcl_core:lava_flowing" },
	interval = 8,
	chance = 1,
	action = mc_parity.convert_nether_lava,
})

minetest.log("action", "[mc_parity] nether lava registered (water-like flow, ABM conversion)")
