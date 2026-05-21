---@diagnostic disable: undefined-global
-- ============================================================================
-- 排行榜页面：地区网吧排行榜 + 三角洲战斗分数排行榜
-- ============================================================================

--- 计算玩家网吧综合评分
--- 口径：设备数×10 + 座椅等级×8 + 网速等级×12 + 空调×6 + 太阳能×5
---       + 餐饮×7 + 装饰×4 + 安保×6 + 发电机×5
---       + 社区投资(水井×8 + 道路×8) + 文化空间(咖啡×6 + 点唱机×4)
---       + 声望/5 + 分店数×20
function CalcCafeScore()
    local p = playerData_
    local score = p.computers * 10
        + (p.chairLevel - 1) * 8
        + (p.netSpeed - 1) * 12
        + p.acLevel * 6
        + p.solarLevel * 5
        + p.foodShop * 7
        + p.decoLevel * 4
        + p.securityLevel * 6
        + p.generatorLevel * 5
        + (p.wellLevel or 0) * 8
        + (p.roadLevel or 0) * 8
        + (p.coffeeLevel or 0) * 6
        + (p.jukeboxLevel or 0) * 4
        + math.floor(p.reputation / 5)
        + #(p.branches or {}) * 20
    -- 队伍技能对网吧评分的贡献（训练队员 = 提升排名）
    for _, m in ipairs(teamMembers_) do
        score = score + math.floor(m.skill * 0.3)
    end
    return score
end

--- 生成 NPC 网吧排行数据（基于玩家当前天数做种子，保持同一天内稳定）
function GetCafeRankingData()
    local day = playerData_.day or 1
    local seed = day * 137  -- 简单种子确保同一天数据一致

    local NPC_CAFES = {
        { name = "Gold Net Cafe",     loc = "拉各斯",     emoji = "🇳🇬", owner = "Victor",   style = "土豪砸钱型" },
        { name = "Safari Online",     loc = "内罗毕",     emoji = "🇰🇪", owner = "Amina",    style = "技术流" },
        { name = "Cape Connect",      loc = "开普敦",     emoji = "🇿🇦", owner = "Johan",    style = "高端商务" },
        { name = "Oasis Gaming",      loc = "阿克拉",     emoji = "🇬🇭", owner = "Kwadwo",   style = "社区温馨" },
        { name = "Nile Net Station",  loc = "开罗",       emoji = "🇪🇬", owner = "Hassan",   style = "历史悠久" },
        { name = "Sahara Cyber",      loc = "达喀尔",     emoji = "🇸🇳", owner = "Ousmane",  style = "法语区霸主" },
        { name = "Kilimanjaro Hub",   loc = "达累斯萨拉姆", emoji = "🇹🇿", owner = "Baraka",  style = "稳扎稳打" },
        { name = "Lion's Den Cafe",   loc = "亚的斯亚贝巴", emoji = "🇪🇹", owner = "Tekle",   style = "咖啡文化" },
        { name = "Thunder Net",       loc = "金沙萨",     emoji = "🇨🇩", owner = "Mobutu Jr", style = "野路子" },
        { name = "Baobab Bytes",      loc = "马普托",     emoji = "🇲🇿", owner = "Carlos",   style = "新兴势力" },
        { name = "Pharaoh Gaming",    loc = "亚历山大",   emoji = "🇪🇬", owner = "Youssef",  style = "电竞专精" },
        { name = "Ubuntu Cafe",       loc = "约翰内斯堡", emoji = "🇿🇦", owner = "Thabo",    style = "公益型" },
    }

    -- NPC 网吧分数锚定玩家分数（玩家越强 NPC 也越强，但差距可控）
    local playerScore = CalcCafeScore()
    local anchor = math.max(playerScore, 60)
    -- 各 NPC 的实力倍率（保持原有相对强弱）
    local npcMults = { 1.25, 0.90, 1.15, 0.70, 1.05, 0.80, 0.63, 0.85, 0.55, 0.50, 1.10, 0.73 }

    local entries = {}
    for i, cafe in ipairs(NPC_CAFES) do
        local mult = npcMults[i] or 0.80
        -- 用 seed + 索引 做伪随机抖动（每天轻微波动）
        local jitter = ((seed + i * 31) % 20) - 10
        local score = math.max(20 + i, math.floor(anchor * mult) + jitter)
        -- 口径数据：人数 = 分数/8，设备 = 分数/12
        local people = math.max(5, math.floor(score / 8) + ((seed + i * 17) % 5))
        local equip  = math.max(3, math.floor(score / 12) + ((seed + i * 7) % 3))
        table.insert(entries, {
            name = cafe.name,
            loc = cafe.loc,
            emoji = cafe.emoji,
            owner = cafe.owner,
            style = cafe.style,
            score = score,
            people = people,
            equip = equip,
        })
    end

    -- 加入玩家自己的网吧（复用上方已算的 playerScore）
    table.insert(entries, {
        name = playerData_.cafeName or "Dragon Net Cafe",
        loc = "本地",
        emoji = "",
        owner = "你",
        style = "传奇崛起",
        score = playerScore,
        people = math.max(1, playerData_.computers or 3),
        equip = (playerData_.computers or 3) + (playerData_.chairLevel or 1) + (playerData_.netSpeed or 1),
        isPlayer = true,
    })

    -- 按分数降序排列
    table.sort(entries, function(a, b) return a.score > b.score end)

    -- 找到玩家排名
    local playerRank = 1
    for i, e in ipairs(entries) do
        if e.isPlayer then playerRank = i; break end
    end

    return entries, playerRank
end

--- 生成三角洲战斗分数排行数据
function GetCombatRankingData()
    local day = playerData_.day or 1
    local seed = day * 251

    local WORLD_PLAYERS = {
        { name = "NiKo",          region = "🇧🇦 波黑",     title = "世界冠军",   tier = "S" },
        { name = "s1mple",        region = "🇺🇦 乌克兰",   title = "传奇狙神",   tier = "S" },
        { name = "ZywOo",         region = "🇫🇷 法国",     title = "欧洲天才",   tier = "S" },
        { name = "donk",          region = "🇷🇺 俄罗斯",   title = "新生代怪物", tier = "S" },
        { name = "ropz",          region = "🇪🇪 爱沙尼亚", title = "步枪大师",   tier = "A" },
        { name = "m0NESY",        region = "🇷🇺 俄罗斯",   title = "AWP新星",    tier = "A" },
        { name = "broky",         region = "🇱🇻 拉脱维亚", title = "稳定输出",   tier = "A" },
        { name = "rain",          region = "🇳🇴 挪威",     title = "老将",       tier = "A" },
        { name = "AfricanHawk",   region = "🇰🇪 肯尼亚",   title = "非洲之鹰",   tier = "B" },
        { name = "NileSniper",    region = "🇪🇬 埃及",     title = "尼罗河之眼", tier = "B" },
        { name = "VictorGold",    region = "🇳🇬 拉各斯",   title = "黄金战队",   tier = "B" },
        { name = "SaharaShadow",  region = "🇸🇳 塞内加尔", title = "沙漠幽影",   tier = "B" },
    }

    -- NPC 战力锚定玩家战力（玩家越强 NPC 也越强，排名始终有追赶动力）
    local playerPower = GetTeamPower()
    local anchor = math.max(playerPower, 80)
    -- 各 NPC 的实力倍率：S 级 1.3-1.5x，A 级 1.0-1.15x，B 级 0.6-0.8x
    local npcMults = { 1.50, 1.43, 1.36, 1.30, 1.15, 1.10, 1.05, 1.00, 0.80, 0.72, 0.65, 0.55 }
    -- 基础底分确保早期 NPC 不会太弱
    local npcBases = { 80, 65, 55, 45, 30, 25, 20, 15, 10, 8, 5, 3 }

    local entries = {}
    for i, p in ipairs(WORLD_PLAYERS) do
        -- 每天轻微波动
        local jitter = ((seed + i * 43) % 30) - 15
        local npcScore = math.max(50, math.floor(anchor * npcMults[i] + npcBases[i]) + jitter)
        table.insert(entries, {
            name = p.name,
            region = p.region,
            title = p.title,
            tier = p.tier,
            score = npcScore,
            isPlayer = false,
        })
    end

    -- 加入玩家战队（复用上方已算的 playerPower）
    table.insert(entries, {
        name = "Dragon Force",
        region = "本地",
        title = #teamMembers_ >= 5 and "非洲新星" or (#teamMembers_ >= 3 and "崛起中" or "初出茅庐"),
        tier = playerPower >= 350 and "S" or (playerPower >= 200 and "A" or (playerPower >= 100 and "B" or "C")),
        score = playerPower,
        isPlayer = true,
    })

    table.sort(entries, function(a, b) return a.score > b.score end)

    local playerRank = 1
    for i, e in ipairs(entries) do
        if e.isPlayer then playerRank = i; break end
    end

    return entries, playerRank
end

function BuildRankingPage()
    -- 排行榜子 tab 状态
    if not rankingSubTab_ then rankingSubTab_ = "cafe" end

    local subTabBar = UI.Panel {
        width = "100%", flexDirection = "row", gap = 4, paddingHorizontal = 4, paddingBottom = 6,
        children = {
            UI.Button {
                text = "网吧排行", fontSize = 13, height = 32, flex = 1,
                fontWeight = rankingSubTab_ == "cafe" and "bold" or "normal",
                backgroundColor = rankingSubTab_ == "cafe" and C.accent or C.cardAlt,
                fontColor = rankingSubTab_ == "cafe" and { 255, 255, 255, 255 } or C.textDim,
                borderRadius = 8,
                borderWidth = rankingSubTab_ == "cafe" and 0 or 1,
                borderColor = C.border,
                onClick = function()
                    rankingSubTab_ = "cafe"
                    BuildUI()
                end,
            },
            UI.Button {
                text = "战斗排行", fontSize = 13, height = 32, flex = 1,
                fontWeight = rankingSubTab_ == "combat" and "bold" or "normal",
                backgroundColor = rankingSubTab_ == "combat" and C.accent or C.cardAlt,
                fontColor = rankingSubTab_ == "combat" and { 255, 255, 255, 255 } or C.textDim,
                borderRadius = 8,
                borderWidth = rankingSubTab_ == "combat" and 0 or 1,
                borderColor = C.border,
                onClick = function()
                    rankingSubTab_ = "combat"
                    BuildUI()
                end,
            },
        },
    }

    local content
    if rankingSubTab_ == "cafe" then
        content = BuildCafeRankingContent()
    else
        content = BuildCombatRankingContent()
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 6,
        backgroundColor = C.card, borderRadius = 12,
        borderWidth = 1, borderColor = C.border,
        children = {
            UI.Label { text = "排行榜", fontSize = 18, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" },
            subTabBar,
            content,
        },
    }
end

function BuildCafeRankingContent()
    local entries, playerRank = GetCafeRankingData()

    local children = {}

    -- ⚔️ 踢馆参与条件说明
    local day = playerData_.day or 1
    local teamCount = #teamMembers_
    local ap = playerData_.actionPoints or 0
    local alreadyChallenged = (challengeDay_ == day)

    -- 各条件状态
    local hasTeam = teamCount >= 1
    local hasAP = ap >= 1
    local canChallenge = hasTeam and hasAP and (not alreadyChallenged)

    local function CondIcon(ok) return ok and "●" or "○" end
    local function CondColor(ok) return ok and C.green or C.red end

    table.insert(children, UI.Panel {
        width = "100%", padding = 10, backgroundColor = C.cardAlt, borderRadius = 10,
        borderWidth = 1, borderColor = canChallenge and { C.green[1], C.green[2], C.green[3], 80 } or { C.red[1], C.red[2], C.red[3], 80 },
        gap = 6,
        children = {
            PanelHeader("踢馆挑战条件", { compact = true, color = C.gold }),
            UI.Panel { flexDirection = "row", gap = 12, flexWrap = "wrap", width = "100%", children = {
                UI.Label { text = CondIcon(hasTeam) .. " 至少1名队员 (" .. teamCount .. "人)", fontSize = 12, fontColor = CondColor(hasTeam) },
                UI.Label { text = CondIcon(hasAP) .. " 消耗1行动点 (剩" .. ap .. ")", fontSize = 12, fontColor = CondColor(hasAP) },
                UI.Label { text = CondIcon(not alreadyChallenged) .. " 每日限1次", fontSize = 12, fontColor = CondColor(not alreadyChallenged) },
            }},
            (not canChallenge) and UI.Label {
                text = not hasTeam and "先去「招募」页面招募队员！"
                    or alreadyChallenged and "今天已踢过馆，明天再来！"
                    or "行动点不足，请结束当天或使用道具恢复",
                fontSize = 11, fontColor = C.textDim, whiteSpace = "normal",
            } or nil,
        },
    })

    -- 数据口径说明
    table.insert(children, UI.Panel {
        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = 8,
        children = {
            UI.Label {
                text = "综合评分口径：设备数量×10 + 设施等级加权 + 社区投资×8 + 声望÷5 + 分店×20",
                fontSize = 11, fontColor = C.textLight, whiteSpace = "normal", lineHeight = 1.4,
            },
        },
    })

    -- 玩家排名高亮
    table.insert(children, UI.Panel {
        width = "100%", padding = 10, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, borderRadius = 10,
        borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
        flexDirection = "row", alignItems = "center", gap = 8,
        children = {
            UI.Label { text = "#" .. playerRank, fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Label { text = (playerData_.cafeName or "Dragon Net Cafe"), fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
                UI.Label { text = "综合分 " .. CalcCafeScore() .. "  |  共 " .. #entries .. " 家", fontSize = 12, fontColor = C.text },
            }},
        },
    })

    -- 排行列表
    for i, e in ipairs(entries) do
        if i > 10 and not e.isPlayer then break end  -- 只显示前10 + 玩家

        local rankIcon = ({ "1st", "2nd", "3rd" })[i] or ("#" .. i)
        local bgColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 25 } or (i % 2 == 0 and C.cardAlt or { C.bg[1], C.bg[2], C.bg[3], 220 })
        local nameColor = e.isPlayer and C.accent or C.text
        local borderCol = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 80 } or { 0, 0, 0, 0 }

        table.insert(children, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = bgColor, borderRadius = 8,
            borderWidth = e.isPlayer and 1 or 0, borderColor = borderCol,
            children = {
                UI.Label { text = tostring(rankIcon), fontSize = 14, width = 30, textAlign = "center" },
                UI.Label { text = (e.emoji and e.emoji ~= "") and e.emoji or "🏪", fontSize = 16, width = 24 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = e.name .. (e.isPlayer and " (你)" or ""), fontSize = 13, fontColor = nameColor, fontWeight = e.isPlayer and "bold" or "normal" },
                    UI.Label { text = e.loc .. " · " .. e.style .. " · " .. e.people .. " " .. e.equip, fontSize = 11, fontColor = C.textDim },
                }},
                UI.Label { text = tostring(e.score), fontSize = 14, fontColor = C.gold, fontWeight = "bold", width = 40, textAlign = "right" },
                -- 踢馆按钮（条件不满足时禁用并给出提示）
                (not e.isPlayer) and UI.Button {
                    text = "挑战", fontSize = 11, width = 36, height = 30,
                    variant = canChallenge and "secondary" or "ghost", paddingHorizontal = 0,
                    fontColor = canChallenge and nil or { 180, 165, 145, 130 },
                    onClick = function()
                        if not canChallenge then
                            local reason = not hasTeam and "至少需要1名队员才能踢馆！\n请先去「招募」页面招募队员。"
                                or alreadyChallenged and "今天已经踢过馆了，明天再来吧！"
                                or "行动点不足，无法踢馆！"
                            ShowChallengeBlockedPopup(reason)
                            return
                        end
                        StartCafeChallenge(e)
                    end,
                } or nil,
            },
        })
    end

    -- 如果玩家不在前10，用省略号连接
    if playerRank > 10 then
        table.insert(children, UI.Label { text = "···", fontSize = 16, fontColor = C.textDim, textAlign = "center", width = "100%" })
    end

    return UI.Panel { width = "100%", gap = 4, children = children }
end

function BuildCombatRankingContent()
    local entries, playerRank = GetCombatRankingData()

    local children = {}

    -- 顶部说明
    table.insert(children, UI.Panel {
        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = 8,
        children = {
            UI.Label {
                text = "三角洲行动全球战力排名  |  战力 = 天赋×0.4 + 技术×0.5 + 心情×0.1 + 特质修正",
                fontSize = 11, fontColor = C.textLight, whiteSpace = "normal", lineHeight = 1.4,
            },
        },
    })

    -- 玩家排名 + 与冠军差距
    local topScore = entries[1] and entries[1].score or 999
    local playerScore = GetTeamPower()
    local gap = topScore - playerScore
    local gapText = gap > 0 and ("距世界冠军差 " .. gap .. " 分") or "你已是世界之巅！"
    local gapColor = gap > 300 and { 255, 100, 100, 255 } or (gap > 100 and { 255, 200, 100, 255 } or { 100, 255, 150, 255 })

    table.insert(children, UI.Panel {
        width = "100%", padding = 10, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, borderRadius = 10,
        borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
        gap = 4,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, width = "100%", children = {
                UI.Label { text = "#" .. playerRank, fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "Dragon Force 战队", fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label { text = "战力 " .. playerScore .. "  |  排名 #" .. playerRank .. " / " .. #entries, fontSize = 12, fontColor = C.text },
                }},
            }},
            UI.Label { text = gapText, fontSize = 13, fontColor = gapColor, textAlign = "center", width = "100%" },
        },
    })

    -- 排行列表
    for i, e in ipairs(entries) do
        if i > 10 and not e.isPlayer then break end

        local rankIcon = ({ "1st", "2nd", "3rd" })[i] or ("#" .. i)
        local tierColors = {
            S = { 255, 215, 50, 255 },
            A = { 200, 140, 60, 255 },
            B = { 100, 160, 200, 255 },
            C = { 150, 150, 150, 255 },
        }
        local bgColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 25 } or (i % 2 == 0 and C.cardAlt or { C.bg[1], C.bg[2], C.bg[3], 220 })
        local nameColor = e.isPlayer and C.accent or C.text

        table.insert(children, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = bgColor, borderRadius = 8,
            borderWidth = e.isPlayer and 1 or 0, borderColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 80 } or { 0, 0, 0, 0 },
            children = {
                UI.Label { text = tostring(rankIcon), fontSize = 14, width = 30, textAlign = "center" },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = e.name .. (e.isPlayer and " (你)" or ""), fontSize = 13, fontColor = nameColor, fontWeight = (i <= 3 or e.isPlayer) and "bold" or "normal" },
                    UI.Label { text = e.region .. " · " .. e.title, fontSize = 11, fontColor = C.textDim },
                }},
                UI.Label { text = "[" .. e.tier .. "]", fontSize = 12, fontColor = tierColors[e.tier] or C.textDim, width = 24 },
                UI.Label { text = tostring(e.score), fontSize = 14, fontColor = C.gold, fontWeight = "bold", width = 40, textAlign = "right" },
            },
        })
    end

    if playerRank > 10 then
        table.insert(children, UI.Label { text = "···", fontSize = 16, fontColor = C.textDim, textAlign = "center", width = "100%" })
    end

    return UI.Panel { width = "100%", gap = 4, children = children }
end

-- InfoRow 已在 GameState.lua 全局定义

--- 获取成就的当前进度 (current, target)
local function GetAchievementProgress(id)
    if id == "first_recruit" then return math.min(#teamMembers_, 1), 1
    elseif id == "full_team" then return math.min(#teamMembers_, 5), 5
    elseif id == "rich" then return math.min(playerData_.money or 0, 3000), 3000
    elseif id == "famous" then return math.min(playerData_.reputation or 0, 200), 200
    elseif id == "first_friendly" then
        local t = (playerData_.friendlyWins or 0) + (playerData_.friendlyLosses or 0)
        return math.min(t, 1), 1
    elseif id == "friendly_5wins" then return math.min(playerData_.friendlyWins or 0, 5), 5
    elseif id == "synergy_first" then return math.min(#(CalcUpgradeSynergies()), 1), 1
    elseif id == "synergy_3" then return math.min(#(CalcUpgradeSynergies()), 3), 3
    elseif id == "havoc_300" then return math.min(playerData_.havocCoins or 0, 300), 300
    elseif id == "day_30" then return math.min(playerData_.day or 0, 30), 30
    elseif id == "karma_saint" then return math.max(0, math.min(playerData_.karma or 0, 10)), 10
    elseif id == "karma_dark" then
        -- karma 越低越接近目标，用负值转正
        local v = -(playerData_.karma or 0)
        return math.max(0, math.min(v, 8)), 8
    elseif id == "iron_fortress" then return HasIronFortress() and 1 or 0, 1
    elseif id == "max_upgrade" then
        local best = math.max(playerData_.chairLevel or 0, playerData_.netSpeed or 0, playerData_.acLevel or 0)
        -- chairLevel/netSpeed max=4, acLevel max=3, computers max=12
        local compProg = math.floor((playerData_.computers or 4) / 12 * 4)
        best = math.max(best, compProg)
        return math.min(best, 4), 4
    end
    return 0, 1
end

function BuildAchievementCard()
    local unlocked = GetUnlockedCount()
    local total = #ACHIEVEMENTS

    local achChildren = {}
    -- 顶部总览
    table.insert(achChildren, UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
        UI.Label { text = "成就墙 " .. unlocked .. "/" .. total, fontSize = 15, fontColor = C.gold, fontWeight = "bold" },
        UI.Panel { flex = 1, height = 8, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = 4, overflow = "hidden", children = {
            UI.Panel { width = (total > 0 and math.floor(unlocked / total * 100) or 0) .. "%", height = "100%", backgroundColor = C.gold, borderRadius = 4 },
        }},
    }})

    -- 全部成就列表
    for _, ach in ipairs(ACHIEVEMENTS) do
        local done = unlockedAchievements_[ach.id] == true
        local cur, tgt = GetAchievementProgress(ach.id)
        local pct = tgt > 0 and math.floor(cur / tgt * 100) or 0
        if done then pct = 100 end

        local statusIcon = done and "●" or "○"
        local nameColor = done and C.gold or { 130, 130, 130, 255 }
        local descColor = done and { C.accent[1], C.accent[2], C.accent[3], 255 } or { 130, 130, 130, 255 }
        local barBg = done and { C.border[1], C.border[2], C.border[3], 120 } or { C.border[1], C.border[2], C.border[3], 100 }
        local barFg = done and C.gold or C.textDim
        local borderCol = done and { C.gold[1], C.gold[2], C.gold[3], 160 } or { C.border[1], C.border[2], C.border[3], 160 }
        local bgCol = done and { C.gold[1], C.gold[2], C.gold[3], 20 } or C.cardAlt

        table.insert(achChildren, UI.Panel {
            width = "100%", padding = 8, gap = 3,
            backgroundColor = bgCol, borderRadius = 8, borderWidth = 1, borderColor = borderCol,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, children = {
                    UI.Label { text = statusIcon, fontSize = 14 },
                    UI.Label { text = ach.name, fontSize = 13, fontColor = nameColor, fontWeight = done and "bold" or "normal", flex = 1 },
                    UI.Label { text = done and "已达成" or (cur .. "/" .. tgt), fontSize = 11, fontColor = descColor },
                }},
                UI.Label { text = ach.desc, fontSize = 11, fontColor = descColor, whiteSpace = "normal" },
                -- 迷你进度条
                UI.Panel { width = "100%", height = 4, backgroundColor = barBg, borderRadius = 2, overflow = "hidden", children = {
                    UI.Panel { width = pct .. "%", height = "100%", backgroundColor = barFg, borderRadius = 2 },
                }},
            },
        })
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = 12, borderWidth = 1, borderColor = { C.border[1], C.border[2], C.border[3], 120 },
        boxShadow = { { x = 0, y = 4, blur = 16, color = { 0, 0, 0, 50 } } },
        children = achChildren,
    }
end

-- ============================================================================
-- 踢馆条件不满足时的提示弹窗
-- ============================================================================
function ShowChallengeBlockedPopup(reason)
    PlaySFX("fail")
    challengeBlockedPopup_ = reason
    BuildUI()
end

function BuildChallengeBlockedPopup()
    if not challengeBlockedPopup_ then return nil end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 140 },
        justifyContent = "center", alignItems = "center",
        onClick = function()
            challengeBlockedPopup_ = nil; BuildUI()
        end,
        children = {
            UI.Panel {
                width = "85%", maxWidth = 360, padding = 20, gap = 12,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = { C.border[1], C.border[2], C.border[3], 200 },
                alignItems = "center",
                boxShadow = { { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 80 } } },
                children = {
                    UI.Label { text = "⚠️ 无法踢馆", fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label { text = challengeBlockedPopup_, fontSize = 14, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, textAlign = "center", width = "100%" },
                    UI.Button {
                        text = "知道了", width = 140, height = 38, fontSize = 14,
                        variant = "primary",
                        onClick = function()
                            challengeBlockedPopup_ = nil; BuildUI()
                        end,
                    },
                },
            },
        },
    }
end

