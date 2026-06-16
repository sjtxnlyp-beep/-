---@diagnostic disable: undefined-global
-- ============================================================================
-- 排行榜页面：地区网吧排行榜 + 三角洲战斗分数排行榜
-- ============================================================================
local Achievements = require("Achievements")

--- 计算玩家网吧综合评分
--- 口径：设备数×10 + 座椅等级×8 + 网速等级×12 + 空调×6 + 太阳能×5
---       + 餐饮×7 + 装饰×4 + 安保×6 + 发电机×5
---       + 社区投资(水井×8 + 道路×8) + 文化空间(咖啡×6 + 点唱机×4)
---       + 声望/5 + 分店数×20
function CalcCafeScore()
    local p = playerData_
    if not p then return 0 end
    local score = (p.computers or 0) * 10
        + ((p.chairLevel or 1) - 1) * 8
        + ((p.netSpeed or 1) - 1) * 12
        + (p.acLevel or 0) * 6
        + (p.solarLevel or 0) * 5
        + (p.foodShop or 0) * 7
        + (p.decoLevel or 0) * 4
        + (p.securityLevel or 0) * 6
        + (p.generatorLevel or 0) * 5
        + (p.wellLevel or 0) * 8
        + (p.roadLevel or 0) * 8
        + (p.coffeeLevel or 0) * 6
        + (p.jukeboxLevel or 0) * 4
        + math.floor((p.reputation or 0) / 5)
        + #(p.branches or {}) * 20
    -- 队伍技能对网吧评分的贡献（训练队员 = 提升排名）
    for _, m in ipairs(teamMembers_ or {}) do
        score = score + math.floor((m.skill or 0) * 0.3)
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

    local function RankTabBtn(label, mode)
        local isActive = rankingSubTab_ == mode
        return UI.Button {
            text = label, fontSize = 13, height = 32, flex = 1,
            fontWeight = isActive and "bold" or "normal",
            backgroundColor = isActive and { 26, 18, 10, 255 } or { 40, 32, 22, 200 },
            fontColor = isActive and { 245, 215, 128, 255 } or C.textDim,
            borderRadius = PX.cardRadius, borderWidth = PX.border,
            borderColor = isActive and { 190, 148, 50, 240 } or { 60, 50, 38, 200 },
            onClick = function()
                rankingSubTab_ = mode; BuildUI()
            end,
        }
    end
    local subTabBar = UI.Panel {
        width = "100%", flexDirection = "row", gap = 4, paddingHorizontal = 4, paddingBottom = 6,
        children = {
            RankTabBtn("网吧排行", "cafe"),
            RankTabBtn("战斗排行", "combat"),
            RankTabBtn("周成长榜", "weekly"),
        },
    }

    local content
    if rankingSubTab_ == "cafe" then
        content = BuildCafeRankingContent()
    elseif rankingSubTab_ == "combat" then
        content = BuildCombatRankingContent()
    else
        content = BuildWeeklyRankingContent()
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = C.border,
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
        width = "100%", padding = 10, backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = canChallenge and { C.green[1], C.green[2], C.green[3], 80 } or { C.red[1], C.red[2], C.red[3], 80 },
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
        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
        children = {
            UI.Label {
                text = "综合评分口径：设备数量×10 + 设施等级加权 + 社区投资×8 + 声望÷5 + 分店×20",
                fontSize = 11, fontColor = C.textLight, whiteSpace = "normal", lineHeight = 1.4,
            },
        },
    })

    -- 玩家排名高亮
    table.insert(children, UI.Panel {
        width = "100%", padding = 10, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
        local nameColor = e.isPlayer and C.gold or C.text
        local borderCol = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 80 } or { 0, 0, 0, 0 }

        table.insert(children, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = bgColor, borderRadius = PX.cardRadius,
            borderWidth = e.isPlayer and PX.border or 0, borderColor = borderCol,
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
                    fontColor = (not canChallenge) and { 180, 165, 145, 130 } or nil,
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
        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
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
        width = "100%", padding = 10, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
        local nameColor = e.isPlayer and C.gold or C.text

        table.insert(children, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = bgColor, borderRadius = PX.cardRadius,
            borderWidth = e.isPlayer and PX.border or 0, borderColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 80 } or { 0, 0, 0, 0 },
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

-- ============================================================================
-- 3.1 周成长排行榜：基于5日周期的成长幅度对比
-- ============================================================================

--- 生成周成长排行数据（玩家 + NPC 的本周分数增幅对比）
function GetWeeklyGrowthData()
    local day = playerData_.day or 1
    local currentWeek = math.floor((day - 1) / 5) + 1
    local seed = currentWeek * 317

    -- 玩家当前分数
    local playerCafeNow = CalcCafeScore()
    -- 玩家上周分数（从 weeklyScores 取最近一条）
    local playerCafePrev = 0
    local ws = playerData_.weeklyScores or {}
    if #ws >= 1 then
        -- 最新记录就是上一个完整周期的快照
        playerCafePrev = ws[#ws].cafeScore or 0
    end
    -- 如果还没有上周数据（第一周），用当前50%估算起始
    if playerCafePrev == 0 and day <= 5 then
        playerCafePrev = math.max(10, math.floor(playerCafeNow * 0.5))
    end
    local playerGrowth = playerCafeNow - playerCafePrev
    local playerGrowthPct = playerCafePrev > 0 and math.floor(playerGrowth / playerCafePrev * 100) or 0

    -- NPC 网吧的周增长（基于锚定 + 随机波动）
    local NPC_WEEKLY = {
        { name = "Gold Net Cafe",     emoji = "🇳🇬", style = "土豪砸钱" },
        { name = "Safari Online",     emoji = "🇰🇪", style = "技术流" },
        { name = "Cape Connect",      emoji = "🇿🇦", style = "高端商务" },
        { name = "Oasis Gaming",      emoji = "🇬🇭", style = "社区温馨" },
        { name = "Nile Net Station",  emoji = "🇪🇬", style = "历史悠久" },
        { name = "Sahara Cyber",      emoji = "🇸🇳", style = "法语区霸主" },
        { name = "Kilimanjaro Hub",   emoji = "🇹🇿", style = "稳扎稳打" },
        { name = "Lion's Den Cafe",   emoji = "🇪🇹", style = "咖啡文化" },
        { name = "Thunder Net",       emoji = "🇨🇩", style = "野路子" },
        { name = "Baobab Bytes",      emoji = "🇲🇿", style = "新兴势力" },
        { name = "Pharaoh Gaming",    emoji = "🇪🇬", style = "电竞专精" },
        { name = "Ubuntu Cafe",       emoji = "🇿🇦", style = "公益型" },
    }
    -- NPC 增长率基准（每周期增长百分比），新兴势力增长快、老牌稳定
    local npcGrowthRates = { 8, 12, 6, 15, 5, 9, 10, 7, 18, 22, 11, 14 }

    local entries = {}
    for i, npc in ipairs(NPC_WEEKLY) do
        local baseRate = npcGrowthRates[i] or 10
        -- 加随机抖动 ±5%
        local jitter = ((seed + i * 53) % 11) - 5
        local growthPct = baseRate + jitter
        -- 用当前 anchor 估算 NPC 的绝对增长
        local anchor = math.max(CalcCafeScore(), 60)
        local npcMults = { 1.25, 0.90, 1.15, 0.70, 1.05, 0.80, 0.63, 0.85, 0.55, 0.50, 1.10, 0.73 }
        local mult = npcMults[i] or 0.80
        local npcScore = math.floor(anchor * mult)
        local npcGrowthAbs = math.max(2, math.floor(npcScore * growthPct / 100))

        table.insert(entries, {
            name = npc.name,
            emoji = npc.emoji,
            style = npc.style,
            growth = npcGrowthAbs,
            growthPct = growthPct,
            currentScore = npcScore,
            isPlayer = false,
        })
    end

    -- 加入玩家
    table.insert(entries, {
        name = playerData_.cafeName or "Dragon Net Cafe",
        emoji = "⭐",
        style = "传奇崛起",
        growth = playerGrowth,
        growthPct = playerGrowthPct,
        currentScore = playerCafeNow,
        isPlayer = true,
    })

    -- 按增长绝对值降序排列
    table.sort(entries, function(a, b) return a.growth > b.growth end)

    local playerRank = 1
    for i, e in ipairs(entries) do
        if e.isPlayer then playerRank = i; break end
    end

    return entries, playerRank, currentWeek
end

function BuildWeeklyRankingContent()
    local entries, playerRank, currentWeek = GetWeeklyGrowthData()
    local day = playerData_.day or 1
    local daysIntoWeek = ((day - 1) % 5) + 1
    local nextSettlement = 5 - daysIntoWeek + 1

    local children = {}

    -- 周期说明
    table.insert(children, UI.Panel {
        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
        gap = 4,
        children = {
            UI.Label {
                text = "📈 第" .. currentWeek .. "周成长排行  |  评估周期：每5天",
                fontSize = 12, fontColor = C.textLight, whiteSpace = "normal",
            },
            UI.Label {
                text = "本周期进度：" .. daysIntoWeek .. "/5天  |  " .. (nextSettlement > 0 and (nextSettlement .. "天后结算") or "今日结算"),
                fontSize = 11, fontColor = C.textDim,
            },
        },
    })

    -- 玩家本周增长概况
    local playerEntry = nil
    for _, e in ipairs(entries) do
        if e.isPlayer then playerEntry = e; break end
    end
    local growthColor = (playerEntry and playerEntry.growth > 0) and C.green or (playerEntry and playerEntry.growth < 0) and C.red or C.textDim
    local trendIcon = (playerEntry and playerEntry.growth > 0) and "📈" or (playerEntry and playerEntry.growth < 0) and "📉" or "➡️"

    table.insert(children, UI.Panel {
        width = "100%", padding = 10, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
        gap = 4,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, width = "100%", children = {
                UI.Label { text = "#" .. playerRank, fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = (playerData_.cafeName or "Dragon Net Cafe"), fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label { text = "当前评分 " .. (playerEntry and playerEntry.currentScore or 0) .. "  |  成长榜 #" .. playerRank, fontSize = 12, fontColor = C.text },
                }},
            }},
            UI.Panel { flexDirection = "row", justifyContent = "center", alignItems = "center", gap = 6, width = "100%", children = {
                UI.Label { text = trendIcon, fontSize = 16 },
                UI.Label {
                    text = "本周成长：" .. (playerEntry and playerEntry.growth > 0 and "+" or "") .. (playerEntry and playerEntry.growth or 0) .. " 分",
                    fontSize = 14, fontColor = growthColor, fontWeight = "bold",
                },
                UI.Label {
                    text = "(" .. (playerEntry and playerEntry.growthPct > 0 and "+" or "") .. (playerEntry and playerEntry.growthPct or 0) .. "%)",
                    fontSize = 12, fontColor = growthColor,
                },
            }},
        },
    })

    -- 排行列表（按成长幅度排序）
    for i, e in ipairs(entries) do
        if i > 10 and not e.isPlayer then break end

        local rankIcon = ({ "🥇", "🥈", "🥉" })[i] or ("#" .. i)
        local bgColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 25 } or (i % 2 == 0 and C.cardAlt or { C.bg[1], C.bg[2], C.bg[3], 220 })
        local nameColor = e.isPlayer and C.gold or C.text
        local gColor = e.growth > 0 and C.green or (e.growth < 0 and C.red or C.textDim)
        local arrow = e.growth > 0 and "↑" or (e.growth < 0 and "↓" or "→")

        table.insert(children, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = bgColor, borderRadius = PX.cardRadius,
            borderWidth = e.isPlayer and PX.border or 0, borderColor = e.isPlayer and { C.gold[1], C.gold[2], C.gold[3], 80 } or { 0, 0, 0, 0 },
            children = {
                UI.Label { text = tostring(rankIcon), fontSize = 14, width = 28, textAlign = "center" },
                UI.Label { text = e.emoji or "🏪", fontSize = 14, width = 20 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = e.name .. (e.isPlayer and " (你)" or ""), fontSize = 13, fontColor = nameColor, fontWeight = (i <= 3 or e.isPlayer) and "bold" or "normal" },
                    UI.Label { text = e.style .. "  |  当前" .. e.currentScore .. "分", fontSize = 11, fontColor = C.textDim },
                }},
                UI.Panel { alignItems = "flex-end", gap = 1, children = {
                    UI.Label { text = arrow .. (e.growth > 0 and "+" or "") .. e.growth, fontSize = 13, fontColor = gColor, fontWeight = "bold" },
                    UI.Label { text = (e.growthPct > 0 and "+" or "") .. e.growthPct .. "%", fontSize = 10, fontColor = gColor },
                }},
            },
        })
    end

    if playerRank > 10 then
        table.insert(children, UI.Label { text = "···", fontSize = 16, fontColor = C.textDim, textAlign = "center", width = "100%" })
    end

    -- 历史周表现（如果有多周数据）
    local ws = playerData_.weeklyScores or {}
    if #ws >= 2 then
        local histChildren = {}
        for i = #ws, math.max(1, #ws - 4), -1 do
            local rec = ws[i]
            local prevRec = ws[i - 1]
            local delta = prevRec and (rec.cafeScore - prevRec.cafeScore) or 0
            local deltaColor = delta > 0 and C.green or (delta < 0 and C.red or C.textDim)
            table.insert(histChildren, UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 4, width = "100%", paddingVertical = 3,
                children = {
                    UI.Label { text = "第" .. (rec.week or "?") .. "周", fontSize = 11, fontColor = C.textDim, width = 42 },
                    UI.Label { text = "Day" .. (rec.day or "?"), fontSize = 11, fontColor = C.textLight, width = 38 },
                    UI.Panel { flex = 1, children = { PixelBar(math.min(1, (rec.cafeScore or 0) / math.max(1, CalcCafeScore())), { height = 4, barColor = C.gold }) } },
                    UI.Label { text = tostring(rec.cafeScore or 0), fontSize = 11, fontColor = C.text, width = 32, textAlign = "right" },
                    UI.Label { text = prevRec and ((delta >= 0 and "+" or "") .. delta) or "-", fontSize = 10, fontColor = deltaColor, width = 30, textAlign = "right" },
                },
            })
        end
        table.insert(children, UI.Panel {
            width = "100%", padding = 8, gap = 4, backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
            children = {
                UI.Label { text = "📊 历史周评分", fontSize = 12, fontColor = C.text, fontWeight = "bold" },
                table.unpack(histChildren),
            },
        })
    end

    return UI.Panel { width = "100%", gap = 4, children = children }
end

-- InfoRow 已在 GameState.lua 全局定义

--- 获取成就的当前进度 (current, target)，基于新 Achievements.lua 的 22 个成就
local function GetAchievementProgress(id)
    -- ── 财富里程碑 ──
    if id == "first_gold"    then return math.min(playerData_.totalEarnings or 0, 1000), 1000
    elseif id == "rolling_cash"  then return math.min(playerData_.money or 0, 5000), 5000
    elseif id == "tycoon"        then return math.min(playerData_.totalEarnings or 0, 50000), 50000
    elseif id == "gold_investor" then return math.min(playerData_.goldOunces or 0, 10), 10
    -- ── 网吧发展 ──
    elseif id == "four_pcs"      then return math.min(playerData_.computers or 1, 4), 4
    elseif id == "ten_pcs"       then return math.min(playerData_.computers or 1, 10), 10
    elseif id == "first_branch"  then return math.min(#(playerData_.branches or {}), 1), 1
    elseif id == "air_condition" then return math.min(playerData_.acLevel or 0, 1), 1
    -- ── 声望与影响力 ──
    elseif id == "known_face"    then return math.min(playerData_.reputation or 0, 50), 50
    elseif id == "local_legend"  then return math.min(playerData_.reputation or 0, 200), 200
    elseif id == "continental"   then return math.min(playerData_.reputation or 0, 500), 500
    -- ── 战队与比赛 ──
    elseif id == "first_recruit" then return math.min(#teamMembers_, 1), 1
    elseif id == "full_squad"    then return math.min(#teamMembers_, 5), 5
    elseif id == "first_win"     then return math.min(playerData_.friendlyWins or 0, 1), 1
    elseif id == "ten_wins"      then return math.min(playerData_.friendlyWins or 0, 10), 10
    elseif id == "champ"         then return math.min(playerData_.tournamentWins or 0, 1), 1
    -- ── 经营坚持 ──
    elseif id == "week_one"      then return math.min(playerData_.day or 1, 7), 7
    elseif id == "month_one"     then return math.min(playerData_.day or 1, 30), 30
    elseif id == "quest_streak5" then return math.min(playerData_.questStreak or 0, 5), 5
    -- ── 道义与选择 ──
    elseif id == "good_boss"     then return math.max(0, math.min(playerData_.karma or 0, 10)), 10
    elseif id == "survivor"      then return math.min(playerData_.nearBankruptCount or 0, 1), 1
    end
    return 0, 1
end

-- 成就分类定义
local ACHIEVE_CATEGORIES = {
    { id = "wealth",    title = "财富里程碑", icon = "💰", ids = { "first_gold", "rolling_cash", "tycoon", "gold_investor" } },
    { id = "cafe",      title = "网吧发展",   icon = "🖥️", ids = { "four_pcs", "ten_pcs", "first_branch", "air_condition" } },
    { id = "fame",      title = "声望影响力", icon = "⭐", ids = { "known_face", "local_legend", "continental" } },
    { id = "team",      title = "战队比赛",   icon = "🏆", ids = { "first_recruit", "full_squad", "first_win", "ten_wins", "champ" } },
    { id = "persist",   title = "经营坚持",   icon = "📅", ids = { "week_one", "month_one", "quest_streak5" } },
    { id = "moral",     title = "道义选择",   icon = "😇", ids = { "good_boss", "survivor" } },
}

--- 成就摘要行（用于升级Tab，点击展开弹窗）
function BuildAchievementCard()
    local stats = Achievements.GetStats()
    local unlocked = stats.unlocked
    local total    = stats.total
    local pct = total > 0 and math.floor(unlocked / total * 100) or 0

    -- 找到下一个即将完成的成就
    local nextAch = nil
    local nextPct = 0
    for _, ach in ipairs(Achievements.ALL) do
        if not Achievements.IsUnlocked(ach.id) then
            local cur, tgt = GetAchievementProgress(ach.id)
            local p = tgt > 0 and math.floor(cur / tgt * 100) or 0
            if p > nextPct then
                nextPct = p
                nextAch = ach
            end
        end
    end

    local hintText = nextAch and ("接近达成: " .. (nextAch.icon or "") .. " " .. (nextAch.title or nextAch.id) .. " (" .. nextPct .. "%)") or "全部达成！"

    -- 最近解锁的成就（最多3个）
    local recentUnlocks = Achievements.GetRecentUnlocked(3)
    local recentRow = nil
    if #recentUnlocks > 0 then
        local recentIcons = {}
        for _, r in ipairs(recentUnlocks) do
            local dayLabel = r.day > 0 and ("D" .. r.day) or ""
            table.insert(recentIcons, UI.Panel {
                alignItems = "center", gap = 1,
                children = {
                    UI.Panel {
                        width = 28, height = 28, borderRadius = 14,
                        backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 },
                        justifyContent = "center", alignItems = "center",
                        children = { UI.Label { text = r.icon or "🏅", fontSize = 14 } },
                    },
                    dayLabel ~= "" and UI.Label { text = dayLabel, fontSize = 8, fontColor = C.textDim } or nil,
                },
            })
        end
        recentRow = UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 4, paddingTop = 4,
            children = {
                UI.Label { text = "最近:", fontSize = 10, fontColor = C.textDim },
                table.unpack(recentIcons),
            },
        }
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = { C.border[1], C.border[2], C.border[3], 120 },
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                onClick = function()
                    achievePopupOpen_ = true; BuildUI()
                end,
                children = {
                    UI.Label { text = "🏅", fontSize = 18 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = "成就墙", fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
                            UI.Label { text = unlocked .. "/" .. total, fontSize = 12, fontColor = C.textDim },
                        }},
                        UI.Panel { width = "100%", height = 6, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = 3, overflow = "hidden", children = {
                            UI.Panel { width = pct .. "%", height = "100%", backgroundColor = C.gold, borderRadius = 3 },
                        }},
                    }},
                    UI.Label { text = "›", fontSize = 20, fontColor = C.textDim },
                },
            },
            recentRow,
            UI.Label { text = hintText, fontSize = 11, fontColor = C.textDim },
        },
    }
end

--- 成就弹窗（分类展示）
function BuildAchievementPopup()
    if not achievePopupOpen_ then return nil end
    local stats = Achievements.GetStats()

    local catPanels = {}
    for _, cat in ipairs(ACHIEVE_CATEGORIES) do
        local catChildren = {}
        local catDone = 0
        for _, achId in ipairs(cat.ids) do
            local ach = nil
            for _, a in ipairs(Achievements.ALL) do
                if a.id == achId then ach = a; break end
            end
            if ach then
                local done = Achievements.IsUnlocked(ach.id)
                if done then catDone = catDone + 1 end
                local cur, tgt = GetAchievementProgress(ach.id)
                local p = (done and 100) or (tgt > 0 and math.floor(cur / tgt * 100) or 0)
                local nameColor = done and C.gold or { 130, 130, 130, 255 }
                local progText  = done and "✓" or (cur .. "/" .. tgt)
                -- 解锁日标注
                local unlockDay = done and Achievements.GetUnlockDay(ach.id) or nil
                local dayTag = nil
                if unlockDay and unlockDay > 0 then
                    dayTag = UI.Label { text = "D" .. unlockDay, fontSize = 9, fontColor = { C.gold[1], C.gold[2], C.gold[3], 160 } }
                end

                table.insert(catChildren, UI.Panel {
                    flexDirection = "row", alignItems = "center", gap = 4, width = "100%",
                    paddingVertical = 3,
                    children = {
                        UI.Label { text = (ach.icon or "○"), fontSize = 13 },
                        UI.Label { text = ach.title or ach.id, fontSize = 12, fontColor = nameColor, flex = 1 },
                        dayTag,
                        UI.Label { text = progText, fontSize = 11, fontColor = done and C.green or C.textDim },
                        -- 迷你进度条
                        UI.Panel { width = 40, height = 4, backgroundColor = { C.border[1], C.border[2], C.border[3], 100 }, borderRadius = 2, overflow = "hidden", children = {
                            UI.Panel { width = p .. "%", height = "100%", backgroundColor = done and C.gold or C.textDim, borderRadius = 2 },
                        }},
                    },
                })
            end
        end
        table.insert(catPanels, UI.Panel {
            width = "100%", gap = 2, children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, paddingBottom = 2, children = {
                    UI.Label { text = cat.icon, fontSize = 13 },
                    UI.Label { text = cat.title, fontSize = 13, fontColor = C.text, fontWeight = "bold" },
                    UI.Label { text = catDone .. "/" .. #cat.ids, fontSize = 10, fontColor = C.textDim },
                }},
                table.unpack(catChildren),
            },
        })
    end

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 12,
        onClick = function() achievePopupOpen_ = false; BuildUI() end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, maxHeight = "85%",
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = 2, borderColor = C.gold,
                padding = 14, gap = 10,
                onClick = function() end, -- 阻止穿透
                children = {
                    UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", width = "100%", children = {
                        UI.Label { text = "🏅 成就墙 " .. stats.unlocked .. "/" .. stats.total, fontSize = 16, fontWeight = "bold", fontColor = C.gold },
                        UI.Button { text = "✕", variant = "ghost", fontSize = 16, fontColor = C.textDim,
                            onClick = function() achievePopupOpen_ = false; BuildUI() end },
                    }},
                    UI.ScrollView { width = "100%", flex = 1, children = {
                        UI.Panel { width = "100%", gap = 12, children = catPanels },
                    }},
                },
            },
        },
    }
end

-- ============================================================================
-- 3.3 成就邮箱系统 UI
-- ============================================================================

--- 邮箱入口卡片（显示在升级tab，成就卡片下方）
function BuildMailboxCard()
    local unclaimedCount = Achievements.GetUnclaimedMailCount()
    local totalMails = #(playerData_.mailbox or {})

    if totalMails == 0 then return nil end  -- 没邮件就不显示

    local badgeColor = unclaimedCount > 0 and { 220, 60, 60, 255 } or { 80, 80, 80, 180 }
    local hintText = unclaimedCount > 0
        and (unclaimedCount .. " 封未领取奖励")
        or "所有奖励已领取"

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = unclaimedCount > 0 and { 220, 160, 50, 120 } or { C.border[1], C.border[2], C.border[3], 120 },
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                onClick = function()
                    mailboxPopupOpen_ = true; BuildUI()
                end,
                children = {
                    UI.Label { text = "📬", fontSize = 18 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                            UI.Label { text = "成就邮箱", fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
                            unclaimedCount > 0 and UI.Panel {
                                backgroundColor = badgeColor, borderRadius = 8,
                                paddingHorizontal = 6, paddingVertical = 1,
                                children = {
                                    UI.Label { text = tostring(unclaimedCount), fontSize = 10, fontColor = { 255, 255, 255, 255 }, fontWeight = "bold" },
                                },
                            } or nil,
                        }},
                        UI.Label { text = hintText, fontSize = 11, fontColor = C.textDim },
                    }},
                    UI.Label { text = "›", fontSize = 20, fontColor = C.textDim },
                },
            },
        },
    }
end

--- 邮箱弹窗（展示所有邮件 + 领取按钮）
function BuildMailboxPopup()
    if not mailboxPopupOpen_ then return nil end

    local mails = Achievements.GetMailbox()
    local unclaimedCount = Achievements.GetUnclaimedMailCount()

    local mailItems = {}
    for idx, mail in ipairs(mails) do
        if idx > 15 then break end  -- 显示最近15封
        local isClaimed = mail.claimed
        local r = mail.reward or {}
        local rewardParts = {}
        if r.money then table.insert(rewardParts, "$" .. r.money) end
        if r.rep then table.insert(rewardParts, "声望+" .. r.rep) end
        if r.karma then table.insert(rewardParts, "道义+" .. r.karma) end
        local rewardText = #rewardParts > 0 and table.concat(rewardParts, "  ") or "无奖励"

        table.insert(mailItems, UI.Panel {
            width = "100%", padding = 8, flexDirection = "row", alignItems = "center", gap = 6,
            backgroundColor = isClaimed and { C.bg[1], C.bg[2], C.bg[3], 180 } or { C.gold[1], C.gold[2], C.gold[3], 15 },
            borderRadius = PX.cardRadius,
            borderWidth = (not isClaimed) and 1 or 0,
            borderColor = (not isClaimed) and { C.gold[1], C.gold[2], C.gold[3], 60 } or { 0, 0, 0, 0 },
            children = {
                UI.Label { text = mail.icon or "📬", fontSize = 16, width = 24 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label {
                        text = mail.title or "奖励",
                        fontSize = 12,
                        fontColor = isClaimed and C.textDim or C.text,
                        fontWeight = isClaimed and "normal" or "bold",
                    },
                    UI.Label {
                        text = rewardText .. "  |  Day" .. (mail.time or "?"),
                        fontSize = 10, fontColor = C.textDim,
                    },
                }},
                (not isClaimed) and UI.Button {
                    text = "领取", fontSize = 11, height = 26, paddingHorizontal = 10,
                    variant = "secondary",
                    onClick = function()
                        Achievements.ClaimMail(mail.id)
                        BuildUI()
                    end,
                } or UI.Label { text = "✓", fontSize = 12, fontColor = { 100, 180, 100, 180 } },
            },
        })
    end

    if #mailItems == 0 then
        table.insert(mailItems, UI.Panel {
            width = "100%", padding = 20, alignItems = "center",
            children = {
                UI.Label { text = "📭", fontSize = 32 },
                UI.Label { text = "暂无邮件", fontSize = 14, fontColor = C.textDim },
                UI.Label { text = "达成成就后奖励将送到这里", fontSize = 11, fontColor = C.textDim },
            },
        })
    end

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 12,
        onClick = function() mailboxPopupOpen_ = false; BuildUI() end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 380, maxHeight = "80%",
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = 2, borderColor = C.gold,
                padding = 14, gap = 10,
                onClick = function() end,  -- 阻止穿透
                children = {
                    -- 标题栏
                    UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", width = "100%", children = {
                        UI.Label { text = "📬 成就邮箱", fontSize = 16, fontWeight = "bold", fontColor = C.gold },
                        UI.Button { text = "✕", variant = "ghost", fontSize = 16, fontColor = C.textDim,
                            onClick = function() mailboxPopupOpen_ = false; BuildUI() end },
                    }},
                    -- 一键领取按钮
                    unclaimedCount > 0 and UI.Button {
                        text = "📦 一键领取全部（" .. unclaimedCount .. "封）",
                        width = "100%", height = 36, fontSize = 13, fontWeight = "bold",
                        backgroundColor = { 26, 18, 10, 255 }, fontColor = { 245, 215, 128, 255 },
                        borderRadius = PX.radius, borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                        onClick = function()
                            Achievements.ClaimAllMail()
                            BuildUI()
                        end,
                    } or nil,
                    -- 邮件列表
                    UI.ScrollView { width = "100%", flex = 1, children = {
                        UI.Panel { width = "100%", gap = 4, children = mailItems },
                    }},
                },
            },
        },
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
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        onClick = function()
            challengeBlockedPopup_ = nil; BuildUI()
        end,
        children = {
            UI.Panel {
                width = "85%", maxWidth = 360, padding = 20, gap = 12,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = C.gold,
                alignItems = "center",
                children = {
                    UI.Label { text = "⚠️ 无法踢馆", fontSize = 16, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label { text = challengeBlockedPopup_, fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, textAlign = "center", width = "100%" },
                    UI.Button {
                        text = "知道了", width = 140, height = 38, fontSize = 14,
                        backgroundColor = C.accent, fontColor = C.text,
                        borderRadius = PX.cardRadius,
                        onClick = function()
                            challengeBlockedPopup_ = nil; BuildUI()
                        end,
                    },
                },
            },
        },
    }
end

