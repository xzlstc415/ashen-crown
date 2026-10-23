# Ruinaccord 六位英雄：种族、名字、头像提示词与背景

世界观回顾：灰烬之王曾统治这片大陆，他的王冠在灰烬巨龙伊格纳洛斯的龙息中锻成。王朝倾覆后，世界成了"阳光照进废墟、藤蔓爬上石柱"的样子。冒险者从哥布林战团一路打到灰烬之王，要把那顶王冠夺回来。六位英雄各有自己要戴上王冠的理由。

## 头像统一规范（2026-10-21 修订）

第一批出图的问题：脸在画面上三分之一、铠甲占了一半画面（圆形头像一裁，中间是胸甲不是脸）；侏儒和半身人都画成了精灵（尖耳朵）；两张猎人和其余四张不是同一种笔触。所以这版把六条提示词改成**同一个框架**：

- **构图固定**：平视镜头，头和肩膀，脸在画面正中央、占画面高度约三分之二，头顶贴近上边缘，肩膀在下边缘被裁掉。头像是圆形的，裁掉四角后剩下的必须是脸。
- **光线固定**：左上方一盏主光，职业强调色只做轮廓光。
- **背景固定**：阳光下长满藤蔓的废墟，虚化。
- **种族特征放在最前面**，而且写明"不是精灵"：只有猎人有尖耳朵。
- **主体描述尽量短**：细节越多，模型越往写实大头照跑。
- **一次出完六张**：用同一个风格参考（例如 `--sref` 指向已通过的兽人头像或 `art/raw/knight.png`，`--sw 100`）和同一个 `--seed`，避免像第一批那样两张猎人跑成另一种笔触。

六条提示词都用下面这段统一后缀：

```
head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

出图后把文件按标题里的文件名放到 `art/heroes/`（例如 `hero_warrior.png`）。

| 职业 | 种族 | 名字 | 一句话 |
|---|---|---|---|
| 战士 | 兽人 | 洛克·灰牙 Rok Greytusk | 从兽人督军麾下出走的持盾者 |
| 法师 | 侏儒 | 皮姆·霜烬 Pim Emberfrost | 在废墟图书馆长大的自学法师 |
| 圣骑士 | 人类 | 奥德里克·晨誓 Aldric Dawnoath | 旧王国最后一名骑士 |
| 猎人 | 精灵 | 凯尔温·荆径 Kaelwen Thornstride | 退出精灵议会的林地巡守 |
| 牧师 | 半身人 | 薇拉·暮钟 Vera Duskbell | 同时听得见圣光与亡者低语的年轻敲钟人 |
| 术士 | 不死族 | 莫文·残烛 Morwen Lastcandle | 被巫妖复活、只剩半条命的宫廷占星师 |

---

## 战士 · 洛克·灰牙 Rok Greytusk — `hero_warrior.png`
兽人 · 男性 · 中年

**背景**：兽人有一条老规矩：盾只为值得的人举。洛克在兽人督军麾下当了二十年持盾者，替督军挡下过数不清的箭，从没问过值不值得。灰烬之王的军队压到营前那天，督军跪下了，而督军献上的第一份投名状，是一座一直跟战团公平交易的边境村庄。洛克那天没有举盾。他把盾放在督军脚边，转身走出营地，走出很远才又把它背起来。从那以后，他只替自己选的人挡箭。他要王冠，是为了让跪下去的人再也不必跪。

**头像提示词**
```
a scarred orc chieftain, moss-green skin, heavy brow, two moderate lower tusks, long black mane braided with bone beads, one blind milky eye with an old scar across it and another scar on the jaw, no helmet, bare shoulders with a studded leather harness, calm proud gaze slightly past the viewer, ember red-orange rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

## 法师 · 皮姆·霜烬 Pim Emberfrost — `hero_mage.png`
侏儒 · 女性 · 年轻

**背景**：风暴女巫的塔倒塌后，塔下的图书馆被埋进废墟。皮姆是在那堆书里长大的孤儿，靠拼凑烧了一半的法术书自学成才，所以她的魔法总是一半火、一半冰，连她自己也说不准下一发会是哪种。她听说灰烬王冠能让人读懂任何文字，想要它不是为了统治，是为了把那些烧焦的书页全部读完。

**头像提示词**
```
a young gnome girl mage, clearly a gnome and not an elf: small round face, big button nose, large bright eyes, small rounded ears, wild silver hair under an oversized patched blue wizard hat tilted to one side, soot on one cheek, mischievous grin, a small flame half orange half icy blue hovering beside her face, icy blue and violet rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

## 圣骑士 · 奥德里克·晨誓 Aldric Dawnoath — `hero_paladin.png`
人类 · 男性 · 三十岁上下

**背景**：奥德里克是旧王国骑士团最后一个受封的骑士。受封那天，国王已经戴上了灰烬王冠，眼睛里开始泛出灰光；他对着那双眼睛宣誓效忠，而后亲眼看着他变成灰烬之王。骑士团在那之后一个个倒下，只剩他还守着誓言。他认定誓言是对王冠所代表的国家，而不是对那个人。他要把王冠从他头上摘下来，让誓言有一个干净的结局。

**头像提示词**
```
a human man paladin about thirty, short dark hair, close-trimmed beard, a thin pale scar across the bridge of the nose, tired but steady eyes looking straight at the viewer, a plain steel gorget and the top of a white tabard with a gold sun, a soft golden halo behind the head, holy gold rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

## 猎人 · 凯尔温·荆径 Kaelwen Thornstride — `hero_hunter.png`
精灵 · 女性 · 外表年轻

**背景**：精灵议会的决定是"不管外面的事"：灰烬之王烧了半个大陆，翠林的结界却从头到尾没开过。凯尔温是边境巡守，她看着结界外的村庄一座座烧光，最后砍断了自己的议会徽记，带着一条恐狼走出了森林。她不恨精灵，只是不再替他们看门。她要王冠，是想亲手试一试：一个人能不能做到整个议会不愿做的事。

**头像提示词**
```
a female elf ranger, the only hero with long pointed ears, sharp fine features, auburn hair in a loose braid, dark-green hood pushed back, two thin lines of green war paint under one eye, a small healed cut on the chin, eyes narrowed and looking off to one side, a snapped elven sigil on a cord at her collar, forest green rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

## 牧师 · 薇拉·暮钟 Vera Duskbell — `hero_priest.png`
半身人 · 女性 · 二十出头

（2026-10-22 重写：原来的老修女玛戈·烛芯不讨喜，换成年轻的角色；形象同时容纳圣光与暗影两条路线，因为牧师的天赋分圣光页和暗影页。）

**背景**：薇拉是被断墙礼拜堂的老修女们捡回来的孤儿，从小负责敲那口裂了缝的晨钟。战争打到礼拜堂那年，她第一次听见了钟声之外的东西：死在墙外的人在低声说话。她发现自己的祷文能把伤者从死亡边上拉回来，而另一种更低、更冷的祷文，能让亡者开口，甚至让敌人的影子反过来咬住他们自己。老修女们说那是异端，要她二选一。薇拉两样都留下了：光用来救人，影用来讨债。她要那顶王冠，是想把它熔成一口新钟，一口既为活人、也为亡者而鸣的钟。

**头像提示词**
```
a young halfling woman priest in her early twenties, clearly a halfling and not an elf: round face, small rounded ears, freckles, bright confident amber eyes, short dark curly hair with a single white streak, a hood that is cream linen on one side and deep violet on the other, a tiny bronze bell earring, a faint knowing half-smile, her face split by two lights: warm holy gold on the left side and cool violet shadow on the right, a few motes of light drifting on one side and thin wisps of shadow curling on the other, pale gold and shadow violet rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

## 术士 · 莫文·残烛 Morwen Lastcandle — `hero_warlock.png`
不死族 · 女性 · 死时三十余岁

**背景**：莫文曾是旧王国的宫廷占星师，也是第一个看出王冠有问题的人。她在朝堂上说出"王冠在吃国王"的那天，被刚戴上王冠的国王处死。骸骨巫妖马拉卡把她从乱葬岗里挖出来复活，想要一个会算星象的仆从，可他只拿到了半个她：另一半还留在死亡那边。她趁巫妖第十一次死去时逃了出来。如今她每施一次法，就要燃掉一点所剩无几的生命，所以她从不浪费任何一发法术。她要王冠，是因为王冠里锁着她的另一半。拿回来之后是活下去还是彻底死去，她还没决定。

**头像提示词**
```
an undead woman warlock, pale grey-blue skin cracked like old porcelain along one cheek, hollow eyes glowing fel green, long black hair gone white at the ends, a deep purple hood pulled low, a high stitched collar, faint knowing smile, a small guttering candle with a green flame held beside her face, fel green and dark purple rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, sunlit overgrown ruins softly blurred behind, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

---

如果用的不是 Midjourney：删掉末尾的 `--ar 1:1 --no ...`，在工具里选正方形，并把 text、frame、border、card、letters、numbers 填进反向提示词。
