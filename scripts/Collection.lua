---@diagnostic disable: undefined-global
-- ============================================================================
-- Collection.lua — 图鉴收集系统
-- 被动记录玩家经历的所有人、事、物，提供长期目标与阶段奖励
-- 专家修正：前30天保证40%+可解锁、阶段奖励含唯一性内容
-- ============================================================================

local Collection = {}

-- ============================================================================
-- 类别定义
-- ============================================================================
Collection.CATEGORIES = {
    { id = "characters", name = "角色图鉴", icon = "👤", desc = "遇见的所有NPC和队员" },
    { id = "events",     name = "事件图鉴", icon = "📖", desc = "经历过的事件和危机" },
    { id = "equipment",  name = "装备图鉴", icon = "🎮", desc = "获得过的所有装备" },
    { id = "moments",    name = "高光时刻", icon = "⭐", desc = "特殊成就和难忘瞬间" },
    { id = "lore",       name = "非洲百科", icon = "🌍", desc = "解锁的文化知识和民俗" },
    { id = "cafe",       name = "网吧变迁", icon = "🏠", desc = "网吧的每个发展阶段" },
}

-- ============================================================================
-- 图鉴条目（含大量低门槛1星条目确保前期40%+可解锁）
-- ============================================================================
Collection.ITEMS = {
    -- ═══ 角色图鉴 (16条) ═══
    { id = "chr_first_member", category = "characters", name = "第一位队员", icon = "🤝", stars = 1,
      desc = "招募了你的第一位战队成员", check = function() return #teamMembers_ >= 1 end },
    { id = "chr_kofi", category = "characters", name = "Kofi·闪电骑手", icon = "⚡", stars = 1,
      desc = "每天骑2小时自行车来网吧的少年", check = function() return HasMember and HasMember("Kofi") end },
    { id = "chr_bigjoe", category = "characters", name = "Big Joe·铁壁", icon = "🛡️", stars = 1,
      desc = "200斤前保镖，灵巧的胖子", check = function() return HasMember and HasMember("Big Joe") end },
    { id = "chr_grace", category = "characters", name = "Grace·暗夜玫瑰", icon = "🌹", stars = 1,
      desc = "白天唱诗班，晚上偷偷来跑刀", check = function() return HasMember and HasMember("Grace") end },
    { id = "chr_snake", category = "characters", name = "Snake·毒蛇", icon = "🐍", stars = 2,
      desc = "街头之王，游戏嗅觉惊人但脾气火爆", check = function() return HasMember and HasMember("Snake") end },
    { id = "chr_mamab", category = "characters", name = "Mama B·隐藏狙神", icon = "🍗", stars = 2,
      desc = "门口卖烤鸡的40岁大婶竟有恐怖狙击天赋", check = function() return HasMember and HasMember("Mama B") end },
    { id = "chr_prince", category = "characters", name = "Prince·酋长之子", icon = "👑", stars = 2,
      desc = "想通过电竞证明自己的贵族少年", check = function() return HasMember and HasMember("Prince") end },
    { id = "chr_xiaoxue", category = "characters", name = "小雪·支教老师", icon = "❄️", stars = 2,
      desc = "从四川来的支教志愿者", check = function() return HasMember and HasMember("小雪") end },
    { id = "chr_thunder", category = "characters", name = "Thunder·退役飞人", icon = "🏃", stars = 2,
      desc = "退役短跑运动员，0.1秒出枪", check = function() return HasMember and HasMember("Thunder") end },
    { id = "chr_full_team", category = "characters", name = "满员战队", icon = "👥", stars = 2,
      desc = "战队达到5人满编", check = function() return #teamMembers_ >= 5 end },
    { id = "chr_3_members", category = "characters", name = "三人成众", icon = "🎯", stars = 1,
      desc = "战队达到3人", check = function() return #teamMembers_ >= 3 end },
    { id = "chr_high_mood", category = "characters", name = "快乐大家庭", icon = "😄", stars = 1,
      desc = "全队平均心情超过80", check = function()
          if #teamMembers_ == 0 then return false end
          local sum = 0; for _, m in ipairs(teamMembers_) do sum = sum + (m.mood or 50) end
          return sum / #teamMembers_ > 80
      end },
    { id = "chr_skill_50", category = "characters", name = "初具实力", icon = "📈", stars = 1,
      desc = "任一队员技能达到50", check = function()
          for _, m in ipairs(teamMembers_) do if (m.skill or 0) >= 50 then return true end end
          return false
      end },
    { id = "chr_skill_100", category = "characters", name = "百炼成钢", icon = "💪", stars = 3,
      desc = "任一队员技能达到100", check = function()
          for _, m in ipairs(teamMembers_) do if (m.skill or 0) >= 100 then return true end end
          return false
      end },
    { id = "chr_dismissed", category = "characters", name = "忍痛割爱", icon = "💔", stars = 1,
      desc = "解雇过一名队员", check = function() return playerData_.hasDismissed end },
    { id = "chr_all_special", category = "characters", name = "全明星阵容", icon = "🌟", stars = 3,
      desc = "招募过所有特殊角色", check = function() return (playerData_.recruitedSpecialCount or 0) >= 8 end },

    -- ═══ 事件图鉴 (18条) ═══
    { id = "evt_first_event", category = "events", name = "初遇变故", icon = "❗", stars = 1,
      desc = "经历第一次随机事件", check = function() return (playerData_.totalEventsTriggered or 0) >= 1 end },
    { id = "evt_5_events", category = "events", name = "见怪不怪", icon = "📋", stars = 1,
      desc = "经历过5次随机事件", check = function() return (playerData_.totalEventsTriggered or 0) >= 5 end },
    { id = "evt_10_events", category = "events", name = "老江湖", icon = "🎩", stars = 2,
      desc = "经历过10次随机事件", check = function() return (playerData_.totalEventsTriggered or 0) >= 10 end },
    { id = "evt_first_blackout", category = "events", name = "第一次停电", icon = "🌑", stars = 1,
      desc = "经历了人生第一次网吧停电", check = function() return (playerData_.blackoutCount or 0) >= 1 end },
    { id = "evt_choice_made", category = "events", name = "抉择时刻", icon = "🔀", stars = 1,
      desc = "第一次在事件中做出选择", check = function() return (playerData_.choicesMade or 0) >= 1 end },
    { id = "evt_10_choices", category = "events", name = "决策达人", icon = "🧠", stars = 2,
      desc = "累计做出10次事件选择", check = function() return (playerData_.choicesMade or 0) >= 10 end },
    { id = "evt_micro_5", category = "events", name = "小事达人", icon = "☕", stars = 1,
      desc = "处理5次零AP小事件", check = function() return (playerData_.microEventsHandled or 0) >= 5 end },
    { id = "evt_micro_20", category = "events", name = "生活管家", icon = "🏡", stars = 2,
      desc = "处理20次零AP小事件", check = function() return (playerData_.microEventsHandled or 0) >= 20 end },
    { id = "evt_crisis_first", category = "events", name = "危机初体验", icon = "⚠️", stars = 2,
      desc = "完成第一条危机链", check = function()
          local c = playerData_.crisisState and playerData_.crisisState.completed or {}
          for _ in pairs(c) do return true end; return false
      end },
    { id = "evt_crisis_3", category = "events", name = "危机老手", icon = "🛡️", stars = 3,
      desc = "完成3条不同的危机链", check = function()
          local c = playerData_.crisisState and playerData_.crisisState.completed or {}
          local n = 0; for _ in pairs(c) do n = n + 1 end; return n >= 3
      end },
    { id = "evt_climax_first", category = "events", name = "高潮日初遇", icon = "🎆", stars = 1,
      desc = "经历第一个高潮日", check = function()
          local h = playerData_.climaxState and playerData_.climaxState.history or {}
          for _ in pairs(h) do return true end; return false
      end },
    { id = "evt_climax_5", category = "events", name = "高潮日大师", icon = "🎯", stars = 3,
      desc = "经历5种不同的高潮日", check = function()
          local h = playerData_.climaxState and playerData_.climaxState.history or {}
          local n = 0; for _ in pairs(h) do n = n + 1 end; return n >= 5
      end },
    { id = "evt_govt_check", category = "events", name = "应付检查", icon = "📋", stars = 1,
      desc = "经历过政府检查事件", check = function() return playerData_.govtCheckDone end },
    { id = "evt_rival_encounter", category = "events", name = "宿敌相遇", icon = "🦊", stars = 1,
      desc = "第一次与Victor产生冲突", check = function() return playerData_.rivalEncountered end },
    { id = "evt_donation", category = "events", name = "慈善之心", icon = "💝", stars = 1,
      desc = "在事件中选择了捐赠/帮助他人", check = function() return (playerData_.karma or 0) >= 5 end },
    { id = "evt_good_karma", category = "events", name = "善有善报", icon = "☀️", stars = 2,
      desc = "道义值达到15", check = function() return (playerData_.karma or 0) >= 15 end },
    { id = "evt_bad_karma", category = "events", name = "灰色地带", icon = "🌘", stars = 2,
      desc = "道义值为负数", check = function() return (playerData_.karma or 0) < 0 end },
    { id = "evt_strategy_10", category = "events", name = "策略大师", icon = "♟️", stars = 2,
      desc = "使用过10次每日策略卡", check = function() return (playerData_.strategyUsedCount or 0) >= 10 end },

    -- ═══ 装备图鉴 (14条) ═══
    { id = "eqp_first_upgrade", category = "equipment", name = "第一次升级", icon = "⬆️", stars = 1,
      desc = "完成第一次网吧升级", check = function() return (playerData_.computers or 1) > 1 or (playerData_.chairLevel or 0) > 0 end },
    { id = "eqp_5pc", category = "equipment", name = "五台战机", icon = "🖥️", stars = 1,
      desc = "网吧电脑数达到5台", check = function() return (playerData_.computers or 1) >= 5 end },
    { id = "eqp_10pc", category = "equipment", name = "十台连坐", icon = "💻", stars = 2,
      desc = "网吧电脑数达到10台", check = function() return (playerData_.computers or 1) >= 10 end },
    { id = "eqp_generator", category = "equipment", name = "电力守护者", icon = "🔋", stars = 1,
      desc = "购买了第一台发电机", check = function() return (playerData_.generatorLevel or 0) >= 1 end },
    { id = "eqp_gen_lv3", category = "equipment", name = "电力帝国", icon = "⚡", stars = 3,
      desc = "发电机升至最高级", check = function() return (playerData_.generatorLevel or 0) >= 3 end },
    { id = "eqp_ac", category = "equipment", name = "清凉一夏", icon = "❄️", stars = 1,
      desc = "安装了空调", check = function() return (playerData_.acLevel or 0) >= 1 end },
    { id = "eqp_chair", category = "equipment", name = "电竞宝座", icon = "🪑", stars = 1,
      desc = "升级了座椅", check = function() return (playerData_.chairLevel or 0) >= 1 end },
    { id = "eqp_deco", category = "equipment", name = "装饰大师", icon = "🎨", stars = 1,
      desc = "网吧装饰等级达到2", check = function() return (playerData_.decoLevel or 0) >= 2 end },
    { id = "eqp_solar", category = "equipment", name = "太阳能先锋", icon = "☀️", stars = 2,
      desc = "安装了太阳能板", check = function() return (playerData_.solarLevel or 0) >= 1 end },
    { id = "eqp_road", category = "equipment", name = "要想富先修路", icon = "🛣️", stars = 1,
      desc = "修建了社区道路", check = function() return (playerData_.roadLevel or 0) >= 1 end },
    { id = "eqp_well", category = "equipment", name = "饮水思源", icon = "🚰", stars = 1,
      desc = "修建了社区水井", check = function() return (playerData_.wellLevel or 0) >= 1 end },
    { id = "eqp_jukebox", category = "equipment", name = "音乐盒子", icon = "🎵", stars = 1,
      desc = "购买了点唱机", check = function() return (playerData_.jukeboxLevel or 0) >= 1 end },
    { id = "eqp_market_buy", category = "equipment", name = "集市常客", icon = "🏪", stars = 1,
      desc = "在二手市场购买过物品", check = function() return (playerData_.marketPurchases or 0) >= 1 end },
    { id = "eqp_5star_item", category = "equipment", name = "天命之人", icon = "🌟", stars = 3,
      desc = "获得第一件五星装备", check = function()
          if not playerData_.marketInventory then return false end
          for _, item in ipairs(playerData_.marketInventory) do
            if (item.stars or item.tier or 0) >= 5 then return true end
          end; return false
      end },

    -- ═══ 高光时刻 (18条) ═══
    { id = "mom_first_profit", category = "moments", name = "第一桶金", icon = "💰", stars = 1,
      desc = "第一天实现盈利", check = function() return storyTriggered_ and storyTriggered_["milestone_first_profit"] end },
    { id = "mom_1k_money", category = "moments", name = "千元户", icon = "💵", stars = 1,
      desc = "资产突破$1,000", check = function() return storyTriggered_ and storyTriggered_["milestone_1k"] end },
    { id = "mom_5k_money", category = "moments", name = "小有积蓄", icon = "🏦", stars = 2,
      desc = "资产突破$5,000", check = function() return storyTriggered_ and storyTriggered_["milestone_5k"] end },
    { id = "mom_10k_money", category = "moments", name = "万元大户", icon = "🤑", stars = 3,
      desc = "资产突破$10,000", check = function() return storyTriggered_ and storyTriggered_["milestone_10k"] end },
    { id = "mom_first_win", category = "moments", name = "初战告捷", icon = "🏆", stars = 1,
      desc = "赢得第一场比赛", check = function() return (playerData_.matchWins or 0) >= 1 end },
    { id = "mom_5_wins", category = "moments", name = "五连胜", icon = "🔥", stars = 2,
      desc = "累计赢得5场比赛", check = function() return (playerData_.matchWins or 0) >= 5 end },
    { id = "mom_10_wins", category = "moments", name = "十胜将军", icon = "⚔️", stars = 3,
      desc = "累计赢得10场比赛", check = function() return (playerData_.matchWins or 0) >= 10 end },
    { id = "mom_rep_50", category = "moments", name = "街知巷闻", icon = "📢", stars = 1,
      desc = "声望突破50", check = function() return (playerData_.reputation or 0) >= 50 end },
    { id = "mom_rep_200", category = "moments", name = "名声在外", icon = "📰", stars = 2,
      desc = "声望突破200", check = function() return (playerData_.reputation or 0) >= 200 end },
    { id = "mom_rep_500", category = "moments", name = "非洲传奇", icon = "👑", stars = 3,
      desc = "声望突破500", check = function() return (playerData_.reputation or 0) >= 500 end },
    { id = "mom_train_10", category = "moments", name = "训练达人", icon = "🎯", stars = 1,
      desc = "累计训练10次", check = function() return (playerData_.totalTrainSessions or 0) >= 10 end },
    { id = "mom_train_50", category = "moments", name = "刻苦训练", icon = "🏋️", stars = 2,
      desc = "累计训练50次", check = function() return (playerData_.totalTrainSessions or 0) >= 50 end },
    { id = "mom_market_visit", category = "moments", name = "逛街达人", icon = "🛍️", stars = 1,
      desc = "累计逛集市5次", check = function() return (playerData_.questMarketVisit or 0) >= 5 end },
    { id = "mom_survived_broke", category = "moments", name = "绝处逢生", icon = "🆘", stars = 2,
      desc = "资产低于$50后恢复到$500以上", check = function() return playerData_.survivedBroke end },
    { id = "mom_day_30", category = "moments", name = "坚持一月", icon = "📅", stars = 1,
      desc = "经营网吧满30天", check = function() return (playerData_.day or 1) >= 30 end },
    { id = "mom_day_60", category = "moments", name = "两月老兵", icon = "🎖️", stars = 2,
      desc = "经营网吧满60天", check = function() return (playerData_.day or 1) >= 60 end },
    { id = "mom_day_100", category = "moments", name = "百日传奇", icon = "🏅", stars = 3,
      desc = "经营网吧满100天", check = function() return (playerData_.day or 1) >= 100 end },
    { id = "mom_prestige", category = "moments", name = "涅槃重生", icon = "🔄", stars = 3,
      desc = "完成第一次转生", check = function() return (playerData_.prestigeCount or 0) >= 1 end },

    -- ═══ 非洲百科 (14条) ═══
    { id = "lore_first_rumor", category = "lore", name = "街头传闻", icon = "👂", stars = 1,
      desc = "听到第一条街头传闻", check = function() return (playerData_.day or 1) >= 2 end },
    { id = "lore_weather", category = "lore", name = "非洲天气", icon = "🌦️", stars = 1,
      desc = "经历过旱季和雨季描写", check = function() return (playerData_.day or 1) >= 12 end },
    { id = "lore_suya", category = "lore", name = "Suya烤肉", icon = "🍖", stars = 1,
      desc = "了解了Suya烤肉的豪萨族起源", check = function() return (playerData_.day or 1) >= 5 end },
    { id = "lore_afrobeats", category = "lore", name = "Afrobeats", icon = "🎶", stars = 1,
      desc = "听过非洲节拍音乐", check = function() return (playerData_.day or 1) >= 3 end },
    { id = "lore_nepa", category = "lore", name = "NEPA停电文化", icon = "⚡", stars = 1,
      desc = "了解尼日利亚的停电日常", check = function() return (playerData_.blackoutCount or 0) >= 1 end },
    { id = "lore_moto", category = "lore", name = "摩托出租车", icon = "🏍️", stars = 1,
      desc = "见识了非洲的摩托交通文化", check = function() return (playerData_.day or 1) >= 7 end },
    { id = "lore_market_culture", category = "lore", name = "集市经济学", icon = "🏪", stars = 1,
      desc = "体验了非洲集市的讨价还价文化", check = function() return (playerData_.questMarketVisit or 0) >= 1 end },
    { id = "lore_football", category = "lore", name = "非洲杯热潮", icon = "⚽", stars = 1,
      desc = "了解了足球在非洲的地位", check = function() return (playerData_.day or 1) >= 10 end },
    { id = "lore_community", category = "lore", name = "社区纽带", icon = "🤝", stars = 1,
      desc = "修建社区设施帮助邻里", check = function() return (playerData_.roadLevel or 0) >= 1 or (playerData_.wellLevel or 0) >= 1 end },
    { id = "lore_tribe", category = "lore", name = "部落传统", icon = "🎭", stars = 2,
      desc = "了解当地部落文化（装饰面具）", check = function() return (playerData_.decoLevel or 0) >= 2 end },
    { id = "lore_gold", category = "lore", name = "黄金海岸", icon = "🥇", stars = 2,
      desc = "了解西非黄金贸易历史", check = function() return (playerData_.day or 1) >= 25 end },
    { id = "lore_esports_africa", category = "lore", name = "非洲电竞", icon = "🎮", stars = 2,
      desc = "见证非洲电竞发展（声望200+）", check = function() return (playerData_.reputation or 0) >= 200 end },
    { id = "lore_havoc_coin", category = "lore", name = "哈弗币经济", icon = "🪙", stars = 1,
      desc = "了解游戏虚拟货币的地下交易生态", check = function() return (playerData_.havocCoins or 0) >= 100 end },
    { id = "lore_chinese_abroad", category = "lore", name = "华人在非洲", icon = "🇨🇳", stars = 2,
      desc = "结识其他在非洲创业的华人同胞", check = function() return playerData_.metChineseAbroad end },

    -- ═══ 网吧变迁 (16条) ═══
    { id = "cafe_open", category = "cafe", name = "开业大吉", icon = "🎊", stars = 1,
      desc = "网吧正式开业的第一天", check = function() return true end },
    { id = "cafe_first_customer", category = "cafe", name = "第一位客人", icon = "🧑", stars = 1,
      desc = "迎来了第一位顾客", check = function() return (playerData_.day or 1) >= 1 end },
    { id = "cafe_busy_day", category = "cafe", name = "爆满时刻", icon = "🔥", stars = 1,
      desc = "经历了第一次客满", check = function() return playerData_.hadFullHouse end },
    { id = "cafe_3pc", category = "cafe", name = "小有规模", icon = "🖥️", stars = 1,
      desc = "电脑数达到3台", check = function() return (playerData_.computers or 1) >= 3 end },
    { id = "cafe_money_500", category = "cafe", name = "摆脱贫困", icon = "📈", stars = 1,
      desc = "累计资产超过$500", check = function() return (playerData_.money or 0) >= 500 end },
    { id = "cafe_team_formed", category = "cafe", name = "战队成立", icon = "🏴", stars = 1,
      desc = "正式组建了电竞战队", check = function() return #teamMembers_ >= 1 end },
    { id = "cafe_first_match", category = "cafe", name = "首战出征", icon = "⚔️", stars = 1,
      desc = "参加了第一场正式比赛", check = function() return (playerData_.matchesPlayed or 0) >= 1 end },
    { id = "cafe_rival_appears", category = "cafe", name = "劲敌出现", icon = "🦊", stars = 1,
      desc = "Victor在对面开了分店", check = function() return (playerData_.day or 1) >= 1 end },
    { id = "cafe_debt_free", category = "cafe", name = "无债一身轻", icon = "🆓", stars = 1,
      desc = "还清所有债务", check = function() return (playerData_.debt or 0) <= 0 and (playerData_.day or 1) >= 5 end },
    { id = "cafe_automation", category = "cafe", name = "自动化启航", icon = "🤖", stars = 2,
      desc = "解锁第一级自动化", check = function() return (playerData_.automationLevel or 0) >= 1 end },
    { id = "cafe_branch", category = "cafe", name = "连锁启航", icon = "🏪", stars = 3,
      desc = "开出第一家分店", check = function() return playerData_.branches and #playerData_.branches >= 1 end },
    { id = "cafe_gold_decor", category = "cafe", name = "金碧辉煌", icon = "✨", stars = 2,
      desc = "购买了黄金装饰", check = function() return playerData_.goldDecor end },
    { id = "cafe_day_7", category = "cafe", name = "一周年", icon = "📅", stars = 1,
      desc = "网吧经营满7天", check = function() return (playerData_.day or 1) >= 7 end },
    { id = "cafe_day_14", category = "cafe", name = "两周目标", icon = "🗓️", stars = 1,
      desc = "网吧经营满14天", check = function() return (playerData_.day or 1) >= 14 end },
    { id = "cafe_income_200", category = "cafe", name = "日入两百", icon = "💸", stars = 1,
      desc = "单日净收入超过$200", check = function() return (playerData_.lastNetIncome or 0) >= 200 end },
    { id = "cafe_prestige", category = "cafe", name = "帝国重启", icon = "🔄", stars = 3,
      desc = "完成转生开启新城市", check = function() return (playerData_.prestigeCount or 0) >= 1 end },
}

-- ============================================================================
-- 阶段奖励（每个类别独立）— 含唯一性奖励
-- ============================================================================
Collection.TIER_REWARDS = {
    { pct = 0.25, title = "初见",
      reward = { money = 100 },
      unique = "解锁专属称号「探索新手」" },
    { pct = 0.50, title = "探索者",
      reward = { money = 300, rep = 20 },
      unique = "解锁网吧特殊装饰「收藏架」" },
    { pct = 0.75, title = "收藏家",
      reward = { money = 600, rep = 50 },
      unique = "解锁隐藏NPC对话（队员讲述过去）" },
    { pct = 1.00, title = "完美图鉴",
      reward = { money = 1000, rep = 100 },
      unique = "解锁专属称号「非洲传奇收藏家」+ 网吧金色主题" },
}

-- ============================================================================
-- 图鉴完成度被动加成
-- ============================================================================
Collection.PASSIVE_BONUSES = {
    { pct = 0.25, desc = "声望收益+5%", type = "rep_bonus", value = 0.05 },
    { pct = 0.50, desc = "训练收益+5%", type = "train_bonus", value = 0.05 },
    { pct = 0.75, desc = "日收入+3%", type = "income_bonus", value = 0.03 },
    { pct = 1.00, desc = "全属性+5%", type = "all_bonus", value = 0.05 },
}

-- ============================================================================
-- 核心逻辑
-- ============================================================================

--- 获取某类别的总条目数
function Collection.CountByCategory(catId)
    local n = 0
    for _, item in ipairs(Collection.ITEMS) do
        if item.category == catId then n = n + 1 end
    end
    return n
end

--- 获取某类别已解锁数
function Collection.CountUnlockedByCategory(catId)
    local col = playerData_.collection or {}
    local n = 0
    for _, item in ipairs(Collection.ITEMS) do
        if item.category == catId and col[item.id] then n = n + 1 end
    end
    return n
end

--- 获取总解锁数和总条目数
function Collection.GetProgress()
    local col = playerData_.collection or {}
    local total = #Collection.ITEMS
    local unlocked = 0
    for _, item in ipairs(Collection.ITEMS) do
        if col[item.id] then unlocked = unlocked + 1 end
    end
    return unlocked, total
end

--- 获取总完成百分比
function Collection.GetTotalPercent()
    local u, t = Collection.GetProgress()
    return u / math.max(1, t)
end

--- 获取被动加成值
function Collection.GetPassiveBonus(bonusType)
    local pct = Collection.GetTotalPercent()
    for i = #Collection.PASSIVE_BONUSES, 1, -1 do
        local b = Collection.PASSIVE_BONUSES[i]
        if pct >= b.pct and b.type == bonusType then
            return b.value
        end
    end
    return 0
end

--- 每日检查并解锁新条目 + 阶段奖励
function Collection.CheckAndUnlock()
    playerData_.collection = playerData_.collection or {}
    playerData_.collectionTiers = playerData_.collectionTiers or {}
    local newlyUnlocked = {}

    for _, item in ipairs(Collection.ITEMS) do
        if not playerData_.collection[item.id] then
            local ok, result = pcall(item.check)
            if ok and result then
                playerData_.collection[item.id] = playerData_.day or 1
                table.insert(newlyUnlocked, item)
            end
        end
    end

    -- 检查阶段奖励
    local tierRewards = {}
    for _, cat in ipairs(Collection.CATEGORIES) do
        local total = Collection.CountByCategory(cat.id)
        local unlocked = Collection.CountUnlockedByCategory(cat.id)
        local pct = unlocked / math.max(1, total)

        for _, tier in ipairs(Collection.TIER_REWARDS) do
            local tierId = cat.id .. "_" .. tostring(math.floor(tier.pct * 100))
            if pct >= tier.pct and not playerData_.collectionTiers[tierId] then
                playerData_.collectionTiers[tierId] = playerData_.day or 1
                -- 发放奖励
                if tier.reward.money then
                    playerData_.money = (playerData_.money or 0) + tier.reward.money
                end
                if tier.reward.rep then
                    playerData_.reputation = (playerData_.reputation or 0) + tier.reward.rep
                end
                table.insert(tierRewards, { cat = cat, tier = tier })
                -- 记录日志
                if AddLog then
                    AddLog("🏆 【图鉴】" .. cat.name .. " 达成「" .. tier.title .. "」！" .. (tier.unique or ""))
                end
            end
        end
    end

    -- 新解锁条目的日志
    for _, item in ipairs(newlyUnlocked) do
        if AddLog then
            local starStr = string.rep("★", item.stars or 1)
            AddLog("📚 【图鉴】解锁：" .. item.icon .. " " .. item.name .. " " .. starStr)
        end
    end

    return newlyUnlocked, tierRewards
end

--- 获取最近解锁的条目（按天倒序）
function Collection.GetRecentUnlocks(limit)
    limit = limit or 5
    local col = playerData_.collection or {}
    local list = {}
    for _, item in ipairs(Collection.ITEMS) do
        if col[item.id] then
            table.insert(list, { item = item, day = col[item.id] })
        end
    end
    table.sort(list, function(a, b) return a.day > b.day end)
    local result = {}
    for i = 1, math.min(limit, #list) do
        result[i] = list[i]
    end
    return result
end

return Collection
