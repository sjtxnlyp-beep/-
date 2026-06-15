---@diagnostic disable: undefined-global
-- ============================================================================
-- 网吧实时经营 UI — UICafe.lua
-- 展示每日网吧事件卡片流，支持选择决策和自动解决
-- 嵌入 BuildActionCard 的行动按钮区域（内联面板模式）
-- ============================================================================

--- 构建网吧实况内联面板（嵌入 BuildActionCard 中展开显示）
function BuildCafeInlinePanel()
    -- 确保当天事件已生成
    GenerateDailyCafeEvents()

    local children = {}

    -- ── 顶部标题栏 + 收起按钮 ──
    local dayLabel = "第 " .. (playerData_.day or 1) .. " 天"
    local totalCount = cafeEvents_ and #cafeEvents_ or 0
    local pendingCount = pendingCafeCount_ or 0

    table.insert(children, UI.Panel {
        width = "100%", flexDirection = "row", alignItems = "center",
        justifyContent = "space-between", paddingBottom = 4,
        children = {
            UI.Panel {
                flex = 1, flexShrink = 1,
                flexDirection = "row", alignItems = "center", gap = 6, flexWrap = "wrap",
                children = {
                    UI.Label { text = "网吧实况", fontSize = 16, fontColor = C.accent, fontWeight = "bold" },
                    UI.Label { text = dayLabel, fontSize = 11, fontColor = C.textDim },
                    pendingCount > 0 and UI.Panel {
                        backgroundColor = { 255, 80, 80, 220 },
                        borderRadius = 10, paddingHorizontal = 7, paddingVertical = 2,
                        children = {
                            UI.Label {
                                text = "待处理 " .. pendingCount,
                                fontSize = 10, fontColor = { 255, 255, 255, 255 }, fontWeight = "bold",
                            },
                        },
                    } or nil,
                },
            },
            UI.Button {
                text = "← 收起", fontSize = 12, height = 28,
                paddingHorizontal = 10, borderRadius = 6,
                variant = "secondary", flexShrink = 0,
                onClick = function()
                    cafePopupOpen_ = false
                    cafeViewOpen_ = false
                    PlaySFX("click")
                    BuildUI()
                end,
            },
        },
    })

    -- ── 分隔线 ──
    table.insert(children, UI.Panel {
        width = "100%", height = 1, backgroundColor = { C.border[1], C.border[2], C.border[3], 80 },
    })

    -- ── 事件卡片列表 ──
    if not cafeEvents_ or #cafeEvents_ == 0 then
        table.insert(children, UI.Panel {
            width = "100%", padding = 16, alignItems = "center", gap = 6,
            children = {
                UI.Label { text = "☕", fontSize = 28 },
                UI.Label { text = "今天网吧一切平静", fontSize = 14, fontColor = C.textDim },
                UI.Label { text = "明天可能会有新的故事发生", fontSize = 11, fontColor = C.textLight },
            },
        })
    else
        for eventIdx, ce in ipairs(cafeEvents_) do
            local card = BuildCafeEventCard(eventIdx, ce)
            if card then
                table.insert(children, card)
            end
        end
    end

    -- ── 底部提示 ──
    table.insert(children, UI.Label {
        text = "每天发生 3~5 件事件，决策影响收入与声望",
        fontSize = 10, fontColor = { C.textDim[1], C.textDim[2], C.textDim[3], 130 },
        textAlign = "center", width = "100%",
    })

    return UI.Panel {
        width = "100%", padding = 10, gap = 8,
        backgroundColor = C.cardAlt, borderRadius = 12,
        borderWidth = 1, borderColor = C.border,
        children = children,
    }
end

-- ============================================================================
-- 单张事件卡片
-- ============================================================================
function BuildCafeEventCard(eventIdx, ce)
    if not ce or not ce.def then return nil end

    local evt = ce.def
    local cat = evt.category or "customer"
    local rarity = evt.rarity or "common"

    -- 颜色查表
    local catColor = CAFE_CAT_COLORS[cat] or { 180, 180, 180, 255 }
    local catIcon = CAFE_CAT_ICONS[cat] or "📌"
    local catName = CAFE_CAT_NAMES[cat] or "未知"
    local rarityBorder = CAFE_RARITY_BORDER[rarity] or { 60, 50, 100, 120 }
    local rarityBg = CAFE_RARITY_BG[rarity] or { 24, 22, 48, 230 }
    local rarityLabel = CAFE_RARITY_LABEL[rarity] or ""

    -- 是否高级（rare/epic）—— 添加发光效果
    local isHighRarity = (rarity == "rare" or rarity == "epic")
    local borderW = isHighRarity and 2 or 1

    -- 卡片子元素
    local cardChildren = {}

    -- 第一行：类别标签 + 稀有度 + 状态（用 wrap 防溢出）
    local tagChildren = {
        UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 3,
            backgroundColor = { catColor[1], catColor[2], catColor[3], 40 },
            borderRadius = 6, paddingHorizontal = 7, paddingVertical = 2,
            flexShrink = 0,
            children = {
                UI.Label { text = catIcon, fontSize = 11 },
                UI.Label { text = catName, fontSize = 10, fontColor = catColor },
            },
        },
    }
    if rarityLabel ~= "" then
        table.insert(tagChildren, UI.Label {
            text = rarityLabel .. " " .. rarity:sub(1, 1):upper() .. rarity:sub(2),
            fontSize = 10, flexShrink = 1,
            fontColor = isHighRarity and C.gold or C.textLight,
        })
    end
    if ce.resolved then
        table.insert(tagChildren, UI.Label {
            text = "✓ 已处理", fontSize = 10, fontColor = C.green, flexShrink = 0,
        })
    end

    table.insert(cardChildren, UI.Panel {
        width = "100%", flexDirection = "row", alignItems = "center",
        justifyContent = "space-between", flexWrap = "wrap", gap = 4,
        children = tagChildren,
    })

    -- 标题
    table.insert(cardChildren, UI.Label {
        text = evt.title or "未知事件",
        fontSize = 14, fontWeight = "bold",
        fontColor = isHighRarity and C.gold or C.text,
        whiteSpace = "normal", width = "100%", flexShrink = 1,
    })

    -- 描述
    table.insert(cardChildren, UI.Label {
        text = evt.desc or "",
        fontSize = 12, fontColor = C.textDim,
        whiteSpace = "normal", lineHeight = 1.4, width = "100%", flexShrink = 1,
    })

    -- ── 结果区域（已解决的事件显示结果） ──
    if ce.resolved and ce.result then
        table.insert(cardChildren, UI.Divider { spacing = 4 })
        table.insert(cardChildren, UI.Panel {
            width = "100%", backgroundColor = { C.green[1], C.green[2], C.green[3], 25 },
            borderRadius = 8, padding = 8,
            children = {
                UI.Label {
                    text = "" .. ce.result,
                    fontSize = 12, fontColor = { C.green[1], C.green[2], C.green[3], 230 },
                    whiteSpace = "normal", lineHeight = 1.4, width = "100%", flexShrink = 1,
                },
            },
        })
    end

    -- ── 选择按钮区域（未解决的 choice 事件） ──
    if not ce.resolved and evt.type == "choice" and evt.choices then
        -- 行动点判断：有AP，或今天已花过1AP（后续免费）
        local day = playerData_.day or 1
        local hasAP = (playerData_.actionPoints or 0) > 0 or cafeActionUsedDay_ == day
        table.insert(cardChildren, UI.Divider { spacing = 4 })

        if hasAP then
            table.insert(cardChildren, UI.Label {
                text = "🤔 你的决定：", fontSize = 12, fontColor = C.accent, paddingBottom = 2,
            })
        else
            table.insert(cardChildren, UI.Label {
                text = "⚡ 需要1行动点处理今日事件", fontSize = 12,
                fontColor = C.red, paddingBottom = 2,
            })
        end

        for choiceIdx, choice in ipairs(evt.choices) do
            local eIdx = eventIdx
            local cIdx = choiceIdx

            -- 选项文本拼接，避免嵌套 children 导致高度计算问题
            local choiceText = choice.text or ("选项 " .. choiceIdx)
            if choice.desc then
                choiceText = choiceText .. "\n" .. choice.desc
            end
            -- P1-2: 追加后果提示（hint）到选项文本下方
            if choice.hint then
                choiceText = choiceText .. "\n" .. "⤷ " .. choice.hint
            end

            table.insert(cardChildren, UI.Button {
                text = choiceText,
                width = "100%", fontSize = 12, borderRadius = 8,
                paddingVertical = 10, paddingHorizontal = 12,
                backgroundColor = hasAP and { 62, 52, 40, 255 } or { C.border[1], C.border[2], C.border[3], 100 },
                borderWidth = 1,
                borderColor = hasAP and { catColor[1], catColor[2], catColor[3], 140 } or { C.border[1], C.border[2], C.border[3], 80 },
                fontColor = hasAP and C.text or C.textLight,
                marginBottom = 2,
                whiteSpace = "normal",
                textAlign = "left",
                onClick = hasAP and function()
                    ResolveCafeEvent(eIdx, cIdx)
                end or nil,
            })
        end
    end

    -- 组装卡片
    local boxShadowVal = nil
    if isHighRarity then
        local glowColor = rarity == "epic"
            and { 255, 180, 50, 50 }
            or { C.gold[1], C.gold[2], C.gold[3], 35 }
        boxShadowVal = { { x = 0, y = 0, blur = 14, color = glowColor } }
    end

    return UI.Panel {
        width = "100%", padding = 12, gap = 6,
        backgroundColor = rarityBg,
        borderRadius = 12,
        borderWidth = borderW,
        borderColor = rarityBorder,
        boxShadow = boxShadowVal,
        children = cardChildren,
    }
end
