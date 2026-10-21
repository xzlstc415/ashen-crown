#!/usr/bin/env python3
"""Card paintings -> game assets.

Put a painting in art/raw/ named after the card id (knight.png, frostbolt.jpg, ...), then run
    python3 art/build_art.py
It crops each image to the card's 2:3 shape (keeping the top, where faces usually are) and writes
    img/cards/<id>.jpg                                       360x540, for the website
    ios/Ruinaccord/Assets.xcassets/Paint/paint_<id>.imageset  600x900, for the app
Cards without a painting keep their vector art. Afterwards run python3 src/build.py (site) and rebuild the app.
Uses macOS `sips`, so no extra tools are needed.
"""
import json, pathlib, subprocess, shutil, tempfile, sys

root = pathlib.Path(__file__).resolve().parent.parent
raw = root / 'art' / 'raw'
web = root / 'img' / 'cards'
ios = root / 'ios' / 'Ruinaccord' / 'Assets.xcassets' / 'Paint'
ids = {c['id'] for c in json.loads((root / 'ios' / 'Ruinaccord' / 'Resources' / 'GameData.json').read_text())['cards']}
# Beta-only cards (/beta/ page) get the web image only; the app does not have them yet.
import re
beta = set(re.findall(r"^\s+(\w+):\{beta:1,", (root / 'src' / 'game.html').read_text(), re.M))

def sips(*a):
    subprocess.run(['sips', *map(str, a)], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def size(p):
    out = subprocess.check_output(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(p)]).decode()
    v = dict(l.split(':') for l in out.splitlines()[1:] if ':' in l)
    return int(v['  pixelWidth'] if '  pixelWidth' in v else v['pixelWidth']), int(v['  pixelHeight'] if '  pixelHeight' in v else v['pixelHeight'])

web.mkdir(parents=True, exist_ok=True)
ios.mkdir(parents=True, exist_ok=True)
(ios / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}, 'properties': {'provides-namespace': False}}, indent=2))
done = set()
with tempfile.TemporaryDirectory() as tmp:
    for src in sorted(raw.glob('*')):
        if src.suffix.lower() not in ('.png', '.jpg', '.jpeg', '.webp'):
            continue
        k = src.stem
        if k not in ids and k not in beta:
            print(f'skip {src.name}: no card with id "{k}"', file=sys.stderr)
            continue
        t = pathlib.Path(tmp) / f'{k}.png'
        sips('-s', 'format', 'png', src, '--out', t)
        w, h = size(t)
        if w * 3 > h * 2:      # too wide: trim the sides
            nw = round(h * 2 / 3); sips('-c', h, nw, '--cropOffset', 0, (w - nw) // 2, t)
        elif w * 3 < h * 2:    # too tall: trim mostly from the bottom
            nh = round(w * 3 / 2); sips('-c', nh, w, '--cropOffset', round((h - nh) * 0.3), 0, t)
        sips('-z', 540, 360, '-s', 'format', 'jpeg', '-s', 'formatOptions', 68, t, '--out', web / f'{k}.jpg')
        done.add(k)
        if k not in ids: continue
        d = ios / f'paint_{k}.imageset'
        shutil.rmtree(d, ignore_errors=True); d.mkdir()
        sips('-z', 900, 600, '-s', 'format', 'jpeg', '-s', 'formatOptions', 72, t, '--out', d / f'{k}.jpg')
        (d / 'Contents.json').write_text(json.dumps({'images': [{'filename': f'{k}.jpg', 'idiom': 'universal'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2))
# paintings whose source was removed
for f in web.glob('*.jpg'):
    if f.stem not in done: f.unlink()
for d in ios.glob('paint_*.imageset'):
    if d.name[6:-9] not in done: shutil.rmtree(d)
print(f'{len(done)} paintings: {", ".join(sorted(done)) or "none"}')
