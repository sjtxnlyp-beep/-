---@diagnostic disable: undefined-global
-- ============================================================================
-- Retention.lua — 留存系统核心模块
-- 包含：新手引导 / 明日预告 / 离线收益 / 目标链 / 周期性大事件
-- ============================================================================

local Retention = {}

-- ============================================================================
-- 1. 新手引导（Day 1-3 教程事件）
-- ============================================================================

--- 教程事件表：每天1-2个精心设计的高参与感事件
local TUTORIAL_EVENTS = {
    [1] = {
        {
            id = "tut_first_customer", category = "customer", rarity = "common",
            title = "🧑‍💻 第一位常客",
            desc = "一个叫 Kwame 的年轻人走进网吧，他看起来有些紧张。\"老板，我能试试那个......三角洲行动吗？我看别人玩过，超酷的！\"",
            type = "choice",
            choices = {
                { text = "🎮 免费给他玩一局，教他基本操作",
                  effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma + 1 end,
                  result = function() return "Kwame 兴奋得手都在抖，第一局就拿了两个击杀！\"老板你太好了！我明天还来！\"他会成为你最忠实的顾客。\n\n💡 提示：善待顾客能提升声望，声望越高客流越多！" end },
                { text = "💰 收他正常价格，生意就是生意",
                  effect = function() playerData_.money = playerData_.money + 30 end,
                  result = function() return "Kwame 付了钱坐下来，虽然有点肉疼但很开心。\"值了！\"——他第二天带了两个朋友来。\n\n💡 提示：每台电脑每天都能产生收入，电脑越多赚得越多！" end },
            },
        },
        {
            id = "tut_equipment_trouble", category = "equipment", rarity = "common",
            title = "⚡ 键盘罢工了",
            desc = "三号机的键盘突然失灵，几个按键按下去没反应。客人抱怨连连。你需要处理这件事。",
            type = "choice",
            choices = {
                { text = "🔧 花 $50 从集市买一个新键盘",
                  effect = function() playerData_.money = playerData_.money - 50; playerData_.equipCondition = math.min(100, playerData_.equipCondition + 10) end,
                  result = function() return "新键盘换上，客人立刻满意了。设备状况提升了！\n\n💡 提示：注意设备状况！低于 80% 会影响收入，可以在升级页面维护设备。" end },
                { text = "🤷 先凑合用，等有钱了再说",
                  effect = function() playerData_.equipCondition = math.max(0, playerData_.equipCondition - 5) end,
                  result = function() return "客人不太高兴地换了一台机器。那台坏键盘的电脑暂时没人愿意坐了。\n\n💡 提示：设备状况太低会降低收入哦！记得定期维护。" end },
            },
        },
    },
    [2] = {
        {
            id = "tut_merchant_visit", category = "business", rarity = "common",
            title = "💼 路过的商人",
            desc = "一个穿着西装的中年人走了进来。\"我是做二手电子设备生意的。听说你这里新开了网吧？我有些好东西可以给你看看——价格绝对公道。\"",
            type = "choice",
            choices = {
                { text = "💰 花 $200 买一批二手鼠标垫和耳机",
                  effect = function() playerData_.money = playerData_.money - 200; playerData_.reputation = playerData_.reputation + 8; trafficBonus_ = trafficBonus_ + 3 end,
                  result = function() return "新装备摆上桌面，整个网吧看起来专业多了。客人们纷纷夸赞！\n\n💡 提示：升级页面有更多装备可以购买——椅子、网速、空调都能提升体验和收入！" end },
                { text = "✋ 算了，我目前资金紧张",
                  effect = function() end,
                  result = function() return "商人留下了名片就走了。\"下次有好货我再来找你。\"\n\n💡 提示：点击底部的「升级」标签页查看所有可用升级！合理投资是致富关键。" end },
            },
        },
        {
            id = "tut_recruit_hint", category = "social", rarity = "common",
            title = "👥 有人想加入战队",
            desc = "网吧里一个玩得不错的年轻人走过来问：\"老板，听说你在组建电竞战队？我......我能试试吗？\"",
            type = "choice",
            choices = {
                { text = "🤝 欢迎！先试训一周看看",
                  effect = function() playerData_.reputation = playerData_.reputation + 3 end,
                  result = function() return "他高兴得跳了起来！\"我一定好好练！\"\n\n💡 提示：在「经营」标签页中，你可以使用行动点来招募队员。队员能帮你跑刀赚钱、参加比赛！" end },
                { text = "🤔 现在还不急，等我准备好了再说",
                  effect = function() end,
                  result = function() return "他有点失望但表示理解。\"好吧，等你需要人的时候找我。\"\n\n💡 提示：战队是游戏核心！招募队员后可以训练、参加友谊赛和锦标赛。" end },
            },
        },
    },
    [3] = {
        {
            id = "tut_rival_appears", category = "business", rarity = "common",
            title = "🏪 竞争对手出现了",
            desc = "街对面新开了一家「Gold Net」网吧，装修豪华，还打出了\"首日免费\"的广告。你的几个老客户好奇地走了过去......",
            type = "choice",
            choices = {
                { text = "💪 提升服务质量，用实力说话",
                  effect = function() playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1 end,
                  result = function() return "你决定靠服务和氛围留住客户。加量不加价，客户们发现还是 Dragon Net 更有人情味。\n\n💡 提示：声望越高，客流越多！声望来自升级、比赛、每日委托等多种渠道。" end },
                { text = "📢 搞促销活动，打价格战",
                  effect = function() playerData_.money = playerData_.money - 100; trafficBonus_ = trafficBonus_ + 5 end,
                  result = function() return "你推出\"充100送50\"活动，今天客流量暴涨！虽然花了点钱，但赚回了人气。\n\n💡 提示：注意平衡收入和投资，别让现金流断裂！" end },
            },
        },
        {
            id = "tut_daily_quest", category = "social", rarity = "common",
            title = "📋 每日委托系统",
            desc = "手机响了——当地电竞协会的消息：\"恭喜加入瓦坎达维尔电竞联盟！每天完成一项委托任务可获得额外奖励。今天的任务已发布，快去看看吧！\"",
            type = "choice",
            choices = {
                { text = "📱 查看今日委托",
                  effect = function() playerData_.reputation = playerData_.reputation + 3 end,
                  result = function() return "你打开了委托列表。完成委托可以获得现金和声望奖励，连续完成还有连击加成！\n\n💡 提示：每日委托在「经营」标签页底部查看。连续完成天数越多，奖励越丰厚！" end },
            },
        },
    },
}

--- 获取指定天数的教程事件列表
---@param day number
---@return table|nil 事件列表或nil
function Retention.GetTutorialEvents(day)
    return TUTORIAL_EVENTS[day]
end

--- 获取下一个未使用的教程事件
---@param day number
---@param usedIndex number 已使用的事件索引（0表示未使用过）
---@return table|nil 事件或nil
function Retention.GetNextTutorialEvent(day, usedIndex)
    local events = TUTORIAL_EVENTS[day]
    if not events then return nil end
    local nextIdx = (usedIndex or 0) + 1
    return events[nextIdx]
end

-- ============================================================================
-- 2. 明日预告系统
-- ============================================================================

--- 生成明日预告内容（1-3条提示）
---@param day number 当前天数（预告的是 day+1 的内容）
---@return table 预告文本数组
function Retention.GenerateTomorrowPreview(day)
    local nextDay = day + 1
    local previews = {}

    -- 里程碑预告
    if nextDay == 5 then
        table.insert(previews, "🎯 明天是第5天，可能会有特殊事件发生！")
    elseif nextDay == 10 then
        table.insert(previews, "⚠️ 第10天开始，可能出现货币贬值——考虑投资黄金避险！")
    elseif nextDay == 15 then
        table.insert(previews, "🏆 经营半个月了！看看能不能挑战更高级别的比赛？")
    elseif nextDay == 20 then
        table.insert(previews, "🌟 第20天！你的网吧已经小有名气，大事件可能要来了……")
    elseif nextDay == 30 then
        table.insert(previews, "🎊 明天就是第30天！能撑到现在真不容易，大结局还会远吗？")
    elseif nextDay % 10 == 0 then
        table.insert(previews, "📅 明天是第" .. nextDay .. "天！阶段性里程碑，保持势头！")
    end

    -- 周期事件预告
    local periodicPreview = Retention.GetPeriodicEventPreview(nextDay)
    if periodicPreview then
        table.insert(previews, periodicPreview)
    end

    -- 目标链预告（如果接近完成某个目标）
    local goalPreview = Retention.GetGoalPreview()
    if goalPreview then
        table.insert(previews, goalPreview)
    end

    -- NPC 剧情预告
    local npcPreview = Retention.GetNPCStoryPreview(nextDay)
    if npcPreview then
        table.insert(previews, npcPreview)
    end

    -- 保底：至少1条预告
    if #previews == 0 then
        local generic = {
            "💰 明天又是充满机遇的一天，做好准备！",
            "🎮 新的一天，新的挑战——Dragon Force 加油！",
            "☀️ 非洲的阳光从不缺席，你的网吧也是！",
            "🔥 继续努力，距离非洲电竞之巅又近了一步！",
        }
        table.insert(previews, generic[math.random(#generic)])
    end

    -- 最多3条
    while #previews > 3 do table.remove(previews) end

    return previews
end

-- ============================================================================
-- 3. 离线收益系统
-- ============================================================================

--- 计算离线收益
---@param offlineSeconds number 离线秒数
---@return table|nil {earnings, hours, canDouble} 或 nil（不足5分钟）
function Retention.CalculateOfflineEarnings(offlineSeconds)
    -- 最少5分钟才触发
    if offlineSeconds < 300 then return nil end

    -- 上限8小时
    local hours = math.min(8, offlineSeconds / 3600)

    -- 基础每小时收入 = 当前日收入 × 30%（离线效率）
    local dailyIncome = 0
    local ok, result = pcall(CalcDailyIncome)
    if ok then dailyIncome = result or 0 end
    if dailyIncome <= 0 then dailyIncome = playerData_.computers * 20 end

    local hourlyRate = math.floor(dailyIncome * 0.3)
    local earnings = math.max(10, math.floor(hourlyRate * hours))

    return {
        earnings = earnings,
        hours = math.floor(hours * 10) / 10,  -- 保留1位小数
        canDouble = true,  -- 广告翻倍选项
    }
end

--- 领取离线收益
---@param doubled boolean 是否通过广告翻倍
function Retention.ClaimOfflineEarnings(doubled)
    if not pendingOfflineReward_ then return end
    local earnings = pendingOfflineReward_.earnings
    if doubled then earnings = earnings * 2 end
    playerData_.money = playerData_.money + earnings
    AddLog("💤 离线收益: +$" .. earnings .. (doubled and " (广告翻倍!)" or ""))
    pendingOfflineReward_ = nil
end

-- ============================================================================
-- 4. 目标链系统
-- ============================================================================

--- 3条目标链定义
local GOAL_CHAINS = {
    develop = {
        name = "🏗️ 发展之路",
        goals = {
            { id = "d1", desc = "拥有 4 台电脑", reward = { money = 100, rep = 5 },
              check = function() return playerData_.computers >= 4 end },
            { id = "d2", desc = "升级网速到 Lv2", reward = { money = 150, rep = 8 },
              check = function() return playerData_.netSpeed >= 2 end },
            { id = "d3", desc = "招募第一个队员", reward = { money = 200, rep = 10 },
              check = function() return #teamMembers_ >= 1 end },
            { id = "d4", desc = "声望达到 50", reward = { money = 200, rep = 0 },
              check = function() return playerData_.reputation >= 50 end },
            { id = "d5", desc = "拥有 6 台电脑", reward = { money = 300, rep = 15 },
              check = function() return playerData_.computers >= 6 end },
            { id = "d6", desc = "安装空调", reward = { money = 200, rep = 10 },
              check = function() return playerData_.acLevel >= 1 end },
            { id = "d7", desc = "赢得一场友谊赛", reward = { money = 300, rep = 20 },
              check = function() return playerData_.friendlyWins >= 1 end },
            { id = "d8", desc = "声望达到 200", reward = { money = 500, rep = 0 },
              check = function() return playerData_.reputation >= 200 end },
            { id = "d9", desc = "拥有 10 台电脑", reward = { money = 800, rep = 30 },
              check = function() return playerData_.computers >= 10 end },
            { id = "d10", desc = "开设第一家分店", reward = { money = 1500, rep = 50 },
              check = function() return #(playerData_.branches or {}) >= 1 end },
        },
    },
    social = {
        name = "👥 社交之路",
        goals = {
            { id = "s1", desc = "完成 1 次每日委托", reward = { money = 80, rep = 5 },
              check = function() return (playerData_.totalRuns or 0) >= 1 or (playerData_.friendlyWins or 0) >= 1 end },
            { id = "s2", desc = "招募 2 个队员", reward = { money = 150, rep = 10 },
              check = function() return #teamMembers_ >= 2 end },
            { id = "s3", desc = "团队平均好感 ≥ 70", reward = { money = 200, rep = 15 },
              check = function()
                  if #teamMembers_ == 0 then return false end
                  local total = 0
                  for _, m in ipairs(teamMembers_) do total = total + (m.mood or 50) end
                  return (total / #teamMembers_) >= 70
              end },
            { id = "s4", desc = "招募 3 个队员", reward = { money = 300, rep = 15 },
              check = function() return #teamMembers_ >= 3 end },
            { id = "s5", desc = "赢得 3 场友谊赛", reward = { money = 300, rep = 20 },
              check = function() return playerData_.friendlyWins >= 3 end },
            { id = "s6", desc = "组建满编 5 人战队", reward = { money = 500, rep = 30 },
              check = function() return #teamMembers_ >= 5 end },
            { id = "s7", desc = "参加一次锦标赛", reward = { money = 500, rep = 25 },
              check = function() return (playerData_.tournamentPlayed or 0) >= 1 end },
            { id = "s8", desc = "赢得锦标赛冠军", reward = { money = 1000, rep = 50 },
              check = function() return (playerData_.tournamentWins or 0) >= 1 end },
        },
    },
    wealth = {
        name = "💰 财富之路",
        goals = {
            { id = "w1", desc = "累计赚取 $3,000", reward = { money = 100, rep = 5 },
              check = function() return (playerData_.totalEarnings or 0) >= 3000 end },
            { id = "w2", desc = "持有 $2,000 现金", reward = { money = 0, rep = 10 },
              check = function() return playerData_.money >= 2000 end },
            { id = "w3", desc = "开设烤鸡摊", reward = { money = 100, rep = 8 },
              check = function() return playerData_.foodShop >= 1 end },
            { id = "w4", desc = "累计赚取 $8,000", reward = { money = 200, rep = 10 },
              check = function() return (playerData_.totalEarnings or 0) >= 8000 end },
            { id = "w5", desc = "购买黄金", reward = { money = 0, rep = 15 },
              check = function() return (playerData_.goldOunces or 0) > 0 end },
            { id = "w6", desc = "购买黄金保险箱", reward = { money = 300, rep = 15 },
              check = function() return playerData_.goldSafe == true end },
            { id = "w7", desc = "累计赚取 $20,000", reward = { money = 500, rep = 25 },
              check = function() return (playerData_.totalEarnings or 0) >= 20000 end },
            { id = "w8", desc = "总资产超过 $50,000", reward = { money = 1000, rep = 50 },
              check = function()
                  local gold = (playerData_.goldOunces or 0) * 1800
                  return playerData_.money + gold >= 50000
              end },
        },
    },
}

--- 检查目标链进度，自动推进并发放奖励
---@return table|nil 刚完成的目标 {chain, goal, reward}
function Retention.CheckGoalProgress()
    local completed = {}
    for chainId, chain in pairs(GOAL_CHAINS) do
        local progress = playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            if goal.check() then
                -- 标记完成
                playerData_.goalCompleted[goal.id] = true
                playerData_.goalProgress[chainId] = progress + 1
                -- 发放奖励
                if goal.reward.money > 0 then
                    playerData_.money = playerData_.money + goal.reward.money
                end
                if goal.reward.rep > 0 then
                    playerData_.reputation = playerData_.reputation + goal.reward.rep
                end
                AddLog("🎯 目标完成: " .. goal.desc .. " → +$" .. goal.reward.money .. " +声望" .. goal.reward.rep)
                table.insert(completed, { chain = chain.name, goal = goal })
                PlaySFX("victory")
            end
        end
    end
    if #completed > 0 then TriggerCelebration() end
    return #completed > 0 and completed or nil
end

--- 获取当前目标概览（用于UI显示）
---@return table 各链当前目标 { {chainName, goalDesc, progress, total, reward} }
function Retention.GetCurrentGoals()
    local result = {}
    for _, chainId in ipairs({"develop", "social", "wealth"}) do
        local chain = GOAL_CHAINS[chainId]
        local progress = playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            table.insert(result, {
                chainId = chainId,
                chainName = chain.name,
                goalDesc = goal.desc,
                progress = progress,
                total = #goals,
                rewardMoney = goal.reward.money,
                rewardRep = goal.reward.rep,
            })
        else
            table.insert(result, {
                chainId = chainId,
                chainName = chain.name,
                goalDesc = "全部完成！",
                progress = #goals,
                total = #goals,
                rewardMoney = 0,
                rewardRep = 0,
                done = true,
            })
        end
    end
    return result
end

--- 获取目标链预告（用于明日预告）
function Retention.GetGoalPreview()
    for _, chainId in ipairs({"develop", "social", "wealth"}) do
        local chain = GOAL_CHAINS[chainId]
        local progress = playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            -- 简单检查是否"接近完成"
            if goal.check and not goal.check() then
                return "🎯 当前目标: " .. goal.desc .. " — 继续努力！"
            end
        end
    end
    return nil
end

-- ============================================================================
-- 5. 周期性大事件
-- ============================================================================

local PERIODIC_EVENTS = {
    {
        id = "africa_cup",
        name = "⚽ 非洲杯足球赛",
        interval = 7,    -- 每7天触发
        duration = 2,     -- 持续2天
        minDay = 5,       -- 最早第5天开始
        desc = "非洲杯比赛期间！球迷们蜂拥到网吧看直播，客流暴涨！",
        effect = function()
            trafficBonus_ = trafficBonus_ + 8
        end,
        dailyEffect = function()
            trafficBonus_ = trafficBonus_ + 8
        end,
        endEffect = function()
            AddLog("⚽ 非洲杯结束了，客流恢复正常。")
        end,
        preview = "⚽ 非洲杯足球赛即将到来！客流将暴涨！",
    },
    {
        id = "power_week",
        name = "⚡ 停电高发期",
        interval = 10,   -- 每10天触发
        duration = 2,
        minDay = 8,
        desc = "电网检修期间频繁停电！有发电机的网吧能逆势赚钱！",
        effect = function()
            if playerData_.generatorLevel > 0 then
                AddLog("⚡ 别人停电你发电！竞争对手都关门了，客流大增！")
                trafficBonus_ = trafficBonus_ + 10
                playerData_.reputation = playerData_.reputation + 5
            else
                AddLog("⚡ 停电了！没有发电机，今天亏损严重......")
                playerData_.money = playerData_.money - math.floor(playerData_.money * 0.05)
            end
        end,
        dailyEffect = function()
            if playerData_.generatorLevel > 0 then
                trafficBonus_ = trafficBonus_ + 10
            else
                playerData_.money = playerData_.money - math.floor(playerData_.money * 0.03)
            end
        end,
        endEffect = function()
            AddLog("⚡ 电网恢复正常供电。")
        end,
        preview = "⚡ 停电高发期将至——快检查发电机！",
    },
    {
        id = "gold_rush",
        name = "📈 黄金狂潮",
        interval = 14,   -- 每14天触发
        duration = 3,
        minDay = 12,
        desc = "国际金价暴涨！持有黄金的人赚翻了！",
        effect = function()
            local gold = playerData_.goldOunces or 0
            if gold > 0 then
                local bonus = math.floor(gold * 300)
                playerData_.money = playerData_.money + bonus
                AddLog("📈 黄金狂潮！你持有的 " .. string.format("%.1f", gold) .. " 盎司升值了 +$" .. bonus .. "！")
            else
                AddLog("📈 黄金狂潮到来！可惜你没有持有黄金......考虑买入？")
            end
        end,
        dailyEffect = function() end,
        endEffect = function()
            AddLog("📈 黄金价格回落到正常水平。")
        end,
        preview = "📈 黄金狂潮将至——手上有金子吗？",
    },
    {
        id = "delta_menggong",
        name = "🔥 三角洲猛攻节",
        interval = 12,   -- 每12天触发
        duration = 3,     -- 持续3天
        minDay = 10,
        desc = "三角洲行动推出猛攻节活动，日活突破5000万！全非洲的网吧都挤满了人！",
        effect = function()
            trafficBonus_ = trafficBonus_ + 12
            AddLog("🔥 猛攻节开幕！'猛攻不被定义'刷屏了！客流暴涨，代练订单也爆了！")
        end,
        dailyEffect = function()
            trafficBonus_ = trafficBonus_ + 12
            -- 猛攻节期间每天有额外代练收入
            local bonus = 30 + math.random(0, 40)
            playerData_.money = playerData_.money + bonus
            playerData_.havocCoins = playerData_.havocCoins + math.random(20, 50)
            AddLog("🔥 猛攻节持续中！代练订单不断，额外收入 +$" .. bonus)
        end,
        endEffect = function()
            playerData_.reputation = playerData_.reputation + 10
            AddLog("🔥 猛攻节结束了！你的网吧在活动期间赚得盆满钵满，声望+10。")
        end,
        preview = "🔥 三角洲猛攻节即将到来——备好设备，客流要爆了！",
    },
    {
        id = "esport_league",
        name = "🏆 网吧联赛周",
        interval = 21,   -- 每21天触发
        duration = 3,
        minDay = 15,
        desc = "全非洲网吧联赛开赛！比赛奖励翻倍，声望加速积累！",
        effect = function()
            playerData_.reputation = playerData_.reputation + 15
            AddLog("🏆 网吧联赛开幕！比赛奖励翻倍，声望获取加速！")
        end,
        dailyEffect = function()
            playerData_.reputation = playerData_.reputation + 5
        end,
        endEffect = function()
            AddLog("🏆 网吧联赛圆满结束！")
        end,
        preview = "🏆 网吧联赛周即将开始——准备好参赛了吗？",
    },
}

--- 检查并触发周期性大事件
---@param day number 当前天数
---@return string|nil 触发的事件名称
function Retention.CheckPeriodicEvents(day)
    -- 先处理进行中的事件
    local active = playerData_.activePeriodicEvent
    if active then
        active.remainDays = active.remainDays - 1
        if active.remainDays <= 0 then
            -- 事件结束
            for _, pe in ipairs(PERIODIC_EVENTS) do
                if pe.id == active.id and pe.endEffect then
                    pcall(pe.endEffect)
                end
            end
            playerData_.activePeriodicEvent = nil
        else
            -- 事件持续中，应用每日效果
            for _, pe in ipairs(PERIODIC_EVENTS) do
                if pe.id == active.id and pe.dailyEffect then
                    pcall(pe.dailyEffect)
                end
            end
            return active.id
        end
    end

    -- 检查是否有新事件触发
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if day >= pe.minDay then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            if day - lastDay >= pe.interval then
                -- 触发！
                playerData_.activePeriodicEvent = {
                    id = pe.id,
                    name = pe.name,
                    remainDays = pe.duration,
                    desc = pe.desc,
                }
                if not playerData_.lastPeriodicDay then playerData_.lastPeriodicDay = {} end
                playerData_.lastPeriodicDay[pe.id] = day
                AddLog(pe.name .. " 开始了！" .. pe.desc)
                if pe.effect then pcall(pe.effect) end
                return pe.id
            end
        end
    end
    return nil
end

--- 获取周期事件预告（用于明日预告）
function Retention.GetPeriodicEventPreview(nextDay)
    -- 检查是否有事件即将触发
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if nextDay >= pe.minDay then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            local daysSince = nextDay - lastDay
            if daysSince == pe.interval then
                return pe.preview
            elseif daysSince >= pe.interval - 2 and daysSince < pe.interval then
                local daysLeft = pe.interval - daysSince
                return pe.name .. " " .. daysLeft .. " 天后到来！"
            end
        end
    end
    return nil
end

--- 获取当前活跃的周期事件信息（用于UI显示）
---@return table|nil {name, desc, remainDays}
function Retention.GetActivePeriodicEvent()
    return playerData_.activePeriodicEvent
end

--- 获取下一个即将到来的周期事件（用于UI倒计时）
---@param day number 当前天数
---@return table|nil {name, daysUntil}
function Retention.GetNextPeriodicEvent(day)
    local closest = nil
    local closestDays = 999
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if day >= (pe.minDay - 3) then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            local nextTrigger = lastDay + pe.interval
            if nextTrigger <= day then nextTrigger = day + pe.interval - ((day - lastDay) % pe.interval) end
            local daysUntil = nextTrigger - day
            if daysUntil > 0 and daysUntil < closestDays then
                closestDays = daysUntil
                closest = { name = pe.name, daysUntil = daysUntil }
            end
        end
    end
    return closest
end

--- NPC 剧情预告占位（由 NPCStorylines 模块填充）
function Retention.GetNPCStoryPreview(nextDay)
    if NPCStorylines and NPCStorylines.GetPreview then
        return NPCStorylines.GetPreview(nextDay)
    end
    return nil
end

return Retention
