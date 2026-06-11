---@diagnostic disable: undefined-global
local Achievements = require("Achievements")
-- 训练逻辑
function StartTraining(idx)
    -- RV2: 免费训练模式跳过AP消耗（方案1）
    if playerData_.freeTrainMode then
        -- 免费模式：不消耗AP（免费次数已在UI按钮点击时扣除，不再重复扣除）
    else
        if not UseActionPoint(1) then return end
    end
    trainMember_ = teamMembers_[idx]
    trainMemberIdx_ = idx
    trainPhase_ = "ready"
    trainActive_ = false
    trainMode_ = "select"
    PlayBGM("train")
    currentPhase_ = PHASE_TRAIN
    BuildUI()
end

--- 随机抽取 n 道不重复的问答题，打乱每道题的选项顺序
function ShuffleQuizQuestions(n)
    local pool = {}
    for i, q in ipairs(QUIZ_POOL) do pool[i] = i end
    -- Fisher-Yates shuffle
    for i = #pool, 2, -1 do
        local j = math.random(1, i)
        pool[i], pool[j] = pool[j], pool[i]
    end
    quizQuestions_ = {}
    for i = 1, math.min(n, #pool) do
        local src = QUIZ_POOL[pool[i]]
        -- 打乱选项顺序，记住正确答案的新位置
        local indices = {1, 2, 3, 4}
        for k = 4, 2, -1 do
            local j = math.random(1, k)
            indices[k], indices[j] = indices[j], indices[k]
        end
        local newOpts = {}
        local newAns = 1
        for k = 1, 4 do
            newOpts[k] = src.opts[indices[k]]
            if indices[k] == src.ans then newAns = k end
        end
        table.insert(quizQuestions_, { q = src.q, opts = newOpts, ans = newAns })
    end
    quizIdx_ = 1
    quizCorrect_ = 0
    quizAnswered_ = false
    quizSelectedOpt_ = 0
end

function SpawnTrainTarget()
    local old = trainActiveCell_
    if old > 0 then DeactivateCell(old) end
    local newCell = old
    while newCell == old do newCell = math.random(1, TRAIN_GRID_SIZE) end
    trainActiveCell_ = newCell
    trainTargetTimer_ = 0
    ActivateCell(newCell)
end

function ActivateCell(idx)
    local cell = uiRoot_ and uiRoot_:FindById("tcell_" .. idx)
    if cell then cell:SetStyle({ backgroundColor = C.target, borderColor = C.targetGlow, borderWidth = 3 }) end
    local icon = uiRoot_ and uiRoot_:FindById("tcellIcon_" .. idx)
    if icon then icon:SetText("🎯") end
end

function DeactivateCell(idx)
    local cell = uiRoot_ and uiRoot_:FindById("tcell_" .. idx)
    if cell then cell:SetStyle({ backgroundColor = C.cellIdle, borderColor = C.border, borderWidth = 1 }) end
    local icon = uiRoot_ and uiRoot_:FindById("tcellIcon_" .. idx)
    if icon then icon:SetText("") end
end

function OnTrainCellClick(idx)
    if not trainActive_ or trainPhase_ ~= "playing" then return end
    if idx == trainActiveCell_ then
        PlaySFX("train_hit")
        trainScore_ = trainScore_ + 1
        trainCombo_ = trainCombo_ + 1
        if trainCombo_ > trainMaxCombo_ then trainMaxCombo_ = trainCombo_ end
        local sl = uiRoot_ and uiRoot_:FindById("trainScoreLabel")
        if sl then sl:SetText("🎯 " .. trainScore_) end
        local cl = uiRoot_ and uiRoot_:FindById("trainComboLabel")
        if cl then
            cl:SetText("🔥 x" .. trainCombo_)
            cl:SetFontColor(trainCombo_ >= 3 and C.gold or C.textDim)
        end
        SpawnTrainTarget()
    else
        PlaySFX("miss")
        trainCombo_ = 0
        local cl = uiRoot_ and uiRoot_:FindById("trainComboLabel")
        if cl then cl:SetText("🔥 x0"); cl:SetFontColor(C.textDim) end
        local cell = uiRoot_ and uiRoot_:FindById("tcell_" .. idx)
        if cell then cell:SetStyle({ backgroundColor = { 80, 30, 30, 200 } }) end
    end
end

function CalcTrainGain()
    if not trainMember_ then return 0 end
    local _, _, synergyTrain = CalcUpgradeSynergies()
    if trainMode_ == "quiz" then
        local base = quizCorrect_ * 2
        local talentBonus = math.floor(trainMember_.talent / 40)
        return math.max(1, base + talentBonus + synergyTrain)
    elseif trainMode_ == "react" then
        local base = reactCorrect_ * 2
        local talentBonus = math.floor(trainMember_.talent / 35)
        return math.max(1, base + talentBonus + synergyTrain)
    elseif trainMode_ == "memory" then
        local base = memoryCorrect_ * 2 + math.max(0, memoryLen_ - 3)
        local talentBonus = math.floor(trainMember_.talent / 35)
        return math.min(8, math.max(1, base + talentBonus + synergyTrain))  -- 单次上限8
    else
        local base = math.floor(trainScore_ / 3) + 1
        local talentBonus = math.floor(trainMember_.talent / 30)
        local comboBonus = math.floor(trainMaxCombo_ / 5)
        return math.max(1, base + talentBonus + comboBonus + synergyTrain)
    end
end

--- 计算训练最终收益（含RV2羁绊+黄金时段+市场装备加成）
function CalcFinalTrainGain()
    local gain = CalcTrainGain()
    -- 市场装备: 训练加成
    if Market and Market.CalcEquippedEffects then
        local ok, mfx = pcall(Market.CalcEquippedEffects)
        if ok and mfx and mfx.trainBonus and mfx.trainBonus > 0 then
            gain = gain + math.max(1, math.floor(gain * mfx.trainBonus))
        end
    end
    -- P2-2: 心情影响训练收益
    if trainMember_ then
        local mood = trainMember_.mood or 50
        if mood >= 80 then
            -- 心情极佳：训练热情高涨 +20%
            gain = math.floor(gain * 1.20)
        elseif mood >= 60 then
            -- 心情良好：正常发挥 +5%
            gain = math.floor(gain * 1.05)
        elseif mood < 30 then
            -- 心情极差：消极怠工，随机失败
            local failChance = (30 - mood) / 60  -- 心情0时 50% 失败率
            if math.random() < failChance then
                gain = math.max(0, math.floor(gain * 0.3))  -- 失败时仅得30%
                AddLog("😞 " .. (trainMember_.name or "队员") .. " 心情低落，训练效果大打折扣！")
            else
                gain = math.floor(gain * 0.75)  -- 成功但效率低
            end
        elseif mood < 50 then
            -- 心情偏低：效率下降 -15%
            gain = math.floor(gain * 0.85)
        end
    end
    if not RV2 or not trainMember_ then return gain end
    -- 方案11: 羁绊训练倍率（师徒关系 ×1.5）
    local ok1, bondMult = pcall(RV2.GetBondTrainMultiplier, trainMember_.name)
    if ok1 and bondMult and bondMult > 1.0 then
        gain = math.floor(gain * bondMult)
    end
    -- 方案9: 黄金时段倍率（×1.5）
    local ok2, ghMult = pcall(RV2.UseGoldenHourAction)
    if ok2 and ghMult and ghMult > 1.0 then
        gain = math.floor(gain * ghMult)
    end
    return gain
end

--- 反应训练：玩家点击方向
function OnReactAnswer(dir)
    if reactPhaseState_ ~= "show" then return end
    reactAnswered_ = dir
    -- 反向模式：正确答案是相反方向
    local expectedDir = reactReverse_ and REACT_OPPOSITE[reactDirection_] or reactDirection_
    local correct = (dir == expectedDir)
    if correct then
        reactCorrect_ = reactCorrect_ + 1
        reactTotalTime_ = reactTotalTime_ + reactTimer_
        PlaySFX("train_hit")
    else
        PlaySFX("miss")
    end
    reactPhaseState_ = "result"
    BuildUI()
end

--- 反应训练：开始新一轮（难度递进）
function StartReactRound()
    reactRound_ = reactRound_ + 1
    if reactRound_ > reactTotal_ then
        trainPhase_ = "done"; trainActive_ = false
        BuildUI()
        return
    end
    local dirs = { "up", "down", "left", "right" }
    reactDirection_ = dirs[math.random(1, 4)]
    reactAnswered_ = false
    reactTimer_ = 0
    reactFlashTimer_ = 0
    reactPhaseState_ = "wait"

    -- 难度递进：时限缩短、等待缩短、反向、闪现
    if reactRound_ <= 3 then
        -- 第1-3轮：入门（充足时间）
        reactTimeLimit_ = 2.0
        reactCountdown_ = 0.8 + math.random() * 0.6
        reactReverse_ = false
        reactFlash_ = false
    elseif reactRound_ <= 5 then
        -- 第4-5轮：加速（时间压缩）
        reactTimeLimit_ = 1.5
        reactCountdown_ = 0.5 + math.random() * 0.5
        reactReverse_ = false
        reactFlash_ = false
    elseif reactRound_ <= 7 then
        -- 第6-7轮：反向（按相反方向）
        reactTimeLimit_ = 1.5
        reactCountdown_ = 0.5 + math.random() * 0.4
        reactReverse_ = true
        reactFlash_ = false
    else
        -- 第8-10轮：闪现+反向（方向短暂显示后消失）
        reactTimeLimit_ = 1.3
        reactCountdown_ = 0.4 + math.random() * 0.3
        reactReverse_ = (reactRound_ % 2 == 0) -- 交替反向
        reactFlash_ = true
    end

    BuildUI()
end

--- 记忆训练：开始新一轮
function StartMemoryRound()
    memoryRound_ = memoryRound_ + 1
    if memoryRound_ > memoryTotalRounds_ then
        trainPhase_ = "done"; trainActive_ = false
        BuildUI()
        return
    end
    trainPhase_ = "playing"
    memorySequence_ = {}
    memoryPlayerSeq_ = {}
    memoryShowIdx_ = 0
    memoryShowTimer_ = 0
    memoryPhaseState_ = "show"
    for i = 1, memoryLen_ do
        memorySequence_[i] = math.random(1, #MEMORY_ICONS)
    end
end

--- 记忆训练：玩家点击图标
function OnMemoryInput(iconIdx)
    if memoryPhaseState_ ~= "input" then return end
    table.insert(memoryPlayerSeq_, iconIdx)
    PlaySFX("click")
    if #memoryPlayerSeq_ >= #memorySequence_ then
        -- 判断是否全部正确
        local allCorrect = true
        for i, v in ipairs(memorySequence_) do
            if memoryPlayerSeq_[i] ~= v then allCorrect = false; break end
        end
        if allCorrect then
            memoryCorrect_ = memoryCorrect_ + 1
            memoryLen_ = math.min(memoryLen_ + 1, 12)  -- 上限12步，超过后难度靠速度体现
            PlaySFX("train_hit")
        else
            PlaySFX("miss")
        end
        memoryPhaseState_ = "result"
    end
    BuildUI()
end

function FinishTraining()
    -- 踢馆模式：跳转到踢馆回合结算
    if challengeActive_ then FinishChallengeRound(); return end

    -- RV2: 免费训练模式走独立结算（方案1）
    if playerData_.freeTrainMode and trainMember_ then
        local score = trainScore_ or 0
        if trainMode_ == "quiz" then score = (quizCorrect_ or 0) * 10
        elseif trainMode_ == "react" then score = (reactCorrect_ or 0) * 10
        elseif trainMode_ == "memory" then score = (memoryCorrect_ or 0) * 10
        end
        pcall(SettleFreeTrainReward, score)
        trainMember_ = nil; trainActive_ = false; trainPhase_ = "ready"; trainMode_ = "select"
        PlayBGM("manage")
        currentPhase_ = PHASE_MANAGE; BuildUI()
        return
    end

    if trainMember_ then
        local gain = CalcFinalTrainGain()  -- 使用含羁绊+黄金时段的最终收益
        trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
        trainMember_.mood = math.max(0, trainMember_.mood - 3)
        playerData_.reputation = playerData_.reputation + 2
        -- 委托追踪：训练次数
        playerData_.questTrainCount = (playerData_.questTrainCount or 0) + 1
        if trainMode_ == "quiz" then
            AddLog("🧠 " .. trainMember_.name .. " 战术问答完成！答对" .. quizCorrect_ .. "/" .. quizTotal_ .. " 技术+" .. gain)
        elseif trainMode_ == "react" then
            AddLog("⚡ " .. trainMember_.name .. " 反应训练完成！正确" .. reactCorrect_ .. "/" .. reactTotal_ .. " 技术+" .. gain)
        elseif trainMode_ == "memory" then
            AddLog("🧩 " .. trainMember_.name .. " 记忆训练完成！通过" .. memoryCorrect_ .. "/" .. memoryTotalRounds_ .. " 技术+" .. gain)
        else
            AddLog("🎯 " .. trainMember_.name .. " 瞄准特训完成！命中" .. trainScore_ .. " 技术+" .. gain)
        end
    end
    trainMember_ = nil; trainActive_ = false; trainPhase_ = "ready"; trainMode_ = "select"
    PlayBGM("manage")
    currentPhase_ = PHASE_MANAGE; BuildUI()
end

function GetTeamAvgSkill()
    if #teamMembers_ == 0 then return 0 end
    local t = 0; for _, m in ipairs(teamMembers_) do t = t + m.skill end
    return math.floor(t / #teamMembers_)
end

function GetTeamPower()
    local p = 0
    for _, m in ipairs(teamMembers_) do
        local base = math.floor(m.talent * 0.4 + m.skill * 0.5 + m.mood * 0.1)
        -- 特质修正：心情高时perk生效，心情低时flaw惩罚加重
        local perkVal = m.perkBonus or 0
        local flawVal = m.flawPenalty or 0
        if m.mood >= 70 then
            base = base + perkVal  -- 心情好，特长发挥
        elseif m.mood < 40 then
            base = base - flawVal  -- 心情差，缺陷暴露
        end
        p = p + base
    end
    -- 黄金键帽加成
    if playerData_.goldKeycaps then p = p + 15 end
    -- 市场装备: 比赛战力加成
    if Market and Market.CalcEquippedEffects then
        local ok, mfx = pcall(Market.CalcEquippedEffects)
        if ok and mfx and mfx.matchPower and mfx.matchPower > 0 then
            p = p + math.floor(mfx.matchPower)
        end
    end
    -- RV2: 羁绊比赛加成（方案11）
    if RV2 then
        local ok, bondBonus = pcall(RV2.GetBondMatchBonus)
        if ok and bondBonus and bondBonus > 0 then
            p = p + bondBonus
        end
    end
    return p
end

--- 计算比赛各项加成
function CalcMatchBonuses()
    local karmaBonus = 0
    if playerData_.karma >= 5 then karmaBonus = 25
    elseif playerData_.karma >= 2 then karmaBonus = 12
    elseif playerData_.karma <= -5 then karmaBonus = -20
    elseif playerData_.karma <= -2 then karmaBonus = -8
    end
    local avgMood = 0
    for _, m in ipairs(teamMembers_) do avgMood = avgMood + m.mood end
    if #teamMembers_ > 0 then avgMood = math.floor(avgMood / #teamMembers_) end
    local moodBonus = math.floor((avgMood - 50) * 0.3)
    -- 战术克制
    local tacticBonus = 0
    local opp = matchOpponents_[matchRound_]
    if opp then
        local oppStyle = opp.style
        if matchTactic_ == "aggressive" and oppStyle == "防守反击" then tacticBonus = 20
        elseif matchTactic_ == "aggressive" and oppStyle == "快攻型" then tacticBonus = -15
        elseif matchTactic_ == "defensive" and oppStyle == "快攻型" then tacticBonus = 20
        elseif matchTactic_ == "defensive" and oppStyle == "防守反击" then tacticBonus = -15
        elseif matchTactic_ == "balanced" then tacticBonus = 5
        end
    end
    -- 侦查加成：正确选择克制战术时额外 +10
    if scoutedRound_ == matchRound_ then tacticBonus = tacticBonus + 10 end
    return karmaBonus, moodBonus, tacticBonus
end

--- 生成单场比赛叙事
function GenerateMatchNarrative(opp, won, mvp, myPower, opPower)
    local lines = {}

    -- 开场（根据游戏类型选择叙事池）
    local narrativeStyle = matchGameType_ and matchGameType_.narrativeStyle or nil
    local narrativePool = narrativeStyle and GAME_NARRATIVE_POOLS[narrativeStyle] or nil
    local openings
    if narrativePool then
        openings = {}
        for _, o in ipairs(narrativePool.openings) do
            table.insert(openings, string.format(o, opp.name))
        end
    else
        openings = {
            "解说员的声音响彻全场：'Dragon Force vs " .. opp.name .. "，比赛开始！'",
            "裁判一声哨响，双方选手开始操作。键盘声噼里啪啦响成一片。",
            "大屏幕上倒计时归零。" .. opp.emoji .. " " .. opp.name .. " 率先发起进攻！",
        }
    end
    table.insert(lines, { text = openings[math.random(1, #openings)], color = C.text })
    PlaySFX("gunshot")

    -- 战术描述
    local tacticDesc = {
        aggressive = "Dragon Force 采用猛攻战术，全队压上！",
        defensive  = "Dragon Force 摆出防守阵型，伺机反击。",
        balanced   = "Dragon Force 攻守均衡，稳步推进。",
    }
    table.insert(lines, { text = "📋 " .. tacticDesc[matchTactic_], color = C.accent })

    -- 中段叙事（随机精彩瞬间，根据游戏类型选择）
    if mvp and #teamMembers_ > 0 then
        local highlights
        if narrativePool then
            highlights = {}
            for _, h in ipairs(narrativePool.highlights) do
                table.insert(highlights, string.format(h, mvp.name))
            end
        else
            highlights = {
                mvp.name .. "一个闪身躲过敌方狙击，反手爆头！全场沸腾！",
                mvp.name .. "连续击倒两名对手，解说员大喊'这就是非洲新星！'",
                "关键时刻，" .. mvp.name .. "用一波教科书级别的跑刀带走局面！",
                mvp.name .. "在最后10秒扭转战局，队友们激动地拍桌子！",
                "对方集中火力压制，" .. mvp.name .. "稳住阵脚一个人扛住了压力！",
            }
        end
        table.insert(lines, { text = "⭐ " .. highlights[math.random(1, #highlights)], color = C.gold })
    end

    -- 其他队员表现
    if #teamMembers_ >= 2 then
        local other = teamMembers_[math.random(1, #teamMembers_)]
        local assists = {
            other.name .. "完美配合，掩护队友突破。",
            other.name .. "稳住后方，没让对手有可乘之机。",
            other.name .. "的走位令对手防不胜防。",
        }
        table.insert(lines, { text = assists[math.random(1, #assists)], color = C.textDim })
    end

    -- 结果
    if won then
        PlaySFX("hit")
        local winTexts = {
            "🎉 Dragon Force 以 " .. myPower .. " vs " .. opPower .. " 拿下本场！",
            "🎉 漂亮！Dragon Force 强势碾压，" .. myPower .. " vs " .. opPower .. "！",
            "🎉 险胜！" .. myPower .. " vs " .. opPower .. "，队员们紧紧拥抱！",
        }
        table.insert(lines, { text = winTexts[math.random(1, #winTexts)], color = C.green })
    else
        PlaySFX("miss")
        local loseTexts = {
            "💔 遗憾落败…… " .. myPower .. " vs " .. opPower .. "。",
            "💔 " .. opp.name .. " 技高一筹，" .. myPower .. " vs " .. opPower .. "。",
            "💔 差一点……" .. myPower .. " vs " .. opPower .. "，队员们沉默不语。",
        }
        table.insert(lines, { text = loseTexts[math.random(1, #loseTexts)], color = C.red })
    end

    -- MVP宣告
    if mvp then
        table.insert(lines, { text = "🏅 本场MVP: " .. mvp.emoji .. " " .. mvp.name, color = C.gold })
    end

    return lines
end

--- 执行单场比赛
--- 处理中局决策选择
function ResolveMidDecision(choiceIdx)
    if not midDecision_ then return end
    local choice = midDecision_.choices[choiceIdx]
    if not choice then return end

    if choice.risk then
        -- 高风险选项：成功率与队伍平均skill挂钩（35%~85%）
        local avgSkill = 0
        for _, m in ipairs(teamMembers_) do avgSkill = avgSkill + m.skill end
        avgSkill = #teamMembers_ > 0 and (avgSkill / #teamMembers_) or 30
        local successChance = math.min(0.85, 0.35 + avgSkill / 200)
        local success = math.random() < successChance
        if success then
            midDecisionBonus_ = choice.bonus
            midDecisionNarrative_ = choice.narrative_win
            AddLog("⚡ 冒险决策成功！战力+" .. choice.bonus)
        else
            midDecisionBonus_ = -math.abs(choice.bonus)
            midDecisionNarrative_ = choice.narrative_fail
            AddLog("⚡ 冒险决策失败！战力" .. midDecisionBonus_)
        end
    else
        -- 普通选项：稳定效果
        midDecisionBonus_ = choice.bonus
        midDecisionNarrative_ = choice.narrative
        if choice.bonus > 0 then
            AddLog("⚡ 决策生效：战力+" .. choice.bonus)
        elseif choice.bonus < 0 then
            AddLog("⚡ 决策代价：战力" .. choice.bonus)
        else
            AddLog("⚡ 稳妥决策，维持现状。")
        end
    end

    matchPhase_ = "mid_decision_result"
    BuildUI()
end

function RunMatchRound()
    local opp = matchOpponents_[matchRound_]
    if not opp then FinishMatch(); return end

    local tp = GetTeamPower()
    local karmaBonus, moodBonus, tacticBonus = CalcMatchBonuses()
    local decisionMod = midDecisionBonus_ or 0
    -- 设备加成：设备状态越好越有利（最高+15）
    local equipBonus = math.floor(((playerData_.equipCondition or 50) - 50) * 0.3)
    -- 游戏类型战力修正
    local gamePowerMod = matchGameType_ and matchGameType_.powerMod or 1.0

    -- RV2: 比赛微操系统（方案8）—— 关键时刻微操加成
    local microOpBonus = 0
    if RV2 then
        local mOk, microOp = pcall(RV2.TriggerMatchMicroOp)
        if mOk and microOp then
            -- 微操成功率基于队伍平均技能（40%~90%）
            local avgSkill = GetTeamAvgSkill()
            local successRate = math.min(0.90, 0.40 + avgSkill / 200)
            if microOp.type == "tap" then
                -- 连点类：用成功率模拟
                if math.random() < successRate then
                    microOpBonus = microOp.bonusOnSuccess
                    AddLog(microOp.successMsg)
                else
                    microOpBonus = microOp.bonusOnFail
                    AddLog(microOp.failMsg or ("😓 " .. microOp.name .. "失败"))
                end
            elseif microOp.type == "choice" then
                -- 选择类：AI选择最优（针对弱点），但随机模拟
                local pick = math.random(1, #microOp.options)
                local opt = microOp.options[pick]
                if opt.correct() then
                    microOpBonus = microOp.bonusCorrect[pick] or 10
                    AddLog("🎯 战术抉择正确！战力+" .. microOpBonus)
                else
                    microOpBonus = microOp.bonusFail or -5
                    AddLog("😓 战术判断失误，战力" .. microOpBonus)
                end
            end
        end
    end

    -- 决策权重放大1.5倍；侦查后随机范围收窄为±8，未侦查为±13
    local scouted = scoutedRound_ == matchRound_
    local randRange = scouted and 8 or 13
    local my = math.floor(tp * gamePowerMod) + karmaBonus + moodBonus + tacticBonus + math.floor(decisionMod * 1.5) + equipBonus + microOpBonus + math.random(-randRange, randRange)
    local op = opp.power + math.random(-randRange, randRange)
    if scouted then
        AddLog("🔍 【侦查生效】掌握了对手信息，比赛波动大幅收窄（±" .. randRange .. "）")
    end
    local won = my > op

    -- 选MVP（贡献最大的队员）
    local mvp = nil
    if #teamMembers_ > 0 then
        local bestVal = -1
        for _, m in ipairs(teamMembers_) do
            local val = m.talent * 0.4 + m.skill * 0.5 + m.mood * 0.1 + math.random(0, 20)
            if val > bestVal then bestVal = val; mvp = m end
        end
    end
    matchMVP_ = mvp

    if won then matchWins_ = matchWins_ + 1 end

    -- 生成叙事
    matchNarrative_ = GenerateMatchNarrative(opp, won, mvp, my, op)

    -- 记录到总日志
    table.insert(matchLog_, { text = "── 第" .. matchRound_ .. "场 vs " .. opp.name .. " ──", color = C.textDim })
    for _, line in ipairs(matchNarrative_) do
        table.insert(matchLog_, line)
    end
    table.insert(matchLog_, { text = "" })

    matchPhase_ = "round_result"
    BuildUI()
end

--- 开始整场比赛（从intro进入第一场战术选择）
-- 赛间互动事件池（在进入下一轮战术选择前触发）
local MATCH_INTERLUDE_POOL = {
    { icon = "📊", title = "半场数据分析",
      desc = "教练（你）打开笔记本电脑，分析了前几局的数据。你发现对手每次都在第45秒发起进攻……",
      choices = {
          { text = "📋 分享数据给队员", bonus = 12, narrative = "队员根据数据调整了防守节奏，明显更有针对性了！" },
          { text = "🤫 自己记住就好", bonus = 5, narrative = "你默默记下了规律，准备在关键时刻提醒队员。" },
      },
    },
    { icon = "📣", title = "观众助威",
      desc = "网吧门口聚了一群围观的年轻人，开始喊'Dragon Force！Dragon Force！'，你的队员听到了欢呼声。",
      choices = {
          { text = "🎉 邀请观众进来近距离看", bonus = 15, risk = true, narrative_win = "观众涌进网吧，气氛燃爆！队员在主场氛围下超常发挥！", narrative_fail = "人太多太吵，队员反而没法集中注意力了。" },
          { text = "👋 朝他们挥挥手继续比赛", bonus = 8, narrative = "一个简单的致意让观众更疯狂了，队员士气大增！" },
      },
    },
    { icon = "🔧", title = "设备中场检修",
      desc = "趁换场间隙，你快速检查了一下设备状态。有台电脑风扇声音有点大，CPU温度偏高……",
      choices = {
          { text = "🧊 用冷却喷雾降温", bonus = 10, narrative = "喷了冷却喷雾后风扇安静了，电脑运行更流畅。" },
          { text = "🔌 换到备用电脑", bonus = 18, risk = true, narrative_win = "备用电脑配置居然更好！队员惊喜地发现帧率提高了20fps！", narrative_fail = "备用电脑的键盘手感不同，队员花了很长时间适应。" },
      },
    },
    { icon = "☕", title = "能量补给",
      desc = "队员们打完几局开始犯困了。你手里有两个选择——Mama Blessing的浓咖啡，或者从冰箱里拿功能饮料。",
      choices = {
          { text = "☕ Mama的浓咖啡", bonus = 10, narrative = "一口下去队员都精神了！Mama的咖啡就是有魔力。" },
          { text = "🥤 功能饮料冲一波", bonus = 20, risk = true, narrative_win = "功能饮料效果拔群！队员反应速度飙升，打出了连杀！", narrative_fail = "有个队员喝太猛呛到了，咳了五分钟才缓过来。" },
      },
    },
    { icon = "💬", title = "对手挑衅",
      desc = "对面的队长在休息时间冲你们喊：'就这？我还以为Dragon Force多厉害呢！'你的队员脸都绿了。",
      choices = {
          { text = "🧘 冷静回应：比赛说话", bonus = 10, narrative = "你淡定地说'下半场见'，队员被你的从容感染，反而更冷静了。" },
          { text = "🔥 反击：等着瞧", bonus = 18, risk = true, narrative_win = "怒火转化为动力，队员下半场打出了统治级表现！", narrative_fail = "情绪太上头，队员开始冲动操作，失误增多。" },
      },
    },
    { icon = "📱", title = "老板来电话了",
      desc = "你在老家的朋友发来微信：'哥们儿，你们比赛有直播吗？我在国内给你拉了一波关注！'直播间人数蹭蹭往上涨。",
      choices = {
          { text = "📲 告诉队员国内在看", bonus = 12, narrative = "队员听说国内有人看他们的比赛，打起了十二分精神！" },
          { text = "🔇 先不说，赛后惊喜", bonus = 6, narrative = "你决定赛后再告诉他们这个好消息，现在专注比赛。" },
      },
    },
    { icon = "🗺️", title = "三角洲战术推演",
      desc = "中场休息时，你在白板上画出了三角洲行动的经典战术站位图。队员们围过来看得入神。",
      choices = {
          { text = "🎯 重点讲解交叉火力", bonus = 14, narrative = "队员领悟了交叉火力配合的精髓，协作意识大幅提升！" },
          { text = "🏃 演练快速轮换战术", bonus = 20, risk = true, narrative_win = "轮换战术演练成功！队员之间的默契仿佛开了挂！", narrative_fail = "战术太复杂了，队员们反而搞混了站位。" },
      },
    },
    { icon = "🔭", title = "赛场侦察兵",
      desc = "Thunder跑来汇报：'教练！我偷偷看了对面的屏幕，他们在练烟雾弹封点！'",
      choices = {
          { text = "💡 让队员准备反烟雾战术", bonus = 16, narrative = "知己知彼百战百胜！针对性的反烟雾战术让对手的烟雾弹成了摆设。" },
          { text = "🤝 告诉Thunder不要偷看", bonus = 5, narrative = "虽然放弃了情报优势，但你教会了队员什么是体育精神。队伍士气反而提升了。" },
      },
    },
    { icon = "🎮", title = "赛前自定义按键",
      desc = "Big Joe举手：'教练，我想把静步键改成空格，三角洲里这样操作更顺手。'其他队员也开始讨论按键设置。",
      choices = {
          { text = "⚙️ 统一优化全队按键", bonus = 15, risk = true, narrative_win = "统一按键后队员操作更流畅，配合更默契！特别是道具切换速度提升了一截！", narrative_fail = "有些队员不习惯新按键，手忙脚乱按错了好几次。" },
          { text = "👐 各自保留习惯按键", bonus = 8, narrative = "每个人用最顺手的设置，发挥最稳定。稳扎稳打也是一种策略。" },
      },
    },
}

function StartMatchRound(roundNum)
    matchRound_ = roundNum
    matchTactic_ = "balanced"
    midDecision_ = nil
    midDecisionBonus_ = 0
    midDecisionNarrative_ = nil

    -- 第2轮及以后，60%概率触发赛间互动事件
    if roundNum >= 2 and math.random() < 0.60 then
        matchInterlude_ = MATCH_INTERLUDE_POOL[math.random(1, #MATCH_INTERLUDE_POOL)]
        matchPhase_ = "interlude"
        BuildUI()
        return
    end

    matchPhase_ = "tactic"
    BuildUI()
end

--- 比赛总结
function FinishMatch()
    local totalRounds = #matchOpponents_
    local losses = matchRound_ - matchWins_
    matchResult_ = (matchRound_ >= totalRounds and losses == 0) and "win"
        or losses > 0 and "lose" or "win"

    if isFriendlyMatch_ then
        -- 比赛奖励（强敌×2，比赛等级倍率叠加）
        local won = matchResult_ == "win"
        local elite = friendlyOpponent_ and friendlyOpponent_.isElite
        local tier = currentMatchTier_ or 1
        local tierCfg = MATCH_TIERS[tier]
        local tierMult = tierCfg and tierCfg.rewardMult or 1.0
        local eliteMult = elite and 2 or 1
        local gameRewardMod = matchGameType_ and matchGameType_.rewardMod or 1.0
        -- RV2: 黄金时段比赛奖励倍率（方案9）
        local ghMatchMult = 1.0
        if RV2 then
            local ok, m = pcall(RV2.UseGoldenHourAction)
            if ok and m then ghMatchMult = m end
        end
        local mult = eliteMult * tierMult * gameRewardMod * ghMatchMult
        -- P1-1 电竞专精：比赛奖励 +30%
        if (playerData_.specialization or "") == "esports" then
            mult = mult * 1.30
        end
        local skillGain = math.floor((won and math.random(4, 8) or math.random(2, 4)) * mult)
        -- P1-1 电竞专精：训练效率 +20%（通过 skillGain 体现）
        if (playerData_.specialization or "") == "esports" then
            skillGain = math.floor(skillGain * 1.20)
        end
        local repGain = math.floor((won and 15 or 5) * mult)
        local prize = math.floor((won and math.random(40, 80) or 0) * mult)
        local hcGain = math.floor((won and math.random(20, 50) or math.random(5, 15)) * mult)
        for _, m in ipairs(teamMembers_) do
            m.skill = math.min(SKILL_CAP, m.skill + skillGain)
            m.mood = math.min(100, m.mood + (won and 10 or -5))
        end
        playerData_.reputation = playerData_.reputation + repGain
        playerData_.money = playerData_.money + prize
        playerData_.havocCoins = playerData_.havocCoins + hcGain
        playerData_.totalRuns = playerData_.totalRuns + 2

        -- 追踪战绩
        -- 快速委托追踪：总场次（胜负均算）
        playerData_.questMatchPlayed = (playerData_.questMatchPlayed or 0) + 1
        if won then
            playerData_.friendlyWins = playerData_.friendlyWins + 1
            -- 委托追踪：比赛胜利
            playerData_.questMatchWins = (playerData_.questMatchWins or 0) + 1
            -- RV2: 比赛胜利赛季积分（方案10）
            if RV2 then pcall(RV2.AddSeasonPoints, 3, "比赛胜利") end
            -- 首次比赛胜利里程碑
            if playerData_.friendlyWins == 1 and not storyTriggered_["milestone_first_win"] then
                storyTriggered_["milestone_first_win"] = true
                AddLog("🎉 【里程碑】首场比赛胜利！Dragon Force 的传奇从这一刻开始！")
                TriggerCelebration()
            end
        else playerData_.friendlyLosses = playerData_.friendlyLosses + 1 end

        -- 追踪各等级胜场
        if won and tier >= 1 and tier <= 3 then
            playerData_.tierWins = playerData_.tierWins or { 0, 0, 0 }
            playerData_.tierWins[tier] = (playerData_.tierWins[tier] or 0) + 1
            -- 检查是否解锁下一等级
            if tier < 3 then
                local nextTier = MATCH_TIERS[tier + 1]
                if nextTier and nextTier.unlock() and playerData_.matchTier == tier then
                    playerData_.matchTier = tier + 1
                    AddLog("🎊 恭喜！解锁新比赛等级: " .. nextTier.name)
                end
            end
        end

        -- 赛季积分
        if won then
            local seasonPts = tier * (elite and 3 or 1)
            playerData_.seasonWins = (playerData_.seasonWins or 0) + seasonPts
            -- 赛季晋级检查
            local seasonThresholds = { 10, 20, 35 }  -- 赛季1→2需10分, 2→3需20分, 3→?需35分
            local sid = playerData_.seasonId or 1
            if sid <= #seasonThresholds and playerData_.seasonWins >= seasonThresholds[sid] then
                playerData_.seasonId = sid + 1
                playerData_.seasonWins = 0
                local seasonNames = { "新秀赛季", "精英赛季", "传奇赛季", "王者赛季" }
                local seasonCashRewards = { 800, 1500, 3000 }   -- 修正倒挂：S1$800 S2$1500 S3$3000
                local seasonRepRewards  = { 40,  70,  120  }    -- 声望递增：40/70/120
                local reward   = seasonCashRewards[sid] or (sid * 800)
                local repReward = seasonRepRewards[sid] or (sid * 40)
                playerData_.money = playerData_.money + reward
                playerData_.reputation = playerData_.reputation + repReward
                AddLog("🏆 赛季晋级！进入「" .. (seasonNames[sid + 1] or "传说赛季") .. "」奖金$" .. reward .. " 声望+" .. repReward)
            end
        end

        local tierTag = tier > 1 and (" [" .. (tierCfg and tierCfg.name or "") .. "]") or ""
        local gameTag = matchGameType_ and (" 🎮" .. matchGameType_.name) or ""
        local rewardLine = "技能+" .. skillGain .. " 声望+" .. repGain
        if prize > 0 then rewardLine = rewardLine .. " 奖金$" .. prize end
        rewardLine = rewardLine .. " 哈弗币+" .. hcGain

        local record = "（战绩 " .. playerData_.friendlyWins .. "胜" .. playerData_.friendlyLosses .. "负）"
        local resultText = won
            and ("🎉 " .. tierTag .. gameTag .. "比赛胜利！" .. rewardLine .. " " .. record)
            or ("😤 " .. tierTag .. gameTag .. "比赛惜败，但积累了经验。" .. rewardLine .. " " .. record)
        table.insert(matchLog_, { text = resultText, color = won and C.gold or C.accent })
        AddLog(resultText)

        -- 比赛结果深度影响经营
        if won then
            -- 胜利朝圣效应：连胜越多，声望/客流爆发越大
            local winStreak = playerData_.friendlyWins - playerData_.friendlyLosses
            if winStreak >= 5 then
                local pilgrimBonus = math.min(50, winStreak * 5)
                playerData_.reputation = playerData_.reputation + pilgrimBonus
                AddLog("🌟 连胜效应！慕名朝圣的玩家络绎不绝，声望+" .. pilgrimBonus)
            end
            -- Prince的特殊效果：赢了比赛声望额外翻倍
            if HasMember("Prince") then
                local princeBonusRep = math.floor(repGain * 0.3)
                playerData_.reputation = playerData_.reputation + princeBonusRep
                AddLog("👑 Prince的人脉发挥作用，额外声望+" .. princeBonusRep)
            end
            PlaySFX("victory"); PlaySFX("crowd_cheer"); TriggerCelebration()
        else
            -- 输了比赛的后果
            -- Snake暴怒风险
            for _, m in ipairs(teamMembers_) do
                if m.name == "Snake" and m.mood < 50 then
                    m.mood = math.max(0, m.mood - 15)
                    AddLog("🐍 Snake赛后暴怒摔了键盘！心情暴跌。你需要安抚他。")
                end
                -- Prince输不起
                if m.name == "Prince" and m.mood < 60 then
                    m.mood = math.max(0, m.mood - 10)
                    AddLog("👑 Prince很沮丧：'我不能输……父亲会笑我的。'")
                end
            end
            -- 连败危机：连续输3场以上，队员可能动摇
            local loseStreak = playerData_.friendlyLosses - playerData_.friendlyWins
            if loseStreak >= 3 and #teamMembers_ > 1 then
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.max(0, m.mood - 5)
                end
                AddLog("😰 连败阴云笼罩，队员们士气低落……有人开始怀疑还有没有未来。")
            end
            PlaySFX("defeat")
        end
        local newAch = Achievements.CheckAndUnlock()
        if newAch and #newAch > 0 then pendingAchievements_ = newAch end
    else
        -- 正式锦标赛结果（适配多级锦标赛）
        local tCfg = (currentTournamentTier_ > 0) and TOURNAMENT_TIERS[currentTournamentTier_] or nil
        local tName = tCfg and tCfg.name or "🏆 锦标赛"
        local resultText = matchResult_ == "win"
            and (tCfg and tCfg.winText or ("🎉 " .. tName .. " Dragon Force 夺冠！"))
            or (tCfg and tCfg.loseText or ("💔 " .. tName .. " 遗憾淘汰"))
        resultText = resultText .. "（" .. matchWins_ .. "胜" .. losses .. "负）"
        table.insert(matchLog_, { text = resultText, color = matchResult_ == "win" and C.gold or C.red })
        if matchResult_ == "win" then
            PlayBGM("victory")
            PlaySFX("victory"); PlaySFX("crowd_cheer")
            TriggerCelebration()
        else
            PlaySFX("defeat")
        end
    end

    matchPhase_ = "final_result"
    BuildUI()
end

