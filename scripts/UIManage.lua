---@diagnostic disable: undefined-global
---@diagnostic disable: assign-type-mismatch
---@diagnostic disable: param-type-mismatch
-- ============================================================================
-- 13. 经营界面（带背景图）
-- ============================================================================
local ProgressiveUnlock = require("ProgressiveUnlock")
local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")
local Retention = require("Retention")
local NPCStorylines = require("NPCStorylines")
local UIMapView = require("UIMapView")
local UICollection = require("UICollection")
require("UIPanel_Upgrade")
require("UIPanel_Actions")
require("UIPanel_Team")
require("UIPanel_Prestige")
require("UIPanel_Status")
require("UIPanel_Daily")
goldExpanded_ = goldExpanded_ or false  -- 黄金交易面板展开状态
mapViewOpen_ = mapViewOpen_ or false    -- 帝国版图面板状态
showEndDayAdPopup_ = showEndDayAdPopup_ or false  -- EndDay翻倍收入广告弹窗

-- ═══════════════════════════════════════════════════════════════
-- P0-2: 今日主目标 —— 每天只显示一条最该做的事
-- 用途：给玩家清晰方向感，比广告/市场/排行榜更重要
-- ═══════════════════════════════════════════════════════════════
local MAIN_OBJECTIVES = {
    -- Week 1: 生存 + Kofi
    [1]  = { text = "把破网吧撑过第一天", hint = "贴传单 · 招揽第一批客人", icon = "🏚️" },
    [2]  = { text = "先让 Dragon Net 活过第二天", hint = "电费房租来袭 · 做出生存抉择", icon = "⚡" },
    [3]  = { text = "找到那个打得离谱的少年", hint = "角落那台破电脑上有异常战绩", icon = "👀" },
    [4]  = { text = "决定你和这个街区的关系", hint = "新来的要融入还是只做生意？", icon = "🏘️" },
    [5]  = { text = "让网吧口碑过 20", hint = "服务好客人 · 维护设备", icon = "⭐" },
    [6]  = { text = "招第二位队员", hint = "留意新 NPC 故事线触发", icon = "👥" },
    [7]  = { text = "打完第一周周末赛", hint = "周末赛检验一周成果", icon = "🏆" },
    -- Week 2: Victor 出场 + 对抗
    [8]  = { text = "面对 Victor 的第一次挑衅", hint = "稳住阵脚，不要慌", icon = "😈" },
    [9]  = { text = "守住客流，别被价格战击垮", hint = "提升服务 · 维系老客户", icon = "🛡️" },
    [10] = { text = "反击差评，守住口碑", hint = "升级网吧 · 积攒好评", icon = "🗣️" },
    [11] = { text = "回复 AEL 邀请邮件", hint = "正式比赛的大门在敲", icon = "📧" },
    [12] = { text = "扛住 Victor 的深夜造访", hint = "你的回应决定队伍士气", icon = "🌙" },
    [13] = { text = "化压力为训练动力", hint = "加强训练 · 提升队伍实力", icon = "🔥" },
    [14] = { text = "留住核心队员", hint = "关注队员忠诚度 · 别被挖角", icon = "⚠️" },
    -- Week 3: 首场正式赛
    [15] = { text = "准备 AEL 预选赛", hint = "确保队伍状态达标", icon = "📋" },
    [16] = { text = "升级设备，备战正式比赛", hint = "电脑性能影响训练效果", icon = "💻" },
    [17] = { text = "赢下 AEL 预选赛第一轮", hint = "比赛中注意阵容搭配", icon = "🏆" },
    [18] = { text = "扩张网吧规模", hint = "更多座位 = 更多收入", icon = "📐" },
    [19] = { text = "建立稳定现金流", hint = "日收入覆盖日支出", icon = "💰" },
    [20] = { text = "预选赛晋级", hint = "打进下一轮", icon = "🚀" },
    [21] = { text = "阶段复盘：三周成果", hint = "检查口碑 · 战绩 · 财务", icon = "📊" },
    -- Week 4: AEL 正赛 + 终章
    [22] = { text = "AEL 正赛首轮", hint = "Dragon Force 正式亮相", icon = "🐉" },
    [23] = { text = "应对赛后舆论", hint = "无论胜负，口碑都在变化", icon = "📰" },
    [24] = { text = "队伍磨合：解决内部矛盾", hint = "留意队员情绪", icon = "🤝" },
    [25] = { text = "击败 Victor 的 Gold Net 战队", hint = "这一战决定街区霸主", icon = "⚔️" },
    [26] = { text = "进入 AEL 四强", hint = "半决赛的门票", icon = "🎖️" },
    [27] = { text = "决赛前最后冲刺", hint = "训练 · 设备 · 士气全部拉满", icon = "💪" },
    [28] = { text = "AEL 总决赛", hint = "所有准备，为了这一刻", icon = "👑" },
    [29] = { text = "赛后收尾：决定未来方向", hint = "继续扩张？还是回家？", icon = "🔮" },
    [30] = { text = "写下你的结局", hint = "回顾 30 天，做出最后选择", icon = "📖" },
}

---获取今日主目标，day > 30 时根据状态动态生成
---@param day integer
---@return {text:string, hint:string, icon:string}|nil
function GetTodayMainObjective(day)
    if MAIN_OBJECTIVES[day] then
        return MAIN_OBJECTIVES[day]
    end
    -- Day 30+ 动态目标
    if day > 30 then
        local rep = playerData_.reputation or 0
        local wins = playerData_.totalTourney or 0
        if rep < 200 then
            return { text = "提升口碑到 200", hint = "当前: " .. rep .. "/200", icon = "⭐" }
        elseif wins < 3 then
            return { text = "赢得第 " .. (wins + 1) .. " 场锦标赛", hint = "已赢: " .. wins .. "/3", icon = "🏆" }
        else
            return { text = "书写传奇的下一章", hint = "自由经营 · 探索隐藏内容", icon = "🐉" }
        end
    end
    return nil
end

function BuildManageTabBar()
    local allTabs = {
        { key = "action",  label = "经营" },
        { key = "upgrade", label = "升级" },
        { key = "team",    label = "团队" },
        { key = "market",  label = "市场" },
        { key = "collection", label = "图鉴" },
        { key = "ranking", label = "排行榜" },
    }
    -- 渐进解锁：仅显示已解锁Tab
    local tabs = {}
    for _, t in ipairs(allTabs) do
        local unlockKey = "tab_" .. t.key
        if t.key == "action" or ProgressiveUnlock.IsUnlocked(unlockKey) then
            table.insert(tabs, t)
        end
    end
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
        local canUp, _ = IdleEngine.CanUnlockAutomation(autoLv + 1)
        if canUp then autoBadge = "!" end
    end
    -- 转生就绪角标
    if not autoBadge and PrestigeSystem.CanPrestige() then autoBadge = "⭐" end

    -- 免费抽角标：每日未使用免费抽时显示提醒
    local marketBadge = nil
    if not playerData_.marketDailyFree then
        marketBadge = "免费"
    end

    local allTabs = {
        { key = "action",     icon = "🏠", label = "经营",   badge = nil },
        { key = "upgrade",    icon = "⬆",  label = "升级",   badge = nil },
        { key = "team",       icon = "👥", label = "团队",   badge = teamBadge },
        { key = "automation", icon = "🤖", label = "自动化", badge = autoBadge },
        { key = "market",     icon = "🛒", label = "市场",   badge = marketBadge },
        { key = "ranking",    icon = "🏆", label = "排行榜", badge = nil },
    }
    -- 渐进解锁：仅显示已解锁的Tab
    local tabs = {}
    for _, t in ipairs(allTabs) do
        local unlockKey = "tab_" .. t.key
        if t.key == "action" or ProgressiveUnlock.IsUnlocked(unlockKey) then
            table.insert(tabs, t)
        end
    end
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

--- 全景像素图（纯氛围展示 + 气泡装饰 + 底部入口浮标）
cafePopupOpen_ = cafePopupOpen_ or false
function BuildPanoramaSection()
    local cafeImg = GetCafeSceneImage()

    -- 对话气泡（网吧顾客的像素风对话，增加趣味性）
    local CAFE_DIALOGUES = {
        "再来一局！", "网速快点啊", "老板加个钟",
        "这把稳赢！", "队友太菜了", "泡面好了没",
        "网管！加冰！", "今晚通宵！", "上分了上分了",
        "别催马上好", "太上头了", "键盘手感不错",
    }
    local d = playerData_.day or 1
    local dIdx1 = (d * 3 + 1) % #CAFE_DIALOGUES + 1

    local bubble1 = nil
    if cafeImg ~= SCENE_IMAGES.cafe_empty and cafeImg ~= SCENE_IMAGES.cafe_blackout then
        bubble1 = UI.Panel {
            position = "absolute", top = 4, left = 8,
            paddingHorizontal = 5, paddingVertical = 2,
            backgroundColor = { 255, 255, 245, 180 },
            borderRadius = PX.radiusSm,
            borderWidth = PX.border, borderColor = { 50, 35, 25, 200 },
            children = {
                UI.Label { text = CAFE_DIALOGUES[dIdx1], fontSize = 8,
                    fontColor = { 40, 30, 20, 255 } },
            },
        }
    end

    -- 夜间时段标识（右上角小标签）
    local hourNow = os.date("*t").hour
    local nightBadge = nil
    if hourNow >= 22 or hourNow < 6 then
        local isOvn = hourNow >= 1 and hourNow < 5
        nightBadge = UI.Panel {
            position = "absolute", top = 4, right = 8,
            paddingHorizontal = 5, paddingVertical = 1,
            backgroundColor = { 30, 20, 50, 200 },
            borderRadius = PX.radiusSm,
            borderWidth = PX.border, borderColor = { 100, 80, 160, 200 },
            children = {
                UI.Label { text = isOvn and "包夜中" or "夜间", fontSize = 8, fontWeight = "bold",
                    fontColor = { 200, 180, 255, 255 } },
            },
        }
    end

    -- 动态构建全景图子列表
    local panoramaChildren = {}
    if bubble1 then table.insert(panoramaChildren, bubble1) end
    if nightBadge then table.insert(panoramaChildren, nightBadge) end

    -- 帝国版图入口（左下角浮标，Day 10+ 或有转生进度时显示）
    local showMapBtn = ProgressiveUnlock.IsUnlocked("prestige_preview")
        or (playerData_.prestigeHonor or 0) > 0
        or #(playerData_.unlockedCities or {}) > 1
    if showMapBtn then
        local conqueredN = #(playerData_.unlockedCities or { "wakandaville" })
        table.insert(panoramaChildren, UI.Panel {
            position = "absolute", bottom = 40, left = 6,
            paddingHorizontal = 6, paddingVertical = 3,
            backgroundColor = { 20, 40, 30, 200 },
            borderRadius = 8,
            borderWidth = 1, borderColor = { 80, 140, 60, 180 },
            flexDirection = "row", alignItems = "center", gap = 3,
            onClick = function()
                mapViewOpen_ = true
                PlaySFX("click")
                BuildUI()
            end,
            children = {
                UI.Label { text = "🌍", fontSize = 11 },
                UI.Label { text = "版图", fontSize = 9, fontWeight = "bold",
                    fontColor = { 140, 220, 120, 255 } },
                UI.Label { text = conqueredN .. "/7", fontSize = 8,
                    fontColor = { 100, 180, 80, 200 } },
            },
        })
    end

    -- 📖 非洲文化图鉴入口（右下角浮标，Day 5+ 显示）
    if (playerData_.day or 1) >= 5 and LoreSystem then
        local totalEntries = LoreSystem.ENTRIES and #LoreSystem.ENTRIES or 0
        local unlocked = playerData_.loreUnlocked or {}
        local unlockedN = 0
        for _ in pairs(unlocked) do unlockedN = unlockedN + 1 end
        local newCount = playerData_.loreNewCount or 0
        local badgeChildren = {
            UI.Label { text = "📖", fontSize = 11 },
            UI.Label { text = "图鉴", fontSize = 9, fontWeight = "bold",
                fontColor = { 200, 180, 120, 255 } },
            UI.Label { text = unlockedN .. "/" .. totalEntries, fontSize = 8,
                fontColor = { 160, 140, 100, 200 } },
        }
        -- 红点：有新解锁
        if newCount > 0 then
            table.insert(badgeChildren, UI.Panel {
                width = 16, height = 16, borderRadius = 8,
                backgroundColor = { 220, 60, 60, 240 },
                justifyContent = "center", alignItems = "center",
                children = {
                    UI.Label { text = tostring(newCount), fontSize = 9, fontWeight = "bold",
                        fontColor = { 255, 255, 255, 255 } },
                },
            })
        end
        table.insert(panoramaChildren, UI.Panel {
            position = "absolute", bottom = 40, right = 6,
            paddingHorizontal = 6, paddingVertical = 3,
            backgroundColor = { 40, 30, 20, 200 },
            borderRadius = 8,
            borderWidth = 1, borderColor = { 140, 110, 50, 180 },
            flexDirection = "row", alignItems = "center", gap = 3,
            onClick = function()
                OpenLorePanel()
                PlaySFX("click")
                BuildUI()
            end,
            children = badgeChildren,
        })
    end

    return UI.Panel {
        width = "100%", height = 80,
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
    -- ── P0-2 今日主目标追踪（旧存档兼容） ──
    p.mainObjDoneDay = p.mainObjDoneDay or 0
    -- v11 自动化/转生（旧存档兼容）
    p.automationLevel = p.automationLevel or 0
    p.prestigeHonor = p.prestigeHonor or 0
    p.prestigeCount = p.prestigeCount or 0
    p.currentCity = p.currentCity or "wakandaville"
    p.unlockedCities = p.unlockedCities or { "wakandaville" }
    p.prestigeHistory = p.prestigeHistory or {}
    p.totalPrestigeEarnings = p.totalPrestigeEarnings or 0

    -- ── AEL 赞助系统字段（旧存档兼容） ──
    p.aelTier = p.aelTier or 0
    p.weeklyWins = p.weeklyWins or 0
    p.weeklyTrainCount = p.weeklyTrainCount or 0
    p.weeklyIncome = p.weeklyIncome or 0
    p.weeklyRepGain = p.weeklyRepGain or 0
    p.weeklyWinStreak = p.weeklyWinStreak or 0

    -- ── 教练系统字段（旧存档兼容） ──
    -- hiredCoach / coachHiredDay: nil 表示未雇佣，无需强制赋值

    -- ── 成就系统字段（旧存档兼容） ──
    p.achievements = p.achievements or {}
    p.mailbox = p.mailbox or {}

    -- ── 彩蛋系统字段（旧存档兼容） ──
    p.eggsTriggered = p.eggsTriggered or {}
    p.eggCounters = p.eggCounters or {}
    p.eggPrestigeCount = p.eggPrestigeCount or 0

    -- ── 事件联动系统字段（旧存档兼容） ──
    p.linkagesClaimed = p.linkagesClaimed or {}

    -- ── 章节系统字段（旧存档兼容） ──
    p.chapterCompleted = p.chapterCompleted or {}

    -- ── 每日问候字段（旧存档兼容） ──
    p.dailyGreetingShownDay = p.dailyGreetingShownDay or 0

    -- ── 渐进解锁字段（旧存档兼容） ──
    p.unlocksNotified = p.unlocksNotified or {}

    -- ── RetentionV2 补充字段（旧存档兼容） ──
    if p.loginStreakClaimed == nil then p.loginStreakClaimed = false end
    p.marketFreeDraws = p.marketFreeDraws or 0

    -- ── 装饰系统字段（旧存档兼容） ──
    p.decoSlots = p.decoSlots or {}
    p.decoSlotsMax = p.decoSlotsMax or 3

    -- ── 其他杂项字段（旧存档兼容） ──
    p.nearBankruptCount = p.nearBankruptCount or 0
    p.questStreak = p.questStreak or 0
    p.dayHistory = p.dayHistory or {}
    p.cityFacilities = p.cityFacilities or {}

    -- ── v13 经营策略卡字段（旧存档兼容） ──
    -- todayStrategy / strategyChoice: nil 表示未生成/未选择，无需强制赋值
    if p.strategyChosen == nil then p.strategyChosen = false end
    if p.overtimeUsedToday == nil then p.overtimeUsedToday = false end
    p.endOfDayDurPenalty = p.endOfDayDurPenalty or 0

    -- ═══ P0-6: 隐藏后果账本（伦理维度，玩家不可见但影响结局） ═══
    p.ethicsLedger = p.ethicsLedger or {
        moneyVsPeople    = 0,  -- +正=重人 -负=重钱（范围 -10 ~ +10）
        legalVsGray      = 0,  -- +正=守法 -负=灰色（范围 -10 ~ +10）
        integrationVsExtraction = 0, -- +正=融入社区 -负=纯粹榨取
        resultVsProcess  = 0,  -- +正=重过程/队员成长 -负=唯结果论
    }
    p.ethicsKeyChoices = p.ethicsKeyChoices or {} -- 关键选择记录：{day, choiceId, delta}

    -- ═══ P3: 第一季主线 (D15-D30) 旧存档兼容 ═══
    if not p.seasonOne then
        p.seasonOne = {
            events = {}, aelStage = "registered", aelPoints = 0,
            kofiPressure = 0, kofiExposure = 0, streetSupport = 0,
            victorPressure = 0, grayRisk = 0, auditRisk = 0,
            facilityPower = 0, finalResult = nil, route = nil, endingId = nil,
        }
    end
    if p.seasonOneComplete == nil then p.seasonOneComplete = false end
    p.postSeason = p.postSeason or false
    p.seasonOneBonus = p.seasonOneBonus or nil
    -- ═══ P6: CityNetwork 旧存档兼容 ═══
    local CityNet = package.loaded["CityNetwork"]
    if CityNet then pcall(CityNet.MigrateOldSave) end

    -- ═══ P0-7: 结局分层数据结构 ═══
    p.endingFlags = p.endingFlags or {
        tournamentBest     = 0,   -- 最佳锦标赛名次 (1=冠军)
        victorDefeated     = false, -- 是否在正式赛击败 Victor
        teamRetained       = true,  -- 核心队员是否全部留下
        communityStanding  = 0,   -- 社区声望积分 (karma + reputation/10)
        financialPeak      = 0,   -- 历史最高资产
        kofiArc            = "neutral", -- Kofi 结局弧线: loyal/departed/rival/partner
        branchCount        = 0,   -- 分店数量
    }

    -- 🔒 安全检测：activeUpgrade_ 卡住修复
    -- 如果 activeUpgrade_ 有值但升级计时器已归零（非跨日模式），说明 CompleteUpgrade 曾崩溃
    if activeUpgrade_ then
        local isStuck = false
        if upgradeCompletionDay_ and upgradeCompletionDay_ > 0 then
            -- 跨日模式：如果当前天数已超过完工日，强制完成
            if (p.day or 1) > upgradeCompletionDay_ + 1 then
                isStuck = true
            end
        else
            -- 实时模式：如果 upgradeTimeLeft_ <= 0 说明早该完成了
            if (upgradeTimeLeft_ or 0) <= 0 and (upgradeTotalTime_ or 0) <= 0 then
                isStuck = true
            end
        end
        if isStuck then
            log:Write(LOG_WARNING, "[Validate] activeUpgrade_ stuck at '" .. tostring(activeUpgrade_) .. "', force clearing")
            activeUpgrade_ = nil
            upgradeTimeLeft_ = 0
            upgradeTotalTime_ = 0
            upgradeCost_ = nil
            upgradeCompletionDay_ = nil
            if AddLog then AddLog("⚠️ 检测到升级状态异常，已自动修复") end
        end
    end
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
        local linkagePanel = SafeBuild("LinkageCard", BuildLinkageCard)
        if linkagePanel then table.insert(actionChildren, linkagePanel) end

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
                                    local resolveOk, result = pcall(RV2.ResolveMicroEvent, me.id, ci)
                                    if not resolveOk then
                                        log:Write(LOG_ERROR, "[UIManage] ResolveMicroEvent error: " .. tostring(result))
                                        result = "处理失败"
                                    end
                                    AddLog("📋 " .. (me.title or "事件") .. ": " .. tostring(result or ""))
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

        -- Batch 3: 装饰面板入口（章节解锁 decoration_slots 后显示）
        local okCS, ChapterSys = pcall(require, "ChapterSystem")
        local decoUnlocked = okCS and ChapterSys and ChapterSys.IsUnlocked and ChapterSys.IsUnlocked("decoration_slots")
        if decoUnlocked then
            local decoPanel = SafeBuild("DecorationPanel", function()
                local okD, UIDeco = pcall(require, "UIDecoration")
                if okD and UIDeco then
                    -- UIDecoration 导出的是文件顶层，BuildDecorationPanel 是全局函数
                    return BuildDecorationPanel()
                end
                return nil
            end)
            if decoPanel then table.insert(actionChildren, decoPanel) end
        end

        -- 网吧装修入口（章节2+或装饰Lv1+）
        local customizeBtn = SafeBuild("CafeCustomizeBtn", function()
            local okCust, _ = pcall(require, "UICafeCustomize")
            if okCust and BuildCafeCustomizeButton then
                return BuildCafeCustomizeButton()
            end
            return nil
        end)
        if customizeBtn then table.insert(actionChildren, customizeBtn) end

        -- P1-4: 7城征途地图胶囊（chapter>=2 时显示，让玩家感知大目标）
        if currentChapter_ >= 2 or (playerData_.unlockedCities and #playerData_.unlockedCities > 1) then
            local roadmapPanel = SafeBuild("RoadmapCapsule", BuildRoadmapCapsule)
            if roadmapPanel then table.insert(actionChildren, roadmapPanel) end
        end

        -- ═══ P6: 城市网络入口（D31+继续经营模式可见） ═══
        if playerData_.postSeason then
            local cnPanel = SafeBuild("CityNetworkPanel", function()
                local CityNet = package.loaded["CityNetwork"] or require("CityNetwork")
                if not CityNet then return nil end
                local overview = CityNet.GetCityOverview()
                local unlockedCount = 0
                local cityCards = {}
                for _, c in ipairs(overview) do
                    if c.isUnlocked then
                        unlockedCount = unlockedCount + 1
                        table.insert(cityCards, UI.Panel {
                            flexDirection = "row", alignItems = "center", gap = 6,
                            paddingVertical = 4, paddingHorizontal = 8,
                            backgroundColor = c.isCurrent and { 40, 100, 60, 255 } or { 50, 50, 60, 255 },
                            borderRadius = 6,
                            children = {
                                UI.Label { text = c.emoji .. " " .. c.name, fontSize = 12, fontColor = { 255, 255, 255, 255 } },
                                c.isCurrent and UI.Label { text = "📍", fontSize = 10 } or nil,
                            },
                        })
                    elseif c.canUnlock then
                        table.insert(cityCards, UI.Panel {
                            flexDirection = "row", alignItems = "center", gap = 6,
                            paddingVertical = 4, paddingHorizontal = 8,
                            backgroundColor = { 80, 80, 40, 255 }, borderRadius = 6,
                            children = {
                                UI.Label { text = c.emoji .. " " .. c.name, fontSize = 12, fontColor = { 255, 220, 100, 255 } },
                                UI.Label { text = "🔓可解锁", fontSize = 10, fontColor = { 255, 200, 60, 255 } },
                            },
                        })
                    end
                end
                local passive = CityNet.CalcPassiveIncome()
                return UI.Panel {
                    width = "100%", backgroundColor = { 30, 35, 50, 255 }, borderRadius = 10,
                    padding = 12, marginTop = 8, gap = 8,
                    children = {
                        UI.Panel { flexDirection = "row", justifyContent = "space-between", alignItems = "center", width = "100%", children = {
                            UI.Label { text = "🌍 城市网络", fontSize = 14, fontWeight = "bold", fontColor = { 100, 200, 255, 255 } },
                            passive > 0 and UI.Label { text = "+$" .. passive .. "/天", fontSize = 11, fontColor = { 100, 255, 150, 255 } } or nil,
                        }},
                        UI.Panel { flexDirection = "row", flexWrap = "wrap", gap = 6, children = cityCards },
                    },
                }
            end)
            if cnPanel then table.insert(actionChildren, cnPanel) end
        end

        local branchPanel = SafeBuild("BranchSelector", BuildBranchSelector)
        if branchPanel then table.insert(actionChildren, branchPanel) end
        table.insert(actionChildren, SafeBuild("DiaryInline", BuildDiaryPage))

        -- P0+P3: 转生预览窗（城市解锁进度 + 当前增益预览）
        local prestigePreview = nil
        local okPS, PS2 = pcall(require, "PrestigeSystem")
        if okPS and PS2 and PS2.CITIES then
            local current = playerData_.prestigeHonor or 0
            local nextCity = nil
            for _, city in ipairs(PS2.CITIES) do
                if city.prestigeReq > current then nextCity = city; break end
            end
            if nextCity then
                -- 碎片减免检查
                local effectiveReq = nextCity.prestigeReq
                local hasFragment = false
                if PS2.GetEffectivePrestigeReq then
                    effectiveReq, hasFragment = PS2.GetEffectivePrestigeReq(nextCity)
                end
                local pct = math.min(100, math.floor(current / effectiveReq * 100))
                local barW = math.max(5, pct)
                -- 当前可获得名誉预览
                local gainPreview = ""
                if PS2.CalcPrestigeGain then
                    local gain = PS2.CalcPrestigeGain()
                    if gain > 0 then
                        gainPreview = "转生可获 +" .. gain .. " 名誉"
                    end
                end
                -- 提示怎么获取名誉
                local hintParts = {}
                if #(playerData_.branches or {}) < 2 then table.insert(hintParts, "开分店+15") end
                table.insert(hintParts, "赢锦标赛+25")
                if (playerData_.day or 1) >= 10 then table.insert(hintParts, "经营天数+名誉") end
                local hintStr = table.concat(hintParts, " | ")
                -- 进度条颜色：接近满时用金色
                local barColor = pct >= 80 and { 255, 200, 50, 240 } or { 100, 160, 255, 220 }
                local previewChildren = {
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                        UI.Label { text = "🌍", fontSize = 14 },
                        UI.Label { text = "下一站：" .. nextCity.emoji .. " " .. nextCity.name, fontSize = 12, fontColor = { 180, 210, 255, 255 }, fontWeight = "bold", flex = 1 },
                        UI.Label { text = current .. "/" .. effectiveReq .. " 名誉", fontSize = 11, fontColor = C.textDim },
                    }},
                    -- 进度条
                    UI.Panel { width = "100%", height = 6, borderRadius = 3, backgroundColor = { 30, 40, 55, 255 }, children = {
                        UI.Panel { width = barW .. "%", height = "100%", borderRadius = 3, backgroundColor = barColor },
                    }},
                }
                -- 碎片减免标记
                if hasFragment then
                    table.insert(previewChildren, UI.Label {
                        text = "🗺️ 城市碎片已激活 — 门槛降低！",
                        fontSize = 10, fontColor = { 120, 230, 180, 220 },
                    })
                end
                -- 转生可获名誉
                if gainPreview ~= "" then
                    table.insert(previewChildren, UI.Label {
                        text = "⭐ " .. gainPreview,
                        fontSize = 10, fontColor = { 255, 210, 100, 200 },
                    })
                end
                -- 城市特殊加成
                if nextCity.specialBonus then
                    table.insert(previewChildren, UI.Label {
                        text = "✨ 城市加成：" .. nextCity.specialBonus,
                        fontSize = 10, fontColor = { 170, 200, 240, 180 },
                    })
                end
                table.insert(previewChildren, UI.Label { text = "💡 " .. hintStr, fontSize = 10, fontColor = { 140, 170, 200, 180 } })
                prestigePreview = UI.Panel {
                    width = "100%", padding = 10, borderRadius = PX.radius,
                    backgroundColor = { 40, 50, 70, 200 },
                    borderWidth = 1, borderColor = pct >= 80 and { 200, 170, 50, 160 } or { 80, 120, 180, 120 },
                    gap = 5,
                    children = previewChildren,
                }
            else
                -- 全部城市已解锁 → 显示传奇状态
                local count = PS2.GetPrestigeCount and PS2.GetPrestigeCount() or 0
                if count > 0 then
                    prestigePreview = UI.Panel {
                        width = "100%", padding = 10, borderRadius = PX.radius,
                        backgroundColor = { 50, 40, 20, 200 },
                        borderWidth = 1, borderColor = { 200, 170, 50, 160 },
                        gap = 4, alignItems = "center",
                        children = {
                            UI.Label { text = "👑 传奇之路完成", fontSize = 13, fontColor = { 255, 215, 0, 255 }, fontWeight = "bold" },
                            UI.Label { text = "转生 " .. count .. " 次 | 名誉 " .. current, fontSize = 11, fontColor = { 200, 180, 120, 200 } },
                        },
                    }
                end
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
            SafeBuild("AELSponsor", BuildAELSponsorPanel),
            SafeBuild("CoachPanel", BuildCoachPanel),
            SafeBuild("AchievementCard", BuildAchievementCard),
            SafeBuild("MailboxCard", BuildMailboxCard),
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
    elseif manageTab_ == "collection" then
        return SafeBuild("CollectionPage", UICollection.BuildCollectionPage)
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
    -- 安全回退：如果当前Tab尚未解锁，回退到"action"
    if manageTab_ ~= "action" then
        local unlockKey = "tab_" .. manageTab_
        if not ProgressiveUnlock.IsUnlocked(unlockKey) then
            manageTab_ = "action"
        end
    end

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
        -- BuildPanoramaSection 的渲染元素现在直接内联到全景图 Panel 中
        -- 广告条带已移除，广告分散到各位置：翻倍收入→日结弹窗 / 额外AP→状态栏内联 / 赞助福利→行动网格

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

        -- 今日经营策略卡（Day 4+ 显示，全景图/广告条下方）
        local stratCard = nil
        if ProgressiveUnlock.IsUnlocked("strategy_card") then
            local ok9, stratCard_ = pcall(BuildStrategyCard)
            if not ok9 then
                log:Write(LOG_ERROR, "[BuildManageUI] BuildStrategyCard error: " .. tostring(stratCard_))
            else
                stratCard = stratCard_
            end
        end

        -- ══════════════════════════════════════════════════════
        -- 新布局：固定一屏，不再整体滚动
        -- 结构：[StatusBar][全景图(压缩)][事件条][结束当天按钮][操作区ScrollView][BottomNav]
        -- ══════════════════════════════════════════════════════

        -- 从 actionCard 中提取结束当天按钮（固定在操作区上方）
        local ap = playerData_.actionPoints or 3
        local noAP = ap <= 0
        local endBotColor = noAP and { 20, 90, 38, 255 } or { 90, 58, 10, 255 }
        local endBgColor  = noAP and { 45, 158, 72, 255 } or { 170, 115, 28, 255 }
        local endBorderHi = noAP and { 100, 220, 130, 200 } or { 230, 185, 75, 200 }
        -- P1-3: AP=0 + D1-D3 时更突出的结束按钮
        local isEarlyNoAP = noAP and (playerData_.day or 1) <= 3
        local endMainText = isEarlyNoAP and "👉 结束今天，进入明天" or (noAP and "✅ 结束今天" or ("结束今天  (第" .. playerData_.day .. "天)"))
        local endBtnHeight = isEarlyNoAP and 44 or 34
        local fixedEndDayBtn = UI.Panel {
            width = "100%", paddingHorizontal = 10, paddingVertical = 2,
            children = {
                UI.Panel {
                    width = "100%", height = endBtnHeight, borderRadius = 8,
                    backgroundColor = endBgColor,
                    borderWidth = 1.5, borderColor = endBorderHi,
                    flexDirection = "row", justifyContent = "center", alignItems = "center",
                    gap = 6,
                    onClick = function()
                        if transition_.active then return end
                        PlaySFX("click")
                        -- 翻倍收入广告：点击EndDay时弹窗询问（Day1-3新手期不弹，保持叙事连贯）
                        if playerData_.day >= 4 and AdManager.CanWatch("double_income", playerData_.day) then
                            showEndDayAdPopup_ = true
                            BuildUI()
                            return
                        end
                        local ok, err = pcall(EndDay)
                        if not ok then
                            log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                            currentPhase_ = PHASE_MANAGE
                            pcall(BuildUI)
                        end
                    end,
                    children = {
                        UI.Label { text = endMainText,
                            fontSize = 13, fontWeight = "bold",
                            fontColor = { 245, 255, 245, 255 } },
                        noAP and UI.Label { text = "· 进入明天",
                            fontSize = 10, fontColor = { 205, 248, 215, 180 } } or nil,
                    },
                },
            },
        }

        -- 事件摘要横条（合并特殊事件+竞对为1行横向紧凑展示）
        local eventChips = {}
        if dailySpecialEvent_ and dailySpecialEvent_.title then
            table.insert(eventChips, UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                paddingHorizontal = 8, paddingVertical = 4,
                backgroundColor = { 60, 60, 90, 140 }, borderRadius = 12,
                borderWidth = 1, borderColor = { 120, 120, 200, 100 },
                children = {
                    UI.Label { text = dailySpecialEvent_.icon or "⚡", fontSize = 11 },
                    UI.Label { text = dailySpecialEvent_.title, fontSize = 10, fontWeight = "bold",
                        fontColor = { 220, 240, 180, 240 } },
                    dailySpecialEvent_.bonus and UI.Label {
                        text = "+" .. dailySpecialEvent_.bonus,
                        fontSize = 9, fontColor = { 100, 220, 130, 255 } } or nil,
                },
            })
        end
        if rivalNpcs_ and #rivalNpcs_ > 0 then
            local topRival = rivalNpcs_[1]
            local steal = topRival.stealPct or 10
            local rivalChipBg = topRival.threat == "high" and { 120, 40, 40, 160 }
                or topRival.threat == "mid" and { 100, 70, 30, 140 }
                or { 60, 60, 60, 120 }
            table.insert(eventChips, UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                paddingHorizontal = 8, paddingVertical = 4,
                backgroundColor = rivalChipBg, borderRadius = 12,
                borderWidth = 1, borderColor = { 200, 100, 80, 100 },
                children = {
                    UI.Label { text = "🏪", fontSize = 10 },
                    UI.Label { text = topRival.name .. " -" .. steal .. "%",
                        fontSize = 10, fontColor = { 255, 180, 150, 230 } },
                    topRival.threat == "high" and UI.Label { text = "⚠️", fontSize = 9 } or nil,
                },
            })
        end
        local eventBar = #eventChips > 0 and UI.Panel {
            width = "100%", paddingHorizontal = 10, paddingVertical = 2,
            flexDirection = "row", flexWrap = "wrap", gap = 6, alignItems = "center",
            children = eventChips,
        } or nil

        -- [重构] quickBar 已移除，stratCard 直接条件插入

        -- ══════════════════════════════════════════════════════
        -- [v3 布局] 参照现代游戏设计：大场景 + 紧凑操作 + 5Tab导航
        -- 结构：[顶部状态栏36px][大全景flex][目标+主按钮][操作网格][5Tab底栏60px]
        -- ══════════════════════════════════════════════════════
        local actionChildren = {}

        -- ── 1) 顶部状态栏（紧凑深色横条，参照参考图） ──
        local topBarItems = {}
        -- 左：Day · 时间
        local dayText = "第" .. playerData_.day .. "天"
        table.insert(topBarItems, UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 4,
            paddingHorizontal = 8, paddingVertical = 4,
            backgroundColor = { 20, 60, 100, 200 }, borderRadius = 10,
            children = {
                UI.Label { text = "📅", fontSize = 10 },
                UI.Label { text = dayText, fontSize = 11, fontWeight = "bold", fontColor = { 255, 255, 255, 255 } },
            },
        })
        -- 中：金币
        table.insert(topBarItems, UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 4,
            paddingHorizontal = 8, paddingVertical = 4,
            backgroundColor = { 20, 60, 100, 200 }, borderRadius = 10,
            children = {
                UI.Label { text = "💰", fontSize = 10 },
                UI.Label { text = FormatMoney(playerData_.money), fontSize = 12, fontWeight = "bold",
                    fontColor = { 255, 220, 80, 255 } },
            },
        })
        -- 右：AP + 天气
        local apVal2 = playerData_.actionPoints or 3
        local apMax2 = playerData_.maxAP or 3
        local apCol2 = apVal2 > 0 and { 100, 255, 150, 255 } or { 255, 100, 80, 255 }
        local wLabel2, wColor2 = GetWeatherLabel()
        local apChildren = {
            UI.Label { text = "⚡", fontSize = 10 },
            UI.Label { text = apVal2 .. "/" .. apMax2, fontSize = 11, fontWeight = "bold", fontColor = apCol2 },
        }
        -- AP=0 时内联广告恢复
        if apVal2 <= 0 and AdManager.CanWatch("extra_ap", playerData_.day) then
            table.insert(apChildren, UI.Panel {
                paddingHorizontal = 4, paddingVertical = 1,
                backgroundColor = { 200, 140, 40, 200 }, borderRadius = 6,
                onClick = function()
                    AdManager.ShowAd("extra_ap", playerData_.day, function()
                        playerData_.actionPoints = playerData_.actionPoints + 1
                        AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                        BuildUI()
                    end)
                end,
                children = { UI.Label { text = "+1", fontSize = 8, fontWeight = "bold", fontColor = { 255, 255, 255, 255 } } },
            })
        end
        table.insert(topBarItems, UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 4,
            paddingHorizontal = 8, paddingVertical = 4,
            backgroundColor = { 20, 60, 100, 200 }, borderRadius = 10,
            children = apChildren,
        })
        table.insert(topBarItems, UI.Label { text = wLabel2, fontSize = 12, fontColor = wColor2 })

        local topStatusBar = UI.Panel {
            width = "100%", height = 36,
            backgroundColor = { 15, 25, 45, 240 },
            flexDirection = "row", alignItems = "center", justifyContent = "space-between",
            paddingHorizontal = 8,
            children = topBarItems,
        }
        table.insert(actionChildren, topStatusBar)

        -- ── 2) 全景图铺满 + 顶部数据/目标 + 底部浮动操作区 ──
        -- 目标文案
        local chapterGoal = ""
        local chapterProgress = ""
        if ChapterSystem and ChapterSystem.GetCurrentChapter then
            local ok99, ch = pcall(ChapterSystem.GetCurrentChapter)
            if ok99 and ch then
                chapterGoal = ch.goal or ch.title or ""
                chapterProgress = ch.progress or ""
            end
        end
        if chapterGoal == "" then chapterGoal = "发展你的网吧帝国" end

        -- 动态经营数据
        local okTraffic, traffic = pcall(RefreshTraffic)
        if not okTraffic then traffic = 0 end
        local okCap, capacity = pcall(CalcCafeCapacity)
        if not okCap then capacity = 1 end
        local okIncome, dailyInc = pcall(CalcDailyIncome)
        if not okIncome or type(dailyInc) ~= "number" then dailyInc = 0 end
        local hourlyInc = math.floor(dailyInc / 8)
        local reputation = playerData_.reputation or 0
        local starRating = string.format("%.1f", math.min(5.0, reputation / 20))

        -- 今日事件提示（队员问候 / 随机事件 / 默认经营提示）
        local todayTip = nil
        do
            local okG, DG = pcall(require, "DailyGreeting")
            if okG and DG and DG.GetTodayPreview then
                local tip = DG.GetTodayPreview()
                if tip then todayTip = tip end
            end
        end
        if not todayTip then
            -- 根据游戏状态生成简短经营提示
            local tips = {}
            if traffic >= capacity * 0.8 then table.insert(tips, "💥 客流爆满！考虑扩容")
            elseif traffic <= capacity * 0.2 then table.insert(tips, "📢 客少冷清，试试贴传单")
            end
            if (playerData_.durability or 100) < 30 then table.insert(tips, "⚠️ 设备老化严重，注意维修") end
            if playerData_.day == 1 then table.insert(tips, "💡 第一天：贴传单吸引客人吧！") end
            if #tips > 0 then todayTip = tips[math.random(1, #tips)] end
        end

        -- 底部浮动操作区内容
        local floatChildren = {}

        -- ═══ P0-2: 今日主目标卡片（最高视觉优先级，每天只显示一条） ═══
        do
            local day = playerData_.day or 1
            local mainObj = GetTodayMainObjective(day)
            if mainObj then
                -- 是否已完成今日主目标
                local objDone = (playerData_.mainObjDoneDay == day)
                local objBg = objDone and { 30, 80, 40, 200 } or { 80, 40, 10, 220 }
                local objBorder = objDone and { 80, 200, 100, 180 } or { 220, 160, 50, 200 }
                local objIcon = objDone and "✅" or (mainObj.icon or "🎯")
                local objTextColor = objDone and { 150, 240, 160, 255 } or { 255, 235, 160, 255 }
                local objSubColor = objDone and { 120, 200, 130, 180 } or { 200, 180, 130, 200 }
                local objSubText = objDone and "已完成 — 干得漂亮" or (mainObj.hint or "")

                table.insert(floatChildren, UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingVertical = 8,
                    backgroundColor = objBg,
                    borderRadius = 8,
                    borderWidth = 1.5, borderColor = objBorder,
                    gap = 2,
                    children = {
                        UI.Panel {
                            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                            children = {
                                UI.Label { text = objIcon, fontSize = 16 },
                                UI.Panel { flex = 1, flexShrink = 1, gap = 1, children = {
                                    UI.Label { text = mainObj.text, fontSize = 13, fontWeight = "bold",
                                        fontColor = objTextColor },
                                    objSubText ~= "" and UI.Label { text = objSubText, fontSize = 10,
                                        fontColor = objSubColor } or nil,
                                }},
                                UI.Label { text = "第" .. day .. "天", fontSize = 9,
                                    fontColor = { 160, 150, 130, 150 } },
                            },
                        },
                    },
                })
            end
        end

        -- 今日事件提示条（操作区顶部，给玩家方向感）
        if todayTip then
            table.insert(floatChildren, UI.Panel {
                width = "100%", paddingHorizontal = 10, paddingVertical = 5,
                backgroundColor = { 255, 200, 60, 20 },
                borderRadius = 6,
                borderWidth = 1, borderColor = { 200, 160, 40, 60 },
                flexDirection = "row", alignItems = "center", gap = 6,
                children = {
                    UI.Label { text = todayTip, fontSize = 11, fontColor = { 255, 225, 130, 255 },
                        flex = 1, flexShrink = 1 },
                },
            })
        end

        -- ═══ Kofi 状态小组件（Day5+ kofi加入后显示） ═══
        if playerData_.kofiJoined then
            local kTrust = playerData_.kofiTrust or 50
            -- 信任等级 & 颜色
            local kLevel, kColor, kIcon
            if kTrust >= 80 then
                kLevel = "挚友" kColor = { 100, 240, 180, 255 } kIcon = "💚"
            elseif kTrust >= 60 then
                kLevel = "信赖" kColor = { 180, 230, 140, 255 } kIcon = "🤝"
            elseif kTrust >= 40 then
                kLevel = "熟悉" kColor = { 200, 200, 120, 255 } kIcon = "👋"
            elseif kTrust >= 20 then
                kLevel = "认识" kColor = { 200, 160, 100, 255 } kIcon = "🙂"
            else
                kLevel = "疏远" kColor = { 180, 100, 80, 255 } kIcon = "😐"
            end
            -- 简短状态描述
            local kStatus = ""
            if playerData_.kofiStays == false then
                kStatus = "已离队" kIcon = "💔" kColor = { 180, 80, 80, 255 }
            elseif playerData_.aelRegistered and (playerData_.day or 0) >= 12 then
                kStatus = "备战AEL中"
            elseif playerData_.kofiJoined then
                kStatus = "训练中"
            end
            -- 信任条（mini progress bar）
            local barW = 60
            local fillW = math.floor(barW * math.min(1, kTrust / 100))
            table.insert(floatChildren, UI.Panel {
                width = "100%", paddingHorizontal = 10, paddingVertical = 5,
                backgroundColor = { 40, 50, 70, 140 },
                borderRadius = 6,
                borderWidth = 1, borderColor = { 60, 80, 120, 100 },
                flexDirection = "row", alignItems = "center", gap = 8,
                children = {
                    UI.Label { text = kIcon, fontSize = 13 },
                    UI.Label { text = "Kofi", fontSize = 11, fontWeight = "bold",
                        fontColor = { 220, 220, 255, 255 } },
                    -- 信任进度条
                    UI.Panel {
                        width = barW, height = 6, borderRadius = 3,
                        backgroundColor = { 30, 30, 50, 200 },
                        children = {
                            UI.Panel {
                                width = fillW, height = 6, borderRadius = 3,
                                backgroundColor = kColor,
                            },
                        },
                    },
                    UI.Label { text = kLevel, fontSize = 10, fontColor = kColor },
                    kStatus ~= "" and UI.Label { text = "· " .. kStatus, fontSize = 9,
                        fontColor = { 160, 160, 180, 180 } } or nil,
                },
            })
        end

        -- 每日赞助条（动态瓶颈检测，奖励玩家当前最需要的资源）
        -- P0-8: D1-D3 抑制广告条，确保新手叙事体验不被打断
        do
            local canSponsor = AdManager.CanWatch("sponsor_gift", playerData_.day)
                and (playerData_.day or 1) >= 4
            if canSponsor then
                -- 动态检测瓶颈，决定今日赞助奖励
                local sponsorIcon = "💼"
                local sponsorText = ""
                local sponsorRewardFn = nil

                local curAP = playerData_.actionPoints or 0
                local dur = playerData_.durability or 100
                local rep = playerData_.reputation or 0
                -- 声望升级阈值：每20点一级
                local repNextThreshold = (math.floor(rep / 20) + 1) * 20
                local repGap = repNextThreshold - rep

                if curAP <= 0 then
                    -- 瓶颈1：行动点耗尽
                    sponsorIcon = "☕"
                    sponsorText = "赞助商送来咖啡提神 · 行动点+1"
                    sponsorRewardFn = function()
                        playerData_.actionPoints = (playerData_.actionPoints or 0) + 1
                        AddLog("☕ 赞助商的咖啡让你精力充沛！行动点+1")
                    end
                elseif dur < 30 then
                    -- 瓶颈2：设备老化
                    sponsorIcon = "🔧"
                    sponsorText = "设备厂商免费上门保养 · 耐久+20"
                    sponsorRewardFn = function()
                        playerData_.durability = math.min(100, (playerData_.durability or 0) + 20)
                        AddLog("🔧 厂商保养完毕！设备耐久+20")
                    end
                elseif repGap <= 10 then
                    -- 瓶颈3：声望接近升级
                    sponsorIcon = "📰"
                    sponsorText = "本地媒体报道你的网吧 · 声望+5"
                    sponsorRewardFn = function()
                        playerData_.reputation = (playerData_.reputation or 0) + 5
                        AddLog("📰 媒体报道带来关注！声望+5")
                    end
                else
                    -- 保底：现金奖励（日收入50%）
                    local bonus = math.floor((playerData_.incomePerDay or 100) * 0.5)
                    sponsorIcon = "💼"
                    sponsorText = "品牌商投放广告位 · +$" .. bonus
                    sponsorRewardFn = function()
                        playerData_.money = (playerData_.money or 0) + bonus
                        AddLog("💼 广告赞助到账！+" .. FormatMoney(bonus))
                    end
                end

                table.insert(floatChildren, UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingVertical = 6,
                    backgroundColor = { 60, 180, 80, 25 },
                    borderRadius = 6,
                    borderWidth = 1, borderColor = { 80, 200, 100, 80 },
                    flexDirection = "row", alignItems = "center", gap = 6,
                    onClick = function()
                        AdManager.ShowAd("sponsor_gift", playerData_.day, function()
                            if sponsorRewardFn then sponsorRewardFn() end
                            PlaySFX("coin")
                            BuildUI()
                        end)
                    end,
                    children = {
                        UI.Label { text = sponsorIcon, fontSize = 13 },
                        UI.Label { text = sponsorText,
                            fontSize = 11, fontColor = { 150, 240, 160, 255 },
                            flex = 1, flexShrink = 1 },
                        UI.Label { text = "领取 ▶", fontSize = 10, fontWeight = "bold",
                            fontColor = { 100, 230, 120, 255 } },
                    },
                })
            end
        end

        -- ═══ 三层固定布局：[提示条] + [Tab头+策略迷你条] + [内容ScrollView] + [结束今天] ═══
        -- 判断策略卡状态：已选→迷你条(放Tab头下方)；未选→展开放提示层
        local stratChosen = playerData_.strategyChosen and playerData_.strategyChoice
        -- 第1层：全局提示条（事件 + 未选策略时展开选择面板）
        local tipChildren = {}
        if eventBar then table.insert(tipChildren, eventBar) end
        if stratCard and not stratChosen then table.insert(tipChildren, stratCard) end

        -- 第2层：Tab 切换头
        local availTabs = GetActionTabs()
        local tabBtns = {}
        for _, t in ipairs(availTabs) do
            local isActive = (currentActionTab_ == t.id)
            local hasActivity = HasTabActivity(t.id)
            table.insert(tabBtns, UI.Panel {
                flex = 1, height = 30,
                justifyContent = "center", alignItems = "center",
                -- 下划线指示器：激活态底部金色条，非激活态无
                borderWidth = { 0, 0, isActive and 2.5 or 0, 0 },
                borderColor = { 220, 175, 60, 255 },
                onClick = function()
                    currentActionTab_ = t.id
                    PlaySFX("click")
                    BuildUI()
                end,
                children = {
                    UI.Panel {
                        flexDirection = "row", alignItems = "center", gap = 4,
                        children = {
                            UI.Label {
                                text = t.icon .. " " .. t.label,
                                fontSize = 13, fontWeight = isActive and "bold" or "normal",
                                fontColor = isActive and { 255, 235, 160, 255 } or { 130, 120, 100, 180 },
                            },
                            hasActivity and not isActive and UI.Panel {
                                width = 6, height = 6, borderRadius = 3,
                                backgroundColor = { 255, 80, 80, 255 },
                            } or nil,
                        },
                    },
                },
            })
        end
        local tabHeader = #availTabs > 1 and UI.Panel {
            width = "100%", flexDirection = "row",
            paddingHorizontal = 8,
            borderWidth = { 0, 0, 1, 0 }, borderColor = { 80, 70, 55, 100 },
            children = tabBtns,
        } or nil

        -- 第3层：Tab 内容（ScrollView 限高）
        local tabContent = actionCard and UI.ScrollView {
            width = "100%", flex = 1, flexBasis = 0,
            children = { actionCard },
        } or nil

        -- 组装浮动区：提示 → Tab头 → [已选策略迷你条] → 内容 → 结束今天(固定底)
        for _, tip in ipairs(tipChildren) do table.insert(floatChildren, tip) end
        if tabHeader then table.insert(floatChildren, tabHeader) end
        if stratCard and stratChosen then table.insert(floatChildren, stratCard) end
        if tabContent then table.insert(floatChildren, tabContent) end
        table.insert(floatChildren, fixedEndDayBtn)

        -- ── 2a) 全景图（压缩高度，不再flex:1撑满） ──
        table.insert(actionChildren, UI.Panel {
            width = "100%", height = 110,
            backgroundImage = GetCafeSceneImage(), backgroundFit = "cover",
            children = {
                -- 目标条（左上覆盖）
                UI.Panel {
                    position = "absolute", top = 0, left = 0, right = 0,
                    paddingHorizontal = 10, paddingVertical = 5,
                    backgroundColor = { 0, 0, 0, 140 },
                    flexDirection = "row", alignItems = "center", gap = 6,
                    children = {
                        UI.Label { text = "🎯", fontSize = 12 },
                        UI.Label { text = chapterGoal, fontSize = 11, fontWeight = "bold",
                            fontColor = { 255, 230, 150, 255 }, flex = 1, flexShrink = 1 },
                        chapterProgress ~= "" and UI.Label { text = chapterProgress, fontSize = 9,
                            fontColor = { 180, 180, 180, 200 } } or nil,
                    },
                },
                -- 动态数据浮条（底部覆盖）
                UI.Panel {
                    position = "absolute", bottom = 0, left = 0, right = 0,
                    paddingHorizontal = 10, paddingVertical = 4,
                    backgroundColor = { 0, 0, 0, 100 },
                    flexDirection = "row", justifyContent = "center", gap = 12,
                    children = {
                        UI.Label { text = "👥" .. traffic .. "/" .. capacity,
                            fontSize = 10, fontColor = { 200, 230, 255, 220 } },
                        UI.Label { text = "💰+$" .. hourlyInc .. "/时",
                            fontSize = 10, fontColor = { 200, 255, 200, 220 } },
                        UI.Label { text = "⭐" .. starRating,
                            fontSize = 10, fontColor = { 255, 230, 150, 220 } },
                    },
                },
            },
        })

        -- ── 2b) 操作区（flex:1 占据剩余全部空间，不再限制 maxHeight） ──
        table.insert(actionChildren, UI.Panel {
            width = "100%", flex = 1, flexBasis = 0,
            backgroundColor = { 15, 12, 8, 230 },
            borderRadius = { 12, 12, 0, 0 },
            paddingHorizontal = 8, paddingTop = 6, paddingBottom = 4,
            gap = 3,
            children = floatChildren,
        })

        -- ── 3) 底部导航栏（复用已有的 BuildBottomNavBar，含角标/渐进解锁） ──
        table.insert(actionChildren, bottomNav)
        if cafePopup then table.insert(actionChildren, cafePopup) end

        -- EndDay 翻倍收入广告弹窗
        if showEndDayAdPopup_ then
            -- 预估今日收入（实时计算，比 incomePerDay 更准确）
            local okInc, estIncome = pcall(CalcDailyIncome)
            if not okInc or type(estIncome) ~= "number" then estIncome = 0 end
            -- 保底：收入为0时使用历史日均或最低保底值，避免"翻倍0"无意义
            if estIncome <= 0 then
                estIncome = math.max(playerData_.incomePerDay or 0, playerData_.computers * 25, 50)
            end
            local todayIncome = estIncome
            table.insert(actionChildren, UI.Panel {
                position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
                backgroundColor = { 0, 0, 0, 180 },
                justifyContent = "center", alignItems = "center",
                paddingHorizontal = 30,
                onClick = function()
                    -- 点击背景关闭弹窗并直接结束一天
                    showEndDayAdPopup_ = false
                    local ok, err = pcall(EndDay)
                    if not ok then
                        log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                        currentPhase_ = PHASE_MANAGE
                        pcall(BuildUI)
                    end
                end,
                children = {
                    UI.Panel {
                        width = "100%", backgroundColor = { 30, 22, 12, 255 },
                        borderRadius = PX.cardRadius, borderWidth = 2,
                        borderColor = { 205, 162, 60, 200 },
                        padding = 16, gap = 12, alignItems = "center",
                        onClick = function() end, -- 阻止穿透
                        children = {
                            UI.Label { text = "💰 翻倍今日收入？", fontSize = 16, fontWeight = "bold",
                                fontColor = { 245, 215, 128, 255 } },
                            UI.Label { text = "预估收入 " .. FormatMoney(todayIncome) .. " → " .. FormatMoney(todayIncome * 2),
                                fontSize = 13, fontColor = { 180, 220, 160, 255 } },
                            -- 看广告翻倍按钮
                            UI.Panel {
                                width = "100%", height = 44, borderRadius = PX.cardRadius,
                                backgroundColor = { 60, 140, 50, 255 },
                                justifyContent = "center", alignItems = "center",
                                marginTop = 4,
                                onClick = function()
                                    showEndDayAdPopup_ = false
                                    AdManager.ShowAd("double_income", playerData_.day, function()
                                        playerData_.money = (playerData_.money or 0) + todayIncome
                                        AddLog("🎬 看广告翻倍收入！额外获得 " .. FormatMoney(todayIncome))
                                        local ok, err = pcall(EndDay)
                                        if not ok then
                                            log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                                            currentPhase_ = PHASE_MANAGE
                                            pcall(BuildUI)
                                        end
                                    end)
                                end,
                                children = {
                                    UI.Label { text = "🎬 看广告翻倍", fontSize = 15, fontWeight = "bold",
                                        fontColor = { 255, 255, 255, 255 } },
                                },
                            },
                            -- 跳过按钮
                            UI.Panel {
                                width = "100%", height = 36, borderRadius = PX.cardRadius,
                                backgroundColor = { 50, 40, 30, 255 },
                                borderWidth = 1, borderColor = { 100, 80, 60, 150 },
                                justifyContent = "center", alignItems = "center",
                                onClick = function()
                                    showEndDayAdPopup_ = false
                                    local ok, err = pcall(EndDay)
                                    if not ok then
                                        log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                                        currentPhase_ = PHASE_MANAGE
                                        pcall(BuildUI)
                                    end
                                end,
                                children = {
                                    UI.Label { text = "跳过，直接结束", fontSize = 13,
                                        fontColor = { 140, 120, 100, 200 } },
                                },
                            },
                        },
                    },
                },
            })
        end

        -- 帝国版图 overlay
        if mapViewOpen_ then
            local okMap, mapContent = pcall(UIMapView.Build)
            if not okMap then
                log:Write(LOG_ERROR, "[BuildManageUI] UIMapView.Build error: " .. tostring(mapContent))
                mapContent = UI.Label { text = "⚠️ 地图加载失败", fontSize = 14, fontColor = { 255, 100, 100, 255 } }
            end
            table.insert(actionChildren, UI.Panel {
                position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
                backgroundColor = { 10, 15, 8, 230 },
                justifyContent = "flex-start", alignItems = "center",
                paddingTop = 10,
                onClick = function()
                    mapViewOpen_ = false
                    PlaySFX("click")
                    BuildUI()
                end,
                children = {
                    UI.Panel {
                        width = "95%", maxHeight = "92%",
                        backgroundColor = { 25, 30, 20, 250 },
                        borderRadius = 14,
                        borderWidth = 1, borderColor = { 80, 120, 50, 150 },
                        onClick = function() end, -- 阻止点击穿透关闭
                        children = {
                            UI.ScrollView {
                                id = "map-view-scroll",
                                width = "100%", flex = 1, flexBasis = 0,
                                children = { mapContent },
                            },
                        },
                    },
                },
            })
        end

        -- 非洲文化图鉴 overlay
        if loreOpen_ then
            local okLore, loreOverlay = pcall(BuildLoreOverlay)
            if okLore and loreOverlay then table.insert(actionChildren, loreOverlay) end
        end

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

    -- 邮箱弹窗层（升级Tab）
    if mailboxPopupOpen_ and manageTab_ == "upgrade" then
        local okM, mPop = pcall(BuildMailboxPopup)
        if okM and mPop then table.insert(otherChildren, mPop) end
    end

    -- 非洲文化图鉴 overlay（所有Tab可访问）
    if loreOpen_ then
        local okLore, loreOverlay = pcall(BuildLoreOverlay)
        if okLore and loreOverlay then table.insert(otherChildren, loreOverlay) end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bg,
        children = otherChildren,
    }
end


