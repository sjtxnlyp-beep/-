---@diagnostic disable: undefined-global
-- ============================================================================
-- IdleEngine.lua — 挂机收益引擎
-- 核心公式：离线收益 = 每秒产出 × 离线秒数 × 离线效率 × 转生加成
-- ============================================================================

local IdleEngine = {}

-- ============================================================================
-- 1. 自动化等级定义（4 阶段）
-- ============================================================================
-- 自动化解锁链：每级自动执行一部分"在线操作"
-- Lv0 手忙脚乱期：纯手动，离线无产出
-- Lv1 初步自动化：自动收银（离线获得 30% 日收入）
-- Lv2 稳定运营：自动收银+自动维护（离线获得 50% 日收入）
-- Lv3 滚雪球期：全自动运营（离线获得 70% 日收入）
-- Lv4 连锁帝国：极致效率（离线获得 85% 日收入）

IdleEngine.AUTOMATION_TREE = {
    [0] = {
        name = "帮工小弟",
        icon = "🧹",
        desc = "门口的Kofi帮你看着店，走时顺便收了收钱",
        offlineRate = 0.20,  -- Lv0基础离线收益20%（帮工小弟保底，提升次留动力）
        effects = { "帮工小弟看店", "离线收益20%/小时" },
        unlockCost = 0,
        unlockDay = 0,
    },
    [1] = {
        name = "自动收银",
        icon = "💰",
        desc = "雇了个收银员，离线也能收钱",
        offlineRate = 0.30,
        effects = { "自动收取上机费", "离线收益30%/小时" },
        unlockCost = 500,
        unlockDay = 4,      -- 至少经营4天
        unlockReq = "经营满4天 + $500",
    },
    [2] = {
        name = "稳定运营",
        icon = "🔧",
        desc = "网管+收银，日常运营自动化",
        offlineRate = 0.50,
        effects = { "自动收银", "自动设备维护", "离线收益50%/小时" },
        unlockCost = 1500,
        unlockDay = 10,
        unlockReq = "经营满10天 + $1,500 + 自动收银Lv1",
    },
    [3] = {
        name = "滚雪球",
        icon = "🏪",
        desc = "店长全权管理，你只需决策",
        offlineRate = 0.70,
        effects = { "全自动运营", "自动购买燃油", "离线收益70%/小时" },
        unlockCost = 3500,
        unlockDay = 16,
        unlockReq = "经营满16天 + $3,500 + 稳定运营Lv2",
    },
    [4] = {
        name = "连锁帝国",
        icon = "👑",
        desc = "职业经理人团队，坐收渔利",
        offlineRate = 0.85,
        effects = { "极致自动化", "自动扩张分店", "离线收益85%/小时" },
        unlockCost = 8000,
        unlockDay = 22,
        unlockReq = "经营满22天 + $8,000 + 滚雪球Lv3 + 至少1家分店",
    },
}

-- ============================================================================
-- 2. 离线收益计算
-- ============================================================================

--- 计算每小时离线收益
--- @param dailyIncome number 当日在线收入
--- @param dailyExpense number 当日在线支出
--- @param autoLevel number 自动化等级 0-4
--- @param prestigeMulti number 转生加成倍率（默认1.0）
--- @return number hourlyEarning 每小时净离线收益
function IdleEngine.CalcHourlyOffline(dailyIncome, dailyExpense, autoLevel, prestigeMulti)
    autoLevel = autoLevel or 0
    prestigeMulti = prestigeMulti or 1.0

    local autoData = IdleEngine.AUTOMATION_TREE[autoLevel]
    if not autoData then return 0 end

    local rate = autoData.offlineRate

    -- P1: 跨模块软加成（升级/团队/装备/星级达标 → 额外离线率）
    local okSB, softBonus = pcall(GetAutomationSoftBonus, autoLevel)
    if okSB and type(softBonus) == "number" and softBonus > 0 then
        rate = rate + softBonus
    end

    -- Lv0 帮工小弟：只收钱不花钱，纯收益
    if autoLevel == 0 then
        local hourlyNet = math.floor((dailyIncome * rate) / 24)
        hourlyNet = hourlyNet * prestigeMulti
        return math.floor(math.max(0, hourlyNet))
    end

    -- 离线时支出也按比例降低（员工不加班、设备低功耗）
    local offlineExpenseRate = 0.4 + autoLevel * 0.1  -- Lv1:50%, Lv2:60%, Lv3:70%, Lv4:80%
    local hourlyNet = (dailyIncome * rate - dailyExpense * offlineExpenseRate) / 24

    -- 保底：至少不亏钱，最低0
    hourlyNet = math.max(0, hourlyNet)

    -- 转生加成
    hourlyNet = hourlyNet * prestigeMulti

    return math.floor(hourlyNet)
end

--- 计算总离线收益（玩家回归时调用）
--- @param offlineSeconds number 离线秒数
--- @param dailyIncome number 日收入
--- @param dailyExpense number 日支出
--- @param autoLevel number 自动化等级
--- @param prestigeMulti number 转生加成
--- @return number totalEarning 总离线收益
--- @return number hours 离线小时数（显示用）
--- @return number perHour 每小时收益（显示用）
--- @return number cappedHours 实际计算的小时数（可能被cap）
function IdleEngine.CalcOfflineEarnings(offlineSeconds, dailyIncome, dailyExpense, autoLevel, prestigeMulti)
    autoLevel = autoLevel or 0
    prestigeMulti = prestigeMulti or 1.0

    local rawHours = offlineSeconds / 3600
    -- P1-3：离线时长按自动化等级阶梯扩展
    -- Lv0=4h, Lv1=8h, Lv2=16h, Lv3=24h, Lv4=48h
    local maxHoursByLevel = { [0] = 4, [1] = 8, [2] = 16, [3] = 24, [4] = 48 }
    -- P1-2：名誉里程碑可增加离线上限
    local honorBonus = (playerData_ and playerData_.honorOfflineBonus) or 0
    local maxHours = (maxHoursByLevel[autoLevel] or 4) + honorBonus
    local cappedHours = math.min(rawHours, maxHours)

    local perHour = IdleEngine.CalcHourlyOffline(dailyIncome, dailyExpense, autoLevel, prestigeMulti)
    local total = perHour * cappedHours

    return math.floor(total), rawHours, perHour, cappedHours
end

-- ============================================================================
-- 3. 自动化解锁检查
-- ============================================================================

--- 检查是否可以解锁指定自动化等级
--- @param targetLevel number 目标等级
--- @return boolean canUnlock 是否可解锁
--- @return string reason 不可解锁的原因
function IdleEngine.CanUnlockAutomation(targetLevel)
    local current = (playerData_ and playerData_.automationLevel) or 0
    local data = IdleEngine.AUTOMATION_TREE[targetLevel]

    if not data then return false, "无效的等级" end
    if current >= targetLevel then return false, "已解锁" end
    if current < targetLevel - 1 then return false, "需要先解锁前置等级" end

    -- 检查天数
    if (playerData_.day or 1) < data.unlockDay then
        return false, "需要经营满" .. data.unlockDay .. "天"
    end

    -- 检查金钱
    if (playerData_.money or 0) < data.unlockCost then
        return false, "需要$" .. data.unlockCost
    end

    -- Lv4 额外条件：至少1家分店
    if targetLevel == 4 then
        if #(playerData_.branches or {}) < 1 then
            return false, "需要至少开设1家分店"
        end
    end

    return true, ""
end

--- 执行自动化升级
--- @param targetLevel number 目标等级
--- @return boolean success
function IdleEngine.UnlockAutomation(targetLevel)
    local canUnlock, reason = IdleEngine.CanUnlockAutomation(targetLevel)
    if not canUnlock then
        log:Write(LOG_WARNING, "[IdleEngine] Cannot unlock automation Lv" .. targetLevel .. ": " .. reason)
        return false
    end

    local data = IdleEngine.AUTOMATION_TREE[targetLevel]
    playerData_.money = playerData_.money - data.unlockCost
    playerData_.automationLevel = targetLevel

    AddLog("🤖 自动化升级！解锁「" .. data.name .. "」— " .. data.desc)
    if PlaySFX then PlaySFX("upgrade") end
    if TriggerCelebration then TriggerCelebration() end

    return true
end

-- ============================================================================
-- 4. 自动化每日效果（在 EndDay 中调用）
-- ============================================================================

--- 自动化每日被动效果
--- @return table|nil result 操作结果 { repairedAmount, fuelBought, fuelCost }
function IdleEngine.ApplyDailyAutomation()
    local level = (playerData_ and playerData_.automationLevel) or 0
    if level <= 0 then return nil end

    local result = { repairedAmount = 0, fuelBought = 0, fuelCost = 0 }

    -- Lv2+: 自动维护设备（每天恢复一点设备状况）
    if level >= 2 then
        local restore = 2 + level  -- Lv2:4, Lv3:5, Lv4:6
        local before = playerData_.equipCondition or 100
        playerData_.equipCondition = math.min(100, before + restore)
        result.repairedAmount = playerData_.equipCondition - before
    end

    -- Lv3+: 自动购买燃油（如果油量低于30%容量）
    if level >= 3 then
        local genLv = playerData_.generatorLevel or 0
        local fuelCap = playerData_.fuelCapacity or 0
        if genLv > 0 and fuelCap > 0 then
            local fuel = playerData_.fuel or 0
            if fuel < fuelCap * 0.3 then
                local buyAmount = math.floor(fuelCap * 0.5)
                local cost = buyAmount * 3  -- $3/升
                if playerData_.money >= cost then
                    playerData_.money = playerData_.money - cost
                    playerData_.fuel = math.min(fuelCap, fuel + buyAmount)
                    result.fuelBought = buyAmount
                    result.fuelCost = cost
                end
            end
        end
    end

    return result
end

-- ============================================================================
-- 5. 离线天数推进（离线超过24小时时，模拟多天结算）
-- ============================================================================

--- 模拟离线期间的多天结算
--- @param offlineHours number 离线小时数
--- @return number daysAdvanced 推进的天数
--- @return number totalEarnings 总离线收益
function IdleEngine.SimulateOfflineDays(offlineHours, dailyIncome, dailyExpense, autoLevel, prestigeMulti)
    autoLevel = autoLevel or (playerData_ and playerData_.automationLevel) or 0
    prestigeMulti = prestigeMulti or 1.0

    -- 最多推进7天（防止离线太久跳过太多内容）
    local maxDays = 7
    local daysToAdvance = math.min(maxDays, math.floor(offlineHours / 24))

    if daysToAdvance <= 0 then
        return 0, 0
    end

    local totalEarnings = 0
    local perHour = IdleEngine.CalcHourlyOffline(dailyIncome, dailyExpense, autoLevel, prestigeMulti)

    for _ = 1, daysToAdvance do
        local dayEarning = perHour * 24
        totalEarnings = totalEarnings + dayEarning
    end

    return daysToAdvance, math.floor(totalEarnings)
end

return IdleEngine
