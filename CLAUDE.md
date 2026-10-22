# Ruinaccord

Web card game (`src/game.html`, built by `python3 src/build.py`, served by GitHub Pages at
https://ruinaccord.hermes-eris.com) and a native SwiftUI iOS app in `ios/` (see `ios/README.md`).

## Releasing the iOS app

Release to TestFlight only when the user asks for it (never automatically after a push; since
2026-10-22 the user decides when a build goes out). When asked, from a clean tree:

```sh
scripts/testflight.sh            # next patch version
scripts/testflight.sh 2.1.0      # a chosen version
```

It raises MARKETING_VERSION in `ios/project.yml`, archives, uploads to TestFlight, then commits
"Release x.y.z", tags `vx.y.z` and pushes. The build number is the time. The tree must be clean.
Web-only changes (site, privacy page) need no release.
