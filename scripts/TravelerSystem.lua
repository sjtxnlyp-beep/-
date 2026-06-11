---@diagnostic disable: undefined-global
-- ============================================================================
-- TravelerSystem.lua — 旅行者NPC系统
-- 来自非洲各地的旅行者随机到访，提供限时交易、文化故事、临时加成
-- 每 3-6 天来一位，停留 1-3 天后离开
-- ============================================================================

local M = {}

-- ============================================================================
-- 旅行者数据库
-- ============================================================================
M.TRAVELERS = {
    -- ── 商人类（提供特殊交易） ──
    {
        id = "trader_amara",
        name = "Amara",
        title = "马里黄金商人",
        emoji = "👳‍♀️",
        origin = "廷巴克图",
        greeting = "和平降临于你，朋友。我从廷巴克图带来了最好的货物。",
        stayDays = 2,
        category = "trader",
        minDay = 8,
        offers = {
            { type = "buy_boost", label = "📈 客流香料", desc = "燃烧异域香料，吸引更多客人（+30%客流，持续2天）", cost = 120,
              effect = function() playerData_.travelerBuffs = playerData_.travelerBuffs or {}; playerData_.travelerBuffs.traffic = { bonus = 0.3, daysLeft = 2 } end },
            { type = "buy_item", label = "🪙 古董硬币", desc = "萨赫勒地区古老金币，收藏价值极高", cost = 200,
              effect = function() playerData_.reputation = playerData_.reputation + 25; playerData_.travelerItemsBought = (playerData_.travelerItemsBought or 0) + 1 end,
              result = "⭐声望+25（古董增值！）" },
            { type = "trade", label = "🔄 以物易物", desc = "用50哈弗币换取她的神秘非洲面具", cost = 0,
              cond = function() return (playerData_.havocCoins or 0) >= 50 end,
              effect = function() playerData_.havocCoins = playerData_.havocCoins - 50; playerData_.reputation = playerData_.reputation + 15; playerData_.travelerItemsBought = (playerData_.travelerItemsBought or 0) + 1 end,
              result = "🎭 获得非洲面具！声望+15" },
        },
        departure = "愿真主保佑你的生意兴隆。我们会再见的。",
    },
    {
        id = "trader_kwame",
        name = "Kwame",
        title = "阿克拉电子商",
        emoji = "🧑‍💼",
        origin = "阿克拉",
        greeting = "Hey bro! 我从阿克拉那边搞到一批好东西，给你看看？",
        stayDays = 2,
        category = "trader",
        minDay = 12,
        offers = {
            { type = "buy_boost", label = "⚡ 超频路由器", desc = "黑市来的企业级路由器，网速翻倍（+50%收入，持续2天）", cost = 250,
              effect = function() playerData_.travelerBuffs = playerData_.travelerBuffs or {}; playerData_.travelerBuffs.income = { bonus = 0.5, daysLeft = 2 } end },
            { type = "buy_boost", label = "🎮 限定外设", desc = "稀有款RGB键盘，队员看了都想练（训练效率+40%，持续3天）", cost = 180,
              effect = function() playerData_.travelerBuffs = playerData_.travelerBuffs or {}; playerData_.travelerBuffs.training = { bonus = 0.4, daysLeft = 3 } end },
            { type = "info", label = "💬 聊聊行情", desc = "免费打听阿克拉电竞圈的消息", cost = 0,
              effect = function() playerData_.reputation = playerData_.reputation + 5 end,
              result = "Kwame 告诉你阿克拉最近在办电竞联赛，奖金丰厚。也许以后可以去那边闯闯。\n⭐声望+5" },
        },
        departure = "下次来给你带更猛的货！Stay cool bro!",
    },
    -- ── 文化类（提供故事和灵感） ──
    {
        id = "griot_sekou",
        name = "Sékou",
        title = "曼丁卡格里奥",
        emoji = "🎵",
        origin = "几内亚",
        greeting = "我是 Sékou，用科拉琴传承我们祖先的智慧。让我为你弹奏一曲。",
        stayDays = 1,
        category = "storyteller",
        minDay = 6,
        offers = {
            { type = "story", label = "🎶 听一段史诗", desc = "曼丁卡帝国的建国传说（全队心情+15）", cost = 0,
              effect = function()
                  for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 15) end
                  playerData_.travelerStoriesHeard = (playerData_.travelerStoriesHeard or 0) + 1
              end,
              result = "Sékou 低沉的歌声讲述了松迪亚塔·凯塔的传奇。队员们听得入神，仿佛回到了帝国的黄金时代。\n❤️全队心情+15" },
            { type = "buy_boost", label = "🥁 鼓舞士气", desc = "请他为队员演奏战鼓（比赛加成+10%，持续2天）", cost = 80,
              effect = function() playerData_.travelerBuffs = playerData_.travelerBuffs or {}; playerData_.travelerBuffs.match = { bonus = 0.1, daysLeft = 2 } end },
        },
        departure = "音乐不会消散，它会留在你心中。再会，朋友。",
    },
    {
        id = "artist_zainab",
        name = "Zainab",
        title = "桑给巴尔画师",
        emoji = "🎨",
        origin = "桑给巴尔",
        greeting = "这里的光线太美了！我能在你网吧画一幅壁画吗？作为交换，我可以教你的员工一些东西。",
        stayDays = 2,
        category = "storyteller",
        minDay = 10,
        offers = {
            { type = "buy_boost", label = "🖼️ 委托壁画", desc = "让她在网吧画一幅壁画（声望+20，客流+20%持续3天）", cost = 150,
              effect = function()
                  playerData_.reputation = playerData_.reputation + 20
                  playerData_.travelerBuffs = playerData_.travelerBuffs or {}
                  playerData_.travelerBuffs.traffic = { bonus = 0.2, daysLeft = 3 }
              end,
              result = "Zainab 画了一幅融合斯瓦希里海洋元素的壁画。顾客们纷纷拍照发社交媒体！\n⭐声望+20 📈客流+20%(3天)" },
            { type = "story", label = "🌊 听旅行故事", desc = "桑给巴尔的香料贸易往事（全队心情+10）", cost = 0,
              effect = function()
                  for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
                  playerData_.travelerStoriesHeard = (playerData_.travelerStoriesHeard or 0) + 1
              end,
              result = "Zainab 讲述了丁香岛的故事——曾经全世界的香料都从这里出发。队员们听得津津有味。\n❤️全队心情+10" },
        },
        departure = "如果你来桑给巴尔，记得找我。那里的日落，是全非洲最美的。",
    },
    -- ── 探险家类（提供稀有机会） ──
    {
        id = "explorer_diallo",
        name = "Diallo",
        title = "撒哈拉向导",
        emoji = "🐫",
        origin = "尼日尔",
        greeting = "我刚穿越撒哈拉过来。路上遇到了些有趣的事，要听听吗？",
        stayDays = 1,
        category = "explorer",
        minDay = 15,
        offers = {
            { type = "buy_item", label = "🗺️ 沙漠地图碎片", desc = "标注了古代贸易路线的羊皮纸（城市碎片+1）", cost = 300,
              effect = function()
                  playerData_.cityFragments = (playerData_.cityFragments or 0) + 1
                  playerData_.travelerItemsBought = (playerData_.travelerItemsBought or 0) + 1
              end,
              result = "🗺️ 城市碎片+1！转生门槛将降低。" },
            { type = "info", label = "🌍 打听远方消息", desc = "免费了解其他城市的情况", cost = 0,
              effect = function() playerData_.reputation = playerData_.reputation + 8 end,
              result = "Diallo 告诉你北方的商路正在恢复，未来会有更多客人路过这一带。\n⭐声望+8" },
        },
        departure = "沙漠教会我耐心。继续坚持，你一定能走得更远。",
    },
    {
        id = "explorer_nyota",
        name = "Nyota",
        title = "东非猎人",
        emoji = "🏹",
        origin = "坦桑尼亚",
        greeting = "Jambo! 我在追踪一头传说中的白狮，路过这里歇歇脚。你这里有水吗？",
        stayDays = 2,
        category = "explorer",
        minDay = 18,
        offers = {
            { type = "buy_boost", label = "🦁 猎人的祝福", desc = "Nyota 分享了马赛人的专注秘诀（训练效率+30%，比赛+15%，持续2天）", cost = 200,
              effect = function()
                  playerData_.travelerBuffs = playerData_.travelerBuffs or {}
                  playerData_.travelerBuffs.training = { bonus = 0.3, daysLeft = 2 }
                  playerData_.travelerBuffs.match = { bonus = 0.15, daysLeft = 2 }
              end },
            { type = "recruit_hint", label = "👥 推荐人才", desc = "她认识一个厉害的年轻人，可以介绍给你", cost = 100,
              effect = function()
                  playerData_.travelerRecruitBonus = (playerData_.travelerRecruitBonus or 0) + 1
                  playerData_.karma = playerData_.karma + 2
              end,
              result = "Nyota 写了封介绍信。下次招募时可能遇到特别优秀的候选人！\n🌟下次招募品质+1" },
        },
        departure = "Kwaheri! 如果你在塞伦盖蒂看到一头白狮，帮我留意。",
    },
    -- ── 神秘类（稀有高收益） ──
    {
        id = "mystic_oba",
        name = "Oba",
        title = "约鲁巴祭司",
        emoji = "🔮",
        origin = "伊费",
        greeting = "命运的线交织在此。我看到你的网吧……有不凡的未来。",
        stayDays = 1,
        category = "mystic",
        minDay = 20,
        offers = {
            { type = "gamble", label = "🎲 命运占卜", desc = "Oba 占卜你的运势（随机大奖或小损失）", cost = 100,
              effect = function()
                  local roll = math.random(1, 100)
                  if roll <= 30 then
                      playerData_.money = playerData_.money + 500
                      playerData_.travelerLastGamble = "🎉 大吉！获得$500"
                  elseif roll <= 60 then
                      playerData_.reputation = playerData_.reputation + 30
                      playerData_.travelerLastGamble = "⭐ 中吉！声望+30"
                  elseif roll <= 85 then
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 20) end
                      playerData_.travelerLastGamble = "❤️ 小吉！全队心情+20"
                  else
                      playerData_.money = playerData_.money - 50
                      playerData_.travelerLastGamble = "💫 凶……破财$50，但也许是好事的前兆"
                  end
              end,
              resultFn = function() return playerData_.travelerLastGamble or "命运已经改变。" end },
            { type = "story", label = "🌀 听神话传说", desc = "约鲁巴创世神话（图鉴+1）", cost = 0,
              effect = function()
                  playerData_.travelerStoriesHeard = (playerData_.travelerStoriesHeard or 0) + 1
                  if LoreSystem and LoreSystem.OnStoryHeard then
                      pcall(LoreSystem.OnStoryHeard, "mystic")
                  end
              end,
              result = "Oba 讲述了奥杜杜瓦从天而降、创造大地的故事。仿佛空气中都弥漫着远古的力量。" },
        },
        departure = "命运之路已为你展开。勇敢走下去吧。",
    },
    {
        id = "mystic_mama_wata",
        name = "Mama Wata",
        title = "水之灵媒",
        emoji = "🧜‍♀️",
        origin = "尼日尔河",
        greeting = "水带来消息……你的网吧会有大事发生。我来帮你准备。",
        stayDays = 2,
        category = "mystic",
        minDay = 25,
        offers = {
            { type = "buy_boost", label = "💧 水之祝福", desc = "神秘仪式，全方位加成（收入+25%、客流+25%，持续3天）", cost = 350,
              effect = function()
                  playerData_.travelerBuffs = playerData_.travelerBuffs or {}
                  playerData_.travelerBuffs.income = { bonus = 0.25, daysLeft = 3 }
                  playerData_.travelerBuffs.traffic = { bonus = 0.25, daysLeft = 3 }
              end },
            { type = "gamble", label = "🌊 河流许愿", desc = "往尼日尔河许愿（可能获得大量哈弗币）", cost = 80,
              effect = function()
                  local roll = math.random(1, 100)
                  if roll <= 40 then
                      playerData_.havocCoins = (playerData_.havocCoins or 0) + 200
                      playerData_.travelerLastGamble = "🌊 河神回应！获得200哈弗币"
                  elseif roll <= 70 then
                      playerData_.havocCoins = (playerData_.havocCoins or 0) + 80
                      playerData_.travelerLastGamble = "💧 涟漪泛起……获得80哈弗币"
                  else
                      playerData_.travelerLastGamble = "🌀 水面平静。许愿币沉入河底……但心意已到"
                  end
              end,
              resultFn = function() return playerData_.travelerLastGamble or "水知道一切。" end },
        },
        departure = "记住——水总会找到出路。你也一样。",
    },
}

-- ============================================================================
-- 旅行者分类
-- ============================================================================
M.CATEGORIES = {
    { id = "trader", name = "商人", icon = "💰" },
    { id = "storyteller", name = "说书人", icon = "📖" },
    { id = "explorer", name = "探险家", icon = "🧭" },
    { id = "mystic", name = "神秘人", icon = "🔮" },
}

-- ============================================================================
-- 核心逻辑
-- ============================================================================

--- 每日结算：检查旅行者到达/离开
function M.OnDayEnd()
    if not playerData_ then return end
    local day = playerData_.day or 1

    -- 1) 递减现有buff天数
    M.TickBuffs()

    -- 2) 检查当前旅行者是否应离开
    local current = playerData_.currentTraveler
    if current then
        current.daysRemaining = (current.daysRemaining or 0) - 1
        if current.daysRemaining <= 0 then
            -- 旅行者离开
            AddLog(current.emoji .. " " .. current.name .. " 离开了：\"" .. (current.departure or "再见！") .. "\"")
            -- 记录到历史
            playerData_.travelerHistory = playerData_.travelerHistory or {}
            table.insert(playerData_.travelerHistory, {
                id = current.id, name = current.name, day = day,
            })
            playerData_.currentTraveler = nil
        end
    end

    -- 3) 如果没有旅行者，判断是否有新来的
    if not playerData_.currentTraveler then
        local lastVisitDay = playerData_.travelerLastVisitDay or 0
        local gap = day - lastVisitDay
        -- 间隔 3-6 天，概率递增
        local chance = 0
        if gap >= 6 then chance = 90
        elseif gap >= 5 then chance = 60
        elseif gap >= 4 then chance = 35
        elseif gap >= 3 then chance = 15
        end
        if day < 6 then chance = 0 end -- Day 6 前不来

        if math.random(1, 100) <= chance then
            M.SpawnTraveler(day)
        end
    end
end

--- 生成一个旅行者
function M.SpawnTraveler(day)
    -- 筛选可用旅行者（满足 minDay，且不是最近来过的）
    local recentIds = {}
    for _, h in ipairs(playerData_.travelerHistory or {}) do
        recentIds[h.id] = true
    end
    -- 只排除最近3位
    local history = playerData_.travelerHistory or {}
    local recentExclude = {}
    for i = math.max(1, #history - 2), #history do
        if history[i] then recentExclude[history[i].id] = true end
    end

    local candidates = {}
    for _, t in ipairs(M.TRAVELERS) do
        if day >= (t.minDay or 0) and not recentExclude[t.id] then
            table.insert(candidates, t)
        end
    end

    if #candidates == 0 then return end

    -- 随机选一个
    local chosen = candidates[math.random(1, #candidates)]
    playerData_.currentTraveler = {
        id = chosen.id,
        name = chosen.name,
        title = chosen.title,
        emoji = chosen.emoji,
        origin = chosen.origin,
        greeting = chosen.greeting,
        departure = chosen.departure,
        category = chosen.category,
        daysRemaining = chosen.stayDays or 1,
        offersUsed = {}, -- 标记已使用的 offer 索引
    }
    playerData_.travelerLastVisitDay = day

    AddLog(chosen.emoji .. " 旅行者 " .. chosen.name .. "（" .. chosen.title .. "）到访！来自" .. chosen.origin)
end

--- Buff 倒计时
function M.TickBuffs()
    local buffs = playerData_.travelerBuffs
    if not buffs then return end
    local toRemove = {}
    for key, buff in pairs(buffs) do
        buff.daysLeft = (buff.daysLeft or 0) - 1
        if buff.daysLeft <= 0 then
            table.insert(toRemove, key)
        end
    end
    for _, key in ipairs(toRemove) do
        buffs[key] = nil
    end
    -- 清空空表
    local hasAny = false
    for _ in pairs(buffs) do hasAny = true; break end
    if not hasAny then playerData_.travelerBuffs = nil end
end

--- 执行旅行者的某个 offer
---@param offerIdx number offer 索引（1-based）
---@return boolean success
---@return string result 结果文本
function M.UseOffer(offerIdx)
    local current = playerData_.currentTraveler
    if not current then return false, "没有旅行者在场" end

    -- 查找旅行者数据
    local travelerData = nil
    for _, t in ipairs(M.TRAVELERS) do
        if t.id == current.id then travelerData = t; break end
    end
    if not travelerData then return false, "旅行者数据丢失" end

    local offer = travelerData.offers[offerIdx]
    if not offer then return false, "无效选项" end

    -- 检查是否已使用
    if current.offersUsed[offerIdx] then
        return false, "已经使用过了"
    end

    -- 检查条件
    if offer.cond and not offer.cond() then
        return false, "条件不满足"
    end

    -- 检查费用
    if (offer.cost or 0) > 0 and playerData_.money < offer.cost then
        return false, "资金不足（需要$" .. offer.cost .. "）"
    end

    -- 扣费
    if (offer.cost or 0) > 0 then
        playerData_.money = playerData_.money - offer.cost
    end

    -- 执行效果
    if offer.effect then offer.effect() end

    -- 标记已使用
    current.offersUsed[offerIdx] = true

    -- 图鉴系统 hook
    if LoreSystem and LoreSystem.OnTravelerInteract then
        pcall(LoreSystem.OnTravelerInteract, current.id, current.category)
    end

    -- 返回结果文本
    local resultText = ""
    if offer.resultFn then
        resultText = offer.resultFn()
    elseif offer.result then
        resultText = offer.result
    else
        resultText = "交易完成！"
    end

    return true, resultText
end

-- ============================================================================
-- Buff 查询 API（供 TrainMatch / GameLogic 调用）
-- ============================================================================

--- 获取客流加成（百分比，如 0.3 表示+30%）
function M.GetTrafficBonus()
    local buffs = playerData_ and playerData_.travelerBuffs
    if not buffs or not buffs.traffic then return 0 end
    return buffs.traffic.bonus or 0
end

--- 获取收入加成
function M.GetIncomeBonus()
    local buffs = playerData_ and playerData_.travelerBuffs
    if not buffs or not buffs.income then return 0 end
    return buffs.income.bonus or 0
end

--- 获取训练效率加成
function M.GetTrainingBonus()
    local buffs = playerData_ and playerData_.travelerBuffs
    if not buffs or not buffs.training then return 0 end
    return buffs.training.bonus or 0
end

--- 获取比赛加成
function M.GetMatchBonus()
    local buffs = playerData_ and playerData_.travelerBuffs
    if not buffs or not buffs.match then return 0 end
    return buffs.match.bonus or 0
end

--- 获取招募品质加成
function M.GetRecruitBonus()
    local bonus = playerData_ and playerData_.travelerRecruitBonus or 0
    if bonus > 0 then
        playerData_.travelerRecruitBonus = bonus - 1  -- 消耗一次
        return 1
    end
    return 0
end

--- 当前是否有旅行者在场
function M.HasTraveler()
    return playerData_ and playerData_.currentTraveler ~= nil
end

--- 获取当前旅行者信息（用于 UI）
function M.GetCurrentTraveler()
    if not playerData_ then return nil end
    return playerData_.currentTraveler
end

--- 获取旅行者的完整 offer 数据（含 UI 显示所需信息）
function M.GetOffers()
    local current = playerData_ and playerData_.currentTraveler
    if not current then return {} end

    local travelerData = nil
    for _, t in ipairs(M.TRAVELERS) do
        if t.id == current.id then travelerData = t; break end
    end
    if not travelerData then return {} end

    local result = {}
    for i, offer in ipairs(travelerData.offers) do
        local used = current.offersUsed[i] or false
        local affordable = (offer.cost or 0) <= (playerData_.money or 0)
        local condMet = (not offer.cond) or offer.cond()
        table.insert(result, {
            idx = i,
            label = offer.label,
            desc = offer.desc,
            cost = offer.cost or 0,
            type = offer.type,
            used = used,
            affordable = affordable,
            condMet = condMet,
            available = (not used) and affordable and condMet,
        })
    end
    return result
end

--- 获取活跃 buff 列表（用于状态栏显示）
function M.GetActiveBuffs()
    local buffs = playerData_ and playerData_.travelerBuffs
    if not buffs then return {} end
    local result = {}
    local labels = {
        traffic = { icon = "📈", name = "客流" },
        income = { icon = "💰", name = "收入" },
        training = { icon = "🎯", name = "训练" },
        match = { icon = "🏆", name = "比赛" },
    }
    for key, buff in pairs(buffs) do
        local info = labels[key] or { icon = "✨", name = key }
        table.insert(result, {
            key = key,
            icon = info.icon,
            name = info.name,
            bonus = buff.bonus or 0,
            daysLeft = buff.daysLeft or 0,
        })
    end
    return result
end

--- 获取访问统计
function M.GetStats()
    local history = playerData_ and playerData_.travelerHistory or {}
    return {
        totalVisits = #history,
        storiesHeard = playerData_ and playerData_.travelerStoriesHeard or 0,
        itemsBought = playerData_ and playerData_.travelerItemsBought or 0,
    }
end

return M
