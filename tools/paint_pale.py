#!/usr/bin/env python3
"""Paint pale-garden textures as RGBA PNGs (no PIL needed).
- creaking.png (32x32): pale gray bark with dark streaks + hollow eyes
- creaking_heart.png (16x16): bark block with 3 glowing orange eyes
- resin_clump.png (16x16): molten-orange lump
- resin_brick.png (16x16): single orange brick
- resin_bricks.png (16x16): brick courses with mortar
- chiseled_resin_bricks.png (16x16): bricks with creaking-face motif
- eyeblossom_closed.png (16x16): gray-green bud on stem
- eyeblossom_open.png (16x16): orange eye bloom on stem
Run from the repo root:  python3 tools/paint_pale.py
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

BARK = (168, 168, 160, 255)     # pale gray bark
BARK_D = (110, 110, 102, 255)   # bark shade/streak
EYE = (232, 122, 28, 255)       # glowing orange (heart/eyes)
RESIN = (214, 110, 26, 255)     # molten resin orange
RESIN_L = (245, 170, 80, 255)   # resin highlight
RESIN_D = (140, 62, 14, 255)    # resin shade
MORTAR = (88, 80, 74, 255)      # mortar lines
STEM = (104, 128, 84, 255)      # eyeblossom stem
BUD = (150, 158, 132, 255)      # closed bud
BLOOM_C = (60, 44, 30, 255)     # open bloom cup
PUPIL = (30, 22, 18, 255)       # bloom pupil

# creaking skin (32x32): vertical bark streaks + hollow eye band near top
c = [[BARK] * 32 for _ in range(32)]
for x in range(32):
    if x % 7 in (2, 5):
        for y in range(32):
            c[y][x] = BARK_D
for x in range(10, 22):
    c[6][x] = PUPIL  # hollow eye band
    c[7][x] = PUPIL
write_png("textures/mc_parity_creaking.png", 32, 32, c)

# heart block (16x16): bark + 3 glowing eyes
h = [[BARK] * 16 for _ in range(16)]
for x in range(16):
    if x % 5 == 2:
        for y in range(16):
            h[y][x] = BARK_D
for ex, ey in [(4, 6), (11, 6), (7, 11)]:
    for dy in (0, 1):
        for dx in (0, 1):
            h[ey + dy][ex + dx] = EYE
write_png("textures/mc_parity_creaking_heart.png", 16, 16, h)

# resin clump (16x16): lumpy molten blob
r = [[(0, 0, 0, 0)] * 16 for _ in range(16)]
blob = [(x, y) for y in range(4, 13) for x in range(4, 12)
        if (x - 7.5) ** 2 + (y - 8) ** 2 <= 16]
for x, y in blob:
    r[y][x] = RESIN
for x, y in [(6, 6), (7, 5), (6, 7), (8, 6)]:
    r[y][x] = RESIN_L
for x, y in [(9, 10), (10, 9), (8, 11), (5, 9)]:
    r[y][x] = RESIN_D
write_png("textures/mc_parity_resin_clump.png", 16, 16, r)

# single brick (16x16): orange with rim
b = [[RESIN_D] * 16 for _ in range(16)]
for y in range(2, 14):
    for x in range(2, 14):
        b[y][x] = RESIN
for x in range(4, 8):
    b[5][x] = RESIN_L
write_png("textures/mc_parity_resin_brick.png", 16, 16, b)

# brick courses (16x16): 4 courses + mortar
k = [[MORTAR] * 16 for _ in range(16)]
for row in range(4):
    y0 = row * 4
    off = 4 if row % 2 else 0
    for y in range(y0 + 1, y0 + 4):
        for x in range(16):
            if (x + off) % 8 != 0:
                k[y][x] = RESIN
write_png("textures/mc_parity_resin_bricks.png", 16, 16, k)

# chiseled (16x16): bricks + creaking-face motif (eyes + mouth slit)
z = [[MORTAR] * 16 for _ in range(16)]
for y in range(1, 15):
    for x in range(1, 15):
        z[y][x] = RESIN
for x in range(4, 7):
    z[5][x] = PUPIL
    z[5][x + 5] = PUPIL
for x in range(5, 11):
    z[10][x] = PUPIL
write_png("textures/mc_parity_chiseled_resin_bricks.png", 16, 16, z)

# eyeblossom closed (16x16): stem + gray bud
e = [[(0, 0, 0, 0)] * 16 for _ in range(16)]
for y in range(6, 16):
    e[y][7] = STEM
    e[y][8] = STEM
for y in range(2, 7):
    for x in range(5, 11):
        if (x - 7.5) ** 2 + (y - 4.5) ** 2 <= 6:
            e[y][x] = BUD
write_png("textures/mc_parity_eyeblossom_closed.png", 16, 16, e)

# eyeblossom open (16x16): stem + orange eye bloom
o = [[(0, 0, 0, 0)] * 16 for _ in range(16)]
for y in range(6, 16):
    o[y][7] = STEM
    o[y][8] = STEM
for y in range(1, 8):
    for x in range(4, 12):
        dx, dy = x - 7.5, (y - 4.5) * 1.2
        if dx * dx + dy * dy <= 9:
            o[y][x] = EYE
for y in range(3, 6):
    for x in range(6, 10):
        if (x - 7.5) ** 2 + ((y - 4.5) * 1.2) ** 2 <= 2.5:
            o[y][x] = PUPIL
write_png("textures/mc_parity_eyeblossom_open.png", 16, 16, o)
