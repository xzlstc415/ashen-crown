#!/usr/bin/env python3
"""Build the site (index.html, sw.js in the repo root) from src/game.html.
Usage: python3 src/build.py   -> writes index.html (+ bumps the service-worker cache)."""
import re, hashlib, pathlib
here = pathlib.Path(__file__).parent
src = (here / 'game.html').read_text()
site = here.parent
title_end = src.index('</title>') + len('</title>')
body = src[title_end:]
# the game file starts with <title>, meta tags, font links and <style>; keep them inside <head>
head_part, rest = body.split('</style>', 1)
head = f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Ruinaccord</title>
<meta name="description" content="A fantasy card duel game. Pick a class, build a deck, and fight your way to the Ashen Crown. Plays in English, Chinese and Japanese.">
<meta name="theme-color" content="#141118">
<meta name="color-scheme" content="dark">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Ruinaccord">
<meta property="og:title" content="Ruinaccord">
<meta property="og:description" content="A fantasy card duel game for your phone and browser.">
<meta property="og:image" content="https://ruinaccord.hermes-eris.com/icon-512.png">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" href="icon.svg" type="image/svg+xml">
<link rel="icon" href="icon-192.png" sizes="192x192" type="image/png">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
{head_part.replace('<meta name="claude:viewport-fit-sides" content="cover">','').strip()}
/* standalone page: safe areas top and bottom (the artifact viewer supplied these before) */
:root{{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}}
body{{margin:0;font-size:15px}}
[hidden]{{display:none!important}}
</style>
</head>
<body>'''
html = head + rest.rstrip() + '''
<script>
if('serviceWorker' in navigator && location.protocol==='https:'){
  addEventListener('load',()=>navigator.serviceWorker.register('sw.js').catch(()=>{}));
}
</script>
</body>
</html>
'''
(site / 'index.html').write_text(html)
ver = hashlib.sha1(html.encode()).hexdigest()[:10]
sw = (here / 'sw.template.js').read_text().replace('__VERSION__', ver)
(site / 'sw.js').write_text(sw)
print('built index.html', len(html), 'bytes; cache version', ver)
