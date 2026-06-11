---@diagnostic disable: undefined-global
local NPCStorylines = require("NPCStorylines")

-- ============================================================================
-- 日记页面：按天倒序展示每日氛围描写 + 事件日志
-- ============================================================================
function BuildDiaryPage()
    local currentDay = playerData_.day or 1

    -- P0-1 新手引导：第一次打开日记，step 3→99
    if (playerData_.tutorialStep or 0) == 3 then
        playerData_.tutorialStep = 99
        AddLog("🎉 【新手引导完成】你已掌握网吧经营的基础！后续可自由探索升级、比赛和招募功能。")
    end

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

    -- P0 分层显示策略：今天展开 + 近6天折叠 + 更早折入"查看更多"
    local RECENT_LIMIT = 6
    ---@diagnostic disable-next-line: global-element
    showOlderDiary_ = showOlderDiary_ or false
    local visibleDays = {}
    local olderDays = {}
    for idx, day in ipairs(days) do
        local isToday = (day == currentDay)
        if isToday then
            table.insert(visibleDays, day)
        elseif idx <= (RECENT_LIMIT + 1) then
            table.insert(visibleDays, day)
        else
            table.insert(olderDays, day)
        end
    end

    -- 如果用户点击了"查看更多"，把older合入visible
    if showOlderDiary_ then
        for _, d in ipairs(olderDays) do
            table.insert(visibleDays, d)
        end
        olderDays = {}
    end

    for _, day in ipairs(visibleDays) do
        local entry = diaryEntries_[day]
        local isToday = (day == currentDay)
        -- 今天默认展开，其他默认折叠（用户可手动切换）
        local isExpanded
        if expandedDiaryDays_[day] ~= nil then
            isExpanded = expandedDiaryDays_[day] == true
        else
            isExpanded = isToday  -- 默认：今天展开，其他折叠
        end

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

            -- 事件日志（P2-3：最多显示8条，超出折叠）
            if entry.logs and #entry.logs > 0 then
                if entry.atmo and entry.atmo ~= "" then
                    table.insert(contentChildren, UI.Panel {
                        width = "100%", height = 1, marginVertical = 6,
                        backgroundColor = { 210, 180, 140, 60 },
                    })
                end
                local logLimit = 8
                local logsToShow = math.min(#entry.logs, logLimit)
                for i = 1, logsToShow do
                    table.insert(contentChildren, UI.Label {
                        text = entry.logs[i],
                        fontSize = 12, fontColor = C.textDim,
                        whiteSpace = "normal", lineHeight = 1.4, width = "100%",
                    })
                end
                -- 超出部分提示
                if #entry.logs > logLimit then
                    table.insert(contentChildren, UI.Label {
                        text = "…还有 " .. (#entry.logs - logLimit) .. " 条记录",
                        fontSize = 11, fontColor = { C.textDim[1], C.textDim[2], C.textDim[3], 140 },
                        paddingTop = 2,
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
            backgroundColor = cardBg, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = borderCol,
            boxShadow = isToday and { { x = 0, y = 2, blur = 12, color = { C.accent[1], C.accent[2], C.accent[3], 40 } } } or nil,
            children = cardChildren,
        })
    end

    -- "查看更多历史"按钮（有更早天数且未展开时显示）
    if #olderDays > 0 then
        table.insert(dayCards, UI.Button {
            text = "📜 查看更早的 " .. #olderDays .. " 天记录",
            width = "100%", minHeight = 34, fontSize = 12,
            fontColor = C.textDim, backgroundColor = { 255, 255, 255, 10 },
            borderRadius = PX.radius, borderWidth = PX.border, borderColor = C.border,
            onClick = function()
                showOlderDiary_ = true
                BuildUI()
            end,
        })
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 8,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = C.border,
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
        ---@diagnostic disable-next-line: param-type-mismatch
        for _, npcId in ipairs(idList) do
            if not npcTotalEvents[npcId] then npcTotalEvents[npcId] = {} end
            npcTotalEvents[npcId][title] = true
        end
    end

    -- 统计 & 分类
    local metCount = 0
    local fullCount = 0
    local interactiveNpcs = {}  -- 有聊天按钮的
    local metNpcs = {}          -- 已遇见但无互动
    local unmetNpcs = {}        -- 未遇见

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

        local totalKinds = 0
        if npcTotalEvents[profile.id] then
            for _ in pairs(npcTotalEvents[profile.id]) do totalKinds = totalKinds + 1 end
        end

        local isFullStory = isMet and totalKinds > 0 and seenCount >= totalKinds
        if isMet then metCount = metCount + 1 end
        if isFullStory then fullCount = fullCount + 1 end

        local canChat = NPCStorylines and NPCStorylines.CanAdvanceNpc and NPCStorylines.CanAdvanceNpc(profile.id)

        local npcData = { profile = profile, journal = journal, isMet = isMet, seenCount = seenCount, totalKinds = totalKinds, isFullStory = isFullStory, canChat = canChat }
        if isMet and canChat then
            table.insert(interactiveNpcs, npcData)
        elseif isMet then
            table.insert(metNpcs, npcData)
        else
            table.insert(unmetNpcs, npcData)
        end
    end

    -- 构建卡片
    local npcCards = {}

    -- 标题
    table.insert(npcCards, UI.Panel {
        width = "100%", alignItems = "center", paddingBottom = 4,
        children = {
            UI.Label { text = "人物志 · 瓦坎达维尔的人们", fontSize = 16, fontColor = C.accent },
            UI.Label { text = "已相遇 " .. metCount .. "/" .. #NPC_PROFILES .. "   ✦ " .. fullCount, fontSize = 11, fontColor = C.textDim },
        },
    })

    -- ═══ 可互动NPC区域（置顶，完整卡片） ═══
    if #interactiveNpcs > 0 then
        table.insert(npcCards, UI.Label { text = "💬 可互动", fontSize = 12, fontColor = C.gold, paddingLeft = 4 })
    end
    for _, nd in ipairs(interactiveNpcs) do
        local profile = nd.profile
        local journal = nd.journal
        local eventCount = #journal.events
        local storyProgress = (playerData_.npcStoryProgress or {})[profile.id]
        local affinityLevel = 0
        if storyProgress and storyProgress > 0 then
            affinityLevel = math.min(5, storyProgress)
        else
            affinityLevel = math.min(5, math.floor(eventCount / 1.5) + 1)
        end
        local hearts = ""
        for h = 1, 5 do hearts = hearts .. (affinityLevel >= h and "❤️" or "🤍") end

        table.insert(npcCards, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = { 255, 215, 0, 12 },
            borderRadius = PX.radius, borderWidth = 1, borderColor = { 190, 148, 50, 100 },
            children = {
                UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                    children = {
                        UI.Label { text = profile.emoji, fontSize = 20 },
                        UI.Panel { flex = 1, gap = 1, children = {
                            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                                UI.Label { text = profile.name, fontSize = 14, fontColor = C.text },
                                UI.Label { text = profile.role, fontSize = 10, fontColor = C.accent,
                                    backgroundColor = { 240, 180, 80, 30 }, paddingHorizontal = 4, paddingVertical = 1, borderRadius = PX.radiusSm },
                            }},
                            UI.Label { text = hearts, fontSize = 9 },
                        }},
                        UI.Button {
                            text = "💬 聊一聊", height = 28, paddingHorizontal = 10, fontSize = 11,
                            borderRadius = PX.radius, borderWidth = PX.border,
                            backgroundColor = { 26, 18, 10, 255 },
                            fontColor = { 245, 215, 128, 255 }, borderColor = { 190, 148, 50, 200 },
                            onClick = function()
                                if NPCStorylines and NPCStorylines.TryAdvanceNpc then
                                    local ev = NPCStorylines.TryAdvanceNpc(profile.id)
                                    if ev then
                                        currentEvent_ = ev
                                        currentPhase_ = PHASE_EVENT
                                        PlayBGM("event")
                                        BuildUI()
                                    end
                                end
                            end,
                        },
                    },
                },
            },
        })
    end

    -- ═══ 已遇见NPC区域（紧凑行，点击展开） ═══
    if #metNpcs > 0 then
        table.insert(npcCards, UI.Label { text = "📖 已遇见", fontSize = 12, fontColor = C.textDim, paddingLeft = 4, paddingTop = 4 })
    end
    ---@diagnostic disable-next-line: global-element
    expandedNpcId_ = expandedNpcId_ or nil
    for _, nd in ipairs(metNpcs) do
        local profile = nd.profile
        local journal = nd.journal
        local eventCount = #journal.events
        local isExpanded = (expandedNpcId_ == profile.id)
        local storyProgress = (playerData_.npcStoryProgress or {})[profile.id]
        local affinityLevel = 0
        if storyProgress and storyProgress > 0 then
            affinityLevel = math.min(5, storyProgress)
        else
            affinityLevel = math.min(5, math.floor(eventCount / 1.5) + 1)
        end

        local badge, badgeColor
        if nd.isFullStory then badge = "✦"; badgeColor = { 255, 215, 0, 255 }
        else badge = nd.seenCount .. "/" .. nd.totalKinds; badgeColor = C.green end

        local cardChildren = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                children = {
                    UI.Label { text = profile.emoji, fontSize = 18 },
                    UI.Label { text = profile.name, fontSize = 13, fontColor = C.text, flex = 1 },
                    UI.Label { text = badge, fontSize = 10, fontColor = badgeColor },
                    UI.Label { text = isExpanded and "▲" or "▼", fontSize = 10, fontColor = C.textDim },
                },
            },
        }

        -- 展开详情
        if isExpanded then
            local affinityLabel = affinityLevel <= 1 and "初识" or affinityLevel == 2 and "熟悉" or affinityLevel == 3 and "信任" or affinityLevel == 4 and "挚友" or "羁绊"
            local hearts = ""
            for h = 1, 5 do hearts = hearts .. (affinityLevel >= h and "❤️" or "🤍") end
            table.insert(cardChildren, UI.Panel {
                width = "100%", paddingTop = 4, paddingLeft = 26, gap = 2,
                children = {
                    UI.Label { text = profile.role .. " · " .. affinityLabel .. " " .. hearts, fontSize = 11, fontColor = C.textDim },
                    UI.Label { text = profile.bio, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                },
            })
            -- 最近3条事件
            local startIdx = math.max(1, eventCount - 2)
            for i = startIdx, eventCount do
                local ev = journal.events[i]
                local line = "第" .. ev.day .. "天 · " .. ev.title
                table.insert(cardChildren, UI.Label {
                    text = "  · " .. line, fontSize = 11, fontColor = { C.blue[1], C.blue[2], C.blue[3], 200 },
                    paddingLeft = 26, whiteSpace = "normal", width = "100%",
                })
            end
        end

        local npcId = profile.id
        table.insert(npcCards, UI.Panel {
            width = "100%", padding = 8, gap = 2,
            backgroundColor = nd.isFullStory and { 255, 215, 0, 8 } or { 255, 255, 255, 10 },
            borderRadius = PX.radius,
            borderWidth = nd.isFullStory and 1 or 0, borderColor = { 255, 215, 0, 30 },
            onClick = function()
                if expandedNpcId_ == npcId then
                    expandedNpcId_ = nil
                else
                    expandedNpcId_ = npcId
                end
                BuildUI()
            end,
            children = cardChildren,
        })
    end

    -- ═══ 未遇见NPC区域（折叠，点击展开列表） ═══
    if #unmetNpcs > 0 then
        ---@diagnostic disable-next-line: global-element
        showUnmetNpcs_ = showUnmetNpcs_ or false
        local unmetHeader = UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 8, backgroundColor = { 240, 180, 100, 10 }, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { 210, 180, 130, 30 },
            onClick = function()
                showUnmetNpcs_ = not showUnmetNpcs_
                BuildUI()
            end,
            children = {
                UI.Label { text = "🔒", fontSize = 14 },
                UI.Label { text = "未遇见 " .. #unmetNpcs .. " 位居民", fontSize = 12, fontColor = C.textDim, flex = 1 },
                UI.Label { text = showUnmetNpcs_ and "▲" or "▼", fontSize = 10, fontColor = C.textDim },
            },
        }
        table.insert(npcCards, unmetHeader)

        if showUnmetNpcs_ then
            for _, nd in ipairs(unmetNpcs) do
                local profile = nd.profile
                local teaseText = profile.tease or ("据说附近有一位" .. profile.role .. "……")
                table.insert(npcCards, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                    padding = 6, paddingLeft = 16,
                    children = {
                        UI.Label { text = "?", fontSize = 16, fontColor = { 130, 130, 130, 160 } },
                        UI.Panel { flex = 1, gap = 1, children = {
                            UI.Label { text = profile.role, fontSize = 11, fontColor = { 130, 130, 130, 180 } },
                            UI.Label { text = teaseText, fontSize = 10, fontColor = { 120, 120, 120, 120 }, whiteSpace = "normal" },
                        }},
                    },
                })
            end
        end
    end

    -- 全收集彩蛋
    if metCount >= #NPC_PROFILES and fullCount >= #NPC_PROFILES then
        table.insert(npcCards, UI.Panel {
            width = "100%", alignItems = "center", paddingTop = 6,
            children = {
                UI.Label { text = "你改变了瓦坎达维尔每一个人的生活！", fontSize = 12, fontColor = { 255, 215, 0, 220 } },
            },
        })
    end

    return UI.Panel {
        width = "100%", gap = 6,
        children = npcCards,
    }
end

-- ── 独立面板：赛季通行证（原RV2方案10，移至升级Tab） ──
function BuildSeasonPassPanel()
    if not RV2 then return nil end
    local sp = RV2.GetSeasonPassStatus()
    if sp.points <= 0 and (playerData_.day or 1) < 3 then return nil end

    -- 统计可领取数量
    local claimable = 0
    local totalRewards = #sp.rewards
    local claimed = 0
    for _, r in ipairs(sp.rewards) do
        local isClaimed = sp.claimedRewards[tostring(r.points)]
        if isClaimed then
            claimed = claimed + 1
        elseif sp.points >= r.points then
            claimable = claimable + 1
        end
    end

    -- 摘要条：有可领取时高亮，点击展开弹窗
    local hasClaim = claimable > 0
    local borderCol = hasClaim and { 160, 130, 220, 200 } or { 120, 100, 200, 80 }
    local bgCol = hasClaim and { 50, 40, 80, 220 } or { 40, 40, 65, 180 }

    return UI.Panel {
        width = "100%", padding = 10, borderRadius = PX.radius,
        backgroundColor = bgCol,
        borderWidth = hasClaim and 2 or PX.border, borderColor = borderCol,
        gap = 4,
        onClick = function() seasonPassPopupOpen_ = true; BuildUI() end,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                children = {
                    UI.Label { text = "🏅", fontSize = 16 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = "赛季通行证", fontSize = 14, fontWeight = "bold", fontColor = { 200, 180, 255, 240 } },
                            UI.Label { text = sp.points .. "分", fontSize = 12, fontColor = { 255, 220, 100, 220 } },
                        }},
                        UI.Label {
                            text = hasClaim and ("🎁 " .. claimable .. "个奖励可领取！") or ("已领 " .. claimed .. "/" .. totalRewards),
                            fontSize = 11, fontColor = hasClaim and C.green or C.textDim,
                        },
                    }},
                    UI.Label { text = "›", fontSize = 20, fontColor = C.textDim },
                },
            },
        },
    }
end

--- 赛季通行证弹窗（完整奖励列表）
function BuildSeasonPassPopup()
    if not seasonPassPopupOpen_ then return nil end
    if not RV2 then return nil end
    local sp = RV2.GetSeasonPassStatus()

    local rewardItems = {}
    for _, r in ipairs(sp.rewards) do
        local isClaimed = sp.claimedRewards[tostring(r.points)]
        local canClaim = not isClaimed and sp.points >= r.points
        table.insert(rewardItems, UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 6,
            width = "100%", padding = 6,
            backgroundColor = canClaim and { 80, 160, 80, 60 } or { 0, 0, 0, 0 },
            borderRadius = PX.radius,
            children = {
                UI.Label { text = r.icon, fontSize = 16, width = 24 },
                UI.Label { text = r.points .. "分", fontSize = 12, fontColor = C.textLight, width = 36 },
                UI.Label { text = r.desc, fontSize = 12, fontColor = isClaimed and C.textDim or C.text, flex = 1 },
                isClaimed and UI.Label { text = "✅", fontSize = 14 }
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
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 12,
        onClick = function() seasonPassPopupOpen_ = false; BuildUI() end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, maxHeight = "80%",
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = 2, borderColor = { 160, 130, 220, 200 },
                padding = 14, gap = 8,
                onClick = function() end,
                children = {
                    UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", width = "100%", children = {
                        UI.Label { text = "🏅 赛季通行证", fontSize = 16, fontWeight = "bold", fontColor = { 200, 180, 255, 240 } },
                        UI.Button { text = "✕", variant = "ghost", fontSize = 16, fontColor = C.textDim,
                            onClick = function() seasonPassPopupOpen_ = false; BuildUI() end },
                    }},
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, width = "100%", children = {
                        UI.Label { text = "当前积分：", fontSize = 13, fontColor = C.textDim },
                        UI.Label { text = sp.points .. " 分", fontSize = 14, fontColor = { 255, 220, 100, 220 }, fontWeight = "bold" },
                    }},
                    UI.ScrollView { width = "100%", flex = 1, children = {
                        UI.Panel { width = "100%", gap = 4, children = rewardItems },
                    }},
                },
            },
        },
    }
end

-- ── 独立面板：免费迷你游戏（原RV2方案1，移至团队Tab） ──
function BuildFreeMiniGamePanel()
    if not RV2 then return nil end
    local freePlays = RV2.GetFreeMiniGamePlays()
    if freePlays <= 0 then return nil end
    local streakText = (playerData_.miniGameStreak or 0) > 0
        and ("🔥 连胜 x" .. playerData_.miniGameStreak .. " 奖励加成！") or ""
    return UI.Panel {
        width = "100%", padding = 10, borderRadius = PX.radius,
        backgroundColor = { 50, 40, 70, 180 },
        borderWidth = PX.border, borderColor = { 160, 120, 220, 80 },
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
function BuildTeamBondPanel()
    if not RV2 or #teamMembers_ < 2 then return nil end
    local bonds = RV2.GetActiveBonds()
    if #bonds == 0 then return nil end
    local bondItems = {}
    for _, ab in ipairs(bonds) do
        table.insert(bondItems, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 6, borderRadius = PX.radius,
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
        width = "100%", padding = 10, borderRadius = PX.radius,
        backgroundColor = { 50, 35, 40, 180 },
        borderWidth = PX.border, borderColor = { 200, 120, 120, 80 },
        gap = 6,
        children = {
            UI.Label { text = "💞 团队羁绊", fontSize = 15, fontWeight = "bold", fontColor = { 255, 160, 180, 240 }, width = "100%" },
            table.unpack(bondItems),
        },
    }
end
