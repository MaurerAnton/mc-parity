#!/usr/bin/env python3
"""Port the 6 MCLN-only item mods (conduit, dripstone, candles, powder
snow, echo shard, mace) + the VL-only chain into mcl_mobs_addon (GPLv3).
Extracts each mod's main lua, remaps ids and media names, assembles
port_items.lua."""
import subprocess, re, os

MCLN = "/tmp/mcln"
VL = "/tmp/mclmobs"
OUT = "/home/llm/questions/mcl_mobs_addon/port_items.lua"

def show(git, path):
    return subprocess.check_output(["git", "-C", git, "show", f"HEAD:{path}"]).decode()

def remap(src, old_prefix, new_prefix):
    src = src.replace(f'"{old_prefix}:', f'"{new_prefix}:')
    src = src.replace(old_prefix + "_", new_prefix + "_")
    return src

parts = []
parts.append('''-- ---------------------------------------------------------------------------
-- PORTED ITEM BLOCKS (GPLv3, from Mineclonia): conduit, dripstone,
-- candles, powder snow, echo shard, mace — the items VoxeLibre lacked.
-- Plus the chain (from VoxeLibre, for Mineclonia).
-- ---------------------------------------------------------------------------

local S = minetest.get_translator("mcl_mobs_addon")
''')

# ---- conduit ----
c = show(MCLN, "mods/ITEMS/mcl_conduits/init.lua")
c = remap(c, "mcl_conduits", "mcl_mobs_addon")
# the conduit mod references mcl_conduit_ media via a local modname var — fix
c = c.replace('local modname = minetest.get_current_modname()', 'local modname = "mcl_mobs_addon"')
parts.append("-- ======================= CONDUIT (1.13) =======================\n" + c + "\n")

# ---- dripstone (init only — lg_register is MCLN-levelgen worldgen) ----
d = show(MCLN, "mods/ITEMS/mcl_dripstone/init.lua")
d = remap(d, "mcl_dripstone", "mcl_mobs_addon")
d = d.replace('local modname = minetest.get_current_modname()', 'local modname = "mcl_mobs_addon"')
parts.append("-- ======================= DRIPSTONE (1.17) =======================\n" + d + "\n")

# ---- candles ----
ca = show(MCLN, "mods/ITEMS/mcl_candles/init.lua")
ca = remap(ca, "mcl_candles", "mcl_mobs_addon")
ca = ca.replace('local modname = minetest.get_current_modname()', 'local modname = "mcl_mobs_addon"')
parts.append("-- ======================= CANDLES (1.17) =======================\n" + ca + "\n")

# ---- powder snow ----
ps = show(MCLN, "mods/ITEMS/mcl_powder_snow/init.lua")
ps = remap(ps, "mcl_powder_snow", "mcl_mobs_addon")
ps = ps.replace('local modname = minetest.get_current_modname()', 'local modname = "mcl_mobs_addon"')
parts.append("-- ======================= POWDER SNOW (1.17) =======================\n" + ps + "\n")

# ---- echo shard (the item from mcl_sculk) ----
sc = show(MCLN, "mods/ITEMS/mcl_sculk/init.lua")
m = re.search(r'core\.register_craftitem\("mcl_sculk:echo_shard", \{.*?\n\}\)\n', sc, re.S)
if m:
    es = remap(m.group(0), "mcl_sculk", "mcl_mobs_addon")
    parts.append("-- ======================= ECHO SHARD (1.19) =======================\n"
                 + es.replace("core.", "minetest.") + "\n")

# ---- mace ----
ma = show(MCLN, "mods/ITEMS/mcl_tools/mace.lua")
ma = remap(ma, "mcl_tools", "mcl_mobs_addon")
ma = ma.replace('local modname = minetest.get_current_modname()', 'local modname = "mcl_mobs_addon"')
parts.append("-- ======================= MACE (1.21) =======================\n" + ma + "\n")

# ---- chain (from VL, for Mineclonia) ----
ch = show(VL, "mods/ITEMS/mcl_lanterns/init.lua")
m2 = re.search(r'minetest\.register_node\("mcl_lanterns:chain", \{.*?\n\}\)\n', ch, re.S)
if m2:
    chain = remap(m2.group(0), "mcl_lanterns", "mcl_mobs_addon")
    parts.append("-- ======================= CHAIN (1.16, VL -> MCLN) =======================\n" + chain + "\n")

open(OUT, "w").write("\n".join(parts))
print(f"assembled: {OUT} ({len(parts)} parts)")
