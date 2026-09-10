#!/usr/bin/env python3
"""Port Mineclonia's pale-oak media to mc_parity (MC 1.21.4 pale garden).

Mineclonia ships a complete `mcl_pale_oak` mod (mcl_trees.register_wood +
plants + resin). VoxeLibre has none. This tool prepares the VL port:

  1. Renames the CC BY-SA textures to our mc_parity_ prefix
     (textures/mc_parity_pale_oak_*.png).
  2. Rewrites the three tree .mts schematics so the node names point at
     OUR registered ids instead of Mineclonia's, writing
     schematics/mc_parity_pale_oak_{1,2,3}.mts.

The .mts rewrite only touches the node-name table; the zlib-compressed
node data and the trailing mapping table are copied verbatim (they index
the name table, so no decompression is needed).

Format reference: src/mapgen/mg_schematic.cpp (Luanti) — signature MTSM,
u16 version, 3x u16 size, u8 slice_probs[size.Y], u16 name count,
string16 names, then the compressed MapNode blob.

Usage:
  python3 tools/port_pale_oak.py [src_dir]     # default /tmp/pale_src

Source (GPLv3 code / CC BY-SA 4.0 media — see Mineclonia LEGAL.md):
  https://codeberg.org/Mineclonia/Mineclonia/src/branch/main/mods/ITEMS/mcl_pale_oak
"""
import os
import shutil
import struct
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = sys.argv[1] if len(sys.argv) > 1 else "/tmp/pale_src"

TEXTURES = {
    "mcl_pale_oak_log.png": "mc_parity_pale_oak_log.png",
    "mcl_pale_oak_log_top.png": "mc_parity_pale_oak_log_top.png",
    "mcl_stripped_pale_oak_log_side.png": "mc_parity_pale_oak_log_stripped.png",
    "mcl_stripped_pale_oak_log_top.png": "mc_parity_pale_oak_log_top_stripped.png",
    "mcl_pale_oak_planks.png": "mc_parity_pale_oak_planks.png",
    "mcl_pale_oak_leaves.png": "mc_parity_pale_oak_leaves.png",
    "mcl_pale_oak_sapling_pale_oak.png": "mc_parity_pale_oak_sapling.png",
    "mcl_pale_oak_door_bottom.png": "mc_parity_pale_oak_door_bottom.png",
    "mcl_pale_oak_door_top.png": "mc_parity_pale_oak_door_top.png",
    "mcl_pale_oak_door_item.png": "mc_parity_pale_oak_door_inv.png",
    "mcl_pale_oak_trapdoor.png": "mc_parity_pale_oak_trapdoor.png",
    "mcl_pale_oak_trapdoor_side.png": "mc_parity_pale_oak_trapdoor_side.png",
    "mcl_pale_oak_hanging_moss.png": "mc_parity_pale_oak_hanging_moss.png",
    "mcl_pale_oak_hanging_moss_tip.png": "mc_parity_pale_oak_hanging_moss_tip.png",
    "mcl_pale_oak_moss.png": "mc_parity_pale_oak_moss.png",
    "mcl_pale_oak_resin_block.png": "mc_parity_resin_block.png",
}

NODE_MAP = {
    "mcl_trees:tree_pale_oak": "mc_parity:pale_oak_tree",
    "mcl_trees:leaves_pale_oak": "mc_parity:pale_oak_leaves",
    "mcl_pale_oak:hanging_moss": "mc_parity:pale_oak_hanging_moss",
    "mcl_pale_oak:hanging_moss_tip": "mc_parity:pale_oak_hanging_moss_tip",
}

SCHEMATICS = ["mcl_pale_oak_1.mts", "mcl_pale_oak_2.mts", "mcl_pale_oak_3.mts"]


def read_u16(data, off):
    return struct.unpack_from(">H", data, off)[0], off + 2


def remap_schematic(src_path, dst_path):
    data = open(src_path, "rb").read()
    if data[:4] != b"MTSM":
        raise ValueError(f"{src_path}: bad signature")
    off = 4
    version, off = read_u16(data, off)
    sx, off = read_u16(data, off)
    sy, off = read_u16(data, off)
    sz, off = read_u16(data, off)
    off += sy  # slice_probs (u8 per y)
    nnames, off = read_u16(data, off)
    names = []
    for _ in range(nnames):
        ln, off = read_u16(data, off)
        names.append(data[off:off + ln].decode("utf-8"))
        off += ln
    out_names = []
    for n in names:
        out_names.append(NODE_MAP.get(n, n))
    header = bytearray()
    header += b"MTSM"
    header += struct.pack(">H", version)
    header += struct.pack(">HHH", sx, sy, sz)
    header += data[12:12 + sy]  # slice_probs verbatim
    header += struct.pack(">H", len(out_names))
    for n in out_names:
        b = n.encode("utf-8")
        header += struct.pack(">H", len(b)) + b
    open(dst_path, "wb").write(bytes(header) + data[off:])
    return version, (sx, sy, sz), names, out_names, len(data) - off


def main():
    tex_src = os.path.join(SRC, "textures")
    tex_dst = os.path.join(REPO, "textures")
    sch_dst = os.path.join(REPO, "schematics")
    os.makedirs(sch_dst, exist_ok=True)
    n = 0
    for src, dst in sorted(TEXTURES.items()):
        s = os.path.join(tex_src, src)
        if not os.path.isfile(s):
            print(f"SKIP (missing): {src}")
            continue
        shutil.copyfile(s, os.path.join(tex_dst, dst))
        n += 1
    print(f"textures copied: {n}/{len(TEXTURES)}")
    for i, name in enumerate(SCHEMATICS, 1):
        s = os.path.join(SRC, name)
        d = os.path.join(sch_dst, f"mc_parity_pale_oak_{i}.mts")
        version, size, names, out_names, tail = remap_schematic(s, d)
        print(f"{d}: v{version} {size[0]}x{size[1]}x{size[2]} "
              f"names={out_names} tail={tail}B")


if __name__ == "__main__":
    main()
