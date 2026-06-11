---@diagnostic disable: undefined-global
-- ============================================================================
-- EventLinkage.lua — 事件联动系统（Batch 6）
-- 跨系统联动：NPC故事线 × 装饰效果 × 城市碎片 × 章节进度
-- 核心机制：事件触发时检查多维条件，给予额外加成或触发连锁事件
-- ============================================================================

local EventLinkage = {}

-- ============================================================================
-- 1. 联动条件定义
-- ============================================================================

--- 联动规则表：当满足特定组合条件时，触发额外效果
--- 结构: { id, name, desc, conditions = {}, reward = function() }
EventLinkage.LINKAGES = {
    -- ────── NPC × 装饰 联动 ──────
    {
        id = "ada_tech_deco",
        name = "科技之心",
        desc = "Ada故事进展 + 拥有科技类装饰 → 设备维护费-20%",
        icon = "💡",
        conditions = {
            { type = "npc_stage", npcId = "ada", minStage = 2 },
            { type = "deco_category_equipped", category = "functional" },
        },
        reward = { equipDecayReduction = 0.20 },
        flavor = "Ada帮你优化了设备管理系统，维护成本大幅降低！",
    },
    {
        id = "mama_b_food_deco",
        name = "美食天堂",
        desc = "Mama B故事进展 + 拥有食物相关装饰 → 客流+15%",
        icon = "🍽️",
        conditions = {
            { type = "npc_stage", npcId = "mama_b", minStage = 2 },
            { type = "item_owned", itemId = "incense_burner" },  -- 非洲鼓形香薰
        },
        reward = { trafficBonus = 0.15 },
        flavor = "Mama B的美食加上好氛围，客人都不想走了！",
    },
    {
        id = "dj_pulse_vibe",
        name = "电音氛围",
        desc = "DJ Pulse故事进展 + 唱片机装饰 → 心情衰减-30%",
        icon = "🎵",
        conditions = {
            { type = "npc_stage", npcId = "dj_pulse", minStage = 1 },
            { type = "item_owned", itemId = "jukebox_vinyl" },  -- 复古唱片机
        },
        reward = { moodDecayReduction = 0.30 },
        flavor = "DJ Pulse的歌单让整个网吧活力满满！",
    },

    -- ────── NPC × 城市碎片 联动 ──────
    {
        id = "ada_nairobi_synergy",
        name = "硅谷桥梁",
        desc = "Ada故事完成 + 拥有内罗毕碎片 → 每日额外+$50",
        icon = "🌐",
        conditions = {
            { type = "npc_stage", npcId = "ada", minStage = 3 },
            { type = "item_owned", itemId = "frag_nairobi" },
        },
        reward = { dailyMoneyBonus = 50 },
        flavor = "Ada帮你联系了内罗毕的科技公司，带来稳定的远程办公客户！",
    },
    {
        id = "dj_pulse_lagos_synergy",
        name = "音浪传奇",
        desc = "DJ Pulse故事完成 + 拥有拉各斯碎片 → 声望获取+20%",
        icon = "🎧",
        conditions = {
            { type = "npc_stage", npcId = "dj_pulse", minStage = 3 },
            { type = "item_owned", itemId = "frag_lagos" },
        },
        reward = { repBonus = 0.20 },
        flavor = "DJ Pulse在拉各斯的演出总提到你的网吧，名声远播！",
    },

    -- ────── 装饰 × 城市碎片 联动 ──────
    {
        id = "full_deco_city_boost",
        name = "地标网吧",
        desc = "装饰槽全满 + 任意城市碎片 → 全收入+8%",
        icon = "🏆",
        conditions = {
            { type = "deco_slots_full" },
            { type = "any_cityfrag" },
        },
        reward = { allRevenueBonus = 0.08 },
        flavor = "你的网吧已经成了当地地标！连外地游客都慕名而来。",
    },

    -- ────── 三系统联动（终极联动）──────
    {
        id = "triple_synergy",
        name = "非洲网王",
        desc = "任意NPC完成 + 装饰全满 + 城市碎片≥3 → 全收入+15%",
        icon = "👑",
        conditions = {
            { type = "any_npc_complete" },
            { type = "deco_slots_full" },
            { type = "cityfrag_count", min = 3 },
        },
        reward = { allRevenueBonus = 0.15 },
        flavor = "横跨多城、故事传奇、装饰华丽——你就是非洲网王！",
    },
    {
        id = "kofi_snake_secret",
        name = "暗夜骑手",
        desc = "Kofi和Snake故事都完成 → 解锁秘密任务奖励",
        icon = "🌙",
        conditions = {
            { type = "npc_stage", npcId = "kofi", minStage = 4 },
            { type = "npc_stage", npcId = "snake", minStage = 4 },
        },
        reward = { dailyMoneyBonus = 30, matchPower = 3 },
        flavor = "Kofi和Snake的故事交织出一段传奇——深夜的网吧里，总有人在默默守护。",
    },
}

-- ============================================================================
-- 2. 条件检查引擎
-- ============================================================================

--- 检查单个条件是否满足
---@param cond table 条件定义
---@return boolean
local function checkCondition(cond)
    if not playerData_ then return false end

    if cond.type == "npc_stage" then
        local progress = playerData_.npcStoryProgress or {}
        return (progress[cond.npcId] or 0) >= (cond.minStage or 1)

    elseif cond.type == "item_owned" then
        if not playerData_.marketInventory then return false end
        for _, inst in ipairs(playerData_.marketInventory) do
            if inst.id == cond.itemId then return true end
        end
        return false

    elseif cond.type == "deco_category_equipped" then
        -- 装饰槽中有指定类别的物品（decoSlots[i] = uid 整数）
        if not playerData_.decoSlots then return false end
        local okMD, MarketData = pcall(require, "MarketData")
        if not okMD then return false end
        for _, uid in pairs(playerData_.decoSlots) do
            if uid then
                -- uid → 查 inventory 找 inst.id → 查 ITEMS_BY_ID 找 def
                for _, inst in ipairs(playerData_.marketInventory or {}) do
                    if inst.uid == uid then
                        local def = MarketData.ITEMS_BY_ID and MarketData.ITEMS_BY_ID[inst.id]
                        if def and def.category == cond.category then return true end
                        break
                    end
                end
            end
        end
        return false

    elseif cond.type == "deco_slots_full" then
        if not playerData_.decoSlots then return false end
        local maxSlots = playerData_.decoSlotsMax or 3
        local filled = 0
        for i = 1, maxSlots do
            if playerData_.decoSlots[i] then filled = filled + 1 end
        end
        return filled >= maxSlots

    elseif cond.type == "any_cityfrag" then
        if not playerData_.marketInventory then return false end
        local okMD, MarketData = pcall(require, "MarketData")
        if not okMD then return false end
        for _, inst in ipairs(playerData_.marketInventory) do
            local def = MarketData.ITEMS_BY_ID and MarketData.ITEMS_BY_ID[inst.id]
            if def and def.category == "cityfrag" then return true end
        end
        return false

    elseif cond.type == "cityfrag_count" then
        if not playerData_.marketInventory then return false end
        local okMD, MarketData = pcall(require, "MarketData")
        if not okMD then return false end
        local count = 0
        for _, inst in ipairs(playerData_.marketInventory) do
            local def = MarketData.ITEMS_BY_ID and MarketData.ITEMS_BY_ID[inst.id]
            if def and def.category == "cityfrag" then count = count + 1 end
        end
        return count >= (cond.min or 1)

    elseif cond.type == "any_npc_complete" then
        local progress = playerData_.npcStoryProgress or {}
        -- 任意NPC达到最大阶段（原始3人=4阶段，新增3人=3阶段）
        local maxStages = { kofi = 4, grace = 4, snake = 4, ada = 3, mama_b = 3, dj_pulse = 3 }
        for npcId, maxS in pairs(maxStages) do
            if (progress[npcId] or 0) >= maxS then return true end
        end
        return false

    elseif cond.type == "chapter_unlocked" then
        local okCS, ChapterSys = pcall(require, "ChapterSystem")
        if okCS and ChapterSys and ChapterSys.IsUnlocked then
            return ChapterSys.IsUnlocked(cond.key)
        end
        return false
    end

    return false
end

-- ============================================================================
-- 3. 联动效果计算
-- ============================================================================

--- 获取当前所有激活的联动效果
---@return table activeLinkages 激活的联动列表
---@return table totalEffects 合并后的总效果
function EventLinkage.GetActiveLinkages()
    local active = {}
    local effects = {}

    for _, linkage in ipairs(EventLinkage.LINKAGES) do
        local allMet = true
        for _, cond in ipairs(linkage.conditions) do
            if not checkCondition(cond) then
                allMet = false
                break
            end
        end
        if allMet then
            table.insert(active, linkage)
            -- 合并效果
            if linkage.reward then
                for k, v in pairs(linkage.reward) do
                    effects[k] = (effects[k] or 0) + v
                end
            end
        end
    end

    return active, effects
end

--- 获取联动效果的收入加成（供 CalcDailyIncome 调用）
---@return number incomeMultiplier 额外收入倍率（如 0.15 表示 +15%）
---@return number flatBonus 额外固定金额
function EventLinkage.GetIncomeBonus()
    local _, effects = EventLinkage.GetActiveLinkages()
    local multi = (effects.allRevenueBonus or 0)
    local flat = (effects.dailyMoneyBonus or 0)
    return multi, flat
end

--- 获取联动效果中的非收入加成（供其他系统查询）
---@return table effects 所有联动效果合集
function EventLinkage.GetAllEffects()
    local _, effects = EventLinkage.GetActiveLinkages()
    return effects
end

-- ============================================================================
-- 4. 联动进度查询（供UI显示）
-- ============================================================================

--- 获取所有联动的进度状态
---@return table list { linkage, active, progress (0~1), unmetConditions }
function EventLinkage.GetLinkageProgress()
    local result = {}
    for _, linkage in ipairs(EventLinkage.LINKAGES) do
        local metCount = 0
        local totalConds = #linkage.conditions
        local unmet = {}
        for _, cond in ipairs(linkage.conditions) do
            if checkCondition(cond) then
                metCount = metCount + 1
            else
                table.insert(unmet, cond)
            end
        end
        table.insert(result, {
            linkage = linkage,
            active = (metCount == totalConds),
            progress = totalConds > 0 and (metCount / totalConds) or 0,
            metCount = metCount,
            totalConds = totalConds,
            unmetConditions = unmet,
        })
    end
    return result
end

--- 获取已激活联动数量和总联动数量
---@return number active 已激活
---@return number total 总数
function EventLinkage.GetLinkageSummary()
    local active = 0
    for _, linkage in ipairs(EventLinkage.LINKAGES) do
        local allMet = true
        for _, cond in ipairs(linkage.conditions) do
            if not checkCondition(cond) then allMet = false; break end
        end
        if allMet then active = active + 1 end
    end
    return active, #EventLinkage.LINKAGES
end

-- ============================================================================
-- 5. 联动事件通知（可嵌入日结算）
-- ============================================================================

--- 检查是否有新解锁的联动（与上次检查对比）
--- 应在 EndDay 中调用，记录新激活的联动并通知玩家
---@return table|nil newlyActivated 新激活的联动列表
function EventLinkage.CheckNewLinkages()
    if not playerData_ then return nil end
    local claimed = playerData_.linkagesClaimed or {}
    local newOnes = {}

    for _, linkage in ipairs(EventLinkage.LINKAGES) do
        if not claimed[linkage.id] then
            local allMet = true
            for _, cond in ipairs(linkage.conditions) do
                if not checkCondition(cond) then allMet = false; break end
            end
            if allMet then
                claimed[linkage.id] = true
                table.insert(newOnes, linkage)
                if AddLog then
                    AddLog(linkage.icon .. " 【联动解锁】" .. linkage.name .. "！" .. linkage.flavor)
                end
            end
        end
    end

    playerData_.linkagesClaimed = claimed
    if #newOnes > 0 then
        return newOnes
    end
    return nil
end

return EventLinkage
