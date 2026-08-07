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
if mcl_mobs_addon.feature_enabled("armadillo") then
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
end
if mcl_mobs_addon.feature_enabled("wolf_armor") then
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
end
if mcl_mobs_addon.feature_enabled("wolf_variants") then
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

end
-- ---------------------------------------------------------------------------
if mcl_mobs_addon.feature_enabled("bogged") then
-- shoots poison arrows, drops slimeballs. Textures from Bettercraft (GPLv3)
-- on the game's skeleton model (no new model needed).
-- ---------------------------------------------------------------------------
minetest.register_craftitem("mcl_mobs_addon:breeze_rod", {
	description = S("Breeze Rod"),
	inventory_image = "mcl_mobs_addon_breeze_rod.png",
	groups = { craftitem = 1 },
	stack_max = 64,
})

-- poison arrow (the framework's "shoot" attack fires registered arrows)
mcl_mobs.register_arrow("mcl_mobs_addon:poison_arrow", {
	visual = "sprite",
	visual_size = { x = 0.4, y = 0.4 },
	textures = { "mcl_bows_arrow.png^[colorize:#4a9e4a:180" },
	velocity = 18,
	expire = 2,
	hit_player = function(self, player)
		if mcl_mobs.get_arrow_damage_func then
			mcl_mobs.get_arrow_damage_func(4)(self, player)
		end
		if mcl_potions and mcl_potions.give_effect_by_level then
			pcall(mcl_potions.give_effect_by_level, "poison", player, 1, 8)
		end
	end,
	hit_mob = mcl_mobs.get_arrow_damage_func and mcl_mobs.get_arrow_damage_func(4),
	hit_node = function() end,
})

local bogged = {
	description = S("Bogged"),
	type = "monster",
	spawn_class = "hostile",
	passive = false,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		breath_max = -1,
		collisionbox = { -0.3, -0.01, -0.3, 0.3, 1.98, 0.3 },
	},
	xp_min = 6,
	xp_max = 6,
	armor = { undead = 100, fleshy = 100 },
	pathfinding = 1,
	group_attack = true,
	head_swivel = "Head_Control",
	head_eye_height = 1.6,
	head_bone_position = vector.new(0, 2.38, 0),
	curiosity = 6,
	visual = "mesh",
	mesh = "mobs_mc_skeleton.b3d",  -- the game's skeleton model (media namespace)
	shooter_avoid_enemy = true,
	strafes = true,
	textures = {
		{
			"mobs_mc_empty.png",  -- armor
			"mcl_mobs_addon_bogged.png^mcl_mobs_addon_bogged_overlay.png",  -- mossy body
			"mcl_bows_bow_0.png",  -- wielded bow
		},
	},
	sounds = {
		random = "mobs_mc_skeleton_random",
		death = "mobs_mc_skeleton_death",
		damage = "mobs_mc_skeleton_hurt",
		distance = 16,
	},
	walk_velocity = 1.2,
	run_velocity = 2.0,
	-- NO ignited_by_sunlight: bogged do not burn in daylight (MC parity)
	floats = 0,
	view_range = 16,
	fear_height = 4,
	attack_type = "shoot",
	arrow = "mcl_mobs_addon:poison_arrow",
	shoot_interval = 2,
	shoot_offset = 1.5,
	dogshoot_switch = 1,
	dogshoot_count_max = 1.8,
	harmed_by_heal = true,
	animation = {
		stand_start = 0, stand_end = 40, stand_speed = 10,
		walk_start = 40, walk_end = 75, speed_normal = 15,
		run_start = 40, run_end = 75, speed_run = 20,
		punch_start = 75, punch_end = 90, punch_speed = 15,
		shoot_start = 75, shoot_end = 90,
		die_start = 160, die_end = 170, die_speed = 15, die_loop = false,
	},
	drops = {
		{ name = "mcl_mobitems:slimeball", chance = 1, min = 0, max = 1 },
		{ name = "mcl_mobitems:bone", chance = 2, min = 0, max = 2 },
	},
}

mcl_mobs.register_mob("mcl_mobs_addon:bogged", bogged)
mcl_mobs_addon.register_egg("mcl_mobs_addon:bogged", S("Bogged"), "#4a9e4a", "#7a5c3a", 0)
mcl_mobs_addon.register_spawn("mcl_mobs_addon:bogged",
	{ "Swampland", "MangroveSwamp", "Swampland_shore" },
	{ "Swampland", "MangroveSwamp", "Swampland_shore" }, 40)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:bogged", 20, 20)

-- ---------------------------------------------------------------------------
end
if mcl_mobs_addon.feature_enabled("breeze") then
-- charges (a 3-ray fan that knocks targets back hard). Cuboid model via
-- tools/gen_b3d.py + painted texture. MC spawns it only in trial chambers
-- (no such structure here yet) — spawn egg only for now.
-- ---------------------------------------------------------------------------
mcl_mobs.register_mob("mcl_mobs_addon:breeze", {
	description = S("Breeze"),
	type = "monster",
	spawn_class = "hostile",
	passive = false,
	initial_properties = {
		hp_min = 30,
		hp_max = 30,
		breath_max = -1,
		collisionbox = { -0.6, 0, -0.6, 0.6, 1.4, 0.6 },
	},
	xp_min = 10,
	xp_max = 10,
	armor = 20,
	pathfinding = 1,
	visual = "mesh",
	mesh = "mcl_mobs_addon_breeze.b3d",
	textures = { "mcl_mobs_addon_breeze.png" },
	visual_size = { x = 1.1, y = 1.1 },
	glow = 5,
	makes_footstep_sound = false,  -- it floats
	walk_velocity = 2,
	run_velocity = 3,
	view_range = 16,
	stepheight = 1.2,
	jump = true,
	fall_damage = 0,
	fire_resistant = true,
	drops = {
		{ name = "mcl_mobs_addon:breeze_rod", chance = 1, min = 1, max = 1 },
	},
	animation = {
		stand_start = 0, stand_end = 40, stand_speed = 15,
		walk_start = 40, walk_end = 75, speed_normal = 20,
		run_start = 40, run_end = 75, speed_run = 25,
		punch_start = 75, punch_end = 90, punch_speed = 20,
		die_start = 160, die_end = 170, die_speed = 15, die_loop = false,
	},
	do_custom = function(self, dtime)
		-- hop around randomly (the breeze is a jumper; MC: it bounces)
		self._mca_hop_t = (self._mca_hop_t or 1.5) - dtime
		if self._mca_hop_t <= 0 and not self.attack then
			self._mca_hop_t = 1.5 + math.random() * 2
			local v = self.object:get_velocity()
			self.object:set_velocity({
				x = (math.random() - 0.5) * 6,
				y = 4.5,
				z = (math.random() - 0.5) * 6,
			})
		end
		-- wind charge volley: a fan of 3 rays (MC: 3-5 charges); strong
		-- knockback, small damage; passes through blocks like the warden's
		-- boom (and like MC wind charges bounce around)
		local target = self.attack
		if target and target:is_valid() then
			local sp = self.object:get_pos()
			local tp = target:get_pos()
			if sp and tp then
				local dist = vector.distance(sp, tp)
				self._mca_volley_t = (self._mca_volley_t or 1.5) - dtime
				if self._mca_volley_t <= 0 and dist < 20 then
					self._mca_volley_t = 2.5
					local dir = vector.normalize(vector.subtract(tp, sp))
					dir.y = 0
					minetest.sound_play("mcl_mobs_addon_warden_boom",
						{ pos = sp, gain = 0.4, max_hear_distance = 20 }, true)
					for _, ang in ipairs({ -0.45, 0, 0.45 }) do
						local c = math.cos(ang)
						local s = math.sin(ang)
						local rd = { x = dir.x * c - dir.z * s, z = dir.x * s + dir.z * c }
						for _, obj in ipairs(minetest.get_objects_inside_radius(sp, 16)) do
							local op = obj:get_pos()
							if op then
								local rel = vector.subtract(op, sp)
								local d = vector.length(rel)
								if d > 1.5 and d <= 16 then
									local nd = vector.normalize(rel)
									if nd.x * rd.x + nd.z * rd.z > 0.85 then
										if obj ~= self.object then
											if mcl_util and mcl_util.deal_damage then
												mcl_util.deal_damage(obj, 1, { type = "wind_charge" })
											end
											-- hard knockback (the MC wind charge)
											obj:set_velocity({
												x = rd.x * 10,
												y = 5,
												z = rd.z * 10,
											})
										end
									end
								end
							end
						end
					end
				end
				if dist > 8 then
					self:gopath(tp, 0.9)  -- close the distance
				end
			end
		end
		return true
	end,
})

mcl_mobs_addon.register_egg("mcl_mobs_addon:breeze", S("Breeze"), "#e8ecf5", "#8cb8e8", 0)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:breeze", 30, 30)

minetest.log("action", "[mcl_mobs_addon] bogged + breeze registered (MC 1.21)")

-- ---------------------------------------------------------------------------
end
if mcl_mobs_addon.feature_enabled("drowned") then
-- drops fishing rods / nautilus shells / tridents. Textures: the game's
-- zombie tinted teal-green (legal — game media, CC BY-SA).
-- ---------------------------------------------------------------------------

local drowned_tex = "mobs_mc_zombie.png^[colorize:#3f9e8e:140"
local DROWNED = {
	type = "monster",
	spawn_class = "hostile",
	attack_player = true,
	hp_min = 20,
	hp_max = 20,
	initial_properties = {
		hp_min = 20,
		hp_max = 20,
		breath_max = 30,
	},
	collisionbox = { -0.3, 0.0, -0.3, 0.3, 1.95, 0.3 },
	visual = "mesh",
	mesh = "mobs_mc_zombie.b3d",
	textures = {
		"mobs_mc_empty.png",
		drowned_tex,
		"mobs_mc_empty.png",
	},
	wears_armor = 1,
	armor = { undead = 100, fleshy = 100 },
	damage = 3,
	floats = 1,  -- swims like a fish
	walk_velocity = 1.2,
	run_velocity = 1.8,
	group_attack = { "mobs_mc:player", "mobs_mc:villager", "mobs_mc:iron_golem" },
	drops = {
		{ name = "mcl_fishing:rod", chance = 1, min = 1, max = 1 },
		{ name = "mcl_mobitems:nautilus_shell", chance = 8, min = 1, max = 1 },
		{ name = "vl_tridents:trident", chance = 25, min = 1, max = 1 },
		{ name = "mcl_tridents:trident", chance = 25, min = 1, max = 1 },
	},
	animation = {
		stand_start = 0, stand_end = 0,
		walk_start = 0, walk_end = 40,
	},
	sounds = {},
}

mcl_mobs.register_mob("mcl_mobs_addon:drowned", DROWNED)
mcl_mobs.register_egg("mcl_mobs_addon:drowned", S("Drowned"), "#3f9e8e", "#15433c", 0)
-- the games' oceans are the "<Biome>_ocean" variants (no plain "Ocean")
mcl_mobs_addon.register_spawn("mcl_mobs_addon:drowned",
	{
		"Jungle_ocean", "Savanna_ocean", "Desert_ocean", "Swampland_ocean",
		"Plains_ocean", "Forest_ocean", "BirchForest_ocean", "FlowerForest_ocean",
		"Taiga_ocean", "ColdTaiga_ocean",
	},
	{
		"Jungle_ocean", "Savanna_ocean", "Desert_ocean", "Swampland_ocean",
		"Plains_ocean", "Forest_ocean", "BirchForest_ocean", "FlowerForest_ocean",
		"Taiga_ocean", "ColdTaiga_ocean",
	}, 30)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:drowned", 20, 20)
end