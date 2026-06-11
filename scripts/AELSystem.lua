-- ============================================================================
-- AELSystem.lua — P2: AEL(非洲电竞联赟)赞助体系
-- 提供中后期(D14+)外部目标感 + 被动收入 + 周期任务
-- ============================================================================

local AELSystem = {}

-- ── 赞助等级定义 ──
AELSystem.TIERS = {
    [1] = {
        name = "铜牌赞助", icon = "🥉",
        dailyIncome = 30,
        bonus = "训练效率+10%",
        bonusKey = "trainBoost", bonusValue = 0.10,
        unlockRep = 80, unlockDay = 14, unlockWins = 0,
    },
    [2] = {
        name = "银牌赞助", icon = "🥈",
        dailyIncome = 80,
        bonus = "设备折扣20%",
        bonusKey = "equipDiscount", bonusValue = 0.20,
        unlockRep = 150, unlockDay = 20, unlockWins = 2,
    },
    [3] = {
        name = "金牌赞助", icon = "🥇",
        dailyIncome = 150,
        bonus = "解锁AEL国际赛名额",
        bonusKey = "internationalAccess", bonusValue = true,
        unlockRep = 250, unlockDay = 26, unlockWins = 4,
    },
}

-- ── 周任务池(按赞助等级) ──
local WEEKLY_TASKS = {
    [1] = {
        { id = "win_match", desc = "本周赢得1场比赛", icon = "🏆",
          check = function() return (playerData_.weeklyWins or 0) >= 1 end },
        { id = "train_5", desc = "本周训练5次以上", icon = "💪",
          check = function() return (playerData_.weeklyTrainCount or 0) >= 5 end },
        { id = "income_500", desc = "本周累计收入≥$500", icon = "💰",
          check = function() return (playerData_.weeklyIncome or 0) >= 500 end },
    },
    [2] = {
        { id = "skill_80", desc = "培养1名技能≥80的队员", icon = "⭐",
          check = function()
              for _, m in ipairs(teamMembers_ or {}) do
                  if (m.skill or 0) >= 80 then return true end
              end
              return false
          end },
        { id = "income_1000", desc = "本周累计收入≥$1000", icon = "💎",
          check = function() return (playerData_.weeklyIncome or 0) >= 1000 end },
        { id = "rep_up_20", desc = "本周声望增长≥20", icon = "📈",
          check = function() return (playerData_.weeklyRepGain or 0) >= 20 end },
    },
    [3] = {
        { id = "avg_skill_100", desc = "全队平均技能≥100", icon = "🌟",
          check = function()
              if not teamMembers_ or #teamMembers_ == 0 then return false end
              local total = 0
              for _, m in ipairs(teamMembers_) do total = total + (m.skill or 0) end
              return (total / #teamMembers_) >= 100
          end },
        { id = "rep_250", desc = "声望达到250", icon = "👑",
          check = function() return (playerData_.reputation or 0) >= 250 end },
        { id = "win_streak_2", desc = "本周连赢2场", icon = "🔥",
          check = function() return (playerData_.weeklyWinStreak or 0) >= 2 end },
    },
}

--- 获取当前AEL赞助信息
---@return table { tier, name, icon, dailyIncome, bonus, tasks, tasksDone, nextTier }
function AELSystem.GetInfo()
    local tier = playerData_.aelTier or 0
    if tier == 0 then
        return { tier = 0, name = "未签约", icon = "📋", dailyIncome = 0 }
    end

    local def = AELSystem.TIERS[tier]
    local tasks = WEEKLY_TASKS[tier] or {}
    local doneCount = 0
    local taskStatus = {}
    for _, t in ipairs(tasks) do
        local done = t.check and t.check() or false
        if done then doneCount = doneCount + 1 end
        table.insert(taskStatus, { desc = t.desc, icon = t.icon, done = done })
    end

    -- 下一级信息
    local nextDef = AELSystem.TIERS[tier + 1]

    return {
        tier = tier,
        name = def.name,
        icon = def.icon,
        dailyIncome = def.dailyIncome,
        bonus = def.bonus,
        tasks = taskStatus,
        tasksDone = doneCount,
        tasksTotal = #tasks,
        nextTier = nextDef,
    }
end

--- 每日结算：获取AEL赞助收入
---@return number 今日AEL赞助收入
function AELSystem.GetDailyIncome()
    local tier = playerData_.aelTier or 0
    if tier == 0 then return 0 end
    local def = AELSystem.TIERS[tier]
    return def and def.dailyIncome or 0
end

--- 获取训练效率加成(由AEL赞助提供)
---@return number 0.0-1.0 之间的加成比例
function AELSystem.GetTrainBoost()
    local tier = playerData_.aelTier or 0
    if tier == 0 then return 0 end
    local def = AELSystem.TIERS[tier]
    if def and def.bonusKey == "trainBoost" then
        return def.bonusValue
    end
    -- 高级别也保留低级别的加成
    if tier >= 1 then return AELSystem.TIERS[1].bonusValue end
    return 0
end

--- 获取设备折扣(银牌+)
---@return number 0.0-1.0 折扣比例
function AELSystem.GetEquipDiscount()
    local tier = playerData_.aelTier or 0
    if tier >= 2 then
        return AELSystem.TIERS[2].bonusValue
    end
    return 0
end

--- 检查是否可以升级赞助等级
---@return table|nil 下一级定义(可升级时) 或 nil
function AELSystem.CheckUpgrade()
    local tier = playerData_.aelTier or 0
    local nextTier = tier + 1
    local def = AELSystem.TIERS[nextTier]
    if not def then return nil end

    local day = playerData_.day or 0
    local rep = playerData_.reputation or 0
    local wins = playerData_.tournamentWins or 0

    if day >= def.unlockDay and rep >= def.unlockRep and wins >= def.unlockWins then
        return def
    end
    return nil
end

--- 每周重置计数器(在 EndDay day%7==0 时调用)
function AELSystem.WeeklyReset()
    playerData_.weeklyWins = 0
    playerData_.weeklyTrainCount = 0
    playerData_.weeklyIncome = 0
    playerData_.weeklyRepGain = 0
    playerData_.weeklyWinStreak = 0
end

--- EndDay 中调用：处理AEL每日逻辑
---@return number aelIncome 今日AEL赞助收入
function AELSystem.OnEndDay()
    local aelIncome = AELSystem.GetDailyIncome()
    if aelIncome > 0 then
        playerData_.money = playerData_.money + aelIncome
        if AddLog then
            AddLog("🏆 AEL赞助收入 +$" .. aelIncome)
        end
    end

    -- 累计本周收入(用于周任务检查)
    -- 注：weeklyIncome 由 EndDay 在计算总收入时更新，这里不重复加

    -- 周任务自动检查升级(每7天)
    if (playerData_.day or 0) % 7 == 0 then
        AELSystem.WeeklyReset()
    end

    return aelIncome
end

return AELSystem
