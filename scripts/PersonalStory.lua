-- ============================================================================
-- PersonalStory.lua — 陈路个人叙事系统
-- 包含：个人碎片揭露 / 结局分支 / 章节独白 / 社区觉醒弧 / 表叔远程线 / NPC来信
-- ============================================================================
---@diagnostic disable: undefined-global

local PersonalStory = {}

-- ============================================================================
-- 1. 场景图注册（新增）
-- ============================================================================
PersonalStory.SCENE_IMAGES = {
    memory_night    = "image/scene_memory_night_20260607081222.png",
    memory_shenzhen = "image/scene_memory_shenzhen_20260607081227.png",
    community       = "image/scene_community_meeting_20260607081217.png",
    summit          = "image/scene_summit_20260607081218.png",
    farewell        = "image/scene_farewell_prestige_20260607081215.png",
}

-- ============================================================================
-- 2. 个人故事碎片（12节点渐进揭露）
-- ============================================================================
PersonalStory.FRAGMENTS = {
    -- D1 开局独白（附着在comic结束后）
    {
        id = "personal_d1_arrival",
        cond = function() return playerData_.day == 1 and not storyTriggered_["personal_d1_arrival"] end,
        trigger = "post_comic", -- 漫画结束后自动触发
        dialogues = {
            { speaker = "你", text = "单程票。47万的债。一间烂网吧。", type = "monologue" },
            { speaker = "你", text = "……至少比在深圳等死强。", type = "monologue" },
        },
    },
    -- D3 Kofi训练时暗示
    {
        id = "personal_d3_kofi_hint",
        cond = function() return playerData_.day >= 3 and storyTriggered_["tutorial_first_train"] end,
        trigger = "append_dialogue", -- 附着在训练教程事件后
        append_to = "tutorial_first_train",
        dialogues = {
            { speaker = "Kofi", text = "老板，你教我的走位很专业啊，以前打过比赛？" },
            { speaker = "你", text = "……以前玩过一点。", type = "monologue" },
        },
    },
    -- D5 专精选择时内心
    {
        id = "personal_d5_specialization",
        cond = function() return storyTriggered_["specialization_choice"] end,
        trigger = "append_monologue",
        append_to = "specialization_choice",
        dialogues = {
            { speaker = "你", text = "选电竞？我当年就是在这个坎上摔的。算了，这次不一样。", type = "monologue" },
        },
    },
    -- D8 Victor嘲讽后内心
    {
        id = "personal_d8_victor",
        cond = function() return playerData_.day >= 8 and storyTriggered_["rival_appears"] end,
        trigger = "append_monologue",
        append_to = "rival_appears",
        dialogues = {
            { speaker = "你", text = "\"外国人来捞金\"——他不知道，我是逃过来的。", type = "monologue" },
        },
    },
    -- D12 Grace追问（独立小事件）
    {
        id = "personal_grace_question",
        cond = function()
            return playerData_.day >= 12
                and playerData_.reputation >= 30
                and not storyTriggered_["personal_grace_question"]
        end,
        trigger = "story_event", -- 走标准故事事件槽
        type = "choice",
        title = "Grace的追问",
        icon = "💬",
        desc = "收摊后，Grace突然问你：\"陈，你到底为什么来非洲？\" 你该怎么回答？",
        choices = {
            {
                text = "🌍 \"听说这边有机会\"",
                result = "Grace看着你笑了笑：\"你在撒谎。不过没关系，每个来这里的人都有自己的故事。\"",
                effect = function()
                    AddChatMsg("Grace", "每个人都有不想提的过去。但这里的日落不问你从哪来。", false, false)
                end,
            },
            {
                text = "💸 \"欠了钱，跑路来的\"",
                result = "Grace愣了一下，然后轻声说：\"诚实。我喜欢。\" 她没再问下去。",
                effect = function()
                    playerData_.karma = (playerData_.karma or 0) + 1
                    AddChatMsg("Grace", "谢谢你的诚实。在这条街上，信任比钱值钱。", false, false)
                end,
            },
            {
                text = "🤷 \"说不清楚\"",
                result = "Grace点点头：\"说不清楚就对了。来非洲的人，没几个说得清。\"",
                effect = function()
                    AddChatMsg("Grace", "没关系，日子会替你回答这个问题的。", false, false)
                end,
            },
        },
    },
    -- D15 催债电话（微事件/Chat）
    {
        id = "personal_d15_debt_call",
        cond = function()
            return playerData_.day >= 15 and not storyTriggered_["personal_d15_debt_call"]
        end,
        trigger = "chat_message", -- 通过Chat系统呈现
        messages = {
            { sender = "未知号码", content = "陈先生，您的分期已逾期6个月。请尽快联系我们协商还款方案。", isSelf = false },
            { sender = "你", content = "（挂断。手在抖。）", isSelf = true },
        },
    },
    -- D20 深夜独白——完整揭露18岁（核心节点）
    {
        id = "personal_d20_full_reveal",
        cond = function()
            return playerData_.day >= 20
                and storyTriggered_["victor_dissolution"]
                and not storyTriggered_["personal_d20_full_reveal"]
        end,
        trigger = "story_event",
        type = "dialogue",
        title = "深夜",
        scene = "memory_night", -- 使用新场景图
        dialogues = {
            { speaker = "旁白", text = "Victor走了。网吧安静下来。你打开了那段存了九年的视频。" },
            { speaker = "你", text = "2017年。深圳。青训最终选拔。最后八人取四。", type = "monologue" },
            { speaker = "你", text = "第三局关键团战，我手抖了。队友喊着我的ID，我听不见。", type = "monologue" },
            { speaker = "你", text = "教练说：'陈路，心态不过关。下次机会……' 没有下次了。", type = "monologue" },
            { speaker = "旁白", text = "视频结束。屏幕黑了。你看着玻璃上自己的倒影——27岁，在非洲开网吧的前电竞青训生。" },
            { speaker = "你", text = "但Kofi不会这样。他不会。", type = "monologue" },
        },
        effect = function()
            AddChatMsg("系统", "【记忆碎片】你想起了9年前的那个下午。", false, true)
        end,
    },
    -- D25 Kofi达到高水平
    {
        id = "personal_d25_kofi_growth",
        cond = function()
            if playerData_.day < 25 then return false end
            for _, m in ipairs(teamMembers_ or {}) do
                if m.name == "Kofi" and (m.skill or 0) >= 70 then return true end
            end
            return false
        end,
        trigger = "append_monologue",
        append_to = "kofi_highlight", -- Kofi的NPCStoryline高光阶段
        dialogues = {
            { speaker = "你", text = "看着他站在赛场上，我想起了自己18岁的那个下午。他不会重蹈我的覆辙。", type = "monologue" },
        },
    },
    -- D35 表叔来电（关键选择）
    {
        id = "personal_d35_uncle_call",
        cond = function()
            return playerData_.day >= 35 and not storyTriggered_["personal_d35_uncle_call"]
        end,
        trigger = "story_event",
        type = "choice",
        title = "表叔的电话",
        icon = "📱",
        desc = "表叔的声音从电话那头传来：\"阿路，你妈让我问你，今年过年回不回来？\" 你沉默了很久。",
        choices = {
            {
                text = "🏠 \"我……考虑一下\"",
                result = "表叔叹了口气：\"别考虑太久。你妈头发都白了一半了。\" 挂了电话，你看着窗外的芒果树发呆。",
                effect = function()
                    playerData_.uncleChoice = "hesitate"
                    AddChatMsg("表叔", "别想太久。你妈每次视频都问你。", false, false)
                end,
            },
            {
                text = "🌍 \"叔，我在这边挺好的\"",
                result = "\"挺好的？\" 表叔笑了，\"行吧，你自己的路自己走。叔也拦不住你。\"",
                effect = function()
                    playerData_.uncleChoice = "stay"
                    playerData_.karma = (playerData_.karma or 0) + 1
                    AddChatMsg("表叔", "年轻人有自己的路。叔支持你。", false, false)
                end,
            },
            {
                text = "💰 \"等我把债还清就回\"",
                result = "表叔沉默了两秒：\"阿路，有些东西比钱重要。\" 你不知道他说的是什么。",
                effect = function()
                    playerData_.uncleChoice = "debt_first"
                    AddChatMsg("表叔", "钱的事叔能帮一点。别把自己逼太紧。", false, false)
                end,
            },
        },
    },
    -- D48 前合伙人来信
    {
        id = "personal_d48_partner_msg",
        cond = function()
            return playerData_.day >= 48 and not storyTriggered_["personal_d48_partner_msg"]
        end,
        trigger = "chat_message",
        messages = {
            { sender = "张鑫（前合伙人）", content = "路哥，好久没联系了。钱的事……是我对不起你。我现在在送外卖，每个月能还你两千。希望你能原谅我。", isSelf = false },
        },
        -- 延迟触发选择事件
        followup_event = {
            id = "personal_d48_forgiveness",
            type = "choice",
            title = "迟到的道歉",
            icon = "✉️",
            desc = "张鑫——当年卷走你全部积蓄的合伙人——发来了道歉消息。你要怎么回复？",
            choices = {
                {
                    text = "🤝 \"算了，都过去了\"",
                    result = "你打了三遍才发出去。手指每次都会犹豫。但发出去的那一刻，心里某个绷了三年的东西松了。",
                    effect = function()
                        playerData_.karma = (playerData_.karma or 0) + 2
                        playerData_.partnerChoice = "forgive"
                        AddChatMsg("你", "算了。把日子过好比什么都重要。", true, false)
                        AddChatMsg("张鑫（前合伙人）", "路哥……谢谢你。我会慢慢还的。", false, false)
                    end,
                },
                {
                    text = "😶 不回复",
                    result = "你盯着屏幕看了很久，最终锁屏放下了手机。有些事，不是一句'对不起'能翻篇的。",
                    effect = function()
                        playerData_.partnerChoice = "ignore"
                    end,
                },
                {
                    text = "😤 \"两千？当年你卷走47万\"",
                    result = "发完你就后悔了。可是——凭什么原谅？你来非洲，根子上就是因为他。",
                    effect = function()
                        playerData_.karma = (playerData_.karma or 0) - 1
                        playerData_.partnerChoice = "angry"
                        AddChatMsg("你", "两千块就想买我三年的原谅？你觉得够吗？", true, false)
                    end,
                },
            },
        },
    },
    -- D52 "会记得我吗"（触发结局倒计时）
    {
        id = "personal_d52_legacy",
        cond = function()
            return playerData_.day >= 52
                and playerData_.reputation >= 200
                and not storyTriggered_["personal_d52_legacy"]
        end,
        trigger = "story_event",
        type = "dialogue",
        title = "深夜独白",
        scene = "memory_night",
        dialogues = {
            { speaker = "旁白", text = "又是一个停电的夜晚。网吧里只有发电机的嗡嗡声。" },
            { speaker = "你", text = "如果明天离开，这里会记得我吗？", type = "monologue" },
            { speaker = "你", text = "还是说——我舍不得离开？", type = "monologue" },
            { speaker = "旁白", text = "发电机停了。窗外传来非洲鼓的节奏。有人在笑。" },
            { speaker = "你", text = "深圳不会停电。但深圳也不会有这些。", type = "monologue" },
        },
        effect = function()
            playerData_.legacyQuestionAsked = true
        end,
    },
}

-- ============================================================================
-- 3. 章节开场独白
-- ============================================================================
PersonalStory.CHAPTER_OPENINGS = {
    [1] = {
        dialogues = {
            { speaker = "你", text = "我站在Wakandaville的街头，看着这间铁皮屋顶的网吧。", type = "monologue" },
            { speaker = "你", text = "三台二手电脑，一条20兆宽带，和我最后的全部身家。", type = "monologue" },
            { speaker = "你", text = "这里的规矩比法律多——但至少，没人认识我。", type = "monologue" },
        },
    },
    [2] = {
        dialogues = {
            { speaker = "你", text = "Victor走了。街坊们说我赢了。", type = "monologue" },
            { speaker = "你", text = "可那通催债电话还在。我欠的不止是钱——我欠自己一个交代。", type = "monologue" },
            { speaker = "你", text = "不过……这条街的游戏，才刚刚开始。", type = "monologue" },
        },
    },
    [3] = {
        dialogues = {
            { speaker = "你", text = "记者把麦克风递到我面前的时候，我第一次觉得——", type = "monologue" },
            { speaker = "你", text = "我不再只是一个逃来非洲的失败者了。", type = "monologue" },
            { speaker = "你", text = "这个社区的未来，好像真的和我有关系。", type = "monologue" },
        },
        scene = "community",
    },
    [4] = {
        dialogues = {
            { speaker = "你", text = "从Wakandaville的铁皮屋到行业峰会的演讲台，不过半年。", type = "monologue" },
            { speaker = "你", text = "有人叫我先驱，有人叫我投机者。", type = "monologue" },
            { speaker = "你", text = "但我知道，这片大陆上还有更大的舞台。", type = "monologue" },
        },
        scene = "summit",
    },
    [5] = {
        dialogues = {
            { speaker = "你", text = "我又回来了。不同的城市，不同的面孔，但同样的黄昏。", type = "monologue" },
            { speaker = "你", text = "表叔去年回了国。这边只剩我一个老陈家的人。", type = "monologue" },
            { speaker = "你", text = "这一次，我不是在逃。这一次，我是在找。", type = "monologue" },
        },
    },
}

-- ============================================================================
-- 4. 社区觉醒弧（8事件 D20-35 填补主线空白）
-- ============================================================================
PersonalStory.COMMUNITY_ARC = {
    {
        id = "community_voice",
        cond = function()
            return playerData_.day >= 20 and playerData_.reputation >= 80
        end,
        type = "choice",
        title = "街坊联名信",
        icon = "📜",
        desc = "一份签了23个名字的信被塞到你门缝下：\"Dragon Net的陈老板，我们需要你的帮助。街区的NEPA供电问题，只有你能协调。\"",
        choices = {
            {
                text = "✊ \"我来想办法\"",
                result = "你没想到自己会答应。但看着那些歪歪扭扭的签名，你发现——这些人信任你。一个外国人。",
                effect = function()
                    playerData_.communityPath = "engaged"
                    playerData_.reputation = playerData_.reputation + 10
                    AddChatMsg("Mama B", "陈老板答应帮忙了！我就说他是好人！", false, false)
                end,
            },
            {
                text = "😰 \"我只是开网吧的……\"",
                result = "Mama B敲门进来：\"你不只是开网吧的。你是这条街上唯一有电脑的人。\" 你无法反驳。",
                effect = function()
                    playerData_.communityPath = "reluctant"
                    playerData_.reputation = playerData_.reputation + 5
                    AddChatMsg("Mama B", "没关系，慢慢来。我们等你准备好。", false, false)
                end,
            },
        },
    },
    {
        id = "power_cooperative",
        cond = function()
            return playerData_.day >= 22 and storyTriggered_["community_voice"]
        end,
        type = "choice",
        title = "电力合作社",
        icon = "⚡",
        desc = "你和隔壁的修车铺老板Ibrahim、卖布的Auntie Rose坐在一起，讨论联合购买一台工业发电机的可能性。每家出$200，共享电力。",
        choices = {
            {
                text = "💰 出$200加入合作社",
                result = "三天后，发电机轰隆响起。整条街第一次在停电时还有灯光。Mama B说：\"这是一个中国人带给我们的。\"",
                effect = function()
                    playerData_.money = playerData_.money - 200
                    playerData_.communityCoopJoined = true
                    playerData_.reputation = playerData_.reputation + 15
                    -- 降低未来停电损失
                    playerData_.powerCoopLevel = 1
                end,
            },
            {
                text = "🤔 先观望一下",
                result = "Ibrahim耸耸肩：\"没关系，门永远为你开着。\" 合作社还是成立了——只是没有你。",
                effect = function()
                    AddChatMsg("Ibrahim", "陈，下次停电的时候想想我们的提议。", false, false)
                end,
            },
        },
    },
    {
        id = "youth_program",
        cond = function()
            return playerData_.day >= 24
                and playerData_.reputation >= 100
                and #(teamMembers_ or {}) >= 3
                and storyTriggered_["community_voice"]
        end,
        type = "choice",
        title = "少年培训计划",
        icon = "🎓",
        desc = "放学后，五六个穿校服的孩子趴在你网吧窗户上看里面的比赛。Grace凑过来说：\"你有没有想过，给这些孩子开个免费培训班？\"",
        choices = {
            {
                text = "🎮 每周六免费开放2小时",
                result = "第一个周六来了12个孩子。你教他们基本操作，Kofi当助教。有个小女孩说：\"我长大要当职业选手。\" 你笑了。",
                effect = function()
                    playerData_.youthProgram = true
                    playerData_.reputation = playerData_.reputation + 20
                    playerData_.karma = (playerData_.karma or 0) + 2
                    AddChatMsg("Grace", "你不知道你做了多大的事。这些孩子以前放学只能去街上。", false, false)
                end,
            },
            {
                text = "💼 \"精力有限，先顾好生意\"",
                result = "Grace没说什么。但那些孩子下周还是来了，趴在窗户上看。",
                effect = function()
                    AddChatMsg("Grace", "没关系。等你准备好的时候，孩子们还在。", false, false)
                end,
            },
        },
    },
    {
        id = "media_attention",
        cond = function()
            return playerData_.day >= 26
                and storyTriggered_["youth_program"]
                and (playerData_.youthProgram == true)
        end,
        type = "dialogue",
        title = "记者来访",
        scene = "community",
        dialogues = {
            { speaker = "旁白", text = "一个拿着手机的年轻人走进来，自称是本地网络媒体的记者。" },
            { speaker = "记者", text = "陈先生，听说你在做免费电竞培训？一个中国人为什么要帮非洲孩子？" },
            { speaker = "你", text = "（你该怎么回答？）", type = "monologue" },
            { speaker = "你", text = "因为……有人曾经给过我机会。虽然我没能抓住。", type = "monologue" },
            { speaker = "记者", text = "这个回答会让很多人感动。明天见报。" },
            { speaker = "旁白", text = "第二天，你的网吧照片上了本地新闻。标题是：\"中国网吧老板的非洲电竞梦\"。" },
        },
        effect = function()
            playerData_.reputation = playerData_.reputation + 25
            playerData_.mediaExposure = true
            AddChatMsg("表叔", "阿路，你上新闻了？！链接发我看看！", false, false)
        end,
    },
    {
        id = "government_notice",
        cond = function()
            return playerData_.day >= 28
                and storyTriggered_["media_attention"]
                and (playerData_.mediaExposure == true)
        end,
        type = "choice",
        title = "政府关注函",
        icon = "🏛️",
        desc = "一封盖着公章的信：\"请陈路先生于本周五到区政府商讨'电子竞技青少年计划'合作事宜。\" 这意味着什么？机会，还是麻烦？",
        choices = {
            {
                text = "🤝 准时赴约",
                result = "区长握着你的手：\"我们需要像你这样的人。\" 你不确定这是好事还是坏事——但合作意味着资源。",
                effect = function()
                    playerData_.govRelation = "cooperate"
                    playerData_.reputation = playerData_.reputation + 15
                    playerData_.money = playerData_.money + 500
                    AddChatMsg("系统", "获得政府合作补贴 $500", false, true)
                end,
            },
            {
                text = "📝 回信婉拒，保持独立",
                result = "Grace说你做了正确的决定。\"在这里，和政府走太近不一定是好事。\" 但你隐约感到，有些门可能就此关上了。",
                effect = function()
                    playerData_.govRelation = "independent"
                    playerData_.karma = (playerData_.karma or 0) + 1
                    AddChatMsg("Grace", "好的选择。独立比钱重要。", false, false)
                end,
            },
        },
    },
    {
        id = "community_choice",
        cond = function()
            return playerData_.day >= 30
                and storyTriggered_["government_notice"]
        end,
        type = "choice",
        title = "社区路线",
        icon = "🔀",
        desc = "深夜，你坐在网吧里想着未来。三条路摆在面前——每一条都意味着不同的人生。",
        choices = {
            {
                text = "🏛️ 配合政府，做正规军",
                result = "你给区长回了电话。\"从明天起，Dragon Net正式成为'非洲电竞青年计划'的示范点。\" 街坊有人鼓掌，有人摇头。",
                effect = function()
                    playerData_.communityRoute = "government"
                    playerData_.reputation = playerData_.reputation + 20
                    playerData_.money = playerData_.money + 1000
                    AddChatMsg("系统", "路线确定：政府合作路线。获得启动资金 $1000。", false, true)
                end,
            },
            {
                text = "✊ 独立发展，社区自治",
                result = "你和Mama B、Ibrahim、Grace组成了\"街区委员会\"。没有公章，没有资金，但有23个签名。够了。",
                effect = function()
                    playerData_.communityRoute = "independent"
                    playerData_.reputation = playerData_.reputation + 15
                    playerData_.karma = (playerData_.karma or 0) + 2
                    AddChatMsg("Mama B", "我们不需要政府来告诉我们怎么过日子。", false, false)
                end,
            },
            {
                text = "🌑 地下化，低调赚钱",
                result = "你把培训班的牌子摘了。从今天起，Dragon Net只是一家普通网吧。至于底下做什么……没人需要知道。",
                effect = function()
                    playerData_.communityRoute = "underground"
                    playerData_.karma = (playerData_.karma or 0) - 2
                    playerData_.money = playerData_.money + 800
                    AddChatMsg("Snake", "聪明的选择，老板。有些事不需要放到台面上。", false, false)
                end,
            },
        },
    },
    {
        id = "old_guard_challenge",
        cond = function()
            return playerData_.day >= 32
                and storyTriggered_["community_choice"]
        end,
        type = "choice",
        title = "老行家的挑战",
        icon = "👊",
        desc = "三个穿花衬衫的中年男人走进来。领头的自称\"Big Ade\"，是Wakandaville传统网吧业主协会的会长。\"小子，你动了我们的蛋糕。\"",
        choices = {
            {
                text = "🤝 \"坐下来谈\"",
                result = "Big Ade最终同意了一杯Palm Wine。两小时后，你们达成了\"不互相挖客户\"的君子协定。他走的时候说：\"你比Victor有规矩。\"",
                effect = function()
                    playerData_.reputation = playerData_.reputation + 10
                    playerData_.karma = (playerData_.karma or 0) + 1
                end,
            },
            {
                text = "💪 \"我的店我做主\"",
                result = "Big Ade冷笑着走了。第二天，你发现门口被泼了红漆。Mama B帮你擦掉了：\"别怕，整条街站你这边。\"",
                effect = function()
                    playerData_.reputation = playerData_.reputation + 5
                    AddChatMsg("Mama B", "红漆洗得掉。但名声洗不掉。你做得对。", false, false)
                end,
            },
        },
    },
    {
        id = "sector_summit",
        cond = function()
            return playerData_.day >= 35 and playerData_.reputation >= 150
        end,
        type = "dialogue",
        title = "行业峰会",
        scene = "summit",
        dialogues = {
            { speaker = "旁白", text = "一封正式邀请函：\"西非电竞产业峰会·Wakandaville站\"——你被邀请作为演讲嘉宾。" },
            { speaker = "你", text = "半年前我还在为房租发愁。现在要我上台讲'非洲电竞的未来'？", type = "monologue" },
            { speaker = "旁白", text = "演讲结束后，三个人递来名片。一个是投资人，一个是电视台，还有一个——来自Lagos。" },
            { speaker = "Lagos来人", text = "陈先生，我们Lagos正在筹建电竞中心。有没有兴趣来看看？" },
            { speaker = "你", text = "Lagos……", type = "monologue" },
            { speaker = "旁白", text = "你把名片收进口袋。也许有一天会用到。也许很快。" },
        },
        effect = function()
            playerData_.reputation = playerData_.reputation + 30
            playerData_.summitCompleted = true
            AddChatMsg("表叔", "听说你演讲了？厉害了阿路！你爸要是知道肯定骄傲。", false, false)
        end,
    },
}

-- ============================================================================
-- 5. 表叔远程线（Chat消息系统）
-- ============================================================================
PersonalStory.UNCLE_MESSAGES = {
    { day = 2,  sender = "表叔", content = "落地了？给你妈报个平安。别丢咱老陈家的脸。" },
    { day = 7,  sender = "表叔", content = "你搞网吧？行吧，比工地强。缺钱跟叔说。" },
    { day = 14, sender = "表叔", content = "听说你那边有个叫Victor的在搞你？小心点，非洲人做生意不按规矩来的。" },
    { day = 20, sender = "表叔", content = "你那边电竞搞得不错嘛。我一个朋友想和你谈谈合作，你考虑一下。" },
    { day = 28, sender = "表叔", content = "阿路，叔这边生意也不好做。想回国了。你呢？" },
    { day = 40, sender = "表叔", content = "叔回国了。深圳变化挺大的。你那边还好吧？" },
    { day = 50, sender = "表叔", content = "阿路，叔说句实话——你在那边开心吗？" },
}

-- ============================================================================
-- 6. NPC远方来信（离别后持续联系）
-- ============================================================================
PersonalStory.DEPARTED_MESSAGES = {
    Kofi = {
        { days_after = 7,  content = "老板，我在训练营适应得不错。教练说我有天赋。想你了。—— Kofi" },
        { days_after = 21, content = "今天第一场正式比赛，赢了！想起在Dragon Net练习的日子。" },
        { days_after = 42, content = "联赛第三名。妈妈说，都是因为你当初愿意收留我。谢谢你，老板。" },
        { days_after = 70, content = "我入选国家队了！！！老板你看到新闻了吗！！！" },
    },
    Snake = {
        -- 自首路线
        surrender = {
            { days_after = 14, content = "监狱里的日子不好过，但我在学编程。讽刺吧。—— Snake" },
            { days_after = 35, content = "出来了。想重新开始。Dragon Net还招人吗？" },
        },
        -- 逃跑路线
        flee = {
            { days_after = 14, content = "在边境小镇。过几天就出境了。别找我。" },
            { days_after = 40, content = "在一个没人认识我的地方，开了个小卖部。挺好的。别替我担心。" },
        },
    },
    Grace = {
        { days_after = 10, content = "大学开学了。室友问我为什么选计算机，我说因为认识一个中国网吧老板。哈哈。" },
        { days_after = 30, content = "陈，我拿了奖学金！爸爸的病也稳定了。谢谢你当初借我的那笔钱。" },
        { days_after = 60, content = "毕业论文题目：《数字基础设施与西非青年就业》。你是我最重要的案例。" },
    },
    ["DJ Pulse"] = {
        { days_after = 7,  content = "Lagos的节奏太快了！但我喜欢。每天有三个场子找我。" },
        { days_after = 25, content = "哥，我在Lagos开了自己的录音棚。等你来的时候请你吃正宗Jollof Rice！" },
    },
}

-- ============================================================================
-- 7. 结局分支逻辑
-- ============================================================================
PersonalStory.ENDINGS = {
    {
        id = "ending_empire",
        name = "帝国缔造者",
        cond = function()
            return (playerData_.karma or 0) >= 5
                and playerData_.communityRoute == "government"
                and playerData_.reputation >= 300
        end,
        scene = "ending_empire",
        dialogues = {
            { speaker = "你", text = "我留下来了。", type = "monologue" },
            { speaker = "你", text = "非洲不只是我逃来的地方——它是我建立一切的地方。", type = "monologue" },
            { speaker = "你", text = "47万的债？早就还清了。但我欠这片土地的，永远还不完。", type = "monologue" },
        },
    },
    {
        id = "ending_legend",
        name = "传奇人物",
        cond = function()
            return (playerData_.karma or 0) >= 5
                and playerData_.communityRoute == "independent"
                and playerData_.reputation >= 300
        end,
        scene = "ending_legend",
        dialogues = {
            { speaker = "你", text = "他们管我叫传奇。我觉得好笑。", type = "monologue" },
            { speaker = "你", text = "我只是一个——没有完成电竞梦的人，在非洲开了家网吧。", type = "monologue" },
            { speaker = "你", text = "但如果有一百个Kofi从这里走出去……那也许，就够了。", type = "monologue" },
        },
    },
    {
        id = "ending_beach",
        name = "功成身退",
        cond = function()
            return playerData_.specialization == "esports"
                and (playerData_.tourneyWins or 0) >= 5
        end,
        scene = "ending_beach",
        dialogues = {
            { speaker = "你", text = "世界冠军的教练。18岁的我做梦都不敢想。", type = "monologue" },
            { speaker = "你", text = "不是我站在那个领奖台上——但台上那个人，是我教出来的。", type = "monologue" },
            { speaker = "你", text = "够了。真的够了。", type = "monologue" },
        },
    },
    {
        id = "ending_warmth",
        name = "社区温暖",
        cond = function()
            return playerData_.specialization == "casual"
                and playerData_.reputation >= 300
        end,
        scene = "ending_warmth",
        dialogues = {
            { speaker = "你", text = "那天停电，整条街的人端着蜡烛来我店里。", type = "monologue" },
            { speaker = "你", text = "Mama B炖了花生汤，Ibrahim带了手鼓，孩子们在角落里打手电游戏。", type = "monologue" },
            { speaker = "你", text = "我想，这就是家吧。不需要回去了。", type = "monologue" },
        },
    },
    {
        id = "ending_sunset",
        name = "夕阳商人",
        cond = function()
            return playerData_.specialization == "trader"
                and playerData_.money >= 50000
        end,
        scene = "ending_sunset",
        dialogues = {
            { speaker = "你", text = "47万还清了。存款六位数。我该回去了。", type = "monologue" },
            { speaker = "你", text = "可是机票买了三次，退了三次。", type = "monologue" },
            { speaker = "你", text = "第四次……我把钱投了新店。", type = "monologue" },
        },
    },
    {
        id = "ending_depart",
        name = "逃离",
        cond = function()
            return (playerData_.karma or 0) <= -3
                and playerData_.communityRoute == "underground"
        end,
        scene = "ending_depart",
        dialogues = {
            { speaker = "你", text = "我又在逃了。", type = "monologue" },
            { speaker = "你", text = "上一次从深圳逃来非洲。这一次从非洲逃去……哪里？", type = "monologue" },
            { speaker = "你", text = "也许有些人注定没有家。", type = "monologue" },
        },
    },
    {
        id = "ending_bankrupt",
        name = "破产",
        cond = function()
            return playerData_.money <= 0
        end,
        scene = "ending_bankrupt",
        dialogues = {
            { speaker = "你", text = "深圳一次，Wakandaville一次。", type = "monologue" },
            { speaker = "你", text = "也许有些人注定不适合当老板。", type = "monologue" },
            { speaker = "你", text = "表叔发来消息：回来吧。你妈等你。", type = "monologue" },
        },
    },
}

-- ============================================================================
-- 8. 转生告别仪式
-- ============================================================================
PersonalStory.PRESTIGE_FAREWELL = {
    -- 告别独白（根据城市不同）
    getDialogues = function(currentCity, nextCity)
        local cityNames = {
            wakandaville = "Wakandaville",
            lagos = "Lagos",
            nairobi = "Nairobi",
            accra = "Accra",
            dakar = "Dakar",
            capetown = "Cape Town",
            kinshasa = "Kinshasa",
        }
        local from = cityNames[currentCity] or "这座城市"
        local to = cityNames[nextCity] or "下一座城市"

        return {
            { speaker = "你", text = "最后看一眼" .. from .. "的天际线。这里有我的汗水、争吵、和……朋友。", type = "monologue" },
            { speaker = "你", text = "我要去" .. to .. "了。带着经验，带着伤疤，带着一颗不再害怕的心。", type = "monologue" },
            { speaker = "你", text = "我不是在逃。这一次，我是在走向。", type = "monologue" },
        }
    end,

    -- NPC告别台词
    getNpcFarewells = function()
        local farewells = {}
        -- 检查当前在场的NPC
        for _, m in ipairs(teamMembers_ or {}) do
            if m.name == "Kofi" then
                table.insert(farewells, { speaker = "Kofi", text = "老板……不，哥。一路顺风。我会继续练的。" })
            elseif m.name == "Grace" then
                table.insert(farewells, { speaker = "Grace", text = "陈，去了新地方别忘了我们。" })
            end
        end
        -- 通用告别
        table.insert(farewells, { speaker = "Mama B", text = "孩子，路上小心。记得吃东西。" })
        return farewells
    end,
}

-- ============================================================================
-- 9. 训练/比赛后感悟（append到现有结果）
-- ============================================================================
PersonalStory.MATCH_REFLECTIONS = {
    -- 第1次比赛胜利
    first_win = {
        cond = function() return (playerData_.tourneyWins or 0) == 1 end,
        text = "（第一场胜利。不是我的——但感觉像是我的。）",
    },
    -- 第3次
    third_win = {
        cond = function() return (playerData_.tourneyWins or 0) == 3 end,
        text = "（三场了。2017年的我看到现在，会怎么想？）",
    },
    -- 第5次
    fifth_win = {
        cond = function() return (playerData_.tourneyWins or 0) == 5 end,
        text = "（五连胜。教练当年说我心态不行——现在我教别人心态。）",
    },
}

-- ============================================================================
-- 10. API：外部调用接口
-- ============================================================================

--- 尝试触发个人故事碎片（在EndDay事件瀑布中调用）
---@return boolean 是否触发了事件
function PersonalStory.TryTriggerFragment()
    for _, frag in ipairs(PersonalStory.FRAGMENTS) do
        -- 支持所有触发类型：story_event / append_dialogue / append_monologue / chat_message
        local trigger = frag.trigger or "story_event"
        if trigger ~= "post_comic" and not storyTriggered_[frag.id] then
            local ok, result = pcall(frag.cond)
            if ok and result then
                storyTriggered_[frag.id] = true
                return true, frag
            end
        end
    end
    return false, nil
end

--- 尝试触发社区觉醒弧事件
---@return boolean, table|nil
function PersonalStory.TryTriggerCommunityArc()
    for _, evt in ipairs(PersonalStory.COMMUNITY_ARC) do
        if not storyTriggered_[evt.id] then
            local ok, result = pcall(evt.cond)
            if ok and result then
                storyTriggered_[evt.id] = true
                return true, evt
            end
        end
    end
    return false, nil
end

--- 检查并发送表叔消息（每日结算调用）
function PersonalStory.CheckUncleMessage()
    local day = playerData_.day
    for _, msg in ipairs(PersonalStory.UNCLE_MESSAGES) do
        local msgKey = "uncle_msg_d" .. msg.day
        if day == msg.day and not storyTriggered_[msgKey] then
            storyTriggered_[msgKey] = true
            AddChatMsg(msg.sender, msg.content, false, false)
            return true
        end
    end
    return false
end

--- 检查并发送NPC离别后消息
function PersonalStory.CheckDepartedMessages()
    -- 检查已离开的NPC
    local departed = playerData_.departedNpcs or {}
    for npcName, departInfo in pairs(departed) do
        local daysSince = playerData_.day - (departInfo.departDay or 0)
        local messages = PersonalStory.DEPARTED_MESSAGES[npcName]
        if messages then
            -- Snake有分支
            if npcName == "Snake" and type(messages) == "table" and messages.surrender then
                local route = departInfo.route or "surrender"
                messages = messages[route] or {}
            end
            ---@cast messages table[]
            for _, msg in ipairs(messages) do
                local msgKey = "departed_" .. npcName .. "_" .. msg.days_after
                if daysSince >= msg.days_after and not storyTriggered_[msgKey] then
                    storyTriggered_[msgKey] = true
                    AddChatMsg(npcName, msg.content, false, false)
                    return true
                end
            end
        end
    end
    return false
end

--- 获取章节开场独白
---@param chapter number
---@return table|nil
function PersonalStory.GetChapterOpening(chapter)
    return PersonalStory.CHAPTER_OPENINGS[chapter]
end

--- 计算结局（从ENDINGS表中选择第一个满足条件的）
---@return table|nil
function PersonalStory.DetermineEnding()
    for _, ending in ipairs(PersonalStory.ENDINGS) do
        local ok, result = pcall(ending.cond)
        if ok and result then
            return ending
        end
    end
    -- 默认结局（如果都不满足，给一个通用结局）
    return {
        id = "ending_default",
        name = "新的开始",
        scene = "ending_beach",
        dialogues = {
            { speaker = "你", text = "这段旅程结束了。但故事不会停在这里。", type = "monologue" },
            { speaker = "你", text = "下一站在哪里，我不知道。但我不再害怕了。", type = "monologue" },
        },
    }
end

--- 计算结局评分（影响结局文本变体）
---@return number
function PersonalStory.CalcEndingScore()
    local score = 0
    score = score + math.min((playerData_.karma or 0) * 3, 24)
    score = score + math.min((playerData_.reputation or 0) / 10, 30)
    -- 深交NPC数
    local bonded = 0
    for _, m in ipairs(teamMembers_ or {}) do
        if (m.bond or 0) >= 3 then bonded = bonded + 1 end
    end
    score = score + bonded * 5
    -- 彩蛋发现数
    local eggs = 0
    for k, v in pairs(storyTriggered_ or {}) do
        if k:find("^easter_") then eggs = eggs + 1 end
    end
    score = score + eggs * 2
    return score
end

--- 获取比赛后感悟（如果条件满足）
---@return string|nil
function PersonalStory.GetMatchReflection()
    for _, ref in pairs(PersonalStory.MATCH_REFLECTIONS) do
        local ok, result = pcall(ref.cond)
        if ok and result then
            return ref.text
        end
    end
    return nil
end

return PersonalStory
