---@diagnostic disable: undefined-global
------------------------------------------------------------
-- Market.lua — 二手市场核心逻辑
-- 抽卡(DoPull)、装备(Equip/Unequip)、回收(Recycle)、
-- 融合(Fuse)、效果聚合(CalcEquippedEffects)、每日结算
------------------------------------------------------------

local MarketData = require("MarketData")
local Market = {}

-- ============================================================
-- 内部工具
-- ============================================================

--- 确保 playerData_ 里有市场所需字段（向后兼容）
function Market.Validate(pd)
    if not pd then return end
    pd.marketInventory   = pd.marketInventory   or {}   -- { {id=, uid=, dur=, ...}, ... }
    pd.marketEquipped    = pd.marketEquipped    or {}   -- { [slotIdx] = uid }
    pd.marketSlots       = pd.marketSlots       or 3
    pd.marketPityCounter = pd.marketPityCounter or 0
    pd.marketTotalPulls  = pd.marketTotalPulls  or 0
    pd.marketNextUID     = pd.marketNextUID     or 1
    pd.marketDailyFree   = pd.marketDailyFree   or false -- 今日是否已用免费单抽
end

--- 生成唯一物品实例 ID
local function nextUID()
    Market.Validate(playerData_)
    local uid = playerData_.marketNextUID
    playerData_.marketNextUID = uid + 1
    return uid
end

--- 通过 uid 找背包物品索引
local function findItemIdx(uid)
    for i, it in ipairs(playerData_.marketInventory) do
        if it.uid == uid then return i end
    end
    return nil
end

--- 判断物品是否已装备
local function isEquipped(uid)
    for _, eqUID in pairs(playerData_.marketEquipped) do
        if eqUID == uid then return true end
    end
    return false
end

-- ============================================================
-- 抽卡（加权 + 保底）
-- ============================================================

--- 根据保底机制选取品质
local function rollTier()
    local pd = playerData_
    local counter = pd.marketPityCounter + 1
    pd.marketPityCounter = counter

    -- 硬保底
    if counter >= MarketData.PITY.legendHard then
        pd.marketPityCounter = 0
        return 5
    end
    -- 软保底（40抽起每抽 +2% 金概率）
    if counter >= MarketData.PITY.legendSoft then
        local extraPct = (counter - MarketData.PITY.legendSoft + 1) * 2
        if math.random(1, 100) <= extraPct then
            pd.marketPityCounter = 0
            return 5
        end
    end
    -- 紫保底
    if counter >= MarketData.PITY.epic and counter % MarketData.PITY.epic == 0 then
        return math.random() < 0.2 and 5 or 4
    end
    -- 蓝保底
    if counter >= MarketData.PITY.rare and counter % MarketData.PITY.rare == 0 then
        local r = math.random()
        if r < 0.05 then return 5
        elseif r < 0.15 then return 4
        else return 3 end
    end

    -- 正常加权随机
    local totalW = 0
    for t = 1, 5 do totalW = totalW + MarketData.TIERS[t].weight end
    local roll = math.random(1, totalW)
    local acc = 0
    for t = 1, 5 do
        acc = acc + MarketData.TIERS[t].weight
        if roll <= acc then return t end
    end
    return 1
end

--- 从指定品质池随机选一件物品，返回定义表
local function pickItem(tier)
    local pool = MarketData.ITEMS_BY_TIER[tier]
    if not pool or #pool == 0 then pool = MarketData.ITEMS_BY_TIER[1] end
    return pool[math.random(1, #pool)]
end

--- 创建物品实例
local function createInstance(itemDef)
    local tierInfo = MarketData.TIERS[itemDef.tier]
    return {
        id   = itemDef.id,
        uid  = nextUID(),
        dur  = tierInfo.durability,    -- 当前耐久
        maxDur = tierInfo.durability,  -- 最大耐久
    }
end

--- 执行单次抽卡，返回物品实例 + 物品定义
function Market.DoPullOne()
    Market.Validate(playerData_)
    local tier = rollTier()
    local def = pickItem(tier)
    local inst = createInstance(def)
    table.insert(playerData_.marketInventory, inst)
    playerData_.marketTotalPulls = playerData_.marketTotalPulls + 1
    return inst, def
end

--- 多连抽 (n次)，返回 { {inst, def}, ... }
function Market.DoPullN(n)
    local results = {}
    for _ = 1, n do
        local inst, def = Market.DoPullOne()
        table.insert(results, { inst = inst, def = def })
    end
    return results
end

--- 检查是否有足够货币执行抽卡
--- @param pullType string "single"|"ten"|"money_single"
--- @return boolean canAfford, string|nil reason
function Market.CanAfford(pullType)
    Market.Validate(playerData_)
    if pullType == "single" then
        if playerData_.marketDailyFree then
            local ok = playerData_.havocCoins >= MarketData.PULL_COST.single
            return ok, (not ok) and ("需要 " .. MarketData.PULL_COST.single .. " 哈弗币") or nil
        else
            return true, nil  -- 每日免费
        end
    elseif pullType == "ten" then
        local ok = playerData_.havocCoins >= MarketData.PULL_COST.ten
        return ok, (not ok) and ("需要 " .. MarketData.PULL_COST.ten .. " 哈弗币") or nil
    elseif pullType == "money_single" then
        local ok = playerData_.money >= MarketData.PULL_COST.money
        return ok, (not ok) and ("需要 $" .. MarketData.PULL_COST.money) or nil
    end
    return false, "未知类型"
end

--- 扣费并执行抽卡
--- @param pullType string "single"|"ten"|"money_single"
--- @return table|nil results, string|nil error
function Market.Pull(pullType)
    local canDo, reason = Market.CanAfford(pullType)
    if not canDo then return nil, reason end

    if pullType == "single" then
        if not playerData_.marketDailyFree then
            playerData_.marketDailyFree = true  -- 标记已用免费
        else
            playerData_.havocCoins = playerData_.havocCoins - MarketData.PULL_COST.single
        end
        local inst, def = Market.DoPullOne()
        return { { inst = inst, def = def } }, nil

    elseif pullType == "ten" then
        playerData_.havocCoins = playerData_.havocCoins - MarketData.PULL_COST.ten
        return Market.DoPullN(10), nil

    elseif pullType == "money_single" then
        playerData_.money = playerData_.money - MarketData.PULL_COST.money
        local inst, def = Market.DoPullOne()
        return { { inst = inst, def = def } }, nil
    end
    return nil, "未知类型"
end

-- ============================================================
-- 装备 / 卸下
-- ============================================================

--- 装备物品到指定槽位
--- @return boolean ok, string|nil err
function Market.Equip(uid, slotIdx)
    Market.Validate(playerData_)
    if slotIdx < 1 or slotIdx > playerData_.marketSlots then
        return false, "槽位未解锁"
    end
    local idx = findItemIdx(uid)
    if not idx then return false, "物品不存在" end
    if isEquipped(uid) then return false, "已装备" end

    -- 如果槽位已有物品，先卸下
    if playerData_.marketEquipped[slotIdx] then
        -- 不需额外操作，直接替换
    end
    playerData_.marketEquipped[slotIdx] = uid
    return true, nil
end

--- 卸下指定槽位
function Market.Unequip(slotIdx)
    Market.Validate(playerData_)
    playerData_.marketEquipped[slotIdx] = nil
    return true
end

-- ============================================================
-- 回收
-- ============================================================

--- 回收物品，返还哈弗币
--- @return number|nil coins, string|nil err
function Market.Recycle(uid)
    Market.Validate(playerData_)
    if isEquipped(uid) then return nil, "请先卸下装备" end
    local idx = findItemIdx(uid)
    if not idx then return nil, "物品不存在" end

    local inst = playerData_.marketInventory[idx]
    local def = MarketData.ITEMS_BY_ID[inst.id]
    if not def then return nil, "数据异常" end

    local coins = MarketData.RECYCLE_VALUE[def.tier] or 10
    -- 耐久折损：不足50%时回收减半
    if inst.dur < inst.maxDur * 0.5 then
        coins = math.floor(coins * 0.5)
    end
    coins = math.max(1, coins)

    table.remove(playerData_.marketInventory, idx)
    playerData_.havocCoins = playerData_.havocCoins + coins
    return coins, nil
end

--- 批量回收（按品质）
--- @return number totalCoins, number count
function Market.RecycleBatch(maxTier)
    Market.Validate(playerData_)
    maxTier = maxTier or 2
    local totalCoins = 0
    local count = 0
    -- 倒序遍历避免索引偏移
    for i = #playerData_.marketInventory, 1, -1 do
        local inst = playerData_.marketInventory[i]
        local def = MarketData.ITEMS_BY_ID[inst.id]
        if def and def.tier <= maxTier and not isEquipped(inst.uid) then
            local coins = MarketData.RECYCLE_VALUE[def.tier] or 10
            if inst.dur < inst.maxDur * 0.5 then
                coins = math.floor(coins * 0.5)
            end
            coins = math.max(1, coins)
            table.remove(playerData_.marketInventory, i)
            totalCoins = totalCoins + coins
            count = count + 1
        end
    end
    playerData_.havocCoins = playerData_.havocCoins + totalCoins
    return totalCoins, count
end

-- ============================================================
-- 融合（3件同品质 → 1件高一级）
-- ============================================================

--- 检查融合可行性
--- @param uid1 number
--- @param uid2 number
--- @param uid3 number
--- @return boolean ok, number|nil resultTier, string|nil err
function Market.CanFuse(uid1, uid2, uid3)
    Market.Validate(playerData_)
    if uid1 == uid2 or uid1 == uid3 or uid2 == uid3 then
        return false, nil, "不能使用相同物品融合"
    end
    local uids = { uid1, uid2, uid3 }
    local tier = nil
    for _, uid in ipairs(uids) do
        if isEquipped(uid) then return false, nil, "请先卸下装备" end
        local idx = findItemIdx(uid)
        if not idx then return false, nil, "物品不存在" end
        local inst = playerData_.marketInventory[idx]
        local def = MarketData.ITEMS_BY_ID[inst.id]
        if not def then return false, nil, "数据异常" end
        if tier == nil then
            tier = def.tier
        elseif def.tier ~= tier then
            return false, nil, "品质不同，无法融合"
        end
    end
    if tier >= 5 then return false, nil, "已是最高品质" end
    return true, tier + 1, nil
end

--- 执行融合：消耗3件同品质，产出1件高品质
--- @return table|nil newInst, table|nil newDef, string|nil err
function Market.Fuse(uid1, uid2, uid3)
    local canDo, resultTier, err = Market.CanFuse(uid1, uid2, uid3)
    if not canDo then return nil, nil, err end

    -- 删除素材（倒序）
    local indices = {}
    for _, uid in ipairs({ uid1, uid2, uid3 }) do
        table.insert(indices, findItemIdx(uid))
    end
    table.sort(indices, function(a, b) return a > b end)
    for _, idx in ipairs(indices) do
        table.remove(playerData_.marketInventory, idx)
    end

    -- 生成新物品
    local def = pickItem(resultTier)
    local inst = createInstance(def)
    table.insert(playerData_.marketInventory, inst)
    return inst, def, nil
end

-- ============================================================
-- 效果聚合（供外部系统读取）
-- ============================================================

--- 计算当前装备栏中所有物品的聚合效果
--- @return table effects { effectKey = totalValue, ... }
function Market.CalcEquippedEffects()
    Market.Validate(playerData_)
    local effects = {}
    for slotIdx = 1, playerData_.marketSlots do
        local uid = playerData_.marketEquipped[slotIdx]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                local def = MarketData.ITEMS_BY_ID[inst.id]
                if def and def.effects and inst.dur > 0 then
                    for k, v in pairs(def.effects) do
                        effects[k] = (effects[k] or 0) + v
                    end
                end
            end
        end
    end
    return effects
end

-- ============================================================
-- 槽位解锁
-- ============================================================

--- 获取下一个可解锁槽位的信息
--- @return table|nil info { slots=, cost=, day= }, string|nil err
function Market.GetNextSlotUnlock()
    Market.Validate(playerData_)
    for _, entry in ipairs(MarketData.SLOT_UNLOCK) do
        if entry.slots > playerData_.marketSlots then
            if playerData_.day < entry.day then
                return nil, "需要到达第 " .. entry.day .. " 天"
            end
            return entry, nil
        end
    end
    return nil, "已满级"
end

--- 解锁下一个槽位
--- @return boolean ok, string|nil err
function Market.UnlockSlot()
    local info, err = Market.GetNextSlotUnlock()
    if not info then return false, err end
    if playerData_.havocCoins < info.cost then
        return false, "需要 " .. info.cost .. " 哈弗币"
    end
    playerData_.havocCoins = playerData_.havocCoins - info.cost
    playerData_.marketSlots = info.slots
    return true, nil
end

-- ============================================================
-- 每日结算（在 EndDay 中调用）
-- ============================================================

--- 每日损耗装备耐久 + 清除损坏物品
function Market.DailyTick()
    Market.Validate(playerData_)

    -- 装备耐久消耗
    local effects = Market.CalcEquippedEffects()
    local decayReduction = effects.equipDecayReduction or 0

    for slotIdx = 1, playerData_.marketSlots do
        local uid = playerData_.marketEquipped[slotIdx]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                -- 基础消耗 = maxDur 的 20%（向上取整），减免后最少1点
                local baseDecay = math.ceil(inst.maxDur * 0.2)
                local decay = math.max(1, math.ceil(baseDecay * (1 - decayReduction)))
                inst.dur = math.max(0, inst.dur - decay)
                -- 耐久归零 → 自动卸下（保留物品，可回收）
                if inst.dur <= 0 then
                    playerData_.marketEquipped[slotIdx] = nil
                    if AddLog then
                        local def = MarketData.ITEMS_BY_ID[inst.id]
                        AddLog("🔧 " .. (def and def.name or "物品") .. " 已损坏，自动卸下。")
                    end
                end
            else
                -- uid 对应物品不存在，清理脏数据
                playerData_.marketEquipped[slotIdx] = nil
            end
        end
    end
end

--- 每日重置（在 RV2.DailyReset 中调用）
function Market.DailyReset()
    Market.Validate(playerData_)
    playerData_.marketDailyFree = false
end

-- ============================================================
-- 重置（新游戏时调用）
-- ============================================================

function Market.FullReset()
    if not playerData_ then return end
    playerData_.marketInventory   = {}
    playerData_.marketEquipped    = {}
    playerData_.marketSlots       = 3
    playerData_.marketPityCounter = 0
    playerData_.marketTotalPulls  = 0
    playerData_.marketNextUID     = 1
    playerData_.marketDailyFree   = false
end

-- ============================================================
-- 查询工具
-- ============================================================

--- 获取背包物品列表（附带定义信息和装备状态）
function Market.GetInventoryDisplay()
    Market.Validate(playerData_)
    local list = {}
    for _, inst in ipairs(playerData_.marketInventory) do
        local def = MarketData.ITEMS_BY_ID[inst.id]
        if def then
            table.insert(list, {
                inst = inst,
                def  = def,
                tier = def.tier,
                equipped = isEquipped(inst.uid),
                durPct = inst.maxDur > 0 and math.floor(inst.dur / inst.maxDur * 100) or 0,
            })
        end
    end
    -- 按品质降序排列
    table.sort(list, function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        return a.inst.uid < b.inst.uid
    end)
    return list
end

--- 获取装备槽显示信息
function Market.GetSlotsDisplay()
    Market.Validate(playerData_)
    local slots = {}
    for i = 1, playerData_.marketSlots do
        local uid = playerData_.marketEquipped[i]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                local def = MarketData.ITEMS_BY_ID[inst.id]
                slots[i] = { inst = inst, def = def, durPct = inst.maxDur > 0 and math.floor(inst.dur / inst.maxDur * 100) or 0 }
            else
                playerData_.marketEquipped[i] = nil
                slots[i] = nil
            end
        else
            slots[i] = nil
        end
    end
    return slots
end

--- 获取统计信息
function Market.GetStats()
    Market.Validate(playerData_)
    local tierCounts = { 0, 0, 0, 0, 0 }
    for _, inst in ipairs(playerData_.marketInventory) do
        local def = MarketData.ITEMS_BY_ID[inst.id]
        if def then tierCounts[def.tier] = tierCounts[def.tier] + 1 end
    end
    return {
        totalItems  = #playerData_.marketInventory,
        totalPulls  = playerData_.marketTotalPulls,
        pityCounter = playerData_.marketPityCounter,
        slots       = playerData_.marketSlots,
        tierCounts  = tierCounts,
    }
end

return Market
