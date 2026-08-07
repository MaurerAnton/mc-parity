#!/usr/bin/env python3
"""Port the 6 MCLN-only item mods (conduit, dripstone, candles, powder
snow, echo shard, mace) + the VL-only chain into mc_parity (GPLv3).
Extracts each mod's main lua, remaps ids and media names, assembles
port_items.lua."""
import subprocess, re, os

MCLN = "/tmp/mcln"
VL = "/tmp/mclmobs"
OUT = "/home/llm/questions/mc_parity/port_items.lua"

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

local S = minetest.get_translator("mc_parity")
''')

# ---- conduit ----
c = show(MCLN, "mods/ITEMS/mcl_conduits/init.lua")
c = remap(c, "mcl_conduits", "mc_parity")
# the conduit mod references mcl_conduit_ media via a local modname var — fix
c = c.replace('local modname = minetest.get_current_modname()', 'local modname = "mc_parity"')
parts.append("-- ======================= CONDUIT (1.13) =======================\n" + c + "\n")

# ---- dripstone (init only — lg_register is MCLN-levelgen worldgen) ----
d = show(MCLN, "mods/ITEMS/mcl_dripstone/init.lua")
d = remap(d, "mcl_dripstone", "mc_parity")
d = d.replace('local modname = minetest.get_current_modname()', 'local modname = "mc_parity"')
parts.append("-- ======================= DRIPSTONE (1.17) =======================\n" + d + "\n")

# ---- candles ----
ca = show(MCLN, "mods/ITEMS/mcl_candles/init.lua")
ca = remap(ca, "mcl_candles", "mc_parity")
ca = ca.replace('local modname = minetest.get_current_modname()', 'local modname = "mc_parity"')
parts.append("-- ======================= CANDLES (1.17) =======================\n" + ca + "\n")

# ---- powder snow ----
ps = show(MCLN, "mods/ITEMS/mcl_powder_snow/init.lua")
ps = remap(ps, "mcl_powder_snow", "mc_parity")
ps = ps.replace('local modname = minetest.get_current_modname()', 'local modname = "mc_parity"')
parts.append("-- ======================= POWDER SNOW (1.17) =======================\n" + ps + "\n")

# ---- echo shard (the item from mcl_sculk) ----
sc = show(MCLN, "mods/ITEMS/mcl_sculk/init.lua")
m = re.search(r'core\.register_craftitem\("mcl_sculk:echo_shard", \{.*?\n\}\)\n', sc, re.S)
if m:
    es = remap(m.group(0), "mcl_sculk", "mc_parity")
    parts.append("-- ======================= ECHO SHARD (1.19) =======================\n"
                 + es.replace("core.", "minetest.") + "\n")

# ---- mace ----
ma = show(MCLN, "mods/ITEMS/mcl_tools/mace.lua")
ma = remap(ma, "mcl_tools", "mc_parity")
ma = ma.replace('local modname = minetest.get_current_modname()', 'local modname = "mc_parity"')
parts.append("-- ======================= MACE (1.21) =======================\n" + ma + "\n")

# ---- chain (from VL, for Mineclonia) ----
ch = show(VL, "mods/ITEMS/mcl_lanterns/init.lua")
m2 = re.search(r'minetest\.register_node\("mcl_lanterns:chain", \{.*?\n\}\)\n', ch, re.S)
if m2:
    chain = remap(m2.group(0), "mcl_lanterns", "mc_parity")
    parts.append("-- ======================= CHAIN (1.16, VL -> MCLN) =======================\n" + chain + "\n")

open(OUT, "w").write("\n".join(parts))
print(f"assembled: {OUT} ({len(parts)} parts)")
