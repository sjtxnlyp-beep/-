---@diagnostic disable: undefined-global
-- ============================================================================
-- 15b. 训练界面（也用于踢馆的 playing 阶段）
-- ============================================================================

--- 训练完成时显示是否刷新个人记录
local function TrainRecordBadge()
    if not replayTrainMode_ then return UI.Panel { height = 0 } end
    local rec = playerData_ and playerData_.trainRecords or {}
    local isNew = false
    if trainMode_ == "aim" then
        isNew = (trainScore_ or 0) > (rec.aim and rec.aim.score or 0)
    elseif trainMode_ == "quiz" then
        isNew = (quizCorrect_ or 0) > (rec.quiz and rec.quiz.correct or 0)
    elseif trainMode_ == "react" then
        isNew = (reactCorrect_ or 0) > (rec.react and rec.react.correct or 0)
    elseif trainMode_ == "memory" then
        isNew = (routeCorrect_ or 0) > (rec.memory and rec.memory.correct or 0)
    elseif trainMode_ == "comm" then
        isNew = (commCorrect_ or 0) > (rec.comm and rec.comm.correct or 0)
    end
    if isNew then
        return UI.Panel {
            paddingHorizontal = 12, paddingVertical = 4, borderRadius = 12,
            backgroundColor = { 200, 155, 40, 220 },
            children = { UI.Label { text = "🏆 NEW RECORD!", fontSize = 13, fontWeight = "bold",
                fontColor = { 40, 20, 0, 255 } } },
        }
    else
        return UI.Label { text = "💪 训练场模式", fontSize = 11, fontColor = C.textDim }
    end
end

---@param fromChallenge boolean|nil 踢馆调用时传true避免递归
function BuildTrainUI(fromChallenge)
    -- 踢馆模式下，非 playing 阶段由踢馆 UI 接管
    if challengeActive_ and not fromChallenge then
        return BuildChallengeRoundUI()
    end

    if not trainMember_ then
        if challengeActive_ then
            -- 踢馆中不能跳走，用占位成员兜底
            trainMember_ = { name = "选手", emoji = "🎮", trait = "踢馆中", skill = 50, mood = 70 }
        else
            currentPhase_ = PHASE_MANAGE
            return BuildManageUI()
        end
    end
    local m = trainMember_
    local modeLabels = { aim = "枪线校准", quiz = "赛后复盘", memory = "路线规划", react = "节奏反应", comm = "指挥通讯" }
    local modeLabel = modeLabels[trainMode_] or "选择训练"

    local headerChildren = {
        UI.Label { text = m.emoji .. " " .. m.name .. " " .. modeLabel, fontSize = 18, fontColor = C.gold },
        UI.Label { text = "「" .. m.trait .. "」 技术:" .. m.skill, fontSize = 14, fontColor = C.textDim },
    }

    local bodyChildren = {}

    -- P2-2: 心情影响提示组件（ready阶段复用）
    local moodReadyHint = nil
    do
        local mood = m.mood or 50
        local moodText, moodColor, moodBg
        if mood >= 80 then
            moodText = "😊 心情极佳 +" .. mood .. " · 训练收益 +20%"
            moodColor = { 80, 200, 120, 255 }
            moodBg   = { 40, 100, 60, 140 }
        elseif mood >= 60 then
            moodText = "🙂 心情良好 " .. mood .. " · 训练收益 +5%"
            moodColor = { 160, 210, 100, 255 }
            moodBg   = { 60, 90, 40, 120 }
        elseif mood < 30 then
            local failPct = math.floor((30 - mood) / 60 * 100)
            moodText = "😞 心情低落 " .. mood .. " · " .. failPct .. "%几率收益-70%！"
            moodColor = { 220, 80, 80, 255 }
            moodBg   = { 100, 30, 30, 140 }
        elseif mood < 50 then
            moodText = "😐 心情偏低 " .. mood .. " · 训练收益 -15%"
            moodColor = { 220, 160, 60, 255 }
            moodBg   = { 90, 70, 20, 120 }
        else
            moodText = "😐 心情普通 " .. mood .. " · 训练正常发挥"
            moodColor = C.textDim
            moodBg   = { 50, 50, 60, 100 }
        end
        moodReadyHint = UI.Panel {
            width = "88%", padding = 8, borderRadius = 8,
            backgroundColor = moodBg,
            children = {
                UI.Label { text = moodText, fontSize = 12, fontColor = moodColor, textAlign = "center" },
            },
        }
    end

    -- ======== 踢馆模式 done 阶段：简化结算界面 ========
    if challengeActive_ and trainPhase_ == "done" then
        local scoreVal = 0
        local scoreLabel = "得分"
        if trainMode_ == "aim" then scoreVal = trainScore_ or 0; scoreLabel = "命中数"
        elseif trainMode_ == "quiz" then scoreVal = quizCorrect_ or 0; scoreLabel = "正确数"
        elseif trainMode_ == "memory" then scoreVal = routeCorrect_ or 0; scoreLabel = "正确路线"
        elseif trainMode_ == "react" then scoreVal = reactCorrect_ or 0; scoreLabel = "命中数"
        elseif trainMode_ == "comm" then scoreVal = commCorrect_ or 0; scoreLabel = "正确识别"
        end
        bodyChildren = {
            UI.Panel { height = 24 },
            UI.Label { text = "⚔️ 比拼结束", fontSize = 20, fontColor = C.gold, fontWeight = "bold" },
            UI.Panel { height = 12 },
            UI.Label { text = (CHALLENGE_MODE_EMOJIS or {})[trainMode_] or "", fontSize = 40 },
            UI.Panel { height = 8 },
            UI.Label { text = (CHALLENGE_MODE_LABELS or {})[trainMode_] or trainMode_, fontSize = 16, fontColor = C.accent },
            UI.Panel { height = 16 },
            UI.Panel {
                width = "70%", padding = 12, backgroundColor = C.cardAlt, borderRadius = 10,
                alignItems = "center", gap = 4,
                children = {
                    UI.Label { text = scoreLabel, fontSize = 13, fontColor = C.textDim },
                    UI.Label { text = tostring(scoreVal), fontSize = 28, fontColor = C.green, fontWeight = "bold" },
                },
            },
            UI.Panel { height = 20 },
            UI.Button { text = "查看对比结果", width = 200, minHeight = 44, fontSize = 15, variant = "primary",
                onClick = function() FinishTraining() end },
        }
        return UI.Panel {
            width = "100%", height = "100%", padding = 8, gap = 4,
            backgroundColor = { 20, 25, 30, 252 },
            children = {
                UI.Panel { width = "100%", alignItems = "center", gap = 2, children = headerChildren },
                UI.Panel { width = "100%", flex = 1, justifyContent = "center", alignItems = "center", children = bodyChildren },
            },
        }
    end

    -- ======== 模式选择界面 ========
    if trainMode_ == "select" then
        -- 训练项定义
        local trainItems = {
            { id = "aim",    icon = "🎯", name = "枪线校准", tag = "手速",  desc = "追击移动靶标",   color = { 255, 100, 60, 255 } },
            { id = "quiz",   icon = "🧠", name = "赛后复盘", tag = "智力",  desc = "战术情境问答",   color = { 100, 180, 255, 255 } },
            { id = "memory", icon = "🗺️", name = "路线规划", tag = "记忆",  desc = "记忆并还原路径", color = { 255, 200, 60, 255 } },
            { id = "react",  icon = "⚡", name = "节奏反应", tag = "反应",  desc = "精准时机点击",   color = { 255, 80, 120, 255 } },
            { id = "comm",   icon = "📡", name = "指挥通讯", tag = "识别",  desc = "信息流快速筛选", color = { 160, 120, 255, 255 } },
        }
        local cards = {}
        for i, item in ipairs(trainItems) do
            local c = item.color
            table.insert(cards, UI.Panel {
                width = "48%", alignItems = "center",
                paddingVertical = 14, paddingHorizontal = 8,
                backgroundColor = { c[1], c[2], c[3], 18 },
                borderRadius = 12,
                borderWidth = 1, borderColor = { c[1], c[2], c[3], 60 },
                pointerEvents = "auto",
                onClick = function()
                    PlaySFX("click")
                    if item.id == "quiz" then
                        local sk = trainMember_ and trainMember_.skill or 0
                        quizTotal_ = sk >= 70 and 8 or sk >= 40 and 6 or 5
                    end
                    trainMode_ = item.id; trainPhase_ = "ready"; BuildUI()
                end,
                children = {
                    -- 顶部：圆形图标
                    UI.Panel {
                        width = 42, height = 42, borderRadius = 21,
                        backgroundColor = { c[1], c[2], c[3], 35 },
                        justifyContent = "center", alignItems = "center",
                        children = { UI.Label { text = item.icon, fontSize = 20 } },
                    },
                    -- 名称
                    UI.Label { text = item.name, fontSize = 14, fontColor = C.text, fontWeight = "bold", marginTop = 8 },
                    -- 描述
                    UI.Label { text = item.desc, fontSize = 10, fontColor = C.textDim, marginTop = 2 },
                    -- 标签
                    UI.Panel {
                        paddingHorizontal = 8, paddingVertical = 3, marginTop = 6,
                        backgroundColor = { c[1], c[2], c[3], 50 },
                        borderRadius = 8,
                        children = { UI.Label { text = item.tag, fontSize = 10, fontColor = c } },
                    },
                },
            })
        end

        bodyChildren = {
            UI.Panel { height = 8 },
            UI.Label { text = "⚔ 训练课程", fontSize = 17, fontColor = C.gold, fontWeight = "bold" },
            UI.Panel { height = 2 },
            UI.Label { text = "选择科目提升选手能力", fontSize = 12, fontColor = C.textDim },
            UI.Panel { height = 12 },
            -- 2列网格布局
            UI.Panel { width = "95%", flexDirection = "row", flexWrap = "wrap", justifyContent = "space-between", gap = 10, children = cards },
        }

    -- ======== 枪线校准模式 ========
    elseif trainMode_ == "aim" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "枪线校准", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "靶标在格子中移动出现\n连击越多，目标移动越快！\n时间 " .. TRAIN_DURATION .. " 秒",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                moodReadyHint,
                UI.Panel { height = 8 },
                UI.Button { text = "🎯 开始校准", width = 180, minHeight = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        trainPhase_ = "playing"
                        trainActive_ = true
                        trainTimer_ = 0
                        trainScore_ = 0
                        trainCombo_ = 0
                        trainMaxCombo_ = 0
                        trainActiveCell_ = 0
                        trainTargetTimer_ = 0
                        trainTargetTimeout_ = math.max(0.7, 1.4 - m.skill * 0.006)
                        SpawnTrainTarget()
                        BuildUI()
                    end,
                },
            }
        elseif trainPhase_ == "playing" then
            local timeLeft = math.max(0, TRAIN_DURATION - trainTimer_)
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", paddingHorizontal = 8,
                children = {
                    UI.Label { id = "trainTimerLabel", text = string.format("⏱ %.1f", timeLeft), fontSize = 16,
                        fontColor = timeLeft < 3 and C.red or C.text },
                    UI.Label { id = "trainScoreLabel", text = "" .. trainScore_, fontSize = 16, fontColor = C.green },
                    UI.Label { id = "trainComboLabel", text = "x" .. trainCombo_, fontSize = 16,
                        fontColor = trainCombo_ >= 3 and C.gold or C.textDim },
                },
            })
            table.insert(bodyChildren, UI.Panel { height = 8 })

            local gridRows = {}
            for row = 1, TRAIN_GRID_ROWS do
                local rowCells = {}
                for col = 1, TRAIN_GRID_COLS do
                    local idx = (row - 1) * TRAIN_GRID_COLS + col
                    local isActive = (idx == trainActiveCell_)
                    table.insert(rowCells, UI.Panel {
                        id = "tcell_" .. idx,
                        width = 64, height = 64,
                        backgroundColor = isActive and C.target or C.cellIdle,
                        borderRadius = 12,
                        borderWidth = isActive and 3 or 1,
                        borderColor = isActive and C.targetGlow or C.border,
                        justifyContent = "center", alignItems = "center",
                        pointerEvents = "auto",
                        transition = "backgroundColor 0.12s easeOut",
                        onClick = function() OnTrainCellClick(idx) end,
                        children = {
                            UI.Label { id = "tcellIcon_" .. idx, text = isActive and "靶" or "", fontSize = 28 },
                        },
                    })
                end
                table.insert(gridRows, UI.Panel {
                    flexDirection = "row", gap = 8, justifyContent = "center",
                    children = rowCells,
                })
            end
            table.insert(bodyChildren, UI.Panel { gap = 8, alignItems = "center", children = gridRows })

        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local rating = trainScore_ >= 15 and "S" or trainScore_ >= 10 and "A" or trainScore_ >= 6 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "训练结束！", fontSize = 20, fontColor = C.text },
                TrainRecordBadge(),
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("命中数", tostring(trainScore_), C.green),
                InfoRow("最大连击", tostring(trainMaxCombo_), C.gold),
                not replayTrainMode_ and InfoRow("技术提升", "+" .. gain, C.blue) or UI.Panel { height = 0 },
                UI.Panel { height = 16 },
                (not replayTrainMode_ and AdManager.CanWatch("train_bonus", playerData_.day)) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "视频加练 技术再+" .. gain, width = "85%", minHeight = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Panel { height = 12 },
                UI.Button { text = "完成", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 赛后复盘模式 ========
    elseif trainMode_ == "quiz" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "🧠 赛后复盘", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "回答" .. quizTotal_ .. "道情境判断题\n模拟比赛中的关键决策瞬间",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                moodReadyHint,
                UI.Panel { height = 8 },
                UI.Button { text = "🧠 开始复盘", width = 180, minHeight = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        ShuffleQuizQuestions(quizTotal_)
                        trainPhase_ = "playing"
                        BuildUI()
                    end,
                },
            }
        elseif trainPhase_ == "playing" and quizIdx_ <= #quizQuestions_ then
            local qData = quizQuestions_[quizIdx_]
            local progress = quizIdx_ .. "/" .. #quizQuestions_
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", paddingHorizontal = 4,
                children = {
                    UI.Label { text = "" .. progress, fontSize = 14, fontColor = C.accent },
                    UI.Label { text = "" .. quizCorrect_ .. " 正确", fontSize = 14, fontColor = C.green },
                },
            })
            table.insert(bodyChildren, UI.Panel { height = 8 })
            table.insert(bodyChildren, UI.Label {
                text = qData.q, fontSize = 14, fontColor = C.text,
                whiteSpace = "normal", lineHeight = 1.4, textAlign = "center",
            })
            table.insert(bodyChildren, UI.Panel { height = 10 })
            -- 选项按钮
            for i, opt in ipairs(qData.opts) do
                local optLabel = ({ "A", "B", "C", "D" })[i]
                local bgColor = C.cellIdle
                local borderCol = C.border
                local textCol = C.text
                if quizAnswered_ then
                    if i == qData.ans then
                        bgColor = { 220, 245, 220, 235 }
                        borderCol = C.green
                        textCol = C.green
                    elseif i == quizSelectedOpt_ and i ~= qData.ans then
                        bgColor = { 255, 240, 240, 235 }
                        borderCol = C.red
                        textCol = C.red
                    end
                end
                table.insert(bodyChildren, UI.Panel {
                    width = "95%", padding = { 10, 12 }, borderRadius = 10,
                    backgroundColor = bgColor, borderWidth = 1, borderColor = borderCol,
                    flexDirection = "row", gap = 8, alignItems = "center",
                    pointerEvents = quizAnswered_ and "none" or "auto",
                    onClick = function()
                        if quizAnswered_ then return end
                        quizAnswered_ = true
                        quizSelectedOpt_ = i
                        if i == qData.ans then
                            quizCorrect_ = quizCorrect_ + 1
                            PlaySFX("train_hit")
                        else
                            PlaySFX("miss")
                        end
                        BuildUI()
                    end,
                    children = {
                        UI.Label { text = optLabel .. ".", fontSize = 14, fontColor = textCol },
                        UI.Label { text = opt, fontSize = 13, fontColor = textCol, whiteSpace = "normal", flex = 1, flexShrink = 1 },
                    },
                })
            end
            -- 答完后显示下一题按钮
            if quizAnswered_ then
                table.insert(bodyChildren, UI.Panel { height = 10 })
                local isLast = quizIdx_ >= #quizQuestions_
                table.insert(bodyChildren, UI.Button {
                    text = isLast and "查看结果" or "下一题",
                    width = 160, minHeight = 38, fontSize = 14, variant = "primary",
                    onClick = function()
                        PlaySFX("click")
                        if isLast then
                            trainPhase_ = "done"
                        else
                            quizIdx_ = quizIdx_ + 1
                            quizAnswered_ = false
                            quizSelectedOpt_ = 0
                        end
                        BuildUI()
                    end,
                })
            end
        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local pct = quizTotal_ > 0 and math.floor(quizCorrect_ / quizTotal_ * 100) or 0
            local rating = pct >= 100 and "S" or pct >= 80 and "A" or pct >= 60 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "复盘结束！", fontSize = 20, fontColor = C.text },
                TrainRecordBadge(),
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("正确率", quizCorrect_ .. "/" .. quizTotal_ .. " (" .. pct .. "%)", C.green),
                not replayTrainMode_ and InfoRow("战术理解", "+" .. gain, C.blue) or UI.Panel { height = 0 },
                UI.Panel { height = 4 },
                UI.Label { text = pct >= 80 and "" .. m.name .. "对战术理解大幅提升！"
                    or pct >= 60 and "📖 " .. m.name .. "学到了不少战术知识"
                    or "😅 " .. m.name .. "还需要更多学习...",
                    fontSize = 14, fontColor = C.textDim, whiteSpace = "normal", textAlign = "center" },
                UI.Panel { height = 16 },
                (not replayTrainMode_ and AdManager.CanWatch("train_bonus", playerData_.day)) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "视频加练 技术再+" .. gain, width = "85%", minHeight = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Panel { height = 12 },
                UI.Button { text = "完成", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 节奏反应模式 ========
    elseif trainMode_ == "react" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "节奏反应", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "屏幕出现方向指令，快速点击对应按钮！\n共" .. reactTotal_ .. "轮，难度逐步提升：\n加速→反向→闪现，越快分越高！",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                moodReadyHint,
                UI.Panel { height = 8 },
                UI.Button { text = "开始训练", width = 180, minHeight = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        reactRound_ = 0; reactCorrect_ = 0; reactTotalTime_ = 0
                        trainActive_ = true; trainTimer_ = 0
                        trainPhase_ = "playing"
                        StartReactRound()
                    end,
                },
            }
        elseif trainPhase_ == "playing" then
            local progress = reactRound_ .. "/" .. reactTotal_
            -- 难度阶段标签
            local diffLabel, diffColor
            if reactRound_ <= 3 then diffLabel = "入门"; diffColor = C.green
            elseif reactRound_ <= 5 then diffLabel = "加速"; diffColor = C.blue
            elseif reactRound_ <= 7 then diffLabel = "反向"; diffColor = C.gold
            else diffLabel = "极限"; diffColor = C.red end
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", alignItems = "center", paddingHorizontal = 4,
                children = {
                    UI.Label { text = "" .. progress, fontSize = 14, fontColor = C.accent },
                    UI.Panel {
                        paddingHorizontal = 8, paddingVertical = 2, borderRadius = 8,
                        backgroundColor = { diffColor[1], diffColor[2], diffColor[3], 60 },
                        children = { UI.Label { text = diffLabel, fontSize = 12, fontColor = diffColor } },
                    },
                    UI.Label { text = "" .. reactCorrect_, fontSize = 14, fontColor = C.green },
                },
            })
            -- 反向模式提示
            if reactReverse_ then
                table.insert(bodyChildren, UI.Panel {
                    width = "100%", padding = 4, marginTop = 2,
                    backgroundColor = { 248, 252, 248, 200 }, borderRadius = 6, alignItems = "center",
                    children = { UI.Label { text = "反向模式：按相反方向！", fontSize = 13, fontColor = C.gold } },
                })
            end
            table.insert(bodyChildren, UI.Panel { height = 8 })

            if reactPhaseState_ == "wait" then
                table.insert(bodyChildren, UI.Panel {
                    width = 120, height = 120, borderRadius = 60,
                    backgroundColor = { 50, 55, 50, 220 }, justifyContent = "center", alignItems = "center",
                    borderWidth = 2, borderColor = C.textDim,
                    children = { UI.Label { text = "准备…", fontSize = 20, fontColor = C.textDim } },
                })
            elseif reactPhaseState_ == "show" then
                local dirIcons = { up = "↑", down = "↓", left = "←", right = "→" }
                local dirNames = { up = "上", down = "下", left = "左", right = "右" }
                -- 闪现模式：方向短暂显示后变成"?"
                local showDir = (not reactFlash_) or (reactFlashTimer_ < 0.4)
                table.insert(bodyChildren, UI.Panel {
                    id = "reactDirPanel",
                    width = 120, height = 120, borderRadius = 60,
                    backgroundColor = showDir and { 65, 25, 25, 240 } or { 30, 50, 35, 240 },
                    justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = showDir and C.red or C.accent,
                    boxShadow = { { x = 0, y = 0, blur = 20, color = showDir and { 210, 80, 60, 100 } or { 200, 150, 50, 100 } } },
                    children = {
                        UI.Label { id = "reactDirIcon", text = showDir and (dirIcons[reactDirection_] or "?") or "?", fontSize = 48 },
                        UI.Label { id = "reactDirHint", text = showDir and (reactReverse_ and "按反向！" or (dirNames[reactDirection_] or "")) or "记住方向！",
                            fontSize = 13, fontColor = showDir and (reactReverse_ and C.gold or C.text) or C.accent },
                    },
                })
                table.insert(bodyChildren, UI.Panel { height = 6 })
                table.insert(bodyChildren, UI.Label { id = "reactTimerLabel",
                    text = string.format("%.1fs", math.max(0, reactTimeLimit_ - reactTimer_)),
                    fontSize = 14, fontColor = C.red })
                table.insert(bodyChildren, UI.Panel { height = 8 })
                -- 方向按钮
                local dirs = { "up", "left", "right", "down" }
                local dIcons = { up = "↑", left = "←", right = "→", down = "↓" }
                table.insert(bodyChildren, UI.Panel {
                    alignItems = "center", gap = 4,
                    children = {
                        UI.Panel { -- 上按钮
                            width = 64, height = 48, borderRadius = 10, backgroundColor = { 240, 245, 240, 230 },
                            justifyContent = "center", alignItems = "center", pointerEvents = "auto",
                            onClick = function() OnReactAnswer("up") end,
                            children = { UI.Label { text = "↑", fontSize = 24 } },
                        },
                        UI.Panel { flexDirection = "row", gap = 4, children = {
                            UI.Panel {
                                width = 64, height = 48, borderRadius = 10, backgroundColor = { 240, 245, 240, 230 },
                                justifyContent = "center", alignItems = "center", pointerEvents = "auto",
                                onClick = function() OnReactAnswer("left") end,
                                children = { UI.Label { text = "←", fontSize = 24 } },
                            },
                            UI.Panel {
                                width = 64, height = 48, borderRadius = 10, backgroundColor = { 240, 245, 240, 230 },
                                justifyContent = "center", alignItems = "center", pointerEvents = "auto",
                                onClick = function() OnReactAnswer("right") end,
                                children = { UI.Label { text = "→", fontSize = 24 } },
                            },
                        }},
                        UI.Panel {
                            width = 64, height = 48, borderRadius = 10, backgroundColor = { 240, 245, 240, 230 },
                            justifyContent = "center", alignItems = "center", pointerEvents = "auto",
                            onClick = function() OnReactAnswer("down") end,
                            children = { UI.Label { text = "↓", fontSize = 24 } },
                        },
                    },
                })
            elseif reactPhaseState_ == "result" then
                local expectedDir = reactReverse_ and REACT_OPPOSITE[reactDirection_] or reactDirection_
                local wasCorrect = reactAnswered_ and (expectedDir == reactAnswered_)
                table.insert(bodyChildren, UI.Panel {
                    width = 120, height = 120, borderRadius = 60,
                    backgroundColor = wasCorrect and { 30, 60, 30, 230 } or { 65, 25, 25, 230 },
                    justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = wasCorrect and C.green or C.red,
                    children = {
                        UI.Label { text = wasCorrect and "✓" or "✗", fontSize = 48, fontColor = wasCorrect and C.green or C.red },
                    },
                })
                table.insert(bodyChildren, UI.Panel { height = 4 })
                table.insert(bodyChildren, UI.Label {
                    text = wasCorrect and ("反应时间: " .. string.format("%.2fs", reactTimer_)) or "超时或方向错误！",
                    fontSize = 13, fontColor = wasCorrect and C.green or C.red,
                })
            end

        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local avgTime = reactCorrect_ > 0 and (reactTotalTime_ / reactCorrect_) or 99
            local rating = reactCorrect_ >= 9 and "S" or reactCorrect_ >= 7 and "A" or reactCorrect_ >= 4 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "节奏反应结束！", fontSize = 20, fontColor = C.text },
                TrainRecordBadge(),
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("正确次数", reactCorrect_ .. "/" .. reactTotal_, C.green),
                InfoRow("平均反应", string.format("%.2fs", avgTime), C.gold),
                not replayTrainMode_ and InfoRow("技术提升", "+" .. gain, C.blue) or UI.Panel { height = 0 },
                UI.Panel { height = 16 },
                (not replayTrainMode_ and AdManager.CanWatch("train_bonus", playerData_.day)) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "视频加练 技术再+" .. gain, width = "85%", minHeight = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Panel { height = 12 },
                UI.Button { text = "完成", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 路线规划模式 ========
    elseif trainMode_ == "memory" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "🗺 路线规划", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "地图上会显示一条行进路线\n记住路径后按顺序点击格子还原！\n每轮通过后路径变长，共" .. routeTotalRounds_ .. "轮",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                moodReadyHint,
                UI.Panel { height = 8 },
                UI.Button { text = "🗺 开始规划", width = 180, minHeight = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        routeRound_ = 0; routeCorrect_ = 0; routeLen_ = 4
                        trainActive_ = true; trainTimer_ = 0
                        StartRouteRound()
                        BuildUI()
                    end,
                },
            }
        elseif trainPhase_ == "playing" then
            local progress = routeRound_ .. "/" .. routeTotalRounds_
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", paddingHorizontal = 4,
                children = {
                    UI.Label { text = "🗺 第" .. progress .. "轮", fontSize = 14, fontColor = C.accent },
                    UI.Label { text = "" .. routeCorrect_ .. " 通过", fontSize = 14, fontColor = C.green },
                    UI.Label { text = "路径: " .. routeLen_ .. "步", fontSize = 14, fontColor = { 180, 180, 100, 255 } },
                },
            })
            table.insert(bodyChildren, UI.Panel { height = 8 })

            -- 构建5×5网格
            local gridSize = ROUTE_GRID
            local cellSize = 48
            local gridRows = {}
            for row = 1, gridSize do
                local rowCells = {}
                for col = 1, gridSize do
                    local idx = (row - 1) * gridSize + col
                    -- 判断格子状态
                    local isOnPath = false
                    local pathOrder = 0
                    for pi, pidx in ipairs(routePath_) do
                        if pidx == idx then isOnPath = true; pathOrder = pi; break end
                    end
                    local isShown = routePhaseState_ == "show" and isOnPath and pathOrder <= routeShowIdx_
                    local isPlayerPicked = false
                    for _, pidx in ipairs(routePlayerPath_) do
                        if pidx == idx then isPlayerPicked = true; break end
                    end

                    local bgColor = C.cellIdle
                    local borderCol = C.border
                    local cellText = ""
                    local textColor = C.text

                    if routePhaseState_ == "show" then
                        if isShown then
                            bgColor = { 180, 200, 80, 200 }
                            borderCol = { 180, 180, 100, 255 }
                            cellText = tostring(pathOrder)
                            textColor = { 40, 60, 20, 255 }
                        end
                    elseif routePhaseState_ == "input" then
                        if isPlayerPicked then
                            bgColor = { 100, 160, 220, 180 }
                            borderCol = C.blue
                            -- 显示玩家输入的顺序
                            for ppi, ppidx in ipairs(routePlayerPath_) do
                                if ppidx == idx then cellText = tostring(ppi); break end
                            end
                            textColor = { 255, 255, 255, 255 }
                        end
                    elseif routePhaseState_ == "result" then
                        if isOnPath then
                            local playerPicked = false
                            local playerOrder = 0
                            for ppi, ppidx in ipairs(routePlayerPath_) do
                                if ppidx == idx then playerPicked = true; playerOrder = ppi; break end
                            end
                            if playerPicked and playerOrder == pathOrder then
                                bgColor = { 30, 60, 30, 230 }
                                borderCol = C.green
                            else
                                bgColor = { 65, 25, 25, 230 }
                                borderCol = C.red
                            end
                            cellText = tostring(pathOrder)
                            textColor = { 255, 255, 255, 255 }
                        end
                    end

                    table.insert(rowCells, UI.Panel {
                        width = cellSize, height = cellSize, borderRadius = 8,
                        backgroundColor = bgColor,
                        borderWidth = 1, borderColor = borderCol,
                        justifyContent = "center", alignItems = "center",
                        pointerEvents = routePhaseState_ == "input" and "auto" or "none",
                        onClick = function() OnRouteInput(idx) end,
                        children = {
                            UI.Label { text = cellText, fontSize = 14, fontColor = textColor },
                        },
                    })
                end
                table.insert(gridRows, UI.Panel {
                    flexDirection = "row", gap = 4, justifyContent = "center",
                    children = rowCells,
                })
            end

            if routePhaseState_ == "show" then
                table.insert(bodyChildren, UI.Label { text = "记住路线！", fontSize = 14, fontColor = C.gold })
            elseif routePhaseState_ == "input" then
                table.insert(bodyChildren, UI.Label {
                    text = "按顺序点击还原路线 (" .. #routePlayerPath_ .. "/" .. #routePath_ .. ")",
                    fontSize = 14, fontColor = { 180, 180, 100, 255 },
                })
            elseif routePhaseState_ == "result" then
                local allOk = #routePlayerPath_ == #routePath_
                if allOk then
                    for i = 1, #routePath_ do
                        if routePlayerPath_[i] ~= routePath_[i] then allOk = false; break end
                    end
                end
                table.insert(bodyChildren, UI.Label {
                    text = allOk and "✓ 路线完美还原！" or "✗ 路线有误",
                    fontSize = 16, fontColor = allOk and C.green or C.red,
                })
            end
            table.insert(bodyChildren, UI.Panel { height = 6 })
            table.insert(bodyChildren, UI.Panel { gap = 4, alignItems = "center", children = gridRows })

        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local rating = routeCorrect_ >= 5 and "S" or routeCorrect_ >= 4 and "A" or routeCorrect_ >= 2 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "路线规划结束！", fontSize = 20, fontColor = C.text },
                TrainRecordBadge(),
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("通过轮数", routeCorrect_ .. "/" .. routeTotalRounds_, C.green),
                InfoRow("最终路径", tostring(routeLen_) .. "步", { 180, 180, 100, 255 }),
                not replayTrainMode_ and InfoRow("技术提升", "+" .. gain, C.blue) or UI.Panel { height = 0 },
                UI.Panel { height = 16 },
                (not replayTrainMode_ and AdManager.CanWatch("train_bonus", playerData_.day)) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "视频加练 技术再+" .. gain, width = "85%", minHeight = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Panel { height = 12 },
                UI.Button { text = "完成", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 指挥通讯模式 ========
    elseif trainMode_ == "comm" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "📡 指挥通讯", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "信息流中会混入大量干扰消息\n快速找到并点击关键情报！\n每轮速度递增，共" .. commTotalRounds_ .. "轮",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                moodReadyHint,
                UI.Panel { height = 8 },
                UI.Button { text = "📡 开始监听", width = 180, minHeight = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        commRound_ = 0; commCorrect_ = 0; commSpeed_ = 1.0
                        trainActive_ = true; trainTimer_ = 0
                        StartCommRound()
                        BuildUI()
                    end,
                },
            }
        elseif trainPhase_ == "playing" then
            local progress = commRound_ .. "/" .. commTotalRounds_
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", paddingHorizontal = 4,
                children = {
                    UI.Label { text = "📡 " .. progress, fontSize = 14, fontColor = C.accent },
                    UI.Label { text = "" .. commCorrect_, fontSize = 14, fontColor = C.green },
                    UI.Label { text = "速度: x" .. string.format("%.1f", commSpeed_), fontSize = 14, fontColor = { 140, 100, 220, 255 } },
                },
            })
            table.insert(bodyChildren, UI.Panel { height = 6 })

            if commPhaseState_ == "wait" then
                table.insert(bodyChildren, UI.Panel {
                    width = "90%", padding = 16, borderRadius = 12,
                    backgroundColor = { 40, 30, 60, 200 }, alignItems = "center", gap = 8,
                    children = {
                        UI.Label { text = "准备接收情报...", fontSize = 16, fontColor = { 140, 100, 220, 255 } },
                        UI.Label { text = "找到高亮的关键消息并点击！", fontSize = 12, fontColor = C.textDim },
                    },
                })
            elseif commPhaseState_ == "scroll" then
                -- 滚动消息列表
                local msgChildren = {}
                for i, msg in ipairs(commMessages_) do
                    local isTarget = msg.isTarget
                    local bgCol = isTarget and { 140, 100, 220, 40 } or { 50, 55, 60, 180 }
                    local borderC = isTarget and { 140, 100, 220, 200 } or { 70, 75, 80, 150 }
                    local fColor = isTarget and { 200, 160, 255, 255 } or C.textDim
                    table.insert(msgChildren, UI.Button {
                        width = "100%", paddingVertical = 8, paddingHorizontal = 10, borderRadius = 8,
                        backgroundColor = bgCol,
                        borderWidth = isTarget and 2 or 1, borderColor = borderC,
                        text = msg.text, fontSize = 12, fontColor = fColor,
                        textAlign = "left",
                        onClick = function() OnCommMessageClick(msg.id) end,
                    })
                end
                table.insert(bodyChildren, UI.ScrollView {
                    width = "95%", height = 240, borderRadius = 10,
                    backgroundColor = { 25, 20, 35, 220 },
                    borderWidth = 1, borderColor = { 80, 60, 120, 200 },
                    padding = 6,
                    children = {
                        UI.Panel { width = "100%", gap = 4, children = msgChildren },
                    },
                })
                table.insert(bodyChildren, UI.Panel { height = 4 })
                table.insert(bodyChildren, UI.Label {
                    text = commAnswered_ and "已选择！" or "⚡ 点击高亮情报!",
                    fontSize = 13, fontColor = commAnswered_ and C.green or { 200, 160, 255, 255 },
                })
            elseif commPhaseState_ == "result" then
                local wasCorrect = commAnswered_ and not commMissed_
                table.insert(bodyChildren, UI.Panel {
                    width = 100, height = 100, borderRadius = 50,
                    backgroundColor = wasCorrect and { 30, 60, 30, 230 } or { 65, 25, 25, 230 },
                    justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = wasCorrect and C.green or C.red,
                    children = {
                        UI.Label { text = wasCorrect and "✓" or "✗", fontSize = 42, fontColor = wasCorrect and C.green or C.red },
                    },
                })
                table.insert(bodyChildren, UI.Panel { height = 4 })
                table.insert(bodyChildren, UI.Label {
                    text = wasCorrect and "情报截获成功！" or (commMissed_ and "情报已流失..." or "选错目标！"),
                    fontSize = 14, fontColor = wasCorrect and C.green or C.red,
                })
            end

        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local rating = commCorrect_ >= 7 and "S" or commCorrect_ >= 5 and "A" or commCorrect_ >= 3 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "指挥通讯结束！", fontSize = 20, fontColor = C.text },
                TrainRecordBadge(),
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("截获情报", commCorrect_ .. "/" .. commTotalRounds_, C.green),
                InfoRow("最终速度", "x" .. string.format("%.1f", commSpeed_), { 140, 100, 220, 255 }),
                not replayTrainMode_ and InfoRow("技术提升", "+" .. gain, C.blue) or UI.Panel { height = 0 },
                UI.Panel { height = 16 },
                (not replayTrainMode_ and AdManager.CanWatch("train_bonus", playerData_.day)) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "视频加练 技术再+" .. gain, width = "85%", minHeight = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Panel { height = 12 },
                UI.Button { text = "完成", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.training,
        backgroundFit = "cover",
        alignItems = "center", gap = 8,
        paddingTop = 16, paddingBottom = 8,
        children = {
            UI.Panel {
                width = "92%", maxWidth = 400, padding = { 16, 12 }, gap = 6,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 1, borderColor = C.border,
                alignItems = "center", flexShrink = 0,
                children = {
                    table.unpack(headerChildren),
                },
            },
            UI.ScrollView {
                width = "92%", maxWidth = 400, flex = 1, flexBasis = 0,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 1, borderColor = C.border,
                children = {
                    UI.Panel {
                        width = "100%", padding = 16,
                        alignItems = "center",
                        children = bodyChildren,
                    },
                },
            },
            UI.Button { text = challengeActive_ and "⚔️ 踢馆进行中..." or "← 返回网吧",
                minHeight = 36, paddingHorizontal = 16, fontSize = 13,
                flexShrink = 0,
                disabled = challengeActive_,
                onClick = function()
                    trainMember_ = nil; trainActive_ = false; trainPhase_ = "ready"
                    PlayBGM("manage")
                    currentPhase_ = PHASE_MANAGE; BuildUI()
                end },
        },
    }
end

