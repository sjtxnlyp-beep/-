---@diagnostic disable: undefined-global
local Achievements = require("Achievements")
local NPCStorylines = require("NPCStorylines")
local NarrativeLayer = require("NarrativeLayer")

-- ============================================================================
-- 14. 随机事件界面（带背景图）
-- ============================================================================
require("UE_Train")
require("UE_Match")
require("UE_Result")

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
                text = ch.text, width = "100%", minHeight = 38, fontSize = 13,
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
                    -- P1-a: 记录选择（用于延迟后果展示）
                    local choiceKey = ch.narrativeKey or (string.find(ch.text, "帮") and "helped")
                        or (string.find(ch.text, "拒") and "refused")
                        or (string.find(ch.text, "原谅") and "forgave")
                        or (string.find(ch.text, "惩") and "punished")
                        or (string.find(ch.text, "收养") and "adopted")
                        or (string.find(ch.text, "合作") and "accepted")
                        or (string.find(ch.text, "欢迎") and "welcomed")
                        or (string.find(ch.text, "送") and "kind")
                        or "default"
                    NarrativeLayer.RecordChoice(safeTitle, choiceKey)
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

    -- 如果没有choices也没有candidate（纯展示型事件），加一个确认按钮
    if not evt.choices and not evt.candidate then
        table.insert(choiceBtns, UI.Button {
            text = "确认", width = "100%", minHeight = 38, fontSize = 13, variant = "primary",
            onClick = function()
                local moneyBefore = playerData_.money
                if evt.effect then
                    local ok, err = pcall(evt.effect)
                    if not ok then log:Write(LOG_ERROR, "[EventAuto] effect error: " .. tostring(err)) end
                end
                local moneyChange = playerData_.money - moneyBefore
                local safeIcon = evt.icon or ""
                local safeTitle = evt.title or "事件"
                -- auto 类型：直接回到管理界面，不再弹出结果二次确认
                if evt.type == "auto" then
                    local resultText = type(evt.autoResult) == "function" and evt.autoResult()
                                       or (evt.autoResult or evt.result or "")
                    if type(resultText) == "function" then
                        local ok2, res = pcall(resultText)
                        resultText = ok2 and res or ""
                    end
                    AddLog(safeIcon .. " " .. safeTitle)
                    if resultText and resultText ~= "" then AddLog("  " .. resultText) end
                    eventResult_ = nil
                    currentEvent_ = nil
                    currentPhase_ = PHASE_MANAGE
                    BuildUI()
                    return
                end
                -- 普通展示型事件：保留原有结果弹窗流程
                local moneyChangeStr = nil
                if moneyChange > 0 then moneyChangeStr = "+$" .. moneyChange
                elseif moneyChange < 0 then moneyChangeStr = "-$" .. (-moneyChange) end
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
                    effects = moneyChangeStr,
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
            width = "100%", padding = 8, gap = 2,
            backgroundColor = C.cardAlt, borderRadius = 8,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                    c.avatar and UI.Panel {
                        width = 32, height = 32, borderRadius = 16,
                        backgroundImage = c.avatar, backgroundFit = "cover",
                        borderWidth = 1, borderColor = C.accent,
                    } or UI.Label { text = c.emoji, fontSize = 20 },
                    UI.Panel { flex = 1, gap = 1, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = c.name, fontSize = 13, fontColor = C.text, fontWeight = "bold" },
                            UI.Label { text = "「" .. c.trait .. "」", fontSize = 11, fontColor = C.textDim },
                            UI.Label { text = "天赋" .. c.talent, fontSize = 10, fontColor = C.blue },
                            UI.Label { text = "技术" .. c.skill, fontSize = 10, fontColor = C.green },
                        }},
                        UI.Label { text = c.desc, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                    }},
                }},
                victorCompeting and UI.Panel {
                    width = "100%", padding = 4, marginTop = 2,
                    backgroundColor = { C.red[1], C.red[2], C.red[3], 20 }, borderRadius = 4,
                    children = {
                        UI.Label { text = "⚠ Victor 竞争中 · 成功率↓", fontSize = 11, fontColor = C.red },
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
                        if selected then recruitReplaceIdx_ = nil else recruitReplaceIdx_ = ti end
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
            -- 图鉴系统 hook：招募角色
            if LoreSystem and LoreSystem.OnRecruit then
                pcall(LoreSystem.OnRecruit, c.name)
            end
        end
        -- 普通招募 / 替换
        local recruitLabel = isFull
            and (recruitReplaceIdx_ and ("替换（$" .. c.fee .. "）成功率 " .. chance .. "%") or "先选择要替换的队员 ↑")
            or ("招募（$" .. c.fee .. "）成功率 " .. chance .. "%")
        table.insert(choiceBtns, UI.Button {
            text = recruitLabel,
            width = "100%", minHeight = 38, fontSize = 14, variant = "primary",
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
            width = "100%", minHeight = 38, fontSize = 14, variant = "secondary",
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
            text = "👋 下次再说", width = "100%", minHeight = 38, fontSize = 14,
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
    if descCharLen > 300 then
        local bytePos = utf8.offset(descText, 298) or #descText
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
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                children = {
                    UI.Panel {
                        width = "100%", gap = 8, alignItems = "center",
                        children = (function()
                            local c = {
                                UI.Label { text = evt.icon or "", fontSize = 36 },
                                UI.Label { text = evt.title or "事件", fontSize = 16, fontColor = C.gold, fontWeight = "bold" },
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
        -- 集市摊贩支线故事推进回调
        if currentEvent_ and currentEvent_._marketVendor then
            local MS = require("MarketStorylines")
            pcall(MS.OnEventCompleted, currentEvent_.id, currentEvent_._marketVendor, currentEvent_._marketStage)
        end
        -- 集市跨线联动事件完成回调
        if currentEvent_ and currentEvent_._marketCrossline then
            local MS = require("MarketStorylines")
            pcall(MS.OnCrosslineCompleted, currentEvent_.id)
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
        text = "确认", width = 180, minHeight = 42, fontSize = 15, variant = "primary",
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
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = children,
            },
        },
    }
end

-- ============================================================================
-- 15a. 踢馆挑战 UI（Ban/Pick + 训练对比模式）
-- ============================================================================
function BuildChallengeRoundUI()
    local opp = challengeOpponent_ or {}
    local modeLabels = CHALLENGE_MODE_LABELS or {}
    local modeEmojis = CHALLENGE_MODE_EMOJIS or {}
    local phase = challengePhase_

    -- ---------- playing: 训练游戏界面（复用 BuildTrainUI，传 true 避免递归） ----------
    if phase == "playing" then
        return BuildTrainUI(true)
    end

    -- ---------- ban_pick: Ban/Pick 选模式 ----------
    if phase == "ban_pick" then
        local allModes = challengeAllModes_ or { "aim", "quiz", "memory", "react", "comm" }
        local banDone = (challengeBanPhase_ == "done")

        -- Ban 阶段 UI
        local banChildren = {}
        if not banDone then
            -- 玩家 Ban 阶段
            table.insert(banChildren, UI.Label { text = "⚔️ Ban/Pick 阶段", fontSize = 20, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" })
            table.insert(banChildren, UI.Label { text = "选择一个你要禁用的项目", fontSize = 13, fontColor = C.textDim, textAlign = "center", width = "100%" })
            table.insert(banChildren, UI.Label { text = "（对手也会禁用一个，剩余3项进行Bo3）", fontSize = 11, fontColor = C.textDim, textAlign = "center", width = "100%" })
            table.insert(banChildren, UI.Panel { height = 8 })

            for _, m in ipairs(allModes) do
                table.insert(banChildren, UI.Button {
                    text = (modeEmojis[m] or "") .. " " .. (modeLabels[m] or m),
                    fontSize = 14, minHeight = 42, width = "100%",
                    variant = "secondary",
                    onClick = function() ChallengePlayerBan(m) end,
                })
            end
        else
            -- Ban 结果展示 + 确认开始
            table.insert(banChildren, UI.Label { text = "⚔️ Ban/Pick 完成", fontSize = 20, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" })
            table.insert(banChildren, UI.Panel { height = 8 })

            -- 你的 Ban
            table.insert(banChildren, UI.Panel {
                width = "100%", padding = 10, backgroundColor = { 60, 30, 30, 180 }, borderRadius = 8, gap = 4,
                children = {
                    UI.Label { text = "你禁用了", fontSize = 12, fontColor = C.textDim },
                    UI.Label { text = (modeEmojis[challengePlayerBan_] or "") .. " " .. (modeLabels[challengePlayerBan_] or ""), fontSize = 15, fontColor = C.red, fontWeight = "bold" },
                },
            })
            -- 对手 Ban
            table.insert(banChildren, UI.Panel {
                width = "100%", padding = 10, backgroundColor = { 60, 30, 30, 180 }, borderRadius = 8, gap = 4,
                children = {
                    UI.Label { text = (opp.emoji or "") .. " " .. (opp.name or "") .. " 禁用了", fontSize = 12, fontColor = C.textDim },
                    UI.Label { text = (modeEmojis[challengeNPCBan_] or "") .. " " .. (modeLabels[challengeNPCBan_] or ""), fontSize = 15, fontColor = C.red, fontWeight = "bold" },
                },
            })
            table.insert(banChildren, UI.Panel { height = 8 })

            -- Bo3 赛程
            table.insert(banChildren, UI.Label { text = "Bo3 赛程", fontSize = 14, fontColor = C.accent, fontWeight = "bold", width = "100%" })
            for i, m in ipairs(challengeModes_) do
                table.insert(banChildren, UI.Panel {
                    width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = 6,
                    flexDirection = "row", alignItems = "center", gap = 8,
                    children = {
                        UI.Label { text = "R" .. i, fontSize = 13, fontColor = C.gold, fontWeight = "bold", width = 28 },
                        UI.Label { text = (modeEmojis[m] or "") .. " " .. (modeLabels[m] or m), fontSize = 14, fontColor = C.text },
                    },
                })
            end
            table.insert(banChildren, UI.Panel { height = 8 })

            table.insert(banChildren, UI.Button {
                text = "开始挑战！", width = 200, minHeight = 44, fontSize = 16,
                variant = "primary",
                onClick = function()
                    challengeRound_ = 1
                    challengePhase_ = "round_intro"
                    BuildUI()
                end,
            })
        end

        return UI.Panel {
            width = "100%", height = "100%", padding = 16, gap = 6,
            backgroundColor = C.bg,
            justifyContent = "center", alignItems = "center",
            children = banChildren,
        }
    end

    -- ---------- select_wager ----------
    if phase == "select_wager" then
        local pScore = CalcCafeScore()
        local nScore = challengeNPCScore_

        -- 赌注选项生成
        local function WagerBtn(label, wType, wAmt)
            return UI.Button {
                text = label, fontSize = 13, minHeight = 34, flex = 1,
                variant = "secondary",
                onClick = function() ConfirmChallengeWager(wType, wAmt) end,
            }
        end

        return UI.Panel {
            width = "100%", height = "100%", padding = 12, gap = 8,
            backgroundColor = C.bg,
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

                -- Bo3 说明
                UI.Panel {
                    width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = 8, gap = 3,
                    children = {
                        UI.Label { text = "Ban/Pick Bo3（先胜2局）", fontSize = 13, fontColor = C.accent },
                        UI.Label { text = "双方各禁用1个项目，剩余3项进行Bo3", fontSize = 11, fontColor = C.textDim },
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
                    text = "← 放弃踢馆", minHeight = 36, fontSize = 13, width = "100%",
                    onClick = function()
                        -- 退还行动点
                        playerData_.actionPoints = playerData_.actionPoints + 1
                        challengeActive_ = false; challengeDay_ = 0
                        challengeOpponent_ = nil; challengePhase_ = "select_wager"
                        challengeRoundResult_ = nil
                        challengePlayerBan_ = nil; challengeNPCBan_ = nil; challengeBanPhase_ = "player"
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
            local bgC = C.cardAlt
            local label = "R" .. i
            if i < challengeRound_ then
                -- 判定过去轮次结果（简单：根据当前wins回推）
                label = "✓"
                bgC = { 50, 80, 50, 220 }
            elseif i == challengeRound_ then
                label = ">"
                bgC = C.card
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
            backgroundColor = C.bg,
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
                    text = "开始比拼！", width = 200, minHeight = 44, fontSize = 16,
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
            backgroundColor = C.bg,
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
                            backgroundColor = { 60, 50, 40, 150 }, borderRadius = 6, paddingHorizontal = 6, paddingVertical = 3,
                            children = {
                            UI.Label { text = "综合分加成 (" .. bonusSign .. bonusPct .. "%)", fontSize = 12, fontColor = bonusColor },
                            UI.Label { text = bonusSign .. bonus, fontSize = 13, fontColor = bonusColor, fontWeight = "bold" },
                        }},
                        UI.Label { text = "你 " .. (r.cafeScore or 0) .. " vs 对手 " .. (r.npcCafeScore or 0), fontSize = 11, fontColor = C.textDim, textAlign = "center", width = "100%" },
                        -- 分隔线
                        UI.Panel { width = "100%", height = 1, backgroundColor = C.border },
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
                    text = "下一轮 →", width = 200, minHeight = 44, fontSize = 16,
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
            local mLabel = (modeEmojis)[m] or "?"
            -- 简化判定：前 challengePlayerWins_ 轮算赢
            local roundWon = (i <= (challengePlayerWins_ + challengeNPCWins_))
            table.insert(roundReview, UI.Label {
                text = mLabel .. " R" .. i .. " " .. ((modeLabels)[m] or m),
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
                    backgroundColor = C.card,
                    borderRadius = PX.cardRadius, borderWidth = PX.border,
                    borderColor = won and C.gold or C.red,
                    alignItems = "center",
                    children = {
                        -- 标题
                        UI.Label { text = won and "踢馆成功！" or "踢馆失败", fontSize = 24, fontColor = won and C.gold or C.red, fontWeight = "bold" },
                        UI.Label { text = "vs " .. (opp.emoji or "") .. " " .. (opp.name or ""), fontSize = 14, fontColor = C.textDim },

                        -- 最终比分
                        UI.Panel {
                            width = "100%", padding = 10, backgroundColor = { 40, 50, 40, 180 }, borderRadius = 10,
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
                        UI.Panel { width = "90%", height = 1, backgroundColor = C.border },

                        -- 收益明细标题
                        UI.Label { text = won and "收益明细" or "损失明细", fontSize = 15, fontColor = C.gold, fontWeight = "bold" },

                        -- 收益明细列表
                        UI.Panel {
                            width = "100%", padding = 10, backgroundColor = C.cardAlt, borderRadius = 10,
                            gap = 2,
                            children = earningsChildren,
                        },

                        -- 赌注信息
                        UI.Label { text = "赌注：" .. wagerLabel .. "  |  倍率：×" .. mult, fontSize = 12, fontColor = C.textDim },

                        -- 确认按钮
                        UI.Button {
                            text = "确认收益", width = 220, minHeight = 46, fontSize = 16,
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

