---@diagnostic disable: undefined-global
-- ============================================================================
-- ReputationSystem.lua — 声望等级制 + 消耗出口 + 衰减机制
-- 声望 = 社会资本：能赚、能花、能失去
-- ============================================================================

local ReputationSystem = {}

-- ============================================================================
-- 1. 等级段定义
-- ============================================================================

ReputationSystem.TIERS = {
    { id = 1, min = 0,   max = 49,   name = "无名小卒", emoji = "👤",
      trafficBonus = 0,    incomeBonus = 0,    extraEffect = nil },
    { id = 2, min = 50,  max = 149,  name = "街坊邻居", emoji = "🏘️",
      trafficBonus = 0.15, incomeBonus = 0,    extraEffect = "解锁社区互助事件" },
    { id = 3, min = 150, max = 299,  name = "区域名人", emoji = "⭐",
      trafficBonus = 0.30, incomeBonus = 0.10, extraEffect = "赞助商合作·可邀请网红" },
    { id = 4, min = 300, max = 599,  name = "城市传奇", emoji = "🌟",
      trafficBonus = 0.50, incomeBonus = 0.20, extraEffect = "比赛费-50%·可招A/S级队员" },
    { id = 5, min = 600, max = 999999, name = "非洲之光", emoji = "👑",
      trafficBonus = 0.80, incomeBonus = 0.30, extraEffect = "停电概率-30%·传奇客户" },
}

--- 获取当前声望等级段
---@return table tier 当前等级段配置
function ReputationSystem.GetCurrentTier()
    local rep = (playerData_ and playerData_.reputation) or 0
    for i = #ReputationSystem.TIERS, 1, -1 do
        if rep >= ReputationSystem.TIERS[i].min then
            return ReputationSystem.TIERS[i]
        end
    end
    return ReputationSystem.TIERS[1]
end

--- 获取下一等级段（用于进度展示）
---@return table|nil nextTier
function ReputationSystem.GetNextTier()
    local current = ReputationSystem.GetCurrentTier()
    if current.id >= #ReputationSystem.TIERS then return nil end
    return ReputationSystem.TIERS[current.id + 1]
end

--- 获取声望等级段的客流乘数（1 + bonus）
---@return number multiplier
function ReputationSystem.GetTrafficMultiplier()
    local tier = ReputationSystem.GetCurrentTier()
    return 1.0 + tier.trafficBonus
end

--- 获取声望等级段的收入乘数（1 + bonus）
---@return number multiplier
function ReputationSystem.GetIncomeMultiplier()
    local tier = ReputationSystem.GetCurrentTier()
    return 1.0 + tier.incomeBonus
end

--- 获取等级段对停电概率的减免
---@return number reduction 0~0.3
function ReputationSystem.GetBlackoutReduction()
    local tier = ReputationSystem.GetCurrentTier()
    if tier.id >= 5 then return 0.30 end
    return 0
end

--- 获取等级段对比赛费用的减免
---@return number discount 0~0.5
function ReputationSystem.GetMatchFeeDiscount()
    local tier = ReputationSystem.GetCurrentTier()
    if tier.id >= 4 then return 0.50 end
    return 0
end

-- ============================================================================
-- 2. 声望消耗系统
-- ============================================================================

ReputationSystem.ACTIONS = {
    invite_influencer = {
        id = "invite_influencer",
        name = "邀请网红打卡",
        emoji = "📸",
        cost = 30,
        cooldown = 3,  -- 天
        minTier = 3,
        desc = "当天客流×2",
        execute = function()
            playerData_.reputation = playerData_.reputation - 30
            playerData_.repInfluencerDay = playerData_.day
            -- 客流翻倍效果存储在当天标记
            playerData_.influencerActiveDay = playerData_.day
            if AddLog then AddLog("📸 网红到店打卡！今日客流翻倍！（声望-30）") end
            return true
        end,
    },
    apply_subsidy = {
        id = "apply_subsidy",
        name = "申请政府补贴",
        emoji = "🏛️",
        cost = 60,
        cooldown = 7,
        minTier = 3,
        desc = "获得$500",
        execute = function()
            playerData_.reputation = playerData_.reputation - 60
            playerData_.money = playerData_.money + 500
            playerData_.repSubsidyDay = playerData_.day
            if AddLog then AddLog("🏛️ 政府中小企业补贴到账 $500！（声望-60）") end
            return true
        end,
    },
    unlock_vip = {
        id = "unlock_vip",
        name = "解锁VIP客户群",
        emoji = "💎",
        cost = 100,
        cooldown = 0,  -- 一次性
        minTier = 3,
        desc = "永久每日+$60",
        execute = function()
            if playerData_.repVipUnlocked then return false end
            playerData_.reputation = playerData_.reputation - 100
            playerData_.repVipUnlocked = true
            if AddLog then AddLog("💎 VIP客户群建立！每日稳定额外收入 +$60（声望-100）") end
            return true
        end,
    },
    challenge_bet = {
        id = "challenge_bet",
        name = "接受挑战赛",
        emoji = "🎲",
        cost = 30,  -- 基础押注
        cooldown = 4,
        minTier = 2,
        desc = "押注30声望，赢×2.5返还",
        execute = function()
            playerData_.reputation = playerData_.reputation - 30
            playerData_.repChallengeDay = playerData_.day
            -- 胜负由比赛系统判定，这里只扣押注
            playerData_.repChallengePending = true
            if AddLog then AddLog("🎲 接受街头挑战！押注30声望，赢了翻2.5倍！") end
            return true
        end,
    },
}

--- 检查某个声望消耗行动是否可用
---@param actionId string
---@return boolean available
---@return string reason
function ReputationSystem.CanDoAction(actionId)
    local action = ReputationSystem.ACTIONS[actionId]
    if not action then return false, "未知行动" end

    local rep = playerData_.reputation or 0
    local tier = ReputationSystem.GetCurrentTier()

    -- 等级段检查
    if tier.id < action.minTier then
        local reqTier = ReputationSystem.TIERS[action.minTier]
        return false, "需要达到「" .. reqTier.name .. "」（声望" .. reqTier.min .. "）"
    end

    -- 声望够不够
    if rep < action.cost then
        return false, "声望不足（需要" .. action.cost .. "，当前" .. rep .. "）"
    end

    -- 下限保护：消耗后不能跌破当前等级段下限
    local afterRep = rep - action.cost
    local currentTier = ReputationSystem.GetCurrentTier()
    if afterRep < currentTier.min then
        return false, "消耗后声望会跌破「" .. currentTier.name .. "」等级（下限" .. currentTier.min .. "）"
    end

    -- 一次性检查
    if actionId == "unlock_vip" and playerData_.repVipUnlocked then
        return false, "已解锁"
    end

    -- 冷却检查
    if action.cooldown > 0 then
        local lastDay = 0
        if actionId == "invite_influencer" then lastDay = playerData_.repInfluencerDay or 0
        elseif actionId == "apply_subsidy" then lastDay = playerData_.repSubsidyDay or 0
        elseif actionId == "challenge_bet" then lastDay = playerData_.repChallengeDay or 0
        end
        local daysSince = (playerData_.day or 1) - lastDay
        if daysSince < action.cooldown then
            return false, "冷却中（还需" .. (action.cooldown - daysSince) .. "天）"
        end
    end

    return true, ""
end

--- 执行声望消耗行动
---@param actionId string
---@return boolean success
---@return string message
function ReputationSystem.DoAction(actionId)
    local canDo, reason = ReputationSystem.CanDoAction(actionId)
    if not canDo then return false, reason end

    local action = ReputationSystem.ACTIONS[actionId]
    local ok = action.execute()
    if ok then
        if SaveGame then SaveGame() end
        return true, action.name .. "成功！"
    end
    return false, "执行失败"
end

-- ============================================================================
-- 3. 声望衰减系统（EndDay调用）
-- ============================================================================

--- 计算当天声望衰减
---@return number totalDecay 总衰减量
---@return table reasons 衰减原因列表
function ReputationSystem.CalcDailyDecay()
    local tier = ReputationSystem.GetCurrentTier()
    -- 等级1不衰减，保护新手
    if tier.id <= 1 then return 0, {} end

    local decay = 0
    local reasons = {}

    -- 设备状态差
    local ec = playerData_.equipCondition or 100
    if ec < 50 then
        local amount = 3
        decay = decay + amount
        table.insert(reasons, { amount = amount, desc = "设备老化（维护" .. ec .. "%）" })
    end

    -- 停电且无发电机
    if playerData_.blackoutToday and (playerData_.generatorLevel or 0) < 1 then
        local amount = 5
        decay = decay + amount
        table.insert(reasons, { amount = amount, desc = "停电无备用电源" })
    end

    -- 竞争对手抢客（rival系统已存在时）
    if rivalNpcs_ and #rivalNpcs_ > 0 then
        local strongRivals = 0
        local myPower = math.floor((playerData_.reputation or 0) / 5 + #(teamMembers_ or {}) * 10)
        for _, rival in ipairs(rivalNpcs_) do
            if (rival.power or 0) > myPower then strongRivals = strongRivals + 1 end
        end
        if strongRivals >= 2 then
            local amount = 5
            decay = decay + amount
            table.insert(reasons, { amount = amount, desc = "竞争对手压制" })
        end
    end

    -- 下限保护：不跌破当前等级段的下限
    local rep = playerData_.reputation or 0
    local floor = tier.min
    if rep - decay < floor then
        decay = math.max(0, rep - floor)
    end

    return decay, reasons
end

--- 应用每日声望衰减（在EndDay中调用）
---@return number actualDecay
function ReputationSystem.ApplyDailyDecay()
    local decay, reasons = ReputationSystem.CalcDailyDecay()
    if decay > 0 then
        playerData_.reputation = math.max(0, (playerData_.reputation or 0) - decay)
        -- 记录到日志
        local parts = {}
        for _, r in ipairs(reasons) do
            table.insert(parts, r.desc .. "(-" .. r.amount .. ")")
        end
        if AddLog and #parts > 0 then
            AddLog("📉 声望衰减 -" .. decay .. "：" .. table.concat(parts, "、"))
        end
    end
    return decay
end

-- ============================================================================
-- 4. 挑战赛结算（比赛后调用）
-- ============================================================================

--- 比赛结束后的声望影响
---@param won boolean 是否赢了
---@param isTournament boolean 是否正式锦标赛
function ReputationSystem.OnMatchResult(won, isTournament)
    if won then
        -- 挑战赛pending结算：返还×2.5
        if playerData_.repChallengePending then
            local reward = math.floor(30 * 2.5)  -- 75声望
            playerData_.reputation = (playerData_.reputation or 0) + reward
            playerData_.repChallengePending = false
            if AddLog then AddLog("🎲 挑战赛大胜！声望 +" .. reward .. "（2.5倍返还）") end
        end
    else
        -- 输了正式比赛扣声望
        if isTournament then
            local loss = 10
            local tier = ReputationSystem.GetCurrentTier()
            local rep = playerData_.reputation or 0
            -- 下限保护
            if rep - loss < tier.min then loss = math.max(0, rep - tier.min) end
            if loss > 0 then
                playerData_.reputation = rep - loss
                if AddLog then AddLog("😞 锦标赛败北，声望 -" .. loss) end
            end
        end
        -- 挑战赛pending失败：已扣除，不返还
        if playerData_.repChallengePending then
            playerData_.repChallengePending = false
            if AddLog then AddLog("🎲 挑战赛落败……押注的30声望打了水漂。") end
        end
    end
end

-- ============================================================================
-- 5. VIP客户每日收入（CalcDailyIncome中调用）
-- ============================================================================

--- 获取VIP客户群每日额外收入
---@return number income
function ReputationSystem.GetVipDailyIncome()
    if playerData_ and playerData_.repVipUnlocked then
        return 60
    end
    return 0
end

--- 网红打卡当天是否激活（客流×2）
---@return boolean active
function ReputationSystem.IsInfluencerActive()
    if not playerData_ then return false end
    return (playerData_.influencerActiveDay or 0) == (playerData_.day or 0)
end

-- ============================================================================
-- 6. 招募等级限制（高星队员需要声望消耗）
-- ============================================================================

--- 检查是否可以招募指定等级的队员
---@param memberRank string "A" | "S" | 其他
---@return boolean canRecruit
---@return number cost 需要消耗的声望
---@return string reason
function ReputationSystem.GetRecruitCost(memberRank)
    local tier = ReputationSystem.GetCurrentTier()
    local rep = playerData_.reputation or 0

    if memberRank == "S" then
        if tier.id < 4 then return false, 80, "需要「城市传奇」等级（声望300+）" end
        if rep < 80 then return false, 80, "声望不足（需80）" end
        if rep - 80 < tier.min then return false, 80, "消耗后会掉级" end
        return true, 80, ""
    elseif memberRank == "A" then
        if tier.id < 4 then return false, 40, "需要「城市传奇」等级（声望300+）" end
        if rep < 40 then return false, 40, "声望不足（需40）" end
        if rep - 40 < tier.min then return false, 40, "消耗后会掉级" end
        return true, 40, ""
    end

    -- B级及以下不需要声望
    return true, 0, ""
end

--- 扣除招募声望费用
---@param memberRank string
---@return boolean success
function ReputationSystem.PayRecruitCost(memberRank)
    local canDo, cost, _ = ReputationSystem.GetRecruitCost(memberRank)
    if not canDo then return false end
    if cost > 0 then
        playerData_.reputation = (playerData_.reputation or 0) - cost
        if AddLog then AddLog("⭐ 招募高星队员，声望消耗 -" .. cost) end
    end
    return true
end

-- ============================================================================
-- 7. 进度信息（UI展示用）
-- ============================================================================

--- 获取声望进度摘要（用于紧凑UI展示）
---@return table info { tier, tierName, emoji, rep, nextReq, progress01, nextName }
function ReputationSystem.GetProgressInfo()
    local rep = (playerData_ and playerData_.reputation) or 0
    local tier = ReputationSystem.GetCurrentTier()
    local nextTier = ReputationSystem.GetNextTier()

    local progress = 0
    local nextReq = 0
    local nextName = "已满级"
    if nextTier then
        nextReq = nextTier.min
        local range = nextReq - tier.min
        local current = rep - tier.min
        progress = range > 0 and (current / range) or 1.0
        nextName = nextTier.name
    else
        progress = 1.0
    end

    return {
        tier = tier.id,
        tierName = tier.name,
        emoji = tier.emoji,
        rep = rep,
        nextReq = nextReq,
        progress01 = math.min(1.0, math.max(0, progress)),
        nextName = nextName,
        trafficBonus = tier.trafficBonus,
        incomeBonus = tier.incomeBonus,
    }
end

-- ============================================================================
-- 8. 获取可用行动列表（UI用）
-- ============================================================================

--- 返回所有声望消耗行动及其当前状态
---@return table[] actions { id, name, icon, cost, desc, canDo, reason }
function ReputationSystem.GetAvailableActions()
    local result = {}
    local actionOrder = { "invite_influencer", "apply_subsidy", "unlock_vip", "challenge_bet" }
    for _, actionId in ipairs(actionOrder) do
        local action = ReputationSystem.ACTIONS[actionId]
        if action then
            local canDo, reason = ReputationSystem.CanDoAction(actionId)
            table.insert(result, {
                id = action.id,
                name = action.name,
                icon = action.emoji,
                cost = action.cost,
                desc = action.desc,
                canDo = canDo,
                reason = reason or "",
            })
        end
    end
    return result
end

return ReputationSystem
