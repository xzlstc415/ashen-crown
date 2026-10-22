#!/usr/bin/env python3
"""Card frames from art/frames/gold_src.png (Legendary) and purple_src.png (one-copy class Epic): a thin bar
with a medallion at the top-left corner, transparent in the middle already.

Each is resized vertically so the inner opening has the card's 10:15.6 ratio, and the opening (found by
scanning the alpha from the centre) plus the medallion's centre are written to art/frames/geometry.json; the
renderers map the opening onto the card's edge and put the cost gem on the medallion. Writes
ios/Ruinaccord/Assets.xcassets/Frames/frame_*.imageset/frame_*.png (512 wide) and img/frame_*.png (384 wide).
Needs Pillow and numpy:  python3 -m venv .venv && .venv/bin/pip install pillow numpy
"""
import json, pathlib
from PIL import Image
import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
RATIO = 15.6 / 10
# The medallion's centre in each source, in pixels (the cost gem sits there).
MEDAL = {"gold": (300, 192), "purple": (248, 183)}
geo = {}

for name in ("gold", "purple"):
    im = Image.open(ROOT / f"art/frames/{name}_src.png").convert("RGBA")
    a = np.array(im); al = a[..., 3] > 120
    H, W = al.shape
    xs = np.where(al[H // 2])[0]; x0, x1 = int(xs[xs < W // 2].max()) + 1, int(xs[xs > W // 2].min())
    ys = np.where(al[:, (x0 + x1) // 2])[0]; y0, y1 = int(ys[ys < H // 2].max()) + 1, int(ys[ys > H // 2].min())
    # alpha never quite reaches 255 in the source; make the solid parts solid
    a[..., 3] = np.where(a[..., 3] >= 248, 255, a[..., 3])
    im = Image.fromarray(a)
    f = (x1 - x0) * RATIO / (y1 - y0)
    H2 = int(round(H * f)); im = im.resize((W, H2), Image.LANCZOS)
    y0, y1 = y0 * f, y1 * f
    mx, my = MEDAL[name][0], MEDAL[name][1] * f
    geo[name] = {"aspect": W / H2, "x0": x0 / W, "x1": x1 / W, "y0": y0 / H2, "y1": y1 / H2,
                 "mx": (mx - x0) / (x1 - x0), "my": (my - y0) / (y1 - y0)}
    ios = ROOT / f"ios/Ruinaccord/Assets.xcassets/Frames/frame_{name}.imageset/frame_{name}.png"
    im.resize((512, int(round(512 * H2 / W))), Image.LANCZOS).save(ios, optimize=True)
    im.resize((384, int(round(384 * H2 / W))), Image.LANCZOS).save(ROOT / f"img/frame_{name}.png", optimize=True)
    print(name, f"{W}x{H2}", {k: round(v, 4) for k, v in geo[name].items()})

(ROOT / "art/frames/geometry.json").write_text(json.dumps(geo, indent=1))
