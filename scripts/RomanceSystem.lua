---@diagnostic disable: undefined-global
-- ============================================================================
-- RomanceSystem.lua — 感情线系统
-- 双线并行：小雪（中国留学生）& Grace（本地商务女性）
-- 设计原则：零AP微事件日常推进 + 关键节点消耗AP
-- ============================================================================
local M = {}

-- ============================================================================
-- 常量
-- ============================================================================
M.MICRO_CHANCE_CORE = 0.60   -- 核心微事件每日触发概率
M.MICRO_CHANCE_BONUS = 0.40  -- 锦上添花微事件触发概率
M.COOLDOWN_DAYS = 2          -- 同一角色微事件最短间隔天数
M.AFFINITY_CAP = 100

-- 阶段晋升阈值（修复#3后）
M.THRESHOLDS = {
    xiaoxue = { 15, 35, 55, 75 },  -- stage1→2, 2→3, 3→4, 4→5
    grace   = { 15, 32, 52, 72 },
}

-- ============================================================================
-- 初始化 bonds 数据结构（在 GameState 初始化时调用）
-- ============================================================================
function M.InitBonds(playerData)
    if not playerData.bonds then
        playerData.bonds = {
            xiaoxue = {
                stage = 0,       -- 0=未激活, 1~5
                affinity = 0,
                flags = {},
                lastInteractDay = 0,
                triggered = {},  -- 已触发事件ID集合
                route = nil,     -- nil / "close" / "slow"
            },
            grace = {
                stage = 0,
                affinity = 0,
                flags = {},
                lastInteractDay = 0,
                triggered = {},
                route = nil,
            },
            crossover = {
                triggered = {},
            },
        }
    end
    return playerData.bonds
end

-- ============================================================================
-- 辅助函数
-- ============================================================================
local function getBond(charId)
    if not playerData_ or not playerData_.bonds then return nil end
    return playerData_.bonds[charId]
end

local function addAffinity(charId, amount)
    local bond = getBond(charId)
    if not bond then return end
    bond.affinity = math.min(M.AFFINITY_CAP, math.max(0, bond.affinity + amount))
end

local function hasFlag(charId, flag)
    local bond = getBond(charId)
    if not bond then return false end
    return bond.flags[flag] == true
end

local function setFlag(charId, flag, value)
    local bond = getBond(charId)
    if not bond then return end
    bond.flags[flag] = value ~= false
end

local function isTriggered(charId, eventId)
    local bond = getBond(charId)
    if not bond then return true end
    return bond.triggered[eventId] == true
end

local function markTriggered(charId, eventId)
    local bond = getBond(charId)
    if not bond then return end
    bond.triggered[eventId] = true
end

local function getStage(charId)
    local bond = getBond(charId)
    return bond and bond.stage or 0
end

local function setStage(charId, stage)
    local bond = getBond(charId)
    if bond then bond.stage = stage end
end

-- ============================================================================
-- 阶段晋升检查
-- ============================================================================
function M.CheckPromotion(charId)
    local bond = getBond(charId)
    if not bond or bond.stage >= 5 then return false end
    local thresholds = M.THRESHOLDS[charId]
    if not thresholds then return false end
    local currentStage = bond.stage
    if currentStage < 1 then return false end  -- stage 0→1 由剧情事件触发
    local needed = thresholds[currentStage]    -- currentStage对应的晋升阈值
    if needed and bond.affinity >= needed then
        -- 额外条件检查
        if charId == "xiaoxue" then
            if currentStage == 3 then
                -- Stage3→4 需要 Day≥28
                if playerData_.day < 28 then return false end
            elseif currentStage == 4 then
                -- Stage4→5 需要 Day≥35
                if playerData_.day < 35 then return false end
            end
        elseif charId == "grace" then
            if currentStage == 3 then
                -- Stage3→4 需要 Day≥22
                if playerData_.day < 22 then return false end
            elseif currentStage == 4 then
                -- Stage4→5 需要 Day≥30
                if playerData_.day < 30 then return false end
            end
        end
        bond.stage = currentStage + 1
        AddLog(string.format("💕 【感情线】与%s的关系进入了新阶段！",
            charId == "xiaoxue" and "小雪" or "Grace"))
        return true
    end
    return false
end

-- ============================================================================
-- 微事件数据池
-- ============================================================================

-- 标记说明: tier = "core" | "bonus"
M.MICRO_EVENTS = {
    -- ====================================================================
    -- 小雪线
    -- ====================================================================
    xiaoxue = {
        -- ── Stage 1: 初来乍到 ──
        { id = "xs_share_snack", stage = 1, tier = "core", affinity = 3,
          title = "🍪 分零食",
          text = "小雪从包里掏出一袋旺旺仙贝：\"老板要不要？我从国内带了好多……这边买不到。\"她小心翼翼地递过来，像是怕你拒绝。",
        },
        { id = "xs_ask_wifi", stage = 1, tier = "core", affinity = 2,
          text = "小雪举着手机走过来：\"老板老板，WiFi密码是什么呀？我的流量已经……\"她的手机屏幕上是和妈妈没发出去的微信消息。",
          title = "📱 问WiFi密码",
        },
        { id = "xs_lost_look", stage = 1, tier = "core", affinity = 3,
          title = "😶 迷路的眼神",
          text = "你注意到小雪坐在角落发呆，看着窗外陌生的街景。她发现你看她，赶紧挤出笑容：\"没事没事！只是在想……这里的云和家里不太一样。\"",
        },
        { id = "xs_phone_call", stage = 1, tier = "bonus", affinity = 2,
          title = "📞 给妈妈打电话",
          text = "深夜，你听到仓库传来小雪压低的声音：\"妈，我很好……吃得很好……不不不，这边一点都不危险……\"她的声音在颤抖。你假装没听到。",
        },
        { id = "xs_curious_menu", stage = 1, tier = "bonus", affinity = 2,
          title = "🍛 好奇菜单",
          text = "小雪盯着门口小摊的菜单看了五分钟：\"这个fufu是什么？为什么要用手吃？……我可以用筷子吗？\"摊主大笑。",
        },

        -- ── Stage 2: 日渐熟悉 ──
        { id = "xs_teach_chinese", stage = 2, tier = "core", affinity = 4,
          title = "🈶 教中文",
          text = "小雪在白板上写了个\"龙\"字：\"这是你网吧名字的意思！来，跟我写——横、竖、撇……\"你的笔画歪歪扭扭，她捂嘴笑：\"哈哈，这是蚯蚓吧！\"",
        },
        { id = "xs_bring_lunch", stage = 2, tier = "core", affinity = 4,
          title = "🍱 带午饭",
          text = "小雪端着两份蛋炒饭走进来：\"我做多了！真的只是做多了！不是特意……\"她的耳尖红了。蛋炒饭上面歪歪扭扭摆了一个笑脸。",
        },
        { id = "xs_fix_typo", stage = 2, tier = "core", affinity = 3,
          title = "✏️ 修正翻译",
          text = "小雪指着网吧门口的英文招牌：\"老板……这个单词拼错了。'Profesional'少了一个s。\"她从包里掏出修正液：\"我帮你改？\"",
        },
        { id = "xs_rain_share", stage = 2, tier = "bonus", affinity = 3,
          title = "🌧️ 共伞",
          text = "暴雨突至。你和小雪挤在网吧门口唯一的雨棚下。\"呃……我有伞。\"她撑开一把小花伞。你们两个大人挤在一把小伞下，肩膀碰着肩膀。她安静得能听到心跳。",
        },
        { id = "xs_sunset_photo", stage = 2, tier = "bonus", affinity = 3,
          title = "🌅 拍夕阳",
          text = "小雪突然拉住你的袖子：\"快看！\"天边的火烧云把整条街染成金色。她举起手机拍了张照，然后小声说：\"……第一次觉得这里也挺美的。\"",
        },

        -- ── Stage 3: 心意渐明 ──
        { id = "xs_late_night_chat", stage = 3, tier = "core", affinity = 5,
          title = "🌙 深夜聊天",
          text = "凌晨一点，网吧只剩你们两个人。小雪抱着膝盖坐在沙发上：\"你说……一个人在国外，最怕什么？\"她没等你回答：\"我最怕突然想起家里的味道，然后发现这里没有。\"",
        },
        { id = "xs_homesick", stage = 3, tier = "core", affinity = 5,
          title = "🏠 想家",
          text = "小雪今天没来网吧。你发消息问，她回了一张照片——窗外的月亮。\"今天是中秋。以前每年这时候都跟爸妈一起吃月饼的。\"你在附近超市找到了一盒进口月饼，不好吃，但她收到时哭了。",
        },
        { id = "xs_birthday_surprise", stage = 3, tier = "core", affinity = 6,
          title = "🎂 生日",
          text = "你不知道小雪今天生日——直到Kofi说漏嘴。你匆忙让Mama B烤了个蛋糕（形状不太规则）。小雪看到蛋糕愣了三秒，然后眼圈红了：\"我以为……在这里没人会记得。\"",
        },
        { id = "xs_cook_together", stage = 3, tier = "bonus", affinity = 4,
          title = "🍳 一起做饭",
          text = "小雪在网吧的小厨房教你做番茄炒蛋：\"你切的番茄太大了！要均匀！\"你故意切得更歪。她拿过刀：\"让开让开，笨手笨脚的！\"两人挤在灶台前，手肘不时碰到。",
        },
        { id = "xs_nickname", stage = 3, tier = "bonus", affinity = 3,
          title = "😝 起外号",
          text = "\"从今天起你就叫'非洲陈独秀'！\"小雪宣布。\"……为什么？\"\"因为你每天都在独自坐在网吧里秀！\"她被自己的冷笑话逗得前仰后合。你不想承认你笑了。",
        },
        { id = "xs_contract_hint", stage = 3, tier = "core", affinity = 2,
          title = "📋 合同快到期了",
          text = "小雪整理文件时自言自语：\"已经第三个月了……合同是半年的……\"她注意到你在看她，赶紧笑了笑：\"没什么！就是数日子而已～\"她的笑容没到达眼睛。",
        },

        -- ── Stage 4: 暗涌 ──
        { id = "xs_future_talk", stage = 4, tier = "core", affinity = 5,
          title = "🔮 聊未来",
          text = "\"你以后……打算一直留在这里吗？\"小雪问的时候没看你。\"这边虽然热了点，但是……\"她没说完。窗外的夕阳把她的脸映得很红，分不清是日光还是别的。",
        },
        { id = "xs_quiet_company", stage = 4, tier = "core", affinity = 5,
          title = "☕ 安静陪伴",
          text = "今天小雪什么都没说。她只是坐在你旁边看书，偶尔给你续杯咖啡。你们之间的沉默第一次不尴尬了——甚至有点舒服。临走时她说：\"有时候不说话也挺好的。\"",
        },
        { id = "xs_ticket_search", stage = 4, tier = "core", affinity = 3,
          title = "✈️ 看机票",
          text = "你路过时瞥见小雪的电脑屏幕——是机票搜索页面。她迅速切换了标签页：\"我只是……帮一个朋友查的。\"你注意到出发地是这里，目的地是国内。",
        },
        { id = "xs_avoid_topic", stage = 4, tier = "bonus", affinity = 3,
          title = "🤐 回避话题",
          text = "Kofi问小雪：\"你什么时候回中国呀？\"小雪的笑容僵了一瞬：\"嗯……还没确定呢！\"她迅速转向你：\"老板！今天晚上吃什么？\"话题被岔开了。但你注意到了。",
        },
        { id = "xs_hometown_gift", stage = 4, tier = "bonus", affinity = 4,
          title = "🎁 家乡特产",
          text = "小雪收到了国内寄来的包裹。她挑出一包茶叶递给你：\"我妈寄的龙井——她说要感谢'照顾她女儿的人'。\"她补了一句：\"我没跟她说你是男的。\"",
        },

        -- ── Stage 5: 交汇 ──
        { id = "xs_confession_setup", stage = 5, tier = "core", affinity = 6,
          title = "💫 告白铺垫",
          text = "小雪把你叫到天台：\"有件事我一直想说……\"风吹起她的头发。你等着。她深吸一口气：\"我的签证下个月到期了。\"",
        },
        { id = "xs_last_sunrise", stage = 5, tier = "core", affinity = 8,
          title = "🌄 最后的日出",
          text = "凌晨五点，小雪发消息叫你看日出。你们并肩坐在天台上看太阳从地平线升起。\"不管以后怎样……\"她靠过来一点，\"我不后悔来这里。因为遇到了你。\"",
        },
        { id = "xs_decision", stage = 5, tier = "core", affinity = 0,  -- 玩家选择，affinity由选项决定
          title = "💕 小雪的决定",
          text = "小雪站在你面前，手里攥着机票。\"签证只剩两周了。\"她抬头看你，眼圈微红：\"给我一个留下来的理由。或者……跟我说再见。\"",
          isChoice = true,
          choices = {
              { text = "❤️ \"留下来。我需要你。\"",
                effect = function()
                    addAffinity("xiaoxue", 10)
                    setFlag("xiaoxue", "stayed", true)
                    setFlag("xiaoxue", "ending_together")
                end,
                result = "小雪愣了一秒，然后笑了——是你见过的最灿烂的笑容。\"……好。我去续签。\"她把机票折成纸飞机扔下天台。\"反正那班机的飞机餐很难吃。\"\n\n💕 小雪选择留下！" },
              { text = "🤝 \"我不想耽误你。但无论多远，我都在。\"",
                effect = function()
                    addAffinity("xiaoxue", 5)
                    setFlag("xiaoxue", "long_distance", true)
                    setFlag("xiaoxue", "ending_distance")
                end,
                result = "小雪沉默了很久。然后她掏出手机：\"那你至少……加我微信。不许不回消息。\"她用力擦了一下眼睛：\"非洲到中国的WiFi……应该够用吧。\"\n\n💕 异地线开启——距离不是终点。" },
              { text = "😔 \"…………\"（说不出口）",
                effect = function()
                    addAffinity("xiaoxue", 3)
                    setFlag("xiaoxue", "ending_open")
                end,
                result = "你什么都没说。小雪等了十秒，然后轻轻笑了：\"嗯……我懂了。\"她没哭。只是把机票收好，整了整头发：\"不管怎样，这段时间——谢谢你。真的。\"\n\n💕 开放式结局——有些话不说出口，也已经足够。" },
          },
        },
        { id = "xs_farewell_letter", stage = 5, tier = "bonus", affinity = 4,
          title = "✉️ 告别信",
          text = "小雪走后（如果她选择回国），你在抽屉里发现一封手写信和一包旺旺仙贝：\"这是我来的第一天分给你的同款。下次见面——换你请我。\"",
          condition = function() return hasFlag("xiaoxue", "ending_distance") or hasFlag("xiaoxue", "ending_open") end,
        },
        { id = "xs_video_call", stage = 5, tier = "bonus", affinity = 4,
          title = "📹 视频通话",
          text = "手机震动。小雪发来视频通话。画面里她穿着厚外套，背景是雪景：\"看！下雪了！我突然想到……你在非洲是不是从来没见过雪？\"她对着镜头哈了一口白气：\"我帮你感受一下！\"",
          condition = function() return hasFlag("xiaoxue", "ending_distance") end,
        },

        -- ── 文化细节（跨Stage可触发）──
        { id = "xs_culture_chili", stage = 2, tier = "bonus", affinity = 2,
          title = "🌶️ 辣椒的误会",
          text = "小雪尝了一口当地菜，眼泪刷地流下来：\"这、这是什么辣椒！！\"你说那是scotch bonnet。她含泪倔强道：\"我是湖南人……只是流汗而已！从眼睛流的汗！\"Grace路过递了杯酸奶：\"眼睛流汗这个说法挺新鲜。\"",
        },
        { id = "xs_culture_dialect", stage = 2, tier = "bonus", affinity = 2,
          title = "🗣️ 方言教学翻车",
          text = "小雪得意地说教Kofi中文了。远处传来Kofi的声音：\"老板娘早上好——！！\"全场安静。小雪脸爆红：\"我教的是'老板'！没有'娘'！！\"Grace翻着报表淡定补刀：\"恭喜，非洲速度。\"",
        },
    },

    -- ====================================================================
    -- Grace线
    -- ====================================================================
    grace = {
        -- ── Stage 1: 冷面相逢 ──
        { id = "gr_first_report", stage = 1, tier = "core", affinity = 2,
          title = "📊 第一份报表",
          text = "Grace把一份打印好的财务报表放在你桌上：\"你上个月的电费付多了12%。这是优化方案。\"她转身就走，没有多余的话。报表做得很专业——比你见过的任何会计都好。",
        },
        { id = "gr_correct_mistake", stage = 1, tier = "core", affinity = 3,
          title = "🔍 纠正错误",
          text = "\"你的供应商在骗你。\"Grace指着发票上的一行数字。\"这个价格比市场价高了40%。我可以帮你找到更好的渠道。\"她的语气很平淡，像是在陈述天气。",
        },
        { id = "gr_cold_greeting", stage = 1, tier = "core", affinity = 2,
          title = "🧊 冷淡寒暄",
          text = "\"早。\"Grace走进来时只说了一个字，然后打开电脑开始工作。你试着闲聊，她礼貌但简短：\"嗯。\"\"是的。\"\"我先忙了。\"不是不友好——只是有清晰的边界感。",
        },
        { id = "gr_overtime", stage = 1, tier = "bonus", affinity = 2,
          title = "🌃 默默加班",
          text = "你发现Grace经常是最后一个离开的人。灯已经关了一半，她还在核对数据。你给她留了盏台灯，第二天她没说谢谢——但那盏灯被她挪到了她觉得最顺手的位置。",
        },
        { id = "gr_coffee_black", stage = 1, tier = "bonus", affinity = 2,
          title = "☕ 黑咖啡",
          text = "你给Grace带了杯加糖的咖啡。她看了一眼：\"我喝黑的。不加糖。\"第二天你改了。她接过去喝了一口，嘴角几乎不可察觉地动了一下——那大概就是Grace的谢谢。",
        },

        -- ── Stage 2: 破冰 ──
        { id = "gr_market_advice", stage = 2, tier = "core", affinity = 4,
          title = "📈 市场建议",
          text = "Grace在白板上画了张竞争对手分析图：\"Blaze Net在价格战上有优势，但我们可以打差异化——VIP训练区、专业比赛解说直播。\"她难得说了一长段话。你发现她的战略眼光比你以为的强得多。",
        },
        { id = "gr_first_smile", stage = 2, tier = "core", affinity = 5,
          title = "😊 第一次笑",
          text = "你不小心把咖啡洒在报表上。Grace看着被染成棕色的文件，表情复杂。然后——她笑了。不是大笑，只是嘴角微微翘起来，但那是你第一次看到Grace笑。\"我有备份。\"她说。",
        },
        { id = "gr_competitor_intel", stage = 2, tier = "core", affinity = 4,
          title = "🕵️ 竞争情报",
          text = "Grace递给你一个U盘：\"Blaze Net下个月的促销计划。我有渠道。\"你不问她怎么拿到的。她看着你把U盘插上电脑的样子说：\"……别告诉别人是我给的。\"",
        },
        { id = "gr_lunch_refuse", stage = 2, tier = "bonus", affinity = 2,
          title = "🍽️ 拒绝午饭",
          text = "\"一起吃午饭？\"你问。Grace看了你一秒：\"不了。我带了自己的。\"她从包里拿出保鲜盒——jollof rice，摆盘很精致。一个人吃得很认真。",
        },
        { id = "gr_small_thanks", stage = 2, tier = "bonus", affinity = 3,
          title = "🔈 小声说谢谢",
          text = "你帮Grace修好了她卡住的打印机。她站在旁边看你弄了十分钟。修好后你转身，她低声说了句什么。\"什么？\"\"……谢谢。\"声音很小。然后她快步走开了。",
        },

        -- ── Stage 3: 信任建立 ──
        { id = "gr_past_reveal", stage = 3, tier = "core", affinity = 6,
          title = "📖 过去的揭示",
          text = "加班到很晚，Grace突然说：\"我以前自己开过公司。\"你惊讶地看她。\"三年前。做进口贸易。合伙人卷钱跑了。\"她的表情很平静，像在说别人的故事。\"所以我不轻易信任人。\"她看着你：\"……但你还行。\"",
        },
        { id = "gr_jealousy_coffee", stage = 3, tier = "core", affinity = 3,
          title = "☕ 多出来的咖啡",
          text = "Grace放下两杯咖啡：\"一杯美式，一杯——\"她看到小雪已经给你递了奶茶。\"……（收回第二杯）这杯我自己喝。\"你问她买了两杯？她说：\"买一送一。别多想。\"",
          condition = function() return getStage("xiaoxue") >= 2 end,
        },
        { id = "gr_vulnerability", stage = 3, tier = "core", affinity = 6,
          title = "💧 脆弱的一面",
          text = "下班后你发现Grace还在办公室，对着电脑发呆。走近看——她在看一张旧照片，是年轻时的自己站在一家店门口。\"那是我第一家公司。\"她没收起照片。\"已经不在了。\"今晚，她没说'明天见'就走了。",
        },
        { id = "gr_jealousy_overtime", stage = 3, tier = "bonus", affinity = 3,
          title = "🌙 加班的理由",
          text = "小雪已经离开了，Grace还在。她不看屏幕，盯着报表：\"今天打烊比平时晚。\"你说想多赚一小时。\"……你以前准时得很。\"她合上笔记本：\"算了，晚安。\"",
          condition = function() return getStage("xiaoxue") >= 2 end,
        },
        { id = "gr_business_partner", stage = 3, tier = "bonus", affinity = 4,
          title = "🤝 商业搭档",
          text = "Grace提出了分店计划的初版方案。\"不是现在。但等资金到位——第一家分店的选址，我已经看好了。\"她递给你一份评估报告，比任何投资分析师都详细。你第一次觉得：这个人不只是在帮你打工。",
        },

        -- ── Stage 4: 暗涌 ──
        { id = "gr_rooftop_talk", stage = 4, tier = "core", affinity = 6,
          title = "🏙️ 天台谈话",
          text = "Grace把你叫到天台。城市的灯光在脚下铺开。\"我想了很久。\"她面对着夜景，不看你。\"这家网吧——从报表来看只是生意。但对你来说不只是，对吧？\"你说是。她终于转过来：\"对我来说也是。\"",
        },
        { id = "gr_almost_confess", stage = 4, tier = "core", affinity = 7,
          title = "💭 差点表白",
          text = "年终总结会后，只剩你和Grace。她收拾文件时停下来：\"有件事我……\"她顿了很久。你等着。\"……明年的预算，我做了三个版本。你看一下。\"她把U盘放在桌上走了。U盘标签上写着：'给老板——私人版'。",
        },
        { id = "gr_protect_business", stage = 4, tier = "core", affinity = 6,
          title = "🛡️ 保护网吧",
          text = "有竞争对手来挖Grace。开出了三倍薪水。你是从Mama B那里听说的。你没问Grace——但她第二天照常来上班了。你说：\"听说……\"她打断你：\"不用谢。我有我自己的判断。\"她看了你一眼：\"我判断这里值得。\"",
        },
        { id = "gr_jealousy_chopstick", stage = 4, tier = "bonus", affinity = 3,
          title = "🥢 筷子事件",
          text = "Grace路过，看到小雪在教你用筷子吃面。她的脚步顿了一下，然后继续走。五分钟后你收到消息：\"明天的供货清单发你邮箱了。另外，筷子夹面要用巧劲，别整根搅。\"你问她怎么知道。【已读不回】",
          condition = function() return getStage("xiaoxue") >= 3 end,
        },
        { id = "gr_subtle_care", stage = 4, tier = "bonus", affinity = 4,
          title = "💊 不动声色的关心",
          text = "你连续咳嗽了一周。Grace什么都没说。但你发现桌上多了盒润喉糖，冰箱里多了瓶蜂蜜，空调温度被调高了两度。你问她是不是——\"是Mama B放的吧。\"她说。（Mama B这周没来过。）",
        },

        -- Grace C路径（慢热线）独白事件
        { id = "gr_memo_peek", stage = 4, tier = "core", affinity = 3,
          title = "📱 Grace的备忘录",
          text = "Grace的手机屏幕亮了一下。你不经意瞥到一行字：\"周六：——\"她迅速把手机翻过去。\"看到了？\" \"什么？\" \"……是工作提醒。\"你说周六那行好像不是工作？她呼了口气：\"是你说过想去海边市场的日子。我只是顺手记了进货路线。纯粹因为顺路。别自作多情。\"她耳尖微红。",
          condition = function() return getBond("grace") and getBond("grace").route == "slow" end,
        },
        { id = "gr_self_talk", stage = 4, tier = "core", affinity = 4,
          title = "🗨️ 关门前的自言自语",
          text = "你去仓库取物资，Grace以为自己一个人。你听到她轻声说：\"你这个人真是……算了。下次问你吃什么的时候，能不能别说'随便'。我又不是真的在问你吃什么。\"你从仓库回来问她跟谁说话。\"在对账。\"你说听到了'随便'。\"你听错了。我走了。明天见。\"你追了一句：\"明天想吃什么？\"她在门口停了一秒：\"不要jollof rice就行。\"",
          condition = function() return getBond("grace") and getBond("grace").route == "slow" end,
        },

        -- ── Stage 5: 归处 ──
        { id = "gr_confession_scene", stage = 5, tier = "core", affinity = 0,
          title = "💕 Grace的告白",
          text = "分店签约仪式后，所有人都走了。Grace站在空荡荡的新店里，背对着你。\"我想问你一件事。\"她转过身。\"这家店——你打算写几个人的名字？\"",
          isChoice = true,
          choices = {
              { text = "❤️ \"两个人。你和我。\"",
                effect = function()
                    addAffinity("grace", 10)
                    setFlag("grace", "ending_partner")
                end,
                result = "Grace沉默了三秒。然后她走过来，把一支笔递到你手里：\"那就写吧。……我的名字怎么拼，不用我教你了吧。\"她的手在微微发抖。\n\n💕 Grace成为你的合伙人——人生的那种。" },
              { text = "🤝 \"我希望是我们。但你值得更好的选择。\"",
                effect = function()
                    addAffinity("grace", 5)
                    setFlag("grace", "ending_respect")
                end,
                result = "Grace笑了——是你见过她最真实的笑容。\"你什么时候变得会说话了。\"她把合同收好：\"好。我选择留在这里。至于为什么——以后再告诉你。\"\n\n💕 Grace以自己的方式留下来了。" },
              { text = "💼 \"作为商业伙伴——你是最好的。\"",
                effect = function()
                    addAffinity("grace", 3)
                    setFlag("grace", "ending_business")
                end,
                result = "Grace的表情没变。但她点了点头的速度比平时快了一拍。\"好。商业伙伴。\"她伸出手来握手。你们握手的时候，她的手很凉。\"那就……继续合作愉快。\"她先松开了手。\n\n💕 有些关系不需要名字——你们都知道。" },
          },
        },
        { id = "gr_partnership_proposal", stage = 5, tier = "core", affinity = 5,
          title = "📋 合伙提议",
          text = "Grace递给你一份文件：\"正式的合伙协议。我拟的。\"你打开——上面写着两个名字，一个是你的。利润分配、决策权限、退出机制……每一条都对你有利。你说这不公平。她说：\"商业不讲公平。讲信任。\"",
          condition = function() return hasFlag("grace", "ending_partner") end,
        },
        { id = "gr_first_name_call", stage = 5, tier = "bonus", affinity = 5,
          title = "💫 第一次叫名字",
          text = "\"Adomaa。\"你突然叫了她的本名。Grace——不，Adomaa——愣在原地。然后她的耳朵肉眼可见地红了。\"……你记得啊。\"她低下头整理了一下不存在的文件：\"嗯。你可以叫。偶尔。不是经常。\"",
          condition = function() return hasFlag("grace", "know_real_name") end,
        },
        { id = "gr_matching_coffee", stage = 5, tier = "bonus", affinity = 4,
          title = "☕ 第二杯咖啡",
          text = "Grace放下两杯咖啡。这次没有犹豫。\"一杯美式，一杯——加了两块糖。\"你说你喝不惯黑的。她嘴角微翘：\"我知道。我第一天就知道了。\"",
        },

        -- ── 文化细节 ──
        { id = "gr_culture_adinkra", stage = 3, tier = "bonus", affinity = 3,
          title = "🎨 Adinkra符号",
          text = "Grace指着一个装饰图案：\"你知道这个符号是什么意思吗？\"你猜是好看的花纹。\"这是Adinkra符号，叫'Odo Nnyew Fie Kwan'——爱不会迷路回家。\"她说奶奶围裙上绣着这个。\"不过原意确实是爱情的。\"她小声补了一句。",
          onTrigger = function() setFlag("grace", "adinkra_symbol") end,
        },
        { id = "gr_culture_name", stage = 2, tier = "bonus", affinity = 2,
          title = "📛 名字的意义",
          text = "你问Grace是不是本名。\"英文名。本名是Adomaa。\"\"什么意思？\"\"Akan语里是'恩典'。和Grace是一个意思。\"你问为什么用英文名。\"做生意方便。\"她停了一下：\"……如果有一天你想叫我Adomaa——算了，Grace就好。\"",
          onTrigger = function() setFlag("grace", "know_real_name") end,
        },
    },

    -- ====================================================================
    -- 双线交叉事件
    -- ====================================================================
    crossover = {
        { id = "cross_lunch", tier = "core", affinity_xs = 2, affinity_gr = 2,
          title = "🍱 三人午饭",
          minDay = 16,
          condition = function() return getStage("xiaoxue") >= 2 and getStage("grace") >= 2 end,
          text = "小雪端着便当走过来：\"老板～今天多做了一份蛋炒饭～\"Grace已经坐在对面：\"…你每天都多做一份？\"小雪笑着说三个人分着吃。Grace带了jollof rice。两人交换食物，气氛意外和谐。Grace小声：\"你的蛋炒饭确实不错。\"小雪：\"下次我教你放老干妈！\"",
        },
        { id = "cross_lockup", tier = "bonus", affinity_xs = 1, affinity_gr = 2,
          title = "🔑 谁来锁门",
          minDay = 20,
          condition = function() return getStage("xiaoxue") >= 2 and getStage("grace") >= 2 end,
          text = "打烊铃响。Grace正要走——看到小雪还在擦桌子。小雪惊讶：\"Grace姐还没走？\"Grace看向你：\"你锁门，我送她到路口。\"小雪说Grace姐人真好。Grace：\"只是顺路。\"转身时嘴角微翘。",
          onTrigger = function() setFlag("grace", "crossover_walkHome") end,
        },
        { id = "cross_anniversary", tier = "core", affinity_xs = 2, affinity_gr = 2,
          title = "🎉 网吧周年策划",
          minDay = 25,
          condition = function() return getStage("xiaoxue") >= 3 and getStage("grace") >= 3 end,
          text = "Grace：\"下个月是网吧开业纪念——\"小雪举手：\"我可以做海报！搞个中非文化交流日！\"Grace思考：\"配合折扣活动……传播效果不错。可以。\"小雪：\"Grace姐负责商业策划，我负责活动内容？\"Grace点头：\"——老板，你负责出钱。\"你：\"……为什么最累的是我？\"",
        },
        { id = "cross_food_fest", tier = "bonus", affinity_xs = 2, affinity_gr = 2,
          title = "🍲 中非美食节",
          minDay = 28,
          condition = function() return getStage("xiaoxue") >= 3 and getStage("grace") >= 3 end,
          text = "网吧门口临时小吃摊。小雪的麻辣香锅让当地人喊着要加辣。Grace的kelewele被你说像糖醋排骨：\"别侮辱我的kelewele。\"两边都在投喂你。你说今天很幸福。她们同时瞪过来：\"少贫。\"",
        },
    },
}

-- ============================================================================
-- 微事件触发逻辑（每日EndDay时调用）
-- ============================================================================
function M.OnEndDay()
    if not playerData_ or not playerData_.bonds then return end
    local day = playerData_.day or 1
    local triggeredToday = {}

    -- 1. 检查阶段晋升
    M.CheckPromotion("xiaoxue")
    M.CheckPromotion("grace")

    -- 2. 交叉事件（优先触发，每天最多1个）
    local crossTriggered = false
    if getStage("xiaoxue") >= 2 and getStage("grace") >= 2 then
        local crossEvents = M.MICRO_EVENTS.crossover
        local candidates = {}
        for _, evt in ipairs(crossEvents) do
            if not isTriggered("crossover", evt.id) then
                local minDay = evt.minDay or 0
                if day >= minDay then
                    local condOk = true
                    if evt.condition then
                        local ok, val = pcall(evt.condition)
                        condOk = ok and (val and true or false)
                    end
                    if condOk then
                        table.insert(candidates, evt)
                    end
                end
            end
        end
        if #candidates > 0 then
            -- 按tier排序：core优先
            table.sort(candidates, function(a, b)
                if a.tier == "core" and b.tier ~= "core" then return true end
                if a.tier ~= "core" and b.tier == "core" then return false end
                return false
            end)
            local evt = candidates[1]
            local chance = (evt.tier == "core") and M.MICRO_CHANCE_CORE or M.MICRO_CHANCE_BONUS
            if math.random() < chance then
                markTriggered("crossover", evt.id)
                addAffinity("xiaoxue", evt.affinity_xs or 0)
                addAffinity("grace", evt.affinity_gr or 0)
                if evt.onTrigger then pcall(evt.onTrigger) end
                AddLog("💞 " .. (evt.title or "双线事件") .. "\n" .. (evt.text or ""))
                crossTriggered = true
                table.insert(triggeredToday, evt.id)
            end
        end
    end

    -- 3. 角色专属微事件（每人每天最多1个，有冷却）
    for _, charId in ipairs({"xiaoxue", "grace"}) do
        local bond = getBond(charId)
        if bond and bond.stage >= 1 then
            -- 冷却检查
            if day - bond.lastInteractDay < M.COOLDOWN_DAYS then
                goto continue_char
            end

            local pool = M.MICRO_EVENTS[charId]
            if not pool then goto continue_char end

            -- 筛选候选事件
            local candidates = {}
            for _, evt in ipairs(pool) do
                if evt.stage == bond.stage and not isTriggered(charId, evt.id) then
                    local condOk = true
                    if evt.condition then
                        local ok, val = pcall(evt.condition)
                        condOk = ok and (val and true or false)
                    end
                    if condOk then
                        table.insert(candidates, evt)
                    end
                end
            end

            if #candidates == 0 then goto continue_char end

            -- core 优先排序
            table.sort(candidates, function(a, b)
                if a.tier == "core" and b.tier ~= "core" then return true end
                if a.tier ~= "core" and b.tier == "core" then return false end
                return false
            end)

            local evt = candidates[1]
            local chance = (evt.tier == "core") and M.MICRO_CHANCE_CORE or M.MICRO_CHANCE_BONUS
            if math.random() < chance then
                markTriggered(charId, evt.id)
                bond.lastInteractDay = day

                -- 处理选择型事件
                if evt.isChoice then
                    -- 将事件推入事件阶段
                    currentEvent_ = {
                        id = evt.id,
                        title = evt.title,
                        desc = evt.text,
                        type = "choice",
                        category = "romance",
                        choices = {},
                    }
                    for _, c in ipairs(evt.choices) do
                        table.insert(currentEvent_.choices, {
                            text = c.text,
                            effect = c.effect,
                            result = function() return c.result end,
                        })
                    end
                    currentPhase_ = PHASE_EVENT
                    PlayBGM("event")
                    BuildUI()
                    return  -- 选择事件阻塞后续流程
                end

                -- 普通展示
                addAffinity(charId, evt.affinity or 0)
                if evt.onTrigger then pcall(evt.onTrigger) end
                local icon = charId == "xiaoxue" and "🌸" or "🌹"
                AddLog(icon .. " " .. (evt.title or "感情事件") .. "\n" .. (evt.text or ""))
                table.insert(triggeredToday, evt.id)
            end

            ::continue_char::
        end
    end

    return triggeredToday
end

-- ============================================================================
-- 小雪入场事件（StoryEvent格式，Day≥8自动触发）
-- ============================================================================
M.XIAOXUE_ARRIVAL_EVENT = {
    id = "xiaoxue_arrival",
    cond = function()
        return playerData_.day >= 8
            and playerData_.bonds
            and playerData_.bonds.xiaoxue.stage == 0
    end,
    type = "dialogue",
    title = "🌸 不速之客",
    dialogues = {
        { speaker = "旁白", text = "午后，一个拖着行李箱的中国女生推门走进网吧。她满头大汗，脸上写满了疲惫和迷茫。" },
        { speaker = "小雪", text = "请问……这里有WiFi吗？我手机没信号了，地图打不开，已经走了好久……" },
        { speaker = "你", text = "当然有。先坐下喝杯水？" },
        { speaker = "小雪", text = "谢谢……我叫林小雪，刚到这边做志愿者项目。住的地方还没找到……呜……" },
        { speaker = "你", text = "（看到她行李箱上的中文贴纸——「加油小雪！」——和一只看起来快要散架的充电宝）" },
        { speaker = "旁白", text = "这是你在非洲遇到的第一个中国同龄人。她看起来比你刚来时更手足无措。" },
        { speaker = "小雪", text = "（连上WiFi后长舒一口气）终于……啊，老板你也是中国人？！太好了太好了！我以为我是整条街唯一的中国人！" },
        { speaker = "旁白", text = "你给她指了附近的旅馆，又多灌了一瓶水。她走的时候转身说——" },
        { speaker = "小雪", text = "我明天能来蹭WiFi吗？我会买东西的！真的！" },
        { speaker = "旁白", text = "【小雪加入了你的日常。感情线开启。】" },
    },
    effect = function()
        if playerData_.bonds then
            playerData_.bonds.xiaoxue.stage = 1
        end
    end,
}

-- ============================================================================
-- Grace感情线激活（在现有Grace Stage1商业事件触发后激活）
-- ============================================================================
function M.ActivateGraceBond()
    if not playerData_ or not playerData_.bonds then return end
    if playerData_.bonds.grace.stage == 0 then
        playerData_.bonds.grace.stage = 1
        AddLog("🌹 【感情线】Grace——这个冷面女人似乎不只是来打工的。")
    end
end

-- ============================================================================
-- DailyGreeting 扩展：感情线专用问候（按stage变化称呼/语气）
-- ============================================================================
M.ROMANCE_GREETINGS = {
    xiaoxue = {
        [1] = {  -- 客气阶段
            "老板早！今天WiFi快不快呀？",
            "早安老板～我给你留了零食在桌上！",
            "老板！这边的早晨好热啊……",
        },
        [2] = {  -- 自然阶段（开始用名字）
            "早！今天我多做了份饭，等下记得吃～",
            "嘿～昨天那个综艺你看了吗？笑死我了！",
            "今天的日出特别好看！我拍了照片给你看～",
        },
        [3] = {  -- 关心阶段
            "你今天脸色不太好……昨晚又加班了？",
            "我泡了茶，在你桌上。别凉了才喝。",
            "今天下雨，你有带伞吗？没有的话用我的。",
        },
        [4] = {  -- 害羞阶段
            "……你来了。（低头整理已经很整齐的桌面）",
            "今天……有件事想跟你说。等下再说吧。",
            "你今天穿这件衣服……嗯，没什么，挺好的。",
        },
        [5] = {  -- 默契阶段
            "（看到你，笑了一下，什么都没说。但一切都在那个笑里了。）",
            "我在这。你也在。就够了。",
            "今天也请多关照——不是客气话。",
        },
    },
    grace = {
        [1] = {  -- 纯商务
            "早。今天的任务清单在你桌上。",
            "报表做好了。有问题找我。",
            "准时了。不错。",
        },
        [2] = {  -- 略微柔和
            "早。咖啡我泡了一壶。公用的。",
            "今天天气不错——适合做事。",
            "……你换了洗发水？算了，没什么。开会吧。",
        },
        [3] = {  -- 信任流露
            "我先到了。给你留了位子——靠窗那个。",
            "早。昨天的方案我又改了一版。更好了。",
            "你昨天走的时候忘关空调了。……我帮你关了。",
        },
        [4] = {  -- 欲言又止
            "……早。（盯着你看了一秒）没什么。开工。",
            "你来了。（收起手机，屏幕上好像是你的名字）",
            "今天的日程比较空。如果你有空……算了，工作优先。",
        },
        [5] = {  -- 坦然
            "早安。今天也一起努力。",
            "我在这里。一直都在。",
            "（递给你咖啡，两杯。不用说什么。）",
        },
    },
}

--- 获取感情线角色当日问候（返回nil表示不适用）
function M.GetRomanceGreeting(charId)
    local bond = getBond(charId)
    if not bond or bond.stage < 1 then return nil end
    local stagePool = M.ROMANCE_GREETINGS[charId] and M.ROMANCE_GREETINGS[charId][bond.stage]
    if not stagePool or #stagePool == 0 then return nil end
    return stagePool[math.random(1, #stagePool)]
end

-- ============================================================================
-- 公开接口
-- ============================================================================
function M.GetBond(charId)
    return getBond(charId)
end

function M.GetStage(charId)
    return getStage(charId)
end

function M.AddAffinity(charId, amount)
    addAffinity(charId, amount)
end

function M.HasFlag(charId, flag)
    return hasFlag(charId, flag)
end

function M.SetFlag(charId, flag, value)
    setFlag(charId, flag, value)
end

return M
