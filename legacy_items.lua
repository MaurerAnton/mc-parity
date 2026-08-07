-- ---------------------------------------------------------------------------
-- LAST PRE-1.13 ITEMS: the lead (1.6), the dragon head (1.9), the shulker
-- boxes (1.11) and the tipped/spectral arrows (1.9). Both games lacked all
-- of these.
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

-- ------------------------------------------------------------------ lead --
minetest.register_craftitem("mc_parity:lead", {
	description = S("Lead"),
	_doc_items_longdesc = S("Tie a mob to a fence post — or to yourself. "
		.. "Right-click a mob to attach the lead, right-click a fence post "
		.. "to tether it, right-click again to detach."),
	inventory_image = "mc_parity_lead.png",
	groups = { craftitem = 1 },
})
minetest.register_craft({
	output = "mc_parity:lead 2",
	recipe = {
		{ "mcl_mobitems:string", "mcl_mobitems:string", "mcl_mobitems:string" },
		{ "mcl_mobitems:string", "mcl_mobitems:slimeball", "mcl_mobitems:string" },
		{ "mcl_mobitems:string", "mcl_mobitems:string", "mcl_mobitems:string" },
	},
})

-- leashed entities: { [entity_id] = { anchor = pos | nil, owner = name } }
local leashed = {}

minetest.register_globalstep(function(dtime)
	if not mc_parity._lead_step then mc_parity._lead_step = 0 end
	mc_parity._lead_step = mc_parity._lead_step + dtime
	if mc_parity._lead_step < 0.5 then return end
	mc_parity._lead_step = 0
	for id, data in pairs(leashed) do
		local obj = minetest.get_entity_by_id(id)
		if not obj or not obj:is_valid() then
			leashed[id] = nil
		else
			local mpos = obj:get_pos()
			local target = nil
			if data.anchor then
				target = data.anchor
			elseif data.owner then
				local p = minetest.get_player_by_name(data.owner)
				if p then target = p:get_pos() end
			end
			if target and mpos then
				local d = vector.distance(mpos, target)
				if d > 10 then
					-- pull the mob back inside the leash range
					local dir = vector.normalize(vector.subtract(target, mpos))
					obj:set_velocity(vector.multiply(dir, 3))
					obj:set_acceleration(vector.multiply(dir, 3))
				elseif d < 2 and data.anchor then
					obj:set_velocity({ x = 0, y = 0, z = 0 })
				end
			end
		end
	end
end)

local function leash_target(player, pointed_thing, anchor)
	if not pointed_thing or not pointed_thing.type then return false end
	if pointed_thing.type == "object" then
		local obj = pointed_thing.ref
		if not obj or not obj:get_luaentity() then return false end
		-- toggle: attached mob -> detach
		if leashed[obj:get_luaentity()._id or obj:get_entity_name()] then
			leashed[obj:get_luaentity()._id or obj:get_entity_name()] = nil
			if obj:get_luaentity() and obj:get_luaentity()._mca_leash then
				obj:get_luaentity()._mca_leash = nil
			end
			return true
		end
		local le = obj:get_luaentity()
		leashed[le._id or obj:get_entity_name()] = {
			owner = player:get_player_name(),
			anchor = anchor,
		}
		if le then le._mca_leash = true end
		return true
	elseif pointed_thing.type == "node" then
		-- tether to a fence post
		local n = minetest.get_node(pointed_thing.under)
		if minetest.get_item_group(n.name, "fence") == 0 then return false end
		-- find the nearest leashed-by-me mob and anchor it here
		for id, data in pairs(leashed) do
			if data.owner == player:get_player_name() and not data.anchor then
				data.anchor = pointed_thing.under
				return true
			end
		end
	end
	return false
end

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if puncher and puncher:is_player() and puncher:get_wielded_item():get_name() == "mc_parity:lead" then
		leash_target(puncher, { type = "node", under = pos }, pos)
	end
end)

minetest.register_chatcommand("lead-test", {
	description = "debug: list leashes",
	privs = { server = true },
	func = function()
		local n = 0
		for _ in pairs(leashed) do n = n + 1 end
		return true, "leashed: " .. n
	end,
})

-- ---------------------------------------------------------- dragon head ----
-- (the mcl_heads.register_head API prefixes mcl_heads: and can't be called
-- from another mod's load context — register our own node instead)
minetest.register_node("mc_parity:dragon_head", {
	description = S("Dragon Head"),
	_doc_items_longdesc = S("The head of the Ender Dragon — a trophy "
		.. "found on the bows of end ships."),
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = { -0.25, -0.5, -0.25, 0.25, 0.25, 0.25 },
	},
	paramtype = "light",
	paramtype2 = "facedir",
	tiles = { "mc_parity_dragon_head.png" },
	is_ground_content = false,
	groups = { handy = 1, dig_by_hand = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
})
minetest.register_craft({
	output = "mc_parity:dragon_head",
	recipe = {
		{ "mcl_mobitems:dragon_breath", "mcl_mobitems:dragon_breath" },
		{ "mcl_mobitems:dragon_breath", "mcl_mobitems:dragon_breath" },
	},
})

-- -------------------------------------------------------- shulker boxes ----
local SHULKER_COLORS = {
	{ "white", "#e9e9e9" }, { "orange", "#f08000" }, { "magenta", "#c74ebd" },
	{ "light_blue", "#3aaaf9" }, { "yellow", "#f8e627" }, { "lime", "#70d919" },
	{ "pink", "#ed8dac" }, { "gray", "#414141" }, { "silver", "#a0a7a7" },
	{ "cyan", "#168989" }, { "purple", "#813f9e" }, { "blue", "#334cb2" },
	{ "brown", "#734931" }, { "green", "#546d1b" }, { "red", "#a02722" },
	{ "black", "#1d1d21" }, { "", "#9c5fb5" },  -- default (undyed)
}

local function shulker_box_node(name, color, glow)
	minetest.register_node(name, {
		description = S("Shulker Box"),
		_doc_items_longdesc = S("A portable chest: it keeps its contents "
			.. "when dug up and placed again."),
		tiles = { "mc_parity_shulker_" .. (color == "" and "default" or color) .. ".png" },
		is_ground_content = false,
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
		light_source = glow or 0,
		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:get_inventory():set_size("main", 27)
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			if player then mcl_chests.open_chest(pos, player) end
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			if player then mcl_chests.open_chest(pos, player) end
		end,
		after_dig_node = function(pos, oldnode, oldmetadata, digger)
			-- drop the box WITH its contents (the MC shulker box property).
			-- NOTE: the engine passes oldmetadata = meta:to_table() (a plain
			-- table with .fields and .inventory), NOT a MetadataRef.
			local inv_data = oldmetadata and oldmetadata.inventory or nil
			local items = {}
			if inv_data and inv_data.main then
				for i = 1, math.min(#inv_data.main, 27) do
					local s = inv_data.main[i]
					if s and not s:is_empty() then
						items[#items + 1] = s:to_string()
					end
				end
			end
			local itemstack = ItemStack(name)
			if #items > 0 then
				itemstack:get_meta():set_string("inv", minetest.serialize(items))
			end
			minetest.add_item(pos, itemstack)
		end,
		on_place = function(itemstack, placer, pointed_thing)
			local pos = pointed_thing and pointed_thing.under
			local def = minetest.registered_nodes[name]
			local ok = minetest.item_place_node(itemstack, placer, pointed_thing, def)
			if ok and itemstack:get_meta():get_string("inv") ~= "" then
				-- restore the contents
				local items = minetest.deserialize(itemstack:get_meta():get_string("inv"))
				if type(items) == "table" then
					local meta = minetest.get_meta(pos)
					meta:get_inventory():set_size("main", 27)
					for i, s in ipairs(items) do
						meta:get_inventory():set_stack("main", i, s)
					end
				end
				itemstack:get_meta():set_string("inv", "")
			end
			return itemstack
		end,
	})
end

local SHULKER = "mc_parity:shulker_box"
for _, c in ipairs(SHULKER_COLORS) do
	shulker_box_node(SHULKER .. (c[1] == "" and "" or "_" .. c[1]), c[1], c[1] == "purple" and 7 or 0)
end
-- craft: 2 shulker shells + 1 chest -> default box; dye it for colors
minetest.register_craft({
	output = SHULKER,
	recipe = {
		{ "mcl_mobitems:shulker_shell", "mcl_mobitems:shulker_shell" },
		{ "mcl_chests:chest", "mcl_chests:chest" },
	},
})
minetest.register_craft({
	type = "shapeless",
	output = SHULKER,
	recipe = { SHULKER .. "_white" },
})

-- -------------------------------------------------------- tipped arrows ----
-- the games' bows fire any item with the ammo_bow group; the custom arrow
-- items register a per-effect entity that reuses the game's arrow class
-- (VL: vl_projectile copy + hit override; Mineclonia: _extra_hit_func).
local TIPPED = {
	poison    = { effect = "poison", duration = 8, color = "#3fae49" },
	slowness  = { effect = "slowness", duration = 8, color = "#7f9ee0" },
	weakness  = { effect = "weakness", duration = 8, color = "#8f8f8f" },
	swiftness = { effect = "swiftness", duration = 8, color = "#e0d07f" },
	harming   = { effect = "harming", duration = 0, color = "#d03a3a", damage = 6 },
	healing   = { effect = "healing", duration = 0, color = "#e07fae", heal = 6 },
	spectral  = { effect = "glowing", duration = 12, color = "#e8e8a0" },
}

local base_arrow = minetest.registered_entities and minetest.registered_entities["mcl_bows:arrow_entity"]

local function tipped_effect(self, obj)
	if not obj or not obj:is_player() then return end
	local item = self._arrow_item or ""
	local eff = TIPPED[item:match("arrow_([a-z]+)$") or ""]
	if not eff then return end
	if eff.damage then
		mcl_util.deal_damage(obj, eff.damage, { type = "arrow", source = self._shooter })
	elseif eff.heal then
		local hp = obj:get_hp()
		obj:set_hp(math.min(hp + eff.heal, obj:get_properties().hp_max or 20))
	elseif eff.effect then
		mcl_potions.give_effect_by_level(eff.effect, obj, 1, eff.duration)
	end
end

if base_arrow then
	for name, eff in pairs(TIPPED) do
		minetest.register_craftitem("mc_parity:arrow_" .. name, {
			description = S("Arrow of " .. name),
			inventory_image = "mc_parity_arrow_" .. name .. ".png",
			groups = { ammo_bow = 1, ammo_bow_regular = 1, craftitem = 1 },
			_arrow_image = { "mcl_bows_arrow.png^[colorize:" .. eff.color .. ":220" },
			stack_max = 64,
		})
		-- entity: copy the game's arrow class, inject the effect on hit
		local cls = table.copy(base_arrow)
		if cls.on_collide_with_entity then  -- VL (vl_projectile)
			local orig = cls.on_collide_with_entity
			cls.on_collide_with_entity = function(self, pos, obj)
				orig(self, pos, obj)
				tipped_effect(self, obj)
			end
		elseif cls._extra_hit_func then  -- Mineclonia (its own projectile)
			local orig_extra = cls._extra_hit_func
			cls._extra_hit_func = function(self, obj)
				if orig_extra then orig_extra(self, obj) end
				tipped_effect(self, obj)
			end
		end
		minetest.register_entity("mc_parity:arrow_" .. name .. "_entity", cls)
	end
	-- crafts: 8 arrows + 1 lingering potion -> 8 tipped arrows
	local POTION = {
		poison = "poison_lingering", slowness = "slowness_lingering",
		weakness = "weakness_lingering", swiftness = "swiftness_lingering",
		harming = "harming_lingering", healing = "healing_lingering",
	}
	for name, potion in pairs(POTION) do
		minetest.register_craft({
			output = "mc_parity:arrow_" .. name .. " 8",
			recipe = {
				{ "mcl_bows:arrow", "mcl_bows:arrow", "mcl_bows:arrow" },
				{ "mcl_bows:arrow", "mcl_potions:" .. potion, "mcl_bows:arrow" },
				{ "mcl_bows:arrow", "mcl_bows:arrow", "mcl_bows:arrow" },
			},
		})
	end
	-- spectral: 1 arrow + 4 glowstone -> 2 spectral arrows
	minetest.register_craft({
		output = "mc_parity:arrow_spectral 2",
		recipe = {
			{ "mcl_core:glowstone_dust", "mcl_core:glowstone_dust" },
			{ "mcl_core:glowstone_dust", "mcl_bows:arrow" },
		},
	})
end

minetest.log("action", "[mc_parity] legacy items: lead + dragon head + shulker boxes + tipped arrows")
