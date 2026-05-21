---@diagnostic disable: undefined-global
-- ============================================================================
-- 14. 随机事件界面（带背景图）
-- ============================================================================
function BuildEventUI()
    -- 展示行动结果弹窗（逛集市、贴传单等直接产生 eventResult_ 而无 currentEvent_）
    if eventResult_ then
        return BuildEventResultUI()
    end
    if not currentEvent_ then
        -- 不能递归调用 BuildUI，否则外层会用空白面板覆盖导致黑屏
        currentPhase_ = PHASE_MANAGE
        return BuildManageUI()
    end
    local evt = currentEvent_

    local choiceBtns = {}
    if evt.choices then
        for i, ch in ipairs(evt.choices) do
            local disabled = false
            if ch.cond then
                local condOk, condVal = pcall(ch.cond)
                if not condOk then
                    log:Write(LOG_ERROR, "[EventChoice] cond error: " .. tostring(condVal))
                    disabled = false
                else
                    disabled = not condVal
                end
            end
            table.insert(choiceBtns, UI.Button {
                text = ch.text, width = "100%", height = 38, fontSize = 13,
                variant = (i == 1) and "primary" or "secondary",
                disabled = disabled,
                onClick = function()
                    local moneyBefore = playerData_.money
                    if ch.effect then
                        local ok, err = pcall(ch.effect)
                        if not ok then log:Write(LOG_ERROR, "[EventChoice] effect error: " .. tostring(err)) end
                    end
                    ApplyIronFortress(moneyBefore)
                    local resultOk, resultText = pcall(function()
                        return type(ch.result) == "function" and ch.result() or (ch.result or "")
                    end)
                    if not resultOk then
                        log:Write(LOG_ERROR, "[EventChoice] result error: " .. tostring(resultText))
                        resultText = "事件已处理"
                    end
                    local moneyChange = playerData_.money - moneyBefore
                    local effectStr = nil
                    if moneyChange > 0 then effectStr = "+$" .. moneyChange
                    elseif moneyChange < 0 then effectStr = "-$" .. (-moneyChange) end
                    local safeIcon = evt.icon or ""
                    local safeTitle = evt.title or "事件"
                    RecordNPCEncounter(safeTitle, ch.text)
                    eventResult_ = {
                        success = not string.find(resultText, "损失") and not string.find(resultText, "失去") and moneyChange >= 0,
                        icon = safeIcon,
                        title = safeTitle,
                        narrative = resultText,
                        effects = effectStr,
                        logText = safeIcon .. " " .. safeTitle .. " → " .. resultText,
                    }
                    BuildUI()
                end,
            })
        end
    end

    -- 如果没有choices也没有candidate（纯展示型事件），加一个"知道了"按钮
    if not evt.choices and not evt.candidate then
        table.insert(choiceBtns, UI.Button {
            text = "知道了", width = "100%", height = 38, fontSize = 13, variant = "primary",
            onClick = function()
                local moneyBefore = playerData_.money
                if evt.effect then
                    local ok, err = pcall(evt.effect)
                    if not ok then log:Write(LOG_ERROR, "[EventAuto] effect error: " .. tostring(err)) end
                end
                local moneyChange = playerData_.money - moneyBefore
                local effectStr = nil
                if moneyChange > 0 then effectStr = "+$" .. moneyChange
                elseif moneyChange < 0 then effectStr = "-$" .. (-moneyChange) end
                local safeIcon = evt.icon or ""
                local safeTitle = evt.title or "事件"
                local descOk, descText = pcall(function()
                    return type(evt.desc) == "function" and evt.desc() or (evt.desc or "")
                end)
                if not descOk then
                    log:Write(LOG_ERROR, "[EventAuto] desc error: " .. tostring(descText))
                    descText = "事件已处理"
                end
                eventResult_ = {
                    success = moneyChange >= 0,
                    icon = safeIcon,
                    title = safeTitle,
                    narrative = descText,
                    effects = effectStr,
                    logText = safeIcon .. " " .. safeTitle,
                }
                BuildUI()
            end,
        })
    end

    if evt.candidate then
        local c = evt.candidate
        -- 计算说服成功率
        local baseChance = 60
        local repBonus = math.min(25, math.floor(playerData_.reputation / 8))
        local talentPenalty = math.max(0, math.floor((c.talent - 70) / 5) * 3) -- 高天赋更难招
        local chance = math.min(95, math.max(30, baseChance + repBonus - talentPenalty))
        local extraFee = math.floor(c.fee * 0.8) -- 加价费用
        local extraChance = math.min(98, chance + 25) -- 加价后成功率

        -- Victor 竞争（第2章后、天赋80+的角色有概率被 Victor 抢）
        local victorCompeting = currentChapter_ >= 2 and c.talent >= 80 and math.random(1, 100) <= 40
        if victorCompeting then
            chance = math.max(20, chance - 15) -- Victor 竞争降低成功率
            extraChance = math.min(95, extraChance - 5)
        end

        table.insert(choiceBtns, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = C.cardAlt, borderRadius = 10,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, children = {
                    c.avatar and UI.Panel {
                        width = 40, height = 40, borderRadius = 20,
                        backgroundImage = c.avatar, backgroundFit = "cover",
                        borderWidth = 1, borderColor = C.accent,
                    } or UI.Label { text = c.emoji, fontSize = 24 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Label { text = c.name .. " · " .. c.trait, fontSize = 13, fontColor = C.text },
                        UI.Label { text = c.desc, fontSize = 14, fontColor = C.textDim, whiteSpace = "normal" },
                        UI.Panel { flexDirection = "row", gap = 8, children = {
                            UI.Label { text = "天赋:" .. c.talent, fontSize = 14, fontColor = C.blue },
                            UI.Label { text = "技术:" .. c.skill, fontSize = 14, fontColor = C.green },
                        }},
                    }},
                }},
                victorCompeting and UI.Panel {
                    width = "100%", padding = 6, marginTop = 4,
                    backgroundColor = { C.red[1], C.red[2], C.red[3], 20 }, borderRadius = 6,
                    children = {
                        UI.Label { text = "Victor 也在争抢此人！成功率下降", fontSize = 14, fontColor = C.red },
                    },
                } or UI.Panel { height = 0 },
            },
        })
        -- 满员时：显示替换选择面板
        local isFull = #teamMembers_ >= 5
        if isFull then
            local replaceChildren = {
                UI.Label { text = "选择要替换的队员", fontSize = 13, fontColor = C.gold },
            }
            for ti, tm in ipairs(teamMembers_) do
                local selected = (recruitReplaceIdx_ == ti)
                table.insert(replaceChildren, UI.Panel {
                    flexDirection = "row", width = "100%", alignItems = "center", gap = 6,
                    padding = 6, borderRadius = 8,
                    backgroundColor = selected and { C.accent[1], C.accent[2], C.accent[3], 25 } or C.cardAlt,
                    borderWidth = selected and 2 or 0,
                    borderColor = C.gold,
                    pointerEvents = "auto",
                    onClick = function()
                        recruitReplaceIdx_ = selected and nil or ti
                        PlaySFX("click")
                        BuildUI()
                    end,
                    children = {
                        tm.avatar and UI.Panel {
                            width = 32, height = 32, borderRadius = 16,
                            backgroundImage = tm.avatar, backgroundFit = "cover",
                        } or UI.Label { text = tm.emoji, fontSize = 18 },
                        UI.Panel { flex = 1, gap = 1, children = {
                            UI.Label { text = tm.name .. "「" .. tm.trait .. "」", fontSize = 12, fontColor = selected and C.gold or C.text },
                            UI.Panel { flexDirection = "row", gap = 6, children = {
                                UI.Label { text = "天赋:" .. tm.talent, fontSize = 11, fontColor = C.blue },
                                UI.Label { text = "技术:" .. tm.skill, fontSize = 11, fontColor = C.green },
                            }},
                        }},
                        UI.Label { text = selected and "✓" or "", fontSize = 16, fontColor = C.gold, width = 20 },
                    },
                })
            end
            table.insert(choiceBtns, UI.ScrollView {
                width = "100%", maxHeight = 220, padding = 8,
                backgroundColor = C.cardAlt, borderRadius = 10,
                borderWidth = 1, borderColor = C.border,
                children = {
                    UI.Panel {
                        width = "100%", gap = 4,
                        children = replaceChildren,
                    },
                },
            })
        end
        -- 招募成功后的通用处理（新招或替换）
        local function DoRecruitSuccess(cost)
            if isFull and recruitReplaceIdx_ then
                local old = teamMembers_[recruitReplaceIdx_]
                table.insert(CANDIDATE_POOL, old)
                teamMembers_[recruitReplaceIdx_] = c
                AddLog("🔄 " .. old.name .. " 被替换，" .. c.name .. " 加入战队")
            else
                table.insert(teamMembers_, c)
            end
            playerData_.questRecruitCount = (playerData_.questRecruitCount or 0) + 1
            RemoveFromCandidatePool(c.name)
            recruitReplaceIdx_ = nil
        end
        -- 普通招募 / 替换
        local recruitLabel = isFull
            and (recruitReplaceIdx_ and ("替换（$" .. c.fee .. "）成功率 " .. chance .. "%") or "先选择要替换的队员 ↑")
            or ("招募（$" .. c.fee .. "）成功率 " .. chance .. "%")
        table.insert(choiceBtns, UI.Button {
            text = recruitLabel,
            width = "100%", height = 38, fontSize = 14, variant = "primary",
            disabled = playerData_.money < c.fee or (isFull and not recruitReplaceIdx_),
            onClick = function()
                playerData_.money = playerData_.money - c.fee
                if math.random(1, 100) <= chance then
                    local replacedName = isFull and recruitReplaceIdx_ and teamMembers_[recruitReplaceIdx_] and teamMembers_[recruitReplaceIdx_].name or nil
                    DoRecruitSuccess(c.fee)
                    PlaySFX("recruit"); TriggerCelebration()
                    local effectsStr = "-$" .. c.fee .. "  |  " .. c.name .. "（天赋" .. c.talent .. " 技术" .. c.skill .. "）"
                    if replacedName then effectsStr = effectsStr .. "  |  替换 " .. replacedName end
                    eventResult_ = {
                        success = true,
                        icon = "",
                        title = replacedName and "替换成功！" or "招募成功！",
                        candidate = c,
                        narrative = victorCompeting
                            and (c.name .. " 面对 Victor 的高薪诱惑，最终还是选择了你。握手的瞬间，你看到了" .. c.emoji .. "眼中燃烧的斗志——Dragon Force 的精神打动了这位天才选手！")
                            or (replacedName
                                and (c.name .. " 看到你腾出了位置，感受到了你的诚意。" .. c.emoji .. " 爽快地签了约：「我不会让你失望的！」")
                                or (c.name .. " 被你描绘的电竞梦想深深吸引。" .. c.emoji .. " 签下合同的那一刻，露出了灿烂的笑容：「一起冲击全非洲冠军吧！」")),
                        effects = effectsStr,
                        logText = replacedName
                            and ("" .. replacedName .. " 离队，" .. c.name .. " 加入战队！")
                            or ("" .. c.name .. " 被你的诚意打动，加入了战队！"),
                        type = "recruit",
                    }
                else
                    if victorCompeting then
                        eventResult_ = {
                            success = false,
                            icon = "",
                            title = "被 Victor 抢走了！",
                            candidate = c,
                            narrative = "Victor 的 Gold Net 战队开出了双倍薪水和顶级设备。" .. c.name .. " 犹豫了很久，最终还是坐上了 Victor 派来的豪车。你握紧拳头，看着尾灯消失在拉各斯的夜色中……",
                            effects = "-$" .. c.fee .. "（打了水漂）",
                            logText = "💔 " .. c.name .. " 被 Victor 的高薪挖走了……钱也白花了！",
                            type = "recruit",
                        }
                    else
                        eventResult_ = {
                            success = false,
                            icon = "😕",
                            title = "招募失败",
                            candidate = c,
                            narrative = c.name .. " 沉默了很久，最终还是摇了摇头：「对不起，我还没准备好加入一支新战队。」也许是时机不对，也许是缘分未到。希望下次还能再见。",
                            effects = "-$" .. c.fee .. "（招募费损失）",
                            logText = "😕 " .. c.name .. " 犹豫再三，还是拒绝了。$" .. c.fee .. " 打了水漂。",
                            type = "recruit",
                        }
                    end
                end
                BuildUI()
            end,
        })
        -- 加价说服 / 替换
        local totalExtra = c.fee + extraFee
        local extraLabel = isFull
            and (recruitReplaceIdx_ and ("加价替换（$" .. totalExtra .. "）成功率 " .. extraChance .. "%") or "先选择要替换的队员 ↑")
            or ("加价说服（$" .. totalExtra .. "）成功率 " .. extraChance .. "%")
        table.insert(choiceBtns, UI.Button {
            text = extraLabel,
            width = "100%", height = 38, fontSize = 14, variant = "secondary",
            disabled = playerData_.money < totalExtra or (isFull and not recruitReplaceIdx_),
            onClick = function()
                playerData_.money = playerData_.money - totalExtra
                if math.random(1, 100) <= extraChance then
                    local replacedName = isFull and recruitReplaceIdx_ and teamMembers_[recruitReplaceIdx_] and teamMembers_[recruitReplaceIdx_].name or nil
                    DoRecruitSuccess(totalExtra)
                    PlaySFX("recruit"); TriggerCelebration()
                    local extraEffects = "-$" .. totalExtra .. "  |  " .. c.name .. "（天赋" .. c.talent .. " 技术" .. c.skill .. "）"
                    if replacedName then extraEffects = extraEffects .. "  |  替换 " .. replacedName end
                    if victorCompeting then
                        playerData_.karma = playerData_.karma + 1
                        extraEffects = extraEffects .. "  |  ✨ 善缘+1"
                        eventResult_ = {
                            success = true,
                            icon = "",
                            title = replacedName and "击败 Victor，替换成功！" or "击败 Victor！",
                            candidate = c,
                            narrative = "你的加价让 Victor 措手不及！" .. c.name .. " 看到你的决心后，毫不犹豫地在合同上签下了名字。" .. c.emoji .. "「能被这样重视，我选 Dragon Force！」Victor 铁青着脸离开了。",
                            effects = extraEffects,
                            logText = replacedName
                                and ("用加价击败 Victor！" .. replacedName .. " 离队，" .. c.name .. " 加入！")
                                or ("用加价击败了 Victor！" .. c.name .. " 选择加入 Dragon Force！"),
                            type = "recruit",
                        }
                    else
                        eventResult_ = {
                            success = true,
                            icon = "",
                            title = replacedName and "替换成功！" or "招募成功！",
                            candidate = c,
                            narrative = c.name .. " 对你的大手笔和诚意非常感动。" .. c.emoji .. " 几乎没有犹豫就签了约：「跟着这样大方的老板，一定能闯出名堂！」",
                            effects = extraEffects,
                            logText = replacedName
                                and ("" .. replacedName .. " 离队，" .. c.name .. " 被你的大手笔打动，签约！")
                                or ("" .. c.name .. " 对你的诚意非常感动，立刻签约！"),
                            type = "recruit",
                        }
                    end
                else
                    eventResult_ = {
                        success = false,
                        icon = "",
                        title = "招募失败",
                        candidate = c,
                        narrative = "即便开出了高价，" .. c.name .. " 依然犹豫不决。最终" .. c.emoji .. "叹了口气：「抱歉，钱不是唯一的考量……」你望着空荡荡的桌子，心在滴血。",
                        effects = "-$" .. totalExtra .. "（全部损失）",
                        logText = "💸 花了大价钱，" .. c.name .. " 还是没来……$" .. totalExtra .. " 全没了。",
                        type = "recruit",
                    }
                end
                BuildUI()
            end,
        })
        table.insert(choiceBtns, UI.Button {
            text = "👋 下次再说", width = "100%", height = 38, fontSize = 14,
            onClick = function()
                recruitReplaceIdx_ = nil
                if victorCompeting then
                    RemoveFromCandidatePool(c.name)
                    eventResult_ = {
                        success = false,
                        icon = "⚠️",
                        title = "错失人才",
                        candidate = c,
                        narrative = "你转身离开后不到一个小时，Victor 就派人找到了" .. c.name .. "。" .. c.emoji .. "当晚就签约 Gold Net。机会稍纵即逝，犹豫的代价是惨痛的……",
                        effects = "😶 " .. c.name .. " 被 Victor 签走",
                        logText = "⚠️ " .. c.name .. " 被 Victor 直接签走了！",
                        type = "recruit",
                    }
                else
                    eventResult_ = {
                        success = false,
                        icon = "👋",
                        title = "暂时告别",
                        candidate = c,
                        narrative = c.name .. " 点了点头：「好吧，也许以后还有机会。」" .. c.emoji .. "背起包走出了网吧，消失在熙熙攘攘的街头。也许某天，你们还会再见。",
                        logText = (evt.icon or "👋") .. " " .. c.name .. " 离开了，也许还会再见……",
                        type = "recruit",
                    }
                end
                BuildUI()
            end,
        })
    end

    -- 限制描述文本长度，确保一屏展示（UTF-8安全截断，约80字符）
    local descText = (function()
        if type(evt.desc) == "function" then
            local ok, txt = pcall(evt.desc)
            return ok and txt or "……"
        end
        return evt.desc or ""
    end)()
    local descCharLen = utf8.len(descText) or 0
    if descCharLen > 80 then
        local bytePos = utf8.offset(descText, 78) or #descText
        descText = string.sub(descText, 1, bytePos - 1) .. "……"
    end

    -- 根据事件类型选择背景图
    local eventBg = SCENE_IMAGES.event
    if evt and evt.type == "recruit" then
        eventBg = SCENE_IMAGES.recruit
    elseif evt and evt.type == "market" then
        eventBg = SCENE_IMAGES.night_market
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = eventBg,
        backgroundFit = "cover",
        justifyContent = "center", alignItems = "center",
        children = {
            UI.ScrollView {
                width = "88%", maxWidth = 400, maxHeight = "90%",
                padding = { 18, 16 },
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = C.accentDim,
                boxShadow = { { x = 0, y = 6, blur = 25, color = { 80, 60, 40, 100 } } },
                children = {
                    UI.Panel {
                        width = "100%", gap = 8, alignItems = "center",
                        children = (function()
                            local c = {
                                UI.Label { text = evt.icon or "", fontSize = 36 },
                                UI.Label { text = evt.title or "事件", fontSize = 17, fontColor = C.gold },
                                UI.Label { text = descText, fontSize = 13, fontColor = C.text, textAlign = "center", whiteSpace = "normal", lineHeight = 1.4, width = "100%" },
                            }
                            for _, btn in ipairs(choiceBtns) do table.insert(c, btn) end
                            return c
                        end)(),
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 14.5 事件/招聘结果展示弹窗
-- ============================================================================
function BuildEventResultUI()
    local r = eventResult_
    local c = r.candidate -- 招聘时有候选人信息

    local borderColor = r.success and C.green or { 200, 80, 60, 200 }
    local titleColor = r.success and C.green or C.gold

    -- 确认逻辑（按钮和点击任意位置共用）
    local isStoryEvent = (currentEvent_ == nil)
    local function doConfirm()
        PlaySFX("click")
        AddLog(r.logText)
        -- 留存系统：NPC 支线剧情推进回调
        if currentEvent_ and currentEvent_.id and NPCStorylines then
            pcall(NPCStorylines.OnEventCompleted, currentEvent_.id)
        end
        eventResult_ = nil
        currentEvent_ = nil
        if isStoryEvent then
            StartTransition("", "", function()
                PlayBGM("manage")
                currentPhase_ = PHASE_MANAGE; BuildUI()
            end)
        else
            currentPhase_ = PHASE_MANAGE
            BuildUI()
        end
    end

    -- 限制叙事文本长度，确保一屏展示（UTF-8安全截断，约80字符）
    local narrativeText = r.narrative or ""
    local charLen = utf8.len(narrativeText) or 0
    if charLen > 80 then
        local bytePos = utf8.offset(narrativeText, 78) or #narrativeText
        narrativeText = string.sub(narrativeText, 1, bytePos - 1) .. "……"
    end

    local children = {
        -- 结果图标 + 标题（紧凑排列）
        UI.Label { text = r.icon or "📌", fontSize = 40 },
        UI.Label { text = r.title, fontSize = 18, fontColor = titleColor },
        UI.Panel { height = 4 },
    }

    -- 候选人信息卡（招聘时展示，精简版）
    if c then
        table.insert(children, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = r.success and { 40, 55, 40, 230 } or { 55, 35, 35, 230 },
            borderRadius = 10, borderWidth = 1,
            borderColor = r.success and { 80, 160, 80, 160 } or { 200, 80, 60, 160 },
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, children = {
                    c.avatar and UI.Panel {
                        width = 40, height = 40, borderRadius = 20,
                        backgroundImage = c.avatar, backgroundFit = "cover",
                        borderWidth = 1, borderColor = C.accent,
                    } or UI.Label { text = c.emoji or "👤", fontSize = 30 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = c.name, fontSize = 15, fontColor = C.text },
                            UI.Label { text = "「" .. c.trait .. "」", fontSize = 11, fontColor = C.accent },
                        }},
                        UI.Panel { flexDirection = "row", gap = 10, children = {
                            UI.Label { text = "天赋:" .. c.talent, fontSize = 12, fontColor = C.blue },
                            UI.Label { text = "技术:" .. c.skill, fontSize = 12, fontColor = C.green },
                        }},
                    }},
                }},
            },
        })
        table.insert(children, UI.Panel { height = 2 })
    end

    -- 叙事段落（精简）
    table.insert(children, UI.Label {
        text = narrativeText, fontSize = 13, fontColor = C.text,
        textAlign = "center", whiteSpace = "normal", lineHeight = 1.5, width = "100%",
    })

    -- 效果摘要
    if r.effects then
        table.insert(children, UI.Panel {
            width = "100%", padding = 8, marginTop = 4,
            backgroundColor = C.cardAlt, borderRadius = 8,
            children = {
                UI.Label { text = r.effects, fontSize = 13, fontColor = C.gold, textAlign = "center", whiteSpace = "normal" },
            },
        })
    end

    -- 确认按钮
    table.insert(children, UI.Panel { height = 8 })
    table.insert(children, UI.Button {
        text = "确认", width = 180, height = 42, fontSize = 15, variant = "primary",
        onClick = function() doConfirm() end,
    })
    table.insert(children, UI.Label {
        text = "（点击任意位置继续）", fontSize = 11, fontColor = C.textLight,
    })

    -- 根据事件结果类型选择背景图
    local resultBg = SCENE_IMAGES.event
    if r and r.type == "recruit" then
        resultBg = SCENE_IMAGES.recruit
    elseif r and r.type == "market" then
        resultBg = SCENE_IMAGES.night_market
    elseif r and r.type == "branch" and r.locationId then
        resultBg = SCENE_IMAGES["branch_" .. r.locationId] or SCENE_IMAGES.event
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = resultBg,
        backgroundFit = "cover",
        justifyContent = "center", alignItems = "center",
        onClick = function() doConfirm() end,
        children = {
            UI.Panel {
                width = "88%", maxWidth = 400, padding = { 20, 16 }, gap = 4,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = borderColor,
                alignItems = "center",
                boxShadow = { { x = 0, y = 6, blur = 25, color = { 80, 60, 40, 100 } } },
                children = children,
            },
        },
    }
end

-- ============================================================================
-- 15a. 踢馆挑战 UI（赌注选择 / 回合介绍 / 回合结果 / 总决算）
-- ============================================================================
function BuildChallengeRoundUI()
    local opp = challengeOpponent_ or {}
    local modeLabels = MINIGAME_LABELS or {}
    local modeEmojis = MINIGAME_EMOJIS or {}
    local phase = challengePhase_

    -- ---------- playing: 小游戏界面 ----------
    if phase == "playing" then
        return BuildMiniGameUI()
    end

    -- ---------- select_wager ----------
    if phase == "select_wager" then
        local pScore = CalcCafeScore()
        local nScore = challengeNPCScore_

        -- 赌注选项生成
        local function WagerBtn(label, wType, wAmt)
            return UI.Button {
                text = label, fontSize = 13, height = 34, flex = 1,
                variant = "secondary",
                onClick = function() ConfirmChallengeWager(wType, wAmt) end,
            }
        end

        -- Bo3 赛程预览
        local schedChildren = {}
        for i = 1, 3 do
            local m = challengeModes_[i]
            table.insert(schedChildren, UI.Label {
                text = (modeEmojis[m] or "?") .. " R" .. i .. " " .. (modeLabels[m] or m),
                fontSize = 12, fontColor = C.text,
            })
        end

        return UI.Panel {
            width = "100%", height = "100%", padding = 12, gap = 8,
            backgroundColor = { 248, 252, 248, 252 },
            children = {
                -- 标题
                UI.Label { text = "⚔️ 踢馆挑战", fontSize = 20, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" },

                -- 对手信息卡
                UI.Panel {
                    width = "100%", padding = 10, backgroundColor = C.cardAlt, borderRadius = 10,
                    borderWidth = 1, borderColor = { 220, 140, 100, 100 }, gap = 4,
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, width = "100%", children = {
                            UI.Label { text = opp.emoji or "", fontSize = 24 },
                            UI.Panel { flex = 1, gap = 2, children = {
                                UI.Label { text = opp.name or "???", fontSize = 15, fontColor = { 200, 130, 50, 255 }, fontWeight = "bold" },
                                UI.Label { text = (opp.loc or "") .. " · " .. (opp.style or ""), fontSize = 12, fontColor = C.textDim },
                            }},
                            UI.Label { text = "" .. nScore, fontSize = 14, fontColor = C.gold },
                        }},
                        UI.Panel { flexDirection = "row", width = "100%", gap = 4, children = {
                            UI.Label { text = "你的实力 " .. pScore, fontSize = 12, fontColor = C.accent, flex = 1 },
                            UI.Label { text = "难度 " .. math.floor(challengeDifficulty_ * 100) .. "%", fontSize = 12, fontColor = { 200, 120, 50, 255 } },
                            UI.Label { text = "倍率 ×" .. challengeMultiplier_, fontSize = 12, fontColor = C.gold },
                        }},
                    },
                },

                -- Bo3 赛程
                UI.Panel {
                    width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = 8, gap = 3,
                    children = {
                        UI.Label { text = "Bo3 赛程（先胜2局）", fontSize = 13, fontColor = C.accent },
                        UI.Panel { flexDirection = "row", gap = 8, width = "100%", children = schedChildren },
                    },
                },

                -- 赌注选择
                UI.Label { text = "选择赌注", fontSize = 15, fontColor = C.text, fontWeight = "bold" },
                UI.Label { text = "赢了获得赌注×" .. challengeMultiplier_ .. "倍奖励，输了失去赌注", fontSize = 11, fontColor = C.textDim },

                -- 金钱赌注
                UI.Panel { width = "100%", gap = 3, children = {
                    UI.Label { text = "金钱 (当前 $" .. playerData_.money .. ")", fontSize = 12, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 4, width = "100%", children = {
                        WagerBtn("$100", "money", 100),
                        WagerBtn("$200", "money", 200),
                        WagerBtn("$500", "money", 500),
                    }},
                }},

                -- 电脑赌注
                UI.Panel { width = "100%", gap = 3, children = {
                    UI.Label { text = "电脑 (当前 " .. playerData_.computers .. " 台)", fontSize = 12, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 4, width = "100%", children = {
                        WagerBtn("1台", "computer", 1),
                        WagerBtn("2台", "computer", 2),
                    }},
                }},

                -- 声望赌注
                UI.Panel { width = "100%", gap = 3, children = {
                    UI.Label { text = "声望 (当前 " .. playerData_.reputation .. ")", fontSize = 12, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 4, width = "100%", children = {
                        WagerBtn("10声望", "reputation", 10),
                        WagerBtn("20声望", "reputation", 20),
                        WagerBtn("50声望", "reputation", 50),
                    }},
                }},

                UI.Panel { flex = 1 },
                -- 返回按钮
                UI.Button {
                    text = "← 放弃踢馆", height = 36, fontSize = 13, width = "100%",
                    onClick = function()
                        -- 退还行动点
                        playerData_.actionPoints = playerData_.actionPoints + 1
                        challengeActive_ = false; challengeDay_ = 0
                        challengeOpponent_ = nil; challengePhase_ = "select_wager"
                        challengeRoundResult_ = nil; miniGame_ = nil
                        trainMember_ = nil; trainActive_ = false
                        currentPhase_ = PHASE_MANAGE; BuildUI()
                    end,
                },
            },
        }

    -- ---------- round_intro ----------
    elseif phase == "round_intro" then
        local mode = challengeModes_[challengeRound_]
        -- Bo3 比分指示
        local scoreBoxes = {}
        for i = 1, 3 do
            local st = "⬜"
            if i < challengeRound_ then
                -- 过去的回合
                st = "——" -- 占位，用下面的颜色方块
            end
            local bgC = { 240, 245, 240, 220 }
            local label = "R" .. i
            if i < challengeRound_ then
                -- 判定过去轮次结果（简单：根据当前wins回推）
                label = "✓"
                bgC = { 220, 240, 220, 220 }
            elseif i == challengeRound_ then
                label = ">"
                bgC = { 248, 252, 248, 220 }
            end
            table.insert(scoreBoxes, UI.Panel {
                width = 50, height = 40, backgroundColor = bgC, borderRadius = 6,
                justifyContent = "center", alignItems = "center",
                borderWidth = i == challengeRound_ and 2 or 0,
                borderColor = C.gold,
                children = {
                    UI.Label { text = label, fontSize = 14, fontColor = C.text, textAlign = "center" },
                    UI.Label { text = modeLabels[challengeModes_[i]] or "", fontSize = 9, fontColor = C.textDim, textAlign = "center" },
                },
            })
        end

        return UI.Panel {
            width = "100%", height = "100%", padding = 16, gap = 12,
            backgroundColor = { 248, 252, 248, 252 },
            justifyContent = "center", alignItems = "center",
            children = {
                UI.Label { text = "⚔️ 第 " .. challengeRound_ .. " 轮", fontSize = 22, fontColor = C.gold, fontWeight = "bold" },
                UI.Label { text = "vs " .. (opp.emoji or "") .. " " .. (opp.name or ""), fontSize = 15, fontColor = { 200, 130, 50, 255 } },

                -- 比分栏
                UI.Panel {
                    flexDirection = "row", gap = 8, paddingVertical = 8, children = {
                        UI.Label { text = "你 " .. challengePlayerWins_, fontSize = 16, fontColor = C.green, fontWeight = "bold" },
                        UI.Label { text = ":", fontSize = 16, fontColor = C.text },
                        UI.Label { text = challengeNPCWins_ .. " 对手", fontSize = 16, fontColor = C.red, fontWeight = "bold" },
                    },
                },

                -- 赛程进度
                UI.Panel { flexDirection = "row", gap = 6, children = scoreBoxes },

                -- 当前模式
                UI.Panel {
                    width = "80%", padding = 16, backgroundColor = C.cardAlt, borderRadius = 12,
                    borderWidth = 1, borderColor = C.accent, alignItems = "center", gap = 6,
                    children = {
                        UI.Label { text = (modeEmojis[mode] or "?"), fontSize = 36 },
                        UI.Label { text = modeLabels[mode] or mode, fontSize = 18, fontColor = C.accent, fontWeight = "bold" },
                        UI.Label { text = "准备好了吗？", fontSize = 13, fontColor = C.textDim },
                    },
                },

                UI.Button {
                    text = "开始比拼！", width = 200, height = 44, fontSize = 16,
                    variant = "primary",
                    onClick = function() StartChallengeRound() end,
                },
            },
        }

    -- ---------- round_result ----------
    elseif phase == "round_result" then
        local r = challengeRoundResult_ or {}
        local mode = r.mode or ""
        local pw = r.playerWin
        local bonus = r.bonus or 0
        local bonusPct = r.bonusPercent or 0
        local bonusColor = bonus >= 0 and C.green or C.red
        local bonusSign = bonus >= 0 and "+" or ""

        return UI.Panel {
            width = "100%", height = "100%", padding = 16, gap = 10,
            backgroundColor = { 248, 252, 248, 252 },
            justifyContent = "center", alignItems = "center",
            children = {
                UI.Label { text = pw and "本轮胜利！" or "本轮惜败", fontSize = 22, fontColor = pw and C.green or C.red, fontWeight = "bold" },
                UI.Label { text = (modeEmojis[mode] or "") .. " " .. (modeLabels[mode] or mode), fontSize = 15, fontColor = C.textDim },

                -- 分数对比
                UI.Panel {
                    width = "85%", padding = 12, backgroundColor = C.cardAlt, borderRadius = 10, gap = 6,
                    children = {
                        UI.Panel { flexDirection = "row", width = "100%", justifyContent = "space-between", children = {
                            UI.Label { text = "操作得分", fontSize = 13, fontColor = C.textDim },
                            UI.Label { text = tostring(r.rawPlayerScore or r.playerScore or 0), fontSize = 15, fontColor = C.text },
                        }},
                        -- 综合分加成行
                        UI.Panel { flexDirection = "row", width = "100%", justifyContent = "space-between",
                            backgroundColor = { 240, 245, 240, 150 }, borderRadius = 6, paddingHorizontal = 6, paddingVertical = 3,
                            children = {
                            UI.Label { text = "综合分加成 (" .. bonusSign .. bonusPct .. "%)", fontSize = 12, fontColor = bonusColor },
                            UI.Label { text = bonusSign .. bonus, fontSize = 13, fontColor = bonusColor, fontWeight = "bold" },
                        }},
                        UI.Label { text = "你 " .. (r.cafeScore or 0) .. " vs 对手 " .. (r.npcCafeScore or 0), fontSize = 11, fontColor = C.textDim, textAlign = "center", width = "100%" },
                        -- 分隔线
                        UI.Panel { width = "100%", height = 1, backgroundColor = { 195, 210, 195, 60 } },
                        UI.Panel { flexDirection = "row", width = "100%", justifyContent = "space-between", children = {
                            UI.Label { text = "你的最终分", fontSize = 14, fontColor = C.text, fontWeight = "bold" },
                            UI.Label { text = tostring(r.playerScore or 0), fontSize = 16, fontColor = C.accent, fontWeight = "bold" },
                        }},
                        UI.Panel { flexDirection = "row", width = "100%", justifyContent = "space-between", children = {
                            UI.Label { text = "👾 对手分数", fontSize = 14, fontColor = C.text },
                            UI.Label { text = tostring(r.npcScore or 0), fontSize = 16, fontColor = { 200, 120, 60, 255 }, fontWeight = "bold" },
                        }},
                    },
                },

                -- 总比分
                UI.Panel {
                    flexDirection = "row", gap = 8, paddingVertical = 6, children = {
                        UI.Label { text = "总比分  你 " .. challengePlayerWins_, fontSize = 16, fontColor = C.green, fontWeight = "bold" },
                        UI.Label { text = ":", fontSize = 16, fontColor = C.text },
                        UI.Label { text = challengeNPCWins_ .. " 对手", fontSize = 16, fontColor = C.red, fontWeight = "bold" },
                    },
                },

                UI.Button {
                    text = "下一轮 →", width = 200, height = 44, fontSize = 16,
                    variant = "primary",
                    onClick = function()
                        challengeRound_ = challengeRound_ + 1
                        challengePhase_ = "round_intro"
                        BuildUI()
                    end,
                },
            },
        }

    -- ---------- final ----------
    elseif phase == "final" then
        local won = challengePlayerWins_ >= 2
        local wType = challengeWagerType_
        local wAmt = challengeWagerAmount_
        local mult = challengeMultiplier_

        local wagerLabel = ""
        local wagerIcon = ""
        if wType == "money" then wagerLabel = "$" .. wAmt; wagerIcon = "$"
        elseif wType == "computer" then wagerLabel = wAmt .. "台电脑"; wagerIcon = ""
        elseif wType == "reputation" then wagerLabel = wAmt .. "声望"; wagerIcon = "★"
        end

        -- 收益明细列表
        local earningsItems = {}
        if won then
            local reward = math.floor(wAmt * mult)
            local rewardLabel = ""
            if wType == "money" then rewardLabel = "+$" .. reward
            elseif wType == "computer" then rewardLabel = "+" .. reward .. "台"
            elseif wType == "reputation" then rewardLabel = "+" .. reward
            end
            table.insert(earningsItems, { icon = wagerIcon, label = "赌注收益 (×" .. mult .. "倍)", value = rewardLabel, color = C.green })
            table.insert(earningsItems, { icon = "★", label = "威名远扬", value = "+10 声望", color = C.green })
            table.insert(earningsItems, { icon = "😊", label = "全队士气提升", value = "+5 心情", color = C.green })
        else
            local lossLabel = ""
            if wType == "money" then lossLabel = "-$" .. wAmt
            elseif wType == "computer" then lossLabel = "-" .. wAmt .. "台"
            elseif wType == "reputation" then lossLabel = "-" .. wAmt
            end
            table.insert(earningsItems, { icon = wagerIcon, label = "赌注损失", value = lossLabel, color = C.red })
            table.insert(earningsItems, { icon = "★", label = "名声受损", value = "-5 声望", color = C.red })
            table.insert(earningsItems, { icon = "😟", label = "全队士气下降", value = "-3 心情", color = C.red })
        end

        -- 构建收益明细行
        local earningsChildren = {}
        for _, item in ipairs(earningsItems) do
            table.insert(earningsChildren, UI.Panel {
                flexDirection = "row", width = "100%", alignItems = "center", gap = 6,
                paddingVertical = 4,
                children = {
                    UI.Label { text = item.icon, fontSize = 16, width = 24 },
                    UI.Label { text = item.label, fontSize = 13, fontColor = C.text, flex = 1 },
                    UI.Label { text = item.value, fontSize = 14, fontColor = item.color, fontWeight = "bold" },
                },
            })
        end

        -- Bo3 各轮次回顾
        local roundReview = {}
        for i = 1, math.min(challengeRound_, 3) do
            local m = challengeModes_[i]
            local mLabel = (MINIGAME_EMOJIS or {})[m] or "?"
            -- 简化判定：前 challengePlayerWins_ 轮算赢
            local roundWon = (i <= (challengePlayerWins_ + challengeNPCWins_))
            table.insert(roundReview, UI.Label {
                text = mLabel .. " R" .. i .. " " .. ((MINIGAME_LABELS or {})[m] or m),
                fontSize = 11, fontColor = C.textDim,
            })
        end

        return UI.Panel {
            width = "100%", height = "100%",
            backgroundColor = C.card,
            justifyContent = "center", alignItems = "center",
            children = {
                -- 弹窗卡片
                UI.Panel {
                    width = "90%", maxWidth = 400, padding = 20, gap = 10,
                    backgroundColor = won and { 240, 250, 235, 248 } or { 255, 245, 245, 248 },
                    borderRadius = 20, borderWidth = 2,
                    borderColor = won and { 220, 190, 80, 180 } or { 210, 100, 80, 180 },
                    alignItems = "center",
                    boxShadow = { { x = 0, y = 8, blur = 30, color = { 80, 60, 40, 120 } } },
                    children = {
                        -- 标题
                        UI.Label { text = won and "踢馆成功！" or "踢馆失败", fontSize = 24, fontColor = won and C.gold or C.red, fontWeight = "bold" },
                        UI.Label { text = "vs " .. (opp.emoji or "") .. " " .. (opp.name or ""), fontSize = 14, fontColor = C.textDim },

                        -- 最终比分
                        UI.Panel {
                            width = "100%", padding = 10, backgroundColor = { 235, 240, 235, 100 }, borderRadius = 10,
                            flexDirection = "row", justifyContent = "center", alignItems = "center", gap = 12,
                            children = {
                                UI.Label { text = "你 " .. challengePlayerWins_, fontSize = 22, fontColor = C.green, fontWeight = "bold" },
                                UI.Label { text = ":", fontSize = 22, fontColor = C.text },
                                UI.Label { text = challengeNPCWins_ .. " 对手", fontSize = 22, fontColor = C.red, fontWeight = "bold" },
                            },
                        },

                        -- 赛程回顾
                        (#roundReview > 0) and UI.Panel {
                            flexDirection = "row", gap = 8, width = "100%", justifyContent = "center",
                            children = roundReview,
                        } or UI.Panel { height = 0 },

                        -- 分隔线
                        UI.Panel { width = "90%", height = 1, backgroundColor = { 195, 210, 195, 60 } },

                        -- 收益明细标题
                        UI.Label { text = won and "收益明细" or "损失明细", fontSize = 15, fontColor = C.gold, fontWeight = "bold" },

                        -- 收益明细列表
                        UI.Panel {
                            width = "100%", padding = 10, backgroundColor = { 240, 245, 240, 80 }, borderRadius = 10,
                            gap = 2,
                            children = earningsChildren,
                        },

                        -- 赌注信息
                        UI.Label { text = "赌注：" .. wagerLabel .. "  |  倍率：×" .. mult, fontSize = 12, fontColor = C.textDim },

                        -- 确认按钮
                        UI.Button {
                            text = "确认收益", width = 220, height = 46, fontSize = 16,
                            variant = "primary",
                            onClick = function() FinishChallenge() end,
                        },
                    },
                },
            },
        }
    end

    -- fallback
    return UI.Panel { width = "100%", height = "100%", children = {
        UI.Label { text = "⚔️ 踢馆进行中...", fontSize = 16, fontColor = C.text },
    }}
end

-- ============================================================================
-- 15b. 打地鼠训练界面
-- ============================================================================
function BuildTrainUI()
    -- 踢馆模式下，所有阶段由踢馆 UI 接管（含 playing 的小游戏界面）
    if challengeActive_ then
        return BuildChallengeRoundUI()
    end

    if not trainMember_ then
        -- 不能递归调用 BuildUI，否则外层会用空白面板覆盖导致黑屏
        currentPhase_ = PHASE_MANAGE
        return BuildManageUI()
    end
    local m = trainMember_
    local modeLabels = { quiz = "战术问答", aim = "瞄准特训", react = "反应训练", memory = "记忆序列" }
    local modeLabel = modeLabels[trainMode_] or "选择训练"

    local headerChildren = {
        UI.Label { text = m.emoji .. " " .. m.name .. " " .. modeLabel, fontSize = 18, fontColor = C.gold },
        UI.Label { text = "「" .. m.trait .. "」 技术:" .. m.skill, fontSize = 14, fontColor = C.textDim },
    }

    local bodyChildren = {}

    -- ======== 模式选择界面 ========
    if trainMode_ == "select" then
        bodyChildren = {
            UI.Panel { height = 12 },
            UI.Label { text = "选择训练科目", fontSize = 18, fontColor = C.text },
            UI.Panel { height = 4 },
            UI.Label { text = "不同训练提升不同能力", fontSize = 13, fontColor = C.textDim },
            UI.Panel { height = 16 },
            -- 瞄准训练卡片
            UI.Panel {
                width = "90%", padding = 14, gap = 6, borderRadius = 14,
                backgroundColor = { C.green[1], C.green[2], C.green[3], 25 }, borderWidth = 2, borderColor = C.green,
                pointerEvents = "auto",
                onClick = function()
                    PlaySFX("click")
                    trainMode_ = "aim"; trainPhase_ = "ready"; BuildUI()
                end,
                children = {
                    UI.Panel { flexDirection = "row", gap = 8, alignItems = "center", children = {
                        UI.Label { text = "靶", fontSize = 28 },
                        UI.Panel { gap = 2, children = {
                            UI.Label { text = "瞄准特训", fontSize = 16, fontColor = C.green },
                            UI.Label { text = "提升手感 · 反应速度", fontSize = 14, fontColor = C.textDim },
                        }},
                    }},
                    UI.Label { text = "在" .. TRAIN_DURATION .. "秒内快速点击随机目标，连击得高分", fontSize = 13,
                        fontColor = { 80, 140, 70, 255 }, whiteSpace = "normal" },
                },
            },
            UI.Panel { height = 8 },
            -- 战术问答卡片
            UI.Panel {
                width = "90%", padding = 14, gap = 6, borderRadius = 14,
                backgroundColor = { C.blue[1], C.blue[2], C.blue[3], 25 }, borderWidth = 2, borderColor = C.blue,
                pointerEvents = "auto",
                onClick = function()
                    PlaySFX("click")
                    -- 根据队员技能动态决定题目数量：技能越高题越多
                    local sk = trainMember_ and trainMember_.skill or 0
                    quizTotal_ = sk >= 70 and 8 or sk >= 40 and 6 or 5
                    trainMode_ = "quiz"; trainPhase_ = "ready"; BuildUI()
                end,
                children = {
                    UI.Panel { flexDirection = "row", gap = 8, alignItems = "center", children = {
                        UI.Label { text = "🧠", fontSize = 28 },
                        UI.Panel { gap = 2, children = {
                            UI.Label { text = "战术问答", fontSize = 16, fontColor = C.blue },
                            UI.Label { text = "提升战术理解 · 团队意识", fontSize = 14, fontColor = C.textDim },
                        }},
                    }},
                    UI.Label { text = "回答" .. quizTotal_ .. "道FPS战术问题，答对越多收获越大", fontSize = 13,
                        fontColor = { 70, 100, 160, 255 }, whiteSpace = "normal" },
                },
            },
            UI.Panel { height = 8 },
            -- 反应训练卡片
            UI.Panel {
                width = "90%", padding = 14, gap = 6, borderRadius = 14,
                backgroundColor = { C.red[1], C.red[2], C.red[3], 20 }, borderWidth = 2, borderColor = C.red,
                pointerEvents = "auto",
                onClick = function()
                    PlaySFX("click")
                    trainMode_ = "react"; trainPhase_ = "ready"; BuildUI()
                end,
                children = {
                    UI.Panel { flexDirection = "row", gap = 8, alignItems = "center", children = {
                        UI.Label { text = "!", fontSize = 28 },
                        UI.Panel { gap = 2, children = {
                            UI.Label { text = "反应训练", fontSize = 16, fontColor = C.red },
                            UI.Label { text = "提升反应速度 · 临场判断", fontSize = 14, fontColor = C.textDim },
                        }},
                    }},
                    UI.Label { text = "看到指令后快速点击对应方向，越快得分越高", fontSize = 13,
                        fontColor = { 180, 80, 60, 255 }, whiteSpace = "normal" },
                },
            },
            UI.Panel { height = 8 },
            -- 记忆训练卡片
            UI.Panel {
                width = "90%", padding = 14, gap = 6, borderRadius = 14,
                backgroundColor = C.cardAlt, borderWidth = 2, borderColor = { 180, 180, 100, 255 },
                pointerEvents = "auto",
                onClick = function()
                    PlaySFX("click")
                    trainMode_ = "memory"; trainPhase_ = "ready"; BuildUI()
                end,
                children = {
                    UI.Panel { flexDirection = "row", gap = 8, alignItems = "center", children = {
                        UI.Label { text = "🧩", fontSize = 28 },
                        UI.Panel { gap = 2, children = {
                            UI.Label { text = "记忆序列", fontSize = 16, fontColor = { 180, 180, 100, 255 } },
                            UI.Label { text = "提升记忆力 · 信息处理", fontSize = 14, fontColor = C.textDim },
                        }},
                    }},
                    UI.Label { text = "记住闪现的图标序列，按正确顺序还原", fontSize = 13,
                        fontColor = { 140, 140, 80, 255 }, whiteSpace = "normal" },
                },
            },
        }

    -- ======== 瞄准模式 ========
    elseif trainMode_ == "aim" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "瞄准训练", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "目标会在格子中随机出现\n快速点击目标得分！\n时间 " .. TRAIN_DURATION .. " 秒",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                UI.Button { text = "🏋️ 开始训练", width = 180, height = 44, fontSize = 16, variant = "primary",
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
                InfoRow("技术提升", "+" .. gain, C.blue),
                UI.Panel { height = 16 },
                AdManager.CanWatch("train_bonus", playerData_.day) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "看视频加练 技术再+" .. gain, width = 200, height = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Button { text = "完成", width = 180, height = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 问答模式 ========
    elseif trainMode_ == "quiz" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "🧠 战术问答", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "回答" .. quizTotal_ .. "道FPS战术问题\n选择最佳答案，提升战术素养",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                UI.Button { text = "🧠 开始问答", width = 180, height = 44, fontSize = 16, variant = "primary",
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
                    width = 160, height = 38, fontSize = 14, variant = "primary",
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
                UI.Label { text = "问答结束！", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("正确率", quizCorrect_ .. "/" .. quizTotal_ .. " (" .. pct .. "%)", C.green),
                InfoRow("战术理解", "+" .. gain, C.blue),
                UI.Panel { height = 4 },
                UI.Label { text = pct >= 80 and "" .. m.name .. "对战术理解大幅提升！"
                    or pct >= 60 and "📖 " .. m.name .. "学到了不少战术知识"
                    or "😅 " .. m.name .. "还需要更多学习...",
                    fontSize = 14, fontColor = C.textDim, whiteSpace = "normal", textAlign = "center" },
                UI.Panel { height = 16 },
                AdManager.CanWatch("train_bonus", playerData_.day) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "看视频加练 技术再+" .. gain, width = 200, height = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Button { text = "完成", width = 180, height = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 反应训练模式 ========
    elseif trainMode_ == "react" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "反应训练", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "屏幕出现方向指令，快速点击对应按钮！\n共" .. reactTotal_ .. "轮，难度逐步提升：\n加速→反向→闪现，越快分越高！",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                UI.Button { text = "开始训练", width = 180, height = 44, fontSize = 16, variant = "primary",
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
                    backgroundColor = { 238, 242, 238, 230 }, justifyContent = "center", alignItems = "center",
                    borderWidth = 2, borderColor = C.textDim,
                    children = { UI.Label { text = "准备…", fontSize = 20, fontColor = C.textDim } },
                })
            elseif reactPhaseState_ == "show" then
                local dirIcons = { up = "↑", down = "↓", left = "←", right = "→" }
                local dirNames = { up = "上", down = "下", left = "左", right = "右" }
                -- 闪现模式：方向短暂显示后变成"?"
                local showDir = (not reactFlash_) or (reactFlashTimer_ < 0.4)
                table.insert(bodyChildren, UI.Panel {
                    width = 120, height = 120, borderRadius = 60,
                    backgroundColor = showDir and { 255, 242, 242, 245 } or { 240, 248, 240, 245 },
                    justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = showDir and C.red or C.accent,
                    boxShadow = { { x = 0, y = 0, blur = 20, color = showDir and { 210, 80, 60, 100 } or { 200, 150, 50, 100 } } },
                    children = showDir and {
                        UI.Label { text = dirIcons[reactDirection_] or "?", fontSize = 48 },
                        UI.Label { text = reactReverse_ and "按反向！" or (dirNames[reactDirection_] or ""), fontSize = 13, fontColor = reactReverse_ and C.gold or C.text },
                    } or {
                        UI.Label { text = "?", fontSize = 48 },
                        UI.Label { text = "记住方向！", fontSize = 13, fontColor = C.accent },
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
                    backgroundColor = wasCorrect and { 225, 245, 225, 230 } or { 255, 240, 240, 230 },
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
                UI.Label { text = "反应训练结束！", fontSize = 20, fontColor = C.text },
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
                InfoRow("技术提升", "+" .. gain, C.blue),
                UI.Panel { height = 16 },
                AdManager.CanWatch("train_bonus", playerData_.day) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "看视频加练 技术再+" .. gain, width = 200, height = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Button { text = "完成", width = 180, height = 42, fontSize = 15, variant = "primary",
                    onClick = function() FinishTraining() end },
            }
        end

    -- ======== 记忆训练模式 ========
    elseif trainMode_ == "memory" then
        if trainPhase_ == "ready" then
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "🧩 记忆序列", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Label {
                    text = "图标会依次闪现\n记住顺序后按相同顺序点击！\n每轮通过后序列变长，共" .. memoryTotalRounds_ .. "轮",
                    fontSize = 13, fontColor = C.textDim, textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                },
                UI.Panel { height = 16 },
                UI.Button { text = "🧩 开始训练", width = 180, height = 44, fontSize = 16, variant = "primary",
                    onClick = function()
                        memoryRound_ = 0; memoryCorrect_ = 0; memoryLen_ = 3
                        trainActive_ = true; trainTimer_ = 0
                        StartMemoryRound()
                        BuildUI()
                    end,
                },
            }
        elseif trainPhase_ == "playing" then
            local progress = memoryRound_ .. "/" .. memoryTotalRounds_
            table.insert(bodyChildren, UI.Panel {
                flexDirection = "row", width = "100%", justifyContent = "space-between", paddingHorizontal = 4,
                children = {
                    UI.Label { text = "🧩 第" .. progress .. "轮", fontSize = 14, fontColor = C.accent },
                    UI.Label { text = "" .. memoryCorrect_ .. " 通过", fontSize = 14, fontColor = C.green },
                    UI.Label { text = "长度: " .. memoryLen_, fontSize = 14, fontColor = { 180, 180, 100, 255 } },
                },
            })
            table.insert(bodyChildren, UI.Panel { height = 8 })

            if memoryPhaseState_ == "show" then
                -- 展示阶段：高亮当前展示的图标
                table.insert(bodyChildren, UI.Label { text = "记住这个序列！", fontSize = 14, fontColor = C.gold })
                table.insert(bodyChildren, UI.Panel { height = 8 })
                local seqChildren = {}
                for i, iconIdx in ipairs(memorySequence_) do
                    local isShown = i <= memoryShowIdx_
                    table.insert(seqChildren, UI.Panel {
                        width = 48, height = 48, borderRadius = 10,
                        backgroundColor = isShown and { 248, 252, 248, 245 } or { 242, 245, 242, 200 },
                        justifyContent = "center", alignItems = "center",
                        borderWidth = isShown and 2 or 1,
                        borderColor = isShown and { 180, 180, 100, 255 } or C.border,
                        children = {
                            UI.Label { text = isShown and MEMORY_ICONS[iconIdx] or "?", fontSize = 24 },
                        },
                    })
                end
                table.insert(bodyChildren, UI.Panel {
                    flexDirection = "row", gap = 6, justifyContent = "center", flexWrap = "wrap",
                    children = seqChildren,
                })
            elseif memoryPhaseState_ == "input" then
                -- 输入阶段：显示选择按钮
                table.insert(bodyChildren, UI.Label { text = "按顺序点击还原序列！", fontSize = 14, fontColor = { 180, 180, 100, 255 } })
                table.insert(bodyChildren, UI.Panel { height = 4 })
                -- 已输入的序列
                local inputChildren = {}
                for i = 1, #memorySequence_ do
                    local entered = memoryPlayerSeq_[i]
                    table.insert(inputChildren, UI.Panel {
                        width = 44, height = 44, borderRadius = 8,
                        backgroundColor = entered and C.cardAlt or C.cardAlt,
                        justifyContent = "center", alignItems = "center",
                        borderWidth = 1, borderColor = entered and { 180, 180, 100, 200 } or C.border,
                        children = {
                            UI.Label { text = entered and MEMORY_ICONS[entered] or "·", fontSize = entered and 20 or 16 },
                        },
                    })
                end
                table.insert(bodyChildren, UI.Panel {
                    flexDirection = "row", gap = 4, justifyContent = "center", flexWrap = "wrap",
                    children = inputChildren,
                })
                table.insert(bodyChildren, UI.Panel { height = 8 })
                -- 可选图标按钮（2行4列）
                local iconBtns = {}
                for i, icon in ipairs(MEMORY_ICONS) do
                    table.insert(iconBtns, UI.Panel {
                        width = 52, height = 52, borderRadius = 10,
                        backgroundColor = { 238, 242, 238, 230 },
                        justifyContent = "center", alignItems = "center",
                        borderWidth = 1, borderColor = C.border,
                        pointerEvents = "auto",
                        onClick = function() OnMemoryInput(i) end,
                        children = { UI.Label { text = icon, fontSize = 26 } },
                    })
                end
                table.insert(bodyChildren, UI.Panel {
                    flexDirection = "row", gap = 6, justifyContent = "center", flexWrap = "wrap",
                    width = "95%",
                    children = iconBtns,
                })
            elseif memoryPhaseState_ == "result" then
                local allCorrect = true
                for i, iconIdx in ipairs(memorySequence_) do
                    if memoryPlayerSeq_[i] ~= iconIdx then allCorrect = false; break end
                end
                local resultIcons = {}
                for i, iconIdx in ipairs(memorySequence_) do
                    local playerIcon = memoryPlayerSeq_[i]
                    local ok = playerIcon == iconIdx
                    table.insert(resultIcons, UI.Panel {
                        width = 44, height = 44, borderRadius = 8,
                        backgroundColor = ok and { 225, 245, 225, 230 } or { 255, 240, 240, 230 },
                        justifyContent = "center", alignItems = "center",
                        borderWidth = 2, borderColor = ok and C.green or C.red,
                        children = { UI.Label { text = MEMORY_ICONS[iconIdx], fontSize = 20 } },
                    })
                end
                table.insert(bodyChildren, UI.Label {
                    text = allCorrect and "✓ 完美还原！" or "✗ 序列错误",
                    fontSize = 16, fontColor = allCorrect and C.green or C.red,
                })
                table.insert(bodyChildren, UI.Panel { height = 4 })
                table.insert(bodyChildren, UI.Panel {
                    flexDirection = "row", gap = 4, justifyContent = "center", flexWrap = "wrap",
                    children = resultIcons,
                })
            end

        elseif trainPhase_ == "done" then
            local gain = CalcTrainGain()
            local rating = memoryCorrect_ >= 5 and "S" or memoryCorrect_ >= 4 and "A" or memoryCorrect_ >= 2 and "B" or "C"
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green or rating == "B" and C.blue or C.textDim
            bodyChildren = {
                UI.Panel { height = 16 },
                UI.Label { text = "记忆训练结束！", fontSize = 20, fontColor = C.text },
                UI.Panel { height = 8 },
                UI.Panel {
                    width = 80, height = 80, borderRadius = 40,
                    backgroundColor = C.cardAlt, justifyContent = "center", alignItems = "center",
                    borderWidth = 3, borderColor = ratingColor,
                    children = { UI.Label { text = rating, fontSize = 36, fontColor = ratingColor } },
                },
                UI.Panel { height = 12 },
                InfoRow("通过轮数", memoryCorrect_ .. "/" .. memoryTotalRounds_, C.green),
                InfoRow("最终长度", tostring(memoryLen_), { 180, 180, 100, 255 }),
                InfoRow("技术提升", "+" .. gain, C.blue),
                UI.Panel { height = 16 },
                AdManager.CanWatch("train_bonus", playerData_.day) and AdManager.AdButton {
                    sceneId = "train_bonus", day = playerData_.day,
                    text = "看视频加练 技术再+" .. gain, width = 200, height = 38, fontSize = 12,
                    onReward = function()
                        if trainMember_ then
                            trainMember_.skill = math.min(SKILL_CAP, trainMember_.skill + gain)
                            AddLog("🎬 " .. trainMember_.name .. "用赞助商的专业软件加练！技术+" .. gain)
                        end
                        BuildUI()
                    end,
                } or UI.Panel { height = 0 },
                UI.Button { text = "完成", width = 180, height = 42, fontSize = 15, variant = "primary",
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
                height = 36, paddingHorizontal = 16, fontSize = 13,
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
                backgroundColor = friendlyOpponent_.isElite and { 255, 240, 240, 230 } or C.cardAlt,
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
                text = "看视频赛前强化 战力+15%",
                width = 220, height = 40, fontSize = 13,
                onReward = function()
                    midDecisionBonus_ = (midDecisionBonus_ or 0) + math.floor(GetTeamPower() * 0.15)
                    AddLog("🎬 赞助商赠送了能量补给！全队状态拉满，战力+15%！")
                    BuildUI()
                end,
            })
        end
        table.insert(children, UI.Button { text = "⚔️ 出发！", width = 180, height = 44, fontSize = 16, variant = "primary",
            onClick = function()
                PlaySFX("click")
                matchLog_ = {}; matchWins_ = 0
                StartMatchRound(1)
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
                    text = c.text .. riskTag, width = "85%", height = 40, fontSize = 13,
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
                backgroundColor = isGood and { 230, 248, 228, 230 } or { 255, 242, 242, 230 },
                borderWidth = 1, borderColor = isGood and C.green or C.red,
                children = {
                    UI.Label { text = isGood and "互动结果" or "互动结果", fontSize = 15, fontColor = isGood and C.green or C.red },
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
            table.insert(children, UI.Button { text = "返回管理", width = "60%", height = 38, fontSize = 14, onClick = function()
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
                width = "80%", padding = 6, backgroundColor = { 225, 245, 225, 220 }, borderRadius = 6,
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
        table.insert(children, UI.Label { text = "选择战术:", fontSize = 14, fontColor = C.gold })
        table.insert(children, UI.Panel { height = 4 })

        local tactics = {
            { key = "aggressive", icon = "", name = "猛攻", desc = "全力进攻，克制防守反击，但被快攻克制" },
            { key = "balanced",   icon = "⚖️", name = "均衡", desc = "攻守平衡，无明显克制，稳定加成" },
            { key = "defensive",  icon = "", name = "防守", desc = "稳守反击，克制快攻型，但被防守反击克制" },
        }
        for _, t in ipairs(tactics) do
            local isSelected = matchTactic_ == t.key
            table.insert(children, UI.Button {
                text = t.icon .. " " .. t.name .. (isSelected and " ✓" or ""),
                width = "80%", height = 38, fontSize = 13,
                variant = isSelected and "primary" or "secondary",
                onClick = function()
                    PlaySFX("click")
                    matchTactic_ = t.key; BuildUI()
                end,
            })
            table.insert(children, UI.Label { text = t.desc, fontSize = 14, fontColor = C.textDim, width = "80%", textAlign = "center", whiteSpace = "normal" })
            table.insert(children, UI.Panel { height = 2 })
        end
        table.insert(children, UI.Panel { height = 8 })
        table.insert(children, UI.Button { text = "⚔️ 开战！", width = 160, height = 42, fontSize = 15, variant = "primary",
            onClick = function()
                PlaySFX("gunshot")
                -- 随机触发中局决策（90%概率，让玩家更有参与感）
                if math.random() < 0.9 then
                    midDecision_ = MID_DECISION_POOL[math.random(1, #MID_DECISION_POOL)]
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
                    text = choice.text .. riskTag, width = "85%", height = 40, fontSize = 13,
                    variant = choice.risk and "danger" or "secondary",
                    onClick = function()
                        PlaySFX("click")
                        ResolveMidDecision(ci)
                    end,
                })
                table.insert(children, UI.Label {
                    text = choice.desc .. " (战力" .. bonusText .. ")",
                    fontSize = 14, fontColor = bonusColor, width = "80%", textAlign = "center", whiteSpace = "normal",
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
                backgroundColor = isGood and { 230, 248, 228, 230 } or { 255, 242, 242, 230 },
                borderWidth = 1, borderColor = isGood and C.green or C.red,
                children = {
                    UI.Label { text = isGood and "决策结果" or "决策结果", fontSize = 15, fontColor = isGood and C.green or C.red },
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
        -- 单场结果叙事
        table.insert(children, UI.Panel { height = 6 })
        table.insert(children, UI.Label { text = "── 第" .. matchRound_ .. "场战报 ──", fontSize = 15, fontColor = C.text })
        table.insert(children, UI.Panel { height = 4 })
        for _, line in ipairs(matchNarrative_) do
            table.insert(children, UI.Label { text = line.text, fontSize = 14, fontColor = line.color or C.text, width = "88%", whiteSpace = "normal", lineHeight = 1.4 })
        end
        table.insert(children, UI.Panel { height = 10 })

        -- 判断是否已决出胜负（单败淘汰制）
        local losses = matchRound_ - matchWins_
        local totalRounds = #matchOpponents_
        if losses > 0 or matchRound_ >= totalRounds then
            -- 输了一场即淘汰，或打完全部对手
            table.insert(children, UI.Button { text = "查看总战报", width = 180, height = 42, fontSize = 14, variant = "primary",
                onClick = function() PlaySFX("click"); FinishMatch() end })
        else
            -- 还有下一场
            local nextOpp = matchOpponents_[matchRound_ + 1]
            local nextLabel = nextOpp and ("➡️ 下一场: " .. nextOpp.emoji .. " " .. nextOpp.name) or "➡️ 下一场"
            table.insert(children, UI.Button { text = nextLabel, width = 220, height = 42, fontSize = 13, variant = "primary",
                onClick = function() PlaySFX("click"); StartMatchRound(matchRound_ + 1) end })
        end

    elseif matchPhase_ == "final_result" then
        -- 总战报
        for _, log in ipairs(matchLog_) do
            table.insert(children, UI.Label { text = log.text, fontSize = 14, fontColor = log.color or C.text, width = "88%", whiteSpace = "normal" })
        end
        table.insert(children, UI.Panel { height = 8 })
        local won = matchResult_ == "win"

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
                    text = "看视频领额外奖金 +$" .. extraReward,
                    width = 220, height = 40, fontSize = 13,
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
                    text = "看视频获得败者补偿 全队技术+3",
                    width = 220, height = 40, fontSize = 13,
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
            local loseText = tCfg and tCfg.loseText or "💔 虽败犹荣……但故事还没有结束。"
            table.insert(children, UI.Label {
                text = won and winText or loseText,
                fontSize = 15, fontColor = won and C.gold or C.red, width = "88%", textAlign = "center", whiteSpace = "normal",
            })
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
                    text = "看视频领额外奖金 +$" .. extraPrize,
                    width = 220, height = 40, fontSize = 13,
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
                    text = "看视频获得败者补偿 全队技术+5 声望+10",
                    width = 240, height = 40, fontSize = 13,
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
-- ============================================================================

--- 根据比赛结果和karma值计算结局
function GetEnding()
    local won = matchResult_ == "win"
    local k = playerData_.karma
    local totalEarn = playerData_.totalEarnings or 0
    local branchCount = #(playerData_.branches or {})
    local seasonId = playerData_.seasonId or 1

    -- 终极结局：博拉卡伊咖啡店（隐藏结局）
    -- 条件：赢得比赛 + 累计收入≥50000 + 至少2家分店 + 赛季达到传奇以上
    if won and totalEarn >= 50000 and branchCount >= 2 and seasonId >= 3 then
        return {
            icon = "🏝️", title = "终极结局：博拉卡伊的日落",
            difficulty = 5, diffLabel = "隐藏", diffColor = { 255, 120, 255, 255 },
            hint = "赢得比赛 + 累计收入$50000+ + 2家分店 + 传奇赛季",
            color = { 255, 180, 100, 255 }, borderColor = { 255, 200, 120, 180 },
            desc = "Dragon Force 夺冠的那晚，你没有参加庆功宴。\n\n"
                .. "你坐在网吧天台上，看着拉各斯的灯火，翻开手机里一张旧照片——碧蓝的海水、白色的沙滩、椰树下的小木屋。那是你来非洲之前，在博拉卡伊拍的。\n\n"
                .. "当初你跟自己说：'等我挣够了钱，就去那里开一间咖啡店，面朝大海，什么都不想。'\n\n"
                .. "你看了看银行账户——".. string.format("$%d", totalEarn) .."。" .. branchCount .. "家分店在自动运转。队员们已经可以独当一面。\n\n"
                .. "三个月后，博拉卡伊白沙滩上多了一间小咖啡店。店名叫 'Dragon Café'。\n\n"
                .. "每天早上，你磨咖啡豆、冲拿铁、看海浪。偶尔有客人问：'老板以前是做什么的？'\n\n"
                .. "你笑笑：'我啊……以前在非洲开网吧。'\n\n"
                .. "手机弹出消息——Snake发来的视频：Dragon Force在新赛季又夺冠了。\n\n"
                .. "你端起咖啡，对着夕阳举了举杯。",
            epilogue = "「人生最好的结局，不是到达终点，而是终于可以停下来。」",
            bgImage = SCENE_IMAGES.ending_beach,
        }
    end

    if won and k >= 4 then
        return {
            icon = "", title = "传奇结局：非洲之光",
            difficulty = 3, diffLabel = "困难", diffColor = { 255, 180, 50, 255 },
            hint = "赢得比赛 + 善良抉择(karma≥4)",
            color = { 255, 215, 0, 255 }, borderColor = { 255, 210, 70, 150 },
            desc = "Dragon Force 不仅赢得了冠军，更赢得了整个非洲的尊重。\n\n你用真诚和善意经营网吧，帮助每一个走进来的年轻人。Snake放下了街头的刀，Grace得到了父亲的祝福，Kofi用奖金给妈妈盖了新房。\n\n国际媒体报道：'一个中国人，在非洲点燃了电竞的星火。'\n\n多年后，Dragon Net Cafe成了非洲电竞的圣地。每年都有来自世界各地的人来这里朝圣——不是为了冠军奖杯，而是为了这里永远敞开的门。",
            epilogue = "「真正的胜利，不是战胜对手，而是改变命运。」",
            bgImage = SCENE_IMAGES.ending_legend,
        }
    elseif won and k <= -3 then
        return {
            icon = "", title = "商业结局：电竞帝国",
            difficulty = 3, diffLabel = "困难", diffColor = { 255, 180, 50, 255 },
            hint = "赢得比赛 + 自私抉择(karma≤-3)",
            color = { 0, 255, 128, 255 }, borderColor = { 0, 200, 100, 150 },
            desc = "Dragon Force 夺冠后，你迅速将品牌商业化。\n\n赞助商蜂拥而至，代练业务遍布非洲。你在五个国家开了连锁网吧，成了'非洲电竞教父'。\n\n但队员们渐渐疏远了你。Snake回到了街头，说'老板只在乎钱'。Kofi默默离开了，没有道别。\n\n你坐在豪华办公室里，看着银行账户上的数字，窗外是灯火通明的城市。一切都很好，只是……有时候会想起那间铁皮屋顶的小网吧。",
            epilogue = "「你赢得了一切，除了那些最重要的东西。」",
            bgImage = SCENE_IMAGES.ending_empire,
        }
    elseif won then
        return {
            icon = "", title = "荣耀结局：冠军之路",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "赢得比赛 + 中性抉择",
            color = { 255, 210, 70, 255 }, borderColor = { 255, 210, 70, 120 },
            desc = "Dragon Force 赢得全非洲三角洲锦标赛！\n\n这是一支由来自不同角落的人组成的队伍——前保镖、牧师的女儿、街头少年、卖烤鸡的大婶……他们因为跑刀聚在一起，因为你的坚持走到最后。\n\n颁奖那晚，所有人围坐在网吧里，吃着Mama Blessing的烤鸡，看着奖杯在烛光下闪闪发亮。\n\n'明年，我们去打世界赛！'有人说。所有人笑了。",
            epilogue = "「从铁皮屋顶到非洲之巅——这就是Dragon Force的故事。」",
            bgImage = SCENE_IMAGES.victory,
        }
    elseif not won and k >= 4 then
        return {
            icon = "", title = "温暖结局：比赛之外",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "比赛失利 + 善良抉择(karma≥4)",
            color = { 100, 180, 255, 255 }, borderColor = { 100, 180, 255, 120 },
            desc = "Dragon Force 没能夺冠。但你知道，这从来不只是关于比赛。\n\nSnake因为你的信任，彻底告别了街头。Grace考上了大学，每个假期都回来帮忙。Kofi成了当地小有名气的电竞教练。\n\n你的网吧成了镇上年轻人的避风港。有孩子来这里学电脑，有人来这里找工作，有人只是来这里坐坐，因为'这里感觉像家'。\n\n输了比赛，赢了人生。也许，这才是你来非洲的意义。",
            epilogue = "「有些东西比冠军更重要。你知道的。」",
            bgImage = SCENE_IMAGES.ending_warmth,
        }
    elseif not won and k <= -3 then
        return {
            icon = "✈️", title = "遗憾结局：回国之路",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "比赛失利 + 自私抉择(karma≤-3)",
            color = { 180, 100, 100, 255 }, borderColor = { 180, 80, 80, 120 },
            desc = "比赛输了。赞助商撤资，代练订单也断了。\n\n你坐在空荡荡的网吧里算了算账——该走了。\n\n收拾行李那天，没有人来送你。只有Mama Blessing在门口放了一份烤鸡，上面贴着便条：'谢谢你，中国老板。'\n\n飞机起飞的时候，你望着窗外越来越小的非洲大陆，想着如果当初对队员好一点，结果会不会不一样。\n\n手机震动，是Snake发来的消息：'老大你走了？……算了。'",
            epilogue = "「有些路走错了，就回不了头了。」",
            bgImage = SCENE_IMAGES.ending_depart,
        }
    else
        return {
            icon = "🌅", title = "平凡结局：明日再战",
            difficulty = 1, diffLabel = "简单", diffColor = { 150, 180, 150, 255 },
            hint = "比赛失利 + 中性抉择",
            color = { 160, 175, 160, 255 }, borderColor = { 195, 210, 195, 120 },
            desc = "Dragon Force 止步半决赛。遗憾，但不绝望。\n\n生活还在继续。网吧每天照常开门，队员们继续训练。你学会了更多斯瓦希里语，也学会了在停电时讲笑话。\n\n'明年再来！'Big Joe举起装满可乐的杯子。所有人碰杯。\n\n窗外非洲的夕阳很美。铁皮屋顶被染成金色。键盘声、笑声、和远处的鼓声混在一起。\n\n日子不完美，但很真实。这就够了。",
            epilogue = "「故事还没结束。明天见。」",
            bgImage = SCENE_IMAGES.ending_sunset,
        }
    end
end

function BuildResultUI()
    local ending = GetEnding()
    local karmaLabel = playerData_.karma >= 4 and "仁义之师" or (playerData_.karma <= -3 and "利益至上" or "中庸之道")
    local karmaColor = playerData_.karma >= 4 and C.green or (playerData_.karma <= -3 and C.red or C.gold)

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = ending.bgImage,
        backgroundFit = "cover",
        justifyContent = "center", alignItems = "center", padding = 16,
        children = {
            UI.ScrollView {
                width = "90%", maxWidth = 420, maxHeight = "92%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 24, 18 }, gap = 8,
                        backgroundColor = C.card, borderRadius = 20,
                        borderWidth = 2, borderColor = ending.borderColor,
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 6, blur = 20, color = { 120, 100, 70, 80 } } },
                        children = {
                            UI.Label { text = ending.icon, fontSize = 48 },
                            UI.Label { text = ending.title, fontSize = 22, fontColor = ending.color,
                                textShadow = { offsetX = 0, offsetY = 2, blur = 6, color = { 160, 130, 90, 100 } } },
                            -- 难度标签和星级
                            UI.Panel {
                                flexDirection = "row", gap = 6, alignItems = "center",
                                paddingHorizontal = 10, paddingVertical = 3,
                                backgroundColor = C.cardAlt, borderRadius = 12,
                                children = {
                                    UI.Label { text = string.rep("★", ending.difficulty), fontSize = 12, fontColor = C.gold },
                                    UI.Label { text = ending.diffLabel, fontSize = 11, fontColor = ending.diffColor, fontWeight = "bold" },
                                },
                            },
                            -- 解锁条件提示
                            UI.Label { text = "🔓 " .. ending.hint, fontSize = 11, fontColor = C.textLight,
                                textAlign = "center", whiteSpace = "normal", width = "100%" },
                            UI.Panel { height = 2 },
                            UI.Panel {
                                width = "100%", padding = 12, gap = 4,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = ending.desc, fontSize = 14, fontColor = C.text,
                                        textAlign = "center", whiteSpace = "normal", lineHeight = 1.6, width = "100%" },
                                },
                            },
                            UI.Panel { height = 4 },
                            UI.Label { text = ending.epilogue, fontSize = 13, fontColor = ending.color,
                                textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                                fontStyle = "italic" },
                            UI.Panel { height = 6 },
                            UI.Panel {
                                width = "100%", padding = 10, gap = 4,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = "最终成绩", fontSize = 13, fontColor = C.accent },
                                    InfoRow("经营天数", playerData_.day .. "天"),
                                    InfoRow("总资产", "$" .. playerData_.money, C.green),
                                    InfoRow("声望值", tostring(playerData_.reputation), C.gold),
                                    InfoRow("战队人数", #teamMembers_ .. "人"),
                                    InfoRow("战队实力", tostring(GetTeamPower()), C.blue),
                                    InfoRow("友谊赛", playerData_.friendlyWins .. "胜 " .. playerData_.friendlyLosses .. "负", C.accent),
                                    InfoRow("锦标赛", (playerData_.tournamentWins or 0) .. "冠 / " .. (playerData_.tournamentPlayed or 0) .. "赛", C.gold),
                                    InfoRow("成就解锁", GetUnlockedCount() .. "/" .. #ACHIEVEMENTS, C.gold),
                                    InfoRow("累计收入", "$" .. (playerData_.totalEarnings or 0), C.green),
                                    InfoRow("分店数量", #(playerData_.branches or {}) .. "家", C.accent),
                                    InfoRow("赛季等级", ({ "新秀", "精英", "传奇", "王者" })[playerData_.seasonId or 1] or "王者", C.gold),
                                    InfoRow("抉择倾向", karmaLabel, karmaColor),
                                },
                            },
                            -- 结局图鉴
                            UI.Panel { height = 4 },
                            UI.Panel {
                                width = "100%", padding = 10, gap = 3,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = "结局图鉴 (共8种)", fontSize = 13, fontColor = C.accent },
                                    UI.Label { text = "★ 平凡结局 · ★ 破产结局", fontSize = 11, fontColor = { 150, 200, 150, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★ 荣耀之路 · ★★ 温暖结局 · ★★ 遗憾结局", fontSize = 11, fontColor = { 100, 200, 255, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★★ 传奇结局 · ★★★ 商业结局", fontSize = 11, fontColor = { 255, 200, 80, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★★★★ 终极隐藏结局", fontSize = 11, fontColor = { 255, 140, 255, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "提示：抉择影响karma，善恶决定结局走向", fontSize = 10, fontColor = C.textLight, whiteSpace = "normal", width = "100%", fontStyle = "italic" },
                                },
                            },
                            UI.Panel { height = 6 },
                            UI.Button { text = "继续经营（返回游戏）", width = "90%", height = 42, fontSize = 14, variant = "primary",
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("🏠 回到网吧", "传奇仍在继续……", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end },
                            UI.Panel { height = 4 },
                            UI.Button { text = "重新开始（解锁其他结局）", width = "90%", height = 36, fontSize = 13,
                                onClick = function()
                                    StartTransition("新的旅程", "不同的选择，不同的命运", function()
                                        ResetGame()
                                    end)
                                end },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 17.5 破产结局画面
-- ============================================================================
function BuildGameOverUI()
    local daysSurvived = playerData_.day - 1
    local teamSize = #teamMembers_

    -- 根据坚持天数选择不同叙事
    local narrative
    if daysSurvived <= 7 then
        narrative = "网吧刚开没多久，就入不敷出了。非洲的烈日依旧炙烤着大地，但你的网吧却彻底凉了。街角的Mama Blessing默默收起了她的烤鸡摊。"
    elseif daysSurvived <= 20 then
        narrative = "你努力了将近一个月，但不断上涨的房租和各种意外最终压垮了这家小网吧。门口的招牌被风吹歪了，没人再来扶正它。"
    elseif daysSurvived <= 40 then
        narrative = "你在这片土地上坚持了" .. daysSurvived .. "天，队员们跟着你经历了不少风雨。但商业的残酷不分国界，网吧最终还是关门了。大家含泪拥抱，约定来日方长。"
    else
        narrative = "整整" .. daysSurvived .. "天，你把一间铁皮小屋变成了远近闻名的跑刀圣地。虽然最终败给了现实，但'Dragon Net Cafe'的传说，将在这条街上流传很久。"
    end

    -- 队员告别语
    local farewellText = ""
    if teamSize > 0 then
        local names = {}
        for _, m in ipairs(teamMembers_) do table.insert(names, m.emoji .. m.name) end
        farewellText = table.concat(names, "、") .. " 向你挥手告别……"
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.ending_bankrupt,
        backgroundFit = "cover",
        imageTint = { 215, 225, 215, 255 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 16,
        children = {
            UI.ScrollView {
                width = "90%", maxWidth = 420, maxHeight = "92%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 24, 20 }, gap = 10,
                        backgroundColor = C.card, borderRadius = 20,
                        borderWidth = 2, borderColor = { 200, 70, 60, 120 },
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 6, blur = 20, color = { 0, 0, 0, 120 } } },
                        children = {
                            UI.Label { text = "", fontSize = 48 },
                            UI.Panel { height = 4 },
                            UI.Label { text = "破产结局：网吧倒闭", fontSize = 22, fontColor = C.red,
                                textShadow = { offsetX = 0, offsetY = 2, blur = 6, color = { 0, 0, 0, 160 } } },
                            UI.Panel {
                                flexDirection = "row", gap = 6, alignItems = "center",
                                paddingHorizontal = 10, paddingVertical = 3,
                                backgroundColor = C.cardAlt, borderRadius = 12,
                                children = {
                                    UI.Label { text = "★", fontSize = 12, fontColor = C.gold },
                                    UI.Label { text = "简单", fontSize = 11, fontColor = C.green, fontWeight = "bold" },
                                },
                            },
                            UI.Label { text = "资金耗尽即触发", fontSize = 11, fontColor = C.textLight,
                                textAlign = "center" },
                            UI.Panel { height = 4 },
                            UI.Label { text = narrative, fontSize = 13, fontColor = C.text,
                                whiteSpace = "normal", textAlign = "center", lineHeight = 1.6, width = "100%" },
                            teamSize > 0 and UI.Label {
                                text = farewellText, fontSize = 14, fontColor = C.textDim,
                                whiteSpace = "normal", textAlign = "center", width = "100%",
                                fontStyle = "italic",
                            } or UI.Panel { height = 0 },
                            UI.Panel { height = 8 },
                            -- 经营记录
                            UI.Panel {
                                width = "100%", padding = 12, gap = 5,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    PanelHeader("经营记录", { icon = "", compact = true }),
                                    InfoRow("坚持天数", daysSurvived .. " 天"),
                                    InfoRow("最终规模", playerData_.computers .. " 台电脑"),
                                    InfoRow("队伍人数", teamSize .. " 人"),
                                    InfoRow("最高声望", tostring(playerData_.reputation), C.gold),
                                    InfoRow("成就解锁", GetUnlockedCount() .. "/" .. #ACHIEVEMENTS, C.gold),
                                },
                            },
                            UI.Panel { height = 8 },
                            -- 小贴士
                            UI.Panel {
                                width = "100%", padding = 10,
                                backgroundColor = C.cardAlt, borderRadius = 8,
                                children = {
                                    UI.Label {
                                        text = "经营小贴士：尽早升级烤鸡摊和装饰，可以显著增加每日收入。控制升级节奏，别把钱花光了！",
                                        fontSize = 13, fontColor = C.green,
                                        whiteSpace = "normal", lineHeight = 1.5, width = "100%",
                                    },
                                },
                            },
                            UI.Panel { height = 10 },
                            AdManager.CanWatch("bailout_boost", playerData_.day) and AdManager.AdButton {
                                sceneId = "bailout_boost", day = playerData_.day,
                                text = "看视频获得赞助商投资 $600", width = "80%", height = 46, fontSize = 15,
                                onReward = function()
                                    playerData_.money = 600
                                    AddLog("�� 赞助商看好你的潜力，投资了$600！声望不减，卷土重来！")
                                    StartTransition("💰 赞助商投资", "有人相信你的实力！这笔投资让你重新站起来。", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end,
                            } or UI.Panel { height = 0 },
                            UI.Button {
                                text = "接受救济，继续经营", width = "80%", height = 46, fontSize = 16, variant = "primary",
                                onClick = function()
                                    PlaySFX("click")
                                    local bailout = 300
                                    playerData_.money = bailout
                                    playerData_.reputation = math.max(0, playerData_.reputation - 20)
                                    AddLog("🤝 Mama Blessing和邻居们凑了$" .. bailout .. "帮你渡过难关。你决定重整旗鼓！")
                                    AddLog("  （声望 -20，大家虽然帮了你，但街坊们的眼神多了几分同情……）")
                                    StartTransition("🤝 好心人的援手", "跌倒了，爬起来！街坊邻居不会看着你倒下。", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Button {
                                text = "东山再起（重新开始）", width = "80%", height = 38, fontSize = 14,
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("重新出发", "这次一定行！", function()
                                        ResetGame()
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Label { text = "\"跌倒了不可怕，可怕的是不敢再站起来。\"", fontSize = 13,
                                fontColor = C.textLight, fontStyle = "italic" },
                        },
                    },
                },
            },
        },
    }
end

