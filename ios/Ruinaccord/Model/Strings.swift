import Foundation

/// The three game languages. `idx` indexes the [en, zh, ja] name arrays in GameData.json.
enum Lang: String, CaseIterable, Codable, Identifiable {
    case en, zh, ja
    var id: String { rawValue }
    var idx: Int { self == .zh ? 1 : self == .ja ? 2 : 0 }
    var label: String { self == .en ? "EN" : self == .zh ? "中文" : "日本語" }
    var isCJK: Bool { self != .en }

    static var system: Lang {
        let code = (Locale.preferredLanguages.first ?? "en").lowercased()
        return code.hasPrefix("zh") ? .zh : code.hasPrefix("ja") ? .ja : .en
    }
}

/// All user-facing text. Mirrors the I18N table of the web game; `**` marks bold in Markdown-rendered text.
struct Tx {
    let lang: Lang
    func pick(_ en: String, _ zh: String, _ ja: String) -> String { lang == .zh ? zh : lang == .ja ? ja : en }
    func name(_ names: [String]) -> String { names.indices.contains(lang.idx) ? names[lang.idx] : names.first ?? "" }

    var brand: String { pick("Ruinaccord", "Ruinaccord", "Ruinaccord") }
    var hero: String { pick("Adventurer", "冒险者", "冒険者") }
    var heroInit: String { pick("A", "冒", "冒") }
    func duelOf(_ n: Int, _ t: Int) -> String { pick("Duel \(n) of \(t)", "第\(n)场，共\(t)场", "決闘 \(n) / \(t)") }
    func stageOf(_ n: Int, _ t: Int) -> String { pick("\(n)/\(t)", "第\(n)/\(t)关", "\(n)/\(t)") }
    func mana(_ a: Int, _ b: Int) -> String { pick("Mana \(a) of \(b)", "法力值 \(a)/\(b)", "マナ \(a)/\(b)") }
    func handDeck(_ h: Int, _ d: Int) -> String { pick("Hand \(h) · Deck \(d)", "手牌 \(h) · 牌库 \(d)", "手札 \(h) · 山札 \(d)") }
    var noEnemy: String { pick("No enemy minions", "敌方没有随从", "敵のミニオンはいない") }
    var playMinions: String { pick("Play minions from your hand", "从手牌中打出随从", "手札からミニオンを出そう") }
    func chooseTarget(_ x: String) -> String { pick("Choose a target for \(x).", "为「\(x)」选择目标。", "「\(x)」の対象を選んでください。") }
    var cancel: String { pick("Cancel", "取消", "キャンセル") }
    var yourTurn: String { pick("Your turn", "你的回合", "あなたのターン") }
    func acting(_ x: String) -> String { pick("\(x) is acting…", "\(x)行动中…", "\(x)が行動中…") }
    var endTurn: String { pick("End turn", "结束回合", "ターン終了") }
    var minion: String { pick("Minion", "随从", "ミニオン") }
    var spell: String { pick("Spell", "法术", "呪文") }
    var guardKw: String { pick("Guard", "守护", "ガード") }
    var wardKw: String { pick("Ward", "护盾", "結界") }
    var gaspKw: String { pick("Last breath", "遗言", "断末魔") }
    var introTitle: String { pick("Fight your way to the Ashen Crown", "一路征战，夺取灰烬王冠", "戦い抜いて、灰燼の王冠を手にせよ") }
    var rules: [String] {
        switch lang {
        case .en: return ["You gain one more **mana** each turn, up to 10. Spend it on minions and spells.",
                          "A **Mage** keeps unspent mana as up to 3 **spell mana**, which only spells can use. Other classes lose it.",
                          "Each class banks its own resource: a **Warrior** gains **Rage** from the hero power and hero damage (4 burst into +2 Attack for the board); a **Warlock** gains **Souls** from friendly deaths (Blood Pact spends 2 instead of hurting, 5 become a Bone Warrior); a **Priest** turns healing past full into **Light** (2 Light take a turn off a Prayer); a **Hunter** gains **Ferocity** each turn for the Beasts in hand (the hero power spends 2 for +1 damage, a Beast played with 3 Charges); a **Paladin** swears **Oaths**, which wait on the altar like Prayers.",
                          "Tap a glowing minion, then tap an enemy to **attack**. New minions wait a turn unless they have **Charge**.",
                          "Enemies must hit **Guard** minions first. **Ward** blocks the next damage taken.",
                          "Choose one of six **classes**. Each has its own **hero power**, usable once per turn, and its own starting deck.",
                          "Defeat eight foes, from a goblin warband to the Ashen King. After each win you also add a card to your deck."]
        case .zh: return ["每回合你的**法力值**上限加1，最多10点。用它打出随从和法术。",
                          "**法师**没用完的法力会存为最多3点**法术法力**，只能用来施放法术；其他职业不会积累。",
                          "每个职业都有自己的资源：**战士**使用技能和英雄受伤获得**怒气**（攒到4点，回合开始爆发：全体随从本回合+2攻击）；**术士**友方随从死亡获得**魂**（鲜血契约可用2魂代替自伤，回合结束时5魂召唤骷髅战士）；**牧师**溢出的治疗化为**圣光**（祷文上祭坛时每2光倒计时-1）；**猎人**每回合开始按手牌中的野兽数获得**兽性**（穿刺之箭每2点多1伤害，有3点时打出的野兽获得冲锋）；**圣骑士**的**誓言**和祷文一样放上祭坛，几回合后应验。",
                          "点击带绿框的随从，再点击敌人即可**攻击**。新随从要等一回合才能攻击，除非它有**冲锋**。",
                          "敌人必须先攻击有**守护**的随从。**护盾**可以抵挡下一次伤害。",
                          "从六个**职业**中选择一个。每个职业都有专属的**英雄技能**（每回合可用一次）和初始牌组。",
                          "击败八名敌人，从哥布林战团一路打到灰烬之王。每赢一场，你还可以向牌组加入一张牌。"]
        case .ja: return ["毎ターン**マナ**の上限が1増える（最大10）。ミニオンと呪文に使おう。",
                          "**魔法使い**は使い切らなかったマナを最大3まで**呪文マナ**として貯め、呪文にだけ使える。他のクラスは貯まらない。",
                          "クラスごとに固有の資源がある。**戦士**はヒーローパワー使用と被ダメージで**怒気**（4で解放、味方全体がこのターン攻撃+2）。**ウォーロック**は味方の死亡で**魂**（血の契約は魂2で自傷を肩代わり、ターン終了時に5で骸骨戦士）。**司祭**は余った回復が**聖光**になる（祈りを祭壇に置くとき聖光2で待ち時間-1）。**狩人**は手札の獣の数だけ毎ターン**野性**を得る（ヒーローパワーは2で+1ダメージ、3あれば出した獣が突撃）。**聖騎士**の**誓い**は祈りと同じく祭壇で待ち、数ターン後に成就する。",
                          "光っているミニオンをタップし、敵をタップして**攻撃**。出したばかりのミニオンは**突撃**がない限り次のターンまで攻撃できない。",
                          "敵は先に**ガード**を持つミニオンを攻撃しなければならない。**結界**は次に受けるダメージを1回防ぐ。",
                          "6つの**クラス**から1つを選ぼう。クラスごとに専用の**ヒーローパワー**（1ターンに1回）と初期デッキがある。",
                          "ゴブリンの戦団から灰燼の王まで、8人の敵を倒そう。勝つたびにカードを1枚デッキに加えられる。"]
        }
    }
    var startDuel: String { pick("Begin the quest", "踏上征程", "冒険に出る") }
    var viewCards: String { pick("Card gallery", "卡牌图鉴", "カード図鑑") }
    var cardsBtn: String { pick("Cards", "图鉴", "図鑑") }
    func defeated(_ x: String) -> String { pick("\(x) is defeated", "\(x)已被击败", "\(x)を倒した") }
    func rewardText(_ n: Int, _ x: String) -> String { pick("Choose a card to add to your deck (\(n) cards now). Next foe: \(x).", "选择一张牌加入你的牌组（当前\(n)张）。下一个敌人：\(x)。", "デッキに加えるカードを1枚選んでください（現在\(n)枚）。次の敵：\(x)。") }
    var skip: String { pick("Skip", "跳过", "スキップ") }
    var lostTitle: String { pick("The adventurer falls", "冒险者倒下了", "冒険者は倒れた") }
    func lostText(_ x: String) -> String { pick("\(x) won this duel. Your deck and class are kept if you retry.", "\(x)赢下了这场决斗。重试时会保留你的牌组和职业。", "\(x)がこの決闘に勝った。再挑戦してもデッキとクラスはそのまま残る。") }
    var retry: String { pick("Retry duel", "重试本场", "再挑戦") }
    var newRun: String { pick("New quest", "重新开始", "最初から") }
    var champTitle: String { pick("The Ashen Crown is yours", "灰烬王冠归你所有", "灰燼の王冠はあなたのもの") }
    func champText(_ n: Int) -> String { pick("You defeated all eight foes with a \(n)-card deck.", "你用\(n)张牌的牌组击败了全部八名敌人。", "\(n)枚のデッキで8人の敵をすべて倒した。") }
    var again: String { pick("Play again", "再玩一次", "もう一度遊ぶ") }
    var galTitle: String { pick("Card gallery", "卡牌图鉴", "カード図鑑") }
    func galSub(_ n: Int) -> String { pick("All \(n) cards in the realm.", "这个世界中的全部\(n)张卡牌。", "この世界の全\(n)枚のカード。") }
    var back: String { pick("Back", "返回", "戻る") }
    var minions: String { pick("Minions", "随从", "ミニオン") }
    var spells: String { pick("Spells", "法术", "呪文") }
    /// Short rarity names for the builder's filter row.
    func rarityShort(_ r: String) -> String { r == "l" ? pick("Legend", "传说", "伝説") : r == "e" ? pick("Epic", "史诗", "エピック") : rarity(r) }
    func rarity(_ r: String) -> String {
        switch r {
        case "c": return pick("Common", "普通", "コモン")
        case "r": return pick("Rare", "稀有", "レア")
        case "e": return pick("Epic", "史诗", "エピック")
        case "l": return pick("Legendary", "传说", "レジェンド")
        default: return pick("Token", "衍生", "トークン")
        }
    }
    func costN(_ n: Int) -> String { pick("\(n) mana", "\(n)费", "コスト\(n)") }
    func race(_ r: String) -> String {
        let table: [String: (String, String, String)] = [
            "human": ("Human", "人类", "人間"), "elf": ("Elf", "精灵", "エルフ"), "dwarf": ("Dwarf", "矮人", "ドワーフ"), "orc": ("Orc", "兽人", "オーク"),
            "halfling": ("Halfling", "半身人", "ハーフリング"), "gnome": ("Gnome", "侏儒", "ノーム"), "undead": ("Undead", "亡灵", "アンデッド"),
            "goblin": ("Goblin", "哥布林", "ゴブリン"), "troll": ("Troll", "巨魔", "トロール"), "beast": ("Beast", "野兽", "獣"), "giant": ("Giant", "巨人", "巨人"),
            "construct": ("Construct", "构造体", "構造体"), "elemental": ("Elemental", "元素", "精霊"), "dragon": ("Dragon", "龙", "ドラゴン"), "treant": ("Treant", "树人", "樹人"),
        ]
        guard let t = table[r] else { return r }
        return pick(t.0, t.1, t.2)
    }
    var bannerYou: String { pick("Your turn", "你的回合", "あなたのターン") }
    var bannerFoe: String { pick("Enemy turn", "敌方回合", "敵のターン") }
    func rises(_ x: String) -> String { pick("\(x) stands in your way.", "\(x)挡住了你的去路。", "\(x)が立ちはだかる。") }
    func fatigue(_ x: String, _ n: Int) -> String { pick("\(x) is out of cards and takes \(n) fatigue damage.", "\(x)的牌库已空，受到\(n)点疲劳伤害。", "\(x)の山札が尽き、\(n)の疲労ダメージを受けた。") }
    func handFull(_ c: String) -> String { pick("Your hand is full. \(c) was lost.", "你的手牌已满，\(c)被烧掉了。", "手札がいっぱいで、\(c)は失われた。") }
    func summon(_ c: String) -> String { pick("You summon \(c).", "你召唤了\(c)。", "\(c)を召喚した。") }
    func cast(_ c: String) -> String { pick("You cast \(c).", "你施放了\(c)。", "\(c)を唱えた。") }
    func castOn(_ c: String, _ t: String) -> String { pick("You cast \(c) on \(t).", "你对\(t)施放了\(c)。", "\(t)に\(c)を唱えた。") }
    func attacks(_ a: String, _ t: String) -> String { pick("\(a) attacks \(t).", "\(a)攻击了\(t)。", "\(a)が\(t)を攻撃。") }
    func burst(_ c: String) -> String { pick("The spirit of \(c) rises.", "\(c)的怨灵升起了。", "\(c)の怨霊が立ち上がった。") }
    func sinks(_ x: String) -> String { pick("\(x) is defeated.", "\(x)被击败了。", "\(x)を倒した。") }
    var falls: String { pick("The adventurer falls.", "冒险者倒下了。", "冒険者は倒れた。") }
    var noMana: String { pick("Not enough mana.", "法力值不足。", "マナが足りない。") }
    var boardFull: String { pick("Your board is full.", "你的场地已满。", "盤面がいっぱいだ。") }
    var noTargets: String { pick("No valid targets for that card.", "这张牌没有可用的目标。", "このカードの対象がいない。") }
    func ready(_ x: String) -> String { pick("\(x) is ready. Tap what to attack.", "\(x)已就绪，点击要攻击的目标。", "\(x)は準備完了。攻撃する対象をタップ。") }
    func already(_ x: String) -> String { pick("\(x) already attacked this turn.", "\(x)本回合已经攻击过了。", "\(x)はこのターン既に攻撃した。") }
    func noAtk(_ x: String) -> String { pick("\(x) has no Attack.", "\(x)没有攻击力。", "\(x)には攻撃力がない。") }
    func nextTurn(_ x: String) -> String { pick("\(x) can attack next turn.", "\(x)下回合才能攻击。", "\(x)は次のターンから攻撃できる。") }
    var guardWay: String { pick("A Guard minion is in the way.", "有守护随从挡在前面。", "ガードを持つミニオンが立ちふさがっている。") }
    func info(_ n: String, _ a: Int, _ h: Int, _ t: String) -> String { pick("\(n): \(a)/\(h)\(t.isEmpty ? "" : " · " + t)", "\(n)：\(a)/\(h)\(t.isEmpty ? "" : " · " + t)", "\(n)：\(a)/\(h)\(t.isEmpty ? "" : " · " + t)") }
    func eTurn(_ x: String) -> String { pick("\(x)'s turn.", "\(x)的回合。", "\(x)のターン。") }
    func eSummon(_ x: String, _ c: String) -> String { pick("\(x) summons \(c).", "\(x)召唤了\(c)。", "\(x)が\(c)を召喚した。") }
    func eCast(_ x: String, _ c: String) -> String { pick("\(x) casts \(c).", "\(x)施放了\(c)。", "\(x)が\(c)を唱えた。") }
    func eCastOn(_ x: String, _ c: String, _ t: String) -> String { pick("\(x) casts \(c) on \(t).", "\(x)对\(t)施放了\(c)。", "\(x)が\(t)に\(c)を唱えた。") }
    var yourTurnLog: String { pick("Your turn.", "轮到你了。", "あなたのターン。") }
    var classTitle: String { pick("Choose your class", "选择你的职业", "クラスを選択") }
    func classSub(_ x: String) -> String { pick("Each class has its own hero power and starting deck. Your first foe: \(x).", "每个职业都有专属的英雄技能和初始牌组。第一个敌人：\(x)。", "クラスごとに専用のヒーローパワーと初期デッキがある。最初の敵：\(x)。") }
    var heroPower: String { pick("Hero power", "英雄技能", "ヒーローパワー") }
    func powerUse(_ n: String, _ t: String?) -> String {
        if let t { return pick("You use \(n) on \(t).", "你对\(t)使用了\(n)。", "\(t)に\(n)を使った。") }
        return pick("You use \(n).", "你使用了\(n)。", "\(n)を使った。")
    }
    var cantPower: String { pick("You can't use your hero power right now.", "现在无法使用英雄技能。", "今はヒーローパワーを使えない。") }
    var modeCamp: String { pick("Adventure", "冒险模式", "冒険モード") }
    var modeCampSub: String { pick("Defeat eight foes in a row with a class starter deck.", "用职业初始牌组，连续击败八名敌人。", "クラスの初期デッキで、8人の敵に連続で挑む。") }
    var modeQuick: String { pick("Quick Match", "自由对战", "フリー対戦") }
    var modeQuickSub: String { pick("Build your own deck and face a random AI opponent.", "自己组一副牌，随机对战一名AI对手。", "自分でデッキを組み、ランダムなAIと対戦する。") }
    func qClassSub(_ n: Int) -> String { pick("Next you will build a \(n)-card deck for this class.", "接下来为这个职业组一副\(n)张的牌组。", "次にこのクラスで\(n)枚のデッキを組む。") }
    func deckTitle(_ x: String) -> String { pick("\(x) deck", "\(x)的牌组", "\(x)のデッキ") }
    func deckRules(_ n: Int) -> String { pick("\(n) cards. Up to 2 copies of a card, 1 of a legendary or a marked epic.", "\(n)张牌。同名卡最多2张，传说卡和特殊史诗卡最多1张。", "\(n)枚。同名カードは2枚まで、レジェンドと特別なエピックは1枚まで。") }
    func deckNeed(_ n: Int) -> String { pick("\(n) more to add", "还差\(n)张", "あと\(n)枚") }
    var deckReady: String { pick("Deck ready", "牌组已完成", "デッキ完成") }
    var autoFill: String { pick("Auto-fill", "自动补满", "自動で埋める") }
    var resetDeck: String { pick("Starter deck", "恢复初始牌组", "初期デッキに戻す") }
    var clearDeck: String { pick("Clear", "清空", "空にする") }
    var nextDiff: String { pick("Next: difficulty", "下一步：选择难度", "次へ：難易度") }
    var curve: String { pick("Mana curve", "法力曲线", "マナカーブ") }
    var filterAll: String { pick("All", "全部", "すべて") }
    var tapAdd: String { pick("Tap a card to add it. Tap a row in your deck to remove one copy.", "点击卡牌加入牌组，点击牌组中的一行移除一张。", "カードをタップで追加、デッキの行をタップで1枚外す。") }
    var limitHit: String { pick("You already have the most copies allowed of that card.", "这张牌已经达到数量上限。", "このカードは枚数上限に達している。") }
    var deckFull: String { pick("Your deck is full.", "牌组已满。", "デッキがいっぱい。") }
    var emptyDeck: String { pick("Your deck is empty. Tap cards to add them.", "牌组是空的，点击卡牌加入。", "デッキは空。カードをタップして追加しよう。") }
    var diffTitle: String { pick("Choose difficulty", "选择难度", "難易度を選択") }
    var diffSub: String { pick("Your opponent's class is chosen at random.", "对手的职业会随机决定。", "相手のクラスはランダムに決まる。") }
    func diff(_ d: Difficulty) -> String {
        switch d {
        case .easy: return pick("Easy", "简单", "かんたん")
        case .normal: return pick("Normal", "普通", "ふつう")
        case .hard: return pick("Hard", "困难", "むずかしい")
        }
    }
    func diffDesc(_ d: Difficulty) -> String {
        switch d {
        case .easy: return pick("The AI makes mistakes and never uses its hero power. Its deck adds common cards.", "AI会出错，也不使用英雄技能。牌组补充普通卡。", "AIはミスをし、ヒーローパワーを使わない。デッキはコモンで補充。")
        case .normal: return pick("Standard AI that uses its class hero power. Its deck adds rare and epic cards.", "标准AI，会使用职业英雄技能。牌组补充稀有卡和史诗卡。", "クラスのヒーローパワーを使う標準AI。デッキはレアとエピックで補充。")
        case .hard: return pick("Standard AI whose deck adds epic and legendary cards.", "标准AI，牌组补充史诗卡和传说卡。", "標準AI。デッキはエピックとレジェンドで補充。")
        }
    }
    func aiName(_ x: String) -> String { pick("\(x) (AI)", "\(x)（AI）", "\(x)（AI）") }
    var goFirst: String { pick("You go first.", "你先手。", "あなたが先攻。") }
    var goSecond: String { pick("You go second and get a Lucky Coin.", "你后手，获得一枚幸运硬币。", "あなたは後攻。幸運のコインを得る。") }
    var qWin: String { pick("Victory", "胜利", "勝利") }
    var qLose: String { pick("Defeat", "失败", "敗北") }
    func qVs(_ c: String, _ d: String) -> String { pick("Opponent: \(c) · \(d)", "对手：\(c) · \(d)", "相手：\(c) · \(d)") }
    var modeOnline: String { pick("Play Online", "在线对战", "オンライン対戦") }
    var modeOnlineSub: String { pick("Find a random opponent, or share a room code and battle a friend.", "随机匹配对手，或分享房间码与好友对战。", "ランダムな相手と対戦、またはルームコードでフレンドと対戦。") }
    var onSub: String { pick("Pick one of your decks. Find a random opponent, or create a room and send your friend the code.", "先选一副你的牌组。可以随机匹配对手，也可以创建房间并把房间码发给好友。", "自分のデッキを選び、ランダムマッチか、ルームを作ってフレンドにコードを送ろう。") }
    var onDeck: String { pick("Your deck", "你的牌组", "あなたのデッキ") }
    var findMatch: String { pick("Find opponent", "随机匹配", "対戦相手を探す") }
    var searching: String { pick("Looking for an opponent…", "正在寻找对手…", "対戦相手を探しています…") }
    func searchingFor(_ s: Int) -> String { pick("Looking for an opponent… \(s)s", "正在寻找对手… \(s)秒", "対戦相手を探しています… \(s)秒") }
    var foundMatch: String { pick("Opponent found!", "找到对手！", "対戦相手が見つかった！") }
    var createRoom: String { pick("Create room", "创建房间", "ルームを作成") }
    var joinRoom: String { pick("Join", "加入", "参加") }
    var codePh: String { pick("6-digit code", "6位房间码", "6桁のコード") }
    var orJoin: String { pick("or join a friend's room", "或加入好友的房间", "またはフレンドのルームに参加") }
    var roomCode: String { pick("Room code", "房间码", "ルームコード") }
    var waitFriend: String { pick("Waiting for your friend to join…", "等待好友加入…", "フレンドの参加を待っています…") }
    var shareInvite: String { pick("Share room code", "分享房间码", "ルームコードを共有") }
    var copied: String { pick("Room code copied.", "房间码已复制。", "ルームコードをコピーしました。") }
    func inviteText(_ c: String) -> String { pick("Join my Ruinaccord duel! Room code \(c)", "来 Ruinaccord 和我对战！房间码 \(c)", "Ruinaccordで対戦しよう！ルームコード \(c)") }
    func connecting(_ c: String) -> String { pick("Connecting to room \(c)…", "正在连接房间 \(c)…", "ルーム \(c) に接続中…") }
    var loadingNet: String { pick("Connecting to the match server…", "正在连接对战服务器…", "対戦サーバーに接続中…") }
    var errServer: String { pick("Could not reach the match server. Check your connection and try again.", "无法连接对战服务器，请检查网络后重试。", "対戦サーバーに接続できません。通信状況を確認して再試行してください。") }
    var errNoRoom: String { pick("No room with that code. Check the code with your friend.", "找不到这个房间，请和好友核对房间码。", "そのコードのルームが見つかりません。コードを確認してください。") }
    var errTimeout: String { pick("Connection timed out. Check your connection and try again.", "连接超时，请检查网络后再试。", "接続がタイムアウトしました。通信状況を確認して再試行してください。") }
    var errVersion: String { pick("You and your friend are on different versions. Both update the app and try again.", "你和好友的游戏版本不同，请双方更新 app 后再试。", "フレンドとバージョンが異なります。両方ともアプリを更新してください。") }
    var errDeck: String { pick("That deck can't be used online.", "这副牌组不能用于在线对战。", "このデッキはオンライン対戦で使えません。") }
    var errCode: String { pick("Enter the 6-digit room code.", "请输入6位房间码。", "6桁のルームコードを入力してください。") }
    var errSignIn: String { pick("Sign in with Apple to play online.", "请先使用 Apple 登录，才能在线对战。", "オンライン対戦にはAppleでサインインしてください。") }
    var errNoBackend: String { pick("Online play needs the Firebase configuration. See ios/README.md.", "在线对战需要 Firebase 配置，请参阅 ios/README.md。", "オンライン対戦にはFirebaseの設定が必要です。ios/README.mdを参照してください。") }
    func foeName(_ c: String) -> String { pick("Opponent (\(c))", "对手（\(c)）", "相手（\(c)）") }
    var onlinePill: String { pick("Online", "在线", "オンライン") }
    var concede: String { pick("Concede", "认输", "降参") }
    var concedeSure: String { pick("Tap again to concede", "再点一次认输", "もう一度押して降参") }
    var netSlow: String { pick("Waiting for your opponent's connection…", "对手网络不稳定，等待中…", "相手の接続を待っています…") }
    var oDraw: String { pick("Draw", "平局", "引き分け") }
    func oVs(_ c: String) -> String { pick("Opponent: \(c)", "对手：\(c)", "相手：\(c)") }
    var oLeft: String { pick("Your opponent left the match.", "对手已离开对局。", "相手が対戦を離れました。") }
    var oConceded: String { pick("Your opponent conceded.", "对手认输了。", "相手が降参しました。") }
    var waitAgain: String { pick("Waiting for your opponent…", "等待对手确认…", "相手を待っています…") }
    var foeAgain: String { pick("Your opponent wants a rematch!", "对手想再来一局！", "相手が再戦を希望しています！") }
    var leaveRoom: String { pick("Leave", "离开", "退出") }
    var onNoDecks: String { pick("Online matches use your own 25-card decks. You don't have a complete one yet, so build one here first.", "在线对战只能使用你自己组的25张牌组。你还没有完整的牌组，先在这里组一副吧。", "オンライン対戦では自分で組んだ25枚のデッキを使います。まだ完成したデッキがないので、ここで組みましょう。") }
    var useDeck: String { pick("Save & use online", "保存并用于在线对战", "保存してオンラインで使う") }
    var oAgain: String { pick("Rematch", "再来一局", "もう一戦") }
    func record(_ w: Int, _ l: Int) -> String { pick("Record: \(w) won, \(l) lost", "战绩：\(w)胜 \(l)负", "戦績：\(w)勝 \(l)敗") }
    var rematch: String { pick("New opponent", "再来一局", "もう一戦") }
    var editDeck: String { pick("Edit deck", "修改牌组", "デッキを編集") }
    var toMenu: String { pick("Main menu", "主菜单", "メインメニュー") }
    var myDecks: String { pick("My decks", "我的牌组", "マイデッキ") }
    var myDecksSub: String { pick("Your decks are saved to your account and follow you to any device.", "牌组保存在你的账号里，换设备也能用。", "デッキはアカウントに保存され、どの端末でも使えます。") }
    var newDeck: String { pick("New deck", "新建牌组", "新しいデッキ") }
    var noDecks: String { pick("No saved decks yet. Tap New deck, build one, and save it.", "还没有保存的牌组。点「新建牌组」，组好后保存。", "保存したデッキはまだない。「新しいデッキ」で組んで保存しよう。") }
    var playDeck: String { pick("Play", "开始对战", "対戦する") }
    var editShort: String { pick("Edit", "编辑", "編集") }
    var deleteDeck: String { pick("Delete", "删除", "削除") }
    var confirmDelete: String { pick("Tap again to delete", "再点一次删除", "もう一度タップで削除") }
    var deckName: String { pick("Deck name", "牌组名称", "デッキ名") }
    var saveDeck: String { pick("Save deck", "保存牌组", "デッキを保存") }
    var savedState: String { pick("Saved", "已保存", "保存済み") }
    var saveAsNew: String { pick("Save as new", "另存为新牌组", "新規保存") }
    func saved(_ x: String) -> String { pick("Saved \"\(x)\".", "已保存「\(x)」。", "「\(x)」を保存した。") }
    func deleted(_ x: String) -> String { pick("Deleted \"\(x)\".", "已删除「\(x)」。", "「\(x)」を削除した。") }
    func defaultName(_ c: String, _ n: Int) -> String { pick("\(c) deck \(n)", "\(c)牌组 \(n)", "\(c)デッキ \(n)") }
    func cardsN(_ n: Int) -> String { pick("\(n) cards", "\(n)张", "\(n)枚") }
    func notReady(_ n: Int) -> String { pick("\(n)/25 · not ready to play", "\(n)/25 · 未完成，暂不能对战", "\(n)/25 · 未完成のため対戦不可") }
    var unsaved: String { pick("Unsaved changes", "有未保存的修改", "未保存の変更あり") }
    var pickClassNew: String { pick("New deck · Choose a class", "新建牌组 · 选择职业", "新しいデッキ · クラスを選択") }
    var copySuffix: String { pick(" (copy)", "（副本）", "（コピー）") }
    func ePower(_ x: String, _ p: String, _ t: String?) -> String {
        if let t { return pick("\(x) uses \(p) on \(t).", "\(x)对\(t)使用了\(p)。", "\(x)が\(t)に\(p)を使った。") }
        return pick("\(x) uses \(p).", "\(x)使用了\(p)。", "\(x)が\(p)を使った。")
    }
    var lpHint: String { pick("Long-press any card to see it full size.", "长按任意卡牌可以放大查看。", "カードを長押しすると拡大表示できる。") }
    func played(_ x: String) -> String { pick("\(x) played", "\(x)打出", "\(x)がプレイ") }
    func target(_ t: String) -> String { pick("Target: \(t)", "目标：\(t)", "対象：\(t)") }
    var history: String { pick("Recent plays", "最近出牌", "最近のプレイ") }
    var battleLog: String { pick("Battle log", "战场记录", "戦場記録") }
    var logEmpty: String { pick("Nothing has been played yet.", "还没有打出任何牌。", "まだ何もプレイされていません。") }
    func turnRound(_ you: Bool, _ n: Int) -> String { you ? pick("YOUR TURN (\(n))", "你的回合（\(n)）", "あなたのターン（\(n)）") : pick("ENEMY TURN (\(n))", "敌方回合（\(n)）", "敵のターン（\(n)）") }
    var manaShort: String { pick("Mana", "法力", "マナ") }
    var armor: String { pick("Armor", "护甲", "装甲") }
    var spellManaShort: String { pick("Spell", "法术", "呪文") }
    var tapClose: String { pick("Tap anywhere to close", "点击任意位置关闭", "タップで閉じる") }
    var fWard: String { pick("Ward", "护盾", "結界") }
    var fFreeze: String { pick("Frozen", "冻结", "凍結") }
    var mullTitle: String { pick("Starting hand", "起手牌", "初期手札") }
    func chooseTitle(_ n: Int) -> String { pick("Pick \(n) to return to your hand", "选\(n)张放回手牌", "\(n)枚選んで手札に戻す") }
    var chooseSub: String { pick("They died this game. The rest stay in the grave.", "这些是本局死亡的随从，没选的留在墓地。", "このゲームで倒されたミニオン。選ばなかったものは墓地に残る。") }
    var chooseOk: String { pick("Take", "拿回", "戻す") }
    var mullSub: String { pick("Tap the cards you want to replace. New cards are drawn, and the replaced ones go to the bottom of your deck.", "点选想替换的牌。会先补抽新牌，换掉的牌放回牌库底部。", "交換したいカードをタップ。新しいカードを引き、交換したカードはデッキの一番下に戻る。") }
    var mullKeep: String { pick("Keep this hand", "保留手牌", "このまま") }
    func mullSwap(_ n: Int) -> String { pick("Replace \(n) card\(n > 1 ? "s" : "")", "替换\(n)张", "\(n)枚交換") }
    var mullWait: String { pick("Waiting for your opponent…", "等待对手选择…", "相手を待っています…") }
    var quitSure: String { pick("Tap again to leave", "再点一次退出", "もう一度押して終了") }
    var quitAria: String { pick("Leave to the main menu", "退出到主菜单", "メインメニューに戻る") }
    var dragPlay: String { pick("Drag the card onto the board to play it.", "把牌拖到场上即可打出。", "カードを盤面へドラッグして使用。") }
    var dragTarget: String { pick("Drag the card onto a target.", "把牌拖到目标上施放。", "カードを対象へドラッグ。") }
    var foeTurn: String { pick("Opponent's turn", "对方的回合", "相手のターン") }
    var healthShort: String { pick("Health", "生命", "体力") }
    var tapPreview: String { pick("Tap a card in your hand to see it.", "点一张手牌查看。", "手札のカードをタップして確認。") }
    var fSilence: String { pick("Silenced", "沉默", "沈黙") }
    var fDestroy: String { pick("Destroyed", "消灭", "破壊") }
    func spKw(_ n: Int) -> String { pick("Spell +\(n)", "法伤+\(n)", "呪文+\(n)") }
    func spellMana(_ n: Int) -> String { pick("\(n) spell mana", "法术法力 \(n)", "呪文マナ \(n)") }
    func fArmor(_ n: Int) -> String { pick("-\(n) armor", "-\(n)护甲", "装甲-\(n)") }
    func armorN(_ n: Int) -> String { pick("+\(n) armor", "+\(n)护甲", "装甲+\(n)") }
    func fAtk(_ n: Int) -> String { pick("+\(n) Atk", "+\(n)攻击", "攻撃+\(n)") }
    func fHp(_ n: Int) -> String { pick("+\(n) HP", "+\(n)生命", "体力+\(n)") }

    // Account & settings
    var settings: String { pick("Settings", "设置", "設定") }
    var language: String { pick("Language", "语言", "言語") }
    var account: String { pick("Account", "账号", "アカウント") }
    var signInApple: String { pick("Sign in with Apple", "通过 Apple 登录", "Appleでサインイン") }
    var continueGuest: String { pick("Continue as guest", "以游客身份继续", "ゲストとして続ける") }
    var guestNote: String { pick("Guest decks are saved to this device's account. Sign in with Apple any time to keep them across devices and play online.", "游客的牌组保存在本设备的账号里。随时可以通过 Apple 登录，在多台设备间同步并在线对战。", "ゲストのデッキはこの端末のアカウントに保存されます。いつでもAppleでサインインすれば、端末間で同期しオンライン対戦ができます。") }
    var welcome: String { pick("Sign in to save your decks and duel online.", "登录后可保存牌组并在线对战。", "サインインしてデッキを保存し、オンラインで対戦しよう。") }
    var signedInAs: String { pick("Signed in with Apple", "已通过 Apple 登录", "Appleでサインイン済み") }
    var guest: String { pick("Guest", "游客", "ゲスト") }
    var signOut: String { pick("Sign out", "退出登录", "サインアウト") }
    var deleteAccount: String { pick("Delete account", "删除账号", "アカウントを削除") }
    var deleteAccountSure: String { pick("Delete your account and all saved decks? This cannot be undone.", "删除账号和所有保存的牌组？此操作无法撤销。", "アカウントと保存したデッキをすべて削除しますか？元に戻せません。") }
    var delete: String { pick("Delete", "删除", "削除") }
    var privacy: String { pick("Privacy policy", "隐私政策", "プライバシーポリシー") }
    var offlineMode: String { pick("Offline mode: no Firebase configuration found, decks are saved on this device only.", "离线模式：未找到 Firebase 配置，牌组仅保存在本设备。", "オフラインモード：Firebaseの設定が見つからないため、デッキはこの端末のみに保存されます。") }
    func stats(_ w: Int, _ l: Int) -> String { pick("Online record: \(w) won · \(l) lost", "在线战绩：\(w)胜 · \(l)负", "オンライン戦績：\(w)勝 · \(l)敗") }
    var signInFailed: String { pick("Sign-in failed. Please try again.", "登录失败，请重试。", "サインインに失敗しました。再試行してください。") }
    var reauthNeeded: String { pick("Please sign in again before deleting your account.", "删除账号前请重新登录。", "アカウントを削除する前にもう一度サインインしてください。") }

    // Effect text (rules text is generated from effect data in every language)
    func fxText(_ fx: Effect, _ tgt: Target?) -> String {
        var out: [String] = []
        if fx.selfDmg > 0 { out.append(pick("Take \(fx.selfDmg) damage.", "受到\(fx.selfDmg)点伤害。", "\(fx.selfDmg)ダメージを受ける。")) }
        if fx.dmg > 0 {
            out.append(tgt == .minion ? pick("Deal \(fx.dmg) damage to a minion.", "对一个随从造成\(fx.dmg)点伤害。", "ミニオン1体に\(fx.dmg)ダメージを与える。")
                       : pick("Deal \(fx.dmg) damage.", "造成\(fx.dmg)点伤害。", "\(fx.dmg)ダメージを与える。"))
        }
        if fx.aoe > 0 {
            out.append(fx.face > 0 ? pick("Deal \(fx.aoe) damage to all enemies.", "对所有敌人造成\(fx.aoe)点伤害。", "敵全体に\(fx.aoe)ダメージを与える。")
                       : pick("Deal \(fx.aoe) damage to all enemy minions.", "对所有敌方随从造成\(fx.aoe)点伤害。", "敵のミニオン全てに\(fx.aoe)ダメージを与える。"))
        } else if fx.face > 0 {
            out.append(pick("Deal \(fx.face) damage to the enemy hero.", "对敌方英雄造成\(fx.face)点伤害。", "敵のヒーローに\(fx.face)ダメージを与える。"))
        }
        if fx.healT > 0 { out.append(pick("Restore \(fx.healT) Health to a friendly character.", "为一个友方角色恢复\(fx.healT)点生命值。", "味方のキャラクター1体の体力を\(fx.healT)回復する。")) }
        if let b = fx.buff {
            let s = stat(b[0], b[1])
            out.append(pick("Give a friendly minion \(s)\(fx.grantGuard ? " and Guard" : "")\(fx.ward ? " and Ward" : "").",
                            "使一个友方随从获得\(s)\(fx.grantGuard ? "和守护" : "")\(fx.ward ? "和护盾" : "")。",
                            "味方のミニオン1体に\(s)\(fx.grantGuard ? "とガード" : "")\(fx.ward ? "と結界" : "")を付与する。"))
        }
        if let t = fx.team { let s = stat(t[0], t[1]); out.append(pick("Give your minions \(s).", "使你的所有随从获得\(s)。", "味方のミニオン全てに\(s)を付与する。")) }
        if let first = fx.summon.first, let c = GameData.shared.card(first) { out.append(summonText(fx.summon.count, c.atk ?? 0, c.hp ?? 0, name(c.names))) }
        if fx.heal > 0 { out.append(pick("Restore \(fx.heal) Health to your hero.", "为你的英雄恢复\(fx.heal)点生命值。", "自分のヒーローの体力を\(fx.heal)回復する。")) }
        if fx.armor > 0 { out.append(pick("Gain \(fx.armor) Armor.", "获得\(fx.armor)点护甲。", "装甲を\(fx.armor)獲得する。")) }
        if fx.draw > 0 { out.append(fx.draw > 1 ? pick("Draw \(fx.draw) cards.", "抽两张牌。", "カードを\(fx.draw)枚引く。") : pick("Draw a card.", "抽一张牌。", "カードを1枚引く。")) }
        if fx.mana > 0 { out.append(pick("Gain \(fx.mana) mana this turn only.", "仅在本回合获得\(fx.mana)点法力值。", "このターンのみ、マナを\(fx.mana)獲得する。")) }
        if fx.purge > 0 { out.append(pick("Destroy all minions with \(fx.purge) or more Attack.", "消灭所有攻击力不低于\(fx.purge)的随从。", "攻撃力\(fx.purge)以上のミニオンをすべて破壊する。")) }
        if fx.revive > 0 { out.append(pick("Revive your most recently killed minion.", "复活你最近死亡的一个随从。", "最後に倒された味方ミニオンを1体蘇らせる。")) }
        if fx.reclaim > 0 { out.append(pick("Look at 5 random minions that died this game and return \(fx.reclaim) of them to your hand.", "从本局死亡的随从中随机展示五张，选\(fx.reclaim)张放回你的手牌。", "このゲームで倒されたミニオンから無作為に5枚を見て、\(fx.reclaim)枚を手札に戻す。")) }
        if fx.hasten > 0 { out.append(pick("Your Prayers count down \(fx.hasten).", "你的所有祷文倒计时减\(fx.hasten)。", "自分の祈祷のカウントを\(fx.hasten)進める。")) }
        if fx.freeze { out.append(pick("Freeze it.", "并冻结目标。", "対象を凍結させる。")) }
        if fx.tempAtk > 0 { out.append(pick("+\(fx.tempAtk) Attack this turn.", "本回合+\(fx.tempAtk)攻击力。", "このターン攻撃力+\(fx.tempAtk)。")) }
        if fx.rush { out.append(pick("It can attack this turn.", "它本回合可以攻击。", "このターン攻撃できる。")) }
        if fx.pierce { out.append(pick("Ignores Armor.", "无视护甲。", "装甲を無視する。")) }
        if fx.wardSummon { out.append(pick("With Ward.", "带护盾。", "結界付き。")) }
        if fx.splash > 0 { out.append(pick("\(fx.splash) damage to the other enemy minions.", "对其他敌方随从各造成\(fx.splash)点伤害。", "他の敵のミニオンに\(fx.splash)ダメージ。")) }
        return out.joined(separator: lang == .en ? " " : "")
    }
    func kwPray(_ cd: Int) -> String { pick("Prayer \(cd): ", "祷文\(cd)：", "祈祷\(cd)：") }
    var prayerT: String { pick("Prayer", "祷文", "祈祷") }
    /// Rules text of a card as its owner's talents changed it.
    func cardText(_ c: Card, ovr: CardOverride?) -> String {
        guard let ovr else { return cardText(c) }
        if let t = ovr.text { return name(t) }
        if c.text != nil && ovr.fx == nil && ovr.pray == nil && ovr.bc == nil { return cardText(c) }
        var kws: [String] = []
        if c.hasGuard { kws.append(guardKw) }
        if c.ward { kws.append(wardKw) }
        if c.surge { kws.append(kwCharge) }
        let sep = lang == .en ? " " : "", kwSep = lang == .en ? ". " : "。", end = lang == .en ? "." : "。"
        var s = kws.isEmpty ? "" : kws.joined(separator: kwSep) + end
        if let bc = ovr.bc ?? c.bc { s += (s.isEmpty ? "" : sep) + kwOnPlay + fxText(bc, bc.tgt) }
        if let g = c.gasp, let gc = GameData.shared.card(g) { s += (s.isEmpty ? "" : sep) + kwLast + summonText(1, gc.atk ?? 0, gc.hp ?? 0, name(gc.names)) }
        if let pr = ovr.pray ?? c.pray { s += kwPray(pr.cd) + fxText(pr.fx, nil) }
        else if let fx = ovr.fx ?? c.fx { s += fxText(fx, fx.tgt) }
        return s
    }
    // Talents and prayers
    var talents: String { pick("Talents", "天赋", "タレント") }
    var cardsTab: String { pick("Cards", "卡牌", "カード") }
    func talPts(_ n: Int, _ m: Int) -> String { pick("Points \(n)/\(m)", "天赋点 \(n)/\(m)", "ポイント \(n)/\(m)") }
    var talBalanced: String { pick("Balanced", "均衡", "バランス") }
    var talClear: String { pick("Clear", "清空", "リセット") }
    var talNeed: String { pick("Pick a talent in the tier above first", "先在上一层选一个天赋", "上の段で1つ選ぶと開く") }
    func talAdvTitle(_ n: Int) -> String { pick("Talents · Duel \(n)", "第\(n)关 · 分配天赋", "第\(n)戦・タレント") }
    func talAdvSub(_ n: Int) -> String { pick("You have \(n) talent point\(n > 1 ? "s" : ""). You can move them before every duel.", "你现在有\(n)点天赋，每关开始前都可以重新分配。", "タレントポイントは\(n)。毎戦の前に振り直せる。") }
    var talFight: String { pick("To battle", "开始战斗", "戦いへ") }
    var qTalTitle: String { pick("Quick play · Talents", "自由对战 · 分配天赋", "フリー対戦・タレント") }
    var qTalSub: String { pick("4 points, one a tier; the deck remembers them.", "4 点天赋，每层一个，会保存在这副牌组里。", "4 ポイント、各段1つ。デッキに保存される。") }
    var nextCards: String { pick("Next: cards", "下一步：选牌", "次へ：カード") }
    var closeLbl: String { pick("Close", "关闭", "閉じる") }
    // Full-screen pages
    var nextPage: String { pick("Next page", "下一页", "次のページ") }
    var prevPage: String { pick("Previous page", "上一页", "前のページ") }
    func pageOf(_ n: Int, _ m: Int) -> String { pick("Page \(n) / \(m)", "第 \(n) / \(m) 页", "\(n) / \(m) ページ") }
    var rulesBtn: String { pick("Rules", "规则", "ルール") }
    var accountApple: String { pick("Apple account", "Apple 账号", "Appleアカウント") }
    /// "3 won · 1 lost", or just a count when `l` is nil (adventure clears).
    func statsShort(_ w: Int, _ l: Int?) -> String {
        guard let l else { return pick("\(w) crowns won", "夺冠 \(w) 次", "王冠 \(w) 回") }
        return pick("\(w) won · \(l) lost", "\(w) 胜 · \(l) 负", "\(w) 勝 · \(l) 敗")
    }
    var introBlurb: String { pick("Sunlight falls through the ruins and vines climb the pillars. Fight from the goblin warband to the Ashen King and take the crown back.", "阳光照进废墟，藤蔓爬上石柱。从哥布林战团一路打到灰烬之王，把那顶王冠夺回来。", "廃墟に陽が差し、蔦が柱を這う。ゴブリンの戦団から灰燼の王まで戦い抜き、王冠を取り戻せ。") }
    func heroName(_ cls: String) -> String {
        switch cls {
        case "warrior": return pick("Rok Greytusk", "洛克·灰牙", "ロク・グレイタスク")
        case "mage": return pick("Pim Emberfrost", "皮姆·霜烬", "ピム・エンバーフロスト")
        case "paladin": return pick("Aldric Dawnoath", "奥德里克·晨誓", "アルドリック・ドーンオース")
        case "hunter": return pick("Kaelwen Thornstride", "凯尔温·荆径", "ケルウェン・ソーンストライド")
        case "priest": return pick("Margo Candlewick", "玛戈·烛芯", "マーゴ・キャンドルウィック")
        case "warlock": return pick("Morwen Lastcandle", "莫文·残烛", "モーウェン・ラストキャンドル")
        default: return ""
        }
    }
    func heroRace(_ cls: String) -> String {
        let r = ["warrior": "orc", "mage": "gnome", "paladin": "human", "hunter": "elf", "priest": "halfling", "warlock": "undead"][cls] ?? "human"
        return race(r)
    }
    func roundN(_ n: Int) -> String { pick("Round \(n)", "第\(n)回合", "第\(n)ラウンド") }
    var talHint: String { pick("One talent a tier from either page; each pick opens the tier below.", "每层在两页中任选一个，选了才解锁下一层。", "各段でどちらかのページから1つ。選ぶと次の段が開く。") }
    var typeAll: String { pick("All", "全部", "すべて") }
    var costLbl: String { pick("Cost", "费用", "コスト") }
    var classCards: String { pick("Class", "职业", "クラス") }
    var neutralCards: String { pick("Neutral", "中立", "中立") }
    var talYours: String { pick("Your talents", "你的天赋", "自分のタレント") }
    var talFoes: String { pick("Enemy talents", "敌方天赋", "敵のタレント") }
    var rageGo: String { pick("Rage!", "怒气爆发！", "怒気解放！") }
    func rage(_ n: Int) -> String { pick("Rage \(n)/\(DuelState.rageCap)", "怒气 \(n)/\(DuelState.rageCap)", "怒気 \(n)/\(DuelState.rageCap)") }
    func souls(_ n: Int) -> String { pick("Souls \(n)/\(DuelState.soulCap)", "魂 \(n)/\(DuelState.soulCap)", "魂 \(n)/\(DuelState.soulCap)") }
    func light(_ n: Int) -> String { pick("Light \(n)/\(DuelState.lightCap)", "圣光 \(n)/\(DuelState.lightCap)", "聖光 \(n)/\(DuelState.lightCap)") }
    var fSoulPay: String { pick("Souls spent", "魂代血", "魂で支払う") }
    var fEther: String { pick("Ethereal", "虚体", "霊体") }
    func fRite(_ n: Int) -> String { pick("Sacrificed \(n)", "献祭\(n)张", "生贄\(n)枚") }
    func rites(_ n: Int) -> String { pick("Rites \(n)", "血祭 \(n)", "儀式 \(n)") }
    var riteTitle: String { pick("Blood Rite: choose one of three Legendaries", "血祭：三张传说牌选一张", "血の儀式：伝説カード3枚から1枚を選ぶ") }
    func riteSub(_ n: Int) -> String { n > 1 ? pick("Two copies join your hand and cost (0) this game.", "两张复制加入你的手牌，本局打出不消耗法力值。", "コピー2枚が手札に加わり、このゲーム中マナを消費しない。") : pick("A copy joins your hand and costs (0) this game. From your third Rite on, two copies come.", "一张复制加入你的手牌，本局打出不消耗法力值。本局第三次血祭起得到两张。", "コピー1枚が手札に加わり、このゲーム中マナを消費しない。3回目の儀式からは2枚になる。") }
    var riteOk: String { pick("Copy", "复制", "コピー") }
    func fero(_ n: Int) -> String { pick("Ferocity \(n)/\(DuelState.feroCap)", "兽性 \(n)/\(DuelState.feroCap)", "野性 \(n)/\(DuelState.feroCap)") }
    var fFero: String { pick("Ferocity!", "兽性！", "野性！") }
    func unity(_ b: Int, _ n: Int) -> String { b > 0 ? pick("Unity +1", "协作 +1", "連携 +1") : pick("Unity \(n)/12", "协作 \(n)/12", "連携 \(n)/12") }
    var talTeaches: String { pick("Works with:", "配合天赋：", "相性の良いタレント：") }
    func talTakePack(_ n: String) -> String { pick("Take the \(n) pack", "选择\(n)牌包", "\(n)パックを取る") }
    func packText(_ n: Int, _ o: String) -> String { pick("Choose a pack for your deck (\(n) cards). Next: \(o).", "选一个牌包加入牌组（现在\(n)张）。下一关：\(o)。", "デッキに加えるパックを選ぶ（現在\(n)枚）。次：\(o)。") }
    var altarLbl: String { pick("Altar", "祭坛", "祭壇") }
    var altarFull: String { pick("Your altar is full.", "祭坛已满。", "祭壇がいっぱいです。") }
    func prayed(_ c: String) -> String { pick("You place \(c) on your altar.", "你把\(c)放上了祭坛。", "\(c)を祭壇に置いた。") }
    func ePrayed(_ x: String, _ c: String) -> String { pick("\(x) places \(c) on the altar.", "\(x)把\(c)放上了祭坛。", "\(x)が\(c)を祭壇に置いた。") }
    func prayerDone(_ x: String, _ c: String) -> String { pick("\(x): \(c) is answered.", "\(x)的\(c)应验了。", "\(x)の\(c)が成就した。") }
    var fPray: String { pick("Answered", "应验", "成就") }
    var fRevive: String { pick("Revived", "复活", "復活") }
    private func stat(_ a: Int, _ h: Int) -> String {
        if a > 0 && h > 0 { return "+\(a)/+\(h)" }
        if a > 0 { return pick("+\(a) Attack", "+\(a)攻击力", "攻撃力+\(a)") }
        return pick("+\(h) Health", "+\(h)生命值", "体力+\(h)")
    }
    func summonText(_ n: Int, _ a: Int, _ h: Int, _ nm: String) -> String {
        switch lang {
        case .en:
            if n > 1 { return "Summon \(["", "a", "two", "three", "four"][min(n, 4)]) \(a)/\(h) \(nm)s." }
            return "Summon a \(a)/\(h) \(nm)."
        case .zh: return "召唤\(["", "一", "两", "三", "四"][min(n, 4)])个\(a)/\(h)的\(nm)。"
        case .ja: return "\(a)/\(h)の\(nm)を\(n)体召喚する。"
        }
    }
    var kwOnPlay: String { pick("On play: ", "登场：", "登場時：") }
    var kwLast: String { pick("Last breath: ", "遗言：", "断末魔：") }
    var kwCharge: String { pick("Charge", "冲锋", "突撃") }
    /// Full rules text of a card.
    func cardText(_ c: Card) -> String {
        if let t = c.text { return name(t) }
        var kws: [String] = []
        if c.hasGuard { kws.append(guardKw) }
        if c.ward { kws.append(wardKw) }
        if c.surge { kws.append(kwCharge) }
        let sep = lang == .en ? " " : "", kwSep = lang == .en ? ". " : "。", end = lang == .en ? "." : "。"
        var s = kws.isEmpty ? "" : kws.joined(separator: kwSep) + end
        if let bc = c.bc { s += (s.isEmpty ? "" : sep) + kwOnPlay + fxText(bc, bc.tgt) }
        if let g = c.gasp, let gc = GameData.shared.card(g) { s += (s.isEmpty ? "" : sep) + kwLast + summonText(1, gc.atk ?? 0, gc.hp ?? 0, name(gc.names)) }
        if let pr = c.pray { s += kwPray(pr.cd) + fxText(pr.fx, nil) }
        else if let fx = c.fx { s += fxText(fx, fx.tgt) }
        return s
    }
    /// Keywords that get bolded in card text.
    var keywords: [String] {
        switch lang {
        case .en: return ["Guard", "Ward", "Charge", "Ethereal", "On play", "Last breath", "Freeze", "Silence", "Spell Damage", "Prayer"]
        case .zh: return ["守护", "护盾", "冲锋", "虚体", "登场", "遗言", "冻结", "沉默", "法术伤害", "祷文"]
        case .ja: return ["ガード", "結界", "突撃", "霊体", "登場時", "断末魔", "凍結", "沈黙", "呪文ダメージ", "祈祷"]
        }
    }
    func cardName(_ id: String) -> String { GameData.shared.card(id).map { name($0.names) } ?? id }
    func cardFlavor(_ id: String) -> String { GameData.shared.card(id).map { name($0.flavor) } ?? "" }
    func className(_ id: String) -> String { GameData.shared.cls(id).map { name($0.names) } ?? id }
    func powerName(_ p: Power) -> String { name(p.names) }
    func powerDesc(_ p: Power) -> String { fxText(p.fx, p.tgt) }
    func oppName(_ i: Int) -> String { GameData.shared.opponents.indices.contains(i) ? name(GameData.shared.opponents[i].names) : "" }
}
