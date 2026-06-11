---@diagnostic disable: undefined-global
-- ============================================================================
-- NPCStorylines.lua — NPC支线剧情系统
-- 3个核心NPC的多阶段故事：Kofi / Grace / Snake
-- ============================================================================

local NPCStorylines = {}

-- ============================================================================
-- 剧情定义
-- ============================================================================

local STORYLINES = {
    -- ========================================
    -- Kofi：闪电单车少年（5阶段）
    -- ========================================
    kofi = {
        name = "Kofi 的故事",
        stages = {
            -- 阶段1：发现秘密（需要 Kofi 在队）
            {
                stage = 1,
                minDay = 5,
                interval = 0, -- 首次触发无间隔
                condition = function()
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Kofi" then return true end
                    end
                    return false
                end,
                event = {
                    id = "kofi_s1_secret", category = "social", rarity = "uncommon",
                    title = "🚲 Kofi 的秘密",
                    desc = "训练结束后，你发现 Kofi 没有走，而是蹲在门口偷偷数零钱。他看到你慌忙把钱塞进口袋。\"没、没什么老板！我这就走！\"你注意到他的自行车链条断了，是用铁丝绑着的。",
                    type = "choice",
                    choices = {
                        { text = "🔧 帮他修好自行车，再给他100块路费",
                          effect = function()
                              playerData_.money = playerData_.money - 100
                              playerData_.karma = playerData_.karma + 2
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then m.mood = math.min(100, m.mood + 20) end
                              end
                          end,
                          result = function() return "Kofi 愣住了，眼眶红了。\"老板......我妈生病了，我每天跑刀赚的钱都寄回去买药。\"他深深鞠了一躬。\"我一定会拼命训练的！\"\n\nKofi 好感度大幅提升！" end },
                        { text = "🤔 关心问了几句，但没给钱",
                          effect = function()
                              playerData_.karma = playerData_.karma + 1
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then m.mood = math.min(100, m.mood + 5) end
                              end
                          end,
                          result = function() return "Kofi 勉强笑了笑。\"没事的老板，我能应付。\"他推着断链的自行车消失在夜色里。你看着他的背影，有些说不出的滋味。" end },
                    },
                },
            },
            -- 阶段2：成长（Kofi 在队 + 心情 > 60）
            {
                stage = 2,
                minDay = 10,
                interval = 4,
                condition = function()
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Kofi" and m.mood > 60 then return true end
                    end
                    return false
                end,
                event = {
                    id = "kofi_s2_growth", category = "social", rarity = "uncommon",
                    title = "🌟 Kofi 的蜕变",
                    desc = "Kofi 最近进步神速。今天训练，他的操作让所有队友都惊呆了——完美的身法，精准的爆头。\"我每天晚上回家还在脑子里过战术\"他害羞地说。但他妈妈的病似乎更重了......",
                    type = "choice",
                    choices = {
                        { text = "💰 给他加薪50%，让他安心训练",
                          effect = function()
                              playerData_.karma = playerData_.karma + 2
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then
                                      m.fee = math.floor(m.fee * 1.5)
                                      m.mood = 100
                                      m.skill = m.skill + 5
                                  end
                              end
                          end,
                          result = function() return "Kofi 激动得说不出话。\"老板......我不会让你失望的！\"他的训练更加刻苦了，技术突飞猛进！\n\nKofi 技能+5！" end },
                        { text = "🤝 保持现状，告诉他可以预支工资",
                          effect = function()
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then m.mood = math.min(100, m.mood + 10) end
                              end
                          end,
                          result = function() return "Kofi 点点头。\"谢谢老板，有你在真好。\"他虽然心里有压力，但训练从未落下过。" end },
                    },
                },
            },
            -- 阶段3：家庭危机
            {
                stage = 3,
                minDay = 18,
                interval = 5,
                condition = function()
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Kofi" then return true end
                    end
                    return false
                end,
                event = {
                    id = "kofi_s3_crisis", category = "social", rarity = "rare",
                    title = "😰 Kofi 的抉择",
                    desc = "Kofi 红着眼睛来找你。\"老板，我妈要做手术......医生说要 $800。我想了很久......可能要暂时离开战队，去首都打工赚钱。\"他的声音在发抖。",
                    type = "choice",
                    choices = {
                        { text = "💰 借给他 $800，不用还",
                          effect = function()
                              playerData_.money = playerData_.money - 800
                              playerData_.karma = playerData_.karma + 5
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then
                                      m.mood = 100
                                      m.skill = m.skill + 8
                                      m.talent = math.min(100, m.talent + 5)
                                  end
                              end
                          end,
                          result = function() return "Kofi 跪了下来，泪流满面。\"老板......我这辈子都跟定你了！\"手术很成功，他妈妈恢复得很好。Kofi 训练起来像换了一个人——他在为恩人而战。\n\nKofi 技能+8，天赋+5！他变得无比忠诚！" end },
                        { text = "💵 借给他 $400，剩下的帮他筹款",
                          effect = function()
                              playerData_.money = playerData_.money - 400
                              playerData_.karma = playerData_.karma + 3
                              playerData_.reputation = playerData_.reputation + 10
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then
                                      m.mood = 95
                                      m.skill = m.skill + 3
                                  end
                              end
                          end,
                          result = function() return "你在网吧举办了一场慈善跑刀赛，收入全部给 Kofi 的妈妈。整个小镇都被感动了！声望大涨！\n\nKofi 技能+3，声望+10！" end },
                        { text = "😔 告诉他你也没钱，但会帮他想办法",
                          effect = function()
                              playerData_.karma = playerData_.karma + 1
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then m.mood = math.max(30, m.mood - 20) end
                              end
                          end,
                          result = function() return "Kofi 沉默了很久。\"我理解，老板。\"他请了一周假，去首都找了份临时工。虽然回来了，但你能看出他的眼里少了些什么。" end },
                    },
                },
            },
            -- 阶段4：高光时刻
            {
                stage = 4,
                minDay = 25,
                interval = 5,
                condition = function()
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Kofi" and m.skill >= 20 then return true end
                    end
                    return false
                end,
                event = {
                    id = "kofi_s4_highlight", category = "social", rarity = "rare",
                    title = "🏆 Kofi 的高光时刻",
                    desc = "一支职业战队的星探看上了 Kofi。\"你的队员天赋惊人。我们可以给他月薪 $500 的合同——是你给他工资的5倍。\"Kofi 站在你身后，一言不发地看着你。",
                    type = "choice",
                    choices = {
                        { text = "🤝 放他去追梦，这是更好的舞台",
                          effect = function()
                              playerData_.karma = playerData_.karma + 5
                              playerData_.reputation = playerData_.reputation + 30
                              playerData_.money = playerData_.money + 500
                              -- 移除 Kofi
                              for i, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then table.remove(teamMembers_, i); break end
                              end
                          end,
                          result = function() return "Kofi 抱住了你。\"老板，没有你就没有今天的我。\"职业队给了你 $500 转会费。Kofi 走了，但他在采访里说：'我的一切，都是 Dragon Net Cafe 教我的。'\n\n声望+30！你培养出了非洲电竞的新星！" end },
                        { text = "💪 留住他，我们一起冲击冠军",
                          effect = function()
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then
                                      m.mood = 100
                                      m.skill = m.skill + 5
                                  end
                              end
                              playerData_.reputation = playerData_.reputation + 10
                          end,
                          result = function() return "Kofi 笑了。\"我哪也不去。Dragon Force 就是我的家。\"星探摇摇头走了。Kofi 训练更加卖力——他要在这里证明一切。\n\nKofi 技能+5！" end },
                    },
                },
            },
            -- 阶段5：结局
            {
                stage = 5,
                minDay = 35,
                interval = 7,
                condition = function()
                    -- Kofi 仍在队中
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Kofi" then return true end
                    end
                    return false
                end,
                event = {
                    id = "kofi_s5_ending", category = "social", rarity = "epic",
                    title = "🌅 Kofi 的来信",
                    desc = "Kofi 的妈妈亲自来到网吧，手里拿着一篮子水果和一封手写信。\"感谢你照顾我的孩子。他现在每天都很开心，这是我最大的心愿。\"Kofi 在一旁红着脸。信上歪歪扭扭地写着：'献给最好的老板'。",
                    type = "choice",
                    choices = {
                        { text = "😊 收下礼物，请她留下来吃顿饭",
                          effect = function()
                              playerData_.karma = playerData_.karma + 3
                              playerData_.reputation = playerData_.reputation + 15
                              for _, m in ipairs(teamMembers_) do
                                  if m.name == "Kofi" then m.mood = 100 end
                              end
                          end,
                          result = function() return "那天晚上，整个网吧变成了一个大家庭。Mama B 烤了最好的鸡，队员们围在一起听 Kofi 妈妈讲他小时候的糗事。Kofi 虽然害羞得不行，但笑得最开心。\n\n这就是非洲——距离再远，家人的爱永远不会缺席。\n\n🎉 Kofi 支线完结！" end },
                    },
                },
            },
        },
    },

    -- ========================================
    -- Grace：牧师之女·暗夜玫瑰（4阶段）
    -- ========================================
    grace = {
        name = "Grace 的故事",
        stages = {
            -- 阶段1：合作提议
            {
                stage = 1,
                minDay = 7,
                interval = 0,
                condition = function()
                    return playerData_.reputation >= 30
                end,
                event = {
                    id = "grace_s1_proposal", category = "business", rarity = "uncommon",
                    title = "🌹 牧师之女的提议",
                    desc = "Grace 来了。她不只是来打游戏的。\"老板，我有个商业计划。教堂的青年团有 50 多个年轻人，如果我们合作办电竞培训班，每人每月收 $20 学费......你算算。\"",
                    type = "choice",
                    choices = {
                        { text = "🤝 合作！利润五五分",
                          effect = function()
                              playerData_.money = playerData_.money + 200
                              playerData_.reputation = playerData_.reputation + 15
                              playerData_.karma = playerData_.karma + 1
                          end,
                          result = function() return "培训班第一期就有 20 人报名！Grace 负责招生和教学，你提供场地和设备。教堂的年轻人终于有了正经事做。\n\n+$200 首期学费！声望+15！" end },
                        { text = "💰 同意，但利润七三分（你七她三）",
                          effect = function()
                              playerData_.money = playerData_.money + 280
                              playerData_.karma = playerData_.karma - 1
                          end,
                          result = function() return "Grace 皱了皱眉，但还是同意了。\"好吧，毕竟场地是你的。\"培训班开起来了，但你能感觉到她不太高兴。\n\n+$280！" end },
                    },
                },
            },
            -- 阶段2：投资机会
            {
                stage = 2,
                minDay = 14,
                interval = 5,
                condition = function()
                    return playerData_.reputation >= 60
                end,
                event = {
                    id = "grace_s2_investment", category = "business", rarity = "rare",
                    title = "💼 Grace 的投资计划",
                    desc = "Grace 兴奋地找到你。\"教堂收到一笔国际捐款，可以购买 10 台新电脑！但有个条件——必须用于青年培训计划，而不是网吧商用。我们如果把培训班做大，每月能赚 $800！但初期需要你出 $500 买教材和桌椅。\"",
                    type = "choice",
                    choices = {
                        { text = "💰 投资 $500，做大培训班",
                          effect = function()
                              playerData_.money = playerData_.money - 500
                              playerData_.reputation = playerData_.reputation + 20
                              playerData_.karma = playerData_.karma + 2
                          end,
                          result = function() return "新教室布置好了，10台崭新的电脑！Grace 在教堂做了演讲，整个镇子的年轻人都知道了。\"老板，我们在做一件伟大的事。\"\n\n声望+20！投资将在未来获得持续回报。" end },
                        { text = "🤔 这个风险太大了，我再考虑考虑",
                          effect = function() end,
                          result = function() return "Grace 有些失望。\"好吧，如果你改变主意......\"她转身走了。教堂的捐款最终用在了别的地方。" end },
                    },
                },
            },
            -- 阶段3：危机
            {
                stage = 3,
                minDay = 22,
                interval = 6,
                condition = function()
                    return playerData_.reputation >= 80
                end,
                event = {
                    id = "grace_s3_crisis", category = "social", rarity = "rare",
                    title = "⛪ Grace 的秘密暴露了",
                    desc = "Grace 的父亲——牧师大人亲自来到网吧。\"我女儿告诉我她在做'青年社区服务'。我现在知道了，她在教年轻人打游戏。\"他的脸色很难看。\"我要求她立刻停止这一切。\"Grace 站在父亲身后，低着头不说话。",
                    type = "choice",
                    choices = {
                        { text = "🤝 向牧师解释电竞培训的价值和社会意义",
                          effect = function()
                              playerData_.reputation = playerData_.reputation + 25
                              playerData_.karma = playerData_.karma + 3
                          end,
                          result = function() return "你拿出学员们的成绩、就业记录和社区反馈。牧师的表情慢慢从愤怒变成了惊讶。\"这些孩子......真的因为你们改变了？\"最终，他不仅同意了，还表示教堂可以提供更多支持。Grace 感激地看着你，眼里闪着泪光。\n\n声望+25！教堂成为你的坚实后盾！" end },
                        { text = "😶 让 Grace 自己和父亲解释",
                          effect = function()
                              playerData_.karma = playerData_.karma - 1
                          end,
                          result = function() return "Grace 试图解释，但牧师还是很生气地带她走了。培训班暂停了两周。Grace 后来偷偷发消息：\"别担心，我会说服他的。只是需要时间。\"" end },
                    },
                },
            },
            -- 阶段4：结局
            {
                stage = 4,
                minDay = 30,
                interval = 7,
                condition = function()
                    return playerData_.reputation >= 120
                end,
                event = {
                    id = "grace_s4_ending", category = "social", rarity = "epic",
                    title = "🌟 Grace 的毕业典礼",
                    desc = "培训班的第一批学员毕业了！Grace 在毕业典礼上发言：\"六个月前，这些孩子在街头无所事事。现在他们有了目标、有了技能、有了希望。\"台下，牧师站起来鼓掌，眼眶泛红。她转向你：\"老板，谢谢你相信我。\"",
                    type = "choice",
                    choices = {
                        { text = "👏 上台发言，分享创业故事",
                          effect = function()
                              playerData_.reputation = playerData_.reputation + 40
                              playerData_.money = playerData_.money + 500
                              playerData_.karma = playerData_.karma + 3
                          end,
                          result = function() return "你的演讲让全场沸腾。\"从三台电脑到改变一个社区——如果我能做到，你们也能！\"毕业典礼上，三家媒体来采访，两个 NGO 表示愿意合作。Grace 的父亲走过来握住你的手：\"年轻人，上帝会保佑你的。\"\n\n声望+40！+$500 赞助金！\n\n🎉 Grace 支线完结！你们一起改变了一个社区。" end },
                    },
                },
            },
        },
    },

    -- ========================================
    -- Snake：街头之王·毒蛇（4阶段）
    -- ========================================
    snake = {
        name = "Snake 的故事",
        stages = {
            -- 阶段1：诱惑
            {
                stage = 1,
                minDay = 8,
                interval = 0,
                condition = function()
                    return playerData_.day >= 8
                end,
                event = {
                    id = "snake_s1_temptation", category = "business", rarity = "uncommon",
                    title = "🐍 Snake 的提议",
                    desc = "深夜，一个留着脏辫的年轻人走进网吧。\"老板，我是 Snake。听说你这里组了战队？\"他压低声音：\"我知道一个来钱快的路子——地下赌盘。我的人脉，你的场地。每场抽成 $200 起步。\"",
                    type = "choice",
                    choices = {
                        { text = "💰 有兴趣，先试试看",
                          effect = function()
                              playerData_.money = playerData_.money + 300
                              playerData_.karma = playerData_.karma - 3
                          end,
                          result = function() return "Snake 嘴角一弯。\"够意思。\"当晚就来了一帮人，赌金从 $20 涨到 $200。你抽成拿了 $300，但总觉得心里不踏实。\n\n+$300！但 karma 下降了......" end },
                        { text = "✋ 不行，赌博太危险了",
                          effect = function()
                              playerData_.karma = playerData_.karma + 2
                              playerData_.reputation = playerData_.reputation + 5
                          end,
                          result = function() return "Snake 耸耸肩。\"你会后悔的。\"他转身消失在夜色里。你松了口气——合法经营才是正道。\n\nkarma+2，声望+5" end },
                    },
                },
            },
            -- 阶段2：灰色交易
            {
                stage = 2,
                minDay = 15,
                interval = 5,
                condition = function()
                    return playerData_.day >= 15
                end,
                event = {
                    id = "snake_s2_deal", category = "business", rarity = "rare",
                    title = "�� Snake 的大买卖",
                    desc = "Snake 又来了，这次带着一个手提箱。\"老板，我搞到一批'特殊渠道'的显卡——市场价 $5000 的货，我只要 $1500。你买了装网吧，一个月就回本。\"他打开箱子，里面是崭新的 RTX 4060。",
                    type = "choice",
                    choices = {
                        { text = "💰 买！这太划算了",
                          effect = function()
                              playerData_.money = playerData_.money - 1500
                              playerData_.computers = playerData_.computers + 2
                              playerData_.karma = playerData_.karma - 4
                          end,
                          result = function() return "显卡装上了，性能确实强劲。但你忍不住想——这些卡到底从哪来的？Snake 笑着说别多问。\n\n+2台电脑！但 karma 大幅下降......" end },
                        { text = "🤔 太便宜了，这不正常",
                          effect = function()
                              playerData_.karma = playerData_.karma + 2
                          end,
                          result = function() return "\"你确定？\"Snake 有些不高兴。\"那我找别家了。\"他拎着箱子走了。两天后你听说隔壁城市的网吧因为使用来路不明的硬件被查封了......好险。\n\nkarma+2" end },
                    },
                },
            },
            -- 阶段3：被发现
            {
                stage = 3,
                minDay = 22,
                interval = 5,
                condition = function()
                    return playerData_.day >= 22
                end,
                event = {
                    id = "snake_s3_exposed", category = "social", rarity = "rare",
                    title = "🚨 警察来了",
                    desc = "两个便衣警察走进网吧。\"我们在调查一起走私案。有人举报你与嫌疑人 Snake 有来往。\"你的心跳加速了。他们在检查你的设备序列号。",
                    type = "choice",
                    choices = {
                        { text = "🤝 全力配合调查，提供 Snake 的信息",
                          effect = function()
                              playerData_.karma = playerData_.karma + 5
                              playerData_.reputation = playerData_.reputation + 10
                          end,
                          result = function() return "你把 Snake 的联系方式和交易记录交给了警察。他们感谢你的配合。\"你是个正经生意人。\"声誉保住了。Snake 可能不会再来了——也好。\n\nkarma+5，声望+10" end },
                        { text = "🤐 什么都不说，只说不认识他",
                          effect = function()
                              playerData_.karma = playerData_.karma - 2
                          end,
                          result = function() return "警察将信将疑地走了。\"我们会继续调查的。\"你擦了一把冷汗。以后得离 Snake 远一点了。" end },
                    },
                },
            },
            -- 阶段4：结局
            {
                stage = 4,
                minDay = 28,
                interval = 5,
                condition = function()
                    return playerData_.day >= 28
                end,
                event = {
                    id = "snake_s4_ending", category = "social", rarity = "epic",
                    title = "🐍 Snake 的最终抉择",
                    desc = "深夜，Snake 独自坐在网吧角落。他没有了往日的嚣张，看起来很疲惫。\"老板，警察在追我。我......我不想再跑了。\"他看着你的眼神和以前完全不同——那是一个迷途少年的眼神。\"你能帮我吗？\"",
                    type = "choice",
                    choices = {
                        { text = "🤝 帮他联系律师，让他自首",
                          effect = function()
                              playerData_.money = playerData_.money - 200
                              playerData_.karma = playerData_.karma + 5
                              playerData_.reputation = playerData_.reputation + 20
                          end,
                          result = function() return "你花了 $200 帮 Snake 请了律师，陪他去自首。在法庭上，他说：'Dragon Net Cafe 的老板是唯一一个没把我当坏人的人。'\n\nSnake 被判社区服务而非入狱。半年后，他回来了——这次是来应聘网管的。\n\n-$200，karma+5，声望+20\n\n🎉 Snake 支线完结！浪子回头。" end },
                        { text = "💰 给他一笔钱，让他跑路",
                          effect = function()
                              playerData_.money = playerData_.money - 500
                              playerData_.karma = playerData_.karma - 2
                          end,
                          result = function() return "你塞给他 $500。\"拿着，别回来了。\"Snake 沉默了很久，最后说了句\"谢谢\"就消失在夜色中。你再也没见过他。\n\n有时候你会想——他过得还好吗？\n\n-$500\n\n🎉 Snake 支线完结。" end },
                        { text = "✋ 这不关我的事，你自己想办法",
                          effect = function()
                              playerData_.karma = playerData_.karma - 1
                          end,
                          result = function() return "Snake 站起来，对你笑了一下。\"我知道了。\"他走了。一周后你在新闻里看到他被逮捕了。你关掉了手机。\n\n🎉 Snake 支线完结。" end },
                    },
                },
            },
        },
    },
}

-- ============================================================================
-- 剧情推进逻辑
-- ============================================================================

--- 尝试推进NPC剧情，返回可触发的事件
---@param day number 当前天数
---@return table|nil 可触发的事件或nil
function NPCStorylines.TryAdvance(day)
    for npcId, storyline in pairs(STORYLINES) do
        local currentStage = (playerData_.npcStoryProgress or {})[npcId] or 0
        local nextStage = currentStage + 1
        for _, stage in ipairs(storyline.stages) do
            if stage.stage == nextStage then
                -- 检查触发条件
                if day >= stage.minDay and stage.condition() then
                    -- 检查间隔
                    local lastDay = 0
                    if npcJournal_[npcId] and npcJournal_[npcId].events then
                        local events = npcJournal_[npcId].events
                        if #events > 0 then lastDay = events[#events].day or 0 end
                    end
                    if stage.interval <= 0 or (day - lastDay) >= stage.interval then
                        return stage.event
                    end
                end
            end
        end
    end
    return nil
end

--- 标记NPC剧情推进（在事件完成后调用）
---@param eventId string 事件ID
function NPCStorylines.OnEventCompleted(eventId)
    for npcId, storyline in pairs(STORYLINES) do
        for _, stage in ipairs(storyline.stages) do
            if stage.event.id == eventId then
                if not playerData_.npcStoryProgress then playerData_.npcStoryProgress = {} end
                playerData_.npcStoryProgress[npcId] = stage.stage
                return
            end
        end
    end
end

--- 检查某个NPC当前是否有可触发的剧情阶段（供UI主动"聊一聊"按钮使用）
---@param npcId string
---@return boolean
function NPCStorylines.CanAdvanceNpc(npcId)
    local storyline = STORYLINES[npcId]
    if not storyline then return false end
    local day = playerData_.day or 1
    local currentStage = (playerData_.npcStoryProgress or {})[npcId] or 0
    local nextStage = currentStage + 1
    for _, stage in ipairs(storyline.stages) do
        if stage.stage == nextStage then
            if day >= stage.minDay and stage.condition() then
                local lastDay = 0
                if npcJournal_[npcId] and npcJournal_[npcId].events then
                    local events = npcJournal_[npcId].events
                    if #events > 0 then lastDay = events[#events].day or 0 end
                end
                if stage.interval <= 0 or (day - lastDay) >= stage.interval then
                    return true
                end
            end
        end
    end
    return false
end

--- 尝试推进指定NPC的剧情，返回可触发的事件（供"聊一聊"按钮使用）
---@param npcId string
---@return table|nil
function NPCStorylines.TryAdvanceNpc(npcId)
    local storyline = STORYLINES[npcId]
    if not storyline then return nil end
    local day = playerData_.day or 1
    local currentStage = (playerData_.npcStoryProgress or {})[npcId] or 0
    local nextStage = currentStage + 1
    for _, stage in ipairs(storyline.stages) do
        if stage.stage == nextStage then
            if day >= stage.minDay and stage.condition() then
                local lastDay = 0
                if npcJournal_[npcId] and npcJournal_[npcId].events then
                    local events = npcJournal_[npcId].events
                    if #events > 0 then lastDay = events[#events].day or 0 end
                end
                if stage.interval <= 0 or (day - lastDay) >= stage.interval then
                    return stage.event
                end
            end
        end
    end
    return nil
end

--- 获取NPC剧情预告（用于明日预告）
---@param nextDay number
---@return string|nil
function NPCStorylines.GetPreview(nextDay)
    for npcId, storyline in pairs(STORYLINES) do
        local currentStage = (playerData_.npcStoryProgress or {})[npcId] or 0
        local nextStage = currentStage + 1
        for _, stage in ipairs(storyline.stages) do
            if stage.stage == nextStage and nextDay >= stage.minDay then
                if npcId == "kofi" then return "🚲 Kofi 似乎有心事......"
                elseif npcId == "grace" then return "🌹 Grace 最近很活跃......"
                elseif npcId == "snake" then return "🐍 深夜可能有不速之客......"
                end
            end
        end
    end
    return nil
end

--- 检查某个事件是否是NPC剧情事件
---@param eventId string
---@return boolean
function NPCStorylines.IsStorylineEvent(eventId)
    for _, storyline in pairs(STORYLINES) do
        for _, stage in ipairs(storyline.stages) do
            if stage.event.id == eventId then return true end
        end
    end
    return false
end

return NPCStorylines
