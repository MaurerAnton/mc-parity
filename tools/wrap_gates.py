#!/usr/bin/env python3
"""Wrap feature sections in `if mc_parity.feature_enabled(...) then ... end`
for the version-gating menu. Sections are defined by line ranges; the script
inserts from the bottom up so line numbers stay valid."""

FILES = {
    "mobs_121.lua": [
        ("armadillo", 18, 108),
        ("wolf_armor", 109, 135),
        ("wolf_variants", 136, 255),
        ("bogged", 257, 358),
        ("breeze", 359, 473),
        ("drowned", 474, None),
    ],
    "mobs_import.lua": [
        ("frog", 34, 161),
        ("turtle", 162, 389),
        ("phantom", 390, 632),
        ("sniffer", 633, None),
    ],
    "mobs_port.lua": [
        ("creeper", 71, 343),
        ("blaze", 344, 637),
        ("enderman", 638, 1393),
        ("pufferfish", 1394, 1650),
        ("ravager", 1651, 2151),
        ("wandering_trader", 2152, None),
    ],
    "deepdark.lua": [
        ("sculk", 53, 110),     # sensor + shrieker nodes
        ("deep_dark", 111, None),  # biome + ancient city
    ],
}

import sys
BASE = "/home/llm/questions/mc_parity"

for fname, sections in FILES.items():
    path = f"{BASE}/{fname}"
    lines = open(path).read().splitlines()
    # resolve None ends (eof) and shift bottom-up
    for i in range(len(sections) - 1, -1, -1):
        gate, start, end = sections[i]
        if end is None:
            end = len(lines)
        indent = ""
        if fname == "mobs_port.lua" and i == len(sections) - 1:
            # trader section: exclude the footer (hp patch) — find it
            footer = next((j for j in range(end - 1, start, -1)
                           if "Mineclonia reads hp from the def base" in lines[j]), None)
            if footer:
                end = footer - 1
        lines[start - 1:start] = [f'if mc_parity.feature_enabled("{gate}") then']
        lines[end:end] = ["end"]
    open(path, "w").write("\n".join(lines))
    print(f"{fname}: wrapped {len(sections)} sections")
