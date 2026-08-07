#!/usr/bin/env python3
"""Extract Mineclonia mob defs for porting into mcl_mobs_addon (GPLv3).
Transforms: mobs_mc:<id> -> mcl_mobs_addon:<id> for the REGISTERED id and
its internal self-references; the register_spawner block -> a dual-game
spawn comment (spawn registration is hand-written in the port module);
mobs_mc.* helpers -> guarded local calls.
"""
import re, sys

def extract_def(path):
    src = open(path, encoding="utf-8").read()
    return src

def port_file(path, out, mob_id, mob_name):
    src = extract_def(path)
    # registered id + self references
    src = src.replace(f'"mobs_mc:{mob_id}"', f'"mcl_mobs_addon:{mob_id}"')
    src = src.replace(f'mcl_mobs.register_mob ("mobs_mc:{mob_id}"',
                      f'mcl_mobs.register_mob ("mcl_mobs_addon:{mob_id}"')
    src = src.replace(f'mcl_mobs.register_egg("mobs_mc:{mob_id}"',
                      f'mcl_mobs.register_egg("mcl_mobs_addon:{mob_id}"')
    open(out, "w", encoding="utf-8").write(src)
    print(f"{mob_name}: {len(src.splitlines())} lines -> {out}")

if __name__ == "__main__":
    src = sys.argv[1]; out = sys.argv[2]; mid = sys.argv[3]; name = sys.argv[4]
    port_file(src, out, mid, name)
