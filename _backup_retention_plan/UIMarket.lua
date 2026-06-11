---@diagnostic disable: undefined-global
------------------------------------------------------------
-- UIMarket.lua — 二手市场 UI
-- 两个子页: "淘货"(抽卡)  |  "背包"(装备/回收/融合)
------------------------------------------------------------

local MarketData = require("MarketData")
local Market     = require("Market")

-- ── 状态 ──
local marketSubTab_ = "pull"       -- "pull" | "bag"
local pullResults_  = nil          -- 上一次抽卡结果（展示用）
local fuseSelection_ = {}         -- 融合选中的uid列表(最多3)
local bagFilter_ = 0              -- 背包品质过滤: 0=全部,1-5=指定品质

-- ============================================================
-- 小工具
-- ============================================================

local function tierColor(tier)
    local t = MarketData.TIERS[tier]
    return t and t.color or C.text
end
local function tierName(tier)
    local t = MarketData.TIERS[tier]
    return t and t.name or "未知"
end
local function tierStars(tier)
    local t = MarketData.TIERS[tier]
    return t and t.stars or "?"
end

--- 耐久度条颜色
local function durColor(pct)
    if pct > 60 then return { 90, 180, 90, 255 } end
    if pct > 30 then return { 220, 180, 50, 255 } end
    return { 220, 70, 50, 255 }
end

--- 效果键的中文名
local EFFECT_LABELS = {
    equipDecayReduction = "设备损耗 ↓",
    trafficBonus        = "客流量 ↑",
    dailyMoneyBonus     = "每日额外收入",
    trainBonus          = "训练收益 ↑",
    matchPower          = "比赛战力 ↑",
    blackoutImmunity    = "断电免疫",
    allRevenueBonus     = "全部收入 ↑",
    repBonus            = "声望增速 ↑",
    moodDecayReduction  = "心情衰减 ↓",
    matchCostReduction  = "比赛费用 ↓",
    apBonus             = "每日额外AP",
    salaryReduction     = "工资支出 ↓",
    goldenHourBonus     = "黄金时段 ↑",
    microEventBonus     = "微事件奖励 ↑",
    moodFloor           = "心情下限",
}

local function effectText(key, val)
    local label = EFFECT_LABELS[key] or key
    if val == 1 and (key == "blackoutImmunity") then
        return label
    elseif val >= 1 and key ~= "matchPower" and key ~= "dailyMoneyBonus" and key ~= "apBonus" and key ~= "moodFloor" then
        return label .. " " .. math.floor(val * 100) .. "%"
    else
        return label .. " +" .. (math.floor(val * 100) / 100)
    end
end

-- ============================================================
-- 抽卡结果展示卡片
-- ============================================================

local function BuildPullResultCard(item)
    local def = item.def
    local inst = item.inst
    local tier = def.tier
    local tInfo = MarketData.TIERS[tier] or MarketData.TIERS[1]
    local bgAlpha = math.min(180 + tier * 15, 240)

    local effectItems = {}
    if def.effects then
        for k, v in pairs(def.effects) do
            table.insert(effectItems, UI.Label {
                text = "· " .. effectText(k, v),
                fontSize = 11, fontColor = { 200, 230, 200, 220 }, width = "100%",
            })
        end
    end

    return UI.Panel {
        width = "100%", padding = 10, borderRadius = PX.cardRadius,
        backgroundColor = { tInfo.color[1] * 0.2, tInfo.color[2] * 0.2, tInfo.color[3] * 0.2, bgAlpha },
        borderWidth = PX.border,
        borderColor = { tInfo.color[1], tInfo.color[2], tInfo.color[3], tier >= 4 and 200 or 80 },
        gap = 4,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                children = {
                    UI.Label { text = def.icon, fontSize = 24 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Label { text = def.name, fontSize = 14, fontWeight = "bold", fontColor = tierColor(tier) },
                        UI.Label { text = tierStars(tier) .. " " .. tierName(tier), fontSize = 11, fontColor = tierColor(tier) },
                    }},
                    UI.Label { text = "耐久 " .. inst.dur .. "/" .. inst.maxDur, fontSize = 11, fontColor = C.textLight },
                },
            },
            UI.Label { text = def.flavor, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal", width = "100%" },
            table.unpack(effectItems),
        },
    }
end

-- ============================================================
-- "淘货" 子页面
-- ============================================================

local function BuildPullView()
    Market.Validate(playerData_)
    local stats = Market.GetStats()
    local coins = playerData_.havocCoins or 0
    local dailyFree = not playerData_.marketDailyFree

    -- 顶部信息栏
    local headerPanel = UI.Panel {
        width = "100%", flexDirection = "row", justifyContent = "space-between",
        alignItems = "center", padding = 8, borderRadius = 8,
        backgroundColor = C.card, gap = 4,
        children = {
            UI.Label { text = "🪙 " .. coins, fontSize = 15, fontWeight = "bold", fontColor = C.gold },
            UI.Label { text = "背包 " .. stats.totalItems .. " 件 · 已抽 " .. stats.totalPulls .. " 次", fontSize = 12, fontColor = C.textLight },
        },
    }

    -- 保底提示
    local pityText = "距保底: " .. (MarketData.PITY.legendHard - stats.pityCounter) .. " 抽"
    if stats.pityCounter >= MarketData.PITY.legendSoft then
        pityText = pityText .. " (软保底中 🔥)"
    end
    local pityLabel = UI.Label {
        text = pityText, fontSize = 11, fontColor = { 255, 200, 100, 200 }, width = "100%", textAlign = "center",
    }

    -- 抽卡按钮区
    local pullButtons = {}

    -- 免费/单抽
    local singleText = dailyFree and "✨ 每日免费单抽" or ("单抽 · " .. MarketData.PULL_COST.single .. "🪙")
    table.insert(pullButtons, UI.Button {
        text = singleText, fontSize = 14, height = 44, flex = 1,
        backgroundColor = dailyFree and { 60, 140, 50, 240 } or nil,
        fontColor = dailyFree and { 220, 255, 210, 255 } or nil,
        borderWidth = dailyFree and PX.border or nil,
        borderColor = dailyFree and { 90, 200, 80, 200 } or nil,
        onClick = function()
            local results, err = Market.Pull("single")
            if err then
                AddLog("❌ " .. err)
            else
                pullResults_ = results
                AddLog("🎰 " .. (dailyFree and "免费" or "花费" .. MarketData.PULL_COST.single .. "🪙") .. "单抽！得到: " .. results[1].def.icon .. " " .. results[1].def.name)
                PlaySFX("coin")
            end
            BuildUI()
        end,
    })

    -- 十连抽
    table.insert(pullButtons, UI.Button {
        text = "十连抽 · " .. MarketData.PULL_COST.ten .. "🪙", fontSize = 14, height = 44, flex = 1,
        variant = "default",
        onClick = function()
            local results, err = Market.Pull("ten")
            if err then
                AddLog("❌ " .. err)
            else
                pullResults_ = results
                local t5, t4, t3 = 0, 0, 0
                for _, r in ipairs(results) do
                    if r.def.tier == 5 then t5 = t5 + 1
                    elseif r.def.tier == 4 then t4 = t4 + 1
                    elseif r.def.tier == 3 then t3 = t3 + 1 end
                end
                local summary = "🎰 十连抽！"
                if t5 > 0 then summary = summary .. " 🌟×" .. t5 end
                if t4 > 0 then summary = summary .. " 💜×" .. t4 end
                if t3 > 0 then summary = summary .. " 💙×" .. t3 end
                AddLog(summary)
                PlaySFX("coin")
            end
            BuildUI()
        end,
    })

    local pullBtnRow = UI.Panel {
        width = "100%", flexDirection = "row", gap = 8,
        children = pullButtons,
    }

    -- 现金单抽
    local moneyPull = UI.Button {
        text = "💵 现金单抽 · $" .. MarketData.PULL_COST.money, fontSize = 13, height = 38, width = "100%",
        backgroundColor = C.adBg, fontColor = C.adText,
        borderWidth = 1, borderColor = C.adBorder,
        onClick = function()
            local results, err = Market.Pull("money_single")
            if err then
                AddLog("❌ " .. err)
            else
                pullResults_ = results
                AddLog("💵 花费$" .. MarketData.PULL_COST.money .. "现金抽卡！得到: " .. results[1].def.icon .. " " .. results[1].def.name)
                PlaySFX("coin")
            end
            BuildUI()
        end,
    }

    -- 广告单抽
    local adPull = nil
    if AdManager and AdManager.AdButton then
        adPull = AdManager.AdButton {
            sceneId = "market_pull", day = playerData_.day,
            text = "📺 看广告免费抽1次",
            fontSize = 13, height = 38, width = "100%",
            onReward = function()
                local inst, def = Market.DoPullOne()
                pullResults_ = { { inst = inst, def = def } }
                AddLog("📺 广告奖励抽卡！得到: " .. def.icon .. " " .. def.name)
                PlaySFX("coin")
                BuildUI()
            end,
        }
    end

    -- 抽卡结果区
    local resultChildren = {}
    if pullResults_ and #pullResults_ > 0 then
        table.insert(resultChildren, UI.Label {
            text = "── 本次获得 ──", fontSize = 13, fontColor = C.textDim, width = "100%", textAlign = "center",
        })
        for _, item in ipairs(pullResults_) do
            table.insert(resultChildren, BuildPullResultCard(item))
        end
    end

    -- 概率公示
    local rateText = "概率: ★60% ★★30% ★★★14% ★★★★5% ★★★★★1% · 保底详情见下"
    local rateLabel = UI.Label {
        text = rateText, fontSize = 10, fontColor = C.textLight, whiteSpace = "normal", width = "100%",
    }

    -- 组合
    local children = { headerPanel, pityLabel, pullBtnRow, moneyPull }
    if adPull then table.insert(children, adPull) end
    if #resultChildren > 0 then
        for _, rc in ipairs(resultChildren) do
            table.insert(children, rc)
        end
    end
    table.insert(children, rateLabel)

    return UI.Panel { width = "100%", gap = 8, children = children }
end

-- ============================================================
-- "背包" 子页面
-- ============================================================

local function BuildBagView()
    Market.Validate(playerData_)
    local items = Market.GetInventoryDisplay()
    local slotsDisplay = Market.GetSlotsDisplay()
    local stats = Market.GetStats()

    local children = {}

    -- ── 装备栏区 ──
    local slotCards = {}
    for i = 1, playerData_.marketSlots do
        local sd = slotsDisplay[i]
        if sd then
            local def = sd.def
            local inst = sd.inst
            table.insert(slotCards, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                padding = 8, borderRadius = PX.cardRadius, gap = 8,
                backgroundColor = { 50, 55, 45, 200 },
                borderWidth = PX.border, borderColor = tierColor(def.tier),
                children = {
                    UI.Label { text = "槽" .. i, fontSize = 11, fontColor = C.textLight, width = 28 },
                    UI.Label { text = def.icon, fontSize = 20 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Label { text = def.name, fontSize = 13, fontWeight = "bold", fontColor = tierColor(def.tier) },
                        UI.Panel { width = "100%", flexDirection = "row", gap = 6, children = {
                            UI.Label { text = tierStars(def.tier), fontSize = 10, fontColor = tierColor(def.tier) },
                            UI.Label { text = "耐久 " .. inst.dur .. "/" .. inst.maxDur, fontSize = 10, fontColor = durColor(sd.durPct) },
                        }},
                    }},
                    UI.Button {
                        text = "卸下", fontSize = 11, height = 28, width = 48,
                        onClick = function()
                            Market.Unequip(i)
                            AddLog("🔽 卸下了 " .. def.name)
                            BuildUI()
                        end,
                    },
                },
            })
        else
            table.insert(slotCards, UI.Panel {
                width = "100%", padding = 8, borderRadius = 8,
                backgroundColor = { 40, 40, 40, 120 },
                borderWidth = 1, borderColor = C.border, borderStyle = "dashed",
                justifyContent = "center", alignItems = "center", height = 44,
                children = {
                    UI.Label { text = "槽" .. i .. " · 空", fontSize = 12, fontColor = C.textLight },
                },
            })
        end
    end

    -- ── P2-1: 装备智能推荐（预计算，稍后插入装备栏之后）──
    local recommendPanel = nil
    do
        local hasEmptySlot = false
        for si = 1, playerData_.marketSlots do
            if not playerData_.marketEquipped[si] then hasEmptySlot = true; break end
        end
        if hasEmptySlot and #items > 0 then
            local WEIGHT = {
                matchPower = 30, trainBonus = 20, trafficBonus = 15,
                allRevenueBonus = 25, dailyMoneyBonus = 0.5, repBonus = 10,
                goldenHourBonus = 15, apBonus = 8, blackoutImmunity = 20,
            }
            local bestItem, bestScore = nil, -1
            for _, item in ipairs(items) do
                if not item.equipped and item.inst.dur > 0 then
                    local score = (item.tier or 1) * 20
                    if item.def.effects then
                        for k, v in pairs(item.def.effects) do
                            local w = WEIGHT[k] or 5
                            score = score + v * w
                        end
                    end
                    if score > bestScore then
                        bestScore = score
                        bestItem = item
                    end
                end
            end
            if bestItem then
                local bd = bestItem.def
                local bi = bestItem.inst
                local emptySlot = nil
                for si = 1, playerData_.marketSlots do
                    if not playerData_.marketEquipped[si] then emptySlot = si; break end
                end
                local efSummary = {}
                if bd.effects then
                    for k, v in pairs(bd.effects) do
                        table.insert(efSummary, effectText(k, v))
                        if #efSummary >= 2 then break end
                    end
                end
                local efStr = #efSummary > 0 and table.concat(efSummary, "  ") or "无特殊加成"
                recommendPanel = UI.Panel {
                    width = "100%", padding = 8, borderRadius = 8,
                    backgroundColor = { 30, 60, 30, 200 },
                    borderWidth = 1, borderColor = { 100, 200, 100, 160 },
                    flexDirection = "row", alignItems = "center", gap = 8,
                    children = {
                        UI.Label { text = "💡", fontSize = 18, flexShrink = 0 },
                        UI.Panel { flex = 1, gap = 2, children = {
                            UI.Label {
                                text = "推荐装备: " .. bd.icon .. " " .. bd.name,
                                fontSize = 12, fontWeight = "bold", fontColor = { 160, 230, 160, 240 }, flexShrink = 1,
                            },
                            UI.Label {
                                text = efStr,
                                fontSize = 10, fontColor = { 130, 200, 130, 180 }, flexShrink = 1,
                            },
                        }},
                        UI.Button {
                            text = "一键装备", fontSize = 11, height = 30, width = 64,
                            backgroundColor = { 50, 140, 50, 230 },
                            fontColor = { 220, 255, 220, 255 },
                            onClick = function()
                                local ok, err2 = Market.Equip(bi.uid, emptySlot)
                                if ok then
                                    AddLog("💡 智能推荐: 装备了 " .. bd.name .. " → 槽" .. emptySlot)
                                    PlaySFX("coin")
                                else
                                    AddLog("❌ " .. (err2 or "装备失败"))
                                end
                                BuildUI()
                            end,
                        },
                    },
                }
            end
        end
    end

    -- 槽位解锁按钮
    local nextSlot, slotErr = Market.GetNextSlotUnlock()
    local slotUnlockBtn = nil
    if nextSlot then
        slotUnlockBtn = UI.Button {
            text = "🔓 解锁第" .. nextSlot.slots .. "格 (" .. nextSlot.cost .. "🪙)",
            fontSize = 12, height = 34, width = "100%",
            onClick = function()
                local ok, err2 = Market.UnlockSlot()
                if ok then
                    AddLog("🔓 解锁了装备栏第 " .. playerData_.marketSlots .. " 格！")
                    PlaySFX("coin")
                else
                    AddLog("❌ " .. (err2 or "解锁失败"))
                end
                BuildUI()
            end,
        }
    end

    table.insert(children, UI.Panel {
        width = "100%", padding = 10, borderRadius = 10,
        backgroundColor = { 40, 50, 40, 180 },
        borderWidth = 1, borderColor = { 100, 140, 100, 80 },
        gap = 6,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    UI.Label { text = "⚔️ 装备栏 (" .. playerData_.marketSlots .. "格)", fontSize = 15, fontWeight = "bold", fontColor = C.text },
                    UI.Label { text = "🪙 " .. (playerData_.havocCoins or 0), fontSize = 13, fontColor = C.gold },
                },
            },
            table.unpack(slotCards),
        },
    })
    if slotUnlockBtn then table.insert(children, slotUnlockBtn) end
    -- P2-1 推荐横幅紧跟装备栏下方
    if recommendPanel then table.insert(children, recommendPanel) end

    -- ── 当前聚合效果 ──
    local effects = Market.CalcEquippedEffects()
    local activatedList = effects._activated or {}
    local effectLabels = {}
    for k, v in pairs(effects) do
        if k ~= "_activated" and v ~= 0 then
            table.insert(effectLabels, UI.Label {
                text = "✦ " .. effectText(k, v), fontSize = 12, fontColor = { 180, 220, 180, 230 }, width = "100%",
            })
        end
    end
    -- P2: 激活效应提示
    if #activatedList > 0 then
        for _, act in ipairs(activatedList) do
            table.insert(effectLabels, UI.Label {
                text = "⚡ " .. act.name .. " 激活(" .. act.cond .. ")",
                fontSize = 11, fontColor = { 255, 200, 80, 240 }, width = "100%",
            })
        end
    end
    if #effectLabels > 0 then
        table.insert(children, UI.Panel {
            width = "100%", padding = 8, borderRadius = 8,
            backgroundColor = { 35, 45, 35, 150 }, gap = 3,
            children = {
                UI.Label { text = "当前装备加成", fontSize = 13, fontWeight = "bold", fontColor = C.text, width = "100%" },
                table.unpack(effectLabels),
            },
        })
    end

    -- ── 品质过滤 ──
    local filterBtns = {}
    local filterOpts = { { tier = 0, label = "全部" } }
    for t = 5, 1, -1 do
        table.insert(filterOpts, { tier = t, label = tierStars(t) .. "(" .. stats.tierCounts[t] .. ")" })
    end
    for _, fo in ipairs(filterOpts) do
        local isActive = (bagFilter_ == fo.tier)
        table.insert(filterBtns, UI.Button {
            text = fo.label, fontSize = 10, height = 26,
            backgroundColor = isActive and C.accent or C.card,
            fontColor = isActive and C.text or C.textLight,
            onClick = function()
                bagFilter_ = fo.tier
                BuildUI()
            end,
        })
    end
    table.insert(children, UI.Panel {
        width = "100%", flexDirection = "row", gap = 4, flexWrap = "wrap",
        children = filterBtns,
    })

    -- ── 批量回收 ──
    table.insert(children, UI.Panel {
        width = "100%", flexDirection = "row", gap = 6,
        children = {
            UI.Button {
                text = "♻️ 回收★以下", fontSize = 11, height = 30, flex = 1,
                onClick = function()
                    local coins, count = Market.RecycleBatch(1)
                    if count > 0 then
                        AddLog("♻️ 回收了 " .. count .. " 件路边货，获得 " .. coins .. "🪙")
                        PlaySFX("coin")
                    else
                        AddLog("没有可回收的★物品")
                    end
                    BuildUI()
                end,
            },
            UI.Button {
                text = "♻️ 回收★★以下", fontSize = 11, height = 30, flex = 1,
                onClick = function()
                    local coins, count = Market.RecycleBatch(2)
                    if count > 0 then
                        AddLog("♻️ 回收了 " .. count .. " 件低品质物品，获得 " .. coins .. "🪙")
                        PlaySFX("coin")
                    else
                        AddLog("没有可回收的★★以下物品")
                    end
                    BuildUI()
                end,
            },
        },
    })

    -- ── 背包物品列表 ──
    local filteredItems = {}
    for _, item in ipairs(items) do
        if bagFilter_ == 0 or item.tier == bagFilter_ then
            table.insert(filteredItems, item)
        end
    end

    if #filteredItems == 0 then
        table.insert(children, UI.Label {
            text = "背包空空如也，去淘货吧！", fontSize = 13, fontColor = C.textDim,
            width = "100%", textAlign = "center", padding = 20,
        })
    else
        for _, item in ipairs(filteredItems) do
            local def = item.def
            local inst = item.inst

            -- 效果文字
            local efTexts = {}
            if def.effects then
                for k, v in pairs(def.effects) do
                    table.insert(efTexts, effectText(k, v))
                end
            end
            local efStr = #efTexts > 0 and table.concat(efTexts, " · ") or ""

            -- 操作按钮
            local actionBtns = {}
            if item.equipped then
                table.insert(actionBtns, UI.Label { text = "已装备", fontSize = 11, fontColor = C.green, width = 50 })
            else
                -- 找第一个空槽位
                local emptySlot = nil
                for si = 1, playerData_.marketSlots do
                    if not playerData_.marketEquipped[si] then
                        emptySlot = si
                        break
                    end
                end
                if emptySlot and inst.dur > 0 then
                    table.insert(actionBtns, UI.Button {
                        text = "装备", fontSize = 10, height = 26, width = 44,
                        variant = "primary",
                        onClick = function()
                            local ok, err = Market.Equip(inst.uid, emptySlot)
                            if ok then
                                AddLog("⚔️ 装备了 " .. def.name .. " → 槽" .. emptySlot)
                            else
                                AddLog("❌ " .. (err or "装备失败"))
                            end
                            BuildUI()
                        end,
                    })
                end
                table.insert(actionBtns, UI.Button {
                    text = "回收", fontSize = 10, height = 26, width = 44,
                    onClick = function()
                        local coins, err = Market.Recycle(inst.uid)
                        if coins then
                            AddLog("♻️ 回收 " .. def.name .. "，获得 " .. coins .. "🪙")
                            PlaySFX("coin")
                        else
                            AddLog("❌ " .. (err or "回收失败"))
                        end
                        BuildUI()
                    end,
                })

                -- 融合选中
                local inFuse = false
                for _, fuid in ipairs(fuseSelection_) do
                    if fuid == inst.uid then inFuse = true; break end
                end
                if not item.equipped then
                    table.insert(actionBtns, UI.Button {
                        text = inFuse and "取消" or "融合",
                        fontSize = 10, height = 26, width = 44,
                        backgroundColor = inFuse and C.accent or nil,
                        onClick = function()
                            if inFuse then
                                for fi = #fuseSelection_, 1, -1 do
                                    if fuseSelection_[fi] == inst.uid then
                                        table.remove(fuseSelection_, fi)
                                        break
                                    end
                                end
                            else
                                if #fuseSelection_ < 3 then
                                    table.insert(fuseSelection_, inst.uid)
                                else
                                    AddLog("⚠️ 最多选择3件物品融合")
                                end
                            end
                            BuildUI()
                        end,
                    })
                end
            end

            local borderC = item.equipped and { 100, 180, 100, 150 } or { tierColor(def.tier)[1], tierColor(def.tier)[2], tierColor(def.tier)[3], 60 }

            table.insert(children, UI.Panel {
                width = "100%", padding = 8, borderRadius = 8,
                backgroundColor = { 45, 40, 38, 200 },
                borderWidth = 1, borderColor = borderC, gap = 4,
                children = {
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                        children = {
                            UI.Label { text = def.icon, fontSize = 20, width = 28 },
                            UI.Panel { flex = 1, gap = 2, children = {
                                UI.Label { text = def.name, fontSize = 13, fontWeight = "bold", fontColor = tierColor(def.tier) },
                                UI.Panel { width = "100%", flexDirection = "row", gap = 6, children = {
                                    UI.Label { text = tierStars(def.tier), fontSize = 10, fontColor = tierColor(def.tier) },
                                    UI.Label { text = inst.dur .. "/" .. inst.maxDur, fontSize = 10, fontColor = durColor(item.durPct) },
                                }},
                            }},
                            UI.Panel { flexDirection = "row", gap = 4, children = actionBtns },
                        },
                    },
                    efStr ~= "" and UI.Label { text = efStr, fontSize = 10, fontColor = C.textLight, whiteSpace = "normal", width = "100%" } or nil,
                },
            })
        end
    end

    -- ── 融合面板 ──
    if #fuseSelection_ > 0 then
        local fuseNames = {}
        for _, uid in ipairs(fuseSelection_) do
            for _, it in ipairs(playerData_.marketInventory) do
                if it.uid == uid then
                    local d = MarketData.ITEMS_BY_ID[it.id]
                    table.insert(fuseNames, d and d.icon or "?")
                    break
                end
            end
        end
        local fusePanel = UI.Panel {
            width = "100%", padding = 10, borderRadius = 10,
            backgroundColor = { 60, 40, 60, 200 },
            borderWidth = 1, borderColor = { 180, 120, 220, 120 },
            gap = 6,
            children = {
                UI.Label {
                    text = "🔮 融合 (" .. #fuseSelection_ .. "/3): " .. table.concat(fuseNames, " + "),
                    fontSize = 13, fontWeight = "bold", fontColor = { 200, 170, 255, 240 }, width = "100%",
                },
                UI.Label {
                    text = "选择3件相同品质的物品 → 融合为1件更高品质物品",
                    fontSize = 11, fontColor = C.textLight, whiteSpace = "normal", width = "100%",
                },
                UI.Panel { width = "100%", flexDirection = "row", gap = 8, children = {
                    UI.Button {
                        text = "清空选择", fontSize = 12, height = 34, flex = 1,
                        onClick = function()
                            fuseSelection_ = {}
                            BuildUI()
                        end,
                    },
                    UI.Button {
                        text = "✨ 开始融合", fontSize = 12, height = 34, flex = 1,
                        variant = "primary",
                        backgroundColor = #fuseSelection_ == 3 and { 140, 80, 200, 220 } or { 80, 80, 80, 150 },
                        onClick = function()
                            if #fuseSelection_ ~= 3 then
                                AddLog("⚠️ 请选择恰好3件物品")
                                return
                            end
                            local newInst, newDef, err = Market.Fuse(fuseSelection_[1], fuseSelection_[2], fuseSelection_[3])
                            fuseSelection_ = {}
                            if newInst then
                                AddLog("✨ 融合成功！得到: " .. newDef.icon .. " " .. newDef.name .. " (" .. tierName(newDef.tier) .. ")")
                                PlaySFX("coin")
                            else
                                AddLog("❌ " .. (err or "融合失败"))
                            end
                            BuildUI()
                        end,
                    },
                }},
            },
        }
        -- 插入到列表顶部（children索引在装备栏之后）
        table.insert(children, 2, fusePanel)
    end

    return UI.Panel { width = "100%", gap = 8, children = children }
end

-- ============================================================
-- 主入口（由 UIManage.lua SafeBuild 调用）
-- ============================================================

function BuildMarketUI()
    -- 子Tab
    local subTabs = {
        { key = "pull", label = "🎰 淘货" },
        { key = "bag",  label = "🎒 背包" },
    }
    local tabBtns = {}
    for _, st in ipairs(subTabs) do
        local isActive = (marketSubTab_ == st.key)
        table.insert(tabBtns, UI.Button {
            text = st.label, fontSize = 14, height = 38, flex = 1,
            fontWeight = isActive and "bold" or "normal",
            backgroundColor = isActive and { 26, 18, 10, 255 } or { 40, 32, 22, 200 },
            fontColor = isActive and { 245, 215, 128, 255 } or C.textDim,
            borderRadius = PX.cardRadius, borderWidth = PX.border,
            borderColor = isActive and { 190, 148, 50, 240 } or { 60, 50, 38, 200 },
            onClick = function()
                marketSubTab_ = st.key
                pullResults_ = nil
                BuildUI()
            end,
        })
    end

    local content = nil
    local function safeView(name, fn)
        local ok, result = pcall(fn)
        if ok then return result end
        print("[UIMarket] " .. name .. " error: " .. tostring(result))
        return UI.Label { text = name .. " 加载失败", fontSize = 12, fontColor = C.textDim }
    end
    if marketSubTab_ == "pull" then
        content = safeView("PullView", BuildPullView)
    else
        content = safeView("BagView", BuildBagView)
    end

    return UI.Panel {
        width = "100%", gap = 10,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", gap = 8,
                children = tabBtns,
            },
            content,
        },
    }
end
