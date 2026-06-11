---@diagnostic disable: undefined-global
------------------------------------------------------------
-- MarketData.lua — 二手市场道具数据定义
------------------------------------------------------------

local MarketData = {}

-- ============================================================
-- 品质等级
-- ============================================================
MarketData.TIERS = {
    [1] = { name = "路边货",   stars = "★",         color = { 180, 180, 180, 255 }, weight = 500, durability = 5  },
    [2] = { name = "集市货",   stars = "★★",        color = { 100, 200, 100, 255 }, weight = 300, durability = 8  },
    [3] = { name = "工坊精品", stars = "★★★",       color = { 100, 150, 255, 255 }, weight = 140, durability = 12 },
    [4] = { name = "大师手工", stars = "★★★★",      color = { 180, 100, 255, 255 }, weight = 50,  durability = 20 },
    [5] = { name = "祖传宝物", stars = "★★★★★",     color = { 255, 200, 50, 255  }, weight = 10,  durability = 50 },
}

-- 回收返还哈弗币
MarketData.RECYCLE_VALUE = { [1] = 10, [2] = 20, [3] = 50, [4] = 120, [5] = 300 }

-- 保底阈值
MarketData.PITY = {
    rare   = 10,   -- 每10抽保底蓝+
    epic   = 30,   -- 每30抽保底紫+
    legendSoft = 40, -- 40抽起软保底(金概率每抽+2%)
    legendHard = 50, -- 50抽硬保底金
}

-- 装备栏位解锁
MarketData.SLOT_UNLOCK = {
    { day = 0,  cost = 0,    slots = 3 }, -- 初始3格
    { day = 10, cost = 1000, slots = 4 },
    { day = 20, cost = 3000, slots = 5 },
    { day = 30, cost = 5000, slots = 6 },
}

-- 抽卡费用
MarketData.PULL_COST = {
    single = 80,      -- 哈弗币
    ten    = 680,     -- 哈弗币(85折)
    money  = 500,     -- 现金
}

-- ============================================================
-- 道具池（30+件）
-- effects 键名与 Market.CalcEquippedEffects() 返回值对应
-- ============================================================
MarketData.ITEMS = {
    -- ═══════════ 设备配件 ═══════════
    { id = "usb_fan",       name = "旧USB风扇",         tier = 1, category = "equipment", icon = "🌀",
      flavor = "阿克拉路边小贩那里淘的，转速感人",
      effects = { equipDecayReduction = 0.02 } },
    { id = "keyboard_cover", name = "防尘键盘套",       tier = 1, category = "equipment", icon = "⌨️",
      flavor = "拉各斯电子市场的塑料套，防灰尘一流",
      effects = { equipDecayReduction = 0.03 } },
    { id = "diy_cooler",    name = "手工散热垫",         tier = 2, category = "equipment", icon = "❄️",
      flavor = "用瓦楞纸板和小风扇DIY的散热神器",
      effects = { equipDecayReduction = 0.05, trafficBonus = 0.02 } },
    { id = "surge_protector", name = "稳压插排",        tier = 2, category = "equipment", icon = "🔌",
      flavor = "尼日利亚制造，专治电压不稳",
      effects = { equipDecayReduction = 0.04, dailyMoneyBonus = 15 } },
    { id = "mech_keyboard", name = "翻新机械键盘",       tier = 3, category = "equipment", icon = "⌨️",
      flavor = "从二手市场淘来的Cherry轴，手感丝滑",
      effects = { trainBonus = 0.10 } },
    { id = "xxl_mousepad",  name = "定制鼠标垫(XXL)",    tier = 3, category = "equipment", icon = "🖱️",
      flavor = "印着战队Logo的超大鼠标垫",
      effects = { matchPower = 3 } },
    { id = "ups_unit",      name = "企业级UPS",          tier = 4, category = "equipment", icon = "🔋",
      flavor = "从倒闭的银行搬来的二手货，稳如老狗",
      effects = { blackoutImmunity = 1, dailyMoneyBonus = 30 } },
    { id = "water_cooling", name = "水冷散热改装套件",   tier = 5, category = "equipment", icon = "💧",
      flavor = "传说中的非洲手工水冷系统，全网吧最酷",
      effects = { equipDecayReduction = 0.15, trafficBonus = 0.08, allRevenueBonus = 0.05 } },

    -- ═══════════ 装饰摆件 ═══════════
    { id = "football_poster", name = "足球海报",        tier = 1, category = "decoration", icon = "⚽",
      flavor = "超级雄鹰队的经典海报，客人爱看",
      effects = { repBonus = 0.05 } },
    { id = "old_speaker",   name = "二手音箱",           tier = 1, category = "decoration", icon = "🔊",
      flavor = "声音有点破，但够响",
      effects = { moodDecayReduction = 0.03 } },
    { id = "djembe_drum",   name = "非洲鼓(Djembe)",     tier = 2, category = "decoration", icon = "🥁",
      flavor = "加纳手工木鼓，有时客人会来敲两下",
      effects = { repBonus = 0.08, moodDecayReduction = 0.05 } },
    { id = "kente_tapestry", name = "Kente布壁挂",       tier = 2, category = "decoration", icon = "🎨",
      flavor = "阿散蒂手织布，象征尊贵与智慧",
      effects = { repBonus = 0.10 } },
    { id = "led_strip",     name = "LED氛围灯带",        tier = 3, category = "decoration", icon = "💡",
      flavor = "从深圳进口的RGB灯带，赛博朋克风",
      effects = { trafficBonus = 0.05, repBonus = 0.08 } },
    { id = "fake_trophy",   name = "电竞冠军奖杯(仿)",   tier = 3, category = "decoration", icon = "🏆",
      flavor = "3D打印的冠军奖杯复制品，客人分不出真假",
      effects = { repBonus = 0.12 } },
    { id = "sand_painting", name = "黄金海岸沙画",       tier = 4, category = "decoration", icon = "🖼️",
      flavor = "大师级沙画艺术品，价值连城",
      effects = { repBonus = 0.15, moodDecayReduction = 0.08 } },
    { id = "ancestral_mask", name = "祖灵面具",          tier = 5, category = "decoration", icon = "🎭",
      flavor = "据说能带来好运的百年面具，网吧镇店之宝",
      effects = { allRevenueBonus = 0.10, repBonus = 0.20 } },

    -- ═══════════ 功能道具 ═══════════
    { id = "energy_recipe",  name = "能量饮料配方",      tier = 1, category = "functional", icon = "🧃",
      flavor = "咖啡因+糖的秘方，提神醒脑",
      effects = { trainBonus = 0.05 } },
    { id = "tactic_notebook", name = "旧战术笔记本",     tier = 2, category = "functional", icon = "📓",
      flavor = "前职业选手遗留的笔记，字迹潦草但有料",
      effects = { trainBonus = 0.08, matchPower = 2 } },
    { id = "wifi_booster",   name = "WiFi信号增强器",    tier = 2, category = "functional", icon = "📡",
      flavor = "自制的锡罐天线，信号强了两格",
      effects = { trafficBonus = 0.04, dailyMoneyBonus = 20 } },
    { id = "event_handbook", name = "赛事组织手册",      tier = 3, category = "functional", icon = "📖",
      flavor = "教你怎么办比赛省钱",
      effects = { matchCostReduction = 0.15 } },
    { id = "energy_capsule", name = "黑市能量胶囊",      tier = 3, category = "functional", icon = "💊",
      flavor = "来路不明但效果拔群，嘘……",
      effects = { apBonus = 1 } },
    { id = "train_ai",       name = "训练AI分析软件",    tier = 4, category = "functional", icon = "🤖",
      flavor = "破解版的职业训练软件，用了都说好",
      effects = { trainBonus = 0.25 } },
    { id = "golden_contract", name = "黄金经理人合同",   tier = 5, category = "functional", icon = "📜",
      flavor = "传说级商业合同，签了就是赚",
      effects = { salaryReduction = 0.30, matchPower = 8, allRevenueBonus = 0.08 } },

    -- ═══════════ 战队装备 ═══════════
    { id = "old_jersey",     name = "旧队服",            tier = 1, category = "teamgear", icon = "👕",
      flavor = "上个赛季剩下的，有点旧但能穿",
      effects = { matchPower = 1 } },
    { id = "wrist_guard",    name = "护腕",              tier = 1, category = "teamgear", icon = "🦾",
      flavor = "防腱鞘炎必备",
      effects = { trainBonus = 0.04 } },
    { id = "gaming_cushion", name = "电竞坐垫",          tier = 2, category = "teamgear", icon = "🪑",
      flavor = "久坐不累的记忆棉坐垫",
      effects = { moodDecayReduction = 0.06 } },
    { id = "noise_cancel_hp", name = "降噪耳机(翻新)",  tier = 3, category = "teamgear", icon = "🎧",
      flavor = "翻新的专业电竞耳机，隔音效果一流",
      effects = { matchPower = 5, trainBonus = 0.08 } },
    { id = "custom_jersey",  name = "定制队服套装",      tier = 3, category = "teamgear", icon = "👔",
      flavor = "带赞助商Logo的正式队服，穿上就是范儿",
      effects = { matchPower = 4, repBonus = 0.05 } },
    { id = "tac_comm",       name = "战术通讯系统",      tier = 4, category = "teamgear", icon = "📻",
      flavor = "专业的队内通讯设备，指挥如臂使指",
      effects = { matchPower = 8, microEventBonus = 0.10 } },
    { id = "champion_boots", name = "冠军战靴",          tier = 5, category = "teamgear", icon = "👟",
      flavor = "据说穿过它的队伍都夺冠了",
      effects = { matchPower = 15, moodFloor = 50, moodDecayReduction = 0.10 } },

    -- ═══════════ 幸运物 ═══════════
    { id = "lottery_scrap",  name = "彩票残片",          tier = 1, category = "charm", icon = "🎫",
      flavor = "刮了一半的彩票，说不定还有奖",
      effects = { dailyMoneyBonus = 8 } },
    { id = "lucky_coin",     name = "幸运硬币",          tier = 2, category = "charm", icon = "🪙",
      flavor = "磨得发亮的旧硬币，据说能带来好运",
      effects = { goldenHourBonus = 0.08, dailyMoneyBonus = 15 } },
    { id = "lizard_charm",   name = "蜥蜴皮护符",        tier = 3, category = "charm", icon = "🦎",
      flavor = "当地巫医祝福过的，微微发热",
      effects = { microEventBonus = 0.20, goldenHourBonus = 0.05 } },
    { id = "gold_nugget",    name = "金矿石挂件",        tier = 4, category = "charm", icon = "💎",
      flavor = "阿散蒂金矿区的原矿，沉甸甸的",
      effects = { dailyMoneyBonus = 60, allRevenueBonus = 0.05 } },
    { id = "grandma_amulet", name = "祖母的护身符",      tier = 5, category = "charm", icon = "🧿",
      flavor = "家族世代相传的神秘护身符，温暖而安心",
      effects = { allRevenueBonus = 0.12, dailyMoneyBonus = 100, goldenHourBonus = 0.10 } },

    -- ═══════════ 员工卡（Batch 4）═══════════
    -- 抽到员工卡后可解锁对应NPC特殊互动/永久加成
    { id = "card_ada",       name = "Ada的名片",          tier = 2, category = "staffcard", icon = "👩‍💻",
      flavor = "网吧常客Ada留下的名片，背面写着：'有事找我'",
      effects = { trainBonus = 0.06, dailyMoneyBonus = 10 } },
    { id = "card_mama_b",    name = "Mama B的食谱",       tier = 2, category = "staffcard", icon = "🍲",
      flavor = "Mama B的秘制鸡肉酱食谱，说是能提升士气",
      effects = { moodDecayReduction = 0.06, repBonus = 0.05 } },
    { id = "card_dj_pulse",  name = "DJ Pulse的混音带",   tier = 3, category = "staffcard", icon = "🎧",
      flavor = "本地最火DJ的独家混音，放了客人不想走",
      effects = { trafficBonus = 0.06, moodDecayReduction = 0.04 } },
    { id = "card_captain_zero", name = "Captain Zero的战术本", tier = 3, category = "staffcard", icon = "📋",
      flavor = "退役职业选手的手写笔记，满是圈圈画画",
      effects = { matchPower = 4, trainBonus = 0.08 } },
    { id = "card_juju",      name = "Juju的符咒袋",       tier = 4, category = "staffcard", icon = "🧙",
      flavor = "街头占卜师Juju送的小布袋，里面装着什么不敢看",
      effects = { goldenHourBonus = 0.10, microEventBonus = 0.15 } },
    { id = "card_fixer",     name = "Fixer的工具箱",      tier = 3, category = "staffcard", icon = "🔧",
      flavor = "万能维修工Fixer总能把坏东西变好",
      effects = { equipDecayReduction = 0.08, dailyMoneyBonus = 20 } },
    { id = "card_big_chief", name = "Big Chief的推荐信",  tier = 4, category = "staffcard", icon = "👑",
      flavor = "当地酋长的亲笔信，盖着金印",
      effects = { repBonus = 0.15, allRevenueBonus = 0.04 } },
    { id = "card_network",   name = "全明星员工合照",     tier = 5, category = "staffcard", icon = "📸",
      flavor = "所有员工的合影——这张照片本身就是传奇",
      effects = { allRevenueBonus = 0.10, matchPower = 6, trainBonus = 0.10 } },

    -- ═══════════ 城市碎片（Batch 5）═══════════
    -- 收集城市碎片可降低对应城市转生门槛（30-50%名誉减免）
    { id = "frag_lagos",     name = "拉各斯商铺租约",     tier = 3, category = "cityfrag", icon = "🏙️",
      flavor = "黄色铁皮箱里翻出来的旧租约，竟然还有效",
      effects = { cityId = "lagos", thresholdReduction = 0.30 } },
    { id = "frag_nairobi",   name = "内罗毕孵化器邀请函", tier = 3, category = "cityfrag", icon = "🌆",
      flavor = "一封来自iHub的邀请信，科技创业的入场券",
      effects = { cityId = "nairobi", thresholdReduction = 0.30 } },
    { id = "frag_accra",     name = "阿克拉大学推荐信",   tier = 3, category = "cityfrag", icon = "🎓",
      flavor = "教授亲笔签名的推荐信，文化之都的敲门砖",
      effects = { cityId = "accra", thresholdReduction = 0.30 } },
    { id = "frag_dakar",     name = "达喀尔港口通行证",   tier = 4, category = "cityfrag", icon = "🌊",
      flavor = "盖着海关蓝章的特许证，可以自由出入港口区",
      effects = { cityId = "dakar", thresholdReduction = 0.35 } },
    { id = "frag_capetown",  name = "开普敦电竞联盟会员卡", tier = 4, category = "cityfrag", icon = "⛰️",
      flavor = "ESL非洲分部的铂金会员，上面有你的名字",
      effects = { cityId = "capetown", thresholdReduction = 0.40 } },
    { id = "frag_kinshasa",  name = "金沙萨音乐节VIP手环", tier = 5, category = "cityfrag", icon = "🥁",
      flavor = "传说中的金沙萨全球音乐节终身通行证，仅发行7枚",
      effects = { cityId = "kinshasa", thresholdReduction = 0.50 } },

    -- ═══════════ 城市专属物品（Batch 6）═══════════
    -- cityExclusive 字段标记只能在对应城市抽到
    -- 拉各斯 — 商业之都
    { id = "lagos_hustle_charm", name = "拉各斯街头护身符", tier = 2, category = "charm", icon = "🔔",
      flavor = "车水马龙的拉各斯街头，人人脖子上都挂一个",
      effects = { dailyMoneyBonus = 25, trafficBonus = 0.04 }, cityExclusive = "lagos" },
    { id = "lagos_trade_license", name = "奥巴贸易许可证", tier = 3, category = "functional", icon = "📃",
      flavor = "拉各斯商人会发的金字执照，有了它进货便宜三成",
      effects = { allRevenueBonus = 0.06, dailyMoneyBonus = 35 }, cityExclusive = "lagos" },
    { id = "lagos_neon_sign", name = "维多利亚岛霓虹灯牌", tier = 4, category = "decoration", icon = "🌃",
      flavor = "从关门的夜总会拆下来的巨型灯牌，半条街都能看到",
      effects = { trafficBonus = 0.10, repBonus = 0.12 }, cityExclusive = "lagos" },

    -- 内罗毕 — 科技之都
    { id = "nairobi_fiber_cable", name = "iHub光纤直连线", tier = 2, category = "equipment", icon = "🔗",
      flavor = "从科技园区直接拉的光纤，延迟低到离谱",
      effects = { trafficBonus = 0.05, equipDecayReduction = 0.03 }, cityExclusive = "nairobi" },
    { id = "nairobi_startup_pass", name = "硅谷沙鸟加速器Pass", tier = 3, category = "functional", icon = "🚀",
      flavor = "M-Pesa创始人签名的创业加速通行证",
      effects = { trainBonus = 0.12, dailyMoneyBonus = 20 }, cityExclusive = "nairobi" },
    { id = "nairobi_solar_chip", name = "太阳能AI芯片", tier = 4, category = "equipment", icon = "☀️",
      flavor = "内罗毕清洁能源实验室的试验品，能自动优化电力分配",
      effects = { equipDecayReduction = 0.10, dailyMoneyBonus = 40, allRevenueBonus = 0.04 }, cityExclusive = "nairobi" },

    -- 阿克拉 — 文化教育之都
    { id = "accra_textbook", name = "加纳大学电竞教材", tier = 2, category = "functional", icon = "📚",
      flavor = "全非洲第一本正式的电竞理论教材",
      effects = { trainBonus = 0.08, repBonus = 0.05 }, cityExclusive = "accra" },
    { id = "accra_kente_jersey", name = "Kente战队制服", tier = 3, category = "teamgear", icon = "👘",
      flavor = "用传统Kente布料定制的电竞队服，文化与竞技的融合",
      effects = { matchPower = 5, repBonus = 0.10 }, cityExclusive = "accra" },
    { id = "accra_wisdom_drum", name = "阿散蒂智慧之鼓", tier = 5, category = "decoration", icon = "🪘",
      flavor = "阿散蒂王室赐予的黄金鼓，据说能传递胜利的节奏",
      effects = { allRevenueBonus = 0.08, repBonus = 0.18, trainBonus = 0.10 }, cityExclusive = "accra" },

    -- 达喀尔 — 港口贸易之都
    { id = "dakar_shipping_crate", name = "港口走私集装箱", tier = 2, category = "equipment", icon = "📦",
      flavor = "海关'不小心'放行的一箱二手显卡",
      effects = { equipDecayReduction = 0.05, dailyMoneyBonus = 18 }, cityExclusive = "dakar" },
    { id = "dakar_wrestling_belt", name = "摔跤冠军腰带", tier = 3, category = "charm", icon = "🤼",
      flavor = "达喀尔传统摔跤赛冠军的铜腰带，力量的象征",
      effects = { matchPower = 6, moodDecayReduction = 0.05 }, cityExclusive = "dakar" },
    { id = "dakar_gold_scales", name = "港口黄金秤", tier = 4, category = "functional", icon = "⚖️",
      flavor = "精密到0.01克的走私级金秤，做黄金生意必备",
      effects = { goldTradeBonus = 0.20, dailyMoneyBonus = 50 }, cityExclusive = "dakar" },

    -- 开普敦 — 电竞之都
    { id = "capetown_esports_chair", name = "ESL赛事级电竞椅", tier = 3, category = "teamgear", icon = "🪑",
      flavor = "和世界赛决赛用的是同一型号，坐上去就有冠军气质",
      effects = { matchPower = 6, moodDecayReduction = 0.08 }, cityExclusive = "capetown" },
    { id = "capetown_broadcast_kit", name = "职业转播设备套装", tier = 4, category = "functional", icon = "📡",
      flavor = "专业的4K转播摄像头+导播台，直播画质拉满",
      effects = { trafficBonus = 0.08, repBonus = 0.12, allRevenueBonus = 0.05 }, cityExclusive = "capetown" },
    { id = "capetown_cape_trophy", name = "好望角冠军杯", tier = 5, category = "decoration", icon = "🏆",
      flavor = "非洲电竞史上最负盛名的奖杯，刻着每届冠军的名字",
      effects = { matchPower = 12, allRevenueBonus = 0.10, repBonus = 0.15 }, cityExclusive = "capetown" },

    -- 金沙萨 — 音乐艺术之都
    { id = "kinshasa_rumba_vinyl", name = "刚果伦巴黑胶唱片", tier = 2, category = "decoration", icon = "💿",
      flavor = "六十年代的珍贵录音，放出来整条街都在跳舞",
      effects = { moodDecayReduction = 0.06, repBonus = 0.06 }, cityExclusive = "kinshasa" },
    { id = "kinshasa_sapeur_suit", name = "萨普尔绅士三件套", tier = 3, category = "charm", icon = "🎩",
      flavor = "金沙萨优雅绅士的标志，穿上它你就是最靓的仔",
      effects = { repBonus = 0.12, dailyMoneyBonus = 30 }, cityExclusive = "kinshasa" },
    { id = "kinshasa_studio_mixer", name = "传奇录音室调音台", tier = 4, category = "equipment", icon = "🎛️",
      flavor = "Papa Wemba用过的调音台！全非洲只有三台",
      effects = { moodDecayReduction = 0.12, trafficBonus = 0.08, allRevenueBonus = 0.06 }, cityExclusive = "kinshasa" },
    { id = "kinshasa_golden_sax", name = "黄金萨克斯风", tier = 5, category = "charm", icon = "🎷",
      flavor = "纯金打造的萨克斯，每次吹响都像在印钞票",
      effects = { allRevenueBonus = 0.15, dailyMoneyBonus = 80, moodDecayReduction = 0.10 }, cityExclusive = "kinshasa" },
}

-- ============================================================
-- 城市经济系统 (Batch 6)
-- ============================================================

-- 城市生活成本系数：影响升级费用、抽卡费用、日常维护
MarketData.CITY_COST_MULTIPLIER = {
    wakandaville = 1.0,   -- 基准
    lagos        = 1.4,   -- 大城市物价高
    nairobi      = 1.3,   -- 科技城消费中上
    accra        = 1.2,   -- 文化城消费适中
    dakar        = 1.35,  -- 港口贸易城
    capetown     = 1.6,   -- 电竞之都，消费最高
    kinshasa     = 1.5,   -- 终极城市
}

-- 城市专属设施（大额消费坑，每城市一个独特投资项目）
-- 每级花费递增，提供独特加成
MarketData.CITY_FACILITIES = {
    lagos = {
        id = "commercial_plaza", name = "商业广场",
        icon = "🏬", maxLevel = 5,
        desc = "在拉各斯最繁华地段租下商铺，客流量暴增",
        costs  = { 2000, 5000, 12000, 25000, 50000 },
        effects = {
            { trafficBonus = 0.15, dailyMoneyBonus = 40 },
            { trafficBonus = 0.25, dailyMoneyBonus = 80 },
            { trafficBonus = 0.35, dailyMoneyBonus = 130, repBonus = 0.05 },
            { trafficBonus = 0.45, dailyMoneyBonus = 200, repBonus = 0.10 },
            { trafficBonus = 0.60, dailyMoneyBonus = 300, repBonus = 0.15, allRevenueBonus = 0.05 },
        },
    },
    nairobi = {
        id = "tech_incubator", name = "科技孵化器",
        icon = "🔬", maxLevel = 5,
        desc = "接入内罗毕科技生态，升级更快、训练更强",
        costs  = { 1800, 4500, 10000, 22000, 45000 },
        effects = {
            { trainBonus = 0.15, equipDecayReduction = 0.05 },
            { trainBonus = 0.25, equipDecayReduction = 0.08 },
            { trainBonus = 0.35, equipDecayReduction = 0.10, dailyMoneyBonus = 50 },
            { trainBonus = 0.45, equipDecayReduction = 0.12, dailyMoneyBonus = 100 },
            { trainBonus = 0.60, equipDecayReduction = 0.15, dailyMoneyBonus = 150, allRevenueBonus = 0.05 },
        },
    },
    accra = {
        id = "university_partnership", name = "大学合作项目",
        icon = "🎓", maxLevel = 5,
        desc = "与加纳大学建立产学研合作，声望飞升",
        costs  = { 1500, 4000, 9000, 20000, 40000 },
        effects = {
            { repBonus = 0.20, trainBonus = 0.08 },
            { repBonus = 0.30, trainBonus = 0.12 },
            { repBonus = 0.40, trainBonus = 0.15, dailyMoneyBonus = 40 },
            { repBonus = 0.50, trainBonus = 0.20, dailyMoneyBonus = 80 },
            { repBonus = 0.65, trainBonus = 0.25, dailyMoneyBonus = 120, allRevenueBonus = 0.05 },
        },
    },
    dakar = {
        id = "port_import_office", name = "港口进出口办公室",
        icon = "🚢", maxLevel = 5,
        desc = "在港口设立办公室，控制设备进口渠道",
        costs  = { 2200, 5500, 13000, 28000, 55000 },
        effects = {
            { equipDecayReduction = 0.08, goldTradeBonus = 0.10 },
            { equipDecayReduction = 0.12, goldTradeBonus = 0.15, dailyMoneyBonus = 50 },
            { equipDecayReduction = 0.15, goldTradeBonus = 0.20, dailyMoneyBonus = 100 },
            { equipDecayReduction = 0.18, goldTradeBonus = 0.30, dailyMoneyBonus = 160 },
            { equipDecayReduction = 0.20, goldTradeBonus = 0.40, dailyMoneyBonus = 250, allRevenueBonus = 0.06 },
        },
    },
    capetown = {
        id = "esports_arena", name = "电竞竞技场",
        icon = "🏟️", maxLevel = 5,
        desc = "建造专业电竞场馆，赛事奖金和声望双丰收",
        costs  = { 3000, 8000, 18000, 40000, 80000 },
        effects = {
            { matchPower = 8, repBonus = 0.10 },
            { matchPower = 15, repBonus = 0.15, dailyMoneyBonus = 60 },
            { matchPower = 22, repBonus = 0.20, dailyMoneyBonus = 120 },
            { matchPower = 30, repBonus = 0.25, dailyMoneyBonus = 200 },
            { matchPower = 40, repBonus = 0.30, dailyMoneyBonus = 300, allRevenueBonus = 0.08 },
        },
    },
    kinshasa = {
        id = "music_studio", name = "传奇音乐工作室",
        icon = "🎵", maxLevel = 5,
        desc = "在音乐之城建录音棚，队员心情和网吧氛围拉满",
        costs  = { 2500, 6500, 15000, 35000, 70000 },
        effects = {
            { moodDecayReduction = 0.12, repBonus = 0.08 },
            { moodDecayReduction = 0.18, repBonus = 0.12, trafficBonus = 0.05 },
            { moodDecayReduction = 0.25, repBonus = 0.18, trafficBonus = 0.08 },
            { moodDecayReduction = 0.30, repBonus = 0.25, trafficBonus = 0.12, dailyMoneyBonus = 100 },
            { moodDecayReduction = 0.35, repBonus = 0.30, trafficBonus = 0.15, dailyMoneyBonus = 200, allRevenueBonus = 0.08 },
        },
    },
}

-- 城市每日运营税（固定日常花费，按城市和经营天数递增）
MarketData.CITY_DAILY_TAX = {
    wakandaville = 0,      -- 起始城市无税
    lagos        = 30,     -- 商业执照费
    nairobi      = 25,     -- 科技园管理费
    accra        = 20,     -- 文化区维护费
    dakar        = 35,     -- 港口通行费
    capetown     = 50,     -- 物业费最贵
    kinshasa     = 40,     -- 城市运营费
}

--- 获取当前城市的生活成本倍率
---@param cityId string|nil
---@return number multiplier
function MarketData.GetCityCostMultiplier(cityId)
    local city = cityId or (playerData_ and playerData_.currentCity) or "wakandaville"
    return MarketData.CITY_COST_MULTIPLIER[city] or 1.0
end

--- 获取当前城市的专属设施数据
---@param cityId string|nil
---@return table|nil facilityDef
function MarketData.GetCityFacility(cityId)
    local city = cityId or (playerData_ and playerData_.currentCity) or "wakandaville"
    return MarketData.CITY_FACILITIES[city]
end

--- 获取当前城市的专属设施当前等级
---@param cityId string|nil
---@return number level (0 = 未建造)
function MarketData.GetCityFacilityLevel(cityId)
    local city = cityId or (playerData_ and playerData_.currentCity) or "wakandaville"
    if not playerData_ or not playerData_.cityFacilities then return 0 end
    return playerData_.cityFacilities[city] or 0
end

--- 获取城市专属设施的当前效果
---@param cityId string|nil
---@return table effects
function MarketData.GetCityFacilityEffects(cityId)
    local city = cityId or (playerData_ and playerData_.currentCity) or "wakandaville"
    local facility = MarketData.CITY_FACILITIES[city]
    if not facility then return {} end
    local level = MarketData.GetCityFacilityLevel(city)
    if level <= 0 then return {} end
    return facility.effects[level] or {}
end

--- 获取每日城市运营税
---@param cityId string|nil
---@return number tax
function MarketData.GetDailyTax(cityId)
    local city = cityId or (playerData_ and playerData_.currentCity) or "wakandaville"
    local baseTax = MarketData.CITY_DAILY_TAX[city] or 0
    -- 税收随经营天数缓慢递增（每10天+10%，上限翻倍）
    local day = (playerData_ and playerData_.day) or 1
    local dayFactor = math.min(2.0, 1.0 + math.floor(day / 10) * 0.1)
    return math.floor(baseTax * dayFactor)
end

-- 按品质分组索引（加速抽卡查找）
MarketData.ITEMS_BY_TIER = {}
for tier = 1, 5 do
    MarketData.ITEMS_BY_TIER[tier] = {}
end
for _, item in ipairs(MarketData.ITEMS) do
    table.insert(MarketData.ITEMS_BY_TIER[item.tier], item)
end

-- 按ID索引
MarketData.ITEMS_BY_ID = {}
for _, item in ipairs(MarketData.ITEMS) do
    MarketData.ITEMS_BY_ID[item.id] = item
end

-- 分类名
MarketData.CATEGORY_NAMES = {
    equipment  = "设备配件",
    decoration = "装饰摆件",
    functional = "功能道具",
    teamgear   = "战队装备",
    charm      = "幸运物",
    staffcard  = "员工卡",
    cityfrag   = "城市碎片",
}

-- ============================================================
-- P2: 装备激活效应（跨模块条件触发额外加成）
-- 结构: { itemId, condDesc, checkFn, bonusEffects }
-- checkFn(playerData) → bool: 条件是否满足
-- bonusEffects: 额外叠加到 effects 上
-- ============================================================
MarketData.ACTIVATE_BONUSES = {
    -- 翻新机械键盘: 团队≥2人时，训练加成翻倍
    { itemId = "mech_keyboard",
      condDesc = "团队≥2人",
      check = function(pd) return teamMembers_ and #teamMembers_ >= 2 end,
      bonus = { trainBonus = 0.10 } },
    -- LED氛围灯带: 装饰升级≥3时，额外声望+流量
    { itemId = "led_strip",
      condDesc = "装饰≥Lv.3",
      check = function(pd) return (pd.decoLevel or 0) >= 3 end,
      bonus = { repBonus = 0.06, trafficBonus = 0.03 } },
    -- 赛事组织手册: 赢过≥3场锦标赛时，比赛费用再降
    { itemId = "event_handbook",
      condDesc = "锦标赛胜≥3场",
      check = function(pd) return (pd.tournamentWins or 0) >= 3 end,
      bonus = { matchCostReduction = 0.10, matchPower = 3 } },
    -- 训练AI分析软件: 自动化等级≥2时解锁额外AP
    { itemId = "train_ai",
      condDesc = "自动化≥Lv.2",
      check = function(pd) return (pd.autoLevel or 0) >= 2 end,
      bonus = { apBonus = 1 } },
    -- 降噪耳机(翻新): 网速升级≥3时，比赛力大增
    { itemId = "noise_cancel_hp",
      condDesc = "网速≥Lv.3",
      check = function(pd) return (pd.netSpeed or 0) >= 3 end,
      bonus = { matchPower = 3 } },
    -- 黄金经理人合同: 咖啡评级≥4星时全面增强
    { itemId = "golden_contract",
      condDesc = "咖啡厅≥4星",
      check = function(pd)
          local ok, r = pcall(GetCafeRating)
          return ok and r and r.star >= 4
      end,
      bonus = { allRevenueBonus = 0.05, matchPower = 5 } },
    -- 冠军战靴: 声望≥300时，比赛力额外+8
    { itemId = "champion_boots",
      condDesc = "声望≥300",
      check = function(pd) return (pd.reputation or 0) >= 300 end,
      bonus = { matchPower = 8 } },
    -- 祖母的护身符: 已转生过≥1次时，全收益再+8%
    { itemId = "grandma_amulet",
      condDesc = "已转生≥1次",
      check = function(pd) return (pd.prestigeCount or 0) >= 1 end,
      bonus = { allRevenueBonus = 0.08 } },
}

-- 按 itemId 索引激活效应
MarketData.ACTIVATE_BY_ID = {}
for _, ab in ipairs(MarketData.ACTIVATE_BONUSES) do
    MarketData.ACTIVATE_BY_ID[ab.itemId] = ab
end

return MarketData
