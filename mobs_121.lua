-- MC 1.20.5/1.21 content — unique (verified: not in VoxeLibre, Mineclonia,
-- Bettercraft, or ContentDB):
--   * ARMADILLO: passive savanna mob; ROLLS UP when a player or hostile
--     mob comes within 3 nodes (armor 100 = near-invulnerable, can't move;
--     unrolls after ~4s without threat); drops armadillo scute every
--     5-10 minutes (MC 1.21.2+). Cuboid model (tools/gen_b3d.py) + painted
--     textures (tools/paint_121.py) — no external media needed.
--   * WOLF VARIANTS (MC 1.20.5): the game's wolf gets a biome-based
--     texture at spawn (Bettercraft's textures, GPLv3; their biome names
--     don't exist in our games — remapped to the games' names).
--   * WOLF ARMOR (MC 1.21): crafted from 6 armadillo scute; right-click a
--     tamed wolf to equip (texture overlay + ~60% damage reduction; drops
--     on the wolf's death).

local S = minetest.get_translator("mcl_mobs_addon")

-- ---------------------------------------------------------------------------
-- ARMADILLO
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mcl_mobs_addon:armadillo", {
	description = S("Armadillo"),
	type = "animal",
	spawn_class = "passive",
	passive = true,
	initial_properties = {
		hp_min = 12,
		hp_max = 12,
		collisionbox = { -0.5, 0, -0.5, 0.5, 0.6, 0.5 },
	},
	xp_min = 1,
	xp_max = 3,
	visual = "mesh",
	mesh = "mcl_mobs_addon_armadillo.b3d",
	textures = { "mcl_mobs_addon_armadillo.png" },
	visual_size = { x = 0.85, y = 0.85 },
	makes_footstep_sound = true,
	walk_velocity = 0.8,
	run_velocity = 1.2,
	pace_bonus = 0.2,
	view_range = 16,
	stepheight = 0.6,
	jump = false,
	fear_height = 2,
	armor = 0,
	animation = {
		stand_start = 0, stand_end = 0, stand_speed = 10,
		walk_start = 0, walk_end = 0, speed_normal = 10,
	},
	do_custom = function(self, dtime)
		-- armadillo scute every 5-10 minutes (MC 1.21.2+)
		self._mca_scute_t = (self._mca_scute_t or 300 + math.random(0, 300)) - dtime
		if self._mca_scute_t <= 0 then
			self._mca_scute_t = 300 + math.random(0, 300)
			minetest.add_item(self.object:get_pos(), "mcl_mobs_addon:armadillo_scute")
		end

		-- roll / unroll (MC: rolls when a player or hostile mob runs close)
		local pos = self.object:get_pos()
		local function threat_near()
			if not pos then return false end
			for _, o in ipairs(minetest.get_objects_inside_radius(pos, 3)) do
				if o:is_player() then
					return true
				end
				local le = o:get_luaentity()
				if le then
					if le.name and le.name:find("^mobs_mc:") and not le.passive then
						return true
					end
					if le.is_mob and not le.passive then
						return true
					end
				end
			end
			return false
		end

		if not self._mca_rolled then
			if threat_near() then
				self._mca_rolled = true
				self._mca_roll_t = 4
				self.armor = 100  -- near-invulnerable while rolled
				self.object:set_properties({ mesh = "mcl_mobs_addon_armadillo_rolled.b3d" })
			end
		else
			self._mca_roll_t = (self._mca_roll_t or 4) - dtime
			if self._mca_roll_t <= 0 then
				if threat_near() then
					self._mca_roll_t = 4
				else
					self._mca_rolled = nil
					self.armor = 0
					self.object:set_properties({ mesh = "mcl_mobs_addon_armadillo.b3d" })
				end
			end
			return false  -- cannot move while rolled
		end
		return true
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:armadillo", S("Armadillo"), "#8c6b4a", "#d8c9a8", 0)
mcl_mobs_addon.register_spawn("mcl_mobs_addon:armadillo",
	{ "Savanna", "SavannaM" },
	{ "Savanna", "SavannaM" }, 40)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:armadillo", 12, 12)

-- ---------------------------------------------------------------------------
-- ARMADILLO SCUTE + WOLF ARMOR
-- ---------------------------------------------------------------------------
minetest.register_craftitem("mcl_mobs_addon:armadillo_scute", {
	description = S("Armadillo Scute"),
	inventory_image = "mcl_mobs_addon_armadillo_scute.png",
	groups = { craftitem = 1 },
	stack_max = 64,
})

minetest.register_craftitem("mcl_mobs_addon:wolf_armor", {
	description = S("Wolf Armor"),
	inventory_image = "mcl_mobs_addon_wolf_armor.png",
	groups = { craftitem = 1 },
	stack_max = 1,
	_tt_help = S("Right-click a tamed wolf to equip"),
})

minetest.register_craft({
	output = "mcl_mobs_addon:wolf_armor",
	recipe = {
		{ "mcl_mobs_addon:armadillo_scute", "mcl_mobs_addon:armadillo_scute" },
		{ "mcl_mobs_addon:armadillo_scute", "mcl_mobs_addon:armadillo_scute" },
		{ "mcl_mobs_addon:armadillo_scute", "mcl_mobs_addon:armadillo_scute" },
	},
})

-- ---------------------------------------------------------------------------
-- WOLF VARIANTS + WOLF ARMOR (runtime patch of the game's mobs_mc:wolf)
-- ---------------------------------------------------------------------------
-- MC 1.20.5 biome map, adapted to the games' actual biome names:
-- (VL and Mineclonia both use the classic names: ColdTaiga, MegaTaiga...
-- Mineclonia additionally has Grove.)
local WOLF_VARIANTS = {
	pale = { tex = "mcl_mobs_addon_wolf.png", biomes = nil },          -- default (taiga)
	spotted = { tex = "mcl_mobs_addon_wolf_spotted.png",
		biomes = { "Savanna", "SavannaM", "SavannaPlateau", "SavannaPlateauM" } },
	snowy = { tex = "mcl_mobs_addon_wolf_snowy.png", biomes = { "Grove" } },
	black = { tex = "mcl_mobs_addon_wolf_black.png",
		biomes = { "MegaTaiga", "MegaSpruceTaiga" } },
	ashen = { tex = "mcl_mobs_addon_wolf_ashen.png", biomes = { "ColdTaiga" } },
	rusty = { tex = "mcl_mobs_addon_wolf_rusty.png",
		biomes = { "Jungle", "JungleM", "BambooJungle", "BambooJungleM" } },
	woods = { tex = "mcl_mobs_addon_wolf_woods.png", biomes = { "Forest" } },
	chestnut = { tex = "mcl_mobs_addon_wolf_chestnut.png",
		biomes = { "MegaSpruceTaiga" } },
	striped = { tex = "mcl_mobs_addon_wolf_striped.png",
		biomes = { "Mesa", "MesaM", "MesaBryce", "MesaPlateauF", "MesaPlateauFM" } },
}

local function wolf_variant_tex(pos)
	local bd = pos and minetest.get_biome_data(pos)
	local bname = bd and minetest.get_biome_name(bd.biome) or ""
	for _, v in pairs(WOLF_VARIANTS) do
		if v.biomes then
			for _, b in ipairs(v.biomes) do
				if b == bname then
					return v.tex
				end
			end
		end
	end
	return WOLF_VARIANTS.pale.tex
end

local WOLF_ARMOR_TEX = "mcl_mobs_addon_wolf_armor.png"

minetest.register_on_mods_loaded(function()
	-- patch the ENTITY class (the framework builds a whitelisted final_def
	-- at registration; registered_mobs holds the original def — patching
	-- the live entity table is what actually takes effect at runtime)
	local cls = minetest.registered_entities and minetest.registered_entities["mobs_mc:wolf"]
	if not cls then
		minetest.log("warning", "[mcl_mobs_addon] mobs_mc:wolf entity not found — variants/armor skipped")
		return
	end

	-- variant texture at spawn (wild wolves; tame/angry use the game's own)
	local orig_spawn = cls.on_spawn
	cls.on_spawn = function(self)
		if orig_spawn then orig_spawn(self) end
		if not self._mca_variant then
			self._mca_variant = wolf_variant_tex(self.object:get_pos())
			if self.base_texture then
				self.base_texture[1] = self._mca_variant
				self.object:set_properties({ textures = self.base_texture })
			end
		end
	end

	-- wolf armor: right-click a tamed wolf with the armor to equip
	local orig_rightclick = cls.on_rightclick
	cls.on_rightclick = function(self, clicker, itemstack, pointed_thing)
		if clicker and clicker:is_player() and self.tamed then
			local wi = clicker:get_wielded_item()
			if wi:get_name() == "mcl_mobs_addon:wolf_armor" then
				self._mca_wolf_armor = true
				if not minetest.settings:get_bool("creative_mode") then
					wi:take_item()
					clicker:set_wielded_item(wi)
				end
				-- plate overlay on the current fur
				if self.base_texture then
					self.base_texture[1] = (self._mca_variant or self.base_texture[1])
						.. "^" .. WOLF_ARMOR_TEX
					self.object:set_properties({ textures = self.base_texture })
				end
				return
			end
		end
		if orig_rightclick then
			orig_rightclick(self, clicker, itemstack, pointed_thing)
		end
		-- MC 1.20.5: a tamed variant wolf keeps its fur + collar
		-- (the game's tame handler resets to the default wolf_tame)
		if self.tamed and self._mca_variant and self.base_texture
				and self.base_texture[1] and not self._mca_tamed
				and self.base_texture[1]:find("mobs_mc_wolf_tame%.png") then
			self._mca_tamed = true
			self.base_texture[1] = self._mca_variant:gsub("%.png$", "_tame.png")
			self.object:set_properties({ textures = self.base_texture })
		end
	end

	-- damage reduction while armored (~60%)
	local orig_punch = cls.on_punch
	cls.on_punch = function(self, puncher, tflp, tool_capabilities, dir, damage)
		if orig_punch then
			orig_punch(self, puncher, tflp, tool_capabilities, dir, damage)
		end
		if self._mca_wolf_armor and damage and damage > 0 then
			local maxhp = self.initial_properties and self.initial_properties.hp_max or 20
			self.object:set_hp(math.min(self.object:get_hp() + damage * 0.6, maxhp))
		end
	end

	-- armor drops on the wolf's death
	local orig_die = cls.on_die
	cls.on_die = function(self, pos)
		if orig_die then orig_die(self, pos) end
		if self._mca_wolf_armor then
			minetest.add_item(pos, "mcl_mobs_addon:wolf_armor")
		end
	end

	minetest.log("action", "[mcl_mobs_addon] wolf patched: biome variants + armor")
end)

minetest.log("action", "[mcl_mobs_addon] armadillo + wolf variants + wolf armor registered")
