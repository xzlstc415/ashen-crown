# Deck simulator

Headless AI-vs-AI duels on the iOS engine (`ios/Ruinaccord/Game/Engine.swift`), for finding strong decks and
talents. `build.sh` compiles the engine for the Mac and rewrites the shipped AI (`AI.swift`) so it plays whichever
side's turn it is; games follow `GameVM.aiTurn` without the animations (quick play, hard, 30 Health, 5-card hands,
both sides mulligan like the AI, a draw after 60 rounds).

```sh
sim/build.sh
sim/.build/sim search -rounds 30 -out sim/.build   # improve champions.json (resumes from it)
sim/.build/sim matrix -games 50 -out sim/.build    # every pair of champions, 50 games each
```

An archetype is a class and the page of its tier-4 talent; tiers 1-3 may come from either page. Each search step
tries mutants of an archetype's champion (1-3 card swaps and/or one talent changed; every 5th round all 144
talent sets for the current deck) against the champions of the other five classes, re-tests the best three and
the champion on a fresh run, and keeps a challenger only when it wins clearly. Strength here means strength as
played by the game's AI.

`python3 sim/export.py` writes `best_decks.json` (the latest result, with names) from the matrix.
