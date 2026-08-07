-- ---------------------------------------------------------------------------
-- TRIAL CHAMBERS (MC 1.21) — the last big vanilla structure.
--   * trial spawner: a node-timer block (like the game's vanilla spawner)
--     that spawns waves scaled to the nearby player count, drops loot when
--     the wave is cleared, then cools down.
--   * vault: per-player loot chest, opened with a trial key.
--   * trial key + wind charge items.
--   * build_trial_chambers: a tuff/copper labyrinth (central chamber +
--     4 corridors + 4 vault rooms + lava traps) placed deep underground.
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mcl_mobs_addon")

local TRIAL_LOOT = { -- pool for both the wave reward and the vault
	"mcl_mobs_addon:wind_charge 3",
	"mcl_mobs_addon:wind_charge 2",
	"mcl_mobs_addon:breeze_rod 1",
	"mcl_mobs_addon:breeze_rod 2",
	"mcl_core:emerald 2",
	"mcl_core:emerald 4",
	"mcl_core:diamond 1",
}

local WAVE_MOBS = { -- weighted per room discipline
	{ "mobs_mc:zombie", 6 },
	{ "mobs_mc:skeleton", 5 },
	{ "mobs_mc:spider", 4 },
	{ "mobs_mc:stray", 3 },
	{ "mobs_mc:husk", 3 },
	{ "mobs_mc:slime", 2 },
	{ "mcl_mobs_addon:breeze", 2 },  -- the breeze guards its chambers
}

local function pick_weighted(list, pr)
	local total = 0
	for _, e in ipairs(list) do total = total + e[2] end
	local r = pr and pr:next(1, total) or math.random(total)
	for _, e in ipairs(list) do
		r = r - e[2]
		if r <= 0 then return e[1] end
	end
	return list[1][1]
end

-- ---------------------------------------------------------------- spawner --
minetest.register_node("mcl_mobs_addon:trial_spawner", {
	description = S("Trial Spawner"),
	_doc_items_longdesc = S("Spawns hostile mobs when players come close. "
		.. "After the wave is cleared it drops loot, then cools down."),
	tiles = { "mcl_mobs_addon_trial_spawner.png" },
	is_ground_content = false,
	groups = { pickaxe = 2, dig_by_pickaxe = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	light_source = 7,
	after_place_node = function(pos)
		minetest.get_node_timer(pos):start(2)
	end,
	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
		local state = meta:get_string("state")
		if state == "" or state == "inactive" then
			-- look for nearby players
			local players = minetest.get_connected_players()
			local near = 0
			for _, p in ipairs(players) do
				if vector.distance(p:get_pos(), pos) < 14 then near = near + 1 end
			end
			if near > 0 then
				-- activate: wave = 2 + 1 per player (cap 8)
				local wave = math.min(2 + near, 8)
				meta:set_int("wave", wave)
				meta:set_int("alive", 0)
				meta:set_string("state", "active")
				local pr = PseudoRandom(pos.x * 7919 + pos.y * 104729 + pos.z)
				local mob = pick_weighted(WAVE_MOBS, pr)
				local spawned = 0
				for i = 1, wave do
					local p = vector.offset(pos, 0, 1, 0)
					local o = minetest.add_entity(p, mob)
					if o then
						local le = o:get_luaentity()
						if le then le._mca_trial = minetest.pos_to_string(pos) end
						spawned = spawned + 1
					end
				end
				meta:set_int("alive", spawned)
				minetest.log("action", "[mcl_mobs_addon] trial spawner @ "
					.. minetest.pos_to_string(pos) .. " wave=" .. spawned .. " mob=" .. mob)
				minetest.get_node_timer(pos):start(2)
				return true
			end
			minetest.get_node_timer(pos):start(3)
			return true
		elseif state == "active" then
			-- reward when the whole wave is dead (checked via the globalstep
			-- that counts the _mca_trial entities; on_timer just re-schedules)
			if meta:get_int("alive") <= 0 then
				meta:set_string("state", "reward")
				-- drop the loot above the spawner
				local pr = PseudoRandom(pos.x * 31 + pos.y * 17 + pos.z)
				local n = pr:next(2, 4)
				for i = 1, n do
					local item = TRIAL_LOOT[pr:next(1, #TRIAL_LOOT)]
					minetest.add_item(vector.offset(pos, 0, 1.2, 0), item)
				end
				minetest.add_item(vector.offset(pos, 0, 1.2, 0),
					"mcl_mobs_addon:trial_key 1")
				meta:set_string("state", "cooldown")
				minetest.get_node_timer(pos):start(1800)
				minetest.log("action", "[mcl_mobs_addon] trial spawner @ "
					.. minetest.pos_to_string(pos) .. " cleared — reward dropped")
				return true
			end
			minetest.get_node_timer(pos):start(2)
			return true
		elseif state == "cooldown" then
			meta:set_string("state", "inactive")
			meta:set_int("wave", 0)
			minetest.get_node_timer(pos):start(3)
			return true
		end
		return true
	end,
})

-- count the surviving trial mobs every 2s and update their spawners
minetest.register_globalstep(function(dtime)
	if not mcl_mobs_addon._trial_step then mcl_mobs_addon._trial_step = 0 end
	mcl_mobs_addon._trial_step = mcl_mobs_addon._trial_step + dtime
	if mcl_mobs_addon._trial_step < 2 then return end
	mcl_mobs_addon._trial_step = 0
	local counts = {}
	for _, le in pairs(minetest.luaentities) do
		if le._mca_trial then
			counts[le._mca_trial] = (counts[le._mca_trial] or 0) + 1
		end
	end
	for pos_str, n in pairs(counts) do
		local pos = minetest.string_to_pos(pos_str)
		if pos then
			local meta = minetest.get_meta(pos)
			if meta:get_string("state") == "active" then
				meta:set_int("alive", n)
			end
		end
	end
end)

-- ------------------------------------------------------------------ vault --
minetest.register_node("mcl_mobs_addon:vault", {
	description = S("Vault"),
	_doc_items_longdesc = S("A per-player loot container. Open it with a "
		.. "trial key: each player gets the loot once."),
	tiles = { "mcl_mobs_addon_vault.png" },
	is_ground_content = false,
	groups = { pickaxe = 2, dig_by_pickaxe = 1, deco_block = 1 },
	sounds = mcl_sounds.node_sound_stone_defaults(),
	light_source = 5,
	on_rightclick = function(pos, node, player, itemstack)
		local name = player:get_player_name()
		local meta = minetest.get_meta(pos)
		if itemstack:get_name() ~= "mcl_mobs_addon:trial_key" then
			minetest.chat_send_player(name, S("The vault is sealed. It needs a trial key."))
			return itemstack
		end
		local opened = meta:get_string("opened") or ""
		if string.find(opened, "|" .. name .. "|", 1, true) then
			minetest.chat_send_player(name, S("You already opened this vault."))
			return itemstack
		end
		-- consume the key, give the loot (drop the rest at the vault)
		local pr = PseudoRandom(pos.x * 13 + pos.y * 7 + pos.z)
		if not minetest.is_creative_enabled(name) then
			itemstack:take_item()
		end
		local inv = player:get_inventory()
		for i = 1, 3 do
			local item = TRIAL_LOOT[pr:next(1, #TRIAL_LOOT)]
			if not inv:room_for_item("main", item) then
				minetest.add_item(vector.offset(pos, 0, 1, 0), item)
			else
				inv:add_item("main", item)
			end
		end
		meta:set_string("opened", opened .. "|" .. name .. "|")
		minetest.chat_send_player(name, S("The vault opens — loot secured!"))
		return itemstack
	end,
})

-- ------------------------------------------------------------------ items --
minetest.register_craftitem("mcl_mobs_addon:trial_key", {
	description = S("Trial Key"),
	inventory_image = "mcl_mobs_addon_trial_key.png",
	groups = { craftitem = 1 },
})
minetest.register_craftitem("mcl_mobs_addon:wind_charge", {
	description = S("Wind Charge"),
	inventory_image = "mcl_mobs_addon_wind_charge.png",
	groups = { craftitem = 1 },
})

-- ------------------------------------------------------------ structure --
local T = "mcl_deepslate:tuff"
local C = "mcl_copper:block"
local CC = "mcl_copper:block_cut"
local LAVA = "mcl_core:lava_source"

-- voxelmanip in the mapgen thread (place_func), direct set_node elsewhere
-- (tests, on-demand building)
local function make_area(pos, size)
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

local function box(area, a, b, node)
	for x = a.x, b.x do
		for y = a.y, b.y do
			for z = a.z, b.z do
				area:set_node({ x = x, y = y, z = z }, { name = node })
			end
		end
	end
end

local function hollow_box(area, a, b, wall, floor)
	-- walls + ceiling
	for x = a.x, b.x do
		for y = a.y, b.y do
			for z = a.z, b.z do
				if x == a.x or x == b.x or z == a.z or z == b.z or y == b.y then
					area:set_node({ x = x, y = y, z = z }, { name = wall })
				end
			end
		end
	end
	-- floor with copper trim
	for x = a.x, b.x do
		for z = a.z, b.z do
			area:set_node({ x = x, y = a.y, z = z }, { name = floor })
		end
	end
end

local function clear_room(area, a, b)
	for x = a.x + 1, b.x - 1 do
		for y = a.y + 1, b.y - 1 do
			for z = a.z + 1, b.z - 1 do
				area:set_node({ x = x, y = y, z = z }, { name = "air" })
			end
		end
	end
end

function mcl_mobs_addon.build_trial_chambers(pos, def, pr, blockseed)
	local area = make_area(vector.offset(pos, -10, 0, -10), { x = 21, y = 9, z = 21 })

	local c = pos  -- chamber centre (the structure is placed centred)

	-- central chamber 11x5x11 (walls tuff, floor tuff + copper trim)
	local chamber_a = vector.offset(c, -5, 0, -5)
	local chamber_b = vector.offset(c, 5, 4, 5)
	hollow_box(area, chamber_a, chamber_b, T, T)
	clear_room(area, chamber_a, chamber_b)
	-- copper pillars
	for _, o in ipairs({ { -4, -4 }, { 4, -4 }, { -4, 4 }, { 4, 4 } }) do
		for y = 0, 3 do
			area:set_node(vector.offset(c, o[1], y + 1, o[2]), { name = C })
		end
	end
	-- the trial spawner in the centre
	area:set_node(c, { name = "mcl_mobs_addon:trial_spawner" })
	area:set_node(vector.offset(c, 0, 1, 0), { name = "air" })

	-- 4 corridors (3 wide, 3 tall, 8 long, outward from the chamber's
	-- doorways) + vault rooms (5x3x5) at the far ends + lava traps
	local dirs = {
		{ 0, 0, 1 }, { 0, 0, -1 }, { 1, 0, 0 }, { -1, 0, 0 },
	}
	for _, d in ipairs(dirs) do
		local ax = d[1] ~= 0 and "x" or "z"  -- corridor axis
		for i = 6, 13 do  -- chamber spans ±5, corridor from 6 to 13
			local p = vector.offset(c, d[1] * i, 0, d[3] * i)
			if vector.equals(p, c) or vector.equals(vector.offset(p, 1, 0, 0), c)
				or vector.equals(vector.offset(p, 0, 0, 1), c) or vector.equals(vector.offset(p, -1, 0, 0), c)
				or vector.equals(vector.offset(p, 0, 0, -1), c) then
						end
			-- tunnel: air + the walls on the perpendicular axis
			area:set_node(p, { name = "air" })
			area:set_node(vector.offset(p, 0, 1, 0), { name = "air" })
			area:set_node(vector.offset(p, 0, 2, 0), { name = "air" })
			area:set_node(vector.offset(p, 0, 3, 0), { name = T })  -- ceiling
			if ax == "x" then
				area:set_node(vector.offset(p, 0, 0, 1), { name = CC })
				area:set_node(vector.offset(p, 0, 0, -1), { name = CC })
				area:set_node(vector.offset(p, 0, 1, 1), { name = CC })
				area:set_node(vector.offset(p, 0, 1, -1), { name = CC })
				area:set_node(vector.offset(p, 0, 2, 1), { name = CC })
				area:set_node(vector.offset(p, 0, 2, -1), { name = CC })
			else
				area:set_node(vector.offset(p, 1, 0, 0), { name = CC })
				area:set_node(vector.offset(p, -1, 0, 0), { name = CC })
				area:set_node(vector.offset(p, 1, 1, 0), { name = CC })
				area:set_node(vector.offset(p, -1, 1, 0), { name = CC })
				area:set_node(vector.offset(p, 1, 2, 0), { name = CC })
				area:set_node(vector.offset(p, -1, 2, 0), { name = CC })
			end
			-- lava trap in the middle of the corridor
			if i == 10 then
				area:set_node(p, { name = LAVA })
				area:set_node(vector.offset(p, 0, 1, 0), { name = "air" })
			end
		end
		-- vault room at the far end (5x3x5)
		local va = vector.offset(c, d[1] * 15, 0, d[3] * 15)
		local ra = vector.offset(va, -2, 0, -2)
		local rb = vector.offset(va, 2, 3, 2)
		hollow_box(area, ra, rb, T, T)
		clear_room(area, ra, rb)
		area:set_node(va, { name = "mcl_mobs_addon:vault" })
		-- doorway between the corridor and the room
		local door = vector.offset(va, -d[1] * 3, 0, -d[3] * 3)
		area:set_node(door, { name = "air" })
		area:set_node(vector.offset(door, 0, 1, 0), { name = "air" })
	end

	area:write_to_map()
	minetest.log("action", "[mcl_mobs_addon] trial chambers built @ " .. minetest.pos_to_string(pos))
end

if mcl_structures and mcl_structures.register_structure then
	mcl_structures.register_structure("mcl_mobs_addon:trial_chambers", {
		place_on = { "mcl_core:stone", "mcl_deepslate:deepslate", "mcl_deepslate:deepslate_with_tuff" },
		biomes = {
			"Plains", "Forest", "FlowerForest", "BirchForest", "RoofedForest",
			"Taiga", "ColdTaiga", "MegaTaiga", "Desert", "Savanna", "Swampland",
			"Jungle", "BambooJungle", "ExtremeHills", "Mesa", "IcePlains",
		},
		y_min = -45,
		y_max = -15,
		place_func = mcl_mobs_addon.build_trial_chambers,
		flags = "place_center_x, place_center_z",
	})
end

minetest.log("action", "[mcl_mobs_addon] trial chambers registered")
