# Ruinaccord

A fantasy card duel game for phones and browsers. Pick one of six classes, fight through an eight-foe Adventure, or build a 25-card deck and face a random AI in Quick Match, or play a friend online with a room code. Plays in English, Chinese and Japanese.

Live: https://ruinaccord.hermes-eris.com

## Layout
- `src/game.html` — the whole game (HTML, CSS and JavaScript in one file). Edit this.
- `src/build.py` — wraps the game into the site: writes `index.html` and `sw.js` in the repo root.
- `src/sw.template.js` — offline service worker template (cache name is stamped per build).
- `peerjs.min.js` — PeerJS 1.5.4 client for Play a Friend (peer-to-peer; signalling via the free PeerJS cloud server). Add `?peer=host:port` to the URL to use a self-hosted PeerServer instead.
- `ios/` — native iOS app (SwiftUI; Sign in with Apple, decks in Firebase, online matchmaking). Card data and art are generated from `src/game.html` by `node ios/tools/gen_data.mjs`. See `ios/README.md`.
- `privacy.html` — privacy policy (linked from App Store Connect).
- Root: the published site (GitHub Pages serves `main` / root), icons, `manifest.webmanifest`, `CNAME`.

## Update the site
```
python3 src/build.py          # website
node ios/tools/gen_data.mjs   # iOS app card data + art (after changing cards)
git commit -am "Update game" && git push
```
