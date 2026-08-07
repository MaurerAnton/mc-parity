-- ---------------------------------------------------------------------------
-- BEE (MC 1.15) — the LAST missing vanilla mob in the whole ecosystem.
-- The games ship the full honey machinery (mcl_beehives + mcl_honey: nest /
-- beehive nodes with 5 honey levels, bottle + shears harvesting, honey
-- bottle / honeycomb / honey block / honeycomb block) but NO bee entity.
-- We add the bee: it pollinates flowers, fills nests, stings when provoked.
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

local FLOWERS = {
	"mcl_flowers:dandelion", "mcl_flowers:poppy", "mcl_flowers:blue_orchid",
	"mcl_flowers:allium", "mcl_flowers:azure_bluet", "mcl_flowers:oxeye_daisy",
	"mcl_flowers:cornflower", "mcl_flowers:lily_of_the_valley",
	"mcl_flowers:tulip_red", "mcl_flowers:tulip_orange",
	"mcl_flowers:tulip_white", "mcl_flowers:tulip_pink",
	"mcl_flowers:sunflower", "mcl_flowers:lilac", "mcl_flowers:rose_bush",
	"mcl_flowers:peony",
}
-- the flower set exists in both games (the classic 1.7-1.14 flowers)

-- crops the bee grows when pollinated: stage node -> next stage node
local CROPS = {}
for _, crop in ipairs({ "wheat", "carrot", "potato" }) do
	for i = 1, 6 do
		CROPS["mcl_farming:" .. crop .. "_" .. i] = "mcl_farming:" .. crop .. "_" .. (i + 1)
	end
end
for i = 0, 6 do
	CROPS["mcl_farming:beetroot_" .. i] = "mcl_farming:beetroot_" .. (i + 1)
end

local NESTS = { "mcl_beehives:bee_nest", "mcl_beehives:beehive" }

local function find_nearby(pos, names, radius)
	local objs = minetest.find_nodes_in_area(
		vector.subtract(pos, radius), vector.add(pos, radius), names)
	return objs and objs[1] or nil
end

-- advance a nest's honey level (bee_nest -> bee_nest_1 -> ... -> bee_nest_5)
local function fill_nest(pos, node)
	if not node or not node.name then return false end
	local prefix, state = node.name:match("^(mcl_beehives:bee[n_]?[a-z_]*_)(%d*)$")
	-- node names: bee_nest / bee_nest_1..5 / beehive / beehive_1..5
	if node.name == "mcl_beehives:bee_nest" or node.name == "mcl_beehives:beehive" then
		state = 0
	else
		state = tonumber(state) or 0
	end
	if state >= 5 then return true end  -- full — the bee keeps visiting
	local base = node.name:match("^(mcl_beehives:[a-z_]+)")
	minetest.set_node(pos, { name = base .. "_" .. (state + 1) })
	return true
end

local BEE = {
	description = S("Bee"),
	type = "animal",
	spawn_class = "passive",
	attack_player = false,
	hp_min = 10,
	hp_max = 10,
	collisionbox = { -0.3, 0.0, -0.3, 0.3, 0.7, 0.3 },
	visual = "mesh",
	mesh = "mc_parity_bee.b3d",
	textures = {
		"mc_parity_bee.png^mc_parity_bee_wings.png",
	},
	light_weight = 2,
	visual_size = { x = 0.7, y = 0.7 },
	fall_speed = -2.25,
	fly = true,
	fear_height = 0,
	walk_velocity = 3,
	run_velocity = 4,
	armor = { fleshy = 100 },
	damage = 2,
	sounds = {},  -- no bee sounds in either game (TODO: CC0 synthesis)

	on_spawn = function(self)
		self._bee_pollinated = nil   -- timestamp when pollen was picked up
		self._bee_cooldown = 0       -- nest-visit cooldown
	end,

	-- the framework's fly=true moves the bee around; here we do the
	-- pollination / honey / crop logic on a timer
	do_custom = function(self, dtime)
		self._bee_t = (self._bee_t or 0) + dtime
		if self._bee_t < 2.5 then return end
		self._bee_t = 0
		local pos = self.object:get_pos()
		if not pos then return end
		local node = minetest.get_node(pos)
		local in_air = node.name == "air" or not minetest.registered_nodes[node.name]

		if self._bee_cooldown > 0 then self._bee_cooldown = self._bee_cooldown - 2.5 end

		-- 1) collect pollen: near a flower
		if not self._bee_pollinated then
			local fl = find_nearby(pos, FLOWERS, 8)
			if fl then
				self._bee_pollinated = os.time()
				return
			end
		end

		-- 2) pollinated: grow crops nearby, then head to a nest
		if self._bee_pollinated then
			if os.time() - self._bee_pollinated > 30 then
				self._bee_pollinated = nil  -- pollen expires
				return
			end
			local crop = find_nearby(pos, CROPS, 4)
			if crop then
				local cnode = minetest.get_node(crop)
				if CROPS[cnode.name] then
					minetest.set_node(crop, { name = CROPS[cnode.name] })
				end
			end
			-- visit a nest (honey +1 per visit, cooldown)
			if self._bee_cooldown <= 0 then
				local nest = find_nearby(pos, NESTS, 12)
				if nest then
					if fill_nest(nest, minetest.get_node(nest)) then
						self._bee_pollinated = nil
						self._bee_cooldown = 30
						return
					end
				end
			end
		end
	end,

	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir)
		-- MC: bees swarm and sting when their nest is hit or they are hit
		if puncher and puncher:is_player() then
			self.angry = 1
		end
	end,

	on_attack = function(self, target)
		-- the sting: poison + the bee dies
		if target and target:is_player() then
			mcl_potions.give_effect_by_level("poison", target, 1, 8)
		end
		mcl_util.deal_damage(self.object, 10, { type = "piercing" })
	end,
}

mcl_mobs.register_mob("mc_parity:bee", BEE)
mcl_mobs.register_egg("mc_parity:bee", S("Bee"), "#f6b201", "#5b5b5b", 0)
mc_parity.register_spawn("mc_parity:bee",
	{ "FlowerForest", "Plains", "SunflowerPlains" },
	{ "FlowerForest", "Plains", "SunflowerPlains" }, 60)
mc_parity.mcln_base_hp("mc_parity:bee", 10, 10)

minetest.log("action", "[mc_parity] bee registered")
