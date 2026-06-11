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

                table.insert(catChildren, UI.Panel {
                    flexDirection = "row", alignItems = "center", gap = 4, width = "100%",
                    paddingVertical = 3,
                    children = {
                        UI.Label { text = (ach.icon or "○"), fontSize = 13 },
                        UI.Label { text = ach.title or ach.id, fontSize = 12, fontColor = nameColor, flex = 1 },
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
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = { 190, 148, 50, 200 },
                alignItems = "center",
                boxShadow = { { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 80 } } },
                children = {
                    UI.Label { text = "⚠️ 无法踢馆", fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                    UI.Label { text = challengeBlockedPopup_, fontSize = 14, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5, textAlign = "center", width = "100%" },
                    UI.Button {
                        text = "知道了", width = 140, height = 38, fontSize = 14,
                        backgroundColor = { 26, 18, 10, 255 }, fontColor = { 245, 215, 128, 255 },
                        borderRadius = PX.radius, borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                        onClick = function()
                            challengeBlockedPopup_ = nil; BuildUI()
                        end,
                    },
                },
            },
        },
    }
end

