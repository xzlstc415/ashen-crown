# Ruinaccord 卡牌绘图提示词

共 117 张：还要画的 84 张在前面，**已经有图的 33 张放在最后**（标着 ✅ available）。标着「测试页」的是只在 /beta/ 出现的新卡。
全部使用画风说明里的 **方向 B**，后缀已经接在每条后面，整段复制即可。每条都写了镜头角度、姿态和朝向，请不要删掉；如果生成出来的人物还是正面站立，在开头加一句 "dynamic pose, not standing straight, not facing the camera"。同类法术（加护甲、加生命、护盾、射箭、大火）每张都用了不同的画面比喻，提示词里写着 no shield 的就不要画盾。

出图后把文件按标题里的文件名放进 `art/raw/`（例如 `goblin.png`），然后运行 `python3 art/build_art.py`。
如果用的不是 Midjourney，删掉末尾的 `--ar 2:3 --no ...`，在工具里选竖图 2:3，并把 text、frame、border、card、letters、numbers 填进反向提示词。

## 中立随从（15 张）

### 半身人飞贼 Halfling Burglar — `burglar.png`
2 费 · 随从 2/2 · 稀有
```
a halfling burglar frozen mid-tiptoe on a rooftop ledge, caught in a beam of moonlight, eyes wide, one finger to his lips, a lumpy sack of loot over his shoulder, seen from a low angle, cool moonlight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 侏儒地脉师 Gnome Geomancer — `geomancer.png`
2 费 · 随从 2/2 · 普通
```
a gnome geomancer woman seen from above, sitting cross-legged on the ground with both palms pressed flat, glowing cracks spreading outward from her hands and pebbles floating up around her blue hat, arcane violet accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 精灵弓手 Elven Archer — `harpooneer.png`
2 费 · 随从 2/2 · 普通
```
an elven archer seen in strict side profile facing left, kneeling on one knee on a mossy fallen column, bow fully drawn, long golden hair blowing back in the wind, soft forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 侏儒炼金师 Gnome Alchemist — `alchemist.png`
3 费 · 随从 2/2 · 稀有
```
a small gnome alchemist peering one-eyed through a bubbling purple potion held up to the light, goggles pushed up into wild orange hair, the potion lighting her face from below, close-up, violet accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 兽人劫掠者 Orc Raider — `eel.png`
3 费 · 随从 3/2 · 稀有
```
an orc raider caught at the top of a leap over a broken gate, body twisted mid-air, axe swung back, black mohawk and war paint, dynamic foreshortened view from below, ember red-orange accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 侏儒巧匠 Gnome Tinkerer — `diver.png`
4 费 · 随从 3/4 · 稀有
```
an old gnome tinkerer lying on his back underneath a sputtering clockwork contraption, only his white beard, red pointed hat and a giant wrench poking out, sparks raining down, seen from the side, warm brass accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 兽人咒术师 Orc Hexer — `hexer.png`
4 费 · 随从 3/4 · 普通
```
an orc hexer shaman crouched over a small fire, face hidden behind a bone mask, blowing green curse smoke that curls up into the shape of a skull, seen from a high angle, sickly green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 密林巨魔 Forest Troll — `lurker.png`
4 费 · 随从 4/5 · 普通
```
a big hunched forest troll leaning lazily against a ruined pillar, picking its tusk with a twig, club resting on the ground, moss on its shoulders, seen in three-quarter view facing right, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 守门石像 Stone Golem — `golem.png`
5 费 · 随从 2/8 · 普通
```
a massive stone golem made of carved temple blocks seen from a worm's-eye angle, filling the doorway it guards, glowing blue rune eyes looking straight down at the viewer, tiny birds nesting on its shoulder, cool blue accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 火元素 Fire Elemental — `firelem.png`
6 费 · 随从 5/5 · 稀有
```
a fire elemental bursting up out of a cracked forge floor, arms flung wide, flames streaming upward like hair, molten core in its chest, seen head-on, bright orange fire accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 食人魔莽夫 Ogre Brute — `ogre.png`
6 费 · 随从 6/7 · 普通
```
a huge dim-witted ogre brute sitting on a flattened wagon, scratching his head with a giant wooden club, a confused frown and a single tooth, patched leather clothes, seen in three-quarter view facing left, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 符文巨人 Runebound Giant — `shark.png`
6 费 · 随从 6/6 · 史诗
```
a towering hairless rune giant seen from far away and below, striding over the ruins toward the right edge, glowing blue rune tattoos, a stone club dragging behind it, clouds at its waist, cool blue rune accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 飞龙骑手 Wyvern Rider — `wyvern.png`
6 费 · 随从 5/5 · 史诗
```
a rider on a green wyvern banking hard in a steep dive, seen from above and behind so the wings fill the frame, rider leaning forward with a spear, wind streaks, sky blue accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 龙骑士 Dragon Knight — `dragonknight.png`
7 费 · 随从 5/5 · 史诗
```
a knight in dark red dragon-scale armor seen from behind on a cliff edge, cape flowing, a small red dragon perched on his raised fist and roaring at the sky, ember orange accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 远古树人 Ancient Treant — `treant.png`
7 费 · 随从 6/9 · 稀有
```
an ancient treant slowly turning its mossy face toward the viewer, half of its body still part of a ruined wall, roots and branches tangled through broken stone, fireflies around, soft forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 传说随从（3 张）

### 山心之王索格林 Thorgrim, King Under Stone — `dwarfking.png`
8 费 · 随从 7/7 · 传说
```
Thorgrim the dwarf king leaning forward on his stone throne, elbows on knees, glaring straight at the viewer, enormous braided orange beard spilling over a great axe across his lap, golden crown, golden accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 翠林女王希尔瓦拉 Sylvara, Queen of the Glade — `elfqueen.png`
8 费 · 随从 5/7 · 传说
```
Sylvara the elf queen walking away through a field of flowers that bloom where she steps, turning her head to look back over her shoulder, long pale golden hair, leaf crown, staff of living wood, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 不朽者马拉卡 Malakar the Undying — `lich.png`
8 费 · 随从 6/6 · 传说
```
Malakar the lich king seen from a low angle, floating above a crumbling crypt with his ragged purple robe billowing upward, arms spread, a crown of green flame, green soulfire spiraling around him, fel green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 中立法术（2 张）

### 暂避锋芒 Tactical Retreat — `retreat.png`
1 费 · 法术 · 普通
```
a soldier vanishing backward into a puff of grey smoke, only his raised shield and one boot still visible, a trail of footprints leading out of the frame, cool blue accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 激昂战歌 Battle Hymn — `hymn.png`
3 费 · 法术 · 稀有
```
a ring of soldiers seen from below, arms around each other's shoulders, singing up into the sky under a waving banner, notes of light rising, warm golden accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 战士职业牌（7 张）

### 兽人狂战士 Orc Berserker — `berserker.png`
2 费 · 随从 2/1 · 普通 · 战士
```
an orc berserker charging straight at the viewer, extreme foreshortening, huge axe swinging overhead, horned helmet, mouth open in a roar, flecks of dirt flying, ember red-orange accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 矮人盾卫 Dwarf Shieldbearer — `crab.png`
2 费 · 随从 1/4 · 普通 · 战士
```
a short stocky dwarf seen almost entirely from behind his huge battered round shield, only his braided red beard, helmet and one squinting eye peeking over the rim, arrows stuck in the shield, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 矮人领主 Dwarf Thane — `thane.png`
5 费 · 随从 5/5 · 稀有 · 战士
```
a proud dwarf thane striding toward the left edge with a great hammer slung across both shoulders, winged helmet, heavy gold-trimmed armor, a stone hall gate behind him, seen from a low angle, warm golden accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 怒火中烧 Inner Rage — `innerrage.png`
0 费 · 法术 · 普通 · 战士
```
a close-up of a warrior's clenched fist, cracks of red light glowing through the skin between the knuckles, steam rising, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 旋风斩 Whirlwind — `whirlwind.png`
1 费 · 法术 · 普通 · 战士
```
a warrior seen from directly above spinning with a giant two-handed axe, a red ring of steel and dust around him, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 斩杀 Execute — `execute.png`
2 费 · 法术 · 稀有 · 战士
```
a heavy executioner axe coming down in a bright red arc, the edge glowing, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 嗜血 Bloodlust — `frenzy.png`
2 费 · 法术 · 稀有 · 战士
```
a warrior with his back to the viewer, arms thrown wide, a red battle-rage aura erupting upward like a bonfire, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 法师职业牌（11 张）

### 余烬学徒 Ember Adept — `emberadept.png`
2 费 · 随从 2/3 · 普通 · 法师 · 测试页
```
a young fire mage girl seen from the side, burning her own notes over a candle with a satisfied smile, ashes drifting up, orange robe, bright orange fire accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 余烬元素 Ember Elemental — `emberele.png`
4 费 · 随从 4/5 · 稀有 · 法师 · 测试页
```
a hulking elemental made of glowing coals and cooling ash, crouched low like a gorilla with knuckles on the ground, embers rising from its back, seen in three-quarter view facing left, bright orange fire accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 寒冰元素 Frost Elemental — `frostele.png`
4 费 · 随从 3/6 · 稀有 · 法师 · 测试页
```
a jagged frost elemental made of stacked ice crystals sitting hunched on a frozen boulder, breath steaming, frost spreading over the ground around it, seen from a low angle, icy blue and arcane violet accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 灰烬凤凰 Ash Phoenix — `phoenix.png`
5 费 · 随从 5/4 · 史诗 · 法师 · 测试页
```
a phoenix made of grey ash and glowing cracks seen from directly below as it spreads its wings across the whole sky, flakes of ash falling toward the viewer, bright orange fire accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 尖塔大法师 Archmage of the Spire — `archmage.png`
6 费 · 随从 6/7 · 史诗 · 法师
```
an old archmage woman sitting in mid-air with her legs crossed, reading one book while a whirlwind of open books orbits around her, silver hair, tall blue hat, staff floating beside her, arcane blue accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 余烬火花 Ember Flick — `emberbolt.png`
1 费 · 法术 · 普通 · 法师 · 测试页
```
a single ember flicked off a fingertip like a coin, glowing and trailing a tiny curl of smoke, extreme close-up of the hand, bright orange fire accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 冰枪术 Ice Lance — `icelance.png`
1 费 · 法术 · 普通 · 法师 · 测试页
```
a slim shard of ice spinning end over end through the air, a frozen enemy shield cracking in the background, crisp and fast, icy blue and arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 碎冰 Shatter — `shatter.png`
2 费 · 法术 · 稀有 · 法师 · 测试页
```
a frozen monster bursting into a thousand glittering ice shards toward the viewer, frozen in the moment of breaking, icy blue and arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 寒冰屏障 Ice Barrier — `icebarrier.png`
3 费 · 法术 · 稀有 · 法师 · 测试页
```
a mage sitting calmly cross-legged inside a faceted crystal of ice like the inside of a geode, an enemy outside frozen mid-swing against the facets, seen from a three-quarter top view, icy blue and arcane violet accent, no shield, no bubble, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 灼热射线 Scorching Ray — `scorch.png`
3 费 · 法术 · 普通 · 法师 · 测试页
```
a thin searing beam of orange light cutting diagonally across the frame through the seam of a knight's armor, molten drips, bright orange fire accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 烈焰风暴 Firestorm — `firestorm.png`
6 费 · 法术 · 史诗 · 法师 · 测试页
```
a firestorm seen from a hilltop, a funnel of flames coming down from red clouds onto the ruins in the valley below, bright orange fire accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 圣骑士职业牌（8 张）

### 神殿祭司 Temple Priestess — `priestess.png`
4 费 · 随从 3/4 · 稀有 · 圣骑士
```
a serene temple priestess walking toward the viewer down a ruined aisle, scattering petals of golden light from an open palm, white robes trailing, golden circlet, holy gold accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 骑士统领 Knight Commander — `commander.png`
5 费 · 随从 4/4 · 史诗 · 圣骑士
```
a veteran knight commander seen from behind his troops, standing on a broken wall and turning back to shout an order, red and gold armor, war banner snapping in the wind, warm golden accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 圣盾术 Sacred Aegis — `aegis.png`
1 费 · 法术 · 普通 · 圣骑士
```
a single glowing golden feather drifting down onto a sleeping squire's shoulder, and where it touches a thin iridescent soap-bubble sphere blooming around him, top-down view, holy gold and pale pink, no shield, no armor plates, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 信仰之盾 Shield of Faith — `brace.png`
1 费 · 法术 · 普通 · 圣骑士
```
a battered wooden tower shield planted in cracked ground, golden roots of light growing out of the earth and wrapping around it to anchor it in place, a gauntleted hand pressing against its back, low angle, amber and gold, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 谦卑 Humility — `humility.png`
2 费 · 法术 · 稀有 · 圣骑士
```
a huge armored brute seen from behind, kneeling as its enormous shadow shrinks to a tiny shape under a small glowing hand held up in front of it, holy gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 侍从集结 Squire's Call — `squires.png`
2 费 · 法术 · 普通 · 圣骑士
```
two eager young squires tumbling over each other as they run toward the left edge, oversized helmets falling over their eyes, wooden shields and a bucket, golden light behind them, holy gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 征召号角 Call to Arms — `calltoarms.png`
3 费 · 法术 · 普通 · 圣骑士
```
a farmer on a rooftop blowing a battle horn, seen from behind, while villagers with pitchforks and old helmets pour into the square below, warm sunrise accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 王者祝福 Blessing of Kings — `kings.png`
4 费 · 法术 · 稀有 · 圣骑士
```
a crown of light descending from above onto a kneeling soldier who looks up in awe, a royal cloak of deep red and gold light unfurling from his shoulders, low angle, regal crimson and gold, no shield, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 猎人职业牌（9 张）

### 精灵兽语者 Elven Beastcaller — `beastcaller.png`
3 费 · 随从 2/3 · 稀有 · 猎人
```
an elven beastcaller sitting on a fallen log with a wolf's head resting in her lap, whistling softly with two fingers, leaves swirling, seen from the side, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 精灵神射手 Elven Marksman — `marksman.png`
3 费 · 随从 3/3 · 稀有 · 猎人 · 测试页
```
an elven marksman sitting high on a broken statue's shoulder, one leg dangling, sighting down an arrow at something far below, seen from a low angle, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 狮鹫骑士 Griffon Rider — `gull.png`
5 费 · 随从 4/4 · 史诗 · 猎人
```
a griffon rider landing hard on a ruined bell tower, the griffon rearing with wings spread wide and golden feathers flaring, rider pointing a lance down at the viewer, low angle, warm sunrise accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 猛扑 Pounce — `pounce.png`
0 费 · 法术 · 普通 · 猎人
```
a big spotted cat mid-leap from a high branch straight down at the viewer, claws out, leaves exploding around it, steep high angle, forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 奥术射击 Arcane Shot — `spray.png`
1 费 · 法术 · 普通 · 猎人
```
an arrow made of violet runes splitting apart mid-flight into a spiral of tiny glowing glyphs, seen in side view against a dark night sky, no archer visible, violet and forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 稳固射击 Steady Shot — `steady.png`
2 费 · 法术 · 普通 · 猎人 · 测试页
```
an extreme close-up of an archer's calm eye and cheek pressed against the taut bowstring, a single snowflake landing on her eyelash, everything else blurred, forest green accent, no arrow in flight, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 群犬出猎 Unleash the Hounds — `hounds.png`
3 费 · 法术 · 史诗 · 猎人
```
a pack of lean hunting hounds bursting through a broken gate straight toward the viewer, dust flying, forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 爆裂射击 Explosive Shot — `explosive.png`
4 费 · 法术 · 稀有 · 猎人 · 测试页
```
an arrow striking a monster and exploding into a starburst of orange sparks that spray the smaller creatures around it, forest green and orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 致命射击 Deadly Shot — `riptide.png`
5 费 · 法术 · 史诗 · 猎人
```
the moment after: a single black-fletched arrow buried deep in a giant's cracked stone breastplate, the giant toppling backward in silhouette, seen from far below, deep red and forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 牧师职业牌（14 张）

### 虚空侍僧 Void Acolyte — `voidacolyte.png`
2 费 · 随从 2/1 · 普通 · 牧师 · 测试页
```
a hooded acolyte seen in profile with a finger to her lips, the sound around her drained away into a swirling purple hush, dark purple accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 领唱祭司 High Cantor — `cantor.png`
3 费 · 随从 2/4 · 稀有 · 牧师 · 测试页
```
a priestess conductor seen from behind, both arms raised mid-gesture, a choir of light silhouettes in front of her, musical ribbons of light, pale white-gold accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 矮人牧师 Dwarven Cleric — `cleric.png`
3 费 · 随从 3/4 · 普通 · 牧师
```
a jolly dwarven cleric mid-laugh, head thrown back, raising a mug of ale in one hand while a big warhammer rests on his shoulder, holy symbol swinging on his chest, seen in three-quarter view facing right, warm golden light accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 精灵破法者 Elven Spellbreaker — `spellbreaker.png`
4 费 · 随从 4/3 · 稀有 · 牧师
```
an elven spellbreaker in crimson armor caught mid-spin, her slim sword slicing clean through a glowing magic sigil that shatters into shards around her, motion blur on the blade, crimson red accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 晨祷 Dawn Prayer — `matins.png`
1 费 · 法术 · 普通 · 牧师 · 测试页
```
a small bell tower at dawn seen from far away, the first sunbeam hitting a ringing bell, birds rising, prayer beads hanging from a window in the foreground, pale white-gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 庇护之言 Word of Shielding — `pwshield.png`
2 费 · 法术 · 普通 · 牧师
```
a priest whispering into cupped hands, the whispered breath turning into long pale ribbons of light that wind around a distant soldier like bandages, side view, pale white-gold and soft blue, no shield, no bubble, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 圣所庇佑 Sanctuary — `sanctuary.png`
2 费 · 法术 · 普通 · 牧师 · 测试页
```
broken chapel walls rebuilding themselves brick by brick out of translucent blocks of light around a few huddled soldiers, seen from above like a doll house with the roof off, pale white-gold accent, no shield, no bubble, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 守夜祷文 Night Vigil — `vigil.png`
2 费 · 法术 · 普通 · 牧师 · 测试页
```
two tall candles on a dark ruined altar at night, each flame guarded by a small hooded figure seen from behind, deep blue night with warm candle light, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 归来圣咏 Hymn of Return — `requiem.png`
3 费 · 法术 · 稀有 · 牧师 · 测试页
```
a lone singer walking slowly along a path of floating lanterns that leads a translucent fallen soldier back from the mist, seen from the side, pale white-gold and soft blue, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 苦痛之言 Word of Pain — `swpain.png`
3 费 · 法术 · 稀有 · 牧师
```
dark purple shadow tendrils curling around a small creature from all sides, a single whispering shadowy mouth at the edge of the frame, dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 毁灭之言 Word of Ruin — `wordruin.png`
3 费 · 法术 · 稀有 · 牧师 · 测试页
```
a cracked stone ward-tablet on a wounded monster's chest breaking apart under a single purple spoken shockwave, close-up, dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 审判之日 Day of Judgment — `judgment.png`
4 费 · 法术 · 史诗 · 牧师 · 测试页
```
a huge cracked bronze bell in a ruined tower swinging toward the viewer, a ring of golden light rolling out across the land, low angle, pale white-gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 天启 Revelation — `revelation.png`
5 费 · 法术 · 史诗 · 牧师 · 测试页
```
the clouds tearing open in a perfect circle above the ruins, a column of blinding light and wings of light pouring down, seen from far below, pale white-gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 折磨之言 Word of Torment — `wordtorment.png`
6 费 · 法术 · 史诗 · 牧师 · 测试页
```
a giant shadowy mouth opening in the sky above a battlefield, a beam of black and purple sound crushing one huge monster, seen from far away, dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 术士职业牌（5 张）

### 守墓亡仆 Grave Thrall — `sailor.png`
2 费 · 随从 1/2 · 稀有 · 术士
```
a hunched skeletal grave thrall dragging itself up out of an open grave, one bony hand on the rim, dented helmet slipping over glowing green eyes, rusty sword in its teeth, seen from above, pale green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 古冢食尸鬼 Barrow Ghoul — `ghoul.png`
3 费 · 随从 3/3 · 普通 · 术士
```
a gaunt grey barrow ghoul seen from inside a dark tomb looking out, clinging to the ceiling of the entrance upside down, long claws and hungry yellow eyes, pale sickly green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 死灵法师 Necromancer — `necro.png`
4 费 · 随从 3/4 · 稀有 · 术士
```
a hooded necromancer kneeling on a graveyard path, tapping the earth with a staff topped by a green gem, ghostly hands rising out of the soil toward him, seen from a high angle, eerie green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 死亡缠绕 Mortal Coil — `coil.png`
1 费 · 法术 · 普通 · 术士
```
a skull-shaped bolt of shadow corkscrewing toward a small creature, a wisp of green light lifting out of the creature like a page being drawn, fel green and dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 灵魂之火 Soulfire — `soulfire.png`
1 费 · 法术 · 稀有 · 术士
```
a warlock seen from the side hurling a ball of green-purple soulfire, the same flame crawling up his own sleeve, fel green and dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 衍生物（游戏中召唤或获得的牌）（10 张）

### 持烛侍僧 Candlebearer — `acolyte.png`
1 费 · 随从 1/2 · 衍生物 · 测试页
```
a small candlebearer in white robes walking toward the viewer, cupping a candle flame against the wind, calm face lit from below, warm candle light, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 猎犬 Hound — `hound.png`
1 费 · 随从 1/1 · 衍生物
```
a small scrappy hunting hound with a red collar skidding to a stop, ears flying, seen from the front, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 义勇民兵 Militia Recruit — `minnow.png`
1 费 · 随从 1/1 · 衍生物
```
a young militia recruit seen from a high angle, gripping a pitchfork too tightly, nervous but brave face looking up, simple leather vest, warm sunrise accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 群猎犬 Pack Hound — `phound.png`
1 费 · 随从 2/1 · 衍生物 · 测试页
```
a scrappy pack hound sitting in tall grass in side view facing right, scratching behind its inside-out ear with a hind leg, tongue out, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 灰狼 Wolf — `elver.png`
2 费 · 随从 2/1 · 衍生物
```
a lean brown wolf running across the frame from right to left, tongue out, eager eyes, forest green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 城门守卫 Town Guard — `reefling.png`
2 费 · 随从 2/2 · 衍生物
```
a town guard seen in three-quarter view facing left, steel helmet, spear planted, one hand raised palm-out to say halt, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 骷髅战士 Bone Warrior — `bonewarr.png`
3 费 · 随从 2/2 · 衍生物 · 测试页
```
a skeleton warrior assembled from mismatched bones of many creatures, standing at attention with a rusted cleaver, green fire in its eye sockets, seen from a low angle, fel green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 钢铁魔像 Iron Golem — `squire.png`
3 费 · 随从 3/3 · 衍生物
```
a small round iron golem sitting on the ground with its legs stuck straight out, glowing orange eyes, steam puffing from its head, warm brass accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 幼龙 Dragon Whelp — `spawn.png`
4 费 · 随从 4/4 · 衍生物
```
a small red dragon whelp perched on a skull, puffing a tiny flame and looking surprised at it, stubby wings, ember orange accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 唤犬哨 Hound Whistle — `whistle.png`
0 费 · 法术 · 衍生物 · 猎人 · 测试页
```
a small carved bone whistle on a leather cord, mid-blow, sound rings rippling out and a hound's ears perking up in the distance, forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

---

# ✅ 已经有图的卡（available，33 张）

这些卡的图片已经生成（在 `art/raw/` 或已经放进游戏），提示词留在这里备查；想重画时再用。

## 中立随从·已有图（1 张）

### 暗巷哥布林 Goblin Cutpurse — `goblin.png`
1 费 · 随从 2/1 · 普通 · ✅ 已有图片 available
```
a skinny green goblin thief hanging upside down by his knees from a broken archway, grinning, a stolen coin purse dangling from his teeth and a small dagger in one hand, seen from below, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 传说随从·已有图（1 张）

### 灰烬巨龙伊格纳洛斯 Ignaroth, Ashen Wyrm — `leviathan.png`
8 费 · 随从 7/8 · 传说 · ✅ 已有图片 available
```
an enormous ash-grey dragon with glowing molten cracks along its scales, wings spread wide, coiled protectively on top of a ruined cathedral tower, breathing a sweeping wave of fire downward, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 中立法术·已有图（4 张）

### 圣光迸发 Radiant Burst — `radiant.png`
3 费 · 法术 · 稀有 · ✅ 已有图片 available
```
a burst of radiant golden light exploding outward in a star shape from a cracked altar, warm rays sweeping across the ruins, holy gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 典籍启示 Scholar's Insight — `tidepool.png`
3 费 · 法术 · 普通 · ✅ 已有图片 available
```
an old open book seen from directly above on a stone desk, golden symbols lifting off the blank pages like moths and flying toward a single candle, warm candle light accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 天罚 Smite — `undertow.png`
3 费 · 法术 · 稀有 · ✅ 已有图片 available
```
a giant hammer made of golden light smashing down onto a monster from the side, cracks and dust spreading across the stone floor, close side view, holy gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 龙息 Dragon's Breath — `breath.png`
6 费 · 法术 · 史诗 · ✅ 已有图片 available
```
a huge dragon head seen from the side breathing a wide stream of fire across the frame, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 战士职业牌·已有图（2 张）

### 盾牌猛击 Shield Slam — `shieldslam.png`
1 费 · 法术 · 史诗 · 战士 · ✅ 已有图片 available
```
a heavy shield slammed into the ground in front of the viewer, a red shockwave ring blasting outward and knocking debris into the air, low angle, ember red-orange accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 盾墙 Shield Wall — `shieldwall.png`
2 费 · 法术 · 普通 · 战士 · ✅ 已有图片 available
```
a warrior in a wide braced stance while dozens of loose iron plates fly in from every direction and clamp onto his body like magnets, overlapping into scale armor, front view with motion streaks, iron grey and ember orange, no shield, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 法师职业牌·已有图（8 张）

### 见习法师 Wizard's Apprentice — `apprentice.png`
1 费 · 随从 1/2 · 普通 · 法师 · ✅ 已有图片 available
```
a nervous young wizard's apprentice seen from behind and slightly above, glancing back over his shoulder in panic while his oversized purple hat smokes and a tiny flame sputters out of his wand, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 法力幼龙 Mana Wyrmling — `wyrmling.png`
1 费 · 随从 2/3 · 稀有 · 法师 · ✅ 已有图片 available
```
a small blue mana wyrmling curled in a loop around a floating glowing rune, chewing on its corner, big curious eyes looking at the viewer, top-down view, arcane violet accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 镜影分身 Mirror Image — `mirror.png`
1 费 · 法术 · 普通 · 法师 · ✅ 已有图片 available
```
a mage standing between two tall shards of floating ice, each shard reflecting a different version of her stepping out of it, icy blue and arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 奥术飞弹 Arcane Missiles — `missiles.png`
1 费 · 法术 · 普通 · 法师 · ✅ 已有图片 available
```
three glowing arcane orbs zigzagging toward the viewer like fireflies, each leaving a curly violet trail, arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 寒冰箭 Frostbolt — `frostbolt.png`
2 费 · 法术 · 普通 · 法师 · ✅ 已有图片 available
```
a jagged bolt of glowing ice flying toward the viewer, trailing frost crystals and cold mist, a gloved hand at the bottom edge just releasing it, glowing icy blue and arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 冰霜新星 Frost Nova — `frostnova.png`
2 费 · 法术 · 稀有 · 法师 · ✅ 已有图片 available
```
a ring of ice exploding outward from the ground seen from directly above, frost spikes radiating like a snowflake, icy blue and arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 奥术之矛 Arcane Lance — `lance.png`
3 费 · 法术 · 稀有 · 法师 · ✅ 已有图片 available
```
a long spear of pure arcane energy flying forward, violet sparks and stars trailing behind, arcane violet accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 火球术 Fireball — `maelstrom.png`
3 费 · 法术 · 史诗 · 法师 · ✅ 已有图片 available
```
a big ball of fire spinning toward the viewer, flames swirling around it, bright orange fire accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 圣骑士职业牌·已有图（1 张）

### 圣骑士先锋 Paladin Vanguard — `knight.png`
4 费 · 随从 3/5 · 稀有 · 圣骑士 · ✅ 已有图片 available
```
a female paladin knight in polished silver plate armor with gold trim, open-face helm, a radiant golden halo behind her head, white tabard with a gold sun emblem, raising a big kite shield with a glowing gold sunburst, standing firm on cracked steps, glowing holy gold accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 猎人职业牌·已有图（3 张）

### 恐狼 Dire Wolf — `direwolf.png`
2 费 · 随从 3/2 · 普通 · 猎人 · ✅ 已有图片 available
```
a big grey dire wolf with a thick mane and a scar over one eye, snarling and crouched to pounce on a broken stone ledge, eyes reflecting firelight, warm firelight accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 猎手印记 Hunter's Mark — `huntmark.png`
1 费 · 法术 · 稀有 · 猎人 · ✅ 已有图片 available
```
a view through a narrow gap in the leaves at a large monster in the distance, a glowing green target ring painted onto it, forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 猎杀令 Kill Command — `killcmd.png`
2 费 · 法术 · 普通 · 猎人 · ✅ 已有图片 available
```
a wolf leaping past the viewer's shoulder toward an enemy in the distance, a hunter's outstretched pointing arm at the edge of the frame, forest green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 牧师职业牌·已有图（5 张）

### 神殿侍僧 Temple Acolyte — `pearl.png`
1 费 · 随从 1/1 · 普通 · 牧师 · ✅ 已有图片 available
```
a young temple acolyte seen from above, kneeling on a cracked mosaic floor with her eyes closed in prayer, a soft bubble of pale light rising around her like a soap bubble, warm holy light accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 驱散 Dispel — `dispel.png`
1 费 · 法术 · 稀有 · 牧师 · ✅ 已有图片 available
```
an open palm pushing through a glowing magic sigil, the sigil breaking apart into fading paper-like flakes, quiet and calm, pale white-gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 神圣惩击 Holy Smite — `holysmite.png`
1 费 · 法术 · 普通 · 牧师 · ✅ 已有图片 available
```
a small sun of white light dropping like a falling star onto a target, bright flare, pale white-gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 治愈之光 Healing Light — `mend.png`
2 费 · 法术 · 稀有 · 牧师 · ✅ 已有图片 available
```
a macro close-up of a cracked armored forearm, liquid golden light flowing into the cracks and sealing them like gold-mended pottery, holy gold accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 死亡之言 Word of Death — `swdeath.png`
4 费 · 法术 · 史诗 · 牧师 · ✅ 已有图片 available
```
a pale hand pointing one finger, a thin black thread of shadow running from the fingertip straight through the heart of a huge monster, the monster fading to grey, side view, dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 术士职业牌·已有图（4 张）

### 黑暗契约 Dark Pact — `darkpact.png`
1 费 · 法术 · 稀有 · 术士 · ✅ 已有图片 available
```
a glowing parchment contract floating in the dark, a skeletal hand holding a quill while a drop of blood falls from a fingertip onto it, purple shadow smoke, dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 亡者复生 Raise Dead — `raisedead.png`
1 费 · 法术 · 普通 · 术士 · ✅ 已有图片 available
```
two skeleton hands bursting out of a grave seen from directly above, green ghostly light and dirt flying, fel green accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 地狱烈焰 Hellfire — `hellfire.png`
3 费 · 法术 · 史诗 · 术士 · ✅ 已有图片 available
```
seen from a castle wall at night, green and purple meteors of hellfire falling on two armies alike, friend and foe both scattering, fel green and dark purple accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 焦土烈焰 Inferno — `inferno.png`
5 费 · 法术 · 史诗 · 术士 · ✅ 已有图片 available
```
ground-level view of a scorched black field, the last small green sapling in the foreground about to be swallowed by a low wall of flame rolling in from the horizon, charcoal and orange, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 衍生物（游戏中召唤或获得的牌）·已有图（4 张）

### 镜影 Mirror Image — `mirrorimg.png`
0 费 · 随从 1/3 · 衍生物 · ✅ 已有图片 available
```
a translucent ice-blue copy of a mage seen from behind, looking at its own reflection in a puddle, calm smile, icy blue accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 怨灵 Restless Spirit — `bubble.png`
1 费 · 随从 2/1 · 衍生物 · ✅ 已有图片 available
```
an angry translucent blue spirit swooping diagonally across the frame with a wailing face and a long wispy tail, cold pale blue accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 骷髅兵 Skeleton — `skeleton.png`
1 费 · 随从 1/1 · 衍生物 · ✅ 已有图片 available
```
a small rattling skeleton warrior tripping over its own rusty sword, arms flailing, green glowing eyes, goofy, fel green accent, the face or most recognizable part in the upper third of the frame, simple ground in the lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 幸运硬币 Lucky Coin — `coin.png`
0 费 · 法术 · 衍生物 · ✅ 已有图片 available
```
a single gold coin spinning on its edge on a tavern table, caught at a tilt, sparkles flying, warm golden accent, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

## 新增（2026-10-22）· 猎人野兽与圣骑士誓言（6 张）

### 荆棘野猪 Thornback Boar — `boar.png`
1 费 · 随从 2/1 · 普通 · 猎人 · 测试页
```
a small wild boar with a ridge of thorn-like bristles charging through undergrowth, tusks lowered, leaves flying, mossy green and earth-brown palette, the animal centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 雾林猎豹 Mistwood Panther — `panther.png`
3 费 · 随从 4/2 · 稀有 · 猎人 · 冲锋 · 测试页
```
a sleek black panther mid-leap out of a misty forest, eyes glowing pale green, fog curling between tree trunks, blue-grey and black palette with a single green accent, the animal centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 巨角麋鹿 Greathorn Elk — `elk.png`
4 费 · 随从 3/5 · 普通 · 猎人 · 守护 · 测试页
```
a huge elk with enormous moss-hung antlers standing firm on a forest path, head lowered, autumn gold and deep green palette, the animal centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 守护誓言 Oath of Shelter — `oathshelter.png`
1 费 · 法术（誓言，2 回合）· 普通 · 圣骑士 · 测试页
```
a kneeling knight's gauntleted hand pressed to the ground as a translucent golden dome of light rises over a small village behind, white-gold and warm grey palette, the effect centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 集结誓言 Oath of Muster — `oathmuster.png`
2 费 · 法术（誓言，2 回合）· 普通 · 圣骑士 · 测试页
```
a tattered banner planted on a hilltop at sunrise with three distant farmers walking up the slope carrying pitchforks and a scythe, warm gold and dusty blue palette, the banner centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 圣战誓言 Oath of Crusade — `oathcrusade.png`
3 费 · 法术（誓言，2 回合）· 稀有 · 圣骑士 · 测试页
```
a sword raised toward a dusk sky with a ring of smaller raised swords around it, golden light breaking through purple clouds, gold and violet palette, the raised sword centered in the upper half of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 渡魂者维斯珀 Vesper the Ferryman — `gravecaller.png`
4 费 · 随从 3/3 · 史诗（一副牌一张） · 术士 · 亡灵 · 虚体 · 测试页 · 2026-10-22 重写：突出半透明的虚体和摆渡亡魂回来
```
a tall gaunt wraith ferryman named Vesper, half see-through, the far bank of a black river showing through his grey-violet shroud, a deep hood with only two pale violet eyes glowing inside, one skeletal hand on a long dripping pole, standing in a narrow black boat that carries two faint glowing souls back toward the viewer, a small pale lantern hanging at the prow, mist curling on still black water, cold violet and bone-white palette with the lantern as the only warm light, ethereal and calm, the face or most recognizable part in the upper third of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

### 瑟拉薇的血祭 Seravine's Blood Rite — `bloodrite.png`
2 费 · 法术 · 史诗（一副牌一张） · 术士 · 测试页 · 2026-10-22 重写：以瑟拉薇本人为主体
```
Seravine, a pale blood priestess in crimson and black ritual robes with a high collar, dark hair pinned up with bone pins, cool satisfied half-smile, holding a fan of glowing parchment slips over a stone basin of dark red fire as they burn away to ash, from the flames rises a single shining golden crown-shaped sigil of light into her other open hand, thin crimson smoke curling around her, deep crimson and black palette with one bright gold accent, the face or most recognizable part in the upper third of the frame, calm simple lower part, hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```
