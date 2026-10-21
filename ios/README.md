# Ruinaccord iOS App（原生版）

这个文件夹是一个完整的原生 iOS 工程（SwiftUI，iOS 17+，只支持横屏）。游戏规则、卡牌、AI 和三种语言都是用 Swift 重写的，不再内嵌网页。

战斗操作是拖拽式的：手牌在自己回合扇形排在底部，拖到场上打出（指向性法术直接拖到目标上），点一下抬起、再点一下也能打出，按住可以放大看；对方回合手牌收到右下角，点一下可以临时展开。随从从自己这边拖出箭头指向目标即可攻击，英雄技能同样可拖；点选操作仍然保留。

- **账号**：通过 Apple 登录（Sign in with Apple），也可以以游客身份玩单机模式。
- **数据**：牌组、语言和战绩保存在 Firebase 的云数据库（Cloud Firestore）里，换设备也在；游客升级为 Apple 账号时牌组会一起带过去。
- **在线对战**：随机匹配（排队系统）和好友房间码，都用 Firestore 实现，不需要自己架服务器。Firebase 免费额度对小规模玩家足够。
- **冒险模式 / 自由对战**：完全本地运行，没网也能玩。

## 目录

- `project.yml`：工程定义，用 [xcodegen](https://github.com/yonaskolb/XcodeGen) 生成 `Ruinaccord.xcodeproj`（已生成好，直接打开也行）。
- `Ruinaccord/App`：入口。`Ruinaccord/Model`：卡牌数据与三语文本。`Ruinaccord/Game`：规则引擎、AI、对局/联网逻辑。`Ruinaccord/Services`：Firebase 与本地存储。`Ruinaccord/Views`：SwiftUI 界面。
- `Ruinaccord/Resources/GameData.json` 和 `Assets.xcassets/Art`：由 `node ios/tools/gen_data.mjs` 从网页版 `src/game.html` 自动生成（卡牌、职业、敌人和所有矢量插画）。改卡牌后在仓库根目录运行它即可。
- `firestore.rules`：数据库安全规则。
- `RuinaccordTests`：规则引擎单元测试（含随机整局模拟）。

默认 Bundle ID `com.hermes-eris.ruinaccord`，版本 2.0（Build 1）。

---

## 第 1 步：创建 Firebase 项目（一次性，约 15 分钟）

1. 打开 https://console.firebase.google.com → **添加项目**，名字随意（例如 `ruinaccord`），不需要 Google Analytics。
2. 项目里点 **iOS+** 添加 iOS 应用，Bundle ID 填 `com.hermes-eris.ruinaccord`（要和 Xcode 里一致）。下载 **GoogleService-Info.plist**，放到 `ios/Ruinaccord/Resources/GoogleService-Info.plist`（旁边有一个 `.example` 做参考；这个文件已在 `.gitignore` 里）。
3. **Authentication → Sign-in method**：启用 **Apple** 和 **匿名**（Anonymous）。Apple 这一项在 iOS 原生登录下不需要填 Services ID。
4. **Firestore Database → 创建数据库**，选生产模式，区域随便（离玩家近即可）。
5. **Firestore → 规则**：把 `ios/firestore.rules` 的内容整个粘贴进去，点发布。

**放好 plist 之后，在 `ios` 文件夹里运行一次 `xcodegen generate`**，否则 Xcode 工程里不包含这个文件，App 仍然是离线模式（打开时不出现登录页就说明没包含进去）。

没有这个 plist 文件时 app 也能编译运行，但会进入“离线模式”：牌组只存在本机，在线对战不可用（界面会提示）。

## 第 2 步：在 Xcode 里打开并签名

1. 安装最新 Xcode，`open ios/Ruinaccord.xcodeproj`。第一次打开会自动下载 Firebase 依赖（Swift Package，约 1 GB，耐心等）。
2. 左侧点蓝色 **Ruinaccord** → TARGETS → Ruinaccord → **Signing & Capabilities**：勾选 Automatically manage signing，选你的 Team。**Sign in with Apple** 能力已经在工程里配置好；如果 Apple 提示要先在开发者网站给 App ID 开启 Sign in with Apple，照做一次即可。
3. 如果改了 Bundle ID，Firebase 里的 iOS 应用也要用同一个 ID 重新添加。

## 第 3 步：在手机上试

连上 iPhone，⌘R。登录页可以 **通过 Apple 登录** 或 **以游客身份继续**。建议试一遍：

- 冒险模式打一两局；自由对战里建一副牌并保存，杀掉 app 重开，牌组还在（Firebase 控制台 → Firestore → `users/<uid>/decks` 里也能看到）。
- 在线对战：两台设备（或一台真机 + 模拟器，各自用不同的 Apple ID 登录）同时点 **随机匹配**，几秒内会配到一起；或者一台 **创建房间**，另一台输入 6 位码 **加入**。
- 设置（右上角齿轮）里可以切换语言、退出登录、删除账号（App Store 审核要求必须有）。

## 第 4 步：App Store Connect 与 TestFlight

和之前一样：

1. https://appstoreconnect.apple.com → App → ＋ 新建 App，套装 ID 选 `com.hermes-eris.ruinaccord`，主要语言简体中文，SKU `ruinaccord`。
2. Xcode 顶部设备选 **Any iOS Device (arm64)** → **Product → Archive** → Distribute App → App Store Connect → Upload。
3. TestFlight 内部测试不需要审核；外部测试需要一次 Beta 审核。审核信息里 **需要登录** 可以不勾（有游客模式），隐私政策网址填 `https://ruinaccord.hermes-eris.com/privacy.html`（已更新了账号相关说明）。
4. **App 隐私**问卷：选择收集“用户 ID”和“其他用户内容”（牌组），用途“App 功能”，关联到用户，不用于追踪。`PrivacyInfo.xcprivacy` 里已经做了同样的声明。

加密出口合规已声明为不使用非豁免加密。

## 以后更新

- 改卡牌 / 平衡：改 `src/game.html`，运行 `python3 src/build.py`（网站）和 `node ios/tools/gen_data.mjs`（app 数据与插画）。规则版本号由卡牌数据自动算出，版本不同的玩家不会被匹配到一起。
- 改界面或逻辑：直接改 Swift 文件。新增 Swift 文件不用做别的，xcodegen 按目录收集；如果改了 `project.yml`，运行 `xcodegen generate`。
- 发版：先提交并推送改动，然后在仓库根目录运行 `scripts/testflight.sh`。它会把版本号加一位（例如 2.0.1 变成 2.0.2，也可以写 `scripts/testflight.sh 2.1.0` 指定），打包、上传到 TestFlight，再提交 "Release x.y.z"、打标签并推送。Build 号自动用当前时间。签名用的是本机的 Apple Distribution 证书和 "Ruinaccord App Store" 描述文件（2027-10-07 到期），上传用 `~/.appstoreconnect/private_keys` 里的团队 API 密钥。
- 跑测试：`xcodebuild test -project ios/Ruinaccord.xcodeproj -scheme Ruinaccord -destination 'platform=iOS Simulator,name=iPhone 17'`。
  测试里的 `testClassBalance` 会让 AI 两边对打约 1800 局，并打印各职业胜率（BALANCE 一行）；改卡牌后看一眼，胜率应在 30%–70% 之间。
- 模拟器截图：加启动参数 `-local`（不签名的模拟器构建无法使用 Firebase 钥匙串），例如 `-local -screen duel -autoplay -lang zh`。`-sel 1` 抬起第二张手牌；`-card frostbolt,goblin,berserker -dragtest` 用代码走一遍拖拽出牌、拖法术到敌方英雄、拖随从攻击和拖英雄技能，并在控制台打印结果（`xcrun simctl launch --console-pty`）。

## 在线对战是怎么工作的

- 每局是 Firestore 里的一个 `matches/{id}` 文档，里面存完整的对局状态（以创建者视角）和当前回合的操作列表。轮到谁，谁就把自己的操作和操作后的状态写进去；对方的 app 监听这个文档，把操作带动画回放一遍，然后核对状态指纹，不一致就直接采用文档里的状态。
- 随机匹配：排队的人在 `queue/{uid}` 留一张票；进来的人用事务认领一张等待中的票并创建对局，所以两个人不会抢到同一个对手。90 秒没刷新的票会被忽略。
- 每 15 秒写一次心跳；对手 60 秒没心跳就判你胜（和网页版一样，切到后台太久会输）。

### 已知限制

- 对局文档里能看到双方的手牌和牌库顺序。普通玩家看不到，但懂技术的人用自己的账号能读到自己对局的数据。朋友之间休闲对战没问题；要做排名赛需要加 Cloud Functions 做服务端裁判。
- 网页版的好友对战（PeerJS）和 app 的在线对战是两套系统，互不相通。
- 排行榜、好友列表、推送通知都没有做。
