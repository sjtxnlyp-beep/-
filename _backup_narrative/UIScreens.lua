---@diagnostic disable: undefined-global
local Retention = require("Retention")

-- ============================================================================
-- 10. UI 调度
-- ============================================================================

-- BuildUI 节流保护：训练模式中防止高频全量重建造成卡顿
local buildUI_lastTime_ = 0
local BUILD_UI_MIN_INTERVAL = 0.05  -- 最小50ms间隔（20FPS上限）

function BuildUI()
    -- ── 自动章节推进拦截（A+C方案）──
    -- 当从任何阶段回到 PHASE_MANAGE 时，若有待推进章节则自动触发
    if currentPhase_ == PHASE_MANAGE and pendingChapterAdvance_ and not pendingChapterAdvance_.isFinal then
        local nextCh = pendingChapterAdvance_.to
        pendingChapterAdvance_ = nil  -- 清除，避免重复触发
        log:Write(LOG_INFO, "[BuildUI] Auto chapter advance intercepted → Chapter " .. tostring(nextCh))
        PlaySFX("upgrade")
        StartChapterWithTransition(nextCh)
        return
    end

    -- 节流：训练模式 playing 阶段防止过于频繁重建
    if currentPhase_ == PHASE_TRAIN and trainPhase_ == "playing" then
        local now = gameTime_ or 0
        if now - buildUI_lastTime_ < BUILD_UI_MIN_INTERVAL then
            return  -- 跳过本次重建，等下一个间隔
        end
        buildUI_lastTime_ = now
    end

    -- 保存当前管理界面滚动位置（重建后在 Update 中恢复）
    if currentPhase_ == PHASE_MANAGE and uiRoot_ then
        local sv = uiRoot_:FindById("manage-scroll")
        if sv then
            local sx, sy = sv:GetScroll()
            if sy and sy > 0 then
                restoreManageScroll_ = { x = sx, y = sy }
            end
        end
        -- 保存网吧弹窗内 ScrollView 的滚动位置
        local csvPopup = uiRoot_:FindById("cafe-popup-scroll")
        if csvPopup then
            local cx, cy = csvPopup:GetScroll()
            if cy and cy > 0 then
                restoreCafePopupScroll_ = { x = cx, y = cy }
            end
        end
    end

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
        elseif currentPhase_ == PHASE_VICTORY  then return BuildVictoryUI()
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

        -- 留存系统弹窗（离线收益：核心弹窗，不受限）
        local offlinePopup = BuildWelcomeBackPopup and BuildWelcomeBackPopup() or nil
        if offlinePopup then table.insert(overlays, offlinePopup) end

        -- ── 非核心弹窗（受每日上限控制） ──
        local previewPopup = nil
        if CanShowPopup() then
            previewPopup = BuildTomorrowPreviewPopup and BuildTomorrowPreviewPopup() or nil
            if previewPopup then
                ConsumePopupSlot()
                table.insert(overlays, previewPopup)
            end
        else
            -- 超出上限：静默消耗 pending 数据（避免下次 BuildUI 再检测）
            pendingTomorrowPreview_ = nil
        end
        -- P0-B 今日任务清单（明日预告关闭后展示，二者不同时出现）
        local dayStartPopup = nil
        if not previewPopup then
            if CanShowPopup() then
                dayStartPopup = BuildDayStartSummaryPopup and BuildDayStartSummaryPopup() or nil
                if dayStartPopup then
                    ConsumePopupSlot()
                    table.insert(overlays, dayStartPopup)
                end
            else
                pendingDayStartSummary_ = nil
            end
        end
        -- P2-A 成就解锁通知（受上限控制，超出转入 mailbox）
        if not previewPopup and not dayStartPopup then
            if CanShowPopup() then
                local achPopup = BuildAchievementUnlockPopup and BuildAchievementUnlockPopup() or nil
                if achPopup then
                    ConsumePopupSlot()
                    table.insert(overlays, achPopup)
                end
            else
                -- 成就超出上限：将剩余转入 mailbox 供玩家手动查看
                if pendingAchievements_ and #pendingAchievements_ > 0 then
                    playerData_.mailbox = playerData_.mailbox or {}
                    for _, ach in ipairs(pendingAchievements_) do
                        table.insert(playerData_.mailbox, {
                            type = "achievement", title = ach.title or ach.id,
                            icon = ach.icon or "🏆", desc = ach.desc or "",
                            reward = ach.reward, read = false,
                            time = playerData_.day or 1,
                        })
                    end
                    pendingAchievements_ = nil
                end
            end
        end

        -- 门口闲聊弹窗（轻量叙事，不受弹窗上限控制）
        if not previewPopup and not dayStartPopup then
            local chatPopup = BuildDoorstepChatPopup and BuildDoorstepChatPopup() or nil
            if chatPopup then table.insert(overlays, chatPopup) end
        end

        -- P0-1 新手引导浮动卡片（底部）
        if currentPhase_ == PHASE_MANAGE then
            local tutCard = BuildTutorialCard and BuildTutorialCard() or nil
            if tutCard then table.insert(overlays, tutCard) end
        end
        -- P0-2 升级效果卡
        if currentPhase_ == PHASE_MANAGE then
            local feedbackPopup = BuildUpgradeFeedbackPopup and BuildUpgradeFeedbackPopup() or nil
            if feedbackPopup then table.insert(overlays, feedbackPopup) end
        end
        -- P0-2 征途小结弹窗（第1天结算后）
        if currentPhase_ == PHASE_MANAGE then
            local daySummary = BuildDaySummaryPopup and BuildDaySummaryPopup() or nil
            if daySummary then table.insert(overlays, daySummary) end
        end
        -- 操作确认弹窗（维修/广告选项等）
        if currentPhase_ == PHASE_MANAGE then
            local actionChoice = BuildActionChoicePopup and BuildActionChoicePopup() or nil
            if actionChoice then table.insert(overlays, actionChoice) end
        end

        -- 用 SafeAreaView 包裹，自动适配手机刘海/状态栏/胶囊按钮
        uiRoot_ = UI.SafeAreaView {
            edges = { "top" },
            paddingTop = 0,
            width = "100%", height = "100%",
            backgroundColor = { 35, 28, 22, 255 },
            children = { result, table.unpack(overlays) },
        }
    else
        local errMsg = ok and ("phase " .. tostring(currentPhase_) .. " returned nil") or tostring(result)
        print("[BuildUI] phase=" .. tostring(currentPhase_) .. " error: " .. errMsg)
        uiRoot_ = UI.SafeAreaView {
            edges = { "top" },
            paddingTop = 0,
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
                        UI.Button { text = "返回管理", width = 160, minHeight = 40, fontSize = 14, variant = "primary",
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
-- P0-1 新手引导：底部浮动任务卡片（醒目、不遮内容）
-- ============================================================================
function BuildTutorialCard()
    local step = playerData_ and (playerData_.tutorialStep or 0) or 0
    if step == 0 or step >= 99 then return nil end

    -- 步骤配置：图标、标题、说明
    local steps = {
        [1] = { icon = "⬆️", title = "新手任务 1/3",  hint = "点击底部「⬆ 升级」标签 → 选一项升级并完成",  tab = "upgrade" },
        [2] = { icon = "📅", title = "新手任务 2/3",  hint = "切换到底部「🏠 经营」标签 → 点击绿色「结束今天」按钮", tab = "action" },
        [3] = { icon = "📖", title = "新手任务 3/3",  hint = "在经营页下方找到「店长日记」，了解今天发生了什么", tab = "action" },
    }
    local cfg = steps[step]
    if not cfg then return nil end

    -- 进度点
    local dots = {}
    for i = 1, 3 do
        table.insert(dots, UI.Panel {
            width = i == step and 16 or 6, height = 6,
            borderRadius = 3,
            backgroundColor = i == step and { 120, 220, 140, 255 }
                           or i < step  and { 80,  160, 100, 200 }
                           or             { 80,   80,  80, 120 },
        })
    end

    return UI.Panel {
        position = "absolute",
        bottom = 78, left = 12, right = 12,  -- 底部导航栏(66px)+间距
        zIndex = 200,
        -- 发光投影效果
        shadowColor = { 0, 0, 0, 180 },
        shadowOffsetY = 4, shadowBlur = 12,
        borderRadius = 14,
        children = {
            UI.Panel {
                width = "100%",
                backgroundColor = { 22, 45, 30, 245 },
                borderRadius = 14,
                borderWidth = 1, borderColor = { 80, 180, 100, 180 },
                paddingHorizontal = 14, paddingVertical = 10,
                flexDirection = "row", alignItems = "center", gap = 12,
                children = {
                    -- 左侧图标徽章
                    UI.Panel {
                        width = 44, height = 44, borderRadius = 22,
                        backgroundColor = { 40, 100, 60, 200 },
                        borderWidth = 1, borderColor = { 100, 200, 120, 160 },
                        justifyContent = "center", alignItems = "center", flexShrink = 0,
                        children = {
                            UI.Label { text = cfg.icon, fontSize = 22, textAlign = "center" },
                        },
                    },
                    -- 中间文字
                    UI.Panel {
                        flex = 1, gap = 4,
                        children = {
                            -- 标题行 + 进度点
                            UI.Panel {
                                flexDirection = "row", alignItems = "center",
                                justifyContent = "space-between",
                                children = {
                                    UI.Label { text = cfg.title, fontSize = 11,
                                        fontWeight = "bold", fontColor = { 120, 220, 140, 255 } },
                                    UI.Panel { flexDirection = "row", gap = 3, alignItems = "center",
                                        children = dots },
                                },
                            },
                            UI.Label {
                                text = cfg.hint, fontSize = 12,
                                fontColor = { 220, 245, 225, 230 },
                                whiteSpace = "normal", lineHeight = 1.3,
                            },
                        },
                    },
                    -- 右侧跳过按钮
                    UI.Panel {
                        width = 28, height = 28, borderRadius = 14,
                        backgroundColor = { 255, 255, 255, 15 },
                        justifyContent = "center", alignItems = "center",
                        flexShrink = 0,
                        onClick = function()
                            playerData_.tutorialStep = 99
                            BuildUI()
                        end,
                        children = {
                            UI.Label { text = "✕", fontSize = 13,
                                fontColor = { 180, 200, 185, 180 }, textAlign = "center" },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- P0-2 升级效果卡弹窗（自动3秒消失）
-- ============================================================================
do
    local feedbackDismissTimer_ = nil
end

function BuildUpgradeFeedbackPopup()
    if not pendingUpgradeFeedback_ then return nil end
    local fb = pendingUpgradeFeedback_

    -- 获取升级配置以查询 levelDesc 和 maxLevel
    local cfg = UPGRADES and UPGRADES[fb.key]
    local curLevel = fb.level or 1
    local maxLevel = cfg and cfg.costs and #cfg.costs or curLevel
    local levelDesc = cfg and cfg.levelDesc and cfg.levelDesc[curLevel] or nil
    local prevDesc = cfg and cfg.levelDesc and curLevel > 1 and cfg.levelDesc[curLevel - 1] or nil
    local isMaxed = curLevel >= maxLevel

    -- 收益数据
    local incomeDelta = fb.incomeDelta or 0

    -- ── 构建弹窗内容 ──
    local popupChildren = {}

    -- 1. 顶部大图标 + 升级标题
    table.insert(popupChildren, UI.Panel {
        width = "100%", alignItems = "center", gap = 4, paddingTop = 4,
        children = {
            UI.Label { text = fb.icon or "🔧", fontSize = 36 },
            UI.Label {
                text = "升级完成！",
                fontSize = 16, fontWeight = "bold",
                fontColor = { 120, 255, 120, 255 },
                textShadow = { offsetX = 0, offsetY = 1, blur = 6, color = { 0, 200, 0, 120 } },
            },
            UI.Label {
                text = (fb.name or fb.key) .. "  Lv." .. curLevel .. (isMaxed and " MAX" or ""),
                fontSize = 13, fontColor = isMaxed and { 255, 215, 0, 255 } or { 200, 230, 200, 255 },
            },
        },
    })

    -- 2. 进度条（当前等级 / 总等级数）
    local progressFrac = curLevel / maxLevel
    table.insert(popupChildren, UI.Panel {
        width = "100%", gap = 3,
        children = {
            -- 进度条背景
            UI.Panel {
                width = "100%", height = 8, borderRadius = 4,
                backgroundColor = { 40, 60, 40, 200 },
                children = {
                    UI.Panel {
                        width = math.floor(progressFrac * 100) .. "%", height = "100%",
                        borderRadius = 4,
                        backgroundColor = isMaxed and { 255, 200, 50, 255 } or { 80, 200, 80, 255 },
                    },
                },
            },
            UI.Label {
                text = curLevel .. " / " .. maxLevel .. (isMaxed and " ✨ 满级" or ""),
                fontSize = 10, fontColor = { 150, 180, 150, 200 },
                textAlign = "right", width = "100%",
            },
        },
    })

    -- 3. 升级描述（Before → After 对比感）
    if levelDesc then
        local descChildren = {}
        if prevDesc then
            table.insert(descChildren, UI.Label {
                text = "旧: " .. prevDesc,
                fontSize = 11, fontColor = { 130, 130, 130, 180 },
                whiteSpace = "normal",
                textDecoration = "line-through",
            })
            table.insert(descChildren, UI.Label { text = "↓", fontSize = 10, fontColor = { 100, 200, 100, 150 } })
        end
        table.insert(descChildren, UI.Label {
            text = "✦ " .. levelDesc,
            fontSize = 12, fontColor = { 220, 255, 200, 255 }, fontWeight = "bold",
            whiteSpace = "normal", lineHeight = 1.4,
        })
        table.insert(popupChildren, UI.Panel {
            width = "100%", borderRadius = 8, padding = 10,
            backgroundColor = { 25, 45, 25, 200 },
            borderWidth = 1, borderColor = { 60, 120, 60, 100 },
            gap = 3,
            children = descChildren,
        })
    end

    -- 4. 收益卡片
    local statItems = {}
    if incomeDelta > 0 then
        table.insert(statItems, UI.Panel {
            flex = 1, alignItems = "center", gap = 2,
            children = {
                UI.Label { text = "📈", fontSize = 16 },
                UI.Label { text = "+" .. incomeDelta, fontSize = 14, fontWeight = "bold", fontColor = { 100, 255, 100, 255 } },
                UI.Label { text = "日收入", fontSize = 9, fontColor = { 140, 180, 140, 200 } },
            },
        })
    elseif incomeDelta < 0 then
        table.insert(statItems, UI.Panel {
            flex = 1, alignItems = "center", gap = 2,
            children = {
                UI.Label { text = "📉", fontSize = 16 },
                UI.Label { text = tostring(incomeDelta), fontSize = 14, fontWeight = "bold", fontColor = { 255, 100, 100, 255 } },
                UI.Label { text = "日收入", fontSize = 9, fontColor = { 140, 180, 140, 200 } },
            },
        })
    end
    table.insert(statItems, UI.Panel {
        flex = 1, alignItems = "center", gap = 2,
        children = {
            UI.Label { text = "⭐", fontSize = 16 },
            UI.Label { text = "+5", fontSize = 14, fontWeight = "bold", fontColor = { 255, 220, 100, 255 } },
            UI.Label { text = "声望", fontSize = 9, fontColor = { 140, 180, 140, 200 } },
        },
    })

    if #statItems > 0 then
        table.insert(popupChildren, UI.Panel {
            width = "100%", flexDirection = "row", gap = 8, justifyContent = "center",
            children = statItems,
        })
    end

    -- 5. 星级进度行
    local okR, rating = pcall(GetCafeRating)
    if okR and rating then
        local starIcons = ""
        for i = 1, 5 do starIcons = starIcons .. (i <= rating.star and "★" or "☆") end
        local progressText = starIcons .. " Lv." .. rating.totalLevel
        local hintText = ""
        if rating.nextStarAt and rating.nextStarAt > 0 then
            local gap2 = rating.nextStarAt - rating.totalLevel
            hintText = "  距" .. (rating.nextStarName or "下一星") .. "还差" .. gap2 .. "级"
        end
        table.insert(popupChildren, UI.Panel {
            width = "100%", alignItems = "center", gap = 2,
            borderTopWidth = 1, borderColor = { 80, 130, 80, 80 }, paddingTop = 6,
            children = {
                UI.Label { text = progressText, fontSize = 12, fontColor = { 255, 220, 100, 255 } },
                hintText ~= "" and UI.Label { text = hintText, fontSize = 10, fontColor = { 180, 180, 140, 180 } } or nil,
            },
        })
    end

    -- 6. 确认按钮
    table.insert(popupChildren, UI.Button {
        text = isMaxed and "满级了！太强了 🎉" or "不错，继续搞 💪",
        width = "100%", height = 32, fontSize = 13,
        variant = "primary",
        onClick = function()
            pendingUpgradeFeedback_ = nil
            BuildUI()
        end,
    })

    -- ── 居中遮罩弹窗 ──
    return UI.Panel {
        position = "absolute",
        top = 0, left = 0, right = 0, bottom = 0,
        justifyContent = "center", alignItems = "center",
        backgroundColor = { 0, 0, 0, 120 },
        children = {
            UI.Panel {
                width = 240,
                backgroundColor = { 20, 35, 20, 245 },
                borderRadius = 14,
                borderWidth = 2, borderColor = isMaxed and { 255, 200, 50, 200 } or { 80, 200, 80, 180 },
                padding = 16, gap = 10,
                boxShadow = {
                    { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 150 } },
                    { x = 0, y = 0, blur = 30, color = isMaxed and { 255, 200, 0, 40 } or { 0, 200, 0, 30 } },
                },
                children = popupChildren,
            },
        },
    }
end

-- ============================================================================
-- ============================================================================
-- P0-2 日结分屏弹窗（每天结束后弹出，分3屏展示：收支摘要/今日故事/状态变化）
-- ============================================================================
daySummaryPage_ = 1  -- 当前分屏页码

function BuildDaySummaryPopup()
    if not pendingDaySummary_ then return nil end
    local s = pendingDaySummary_
    local page = daySummaryPage_ or 1
    local isProfit = (s.netIncome or 0) >= 0
    local profitColor = isProfit and { 100, 220, 100, 255 } or { 240, 80, 80, 255 }
    local profitSign = isProfit and "+" or ""

    -- 判断总页数（有故事内容才显示故事页，有状态变化才显示状态页，有周报才显示周报页）
    local hasStory = s.storyLines and #s.storyLines > 0
    local hasStatus = s.statusChanges and #s.statusChanges > 0
    local hasWeekly = s.weeklyReport ~= nil
    local totalPages = 1 + (hasStory and 1 or 0) + 1 + (hasWeekly and 1 or 0)  -- 收支 + [故事] + 提示 + [周报]

    -- 构建页面内容
    local pageContent = {}

    if page == 1 then
        -- ═══ 第1屏：收支摘要 ═══
        -- 数据卡片行
        local cards = UI.Panel {
            width = "100%", flexDirection = "row", gap = 8,
            children = {
                UI.Panel {
                    flex = 1, borderRadius = 10,
                    backgroundColor = { 40, 80, 40, 200 },
                    borderWidth = 1, borderColor = { 80, 160, 80, 120 },
                    padding = 10, gap = 4, alignItems = "center",
                    children = {
                        UI.Label { text = "📈", fontSize = 20 },
                        UI.Label { text = "$" .. (s.income or 0), fontSize = 16,
                            fontWeight = "bold", fontColor = { 120, 220, 120, 255 } },
                        UI.Label { text = "今日收入", fontSize = 11, fontColor = C.textLight },
                    },
                },
                UI.Panel {
                    flex = 1, borderRadius = 10,
                    backgroundColor = isProfit and { 40, 80, 40, 200 } or { 80, 30, 30, 200 },
                    borderWidth = 1, borderColor = isProfit and { 80, 160, 80, 120 } or { 160, 60, 60, 120 },
                    padding = 10, gap = 4, alignItems = "center",
                    children = {
                        UI.Label { text = isProfit and "💰" or "📉", fontSize = 20 },
                        UI.Label { text = profitSign .. (s.netIncome or 0), fontSize = 16,
                            fontWeight = "bold", fontColor = profitColor },
                        UI.Label { text = "净利润", fontSize = 11, fontColor = C.textLight },
                    },
                },
                UI.Panel {
                    flex = 1, borderRadius = 10,
                    backgroundColor = { 50, 45, 20, 200 },
                    borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 100 },
                    padding = 10, gap = 4, alignItems = "center",
                    children = {
                        UI.Label { text = "🏦", fontSize = 20 },
                        UI.Label { text = "$" .. (s.money or 0), fontSize = 16,
                            fontWeight = "bold", fontColor = C.gold },
                        UI.Label { text = "存款", fontSize = 11, fontColor = C.textLight },
                    },
                },
            },
        }
        table.insert(pageContent, cards)

        -- 支出明细（紧凑列表）
        if s.expenses and #s.expenses > 0 then
            local expChildren = {
                UI.Label { text = "支出明细", fontSize = 12, fontWeight = "bold",
                    fontColor = { 200, 180, 150, 200 } },
            }
            for _, exp in ipairs(s.expenses) do
                table.insert(expChildren, UI.Panel {
                    width = "100%", flexDirection = "row", justifyContent = "space-between",
                    children = {
                        UI.Label { text = exp.name, fontSize = 11, fontColor = C.textLight },
                        UI.Label { text = "-$" .. exp.amount, fontSize = 11,
                            fontColor = { 240, 130, 100, 220 } },
                    },
                })
            end
            table.insert(expChildren, UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between",
                marginTop = 4, paddingTop = 4,
                borderTopWidth = 1, borderColor = { 255, 255, 255, 30 },
                children = {
                    UI.Label { text = "合计支出", fontSize = 11, fontWeight = "bold", fontColor = C.textLight },
                    UI.Label { text = "-$" .. (s.totalExpense or 0), fontSize = 11,
                        fontWeight = "bold", fontColor = { 240, 100, 80, 255 } },
                },
            })
            table.insert(pageContent, UI.Panel {
                width = "100%", borderRadius = 8, backgroundColor = { 20, 18, 12, 200 },
                padding = 10, gap = 3,
                children = expChildren,
            })
        end

    elseif page == 2 and hasStory then
        -- ═══ 第2屏：今日故事 ═══
        local storyChildren = {}
        for i, line in ipairs(s.storyLines) do
            if i <= 5 then
                table.insert(storyChildren, UI.Label {
                    text = line, fontSize = 12,
                    fontColor = { 220, 210, 190, 230 },
                    whiteSpace = "normal", lineHeight = 1.5,
                })
                if i < math.min(5, #s.storyLines) then
                    table.insert(storyChildren, UI.Panel {
                        width = "100%", height = 1,
                        backgroundColor = { 255, 255, 255, 15 }, marginVertical = 2,
                    })
                end
            end
        end
        table.insert(pageContent, UI.Panel {
            width = "100%", borderRadius = 8, backgroundColor = { 25, 30, 20, 200 },
            borderWidth = 1, borderColor = { 100, 140, 80, 80 },
            padding = 12, gap = 6,
            children = storyChildren,
        })

    elseif page == totalPages and hasWeekly then
        -- ═══ 五日周报页 ═══
        local wr = s.weeklyReport
        local netPositive = (wr.totalNet or 0) >= 0
        -- 评级
        local grade = "D"
        if wr.avgNet >= 200 then grade = "S"
        elseif wr.avgNet >= 100 then grade = "A"
        elseif wr.avgNet >= 50 then grade = "B"
        elseif wr.avgNet >= 0 then grade = "C"
        end
        local gradeColors = { S = {255,215,0,255}, A = {100,220,100,255}, B = {100,180,220,255}, C = {200,180,100,255}, D = {200,100,100,255} }
        local gradeColor = gradeColors[grade] or C.textLight
        -- 趋势箭头
        local function trend(val)
            if val > 0 then return "↑" .. val
            elseif val < 0 then return "↓" .. math.abs(val)
            else return "→ 持平" end
        end
        table.insert(pageContent, UI.Panel {
            width = "100%", borderRadius = 12,
            backgroundColor = { 20, 30, 50, 220 },
            borderWidth = 1, borderColor = { 100, 150, 220, 150 },
            padding = 14, gap = 8,
            children = {
                -- 标题与评级
                UI.Panel {
                    width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                    children = {
                        UI.Label { text = "📅 第" .. wr.fromDay .. "~" .. wr.toDay .. "天", fontSize = 13, fontWeight = "bold", fontColor = { 180, 210, 255, 255 } },
                        UI.Panel {
                            paddingHorizontal = 10, paddingVertical = 4, borderRadius = 8,
                            backgroundColor = { gradeColor[1], gradeColor[2], gradeColor[3], 40 },
                            borderWidth = 1, borderColor = gradeColor,
                            children = { UI.Label { text = grade .. "级", fontSize = 14, fontWeight = "bold", fontColor = gradeColor } },
                        },
                    },
                },
                -- 数据汇总
                UI.Panel {
                    width = "100%", flexDirection = "row", gap = 6,
                    children = {
                        UI.Panel { flex = 1, alignItems = "center", gap = 2, children = {
                            UI.Label { text = "$" .. wr.totalIncome, fontSize = 14, fontWeight = "bold", fontColor = { 120, 220, 120, 255 } },
                            UI.Label { text = "总收入", fontSize = 10, fontColor = C.textLight },
                        }},
                        UI.Panel { flex = 1, alignItems = "center", gap = 2, children = {
                            UI.Label { text = "$" .. wr.totalExpense, fontSize = 14, fontWeight = "bold", fontColor = { 240, 130, 100, 255 } },
                            UI.Label { text = "总支出", fontSize = 10, fontColor = C.textLight },
                        }},
                        UI.Panel { flex = 1, alignItems = "center", gap = 2, children = {
                            UI.Label { text = (netPositive and "+" or "") .. wr.totalNet, fontSize = 14, fontWeight = "bold", fontColor = netPositive and {100,220,100,255} or {240,80,80,255} },
                            UI.Label { text = "净利润", fontSize = 10, fontColor = C.textLight },
                        }},
                    },
                },
                -- 增长指标
                UI.Panel {
                    width = "100%", height = 1, backgroundColor = { 255, 255, 255, 20 },
                },
                UI.Panel {
                    width = "100%", gap = 4,
                    children = {
                        UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", children = {
                            UI.Label { text = "💰 资金变动", fontSize = 11, fontColor = C.textLight },
                            UI.Label { text = trend(wr.moneyGrowth), fontSize = 11, fontColor = wr.moneyGrowth >= 0 and {100,220,100,255} or {240,100,80,255} },
                        }},
                        UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", children = {
                            UI.Label { text = "⭐ 声望变动", fontSize = 11, fontColor = C.textLight },
                            UI.Label { text = trend(wr.repGrowth), fontSize = 11, fontColor = wr.repGrowth >= 0 and {100,180,220,255} or {240,100,80,255} },
                        }},
                        UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", children = {
                            UI.Label { text = "📈 日均收入", fontSize = 11, fontColor = C.textLight },
                            UI.Label { text = "$" .. wr.avgIncome, fontSize = 11, fontColor = { 180, 220, 180, 255 } },
                        }},
                    },
                },
                -- 最佳/最差天
                (wr.bestDay and wr.worstDay) and UI.Panel {
                    width = "100%", flexDirection = "row", gap = 6, marginTop = 2,
                    children = {
                        UI.Panel { flex = 1, borderRadius = 6, backgroundColor = {30,60,30,200}, padding = 6, alignItems = "center", gap = 2, children = {
                            UI.Label { text = "🏆 最佳", fontSize = 9, fontColor = C.textLight },
                            UI.Label { text = "Day" .. (wr.bestDay.day or "?"), fontSize = 11, fontWeight = "bold", fontColor = {120,220,120,255} },
                            UI.Label { text = "+$" .. (wr.bestDay.net or 0), fontSize = 10, fontColor = {100,200,100,200} },
                        }},
                        UI.Panel { flex = 1, borderRadius = 6, backgroundColor = {60,30,30,200}, padding = 6, alignItems = "center", gap = 2, children = {
                            UI.Label { text = "📉 最差", fontSize = 9, fontColor = C.textLight },
                            UI.Label { text = "Day" .. (wr.worstDay.day or "?"), fontSize = 11, fontWeight = "bold", fontColor = {240,130,100,255} },
                            UI.Label { text = "$" .. (wr.worstDay.net or 0), fontSize = 10, fontColor = {200,100,80,200} },
                        }},
                    },
                } or UI.Panel { height = 0 },
            },
        })

    else
        -- ═══ 状态变化 + 提示页 ═══
        -- 状态变化
        if hasStatus then
            local statChildren = {}
            for _, st in ipairs(s.statusChanges) do
                table.insert(statChildren, UI.Label {
                    text = st, fontSize = 13, fontColor = { 200, 200, 220, 240 },
                })
            end
            table.insert(pageContent, UI.Panel {
                width = "100%", borderRadius = 8, backgroundColor = { 30, 25, 40, 200 },
                borderWidth = 1, borderColor = { 120, 100, 180, 80 },
                padding = 10, gap = 6,
                children = statChildren,
            })
        end
        -- 提示
        table.insert(pageContent, UI.Panel {
            width = "100%", borderRadius = 10,
            backgroundColor = { 30, 50, 70, 200 },
            borderWidth = 1, borderColor = { 80, 130, 200, 120 },
            padding = 10, flexDirection = "row", gap = 8, alignItems = "flex-start",
            children = {
                UI.Label { text = "💡", fontSize = 16, flexShrink = 0 },
                UI.Label {
                    text = s.tip or "继续经营，招募队员，向非洲电竞冠军进发！",
                    fontSize = 12, fontColor = { 160, 210, 255, 230 },
                    whiteSpace = "normal", lineHeight = 1.4, flex = 1,
                },
            },
        })
        -- 明日预告
        if s.tomorrowPreview then
            local tp = s.tomorrowPreview
            table.insert(pageContent, UI.Panel {
                width = "100%", borderRadius = 10,
                backgroundColor = { 50, 35, 15, 220 },
                borderWidth = 1, borderColor = { 220, 170, 50, 150 },
                padding = 10, gap = 4,
                children = {
                    UI.Label {
                        text = "🔮 明日预告",
                        fontSize = 13, fontWeight = "bold",
                        fontColor = { 255, 210, 80, 255 },
                    },
                    UI.Panel {
                        width = "100%", flexDirection = "row", gap = 8, alignItems = "center",
                        children = {
                            UI.Label { text = tp.icon, fontSize = 20 },
                            UI.Panel { flex = 1, gap = 2, children = {
                                UI.Label {
                                    text = tp.title,
                                    fontSize = 13, fontWeight = "bold",
                                    fontColor = { 255, 240, 200, 255 },
                                },
                                UI.Label {
                                    text = tp.hint,
                                    fontSize = 11, fontColor = { 200, 180, 140, 220 },
                                    whiteSpace = "normal", lineHeight = 1.3,
                                },
                            }},
                        },
                    },
                },
            })
        end
    end

    -- 页面标题（动态构建页面标题列表）
    local pageTitleList = { "📊 收支摘要" }
    if hasStory then table.insert(pageTitleList, "📖 今日故事") end
    table.insert(pageTitleList, "🔔 状态总结")
    if hasWeekly then table.insert(pageTitleList, "📋 五日周报") end
    local titleText = pageTitleList[page] or pageTitleList[1]

    -- 翻页指示器
    local dots = {}
    for i = 1, totalPages do
        table.insert(dots, UI.Panel {
            width = 8, height = 8, borderRadius = 4,
            backgroundColor = (i == page) and C.gold or { 100, 100, 100, 150 },
            marginHorizontal = 3,
        })
    end

    -- 按钮：最后一页显示"继续征途"，其他页显示"下一页→"
    local isLastPage = (page >= totalPages)
    local btnText = isLastPage and "继续征途 →" or "继续 →"
    local btnAction = function()
        if isLastPage then
            pendingDaySummary_ = nil
            daySummaryPage_ = 1
            BuildUI()
        else
            ---@diagnostic disable-next-line: assign-type-mismatch
            daySummaryPage_ = page + 1
            BuildUI()
        end
    end

    -- 组装 children 列表（避免 table.unpack 不在末尾的陷阱）
    local cardChildren = {
        -- 标题行
        UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            justifyContent = "center", gap = 8,
            children = {
                UI.Label {
                    text = "第" .. s.day .. "天 · " .. titleText,
                    fontSize = 16, fontWeight = "bold",
                    fontColor = C.gold, textAlign = "center",
                },
            },
        },
        -- 分割线
        UI.Panel { width = "100%", height = 1, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 60 } },
    }
    -- 插入页面内容
    for _, item in ipairs(pageContent) do
        table.insert(cardChildren, item)
    end
    -- 翻页指示器
    table.insert(cardChildren, UI.Panel {
        width = "100%", flexDirection = "row", justifyContent = "center",
        alignItems = "center", marginTop = 4,
        children = dots,
    })
    -- 按钮
    table.insert(cardChildren, UI.Button {
        text = btnText,
        width = "100%", height = 42, fontSize = 14, fontWeight = "bold",
        backgroundColor = isLastPage and C.accent or { 60, 90, 60, 255 },
        borderRadius = PX.cardRadius,
        onClick = btnAction,
    })

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 20,
        zIndex = 300,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 340,
                backgroundColor = C.card,
                borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                padding = 20, gap = 12,
                children = cardChildren,
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

    -- 交互式选择区域（有choices且尚未选择时显示按钮，选择后显示响应）
    local hasChoices = panel.choices and #panel.choices > 0
    local bottomChildren = {}
    -- 标题
    table.insert(bottomChildren, UI.Label {
        text = panel.title,
        fontSize = 20, fontWeight = "bold",
        fontColor = { 255, 220, 160, 255 },
    })
    -- 文字行
    table.insert(bottomChildren, UI.Panel {
        width = "90%", maxWidth = 360,
        gap = 2, alignItems = "center",
        children = lineChildren,
    })

    if hasChoices and not comicChoiceResponse_ then
        -- 显示选择按钮（点击面板不翻页）
        table.insert(bottomChildren, UI.Panel { height = 10 })
        for _, choice in ipairs(panel.choices) do
            table.insert(bottomChildren, UI.Button {
                text = choice.text, fontSize = 14, fontWeight = "bold",
                width = "85%", maxWidth = 320, height = 44,
                backgroundColor = { 60, 45, 30, 220 },
                fontColor = { 255, 248, 235, 240 },
                borderWidth = 1, borderColor = { 255, 200, 100, 120 },
                borderRadius = 8,
                onClick = function()
                    PlaySFX("click")
                    comicChoiceResponse_ = choice.response
                    BuildUI()
                end,
            })
        end
    elseif comicChoiceResponse_ then
        -- 已选择：显示响应文本 + 点击继续提示
        table.insert(bottomChildren, UI.Panel { height = 8 })
        table.insert(bottomChildren, UI.Label {
            text = comicChoiceResponse_,
            fontSize = 14, fontColor = { 180, 255, 180, 230 },
            textAlign = "center", whiteSpace = "normal",
            width = "85%", maxWidth = 320,
        })
        table.insert(bottomChildren, UI.Panel { height = 8 })
        table.insert(bottomChildren, UI.Label {
            text = isLast and "点击开始游戏 ▶" or "点击继续 ▶",
            fontSize = 12, fontColor = { 255, 248, 235, 140 },
        })
    else
        -- 无选择的普通面板
        table.insert(bottomChildren, UI.Panel { height = 6 })
        table.insert(bottomChildren, UI.Panel {
            flexDirection = "row", gap = 6,
            alignItems = "center", justifyContent = "center",
            children = dots,
        })
        table.insert(bottomChildren, UI.Label {
            text = isLast and "点击开始游戏 ▶" or "点击继续 ▶",
            fontSize = 12, fontColor = { 255, 248, 235, 100 },
        })
    end

    -- 面板点击逻辑：有未选择的choices时禁用翻页
    local panelOnClick = nil
    if not hasChoices or comicChoiceResponse_ then
        panelOnClick = function()
            comicChoiceResponse_ = nil  -- 清除响应
            advanceComic()
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = { 30, 22, 16, 255 },
        onClick = panelOnClick,
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
                children = bottomChildren,
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

    local havocCoins = reward.havocCoins or 0

    local btns = {}
    -- 看广告翻倍按钮
    if reward.canDouble then
        local doubleText = "📺 看广告翻倍 → $" .. (reward.earnings * 2)
        if havocCoins > 0 then
            doubleText = doubleText .. " +💎" .. (havocCoins * 2)
        end
        table.insert(btns, AdManager.AdButton {
            sceneId = "offline_double", day = playerData_.day,
            text = doubleText,
            onReward = function()
                if Retention then Retention.ClaimOfflineEarnings(true) end
                pendingOfflineReward_ = nil
                BuildUI()
            end,
            width = "100%", height = 40, fontSize = 14,
        })
    end
    -- 直接领取按钮
    local claimText = "💰 领取 $" .. reward.earnings
    if havocCoins > 0 then
        claimText = claimText .. " +💎" .. havocCoins
    end
    table.insert(btns, UI.Button {
        text = claimText,
        width = "100%", height = 40, fontSize = 14,
        variant = "primary",
        onClick = function()
            if Retention then Retention.ClaimOfflineEarnings(false) end
            pendingOfflineReward_ = nil
            BuildUI()
        end,
    })

    -- 自动化等级描述
    local autoLevel = reward.autoLevel or 0
    local autoNames = { [0] = "帮工小弟", "自动收银", "稳定运营", "滚雪球", "连锁帝国" }
    local autoIcons = { [0] = "🧹", "💰", "🔧", "🏪", "👑" }
    local autoName = autoNames[autoLevel] or "帮工小弟"
    local autoIcon = autoIcons[autoLevel] or "🧹"

    -- 离开描述（含天数推进）- Lv0特殊文案
    local awayDesc
    if autoLevel == 0 then
        local helperNames = { "门口的Kofi", "小弟Kwame", "热心邻居Ama" }
        local helperName = helperNames[math.random(1, #helperNames)]
        awayDesc = helperName .. "帮你看着店收了 $" .. reward.earnings .. "，你走了 " .. reward.hours .. " 小时。"
    else
        awayDesc = "你离开了 " .. reward.hours .. " 小时"
        if (reward.daysAdvanced or 0) > 0 then
            awayDesc = awayDesc .. "（推进了 " .. reward.daysAdvanced .. " 天）"
        end
        awayDesc = awayDesc .. "，网吧照常运营。"
    end

    -- 每小时收益提示
    local perHourInfo = nil
    if (reward.perHour or 0) > 0 then
        perHourInfo = UI.Label {
            text = autoIcon .. " " .. autoName .. " · $" .. reward.perHour .. "/小时",
            fontSize = 12, fontColor = C.textSub, textAlign = "center", width = "100%",
        }
    end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        children = {
            UI.Panel {
                width = "85%", maxWidth = 360, padding = 20, gap = 14,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    UI.Label { text = "🌙", fontSize = 48 },
                    UI.Label { text = "欢迎回来！", fontSize = 20, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label {
                        text = awayDesc,
                        fontSize = 14, fontColor = C.text, whiteSpace = "normal", textAlign = "center", width = "100%",
                    },
                    UI.Panel {
                        width = "100%", padding = 12, backgroundColor = { 60, 50, 40, 255 },
                        borderRadius = 8, alignItems = "center", gap = 4,
                        children = {
                            UI.Label { text = "💰 离线收益", fontSize = 13, fontColor = C.textSub },
                            UI.Label { text = "$" .. reward.earnings, fontSize = 28, fontColor = C.gold, fontWeight = "bold" },
                            havocCoins > 0 and UI.Panel {
                                flexDirection = "row", alignItems = "center", gap = 4,
                                children = {
                                    UI.Label { text = "💎", fontSize = 16 },
                                    UI.Label { text = "+" .. havocCoins .. " 哈弗币", fontSize = 16, fontColor = { 130, 200, 255, 255 }, fontWeight = "bold" },
                                },
                            } or nil,
                            perHourInfo,
                        },
                    },
                    -- 连续登录签到条
                    (function()
                        local RV2 = require("RetentionV2")
                        local info = RV2.GetLoginStreakInfo()
                        local rewards = RV2.LOGIN_STREAK_REWARDS
                        -- 7日签到进度条
                        local dayDots = {}
                        for i = 1, 7 do
                            local r = rewards[i]
                            local isToday = (i == info.day)
                            local isPast = (i < info.day) or (i == info.day and info.claimed)
                            local dotBg = isPast and { 80, 160, 80, 255 }
                                or isToday and { 255, 200, 50, 255 }
                                or { 60, 60, 60, 200 }
                            local dotBorder = isToday and { 255, 230, 100, 255 } or { 80, 80, 80, 100 }
                            table.insert(dayDots, UI.Panel {
                                width = 32, height = 40, alignItems = "center", justifyContent = "center",
                                gap = 2,
                                children = {
                                    UI.Panel {
                                        width = 24, height = 24, borderRadius = 12,
                                        backgroundColor = dotBg, borderWidth = isToday and 2 or 1,
                                        borderColor = dotBorder,
                                        justifyContent = "center", alignItems = "center",
                                        children = {
                                            UI.Label { text = isPast and "✓" or r.icon, fontSize = isPast and 10 or 12 },
                                        },
                                    },
                                    UI.Label { text = "D" .. i, fontSize = 9, fontColor = isToday and C.gold or C.textDim },
                                },
                            })
                        end
                        -- 领取按钮
                        local claimBtn = nil
                        if not info.claimed then
                            claimBtn = UI.Button {
                                text = "🎁 领取签到: " .. info.reward.label,
                                width = "100%", height = 36, fontSize = 13, fontWeight = "bold",
                                backgroundColor = { 180, 120, 30, 255 }, borderRadius = 8,
                                onClick = function()
                                    RV2.ClaimLoginStreakReward()
                                    BuildUI()
                                end,
                            }
                        else
                            claimBtn = UI.Label {
                                text = "✅ 今日已签到 · 连续" .. info.streakCount .. "天",
                                fontSize = 12, fontColor = { 120, 200, 120, 200 }, textAlign = "center", width = "100%",
                            }
                        end
                        return UI.Panel {
                            width = "100%", padding = 10, backgroundColor = { 40, 35, 50, 220 },
                            borderRadius = 10, borderWidth = 1, borderColor = { 160, 130, 60, 120 },
                            gap = 8, alignItems = "center",
                            children = {
                                UI.Label { text = "📅 连续签到 · 第" .. info.day .. "/7天", fontSize = 12, fontColor = C.gold, fontWeight = "bold" },
                                UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", children = dayDots },
                                claimBtn,
                            },
                        }
                    end)(),
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

    -- urgency 对应的背景色和边框色
    local urgencyStyle = {
        high = { bg = { 80, 25, 20, 220 }, border = { 220, 80, 60, 180 }, dot = { 240, 80, 60, 255 } },
        mid  = { bg = { 55, 48, 20, 220 }, border = { 220, 180, 50, 160 }, dot = { 240, 180, 50, 255 } },
        low  = { bg = { 38, 50, 38, 200 }, border = { 80, 150, 80, 120 }, dot = { 100, 200, 100, 255 } },
    }

    local previewItems = {}
    for i, item in ipairs(pendingTomorrowPreview_) do
        -- 兼容旧格式（纯字符串）和新格式（table）
        local text    = type(item) == "table" and item.text    or item
        local urgency = type(item) == "table" and item.urgency or "low"
        local icon    = type(item) == "table" and item.icon    or "📌"
        local isNarrative = type(item) == "table" and item.narrative
        local scene   = type(item) == "table" and item.scene or nil
        local style   = urgencyStyle[urgency] or urgencyStyle.low

        if isNarrative and scene then
            -- 叙事化条目：场景描写 + 故事钩子，特殊渲染
            table.insert(previewItems, UI.Panel {
                width = "100%", borderRadius = 10, padding = 12,
                backgroundColor = { 20, 25, 45, 240 },
                borderWidth = 1, borderColor = { 100, 120, 200, 150 },
                gap = 8,
                children = {
                    -- 场景氛围文字（斜体感，淡色）
                    UI.Label {
                        text = scene, fontSize = 12,
                        fontColor = { 140, 160, 200, 200 },
                        whiteSpace = "normal", lineHeight = 1.5,
                    },
                    -- 分隔
                    UI.Panel { width = 40, height = 1, backgroundColor = { 100, 120, 200, 80 } },
                    -- 故事钩子（高亮，更大字号）
                    UI.Panel {
                        width = "100%", flexDirection = "row", gap = 8, alignItems = "flex-start",
                        children = {
                            UI.Label { text = icon, fontSize = 20, flexShrink = 0 },
                            UI.Label {
                                text = text, fontSize = 14,
                                fontColor = { 220, 230, 255, 255 },
                                fontWeight = "bold",
                                whiteSpace = "normal", lineHeight = 1.5, flex = 1,
                            },
                        },
                    },
                },
            })
        else
            -- 普通系统提示条目
            table.insert(previewItems, UI.Panel {
                width = "100%", borderRadius = 8, padding = 10,
                backgroundColor = style.bg,
                borderWidth = 1, borderColor = style.border,
                flexDirection = "row", gap = 8, alignItems = "flex-start",
                children = {
                    UI.Label { text = icon, fontSize = 18, flexShrink = 0, marginTop = 1 },
                    UI.Label {
                        text = text, fontSize = 13, fontColor = C.text,
                        whiteSpace = "normal", lineHeight = 1.45, flex = 1,
                    },
                },
            })
        end
    end

    -- 判断是否有叙事条目，调整标题和按钮风格
    local hasNarrative = false
    for _, item in ipairs(pendingTomorrowPreview_) do
        if type(item) == "table" and item.narrative then hasNarrative = true; break end
    end
    local titleIcon = hasNarrative and "🌙" or "🔮"
    local titleText = hasNarrative and "夜深了……" or "明日预告"
    local btnText   = hasNarrative and "关灯，睡了 💤" or "好的，明天见！✨"

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 16,
        onClick = function()
            pendingTomorrowPreview_ = nil; BuildUI()
        end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, padding = 20, gap = 14,
                backgroundColor = C.card,
                borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    -- 标题行
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center",
                        justifyContent = "center", gap = 10,
                        children = {
                            UI.Label { text = titleIcon, fontSize = 30 },
                            UI.Panel { gap = 2, alignItems = "center", children = {
                                UI.Label { text = titleText, fontSize = 18,
                                    fontColor = { 160, 200, 255, 255 }, fontWeight = "bold" },
                                UI.Label { text = "点击任意位置关闭", fontSize = 11,
                                    fontColor = { 120, 120, 120, 180 } },
                            }},
                        },
                    },
                    -- 分割线
                    UI.Panel { width = "100%", height = 1,
                        backgroundColor = { 80, 100, 160, 80 } },
                    -- 预告条目
                    UI.Panel { width = "100%", gap = 8, children = previewItems },
                    -- 按钮
                    UI.Button {
                        text = btnText, width = "100%", height = 44,
                        fontSize = 15, fontWeight = "bold",
                        backgroundColor = hasNarrative and { 40, 50, 100, 240 } or { 60, 90, 160, 240 },
                        borderRadius = 12,
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
-- 门口闲聊弹窗（轻量叙事氛围）
-- ============================================================================
function BuildDoorstepChatPopup()
    if not pendingDoorstepChat_ then return nil end
    if currentPhase_ ~= PHASE_MANAGE then return nil end

    local chat = pendingDoorstepChat_
    local char = chat.character or { name = "路人", emoji = "👤", desc = "" }
    local reward = chat.reward

    -- 关闭并领取奖励
    local function dismiss()
        if reward then
            pcall(DoorstepChat.ClaimReward, reward)
        end
        pendingDoorstepChat_ = nil
        BuildUI()
    end

    -- 奖励提示
    local rewardLine = nil
    if reward then
        rewardLine = UI.Panel {
            width = "100%", borderRadius = 8, padding = 10,
            backgroundColor = { 40, 60, 40, 220 },
            borderWidth = 1, borderColor = { 80, 180, 80, 150 },
            flexDirection = "row", gap = 8, alignItems = "center",
            children = {
                UI.Label { text = "🎁", fontSize = 16, flexShrink = 0 },
                UI.Label {
                    text = reward.msg or "获得了小奖励", fontSize = 12,
                    fontColor = { 140, 230, 140, 255 },
                    whiteSpace = "normal", flex = 1,
                },
            },
        }
    end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 20,
        onClick = dismiss,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 360, padding = 18, gap = 12,
                backgroundColor = C.card,
                borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    -- 角色头像+名字
                    UI.Panel {
                        width = "100%", flexDirection = "row", gap = 10, alignItems = "center",
                        children = {
                            UI.Panel {
                                width = 44, height = 44, borderRadius = PX.cardRadius,
                                backgroundColor = C.cardAlt,
                                borderWidth = PX.borderSm, borderColor = C.gold,
                                justifyContent = "center", alignItems = "center",
                                children = {
                                    UI.Label { text = char.emoji, fontSize = 22 },
                                },
                            },
                            UI.Panel { gap = 2, flex = 1, children = {
                                UI.Label { text = char.name, fontSize = 14,
                                    fontColor = C.gold, fontWeight = "bold" },
                                UI.Label { text = char.desc, fontSize = 11,
                                    fontColor = C.textDim },
                            }},
                            UI.Label { text = "☀️", fontSize = 20, flexShrink = 0 },
                        },
                    },
                    -- 分割线
                    UI.Panel { width = "100%", height = 1,
                        backgroundColor = { 100, 80, 50, 80 } },
                    -- 对话气泡
                    UI.Panel {
                        width = "100%", borderRadius = PX.radiusSm, padding = 14,
                        backgroundColor = C.cardAlt,
                        borderWidth = PX.borderSm, borderColor = C.border,
                        children = {
                            UI.Label {
                                text = "\"" .. chat.line .. "\"",
                                fontSize = 14, fontColor = C.text,
                                whiteSpace = "normal", lineHeight = 1.6,
                            },
                        },
                    },
                    -- 奖励（如果有）
                    rewardLine,
                    -- 关闭按钮
                    UI.Button {
                        text = reward and "谢了！收下 👋" or "哈哈，走了 👋",
                        width = "100%", height = 40,
                        fontSize = 14,
                        backgroundColor = C.accent,
                        borderRadius = PX.cardRadius,
                        onClick = dismiss,
                    },
                    -- 提示
                    UI.Label { text = "点击任意位置关闭", fontSize = 10,
                        fontColor = { 120, 100, 80, 150 } },
                },
            },
        },
    }
end

-- ============================================================================
-- P0-B 今日任务清单弹窗（每日进场汇总）
-- ============================================================================
function BuildDayStartSummaryPopup()
    if not pendingDayStartSummary_ then return nil end
    -- 仅在管理界面展示
    if currentPhase_ ~= PHASE_MANAGE then return nil end

    local s = pendingDayStartSummary_

    -- 关闭函数
    local function dismiss()
        pendingDayStartSummary_ = nil
        BuildUI()
    end

    -- ── 委托卡片 ──
    local questCard = nil
    if s.quest then
        local streakBadge = nil
        if (s.streak or 0) >= 1 then
            streakBadge = UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 4,
                backgroundColor = { 180, 120, 20, 200 }, borderRadius = 10,
                paddingHorizontal = 8, paddingVertical = 3,
                children = {
                    UI.Label { text = "🔥", fontSize = 12 },
                    UI.Label { text = "连击 x" .. s.streak, fontSize = 11,
                        fontColor = { 255, 220, 100, 255 }, fontWeight = "bold" },
                },
            }
        end
        questCard = UI.Panel {
            width = "100%", padding = 12, borderRadius = 10, gap = 6,
            backgroundColor = { 30, 42, 55, 240 },
            borderWidth = 1, borderColor = { 60, 120, 200, 150 },
            children = {
                -- 标题行
                UI.Panel {
                    flexDirection = "row", alignItems = "center",
                    justifyContent = "space-between", width = "100%",
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = "📋", fontSize = 16 },
                            UI.Label { text = "今日委托", fontSize = 13, fontColor = { 120, 180, 255, 255 },
                                fontWeight = "bold" },
                        }},
                        streakBadge or UI.Panel { width = 0, height = 0 },
                    },
                },
                UI.Label {
                    text = s.quest.icon .. " " .. s.quest.desc,
                    fontSize = 13, fontColor = C.text, whiteSpace = "normal",
                },
                UI.Label {
                    text = "奖励：" .. s.quest.reward,
                    fontSize = 12, fontColor = { 200, 170, 80, 255 },
                },
            },
        }
    end

    -- ── 目标链卡片 ──
    local goalCard = nil
    if s.goal then
        local pctW = math.max(4, math.min(100, s.goal.pct))
        goalCard = UI.Panel {
            width = "100%", padding = 12, borderRadius = 10, gap = 6,
            backgroundColor = { 35, 50, 30, 240 },
            borderWidth = 1, borderColor = { 80, 160, 60, 150 },
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                    UI.Label { text = "🎯", fontSize = 16 },
                    UI.Label { text = "目标链 · " .. s.goal.chain,
                        fontSize = 13, fontColor = { 140, 220, 100, 255 }, fontWeight = "bold" },
                    UI.Label { text = "(" .. s.goal.stepNum .. "/" .. s.goal.totalSteps .. ")",
                        fontSize = 11, fontColor = { 140, 140, 140, 200 } },
                }},
                UI.Label {
                    text = "下一步：" .. s.goal.desc,
                    fontSize = 13, fontColor = C.text, whiteSpace = "normal",
                },
                -- 进度条
                UI.Panel {
                    width = "100%", height = 5, borderRadius = 3,
                    backgroundColor = { 40, 40, 40, 200 },
                    children = {
                        UI.Panel {
                            width = pctW .. "%", height = "100%", borderRadius = 3,
                            backgroundColor = { 100, 200, 80, 255 },
                        },
                    },
                },
            },
        }
    end

    -- ── 今日特别行动卡片 ──
    local eventCard = nil
    if s.event then
        eventCard = UI.Panel {
            width = "100%", padding = 10, borderRadius = 10,
            backgroundColor = { 50, 38, 20, 230 },
            borderWidth = 1, borderColor = { 200, 160, 60, 140 },
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = s.event.icon, fontSize = 20, flexShrink = 0 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "今日特别行动：" .. s.event.title,
                        fontSize = 13, fontColor = { 255, 200, 80, 255 }, fontWeight = "bold" },
                    UI.Label { text = s.event.desc, fontSize = 12,
                        fontColor = { 200, 185, 160, 220 }, whiteSpace = "normal" },
                }},
            },
        }
    end

    -- ── 队员心情警告 ──
    local moodWarn = nil
    if s.teamWarn then
        moodWarn = UI.Panel {
            width = "100%", padding = 10, borderRadius = 10,
            backgroundColor = { 60, 25, 25, 220 },
            borderWidth = 1, borderColor = { 200, 60, 60, 140 },
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = "😞", fontSize = 18, flexShrink = 0 },
                UI.Label {
                    text = "队员心情偏低：" .. s.teamWarn .. "\n记得照顾一下他们！",
                    fontSize = 12, fontColor = { 240, 160, 160, 255 },
                    whiteSpace = "normal", flex = 1,
                },
            },
        }
    end

    -- ── P1: 队员每日一言 ──
    local greetingCard = nil
    local greetOk, DailyGreeting = pcall(require, "DailyGreeting")
    if greetOk and DailyGreeting and DailyGreeting.Generate then
        local greeting = DailyGreeting.Generate()
        if greeting then
            -- C2: 缓存到 playerData_ 供状态栏持续展示
            playerData_.todayGreeting = { speaker = greeting.speaker, emoji = greeting.emoji, text = greeting.text, moodCat = greeting.moodCat }
            local moodColor = greeting.moodCat == "happy" and { 100, 220, 140, 255 }
                or greeting.moodCat == "low" and { 220, 140, 100, 255 }
                or { 180, 180, 180, 255 }
            greetingCard = UI.Panel {
                width = "100%", padding = 14, borderRadius = 12, gap = 8,
                backgroundColor = { 28, 35, 45, 240 },
                borderWidth = 1, borderColor = { 100, 140, 180, 120 },
                alignItems = "center",
                children = {
                    UI.Label { text = greeting.emoji, fontSize = 28 },
                    UI.Label {
                        text = "\"" .. greeting.text .. "\"",
                        fontSize = 14, fontColor = C.text, textAlign = "center",
                        whiteSpace = "normal", fontStyle = "italic",
                    },
                    UI.Label {
                        text = "── " .. greeting.speaker,
                        fontSize = 12, fontColor = moodColor, textAlign = "right",
                        width = "100%",
                    },
                },
            }
        end
    end

    -- 组装所有卡片（过滤 nil）
    local cards = {}
    if greetingCard then table.insert(cards, greetingCard) end
    -- questCard 已移除（今日委托功能暂停）
    if goalCard   then table.insert(cards, goalCard)   end
    if eventCard  then table.insert(cards, eventCard)  end
    if moodWarn   then table.insert(cards, moodWarn)   end

    -- 如果没有任何内容就不弹
    if #cards == 0 then
        pendingDayStartSummary_ = nil
        return nil
    end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 16,
        onClick = dismiss,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, padding = 18, gap = 14,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    -- 标题
                    UI.Panel {
                        width = "100%", flexDirection = "row",
                        alignItems = "center", justifyContent = "center", gap = 10,
                        children = {
                            UI.Label { text = "☀️", fontSize = 28 },
                            UI.Panel { gap = 2, alignItems = "center", children = {
                                UI.Label {
                                    text = "第 " .. s.day .. " 天  任务清单",
                                    fontSize = 17, fontColor = { 200, 240, 180, 255 }, fontWeight = "bold",
                                },
                                UI.Label { text = "今天要做什么，一目了然", fontSize = 11,
                                    fontColor = { 120, 140, 100, 200 } },
                            }},
                        },
                    },
                    -- 分割线
                    UI.Panel { width = "100%", height = 1,
                        backgroundColor = { 80, 120, 60, 80 } },
                    -- 卡片列表
                    UI.Panel { width = "100%", gap = 8, children = cards },
                    -- 开始按钮
                    UI.Button {
                        text = "明白了，开始今天！🚀", width = "100%", height = 44,
                        fontSize = 15, fontWeight = "bold",
                        backgroundColor = C.accent, borderRadius = PX.cardRadius,
                        onClick = dismiss,
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- P2-A 成就解锁通知弹窗（每次最多弹出首个未展示成就）
-- ============================================================================
function BuildAchievementUnlockPopup()
    if not pendingAchievements_ or #pendingAchievements_ == 0 then return nil end
    if currentPhase_ ~= PHASE_MANAGE then return nil end

    -- 每次只展示队列里第一条
    local ach = pendingAchievements_[1]

    local function dismiss()
        table.remove(pendingAchievements_, 1)
        if #pendingAchievements_ == 0 then pendingAchievements_ = nil end
        BuildUI()
    end

    -- 奖励描述
    local rewardParts = {}
    if ach.reward then
        if (ach.reward.money or 0) > 0 then
            table.insert(rewardParts, "$" .. ach.reward.money)
        end
        if (ach.reward.rep or 0) > 0 then
            table.insert(rewardParts, "声望 +" .. ach.reward.rep)
        end
        if (ach.reward.karma or 0) > 0 then
            table.insert(rewardParts, "道义 +" .. ach.reward.karma)
        end
    end
    local rewardText = #rewardParts > 0 and ("奖励：" .. table.concat(rewardParts, " · ")) or nil

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 24,
        onClick = dismiss,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 340,
                padding = 20, gap = 14,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    -- 标题行
                    UI.Label { text = "🏅 成就解锁！", fontSize = 16,
                        fontColor = C.gold, fontWeight = "bold" },
                    -- 图标大字
                    UI.Label { text = ach.icon, fontSize = 48 },
                    -- 成就标题
                    UI.Label {
                        text = ach.title,
                        fontSize = 18, fontColor = C.text,
                        fontWeight = "bold", textAlign = "center",
                    },
                    -- 成就描述
                    UI.Label {
                        text = ach.desc,
                        fontSize = 13, fontColor = C.textDim,
                        whiteSpace = "normal", textAlign = "center",
                    },
                    -- 奖励行
                    rewardText and UI.Panel {
                        paddingHorizontal = 10, paddingVertical = 5,
                        backgroundColor = C.cardAlt, borderRadius = PX.radiusSm,
                        children = {
                            UI.Label { text = rewardText, fontSize = 12,
                                fontColor = C.gold, textAlign = "center" },
                        },
                    } or UI.Panel { width = 0, height = 0 },
                    -- 分割线
                    UI.Panel { width = "80%", height = 1, backgroundColor = { C.border[1], C.border[2], C.border[3], 80 } },
                    -- 确认按钮
                    UI.Button {
                        text = "太棒了！继续", width = "100%", height = 40,
                        fontSize = 14, fontWeight = "bold",
                        backgroundColor = C.accent, borderRadius = PX.cardRadius,
                        onClick = dismiss,
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

