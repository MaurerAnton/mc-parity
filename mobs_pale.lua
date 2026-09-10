-- ---------------------------------------------------------------------------
-- PALE GARDEN TIE-IN (MC 1.21.4): the creaking + creaking heart + resin
-- chain + eyeblossom. Model procedural (tools/gen_b3d.py creaking),
-- textures painted (tools/paint_pale.py) — no Blender, no external media.
--
-- Scope note: a full pale-garden biome needs the pale oak WOOD SET (logs,
-- leaves, planks, hanging moss overhaul) — that is a separate project.
-- Hearts + eyeblossoms scatter in the games' dark forests (RoofedForest
-- et al, runtime-filtered), where the woodland mansion already lives.
--
-- MC mechanics: the creaking is immune to damage, moves only while
-- unwatched (gaze check with line of sight), hits for 3, despawns by day,
-- and dies with its heart. Punching it sweats resin clumps out of the
-- heart. Resin clumps smelt into bricks (blocks, chiseled).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

local HEART = "mc_parity:creaking_heart"
local GAZE_DOT = 0.9  -- cos(~25 deg): watched-cone half angle
local GAZE_RANGE = 28
local HIT_RANGE = 2.4
local HIT_COOLDOWN = 1.0

if mc_parity.feature_enabled("pale") then
-- ---------------------------------------------------------------------------

-- watched by any non-spectator player with line of sight?
local function observed_by(eye)
	for _, player in ipairs(minetest.get_connected_players()) do
		if mc_parity.is_spectator and mc_parity.is_spectator(player) then
			-- spectators don't exist in MC: skip (phantom/vibration rule)
		else
			local ppos = player:get_pos()
			if ppos and vector.distance(ppos, eye) < GAZE_RANGE then
				local from = vector.offset(ppos, 0, 1.6, 0)
				local look = player:get_look_dir()
				if look and vector.dot(vector.direction(from, eye), look) > GAZE_DOT then
					local clear = minetest.line_of_sight(from, eye)
					if clear then return true end
				end
			end
		end
	end
	return false
end

local function nearest_prey(pos)
	local best, bestd
	for _, player in ipairs(minetest.get_connected_players()) do
		local pname = player:get_player_name()
		if mc_parity.is_spectator and mc_parity.is_spectator(player) then
			-- skip
		elseif minetest.is_creative_enabled(pname) then
			-- MC: the creaking ignores creative players
		else
			local ppos = player:get_pos()
			if ppos then
				local d = vector.distance(pos, ppos)
				if d < 16 and (not bestd or d < bestd) then
					best, bestd = player, d
				end
			end
		end
	end
	return best, bestd
end

mcl_mobs.register_mob("mc_parity:creaking", {
	description = S("Creaking"),
	type = "monster",
	spawn_class = "hostile",
	can_despawn = true,
	initial_properties = {
		hp_min = 500,
		hp_max = 500,
		collisionbox = {-0.4, 0.0, -0.4, 0.4, 2.6, 0.4},
	},
	xp_min = 0,
	xp_max = 0,
	-- immune to damage (MC parity): engine groups + deep hp pool.
	-- The on_punch hook below still fires for the resin drops.
	armor = { fleshy = 100, immortal = 1 },
	passive = false,
	visual = "mesh",
	mesh = "mc_parity_creaking.b3d",
	textures = {
		{"mc_parity_creaking.png"},
	},
	visual_size = {x = 1.8, y = 1.8},
	makes_footstep_sound = true,
	view_range = 16,
	walk_velocity = 2.2,
	run_velocity = 2.2,
	damage = 3,  -- MC melee (no knockback — dealt manually, see below)
	reach = 3,
	fear_height = 0,
	jump = false,
	floats = 0,
	-- MC creakings groan; ours stays silent (no fitting game sound,
	-- synthesis reserved for a later pass)
	sounds = {},
	drops = {},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 0, walk_speed = 25,
		run_start = 0, run_end = 0, run_speed = 25,
	},
	on_spawn = function(self)
		self._mca_t = 0
		self._mca_hit_cd = 0
	end,
	-- full custom control (allay pattern: false skips the framework step)
	do_custom = function(self, dtime)
		self._mca_t = (self._mca_t or 0) + dtime
		if self._mca_t < 0.4 then return false end
		self._mca_t = 0
		local pos = self.object:get_pos()
		if not pos then return false end
		-- heart gone -> crumble (MC parity); day -> despawn
		if not self._mca_heart
				or minetest.get_node(self._mca_heart).name ~= HEART then
			if self.object:is_valid() then self.object:remove() end
			return false
		end
		if mcl_util.is_daytime() then
			if self.object:is_valid() then self.object:remove() end
			return false
		end
		local eye = vector.offset(pos, 0, 2.2, 0)
		if observed_by(eye) then
			-- watched: freeze (MC parity)
			self.object:set_velocity({x = 0, y = self.object:get_velocity().y, z = 0})
			return false
		end
		local prey, dist = nearest_prey(pos)
		if prey and dist then
			local ppos = prey:get_pos()
			if dist < HIT_RANGE then
				self._mca_hit_cd = (self._mca_hit_cd or 0) - 0.4
				if self._mca_hit_cd <= 0 then
					self._mca_hit_cd = HIT_COOLDOWN
					prey:punch(self.object, 1.0, {
						full_punch_interval = 1.0,
						damage_groups = { fleshy = 3 },
					})
				end
				self.object:set_velocity({x = 0, y = self.object:get_velocity().y, z = 0})
			else
				local dir = vector.direction(pos, ppos)
				local sp = 2.2
				self.object:set_velocity({x = dir.x * sp, y = self.object:get_velocity().y, z = dir.z * sp})
				self.object:set_yaw(math.atan2(-dir.x, dir.z))
			end
		else
			self.object:set_velocity({x = 0, y = self.object:get_velocity().y, z = 0})
		end
		return false
	end,
	-- punching never wounds (armor) but sweats resin out of the heart
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		local heart = self._mca_heart
		local at = heart and minetest.get_node(heart).name == HEART
			and heart or self.object:get_pos()
		if at then
			minetest.add_item(vector.offset(at, 0, 1, 0), "mc_parity:resin_clump")
		end
	end,
})

mc_parity.register_egg("mc_parity:creaking", S("Creaking"), "#a8a8a0", "#e87a1c", 0)
-- no natural spawn (MC: heart-only + egg — like our skeleton-horse trap)
mc_parity.mcln_base_hp("mc_parity:creaking", 500, 500)

-- creaking heart: spawns its creaking on dark nights, dies -> creaking dies
minetest.register_node(HEART, {
	description = S("Creaking Heart"),
	tiles = {"mc_parity_creaking_heart.png"},
	groups = {choppy = 2, oddly_breakable_by_hand = 1},
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_tt_help = S("Spawns a creaking on dark nights"),
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(5)
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(5)
	end,
	on_timer = function(pos)
		if not mcl_util.is_daytime() then
			local found = false
			for _, o in ipairs(minetest.get_objects_inside_radius(pos, 16)) do
				local le = o:get_luaentity()
				if le and le.name == "mc_parity:creaking" then
					found = true
					break
				end
			end
			if not found then
				local obj = minetest.add_entity(vector.offset(pos, 0, 1, 0), "mc_parity:creaking")
				if obj then
					local le = obj:get_luaentity()
					if le then le._mca_heart = vector.new(pos) end
				end
			end
		end
		minetest.get_node_timer(pos):start(5)
		return false
	end,
})

-- resin chain (MC 1.21.4): clump -> smelt -> brick -> blocks
minetest.register_craftitem("mc_parity:resin_clump", {
	description = S("Resin Clump"),
	inventory_image = "mc_parity_resin_clump.png",
	groups = {craftitem = 1},
	stack_max = 64,
})
minetest.register_craftitem("mc_parity:resin_brick", {
	description = S("Resin Brick"),
	inventory_image = "mc_parity_resin_brick.png",
	groups = {craftitem = 1},
	stack_max = 64,
})
minetest.register_craft({
	type = "cooking",
	output = "mc_parity:resin_brick",
	recipe = "mc_parity:resin_clump",
})
for _, v in ipairs({
	{ "resin_bricks", "Resin Bricks", "mc_parity_resin_bricks.png" },
	{ "chiseled_resin_bricks", "Chiseled Resin Bricks", "mc_parity_chiseled_resin_bricks.png" },
}) do
	minetest.register_node("mc_parity:" .. v[1], {
		description = S(v[2]),
		tiles = { "mc_parity_" .. v[1] .. ".png" },
		groups = { pickaxe = 1, dig_by_pickaxe = 1, deco_block = 1 },
		sounds = mcl_sounds.node_sound_stone_defaults(),
	})
end
minetest.register_craft({
	output = "mc_parity:resin_bricks",
	recipe = {
		{ "mc_parity:resin_brick", "mc_parity:resin_brick" },
		{ "mc_parity:resin_brick", "mc_parity:resin_brick" },
	},
})
-- no slabs in scope: chiseled from two stacked brick blocks (documented)
minetest.register_craft({
	output = "mc_parity:chiseled_resin_bricks",
	recipe = {
		{ "mc_parity:resin_bricks" },
		{ "mc_parity:resin_bricks" },
	},
})

-- block of resin (MC 1.21.4; 9 clumps <-> block)
minetest.register_node("mc_parity:block_of_resin", {
	description = S("Block of Resin"),
	tiles = { "mc_parity_resin_block.png" },
	groups = { dig_immediate = 3, handy = 1 },
	sounds = mcl_sounds.node_sound_wood_defaults(),
	_mcl_hardness = 0,
})
minetest.register_craft({
	output = "mc_parity:block_of_resin",
	recipe = {
		{ "mc_parity:resin_clump", "mc_parity:resin_clump", "mc_parity:resin_clump" },
		{ "mc_parity:resin_clump", "mc_parity:resin_clump", "mc_parity:resin_clump" },
		{ "mc_parity:resin_clump", "mc_parity:resin_clump", "mc_parity:resin_clump" },
	},
})
minetest.register_craft({
	output = "mc_parity:resin_clump 9",
	recipe = { { "mc_parity:block_of_resin" } },
})

-- eyeblossom: closed by day, open by night (MC 1.21.4)
minetest.register_node("mc_parity:eyeblossom_closed", {
	description = S("Closed Eyeblossom"),
	drawtype = "plantlike",
	tiles = {"mc_parity_eyeblossom_closed.png"},
	inventory_image = "mc_parity_eyeblossom_closed.png",
	wield_image = "mc_parity_eyeblossom_closed.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flora = 1, attached_node = 1},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})
minetest.register_node("mc_parity:eyeblossom_open", {
	description = S("Open Eyeblossom"),
	drawtype = "plantlike",
	tiles = {"mc_parity_eyeblossom_open.png"},
	inventory_image = "mc_parity_eyeblossom_open.png",
	wield_image = "mc_parity_eyeblossom_open.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, flora = 1, attached_node = 1, not_in_creative_inventory = 1},
	sounds = mcl_sounds.node_sound_leaves_defaults(),
})
minetest.register_abm({
	label = "mc_parity eyeblossom day/night",
	nodenames = {"mc_parity:eyeblossom_closed", "mc_parity:eyeblossom_open"},
	interval = 20,
	chance = 1,
	action = function(pos, node)
		local day = mcl_util.is_daytime()
		if day and node.name == "mc_parity:eyeblossom_open" then
			minetest.set_node(pos, {name = "mc_parity:eyeblossom_closed"})
		elseif not day and node.name == "mc_parity:eyeblossom_closed" then
			minetest.set_node(pos, {name = "mc_parity:eyeblossom_open"})
		end
	end,
})

-- scatter in the dark forests both games share names with (VL: RoofedForest;
-- the mansion code hit missing-biome errors on Mineclonia, so filter at load).
-- PaleGarden (pale_oak.lua, loaded first) is included when present.
do
	local want = { RoofedForest = true, RoofedForestM = true,
		DarkForest = true, DarkOakForest = true, PaleGarden = true }
	local biomes = {}
	for name in pairs(minetest.registered_biomes) do
		if want[name] then table.insert(biomes, name) end
	end
	local place_on = { "mcl_core:dirt_with_grass" }
	if minetest.registered_nodes["mc_parity:pale_oak_moss"] then
		table.insert(place_on, "mc_parity:pale_oak_moss")
	end
	if #biomes > 0 then
		minetest.register_decoration({
			name = "mc_parity:pale_heart_scatter",
			deco_type = "simple",
			place_on = place_on,
			sidelen = 16,
			fill_ratio = 0.0002,
			biomes = biomes,
			decoration = HEART,
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
		minetest.register_decoration({
			name = "mc_parity:pale_eyeblossom_scatter",
			deco_type = "simple",
			place_on = place_on,
			sidelen = 16,
			fill_ratio = 0.004,
			biomes = biomes,
			decoration = "mc_parity:eyeblossom_closed",
			flags = "place_center_x, place_center_z",
			rotation = "random",
		})
		minetest.log("action", "[mc_parity] pale scatter in: " .. table.concat(biomes, ","))
	end
end

minetest.log("action", "[mc_parity] pale garden tie-in registered")

-- ---------------------------------------------------------------------------
end
