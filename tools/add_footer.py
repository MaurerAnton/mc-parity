#!/usr/bin/env python3
"""Append the Mineclonia hp patch block to the assembled mobs_port.lua."""
import re

OUT = "/home/llm/questions/mcl_mobs_addon/mobs_port.lua"

FOOTER = '''
-- Mineclonia reads hp from the def base (math.random at activate) — the
-- same latent crash as the other addon mobs; patch after registration.
for _name, _hp in pairs({
\t["mcl_mobs_addon:creeper"] = {20, 20},
\t["mcl_mobs_addon:creeper_charged"] = {20, 20},
\t["mcl_mobs_addon:blaze"] = {20, 20},
\t["mcl_mobs_addon:enderman"] = {40, 40},
\t["mcl_mobs_addon:pufferfish"] = {6, 6},
\t["mcl_mobs_addon:ravager"] = {100, 100},
\t["mcl_mobs_addon:wandering_trader"] = {20, 20},
\t["mcl_mobs_addon:trader_llama"] = {30, 30},
}) do
\tmcl_mobs_addon.mcln_base_hp(_name, _hp[1], _hp[2])
end

minetest.log("action", "[mcl_mobs_addon] ported mobs registered (creeper/enderman/blaze/pufferfish/ravager/trader)")
'''

src = open(OUT).read()
# remove any previous footer attempt, then append
src = re.sub(r"\n-- Mineclonia reads hp from the def base.*$", "\n", src, flags=re.S)
open(OUT, "w").write(src.rstrip() + "\n" + FOOTER)
print("footer appended:", OUT)
