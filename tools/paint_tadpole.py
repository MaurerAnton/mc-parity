#!/usr/bin/env python3
"""Paint tadpole-chain textures as RGBA PNGs (no PIL needed).
- tadpole.png (16x16): dark olive body, lighter belly, translucent tail
- frogspawn.png (16x16): tan jelly cluster with dark egg dots
- bucket_tadpole.png (16x16): iron bucket, water top, tadpole squiggle
Run from the repo root:  python3 tools/paint_tadpole.py
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

def blank(w, h):
    return [[(0, 0, 0, 0)] * w for _ in range(h)]

BODY = (74, 84, 48, 255)        # dark olive
BELLY = (150, 158, 110, 255)    # pale olive
TAIL = (74, 84, 48, 140)        # translucent tail
JELLY = (196, 178, 132, 255)    # tan jelly
EGG = (46, 44, 34, 255)         # dark egg dot
IRON = (150, 150, 156, 255)     # bucket iron
IRON_D = (96, 96, 104, 255)     # bucket shade
WATER = (52, 95, 218, 255)      # bucket water

# tadpole body (16x16): round head left, tapering tail right
t = blank(16, 16)
for y in range(16):
    for x in range(16):
        dx, dy = x - 5, y - 8
        if dx * dx + dy * dy <= 16:          # head-body disc (r=4)
            t[y][x] = BELLY if dy > 1 else BODY
        elif 6 <= x <= 14 and abs(y - 8) <= max(0, 3 - (x - 6) // 3):
            t[y][x] = TAIL                    # tapering tail
write_png("textures/mc_parity_tadpole.png", 16, 16, t)

# frogspawn (16x16): jelly bed + 7 dark eggs
f = blank(16, 16)
eggs = [(4, 4), (9, 3), (12, 7), (6, 9), (10, 11), (3, 12), (12, 12)]
for y in range(16):
    for x in range(16):
        f[y][x] = JELLY
for ex, ey in eggs:
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if abs(dx) + abs(dy) <= 1:
                f[ey + dy][ex + dx] = EGG
write_png("textures/mc_parity_frogspawn.png", 16, 16, f)

# tadpole bucket (16x16): iron pail, water line, tadpole squiggle
b = blank(16, 16)
for y in range(16):
    for x in range(16):
        if 3 <= x <= 12:
            if y <= 1:
                b[y][x] = IRON_D               # rim
            elif 2 <= y <= 5:
                b[y][x] = WATER                # water top
            elif 6 <= y <= 14:
                b[y][x] = IRON if x in (3, 12) else IRON_D  # walls+shade
            elif y == 15:
                b[y][x] = IRON_D               # base
# tadpole squiggle in the water
for x, y in [(5, 3), (6, 4), (7, 3), (8, 4), (9, 3)]:
    b[y][x] = EGG
write_png("textures/mc_parity_bucket_tadpole.png", 16, 16, b)
