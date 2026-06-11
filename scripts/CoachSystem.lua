-- ============================================================================
-- CoachSystem.lua — P2: 教练雇佣系统
-- 提供中后期(D14+)队员成长加速 + 情感羁绊 + 每日开支
-- ============================================================================

local CoachSystem = {}

-- ── 教练定义 ──
CoachSystem.COACHES = {
    {
        id = "chen",
        name = "陈教练",
        icon = "🎯",
        title = "退役职业选手（中国）",
        desc = "前中国职业战队主力，因伤退役后辗转来到非洲。训练严格但有效。",
        dailyCost = 40,
        skillBoost = 3,        -- 每日全队技能+3
        moodEffect = -2,       -- 每日心情-2（训练辛苦）
        specialBonus = "crit",  -- 特殊加成：比赛暴击率
        critChance = 0.15,
        unlockDay = 14,
        unlockRep = 80,
    },
    {
        id = "kwame",
        name = "Coach K",
        icon = "🏋️",
        title = "本地体能教练",
        desc = "加纳退役足球运动员，转型电竞体能顾问。擅长心态调整和团队建设。",
        dailyCost = 25,
        skillBoost = 1,        -- 每日全队技能+1
        moodEffect = 5,        -- 每日心情+5（擅长鼓舞）
        specialBonus = "morale", -- 特殊加成：比赛前心态加成
        moraleBoost = 15,
        unlockDay = 10,
        unlockRep = 50,
    },
    {
        id = "maria",
        name = "Maria教练",
        icon = "📊",
        title = "数据分析师（尼日利亚）",
        desc = "拉各斯大学计算机硕士，专注比赛数据分析和战术优化。",
        dailyCost = 55,
        skillBoost = 2,        -- 每日全队技能+2
        moodEffect = 0,        -- 心情无变化
        specialBonus = "tactic", -- 特殊加成：战术分析
        tacticBonus = 0.20,     -- 比赛胜率+20%
        unlockDay = 20,
        unlockRep = 150,
    },
}

--- 获取教练定义
---@param coachId string
---@return table|nil
function CoachSystem.GetCoachDef(coachId)
    for _, c in ipairs(CoachSystem.COACHES) do
        if c.id == coachId then return c end
    end
    return nil
end

--- 获取当前雇佣的教练信息
---@return table|nil { coach定义 + hiredDay }
function CoachSystem.GetHiredCoach()
    local id = playerData_.hiredCoach
    if not id then return nil end
    local def = CoachSystem.GetCoachDef(id)
    if not def then return nil end
    return {
        id = def.id,
        name = def.name,
        icon = def.icon,
        title = def.title,
        desc = def.desc,
        dailyCost = def.dailyCost,
        skillBoost = def.skillBoost,
        moodEffect = def.moodEffect,
        specialBonus = def.specialBonus,
        hiredDay = playerData_.coachHiredDay or 0,
        daysWith = (playerData_.day or 0) - (playerData_.coachHiredDay or 0),
    }
end

--- 获取可雇佣教练列表
---@return table[] 可用教练(满足解锁条件的)
function CoachSystem.GetAvailableCoaches()
    local result = {}
    local day = playerData_.day or 0
    local rep = playerData_.reputation or 0
    for _, c in ipairs(CoachSystem.COACHES) do
        if day >= c.unlockDay and rep >= c.unlockRep then
            table.insert(result, c)
        end
    end
    return result
end

--- 雇佣教练
---@param coachId string
---@return boolean success
---@return string? errorMsg
function CoachSystem.Hire(coachId)
    local def = CoachSystem.GetCoachDef(coachId)
    if not def then return false, "教练不存在" end

    local day = playerData_.day or 0
    local rep = playerData_.reputation or 0
    if day < def.unlockDay or rep < def.unlockRep then
        return false, "未达到解锁条件"
    end

    -- 解雇原有教练（如果有）
    if playerData_.hiredCoach then
        CoachSystem.Fire()
    end

    playerData_.hiredCoach = coachId
    playerData_.coachHiredDay = day
    if AddLog then
        AddLog(string.format("%s 加入了Dragon Force教练组！", def.icon .. def.name))
    end
    return true
end

--- 解雇当前教练
function CoachSystem.Fire()
    local old = playerData_.hiredCoach
    if old then
        local def = CoachSystem.GetCoachDef(old)
        if def and AddLog then
            AddLog(string.format("👋 %s离开了教练组。", def.name))
        end
    end
    playerData_.hiredCoach = nil
    playerData_.coachHiredDay = nil
end

--- 获取教练每日开支
---@return number
function CoachSystem.GetDailyCost()
    local id = playerData_.hiredCoach
    if not id then return 0 end
    local def = CoachSystem.GetCoachDef(id)
    return def and def.dailyCost or 0
end

--- 获取教练对训练的加成
---@return number skillBoost, number moodEffect
function CoachSystem.GetTrainBoost()
    local id = playerData_.hiredCoach
    if not id then return 0, 0 end
    local def = CoachSystem.GetCoachDef(id)
    if not def then return 0, 0 end
    return def.skillBoost, def.moodEffect
end

--- 获取比赛加成
---@return table { critChance, moraleBoost, tacticBonus }
function CoachSystem.GetMatchBonus()
    local result = { critChance = 0, moraleBoost = 0, tacticBonus = 0 }
    local id = playerData_.hiredCoach
    if not id then return result end
    local def = CoachSystem.GetCoachDef(id)
    if not def then return result end

    if def.specialBonus == "crit" then
        result.critChance = def.critChance or 0
    elseif def.specialBonus == "morale" then
        result.moraleBoost = def.moraleBoost or 0
    elseif def.specialBonus == "tactic" then
        result.tacticBonus = def.tacticBonus or 0
    end
    return result
end

--- EndDay 中调用：处理教练每日效果
---@return number coachCost 今日教练开支
function CoachSystem.OnEndDay()
    local id = playerData_.hiredCoach
    if not id then return 0 end
    local def = CoachSystem.GetCoachDef(id)
    if not def then return 0 end

    -- 技能加成
    if def.skillBoost ~= 0 and teamMembers_ and #teamMembers_ > 0 then
        local SKILL_CAP = 150
        for _, m in ipairs(teamMembers_) do
            m.skill = math.min(SKILL_CAP, (m.skill or 0) + def.skillBoost)
        end
    end

    -- 心情效果
    if def.moodEffect ~= 0 and teamMembers_ and #teamMembers_ > 0 then
        for _, m in ipairs(teamMembers_) do
            m.mood = math.max(0, math.min(100, (m.mood or 50) + def.moodEffect))
        end
    end

    -- 扣除教练费用
    local cost = def.dailyCost
    playerData_.money = playerData_.money - cost

    -- 每周一日志提醒
    if (playerData_.day or 0) % 7 == 1 then
        if AddLog then
            AddLog(string.format("%s %s本周训练计划进行中（日薪$%d）",
                def.icon, def.name, cost))
        end
    end

    return cost
end

return CoachSystem
