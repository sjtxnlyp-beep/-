---@diagnostic disable: undefined-global
-- ============================================================================
-- 13.5 群聊界面（代练工作室群）
-- ============================================================================
function BuildGroupChatUI()
    -- 计算显示起始索引：从上次阅读位置开始（保留2条上文），有新消息时插入分隔线
    local totalMsgs = #chatMessages_
    local displayStart = 1
    local hasOlderMsgs = false
    local newMsgDividerIdx = 0  -- 在这个索引前插入"新消息"分隔线

    if chatLastReadIdx_ > 0 and chatLastReadIdx_ < totalMsgs then
        -- 有未读消息：从上次已读位置前2条开始，显示上文
        displayStart = math.max(1, chatLastReadIdx_ - 1)
        hasOlderMsgs = displayStart > 1
        newMsgDividerIdx = chatLastReadIdx_ + 1  -- 分隔线位置
    elseif chatLastReadIdx_ >= totalMsgs then
        -- 没有新消息：显示最近的消息（最多30条）
        displayStart = math.max(1, totalMsgs - 29)
        hasOlderMsgs = displayStart > 1
    end
    -- else: chatLastReadIdx_ == 0（首次/重置），显示全部

    -- 构建历史消息列表
    local msgWidgets = {}

    -- "查看更早消息"按钮
    if hasOlderMsgs then
        table.insert(msgWidgets, UI.Panel {
            width = "100%", alignItems = "center", paddingTop = 6, paddingBottom = 6,
            children = {
                UI.Button {
                    text = "↑ 查看更早的 " .. (displayStart - 1) .. " 条消息",
                    fontSize = 11, height = 28,
                    backgroundColor = { C.border[1], C.border[2], C.border[3], 100 },
                    fontColor = C.textLight,
                    borderRadius = 14,
                    paddingLeft = 16, paddingRight = 16,
                    onClick = function()
                        -- 展开全部消息
                        chatLastReadIdx_ = 0
                        BuildUI()
                    end,
                },
            },
        })
    end

    for i = displayStart, totalMsgs do
        local msg = chatMessages_[i]

        -- 在新消息位置插入分隔线
        if i == newMsgDividerIdx then
            table.insert(msgWidgets, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                paddingLeft = 16, paddingRight = 16, paddingTop = 6, paddingBottom = 6,
                gap = 8,
                children = {
                    UI.Panel { flex = 1, height = 1, backgroundColor = { 255, 100, 100, 120 } },
                    UI.Label { text = "以下是新消息", fontSize = 10, fontColor = { 255, 120, 120, 200 } },
                    UI.Panel { flex = 1, height = 1, backgroundColor = { 255, 100, 100, 120 } },
                },
            })
        end

        if msg.isSystem then
            -- 系统消息：居中灰色
            table.insert(msgWidgets, UI.Panel {
                width = "100%", alignItems = "center", paddingTop = 4, paddingBottom = 4,
                children = {
                    UI.Label {
                        text = msg.content, fontSize = 11,
                        fontColor = C.textLight,
                    },
                },
            })
        else
            -- 聊天气泡（用列布局 + alignItems 控制左右对齐）
            local isSelf = msg.isSelf
            local bubbleColor = isSelf and C.bubble_self or C.bubble_other
            local nameColor = isSelf and C.blue or C.accent
            table.insert(msgWidgets, UI.Panel {
                width = "100%",
                alignItems = isSelf and "flex-end" or "flex-start",
                paddingLeft = 8, paddingRight = 8,
                paddingTop = 3, paddingBottom = 3,
                children = {
                    UI.Panel {
                        backgroundColor = bubbleColor,
                        borderRadius = 10,
                        paddingLeft = 10, paddingRight = 10,
                        paddingTop = 6, paddingBottom = 6,
                        maxWidth = "85%",
                        flexShrink = 1,
                        children = {
                            UI.Label {
                                text = msg.sender, fontSize = 11,
                                fontColor = nameColor,
                            },
                            UI.Label {
                                text = msg.content, fontSize = 13,
                                fontColor = C.text,
                                marginTop = 2,
                            },
                        },
                    },
                },
            })
        end
    end

    -- 决策选项区域（⚖️ 仲裁台）
    local decisionPanel = nil
    if pendingChatDecision_ then
        local optBtns = {}
        for idx, opt in ipairs(pendingChatDecision_.options) do
            table.insert(optBtns, UI.Button {
                text = opt.text, fontSize = 13,
                height = 40, width = "100%",
                backgroundColor = C.cardAlt,
                fontColor = C.accent,
                borderRadius = 8,
                borderWidth = 1,
                borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
                onClick = function()
                    HandleChatDecision(idx)
                end,
            })
        end

        -- 冲突双方展示
        local partiesBar = nil
        local parties = pendingChatDecision_.conflictParties
        if parties and #parties >= 2 then
            partiesBar = UI.Panel {
                width = "100%", flexDirection = "row",
                alignItems = "center", justifyContent = "center",
                gap = 10, paddingTop = 4, paddingBottom = 6,
                children = {
                    -- 当事人A
                    UI.Panel {
                        backgroundColor = { 180, 60, 60, 180 },
                        borderRadius = 6,
                        paddingLeft = 10, paddingRight = 10,
                        paddingTop = 4, paddingBottom = 4,
                        children = {
                            UI.Label {
                                text = "🔴 " .. parties[1],
                                fontSize = 12, fontColor = { 255, 220, 220, 255 },
                            },
                        },
                    },
                    -- VS
                    UI.Label {
                        text = "⚔️", fontSize = 16,
                    },
                    -- 当事人B
                    UI.Panel {
                        backgroundColor = { 50, 80, 160, 180 },
                        borderRadius = 6,
                        paddingLeft = 10, paddingRight = 10,
                        paddingTop = 4, paddingBottom = 4,
                        children = {
                            UI.Label {
                                text = "🔵 " .. parties[2],
                                fontSize = 12, fontColor = { 200, 220, 255, 255 },
                            },
                        },
                    },
                },
            }
        end

        -- 仲裁台主面板
        local panelChildren = {
            -- 仲裁台标题栏
            UI.Panel {
                width = "100%", flexDirection = "row",
                alignItems = "center", justifyContent = "center",
                gap = 6, paddingBottom = 4,
                borderColor = { C.border[1], C.border[2], C.border[3], 160 },
                children = {
                    UI.Label { text = "⚖️ 仲裁台", fontSize = 15, fontColor = C.gold, fontWeight = "bold" },
                },
            },
        }
        -- 冲突双方
        if partiesBar then
            table.insert(panelChildren, partiesBar)
        end
        -- 冲突描述
        table.insert(panelChildren, UI.Label {
            text = pendingChatDecision_.question,
            fontSize = 13, fontColor = C.text,
            whiteSpace = "normal", width = "100%",
            marginBottom = 6, marginTop = 2,
        })
        -- 分隔线
        table.insert(panelChildren, UI.Panel {
            width = "100%", height = 1,
            backgroundColor = { C.border[1], C.border[2], C.border[3], 120 },
            marginBottom = 4,
        })
        -- 选项提示
        table.insert(panelChildren, UI.Label {
            text = "请选择处理方式：", fontSize = 11,
            fontColor = C.textLight,
            marginBottom = 2,
        })
        -- 选项按钮
        for _, btn in ipairs(optBtns) do
            table.insert(panelChildren, btn)
        end

        decisionPanel = UI.Panel {
            width = "100%",
            backgroundColor = C.card,
            borderRadius = 12,
            padding = 12, gap = 5,
            marginTop = 6,
            borderWidth = 2,
            borderColor = { C.border[1], C.border[2], C.border[3], 180 },
            children = panelChildren,
        }
    end

    -- 输入栏构建函数（空状态和正常状态共用）
    local function BuildInputBar()
        local inputField = nil
        local function doSend()
            if not inputField then return end
            local txt = inputField:GetValue()
            if not txt or txt == "" then return end
            inputField:Clear()
            HandleBossChat(txt)
        end
        inputField = UI.TextField {
            flexGrow = 1, height = 36,
            placeholder = "说点什么...",
            fontSize = 13,
            backgroundColor = C.cardAlt,
            fontColor = C.text,
            borderRadius = 8,
            borderWidth = 1,
            borderColor = { C.border[1], C.border[2], C.border[3], 120 },
            onSubmit = function(field, text)
                if text and text ~= "" then
                    HandleBossChat(text)
                    field:Clear()
                end
            end,
        }
        return UI.Panel {
            width = "100%", height = 48,
            flexDirection = "row", alignItems = "center",
            gap = 6,
            paddingLeft = 8, paddingRight = 8,
            paddingTop = 4, paddingBottom = 4,
            backgroundColor = C.cardAlt,
            borderColor = { C.border[1], C.border[2], C.border[3], 120 },
            borderWidth = 1,
            children = {
                inputField,
                UI.Button {
                    text = "发送", fontSize = 13,
                    width = 56, height = 34,
                    backgroundColor = C.accent,
                    fontColor = { 255, 255, 255, 255 },
                    borderRadius = 8,
                    onClick = function() doSend() end,
                },
            },
        }
    end

    -- 空状态
    if #chatMessages_ == 0 then
        return UI.Panel {
            width = "100%", height = "100%",
            children = {
                UI.Panel {
                    width = "100%", flex = 1,
                    justifyContent = "center", alignItems = "center",
                    children = {
                        UI.Label { text = "代练工作室群", fontSize = 18, fontColor = C.accent },
                        UI.Label { text = "消息将在每天结算后出现", fontSize = 13, fontColor = C.textDim, marginTop = 8 },
                        UI.Label { text = "也可以直接在下方输入聊天", fontSize = 12, fontColor = C.textDim, marginTop = 4 },
                    },
                },
                BuildInputBar(),
            },
        }
    end

    -- 组装：标题 + 消息列表(ScrollView) + 决策区
    local chatContent = {}
    -- 把所有消息和 decisionPanel 放一起
    for _, w in ipairs(msgWidgets) do table.insert(chatContent, w) end
    if decisionPanel then table.insert(chatContent, decisionPanel) end

    return UI.Panel {
        width = "100%", flex = 1,
        children = {
            -- 群名栏
            UI.Panel {
                width = "100%", height = 34,
                backgroundColor = C.cardAlt,
                justifyContent = "center", alignItems = "center",
                flexDirection = "row", gap = 6,
                children = {
                    UI.Label { text = "⚖️", fontSize = 14 },
                    UI.Label { text = "代练工作室群", fontSize = 14, fontColor = C.text },
                    UI.Label { text = "(" .. (#teamMembers_ + 1) .. "人)", fontSize = 12, fontColor = C.textDim },
                    pendingChatDecision_ and UI.Panel {
                        backgroundColor = { 220, 180, 80, 200 },
                        borderRadius = 4,
                        paddingLeft = 6, paddingRight = 6,
                        paddingTop = 1, paddingBottom = 1,
                        marginLeft = 4,
                        children = {
                            UI.Label { text = "待仲裁", fontSize = 9, fontColor = { 40, 30, 10, 255 } },
                        },
                    } or nil,
                },
            },
            -- 消息列表（有新消息时停在分隔线位置，无新消息时滚到底部看最新）
            UI.ScrollView {
                width = "100%", flex = 1,
                backgroundColor = { C.bg[1], C.bg[2], C.bg[3], 220 },
                padding = 4,
                scrollToEnd = (newMsgDividerIdx == 0),
                children = chatContent,
            },
            -- 底部输入栏
            BuildInputBar(),
        },
    }
end

