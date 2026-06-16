---@diagnostic disable: undefined-global
-- ============================================================================
-- CityNetwork.lua — D31+ 多城市继续经营系统
-- 核心功能：
--   1. 第一季结局后进入继续经营模式（保留资产，不清空）
--   2. 城市网络管理（查看/切换/解锁城市）
--   3. 第一季结局 bonus 影响新城市开局
--   4. 与 PrestigeSystem.CITIES 复用城市数据
-- ============================================================================

local CityNetwork = {}

-- ============================================================================
-- 1. 城市解锁条件（D31+ 继续经营模式，非转生）
-- ============================================================================
-- 继续经营模式的城市解锁条件比转生更宽松：
-- 不需要转生重置，只需满足条件即可"开设分部"

CityNetwork.UNLOCK_CONDITIONS = {
    lagos = {
        label = "拉各斯分部",
        desc = "西非商业中心，客流量巨大",
        conditions = { day = 35, money = 3000, reputation = 50 },
        hint = "经营到D35，持有$3000，声望50+",
    },
    nairobi = {
        label = "内罗毕分部",
        desc = "东非科技枢纽，升级成本低",
        conditions = { day = 45, money = 5000, reputation = 100 },
        hint = "经营到D45，持有$5000，声望100+",
    },
    accra = {
        label = "阿克拉分部",
        desc = "加纳文化教育中心",
        conditions = { day = 60, money = 8000, reputation = 200 },
        hint = "经营到D60，持有$8000，声望200+",
    },
}

-- ============================================================================
-- 2. 继续经营模式入口
-- ============================================================================

--- 进入D31+继续经营模式（从结局页调用）
--- 不清空任何资产，只标记进入第二季
function CityNetwork.EnterPostSeason()
    if not playerData_ then return false end

    playerData_.postSeason = true
    playerData_.season = playerData_.season or 2

    -- 确保 cityNetwork 数据存在
    CityNetwork.EnsureState()

    print("[CityNetwork] 进入D31+继续经营模式")
    return true
end

--- 初始化/验证 cityNetwork 状态
function CityNetwork.EnsureState()
    if not playerData_ then return end

    if not playerData_.cityNetwork then
        playerData_.cityNetwork = {
            current = playerData_.currentCity or "wakandaville",
            expansionDay = playerData_.day or 31,
            cities = {},
            totalCityIncome = 0,
        }
    end

    local cn = playerData_.cityNetwork

    -- 确保当前城市记录存在
    if not cn.cities[cn.current] then
        cn.cities[cn.current] = {
            unlocked = true,
            unlockedDay = 1,
            reputation = playerData_.reputation or 0,
            totalIncome = playerData_.totalEarnings or 0,
            cafeName = "Dragon Net Cafe",
        }
    end
end

-- ============================================================================
-- 3. 城市解锁检测
-- ============================================================================

--- 检查某个城市是否满足解锁条件
---@param cityId string
---@return boolean canUnlock
---@return string|nil reason 不满足时的原因
function CityNetwork.CanUnlockCity(cityId)
    local cond = CityNetwork.UNLOCK_CONDITIONS[cityId]
    if not cond then return false, "未知城市" end

    CityNetwork.EnsureState()
    local cn = playerData_.cityNetwork

    -- 已经解锁
    if cn.cities[cityId] and cn.cities[cityId].unlocked then
        return false, "已经解锁"
    end

    -- 必须在继续经营模式
    if not playerData_.postSeason then
        return false, "需要完成第一季"
    end

    local day = playerData_.day or 1
    local money = playerData_.money or 0
    local rep = playerData_.reputation or 0
    local c = cond.conditions

    if day < (c.day or 0) then
        return false, "需要经营到第" .. c.day .. "天"
    end
    if money < (c.money or 0) then
        return false, "需要持有$" .. c.money
    end
    if rep < (c.reputation or 0) then
        return false, "需要声望" .. c.reputation .. "+"
    end

    return true, nil
end

--- 解锁新城市（花费资金建立分部）
---@param cityId string
---@return boolean success
---@return string message
function CityNetwork.UnlockCity(cityId)
    local canUnlock, reason = CityNetwork.CanUnlockCity(cityId)
    if not canUnlock then
        return false, reason or "条件不足"
    end

    CityNetwork.EnsureState()
    local cn = playerData_.cityNetwork
    local cond = CityNetwork.UNLOCK_CONDITIONS[cityId]

    -- 扣除开设费用（条件金额的50%作为开设成本）
    local cost = math.floor((cond.conditions.money or 0) * 0.5)

    -- 应用结局 bonus
    local bonus = playerData_.seasonOneBonus or {}
    if bonus.expansionDiscount then
        cost = math.floor(cost * (1 - bonus.expansionDiscount))
    end
    if bonus.expansionSpeed then
        cost = math.floor(cost * (1 - bonus.expansionSpeed))
    end

    if (playerData_.money or 0) < cost then
        return false, "资金不足，需要$" .. cost
    end

    playerData_.money = playerData_.money - cost

    -- 记录新城市
    cn.cities[cityId] = {
        unlocked = true,
        unlockedDay = playerData_.day or 31,
        reputation = 0,
        totalIncome = 0,
        cafeName = "Dragon Net " .. (cond.label or cityId),
    }

    -- 同步到旧系统（兼容 PrestigeSystem 和 UIMapView）
    if not playerData_.unlockedCities then
        playerData_.unlockedCities = { "wakandaville" }
    end
    local alreadyIn = false
    for _, uid in ipairs(playerData_.unlockedCities) do
        if uid == cityId then alreadyIn = true; break end
    end
    if not alreadyIn then
        table.insert(playerData_.unlockedCities, cityId)
    end

    print("[CityNetwork] 解锁城市: " .. cityId .. " 花费: $" .. cost)
    return true, "成功开设" .. (cond.label or cityId) .. "！花费$" .. cost
end

-- ============================================================================
-- 4. 城市切换
-- ============================================================================

--- 切换当前经营城市
---@param cityId string
---@return boolean success
function CityNetwork.SwitchCity(cityId)
    CityNetwork.EnsureState()
    local cn = playerData_.cityNetwork

    if not cn.cities[cityId] or not cn.cities[cityId].unlocked then
        return false
    end

    -- 保存当前城市状态
    local curCity = cn.cities[cn.current]
    if curCity then
        curCity.reputation = playerData_.reputation or 0
        curCity.totalIncome = playerData_.totalEarnings or 0
    end

    -- 切换
    cn.current = cityId
    playerData_.currentCity = cityId

    print("[CityNetwork] 切换到城市: " .. cityId)
    return true
end

-- ============================================================================
-- 5. 城市网络总览数据（供UI展示）
-- ============================================================================

--- 获取城市网络状态总览
---@return table[] cityList
function CityNetwork.GetCityOverview()
    CityNetwork.EnsureState()
    local cn = playerData_.cityNetwork
    local result = {}

    -- 使用 PrestigeSystem 的城市数据
    local PrestigeSystem = package.loaded["PrestigeSystem"]
    local allCities = PrestigeSystem and PrestigeSystem.CITIES or {
        { id = "wakandaville", name = "瓦坎达维尔", emoji = "🏘️" },
        { id = "lagos", name = "拉各斯", emoji = "🏙️" },
        { id = "nairobi", name = "内罗毕", emoji = "🌆" },
    }

    for _, city in ipairs(allCities) do
        local networkData = cn.cities[city.id]
        local unlockCond = CityNetwork.UNLOCK_CONDITIONS[city.id]
        local isCurrent = (cn.current == city.id)
        local isUnlocked = (networkData ~= nil and networkData.unlocked)

        local canUnlock = false
        local unlockHint = ""
        if not isUnlocked and unlockCond then
            canUnlock = CityNetwork.CanUnlockCity(city.id)
            unlockHint = unlockCond.hint or ""
        end

        table.insert(result, {
            id = city.id,
            name = city.name,
            emoji = city.emoji,
            desc = city.desc or "",
            isCurrent = isCurrent,
            isUnlocked = isUnlocked,
            canUnlock = canUnlock,
            unlockHint = unlockHint,
            reputation = networkData and networkData.reputation or 0,
            totalIncome = networkData and networkData.totalIncome or 0,
            cafeName = networkData and networkData.cafeName or nil,
            specialBonus = city.specialBonus or nil,
        })
    end

    return result
end

--- 获取每日被动收入（其他城市产出）
---@return number passiveIncome
function CityNetwork.CalcPassiveIncome()
    CityNetwork.EnsureState()
    local cn = playerData_.cityNetwork
    local total = 0

    local PrestigeSystem = package.loaded["PrestigeSystem"]
    local allCities = PrestigeSystem and PrestigeSystem.CITIES or {}

    for _, city in ipairs(allCities) do
        local nd = cn.cities[city.id]
        if nd and nd.unlocked and city.id ~= cn.current then
            -- 非当前城市每天产生被动收入
            local baseIncome = 50
            local multi = city.incomeMulti or 1.0
            total = total + math.floor(baseIncome * multi)
        end
    end

    -- 结局 bonus 加成
    local bonus = playerData_.seasonOneBonus or {}
    if bonus.incomeBonus then
        total = math.floor(total * (1 + bonus.incomeBonus))
    end

    return total
end

-- ============================================================================
-- 6. 结局 bonus 查询（供 UI 展示）
-- ============================================================================

--- 获取当前结局带来的多城市加成描述
---@return table[] bonusList { {icon, text} }
function CityNetwork.GetEndingBonusDesc()
    local bonus = playerData_.seasonOneBonus or {}
    local result = {}

    if bonus.repBonus and bonus.repBonus > 0 then
        table.insert(result, { icon = "⭐", text = "声望+" .. bonus.repBonus })
    end
    if bonus.incomeBonus then
        table.insert(result, { icon = "💰", text = "被动收入+" .. math.floor(bonus.incomeBonus * 100) .. "%" })
    end
    if bonus.startMoney and bonus.startMoney > 0 then
        table.insert(result, { icon = "💵", text = "启动资金+$" .. bonus.startMoney })
    end
    if bonus.maintenanceDiscount then
        table.insert(result, { icon = "🔧", text = "维护费-" .. math.floor(bonus.maintenanceDiscount * 100) .. "%" })
    end
    if bonus.expansionDiscount then
        table.insert(result, { icon = "🏗️", text = "扩张成本-" .. math.floor(bonus.expansionDiscount * 100) .. "%" })
    end
    if bonus.expansionSpeed then
        table.insert(result, { icon = "🚀", text = "扩张速度+" .. math.floor(bonus.expansionSpeed * 100) .. "%" })
    end
    if bonus.communityEvents then
        table.insert(result, { icon = "🏘️", text = "解锁社区合作事件" })
    end
    if bonus.youthEvents then
        table.insert(result, { icon = "🎓", text = "解锁青训学院事件" })
    end
    if bonus.kofiLoyalty and bonus.kofiLoyalty > 0 then
        table.insert(result, { icon = "🎮", text = "Kofi忠诚+" .. bonus.kofiLoyalty })
    end
    if bonus.trainingBonus then
        table.insert(result, { icon = "📈", text = "训练效率+" .. math.floor(bonus.trainingBonus * 100) .. "%" })
    end
    if bonus.grayRiskCarry and bonus.grayRiskCarry > 0 then
        table.insert(result, { icon = "⚠️", text = "灰色风险继承(+" .. bonus.grayRiskCarry .. ")" })
    end
    if bonus.trustPenalty and bonus.trustPenalty < 0 then
        table.insert(result, { icon = "💔", text = "信任惩罚(" .. bonus.trustPenalty .. ")" })
    end
    if bonus.loyaltyPenalty and bonus.loyaltyPenalty < 0 then
        table.insert(result, { icon = "🚪", text = "忠诚惩罚(" .. bonus.loyaltyPenalty .. ")" })
    end

    return result
end

-- ============================================================================
-- 7. 存档兼容
-- ============================================================================

--- 旧存档迁移（在 ValidatePlayerData 中调用）
function CityNetwork.MigrateOldSave()
    if not playerData_ then return end
    if playerData_.cityNetwork then return end -- 已有，不需要迁移

    -- 如果已经是 postSeason 但没有 cityNetwork，补建
    if playerData_.postSeason then
        CityNetwork.EnsureState()
    end
end

return CityNetwork
