---@diagnostic disable: undefined-global
------------------------------------------------------------
-- UIDecoration.lua — 装饰可视化面板（Batch 3）
-- 展示装饰槽位、放置/移除操作、效果总览、套装奖励
------------------------------------------------------------

local MarketData = require("MarketData")
local Market     = require("Market")

-- ── 局部工具 ──

local function tierColor(tier)
    local t = MarketData.TIERS[tier]
    return t and t.color or C.text
end
local function tierStars(tier)
    local t = MarketData.TIERS[tier]
    return t and t.stars or "?"
end

--- 效果键的中文名
local EFFECT_LABELS = {
    equipDecayReduction = "设备损耗 ↓",
    trafficBonus        = "客流量 ↑",
    dailyMoneyBonus     = "每日额外收入",
    trainBonus          = "训练收益 ↑",
    matchPower          = "比赛战力 ↑",
    allRevenueBonus     = "全部收入 ↑",
    repBonus            = "声望增速 ↑",
    moodDecayReduction  = "心情衰减 ↓",
}

local function effectText(key, val)
    local label = EFFECT_LABELS[key] or key
    if type(val) ~= "number" then return label .. " " .. tostring(val) end
    if val >= 1 and key ~= "dailyMoneyBonus" then
        return label .. " " .. math.floor(val * 100) .. "%"
    else
        return label .. " +" .. (math.floor(val * 100) / 100)
    end
end

-- ============================================================
-- 装饰槽位卡片（单个槽位）
-- ============================================================

local function BuildSlotCard(slotIdx, slotData, maxSlots)
    if slotData and slotData.def then
        -- 已放置物品
        local def = slotData.def
        local tier = def.tier
        local tInfo = MarketData.TIERS[tier] or MarketData.TIERS[1]
        local borderC = { tInfo.color[1], tInfo.color[2], tInfo.color[3], 160 }

        return UI.Panel {
            width = 90, height = 110, padding = 6, borderRadius = PX.cardRadius,
            backgroundColor = { tInfo.color[1] * 0.15, tInfo.color[2] * 0.15, tInfo.color[3] * 0.15, 220 },
            borderWidth = PX.border, borderColor = borderC,
            alignItems = "center", justifyContent = "center", gap = 3,
            children = {
                UI.Label { text = def.icon, fontSize = 22 },
                UI.Label { text = def.name, fontSize = 10, fontColor = tierColor(tier), textAlign = "center", width = "100%" },
                UI.Label { text = tierStars(tier), fontSize = 9, fontColor = tierColor(tier) },
                UI.Button {
                    text = "移除", fontSize = 9, height = 20, width = "90%",
                    backgroundColor = { 140, 60, 60, 180 },
                    fontColor = { 255, 200, 200, 255 },
                    onClick = function()
                        Market.RemoveDeco(slotIdx)
                        AddLog("🪑 移除了装饰: " .. def.name)
                        BuildUI()
                    end,
                },
            },
        }
    else
        -- 空槽位
        return UI.Panel {
            width = 90, height = 110, padding = 6, borderRadius = PX.cardRadius,
            backgroundColor = { 40, 40, 50, 150 },
            borderWidth = 1, borderColor = { 80, 80, 100, 100 },
            alignItems = "center", justifyContent = "center", gap = 4,
            children = {
                UI.Label { text = "🪑", fontSize = 20 },
                UI.Label { text = "空槽位", fontSize = 10, fontColor = C.textDim },
                UI.Label { text = "#" .. slotIdx, fontSize = 9, fontColor = { 120, 120, 140, 150 } },
            },
        }
    end
end

-- ============================================================
-- 可放置物品列表
-- ============================================================

local function BuildAvailableItem(item, slotIdx)
    local def = item.def
    local tier = def.tier
    local tInfo = MarketData.TIERS[tier] or MarketData.TIERS[1]

    local effectItems = {}
    if def.effects then
        for k, v in pairs(def.effects) do
            table.insert(effectItems, UI.Label {
                text = "· " .. effectText(k, v),
                fontSize = 10, fontColor = { 180, 210, 180, 200 },
            })
        end
    end

    return UI.Panel {
        width = "100%", flexDirection = "row", padding = 8, borderRadius = PX.radius,
        backgroundColor = { 50, 45, 55, 180 },
        borderWidth = 1, borderColor = { tInfo.color[1], tInfo.color[2], tInfo.color[3], 80 },
        alignItems = "center", gap = 8,
        children = {
            UI.Label { text = def.icon, fontSize = 20, flexShrink = 0 },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, children = {
                    UI.Label { text = def.name, fontSize = 12, fontWeight = "bold", fontColor = tierColor(tier) },
                    UI.Label { text = tierStars(tier), fontSize = 10, fontColor = tierColor(tier) },
                }},
                table.unpack(effectItems),
            }},
            UI.Button {
                text = "放置", fontSize = 11, height = 28, width = 52,
                backgroundColor = { 60, 130, 80, 200 },
                fontColor = { 220, 255, 220, 255 },
                onClick = function()
                    local ok, err = Market.PlaceDeco(item.inst.uid, slotIdx)
                    if ok then
                        AddLog("🪑 放置了装饰: " .. def.name .. " → 槽位" .. slotIdx)
                    else
                        AddLog("⚠️ " .. (err or "放置失败"))
                    end
                    BuildUI()
                end,
            },
        },
    }
end

-- ============================================================
-- 主面板
-- ============================================================

--- 寻找第一个空槽位（用于"快速放置"按钮）
local function findFirstEmptySlot()
    Market.ValidateDeco(playerData_)
    for i = 1, playerData_.decoSlotsMax do
        if not playerData_.decoSlots[i] then return i end
    end
    return nil
end

function BuildDecorationPanel()
    Market.Validate(playerData_)
    Market.ValidateDeco(playerData_)

    -- 获取显示数据
    local slots, maxSlots = Market.GetDecoSlotsDisplay()
    local effects = Market.CalcDecoEffects()
    local available = Market.GetAvailableDecoItems()
    local emptySlot = findFirstEmptySlot()

    -- ── 装饰槽位网格 ──
    local slotCards = {}
    for i = 1, maxSlots do
        table.insert(slotCards, BuildSlotCard(i, slots[i], maxSlots))
    end

    local slotsGrid = UI.Panel {
        width = "100%", flexDirection = "row", flexWrap = "wrap",
        gap = 8, justifyContent = "center", padding = 6,
        children = slotCards,
    }

    -- ── 套装奖励指示器 ──
    local setBonusPanel = nil
    if effects._setBonus then
        setBonusPanel = UI.Panel {
            width = "100%", padding = 8, borderRadius = PX.radius,
            backgroundColor = { 80, 60, 20, 180 },
            borderWidth = PX.border, borderColor = { 255, 200, 50, 150 },
            flexDirection = "row", alignItems = "center", gap = 6,
            children = {
                UI.Label { text = "✨", fontSize = 16 },
                UI.Label { text = "套装奖励激活！全收入 +5%", fontSize = 13, fontWeight = "bold", fontColor = C.gold },
            },
        }
    elseif effects._placedCount > 0 then
        local remain = maxSlots - effects._placedCount
        setBonusPanel = UI.Panel {
            width = "100%", padding = 6, borderRadius = PX.radius,
            backgroundColor = { 40, 40, 50, 120 },
            flexDirection = "row", alignItems = "center", gap = 4,
            children = {
                UI.Label { text = "🧩", fontSize = 13 },
                UI.Label { text = "再放置 " .. remain .. " 件激活套装奖励", fontSize = 11, fontColor = C.textDim },
            },
        }
    end

    -- ── 效果总览 ──
    local effectsPanel = nil
    local effectEntries = {}
    for k, v in pairs(effects) do
        if type(v) == "number" and v > 0 and not k:match("^_") then
            table.insert(effectEntries, UI.Label {
                text = "• " .. effectText(k, v),
                fontSize = 11, fontColor = { 180, 220, 180, 220 },
            })
        end
    end
    if #effectEntries > 0 then
        effectsPanel = UI.Panel {
            width = "100%", padding = 8, borderRadius = PX.radius,
            backgroundColor = { 40, 55, 40, 160 },
            borderWidth = 1, borderColor = { 80, 140, 80, 80 },
            gap = 3,
            children = {
                UI.Label { text = "📊 装饰加成总览", fontSize = 12, fontWeight = "bold", fontColor = C.green },
                table.unpack(effectEntries),
            },
        }
    end

    -- ── 解锁按钮 ──
    local unlockBtn = nil
    if maxSlots < 6 then
        local costs = { [4] = 2000, [5] = 5000, [6] = 10000 }
        local nextCost = costs[maxSlots + 1] or 5000
        unlockBtn = UI.Button {
            text = "🔓 解锁第 " .. (maxSlots + 1) .. " 个槽位 ($" .. nextCost .. ")",
            fontSize = 12, height = 36, width = "100%",
            backgroundColor = playerData_.money >= nextCost and { 60, 100, 150, 200 } or { 60, 60, 60, 150 },
            fontColor = playerData_.money >= nextCost and { 200, 230, 255, 255 } or C.textDim,
            onClick = function()
                local ok, err = Market.UnlockDecoSlot()
                if ok then
                    AddLog("🔓 解锁了新装饰槽位！当前 " .. playerData_.decoSlotsMax .. " 个")
                    PlaySFX("upgrade")
                else
                    AddLog("⚠️ " .. (err or "解锁失败"))
                end
                BuildUI()
            end,
        }
    end

    -- ── 可放置装饰列表 ──
    local availablePanel = nil
    if emptySlot and #available > 0 then
        local itemCards = {}
        for i, item in ipairs(available) do
            if i > 6 then break end -- 最多显示6个
            table.insert(itemCards, BuildAvailableItem(item, emptySlot))
        end
        availablePanel = UI.Panel {
            width = "100%", gap = 4,
            children = {
                UI.Label { text = "🎁 可放置的装饰（" .. #available .. " 件）", fontSize = 12, fontWeight = "bold", fontColor = C.text },
                table.unpack(itemCards),
            },
        }
    elseif not emptySlot and #available > 0 then
        availablePanel = UI.Label {
            text = "所有槽位已满，移除现有装饰后可更换",
            fontSize = 11, fontColor = C.textDim, width = "100%",
        }
    elseif #available == 0 and effects._placedCount == 0 then
        availablePanel = UI.Label {
            text = "💡 在「市场」抽到装饰类物品后可在此放置",
            fontSize = 11, fontColor = C.textDim, width = "100%", whiteSpace = "normal",
        }
    end

    -- ── 组装面板 ──
    local panelChildren = {
        UI.Label { text = "🪑 网吧装饰", fontSize = 16, fontWeight = "bold", fontColor = C.text, width = "100%" },
        UI.Label { text = "放置装饰品美化网吧，获得被动加成", fontSize = 11, fontColor = C.textDim, width = "100%" },
        slotsGrid,
    }
    if setBonusPanel then table.insert(panelChildren, setBonusPanel) end
    if effectsPanel then table.insert(panelChildren, effectsPanel) end
    if unlockBtn then table.insert(panelChildren, unlockBtn) end
    if availablePanel then table.insert(panelChildren, availablePanel) end

    return UI.Panel {
        width = "100%", padding = 12, borderRadius = PX.radius,
        backgroundColor = { 35, 30, 45, 200 },
        borderWidth = PX.border, borderColor = { 120, 90, 160, 100 },
        gap = 8,
        children = panelChildren,
    }
end
