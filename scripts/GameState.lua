---@diagnostic disable: undefined-global
-- ============================================================================
-- 1. 全局状态 & 常量
-- ============================================================================
---@type any
uiRoot_ = nil
gameTime_ = 0
lastDt_ = 0.016
lastBuildUITime_ = 0        -- 上次成功 BuildUI 的 gameTime（黑屏检测用）
lastBuildUIPhase_ = nil     -- 上次 BuildUI 对应的 phase

PHASE_TITLE    = "title"
PHASE_DIALOGUE = "dialogue"
PHASE_MANAGE   = "manage"
PHASE_TRAIN    = "train"
PHASE_EVENT    = "event"
PHASE_MATCH    = "match"
PHASE_RESULT   = "result"
PHASE_GAMEOVER = "gameover"
PHASE_COMIC   = "comic"

currentPhase_ = PHASE_TITLE
manageTab_ = "action"  -- 管理界面当前Tab: "action" / "upgrade" / "team"
branchOpenStep_ = 0   -- 分店开设流程: 0=关闭 1=选地点 2=选游戏
branchOpenLocOpts_ = nil  -- 待选地点列表（2-3个随机）
branchOpenSelLoc_ = nil   -- 已选地点
currentChapter_ = 1

-- 配色（暗色主题 · 焦橙点缀 v5 — 严格设计规格）
C = {
    -- 基底
    bg       = { 45, 36, 32, 255 },      -- #2D2420 页面底
    card     = { 61, 53, 48, 255 },      -- #3D3530 卡片/按钮底
    cardAlt  = { 72, 62, 56, 255 },      -- 卡片变体（略亮）
    -- 主色
    accent   = { 199, 91, 18, 255 },     -- #C75B12 焦橙（主色）
    accentDim= { 160, 72, 14, 255 },     -- 深焦橙
    accentLight = { 80, 55, 35, 255 },   -- 暗焦橙背景
    -- 功能色
    gold     = { 212, 160, 23, 255 },    -- #D4A017 金/货币
    goldDim  = { 160, 120, 18, 255 },    -- 暗金
    green    = { 90, 145, 85, 255 },     -- 低饱和绿（成功/正向）
    red      = { 230, 70, 70, 255 },     -- 亮红
    blue     = { 180, 155, 110, 255 },   -- 暖琥珀（禁蓝，替代信息色）
    -- 广告专用（暖金高亮，吸引点击）
    adBg     = { 50, 42, 32, 255 },      -- 深棕底（比card暗，衬托金字）
    adText   = { 255, 215, 80, 255 },    -- 亮金文字（高对比度吸引眼球）
    adBorder = { 212, 170, 50, 140 },    -- 金色边框
    -- 文字
    text     = { 255, 255, 255, 255 },   -- #FFFFFF 主文字
    textDim  = { 232, 224, 212, 255 },   -- #E8E0D4 副文字
    textLight= { 122, 107, 93, 255 },    -- #7A6B5D 辅助文字
    -- 边框/装饰
    border   = { 80, 68, 55, 255 },      -- 暗边框
    target   = { 230, 70, 70, 255 },     -- 亮红目标
    targetGlow = { 230, 100, 40, 210 },  -- 橙色辉光
    cellIdle = { 55, 48, 38, 240 },      -- 暗调格
    overlay  = { 10, 8, 5, 200 },        -- 深遮罩
    -- UI 专用 Token
    statusBar    = { 45, 36, 32, 250 },     -- StatusBar 底（同页面底）
    statusText   = { 255, 255, 255, 255 },  -- StatusBar 白文字
    tabBg        = { 45, 36, 32, 255 },     -- TabBar 底（同页面底）
    tabBorder    = { 80, 68, 55, 200 },     -- TabBar 底线
    bubble_self  = { 70, 58, 42, 240 },     -- 自己气泡
    bubble_other = { 58, 50, 40, 245 },     -- 他人气泡
    upgrade_bg   = { 61, 53, 48, 250 },     -- 升级卡片
    upgrade_active = { 72, 62, 56, 255 },   -- 升级中
    upgrade_max  = { 50, 70, 52, 250 },     -- 满级（低饱和绿底）
    diary_today  = { 61, 53, 48, 255 },     -- 今日日记
    diary_past   = { 52, 44, 38, 245 },     -- 过去日记
}

-- ============================================================================
-- 2. 场景图片映射
-- ============================================================================
SCENE_IMAGES = {
    title    = "image/scene_title_20260420090814.png",
    ch1      = "image/scene_ch1_arrival_20260420090811.png",
    ch2      = "image/scene_ch2_cafe_20260420090813.png",
    ch3      = "image/scene_ch3_rival_20260420090818.png",
    ch4      = "image/scene_ch4_blackout_20260420090821.png",
    ch5      = "image/scene_ch5_arena_20260420090843.png",
    event    = "image/scene_event_bg_20260420090813.png",
    victory  = "image/scene_victory_20260420090812.png",
    -- 新增场景图（沉浸感增强）
    match        = "image/scene_match_20260509034041.png",
    training     = "image/scene_training_20260509034331.png",
    night_market = "image/scene_night_market_20260509034605.png",
    recruit      = "image/scene_recruit_20260509034852.png",
    -- 结局专属场景图
    ending_beach    = "image/scene_ending_beach_20260509035149.png",
    ending_empire   = "image/scene_ending_empire_20260509035457.png",
    ending_depart   = "image/scene_ending_depart_20260509035747.png",
    ending_sunset   = "image/scene_ending_sunset_20260509040020.png",
    ending_legend   = "image/scene_ending_legend_20260511091931.png",
    ending_warmth   = "image/scene_ending_warmth_20260511091926.png",
    ending_bankrupt = "image/scene_ending_bankrupt_20260511091925.png",
    -- 分店城市场景
    branch_lagos    = "image/branch_lagos_20260511101806.png",
    branch_nairobi  = "image/branch_nairobi_20260511101827.png",
    branch_accra    = "image/branch_accra_20260511101847.png",
    branch_dakar    = "image/branch_dakar_20260511101918.png",
    branch_capetown = "image/branch_capetown_20260511101938.png",
    branch_kinshasa = "image/branch_kinshasa_20260511102003.png",
    -- 漫画开场面板
    comic_1 = "image/comic_panel_1_departure_20260512030921.png",
    comic_2 = "image/comic_panel_2_arrival_20260512030952.png",
    comic_3 = "image/comic_panel_3_opening_20260512032020.png",
    -- 网吧经营状态场景图（像素风格建筑截面）
    cafe_empty      = "image/cafe_empty_20260519093115.png",
    cafe_few        = "image/cafe_few_20260519093129.png",
    cafe_normal     = "image/cafe_normal_20260519093113.png",
    cafe_busy       = "image/cafe_busy_20260519093142.png",
    cafe_blackout   = "image/cafe_blackout_20260519093115.png",
    cafe_tournament = "image/cafe_tournament_20260519093115.png",
    cafe_bbq        = "image/cafe_bbq_20260519093112.png",
    cafe_streaming  = "image/cafe_streaming_20260519093116.png",
}

CHAPTER_IMAGES = {}
for _, key in ipairs(ChapterData.CHAPTER_IMAGE_KEYS) do
    table.insert(CHAPTER_IMAGES, SCENE_IMAGES[key] or SCENE_IMAGES.ch1)
end

-- ============================================================================
-- 2.4 漫画开场面板数据
-- ============================================================================
COMIC_PANELS = {
    {
        image = SCENE_IMAGES.comic_1,
        title = "卷不动了",
        lines = {
            "200份简历，30场面试",
            "最后的offer薪资还不够付房租",
            "5000美元，全部身家",
            "买了一张飞往非洲的单程票",
        },
    },
    {
        image = SCENE_IMAGES.comic_2,
        title = "瓦坎达维尔",
        lines = {
            "没有红绿灯，没有外卖",
            "街边的山羊比汽车多",
            "房东Musa指着铁皮屋说：",
            "\"最好的店面，月租200刀\"",
        },
    },
    {
        image = SCENE_IMAGES.comic_3,
        title = "Dragon Net Cafe",
        lines = {
            "三台二手电脑，一个路由器",
            "墙上喷漆画了一条龙",
            "油漆没干，第一个客人就来了",
            "组建战队，征战非洲电竞！",
        },
    },
}
comicPanelIdx_ = 1  -- 当前漫画面板索引

-- ============================================================================
-- 2.5 分店系统数据
-- ============================================================================
BRANCH_LOCATIONS = {
    { id = "lagos", name = "拉各斯", emoji = "🏙️",
      desc = "尼日利亚最大城市，人口超2000万的商业中心",
      flavor = "街头摩托车穿梭如织，霓虹灯和柴油发电机的轰鸣声此起彼伏。这里的年轻人对电竞疯狂痴迷。",
      bonusType = "traffic", bonusDesc = "客流+30%", incomeBonus = 1.3 },
    { id = "nairobi", name = "内罗毕", emoji = "🌆",
      desc = "肯尼亚首都，东非科技创新中心",
      flavor = "硅谷般的创业氛围弥漫在空气中。大学生们排队来打Dota和写代码，有时候两件事同时做。",
      bonusType = "tech", bonusDesc = "科技加成·收入+20%", incomeBonus = 1.2 },
    { id = "accra", name = "阿克拉", emoji = "🎓",
      desc = "加纳首都，西非文化与教育之都",
      flavor = "大学城的学生们下课后直奔网吧。这里的电竞氛围温和但持久，像加纳可可一样醇厚。",
      bonusType = "reputation", bonusDesc = "每日声望+8", incomeBonus = 1.0 },
    { id = "dakar", name = "达喀尔", emoji = "🌊",
      desc = "塞内加尔首都，大西洋畔的西非门户",
      flavor = "海风吹过来的时候带着鱼腥味和法语歌曲。港口的水手和渔民是你最忠实的夜间客户。",
      bonusType = "trade", bonusDesc = "黄金交易收益+15%", incomeBonus = 1.1 },
    { id = "capetown", name = "开普敦", emoji = "⛰️",
      desc = "南非著名港口城市，非洲电竞发展最快的地方",
      flavor = "桌山脚下的网吧，窗外就是壮丽的海景。这里的电竞基础设施全非洲最好。",
      bonusType = "esport", bonusDesc = "比赛奖金+25%", incomeBonus = 1.15 },
    { id = "kinshasa", name = "金沙萨", emoji = "🥁",
      desc = "刚果(金)首都，1700万人的音乐之城",
      flavor = "Rumba音乐从每个角落飘来。这座混乱又充满活力的城市，年轻人把网吧当成第二个家。",
      bonusType = "mood", bonusDesc = "队员心情+10", incomeBonus = 1.05 },
}

BRANCH_GAMES = {
    { id = "csgo", name = "CS:GO", emoji = "🔫",
      desc = "经典FPS·硬核玩家最爱",
      flavor = "枪声和闪光弹的声音从耳机里渗透出来，整个网吧弥漫着紧张的竞技氛围。",
      bonusDesc = "战力+8", bonusType = "combat" },
    { id = "dota2", name = "Dota 2", emoji = "🧙",
      desc = "硬核MOBA·策略大师的战场",
      flavor = "'GG！'的喊声此起彼伏。Dota玩家们讨论战术的声音比隔壁酒吧还热闹。",
      bonusDesc = "训练效率+20%", bonusType = "strategy" },
    { id = "lol", name = "英雄联盟", emoji = "⚔️",
      desc = "全球最热MOBA·人气之王",
      flavor = "每晚八点准时开始的排位赛时间，座位永远不够用。学生们为了五杀能等到凌晨。",
      bonusDesc = "声望获取+25%", bonusType = "popularity" },
    { id = "pubg", name = "PUBG", emoji = "🪖",
      desc = "大逃杀吃鸡·全民狂欢",
      flavor = "'大吉大利，今晚吃鸡！'——这句话被翻译成了至少五种非洲方言。",
      bonusDesc = "日收入+20%", bonusType = "income" },
    { id = "valorant", name = "Valorant", emoji = "💥",
      desc = "新兴战术FPS·年轻人的新宠",
      flavor = "最新潮的年轻人都在玩这个。虽然服务器延迟高，但热情挡不住。",
      bonusDesc = "更易招到高技能选手", bonusType = "recruit" },
}

-- 分店开设费用（按第几家分店递增）
BRANCH_COSTS = { 5000, 7000, 9000 }

-- ============================================================================
-- 3. 过场动画系统
-- ============================================================================
transition_ = {
    active = false,
    phase = "none",        -- "fadeOut" | "hold" | "fadeIn" | "none"
    timer = 0,
    fadeOutDur = 0.4,
    holdDur = 0.8,
    fadeInDur = 0.5,
    alpha = 0,
    titleText = "",        -- 过场中间显示的文字
    subtitleText = "",
    onMidpoint = nil,      -- 黑屏时的回调（切换场景）
    midpointCalled = false,
}

-- ============================================================================
-- UI 工具组件（百货商店物语风格）
-- ============================================================================

--- 面板标题栏（Kairosoft 风格：左侧色块标签 + 标题文字 + 可选关闭按钮）
---@param title string 标题文字
---@param opts table|nil 可选参数 { icon, onClose, color, compact }
function PanelHeader(title, opts)
    opts = opts or {}
    local bgColor = opts.color or C.accent
    local compact = opts.compact
    local fontSize = compact and 13 or 15
    local padV = compact and 6 or 9
    local padH = compact and 10 or 14

    local children = {
        UI.Panel {
            flexDirection = "row", alignItems = "center", gap = 6, flexShrink = 1,
            children = {
                opts.icon and UI.Label { text = opts.icon, fontSize = fontSize + 1 } or nil,
                UI.Label {
                    text = title, fontSize = fontSize,
                    fontColor = { 255, 255, 255, 255 }, fontWeight = "bold",
                    flexShrink = 1,
                },
            },
        },
    }
    -- 右侧：关闭按钮（白色半透明）
    if opts.onClose then
        children[#children + 1] = UI.Button {
            text = "✕", width = 26, height = 26,
            fontSize = 13, borderRadius = 13,
            backgroundColor = { 255, 255, 255, 50 },
            fontColor = { 255, 255, 255, 220 },
            onClick = function(self)
                PlaySFX("click")
                opts.onClose()
            end,
        }
    end

    return UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingHorizontal = padH, paddingVertical = padV,
        backgroundColor = bgColor,
        children = children,
    }
end

--- 信息行组件（标签: 值）
function InfoRow(label, value, color)
    return UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingVertical = 2,
        children = {
            UI.Label { text = label, fontSize = 12, fontColor = C.textDim },
            UI.Label { text = tostring(value), fontSize = 12,
                fontColor = color or C.text, fontWeight = "bold" },
        },
    }
end

--- 启动过场动画（委托给 CinematicTransition，支持电影级效果）
---@param title string 过场标题
---@param subtitle string 过场副标题
---@param onMidpoint function 黑屏中间执行的回调
---@param atmosphere string|nil 氛围文字（可选）
---@param chapterNum number|nil 章节编号（可选）
function StartTransition(title, subtitle, onMidpoint, atmosphere, chapterNum)
    CinematicTransition.Start({
        title = title or "",
        subtitle = subtitle or "",
        atmosphere = atmosphere or "",
        chapterNum = chapterNum or 0,
        onMidpoint = onMidpoint,
    })
    -- 同步代理状态（保持旧引用兼容）
    transition_.active = true
    transition_.phase = "fadeOut"
    transition_.alpha = 0
end

function UpdateTransition(dt)
    CinematicTransition.Update(dt)
    -- 同步代理状态
    local wasActive = transition_.active
    transition_.active = CinematicTransition.IsActive()
    transition_.alpha = CinematicTransition.GetAlpha()
    if not transition_.active then
        transition_.phase = "none"
        transition_.alpha = 0
        -- 转场刚结束（含异常终止）时，检查 UI 是否存在；不存在则立即恢复
        if wasActive then
            if uiRoot_ == nil then
                log:Write(LOG_WARNING, "[UpdateTransition] transition ended but uiRoot_ nil, phase=" .. tostring(currentPhase_) .. " → forcing BuildUI")
                pcall(BuildUI)
            end
        end
    end
end

-- ============================================================================
-- 4. 打字机效果系统
-- ============================================================================
typewriter_ = {
    fullText = "",
    displayLen = 0,
    speed = 28,         -- 字/秒
    timer = 0,
    done = false,
}

function StartTypewriter(text)
    typewriter_.fullText = text
    typewriter_.displayLen = 0
    typewriter_.timer = 0
    typewriter_.done = false
end

function UpdateTypewriter(dt)
    if typewriter_.done then return end
    typewriter_.timer = typewriter_.timer + dt
    local target = math.floor(typewriter_.timer * typewriter_.speed)
    -- 计算 UTF-8 字符数
    local charCount = Utf8Len(typewriter_.fullText)
    if target >= charCount then
        typewriter_.displayLen = charCount
        typewriter_.done = true
    else
        typewriter_.displayLen = target
    end
end

function GetTypewriterText()
    if typewriter_.done then return typewriter_.fullText end
    return Utf8Sub(typewriter_.fullText, 1, typewriter_.displayLen) .. "▌"
end

function SkipTypewriter()
    typewriter_.done = true
    typewriter_.displayLen = Utf8Len(typewriter_.fullText)
    CinematicDialogue.SkipTypewriter()
end

--- UTF-8 字符串长度
function Utf8Len(s)
    local len = 0
    local i = 1
    local bytes = #s
    while i <= bytes do
        local b = string.byte(s, i)
        if b < 0x80 then i = i + 1
        elseif b < 0xE0 then i = i + 2
        elseif b < 0xF0 then i = i + 3
        else i = i + 4 end
        len = len + 1
    end
    return len
end

--- UTF-8 字符串截取
function Utf8Sub(s, startChar, endChar)
    local i = 1
    local charIdx = 0
    local startByte, endByte = 1, #s
    local bytes = #s
    while i <= bytes do
        charIdx = charIdx + 1
        if charIdx == startChar then startByte = i end
        local b = string.byte(s, i)
        local step = 1
        if b < 0x80 then step = 1
        elseif b < 0xE0 then step = 2
        elseif b < 0xF0 then step = 3
        else step = 4 end
        if charIdx == endChar then endByte = i + step - 1; break end
        i = i + step
    end
    return string.sub(s, startByte, endByte)
end

-- ============================================================================
-- 5. 游戏数据
-- ============================================================================
playerData_ = {
    money = 5000, reputation = 0, day = 1,
    cafeName = "Dragon Net Cafe",
    computers = 3, chairLevel = 1, netSpeed = 1, acLevel = 0,
    -- v4 新增
    solarLevel = 0,     -- 太阳能板 (减少停电影响)
    foodShop = 0,       -- 烤鸡摊/小卖部
    decoLevel = 0,      -- 非洲装饰 (面具、壁画)
    securityLevel = 0,  -- 保安/安保
    havocCoins = 0,     -- 哈弗币 (三角洲货币)
    totalRuns = 0,      -- 跑刀总次数
    actionPoints = 3,   -- 每日行动点数（每天重置为3）
    karma = 0,          -- 抉择倾向（正=仁义 负=利己，影响结局）
    friendlyWins = 0,   -- 友谊赛胜场
    friendlyLosses = 0, -- 友谊赛败场
    debt = 0,           -- 借款余额（向 Mama B 借的）
    debtDay = 0,        -- 上次借款日（同一天不能多次借）
    equipCondition = 100, -- 设备状况 0-100%（影响收入）
    matchTier = 1,        -- 当前最高解锁的比赛等级
    tierWins = { 0, 0, 0 }, -- 各等级胜场数
    -- v5 新增：发电机/燃油系统
    generatorLevel = 0,   -- 发电机等级 0=无, 1=小型柴油机, 2=中型发电机, 3=大型静音发电机
    fuel = 0,             -- 当前燃油储量（升）
    fuelCapacity = 0,     -- 燃油罐容量（升）
    -- v5 新增：分店系统
    branches = {},        -- 分店列表 { {name, income, day} }
    totalEarnings = 0,    -- 历史总收入（用于终极结局判定）
    -- v5 新增：赛季系统
    seasonId = 1,         -- 当前赛季编号
    seasonWins = 0,       -- 本赛季胜场
    seasonRewards = {},   -- 已领取的赛季奖励
    -- v6 新增：黄金交易系统
    goldOunces = 0,       -- 黄金持有量（盎司，精确到0.1）
    -- v8 新增：政变系统
    coupDaysLeft = 0,     -- 政变剩余天数（0=无政变，>0=政变进行中）
    -- v9 新增：黄金特殊物品
    goldSafe = false,     -- 黄金保险箱（贬值/政变现金损失减半）
    goldVIP = false,      -- 黄金VIP卡（每日收入+15%）
    -- v7 新增：社区枢纽系统
    wellLevel = 0,        -- 水井等级 0=无, 1=手动压水井, 2=深井+水塔, 3=太阳能水泵
    roadLevel = 0,        -- 道路等级 0=土路, 1=碎石路, 2=水泥路, 3=柏油路+路灯
    coffeeLevel = 0,      -- 咖啡吧台 0=无, 1=速溶咖啡角, 2=手冲吧台, 3=精品咖啡吧
    jukeboxLevel = 0,     -- 点唱机 0=无, 1=卡带点唱机, 2=联网数字点唱机
    tournamentWins = 0,   -- 锦标赛夺冠次数
    tournamentPlayed = 0, -- 锦标赛参赛次数
    tournamentTierWins = {}, -- 各级锦标赛夺冠记录 { regional=N, national=N, ... }
    -- v10 留存系统
    lastSaveTimestamp = 0,      -- 上次保存时间戳(os.time)
    goalProgress = { develop = 1, social = 1, wealth = 1 },  -- 目标链进度(1-based)
    goalCompleted = {},         -- 已完成目标ID集合
    activePeriodicEvent = nil,  -- 当前周期事件 {id, remainDays, params}
    lastPeriodicDay = {},       -- {eventId = lastTriggerDay}
    npcStoryProgress = { kofi = 0, grace = 0, snake = 0 },   -- NPC支线剧情阶段
}

teamMembers_ = {}
eventLog_ = {}
unlockedAchievements_ = {}  -- 已解锁成就 id 集合
npcJournal_ = {}  -- NPC 事迹记录 { [npcId] = { events = { {day=, title=, choice=}, ... } } }
chaptersRead_ = {}  -- 已读过的章节号集合（重玩时可跳过）
dialogueOverride_ = nil      -- 对话覆盖模式（"elite_entrance" 等）
eliteEntranceDialogues_ = nil -- 精英入场对话数据
eliteEntranceIdx_ = nil       -- 精英入场对话当前索引

-- 群聊系统（代练工作室群）
chatMessages_ = {}             -- 群聊消息列表 { {sender, content, isSelf, isSystem, day} }
chatUnread_ = 0                -- 未读消息数
chatLastReadIdx_ = 0           -- 上次阅读到的消息索引（退出群聊时保存）
pendingChatDecision_ = nil     -- 当前待回复事件 { eventId, question, options = { {text, effect} } }
chatEventTriggered_ = {}       -- 已触发过的一次性聊天事件 id 集合
chatTriggerCooldowns_ = {}     -- 状态触发器冷却 {triggerId -> lastDay}

-- 日记系统（按天存储每日氛围+事件叙事）
diaryEntries_ = {}             -- { [day] = { atmo = "氛围文字", logs = {"日志1","日志2",...} } }
cachedAtmoDay_ = -1            -- 当天氛围文字生成缓存日
cachedAtmoText_ = ""           -- 当天氛围文字缓存
expandedDiaryDays_ = {}        -- { [day] = true } 展开状态（默认全部收起）

-- 客流量系统
trafficBonus_ = 0              -- 临时客流加成（事件触发，每日重置）
cachedTraffic_ = 0             -- 当日缓存客流
cachedTrafficDay_ = -1         -- 缓存对应的天数
customerAnim_ = {              -- 客流动画状态
    figures = {},                     -- { x, y, speed, phase, timer }
    spawnTimer = 0,
}

-- 留存系统全局变量
pendingOfflineReward_ = nil     -- 离线收益待领取 {earnings, hours, canDouble}
pendingTomorrowPreview_ = nil   -- 明日预告内容 {"预告1", "预告2", ...}
tutorialShownToday_ = false     -- 当日教程事件是否已展示

--- 庆祝粒子动画系统
celebration_ = {
    active = false,
    timer = 0,
    duration = 2.5,
    particles = {},  -- { x, y, vx, vy, size, r, g, b, a, life }
}

-- ============================================================================
-- 5.5 成就系统
-- ============================================================================
ACHIEVEMENTS = {
    { id = "first_recruit",   name = "伯乐初成",   desc = "招募第一位队员" },
    { id = "full_team",       name = "五虎将",     desc = "组建满编5人战队" },
    { id = "rich",            name = "非洲首富",   desc = "持有 $3000 以上" },
    { id = "famous",          name = "名声在外",   desc = "声望达到 200" },
    { id = "first_friendly",  name = "⚔️ 初出茅庐",   desc = "完成第一场友谊赛" },
    { id = "friendly_5wins",  name = "常胜将军",   desc = "友谊赛累计 5 胜" },
    { id = "synergy_first",   name = "🔗 初现联动",   desc = "激活第一个升级联动" },
    { id = "synergy_3",       name = "联动大师",   desc = "同时激活 3 个升级联动" },
    { id = "havoc_300",       name = "🪙 哈弗币大亨", desc = "累计获得 300 哈弗币" },
    { id = "day_30",          name = "老非洲",     desc = "经营满 30 天" },
    { id = "karma_saint",     name = "非洲圣人",   desc = "karma 达到 +10" },
    { id = "karma_dark",      name = "商业鬼才",   desc = "karma 达到 -8" },
    { id = "iron_fortress",   name = "铜墙铁壁",   desc = "激活铁壁网吧联动" },
    { id = "max_upgrade",     name = "顶级网吧",   desc = "任意一项升级到满级" },
}

function CheckAchievementCondition(id)
    if id == "first_recruit" then return #teamMembers_ >= 1
    elseif id == "full_team" then return #teamMembers_ >= 5
    elseif id == "rich" then return playerData_.money >= 3000
    elseif id == "famous" then return playerData_.reputation >= 200
    elseif id == "first_friendly" then return playerData_.friendlyWins + playerData_.friendlyLosses >= 1
    elseif id == "friendly_5wins" then return playerData_.friendlyWins >= 5
    elseif id == "synergy_first" then return #(CalcUpgradeSynergies()) >= 1
    elseif id == "synergy_3" then return #(CalcUpgradeSynergies()) >= 3
    elseif id == "havoc_300" then return playerData_.havocCoins >= 300
    elseif id == "day_30" then return playerData_.day >= 30
    elseif id == "karma_saint" then return playerData_.karma >= 10
    elseif id == "karma_dark" then return playerData_.karma <= -8
    elseif id == "iron_fortress" then return HasIronFortress()
    elseif id == "max_upgrade" then
        return playerData_.chairLevel >= 4 or playerData_.netSpeed >= 4
            or playerData_.acLevel >= 3 or playerData_.computers >= 12
    end
    return false
end

function CheckAchievements()
    for _, ach in ipairs(ACHIEVEMENTS) do
        if not unlockedAchievements_[ach.id] and CheckAchievementCondition(ach.id) then
            unlockedAchievements_[ach.id] = true
            AddLog("🏆 成就解锁: " .. ach.name .. " — " .. ach.desc)
            PlaySFX("victory"); TriggerCelebration()
        end
    end
end

function GetUnlockedCount()
    local n = 0
    for _ in pairs(unlockedAchievements_) do n = n + 1 end
    return n
end

CANDIDATE_POOL = {
    -- 特色人物（带剧情）
    { name = "Kofi",   talent = 90, mood = 100, skill = 12, trait = "闪电单车少年", emoji = "🧑🏿", avatar = "image/avatar_kofi_20260520061044.png",
      desc = "每天骑2小时自行车来网吧，妈妈反对他打游戏，但他的跑刀天赋惊人",
      fee = 80, special = true,
      perk = "晨练加成", perkDesc = "每天骑车12公里锻炼体能，比赛时耐力+15%", perkBonus = 8,
      flaw = "家庭压力", flawDesc = "妈妈随时可能发现真相，心情波动大", flawPenalty = 5,
      story = "Kofi每天凌晨五点起床，骑着破自行车翻过两座山头来网吧。他妈妈以为他去打工了。有一次你发现他偷偷把跑刀赚的哈弗币换成钱寄回家……" },
    { name = "Big Joe", talent = 72, mood = 100, skill = 8, trait = "前保镖·灵巧胖子", emoji = "🧑🏿", avatar = "image/avatar_bigjoe_20260520061052.png",
      desc = "前酋长保镖，200斤的体格却有极其灵巧的手指，擅长近距离刚枪",
      fee = 80, special = true,
      perk = "铁壁防御", perkDesc = "前保镖经验，防守战术时额外加成", perkBonus = 12,
      flaw = "体力有限", flawDesc = "体重大容易疲劳，加时赛表现下降", flawPenalty = 4,
      story = "Big Joe曾经是当地酋长的贴身保镖，因为一次事故离职。他说'保护人用拳头，保护队友用鼠标'。第一次玩三角洲就用霰弹枪拿了五杀。" },
    { name = "Grace",  talent = 88, mood = 100, skill = 22, trait = "牧师之女·暗夜玫瑰", emoji = "👩🏿", avatar = "image/avatar_grace_20260520061043.png",
      desc = "牧师的女儿，白天在教堂唱诗班，晚上偷偷来网吧跑刀",
      fee = 100, special = true,
      perk = "冷静之心", perkDesc = "唱诗班的专注力训练，高压下不崩盘", perkBonus = 10,
      flaw = "时间受限", flawDesc = "周日必须去教堂，训练时间比别人少", flawPenalty = 3,
      story = "Grace的父亲是镇上最大教堂的牧师。她每周日带领唱诗班，其余时间偷偷来网吧。她说'上帝教我精准——所以我每枪都是爆头'。" },
    { name = "Snake",  talent = 95, mood = 80, skill = 5, trait = "街头之王·毒蛇", emoji = "🧑🏿", avatar = "image/avatar_snake_20260520061042.png",
      desc = "街头帮派小头目，游戏嗅觉惊人，但脾气火爆需要管教",
      fee = 130, special = true,
      perk = "嗜血本能", perkDesc = "街头生存直觉，进攻战术时爆发力惊人", perkBonus = 15,
      flaw = "暴躁易怒", flawDesc = "心情低时可能摔鼠标，影响全队士气", flawPenalty = 8,
      story = "Snake在街头混了五年，所有人都怕他。但他说'在游戏里杀人比在街上干净'。你需要花时间收服他——一旦他认你当老大，他会拼命。" },
    { name = "Mama B", talent = 65, mood = 100, skill = 35, trait = "烤鸡婆婆·隐藏狙神", emoji = "👩🏿", avatar = "image/avatar_mamab_20260520061044.png",
      desc = "门口卖烤鸡的40岁大婶，竟然有着恐怖的狙击天赋",
      fee = 50, special = true,
      perk = "稳如老狗", perkDesc = "40年人生阅历，心态永远稳定", perkBonus = 6,
      flaw = "大龄选手", flawDesc = "反应速度不如年轻人，技能成长较慢", flawPenalty = 3,
      story = "Mama Blessing本来只是在你网吧门口卖烤鸡。有天她好奇坐下来试了一局，结果用狙击枪打出了全场最高击杀。你当场就惊了。" },
    { name = "Prince", talent = 85, mood = 100, skill = 15, trait = "酋长之子·王子", emoji = "🧑🏿", avatar = "image/avatar_prince_20260520061040.png",
      desc = "当地部落酋长的儿子，想通过电竞证明自己不只是个富二代",
      fee = 25, special = true,
      perk = "人脉广阔", perkDesc = "酋长之子的身份，赢了比赛声望加倍", perkBonus = 7,
      flaw = "公子脾气", flawDesc = "输了比赛心情暴跌，需要哄", flawPenalty = 6,
      story = "Prince Adeyemi的父亲是当地最有权势的酋长。他不缺钱，但缺认可。他说'我不要父亲给我的一切，我要自己赢来的荣耀'。象征性收点费用，但他想当队长。" },
    { name = "小雪",   talent = 82, mood = 100, skill = 28, trait = "支教老师·跨国连线", emoji = "👩", avatar = "image/avatar_xiaoxue_20260520061051.png",
      desc = "中国来的支教志愿者，教孩子们中文之余也教他们打三角洲",
      fee = 60, special = true,
      perk = "团队粘合", perkDesc = "温柔的性格能安抚队友情绪，全队心情+", perkBonus = 8,
      flaw = "支教期限", flawDesc = "支教合同到期可能要回国", flawPenalty = 2,
      story = "小雪(Yuki)是从四川来非洲支教的大学生。她教当地孩子说中文，也教他们打三角洲。她说'我在这里找到了比大城市更纯粹的快乐'。" },
    { name = "Thunder",talent = 93, mood = 100, skill = 3, trait = "退役短跑·闪电反应", emoji = "🧑🏿", avatar = "image/avatar_thunder_20260520061045.png",
      desc = "退役短跑运动员，反应速度堪称变态，0.1秒出枪",
      fee = 100, special = true,
      perk = "闪电反应", perkDesc = "0.1秒出枪速度，进攻战术额外加成", perkBonus = 12,
      flaw = "旧伤复发", flawDesc = "高强度训练后手腕疼痛，需要休息", flawPenalty = 5,
      story = "Thunder曾是国家短跑队候补队员，因伤退役。他的反应速度是普通人的三倍。第一次摸鼠标就展现了恐怖的甩枪速度，你从没见过这种天赋。" },
}

-- ============================================================================
-- 5.6 NPC 档案表（人物页面用）
-- ============================================================================
NPC_PROFILES = {
    { id = "mama_blessing", name = "Mama Blessing", emoji = "👩🏿", role = "烤鸡摊主",
      bio = "网吧门口卖烤鸡的40岁大婶。她的烤鸡是队员们的精神支柱，也是网吧的灵魂人物。",
      tease = "网吧门口飘来阵阵烤鸡香味……这位大婶似乎不只会做烤鸡？", hint = "经营到「本地节日庆典」或招募 Mama B" },
    { id = "kwame",         name = "Kwame",         emoji = "🧑🏿", role = "忠实老顾客",
      bio = "网吧最守规矩的常客，从不欠费。家境不宽裕但为人正直。",
      tease = "有个常客总在最便宜的位置坐着，从不多花一分钱。他有心事……", hint = "持续经营，随机触发「老顾客求助」" },
    { id = "baobao",        name = "包包哥",         emoji = "🧑",  role = "浙江老乡",
      bio = "在马达加斯加开网吧的浙江人，四处跑市场。热心肠，人脉广。",
      tease = "听说附近有个浙江老乡也在非洲做生意，说不定哪天会来串门。", hint = "持续经营，随机触发「中国同胞来访」" },
    { id = "xiaoma",        name = "小马",           emoji = "🧑🏿", role = "网吧帮工",
      bio = "你雇来的本地帮工，年纪不大，家里困难。犯过错，但本性不坏。",
      tease = "你的零钱好像少了一点？那个帮工的眼神有些闪躲……", hint = "持续经营，随机触发「员工偷零钱」" },
    { id = "neighbor",      name = "隔壁大爷",       emoji = "👴🏿", role = "隔壁邻居",
      bio = "住在网吧隔壁的老爷爷，孙子经常来网吧玩。心地善良，常送水果。",
      tease = "隔壁屋子传来收音机的声音，偶尔飘过来水果的香味。", hint = "持续经营，随机触发「邻居送水果」" },
    { id = "principal",     name = "校长",           emoji = "🧑🏿", role = "中学校长",
      bio = "附近中学的校长。希望通过电脑和电竞给学生们一条新路。",
      tease = "附近学校的校长最近在四处寻找合作机会……电竞能改变孩子们吗？", hint = "持续经营，随机触发「学校合作邀请」" },
    { id = "tanker_driver", name = "油罐车司机",     emoji = "🧑🏿", role = "过路司机",
      bio = "开油罐车跑长途的司机。非洲的路到处是坑，但人心不是。",
      tease = "远处传来油罐车沉重的引擎声……据说那个司机消息很灵通。", hint = "持续经营，随机触发「油罐车路过」" },
    { id = "blogger",       name = "旅行博主",       emoji = "📸",  role = "网红博主",
      bio = "拥有百万粉丝的旅行/美食博主，四处探店拍视频。",
      tease = "TikTok上有个百万粉丝的博主在附近拍vlog……会来你的网吧吗？", hint = "声望提高后触发「网红打卡潮」" },
    { id = "ngo",           name = "数字非洲",       emoji = "🎁",  role = "NGO 组织",
      bio = "致力于用数字技术帮助非洲青年的公益组织。",
      tease = "「数字非洲」公益基金在本地区寻找合作网吧……你符合条件吗？", hint = "声望提高后触发「NGO捐赠电脑」" },
    { id = "embassy",       name = "大使馆文化处",    emoji = "🏛️",  role = "中国大使馆",
      bio = "中国驻当地大使馆文化处，推动中非青年交流。",
      tease = "大使馆最近在推中非青年文化交流项目，可能会有电话打来……", hint = "声望提高后触发「大使馆来电」" },
    { id = "dragon_dog",    name = "Dragon",         emoji = "🐕",  role = "网吧吉祥物",
      bio = "一只流浪小狗，被你收养后成了网吧的明星。",
      tease = "街角有只流浪狗总在网吧门口转悠，眼巴巴地看着你……", hint = "持续经营，随机触发「流浪狗收养」" },
    { id = "kofi_jr",       name = "Kofi Junior",    emoji = "🧑🏿", role = "Mama Blessing 的儿子",
      bio = "在首都学IT的年轻人。回到小镇后成了网吧的兼职技术员。",
      tease = "Mama Blessing提到她在首都学IT的儿子最近要回来了……", hint = "经营12天后触发「Mama Blessing的儿子回来了」" },
}

-- 事件标题 → NPC ID 映射（用于自动记录 NPC 事迹）
EVENT_NPC_MAP = {
    ["邻居送水果"]               = "neighbor",
    ["老顾客求助"]               = "kwame",
    ["中国同胞来访"]             = "baobao",
    ["员工偷零钱"]               = "xiaoma",
    ["Mama Blessing的儿子回来了"] = { "mama_blessing", "kofi_jr" },
    ["学校合作邀请"]             = "principal",
    ["油罐车路过"]               = "tanker_driver",
    ["网红打卡潮"]               = "blogger",
    ["网红博主来访"]             = "blogger",
    ["NGO捐赠电脑"]              = "ngo",
    ["大使馆来电"]               = "embassy",
    ["大使馆电竞活动"]           = "embassy",
    ["流浪狗收养"]               = "dragon_dog",
    ["本地节日庆典"]             = "mama_blessing",
    -- NPC 故事线扩展
    ["Kwame的电竞梦"]            = "kwame",
    ["Kwame获奖了"]              = "kwame",
    ["小马的生意经"]             = "xiaoma",
    ["小马出师了"]               = "xiaoma",
    ["邻居的果树危机"]           = "neighbor",
    ["丰收季节"]                 = "neighbor",
    ["校长的电脑课"]             = "principal",
    ["毕业典礼"]                 = "principal",
    ["油荒"]                     = "tanker_driver",
    ["龙狗生崽了"]               = "dragon_dog",
    ["龙狗成网红"]               = "dragon_dog",
    ["Kofi的音乐梦"]             = "kofi_jr",
    -- 剧情事件 NPC 映射（STORY_EVENTS 触发时也需要记录）
    ["门口的烤鸡香"]             = "mama_blessing",
    ["停电危机·Mama B的智慧"]    = "mama_blessing",
    ["包包哥驾到"]               = "baobao",
    ["第一个三角洲玩家"]         = "kwame",
    ["Kofi的秘密"]               = "kwame",
    ["Snake的考验"]              = "xiaoma",
    ["Grace的秘密被发现了"]      = "principal",
    ["酋长之子的选择"]           = "neighbor",
}

--- 记录 NPC 事迹
function RecordNPCEncounter(eventTitle, choiceText)
    local npcIds = EVENT_NPC_MAP[eventTitle]
    if not npcIds then return end
    -- 统一为数组
    if type(npcIds) == "string" then npcIds = { npcIds } end
    for _, npcId in ipairs(npcIds) do
        if not npcJournal_[npcId] then
            npcJournal_[npcId] = { events = {} }
        end
        table.insert(npcJournal_[npcId].events, {
            day = playerData_.day,
            title = eventTitle,
            choice = choiceText,
        })
    end
end

-- 章节剧情（从 ChapterData 模块加载）
CHAPTERS = ChapterData.CHAPTERS
CHAPTERS_OLD_ = {
    {
        title = "第一章：非洲创业",
        atmosphere = "飞机引擎嗡嗡作响，窗外是绵延无际的非洲红土大陆。一段未知的旅程即将开始。",
        dialogues = {
            { speaker = "旁白", text = "18小时航程后，你带着全部身家5000美元，降落在非洲大陆。" },
            { speaker = "你",   text = "在国内卷不动，那就去非洲创业！开网吧，搞电竞，带非洲兄弟跑刀三角洲！" },
            { speaker = "旁白", text = "瓦坎达维尔小城。三台二手电脑、一个路由器、几把塑料凳——Dragon Net Cafe，正式开业。" },
            { speaker = "旁白", text = "每到傍晚，一群年轻人聚在窗外看别人玩三角洲。你设了两台免费体验机，网吧瞬间爆满。" },
            { speaker = "内心", text = "这些孩子用键盘和鼠标，在数字世界里淘金。游戏不只是游戏——它是一条出路。", type = "monologue" },
            { speaker = "你",   text = "组建战队，跑刀赚钱，最终打进职业联赛！Dragon Force，就叫这个名字！" },
            { speaker = "旁白", text = "名声传开，竞争也来了——隔壁城市富二代砸了一万刀开了'Gold Net'网吧。但B站上'纯黑跑刀'的视频意外爆火，你的网吧成了网红打卡点。" },
            { speaker = "内心", text = "从代练到职业联赛……这一步，才是真正的分水岭。全非洲三角洲锦标赛，我们来了。", type = "monologue" },
        },
    },
    {
        title = "第二章：至暗时刻",
        atmosphere = "整个城市陷入黑暗，远处偶尔传来发电机的轰鸣。屏幕的微光是唯一的希望。",
        dialogues = {
            { speaker = "旁白", text = "距离全非洲大赛还有两周——整个瓦坎达维尔连续四天大停电。" },
            { speaker = "你",   text = "不行，不能停下训练！离比赛只有两周了！" },
            { speaker = "旁白", text = "你跑了三个城市，花800刀从废品站淘来一台发电机。队员们在摇晃的灯光下挤在一起训练。" },
            { speaker = "内心", text = "看着他们在摇晃的灯光下拼命的样子，我突然明白了——不是我在帮他们追梦，是他们在教我什么叫不放弃。", type = "monologue" },
            { speaker = "旁白", text = "【全队士气大涨！所有队员技术 +8】" },
        },
        skillBoost = 8,
    },
    {
        title = "第三章：Dragon Force 出征",
        atmosphere = "决赛的日子终于到来。所有人的心都悬着，空气中弥漫着紧张与期待。",
        dialogues = {
            { speaker = "旁白", text = "比赛日。六小时大巴后，你们来到拉各斯非洲电竞中心。12个国家，32支强队。" },
            { speaker = "内心", text = "从铁皮屋到电竞中心，从塑料凳到电竞椅。这条路，我们用汗水和停电的黑夜一步步走过来的。值了。", type = "monologue" },
            { speaker = "你",   text = "兄弟们，紧张吗？" },
            { speaker = "旁白", text = "'老板，我们连停电都扛过来了——还怕这个？纯黑跑刀，谁怕谁！'" },
            { speaker = "你",   text = "今天，让全世界知道——Dragon Force，我们来了！" },
            { speaker = "旁白", text = "【决赛即将开始——证明一切！】" },
        },
        isFinalBattle = true,
    },
}

-- 升级配置（含非洲特色）
UPGRADES = {
    computer = { name = "加一台电脑",    costs = {800, 1200, 1800, 2500, 3500, 5000, 7000, 10000, 14000, 18000, 25000, 35000}, icon = "🖥️",
        desc = "从集市淘来的二手主机",
        levelDesc = {
            "集市淘来的二手戴尔",
            "加装了防沙网的翻新联想",
            "带RGB灯的网吧版神机",
            "走私来的矿卡4060整机",
            "全非洲最强·水冷4090战舰",
            "从迪拜空运的商务工作站",
            "电竞品牌定制机·带战队Logo",
            "双路水冷超频怪兽",
            "企业级刀片服务器改装机",
            "比赛级专业电竞PC·144Hz标配",
            "全息散热概念机·街坊围观",
            "钻石级旗舰·非洲大陆最强配置",
        } },
    chair    = { name = "升级座椅",      costs = {300, 600, 1000, 1500},        icon = "💺",
        desc = "屁股坐塑料凳练不出枪神",
        levelDesc = { "集市塑料凳·包断腿", "折叠椅·至少有靠背了", "仿版电竞椅·印着假Logo", "真·雷蛇电竞椅·从拉各斯港口截的" } },
    net      = { name = "升级网速",      costs = {500, 1000, 2000, 3000},       icon = "📡",
        desc = "200ms延迟怎么跑刀？",
        levelDesc = { "村口信号塔·200ms起步", "加了定向天线·150ms稳定", "拉了光纤·80ms丝滑", "卫星锅+光纤双路由·30ms极限" } },
    ac       = { name = "装/升级空调",   costs = {400, 800, 1500},              icon = "❄️",
        desc = "40度高温手都是汗怎么瞄准",
        levelDesc = { "二手风扇·勉强吹到三号机", "壁挂空调·非洲罕见的奢侈品", "中央空调·整条街都来蹭凉" } },
    solar    = { name = "太阳能板",      costs = {600, 1200, 2000},             icon = "☀️",
        desc = "把非洲最不缺的阳光变成电",
        levelDesc = { "一块旧太阳能板·能给手机充电", "屋顶排列太阳能矩阵", "微型太阳能电站·半条街供电" } },
    food     = { name = "烤鸡摊/小卖部", costs = {300, 700, 1200},              icon = "🍗",
        desc = "Mama B的秘制烤鸡·半条街闻着香",
        levelDesc = { "路边烤鸡摊·炭火现烤", "加了冰柜卖汽水·芬达可乐管够", "小超市·泡面辣条能量饮料一应俱全" } },
    deco     = { name = "非洲装饰",      costs = {200, 500, 1000},              icon = "🎨",
        desc = "铁皮墙上挂战神面具",
        levelDesc = { "手工木雕面具·镇宅辟邪", "LED灯条+涂鸦墙·赛博部落风", "全息投影+部落图腾·非洲最酷网吧" } },
    security = { name = "请保安",        costs = {400, 800},                    icon = "🛡️",
        desc = "Big Joe推荐的兄弟们",
        levelDesc = { "一个退役拳手·在门口嗑瓜子", "两个前军人·带对讲机巡逻" } },
    generator = { name = "发电机",       costs = {500, 1200, 2500},             icon = "⚡",
        desc = "停电是非洲日常·但跑刀不能停",
        levelDesc = { "二手小型柴油机·轰隆隆响", "中型汽油发电机·稳定供电", "大型静音发电机·全店满载不跳闸" } },
    -- v7 社区枢纽
    well     = { name = "挖一口水井",   costs = {400, 900, 1800},              icon = "💧",
        desc = "干净的水，比WiFi更稀缺",
        levelDesc = { "手动压水井·排队打水的村民络绎不绝", "深井+水塔·半条街不用走两公里挑水了", "太阳能水泵+蓄水池·全村的饮水工程" } },
    road     = { name = "修缮门前路",   costs = {500, 1200, 2200},             icon = "🛤️",
        desc = "土路扬尘毁设备，下雨变泥潭",
        levelDesc = { "填坑铺碎石·至少摩托车不颠了", "水泥路面·雨天不用趟泥水进门", "柏油路+太阳能路灯·整条街的骄傲" } },
    coffee   = { name = "咖啡吧台",     costs = {350, 800, 1500},              icon = "☕",
        desc = "一杯咖啡，一个下午，一段故事",
        levelDesc = { "简易咖啡角·速溶咖啡配塑料杯", "吧台+手冲设备·用当地豆子现磨", "精品咖啡吧+甜点柜·小镇的星巴克" } },
    jukebox  = { name = "老式点唱机",   costs = {300, 700},                    icon = "🎵",
        desc = "音乐是这片土地的灵魂",
        levelDesc = { "二手卡带点唱机·非洲鼓点配电子乐", "联网数字点唱机·全球音乐随便点" } },
}

-- 升级显示顺序（分三组：集市 / 社区投资 / 文化空间）
UPGRADE_ORDER = { "computer", "chair", "net", "ac", "solar", "food", "deco", "security", "generator" }
UPGRADE_COMMUNITY = { "well", "road" }
UPGRADE_CULTURE = { "coffee", "jukebox" }

