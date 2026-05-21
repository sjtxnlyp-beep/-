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
}

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
}

return MarketData
