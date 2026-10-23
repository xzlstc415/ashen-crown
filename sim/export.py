"""Writes sim/best_decks.json from sim/.build/matrix.json, with card and talent names (run after `sim matrix`)."""
import json, collections, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
d = json.loads((root / 'ios/Ruinaccord/Resources/GameData.json').read_text())
cards = {c['id']: c for c in d['cards']}
nodes, pages = {}, {}
for cls, pg in d['talents']['pages'].items():
    for p in pg:
        pages[(cls, p['id'])] = p['names'][1]
        for row in p['tiers']:
            for n in row: nodes[n['id']] = n['names'][1]
m = json.loads((root / 'sim/.build/matrix.json').read_text())
out = []
for a in sorted(m, key=lambda x: -x['winRate']):
    cnt = collections.Counter(a['deck'])
    out.append({**a, 'treeName': pages[(a['cls'], a['tree'])], 'talentNames': [nodes[t] for t in a['talents']],
                'deckNames': {cards[k]['names'][1]: v for k, v in sorted(cnt.items(), key=lambda kv: (cards[kv[0]]['cost'], kv[0]))}})
(root / 'sim/best_decks.json').write_text(json.dumps({'method': 'sim/README.md', 'gamesPerPair': 50, 'decks': out}, ensure_ascii=False, indent=1))
for a in out: print(f"{a['arch']:16} {a['winRate']:.3f}")
