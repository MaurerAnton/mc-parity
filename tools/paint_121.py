#!/usr/bin/env python3
"""Paint 1.21 item/mob textures as RGBA PNGs (no PIL needed).
- armadillo.png  (64x64): sandy-tan shell with brown bands
- armadillo_rolled.png (32x32): same shell pattern (ball)
- armadillo_scute.png (16x16): small tan scale with darker rim
- wolf_armor.png  (16x16): tan plate with darker border + rivets
"""
import struct, zlib, os

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

def fill(px, w, h, color):
    for y in range(h):
        for x in range(w):
            px[y][x] = color

def rect(px, x0, y0, x1, y1, color):
    for y in range(max(0, y0), min(len(px), y1)):
        for x in range(max(0, x0), min(len(px[0]), x1)):
            px[y][x] = color

def banded_shell(px, w, h, base, band):
    fill(px, w, h, base)
    for i, y in enumerate(range(0, h, 8)):
        if i % 2 == 1:
            rect(px, 0, y, w, min(y + 4, h), band)

def rounded(px, w, h, color, border):
    fill(px, w, h, (0, 0, 0, 0))
    for y in range(h):
        for x in range(w):
            dx = min(x, w - 1 - x); dy = min(y, h - 1 - y)
            if dx < 2 and dy < 2:  # corner cut
                continue
            px[y][x] = border if (dx < 1 or dy < 1) else color

SHELL = (184, 138, 90, 255)      # sandy tan
BAND = (138, 90, 52, 255)        # brown band
RIM = (90, 58, 34, 255)          # dark brown

# armadillo body/shell (64x64)
a = [[(0, 0, 0, 0)] * 64 for _ in range(64)]
banded_shell(a, 64, 64, SHELL, BAND)
rect(a, 4, 4, 60, 60, (0, 0, 0, 0))  # transparent margin (paint only the center)
write_png("textures/mc_parity_armadillo.png", 64, 64, a)

# rolled ball (32x32)
r = [[(0, 0, 0, 0)] * 32 for _ in range(32)]
banded_shell(r, 32, 32, SHELL, BAND)
write_png("textures/mc_parity_armadillo_rolled.png", 32, 32, r)

# armadillo scute (16x16): tan scale, darker rim
s = [[(0, 0, 0, 0)] * 16 for _ in range(16)]
rounded(s, 16, 16, SHELL, RIM)
rect(s, 3, 5, 13, 6, RIM)  # a ridge line
write_png("textures/mc_parity_armadillo_scute.png", 16, 16, s)

# wolf armor (16x16): tan plate, darker border, rivets
wa = [[(0, 0, 0, 0)] * 16 for _ in range(16)]
rounded(wa, 16, 16, (200, 155, 90, 255), RIM)
for rx, ry in [(3, 3), (12, 3), (3, 12), (12, 12), (7, 7)]:
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if 0 <= rx + dx < 16 and 0 <= ry + dy < 16:
                wa[ry + dy][rx + dx] = RIM
    wa[ry][rx] = (220, 180, 110, 255)
write_png("textures/mc_parity_wolf_armor.png", 16, 16, wa)
