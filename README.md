# Ashen Crown · 灰烬王冠

A fantasy card duel game for phones and browsers. Pick one of six classes, fight through an eight-foe Adventure, or build a 25-card deck and face a random AI in Quick Match, or play a friend online with a room code. Plays in English, Chinese and Japanese.

Live: https://ashen-crown.hermes-eris.com

## Layout
- `src/game.html` — the whole game (HTML, CSS and JavaScript in one file). Edit this.
- `src/build.py` — wraps the game into the site: writes `index.html` and `sw.js` in the repo root.
- `src/sw.template.js` — offline service worker template (cache name is stamped per build).
- `peerjs.min.js` — PeerJS 1.5.4 client for Play a Friend (peer-to-peer; signalling via the free PeerJS cloud server). Add `?peer=host:port` to the URL to use a self-hosted PeerServer instead.
- Root: the published site (GitHub Pages serves `main` / root), icons, `manifest.webmanifest`, `CNAME`.

## Update the site
```
python3 src/build.py
git commit -am "Update game" && git push
```
