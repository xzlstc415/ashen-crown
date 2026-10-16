# Ruinaccord

Web card game (`src/game.html`, built by `python3 src/build.py`, served by GitHub Pages at
https://ruinaccord.hermes-eris.com) and a native SwiftUI iOS app in `ios/` (see `ios/README.md`).

## Releasing the iOS app

Whenever a push includes changes that reach the iOS app (anything under `ios/`, or card data in
`src/game.html` after running `node ios/tools/gen_data.mjs`), release right after pushing:

```sh
scripts/testflight.sh            # next patch version
scripts/testflight.sh 2.1.0      # a chosen version
```

It raises MARKETING_VERSION in `ios/project.yml`, archives, uploads to TestFlight, then commits
"Release x.y.z", tags `vx.y.z` and pushes. The build number is the time. The tree must be clean.
Web-only changes (site, privacy page) need no release.
