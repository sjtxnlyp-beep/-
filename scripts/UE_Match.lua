---@diagnostic disable: undefined-global
-- ============================================================================
-- 16. 比赛界面（带背景图）
-- ============================================================================
function BuildMatchUI()
    local tier = currentMatchTier_ or 1
    local tierCfg = MATCH_TIERS[tier]
    local tierName = tierCfg and tierCfg.name or "⚔️ 友谊赛"
    local tournamentCfg = (not isFriendlyMatch_ and currentTournamentTier_ > 0) and TOURNAMENT_TIERS[currentTournamentTier_] or nil
    local matchTitle = isFriendlyMatch_ and tierName or (tournamentCfg and tournamentCfg.name or "锦标赛")
    local titleColor = isFriendlyMatch_ and C.accent or (currentTournamentTier_ >= 4 and C.red or C.gold)
    local children = {
        UI.Label { text = matchTitle, fontSize = 20, fontColor = titleColor,
            textShadow = { offsetX = 0, offsetY = 2, blur = 8, color = { 200, 160, 80, 80 } } },
    }

    -- 比分条
    if matchPhase_ ~= "intro" then
        local losses = matchRound_ - matchWins_
        local scoreText = "战绩: " .. matchWins_ .. "胜 " .. losses .. "负 · 第" .. matchRound_ .. "/" .. #matchOpponents_ .. "场"
        table.insert(children, UI.Label { text = scoreText, fontSize = 13, fontColor = C.accent })
    end

    if matchPhase_ == "intro" then
        -- 赛前阵容展示
        table.insert(children, UI.Panel { height = 8 })
        if isFriendlyMatch_ and friendlyOpponent_ then
            local tierDesc = tier > 1 and (tierName .. " · 奖励×" .. (tierCfg and tierCfg.rewardMult or 1)) or "检验训练成果"
            local eliteTag = friendlyOpponent_.isElite and "强敌挑战" or tierDesc
            local eliteColor = friendlyOpponent_.isElite and C.red or C.textDim
            table.insert(children, UI.Label { text = "Dragon Force vs " .. (friendlyOpponent_.name or "???"), fontSize = 14, fontColor = C.text })
            table.insert(children, UI.Label { text = eliteTag, fontSize = 13, fontColor = eliteColor })
        else
            table.insert(children, UI.Label { text = "Dragon Force vs 全非洲强队", fontSize = 14, fontColor = C.text })
            table.insert(children, UI.Label { text = "单败淘汰 · 四场锦标赛", fontSize = 13, fontColor = C.textDim })
        end
        table.insert(children, UI.Panel { height = 6 })
        for _, m in ipairs(teamMembers_) do
            table.insert(children, UI.Panel {
                flexDirection = "row", gap = 6, alignItems = "center", width = "80%",
                padding = 6, backgroundColor = C.cardAlt, borderRadius = 8,
                children = {
                    UI.Label { text = m.emoji, fontSize = 16 },
                    UI.Label { text = m.name, fontSize = 14, fontColor = C.text },
                    UI.Panel { flex = 1 },
                    UI.Label { text = "技" .. m.skill .. " 天" .. m.talent, fontSize = 14, fontColor = C.textDim },
                },
            })
        end
        table.insert(children, UI.Panel { height = 4 })
        table.insert(children, UI.Label { text = "综合评分: " .. GetTeamPower(), fontSize = 16, fontColor = C.green })
        table.insert(children, UI.Panel { height = 4 })
        -- 对手一览
        if not isFriendlyMatch_ then
            table.insert(children, UI.Label { text = "── 对阵表 ──", fontSize = 14, fontColor = C.textDim })
            for i, opp in ipairs(matchOpponents_) do
                table.insert(children, UI.Label {
                    text = "第" .. i .. "场: " .. opp.emoji .. " " .. opp.name .. " (" .. opp.style .. ")",
                    fontSize = 13, fontColor = C.text,
                })
            end
        else
            table.insert(children, UI.Panel {
                width = "85%", padding = 10, gap = 4,
                backgroundColor = friendlyOpponent_.isElite and { 65, 25, 25, 230 } or C.cardAlt,
                borderRadius = 10, borderWidth = friendlyOpponent_.isElite and 1 or 0,
                borderColor = friendlyOpponent_.isElite and C.red or C.border,
                children = {
                    UI.Label { text = friendlyOpponent_.emoji .. " " .. friendlyOpponent_.name, fontSize = 14, fontColor = friendlyOpponent_.isElite and C.red or C.accent },
                    UI.Label { text = friendlyOpponent_.flavor or "", fontSize = 14, fontColor = C.textDim, whiteSpace = "normal" },
                    UI.Panel { flexDirection = "row", gap = 10, children = {
                        UI.Label { text = "风格: " .. friendlyOpponent_.style, fontSize = 14, fontColor = C.text },
                        UI.Label { text = "实力: " .. friendlyOpponent_.power, fontSize = 14, fontColor = friendlyOpponent_.isElite and C.red or C.green },
                    }},
                    UI.Label { text = "你的战绩: " .. playerData_.friendlyWins .. "胜 " .. playerData_.friendlyLosses .. "负", fontSize = 14, fontColor = C.gold },
                },
            })
        end
        table.insert(children, UI.Panel { height = 8 })
        -- 广告：赛前战力加成
        if AdManager.CanWatch("match_power_up", playerData_.day) then
            table.insert(children, AdManager.AdButton {
                sceneId = "match_power_up", day = playerData_.day,
                text = "视频赛前强化 战力+15%",
                width = "85%", height = 40, fontSize = 12,
                onReward = function()
                    midDecisionBonus_ = (midDecisionBonus_ or 0) + math.floor(GetTeamPower() * 0.15)
                    AddLog("🎬 赞助商赠送了能量补给！全队状态拉满，战力+15%！")
                    BuildUI()
                end,
            })
        end
        -- P1-5: 出发前先进入战术选择阶段
        table.insert(children, UI.Button { text = "⚔️ 选择战术出发！", width = "85%", minHeight = 44, fontSize = 16, variant = "primary",
            onClick = function()
                PlaySFX("click")
                matchLog_ = {}; matchWins_ = 0; matchRound_ = 1
                matchPhase_ = "tactic"
                BuildUI()
            end })

    elseif matchPhase_ == "interlude" then
        -- 赛间互动事件（第2轮+触发）
        local ilu = matchInterlude_
        if ilu then
            table.insert(children, UI.Panel { height = 8 })
            table.insert(children, UI.Label { text = (ilu.icon or "🔔") .. " " .. ilu.title, fontSize = 16, fontColor = C.gold, textAlign = "center" })
            table.insert(children, UI.Panel { height = 6 })
            table.insert(children, UI.Panel {
                width = "90%", padding = 12, borderRadius = 8,
                backgroundColor = C.cardAlt, borderWidth = 1, borderColor = C.border,
                children = {
                    UI.Label { text = ilu.desc, fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, width = "100%" },
                },
            })
            table.insert(children, UI.Panel { height = 10 })
            table.insert(children, UI.Label { text = "你的选择：", fontSize = 14, fontColor = C.accent })
            table.insert(children, UI.Panel { height = 4 })
            for ci, c in ipairs(ilu.choices) do
                local riskTag = c.risk and "  ⚠️高风险" or ""
                table.insert(children, UI.Button {
                    text = c.text .. riskTag, width = "88%", minHeight = 40, fontSize = 12,
                    variant = c.risk and "danger" or "secondary",
                    onClick = function()
                        PlaySFX("click")
                        if c.risk then
                            local avgSkill = 0
                            for _, m in ipairs(teamMembers_) do avgSkill = avgSkill + m.skill end
                            avgSkill = #teamMembers_ > 0 and (avgSkill / #teamMembers_) or 30
                            local chance = math.min(0.80, 0.40 + avgSkill / 200)
                            if math.random() < chance then
                                midDecisionBonus_ = (midDecisionBonus_ or 0) + c.bonus
                                AddLog("" .. ilu.title .. "成功！战力+" .. c.bonus)
                                matchInterlude_ = { resultText = c.narrative_win or c.narrative, success = true, bonus = c.bonus }
                            else
                                local penalty = math.floor(c.bonus * 0.5)
                                midDecisionBonus_ = (midDecisionBonus_ or 0) - penalty
                                AddLog("😵 " .. ilu.title .. "失败！战力-" .. penalty)
                                matchInterlude_ = { resultText = c.narrative_fail or "事与愿违……", success = false, bonus = -penalty }
                            end
                        else
                            midDecisionBonus_ = (midDecisionBonus_ or 0) + c.bonus
                            AddLog("" .. ilu.title .. "：战力+" .. c.bonus)
                            matchInterlude_ = { resultText = c.narrative, success = true, bonus = c.bonus }
                        end
                        matchPhase_ = "interlude_result"
                        BuildUI()
                    end,
                })
                table.insert(children, UI.Panel { height = 3 })
            end
        else
            matchPhase_ = "tactic"
            BuildUI()
        end

    elseif matchPhase_ == "interlude_result" then
        -- 赛间互动结果展示
        local ir = matchInterlude_
        if ir and ir.resultText then
            local isGood = ir.success
            table.insert(children, UI.Panel { height = 10 })
            table.insert(children, UI.Panel {
                width = "88%", padding = 14, borderRadius = 8,
                backgroundColor = isGood and { 30, 60, 30, 230 } or { 65, 25, 25, 230 },
                borderWidth = 1, borderColor = isGood and C.green or C.red,
                children = {
                    UI.Label { text = "互动结果", fontSize = 15, fontColor = isGood and C.green or C.red },
                    UI.Panel { height = 4 },
                    UI.Label { text = ir.resultText, fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, width = "100%" },
                    UI.Panel { height = 4 },
                    UI.Label { text = "战力影响: " .. (ir.bonus >= 0 and "+" or "") .. ir.bonus, fontSize = 14, fontColor = isGood and C.green or C.red },
                },
            })
            table.insert(children, UI.Panel { height = 12 })
            table.insert(children, UI.Button {
                text = "⚔️ 进入战术选择", width = 180, height = 42, fontSize = 14, variant = "primary",
                onClick = function()
                    PlaySFX("click")
                    matchInterlude_ = nil
                    matchPhase_ = "tactic"
                    BuildUI()
                end,
            })
        else
            matchPhase_ = "tactic"
            BuildUI()
        end

    elseif matchPhase_ == "tactic" then
        -- 战术选择界面
        local opp = matchOpponents_[matchRound_]
        if not opp then
            log:Write(LOG_ERROR, "[BuildMatchUI] tactic: opp nil, round=" .. tostring(matchRound_) .. " #opps=" .. tostring(#matchOpponents_))
            table.insert(children, UI.Label { text = "⚠️ 对手数据异常，请返回", fontSize = 14, fontColor = C.red })
            table.insert(children, UI.Button { text = "返回管理", width = "60%", minHeight = 38, fontSize = 14, onClick = function()
                currentPhase_ = PHASE_MANAGE; matchPhase_ = "intro"; BuildUI()
            end })
            return UI.Panel { width = "100%", padding = 10, gap = 6, children = children }
        end
        table.insert(children, UI.Panel { height = 8 })
        table.insert(children, UI.Label { text = "── 第" .. matchRound_ .. "场 ──", fontSize = 16, fontColor = C.text })
        table.insert(children, UI.Label { text = "对手: " .. opp.emoji .. " " .. opp.name, fontSize = 14, fontColor = C.accent })
        table.insert(children, UI.Label { text = "对手风格: " .. opp.style, fontSize = 14, fontColor = C.textDim })

        -- 战术侦查
        local scouted = scoutedRound_ == matchRound_
        if scouted then
            local bestTactic = opp.style == "快攻型" and "🛡️防守" or (opp.style == "防守反击" and "🔥猛攻" or "⚖️均衡")
            table.insert(children, UI.Panel {
                width = "80%", padding = 6, backgroundColor = { 30, 55, 30, 200 }, borderRadius = 6,
                children = {
                    UI.Label { text = "侦查报告: 建议使用「" .. bestTactic .. "」战术", fontSize = 13, fontColor = C.green },
                },
            })
        elseif playerData_.money >= 50 then
            table.insert(children, UI.Button {
                text = "侦查对手 ($50)", width = "60%", height = 36, fontSize = 13,
                onClick = function()
                    playerData_.money = playerData_.money - 50
                    scoutedRound_ = matchRound_
                    PlaySFX("click")
                    BuildUI()
                end,
            })
        end

        table.insert(children, UI.Panel { height = 10 })
        table.insert(children, UI.Label { text = "🎯 选择本场战术", fontSize = 15, fontWeight = "bold", fontColor = C.gold })
        table.insert(children, UI.Panel { height = 6 })

        -- 克制关系说明
        local oppStyle = opp.style
        local COUNTER_MAP = {
            ["快攻型"]   = { best = "defensive",  worst = "aggressive" },
            ["防守反击"] = { best = "aggressive",  worst = "defensive"  },
            ["均衡型"]   = { best = "balanced",    worst = nil          },
        }
        local counterInfo = COUNTER_MAP[oppStyle] or {}

        local tactics = {
            { key = "aggressive", icon = "🔥", name = "冲锋流", desc = "全力进攻，克制防守反击\n被快攻型克制", powerMod = "+20 vs 防守反击" },
            { key = "balanced",   icon = "⚖️", name = "稳健流", desc = "攻守均衡，无明显弱点\n稳定 +5 战力加成", powerMod = "+5 稳定" },
            { key = "defensive",  icon = "🛡️", name = "针对研究", desc = "稳守反击，克制快攻型\n被防守反击克制", powerMod = "+20 vs 快攻型" },
        }
        for _, t in ipairs(tactics) do
            local isSelected = matchTactic_ == t.key
            local isBest = counterInfo.best == t.key
            local isWorst = counterInfo.worst == t.key
            local bgColor = isSelected and { 60, 120, 80, 200 }
                         or isBest and { 40, 80, 50, 150 }
                         or isWorst and { 80, 30, 30, 120 }
                         or { 45, 45, 55, 160 }
            local borderColor = isSelected and { 100, 220, 130, 200 }
                             or isBest and { 80, 180, 100, 150 }
                             or isWorst and { 200, 80, 80, 150 }
                             or { 80, 80, 100, 100 }
            local tag = isBest and "  ✅克制" or (isWorst and "  ❌被克" or "")
            table.insert(children, UI.Panel {
                width = "88%", padding = 10, borderRadius = 8,
                backgroundColor = bgColor,
                borderWidth = isSelected and 2 or 1, borderColor = borderColor,
                gap = 3,
                onClick = function()
                    PlaySFX("click")
                    matchTactic_ = t.key; BuildUI()
                end,
                children = {
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, children = {
                        UI.Label { text = t.icon, fontSize = 18 },
                        UI.Label { text = t.name .. tag, fontSize = 14, fontWeight = "bold",
                            fontColor = isSelected and { 180, 255, 200, 255 } or { 220, 220, 220, 220 } },
                        UI.Panel { flex = 1 },
                        isSelected and UI.Label { text = "✓ 已选", fontSize = 11, fontColor = { 100, 220, 130, 255 } } or nil,
                    }},
                    UI.Label { text = t.desc, fontSize = 11, fontColor = { 180, 190, 180, 200 },
                        whiteSpace = "normal", width = "100%" },
                    UI.Label { text = "战力加成: " .. t.powerMod, fontSize = 11,
                        fontColor = isBest and { 100, 220, 130, 220 } or { 160, 160, 180, 180 } },
                },
            })
            table.insert(children, UI.Panel { height = 4 })
        end
        table.insert(children, UI.Panel { height = 8 })
        table.insert(children, UI.Button { text = "⚔️ 开战！", width = 160, minHeight = 42, fontSize = 15, variant = "primary",
            onClick = function()
                PlaySFX("gunshot")
                -- 随机触发中局决策（90%概率，让玩家更有参与感）
                if math.random() < 0.9 then
                    -- 按当前比赛游戏类型过滤可用决策场景
                    local style = matchGameType_ and matchGameType_.narrativeStyle or "tactical"
                    local filtered = {}
                    for _, d in ipairs(MID_DECISION_POOL) do
                        if d.tags == "all" or string.find(d.tags, style, 1, true) then
                            filtered[#filtered + 1] = d
                        end
                    end
                    if #filtered == 0 then filtered = MID_DECISION_POOL end
                    midDecision_ = filtered[math.random(1, #filtered)]
                    midDecisionBonus_ = 0
                    matchPhase_ = "mid_decision"
                    BuildUI()
                else
                    midDecision_ = nil
                    midDecisionBonus_ = 0
                    RunMatchRound()
                end
            end })

    elseif matchPhase_ == "mid_decision" then
        -- 中局突发情境决策
        table.insert(children, UI.Panel { height = 6 })
        table.insert(children, UI.Label { text = "比赛中突发情况！", fontSize = 16, fontColor = C.gold, textAlign = "center" })
        table.insert(children, UI.Panel { height = 6 })
        if midDecision_ then
            table.insert(children, UI.Panel {
                width = "90%", padding = 12, borderRadius = 8,
                backgroundColor = C.cardAlt, borderWidth = 1, borderColor = C.border,
                children = {
                    UI.Label { text = midDecision_.situation, fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, width = "100%" },
                },
            })
            table.insert(children, UI.Panel { height = 10 })
            table.insert(children, UI.Label { text = "你的决定：", fontSize = 14, fontColor = C.accent })
            table.insert(children, UI.Panel { height = 4 })
            for ci, choice in ipairs(midDecision_.choices) do
                local riskTag = choice.risk and "  ⚠️高风险" or ""
                local bonusColor = choice.bonus > 0 and C.green or (choice.bonus < 0 and C.red or C.textDim)
                local bonusText = choice.bonus > 0 and ("+" .. choice.bonus) or tostring(choice.bonus)
                table.insert(children, UI.Button {
                    text = choice.text .. riskTag, width = "88%", minHeight = 40, fontSize = 12,
                    variant = choice.risk and "danger" or "secondary",
                    onClick = function()
                        PlaySFX("click")
                        ResolveMidDecision(ci)
                    end,
                })
                table.insert(children, UI.Label {
                    text = choice.desc .. " (战力" .. bonusText .. ")",
                    fontSize = 12, fontColor = bonusColor, width = "85%", textAlign = "center", whiteSpace = "normal",
                })
                table.insert(children, UI.Panel { height = 3 })
            end
        end

    elseif matchPhase_ == "mid_decision_result" then
        -- 中局决策结果展示
        table.insert(children, UI.Panel { height = 10 })
        if midDecisionNarrative_ then
            local isGood = midDecisionBonus_ >= 0
            table.insert(children, UI.Panel {
                width = "88%", padding = 14, borderRadius = 8,
                backgroundColor = isGood and { 30, 60, 30, 230 } or { 65, 25, 25, 230 },
                borderWidth = 1, borderColor = isGood and C.green or C.red,
                children = {
                    UI.Label { text = "决策结果", fontSize = 15, fontColor = isGood and C.green or C.red },
                    UI.Panel { height = 6 },
                    UI.Label { text = midDecisionNarrative_, fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, width = "100%" },
                    UI.Panel { height = 6 },
                    UI.Label {
                        text = "战力修正: " .. (midDecisionBonus_ >= 0 and "+" or "") .. midDecisionBonus_,
                        fontSize = 14, fontColor = isGood and C.green or C.red,
                    },
                },
            })
        end
        table.insert(children, UI.Panel { height = 12 })
        table.insert(children, UI.Button {
            text = "⚔️ 继续比赛！", width = 180, height = 42, fontSize = 14, variant = "primary",
            onClick = function()
                PlaySFX("gunshot")
                RunMatchRound()
            end,
        })

    elseif matchPhase_ == "round_result" then
        -- ── P1-3: 比赛视觉化 ──
        local opp = matchOpponents_[matchRound_]
        local roundWon = matchWins_ > (matchRound_ - matchWins_) -- 简化判断：本轮如果当前wins>losses说明最近赢了
        -- 精确判断：narrative最后一条是绿色=赢
        local lastNarr = matchNarrative_ and matchNarrative_[#matchNarrative_]
        if lastNarr then roundWon = (lastNarr.color == C.green) end

        -- VS 对决面板（紧凑）
        local myPowerDisplay = GetTeamPower and GetTeamPower() or 0
        local opPowerDisplay = opp and opp.power or 0
        local vsPanel = UI.Panel {
            width = "92%", flexDirection = "row", alignItems = "center",
            justifyContent = "space-between", padding = 8,
            backgroundColor = { 20, 20, 30, 220 }, borderRadius = 10,
            borderWidth = 1, borderColor = roundWon and { 80, 200, 80, 150 } or { 200, 80, 80, 150 },
            children = {
                -- 我方
                UI.Panel { alignItems = "center", gap = 2, children = {
                    UI.Label { text = "🐉", fontSize = 22 },
                    UI.Label { text = "Dragon Force", fontSize = 10, fontColor = { 120, 200, 255, 255 } },
                    UI.Label { text = tostring(myPowerDisplay), fontSize = 16, fontWeight = "bold",
                        fontColor = roundWon and C.green or C.text },
                }},
                -- VS 标志
                UI.Panel { alignItems = "center", children = {
                    UI.Label { text = "⚔️", fontSize = 20 },
                    UI.Label { text = "第" .. matchRound_ .. "场", fontSize = 10, fontColor = C.textDim },
                }},
                -- 对手
                UI.Panel { alignItems = "center", gap = 2, children = {
                    UI.Label { text = opp and opp.emoji or "👤", fontSize = 22 },
                    UI.Label { text = opp and opp.name or "???", fontSize = 10, fontColor = { 255, 160, 120, 255 } },
                    UI.Label { text = tostring(opPowerDisplay), fontSize = 16, fontWeight = "bold",
                        fontColor = (not roundWon) and C.red or C.text },
                }},
            },
        }
        table.insert(children, UI.Panel { height = 4 })
        table.insert(children, vsPanel)
        table.insert(children, UI.Panel { height = 4 })

        -- 胜负大字 Banner
        if roundWon then
            table.insert(children, UI.Label {
                text = "🎉 VICTORY!", fontSize = 20, fontWeight = "bold",
                fontColor = { 80, 255, 120, 255 },
                textShadow = { offsetX = 0, offsetY = 2, blur = 12, color = { 50, 200, 80, 120 } },
            })
        else
            table.insert(children, UI.Label {
                text = "💔 DEFEATED", fontSize = 20, fontWeight = "bold",
                fontColor = { 255, 100, 100, 255 },
                textShadow = { offsetX = 0, offsetY = 2, blur = 12, color = { 200, 50, 50, 120 } },
            })
        end

        -- 战报叙事（限制高度，内部可滚动）
        local narrativeLines = {}
        for _, line in ipairs(matchNarrative_ or {}) do
            local isHighlight = line.color == C.gold or line.color == C.green or line.color == C.red
            table.insert(narrativeLines, UI.Label {
                text = line.text, fontSize = isHighlight and 12 or 11,
                fontColor = line.color or C.text,
                fontWeight = isHighlight and "bold" or nil,
                width = "100%", whiteSpace = "normal", lineHeight = 1.4,
            })
        end
        -- MVP 放在叙事区内部
        if matchMVP_ then
            table.insert(narrativeLines, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                padding = 6, gap = 6, marginTop = 4,
                backgroundColor = { 50, 45, 20, 200 }, borderRadius = 6,
                borderWidth = 1, borderColor = { 200, 160, 50, 150 },
                children = {
                    UI.Label { text = matchMVP_.emoji or "⭐", fontSize = 18 },
                    UI.Panel { gap = 1, flex = 1, children = {
                        UI.Label { text = "MVP " .. matchMVP_.name, fontSize = 12, fontWeight = "bold", fontColor = C.gold },
                    }},
                    UI.Label { text = "🏅", fontSize = 16 },
                },
            })
        end
        table.insert(children, UI.ScrollView {
            width = "92%", maxHeight = 120, marginTop = 4,
            children = {
                UI.Panel { width = "100%", gap = 3, children = narrativeLines },
            },
        })
        table.insert(children, UI.Panel { height = 8 })

        -- 判断是否已决出胜负（单败淘汰制）
        local losses = matchRound_ - matchWins_
        local totalRounds = #matchOpponents_
        if losses > 0 or matchRound_ >= totalRounds then
            -- 输了一场即淘汰，或打完全部对手
            table.insert(children, UI.Button { text = "查看总战报", width = 180, minHeight = 40, fontSize = 14, variant = "primary",
                onClick = function() PlaySFX("click"); FinishMatch() end })
        else
            -- 还有下一场
            local nextOpp = matchOpponents_[matchRound_ + 1]
            local nextLabel = nextOpp and ("➡️ 下一场: " .. nextOpp.emoji .. " " .. nextOpp.name) or "➡️ 下一场"
            table.insert(children, UI.Button { text = nextLabel, width = "85%", minHeight = 40, fontSize = 13, variant = "primary",
                onClick = function() PlaySFX("click"); StartMatchRound(matchRound_ + 1) end })
        end

    elseif matchPhase_ == "final_result" then
        -- ── P1-3: 总战报视觉化 ──
        local won = matchResult_ == "win"

        -- 顶部大结果 Banner
        table.insert(children, UI.Panel {
            width = "92%", padding = 16, alignItems = "center", gap = 6,
            backgroundColor = won and { 20, 45, 20, 230 } or { 45, 20, 20, 230 },
            borderRadius = 14,
            borderWidth = 2, borderColor = won and { 80, 200, 80, 180 } or { 200, 80, 80, 180 },
            children = {
                UI.Label {
                    text = won and "🏆 CHAMPION!" or "😤 GAME OVER",
                    fontSize = 26, fontWeight = "bold",
                    fontColor = won and { 255, 215, 0, 255 } or { 255, 120, 120, 255 },
                    textShadow = { offsetX = 0, offsetY = 3, blur = 16, color = won and { 200, 160, 0, 150 } or { 200, 50, 50, 150 } },
                },
                UI.Label {
                    text = won and ("Dragon Force " .. matchWins_ .. " 连胜夺冠！") or ("止步第 " .. matchRound_ .. " 场"),
                    fontSize = 14, fontColor = won and C.gold or C.textDim,
                },
                -- 战绩统计
                UI.Label {
                    text = "总战绩: " .. matchWins_ .. "胜 " .. (matchRound_ - matchWins_) .. "负",
                    fontSize = 13, fontColor = C.text,
                },
            },
        })
        table.insert(children, UI.Panel { height = 8 })

        -- 各轮精简摘要（只保留标题行和胜负结果行）
        for i, mlog in ipairs(matchLog_ or {}) do
            local t = mlog.text
            if t:find("^──") or t:find("^🎉") or t:find("^💔") or t:find("^😤") or t:find("^🏅") then
                table.insert(children, UI.Label { text = t, fontSize = 13, fontColor = mlog.color or C.text, width = "88%", whiteSpace = "normal" })
            end
        end
        table.insert(children, UI.Panel { height = 6 })

        if isFriendlyMatch_ then
            -- 友谊赛结果界面
            table.insert(children, UI.Label {
                text = won and "友谊赛胜利！队伍实力得到检验！" or "虽然输了，但学到了宝贵经验！",
                fontSize = 15, fontColor = won and C.gold or C.accent, width = "88%", textAlign = "center", whiteSpace = "normal",
            })
            table.insert(children, UI.Panel { height = 8 })
            -- 广告：友谊赛胜利后奖励翻倍
            if won and AdManager.CanWatch("match_reward_2x", playerData_.day) then
                local tierCfgLocal = MATCH_TIERS[currentMatchTier_ or 1]
                local extraReward = tierCfgLocal and math.floor(50 * (tierCfgLocal.rewardMult or 1)) or 50
                table.insert(children, AdManager.AdButton {
                    sceneId = "match_reward_2x", day = playerData_.day,
                    text = "视频领额外奖金 +$" .. extraReward,
                    width = "85%", height = 40, fontSize = 12,
                    onReward = function()
                        playerData_.money = playerData_.money + extraReward
                        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + extraReward
                        AddLog("🎬 赞助商为胜利加码！额外奖金$" .. extraReward .. "！")
                        BuildUI()
                    end,
                })
            end
            -- 广告：友谊赛失败复活（全队技术+经验补偿）
            if not won and AdManager.CanWatch("revive_match", playerData_.day) then
                table.insert(children, AdManager.AdButton {
                    sceneId = "revive_match", day = playerData_.day,
                    text = "视频获得败者补偿 全队技术+3",
                    width = "85%", height = 40, fontSize = 12,
                    onReward = function()
                        for _, m in ipairs(teamMembers_) do
                            m.skill = math.min(SKILL_CAP, (m.skill or 30) + 3)
                        end
                        AddLog("🎬 赞助商请来了教练复盘比赛！全队从失败中学到了宝贵经验，技术+3！")
                        BuildUI()
                    end,
                })
            end
            table.insert(children, UI.Button {
                text = "返回网吧",
                width = 180, height = 40, fontSize = 14, variant = "primary",
                onClick = function()
                    PlaySFX("click")
                    isFriendlyMatch_ = false
                    friendlyOpponent_ = nil
                    matchGameType_ = nil
                    -- 比赛结束自然间隔：尝试插屏广告
                    AdManager.ShowInterstitial(playerData_.day)
                    currentPhase_ = PHASE_MANAGE
                    BuildUI()
                end,
            })
        else
            -- 正式锦标赛结果界面（多级）
            local tCfg = (currentTournamentTier_ > 0) and TOURNAMENT_TIERS[currentTournamentTier_] or nil
            local winText = tCfg and tCfg.winText or "🏆 冠军！Dragon Force 夺冠！"
            -- 注：winText 已在顶部 finalEntry 中显示（含战绩），此处不再重复为 Label
            -- 奖励预览
            if won and tCfg then
                table.insert(children, UI.Label {
                    text = "奖金 $" .. tCfg.prize .. " · 声望 +" .. tCfg.repReward,
                    fontSize = 13, fontColor = C.green, textAlign = "center",
                })
            end
            table.insert(children, UI.Panel { height = 8 })
            -- 广告：锦标赛胜利后奖金翻倍
            if won and tCfg and AdManager.CanWatch("match_reward_2x", playerData_.day) then
                local extraPrize = math.floor(tCfg.prize * 0.5)
                table.insert(children, AdManager.AdButton {
                    sceneId = "match_reward_2x", day = playerData_.day,
                    text = "视频领额外奖金 +$" .. extraPrize,
                    width = "85%", height = 40, fontSize = 12,
                    onReward = function()
                        playerData_.money = playerData_.money + extraPrize
                        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + extraPrize
                        AddLog("🎬 赞助商追加锦标赛奖金！额外获得$" .. extraPrize .. "！")
                        BuildUI()
                    end,
                })
            end
            -- 广告：锦标赛失败经验补偿
            if not won and AdManager.CanWatch("revive_match", playerData_.day) then
                table.insert(children, AdManager.AdButton {
                    sceneId = "revive_match", day = playerData_.day,
                    text = "视频败者补偿 技术+5 声望+10",
                    width = "85%", height = 40, fontSize = 12,
                    onReward = function()
                        for _, m in ipairs(teamMembers_) do
                            m.skill = math.min(SKILL_CAP, (m.skill or 30) + 5)
                        end
                        playerData_.reputation = playerData_.reputation + 10
                        AddLog("🎬 赞助商请来了职业教练分析比赛录像！全队技术+5，声望+10！")
                        BuildUI()
                    end,
                })
            end
            -- 继续经营按钮（核心循环）
            local isWorldChamp = won and currentTournamentTier_ == 4
            table.insert(children, UI.Button {
                text = isWorldChamp and "带着世界冠军继续传奇" or (won and "带着荣耀继续经营" or "回去继续奋斗"),
                width = 220, height = 42, fontSize = 14, variant = "primary",
                onClick = function()
                    PlaySFX("click")
                    -- 记录锦标赛战绩
                    playerData_.tournamentPlayed = (playerData_.tournamentPlayed or 0) + 1
                    if tCfg then
                        if not playerData_.tournamentTierWins then playerData_.tournamentTierWins = {} end
                        if won then
                            playerData_.tournamentTierWins[tCfg.id] = (playerData_.tournamentTierWins[tCfg.id] or 0) + 1
                            playerData_.tournamentWins = (playerData_.tournamentWins or 0) + 1
                            playerData_.money = playerData_.money + tCfg.prize
                            playerData_.reputation = playerData_.reputation + tCfg.repReward
                            AddLog(winText .. " 奖金 $" .. tCfg.prize .. "！声望 +" .. tCfg.repReward .. "！")
                            -- 首次锦标赛夺冠里程碑
                            if playerData_.tournamentWins == 1 and not storyTriggered_["milestone_first_tourney"] then
                                storyTriggered_["milestone_first_tourney"] = true
                                AddLog("🎉 【里程碑】首次锦标赛夺冠！整个村子都在为你欢呼！")
                                TriggerCelebration()
                            end
                        else
                            playerData_.reputation = playerData_.reputation + math.floor(tCfg.repReward * 0.3)
                            AddLog(loseText .. " 声望 +" .. math.floor(tCfg.repReward * 0.3))
                        end
                    end
                    isFriendlyMatch_ = false
                    currentTournamentTier_ = 0
                    matchGameType_ = nil
                    -- 锦标赛结束自然间隔：尝试插屏广告
                    AdManager.ShowInterstitial(playerData_.day)
                    StartTransition("🏠 回到网吧", "故事还在继续……", function()
                        PlayBGM("manage")
                        currentPhase_ = PHASE_MANAGE; BuildUI()
                    end)
                end,
            })
            table.insert(children, UI.Panel { height = 4 })
            -- 查看结局按钮（可选）
            table.insert(children, UI.Button {
                text = "查看结局（结束游戏）",
                width = 220, height = 36, fontSize = 13,
                onClick = function()
                    PlaySFX("click")
                    -- 同样结算奖励
                    playerData_.tournamentPlayed = (playerData_.tournamentPlayed or 0) + 1
                    if tCfg then
                        if not playerData_.tournamentTierWins then playerData_.tournamentTierWins = {} end
                        if won then
                            playerData_.tournamentTierWins[tCfg.id] = (playerData_.tournamentTierWins[tCfg.id] or 0) + 1
                            playerData_.tournamentWins = (playerData_.tournamentWins or 0) + 1
                            playerData_.money = playerData_.money + tCfg.prize
                            playerData_.reputation = playerData_.reputation + tCfg.repReward
                            -- 首次锦标赛夺冠里程碑
                            if playerData_.tournamentWins == 1 and not storyTriggered_["milestone_first_tourney"] then
                                storyTriggered_["milestone_first_tourney"] = true
                                AddLog("🎉 【里程碑】首次锦标赛夺冠！整个村子都在为你欢呼！")
                                TriggerCelebration()
                            end
                        end
                    end
                    currentTournamentTier_ = 0
                    matchGameType_ = nil
                    local title = won and "冠军" or "旅程终点"
                    local sub = won and (tCfg and tCfg.winText or "Dragon Force 夺冠！") or "每段旅程都有意义……"
                    StartTransition(title, sub, function()
                        currentPhase_ = PHASE_RESULT; BuildUI()
                    end)
                end,
            })
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.ch5,
        backgroundFit = "cover",
        imageTint = { 215, 225, 215, 255 },
        justifyContent = "center", alignItems = "center", gap = 4, padding = 16,
        children = {
            UI.ScrollView {
                width = "90%", maxWidth = 420, maxHeight = "92%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 20, 16 }, gap = 5,
                        backgroundColor = C.card, borderRadius = 16,
                        borderWidth = 2, borderColor = { 180, 200, 180, 120 },
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 4, blur = 18, color = { 0, 0, 0, 60 } } },
                        children = children,
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 17. 结算界面（多结局系统）
