-- ---------------------------------------------------------------------------
-- TADPOLE + FROGSPAWN + BUCKET (MC 1.19) — the frog breeding chain.
-- MC loop: feed frogs slimeballs -> frogspawn on water -> 2-4 tadpoles ->
-- tadpoles grow into frogs after ~20 min; tadpoles ride in water buckets.
-- Model: procedural cuboid (tools/gen_b3d.py tadpole); textures painted
-- (tools/paint_tadpole.py). No Blender, no external media — like the bee.
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mc_parity")

local WATER = "mcl_core:water_source"  -- both games (checked at runtime)
local SLIMEBALL = "mcl_mobitems:slimeball"
local EMPTY_BUCKET = "mcl_buckets:bucket_empty"
local WATER_BUCKET = "mcl_buckets:bucket_water"
local RIVER_BUCKET = "mcl_buckets:bucket_river_water"

local GROW_S = 1200  -- tadpole -> frog after ~20 min (MC parity)
local BREED_COOLDOWN_S = 300

if mc_parity.feature_enabled("tadpole") then
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mc_parity:tadpole", {
	description = S("Tadpole"),
	type = "animal",
	spawn_class = "passive",
	can_despawn = true,
	initial_properties = {
		hp_min = 6,
		hp_max = 6,
		collisionbox = {-0.15, 0.0, -0.15, 0.15, 0.25, 0.15},
	},
	xp_min = 1,
	xp_max = 3,
	passive = true,
	visual = "mesh",
	mesh = "mc_parity_tadpole.b3d",
	textures = {
		{"mc_parity_tadpole.png"},
	},
	visual_size = {x = 0.5, y = 0.5},
	makes_footstep_sound = false,
	view_range = 8,
	walk_velocity = 1.2,
	run_velocity = 2.0,
	damage = 0,
	jump = false,
	floats = 0,
	-- fish movement (same fields as the ported pufferfish, mobs_port.lua)
	swims = true,
	pace_height = 1.0,
	breathes_in_water = true,
	-- MC tadpoles are silent
	sounds = {},
	drops = {},
	on_spawn = function(self)
		self._mca_born = os.time()
		self._mca_t = 0
	end,
	do_custom = function(self, dtime)
		-- grow into a frog after ~20 min (MC parity)
		self._mca_t = (self._mca_t or 0) + dtime
		if self._mca_t < 10 then return true end
		self._mca_t = 0
		if not self._mca_born then self._mca_born = os.time() end
		if os.time() - self._mca_born >= GROW_S then
			local pos = self.object:get_pos()
			if pos and minetest.registered_entities["mc_parity:frog"] then
				minetest.add_entity(pos, "mc_parity:frog")
			end
			if self.object:is_valid() then self.object:remove() end
			return false
		end
		return true
	end,
	on_rightclick = function(self, clicker)
		-- scoop up with a water bucket (MC parity; pufferfish pattern)
		if not (clicker and clicker:is_player()) then return end
		local bn = clicker:get_wielded_item():get_name()
		if bn == WATER_BUCKET or bn == RIVER_BUCKET then
			if self.safe_remove then self.safe_remove(self)
			elseif self.object:is_valid() then self.object:remove() end
			clicker:set_wielded_item("mc_parity:bucket_tadpole")
			if awards and awards.unlock then
				pcall(awards.unlock, clicker:get_player_name(), "mcl:tacticalFishing")
			end
		end
	end,
})

mc_parity.register_egg("mc_parity:tadpole", S("Tadpole"), "#6b5b3e", "#2e2a1e", 0)
mc_parity.register_spawn("mc_parity:tadpole",
	{"Swampland", "MangroveSwamp"},
	{"Swampland", "MangroveSwamp"}, 40)
mc_parity.mcln_base_hp("mc_parity:tadpole", 6, 6)

-- frogspawn: floats on water, hatches 2-4 tadpoles after 5-10 min
-- (turtle-egg pattern: node timer + direct add_entity, mobs_import.lua)
minetest.register_node("mc_parity:frogspawn", {
	description = S("Frogspawn"),
	drawtype = "plantlike",
	tiles = {"mc_parity_frogspawn.png"},
	inventory_image = "mc_parity_frogspawn.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	groups = {snappy = 3, deco_block = 1, oddly_breakable_by_hand = 1},
	sounds = mcl_sounds.node_sound_defaults(),
	_tt_help = S("Hatches into tadpoles"),
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(300 + math.random(0, 300))
	end,
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		minetest.get_node_timer(pos):start(300 + math.random(0, 300))
	end,
	on_timer = function(pos)
		-- needs adjacent water (MC: frogspawn floats) — else retry later
		local water = minetest.find_node_near(pos, 1, {WATER})
		if not water then
			minetest.get_node_timer(pos):start(120)
			return false
		end
		minetest.remove_node(pos)
		for _ = 1, 2 + math.random(0, 2) do
			local p = vector.offset(water, math.random(-1, 1), 0, math.random(-1, 1))
			if minetest.get_node(p).name ~= WATER then p = water end
			minetest.add_entity(p, "mc_parity:tadpole")
		end
		return false
	end,
})

-- bucket of tadpole (MC parity; pufferfish-bucket pattern, mobs_port.lua)
minetest.register_craftitem("mc_parity:bucket_tadpole", {
	description = S("Bucket of Tadpole"),
	inventory_image = "mc_parity_bucket_tadpole.png",
	groups = {craftitem = 1},
	stack_max = 1,
	liquids_pointable = true,
	on_place = function(itemstack, placer, pointed_thing)
		if pointed_thing and pointed_thing.type == "node" then
			local node = minetest.get_node(pointed_thing.under)
			local above = minetest.get_node(pointed_thing.above)
			if node and node.name == WATER and above and above.name == "air" then
				minetest.add_entity(pointed_thing.above, "mc_parity:tadpole")
				if minetest.registered_items[EMPTY_BUCKET] then
					return ItemStack(EMPTY_BUCKET)
				end
				return ItemStack("")
			end
		end
		return itemstack
	end,
})

-- breeding: feed a frog a slimeball -> frogspawn on nearby water surface.
-- Runtime patch of the live entity class (wolf-variant pattern, mobs_121.lua:
-- patch minetest.registered_entities, never mcl_mobs.registered_mobs).
do
	local frog_ent = minetest.registered_entities["mc_parity:frog"]
	if frog_ent and minetest.registered_items[SLIMEBALL] then
		local orig_rc = frog_ent.on_rightclick
		frog_ent.on_rightclick = function(self, clicker)
			if clicker and clicker:is_player()
					and not (self._mca_bred and os.time() - self._mca_bred < BREED_COOLDOWN_S) then
				local wielded = clicker:get_wielded_item()
				if wielded:get_name() == SLIMEBALL then
					local cpos = self.object:get_pos()
					local spot
					if cpos then
						local bestd
						for dx = -8, 8 do for dy = -3, 2 do for dz = -8, 8 do
							local p = vector.offset(cpos, dx, dy, dz)
							if minetest.get_node(p).name == WATER
									and minetest.get_node(vector.offset(p, 0, 1, 0)).name == "air" then
								local d = vector.distance(cpos, p)
								if not bestd or d < bestd then
									spot, bestd = vector.offset(p, 0, 1, 0), d
								end
							end
						end end end
					end
					if spot then
						if not minetest.is_creative_enabled(clicker:get_player_name()) then
							wielded:take_item()
							clicker:set_wielded_item(wielded)
						end
						minetest.set_node(spot, {name = "mc_parity:frogspawn"})
						self._mca_bred = os.time()
						return
					end
					-- no water nearby: keep the slimeball, fall through
				end
			end
			if orig_rc then return orig_rc(self, clicker) end
		end
	end
end

minetest.log("action", "[mc_parity] tadpole chain registered")

-- ---------------------------------------------------------------------------
end
