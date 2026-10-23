# Ruinaccord 六位英雄：种族、名字、头像提示词与背景

世界观回顾：灰烬之王曾统治这片大陆，他的王冠在灰烬巨龙伊格纳洛斯的龙息中锻成。王朝倾覆后，世界成了"阳光照进废墟、藤蔓爬上石柱"的样子。冒险者从哥布林战团一路打到灰烬之王，要把那顶王冠夺回来。六位英雄各有自己要戴上王冠的理由。

## 头像统一规范（2026-10-21 修订）

第一批出图的问题：脸在画面上三分之一、铠甲占了一半画面（圆形头像一裁，中间是胸甲不是脸）；侏儒和半身人都画成了精灵（尖耳朵）；两张猎人和其余四张不是同一种笔触。所以这版把六条提示词改成**同一个框架**：

- **构图固定**：平视镜头，头和肩膀，脸在画面正中央、占画面高度约三分之二，头顶贴近上边缘，肩膀在下边缘被裁掉。头像是圆形的，裁掉四角后剩下的必须是脸。
- **光线固定**：左上方一盏主光，职业强调色只做轮廓光。
- **背景按职业区分**（2026-10-22 修订）：战士角斗场、法师魔法图书馆、圣骑士战场、猎人森林、牧师修道院、术士暗黑墓穴，统一虚化处理。
- **种族特征放在最前面**，而且写明"不是精灵"：只有猎人有尖耳朵。
- **主体描述尽量短**：细节越多，模型越往写实大头照跑。
- **一次出完六张**：用同一个风格参考（例如 `--sref` 指向已通过的兽人头像或 `art/raw/knight.png`，`--sw 100`）和同一个 `--seed`，避免像第一批那样两张猎人跑成另一种笔触。

六条提示词都用下面这段统一后缀（`<the class backdrop>` 换成各职业自己的背景）：

```
head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, <the class backdrop, softly blurred>, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic
```

出图后把文件按标题里的文件名放到 `art/heroes/`（例如 `hero_warrior.png`）。

| 职业 | 种族 | 名字 | 一句话 |
|---|---|---|---|
| 战士 | 兽人 | 洛克·灰牙 Rok Greytusk | 从兽人督军麾下出走的持盾者 |
| 法师 | 侏儒 | 皮姆·霜烬 Pim Emberfrost | 在废墟图书馆长大的自学法师 |
| 圣骑士 | 人类 | 奥德里克·晨誓 Aldric Dawnoath | 把残存骑士团变成一股政治力量的团长 |
| 猎人 | 精灵 | 凯尔温·荆径 Kaelwen Thornstride | 退出精灵议会的林地巡守 |
| 牧师 | 不明 | 雷恩·暮钟 Wren Duskbell | 同时听得见圣光与亡者低语的年轻敲钟人 |
| 术士 | 不死族 | 莫文·残烛 Morwen Lastcandle | 被巫妖复活、只剩半条命的宫廷占星师 |

---

## 战士 · 洛克·灰牙 Rok Greytusk — `hero_warrior.png`
兽人 · 男性 · 中年

**背景**：兽人有一条老规矩：盾只为值得的人举。洛克在兽人督军麾下当了二十年持盾者，替督军挡下过数不清的箭，从没问过值不值得。灰烬之王的军队压到营前那天，督军跪下了，而督军献上的第一份投名状，是一座一直跟战团公平交易的边境村庄。洛克那天没有举盾。他把盾放在督军脚边，转身走出营地，走出很远才又把它背起来。从那以后，他只替自己选的人挡箭。他要王冠，是为了让跪下去的人再也不必跪。

**头像提示词**
```
a scarred orc chieftain, moss-green skin, heavy brow, two moderate lower tusks, long black mane braided with bone beads, one blind milky eye with an old scar across it and another scar on the jaw, no helmet, bare shoulders with a studded leather harness, calm proud gaze slightly past the viewer, ember red-orange rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, behind him a sun-baked gladiator arena: worn sandstone tiers, torn red banners, dust hanging in the hot air, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, overgrown ruins
```

## 法师 · 皮姆·霜烬 Pim Emberfrost — `hero_mage.png`
侏儒 · 女性 · 年轻

**背景**：风暴女巫的塔倒塌后，塔下的图书馆被埋进废墟。皮姆是在那堆书里长大的孤儿，靠拼凑烧了一半的法术书自学成才，所以她的魔法总是一半火、一半冰，连她自己也说不准下一发会是哪种。她听说灰烬王冠能让人读懂任何文字，想要它不是为了统治，是为了把那些烧焦的书页全部读完。

**头像提示词**
```
a young gnome girl mage, clearly a gnome and not an elf: small round face, big button nose, large bright eyes, small rounded ears, wild silver hair under an oversized patched blue wizard hat tilted to one side, soot on one cheek, mischievous grin, a small flame half orange half icy blue hovering beside her face, icy blue and violet rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, behind her a magical library: towering shelves of old books, a few glowing pages and faint runes drifting in the air, warm candle and arcane blue light, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, overgrown ruins
```

## 圣骑士 · 奥德里克·晨誓 Aldric Dawnoath — `hero_paladin.png`
人类 · 男性 · 三十岁上下

（2026-10-22 重写：不只是圣洁的好人，而是精明、自信、权力欲旺盛的强人，性格参照凯撒。）

**背景**：奥德里克是旧王国骑士团的团长，也是骑士团里最年轻的一位。国王戴上灰烬王冠、眼睛开始泛出灰光的那天，老团长们选择了沉默，奥德里克选择了记账：哪位领主还有兵，哪座城还有粮，哪位主教还肯说话。王朝倾覆后，他把散落各地的残存骑士重新集结起来，用誓言、联姻和恰到好处的宽恕把半个北境收拢到自己的旗下。被他击败的叛军领主，他一个都没杀，全都放回去，让他们欠着他的人情。士兵爱他，因为他和他们同吃同睡；贵族怕他，因为他从不忘记谁欠了他什么。他说自己的誓言是对国家，而不是对那个戴王冠的人；他没说出口的是，他早已认定，这个国家最好的君主就是他自己。他要那顶王冠，是为了把它从灰烬之王头上摘下来，然后，也许，亲手戴上。

**头像提示词**（2026-10-22：刚毅、精明、自信，凯撒式的统帅气质）
```
a human man paladin knight-commander about thirty with a hard, resolute, commanding face in the manner of a Roman general: a strong square jaw, high sharp cheekbones, a heavy straight brow, short dark hair cropped close and brushed forward, close-trimmed beard, a thin pale scar across the bridge of the nose and another through one eyebrow, shrewd calculating eyes that hold the viewer's gaze with total self-assurance, the faint hint of a knowing, ambitious smile at one corner of a firm mouth, chin slightly raised, a polished steel gorget, a crimson commander's cloak fastened at the shoulder with a gold sun clasp, a thin gold laurel embroidered along the collar, a white tabard with a gold sun just visible, hard-edged holy gold rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, behind him a battlefield: his own banners raised through drifting smoke, rows of soldiers far away, golden late-day light through the dust, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, overgrown ruins, gentle smile, soft features, kind eyes, halo, humble expression
```

## 猎人 · 凯尔温·荆径 Kaelwen Thornstride — `hero_hunter.png`
精灵 · 女性 · 外表年轻

**背景**：精灵议会的决定是"不管外面的事"：灰烬之王烧了半个大陆，翠林的结界却从头到尾没开过。凯尔温是边境巡守，她看着结界外的村庄一座座烧光，最后砍断了自己的议会徽记，带着一条恐狼走出了森林。她不恨精灵，只是不再替他们看门。她要王冠，是想亲手试一试：一个人能不能做到整个议会不愿做的事。

**头像提示词**（2026-10-22：改为拉弓瞄准的瞬间）
```
a female elf ranger drawing her longbow to full draw and aiming, the only hero with long pointed ears, sharp fine features, auburn hair in a loose braid, dark-green hood pushed back, two thin lines of green war paint under one eye, a small healed cut on the chin, one eye narrowed in focus and fixed on a target off to the right, the bowstring pulled back to the corner of her mouth with two fingers, the arrow shaft running past her cheek toward the right of the frame with its fletching beside her face, a snapped elven sigil on a cord at her collar, forest green rim light along the arrow and her profile, tight three-quarter portrait of head, hands and the drawn string, the face slightly left of centre and filling about half of the frame, the arrowhead and bow inside the frame, the corners left empty for a round crop, one key light from the upper left, behind her a deep sunlit forest: tall mossy trees, ferns and shafts of green-gold light, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, overgrown ruins, looking at the viewer, relaxed bow
```

## 牧师 · 雷恩·暮钟 Wren Duskbell — `hero_priest.png`
种族不明（外表近似人类） · 性别不明（形象为非常中性的年轻男子） · 二十出头

（2026-10-22 重写：原来的老修女玛戈·烛芯不讨喜，换成年轻的角色；性别刻意不点明，外貌按非常中性化的男子来画；形象同时容纳圣光与暗影两条路线，因为牧师的天赋分圣光页和暗影页。背景文字不使用性别代词。）

**背景**：雷恩是被断墙礼拜堂的老修女们捡回来的孤儿，没有人知道雷恩从哪里来、是什么血统：看上去像人类，却从不生病，也几乎不见长大。从小负责敲那口裂了缝的晨钟。战争打到礼拜堂那年，雷恩第一次听见了钟声之外的东西：死在墙外的人在低声说话。雷恩的祷文能把伤者从死亡边上拉回来，而另一种更低、更冷的祷文，能让亡者开口，甚至让敌人的影子反过来咬住敌人自己。老修女们说那是异端，要雷恩二选一。雷恩两样都留下了：光用来救人，影用来讨债。雷恩要那顶王冠，是想把它熔成一口新钟，一口既为活人、也为亡者而鸣的钟。

**头像提示词**
```
a young human priest in their early twenties with a very androgynous, delicate look, gender ambiguous, read as a soft-featured young man: smooth fine features, high cheekbones, calm grey eyes with long lashes, no beard, shoulder-length straight silver-black hair parted in the middle, a hood that is cream linen on one side and deep violet on the other, a tiny bronze bell earring, a serene unreadable half-smile, the face split by two lights: warm holy gold on the left side and cool violet shadow on the right, a few motes of light drifting on one side and thin wisps of shadow curling on the other, pale gold and shadow violet rim light, head-and-shoulders portrait, eye-level camera, the face exactly centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, one key light from the upper left, behind them the quiet cloister of an old monastery: stone arches, a stained-glass window and candlelight, half in warm light and half in violet shadow, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, overgrown ruins, muscular, heavy jaw, makeup
```

## 术士 · 莫文·残烛 Morwen Lastcandle — `hero_warlock.png`
不死族 · 女性 · 死时三十余岁

**背景**：莫文曾是旧王国的宫廷占星师，也是第一个看出王冠有问题的人。她在朝堂上说出"王冠在吃国王"的那天，被刚戴上王冠的国王处死。骸骨巫妖马拉卡把她从乱葬岗里挖出来复活，想要一个会算星象的仆从，可他只拿到了半个她：另一半还留在死亡那边。她趁巫妖第十一次死去时逃了出来。如今她每施一次法，就要燃掉一点所剩无几的生命，所以她从不浪费任何一发法术。她要王冠，是因为王冠里锁着她的另一半。拿回来之后是活下去还是彻底死去，她还没决定。

**头像提示词**（2026-10-22：改为侧脸、暗黑背景；按之前的决定去掉"空洞的眼睛"，把生命之烛放到画面前景）
```
an undead woman warlock in side profile facing left, pale grey-blue skin cracked like old porcelain along her cheekbone, a single visible eye with a faint fel green glow, a sharp elegant profile with a thin nose and lips, long black hair gone white at the ends falling from a deep purple hood, a high stitched collar, a small guttering candle of life with a green flame held in front of her face in the foreground, its light the only warm thing on her face, fel green and dark purple rim light tracing the profile, head-and-shoulders portrait, the head centered and filling about two thirds of the frame, top of the head near the top edge, shoulders cut off by the bottom edge, dark gothic background: a gloomy crypt in deep shadow, black and violet mist, faint gravestones barely visible, softly blurred, same painterly style as the card illustrations: hand-painted, simplified shapes, bold clean silhouette, soft brush texture, limited palette, roguelike card game art, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 1:1 --no text, frame, border, card, letters, numbers, logo, watermark, full body, armor filling the frame, photorealistic, front view, sunlight
```

---

如果用的不是 Midjourney：删掉末尾的 `--ar 1:1 --no ...`，在工具里选正方形，并把 text、frame、border、card、letters、numbers 填进反向提示词。
