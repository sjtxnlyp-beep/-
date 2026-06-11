---@diagnostic disable: undefined-global
--- 铁壁网吧：负面事件金钱损失减半
function ApplyIronFortress(moneyBefore)
    if HasIronFortress() and playerData_.money < moneyBefore then
        local loss = moneyBefore - playerData_.money
        local refund = math.floor(loss / 2)
        playerData_.money = playerData_.money + refund
        AddLog("🛡️ 铁壁网吧防护！减损 $" .. refund)
    end
end

--- 每4天强制触发NPC事件，优先选择未遇见的NPC相关事件
function ForceNpcEvent()
    -- 收集未遇见的 NPC ID
    local unmetNpcs = {}
    for _, prof in ipairs(NPC_PROFILES) do
        if not npcJournal_[prof.id] then unmetNpcs[prof.id] = true end
    end
    if not next(unmetNpcs) then return false end  -- 所有NPC都已遇见

    -- 从 NPC 事件池中选取满足条件的事件
    local npcEvents = {}
    for _, e in ipairs(RANDOM_EVENTS) do
        local npcIds = EVENT_NPC_MAP[e.title]
        if npcIds then
            local ids = type(npcIds) == "string" and { npcIds } or npcIds
            for _, nid in ipairs(ids) do
                if unmetNpcs[nid] then
                    if not e.cond then
                        table.insert(npcEvents, e); break
                    else
                        local ok, val = pcall(e.cond)
                        if ok and val then table.insert(npcEvents, e); break end
                    end
                end
            end
        end
    end
    if #npcEvents == 0 then return false end

    -- 随机选一个触发（走正常的事件阶段 UI，与 TriggerRandomEvent 一致）
    local evt = npcEvents[math.random(1, #npcEvents)]
    PlaySFX("event")
    RecordNPCEncounter(evt.title)
    if evt.type == "auto" then
        local moneyBefore = playerData_.money
        if evt.effect then
            local ok2, err2 = pcall(evt.effect)
            if not ok2 then
                log:Write(LOG_ERROR, "[ForceNpcEvent] effect error: " .. tostring(err2))
            end
        end
        ApplyIronFortress(moneyBefore)
        AddLog((evt.icon or "📌") .. " " .. (evt.title or "事件") .. ": " .. (evt.result or ""))
        playerData_.money = math.max(0, playerData_.money)
        BuildUI()
    else
        -- choice 类型：切换到事件阶段，由 BuildEventUI 渲染选项
        currentEvent_ = evt
        currentPhase_ = PHASE_EVENT
        PlayBGM("event")
        BuildUI()
    end
    return true
end

function TriggerRandomEvent()
    PlaySFX("event")

    -- ====== NPC 事件优先机制 ======
    -- 40% 概率尝试优先触发「与未遇见 NPC 相关」的事件，提高解锁率
    local evt
    local tryNpcFirst = math.random() < 0.60
    if tryNpcFirst then
        -- 收集未遇见的 NPC ID
        local unmetNpcs = {}
        for _, prof in ipairs(NPC_PROFILES) do
            if not npcJournal_[prof.id] then unmetNpcs[prof.id] = true end
        end
        -- 如果有未遇见的 NPC，从 NPC 事件池中优先选取
        if next(unmetNpcs) then
            local npcEvents = {}
            for _, e in ipairs(RANDOM_EVENTS) do
                local npcIds = EVENT_NPC_MAP[e.title]
                if npcIds then
                    local ids = type(npcIds) == "string" and { npcIds } or npcIds
                    for _, nid in ipairs(ids) do
                        if unmetNpcs[nid] then
                            -- 检查条件是否满足
                            if not e.cond then
                                table.insert(npcEvents, e); break
                            else
                                local ok, val = pcall(e.cond)
                                if ok and val then table.insert(npcEvents, e); break end
                            end
                        end
                    end
                end
            end
            if #npcEvents > 0 then
                evt = npcEvents[math.random(1, #npcEvents)]
            end
        end
    end

    -- ====== 常规随机选取（备选路径或 60% 概率直接走这里）======
    if not evt then
        for _ = 1, 10 do
            local idx = math.random(1, #RANDOM_EVENTS)
            local candidate = RANDOM_EVENTS[idx]
            if not candidate.cond then
                evt = candidate; break
            else
                local cOk, cVal = pcall(candidate.cond)
                if not cOk then
                    log:Write(LOG_ERROR, "[RandomEvent] cond error: " .. tostring(cVal))
                elseif cVal then
                    evt = candidate; break
                end
            end
        end
    end
    if not evt then
        -- 所有尝试都不满足条件，回退到第一个无条件事件
        for _, e in ipairs(RANDOM_EVENTS) do
            if not e.cond then evt = e; break end
        end
    end
    if not evt then
        -- 极端保底：无可用事件，直接回管理界面
        BuildUI()
        return
    end
    if evt.type == "auto" then
        local moneyBefore = playerData_.money
        if evt.effect then
            local ok2, err2 = pcall(evt.effect)
            if not ok2 then
                log:Write(LOG_ERROR, "[TriggerRandomEvent] effect error: " .. tostring(err2))
            end
        end
        ApplyIronFortress(moneyBefore)
        AddLog((evt.icon or "📌") .. " " .. (evt.title or "事件") .. ": " .. (evt.result or ""))
        RecordNPCEncounter(evt.title)
        playerData_.money = math.max(0, playerData_.money)
        BuildUI()
    else
        currentEvent_ = evt
        currentPhase_ = PHASE_EVENT; PlayBGM("event"); BuildUI()
    end
end

function TriggerRecruitEvent()
    if #CANDIDATE_POOL == 0 then BuildUI(); return end
    PlaySFX("recruit")
    local idx = math.random(1, #CANDIDATE_POOL)
    local c = CANDIDATE_POOL[idx]

    local pronoun = (c.emoji == "👩🏿") and "她" or "他"
    local descText = ""

    if c.special and c.story then
        -- 特殊角色：展示专属剧情
        descText = c.story .. "\n\n" .. c.desc .. "。"
    else
        local introTexts = {
            "一个人推开了网吧的门，好奇地四处张望。你注意到" .. pronoun .. "盯着屏幕里的三角洲画面，眼睛里闪着光。",
            "门外传来一阵争吵。一个叫 " .. c.name .. " 的年轻人正在跟朋友争论跑刀战术，说得头头是道。你走出去搭了句话。",
            "常客介绍了一个叫 " .. c.name .. " 的人来网吧。据说" .. pronoun .. "在附近小有名气——'那个跑刀超猛的人'。",
        }
        descText = introTexts[math.random(1, #introTexts)] .. "\n\n你让" .. pronoun .. "坐下来打了一局——" .. c.desc .. "。"
    end

    currentEvent_ = {
        type = "recruit",
        title = c.special and ("特殊人物: " .. c.name) or "有人来了！",
        icon = c.emoji,
        desc = descText,
        candidate = c,
    }
    currentPhase_ = PHASE_EVENT; BuildUI()
end

--- 消耗行动点数，不够则返回false
