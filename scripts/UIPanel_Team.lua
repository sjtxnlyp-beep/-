---@diagnostic disable: undefined-global
function BuildTeamCard()
    local children = {
        PanelHeader("战队 (" .. #teamMembers_ .. "/5)", { icon = nil, compact = true }),
    }
    if #teamMembers_ == 0 then
        table.insert(children, UI.Label { text = "还没有队员\n经营网吧时会有人来找你", fontSize = 13, fontColor = C.textDim, whiteSpace = "normal" })
    end
    for i, m in ipairs(teamMembers_) do
        -- 心情颜色：红(<40) 黄(40-70) 绿(>70)
        local moodColor = m.mood > 70 and C.green or (m.mood >= 40 and C.gold or C.red)
        local moodIcon = m.mood > 70 and "😊" or (m.mood >= 40 and "😐" or "😞")
        -- 技能进度百分比
        local skillPct = math.floor(math.min(SKILL_CAP, m.skill) / SKILL_CAP * 100)

        table.insert(children, UI.Panel {
            flexDirection = "row", alignItems = "center", width = "100%", gap = 6,
            padding = 5, backgroundColor = C.cardAlt, borderRadius = PX.radius,
            children = {
                m.avatar and UI.Panel {
                    width = 36, height = 36, borderRadius = 18,
                    backgroundImage = m.avatar, backgroundFit = "cover",
                    borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                } or UI.Label { text = m.emoji, fontSize = 18 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = m.name .. " · " .. m.trait, fontSize = 13, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = "天" .. m.talent, fontSize = 13, fontColor = C.gold },
                        UI.Label { text = moodIcon .. m.mood, fontSize = 13, fontColor = moodColor },
                    }},
                    -- 技能进度条
                    UI.Panel { flexDirection = "row", gap = 4, alignItems = "center", width = "100%", children = {
                        UI.Label { text = "技" .. m.skill, fontSize = 13, fontColor = C.green },
                        UI.Panel { flex = 1, height = 4, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = PX.radiusSm, overflow = "hidden", children = {
                            UI.Panel { width = skillPct .. "%", height = "100%", backgroundColor = C.green, borderRadius = PX.radiusSm },
                        }},
                    }},
                    -- 特质标签
                    m.perk and UI.Panel { flexDirection = "row", gap = 4, alignItems = "center", children = {
                        UI.Label { text = "✦" .. m.perk, fontSize = 11,
                            fontColor = m.mood >= 70 and C.green or C.textDim },
                        m.flaw and UI.Label { text = "✧" .. m.flaw, fontSize = 11,
                            fontColor = m.mood < 40 and C.red or C.textDim } or nil,
                    }} or nil,
                }},
                UI.Panel { gap = 4, alignItems = "center", children = {
                    UI.Button { text = "练", minHeight = 32, paddingHorizontal = 10, fontSize = 13,
                        fontColor = playerData_.actionPoints <= 0 and C.textDim or nil,
                        onClick = function()
                            if playerData_.actionPoints <= 0 then
                                trainNoAPIdx_ = i
                                BuildUI()
                            else
                                StartTransition("特训时间", m.name .. " · " .. m.trait, function()
                                    StartTraining(i)
                                end)
                            end
                        end },
                    UI.Button { text = dismissConfirmIdx_ == i and "确认？" or "解雇", minHeight = 26,
                        paddingHorizontal = 8, fontSize = 11,
                        fontColor = dismissConfirmIdx_ == i and C.red or C.textDim,
                        variant = "ghost",
                        onClick = function()
                            if dismissConfirmIdx_ == i then
                                dismissConfirmIdx_ = nil
                                DismissMember(i)
                            else
                                dismissConfirmIdx_ = i
                                BuildUI()
                            end
                        end },
                }},
            },
        })
        -- 无AP提示面板（点击"练"时AP不足触发）
        if trainNoAPIdx_ == i then
            local noAPChildren = {
                UI.Label { text = "⚡ 需要1点行动力才能训练", fontSize = 13, fontColor = C.gold },
            }
            if AdManager.CanWatch("extra_ap", playerData_.day) then
                table.insert(noAPChildren, AdManager.AdButton {
                    sceneId = "extra_ap", day = playerData_.day,
                    text = "看视频获得 +1 行动力",
                    width = "100%", height = 36, fontSize = 12,
                    onReward = function()
                        playerData_.actionPoints = playerData_.actionPoints + 1
                        AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                        trainNoAPIdx_ = nil
                        BuildUI()
                    end,
                })
            end
            table.insert(noAPChildren, UI.Button {
                text = "知道了", variant = "ghost", fontSize = 11, height = 28,
                fontColor = C.textDim,
                onClick = function()
                    trainNoAPIdx_ = nil
                    BuildUI()
                end,
            })
            table.insert(children, UI.Panel {
                width = "100%", padding = 8, gap = 6,
                backgroundColor = { 60, 45, 15, 255 }, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { 180, 140, 40, 150 },
                alignItems = "center",
                children = noAPChildren,
            })
        end
    end
    -- 广告：团队看电影提振心情（平均心情<90时出现）
    if #teamMembers_ > 0 then
        local totalMood = 0
        for _, m in ipairs(teamMembers_) do totalMood = totalMood + m.mood end
        local avgMood = totalMood / #teamMembers_
        if avgMood < 90 and AdManager.CanWatch("mood_boost", playerData_.day) then
            table.insert(children, AdManager.AdButton {
                sceneId = "mood_boost", day = playerData_.day,
                text = "看广告请队员看电影 心情+15", width = "100%", height = 38, fontSize = 12,
                onReward = function()
                    for _, m in ipairs(teamMembers_) do
                        m.mood = math.min(100, m.mood + 15)
                    end
                    AddLog("🎬 赞助商赠送电影票！全队一起看了大片，心情大好！所有队员心情+15")
                    BuildUI()
                end,
            })
        end
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 5,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = children,
    }
end

function BuildEventLog()
    if #eventLog_ == 0 then return UI.Panel {} end
    -- 只展示最新2条，保持紧凑
    local items = {}
    for i = #eventLog_, math.max(1, #eventLog_ - 1), -1 do
        local txt = eventLog_[i]
        if type(txt) ~= "string" then txt = tostring(txt or "") end
        -- 每条记录前加图标前缀（如果没有的话）
        if not txt:match("^[%p%s]*[\u{1F300}-\u{1FAFF}]") and not txt:match("^第") then
            txt = "📌 " .. txt
        end
        table.insert(items, UI.Label {
            text = txt, fontSize = 13, fontColor = C.textDim,
            whiteSpace = "normal", lineHeight = 1.5,
        })
    end

    local logChildren = {
        UI.Panel {
            flexDirection = "row", alignItems = "center", justifyContent = "space-between", width = "100%",
            children = {
                PanelHeader("最近动态", { icon = nil, compact = true, color = C.accentDim }),
                #eventLog_ > 2 and UI.Label {
                    text = "共" .. #eventLog_ .. "条",
                    fontSize = 14, fontColor = C.textDim,
                } or nil,
            },
        },
    }
    for _, item in ipairs(items) do
        table.insert(logChildren, item)
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = logChildren,
    }
end

