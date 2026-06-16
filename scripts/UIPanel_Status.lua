---@diagnostic disable: undefined-global
local PrestigeSystem = require("PrestigeSystem")
local NarrativeLayer = require("NarrativeLayer")

function BuildStatusBar()
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local tDesc, tColor = GetTrafficDesc(traffic, capacity)
    local moneyStr = "$" .. FormatMoney(playerData_.money)
    local ap = playerData_.actionPoints
    local ratio = capacity > 0 and (traffic / capacity) or 0
    local pct = math.min(100, math.floor(ratio * 100))
    local barColor
    if ratio >= 1.0 then barColor = C.green
    elseif ratio >= 0.7 then barColor = C.gold
    else barColor = C.textLight end

    -- 天气标签（emoji + 完整名，badge 仅显示 emoji 节省空间）
    local weatherLabel, weatherColor, weatherName = GetWeatherLabel()

    -- 章节目标：拆解子条件 + 计算进度
    local nextCh = currentChapter_ + 1
    local goalLabel = ""
    local goalSubs = {}  -- { { text=显示文本, done=是否完成 }, ... }
    local goalDone = false
    if nextCh <= #CHAPTERS then
        if nextCh == 2 then
            goalLabel = "第二章"
            local dayOk = playerData_.day >= 4
            local memOk = #teamMembers_ >= 1
            goalSubs = {
                { text = "第4天", done = dayOk, cur = playerData_.day, max = 4 },
                { text = "招1名队员", done = memOk, cur = #teamMembers_, max = 1 },
            }
        elseif nextCh == 3 then
            goalLabel = "第三章"
            local memOk = #teamMembers_ >= 2
            local avgSk = (type(GetTeamAvgSkill) == "function") and GetTeamAvgSkill() or 0
            local skOk = avgSk >= 30
            goalSubs = {
                { text = "2名队员", done = memOk, cur = #teamMembers_, max = 2 },
                { text = "技术30", done = skOk, cur = avgSk, max = 30 },
            }
        elseif nextCh == 4 then
            goalLabel = "第四章"
            local dayOk = playerData_.day >= 14
            local repOk = (playerData_.reputation or 0) >= 80
            goalSubs = {
                { text = "第14天", done = dayOk, cur = playerData_.day, max = 14 },
                { text = "声望80", done = repOk, cur = playerData_.reputation or 0, max = 80 },
            }
        elseif nextCh == 5 then
            goalLabel = "第五章"
            local dayOk = playerData_.day >= 18
            local winOk = (playerData_.tournamentWins or 0) >= 1
            goalSubs = {
                { text = "第18天", done = dayOk, cur = playerData_.day, max = 18 },
                { text = "赢1次锦标赛", done = winOk, cur = playerData_.tournamentWins or 0, max = 1 },
            }
        else
            goalLabel = "继续发展"
        end
    else
        goalLabel = "全部通关"
        goalDone = true
    end
    -- 计算总进度
    local doneCount = 0
    for _, s in ipairs(goalSubs) do if s.done then doneCount = doneCount + 1 end end
    local goalProgress = #goalSubs > 0 and (doneCount / #goalSubs) or (goalDone and 1.0 or 0)
    local goalPct = math.floor(goalProgress * 100)

    -- 政变警告
    local coupWarn = nil
    if IsCoupActive() then
        coupWarn = UI.Panel {
            width = "100%", paddingVertical = 2, paddingHorizontal = 8,
            backgroundColor = { 200, 50, 50, 60 }, borderRadius = PX.radiusSm,
            children = {
                UI.Label { text = "[政变] 剩余" .. playerData_.coupDaysLeft .. "天",
                    fontSize = 11, fontWeight = "bold", fontColor = C.red, textAlign = "center" },
            },
        }
    end

    -- P2-2：收支明细展开状态
    local sbExpanded = playerData_.statusBarExpanded == true
    local income2 = 0
    ---@diagnostic disable-next-line: assign-type-mismatch
    do local ok, v = pcall(CalcDailyIncome); if ok then income2 = v end end
    local expense2 = 0
    do local ok, _, v = pcall(CalcDailyExpenses); if ok then expense2 = v end end
    local net2 = income2 - expense2
    local netColor2 = net2 >= 0 and C.green or C.red
    local netSign2 = net2 >= 0 and "+" or ""

    -- P0-a: 收支展开面板 — 叙事化表达
    ---@diagnostic disable-next-line: param-type-mismatch
    local narrInc, narrExp, narrNet = NarrativeLayer.GetNarrativeFinance(income2, expense2, tonumber(traffic) or 0)
    local incomeDetailPanel = sbExpanded and UI.Panel {
        width = "100%", gap = 4,
        paddingHorizontal = 6, paddingVertical = 5,
        backgroundColor = { 30, 40, 30, 100 }, borderRadius = 4,
        children = {
            -- 叙事描述行
            UI.Label { text = narrNet, fontSize = 12, fontWeight = "bold", fontColor = netColor2, whiteSpace = "normal" },
            -- 详细数字行（缩小辅助）
            UI.Panel { flexDirection = "row", gap = 8, children = {
                UI.Label { text = "收$" .. income2, fontSize = 10, fontColor = C.green },
                UI.Label { text = "支$" .. expense2, fontSize = 10, fontColor = C.red },
                UI.Label { text = "净" .. netSign2 .. "$" .. math.abs(net2), fontSize = 10, fontColor = netColor2 },
            }},
        },
    } or nil

    -- 动态构建 children，避免 nil 在中间位置截断 ipairs
    local sbChildren = {}

    -- 行1: cafeName + 金额 + 天数
    table.insert(sbChildren, UI.Panel {
        width = "100%", flexDirection = "row", alignItems = "center",
        justifyContent = "space-between",
        children = {
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 6, flexShrink = 1,
                onClick = function()
                    playerData_.statusBarExpanded = not (playerData_.statusBarExpanded == true)
                    BuildUI()
                end,
                children = {
                    UI.Label { text = playerData_.cafeName, fontSize = 13, fontColor = C.text, flexShrink = 1 },
                    UI.Label { text = moneyStr, fontSize = 15, fontWeight = "bold", fontColor = C.moneyGreen },
                    UI.Label { text = sbExpanded and "▲" or "▼", fontSize = 10, fontColor = C.textDim },
                },
            },
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 4,
                children = {
                    UI.Label { text = "D" .. playerData_.day, fontSize = 12, fontWeight = "bold", fontColor = C.textDim },
                    UI.Label { text = weatherLabel, fontSize = 14, flexShrink = 0, fontColor = weatherColor },
                    (GetCurrentSeason and GetCurrentSeason()) and UI.Label {
                        text = GetCurrentSeason().name,
                        fontSize = 9, fontColor = { weatherColor[1], weatherColor[2], weatherColor[3], 180 },
                    } or UI.Panel { height = 0 },
                },
            },
        },
    })

    -- 行2: 人气指标 — P0-a 叙事化客流描述
    local narrTraffic = NarrativeLayer.GetNarrativeTraffic(traffic, capacity)
    table.insert(sbChildren, UI.Panel {
        width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
        children = {
            UI.Panel {
                flex = 1, flexDirection = "row", alignItems = "center", gap = 5,
                children = {
                    UI.Label { text = "📊", fontSize = 10, flexShrink = 0 },
                    UI.Label { text = narrTraffic, fontSize = 11, fontColor = tColor, flexShrink = 1 },
                    UI.Panel {
                        flex = 1, height = 6, borderRadius = 3,
                        backgroundColor = { C.border[1], C.border[2], C.border[3], 40 },
                        children = {
                            UI.Panel {
                                width = pct .. "%", height = "100%", borderRadius = 3,
                                backgroundColor = barColor,
                            },
                        },
                    },
                },
            },
        },
    })

    -- P2-2：收支明细展开行（可能为 nil）
    if incomeDetailPanel then table.insert(sbChildren, incomeDetailPanel) end

    -- 2.5 天气效果提示行（展开时显示）
    if sbExpanded and GetWeatherInfo then
        local wInfo = GetWeatherInfo()
        if wInfo and wInfo.weather and wInfo.weather.id ~= "cloudy" then
            local w = wInfo.weather
            local fxParts = {}
            if w.traffic > 0 then table.insert(fxParts, "客流+" .. math.floor(w.traffic*100) .. "%")
            elseif w.traffic < 0 then table.insert(fxParts, "客流" .. math.floor(w.traffic*100) .. "%") end
            if w.income > 0 then table.insert(fxParts, "收入+" .. math.floor(w.income*100) .. "%")
            elseif w.income < 0 then table.insert(fxParts, "收入" .. math.floor(w.income*100) .. "%") end
            if w.power > 0 then table.insert(fxParts, "断电风险+" .. math.floor(w.power*100) .. "%") end
            if #fxParts > 0 then
                table.insert(sbChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 4,
                    paddingHorizontal = 4, paddingVertical = 3,
                    backgroundColor = { w.color[1], w.color[2], w.color[3], 25 },
                    borderRadius = 4,
                    children = {
                        UI.Label { text = w.emoji, fontSize = 10, flexShrink = 0 },
                        UI.Label { text = w.name .. ": " .. table.concat(fxParts, " | "),
                            fontSize = 10, fontColor = { w.color[1], w.color[2], w.color[3], 220 } },
                    },
                })
            end
        end
    end

    -- 章节目标行已移至行动卡片（避免重复）

    -- 政变警告（可能为 nil）
    if coupWarn then table.insert(sbChildren, coupWarn) end

    -- P0-3 挂机收益估算（day>=3 且 action 标签）
    if (playerData_.day or 1) >= 3 and manageTab_ == "action" then
        local autoLevel = playerData_.automationLevel or 0
        local maxHoursByLevel = { [0]=4, [1]=8, [2]=16, [3]=24, [4]=48 }
        local honorBonus = playerData_.honorOfflineBonus or 0
        local maxH = (maxHoursByLevel[autoLevel] or 4) + honorBonus
        local autoNames = { [0]="🧹 帮工小弟", [1]="💰 自动收银", [2]="🔧 稳定运营", [3]="🏪 滚雪球", [4]="👑 连锁帝国" }
        local autoLabel = autoNames[autoLevel] or "未知"

        -- 使用 IdleEngine 精确计算
        local perHour = 0
        local okIdle, IdleEng = pcall(require, "IdleEngine")
        if okIdle and IdleEng and IdleEng.CalcHourlyOffline then
            local okInc, dailyInc = pcall(CalcDailyIncome)
            if not okInc then dailyInc = 0 end
            local dailyExp = playerData_.dailyExpense or 0
            local prestigeMulti = playerData_.prestigeMultiplier or 1.0
            local okCalc, result = pcall(IdleEng.CalcHourlyOffline, dailyInc, dailyExp, autoLevel, prestigeMulti)
            if okCalc and type(result) == "number" then perHour = result end
        end
        local maxEarning = perHour * maxH

        -- 下一级升级提示
        local nextHint = ""
        if autoLevel < 4 and okIdle and IdleEng and IdleEng.CanUnlockAutomation then
            local canUp, _ = IdleEng.CanUnlockAutomation(autoLevel + 1)
            if canUp then
                nextHint = " · ⬆可升级"
            end
        end

        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 4, paddingVertical = 2,
            backgroundColor = { 40, 60, 80, 60 }, borderRadius = 4, gap = 6,
            children = {
                UI.Label { text = "🌙", fontSize = 10 },
                UI.Label {
                    text = autoLabel .. " · $" .. perHour .. "/h · " .. maxH .. "h上限 · 最多$" .. maxEarning .. nextHint,
                    fontSize = 10, fontColor = { 140, 180, 220, 200 }, flex = 1,
                },
            },
        })
    end

    -- B4: 声望进度条（转生达成12天后 or 已有转生次数）
    if (playerData_.day or 1) >= 12 or (playerData_.prestigeCount or 0) > 0 then
        local okPS, PS = pcall(require, "PrestigeSystem")
        if okPS and PS then
            local nextInfo = PS.GetNextCityInfo and PS.GetNextCityInfo()
            if nextInfo and nextInfo.city then
                local honor = nextInfo.currentHonor or 0
                local req = nextInfo.effectiveReq or 1
                local pctP = math.min(1.0, honor / math.max(1, req))
                local barW = math.floor(pctP * 100)  -- percentage width
                local cityLabel = (nextInfo.city.emoji or "") .. " " .. (nextInfo.city.name or "???")
                local fragHint = nextInfo.hasFragment and " 🗺️-" .. math.floor((nextInfo.reduction or 0) * 100) .. "%" or ""
                table.insert(sbChildren, UI.Panel {
                    width = "100%", paddingHorizontal = 4, paddingVertical = 3, gap = 2,
                    backgroundColor = { 80, 50, 20, 50 }, borderRadius = 4,
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, width = "100%", children = {
                            UI.Label { text = "👑", fontSize = 10, flexShrink = 0 },
                            UI.Label { text = "名誉 " .. honor .. "/" .. req .. fragHint,
                                fontSize = 10, fontColor = { 220, 190, 100, 220 }, flex = 1 },
                            UI.Label { text = cityLabel, fontSize = 10, fontColor = { 180, 160, 120, 200 }, flexShrink = 0 },
                        }},
                        -- 像素风进度条
                        PixelBar(pctP, { height = 5, barColor = pctP >= 1.0 and { 100, 220, 100, 220 } or { 220, 180, 60, 200 } }),
                    },
                })
            elseif not nextInfo then
                -- 所有城市已解锁
                local honor = PS.GetPrestigeHonor and PS.GetPrestigeHonor() or 0
                if honor > 0 then
                    table.insert(sbChildren, UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center",
                        paddingHorizontal = 4, paddingVertical = 2,
                        backgroundColor = { 80, 50, 20, 50 }, borderRadius = 4, gap = 4,
                        children = {
                            UI.Label { text = "👑", fontSize = 10 },
                            UI.Label { text = "商会名誉 " .. honor .. " · 全城市已解锁",
                                fontSize = 10, fontColor = { 220, 190, 100, 220 }, flex = 1 },
                        },
                    })
                end
            end
        end
    end

    -- B5: 登录连续天数徽章（简洁版）
    if (playerData_.loginStreak or 0) >= 1 then
        local okRV2, RV2 = pcall(require, "RetentionV2")
        if okRV2 and RV2 and RV2.GetLoginStreakInfo then
            local okInfo, streakInfo = pcall(RV2.GetLoginStreakInfo)
            if okInfo and streakInfo then
                local streak = streakInfo.streakCount or 0
                local cycleDay = streakInfo.day or 1
                local claimed = streakInfo.claimed
                -- 7个小圆点 + 连击数字
                local dots = {}
                for i = 1, 7 do
                    local isPast = i < cycleDay or (i == cycleDay and claimed)
                    local isToday = (i == cycleDay and not claimed)
                    local dotColor = isPast and { 80, 180, 80, 220 }
                        or isToday and { 255, 200, 50, 240 }
                        or { 60, 60, 60, 150 }
                    table.insert(dots, UI.Panel {
                        width = 8, height = 8, borderRadius = 4,
                        backgroundColor = dotColor,
                        borderWidth = isToday and 1 or 0,
                        borderColor = { 255, 230, 100, 200 },
                    })
                end
                local streakColor = streak >= 7 and { 255, 200, 50, 240 }
                    or streak >= 3 and { 180, 220, 140, 220 }
                    or { 140, 160, 180, 200 }
                local claimHint = (not claimed) and " · 可领" or ""
                table.insert(sbChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center",
                    paddingHorizontal = 4, paddingVertical = 2,
                    backgroundColor = { 50, 40, 60, 50 }, borderRadius = 4, gap = 5,
                    children = {
                        UI.Label { text = "📅", fontSize = 10, flexShrink = 0 },
                        UI.Label { text = "连续" .. streak .. "天" .. claimHint,
                            fontSize = 10, fontColor = streakColor, flexShrink = 0 },
                        UI.Panel { flex = 1, flexDirection = "row", justifyContent = "flex-end", gap = 3,
                            alignItems = "center", children = dots },
                    },
                })
            end
        end
    end

    -- C2: 每日一言（状态栏紧凑版，读取缓存）
    if playerData_.todayGreeting and playerData_.dailyGreetingShownDay == playerData_.day then
        local g = playerData_.todayGreeting
        local gColor = g.moodCat == "happy" and { 140, 220, 160, 200 }
            or g.moodCat == "low" and { 220, 160, 120, 200 }
            or { 170, 180, 190, 200 }
        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 4, paddingVertical = 2,
            backgroundColor = { 40, 45, 55, 40 }, borderRadius = 4, gap = 4,
            children = {
                UI.Label { text = g.emoji or "💬", fontSize = 10, flexShrink = 0 },
                UI.Label { text = "\"" .. (g.text or "") .. "\"",
                    fontSize = 10, fontColor = gColor, flex = 1,
                    numberOfLines = 1 },
                UI.Label { text = "— " .. (g.speaker or ""),
                    fontSize = 9, fontColor = { 130, 140, 150, 180 }, flexShrink = 0 },
            },
        })
    end

    -- C1: 章节里程碑进度（紧凑版）
    if (playerData_.day or 1) >= 2 then
        local okCS, CS = pcall(require, "ChapterSystem")
        if okCS and CS and CS.GetCurrentChapterData then
            local chData = CS.GetCurrentChapterData()
            if chData then
                local chNum = CS.GetCurrentChapter()
                local milestones = CS.GetMilestonesDisplay and CS.GetMilestonesDisplay() or {}
                local doneCount2 = 0
                local nextMs = nil
                for _, ms in ipairs(milestones) do
                    if ms.completed then
                        doneCount2 = doneCount2 + 1
                    elseif not nextMs then
                        nextMs = ms
                    end
                end
                local totalMs = #milestones
                local msPct = totalMs > 0 and math.floor(doneCount2 / totalMs * 100) or 0
                local msBarW = msPct .. "%"
                local nextLabel = nextMs and ((nextMs.icon or "") .. " " .. nextMs.title) or "✅ 全部完成"
                table.insert(sbChildren, UI.Panel {
                    width = "100%", paddingHorizontal = 4, paddingVertical = 3, gap = 2,
                    backgroundColor = { 40, 50, 70, 50 }, borderRadius = 4,
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, width = "100%", children = {
                            UI.Label { text = chData.emoji or "📖", fontSize = 10, flexShrink = 0 },
                            UI.Label { text = "第" .. chNum .. "章 " .. doneCount2 .. "/" .. totalMs,
                                fontSize = 10, fontColor = { 160, 190, 220, 220 }, flexShrink = 0 },
                            UI.Label { text = nextLabel,
                                fontSize = 10, fontColor = { 180, 200, 160, 200 }, flex = 1, textAlign = "right" },
                        }},
                        UI.Panel {
                            width = "100%", height = 4, backgroundColor = { 40, 40, 60, 120 }, borderRadius = 2,
                            children = {
                                UI.Panel {
                                    width = msBarW, height = "100%",
                                    backgroundColor = msPct >= 100 and { 100, 220, 150, 220 } or { 100, 160, 220, 200 },
                                    borderRadius = 2,
                                },
                            },
                        },
                    },
                })
            end
        end
    end

    -- P1-6: 今日特别行动事件徽章
    if dailySpecialEvent_ and dailySpecialEvent_.title then
        local evtBg = dailySpecialEvent_.modifier == "traffic" and { 40, 90, 60, 120 }
                   or dailySpecialEvent_.modifier == "income" and { 60, 80, 40, 120 }
                   or { 60, 60, 90, 120 }
        local evtBorder = dailySpecialEvent_.modifier == "traffic" and { 80, 200, 120, 150 }
                       or dailySpecialEvent_.modifier == "income" and { 160, 200, 80, 150 }
                       or { 120, 120, 200, 150 }
        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 6, paddingVertical = 3,
            backgroundColor = evtBg, borderRadius = 4,
            borderWidth = 1, borderColor = evtBorder, gap = 5,
            children = {
                UI.Label { text = dailySpecialEvent_.icon or "⚡", fontSize = 12, flexShrink = 0 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = dailySpecialEvent_.title, fontSize = 11, fontWeight = "bold",
                        fontColor = { 220, 240, 180, 240 }, flexShrink = 1 },
                    dailySpecialEvent_.desc and UI.Label { text = dailySpecialEvent_.desc, fontSize = 10,
                        fontColor = { 180, 200, 160, 180 }, flexShrink = 1, whiteSpace = "normal" } or nil,
                }},
                dailySpecialEvent_.bonus and UI.Label {
                    text = "+" .. dailySpecialEvent_.bonus,
                    fontSize = 11, fontWeight = "bold", fontColor = { 100, 220, 130, 255 }, flexShrink = 0,
                } or nil,
            },
        })
    end

    -- P2-3: 竞争对手压力提示（方案C：高威胁时显示预计日损失）
    if rivalNpcs_ and #rivalNpcs_ > 0 and manageTab_ == "action" then
        local topRival = rivalNpcs_[1]
        local steal = topRival.stealPct or 10
        local rivalColor = topRival.threat == "high" and { 200, 60, 60, 100 }
                        or topRival.threat == "mid" and { 200, 140, 40, 80 }
                        or { 80, 80, 80, 60 }
        local rivalTextColor = topRival.threat == "high" and { 255, 160, 140, 230 }
                            or topRival.threat == "mid" and { 255, 210, 120, 210 }
                            or { 170, 170, 170, 180 }

        -- 方案C: 高威胁时计算估算日损失金额
        local lossLabel = nil
        if steal > 10 then
            local okInc, baseIncome = pcall(CalcDailyIncome)
            if okInc and baseIncome > 0 then
                local estLoss = math.floor(baseIncome * steal / 100)
                lossLabel = UI.Label {
                    text = "-$" .. estLoss .. "/天",
                    fontSize = 10, fontWeight = "bold",
                    fontColor = { 255, 100, 80, 255 }, flexShrink = 0,
                }
            end
        end

        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 6, paddingVertical = 3,
            backgroundColor = rivalColor, borderRadius = 4, gap = 5,
            -- 点击跳转经营标签（方案C: 可交互引导玩家关注）
            onClick = manageTab_ ~= "action" and function()
                manageTab_ = "action"; BuildUI()
            end or nil,
            children = {
                UI.Label { text = "🏪", fontSize = 11, flexShrink = 0 },
                UI.Label {
                    text = topRival.name .. " 开业中 · 抢走约" .. steal .. "%客流",
                    fontSize = 10, fontColor = rivalTextColor, flex = 1, flexShrink = 1,
                },
                lossLabel,
                topRival.threat == "high" and UI.Label { text = "⚠️强敌", fontSize = 10,
                    fontColor = { 255, 120, 100, 255 }, flexShrink = 0 } or nil,
            },
        })
    end

    -- P0-b: NPC 行为微描述（一句环境叙事）
    local npcLine = NarrativeLayer.GetDailyNPCBehavior()
    if npcLine then
        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 5, paddingVertical = 3,
            backgroundColor = { 50, 45, 40, 50 }, borderRadius = 4, gap = 4,
            children = {
                UI.Label { text = "👁️", fontSize = 9, flexShrink = 0 },
                UI.Label { text = npcLine,
                    fontSize = 10, fontColor = { 200, 190, 170, 200 }, flex = 1,
                    whiteSpace = "normal", numberOfLines = 2 },
            },
        })
    end

    -- P1-a: 延迟后果展示（选择的回响）
    local consequence = NarrativeLayer.GetDelayedConsequence()
    if consequence then
        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 5, paddingVertical = 3,
            backgroundColor = { 60, 50, 30, 60 }, borderRadius = 4, gap = 4,
            borderWidth = 1, borderColor = { 180, 150, 80, 60 },
            children = {
                UI.Label { text = "🔮", fontSize = 9, flexShrink = 0 },
                UI.Label { text = consequence,
                    fontSize = 10, fontColor = { 220, 200, 140, 220 }, flex = 1,
                    whiteSpace = "normal", numberOfLines = 2 },
            },
        })
    end

    return UI.Panel {
        width = "100%",
        backgroundColor = C.statusBar,
        borderWidth = { 0, 0, 1, 0 }, borderColor = { C.border[1], C.border[2], C.border[3], 60 },
        paddingHorizontal = 14, paddingVertical = 8, gap = 4,
        children = sbChildren,
    }
end

--- P1-4: 7城征途地图进度胶囊
function BuildRoadmapCapsule()
    -- 城市列表（与 PrestigeSystem 一致）
    local CITIES = {
        { id = "wakandaville", name = "瓦坎达",  icon = "🏠", color = { 100, 160, 100, 255 } },
        { id = "lagos",        name = "拉各斯",  icon = "🌆", color = { 200, 160, 60, 255 }  },
        { id = "nairobi",      name = "内罗毕",  icon = "🌿", color = { 80, 180, 120, 255 }  },
        { id = "accra",        name = "阿克拉",  icon = "🌞", color = { 220, 130, 50, 255 }  },
        { id = "dakar",        name = "达喀尔",  icon = "🌊", color = { 60, 140, 200, 255 }  },
        { id = "capetown",     name = "开普敦",  icon = "⛰️", color = { 160, 100, 200, 255 } },
        { id = "kinshasa",     name = "金沙萨",  icon = "👑", color = { 220, 180, 40, 255 }  },
    }

    local currentCity = playerData_.currentCity or "wakandaville"
    local unlockedCities = playerData_.unlockedCities or { "wakandaville" }
    -- 构建解锁集合
    local unlockedSet = {}
    for _, cid in ipairs(unlockedCities) do unlockedSet[cid] = true end

    local currentIdx = 1
    for i, c in ipairs(CITIES) do
        if c.id == currentCity then currentIdx = i; break end
    end

    -- 城市节点
    local cityNodes = {}
    for i, city in ipairs(CITIES) do
        local isUnlocked = unlockedSet[city.id] == true
        local isCurrent = city.id == currentCity
        local isFuture = not isUnlocked

        local nodeBg = isCurrent and city.color
                    or isUnlocked and { 60, 90, 60, 200 }
                    or { 40, 40, 40, 120 }
        local nameFontColor = isCurrent and { 255, 255, 220, 255 }
                           or isUnlocked and { 180, 220, 160, 200 }
                           or { 100, 100, 100, 140 }
        local iconDisplay = isFuture and "🔒" or city.icon

        -- 连接线（非最后一个城市右侧显示）
        local connectorChildren = nil
        if i < #CITIES then
            local connColor = (isUnlocked and unlockedSet[CITIES[i+1].id]) and { 80, 180, 100, 200 }
                           or { 40, 40, 40, 80 }
            connectorChildren = UI.Panel {
                width = 16, height = 2, alignSelf = "center",
                backgroundColor = connColor, flexShrink = 0,
            }
        end

        local nodeEl = UI.Panel {
            flexDirection = "row", alignItems = "center", flexShrink = 0,
            children = {
                -- 城市节点圆形
                UI.Panel {
                    width = 44, height = 44, borderRadius = 22, flexShrink = 0,
                    backgroundColor = nodeBg,
                    borderWidth = isCurrent and 2 or 1,
                    borderColor = isCurrent and { 255, 255, 200, 220 } or { 80, 80, 80, 100 },
                    alignItems = "center", justifyContent = "center", gap = 1,
                    children = {
                        UI.Label { text = iconDisplay, fontSize = 16 },
                        UI.Label { text = city.name, fontSize = 8, fontColor = nameFontColor,
                            textAlign = "center" },
                    },
                },
                connectorChildren,
            },
        }
        table.insert(cityNodes, nodeEl)
    end

    -- 征途进度文字
    local nextCity = CITIES[currentIdx + 1]
    local progressText = nextCity
        and ("下一站: " .. nextCity.icon .. nextCity.name)
        or "🎉 全城征途完成！"

    return UI.Panel {
        width = "100%", padding = 10, borderRadius = PX.radius,
        backgroundColor = { 30, 45, 35, 200 },
        borderWidth = PX.border, borderColor = { 80, 160, 80, 80 },
        gap = 8,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    UI.Label { text = "🗺️ 征途地图", fontSize = 14, fontWeight = "bold",
                        fontColor = { 140, 220, 140, 240 } },
                    UI.Label { text = progressText, fontSize = 11,
                        fontColor = { 180, 200, 160, 200 } },
                },
            },
            -- 横向滚动的城市胶囊链
            UI.ScrollView {
                width = "100%", height = 56, flexDirection = "row",
                scrollEnabled = true, scrollDirection = "horizontal",
                children = {
                    UI.Panel {
                        flexDirection = "row", alignItems = "center",
                        paddingHorizontal = 4, paddingVertical = 4,
                        children = cityNodes,
                    },
                },
            },
            -- 当前城市加成提示
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                children = {
                    UI.Label { text = "📍", fontSize = 11, flexShrink = 0 },
                    UI.Label {
                        text = "当前: " .. (CITIES[currentIdx].icon or "") .. " " .. (CITIES[currentIdx].name or "")
                            .. " · 收入×" .. string.format("%.1f", (function()
                                if PrestigeSystem and PrestigeSystem.GetCurrentCity then
                                    local ok, city = pcall(PrestigeSystem.GetCurrentCity)
                                    if ok and city then return city.incomeMulti or 1.0 end
                                end
                                return 1.0
                            end)()),
                        fontSize = 11, fontColor = { 160, 210, 160, 200 }, flex = 1,
                    },
                },
            },
            -- C3: 下一个里程碑目标提示
            (function()
                local okCS2, CS2 = pcall(require, "ChapterSystem")
                if not okCS2 or not CS2 or not CS2.GetMilestonesDisplay then return nil end
                local ms2 = CS2.GetMilestonesDisplay()
                local nextMs2 = nil
                for _, m in ipairs(ms2) do
                    if not m.completed then nextMs2 = m; break end
                end
                if not nextMs2 then return nil end
                return UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                    paddingTop = 2,
                    children = {
                        UI.Label { text = "🎯", fontSize = 11, flexShrink = 0 },
                        UI.Label {
                            text = "下一目标: " .. (nextMs2.icon or "") .. " " .. nextMs2.title .. " — " .. nextMs2.desc,
                            fontSize = 11, fontColor = { 180, 180, 220, 200 }, flex = 1,
                        },
                    },
                }
            end)(),
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
                width = "100%", height = 8, borderRadius = PX.radiusSm,
                backgroundColor = C.cardAlt,
                children = {
                    UI.Panel {
                        width = pct .. "%", height = "100%", borderRadius = PX.radiusSm,
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
        width = "100%", padding = 10, borderRadius = PX.cardRadius,
        backgroundColor = C.cardAlt,
        borderWidth = PX.border, borderColor = C.border,
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
                width = "100%", height = 38, fontSize = 13, borderRadius = PX.radius,
                backgroundColor = { C.accent[1], C.accent[2], C.accent[3], 200 }, fontColor = { 255, 255, 255, 255 },
                borderWidth = PX.border, borderColor = C.border,
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
            borderRadius = PX.radius, borderWidth = PX.border,
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
        backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
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
                    width = "100%", height = 5, minHeight = 5, borderRadius = PX.radius,
                    backgroundColor = C.cardAlt,
                    flexShrink = 0,
                    children = {
                        UI.Panel {
                            width = pct .. "%", height = "100%", borderRadius = PX.radius,
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
    ---@diagnostic disable-next-line: assign-type-mismatch
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
        backgroundColor = C.cardAlt, borderRadius = PX.radius,
        padding = 10,
        children = finChildren,
    }

    -- ── 模块5: 联动加成（有才显示） ──
    local synergies = CalcUpgradeSynergies()
    ---@type table|nil
    local synergySection = nil
    if #synergies > 0 then
        ---@diagnostic disable-next-line: assign-type-mismatch
        local synergyItems = {
            PanelHeader("联动加成", { icon = nil, compact = true, color = C.gold }),
        }
        ---@diagnostic disable-next-line: param-type-mismatch
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
                    backgroundColor = { 240, 180, 50, 20 }, borderRadius = PX.radius,
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
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = C.border,
        children = cardChildren,
    }
end

-- ============================================================================
-- 今日经营策略卡（场景图下方横条）
-- ============================================================================
-- ── 策略卡折叠状态 ──
stratCardCollapsed_ = stratCardCollapsed_ or false   -- 是否已自动折叠
stratCardShowTime_ = stratCardShowTime_ or 0         -- 展示起始时间(gameTime_)
stratCardLastDay_ = stratCardLastDay_ or 0           -- 上次记录的天数（换天重置）

function BuildStrategyCard()
    local strat = nil
    if playerData_.todayStrategy and DAILY_STRATEGIES then
        for _, s in ipairs(DAILY_STRATEGIES) do
            if s.id == playerData_.todayStrategy then strat = s; break end
        end
    end

    -- 若当日无策略（第1天初始状态），仅显示提示
    if not strat then
        return UI.Panel {
            width = "100%",
            backgroundColor = { 30, 35, 45, 200 },
            paddingVertical = 8, paddingHorizontal = 12,
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = "📋", fontSize = 18 },
                UI.Label {
                    text = "今日策略将在第一次结算后生效",
                    fontSize = 12, fontColor = C.textDim, flex = 1,
                },
            },
        }
    end

    -- 换天重置折叠状态
    local day = playerData_.day or 1
    if day ~= stratCardLastDay_ then
        stratCardLastDay_ = day
        stratCardCollapsed_ = false
        stratCardShowTime_ = gameTime_ or 0
    end
    -- 首次展示时记录时间
    if stratCardShowTime_ == 0 then
        stratCardShowTime_ = gameTime_ or 0
    end

    local chosen   = playerData_.strategyChosen
    local choice   = playerData_.strategyChoice  -- "A" or "B"
    local optA     = strat.optA
    local optB     = strat.optB

    -- 已选状态：极简折叠条（单行，最小化占位）
    if chosen and choice then
        local pickedOpt = (choice == "A") and optA or optB
        local modPct = math.floor(((pickedOpt.incomeMod or 1.0) - 1.0) * 100)
        local modTag = modPct == 0 and "" or
                       (modPct > 0 and string.format(" +%d%%", modPct) or string.format(" %d%%", modPct))
        local modColor = modPct > 0 and C.green or (modPct < 0 and C.red or C.textDim)
        return UI.Panel {
            width = "100%",
            backgroundColor = { 20, 30, 42, 180 },
            paddingVertical = 4, paddingHorizontal = 10,
            borderRadius = 6,
            flexDirection = "row", alignItems = "center", gap = 6,
            children = {
                UI.Label { text = strat.icon or "📋", fontSize = 13 },
                UI.Label {
                    text = (pickedOpt.label or "") .. modTag,
                    fontSize = 11, fontColor = modColor, flex = 1,
                },
                UI.Button {
                    text = "改选", height = 22, fontSize = 10,
                    backgroundColor = { 50, 50, 70, 150 }, fontColor = C.textDim,
                    borderRadius = 4, paddingHorizontal = 8,
                    onClick = function()
                        playerData_.strategyChosen = false
                        playerData_.strategyChoice = nil
                        PlaySFX("click")
                        BuildUI()
                    end,
                },
            },
        }
    end

    -- 未选但已折叠：极简提示条（点击展开）
    if not chosen and stratCardCollapsed_ then
        return UI.Panel {
            width = "100%",
            backgroundColor = { 20, 30, 42, 180 },
            paddingVertical = 5, paddingHorizontal = 10,
            borderRadius = 6,
            flexDirection = "row", alignItems = "center", gap = 6,
            onClick = function()
                stratCardCollapsed_ = false
                stratCardShowTime_ = gameTime_ or 0  -- 重新计时
                PlaySFX("click")
                BuildUI()
            end,
            children = {
                UI.Label { text = strat.icon or "📋", fontSize = 13 },
                UI.Label {
                    text = "今日策略待选择", fontSize = 11,
                    fontColor = C.textDim, flex = 1,
                },
                UI.Label {
                    text = "展开 ▼", fontSize = 10,
                    fontColor = { 140, 180, 255, 200 },
                },
            },
        }
    end

    -- 未选状态：展开双选面板
    local function makeOptBtn(optKey, opt)
        if not opt then return UI.Panel { width = 0, height = 0 } end
        local mod     = opt.incomeMod or 1.0
        local modPct  = math.floor((mod - 1.0) * 100)
        local modStr  = modPct == 0 and "收入×1.0" or
                        (modPct > 0 and string.format("收入+%d%%", modPct) or string.format("收入%d%%", modPct))
        local modColor = modPct > 0 and C.green or (modPct < 0 and C.red or C.textDim)
        local bgCol   = opt.color or { 50, 80, 120, 200 }
        local isA     = (optKey == "A")
        return UI.Button {
            flex = 1, height = 52, borderRadius = 8,
            backgroundColor = bgCol,
            borderWidth = 1, borderColor = isA and { 100, 170, 255, 160 } or { 255, 160, 60, 160 },
            paddingHorizontal = 8, paddingVertical = 4,
            flexDirection = "column", alignItems = "flex-start", gap = 2,
            onClick = function()
                playerData_.strategyChosen = true
                playerData_.strategyChoice = optKey
                PlaySFX("click")
                BuildUI()
            end,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, children = {
                    UI.Label {
                        text = (isA and "A  " or "B  ") .. (opt.label or ""),
                        fontSize = 12, fontWeight = "bold", fontColor = { 255, 255, 255, 240 },
                    },
                }},
                UI.Label {
                    text = modStr, fontSize = 11, fontColor = modColor,
                },
            },
        }
    end

    return UI.Panel {
        width = "100%",
        backgroundColor = { 20, 28, 40, 220 },
        paddingVertical = 8, paddingHorizontal = 10, gap = 6,
        children = {
            -- 标题行
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 6, width = "100%",
                children = {
                    UI.Label { text = strat.icon or "📋", fontSize = 16 },
                    UI.Panel { flex = 1, gap = 1, children = {
                        UI.Label {
                            text = "今日策略：" .. (strat.title or ""),
                            fontSize = 12, fontWeight = "bold", fontColor = C.text,
                        },
                        UI.Label {
                            text = strat.hint or "",
                            fontSize = 11, fontColor = C.textDim, whiteSpace = "normal",
                        },
                    }},
                },
            },
            -- 双选按钮行
            UI.Panel {
                flexDirection = "row", gap = 8, width = "100%",
                children = {
                    makeOptBtn("A", optA),
                    makeOptBtn("B", optB),
                },
            },
        },
    }
end

-- ============================================================================
-- 事件联动面板（联动进度展示，Day 10+ 显示）
-- ============================================================================

function BuildLinkageCard()
    local ok, EL = pcall(require, "EventLinkage")
    if not ok or not EL then return nil end
    local day = playerData_.day or 0
    if day < 10 then return nil end

    local activeCount, totalCount = EL.GetLinkageSummary()
    if totalCount == 0 then return nil end

    local pct = math.floor(activeCount / totalCount * 100)
    local progress = EL.GetLinkageProgress()

    -- 显示已激活的联动效果简报
    local activeItems = {}
    local pendingItems = {}
    for _, p in ipairs(progress) do
        if p.active then
            table.insert(activeItems, p)
        elseif p.progress > 0 then
            table.insert(pendingItems, p)
        end
    end

    -- 最多显示3个已激活 + 2个进行中
    local children = {}

    -- 已激活联动
    if #activeItems > 0 then
        local activeRows = {}
        for i, p in ipairs(activeItems) do
            if i > 3 then break end
            local lk = p.linkage
            -- 效果描述
            local effectParts = {}
            if lk.reward then
                if lk.reward.allRevenueBonus then table.insert(effectParts, "收入+" .. math.floor(lk.reward.allRevenueBonus * 100) .. "%") end
                if lk.reward.dailyMoneyBonus then table.insert(effectParts, "+$" .. lk.reward.dailyMoneyBonus .. "/天") end
                if lk.reward.trafficBonus then table.insert(effectParts, "客流+" .. math.floor(lk.reward.trafficBonus * 100) .. "%") end
                if lk.reward.repBonus then table.insert(effectParts, "声望+" .. math.floor(lk.reward.repBonus * 100) .. "%") end
                if lk.reward.moodDecayReduction then table.insert(effectParts, "心情衰减-" .. math.floor(lk.reward.moodDecayReduction * 100) .. "%") end
                if lk.reward.equipDecayReduction then table.insert(effectParts, "维护-" .. math.floor(lk.reward.equipDecayReduction * 100) .. "%") end
                if lk.reward.matchPower then table.insert(effectParts, "战力+" .. lk.reward.matchPower) end
            end
            local effectText = #effectParts > 0 and table.concat(effectParts, " ") or ""

            table.insert(activeRows, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 4, paddingVertical = 2,
                children = {
                    UI.Label { text = lk.icon or "🔗", fontSize = 12 },
                    UI.Label { text = lk.name, fontSize = 11, fontColor = C.gold, flex = 1 },
                    UI.Label { text = effectText, fontSize = 10, fontColor = C.green },
                },
            })
        end
        if #activeItems > 3 then
            table.insert(activeRows, UI.Label {
                text = "..." .. (#activeItems - 3) .. " 个更多",
                fontSize = 10, fontColor = C.textDim,
            })
        end
        table.insert(children, UI.Panel { width = "100%", gap = 2, children = activeRows })
    end

    -- 进行中联动（条件部分满足）
    if #pendingItems > 0 then
        local pendingRows = {}
        for i, p in ipairs(pendingItems) do
            if i > 2 then break end
            local lk = p.linkage
            local progBarPct = math.floor(p.progress * 100)
            table.insert(pendingRows, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 4, paddingVertical = 2,
                children = {
                    UI.Label { text = lk.icon or "🔗", fontSize = 12 },
                    UI.Label { text = lk.name, fontSize = 11, fontColor = C.textDim, flex = 1 },
                    UI.Label { text = p.metCount .. "/" .. p.totalConds, fontSize = 10, fontColor = C.textDim },
                    UI.Panel { width = 30, height = 4, backgroundColor = { C.border[1], C.border[2], C.border[3], 100 }, borderRadius = 2, overflow = "hidden", children = {
                        UI.Panel { width = progBarPct .. "%", height = "100%", backgroundColor = { 180, 150, 50, 200 }, borderRadius = 2 },
                    }},
                },
            })
        end
        table.insert(children, UI.Panel {
            width = "100%", gap = 2, paddingTop = 4,
            children = {
                UI.Label { text = "进行中:", fontSize = 10, fontColor = C.textDim },
                table.unpack(pendingRows),
            },
        })
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { C.border[1], C.border[2], C.border[3], 120 },
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                children = {
                    UI.Label { text = "🔗", fontSize = 16 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = "事件联动", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
                            UI.Label { text = activeCount .. "/" .. totalCount .. " 激活", fontSize = 11, fontColor = activeCount > 0 and C.green or C.textDim },
                        }},
                        UI.Panel { width = "100%", height = 5, backgroundColor = { C.border[1], C.border[2], C.border[3], 100 }, borderRadius = 3, overflow = "hidden", children = {
                            UI.Panel { width = pct .. "%", height = "100%", backgroundColor = C.gold, borderRadius = 3 },
                        }},
                    }},
                },
            },
            table.unpack(children),
        },
    }
end
