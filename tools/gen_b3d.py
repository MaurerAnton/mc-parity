#!/usr/bin/env python3
"""Minimal .b3d writer for box-based mob models (Luanti).

Mirrors Luanti's CB3DMeshFileLoader exactly (verified against
mobs_mc_wolf.b3d and irr/src/CB3DMeshFileLoader.cpp):
  - chunk size = length of chunk DATA (excluding the 8-byte header)
  - strings are NUL-terminated (readString reads until 0x00)
  - TEXS optional; brush with texture_id=-1 (entity provides the texture)
  - VRTS: flags=0 (loader computes normals), 1 texcoord set, size 2
  - TRIS: brush_id + raw s32 index triples (no flags/count in Luanti fork)
  - V=0 maps to the TOP of the texture
Usage: gen_b3d.py out.b3d [texture.png]  (edit boxes below per mob)
"""
import struct, sys

def chunk(name, data):
    return name.encode() + struct.pack("<i", len(data)) + data

def cstr(s):
    return s.encode() + b"\x00"

def f32(*vals):
    return struct.pack("<" + "f" * len(vals), *vals)

def s32(*vals):
    return struct.pack("<" + "i" * len(vals), *vals)

def corners(x0, y0, z0, x1, y1, z1):
    return [
        (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
        (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1),
    ]

FACES = [(4, 5, 7, 6), (1, 0, 2, 3), (1, 5, 7, 3), (0, 4, 6, 2), (3, 7, 5, 1), (0, 1, 5, 4)]
UVS = [(0, 1), (1, 1), (1, 0), (0, 0)]

def box_geometry(c):
    verts, tris, base = [], [], 0
    for face in FACES:
        for ci in face:
            x, y, z = c[ci]
            u, v = UVS[len(verts) % 4]
            verts.append((x, y, z, u, v))
        a, b, d, e = base, base + 1, base + 2, base + 3
        tris += [(a, b, d), (a, d, e)]
        base += 4
    return verts, tris

def build_mesh(boxes):
    verts, tris, vbase = [], [], 0
    for (minp, maxp) in boxes:
        v, t = box_geometry(corners(*minp, *maxp))
        verts += v
        tris += [(i + vbase, j + vbase, k + vbase) for (i, j, k) in t]
        vbase += len(v)
    return verts, tris

def write_b3d(path, boxes):
    verts, tris = build_mesh(boxes)
    brus = chunk("BRUS", s32(1) + cstr("mat") + f32(1, 1, 1, 1)
                 + f32(0) + s32(1) + s32(0) + s32(-1))
    vrts = chunk("VRTS", s32(0, 1, 2) + b"".join(f32(x, y, z, u, v) for x, y, z, u, v in verts))
    triss = chunk("TRIS", s32(-1) + b"".join(s32(a, b, c) for a, b, c in tris))
    mesh = chunk("MESH", s32(0) + vrts + triss)
    node = chunk("NODE", cstr("body") + f32(0, 0, 0) + f32(1, 1, 1) + f32(1, 0, 0, 0) + mesh)
    main = b"BB3D" + struct.pack("<i", 4 + len(brus) + len(node)) + s32(1) + brus + node
    with open(path, "wb") as f:
        f.write(main)
    print(f"{path}: {len(verts)} verts, {len(tris)} tris, {len(main)} bytes")

# --- Goat (MC proportions; model ~4.5 units tall = 1 node) ---
GOAT = [
    ((-0.9, 1.0, -1.2), (0.9, 2.8, 1.2)),      # body
    ((-0.45, 2.8, 1.2), (0.45, 3.9, 2.6)),     # head (front = +z)
    ((-0.35, 3.9, 1.6), (-0.05, 4.5, 1.9)),    # horn L
    ((0.05, 3.9, 1.6), (0.35, 4.5, 1.9)),      # horn R
    ((-0.75, 0.0, -0.9), (-0.4, 1.0, -0.5)),   # leg FL
    ((0.4, 0.0, -0.9), (0.75, 1.0, -0.5)),     # leg FR
    ((-0.75, 0.0, 0.5), (-0.4, 1.0, 0.9)),     # leg BL
    ((0.4, 0.0, 0.5), (0.75, 1.0, 0.9)),       # leg BR
]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "mcl_mobs_addon_goat.b3d"
    write_b3d(out, GOAT)

# --- Armadillo (MC 1.21; low oval body, small head + tail, 4 legs) ---
# Model ~3.0 units tall; the mob def uses visual_size 0.75 -> ~0.55 node
ARMADILLO = [
    ((-1.0, 0.9, -0.8), (1.0, 1.9, 0.8)),       # body (wide, low)
    ((-0.35, 1.0, 0.8), (0.35, 1.7, 1.6)),      # head (front = +z)
    ((-0.2, 1.0, -1.3), (0.2, 1.4, -0.8)),      # tail (back = -z)
    ((-0.9, 0.0, -0.6), (-0.5, 0.9, -0.2)),     # leg FL
    ((0.5, 0.0, -0.6), (0.9, 0.9, -0.2)),       # leg FR
    ((-0.9, 0.0, 0.2), (-0.5, 0.9, 0.6)),       # leg BL
    ((0.5, 0.0, 0.2), (0.9, 0.9, 0.6)),         # leg BR
]

# Rolled state: a tight ball (MC: the armadillo curls up)
ARMADILLO_ROLLED = [
    ((-0.8, 0.0, -0.8), (0.8, 1.6, 0.8)),
]

