---@diagnostic disable: undefined-global
-- ============================================================================
-- 13. 经营界面（带背景图）
-- ============================================================================
function BuildManageTabBar()
    local tabs = {
        { key = "action",  label = "经营" },
        { key = "upgrade", label = "升级" },
        { key = "team",    label = "团队" },
        { key = "market",  label = "市场" },
        { key = "ranking", label = "排行榜" },
    }
    local tabChildren = {}
    for _, t in ipairs(tabs) do
        local isActive = (manageTab_ == t.key)
        table.insert(tabChildren, UI.Button {
            text = t.label, fontSize = 13, fontWeight = isActive and "bold" or "normal",
            height = 44, flex = 1,
            backgroundColor = { 0, 0, 0, 0 },
            fontColor = isActive and C.text or C.textLight,
            borderRadius = 0,
            borderWidth = isActive and { 0, 0, 2, 0 } or 0,
            borderColor = isActive and C.accent or nil,
            onClick = function()
                if manageTab_ ~= t.key then PlaySFX("page_turn") end
                manageTab_ = t.key
                BuildUI()
            end,
        })
    end
    return UI.Panel {
        width = "100%", flexDirection = "row",
        backgroundColor = C.tabBg,
        borderBottomWidth = 1, borderColor = C.tabBorder,
        children = tabChildren,
    }
end

--- 全面验证 playerData_ 字段完整性（防止旧存档缺字段导致 nil 崩溃）
function ValidatePlayerData()
    local p = playerData_
    if not p then
        log:Write(LOG_ERROR, "[Validate] playerData_ is nil! Resetting to defaults.")
        playerData_ = {
            money = 5000, reputation = 0, day = 1, cafeName = "Dragon Net Cafe",
            computers = 3, chairLevel = 1, netSpeed = 1, acLevel = 0,
            solarLevel = 0, foodShop = 0, decoLevel = 0, securityLevel = 0,
            havocCoins = 0, totalRuns = 0, actionPoints = 3, karma = 0,
            friendlyWins = 0, friendlyLosses = 0, debt = 0, debtDay = 0,
            equipCondition = 100, matchTier = 1, tierWins = { 0, 0, 0 },
            generatorLevel = 0, fuel = 0, fuelCapacity = 0,
            branches = {}, totalEarnings = 0,
            seasonId = 1, seasonWins = 0, seasonRewards = {},
        }
        return
    end
    -- 核心字段（算术运算直接使用，nil 会崩溃）
    p.money = p.money or 5000
    p.reputation = p.reputation or 0
    p.day = p.day or 1
    p.cafeName = p.cafeName or "Dragon Net Cafe"
    p.computers = p.computers or 3
    p.chairLevel = p.chairLevel or 1
    p.netSpeed = p.netSpeed or 1
    p.acLevel = p.acLevel or 0
    p.solarLevel = p.solarLevel or 0
    p.foodShop = p.foodShop or 0
    p.decoLevel = p.decoLevel or 0
    p.securityLevel = p.securityLevel or 0
    p.havocCoins = p.havocCoins or 0
    p.totalRuns = p.totalRuns or 0
    p.actionPoints = p.actionPoints or 3
    p.karma = p.karma or 0
    p.friendlyWins = p.friendlyWins or 0
    p.friendlyLosses = p.friendlyLosses or 0
    p.debt = p.debt or 0
    p.debtDay = p.debtDay or 0
    p.equipCondition = p.equipCondition or 100
    p.matchTier = p.matchTier or 1
    p.tierWins = p.tierWins or { 0, 0, 0 }
    p.generatorLevel = p.generatorLevel or 0
    p.fuel = p.fuel or 0
    p.fuelCapacity = p.fuelCapacity or 0
    p.branches = p.branches or {}
    p.totalEarnings = p.totalEarnings or 0
    p.seasonId = p.seasonId or 1
    p.seasonWins = p.seasonWins or 0
    p.seasonRewards = p.seasonRewards or {}
    p.goldOunces = p.goldOunces or 0
    p.coupDaysLeft = p.coupDaysLeft or 0
    if p.goldSafe == nil then p.goldSafe = false end
    if p.goldVIP == nil then p.goldVIP = false end
    p.wellLevel = p.wellLevel or 0
    p.roadLevel = p.roadLevel or 0
    p.coffeeLevel = p.coffeeLevel or 0
    p.jukeboxLevel = p.jukeboxLevel or 0
    p.tournamentWins = p.tournamentWins or 0
    p.tournamentPlayed = p.tournamentPlayed or 0
    p.tournamentTierWins = p.tournamentTierWins or {}
    -- 确保 tierWins 有 3 个元素
    for i = 1, 3 do
        p.tierWins[i] = p.tierWins[i] or 0
    end
    -- ── RetentionV2 字段（旧存档兼容） ──
    p.microEventsUsed = p.microEventsUsed or {}
    p.microEventsToday = p.microEventsToday or 0
    p.freeMiniGamesToday = p.freeMiniGamesToday or 0
    p.miniGameStreak = p.miniGameStreak or 0
    p.adAPRecoverToday = p.adAPRecoverToday or 0
    p.baseAP = p.baseAP or 3
    p.apBonus = p.apBonus or 0
    p.loginStreak = p.loginStreak or 0
    if p.goldenHourActive == nil then p.goldenHourActive = false end
    if p.goldenHourTriggered == nil then p.goldenHourTriggered = false end
    p.goldenHourActions = p.goldenHourActions or 0
    p.goldenHourMaxActions = p.goldenHourMaxActions or 3
    if p.freeMatchToday == nil then p.freeMatchToday = false end
    p.matchMicroOpsUsed = p.matchMicroOpsUsed or 0
    p.seasonPassPoints = p.seasonPassPoints or 0
    p.seasonPassClaimed = p.seasonPassClaimed or {}
    if p.rv2Day1Shown == nil then p.rv2Day1Shown = false end
    if p.rv2Day2Shown == nil then p.rv2Day2Shown = false end
    -- 里程碑标记
    if p.milestone_5pc == nil then p.milestone_5pc = false end
    if p.milestone_100rep == nil then p.milestone_100rep = false end
    if p.milestone_10k == nil then p.milestone_10k = false end
    if p.milestone_3team == nil then p.milestone_3team = false end
    if p.milestone_first_champ == nil then p.milestone_first_champ = false end
    if p.milestone_branch == nil then p.milestone_branch = false end
    -- ── 二手市场字段（旧存档兼容） ──
    p.marketInventory   = p.marketInventory   or {}
    p.marketEquipped    = p.marketEquipped    or {}
    p.marketSlots       = p.marketSlots       or 3
    p.marketPityCounter = p.marketPityCounter or 0
    p.marketTotalPulls  = p.marketTotalPulls  or 0
    p.marketNextUID     = p.marketNextUID     or 1
    if p.marketDailyFree == nil then p.marketDailyFree = false end
    -- 验证分店数据完整性
    for i, br in ipairs(p.branches) do
        br.name = br.name or ("分店" .. i)
        br.location = br.location or "未知"
        br.locationId = br.locationId or "unknown"
        br.locationEmoji = br.locationEmoji or "🏪"
        br.gameType = br.gameType or "csgo"
        br.gameName = br.gameName or "CS:GO"
        br.gameEmoji = br.gameEmoji or "🎮"
        br.bonusType = br.bonusType or "traffic"
        br.bonusDesc = br.bonusDesc or ""
        br.gameBonusType = br.gameBonusType or "combat"
        br.gameBonusDesc = br.gameBonusDesc or ""
        br.income = br.income or 40
        br.day = br.day or p.day
    end
    -- 验证队员数据完整性
    if teamMembers_ then
        for i, m in ipairs(teamMembers_) do
            m.name = m.name or ("队员" .. i)
            m.emoji = m.emoji or "🧑"
            m.trait = m.trait or "未知"
            m.talent = m.talent or 30
            m.skill = m.skill or 10
            m.mood = m.mood or 60
            m.fee = m.fee or 30
            m.perkBonus = m.perkBonus or 0
            m.flawPenalty = m.flawPenalty or 0
        end
    else
        teamMembers_ = {}
    end
end

-- ============================================================================
-- 日记页面：按天倒序展示每日氛围描写 + 事件日志
-- ============================================================================
function BuildDiaryPage()
    local currentDay = playerData_.day or 1

    -- 收集所有有记录的天数并倒序排列
    local days = {}
    for d, _ in pairs(diaryEntries_) do
        table.insert(days, d)
    end
    table.sort(days, function(a, b) return a > b end)

    -- 如果当天还没有日记条目，先创建占位
    if not diaryEntries_[currentDay] then
        diaryEntries_[currentDay] = { atmo = cachedAtmoText_ or "", logs = {} }
        if not days[1] or days[1] ~= currentDay then
            table.insert(days, 1, currentDay)
        end
    end

    if #days == 0 then
        return UI.Panel {
            width = "100%", padding = 16, alignItems = "center",
            children = {
                UI.Label { text = "店长日记", fontSize = 18, fontColor = C.accent },
                UI.Label { text = "还没有日记记录\n经营网吧后这里会记录每天的故事", fontSize = 13, fontColor = C.textDim, whiteSpace = "normal" },
            },
        }
    end

    local dayCards = {}

    -- 标题
    table.insert(dayCards, UI.Panel {
        width = "100%", paddingHorizontal = 4, paddingBottom = 4,
        flexDirection = "row", alignItems = "center", justifyContent = "space-between",
        children = {
            UI.Label { text = "店长日记", fontSize = 16, fontColor = C.accent },
            UI.Label { text = "共 " .. #days .. " 天", fontSize = 12, fontColor = C.textDim },
        },
    })

    for _, day in ipairs(days) do
        local entry = diaryEntries_[day]
        local isToday = (day == currentDay)
        local isExpanded = expandedDiaryDays_[day] == true

        -- 日期标题
        local dayTitle = "第 " .. day .. " 天"
        if isToday then dayTitle = dayTitle .. "（今天）" end

        -- 摘要：取氛围文字前30字 + 日志条数
        local summary = ""
        if entry.atmo and entry.atmo ~= "" then
            local atmoPreview = entry.atmo
            -- 截取前30个UTF-8字符作为摘要
            local charCount = 0
            local bytePos = 1
            while charCount < 30 and bytePos <= #atmoPreview do
                local b = string.byte(atmoPreview, bytePos)
                if b < 128 then bytePos = bytePos + 1
                elseif b < 224 then bytePos = bytePos + 2
                elseif b < 240 then bytePos = bytePos + 3
                else bytePos = bytePos + 4 end
                charCount = charCount + 1
            end
            if bytePos <= #atmoPreview then
                summary = string.sub(atmoPreview, 1, bytePos - 1) .. "…"
            else
                summary = atmoPreview
            end
        else
            summary = isToday and "今天的故事还在书写中……" or "平淡的一天"
        end
        local logCount = (entry.logs and #entry.logs) or 0
        local logHint = logCount > 0 and ("  " .. logCount .. "条记录") or ""

        -- 卡片颜色
        local cardBg = isToday and C.diary_today or C.diary_past
        local borderCol = isToday and { C.accent[1], C.accent[2], C.accent[3], 80 } or C.border

        -- 构建卡片子元素
        local cardChildren = {}

        -- 日期头 + 展开/收起按钮（一行）
        local dayNum = day  -- 闭包捕获
        table.insert(cardChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            justifyContent = "space-between",
            children = {
                UI.Panel {
                    flexDirection = "row", alignItems = "center", gap = 6, flex = 1,
                    children = {
                        UI.Label {
                            text = isToday and "●" or "○",
                            fontSize = 14,
                        },
                        UI.Label {
                            text = dayTitle,
                            fontSize = 14, fontWeight = "bold",
                            fontColor = isToday and C.accent or C.textDim,
                        },
                    },
                },
                UI.Button {
                    text = isExpanded and "▲ 收起" or "▼ 展开",
                    variant = "text",
                    fontSize = 11,
                    fontColor = C.accent,
                    paddingHorizontal = 8, paddingVertical = 2,
                    onClick = function()
                        expandedDiaryDays_[dayNum] = not expandedDiaryDays_[dayNum]
                        BuildUI()
                    end,
                },
            },
        })

        if isExpanded then
            -- ==== 展开状态：显示完整内容 ====
            local contentChildren = {}

            -- 氛围描写
            if entry.atmo and entry.atmo ~= "" then
                table.insert(contentChildren, UI.Label {
                    text = entry.atmo,
                    fontSize = 13, fontColor = C.text,
                    whiteSpace = "normal", lineHeight = 1.6, width = "100%",
                })
            end

            -- 事件日志
            if entry.logs and #entry.logs > 0 then
                if entry.atmo and entry.atmo ~= "" then
                    table.insert(contentChildren, UI.Panel {
                        width = "100%", height = 1, marginVertical = 6,
                        backgroundColor = { 210, 180, 140, 60 },
                    })
                end
                for _, logText in ipairs(entry.logs) do
                    table.insert(contentChildren, UI.Label {
                        text = logText,
                        fontSize = 12, fontColor = C.textDim,
                        whiteSpace = "normal", lineHeight = 1.4, width = "100%",
                    })
                end
            end

            if #contentChildren == 0 then
                table.insert(contentChildren, UI.Label {
                    text = isToday and "今天的故事还在书写中……" or "平淡的一天，没有特别的事发生。",
                    fontSize = 12, fontColor = C.textDim, whiteSpace = "normal",
                })
            end

            table.insert(cardChildren, UI.Panel {
                width = "100%", gap = 4, paddingLeft = 4, paddingTop = 4,
                children = contentChildren,
            })
        else
            -- ==== 收起状态：只显示一行摘要 ====
            table.insert(cardChildren, UI.Label {
                text = summary .. logHint,
                fontSize = 12, fontColor = C.textDim,
                whiteSpace = "nowrap",
                paddingLeft = 4, paddingTop = 2,
            })
        end

        table.insert(dayCards, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = cardBg, borderRadius = 10,
            borderWidth = 1, borderColor = borderCol,
            boxShadow = isToday and { { x = 0, y = 2, blur = 12, color = { C.accent[1], C.accent[2], C.accent[3], 40 } } } or nil,
            children = cardChildren,
        })
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 8,
        backgroundColor = C.card, borderRadius = 12,
        borderWidth = 1, borderColor = C.border,
        children = dayCards,
    }
end

-- ============================================================================
-- 人物页面：展示已遇到的 NPC 及其事迹（保留函数，不再在 Tab 中展示）
-- ============================================================================
function BuildPeoplePage()
    -- 预计算每个 NPC 可触发的不同事件标题数（用于判断故事是否完整）
    local npcTotalEvents = {}  -- npcId → { title1=true, title2=true, ... }
    for title, ids in pairs(EVENT_NPC_MAP) do
        local idList = (type(ids) == "string") and { ids } or ids
        for _, npcId in ipairs(idList) do
            if not npcTotalEvents[npcId] then npcTotalEvents[npcId] = {} end
            npcTotalEvents[npcId][title] = true
        end
    end

    -- 统计
    local metCount = 0
    local fullCount = 0

    -- 构建卡片
    local npcCards = {}
    for _, profile in ipairs(NPC_PROFILES) do
        local journal = npcJournal_[profile.id]
        local isMet = journal ~= nil and #journal.events > 0

        -- 计算已触发的不同事件标题
        local seenTitles = {}
        if journal then
            for _, ev in ipairs(journal.events) do
                seenTitles[ev.title] = true
            end
        end
        local seenCount = 0
        for _ in pairs(seenTitles) do seenCount = seenCount + 1 end

        -- 该 NPC 总共有几种事件
        local totalKinds = 0
        if npcTotalEvents[profile.id] then
            for _ in pairs(npcTotalEvents[profile.id]) do totalKinds = totalKinds + 1 end
        end

        local isFullStory = isMet and totalKinds > 0 and seenCount >= totalKinds

        if isMet then metCount = metCount + 1 end
        if isFullStory then fullCount = fullCount + 1 end

        if isMet then
            -- ====== 已相遇：完整卡片 ======
            local eventCount = #journal.events

            -- 状态徽章
            local badge, badgeColor, badgeBg
            if isFullStory then
                badge = "✦ 故事完整"
                badgeColor = { 255, 215, 0, 255 }
                badgeBg = { 255, 200, 0, 30 }
            else
                badge = "已相遇 " .. seenCount .. "/" .. totalKinds
                badgeColor = C.green
                badgeBg = { C.green[1], C.green[2], C.green[3], 25 }
            end

            -- 构建事迹列表（最近 5 条）
            local eventItems = {}
            local startIdx = math.max(1, eventCount - 4)
            for i = startIdx, eventCount do
                local ev = journal.events[i]
                local line = "第" .. ev.day .. "天 · " .. ev.title
                if ev.choice then
                    line = line .. " → " .. string.gsub(ev.choice, "^[%S]+ ", "")
                end
                table.insert(eventItems, UI.Label {
                    text = "  · " .. line,
                    fontSize = 11, fontColor = { C.blue[1], C.blue[2], C.blue[3], 200 },
                    whiteSpace = "normal", width = "100%",
                })
            end
            if startIdx > 1 then
                table.insert(eventItems, 1, UI.Label {
                    text = "  ...还有 " .. (startIdx - 1) .. " 条更早的记录",
                    fontSize = 10, fontColor = C.textDim,
                })
            end

            table.insert(npcCards, UI.Panel {
                width = "100%", padding = 10, gap = 4,
                backgroundColor = isFullStory and { 255, 215, 0, 10 } or { 255, 255, 255, 15 },
                borderRadius = 8,
                borderWidth = isFullStory and 1 or 0,
                borderColor = isFullStory and { 255, 215, 0, 40 } or { 0, 0, 0, 0 },
                children = {
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                        children = {
                            UI.Label { text = profile.emoji, fontSize = 22 },
                            UI.Panel {
                                flex = 1, gap = 1,
                                children = {
                                    UI.Panel {
                                        flexDirection = "row", alignItems = "center", gap = 6,
                                        children = {
                                            UI.Label { text = profile.name, fontSize = 14, fontColor = C.text },
                                            UI.Label { text = profile.role, fontSize = 10, fontColor = C.accent,
                                                backgroundColor = { 240, 180, 80, 30 }, paddingLeft = 4, paddingRight = 4,
                                                paddingTop = 1, paddingBottom = 1, borderRadius = 4 },
                                        },
                                    },
                                    UI.Label { text = profile.bio, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                                },
                            },
                            UI.Label { text = badge, fontSize = 10, fontColor = badgeColor,
                                backgroundColor = badgeBg, paddingLeft = 5, paddingRight = 5,
                                paddingTop = 2, paddingBottom = 2, borderRadius = 6 },
                        },
                    },
                    UI.Panel {
                        width = "100%", gap = 2, marginTop = 4,
                        borderWidth = { 1, 0, 0, 0 }, borderColor = { 255, 255, 255, 20 },
                        paddingTop = 4,
                        children = eventItems,
                    },
                },
            })
        else
            -- ====== 未相遇：悬念卡片（展示线索刺激解锁欲望）======
            local teaseText = profile.tease or ("据说附近有一位" .. profile.role .. "，也许某天会出现……")
            local hintText = profile.hint or "持续经营，等待命运的安排"
            table.insert(npcCards, UI.Panel {
                width = "100%", padding = 10, gap = 6,
                backgroundColor = { 240, 180, 100, 15 },
                borderRadius = 8,
                borderWidth = 1, borderColor = { 210, 180, 130, 30 },
                children = {
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                        children = {
                            UI.Label { text = "?", fontSize = 22 },
                            UI.Panel {
                                flex = 1, gap = 1,
                                children = {
                                    UI.Panel {
                                        flexDirection = "row", alignItems = "center", gap = 6,
                                        children = {
                                            UI.Label { text = "???", fontSize = 14, fontColor = { 130, 130, 130, 200 } },
                                            UI.Label { text = profile.role, fontSize = 10, fontColor = { 130, 130, 130, 180 },
                                                backgroundColor = { 200, 210, 80, 20 }, paddingLeft = 4, paddingRight = 4,
                                                paddingTop = 1, paddingBottom = 1, borderRadius = 4 },
                                        },
                                    },
                                    UI.Label { text = teaseText, fontSize = 11, fontColor = { 120, 120, 120, 160 },
                                        whiteSpace = "normal", fontStyle = "italic" },
                                },
                            },
                            UI.Label { text = "锁", fontSize = 16, fontColor = { 160, 140, 110, 120 } },
                        },
                    },
                    UI.Panel {
                        width = "100%", paddingTop = 4, paddingLeft = 30,
                        borderWidth = { 1, 0, 0, 0 }, borderColor = { 230, 170, 80, 20 },
                        children = {
                            UI.Label { text = "" .. hintText, fontSize = 10, fontColor = { 160, 140, 100, 120 },
                                whiteSpace = "normal" },
                        },
                    },
                },
            })
        end
    end

    -- 底部统计
    table.insert(npcCards, UI.Panel {
        width = "100%", alignItems = "center", paddingTop = 8, gap = 2,
        children = {
            UI.Label {
                text = "已相遇 " .. metCount .. "/" .. #NPC_PROFILES .. " 位居民   ✦ 故事完整 " .. fullCount .. "/" .. #NPC_PROFILES,
                fontSize = 11, fontColor = C.textDim,
            },
            metCount >= #NPC_PROFILES and fullCount >= #NPC_PROFILES and UI.Label {
                text = "你改变了瓦坎达维尔每一个人的生活！",
                fontSize = 12, fontColor = { 255, 215, 0, 220 },
            } or UI.Panel { height = 0 },
        },
    })

    -- 标题
    table.insert(npcCards, 1, UI.Panel {
        width = "100%", alignItems = "center", paddingBottom = 4,
        children = {
            UI.Label { text = "人物志 · 瓦坎达维尔的人们", fontSize = 16, fontColor = C.accent },
            UI.Label { text = "你在这片土地上遇到的每一个人，都因你而不同。", fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
        },
    })

    return UI.Panel {
        width = "100%", gap = 8,
        children = npcCards,
    }
end

-- ── 独立面板：赛季通行证（原RV2方案10，移至升级Tab） ──
local function BuildSeasonPassPanel()
    if not RV2 then return nil end
    local sp = RV2.GetSeasonPassStatus()
    if sp.points <= 0 and (playerData_.day or 1) < 3 then return nil end
    local rewardItems = {}
    for _, r in ipairs(sp.rewards) do
        local claimed = sp.claimedRewards[tostring(r.points)]
        local canClaim = not claimed and sp.points >= r.points
        table.insert(rewardItems, UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 6,
            width = "100%", padding = 4,
            backgroundColor = canClaim and { 80, 160, 80, 60 } or { 0, 0, 0, 0 },
            borderRadius = 6,
            children = {
                UI.Label { text = r.icon, fontSize = 16, width = 24 },
                UI.Label { text = r.points .. "分", fontSize = 12, fontColor = C.textLight, width = 36 },
                UI.Label { text = r.desc, fontSize = 12, fontColor = claimed and C.textDim or C.text, flex = 1 },
                claimed and UI.Label { text = "✅", fontSize = 14 }
                    or (canClaim and UI.Button {
                        text = "领取", fontSize = 11, height = 28, width = 48,
                        variant = "primary",
                        onClick = function()
                            local msg = RV2.ClaimSeasonPassReward(r.points)
                            if msg then AddLog(msg) end
                            BuildUI()
                        end,
                    } or UI.Label { text = "🔒", fontSize = 14 }),
            },
        })
    end
    return UI.Panel {
        width = "100%", padding = 10, borderRadius = 10,
        backgroundColor = { 40, 40, 65, 180 },
        borderWidth = 1, borderColor = { 120, 100, 200, 80 },
        gap = 6,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    UI.Label { text = "🏅 赛季通行证", fontSize = 15, fontWeight = "bold", fontColor = { 200, 180, 255, 240 } },
                    UI.Label { text = sp.points .. " 分", fontSize = 13, fontColor = { 255, 220, 100, 220 } },
                },
            },
            table.unpack(rewardItems),
        },
    }
end

-- ── 独立面板：免费迷你游戏（原RV2方案1，移至团队Tab） ──
local function BuildFreeMiniGamePanel()
    if not RV2 then return nil end
    local freePlays = RV2.GetFreeMiniGamePlays()
    if freePlays <= 0 then return nil end
    local streakText = (playerData_.miniGameStreak or 0) > 0
        and ("🔥 连胜 x" .. playerData_.miniGameStreak .. " 奖励加成！") or ""
    return UI.Panel {
        width = "100%", padding = 10, borderRadius = 10,
        backgroundColor = { 50, 40, 70, 180 },
        borderWidth = 1, borderColor = { 160, 120, 220, 80 },
        gap = 6,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    UI.Label { text = "🎮 免费小游戏", fontSize = 15, fontWeight = "bold", fontColor = { 180, 150, 255, 240 } },
                    UI.Label { text = "剩余 " .. freePlays .. " 次", fontSize = 12, fontColor = { 200, 200, 255, 200 } },
                },
            },
            UI.Label { text = "不消耗行动点！赢了获得50%奖励" .. (streakText ~= "" and (" · " .. streakText) or ""), fontSize = 12, fontColor = C.textLight, whiteSpace = "normal", width = "100%" },
            UI.Button {
                text = "🎲 开始免费训练", fontSize = 14, height = 40, width = "100%",
                variant = "primary",
                onClick = function()
                    if #teamMembers_ == 0 then
                        AddLog("⚠️ 需要至少1名队员才能训练！")
                        BuildUI()
                        return
                    end
                    if RV2.UseFreeMiniGamePlay() then
                        AddLog("🎮 开始免费训练！（不消耗行动点）")
                        playerData_.freeTrainMode = true
                        trainMember_ = teamMembers_[1]
                        trainMemberIdx_ = 1
                        trainPhase_ = "ready"
                        trainActive_ = false
                        trainMode_ = "select"
                        currentPhase_ = PHASE_TRAIN
                        PlayBGM("train")
                        BuildUI()
                    end
                end,
            },
        },
    }
end

-- ── 独立面板：团队羁绊（原RV2方案11，移至团队Tab） ──
local function BuildTeamBondPanel()
    if not RV2 or #teamMembers_ < 2 then return nil end
    local bonds = RV2.GetActiveBonds()
    if #bonds == 0 then return nil end
    local bondItems = {}
    for _, ab in ipairs(bonds) do
        table.insert(bondItems, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 6, borderRadius = 6,
            backgroundColor = { 60, 50, 50, 100 },
            children = {
                UI.Label { text = ab.member1.emoji .. "+" .. ab.member2.emoji, fontSize = 14, width = 50 },
                UI.Panel {
                    flex = 1, gap = 2,
                    children = {
                        UI.Label { text = ab.bond.name, fontSize = 13, fontWeight = "bold", fontColor = { 255, 180, 180, 240 } },
                        UI.Label { text = ab.member1.name .. " & " .. ab.member2.name .. " → " .. ab.bond.effectDesc, fontSize = 11, fontColor = C.textLight },
                    },
                },
            },
        })
    end
    return UI.Panel {
        width = "100%", padding = 10, borderRadius = 10,
        backgroundColor = { 50, 35, 40, 180 },
        borderWidth = 1, borderColor = { 200, 120, 120, 80 },
        gap = 6,
        children = {
            UI.Label { text = "💞 团队羁绊", fontSize = 15, fontWeight = "bold", fontColor = { 255, 160, 180, 240 }, width = "100%" },
            table.unpack(bondItems),
        },
    }
end

function BuildManageTabContent()
    -- 每次构建 UI 前验证数据完整性
    ValidatePlayerData()

    -- 防御性构建：逐个组件 pcall，精确定位崩溃点
    local function SafeBuild(name, fn)
        local ok, result = pcall(fn)
        if not ok then
            log:Write(LOG_ERROR, "[BuildManageTabContent] " .. name .. " crashed: " .. tostring(result))
            return UI.Label { text = "⚠️ " .. name .. " 加载失败", fontSize = 12, fontColor = { 255, 100, 100, 255 }, whiteSpace = "normal", width = "100%" }
        end
        return result
    end

    if manageTab_ == "action" then
        local actionChildren = {}
        -- 政变期间顶部显示醒目警告横幅
        if IsCoupActive() then
            table.insert(actionChildren, UI.Panel {
                width = "100%", padding = 10, borderRadius = 10,
                backgroundColor = { 200, 85, 60, 220 },
                borderWidth = 2, borderColor = { 255, 60, 60, 150 },
                gap = 4,
                children = {
                    UI.Label { text = "军事政变进行中！", fontSize = 16, fontColor = { 255, 80, 80, 255 }, fontWeight = "bold", textAlign = "center", width = "100%" },
                    UI.Label { text = "剩余 " .. playerData_.coupDaysLeft .. " 天 · 所有消费仅接受黄金支付", fontSize = 13, fontColor = { 255, 200, 150, 220 }, textAlign = "center", width = "100%" },
                    UI.Label {
                        text = "现金被冻结 | 黄金持仓: " .. string.format("%.1f", playerData_.goldOunces or 0) .. "oz | 金价: $" .. GetGoldPrice() .. "/oz",
                        fontSize = 12, fontColor = { 255, 215, 0, 200 }, textAlign = "center", width = "100%",
                    },
                },
            })
        end
        table.insert(actionChildren, SafeBuild("ActionCard", BuildActionCard))
        local sponsorPanel = SafeBuild("SponsorCenter", BuildSponsorCenter)
        if sponsorPanel then table.insert(actionChildren, sponsorPanel) end

        -- 留存系统：目标链进度卡片 + 周期性大事件指示器
        local retentionPanel = SafeBuild("RetentionCards", function()
            local cards = {}

            -- 目标链进度卡片
            if Retention and Retention.GetCurrentGoals then
                local goals = Retention.GetCurrentGoals()
                if goals and #goals > 0 then
                    local CHAIN_ICONS = { develop = "🏗️", social = "🤝", wealth = "💰" }
                    local CHAIN_COLORS = {
                        develop = { 70, 160, 230, 40 },
                        social  = { 230, 160, 70, 40 },
                        wealth  = { 70, 200, 120, 40 },
                    }
                    local goalItems = {}
                    for _, g in ipairs(goals) do
                        local icon = CHAIN_ICONS[g.chainId] or "🎯"
                        local barColor = CHAIN_COLORS[g.chainId] or { 150, 150, 150, 60 }
                        local pct = g.total > 0 and (g.progress / g.total) or 0
                        local progressText = g.done and "✅ 全部完成" or (g.progress .. "/" .. g.total)
                        local rewardText = ""
                        if not g.done then
                            local parts = {}
                            if g.rewardMoney and g.rewardMoney > 0 then table.insert(parts, "$" .. g.rewardMoney) end
                            if g.rewardRep and g.rewardRep > 0 then table.insert(parts, "+" .. g.rewardRep .. "声望") end
                            if #parts > 0 then rewardText = "奖励: " .. table.concat(parts, " ") end
                        end
                        table.insert(goalItems, UI.Panel {
                            width = "100%", padding = 8, borderRadius = 8,
                            backgroundColor = barColor, gap = 3,
                            children = {
                                UI.Panel {
                                    width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                                    children = {
                                        UI.Label { text = icon .. " " .. g.chainName, fontSize = 13, fontWeight = "bold", fontColor = { 255, 255, 255, 230 } },
                                        UI.Label { text = progressText, fontSize = 11, fontColor = { 255, 255, 255, 180 } },
                                    },
                                },
                                UI.Label { text = g.goalDesc, fontSize = 12, fontColor = { 255, 255, 255, 200 }, whiteSpace = "normal", width = "100%" },
                                -- 进度条
                                UI.Panel {
                                    width = "100%", height = 4, borderRadius = 2,
                                    backgroundColor = { 0, 0, 0, 60 },
                                    children = {
                                        UI.Panel {
                                            width = math.floor(pct * 100) .. "%", height = 4, borderRadius = 2,
                                            backgroundColor = g.done and { 100, 220, 100, 220 } or { 255, 220, 100, 220 },
                                        },
                                    },
                                },
                                rewardText ~= "" and UI.Label { text = rewardText, fontSize = 11, fontColor = { 255, 215, 100, 200 } } or nil,
                            },
                        })
                    end
                    table.insert(cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = 10,
                        backgroundColor = { 40, 40, 60, 180 },
                        borderWidth = 1, borderColor = { 255, 220, 100, 60 },
                        gap = 6,
                        children = {
                            UI.Label { text = "🎯 目标挑战", fontSize = 15, fontWeight = "bold", fontColor = { 255, 220, 100, 240 }, width = "100%" },
                            table.unpack(goalItems),
                        },
                    })
                end
            end

            -- 周期性大事件指示器
            if Retention then
                local active = Retention.GetActivePeriodicEvent and Retention.GetActivePeriodicEvent()
                if active then
                    -- 活跃的周期事件
                    table.insert(cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = 10,
                        backgroundColor = { 180, 60, 60, 140 },
                        borderWidth = 1, borderColor = { 255, 100, 100, 100 },
                        gap = 4,
                        children = {
                            UI.Label { text = "⚡ " .. (active.name or "特殊事件") .. " 进行中", fontSize = 14, fontWeight = "bold", fontColor = { 255, 180, 100, 255 }, width = "100%" },
                            UI.Label { text = active.desc or "", fontSize = 12, fontColor = { 255, 255, 255, 200 }, whiteSpace = "normal", width = "100%" },
                            active.remainDays and UI.Label { text = "剩余 " .. active.remainDays .. " 天", fontSize = 12, fontColor = { 255, 200, 150, 200 } } or nil,
                        },
                    })
                else
                    -- 下一个周期事件倒计时
                    local nextEvent = Retention.GetNextPeriodicEvent and Retention.GetNextPeriodicEvent(playerData_.day)
                    if nextEvent then
                        table.insert(cards, UI.Panel {
                            width = "100%", padding = 8, borderRadius = 8,
                            backgroundColor = { 60, 60, 80, 120 },
                            flexDirection = "row", alignItems = "center", gap = 8,
                            children = {
                                UI.Label { text = "📅", fontSize = 18 },
                                UI.Panel {
                                    flex = 1, gap = 2,
                                    children = {
                                        UI.Label { text = "即将到来: " .. nextEvent.name, fontSize = 13, fontWeight = "bold", fontColor = { 200, 200, 255, 220 } },
                                        UI.Label { text = nextEvent.daysUntil .. " 天后", fontSize = 12, fontColor = { 180, 180, 200, 180 } },
                                    },
                                },
                            },
                        })
                    end
                end
            end

            if #cards == 0 then return nil end
            return UI.Panel { width = "100%", gap = 8, children = cards }
        end)
        if retentionPanel then table.insert(actionChildren, retentionPanel) end

        -- ── RV2 留存增强面板 ──
        local rv2Panel = SafeBuild("RV2Panel", function()
            local rv2Cards = {}

            -- 黄金时段指示器（方案9）
            if RV2 and RV2.IsGoldenHour() then
                local left = (playerData_.goldenHourMaxActions or 3) - (playerData_.goldenHourActions or 0)
                table.insert(rv2Cards, UI.Panel {
                    width = "100%", padding = 10, borderRadius = 10,
                    backgroundColor = { 200, 170, 40, 180 },
                    borderWidth = 2, borderColor = { 255, 215, 0, 200 },
                    gap = 4,
                    children = {
                        UI.Label { text = "🌟 黄金时段！", fontSize = 16, fontWeight = "bold", fontColor = { 255, 255, 220, 255 }, width = "100%" },
                        UI.Label { text = "所有行动收益 ×1.5！剩余 " .. left .. " 次行动", fontSize = 13, fontColor = { 255, 255, 200, 230 }, width = "100%" },
                    },
                })
            end

            -- 零AP微事件（方案3）
            if RV2 and (playerData_.microEventsToday or 0) < 3 then
                local events = RV2.GenerateMicroEvents()
                if #events > 0 then
                    local evtItems = {}
                    for _, me in ipairs(events) do
                        local choiceBtns = {}
                        for ci, ch in ipairs(me.choices) do
                            table.insert(choiceBtns, UI.Button {
                                text = ch.text, fontSize = 12, height = 36, flex = 1,
                                backgroundColor = { 70, 130, 90, 200 },
                                onClick = function()
                                    local result = RV2.ResolveMicroEvent(me.id, ci)
                                    AddLog("📋 " .. me.title .. ": " .. result)
                                    BuildUI()
                                end,
                            })
                        end
                        table.insert(evtItems, UI.Panel {
                            width = "100%", padding = 8, borderRadius = 8,
                            backgroundColor = { 50, 60, 70, 150 }, gap = 4,
                            children = {
                                UI.Label { text = me.title, fontSize = 14, fontWeight = "bold", fontColor = C.text, width = "100%" },
                                UI.Label { text = me.desc, fontSize = 12, fontColor = C.textLight, whiteSpace = "normal", width = "100%" },
                                UI.Panel { width = "100%", flexDirection = "row", gap = 6, children = choiceBtns },
                            },
                        })
                    end
                    table.insert(rv2Cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = 10,
                        backgroundColor = { 40, 50, 60, 180 },
                        borderWidth = 1, borderColor = { 100, 180, 130, 80 },
                        gap = 6,
                        children = {
                            UI.Label { text = "☕ 网吧日常（免费互动）", fontSize = 15, fontWeight = "bold", fontColor = { 130, 220, 160, 240 }, width = "100%" },
                            table.unpack(evtItems),
                        },
                    })
                end
            end

            -- AP广告恢复按钮（方案2）
            if RV2 and playerData_.actionPoints <= 0 and RV2.CanAdRecoverAP() then
                local usedCount = playerData_.adAPRecoverToday or 0
                table.insert(rv2Cards, UI.Panel {
                    width = "100%", padding = 10, borderRadius = 10,
                    backgroundColor = { 60, 50, 40, 180 },
                    borderWidth = 1, borderColor = { 200, 160, 60, 80 },
                    gap = 4,
                    children = {
                        UI.Label { text = "⚡ 行动点不足？", fontSize = 14, fontWeight = "bold", fontColor = { 255, 200, 100, 240 }, width = "100%" },
                        AdManager.AdButton {
                            sceneId = "ap_recover", day = playerData_.day,
                            text = "📺 看短片恢复 +1AP（" .. usedCount .. "/2）",
                            fontSize = 13, height = 38, width = "100%",
                            onReward = function()
                                RV2.DoAdRecoverAP()
                                BuildUI()
                            end,
                        },
                    },
                })
            end

            if #rv2Cards == 0 then return nil end
            return UI.Panel { width = "100%", gap = 8, children = rv2Cards }
        end)
        if rv2Panel then table.insert(actionChildren, rv2Panel) end

        local branchPanel = SafeBuild("BranchSelector", BuildBranchSelector)
        if branchPanel then table.insert(actionChildren, branchPanel) end
        table.insert(actionChildren, SafeBuild("DiaryInline", BuildDiaryPage))
        return UI.Panel {
            width = "100%", gap = 12,
            children = actionChildren,
        }
    elseif manageTab_ == "upgrade" then
        local upgradeChildren = {
            SafeBuild("UpgradeCard", BuildUpgradeCard),
            SafeBuild("AchievementCard", BuildAchievementCard),
            SafeBuild("SeasonPass", BuildSeasonPassPanel),
        }
        return UI.Panel {
            width = "100%", gap = 8,
            children = upgradeChildren,
        }
    elseif manageTab_ == "team" then
        local teamChildren = {
            SafeBuild("TeamCard", BuildTeamCard),
            SafeBuild("FreeMiniGame", BuildFreeMiniGamePanel),
            SafeBuild("TeamBond", BuildTeamBondPanel),
        }
        return UI.Panel {
            width = "100%", gap = 8,
            children = teamChildren,
        }
    elseif manageTab_ == "market" then
        return SafeBuild("MarketPage", BuildMarketUI)
    else -- "ranking"
        return UI.Panel {
            width = "100%", gap = 8,
            children = {
                SafeBuild("RankingPage", BuildRankingPage),
            },
        }
    end
end

-- 事件类型 → 网吧场景图映射
local CAFE_EVENT_IMAGE_MAP = {
    tournament  = "cafe_tournament",
    bbq         = "cafe_bbq",
    streaming   = "cafe_streaming",
    blackout    = "cafe_blackout",
}

--- 根据经营状态选择网吧场景图片
function GetCafeSceneImage()
    -- 1. 停电优先
    if (playerData_.blackoutDays or 0) > 0 then
        return SCENE_IMAGES.cafe_blackout
    end
    -- 2. 特殊事件覆盖（由 CafeAnimEvents.Push 设置）
    if cafeSceneEvent_ then
        local imgKey = CAFE_EVENT_IMAGE_MAP[cafeSceneEvent_]
        if imgKey and SCENE_IMAGES[imgKey] then
            return SCENE_IMAGES[imgKey]
        end
    end
    -- 3. 根据客流比例选择
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local ratio = capacity > 0 and (traffic / capacity) or 0
    if ratio <= 0.1 then
        return SCENE_IMAGES.cafe_empty
    elseif ratio <= 0.4 then
        return SCENE_IMAGES.cafe_few
    elseif ratio <= 0.8 then
        return SCENE_IMAGES.cafe_normal
    else
        return SCENE_IMAGES.cafe_busy
    end
end

function BuildManageUI()
    -- 根据当前章节选择管理背景
    local bgImg = CHAPTER_IMAGES[currentChapter_] or SCENE_IMAGES.ch2

    -- 防御性构建子组件，防止单个组件崩溃导致整个UI黑屏
    local ok1, statusBar = pcall(BuildStatusBar)
    if not ok1 then
        log:Write(LOG_ERROR, "[BuildManageUI] BuildStatusBar error: " .. tostring(statusBar))
        statusBar = UI.Label { text = "⚠️ 状态栏加载失败", fontSize = 14, fontColor = { 255, 100, 100, 255 } }
    end

    local ok2, atmosphere = pcall(GetAtmosphere)
    local atmosText = ok2 and atmosphere or "..."

    -- 根据经营状态选择对应的网吧场景图
    local cafeImg = GetCafeSceneImage()

    local ok3, tabBar = pcall(BuildManageTabBar)
    if not ok3 then
        log:Write(LOG_ERROR, "[BuildManageUI] BuildManageTabBar error: " .. tostring(tabBar))
        tabBar = UI.Panel {}
    end

    local ok4, tabContent = pcall(BuildManageTabContent)
    if not ok4 then
        log:Write(LOG_ERROR, "[BuildManageUI] BuildManageTabContent error: " .. tostring(tabContent))
        tabContent = UI.Label { text = "⚠️ 内容加载失败: " .. tostring(tabContent), fontSize = 13, fontColor = { 255, 100, 100, 255 }, whiteSpace = "normal", width = "90%" }
    end

    return UI.Panel {
        width = "100%", height = "100%",
        children = {
            statusBar,
            -- 经营状态场景图（根据人数/事件动态切换）
            UI.Panel {
                width = "100%", height = 160,
                backgroundImage = cafeImg,
                backgroundFit = "cover",
            },
            -- 下方内容区：背景图只覆盖tabBar+滚动区
            UI.Panel {
                flex = 1, width = "100%", flexBasis = 0,
                backgroundImage = bgImg,
                backgroundFit = "cover",
                imageTint = { 30, 24, 18, 200 },
                children = {
                    -- Tab 导航栏
                    tabBar,
                    -- 主内容（分Tab显示，减少滚动）
                    UI.ScrollView {
                        id = "manage-scroll",
                        flex = 1, width = "100%", flexBasis = 0,
                        paddingHorizontal = 8, paddingVertical = 8,
                        children = { tabContent },
                    },
                },
            },
        },
    }
end

function BuildStatusBar()
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local tDesc, tColor = GetTrafficDesc(traffic, capacity)
    local moneyStr = "$" .. FormatMoney(playerData_.money)
    local ec = playerData_.equipCondition or 100

    -- ── 第二行：核心指标 ──
    local statItems = {}
    table.insert(statItems, { text = "D" .. playerData_.day, color = C.textDim })
    table.insert(statItems, { text = "AP " .. playerData_.actionPoints,
        color = playerData_.actionPoints > 0 and C.gold or C.textLight })
    table.insert(statItems, { text = "|", color = { C.textLight[1], C.textLight[2], C.textLight[3], 80 } })
    local repStr = playerData_.reputation >= 100000 and string.format("%.1fK", playerData_.reputation / 1000) or tostring(playerData_.reputation)
    table.insert(statItems, { text = "Rep " .. repStr, color = C.gold })
    table.insert(statItems, { text = tDesc .. traffic .. "/" .. capacity, color = tColor })

    -- 政变警告
    if IsCoupActive() then
        table.insert(statItems, { text = "[政变]" .. playerData_.coupDaysLeft .. "天", color = C.red })
    end

    local statLabels = {}
    for _, s in ipairs(statItems) do
        table.insert(statLabels, UI.Label { text = s.text, fontSize = 11, fontColor = s.color })
    end

    -- ── 第三行：维护 + 可选指标 ──
    local line3Items = {}
    table.insert(line3Items, { text = "维护 " .. ec .. "%",
        color = ec <= 30 and C.red or (ec <= 50 and C.gold or C.textLight) })
    local karmaText = (playerData_.karma >= 4 and "善" or (playerData_.karma <= -3 and "恶" or "中")) .. playerData_.karma
    local karmaColor = playerData_.karma >= 4 and C.green or (playerData_.karma <= -3 and C.red or C.textLight)
    table.insert(line3Items, { text = karmaText, color = karmaColor })
    local goldOz = playerData_.goldOunces or 0
    if goldOz > 0 then
        local gVal = math.floor(goldOz * GetGoldPrice())
        table.insert(line3Items, { text = "Au " .. string.format("%.1f", goldOz) .. "oz ~$" .. FormatMoney(gVal), color = C.gold })
    end
    local branchCount = #(playerData_.branches or {})
    if branchCount > 0 then
        table.insert(line3Items, { text = "分店x" .. branchCount, color = C.textDim })
    end

    local line3Labels = {}
    for _, s in ipairs(line3Items) do
        table.insert(line3Labels, UI.Label { text = s.text, fontSize = 10, fontColor = s.color })
    end

    return UI.Panel {
        width = "100%", height = 48,
        backgroundColor = C.statusBar,
        borderWidth = { 0, 0, 1, 0 }, borderColor = { C.border[1], C.border[2], C.border[3], 80 },
        paddingHorizontal = 12, justifyContent = "center", gap = 1,
        children = {
            -- 第一行：网吧名（左） + 金额（右，金色突出）
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                justifyContent = "space-between",
                paddingRight = 80,
                children = {
                    UI.Label { text = playerData_.cafeName, fontSize = 13, fontColor = C.text, flexShrink = 1 },
                    UI.Label { text = moneyStr, fontSize = 16, fontWeight = "bold", fontColor = C.gold },
                },
            },
            -- 第二行：核心指标
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                flexWrap = "wrap", gap = 6, paddingRight = 80,
                children = statLabels,
            },
            -- 第三行：维护 + 可选指标
            #line3Labels > 0 and UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                flexWrap = "wrap", gap = 6, paddingRight = 80,
                children = line3Labels,
            } or nil,
        },
    }
end

--- 客流量可视化条
function BuildTrafficBar()
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local ratio = math.min(1.5, traffic / math.max(1, capacity))
    local pct = math.min(100, math.floor(ratio * 100))
    local desc, descColor = GetTrafficDesc(traffic, capacity)
    -- 进度条颜色
    local barColor
    if ratio >= 1.3 then barColor = { 240, 60, 60, 255 }       -- 爆满红色
    elseif ratio >= 1.0 then barColor = C.green                  -- 满员绿色
    elseif ratio >= 0.7 then barColor = { 255, 185, 50, 255 }  -- 正常金色
    else barColor = C.textDim end                               -- 冷清灰色
    -- 客流图标动画（用不同表情反映状态）
    local icons = ratio >= 1.0
        and "人流满" or (ratio >= 0.7 and "人流中" or "人流少")
    local weekday = ((playerData_.day - 1) % 7) + 1
    local dayTag = weekday >= 6 and " 周末" or ""
    return UI.Panel {
        width = "100%", gap = 3,
        children = {
            UI.Panel {
                flexDirection = "row", justifyContent = "space-between", width = "100%",
                children = {
                    UI.Label { text = icons .. " 客流", fontSize = 14, fontColor = descColor },
                    UI.Label { text = traffic .. "/" .. capacity .. " " .. desc .. dayTag, fontSize = 13, fontColor = descColor },
                },
            },
            -- 进度条背景
            UI.Panel {
                width = "100%", height = 8, borderRadius = 4,
                backgroundColor = C.cardAlt,
                children = {
                    UI.Panel {
                        width = pct .. "%", height = "100%", borderRadius = 4,
                        backgroundColor = barColor,
                    },
                },
            },
        },
    }
end

--- 赞助商中心：主动看广告获取小额随机奖励
function BuildSponsorCenter()
    if not AdManager.CanWatch("sponsor_small", playerData_.day) then return nil end
    -- 随机奖励池
    local rewards = {
        { label = "$30现金",   fn = function() playerData_.money = playerData_.money + 30; playerData_.totalEarnings = (playerData_.totalEarnings or 0) + 30; AddLog("📺 赞助商小额赞助 +$30！") end },
        { label = "声望+5",   fn = function() playerData_.reputation = playerData_.reputation + 5; AddLog("📺 赞助商帮你在社交媒体曝光！声望+5") end },
        { label = "设备+10%", fn = function() playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 80) + 10); AddLog("📺 赞助商寄来零件！设备状态+10%") end },
        { label = "行动点+1", fn = function() playerData_.actionPoints = playerData_.actionPoints + 1; AddLog("📺 赞助商的咖啡让你精力充沛！行动点+1") end },
    }
    return UI.Panel {
        width = "100%", padding = 10, borderRadius = 12,
        backgroundColor = C.cardAlt,
        borderWidth = 1, borderColor = C.border,
        gap = 6,
        children = {
            UI.Label { text = "赞助商中心", fontSize = 15, fontColor = C.gold, fontWeight = "bold" },
            UI.Label {
                text = "每天可观看" .. (AdManager.limits.sponsor_small or 3) .. "次赞助商短片，获取随机小额奖励",
                fontSize = 11, fontColor = C.textDim, whiteSpace = "normal",
            },
            AdManager.AdButton {
                sceneId = "sponsor_small", day = playerData_.day,
                text = "观看赞助商短片 → 随机奖励",
                width = "100%", height = 38, fontSize = 13, borderRadius = 8,
                backgroundColor = { C.accent[1], C.accent[2], C.accent[3], 200 }, fontColor = { 255, 255, 255, 255 },
                borderWidth = 1, borderColor = C.border,
                onReward = function()
                    local r = rewards[math.random(1, #rewards)]
                    r.fn()
                    playerData_.questAdWatchCount = (playerData_.questAdWatchCount or 0) + 1
                    PlaySFX("coin")
                    BuildUI()
                end,
            },
        },
    }
end

--- 分店选择器/展示模块
function BuildBranchSelector()
    local branches = playerData_.branches or {}
    if #branches == 0 then return nil end

    local branchCards = {}
    for i, br in ipairs(branches) do
        -- 按城市设置不同底色
        local locColors = {
            lagos    = { 50, 180, 80 },
            nairobi  = { 60, 140, 200 },
            accra    = { 200, 160, 60 },
            dakar    = { 80, 160, 200 },
            capetown = { 160, 80, 200 },
            kinshasa = { 200, 120, 60 },
        }
        local lc = locColors[br.locationId] or { 80, 120, 80 }
        local daysOpen = playerData_.day - (br.day or playerData_.day)

        local branchBg = SCENE_IMAGES["branch_" .. (br.locationId or "")]
        table.insert(branchCards, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = branchBg and { 0, 0, 0, 100 } or { lc[1], lc[2], lc[3], 35 },
            backgroundImage = branchBg,
            backgroundFit = "cover",
            borderRadius = 10, borderWidth = 1,
            borderColor = { lc[1] + 40, lc[2] + 40, lc[3] + 40, 90 },
            children = {
                -- 行1: 店名 + 日收入
                UI.Panel {
                    width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                    children = {
                        UI.Label { text = (br.locationEmoji or "🏪") .. " " .. (br.name or ("分店" .. i)),
                            fontSize = 14, fontColor = C.text, fontWeight = "bold" },
                        UI.Label { text = "$" .. (br.income or 40) .. "/天",
                            fontSize = 13, fontColor = C.green },
                    },
                },
                -- 行2: 游戏 + 加成
                UI.Panel {
                    width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                    children = {
                        UI.Label { text = (br.gameEmoji or "🎮") .. " " .. (br.gameName or "综合"),
                            fontSize = 12, fontColor = C.textDim },
                        UI.Label { text = "" .. (br.bonusDesc or "") .. " | " .. (br.gameBonusDesc or ""),
                            fontSize = 11, fontColor = C.textDim },
                    },
                },
                -- 行3: 运营天数
                UI.Label { text = "开业于第" .. (br.day or "?") .. "天 · 已运营" .. daysOpen .. "天",
                    fontSize = 11, fontColor = C.textDim },
            },
        })
    end

    return UI.Panel {
        width = "100%", padding = 12, gap = 8,
        backgroundColor = C.cardAlt, borderRadius = 14,
        borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
        boxShadow = { { x = 0, y = 2, blur = 10, color = { 0, 0, 0, 60 } } },
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    PanelHeader("连锁帝国", { icon = nil, color = C.gold }),
                    UI.Label { text = #branches .. "/3 家", fontSize = 13,
                        fontColor = #branches >= 3 and C.green or C.textDim },
                },
            },
            UI.Divider { color = { C.accent[1], C.accent[2], C.accent[3], 40 } },
            table.unpack(branchCards),
        },
    }
end

function BuildCafeCard()
    local netNames = { "蜗牛", "普通", "高速", "光纤", "卫星" }
    local chrNames = { "塑料凳", "折叠椅", "网吧椅", "电竞椅", "皇帝座" }
    local acNames  = { "无", "小空调", "中央空调", "全屋恒温" }
    local solNames = { "无", "小面板", "中面板", "大面板" }
    local foodNames = { "无", "烤玉米摊", "烤鸡摊", "小卖部" }
    local decoNames = { "无", "非洲面具", "壁画+面具", "主题装修" }

    local netN = netNames[playerData_.netSpeed] or "?"
    local chrN = chrNames[playerData_.chairLevel] or "?"
    local acN  = acNames[playerData_.acLevel + 1] or "?"
    local solN = solNames[playerData_.solarLevel + 1] or "?"
    local foodN = foodNames[playerData_.foodShop + 1] or "?"
    local decoN = decoNames[playerData_.decoLevel + 1] or "?"

    -- ── 带进度条的信息行 ──
    local function ProgressRow(icon, label, current, maxVal, valueTxt, barColor)
        local pct = math.floor(math.min(1, current / math.max(1, maxVal)) * 100)
        return UI.Panel {
            width = "100%", gap = 2, flexShrink = 0,
            children = {
                InfoRow(icon .. " " .. label, valueTxt, barColor),
                UI.Panel {
                    width = "100%", height = 5, minHeight = 5, borderRadius = 3,
                    backgroundColor = C.cardAlt,
                    flexShrink = 0,
                    children = {
                        UI.Panel {
                            width = pct .. "%", height = "100%", borderRadius = 3,
                            backgroundColor = barColor or { 80, 160, 255, 200 },
                        },
                    },
                },
            },
        }
    end

    -- ── 模块1: 基础设施 ──
    local infraSection = UI.Panel {
        width = "100%", gap = 4, flexShrink = 0,
        children = {
            PanelHeader("基础设施", { icon = nil, compact = true }),
            (function()
                local initComputers = 3
                local computerUpgradeMax = initComputers + #UPGRADES.computer.costs  -- 场地上限
                local cur = playerData_.computers
                local desc
                if cur > computerUpgradeMax then
                    desc = cur .. "台(场地" .. computerUpgradeMax .. "+事件加成" .. (cur - computerUpgradeMax) .. ")"
                elseif cur >= computerUpgradeMax then
                    desc = cur .. "/" .. computerUpgradeMax .. "台(已满)"
                else
                    desc = cur .. "/" .. computerUpgradeMax .. "台"
                end
                return ProgressRow("", "电脑", math.min(cur, computerUpgradeMax), computerUpgradeMax, desc, { 80, 180, 255, 255 })
            end)(),
            ProgressRow("", "座椅", playerData_.chairLevel, 5,
                chrN .. " Lv" .. playerData_.chairLevel, { 160, 130, 255, 255 }),
            ProgressRow("🌐", "网速", playerData_.netSpeed, 5,
                netN .. " Lv" .. playerData_.netSpeed, { 100, 220, 200, 255 }),
        },
    }

    -- ── 模块2: 环境配套 ──
    local envChildren = {
        PanelHeader("环境配套", { icon = "🌿", compact = true }),
    }
    if playerData_.acLevel > 0 then
        table.insert(envChildren, ProgressRow("❄️", "空调", playerData_.acLevel, 3,
            acN, { 100, 200, 240, 255 }))
    else
        table.insert(envChildren, InfoRow("❄️ 空调", "未安装", C.textDim))
    end
    if playerData_.solarLevel > 0 then
        table.insert(envChildren, ProgressRow("☀️", "太阳能", playerData_.solarLevel, 3,
            solN, { 255, 200, 60, 255 }))
    else
        table.insert(envChildren, InfoRow("☀️ 太阳能", "未安装", C.textDim))
    end
    if playerData_.foodShop > 0 then
        table.insert(envChildren, ProgressRow("🍗", "小卖部", playerData_.foodShop, 3,
            foodN, { 255, 160, 80, 255 }))
    else
        table.insert(envChildren, InfoRow("🍗 小卖部", "未开设", C.textDim))
    end
    if playerData_.decoLevel > 0 then
        table.insert(envChildren, ProgressRow("🎭", "装饰", playerData_.decoLevel, 3,
            decoN, { 220, 120, 200, 255 }))
    else
        table.insert(envChildren, InfoRow("🎭 装饰", "无", C.textDim))
    end
    -- 发电机 & 燃油
    local genLv = playerData_.generatorLevel or 0
    local genNames = { "无", "小型柴油机", "中型发电机", "大型静音发电机" }
    if genLv > 0 then
        table.insert(envChildren, ProgressRow("", "发电机", genLv, 3,
            genNames[genLv + 1] or "?", { 255, 220, 80, 255 }))
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        local fuelColor = fuel <= 0 and { 240, 70, 70, 255 }
            or (fuel <= math.floor(cap * 0.3) and { 255, 185, 50, 255 } or { 100, 220, 140, 255 })
        table.insert(envChildren, ProgressRow("⛽", "燃油", fuel, cap,
            fuel .. "/" .. cap .. "L", fuelColor))
    else
        table.insert(envChildren, InfoRow("发电机", "未购买", C.textDim))
    end
    -- 分店
    local branches = playerData_.branches or {}
    if #branches > 0 then
        table.insert(envChildren, InfoRow("分店", #branches .. "家", C.green))
    end

    local envSection = UI.Panel {
        width = "100%", gap = 4, flexShrink = 0,
        children = envChildren,
    }

    -- ── 模块3: 客流状态（复用已有 BuildTrafficBar） ──
    local trafficSection = BuildTrafficBar()

    -- ── 模块4: 财务简报 ──
    local income = CalcDailyIncome()
    local _, totalExpense = CalcDailyExpenses()
    local netIncome = income - totalExpense
    local netColor = netIncome >= 0 and C.green or C.red
    local netSign = netIncome >= 0 and "+" or ""

    local finChildren = {
        PanelHeader("财务简报", { icon = "💹", compact = true }),
        -- 净收入突出显示
        UI.Panel {
            width = "100%", flexDirection = "row", justifyContent = "center",
            alignItems = "center", gap = 6, flexShrink = 0,
            children = {
                UI.Label { text = "日净收入", fontSize = 13, fontColor = C.textDim },
                UI.Label { text = netSign .. "$" .. netIncome, fontSize = 18, fontColor = netColor },
            },
        },
        -- 收支明细
        InfoRow("收入", "+$" .. income, C.green),
        InfoRow("支出", "-$" .. totalExpense, C.red),
    }
    -- 借款显示
    if playerData_.debt > 0 then
        table.insert(finChildren, InfoRow("欠款", "$" .. playerData_.debt, C.red))
    end
    -- 哈弗币
    if playerData_.havocCoins > 0 then
        table.insert(finChildren, InfoRow("🪙 哈弗币", tostring(playerData_.havocCoins), C.gold))
    end

    local finSection = UI.Panel {
        width = "100%", gap = 4, flexShrink = 0,
        backgroundColor = C.cardAlt, borderRadius = 10,
        padding = 10,
        children = finChildren,
    }

    -- ── 模块5: 联动加成（有才显示） ──
    local synergies = CalcUpgradeSynergies()
    ---@type table|nil
    local synergySection = nil
    if #synergies > 0 then
        local synergyItems = {
            PanelHeader("联动加成", { icon = nil, compact = true, color = C.gold }),
        }
        for _, s in ipairs(synergies) do
            table.insert(synergyItems, UI.Label {
                text = s.name .. "  " .. s.desc,
                fontSize = 14, fontColor = { C.green[1], C.green[2], C.green[3], 220 },
                whiteSpace = "normal", lineHeight = 1.3,
            })
        end
        synergySection = UI.Panel {
            width = "100%", gap = 3,
            children = synergyItems,
        }
    end

    -- ── 组装卡片 ──
    local cardChildren = {
        UI.Panel {
            flexDirection = "row", justifyContent = "space-between",
            alignItems = "center", width = "100%",
            children = {
                PanelHeader("网吧概况", { icon = nil }),
                UI.Panel {
                    paddingHorizontal = 8, paddingVertical = 2,
                    backgroundColor = { 240, 180, 50, 20 }, borderRadius = 10,
                    children = {
                        UI.Label { text = "第" .. playerData_.day .. "天", fontSize = 13, fontColor = C.gold },
                    },
                },
            },
        },
        infraSection,
        UI.Divider { spacing = 4, color = { C.border[1], C.border[2], C.border[3], 120 } },
        envSection,
        UI.Divider { spacing = 4, color = { C.border[1], C.border[2], C.border[3], 120 } },
        trafficSection,
        UI.Divider { spacing = 4, color = { C.border[1], C.border[2], C.border[3], 120 } },
        finSection,
    }
    if synergySection then
        table.insert(cardChildren, UI.Divider { spacing = 4, color = { C.border[1], C.border[2], C.border[3], 120 } })
        table.insert(cardChildren, synergySection)
    end

    return UI.Panel {
        width = "100%", padding = 12, gap = 8,
        backgroundColor = C.card, borderRadius = 14,
        borderWidth = 1, borderColor = C.border,
        children = cardChildren,
    }
end

function BuildActionCard()
    local nextCh = currentChapter_ + 1
    local hasNext = nextCh <= #CHAPTERS
    local canAdv, advReason = false, ""
    if hasNext then
        if nextCh == 2 and #teamMembers_ >= 1 and playerData_.day >= 4 then canAdv = true
        elseif nextCh == 3 and #teamMembers_ >= 2 and GetTeamAvgSkill() >= 30 then canAdv = true
        elseif nextCh == 4 and playerData_.day >= 14 and playerData_.reputation >= 80 then canAdv = true
        elseif nextCh == 5 and playerData_.day >= 18 and (playerData_.tournamentWins or 0) >= 1 then canAdv = true
        elseif nextCh > 5 then canAdv = true  -- 未来扩展章节默认可推进
        end
        if not canAdv then
            if nextCh == 2 then advReason = "第二章（第4天 + 队员1人）"
            elseif nextCh == 3 then advReason = "第三章（队员2人 + 平均技术30）"
            elseif nextCh == 4 then advReason = "第四章（第14天 + 声望80）"
            elseif nextCh == 5 then advReason = "第五章（第18天 + 赢过1次锦标赛）"
            end
        end
    end

    local ap = playerData_.actionPoints
    local noAP = ap <= 0

    -- ── 辅助：创建行动按钮 ──
    local function ActionBtn(props)
        if props.variant then
            return UI.Button {
                text = props.text,
                width = props.width or "100%",
                height = props.height or 44, fontSize = 14, borderRadius = 10,
                disabled = props.disabled,
                variant = props.variant,
                flex = props.flex,
                onClick = props.onClick,
            }
        end
        return UI.Button {
            text = props.text,
            width = props.width or "100%",
            height = props.height or 44, fontSize = 14, fontWeight = "bold", borderRadius = 10,
            backgroundColor = props.disabled and { 50, 44, 40, 255 } or C.card,
            fontColor = props.disabled and C.textLight or C.text,
            borderWidth = 1,
            borderColor = props.disabled and C.border or (props.borderColor or C.accent),
            disabled = props.disabled,
            flex = props.flex,
            onClick = props.onClick,
        }
    end

    -- ── 辅助：2x2 网格按钮（双行：标题 + 金色价格） ──
    local function GridBtn(props)
        local disabled = props.disabled
        return UI.Panel {
            width = "48%", height = 64, borderRadius = 10,
            backgroundColor = disabled and { 50, 44, 40, 255 } or C.card,
            borderWidth = 1.5,
            borderColor = disabled and C.border or C.accent,
            justifyContent = "center", alignItems = "center", gap = 2,
            onClick = not disabled and props.onClick or nil,
            children = {
                UI.Label {
                    text = props.title, fontSize = 14, fontWeight = "bold",
                    fontColor = disabled and C.textLight or C.text,
                },
                props.price and UI.Label {
                    text = props.price, fontSize = 12,
                    fontColor = disabled and C.textLight or C.gold,
                } or nil,
            },
        }
    end

    -- ── 1) 标题行（暗色底 + AP 徽章，与按钮风格统一） ──
    local header = UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingHorizontal = 12, paddingVertical = 8,
        backgroundColor = C.cardAlt,
        borderRadius = 10,
        borderWidth = 1, borderColor = C.border,
        children = {
            -- 左侧：标题
            UI.Label { text = "行动", fontSize = 14, fontColor = C.text, fontWeight = "bold" },
            -- 右侧：AP 徽章
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 4,
                paddingHorizontal = 10, paddingVertical = 3,
                backgroundColor = { C.border[1], C.border[2], C.border[3], 120 },
                borderRadius = 10,
                children = {
                    UI.Label { text = "AP", fontSize = 13, fontColor = C.textDim },
                    UI.Label { text = ap .. "/3", fontSize = 14, fontWeight = "bold",
                        fontColor = noAP and C.red or C.gold },
                },
            },
        },
    }

    -- ── 广告：额外行动点（AP耗尽时显示） ──
    local adExtraAP = nil
    if noAP and AdManager.CanWatch("extra_ap", playerData_.day) then
        adExtraAP = AdManager.AdButton {
            sceneId = "extra_ap", day = playerData_.day,
            text = "看视频多干一件事 +1AP",
            height = 42, fontSize = 13,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                BuildUI()
            end,
        }
    end

    -- ── 广告：翻倍昨日收入 / 经营补贴 ──
    local adDoubleIncome = nil
    local lastNet = playerData_.lastNetIncome or 0
    if AdManager.CanWatch("double_income", playerData_.day) then
        local bonus = lastNet > 0 and lastNet or math.max(50, math.floor(playerData_.day * 8))
        local label = lastNet > 0
            and ("看广告翻倍昨日收入 +$" .. bonus)
            or  ("看广告领经营补贴 +$" .. bonus)
        adDoubleIncome = AdManager.AdButton {
            sceneId = "double_income", day = playerData_.day,
            text = label,
            height = 42, fontSize = 13,
            onReward = function()
                playerData_.money = playerData_.money + bonus
                playerData_.totalEarnings = (playerData_.totalEarnings or 0) + bonus
                playerData_.lastNetIncome = 0
                AddLog("🎬 赞助商追加了经营奖励！额外获得$" .. bonus .. "！")
                BuildUI()
            end,
        }
    end

    -- ── 1.5) 每日委托任务面板（第10天后显示） ──
    local questPanel = nil
    if dailyQuest_ and playerData_.day >= 10 then
        CheckQuestProgress()
        local q = dailyQuest_
        local done = q.progress >= q.goal
        local progressText = done and "已完成" or (q.progress .. "/" .. q.goal)
        local questChildren = {
            UI.Panel {
                flexDirection = "row", justifyContent = "space-between", alignItems = "center", width = "100%",
                children = {
                    UI.Label { text = "每日委托", fontSize = 14, fontColor = C.gold },
                    UI.Label { text = progressText, fontSize = 13,
                        fontColor = done and C.green or C.textDim },
                },
            },
            UI.Label { text = q.desc, fontSize = 13, fontColor = C.text, marginTop = 4 },
            UI.Label { text = "奖励: " .. q.rewardDesc, fontSize = 12, fontColor = C.textDim, marginTop = 2 },
        }
        if done and not q.claimed then
            table.insert(questChildren, UI.Button {
                text = "领取奖励", width = "100%", height = 38, fontSize = 13, fontWeight = "bold",
                borderRadius = 10, marginTop = 6,
                backgroundColor = { 65, 55, 40, 255 },
                fontColor = C.gold,
                borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                onClick = function()
                    ClaimQuestReward()
                    BuildUI()
                end,
            })
        elseif q.claimed then
            table.insert(questChildren, UI.Label {
                text = "已领取", fontSize = 12, fontColor = { C.green[1], C.green[2], C.green[3], 180 },
                marginTop = 4, textAlign = "center",
            })
        end
        questPanel = UI.Panel {
            width = "100%", paddingHorizontal = 12, paddingVertical = 10,
            backgroundColor = C.cardAlt, borderRadius = 12,
            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 40 },
            gap = 2, children = questChildren,
        }
    end

    -- ── 2) 结束今天（始终醒目：橙色底 + 白色粗体，最突出按钮） ──
    local endDayBtn = UI.Button {
        text = noAP and "行动点已用完，结束今天" or "结束今天",
        width = "100%", height = 56, fontSize = 20, fontWeight = "bold", borderRadius = 12,
        backgroundColor = C.accent,
        fontColor = C.text,
        borderWidth = 0,
        onClick = function()
            -- 过场动画期间禁止操作，防止重复触发 EndDay 导致黑屏
            if transition_.active then return end
            PlaySFX("click")
            local ok, err = pcall(EndDay)
            if not ok then
                log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
        end,
    }

    -- ── 3) 高频操作：2x2 网格（48%宽·64px·橙色边框·价格第二行） ──
    local gridRow1 = {}
    table.insert(gridRow1, GridBtn {
        title = "逛集市", price = "$50",
        disabled = noAP or playerData_.money < 50,
        onClick = function() DoVisitMarket() end,
    })
    table.insert(gridRow1, GridBtn {
        title = "贴传单", price = "$30",
        disabled = noAP or playerData_.money < 30,
        onClick = function() DoPostFlyers() end,
    })

    local gridRow2 = {}
    if #CANDIDATE_POOL > 0 then
        local isFull = #teamMembers_ >= 5
        table.insert(gridRow2, GridBtn {
            title = isFull and "替换队员" or "招募队员", price = "$200",
            disabled = noAP or playerData_.money < 200,
            onClick = function() ScoutRecruit() end,
        })
    end
    table.insert(gridRow2, GridBtn {
        title = friendlyMatchToday_ and "比赛(已赛)" or "比赛",
        disabled = noAP or #teamMembers_ < 2 or friendlyMatchToday_,
        onClick = function()
            matchTierSelect_ = not matchTierSelect_
            PlaySFX("click")
            BuildUI()
        end,
    })
    if #gridRow2 < 2 then
        table.insert(gridRow2, 1, UI.Panel { width = "48%" })
    end

    local gridPanel = UI.Panel {
        width = "100%", gap = 8,
        children = {
            UI.Panel { width = "100%", flexDirection = "row", gap = 8, justifyContent = "space-between", children = gridRow1 },
            UI.Panel { width = "100%", flexDirection = "row", gap = 8, justifyContent = "space-between", children = gridRow2 },
        },
    }

    -- ── 3.5) 比赛等级选择面板 ──
    local tierPanel = nil
    if matchTierSelect_ and not friendlyMatchToday_ and not noAP and #teamMembers_ >= 2 then
        local tierBtns = {}
        local tw = playerData_.tierWins or { 0, 0, 0 }
        for i, tier in ipairs(MATCH_TIERS) do
            local unlocked = tier.unlock()
            local canAfford = playerData_.money >= tier.cost
            local winsText = tw[i] and tw[i] > 0 and (" (" .. tw[i] .. "胜)") or ""
            if unlocked then
                table.insert(tierBtns, ActionBtn {
                    text = tier.name .. " $" .. tier.cost .. winsText,
                    borderColor = { C.accent[1], C.accent[2], C.accent[3], 160 },
                    disabled = not canAfford,
                    onClick = function()
                        matchTierSelect_ = false
                        pendingMatchTier_ = i
                        matchGameSelect_ = true
                        PlaySFX("click")
                        BuildUI()
                    end,
                })
            else
                table.insert(tierBtns, ActionBtn {
                    text = "" .. tier.unlockDesc,
                    disabled = true,
                })
            end
        end
        -- 多级锦标赛入口（第三章完成后解锁）
        if chaptersRead_[3] then
            local tWinsMap = playerData_.tournamentTierWins or {}
            table.insert(tierBtns, UI.Panel { height = 2, width = "90%", backgroundColor = { 220, 165, 30, 100 } })
            table.insert(tierBtns, UI.Label { text = "── 锦标赛 ──", fontSize = 12, fontColor = C.gold, textAlign = "center" })
            for ti, tt in ipairs(TOURNAMENT_TIERS) do
                local prevOk = (tt.prevWinReq == nil) or ((tWinsMap[tt.prevWinReq] or 0) >= 1)
                local repOk = playerData_.reputation >= tt.repReq
                local teamOk = #teamMembers_ >= tt.teamReq
                local powerOk = GetTeamPower() >= tt.powerReq
                local canAffordT = playerData_.money >= tt.cost
                local unlocked = prevOk and repOk and teamOk and powerOk
                local myWins = tWinsMap[tt.id] or 0
                local record = myWins > 0 and (" ×" .. myWins) or ""
                if unlocked then
                    local borderColors = {
                        { 100, 180, 255, 80 }, { C.accent[1], C.accent[2], C.accent[3], 100 },
                        { 255, 210, 70, 120 }, { 255, 80, 80, 150 },
                    }
                    table.insert(tierBtns, ActionBtn {
                        text = tt.name .. " $" .. tt.cost .. record,
                        borderColor = { C.accent[1], C.accent[2], C.accent[3], 120 },
                        disabled = not canAffordT,
                        onClick = function()
                            matchTierSelect_ = false
                            PlaySFX("click")
                            playerData_.money = playerData_.money - tt.cost
                            isFriendlyMatch_ = false
                            currentTournamentTier_ = ti
                            matchGameType_ = nil
                            -- 深拷贝对手列表
                            matchOpponents_ = {}
                            for _, opp in ipairs(tt.opponents) do
                                table.insert(matchOpponents_, { name = opp.name, power = opp.power, style = opp.style, emoji = opp.emoji, boss = opp.boss })
                            end
                            matchRound_ = 0; matchWins_ = 0; matchLog_ = {}; matchPhase_ = "intro"
                            PlayBGM("match")
                            StartTransition(tt.transition.title, tt.transition.sub, function()
                                currentPhase_ = PHASE_MATCH; BuildUI()
                            end)
                        end,
                    })
                else
                    -- 显示锁定原因
                    local reasons = {}
                    if not prevOk then table.insert(reasons, "需先夺冠上一级") end
                    if not repOk then table.insert(reasons, "声望≥" .. tt.repReq) end
                    if not teamOk then table.insert(reasons, tt.teamReq .. "名队员") end
                    if not powerOk then table.insert(reasons, "战力≥" .. tt.powerReq) end
                    table.insert(tierBtns, ActionBtn {
                        text = "" .. tt.name .. " (" .. table.concat(reasons, ", ") .. ")",
                        disabled = true,
                    })
                end
            end
        end
        table.insert(tierBtns, ActionBtn {
            text = "← 返回", variant = "secondary",
            onClick = function() matchTierSelect_ = false; PlaySFX("click"); BuildUI() end,
        })
        tierPanel = UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = 10,
            borderWidth = 1, borderColor = { 240, 180, 50, 40 },
            children = {
                UI.Label { text = "选择比赛等级", fontSize = 13, fontColor = C.gold },
                table.unpack(tierBtns),
            },
        }
    end

    -- ── 3.6) 游戏选择面板 ──
    local gameSelectPanel = nil
    if matchGameSelect_ and pendingMatchTier_ then
        local gameBtns = {}
        for _, gt in ipairs(MATCH_GAME_TYPES) do
            local modInfo = ""
            if gt.powerMod ~= 1.0 then
                modInfo = modInfo .. (gt.powerMod > 1.0 and " 战力↑" or " 战力↓")
            end
            if gt.rewardMod ~= 1.0 then
                modInfo = modInfo .. (gt.rewardMod > 1.0 and " 奖励↑" or " 奖励↓")
            end
            table.insert(gameBtns, ActionBtn {
                text = gt.name .. modInfo,
                onClick = function()
                    matchGameType_ = gt
                    matchGameSelect_ = false
                    PlaySFX("click")
                    DoHostTournament(pendingMatchTier_)
                end,
            })
        end
        table.insert(gameBtns, UI.Label {
            text = "选择参赛游戏类型，不同游戏有不同战力和奖励修正",
            fontSize = 10, fontColor = C.textDim, textAlign = "center",
        })
        table.insert(gameBtns, ActionBtn {
            text = "← 返回选等级", variant = "secondary",
            onClick = function()
                matchGameSelect_ = false
                pendingMatchTier_ = nil
                matchTierSelect_ = true
                PlaySFX("click")
                BuildUI()
            end,
        })
        gameSelectPanel = UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = 10,
            borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = {
                UI.Label { text = "选择比赛游戏", fontSize = 13, fontColor = C.accent },
                table.unpack(gameBtns),
            },
        }
    end

    -- ── 3.8) 网吧实况（免费查看，不消耗行动点） ──
    local cafePanel = nil
    do
        GenerateDailyCafeEvents()
        local pendingCafe = pendingCafeCount_ or 0
        local totalCafe = cafeEvents_ and #cafeEvents_ or 0
        if cafeViewOpen_ then
            local ok, result = pcall(BuildCafeInlinePanel)
            cafePanel = ok and result or nil
        elseif totalCafe > 0 or pendingCafe > 0 then
            local btnText = "网吧实况"
            if pendingCafe > 0 then
                btnText = btnText .. "（" .. pendingCafe .. "件待处理）"
            else
                btnText = btnText .. "（" .. totalCafe .. "件）"
            end
            cafePanel = UI.Button {
                text = btnText,
                width = "100%", height = 44, fontSize = 14, fontWeight = "bold", borderRadius = 10,
                backgroundColor = C.card,
                fontColor = pendingCafe > 0 and C.gold or C.textDim,
                borderWidth = 1.5,
                borderColor = pendingCafe > 0 and { C.accent[1], C.accent[2], C.accent[3], 180 } or { C.border[1], C.border[2], C.border[3], 120 },
                onClick = function()
                    cafeViewOpen_ = true
                    AutoResolveCafeEvents()
                    PlaySFX("click")
                    BuildUI()
                end,
            }
        end
    end

    -- ── 4) 条件性行动（按类别分组） ──

    -- ── 4a) 设备与维护 ──
    local maintActions = {}
    -- 买燃油（有发电机时显示）
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 then
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        local fuelCost = 8 * (cap - fuel)  -- 按缺量购买，每升$8
        if fuel < cap then
            fuelCost = math.min(fuelCost, math.max(30, fuelCost))  -- 最低$30起购
            local buyAmount = cap - fuel
            table.insert(maintActions, ActionBtn {
                text = "买燃油 +" .. buyAmount .. "L $" .. fuelCost .. " (" .. fuel .. "/" .. cap .. "L)",
                disabled = playerData_.money < fuelCost,
                onClick = function() DoBuyFuel() end,
            })
        else
            table.insert(maintActions, UI.Label {
                text = "燃油已满 " .. fuel .. "/" .. cap .. "L", fontSize = 13, fontColor = C.green,
            })
        end
    end
    -- 维修设备
    local cond = playerData_.equipCondition or 100
    if cond < 95 then
        local repairCost = 50 + playerData_.computers * 10
        local condColor = cond <= 30 and C.red or (cond <= 50 and C.gold or C.text)
        table.insert(maintActions, ActionBtn {
            text = "维修设备 $" .. repairCost .. " (" .. string.format("%.1f", cond) .. "%)",
            disabled = noAP or playerData_.money < repairCost,
            onClick = function() DoRepairEquipment() end,
        })
        -- 广告：免费维修
        if AdManager.CanWatch("free_repair", playerData_.day) then
            table.insert(maintActions, AdManager.AdButton {
                sceneId = "free_repair", day = playerData_.day,
                text = "看视频免费维修 省$" .. repairCost,
                height = 38, fontSize = 12,
                onReward = function()
                    local before = playerData_.equipCondition or 0
                    playerData_.equipCondition = math.min(100, before + 30)
                    AddLog("🎬 赞助商派技术团队免费维护！" .. before .. "%→" .. playerData_.equipCondition .. "%")
                    BuildUI()
                end,
            })
        end
    end

    -- ── 4b) 副业赚钱 ──
    local sideJobActions = {}
    -- 手机维修（随时可做）
    table.insert(sideJobActions, ActionBtn {
        text = "修手机赚外快 AP1",
        disabled = noAP,
        onClick = function() DoPhoneRepair() end,
    })
    -- 代练服务（有队员时显示）
    if #teamMembers_ >= 1 then
        table.insert(sideJobActions, ActionBtn {
            text = "代练服务 AP1",
            disabled = noAP,
            onClick = function() DoBoostingService() end,
        })
    end
    -- 直播跑刀三角洲
    if #teamMembers_ >= 2 and playerData_.netSpeed >= 2 then
        table.insert(sideJobActions, ActionBtn {
            text = "直播跑刀三角洲 AP1",
            disabled = noAP,
            onClick = function() DoStreamDeltaForce() end,
        })
    end
    -- 网吧包场（3台电脑以上）
    if playerData_.computers >= 4 then
        table.insert(sideJobActions, ActionBtn {
            text = "接包场活动 AP1",
            disabled = noAP,
            onClick = function() DoCafeRental() end,
        })
    end
    -- 二手市场（第7天后解锁）
    if playerData_.day >= 7 then
        table.insert(sideJobActions, ActionBtn {
            text = "逛二手淘宝 AP1",
            disabled = noAP or playerData_.money < 50,
            onClick = function() DoSecondHandMarket() end,
        })
    end

    -- ── 4c) 团队与社交 ──
    local socialActions = {}
    if #teamMembers_ > 0 then
        table.insert(socialActions, ActionBtn {
            text = "请队员吃烤肉 ($60) AP1",
            disabled = noAP or playerData_.money < 60,
            onClick = function() DoTeamBBQ() end,
        })
    end
    -- 广告：免费招募（有候选人时显示，满员时变为免费替换）
    if #CANDIDATE_POOL > 0 and AdManager.CanWatch("recruit_discount", playerData_.day) then
        local adLabel = #teamMembers_ >= 5 and "看视频免费替换队员（省$200）" or "看视频免费招募一次（省$200）"
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "recruit_discount", day = playerData_.day,
            text = adLabel,
            height = 38, fontSize = 12,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1  -- 补回行动点
                AddLog("🎬 赞助商赞助了招募费用！这次找人不花钱！")
                ScoutRecruit()
            end,
        })
    end
    -- 广告：媒体采访声望+20
    if AdManager.CanWatch("reputation_ad", playerData_.day) then
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "reputation_ad", day = playerData_.day,
            text = "接受媒体采访 声望+20",
            height = 38, fontSize = 12,
            onReward = function()
                playerData_.reputation = playerData_.reputation + 20
                AddLog("🎬 赞助商安排了媒体采访！你的网吧故事登上了当地报纸。声望+20")
                BuildUI()
            end,
        })
    end

    -- ── 4d) 扩张经营 ──
    local expandActions = {}
    -- 借钱
    if playerData_.money < 300 and (playerData_.debt or 0) < 500 then
        local alreadyBorrowed = playerData_.debtDay == playerData_.day
        table.insert(expandActions, ActionBtn {
            text = alreadyBorrowed and "找Mama B借钱 (今日已借)" or "找Mama B借钱 ($300)",
            disabled = alreadyBorrowed,
            onClick = function() DoBorrowMoney() end,
        })
    end
    if (playerData_.debt or 0) > 0 then
        table.insert(expandActions, UI.Label {
            text = "欠款: $" .. playerData_.debt .. " (每日自动还30%余额)",
            fontSize = 14, fontColor = C.red, paddingLeft = 4,
        })
    end

    -- ── 4e) 黄金交易 ──
    local goldPanel = nil
    -- 黄金交易（第10天后解锁）
    if playerData_.day >= 10 then
        local goldPrice = GetGoldPrice()
        local curGold = playerData_.goldOunces or 0
        local goldVal = curGold > 0 and math.floor(curGold * goldPrice) or 0
        -- 金价趋势指示
        local prevPrice = GetGoldPrice((playerData_.day or 1) - 1)
        local trend = goldPrice > prevPrice and "↑" or (goldPrice < prevPrice and "↓" or "→")
        goldPanel = UI.Panel {
            width = "100%", padding = 8, gap = 4,
            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 40 }, borderRadius = 10,
            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 120 },
            children = {
                UI.Label {
                    text = trend .. " 金价: $" .. goldPrice .. "/oz" ..
                        (curGold > 0 and ("  |  持仓: " .. string.format("%.1f", curGold) .. "oz ≈ $" .. goldVal) or ""),
                    fontSize = 13, fontColor = { 255, 215, 0, 255 }, width = "100%",
                },
                -- 快捷买入按钮组
                UI.Panel {
                    width = "100%", flexDirection = "row", gap = 4, flexWrap = "wrap",
                    children = (function()
                        local buyBtns = {}
                        local units = { 0.1, 0.5, 1.0 }
                        for _, u in ipairs(units) do
                            local cost = math.floor(goldPrice * u)
                            table.insert(buyBtns, UI.Button {
                                text = "买" .. u .. "oz\n$" .. cost,
                                flex = 1, height = 40, fontSize = 11, borderRadius = 8,
                                backgroundColor = playerData_.money >= cost and { 60, 45, 20, 220 } or { 50, 45, 40, 200 },
                                fontColor = playerData_.money >= cost and { 255, 230, 150, 255 } or { 130, 115, 100, 180 },
                                borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 60 },
                                disabled = playerData_.money < cost,
                                onClick = function()
                                    if playerData_.money >= cost then
                                        playerData_.money = playerData_.money - cost
                                        local actual = u
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            actual = math.floor((u * 1.2) * 10) / 10
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%黄金！")
                                        end
                                        playerData_.goldOunces = (playerData_.goldOunces or 0) + actual
                                        AddLog("🥇 买入黄金 " .. actual .. "oz @ $" .. goldPrice .. "/oz，花费$" .. cost)
                                        PlaySFX("upgrade"); BuildUI()
                                    end
                                end,
                            })
                        end
                        -- "全部买入"按钮
                        local maxBuy = math.floor(playerData_.money / goldPrice * 10) / 10  -- 精确到0.1
                        if maxBuy >= 0.1 then
                            local maxCost = math.floor(goldPrice * maxBuy)
                            table.insert(buyBtns, UI.Button {
                                text = "全买\n" .. maxBuy .. "oz",
                                flex = 1, height = 40, fontSize = 11, borderRadius = 8,
                                backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 },
                                fontColor = { 255, 230, 150, 255 },
                                borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                                onClick = function()
                                    if playerData_.money >= maxCost then
                                        playerData_.money = playerData_.money - maxCost
                                        local actual = maxBuy
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            actual = math.floor((maxBuy * 1.2) * 10) / 10
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%黄金！")
                                        end
                                        playerData_.goldOunces = (playerData_.goldOunces or 0) + actual
                                        AddLog("🥇 全仓买入黄金 " .. actual .. "oz @ $" .. goldPrice .. "/oz，花费$" .. maxCost)
                                        PlaySFX("upgrade"); BuildUI()
                                    end
                                end,
                            })
                        end
                        return buyBtns
                    end)(),
                },
                -- 快捷卖出按钮组（有持仓时显示）
                curGold >= 0.1 and UI.Panel {
                    width = "100%", flexDirection = "row", gap = 4, flexWrap = "wrap",
                    children = (function()
                        local sellBtns = {}
                        local units = { 0.1, 0.5, 1.0 }
                        for _, u in ipairs(units) do
                            if curGold >= u then
                                local income = math.floor(goldPrice * u)
                                table.insert(sellBtns, UI.Button {
                                    text = "卖" .. u .. "oz\n+$" .. income,
                                    flex = 1, height = 40, fontSize = 11, borderRadius = 8,
                                    backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                    fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                    borderWidth = 1, borderColor = { C.green[1], C.green[2], C.green[3], 60 },
                                    onClick = function()
                                        if (playerData_.goldOunces or 0) >= u then
                                            playerData_.goldOunces = playerData_.goldOunces - u
                                            if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                            local actualIncome = income
                                            if (playerData_.goldTradeBonus or 0) > 0 then
                                                actualIncome = math.floor(income * 1.2)
                                                playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                                AddLog("🎫 使用黄金交易优惠券！额外获得20%收入！")
                                            end
                                            playerData_.money = playerData_.money + actualIncome
                                            AddLog("💵 卖出黄金 " .. u .. "oz @ $" .. goldPrice .. "/oz，收入$" .. actualIncome)
                                            PlaySFX("click"); BuildUI()
                                        end
                                    end,
                                })
                            end
                        end
                        -- "全部卖出"按钮
                        if curGold >= 0.1 then
                            local totalIncome = math.floor(goldPrice * curGold)
                            table.insert(sellBtns, UI.Button {
                                text = "全卖\n+$" .. totalIncome,
                                flex = 1, height = 40, fontSize = 11, borderRadius = 8,
                                backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                borderWidth = 1, borderColor = { C.green[1], C.green[2], C.green[3], 80 },
                                onClick = function()
                                    local sellAll = playerData_.goldOunces or 0
                                    if sellAll >= 0.1 then
                                        local income = math.floor(goldPrice * sellAll)
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            income = math.floor(income * 1.2)
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%收入！")
                                        end
                                        playerData_.goldOunces = 0
                                        playerData_.money = playerData_.money + income
                                        AddLog("💵 清仓卖出黄金 " .. string.format("%.1f", sellAll) .. "oz @ $" .. goldPrice .. "/oz，收入$" .. income)
                                        PlaySFX("click"); BuildUI()
                                    end
                                end,
                            })
                        end
                        return sellBtns
                    end)(),
                } or nil,
                -- 黄金消费玩法（第20天后+有黄金持仓时解锁）
                (playerData_.day >= 20 and curGold >= 0.5) and UI.Panel {
                    width = "100%", gap = 4, paddingTop = 4,
                    children = {
                        UI.Label { text = "── 黄金投资 ──", fontSize = 11, fontColor = { 255, 215, 0, 180 }, textAlign = "center", width = "100%" },
                        -- 黄金装饰：花0.5oz，永久每日声望+3
                        (not playerData_.goldDecor) and UI.Button {
                            text = "黄金奖杯装饰 (0.5oz) → 每日声望+3",
                            width = "100%", height = 38, fontSize = 12, borderRadius = 8,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 0.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 0.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 0.5
                                    playerData_.goldDecor = true
                                    AddLog("🏆 用0.5盎司黄金打造了一座闪闪发光的奖杯！摆在柜台上，每天都能吸引更多客人。（每日声望+3）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        } or UI.Label { text = "黄金奖杯已展示（每日声望+3）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 },
                        -- 黄金键帽：花1oz，永久战队+15战力
                        playerData_.goldKeycaps and UI.Label { text = "黄金键帽已装备（战队+15战力）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金键帽套装 (1oz) → 战队战力+15",
                            width = "100%", height = 38, fontSize = 12, borderRadius = 8,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 1.0,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 1.0 then
                                    playerData_.goldOunces = playerData_.goldOunces - 1.0
                                    playerData_.goldKeycaps = true
                                    AddLog("⌨️ 从拉各斯定制了一套纯金键帽！队员们爱不释手，手感和气场直接拉满。（战队永久+15战力）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金赞助：花2oz，karma+2 声望+50（可重复）
                        UI.Button {
                            text = "赞助社区电竞赛 (2oz) → 声望+50 karma+2",
                            width = "100%", height = 38, fontSize = 12, borderRadius = 8,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 2.0,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 2.0 then
                                    playerData_.goldOunces = playerData_.goldOunces - 2.0
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.reputation = playerData_.reputation + 50
                                    playerData_.karma = playerData_.karma + 2
                                    AddLog("🤝 你用黄金赞助了一场社区电竞赛事！全城的年轻人都来参加了。你的名字被印在了奖杯上。（声望+50，karma+2）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金保险箱：花1.5oz，贬值/政变现金损失减半
                        playerData_.goldSafe and UI.Label { text = "黄金保险箱已启用（损失减半）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金保险箱 (1.5oz) → 贬值/政变损失减半",
                            width = "100%", height = 38, fontSize = 12, borderRadius = 8,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = 1, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
                            disabled = curGold < 1.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 1.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 1.5
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.goldSafe = true
                                    AddLog("🔐 你在黑市搞到了一个瑞士产黄金保险箱！把最重要的现金锁在里面，再也不怕贬值和政变了。（贬值/政变现金损失减半）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金VIP卡：花2.5oz，永久每日收入+15%
                        playerData_.goldVIP and UI.Label { text = "黄金VIP已激活（收入+15%）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金VIP卡 (2.5oz) → 每日收入+15%",
                            width = "100%", height = 38, fontSize = 12, borderRadius = 8,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = 1, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
                            disabled = curGold < 2.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 2.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 2.5
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.goldVIP = true
                                    AddLog("💳 一张闪闪发光的黄金VIP卡！凭此卡在拉各斯商业圈享受顶级待遇，合作伙伴们纷纷主动上门。（每日收入永久+15%）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                    },
                } or nil,
                -- 💰 看广告 → 下次黄金买卖获得额外收益
                AdManager.AdButton {
                    sceneId = "gold_trade_bonus", day = playerData_.day,
                    text = "看广告 → 下次黄金交易额外+20%收益",
                    width = "100%", height = 36, fontSize = 12, borderRadius = 8,
                    backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, fontColor = { 255, 220, 100, 255 },
                    borderWidth = 1, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 100 },
                    onReward = function()
                        playerData_.goldTradeBonus = (playerData_.goldTradeBonus or 0) + 1
                        playerData_.questGoldTradeCount = (playerData_.questGoldTradeCount or 0) + 1
                        AddLog("📺 赞助商赠送黄金交易优惠券！下次买入/卖出黄金时额外获得20%收益！")
                        PlaySFX("coin")
                        BuildUI()
                    end,
                },
            },
        }
    end
    -- 开分店（资金≥8000 + 分店<3）
    local branchCount = #(playerData_.branches or {})
    local nextBranchCost = BRANCH_COSTS[branchCount + 1] or 9000
    local canBranch = playerData_.money >= 8000 and branchCount < 3
    if canBranch and branchOpenStep_ == 0 then
        table.insert(expandActions, ActionBtn {
            text = "开分店 $" .. nextBranchCost .. " (第" .. (branchCount + 1) .. "家)",
            disabled = playerData_.money < nextBranchCost,
            onClick = function()
                branchOpenLocOpts_ = RollBranchLocationOptions()
                branchOpenStep_ = 1
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    -- 分店开设流程：步骤1-选地点
    if branchOpenStep_ == 1 and branchOpenLocOpts_ then
        local locBtns = {
            PanelHeader("选择分店城市", { icon = "", color = C.gold }),
            UI.Label { text = "在这些城市中选一个开设分店", fontSize = 12, fontColor = C.textDim, textAlign = "center", width = "100%" },
        }
        for _, loc in ipairs(branchOpenLocOpts_) do
            table.insert(locBtns, UI.Button {
                text = loc.name .. "\n" .. loc.desc .. "\n" .. loc.bonusDesc,
                width = "100%", height = 70, fontSize = 13, borderRadius = 10,
                backgroundColor = C.accentLight, fontColor = C.text,
                borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    branchOpenSelLoc_ = loc
                    branchOpenStep_ = 2
                    PlaySFX("click")
                    BuildUI()
                end,
            })
        end
        table.insert(locBtns, UI.Button {
            text = "← 取消", width = "100%", height = 36, fontSize = 13, borderRadius = 8,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 0; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.accentLight, borderRadius = 12,
            borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = locBtns,
        })
    end
    -- 分店开设流程：步骤2-选游戏
    if branchOpenStep_ == 2 and branchOpenSelLoc_ then
        local gameBtns = {
            PanelHeader("选择主营游戏", { icon = nil, color = C.gold }),
            UI.Label { text = branchOpenSelLoc_.name .. " 分店 · 选择特色游戏", fontSize = 12, fontColor = C.accent, textAlign = "center", width = "100%" },
        }
        for _, game in ipairs(BRANCH_GAMES) do
            table.insert(gameBtns, UI.Button {
                text = game.name .. " — " .. game.desc .. "\n" .. game.bonusDesc,
                width = "100%", height = 56, fontSize = 13, borderRadius = 10,
                backgroundColor = C.cardAlt, fontColor = C.text,
                borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 80 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    PlaySFX("upgrade")
                    DoOpenBranch(branchOpenSelLoc_, game)
                end,
            })
        end
        table.insert(gameBtns, UI.Button {
            text = "← 重选城市", width = "100%", height = 36, fontSize = 13, borderRadius = 8,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 1; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.cardAlt, borderRadius = 12,
            borderWidth = 1, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = gameBtns,
        })
    end

    -- ── 5) 章节推进（放在"结束今天"下方，提高感知度） ──
    local chapterBtn = nil
    if hasNext then
        if canAdv then
            chapterBtn = UI.Button {
                text = (CHAPTERS[nextCh] and CHAPTERS[nextCh].title or "下一章") .. " →",
                width = "100%", height = 48, fontSize = 15, fontWeight = "bold", borderRadius = 10,
                variant = "primary",
                onClick = function() StartChapterWithTransition(nextCh) end,
            }
        else
            chapterBtn = UI.Panel {
                width = "100%", paddingHorizontal = 12, paddingVertical = 8,
                backgroundColor = { C.border[1], C.border[2], C.border[3], 60 },
                borderRadius = 10, alignItems = "center",
                children = {
                    UI.Label { text = advReason, fontSize = 13, fontColor = C.textDim },
                },
            }
        end
    else
        chapterBtn = UI.Panel {
            width = "100%", paddingHorizontal = 12, paddingVertical = 8,
            backgroundColor = { C.green[1], C.green[2], C.green[3], 25 },
            borderRadius = 10, alignItems = "center",
            children = {
                UI.Label { text = "所有章节已完成", fontSize = 13, fontColor = C.green },
            },
        }
    end

    -- （已精简：移除夜间加练和日结奖金广告，只保留翻倍收入和额外AP，减少广告干扰）

    -- ── 辅助：分区标题 ──
    local function SectionTitle(icon, title)
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            paddingTop = 4, paddingBottom = 2,
            children = {
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
                UI.Label { text = icon .. " " .. title, fontSize = 12, fontColor = C.textDim, flexShrink = 0 },
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
            },
        }
    end

    -- ── 辅助：分区容器 ──
    local function SectionPanel(items)
        if #items == 0 then return nil end
        return UI.Panel {
            width = "100%", gap = 6,
            children = items,
        }
    end

    -- ── 组装卡片（分区清晰，结构明确） ──
    local cardChildren = { header }

    -- 广告区
    if adDoubleIncome then table.insert(cardChildren, adDoubleIncome) end
    if adExtraAP then table.insert(cardChildren, adExtraAP) end

    -- 章节 + 委托
    if chapterBtn then table.insert(cardChildren, chapterBtn) end
    if questPanel then table.insert(cardChildren, questPanel) end

    -- 核心经营（集市/传单/招募/比赛）
    table.insert(cardChildren, gridPanel)
    if tierPanel then table.insert(cardChildren, tierPanel) end
    if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end

    -- 网吧实况
    if cafePanel then table.insert(cardChildren, cafePanel) end

    -- 设备维护区块
    if #maintActions > 0 then
        table.insert(cardChildren, SectionTitle("🔧", "设备维护"))
        local mp = SectionPanel(maintActions)
        if mp then table.insert(cardChildren, mp) end
    end

    -- 副业赚钱区块
    if #sideJobActions > 0 then
        table.insert(cardChildren, SectionTitle("💼", "副业赚钱"))
        local sp = SectionPanel(sideJobActions)
        if sp then table.insert(cardChildren, sp) end
    end

    -- 团队与社交区块
    if #socialActions > 0 then
        table.insert(cardChildren, SectionTitle("🤝", "团队社交"))
        local sop = SectionPanel(socialActions)
        if sop then table.insert(cardChildren, sop) end
    end

    -- 黄金交易区块
    if goldPanel then
        table.insert(cardChildren, SectionTitle("🥇", "黄金交易"))
        table.insert(cardChildren, goldPanel)
    end

    -- 扩张经营区块
    if #expandActions > 0 then
        table.insert(cardChildren, SectionTitle("🏗️", "扩张经营"))
        local ep = SectionPanel(expandActions)
        if ep then table.insert(cardChildren, ep) end
    end

    -- 结束今天（始终在最底部）
    table.insert(cardChildren, endDayBtn)

    return UI.Panel {
        width = "100%", padding = 12, gap = 10,
        backgroundColor = C.card, borderRadius = 14, borderWidth = 1, borderColor = C.border,
        children = cardChildren,
    }
end

function GetUpgradeCur(key)
    if key == "computer" then return playerData_.computers - 3
    elseif key == "chair" then return playerData_.chairLevel - 1
    elseif key == "net" then return playerData_.netSpeed - 1
    elseif key == "ac" then return playerData_.acLevel
    elseif key == "solar" then return playerData_.solarLevel
    elseif key == "food" then return playerData_.foodShop
    elseif key == "deco" then return playerData_.decoLevel
    elseif key == "security" then return playerData_.securityLevel
    elseif key == "generator" then return playerData_.generatorLevel or 0
    elseif key == "well" then return playerData_.wellLevel or 0
    elseif key == "road" then return playerData_.roadLevel or 0
    elseif key == "coffee" then return playerData_.coffeeLevel or 0
    elseif key == "jukebox" then return playerData_.jukeboxLevel or 0
    end
    return 0
end

--- 构建"正在升级中"的进度卡片
local function BuildUpgradeProgressPanel()
    if not activeUpgrade_ then return nil end
    local cfg = UPGRADES[activeUpgrade_]
    if not cfg then return nil end
    local pct = 1.0 - (upgradeTimeLeft_ / math.max(1, upgradeTotalTime_))
    local timeStr = FormatUpgradeTime(math.max(0, upgradeTimeLeft_))
    local canAd = AdManager.CanWatch("upgrade_skip", playerData_.day)
    local adChildren = {}
    if canAd then
        table.insert(adChildren, AdManager.AdButton {
            sceneId = "upgrade_skip", day = playerData_.day,
            text = "看广告立即完成", width = "100%", height = 34, fontSize = 12,
            onReward = function()
                AddLog("📺 赞助商加速！升级立即完成！")
                CompleteUpgrade()
            end,
        })
    end
    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.cardAlt, borderRadius = 10,
        borderWidth = 1, borderColor = C.border,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                UI.Label { text = cfg.icon, fontSize = 22 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = cfg.name .. " 升级中...", fontSize = 14, fontColor = C.green, fontWeight = "bold" },
                    UI.Label { text = cfg.levelDesc and cfg.levelDesc[GetUpgradeCur(activeUpgrade_) + 1] or "", fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                }},
                UI.Label { id = "upgrade-time-label", text = timeStr, fontSize = 16, fontColor = C.gold, fontWeight = "bold" },
            }},
            -- 进度条
            UI.Panel { width = "100%", height = 8, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = 4, overflow = "hidden", children = {
                UI.Panel { id = "upgrade-progress-fill", width = math.floor(pct * 100) .. "%", height = "100%", backgroundColor = C.green, borderRadius = 4 },
            }},
            table.unpack(adChildren),
        },
    }
end

--- 生成小标签 pill（图标+文字的彩色小标签）
local function UpgradePill(icon, text, bgColor, fgColor)
    return UI.Panel {
        flexDirection = "row", alignItems = "center", gap = 3,
        paddingHorizontal = 6, paddingVertical = 2,
        backgroundColor = bgColor, borderRadius = 6,
        children = {
            UI.Label { text = icon, fontSize = 11 },
            UI.Label { text = text, fontSize = 11, fontColor = fgColor, fontWeight = "bold" },
        },
    }
end

--- 生成单个升级物品卡片
local function BuildUpgradeItemCard(key)
    local cfg = UPGRADES[key]
    if not cfg then return nil end
    local cur = GetUpgradeCur(key)
    local nxt = cur + 1
    local maxLevels = cfg.costs and #cfg.costs or 0
    local maxed = nxt > maxLevels
    local cost = not maxed and cfg.costs[nxt] or nil
    local curDesc = cfg.levelDesc and cfg.levelDesc[cur] or nil
    local nxtDesc = cfg.levelDesc and cfg.levelDesc[nxt] or nil
    local isActive = activeUpgrade_ == key
    local hasPending = activeUpgrade_ ~= nil and not isActive
    local canAfford = cost and CanAffordCost(cost) or false
    local coupTag = IsCoupActive() and not maxed and "[政变]" or ""

    -- 等级文本 Lv.X/Max
    local lvText = maxed and ("Lv.MAX") or ("Lv." .. cur .. "/" .. maxLevels)
    local lvColor = maxed and C.green or C.textDim

    -- 等级指示条（用小方块代替小圆点，更容易看）
    local dots = {}
    for i = 1, maxLevels do
        table.insert(dots, UI.Panel {
            width = 8, height = 4, borderRadius = 2,
            backgroundColor = i <= cur and C.accent or C.border,
        })
    end

    -- 描述：当前 → 下级
    local descText
    if maxed then
        descText = curDesc or cfg.desc
    elseif curDesc and nxtDesc then
        descText = curDesc .. " → " .. nxtDesc
    elseif nxtDesc then
        descText = cfg.desc .. " → " .. nxtDesc
    else
        descText = cfg.desc
    end

    -- ── 底部操作栏 ──
    local bottomRow = {}
    if maxed then
        -- 满级：只显示满级标识
        table.insert(bottomRow, UpgradePill("", "满级", { C.green[1], C.green[2], C.green[3], 40 }, C.green))
    elseif isActive then
        -- 升级中
        table.insert(bottomRow, UpgradePill("", "升级中", { C.gold[1], C.gold[2], C.gold[3], 40 }, C.gold))
    else
        -- 可升级：显示费用标签 + 时间标签 + 升级按钮
        if cost then
            local costText = FormatCostText(cost)
            local timeText = FormatUpgradeTime(CalcUpgradeTime(cost, key))
            table.insert(bottomRow, UpgradePill("", costText,
                canAfford and { C.green[1], C.green[2], C.green[3], 40 } or { C.red[1], C.red[2], C.red[3], 40 },
                canAfford and C.green or C.red))
            table.insert(bottomRow, UpgradePill("", timeText, { C.blue[1], C.blue[2], C.blue[3], 40 }, C.blue))
        end
        -- 弹性占位，把按钮推到右边
        table.insert(bottomRow, UI.Panel { flex = 1 })
        table.insert(bottomRow, UI.Button {
            text = coupTag .. "升级",
            height = 28, paddingHorizontal = 16, fontSize = 12, borderRadius = 8,
            disabled = hasPending or not canAfford,
            onClick = function() DoUpgrade(key) end,
        })
    end

    local borderCol = maxed and { C.border[1], C.border[2], C.border[3], 120 }
        or isActive and { C.green[1], C.green[2], C.green[3], 180 }
        or (IsCoupActive() and { 220, 180, 60, 160 } or C.border)

    return UI.Panel {
        width = "100%", padding = 10, gap = 5,
        backgroundColor = isActive and C.upgrade_active or (maxed and C.upgrade_max or C.upgrade_bg),
        borderRadius = 10, borderWidth = 1, borderColor = borderCol,
        children = {
            -- 第1行：名称缩写色块 + 名称 + 等级
            UI.Panel { flexDirection = "row", alignItems = "center", width = "100%", gap = 8, children = {
                -- 缩写色块
                UI.Panel {
                    width = 36, height = 36, borderRadius = 8,
                    backgroundColor = maxed and C.green or (isActive and C.gold or C.accent),
                    justifyContent = "center", alignItems = "center",
                    children = { UI.Label { text = (cfg.icon ~= "" and cfg.icon) or string.sub(cfg.name, 1, 3), fontSize = (cfg.icon ~= "" and 20) or 12, fontWeight = "bold", fontColor = { 255, 255, 255, 255 } } },
                },
                -- 名称 + 等级条
                UI.Panel { flex = 1, gap = 3, children = {
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                        UI.Label { text = cfg.name, fontSize = 14, fontColor = C.text, fontWeight = "bold" },
                        UI.Label { text = lvText, fontSize = 11, fontColor = lvColor },
                    }},
                    UI.Panel { flexDirection = "row", gap = 2, alignItems = "center", children = dots },
                }},
            }},
            -- 第2行：描述
            UI.Label {
                text = descText,
                fontSize = 11, fontColor = maxed and { 110, 190, 110, 200 } or C.textDim,
                whiteSpace = "normal", width = "100%", paddingLeft = 2,
            },
            -- 第3行：费用标签 + 时间标签 + 按钮
            UI.Panel {
                flexDirection = "row", alignItems = "center", width = "100%", gap = 6,
                children = bottomRow,
            },
        },
    }
end

--- 生成一组升级卡片
local function BuildUpgradeGroup(keys, children)
    for _, key in ipairs(keys) do
        local card = BuildUpgradeItemCard(key)
        if card then table.insert(children, card) end
    end
end

function BuildUpgradeCard()
    local children = {}

    -- 正在升级的进度卡片（置顶）
    local progressPanel = BuildUpgradeProgressPanel()
    if progressPanel then
        table.insert(children, progressPanel)
        table.insert(children, UI.Divider { spacing = 4 })
    end

    table.insert(children, PanelHeader("升级·集市", { icon = nil, compact = true }))
    BuildUpgradeGroup(UPGRADE_ORDER, children)

    -- ── 社区投资分组 ──
    table.insert(children, UI.Divider { spacing = 6 })
    table.insert(children, PanelHeader("社区投资", { icon = "🏘️", compact = true, color = C.blue }))
    BuildUpgradeGroup(UPGRADE_COMMUNITY, children)

    -- ── 文化空间分组 ──
    table.insert(children, UI.Divider { spacing = 6 })
    table.insert(children, PanelHeader("文化空间", { icon = "🎭", compact = true, color = { 220, 140, 80, 255 } }))
    BuildUpgradeGroup(UPGRADE_CULTURE, children)

    -- 联动加成展示
    local synergies = CalcUpgradeSynergies()
    if #synergies > 0 then
        table.insert(children, UI.Divider { spacing = 4 })
        table.insert(children, PanelHeader("联动加成", { icon = "🔗", compact = true, color = C.gold }))
        for _, s in ipairs(synergies) do
            table.insert(children, UI.Label {
                text = s.name, fontSize = 14, fontColor = C.green,
            })
        end
    end
    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = 12, borderWidth = 1, borderColor = C.border,
        children = children,
    }
end

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
            padding = 5, backgroundColor = C.cardAlt, borderRadius = 8,
            children = {
                m.avatar and UI.Panel {
                    width = 36, height = 36, borderRadius = 18,
                    backgroundImage = m.avatar, backgroundFit = "cover",
                    borderWidth = 1, borderColor = C.accent,
                } or UI.Label { text = m.emoji, fontSize = 18 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = m.name .. " · " .. m.trait, fontSize = 13, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = "天" .. m.talent, fontSize = 13, fontColor = C.blue },
                        UI.Label { text = moodIcon .. m.mood, fontSize = 13, fontColor = moodColor },
                    }},
                    -- 技能进度条
                    UI.Panel { flexDirection = "row", gap = 4, alignItems = "center", width = "100%", children = {
                        UI.Label { text = "技" .. m.skill, fontSize = 13, fontColor = C.green },
                        UI.Panel { flex = 1, height = 4, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = 2, overflow = "hidden", children = {
                            UI.Panel { width = skillPct .. "%", height = "100%", backgroundColor = C.green, borderRadius = 2 },
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
                    UI.Button { text = "练", height = 32, paddingHorizontal = 10, fontSize = 13,
                        disabled = playerData_.actionPoints <= 0,
                        onClick = function()
                            StartTransition("特训时间", m.name .. " · " .. m.trait, function()
                                StartTraining(i)
                            end)
                        end },
                    UI.Button { text = dismissConfirmIdx_ == i and "确认？" or "解雇", height = 26,
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
        backgroundColor = C.card, borderRadius = 12, borderWidth = 1, borderColor = C.border,
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
        backgroundColor = C.card, borderRadius = 14, borderWidth = 1, borderColor = C.border,
        children = logChildren,
    }
end

