#!/usr/bin/env python3
"""Writes art/PROMPTS.md: one ready-to-copy image prompt per card (style direction B, see art/STYLE.md).
Card facts come from the game data; the scene for each card is written below. Re-run after adding cards."""
import json, pathlib
root = pathlib.Path(__file__).resolve().parent.parent
d = json.loads((root / 'ios/Ruinaccord/Resources/GameData.json').read_text())

SUFFIX = ('hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, '
          'limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, '
          'no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark')
MINION = 'head and face in the upper third of the frame, simple ground in the lower part'
SPELL = 'the effect centered in the upper half of the frame, calm simple lower part'

S = {
# ---- neutral minions ----
'goblin': 'a skinny green goblin thief with big ears and a sly grin, clutching a stolen coin purse and a small dagger, crouching on a broken wall, warm firelight accent',
'pearl': 'a young temple acolyte in white and gold robes, eyes closed in prayer, a soft bubble of pale light shielding her, warm holy light accent',
'apprentice': "a nervous young wizard's apprentice in an oversized purple hat with singed eyebrows, a small flame sputtering from his wand, warm firelight accent",
'crab': 'a short stocky dwarf with a braided red beard hiding behind a huge battered round shield taller than himself, steady and stubborn, warm firelight accent',
'harpooneer': 'a calm elven archer with long golden hair drawing a bow, one arrow ready, standing on a mossy broken column, soft forest green accent',
'cleric': 'a jolly dwarven cleric with a grey beard, holy symbol on his chest, a big warhammer on his shoulder and a mug of ale, warm golden light accent',
'berserker': 'a wild orc berserker with green skin, horned helmet and a huge axe, roaring and charging forward, ember red-orange accent',
'burglar': 'a cheerful halfling burglar in a dark hooded cloak tiptoeing with a sack of loot and a lockpick, mischievous grin, cool moonlight accent',
'eel': 'a fast orc raider with a black mohawk leaping over a broken gate, axe raised, war paint, ember red-orange accent',
'lurker': 'a big hunched forest troll with blue-green skin, long nose and tusks, holding a tree-branch club, moss growing on its shoulders, forest green accent',
'sailor': 'a hunched skeletal grave thrall in rotting rags and a dented helmet, eyes glowing green, holding a rusty sword, pale green accent',
'beastcaller': 'an elven beastcaller woman whistling with two fingers, a wolf at her side, leaves swirling around her, forest green accent',
'ghoul': 'a gaunt grey barrow ghoul crawling out of a crumbling tomb, long claws, hungry yellow eyes, pale sickly green accent',
'alchemist': 'a small gnome alchemist with wild orange hair and goggles, holding up a bubbling purple potion, smoke puffs around, violet accent',
'diver': 'an old gnome tinkerer with a white beard and a red pointed hat, holding a giant wrench next to a sputtering clockwork gadget, warm brass accent',
'gull': 'a knight riding a griffon diving through the sky, the griffon with golden feathers and spread wings, lance pointing forward, warm sunrise accent',
'commander': 'a veteran knight commander in red and gold armor with a short beard, raising a war banner and shouting an order, warm golden accent',
'golem': 'a massive stone golem made of carved temple blocks, glowing blue runes for eyes, standing guard in front of an empty doorway, cool blue accent',
'shark': 'a towering hairless giant covered in glowing blue rune tattoos, a stone club over its shoulder, looking down, cool blue rune accent',
'firelem': 'a fire elemental made of swirling flames shaped like a muscular figure, molten core in its chest, sparks flying, bright orange fire accent',
'ogre': 'a huge dim-witted ogre brute with a single tooth and a giant wooden club, confused frown, patched leather clothes, warm firelight accent',
'archmage': 'an old archmage woman with silver hair and a tall blue hat, floating books circling her, a glowing staff, arcane blue accent',
'hexer': 'an orc hexer shaman with a bone mask and a staff topped with a green skull, casting a curse of green smoke, sickly green accent',
'priestess': 'a serene temple priestess in white robes with a golden circlet, raising a staff that sheds golden blessings on unseen allies, holy gold accent',
'necro': 'a hooded necromancer in black robes raising a staff with a green gem, ghostly spirits rising from the ground around him, eerie green accent',
'thane': 'a proud dwarf thane in heavy gold-trimmed armor and a winged helmet, leaning on a great hammer in front of a stone hall gate, warm golden accent',
'wyvern': 'a rider on a green wyvern swooping low, the wyvern with leathery wings and a long tail, rider holding a spear, wind streaks, sky blue accent',
'treant': 'an ancient treant with bark skin, a wise mossy face and branches full of leaves, roots gripping broken ruins, soft forest green accent',
'dragonknight': 'a knight in dark red dragon-scale armor with a dragon-shaped helmet, a small red dragon perched on his shoulder, ember orange accent',
'wyrmling': 'a small blue mana wyrmling, a snake-like baby dragon, nibbling on a floating glowing rune, curious big eyes, arcane violet accent',
'geomancer': 'a gnome geomancer woman with a blue wizard hat touching the ground, glowing cracks and floating pebbles rising around her, arcane violet accent',
'spellbreaker': 'an elven spellbreaker in crimson armor with a slim sword cutting through a glowing magic sigil that shatters into shards, crimson red accent',
# ---- legendary minions ----
'lich': 'Malakar the lich king, a skeletal sorcerer in a dark purple robe with a crown of green flame, raising a staff, green soulfire swirling, fel green accent',
'dwarfking': 'Thorgrim, a mighty dwarf king with an enormous braided orange beard and a golden crown, sitting on a stone throne holding a great axe, golden accent',
'elfqueen': 'Sylvara, an elegant elf queen with long pale golden hair and a leaf crown, flowers blooming where she steps, a staff of living wood, forest green accent',
# ---- neutral spells ----
'spray': 'a single fiery bolt shooting from an outstretched hand, bright orange flame trail, small embers, ember red-orange accent',
'brace': 'a radiant blue and gold shield of light forming in front of a soldier, holy star at its center, holy gold accent',
'darkpact': 'a glowing parchment scroll with an unreadable blood smear floating in the air, a skeletal hand holding a quill, purple shadow smoke, dark purple accent',
'frenzy': 'a warrior roaring with red battle rage aura bursting around him, eyes glowing red, drops of blood in the air, crimson red accent',
'tidepool': 'an open old book glowing with abstract golden symbols lifting off blank pages, a candle beside it, warm candle light accent',
'mend': 'warm golden healing light pouring down onto open hands, soft glowing particles, holy gold accent',
'shieldwall': 'a row of soldiers locking overlapping shields together into a wall, seen from the front, steel and gold, warm firelight accent',
'calltoarms': 'a farmer blowing a battle horn while villagers with pitchforks and old helmets gather, determined faces, warm sunrise accent',
'undertow': 'a pillar of holy light striking down from the clouds onto the ground, judgment beam, holy gold accent',
'radiant': 'a burst of radiant golden light exploding outward in a star shape, warm rays, holy gold accent',
'hymn': 'a group of soldiers singing a battle hymn under a waving banner, mouths open, musical notes of light rising, warm golden accent',
'lance': 'a long spear of pure arcane energy flying forward, violet sparks and stars trailing behind, arcane violet accent',
'maelstrom': 'a big ball of fire spinning toward a group of enemies, flames swirling around it, bright orange fire accent',
'riptide': 'a jagged lightning bolt striking down from a dark cloud, bright white-blue electricity, storm blue accent',
'breath': 'a huge dragon head seen from the side breathing a wide stream of fire across the frame, ember red-orange accent',
'inferno': 'a sea of roaring flames rising high, burning ground and silhouettes of broken pillars, bright orange fire accent',
'retreat': 'a wounded soldier stepping back behind a raised shield while a glowing card of light pulls him away, cool blue accent',
# ---- warrior ----
'innerrage': 'a warrior gritting his teeth, a red rage flame igniting in his chest, veins glowing, ember red-orange accent',
'whirlwind': 'a warrior spinning with a giant two-handed axe, a red whirlwind of steel around him, dust and sparks flying, ember red-orange accent',
'shieldslam': 'a warrior smashing a heavy shield forward into an enemy, shockwave rings, ember red-orange accent',
'execute': 'a heavy executioner axe coming down in a bright red arc, the edge glowing, ember red-orange accent',
# ---- mage ----
'missiles': 'three glowing arcane orbs streaking forward from a hand, violet star trails, arcane violet accent',
'mirror': 'a mage splitting into two translucent shimmering copies of herself, icy blue outlines, icy blue and arcane violet accent',
'frostnova': 'a ring of ice exploding outward from the ground, frost spikes freezing everything around, icy blue and arcane violet accent',
# ---- paladin ----
'squires': 'two eager young squires in oversized helmets running forward with wooden shields and buckets, golden light behind them, holy gold accent',
'humility': 'a huge armored brute kneeling and shrinking under a beam of golden light, head bowed, holy gold accent',
'aegis': 'a golden bubble of holy light forming around a kneeling soldier, a glowing card of light floating beside, holy gold accent',
'kings': 'a golden crown of light descending onto a soldier, golden aura and wings of light, holy gold accent',
# ---- hunter ----
'pounce': 'a big cat leaping forward with claws out, motion streaks, green leaves flying, forest green accent',
'huntmark': 'a glowing green hunter target mark painted over a monster in the distance, an arrow nocked in the foreground, forest green accent',
'killcmd': 'a hunter pointing forward and shouting while a wolf leaps past her toward the enemy, forest green accent',
'hounds': 'a pack of lean hunting hounds bursting out running toward the viewer, dust flying, forest green accent',
# ---- priest ----
'pwshield': 'a soft white-gold shield of light wrapping around a soldier, glowing runes of protection, pale white-gold accent',
'holysmite': 'a small sun of white light striking a target, bright flare, pale white-gold accent',
'dispel': 'a magic sigil shattering into fading pieces in front of an open palm, silence and calm, pale white-gold accent',
'swpain': 'dark purple shadow tendrils wrapping around a small creature, a whispering shadow priest hand, dark purple accent',
'swdeath': 'a single word of shadow magic as a black and purple bolt piercing a huge monster, dark purple accent',
# ---- warlock ----
'soulfire': 'a warlock throwing a ball of green-purple soulfire, the flame also burning his own arm, fel green and dark purple accent',
'coil': 'a spiraling coil of dark shadow energy wrapping around a target, fel green core, fel green and dark purple accent',
'raisedead': 'two skeleton hands bursting out of a grave with green ghostly light, dirt flying, fel green accent',
'hellfire': 'a rain of green and purple hellfire falling from the sky over a broken battlefield, fel green and dark purple accent',
# ---- tokens ----
'bubble': 'an angry translucent blue spirit floating with a wailing face and wispy tail, cold pale blue accent',
'minnow': 'a young militia recruit holding a pitchfork with a nervous but brave face, simple leather vest, warm sunrise accent',
'reefling': 'a town guard in a simple steel helmet holding a spear, raising a hand to say halt, warm firelight accent',
'elver': 'a lean brown wolf running with its tongue out, eager eyes, forest green accent',
'squire': 'a small iron golem with a round body and glowing orange eyes, standing ready, warm brass accent',
'coin': 'a single gold coin spinning in the air with a star on it, sparkles, warm golden accent',
'skeleton': 'a small rattling skeleton warrior with a rusty sword and green glowing eyes, goofy pose, fel green accent',
'mirrorimg': 'a translucent shimmering copy of a mage made of ice-blue light, calm smile, icy blue accent',
'hound': 'a small scrappy hunting hound with a red collar, mid-run, forest green accent',
'spawn': 'a small red dragon whelp with stubby wings and a big head, puffing a little flame, ember orange accent',
}

ZH_RAR = {'c': '普通', 'r': '稀有', 'e': '史诗', 'l': '传说', 't': '衍生物'}
ZH_CLS = {c['id']: c['names'][1] for c in d['classes']}
done = {'knight', 'frostbolt', 'direwolf', 'leviathan'}
cards = [c for c in d['cards'] if c['id'] not in done]
missing = [c['id'] for c in cards if c['id'] not in S]
assert not missing, missing

groups = [('中立随从', lambda c: c['type'] == 'm' and not c['token'] and not c.get('cls') and c['rarity'] != 'l'),
          ('传说随从', lambda c: c['type'] == 'm' and c['rarity'] == 'l'),
          ('中立法术', lambda c: c['type'] == 's' and not c['token'] and not c.get('cls'))]
groups += [(f"{c['names'][1]}专属法术", (lambda cid: lambda c: c.get('cls') == cid)(c['id'])) for c in d['classes']]
groups += [('衍生物（游戏中召唤或获得的牌）', lambda c: c['token'])]

out = ['# Ruinaccord 卡牌绘图提示词', '',
       f'共 {len(cards)} 张（不含已经完成的圣骑士先锋、寒冰箭、恐狼、灰烬巨龙）。全部使用画风说明里的 **方向 B**，后缀已经接在每条后面，整段复制即可。',
       '', '出图后把文件按标题里的文件名放进 `art/raw/`（例如 `goblin.png`），然后运行 `python3 art/build_art.py`。',
       '如果用的不是 Midjourney，删掉末尾的 `--ar 2:3 --no ...`，在工具里选竖图 2:3，并把 text、frame、border、card、letters、numbers 填进反向提示词。', '']
n = 0
for title, f in groups:
    sel = [c for c in cards if f(c)]
    if not sel: continue
    out += [f'## {title}（{len(sel)} 张）', '']
    for c in sorted(sel, key=lambda c: (c['cost'], c['id'])):
        n += 1
        kind = f"随从 {c['atk']}/{c['hp']}" if c['type'] == 'm' else '法术'
        meta = f"{c['cost']} 费 · {kind} · {ZH_RAR[c['rarity']]}" + (f" · {ZH_CLS[c['cls']]}" if c.get('cls') else '')
        comp = MINION if c['type'] == 'm' else SPELL
        out += [f"### {c['names'][1]} {c['names'][0]} — `{c['id']}.png`", meta, '```', f"{S[c['id']]}, {comp}, {SUFFIX}", '```', '']
assert n == len(cards)
(root / 'art' / 'PROMPTS.md').write_text('\n'.join(out))
print(f'wrote art/PROMPTS.md with {n} prompts')
