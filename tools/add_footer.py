#!/usr/bin/env python3
"""Append the Mineclonia hp patch block to the assembled mobs_port.lua."""
import re

OUT = "/home/llm/questions/mc_parity/mobs_port.lua"

FOOTER = '''
-- Mineclonia reads hp from the def base (math.random at activate) — the
-- same latent crash as the other addon mobs; patch after registration.
for _name, _hp in pairs({
\t["mc_parity:creeper"] = {20, 20},
\t["mc_parity:creeper_charged"] = {20, 20},
\t["mc_parity:blaze"] = {20, 20},
\t["mc_parity:enderman"] = {40, 40},
\t["mc_parity:pufferfish"] = {6, 6},
\t["mc_parity:ravager"] = {100, 100},
\t["mc_parity:wandering_trader"] = {20, 20},
\t["mc_parity:trader_llama"] = {30, 30},
}) do
\tmc_parity.mcln_base_hp(_name, _hp[1], _hp[2])
end

minetest.log("action", "[mc_parity] ported mobs registered (creeper/enderman/blaze/pufferfish/ravager/trader)")
'''

src = open(OUT).read()
# remove any previous footer attempt, then append
src = re.sub(r"\n-- Mineclonia reads hp from the def base.*$", "\n", src, flags=re.S)
open(OUT, "w").write(src.rstrip() + "\n" + FOOTER)
print("footer appended:", OUT)
