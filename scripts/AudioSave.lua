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
local SAVE_BACKUP = "save_africa_cafe.bak.json"
local SAVE_TEMP = "save_africa_cafe.tmp.json"

--- 安全写入存档（先写临时文件，成功后再替换正式文件）
local function SafeWriteFile(filename, content)
    local file = File(filename, FILE_WRITE)
    if not file:IsOpen() then return false, "cannot open file" end
    file:WriteString(content)
    file:Close()
    -- 验证写入是否成功（回读检查）
    local verify = File(filename, FILE_READ)
    if not verify:IsOpen() then return false, "verify open failed" end
    local readBack = verify:ReadString()
    verify:Close()
    if #readBack ~= #content then
        return false, "verify size mismatch: wrote " .. #content .. " read " .. #readBack
    end
    return true
end

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
        -- 集市摊贩支线故事
        marketStoryProgress = marketStoryProgress_,
        marketStoryCompleted = marketStoryCompleted_,
        marketStoryLastDay = marketStoryLastDay_,
        marketStoryCrossCompleted = marketStoryCrossCompleted_,
        -- unlockedAchievements 已迁移到 playerData_.achievements，此字段保留为空以兼容旧版读取
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
        return false
    end
    -- 基本合法性检查：JSON 至少应该以 { 开头且长度合理
    if type(jsonStr) ~= "string" or #jsonStr < 50 or jsonStr:sub(1, 1) ~= "{" then
        log:Write(LOG_ERROR, "[Save] Invalid JSON output, len=" .. tostring(jsonStr and #jsonStr or 0))
        return false
    end

    -- 原子写入流程：先写临时文件 → 验证 → 备份旧文件 → 替换
    local writeOk, writeErr = SafeWriteFile(SAVE_TEMP, jsonStr)
    if not writeOk then
        log:Write(LOG_ERROR, "[Save] Temp write failed: " .. tostring(writeErr))
        if AddLog then AddLog("⚠️ 存档写入失败，请检查存储空间") end
        return false
    end

    -- 备份当前存档（如果存在）
    if fileSystem:FileExists(SAVE_FILE) then
        local oldFile = File(SAVE_FILE, FILE_READ)
        if oldFile:IsOpen() then
            local oldContent = oldFile:ReadString()
            oldFile:Close()
            if #oldContent > 50 then
                SafeWriteFile(SAVE_BACKUP, oldContent)
            end
        end
    end

    -- 将临时文件内容写入正式存档
    local finalOk, finalErr = SafeWriteFile(SAVE_FILE, jsonStr)
    if not finalOk then
        log:Write(LOG_ERROR, "[Save] Final write failed: " .. tostring(finalErr))
        if AddLog then AddLog("⚠️ 存档保存失败") end
        return false
    end

    print("[Save] Game saved. Day=" .. playerData_.day .. " size=" .. #jsonStr)
    if AddLog and playerData_ then
        AddLog("💾 进度已自动保存（第" .. (playerData_.day or 1) .. "天）")
    end
    return true
end

--- 检查是否有存档（主存档或备份都算）
function HasSaveFile()
    return fileSystem:FileExists(SAVE_FILE) or fileSystem:FileExists(SAVE_BACKUP)
end

--- 尝试从指定文件读取并解析存档
local function TryLoadFile(filename)
    if not fileSystem:FileExists(filename) then return nil, "not found" end
    local file = File(filename, FILE_READ)
    if not file:IsOpen() then return nil, "cannot open" end
    local content = file:ReadString()
    file:Close()
    if not content or #content < 10 then return nil, "empty file" end
    local ok, data = pcall(cjson.decode, content)
    if not ok or type(data) ~= "table" then return nil, "decode failed: " .. tostring(data) end
    if not data.playerData then return nil, "missing playerData" end
    return data
end

--- 加载游戏进度
function LoadGame()
    -- 先尝试主存档，失败则自动回退到备份
    local data, err = TryLoadFile(SAVE_FILE)
    if not data then
        print("[Save] Primary load failed: " .. tostring(err) .. ", trying backup...")
        data, err = TryLoadFile(SAVE_BACKUP)
        if not data then
            print("[Save] Backup load also failed: " .. tostring(err))
            return false
        end
        print("[Save] Loaded from backup successfully!")
        if AddLog then AddLog("⚠️ 主存档损坏，已从备份恢复") end
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
        playerData_.npcStoryProgress = playerData_.npcStoryProgress or {}
        -- 补全新增NPC进度键（兼容旧存档）
        for _, npc in ipairs({"kofi", "grace", "snake", "ada", "dj_pulse", "mama_b"}) do
            playerData_.npcStoryProgress[npc] = playerData_.npcStoryProgress[npc] or 0
        end
        -- ── 新系统字段兜底（v11+ 子系统） ──
        playerData_.aelTier = playerData_.aelTier or 0
        playerData_.weeklyWins = playerData_.weeklyWins or 0
        playerData_.weeklyTrainCount = playerData_.weeklyTrainCount or 0
        playerData_.weeklyIncome = playerData_.weeklyIncome or 0
        playerData_.weeklyRepGain = playerData_.weeklyRepGain or 0
        playerData_.weeklyWinStreak = playerData_.weeklyWinStreak or 0
        playerData_.achievements = playerData_.achievements or {}
        playerData_.mailbox = playerData_.mailbox or {}
        playerData_.eggsTriggered = playerData_.eggsTriggered or {}
        playerData_.eggCounters = playerData_.eggCounters or {}
        playerData_.eggPrestigeCount = playerData_.eggPrestigeCount or 0
        playerData_.linkagesClaimed = playerData_.linkagesClaimed or {}
        playerData_.chapterCompleted = playerData_.chapterCompleted or {}
        playerData_.dailyGreetingShownDay = playerData_.dailyGreetingShownDay or 0
        playerData_.unlocksNotified = playerData_.unlocksNotified or {}
        if playerData_.loginStreakClaimed == nil then playerData_.loginStreakClaimed = false end
        playerData_.marketFreeDraws = playerData_.marketFreeDraws or 0
        playerData_.decoSlots = playerData_.decoSlots or {}
        playerData_.decoSlotsMax = playerData_.decoSlotsMax or 3
        playerData_.nearBankruptCount = playerData_.nearBankruptCount or 0
        playerData_.questStreak = playerData_.questStreak or 0
        playerData_.dayHistory = playerData_.dayHistory or {}
        playerData_.cityFacilities = playerData_.cityFacilities or {}
        if playerData_.strategyChosen == nil then playerData_.strategyChosen = false end
        if playerData_.overtimeUsedToday == nil then playerData_.overtimeUsedToday = false end
        playerData_.endOfDayDurPenalty = playerData_.endOfDayDurPenalty or 0
    end

    -- 恢复队员
    if data.teamMembers then
        teamMembers_ = data.teamMembers
        -- 兼容旧存档：确保每个队员核心字段不为 nil
        for _, m in ipairs(teamMembers_) do
            m.mood = m.mood or 50
            m.skill = m.skill or 0
            m.talent = m.talent or 50
        end
    end

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
                local decOk, dec = pcall(evt.decision)
                if decOk and dec then
                    pendingChatDecision_ = { eventId = evt.id, question = dec.question, options = dec.options }
                else
                    print("[Save] Failed to rebuild pendingChatDecision for event: " .. tostring(evt.id))
                end
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

    -- 恢复集市摊贩支线故事进度
    marketStoryProgress_ = data.marketStoryProgress or {}
    marketStoryCompleted_ = data.marketStoryCompleted or {}
    marketStoryLastDay_ = data.marketStoryLastDay or {}
    marketStoryCrossCompleted_ = data.marketStoryCrossCompleted or {}

    -- 旧存档迁移：unlockedAchievements → playerData_.achievements
    -- 新系统把成就存在 playerData_.achievements 中，旧字段如有数据则合并
    if data.unlockedAchievements and next(data.unlockedAchievements) then
        playerData_.achievements = playerData_.achievements or {}
        for id, v in pairs(data.unlockedAchievements) do
            if v then playerData_.achievements[id] = true end
        end
    end
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

    -- ======== 修复 JSON 数字 key 反序列化问题 ========
    -- cjson.decode 会把数字 key 还原为数字（在 lua-cjson 2.1+ 中），
    -- 但某些 sparse table（如 marketEquipped/decoSlots）可能混用字符串 key。
    -- 统一修复：将字符串数字 key 转为真正的数字 key。
    local function fixNumericKeys(tbl)
        if type(tbl) ~= "table" then return tbl end
        local fixed = {}
        local needsFix = false
        for k, v in pairs(tbl) do
            local numK = tonumber(k)
            if numK and type(k) == "string" then
                fixed[numK] = v
                needsFix = true
            else
                fixed[k] = v
            end
        end
        if needsFix then
            -- 清空原表并写回修复后的数据
            for k in pairs(tbl) do tbl[k] = nil end
            for k, v in pairs(fixed) do tbl[k] = v end
        end
        return tbl
    end

    -- 修复已知使用数字 key 的字段
    if playerData_.marketEquipped then
        fixNumericKeys(playerData_.marketEquipped)
    end
    if playerData_.decoSlots then
        fixNumericKeys(playerData_.decoSlots)
    end
    if playerData_.tierWins then
        fixNumericKeys(playerData_.tierWins)
    end
    if playerData_.tournamentTierWins then
        fixNumericKeys(playerData_.tournamentTierWins)
    end
    if playerData_.seasonRewards then
        fixNumericKeys(playerData_.seasonRewards)
    end

    -- ======== 二手市场字段兼容（确保 Validate 不会清空已有数据）========
    if Market and Market.Validate then
        Market.Validate(playerData_)
    end
    if Market and Market.ValidateFacility then
        Market.ValidateFacility(playerData_)
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

    -- 恢复候选池：用当前城市重建完整池后，按保存的名字过滤出剩余候选人
    local currentCity = playerData_.currentCity or "wakandaville"
    if data.candidateNames then
        InitCandidatePool(currentCity)  -- 先按当前城市重建完整候选池
        local nameSet = {}
        for _, n in ipairs(data.candidateNames) do nameSet[n] = true end
        local newPool = {}
        for _, c in ipairs(CANDIDATE_POOL) do
            if nameSet[c.name] then table.insert(newPool, c) end
        end
        CANDIDATE_POOL = newPool
    else
        -- 旧存档无 candidateNames 字段：直接按城市初始化完整池
        InitCandidatePool(currentCity)
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
        playerData_.npcStoryProgress = playerData_.npcStoryProgress or {}
        for _, npc in ipairs({"kofi", "grace", "snake", "ada", "dj_pulse", "mama_b"}) do
            playerData_.npcStoryProgress[npc] = playerData_.npcStoryProgress[npc] or 0
        end
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
    if playerData_.lastSaveTimestamp and playerData_.lastSaveTimestamp > 0 and Retention then
        local offOk, offErr = pcall(function()
            local offlineSeconds = os.time() - playerData_.lastSaveTimestamp
            local reward = Retention.CalculateOfflineEarnings(offlineSeconds)
            if reward then
                pendingOfflineReward_ = reward
                print("[Save] Offline earnings pending: $" .. tostring(reward.earnings) .. " (" .. tostring(reward.hours) .. "h)")
            end
        end)
        if not offOk then
            print("[Save] Offline earnings calc error (non-fatal): " .. tostring(offErr))
        end
    end

    print("[Save] Game loaded. Day=" .. tostring(playerData_.day) .. ", Chapter=" .. tostring(currentChapter_))
    return true
end

-- ============================================================================
-- 自动存档：应用挂起/切后台/定时保存
-- ============================================================================
local AUTO_SAVE_INTERVAL = 30  -- 每30秒自动存档一次
local autoSaveTimer_ = 0

--- 在 HandleUpdate 中调用，实现定时自动存档
function AutoSaveUpdate(dt)
    -- 仅在游戏进行中（非标题/非对话）时自动存档
    if not playerData_ or currentPhase_ == PHASE_TITLE then return end
    autoSaveTimer_ = autoSaveTimer_ + dt
    if autoSaveTimer_ >= AUTO_SAVE_INTERVAL then
        autoSaveTimer_ = 0
        local ok, err = pcall(SaveGame)
        if not ok then
            log:Write(LOG_ERROR, "[AutoSave] error: " .. tostring(err))
        end
    end
end

--- 重置自动存档计时器（在手动存档后调用，避免重复存储）
function ResetAutoSaveTimer()
    autoSaveTimer_ = 0
end

