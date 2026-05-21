---@diagnostic disable: undefined-global
-- ============================================================================
-- 语音播放控制
-- ============================================================================
function PlayVoice(path)
    StopVoice()
    if not audioNode_ then return end
    local sound = cache:GetResource("Sound", path)
    if not sound then
        print("[Voice] Not found: " .. tostring(path))
        return
    end
    voiceSoundSource_ = audioNode_:CreateComponent("SoundSource")
    voiceSoundSource_.gain = 0.85
    voiceSoundSource_:Play(sound)
    print("[Voice] Playing: " .. path)
end

function StopVoice()
    if voiceSoundSource_ then
        voiceSoundSource_:Stop()
        if audioNode_ then
            audioNode_:RemoveComponent(voiceSoundSource_)
        end
        voiceSoundSource_ = nil
    end
end

--- 尝试为当前对话行播放语音
function TryPlayVoiceForDialogue(dlg)
    if not dlg then return end
    local voicePath = FindVoice(dlg.text)
    if voicePath then
        PlayVoice(voicePath)
    else
        StopVoice()
    end
end

-- ============================================================================
-- BGM / SFX 播放控制
-- ============================================================================

--- 播放背景音乐（委托给 AudioDirector，支持交叉淡入淡出）
function PlayBGM(key)
    AudioDirector.PlayBGM(key)
    currentBGM_ = key
end

--- 停止背景音乐
function StopBGM()
    AudioDirector.StopBGM()
    currentBGM_ = ""
end

--- 播放环境音（章节切换时调用）
function PlayAmbient(key)
    if key and key ~= "none" and key ~= "" then
        AudioDirector.PlayAmbient(key)
    else
        AudioDirector.StopAmbient()
    end
end

--- 播放一次性音效（自动清理）
function PlaySFX(key)
    local path = SFX_PATHS[key]
    if not path or not audioNode_ then return end
    local sound = cache:GetResource("Sound", path)
    if not sound then return end
    local src = audioNode_:CreateComponent("SoundSource")
    src.soundType = "Effect"
    src.gain = 0.6
    src.autoRemoveMode = REMOVE_COMPONENT
    src:Play(sound)
end

-- ============================================================================
-- 存档系统
-- ============================================================================
local SAVE_FILE = "save_africa_cafe.json"

--- 保存游戏进度
function SaveGame()
    -- 记录保存时间戳（用于离线收益计算）
    playerData_.lastSaveTimestamp = os.time()

    local saveData = {
        version = 4,
        playerData = playerData_,
        teamMembers = teamMembers_,
        eventLog = eventLog_,
        currentChapter = currentChapter_,
        storyTriggered = storyTriggered_,
        unlockedAchievements = unlockedAchievements_,
        chaptersRead = chaptersRead_,
        npcJournal = npcJournal_,
        -- 群聊数据
        chatMessages = chatMessages_,
        chatUnread = chatUnread_,
        chatLastReadIdx = chatLastReadIdx_,
        -- 只保存 eventId（函数无法序列化，读档后从 CHAT_EVENTS 重建）
        pendingChatEventId = pendingChatDecision_ and pendingChatDecision_.eventId or nil,
        chatEventTriggered = chatEventTriggered_,
        chatTriggerCooldowns = chatTriggerCooldowns_,
        adWatchLog = AdManager.GetSaveData(),
        -- 每日委托
        dailyQuest = dailyQuest_,
        -- 日记系统
        diaryEntries = diaryEntries_,
        -- 网吧实时经营（只存 id + resolved + result + day，effect 函数不可序列化）
        cafeEventsDay = cafeEventsDay_ or 0,
        cafeEventsSave = (function()
            local arr = {}
            if cafeEvents_ then
                for _, ce in ipairs(cafeEvents_) do
                    table.insert(arr, {
                        id = ce.def and ce.def.id or nil,
                        resolved = ce.resolved,
                        result = ce.result,
                        day = ce.day,
                    })
                end
            end
            return arr
        end)(),
        -- 保存候选池中剩余人物的名字，用于加载时恢复
        candidateNames = {},
    }
    for _, c in ipairs(CANDIDATE_POOL) do
        table.insert(saveData.candidateNames, c.name)
    end
    local encOk, jsonStr = pcall(cjson.encode, saveData)
    if not encOk then
        log:Write(LOG_ERROR, "[Save] cjson.encode failed: " .. tostring(jsonStr))
        return
    end
    local file = File(SAVE_FILE, FILE_WRITE)
    if file:IsOpen() then
        file:WriteString(jsonStr)
        file:Close()
        print("[Save] Game saved. Day=" .. playerData_.day)
    else
        print("[Save] Failed to open save file!")
    end
end

--- 检查是否有存档
function HasSaveFile()
    return fileSystem:FileExists(SAVE_FILE)
end

--- 加载游戏进度
function LoadGame()
    if not HasSaveFile() then return false end
    local file = File(SAVE_FILE, FILE_READ)
    if not file:IsOpen() then return false end
    local ok, data = pcall(cjson.decode, file:ReadString())
    file:Close()
    if not ok or not data then
        print("[Save] Failed to decode save file!")
        return false
    end

    -- 恢复玩家数据
    if data.playerData then
        playerData_ = data.playerData
        -- 确保新字段有默认值（兼容旧存档）
        playerData_.actionPoints = playerData_.actionPoints or 3
        playerData_.karma = playerData_.karma or 0
        playerData_.havocCoins = playerData_.havocCoins or 0
        playerData_.totalRuns = playerData_.totalRuns or 0
        playerData_.solarLevel = playerData_.solarLevel or 0
        playerData_.foodShop = playerData_.foodShop or 0
        playerData_.decoLevel = playerData_.decoLevel or 0
        playerData_.securityLevel = playerData_.securityLevel or 0
        playerData_.goldOunces = playerData_.goldOunces or 0
        playerData_.tournamentTierWins = playerData_.tournamentTierWins or {}
        playerData_.wellLevel = playerData_.wellLevel or 0
        playerData_.roadLevel = playerData_.roadLevel or 0
        playerData_.coffeeLevel = playerData_.coffeeLevel or 0
        playerData_.jukeboxLevel = playerData_.jukeboxLevel or 0
        playerData_.tournamentWins = playerData_.tournamentWins or 0
        playerData_.tournamentPlayed = playerData_.tournamentPlayed or 0
        -- v10 留存系统字段（兼容旧存档）
        playerData_.lastSaveTimestamp = playerData_.lastSaveTimestamp or 0
        playerData_.goalProgress = playerData_.goalProgress or { develop = 1, social = 1, wealth = 1 }
        playerData_.goalCompleted = playerData_.goalCompleted or {}
        playerData_.activePeriodicEvent = playerData_.activePeriodicEvent or nil
        playerData_.lastPeriodicDay = playerData_.lastPeriodicDay or {}
        playerData_.npcStoryProgress = playerData_.npcStoryProgress or { kofi = 0, grace = 0, snake = 0 }
    end

    -- 恢复队员
    if data.teamMembers then teamMembers_ = data.teamMembers end

    -- 恢复群聊数据（兼容旧存档：无群聊数据时用空表）
    chatMessages_ = data.chatMessages or {}
    chatUnread_ = data.chatUnread or 0
    chatLastReadIdx_ = data.chatLastReadIdx or 0
    chatEventTriggered_ = data.chatEventTriggered or {}
    chatTriggerCooldowns_ = data.chatTriggerCooldowns or {}
    AdManager.LoadSaveData(data.adWatchLog or {})
    dailyQuest_ = data.dailyQuest  -- 恢复每日委托
    -- 从 eventId 重建待决策（函数无法序列化）
    pendingChatDecision_ = nil
    if data.pendingChatEventId then
        for _, evt in ipairs(CHAT_EVENTS) do
            if evt.id == data.pendingChatEventId and evt.decision then
                local dec = evt.decision()
                pendingChatDecision_ = { eventId = evt.id, question = dec.question, options = dec.options }
                break
            end
        end
    end

    -- 兼容旧存档：为队员补充 perk/flaw 特质数据（从顶部 CANDIDATE_POOL 初始定义匹配）
    local PERK_FLAW_REF = {
        ["Kofi"]    = { perk = "晨练加成", perkDesc = "每天骑车12公里锻炼体能，比赛时耐力+15%", perkBonus = 8,
                        flaw = "家庭压力", flawDesc = "妈妈随时可能发现真相，心情波动大", flawPenalty = 5 },
        ["Big Joe"] = { perk = "铁壁防御", perkDesc = "前保镖经验，防守战术时额外加成", perkBonus = 12,
                        flaw = "体力有限", flawDesc = "体重大容易疲劳，加时赛表现下降", flawPenalty = 4 },
        ["Grace"]   = { perk = "冷静之心", perkDesc = "唱诗班的专注力训练，高压下不崩盘", perkBonus = 10,
                        flaw = "时间受限", flawDesc = "周日必须去教堂，训练时间比别人少", flawPenalty = 3 },
        ["Snake"]   = { perk = "嗜血本能", perkDesc = "街头生存直觉，进攻战术时爆发力惊人", perkBonus = 15,
                        flaw = "暴躁易怒", flawDesc = "心情低时可能摔鼠标，影响全队士气", flawPenalty = 8 },
        ["Mama B"]  = { perk = "稳如老狗", perkDesc = "40年人生阅历，心态永远稳定", perkBonus = 6,
                        flaw = "大龄选手", flawDesc = "反应速度不如年轻人，技能成长较慢", flawPenalty = 3 },
        ["Prince"]  = { perk = "人脉广阔", perkDesc = "酋长之子的身份，赢了比赛声望加倍", perkBonus = 7,
                        flaw = "公子脾气", flawDesc = "输了比赛心情暴跌，需要哄", flawPenalty = 6 },
        ["小雪"]    = { perk = "团队粘合", perkDesc = "温柔的性格能安抚队友情绪，全队心情+", perkBonus = 8,
                        flaw = "支教期限", flawDesc = "支教合同到期可能要回国", flawPenalty = 2 },
        ["Thunder"] = { perk = "闪电反应", perkDesc = "0.1秒出枪速度，进攻战术额外加成", perkBonus = 12,
                        flaw = "旧伤复发", flawDesc = "高强度训练后手腕疼痛，需要休息", flawPenalty = 5 },
    }
    for _, m in ipairs(teamMembers_) do
        if not m.perk and PERK_FLAW_REF[m.name] then
            local ref = PERK_FLAW_REF[m.name]
            m.perk = ref.perk; m.perkDesc = ref.perkDesc; m.perkBonus = ref.perkBonus
            m.flaw = ref.flaw; m.flawDesc = ref.flawDesc; m.flawPenalty = ref.flawPenalty
        end
    end

    -- 恢复事件日志
    if data.eventLog then eventLog_ = data.eventLog end

    -- 恢复章节进度
    if data.currentChapter then currentChapter_ = data.currentChapter end

    -- 恢复剧情触发记录
    if data.storyTriggered then storyTriggered_ = data.storyTriggered end

    -- 恢复成就和已读章节
    if data.unlockedAchievements then unlockedAchievements_ = data.unlockedAchievements end
    if data.chaptersRead then chaptersRead_ = data.chaptersRead end

    -- 恢复 NPC 事迹记录（兼容旧存档）
    npcJournal_ = data.npcJournal or {}

    -- 恢复日记系统（兼容旧存档）
    if data.diaryEntries then
        diaryEntries_ = data.diaryEntries
        -- JSON 反序列化后 key 变成字符串，需要转回数字
        local fixed = {}
        for k, v in pairs(diaryEntries_) do
            fixed[tonumber(k) or k] = v
        end
        diaryEntries_ = fixed
    else
        diaryEntries_ = {}
    end
    cachedAtmoDay_ = -1
    cachedAtmoText_ = ""

    -- 恢复网吧实时经营数据（兼容旧存档）
    cafeEventsDay_ = data.cafeEventsDay or 0
    cafeEvents_ = {}
    pendingCafeCount_ = 0
    if data.cafeEventsSave then
        -- 从 id 重建事件引用（effect 函数不可序列化，需从 CAFE_EVENTS 重建 def）
        local evtById = {}
        if CAFE_EVENTS then
            for _, evt in ipairs(CAFE_EVENTS) do
                evtById[evt.id] = evt
            end
        end
        for _, saved in ipairs(data.cafeEventsSave) do
            local def = saved.id and evtById[saved.id] or nil
            if def then
                local ce = {
                    def = def,
                    resolved = saved.resolved or false,
                    result = saved.result,
                    day = saved.day,
                }
                table.insert(cafeEvents_, ce)
                if not ce.resolved then
                    pendingCafeCount_ = pendingCafeCount_ + 1
                end
            end
        end
    end

    -- 兼容旧存档：友谊赛字段
    playerData_.friendlyWins = playerData_.friendlyWins or 0
    playerData_.friendlyLosses = playerData_.friendlyLosses or 0
    -- 兼容旧存档：借款系统
    playerData_.debt = playerData_.debt or 0
    playerData_.debtDay = playerData_.debtDay or 0
    -- 兼容旧存档：设备/比赛/分店/赛季/发电机等新字段
    playerData_.equipCondition = playerData_.equipCondition or 100
    playerData_.matchTier = playerData_.matchTier or 1
    playerData_.tierWins = playerData_.tierWins or { 0, 0, 0 }
    playerData_.generatorLevel = playerData_.generatorLevel or 0
    playerData_.fuel = playerData_.fuel or 0
    playerData_.fuelCapacity = playerData_.fuelCapacity or 0
    playerData_.branches = playerData_.branches or {}
    playerData_.totalEarnings = playerData_.totalEarnings or 0
    playerData_.seasonId = playerData_.seasonId or 1
    playerData_.seasonWins = playerData_.seasonWins or 0
    playerData_.seasonRewards = playerData_.seasonRewards or {}

    -- 兼容旧存档：客流量系统（临时变量不存档，每次加载重置）
    trafficBonus_ = 0
    cachedTrafficDay_ = -1

    -- 恢复候选池：用名字重建
    if data.candidateNames then
        InitCandidatePool()  -- 先重建完整候选池
        local nameSet = {}
        for _, n in ipairs(data.candidateNames) do nameSet[n] = true end
        local newPool = {}
        for _, c in ipairs(CANDIDATE_POOL) do
            if nameSet[c.name] then table.insert(newPool, c) end
        end
        CANDIDATE_POOL = newPool
    end

    -- ========== 版本迁移 ==========
    local saveVer = data.version or 1

    -- v2 → v3: 新增章节4/5，老玩家需要提示
    if saveVer < 3 then
        -- 确保新字段有默认值
        playerData_.tournamentWins = playerData_.tournamentWins or 0

        -- 在群聊中推送系统通知（玩家进入管理界面后会看到）
        table.insert(chatMessages_, {
            sender = "系统",
            content = "🎉 游戏更新！新增了第四章「地区争霸」和第五章「非洲之巅」，继续推进故事解锁全新剧情吧！",
            isSelf = false,
            isSystem = true,
            day = playerData_.day,
        })
        chatUnread_ = (chatUnread_ or 0) + 1

        -- 事件日志也记一笔
        table.insert(eventLog_, "第" .. playerData_.day .. "天: 📢 游戏更新 — 新增第四章&第五章剧情！")
        if #eventLog_ > 20 then table.remove(eventLog_, 1) end

        print("[Save] Migrated save v" .. saveVer .. " → v3: notified new chapters 4/5")
    end

    -- v3 → v4: 留存系统（目标链/周期事件/NPC支线/离线收益）
    if saveVer < 4 then
        -- 初始化留存字段（如果playerData恢复中没有）
        playerData_.goalProgress = playerData_.goalProgress or { develop = 1, social = 1, wealth = 1 }
        playerData_.goalCompleted = playerData_.goalCompleted or {}
        playerData_.lastPeriodicDay = playerData_.lastPeriodicDay or {}
        playerData_.npcStoryProgress = playerData_.npcStoryProgress or { kofi = 0, grace = 0, snake = 0 }
        playerData_.lastSaveTimestamp = playerData_.lastSaveTimestamp or 0

        -- 通知玩家新系统
        table.insert(chatMessages_, {
            sender = "系统",
            content = "🎯 新系统上线！目标链追踪、离线收益、NPC支线剧情——更多精彩内容等你体验！",
            isSelf = false,
            isSystem = true,
            day = playerData_.day,
        })
        chatUnread_ = (chatUnread_ or 0) + 1
        table.insert(eventLog_, "第" .. playerData_.day .. "天: 📢 更新 — 留存系统上线！")
        if #eventLog_ > 20 then table.remove(eventLog_, 1) end

        print("[Save] Migrated save v" .. saveVer .. " → v4: retention system initialized")
    end

    -- 计算离线收益（需要 Retention 模块已加载）
    if playerData_.lastSaveTimestamp > 0 and Retention then
        local offlineSeconds = os.time() - playerData_.lastSaveTimestamp
        local reward = Retention.CalculateOfflineEarnings(offlineSeconds)
        if reward then
            pendingOfflineReward_ = reward
            print("[Save] Offline earnings pending: $" .. reward.earnings .. " (" .. reward.hours .. "h)")
        end
    end

    print("[Save] Game loaded. Day=" .. playerData_.day .. ", Chapter=" .. currentChapter_)
    return true
end

