---@diagnostic disable: undefined-global
function InitCandidatePool()
    CANDIDATE_POOL = {
        { name = "Kofi",   talent = 90, mood = 100, skill = 12, trait = "闪电单车少年", emoji = "🧑🏿",
          desc = "每天骑2小时自行车来网吧，跑刀天赋惊人", fee = 80, special = true,
          perk = "晨练加成", perkDesc = "每天骑车12公里锻炼体能，比赛时耐力+15%", perkBonus = 8,
          flaw = "家庭压力", flawDesc = "妈妈随时可能发现真相，心情波动大", flawPenalty = 5,
          story = "Kofi每天凌晨五点起床，骑着破自行车翻过两座山头来网吧。他妈妈以为他去打工了。有一次你发现他偷偷把跑刀赚的哈弗币换成钱寄回家……" },
        { name = "Big Joe", talent = 72, mood = 100, skill = 8, trait = "前保镖·灵巧胖子", emoji = "🧑🏿",
          desc = "200斤前酋长保镖，却有极其灵巧的手指", fee = 80, special = true,
          perk = "铁壁防御", perkDesc = "前保镖经验，防守战术时额外加成", perkBonus = 12,
          flaw = "体力有限", flawDesc = "体重大容易疲劳，加时赛表现下降", flawPenalty = 4,
          story = "Big Joe曾经是当地酋长的贴身保镖。他说'保护人用拳头，保护队友用鼠标'。第一次玩三角洲就用霰弹枪拿了五杀。" },
        { name = "Grace",  talent = 88, mood = 100, skill = 22, trait = "牧师之女·暗夜玫瑰", emoji = "👩🏿",
          desc = "白天唱诗班，晚上偷偷来网吧跑刀", fee = 100, special = true,
          perk = "冷静之心", perkDesc = "唱诗班的专注力训练，高压下不崩盘", perkBonus = 10,
          flaw = "时间受限", flawDesc = "周日必须去教堂，训练时间比别人少", flawPenalty = 3,
          story = "Grace的父亲是镇上最大教堂的牧师。她说'上帝教我精准——所以我每枪都是爆头'。" },
        { name = "Snake",  talent = 95, mood = 80, skill = 5, trait = "街头之王·毒蛇", emoji = "🧑🏿",
          desc = "街头帮派小头目，游戏嗅觉惊人但脾气火爆", fee = 130, special = true,
          perk = "嗜血本能", perkDesc = "街头生存直觉，进攻战术时爆发力惊人", perkBonus = 15,
          flaw = "暴躁易怒", flawDesc = "心情低时可能摔鼠标，影响全队士气", flawPenalty = 8,
          story = "Snake在街头混了五年，所有人都怕他。他说'在游戏里杀人比在街上干净'。一旦他认你当老大，他会拼命。" },
        { name = "Mama B", talent = 65, mood = 100, skill = 35, trait = "烤鸡婆婆·隐藏狙神", emoji = "👩🏿",
          desc = "门口卖烤鸡的40岁大婶，竟有恐怖的狙击天赋", fee = 50, special = true,
          perk = "稳如老狗", perkDesc = "40年人生阅历，心态永远稳定", perkBonus = 6,
          flaw = "大龄选手", flawDesc = "反应速度不如年轻人，技能成长较慢", flawPenalty = 3,
          story = "Mama Blessing本来只是在网吧门口卖烤鸡。有天她好奇试了一局，结果用狙击枪打出全场最高击杀。你当场就惊了。" },
        { name = "Prince", talent = 85, mood = 100, skill = 15, trait = "酋长之子·王子", emoji = "🧑🏿",
          desc = "酋长的儿子，想通过电竞证明自己", fee = 25, special = true,
          perk = "人脉广阔", perkDesc = "酋长之子的身份，赢了比赛声望加倍", perkBonus = 7,
          flaw = "公子脾气", flawDesc = "输了比赛心情暴跌，需要哄", flawPenalty = 6,
          story = "Prince的父亲是当地最有权势的酋长。他说'我不要父亲给我的一切，我要自己赢来的荣耀'。加入免费但想当队长。" },
        { name = "小雪",   talent = 82, mood = 100, skill = 28, trait = "支教老师·跨国连线", emoji = "👩",
          desc = "中国支教志愿者，教孩子中文也教他们跑刀", fee = 60, special = true,
          perk = "团队粘合", perkDesc = "温柔的性格能安抚队友情绪，全队心情+", perkBonus = 8,
          flaw = "支教期限", flawDesc = "支教合同到期可能要回国", flawPenalty = 2,
          story = "小雪是从四川来非洲支教的大学生。她说'我在这里找到了比大城市更纯粹的快乐'。" },
        { name = "Thunder",talent = 93, mood = 100, skill = 3, trait = "退役短跑·闪电反应", emoji = "🧑🏿",
          desc = "退役短跑运动员，0.1秒出枪反应速度", fee = 100, special = true,
          perk = "闪电反应", perkDesc = "0.1秒出枪速度，进攻战术额外加成", perkBonus = 12,
          flaw = "旧伤复发", flawDesc = "高强度训练后手腕疼痛，需要休息", flawPenalty = 5,
          story = "Thunder曾是国家短跑队候补，因伤退役。他的反应速度是普通人的三倍，第一次摸鼠标就展现了恐怖的甩枪速度。" },
    }
end

function ResetGame()
    StopBGM()
    StopVoice()  -- 重置时停止语音
    playerData_ = {
        money = 5000, reputation = 0, day = 1, cafeName = "Dragon Net Cafe",
        computers = 3, chairLevel = 1, netSpeed = 1, acLevel = 0,
        solarLevel = 0, foodShop = 0, decoLevel = 0, securityLevel = 0,
        havocCoins = 0, totalRuns = 0,
        actionPoints = 6, karma = 0,  -- 新手保护期Day1给6AP
        friendlyWins = 0, friendlyLosses = 0,
        equipCondition = 100,
        matchTier = 1, tierWins = { 0, 0, 0 },
        generatorLevel = 0, fuel = 0, fuelCapacity = 0,
        branches = {}, totalEarnings = 0,
        goalProgress = { develop = 1, social = 1, wealth = 1 },
        goalCompleted = {},
        nearBankruptCount = 0,
        seasonId = 1, seasonWins = 0, seasonRewards = {},
        wellLevel = 0, roadLevel = 0, coffeeLevel = 0, jukeboxLevel = 0,
        tournamentWins = 0, tournamentPlayed = 0,
        tournamentTierWins = {},
        debt = 0, debtDay = 0,
        goldOunces = 0, coupDaysLeft = 0,
        goldDecor = false,
        goldKeycaps = false,
        goldSafe = false,
        goldVIP = false,
    }
    unlockedAchievements_ = {}
    InitCandidatePool()
    teamMembers_ = {}; eventLog_ = {}; currentChapter_ = 1; npcJournal_ = {}
    recruitReplaceIdx_ = nil; dismissConfirmIdx_ = nil; trainNoAPIdx_ = nil
    achievePopupOpen_ = false; seasonPassPopupOpen_ = false
    upgradeGroupExpand_ = {}  -- 手风琴展开状态 { market=false, community=false, culture=false }
    storyTriggered_ = {}; pendingStoryEffect_ = nil; pendingStoryMeta_ = nil
    isFriendlyMatch_ = false; friendlyOpponent_ = nil; friendlyMatchToday_ = false; scoutedRound_ = 0
    -- 踢馆重置
    challengeActive_ = false; challengeDay_ = 0; challengeOpponent_ = nil
    challengeWagerType_ = ""; challengeWagerAmount_ = 0
    challengeRound_ = 0; challengePlayerWins_ = 0; challengeNPCWins_ = 0
    challengeModes_ = {}; challengePhase_ = "select_wager"
    challengeDifficulty_ = 0.5; challengeNPCScore_ = 0; challengeMultiplier_ = 1.5; challengeRoundResult_ = nil; miniGame_ = nil
    matchTierSelect_ = false; currentMatchTier_ = 1; currentTournamentTier_ = 0
    matchGameType_ = nil; matchGameSelect_ = false; pendingMatchTier_ = nil
    dialogueOverride_ = nil; eliteEntranceDialogues_ = nil; eliteEntranceIdx_ = nil
    trafficBonus_ = 0; cachedTrafficDay_ = -1
    customerAnim_ = { figures = {}, spawnTimer = 0 }
    chatMessages_ = {}; chatUnread_ = 0; chatLastReadIdx_ = 0; pendingChatDecision_ = nil; chatEventTriggered_ = {}; chatTriggerCooldowns_ = {}
    branchOpenStep_ = 0; branchOpenLocOpts_ = nil; branchOpenSelLoc_ = nil
    AdManager.Reset()
    -- RetentionV2 完全重置
    if RV2 then RV2.FullReset() end
    -- 二手市场完全重置
    if Market and Market.FullReset then pcall(Market.FullReset) end
    -- 清除经营动作动画
    local CafeAnimEvents = require("CafeAnimEvents")
    CafeAnimEvents.Clear()
    dailyQuest_ = nil  -- 重置每日委托
    -- 网吧实时经营重置
    cafeEvents_ = {}
    cafeEventsDay_ = 0
    pendingCafeCount_ = 0
    cafeViewOpen_ = false
    cafeActionUsedDay_ = 0
    restoreManageScroll_ = nil
    restoreCafePopupScroll_ = nil
    -- 升级计时器重置
    activeUpgrade_ = nil
    upgradeTimeLeft_ = 0
    upgradeTotalTime_ = 0
    upgradeCost_ = nil
    upgradeSynergiesBefore_ = nil
    manageTab_ = "action"
    currentPhase_ = PHASE_TITLE; matchPhase_ = "intro"; matchLog_ = {}
    PlayBGM("title")
    BuildUI()
end

-- ============================================================================
-- 19. 帧更新 & 输入
-- ============================================================================

---@param eventType string
---@param eventData UpdateEventData
function HandleUpdate(eventType, eventData)
    local dt = eventData["TimeStep"]:GetFloat()
    lastDt_ = dt
    gameTime_ = gameTime_ + dt

    -- 过场动画更新
    UpdateTransition(dt)

    -- 代理状态一致性修复：CinematicTransition 可能在 onMidpoint 异常时
    -- 内部已经 active=false，但代理 transition_.active 还是 true
    if transition_.active and not CinematicTransition.IsActive() then
        log:Write(LOG_WARNING, "[Watchdog] proxy active but CinematicTransition inactive, syncing")
        transition_.active = false
        transition_.phase = "none"
        transition_.alpha = 0
    end

    -- UI 看门狗：检测到 UI 丢失且无过场动画时自动恢复（所有阶段均覆盖）
    if not transition_.active then
        if uiRoot_ == nil then
            -- UI 完全丢失
            uiWatchdog_ = (uiWatchdog_ or 0) + dt
            if uiWatchdog_ > 0.2 then
                log:Write(LOG_WARNING, "[Watchdog] uiRoot_ nil for 0.2s, phase=" .. tostring(currentPhase_) .. " forcing BuildUI")
                uiWatchdog_ = 0
                -- 如果当前 phase 的数据状态不完整，回退到安全界面
                local buildOk, buildErr = pcall(BuildUI)
                if not buildOk then
                    log:Write(LOG_ERROR, "[Watchdog] BuildUI failed: " .. tostring(buildErr) .. " → fallback")
                    -- 标题页用 TITLE，其他用 MANAGE
                    if currentPhase_ ~= PHASE_TITLE then
                        currentPhase_ = PHASE_MANAGE
                    end
                    pcall(BuildUI)
                end
            end
        else
            uiWatchdog_ = 0
            -- 额外检测：phase 已切换但 UI 未重建（uiRoot_ 存在但内容过期 → 视觉黑屏）
            if lastBuildUIPhase_ and lastBuildUIPhase_ ~= currentPhase_
               and gameTime_ - lastBuildUITime_ > 0.3 then
                log:Write(LOG_WARNING, "[Watchdog] phase mismatch: UI=" .. tostring(lastBuildUIPhase_)
                    .. " current=" .. tostring(currentPhase_) .. " stale " .. string.format("%.1fs", gameTime_ - lastBuildUITime_) .. " → rebuilding")
                pcall(BuildUI)
            end
        end
    else
        uiWatchdog_ = 0
    end

    -- 黑屏恢复：如果过场已结束但 alpha 不为零（异常残留），强制清零
    -- 移到条件外部，确保 PHASE_TITLE 等所有阶段都能恢复
    if not transition_.active and transition_.alpha > 0 then
        transition_.alpha = 0
        transition_.phase = "none"
    end

    -- 恢复管理界面滚动位置（等待布局和 contentHeight 计算完成再恢复）
    if restoreManageScroll_ and uiRoot_ then
        restoreManageScroll_.frames = (restoreManageScroll_.frames or 0) + 1
        -- 等至少3帧确保 Yoga layout + ScrollView.UpdateContentSize 都已执行
        if restoreManageScroll_.frames >= 3 then
            local sv = uiRoot_:FindById("manage-scroll")
            if sv then
                local _, contentH = sv:GetContentSize()
                if contentH and contentH > 0 then
                    -- clamp 到有效范围，防止内容变短后 bounce back
                    local layout = sv:GetLayout()
                    local maxY = math.max(0, contentH - (layout and layout.h or 0))
                    local safeY = math.min(restoreManageScroll_.y, maxY)
                    sv:SetScrollDirect(restoreManageScroll_.x, safeY)
                    restoreManageScroll_ = nil
                elseif restoreManageScroll_.frames > 10 then
                    -- 超时安全退出，避免无限等待
                    restoreManageScroll_ = nil
                end
            else
                restoreManageScroll_ = nil
            end
        end
    end

    -- 恢复网吧弹窗内 ScrollView 的滚动位置
    if restoreCafePopupScroll_ and uiRoot_ then
        restoreCafePopupScroll_.frames = (restoreCafePopupScroll_.frames or 0) + 1
        if restoreCafePopupScroll_.frames >= 3 then
            local csv = uiRoot_:FindById("cafe-popup-scroll")
            if csv then
                local _, contentH = csv:GetContentSize()
                if contentH and contentH > 0 then
                    local layout = csv:GetLayout()
                    local maxY = math.max(0, contentH - (layout and layout.h or 0))
                    local safeY = math.min(restoreCafePopupScroll_.y, maxY)
                    csv:SetScrollDirect(restoreCafePopupScroll_.x, safeY)
                    restoreCafePopupScroll_ = nil
                elseif restoreCafePopupScroll_.frames > 10 then
                    restoreCafePopupScroll_ = nil
                end
            else
                restoreCafePopupScroll_ = nil
            end
        end
    end

    -- 升级倒计时
    if activeUpgrade_ and upgradeTimeLeft_ > 0 then
        upgradeTimeLeft_ = upgradeTimeLeft_ - dt
        -- 更新进度条 UI（直接操作避免全量 rebuild）
        local bar = uiRoot_ and uiRoot_:FindById("upgrade-progress-fill")
        local lbl = uiRoot_ and uiRoot_:FindById("upgrade-time-label")
        if bar then
            local pct = 1.0 - (upgradeTimeLeft_ / math.max(1, upgradeTotalTime_))
            bar:SetStyle({ width = math.floor(pct * 100) .. "%" })
        end
        if lbl then
            lbl:SetText(FormatUpgradeTime(math.max(0, upgradeTimeLeft_)))
        end
        if upgradeTimeLeft_ <= 0 then
            upgradeTimeLeft_ = 0
            CompleteUpgrade()
        end
    elseif activeUpgrade_ and upgradeTimeLeft_ == -1 then
        -- 跨日建造模式：显示"建造中"，等待目标天数到达
        local lbl = uiRoot_ and uiRoot_:FindById("upgrade-time-label")
        if lbl then
            local daysLeft = (upgradeCompletionDay_ or 0) - (playerData_.day or 1)
            if daysLeft > 0 then
                lbl:SetText("还需" .. daysLeft .. "天")
            else
                lbl:SetText("即将完成...")
            end
        end
        local bar = uiRoot_ and uiRoot_:FindById("upgrade-progress-fill")
        if bar then
            -- 根据天数显示大致进度
            local totalDays = (upgradeCompletionDay_ or 1) - ((upgradeCompletionDay_ or 1) - 2)
            local elapsed = (playerData_.day or 1) - ((upgradeCompletionDay_ or 2) - 2)
            local pct = math.min(0.9, math.max(0.1, elapsed / math.max(1, totalDays)))
            bar:SetStyle({ width = math.floor(pct * 100) .. "%" })
        end
    end

    -- 客流动画更新
    UpdateCustomerAnim(dt)

    -- AudioDirector 每帧更新（BGM交叉淡入淡出 + 环境音淡入淡出）
    AudioDirector.Update(dt)

    -- 打字机更新（CinematicDialogue 驱动 + 旧state同步）
    if currentPhase_ == PHASE_DIALOGUE and not typewriter_.done then
        CinematicDialogue.UpdateTypewriter(dt)
        UpdateTypewriter(dt)
        -- 同步 CinematicDialogue 状态到旧 typewriter_ 变量
        typewriter_.done = CinematicDialogue.IsDone()
        local label = uiRoot_ and uiRoot_:FindById("dialogueText")
        if label then
            label:SetText(CinematicDialogue.GetDisplayText())
        end
    end

    -- 训练更新（瞄准模式）
    if currentPhase_ == PHASE_TRAIN and trainActive_ and trainPhase_ == "playing" and trainMode_ == "aim" then
        trainTimer_ = trainTimer_ + dt
        trainTargetTimer_ = trainTargetTimer_ + dt

        local tl = uiRoot_ and uiRoot_:FindById("trainTimerLabel")
        if tl then
            local left = math.max(0, TRAIN_DURATION - trainTimer_)
            tl:SetText(string.format("⏱ %.1f", left))
            tl:SetFontColor(left < 3 and C.red or C.text)
        end

        if trainTargetTimer_ >= trainTargetTimeout_ then
            trainCombo_ = 0
            local cl = uiRoot_ and uiRoot_:FindById("trainComboLabel")
            if cl then cl:SetText("🔥 x0"); cl:SetFontColor(C.textDim) end
            SpawnTrainTarget()
        end

        if trainTimer_ >= TRAIN_DURATION then
            trainActive_ = false
            trainPhase_ = "done"
            if trainActiveCell_ > 0 then DeactivateCell(trainActiveCell_) end
            BuildUI()
        end
    end

    -- 训练更新（反应模式）
    if currentPhase_ == PHASE_TRAIN and trainActive_ and trainPhase_ == "playing" and trainMode_ == "react" then
        trainTimer_ = trainTimer_ + dt
        if reactPhaseState_ == "wait" then
            reactCountdown_ = reactCountdown_ - dt
            if reactCountdown_ <= 0 then
                reactPhaseState_ = "show"
                reactTimer_ = 0
                BuildUI()
            end
        elseif reactPhaseState_ == "show" then
            reactTimer_ = reactTimer_ + dt
            reactFlashTimer_ = reactFlashTimer_ + dt
            -- 闪现模式：0.4秒后方向消失，需要触发 UI 刷新
            if reactFlash_ and math.abs(reactFlashTimer_ - 0.4) < dt * 1.1 then
                BuildUI()
            end
            -- 实时更新计时器
            local tl = uiRoot_ and uiRoot_:FindById("reactTimerLabel")
            if tl then
                tl:SetText(string.format("%.1fs", math.max(0, reactTimeLimit_ - reactTimer_)))
            end
            if reactTimer_ >= reactTimeLimit_ then
                -- 超时
                reactAnswered_ = nil
                PlaySFX("miss")
                reactPhaseState_ = "result"
                BuildUI()
            end
        elseif reactPhaseState_ == "result" then
            reactCountdown_ = reactCountdown_ - dt
            if not reactAnswered_ or reactCountdown_ <= -0.8 then
                -- 等待0.8秒后自动进入下一轮
                reactCountdown_ = 0
                StartReactRound()
            end
        end
    end

    -- 训练更新（记忆模式）
    if currentPhase_ == PHASE_TRAIN and trainActive_ and trainPhase_ == "playing" and trainMode_ == "memory" then
        trainTimer_ = trainTimer_ + dt
        if memoryPhaseState_ == "show" then
            memoryShowTimer_ = memoryShowTimer_ + dt
            local interval = 0.7
            if memoryShowTimer_ >= interval then
                memoryShowTimer_ = 0
                memoryShowIdx_ = memoryShowIdx_ + 1
                if memoryShowIdx_ > #memorySequence_ then
                    -- 展示完毕，等一下再进入输入阶段
                    memoryShowIdx_ = #memorySequence_
                    memoryPhaseState_ = "input"
                    memoryPlayerSeq_ = {}
                end
                BuildUI()
            end
        elseif memoryPhaseState_ == "result" then
            memoryShowTimer_ = memoryShowTimer_ + dt
            if memoryShowTimer_ >= 1.2 then
                memoryShowTimer_ = 0
                StartMemoryRound()
                BuildUI()
            end
        end
    end
end

---@param eventType string
---@param eventData KeyDownEventData
function HandleKeyDown(eventType, eventData)
    if transition_.active then return end  -- 过场中禁止操作

    local key = eventData["Key"]:GetInt()
    if key == KEY_RETURN or key == KEY_SPACE then
        if currentPhase_ == PHASE_TITLE then StartChapterWithTransition(1)
        elseif currentPhase_ == PHASE_DIALOGUE then AdvanceDialogue() end
    end
    if key == KEY_ESCAPE then
        if currentPhase_ == PHASE_TRAIN then
            trainMember_ = nil; trainActive_ = false; trainPhase_ = "ready"; trainMode_ = "select"
            PlayBGM("manage")
            currentPhase_ = PHASE_MANAGE; BuildUI()
        end
        -- 事件不允许Escape跳过，必须通过按钮选择
    end
end
