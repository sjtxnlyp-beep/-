---@diagnostic disable: undefined-global
-- ============================================================================
-- 10. UI 调度
-- ============================================================================
function BuildUI()
    if uiRoot_ then UI.SetRoot(nil, true) end

    -- Banner 广告：管理界面展示，其他界面隐藏
    if currentPhase_ == PHASE_MANAGE then
        AdManager.ShowBanner()
    else
        AdManager.HideBanner()
    end

    -- 每次构建 UI 前验证数据（防止任何阶段因 nil 字段崩溃）
    if currentPhase_ ~= PHASE_TITLE then
        pcall(ValidatePlayerData)
    end

    local ok, result = pcall(function()
        if currentPhase_ == PHASE_TITLE then return BuildTitleUI()
        elseif currentPhase_ == PHASE_COMIC then return BuildComicUI()
        elseif currentPhase_ == PHASE_DIALOGUE then return BuildDialogueUI()
        elseif currentPhase_ == PHASE_MANAGE then return BuildManageUI()
        elseif currentPhase_ == PHASE_TRAIN then return BuildTrainUI()
        elseif currentPhase_ == PHASE_EVENT then return BuildEventUI()
        elseif currentPhase_ == PHASE_MATCH then return BuildMatchUI()
        elseif currentPhase_ == PHASE_RESULT then return BuildResultUI()
        elseif currentPhase_ == PHASE_GAMEOVER then return BuildGameOverUI()
        end
    end)

    if ok and result then
        -- 收集所有弹窗覆盖层
        local overlays = {}
        -- 踢馆条件不满足弹窗
        local blockedPopup = BuildChallengeBlockedPopup and BuildChallengeBlockedPopup() or nil
        if blockedPopup then table.insert(overlays, blockedPopup) end
        -- 小游戏退出确认弹窗
        local exitPopup = BuildMiniGameExitPopup and BuildMiniGameExitPopup() or nil
        if exitPopup then table.insert(overlays, exitPopup) end

        -- 留存系统弹窗（离线收益 / 明日预告）
        local offlinePopup = BuildWelcomeBackPopup and BuildWelcomeBackPopup() or nil
        if offlinePopup then table.insert(overlays, offlinePopup) end
        local previewPopup = BuildTomorrowPreviewPopup and BuildTomorrowPreviewPopup() or nil
        if previewPopup then table.insert(overlays, previewPopup) end

        -- 用 SafeAreaView 包裹，自动适配手机刘海/状态栏/胶囊按钮
        -- paddingTop=36 保底间距，SafeAreaView 叠加系统安全区（刘海通常 44-60px）
        uiRoot_ = UI.SafeAreaView {
            edges = { "top" },
            paddingTop = 36,
            width = "100%", height = "100%",
            backgroundColor = { 35, 28, 22, 255 },
            children = { result, table.unpack(overlays) },
        }
    else
        local errMsg = ok and ("phase " .. tostring(currentPhase_) .. " returned nil") or tostring(result)
        print("[BuildUI] phase=" .. tostring(currentPhase_) .. " error: " .. errMsg)
        uiRoot_ = UI.SafeAreaView {
            edges = { "top" },
            paddingTop = 36,
            width = "100%", height = "100%",
            backgroundColor = C.bg,
            children = {
                UI.Panel {
                    width = "100%", height = "100%",
                    justifyContent = "center", alignItems = "center", gap = 12,
                    children = {
                        UI.Label { text = "⚠️ 界面渲染出错", fontSize = 20, fontColor = { 255, 100, 100, 255 } },
                        UI.Label { text = errMsg, fontSize = 13, fontColor = { 200, 200, 200, 255 },
                            whiteSpace = "normal", width = "80%", textAlign = "center" },
                        UI.Button { text = "返回管理", width = 160, height = 40, fontSize = 14, variant = "primary",
                            onClick = function()
                                currentPhase_ = PHASE_MANAGE
                                BuildUI()
                            end },
                    },
                },
            },
        }
    end

    UI.SetRoot(uiRoot_)
    lastBuildUITime_ = gameTime_
    lastBuildUIPhase_ = currentPhase_
end

-- ============================================================================
-- 11. 标题画面（带背景图）
-- ============================================================================
function BuildTitleUI()
    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.title,
        backgroundFit = "cover",
        justifyContent = "center", alignItems = "center",
        children = {
            -- 全屏暗色遮罩（加深，让文字清晰可读）
            UI.Panel {
                width = "100%", height = "100%", position = "absolute",
                backgroundColor = { 10, 8, 5, 180 },
            },
            -- 居中内容区（深色毛玻璃底板 + 暖金边框）
            UI.Panel {
                width = "88%", maxWidth = 380,
                padding = { 44, 28 }, gap = 14,
                alignItems = "center",
                backgroundColor = { 15, 12, 8, 160 },
                borderRadius = 20,
                borderWidth = 1.5,
                borderColor = { 200, 165, 80, 100 },
                boxShadow = { { x = 0, y = 6, blur = 30, color = { 0, 0, 0, 160 } } },
                children = {
                    UI.Label { text = "非洲网吧大亨", fontSize = 30, fontWeight = "bold",
                        fontColor = { 255, 255, 255, 255 },
                        textShadow = { offsetX = 0, offsetY = 3, blur = 16, color = { 0, 0, 0, 240 } } },
                    UI.Label { text = "CYBER CAFE TYCOON", fontSize = 12,
                        fontColor = { 255, 220, 160, 180 }, letterSpacing = 3,
                        textShadow = { offsetX = 0, offsetY = 1, blur = 6, color = { 0, 0, 0, 200 } } },
                    UI.Panel { height = 6 },
                    UI.Label {
                        text = "带着5000美元只身前往非洲\n在尘土飞扬的小城开一间网吧\n发掘天赋异禀的年轻人\n组建最强战队 征战三角洲巅峰",
                        fontSize = 14, fontColor = { 255, 248, 235, 230 }, textAlign = "center",
                        whiteSpace = "normal", lineHeight = 1.8,
                        textShadow = { offsetX = 0, offsetY = 1, blur = 8, color = { 0, 0, 0, 220 } },
                    },
                    UI.Panel { height = 16 },
                    UI.Button {
                        text = "开始冒险",
                        width = 240, height = 52, fontSize = 18, fontWeight = "bold", borderRadius = 14,
                        backgroundColor = C.accent,
                        fontColor = { 255, 255, 255, 255 },
                        boxShadow = { { x = 0, y = 4, blur = 20, color = { C.accent[1], C.accent[2], C.accent[3], 160 } } },
                        onClick = function()
                            PlaySFX("click")
                            comicPanelIdx_ = 1
                            currentPhase_ = PHASE_COMIC
                            PlayBGM("title")
                            BuildUI()
                        end,
                    },
                    HasSaveFile() and UI.Button {
                        text = "继续游戏",
                        width = 240, height = 44, fontSize = 15, borderRadius = 12,
                        backgroundColor = { 255, 255, 255, 30 },
                        fontColor = { 255, 248, 235, 240 },
                        borderWidth = 1, borderColor = { 255, 248, 235, 100 },
                        onClick = function()
                            PlaySFX("click")
                            if LoadGame() then
                                StartTransition("欢迎回来", "第" .. playerData_.day .. "天", function()
                                    PlayBGM("manage")
                                    currentPhase_ = PHASE_MANAGE; BuildUI()
                                end)
                            else
                                AddLog("存档数据损坏，无法加载")
                                BuildUI()
                            end
                        end,
                    } or UI.Panel { height = 0 },
                    HasSaveFile() and UI.Label { text = "有存档可继续",
                        fontSize = 12, fontColor = { 255, 248, 235, 120 },
                        textShadow = { offsetX = 0, offsetY = 1, blur = 4, color = { 0, 0, 0, 160 } } }
                    or nil,
                },
            },
        },
    }
end

-- ============================================================================
-- 11b. 漫画开场界面
-- ============================================================================
function BuildComicUI()
    local panel = COMIC_PANELS[comicPanelIdx_]
    if not panel then
        -- 安全兜底：直接进入游戏（不能递归调用 BuildUI，否则外层会覆盖导致黑屏）
        chaptersRead_[1] = true
        PlayBGM("manage")
        currentPhase_ = PHASE_MANAGE
        return BuildManageUI()
    end

    local total = #COMIC_PANELS
    local isLast = comicPanelIdx_ >= total

    -- 文字行组件
    local lineChildren = {}
    for _, line in ipairs(panel.lines) do
        table.insert(lineChildren, UI.Label {
            text = line, fontSize = 15, fontColor = { 255, 248, 235, 210 },
            textAlign = "center", whiteSpace = "normal", lineHeight = 1.6,
        })
    end

    -- 页码指示器（圆点）
    local dots = {}
    for i = 1, total do
        table.insert(dots, UI.Panel {
            width = i == comicPanelIdx_ and 24 or 8,
            height = 8,
            borderRadius = 4,
            backgroundColor = i == comicPanelIdx_ and C.accent or { 255, 248, 235, 60 },
        })
    end

    -- 前进到下一面板或结束
    local function advanceComic()
        PlaySFX("click")
        if isLast then
            -- 漫画结束 → 标记第一章已读 → 进入管理阶段
            chaptersRead_[1] = true
            StartTransition("第一章：非洲创业", "Dragon Net Cafe 正式开业", function()
                PlayBGM("manage")
                currentPhase_ = PHASE_MANAGE
                BuildUI()
            end)
        else
            comicPanelIdx_ = comicPanelIdx_ + 1
            BuildUI()
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = { 30, 22, 16, 255 },
        onClick = function() advanceComic() end,
        children = {
            -- 上方：漫画图片区域（占满剩余空间，完整显示）
            UI.Panel {
                width = "100%", flexGrow = 1, flexShrink = 1,
                backgroundImage = panel.image,
                backgroundFit = "contain",
            },
            -- 下方：文字信息区域（暗色底）
            UI.Panel {
                width = "100%",
                paddingTop = 14, paddingBottom = 16,
                paddingLeft = 24, paddingRight = 24,
                gap = 6,
                alignItems = "center",
                backgroundColor = { 25, 18, 12, 250 },
                borderTopWidth = 1, borderColor = { 255, 248, 235, 40 },
                children = {
                    -- 标题
                    UI.Label {
                        text = panel.title,
                        fontSize = 20, fontWeight = "bold",
                        fontColor = { 255, 220, 160, 255 },
                    },
                    -- 文字行
                    UI.Panel {
                        width = "90%", maxWidth = 360,
                        gap = 2, alignItems = "center",
                        children = lineChildren,
                    },
                    UI.Panel { height = 6 },
                    -- 页码指示器 + 提示
                    UI.Panel {
                        flexDirection = "row", gap = 6,
                        alignItems = "center", justifyContent = "center",
                        children = dots,
                    },
                    UI.Label {
                        text = isLast and "点击开始游戏 ▶" or "点击继续 ▶",
                        fontSize = 12, fontColor = { 255, 248, 235, 100 },
                    },
                },
            },
            -- 右上角跳过按钮
            UI.Panel {
                position = "absolute", top = 8, right = 8,
                children = {
                    UI.Button {
                        text = "跳过 ▶▶", variant = "ghost",
                        fontSize = 12, fontColor = { 255, 248, 235, 160 },
                        paddingLeft = 10, paddingRight = 10,
                        height = 28,
                        backgroundColor = { 0, 0, 0, 100 },
                        borderRadius = 14,
                        onClick = function()
                            PlaySFX("click")
                            chaptersRead_[1] = true
                            StartTransition("第一章：非洲创业", "Dragon Net Cafe 正式开业", function()
                                PlayBGM("manage")
                                currentPhase_ = PHASE_MANAGE
                                BuildUI()
                            end)
                        end,
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 12a. 精英入场对话界面
-- ============================================================================
function BuildEliteEntranceUI()
    local dlg = eliteEntranceDialogues_[eliteEntranceIdx_] or { speaker = "", text = "" }
    local total = #eliteEntranceDialogues_
    local opp = friendlyOpponent_ or { name = "???", emoji = "⚔️" }

    local colors = {
        ["旁白"]   = { fg = { 100, 100, 100, 220 }, bg = C.cardAlt },
        ["你"]     = { fg = C.blue,                  bg = { C.blue[1], C.blue[2], C.blue[3], 25 } },
    }
    local col = colors[dlg.speaker] or { fg = C.accent, bg = { C.accent[1], C.accent[2], C.accent[3], 25 } }

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.match or SCENE_IMAGES.ch3,
        backgroundFit = "cover",
        children = {
            -- 顶部：强敌标识
            UI.Panel {
                width = "100%", height = 48, justifyContent = "center", alignItems = "center",
                backgroundColor = { 200, 70, 50, 200 },
                borderWidth = { 0, 0, 2, 0 }, borderColor = { 220, 80, 60, 150 },
                children = { UI.Label { text = "强敌降临 — " .. opp.emoji .. " " .. opp.name, fontSize = 16, fontColor = { 255, 245, 235, 255 } } },
            },
            -- 中央留白
            UI.Panel { flex = 1, width = "100%" },
            -- 对话框（整个面板可点击）
            UI.Panel {
                width = "100%", padding = { 16, 16, 28, 16 }, gap = 10,
                backgroundColor = col.bg,
                borderRadius = { 16, 16, 0, 0 },
                minHeight = 150,
                borderWidth = { 2, 0, 0, 0 }, borderColor = { 220, 80, 60, 80 },
                boxShadow = { { x = 0, y = -6, blur = 25, color = { 150, 60, 40, 100 } } },
                onClick = function()
                    PlaySFX("click")
                    if eliteEntranceIdx_ < total then
                        eliteEntranceIdx_ = eliteEntranceIdx_ + 1
                        BuildUI()
                    else
                        dialogueOverride_ = nil
                        eliteEntranceDialogues_ = nil
                        eliteEntranceIdx_ = nil
                        currentPhase_ = PHASE_MATCH
                        BuildUI()
                    end
                end,
                children = {
                    UI.Panel {
                        flexDirection = "row", alignItems = "center",
                        children = {
                            UI.Label { text = "【" .. dlg.speaker .. "】", fontSize = 15, fontColor = col.fg },
                            UI.Panel { flex = 1 },
                            UI.Label { text = eliteEntranceIdx_ .. "/" .. total, fontSize = 14, fontColor = C.textDim },
                        },
                    },
                    UI.Label {
                        text = dlg.text, fontSize = 14, fontColor = C.text,
                        width = "100%", whiteSpace = "normal", lineHeight = 1.5,
                    },
                    UI.Panel {
                        flexDirection = "row", justifyContent = "flex-end", alignItems = "center", width = "100%", gap = 8,
                        children = {
                            UI.Label {
                                text = (eliteEntranceIdx_ < total) and "点击继续 ▶" or "点击开战 ⚔️",
                                fontSize = 14, fontColor = { 200, 100, 70, 180 },
                            },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 留存系统：离线收益弹窗（"欢迎回来"）
-- ============================================================================
function BuildWelcomeBackPopup()
    if not pendingOfflineReward_ then return nil end
    local reward = pendingOfflineReward_

    local btns = {}
    -- 看广告翻倍按钮
    if reward.canDouble then
        table.insert(btns, AdManager.AdButton {
            sceneId = "offline_double", day = playerData_.day,
            text = "📺 看广告翻倍 → $" .. (reward.earnings * 2),
            onReward = function()
                if Retention then Retention.ClaimOfflineEarnings(true) end
                pendingOfflineReward_ = nil
                BuildUI()
            end,
            width = "100%", height = 40, fontSize = 14,
        })
    end
    -- 直接领取按钮
    table.insert(btns, UI.Button {
        text = "💰 领取 $" .. reward.earnings,
        width = "100%", height = 40, fontSize = 14,
        variant = "primary",
        onClick = function()
            if Retention then Retention.ClaimOfflineEarnings(false) end
            pendingOfflineReward_ = nil
            BuildUI()
        end,
    })

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 160 },
        justifyContent = "center", alignItems = "center",
        children = {
            UI.Panel {
                width = "85%", maxWidth = 360, padding = 20, gap = 14,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = C.gold,
                alignItems = "center",
                boxShadow = { { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 80 } } },
                children = {
                    UI.Label { text = "🌙", fontSize = 48 },
                    UI.Label { text = "欢迎回来！", fontSize = 20, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label {
                        text = "你离开了 " .. reward.hours .. " 小时，网吧照常运营。",
                        fontSize = 14, fontColor = C.text, whiteSpace = "normal", textAlign = "center", width = "100%",
                    },
                    UI.Panel {
                        width = "100%", padding = 12, backgroundColor = { 60, 50, 40, 255 },
                        borderRadius = 8, alignItems = "center", gap = 4,
                        children = {
                            UI.Label { text = "💰 离线收益", fontSize = 13, fontColor = C.textSub },
                            UI.Label { text = "$" .. reward.earnings, fontSize = 28, fontColor = C.gold, fontWeight = "bold" },
                        },
                    },
                    table.unpack(btns),
                },
            },
        },
    }
end

-- ============================================================================
-- 留存系统：明日预告弹窗（EndDay 后展示）
-- ============================================================================
function BuildTomorrowPreviewPopup()
    if not pendingTomorrowPreview_ or #pendingTomorrowPreview_ == 0 then return nil end
    -- 仅在管理界面展示
    if currentPhase_ ~= PHASE_MANAGE then return nil end

    local previewItems = {}
    for i, text in ipairs(pendingTomorrowPreview_) do
        table.insert(previewItems, UI.Label {
            text = text, fontSize = 14, fontColor = C.text,
            whiteSpace = "normal", lineHeight = 1.5, width = "100%",
        })
        if i < #pendingTomorrowPreview_ then
            table.insert(previewItems, UI.Panel {
                width = "80%", height = 1, backgroundColor = { 80, 70, 60, 120 },
                alignSelf = "center",
            })
        end
    end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 140 },
        justifyContent = "center", alignItems = "center",
        onClick = function()
            pendingTomorrowPreview_ = nil; BuildUI()
        end,
        children = {
            UI.Panel {
                width = "85%", maxWidth = 360, padding = 20, gap = 12,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = { 100, 140, 200, 200 },
                alignItems = "center",
                boxShadow = { { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 80 } } },
                children = {
                    UI.Label { text = "🔮", fontSize = 40 },
                    UI.Label { text = "明日预告", fontSize = 18, fontColor = { 130, 170, 220, 255 }, fontWeight = "bold" },
                    UI.Panel {
                        width = "100%", padding = 12, gap = 8,
                        backgroundColor = { 50, 42, 36, 255 }, borderRadius = 8,
                        children = previewItems,
                    },
                    UI.Button {
                        text = "期待明天！", width = 160, height = 38, fontSize = 14,
                        variant = "primary",
                        onClick = function()
                            pendingTomorrowPreview_ = nil; BuildUI()
                        end,
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 12. 对话界面（带背景图 + 打字机效果）
-- ============================================================================
function BuildDialogueUI()
    -- 精英入场对话模式
    if dialogueOverride_ == "elite_entrance" and eliteEntranceDialogues_ then
        return BuildEliteEntranceUI()
    end

    local chapter = CHAPTERS[currentChapter_]
    local dlg = currentDialogues_[dialogueIndex_] or { speaker = "", text = "" }

    local isMonologue = dlg.type == "monologue"
    local hasVoice = FindVoice(dlg.text) ~= nil

    local colors = {
        ["旁白"] = { fg = { 100, 100, 100, 220 }, bg = C.cardAlt },
        ["你"]   = { fg = C.blue,                  bg = { C.blue[1], C.blue[2], C.blue[3], 25 } },
        ["内心"] = { fg = { 170, 155, 138, 220 }, bg = { 42, 36, 30, 240 } },
    }
    local col = colors[dlg.speaker] or { fg = C.gold, bg = { C.accent[1], C.accent[2], C.accent[3], 25 } }

    local bgImg = CHAPTER_IMAGES[currentChapter_] or SCENE_IMAGES.ch1

    -- 对话推进：点击屏幕任意位置均可触发（移动端友好）
    local function onDialogueClick()
        if not CinematicDialogue.IsDone() then
            SkipTypewriter()
            local textLabel = uiRoot_ and uiRoot_:FindById("dialogueText")
            if textLabel then
                local d = currentDialogues_[dialogueIndex_]
                local mono = d and d.type == "monologue"
                local fullText = CinematicDialogue.GetFullText()
                textLabel:SetText(mono and ("「" .. fullText .. "」") or fullText)
            end
            local hintLabel = uiRoot_ and uiRoot_:FindById("dialogueHint")
            if hintLabel then
                hintLabel:SetText((dialogueIndex_ < #currentDialogues_) and "点击继续 ▶" or "点击完成 ✓")
            end
        else
            AdvanceDialogue()
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = bgImg,
        backgroundFit = "cover",
        onClick = onDialogueClick,
        children = {
            -- 章节标题栏（半透明）—— 剧情事件对话显示事件标题
            UI.Panel {
                width = "100%", height = 42, justifyContent = "center", alignItems = "center",
                backgroundColor = { C.overlay[1], C.overlay[2], C.overlay[3], 150 },
                borderWidth = { 0, 0, 1, 0 }, borderColor = { C.border[1], C.border[2], C.border[3], 160 },
                children = { UI.Label { text = (chapter and chapter.title) or (pendingStoryMeta_ and pendingStoryMeta_.title) or "剧情", fontSize = 15, fontColor = C.accent } },
            },
            -- 中央留白，展示背景图
            UI.Panel {
                flex = 1, width = "100%", justifyContent = "flex-end", alignItems = "center",
                paddingBottom = 6,
                children = (function()
                    -- 章节对话显示章节专属氛围；剧情事件对话不显示
                    local atmoText = nil
                    if not pendingStoryEffect_ then
                        local ch = CHAPTERS[currentChapter_]
                        atmoText = ch and ch.atmosphere
                    end
                    if not atmoText then return {} end
                    return {
                        UI.Panel {
                            width = "85%", maxWidth = 440, padding = { 8, 10 },
                            backgroundColor = { C.overlay[1], C.overlay[2], C.overlay[3], 100 }, borderRadius = 10,
                            children = {
                                UI.Label { text = atmoText, fontSize = 14, fontColor = { 240, 235, 225, 200 },
                                    textAlign = "center", whiteSpace = "normal", lineHeight = 1.4 },
                            },
                        },
                    }
                end)(),
            },
            -- 对话框（底部，带打字机效果）
            UI.Panel {
                width = "100%", padding = { 16, 16, 28, 16 }, gap = 10,
                backgroundColor = isMonologue and { 42, 36, 30, 240 } or col.bg,
                borderRadius = { 16, 16, 0, 0 },
                minHeight = 160,
                borderWidth = isMonologue and { 1, 0, 0, 0 } or nil,
                borderColor = isMonologue and { C.border[1], C.border[2], C.border[3], 160 } or nil,
                boxShadow = { { x = 0, y = -6, blur = 20, color = isMonologue and { 0, 0, 0, 50 } or { 0, 0, 0, 70 } } },
                children = {
                    UI.Panel {
                        flexDirection = "row", alignItems = "center",
                        children = {
                            UI.Label {
                                text = isMonologue and "💭 【内心独白】" or ("【" .. dlg.speaker .. "】"),
                                fontSize = isMonologue and 14 or 15,
                                fontColor = isMonologue and C.textDim or col.fg,
                            },
                            UI.Panel { flex = 1 },
                            hasVoice and UI.Label { text = "🔊", fontSize = 14, fontColor = { 100, 160, 200, 180 } } or UI.Panel { width = 0, height = 0 },
                            UI.Label { text = dialogueIndex_ .. "/" .. #currentDialogues_, fontSize = 14, fontColor = C.textDim, marginLeft = hasVoice and 6 or 0 },
                        },
                    },
                    UI.Label {
                        id = "dialogueText",
                        text = (function()
                            local dispText = CinematicDialogue.GetDisplayText()
                            local cineDone = CinematicDialogue.IsDone()
                            if isMonologue then
                                return "「" .. dispText .. (cineDone and "」" or "")
                            end
                            return dispText
                        end)(),
                        fontSize = isMonologue and 13 or 14,
                        fontColor = isMonologue and { 200, 185, 160, 230 } or C.text,
                        width = "100%", whiteSpace = "normal",
                        lineHeight = isMonologue and 1.7 or 1.5,
                        letterSpacing = isMonologue and 0.5 or 0,
                    },
                    UI.Panel {
                        flexDirection = "row", justifyContent = "flex-end", alignItems = "center", width = "100%", gap = 8,
                        children = {
                            -- 已读章节可跳过整段对话
                            chaptersRead_[currentChapter_] and UI.Button {
                                text = "⏭ 跳过全部", height = 36, paddingHorizontal = 14, fontSize = 13,
                                variant = "secondary",
                                onClick = function(self, e)
                                    if e and e.stopPropagation then e:stopPropagation() end
                                    PlaySFX("click"); SkipEntireDialogue()
                                end,
                            } or UI.Panel { width = 0, height = 0 },
                            -- 提示文字（替代按钮，因为整个区域已可点击）
                            UI.Label {
                                id = "dialogueHint",
                                text = CinematicDialogue.IsDone()
                                    and ((dialogueIndex_ < #currentDialogues_) and "点击继续 ▶" or "点击完成 ✓")
                                    or "点击跳过 ▶▶",
                                fontSize = 14, fontColor = { 160, 130, 90, 180 },
                            },
                        },
                    },
                },
            },
        },
    }
end

