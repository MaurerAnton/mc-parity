#!/usr/bin/env python3
"""Generate the heavy core block textures (MC 1.21.5; neither game has the
block and Pixel-Perfection-Legacy has no heavy_core.png yet).

Emits 16x16 RGBA PNGs: mc_parity_heavy_core_{top,bottom,side}.png
in ../textures/. Uses the pure-Python PNG writer from paint_121.py.
Design: dark metal block with a lighter "core" plate and ring, matching
the vanilla look (dark iron block, inset lighter core).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from paint_121 import write_png, fill, rect, rounded

W = H = 16
BASE = (62, 62, 66, 255)        # dark metal
FRAME = (36, 36, 40, 255)       # darker frame
CORE = (96, 96, 102, 255)       # lighter core plate
CORE_HI = (150, 150, 158, 255)  # center highlight
BAND = (84, 84, 90, 255)        # side band

def block_top():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    fill(px, W, H, BASE)
    rect(px, 0, 0, W, 1, FRAME)
    rect(px, 0, H - 1, W, H, FRAME)
    rect(px, 0, 0, 1, H, FRAME)
    rect(px, W - 1, 0, W, H, FRAME)
    # inset core plate (rounded)
    rounded(px, W, H, CORE, CORE)
    rect(px, 2, 2, W - 2, 3, CORE)
    rect(px, 2, H - 3, W - 2, H - 2, CORE)
    rect(px, 2, 2, 3, H - 2, CORE)
    rect(px, W - 3, 2, W - 2, H - 2, CORE)
    # center highlight
    rect(px, 6, 6, 10, 10, CORE_HI)
    return px

def block_bottom():
    # same as top but without the center highlight (sits on the ground)
    px = block_top()
    rect(px, 6, 6, 10, 10, CORE)
    return px

def block_side():
    px = [[(0, 0, 0, 0)] * W for _ in range(H)]
    fill(px, W, H, BASE)
    rect(px, 0, 0, W, 1, FRAME)
    rect(px, 0, H - 1, W, H, FRAME)
    rect(px, 0, 0, 1, H, FRAME)
    rect(px, W - 1, 0, W, H, FRAME)
    # horizontal band around the middle (the "core" seen from the side)
    rect(px, 1, 6, W - 1, 10, BAND)
    # band inner highlight
    rect(px, 1, 7, W - 1, 8, CORE)
    return px

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "textures")
write_png(os.path.join(out, "mc_parity_heavy_core_top.png"), W, H, block_top())
write_png(os.path.join(out, "mc_parity_heavy_core_bottom.png"), W, H, block_bottom())
write_png(os.path.join(out, "mc_parity_heavy_core_side.png"), W, H, block_side())
