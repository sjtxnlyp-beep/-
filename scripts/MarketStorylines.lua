---@diagnostic disable: undefined-global
-- ============================================================================
-- MarketStorylines.lua — 集市摊贩支线故事系统
-- ============================================================================
-- 设计理念（5主策+5文案视角）：
--   主策1: 支线故事提供情感锚点，让集市不只是"抽卡面板"
--   主策2: 故事节点绑定天数+条件，制造"明天还想来"的期待感
--   主策3: 选择产生真实后果（价格折扣/独占道具/NPC关系），驱动重玩
--   主策4: 故事线彼此交叉——摊贩之间有关系网，决策传导
--   主策5: 控制每日故事密度（最多1条/天），避免信息过载
--   文案1: 每个摊贩有鲜明人格弧，从陌生人→朋友的完整旅程
--   文案2: 对话体现非洲本土文化（市场讨价还价/社群互助/梦想与现实）
--   文案3: 悬念钩子——每段结尾留下"下次会怎样"的期待
--   文案4: 选择不应该有明显"正确答案"——都是trade-off
--   文案5: 故事与主线呼应——摊贩的命运映射玩家自己的创业历程
-- ============================================================================

local MarketStorylines = {}

-- ============================================================================
-- 摊贩角色定义
-- ============================================================================
local VENDORS = {
    -- ═══ 阿姆斯特丹小哥 Kwame：走私电子零件的商人，有大梦想 ═══
    kwame = {
        name = "Kwame",
        title = "电子零件贩子",
        icon = "🔧",
        intro = "一个总在修东西的年轻人，据说他的零件来自'神秘渠道'",
    },
    -- ═══ 老太太 Nana Esi：卖护身符的智慧老人 ═══
    nana = {
        name = "Nana Esi",
        title = "护符摊主",
        icon = "🧿",
        intro = "集市上年纪最大的摊主，所有人都叫她Nana",
    },
    -- ═══ 少女 Ama：卖二手键鼠的大学生，想要出国 ═══
    ama = {
        name = "Ama",
        title = "二手外设摊",
        icon = "🖱️",
        intro = "白天摆摊卖键鼠，晚上偷偷学编程的女大学生",
    },
}

-- ============================================================================
-- 故事线定义
-- 架构沿用 NPCStorylines 模式：stage/minDay/interval/condition/event
-- ============================================================================
local STORYLINES = {
    -- ════════════════════════════════════════════════════════════════
    -- 📖 Kwame 线：从小贩到合伙人（5阶段）
    -- 主题：信任与商业伙伴关系 / 灰色地带的道德选择
    -- ════════════════════════════════════════════════════════════════
    kwame = {
        name = "Kwame：零件之王",
        vendorId = "kwame",
        stages = {
            -- 阶段1：初遇——他主动搭讪你
            {
                stage = 1,
                minDay = 4,
                interval = 0,
                condition = function()
                    return (playerData_.marketTotalPulls or 0) >= 3
                end,
                event = {
                    id = "kwame_s1_meet",
                    title = "🔧 角落里的修理摊",
                    desc = "你在集市角落注意到一个年轻人——他面前摆满了各种电子元件，正在焊接什么东西。他抬头看见你，眼睛一亮。",
                    type = "choice",
                    choices = {
                        { text = "过去看看他在修什么",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "\"嘿！中国老板！我听说过你！\" Kwame 兴奋地站起来。\"你看这个，\" 他举起一块主板，\"GTX 1050的显卡——我从拉各斯港口那边搞来的。运费加工加起来才60美金。要不要？\"\n\n他递给你一张皱巴巴的名片：'Kwame Electronic - Everything You Need'。\n\n【Kwame 记住了你】"
                          end },
                        { text = "点头示意，先逛别的",
                          effect = function() end,
                          result = function()
                              return "你礼貌地点了点头继续走。身后传来他的声音：\"改天来找我！我这有好货！\"\n\n你记住了他的位置——集市东南角。\n\n【Kwame 记住了你】"
                          end },
                    },
                },
            },
            -- 阶段2：生意往来——帮你解决设备问题
            {
                stage = 2,
                minDay = 10,
                interval = 4,
                condition = function()
                    return playerData_.day >= 10
                end,
                event = {
                    id = "kwame_s2_deal",
                    title = "🔧 Kwame 的提议",
                    desc = "Kwame 在集市上拦住你：\"老板！我有批好货要到了——二手机械键盘，全是从迪拜那边清仓出来的。我给你成本价！\" 他压低声音：\"但是……我进货的钱不太够。你能不能先垫$150？下周还你，外加两把键盘。\"",
                    type = "choice",
                    choices = {
                        { text = "💰 借他$150（投资关系）",
                          effect = function()
                              playerData_.money = playerData_.money - 150
                              playerData_.karma = (playerData_.karma or 0) + 2
                          end,
                          result = function()
                              return "Kwame 双手握住你的手：\"兄弟！你不会后悔的！Kwame 说话算话！\" 他掏出一个小本子认真记下了数字。\n\n\"下周，我给你最好的货。你等着！\"\n\n你看着他骑着摩托车消失在尘土中。但愿这不是打水漂……\n\n【-$150 / Kwame 信任度↑↑ / 下次集市有惊喜】"
                          end,
                          cond = function() return playerData_.money >= 150 end },
                        { text = "🤝 只买成品，不垫钱",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "\"行吧行吧，\" Kwame 有点失望但很快恢复了笑容。\"那等货到了你第一个来挑！我给你留最好的！\"\n\n他拍拍你的肩膀：\"中国老板够意思。以后有好东西，第一个想到你。\"\n\n【Kwame 关系正常发展】"
                          end },
                    },
                },
            },
            -- 阶段3：出事了——他被人举报
            {
                stage = 3,
                minDay = 18,
                interval = 5,
                condition = function()
                    return playerData_.day >= 18
                end,
                event = {
                    id = "kwame_s3_trouble",
                    title = "🚨 Kwame 摊位空了",
                    desc = "你发现 Kwame 的摊位空了，零件散落一地。隔壁摊主告诉你：\"警察来了，说他的货没有进口许可证。把人带走了。\" 你的手机响了——是 Kwame 的号码。\"老板……我进去了……能不能帮我想想办法？保释金要$300……\"",
                    type = "choice",
                    choices = {
                        { text = "💰 帮他交保释金（-$300）",
                          effect = function()
                              playerData_.money = playerData_.money - 300
                              playerData_.karma = (playerData_.karma or 0) + 3
                          end,
                          result = function()
                              return "第二天 Kwame 出来了，眼眶红红的。\"老板……我这辈子记住你了。\" 他沉默了很久。\n\n\"我想明白了。不能再走灰色路子了。我要正经开个维修店。\" 他看着你：\"你愿意……当我的合伙人吗？\"\n\n【-$300 / Kwame：生死之交 / 合伙机会解锁】"
                          end,
                          cond = function() return playerData_.money >= 300 end },
                        { text = "📞 帮他找律师，但不出钱",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "你帮 Kwame 联系了一个本地律师。过了三天他才出来，瘦了一圈。\n\n\"谢谢老板。\" 他的语气平静了很多。\"我要换个活法了。之前走的那些路子，不能再走了。\"\n\n他开始在集市正规租了个位置，虽然货少了但都有来路。\n\n【Kwame 感恩但更独立 / 后续可能有惊喜】"
                          end },
                        { text = "😔 爱莫能助，不掺和",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) - 1
                          end,
                          result = function()
                              return "你挂了电话。这不是你该管的事。\n\n一周后 Kwame 出来了，但他没来找你。有人说他去了另一个城市。集市角落那个摊位，再也没人摆了。\n\n【Kwame 故事线提前结束 / 失去合作机会】"
                          end },
                    },
                },
            },
            -- 阶段4：合伙——他的维修店开张
            {
                stage = 4,
                minDay = 26,
                interval = 5,
                condition = function()
                    -- 只有帮了他（花了钱或找律师）才触发
                    local triggered = marketStoryProgress_ and marketStoryProgress_.kwame or 0
                    return triggered >= 3 and playerData_.day >= 26
                end,
                event = {
                    id = "kwame_s4_partner",
                    title = "🏪 Kwame 的新店",
                    desc = "Kwame 兴冲冲找到你：\"老板！你看！\" 他带你到集市旁一间小铁皮屋——门口挂着手写招牌 'Dragon Tech Repair'。\"我用你名字命名的！因为没有你就没有这个店！\" 他提出——每周给你送配件，成本价！",
                    type = "choice",
                    choices = {
                        { text = "🤝 入股他的店（投资$200，长期收益）",
                          effect = function()
                              playerData_.money = playerData_.money - 200
                              playerData_.karma = (playerData_.karma or 0) + 2
                              -- 永久效果：每日额外收入
                              playerData_.kwamePartner = true
                          end,
                          result = function()
                              return "你和 Kwame 握手成交。他拿出一张皱巴巴的纸，一笔一划写了个\"合同\"——歪歪扭扭的字，但诚意满满。\n\n\"从今天起，你的网吧设备维修我全包！零件成本价！每个月分红给你！\"\n\n【-$200 / 解锁每日额外收入+$15 / 集市淘货折扣 -10%】"
                          end,
                          cond = function() return playerData_.money >= 200 end },
                        { text = "👏 祝贺他，但保持距离",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "\"你自己的店，自己当家！\" 你拍拍 Kwame 的肩膀。他笑了：\"没关系老板，你永远是我兄弟。以后修东西找我，半价！\"\n\n【集市淘货折扣 -5%】"
                          end },
                    },
                },
            },
            -- 阶段5：回报——关键时刻他帮你
            {
                stage = 5,
                minDay = 35,
                interval = 6,
                condition = function()
                    local triggered = marketStoryProgress_ and marketStoryProgress_.kwame or 0
                    return triggered >= 4 and playerData_.day >= 35
                end,
                event = {
                    id = "kwame_s5_payback",
                    title = "🔧 Kwame 的回报",
                    desc = "比赛前三天，你的核心电脑突然烧了主板！这台机器是主力选手训练专用的！普通渠道维修至少要一周——但比赛等不了。这时 Kwame 出现了：\"老板，你忘了？你兄弟我是做什么的？\"",
                    type = "choice",
                    choices = {
                        { text = "🙏 拜托了兄弟！",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                              -- 训练加成
                              for _, m in ipairs(teamMembers_) do
                                  m.skill = math.min(SKILL_CAP, (m.skill or 0) + 3)
                              end
                          end,
                          result = function()
                              return "Kwame 连夜拆了自己店里的备用板，给你的电脑换上。第二天一早，机器满血复活。\n\n\"兄弟之间，不说这个。\" 他擦了擦手上的焊锡渍。\"你当初帮我的，我这辈子都记着。\"\n\n队员们欢呼着围上去——训练恢复正常！\n\n【全队技术+3 / Kwame 成为你的终生盟友】"
                          end },
                    },
                },
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════
    -- 📖 Nana Esi 线：智慧老人与传承（5阶段）
    -- 主题：本土文化认同 / 精神力量 / 社区纽带
    -- ════════════════════════════════════════════════════════════════
    nana = {
        name = "Nana Esi：集市守护者",
        vendorId = "nana",
        stages = {
            -- 阶段1：她在观察你
            {
                stage = 1,
                minDay = 6,
                interval = 0,
                condition = function()
                    return playerData_.day >= 6
                end,
                event = {
                    id = "nana_s1_observe",
                    title = "🧿 那个一直看着你的老太太",
                    desc = "你注意到每次逛集市，角落卖护身符的老太太都在看着你。今天她终于开口了——用流利的英语。\"中国来的年轻人，你在这里开网吧？\" 她的眼睛很亮，像能看穿你。",
                    type = "choice",
                    choices = {
                        { text = "🙏 恭敬地问候长辈",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.reputation = (playerData_.reputation or 0) + 5
                          end,
                          result = function()
                              return "老太太笑了——满脸皱纹像非洲大地的纹路。\"礼貌的年轻人。我叫 Nana Esi，在这个集市摆了40年摊了。\"\n\n她从围裙口袋里掏出一个小木雕递给你：\"拿着。这是Adinkra符号——代表'新的开始'。在这里做生意……你需要这个。\"\n\n【声望+5 / 获得'新生符'（收藏品）/ Nana Esi 好感↑】"
                          end },
                        { text = "👋 打个招呼就走",
                          effect = function() end,
                          result = function()
                              return "你礼貌地笑笑，准备走开。她轻声说了句什么——你没听清，但隐约觉得是\"会再见的\"。\n\n集市嘈杂声把一切盖过去了。但你记住了她的位置。\n\n【Nana Esi 记住了你】"
                          end },
                    },
                },
            },
            -- 阶段2：她来网吧找你
            {
                stage = 2,
                minDay = 13,
                interval = 5,
                condition = function()
                    return playerData_.day >= 13
                end,
                event = {
                    id = "nana_s2_visit",
                    title = "🧿 不速之客",
                    desc = "午休时，一个意想不到的客人走进网吧—— Nana Esi。她拄着拐杖环顾四周，对着闪烁的屏幕啧啧称奇。\"所以这就是让年轻人疯狂的东西？\" 她走到你面前：\"我孙子 Yaw，14岁。整天说要来你这里。我想先看看你是什么样的人。\"",
                    type = "choice",
                    choices = {
                        { text = "☕ 请她坐下，泡杯茶慢慢聊",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.reputation = (playerData_.reputation or 0) + 10
                          end,
                          result = function()
                              return "你给她泡了绿茶——用从国内带来的最后一包碧螺春。Nana 喝了一口，眼睛亮了：\"好东西。\"\n\n她看了看训练中的队员们：\"你教他们打游戏……也教他们做人？\" 你点头。她沉默了一会，然后说：\n\n\"Yaw 可以来。但你要答应我——如果他不听话，你告诉我。\" 她拍了拍你的手：\"你是个好人。我在这个集市40年，看人不会错。\"\n\n【声望+10 / 社区认可度↑ / 下次集市Nana的摊位有特别折扣】"
                          end },
                        { text = "📋 给她看看训练日程表",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                              playerData_.reputation = (playerData_.reputation or 0) + 5
                          end,
                          result = function()
                              return "你拿出训练计划表给她看——早上体能训练、下午战术分析、晚上实战演练。Nana 点点头：\"有规矩，好。\"\n\n\"Yaw 可以来。\" 她站起身。\"但是——\" 她回头看了你一眼，\"如果他功课落下了，你要负责。\"\n\n\"是的长辈。\" 你认真地说。她似乎满意了。\n\n【声望+5 / 社区信任↑】"
                          end },
                    },
                },
            },
            -- 阶段3：集市危机——她需要帮助
            {
                stage = 3,
                minDay = 20,
                interval = 5,
                condition = function()
                    return playerData_.day >= 20
                end,
                event = {
                    id = "nana_s3_crisis",
                    title = "🧿 集市的坏消息",
                    desc = "Nana Esi 脸色凝重地找到你：\"市政府要拆掉集市了。说要建什么商业中心。\" 她的声音有些颤抖：\"这个集市有200年历史了……是社区的灵魂。\" 她看着你：\"你在中国，有没有见过这样的事？你能不能帮我们想想办法？\"",
                    type = "choice",
                    choices = {
                        { text = "📢 帮忙组织联名请愿 + 拍视频传播",
                          effect = function()
                              playerData_.money = playerData_.money - 80
                              playerData_.karma = (playerData_.karma or 0) + 3
                              playerData_.reputation = (playerData_.reputation or 0) + 30
                          end,
                          result = function()
                              return "你用网吧的设备帮摊主们打印请愿书，还让队员拍了个短视频——\"200年集市的故事\"。视频在本地社交媒体火了！\n\n一周后，市政府宣布：集市保留，但会进行翻修。Nana Esi 在所有摊主面前拉着你的手：\"这个中国年轻人，是我们自己人！\"\n\n【-$80 / 声望+30 / 你在社区彻底扎根了 / Nana 给你集市'永久友谊折扣'】"
                          end },
                        { text = "🤝 精神支持，但不介入本地政治",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                              playerData_.reputation = (playerData_.reputation or 0) + 5
                          end,
                          result = function()
                              return "你安慰了 Nana，但没有直接参与。\"这是你们的集市，你们的家。我相信你们能守住。\"\n\n最终集市确实保留下来了——摊主们自己组织了抗议。Nana 事后对你说：\"我理解。你是外国人，不好掺和。\"\n\n她的语气没有责备，但你感觉她对你的期待少了一些。\n\n【声望+5 / Nana 关系保持平稳】"
                          end },
                    },
                },
            },
            -- 阶段4：传承之物
            {
                stage = 4,
                minDay = 28,
                interval = 5,
                condition = function()
                    local triggered = marketStoryProgress_ and marketStoryProgress_.nana or 0
                    return triggered >= 3 and playerData_.day >= 28
                end,
                event = {
                    id = "nana_s4_gift",
                    title = "🧿 Nana Esi 的传承",
                    desc = "一个特别的日子。Nana Esi 把你叫到她的摊位后面——那里有个小仓库，堆满了几十年的收藏。\"我82岁了，\" 她说，\"这些东西，我带不走。\" 她拿出一个旧木箱：\"你帮了这个集市。这些是我给你的感谢。\"",
                    type = "choice",
                    choices = {
                        { text = "🙏 感恩收下",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 2
                              -- 给玩家一些好道具
                              playerData_.havocCoins = (playerData_.havocCoins or 0) + 200
                              playerData_.reputation = (playerData_.reputation or 0) + 15
                              playerData_.nanaBless = true
                          end,
                          result = function()
                              return "木箱里有几样东西：一条旧的kente布围巾、一个黄铜秤砣（集市创始人用过的）、还有一封信——是她年轻时写给丈夫的情书。\n\n\"围巾给你挡太阳。秤砣代表公平。信……\" 她笑了，\"提醒你做事要用心。\"\n\n你突然觉得——你不只是在这里开网吧。你已经成为这个社区的一部分了。\n\n【获得传承宝物 / 🪙+200 / 声望+15 / 解锁'Nana的祝福'——全队心情衰减-20%】"
                          end },
                    },
                },
            },
            -- 阶段5：告别与新生
            {
                stage = 5,
                minDay = 38,
                interval = 6,
                condition = function()
                    local triggered = marketStoryProgress_ and marketStoryProgress_.nana or 0
                    return triggered >= 4 and playerData_.day >= 38
                end,
                event = {
                    id = "nana_s5_farewell",
                    title = "🧿 一个时代的落幕",
                    desc = "早上来到集市，你发现 Nana 的摊位被鲜花和蜡烛包围——她昨晚在睡梦中安详离世了。整个集市都在默哀。她的孙子 Yaw 红着眼睛递给你一个信封：\"奶奶说……这个要给中国老板。\"",
                    type = "choice",
                    choices = {
                        { text = "📖 打开信封",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.reputation = (playerData_.reputation or 0) + 20
                              -- 永久心情保护
                              playerData_.nanaLegacy = true
                          end,
                          result = function()
                              return "信上是 Nana 工整的字迹：\n\n\"年轻人，你让我看到了一件事——人和人之间的好意，不分国界。你照顾了这些孩子，就像你自己的孩子。这是最大的善。\n\n我把集市东南角那个位置留给你。月租免了。算是老太婆最后的礼物。愿你和你的孩子们一切都好。\"\n\n—— Nana Esi\n\n你站在清晨的阳光里，攥着信纸，第一次在非洲流了泪。\n\n【声望+20 / 集市免费摊位解锁 / 全队心情衰减永久-20% / Nana的精神永远与你同在】"
                          end },
                    },
                },
            },
        },
    },

    -- ════════════════════════════════════════════════════════════════
    -- 📖 Ama 线：从兼职到逆袭的大学生（5阶段）
    -- 主题：教育/科技改变命运 / 性别平等 / 知识经济
    -- ════════════════════════════════════════════════════════════════
    ama = {
        name = "Ama：编程女孩",
        vendorId = "ama",
        stages = {
            -- 阶段1：她比别的摊主不一样
            {
                stage = 1,
                minDay = 8,
                interval = 0,
                condition = function()
                    return playerData_.day >= 8
                end,
                event = {
                    id = "ama_s1_meet",
                    title = "🖱️ 会编程的摊主",
                    desc = "一个戴眼镜的年轻女孩在卖二手键盘鼠标——但与众不同的是，她的摊位后面支着一台笔记本，屏幕上是代码编辑器。你凑近看了一眼——是 Python。她注意到你在看，脸微微发红。",
                    type = "choice",
                    choices = {
                        { text = "💻 \"你在学编程？我也懂一些\"",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "\"真的吗？！\" 她的眼睛亮了起来。\"我叫 Ama，阿克拉大学计算机系的！但是……\" 她的声音低了下去，\"学费好贵。所以白天摆摊。\"\n\n她看了看你的网吧方向：\"你的网吧……也用代码管理吗？\"\n\n你笑了。这个女孩，有潜力。\n\n【Ama 记住了你的善意】"
                          end },
                        { text = "🖱️ 只是来买鼠标的",
                          effect = function() end,
                          result = function()
                              return "你挑了个不错的罗技鼠标——才$5。她仔细地用报纸包好递给你。\n\n\"谢谢光顾！\" 她笑得很阳光。你注意到她的手指有墨水渍——写字或者写代码留下的。\n\n这个摊主，好像和别人不太一样。\n\n【Ama 记住了你】"
                          end },
                    },
                },
            },
            -- 阶段2：她遇到了困境
            {
                stage = 2,
                minDay = 15,
                interval = 5,
                condition = function()
                    return playerData_.day >= 15
                end,
                event = {
                    id = "ama_s2_help",
                    title = "🖱️ Ama 的求助",
                    desc = "Ama 在集市上看起来很沮丧。\"下学期的学费……\" 她叹气。\"我爸说女孩子读那么多书没用。但我想做程序员！\" 她犹豫了一下：\"老板……你网吧需不需要人？我可以兼职帮你修电脑、做网站。工资算进学费就好。\"",
                    type = "choice",
                    choices = {
                        { text = "✅ 收她做兼职（-$50/周，获得技术支持）",
                          effect = function()
                              playerData_.money = playerData_.money - 50
                              playerData_.karma = (playerData_.karma or 0) + 2
                          end,
                          result = function()
                              return "\"真的吗？！\" Ama 几乎跳了起来。\"我不会让你失望的！\"\n\n她第二天就来了——不但修好了3号机的蓝屏，还帮你写了个自动记账的小程序。\n\n\"我还有很多想法……\" 她说，眼里闪着光。\n\n【-$50 / 获得'技术支持'——设备故障概率-30% / Ama 好感↑↑】"
                          end,
                          cond = function() return playerData_.money >= 50 end },
                        { text = "📚 推荐她几个免费学习网站",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "你把 freeCodeCamp 和 Coursera 的地址写给她：\"来我网吧用电脑学，不收你钱。\"\n\nAma 认真地把链接抄在笔记本上：\"谢谢老板……你是第一个鼓励我的人。我爸说女孩子搞电脑没出息，但我不信。\"\n\n她的语气里有一种不服输的劲。\n\n【Ama 好感↑ / 后续她可能用学到的技术帮你】"
                          end },
                    },
                },
            },
            -- 阶段3：她做出了成果
            {
                stage = 3,
                minDay = 22,
                interval = 5,
                condition = function()
                    return playerData_.day >= 22
                end,
                event = {
                    id = "ama_s3_project",
                    title = "🖱️ Ama 的作品",
                    desc = "Ama 兴奋地拿着笔记本来找你：\"老板看！我做了一个APP！\" 屏幕上是一个简陋但功能完整的界面——集市摊位查询工具。\"摊主可以注册，顾客可以搜索谁有什么货！\" 她有些紧张：\"你觉得……有人会用吗？\"",
                    type = "choice",
                    choices = {
                        { text = "🚀 \"太棒了！我帮你推广到整个集市！\"",
                          effect = function()
                              playerData_.money = playerData_.money - 30
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.reputation = (playerData_.reputation or 0) + 15
                          end,
                          result = function()
                              return "你帮 Ama 打印了传单，在集市到处贴。第一周就有20个摊主注册了！\n\n\"全靠你！\" Ama 笑得像个孩子。\"Nana Esi 都注册了！她让孙子帮她拍了护身符的照片上传！\"\n\n这个曾经卖二手鼠标的女孩，开始被人叫做\"集市的技术顾问\"了。\n\n【-$30 / 声望+15 / Ama 的APP让集市现代化了】"
                          end },
                        { text = "💡 \"不错，但需要改进。我提几个建议\"",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "你从用户体验角度给了她一些建议：\"加个地图、让搜索更快、UI再简洁点……\"\n\nAma 认真地记下来：\"我下周改完给你看！\" 一周后果然——新版本好了很多。\n\n\"谢谢老板！\" 她说。\"你比我大学的教授有用多了。\"\n\n【Ama 技术成长↑ / 后续有更强的作品】"
                          end },
                    },
                },
            },
            -- 阶段4：她面临选择
            {
                stage = 4,
                minDay = 30,
                interval = 5,
                condition = function()
                    local triggered = marketStoryProgress_ and marketStoryProgress_.ama or 0
                    return triggered >= 3 and playerData_.day >= 30
                end,
                event = {
                    id = "ama_s4_choice",
                    title = "🖱️ Ama 的十字路口",
                    desc = "Ama 坐在你面前，手里攥着一封信——来自拉各斯一家科技公司的offer。\"月薪是我摆摊的10倍……\" 她说，\"但是得搬到拉各斯去。\" 她看着你：\"如果我走了……集市的APP谁维护？Nana的孙子Yaw刚学会用……\"",
                    type = "choice",
                        choices = {
                        { text = "✈️ \"去吧！这是你应得的\"",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.reputation = (playerData_.reputation or 0) + 10
                          end,
                          result = function()
                              return "\"真的？\" Ama 的眼眶红了。\"我……我以为你会让我留下来。\"\n\n\"你的才华不该被困在一个小集市里。\" 你说。\"去吧，去拉各斯。去改变更多人。\"\n\n她站起来深深鞠了一躬：\"老板，你是我遇到过最好的人。我每个月都会回来看你们的。\"\n\n走的那天，整个集市都来送她了。\n\n【声望+10 / Ama 远程继续维护APP / 每月给你科技资讯加成】"
                          end },
                        { text = "🤔 \"要不……先远程试试？\"",
                          effect = function()
                              playerData_.karma = (playerData_.karma or 0) + 1
                          end,
                          result = function()
                              return "你提了个折中方案：问公司能不能远程办公？Ama 试着去谈了——结果公司同意每周只去一天！\n\n\"老板你太聪明了！\" 她开心地说。\"这样我还能看着集市的APP，也能在你网吧帮忙！\"\n\n有时候最好的答案不是二选一。\n\n【Ama 留在身边 / 科技公司收入分你一部分 / 持续技术支持】"
                          end },
                    },
                },
            },
            -- 阶段5：她成功了
            {
                stage = 5,
                minDay = 40,
                interval = 6,
                condition = function()
                    local triggered = marketStoryProgress_ and marketStoryProgress_.ama or 0
                    return triggered >= 4 and playerData_.day >= 40
                end,
                event = {
                    id = "ama_s5_success",
                    title = "🖱️ TED演讲邀请",
                    desc = "Ama 发来消息——附了一张截图：TEDx Accra 邀请她去做演讲！题目：\"从集市到代码——一个非洲女孩的科技之路\"。\"老板……\" 她的语音消息声音发颤：\"他们问我有没有mentor要感谢。我说有。我说了你的名字。\"",
                    type = "choice",
                    choices = {
                        { text = "😊 \"我只是给了你一个机会。路是你自己走的。\"",
                          effect = function()
                              playerData_.reputation = (playerData_.reputation or 0) + 30
                              playerData_.karma = (playerData_.karma or 0) + 2
                              playerData_.amaMentor = true
                          end,
                          result = function()
                              return "TED 演讲的视频你看了三遍。Ama 站在舞台上，自信满满：\n\n\"……我曾经在集市卖二手鼠标。直到遇到一个中国网吧老板——他看到了我的代码，而不是我的性别。他说：'你不该被困在这里'。\"\n\n台下掌声雷动。\n\n评论区最热的一条：\"这才是真正的全球化——不是产品出海，是善意出海。\"\n\n【声望+30 / 解锁'编程导师'声望 / Ama 成为你在科技圈的人脉】"
                          end },
                    },
                },
            },
        },
    },
}

-- ============================================================================
-- 引擎逻辑
-- ============================================================================

--- 初始化/兼容旧存档
function MarketStorylines.Init()
    if not marketStoryProgress_ then
        marketStoryProgress_ = {}
    end
    if not marketStoryCompleted_ then
        marketStoryCompleted_ = {}  -- {eventId = true}
    end
    if not marketStoryLastDay_ then
        marketStoryLastDay_ = {}  -- {vendorId = lastTriggerDay}
    end
end

--- 获取某摊贩当前阶段号
function MarketStorylines.GetStage(vendorId)
    MarketStorylines.Init()
    return (marketStoryProgress_[vendorId] or 0)
end

--- 检查某事件是否已完成
function MarketStorylines.IsCompleted(eventId)
    MarketStorylines.Init()
    return marketStoryCompleted_[eventId] == true
end

--- 尝试推进故事（每天最多触发1个集市故事）
--- 返回: event table 或 nil
function MarketStorylines.TryAdvance(currentDay)
    MarketStorylines.Init()

    -- 收集所有可触发的故事节点
    local candidates = {}

    for vendorId, storyline in pairs(STORYLINES) do
        local currentStage = marketStoryProgress_[vendorId] or 0
        local nextStageNum = currentStage + 1
        local stages = storyline.stages

        -- 找到下一阶段
        local nextStage = nil
        for _, s in ipairs(stages) do
            if s.stage == nextStageNum then
                nextStage = s
                break
            end
        end

        if nextStage then
            -- 检查天数要求
            if currentDay >= nextStage.minDay then
                -- 检查间隔
                local lastDay = marketStoryLastDay_[vendorId] or 0
                if (currentDay - lastDay) >= nextStage.interval then
                    -- 检查条件
                    local condOK = true
                    if nextStage.condition then
                        local ok, res = pcall(nextStage.condition)
                        condOK = ok and res
                    end
                    if condOK then
                        table.insert(candidates, {
                            vendorId = vendorId,
                            stageNum = nextStageNum,
                            stage = nextStage,
                            priority = nextStageNum, -- 低阶段优先
                        })
                    end
                end
            end
        end
    end

    if #candidates == 0 then return nil end

    -- 优先触发低阶段（让玩家先认识所有摊贩，再深入）
    table.sort(candidates, function(a, b) return a.priority < b.priority end)

    local chosen = candidates[1]
    return chosen.stage.event, chosen.vendorId, chosen.stageNum
end

--- 标记故事事件完成，推进阶段
function MarketStorylines.OnEventCompleted(eventId, vendorId, stageNum)
    MarketStorylines.Init()
    marketStoryCompleted_[eventId] = true
    marketStoryProgress_[vendorId] = stageNum
    marketStoryLastDay_[vendorId] = playerData_.day
end

--- 获取所有摊贩的故事预览（用于UI展示）
function MarketStorylines.GetAllPreviews()
    MarketStorylines.Init()
    local previews = {}
    for vendorId, storyline in pairs(STORYLINES) do
        local stage = marketStoryProgress_[vendorId] or 0
        local totalStages = #storyline.stages
        local vendor = VENDORS[vendorId]
        table.insert(previews, {
            vendorId = vendorId,
            name = vendor and vendor.name or vendorId,
            icon = vendor and vendor.icon or "❓",
            title = vendor and vendor.title or "",
            storyName = storyline.name,
            currentStage = stage,
            totalStages = totalStages,
            completed = stage >= totalStages,
        })
    end
    return previews
end

--- 获取摊贩信息
function MarketStorylines.GetVendor(vendorId)
    return VENDORS[vendorId]
end

--- 判断是否是集市故事事件
function MarketStorylines.IsMarketStoryEvent(eventId)
    if not eventId then return false end
    for _, storyline in pairs(STORYLINES) do
        for _, stage in ipairs(storyline.stages) do
            if stage.event and stage.event.id == eventId then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- Layer 1: 氛围文本系统 — 每次逛集市时注入1-2句环境描写
-- ============================================================================

--- 根据当前认识的NPC和故事进度，生成沉浸式环境描写
--- @return string|nil 氛围文本（nil表示玩家还没认识任何摊贩）
function MarketStorylines.GetAmbientText()
    MarketStorylines.Init()

    local kwameStage = marketStoryProgress_.kwame or 0
    local nanaStage = marketStoryProgress_.nana or 0
    local amaStage = marketStoryProgress_.ama or 0

    -- 还没认识任何人，不输出氛围
    if kwameStage == 0 and nanaStage == 0 and amaStage == 0 then
        return nil
    end

    -- 按角色和阶段收集氛围片段
    local snippets = {}

    -- ── Kwame 氛围 ──
    if kwameStage == 1 then
        table.insert(snippets, "路过角落时，Kwame 正蹲在地上焊接什么，看见你抬手打了个招呼。")
        table.insert(snippets, "Kwame 的摊位前多了几块新到的显卡，他朝你挤了挤眼。")
    elseif kwameStage == 2 then
        table.insert(snippets, "Kwame 骑着摩托车从远处过来，车后座绑着一箱子货，冲你按了两声喇叭。")
        table.insert(snippets, "\"老板！等会儿来看看新到的货！\" Kwame 远远喊了一声。")
    elseif kwameStage == 3 then
        table.insert(snippets, "Kwame 的摊位挂了个手写的新招牌，字写得歪歪扭扭但很认真。")
        table.insert(snippets, "你注意到 Kwame 在和一个穿制服的人交谈，表情严肃但平静。")
    elseif kwameStage == 4 then
        table.insert(snippets, "Dragon Tech Repair 的铁皮门半开着，里面传来Kwame哼歌的声音。")
        table.insert(snippets, "Kwame 的小店门口排了两个客人，他忙得满头是汗但乐呵呵的。")
    elseif kwameStage >= 5 then
        table.insert(snippets, "路过 Dragon Tech 时，Kwame 正在教一个小男孩拆装电脑——\"兄弟，你那个键盘我修好了！\"")
        table.insert(snippets, "Kwame 的店铺旁边多了一面锦旗，是客户送的——\"技术精湛，价格公道\"。")
    end

    -- ── Nana Esi 氛围 ──
    if nanaStage == 1 then
        table.insert(snippets, "Nana Esi 在她的摊位后面打瞌睡，膝盖上摊着一本旧圣经。")
        table.insert(snippets, "一个年轻妈妈抱着孩子在 Nana 摊位前挑护身符，Nana 认真地帮她选。")
    elseif nanaStage == 2 then
        table.insert(snippets, "Nana 的孙子 Yaw 坐在奶奶摊位旁，偷偷用手机打游戏——被Nana敲了一下脑袋。")
        table.insert(snippets, "Nana 正在给一个小男孩讲故事，周围围了五六个孩子听得入迷。")
    elseif nanaStage == 3 then
        table.insert(snippets, "集市里多了几张反对拆迁的标语，Nana 的摊位上挂着最大的一张。")
        table.insert(snippets, "几个摊主聚在 Nana 旁边低声讨论什么，见你走近纷纷点头致意。")
    elseif nanaStage == 4 then
        table.insert(snippets, "Nana 今天戴了条漂亮的 kente 布头巾，精神头比平时好。她远远朝你微笑。")
        table.insert(snippets, "你路过时 Nana 正在喝茶，她朝你扬了扬杯子——像是在说\"有空来坐坐\"。")
    elseif nanaStage >= 5 then
        table.insert(snippets, "Nana 曾经的摊位前，那盆她养了十几年的仙人掌仍在安静生长。")
        table.insert(snippets, "一个老摊主指着角落的鲜花说：\"Nana 走了半个月了，我们每天还是会给她摆一束花。\"")
    end

    -- ── Ama 氛围 ──
    if amaStage == 1 then
        table.insert(snippets, "Ama 正戴着耳机敲代码，面前的键盘摊位无人问津——她全然不在意的样子。")
        table.insert(snippets, "你看到 Ama 的笔记本旁边摞了一小叠手写笔记，写着密密麻麻的算法。")
    elseif amaStage == 2 then
        table.insert(snippets, "Ama 在摊位上贴了张纸条：\"修电脑、装系统、做网站——找我！\" 字迹工整。")
        table.insert(snippets, "一个大学生模样的男生在和 Ama 讨论编程题，她讲得头头是道。")
    elseif amaStage == 3 then
        table.insert(snippets, "好几个摊主低头看手机——他们在用 Ama 做的集市APP查价格。")
        table.insert(snippets, "Ama 的摊位多了一块小白板，上面写着 APP 今日注册人数。")
    elseif amaStage == 4 then
        table.insert(snippets, "Ama 今天穿了件写着\"Hello World\"的T恤，正在视频电话里和什么人讨论技术方案。")
        table.insert(snippets, "经过 Ama 摊位时，她冲你比了个OK手势——看起来心情不错。")
    elseif amaStage >= 5 then
        table.insert(snippets, "Ama 的摊位交给了一个学妹打理，墙上贴着她 TED 演讲的截图海报。")
        table.insert(snippets, "一个女中学生对着 Ama 曾经的摊位自拍——旁边有人说\"就是那个上了TED的摊主\"。")
    end

    -- ── 组合氛围（如果认识多人，产生交叉描写）──
    if kwameStage >= 2 and nanaStage >= 2 then
        table.insert(snippets, "Kwame 路过 Nana 摊位时放下了一袋水果，Nana 笑着摆摆手说\"又乱花钱\"。")
        table.insert(snippets, "Nana 拉住路过的 Kwame 帮她修收音机，他嘟囔着\"我不是修这个的\"但还是蹲下了。")
    end
    if amaStage >= 2 and nanaStage >= 2 then
        table.insert(snippets, "Ama 在教 Nana 的孙子 Yaw 用电脑——Nana 在旁边假装不关心，但偷偷看了好几眼。")
        table.insert(snippets, "Yaw 兴奋地跑到 Nana 面前：\"奶奶！Ama 姐姐说我有编程天赋！\"")
    end
    if kwameStage >= 2 and amaStage >= 2 then
        table.insert(snippets, "Kwame 和 Ama 不知道在争论什么——好像是手机该选哪个品牌的问题。")
        table.insert(snippets, "Ama 帮 Kwame 给零件拍照上传到 APP——\"这样人家能在线问价了！\"")
    end
    if kwameStage >= 3 and nanaStage >= 3 and amaStage >= 3 then
        table.insert(snippets, "三个你认识的摊贩正凑在一起聊天——看到你来了，同时朝你打招呼。这个集市，越来越有家的感觉了。")
    end

    if #snippets == 0 then return nil end
    return snippets[math.random(1, #snippets)]
end

-- ============================================================================
-- Layer 2: 轻量级间歇事件 — 在大阶段之间触发小互动
-- ============================================================================
-- 设计：不需要选择面板，直接注入市场叙事作为额外文字段
-- 触发概率约35%，每次逛集市时检查

local INTERVAL_EVENTS = {
    -- ── Kwame 间歇 ──
    {
        vendorId = "kwame",
        afterStage = 1, -- 在S1完成后、S2之前
        texts = {
            "集市入口处，Kwame 远远朝你竖了个大拇指：\"老板！上次那个鼠标好用不？下次给你更好的！\" 你还没回话他就骑着摩托颠颠地跑了。",
            "角落里传来敲击声——Kwame 正蹲在地上拆一台旧笔记本。\"这玩意儿里面有块好内存条，\" 他头也不抬地说，\"等我拆出来给你留着。\"",
            "Kwame 在和隔壁摊主争论什么牌子的充电器最耐用。看见你走过来立刻停下：\"老板说句公道话！小米的好还是三星的好？\"",
        },
    },
    {
        vendorId = "kwame",
        afterStage = 2,
        texts = {
            "Kwame 把一小包东西塞到你手里：\"之前借的钱我先还一点——$30，剩下的下周！\" 他笑嘻嘻地拍了拍口袋：\"货到了，赚了不少！\"",
            "你注意到 Kwame 今天穿了件新T恤，上面印着\"TECH KING\"。\"好看吧？自己设计的！\" 他得意地转了个圈。",
            "Kwame 递给你一根冰棍：\"天太热了。老板辛苦——每天从网吧跑来跑去的。\" 他的语气比以前随意了些，像朋友之间的寒暄。",
        },
    },
    {
        vendorId = "kwame",
        afterStage = 3,
        texts = {
            "Kwame 今天面色严肃，在认真填写什么表格。看见你走过来苦笑了一下：\"办营业执照呢……原来正经做生意这么多手续。\"",
            "\"老板，你说我这个店名好不好——Dragon Tech？\" Kwame 在纸上写了好几个名字又划掉。\"要有气势！但又不能太嚣张……\"",
            "Kwame 正在刷墙——一面铁皮墙被他刷成了蓝色。\"我的新店！\" 他满手油漆，\"还差个招牌。你帮我看看字写得正不正？\"",
        },
    },
    {
        vendorId = "kwame",
        afterStage = 4,
        texts = {
            "Dragon Tech 门口贴着\"今日优惠\"的手写海报。Kwame 学着正规商店的样子，结果把\"优惠\"写成了\"优回\"——你决定不说破。",
            "一个客人从 Dragon Tech 出来时对你说：\"你朋友的店不错啊！修东西又快又便宜！\" Kwame 在里面偷听，笑得合不拢嘴。",
            "Kwame 递给你一张名片——印刷的那种！\"怎么样？正式吧！\" 上面写着 'Dragon Tech Repair - Quality Service Since 2024'。",
        },
    },

    -- ── Nana Esi 间歇 ──
    {
        vendorId = "nana",
        afterStage = 1,
        texts = {
            "经过 Nana 的摊位时，她正在给一个Adinkra符号上色。抬头看见你，点了点头——不说话，但那个微笑很温暖。",
            "Nana 今天在编织什么——一条彩色手绳。旁边的小女孩看得入迷：\"奶奶教我！\" \"先把功课做完。\"",
            "你路过时闻到一股草药香味——Nana 在熬什么东西。\"驱蚊的，\" 她解释道，\"每年这个时候蚊子最多。要不要一瓶？\"",
        },
    },
    {
        vendorId = "nana",
        afterStage = 2,
        texts = {
            "Yaw 在 Nana 摊位旁做作业，Nana 不时探头看一眼。\"这个不对，重算！\" Yaw 哀嚎一声。你经过时他可怜巴巴地看了你一眼。",
            "Nana 正和一个年轻妈妈聊天，帮她挑一个\"保佑孩子考试顺利\"的护符。她认真得像在开处方。",
            "\"你那个茶还有没有？\" Nana 问。\"上次那个绿茶，我喝了睡得特别好。\" 看来碧螺春的效果不错。",
        },
    },
    {
        vendorId = "nana",
        afterStage = 3,
        texts = {
            "集市翻修工程开始了——Nana 的摊位旁边围着施工围挡。她坐在折叠椅上，看工人干活：\"希望他们别把我的仙人掌挪走。\"",
            "一个记者在采访 Nana——\"您在这里摆了多少年摊了？\" \"四十年。从我丈夫还在的时候就开始了。\" 她的语气平静而骄傲。",
            "Nana 让你帮忙看看她的新位置图——翻修后摊位会稍微挪动。\"只要还在这棵树旁边就好。这棵树比我年纪还大。\"",
        },
    },
    {
        vendorId = "nana",
        afterStage = 4,
        texts = {
            "Nana 今天精神特别好，给每个路过的熟人都打了招呼。\"天气好的时候，\" 她对你说，\"活着就是赚到。\"",
            "你看到 Yaw 帮 Nana 整理摊位上的护符——动作笨拙但很认真。Nana 坐在一旁慈祥地看着，像在看一幅画。",
            "Nana 递给你一块她自己做的花生糖：\"尝尝。我年轻时候卖糖的，后来才改卖护符。\" 花生糖很甜，有种老派的幸福感。",
        },
    },

    -- ── Ama 间歇 ──
    {
        vendorId = "ama",
        afterStage = 1,
        texts = {
            "Ama 朝你举起一个U盘：\"老板！帮我从你网吧下载个VS Code安装包呗？学校的网太慢了！\" 你接过U盘——上面贴着一张\"fighting!\"的贴纸。",
            "Ama 正对着屏幕皱眉——看起来是在debug。你走过去瞥了一眼：一个IndexError。她注意到你看了，不好意思地笑笑。",
            "今天 Ama 的摊位前多了一块纸板招牌：\"收二手笔记本电脑——只要能开机的。\" 创业精神从一块纸板开始。",
        },
    },
    {
        vendorId = "ama",
        afterStage = 2,
        texts = {
            "Ama 兴奋地给你看手机屏幕——她的 GitHub 账号收到了第一颗星。\"有人给我的项目点星了！\" 虽然只有1颗，但她开心得像中了彩票。",
            "\"老板，Python 和 JavaScript 你觉得先学哪个好？\" Ama 举着两本书问你。不等你回答她自己说：\"算了两个都学！\"",
            "Ama 在摊位上支了个小白板，上面画着流程图。一个路过的中学生好奇地停下来看——\"这是什么？\" \"编程的逻辑，想学吗？\"",
        },
    },
    {
        vendorId = "ama",
        afterStage = 3,
        texts = {
            "Ama 的 APP 又更新了——她在摊位前贴了张\"V2.0 新功能\"的海报。集市摊主们开始叫她\"小工程师\"了。",
            "一个外国NGO的人在集市拍照，发现了 Ama 的APP后驻足很久——跟她交换了名片。Ama 事后激动地跟你说：\"他说可以帮我申请技术奖学金！\"",
            "Ama 教了三个女中学生写 HTML。\"这不是魔法，\" 她说，\"只是告诉电脑你想要什么。如果我能学会，你们也能。\"",
        },
    },
    {
        vendorId = "ama",
        afterStage = 4,
        texts = {
            "Ama 发来一张自拍——她穿着正装站在一栋写字楼前面。配文：\"第一天上班！感觉自己像个大人了 😂\"",
            "Ama 周末回来逛集市，一群人围着她问这问那。她已经不是那个安静敲代码的女孩了——自信从骨子里透出来。",
            "Ama 给你转了一篇文章：\"非洲科技创业者Top30\"——虽然她还没上榜，但她在评论区被人提名了。\"明年一定上！\" 她说。",
        },
    },
}

--- 尝试获取一个间歇事件文本（概率触发，非阻塞）
--- @return string|nil 间歇事件文字片段（nil=本次不触发）
function MarketStorylines.TryGetIntervalEvent()
    MarketStorylines.Init()

    -- 35% 基础触发概率
    if math.random(1, 100) > 35 then return nil end

    -- 收集当前可用的间歇事件
    local candidates = {}
    for _, ie in ipairs(INTERVAL_EVENTS) do
        local stage = marketStoryProgress_[ie.vendorId] or 0
        -- 条件：已完成afterStage但还没到下一个大阶段
        if stage == ie.afterStage then
            for _, t in ipairs(ie.texts) do
                table.insert(candidates, t)
            end
        end
    end

    if #candidates == 0 then return nil end
    return candidates[math.random(1, #candidates)]
end

-- ============================================================================
-- Layer 3: 跨线联动事件 — 多条故事线达到特定阶段时触发的特殊互动
-- ============================================================================
-- 设计：条件达成后以选择事件弹出（复用 currentEvent_ 系统）
-- 每个联动节点只触发一次

local CROSSLINE_EVENTS = {
    -- ── 联动1: Kwame S3 + Nana 已认识 → Nana提供律师人脉 ──
    {
        id = "cross_kwame_nana_lawyer",
        conditions = function()
            local kStage = marketStoryProgress_.kwame or 0
            local nStage = marketStoryProgress_.nana or 0
            return kStage >= 3 and nStage >= 2
        end,
        event = {
            id = "cross_kwame_nana_lawyer",
            title = "🔧🧿 老太太的人脉",
            desc = "你在集市碰到 Nana Esi，她叫住你：\"听说那个卖零件的小子出事了？\" 你点头。Nana 从围裙口袋里翻出一张皱巴巴的名片：\"我老伴当年的同学——现在是律师。找他，比外面便宜。\" 她顿了顿：\"那小子虽然毛躁，但心不坏。\"",
            type = "choice",
            choices = {
                { text = "🙏 \"谢谢 Nana，我转告 Kwame\"",
                  effect = function()
                      playerData_.karma = (playerData_.karma or 0) + 1
                      playerData_.reputation = (playerData_.reputation or 0) + 5
                  end,
                  result = function()
                      return "你把名片拍了照发给 Kwame。过了一会儿他回了一长串感恩的表情包，末尾写着：\"Nana 奶奶是天使！我出来一定给她送最好的收音机！\"\n\n集市里的人，正在慢慢成为一张网。\n\n【声望+5 / Kwame+Nana 关系链接 / 律师费更低】"
                  end },
            },
        },
    },

    -- ── 联动2: Ama S3 APP + Kwame 已认识 → Kwame第一个注册 ──
    {
        id = "cross_ama_kwame_app",
        conditions = function()
            local aStage = marketStoryProgress_.ama or 0
            local kStage = marketStoryProgress_.kwame or 0
            return aStage >= 3 and kStage >= 2
        end,
        event = {
            id = "cross_ama_kwame_app",
            title = "🖱️🔧 第一个注册用户",
            desc = "Ama 的集市 APP 上线第一天——你看到 Kwame 正拿着手机在 Ama 摊位前比划。\"这个怎么注册？要拍照片？拍哪里？\" Ama 耐心地教他一步步操作。最后 Kwame 的摊位成了 APP 上的第一条商家信息——配图是他笑得合不拢嘴的自拍。",
            type = "choice",
            choices = {
                { text = "📸 帮他们合个影",
                  effect = function()
                      playerData_.karma = (playerData_.karma or 0) + 1
                      playerData_.reputation = (playerData_.reputation or 0) + 5
                  end,
                  result = function()
                      return "你用手机给他们拍了张合照——Kwame 举着手机展示自己的商家页面，Ama 在旁边比V。\n\n\"发到APP首页当宣传图！\" Kwame说。\n\"你先把你那张自拍换掉吧……\" Ama翻了个白眼。\n\n这就是集市新旧交融的样子。\n\n【声望+5 / APP 知名度↑】"
                  end },
                { text = "👀 远远看着，不打扰",
                  effect = function()
                      playerData_.karma = (playerData_.karma or 0) + 1
                  end,
                  result = function()
                      return "你站在远处看着这一幕——从卖零件的街头小贩，到抱着笔记本编程的女大学生，这个集市因为你的出现，正在悄悄改变。\n\n不需要你做什么。你已经是催化剂了。\n\n【Kwame 成为 APP 种子用户 / 集市数字化进程+1】"
                  end },
            },
        },
    },

    -- ── 联动3: Nana S3 集市危机 + Ama 已认识 → Ama帮做宣传网站 ──
    {
        id = "cross_nana_ama_website",
        conditions = function()
            local nStage = marketStoryProgress_.nana or 0
            local aStage = marketStoryProgress_.ama or 0
            return nStage >= 3 and aStage >= 2
        end,
        event = {
            id = "cross_nana_ama_website",
            title = "🧿🖱️ 代码守护传统",
            desc = "保卫集市的抗议活动正在进行。Ama 主动找到你：\"老板，我能帮上忙！我可以做一个'拯救200年老集市'的网页——放历史照片、摊主故事、签名请愿！\" 她的眼睛亮亮的：\"Nana 奶奶教过我——年轻人要为社区做点什么。\"",
            type = "choice",
            choices = {
                { text = "💻 \"太好了！用我网吧的电脑和网络\"",
                  effect = function()
                      playerData_.reputation = (playerData_.reputation or 0) + 10
                      playerData_.karma = (playerData_.karma or 0) + 2
                  end,
                  result = function()
                      return "当晚 Ama 在你网吧熬夜做了个简洁漂亮的网页。Nana 提供了40年前集市的老照片——黑白的，但故事鲜活。\n\n第二天网页链接在 WhatsApp 群里疯转，本地新闻台都来采访了。\n\n\"看，\" Nana 对 Ama 说，\"你这个会电脑的本事，今天可比我的护符有用。\" Ama 笑着抱了抱老太太。\n\n【声望+10 / 传统与科技的融合 / 保卫集市运动加速】"
                  end },
                { text = "👍 \"你去做吧，需要什么说一声\"",
                  effect = function()
                      playerData_.karma = (playerData_.karma or 0) + 1
                      playerData_.reputation = (playerData_.reputation or 0) + 5
                  end,
                  result = function()
                      return "Ama 用自己的笔记本做了网页——简陋但信息完整。三天内收到了200多个电子签名。\n\n\"Nana 奶奶看了特别感动，\" Ama 后来跟你说。\"她说我是'集市的新守护者'。\"\n\n一老一少，用各自的方式守护同一个地方。\n\n【声望+5 / Nana+Ama 关系强化】"
                  end },
            },
        },
    },

    -- ── 联动4: 三线汇聚 — 全员进度≥4 → 集市周年聚会 ──
    {
        id = "cross_all_reunion",
        conditions = function()
            local kStage = marketStoryProgress_.kwame or 0
            local nStage = marketStoryProgress_.nana or 0
            local aStage = marketStoryProgress_.ama or 0
            return kStage >= 4 and nStage >= 4 and aStage >= 4
        end,
        event = {
            id = "cross_all_reunion",
            title = "🎉 集市的人们",
            desc = "今天不知道谁张罗的——集市中间摆了张长桌，上面铺着 kente 布，放着水果和饮料。Kwame 在烤肉，Ama 在放音乐，Nana 坐在正中间的位置上笑眯眯地看着所有人。\n\n\"来！中国老板！坐这里！\" 三个人同时朝你招手。原来今天是集市建成200周年纪念日——而你，不知不觉已经成了这里的一份子。",
            type = "choice",
            choices = {
                { text = "🍻 \"干杯！为了集市，为了我们！\"",
                  effect = function()
                      playerData_.karma = (playerData_.karma or 0) + 3
                      playerData_.reputation = (playerData_.reputation or 0) + 20
                      playerData_.havocCoins = (playerData_.havocCoins or 0) + 100
                      -- 全队心情加满
                      if teamMembers_ then
                          for _, m in ipairs(teamMembers_) do
                              m.mood = math.min(100, (m.mood or 50) + 20)
                          end
                      end
                  end,
                  result = function()
                      return "你举起一杯本地啤酒。Kwame 举着可乐（\"我开车来的！\"），Ama 举着橙汁，Nana 举着她的草药茶。\n\n\"Obroni老板！\" Kwame 大喊，\"你是第一个被邀请参加集市周年庆的外国人！\"\n\n\"不是外国人了，\" Nana 平静地说。\"是自家人。\"\n\n夕阳把所有人的影子拉得很长。你想——或许多年以后回忆非洲的日子，这一刻会是最亮的那个画面。\n\n【🪙+100 / 声望+20 / 全队心情+20 / 达成'集市家人'成就】"
                  end },
            },
        },
    },
}

--- 尝试触发跨线联动事件
--- @return table|nil event 联动事件（nil=无可触发）
function MarketStorylines.TryGetCrosslineEvent()
    MarketStorylines.Init()
    if not marketStoryCrossCompleted_ then
        marketStoryCrossCompleted_ = {}
    end

    for _, ce in ipairs(CROSSLINE_EVENTS) do
        if not marketStoryCrossCompleted_[ce.id] then
            local ok, condMet = pcall(ce.conditions)
            if ok and condMet then
                return ce.event
            end
        end
    end
    return nil
end

--- 标记跨线联动事件完成
function MarketStorylines.OnCrosslineCompleted(eventId)
    if not marketStoryCrossCompleted_ then
        marketStoryCrossCompleted_ = {}
    end
    marketStoryCrossCompleted_[eventId] = true
end

--- 判断是否是跨线联动事件
function MarketStorylines.IsCrosslineEvent(eventId)
    if not eventId then return false end
    for _, ce in ipairs(CROSSLINE_EVENTS) do
        if ce.id == eventId then return true end
    end
    return false
end

--- 获取摊贩的永久效果（用于集市折扣等）
function MarketStorylines.GetBonuses()
    MarketStorylines.Init()
    local bonuses = {
        pullDiscount = 0,     -- 抽卡折扣百分比
        moodDecay = 0,        -- 心情衰减减少
        dailyIncome = 0,      -- 每日额外收入
        equipRepair = 0,      -- 设备维修折扣
    }

    -- Kwame 合伙效果
    if playerData_.kwamePartner then
        bonuses.pullDiscount = bonuses.pullDiscount + 10
        bonuses.dailyIncome = bonuses.dailyIncome + 15
        bonuses.equipRepair = bonuses.equipRepair + 30
    elseif (marketStoryProgress_ and (marketStoryProgress_.kwame or 0) >= 4) then
        bonuses.pullDiscount = bonuses.pullDiscount + 5
    end

    -- Nana Esi 祝福效果
    if playerData_.nanaBless then
        bonuses.moodDecay = bonuses.moodDecay + 15
    end
    if playerData_.nanaLegacy then
        bonuses.moodDecay = bonuses.moodDecay + 20
        bonuses.pullDiscount = bonuses.pullDiscount + 5
    end

    -- Ama 技术支持效果
    if playerData_.amaMentor then
        bonuses.dailyIncome = bonuses.dailyIncome + 10
    end

    return bonuses
end

return MarketStorylines
