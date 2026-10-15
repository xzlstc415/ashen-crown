# 灰烬王冠 iOS App（TestFlight）

这个文件夹是一个完整的 Xcode 工程：一个原生 iOS 壳，里面打包了整套游戏网页，所以不联网也能玩冒险和自由对战。好友对战需要联网，app 和网页版的玩家可以互相对战。

- `AshenCrown.xcodeproj`：用 Xcode 打开它。
- `AshenCrown/Web/`：打包进 app 的游戏文件，由 `python3 src/build.py` 自动同步，不要手改。
- `AshenCrown/*.swift`：app 代码（全屏网页视图 + 本地文件加载）。
- `gen_pbxproj.py`：重新生成工程文件。只有新增 Swift 文件时才需要运行；往 `Web/` 里加文件不用。

默认设置：Bundle ID 为 `com.hermes-eris.ashencrown`，版本 1.0（Build 1），最低支持 iOS 15，iPhone 竖屏、iPad 全方向。桌面名称会跟随系统语言：简体中文显示「灰烬王冠」，日文显示「灰燼の王冠」，其他语言显示「Ashen Crown」。

---

## 第 1 步：在 Mac 上打开工程

1. 安装最新版 Xcode（App Store 里搜 Xcode）。
2. 在 Xcode → Settings → Accounts 里，用你的 Apple 开发者账号登录。
3. 获取代码并打开工程：
   ```
   git clone https://github.com/xzlstc415/ashen-crown.git
   open ashen-crown/ios/AshenCrown.xcodeproj
   ```

## 第 2 步：设置签名

1. 在左侧点最上面的 **AshenCrown**（蓝色图标），中间选 TARGETS → **AshenCrown** → **Signing & Capabilities**。
2. 勾选 **Automatically manage signing**，**Team** 选你的开发者团队。
3. **Bundle Identifier** 默认是 `com.hermes-eris.ashencrown`。如果提示已被占用，改成别的，例如 `com.你的名字.ashencrown`。

## 第 3 步：先在自己的 iPhone 上试一下（推荐）

1. 用数据线连接 iPhone，在 Xcode 顶部的设备菜单里选中它，按 ⌘R 运行。
2. 第一次需要在 iPhone 上开启「设置 → 隐私与安全性 → 开发者模式」，手机会重启一次。
3. 试一遍以下几项：
   - 冒险模式能正常进行。
   - 自由对战里新建并保存牌组，杀掉 app 再打开，牌组还在。
   - 好友对战：手机 app 开房间，另一台设备用浏览器打开 ashen-crown.hermes-eris.com 加入。

## 第 4 步：在 App Store Connect 创建 app

1. 打开 https://appstoreconnect.apple.com → **App** → 左上角 **＋** → **新建 App**。
2. 按下面填写：
   - **平台**：iOS
   - **名称**：灰烬王冠。名称在整个 App Store 必须唯一，被占用就换一个，例如「灰烬王冠 Ashen Crown」。
   - **主要语言**：简体中文
   - **套装 ID**：选第 2 步里的 Bundle ID。如果列表里没有，先在 Xcode 里运行一次（第 3 步），或者到 developer.apple.com → Identifiers 手动注册。
   - **SKU**：`ashencrown`，随便填，自己看得懂就行。
   - **用户访问权限**：完全访问

## 第 5 步：打包上传

1. 在 Xcode 顶部的设备菜单选 **Any iOS Device (arm64)**。
2. 菜单 **Product → Archive**，等待一两分钟。
3. 弹出的 Organizer 里选刚才的归档，点 **Distribute App** → **App Store Connect** → **Upload**，后面一路默认即可。
4. App Store Connect 处理上传通常需要 10～30 分钟，处理完会发邮件通知。

加密出口合规：工程已经声明不使用非豁免加密（`ITSAppUsesNonExemptEncryption = NO`），所以不会再问这个问题。

## 第 6 步：通过 TestFlight 分发给朋友

进入 App Store Connect → 你的 app → **TestFlight** 标签。

### 内部测试（最快，不用审核）

适用于你开发者团队里的成员，最多 100 人。

1. 在 **内部测试** 下点 ＋ 新建群组，加入测试员。
2. 把构建版本添加到这个群组。

### 外部测试（给朋友，需要一次 Beta 审核）

1. 点 **外部测试** 旁的 ＋，新建群组，例如「朋友」。
2. 填写 **测试信息**，可以直接用下面的文字：
   - **Beta 版 App 描述**：灰烬王冠是一款奇幻卡牌对战游戏。选择六个职业之一，挑战八名敌人的冒险，自己组牌对战 AI，或通过房间码与好友在线对战。支持中文、英文和日文。
   - **反馈电子邮件**：你自己的邮箱。
   - **隐私政策网址**：`https://ashen-crown.hermes-eris.com/privacy.html`
   - **测试内容**：请试玩冒险模式和自由对战，并和朋友试一局好友对战（一人创建房间，另一人输入 6 位房间码）。遇到连不上、卡住或显示问题，请截图反馈。
   - **Beta 版 App 审核信息**：填写你的联系方式。这个 app 不需要登录，「需要登录」不要勾选。
3. 把构建版本加入群组，然后点 **提交审核**。第一次审核通常一天内完成，之后同一版本号下的新构建一般不用再审。
4. 审核通过后，在群组里开启 **公开链接**，把链接发给朋友。朋友先在 App Store 安装 **TestFlight**，再点链接安装灰烬王冠。

外部测试最多 10,000 人。每个构建版本 90 天后过期，过期前上传新构建即可。

---

## 以后更新游戏

1. 改好游戏后，在仓库根目录运行 `python3 src/build.py`。这一步会同时更新网站和 `ios/AshenCrown/Web/`。
2. 在 Xcode 里把 **Build** 号加 1。位置是 General → Identity → Build。如果是较大的更新，也可以把 **Version** 改成 1.1。
3. 重复第 5 步上传，然后在 TestFlight 里把新构建加入测试群组。

## 已知限制

- **邀请链接打开的是网站，不是 app。** 好友在浏览器里也能直接加入对战。要让链接直接拉起 app，需要配置 Universal Links：在网站上放一个 apple-app-site-association 文件，并在 Xcode 里开启 Associated Domains。这一步要用到你的 Team ID，以后需要时再加。
- **好友对战用的是免费的 PeerJS 配对服务器。** 那个服务器出问题时就无法开房。
- **把 app 切到后台超过 60 秒**，对局会判对方胜，和网页版一样。
