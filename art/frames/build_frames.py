#!/usr/bin/env python3
"""Card frames from art/frames/frames_src.png (gold Legendary frame left, purple one-copy Epic frame right).

The middle of each frame is cut out by brightness (dark interior -> transparent, bright ornament -> opaque)
inside the inner opening, then two straight-edge bands are duplicated so the OPENING has the card's 10:15.6
ratio: the frame is drawn with its opening on the card's edge, the ornaments hanging outside (the printed
geometry goes into CardView.swift / the .card.leg CSS). Writes ios/Ruinaccord/Assets.xcassets/Frames/frame_*.imageset/frame_*.png (512 wide) and
img/frame_*.png (384 wide). Needs Pillow and numpy:  python3 -m venv .venv && .venv/bin/pip install pillow numpy
"""
import pathlib
from PIL import Image, ImageFilter
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = Image.open(ROOT / "art/frames/frames_src.png").convert("RGBA")
W, H = SRC.size
RATIO = 10 / 15.6

def process(name, half, rect, lo, hi, bands):
    im = SRC.crop(half)
    a = np.array(im).astype(np.float32)
    lum = 0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]
    x0, y0, x1, y1 = rect
    cut = np.clip((lum - lo) / (hi - lo), 0, 1)
    mask = np.zeros_like(lum); mask[y0:y1, x0:x1] = 1
    mask = np.array(Image.fromarray((mask * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10))).astype(np.float32) / 255
    a[..., 3] = a[..., 3] * (1 - mask) + a[..., 3] * cut * mask
    a[..., 3] = np.where(a[..., 3] >= 248, 255, a[..., 3])
    arr = a.astype(np.uint8)
    w, h = arr.shape[1], arr.shape[0]
    extra = int(round((x1 - x0) / RATIO)) - (y1 - y0); per = extra // len(bands)
    pieces, prev = [], 0
    for i, y in enumerate(bands):
        pieces.append(arr[prev:y]); n = per if i < len(bands) - 1 else extra - per * (len(bands) - 1)
        pieces.append(arr[y - n // 2:y - n // 2 + n]); prev = y
    pieces.append(arr[prev:])
    out = Image.fromarray(np.concatenate(pieces, axis=0))
    ow, oh = out.size
    print(f"{name}: image {ow}x{oh}, opening x {x0/ow:.4f}..{x1/ow:.4f}  y {y0/oh:.4f}..{(y1+extra)/oh:.4f}")
    ios = ROOT / f"ios/Ruinaccord/Assets.xcassets/Frames/frame_{name}.imageset/frame_{name}.png"
    out.resize((512, int(512 / RATIO)), Image.LANCZOS).save(ios, optimize=True)
    out.resize((384, int(384 / RATIO)), Image.LANCZOS).save(ROOT / f"img/frame_{name}.png", optimize=True)
    print(name, out.size, "->", ios.name, f"img/frame_{name}.png")

process("gold", (0, 0, W // 2, H), (150, 150, 625, 840), 105, 170, [330, 720])
process("purple", (W // 2, 0, W, H), (135, 125, 640, 855), 80, 140, [330, 720])
