---@diagnostic disable: undefined-global
-- ============================================================================
-- ProgressiveUnlock.lua — 渐进解锁系统
-- 控制Tab、Action页元素、系统功能的逐Day解锁
-- P0-1 + P0-2 核心实现
-- ============================================================================

local M = {}

-- ── 解锁时间表 ──
-- 每个feature对应解锁所需的最低天数
M.UNLOCK_DAY = {
    -- Tabs
    tab_upgrade     = 2,   -- 升级Tab: Day 2（"键盘坏了"事件后解锁）
    tab_team        = 3,   -- 团队Tab: Day 3（Kofi加入后）
    tab_market      = 5,   -- 市场Tab: Day 5（商人剧情后）
    tab_automation  = 8,   -- 自动化Tab: Day 8
    tab_collection  = 7,   -- 图鉴Tab: Day 7
    tab_ranking     = 10,  -- 排行榜Tab: Day 10

    -- Action页元素
    btn_recruit     = 2,   -- 招募按钮: Day 2（Kofi主动上门）
    btn_match       = 3,   -- 比赛按钮: Day 3
    btn_train       = 3,   -- 训练按钮: Day 3
    btn_market_visit = 4,  -- 逛集市: Day 4
    btn_flyers      = 1,   -- 贴传单: Day 1（保留）

    -- Action页条件面板
    panel_quest     = 5,   -- 每日委托: Day 5（原为Day 10，提前）
    panel_gold      = 12,  -- 黄金交易: Day 12
    panel_branch    = 12,  -- 分店: Day 12
    panel_sidejob   = 6,   -- 副业: Day 6
    panel_social    = 4,   -- 社交: Day 4
    panel_maintain  = 3,   -- 设备维护: Day 3

    -- 其他系统
    ad_banner       = 3,   -- 广告条: Day 3+
    strategy_card   = 4,   -- 策略卡: Day 4+
    advisor_tip     = 3,   -- 顾问建议: Day 3+
    micro_events    = 4,   -- 微事件: Day 4+
    goal_chain      = 5,   -- 目标链: Day 5+
    golden_hour     = 5,   -- 黄金时段: Day 5+
    prestige_preview = 10, -- 转生预览: Day 10+
    season_pass     = 7,   -- 赛季通行证: Day 7+
    offline_hint    = 3,   -- 离线收入提示: Day 3+
}

--- 检查某个feature是否已解锁
---@param featureKey string
---@return boolean
function M.IsUnlocked(featureKey)
    local day = playerData_ and playerData_.day or 1
    local requiredDay = M.UNLOCK_DAY[featureKey]
    if not requiredDay then return true end -- 未定义的默认解锁
    return day >= requiredDay
end

--- 获取当前可见的Tab列表
---@return table[] tabs Array of {key, icon, label}
function M.GetVisibleTabs()
    local day = playerData_ and playerData_.day or 1
    local tabs = {
        { key = "action", icon = "🏠", label = "经营" }, -- 始终可见
    }
    if day >= M.UNLOCK_DAY.tab_upgrade then
        table.insert(tabs, { key = "upgrade", icon = "⬆", label = "升级" })
    end
    if day >= M.UNLOCK_DAY.tab_team then
        table.insert(tabs, { key = "team", icon = "👥", label = "团队" })
    end
    if day >= M.UNLOCK_DAY.tab_market then
        table.insert(tabs, { key = "market", icon = "🛒", label = "市场" })
    end
    if day >= M.UNLOCK_DAY.tab_automation then
        table.insert(tabs, { key = "automation", icon = "🤖", label = "自动化" })
    end
    if day >= M.UNLOCK_DAY.tab_collection then
        table.insert(tabs, { key = "collection", icon = "📖", label = "图鉴" })
    end
    if day >= M.UNLOCK_DAY.tab_ranking then
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
        btn_recruit    = "有人想加入你的战队！",
        btn_match      = "准备好参加第一场比赛了！",
    }
    return hints[featureKey]
end

--- 检查并触发解锁通知（每天调用一次）
---@return string|nil unlockMessage 如果今天有新解锁，返回提示信息
function M.CheckDailyUnlocks()
    local day = playerData_ and playerData_.day or 1
    -- 初始化已通知列表
    if not playerData_.unlocksNotified then
        playerData_.unlocksNotified = {}
    end

    -- 检查今天是否有新解锁的Tab
    local tabKeys = { "tab_upgrade", "tab_team", "tab_market", "tab_automation", "tab_collection", "tab_ranking" }
    for _, key in ipairs(tabKeys) do
        if day == M.UNLOCK_DAY[key] and not playerData_.unlocksNotified[key] then
            playerData_.unlocksNotified[key] = true
            return M.GetUnlockHint(key)
        end
    end
    return nil
end

return M
