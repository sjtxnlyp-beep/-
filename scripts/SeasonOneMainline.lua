---@diagnostic disable: undefined-global
-- ============================================================================
-- SeasonOneMainline.lua — 第一季主线 (D15-D30)
-- 职责: 16天强主线事件 + 路线计算 + 结局生成 + D31加成
-- ============================================================================

local SeasonOneMainline = {}

-- ============================================================================
-- 1. 第一季状态初始化
-- ============================================================================

function SeasonOneMainline.EnsureState()
    if not playerData_ then return end
    playerData_.seasonOne = playerData_.seasonOne or {
        events = {},           -- 已触发事件记录 {[day]=choiceIdx}
        aelStage = "registered",  -- registered/qualifier/main/semifinal/final
        aelPoints = 0,         -- AEL 积分
        kofiPressure = 0,      -- Kofi 压力 (0-10)
        kofiExposure = 0,      -- Kofi 曝光度
        streetSupport = 0,     -- 街区支持
        victorPressure = 0,    -- Victor 施压度
        grayRisk = 0,          -- 灰色风险
        auditRisk = 0,         -- AEL 审查风险
        facilityPower = 0,     -- 设施评分(缓存)
        finalResult = nil,     -- 决赛结果
        route = nil,           -- 路线倾向
        endingId = nil,        -- 最终结局ID
    }
end

-- ============================================================================
-- 2. D15-D30 主线事件表
-- ============================================================================

local MAINLINE_EVENTS = {
    -- ═══ D15: AEL 报名确认 ═══
    [15] = {
        id = "s1_d15_ael_register", category = "ael",
        title = "📋 AEL报名确认",
        desc = "AEL 非洲电竞联盟的报名邮件终于到了。三个选项摆在面前：低调报名、高调宣战、或者找个灰色赞助商垫资。Kofi 在旁边紧张地搓着手：\"老板，我们真的要打正式比赛了？\"",
        type = "choice",
        choices = {
            { text = "📝 低调报名，稳扎稳打", hint = "AEL+2 · 低风险",
              ethics = { resultVsProcess = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
                  s.aelStage = "qualifier"
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你默默填完了报名表。没有宣传，没有噱头。Kofi 松了口气：\"这样好，我们先证明自己。\"" },
            { text = "📢 高调宣战，造势引流", hint = "声望+15 · Victor注意+2",
              ethics = { resultVsProcess = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
                  s.aelStage = "qualifier"
                  s.victorPressure = s.victorPressure + 2
                  s.kofiExposure = s.kofiExposure + 2
                  playerData_.reputation = playerData_.reputation + 15
              end,
              result = "你在社交媒体上发了宣战帖：\"Dragon Force 来了。\" 一天之内转发破千。Victor 的账号沉默了——但你知道他看到了。" },
            { text = "💼 找灰色赞助垫报名费", hint = "现金+200 · 灰色风险+2",
              ethics = { legalVsGray = -2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
                  s.aelStage = "qualifier"
                  s.grayRisk = s.grayRisk + 2
                  playerData_.money = playerData_.money + 200
              end,
              result = "一个自称\"体育经纪人\"的男人递来现金。\"放心，我只要你们球衣上一个小logo。\" 钱是到了，但这logo来路不明。" },
        },
    },

    -- ═══ D16: 赛前训练崩盘 ═══
    [16] = {
        id = "s1_d16_training_crash", category = "team",
        title = "💥 训练崩了",
        desc = "距离预选赛还有一天，Kofi 在训练中连续失误。他摔了鼠标站起来：\"网老是卡！这破网怎么打比赛！\" 队友们面面相觑。你需要快速处理这个局面。",
        type = "choice",
        choices = {
            { text = "🫂 安抚Kofi，今天收工休息", hint = "Kofi压力-2 · 训练量不足",
              ethics = { moneyVsPeople = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.kofiPressure = math.max(0, s.kofiPressure - 2)
                  s.streetSupport = s.streetSupport + 1
              end,
              result = "你拍拍 Kofi 的肩膀：\"明天才是正式的。今天回去早点睡。\" 他点点头。有时候，休息比训练更重要。" },
            { text = "🔥 加训两小时，必须磨合", hint = "AEL+1 · Kofi压力+1",
              ethics = { resultVsProcess = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
                  s.kofiPressure = s.kofiPressure + 1
              end,
              result = "你严肃地说：\"再来两小时。输了你们会后悔的。\" Kofi 沉默地重新坐下。训练是完成了，但他的眼神有些疲惫。" },
            { text = "🖥️ 紧急升级网络设备", hint = "现金-150 · 设施评分+",
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.money = playerData_.money - 150
                  playerData_.netSpeed = math.min(5, (playerData_.netSpeed or 1) + 1)
                  s.kofiPressure = math.max(0, s.kofiPressure - 1)
              end,
              result = "你掏出私房钱叫来网络公司加急升级。一小时后，延迟从80ms降到30ms。Kofi 试了一把：\"……老板，这才对嘛！\"" },
        },
    },

    -- ═══ D17: 预选赛第一轮 ═══
    [17] = {
        id = "s1_d17_qualifier_r1", category = "match",
        title = "⚔️ 预选赛首战",
        desc = "预选赛第一轮对手是 Kumasi Knights——本地老牌战队。比赛前 Kofi 深呼吸：\"第一场正式比赛……老板，用什么战术？\" 对面的队长正在做热身操，一脸轻松。",
        type = "choice",
        choices = {
            { text = "🛡️ 保守防守，稳住别浪", hint = "稳定·低风险·AEL+2",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
                  s.aelStage = "qualifier"
              end,
              result = "你让队伍前期猥琐发育。对面急躁先开团被抓到破绽——Dragon Force 2:1 险胜！虽然不漂亮，但赢了就是赢了。" },
            { text = "🐉 围绕Kofi打，秀翻全场", hint = "Kofi曝光+2 · 高风险高回报",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 3
                  s.kofiExposure = s.kofiExposure + 2
                  s.kofiPressure = s.kofiPressure + 1
              end,
              result = "Kofi 单杀对面双C，全场沸腾！弹幕刷屏：\"这谁？？？太猛了！\" 2:0 完胜。但赛后 Kofi 的ID开始被人记住了……" },
            { text = "🎲 奇招战术，打乱节奏", hint = "不稳定·赢了出名",
              effect = function()
                  local s = playerData_.seasonOne
                  local roll = math.random(1, 10)
                  if roll >= 4 then
                      s.aelPoints = s.aelPoints + 3
                      playerData_.reputation = playerData_.reputation + 10
                  else
                      s.aelPoints = s.aelPoints + 1
                  end
              end,
              result = "你让队伍用了从没练过的阵容。解说都懵了。对面更懵——混乱中 Dragon Force 拿下了胜利！（也许是运气。）" },
        },
    },

    -- ═══ D18: 赛后舆论 ═══
    [18] = {
        id = "s1_d18_post_match", category = "media",
        title = "📱 赛后的风暴",
        desc = "一觉醒来，手机炸了。Dragon Force 昨天的比赛上了本地电竞论坛热搜。有人夸\"草根奇迹\"，有人质疑\"一场能说明什么\"。还有记者要采访。",
        type = "choice",
        choices = {
            { text = "🎤 接受采访，讲草根故事", hint = "声望+20 · Kofi曝光+1",
              ethics = { integrationVsExtraction = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.reputation = playerData_.reputation + 20
                  s.kofiExposure = s.kofiExposure + 1
                  s.streetSupport = s.streetSupport + 2
              end,
              result = "记者写道：\"从铁皮屋到电竞赛场，Dragon Force 的故事比任何剧本都精彩。\" 街坊们开始以你的网吧为荣。" },
            { text = "🤫 低调训练，闭门不见", hint = "AEL+1 · 无曝光风险",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
              end,
              result = "你关掉手机，拉上门帘：\"来，继续练。下一场更难。\" 外面的热度慢慢散了，但队伍的默契又进了一步。" },
            { text = "💰 借热度做营销，招新客", hint = "现金+100 · 商业化",
              ethics = { integrationVsExtraction = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.money = playerData_.money + 100
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你火速做了张海报贴门口：\"AEL 参赛战队主场——来 Dragon Net 体验冠军同款网速！\" 新客人果然多了不少。" },
        },
    },

    -- ═══ D19: 赞助名片 ═══
    [19] = {
        id = "s1_d19_sponsorship", category = "business",
        title = "💼 谁来赞助？",
        desc = "柜台上出现了三张名片。一张是 AEL 官方赞助联系人，一张是本地加纳商会的 Nana 先生，还有一张……没有名字，只有一个电话号码和一行字：\"想赢就打这个。\"",
        type = "choice",
        choices = {
            { text = "🏛️ 联系AEL正规赞助", hint = "审查风险-1 · 流程慢",
              ethics = { legalVsGray = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.auditRisk = math.max(0, s.auditRisk - 1)
                  playerData_.money = playerData_.money + 80
              end,
              result = "AEL 的人很官方：\"填表格、提交资质、等审批。\" 繁琐，但拿到了 $80 的小额赞助和一个\"合规参赛\"的戳。" },
            { text = "🤝 本地商会 Nana 先生", hint = "街区+2 · 社区路线",
              ethics = { integrationVsExtraction = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.streetSupport = s.streetSupport + 2
                  playerData_.money = playerData_.money + 120
              end,
              result = "Nana 先生笑呵呵地说：\"不要logo，队服上印'加纳商会青年项目'就行。\" 他还介绍了几个本地老板来你这里包场。" },
            { text = "📞 拨那个神秘号码", hint = "现金+300 · 灰色风险+3",
              ethics = { legalVsGray = -3 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.grayRisk = s.grayRisk + 3
                  playerData_.money = playerData_.money + 300
              end,
              result = "电话那头只说了一句：\"门口有个包裹。\" 打开一看——$300 现金和一套定制队服。好看，但你总觉得哪里不对。" },
        },
    },

    -- ═══ D20: AEL 审查通知 ═══
    [20] = {
        id = "s1_d20_ael_audit", category = "ael",
        title = "⚠️ AEL审查通知",
        desc = "一封正式邮件：\"AEL 合规部将于近日审查贵战队参赛资格，包括场地、赞助来源和选手注册。\" 如果有灰色赞助或手续不全，可能被取消资格。",
        type = "choice",
        choices = {
            { text = "📄 老实补齐所有手续", hint = "现金-100 · 审查风险-2",
              ethics = { legalVsGray = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.auditRisk = math.max(0, s.auditRisk - 2)
                  playerData_.money = playerData_.money - 100
              end,
              result = "你花了一天跑手续：营业执照复印件、选手身份证明、场地租赁合同。审查员点头：\"材料齐全，没问题。\"" },
            { text = "🔌 展示备用供电方案", hint = "需要发电机 · 审查风险-1",
              effect = function()
                  local s = playerData_.seasonOne
                  if (playerData_.generatorLevel or 0) >= 1 then
                      s.auditRisk = math.max(0, s.auditRisk - 1)
                      s.facilityPower = s.facilityPower + 5
                  end
              end,
              result = function()
                  if (playerData_.generatorLevel or 0) >= 1 then
                      return "审查员看到你的发电机，在表格上打了个勾：\"停电保障——合格。\" 这是加分项。"
                  else
                      return "你说有备用供电……但翻遍网吧也找不到发电机。审查员摇摇头在表格上画了个问号。"
                  end
              end },
            { text = "🤫 托关系抹掉问题记录", hint = "快捷 · 灰色风险+2",
              ethics = { legalVsGray = -2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.auditRisk = math.max(0, s.auditRisk - 1)
                  s.grayRisk = s.grayRisk + 2
              end,
              result = "你找了个\"认识人\"的中间人。审查表上的问题项消失了。但你知道——这种事早晚要还的。" },
        },
    },

    -- ═══ D21: 第三周复盘 ═══
    [21] = {
        id = "s1_d21_week3_review", category = "strategy",
        title = "📊 三周复盘",
        desc = "三周过去了。你坐在打烊后的网吧里，看着墙上的记录。队伍在成长，但方向越来越模糊。接下来的关键一周，你要把精力放在哪里？",
        type = "choice",
        choices = {
            { text = "🏘️ 社区优先，深耕本地", hint = "街区+3 · 社区路线",
              ethics = { integrationVsExtraction = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.streetSupport = s.streetSupport + 3
                  s.route = "community"
              end,
              result = "你决定把重心放在街坊关系上。网吧不只是赚钱的地方，更是社区的一部分。这条路慢，但走得稳。" },
            { text = "💼 商业优先，扩张变现", hint = "现金+150 · 商业路线",
              ethics = { integrationVsExtraction = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.money = playerData_.money + 150
                  s.route = "business"
              end,
              result = "你列了个扩张计划：加机位、涨价、搞会员制。钱确实来得更快了。但 Kofi 说：\"老板，来蹭网的那些小孩怎么办？\"" },
            { text = "🐉 战队优先，冲击冠军", hint = "AEL+2 · Kofi压力+1",
              ethics = { resultVsProcess = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
                  s.kofiPressure = s.kofiPressure + 1
                  s.route = "esports"
              end,
              result = "你在训练室贴了张纸：\"目标：AEL 冠军。\" 所有人都看到了。压力大了，但方向清楚了。" },
        },
    },

    -- ═══ D22: AEL 正赛首轮 ═══
    [22] = {
        id = "s1_d22_main_round1", category = "match",
        title = "🏟️ 正赛首轮",
        desc = "晋级正赛了！对手是 Cape Coast Titans，实力比预选赛的对手强了不止一个档次。线上直播观众破了千。Kofi 紧了紧耳机带：\"这次来真的了。\"",
        type = "choice",
        choices = {
            { text = "⚖️ 均衡阵容，稳定发挥", hint = "AEL+2 · 可靠",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
              end,
              result = "均衡打法让对面找不到突破口。三局苦战，Dragon Force 2:1 惊险晋级！解说喊：\"草根战队的韧性！\"" },
            { text = "🌟 押注Kofi，核心Carry", hint = "Kofi曝光+2 · 高上限",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 3
                  s.kofiExposure = s.kofiExposure + 2
                  s.kofiPressure = s.kofiPressure + 1
              end,
              result = "所有资源给 Kofi。他没辜负期望——四杀翻盘！全场高呼他的名字。但赛后他说：\"压力好大。\"" },
            { text = "🔄 轮换新人，练兵为主", hint = "AEL+1 · 队伍成长",
              ethics = { resultVsProcess = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
                  s.kofiPressure = math.max(0, s.kofiPressure - 1)
              end,
              result = "你让替补上了两局。赢得艰难，差点翻车。但新人有了大赛经验，Kofi 也稍微喘了口气。" },
        },
    },

    -- ═══ D23: Victor 冠名决赛 ═══
    [23] = {
        id = "s1_d23_victor_sponsor", category = "rivalry",
        title = "😈 Victor的阴影",
        desc = "Victor 在社交媒体宣布：Gold Net 冠名赞助 AEL 区域决赛。他还配文：\"期待各位小队伍来我的舞台上表演。\" 评论区一堆人@你。",
        type = "choice",
        choices = {
            { text = "🤝 正面回应：感谢赞助", hint = "Victor压力-1 · 大气",
              ethics = { moneyVsPeople = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.victorPressure = math.max(0, s.victorPressure - 1)
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你发了条回复：\"感谢 Victor 为本地电竞投资。决赛见。\" 评论区说你\"格局大\"。Victor 倒是没再说什么。" },
            { text = "🔥 硬刚：他的钱买不了冠军", hint = "声望+10 · Victor压力+2",
              effect = function()
                  local s = playerData_.seasonOne
                  s.victorPressure = s.victorPressure + 2
                  playerData_.reputation = playerData_.reputation + 10
              end,
              result = "你的回击帖子比他的还火：\"冠名权买不了冠军。场上见。\" 粉丝沸腾了。但 Victor 的反应……你开始担心了。" },
            { text = "🕵️ 暗中收集他的商业弱点", hint = "需安保Lv2 · 灰色",
              ethics = { legalVsGray = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  if (playerData_.securityLevel or 0) >= 2 then
                      s.victorPressure = math.max(0, s.victorPressure - 2)
                      s.grayRisk = s.grayRisk + 1
                  else
                      s.grayRisk = s.grayRisk + 1
                  end
              end,
              result = function()
                  if (playerData_.securityLevel or 0) >= 2 then
                      return "监控录像拍到了有趣的东西——Victor 的人半夜在你网吧附近转悠。这是证据。留着，也许决赛前用得上。"
                  else
                      return "你想调查 Victor，但没有监控设备，什么也查不到。只是白白冒了风险。"
                  end
              end },
        },
    },

    -- ═══ D24: 队员动摇 ═══
    [24] = {
        id = "s1_d24_poach_attempt", category = "team",
        title = "💰 Victor挖人",
        desc = "训练时，队里的辅助选手 Thunder 没来。打电话才知道——Victor 开出三倍工资挖他。\"老板，我也为难……他开的条件太好了。\"",
        type = "choice",
        choices = {
            { text = "💵 涨薪留人，钱能解决", hint = "现金-200 · 队伍稳定",
              ethics = { moneyVsPeople = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.money = playerData_.money - 200
              end,
              result = "你咬牙给 Thunder 加了薪。他回来了，但你知道——金钱买来的忠诚有保质期。" },
            { text = "💬 谈梦想，我们的故事", hint = "人情路线 · 有风险",
              ethics = { moneyVsPeople = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  local kofiTrust = playerData_.kofiTrust or 0
                  if kofiTrust >= 5 or s.streetSupport >= 5 then
                      s.streetSupport = s.streetSupport + 1
                  end
              end,
              result = "你找 Thunder 聊了一夜。从第一天组队说到现在，从破铁皮屋说到 AEL。第二天他发消息：\"老板，我留下。\" " },
            { text = "✋ 放他自由，不强留", hint = "缺人但无怨 · 道德",
              ethics = { moneyVsPeople = 1, resultVsProcess = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.kofiPressure = s.kofiPressure + 1
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你说：\"你去吧，Victor 那边条件确实好。\" Thunder 愣了很久。他走了——但走之前留了句：\"决赛我不会对你们下死手的。\"" },
        },
    },

    -- ═══ D25: Gold Net 对决 ═══
    [25] = {
        id = "s1_d25_vs_goldnet", category = "match",
        title = "🐉 Dragon vs Gold",
        desc = "半决赛，Dragon Force 对阵 Gold Net Warriors——Victor 的战队。全场爆满，连走廊都站满了人。Victor 坐在对面VIP席上笑着朝你举了举杯。",
        type = "choice",
        choices = {
            { text = "⚔️ 正面对抗，实力说话", hint = "AEL+3 · 看设施和训练",
              effect = function()
                  local s = playerData_.seasonOne
                  local facility = SeasonOneMainline.CalcFacilityPower()
                  local bonus = math.floor(facility / 20)
                  s.aelPoints = s.aelPoints + 2 + bonus
                  if s.aelPoints >= 12 then
                      s.aelPoints = s.aelPoints + 1
                  end
              end,
              result = "纯实力对决。你的网吧设施、日常训练、队伍磨合——所有积累在这一刻兑现。Dragon Force 全力以赴！" },
            { text = "🐴 田忌赛马，扬长避短", hint = "AEL+2 · 智取",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 2
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你安排 Kofi 打对面弱点位置，用阵容克制。解说说：\"Dragon Force 教练组这Ban/Pick太聪明了！\" 2:1，智取！" },
            { text = "🌑 利用掌握的把柄施压", hint = "需证据 · 灰色风险+2",
              ethics = { legalVsGray = -2 },
              effect = function()
                  local s = playerData_.seasonOne
                  if s.victorPressure <= -2 or (playerData_.securityLevel or 0) >= 2 then
                      s.aelPoints = s.aelPoints + 3
                      s.victorPressure = math.max(0, s.victorPressure - 3)
                  else
                      s.aelPoints = s.aelPoints + 1
                  end
                  s.grayRisk = s.grayRisk + 2
              end,
              result = "赛前你让人\"不小心\"泄露了 Victor 队的违规训练记录。他的队员上场时明显心不在焉。这一招……代价以后再说。" },
        },
    },

    -- ═══ D26: 媒体采访 ═══
    [26] = {
        id = "s1_d26_interview", category = "media",
        title = "🎤 决赛前采访",
        desc = "本地电视台来做赛前专题。记者问：\"如果用一句话形容 Dragon Force，你会说什么？\" 镜头对准你。这句话会上新闻，会被所有人看到。",
        type = "choice",
        choices = {
            { text = "🏘️ \"我们是街区的孩子\"", hint = "街区+3 · 社区结局倾向",
              ethics = { integrationVsExtraction = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.streetSupport = s.streetSupport + 3
                  playerData_.reputation = playerData_.reputation + 10
              end,
              result = "这句话在街区传开了。第二天开门时，门口放着邻居们凑钱买的加油横幅。你差点哭了。" },
            { text = "💼 \"我们是非洲电竞的未来\"", hint = "声望+15 · 商业路线",
              ethics = { integrationVsExtraction = -1 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.reputation = playerData_.reputation + 15
                  playerData_.money = playerData_.money + 50
              end,
              result = "新闻标题就用了你的话。LinkedIn 上有投资人开始关注你了。商业版图正在展开。" },
            { text = "🔥 \"Victor，接招吧\"", hint = "Victor压力+2 · 话题性",
              effect = function()
                  local s = playerData_.seasonOne
                  s.victorPressure = s.victorPressure + 2
                  playerData_.reputation = playerData_.reputation + 10
              end,
              result = "记者差点把话筒掉了。这条视频当晚就上了热搜。全城都在讨论——决赛，成了一场不能输的对决。" },
        },
    },

    -- ═══ D27: 灰色捷径 ═══
    [27] = {
        id = "s1_d27_gray_offer", category = "moral",
        title = "🌑 黑暗邀约",
        desc = "一个陌生人找上门，自称是\"地下博彩\"的人。\"决赛押你们输，我给你们 $500。还是说……你想让对面的核心选手'状态不好'？\" 他笑着递来名片。",
        type = "choice",
        choices = {
            { text = "🚫 拒绝，把他赶出去", hint = "灰色风险-1 · 正面路线",
              ethics = { legalVsGray = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.grayRisk = math.max(0, s.grayRisk - 1)
                  s.streetSupport = s.streetSupport + 1
              end,
              result = "你把他推出门：\"滚。Dragon Force 不做这种事。\" 他走后你发现手在抖——$500 不少了。但你知道自己做了对的选择。" },
            { text = "💰 拿钱但不配合假赛", hint = "现金+500 · 灰色风险+2",
              ethics = { legalVsGray = -2 },
              effect = function()
                  local s = playerData_.seasonOne
                  playerData_.money = playerData_.money + 500
                  s.grayRisk = s.grayRisk + 2
              end,
              result = "你收了钱但打算照打。\"聪明人。\" 他笑着离开。你知道这不是最后一次见到他。" },
            { text = "🕳️ 深度合作，让对面出问题", hint = "Victor倒 · 灰色风险+4",
              ethics = { legalVsGray = -4 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.grayRisk = s.grayRisk + 4
                  s.victorPressure = math.max(0, s.victorPressure - 5)
                  playerData_.money = playerData_.money + 300
              end,
              result = "你答应了。决赛前夜，Victor 的核心选手\"食物中毒\"住了院。你赢了——但这个秘密会永远跟着你。" },
        },
    },

    -- ═══ D28: 决赛前夜 ═══
    [28] = {
        id = "s1_d28_eve_of_final", category = "team",
        title = "🌙 决赛前夜",
        desc = "明天就是决赛了。网吧里安静得能听见风扇的声音。Kofi 还在练习，其他人早回去了。你走到他身边坐下。",
        type = "choice",
        choices = {
            { text = "😴 让所有人回去休息", hint = "Kofi压力-2 · 体力恢复",
              ethics = { moneyVsPeople = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.kofiPressure = math.max(0, s.kofiPressure - 2)
              end,
              result = "你把 Kofi 赶回家：\"明天你是主力，给我睡够八小时。\" 他笑着走了。夜里你一个人坐在网吧，看着月光——明天，就是答案了。" },
            { text = "🔥 最后一练，查漏补缺", hint = "AEL+1 · Kofi压力+1",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
                  s.kofiPressure = s.kofiPressure + 1
              end,
              result = "你陪 Kofi 练到凌晨两点。他的操作又快了一点点。\"够了吗？\" 他问。\"够了。\" 你说。但你们都不确定。" },
            { text = "📣 发动街区，全城应援", hint = "街区+2 · 氛围加成",
              ethics = { integrationVsExtraction = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.streetSupport = s.streetSupport + 2
                  playerData_.reputation = playerData_.reputation + 5
              end,
              result = "你在社区群里发了消息：\"明天，为 Dragon Force 加油！\" 一夜之间，街区的商铺窗户上贴满了Dragon的龙旗。" },
        },
    },

    -- ═══ D29: Victor 最后消息 ═══
    [29] = {
        id = "s1_d29_victor_msg", category = "rivalry",
        title = "📨 Victor的消息",
        desc = "深夜手机响了。Victor 发来一条消息：\"明天见。不管结果如何，你让这条街变得有趣了。祝好运——你会需要的。\" 你盯着屏幕。",
        type = "choice",
        choices = {
            { text = "🤝 回复：\"互相成就，明天尽兴\"", hint = "Victor压力-1 · 格局",
              ethics = { moneyVsPeople = 1 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.victorPressure = math.max(0, s.victorPressure - 1)
              end,
              result = "你回了一条简短的消息。Victor 秒回了个👊。也许——你们之间不只是对手。明天的比赛，多了一层敬意。" },
            { text = "🔥 回复：\"明天让你后悔认识我\"", hint = "Victor压力+1 · 火药味",
              effect = function()
                  local s = playerData_.seasonOne
                  s.victorPressure = s.victorPressure + 1
              end,
              result = "Victor 回了个笑脸emoji。你把手机摔在床上。明天——不是打比赛，是打仗。" },
            { text = "😶 已读不回，沉默备战", hint = "无影响 · 专注",
              effect = function()
                  local s = playerData_.seasonOne
                  s.aelPoints = s.aelPoints + 1
              end,
              result = "你放下手机，闭上眼睛。不需要回应。明天的操作就是最好的回答。你沉沉睡去——梦里全是代码和倒计时。" },
        },
    },

    -- ═══ D30: 第一季决赛（自动演出+最终选择） ═══
    [30] = {
        id = "s1_d30_grand_final", category = "match",
        title = "🏆 第一季决赛",
        desc = "决赛日。天还没亮，门口已经排满了举着 Dragon Force 旗帜的人。全城的目光都在这里。Kofi 在后台闭着眼，嘴唇微动——他在默念操作。一切准备就绪。三十天的故事，今天画上句号。",
        type = "choice",
        choices = {
            { text = "🐉 相信队伍，放手一搏", hint = "综合实力决定结局",
              effect = function()
                  local s = playerData_.seasonOne
                  -- 决赛结果由综合得分决定，这里只标记选择
                  s.finalChoice = "trust_team"
              end,
              result = "你站在教练席上，看着五个少年走上舞台。你什么也没说——该说的三十天前就说完了。灯光亮起。" },
            { text = "🎯 孤注一掷，一切为赢", hint = "增加胜率但代价更大",
              ethics = { resultVsProcess = 2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.finalChoice = "all_in"
                  s.aelPoints = s.aelPoints + 2
                  s.kofiPressure = s.kofiPressure + 2
              end,
              result = "你把所有战术推翻重来，临场变阵。队员们一脸震惊但执行了。这是豪赌——要么辉煌，要么崩盘。" },
            { text = "🌱 不管输赢，享受过程", hint = "降低压力·过程路线",
              ethics = { resultVsProcess = -2 },
              effect = function()
                  local s = playerData_.seasonOne
                  s.finalChoice = "enjoy"
                  s.kofiPressure = math.max(0, s.kofiPressure - 3)
              end,
              result = "你笑着对队伍说：\"开心点。不管结果如何——我们已经走得比任何人想象的远了。\" Kofi 笑了：\"知道了老板。\"" },
        },
    },
}

-- ============================================================================
-- 3. 事件获取接口
-- ============================================================================

--- 获取指定天数的第一季主线事件
---@param day number 当前天数(prevDay, 即刚结束的那天)
---@return table|nil 事件表或nil
function SeasonOneMainline.GetMainEvent(day)
    SeasonOneMainline.EnsureState()
    local evt = MAINLINE_EVENTS[day]
    if not evt then return nil end
    -- 检查是否已触发过
    if playerData_.seasonOne.events[day] then return nil end
    -- 包装 choices: 注入 MarkComplete + ApplyChoiceEthics
    if evt.choices and not evt._wrapped then
        for i, ch in ipairs(evt.choices) do
            local origEffect = ch.effect
            ch.effect = function()
                SeasonOneMainline.MarkComplete(day, i)
                if origEffect then origEffect() end
                if ch.ethics and ApplyChoiceEthics then
                    ApplyChoiceEthics(ch, day, (evt.id or "s1_d" .. day) .. "_c" .. i)
                end
            end
        end
        evt._wrapped = true
    end
    return evt
end

--- 标记事件已完成
---@param day number
---@param choiceIdx number
function SeasonOneMainline.MarkComplete(day, choiceIdx)
    SeasonOneMainline.EnsureState()
    playerData_.seasonOne.events[day] = choiceIdx
end

-- ============================================================================
-- 4. 设施评分
-- ============================================================================

--- 计算网吧设施综合评分(0-100)
---@return number
function SeasonOneMainline.CalcFacilityPower()
    if not playerData_ then return 0 end
    local score = 0
    score = score + (playerData_.computers or 0) * 2
    score = score + (playerData_.netSpeed or 1) * 8
    score = score + (playerData_.generatorLevel or 0) * 10
    score = score + (playerData_.acLevel or 0) * 6
    score = score + (playerData_.securityLevel or 0) * 8
    score = score + math.floor((playerData_.equipCondition or 100) / 10)
    return score
end

-- ============================================================================
-- 5. 路线计算
-- ============================================================================

--- 计算第一季路线(结局分流依据)
---@return string routeId, table scores
function SeasonOneMainline.CalcSeasonOneRoute()
    SeasonOneMainline.EnsureState()
    local s = playerData_.seasonOne
    local ledger = playerData_.ethicsLedger or {}
    local facility = SeasonOneMainline.CalcFacilityPower()

    -- 六条路线得分
    local routes = {
        african_light = 0,   -- 非洲之光
        community_leader = 0, -- 街区领袖
        business_empire = 0,  -- 商业扩张
        gray_rise = 0,        -- 灰色崛起
        victor_mirror = 0,    -- Victor的镜子
        fight_another_day = 0, -- 明日再战
    }

    -- AEL 积分影响
    local ael = s.aelPoints or 0
    if ael >= 15 then routes.african_light = routes.african_light + 30
    elseif ael >= 10 then routes.african_light = routes.african_light + 15 end

    -- 人情vs金钱
    local mvp = ledger.moneyVsPeople or 0
    if mvp >= 3 then
        routes.african_light = routes.african_light + 15
        routes.community_leader = routes.community_leader + 20
    elseif mvp <= -3 then
        routes.business_empire = routes.business_empire + 15
        routes.victor_mirror = routes.victor_mirror + 15
    end

    -- 融入vs榨取
    local ive = ledger.integrationVsExtraction or 0
    if ive >= 3 then
        routes.community_leader = routes.community_leader + 25
        routes.african_light = routes.african_light + 10
    elseif ive <= -3 then
        routes.business_empire = routes.business_empire + 20
    end

    -- 合法vs灰色
    local lvg = ledger.legalVsGray or 0
    if lvg >= 3 then
        routes.community_leader = routes.community_leader + 10
        routes.african_light = routes.african_light + 10
    elseif lvg <= -3 then
        routes.gray_rise = routes.gray_rise + 30
    end

    -- 灰色风险
    if s.grayRisk >= 6 then routes.gray_rise = routes.gray_rise + 20 end

    -- 结果vs过程
    local rvp = ledger.resultVsProcess or 0
    if rvp >= 3 then
        routes.victor_mirror = routes.victor_mirror + 20
    elseif rvp <= -3 then
        routes.community_leader = routes.community_leader + 10
    end

    -- 街区支持
    if s.streetSupport >= 8 then routes.community_leader = routes.community_leader + 20
    elseif s.streetSupport >= 5 then routes.community_leader = routes.community_leader + 10 end

    -- 设施评分
    if facility >= 60 then routes.african_light = routes.african_light + 10 end

    -- 商业数据
    if (playerData_.money or 0) >= 3000 then routes.business_empire = routes.business_empire + 20 end
    if #(playerData_.branches or {}) >= 1 then routes.business_empire = routes.business_empire + 15 end

    -- Victor 压力（被压越多，"Victor的镜子"越高）
    if s.victorPressure >= 5 and ael >= 10 then
        routes.victor_mirror = routes.victor_mirror + 15
    end

    -- 失利兜底
    if ael < 8 then routes.fight_another_day = routes.fight_another_day + 40 end

    -- 找最高分路线
    local bestRoute = "fight_another_day"
    local bestScore = 0
    for k, v in pairs(routes) do
        if v > bestScore then bestScore = v; bestRoute = k end
    end

    return bestRoute, routes
end

-- ============================================================================
-- 6. 第一季结局
-- ============================================================================

local ENDINGS = {
    african_light = {
        title = "🌍 非洲之光",
        subtitle = "从铁皮屋到冠军领奖台",
        matchResult = "Dragon Force 夺冠！Kofi 举起奖杯的照片登上了非洲电竞头版。",
        kofi = "Kofi 成为本地电竞明星，但他说：\"我哪儿也不去。这是我的主场。\"",
        street = "街区为你举办了庆祝派对。孩子们排队要签名。你的网吧成了地标。",
        victor = "Victor 在颁奖典礼上和你握了手：\"下赛季再来。\"",
        future = "青训学院的邀请函已经到了。你的下一步——不只是网吧了。",
        d31Bonus = { repBonus = 50, incomeBonus = 0.2, youthEvents = true },
    },
    community_leader = {
        title = "🏘️ 街区领袖",
        subtitle = "冠军只是称号，社区才是家",
        matchResult = "止步四强，但比赛那天整条街都在你门口看直播。",
        kofi = "Kofi 留下了，并开始教街区的孩子们打游戏。",
        street = "学校主动找来：\"能合作个电竞兴趣班吗？\" 你笑着点头。",
        victor = "Victor 的网吧关门了——不是因为你赢了，而是因为街坊更愿意来你这里。",
        future = "这条街因你而不同。下一步，也许是更多的街区。",
        d31Bonus = { maintenanceDiscount = 0.1, communityEvents = true, repBonus = 30 },
    },
    business_empire = {
        title = "💼 商业帝国",
        subtitle = "从一家店到连锁品牌",
        matchResult = "比赛成绩不是最亮眼的，但你的品牌估值翻了三倍。",
        kofi = "Kofi 还在，但他开始觉得自己只是品牌的一部分。",
        street = "网吧变成了连锁店标准化模板。老邻居说\"变了\"。",
        victor = "Victor 提出合作，而不是竞争。",
        future = "投资人的钱到账了。新城市的第一家分店选址已经确定。",
        d31Bonus = { startMoney = 1000, expansionDiscount = 0.15, repBonus = 10 },
    },
    gray_rise = {
        title = "🌑 灰色崛起",
        subtitle = "赢了比赛，但代价是什么？",
        matchResult = "Dragon Force 进了决赛——但有人在论坛上质疑你们的\"运气\"。",
        kofi = "Kofi 赢了比赛，但赛后他说：\"老板，有些事我不想知道。\"",
        street = "街区的人看你的眼神变了。他们尊重你，但也害怕你。",
        victor = "Victor 输了，但他留了句：\"早晚有人查到的。\"",
        future = "现金很多，但夜里总是睡不安稳。新的\"合作伙伴\"已经在敲门了。",
        d31Bonus = { startMoney = 1500, grayRiskCarry = 2, trustPenalty = -10 },
    },
    victor_mirror = {
        title = "🪞 Victor的镜子",
        subtitle = "你赢了他，但变成了他",
        matchResult = "冠军拿到手了。但你看着奖杯，想起了三十天前的自己。",
        kofi = "Kofi 开始叫你\"老板\"而不是名字。他有多久没笑了？",
        street = "街坊说：\"他跟 Victor 有什么区别？\" 你假装没听见。",
        victor = "Victor 在社交媒体上发了一句：\"欢迎加入俱乐部。\"",
        future = "扩张速度很快，但核心队员开始递辞呈了。",
        d31Bonus = { expansionSpeed = 0.15, loyaltyPenalty = -10, repBonus = 20 },
    },
    fight_another_day = {
        title = "🌅 明日再战",
        subtitle = "输了比赛，但没输掉一切",
        matchResult = "决赛输了。灯灭了，观众散了。但队伍还在。",
        kofi = "Kofi 红着眼说：\"明年，一定赢回来。\" 你信他。",
        street = "回到网吧，门口放着一束花和一张纸条：\"我们还在。\"",
        victor = "Victor 没有嘲讽。他只说了一句：\"下赛季见。\"",
        future = "资源普通，但队伍愿意继续。故事还没写完。",
        d31Bonus = { kofiLoyalty = 10, trainingBonus = 0.1, repBonus = 15 },
    },
}

--- 计算决赛胜负
---@return boolean won
function SeasonOneMainline.CalcFinalResult()
    SeasonOneMainline.EnsureState()
    local s = playerData_.seasonOne
    local power = 0
    -- 基础：AEL 积分
    power = power + (s.aelPoints or 0) * 3
    -- 设施加成
    power = power + SeasonOneMainline.CalcFacilityPower()
    -- 街区声援
    power = power + (s.streetSupport or 0) * 2
    -- 减分
    power = power - (s.kofiPressure or 0) * 3
    power = power - (s.victorPressure or 0) * 2
    power = power - (s.auditRisk or 0) * 4
    -- 最终选择加成
    if s.finalChoice == "all_in" then power = power + 10 end
    if s.finalChoice == "enjoy" then power = power + 3 end
    -- 灰色风险高时额外扣分（审查）
    if s.grayRisk >= 5 then power = power - 15 end

    return power >= 45  -- 45分以上胜利
end

--- 构建第一季结局数据
---@return table ending
function SeasonOneMainline.BuildSeasonOneEnding()
    SeasonOneMainline.EnsureState()
    local won = SeasonOneMainline.CalcFinalResult()
    local route, scores = SeasonOneMainline.CalcSeasonOneRoute()

    -- 胜负修正路线
    if not won and route == "african_light" then
        route = "fight_another_day"
    end
    if not won and route == "victor_mirror" then
        route = "fight_another_day"
    end

    playerData_.seasonOne.endingId = route
    playerData_.seasonOne.finalResult = won and "win" or "lose"

    local ending = ENDINGS[route]
    if not ending then ending = ENDINGS["fight_another_day"] end

    return {
        id = route,
        won = won,
        title = ending.title,
        subtitle = ending.subtitle,
        matchResult = ending.matchResult,
        kofi = ending.kofi,
        street = ending.street,
        victor = ending.victor,
        future = ending.future,
        d31Bonus = ending.d31Bonus,
    }
end

--- 应用结局奖励到 D31+ 存档
function SeasonOneMainline.ApplySeasonEndingRewards()
    SeasonOneMainline.EnsureState()
    local endingId = playerData_.seasonOne.endingId
    if not endingId then return end
    local ending = ENDINGS[endingId]
    if not ending or not ending.d31Bonus then return end

    local bonus = ending.d31Bonus
    playerData_.seasonOneBonus = bonus
    playerData_.postSeason = true
    playerData_.season = 2

    -- 立即生效的奖励
    if bonus.repBonus then
        playerData_.reputation = (playerData_.reputation or 0) + bonus.repBonus
    end
    if bonus.startMoney then
        playerData_.money = (playerData_.money or 0) + bonus.startMoney
    end

    -- 持续性加成写入标记（供其他系统读取）
    playerData_.seasonOneEndingShown = true
end

--- 获取设施升级推荐
---@return table {name, reason, impact}
function SeasonOneMainline.GetUpgradeRecommendation()
    SeasonOneMainline.EnsureState()
    local s = playerData_.seasonOne
    local day = playerData_.day or 1

    if s.kofiPressure >= 4 then
        return { name = "空调/环境", reason = "Kofi 压力过大，需要舒适环境", impact = "队员疲劳降低，训练效率提升" }
    end
    if s.victorPressure >= 4 then
        return { name = "安保/监控", reason = "Victor 动作频繁，需要防范", impact = "破坏风险下降，可收集证据" }
    end
    if day >= 15 and day <= 17 then
        return { name = "网络", reason = "AEL 预选赛临近", impact = "比赛稳定性提升，掉线风险降低" }
    end
    if day >= 18 and day <= 22 then
        return { name = "电力/发电机", reason = "正赛期间停电风险高", impact = "比赛不受停电影响，审查加分" }
    end
    if day >= 23 and day <= 28 then
        return { name = "电脑", reason = "半决赛需要更强硬件", impact = "训练效率和基础战力提升" }
    end
    return { name = "网络", reason = "通用推荐", impact = "口碑和比赛稳定性" }
end

return SeasonOneMainline
