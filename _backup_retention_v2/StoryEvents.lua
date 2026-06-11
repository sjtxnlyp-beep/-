---@diagnostic disable: undefined-global
-- ============================================================================
-- 6.5 剧情事件引擎（条件触发，只触发一次）
-- ============================================================================
storyTriggered_ = {}  -- 已触发的剧情事件id集合

--- 检查某成员是否已被招募
function HasMember(name)
    for _, m in ipairs(teamMembers_) do if m.name == name then return true end end
    return false
end

--- 剧情事件列表：按条件在经营中自动触发，每个只触发一次
STORY_EVENTS = {
    -- ===== 第一幕：扎根（前 5 天） =====
    { id = "mama_chicken",
      cond = function() return playerData_.day >= 2 end,
      type = "dialogue",
      title = "门口的烤鸡香",
      dialogues = {
          { speaker = "旁白", text = "网吧门口，一个扛着炭火炉的大婶正在烤鸡。油脂滴在炭火上，发出嗞嗞的声响，香味飘了半条街。" },
          { speaker = "Mama B", text = "嘿，中国老板！生意不好？我在你门口卖烤鸡，你给我借点电，怎么样？" },
          { speaker = "你", text = "成交！正好我这也没几个客人……" },
          { speaker = "旁白", text = "于是，Dragon Net Cafe 门口多了一个烤鸡摊。意外的是，来买烤鸡的人顺便进来上了网。" },
          { speaker = "旁白", text = "【客流量小幅增加。Mama Blessing 成为你的第一个本地朋友。】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 10; playerData_.money = playerData_.money + 30 end,
    },
    { id = "first_customer_delta",
      cond = function() return playerData_.day >= 3 end,
      type = "dialogue",
      title = "第一个三角洲玩家",
      dialogues = {
          { speaker = "旁白", text = "下午三点，一个穿拖鞋的少年走进网吧，怯生生地问——" },
          { speaker = "少年", text = "老板……我听说你这能打那个游戏？就是那个……可以赚钱的？" },
          { speaker = "你", text = "三角洲行动？可以啊！来，我教你。" },
          { speaker = "旁白", text = "你手把手教他创建角色、学会基本操作。他的眼睛越来越亮。" },
          { speaker = "少年", text = "这个……如果我打得好，真的可以赚到钱吗？" },
          { speaker = "你", text = "当然。跑刀成功撤离，每次都能赚哈弗币。哈弗币可以换真钱。" },
          { speaker = "少年", text = "（眼睛放光）我明天还来！我要带我朋友一起来！" },
          { speaker = "旁白", text = "这是你在非洲种下的第一颗种子。\n\n【'跑刀'的消息开始在年轻人中传播。】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 8 end,
    },

    -- ===== 第二幕：跑刀经济学（5-10 天） =====
    { id = "havoc_economy",
      cond = function() return playerData_.day >= 6 and playerData_.havocCoins >= 30 end,
      type = "dialogue",
      title = "哈弗币经济学",
      dialogues = {
          { speaker = "旁白", text = "网吧上座率越来越高。你发现了一个有趣的现象——" },
          { speaker = "旁白", text = "常客们开始用哈弗币互相交易。有人跑刀赚了币，就在网吧里卖给想买装备的人。" },
          { speaker = "常客A", text = "老板，我跑了一把赚了200哈弗币！你能帮我换成美金吗？" },
          { speaker = "你", text = "呃……我试试联系一下。" },
          { speaker = "旁白", text = "你摸索出了一条路子：把哈弗币卖给国内的玩家。一来一回，竟然还有不错的利润。" },
          { speaker = "你", text = "等等……这不就是'纯黑跑刀'的商业模式吗？非洲这边人力成本低，跑刀效率高……这是一条产业链啊！" },
          { speaker = "旁白", text = "【你解锁了跑刀代练商业模式。哈弗币不再只是游戏货币，它是真金白银。】" },
      },
      effect = function() playerData_.money = playerData_.money + 50; playerData_.havocCoins = playerData_.havocCoins + 30 end,
    },
    { id = "kofi_backstory",
      cond = function() return HasMember("Kofi") and playerData_.day >= 7 end,
      type = "dialogue",
      title = "Kofi的秘密",
      dialogues = {
          { speaker = "旁白", text = "凌晨六点，你起床去开门，发现Kofi已经坐在门口了。他的自行车链条断了，是推着车走来的。" },
          { speaker = "你", text = "Kofi？这么早？你走了多远？" },
          { speaker = "Kofi", text = "（低头）十二公里。链条昨天就断了……但我不想缺席训练。" },
          { speaker = "你", text = "……" },
          { speaker = "Kofi", text = "老板，我能跟你说件事吗？我妈妈以为我每天去矿场打工。她不知道我来打游戏。" },
          { speaker = "Kofi", text = "但是……上个月我偷偷把跑刀赚的哈弗币换成钱寄回家了。比矿场赚得多。" },
          { speaker = "Kofi", text = "如果我能打进职业联赛……我就能把妈妈接到城里来。她就不用再种地了。" },
          { speaker = "你", text = "（拍他肩膀）走，进去练。你的梦想，我帮你扛。" },
          { speaker = "旁白", text = "你默默决定——给Kofi配一辆新自行车。\n\n【Kofi 技术+5，心情+20。你与队员的关系更近了。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Kofi" then m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = math.min(100, m.mood + 20) end
          end
          playerData_.money = playerData_.money - 30
      end,
    },

    -- ===== 第三幕：团队成型（队员>=2） =====
    { id = "first_team_meal",
      cond = function() return #teamMembers_ >= 2 end,
      type = "dialogue",
      title = "第一顿团队聚餐",
      dialogues = {
          { speaker = "旁白", text = "今天是Dragon Force战队正式成立的日子。你决定请大家吃顿好的。" },
          { speaker = "你", text = "兄弟们！今晚Mama B的烤鸡管够！庆祝Dragon Force成立！" },
          { speaker = "旁白", text = "队员们围坐在网吧外面的空地上，月光下啃着烤鸡，喝着橙色芬达。" },
          { speaker = teamMembers_[1] and teamMembers_[1].name or "队员", text = "老板，你为什么不在中国待着？来这里不苦吗？" },
          { speaker = "你", text = "苦？在哪都苦。但在这里苦得有意思。" },
          { speaker = "旁白", text = "有人打开手机放起了非洲鼓的节拍。" },
          { speaker = "旁白", text = "远处传来夜鸟的叫声。头顶的银河比你在国内见过的任何一次都清晰。" },
          { speaker = "你", text = "（心想）这帮小子……值得。" },
          { speaker = "旁白", text = "【全队心情+15。这是Dragon Force的起点。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 15) end
          playerData_.money = playerData_.money - 40
      end,
    },
    { id = "snake_conflict",
      cond = function() return HasMember("Snake") and playerData_.day >= 8 end,
      type = "choice",
      title = "Snake的考验",
      icon = "🐍",
      desc = "训练赛上，Snake和队友发生激烈冲突。他摔了鼠标，站起来指着对面骂——'你这个垃圾！连个跑刀都不会！'\n\n整个网吧安静了。所有人都在看你怎么处理。",
      choices = {
          { text = "💪 严厉训话：这里是战队，不是街头", result = "你把Snake叫到门外，认真谈了半小时。\n\nSnake沉默了很久，最后说：'我错了。在街上谁不服就打。但你说得对，这里不一样。'\n\n他走回去，默默捡起鼠标继续训练。\n\n【Snake 技术+5，但心情-10。他开始学会控制自己。】",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Snake" then m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = math.max(0, m.mood - 10) end
                end
                playerData_.reputation = playerData_.reputation + 10
                playerData_.karma = playerData_.karma - 1  -- 严厉但有效
            end },
          { text = "🤝 私下谈心：理解他的过去", result = "你等人都走了，跟Snake坐下来聊。他说起在街上混的日子，打架、挨打、被人看不起。\n\n'游戏是我唯一不用靠拳头的地方。但我不会别的方式。'\n\n你说：'从现在起，你用枪法说话。'\n\n【Snake 心情+10，全队凝聚力提升。声望+15】",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Snake" then m.mood = math.min(100, m.mood + 10) end
                    m.mood = math.min(100, m.mood + 5)
                end
                playerData_.reputation = playerData_.reputation + 15
                playerData_.karma = playerData_.karma + 2  -- 以心换心
            end },
      },
    },
    { id = "grace_secret",
      cond = function() return HasMember("Grace") and playerData_.day >= 10 end,
      type = "dialogue",
      title = "Grace的秘密被发现了",
      dialogues = {
          { speaker = "旁白", text = "周日下午，一个穿着牧师袍的男人走进了网吧。网吧瞬间安静了。" },
          { speaker = "Grace的父亲", text = "Grace！你……你在这里做什么？！" },
          { speaker = "Grace", text = "爸爸！我……我可以解释的……" },
          { speaker = "Grace的父亲", text = "（转向你）你就是那个中国人？你在教我女儿打暴力游戏？！" },
          { speaker = "你", text = "牧师先生，请先听我说。Grace在我这里不是在浪费时间——她在学习团队合作、反应力和战术思维。" },
          { speaker = "你", text = "而且……她有机会代表整个非洲参加国际电竞比赛。这是一份正经的事业。" },
          { speaker = "Grace的父亲", text = "……" },
          { speaker = "Grace", text = "爸爸，上帝给了我一双稳定的手和精准的眼睛。这就是我的天赋。我不想浪费它。" },
          { speaker = "Grace的父亲", text = "（长叹）我需要时间考虑。但是Grace——你不能再瞒着我了。" },
          { speaker = "旁白", text = "牧师离开了。Grace的眼眶红了，但她很快擦干眼泪坐回电脑前。\n\n【Grace 技术+3。她再也不用偷偷摸摸了。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Grace" then m.skill = math.min(SKILL_CAP, m.skill + 3); m.mood = math.min(100, m.mood + 10) end
          end
      end,
    },

    -- ===== 第四幕：发展壮大（10-15天） =====
    { id = "baobao_visit",
      cond = function() return playerData_.day >= 11 and playerData_.reputation >= 40 end,
      type = "dialogue",
      title = "包包哥驾到",
      dialogues = {
          { speaker = "旁白", text = "一辆崭新的丰田霸道停在网吧门口。车上下来一个戴金链子的中国男人，后面跟着两个非洲保镖。" },
          { speaker = "包包哥", text = "哟！兄弟！听说你在这搞电竞？我是包包哥，浙江温州的，在马达加斯加开了三家网吧！" },
          { speaker = "你", text = "（内心震撼）三家？！" },
          { speaker = "包包哥", text = "跑刀代练这条路，我比你早走半年。但你这搞战队的思路厉害啊！" },
          { speaker = "包包哥", text = "听说你要打全非洲锦标赛？需要赞助不？我出钱，你出人，赢了奖金五五分！" },
          { speaker = "你", text = "包哥……这可太及时了！" },
          { speaker = "包包哥", text = "另外，我这有个渠道——国内有人专门收'纯黑跑刀'的哈弗币。价格比你现在出的高20%。" },
          { speaker = "旁白", text = "包包哥留下了$500赞助金和一箱泡面辣条。\n\n【获得$500。解锁高价哈弗币渠道。包包哥成为你的盟友。】" },
      },
      effect = function() playerData_.money = playerData_.money + 500; playerData_.reputation = playerData_.reputation + 30 end,
    },
    { id = "power_crisis",
      cond = function() return playerData_.day >= 12 and playerData_.solarLevel == 0 end,
      type = "dialogue",
      title = "停电危机·Mama B的智慧",
      dialogues = {
          { speaker = "旁白", text = "又是停电。这已经是这周第三次了。队员们无事可做，士气低落。" },
          { speaker = "Mama B", text = "（从门口探头）老板，你为什么不装太阳能板？这里的太阳又不花钱！" },
          { speaker = "你", text = "太阳能？划算吗？" },
          { speaker = "Mama B", text = "我表弟在城里卖太阳能板，我帮你问问？他给朋友价。" },
          { speaker = "你", text = "Mama B，你真是我的救星！" },
          { speaker = "旁白", text = "你开始认真考虑太阳能板的投资。\n\n【提示：升级'太阳能板'可以减少停电影响。声望+10】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 10 end,
    },
    { id = "b_station_famous",
      cond = function() return playerData_.reputation >= 60 and playerData_.totalRuns >= 5 end,
      type = "dialogue",
      title = "我们上B站热搜了！",
      dialogues = {
          { speaker = "旁白", text = "你的手机突然疯狂震动——微信、QQ、抖音的消息多到刷不过来。" },
          { speaker = "你", text = "怎么了？出什么事了？" },
          { speaker = "旁白", text = "国内一个百万粉UP主做了一期视频：《在非洲开网吧教黑人兄弟跑刀三角洲》" },
          { speaker = "旁白", text = "播放量三天破了500万。弹幕刷屏：'纯黑跑刀'、'非洲战神'、'这才是真正的文化输出'。" },
          { speaker = "旁白", text = "你打开评论区，有人写道：'这是我见过最硬核的创业故事。在非洲，用游戏改变命运。'" },
          { speaker = "你", text = "（鼻子一酸）我只是想开个网吧来着……" },
          { speaker = "旁白", text = "视频火了之后，国内好几个赞助商联系了你。甚至有电竞媒体想来做专访。\n\n【声望+40，$+200。'纯黑跑刀'成为热门话题。】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 40; playerData_.money = playerData_.money + 200 end,
    },
    { id = "prince_dilemma",
      cond = function() return HasMember("Prince") and playerData_.day >= 13 end,
      type = "choice",
      title = "酋长之子的选择",
      icon = "👑",
      desc = "Prince的父亲——酋长大人亲自来到网吧。他的保镖站在门口，气氛一下子凝重起来。\n\n'我的儿子，你已经证明了自己。现在跟我回去，我安排你去拉各斯学商。'\n\nPrince看向你，眼里写满了挣扎。",
      choices = {
          { text = "🙏 尊重酋长：让Prince自己选", result = "你说：'酋长先生，Prince在我们队是核心。但这是他的人生，应该他自己决定。'\n\nPrince深吸一口气：'爸，我要留下。比赛结束之前，我哪也不去。'\n\n酋长沉默良久，最后点了点头。\n\n【Prince 心情+20，技术+5。酋长赠送$200表示认可。】",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Prince" then m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = math.min(100, m.mood + 20) end
                end
                playerData_.money = playerData_.money + 200; playerData_.reputation = playerData_.reputation + 20
                playerData_.karma = playerData_.karma + 2  -- 尊重自主
            end },
          { text = "👋 放Prince走：不能跟酋长对着干", result = "你叹了口气：'Prince，家里的事更重要。'\n\nPrince什么也没说，跟着父亲的车走了。三天后你收到他的短信：'等比赛那天，我会回来的。'\n\n【Prince暂时离队。但你获得酋长的友谊，声望+30。】",
            effect = function()
                for i, m in ipairs(teamMembers_) do if m.name == "Prince" then table.remove(teamMembers_, i); break end end
                playerData_.reputation = playerData_.reputation + 30
                playerData_.karma = playerData_.karma - 1  -- 务实但放弃了队友
            end },
      },
    },

    -- ===== 第五幕：赛前冲刺 =====
    { id = "team_bonding",
      cond = function() return #teamMembers_ >= 3 and GetTeamAvgSkill() >= 30 end,
      type = "dialogue",
      title = "深夜的网吧",
      dialogues = {
          { speaker = "旁白", text = "凌晨两点。训练结束了，但没人想走。" },
          { speaker = "旁白", text = "有人去Mama B的摊子端来了剩余的烤鸡。有人泡了最后几包辣条。" },
          { speaker = teamMembers_[1] and teamMembers_[1].name or "队员", text = "老板，你说我们真的能赢吗？那些大城市的队伍，设备比我们好十倍……" },
          { speaker = "你", text = "设备？嘿，我问你——他们停过电吗？" },
          { speaker = "旁白", text = "哄堂大笑。" },
          { speaker = "你", text = "他们猴子偷过鼠标吗？" },
          { speaker = "旁白", text = "笑声更大了。" },
          { speaker = "你", text = "我们在40度的铁皮屋里训练，在停电的黑暗中等待，在猴子偷了鼠标后用触摸板打完一局——" },
          { speaker = "你", text = "——这样的队伍，有什么好怕的？" },
          { speaker = "旁白", text = "安静了。然后，有人开始鼓掌。掌声越来越大。" },
          { speaker = "旁白", text = "非洲夜空下，Dragon Net Cafe的灯光是整条街唯一的光。\n\n【全队技术+3，心情+20。你们，准备好了。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3); m.mood = math.min(100, m.mood + 20) end
      end,
    },
    { id = "mama_b_sniper",
      cond = function() return HasMember("Mama B") and playerData_.day >= 14 end,
      type = "dialogue",
      title = "Mama B的真正实力",
      dialogues = {
          { speaker = "旁白", text = "训练赛上，你让Mama B试试狙击手位。" },
          { speaker = "旁白", text = "第一局：三杀。第二局：四杀。第三局……她一枪爆了对面最强选手的头。" },
          { speaker = teamMembers_[1] and teamMembers_[1].name or "队员", text = "Mama！你真的是40岁吗？！这反应速度不可能的！" },
          { speaker = "Mama B", text = "（微笑）我卖了20年烤鸡，练出了一双稳如磐石的手。翻鸡架和瞄准其实是一样的道理。" },
          { speaker = "你", text = "（目瞪口呆）" },
          { speaker = "Mama B", text = "而且啊……你以为我只会卖烤鸡？我年轻时候可是全村飞镖冠军。" },
          { speaker = "旁白", text = "队员们纷纷叫她'狙神婆婆'。Mama B笑着说：'比赛完了，还是要回来卖烤鸡的。'\n\n【Mama B 技术+8，全队心情+10。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Mama B" then m.skill = math.min(SKILL_CAP, m.skill + 8) end
              m.mood = math.min(100, m.mood + 10)
          end
      end,
    },
    { id = "thunder_story",
      cond = function() return HasMember("Thunder") and playerData_.day >= 9 end,
      type = "dialogue",
      title = "Thunder的伤疤",
      dialogues = {
          { speaker = "旁白", text = "训练间隙，你注意到Thunder在揉自己的右膝盖。" },
          { speaker = "你", text = "Thunder，你膝盖没事吧？" },
          { speaker = "Thunder", text = "（苦笑）老伤了。我曾经百米跑进10秒5，差一点就进了国家队。" },
          { speaker = "Thunder", text = "然后膝盖韧带断了。医生说我再也跑不了了。" },
          { speaker = "Thunder", text = "我在家躺了半年，什么都不想干。直到有一天路过你的网吧……" },
          { speaker = "Thunder", text = "你知道吗？第一次摸鼠标的时候，我发现——我的速度还在。只是从腿转移到了手上。" },
          { speaker = "Thunder", text = "0.1秒出枪。教练以前说我反应快得离谱，现在终于找到新用处了。" },
          { speaker = "你", text = "Thunder……你的速度没有消失。它只是换了一条赛道。" },
          { speaker = "旁白", text = "Thunder沉默了一会儿，然后笑了。那是你第一次看到他真正放松的笑容。\n\n【Thunder 技术+5，心情+15。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Thunder" then m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = math.min(100, m.mood + 15) end
          end
      end,
    },
    { id = "xiaoxue_bridge",
      cond = function() return HasMember("小雪") and playerData_.day >= 10 end,
      type = "dialogue",
      title = "小雪的课堂",
      dialogues = {
          { speaker = "旁白", text = "周末，小雪带了一群支教班上的孩子来参观网吧。" },
          { speaker = "小雪", text = "孩子们，今天的中文课换个地方上——我教你们一边打游戏一边学中文！" },
          { speaker = "旁白", text = "孩子们兴奋极了。小雪让他们在游戏里用中文交流。" },
          { speaker = "孩子们", text = "前方有敌人！快跑！撤离！……这些词好难啊！" },
          { speaker = "小雪", text = "（笑）'跑刀'用中文怎么说？对，'跑——刀'！'撤离成功'！" },
          { speaker = "你", text = "小雪老师，你这个中文教学法……绝了。" },
          { speaker = "小雪", text = "语言最好的学习方式就是沉浸。游戏就是最好的沉浸环境啊。" },
          { speaker = "旁白", text = "这个画面被一个志愿者拍了下来发到了朋友圈。\n\n【声望+20。小雪 技术+3。'游戏+教育'的模式引起了关注。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "小雪" then m.skill = math.min(SKILL_CAP, m.skill + 3) end
          end
          playerData_.reputation = playerData_.reputation + 20
      end,
    },
    { id = "bigjoe_bodyguard",
      cond = function() return HasMember("Big Joe") and playerData_.day >= 9 end,
      type = "dialogue",
      title = "Big Joe挺身而出",
      dialogues = {
          { speaker = "旁白", text = "夜里十一点，三个混混走进网吧。他们翻着桌上的东西，态度很嚣张。" },
          { speaker = "混混", text = "这网吧不错啊。中国老板，识相的话每个月交点'保护费'？" },
          { speaker = "旁白", text = "你还没开口，Big Joe站了起来。他200斤的身躯挡在你前面。" },
          { speaker = "Big Joe", text = "（低沉地）我以前给酋长当保镖的时候，处理过比你们难缠十倍的人。走吧。" },
          { speaker = "旁白", text = "三个混混对视了一眼，灰溜溜地走了。" },
          { speaker = "你", text = "Joe哥……太帅了。" },
          { speaker = "Big Joe", text = "（笑）保护人用拳头，保护队友用鼠标。但偶尔，还是得用用拳头。" },
          { speaker = "旁白", text = "【Big Joe 心情+15。网吧安全感大增。声望+10。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Big Joe" then m.mood = math.min(100, m.mood + 15) end
          end
          playerData_.reputation = playerData_.reputation + 10; playerData_.securityLevel = math.max(playerData_.securityLevel, 1)
      end,
    },

    -- ===== 里程碑事件 =====
    { id = "rival_appears",
      cond = function() return playerData_.reputation >= 50 end,
      type = "dialogue",
      title = "对手出现",
      dialogues = {
          { speaker = "旁白", text = "路人冲进网吧，气喘吁吁——" },
          { speaker = "路人", text = "老板！隔壁城市Lagos那个Gold Net网吧……他们也组了战队！" },
          { speaker = "路人", text = "听说老板是个叫Victor的德国人，砸了一万刀买最新设备，还从肯尼亚请了教练！他们放话说全非洲第一！" },
          { speaker = "你", text = "（握拳）设备好有什么用？关键看人。" },
          { speaker = "旁白", text = "竞争，来了。\n\n【主线推进：Victor和Gold Net战队出现。请加快升级和训练！】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 10 end,
    },
    { id = "victor_provoke",
      cond = function() return storyTriggered_["rival_appears"] and playerData_.day >= 12 end,
      type = "dialogue",
      title = "Victor的挑衅",
      dialogues = {
          { speaker = "旁白", text = "一辆黑色奔驰G停在网吧门口。一个穿着考究的白人男子走了进来。" },
          { speaker = "Victor", text = "（打量四周）所以这就是那个传说中的Dragon Net Cafe？比我想象的……还要简陋。" },
          { speaker = "你", text = "你是？" },
          { speaker = "Victor", text = "Victor Schneider。Gold Net的老板。我就来看看，到底是什么样的地方，能培养出'全非洲最有灵魂的战队'。" },
          { speaker = "Victor", text = "（冷笑）你的队员用的是什么？二手键盘？三百块的鼠标？我的队员人手一套罗技旗舰。" },
          { speaker = "你", text = "电竞不是比谁的鼠标贵。" },
          { speaker = "Victor", text = "不，电竞比的就是资源。资金、设备、专业教练——你一样都没有。" },
          { speaker = "Victor", text = "锦标赛上见。我会让你知道，光凭'灵魂'是赢不了比赛的。" },
          { speaker = "旁白", text = "Victor转身离开了。网吧里的气氛一下子沉了下去。" },
          { speaker = "旁白", text = "但你看到队员们的眼神——那不是恐惧，是愤怒和不服。\n\n【全队心情+10。怒火也是动力。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
          playerData_.reputation = playerData_.reputation + 5
      end,
    },
    { id = "victor_poach",
      cond = function() return storyTriggered_["victor_provoke"] and #teamMembers_ >= 2 and playerData_.day >= 14 end,
      type = "choice",
      title = "Victor的挖角",
      icon = "💰",
      desc = "你最好的队员收到了Victor的私信：'加入Gold Net，月薪500美金，全套顶级设备。你在那个铁皮屋里待着有什么前途？'\n\n队员把消息给你看了。怎么办？",
      choices = {
          { text = "🔥 加薪留人（每人+$50/月）", result = "你咬牙涨了工资。队员们感动了：'老板，我们不走。Dragon Force才是家。'\n\n【-$100，全队心情+20，忠诚度大增。】",
            effect = function() playerData_.money = playerData_.money - 100; playerData_.karma = playerData_.karma + 2
              for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 20) end end,
            cond = function() return playerData_.money >= 100 end },
          { text = "💪 用梦想挽留", result = "你把大家叫到一起：'Victor给的是钱，我给的是未来。赢了锦标赛，你们就是传奇。'\n\n队员们沉默，然后点了点头。\n\n【全队心情+8，技术+2。梦想的力量。】",
            effect = function() playerData_.karma = playerData_.karma + 1
              for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 8); m.skill = math.min(SKILL_CAP, m.skill + 2) end end },
      },
    },
    { id = "victor_sabotage",
      cond = function() return storyTriggered_["victor_poach"] and playerData_.day >= 16 end,
      type = "choice",
      title = "可疑的断网",
      icon = "🔌",
      desc = "连续三天，你的网吧网络断断续续。技术员检查后发现——有人在你的网线接头上做了手脚。\n\nMama B说她看到Gold Net的人在附近出没。",
      choices = {
          { text = "🛡️ 花钱升级网络安全（-$120）", result = "你请了专业人员重新布线，加装了监控。以后不怕了。\n\n【-$120，声望+10。网络稳定性提升。】",
            effect = function() playerData_.money = playerData_.money - 120; playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 120 end },
          { text = "📢 公开曝光Victor的行为", result = "你把证据发到社交媒体上。Victor被迫道歉。\n\n【声望+25。Victor名声受损，但他会记恨你。】",
            effect = function() playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 1 end },
      },
    },
    { id = "media_interview",
      cond = function() return playerData_.reputation >= 80 and #teamMembers_ >= 3 end,
      type = "dialogue",
      title = "记者来访",
      dialogues = {
          { speaker = "旁白", text = "一辆印着电视台标志的车停在门口。一男一女拿着摄像机走进来。" },
          { speaker = "记者", text = "你好！我们是非洲之声电视台的。我们想做一期关于'电子竞技改变非洲青年命运'的专题。" },
          { speaker = "记者", text = "听说你从中国来这里开网吧，组建了一支叫Dragon Force的战队？" },
          { speaker = "你", text = "是的。这些孩子有天赋，只是缺少机会。" },
          { speaker = "记者", text = "（对着镜头）观众朋友们，在这间简陋的铁皮屋里，一群非洲年轻人正在用键盘和鼠标改写自己的命运……" },
          { speaker = "旁白", text = "采访播出后引起了巨大反响。越来越多的人知道了Dragon Force。\n\n【声望+30，$+100。Dragon Force的故事传遍了非洲。】" },
      },
      effect = function() playerData_.reputation = playerData_.reputation + 30; playerData_.money = playerData_.money + 100 end,
    },

    -- ===== 队员个人事件 =====
    { id = "kofi_mom",
      cond = function() return HasMember("Kofi") and playerData_.day >= 8 end,
      type = "dialogue",
      title = "Kofi的妈妈来了",
      dialogues = {
          { speaker = "旁白", text = "一个穿着传统服装的非洲妇女推开网吧大门，表情严肃得像要找人算账。" },
          { speaker = "Kofi的妈妈", text = "你就是那个中国老板？你把我儿子带坏了！他不去地里干活，天天跑来打游戏！" },
          { speaker = "Kofi", text = "（慌张站起来）妈妈！我……我没有乱来……" },
          { speaker = "你", text = "阿姨您好，请坐。Kofi 是我见过最有天赋的年轻人。请看看这个——" },
          { speaker = "旁白", text = "你打开 Kofi 的账户记录，给她看上个月通过跑刀赚到的钱。比他在工地搬砖一个月还多。" },
          { speaker = "Kofi的妈妈", text = "这……这些钱都是他赚的？不是偷的？" },
          { speaker = "你", text = "每一分都是他自己赚的。而且我正在培养他进入职业电竞联赛。如果成功，他会改变你们全家。" },
          { speaker = "Kofi的妈妈", text = "（沉默很久，声音发颤）……你要保证，不让他学坏。他是我唯一的希望。" },
          { speaker = "Kofi", text = "（红着眼眶）妈妈……我一定会让你骄傲的。" },
          { speaker = "旁白", text = "Kofi 的妈妈最终默许了。临走前她塞给你一袋自家种的芒果，转身擦了擦眼角。\n\n【Kofi 解除心理负担，训练全力投入。技术+10 心情满值。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Kofi" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 10) end
          end
      end,
    },
    { id = "snake_redemption",
      cond = function() return HasMember("Snake") and playerData_.day >= 12 and playerData_.karma >= 2 end,
      type = "dialogue",
      title = "Snake的告白",
      dialogues = {
          { speaker = "旁白", text = "深夜，网吧只剩你和 Snake。他难得地没有戴墨镜，表情异常认真。" },
          { speaker = "Snake", text = "老板……我想跟你说个事。" },
          { speaker = "你", text = "怎么了？" },
          { speaker = "Snake", text = "我以前在街上混，手上不干净。偷过东西，打过人。有个疤……是刀留的。" },
          { speaker = "Snake", text = "但自从来了你这，我发现——在游戏里杀人的感觉，比在街上好太多了。没人真的受伤。" },
          { speaker = "内心", text = "看着他认真的样子，你想起他第一次来网吧时那副谁都不服的表情。变化，是真实发生的。", type = "monologue" },
          { speaker = "Snake", text = "我想……我想把以前的兄弟也拉过来。让他们也打游戏，别再在街上混了。可以吗？" },
          { speaker = "你", text = "当然可以。Dragon Net Cafe 的门，对所有人敞开。" },
          { speaker = "Snake", text = "（露出一个罕见的笑容）谢了，老大。" },
          { speaker = "旁白", text = "第二天，Snake 带来了三个以前的兄弟。他们笨拙地握着鼠标，眼神却出奇地专注。\n\n【Snake 彻底归心。技术+8，声望+20。网吧多了几个忠实顾客。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Snake" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 8) end
          end
          playerData_.reputation = playerData_.reputation + 20; playerData_.money = playerData_.money + 40
      end,
    },
    { id = "grace_sermon",
      cond = function() return HasMember("Grace") and playerData_.day >= 10 and storyTriggered_["grace_secret"] end,
      type = "choice",
      title = "Grace 的秘密暴露了",
      icon = "⛪",
      desc = "周日下午，一个穿着牧师长袍的中年男人怒气冲冲地冲进网吧。\n\n「Grace！我就知道你不是在图书馆！你在这种地方——打游戏！？」\n\nGrace 脸色苍白：「爸爸……我可以解释……」\n\n牧师转向你：「你就是那个引诱我女儿堕落的人！」",
      choices = {
          { text = "🙏 诚恳解释电竞的价值", result = "你向牧师展示了Grace的比赛录像和收入记录。他沉默了很久，最终叹了口气说'也许上帝确实给了她不同的天赋'。\n\nGrace 光明正大训练！技术+12",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Grace" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 12) end
                end
                playerData_.karma = playerData_.karma + 2
            end },
          { text = "🤫 让Grace自己做选择", result = "Grace哭着跑出去了。三天后她悄悄回来，说已经和父亲谈过了。虽然还要偷偷来，但她的眼神更坚定了。\n\nGrace 心情-10 但技术+5",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Grace" then m.mood = math.max(0, m.mood - 10); m.skill = math.min(SKILL_CAP, m.skill + 5) end
                end
            end },
      },
      cond_type = "story_choice",
    },
    { id = "mamab_sniper",
      cond = function() return HasMember("Mama B") and playerData_.day >= 11 and storyTriggered_["mama_b_sniper"] end,
      type = "choice",
      title = "Mama B 的狙击课",
      icon = "🎯",
      desc = "下午三点，Mama B 像往常一样架着她的烤鸡摊。一个路过的退役军人看见她在空闲时用鼠标练狙——屏幕上全是爆头击杀。\n\n退役军人（震惊）：「大姐……你这枪法，比我们连队的狙击手还稳！」\n\nMama B 腼腆地笑：「烤鸡翻面要掌握时机，狙击也一样嘛。」\n\n退役军人转身对你说：「老板，我认识拉各斯的一个电竞教练。让他看看这位大姐的录像，说不定能拿到军方狙击赛的邀请函。」",
      choices = {
          { text = "📧 联系教练，争取军方邀请", result = "教练看了Mama B的录像，当场震惊。三天后军方狙击电竞邀请赛的邀请函寄到了网吧。\n\nMama B 成为全镇传奇！技术+15 声望+30",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Mama B" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 15) end
                end
                playerData_.reputation = playerData_.reputation + 30
                playerData_.karma = playerData_.karma + 1
            end },
          { text = "🍗 让她专心卖烤鸡，别分心", result = "Mama B 点点头：'也是，烤鸡还是第一位。'但你看到她的眼神暗了一瞬。\n\nMama B 心情-15 技术+3",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    if m.name == "Mama B" then m.mood = math.max(0, m.mood - 15); m.skill = math.min(SKILL_CAP, m.skill + 3) end
                end
            end },
      },
      cond_type = "story_choice",
    },
    { id = "prince_father",
      cond = function() return HasMember("Prince") and playerData_.day >= 13 and storyTriggered_["prince_dilemma"] end,
      type = "dialogue",
      title = "酋长的警告",
      dialogues = {
          { speaker = "旁白", text = "一辆黑色SUV停在网吧门口。两个穿西装的保镖先下了车，然后一个戴金链的中年男人缓缓走出。" },
          { speaker = "旁白", text = "所有人都安静了——这是当地酋长，Prince的父亲。" },
          { speaker = "酋长", text = "你就是那个中国人？我儿子天天往你这里跑，荒废了家族事务。" },
          { speaker = "你", text = "酋长先生，Prince 在这里学到的不仅是游戏——" },
          { speaker = "酋长", text = "（举手打断）我不想听。我给你两个选择：让他回来继承家业，或者……" },
          { speaker = "Prince", text = "（突然站起来）父亲！够了！" },
          { speaker = "旁白", text = "网吧里所有人都愣住了。Prince 从来没有在公开场合顶撞过父亲。" },
          { speaker = "Prince", text = "我尊敬您，但我不要靠您的名字活着。Dragon Force 是我自己选择的路。如果我们赢了全非洲大赛——" },
          { speaker = "酋长", text = "（沉默良久）……赢了再说。" },
          { speaker = "旁白", text = "酋长转身上车。临走前，他的保镖悄悄塞给你一个信封。\n里面是$500和一张纸条：'照顾好他。'\n\n【Prince 觉醒！技术+12 心情满值 +$500】" },
      },
      effect = function()
          playerData_.money = playerData_.money + 500
          for _, m in ipairs(teamMembers_) do
              if m.name == "Prince" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 12) end
          end
      end,
    },
    { id = "yuki_livestream",
      cond = function() return HasMember("小雪") and playerData_.day >= 9 end,
      type = "dialogue",
      title = "小雪的直播",
      dialogues = {
          { speaker = "旁白", text = "晚上九点，你发现小雪对着手机在直播。弹幕密密麻麻全是中文。" },
          { speaker = "小雪", text = "（对着镜头）家人们看！这就是我在非洲的网吧！今天我们队刚跑了一波三角洲，你们猜怎么着——" },
          { speaker = "旁白", text = "你凑过去一看——直播间人数：27000。" },
          { speaker = "你", text = "两万七？？这么多人？！" },
          { speaker = "小雪", text = "（得意地笑）我在B站有个账号叫'非洲支教日记'，之前拍了些教孩子们说中文的视频。这次直播跑刀，粉丝们都疯了。" },
          { speaker = "旁白", text = "弹幕里刷着：'纯黑跑刀YYDS' '非洲老哥带我飞' '打赏10个火箭支持支教老师'" },
          { speaker = "小雪", text = "老板，这次直播打赏已经超过5000块人民币了。我想……我想把一半捐给村里的学校，一半留给网吧。你觉得呢？" },
          { speaker = "内心", text = "看着她认真的眼神，你想起她说'在这里找到了比大城市更纯粹的快乐'。这个姑娘，比你更像个理想主义者。", type = "monologue" },
          { speaker = "你", text = "全捐给学校吧。网吧不差这点钱。你做的事比跑刀更重要。" },
          { speaker = "小雪", text = "（眼眶红了）老板……谢谢你。" },
          { speaker = "旁白", text = "直播间弹幕瞬间刷屏：'老板是真男人' '泪目了' '我也要去非洲支教'\n\n【声望暴涨！声望+50 小雪技术+10 全队心情+10】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 50
          for _, m in ipairs(teamMembers_) do
              if m.name == "小雪" then m.skill = math.min(SKILL_CAP, m.skill + 10) end
              m.mood = math.min(100, m.mood + 10)
          end
          playerData_.karma = playerData_.karma + 3
      end,
    },
    { id = "thunder_comeback",
      cond = function() return HasMember("Thunder") and playerData_.day >= 15 end,
      type = "dialogue",
      title = "Thunder 的赛道",
      dialogues = {
          { speaker = "旁白", text = "训练间隙，你看到 Thunder 一个人坐在网吧门口，盯着远处的红土路发呆。" },
          { speaker = "你", text = "怎么了？不舒服？" },
          { speaker = "Thunder", text = "（指着远处）老板……你知道那条路通向哪里吗？国家体育场。我以前每天在那里跑400米。" },
          { speaker = "Thunder", text = "0.1秒。我比冠军慢了0.1秒。然后膝盖就废了。" },
          { speaker = "内心", text = "0.1秒——对短跑运动员来说，那是一个宇宙的距离。", type = "monologue" },
          { speaker = "Thunder", text = "教练说我再也跑不了了。我妈哭了一个星期。我在家躺了三个月，觉得人生完了。" },
          { speaker = "Thunder", text = "然后我走进你的网吧，第一次摸鼠标——那个甩枪的感觉……就像在跑道上冲刺一样。" },
          { speaker = "你", text = "你的反应速度是天赋。只是换了一条赛道。" },
          { speaker = "Thunder", text = "（站起来，活动了一下膝盖）老板，我想明白了。跑道在腿上，也在手上。这次我不会再输0.1秒了。" },
          { speaker = "旁白", text = "Thunder 走回网吧，坐下来开始疯狂练习。你注意到他的甩枪速度又快了——0.08秒出枪。\n\n【Thunder 突破瓶颈！技术+14 天赋提升至98】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Thunder" then
                  m.mood = 100
                  m.skill = math.min(SKILL_CAP, m.skill + 14)
                  m.talent = math.min(100, m.talent + 5)  -- 天赋也提升
              end
          end
      end,
    },
    { id = "bigjoe_arm",
      cond = function() return HasMember("Big Joe") and playerData_.day >= 14 end,
      type = "dialogue",
      title = "Big Joe 的旧伤",
      dialogues = {
          { speaker = "旁白", text = "训练赛进行到一半，Big Joe 突然停下了，右手不自然地垂着。" },
          { speaker = "Big Joe", text = "（咬着牙）没事……老毛病。当保镖时候伤的，有时候会突然疼。" },
          { speaker = "你", text = "别硬撑！先休息。" },
          { speaker = "Big Joe", text = "老板，我怕……我怕手废了，就没用了。你还会要我吗？" },
          { speaker = "内心", text = "看着这个200斤的壮汉眼里闪着不安，你心里一阵酸。在这片土地上，每个人都在害怕被抛弃。", type = "monologue" },
          { speaker = "你", text = "Joe，你不只是一个选手。你是 Dragon Force 的灵魂。手疼的时候，你就当教练指挥。" },
          { speaker = "Big Joe", text = "（愣住，然后咧嘴笑了）老板……你是我见过最好的人。" },
          { speaker = "旁白", text = "你花了$60买了护腕和止痛药给Big Joe。从此他训练前都会先热身按摩。\n\n【Big Joe 忠诚度MAX，全队心情+8。】" },
      },
      effect = function()
          playerData_.money = playerData_.money - 60
          for _, m in ipairs(teamMembers_) do
              if m.name == "Big Joe" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 5) end
              m.mood = math.min(100, m.mood + 8)
          end
      end,
    },

    -- ===== 中期里程碑事件（不依赖特定队员，填补叙事空窗） =====
    { id = "milestone_local_fame",
      cond = function() return playerData_.day >= 6 and playerData_.reputation >= 20 end,
      type = "dialogue",
      title = "小镇名人",
      dialogues = {
          { speaker = "旁白", text = "清晨，网吧门口围了一群好奇的孩子，趴在窗户上往里看。" },
          { speaker = "小孩A", text = "就是这里！我哥说这个中国人的网吧能赚钱！" },
          { speaker = "小孩B", text = "真的假的？打游戏能赚钱？" },
          { speaker = "旁白", text = "镇上的杂货铺老板也走过来，递给你一瓶芬达。" },
          { speaker = "杂货铺老板", text = "中国老板，听说你这里年轻人排着队来？我能在你门口摆个摊卖饮料不？租金我给你。" },
          { speaker = "你", text = "行啊，热闹点好。" },
          { speaker = "旁白", text = "Dragon Net Cafe 开始成为小镇的据点。你在这片土地上扎下了根。\n\n【声望+15，每日额外收入+10】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          playerData_.foodShop = math.max(playerData_.foodShop, 1)
      end,
    },
    { id = "milestone_power_of_team",
      cond = function() return playerData_.day >= 9 and #teamMembers_ >= 1 end,
      type = "dialogue",
      title = "一场输不起的赌",
      dialogues = {
          { speaker = "旁白", text = "隔壁村的网吧老板——一个留着大胡子的尼日利亚人走进来，拍了一张100美元钞票在柜台上。" },
          { speaker = "大胡子", text = "中国佬！你的人不是很能打吗？我的人跟你的人打一场，100块赌注。敢不敢？" },
          { speaker = "旁白", text = "你的队员们从屏幕后面探出头来。网吧里所有人都在看着你。" },
          { speaker = "你", text = "（看了看队员们）……打。" },
          { speaker = "旁白", text = "这是Dragon Force第一次有了'为战队而战'的感觉。无论输赢，他们更像一个团队了。" },
          { speaker = "旁白", text = "【全队心情+10，技术+3。你的战队精神开始成型。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do
              m.mood = math.min(100, m.mood + 10)
              m.skill = math.min(SKILL_CAP, m.skill + 3)
          end
          playerData_.money = playerData_.money + 50
      end,
    },
    { id = "milestone_rent_hike",
      cond = function() return playerData_.day >= 12 end,
      type = "choice",
      title = "房东来了",
      icon = "🏠",
      desc = "房东——一个戴金链子的胖男人出现在网吧门口。\n\n'中国老板，听说你生意不错啊？下个月房租涨50%。不满意？隔壁可有人出价更高。'\n\n你攥紧了拳头。这个地方是Dragon Force的根据地，不能丢。",
      choices = {
          { text = "💰 接受涨价，保住根据地", result = "你咬着牙签了新合同。房租涨了，但Dragon Net Cafe还在。\n\n队员们凑在一起，Kofi说：'老板别担心，我们会赚更多的。'\n\n【房租永久上涨，但全队凝聚力提升。心情+8】",
            effect = function()
                for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 8) end
                playerData_.money = playerData_.money - 100
            end },
          { text = "🗣️ 谈判：用名气换折扣", result = "你冷静地跟房东分析：'我这网吧带火了整条街，你隔壁那几家铺子都是沾了我的光。赶我走，你的其他租户也会受影响。'\n\n房东想了想：'行，只涨20%。但你欠我一个人情。'\n\n【小幅涨租，声望+10，保住一笔钱】",
            effect = function()
                playerData_.money = playerData_.money - 50
                playerData_.reputation = playerData_.reputation + 10
            end },
      },
    },
    { id = "milestone_internet_down",
      cond = function() return playerData_.day >= 15 and playerData_.netSpeed < 3 end,
      type = "dialogue",
      title = "全镇断网危机",
      dialogues = {
          { speaker = "旁白", text = "灾难降临——全镇的网络中断了。据说是海底光缆出了问题，可能要三天才能修复。" },
          { speaker = "旁白", text = "没有网络，网吧没法营业。队员们焦躁不安。比赛在即，训练不能停。" },
          { speaker = "你", text = "既然没法线上训练，我们就线下练！" },
          { speaker = "你", text = "反应速度、战术讨论、团队配合……不用电脑也能提升。" },
          { speaker = "旁白", text = "你在网吧外面的空地上组织了体能训练和战术推演。路人纷纷围观，以为这是什么运动队。" },
          { speaker = "旁白", text = "三天后网络恢复时，队员们发现彼此的默契提升了一个档次。\n\n【全队技术+5。逆境中的团队力量。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 5) end
          playerData_.reputation = playerData_.reputation + 10
      end,
    },
    { id = "milestone_community",
      cond = function() return playerData_.day >= 18 and playerData_.reputation >= 70 end,
      type = "dialogue",
      title = "社区的力量",
      dialogues = {
          { speaker = "旁白", text = "镇长亲自登门拜访了。他带着几个长老，表情严肃但眼里有笑意。" },
          { speaker = "镇长", text = "中国老板，我们商量过了。你的网吧给这个镇带来了变化——年轻人有了收入，不再去城里打零工了。" },
          { speaker = "镇长", text = "镇议会决定，免你三个月房租。我们希望你留下来。" },
          { speaker = "你", text = "……谢谢。我哪也不去。" },
          { speaker = "旁白", text = "晚上，你站在网吧门口看着星空。从一个人到一个队，再到一个社区。你不再只是'那个开网吧的中国人'了。" },
          { speaker = "旁白", text = "【获得$300社区支持金。声望+25。这是你在非洲的家。】" },
      },
      effect = function()
          playerData_.money = playerData_.money + 300
          playerData_.reputation = playerData_.reputation + 25
      end,
    },

    -- ===== 道德博弈事件 =====
    { id = "warlord_computers",
      cond = function() return playerData_.day >= 12 and playerData_.computers >= 5 end,
      type = "choice",
      title = "军阀的提案",
      icon = "🔫",
      desc = "两个穿迷彩服的人走进网吧。为首的脸上有道疤，自称是 General Okafor 的手下。\n\n'老板，我们需要借用你的高性能电脑跑一些……计算。三天时间，我们付 $800。你不需要问是什么计算。'\n\n你知道拒绝可能有麻烦，但答应的话，网吧要停业三天，而且……天知道他们要算什么。",
      choices = {
          { text = "💰 答应：$800到手，管他算什么",
            result = "你把后面三台电脑清出来给他们用。三天里，那几台机器的风扇一直狂转。\n\n队员们被迫挤在前面的机位训练，效率大打折扣。但$800真金白银到手了。\n\n三天后他们走了，一句多余的话都没说。桌上留了一叠美金。\n\n【💰+$800，但声望-20，全队心情-10。有些钱拿着烫手。】",
            effect = function()
                playerData_.money = playerData_.money + 800; playerData_.reputation = playerData_.reputation - 20; playerData_.karma = playerData_.karma - 2
                for _, m in ipairs(teamMembers_) do m.mood = math.max(0, m.mood - 10) end
            end },
          { text = "🚫 拒绝：这钱不能拿",
            result = "你深吸一口气：'对不起，我的电脑要给战队训练用。'\n\n疤脸男盯着你看了很久，然后笑了：'有种。'\n\n他们走了。Mama Blessing从门外探头进来：'你做了正确的选择，中国老板。'\n\n第二天，你发现门口有人留了一袋新鲜水果。便条上写着：'感谢你没有帮坏人。'\n\n【声望+30，karma+2，全队心情+5。正义有时候也有回报。】",
            effect = function()
                playerData_.reputation = playerData_.reputation + 30; playerData_.karma = playerData_.karma + 2
                for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
            end },
          { text = "🤝 谈条件：可以，但我要看你们算什么",
            result = "你说：'我可以帮忙，但我得知道你们在做什么。'\n\n对方犹豫了一下，从包里掏出U盘：'是气象数据。General想在雨季之前规划一条新的运输路线。'\n\n原来只是物流计算。你松了口气，帮他们跑了数据。作为感谢，General Okafor 还送了你一台军用UPS电源。\n\n【💰+$400，声望+10，装备状态+10。有时候真相没那么可怕。】",
            effect = function()
                playerData_.money = playerData_.money + 400; playerData_.reputation = playerData_.reputation + 10
                playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 10)
            end },
      },
    },
    { id = "zero_talent_kid",
      cond = function() return playerData_.day >= 10 and #teamMembers_ >= 2 and #teamMembers_ < 5 end,
      type = "choice",
      title = "没有天赋的少年",
      icon = "🥺",
      desc = "一个瘦小的少年已经在网吧门口站了三天了。每天放学后他就来，趴在窗户上看队员训练。\n\n今天你终于叫他进来试了一局。结果……惨不忍睹。0击杀，死了12次。\n\n但他没有放弃。他红着眼眶问你：'老板……我知道我很菜。但是……你能教我吗？我什么都愿意做。我可以帮忙扫地、搬东西……'\n\n你看了看他的手——指节粗大，是常年洗碗留下的痕迹。Mama Blessing悄悄跟你说：'这孩子叫Abel，是孤儿院出来的。'",
      choices = {
          { text = "❤️ 收下他：'天赋不够，努力来凑'",
            result = "你拍了拍Abel的肩膀：'明天开始，你就是Dragon Force的见习队员。'\n\nAbel的眼泪瞬间就掉下来了。\n\n他确实不是打游戏的料。但他比任何人都努力——每天第一个到，最后一个走。帮忙打扫网吧、给队员倒水、记录训练数据。\n\n一个月后，他的技术虽然还是队里最差的，但他成了战队的'隐形管家'。所有人都喜欢他。\n\n【Abel加入战队（天赋低但成长稳定）。全队心情+10，karma+2。有些人的价值，不在键盘上。】",
            effect = function()
                table.insert(teamMembers_, { name = "Abel", talent = 40, mood = 100, skill = 5, trait = "孤儿院之光·不屈少年", emoji = "🧑🏿",
                    perk = "团队之心", perkDesc = "负责后勤和士气，全队心情恢复更快", perkBonus = 4,
                    flaw = "天赋不足", flawDesc = "操作基本功弱，比赛时拖后腿", flawPenalty = 6 })
                playerData_.questRecruitCount = (playerData_.questRecruitCount or 0) + 1
                for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
                playerData_.karma = playerData_.karma + 2
            end },
          { text = "💔 婉拒：'对不起，战队需要天赋'",
            result = "你犹豫了很久，最终说：'Abel……你是个好孩子。但电竞这条路，不适合每个人。'\n\nAbel低下头，没有说话。他默默走出了网吧。\n\nSnake突然站起来：'老板，你就这么把他赶走？'\n\n你没有回答。那天晚上，你看到Abel站在街对面，远远地看着网吧的灯光。\n\n【karma-1，队员心情-5。每个决定都有代价。但这也许是对他负责。】",
            effect = function()
                playerData_.karma = playerData_.karma - 1
                for _, m in ipairs(teamMembers_) do m.mood = math.max(0, m.mood - 5) end
            end },
      },
    },
    { id = "sandstorm_crisis",
      cond = function() return playerData_.day >= 15 end,
      type = "choice",
      title = "沙尘暴来了",
      icon = "🌪️",
      desc = "天色突然暗了下来。远处的地平线上，一道棕黄色的墙正在迅速逼近——沙尘暴。\n\n大风已经开始刮了，路上的行人拼命往建筑物里跑。你的网吧铁皮屋顶被吹得哐哐作响。\n\n关键是——有三个客人还在网吧里跑刀，而且他们即将完成一笔大额撤离。还有两分钟就能到撤离点。\n\n如果现在断电撤离，他们的跑刀进度全白费。如果继续开着……铁皮屋顶可能扛不住。",
      choices = {
          { text = "🛡️ 坚持两分钟：让他们完成撤离",
            result = function()
                if (playerData_.generatorLevel or 0) >= 2 then
                    return "你大喊：'稳住！还有两分钟！'\n\n铁皮屋顶发出恐怖的声响，沙粒像子弹一样打在窗户上。但你的加固过的发电机稳稳运转，电力没断。\n\n两分钟后，三个客人成功撤离。他们激动得快哭了：'老板你是神！'\n\n沙尘暴过后，网吧只掉了几块铁皮。设备完好。你的英雄事迹传遍了全镇。\n\n【💰+$150 ⭐+25 发电机扛住了！】"
                else
                    return "你大喊：'稳住！还有两分钟！'\n\n铁皮屋顶被掀飞了一角！沙子灌进来，显示器上全是灰。但那三个客人死死盯着屏幕，手没离开鼠标。\n\n他们成功撤离了。但网吧的设备被沙子糊了一层，需要清理和维修。\n\n【💰+$80 但设备状态-15。铁皮屋顶真的该修了。】"
                end
            end,
            effect = function()
                if (playerData_.generatorLevel or 0) >= 2 then
                    playerData_.money = playerData_.money + 150; playerData_.reputation = playerData_.reputation + 25
                else
                    playerData_.money = playerData_.money + 80
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 15)
                end
            end },
          { text = "⚡ 立刻断电撤离：安全第一",
            result = "你拔掉了总闸：'所有人出去！安全第一！'\n\n三个客人一脸绝望：'老板！还有两分钟就撤离了！'\n\n但你把他们推出了门。沙尘暴在外面肆虐了一个小时。\n\n暴风过后，网吧完好无损。那三个客人虽然抱怨了几句，但看到隔壁店铺的招牌都被吹飞了，也不说什么了。\n\n【设备安全。声望+5。客人不太高兴但理解你。】",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
            end },
      },
    },
    { id = "internet_ban_rumor",
      cond = function() return playerData_.day >= 18 and playerData_.reputation >= 80 end,
      type = "choice",
      title = "禁令传闻",
      icon = "📜",
      desc = "一条消息在城里疯传：政府可能要出台'游戏宵禁令'——晚上10点后禁止营业性质的游戏场所开放。\n\n这对你的影响巨大，因为包夜跑刀是网吧最赚钱的时段。\n\n镇上的网吧老板们正在组织联名请愿，需要有人牵头去首都递交。但这意味着你要离开网吧三天，路费自付。",
      choices = {
          { text = "🗣️ 牵头请愿：为行业发声",
            result = "你花了$200路费赶到首都，和其他五个网吧老板一起见了文化部的官员。\n\n你用蹩脚的当地语言讲述了电竞给年轻人带来的改变——Kofi用跑刀养家，Grace找到了人生方向。\n\n官员听完沉默了很久，最终说：'我们会考虑修改政策。'\n\n回来后，你发现镇上所有的网吧老板都在门口挂了'感谢Dragon Net Cafe'的横幅。\n\n【💸-$200，声望+50，karma+2。你不只是在经营网吧——你在守护一个行业。】",
            effect = function()
                playerData_.money = playerData_.money - 200; playerData_.reputation = playerData_.reputation + 50; playerData_.karma = playerData_.karma + 2
            end },
          { text = "🤫 观望等待：先看看情况",
            result = "你决定不出头，先观望。\n\n最终禁令没有通过——但这次是隔壁Gold Net的老板牵头请愿成功的。他因此成了行业英雄，声望大涨。\n\n而你……错过了一次被全城认可的机会。\n\n【无直接损失。但Gold Net声望+30。机会只敲一次门。】",
            effect = function()
                playerData_.reputation = playerData_.reputation - 10
            end },
      },
    },

    -- ===== 第六幕：中后期扩张与挑战（20天+） =====
    { id = "government_inspection",
      cond = function() return playerData_.day >= 20 and playerData_.computers >= 8 end,
      type = "choice",
      title = "突击检查",
      icon = "🏛️",
      desc = "两辆政府车停在门口。三个穿制服的人走进来，拿着表格上下打量。\n\n'营业执照？消防许可？卫生证？'\n\n你慌了——有些手续确实没办全。但你发现带头的那个人在偷偷玩三角洲……",
      choices = {
          { text = "📋 老实交代，花钱补齐手续（-$300）",
            result = "你诚恳地说：'长官，我承认手续不全。给我一周时间补齐。'\n\n你跑了三天衙门，盖了十几个章。累得半死，但终于拿到了全部许可证。\n\n检查员临走时说：'难得见到这么规矩的外国老板。以后有事可以找我。'\n\n【-$300，但获得合法经营保障。声望+20，不再有突击检查风险。】",
            effect = function()
                playerData_.money = playerData_.money - 300; playerData_.reputation = playerData_.reputation + 20
                playerData_.hasLicense = true
            end,
            cond = function() return playerData_.money >= 300 end },
          { text = "🎮 邀请检查员体验跑刀",
            result = "你注意到带头检查员在偷看屏幕，灵机一动：'长官，要不要试试？这游戏在全非洲都火了。'\n\n半小时后，检查员摘下帽子，挽起袖子，正在疯狂跑刀。他的同事在旁边干瞪眼。\n\n'这个……手续你尽快补。不急，一个月内就行。'\n\n他走的时候还问了WiFi密码。\n\n【-$100 手续简化费，声望+15。检查员成了常客。】",
            effect = function()
                playerData_.money = playerData_.money - 100; playerData_.reputation = playerData_.reputation + 15
            end },
      },
    },
    -- 2-C 新增：竞对特使造访（Day 20-23，rivalNpcs_ 已激活且声望 >= 60）
    { id = "rival_envoy_visit",
      cond = function()
          return playerData_.day >= 20 and playerData_.day <= 23
              and rivalNpcs_ ~= nil
              and (playerData_.reputation or 0) >= 60
              and not storyTriggered_["rival_envoy_visit"]
      end,
      type = "choice",
      title = "对手的使者",
      icon = "🤝",
      desc = "一个穿着 Blaze Net 队服的年轻人走进了你的网吧，礼貌地递上一张名片。\n\n'Blaze Net 的老板想见你。他说……你们的网吧越来越像个威胁了。'\n\n'他的提议是：停止参加本赛季锦标赛，换取 Blaze Net 不再故意压低你们的客流。'\n\n Mama B 把抹布摔在了台上。",
      choices = {
          { text = "🚫 拒绝：在自己的地盘认输？没门！",
            result = "你站起来，把名片还给他：'告诉你老板，Dragon Net 退赛？做梦。'\n\n年轻人尴尬地笑了笑，走出门时小声说：'其实……我也觉得你们比他们强。'\n\nMama B 高声喊道：'好！就该这样！'\n\n【拒绝收买，声望 +15，karma +1。Blaze Net 本周抢客力度 +5%，但你赢得了尊重。】",
            effect = function()
                playerData_.reputation = (playerData_.reputation or 0) + 15
                playerData_.karma = (playerData_.karma or 0) + 1
                if rivalNpcs_ and rivalNpcs_[1] then
                    rivalNpcs_[1].stealPct = math.min(30, (rivalNpcs_[1].stealPct or 15) + 5)
                end
            end },
          { text = "🤔 听他说完：也许有条件可以谈？",
            result = "你让他坐下，听完了所有条件。\n\n'停赛换取停手……这不是合作，这是勒索。'\n\n你把条件改成了：'我们继续参赛，但愿意共同举办一场公开表演赛，让两家的客户都看到真正的实力对决。'\n\n使者沉默片刻，说'我会转告'后离开了。\n\n【展现气度，声望 +10，Blaze Net 抢客力度本周降低 3%。互相尊重的竞争，才是长久之道。】",
            effect = function()
                playerData_.reputation = (playerData_.reputation or 0) + 10
                if rivalNpcs_ and rivalNpcs_[1] then
                    rivalNpcs_[1].stealPct = math.max(5, (rivalNpcs_[1].stealPct or 15) - 3)
                end
            end },
      },
    },
    -- 2-C 新增：忠实粉丝团形成（Day 22-26，computers >= 6 且总收入 >= 800）
    { id = "loyal_fans_formation",
      cond = function()
          return playerData_.day >= 22 and playerData_.day <= 26
              and (playerData_.computers or 0) >= 6
              and (playerData_.totalEarnings or 0) >= 800
              and not storyTriggered_["loyal_fans_formation"]
      end,
      type = "dialogue",
      title = "第一批死忠粉",
      dialogues = {
          { speaker = "旁白", text = "你注意到每天下午三点，总有同样的五张面孔出现在网吧门口——还没开门就在等。" },
          { speaker = "少年甲", text = "老板！今天有训练赛吗？我们专门来看 Dragon Force 的！" },
          { speaker = "你", text = "……你们每天都来？" },
          { speaker = "少年乙", text = "当然！上次 Kofi 那个六杀，全学校都在传！我们给你们做了应援牌！" },
          { speaker = "旁白", text = "他从背包里掏出一块硬纸板，上面歪歪扭扭地写着 'GO DRAGON FORCE'，还画了一条金色的龙。" },
          { speaker = "Kofi", text = "（小声凑过来）老板……这些是我们的粉丝吗？" },
          { speaker = "你", text = "（看着那块纸板，一时不知道说什么好）" },
          { speaker = "旁白", text = "你让他们进来，给每个人送了一瓶可乐。\n\n从那天起，下午三点，网吧门口总会有一群孩子在等着看训练。有时候带来自己种的芒果，有时候带来自制的加油横幅。\n\n【首批忠实粉丝！声望 +25，全队心情 +10。你们不只是在赢比赛，你们在成为这个地方的希望。】" },
      },
      effect = function()
          playerData_.reputation = (playerData_.reputation or 0) + 25
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
          playerData_.karma = (playerData_.karma or 0) + 1
          storyTriggered_["loyal_fans_formation"] = true
      end,
    },
    { id = "african_esports_media",
      cond = function() return playerData_.day >= 22 and playerData_.reputation >= 100 end,
      type = "dialogue",
      title = "非洲电竞联盟来电",
      dialogues = {
          { speaker = "旁白", text = "你的手机响了。来电显示是一个拉各斯的号码。" },
          { speaker = "AEL代表", text = "你好，我是非洲电竞联盟(AEL)的代表。我们注意到Dragon Force在地区赛的表现。" },
          { speaker = "AEL代表", text = "联盟正在筹备一个'非洲电竞发展计划'，希望在每个国家选拔一支代表队。" },
          { speaker = "AEL代表", text = "如果Dragon Force能在接下来的锦标赛中进入前三……我们将提供全额赞助，包括设备升级和国际赛事差旅费。" },
          { speaker = "你", text = "……前三？" },
          { speaker = "AEL代表", text = "是的。全额赞助，每年$10000的训练津贴，还有——代表非洲参加世界电竞锦标赛的名额。" },
          { speaker = "旁白", text = "你挂了电话，手在发抖。不是害怕，是兴奋。\n\n你走进网吧，对着队员们说：'兄弟们，我们有了一个更大的目标。'\n\n【全队技术+5，心情+15。前方有光，值得全力以赴。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = math.min(100, m.mood + 15) end
          playerData_.reputation = playerData_.reputation + 20
      end,
    },
    { id = "equipment_sponsor",
      cond = function() return playerData_.day >= 25 and playerData_.reputation >= 120 end,
      type = "choice",
      title = "赞助商的条件",
      icon = "🖥️",
      desc = "一个国际外设品牌的非洲区经理发来邮件：\n\n'我们愿意免费提供全套旗舰装备（价值$3000），条件是：\n1. 队员在比赛中必须使用我们的设备\n2. 每月拍摄一个产品推广视频\n3. 合同期两年，违约赔偿$5000'\n\n这是一个改变装备劣势的机会，但两年合约很长……",
      choices = {
          { text = "✅ 接受赞助：免费顶级装备！",
            result = "三天后，一大箱崭新的设备运到了网吧。队员们像过年一样兴奋。\n\nSnake第一个坐下来试新鼠标：'这手感……我以前用的是什么垃圾？'\n\n设备升级后，队员们的操作精准度肉眼可见地提升了。\n\n【设备状态满值，全队技术+8。赞助商Logo出现在队服上。】",
            effect = function()
                playerData_.equipCondition = 100
                for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 8) end
                playerData_.reputation = playerData_.reputation + 15
            end },
          { text = "❌ 婉拒：两年太长，自由更重要",
            result = "你回邮件：'感谢好意，但我们暂时不想被合约束缚。'\n\n队员们有些失望，但你说：'等我们赢了锦标赛，赞助商会排着队来找我们。到时候我们挑。'\n\n【声望+10，保持自由身。karma+1。】",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1
            end },
      },
    },
    { id = "hometown_doubters",
      cond = function() return playerData_.day >= 28 and playerData_.reputation >= 80 end,
      type = "dialogue",
      title = "国内的质疑",
      dialogues = {
          { speaker = "旁白", text = "你打开微信朋友圈，发现老家的同学们在讨论你——" },
          { speaker = "旁白", text = "'听说他在非洲开网吧？脑子坏了吧？' '都快三十的人了还在折腾' '他爸妈都急死了'" },
          { speaker = "旁白", text = "你翻到妈妈的消息：'儿子，你什么时候回来？邻居家的小王都买房了……'" },
          { speaker = "你", text = "（关掉手机，深呼吸）" },
          { speaker = "旁白", text = "凌晨的网吧，只有风扇在转。你看着墙上贴的Dragon Force全家福——那张在停电夜用手机闪光灯拍的照片。" },
          { speaker = "你", text = "（自言自语）邻居小王买房了。但小王没有让一群非洲少年的命运改变。" },
          { speaker = "旁白", text = "你给妈妈发了一条消息：'妈，等我们赢了比赛，我带队员回老家吃羊肉泡馍。'\n\n【你的内心更加坚定了。全队心情+5。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
          playerData_.karma = playerData_.karma + 1
      end,
    },
    -- =====================================================================
    -- 3-B 竞对叙事事件线：Victor / Gold Net 的兴衰弧
    -- =====================================================================

    { id = "gold_net_inner_crisis",
      cond = function()
          return playerData_.day >= 26 and playerData_.day <= 32
              and (storyTriggered_["victor_sabotage"] or storyTriggered_["rival_envoy_visit"])
              and (playerData_.reputation or 0) >= 90
              and not storyTriggered_["gold_net_inner_crisis"]
      end,
      type = "dialogue",
      title = "Gold Net 内部裂痕",
      dialogues = {
          { speaker = "旁白", text = "Mama B把一叠打印的截图放在你桌上，表情意味深长。" },
          { speaker = "Mama B", text = "你看看这个。Gold Net的队员在群里吵起来了，有人截图发出来了。" },
          { speaker = "旁白", text = "截图显示，Gold Net的韩国教练已经离职，理由是'Victor不尊重球员'。三名队员私聊吐槽训练强度太大、奖金被克扣。" },
          { speaker = "你", text = "……Victor把人逼得太紧了。" },
          { speaker = "Mama B", text = "有钱没心，留不住人。就算用金钱堆出来的队，也只是雇佣兵。" },
          { speaker = "你", text = "（看着训练中的Dragon Force）我们不一样。这里的每个人都是自己选择留下来的。" },
          { speaker = "旁白", text = "当天晚上，Gold Net 的一名替补队员悄悄发来私信：'我能来Dragon Net面试吗？'\n\n【Gold Net 出现内乱。你的声望进一步提升，全赛区都在看你如何应对。声望+15。】" },
      },
      effect = function()
          playerData_.reputation = (playerData_.reputation or 0) + 15
          storyTriggered_["gold_net_inner_crisis"] = true
      end,
    },

    { id = "victor_last_gambit",
      cond = function()
          return playerData_.day >= 30 and playerData_.day <= 36
              and storyTriggered_["gold_net_inner_crisis"]
              and (playerData_.reputation or 0) >= 120
              and not storyTriggered_["victor_last_gambit"]
      end,
      type = "choice",
      title = "Victor 的最后赌注",
      icon = "🎰",
      desc = "Victor 出现在网吧门口，这次没有嘲讽，没有随从。他独自一人，看起来比上次苍老了很多。\n\n'我直说吧。Gold Net 的投资人要撤资了。我需要在最后一场大赛中赢你，否则我就没有谈判筹码。'\n\n'……我想提议——把这场比赛办成一场真正的公开商业赛事。你我各出$500，请媒体直播，门票收入五五分。输家退出本赛区锦标赛系列。'\n\n'赢家，赢一切。'",
      choices = {
          { text = "⚔️ 接受决战：赢就赢个彻底",
            result = "'成交。'\n\nVictor第一次正眼看了你。不是轻蔑，是某种久违的尊重。\n\n'Dragon Force……你们是我见过的，资金最少但士气最高的队。我希望你们赢，是因为这圈子需要你们这样的故事。'\n\n三天后，公开赛的票在两小时内售罄。\n\n【-$500，锦标赛奖励翻倍。声望+20，karma+1。】",
            effect = function()
                playerData_.money = (playerData_.money or 0) - 500
                playerData_.reputation = (playerData_.reputation or 0) + 20
                playerData_.karma = (playerData_.karma or 0) + 1
                playerData_.victorFinalBet = true
            end,
            cond = function() return (playerData_.money or 0) >= 500 end },
          { text = "🤝 拒绝赌注，提议友谊赛",
            result = "'我不打赌注赛。但如果你想要一场公开赛——我们可以办，不设输家条款，让观众决定谁是真正的王者。'\n\nVictor沉默了很久，最后说：'……你比我想象的更有意思。'\n\n友谊赛如期举行，两队都赢得了观众。\n\n【声望+25，karma+2。没有输家的赛场，才是真正的胜利。】",
            effect = function()
                playerData_.reputation = (playerData_.reputation or 0) + 25
                playerData_.karma = (playerData_.karma or 0) + 2
            end },
      },
      effect = function() storyTriggered_["victor_last_gambit"] = true end,
    },

    { id = "gold_net_dissolution",
      cond = function()
          return playerData_.day >= 34 and playerData_.day <= 40
              and storyTriggered_["victor_last_gambit"]
              and (playerData_.totalTourney or 0) >= 2
              and not storyTriggered_["gold_net_dissolution"]
      end,
      type = "dialogue",
      title = "Gold Net 的落幕",
      dialogues = {
          { speaker = "旁白", text = "一个周五的傍晚，Gold Net 的门口挂上了'暂停营业'的牌子。" },
          { speaker = "旁白", text = "Victor 的投资人已经正式撤资。那批从欧洲运来的顶级设备，据说要被当二手货处理。" },
          { speaker = "旁白", text = "Kofi 把手机塞到你面前：'老板，你看，Victor 发朋友圈了。'" },
          { speaker = "Victor（朋友圈）", text = "'我在非洲待了两年，输给了一间铁皮屋。我以为钱可以买到一切，但我错了。Dragon Force 那些孩子有我永远买不到的东西——他们热爱这件事本身。祝你们好。'" },
          { speaker = "你", text = "（看完，沉默片刻）" },
          { speaker = "Kofi", text = "老板……你不高兴吗？我们赢了啊！" },
          { speaker = "你", text = "我高兴。只是……希望他还有机会找到那种热爱。" },
          { speaker = "旁白", text = "一周后，Victor 亲自来到 Dragon Net，把 Gold Net 最后一批品质最好的键盘留给了你们。\n\n'给那些孩子用吧。设备本来就不该白费在我这种地方。'\n\n【竞对叙事完结。Dragon Force 正式成为本赛区无可争议的第一。声望+30，全队技术+5。】" },
      },
      effect = function()
          playerData_.reputation = (playerData_.reputation or 0) + 30
          for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 5) end
          playerData_.karma = (playerData_.karma or 0) + 1
          storyTriggered_["gold_net_dissolution"] = true
          -- 清除 Gold Net 作为竞争对手的威胁
          if rivalNpcs_ then
              for _, r in ipairs(rivalNpcs_) do
                  if r.name and r.name:find("Gold Net") then
                      r.stealPct = 0; r.active = false
                  end
              end
          end
      end,
    },

    { id = "pre_tournament_crisis",
      cond = function() return playerData_.day >= 30 and playerData_.totalTourney >= 1 end,
      type = "choice",
      title = "赛前危机",
      icon = "⚠️",
      desc = "距离大赛还有三天。你的核心队员突然发烧了，躺在网吧的沙发上直打哆嗦。\n\n镇上唯一的诊所说可能是疟疾，需要吃药休息至少一周。但一周后比赛就结束了。\n\n队员拉着你的手：'老板……不要换掉我。给我药，让我打完这场。求你了。'",
      choices = {
          { text = "💊 花钱买最好的药，让他上场（-$200）",
            result = "你开车跑了两个小时去城里的大医院买了进口药。队员吃了药后烧退了，虽然还很虚弱，但坚持要训练。\n\n比赛那天，他全场发挥失常——但在最关键的一局，他抖着手打出了全场最关键的一个击杀。\n\n赛后他跪在地上哭了。不是因为赢了，是因为没有被放弃。\n\n【-$200，生病队员技术-5但心情+30，全队心情+15。有些胜利超越比分。】",
            effect = function()
                playerData_.money = playerData_.money - 200
                for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 15) end
                playerData_.karma = playerData_.karma + 1
            end,
            cond = function() return playerData_.money >= 200 end },
          { text = "🛌 让他休息，启用替补",
            result = "你按住他的肩膀：'你的健康比任何比赛都重要。好好休息，下次还有机会。'\n\n他含着眼泪点了点头。你紧急调整了战术，让其他队员补位。\n\n虽然少了主力，但队伍的默契反而因为逆境更强了。\n\n【全队技术+3，karma+2。有些教练的伟大，在于放手。】",
            effect = function()
                for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3) end
                playerData_.karma = playerData_.karma + 2
            end },
      },
    },
    { id = "gold_rush_scandal",
      cond = function() return playerData_.day >= 24 and (playerData_.goldOunces or 0) >= 3 end,
      type = "choice",
      title = "黄金骗局",
      icon = "🥇",
      desc = "一个自称'国际黄金交易员'的男人找到你，西装笔挺，手上戴着三个金戒指。\n\n'听说你在囤黄金？我有个内幕消息——下周政府要出台黄金出口禁令，金价至少涨50%。'\n\n'现在把你的黄金全部转给我代持，等涨价后卖出，利润三七分。你七我三。'\n\nMama B在角落里疯狂摇头。",
      choices = {
          { text = "🚫 拒绝：听Mama B的",
            result = "你笑着摇头：'不了，兄弟。我自己的黄金自己守。'\n\n男人脸色一变，匆匆离开了。三天后你听说隔壁镇有两个人被同样的骗局骗走了所有积蓄。\n\n你默默给Mama B买了一箱芬达。\n\n【黄金安全！声望+10，karma+1。Mama B是你的守护天使。】",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1
            end },
          { text = "🤔 交一部分试试（1oz）",
            result = "你决定冒个小险，给了他1盎司黄金。\n\n三天后……他的电话打不通了。你去他说的办公室找，发现是个空房间。\n\n1盎司黄金，就这么没了。Mama B叹气：'中国老板，非洲的骗子比你想象的多。'\n\n【失去1oz黄金。karma-1。学到了一课。】",
            effect = function()
                playerData_.goldOunces = math.max(0, (playerData_.goldOunces or 0) - 1)
                playerData_.karma = playerData_.karma - 1
            end },
      },
    },
    { id = "world_tournament_invite",
      cond = function() return playerData_.day >= 35 and playerData_.reputation >= 150 and playerData_.totalTourney >= 3 end,
      type = "dialogue",
      title = "通往世界的门",
      dialogues = {
          { speaker = "旁白", text = "一封带着官方印章的邮件躺在你的收件箱里。发件人是——世界电子竞技协会(WECA)。" },
          { speaker = "旁白", text = "'尊敬的Dragon Force战队：基于贵队在非洲赛区的优异表现，我们正式邀请贵队参加第一届世界三角洲行动锦标赛(WDAC)。'" },
          { speaker = "旁白", text = "'比赛地点：上海。日期：下月15日。差旅及住宿由赛事方承担。'" },
          { speaker = "你", text = "（双手颤抖地放下手机）" },
          { speaker = "旁白", text = "你走到网吧中央，清了清嗓子。" },
          { speaker = "你", text = "兄弟们……我们收到了一封邀请函。" },
          { speaker = "你", text = "世界锦标赛。在上海。他们邀请我们代表非洲参赛。" },
          { speaker = "旁白", text = "三秒钟的寂静。然后——" },
          { speaker = "旁白", text = "整个网吧沸腾了。有人在喊，有人在哭，Big Joe把Kofi举过了头顶。Mama B在门口擦着眼泪说：'我就知道你们行的。'" },
          { speaker = "你", text = "（红了眼眶）从铁皮屋到上海……我们走了很远。但路还没走完。" },
          { speaker = "旁白", text = "Dragon Force，要去征服世界了。\n\n【全队技术+10，心情满值。声望+50。传奇，才刚刚开始。】" },
      },
      effect = function()
          for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 10); m.mood = 100 end
          playerData_.reputation = playerData_.reputation + 50; playerData_.money = playerData_.money + 300
      end,
    },

    -- =====================================================================
    -- 角色技能阈值专属剧情（8角色 × 3阈值 = 24事件）
    -- 每个角色根据初始技能和性格设定不同触发点
    -- =====================================================================

    -- ── Kofi（初始12）: 40 / 80 / 120 ──
    { id = "kofi_skill_40",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Kofi" and m.skill >= 40 then return true end end return false end,
      type = "dialogue", title = "闪电少年的觉醒",
      dialogues = {
          { speaker = "旁白", text = "训练结束，Kofi的手指在键盘上敲出了一串流畅的连招。他自己都愣住了。" },
          { speaker = "Kofi", text = "老板！你看到了吗？！我刚才那个操作——我以前骑自行车送快递都没这么快过！" },
          { speaker = "你", text = "不错，继续保持。" },
          { speaker = "旁白", text = "Kofi的眼睛亮了起来。曾经只会送快递的少年，正在蜕变为赛场上的闪电。\n\n【Kofi 技术突破！心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Kofi" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "kofi_skill_80",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Kofi" and m.skill >= 80 then return true end end return false end,
      type = "dialogue", title = "送快递的世界冠军",
      dialogues = {
          { speaker = "旁白", text = "Kofi在训练赛中打出了惊人的APM数据，甚至超过了一些职业选手。" },
          { speaker = "Kofi", text = "你们知道吗，骑单车送快递的时候要同时看路、躲车、算时间……原来这些全是训练反应速度！" },
          { speaker = "Grace", text = "所以你的反应速度是在车流里练出来的？……这也太野了吧。" },
          { speaker = "旁白", text = "街头的历练成了赛场的天赋，Kofi正在用自己的方式证明：英雄不问出处。\n\n【Kofi 声望+15，全队心情+5】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
      end,
    },
    { id = "kofi_skill_120",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Kofi" and m.skill >= 120 then return true end end return false end,
      type = "dialogue", title = "闪电之名",
      dialogues = {
          { speaker = "旁白", text = "国际赛事解说员在直播中给Kofi起了一个绰号——'非洲闪电'。弹幕疯狂刷屏。" },
          { speaker = "Kofi", text = "（看着手机，眼眶泛红）妈妈……你的儿子不再只是送快递的了。" },
          { speaker = "你", text = "你永远是送快递的Kofi，只是现在你送的是胜利。" },
          { speaker = "旁白", text = "Kofi的故事被非洲媒体广泛报道，激励了无数像他一样的年轻人。\n\n【Kofi 全属性提升！声望+25，$200】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Kofi" then m.skill = math.min(SKILL_CAP, m.skill + 5); m.mood = 100 end end
          playerData_.reputation = playerData_.reputation + 25; playerData_.money = playerData_.money + 200
      end,
    },

    -- ── Big Joe（初始8）: 35 / 70 / 110 ──
    { id = "bigjoe_skill_35",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Big Joe" and m.skill >= 35 then return true end end return false end,
      type = "dialogue", title = "巨熊的温柔",
      dialogues = {
          { speaker = "旁白", text = "Big Joe的大手指在小键盘上艰难地操作，但他的走位越来越精准了。" },
          { speaker = "Big Joe", text = "以前当保镖，要预判老板往哪走，替他挡子弹……现在就是替队友挡伤害嘛，一样的！" },
          { speaker = "你", text = "Joe，你天生就是个守护者。" },
          { speaker = "旁白", text = "Big Joe的前排意识让团队的生存率大幅提升。保镖的直觉，在赛场上同样管用。\n\n【Big Joe 心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Big Joe" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "bigjoe_skill_70",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Big Joe" and m.skill >= 70 then return true end end return false end,
      type = "dialogue", title = "铁壁之名",
      dialogues = {
          { speaker = "旁白", text = "在最近的比赛中，Big Joe创下了一个记录：全场零死亡。" },
          { speaker = "Snake", text = "这家伙……是真的打不死吗？我试了三种套路都抓不到他的破绽。" },
          { speaker = "Big Joe", text = "（憨笑）以前老板说，'你要是倒了，我也活不了。'所以我学会了——绝对不倒。" },
          { speaker = "旁白", text = "Big Joe获得了'铁壁'称号，对手闻风丧胆。\n\n【声望+15，全队心情+5】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
      end,
    },
    { id = "bigjoe_skill_110",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Big Joe" and m.skill >= 110 then return true end end return false end,
      type = "dialogue", title = "不可撼动的山",
      dialogues = {
          { speaker = "旁白", text = "国际赛场上，Big Joe的防守数据引起了多支豪门战队的注意。" },
          { speaker = "Big Joe", text = "老板，有人出高价想挖我走……但我不会去的。Dragon Force就是我的家。" },
          { speaker = "你", text = "Joe……谢谢你。" },
          { speaker = "旁白", text = "Big Joe拒绝了高薪邀约，他的忠诚让整个团队更加团结。\n\n【全队心情+10，Big Joe 技术+5，声望+20】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do
              m.mood = math.min(100, m.mood + 10)
              if m.name == "Big Joe" then m.skill = math.min(SKILL_CAP, m.skill + 5) end
          end
          playerData_.reputation = playerData_.reputation + 20
      end,
    },

    -- ── Grace（初始22）: 50 / 90 / 130 ──
    { id = "grace_skill_50",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Grace" and m.skill >= 50 then return true end end return false end,
      type = "dialogue", title = "暗夜中的玫瑰",
      dialogues = {
          { speaker = "旁白", text = "Grace在深夜的训练室里独自练习，屏幕的光映在她专注的脸上。" },
          { speaker = "Grace", text = "爸爸说女孩子不该打游戏……但我觉得，上帝给我这双手，不只是为了翻圣经。" },
          { speaker = "你", text = "你的天赋不该被任何人定义。" },
          { speaker = "旁白", text = "Grace的操作越来越凌厉，她在用实力回应所有的质疑。\n\n【Grace 心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Grace" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "grace_skill_90",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Grace" and m.skill >= 90 then return true end end return false end,
      type = "dialogue", title = "牧师的祝福",
      dialogues = {
          { speaker = "旁白", text = "Grace的父亲——那位严厉的牧师，第一次来到了网吧。" },
          { speaker = "Grace", text = "（紧张）爸爸……你怎么来了？" },
          { speaker = "牧师", text = "我看了你比赛的视频。Grace……你像你妈妈一样，做什么都全力以赴。" },
          { speaker = "Grace", text = "（哭了）爸爸……" },
          { speaker = "旁白", text = "牧师离开时留下了一句：'上帝保佑你赢。'Grace哭了很久，但笑容比以往更灿烂。\n\n【Grace 心情满值，声望+15】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Grace" then m.mood = 100 end end
          playerData_.reputation = playerData_.reputation + 15
      end,
    },
    { id = "grace_skill_130",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Grace" and m.skill >= 130 then return true end end return false end,
      type = "dialogue", title = "非洲女子电竞之光",
      dialogues = {
          { speaker = "旁白", text = "Grace被评选为'非洲年度最佳女子电竞选手'，她的故事登上了CNN。" },
          { speaker = "Grace", text = "记者问我怎么走到今天的。我说：'我有一个愿意赌在我身上的老板，和一群愿意陪我拼的兄弟。'" },
          { speaker = "旁白", text = "Grace成为了无数非洲女孩的榜样，证明了游戏没有性别界限。\n\n【声望+30，$300，Grace 技术+5】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Grace" then m.skill = math.min(SKILL_CAP, m.skill + 5) end end
          playerData_.reputation = playerData_.reputation + 30; playerData_.money = playerData_.money + 300
      end,
    },

    -- ── Snake（初始5）: 30 / 65 / 105 ──
    { id = "snake_skill_30",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Snake" and m.skill >= 30 then return true end end return false end,
      type = "dialogue", title = "毒蛇收起了獠牙",
      dialogues = {
          { speaker = "旁白", text = "Snake又一次在训练中和队友起了冲突。但这次，他主动道了歉。" },
          { speaker = "Snake", text = "……我知道我脾气差。但在街上混的时候，不凶就会被欺负。" },
          { speaker = "你", text = "这里不是街头。这里是你的队伍，你的兄弟。" },
          { speaker = "Snake", text = "（沉默了很久）……我试试。" },
          { speaker = "旁白", text = "Snake第一次在训练结束后没有摔键盘。这是一个小小的进步，却意义重大。\n\n【Snake 心情+15】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Snake" then m.mood = math.min(100, m.mood + 15) end end end,
    },
    { id = "snake_skill_65",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Snake" and m.skill >= 65 then return true end end return false end,
      type = "dialogue", title = "街头之王的蜕变",
      dialogues = {
          { speaker = "旁白", text = "在一场关键比赛中，Snake放弃了自己的击杀数，选择了掩护队友。" },
          { speaker = "Big Joe", text = "Snake！你刚才……你居然帮我挡了一发？！" },
          { speaker = "Snake", text = "别感动了，胖子。赢了比赛请我吃鸡就行。" },
          { speaker = "旁白", text = "毒蛇学会了团队合作。街头之王正在成为真正的战士。\n\n【全队心情+10，声望+10】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
          playerData_.reputation = playerData_.reputation + 10
      end,
    },
    { id = "snake_skill_105",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Snake" and m.skill >= 105 then return true end end return false end,
      type = "dialogue", title = "毒蛇的承诺",
      dialogues = {
          { speaker = "旁白", text = "Snake收到了曾经街头帮派的消息，让他回去'帮忙办事'。" },
          { speaker = "Snake", text = "老板。我以前的人找上来了，让我回去。" },
          { speaker = "你", text = "你怎么想？" },
          { speaker = "Snake", text = "（把手机摔在桌上）老子现在是职业选手，不是街头混混了。让他们滚。" },
          { speaker = "旁白", text = "Snake和过去彻底决裂。从此，他的毒只在赛场上释放。\n\n【Snake 心情满值，技术+5，声望+20】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Snake" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 5) end end
          playerData_.reputation = playerData_.reputation + 20
      end,
    },

    -- ── Mama B（初始35）: 55 / 85 / 115 ──
    { id = "mamab_skill_55",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Mama B" and m.skill >= 55 then return true end end return false end,
      type = "dialogue", title = "婆婆的秘密",
      dialogues = {
          { speaker = "旁白", text = "大家发现Mama B狙击命中率高得离谱，终于忍不住问了。" },
          { speaker = "Kofi", text = "Mama，你到底以前是干什么的？这枪法也太准了！" },
          { speaker = "Mama B", text = "（神秘一笑）年轻的时候，我在军队食堂工作。顺便……学了点别的。" },
          { speaker = "旁白", text = "没人知道Mama B的过去，但所有人都知道——惹她的人，没有好下场。\n\n【Mama B 心情+15】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Mama B" then m.mood = math.min(100, m.mood + 15) end end end,
    },
    { id = "mamab_skill_85",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Mama B" and m.skill >= 85 then return true end end return false end,
      type = "dialogue", title = "以烤鸡之名",
      dialogues = {
          { speaker = "旁白", text = "比赛解说员发现了一个有趣的数据：Mama B每次大招之前都会说'烤鸡熟了'。" },
          { speaker = "解说员", text = "观众朋友们！Mama B又说'烤鸡熟了'了！这意味着对面要凉了！" },
          { speaker = "Mama B", text = "烤鸡嘛，火候到了就该出炉。对手也一样。" },
          { speaker = "旁白", text = "'烤鸡熟了'成为了网络热梗，Mama B的粉丝暴涨。\n\n【声望+20，$150】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 20; playerData_.money = playerData_.money + 150
      end,
    },
    { id = "mamab_skill_115",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Mama B" and m.skill >= 115 then return true end end return false end,
      type = "dialogue", title = "永远的Mama",
      dialogues = {
          { speaker = "旁白", text = "赛后采访，记者问Mama B为什么这个年纪还在打比赛。" },
          { speaker = "Mama B", text = "因为这些孩子需要我。不是需要我的枪法——是需要有人在输了的时候说'没关系，明天再来'。" },
          { speaker = "你", text = "Mama……" },
          { speaker = "Mama B", text = "别哭了老板。走，我给你们烤鸡吃。赢了的庆功鸡，不一样的味道。" },
          { speaker = "旁白", text = "Mama B不只是狙击手，她是Dragon Force的灵魂。\n\n【全队心情满值，声望+20，Mama B 技术+3】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do
              m.mood = 100
              if m.name == "Mama B" then m.skill = math.min(SKILL_CAP, m.skill + 3) end
          end
          playerData_.reputation = playerData_.reputation + 20
      end,
    },

    -- ── Prince（初始15）: 45 / 85 / 125 ──
    { id = "prince_skill_45",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Prince" and m.skill >= 45 then return true end end return false end,
      type = "dialogue", title = "王子的面具",
      dialogues = {
          { speaker = "旁白", text = "Prince在训练中总是保持着一种疏离感，像是在刻意和大家保持距离。" },
          { speaker = "Prince", text = "在家族里，我不被允许输。每次输了……后果很严重。" },
          { speaker = "你", text = "这里不是你家。这里你可以输，可以再来。" },
          { speaker = "Prince", text = "（摘下了那条昂贵的项链，放在桌上）那我……就当个普通的队员试试。" },
          { speaker = "旁白", text = "Prince放下了王子的包袱，第一次以'队友'的身份融入了团队。\n\n【Prince 心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Prince" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "prince_skill_85",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Prince" and m.skill >= 85 then return true end end return false end,
      type = "dialogue", title = "酋长的来信",
      dialogues = {
          { speaker = "旁白", text = "Prince收到了一封来自家族的信，是他父亲——酋长亲笔写的。" },
          { speaker = "Prince", text = "（声音颤抖）'我的儿子，你选择了自己的路，这需要比继承王位更大的勇气。为父以你为傲。'" },
          { speaker = "旁白", text = "Prince在天台站了很久。回来的时候，他的眼神不一样了。" },
          { speaker = "Prince", text = "老板，明天的训练……能不能加练两小时？" },
          { speaker = "旁白", text = "得到父亲认可的Prince，爆发出了惊人的能量。\n\n【Prince 心情满值，技术+3，声望+15】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Prince" then m.mood = 100; m.skill = math.min(SKILL_CAP, m.skill + 3) end end
          playerData_.reputation = playerData_.reputation + 15
      end,
    },
    { id = "prince_skill_125",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Prince" and m.skill >= 125 then return true end end return false end,
      type = "dialogue", title = "自己的王国",
      dialogues = {
          { speaker = "旁白", text = "Prince用自己的比赛奖金在家乡建了一个电竞训练营，免费教贫困孩子打游戏。" },
          { speaker = "Prince", text = "我不需要继承父亲的王位。我要建自己的王国——用键盘和鼠标。" },
          { speaker = "旁白", text = "Prince的训练营为Dragon Force输送了源源不断的后备人才。\n\n【声望+30，$250，全队心情+5】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 30; playerData_.money = playerData_.money + 250
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
      end,
    },

    -- ── 小雪（初始28）: 55 / 95 / 135 ──
    { id = "xiaoxue_skill_55",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "小雪" and m.skill >= 55 then return true end end return false end,
      type = "dialogue", title = "远方的牵挂",
      dialogues = {
          { speaker = "旁白", text = "小雪在训练间隙接了一个视频电话，是她之前支教时候的学生们。" },
          { speaker = "小雪", text = "（对着手机）老师现在在非洲打比赛呢！你们好好学习，老师给你们赢奖杯回来！" },
          { speaker = "旁白", text = "挂了电话，小雪擦了擦眼角，然后坐回了电脑前，比之前更加认真。" },
          { speaker = "小雪", text = "好了，继续练。孩子们在看着我呢。" },
          { speaker = "旁白", text = "为了远方的孩子们，小雪的每一次训练都格外认真。\n\n【小雪 心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "小雪" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "xiaoxue_skill_95",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "小雪" and m.skill >= 95 then return true end end return false end,
      type = "dialogue", title = "跨国连线",
      dialogues = {
          { speaker = "旁白", text = "小雪利用直播平台，一边打比赛一边教非洲和中国的孩子们学编程。观众人数突破了十万。" },
          { speaker = "小雪", text = "你们看，写代码和打游戏一样，都是解决问题的过程。来，跟老师一起……" },
          { speaker = "旁白", text = "小雪成了'最会打游戏的支教老师'，两国媒体争相报道。\n\n【声望+20，$200】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 20; playerData_.money = playerData_.money + 200
      end,
    },
    { id = "xiaoxue_skill_135",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "小雪" and m.skill >= 135 then return true end end return false end,
      type = "dialogue", title = "两个世界的桥梁",
      dialogues = {
          { speaker = "旁白", text = "小雪收到了联合国教科文组织的邀请，请她分享'电竞教育在发展中国家的实践'。" },
          { speaker = "小雪", text = "老板……他们要我去日内瓦演讲。不过别担心，我讲完就赶回来打比赛！" },
          { speaker = "你", text = "去吧，这是比赢比赛更重要的事。" },
          { speaker = "旁白", text = "小雪用一个人的力量，在中国和非洲之间架起了一座电竞与教育的桥梁。\n\n【声望+35，$300，全队心情+10】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 35; playerData_.money = playerData_.money + 300
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
      end,
    },

    -- ── Thunder（初始3）: 25 / 60 / 100 ──
    { id = "thunder_skill_25",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Thunder" and m.skill >= 25 then return true end end return false end,
      type = "dialogue", title = "起跑线上的雷霆",
      dialogues = {
          { speaker = "旁白", text = "Thunder的反应速度测试数据出来了——0.11秒，接近人类极限。" },
          { speaker = "Thunder", text = "在田径场上，起跑慢0.01秒就是输。我的身体……已经被训练到极限了。" },
          { speaker = "你", text = "现在把这个极限用在游戏里。" },
          { speaker = "Thunder", text = "（微笑）以前是用腿跑，现在是用手指跑。换了条赛道而已。" },
          { speaker = "旁白", text = "Thunder的闪电反应开始在游戏中展现威力，对手的突袭几乎骗不到他。\n\n【Thunder 心情+20】" },
      },
      effect = function() for _,m in ipairs(teamMembers_) do if m.name == "Thunder" then m.mood = math.min(100, m.mood + 20) end end end,
    },
    { id = "thunder_skill_60",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Thunder" and m.skill >= 60 then return true end end return false end,
      type = "dialogue", title = "从赛道到赛场",
      dialogues = {
          { speaker = "旁白", text = "Thunder在比赛中展现了惊人的极限反应——在对手开枪的瞬间完成了闪避和反击。" },
          { speaker = "解说员", text = "不可思议！Thunder的反应速度已经超越了大部分职业选手！这是什么人类极限？！" },
          { speaker = "Thunder", text = "膝盖受伤让我离开了田径……但上帝关了一扇门，又开了一扇窗。" },
          { speaker = "旁白", text = "退役短跑选手的传奇故事，在电竞赛场上续写了新章。\n\n【声望+15，全队心情+5】" },
      },
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          for _,m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
      end,
    },
    { id = "thunder_skill_100",
      cond = function() for _,m in ipairs(teamMembers_) do if m.name == "Thunder" and m.skill >= 100 then return true end end return false end,
      type = "dialogue", title = "闪电永不停歇",
      dialogues = {
          { speaker = "旁白", text = "尼日利亚田径协会邀请Thunder担任'电竞体育大使'，表彰他跨界的成就。" },
          { speaker = "Thunder", text = "他们说我给退役运动员指了一条新路……其实是老板你给我指的路。" },
          { speaker = "你", text = "路是你自己跑出来的，Thunder。" },
          { speaker = "旁白", text = "Thunder的故事激励了无数受伤退役的运动员投身电竞，他们都叫他'电竞闪电'。\n\n【声望+25，$200，Thunder 技术+5】" },
      },
      effect = function()
          for _,m in ipairs(teamMembers_) do if m.name == "Thunder" then m.skill = math.min(SKILL_CAP, m.skill + 5) end end
          playerData_.reputation = playerData_.reputation + 25; playerData_.money = playerData_.money + 200
      end,
    },

    -- ── P1-7 Karma 双路线局（光明 / 黑暗）──
    -- 光明路线：karma >= 8，Grace 第20天后揭示人脉资源
    {
        id = "grace_light_path",
        cond = function()
            if (playerData_.day or 1) < 20 then return false end
            if not storyTriggered_["grace_secret"] then return false end
            if playerData_.karma == nil or playerData_.karma < 8 then return false end
            for _, m in ipairs(teamMembers_) do
                if m.name == "Grace" then return true end
            end
            return false
        end,
        type = "choice",
        title = "🌟 恩典的礼物",
        icon = "🌟",
        desc = "Grace找到了你，神情有些激动……",
        choices = {
            {
                text = "💡 让她牵线，尝试合作",
                result = function()
                    playerData_.money = playerData_.money + 500
                    playerData_.reputation = playerData_.reputation + 25
                    playerData_.karma = playerData_.karma + 2
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Grace" then
                            m.mood = math.min(100, m.mood + 20)
                            m.skill = math.min(SKILL_CAP, m.skill + 8)
                        end
                    end
                    AddLog("🌟 Grace的人脉资源带来了 $500 赞助，声望+25，Grace 技术+8。")
                    return "Grace笑得很灿烂：「老板，谢谢你从第一天就信任我。这些人脉，我早就想用来回报你了。」"
                end,
            },
            {
                text = "🙏 婉拒，不想麻烦她的关系网",
                result = function()
                    playerData_.karma = playerData_.karma + 1
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Grace" then
                            m.mood = math.min(100, m.mood + 10)
                        end
                    end
                    AddLog("🌟 你婉拒了Grace的好意，但她更尊重你了。Karma+1，Grace 心情+10。")
                    return "Grace眼里闪过一丝感动：「你真的很特别，老板。我在这里做的每一件事都值得。」"
                end,
            },
        },
        dialogues_prefix = {
            { speaker = "Grace", text = "老板，我……我有件事想跟你说。我爸爸认识几个企业赞助商，他们对我们战队很感兴趣。" },
            { speaker = "Grace", text = "我知道我一直没提，是因为……我不想靠关系走捷径。但现在我觉得，我们值得拥有更好的资源。" },
            { speaker = "你", text = "Grace，你确定这是你真心想做的，不是为了我？" },
            { speaker = "Grace", text = "（坚定地点头）我确定。你一直相信我，现在我想用行动来回报。" },
        },
    },
    -- 黑暗路线：karma <= -8，Snake 提出走暗门捷径
    {
        id = "snake_dark_path",
        cond = function()
            if (playerData_.day or 1) < 20 then return false end
            if playerData_.karma == nil or playerData_.karma > -8 then return false end
            for _, m in ipairs(teamMembers_) do
                if m.name == "Snake" then return true end
            end
            return false
        end,
        type = "choice",
        title = "🐍 蛇的提议",
        icon = "🐍",
        desc = "Snake把你拉到一个无人角落，低声说……",
        choices = {
            {
                text = "💰 接受，利益至上",
                result = function()
                    playerData_.money = playerData_.money + 800
                    playerData_.karma = playerData_.karma - 3
                    playerData_.reputation = math.max(0, playerData_.reputation - 10)
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Grace" then
                            m.mood = math.max(0, m.mood - 20)
                        end
                    end
                    AddLog("🐍 你接受了Snake的提议，得到 $800 但 Karma-3，声望-10，Grace 心情-20（她知道了）。")
                    return "Snake皮笑肉不笑：「聪明。兄弟，这条路走了就停不下来——但赢的感觉，你懂的。」"
                end,
            },
            {
                text = "🚫 拒绝，这不是我想要的胜利",
                result = function()
                    playerData_.karma = playerData_.karma + 3
                    for _, m in ipairs(teamMembers_) do
                        if m.name == "Snake" then
                            m.mood = math.max(0, m.mood - 10)
                        end
                    end
                    playerData_.reputation = playerData_.reputation + 5
                    AddLog("✋ 你拒绝了Snake，Karma+3，声望+5。Snake不满，但这是你的底线。")
                    return "你直视着Snake：「我们可以慢慢赢，但不能这样赢。」\n\nSnake沉默了很久，然后冷哼一声走开了。"
                end,
            },
        },
        dialogues_prefix = {
            { speaker = "Snake", text = "老板，我认识个人……他可以在下场比赛前拿到对手的战术情报。" },
            { speaker = "Snake", text = "钱的事好谈，$300 搞定。赢了比赛至少收回来十倍。你懂的。" },
            { speaker = "你", text = "……这不是正当渠道吧？" },
            { speaker = "Snake", text = "（冷笑）这个世界上有几个人靠正当渠道赢到顶的？老板，你最近日子也不好过。这是条捷径。" },
        },
    },

    -- ── P1-1 专精方向选择（第5天触发，且尚未选择）──
    {
        id = "specialization_choice",
        type = "choice",
        title = "🔱 经营方向抉择",
        icon = "🔱",
        desc = "你已经撑过了最难的头几天。现在，Big Joe 和两个街坊朋友围坐在你的网吧里，各自给出了不同的建议……",
        cond = function()
            return (playerData_.day or 1) >= 5
                and (playerData_.specChoiceDay or 0) == 0
        end,
        choices = {
            {
                text = "⚔️ 电竞路线 — 专注比赛训练，打出名气",
                result = function()
                    playerData_.specialization = "esports"
                    playerData_.specChoiceDay = playerData_.day
                    AddLog("⚔️ 【专精：电竞】你决定走电竞之路！比赛奖励 +30%，队员训练效率 +20%。")
                    return "Big Joe竖起大拇指：「好样的！只有打出名堂，街坊才真正尊重你。」"
                end,
            },
            {
                text = "☕ 休闲路线 — 打造舒适氛围，留住回头客",
                result = function()
                    playerData_.specialization = "casual"
                    playerData_.specChoiceDay = playerData_.day
                    AddLog("☕ 【专精：休闲】你选择做人气最旺的街坊聚点！日收入 +20%，客流上限 +5。")
                    return "Mama B笑道：「孩子，留住人心，钱就跟着来了。咖啡和音乐，是灵魂的食物。」"
                end,
            },
            {
                text = "💼 商贸路线 — 囤货转手，钱生钱",
                result = function()
                    playerData_.specialization = "trader"
                    playerData_.specChoiceDay = playerData_.day
                    AddLog("💼 【专精：商贸】你走上了商贸之路！黑市折扣 -20%，每日被动收入 +15$。")
                    return "Kwame压低声音：「兄弟，真正的财富从不靠苦力——让系统替你跑腿。」"
                end,
            },
        },
    },
}

pendingStoryEffect_ = nil  -- 剧情事件 effect（对话结束后执行）
pendingStoryMeta_   = nil  -- 剧情事件元数据（title, lastText）用于结果弹窗

--- 检查并触发一个剧情事件，返回 true 如果触发了
function TryTriggerStoryEvent()
    for _, evt in ipairs(STORY_EVENTS) do
        local condOk, condResult = pcall(evt.cond)
        if not condOk then
            log:Write(LOG_ERROR, "[StoryEvent] cond error id=" .. tostring(evt.id) .. ": " .. tostring(condResult))
            condResult = false
        end
        if not storyTriggered_[evt.id] and condResult then
            storyTriggered_[evt.id] = true
            RecordNPCEncounter(evt.title)  -- 剧情事件也记录 NPC 关系
            log:Write(LOG_INFO, "[StoryEvent] triggered id=" .. tostring(evt.id) .. " type=" .. tostring(evt.type) .. " day=" .. tostring(playerData_.day))
            if evt.type == "dialogue" then
                -- 剧情对话：用过场动画切入
                StartTransition(evt.title, "剧情", function()
                    currentDialogues_ = evt.dialogues
                    dialogueIndex_ = 1
                    -- 保存 effect 和元数据，对话结束时展示结果弹窗
                    pendingStoryEffect_ = evt.effect
                    local lastDlg = evt.dialogues[#evt.dialogues]
                    pendingStoryMeta_ = {
                        title = evt.title,
                        lastText = lastDlg and lastDlg.text or "",
                    }
                    local firstDlg2 = currentDialogues_[1]
                    if not firstDlg2 then
                        log:Write(LOG_ERROR, "[StoryEvent] dialogues[1] is nil for event: " .. tostring(evt.id))
                        currentPhase_ = PHASE_MANAGE; BuildUI(); return
                    end
                    local isMono2 = firstDlg2.type == "monologue"
                    CinematicDialogue.StartTypewriter(firstDlg2.text or "", isMono2)
                    StartTypewriter(firstDlg2.text or "")
                    PlayBGM("event")
                    currentPhase_ = PHASE_DIALOGUE
                    BuildUI()
                end)
            elseif evt.type == "choice" then
                -- 剧情选择：也用过场动画切入（防止在 onClick 回调中直接 BuildUI 导致 UI 框架状态损坏）
                StartTransition(evt.title, "剧情抉择", function()
                    currentEvent_ = evt
                    currentPhase_ = PHASE_EVENT
                    PlayBGM("event")
                    BuildUI()
                end)
            else
                -- 兜底：未知事件类型，回退到管理界面，防止黑屏
                log:Write(LOG_ERROR, "[StoryEvent] unknown type: " .. tostring(evt.type) .. " id=" .. tostring(evt.id))
                currentPhase_ = PHASE_MANAGE
                BuildUI()
            end
            return true
        end
    end
    return false
end

