#!/usr/bin/env python3
"""Writes art/PROMPTS.md: one ready-to-copy image prompt per card (style direction B, see art/STYLE.md).
Card facts come from the game data (main cards from the iOS GameData.json, beta-only cards straight from
src/game.html); the scene for each card is written below. Cards that already have a picture (img/cards/ or art/raw/)
go to the end, marked available. Re-run after adding cards or paintings.

Every scene names its own camera angle and pose on purpose (see "姿态与构图" in STYLE.md): if two prompts
read alike, the paintings come out alike."""
import json, pathlib, re, subprocess
root = pathlib.Path(__file__).resolve().parent.parent

SUFFIX = ('hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, '
          'limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, '
          'no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark')
MINION = 'the face or most recognizable part in the upper third of the frame, simple ground in the lower part'
SPELL = 'the effect centered in the upper half of the frame, calm simple lower part'

# Every card, including the beta-only ones, read from the game source with beta switched on, so names and
# numbers are always the current ones.
JS = r"""
const fs=require('fs');const html=fs.readFileSync(process.argv[1],'utf8');
const a=html.indexOf('// ---------- card art ----------'),b=html.indexOf('const CBY=');
const d=new Function('ASHEN_BETA',html.slice(a,b)+'\nreturn {CARDS,CLASSES};')(true);
console.log(JSON.stringify({cards:Object.entries(d.CARDS).map(([id,c])=>({id,cost:c.c,type:c.t,atk:c.a||0,hp:c.h||0,rarity:c.r,
  cls:c.cls||null,token:!!c.token,beta:!!c.beta,names:c.n})),classes:d.CLASSES.map(c=>({id:c.id,names:c.n}))}));
"""
d = json.loads(subprocess.check_output(['node', '-e', JS, str(root / 'src/game.html')]))

S = {
# ---------------- neutral minions ----------------
'goblin': 'a skinny green goblin thief hanging upside down by his knees from a broken archway, grinning, a stolen coin purse dangling from his teeth and a small dagger in one hand, seen from below, warm firelight accent',
'apprentice': "a nervous young wizard's apprentice seen from behind and slightly above, glancing back over his shoulder in panic while his oversized purple hat smokes and a tiny flame sputters out of his wand, warm firelight accent",
'harpooneer': 'an elven archer seen in strict side profile facing left, kneeling on one knee on a mossy fallen column, bow fully drawn, long golden hair blowing back in the wind, soft forest green accent',
'burglar': 'a halfling burglar frozen mid-tiptoe on a rooftop ledge, caught in a beam of moonlight, eyes wide, one finger to his lips, a lumpy sack of loot over his shoulder, seen from a low angle, cool moonlight accent',
'geomancer': 'a gnome geomancer woman seen from above, sitting cross-legged on the ground with both palms pressed flat, glowing cracks spreading outward from her hands and pebbles floating up around her blue hat, arcane violet accent',
'eel': 'an orc raider caught at the top of a leap over a broken gate, body twisted mid-air, axe swung back, black mohawk and war paint, dynamic foreshortened view from below, ember red-orange accent',
'alchemist': 'a small gnome alchemist peering one-eyed through a bubbling purple potion held up to the light, goggles pushed up into wild orange hair, the potion lighting her face from below, close-up, violet accent',
'lurker': 'a big hunched forest troll leaning lazily against a ruined pillar, picking its tusk with a twig, club resting on the ground, moss on its shoulders, seen in three-quarter view facing right, forest green accent',
'diver': 'an old gnome tinkerer lying on his back underneath a sputtering clockwork contraption, only his white beard, red pointed hat and a giant wrench poking out, sparks raining down, seen from the side, warm brass accent',
'hexer': 'an orc hexer shaman crouched over a small fire, face hidden behind a bone mask, blowing green curse smoke that curls up into the shape of a skull, seen from a high angle, sickly green accent',
'golem': 'a massive stone golem made of carved temple blocks seen from a worm\'s-eye angle, filling the doorway it guards, glowing blue rune eyes looking straight down at the viewer, tiny birds nesting on its shoulder, cool blue accent',
'shark': 'a towering hairless rune giant seen from far away and below, striding over the ruins toward the right edge, glowing blue rune tattoos, a stone club dragging behind it, clouds at its waist, cool blue rune accent',
'firelem': 'a fire elemental bursting up out of a cracked forge floor, arms flung wide, flames streaming upward like hair, molten core in its chest, seen head-on, bright orange fire accent',
'axethrower': 'a broad-shouldered orc in a dented iron helm caught mid-throw, one arm whipped forward as a spinning hand axe leaves his fingers toward the viewer, a second axe ready at his belt, seen from a low front angle, rust orange accent',
'ogre': 'a huge dim-witted ogre brute sitting on a flattened wagon, scratching his head with a giant wooden club, a confused frown and a single tooth, patched leather clothes, seen in three-quarter view facing left, warm firelight accent',
'wyvern': 'a rider on a green wyvern banking hard in a steep dive, seen from above and behind so the wings fill the frame, rider leaning forward with a spear, wind streaks, sky blue accent',
'treant': 'an ancient treant slowly turning its mossy face toward the viewer, half of its body still part of a ruined wall, roots and branches tangled through broken stone, fireflies around, soft forest green accent',
'dragonknight': 'a knight in dark red dragon-scale armor seen from behind on a cliff edge, cape flowing, a small red dragon perched on his raised fist and roaring at the sky, ember orange accent',
# ---------------- legendary minions ----------------
'leviathan': 'an enormous ash-grey dragon with glowing molten cracks along its scales, wings spread wide, coiled protectively on top of a ruined cathedral tower, breathing a sweeping wave of fire downward, warm firelight accent',
'lich': 'Malakar the lich king seen from a low angle, floating above a crumbling crypt with his ragged purple robe billowing upward, arms spread, a crown of green flame, green soulfire spiraling around him, fel green accent',
'dwarfking': 'Thorgrim the dwarf king leaning forward on his stone throne, elbows on knees, glaring straight at the viewer, enormous braided orange beard spilling over a great axe across his lap, golden crown, golden accent',
'elfqueen': 'Sylvara the elf queen walking away through a field of flowers that bloom where she steps, turning her head to look back over her shoulder, long pale golden hair, leaf crown, staff of living wood, forest green accent',
# ---------------- class minions ----------------
'knight': 'a female paladin knight in polished silver plate armor with gold trim, open-face helm, a radiant golden halo behind her head, white tabard with a gold sun emblem, raising a big kite shield with a glowing gold sunburst, standing firm on cracked steps, glowing holy gold accent',
'direwolf': 'a big grey dire wolf with a thick mane and a scar over one eye, snarling and crouched to pounce on a broken stone ledge, eyes reflecting firelight, warm firelight accent',
'pearl': 'a young temple acolyte seen from above, kneeling on a cracked mosaic floor with her eyes closed in prayer, a soft bubble of pale light rising around her like a soap bubble, warm holy light accent',
'crab': 'a short stocky dwarf seen almost entirely from behind his huge battered round shield, only his braided red beard, helmet and one squinting eye peeking over the rim, arrows stuck in the shield, warm firelight accent',
'cleric': 'a jolly dwarven cleric mid-laugh, head thrown back, raising a mug of ale in one hand while a big warhammer rests on his shoulder, holy symbol swinging on his chest, seen in three-quarter view facing right, warm golden light accent',
'berserker': 'an orc berserker charging straight at the viewer, extreme foreshortening, huge axe swinging overhead, horned helmet, mouth open in a roar, flecks of dirt flying, ember red-orange accent',
'sailor': 'a hunched skeletal grave thrall dragging itself up out of an open grave, one bony hand on the rim, dented helmet slipping over glowing green eyes, rusty sword in its teeth, seen from above, pale green accent',
'beastcaller': 'an elven beastcaller sitting on a fallen log with a wolf\'s head resting in her lap, whistling softly with two fingers, leaves swirling, seen from the side, forest green accent',
'ghoul': 'a gaunt grey barrow ghoul seen from inside a dark tomb looking out, clinging to the ceiling of the entrance upside down, long claws and hungry yellow eyes, pale sickly green accent',
'gull': 'a griffon rider landing hard on a ruined bell tower, the griffon rearing with wings spread wide and golden feathers flaring, rider pointing a lance down at the viewer, low angle, warm sunrise accent',
'commander': 'a veteran knight commander seen from behind his troops, standing on a broken wall and turning back to shout an order, red and gold armor, war banner snapping in the wind, warm golden accent',
'archmage': 'an old archmage woman sitting in mid-air with her legs crossed, reading one book while a whirlwind of open books orbits around her, silver hair, tall blue hat, staff floating beside her, arcane blue accent',
'priestess': 'a serene temple priestess walking toward the viewer down a ruined aisle, scattering petals of golden light from an open palm, white robes trailing, golden circlet, holy gold accent',
'necro': 'a hooded necromancer kneeling on a graveyard path, tapping the earth with a staff topped by a green gem, ghostly hands rising out of the soil toward him, seen from a high angle, eerie green accent',
'thane': 'a proud dwarf thane striding toward the left edge with a great hammer slung across both shoulders, winged helmet, heavy gold-trimmed armor, a stone hall gate behind him, seen from a low angle, warm golden accent',
'wyrmling': 'a small blue mana wyrmling curled in a loop around a floating glowing rune, chewing on its corner, big curious eyes looking at the viewer, top-down view, arcane violet accent',
'spellbreaker': 'an elven spellbreaker in crimson armor caught mid-spin, her slim sword slicing clean through a glowing magic sigil that shatters into shards around her, motion blur on the blade, crimson red accent',
# ---------------- neutral spells ----------------
'retreat': 'a soldier vanishing backward into a puff of grey smoke, only his raised shield and one boot still visible, a trail of footprints leading out of the frame, cool blue accent',
'tidepool': 'an old open book seen from directly above on a stone desk, golden symbols lifting off the blank pages like moths and flying toward a single candle, warm candle light accent',
'undertow': 'a giant hammer made of golden light smashing down onto a monster from the side, cracks and dust spreading across the stone floor, close side view, holy gold accent',
'radiant': 'a burst of radiant golden light exploding outward in a star shape from a cracked altar, warm rays sweeping across the ruins, holy gold accent',
'hymn': 'a ring of soldiers seen from below, arms around each other\'s shoulders, singing up into the sky under a waving banner, notes of light rising, warm golden accent',
'breath': 'a huge dragon head seen from the side breathing a wide stream of fire across the frame, ember red-orange accent',
'coin': 'a single gold coin spinning on its edge on a tavern table, caught at a tilt, sparkles flying, warm golden accent',
# ---------------- warrior ----------------
'innerrage': 'a close-up of a warrior\'s clenched fist, cracks of red light glowing through the skin between the knuckles, steam rising, ember red-orange accent',
'whirlwind': 'a warrior seen from directly above spinning with a giant two-handed axe, a red ring of steel and dust around him, ember red-orange accent',
'shieldslam': 'a heavy shield slammed into the ground in front of the viewer, a red shockwave ring blasting outward and knocking debris into the air, low angle, ember red-orange accent',
'execute': 'a heavy executioner axe coming down in a bright red arc, the edge glowing, ember red-orange accent',
'frenzy': 'a warrior with his back to the viewer, arms thrown wide, a red battle-rage aura erupting upward like a bonfire, ember red-orange accent',
'shieldwall': 'a warrior in a wide braced stance while dozens of loose iron plates fly in from every direction and clamp onto his body like magnets, overlapping into scale armor, front view with motion streaks, iron grey and ember orange, no shield',
# ---------------- mage ----------------
'frostbolt': 'a jagged bolt of glowing ice flying toward the viewer, trailing frost crystals and cold mist, a gloved hand at the bottom edge just releasing it, glowing icy blue and arcane violet accent',
'missiles': 'three glowing arcane orbs zigzagging toward the viewer like fireflies, each leaving a curly violet trail, arcane violet accent',
'mirror': 'a mage standing between two tall shards of floating ice, each shard reflecting a different version of her stepping out of it, icy blue and arcane violet accent',
'frostnova': 'a ring of ice exploding outward from the ground seen from directly above, frost spikes radiating like a snowflake, icy blue and arcane violet accent',
'lance': 'a long spear of pure arcane energy flying forward, violet sparks and stars trailing behind, arcane violet accent',
'maelstrom': 'a big ball of fire spinning toward the viewer, flames swirling around it, bright orange fire accent',
# ---------------- paladin ----------------
'squires': 'two eager young squires tumbling over each other as they run toward the left edge, oversized helmets falling over their eyes, wooden shields and a bucket, golden light behind them, holy gold accent',
'calltoarms': 'a farmer on a rooftop blowing a battle horn, seen from behind, while villagers with pitchforks and old helmets pour into the square below, warm sunrise accent',
'humility': 'a huge armored brute seen from behind, kneeling as its enormous shadow shrinks to a tiny shape under a small glowing hand held up in front of it, holy gold accent',
# The four defensive blessings each get their own shape: a rooted tower shield, a falling feather bubble,
# whispered ribbons (priest) and a descending crown. Keep them apart.
'brace': 'a battered wooden tower shield planted in cracked ground, golden roots of light growing out of the earth and wrapping around it to anchor it in place, a gauntleted hand pressing against its back, low angle, amber and gold',
'aegis': 'a single glowing golden feather drifting down onto a sleeping squire\'s shoulder, and where it touches a thin iridescent soap-bubble sphere blooming around him, top-down view, holy gold and pale pink, no shield, no armor plates',
'kings': 'a crown of light descending from above onto a kneeling soldier who looks up in awe, a royal cloak of deep red and gold light unfurling from his shoulders, low angle, regal crimson and gold, no shield',
# ---------------- hunter ----------------
'pounce': 'a big spotted cat mid-leap from a high branch straight down at the viewer, claws out, leaves exploding around it, steep high angle, forest green accent',
'spray': 'an arrow made of violet runes splitting apart mid-flight into a spiral of tiny glowing glyphs, seen in side view against a dark night sky, no archer visible, violet and forest green accent',
'huntmark': 'a view through a narrow gap in the leaves at a large monster in the distance, a glowing green target ring painted onto it, forest green accent',
'killcmd': 'a wolf leaping past the viewer\'s shoulder toward an enemy in the distance, a hunter\'s outstretched pointing arm at the edge of the frame, forest green accent',
'hounds': 'a pack of lean hunting hounds bursting through a broken gate straight toward the viewer, dust flying, forest green accent',
'riptide': 'the moment after: a single black-fletched arrow buried deep in a giant\'s cracked stone breastplate, the giant toppling backward in silhouette, seen from far below, deep red and forest green accent',
# ---------------- priest ----------------
'pwshield': 'a priest whispering into cupped hands, the whispered breath turning into long pale ribbons of light that wind around a distant soldier like bandages, side view, pale white-gold and soft blue, no shield, no bubble',
'holysmite': 'a small sun of white light dropping like a falling star onto a target, bright flare, pale white-gold accent',
'dispel': 'an open palm pushing through a glowing magic sigil, the sigil breaking apart into fading paper-like flakes, quiet and calm, pale white-gold accent',
'mend': 'a macro close-up of a cracked armored forearm, liquid golden light flowing into the cracks and sealing them like gold-mended pottery, holy gold accent',
'swpain': 'dark purple shadow tendrils curling around a small creature from all sides, a single whispering shadowy mouth at the edge of the frame, dark purple accent',
'swdeath': 'a pale hand pointing one finger, a thin black thread of shadow running from the fingertip straight through the heart of a huge monster, the monster fading to grey, side view, dark purple accent',
# ---------------- warlock ----------------
'darkpact': 'a glowing parchment contract floating in the dark, a skeletal hand holding a quill while a drop of blood falls from a fingertip onto it, purple shadow smoke, dark purple accent',
'soulfire': 'a warlock seen from the side hurling a ball of green-purple soulfire, the same flame crawling up his own sleeve, fel green and dark purple accent',
'coil': 'a skull-shaped bolt of shadow corkscrewing toward a small creature, a wisp of green light lifting out of the creature like a page being drawn, fel green and dark purple accent',
'raisedead': 'two skeleton hands bursting out of a grave seen from directly above, green ghostly light and dirt flying, fel green accent',
'hellfire': 'seen from a castle wall at night, green and purple meteors of hellfire falling on two armies alike, friend and foe both scattering, fel green and dark purple accent',
'inferno': 'ground-level view of a scorched black field, the last small green sapling in the foreground about to be swallowed by a low wall of flame rolling in from the horizon, charcoal and orange',
# ---------------- tokens ----------------
'bubble': 'an angry translucent blue spirit swooping diagonally across the frame with a wailing face and a long wispy tail, cold pale blue accent',
'minnow': 'a young militia recruit seen from a high angle, gripping a pitchfork too tightly, nervous but brave face looking up, simple leather vest, warm sunrise accent',
'reefling': 'a town guard seen in three-quarter view facing left, steel helmet, spear planted, one hand raised palm-out to say halt, warm firelight accent',
'elver': 'a lean brown wolf running across the frame from right to left, tongue out, eager eyes, forest green accent',
'squire': 'a small round iron golem sitting on the ground with its legs stuck straight out, glowing orange eyes, steam puffing from its head, warm brass accent',
'skeleton': 'a small rattling skeleton warrior tripping over its own rusty sword, arms flailing, green glowing eyes, goofy, fel green accent',
'mirrorimg': 'a translucent ice-blue copy of a mage seen from behind, looking at its own reflection in a puddle, calm smile, icy blue accent',
'hound': 'a small scrappy hunting hound with a red collar skidding to a stop, ears flying, seen from the front, forest green accent',
'spawn': 'a small red dragon whelp perched on a skull, puffing a tiny flame and looking surprised at it, stubby wings, ember orange accent',
# ================ beta-only cards ================
# mage · fire
'emberbolt': 'a single ember flicked off a fingertip like a coin, glowing and trailing a tiny curl of smoke, extreme close-up of the hand, bright orange fire accent',
'emberadept': 'a young fire mage girl seen from the side, burning her own notes over a candle with a satisfied smile, ashes drifting up, orange robe, bright orange fire accent',
'scorch': 'a thin searing beam of orange light cutting diagonally across the frame through the seam of a knight\'s armor, molten drips, bright orange fire accent',
'emberele': 'a hulking elemental made of glowing coals and cooling ash, crouched low like a gorilla with knuckles on the ground, embers rising from its back, seen in three-quarter view facing left, bright orange fire accent',
'phoenix': 'a phoenix made of grey ash and glowing cracks seen from directly below as it spreads its wings across the whole sky, flakes of ash falling toward the viewer, bright orange fire accent',
'firestorm': 'a firestorm seen from a hilltop, a funnel of flames coming down from red clouds onto the ruins in the valley below, bright orange fire accent',
# mage · frost
'icelance': 'a slim shard of ice spinning end over end through the air, a frozen enemy shield cracking in the background, crisp and fast, icy blue and arcane violet accent',
'icebarrier': 'a mage sitting calmly cross-legged inside a faceted crystal of ice like the inside of a geode, an enemy outside frozen mid-swing against the facets, seen from a three-quarter top view, icy blue and arcane violet accent, no shield, no bubble',
'frostele': 'a jagged frost elemental made of stacked ice crystals sitting hunched on a frozen boulder, breath steaming, frost spreading over the ground around it, seen from a low angle, icy blue and arcane violet accent',
'shatter': 'a frozen monster bursting into a thousand glittering ice shards toward the viewer, frozen in the moment of breaking, icy blue and arcane violet accent',
# priest · holy prayers
'matins': 'a small bell tower at dawn seen from far away, the first sunbeam hitting a ringing bell, birds rising, prayer beads hanging from a window in the foreground, pale white-gold accent',
'vigil': 'two tall candles on a dark ruined altar at night, each flame guarded by a small hooded figure seen from behind, deep blue night with warm candle light',
'sanctuary': 'broken chapel walls rebuilding themselves brick by brick out of translucent blocks of light around a few huddled soldiers, seen from above like a doll house with the roof off, pale white-gold accent, no shield, no bubble',
'cantor': 'a priestess conductor seen from behind, both arms raised mid-gesture, a choir of light silhouettes in front of her, musical ribbons of light, pale white-gold accent',
'requiem': 'a lone singer walking slowly along a path of floating lanterns that leads a translucent fallen soldier back from the mist, seen from the side, pale white-gold and soft blue',
'judgment': 'a huge cracked bronze bell in a ruined tower swinging toward the viewer, a ring of golden light rolling out across the land, low angle, pale white-gold accent',
'revelation': 'the clouds tearing open in a perfect circle above the ruins, a column of blinding light and wings of light pouring down, seen from far below, pale white-gold accent',
'acolyte': 'a small candlebearer in white robes walking toward the viewer, cupping a candle flame against the wind, calm face lit from below, warm candle light',
# priest · shadow
'voidacolyte': 'a hooded acolyte seen in profile with a finger to her lips, the sound around her drained away into a swirling purple hush, dark purple accent',
'wordruin': 'a cracked stone ward-tablet on a wounded monster\'s chest breaking apart under a single purple spoken shockwave, close-up, dark purple accent',
'wordtorment': 'a giant shadowy mouth opening in the sky above a battlefield, a beam of black and purple sound crushing one huge monster, seen from far away, dark purple accent',
# hunter
'steady': 'an extreme close-up of an archer\'s calm eye and cheek pressed against the taut bowstring, a single snowflake landing on her eyelash, everything else blurred, forest green accent, no arrow in flight',
'explosive': 'an arrow striking a monster and exploding into a starburst of orange sparks that spray the smaller creatures around it, forest green and orange accent',
'marksman': 'an elven marksman sitting high on a broken statue\'s shoulder, one leg dangling, sighting down an arrow at something far below, seen from a low angle, forest green accent',
'whistle': 'a small carved bone whistle on a leather cord, mid-blow, sound rings rippling out and a hound\'s ears perking up in the distance, forest green accent',
'phound': 'a scrappy pack hound sitting in tall grass in side view facing right, scratching behind its inside-out ear with a hind leg, tongue out, forest green accent',
# warlock
'bonewarr': 'a skeleton warrior assembled from mismatched bones of many creatures, standing at attention with a rusted cleaver, green fire in its eye sockets, seen from a low angle, fel green accent',
}
S = {k: v for k, v in S.items() if v}

ZH_RAR = {'c': '普通', 'r': '稀有', 'e': '史诗', 'l': '传说', 't': '衍生物'}
ZH_CLS = {c['id']: c['names'][1] for c in d['classes']}
# Pictures already made: in the game (img/cards) or generated and waiting in art/raw.
done = {p.stem for p in (root / 'img/cards').glob('*.jpg')} | {p.stem for p in (root / 'art/raw').glob('*') if p.suffix.lower() in ('.png', '.jpg', '.jpeg', '.webp')}
cards = d['cards']
missing = [c['id'] for c in cards if c['id'] not in S]
assert not missing, missing

# Prompts that read alike give pictures that look alike: list the closest pairs for a manual check.
def words(t): return set(re.findall(r"[a-z']+", t.lower())) - {'a', 'the', 'of', 'and', 'with', 'in', 'on', 'its', 'his', 'her', 'to', 'from', 'accent', 'seen'}
close = []
ids = sorted(S)
for i, x in enumerate(ids):
    for y in ids[i + 1:]:
        A, B = words(S[x]), words(S[y]); j = len(A & B) / max(1, len(A | B))
        if j >= 0.3: close.append((round(j, 2), x, y))

groups = [('中立随从', lambda c: c['type'] == 'm' and not c['token'] and not c.get('cls') and c['rarity'] != 'l'),
          ('传说随从', lambda c: c['type'] == 'm' and c['rarity'] == 'l' and not c['token']),
          ('中立法术', lambda c: c['type'] == 's' and not c['token'] and not c.get('cls'))]
groups += [(f"{c['names'][1]}职业牌", (lambda cid: lambda c: c.get('cls') == cid and not c['token'] and c['rarity'] != 'l')(c['id'])) for c in d['classes']]
groups += [('衍生物（游戏中召唤或获得的牌）', lambda c: c['token'])]

todo = [c for c in cards if c['id'] not in done]
have = [c for c in cards if c['id'] in done]
out = ['# Ruinaccord 卡牌绘图提示词', '',
       f'共 {len(cards)} 张：还要画的 {len(todo)} 张在前面，**已经有图的 {len(have)} 张放在最后**（标着 ✅ available）。标着「测试页」的是只在 /beta/ 出现的新卡。',
       '全部使用画风说明里的 **方向 B**，后缀已经接在每条后面，整段复制即可。每条都写了镜头角度、姿态和朝向，请不要删掉；'
       '如果生成出来的人物还是正面站立，在开头加一句 "dynamic pose, not standing straight, not facing the camera"。'
       '同类法术（加护甲、加生命、护盾、射箭、大火）每张都用了不同的画面比喻，提示词里写着 no shield 的就不要画盾。', '',
       '出图后把文件按标题里的文件名放进 `art/raw/`（例如 `goblin.png`），然后运行 `python3 art/build_art.py`。',
       '如果用的不是 Midjourney，删掉末尾的 `--ar 2:3 --no ...`，在工具里选竖图 2:3，并把 text、frame、border、card、letters、numbers 填进反向提示词。', '']

def section(pool, title_suffix='', mark=''):
    lines, seen = [], set()
    for title, f in groups:
        sel = [c for c in pool if f(c) and c['id'] not in seen]
        if not sel: continue
        lines += [f'## {title}{title_suffix}（{len(sel)} 张）', '']
        for c in sorted(sel, key=lambda c: (c['type'], c['cost'], c['id'])):
            seen.add(c['id'])
            kind = f"随从 {c['atk']}/{c['hp']}" if c['type'] == 'm' else '法术'
            meta = f"{c['cost']} 费 · {kind} · {ZH_RAR[c['rarity']]}" + (f" · {ZH_CLS[c['cls']]}" if c.get('cls') else '') + (' · 测试页' if c.get('beta') else '') + mark
            comp = MINION if c['type'] == 'm' else SPELL
            lines += [f"### {c['names'][1]} {c['names'][0]} — `{c['id']}.png`", meta, '```', f"{S[c['id']]}, {comp}, {SUFFIX}", '```', '']
    assert seen == {c['id'] for c in pool}, set(c['id'] for c in pool) - seen
    return lines

out += section(todo)
out += ['---', '', f'# ✅ 已经有图的卡（available，{len(have)} 张）', '',
        '这些卡的图片已经生成（在 `art/raw/` 或已经放进游戏），提示词留在这里备查；想重画时再用。', '']
out += section(have, '·已有图', ' · ✅ 已有图片 available')
(root / 'art' / 'PROMPTS.md').write_text('\n'.join(out))
print(f'wrote art/PROMPTS.md: {len(todo)} to paint, {len(have)} available ({sum(1 for c in cards if c.get("beta"))} beta-only cards)')
for j, x, y in sorted(close, reverse=True)[:12]: print('similar', j, x, y)
