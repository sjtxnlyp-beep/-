---@diagnostic disable: undefined-global
-- ============================================================================
-- 13. 经营界面（带背景图）
-- ============================================================================
goldExpanded_ = goldExpanded_ or false  -- 黄金交易面板展开状态
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

--- 底部导航栏（像素风格，放大按钮）
function BuildBottomNavBar()
    -- 角标数据
    -- 团队角标：可招募 或 有NPC可聊
    local teamBadge = nil
    if #(CANDIDATE_POOL or {}) > 0 and #teamMembers_ < 5 then
        teamBadge = "!"
    elseif NPCStorylines and NPCStorylines.CanAdvanceNpc then
        -- 检查是否有已解锁NPC可推进剧情
        local NPC_IDS = { "kofi", "grace", "snake" }
        for _, nid in ipairs(NPC_IDS) do
            if NPCStorylines.CanAdvanceNpc(nid) then
                teamBadge = "💬"
                break
            end
        end
    end
    -- 自动化升级就绪角标
    local autoBadge = nil
    local autoLv = playerData_.automationLevel or 0
    if autoLv < 4 then
        local IdleEngine = require("IdleEngine")
        local canUp, _ = IdleEngine.CanUnlockAutomation(autoLv + 1)
        if canUp then autoBadge = "!" end
    end
    -- 转生就绪角标
    local PrestigeSystem = require("PrestigeSystem")
    if not autoBadge and PrestigeSystem.CanPrestige() then autoBadge = "⭐" end

    local tabs = {
        { key = "action",     icon = "🏠", label = "经营",   badge = nil },
        { key = "upgrade",    icon = "⬆",  label = "升级",   badge = nil },
        { key = "team",       icon = "👥", label = "团队",   badge = teamBadge },
        { key = "automation", icon = "🤖", label = "自动化", badge = autoBadge },
        { key = "market",     icon = "🛒", label = "市场",   badge = nil },
        { key = "ranking",    icon = "🏆", label = "排行榜", badge = nil },
    }
    local tabItems = {}
    for _, t in ipairs(tabs) do
        local isActive = (manageTab_ == t.key)
        -- 角标气泡
        local badgeNode = nil
        if t.badge then
            local badgeText = type(t.badge) == "number" and tostring(t.badge) or t.badge
            badgeNode = UI.Panel {
                position = "absolute", top = 0, right = 2,
                minWidth = 18, height = 18, borderRadius = PX.radius,
                backgroundColor = C.red,
                justifyContent = "center", alignItems = "center",
                paddingHorizontal = 4,
                borderWidth = PX.border, borderColor = C.card,
                children = {
                    UI.Label { text = badgeText, fontSize = 10, fontWeight = "bold", fontColor = { 255, 255, 255, 255 } },
                },
            }
        end
        -- 激活状态：图标上方圆角高亮条
        local activePill = isActive and UI.Panel {
            position = "absolute", top = 0, left = "20%", right = "20%",
            height = 3, borderRadius = 2,
            backgroundColor = C.accent,
        } or nil

        -- 动态构建子列表，避免 nil 放在首位导致 ipairs 中断
        local tabChildren = {}
        if activePill then table.insert(tabChildren, activePill) end
        table.insert(tabChildren, UI.Panel {
            width = 34, height = 28, borderRadius = 10,
            justifyContent = "center", alignItems = "center",
            backgroundColor = isActive and { C.accent[1], C.accent[2], C.accent[3], 35 } or { 0,0,0,0 },
            children = {
                UI.Label { text = t.icon, fontSize = 20, textAlign = "center" },
            },
        })
        table.insert(tabChildren, UI.Label {
            text = t.label, fontSize = 10,
            fontColor = isActive and C.accent or C.textLight,
            fontWeight = isActive and "bold" or "normal",
            textAlign = "center", marginTop = 2,
        })
        if badgeNode then table.insert(tabChildren, badgeNode) end

        table.insert(tabItems, UI.Panel {
            flex = 1, height = 66,
            justifyContent = "center", alignItems = "center",
            paddingTop = 8, paddingBottom = 6,
            backgroundColor = { 0, 0, 0, 0 },
            onClick = function()
                if manageTab_ ~= t.key then PlaySFX("page_turn") end
                manageTab_ = t.key
                BuildUI()
            end,
            children = tabChildren,
        })
    end
    return UI.Panel {
        width = "100%", height = 66, flexDirection = "row",
        backgroundColor = C.card,
        borderTopWidth = 1, borderColor = { C.border[1], C.border[2], C.border[3], 120 },
        children = tabItems,
    }
end

--- 热区按钮辅助（透明绝对定位，含小标签）
local function HotspotBtn(props)
    local disabled = props.disabled
    local bgColor = disabled and { 0, 0, 0, 60 } or { 0, 0, 0, 80 }
    local labelColor = disabled and { 180, 170, 160, 180 } or { 253, 245, 230, 240 }
    local children = {
        UI.Label {
            text = props.label, fontSize = 11, fontWeight = "bold",
            fontColor = labelColor, textAlign = "center",
        },
    }
    if props.price then
        table.insert(children, UI.Label {
            text = props.price, fontSize = 10,
            fontColor = disabled and C.textLight or C.gold,
            textAlign = "center",
        })
    end
    if props.badge then
        table.insert(children, 1, UI.Panel {
            position = "absolute", top = 2, right = 2,
            width = 8, height = 8, borderRadius = PX.radiusSm,
            backgroundColor = C.red or { 255, 80, 80, 255 },
        })
    end
    return UI.Panel {
        position = "absolute",
        top = props.top, left = props.left,
        right = props.right, bottom = props.bottom,
        width = props.width, height = props.height,
        backgroundColor = bgColor,
        borderRadius = PX.radius,
        borderWidth = disabled and 0 or PX.border,
        borderColor = { 253, 245, 230, 60 },
        justifyContent = "center", alignItems = "center", gap = 1,
        onClick = not disabled and props.onClick or nil,
        children = children,
    }
end

--- 沉浸式广告专区条带（全景与行动区之间）
--- 横向滚动排列可用的激励广告，紧凑醒目
function BuildAdBanner()
    local items = {}
    local day = playerData_.day

    -- 1. 翻倍昨日收入 / 经营补贴
    local lastNet = playerData_.lastNetIncome or 0
    if AdManager.CanWatch("double_income", day) then
        local bonus = lastNet > 0 and lastNet or math.max(50, math.floor(day * 8))
        local label = lastNet > 0
            and ("翻倍收入 +$" .. bonus)
            or  ("经营补贴 +$" .. bonus)
        table.insert(items, AdManager.AdButton {
            sceneId = "double_income", day = day,
            text = "📺 " .. label,
            height = 34, fontSize = 11, borderRadius = PX.radius,
            paddingHorizontal = 12,
            backgroundColor = { 40, 80, 40, 220 },
            fontColor = C.moneyGreen,
            borderWidth = PX.border, borderColor = { C.moneyGreen[1], C.moneyGreen[2], C.moneyGreen[3], 100 },
            onReward = function()
                playerData_.money = playerData_.money + bonus
                playerData_.totalEarnings = (playerData_.totalEarnings or 0) + bonus
                playerData_.lastNetIncome = 0
                AddLog("🎬 赞助商追加了经营奖励！额外获得$" .. bonus .. "！")
                BuildUI()
            end,
        })
    end

    -- 2. 额外行动点（AP耗尽时）
    local noAP = (playerData_.actionPoints or 0) <= 0
    if noAP and AdManager.CanWatch("extra_ap", day) then
        table.insert(items, AdManager.AdButton {
            sceneId = "extra_ap", day = day,
            text = "📺 恢复行动 +1AP",
            height = 34, fontSize = 11, borderRadius = PX.radius,
            paddingHorizontal = 12,
            backgroundColor = { 80, 50, 30, 220 },
            fontColor = C.gold,
            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 100 },
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                BuildUI()
            end,
        })
    end

    -- 3. 赞助商中心（提前确定奖励，展示给玩家看）
    if AdManager.CanWatch("sponsor_small", day) then
        local rewards = {
            { label = "$30现金",   fn = function() playerData_.money = playerData_.money + 30; playerData_.totalEarnings = (playerData_.totalEarnings or 0) + 30; AddLog("📺 赞助商小额赞助 +$30！") end },
            { label = "声望+5",   fn = function() playerData_.reputation = playerData_.reputation + 5; AddLog("📺 赞助商帮你在社交媒体曝光！声望+5") end },
            { label = "设备+10%", fn = function() playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 80) + 10); AddLog("📺 赞助商寄来零件！设备状态+10%") end },
            { label = "行动点+1", fn = function() playerData_.actionPoints = playerData_.actionPoints + 1; AddLog("📺 赞助商的咖啡让你精力充沛！行动点+1") end },
        }
        -- 提前确定奖励，让玩家知道会得到什么（提升点击率）
        local preRoll = rewards[math.random(1, #rewards)]
        table.insert(items, AdManager.AdButton {
            sceneId = "sponsor_small", day = day,
            text = "📺 看短片得 " .. preRoll.label,
            height = 34, fontSize = 11, borderRadius = PX.radius,
            paddingHorizontal = 12,
            backgroundColor = { 60, 46, 70, 220 },
            fontColor = { 200, 180, 255, 255 },
            borderWidth = PX.border, borderColor = { 160, 130, 200, 100 },
            onReward = function()
                preRoll.fn()
                playerData_.questAdWatchCount = (playerData_.questAdWatchCount or 0) + 1
                PlaySFX("coin")
                BuildUI()
            end,
        })
    end

    -- 没有可用广告时不显示
    if #items == 0 then return nil end

    return UI.Panel {
        width = "100%",
        backgroundColor = { 20, 16, 12, 200 },
        paddingHorizontal = 8, paddingVertical = 5,
        children = {
            UI.ScrollView {
                width = "100%", height = 44,
                scrollDirection = "horizontal",
                showScrollIndicator = false,
                children = {
                    UI.Panel {
                        flexDirection = "row", gap = 8, alignItems = "center",
                        height = "100%",
                        children = items,
                    },
                },
            },
        },
    }
end

--- 全景像素图 + 实况入口浮标 + 广告招募横条
cafePopupOpen_ = cafePopupOpen_ or false
function BuildPanoramaSection()
    local cafeImg = GetCafeSceneImage()

    -- 实况入口（右上角浮标，带动效脉冲）
    GenerateDailyCafeEvents()
    local pendingCafe = pendingCafeCount_ or 0
    local totalCafe = cafeEvents_ and #cafeEvents_ or 0
    local cafeLabel = "网吧实况"
    if pendingCafe > 0 then
        cafeLabel = cafeLabel .. " " .. pendingCafe .. "件待处理"
    elseif totalCafe > 0 then
        cafeLabel = cafeLabel .. " " .. totalCafe .. "件"
    end

    -- 动效：脉冲光圈（基于 gameTime_ 周期性变化透明度）
    local pulse = pendingCafe > 0 and (math.floor(gameTime_ * 3) % 2 == 0) or false
    local badgeBg = pendingCafe > 0
        and (pulse and { 180, 50, 20, 220 } or { 140, 40, 15, 200 })
        or { 0, 0, 0, 140 }
    local badgeBorder = pendingCafe > 0
        and (pulse and { 255, 120, 40, 255 } or { C.gold[1], C.gold[2], C.gold[3], 200 })
        or { 253, 245, 230, 80 }

    -- 动态构建 hotCafe 子列表，避免 nil 放首位导致 ipairs 中断
    local hotCafeChildren = {}
    table.insert(hotCafeChildren, UI.Label {
        text = cafeLabel, fontSize = 12, fontWeight = "bold",
        fontColor = pendingCafe > 0 and { 255, 220, 140, 255 } or { 253, 245, 230, 220 },
    })
    if pendingCafe > 0 then
        table.insert(hotCafeChildren, UI.Panel {
            width = 10, height = 10, borderRadius = PX.radiusSm,
            backgroundColor = pulse and { 255, 60, 60, 255 } or { 255, 120, 60, 255 },
            borderWidth = PX.border, borderColor = { 255, 255, 255, 150 },
        })
    end

    local hotCafe = UI.Panel {
        position = "absolute", top = 6, right = 6,
        paddingHorizontal = 10, paddingVertical = 6,
        backgroundColor = badgeBg,
        borderRadius = PX.cardRadius,
        borderWidth = pendingCafe > 0 and 2 or 1,
        borderColor = badgeBorder,
        flexDirection = "row", alignItems = "center", gap = 5,
        onClick = function()
            cafePopupOpen_ = true
            AutoResolveCafeEvents()
            PlaySFX("click")
            BuildUI()
        end,
        children = hotCafeChildren,
    }

    -- 对话气泡（网吧顾客的像素风对话，增加趣味性）
    local CAFE_DIALOGUES = {
        "再来一局！", "网速快点啊", "老板加个钟",
        "这把稳赢！", "队友太菜了", "泡面好了没",
        "网管！加冰！", "今晚通宵！", "上分了上分了",
        "别催马上好", "太上头了", "键盘手感不错",
    }
    local d = playerData_.day or 1
    local dIdx1 = (d * 3 + 1) % #CAFE_DIALOGUES + 1
    local dIdx2 = (d * 7 + 5) % #CAFE_DIALOGUES + 1
    if dIdx2 == dIdx1 then dIdx2 = dIdx1 % #CAFE_DIALOGUES + 1 end

    -- 像素对话气泡（仅有客人时显示）
    local bubble1, bubble2 = nil, nil
    if cafeImg ~= SCENE_IMAGES.cafe_empty and cafeImg ~= SCENE_IMAGES.cafe_blackout then
        bubble1 = UI.Panel {
            position = "absolute", bottom = 55, left = 12,
            paddingHorizontal = 6, paddingVertical = 3,
            backgroundColor = { 255, 255, 245, 220 },
            borderRadius = PX.radiusSm,
            borderWidth = PX.border, borderColor = { 50, 35, 25, 255 },
            children = {
                UI.Label { text = CAFE_DIALOGUES[dIdx1], fontSize = 9, fontWeight = "bold",
                    fontColor = { 40, 30, 20, 255 } },
            },
        }
        -- 客多时显示第二个气泡
        if cafeImg ~= SCENE_IMAGES.cafe_few and cafeImg ~= SCENE_IMAGES.cafe_few_night then
            bubble2 = UI.Panel {
                position = "absolute", bottom = 28, right = 50,
                paddingHorizontal = 6, paddingVertical = 3,
                backgroundColor = { 255, 250, 230, 210 },
                borderRadius = PX.radiusSm,
                borderWidth = PX.border, borderColor = { 50, 35, 25, 255 },
                children = {
                    UI.Label { text = CAFE_DIALOGUES[dIdx2], fontSize = 9, fontWeight = "bold",
                        fontColor = { 40, 30, 20, 255 } },
                },
            }
        end
    end

    -- 夜间时段标识（深夜玩家共鸣）
    local hourNow = os.date("*t").hour
    local nightBadge = nil
    if hourNow >= 22 or hourNow < 6 then
        local isOvn = hourNow >= 1 and hourNow < 5
        nightBadge = UI.Panel {
            position = "absolute", top = 8, left = 8,
            paddingHorizontal = 6, paddingVertical = 2,
            backgroundColor = { 30, 20, 50, 200 },
            borderRadius = PX.radiusSm,
            borderWidth = PX.border, borderColor = { 100, 80, 160, 200 },
            children = {
                UI.Label { text = isOvn and "包夜中" or "夜间", fontSize = 9, fontWeight = "bold",
                    fontColor = { 200, 180, 255, 255 } },
            },
        }
    end

    -- 动态构建全景图子列表，避免 nil 放首位导致 ipairs 中断
    local panoramaChildren = {}
    table.insert(panoramaChildren, hotCafe)
    if nightBadge then table.insert(panoramaChildren, nightBadge) end
    if bubble1 then table.insert(panoramaChildren, bubble1) end
    if bubble2 then table.insert(panoramaChildren, bubble2) end

    return UI.Panel {
        width = "100%", height = 230,
        backgroundImage = cafeImg, backgroundFit = "cover",
        children = panoramaChildren,
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
    -- v12 新字段（旧存档兼容）
    p.tutorialStep = p.tutorialStep or 0
    p.specialization = p.specialization or nil
    p.specChoiceDay = p.specChoiceDay or 0
    p.prestigeMilestonesClaimed = p.prestigeMilestonesClaimed or {}
    if p.statusBarExpanded == nil then p.statusBarExpanded = false end
    p.upgradeListFilter = p.upgradeListFilter or "all"
    p.honorOfflineBonus = p.honorOfflineBonus or 0
    p.honorIncomeBonus = p.honorIncomeBonus or 0
    -- v11 自动化/转生（旧存档兼容）
    p.automationLevel = p.automationLevel or 0
    p.prestigeHonor = p.prestigeHonor or 0
    p.prestigeCount = p.prestigeCount or 0
    p.currentCity = p.currentCity or "wakandaville"
    p.unlockedCities = p.unlockedCities or { "wakandaville" }
    p.prestigeHistory = p.prestigeHistory or {}
    p.totalPrestigeEarnings = p.totalPrestigeEarnings or 0
end

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

            -- 判断该NPC是否有可主动触发的剧情
            local canChat = NPCStorylines and NPCStorylines.CanAdvanceNpc and NPCStorylines.CanAdvanceNpc(profile.id)
            local chatBtn = canChat and UI.Button {
                text = "💬 聊一聊",
                height = 26, paddingHorizontal = 10, fontSize = 11,
                borderRadius = PX.radius, borderWidth = PX.border,
                backgroundColor = { 26, 18, 10, 255 },
                fontColor = { 245, 215, 128, 255 },
                borderColor = { 190, 148, 50, 200 },
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
            } or nil

            table.insert(npcCards, UI.Panel {
                width = "100%", padding = 10, gap = 4,
                backgroundColor = isFullStory and { 255, 215, 0, 10 } or { 255, 255, 255, 15 },
                borderRadius = PX.radius,
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
                                                paddingTop = 1, paddingBottom = 1, borderRadius = PX.radiusSm },
                                        },
                                    },
                                    UI.Label { text = profile.bio, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                                },
                            },
                            UI.Label { text = badge, fontSize = 10, fontColor = badgeColor,
                                backgroundColor = badgeBg, paddingLeft = 5, paddingRight = 5,
                                paddingTop = 2, paddingBottom = 2, borderRadius = PX.radius },
                        },
                    },
                    UI.Panel {
                        width = "100%", gap = 2, marginTop = 4,
                        borderWidth = { 1, 0, 0, 0 }, borderColor = { 255, 255, 255, 20 },
                        paddingTop = 4,
                        children = eventItems,
                    },
                    chatBtn and UI.Panel {
                        width = "100%", flexDirection = "row", justifyContent = "flex-end",
                        marginTop = 4,
                        children = { chatBtn },
                    } or UI.Panel { height = 0 },
                },
            })
        else
            -- ====== 未相遇：悬念卡片（展示线索刺激解锁欲望）======
            local teaseText = profile.tease or ("据说附近有一位" .. profile.role .. "，也许某天会出现……")
            local hintText = profile.hint or "持续经营，等待命运的安排"
            table.insert(npcCards, UI.Panel {
                width = "100%", padding = 10, gap = 6,
                backgroundColor = { 240, 180, 100, 15 },
                borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { 210, 180, 130, 30 },
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
                                                paddingTop = 1, paddingBottom = 1, borderRadius = PX.radiusSm },
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
local function BuildSeasonPassPopup()
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
local function BuildFreeMiniGamePanel()
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
local function BuildTeamBondPanel()
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
                width = "100%", padding = 10, borderRadius = PX.radius,
                backgroundColor = { 200, 85, 60, 220 },
                borderWidth = PX.border, borderColor = { 255, 60, 60, 150 },
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
        -- P0: 今日顾问建议（跨模块信号引导）
        local advisorTip = nil
        local okAdv, tip = pcall(GetDailyAdvisorTip)
        if okAdv and tip then
            advisorTip = UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                padding = 8, gap = 8, borderRadius = PX.radius,
                backgroundColor = { 60, 80, 60, 200 },
                borderWidth = 1, borderColor = { 100, 160, 80, 120 },
                children = {
                    UI.Label { text = tip.icon or "💡", fontSize = 16 },
                    UI.Panel { flex = 1, gap = 1, children = {
                        UI.Label { text = tip.text or "", fontSize = 12, fontColor = C.text, fontWeight = "bold" },
                        UI.Label { text = tip.hint or "", fontSize = 11, fontColor = C.textDim },
                    }},
                    UI.Label { text = "顾问", fontSize = 10, fontColor = { 140, 180, 120, 180 } },
                },
            }
        end
        if advisorTip then table.insert(actionChildren, advisorTip) end

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
                            width = "100%", padding = 8, borderRadius = PX.radius,
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
                                    width = "100%", height = 4, borderRadius = PX.radiusSm,
                                    backgroundColor = { 0, 0, 0, 60 },
                                    children = {
                                        UI.Panel {
                                            width = math.floor(pct * 100) .. "%", height = 4, borderRadius = PX.radiusSm,
                                            backgroundColor = g.done and { 100, 220, 100, 220 } or { 255, 220, 100, 220 },
                                        },
                                    },
                                },
                                rewardText ~= "" and UI.Label { text = rewardText, fontSize = 11, fontColor = { 255, 215, 100, 200 } } or nil,
                            },
                        })
                    end
                    table.insert(cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = PX.radius,
                        backgroundColor = { 40, 40, 60, 180 },
                        borderWidth = PX.border, borderColor = { 255, 220, 100, 60 },
                        gap = 6,
                        children = {
                            UI.Label { text = "🎯 目标挑战", fontSize = 15, fontWeight = "bold", fontColor = { 255, 220, 100, 240 }, width = "100%" },
                            table.unpack(goalItems),
                        },
                    })
                end
            end

            -- P2-B 精英目标卡（3条目标链全部完成后显示）
            if Retention and Retention.GetCurrentEliteGoal then
                local elite = Retention.GetCurrentEliteGoal()
                if elite then
                    local eliteCard
                    if elite.done then
                        -- 全部完成态
                        eliteCard = UI.Panel {
                            width = "100%", padding = 10, borderRadius = PX.radius,
                            backgroundColor = { 50, 35, 80, 200 },
                            borderWidth = PX.border, borderColor = { 200, 150, 255, 120 },
                            flexDirection = "row", alignItems = "center", gap = 10,
                            children = {
                                UI.Label { text = "🌐", fontSize = 26, flexShrink = 0 },
                                UI.Panel { flex = 1, gap = 2, children = {
                                    UI.Label { text = "传奇已成", fontSize = 14, fontWeight = "bold",
                                        fontColor = { 220, 180, 255, 255 } },
                                    UI.Label { text = elite.desc, fontSize = 12,
                                        fontColor = { 180, 160, 220, 200 }, whiteSpace = "normal" },
                                }},
                            },
                        }
                    else
                        -- 进行中精英目标
                        local rewardParts = {}
                        if elite.reward then
                            if (elite.reward.money or 0) > 0 then table.insert(rewardParts, "$" .. elite.reward.money) end
                            if (elite.reward.rep or 0) > 0 then table.insert(rewardParts, "+" .. elite.reward.rep .. "声望") end
                        end
                        local rewardStr = #rewardParts > 0 and ("奖励: " .. table.concat(rewardParts, " · ")) or ""
                        eliteCard = UI.Panel {
                            width = "100%", padding = 10, borderRadius = PX.radius,
                            backgroundColor = { 45, 30, 70, 200 },
                            borderWidth = PX.border, borderColor = { 180, 120, 255, 140 },
                            gap = 6,
                            children = {
                                -- 标题行
                                UI.Panel {
                                    width = "100%", flexDirection = "row",
                                    alignItems = "center", justifyContent = "space-between",
                                    children = {
                                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                                            UI.Label { text = "🌟", fontSize = 14 },
                                            UI.Label { text = "精英目标 · " .. elite.idx .. "/" .. elite.total,
                                                fontSize = 13, fontWeight = "bold",
                                                fontColor = { 220, 180, 255, 255 } },
                                        }},
                                        UI.Panel {
                                            paddingHorizontal = 6, paddingVertical = 2,
                                            backgroundColor = { 120, 60, 200, 140 }, borderRadius = 8,
                                            children = {
                                                UI.Label { text = "挑战", fontSize = 10,
                                                    fontColor = { 230, 200, 255, 255 } },
                                            },
                                        },
                                    },
                                },
                                -- 目标图标+标题
                                UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, children = {
                                    UI.Label { text = elite.icon, fontSize = 22, flexShrink = 0 },
                                    UI.Panel { flex = 1, gap = 2, children = {
                                        UI.Label { text = elite.title, fontSize = 15, fontWeight = "bold",
                                            fontColor = { 255, 240, 200, 255 } },
                                        UI.Label { text = elite.desc, fontSize = 12,
                                            fontColor = { 200, 185, 235, 220 }, whiteSpace = "normal" },
                                    }},
                                }},
                                -- 奖励
                                rewardStr ~= "" and UI.Label { text = rewardStr, fontSize = 11,
                                    fontColor = { 255, 215, 100, 200 } } or nil,
                            },
                        }
                    end
                    if eliteCard then table.insert(cards, eliteCard) end
                end
            end

            -- 周期性大事件指示器
            if Retention then
                local active = Retention.GetActivePeriodicEvent and Retention.GetActivePeriodicEvent()
                if active then
                    -- 活跃的周期事件
                    table.insert(cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = PX.radius,
                        backgroundColor = { 180, 60, 60, 140 },
                        borderWidth = PX.border, borderColor = { 255, 100, 100, 100 },
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
                            width = "100%", padding = 8, borderRadius = PX.radius,
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
                    width = "100%", padding = 10, borderRadius = PX.radius,
                    backgroundColor = { 200, 170, 40, 180 },
                    borderWidth = PX.border, borderColor = { 255, 215, 0, 200 },
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
                            width = "100%", padding = 8, borderRadius = PX.radius,
                            backgroundColor = { 50, 60, 70, 150 }, gap = 4,
                            children = {
                                UI.Label { text = me.title, fontSize = 14, fontWeight = "bold", fontColor = C.text, width = "100%" },
                                UI.Label { text = me.desc, fontSize = 12, fontColor = C.textLight, whiteSpace = "normal", width = "100%" },
                                UI.Panel { width = "100%", flexDirection = "row", gap = 6, children = choiceBtns },
                            },
                        })
                    end
                    table.insert(rv2Cards, UI.Panel {
                        width = "100%", padding = 10, borderRadius = PX.radius,
                        backgroundColor = { 40, 50, 60, 180 },
                        borderWidth = PX.border, borderColor = { 100, 180, 130, 80 },
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
                    width = "100%", padding = 10, borderRadius = PX.radius,
                    backgroundColor = { 60, 50, 40, 180 },
                    borderWidth = PX.border, borderColor = { 200, 160, 60, 80 },
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

        -- P1-4: 7城征途地图胶囊（chapter>=2 时显示，让玩家感知大目标）
        if currentChapter_ >= 2 or (playerData_.unlockedCities and #playerData_.unlockedCities > 1) then
            local roadmapPanel = SafeBuild("RoadmapCapsule", BuildRoadmapCapsule)
            if roadmapPanel then table.insert(actionChildren, roadmapPanel) end
        end

        local branchPanel = SafeBuild("BranchSelector", BuildBranchSelector)
        if branchPanel then table.insert(actionChildren, branchPanel) end
        table.insert(actionChildren, SafeBuild("DiaryInline", BuildDiaryPage))

        -- P0: 转生预览窗（让远期目标Day 1可见）
        local prestigePreview = nil
        local okPS, PS2 = pcall(require, "PrestigeSystem")
        if okPS and PS2 and PS2.CITIES then
            local current = playerData_.prestigePoints or 0
            local nextCity = nil
            for _, city in ipairs(PS2.CITIES) do
                if city.prestigeReq > current then nextCity = city; break end
            end
            if nextCity then
                local pct = math.min(100, math.floor(current / nextCity.prestigeReq * 100))
                local barW = math.max(5, pct)
                -- 提示怎么获取名誉
                local hintParts = {}
                if #(playerData_.branches or {}) < 2 then table.insert(hintParts, "开分店+15") end
                table.insert(hintParts, "赢锦标赛+25")
                if (playerData_.day or 1) >= 10 then table.insert(hintParts, "升级网吧+声望") end
                local hintStr = table.concat(hintParts, " | ")
                prestigePreview = UI.Panel {
                    width = "100%", padding = 10, borderRadius = PX.radius,
                    backgroundColor = { 40, 50, 70, 200 },
                    borderWidth = 1, borderColor = { 80, 120, 180, 120 },
                    gap = 6,
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                            UI.Label { text = "🌍", fontSize = 14 },
                            UI.Label { text = "下一站：" .. nextCity.emoji .. " " .. nextCity.name, fontSize = 12, fontColor = { 180, 210, 255, 255 }, fontWeight = "bold", flex = 1 },
                            UI.Label { text = current .. "/" .. nextCity.prestigeReq .. " 名誉", fontSize = 11, fontColor = C.textDim },
                        }},
                        -- 进度条
                        UI.Panel { width = "100%", height = 6, borderRadius = 3, backgroundColor = { 30, 40, 55, 255 }, children = {
                            UI.Panel { width = barW .. "%", height = "100%", borderRadius = 3, backgroundColor = { 100, 160, 255, 220 } },
                        }},
                        UI.Label { text = "💡 " .. hintStr, fontSize = 10, fontColor = { 140, 170, 200, 180 } },
                    },
                }
            end
        end
        if prestigePreview then table.insert(actionChildren, prestigePreview) end

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
            SafeBuild("PeoplePage", BuildPeoplePage),
        }
        return UI.Panel {
            width = "100%", gap = 8,
            children = teamChildren,
        }
    elseif manageTab_ == "automation" then
        return SafeBuild("AutomationPanel", BuildAutomationPanel)
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
    -- 3. 特殊日期场景（锦标赛日、烧烤日等）
    if matchInProgress_ then
        return SCENE_IMAGES.cafe_tournament or SCENE_IMAGES.cafe_busy
    end
    if streamingActive_ then
        return SCENE_IMAGES.cafe_streaming or SCENE_IMAGES.cafe_busy
    end
    -- 4. 根据客流比例 + 周末修正
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local ratio = capacity > 0 and (traffic / capacity) or 0
    -- 周末时客流显得更热闹
    local weekday = ((playerData_.day - 1) % 7) + 1
    if weekday >= 6 then ratio = ratio * 1.15 end
    -- 夜间时段检测（真实世界时间，深夜玩家看到包夜场景引发共鸣）
    local hour = os.date("*t").hour
    local isNight = hour >= 22 or hour < 6
    local isOvernight = hour >= 1 and hour < 5

    if ratio <= 0.1 then
        return SCENE_IMAGES.cafe_empty
    elseif ratio <= 0.4 then
        if isOvernight then return SCENE_IMAGES.cafe_overnight end
        return isNight and SCENE_IMAGES.cafe_few_night or SCENE_IMAGES.cafe_few
    elseif ratio <= 0.8 then
        if isOvernight then return SCENE_IMAGES.cafe_overnight end
        return isNight and SCENE_IMAGES.cafe_normal_night or SCENE_IMAGES.cafe_normal
    else
        if isOvernight then return SCENE_IMAGES.cafe_overnight end
        return isNight and SCENE_IMAGES.cafe_busy_night or SCENE_IMAGES.cafe_busy
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

    -- 底部导航栏（替代旧 tabBar）
    local ok5, bottomNav = pcall(BuildBottomNavBar)
    if not ok5 then
        log:Write(LOG_ERROR, "[BuildManageUI] BuildBottomNavBar error: " .. tostring(bottomNav))
        bottomNav = UI.Panel { width = "100%", height = 56 }
    end

    -- ── 经营Tab：全景 + 广告条 + 完整行动面板 ──
    if manageTab_ == "action" then
        local ok6, panorama = pcall(BuildPanoramaSection)
        if not ok6 then
            log:Write(LOG_ERROR, "[BuildManageUI] BuildPanoramaSection error: " .. tostring(panorama))
            panorama = UI.Panel { width = "100%", height = 200, backgroundColor = C.card }
        end

        -- 广告专区条带（横向滚动，全景下方）
        local ok8, adBanner = pcall(BuildAdBanner)
        if not ok8 then
            log:Write(LOG_ERROR, "[BuildManageUI] BuildAdBanner error: " .. tostring(adBanner))
            adBanner = nil
        end

        -- 使用完整行动面板（保留所有原始内容）
        local ok7, actionCard = pcall(BuildActionCard)
        if not ok7 then
            log:Write(LOG_ERROR, "[BuildManageUI] BuildActionCard error: " .. tostring(actionCard))
            actionCard = UI.Label { text = "⚠️ 行动面板加载失败: " .. tostring(actionCard),
                fontSize = 13, fontColor = { 255, 100, 100, 255 }, whiteSpace = "normal", width = "90%" }
        end

        -- 网吧实况弹窗覆盖（点击全景图徽章时显示，不消耗AP）
        local cafePopup = nil
        if cafePopupOpen_ then
            local okCafe, cafeContent = pcall(BuildCafeInlinePanel)
            if not okCafe then
                log:Write(LOG_ERROR, "[BuildManageUI] BuildCafeInlinePanel error: " .. tostring(cafeContent))
                cafeContent = UI.Label { text = "加载失败", fontSize = 14, fontColor = C.red }
            end
            cafePopup = UI.Panel {
                position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
                backgroundColor = { 0, 0, 0, 160 },
                justifyContent = "center", alignItems = "center",
                paddingHorizontal = 16, paddingVertical = 40,
                onClick = function()
                    cafePopupOpen_ = false
                    PlaySFX("click")
                    BuildUI()
                end,
                children = {
                    UI.Panel {
                        width = "100%", maxHeight = "80%",
                        backgroundColor = C.card, borderRadius = PX.cardRadius,
                        borderWidth = PX.border, borderColor = C.border,
                        padding = 12, gap = 8,
                        onClick = function() end, -- 阻止点击穿透关闭
                        children = {
                            -- 标题栏
                            UI.Panel {
                                width = "100%", flexDirection = "row",
                                justifyContent = "space-between", alignItems = "center",
                                children = {
                                    UI.Label { text = "网吧实况", fontSize = 16, fontWeight = "bold", fontColor = C.gold },
                                    UI.Panel {
                                        paddingHorizontal = 10, paddingVertical = 4,
                                        backgroundColor = { C.border[1], C.border[2], C.border[3], 80 },
                                        borderRadius = PX.radius,
                                        onClick = function()
                                            cafePopupOpen_ = false
                                            PlaySFX("click")
                                            BuildUI()
                                        end,
                                        children = {
                                            UI.Label { text = "关闭", fontSize = 13, fontColor = C.text },
                                        },
                                    },
                                },
                            },
                            -- 内容区（可滚动）
                            UI.ScrollView {
                                id = "cafe-popup-scroll",
                                width = "100%", flex = 1, flexBasis = 0,
                                children = { cafeContent },
                            },
                        },
                    },
                },
            }
        end

        -- 今日经营策略卡（全景图/广告条下方）
        local ok9, stratCard = pcall(BuildStrategyCard)
        if not ok9 then
            log:Write(LOG_ERROR, "[BuildManageUI] BuildStrategyCard error: " .. tostring(stratCard))
            stratCard = nil
        end

        -- 动态构建子列表，避免 nil 在中间位置截断 ipairs 遍历
        local actionChildren = { statusBar, panorama }
        if adBanner then table.insert(actionChildren, adBanner) end
        if stratCard then table.insert(actionChildren, stratCard) end
        table.insert(actionChildren, UI.Panel {
            flex = 1, width = "100%", flexBasis = 0,
            backgroundImage = bgImg,
            backgroundFit = "cover",
            imageTint = { 30, 24, 18, 200 },
            children = {
                UI.ScrollView {
                    id = "manage-scroll",
                    flex = 1, width = "100%", flexBasis = 0,
                    paddingHorizontal = 8, paddingVertical = 6,
                    children = { actionCard },
                },
            },
        })
        table.insert(actionChildren, bottomNav)
        if cafePopup then table.insert(actionChildren, cafePopup) end

        return UI.Panel {
            width = "100%", height = "100%",
            backgroundColor = C.bg,
            children = actionChildren,
        }
    end

    -- ── 其他Tab：全宽内容 ──
    local ok4, tabContent = pcall(BuildManageTabContent)
    if not ok4 then
        log:Write(LOG_ERROR, "[BuildManageUI] BuildManageTabContent error: " .. tostring(tabContent))
        tabContent = UI.Label { text = "⚠️ 内容加载失败: " .. tostring(tabContent),
            fontSize = 13, fontColor = { 255, 100, 100, 255 }, whiteSpace = "normal", width = "90%" }
    end

    -- 转生确认弹窗层
    local prestigePopup = nil
    if showPrestigeConfirm_ and manageTab_ == "automation" then
        local okPop, popContent = pcall(BuildPrestigeConfirmPopup)
        if okPop then prestigePopup = popContent end
    end

    -- 动态构建子列表，避免 nil 在中间位置截断 ipairs 遍历
    local otherChildren = {
        statusBar,
        UI.Panel {
            flex = 1, width = "100%", flexBasis = 0,
            backgroundImage = bgImg,
            backgroundFit = "cover",
            imageTint = { 30, 24, 18, 200 },
            children = {
                UI.ScrollView {
                    id = "manage-scroll",
                    flex = 1, width = "100%", flexBasis = 0,
                    paddingHorizontal = 8, paddingVertical = 8,
                    children = { tabContent },
                },
            },
        },
        bottomNav,
    }
    if prestigePopup then table.insert(otherChildren, prestigePopup) end

    -- 成就弹窗层（升级Tab）
    if achievePopupOpen_ and manageTab_ == "upgrade" then
        local okA, aPop = pcall(BuildAchievementPopup)
        if okA and aPop then table.insert(otherChildren, aPop) end
    end

    -- 赛季通行证弹窗层（升级Tab）
    if seasonPassPopupOpen_ and manageTab_ == "upgrade" then
        local okS, sPop = pcall(BuildSeasonPassPopup)
        if okS and sPop then table.insert(otherChildren, sPop) end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bg,
        children = otherChildren,
    }
end

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
    do local ok, v = pcall(CalcDailyIncome); if ok then income2 = v end end
    local expense2 = 0
    do local ok, _, v = pcall(CalcDailyExpenses); if ok then expense2 = v end end
    local net2 = income2 - expense2
    local netColor2 = net2 >= 0 and C.green or C.red
    local netSign2 = net2 >= 0 and "+" or ""

    -- 收支展开面板（点击金额区域时显示）
    local incomeDetailPanel = sbExpanded and UI.Panel {
        width = "100%", flexDirection = "row", gap = 10,
        paddingHorizontal = 4, paddingVertical = 4,
        backgroundColor = { 30, 40, 30, 100 }, borderRadius = 4,
        children = {
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Label { text = "日收入", fontSize = 10, fontColor = C.textDim },
                UI.Label { text = "+$" .. income2, fontSize = 13, fontWeight = "bold", fontColor = C.green },
            }},
            UI.Panel { width = 1, backgroundColor = { C.border[1], C.border[2], C.border[3], 80 } },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Label { text = "日支出", fontSize = 10, fontColor = C.textDim },
                UI.Label { text = "-$" .. expense2, fontSize = 13, fontWeight = "bold", fontColor = C.red },
            }},
            UI.Panel { width = 1, backgroundColor = { C.border[1], C.border[2], C.border[3], 80 } },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Label { text = "净收入", fontSize = 10, fontColor = C.textDim },
                UI.Label { text = netSign2 .. "$" .. net2, fontSize = 13, fontWeight = "bold", fontColor = netColor2 },
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
                flexDirection = "row", alignItems = "center", gap = 6,
                children = {
                    UI.Label { text = "D" .. playerData_.day, fontSize = 12, fontWeight = "bold", fontColor = C.textDim },
                    UI.Label { text = weatherLabel, fontSize = 14, flexShrink = 0, fontColor = weatherColor },
                },
            },
        },
    })

    -- 行2: 人气指标（AP 已在行动卡片头部显示，此处不重复）
    table.insert(sbChildren, UI.Panel {
        width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
        children = {
            UI.Panel {
                flex = 1, flexDirection = "row", alignItems = "center", gap = 5,
                children = {
                    UI.Label { text = "📊", fontSize = 10, flexShrink = 0 },
                    UI.Label { text = tDesc, fontSize = 11, fontWeight = "bold", fontColor = tColor, flexShrink = 0 },
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

    -- 章节目标行已移至行动卡片（避免重复）

    -- 政变警告（可能为 nil）
    if coupWarn then table.insert(sbChildren, coupWarn) end

    -- P0-3 挂机收益估算（day>=3 且 action 标签）
    if (playerData_.day or 1) >= 3 and manageTab_ == "action" then
        local autoLevel = playerData_.automationLevel or 0
        local maxHoursByLevel = { [0]=4, [1]=8, [2]=16, [3]=24, [4]=48 }
        local maxH = maxHoursByLevel[autoLevel] or 4
        local okInc, dailyInc = pcall(CalcDailyIncome)
        if not okInc then dailyInc = 0 end
        local perHour = math.floor(dailyInc / 24)
        local maxEarning = perHour * maxH
        local autoNames = { [0]="🤯 无自动化", [1]="💰 自动收银", [2]="🔧 稳定运营", [3]="🏪 连锁模式", [4]="👑 帝国模式" }
        local autoLabel = autoNames[autoLevel] or "未知"
        table.insert(sbChildren, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            paddingHorizontal = 4, paddingVertical = 2,
            backgroundColor = { 40, 60, 80, 60 }, borderRadius = 4, gap = 6,
            children = {
                UI.Label { text = "🌙", fontSize = 10 },
                UI.Label {
                    text = "挂机上限 " .. maxH .. "h · 最多 $" .. maxEarning .. "  " .. autoLabel,
                    fontSize = 10, fontColor = { 140, 180, 220, 200 }, flex = 1,
                },
            },
        })
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
                            .. " · 收入×" .. string.format("%.1f", PrestigeSystem and PrestigeSystem.GetCurrentCity and
                                (PrestigeSystem.GetCurrentCity().incomeMulti or 1.0) or 1.0),
                        fontSize = 11, fontColor = { 160, 210, 160, 200 }, flex = 1,
                    },
                },
            },
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

    local chosen   = playerData_.strategyChosen
    local choice   = playerData_.strategyChoice  -- "A" or "B"
    local optA     = strat.optA
    local optB     = strat.optB

    -- 已选状态：显示紧凑确认条
    if chosen and choice then
        local pickedOpt = (choice == "A") and optA or optB
        local modPct = math.floor(((pickedOpt.incomeMod or 1.0) - 1.0) * 100)
        local modStr = modPct == 0 and "收入不变" or
                       (modPct > 0 and string.format("收入+%d%%", modPct) or string.format("收入%d%%", modPct))
        local modColor = modPct > 0 and C.green or (modPct < 0 and C.red or C.textDim)
        return UI.Panel {
            width = "100%",
            backgroundColor = { 25, 38, 50, 220 },
            paddingVertical = 7, paddingHorizontal = 12,
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = strat.icon or "📋", fontSize = 16 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label {
                        text = strat.title .. " — 已选：" .. (pickedOpt.label or ""),
                        fontSize = 12, fontWeight = "bold", fontColor = C.text,
                    },
                    UI.Label {
                        text = modStr,
                        fontSize = 11, fontColor = modColor,
                    },
                }},
                UI.Button {
                    text = "改选", height = 28, fontSize = 11,
                    backgroundColor = { 60, 60, 80, 180 }, fontColor = C.textLight,
                    borderRadius = 6, paddingHorizontal = 10,
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
                height = props.height or 40, fontSize = 14, borderRadius = PX.radius,
                disabled = props.disabled,
                variant = props.variant,
                flex = props.flex,
                onClick = props.onClick,
            }
        end
        return UI.Button {
            text = props.text,
            width = props.width or "100%",
            height = props.height or 40, fontSize = 14, fontWeight = "bold", borderRadius = PX.radius,
            backgroundColor = props.disabled and { 38, 30, 22, 255 } or { 28, 20, 12, 255 },
            fontColor = props.disabled and { 90, 78, 64, 255 } or { 245, 215, 128, 255 },
            borderWidth = PX.border,
            -- 统一金色边框，去掉橙红 accent（与 GridBtn 一致）
            borderColor = props.disabled and { 55, 46, 36, 255 } or (props.borderColor or { 190, 148, 50, 240 }),
            disabled = props.disabled,
            flex = props.flex,
            onClick = props.onClick,
        }
    end

    -- ── 辅助：2x2 网格按钮（开罗三层像素凸起） ──
    local function GridBtn(props)
        local disabled = props.disabled
        -- 三层结构：黑色外轮廓 → 暗金凸起底边 → 深棕内容区
        local outerBorder = disabled and { 15, 12, 8, 255 }  or { 12, 8, 4, 255 }   -- 最外层近黑描边
        local midShadow   = disabled and { 40, 34, 26, 255 } or { 80, 58, 14, 255 }  -- 中层暗金底边（凸起感）
        local bgColor     = disabled and { 38, 30, 22, 255 } or { 26, 18, 10, 255 }  -- 内容区深黑棕
        local innerBorder = disabled and { 65, 55, 42, 200 } or { 205, 162, 60, 240 } -- 内边亮金边框
        local titleColor  = disabled and { 90, 78, 64, 255 } or { 245, 215, 128, 255 }

        -- 第1行：标题（粗体金字）
        local btnChildren = {
            UI.Label {
                text = props.title, fontSize = 13, fontWeight = "bold",
                fontColor = titleColor,
            },
        }
        -- 第2行：价格 + 收益 横排（3行→2行，消除拥挤感）
        local row2Children = {}
        if props.price then
            table.insert(row2Children, UI.Label {
                text = props.price, fontSize = 11, fontWeight = "bold",
                fontColor = disabled and { 72, 62, 48, 255 } or { 230, 195, 85, 255 },
            })
        end
        if props.reward and not disabled then
            table.insert(row2Children, UI.Label {
                text = props.reward, fontSize = 9, fontWeight = "bold",
                fontColor = { 100, 220, 120, 255 },
            })
        elseif props.reason and disabled then
            table.insert(row2Children, UI.Label {
                text = props.reason, fontSize = 9,
                fontColor = { 88, 76, 60, 220 },
            })
        end
        if #row2Children > 0 then
            table.insert(btnChildren, UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 6,
                children = row2Children,
            })
        end
        -- 第1层：近黑外轮廓（开罗贴纸感）
        return UI.Panel {
            width = "48%", height = 60, borderRadius = PX.cardRadius,
            backgroundColor = outerBorder,
            justifyContent = "center", alignItems = "center",
            onClick = not disabled and props.onClick or nil,
            children = {
                -- 第2层：暗金底边（凸起阴影）
                UI.Panel {
                    width = "100%", height = 56, borderRadius = PX.cardRadius,
                    backgroundColor = midShadow,
                    justifyContent = "flex-start", alignItems = "center",
                    children = {
                        -- 第3层：实际内容区
                        UI.Panel {
                            width = "100%", height = 53, borderRadius = PX.cardRadius,
                            backgroundColor = bgColor,
                            borderWidth = 2, borderColor = innerBorder,
                            justifyContent = "center", alignItems = "center", gap = 4,
                            children = btnChildren,
                        },
                    },
                },
            },
        }
    end

    -- ── 1) 标题行（与卡片背景融合，无独立边框） ──
    local header = UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingBottom = 8,
        borderWidth = { 0, 0, 1, 0 }, borderColor = { C.border[1], C.border[2], C.border[3], 50 },
        children = {
            -- 左侧：标题
            UI.Label { text = "行动", fontSize = 15, fontColor = C.text, fontWeight = "bold" },
            -- 右侧：AP 徽章
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                paddingHorizontal = 10, paddingVertical = 4,
                backgroundColor = noAP and { C.red[1], C.red[2], C.red[3], 30 } or { C.gold[1], C.gold[2], C.gold[3], 25 },
                borderRadius = PX.radius,
                borderWidth = 1,
                borderColor = noAP and { C.red[1], C.red[2], C.red[3], 60 } or { C.gold[1], C.gold[2], C.gold[3], 50 },
                children = {
                    UI.Label { text = "AP", fontSize = 12, fontColor = noAP and C.red or C.gold },
                    UI.Label { text = ap .. "/3", fontSize = 13, fontWeight = "bold",
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

    -- ── 方案B: 加班按钮（AP耗尽且今日未加班且没广告可看时显示） ──
    local overtimeBtn = nil
    if noAP and not (playerData_.overtimeUsedToday) and not adExtraAP then
        local canAfford = (playerData_.money or 0) >= 30
        overtimeBtn = UI.Button {
            text = canAfford and "加班 -$30 -耐久5  → +1AP" or "加班需要 $30（余额不足）",
            width = "100%", height = 42, fontSize = 13,
            fontWeight = "bold",
            backgroundColor = canAfford and { 50, 35, 18, 255 } or { 35, 28, 20, 255 },
            fontColor = canAfford and { 230, 170, 60, 255 } or { 90, 78, 60, 200 },
            borderWidth = PX.border,
            borderColor = canAfford and { 180, 130, 40, 200 } or { 70, 60, 45, 150 },
            borderRadius = PX.radius,
            disabled = not canAfford,
            onClick = canAfford and function()
                playerData_.money = playerData_.money - 30
                playerData_.actionPoints = (playerData_.actionPoints or 0) + 1
                playerData_.overtimeUsedToday = true
                playerData_.endOfDayDurPenalty = (playerData_.endOfDayDurPenalty or 0) + 5
                AddLog("🌙 【加班】你透支精力撑到深夜——$30咖啡钱 + 设备多跑一小时，换来1点行动力")
                BuildUI()
            end or nil,
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

    -- ── 1.5) 每日委托任务面板（第10天后显示；Day15+ 展示委托板） ──
    local questPanel = nil
    if dailyQuest_ and playerData_.day >= 10 then
        CheckQuestProgress()

        -- 委托卡片构建函数（主委托 + 快速委托共用）
        local function BuildQuestCard(q, slotIdx, titleLabel)
            local done = q.progress >= q.goal
            local progressText = done and "已完成" or (q.progress .. "/" .. q.goal)
            local children = {
                UI.Panel {
                    flexDirection = "row", justifyContent = "space-between",
                    alignItems = "center", width = "100%",
                    children = {
                        UI.Panel { flexDirection = "row", alignItems = "center", gap = 5, children = {
                            UI.Label { text = q.icon or "📋", fontSize = 14 },
                            UI.Label { text = titleLabel, fontSize = 13, fontColor = C.gold },
                        }},
                        UI.Label { text = progressText, fontSize = 12,
                            fontColor = done and C.green or C.textDim },
                    },
                },
                UI.Label { text = q.desc, fontSize = 12, fontColor = C.text, marginTop = 3,
                    whiteSpace = "normal" },
                UI.Label { text = "奖励: " .. q.rewardDesc, fontSize = 11,
                    fontColor = C.textDim, marginTop = 1 },
            }
            if done and not q.claimed then
                table.insert(children, UI.Button {
                    text = "领取", width = "100%", height = 34, fontSize = 12, fontWeight = "bold",
                    borderRadius = PX.radius, marginTop = 5,
                    backgroundColor = { 65, 55, 40, 255 }, fontColor = C.gold,
                    borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                    onClick = function()
                        if slotIdx == 1 then ClaimQuestReward()
                        else pcall(ClaimBoardQuestReward, slotIdx) end
                        BuildUI()
                    end,
                })
            elseif q.claimed then
                table.insert(children, UI.Label {
                    text = "✅ 已领取", fontSize = 11,
                    fontColor = { C.green[1], C.green[2], C.green[3], 180 },
                    marginTop = 3, textAlign = "center",
                })
            end
            local borderCol = done and not q.claimed
                and { 200, 170, 60, 120 }
                or { C.gold[1], C.gold[2], C.gold[3], 40 }
            return UI.Panel {
                width = "100%", paddingHorizontal = 10, paddingVertical = 8,
                backgroundColor = C.cardAlt, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = borderCol,
                gap = 2, children = children,
            }
        end

        -- Day 15+ 委托板：3个槽位
        if playerData_.day >= 15 and dailyQuestBoard_ and #dailyQuestBoard_ >= 1 then
            local boardCards = {}
            local labels = { "主委托", "快速委托", "快速委托" }
            for i, q in ipairs(dailyQuestBoard_) do
                if q then
                    table.insert(boardCards, BuildQuestCard(q, i, labels[i] or "委托"))
                end
            end
            -- 委托板标题行（含连击徽章）
            local streak = playerData_.questStreak or 0
            local streakBadge = streak >= 1 and UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                backgroundColor = { 160, 100, 10, 200 }, borderRadius = 8,
                paddingHorizontal = 6, paddingVertical = 2,
                children = {
                    UI.Label { text = "🔥", fontSize = 10 },
                    UI.Label { text = "连击x" .. streak, fontSize = 10,
                        fontColor = { 255, 215, 80, 255 }, fontWeight = "bold" },
                },
            } or nil
            questPanel = UI.Panel {
                width = "100%", paddingHorizontal = 12, paddingVertical = 10,
                backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 50 },
                gap = 8,
                children = {
                    -- 标题行
                    UI.Panel {
                        flexDirection = "row", justifyContent = "space-between",
                        alignItems = "center", width = "100%",
                        children = {
                            UI.Label { text = "📋 今日委托板", fontSize = 14, fontColor = C.gold,
                                fontWeight = "bold" },
                            streakBadge or UI.Panel { width = 0, height = 0 },
                        },
                    },
                    -- 委托卡片
                    table.unpack(boardCards),
                },
            }
        else
            -- Day 5-14：单委托（原有逻辑）
            questPanel = BuildQuestCard(dailyQuest_, 1, "每日委托")
        end
    end

    -- ── 2) 结束今天（主操作按钮，像素凸起感） ──
    -- 凸起底色（暗色露出底边）
    local endBotColor = noAP and { 20, 90, 38, 255 } or { 90, 58, 10, 255 }
    local endBgColor  = noAP and { 45, 158, 72, 255 } or { 170, 115, 28, 255 }
    local endBorderHi = noAP and { 100, 220, 130, 200 } or { 230, 185, 75, 200 }
    -- 单行文字：正常时 "结束今天 (第N天)"，AP耗尽时两行保留提示
    local endMainText = noAP and "✅ 结束今天" or ("结束今天  (第" .. playerData_.day .. "天)")
    local endDayBtn = UI.Panel {
        width = "100%", height = 44, borderRadius = PX.cardRadius,
        backgroundColor = endBotColor,
        justifyContent = "center", alignItems = "center",
        onClick = function()
            if transition_.active then return end
            PlaySFX("click")
            local ok, err = pcall(EndDay)
            if not ok then
                log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
        end,
        children = {
            UI.Panel {
                width = "100%", height = 41, borderRadius = PX.cardRadius,
                backgroundColor = endBgColor,
                borderWidth = 2, borderColor = endBorderHi,
                flexDirection = "row", justifyContent = "center", alignItems = "center",
                paddingHorizontal = 12, gap = 8,
                children = {
                    UI.Label { text = noAP and "✅ 结束今天" or endMainText,
                        fontSize = 15, fontWeight = "bold",
                        fontColor = { 245, 255, 245, 255 } },
                    noAP and UI.Label { text = "行动点已用完·进入明天",
                        fontSize = 10, fontColor = { 205, 248, 215, 180 } } or nil,
                },
            },
        },
    }

    -- ── 3) 高频操作：2x2 网格（48%宽·74px·橙色边框·价格+收益预期） ──
    local gridRow1 = {}
    table.insert(gridRow1, GridBtn {
        title = "逛集市", price = "$50",
        reward = "↑ 人流 / 库存",
        disabled = noAP or playerData_.money < 50,
        reason = playerData_.money < 50 and "余额不足" or nil,
        onClick = function() DoVisitMarket() end,
    })
    table.insert(gridRow1, GridBtn {
        title = "贴传单", price = "$30",
        reward = "↑ 声望 / 曝光",
        disabled = noAP or playerData_.money < 30,
        reason = playerData_.money < 30 and "余额不足" or nil,
        onClick = function() DoPostFlyers() end,
    })

    local gridRow2 = {}
    if #CANDIDATE_POOL > 0 then
        local isFull = #teamMembers_ >= 5
        table.insert(gridRow2, GridBtn {
            title = isFull and "替换队员" or "招募队员", price = "$200",
            reward = isFull and "↑ 战力" or "↑ 队伍人数",
            disabled = noAP or playerData_.money < 200,
            reason = playerData_.money < 200 and "余额不足" or nil,
            onClick = function() ScoutRecruit() end,
        })
    end
    local matchDisableReason = nil
    if #teamMembers_ < 2 then matchDisableReason = "需2名队员"
    elseif friendlyMatchToday_ then matchDisableReason = "今日已赛" end
    table.insert(gridRow2, GridBtn {
        title = "比赛",
        reward = "↑ 奖金 / 声望",
        disabled = noAP or #teamMembers_ < 2 or friendlyMatchToday_,
        reason = matchDisableReason,
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
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { 240, 180, 50, 40 },
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
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = {
                UI.Label { text = "选择比赛游戏", fontSize = 13, fontColor = C.accent },
                table.unpack(gameBtns),
            },
        }
    end

    -- ── 3.8) 网吧实况（独立居中按钮，免费查看） ──
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
                btnText = btnText .. "（" .. pendingCafe .. "件待处理！）"
            else
                btnText = btnText .. "（" .. totalCafe .. "件）"
            end
            cafePanel = UI.Panel {
                width = "100%", height = 44, borderRadius = PX.radius,
                backgroundColor = pendingCafe > 0 and C.cardAlt or C.card,
                borderWidth = PX.border,
                borderColor = pendingCafe > 0 and { C.accent[1], C.accent[2], C.accent[3], 120 } or C.border,
                justifyContent = "center", alignItems = "center",
                onClick = function()
                    cafeViewOpen_ = true
                    AutoResolveCafeEvents()
                    PlaySFX("click")
                    BuildUI()
                end,
                children = {
                    UI.Label {
                        text = btnText, fontSize = 14, fontWeight = "bold",
                        fontColor = pendingCafe > 0 and C.accent or C.textDim,
                    },
                },
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
    -- 广告：免费招募队员
    if #CANDIDATE_POOL > 0 and AdManager.CanWatch("recruit_discount", playerData_.day) then
        local adLabel = #teamMembers_ >= 5 and "看视频免费替换队员（省$200）" or "看视频免费招募一次（省$200）"
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "recruit_discount", day = playerData_.day,
            text = adLabel, height = 38, fontSize = 12,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
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
            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 40 }, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 120 },
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
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = playerData_.money >= cost and { 60, 45, 20, 220 } or { 50, 45, 40, 200 },
                                fontColor = playerData_.money >= cost and { 255, 230, 150, 255 } or { 130, 115, 100, 180 },
                                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 60 },
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
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 },
                                fontColor = { 255, 230, 150, 255 },
                                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
                                    flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                    backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                    fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                    borderWidth = PX.border, borderColor = { C.green[1], C.green[2], C.green[3], 60 },
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
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                borderWidth = PX.border, borderColor = { C.green[1], C.green[2], C.green[3], 80 },
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
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
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
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
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
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
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
                    width = "100%", height = 36, fontSize = 12, borderRadius = PX.radius,
                    backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, fontColor = { 255, 220, 100, 255 },
                    borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 100 },
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
                width = "100%", height = 70, fontSize = 13, borderRadius = PX.radius,
                backgroundColor = C.accentLight, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
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
            text = "← 取消", width = "100%", height = 36, fontSize = 13, borderRadius = PX.radius,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 0; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.accentLight, borderRadius = PX.cardRadius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
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
                width = "100%", height = 56, fontSize = 13, borderRadius = PX.radius,
                backgroundColor = C.cardAlt, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 80 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    PlaySFX("upgrade")
                    DoOpenBranch(branchOpenSelLoc_, game)
                end,
            })
        end
        table.insert(gameBtns, UI.Button {
            text = "← 重选城市", width = "100%", height = 36, fontSize = 13, borderRadius = PX.radius,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 1; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = gameBtns,
        })
    end

    -- ── 5) 章节推进（条件达成时显示醒目横幅） ──
    local chapterAdvBanner = nil
    if canAdv and hasNext then
        local nextChName = (CHAPTERS[nextCh] and CHAPTERS[nextCh].name) or ("第" .. nextCh .. "章")
        chapterAdvBanner = UI.Panel {
            width = "100%", borderRadius = 14, overflow = "hidden",
            -- 深蓝棕色，与游戏主题棕金调和谐
            backgroundColor = { 35, 55, 80, 255 },
            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 160 },
            onClick = function()
                if transition_.active then return end
                PlaySFX("upgrade")
                StartChapterWithTransition(nextCh)
            end,
            children = {
                -- 装饰条（金色）
                UI.Panel {
                    width = "100%", height = 3,
                    backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 200 },
                },
                UI.Panel {
                    width = "100%", padding = 12, gap = 4,
                    flexDirection = "row", alignItems = "center",
                    children = {
                        UI.Panel {
                            width = 40, height = 40, borderRadius = 20,
                            backgroundColor = { 50, 80, 110, 255 },
                            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 120 },
                            justifyContent = "center", alignItems = "center",
                            children = { UI.Label { text = "🚀", fontSize = 20, textAlign = "center" } },
                        },
                        UI.Panel {
                            flex = 1, marginLeft = 10, gap = 2,
                            children = {
                                UI.Label { text = "章节解锁！进入" .. nextChName,
                                    fontSize = 15, fontWeight = "bold",
                                    fontColor = { C.gold[1], C.gold[2], C.gold[3], 255 } },
                                UI.Label { text = "点击此处开启新篇章 ▶",
                                    fontSize = 12, fontColor = { C.gold[1], C.gold[2], C.gold[3], 180 } },
                            },
                        },
                    },
                },
            },
        }
    elseif hasNext and advReason ~= "" then
        -- 尚未解锁：灰色进度提示
        chapterAdvBanner = UI.Panel {
            width = "100%", borderRadius = 12, padding = 10,
            backgroundColor = { 40, 38, 34, 200 },
            borderWidth = 1, borderColor = { C.border[1], C.border[2], C.border[3], 80 },
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = "🔒", fontSize = 16 },
                UI.Label { text = "解锁" .. ((CHAPTERS[nextCh] and CHAPTERS[nextCh].name) or ("第"..nextCh.."章")) .. "：" .. advReason,
                    fontSize = 11, fontColor = C.textDim, flex = 1 },
            },
        }
    end

    -- （已精简：移除夜间加练和日结奖金广告，只保留翻倍收入和额外AP，减少广告干扰）

    -- ── 辅助：分区标题 ──
    local function SectionTitle(icon, title)
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            paddingTop = 2, paddingBottom = 1,
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

    -- 结束今天（置顶，参考图样式）
    table.insert(cardChildren, endDayBtn)

    -- 章节推进横幅（条件满足时紧接结束今天显示）
    if chapterAdvBanner then table.insert(cardChildren, chapterAdvBanner) end

    -- 加班区（方案B）— adDoubleIncome 已由顶部 adBanner 展示，此处不重复
    if adExtraAP then table.insert(cardChildren, adExtraAP) end
    if overtimeBtn then table.insert(cardChildren, overtimeBtn) end

    -- 委托
    if questPanel then table.insert(cardChildren, questPanel) end

    -- 核心经营（集市/传单/招募/比赛）
    table.insert(cardChildren, gridPanel)
    if tierPanel then table.insert(cardChildren, tierPanel) end
    if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end

    -- 设备维护区块
    if #maintActions > 0 then
        table.insert(cardChildren, SectionTitle("🔧", "设备维护"))
        local mp = SectionPanel(maintActions)
        if mp then table.insert(cardChildren, mp) end
    end

    -- 副业赚钱区块（双列网格）
    if #sideJobActions > 0 then
        table.insert(cardChildren, SectionTitle("💼", "副业赚钱"))
        local sideRows = {}
        local i = 1
        while i <= #sideJobActions do
            local cells = { UI.Panel { flex = 1, children = { sideJobActions[i] } } }
            if sideJobActions[i + 1] then
                table.insert(cells, UI.Panel { flex = 1, children = { sideJobActions[i + 1] } })
            else
                table.insert(cells, UI.Panel { flex = 1 })  -- 占位，保持网格对齐
            end
            table.insert(sideRows, UI.Panel {
                width = "100%", flexDirection = "row", gap = 6,
                children = cells,
            })
            i = i + 2
        end
        table.insert(cardChildren, UI.Panel { width = "100%", gap = 6, children = sideRows })
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

    -- ── 日记模块（按天分组，近5天，各天可独立展开/收起） ──
    do
        -- P0-1 新手引导 step3：日记渲染即表示玩家看到了日记，自动完成
        if (playerData_.tutorialStep or 0) == 3 then
            playerData_.tutorialStep = 99
            AddLog("🎉 【引导完成】你已掌握网吧经营基础！升级·比赛·招募，尽情探索吧！")
        end

        local currentDay = playerData_.day or 1
        -- 确保当天有条目
        if not diaryEntries_[currentDay] then
            local ok2, atmo2 = pcall(GetAtmosphere)
            diaryEntries_[currentDay] = { atmo = (ok2 and atmo2 or ""), logs = {} }
        end
        -- 刷新当天氛围（可能在同一天多次打开）
        local ok, atmosText = pcall(GetAtmosphere)
        if ok and atmosText and atmosText ~= "" then
            diaryEntries_[currentDay].atmo = atmosText
        end

        -- 收集所有天数，倒序，取近5天
        local allDays = {}
        for d, _ in pairs(diaryEntries_) do table.insert(allDays, d) end
        table.sort(allDays, function(a, b) return a > b end)
        local recentDays = {}
        for i = 1, math.min(5, #allDays) do recentDays[i] = allDays[i] end

        if #recentDays > 0 then
            table.insert(cardChildren, SectionTitle("📖", "店长日记"))

            for _, day in ipairs(recentDays) do
                local entry = diaryEntries_[day]
                local isToday = (day == currentDay)
                local isExpanded = expandedDiaryDays_[day] == true

                -- 摘要文字
                local summary = ""
                if entry.atmo and entry.atmo ~= "" then
                    local charCount, bytePos = 0, 1
                    while charCount < 25 and bytePos <= #entry.atmo do
                        local b = string.byte(entry.atmo, bytePos)
                        if b < 128 then bytePos = bytePos + 1
                        elseif b < 224 then bytePos = bytePos + 2
                        elseif b < 240 then bytePos = bytePos + 3
                        else bytePos = bytePos + 4 end
                        charCount = charCount + 1
                    end
                    summary = bytePos <= #entry.atmo and string.sub(entry.atmo, 1, bytePos - 1) .. "…" or entry.atmo
                end
                local logCount = (entry.logs and #entry.logs) or 0
                local logHint = logCount > 0 and ("  " .. logCount .. "条记录") or ""

                local cardBg = isToday and (C.diary_today or { 93, 67, 54, 255 }) or (C.diary_past or { 62, 48, 38, 245 })
                local borderCol = isToday and { C.accent[1], C.accent[2], C.accent[3], 60 } or { C.border[1], C.border[2], C.border[3], 50 }
                local dayLabel = "D" .. day .. (isToday and "（今天）" or "")
                local dayNum = day

                -- 日记卡片子元素
                local diaryCardChildren = {}

                -- 头部行：日期 + 展开/收起
                table.insert(diaryCardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center",
                    justifyContent = "space-between",
                    children = {
                        UI.Panel {
                            flexDirection = "row", alignItems = "center", gap = 5, flexShrink = 1,
                            children = {
                                UI.Label { text = isToday and "●" or "○", fontSize = 10,
                                    fontColor = isToday and C.accent or C.textLight },
                                UI.Label { text = dayLabel, fontSize = 12, fontWeight = "bold",
                                    fontColor = isToday and C.accent or C.textDim },
                            },
                        },
                        UI.Label { text = isExpanded and "▲" or "▼", fontSize = 10, fontColor = C.textLight },
                    },
                })

                if isExpanded then
                    -- 展开：氛围 + 日志
                    local contentChildren = {}
                    if entry.atmo and entry.atmo ~= "" then
                        table.insert(contentChildren, UI.Label {
                            text = entry.atmo, fontSize = 12, fontColor = { 253, 245, 230, 180 },
                            whiteSpace = "normal", lineHeight = 1.5, width = "100%",
                        })
                    end
                    if entry.logs and #entry.logs > 0 then
                        if entry.atmo and entry.atmo ~= "" then
                            table.insert(contentChildren, UI.Panel {
                                width = "100%", height = 1, marginVertical = 4,
                                backgroundColor = { 210, 180, 140, 40 },
                            })
                        end
                        for _, logText in ipairs(entry.logs) do
                            table.insert(contentChildren, UI.Label {
                                text = logText, fontSize = 11, fontColor = C.textDim,
                                whiteSpace = "normal", lineHeight = 1.3, width = "100%",
                            })
                        end
                    end
                    if #contentChildren == 0 then
                        table.insert(contentChildren, UI.Label {
                            text = isToday and "今天的故事还在书写中……" or "平淡的一天。",
                            fontSize = 11, fontColor = C.textLight,
                        })
                    end
                    table.insert(diaryCardChildren, UI.Panel {
                        width = "100%", gap = 3, paddingTop = 4,
                        children = contentChildren,
                    })
                else
                    -- 收起：一行摘要
                    if summary ~= "" or logHint ~= "" then
                        table.insert(diaryCardChildren, UI.Label {
                            text = (summary ~= "" and summary or "平淡的一天") .. logHint,
                            fontSize = 11, fontColor = C.textLight, whiteSpace = "nowrap",
                            paddingTop = 2,
                        })
                    end
                end

                table.insert(cardChildren, UI.Panel {
                    width = "100%", padding = 8, gap = 2,
                    backgroundColor = cardBg, borderRadius = PX.radius,
                    borderWidth = 1, borderColor = borderCol,
                    onClick = function()
                        expandedDiaryDays_[dayNum] = not expandedDiaryDays_[dayNum]
                        BuildUI()
                    end,
                    children = diaryCardChildren,
                })
            end
        end
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 8,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = cardChildren,
    }
end

--- 精简版行动区（用于沉浸式全景布局，移除已在热区的操作）
function BuildCompactActions()
    local nextCh = currentChapter_ + 1
    local hasNext = nextCh <= #CHAPTERS
    local canAdv, advReason = false, ""
    if hasNext then
        if nextCh == 2 and #teamMembers_ >= 1 and playerData_.day >= 4 then canAdv = true
        elseif nextCh == 3 and #teamMembers_ >= 2 and GetTeamAvgSkill() >= 30 then canAdv = true
        elseif nextCh == 4 and playerData_.day >= 14 and playerData_.reputation >= 80 then canAdv = true
        elseif nextCh == 5 and playerData_.day >= 18 and (playerData_.tournamentWins or 0) >= 1 then canAdv = true
        elseif nextCh > 5 then canAdv = true
        end
        if not canAdv then
            if nextCh == 2 then advReason = "第二章（第4天 + 队员1人）"
            elseif nextCh == 3 then advReason = "第三章（队员2人 + 平均技术30）"
            elseif nextCh == 4 then advReason = "第四天（第14天 + 声望80）"
            elseif nextCh == 5 then advReason = "第五章（第18天 + 赢过1次锦标赛）"
            end
        end
    end

    local ap = playerData_.actionPoints
    local noAP = ap <= 0

    -- ── 辅助：紧凑行动按钮 ──
    local function ActionBtn(props)
        if props.variant then
            return UI.Button {
                text = props.text, width = props.width or "100%",
                height = props.height or 38, fontSize = 13, borderRadius = PX.radius,
                disabled = props.disabled, variant = props.variant, flex = props.flex,
                onClick = props.onClick,
            }
        end
        return UI.Button {
            text = props.text, width = props.width or "100%",
            height = props.height or 38, fontSize = 13, fontWeight = "bold", borderRadius = PX.radius,
            backgroundColor = props.disabled and { 50, 44, 40, 255 } or C.card,
            fontColor = props.disabled and C.textLight or C.text,
            borderWidth = PX.border,
            borderColor = props.disabled and C.border or (props.borderColor or C.accent),
            disabled = props.disabled, flex = props.flex,
            onClick = props.onClick,
        }
    end

    -- ── 次要状态标签行（从旧StatusBar移来） ──
    local tagItems = {}
    local ec = playerData_.equipCondition or 100
    table.insert(tagItems, UI.Label {
        text = "维护" .. ec .. "%", fontSize = 10,
        fontColor = ec <= 30 and C.red or (ec <= 50 and C.gold or C.textLight),
    })
    local karmaVal = playerData_.karma or 0
    local karmaTag = (karmaVal >= 4 and "善" or (karmaVal <= -3 and "恶" or "中")) .. karmaVal
    table.insert(tagItems, UI.Label {
        text = karmaTag, fontSize = 10,
        fontColor = karmaVal >= 4 and C.green or (karmaVal <= -3 and C.red or C.textLight),
    })
    local repStr = playerData_.reputation >= 100000 and string.format("%.1fK", playerData_.reputation / 1000) or tostring(playerData_.reputation)
    table.insert(tagItems, UI.Label { text = "Rep" .. repStr, fontSize = 10, fontColor = C.gold })
    local goldOz = playerData_.goldOunces or 0
    if goldOz > 0 then
        table.insert(tagItems, UI.Label {
            text = "Au" .. string.format("%.1f", goldOz) .. "oz", fontSize = 10, fontColor = C.gold,
        })
    end
    local branchCount = #(playerData_.branches or {})
    if branchCount > 0 then
        table.insert(tagItems, UI.Label { text = "分店x" .. branchCount, fontSize = 10, fontColor = C.textDim })
    end

    local tagRow = UI.Panel {
        width = "100%", flexDirection = "row", flexWrap = "wrap",
        gap = 8, paddingHorizontal = 4, paddingVertical = 4,
        backgroundColor = C.cardAlt, borderRadius = PX.radius,
        children = tagItems,
    }

    -- ── 结束今天（像素凸起感） ──
    local noAP2 = (playerData_.actionPoints or 3) <= 0
    local endBotColor2 = noAP2 and { 20, 90, 38, 255 } or { 90, 58, 10, 255 }
    local endBgColor2  = noAP2 and { 45, 158, 72, 255 } or { 170, 115, 28, 255 }
    local endBorderHi2 = noAP2 and { 100, 220, 130, 200 } or { 230, 185, 75, 200 }
    local endMainText2 = noAP2 and "✅ 结束今天" or ("结束今天  (第" .. (playerData_.day or 1) .. "天)")
    local endDayBtn = UI.Panel {
        width = "100%", height = 44, borderRadius = PX.cardRadius,
        backgroundColor = endBotColor2,
        justifyContent = "center", alignItems = "center",
        onClick = function()
            if transition_.active then return end
            PlaySFX("click")
            local ok, err = pcall(EndDay)
            if not ok then
                log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
        end,
        children = {
            UI.Panel {
                width = "100%", height = 41, borderRadius = PX.cardRadius,
                backgroundColor = endBgColor2,
                borderWidth = 2, borderColor = endBorderHi2,
                flexDirection = "row", justifyContent = "center", alignItems = "center",
                paddingHorizontal = 12, gap = 8,
                children = {
                    UI.Label { text = noAP2 and "✅ 结束今天" or endMainText2,
                        fontSize = 15, fontWeight = "bold",
                        fontColor = { 245, 255, 245, 255 } },
                    noAP2 and UI.Label { text = "行动点已用完·进入明天",
                        fontSize = 10, fontColor = { 205, 248, 215, 180 } } or nil,
                },
            },
        },
    }

    -- ── 广告区 ──
    local adDoubleIncome = nil
    local lastNet = playerData_.lastNetIncome or 0
    if AdManager.CanWatch("double_income", playerData_.day) then
        local bonus = lastNet > 0 and lastNet or math.max(50, math.floor(playerData_.day * 8))
        local label = lastNet > 0
            and ("看广告翻倍昨日收入 +$" .. bonus)
            or  ("看广告领经营补贴 +$" .. bonus)
        adDoubleIncome = AdManager.AdButton {
            sceneId = "double_income", day = playerData_.day,
            text = label, height = 36, fontSize = 12,
            onReward = function()
                playerData_.money = playerData_.money + bonus
                playerData_.totalEarnings = (playerData_.totalEarnings or 0) + bonus
                playerData_.lastNetIncome = 0
                AddLog("🎬 赞助商追加了经营奖励！额外获得$" .. bonus .. "！")
                BuildUI()
            end,
        }
    end

    local adExtraAP = nil
    if noAP and AdManager.CanWatch("extra_ap", playerData_.day) then
        adExtraAP = AdManager.AdButton {
            sceneId = "extra_ap", day = playerData_.day,
            text = "看视频多干一件事 +1AP", height = 36, fontSize = 12,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                BuildUI()
            end,
        }
    end

    -- 方案B: 加班按钮（精简版，BuildCompactActions 里）
    local overtimeBtn = nil
    if noAP and not (playerData_.overtimeUsedToday) and not adExtraAP then
        local canAfford = (playerData_.money or 0) >= 30
        overtimeBtn = UI.Button {
            text = canAfford and "加班 -$30 -耐久5 → +1AP" or "加班需 $30（余额不足）",
            width = "100%", height = 40, fontSize = 12, fontWeight = "bold",
            backgroundColor = canAfford and { 50, 35, 18, 255 } or { 35, 28, 20, 255 },
            fontColor = canAfford and { 230, 170, 60, 255 } or { 90, 78, 60, 200 },
            borderWidth = PX.border,
            borderColor = canAfford and { 180, 130, 40, 200 } or { 70, 60, 45, 150 },
            borderRadius = PX.radius,
            disabled = not canAfford,
            onClick = canAfford and function()
                playerData_.money = playerData_.money - 30
                playerData_.actionPoints = (playerData_.actionPoints or 0) + 1
                playerData_.overtimeUsedToday = true
                playerData_.endOfDayDurPenalty = (playerData_.endOfDayDurPenalty or 0) + 5
                AddLog("🌙 【加班】透支精力——$30 + 设备多跑一小时，换来1点行动力")
                BuildUI()
            end or nil,
        }
    end

    -- ── 每日委托（Day15+ 显示委托板精简版） ──
    local questPanel = nil
    if dailyQuest_ and playerData_.day >= 10 then
        CheckQuestProgress()

        -- 精简委托行构建函数
        local function QuestRow(q, slotIdx, label)
            local done = q.progress >= q.goal
            local progressText = done and "✅" or (q.progress .. "/" .. q.goal)
            local rowChildren = {
                UI.Label { text = q.icon or "📋", fontSize = 13, flexShrink = 0 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = label .. ": " .. q.desc, fontSize = 11,
                        fontColor = C.text, whiteSpace = "normal" },
                    UI.Label { text = "奖励: " .. q.rewardDesc, fontSize = 10,
                        fontColor = C.textDim },
                }},
                UI.Label { text = progressText, fontSize = 11,
                    fontColor = done and C.green or C.textDim, flexShrink = 0 },
            }
            if done and not q.claimed then
                table.insert(rowChildren, UI.Button {
                    text = "领取", width = 46, height = 26, fontSize = 10,
                    borderRadius = 5, backgroundColor = { 65, 55, 40, 255 },
                    fontColor = C.gold, flexShrink = 0,
                    onClick = function()
                        if slotIdx == 1 then ClaimQuestReward()
                        else pcall(ClaimBoardQuestReward, slotIdx) end
                        BuildUI()
                    end,
                })
            end
            return UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                paddingHorizontal = 8, paddingVertical = 5,
                backgroundColor = done and not q.claimed
                    and { 50, 44, 20, 220 } or C.cardAlt,
                borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 35 },
                children = rowChildren,
            }
        end

        if playerData_.day >= 15 and dailyQuestBoard_ and #dailyQuestBoard_ >= 1 then
            -- 委托板精简视图
            local rows = {}
            local labels = { "主委托", "快速", "快速" }
            for i, q in ipairs(dailyQuestBoard_) do
                if q then table.insert(rows, QuestRow(q, i, labels[i] or "委托")) end
            end
            local streak = playerData_.questStreak or 0
            questPanel = UI.Panel {
                width = "100%", paddingHorizontal = 8, paddingVertical = 8,
                backgroundColor = C.cardAlt, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 40 },
                gap = 4,
                children = {
                    UI.Panel {
                        flexDirection = "row", justifyContent = "space-between",
                        alignItems = "center", width = "100%",
                        children = {
                            UI.Label { text = "📋 委托板", fontSize = 12, fontColor = C.gold },
                            streak >= 1 and UI.Label {
                                text = "🔥x" .. streak, fontSize = 11,
                                fontColor = { 255, 200, 60, 255 },
                            } or UI.Panel { width = 0, height = 0 },
                        },
                    },
                    table.unpack(rows),
                },
            }
        else
            questPanel = QuestRow(dailyQuest_, 1, "今日委托")
        end
    end

    -- ── 精简网格：只保留贴传单+比赛（逛集市/招募已在热区） ──
    local function GridBtn(props)
        local disabled = props.disabled
        local btnChildren = {
            UI.Label { text = props.title, fontSize = 13, fontWeight = "bold",
                fontColor = disabled and { 110, 95, 80, 255 } or C.text },
        }
        if props.price then
            table.insert(btnChildren, UI.Label { text = props.price, fontSize = 11,
                fontColor = disabled and { 90, 78, 65, 255 } or C.gold })
        end
        if props.reward and not disabled then
            table.insert(btnChildren, UI.Label { text = props.reward, fontSize = 9,
                fontColor = { 130, 200, 140, 200 } })
        end
        if props.reason and disabled then
            table.insert(btnChildren, UI.Label { text = props.reason, fontSize = 9,
                fontColor = { 120, 100, 80, 200 } })
        end
        return UI.Panel {
            width = "48%", height = 68, borderRadius = PX.radius,
            backgroundColor = disabled and { 48, 40, 34, 255 } or C.card,
            borderWidth = PX.border, borderColor = disabled and C.border or C.accent,
            justifyContent = "center", alignItems = "center", gap = 1,
            onClick = not disabled and props.onClick or nil,
            children = btnChildren,
        }
    end

    local gridItems = {}
    table.insert(gridItems, GridBtn {
        title = "贴传单", price = "$30",
        reward = "↑ 声望 / 曝光",
        disabled = noAP or playerData_.money < 30,
        reason = playerData_.money < 30 and "余额不足" or nil,
        onClick = function() DoPostFlyers() end,
    })
    local matchReason2 = nil
    if #teamMembers_ < 2 then matchReason2 = "需2名队员"
    elseif friendlyMatchToday_ then matchReason2 = "今日已赛" end
    table.insert(gridItems, GridBtn {
        title = "比赛",
        reward = "↑ 奖金 / 声望",
        disabled = noAP or #teamMembers_ < 2 or friendlyMatchToday_,
        reason = matchReason2,
        onClick = function()
            matchTierSelect_ = not matchTierSelect_
            PlaySFX("click"); BuildUI()
        end,
    })

    local gridPanel = UI.Panel {
        width = "100%", flexDirection = "row", gap = 8, justifyContent = "space-between",
        children = gridItems,
    }

    -- ── 比赛等级选择（复用原逻辑） ──
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
                    disabled = not canAfford,
                    onClick = function()
                        matchTierSelect_ = false
                        pendingMatchTier_ = i
                        matchGameSelect_ = true
                        PlaySFX("click"); BuildUI()
                    end,
                })
            else
                table.insert(tierBtns, ActionBtn { text = "" .. tier.unlockDesc, disabled = true })
            end
        end
        -- 锦标赛入口
        if chaptersRead_[3] then
            local tWinsMap = playerData_.tournamentTierWins or {}
            table.insert(tierBtns, UI.Panel { height = 2, width = "90%", backgroundColor = { 220, 165, 30, 100 } })
            table.insert(tierBtns, UI.Label { text = "── 锦标赛 ──", fontSize = 11, fontColor = C.gold, textAlign = "center" })
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
                    table.insert(tierBtns, ActionBtn {
                        text = tt.name .. " $" .. tt.cost .. record,
                        disabled = not canAffordT,
                        onClick = function()
                            matchTierSelect_ = false
                            PlaySFX("click")
                            playerData_.money = playerData_.money - tt.cost
                            isFriendlyMatch_ = false
                            currentTournamentTier_ = ti
                            matchGameType_ = nil
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
                    table.insert(tierBtns, ActionBtn { text = "" .. tt.unlockDesc, disabled = true })
                end
            end
        end
        tierPanel = UI.Panel {
            width = "100%", padding = 8, gap = 4,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = tierBtns,
        }
    end

    -- ── 游戏选择面板 ──
    local gameSelectPanel = nil
    if matchGameSelect_ and pendingMatchTier_ then
        local gameBtns = {}
        for _, gt in ipairs(GAME_TYPES) do
            table.insert(gameBtns, ActionBtn {
                text = gt.name .. " (" .. gt.desc .. ")",
                onClick = function()
                    matchGameType_ = gt
                    matchGameSelect_ = false
                    PlaySFX("click")
                    DoHostTournament(pendingMatchTier_)
                end,
            })
        end
        table.insert(gameBtns, UI.Label {
            text = "选择参赛游戏类型", fontSize = 10, fontColor = C.textDim, textAlign = "center",
        })
        table.insert(gameBtns, ActionBtn {
            text = "← 返回选等级", variant = "secondary",
            onClick = function()
                matchGameSelect_ = false; pendingMatchTier_ = nil; matchTierSelect_ = true
                PlaySFX("click"); BuildUI()
            end,
        })
        gameSelectPanel = UI.Panel {
            width = "100%", padding = 8, gap = 4,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = { UI.Label { text = "选择比赛游戏", fontSize = 12, fontColor = C.accent }, table.unpack(gameBtns) },
        }
    end

    -- ── 章节推进（条件达成时显示醒目横幅） ──
    local chapterAdvBanner = nil
    if canAdv and hasNext then
        local nextChName = (CHAPTERS[nextCh] and CHAPTERS[nextCh].name) or ("第" .. nextCh .. "章")
        chapterAdvBanner = UI.Panel {
            width = "100%", borderRadius = 14, overflow = "hidden",
            backgroundColor = { 35, 55, 80, 255 },
            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 160 },
            onClick = function()
                if transition_.active then return end
                PlaySFX("upgrade")
                StartChapterWithTransition(nextCh)
            end,
            children = {
                UI.Panel { width = "100%", height = 3, backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 200 } },
                UI.Panel {
                    width = "100%", padding = 12, gap = 4,
                    flexDirection = "row", alignItems = "center",
                    children = {
                        UI.Panel {
                            width = 40, height = 40, borderRadius = 20,
                            backgroundColor = { 50, 80, 110, 255 },
                            justifyContent = "center", alignItems = "center",
                            children = { UI.Label { text = "🚀", fontSize = 20, textAlign = "center" } },
                        },
                        UI.Panel {
                            flex = 1, marginLeft = 10, gap = 2,
                            children = {
                                UI.Label { text = "章节解锁！进入" .. nextChName,
                                    fontSize = 15, fontWeight = "bold",
                                    fontColor = { C.gold[1], C.gold[2], C.gold[3], 255 } },
                                UI.Label { text = "点击此处开启新篇章 ▶",
                                    fontSize = 12, fontColor = { C.gold[1], C.gold[2], C.gold[3], 180 } },
                            },
                        },
                    },
                },
            },
        }
    elseif hasNext and advReason ~= "" then
        chapterAdvBanner = UI.Panel {
            width = "100%", borderRadius = 12, padding = 10,
            backgroundColor = { 40, 38, 34, 200 },
            borderWidth = 1, borderColor = { C.border[1], C.border[2], C.border[3], 80 },
            flexDirection = "row", alignItems = "center", gap = 8,
            children = {
                UI.Label { text = "🔒", fontSize = 16 },
                UI.Label { text = "解锁" .. ((CHAPTERS[nextCh] and CHAPTERS[nextCh].name) or ("第"..nextCh.."章")) .. "：" .. advReason,
                    fontSize = 11, fontColor = C.textDim, flex = 1 },
            },
        }
    end

    -- ── 分区辅助 ──
    local function SectionTitle(icon, title)
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            paddingTop = 2, paddingBottom = 1,
            children = {
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
                UI.Label { text = icon .. " " .. title, fontSize = 11, fontColor = C.textDim, flexShrink = 0 },
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
            },
        }
    end

    -- ── 设备维护（复用原逻辑） ──
    local maintActions = {}
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 then
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        local fuelCost = 8 * (cap - fuel)
        if fuel < cap then
            fuelCost = math.min(fuelCost, math.max(30, fuelCost))
            local buyAmount = cap - fuel
            table.insert(maintActions, ActionBtn {
                text = "买燃油 +" .. buyAmount .. "L $" .. fuelCost .. " (" .. fuel .. "/" .. cap .. "L)",
                disabled = playerData_.money < fuelCost,
                onClick = function() DoBuyFuel() end,
            })
        else
            table.insert(maintActions, UI.Label {
                text = "燃油已满 " .. fuel .. "/" .. cap .. "L", fontSize = 12, fontColor = C.green,
            })
        end
    end
    local cond = playerData_.equipCondition or 100
    if cond < 95 then
        local repairCost = 50 + playerData_.computers * 10
        table.insert(maintActions, ActionBtn {
            text = "维修设备 $" .. repairCost .. " (" .. string.format("%.1f", cond) .. "%)",
            disabled = noAP or playerData_.money < repairCost,
            onClick = function() DoRepairEquipment() end,
        })
        if AdManager.CanWatch("free_repair", playerData_.day) then
            table.insert(maintActions, AdManager.AdButton {
                sceneId = "free_repair", day = playerData_.day,
                text = "看视频免费维修 省$" .. repairCost,
                height = 34, fontSize = 11,
                onReward = function()
                    local before = playerData_.equipCondition or 0
                    playerData_.equipCondition = math.min(100, before + 30)
                    AddLog("🎬 赞助商派技术团队免费维护！" .. before .. "%→" .. playerData_.equipCondition .. "%")
                    BuildUI()
                end,
            })
        end
    end

    -- ── 副业（移除修手机，已在热区） ──
    local sideJobActions = {}
    if #teamMembers_ >= 1 then
        table.insert(sideJobActions, ActionBtn {
            text = "代练服务 AP1", disabled = noAP,
            onClick = function() DoBoostingService() end,
        })
    end
    if #teamMembers_ >= 2 and playerData_.netSpeed >= 2 then
        table.insert(sideJobActions, ActionBtn {
            text = "直播跑刀三角洲 AP1", disabled = noAP,
            onClick = function() DoStreamDeltaForce() end,
        })
    end
    if playerData_.computers >= 4 then
        table.insert(sideJobActions, ActionBtn {
            text = "接包场活动 AP1", disabled = noAP,
            onClick = function() DoCafeRental() end,
        })
    end
    if playerData_.day >= 7 then
        table.insert(sideJobActions, ActionBtn {
            text = "逛二手淘宝 AP1", disabled = noAP or playerData_.money < 50,
            onClick = function() DoSecondHandMarket() end,
        })
    end

    -- ── 社交 ──
    local socialActions = {}
    if #teamMembers_ > 0 then
        table.insert(socialActions, ActionBtn {
            text = "请队员吃烤肉 ($60) AP1",
            disabled = noAP or playerData_.money < 60,
            onClick = function() DoTeamBBQ() end,
        })
    end
    -- 广告：免费招募队员
    if #CANDIDATE_POOL > 0 and AdManager.CanWatch("recruit_discount", playerData_.day) then
        local adLabel = #teamMembers_ >= 5 and "看视频免费替换队员（省$200）" or "看视频免费招募一次（省$200）"
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "recruit_discount", day = playerData_.day,
            text = adLabel, height = 34, fontSize = 11,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商赞助了招募费用！这次找人不花钱！")
                ScoutRecruit()
            end,
        })
    end
    if AdManager.CanWatch("reputation_ad", playerData_.day) then
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "reputation_ad", day = playerData_.day,
            text = "接受媒体采访 声望+20", height = 34, fontSize = 11,
            onReward = function()
                playerData_.reputation = playerData_.reputation + 20
                AddLog("🎬 赞助商安排了媒体采访！声望+20")
                BuildUI()
            end,
        })
    end

    -- ── 扩张 ──
    local expandActions = {}
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
            fontSize = 13, fontColor = C.red, paddingLeft = 4,
        })
    end
    local nextBranchCost = BRANCH_COSTS[branchCount + 1] or 9000
    local canBranch = playerData_.money >= 8000 and branchCount < 3
    if canBranch and branchOpenStep_ == 0 then
        table.insert(expandActions, ActionBtn {
            text = "开分店 $" .. nextBranchCost .. " (第" .. (branchCount + 1) .. "家)",
            disabled = playerData_.money < nextBranchCost,
            onClick = function()
                branchOpenLocOpts_ = RollBranchLocationOptions()
                branchOpenStep_ = 1
                PlaySFX("click"); BuildUI()
            end,
        })
    end
    -- 分店步骤1
    if branchOpenStep_ == 1 and branchOpenLocOpts_ then
        local locBtns = {
            UI.Label { text = "选择分店城市", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
        }
        for _, loc in ipairs(branchOpenLocOpts_) do
            table.insert(locBtns, UI.Button {
                text = loc.name .. "\n" .. loc.desc .. "\n" .. loc.bonusDesc,
                width = "100%", height = 60, fontSize = 12, borderRadius = PX.radius,
                backgroundColor = C.accentLight, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    branchOpenSelLoc_ = loc; branchOpenStep_ = 2
                    PlaySFX("click"); BuildUI()
                end,
            })
        end
        table.insert(locBtns, UI.Button {
            text = "← 取消", width = "100%", height = 32, fontSize = 12, borderRadius = PX.radius, variant = "secondary",
            onClick = function() branchOpenStep_ = 0; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.accentLight, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = locBtns,
        })
    end
    -- 分店步骤2
    if branchOpenStep_ == 2 and branchOpenSelLoc_ then
        local gameBtns = {
            UI.Label { text = branchOpenSelLoc_.name .. " · 选择特色游戏", fontSize = 12, fontColor = C.accent, textAlign = "center", width = "100%" },
        }
        for _, game in ipairs(BRANCH_GAMES) do
            table.insert(gameBtns, UI.Button {
                text = game.name .. " — " .. game.desc .. "\n" .. game.bonusDesc,
                width = "100%", height = 50, fontSize = 12, borderRadius = PX.radius,
                backgroundColor = C.cardAlt, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 80 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function() PlaySFX("upgrade"); DoOpenBranch(branchOpenSelLoc_, game) end,
            })
        end
        table.insert(gameBtns, UI.Button {
            text = "← 重选城市", width = "100%", height = 32, fontSize = 12, borderRadius = PX.radius, variant = "secondary",
            onClick = function() branchOpenStep_ = 1; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = gameBtns,
        })
    end

    -- ── 黄金交易（复用原逻辑，仅在第10天后显示） ──
    local goldPanel = nil
    if playerData_.day >= 10 then
        -- 委托给原 BuildActionCard 中的黄金面板太长，这里简化为入口按钮
        local goldPrice = GetGoldPrice()
        local curGold = playerData_.goldOunces or 0
        local prevPrice = GetGoldPrice((playerData_.day or 1) - 1)
        local trend = goldPrice > prevPrice and "↑" or (goldPrice < prevPrice and "↓" or "→")
        local holdText = curGold > 0 and (" 持仓" .. string.format("%.1f", curGold) .. "oz") or ""
        goldPanel = ActionBtn {
            text = trend .. " 金价$" .. goldPrice .. "/oz" .. holdText .. " (点击展开)",
            borderColor = { C.gold[1], C.gold[2], C.gold[3], 120 },
            onClick = function()
                -- 切换到原 action tab 让用户使用完整黄金面板
                goldExpanded_ = not goldExpanded_
                PlaySFX("click"); BuildUI()
            end,
        }
        -- 展开时使用完整版
        if goldExpanded_ then
            local ok, fullCard = pcall(BuildActionCard)
            if ok then return fullCard end
        end
    end

    -- ── 组装紧凑卡片 ──
    local cardChildren = {}

    -- 状态标签行
    table.insert(cardChildren, tagRow)

    -- 结束今天（最醒目）
    table.insert(cardChildren, endDayBtn)

    -- 章节推进横幅（条件满足时紧接结束今天显示）
    if chapterAdvBanner then table.insert(cardChildren, chapterAdvBanner) end

    -- 广告区
    if adDoubleIncome then table.insert(cardChildren, adDoubleIncome) end
    if adExtraAP then table.insert(cardChildren, adExtraAP) end
    if overtimeBtn then table.insert(cardChildren, overtimeBtn) end  -- 方案B: 加班按钮

    -- 委托
    if questPanel then table.insert(cardChildren, questPanel) end

    -- 贴传单+比赛
    table.insert(cardChildren, gridPanel)
    if tierPanel then table.insert(cardChildren, tierPanel) end
    if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end

    -- 分区
    if #maintActions > 0 then
        table.insert(cardChildren, SectionTitle("🔧", "设备维护"))
        for _, a in ipairs(maintActions) do table.insert(cardChildren, a) end
    end
    if #sideJobActions > 0 then
        table.insert(cardChildren, SectionTitle("💼", "副业"))
        for _, a in ipairs(sideJobActions) do table.insert(cardChildren, a) end
    end
    if #socialActions > 0 then
        table.insert(cardChildren, SectionTitle("🤝", "社交"))
        for _, a in ipairs(socialActions) do table.insert(cardChildren, a) end
    end
    if goldPanel then
        table.insert(cardChildren, SectionTitle("🥇", "黄金"))
        table.insert(cardChildren, goldPanel)
    end
    if #expandActions > 0 then
        table.insert(cardChildren, SectionTitle("🏗️", "扩张"))
        for _, a in ipairs(expandActions) do table.insert(cardChildren, a) end
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 6,
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
        backgroundColor = C.cardAlt, borderRadius = PX.radius,
        borderWidth = PX.border, borderColor = C.border,
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
            UI.Panel { width = "100%", height = 8, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = PX.radiusSm, overflow = "hidden", children = {
                UI.Panel { id = "upgrade-progress-fill", width = math.floor(pct * 100) .. "%", height = "100%", backgroundColor = C.green, borderRadius = PX.radiusSm },
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
        backgroundColor = bgColor, borderRadius = PX.radius,
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
            width = 8, height = 4, borderRadius = PX.radiusSm,
            backgroundColor = i <= cur and { 190, 148, 50, 240 } or C.border,
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
            -- P1: 员工建议折扣
            local discPct, discWho = 0, nil
            local okDisc, dp, dw = pcall(GetStaffDiscountForUpgrade, key)
            if okDisc and dp and dp > 0 then discPct, discWho = dp, dw end
            if discPct > 0 then
                table.insert(bottomRow, UpgradePill("", costText,
                    { 80, 80, 70, 60 }, { 160, 150, 130, 160 }))
                table.insert(bottomRow, UpgradePill("", "-" .. discPct .. "% " .. (discWho or "员工"),
                    { 80, 180, 80, 50 }, { 120, 230, 120, 255 }))
            else
                table.insert(bottomRow, UpgradePill("", costText,
                    canAfford and { C.green[1], C.green[2], C.green[3], 40 } or { C.red[1], C.red[2], C.red[3], 40 },
                    canAfford and C.green or C.red))
            end
            table.insert(bottomRow, UpgradePill("", timeText, { 60, 80, 120, 80 }, { 160, 185, 220, 255 }))
        end
        -- 弹性占位，把按钮推到右边
        table.insert(bottomRow, UI.Panel { flex = 1 })
        table.insert(bottomRow, UI.Button {
            text = coupTag .. "升级",
            height = 28, paddingHorizontal = 16, fontSize = 12, borderRadius = PX.radius,
            disabled = hasPending or not canAfford,
            onClick = function() DoUpgrade(key) end,
        })
    end

    local borderCol = maxed and { 80, 90, 80, 80 }
        or isActive and { C.green[1], C.green[2], C.green[3], 180 }
        or (IsCoupActive() and { 220, 180, 60, 160 } or C.border)
    -- 满级：整体降低对比度，卡片变灰暗
    local cardBg = isActive and C.upgrade_active
        or (maxed and { 55, 62, 52, 200 } or C.upgrade_bg)
    local nameColor = maxed and { 130, 150, 125, 160 } or C.text

    return UI.Panel {
        width = "100%", padding = 10, gap = 5,
        backgroundColor = cardBg,
        borderRadius = PX.radius, borderWidth = maxed and PX.borderSm or PX.border, borderColor = borderCol,
        opacity = maxed and 0.65 or 1.0,
        children = {
            -- 第1行：名称缩写色块 + 名称 + 等级
            UI.Panel { flexDirection = "row", alignItems = "center", width = "100%", gap = 8, children = {
                -- 缩写色块
                UI.Panel {
                    width = 36, height = 36, borderRadius = PX.radius,
                    backgroundColor = maxed and { 80, 100, 78, 180 } or (isActive and C.gold or { 120, 90, 30, 220 }),
                    justifyContent = "center", alignItems = "center",
                    children = { UI.Label { text = (cfg.icon ~= "" and cfg.icon) or string.sub(cfg.name, 1, 3), fontSize = (cfg.icon ~= "" and 20) or 12, fontWeight = "bold", fontColor = maxed and { 160, 200, 155, 200 } or { 255, 255, 255, 255 } } },
                },
                -- 名称 + 等级条
                UI.Panel { flex = 1, gap = 3, children = {
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                        UI.Label { text = cfg.name, fontSize = 14, fontColor = nameColor, fontWeight = "bold" },
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
    if not upgradeGroupExpand_ then upgradeGroupExpand_ = {} end

    -- ── 辅助：统计满级/未满级 ──
    local allKeys = {}
    for _, k in ipairs(UPGRADE_ORDER) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_COMMUNITY) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_CULTURE) do table.insert(allKeys, k) end

    local maxedKeys = {}
    local availableKeys = {}
    for _, key in ipairs(allKeys) do
        local cfg = UPGRADES[key]
        if cfg then
            local cur = GetUpgradeCur(key)
            local maxLevels = cfg.costs and #cfg.costs or 0
            if cur >= maxLevels then
                table.insert(maxedKeys, key)
            else
                table.insert(availableKeys, key)
            end
        end
    end

    -- ══════════════════════════════════════════
    -- 网吧等级进度条（宏观目标）
    -- ══════════════════════════════════════════
    local rating = GetCafeRating()
    local starIcons = string.rep("⭐", rating.star)
    local progressPct = 0
    if rating.nextStarAt then
        -- 找当前星级的起始阈值
        local tiers = { 0, 8, 18, 30, 45 }
        local curAt = tiers[rating.star] or 0
        local range = rating.nextStarAt - curAt
        progressPct = range > 0 and math.floor((rating.totalLevel - curAt) / range * 100) or 100
    else
        progressPct = 100
    end
    local ratingSubText = rating.nextStarName
        and ("→ " .. rating.nextStarName .. " 还差" .. (rating.nextStarAt - rating.totalLevel) .. "级")
        or "已达最高等级！"

    table.insert(children, UI.Panel {
        width = "100%", gap = 4, paddingBottom = 4, children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                UI.Label { text = starIcons, fontSize = 14 },
                UI.Label { text = rating.starName, fontSize = 14, fontWeight = "bold", fontColor = C.gold },
                UI.Panel { flex = 1 },
                UI.Label { text = "Lv." .. rating.totalLevel, fontSize = 12, fontColor = C.textLight },
            }},
            UI.Panel { width = "100%", height = 6, backgroundColor = { 50, 50, 40, 180 }, borderRadius = 3, overflow = "hidden", children = {
                UI.Panel { width = math.min(100, progressPct) .. "%", height = "100%", borderRadius = 3,
                    backgroundColor = rating.nextStarName and C.gold or C.green },
            }},
            UI.Label { text = ratingSubText, fontSize = 11, fontColor = C.textDim },
        },
    })
    table.insert(children, UI.Divider { spacing = 4 })

    -- ── 正在升级的进度卡片（置顶） ──
    local progressPanel = BuildUpgradeProgressPanel()
    if progressPanel then
        table.insert(children, progressPanel)
        table.insert(children, UI.Divider { spacing = 4 })
    end

    -- ══════════════════════════════════════════
    -- 推荐升级区（瓶颈感知 + ROI 排序 + 情境文案）
    -- ══════════════════════════════════════════
    if #availableKeys > 0 and not activeUpgrade_ then
        -- 1) 检测当前瓶颈
        local traffic = RefreshTraffic()
        local capacity = CalcCafeCapacity()
        local util = traffic / math.max(1, capacity)
        local genLv = playerData_.generatorLevel or 0
        local solarLv = playerData_.solarLevel or 0
        local hasPowerProtect = (genLv >= 1 and (playerData_.fuel or 0) > 0) or solarLv >= 2

        -- 瓶颈类型判定
        local bottleneck = "balanced"  -- 默认均衡
        local bottleneckText = nil
        local bottleneckColor = C.gold
        if util >= 1.0 then
            bottleneck = "capacity"
            local overflow = math.max(0, traffic - capacity)
            bottleneckText = "🔥 客满溢出！" .. overflow .. "人在排队，扩容可直接增收"
            bottleneckColor = { 255, 120, 80, 255 }
        elseif util < 0.7 then
            bottleneck = "traffic"
            local empty = capacity - traffic
            bottleneckText = "📉 " .. empty .. "个空位没坐满，需要引流拉客"
            bottleneckColor = { 120, 180, 255, 255 }
        elseif not hasPowerProtect and playerData_.day >= 3 then
            bottleneck = "power"
            bottleneckText = "⚡ 无停电保护，15%概率收入腰斩"
            bottleneckColor = { 255, 200, 60, 255 }
        end

        -- 2) 每项升级的 ROI 和瓶颈加成
        -- ROI 定义：每日增收估算 / 花费（越高越优先）
        local dailyBenefitMap = {
            computer  = 25, chair = 5, net = 10, ac = 8,
            solar = 6, food = 18, deco = 8, security = 5,
            generator = 10, well = 4, road = 12, coffee = 15, jukebox = 5,
        }
        -- 瓶颈相关项
        local capacityKeys = { computer = true, chair = true, ac = true }
        local trafficKeys  = { food = true, road = true, deco = true, coffee = true, jukebox = true, well = true }
        local powerKeys    = { generator = true, solar = true }

        local scored = {}
        for _, key in ipairs(availableKeys) do
            local cfg = UPGRADES[key]
            local cur = GetUpgradeCur(key)
            local nxt = cur + 1
            local cost = cfg.costs[nxt]
            local costVal = type(cost) == "table" and (cost.money or cost[1] or 999999) or (cost or 999999)
            local canAfford = CanAffordCost(cost)

            -- 基础分：买得起权重
            local score = canAfford and 800 or 0

            -- ROI 分（归一化到 0-400 范围）
            local dailyB = dailyBenefitMap[key] or 5
            local roi = dailyB / math.max(1, costVal)
            score = score + roi * 2000  -- roi ~0.05-0.3 → 100-600 分

            -- 瓶颈加成（核心改动！）
            local reason = nil
            if bottleneck == "capacity" and capacityKeys[key] then
                score = score + 500
                if key == "computer" then
                    reason = "➕ 加电脑 +3容量，解决排队"
                elseif key == "chair" then
                    reason = "➕ 升椅子 +2容量"
                elseif key == "ac" then
                    reason = "➕ 升空调 +2容量"
                end
            elseif bottleneck == "traffic" and trafficKeys[key] then
                score = score + 500
                if key == "food" then
                    reason = "📢 烤鸡摊 +5客流，引流利器"
                elseif key == "road" then
                    reason = "📢 修路 +4客流"
                elseif key == "coffee" then
                    reason = "📢 咖啡 +4客流"
                elseif key == "deco" then
                    reason = "📢 装饰 +3客流"
                else
                    reason = "📢 引流提升"
                end
            elseif bottleneck == "power" and powerKeys[key] then
                score = score + 400
                if key == "generator" then
                    reason = "🛡️ 发电机防停电，收入不腰斩"
                elseif key == "solar" then
                    reason = "🛡️ 太阳能减损"
                end
            end

            table.insert(scored, { key = key, score = score, canAfford = canAfford, reason = reason })
        end
        table.sort(scored, function(a, b) return a.score > b.score end)

        -- 3) 渲染推荐卡片
        local recChildren = {}
        local recCount = math.min(3, #scored)
        for idx = 1, recCount do
            local item = scored[idx]
            local card = BuildUpgradeItemCard(item.key)
            if card then
                local extras = {}
                -- 瓶颈相关推荐原因（新增，最重要的信息）
                if item.reason then
                    table.insert(extras, UI.Label {
                        text = item.reason, fontSize = 11, fontColor = { 255, 220, 100, 255 },
                        paddingLeft = 4,
                    })
                else
                    -- 无特定瓶颈关联时显示通用收益
                    local benefit = GetUpgradeBenefitText(item.key)
                    if benefit then
                        table.insert(extras, UI.Label {
                            text = "📈 " .. benefit, fontSize = 11, fontColor = { 140, 220, 140, 240 },
                            paddingLeft = 4,
                        })
                    end
                end
                local synergyHint = GetUpgradeSynergyHint(item.key)
                if synergyHint then
                    table.insert(extras, UI.Label {
                        text = synergyHint, fontSize = 11, fontColor = { 255, 180, 80, 240 },
                        paddingLeft = 4,
                    })
                end
                if #extras > 0 then
                    table.insert(recChildren, UI.Panel { width = "100%", gap = 2, children = {
                        card,
                        table.unpack(extras),
                    }})
                else
                    table.insert(recChildren, card)
                end
            end
        end

        if #recChildren > 0 then
            -- 推荐区标题 + 瓶颈提示
            local headerText = "推荐升级"
            if bottleneck == "capacity" then headerText = "推荐升级 · 扩容优先"
            elseif bottleneck == "traffic" then headerText = "推荐升级 · 引流优先"
            elseif bottleneck == "power" then headerText = "推荐升级 · 供电优先"
            end
            table.insert(children, PanelHeader(headerText, { icon = "⭐", compact = true, color = C.gold }))
            -- 瓶颈一句话提示
            if bottleneckText then
                table.insert(children, UI.Label {
                    text = bottleneckText, fontSize = 11, fontColor = bottleneckColor,
                    paddingLeft = 4, paddingBottom = 4,
                })
            end
            for _, c in ipairs(recChildren) do table.insert(children, c) end
            table.insert(children, UI.Divider { spacing = 6 })
        end
    end

    -- ══════════════════════════════════════════
    -- 分组折叠手风琴（默认收起，只显示摘要行）
    -- ══════════════════════════════════════════
    local function BuildGroupAccordion(keys, groupId, title, icon, color)
        local groupAvail = {}
        local groupTotal = #keys
        local cheapestKey, cheapestCost = nil, 999999999
        for _, key in ipairs(keys) do
            local cfg = UPGRADES[key]
            if cfg then
                local cur = GetUpgradeCur(key)
                local maxLevels = cfg.costs and #cfg.costs or 0
                if cur < maxLevels then
                    table.insert(groupAvail, key)
                    local nxtCost = cfg.costs[cur + 1]
                    local cv = type(nxtCost) == "table" and (nxtCost.money or nxtCost[1] or 999999) or (nxtCost or 999999)
                    if cv < cheapestCost then
                        cheapestCost = cv
                        cheapestKey = key
                    end
                end
            end
        end
        if #groupAvail == 0 then return end

        local isExpanded = upgradeGroupExpand_[groupId] or false
        local cheapIcon = cheapestKey and (UPGRADES[cheapestKey].icon or "") or ""
        local summaryText = "可升" .. #groupAvail .. "项"
        if cheapestKey then
            summaryText = summaryText .. " | 最便宜" .. cheapIcon .. "$" .. FormatMoney(cheapestCost)
        end

        -- 摘要行（点击展开/收起）
        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 8, backgroundColor = { 45, 45, 40, 180 }, borderRadius = PX.radius,
            onClick = function()
                upgradeGroupExpand_[groupId] = not isExpanded
                BuildUI()
            end,
            children = {
                UI.Label { text = isExpanded and "▾" or "▸", fontSize = 12, fontColor = C.textDim, width = 14 },
                icon and UI.Label { text = icon, fontSize = 14 } or nil,
                UI.Label { text = title, fontSize = 13, fontColor = color or C.text, fontWeight = "bold" },
                UI.Label { text = "(" .. #groupAvail .. "/" .. groupTotal .. ")", fontSize = 11, fontColor = C.textDim },
                UI.Panel { flex = 1 },
                UI.Label { text = summaryText, fontSize = 11, fontColor = C.textLight },
            },
        })

        -- 展开时显示完整卡片
        if isExpanded then
            for _, key in ipairs(groupAvail) do
                local card = BuildUpgradeItemCard(key)
                if card then table.insert(children, card) end
            end
        end
    end

    BuildGroupAccordion(UPGRADE_ORDER, "market", "集市", "🏪", C.text)
    BuildGroupAccordion(UPGRADE_COMMUNITY, "community", "社区投资", "🏘️", C.gold)
    BuildGroupAccordion(UPGRADE_CULTURE, "culture", "文化空间", "🎭", { 220, 140, 80, 255 })

    -- ══════════════════════════════════════════
    -- 联动加成（折叠展示）
    -- ══════════════════════════════════════════
    local synergies = CalcUpgradeSynergies()
    if #synergies > 0 then
        table.insert(children, UI.Divider { spacing = 4 })
        local synExpand = upgradeGroupExpand_["synergy"] or false
        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 6, backgroundColor = { 50, 50, 35, 160 }, borderRadius = PX.radius,
            onClick = function()
                upgradeGroupExpand_["synergy"] = not synExpand
                BuildUI()
            end,
            children = {
                UI.Label { text = synExpand and "▾" or "▸", fontSize = 12, fontColor = C.textDim, width = 14 },
                UI.Label { text = "🔗", fontSize = 13 },
                UI.Label { text = "已激活联动", fontSize = 13, fontColor = C.green, fontWeight = "bold" },
                UI.Label { text = "×" .. #synergies, fontSize = 12, fontColor = C.gold },
            },
        })
        if synExpand then
            for _, s in ipairs(synergies) do
                table.insert(children, UI.Label {
                    text = "  " .. s.name .. " — " .. s.desc, fontSize = 12, fontColor = { 160, 220, 140, 220 },
                    whiteSpace = "normal", width = "100%", paddingLeft = 20,
                })
            end
        end
    end

    -- ══════════════════════════════════════════
    -- 满级徽章区（紧凑一行）
    -- ══════════════════════════════════════════
    if #maxedKeys > 0 then
        table.insert(children, UI.Divider { spacing = 4 })
        local badges = {}
        for _, key in ipairs(maxedKeys) do
            local cfg = UPGRADES[key]
            table.insert(badges, UI.Panel {
                width = 28, height = 28, borderRadius = 14,
                backgroundColor = { 60, 80, 55, 220 },
                borderWidth = 1, borderColor = { 100, 160, 90, 180 },
                justifyContent = "center", alignItems = "center",
                children = { UI.Label { text = cfg.icon, fontSize = 12 } },
            })
        end
        table.insert(children, UI.Panel {
            width = "100%", gap = 3, children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, children = {
                    UI.Label { text = "✅", fontSize = 11 },
                    UI.Label { text = "已满级", fontSize = 11, fontColor = C.green, fontWeight = "bold" },
                    UI.Label { text = #maxedKeys .. "/" .. #allKeys, fontSize = 11, fontColor = C.textDim },
                }},
                UI.Panel { flexDirection = "row", flexWrap = "wrap", gap = 3, children = badges },
            },
        })
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
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
            padding = 5, backgroundColor = C.cardAlt, borderRadius = PX.radius,
            children = {
                m.avatar and UI.Panel {
                    width = 36, height = 36, borderRadius = 18,
                    backgroundImage = m.avatar, backgroundFit = "cover",
                    borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                } or UI.Label { text = m.emoji, fontSize = 18 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = m.name .. " · " .. m.trait, fontSize = 13, fontColor = C.text },
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = "天" .. m.talent, fontSize = 13, fontColor = C.gold },
                        UI.Label { text = moodIcon .. m.mood, fontSize = 13, fontColor = moodColor },
                    }},
                    -- 技能进度条
                    UI.Panel { flexDirection = "row", gap = 4, alignItems = "center", width = "100%", children = {
                        UI.Label { text = "技" .. m.skill, fontSize = 13, fontColor = C.green },
                        UI.Panel { flex = 1, height = 4, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = PX.radiusSm, overflow = "hidden", children = {
                            UI.Panel { width = skillPct .. "%", height = "100%", backgroundColor = C.green, borderRadius = PX.radiusSm },
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
                        fontColor = playerData_.actionPoints <= 0 and C.textDim or nil,
                        onClick = function()
                            if playerData_.actionPoints <= 0 then
                                trainNoAPIdx_ = i
                                BuildUI()
                            else
                                StartTransition("特训时间", m.name .. " · " .. m.trait, function()
                                    StartTraining(i)
                                end)
                            end
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
        -- 无AP提示面板（点击"练"时AP不足触发）
        if trainNoAPIdx_ == i then
            local noAPChildren = {
                UI.Label { text = "⚡ 需要1点行动力才能训练", fontSize = 13, fontColor = C.gold },
            }
            if AdManager.CanWatch("extra_ap", playerData_.day) then
                table.insert(noAPChildren, AdManager.AdButton {
                    sceneId = "extra_ap", day = playerData_.day,
                    text = "看视频获得 +1 行动力",
                    width = "100%", height = 36, fontSize = 12,
                    onReward = function()
                        playerData_.actionPoints = playerData_.actionPoints + 1
                        AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                        trainNoAPIdx_ = nil
                        BuildUI()
                    end,
                })
            end
            table.insert(noAPChildren, UI.Button {
                text = "知道了", variant = "ghost", fontSize = 11, height = 28,
                fontColor = C.textDim,
                onClick = function()
                    trainNoAPIdx_ = nil
                    BuildUI()
                end,
            })
            table.insert(children, UI.Panel {
                width = "100%", padding = 8, gap = 6,
                backgroundColor = { 60, 45, 15, 255 }, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { 180, 140, 40, 150 },
                alignItems = "center",
                children = noAPChildren,
            })
        end
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
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
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
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = logChildren,
    }
end

-- ============================================================================
-- 自动化管理 & 转生系统面板
-- ============================================================================
showPrestigeConfirm_ = false  -- 转生确认弹窗开关

function BuildAutomationPanel()
    local IdleEngine = require("IdleEngine")
    local PrestigeSystem = require("PrestigeSystem")
    local autoLv = playerData_.automationLevel or 0
    local autoData = IdleEngine.AUTOMATION_TREE[autoLv]
    local honor = playerData_.prestigeHonor or 0
    local prestigeCount = playerData_.prestigeCount or 0
    local prestigeMulti = PrestigeSystem.CalcPrestigeMultiplier()

    local children = {}

    -- ── 区域 1：当前自动化状态 ──
    local effectItems = {}
    if autoData and autoData.effects then
        for _, eff in ipairs(autoData.effects) do
            table.insert(effectItems, UI.Label {
                text = "  • " .. eff, fontSize = 12, fontColor = C.green, whiteSpace = "normal", width = "100%",
            })
        end
    end
    if #effectItems == 0 then
        table.insert(effectItems, UI.Label {
            text = "  暂无自动化效果，所有操作需手动完成", fontSize = 12, fontColor = C.textDim, whiteSpace = "normal", width = "100%",
        })
    end

    -- 每小时离线收益预估
    local dailyIncome = 0
    local okInc, resInc = pcall(CalcDailyIncome)
    if okInc and type(resInc) == "number" then dailyIncome = resInc end
    local dailyExpense = 0
    local okExp, resExp = pcall(CalcDailyExpenses)
    if okExp and type(resExp) == "table" then
        for _, item in ipairs(resExp) do dailyExpense = dailyExpense + (item.amount or item[2] or 0) end
    end
    local perHour = IdleEngine.CalcHourlyOffline(dailyIncome, dailyExpense, autoLv, prestigeMulti)

    table.insert(children, UI.Panel {
        width = "100%", padding = 12, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                UI.Label { text = autoData and autoData.icon or "🤖", fontSize = 28 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "自动化等级 Lv" .. autoLv, fontSize = 16, fontWeight = "bold", fontColor = C.text },
                    UI.Label { text = autoData and autoData.name or "未知", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label { text = "$" .. FormatMoney(perHour) .. "/h", fontSize = 18, fontColor = C.moneyGreen, fontWeight = "bold" },
                    UI.Label { text = "离线收益", fontSize = 11, fontColor = C.textDim },
                }},
            }},
            UI.Panel { width = "100%", height = 1, backgroundColor = C.border, marginVertical = 4 },
            UI.Label { text = "当前效果：", fontSize = 13, fontColor = C.textLight, fontWeight = "bold" },
            table.unpack(effectItems),
        },
    })

    -- ── 区域 2：自动化升级树 ──
    table.insert(children, PanelHeader("升级路线", { icon = nil, compact = true, color = C.gold }))

    for lvl = 1, 4 do
        local lvData = IdleEngine.AUTOMATION_TREE[lvl]
        if not lvData then goto continue_lv end
        local isUnlocked = autoLv >= lvl
        local isCurrent = autoLv == lvl
        local isNext = autoLv == lvl - 1
        local canUnlock, reason = false, ""
        if isNext then canUnlock, reason = IdleEngine.CanUnlockAutomation(lvl) end

        local cardBg = isUnlocked and C.upgrade_max or (isCurrent and C.upgrade_active or C.card)
        local borderCol = isCurrent and C.gold or (isUnlocked and C.green or C.border)

        local statusLabel
        if isUnlocked then
            statusLabel = UI.Label { text = "✅ 已解锁", fontSize = 12, fontColor = C.green, fontWeight = "bold" }
        elseif isNext and canUnlock then
            statusLabel = UI.Button {
                text = "解锁 $" .. FormatMoney(lvData.unlockCost), fontSize = 13, fontWeight = "bold",
                height = 32, paddingHorizontal = 12,
                backgroundColor = { 26, 18, 10, 255 }, fontColor = { 245, 215, 128, 255 },
                borderRadius = PX.radius, borderWidth = PX.border, borderColor = { 190, 148, 50, 240 },
                onClick = function()
                    local ok = IdleEngine.UnlockAutomation(lvl)
                    if ok then
                        SaveGame()
                        BuildUI()
                    end
                end,
            }
        elseif isNext then
            statusLabel = UI.Label { text = "🔒 " .. reason, fontSize = 11, fontColor = C.red, whiteSpace = "normal", width = "100%" }
        else
            statusLabel = UI.Label { text = "🔒 需要先解锁Lv" .. (lvl - 1), fontSize = 11, fontColor = C.textDim }
        end

        table.insert(children, UI.Panel {
            width = "100%", padding = 10, gap = 4,
            backgroundColor = cardBg, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = borderCol,
            children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                    UI.Label { text = lvData.icon, fontSize = 22 },
                    UI.Panel { flex = 1, gap = 2, children = {
                        UI.Label { text = "Lv" .. lvl .. " " .. lvData.name, fontSize = 14, fontWeight = "bold", fontColor = C.text },
                        UI.Label { text = lvData.desc, fontSize = 11, fontColor = C.textDim, whiteSpace = "normal", width = "100%" },
                    }},
                }},
                -- 效果列表
                UI.Panel { width = "100%", paddingLeft = 28, gap = 2, children = (function()
                    local effs = {}
                    for _, e in ipairs(lvData.effects or {}) do
                        table.insert(effs, UI.Label { text = "• " .. e, fontSize = 11, fontColor = isUnlocked and C.green or C.textLight })
                    end
                    return effs
                end)() },
                -- 条件/按钮
                UI.Panel { width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center", marginTop = 4, children = {
                    lvData.unlockReq and UI.Label { text = lvData.unlockReq, fontSize = 10, fontColor = C.textDim, flex = 1, whiteSpace = "normal" } or nil,
                    statusLabel,
                }},
            },
        })
        ::continue_lv::
    end

    -- ── 区域 3：转生系统 ──
    table.insert(children, UI.Panel { width = "100%", height = 12 })
    table.insert(children, PanelHeader("转生 · 连锁扩张", { icon = nil, compact = true, color = C.gold }))

    local canPrestige, prestigeReason, prestigeGain = PrestigeSystem.CanPrestige()
    if not canPrestige then prestigeGain = PrestigeSystem.CalcPrestigeGain() end

    local currentCity = PrestigeSystem.GetCurrentCity()
    local cityName = currentCity and currentCity.name or "瓦坎达维尔"
    local cityEmoji = currentCity and currentCity.emoji or "🏘️"

    table.insert(children, UI.Panel {
        width = "100%", padding = 12, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.gold,
        children = {
            -- 当前状态
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, width = "100%", children = {
                UI.Label { text = cityEmoji, fontSize = 28 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = "当前城市：" .. cityName, fontSize = 15, fontWeight = "bold", fontColor = C.text },
                    UI.Label { text = "转生次数：" .. prestigeCount .. " | 商会名誉：" .. honor, fontSize = 12, fontColor = C.gold },
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label { text = string.format("%.1fx", prestigeMulti), fontSize = 20, fontColor = C.moneyGreen, fontWeight = "bold" },
                    UI.Label { text = "永久加成", fontSize = 10, fontColor = C.textDim },
                }},
            }},
            UI.Panel { width = "100%", height = 1, backgroundColor = C.border, marginVertical = 2 },
            -- 转生预览
            UI.Label { text = "💫 转生可获得 +" .. prestigeGain .. " 商会名誉", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
            UI.Label {
                text = "转生将重置经营进度（金钱/设备/声望），但保留：自动化等级、商会名誉、已解锁城市、50%哈弗币",
                fontSize = 11, fontColor = C.textDim, whiteSpace = "normal", width = "100%",
            },
            -- 转生按钮
            canPrestige and UI.Button {
                text = "🌟 转生 · 开启新城市", fontSize = 15, fontWeight = "bold",
                width = "100%", height = 44,
                backgroundColor = { 180, 140, 30, 255 }, fontColor = { 40, 20, 0, 255 },
                borderRadius = PX.radius, borderWidth = PX.border, borderColor = C.gold,
                onClick = function()
                    PlaySFX("click")
                    showPrestigeConfirm_ = true
                    BuildUI()
                end,
            } or UI.Label {
                text = "🔒 " .. prestigeReason,
                fontSize = 12, fontColor = C.red, whiteSpace = "normal", width = "100%", textAlign = "center", marginTop = 4,
            },
        },
    })

    -- ── 区域 4：城市地图 ──
    table.insert(children, UI.Panel { width = "100%", height = 8 })
    table.insert(children, PanelHeader("非洲城市地图", { icon = nil, compact = true, color = C.textLight }))

    local unlockedSet = {}
    for _, uid in ipairs(playerData_.unlockedCities or { "wakandaville" }) do unlockedSet[uid] = true end

    for _, city in ipairs(PrestigeSystem.CITIES) do
        local isHere = (playerData_.currentCity or "wakandaville") == city.id
        local isOpen = unlockedSet[city.id]
        local canOpen = honor >= city.prestigeReq
        local cityBorder = isHere and C.gold or (isOpen and C.green or C.border)
        local cityBg = isHere and C.upgrade_active or (isOpen and { 45, 75, 48, 200 } or C.card)

        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", padding = 8, gap = 8, alignItems = "center",
            backgroundColor = cityBg, borderRadius = PX.radius,
            borderWidth = isHere and 2 or PX.borderSm, borderColor = cityBorder,
            children = {
                UI.Label { text = city.emoji, fontSize = 24 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = city.name, fontSize = 14, fontWeight = "bold", fontColor = isOpen and C.text or C.textDim },
                        isHere and UI.Label { text = "📍当前", fontSize = 10, fontColor = C.gold, fontWeight = "bold" } or nil,
                    }},
                    UI.Label { text = city.difficultyTag or "", fontSize = 10, fontColor = C.textLight },
                    city.specialBonus and UI.Label {
                        text = "✨ " .. city.specialBonus, fontSize = 11,
                        fontColor = isOpen and C.green or C.textDim,
                    } or nil,
                }},
                UI.Panel { alignItems = "flex-end", gap = 2, children = {
                    UI.Label {
                        text = isOpen and (string.format("%.1fx", city.incomeMulti)) or ("🔒 " .. city.prestigeReq),
                        fontSize = isOpen and 16 or 12,
                        fontColor = isOpen and C.moneyGreen or (canOpen and C.gold or C.textDim),
                        fontWeight = isOpen and "bold" or "normal",
                    },
                    UI.Label { text = isOpen and "收入倍率" or "所需名誉", fontSize = 9, fontColor = C.textDim },
                }},
            },
        })
    end

    return UI.Panel {
        width = "100%", gap = 8,
        children = children,
    }
end

--- 转生确认弹窗
function BuildPrestigeConfirmPopup()
    local PrestigeSystem = require("PrestigeSystem")
    local gain, breakdown = PrestigeSystem.CalcPrestigeGain()
    local currentHonor = playerData_.prestigeHonor or 0
    local newHonor = currentHonor + gain
    local newMulti = 1.0 + math.min(2.0, newHonor / 100 * 0.1)

    -- 找到下一个未解锁城市
    local unlockedSet = {}
    for _, uid in ipairs(playerData_.unlockedCities or { "wakandaville" }) do unlockedSet[uid] = true end
    local nextCity = nil
    for _, city in ipairs(PrestigeSystem.CITIES) do
        if not unlockedSet[city.id] then nextCity = city; break end
    end

    local detailRows = {}
    local function addRow(label, value)
        table.insert(detailRows, UI.Panel {
            flexDirection = "row", justifyContent = "space-between", width = "100%", children = {
                UI.Label { text = label, fontSize = 12, fontColor = C.textDim },
                UI.Label { text = value, fontSize = 12, fontColor = C.gold, fontWeight = "bold" },
            },
        })
    end
    if breakdown then
        if (breakdown.earnings or 0) > 0 then addRow("累计收入贡献", "+" .. breakdown.earnings) end
        if (breakdown.branches or 0) > 0 then addRow("分店贡献", "+" .. breakdown.branches) end
        if (breakdown.tournaments or 0) > 0 then addRow("锦标赛贡献", "+" .. breakdown.tournaments) end
        if (breakdown.days or 0) > 0 then addRow("经营天数贡献", "+" .. breakdown.days) end
        if (breakdown.reputation or 0) > 0 then addRow("声望贡献", "+" .. breakdown.reputation) end
        if (breakdown.chainBonus or 0) > 0 then addRow("连锁转生加成", "+" .. breakdown.chainBonus .. "%") end
    end

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 180 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 20,
        onClick = function()
            showPrestigeConfirm_ = false
            PlaySFX("click")
            BuildUI()
        end,
        children = {
            UI.Panel {
                width = "100%", maxWidth = 360,
                backgroundColor = C.card, borderRadius = PX.cardRadius,
                borderWidth = 2, borderColor = C.gold,
                padding = 16, gap = 8,
                onClick = function() end, -- 阻止穿透
                children = {
                    UI.Label { text = "🌟 确认转生", fontSize = 18, fontWeight = "bold", fontColor = C.gold, textAlign = "center", width = "100%" },
                    UI.Panel { width = "100%", height = 1, backgroundColor = C.border },
                    -- 名誉获取
                    UI.Panel { flexDirection = "row", justifyContent = "center", alignItems = "center", gap = 8, width = "100%", children = {
                        UI.Label { text = "商会名誉", fontSize = 13, fontColor = C.textDim },
                        UI.Label { text = tostring(currentHonor), fontSize = 16, fontColor = C.textLight },
                        UI.Label { text = "→", fontSize = 16, fontColor = C.gold },
                        UI.Label { text = tostring(newHonor), fontSize = 18, fontColor = C.gold, fontWeight = "bold" },
                        UI.Label { text = "(+" .. gain .. ")", fontSize = 13, fontColor = C.green },
                    }},
                    -- 倍率变化
                    UI.Label {
                        text = "收入加成：" .. string.format("%.1fx → %.1fx", PrestigeSystem.CalcPrestigeMultiplier(), newMulti),
                        fontSize = 13, fontColor = C.moneyGreen, textAlign = "center", width = "100%",
                    },
                    -- 下一城市
                    nextCity and UI.Panel {
                        width = "100%", padding = 8, backgroundColor = C.cardAlt, borderRadius = PX.radius, gap = 4, children = {
                            UI.Label { text = "🏙️ 前往新城市", fontSize = 13, fontColor = C.textLight, textAlign = "center", width = "100%" },
                            UI.Label {
                                text = nextCity.emoji .. " " .. nextCity.name .. " — " .. nextCity.difficultyTag,
                                fontSize = 14, fontColor = C.text, fontWeight = "bold", textAlign = "center", width = "100%",
                            },
                            nextCity.specialBonus and UI.Label {
                                text = "✨ " .. nextCity.specialBonus, fontSize = 12, fontColor = C.green, textAlign = "center", width = "100%",
                            } or nil,
                        },
                    } or nil,
                    -- 明细
                    #detailRows > 0 and UI.Panel {
                        width = "100%", padding = 8, backgroundColor = { C.bg[1], C.bg[2], C.bg[3], 180 },
                        borderRadius = PX.radius, gap = 3,
                        children = detailRows,
                    } or nil,
                    -- 警告
                    UI.Label {
                        text = "⚠️ 将重置：金钱、设备、声望、团队、分店\n保留：自动化等级、商会名誉、已解锁城市、50%哈弗币",
                        fontSize = 11, fontColor = C.red, whiteSpace = "normal", width = "100%", textAlign = "center",
                    },
                    UI.Panel { width = "100%", height = 4 },
                    -- 按钮
                    UI.Panel { flexDirection = "row", gap = 10, width = "100%", justifyContent = "center", children = {
                        UI.Button {
                            text = "取消", fontSize = 14, height = 38, paddingHorizontal = 24,
                            backgroundColor = C.cardAlt, fontColor = C.textLight, borderRadius = PX.radius,
                            borderWidth = PX.borderSm, borderColor = C.border,
                            onClick = function()
                                showPrestigeConfirm_ = false
                                PlaySFX("click")
                                BuildUI()
                            end,
                        },
                        UI.Button {
                            text = "🌟 确认转生", fontSize = 14, fontWeight = "bold", height = 38, paddingHorizontal = 24,
                            backgroundColor = { 180, 140, 30, 255 }, fontColor = { 40, 20, 0, 255 },
                            borderRadius = PX.radius, borderWidth = PX.border, borderColor = C.gold,
                            onClick = function()
                                showPrestigeConfirm_ = false
                                local ok, msg = PrestigeSystem.DoPrestige()
                                if ok then
                                    SaveGame()
                                    PlaySFX("victory")
                                    if TriggerCelebration then TriggerCelebration() end
                                else
                                    AddLog("❌ 转生失败：" .. (msg or "未知原因"))
                                end
                                BuildUI()
                            end,
                        },
                    }},
                },
            },
        },
    }
end

