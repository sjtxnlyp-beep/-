---@diagnostic disable: undefined-global
-- ============================================================================
-- ClimaxDay.lua — 高潮日系统
-- 周期性高能日：解锁限定行动（消耗AP）、收入倍率加成（cap 1.8）
-- 专家修正：不给免费AP，改为"解锁平时不可用的限定行动(cost AP)"
-- 互斥：危机链进行中不触发高潮日
-- ============================================================================

local ClimaxDay = {}

-- ============================================================================
-- 高潮日类型配置
-- ============================================================================
ClimaxDay.TYPES = {
    {
        id = "esports_fever",
        name = "电竞狂热日",
        icon = "🔥",
        desc = "全城电竞热潮！限时特训+挑战赛开启",
        unlockDay = 14,
        incomeMulti = 1.5,
        -- 限定行动（平时不可用，高潮日才能花AP执行）
        limitedActions = {
            { id = "intensive_drill", name = "强化特训", icon = "💪", cost = 1,
              desc = "密集训练，技能+8（平时+3~5）",
              effect = function()
                  for _, m in ipairs(teamMembers_) do
                      m.skill = math.min(150, (m.skill or 0) + 8)
                  end
                  if AddLog then AddLog("💪 强化特训完成！全队技能+8") end
              end },
            { id = "challenge_match", name = "挑战赛", icon = "⚔️", cost = 1,
              desc = "高额奖金挑战赛（奖励x2）",
              effect = function()
                  playerData_.money = (playerData_.money or 0) + 300
                  playerData_.reputation = (playerData_.reputation or 0) + 15
                  if AddLog then AddLog("⚔️ 挑战赛获胜！+$300 +15声望") end
              end },
        },
    },
    {
        id = "community_festival",
        name = "社区庆典日",
        icon = "🎉",
        desc = "街区节日！限时招募+声望翻倍",
        unlockDay = 18,
        incomeMulti = 1.3,
        limitedActions = {
            { id = "festival_recruit", name = "节日招募", icon = "🤝", cost = 1,
              desc = "庆典气氛中更容易说服人加入",
              effect = function()
                  playerData_.reputation = (playerData_.reputation or 0) + 25
                  if AddLog then AddLog("🤝 节日招募成功！+25声望") end
              end },
            { id = "community_show", name = "社区表演赛", icon = "🎭", cost = 1,
              desc = "在庆典上展示战队实力",
              effect = function()
                  playerData_.reputation = (playerData_.reputation or 0) + 20
                  playerData_.money = (playerData_.money or 0) + 150
                  if AddLog then AddLog("🎭 表演赛精彩！+$150 +20声望") end
              end },
        },
    },
    {
        id = "market_boom",
        name = "市场繁荣日",
        icon = "💰",
        desc = "经济大潮！限时投资+设备特价",
        unlockDay = 22,
        incomeMulti = 1.8,
        limitedActions = {
            { id = "bulk_purchase", name = "批量采购", icon = "🏪", cost = 1,
              desc = "市场特价日批量购入设备（省$200）",
              effect = function()
                  playerData_.computers = (playerData_.computers or 1) + 1
                  if AddLog then AddLog("🏪 特价采购！电脑+1（省$200）") end
              end },
            { id = "investor_meeting", name = "投资人会面", icon = "🤵", cost = 1,
              desc = "繁荣日容易吸引投资人",
              effect = function()
                  playerData_.money = (playerData_.money or 0) + 500
                  if AddLog then AddLog("🤵 投资人注资！+$500") end
              end },
        },
    },
    {
        id = "talent_surge",
        name = "人才涌现日",
        icon = "⭐",
        desc = "天才频出！限定选秀+队员突破",
        unlockDay = 28,
        incomeMulti = 1.2,
        limitedActions = {
            { id = "talent_scout", name = "天才发掘", icon = "🔍", cost = 1,
              desc = "发掘隐藏天才，随机队员技能+12",
              effect = function()
                  if #teamMembers_ > 0 then
                      local idx = math.random(1, #teamMembers_)
                      teamMembers_[idx].skill = math.min(150, (teamMembers_[idx].skill or 0) + 12)
                      if AddLog then AddLog("🔍 发现天才！" .. (teamMembers_[idx].name or "队员") .. " 技能+12") end
                  end
              end },
            { id = "team_bonding", name = "团建活动", icon = "🤗", cost = 1,
              desc = "全队心情恢复+提升凝聚力",
              effect = function()
                  for _, m in ipairs(teamMembers_) do
                      m.mood = math.min(100, (m.mood or 50) + 20)
                  end
                  if AddLog then AddLog("🤗 团建成功！全队心情+20") end
              end },
        },
    },
    {
        id = "media_spotlight",
        name = "媒体聚焦日",
        icon = "📺",
        desc = "记者来访！限时专访+品牌曝光",
        unlockDay = 35,
        incomeMulti = 1.6,
        limitedActions = {
            { id = "press_interview", name = "接受采访", icon = "🎤", cost = 1,
              desc = "媒体采访带来巨大声望",
              effect = function()
                  playerData_.reputation = (playerData_.reputation or 0) + 40
                  if AddLog then AddLog("🎤 采访播出！+40声望") end
              end },
            { id = "brand_deal", name = "品牌合作", icon = "🏷️", cost = 1,
              desc = "签署品牌赞助合同",
              effect = function()
                  playerData_.money = (playerData_.money or 0) + 400
                  playerData_.reputation = (playerData_.reputation or 0) + 10
                  if AddLog then AddLog("🏷️ 品牌合作签约！+$400 +10声望") end
              end },
        },
    },
}

-- ============================================================================
-- 核心逻辑
-- ============================================================================

--- 初始化/确保状态存在
function ClimaxDay.EnsureState()
    playerData_.climaxState = playerData_.climaxState or {
        history = {},           -- 已触发的高潮日 { [typeId] = dayNum }
        actionsUsed = {},       -- 今天已用的限定行动 { [actionId] = true }
        activeToday = nil,      -- 今天活跃的高潮日类型ID
        lastClimaxDay = 0,      -- 上次触发高潮日的天数（冷却用）
    }
end

--- 判断今天是否可以触发高潮日（在EndDay结束前调用，为明天做准备）
--- @return table|nil 如果明天可触发，返回高潮日类型配置
function ClimaxDay.TryTriggerForTomorrow()
    ClimaxDay.EnsureState()
    local state = playerData_.climaxState
    local day = playerData_.day or 1

    -- 互斥：危机链进行中不触发
    if playerData_.crisisState and playerData_.crisisState.active then
        return nil
    end

    -- 冷却：距离上次至少7天
    if day - (state.lastClimaxDay or 0) < 7 then
        return nil
    end

    -- 筛选可触发的类型（已解锁且满足概率）
    local candidates = {}
    for _, ct in ipairs(ClimaxDay.TYPES) do
        if day >= (ct.unlockDay or 999) then
            table.insert(candidates, ct)
        end
    end

    if #candidates == 0 then return nil end

    -- 触发概率：20%每天（冷却后）
    if math.random() > 0.20 then return nil end

    -- 随机选一个
    local chosen = candidates[math.random(1, #candidates)]

    -- 设置明天为高潮日
    state.activeToday = chosen.id
    state.actionsUsed = {}
    state.lastClimaxDay = day + 1
    state.history[chosen.id] = (state.history[chosen.id] or 0) + 1

    if AddLog then
        AddLog("🎆 【高潮日预告】明天是「" .. chosen.name .. "」！" .. chosen.desc)
    end

    return chosen
end

--- 获取今天活跃的高潮日（如果有）
--- @return table|nil 高潮日类型配置
function ClimaxDay.GetActiveToday()
    ClimaxDay.EnsureState()
    local state = playerData_.climaxState
    if not state.activeToday then return nil end

    for _, ct in ipairs(ClimaxDay.TYPES) do
        if ct.id == state.activeToday then return ct end
    end
    return nil
end

--- 判断是否是高潮日
function ClimaxDay.IsClimaxDay()
    return ClimaxDay.GetActiveToday() ~= nil
end

--- 获取今日收入倍率（已 cap 到 1.8）
function ClimaxDay.GetIncomeMultiplier()
    local ct = ClimaxDay.GetActiveToday()
    if not ct then return 1.0 end
    return math.min(1.8, ct.incomeMulti or 1.0)
end

--- 获取可用的限定行动列表
function ClimaxDay.GetAvailableActions()
    local ct = ClimaxDay.GetActiveToday()
    if not ct then return {} end

    ClimaxDay.EnsureState()
    local state = playerData_.climaxState
    local available = {}
    for _, action in ipairs(ct.limitedActions or {}) do
        if not state.actionsUsed[action.id] then
            table.insert(available, action)
        end
    end
    return available
end

--- 执行限定行动
--- @return boolean 是否成功
function ClimaxDay.ExecuteAction(actionId)
    local ct = ClimaxDay.GetActiveToday()
    if not ct then return false end

    ClimaxDay.EnsureState()
    local state = playerData_.climaxState

    -- 已用过
    if state.actionsUsed[actionId] then return false end

    -- 找到该行动
    local action = nil
    for _, a in ipairs(ct.limitedActions or {}) do
        if a.id == actionId then action = a; break end
    end
    if not action then return false end

    -- 消耗AP
    local cost = action.cost or 1
    if not UseActionPoint(cost) then return false end

    -- 执行效果
    if action.effect then
        local ok, err = pcall(action.effect)
        if not ok then
            print("[ClimaxDay] Action effect error: " .. tostring(err))
        end
    end

    -- 标记已用
    state.actionsUsed[actionId] = true
    return true
end

--- 清除今日高潮日状态（在EndDay时调用）
function ClimaxDay.ClearToday()
    ClimaxDay.EnsureState()
    local state = playerData_.climaxState
    state.activeToday = nil
    state.actionsUsed = {}
end

--- 高潮日是否阻止常规停电（高潮日不停电）
function ClimaxDay.BlocksBlackout()
    return ClimaxDay.IsClimaxDay()
end

return ClimaxDay
