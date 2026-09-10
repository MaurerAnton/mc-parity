#!/usr/bin/env python3
"""Paint the disc-5 pair as RGBA PNGs (no PIL needed).
- disc_fragment_5.png (16x16): teal shard with lighter facet
- record_5.png (16x16): dark disc label with teal ring
Run from the repo root:  python3 tools/paint_disc5.py
"""
import struct, zlib

def write_png(path, w, h, px):  # px: list of (r,g,b,a) rows*cols
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
    raw = b"".join(b"\x00" + b"".join(struct.pack("BBBB", *p) for p in row) for row in px)
    png = (b"\x89PNG\r\n\x1a\n"
           + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
           + chunk(b"IDAT", zlib.compress(raw))
           + chunk(b"IEND", b""))
    open(path, "wb").write(png)
    print(f"{path}: {w}x{h} {len(png)} bytes")

def blank():
    return [[(0, 0, 0, 0)] * 16 for _ in range(16)]

TEAL = (63, 185, 165, 255)      # disc-5 teal
TEAL_L = (140, 230, 215, 255)   # facet highlight
TEAL_D = (28, 110, 98, 255)     # shade
DARK = (24, 24, 28, 255)        # label base

# fragment: angular shard, teal with a light facet + dark edge
f = blank()
shard = [(7, 2), (8, 2), (6, 3), (7, 3), (8, 3), (9, 3), (5, 4), (6, 4),
         (7, 4), (8, 4), (9, 4), (5, 5), (6, 5), (7, 5), (8, 5), (9, 5),
         (4, 6), (5, 6), (6, 6), (7, 6), (8, 6), (9, 6), (4, 7), (5, 7),
         (6, 7), (7, 7), (8, 7), (5, 8), (6, 8), (7, 8), (8, 8), (6, 9),
         (7, 9), (6, 10), (7, 10), (10, 6), (10, 7), (9, 9), (8, 10)]
for x, y in shard:
    f[y][x] = TEAL
for x, y in [(6, 4), (7, 4), (6, 5), (5, 6), (6, 6)]:
    f[y][x] = TEAL_L
for x, y in [(9, 3), (9, 4), (9, 5), (9, 6), (8, 8), (7, 10)]:
    f[y][x] = TEAL_D
write_png("textures/mc_parity_disc_fragment_5.png", 16, 16, f)

# label: dark disc with teal ring + center hole
r = blank()
for y in range(16):
    for x in range(16):
        dx, dy = x - 7.5, y - 7.5
        d2 = dx * dx + dy * dy
        if d2 <= 49:  # disc face (r=7)
            c = DARK
            if 20 <= d2 <= 30:  # teal ring
                c = TEAL
            if d2 <= 4:  # center hole
                c = (0, 0, 0, 0)
            r[y][x] = c
write_png("textures/mc_parity_record_5.png", 16, 16, r)
