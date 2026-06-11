---@diagnostic disable: undefined-global
local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")

-- ============================================================================
-- 自动化管理 & 转生系统面板
-- ============================================================================
showPrestigeConfirm_ = false  -- 转生确认弹窗开关

function BuildAutomationPanel()
    local autoLv = playerData_.automationLevel or 0
    local autoData = IdleEngine.AUTOMATION_TREE[autoLv]
    local honor = playerData_.prestigeHonor or 0
    local prestigeCount = playerData_.prestigeCount or 0
    local prestigeMulti = PrestigeSystem.CalcPrestigeMultiplier()

    local children = {}

    -- ── 区域 1：当前自动化状态 ──
    local effectItems = {}
    if autoData and autoData.effects then
        for _, eff in ipairs(autoData.effects) do
            table.insert(effectItems, UI.Label {
                text = "  • " .. eff, fontSize = 12, fontColor = C.green, whiteSpace = "normal", width = "100%",
            })
        end
    end
    if #effectItems == 0 then
        table.insert(effectItems, UI.Label {
            text = "  暂无自动化效果，所有操作需手动完成", fontSize = 12, fontColor = C.textDim, whiteSpace = "normal", width = "100%",
        })
    end

    -- 每小时离线收益预估
    local dailyIncome = 0
    local okInc, resInc = pcall(CalcDailyIncome)
    if okInc and type(resInc) == "number" then dailyIncome = resInc end
    local dailyExpense = 0
    local okExp, resExp = pcall(CalcDailyExpenses)
    if okExp and type(resExp) == "table" then
        for _, item in ipairs(resExp) do dailyExpense = dailyExpense + (item.amount or item[2] or 0) end
    end
    local perHour = IdleEngine.CalcHourlyOffline(dailyIncome, dailyExpense, autoLv, prestigeMulti)

    table.insert(children, UI.Panel {
        width = "100%", padding = 12, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                UI.Label { text = autoData and autoData.icon or "🤖", fontSize = 28 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "自动化等级 Lv" .. autoLv, fontSize = 16, fontWeight = "bold", fontColor = C.text },
                    UI.Label { text = autoData and autoData.name or "未知", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label { text = "$" .. FormatMoney(perHour) .. "/h", fontSize = 18, fontColor = C.moneyGreen, fontWeight = "bold" },
                    UI.Label { text = "离线收益", fontSize = 11, fontColor = C.textDim },
                }},
            }},
            UI.Panel { width = "100%", height = 1, backgroundColor = C.border, marginVertical = 4 },
            UI.Label { text = "当前效果：", fontSize = 13, fontColor = C.textLight, fontWeight = "bold" },
            table.unpack(effectItems),
        },
    })

    -- ── 区域 2：自动化升级树 ──
    table.insert(children, PanelHeader("升级路线", { icon = nil, compact = true, color = C.gold }))

    for lvl = 1, 4 do
        local lvData = IdleEngine.AUTOMATION_TREE[lvl]
        if not lvData then goto continue_lv end
        local isUnlocked = autoLv >= lvl
        local isCurrent = autoLv == lvl
        local isNext = autoLv == lvl - 1
        local canUnlock, reason = false, ""
        if isNext then canUnlock, reason = IdleEngine.CanUnlockAutomation(lvl) end

        local cardBg = isUnlocked and C.upgrade_max or (isCurrent and C.upgrade_active or C.card)
        local borderCol = isCurrent and C.gold or (isUnlocked and C.green or C.border)

        local statusLabel
        if isUnlocked then
            statusLabel = UI.Label { text = "✅ 已解锁", fontSize = 12, fontColor = C.green, fontWeight = "bold" }
        elseif isNext and canUnlock then
            statusLabel = UI.Button {
                text = "解锁 $" .. FormatMoney(lvData.unlockCost), fontSize = 13, fontWeight = "bold",
                height = 32, paddingHorizontal = 12,
                backgroundColor = { 26, 18, 10, 255 }, fontColor = { 245, 215, 128, 255 },
                borderRadius = PX.radius, borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                onClick = function()
                    local ok = IdleEngine.UnlockAutomation(lvl)
                    if ok then
                        SaveGame()
                        BuildUI()
                    end
                end,
            }
        elseif isNext then
            statusLabel = UI.Label { text = "🔒 " .. reason, fontSize = 11, fontColor = C.red, whiteSpace = "normal", width = "100%" }
        else
            statusLabel = UI.Label { text = "🔒 需要先解锁Lv" .. (lvl - 1), fontSize = 11, fontColor = C.textDim }
        end

        table.insert(children, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = cardBg, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = borderCol,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                    UI.Label { text = lvData.icon, fontSize = 22 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Label { text = "Lv" .. lvl .. " " .. lvData.name, fontSize = 14, fontWeight = "bold", fontColor = C.text },
                        UI.Label { text = lvData.desc, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal", width = "100%" },
                    }},
                }},
                -- 效果列表
                UI.Panel { width = "100%", paddingLeft = 28, gap = 2, children = (function()
                    local effs = {}
                    for _, e in ipairs(lvData.effects or {}) do
                        table.insert(effs, UI.Label { text = "• " .. e, fontSize = 11, fontColor = isUnlocked and C.green or C.textLight })
                    end
                    return effs
                end)() },
                -- 条件/按钮
                UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center", marginTop = 4, children = {
                    lvData.unlockReq and UI.Label { text = lvData.unlockReq, fontSize = 10, fontColor = C.textDim, flex = 1, whiteSpace = "normal" } or nil,
                    statusLabel,
                }},
            },
        })
        ::continue_lv::
    end

    -- ── 区域 3：转生系统 ──
    table.insert(children, UI.Panel { width = "100%", height = 12 })
    table.insert(children, PanelHeader("转生 · 连锁扩张", { icon = nil, compact = true, color = C.gold }))

    local canPrestige, prestigeReason, prestigeGain = PrestigeSystem.CanPrestige()
    if not canPrestige then prestigeGain = PrestigeSystem.CalcPrestigeGain() end

    local currentCity = PrestigeSystem.GetCurrentCity()
    local cityName = currentCity and currentCity.name or "瓦坎达维尔"
    local cityEmoji = currentCity and currentCity.emoji or "🏘️"

    table.insert(children, UI.Panel {
        width = "100%", padding = 12, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.gold,
        children = {
            -- 当前状态
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, width = "100%", children = {
                UI.Label { text = cityEmoji, fontSize = 28 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "当前城市：" .. cityName, fontSize = 15, fontWeight = "bold", fontColor = C.text },
                    UI.Label { text = "转生次数：" .. prestigeCount .. " | 商会名誉：" .. honor, fontSize = 12, fontColor = C.gold },
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label { text = string.format("%.1fx", prestigeMulti), fontSize = 20, fontColor = C.moneyGreen, fontWeight = "bold" },
                    UI.Label { text = "永久加成", fontSize = 10, fontColor = C.textDim },
                }},
            }},
            UI.Panel { width = "100%", height = 1, backgroundColor = C.border, marginVertical = 2 },
            -- 转生预览
            UI.Label { text = "💫 转生可获得 +" .. prestigeGain .. " 商会名誉", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
            UI.Label {
                text = "转生将重置经营进度（金钱/设备/声望），但保留：自动化等级、商会名誉、已解锁城市、50%哈弗币",
                fontSize = 11, fontColor = C.textDim, whiteSpace = "normal", width = "100%",
            },
            -- 转生按钮
            canPrestige and UI.Button {
                text = "🌟 转生 · 开启新城市", fontSize = 15, fontWeight = "bold",
                width = "100%", height = 44,
                backgroundColor = { 180, 140, 30, 255 }, fontColor = { 40, 20, 0, 255 },
                borderRadius = PX.radius, borderWidth = PX.border, borderColor = C.gold,
                onClick = function()
                    PlaySFX("click")
                    showPrestigeConfirm_ = true
                    BuildUI()
                end,
            } or UI.Label {
                text = "🔒 " .. prestigeReason,
                fontSize = 12, fontColor = C.red, whiteSpace = "normal", width = "100%", textAlign = "center", marginTop = 4,
            },
        },
    })

    -- ── 区域 4：城市地图 ──
    table.insert(children, UI.Panel { width = "100%", height = 8 })
    table.insert(children, PanelHeader("非洲城市地图", { icon = nil, compact = true, color = C.textLight }))

    local unlockedSet = {}
    for _, uid in ipairs(playerData_.unlockedCities or { "wakandaville" }) do unlockedSet[uid] = true end

    for _, city in ipairs(PrestigeSystem.CITIES) do
        local isHere = (playerData_.currentCity or "wakandaville") == city.id
        local isOpen = unlockedSet[city.id]
        local canOpen = honor >= city.prestigeReq
        local cityBorder = isHere and C.gold or (isOpen and C.green or C.border)
        local cityBg = isHere and C.upgrade_active or (isOpen and { 45, 75, 48, 200 } or C.card)

        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", padding = 8, gap = 8, alignItems = "center",
            backgroundColor = cityBg, borderRadius = PX.radius,
            borderWidth = isHere and 2 or PX.borderSm, borderColor = cityBorder,
            children = {
                UI.Label { text = city.emoji, fontSize = 24 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = city.name, fontSize = 14, fontWeight = "bold", fontColor = isOpen and C.text or C.textDim },
                        isHere and UI.Label { text = "📍当前", fontSize = 10, fontColor = C.gold, fontWeight = "bold" } or nil,
                    }},
                    UI.Label { text = city.difficultyTag or "", fontSize = 10, fontColor = C.textLight },
                    city.specialBonus and UI.Label {
                        text = "✨ " .. city.specialBonus, fontSize = 11,
                        fontColor = isOpen and C.green or C.textDim,
                    } or nil,
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label {
                        text = isOpen and (string.format("%.1fx", city.incomeMulti)) or ("🔒 " .. city.prestigeReq),
                        fontSize = isOpen and 16 or 12,
                        fontColor = isOpen and C.moneyGreen or (canOpen and C.gold or C.textDim),
                        fontWeight = isOpen and "bold" or "normal",
                    },
                    UI.Label { text = isOpen and "收入倍率" or "所需名誉", fontSize = 9, fontColor = C.textDim },
                }},
            },
        })
    end

    return UI.Panel {
        width = "100%", gap = 8,
        children = children,
    }
end

--- 转生确认弹窗
function BuildPrestigeConfirmPopup()
    local gain, breakdown = PrestigeSystem.CalcPrestigeGain()
    local currentHonor = playerData_.prestigeHonor or 0
    local newHonor = currentHonor + gain
    local newMulti = 1.0 + math.min(2.0, newHonor / 100 * 0.1)

    -- 找到下一个未解锁城市
    local unlockedSet = {}
    for _, uid in ipairs(playerData_.unlockedCities or { "wakandaville" }) do unlockedSet[uid] = true end
    local nextCity = nil
    for _, city in ipairs(PrestigeSystem.CITIES) do
        if not unlockedSet[city.id] then nextCity = city; break end
    end

    local detailRows = {}
    local function addRow(label, value)
        table.insert(detailRows, UI.Panel {
            flexDirection = "row", justifyContent = "space-between", width = "100%", children = {
                UI.Label { text = label, fontSize = 12, fontColor = C.textDim },
                UI.Label { text = value, fontSize = 12, fontColor = C.gold, fontWeight = "bold" },
            },
        })
    end
    if breakdown then
        if (breakdown.earnings or 0) > 0 then addRow("累计收入贡献", "+" .. breakdown.earnings) end
        if (breakdown.branches or 0) > 0 then addRow("分店贡献", "+" .. breakdown.branches) end
        if (breakdown.tournaments or 0) > 0 then addRow("锦标赛贡献", "+" .. breakdown.tournaments) end
        if (breakdown.days or 0) > 0 then addRow("经营天数贡献", "+" .. breakdown.days) end
        if (breakdown.reputation or 0) > 0 then addRow("声望贡献", "+" .. breakdown.reputation) end
        if (breakdown.chainBonus or 0) > 0 then addRow("连锁转生加成", "+" .. breakdown.chainBonus .. "%") end
    end

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 20,
        onClick = function()
            showPrestigeConfirm_ = false
            PlaySFX("click")
            BuildUI()
        end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 360,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = 2, borderColor = C.gold,
                padding = 16, gap = 8,
                onClick = function() end, -- 阻止穿透
                children = {
                    UI.Label { text = "🌟 确认转生", fontSize = 18, fontWeight = "bold", fontColor = C.gold, textAlign = "center", width = "100%" },
                    UI.Panel { width = "100%", height = 1, backgroundColor = C.border },
                    -- 名誉获取
                    UI.Panel { flexDirection = "row", justifyContent = "center", alignItems = "center", gap = 8, width = "100%", children = {
                        UI.Label { text = "商会名誉", fontSize = 13, fontColor = C.textDim },
                        UI.Label { text = tostring(currentHonor), fontSize = 16, fontColor = C.textLight },
                        UI.Label { text = "→", fontSize = 16, fontColor = C.gold },
                        UI.Label { text = tostring(newHonor), fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                        UI.Label { text = "(+" .. gain .. ")", fontSize = 13, fontColor = C.green },
                    }},
                    -- 倍率变化
                    UI.Label {
                        text = "收入加成：" .. string.format("%.1fx → %.1fx", PrestigeSystem.CalcPrestigeMultiplier(), newMulti),
                        fontSize = 13, fontColor = C.moneyGreen, textAlign = "center", width = "100%",
                    },
                    -- 下一城市
                    nextCity and UI.Panel {
                        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = PX.radius, gap = 4, children = {
                            UI.Label { text = "🏙️ 前往新城市", fontSize = 13, fontColor = C.textLight, textAlign = "center", width = "100%" },
                            UI.Label {
                                text = nextCity.emoji .. " " .. nextCity.name .. " — " .. nextCity.difficultyTag,
                                fontSize = 14, fontColor = C.text, fontWeight = "bold", textAlign = "center", width = "100%",
                            },
                            nextCity.specialBonus and UI.Label {
                                text = "✨ " .. nextCity.specialBonus, fontSize = 12, fontColor = C.green, textAlign = "center", width = "100%",
                            } or nil,
                        },
                    } or nil,
                    -- 明细
                    #detailRows > 0 and UI.Panel {
                        width = "100%", padding = 8, backgroundColor = { C.bg[1], C.bg[2], C.bg[3], 180 },
                        borderRadius = PX.radius, gap = 3,
                        children = detailRows,
                    } or nil,
                    -- 警告
                    UI.Label {
                        text = "⚠️ 将重置：金钱、设备、声望、团队、分店\n保留：自动化等级、商会名誉、已解锁城市、50%哈弗币",
                        fontSize = 11, fontColor = C.red, whiteSpace = "normal", width = "100%", textAlign = "center",
                    },
                    UI.Panel { width = "100%", height = 4 },
                    -- 按钮
                    UI.Panel { flexDirection = "row", gap = 10, width = "100%", justifyContent = "center", children = {
                        UI.Button {
                            text = "取消", fontSize = 14, height = 38, paddingHorizontal = 24,
                            backgroundColor = C.cardAlt, fontColor = C.textLight, borderRadius = PX.radius,
                            borderWidth = PX.borderSm, borderColor = C.border,
                            onClick = function()
                                showPrestigeConfirm_ = false
                                PlaySFX("click")
                                BuildUI()
                            end,
                        },
                        UI.Button {
                            text = "🌟 确认转生", fontSize = 14, fontWeight = "bold", height = 38, paddingHorizontal = 24,
                            backgroundColor = { 180, 140, 30, 255 }, fontColor = { 40, 20, 0, 255 },
                            borderRadius = PX.radius, borderWidth = PX.border, borderColor = C.gold,
                            onClick = function()
                                showPrestigeConfirm_ = false
                                local ok, msg = PrestigeSystem.DoPrestige()
                                if ok then
                                    SaveGame()
                                    PlaySFX("victory")
                                    if TriggerCelebration then TriggerCelebration() end
                                else
                                    AddLog("❌ 转生失败：" .. (msg or "未知原因"))
                                end
                                BuildUI()
                            end,
                        },
                    }},
                },
            },
        },
    }
end

