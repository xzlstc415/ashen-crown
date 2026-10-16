# Ruinaccord 卡牌画风说明（草稿）

参考图：圣骑士先锋（暗黑写实风，2026-10-16 选定）。

## 画风关键词

- 暗黑奇幻厚涂（dark fantasy painting），写实比例，细节丰富，像主机游戏原画。
- 世界观：一切都发生在**废墟**里，比如倒塌的哥特教堂、碎裂的城墙、长满苔藓的石柱，空气里飘着灰烬和火星。
- 色调：整体偏冷灰、低饱和，只有**一个发光的重点**，用该职业的颜色（见下表）。
- 光线：阴天或暴风雨的天空，人物有强烈的轮廓光，发光的部分（剑、眼睛、法术）最亮。
- 质感：盔甲、布料要旧，有划痕、破损和锈迹，不要崭新光亮。

## 职业强调色（发光重点用这个颜色）

| 职业 | 强调色 | 英文提示词 |
|---|---|---|
| 战士 | 余烬红橙 | glowing ember red-orange |
| 法师 | 冰蓝与奥术紫 | glowing icy blue and arcane violet |
| 圣骑士 | 圣光金 | glowing holy gold |
| 猎人 | 林地翠绿 | glowing forest green |
| 牧师 | 苍白圣光 | glowing pale white-gold |
| 术士 | 邪能绿与暗紫 | glowing fel green and dark purple |
| 中立卡 | 暖色火光 | warm firelight |

## 构图（重要，关系到卡面版式）

卡面是**全图版式**：整张画就是卡牌背景，下方约 40% 会盖一个半透明的文字框（像万智牌的全图卡）。

- **一律生成竖图，比例 2:3**（Midjourney 加 `--ar 2:3`），分辨率至少 1024×1536。和参考图一样，不需要再裁切。
- **主体放在画面上方 60%**：头部、武器、发光点都在这里。下方 40% 只放地面、碎石、雾气这类简单背景，因为会被文字框挡住。
- 场上的随从小头像会取画面上半部分，所以**脸或最有辨识度的部位要在上三分之一**。
- 一张图只有一个主体，背景要比主体暗、模糊，这样在手机上缩小后还能认出来。
- 法术牌画"正在施放的瞬间"：法术效果本身是主体（例如冰箭、火焰、光柱），可以露出施法者的手，但不画完整人物。
- 不要文字、不要水印、不要画框和边框。

## 通用后缀（每条提示词末尾都加）

```
dark fantasy digital painting, ruined gothic world, ash and embers in the air, overcast stormy sky, dramatic rim lighting, muted desaturated palette with one strong glowing accent, highly detailed, cinematic, painterly, no text, no watermark, no border --ar 2:3
```

## 第一批测试提示词

先用这四张验证不同类型的牌能不能保持统一，没问题再批量出。

1. **圣骑士先锋**（已有参考图，可以直接用；想改成女骑士的话用这条重出）
```
a female paladin knight in battered blackened plate armor with gold trim, great helm with a glowing cross-shaped visor slit, a broken halo of golden thorns floating behind the head, tattered white tabard with a gold sun emblem, huge cracked tower shield with a gold sunburst and glowing gold cracks, longsword lowered, standing guard in a ruined cathedral with a shattered rose window, glowing holy gold accent, [通用后缀]
```

2. **寒冰箭**（法术牌）
```
a jagged spear of glowing ice streaking across the frame, frost crystals and shards trailing behind it, a gauntleted hand at the edge releasing it, ruined frozen courtyard with broken pillars in the background, glowing icy blue and arcane violet accent, [通用后缀]
```

3. **恐狼**（野兽）
```
a huge scarred dire wolf with grey matted fur, snarling, low and ready to pounce among fallen stones of a ruined wall, breath steaming in the cold air, eyes reflecting firelight, warm firelight accent, [通用后缀]
```

4. **灰烬巨龙伊格纳洛斯**（传说）
```
an enormous ancient dragon with ash-grey cracked scales and molten veins, wings spread over a burning ruined city, perched on a collapsed cathedral tower, fire glowing in its throat, embers raining down, warm firelight accent, [通用后缀]
```

## 出图后怎么交给我

把图片放进仓库的 `art/raw/` 文件夹，文件名用卡牌 ID，例如 `knight.png`、`frostbolt.jpg`（PNG、JPG、WebP 都可以）。然后运行：

```sh
python3 art/build_art.py   # 裁成 2:3，生成网页和 App 用的 JPEG
python3 src/build.py       # 重新生成网站
```

或者直接把图发给我，我来放。`art/raw/` 不进 git（原图太大），生成的 `img/cards/` 和 App 里的 `Paint` 素材会提交。
