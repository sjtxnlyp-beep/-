---@diagnostic disable: undefined-global
------------------------------------------------------------
-- LoreSystem.lua — 非洲文化图鉴 / 博物馆系统
-- [2.2] 收集+教育+长期目标
------------------------------------------------------------

local M = {}

-- ============================================================
-- 图鉴分类
-- ============================================================
M.CATEGORIES = {
    { id = "characters", name = "角色档案", icon = "👤", desc = "你队伍中的传奇人物" },
    { id = "cities",     name = "城市百科", icon = "🏙️", desc = "非洲大陆的明珠" },
    { id = "culture",    name = "文化知识", icon = "🎭", desc = "多彩的非洲文明" },
    { id = "food",       name = "美食图鉴", icon = "🍲", desc = "舌尖上的非洲" },
    { id = "slang",      name = "俚语辞典", icon = "💬", desc = "街头黑话大全" },
    { id = "history",    name = "电竞简史", icon = "📜", desc = "非洲电竞崛起之路" },
    { id = "items",      name = "物品图鉴", icon = "🎒", desc = "市场淘来的宝贝" },
}

-- ============================================================
-- 图鉴条目数据（60+ 条）
-- ============================================================
M.ENTRIES = {
    -- ─── 角色档案（8条）───
    { id = "char_kofi", category = "characters",
      title = "Kofi", subtitle = "街头天才",
      unlockType = "recruit", unlockParam = "Kofi",
      content = "Kofi，全名 Kofi Mensah。在阿坎族命名传统中，周五出生的男孩会被命名为 Kofi。来自加纳库马西的可可种植家庭，15岁时在网吧旧电脑上自学成为服务器第一。",
      cultural_note = "阿坎族'日名'制度：周一=Kwadwo, 周二=Kwabena, 周三=Kwaku, 周四=Yaw, 周五=Kofi, 周六=Kwame, 周日=Kwasi。联合国前秘书长科菲·安南(Kofi Annan)也是周五出生。" },

    { id = "char_grace", category = "characters",
      title = "Grace", subtitle = "闪电手速",
      unlockType = "recruit", unlockParam = "Grace",
      content = "Grace Okafor，尼日利亚伊博族姑娘。在拉各斯长大，从小在妈妈的手机维修摊帮忙，练就了超凡的手指灵活度。她的 APM（每分钟操作数）在本地无人能敌。",
      cultural_note = "伊博族是尼日利亚三大民族之一(豪萨、约鲁巴、伊博)，以经商能力著称。'Igbo land is no man's land'——伊博人在非洲各地都能找到商机。" },

    { id = "char_snake", category = "characters",
      title = "Snake", subtitle = "毒蛇老兵",
      unlockType = "recruit", unlockParam = "Snake",
      content = "Snake，真名不详。据说来自肯尼亚蒙巴萨港口区，年轻时是码头搬运工。某天在网吧里展现了惊人的FPS天赋——'像蛇一样安静地接近，然后一击致命'。",
      cultural_note = "蒙巴萨是东非最大港口，斯瓦希里语'mvita'意为'战争之岛'。这里的旧城区有着阿拉伯-斯瓦希里混合建筑风格，被联合国列为世界遗产。" },

    { id = "char_prince", category = "characters",
      title = "Prince", subtitle = "贵族少爷",
      unlockType = "recruit", unlockParam = "Prince",
      content = "Prince Adeyemi，来自约鲁巴族的富裕家庭。父亲是拉各斯的进口商人，本该继承家业，但他选择了电竞之路。打法华丽但偶尔粗心。",
      cultural_note = "约鲁巴族有着复杂的世袭头衔系统。'Oba'是国王，'Chief'是酋长。现代约鲁巴贵族虽不再有政治权力，但在社区中仍受尊敬。" },

    { id = "char_bigjoe", category = "characters",
      title = "Big Joe", subtitle = "铁壁坦克",
      unlockType = "recruit", unlockParam = "Big Joe",
      content = "Big Joe，原名 Joseph Osei。加纳退役半职业拳击手，手掌如蒲扇。转行电竞后成了最强防守型选手——'你可以打我，但你打不过我'。",
      cultural_note = "加纳有着深厚的拳击传统。传奇拳王 Azumah Nelson 是加纳民族英雄，曾获 WBC 羽量级和超羽量级世界冠军。Bukom 社区被称为'拳击工厂'。" },

    { id = "char_mama_b", category = "characters",
      title = "Mama B", subtitle = "网吧大妈",
      unlockType = "recruit", unlockParam = "Mama B",
      content = "Mama B，本名 Binta。原来在网吧对面卖 Jollof Rice 的大婶，后来发现自己有战略天赋——看比赛比队员还紧张，指挥比教练还管用。",
      cultural_note = "在西非，'Mama'不仅是对母亲的称呼，也是对年长女性的尊称。很多社区里，卖食物的'Mama'就是信息集散中心——她们知道所有人的故事。" },

    { id = "char_tiny", category = "characters",
      title = "Tiny", subtitle = "迷你刺客",
      unlockType = "recruit", unlockParam = "Tiny",
      content = "Tiny，塞内加尔来的小个子。身高不到 1.6 米，但反应速度极快。在达喀尔的网吧圈子里有个外号叫'Le Moustique'（蚊子）——烦人但打不到。",
      cultural_note = "达喀尔是塞内加尔首都，也是非洲最西端城市。这里的 Teranga 精神（好客精神）闻名非洲——'Teranga'在沃洛夫语中意为'热情好客'。" },

    { id = "char_doc", category = "characters",
      title = "Doc", subtitle = "分析博士",
      unlockType = "recruit", unlockParam = "Doc",
      content = "Doc，埃塞俄比亚人，真名 Dawit。在亚的斯亚贝巴大学读了三年计算机科学后退学搞电竞数据分析。队友叫他 Doc 因为'他总能诊断出我们输的原因'。",
      cultural_note = "埃塞俄比亚是非洲唯一未被殖民的国家（意大利短暂占领不被承认）。它有自己独特的字母系统(Ge'ez)、日历（比公历晚7-8年）和计时方式（日出为0点）。" },

    -- ─── 城市百科（7条）───
    { id = "city_wakandaville", category = "cities",
      title = "瓦坎达维尔", subtitle = "梦开始的地方",
      unlockType = "city", unlockParam = "wakandaville",
      content = "一个虚构的西非小镇，到处是铁皮屋顶、红土路和生机勃勃的市场。Dragon Net Cafe 就在主街拐角处，门前那棵芒果树是最好的地标。",
      cultural_note = "非洲的网吧文化始于1990年代末。在智能手机普及前，网吧是非洲年轻人接触数字世界的主要窗口——游戏、社交、学习，一切都在这里发生。" },

    { id = "city_lagos", category = "cities",
      title = "拉各斯", subtitle = "非洲的纽约",
      unlockType = "city", unlockParam = "lagos",
      content = "尼日利亚第一大城市，人口超 2000 万。这里有非洲最大电影产业'诺莱坞'(Nollywood)，每年产出约 2500 部电影。同时也是西非电竞的中心。",
      cultural_note = "拉各斯原名'Eko'（约鲁巴语'营地'）。'Lagos'是15世纪葡萄牙探险者取的名字，源自葡萄牙南部的Lagos镇。全城分为大陆部分和岛屿部分，维多利亚岛是富人区。" },

    { id = "city_nairobi", category = "cities",
      title = "内罗毕", subtitle = "东非硅谷",
      unlockType = "city", unlockParam = "nairobi",
      content = "肯尼亚首都，东非创业之城。M-Pesa 移动支付就诞生在这里，比微信支付还早了好几年。科技园区 iHub 是非洲创新的摇篮。",
      cultural_note = "内罗毕在马赛语中意为'凉爽的水'(Enkare Nairobi)。这座城市建在 1600 米高原上，虽在赤道附近但气候凉爽。市内还有世界唯一的城市国家公园——能在 CBD 看长颈鹿。" },

    { id = "city_accra", category = "cities",
      title = "阿克拉", subtitle = "黄金海岸明珠",
      unlockType = "city", unlockParam = "accra",
      content = "加纳首都，大西洋畔的文化重镇。这里有西非最好的大学之一——加纳大学。Osu 牛津街是年轻人聚集地，网吧林立。",
      cultural_note = "加纳是撒哈拉以南非洲第一个独立的殖民地国家(1957年)。独立领袖夸梅·恩克鲁玛(Kwame Nkrumah)提出了泛非主义理想，非洲联盟的精神源头之一。" },

    { id = "city_dakar", category = "cities",
      title = "达喀尔", subtitle = "大西洋之门",
      unlockType = "city", unlockParam = "dakar",
      content = "塞内加尔首都，非洲最西端的大城市。因达喀尔拉力赛闻名世界。港口贸易发达，黄金和珠宝市场兴旺。",
      cultural_note = "达喀尔的戈雷岛(Île de Gorée)是大西洋奴隶贸易的重要历史遗址，现为世界遗产。'不归之门'面朝大海，象征着数百万非洲人的命运。每年有数十万人来此凭吊。" },

    { id = "city_capetown", category = "cities",
      title = "开普敦", subtitle = "彩虹之城",
      unlockType = "city", unlockParam = "capetown",
      content = "南非立法首都，非洲基础设施最完善的城市。桌山脚下，印度洋与大西洋在此交汇。非洲电竞锦标赛的常驻举办地。",
      cultural_note = "开普敦有11种官方语言并存。Bo-Kaap街区的彩色房屋是马来裔穆斯林社区的标志。好望角并非非洲最南端——真正的最南端是厄加勒斯角(Cape Agulhas)。" },

    { id = "city_kinshasa", category = "cities",
      title = "金沙萨", subtitle = "刚果心跳",
      unlockType = "city", unlockParam = "kinshasa",
      content = "刚果民主共和国首都，非洲第三大城市。这里是伦巴音乐(Rumba)的故乡，也是传说中最疯狂的电竞地下战场。",
      cultural_note = "金沙萨与布拉柴维尔(刚果共和国首都)隔河相望，是世界上距离最近的两个首都(仅1.6公里)。城市别名'Kin la Belle'（美丽的金），以夜生活和音乐闻名。" },

    -- ─── 文化知识（12条，部分由 ComboEvents 触发）───
    { id = "twi_proverb", category = "culture",
      title = "特维语谚语", subtitle = "阿坎族智慧",
      unlockType = "combo", unlockParam = "street_legends",
      content = "'Obi nkyere abofra Nyame' —— 无需教孩子认识上帝（真理不言自明）。特维语(Twi)是加纳阿坎族最广泛使用的语言之一，约有 900 万母语使用者。",
      cultural_note = "加纳有超过80种本土语言。政府承认9种官方本土语言，但英语是通用语。很多加纳人能说3-4种语言。" },

    { id = "ankara_fabric", category = "culture",
      title = "安卡拉蜡染布", subtitle = "非洲时尚之魂",
      unlockType = "combo", unlockParam = "kings_tailor",
      content = "安卡拉(Ankara)布料以鲜艳的几何图案闻名，是西非最具标志性的纺织品。每块图案都有名字和含义。",
      cultural_note = "虽然叫'非洲蜡染布'，但安卡拉技术其实源自印尼蜡染(Batik)，经荷兰传入西非。非洲人将其发展成独特的艺术形式，现在反而是全球非洲文化的象征。" },

    { id = "african_art_boom", category = "culture",
      title = "非洲当代艺术浪潮", subtitle = "从边缘到中心",
      unlockType = "combo", unlockParam = "canvas_code",
      content = "21世纪以来，非洲当代艺术市场爆炸式增长。尼日利亚艺术家 Ben Enwonwu 的画作拍出超过 100 万美元。",
      cultural_note = "非洲大陆有着最古老的艺术传统——南非布隆博斯洞穴的赭石刻画距今7万年，是已知最早的人类抽象艺术。当代非洲艺术家正在'用传统语汇说现代故事'。" },

    { id = "djembe_drum", category = "culture",
      title = "金贝鼓(Djembe)", subtitle = "会说话的鼓",
      unlockType = "combo", unlockParam = "noble_commoner",
      content = "金贝鼓起源于13世纪的曼丁帝国(今马里/几内亚)，用整块木头雕成高脚杯形状，蒙上山羊皮。",
      cultural_note = "在曼丁卡文化中，金贝鼓被称为'能用手触摸音乐的乐器'。传统上只有特定社会阶层(Numu/铁匠种姓)的人才能制作和演奏金贝鼓。" },

    { id = "kente_cloth", category = "culture",
      title = "肯特布(Kente)", subtitle = "王者之布",
      unlockType = "day", unlockParam = 20,
      content = "肯特布是加纳阿散蒂王国的传统编织布料，每种颜色和图案都有深意：金色代表王权，绿色代表丰收，蓝色代表和平。",
      cultural_note = "传说肯特布的灵感来自蜘蛛织网。最珍贵的肯特布只有国王能穿，每块的编织可能需要数月。2001年联合国秘书长安南曾穿肯特布参加就职典礼。" },

    { id = "ubuntu_philosophy", category = "culture",
      title = "乌班图(Ubuntu)", subtitle = "我在故我们在",
      unlockType = "day", unlockParam = 30,
      content = "'Ubuntu'是南部非洲班图语系的哲学概念——'Umuntu ngumuntu ngabantu'（一个人之所以为人，是因为其他人）。",
      cultural_note = "Ubuntu哲学强调社群、分享和互助。曼德拉将其解释为：'旅行者停留在村庄，不用开口要食物和水，人们就会主动提供'。Linux操作系统Ubuntu也取名于此。" },

    { id = "adinkra_symbols", category = "culture",
      title = "阿丁克拉符号", subtitle = "图像里的哲学",
      unlockType = "day", unlockParam = 45,
      content = "阿丁克拉(Adinkra)是加纳阿散蒂族的象征符号系统，有80多个符号，每个表达一个概念或格言。",
      cultural_note = "最著名的阿丁克拉符号是'Gye Nyame'（除了上帝没有谁），象征上帝的至高无上。这些符号被用于布料、建筑、珠宝和当代设计中。" },

    { id = "griot_tradition", category = "culture",
      title = "格里奥(Griot)", subtitle = "活着的图书馆",
      unlockType = "day", unlockParam = 60,
      content = "格里奥是西非的口述历史传承者——集历史学家、音乐家、故事家、外交官于一身的世袭职业。",
      cultural_note = "格里奥被称为'活着的图书馆'。在没有文字的时代，一位格里奥的去世等于烧毁了一座图书馆。他们能背诵数百年的家族谱系和部落历史。" },

    -- ─── 美食图鉴（8条）───
    { id = "jollof_war", category = "food",
      title = "Jollof Rice 之战", subtitle = "西非最大争议",
      unlockType = "combo", unlockParam = "old_young",
      content = "Jollof Rice 是西非最具代表性的米饭料理——番茄酱底、洋葱、辣椒，配上肉或鱼。但尼日利亚和加纳都声称自己的版本最正宗。",
      cultural_note = "这场'Jollof 战争'已经从餐桌延伸到社交媒体。每逢世界食物日，尼日利亚人和加纳人就会在推特上互相嘲讽对方的Jollof。连政客和名人都会参战。" },

    { id = "suya_culture", category = "food",
      title = "Suya 烤肉", subtitle = "街头烟火气",
      unlockType = "combo", unlockParam = "iron_fortress",
      content = "Suya 是尼日利亚的标志性街头小吃——用花生粉、辣椒和香料腌制的烤牛肉串。晚上路边摊的烟火气是拉各斯的灵魂。",
      cultural_note = "Suya 起源于北尼日利亚的豪萨族。正宗的 Suya 用的是 Yaji 调料——花生粉、姜、辣椒、洋葱粉和一种叫 Kanwa 的天然碱。每个 Suya 摊主都有自己的秘方。" },

    { id = "injera_bread", category = "food",
      title = "因杰拉(Injera)", subtitle = "可以吃的盘子",
      unlockType = "day", unlockParam = 15,
      content = "因杰拉是埃塞俄比亚的国民主食——一种海绵状的酸味薄饼，用苔麸(Teff)制成。吃饭时铺在盘子上，撕下一块包裹菜肴。",
      cultural_note = "苔麸(Teff)是世界上最小的谷物，直径不到1毫米。它富含铁质和蛋白质，无麸质，近年在欧美被追捧为'超级食物'。但在埃塞俄比亚，它已经被吃了三千年。" },

    { id = "fufu_pounding", category = "food",
      title = "富富(Fufu)", subtitle = "木臼里的节奏",
      unlockType = "day", unlockParam = 25,
      content = "富富是西非的主食之一——将煮熟的山药、木薯或大蕉放入木臼中捶打成黏糊状。捶打富富的声音是非洲村庄的典型音景。",
      cultural_note = "捶打富富需要两人配合：一人用木杵捶打，另一人翻动面团。节奏感很重要——'咚-翻-咚-翻'。现在有了机器加工，但很多人认为手工捶打的味道更好。" },

    { id = "bunny_chow", category = "food",
      title = "兔子窝(Bunny Chow)", subtitle = "面包碗里的宇宙",
      unlockType = "day", unlockParam = 40,
      content = "起源于南非德班的印度裔社区——把半条面包掏空，填满浓郁的咖喱。名字里虽然有'Bunny'但跟兔子没关系。",
      cultural_note = "'Bunny'可能来自印地语'bania'(商人阶层)。在种族隔离时期，印度裔工人不能在餐厅用餐，就把咖喱装在面包里带走——苦难中诞生的创意美食。" },

    { id = "tagine_pot", category = "food",
      title = "塔吉锅(Tagine)", subtitle = "北非慢炖魔法",
      unlockType = "day", unlockParam = 50,
      content = "塔吉是北非特有的陶土炖锅——锥形盖子能让蒸汽循环，用最少的水炖出最浓郁的味道。",
      cultural_note = "塔吉锅的锥形设计是沙漠地区节水智慧的产物。柏柏尔人(Berber)数千年前就在撒哈拉边缘用这种方式烹饪，一锅炖菜能养活一大家子。" },

    { id = "biltong_jerky", category = "food",
      title = "比尔通(Biltong)", subtitle = "南非的牛肉干",
      unlockType = "prestige", unlockParam = 3,
      content = "比尔通是南非风干肉——用醋、盐和胡椒腌制后风干的牛肉。比美国牛肉干更厚、更嫩、味道更浓。",
      cultural_note = "比尔通起源于17世纪荷兰移民(布尔人)保存肉类的需要。'Biltong'在荷兰语中意为'臀部条肉'。现在是南非看体育比赛时的标配零食。" },

    { id = "chapati_eastafrica", category = "food",
      title = "恰帕蒂(Chapati)", subtitle = "东非版飞饼",
      unlockType = "prestige", unlockParam = 2,
      content = "恰帕蒂是东非（肯尼亚、坦桑尼亚）的日常食物——印度移民带来的无酵饼，在东非发展出了自己的特色：更油、更酥、层次更多。",
      cultural_note = "印度洋贸易把印度文化带到了东非海岸。斯瓦希里语本身就混合了班图语和阿拉伯语，而恰帕蒂则是印度-非洲文化融合的美味证据。" },

    -- ─── 俚语辞典（8条）───
    { id = "slang_wahala", category = "slang",
      title = "Wahala", subtitle = "尼日利亚",
      unlockType = "day", unlockParam = 3,
      content = "意思：麻烦/问题。\n用法：'No wahala!'（没问题！）或 'Wahala dey!'（有麻烦了！）",
      cultural_note = "Wahala 源自豪萨语，已经成为尼日利亚洋泾浜英语(Pidgin)中使用频率最高的词之一。甚至进入了英国俚语圈。" },

    { id = "slang_sabi", category = "slang",
      title = "Sabi", subtitle = "西非通用",
      unlockType = "day", unlockParam = 8,
      content = "意思：知道/懂得/擅长。\n用法：'You sabi this game!'（你很懂这游戏！）",
      cultural_note = "Sabi 来自葡萄牙语'saber'(知道)。西非洋泾浜英语中有大量葡萄牙语借词，因为葡萄牙人是最早到达西非海岸的欧洲人。" },

    { id = "slang_sharp", category = "slang",
      title = "Sharp-sharp", subtitle = "南非",
      unlockType = "day", unlockParam = 12,
      content = "意思：好的/酷/没问题/再见。\n用法：'Sharp-sharp, bro!'（好嘞兄弟！）",
      cultural_note = "南非有自己独特的俚语体系叫 Tsotsitaal，混合了祖鲁语、阿非利卡语和英语。Sharp-sharp 是最友好的日常用语之一。" },

    { id = "slang_sawa", category = "slang",
      title = "Sawa", subtitle = "东非",
      unlockType = "day", unlockParam = 18,
      content = "意思：好的/OK/没问题。\n用法：'Sawa sawa!'（完全没问题！）",
      cultural_note = "Sawa 是斯瓦希里语，在肯尼亚和坦桑尼亚使用极广。斯瓦希里语是非洲使用人数最多的语言之一，约有1亿使用者（大多数为第二语言）。" },

    { id = "slang_chale", category = "slang",
      title = "Chale", subtitle = "加纳",
      unlockType = "day", unlockParam = 22,
      content = "意思：兄弟/朋友（类似 bro/dude）。\n用法：'Chale, we go win!'（兄弟，我们会赢的！）",
      cultural_note = "Chale 在加纳 Pidgin 中无处不在。加纳人还喜欢说'charley'作为变体。阿克拉有一种拖鞋叫'Charlie wote'（Charlie走吧），因为穿上就能立刻出门。" },

    { id = "slang_lekker", category = "slang",
      title = "Lekker", subtitle = "南非",
      unlockType = "day", unlockParam = 35,
      content = "意思：好/棒/美味/愉快（万能正面形容词）。\n用法：'That match was lekker!'（那场比赛太棒了！）",
      cultural_note = "Lekker 来自阿非利卡语(Afrikaans)，源头是荷兰语。南非英语中大量夹杂阿非利卡语词汇，形成了独特的'South African English'。" },

    { id = "slang_asap_rocky", category = "slang",
      title = "Oga", subtitle = "尼日利亚",
      unlockType = "day", unlockParam = 28,
      content = "意思：老板/大佬/老大。\n用法：'Oga, abeg give me discount!'（老板，求你给个折扣！）",
      cultural_note = "Oga 源自约鲁巴语，表示尊敬和权威。在尼日利亚，对老板、警察、甚至公交车司机都可以用'Oga'。类似中文'师傅'的万能尊称。" },

    { id = "slang_braa", category = "slang",
      title = "Bra/Bru", subtitle = "南非",
      unlockType = "prestige", unlockParam = 4,
      content = "意思：兄弟/哥们（类似 bro）。\n用法：'Howzit, bru!'（嘿兄弟，怎么样！）",
      cultural_note = "'Howzit'(How is it的缩略)加'bru'(brother的缩略)是南非最经典的打招呼方式。在开普敦的冲浪文化中尤其流行。" },

    -- ─── 电竞简史（8条）───
    { id = "hist_lan_party", category = "history",
      title = "LAN Party 时代", subtitle = "网线连接的热血",
      unlockType = "day", unlockParam = 5,
      content = "在宽带普及前，非洲的电竞比赛都是通过局域网(LAN)进行的。几十台电脑用网线连在一起，选手们肩并肩坐在狭小的网吧里战斗。",
      cultural_note = "非洲第一批电竞赛事大多在南非举办（如 rAge Gaming Expo，始于2002年）。由于网络基础设施的限制，LAN赛制在非洲持续的时间比其他地区更长。" },

    { id = "hist_mobile_revolution", category = "history",
      title = "手机革命", subtitle = "跳过PC时代",
      unlockType = "day", unlockParam = 10,
      content = "非洲跳过了个人电脑时代，直接进入移动时代。2020年非洲移动用户超过5亿，手机游戏成为最大的游戏市场。",
      cultural_note = "这种'蛙跳效应'在非洲很常见：没有固定电话直接用手机，没有银行网点直接用移动支付。M-Pesa(肯尼亚)是全球最成功的移动支付，比支付宝还早好几年。" },

    { id = "hist_esports_growth", category = "history",
      title = "非洲电竞起飞", subtitle = "2018-2023",
      unlockType = "day", unlockParam = 35,
      content = "2018年后非洲电竞进入爆发期：南非 Bravado Gaming 在CS:GO打入国际赛事；尼日利亚 FIFA 电竞在全球排名前列；肯尼亚诞生了多个职业战队。",
      cultural_note = "非洲电竞的增长速度是全球最快的——年均增长率超过30%。但基础设施和赞助仍是最大挑战：很多非洲职业选手不得不在网吧训练，因为买不起自己的设备。" },

    { id = "african_boxing", category = "history",
      title = "非洲拳击传统", subtitle = "从拳台到键盘",
      unlockType = "combo", unlockParam = "iron_fortress",
      content = "加纳 Bukom 社区被称为'拳击工厂'——这个渔村出了 7 位世界冠军。拳击在非洲不仅是运动，更是脱贫的阶梯。",
      cultural_note = "从 Azumah Nelson 到 Joshua Clottey，加纳拳手以技术细腻著称。电竞选手 Big Joe 从拳击转型，体现了非洲年轻人在不同'竞技场'间的流动性。" },

    { id = "gold_coast_history", category = "history",
      title = "黄金海岸的故事", subtitle = "从殖民到独立",
      unlockType = "combo", unlockParam = "merchant_alliance",
      content = "加纳古称'黄金海岸'(Gold Coast)，是非洲黄金产量最高的地区之一。15世纪起，欧洲人为黄金而来，带走了黄金和奴隶。",
      cultural_note = "1957年黄金海岸独立，改名'Ghana'——取自中世纪的加纳帝国。虽然地理上并不重叠，但这个名字象征着非洲的黄金文明和独立自强的精神。" },

    { id = "hist_internet_cables", category = "history",
      title = "海底光缆登陆", subtitle = "非洲连接世界",
      unlockType = "day", unlockParam = 55,
      content = "2009年 SEACOM 海底光缆在蒙巴萨登陆，东非网速暴涨50倍。此后 EASSy、WACS 等光缆相继铺设，非洲终于不再是互联网孤岛。",
      cultural_note = "在海底光缆之前，非洲的国际带宽主要靠卫星，延迟高达600ms——对电竞来说是致命的。光缆让非洲玩家第一次能和欧洲服务器实现合理延迟的对战。" },

    { id = "hist_streaming", category = "history",
      title = "非洲游戏主播崛起", subtitle = "YouTube一代",
      unlockType = "prestige", unlockParam = 5,
      content = "2020年代，非洲游戏主播在 YouTube 和 Twitch 上崛起。尼日利亚主播们用 Pidgin 英语解说的风格吸引了全球观众。",
      cultural_note = "非洲主播面临独特挑战：电力不稳定(随时可能停电)、网络波动、设备昂贵。但他们的幽默感和生命力反而成了特色——停电时表演'黑屏脱口秀'成了名场面。" },

    { id = "hist_future", category = "history",
      title = "非洲电竞2030", subtitle = "下一个十亿玩家",
      unlockType = "prestige", unlockParam = 6,
      content = "非洲人口中位年龄仅19岁——全球最年轻的大陆。到2030年预计将有6亿游戏玩家。这里将是全球游戏产业最后一块蓝海。",
      cultural_note = "非洲大陆有54个国家、2000多种语言。游戏本地化是巨大的商业机会。越来越多本土游戏工作室开始创作'非洲故事'的游戏，而非简单移植海外作品。" },

    -- ─── 物品图鉴（8条，由市场获取触发）───
    { id = "item_tier1", category = "items",
      title = "路边货", subtitle = "便宜大碗",
      unlockType = "item_tier", unlockParam = 1,
      content = "路边摊淘来的二手设备——虽然破旧但能用。非洲网吧里90%的设备都是从欧洲'电子垃圾'中翻新的。",
      cultural_note = "加纳阿克拉的 Agbogbloshie 曾是世界最大电子垃圾场。工人们冒着有毒烟雾拆解旧电脑提取铜和金，日收入仅2-5美元。2021年该场地已关闭搬迁。" },

    { id = "item_tier2", category = "items",
      title = "集市货", subtitle = "市场淘宝",
      unlockType = "item_tier", unlockParam = 2,
      content = "集市上的正规二手货——有时候运气好能淘到九成新的设备。非洲的二手市场是一门大学问。",
      cultural_note = "西非市场(如尼日利亚的 Computer Village)是非洲最大的电子产品集散地。这里的商贩能以惊人的低价组装'白牌'电脑，性能不输品牌机。" },

    { id = "item_tier3", category = "items",
      title = "工坊精品", subtitle = "匠人手艺",
      unlockType = "item_tier", unlockParam = 3,
      content = "非洲本土工坊出品——这些小作坊虽然设备简陋，但产出的东西品质惊人。'非洲制造'不代表粗糙。",
      cultural_note = "肯尼亚的 BRCK 公司制造了'非洲最坚固的路由器'——防尘、防水、内置电池，专为非洲环境设计。这代表了'为非洲设计'(Design for Africa)的新趋势。" },

    { id = "item_tier4", category = "items",
      title = "大师手工", subtitle = "稀世之珍",
      unlockType = "item_tier", unlockParam = 4,
      content = "由顶级工匠打造的定制设备——在非洲，真正的大师级工匠是社区的骄傲和传奇。",
      cultural_note = "非洲的工匠(Artisan)传统源远流长。贝宁青铜器、阿散蒂黄金饰品、马赛珠饰……这些传统工艺代表了非洲数千年的制造智慧。现在新一代工匠在用3D打印延续这种精神。" },

    { id = "item_tier5", category = "items",
      title = "祖传宝物", subtitle = "传说中的存在",
      unlockType = "item_tier", unlockParam = 5,
      content = "几乎见不到的传说级设备——据说是某位传奇电竞选手退役时留下的遗物。拥有它就等于拥有了一段历史。",
      cultural_note = "在非洲传统文化中，祖先留下的物品(Ancestral artifacts)具有精神力量。这种信仰在现代电竞中演变为'传奇选手的设备带有好运'——类似中国的'锦鲤'文化。" },

    { id = "item_golden_keyboard", category = "items",
      title = "黄金键盘", subtitle = "阿散蒂皇家工艺",
      unlockType = "item_special", unlockParam = "golden_keyboard",
      content = "用阿散蒂王国传统金工技艺打造的键盘——每个键帽都镶嵌着微型阿丁克拉符号。据说输入时能带来好运。",
      cultural_note = "阿散蒂王国(位于今加纳)以精湛的金工技艺闻名。黄金凳(Golden Stool)是王国的精神象征，据说从天而降，代表民族的灵魂。" },

    { id = "item_djembe_speaker", category = "items",
      title = "金贝鼓音箱", subtitle = "传统与科技的碰撞",
      unlockType = "item_special", unlockParam = "djembe_speaker",
      content = "把金贝鼓改造成蓝牙音箱——低频震撼如战鼓，高频清亮如溪流。非洲匠人的创意永远令人惊叹。",
      cultural_note = "非洲的'回收改造'(Upcycling)文化令人叹为观止。从汽油桶变成钢鼓(Steel Pan)，到轮胎变成凉鞋，再到油桶变成足球门——创意就是非洲人的超能力。" },

    { id = "item_ankara_mousepad", category = "items",
      title = "安卡拉鼠标垫", subtitle = "布料上的战场",
      unlockType = "item_special", unlockParam = "ankara_mousepad",
      content = "用正宗安卡拉蜡染布制作的超大鼠标垫。每一块的图案都是独一无二的——就像每场比赛都不会重复。",
      cultural_note = "安卡拉布料的图案有自己的名字和故事。'Target'图案(同心圆)寓意专注，'Fern'图案(蕨叶)代表坚韧——电竞选手偏爱这两种图案不是没有道理。" },
}

-- ============================================================
-- 解锁逻辑
-- ============================================================

--- 尝试解锁一个图鉴条目
---@param entryId string 条目ID
---@return boolean 是否新解锁
function M.TryUnlock(entryId)
    if not playerData_ then return false end
    playerData_.loreUnlocked = playerData_.loreUnlocked or {}
    if playerData_.loreUnlocked[entryId] then return false end

    playerData_.loreUnlocked[entryId] = true
    playerData_.loreNewCount = (playerData_.loreNewCount or 0) + 1

    -- 记录最近解锁（用于 toast 通知）
    playerData_.loreLastUnlock = entryId

    -- 找到对应条目，打日志
    for _, entry in ipairs(M.ENTRIES) do
        if entry.id == entryId then
            AddLog("📖 图鉴解锁：" .. (entry.title or entryId))
            break
        end
    end
    return true
end

--- 批量检测并解锁满足条件的条目
function M.CheckAllUnlocks()
    if not playerData_ then return end
    playerData_.loreUnlocked = playerData_.loreUnlocked or {}

    for _, entry in ipairs(M.ENTRIES) do
        if not playerData_.loreUnlocked[entry.id] then
            local shouldUnlock = false

            if entry.unlockType == "recruit" then
                -- 招募了指定角色
                shouldUnlock = HasMember and HasMember(entry.unlockParam)

            elseif entry.unlockType == "city" then
                -- 解锁了指定城市
                shouldUnlock = (entry.unlockParam == "wakandaville") or (playerData_.currentCity == entry.unlockParam)
                -- 也检查已解锁城市列表
                if not shouldUnlock and playerData_.unlockedCities then
                    for _, cid in ipairs(playerData_.unlockedCities) do
                        if cid == entry.unlockParam then
                            shouldUnlock = true
                            break
                        end
                    end
                end

            elseif entry.unlockType == "combo" then
                -- 完成了指定组合事件
                local ct = playerData_.comboTriggered or {}
                shouldUnlock = ct[entry.unlockParam] == true

            elseif entry.unlockType == "day" then
                -- 到达指定天数
                shouldUnlock = (playerData_.day or 1) >= entry.unlockParam

            elseif entry.unlockType == "item_tier" then
                -- 获得过指定品质的物品
                local maxTier = playerData_.loreMaxItemTier or 1
                shouldUnlock = maxTier >= entry.unlockParam

            elseif entry.unlockType == "item_special" then
                -- 获得过特殊物品（通过 ID 标记）
                local specialItems = playerData_.loreSpecialItems or {}
                shouldUnlock = specialItems[entry.unlockParam] == true

            elseif entry.unlockType == "prestige" then
                -- 到达指定转生次数
                local pCount = playerData_.prestigeCount or 0
                shouldUnlock = pCount >= entry.unlockParam
            end

            if shouldUnlock then
                M.TryUnlock(entry.id)
            end
        end
    end
end

--- 当招募角色时调用
---@param memberName string
function M.OnRecruit(memberName)
    for _, entry in ipairs(M.ENTRIES) do
        if entry.unlockType == "recruit" and entry.unlockParam == memberName then
            M.TryUnlock(entry.id)
        end
    end
end

--- 当获得物品时调用（更新最高品质）
---@param tier number 品质等级 1-5
---@param itemId? string 特殊物品ID
function M.OnItemObtained(tier, itemId)
    if not playerData_ then return end
    local maxTier = playerData_.loreMaxItemTier or 0
    if tier > maxTier then
        playerData_.loreMaxItemTier = tier
    end
    -- 检测品质解锁
    for _, entry in ipairs(M.ENTRIES) do
        if entry.unlockType == "item_tier" and tier >= entry.unlockParam then
            M.TryUnlock(entry.id)
        end
    end
    -- 特殊物品
    if itemId then
        playerData_.loreSpecialItems = playerData_.loreSpecialItems or {}
        playerData_.loreSpecialItems[itemId] = true
        for _, entry in ipairs(M.ENTRIES) do
            if entry.unlockType == "item_special" and entry.unlockParam == itemId then
                M.TryUnlock(entry.id)
            end
        end
    end
end

--- 当到达新城市时调用
---@param cityId string
function M.OnCityReached(cityId)
    if not playerData_ then return end
    for _, entry in ipairs(M.ENTRIES) do
        if entry.unlockType == "city" and entry.unlockParam == cityId then
            M.TryUnlock(entry.id)
        end
    end
end

-- ============================================================
-- 查询 API
-- ============================================================

--- 获取某分类的所有条目（含解锁状态）
---@param categoryId string
---@return table[] entries
function M.GetCategoryEntries(categoryId)
    local results = {}
    playerData_.loreUnlocked = playerData_.loreUnlocked or {}
    for _, entry in ipairs(M.ENTRIES) do
        if entry.category == categoryId then
            table.insert(results, {
                id = entry.id,
                title = entry.title,
                subtitle = entry.subtitle,
                content = entry.content,
                cultural_note = entry.cultural_note,
                unlocked = playerData_.loreUnlocked[entry.id] == true,
            })
        end
    end
    return results
end

--- 获取总进度
---@return number unlocked, number total
function M.GetProgress()
    playerData_.loreUnlocked = playerData_.loreUnlocked or {}
    local unlocked = 0
    for _ in pairs(playerData_.loreUnlocked) do
        unlocked = unlocked + 1
    end
    return unlocked, #M.ENTRIES
end

--- 获取新解锁数量（红点用）
---@return number
function M.GetNewCount()
    return playerData_.loreNewCount or 0
end

--- 清除新解锁计数（进入图鉴 UI 时调用）
function M.ClearNewCount()
    if playerData_ then
        playerData_.loreNewCount = 0
    end
end

--- 获取最近解锁的条目信息（toast 用）
---@return table|nil entry
function M.GetLastUnlockEntry()
    local lastId = playerData_ and playerData_.loreLastUnlock
    if not lastId then return nil end
    for _, entry in ipairs(M.ENTRIES) do
        if entry.id == lastId then return entry end
    end
    return nil
end

return M
