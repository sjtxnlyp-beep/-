---@diagnostic disable: undefined-global
------------------------------------------------------------
-- Market.lua — 二手市场核心逻辑
-- 抽卡(DoPull)、装备(Equip/Unequip)、回收(Recycle)、
-- 融合(Fuse)、效果聚合(CalcEquippedEffects)、每日结算
------------------------------------------------------------

local MarketData = require("MarketData")
local MarketStorylines = require("MarketStorylines")
local Market = {}

-- ============================================================
-- 内部工具
-- ============================================================

--- 确保 playerData_ 里有市场所需字段（向后兼容）
function Market.Validate(pd)
    if not pd then return end
    pd.marketInventory   = pd.marketInventory   or {}   -- { {id=, uid=, dur=, ...}, ... }
    pd.marketEquipped    = pd.marketEquipped    or {}   -- { [slotIdx] = uid }
    pd.marketSlots       = tonumber(pd.marketSlots) or 3
    pd.marketPityCounter = tonumber(pd.marketPityCounter) or 0
    pd.marketTotalPulls  = tonumber(pd.marketTotalPulls) or 0
    pd.marketNextUID     = tonumber(pd.marketNextUID) or 1
    pd.marketDailyFree   = pd.marketDailyFree   or false -- 今日是否已用免费单抽
    pd.havocCoins        = tonumber(pd.havocCoins) or 0  -- 确保哈弗币字段存在
    -- 修复旧存档中 JSON 反序列化后数字变 string 的问题
    for _, inst in ipairs(pd.marketInventory) do
        inst.dur    = tonumber(inst.dur) or 0
        inst.maxDur = tonumber(inst.maxDur) or inst.dur
        inst.uid    = tonumber(inst.uid) or inst.uid
    end
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
--- 城市专属物品只在对应城市出现
local function pickItem(tier)
    local pool = MarketData.ITEMS_BY_TIER[tier]
    if not pool or #pool == 0 then pool = MarketData.ITEMS_BY_TIER[1] end

    -- 过滤城市专属：排除不属于当前城市的专属物品
    local currentCity = playerData_ and playerData_.currentCity or "wakandaville"
    local filtered = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, item in ipairs(pool) do
        if not item.cityExclusive or item.cityExclusive == currentCity then
            table.insert(filtered, item)
        end
    end
    ---@diagnostic disable-next-line: assign-type-mismatch
    if #filtered == 0 then filtered = pool end  -- 兜底
    return filtered[math.random(1, #filtered)]
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
    -- 图鉴系统 hook：记录物品品质
    if LoreSystem and LoreSystem.OnItemObtained then
        pcall(LoreSystem.OnItemObtained, def.tier or tier, def.id)
    end
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
        local costMul = MarketData.GetCityCostMultiplier and MarketData.GetCityCostMultiplier() or 1.0
        local cost = math.floor(MarketData.PULL_COST.money * costMul)
        local ok = playerData_.money >= cost
        return ok, (not ok) and ("需要 $" .. cost) or nil
    end
    return false, "未知类型"
end

--- 扣费并执行抽卡
--- @param pullType string "single"|"ten"|"money_single"
--- @return table|nil results, string|nil error
function Market.Pull(pullType)
    local canDo, reason = Market.CanAfford(pullType)
    if not canDo then return nil, reason end

    -- 获取故事线折扣
    local discount = 0
    pcall(function()
        local bonuses = MarketStorylines.GetBonuses()
        discount = bonuses.pullDiscount or 0
    end)
    local discountMul = math.max(0.5, 1 - discount / 100) -- 最多5折

    if pullType == "single" then
        if not playerData_.marketDailyFree then
            playerData_.marketDailyFree = true  -- 标记已用免费
        else
            local cost = math.floor(MarketData.PULL_COST.single * discountMul)
            playerData_.havocCoins = playerData_.havocCoins - cost
        end
        local inst, def = Market.DoPullOne()
        return { { inst = inst, def = def } }, nil

    elseif pullType == "ten" then
        local cost = math.floor(MarketData.PULL_COST.ten * discountMul)
        playerData_.havocCoins = playerData_.havocCoins - cost
        return Market.DoPullN(10), nil

    elseif pullType == "money_single" then
        local costMul = MarketData.GetCityCostMultiplier and MarketData.GetCityCostMultiplier() or 1.0
        local cost = math.floor(MarketData.PULL_COST.money * costMul * discountMul)
        playerData_.money = playerData_.money - cost
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
    local activatedList = {}  -- P2: 记录已激活的装备ID
    for slotIdx = 1, playerData_.marketSlots do
        local uid = playerData_.marketEquipped[slotIdx]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                local def = MarketData.ITEMS_BY_ID[inst.id]
                if def and def.effects and inst.dur > 0 then
                    for k, v in pairs(def.effects) do
                        if type(v) == "number" then
                            ---@diagnostic disable-next-line: assign-type-mismatch
                            effects[k] = (effects[k] or 0) + v
                        else
                            effects[k] = v  -- cityId 等字符串效果直接保留
                        end
                    end
                    -- P2: 装备激活效应（跨模块条件满足时叠加额外加成）
                    local ab = MarketData.ACTIVATE_BY_ID and MarketData.ACTIVATE_BY_ID[inst.id]
                    if ab and ab.check then
                        local okC, met = pcall(ab.check, playerData_)
                        if okC and met and ab.bonus then
                            for k, v in pairs(ab.bonus) do
                                effects[k] = (effects[k] or 0) + v
                            end
                            table.insert(activatedList, { id = inst.id, name = def.name, cond = ab.condDesc })
                        end
                    end
                end
            end
        end
    end
    effects._activated = activatedList  -- 附带激活信息供 UI 显示
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
                if def then
                    slots[i] = { inst = inst, def = def, durPct = inst.maxDur > 0 and math.floor(inst.dur / inst.maxDur * 100) or 0 }
                else
                    -- 物品定义不存在（可能因版本更新），自动卸下
                    playerData_.marketEquipped[i] = nil
                    slots[i] = nil
                end
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

-- ============================================================
-- Batch 3: 装饰槽位系统
-- 独立于装备槽，专门放置 category="decoration" 的物品
-- 装饰不会损耗耐久，但有独立的效果聚合
-- ============================================================

--- 确保装饰槽位字段存在
function Market.ValidateDeco(pd)
    if not pd then return end
    pd.decoSlots    = pd.decoSlots    or {}   -- { [slotIdx] = uid }
    pd.decoSlotsMax = pd.decoSlotsMax or 3    -- 初始3个装饰位
end

--- 判断物品是否已放入装饰槽
local function isDecoPlaced(uid)
    for _, dUID in pairs(playerData_.decoSlots or {}) do
        if dUID == uid then return true end
    end
    return false
end

--- 放置装饰品到指定槽位
--- @return boolean ok, string|nil err
function Market.PlaceDeco(uid, slotIdx)
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)

    if slotIdx < 1 or slotIdx > playerData_.decoSlotsMax then
        return false, "装饰位未解锁"
    end

    local idx = findItemIdx(uid)
    if not idx then return false, "物品不存在" end

    local inst = playerData_.marketInventory[idx]
    local def = MarketData.ITEMS_BY_ID[inst.id]
    if not def then return false, "数据异常" end
    if def.category ~= "decoration" then
        return false, "只能放置装饰类物品"
    end
    if isEquipped(uid) then return false, "物品已装备" end
    if isDecoPlaced(uid) then return false, "已放置" end

    -- 如果槽位已有物品，先移除
    playerData_.decoSlots[slotIdx] = uid
    return true, nil
end

--- 移除装饰槽位中的物品
function Market.RemoveDeco(slotIdx)
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)
    playerData_.decoSlots[slotIdx] = nil
    return true
end

--- 解锁额外装饰槽位（通过章节或金币）
--- @return boolean ok, string|nil err
function Market.UnlockDecoSlot()
    Market.ValidateDeco(playerData_)
    local maxAllowed = 6  -- 装饰位上限
    if playerData_.decoSlotsMax >= maxAllowed then
        return false, "已达上限"
    end
    -- 解锁费用递增
    local costs = { [4] = 2000, [5] = 5000, [6] = 10000 }
    local nextSlot = playerData_.decoSlotsMax + 1
    local cost = costs[nextSlot] or 5000
    if playerData_.money < cost then
        return false, "需要 $" .. cost
    end
    playerData_.money = playerData_.money - cost
    playerData_.decoSlotsMax = nextSlot
    return true, nil
end

--- 计算装饰槽位的聚合效果
--- @return table effects
function Market.CalcDecoEffects()
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)
    local effects = {}
    local placed = {}
    for slotIdx = 1, playerData_.decoSlotsMax do
        local uid = playerData_.decoSlots[slotIdx]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                local def = MarketData.ITEMS_BY_ID[inst.id]
                if def and def.effects then
                    for k, v in pairs(def.effects) do
                        if type(v) == "number" then
                            effects[k] = (effects[k] or 0) + v
                        else
                            effects[k] = v
                        end
                    end
                    table.insert(placed, { slot = slotIdx, def = def, inst = inst })
                end
            else
                playerData_.decoSlots[slotIdx] = nil
            end
        end
    end
    -- 装饰套装奖励：放满所有槽位时额外 +5% 全收入
    if #placed >= playerData_.decoSlotsMax and playerData_.decoSlotsMax >= 3 then
        effects.allRevenueBonus = (effects.allRevenueBonus or 0) + 0.05
        effects._setBonus = true
    end
    effects._placedCount = #placed
    return effects
end

--- 获取装饰槽位显示信息
function Market.GetDecoSlotsDisplay()
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)
    local slots = {}
    for i = 1, playerData_.decoSlotsMax do
        local uid = playerData_.decoSlots[i]
        if uid then
            local idx = findItemIdx(uid)
            if idx then
                local inst = playerData_.marketInventory[idx]
                local def = MarketData.ITEMS_BY_ID[inst.id]
                slots[i] = { inst = inst, def = def }
            else
                playerData_.decoSlots[i] = nil
                slots[i] = nil
            end
        else
            slots[i] = nil
        end
    end
    return slots, playerData_.decoSlotsMax
end

--- 获取可放置的装饰品列表（背包中 category=decoration 且未装备/未放置的）
function Market.GetAvailableDecoItems()
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)
    local list = {}
    for _, inst in ipairs(playerData_.marketInventory) do
        local def = MarketData.ITEMS_BY_ID[inst.id]
        if def and def.category == "decoration" and not isEquipped(inst.uid) and not isDecoPlaced(inst.uid) then
            table.insert(list, { inst = inst, def = def, tier = def.tier })
        end
    end
    table.sort(list, function(a, b)
        if a.tier ~= b.tier then return a.tier > b.tier end
        return a.inst.uid < b.inst.uid
    end)
    return list
end

-- ============================================================
-- Batch 4: 城市设施系统（大额金币消耗 + 永久加成）
-- ============================================================

--- 确保城市设施字段存在
function Market.ValidateFacility(pd)
    if not pd then return end
    pd.cityFacilities = pd.cityFacilities or {}  -- { [cityId] = level }
end

--- 获取当前城市设施信息（供 UI 显示）
--- @return table|nil info { name, desc, level, maxLevel, nextCost, effects, nextEffects }
function Market.GetCityFacilityInfo()
    Market.ValidateFacility(playerData_)
    local facility = MarketData.GetCityFacility()
    if not facility then return nil end

    local currentCity = playerData_.currentCity or "wakandaville"
    local level = playerData_.cityFacilities[currentCity] or 0
    local maxLevel = #facility.levels

    local info = {
        name     = facility.name,
        desc     = facility.desc,
        level    = level,
        maxLevel = maxLevel,
        effects  = level > 0 and facility.levels[level].effects or {},
    }
    -- 下一级信息
    if level < maxLevel then
        local nextLvl = facility.levels[level + 1]
        info.nextCost    = nextLvl.cost
        info.nextEffects = nextLvl.effects
    end
    return info
end

--- 升级当前城市设施
--- @return boolean ok, string|nil err
function Market.UpgradeCityFacility()
    Market.ValidateFacility(playerData_)
    local facility = MarketData.GetCityFacility()
    if not facility then return false, "本城市无可升级设施" end

    local currentCity = playerData_.currentCity or "wakandaville"
    local level = playerData_.cityFacilities[currentCity] or 0
    local maxLevel = #facility.levels

    if level >= maxLevel then return false, "已满级" end

    local nextLvl = facility.levels[level + 1]
    if playerData_.money < nextLvl.cost then
        return false, "需要 $" .. nextLvl.cost
    end

    playerData_.money = playerData_.money - nextLvl.cost
    playerData_.cityFacilities[currentCity] = level + 1

    if AddLog then
        AddLog("🏗️ " .. facility.name .. " 升级到 Lv." .. (level + 1) .. "!")
    end
    return true, nil
end

--- 计算当前城市设施效果（供效果聚合使用）
--- @return table effects
function Market.CalcFacilityEffects()
    Market.ValidateFacility(playerData_)
    local effects = MarketData.GetCityFacilityEffects()
    return effects or {}
end

-- ============================================================
-- 每日城市税（在 EndDay/DailyTick 之后调用）
-- ============================================================

--- 扣除每日城市税，返回扣除金额
--- @return number taxAmount
function Market.ApplyDailyTax()
    local tax = MarketData.GetDailyTax and MarketData.GetDailyTax() or 0
    if tax > 0 and playerData_ then
        -- 城市设施可能减税
        local facilityEffects = Market.CalcFacilityEffects()
        local taxReduction = facilityEffects.taxReduction or 0
        tax = math.max(0, math.floor(tax * (1 - taxReduction)))

        if tax > 0 then
            playerData_.money = math.max(0, playerData_.money - tax)
            if AddLog then
                AddLog("🏛️ 缴纳城市运营税 $" .. tax)
            end
        end
    end
    return tax
end

--- 计算所有市场系统的聚合效果（装备 + 装饰 + 城市设施）
--- 供外部统一调用
--- @return table combinedEffects
function Market.CalcAllEffects()
    local eq = Market.CalcEquippedEffects()
    local deco = Market.CalcDecoEffects()
    local fac = Market.CalcFacilityEffects()

    local combined = {}
    -- 合并三层效果
    for _, src in ipairs({ eq, deco, fac }) do
        for k, v in pairs(src) do
            if k:sub(1, 1) ~= "_" then  -- 跳过内部标记
                if type(v) == "number" then
                    combined[k] = (combined[k] or 0) + v
                else
                    combined[k] = v
                end
            end
        end
    end
    -- 保留内部标记
    combined._activated = eq._activated
    combined._setBonus = deco._setBonus
    combined._placedCount = deco._placedCount
    return combined
end

return Market
