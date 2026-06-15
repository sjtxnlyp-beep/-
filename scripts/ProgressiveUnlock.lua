---@diagnostic disable: undefined-global
-- ============================================================================
-- ProgressiveUnlock.lua — 渐进解锁系统（v2：天数 + 剧情事件双条件）
-- 控制Tab、Action页元素、系统功能的逐Day解锁
-- Tab 解锁绑定关键剧情节点，让进度更有叙事感
-- ============================================================================

local M = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- 解锁条件定义
-- day: 最低天数（必须满足）
-- story: 剧情事件ID（可选。若设定则该事件必须已触发）
-- storyAny: 剧情事件ID数组（任一触发即满足）
-- fallbackDay: 兜底天数（超过此天数即使剧情未触发也强制解锁，防卡关）
-- ══════════════════════════════════════════════════════════════════════════════

M.UNLOCK_RULES = {
    -- ═══ Action面板内Tab ═══
    -- 街区Tab：Day 4 + 完成"集市初探"（或 Day 6 兜底）
    tab_hood = { day = 4, story = "first_market_visit", fallbackDay = 6 },
    -- 战队Tab：Day 3 + Kofi加入事件（或 Day 5 兜底）
    tab_team_action = { day = 3, story = "kofi_joined", fallbackDay = 5 },
    -- 风险/投资Tab：Day 7 + 任一金融相关事件（或 Day 12 兜底）
    tab_risk = { day = 7, storyAny = { "big_joe_intro", "first_gold_trade", "merchant_visit" }, fallbackDay = 12 },

    -- ═══ 管理面板Tab ═══
    tab_upgrade     = { day = 2 },  -- Day 2 自动解锁（基础功能无需剧情门控）
    tab_team        = { day = 3, story = "kofi_joined", fallbackDay = 5 },
    tab_market      = { day = 5, story = "merchant_visit", fallbackDay = 7 },
    tab_automation  = { day = 8 },
    tab_collection  = { day = 7 },
    tab_ranking     = { day = 10 },

    -- ═══ Action页元素 ═══
    btn_recruit     = { day = 2, story = "kofi_joined", fallbackDay = 4 },
    btn_match       = { day = 3 },
    btn_train       = { day = 3 },
    btn_market_visit = { day = 4, story = "first_market_visit", fallbackDay = 6 },
    btn_flyers      = { day = 1 },

    -- ═══ Action页条件面板 ═══
    panel_quest     = { day = 5 },
    panel_gold      = { day = 12 },
    panel_branch    = { day = 12 },
    panel_sidejob   = { day = 6 },
    panel_sponsor   = { day = 5 },
    panel_social    = { day = 4 },
    panel_maintain  = { day = 3 },

    -- ═══ 其他系统 ═══
    ad_banner       = { day = 3 },
    strategy_card   = { day = 4 },
    advisor_tip     = { day = 3 },
    micro_events    = { day = 4 },
    goal_chain      = { day = 5 },
    golden_hour     = { day = 5 },
    prestige_preview = { day = 10 },
    season_pass     = { day = 7 },
    offline_hint    = { day = 3 },
}

-- 兼容旧的 UNLOCK_DAY 接口（只读）
M.UNLOCK_DAY = setmetatable({}, {
    __index = function(_, key)
        local rule = M.UNLOCK_RULES[key]
        if rule then return rule.day end
        return nil
    end
})

-- ══════════════════════════════════════════════════════════════════════════════
-- 剧情事件完成记录
-- playerData_.storyCompleted = { ["event_id"] = true, ... }
-- ══════════════════════════════════════════════════════════════════════════════

--- 标记某个剧情事件为已完成
---@param eventId string
function M.MarkStoryCompleted(eventId)
    if not playerData_ then return end
    if not playerData_.storyCompleted then
        playerData_.storyCompleted = {}
    end
    playerData_.storyCompleted[eventId] = true
end

--- 检查某个剧情事件是否已完成
---@param eventId string
---@return boolean
function M.IsStoryCompleted(eventId)
    if not playerData_ then return false end
    if not playerData_.storyCompleted then return false end
    return playerData_.storyCompleted[eventId] == true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- 核心解锁判定
-- ══════════════════════════════════════════════════════════════════════════════

--- 检查某个feature是否已解锁
---@param featureKey string
---@return boolean
function M.IsUnlocked(featureKey)
    local day = playerData_ and playerData_.day or 1
    local rule = M.UNLOCK_RULES[featureKey]

    -- 未定义规则 → 默认解锁
    if not rule then return true end

    -- 天数条件：必须满足
    if day < rule.day then return false end

    -- 兜底天数：超过此天数强制解锁（防卡关）
    if rule.fallbackDay and day >= rule.fallbackDay then return true end

    -- 剧情条件：story（单个事件必须完成）
    if rule.story then
        return M.IsStoryCompleted(rule.story)
    end

    -- 剧情条件：storyAny（任一事件完成即可）
    if rule.storyAny then
        for _, eid in ipairs(rule.storyAny) do
            if M.IsStoryCompleted(eid) then return true end
        end
        return false
    end

    -- 无剧情条件，纯天数判定已通过
    return true
end

--- 获取解锁进度描述（用于锁定状态显示）
---@param featureKey string
---@return string|nil 描述文本
function M.GetLockReason(featureKey)
    local day = playerData_ and playerData_.day or 1
    local rule = M.UNLOCK_RULES[featureKey]
    if not rule then return nil end

    if day < rule.day then
        return "Day " .. rule.day .. " 解锁"
    end

    -- 天数够了但剧情没触发
    local storyHints = {
        kofi_joined       = "等待Kofi加入后解锁",
        first_market_visit = "首次探访集市后解锁",
        merchant_visit    = "商人来访后解锁",
        big_joe_intro     = "遇到Big Joe后解锁",
        first_gold_trade  = "首次黄金交易后解锁",
    }

    if rule.story and not M.IsStoryCompleted(rule.story) then
        return storyHints[rule.story] or "完成关键剧情后解锁"
    end

    if rule.storyAny then
        for _, eid in ipairs(rule.storyAny) do
            if storyHints[eid] then
                return storyHints[eid]
            end
        end
        return "完成关键剧情后解锁"
    end

    return nil
end

--- 获取当前可见的Tab列表（管理面板用）
---@return table[] tabs Array of {key, icon, label}
function M.GetVisibleTabs()
    local tabs = {
        { key = "action", icon = "🏠", label = "经营" }, -- 始终可见
    }
    if M.IsUnlocked("tab_upgrade") then
        table.insert(tabs, { key = "upgrade", icon = "⬆", label = "升级" })
    end
    if M.IsUnlocked("tab_team") then
        table.insert(tabs, { key = "team", icon = "👥", label = "团队" })
    end
    if M.IsUnlocked("tab_market") then
        table.insert(tabs, { key = "market", icon = "🛒", label = "市场" })
    end
    if M.IsUnlocked("tab_automation") then
        table.insert(tabs, { key = "automation", icon = "🤖", label = "自动化" })
    end
    if M.IsUnlocked("tab_collection") then
        table.insert(tabs, { key = "collection", icon = "📖", label = "图鉴" })
    end
    if M.IsUnlocked("tab_ranking") then
        table.insert(tabs, { key = "ranking", icon = "🏆", label = "排行榜" })
    end
    return tabs
end

--- 获取解锁提示文本（用于新Tab解锁时的动画提示）
---@param featureKey string
---@return string|nil description
function M.GetUnlockHint(featureKey)
    local hints = {
        tab_upgrade    = "设备需要维护了！解锁「升级」功能",
        tab_team       = "Kofi加入了战队！解锁「团队」管理",
        tab_market     = "商人带来了好货！解锁「市场」",
        tab_automation = "你太累了...解锁「自动化」经营",
        tab_collection = "你的经历值得记录！解锁「图鉴」",
        tab_ranking    = "首场联赛开始！解锁「排行榜」",
        tab_hood       = "附近的街区等你探索！解锁「街区」",
        tab_risk       = "高风险高回报！解锁「投资」",
        tab_team_action = "战队需要你！解锁「战队」操作",
        btn_recruit    = "有人想加入你的战队！",
        btn_match      = "准备好参加第一场比赛了！",
    }
    return hints[featureKey]
end

--- 检查并触发解锁通知（每天调用一次）
---@return string|nil unlockMessage 如果今天有新解锁，返回提示信息
function M.CheckDailyUnlocks()
    -- 初始化已通知列表
    if not playerData_.unlocksNotified then
        playerData_.unlocksNotified = {}
    end

    -- 检查所有有 hint 的 feature
    local checkKeys = {
        "tab_upgrade", "tab_team", "tab_market", "tab_automation",
        "tab_collection", "tab_ranking", "tab_hood", "tab_risk", "tab_team_action",
    }
    for _, key in ipairs(checkKeys) do
        if M.IsUnlocked(key) and not playerData_.unlocksNotified[key] then
            playerData_.unlocksNotified[key] = true
            local hint = M.GetUnlockHint(key)
            if hint then return hint end
        end
    end
    return nil
end

return M
