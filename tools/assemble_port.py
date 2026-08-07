#!/usr/bin/env python3
"""Assemble mobs_port.lua from the Mineclonia-extracted defs (GPLv3).
Per-file fixes: mobs_mc helper guards, spawn-block replacement, ravager
de-Mineclonia-ing, wandering-trader extraction.
"""
import re, subprocess

OUT = "/home/llm/questions/mcl_mobs_addon/mobs_port.lua"
TMP = "/tmp/"

HEADER = """-- MC mobs ported from Mineclonia (GPLv3 — same license as the addon):
-- creeper (+charged), enderman, blaze, pufferfish, ravager,
-- wandering trader. These close the LAST ecosystem gaps: VoxeLibre
-- 0.92 lacks creeper/enderman/blaze/pufferfish/wandering_trader
-- entirely; Mineclonia has them but NOT ravager-friendly targeting here.
-- Adapted: ids -> mcl_mobs_addon:*, Mineclonia-only spawn API ->
-- dual-game register_monster_spawn, raid/targeting-rule machinery ->
-- standard framework aggro (the targeting-rule API is Mineclonia-only).
-- Media (models/textures) keeps the mobs_mc_* names (the media namespace
-- is global; on Mineclonia our identical copies simply shadow the game's).

local S = minetest.get_translator("mcl_mobs_addon")

-- Mineclonia's table.merge is missing in VoxeLibre — shim it
if not table.merge then
	function table.merge(t1, t2)
		local r = {}
		if t1 then for k, v in pairs(t1) do r[k] = v end end
		if t2 then for k, v in pairs(t2) do r[k] = v end end
		return r
	end
end

-- shared biome lists (verified valid in BOTH games' registries)
local OW_MONSTERS = {
\t"Plains", "Forest", "SunflowerPlains", "FlowerForest", "BirchForest",
\t"BirchForestM", "RoofedForest", "Taiga", "MegaTaiga", "MegaSpruceTaiga",
\t"ColdTaiga", "Desert", "Savanna", "SavannaM", "Swampland", "Jungle",
\t"JungleM", "BambooJungle", "ExtremeHills", "Mesa", "MesaBryce",
\t"MesaPlateauF", "MesaPlateauFM", "IcePlains", "IcePlainsSpikes",
}
local NETHER_BIOMES = { "Nether", "CrimsonForest", "WarpedForest" }
local END_BIOMES = {
\t"End", "EndBarrens", "EndBorder", "EndHighlands", "EndIsland",
\t"EndMidlands", "EndSmallIslands",
}
local OCEAN_BIOMES = {
\t"Jungle_ocean", "Savanna_ocean", "Desert_ocean", "Swampland_ocean",
\t"Plains_ocean", "Forest_ocean", "BirchForest_ocean", "FlowerForest_ocean",
\t"Taiga_ocean", "ColdTaiga_ocean",
}

-- dual-game monster spawn (the animal variant in init.lua is for passives;
-- monsters use the game's monster_spawner template + pack sizes)
local function register_monster_spawn(name, biomes, weight, pack_min, pack_max, dimension)
\tdimension = dimension or "overworld"
\tlocal ok, err = pcall(function()
\tif mcl_mobs.register_spawner and mobs_mc and mobs_mc.monster_spawner then
\t\tmcl_mobs.register_spawner(table.merge(mobs_mc.monster_spawner, {
\t\t\tname = name,
\t\t\tbiomes = biomes,
\t\t\tweight = weight,
\t\t\tpack_min = pack_min or 1,
\t\t\tpack_max = pack_max or 1,
\t\t}))
\telseif mcl_mobs.spawn_setup then
\t\tmcl_mobs:spawn_setup({
\t\t\tname = name,
\t\t\tdimension = dimension,
\t\t\tbiomes = biomes,
\t\t\tweight = weight,
\t\t})
\tend
\tend)
\tif not ok then
\t\tminetest.log("action", "[mcl_mobs_addon] spawn FAIL " .. tostring(name) .. ": " .. tostring(err))
\tend
end

"""

def strip_spawn(src):
    """Remove the trailing register_spawner section (after the last
    register_mob) — table.merge inside the defs stays untouched."""
    lines = src.splitlines()
    mobs = [i for i, l in enumerate(lines) if "register_mob" in l]
    last_mob = mobs[-1] if mobs else -1
    out, i = lines[:last_mob + 1], last_mob + 1
    while i < len(lines):
        l = lines[i]
        if ("register_spawner" in l or "table.merge" in l
                or "biomes = mobs_mc.monster_biomes" in l or "spawner_" in l):
            while i < len(lines) and lines[i].strip() != "})":
                i += 1
            i += 1
            continue
        out.append(l)
        i += 1
    return "\n".join(out).rstrip() + "\n"

def de_mcln(src, add_aggro=True):
    """Strip Mineclonia-only machinery from a ported def:
    _targeting_rules / ai_functions blocks, mob_class.* references."""
    def strip_braced(s, marker):
        lines = s.splitlines()
        out, i = [], 0
        while i < len(lines):
            l = lines[i]
            if marker in l and "=" in l and "{" in l:
                depth = l.count("{") - l.count("}")
                while i < len(lines) and depth > 0:
                    i += 1
                    if i < len(lines):
                        depth += lines[i].count("{") - lines[i].count("}")
                i += 1
                continue
            out.append(l)
            i += 1
        return "\n".join(out)
    src = strip_braced(src, "_targeting_rules")
    src = strip_braced(src, "ai_functions")
    src = re.sub(r"mob_class\.[a-z_]+\n", "", src)
    src = re.sub(r"local mob_class = [^\n]*\n", "", src)
    src = re.sub(r"mob_class\.([a-z_]+) ?\(self(,|\))", r"mcl_mobs.mob_class.\1(self\2", src)
    def strip_gwp(s):
        lines = s.splitlines()
        out, i = [], 0
        while i < len(lines):
            l = lines[i]
            if "gwp_penalties" in l or "gwp_floortypes" in l:
                if "{" in l:
                    while i < len(lines) and lines[i].strip() != "})":
                        i += 1
                    i += 1
                else:
                    i += 1  # one-line assignment — skip just it
                continue
            out.append(l)
            i += 1
        return "\n".join(out)
    src = strip_gwp(src)
    src = re.sub(r"\tdo_go_pos = [^\n]*\n", "", src)
    if add_aggro:
        if "attack_player" not in src:
            # standard framework aggro (the targeting-rule API is MCLN-only)
            src = re.sub(r"(\ttype = \"monster\",\n)", r"\1\tattack_player = true,\n", src, count=1)
        if "spawn_class" not in src.split("register_mob")[0]:
            # VoxeLibre asserts a spawn class on every mob
            src = re.sub(r"(\ttype = \"monster\",\n)", "\\1\tspawn_class = \"hostile\",\n", src, count=1)
    else:
        if "spawn_class" not in src.split("register_mob")[0]:
            src = re.sub(r"(\ttype = \"animal\",\n)", "\\1\tspawn_class = \"passive\",\n", src, count=1)
            src = re.sub(r"(\ttype = \"monster\",\n)", "\\1\tspawn_class = \"passive\",\n", src, count=1)
    return src

# ---- creeper ----
c = open(TMP + "port_creeper.lua").read()
c = c.replace("mobs_mc:creeper_charged", "mcl_mobs_addon:creeper_charged")
c = c.replace('local mobs_griefing = mobs_mc.is_mob_griefing_enabled("creeper")',
              'local mobs_griefing = (mobs_mc and mobs_mc.is_mob_griefing_enabled)\n\tand mobs_mc.is_mob_griefing_enabled("creeper") or true')
c = de_mcln(c)
c = strip_spawn(c)
creeper = c + """
register_monster_spawn("mcl_mobs_addon:creeper", OW_MONSTERS, 100, 4, 4)
"""

# ---- blaze ----
b = open(TMP + "port_blaze.lua").read()
b = b.replace("mobs_mc:blaze_fireball", "mcl_mobs_addon:blaze_fireball")
b = de_mcln(b)
b = strip_spawn(b)
blaze = b + """
register_monster_spawn("mcl_mobs_addon:blaze", NETHER_BIOMES, 20, 1, 2, "nether")
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:blaze", 20, 20)
"""

# ---- enderman ----
e = open(TMP + "port_enderman.lua").read()
e = e.replace("mobs_mc:ender_eyes", "mcl_mobs_addon:ender_eyes")
e = e.replace('local mobs_griefing = mobs_mc.is_mob_griefing_enabled("enderman")',
              'local mobs_griefing = (mobs_mc and mobs_mc.is_mob_griefing_enabled)\n\tand mobs_mc.is_mob_griefing_enabled("enderman") or true')
e = de_mcln(e)
e = strip_spawn(e)
enderman = e + """
register_monster_spawn("mcl_mobs_addon:enderman", OW_MONSTERS, 1, 1, 4)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:enderman", 40, 40)
register_monster_spawn("mcl_mobs_addon:enderman", NETHER_BIOMES, 1, 1, 4, "nether")
register_monster_spawn("mcl_mobs_addon:enderman", END_BIOMES, 10, 4, 4, "end")
"""

# ---- pufferfish ----
p = open(TMP + "port_pufferfish.lua").read()
p = de_mcln(p, add_aggro=False)
p = strip_spawn(p)
pufferfish = p + """
register_monster_spawn("mcl_mobs_addon:pufferfish", OCEAN_BIOMES, 10, 1, 3)
mcl_mobs_addon.mcln_base_hp("mcl_mobs_addon:pufferfish", 6, 6)
"""

# ---- ravager: de-Mineclonia (raid template + targeting rules + gwp) ----
r = open(TMP + "port_ravager.lua").read()
r = r.replace("local raid_mob = mobs_mc.raid_mob", "local raid_mob = {}  -- raid system not ported (Mineclonia-only)")
r = de_mcln(r)
r = re.sub(r"ravager\.gwp_penalties = .*?\n\n", "\n", r, flags=re.S)
r = re.sub(r"ravager\.gwp_floortypes = .*?\n\n", "\n", r, flags=re.S)
ravager = r + """
-- no natural spawn (MC: raid-only); egg only
"""

# ---- wandering trader ----
wt_src = subprocess.check_output(["git", "-C", "/tmp/mcln", "show",
    "HEAD:mods/ENTITIES/mobs_mc/wandering_trader.lua"]).decode()
wt = wt_src.replace('"mobs_mc:wandering_trader"', '"mcl_mobs_addon:wandering_trader"').replace("mobs_mc:trader_llama", "mcl_mobs_addon:trader_llama")
# villager_base is a LOCAL in the game's villager.lua (not exported) — the
# trader's def is self-contained, so merge over an empty base
wt = re.sub(r"local villager_base = mobs_mc\.villager_base", "local villager_base = {}", wt)
wt = re.sub(r"(local wandering_trader = table\.merge \(villager_base, \{\n)",
            "\\1\\ttype = \"animal\",\n\\tspawn_class = \"passive\",\n", wt)
wt = de_mcln(wt, add_aggro=False)
# trade_from_table is Mineclonia-only (VL villagers build trades differently)
wt = wt.replace("local function get_wandering_trades ()",
    "local function get_wandering_trades ()\n\tif not (mobs_mc and mobs_mc.trade_from_table) then return {} end")
# the file's own trader spawner (is_canonical) duplicates our appended
# spawn and calls register_spawner, which is nil on VoxeLibre — drop it
def drop_trader_spawner(s):
    lines = s.splitlines()
    out, i, skip = [], 0, False
    while i < len(lines):
        l = lines[i]
        if ("wandering_trader_spawner" in l or "trader_llama_spawner" in l) and "=" in l:
            skip = True
        if skip:
            if "register_spawner" in l:
                skip = False
            i += 1
            continue
        out.append(l)
        i += 1
    return "\n".join(out)
wt = drop_trader_spawner(wt)
# trader_llama merges the game's llama (no spawn_class there)
wt = re.sub(r"(local trader_llama = table\.merge \(llama, \{\n)",
            "\\1\\ttype = \"animal\",\\n\\tspawn_class = \"passive\",\\n", wt)
# villager_base is empty now — route its activate to the framework class
wt = wt.replace("villager_base.mob_activate (self,", "mcl_mobs.mob_class.mob_activate (self,")
# update_trades is Mineclonia-only (villager method absent on VL)
wt = wt.replace("self:update_trades (get_wandering_trades ())",
                "if self.update_trades then\n\t\tself:update_trades (get_wandering_trades ())\n\tend")
# villager_base is empty — guard the persistence override (Mineclonia-only)
wt = wt.replace("function wandering_trader:get_staticdata_table ()",
    "function wandering_trader:get_staticdata_table ()\n\tif not villager_base.get_staticdata_table then return {} end")
trader = wt + """
-- natural spawn: rare, like MC; traders wander with their llamas.
-- Mineclonia branch FIRST (their spawn_setup is a broken compat shim).
if mcl_mobs.register_spawner and mobs_mc and mobs_mc.animal_spawner then
\tmcl_mobs.register_spawner(table.merge(mobs_mc.animal_spawner, {
\t\tname = "mcl_mobs_addon:wandering_trader", biomes = OW_MONSTERS, weight = 5,
\t}))
elseif mcl_mobs.spawn_setup then
\tmcl_mobs:spawn_setup({ name = "mcl_mobs_addon:wandering_trader", dimension = "overworld", biomes = OW_MONSTERS, weight = 5 })
end
"""

with open(OUT, "w") as f:
    f.write(HEADER)
    f.write("-- ---------------------------------------------------------------------------\n-- CREEPER (+charged)\n-- ---------------------------------------------------------------------------\n")
    f.write(creeper + "\n")
    f.write("-- ---------------------------------------------------------------------------\n-- BLAZE\n-- ---------------------------------------------------------------------------\n")
    f.write(blaze + "\n")
    f.write("-- ---------------------------------------------------------------------------\n-- ENDERMAN\n-- ---------------------------------------------------------------------------\n")
    f.write(enderman + "\n")
    f.write("-- ---------------------------------------------------------------------------\n-- PUFFERFISH\n-- ---------------------------------------------------------------------------\n")
    f.write(pufferfish + "\n")
    f.write("-- ---------------------------------------------------------------------------\n-- RAVAGER\n-- ---------------------------------------------------------------------------\n")
    f.write(ravager + "\n")
    f.write("-- ---------------------------------------------------------------------------\n-- WANDERING TRADER\n-- ---------------------------------------------------------------------------\n")
    f.write(trader + "\n")
    f.write('minetest.log("action", "[mcl_mobs_addon] ported mobs registered (creeper/enderman/blaze/pufferfish/ravager/trader)")\n')
print("assembled:", OUT)
