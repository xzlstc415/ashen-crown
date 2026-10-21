# Ruinaccord 卡牌画风说明

第二版（2026-10-16）：第一版"暗黑写实"太重，改成更轻、更风格化的手绘风，方向参考《英雄联盟》原画和《杀戮尖塔》。

## 画风关键词

- **风格化手绘插画**，不是照片级写实。形体要概括、轮廓清楚，像游戏原画而不是电影截图。
- **轮廓第一**：一眼能看出是什么（骑士、狼、冰箭），缩到手机上很小也能认出来。
- **颜色明快**：饱和度中等偏高，明暗对比清楚。阴影用带颜色的暗部（偏紫、偏蓝），不要发灰发黑。
- **细节适量**：大块面干净，只在脸、武器、发光点这些重点上画细节。不要满屏的划痕、锈迹、碎屑。
- **世界观不变**：还是废墟世界，但画面是"阳光照进废墟、藤蔓爬上石柱"，不是末日焦土。
- **只画插画本身**：不要卡框、边框、文字、数字、图标、费用宝石。这些由游戏来画。

## 两个可选方向

用同一张牌各生成一次，选更喜欢的那个，之后所有牌统一用它。

**方向 A：英雄联盟原画风**（更华丽）
- 半写实的厚涂，人物比例略夸张（肩更宽、武器更大）。
- 光影戏剧化，有明显的轮廓光和发光特效。
- 背景有景深，但比主体暗、虚。

**方向 B：杀戮尖塔风**（更简洁）
- 手绘感更强，笔触明显，形体更简化，接近绘本。
- 颜色块更平，阴影层次少，配色更有限。
- 背景很简单，常常只是一块渐变或几笔暗示的场景。

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

## 构图（关系到卡面版式）

卡面是**全图版式**：整张画就是卡牌背景，下方约 40% 会盖一个半透明的文字框。

- **竖图，比例 2:3**，至少 1024×1536。
- **主体放在画面上方 60%**：头部、武器、发光点都在这里。下方 40% 只放地面、碎石、雾气这类简单背景。
- 场上的随从小头像取画面上半部分，所以**脸或最有辨识度的部位要在上三分之一**。
- 一张图只有一个主体，背景比主体暗、简单。
- 法术牌画"正在施放的瞬间"：法术效果本身是主体，可以露出施法者的手，但不画完整人物。

## 姿态与构图：避免「一个模子刻出来」（2026-10-20 补充）

第一批出图的问题：人物几乎都是正面站立、居中、看镜头、手里拿着东西。原因是提示词只写了「谁 + 拿着什么」，没写镜头和动作，模型就默认用最保守的站姿。现在每条提示词都写明三件事：

1. **镜头角度**：仰视、俯视、正上方、侧面剪影、从背后看、越肩、远景、特写、斜构图。同一费用段和同一职业里尽量不重复。
2. **动作和姿态**：跃起、扑下、转身回头、坐着、跪着、倒挂、靠着、绊倒、奔跑。站着的也要有重心和情绪，比如前倾、喘气、叉腰。
3. **朝向**：面朝左、面朝右、背对、正对冲向镜头，交替使用。

可以借鉴的写法：

| 写法 | 例子 |
|---|---|
| 从背后看、回头 | seen from behind, looking back over the shoulder |
| 极端透视冲向镜头 | charging straight at the viewer, extreme foreshortening |
| 仰视显得巨大 | seen from a worm's-eye angle, filling the frame |
| 俯视显得渺小或安静 | seen from above, kneeling on the floor |
| 侧面剪影 | strict side profile facing left |
| 姿态里带性格 | leaning lazily, picking its tusk / tripping over its own sword |

如果出图还是正面站立，在提示词开头加 `dynamic pose, not standing straight, not facing the camera`。小头像会取画面上半部分，所以姿态再自由，**脸或最有辨识度的部位也要留在画面上三分之一**。

## 法术牌之间要拉开

同类法术（尤其是防御和增益）不能只是「一个盾 + 不同颜色」。每张防御法术都给一个独有的**形状**和**材质**，并配不同的镜头：

| 卡 | 形状 | 材质与颜色 | 镜头 |
|---|---|---|---|
| 信仰之盾 | 扎根在地里的木塔盾 | 金色光之树根缠绕固定 | 仰视 |
| 圣盾术 | 羽毛落下后绽开的泡泡 | 半透明彩虹肥皂泡，金与淡粉 | 正上方 |
| 真言术：盾 | 低语化成的长丝带 | 苍白丝带像绷带一样缠绕，淡金与淡蓝 | 侧面 |
| 王者祝福 | 落下的光之王冠 + 披风 | 深红与金，王家感 | 仰视 |
| 盾墙 | 一排参差的矮人盾 | 铁灰与土褐，箭被弹开 | 盾后极低视角 |
| 寒冰屏障 | 冰晶洞（像晶洞内部） | 多面冰晶，敌人冻在外面 | 斜上方 |
| 圣所庇佑 | 自动重建的礼拜堂墙 | 半透明光砖 | 俯视 |
| 治愈之光 | 金液流进铠甲裂缝 | 像金缮修补陶器 | 微距特写 |

其他法术也遵循同一原则：同职业里相邻费用的法术，形状（球、线、环、柱、雨、碎片）和镜头要不同。

## 通用后缀（每条提示词末尾加一个）

方向 A：
```
stylized fantasy splash art, painterly digital illustration, bold readable silhouette, vibrant saturated colors, colorful shadows, dramatic rim lighting, clean shapes, sunlit overgrown ruins in the background, game key art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

方向 B：
```
hand-painted storybook illustration, simplified shapes, bold clean silhouette, flat color blocks with soft brush texture, limited palette, minimal simple background, roguelike card game art, full-bleed illustration only, no card frame, no border, no text, no letters, no numbers, no icons, no UI --ar 2:3 --no text, frame, border, card, letters, numbers, logo, watermark
```

如果用的不是 Midjourney，把末尾的 `--ar 2:3 --no ...` 去掉，在工具里选竖图 2:3，并把 "text, frame, border, card, letters, numbers" 填进反向提示词（negative prompt）。

## 测试提示词

每张都用 A、B 两个后缀各生成一次。

1. **圣骑士先锋**（4 费 3/5 随从，守护）
```
a female paladin knight in polished silver plate armor with gold trim, open-face helm, a radiant golden halo behind her head, white tabard with a gold sun emblem, raising a big kite shield with a glowing gold sunburst, standing firm on cracked steps, glowing holy gold accent, [后缀]
```

2. **寒冰箭**（2 费法师法术）
```
a jagged bolt of glowing ice flying toward the viewer, trailing frost crystals and cold mist, a gloved hand at the bottom edge just releasing it, glowing icy blue and arcane violet accent, [后缀]
```

3. **恐狼**（2 费 3/2 野兽）
```
a big grey dire wolf with a thick mane and a scar over one eye, snarling and crouched to pounce on a broken stone ledge, eyes reflecting firelight, warm firelight accent, [后缀]
```

4. **灰烬巨龙伊格纳洛斯**（8 费 7/8 传说龙，守护，登场时对所有敌方随从造成 2 点伤害）
```
an enormous ash-grey dragon with glowing molten cracks along its scales, wings spread wide, coiled protectively on top of a ruined cathedral tower, breathing a sweeping wave of fire downward, warm firelight accent, [后缀]
```

## 出图后怎么交给我

把图片放进 `art/raw/`，文件名用卡牌 ID，例如 `knight.png`、`frostbolt.png`、`direwolf.png`、`leviathan.png`。然后运行：

```sh
python3 art/build_art.py   # 裁成 2:3，生成网页和 App 用的 JPEG
python3 src/build.py --beta
```

或者直接把图发给我，我来放。`art/raw/` 不进 git，生成的 `img/cards/` 和 App 的 `Paint` 素材会提交。
