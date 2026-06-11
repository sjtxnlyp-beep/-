---@diagnostic disable: undefined-global
-- ============================================================================
-- PrestigeSystem.lua — 转生/连锁扩张系统
-- 核心循环：本地积累 → 触发转生 → 重置本地 → 获得永久加成 → 解锁新城市
-- ============================================================================

local PrestigeSystem = {}

-- ============================================================================
-- 1. 城市扩张路线（转生目标城市）
-- ============================================================================
-- 每次转生 = 在新城市开一家网吧，获得永久商会名誉加成
-- 瓦坎达维尔(起始) → 拉各斯 → 内罗毕 → 阿克拉 → 达喀尔 → 开普敦 → 金沙萨

PrestigeSystem.CITIES = {
    { id = "wakandaville", name = "瓦坎达维尔", emoji = "🏘️",
      desc = "一切开始的地方——铁皮屋、红土路、Dragon Net Cafe",
      prestigeReq = 0,           -- 解锁所需商会名誉
      incomeMulti = 1.0,         -- 城市收入倍率
      difficultyTag = "起始城市",
    },
    { id = "lagos", name = "拉各斯", emoji = "🏙️",
      desc = "尼日利亚商业首都，2000万人口的超级城市",
      prestigeReq = 100,
      incomeMulti = 1.3,
      difficultyTag = "高客流·高租金",
      specialBonus = "客流量+30%",
    },
    { id = "nairobi", name = "内罗毕", emoji = "🌆",
      desc = "东非硅谷，科技创业氛围浓厚",
      prestigeReq = 300,
      incomeMulti = 1.2,
      difficultyTag = "科技加成·竞争激烈",
      specialBonus = "升级费用-15%",
    },
    { id = "accra", name = "阿克拉", emoji = "🎓",
      desc = "加纳文化教育中心，大学城",
      prestigeReq = 600,
      incomeMulti = 1.15,
      difficultyTag = "声望获取+25%",
      specialBonus = "每日声望+10",
    },
    { id = "dakar", name = "达喀尔", emoji = "🌊",
      desc = "大西洋畔港口城市，贸易枢纽",
      prestigeReq = 1000,
      incomeMulti = 1.25,
      difficultyTag = "贸易加成·季风影响",
      specialBonus = "黄金交易收益+20%",
    },
    { id = "capetown", name = "开普敦", emoji = "⛰️",
      desc = "非洲电竞之都，基础设施最佳",
      prestigeReq = 1800,
      incomeMulti = 1.4,
      difficultyTag = "电竞天堂·巅峰挑战",
      specialBonus = "比赛奖金+30%",
    },
    { id = "kinshasa", name = "金沙萨", emoji = "🥁",
      desc = "音乐之城，终极隐藏城市",
      prestigeReq = 3000,
      incomeMulti = 1.5,
      difficultyTag = "终极挑战·传奇之路",
      specialBonus = "全属性+10%",
    },
}

-- ============================================================================
-- 2. 转生收益计算
-- ============================================================================

--- 计算当前进度可获得的商会名誉
--- 公式：基础 = sqrt(总收入/1000) × 10 + 分店数×15 + 锦标赛冠军×25
--- @return number prestige 可获得的商会名誉
--- @return table breakdown 明细
function PrestigeSystem.CalcPrestigeGain()
    local totalEarnings = playerData_.totalEarnings or 0
    local branchCount = #(playerData_.branches or {})
    local tournamentWins = playerData_.tournamentWins or 0
    local day = playerData_.day or 1
    local reputation = playerData_.reputation or 0

    -- 各项贡献
    local earningsPart = math.floor(math.sqrt(totalEarnings / 1000) * 10)
    local branchPart = branchCount * 15
    local tournamentPart = tournamentWins * 25
    local dayPart = math.floor(day / 4) * 3  -- 每4天贡献3点（3.2 缩短周期补偿）
    local repPart = math.floor(reputation / 50) * 5  -- 每50声望贡献5点

    local total = earningsPart + branchPart + tournamentPart + dayPart + repPart

    -- 连续转生加成（每次转生+5%产出加成，上限+50%）
    local prestigeCount = (playerData_.prestigeCount or 0)
    local chainBonus = math.min(0.5, prestigeCount * 0.05)
    total = math.floor(total * (1 + chainBonus))

    return total, {
        earnings = earningsPart,
        branches = branchPart,
        tournaments = tournamentPart,
        days = dayPart,
        reputation = repPart,
        chainBonus = math.floor(chainBonus * 100),
    }
end

--- 计算转生后的永久加成倍率
--- @return number multi 总收入倍率
function PrestigeSystem.CalcPrestigeMultiplier()
    local honor = (playerData_ and playerData_.prestigeHonor) or 0
    -- 每100名誉 = +30% 收入，400名誉=2x，667名誉达上限3.0x（约5~8次转生可感知）
    local multi = 1.0 + math.min(2.0, honor / 100 * 0.3)
    return multi
end

--- 计算离线收益的转生加成
function PrestigeSystem.GetOfflineMultiplier()
    return PrestigeSystem.CalcPrestigeMultiplier()
end

-- ============================================================================
-- 2.5 城市碎片系统（Batch 5）
-- 拥有对应城市碎片可降低转生名誉门槛
-- ============================================================================

--- 检查玩家是否拥有某城市碎片
---@param cityId string 城市ID
---@return boolean hasFragment
---@return number reduction 门槛减免比例(0~0.5)
function PrestigeSystem.GetCityFragmentBonus(cityId)
    if not playerData_ or not playerData_.marketInventory then
        return false, 0
    end
    local okMD, MarketData = pcall(require, "MarketData")
    if not okMD then return false, 0 end

    for _, inst in ipairs(playerData_.marketInventory) do
        local itemDef = MarketData.ITEMS_BY_ID and MarketData.ITEMS_BY_ID[inst.id]
        if itemDef and itemDef.category == "cityfrag" and itemDef.effects and itemDef.effects.cityId == cityId then
            return true, itemDef.effects.thresholdReduction or 0.30
        end
    end
    return false, 0
end

--- 获取某城市实际解锁所需名誉（考虑碎片减免）
---@param city table 城市配置
---@return number effectiveReq 实际所需名誉
---@return boolean hasFragment 是否有碎片
---@return number reduction 减免比例
function PrestigeSystem.GetEffectivePrestigeReq(city)
    if not city then return 9999, false, 0 end
    local hasFragment, reduction = PrestigeSystem.GetCityFragmentBonus(city.id)
    local effectiveReq = city.prestigeReq
    if hasFragment then
        effectiveReq = math.floor(city.prestigeReq * (1 - reduction))
    end
    return effectiveReq, hasFragment, reduction
end

-- ============================================================================
-- 3. 转生条件检查
-- ============================================================================

--- 检查是否满足转生条件
--- @return boolean canPrestige
--- @return string reason 不满足的原因
--- @return number gain 可获得的名誉
function PrestigeSystem.CanPrestige()
    local day = playerData_.day or 1
    local totalEarnings = playerData_.totalEarnings or 0

    -- 最低条件：经营满12天 且 总收入 >= $1,500（3.2 缩短转生门槛）
    if day < 12 then
        return false, "需要经营满12天（当前第" .. day .. "天）", 0
    end
    if totalEarnings < 1500 then
        return false, "需要累计收入 ≥ $1,500（当前 $" .. totalEarnings .. "）", 0
    end

    local gain = PrestigeSystem.CalcPrestigeGain()
    if gain < 10 then
        return false, "当前进度产出的名誉太少（" .. gain .. "），建议继续发展", gain
    end

    return true, "", gain
end

-- ============================================================================
-- 4. 执行转生
-- ============================================================================

--- 执行转生：重置本地进度，获得永久加成
--- @param targetCityId string|nil 目标城市ID（nil则选下一个未解锁城市）
--- @return boolean success
--- @return string message 结果描述
function PrestigeSystem.DoPrestige(targetCityId)
    local canDo, reason, gain = PrestigeSystem.CanPrestige()
    if not canDo then
        return false, reason
    end

    gain = PrestigeSystem.CalcPrestigeGain()

    -- 确定目标城市
    local nextCity = nil
    if targetCityId then
        for _, city in ipairs(PrestigeSystem.CITIES) do
            if city.id == targetCityId then nextCity = city; break end
        end
    end
    if not nextCity then
        -- 自动选择下一个未解锁的城市
        local unlockedCities = playerData_.unlockedCities or { "wakandaville" }
        for _, city in ipairs(PrestigeSystem.CITIES) do
            local found = false
            for _, uid in ipairs(unlockedCities) do
                if uid == city.id then found = true; break end
            end
            if not found then
                nextCity = city
                break
            end
        end
    end

    -- 记录转生前数据（用于回顾）
    local prestigeRecord = {
        fromCity = playerData_.currentCity or "wakandaville",
        toCity = nextCity and nextCity.id or "unknown",
        day = playerData_.day,
        totalEarnings = playerData_.totalEarnings,
        honorGained = gain,
        timestamp = os.time(),
    }

    -- ── 永久数据保留 ──
    local keepData = {
        prestigeHonor = (playerData_.prestigeHonor or 0) + gain,
        prestigeCount = (playerData_.prestigeCount or 0) + 1,
        unlockedCities = playerData_.unlockedCities or { "wakandaville" },
        prestigeHistory = playerData_.prestigeHistory or {},
        automationLevel = playerData_.automationLevel or 0,  -- 自动化等级保留
        -- 成就保留
        totalPrestigeEarnings = (playerData_.totalPrestigeEarnings or 0) + (playerData_.totalEarnings or 0),
        -- 城市设施保留（跨转生永久投资）
        cityFacilities = playerData_.cityFacilities or {},
    }

    -- 解锁新城市（Batch 5: 碎片减免机制整合）
    if nextCity then
        local alreadyUnlocked = false
        for _, uid in ipairs(keepData.unlockedCities) do
            if uid == nextCity.id then alreadyUnlocked = true; break end
        end
        if not alreadyUnlocked then
            -- 检查碎片减免
            local hasFragment, reduction = PrestigeSystem.GetCityFragmentBonus(nextCity.id)
            local effectiveReq = nextCity.prestigeReq
            if hasFragment then
                effectiveReq = math.floor(nextCity.prestigeReq * (1 - reduction))
            end
            -- 检查名誉是否满足（考虑碎片减免后的门槛）
            if keepData.prestigeHonor >= effectiveReq then
                table.insert(keepData.unlockedCities, nextCity.id)
                if hasFragment and AddLog then
                    AddLog("🗺️ 【碎片加持】" .. nextCity.emoji .. " " .. nextCity.name ..
                        " 门槛降低" .. math.floor(reduction * 100) .. "%！（" ..
                        nextCity.prestigeReq .. " → " .. effectiveReq .. "）")
                end
            else
                -- 名誉不够，不解锁城市但转生仍然成功（积累名誉）
                nextCity = nil  -- 不进入新城市，留在当前城市继续
                if AddLog then
                    AddLog("📊 名誉积累中，尚未满足下一城市门槛")
                end
            end
        end
    end

    -- 记录转生历史
    table.insert(keepData.prestigeHistory, prestigeRecord)

    -- ── 重置本地数据 ──
    -- 保留初始资金（转生后更多启动资金）
    local startMoney = 5000 + keepData.prestigeCount * 500  -- 每次转生多500启动资金
    startMoney = math.min(startMoney, 10000)  -- 上限1万

    playerData_.money = startMoney
    playerData_.reputation = 0
    playerData_.day = 1
    playerData_.computers = 3
    playerData_.chairLevel = 1
    playerData_.netSpeed = 1
    playerData_.acLevel = 0
    playerData_.solarLevel = 0
    playerData_.foodShop = 0
    playerData_.decoLevel = 0
    playerData_.securityLevel = 0
    playerData_.generatorLevel = 0
    playerData_.fuel = 0
    playerData_.fuelCapacity = 0
    playerData_.wellLevel = 0
    playerData_.roadLevel = 0
    playerData_.coffeeLevel = 0
    playerData_.jukeboxLevel = 0
    playerData_.equipCondition = 100
    playerData_.actionPoints = 3
    playerData_.friendlyWins = 0
    playerData_.friendlyLosses = 0
    playerData_.debt = 0
    playerData_.debtDay = 0
    playerData_.matchTier = 1
    playerData_.tierWins = { 0, 0, 0 }
    playerData_.branches = {}
    playerData_.totalEarnings = 0
    playerData_.goldOunces = 0
    playerData_.coupDaysLeft = 0
    playerData_.goldSafe = false
    playerData_.goldVIP = false
    playerData_.havocCoins = math.floor((playerData_.havocCoins or 0) * 0.5) -- 哈弗币保留50%
    playerData_.seasonWins = 0
    playerData_.tournamentWins = 0
    playerData_.tournamentPlayed = 0

    -- 写回永久数据
    playerData_.prestigeHonor = keepData.prestigeHonor
    playerData_.prestigeCount = keepData.prestigeCount
    playerData_.unlockedCities = keepData.unlockedCities
    playerData_.prestigeHistory = keepData.prestigeHistory
    playerData_.automationLevel = keepData.automationLevel
    playerData_.totalPrestigeEarnings = keepData.totalPrestigeEarnings
    playerData_.cityFacilities = keepData.cityFacilities
    playerData_.currentCity = nextCity and nextCity.id or (playerData_.currentCity or "wakandaville")

    -- 重置队伍（保留特殊角色的好感度记忆）
    teamMembers_ = {}

    -- 为新城市初始化候选队员池
    local newCityId = playerData_.currentCity or "wakandaville"
    InitCandidatePool(newCityId)

    -- 图鉴系统 hook：到达新城市
    if LoreSystem and LoreSystem.OnCityReached then
        pcall(LoreSystem.OnCityReached, newCityId)
    end

    -- 重置事件日志（保留日记精华）
    eventLog_ = {}
    diaryEntries_ = {}

    -- 重置故事触发标记（允许重新体验）
    if storyTriggered_ then
        -- 保留里程碑成就标记，重置剧情标记
        local keepKeys = {
            "milestone_first_profit", "milestone_1k", "milestone_3k",
            "milestone_5k", "milestone_10k", "milestone_50k",
        }
        local keepSet = {}
        for _, k in ipairs(keepKeys) do keepSet[k] = storyTriggered_[k] end
        -- 清空后恢复
        for k in pairs(storyTriggered_) do storyTriggered_[k] = nil end
        for k, v in pairs(keepSet) do storyTriggered_[k] = v end
    end

    AddLog("🌟 【转生】恭喜！获得 " .. gain .. " 商会名誉！")
    if nextCity then
        AddLog("🏙️ 前往「" .. nextCity.name .. "」开设新网吧！")
    else
        local currentCityName = playerData_.currentCity or "wakandaville"
        AddLog("🔄 在「" .. currentCityName .. "」重新起步，继续积累名誉！")
    end
    AddLog("💰 启动资金：$" .. startMoney .. "（转生加成）")

    -- P1-2：转生后检查名誉里程碑
    local milestoneOk, milestoneErr = pcall(PrestigeSystem.CheckHonorMilestones)
    if not milestoneOk then
        log:Write(LOG_WARNING, "[DoPrestige] CheckHonorMilestones error: " .. tostring(milestoneErr))
    end

    -- 彩蛋：转生触发
    pcall(function() require("EasterEggs").OnPrestige(keepData.prestigeCount) end)

    if PlaySFX then PlaySFX("victory") end
    if TriggerCelebration then TriggerCelebration() end

    local resultCity = nextCity and nextCity.name or (playerData_.currentCity or "瓦坎达维尔")
    return true, "成功转生至「" .. resultCity .. "」，获得 " .. gain .. " 商会名誉！"
end

-- ============================================================================
-- 5. 查询接口
-- ============================================================================

--- 获取当前城市信息
function PrestigeSystem.GetCurrentCity()
    local cityId = (playerData_ and playerData_.currentCity) or "wakandaville"
    for _, city in ipairs(PrestigeSystem.CITIES) do
        if city.id == cityId then return city end
    end
    return PrestigeSystem.CITIES[1]
end

--- 获取下一个可解锁的城市
function PrestigeSystem.GetNextCity()
    local unlockedCities = (playerData_ and playerData_.unlockedCities) or { "wakandaville" }
    for _, city in ipairs(PrestigeSystem.CITIES) do
        local found = false
        for _, uid in ipairs(unlockedCities) do
            if uid == city.id then found = true; break end
        end
        if not found then return city end
    end
    return nil -- 全部解锁
end

--- 获取下一个城市的解锁信息（含碎片减免详情）
---@return table|nil info { city, effectiveReq, hasFragment, reduction, currentHonor, canUnlock }
function PrestigeSystem.GetNextCityInfo()
    local nextCity = PrestigeSystem.GetNextCity()
    if not nextCity then return nil end
    local effectiveReq, hasFragment, reduction = PrestigeSystem.GetEffectivePrestigeReq(nextCity)
    local currentHonor = PrestigeSystem.GetPrestigeHonor()
    return {
        city = nextCity,
        effectiveReq = effectiveReq,
        originalReq = nextCity.prestigeReq,
        hasFragment = hasFragment,
        reduction = reduction,
        currentHonor = currentHonor,
        canUnlock = currentHonor >= effectiveReq,
    }
end

--- 获取转生次数
function PrestigeSystem.GetPrestigeCount()
    return (playerData_ and playerData_.prestigeCount) or 0
end

--- 获取商会名誉总量
function PrestigeSystem.GetPrestigeHonor()
    return (playerData_ and playerData_.prestigeHonor) or 0
end

--- 获取已解锁城市列表
function PrestigeSystem.GetUnlockedCities()
    return (playerData_ and playerData_.unlockedCities) or { "wakandaville" }
end

--- 获取转生历史
function PrestigeSystem.GetPrestigeHistory()
    return (playerData_ and playerData_.prestigeHistory) or {}
end

-- ============================================================================
-- P1-2 转生名誉里程碑系统
-- ============================================================================
PrestigeSystem.HONOR_MILESTONES = {
    { threshold = 50,   icon = "🥉", name = "铜牌商人",   reward = "offline_cap+2",  desc = "离线上限 +2 小时" },
    { threshold = 100,  icon = "🥈", name = "银牌掌柜",   reward = "income_pct+5",   desc = "每日收入永久 +5%" },
    { threshold = 250,  icon = "🥇", name = "金牌老板",   reward = "havoc_coins+50", desc = "获得 💎50 哈弗币" },
    { threshold = 500,  icon = "💎", name = "钻石大亨",   reward = "income_pct+10",  desc = "每日收入永久 +10%" },
    { threshold = 1000, icon = "👑", name = "非洲之王",   reward = "offline_cap+8",  desc = "离线上限再 +8 小时" },
}

--- 检查并发放名誉里程碑奖励
function PrestigeSystem.CheckHonorMilestones()
    if not playerData_ then return end
    local honor = playerData_.prestigeHonor or 0
    local claimed = playerData_.prestigeMilestonesClaimed or {}
    local rewards = {}

    for _, ms in ipairs(PrestigeSystem.HONOR_MILESTONES) do
        if honor >= ms.threshold and not claimed[ms.threshold] then
            claimed[ms.threshold] = true
            table.insert(rewards, ms)
            -- 应用奖励
            if ms.reward == "offline_cap+2" then
                playerData_.honorOfflineBonus = (playerData_.honorOfflineBonus or 0) + 2
            elseif ms.reward == "offline_cap+8" then
                playerData_.honorOfflineBonus = (playerData_.honorOfflineBonus or 0) + 8
            elseif ms.reward == "income_pct+5" then
                playerData_.honorIncomeBonus = (playerData_.honorIncomeBonus or 0) + 5
            elseif ms.reward == "income_pct+10" then
                playerData_.honorIncomeBonus = (playerData_.honorIncomeBonus or 0) + 10
            elseif ms.reward == "havoc_coins+50" then
                playerData_.havocCoins = (playerData_.havocCoins or 0) + 50
            end
            if AddLog then
                AddLog(ms.icon .. " 【名誉里程碑】" .. ms.name .. "！奖励：" .. ms.desc)
            end
        end
    end

    playerData_.prestigeMilestonesClaimed = claimed
    return rewards
end

return PrestigeSystem
