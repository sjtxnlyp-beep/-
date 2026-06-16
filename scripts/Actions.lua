---@diagnostic disable: undefined-global
local CafeAnimEvents = require("CafeAnimEvents")
local MarketStorylines = require("MarketStorylines")

function UseActionPoint(cost)
    cost = cost or 1
    local ap = playerData_.actionPoints or 0
    if ap < cost then return false end
    playerData_.actionPoints = ap - cost
    -- 微反馈：AP消耗粒子
    pcall(MFX_APBurst, cost)
    -- RV2: 黄金时段触发检查（方案9）
    if RV2 and not RV2.IsGoldenHour() then
        pcall(RV2.TryTriggerGoldenHour)
    end
    -- RV2: 赛季通行证积分（每次行动+1分）
    if RV2 then pcall(RV2.AddSeasonPoints, 1, "行动消耗") end
    return true
end

--- RV2: 免费训练完成后的奖励结算（方案1）
function SettleFreeTrainReward(score)
    if not RV2 then return end
    local reward = RV2.CalcFreeMiniGameReward(score)
    playerData_.money = playerData_.money + reward.money
    playerData_.reputation = playerData_.reputation + reward.rep
    -- 连胜追踪
    if score > 0 then
        playerData_.miniGameStreak = (playerData_.miniGameStreak or 0) + 1
    else
        playerData_.miniGameStreak = 0
    end
    local msg = "🎮 免费训练完成！💰+$" .. reward.money .. " ⭐+" .. reward.rep
    if reward.streakBonus > 0 then
        msg = msg .. "（连胜x" .. reward.streakBonus .. " 加成！）"
    end
    AddLog(msg)
    playerData_.freeTrainMode = false
    -- 赛季积分
    pcall(RV2.AddSeasonPoints, 1, "免费训练")
end

function ScoutRecruit()
    local scoutCost = GetCityCost and GetCityCost(200) or 200
    -- 角色组合被动：招募费用折扣
    if ComboEvents then
        local dOk, disc = pcall(ComboEvents.GetRecruitDiscount)
        if dOk and disc and disc > 0 then
            scoutCost = math.max(50, math.floor(scoutCost * (1 - disc)))
        end
    end
    if playerData_.money < scoutCost or #CANDIDATE_POOL == 0 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - scoutCost
    pcall(MFX_MoneyPop, -scoutCost)
    AddLog("🔍 花了 $" .. scoutCost .. " 四处打听，看看有没有高手……")

    CafeAnimEvents.Push("scout")
    if math.random() < 0.75 then
        TriggerRecruitEvent()
    else
        AddLog("😕 这次没找到合适的人，钱白花了。")
        BuildUI()
    end
end

function RemoveFromCandidatePool(name)
    for i, c in ipairs(CANDIDATE_POOL) do
        if c.name == name then table.remove(CANDIDATE_POOL, i); return end
    end
end

--- 解雇队员（将其从战队移除，归还到候选池）
---@param idx number 队员在 teamMembers_ 中的索引
function DismissMember(idx)
    local m = teamMembers_[idx]
    if not m then return end
    local name = m.name
    -- 归还到候选池（保留成长后的属性）
    table.insert(CANDIDATE_POOL, m)
    table.remove(teamMembers_, idx)
    PlaySFX("click")
    AddLog("👋 " .. name .. " 离开了战队，也许以后还会再见。")
    BuildUI()
end

-- ========== v4 新行动 ==========

-- ═══════════════════════════════════════════════════════════════════════════
-- 集市特殊事件系统 v2
-- 架构：60%总触发率 → 从合格池中等权随机抽1个
-- 分层：通用可重复 / 队友可重复 / 感情线一次性 / 彩蛋一次性
-- ═══════════════════════════════════════════════════════════════════════════

--- 辅助：检查是否有指定队员
local function _HasTeammate(name)
    for _, m in ipairs(teamMembers_) do if m.name == name then return true end end
    return false
end

local MARKET_SPECIAL_EVENTS = {
    -- ══════════════════════════════════════════════════════════════
    -- 通用可重复层（无条件，任何时候都可能触发）
    -- ══════════════════════════════════════════════════════════════
    { id = "market_griot", oneTime = false,
      cond = function() return true end,
      icon = "🪘", title = "说书人的故事",
      narrative = "集市中央的大树下，一位白发苍苍的老人正在击鼓说书。周围围满了人。\n\n"
          .. "他讲的是一个年轻人离开家乡、在远方建立王国的故事。你听不懂约鲁巴语，但旁边有人翻译：\n\n"
          .. "「……他说，真正的财富不是金子，而是你身边愿意留下来的人。」\n\n"
          .. "你站着听完了整个故事。回去的路上，不知为什么觉得特别踏实。",
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
          return "😊 全队心情+5（故事的力量）"
      end,
    },
    { id = "market_bargain", oneTime = false,
      cond = function() return true end,
      icon = "🗣️", title = "砍价王",
      narrative = nil,
      effect = function()
          if math.random(1, 100) <= 55 then
              local earn = 60 + math.floor(playerData_.reputation / 12)
              playerData_.money = playerData_.money + earn
              playerData_.reputation = playerData_.reputation + 5
              return "💰 +$" .. earn .. " ⭐+5（砍价胜利！）"
          else
              playerData_.money = playerData_.money - 20
              return "💸 -$20（被大妈反杀了……）"
          end
      end,
      getNarrative = function(result)
          if result:find("胜利") then
              return "一个摊位上摆着成色不错的二手路由器。你随口问价——$120？太贵了。\n\n"
                  .. "你使出看家本领：先假装走开，然后被叫回来；再挑毛病，再假装不情愿……\n\n"
                  .. "三个回合后，大妈叹了口气：「行行行！就你最会讲价！$60拿走！」\n\n"
                  .. "你心里美滋滋的。这可是能转手大赚一笔的好货。"
          else
              return "一个摊位上摆着成色不错的二手路由器。你随口问价——$80？可以再便宜点吗？\n\n"
                  .. "大妈眯起眼睛：「年轻人，你看看这成色！别处你找不到的！」\n\n"
                  .. "一番拉扯后……你也不知道怎么回事，走出集市时手里多了一串你完全不需要的珠子，$20就这么没了。\n\n"
                  .. "回头看，大妈正对着你的背影笑。老江湖了。"
          end
      end,
    },
    { id = "market_lost", oneTime = false,
      cond = function() return true end,
      icon = "🌀", title = "迷路了",
      narrative = "你往集市深处走了一条从没走过的小巷——然后就彻底迷路了。\n\n"
          .. "七拐八绕之后，你发现一个僻静的小院子，里面竟然摆着各种手工艺品：木雕、蜡染布、串珠画……\n\n"
          .. "院子主人是个沉默的老奶奶，比划了半天，以极低的价格卖给你一块漂亮的蜡染布。\n\n"
          .. "你把它挂在网吧墙上——嘿，还真有那味了。",
      effect = function()
          playerData_.decoLevel = math.min(playerData_.decoLevel + 1, 10)
          playerData_.reputation = playerData_.reputation + 5
          return "🎨 装饰+1 ⭐声望+5（发现宝藏小院）"
      end,
    },
    { id = "market_barber", oneTime = false,
      cond = function() return true end,
      icon = "💇", title = "流动理发师",
      narrative = "一个推着小车的理发师热情地拦住你：「Oga! Come sit! I make you look like Wizkid!」\n\n"
          .. "你本想拒绝，但旁边几个大妈也在起哄：「让他剪！他手艺好！」\n\n"
          .. "半小时后你顶着一个从没尝试过的发型走出来。说实话——还挺潮的？\n\n"
          .. "回到网吧，队员们盯着你看了三秒，然后爆笑：「老板这是要去选秀吗？！」\n"
          .. "但当天来了好几个新顾客——都是在集市上见过你新发型的。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 8
          playerData_.money = playerData_.money - 15
          return "⭐ 声望+8 💸-$15（新发型出圈了）"
      end,
    },
    { id = "market_football_bet", oneTime = false,
      cond = function() return true end,
      icon = "⚽", title = "足球彩票",
      narrative = nil,
      effect = function()
          if math.random(1, 100) <= 45 then
              local win = 80 + math.random(20, 60)
              playerData_.money = playerData_.money + win
              return "💰 +$" .. win .. "（赢了！）"
          else
              playerData_.money = playerData_.money - 50
              return "💸 -$50（输了……）"
          end
      end,
      getNarrative = function(result)
          if result:find("赢") then
              return "集市角落有个足球下注摊，一群人围着看比赛。大屏幕上是非洲杯半决赛。\n\n"
                  .. "「Nigeria vs Ghana! 来一注！」摊主冲你招手。\n\n"
                  .. "你犹豫了一下，掏了$50押尼日利亚。最后10分钟——进了！！\n\n"
                  .. "「GOOOAAAL!」全场疯了。你挤出人群时口袋里鼓鼓的，今天运气不错。"
          else
              return "集市角落有个足球下注摊，一群人围着看比赛。大屏幕上是非洲杯半决赛。\n\n"
                  .. "「Nigeria vs Ghana! 来一注！」摊主冲你招手。\n\n"
                  .. "你掏了$50押尼日利亚。补时第3分钟——加纳绝杀了。\n\n"
                  .. "你看着摊主收走你的钱，他还安慰你：「Next time, oga! Next time!」\n下次个鬼啊……"
          end
      end,
    },
    { id = "market_food_stall", oneTime = false,
      cond = function() return true end,
      icon = "🍖", title = "绝味烤肉串",
      narrative = "一股令人窒息的香气把你拐进了一条小巷——一个从没见过的烤肉摊。\n\n"
          .. "摊主是个笑眯眯的大叔，炭火上滋滋作响的 Suya 肉串裹满了辣椒粉和花生碎。\n\n"
          .. "「来，尝一根！不好吃不要钱！」\n\n你咬了一口——味觉爆炸。辣、香、焦、嫩，全有了。\n\n"
          .. "你当场买了二十根打包回去。当晚训练时队员们吃得满嘴流油，士气高涨：\n「老板以后每天买！」",
      effect = function()
          playerData_.money = playerData_.money - 25
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 4) end
          return "😊 全队心情+4 💸-$25（美食的力量）"
      end,
    },
    { id = "market_fortune", oneTime = false,
      cond = function() return true end,
      icon = "🔮", title = "占卜师",
      narrative = nil,
      effect = function()
          local roll = math.random(1, 3)
          if roll == 1 then
              playerData_.trainBonus = (playerData_.trainBonus or 0) + 1
              return "🎯 下次训练效果+1（命运指引）"
          elseif roll == 2 then
              for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 6) end
              return "😊 全队心情+6（吉兆）"
          else
              playerData_.reputation = playerData_.reputation + 10
              return "⭐ 声望+10（贵人相助）"
          end
      end,
      getNarrative = function(result)
          if result:find("训练") then
              return "一个包着靛蓝头巾的老妇人坐在路边，面前摆着一堆贝壳和骨头。\n\n"
                  .. "她突然抬头看着你：「You! Sit down. The spirits have something for you.」\n\n"
                  .. "她把贝壳撒在布上，端详了许久：「Your hands will be blessed tomorrow. Whatever you do, do it with full heart.」\n\n"
                  .. "你半信半疑地走了。但第二天训练时，你确实觉得手感出奇地好。"
          elseif result:find("心情") then
              return "一个包着靛蓝头巾的老妇人坐在路边，面前摆着一堆贝壳和骨头。\n\n"
                  .. "她拉住你的手看了看掌纹，露出一个温暖的笑：\n\n"
                  .. "「Good fortune is coming. Your people——they are the right ones. Trust them.」\n\n"
                  .. "你不知道她说的准不准，但心里暖暖的。回去告诉队员们，大家都笑了：「老板被忽悠了吧！」\n但笑着笑着，气氛确实好了不少。"
          else
              return "一个包着靛蓝头巾的老妇人坐在路边，面前摆着一堆贝壳和骨头。\n\n"
                  .. "她闭着眼念了几句，然后睁开：「A powerful person will notice you soon. Be ready.」\n\n"
                  .. "你笑笑准备离开，她又加了一句：「Leave something for the spirits.」\n\n"
                  .. "你放了几块钱在她面前。说来奇怪，当天下午就有个商人主动找你谈合作。"
          end
      end,
    },
    { id = "market_musician", oneTime = false,
      cond = function() return true end,
      icon = "🎵", title = "街头乐手",
      narrative = "集市拐角处，一个瘦高个青年坐在翻过来的水桶上，弹着一把破旧的拇指琴。\n\n"
          .. "叮叮咚咚的声音出奇地好听。周围的人都停下脚步听，有人跟着节奏轻轻摇摆。\n\n"
          .. "他弹完一曲，冲你笑了笑：「Like it? This is the sound of home.」\n\n"
          .. "你丢了几块钱进他面前的破碗里。走出老远，旋律还在耳边转。\n晚上回到网吧，你哼着那个调子——队员们说你今天心情特别好。",
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 3) end
          playerData_.reputation = playerData_.reputation + 3
          return "😊 全队心情+3 ⭐+3（音乐治愈）"
      end,
    },
    { id = "market_phone_scam", oneTime = false,
      cond = function() return playerData_.day >= 5 end,
      icon = "📱", title = "充值骗局",
      narrative = "「Oga! Cheap data! 10GB only $20!」一个年轻人拿着一叠充值卡凑过来。\n\n"
          .. "价格确实便宜得离谱。你掏钱买了两张——回去一试，全是空卡。\n\n"
          .. "你气冲冲跑回去找人，那小子早跑没影了。旁边卖水的大姐同情地看着你：\n\n"
          .. "「Every new person falls for this one time. Now you know.」\n\n"
          .. "亏了钱，但长了教训。而且因为你在集市上\"义正辞严\"追人的样子，反而传出了\"这个老板不好欺负\"的名声。",
      effect = function()
          playerData_.money = playerData_.money - 30
          playerData_.reputation = playerData_.reputation + 10
          return "💸 -$30 ⭐+10（吃一堑长一智）"
      end,
    },

    -- ══════════════════════════════════════════════════════════════
    -- 队友可重复层（需特定队员在队）
    -- ══════════════════════════════════════════════════════════════
    { id = "market_kofi_delivery", oneTime = false,
      cond = function() return _HasTeammate("Kofi") end,
      icon = "🚲", title = "Kofi的副业",
      narrative = "远远地你看到一个熟悉的身影——Kofi骑着他那辆破单车在集市里穿梭，车后座绑着好几个包裹。\n\n"
          .. "「Kofi？你在送外卖？」你喊住他。\n\n"
          .. "他一脸尴尬地刹住车：「老板……我就是顺路帮人带点东西。我妈最近身体不好，医药费……」\n\n"
          .. "你拍拍他的肩：「以后别偷偷摸摸的了。训练完有空你就跑，我不扣你工资。」\n\n"
          .. "Kofi愣了一下，然后笑了——那种从心底冒出来的笑：「老板！我训练绝对更拼命！」",
      effect = function()
          for _, m in ipairs(teamMembers_) do
              if m.name == "Kofi" then m.mood = math.min(100, m.mood + 15); break end
          end
          playerData_.reputation = playerData_.reputation + 5
          return "😊 Kofi心情+15 ⭐+5（老板的温度）"
      end,
    },
    { id = "market_snake_contact", oneTime = false,
      cond = function() return _HasTeammate("Snake") end,
      icon = "🐍", title = "Snake的门路",
      narrative = nil,
      effect = function()
          if math.random(1, 100) <= 65 then
              local earn = 70 + math.random(30, 80)
              playerData_.money = playerData_.money + earn
              return "💰 +$" .. earn .. "（黑市好价）"
          else
              playerData_.money = playerData_.money - 40
              return "💸 -$40（这次翻车了）"
          end
      end,
      getNarrative = function(result)
          if result:find("好价") then
              return "转过一个巷子，你差点撞上Snake——他正在跟一个戴金牙的大哥低声说话。\n\n"
                  .. "看到你来了，Snake不慌不忙：「老板，来得正好。这位兄弟有批……呃，'渠道货'。显卡，便宜。」\n\n"
                  .. "你看了看成色——确实是好东西。Snake帮你砍了个绝低的价，大哥也给面子。\n\n"
                  .. "离开时Snake说：「在街上混过的人，总有几个用得着的朋友。」\n你想想也是，这种人脉确实买不到。"
          else
              return "转过一个巷子，你差点撞上Snake——他正在跟一个戴金牙的大哥低声说话。\n\n"
                  .. "「老板！有批好货！显卡！价格绝对美丽！」Snake信誓旦旦。\n\n"
                  .. "你掏了钱……回去一试，全是矿卡，跑两分钟就过热死机。\n\n"
                  .. "Snake挠挠头：「那个……下次我先验货。」\n你叹了口气——江湖有风险，跟着Snake淘货也是个技术活。"
          end
      end,
    },
    { id = "market_bigjoe_bodyguard", oneTime = false,
      cond = function() return _HasTeammate("Big Joe") end,
      icon = "🛡️", title = "Big Joe的威压",
      narrative = "集市里正走着，前面突然起了骚动——两帮人在对峙，眼看要动手。\n\n"
          .. "你正想绕道走，Big Joe不知从哪冒出来，往人群中间一站。\n\n"
          .. "他连话都没说，就那么站着。一米九的块头、满脸刀疤——两帮人看了他一眼，竟然各自散了。\n\n"
          .. "「Joe，你怎么在这？」\n\n"
          .. "「跟在你后面怕你出事。」他面无表情，「老板，这片最近不太平，你逛集市我跟着。」\n\n"
          .. "旁边目睹全程的摊主们纷纷点头：你家这位保镖，排面十足。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 12
          for _, m in ipairs(teamMembers_) do
              if m.name == "Big Joe" then m.mood = math.min(100, m.mood + 8); break end
          end
          return "⭐ 声望+12 😊Joe心情+8（大哥罩你）"
      end,
    },
    { id = "market_prince_spotted", oneTime = false,
      cond = function() return _HasTeammate("Prince") end,
      icon = "👑", title = "王子驾到",
      narrative = "你正路过一排摊位，突然所有摊主齐刷刷站了起来——\n\n"
          .. "原来Prince在你身后。他今天没化妆也没换衣服，但这片的人显然都认识他爸。\n\n"
          .. "「Oga Prince! Welcome! Anything you want, free free!」\n摊主们争先恐后献宝：最好的布料、最新鲜的水果、手工雕刻的木盒。\n\n"
          .. "Prince一脸无奈：「我不是来摆谱的……我就是跟老板逛逛。」\n\n"
          .. "但架不住热情——你们带着一大堆\"赠品\"回去了。Prince闷声说：\n「……我讨厌这种感觉。他们尊敬的是我爸，不是我。」\n\n"
          .. "你说：「等你拿了冠军，他们尊敬的就是你自己了。」他没说话，但走路的步子快了几分。",
      effect = function()
          playerData_.money = playerData_.money + 50
          playerData_.reputation = playerData_.reputation + 8
          for _, m in ipairs(teamMembers_) do
              if m.name == "Prince" then m.mood = math.min(100, m.mood + 10); break end
          end
          return "💰+$50 ⭐+8 😊Prince心情+10（酋长之子的烦恼）"
      end,
    },
    { id = "market_thunder_race", oneTime = false,
      cond = function() return _HasTeammate("Thunder") end,
      icon = "⚡", title = "闪电挑战",
      narrative = "集市中间一条直道上，几个年轻人正在比赛跑步。\n\n"
          .. "一个小伙看到Thunder，眼睛亮了：「Ey! Aren't you Thunder? The sprinter? Race me!」\n\n"
          .. "Thunder本想拒绝，但周围人越聚越多，全在起哄。他叹了口气脱掉外套——\n\n"
          .. "枪响（其实是有人拍了一下铁桶）。三秒后Thunder已经冲到了终点。\n\n"
          .. "那小伙还在半路呢。\n\n"
          .. "围观人群疯了：「He's still got it!!」\n\nThunder喘着气回来，脸上难得带着笑：「腿伤是腿伤，但这种距离……还行。」\n\n"
          .. "从此集市上多了个传说：Dragon网吧有个能跑过摩托车的人。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          for _, m in ipairs(teamMembers_) do
              if m.name == "Thunder" then m.mood = math.min(100, m.mood + 12); break end
          end
          return "⭐ 声望+15 😊Thunder心情+12（传说回归）"
      end,
    },
    { id = "market_mamab_recipe", oneTime = false,
      cond = function() return _HasTeammate("Mama B") end,
      icon = "🍗", title = "烤鸡对决",
      narrative = "集市上传来一阵骚动——两个烤鸡摊正在\"对线\"。一个是Mama B，对面是个年轻的小伙子。\n\n"
          .. "「你这个太辣了！客人不喜欢！」小伙挑衅。\nMama B 不慌不忙：「辣？我这叫有灵魂。你那个，白开水一样。」\n\n"
          .. "围观群众起哄：「比赛！比赛！」\n\n"
          .. "两人各烤了一份让大家盲评。结果——Mama B 以 7:3 碾压获胜。\n\n"
          .. "Mama B 得意地看了你一眼：「老板，看到没？你网吧请的人，哪个不是大佬。」\n小伙灰溜溜走了。你觉得网吧门口的烤鸡摊今晚得排长队了。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 10
          playerData_.money = playerData_.money + 30
          for _, m in ipairs(teamMembers_) do
              if m.name == "Mama B" then m.mood = math.min(100, m.mood + 10); break end
          end
          return "⭐+10 💰+$30 😊MamaB心情+10（烤鸡女王）"
      end,
    },
    { id = "market_teammate_bond", oneTime = false,
      cond = function() return #teamMembers_ >= 2 end,
      icon = "🤜", title = "队友日常",
      narrative = nil,
      effect = function()
          local m1 = teamMembers_[math.random(1, #teamMembers_)]
          local m2 = m1
          local attempts = 0
          while m2.name == m1.name and attempts < 10 do
              m2 = teamMembers_[math.random(1, #teamMembers_)]
              attempts = attempts + 1
          end
          m1.mood = math.min(100, m1.mood + 6)
          m2.mood = math.min(100, m2.mood + 6)
          return "😊 " .. m1.name .. "&" .. m2.name .. " 心情+6（兄弟情）"
      end,
      getNarrative = function(result)
          local scenes = {
              "你在集市拐角撞见两个队员蹲在一个摊位前——在看盗版漫画。\n\n"
                  .. "「老板！这不是……我们就是路过！」他们慌慌张张站起来。\n\n"
                  .. "你瞄了一眼——《灌篮高手》，嗯，品味不错。\n「看完记得回去训练。」你假装严肃地说。\n\n"
                  .. "他们对视一眼，偷笑出来。你走远后还能听到他们在讨论流川枫和三井谁更强。",
              "集市上人挤人，你正费劲往前走，突然听到前面传来熟悉的笑声——\n\n"
                  .. "两个队员在一个旧衣摊前互相比划T恤。一个举着件荧光绿的：「这个怎么样？比赛穿！」\n\n"
                  .. "另一个嫌弃地摆手：「穿这个上场对面直接闪瞎了还怎么打？」\n\n"
                  .. "你悄悄走开了。看到队员们自发地玩在一起，比什么团建活动都有用。",
              "你路过一个二手游戏摊，发现两个队员正在跟摊主激烈讨论——\n\n"
                  .. "「这张碟绝对是正版！」「大哥你这刻录痕迹明显的……」\n\n"
                  .. "最后他们凑钱买了一张存疑的盘，说要回去验证。\n\n"
                  .. "你摇摇头，但嘴角是上翘的——有这种共同爱好的队友，团队凝聚力差不了。",
          }
          return scenes[math.random(1, #scenes)]
      end,
    },
    { id = "market_dragon_chaos", oneTime = false,
      cond = function()
          return playerData_.npcStoryProgress and playerData_.npcStoryProgress.dragon_dog
              and playerData_.npcStoryProgress.dragon_dog >= 1
      end,
      icon = "🐕", title = "Dragon闯祸",
      narrative = nil,
      effect = function()
          if math.random(1, 100) <= 50 then
              playerData_.reputation = playerData_.reputation + 8
              return "⭐+8 🐕（Dragon意外圈粉）"
          else
              playerData_.money = playerData_.money - 25
              return "💸-$25 🐕（赔了人家的鸡）"
          end
      end,
      getNarrative = function(result)
          if result:find("圈粉") then
              return "你带Dragon逛集市——或者说，Dragon带你逛集市。\n\n"
                  .. "这条狗像个巡视领地的将军，在每个摊位前嗅一嗅，尾巴摇得像螺旋桨。\n\n"
                  .. "一个卖玩具的大姐被它逗得合不拢嘴：「This dog is a celebrity!」\n\n"
                  .. "还有小孩子排队要摸它。Dragon享受着万众瞩目，你觉得它活得比你潇洒多了。\n\n"
                  .. "临走时好几个摊主说：「下次再带它来！」——你不确定他们更欢迎你还是Dragon。"
          else
              return "你带Dragon逛集市——然后后悔了。\n\n"
                  .. "它突然挣脱绳子冲向一个活鸡摊位！鸡飞狗跳（字面意思），摊主大妈尖叫着追。\n\n"
                  .. "等你抓住Dragon时，它嘴里叼着一根鸡毛，无辜地看着你。摊上三只鸡跑了两只。\n\n"
                  .. "大妈义正辞严地要赔偿。你掏出钱包的手都在抖——不是心疼钱，是丢人。\n\n"
                  .. "Dragon在旁边打了个哈欠。它没有一点愧疚之心。"
          end
      end,
    },

    -- ══════════════════════════════════════════════════════════════
    -- 感情线一次性层（需bonds + stage条件）
    -- ══════════════════════════════════════════════════════════════
    { id = "market_xiaoxue_teach", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.xiaoxue then return false end
          return playerData_.bonds.xiaoxue.stage >= 1
      end,
      icon = "📖", title = "集市角落的课堂",
      narrative = "集市边缘的大树下，你看到了一个意想不到的画面——\n\n"
          .. "小雪蹲在地上，面前围着五六个黑人小孩，正在用树枝在沙地上教他们写字。\n\n"
          .. "「A——Apple。B——Ball。」孩子们跟着她大声念，发音千奇百怪但笑得灿烂。\n\n"
          .. "你站在远处看了很久。阳光透过树叶洒下来，她笑起来的样子——你突然觉得，这大概就是她来非洲的意义。\n\n"
          .. "小雪余光瞟到了你，愣了一下，然后耳朵红了：「你……你看了多久？」\n\n"
          .. "「刚到。」你撒了谎。「走吧，回去了。」\n她小跑几步跟上来，嘴角压不住地上翘。",
      effect = function()
          if playerData_.bonds and playerData_.bonds.xiaoxue then
              playerData_.bonds.xiaoxue.affinity = math.min(100, playerData_.bonds.xiaoxue.affinity + 4)
              playerData_.bonds.xiaoxue.lastInteractDay = playerData_.day
          end
          return "💕 小雪好感+4（心动的瞬间）"
      end,
    },
    { id = "market_xiaoxue_rescue", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.xiaoxue then return false end
          return playerData_.bonds.xiaoxue.stage >= 2
      end,
      icon = "🌸", title = "集市偶遇·小雪",
      narrative = "正要离开集市，你听到一个熟悉的声音——\n\n"
          .. "「不是！我给过钱了！You already took my money！」\n\n"
          .. "循声一看：小雪被一个摊主拦住了，对方咬定她没付款。小雪急得脸通红，翻遍包也找不到收据。\n\n"
          .. "你走过去，用当地语跟摊主交涉。几句话后摊主就怂了——显然是看她外国人面孔想讹一笔。\n\n"
          .. "「你怎么在这？」小雪松了口气，眼圈都红了，「我以为……没人会帮我。」\n\n"
          .. "「你忘了？你老板在这片有头有脸的。」你故作轻松。她破涕为笑，用力点了点头。\n\n"
          .. "回去的路上她一直跟在你旁边，比平时近了半步。",
      effect = function()
          playerData_.money = playerData_.money - 20
          if playerData_.bonds and playerData_.bonds.xiaoxue then
              playerData_.bonds.xiaoxue.affinity = math.min(100, playerData_.bonds.xiaoxue.affinity + 5)
              playerData_.bonds.xiaoxue.lastInteractDay = playerData_.day
          end
          return "💕 小雪好感+5 💸-$20（解围）"
      end,
    },
    { id = "market_xiaoxue_date", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.xiaoxue then return false end
          return playerData_.bonds.xiaoxue.stage >= 3
              and playerData_.marketTriggered
              and playerData_.marketTriggered["market_xiaoxue_rescue"]
      end,
      icon = "🍡", title = "一起逛集市",
      narrative = "今天刚到集市入口，就看到小雪站在那里东张西望。\n\n"
          .. "「你也来逛集市？」你走过去。\n「嗯！我想买……呃，一些东西。」她的耳尖肉眼可见地红了。\n\n"
          .. "你们并肩走过一个个摊位。她对所有东西都好奇：非洲鼓、手编凉鞋、五颜六色的调料粉。\n\n"
          .. "在一个烤玉米摊前，她买了两根——递一根给你：「尝尝！比国内的甜好多！」\n\n"
          .. "玉米确实甜。但你觉得可能不只是玉米的缘故。\n\n"
          .. "离开时她小声说：「下次……能不能再一起来？」",
      effect = function()
          if playerData_.bonds and playerData_.bonds.xiaoxue then
              playerData_.bonds.xiaoxue.affinity = math.min(100, playerData_.bonds.xiaoxue.affinity + 6)
              playerData_.bonds.xiaoxue.lastInteractDay = playerData_.day
          end
          return "💕 小雪好感+6（心里甜甜的）"
      end,
    },
    { id = "market_xiaoxue_gift", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.xiaoxue then return false end
          return playerData_.bonds.xiaoxue.stage >= 4
              and playerData_.marketTriggered
              and playerData_.marketTriggered["market_xiaoxue_date"]
      end,
      icon = "🎁", title = "小雪的礼物",
      narrative = "你刚逛完集市准备走，口袋里的手机震了一下——小雪发来消息：\n\n"
          .. "「你今天去集市了吗？出来的时候左手边第三个摊位……有个东西帮我拿一下。我付过钱了。」\n\n"
          .. "你半信半疑地走过去，摊主递给你一个布袋子：「你女朋友上午来订的。」\n\n"
          .. "你说她不是——算了。打开一看：一条手编的彩色手绳，非洲风格的编织纹路，尾端坠着一颗蓝色珠子。\n\n"
          .. "手机又响了：「那个……就是谢谢你一直照顾我。戴不戴随你啦。」\n\n"
          .. "你把手绳套在手腕上。蓝珠子在阳光下一闪一闪的，和她的名字一样清亮。",
      effect = function()
          if playerData_.bonds and playerData_.bonds.xiaoxue then
              playerData_.bonds.xiaoxue.affinity = math.min(100, playerData_.bonds.xiaoxue.affinity + 8)
              playerData_.bonds.xiaoxue.lastInteractDay = playerData_.day
          end
          return "💕 小雪好感+8（你戴上了那条手绳）"
      end,
    },
    { id = "market_grace_intro", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.grace then return false end
          return playerData_.bonds.grace.stage >= 2
      end,
      icon = "💼", title = "Grace的合作伙伴",
      narrative = "你正在集市里闲逛，一个声音从背后传来——\n\n"
          .. "「Hey！老板！」Grace 穿着一身干练的商务装从人群中走出来，身后跟着一个戴金链子的大哥。\n\n"
          .. "「来来来，介绍一下——这是 Kwame，电子配件批发商。我跟他提过你。」\n\n"
          .. "Kwame 上下打量你一番，咧嘴一笑：「Grace 说你网吧生意不错？以后设备配件找我，给你批发价。」\n\n"
          .. "Grace 在旁边微微一笑：「我可是帮了你大忙吧？」她的语气里有几分得意，又有几分……别的什么。\n\n"
          .. "你发现她今天画了淡妆。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 15
          if playerData_.bonds and playerData_.bonds.grace then
              playerData_.bonds.grace.affinity = math.min(100, playerData_.bonds.grace.affinity + 4)
              playerData_.bonds.grace.lastInteractDay = playerData_.day
          end
          return "💕 Grace好感+4 ⭐声望+15（人脉扩展）"
      end,
    },
    { id = "market_grace_fashion", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.grace then return false end
          return playerData_.bonds.grace.stage >= 2
              and playerData_.marketTriggered
              and playerData_.marketTriggered["market_grace_intro"]
      end,
      icon = "👗", title = "非洲的颜色",
      narrative = "集市布料区，你远远看到Grace站在一个摊位前，身上披着一块鲜艳的Ankara布料。\n\n"
          .. "那块布是大胆的橙红配金色，印着抽象的几何纹样。Grace对着一面小镜子左看右看。\n\n"
          .. "「适合你。」你走过去说了一句。\n\n"
          .. "她显然没料到你在这，一瞬间的错愕后迅速恢复了招牌的沉稳：\n「你觉得？这种风格会不会太……张扬了？」\n\n"
          .. "「你本来就张扬。」\n\n"
          .. "Grace愣了半秒，然后低下头笑了——一种你从没见过的、少女般的笑：\n「……那我买了。」\n\n"
          .. "她转身付钱时你注意到她耳朵尖是红的。你假装没看见。",
      effect = function()
          if playerData_.bonds and playerData_.bonds.grace then
              playerData_.bonds.grace.affinity = math.min(100, playerData_.bonds.grace.affinity + 5)
              playerData_.bonds.grace.lastInteractDay = playerData_.day
          end
          return "💕 Grace好感+5（她难得的柔软一面）"
      end,
    },
    { id = "market_grace_deal", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.grace then return false end
          return playerData_.bonds.grace.stage >= 3
              and playerData_.marketTriggered
              and playerData_.marketTriggered["market_grace_intro"]
      end,
      icon = "🤝", title = "联手砍价",
      narrative = "Grace 拉着你去一个二手显示器摊位：「那批货我盯了很久，今天杀价需要你配合。」\n\n"
          .. "她制定了战术：你扮演\"有很多选择的大老板\"，她扮演\"精打细算的军师\"。\n\n"
          .. "三轮谈判后，摊主从$200降到$120。Grace 冲你挑了挑眉：「看到了吗？这就叫配合。」\n\n"
          .. "你笑：「你应该来我网吧当经理。」\n\n"
          .. "她顿了一下，然后轻轻笑了：「……再说吧。」\n\n"
          .. "你们抬着显示器往回走，夕阳把两个人的影子拉得老长。",
      effect = function()
          playerData_.money = playerData_.money + 80
          if playerData_.bonds and playerData_.bonds.grace then
              playerData_.bonds.grace.affinity = math.min(100, playerData_.bonds.grace.affinity + 5)
              playerData_.bonds.grace.lastInteractDay = playerData_.day
          end
          return "💕 Grace好感+5 💰+$80（完美配合）"
      end,
    },
    { id = "market_grace_past", oneTime = true,
      cond = function()
          if not playerData_.bonds or not playerData_.bonds.grace then return false end
          return playerData_.bonds.grace.stage >= 4
              and playerData_.marketTriggered
              and playerData_.marketTriggered["market_grace_deal"]
      end,
      icon = "🌅", title = "Grace的秘密",
      narrative = "夕阳西下的集市，你和Grace并肩走着。今天人少，出奇地安静。\n\n"
          .. "Grace突然开口：「你有没有想过……为什么一个拉各斯大学的高材生，会来这种小镇打电竞？」\n\n"
          .. "你没说话，等她继续。\n\n"
          .. "「我爸是牧师。他觉得女孩子应该嫁人、生孩子、在教堂唱诗班唱歌。」她笑了一声，很苦。\n\n"
          .. "「我考上了拉各斯最好的大学，学了计算机。他说我叛逆。我打电竞赚了第一笔奖金寄回家——他把钱退了回来。」\n\n"
          .. "她顿了很久。「所以你问我为什么在这。因为……这是唯一一个没有人用'应该'来定义我的地方。」\n\n"
          .. "你说：「在我这里，你就是Grace。别的不重要。」\n\n"
          .. "她看了你很久很久，然后轻轻说了两个字：「谢谢。」\n声音很小。但你听见了。",
      effect = function()
          if playerData_.bonds and playerData_.bonds.grace then
              playerData_.bonds.grace.affinity = math.min(100, playerData_.bonds.grace.affinity + 10)
              playerData_.bonds.grace.lastInteractDay = playerData_.day
          end
          return "💕 Grace好感+10（她终于对你敞开心扉）"
      end,
    },

    -- ══════════════════════════════════════════════════════════════
    -- 彩蛋一次性层（高条件稀有）
    -- ══════════════════════════════════════════════════════════════
    { id = "market_wedding", oneTime = true,
      cond = function()
          return playerData_.day >= 20 and (playerData_.karma or 0) >= 5
      end,
      icon = "🎉", title = "误闯婚礼",
      narrative = "你走错了一个路口——突然被一群盛装打扮的人围住了。\n\n"
          .. "音乐声震天响，五颜六色的布料在风中飘扬。一个大妈热情地拉住你：\n"
          .. "「Come! Come! We celebrate!」\n\n"
          .. "原来隔壁正在办婚礼。你被拉进人群，被迫学跳了一支当地舞蹈。\n"
          .. "新郎新娘看到你这个外国人加入特别开心，非要让你坐主桌。\n\n"
          .. "你吃了一顿此生最丰盛的非洲宴席，还收到了一块写着祝福语的布料当礼物。\n\n"
          .. "回到网吧，你把布料挂在门口。队员们围过来：「老板去哪嗨了？！」",
      effect = function()
          playerData_.reputation = playerData_.reputation + 20
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
          return "⭐声望+20 😊全队心情+10（非洲婚礼！）"
      end,
    },
    { id = "market_celebrity", oneTime = true,
      cond = function()
          return playerData_.day >= 30 and playerData_.reputation >= 80
      end,
      icon = "📺", title = "意外成名",
      narrative = "你正在挑水果，突然一个扛着摄像机的人冲了过来——\n\n"
          .. "「You are the Dragon Net Cafe boss, right?! We heard about your esports team!」\n\n"
          .. "原来是当地电视台在做\"小镇创业者\"专题。记者把话筒怼到你脸前：\n\n"
          .. "「How does a Chinese man build an esports empire in Africa?」\n\n"
          .. "你完全没准备，支支吾吾说了几句。记者激动得不行：「Great! Very inspiring!」\n\n"
          .. "第二天节目播了。你的手机被打爆了——包括三个想来谈赞助的商人。\n队员们在网吧围着电视回放笑得前仰后合：「老板这表情太搞了！」",
      effect = function()
          playerData_.reputation = playerData_.reputation + 30
          playerData_.money = playerData_.money + 200
          return "⭐声望+30 💰+$200（赞助商找上门）"
      end,
    },
    { id = "market_old_friend", oneTime = true,
      cond = function()
          return playerData_.day >= 40 and #teamMembers_ >= 4
      end,
      icon = "🇨🇳", title = "老乡来了",
      narrative = "你正在集市闲逛，突然一个熟悉的语调传来——\n\n"
          .. "「卧槽？中国人？你也在这鬼地方？！」\n\n"
          .. "回头一看：一个晒得黢黑的中年大哥，穿着\"中国建设\"的工服，满脸惊喜。\n\n"
          .. "「兄弟，我修路的，在这三年了。听说附近有个中国人开网吧，没想到真碰上了！」\n\n"
          .. "你俩站在路边聊了快一个小时——从家乡菜到春节，从非洲见闻到各自的孤独。\n\n"
          .. "临走时他说：「下周带我们工地的弟兄去你那上网。二十多号人，有折扣没？」\n\n"
          .. "你笑：「老乡来了还收什么钱。半价！」\n\n"
          .. "他拍着你肩膀：「兄弟，在这边不容易。互相照应着。」\n\n"
          .. "你鼻子有点酸。好久没听到乡音了。",
      effect = function()
          playerData_.money = playerData_.money + 150
          playerData_.reputation = playerData_.reputation + 15
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
          return "💰+$150 ⭐+15 😊全队+5（他乡遇故知）"
      end,
    },
    { id = "market_baobao_hustle", oneTime = true,
      cond = function()
          return playerData_.day >= 15 and playerData_.reputation >= 40
      end,
      icon = "🧳", title = "包包哥的生意经",
      narrative = "集市最热闹的十字路口，你看到了包包哥——他正在摆摊卖……手机壳？\n\n"
          .. "「哟！老板来了！」他热情地招呼你，「看看，义乌进的货，成本两块五，这边卖$5一个！」\n\n"
          .. "你凑过去看：一堆花花绿绿的手机壳，居然还有印着非洲领导人头像的款式。\n\n"
          .. "「这你怎么想到的？」\n\n"
          .. "包包哥得意地笑：「在非洲做生意，得接地气！我还有一批印国旗的充电宝，你要不要在网吧代卖？分你三成！」\n\n"
          .. "你看着他那精明的笑脸，不得不承认——浙江人做生意确实有一套。\n最后你答应了。反正网吧柜台空着也是空着。",
      effect = function()
          playerData_.money = playerData_.money + 60
          playerData_.reputation = playerData_.reputation + 8
          return "💰+$60 ⭐+8（浙商的智慧）"
      end,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
--- 检查集市特殊事件触发（v2：60%总触发率 + 等权抽取）
-- ═══════════════════════════════════════════════════════════════════════════
function CheckMarketSpecialEvent()
    -- 60% 总触发率：先决定是否触发特殊事件
    if math.random(1, 100) > 60 then return nil end

    -- 确保存在 marketTriggered 记录表
    playerData_.marketTriggered = playerData_.marketTriggered or {}
    -- 记忆窗口：最近3次触发的事件ID，防止连续重复
    playerData_.marketRecentIds = playerData_.marketRecentIds or {}

    -- 构建候选列表（满足条件的事件）
    local candidates = {}
    for _, evt in ipairs(MARKET_SPECIAL_EVENTS) do
        -- 一次性事件检查是否已触发
        if evt.oneTime and playerData_.marketTriggered[evt.id] then
            goto continue
        end
        -- 条件检查
        if evt.cond and not evt.cond() then
            goto continue
        end
        table.insert(candidates, evt)
        ::continue::
    end

    if #candidates == 0 then return nil end

    -- 短期记忆：从候选中排除最近3次触发的事件（一次性事件不受此限制，本来就不会重复）
    local freshCandidates = {}
    local recentSet = {}
    for _, rid in ipairs(playerData_.marketRecentIds) do recentSet[rid] = true end
    for _, evt in ipairs(candidates) do
        if evt.oneTime or not recentSet[evt.id] then
            table.insert(freshCandidates, evt)
        end
    end
    -- 降级：如果排除后为空（极端情况），退回全池
    if #freshCandidates > 0 then candidates = freshCandidates end

    -- 优先级：感情线一次性 > 彩蛋一次性 > 等权随机
    local chosen = nil

    -- 感情线一次性事件（小雪优先）
    local romanceCandidates = {}
    for _, evt in ipairs(candidates) do
        if evt.oneTime and (evt.id:find("xiaoxue") or evt.id:find("grace")) then
            table.insert(romanceCandidates, evt)
        end
    end
    if #romanceCandidates > 0 then
        chosen = romanceCandidates[math.random(1, #romanceCandidates)]
    end

    -- 其他一次性事件
    if not chosen then
        local oneTimeCandidates = {}
        for _, evt in ipairs(candidates) do
            if evt.oneTime then
                table.insert(oneTimeCandidates, evt)
            end
        end
        if #oneTimeCandidates > 0 and math.random(1, 100) <= 40 then
            chosen = oneTimeCandidates[math.random(1, #oneTimeCandidates)]
        end
    end

    -- 等权随机（从所有候选中抽）
    if not chosen then
        chosen = candidates[math.random(1, #candidates)]
    end

    -- 更新记忆窗口（滑动保留最近3次，展现事件丰富度）
    table.insert(playerData_.marketRecentIds, chosen.id)
    if #playerData_.marketRecentIds > 3 then
        table.remove(playerData_.marketRecentIds, 1)
    end

    -- 标记已触发
    if chosen.oneTime then
        playerData_.marketTriggered[chosen.id] = true
        -- 感情线事件同步到 bonds.triggered
        if chosen.id:find("xiaoxue") and playerData_.bonds and playerData_.bonds.xiaoxue then
            playerData_.bonds.xiaoxue.triggered = playerData_.bonds.xiaoxue.triggered or {}
            playerData_.bonds.xiaoxue.triggered[chosen.id] = true
        elseif chosen.id:find("grace") and playerData_.bonds and playerData_.bonds.grace then
            playerData_.bonds.grace.triggered = playerData_.bonds.grace.triggered or {}
            playerData_.bonds.grace.triggered[chosen.id] = true
        end
    end

    -- 执行效果
    local effectStr = ""
    if chosen.effect then
        effectStr = chosen.effect() or ""
    end

    -- 叙事文本（支持动态生成）
    local narrativeText = chosen.narrative
    if chosen.getNarrative then
        narrativeText = chosen.getNarrative(effectStr)
    end

    -- 特殊动画
    if chosen.id:find("xiaoxue") then
        CafeAnimEvents.Push("market_xiaoxue")
    elseif chosen.id:find("grace") then
        CafeAnimEvents.Push("market_grace")
    elseif chosen.id == "market_wedding" then
        CafeAnimEvents.Push("market_wedding")
    end

    return {
        icon = chosen.icon,
        title = chosen.title,
        narrative = narrativeText,
        effects = effectStr,
    }
end

-- ── 集市基础故事池（10个独立故事，替代旧的roll分段）──
local MARKET_BASE_STORIES = {
    {
        id = "base_keyboard", icon = "⌨️", title = "淘到好货",
        narrative = "集市角落，一个大叔正在收拾摊位。你眼尖，一眼认出那堆破纸箱里藏着几套品质不错的二手键鼠。\n\n"
            .. "「这些不要了？」你随口一问。\n「拿走拿走，占地方！」\n\n"
            .. "你花了点小钱收下，回去擦干净一摆——嘿，比新的还好用。转手就有人来买。",
        apply = function()
            local earn = 80 + math.floor(playerData_.reputation / 8)
            playerData_.money = playerData_.money + earn
            return "💰 +$" .. earn
        end,
    },
    {
        id = "base_mask", icon = "🎭", title = "非洲面具",
        narrative = "一位老匠人的摊位吸引了你的目光——几十个手工雕刻的木制面具，每一个都表情各异。\n\n"
            .. "你挑了一个龇牙咧嘴的战士面具挂在网吧门口。\n\n"
            .. "「老板这面具好凶啊！」「酷！拍个照发朋友圈！」\n路过的人纷纷驻足，还有人专程来打卡。",
        apply = function()
            local repGain = 10 + math.floor((playerData_.decoLevel or 0) * 5)
            playerData_.reputation = playerData_.reputation + repGain
            playerData_.decoLevel = math.min((playerData_.decoLevel or 0) + 1, #UPGRADES.deco.costs)
            return "⭐ 声望+" .. repGain
        end,
    },
    {
        id = "base_bracelet", icon = "📿", title = "特色手链",
        cond = function() return #teamMembers_ > 0 end,
        narrative = function()
            local m = teamMembers_[math.random(1, #teamMembers_)]
            local boost = 15 + math.floor((100 - m.mood) / 5)
            m.mood = math.min(100, m.mood + boost)
            return "逛着逛着，你在一个珠宝摊看到了一条编着彩色珠子的手链，上面刻着当地部落的祝福图案。\n\n"
                .. "你想起 " .. m.name .. " 最近状态不太好，顺手买了一条带回去。\n\n"
                .. "「这……给我的？」" .. m.name .. " 有点惊讶，然后咧嘴一笑，立刻戴上了。\n"
                .. "「老板，今天训练我绝对不偷懒！」",
                "😊 " .. m.name .. " 心情+" .. boost
        end,
    },
    {
        id = "base_havoc", icon = "🪙", title = "低价哈弗币",
        narrative = "集市入口处，一个戴墨镜的年轻人鬼鬼祟祟凑过来：\n\n"
            .. "「老板，要哈弗币不？我刚跑了一晚上，急出手，便宜卖！」\n\n"
            .. "你验了验货——确实是真的。一番讨价还价后以市场价七折成交。\n"
            .. "做完交易，他骑着摩托一溜烟跑了。这非洲地下经济，还真是无处不在。",
        apply = function()
            local coins = 40 + math.floor(playerData_.reputation / 10)
            playerData_.havocCoins = playerData_.havocCoins + coins
            return "🪙 哈弗币+" .. coins
        end,
    },
    {
        id = "base_merchant", icon = "✨", title = "稀有商人",
        narrative = "你正准备回去，集市最深处一个你从没见过的摊位突然出现。\n\n"
            .. "摊主是个穿着考究的中年人，摊上摆着各种电竞周边——定制鼠标垫、战队T恤、RGB灯带。\n\n"
            .. "「你是开网吧的？」他一眼认出你，「我有批货，在非洲卖不掉，你要的话成本价给你。」\n\n"
            .. "你一口答应。回去挂上架，当天就被网吧客人抢光了。\n这种好运，可不是天天都有。",
        apply = function()
            local bonus = 150 + math.random(50, 100)
            playerData_.money = playerData_.money + bonus
            playerData_.reputation = playerData_.reputation + 10
            return "💰 +$" .. bonus .. "  ⭐ 声望+10"
        end,
    },
    {
        id = "base_spice", icon = "🌶️", title = "香料贩子",
        narrative = "一位胖胖的大婶正吃力地搬着好几箱香料。你顺手帮了一把。\n\n"
            .. "「哎呀谢谢你！中国老板是吧？」她擦擦汗，从箱子里抓了一大把辣椒和咖喱粉塞给你。\n\n"
            .. "「拿去拿去！以后来集市找Auntie Fati，给你最低价！」\n\n"
            .. "你拎着香料回网吧，Mama B看到两眼放光——「这个做jollof rice绝了！」",
        apply = function()
            local earn = 60 + math.random(20, 50)
            playerData_.money = playerData_.money + earn
            return "💰 +$" .. earn .. "（省下采购费）"
        end,
    },
    {
        id = "base_oware", icon = "🎲", title = "棋盘赌局",
        narrative = "集市大树下，几个老头正围坐着玩oware棋。看你驻足观望，一个白胡子老头招手：\n\n"
            .. "「年轻人，来一局？赢了请你喝棕榈酒，输了……请我喝。」\n\n"
            .. "你坐下来——这局面，和打三角洲的博弈还真有几分相似。",
        apply = function()
            if math.random(1, 100) <= 55 then
                local win = 50 + math.random(30, 80)
                playerData_.money = playerData_.money + win
                playerData_.reputation = playerData_.reputation + 5
                return "💰 +$" .. win .. " ⭐+5（赢了！老头竖起拇指）"
            else
                playerData_.reputation = playerData_.reputation + 8
                return "⭐ 声望+8（虽然输了，但老头们记住了你）"
            end
        end,
    },
    {
        id = "base_gossip", icon = "👂", title = "八卦集散地",
        narrative = "集市尽头的茶铺，是当地信息流通最快的地方。\n\n"
            .. "你要了一杯甜茶，竖起耳朵听周围的闲聊。\n\n"
            .. "有人说城东新开了一家网吧——「但老板不会搞活动，冷清得很。」\n"
            .. "有人说下周有个大型社区活动——「摆摊的话人流量暴涨。」\n\n"
            .. "这些情报，比任何市场报告都管用。",
        apply = function()
            local rep = 12 + math.random(3, 8)
            playerData_.reputation = playerData_.reputation + rep
            return "⭐ 声望+" .. rep .. "（情报加持）"
        end,
    },
    {
        id = "base_repair", icon = "🔧", title = "修理匠",
        narrative = "一个路边摊铺着一块布，上面摆满了各种拆机零件——风扇、内存条、电源线，应有尽有。\n\n"
            .. "「Boss, what you need?」摊主是个年轻人，手上还沾着焊锡的痕迹。\n\n"
            .. "你翻了翻——居然有几块能用的显卡散热片和一把品相不错的椅子轮子。\n"
            .. "花了点小钱打包带走。回去装上，网吧设备质量又提升了一档。",
        apply = function()
            playerData_.pcQuality = math.min((playerData_.pcQuality or 0) + 1, 20)
            local earn = 30 + math.random(10, 30)
            playerData_.money = playerData_.money + earn
            return "🖥️ 设备+1  💰+$" .. earn
        end,
    },
    {
        id = "base_compatriot", icon = "🤝", title = "异乡人",
        narrative = function()
            local variants = {
                "你在集市碰到一个背着大包的中国小伙，一聊才知道是隔壁城市做手机贸易的。\n\n"
                    .. "「哥们你在这开网吧？牛啊！改天我带朋友过来打游戏！」\n\n"
                    .. "他留了联系方式。在异国他乡，同胞情谊格外珍贵。",
                "一个面熟的非洲大姐跑过来跟你打招呼——她是你家附近杂货铺的老板娘。\n\n"
                    .. "「中国老板！我儿子天天说要去你店里打游戏，你能不能给个优惠？」\n\n"
                    .. "你笑着说好。邻里关系，就是这样处出来的。",
                "集市出口处，一个穿着整洁的年轻人拦住你——他自我介绍是当地大学的计算机系学生。\n\n"
                    .. "「我听说您开了个很火的网吧……能不能让我来实习？我会修电脑！」\n\n"
                    .. "你要了他的电话号码。人才，有时候就是这样遇到的。",
            }
            return variants[math.random(1, #variants)]
        end,
        apply = function()
            playerData_.reputation = playerData_.reputation + 10
            if #teamMembers_ > 0 then
                local m = teamMembers_[math.random(1, #teamMembers_)]
                m.mood = math.min(100, m.mood + 8)
                return "⭐ 声望+10  😊 " .. m.name .. " 心情+8"
            end
            return "⭐ 声望+10"
        end,
    },
}

function DoVisitMarket()
    local marketVisitCost = GetCityCost and GetCityCost(50) or 50
    if playerData_.money < marketVisitCost then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - marketVisitCost
    -- 委托追踪：逛集市
    playerData_.questMarketVisit = (playerData_.questMarketVisit or 0) + 1
    -- 首次逛集市：标记剧情解锁点
    if playerData_.questMarketVisit == 1 then
        local PU = require("ProgressiveUnlock")
        PU.MarkStoryCompleted("first_market_visit")
    end

    CafeAnimEvents.Push("market_return")
    playerData_.marketRecentIds = playerData_.marketRecentIds or {}

    local title, narrative, effects, icon, success

    -- ══ 最优先：检查摊贩支线主线故事 ══
    local storyEvent, storyVendor, storyStage = nil, nil, nil
    pcall(function()
        storyEvent, storyVendor, storyStage = MarketStorylines.TryAdvance(playerData_.day)
    end)
    if storyEvent then
        -- 支线故事以选择事件形式展示（复用 currentEvent_ 系统）
        currentEvent_ = storyEvent
        currentEvent_._marketVendor = storyVendor
        currentEvent_._marketStage = storyStage
        currentPhase_ = PHASE_EVENT
        PlaySFX("event")
        SaveGame()
        BuildUI()
        return
    end

    -- ══ 次优先：检查跨线联动事件（Layer 3）══
    local crossEvent = nil
    pcall(function()
        crossEvent = MarketStorylines.TryGetCrosslineEvent()
    end)
    if crossEvent then
        currentEvent_ = crossEvent
        currentEvent_._marketCrossline = true
        currentPhase_ = PHASE_EVENT
        PlaySFX("event")
        SaveGame()
        BuildUI()
        return
    end

    -- ══ 优先检查特殊事件（60%概率触发）══
    local special = CheckMarketSpecialEvent()
    if special then
        icon = special.icon
        title = special.title
        narrative = special.narrative
        effects = special.effects
        success = true
    else
        -- ══ 基础故事池：从10个故事中抽取（排除最近3次）══
        local recentSet = {}
        for _, rid in ipairs(playerData_.marketRecentIds) do recentSet[rid] = true end

        local baseCandidates = {}
        for _, story in ipairs(MARKET_BASE_STORIES) do
            if not recentSet[story.id] then
                if not story.cond or story.cond() then
                    table.insert(baseCandidates, story)
                end
            end
        end
        -- 降级：全被排除时退回全池
        if #baseCandidates == 0 then
            for _, story in ipairs(MARKET_BASE_STORIES) do
                if not story.cond or story.cond() then
                    table.insert(baseCandidates, story)
                end
            end
        end

        local chosen = baseCandidates[math.random(1, #baseCandidates)]
        icon = chosen.icon
        title = chosen.title

        -- 叙事：支持函数式动态生成
        if type(chosen.narrative) == "function" then
            local narr, eff = chosen.narrative()
            narrative = narr
            effects = eff or ""
        else
            narrative = chosen.narrative
            effects = ""
        end

        -- 效果：apply 返回效果描述
        if chosen.apply then
            effects = chosen.apply()
        end

        -- 记入记忆窗口
        table.insert(playerData_.marketRecentIds, chosen.id)
        if #playerData_.marketRecentIds > 3 then
            table.remove(playerData_.marketRecentIds, 1)
        end
        success = true
    end

    -- ══ Layer 1 + Layer 2: 注入氛围文本和间歇小互动 ══
    local ambientText, intervalText = nil, nil
    pcall(function()
        ambientText = MarketStorylines.GetAmbientText()
    end)
    pcall(function()
        intervalText = MarketStorylines.TryGetIntervalEvent()
    end)

    -- 拼接叙事（氛围在前，正文，间歇在后）
    local fullNarrative = ""
    if ambientText then
        fullNarrative = ambientText .. "\n\n"
    end
    fullNarrative = fullNarrative .. (narrative or "")
    if intervalText then
        fullNarrative = fullNarrative .. "\n\n———\n\n" .. intervalText
    end

    eventResult_ = {
        success = success,
        icon = icon,
        title = "🏪 逛集市 · " .. title,
        narrative = fullNarrative,
        effects = effects,
        logText = "🏪 " .. title .. " — " .. effects,
        type = "market",
    }
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

--- 友谊赛对手库（比之前6个更丰富，含特色描述）
-- （MATCH_TIERS 和 matchTierSelect_ 已移至文件前部，确保 BuildActionCard 可见）

local FRIENDLY_OPPONENTS = {
    { name = "Kano Boys",       emoji = "🦁", flavor = "尼日利亚街头少年队，靠野路子杀出血路" },
    { name = "Lagos Lightning", emoji = "⚡", flavor = "拉各斯网吧老手，闪电般的反应速度" },
    { name = "Accra Wolves",    emoji = "🐺", flavor = "加纳大学生战队，纪律严明" },
    { name = "Nairobi Hawks",   emoji = "🦅", flavor = "内罗毕鹰眼狙击手联盟" },
    { name = "Dakar Stars",     emoji = "⭐", flavor = "塞内加尔明星选手，人气极高" },
    { name = "Cairo Cobras",    emoji = "🐍", flavor = "开罗毒蛇队，擅长阴险战术" },
    { name = "Kampala Rhinos",  emoji = "🦏", flavor = "乌干达犀牛队，防守铁桶阵" },
    { name = "Addis Phoenix",   emoji = "🔥", flavor = "亚的斯亚贝巴凤凰队，逆风翻盘专家" },
    { name = "Cape Lions",      emoji = "🦁", flavor = "开普敦雄狮，南非赛区霸主" },
    { name = "Marrakech Sand",  emoji = "🏜️", flavor = "马拉喀什沙暴队，神出鬼没" },
}
--- 强敌对手（5胜后随机出现，实力更强，奖励更高）
local ELITE_OPPONENTS = {
    { name = "Victor's Vipers", emoji = "👿", flavor = "Victor 亲自带队的精英小队！", powerMult = { 1.1, 1.4 },
      entrance = {
          { speaker = "旁白", text = "网吧的门被猛地推开。一个高大的身影站在逆光中，身后是三个戴着统一耳机的队员。" },
          { speaker = "Victor", text = "Dragon Force？就是你们一直在我背后追赶？（轻蔑地笑了笑）有意思。" },
          { speaker = "你", text = "Victor……你怎么来了？" },
          { speaker = "Victor", text = "听说你们连赢了好几场？我亲自来看看——到底是真有实力，还是对手太弱。" },
          { speaker = "旁白", text = "空气瞬间凝固。你的队员们放下手中的鼠标，眼神变得锐利。\n\n【⚠️ 强敌 Victor's Vipers 下战书！这是证明自己的机会！】" },
      }},
    { name = "Team Tsunami",    emoji = "🌊", flavor = "日本远征军，亚洲赛区顶级强队", powerMult = { 1.15, 1.35 },
      entrance = {
          { speaker = "旁白", text = "五个穿着整齐队服的日本选手走进网吧，礼貌地鞠了一躬。他们的队服背后印着巨大的浪花图案。" },
          { speaker = "Tsunami队长", text = "（用英语）你好。我们是Team Tsunami，听说非洲有一支很强的新队伍。我们来切磋。" },
          { speaker = "你", text = "亚洲赛区的强队……专程来非洲？" },
          { speaker = "Tsunami队长", text = "（微微一笑）强者不问出处。请多指教。" },
          { speaker = "旁白", text = "你注意到他们每个人带的都是定制外设，键盘上刻着各自的名字。\n\n【⚠️ 亚洲劲旅 Team Tsunami 登门挑战！他们的纪律性令人生畏！】" },
      }},
    { name = "EU Phantoms",     emoji = "👻", flavor = "欧洲幽灵队，世界排名前20", powerMult = { 1.2, 1.5 },
      entrance = {
          { speaker = "旁白", text = "一封加密邮件出现在你的收件箱：'我们知道你在哪。明天下午三点，线上见。——Phantoms'" },
          { speaker = "你", text = "EU Phantoms……世界排名前20的队伍，怎么会知道我们？" },
          { speaker = "旁白", text = "第二天下午三点整，对方准时上线。五个欧洲ID同时进入房间，头像全是幽灵面具。" },
          { speaker = "Phantom队长", text = "（语音连麦）We've been watching you, Dragon Force. Let's see if the hype is real." },
          { speaker = "旁白", text = "你的队员们对视一眼，然后不约而同地戴上耳机。\n\n【⚠️ 世界级强队 EU Phantoms 线上约战！这是Dragon Force目前面对的最强对手！】" },
      }},
}

function DoHostTournament(tier)
    tier = tier or 1
    if friendlyMatchToday_ then AddLog("⏳ 今天已经打过比赛了，明天再来吧！"); BuildUI(); return end
    local tierCfg = MATCH_TIERS[tier]
    if not tierCfg then return end
    local matchCost = GetCityCost and GetCityCost(tierCfg.cost) or tierCfg.cost
    if playerData_.money < matchCost or #teamMembers_ < 2 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - matchCost
    friendlyMatchToday_ = true
    currentMatchTier_ = tier  -- 记录当前比赛等级，FinishMatch 用

    local teamPower = GetTeamPower()
    local oppStyles = { "快攻型", "防守反击", "均衡型" }

    -- 高等级比赛或5胜后有概率遇到强敌
    local eliteChance = tier >= 3 and 50 or (tier >= 2 and 35 or (playerData_.friendlyWins >= 5 and 30 or 0))
    local isElite = math.random(1, 100) <= eliteChance
    local oppData, oppPower

    if isElite then
        oppData = ELITE_OPPONENTS[math.random(1, #ELITE_OPPONENTS)]
        local mult = oppData.powerMult
        -- 精英对手也使用锚定公式：基础值 + 玩家战力的一部分
        local anchor = (tierCfg.basePower or 100) + math.floor(teamPower * 0.4)
        oppPower = math.floor(anchor * (mult[1] + math.random() * (mult[2] - mult[1])))
    else
        oppData = FRIENDLY_OPPONENTS[math.random(1, #FRIENDLY_OPPONENTS)]
        -- 锚定公式：basePower + teamPower * powerFrac，再加随机浮动
        local anchor = (tierCfg.basePower or 100) + math.floor(teamPower * (tierCfg.powerFrac or 0.35))
        local variance = math.random(-15, 15)
        oppPower = math.max(50, anchor + variance)
    end

    friendlyOpponent_ = {
        name = oppData.name,
        emoji = oppData.emoji,
        style = oppStyles[math.random(1, #oppStyles)],
        power = oppPower,
        isElite = isElite,
        flavor = oppData.flavor,
    }
    isFriendlyMatch_ = true
    matchOpponents_ = { friendlyOpponent_ }
    matchPhase_ = "intro"
    matchLog_ = {}
    matchWins_ = 0
    matchRound_ = 1
    matchTactic_ = "balanced"
    matchNarrative_ = {}

    CafeAnimEvents.Push("tournament")
    local prefix = isElite and "🔥 强敌降临！" or "⚔️ 发起友谊赛！"
    local gameTag = matchGameType_ and (" [" .. matchGameType_.emoji .. matchGameType_.name .. "]") or ""
    AddLog(prefix .. gameTag .. " 对手: " .. friendlyOpponent_.emoji .. " " .. friendlyOpponent_.name)

    -- 精英对手：专属入场对话过渡
    if isElite and oppData.entrance then
        PlayBGM("match")
        eliteEntranceDialogues_ = oppData.entrance
        eliteEntranceIdx_ = 1
        currentPhase_ = PHASE_DIALOGUE
        dialogueOverride_ = "elite_entrance"
        BuildUI()
        return
    end

    currentPhase_ = PHASE_MATCH
    BuildUI()
end

-- ═══ Day2 主线行动：电费/房租危机 ═══
function DoDay2MainAction()
    if not UseActionPoint(1) then return end
    local evt = Retention and Retention.GetNextTutorialEvent(2, 0)
    if not evt then
        AddLog("⚡ Day2主线事件加载失败，请报告bug")
        return
    end
    playerData_.day2CrisisDone = true
    currentEvent_ = evt
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

-- ═══ Day3 主线行动：Kofi 影子事件 ═══
function DoDay3MainAction()
    if not UseActionPoint(1) then return end
    local evt = Retention and Retention.GetNextTutorialEvent(3, 0)
    if not evt then
        AddLog("👀 Day3主线事件加载失败，请报告bug")
        return
    end
    playerData_.day3KofiDone = true
    currentEvent_ = evt
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

-- ═══ Day4 主线行动：街区信任事件 ═══
function DoDay4MainAction()
    if not UseActionPoint(1) then return end
    local evt = Retention and Retention.GetNextTutorialEvent(4, 0)
    if not evt then
        AddLog("🏘️ Day4主线事件加载失败，请报告bug")
        return
    end
    playerData_.day4CommunityDone = true
    currentEvent_ = evt
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

function DoPostFlyers()
    local flyerCost = GetCityCost and GetCityCost(30) or 30
    if playerData_.money < flyerCost then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - flyerCost
    local rep = math.random(8, 20)
    playerData_.reputation = playerData_.reputation + rep
    CafeAnimEvents.Push("post_flyers")
    -- Day1 首次贴传单完成主线标记
    if (playerData_.day or 1) == 1 and not playerData_.day1FlyerDone then
        playerData_.day1FlyerDone = true
    end
    -- P1-1: D1-D3 不触发随机招募，保护新手节奏
    if (playerData_.day or 1) >= 4 and math.random() < 0.3 and #CANDIDATE_POOL > 0 and #teamMembers_ < 5 then
        AddLog("📢 传单引来高手！声望+" .. rep)
        TriggerRecruitEvent()
        return
    end
    -- P1-1: D1首次行动给清晰反馈（优先级高于叙事段落）
    if (playerData_.day or 1) <= 2 and rep > 0 then
        AddLog("📋 贴传单完成！花费$" .. flyerCost .. " | 声望+" .. rep .. " | AP-1")
    end

    -- === 队员故事系统（55%触发率，有队员时优先） ===
    if #teamMembers_ > 0 and math.random() < 0.55 then
        local story = BuildMemberFlyerStory()
        if story then
            AddLog("📢 " .. story.title .. " — 声望+" .. rep)
            eventResult_ = {
                success = true,
                icon = story.icon,
                title = "📢 贴传单 · " .. story.title,
                narrative = story.narrative,
                effects = "⭐ 声望+" .. rep,
                logText = "📢 " .. story.title .. " — 声望+" .. rep,
            }
            currentPhase_ = PHASE_EVENT
            BuildUI()
            return
        end
    end

    -- === 通用传单故事（无队员 / 队员故事未触发时） ===
    local FLYER_STORIES = {
        {
            icon = "🧒",
            title = "小孩子帮忙",
            narrative = "你在电线杆上贴传单时，旁边几个小孩凑过来看热闹。\n\n"
                .. "「哥哥，给我几张！我帮你贴到学校门口去！」\n\n"
                .. "你递了一叠给他们，他们像放风筝一样跑远了。\n第二天，还真有几个学生来了——「我们看到传单了！」",
        },
        {
            icon = "🏍️",
            title = "摩托车司机",
            narrative = "贴传单路上，你搭了一辆摩托车。司机边骑边回头喊：\n\n"
                .. "「三角洲行动？我知道！我侄子天天说要当职业选手！」\n\n"
                .. "你塞了两张传单给他：「让他来Dragon Net Cafe，我教他。」\n"
                .. "「好嘞！」司机油门一轰，传单在风中猎猎作响。",
        },
        {
            icon = "👵",
            title = "好奇的大婶",
            narrative = "你正往墙上刷浆糊，隔壁杂货铺的大婶端着茶杯走过来。\n\n"
                .. "「中国老板，你贴的什么？'纯黑跑刀'……这是卖刀的？」\n"
                .. "「不是不是，是打游戏赚钱的。」\n"
                .. "「打游戏还能赚钱？？」她瞪大了眼睛，转身就喊——\n"
                .. "「阿布！快来看！中国老板说打游戏能赚钱！」\n\n一传十十传百，这就是非洲的信息传播速度。",
        },
        {
            icon = "🌧️",
            title = "雨中传单",
            narrative = "传单贴到一半突然下起了大雨。你蹲在路边小棚子下避雨。\n\n"
                .. "旁边几个年轻人也在躲雨，无聊地刷着手机。\n你顺手递了几张传单过去：「去Dragon Net Cafe打游戏，赚哈弗币换真钱。」\n\n"
                .. "他们互相看了一眼——「真的假的？」「反正下雨也没事干，走？」\n\n雨还没停，他们就出发了。",
        },
        {
            icon = "🎵",
            title = "传单上的涂鸦",
            narrative = "你回头检查贴出去的传单，发现有人在好几张上面画了涂鸦——\n\n"
                .. "一个戴墨镜的火柴人，旁边写着「DRAGON FORCE 牛逼！」\n\n"
                .. "虽然字丑得不忍直视，但你笑了。\n这说明有人真的在看你的传单，甚至还成了你的粉丝。",
        },
        {
            icon = "🏫",
            title = "学校门口",
            narrative = "你把传单贴到了附近中学的围墙外面。\n\n"
                .. "放学铃一响，十几个学生围了上来。\n"
                .. "「Dragon Net Cafe？离这儿远吗？」「有空调吗？」「网速快不快？」\n\n"
                .. "你一一回答，最后补了一句：「你们来了，第一小时半价。」\n\n"
                .. "第二天下午四点，网吧突然来了一波学生潮。",
        },
    }

    -- 通用故事去重（用 recentFlyerBaseIds 桶）
    if not playerData_.recentFlyerBaseIds then playerData_.recentFlyerBaseIds = {} end
    local available = {}
    for i, s in ipairs(FLYER_STORIES) do
        local used = false
        for _, rid in ipairs(playerData_.recentFlyerBaseIds) do
            if rid == i then used = true; break end
        end
        if not used then table.insert(available, { idx = i, story = s }) end
    end
    if #available == 0 then
        playerData_.recentFlyerBaseIds = {}
        available = {}
        for i, s in ipairs(FLYER_STORIES) do table.insert(available, { idx = i, story = s }) end
    end
    local pick = available[math.random(1, #available)]
    table.insert(playerData_.recentFlyerBaseIds, pick.idx)
    if #playerData_.recentFlyerBaseIds > 4 then table.remove(playerData_.recentFlyerBaseIds, 1) end

    local story = pick.story
    eventResult_ = {
        success = true,
        icon = story.icon,
        title = "📢 贴传单 · " .. story.title,
        narrative = story.narrative,
        effects = "⭐ 声望+" .. rep,
        logText = "📢 " .. story.title .. " — 声望+" .. rep,
    }
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

--- 📢 队员贴传单故事构建器（双桶去重，8个模板 × 队员组合）
function BuildMemberFlyerStory()
    -- 8个队员故事模板，{name} 和 {emoji} 运行时替换
    local MEMBER_FLYER_TEMPLATES = {
        { id = 1, icon = "{emoji}", title = "{name}的宣传攻势",
          narrative = "{name}主动说「老板，今天我来帮你贴！」\n\n结果这家伙不走寻常路——站在路口举着传单大喊：\n「Dragon Net Cafe！来了就是兄弟！不来就是……也是兄弟！但你会后悔！」\n\n路人被逗乐了，还真有几个跟着来了。" },
        { id = 2, icon = "{emoji}", title = "{name}的人脉圈",
          narrative = "你发现{name}贴传单时认识的人出奇地多。\n\n走几步就有人打招呼：「嘿{name}！这是你老板的店？」\n{name}拍着胸脯：「当然！非洲最强战队Dragon Force的大本营！」\n\n比你自己贴十天效果都好。" },
        { id = 3, icon = "{emoji}", title = "{name}被搭讪",
          narrative = "贴传单路上，有个穿西装的人拦住{name}：\n「你们队在招人吗？我弟弟天天看你们打比赛的视频——」\n\n{name}一脸傲娇：「Dragon Force不是谁都能进的。让他先来试试。」\n\n你在旁边偷笑——这小子，飘了。" },
        { id = 4, icon = "{emoji}", title = "{name}的即兴表演",
          narrative = "{name}拿起传单贴了两张就坐不住了。\n\n掏出手机放了段比赛录像，在街边给路人现场解说：\n「看到没！这个走位！这是我做的！三杀！」\n\n围了一圈人看，比传单有用多了。" },
        { id = 5, icon = "{emoji}", title = "{name}和小粉丝",
          narrative = "有个小孩跑过来拉{name}的衣角：\n「你是Dragon Force的吗？我在视频里见过你！」\n\n{name}蹲下来签了个名（虽然签在传单背面），那小孩宝贝似地收起来。\n\n你看着这一幕，突然觉得一切努力都值了。" },
        { id = 6, icon = "{emoji}", title = "{name}翘班贴传单",
          narrative = "{name}今天本来该训练，但非要跟你出来贴传单。\n\n「训练明天补嘛！我想看看外面的人怎么说我们！」\n\n你俩并肩走在街上，一边贴一边聊战术。\n难得的轻松时光。" },
        { id = 7, icon = "{emoji}", title = "{name}的口碑效应",
          narrative = "你还没开始贴，就有个摊贩主动过来：\n「你是{name}的老板吧？他上次帮我搬东西，人真好！」\n\n「你们的传单给我几张，我贴在我摊位上。」\n\n看来{name}平时积累的好人缘，正在变成无形资产。" },
        { id = 8, icon = "{emoji}", title = "{name}的反向营销",
          narrative = "{name}别出心裁，在传单背面写了句话：\n「如果你能在跑刀赛里活过{name}三分钟，免费上网一小时！」\n\n第二天来了五个人挑战，全军覆没——但都充了钱继续玩。\n{name}得意地冲你竖大拇指。" },
    }

    -- 双桶去重：recentFlyerMemberIds 记录最近用过的模板ID
    if not playerData_.recentFlyerMemberIds then playerData_.recentFlyerMemberIds = {} end

    -- 过滤出未使用的模板
    local available = {}
    for _, t in ipairs(MEMBER_FLYER_TEMPLATES) do
        local used = false
        for _, rid in ipairs(playerData_.recentFlyerMemberIds) do
            if rid == t.id then used = true; break end
        end
        if not used then table.insert(available, t) end
    end
    -- 所有模板用完 → 清空重来
    if #available == 0 then
        playerData_.recentFlyerMemberIds = {}
        available = MEMBER_FLYER_TEMPLATES
    end

    -- 随机选一个模板和一个队员
    local template = available[math.random(1, #available)]
    local member = teamMembers_[math.random(1, #teamMembers_)]

    -- 记录已用模板
    table.insert(playerData_.recentFlyerMemberIds, template.id)
    if #playerData_.recentFlyerMemberIds > 6 then table.remove(playerData_.recentFlyerMemberIds, 1) end

    -- 替换占位符
    local function fillTemplate(str)
        return str:gsub("{name}", member.name):gsub("{emoji}", member.emoji or "🧑🏿")
    end

    return {
        icon = fillTemplate(template.icon),
        title = fillTemplate(template.title),
        narrative = fillTemplate(template.narrative),
    }
end

--- 向 Mama B 借钱（经济缓冲，防止死亡螺旋）
function DoBorrowMoney()
    if playerData_.debt >= 500 then
        AddLog("💬 Mama B：「你已经欠我 $" .. playerData_.debt .. " 了，先还清再说！」")
        BuildUI(); return
    end
    if playerData_.debtDay == playerData_.day then
        AddLog("💬 Mama B：「今天已经借过了，明天再来吧。」")
        BuildUI(); return
    end
    local amount = 300
    playerData_.money = playerData_.money + amount
    pcall(MFX_MoneyPop, amount)
    playerData_.debt = playerData_.debt + amount
    playerData_.debtDay = playerData_.day
    CafeAnimEvents.Push("borrow_money")
    AddLog("💰 Mama B 递过来一叠钞票：「$" .. amount .. "，记着还。利息每天 10%。」")
    AddLog("   当前欠款: $" .. playerData_.debt .. "（每日结算自动扣除利息+本金）")
    PlaySFX("click")
    BuildUI()
end

-- ============================================================================
-- ============================================================================
-- v6 新增：Big Joe 高利贷（15%日息，上限$500，比Mama B更狠但额度更高）
-- ============================================================================

--- Big Joe 高利贷借款
function DoBorrowBigJoe()
    if not playerData_.bigJoeUnlocked then
        AddLog("🦈 你翻遍抽屉也找不到那张名片了。（未解锁）")
        BuildUI(); return
    end
    local bigJoeDebt = playerData_.bigJoeDebt or 0
    if bigJoeDebt >= 500 then
        AddLog("🦈 Big Joe：\"够了兄弟，你已经欠我$" .. bigJoeDebt .. "。先把旧账清了。\"")
        BuildUI(); return
    end
    if playerData_.bigJoeDebtDay == playerData_.day then
        AddLog("🦈 Big Joe：\"一天借一次，规矩。明天再来。\"")
        BuildUI(); return
    end
    local amount = 500
    playerData_.money = playerData_.money + amount
    pcall(MFX_MoneyPop, amount)
    playerData_.bigJoeDebt = (playerData_.bigJoeDebt or 0) + amount
    playerData_.bigJoeDebtDay = playerData_.day
    CafeAnimEvents.Push("borrow_money")
    AddLog("🦈 Big Joe 从花衬衫口袋掏出一叠钞票拍在桌上：\"$" .. amount .. "，日息15%。别让我来找你。\"")
    AddLog("   ⚠️ Big Joe 欠款: $" .. playerData_.bigJoeDebt .. "（每日结算扣15%利息+自动还款）")
    PlaySFX("click")
    BuildUI()
end

-- v5 新增行动：二手市场 & 分店
-- ============================================================================

--- 二手设备淘宝市场
function DoSecondHandMarket()
    if not UseActionPoint(1) then return end
    PlayBGM("market")
    PlaySFX("event")
    CafeAnimEvents.Push("second_hand")
    -- 随机生成2-3个二手商品
    local items = {
        { name = "二手显示器", desc = "有几个亮点，但能用", cost = 80, goodChance = 0.6,
          goodEffect = function() playerData_.computers = playerData_.computers + 1; return "💻 电脑+1台（捡到宝了！）" end,
          badEffect = function() playerData_.money = playerData_.money - 30; return "💸 用了两天就坏了，白花钱还倒贴维修费-$30" end },
        { name = "旧电竞椅", desc = "皮有点裂，但人体工学还在", cost = 120, goodChance = 0.7,
          goodEffect = function()
            if playerData_.chairLevel < 5 then playerData_.chairLevel = playerData_.chairLevel + 1 end
            return "🪑 座椅升级！坐着真舒服"
          end,
          badEffect = function() return "🪑 坐上去第二天就塌了……不过也没花多少钱" end },
        { name = "来路不明的路由器", desc = "据说是从大使馆流出来的", cost = 150, goodChance = 0.5,
          goodEffect = function()
            if playerData_.netSpeed < 5 then playerData_.netSpeed = playerData_.netSpeed + 1 end
            return "🌐 网速提升！果然是好货"
          end,
          badEffect = function()
            playerData_.equipCondition = math.max(0, playerData_.equipCondition - 15)
            return "⚠️ 路由器短路了！设备状况-15%"
          end },
        { name = "太阳能板碎片", desc = "拼一拼说不定能用", cost = 100, goodChance = 0.4,
          goodEffect = function()
            if playerData_.solarLevel < 3 then playerData_.solarLevel = playerData_.solarLevel + 1 end
            return "☀️ 太阳能板拼装成功！效果不错"
          end,
          badEffect = function() return "☀️ 拼了半天发现缺关键零件，白忙活" end },
        { name = "二手发电机零件", desc = "看起来还能翻新", cost = 200, goodChance = 0.55,
          goodEffect = function()
            playerData_.fuel = math.min((playerData_.fuel or 0) + 15, playerData_.fuelCapacity or 20)
            playerData_.equipCondition = math.min(100, playerData_.equipCondition + 10)
            return "⛽ 发电机翻新成功！燃油+15L 设备+10%"
          end,
          badEffect = function()
            playerData_.equipCondition = math.max(0, playerData_.equipCondition - 10)
            return "💥 零件不兼容，拆装过程中还弄坏了其他设备-10%"
          end },
        { name = "神秘主机箱", desc = "卖家说里面配置很好，但不让打开看", cost = 250, goodChance = 0.45,
          goodEffect = function()
            playerData_.computers = playerData_.computers + 1
            playerData_.reputation = playerData_.reputation + 20
            return "💻🎉 居然是高配主机！电脑+1 声望+20"
          end,
          badEffect = function()
            playerData_.money = playerData_.money - 50
            return "📦 打开一看全是砖头……被骗了-$50"
          end },
    }
    -- 随机选2-3个
    local shuffled = {}
    for i = 1, #items do shuffled[i] = items[i] end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    local count = math.random(2, 3)
    local available = {}
    for i = 1, math.min(count, #shuffled) do
        table.insert(available, shuffled[i])
    end

    -- 构建选择事件
    local choices = {}
    for _, item in ipairs(available) do
        table.insert(choices, {
            text = "💰 " .. item.name .. " $" .. item.cost,
            cond = function() return playerData_.money >= item.cost end,
            result = "",
            effect = function()
                playerData_.money = playerData_.money - item.cost
                if math.random() < item.goodChance then
                    local gOk, msg = pcall(item.goodEffect)
                    if not gOk then msg = "淘到了好东西！" end
                    AddLog("📦 二手淘宝: " .. msg)
                    eventResult_ = {
                        success = true, icon = "🎉", title = "📦 淘到好货！",
                        narrative = item.name .. "——" .. (item.desc or "") .. "\n\n结果：" .. msg,
                        effects = msg .. " | 花费 $" .. item.cost,
                        logText = "📦 " .. msg,
                    }
                else
                    local bOk, msg = pcall(item.badEffect)
                    if not bOk then msg = "翻车了……" end
                    AddLog("📦 二手淘宝: " .. msg)
                    eventResult_ = {
                        success = false, icon = "😅", title = "📦 翻车了……",
                        narrative = item.name .. "——" .. (item.desc or "") .. "\n\n结果：" .. msg .. "\n\n这就是非洲二手市场的刺激之处！",
                        effects = msg .. " | 花费 $" .. item.cost,
                        logText = "📦 " .. msg,
                    }
                end
                currentPhase_ = PHASE_EVENT
                BuildUI()
            end,
        })
    end
    table.insert(choices, {
        text = "🚶 不买了，回去",
        result = "明智的选择……或者说怂了？",
        effect = function()
            AddLog("📦 逛了一圈二手市场，什么都没买")
            PlayBGM("manage")
            BuildUI()
        end,
    })

    -- 触发选择事件
    local evt = {
        type = "choice", title = "📦 非洲二手淘宝", icon = "📦",
        desc = "镇上的二手市场又开了！各种来路不明的电子设备摆满了地摊。\n\n卖家们热情地招呼：'便宜便宜！保证好用！'\n\n你心里明白——有宝也有坑，全凭运气。",
        choices = choices,
    }
    currentEvent_ = evt
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

--- 获取已占用的分店地点ID列表
function GetUsedBranchLocationIds()
    local used = {}
    for _, br in ipairs(playerData_.branches or {}) do
        if br.locationId then used[br.locationId] = true end
    end
    return used
end

--- 随机选取2-3个可用分店地点
function RollBranchLocationOptions()
    local used = GetUsedBranchLocationIds()
    local available = {}
    for _, loc in ipairs(BRANCH_LOCATIONS) do
        if not used[loc.id] then table.insert(available, loc) end
    end
    -- 打乱顺序后取前2-3个
    for i = #available, 2, -1 do
        local j = math.random(1, i)
        available[i], available[j] = available[j], available[i]
    end
    local count = math.min(#available, math.random(2, 3))
    local result = {}
    for i = 1, count do result[i] = available[i] end
    return result
end

--- 开分店（带地点和游戏选择）
function DoOpenBranch(locData, gameData)
    local branches = playerData_.branches or {}
    local idx = #branches + 1
    ---@diagnostic disable-next-line: assign-type-mismatch
    local cost = BRANCH_COSTS[idx] or 9000
    ---@diagnostic disable-next-line: assign-type-mismatch
    cost = GetCityCost and GetCityCost(cost) or cost
    if playerData_.money < cost then return end
    if idx > 3 then
        AddLog("🏪 最多只能开3家分店！")
        BuildUI()
        return
    end
    playerData_.money = playerData_.money - cost
    CafeAnimEvents.Push("open_branch")
    local baseIncome = 40 + math.random(10, 30) + playerData_.reputation / 10
    local dailyIncome = math.floor(baseIncome * (locData.incomeBonus or 1.0))

    local branchName = "Dragon·" .. locData.name .. "店"
    table.insert(branches, {
        name = branchName,
        location = locData.name,
        locationId = locData.id,
        locationEmoji = locData.emoji,
        gameType = gameData.id,
        gameName = gameData.name,
        gameEmoji = gameData.emoji,
        bonusType = locData.bonusType,
        bonusDesc = locData.bonusDesc,
        gameBonusType = gameData.bonusType,
        gameBonusDesc = gameData.bonusDesc,
        income = dailyIncome,
        day = playerData_.day,
    })
    playerData_.branches = branches
    playerData_.reputation = playerData_.reputation + 60

    -- 首次开分店里程碑
    if #branches == 1 and not storyTriggered_["milestone_first_branch"] then
        storyTriggered_["milestone_first_branch"] = true
        AddLog("🎉 【里程碑】第一家分店开业！从单店到连锁，你迈出了关键一步！")
        TriggerCelebration()
    end

    -- 按地点生成不同叙事
    local locNarratives = {
        lagos = "拉各斯的商业街上，你找到了一间位置绝佳的铺面。虽然隔壁是嘈杂的发电机维修店，但人流量惊人。\n\n开业第一天，"
            .. gameData.emoji .. " " .. gameData.name .. " 的海报贴满了整条街。摩托车司机们纷纷停下来围观。\n\n"
            .. "'嘿！这里能打" .. gameData.name .. "？太酷了！'一个穿着国家队球衣的年轻人冲了进来。\n\n"
            .. "Big Joe在电话那头喊：'老板，你的商业帝国从拉各斯开始了！'",
        nairobi = "内罗毕科技园区旁边，你的新店开在了一排咖啡馆中间。装修现代，WiFi极速。\n\n"
            .. "一群大学生听说这里能玩" .. gameData.name .. "，下课后直接冲了过来。\n\n"
            .. "'终于不用去市中心了！'一个计算机系的学生激动地说，'而且" .. gameData.name .. "的延迟居然这么低！'\n\n"
            .. "你微笑着看着爆满的大厅——东非的电竞市场，刚刚被你撕开了一道口子。",
        accra = "阿克拉大学城的入口处，你的分店选在了一栋殖民时期老建筑里。高高的天花板和木质百叶窗别有风味。\n\n"
            .. "开业那天，文学院的教授都来捧场了：'年轻人需要正当的娱乐。" .. gameData.name .. "至少比街头赌博健康。'\n\n"
            .. "学生们举着手写海报排队入场。你看着他们兴奋的脸庞，想起了自己年轻时的样子。",
        dakar = "达喀尔港口附近的小巷里，你找到了一间能看到大西洋的铺面。海风从窗户吹进来，带着咸味。\n\n"
            .. "第一批客人是几个法国水手。他们用蹩脚的英语问：'" .. gameData.name .. " serveur, c'est bon?'\n\n"
            .. "'网速绝对够用！'你指着闪烁的路由器指示灯。水手们欢呼着坐下，开始了通宵对战。\n\n"
            .. "这座城市的夜晚，从此多了键盘和鼠标的声音。",
        capetown = "开普敦桌山脚下，你的分店开在了一个时尚街区。落地玻璃窗外就是壮丽的山景。\n\n"
            .. "开业消息在南非电竞论坛上炸了锅。" .. gameData.name .. " 的本地职业选手亲自来站台，粉丝们尖叫着涌进来。\n\n"
            .. "'Dragon Net Cafe来开普敦了！非洲电竞要起飞！'一个博主在直播中喊道。\n\n"
            .. "你站在人群中，感觉自己正在创造历史。",
        kinshasa = "金沙萨最热闹的街区，你的分店紧挨着一家Rumba音乐酒吧。鼓点和键盘声交织在一起。\n\n"
            .. "开业那天，街坊们自发组织了一场庆祝派对。有人拿来了手鼓，有人带来了烤鱼。\n\n"
            .. "'在金沙萨，开店不需要广告——你需要的是一场好派对！'邻居大叔边跳舞边说。\n\n"
            .. "你的" .. gameData.name .. "分店，就这样在非洲最魔幻的城市开张了。",
    }

    local narrative = locNarratives[locData.id] or
        ("你在" .. locData.name .. "开了一家主打" .. gameData.name .. "的分店。开业大吉！")

    eventResult_ = {
        success = true,
        icon = "🏪",
        type = "branch",
        locationId = locData.id,
        title = "🏪 " .. branchName .. "开业！",
        narrative = narrative,
        effects = locData.emoji .. " " .. locData.name .. " | " .. gameData.emoji .. " " .. gameData.name
            .. "\n📍 " .. locData.desc
            .. "\n💰 预估日收入 $" .. dailyIncome .. " | 声望+60"
            .. "\n🎁 地点加成: " .. locData.bonusDesc
            .. "\n🎮 游戏加成: " .. gameData.bonusDesc,
        logText = "🏪 在" .. locData.name .. "开设「" .. branchName .. "」主营" .. gameData.name .. "，日入$" .. dailyIncome,
    }

    -- 重置开设流程状态
    branchOpenStep_ = 0
    branchOpenLocOpts_ = nil
    branchOpenSelLoc_ = nil

    -- 过场动画
    StartTransition("🏪 新店开业", locData.emoji .. " " .. locData.name .. " · " .. gameData.emoji .. " " .. gameData.name, function()
        currentPhase_ = PHASE_EVENT
        BuildUI()
    end)
end

function DoBuyFuel()
    local fuel = playerData_.fuel or 0
    local cap = playerData_.fuelCapacity or 20
    if fuel >= cap then return end
    local buyAmount = cap - fuel
    local cost = buyAmount * 8
    cost = math.max(30, cost)  -- 最低$30
    cost = GetCityCost and GetCityCost(cost) or cost
    if playerData_.money < cost then return end
    playerData_.money = playerData_.money - cost
    playerData_.fuel = cap
    CafeAnimEvents.Push("buy_fuel")
    local narratives = {
        "你骑着摩托去镇上加油站，把两个大桶灌满柴油拖回来。\n\n加油站老板Kwame说：'又是你！生意好啊老板！'\n\n'不买油就停电，停电就没钱赚。'你把油灌进油罐，擦了擦手上的柴油味。",
        "Big Joe帮你去黑市搞了便宜柴油。味道有点奇怪，但发电机照样跑得欢。\n\n'非洲做生意，什么都得灵活变通！'Big Joe拍了拍油桶说。",
        "Mama Blessing的侄子开了辆皮卡把油送到门口。\n\n'Mama说了，给中国老板打九折。'\n你心想：这哪有九折，分明是原价啊……但还是笑着收了。",
    }
    local narrative = narratives[math.random(1, #narratives)]
    eventResult_ = {
        success = true,
        icon = "⛽",
        title = "⛽ 补充燃油",
        narrative = narrative,
        effects = "燃油: " .. fuel .. "L → " .. cap .. "L | 花费 $" .. cost,
        logText = "⛽ 补充燃油 +" .. buyAmount .. "L (-$" .. cost .. ")",
    }
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

function DoRepairEquipment()
    local repairCost = 50 + playerData_.computers * 10
    repairCost = GetCityCost and GetCityCost(repairCost) or repairCost
    if playerData_.money < repairCost then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - repairCost
    CafeAnimEvents.Push("repair")
    local before = playerData_.equipCondition or 0
    playerData_.equipCondition = math.min(100, before + 30)
    local after = playerData_.equipCondition
    -- 结果弹窗
    local narrative, icon
    if before <= 30 then
        narrative = "键盘全换了新轴，显示器擦得锃亮，鼠标垫也换了新的。\n\n"
            .. "修完之后你站在门口看了看——嗯，又是崭新的Dragon Net Cafe！\n\n"
            .. "第一个进来的顾客说：'哇，换新电脑了？'你笑了笑：'修了修而已。'"
        icon = "🔧"
    elseif before <= 50 then
        narrative = "你花了半天时间给所有电脑做了一次大保健——\n清灰、换硅脂、整理线缆。\n\n"
            .. "Big Joe路过说：'老板你修电脑比跑刀还认真啊！'\n"
            .. "'工欲善其事，必先利其器。'你擦了擦汗回答。"
        icon = "🛠️"
    else
        narrative = "例行维护——检查了所有接口和风扇，更换了几个磨损的按键。\n\n"
            .. "虽然没什么大问题，但保养到位才能跑得长久。"
        icon = "🔧"
    end
    eventResult_ = {
        success = true,
        icon = icon,
        title = "🔧 设备维修",
        narrative = narrative,
        effects = "设备状况: " .. before .. "% → " .. after .. "% | 花费 $" .. repairCost,
        logText = "🔧 维修设备 " .. before .. "%→" .. after .. "% (-$" .. repairCost .. ")",
    }
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

function DoTeamBBQ()
    local bbqCost = GetCityCost and GetCityCost(60) or 60
    if playerData_.money < bbqCost or #teamMembers_ == 0 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - bbqCost
    CafeAnimEvents.Push("bbq")
    local moodBoost = math.random(15, 30)
    for _, m in ipairs(teamMembers_) do
        m.mood = math.min(100, m.mood + moodBoost)
    end
    PlaySFX("coin_collect")
    local mvp = teamMembers_[math.random(1, #teamMembers_)]
    -- 选一个和 mvp 不同的队员作为"说话者"，避免同一人重复出现
    local talker = mvp
    if #teamMembers_ > 1 then
        repeat talker = teamMembers_[math.random(1, #teamMembers_)] until talker ~= mvp
    end
    local scenes = {
        { title = "烤肉之夜！", narrative = "月光下，队员们围坐在网吧门口的空地上。\n\nMama Blessing亲自掌勺，炭火上滋滋冒油的Suya串香飘半条街。\n\n" .. mvp.name .. "吃了三串还不够，" .. talker.name .. "说'老板最够意思！'" },
        { title = "加餐犒劳！", narrative = "你从市场买了一整只烤鸡和一箱芬达。\n\n队员们抢着啃鸡腿，" .. mvp.name .. "举着芬达瓶说'为Dragon Force干杯！'\n\n笑声传到了隔壁Uncle Charles家。" },
        { title = "团队聚餐！", narrative = "Mama Blessing端来了她的拿手好菜——Jollof饭配烤鸡翅。\n\n" .. mvp.name .. "边吃边说'跟着老板有肉吃！'\n\n大家吃得肚子圆滚滚的，心情好了不少。" },
    }
    local scene = scenes[math.random(1, #scenes)]
    eventResult_ = {
        success = true, icon = "🍖",
        title = scene.title,
        narrative = scene.narrative,
        effects = "💰 -$60  😊 全队心情+" .. moodBoost,
        logText = "🍖 请队员吃烤肉，全队心情+" .. moodBoost .. "！" .. mvp.name .. "说'老板最够意思！'",
    }
    currentPhase_ = PHASE_EVENT; BuildUI()
end

function DoStreamDeltaForce()
    if #teamMembers_ < 2 or playerData_.netSpeed < 2 then return end
    if not UseActionPoint(1) then return end

    CafeAnimEvents.Push("streaming")
    -- 观众数受声望+队伍平均技术+网速影响
    local avgSkill = GetTeamAvgSkill()
    local netBonus = (playerData_.netSpeed - 1) * 30
    local viewers = math.random(50, 200) + playerData_.reputation + avgSkill * 2 + netBonus
    local income = math.floor(viewers / 8)
    local repGain = math.floor(viewers / 15)
    local coins = math.random(10, 30) + math.floor(avgSkill / 5)

    playerData_.money = playerData_.money + income
    pcall(MFX_MoneyPop, income)
    playerData_.reputation = playerData_.reputation + repGain
    playerData_.havocCoins = playerData_.havocCoins + coins
    playerData_.totalRuns = playerData_.totalRuns + 2

    -- 队员表现影响直播精彩度
    local mvp = teamMembers_[math.random(1, #teamMembers_)]
    PlaySFX("coin_collect")
    if viewers > 500 then
        -- 大火直播：额外奖励 + 队员技术增长
        local skillGain = math.random(1, 3)
        for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + skillGain) end
        PlaySFX("crowd_cheer")
        eventResult_ = {
            success = true, icon = "📺",
            title = "🔥 直播爆了！",
            narrative = "观众" .. viewers .. "人！" .. mvp.name .. "操作太秀，弹幕刷屏'纯黑跑刀永远的神！'\n全队技术+" .. skillGain,
            effects = "💰 $+" .. income .. "  ⭐ 声望+" .. repGain .. "  🪙 浩劫币+" .. coins,
            logText = "📺 🔥 直播爆了！观众" .. viewers .. "人！$+" .. income .. " 全队技术+" .. skillGain,
        }
    elseif viewers > 300 then
        eventResult_ = {
            success = true, icon = "📺",
            title = "直播大火！",
            narrative = mvp.name .. "全程高光，观众" .. viewers .. "人，弹幕不断",
            effects = "💰 $+" .. income .. "  ⭐ 声望+" .. repGain .. "  🪙 浩劫币+" .. coins,
            logText = "📺 直播跑刀大火！" .. mvp.name .. "全程高光，观众" .. viewers .. "人，打赏 $" .. income,
        }
    else
        eventResult_ = {
            success = true, icon = "📺",
            title = "直播跑刀",
            narrative = "观众" .. viewers .. "人，" .. mvp.name .. "稳定发挥，老粉捧场",
            effects = "💰 $+" .. income .. "  ⭐ 声望+" .. repGain .. "  🪙 浩劫币+" .. coins,
            logText = "📺 直播跑刀，观众" .. viewers .. "人，收入 $" .. income .. "，声望+" .. repGain,
        }
    end
    currentPhase_ = PHASE_EVENT; BuildUI()
end

-- ========== 主动赚钱行动 ==========

--- 代练服务：队员用技术帮人代练，按技术等级收费
function DoBoostingService()
    if #teamMembers_ < 1 then return end
    if not UseActionPoint(1) then return end

    CafeAnimEvents.Push("boosting")
    local avgSkill = GetTeamAvgSkill()
    -- 基础收入 + 技术加成，技术越高代练费越贵
    local baseIncome = 40 + math.floor(avgSkill * 1.2)
    -- 随机客户数量 1~3
    local clients = math.random(1, 3)
    local totalIncome = baseIncome * clients
    -- 小概率翻车（技术太低被投诉）
    local failChance = math.max(0.05, 0.30 - avgSkill / 150)
    local failed = math.random() < failChance

    -- 代练也算跑刀经验
    for _, m in ipairs(teamMembers_) do
        m.skill = math.min(SKILL_CAP, m.skill + math.random(0, 1))
    end

    if failed then
        -- 代练翻车，退款+声望损失
        local refund = math.floor(totalIncome * 0.5)
        local net = totalIncome - refund
        playerData_.reputation = math.max(0, playerData_.reputation - 5)
        playerData_.money = playerData_.money + net
        PlaySFX("negative")
        eventResult_ = {
            success = false, icon = "🎮",
            title = "代练翻车！",
            narrative = teamMembers_[math.random(1, #teamMembers_)].name .. "打输了，被客户骂了一顿，退款$" .. refund,
            effects = "💰 $+" .. net .. "  ⭐ 声望-5",
            logText = "🎮 代练翻车，净收入$" .. net .. "，声望-5",
        }
    else
        playerData_.money = playerData_.money + totalIncome
        local repGain = math.floor(clients * 2)
        playerData_.reputation = playerData_.reputation + repGain
        PlaySFX("coin_collect")
        local mvpName = teamMembers_[math.random(1, #teamMembers_)].name
        eventResult_ = {
            success = true, icon = "🎮",
            title = clients >= 3 and "代练爆单！" or "代练完成",
            narrative = clients >= 3
                and ("接了" .. clients .. "个客户，" .. mvpName .. "连续carry！")
                or ("接了" .. clients .. "个客户，顺利完成"),
            effects = "💰 $+" .. totalIncome .. "  ⭐ 声望+" .. repGain,
            logText = "🎮 代练服务，$+" .. totalIncome .. "，声望+" .. repGain,
        }
    end
    currentPhase_ = PHASE_EVENT; BuildUI()
end

--- 网吧包场：接团建、生日会、培训等包场活动
function DoCafeRental()
    if not UseActionPoint(1) then return end

    CafeAnimEvents.Push("cafe_rental")
    local scenes = {
        { icon = "🎂", name = "生日派对", basePay = 120, repGain = 8, desc = "一群中学生来办电竞生日会" },
        { icon = "🏢", name = "公司团建", basePay = 200, repGain = 12, desc = "旁边建筑工地的工头带工人来团建" },
        { icon = "📚", name = "学校培训", basePay = 150, repGain = 15, desc = "附近学校租场地教学生用电脑" },
        { icon = "🎬", name = "YouTuber拍摄", basePay = 180, repGain = 20, desc = "一个小网红要在你店里拍视频" },
        { icon = "⚽", name = "球赛转播", basePay = 100, repGain = 10, desc = "非洲杯比赛，大家挤过来看大屏" },
    }
    local scene = scenes[math.random(1, #scenes)]
    -- 收入受电脑数和设备状况加成
    local compBonus = playerData_.computers * 8
    local condMult = (playerData_.equipCondition or 100) >= 80 and 1.0 or 0.7
    local totalPay = math.floor((scene.basePay + compBonus) * condMult)

    playerData_.money = playerData_.money + totalPay
    pcall(MFX_MoneyPop, totalPay)
    playerData_.reputation = playerData_.reputation + scene.repGain
    PlaySFX("coin_collect")
    -- 包场有概率损坏设备
    local dmgText = ""
    if math.random() < 0.25 then
        local dmg = math.random(3, 8)
        playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - dmg)
        dmgText = "\n⚠️ 客人太嗨了，设备磨损" .. dmg .. "%"
    end
    eventResult_ = {
        success = true, icon = scene.icon,
        title = "包场：" .. scene.name .. "！",
        narrative = scene.desc .. dmgText,
        effects = "💰 $+" .. totalPay .. "  ⭐ 声望+" .. scene.repGain,
        logText = scene.icon .. " 包场" .. scene.name .. "，$+" .. totalPay .. "，声望+" .. scene.repGain,
    }
    currentPhase_ = PHASE_EVENT; BuildUI()
end

--- 手机维修：利用技术做副业，修手机赚外快
function DoPhoneRepair()
    if not UseActionPoint(1) then return end

    CafeAnimEvents.Push("phone_repair")
    local jobs = {
        { name = "换屏幕", pay = 40, diff = 20 },
        { name = "修充电口", pay = 25, diff = 10 },
        { name = "刷机救砖", pay = 60, diff = 40 },
        { name = "清病毒", pay = 35, diff = 15 },
        { name = "换电池", pay = 30, diff = 10 },
        { name = "修WiFi模块", pay = 55, diff = 35 },
    }
    -- 每次随机接2~4单
    local numJobs = math.random(2, 4)
    local totalPay = 0
    local totalFail = 0
    local details = {}
    local techSkill = GetTeamAvgSkill()
    -- 没队员也能做（老板自己动手），但技术以30为底
    if #teamMembers_ == 0 then techSkill = 30 end

    for i = 1, numJobs do
        local job = jobs[math.random(1, #jobs)]
        local success = math.random(1, 100) <= (60 + techSkill - job.diff)
        if success then
            totalPay = totalPay + job.pay
            table.insert(details, job.name .. "✓")
        else
            totalFail = totalFail + 1
            table.insert(details, job.name .. "✗")
        end
    end

    playerData_.money = playerData_.money + totalPay
    local detailStr = table.concat(details, "、")
    if totalFail == 0 then
        playerData_.reputation = playerData_.reputation + 3
        PlaySFX("coin_collect")
        eventResult_ = {
            success = true, icon = "📱",
            title = "维修全部搞定！",
            narrative = detailStr .. "\n客户竖起大拇指：'技术真不错！'",
            effects = "💰 $+" .. totalPay .. "  ⭐ 声望+3",
            logText = "📱 手机维修全部搞定！" .. detailStr .. "，收入$" .. totalPay .. "，声望+3",
        }
    elseif totalPay > 0 then
        PlaySFX("coin_collect")
        eventResult_ = {
            success = true, icon = "📱",
            title = "维修部分完成",
            narrative = detailStr .. "\n有几单没修好，但总算有收入",
            effects = "💰 $+" .. totalPay,
            logText = "📱 手机维修：" .. detailStr .. "，收入$" .. totalPay,
        }
    else
        playerData_.reputation = math.max(0, playerData_.reputation - 2)
        PlaySFX("negative")
        eventResult_ = {
            success = false, icon = "📱",
            title = "维修全翻车了...",
            narrative = detailStr .. "\n全部搞砸，客户气得摔门走了",
            effects = "⭐ 声望-2",
            logText = "📱 手机维修全翻车了..." .. detailStr .. "，白忙一场，声望-2",
        }
    end
    currentPhase_ = PHASE_EVENT; BuildUI()
end

-- ========== end v4 新行动 ==========

--- 计算升级所需时间（秒），基于费用和当前等级
--- 公式: cost^0.65 * 0.5 * (1 + cur*0.12)，范围 [15, 900]
--- 早期(cur=0): 15-40s  中期(cur=2-4): 1-2min  后期(cur=6+): 4-15min
--- 等级越高同价格时间越长，体现"工程越来越复杂"，让广告跳过更有价值
---@param cost number
---@param key? string 升级项 key，用于获取当前等级
---@return number seconds
function CalcUpgradeTime(cost, key)
    if type(cost) ~= "number" or cost <= 0 then return 15 end
    ---@diagnostic disable-next-line: access-invisible
    local base = math.pow(cost, 0.65) * 0.5
    local cur = key and GetUpgradeCur(key) or 0
    local tier = 1.0 + cur * 0.12
    return math.min(900, math.max(15, math.floor(base * tier)))
end

--- 判断升级是否为跨日建造（费用≥1500 且等级≥3）
---@param cost number|table 升级费用
---@param key string 升级键名
---@return number daysNeeded 0=当天完成, 1=需要1天, 2=需要2天
function CalcUpgradeDaysNeeded(cost, key)
    local costVal = type(cost) == "table" and (cost.money or 0) or (type(cost) == "number" and cost or 0)
    local cur = key and GetUpgradeCur(key) or 0
    if costVal >= 3000 and cur >= 4 then return 2 end  -- 超高级升级需要2天
    if costVal >= 1500 and cur >= 3 then return 1 end  -- 高级升级需要1天
    return 0  -- 当天完成
end

--- 格式化剩余时间
---@param seconds number
---@return string
function FormatUpgradeTime(seconds)
    if seconds <= 0 then return "完成" end
    local m = math.floor(seconds / 60)
    local s = math.ceil(seconds % 60)
    if m > 0 then
        return string.format("%d:%02d", m, s)
    end
    return s .. "秒"
end

function DoUpgrade(key)
    local cfg = UPGRADES[key]
    if not cfg then return end
    -- 已有升级进行中
    if activeUpgrade_ then return end
    local cur = GetUpgradeCur(key)
    local nxt = cur + 1
    if nxt > #cfg.costs then return end
    local cost = cfg.costs[nxt]
    -- 城市生活成本系数（基础倍率，在所有折扣之前应用）
    if GetCityCost then
        if type(cost) == "table" then
            cost = {}
            ---@diagnostic disable-next-line: param-type-mismatch
            for ck, cv in pairs(cfg.costs[nxt]) do cost[ck] = cv end
            if cost.money then
                cost.money = GetCityCost(cost.money)
            end
        elseif type(cost) == "number" then
            cost = GetCityCost(cost)
        end
    end
    -- 新手保护期折扣（Day1-5 七折）
    if RV2 then
        local nbDiscount = RV2.GetNewbieDiscount(playerData_.day)
        if nbDiscount < 1.0 then
            if type(cost) == "table" then
                cost = {}
                ---@diagnostic disable-next-line: param-type-mismatch
                for ck, cv in pairs(cfg.costs[nxt]) do cost[ck] = cv end
                if cost.money then
                    cost.money = math.floor(cost.money * nbDiscount)
                end
            elseif type(cost) == "number" then
                cost = math.floor(cost * nbDiscount)
            end
        end
    end
    -- P1: 员工建议折扣（团队→升级费用减免）
    local staffDiscPct = 0
    local staffDiscWho = nil
    local okSD, sdp, sdw = pcall(GetStaffDiscountForUpgrade, key)
    if okSD and sdp and sdp > 0 then staffDiscPct, staffDiscWho = sdp, sdw end
    if staffDiscPct > 0 then
        -- 对 money 字段应用折扣
        if type(cost) == "table" then
            cost = {}
            ---@diagnostic disable-next-line: param-type-mismatch
            for ck, cv in pairs(cfg.costs[nxt]) do cost[ck] = cv end
            if cost.money then
                cost.money = math.floor(cost.money * (1 - staffDiscPct / 100))
            end
        elseif type(cost) == "number" then
            cost = math.floor(cost * (1 - staffDiscPct / 100))
        end
    end
    -- 每日限时折扣（叠加）
    local dailyDealApplied = false
    if RV2 and RV2.GetDailyDiscount then
        local dd = RV2.GetDailyDiscount()
        if dd and dd.key == key and not dd.used then
            if type(cost) == "table" then
                if cost.money then
                    cost.money = math.floor(cost.money * (100 - dd.pct) / 100)
                end
            elseif type(cost) == "number" then
                cost = math.floor(cost * (100 - dd.pct) / 100)
            end
            dailyDealApplied = true
        end
    end
    -- TabSubQuests 市场调研折扣（次日生效的升级折扣，值为0~1小数如0.15=15%off）
    local subqDiscountApplied = false
    local subqDisc = playerData_.activeShopDiscount
    if subqDisc and subqDisc > 0 then
        local discMult = 1.0 - subqDisc  -- 0.15 → 0.85
        if type(cost) == "table" then
            if cost.money then
                cost.money = math.floor(cost.money * discMult)
            end
        elseif type(cost) == "number" then
            cost = math.floor(cost * discMult)
        end
        subqDiscountApplied = true
    end
    if not CanAffordCost(cost) then return end
    -- 记录升级前的联动（用于完成时检测新联动激活）
    upgradeSynergiesBefore_ = {}
    local oldSynergies = CalcUpgradeSynergies()
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, s in ipairs(oldSynergies) do upgradeSynergiesBefore_[s.name] = true end
    local ok, payDesc = TryPayCost(cost)
    if not ok then return end
    if dailyDealApplied then
        if RV2 and RV2.MarkDailyDiscountUsed then RV2.MarkDailyDiscountUsed(key) end
        AddLog("🏷️ 限时特惠已使用！节省了大笔开支！")
    end
    if staffDiscPct > 0 then
        AddLog("👷 " .. (staffDiscWho or "员工") .. "帮忙省了" .. staffDiscPct .. "%费用！")
    end
    if subqDiscountApplied then
        AddLog("📋 市场调研折扣生效！节省" .. math.floor((subqDisc or 0) * 100) .. "%费用")
    end
    if IsCoupActive() then
        AddLog("🪖 政变期间升级，支付了" .. payDesc)
    end
    -- 启动升级计时器
    local buildTime = CalcUpgradeTime(cost, key)
    local daysNeeded = CalcUpgradeDaysNeeded(cost, key)
    activeUpgrade_ = key
    upgradeTotalTime_ = buildTime
    upgradeTimeLeft_ = buildTime
    upgradeCost_ = cost  -- 记录费用，用于日志
    -- 跨日建造：高级升级需要等待1-2天
    if daysNeeded > 0 then
        upgradeCompletionDay_ = (playerData_.day or 1) + daysNeeded
        upgradeTimeLeft_ = -1  -- 标记为跨日模式，不用实时计时
        AddLog("🏗️ 大工程启动！预计第" .. upgradeCompletionDay_ .. "天完工（跨日建造）")
    else
        upgradeCompletionDay_ = nil
    end
    CafeAnimEvents.Push("upgrade_start")
    PlaySFX("upgrade")
    AddLog(cfg.icon .. " " .. cfg.name .. " 开始升级 (" .. FormatUpgradeTime(buildTime) .. ")")
    BuildUI()
end

--- 完成升级：应用实际效果、播放音效、触发叙事
function CompleteUpgrade()
    local key = activeUpgrade_
    if not key then return end
    local cfg = UPGRADES[key]
    if not cfg then
        activeUpgrade_ = nil
        return
    end

    -- 🔒 安全保障：无论中间逻辑是否崩溃，升级状态一定被清除
    local function DoCompleteUpgrade()
        CafeAnimEvents.Push("upgrade_complete")
        -- P0-2：记录升级前收入（用于效果卡显示差值）
        local incomeBeforeUpgrade_ = 0
        ---@diagnostic disable-next-line: assign-type-mismatch
        pcall(function() incomeBeforeUpgrade_ = CalcDailyIncome() end)

        -- 应用升级效果
        playerData_.reputation = (playerData_.reputation or 0) + 5
    if key == "computer" then playerData_.computers = playerData_.computers + 1
    elseif key == "chair" then playerData_.chairLevel = playerData_.chairLevel + 1
    elseif key == "net" then playerData_.netSpeed = playerData_.netSpeed + 1
    elseif key == "ac" then playerData_.acLevel = playerData_.acLevel + 1
    elseif key == "solar" then playerData_.solarLevel = playerData_.solarLevel + 1
    elseif key == "food" then playerData_.foodShop = playerData_.foodShop + 1
    elseif key == "deco" then playerData_.decoLevel = playerData_.decoLevel + 1
    elseif key == "security" then playerData_.securityLevel = playerData_.securityLevel + 1
    elseif key == "generator" then
        playerData_.generatorLevel = (playerData_.generatorLevel or 0) + 1
        local capTable = { 20, 40, 60 }
        local fuelGift = { 10, 15, 20 }
        playerData_.fuelCapacity = capTable[playerData_.generatorLevel] or 60
        local gift = fuelGift[playerData_.generatorLevel] or 0
        playerData_.fuel = math.min((playerData_.fuel or 0) + gift, playerData_.fuelCapacity)
        AddLog("⛽ 获得油罐容量 " .. playerData_.fuelCapacity .. "L，赠送 " .. gift .. "L 燃油")
    elseif key == "well" then playerData_.wellLevel = (playerData_.wellLevel or 0) + 1
    elseif key == "road" then playerData_.roadLevel = (playerData_.roadLevel or 0) + 1
    elseif key == "coffee" then playerData_.coffeeLevel = (playerData_.coffeeLevel or 0) + 1
    elseif key == "jukebox" then playerData_.jukeboxLevel = (playerData_.jukeboxLevel or 0) + 1
    end

    -- 音效
    local sfxMap = { well = "well_water", road = "road_build", coffee = "coffee_brew", jukebox = "jukebox_play" }
    if sfxMap[key] then
        PlaySFX(sfxMap[key])
    else
        PlaySFX("upgrade")
    end
    PlaySFX("level_up")
    -- 微反馈：升级完成金色脉冲
    pcall(MFX_UpgradeFlash)
    -- 委托追踪
    playerData_.questUpgradeCount = (playerData_.questUpgradeCount or 0) + 1
    local cost = upgradeCost_ or 0
    AddLog(cfg.icon .. " " .. cfg.name .. " 升级完成！($" .. cost .. ")")

    -- ── 卫星天线叙事 ──
    if key == "net" and playerData_.netSpeed >= 5 and not storyTriggered_["satellite_installed"] then
        storyTriggered_["satellite_installed"] = true
        AddLog("📡 你把那个白色的大碟子搬上了屋顶。全村的人都围过来看热闹——")
        AddLog("  Uncle Charles说这是'从天上偷网的锅'，几个小孩爬到隔壁屋顶想看得更清楚。")
        AddLog("  你对准天空，调整角度。信号灯从红变黄、从黄变绿的那一刻，围观的人群发出了'哦——！'的欢呼。")
        AddLog("  Mama Blessing端来一盘烤鸡翅庆祝：'这是我们村的大日子。'")
        AddLog("  网速从蜗牛变成了火箭。第一个连上的客人看了五秒YouTube，眼眶竟然红了——他三年没看过视频了。")
        AddLog("  从今天起，Dragon Net Cafe不再只是一个网吧。它是这个村庄连接世界的唯一窗口。")
    end

    -- ── 网速里程碑叙事 ──
    if key == "net" and playerData_.netSpeed == 3 and not storyTriggered_["net_highspeed"] then
        storyTriggered_["net_highspeed"] = true
        AddLog("  升级到高速网络后，加载网页不再需要等三分钟了。有个客人激动地说：'图片居然能直接显示！不用等！'")
    elseif key == "net" and playerData_.netSpeed == 4 and not storyTriggered_["net_fiber"] then
        storyTriggered_["net_fiber"] = true
        AddLog("  光纤接入了。第一次打三角洲不卡的时候，整个网吧爆发出欢呼声。有人甚至站起来鼓掌。")
    end

    -- ── 水井叙事 ──
    if key == "well" and playerData_.wellLevel == 1 and not storyTriggered_["well_first"] then
        storyTriggered_["well_first"] = true
        AddLog("🚰 第一口水从井里涌出来的时候，围观的阿婆们发出了惊叹声。")
        AddLog("  Uncle Charles尝了一口：'比河水甜。'他眼里有什么东西在闪。")
        AddLog("  消息像风一样传遍了半个村子。下午，门口排起了打水的长队。")
        AddLog("  有人打完水，顺便问了句WiFi密码。你笑了。这才是做生意的格局。")
    end
    if key == "well" and playerData_.wellLevel >= 3 and not storyTriggered_["well_solar"] then
        storyTriggered_["well_solar"] = true
        AddLog("🚰 太阳能水泵装好了。它安静地运转着，像一颗不知疲倦的心脏。")
        AddLog("  村长专门过来握了你的手：'你给这个村子带来的，不只是网络。'")
        AddLog("  蓄水池边有人洗衣服、有人给牛饮水、有人在聊天。这口井成了村子的心脏。")
    end

    -- ── 修路叙事 ──
    if key == "road" and playerData_.roadLevel == 2 and not storyTriggered_["road_cement"] then
        storyTriggered_["road_cement"] = true
        AddLog("🛤️ 水泥路面铺好的那天，一辆小卡车第一次开到了你门口。")
        AddLog("  几个孩子追着卡车跑，笑声回荡在整条街。司机探出头：'这路不错啊！'")
        AddLog("  设备里的灰尘肉眼可见地少了。你摸了摸键盘——干净的，真好。")
    end
    if key == "road" and playerData_.roadLevel >= 3 and not storyTriggered_["road_tarmac"] then
        storyTriggered_["road_tarmac"] = true
        AddLog("🛤️ 柏油路铺好那天，整条街的人都出来看。黑色的路面在阳光下泛着光。")
        AddLog("  晚上太阳能路灯亮起来的时候，有人哭了。他说他活了四十年，第一次不用摸黑回家。")
        AddLog("  Mama Blessing站在路灯下拍了张照片发给城里的女儿：'你看，咱村也有路灯了。'")
        AddLog("  有人说：'这条路会改变一切。'你觉得他说得对。")
    end

    -- ── 咖啡吧台叙事 ──
    if key == "coffee" and playerData_.coffeeLevel == 2 and not storyTriggered_["coffee_barista"] then
        storyTriggered_["coffee_barista"] = true
        AddLog("☕ 手冲设备装好后，你用本地烘焙的豆子冲了第一杯。")
        AddLog("  一个从拉各斯来的年轻人喝了一口，愣了很久：'...这味道，和城里的咖啡馆一样。'")
        AddLog("  他的眼眶红了。你没问为什么。有些故事不需要解释，一杯咖啡就够了。")
    end

    -- ── 点唱机叙事 ──
    if key == "jukebox" and playerData_.jukeboxLevel == 1 and not storyTriggered_["jukebox_first"] then
        storyTriggered_["jukebox_first"] = true
        AddLog("🎵 老式点唱机通电的那一刻，整个网吧安静了三秒。")
        AddLog("  然后Fela Kuti的鼓点炸开了——'Zombie'的旋律让所有人开始点头。")
        AddLog("  一个正在打游戏的客人摘下耳机，跟着节奏摇起了头。音乐就是这片土地的血液。")
    end

    -- ── 联动激活反馈 ──
    local oldSynergyNames = upgradeSynergiesBefore_ or {}
    local newSynergies = CalcUpgradeSynergies()
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, s in ipairs(newSynergies) do
        if not oldSynergyNames[s.name] then
            AddLog("🔗 【联动激活】" .. s.name .. " — " .. s.desc)
            PlaySFX("level_up")
            TriggerCelebration()
        end
    end

    -- P2: 升级里程碑 → 触发市场奖励事件
    local okME, milestoneEvent = pcall(CheckUpgradeMilestoneMarketEvent)
    if okME and milestoneEvent then
        AddLog("🎁 【市场联动】" .. milestoneEvent)
        PlaySFX("reward")
    end

    -- P0-1 新手引导：完成第一次升级，step 1→2
    if (playerData_.tutorialStep or 0) == 1 then
        playerData_.tutorialStep = 2
        AddLog("📌 【新手任务】太棒了！升级完成！再结束一天，去日记里看看效果。")
    end

    -- P0-2 升级效果卡：记录升级完成，供 UI 展示反馈弹窗
    local incomeAfterUpgrade_ = 0
    ---@diagnostic disable-next-line: assign-type-mismatch
    pcall(function() incomeAfterUpgrade_ = CalcDailyIncome() end)
    pendingUpgradeFeedback_ = {
        key = key,
        icon = cfg.icon or "🔧",
        name = cfg.name or key,
        level = GetUpgradeCur(key),
        timestamp = gameTime_,
        incomeDelta = incomeAfterUpgrade_ - incomeBeforeUpgrade_,
    }

        -- 彩蛋：升级完成触发
        local eggOk, eggErr = pcall(function() require("EasterEggs").OnUpgradeComplete(key) end)
        if not eggOk then log:Write(LOG_WARNING, "[CompleteUpgrade] EasterEggs error: " .. tostring(eggErr)) end
    end -- DoCompleteUpgrade

    -- 执行升级逻辑（pcall 保护，确保清理一定执行）
    local ok, err = pcall(DoCompleteUpgrade)
    if not ok then
        log:Write(LOG_ERROR, "[CompleteUpgrade] CRASHED during upgrade '" .. tostring(key) .. "': " .. tostring(err))
        AddLog("⚠️ 升级完成时出现异常，已安全恢复")
    end

    -- 🔒 无论是否崩溃，升级状态一定被清除
    activeUpgrade_ = nil
    upgradeTimeLeft_ = 0
    upgradeTotalTime_ = 0
    upgradeCost_ = nil
    upgradeSynergiesBefore_ = nil
    BuildUI()
end

--- 广告跳过升级等待
function SkipUpgradeByAd()
    if not activeUpgrade_ then return end
    AdManager.ShowAd("upgrade_skip", playerData_.day, function()
        AddLog("📺 赞助商加速！升级立即完成！")
        CompleteUpgrade()
    end)
end

-- ============================================================================
-- 踢馆 (Cafe Challenge) 系统
-- ============================================================================

--- 发起踢馆
function StartCafeChallenge(npcData)
    if challengeDay_ == (playerData_.day or 1) then
        AddLog("⏳ 今天已经踢过馆了，明天再来吧！"); BuildUI(); return
    end
    if #teamMembers_ < 1 then
        AddLog("❌ 至少需要1名队员才能踢馆！"); PlaySFX("fail"); BuildUI(); return
    end
    if not UseActionPoint(1) then
        AddLog("⚡ 行动点不足，无法踢馆！"); PlaySFX("fail"); BuildUI(); return
    end

    challengeActive_ = true
    challengeDay_ = playerData_.day or 1
    challengeOpponent_ = npcData
    challengeRound_ = 0
    challengePlayerWins_ = 0
    challengeNPCWins_ = 0
    challengePhase_ = "select_wager"
    PlayBGM("challenge")

    -- 计算难度：基于双方网吧分数比
    local playerScore = CalcCafeScore()
    local npcScore = npcData.score or 100
    challengeNPCScore_ = npcScore
    challengeDifficulty_ = math.max(0.3, math.min(1.0, npcScore / math.max(1, playerScore) * 0.5 + 0.1))

    -- 计算倍率
    local ratio = npcScore / math.max(1, playerScore)
    if ratio >= 1.5 then challengeMultiplier_ = 2.5
    elseif ratio >= 1.2 then challengeMultiplier_ = 2.0
    elseif ratio >= 0.9 then challengeMultiplier_ = 1.5
    else challengeMultiplier_ = 1.2 end

    -- Ban/Pick 初始化：进入 ban_pick 阶段让玩家先Ban
    challengePlayerBan_ = nil
    challengeNPCBan_ = nil
    challengeBanPhase_ = "player"
    challengeModes_ = {}

    PlaySFX("event")
    AddLog("⚔️ 向 " .. (npcData.emoji or "") .. " " .. (npcData.name or "???") .. " 发起踢馆挑战！")

    currentPhase_ = PHASE_TRAIN
    BuildUI()
end

--- 确认赌注并开始第一轮
function ConfirmChallengeWager(wagerType, wagerAmount)
    -- 验证资源是否足够
    if wagerType == "money" and playerData_.money < wagerAmount then
        AddLog("💰 金钱不足！需要 $" .. wagerAmount .. "，当前 $" .. playerData_.money); PlaySFX("fail"); return
    end
    if wagerType == "computer" and playerData_.computers <= wagerAmount then
        AddLog("💻 电脑不足！需要 " .. wagerAmount .. " 台，当前 " .. playerData_.computers .. " 台"); PlaySFX("fail"); return
    end
    if wagerType == "reputation" and playerData_.reputation < wagerAmount then
        AddLog("⭐ 声望不足！需要 " .. wagerAmount .. "，当前 " .. playerData_.reputation); PlaySFX("fail"); return
    end

    challengeWagerType_ = wagerType
    challengeWagerAmount_ = wagerAmount
    challengePhase_ = "ban_pick"
    challengeBanPhase_ = "player"
    PlaySFX("click")
    BuildUI()
end

--- 开始当前踢馆轮次（启动小游戏）
function StartChallengeRound()
    local mode = challengeModes_[challengeRound_]
    if not mode then FinishChallenge(); return end

    challengePhase_ = "playing"
    -- 设置训练队员（踢馆时用第一个队员或虚拟占位）
    if not trainMember_ then
        if teamMembers_ and #teamMembers_ > 0 then
            trainMember_ = teamMembers_[1]
        else
            trainMember_ = { name = "选手", emoji = "🎮", trait = "踢馆中", skill = 50, mood = 70 }
        end
    end
    -- 启动训练游戏（复用训练系统）
    trainMode_ = mode
    trainPhase_ = "ready"
    trainActive_ = false
    trainTimer_ = 0
    trainScore_ = 0
    -- 重置各模式分数，防止 Bo3 跨轮分数泄漏
    quizCorrect_ = 0
    reactCorrect_ = 0
    routeCorrect_ = 0
    commCorrect_ = 0

    -- 训练走正常 ready→playing→done 流程（玩家点按钮开始）
    BuildUI()
end

--- 玩家执行 Ban（踢馆 Ban/Pick 阶段）
function ChallengePlayerBan(mode)
    challengePlayerBan_ = mode
    challengeBanPhase_ = "npc"
    -- NPC 自动 Ban：根据难度选一个对NPC不利的模式（随机从剩余模式中选）
    local remaining = {}
    for _, m in ipairs(challengeAllModes_) do
        if m ~= mode then table.insert(remaining, m) end
    end
    -- NPC 策略：高难度NPC倾向ban掉玩家擅长的（这里简化为随机）
    challengeNPCBan_ = remaining[math.random(1, #remaining)]
    challengeBanPhase_ = "done"

    -- 从剩余3个模式中随机排列作为Bo3赛程
    local finalModes = {}
    for _, m in ipairs(challengeAllModes_) do
        if m ~= challengePlayerBan_ and m ~= challengeNPCBan_ then
            table.insert(finalModes, m)
        end
    end
    -- 随机打乱顺序
    for i = #finalModes, 2, -1 do
        local j = math.random(1, i)
        finalModes[i], finalModes[j] = finalModes[j], finalModes[i]
    end
    challengeModes_ = finalModes

    PlaySFX("click")
    BuildUI()
end

--- 单轮踢馆结束（训练完成后调用）
function FinishChallengeRound()
    local mode = challengeModes_[challengeRound_]
    -- 从训练系统获取玩家分数
    local playerScore = 0
    if mode == "aim" then playerScore = trainScore_ or 0
    elseif mode == "quiz" then playerScore = quizCorrect_ or 0
    elseif mode == "memory" then playerScore = routeCorrect_ or 0
    elseif mode == "react" then playerScore = reactCorrect_ or 0
    elseif mode == "comm" then playerScore = commCorrect_ or 0
    end

    -- 综合分加成：玩家网吧综合分 vs NPC 综合分
    local cafeScore = CalcCafeScore()
    local npcCafeScore = (challengeOpponent_ or {}).score or 100
    -- 加成比例 = (我方综合分 - 对方综合分) / 对方综合分，裁剪到 [-30%, +30%]
    local bonusRatio = math.max(-0.3, math.min(0.3, (cafeScore - npcCafeScore) / math.max(1, npcCafeScore)))
    local bonus = math.floor(playerScore * bonusRatio)
    local rawPlayerScore = playerScore
    playerScore = math.max(0, playerScore + bonus)

    -- 计算NPC分数（基于难度和训练模式基准）
    local base = (CHALLENGE_NPC_THRESHOLDS or {})[mode] or 5
    local npcScore = math.floor(base * challengeDifficulty_ + math.random(-1, 1))
    npcScore = math.max(1, npcScore)
    challengeNPCScore_ = npcScore

    -- 平局时判定为玩家胜（主场优势）
    local playerWin = (playerScore >= npcScore)
    if playerWin then
        challengePlayerWins_ = challengePlayerWins_ + 1
    else
        challengeNPCWins_ = challengeNPCWins_ + 1
    end

    -- 存储本轮结果用于UI显示
    challengeRoundResult_ = {
        mode = mode,
        rawPlayerScore = rawPlayerScore,   -- 原始得分（加成前）
        bonus = bonus,                     -- 综合分加成值
        bonusPercent = math.floor(bonusRatio * 100), -- 加成百分比
        cafeScore = cafeScore,             -- 我方综合分
        npcCafeScore = npcCafeScore,       -- 对方综合分
        playerScore = playerScore,         -- 最终得分（含加成）
        npcScore = npcScore,
        playerWin = playerWin,
    }

    -- 清理训练状态
    trainMember_ = nil; trainActive_ = false; trainPhase_ = "ready"; trainMode_ = "select"

    -- 检查是否已分出胜负（Bo3 先到2胜）
    if challengePlayerWins_ >= 2 or challengeNPCWins_ >= 2 then
        challengePhase_ = "final"
    else
        challengePhase_ = "round_result"
    end
    BuildUI()
end

--- 踢馆总结算
function FinishChallenge()
    local won = challengePlayerWins_ >= 2
    local opp = challengeOpponent_ or {}
    local wType = challengeWagerType_
    local wAmt = challengeWagerAmount_
    local mult = challengeMultiplier_

    local effectLines = {}

    if won then
        -- 赢：返还赌注 + 赌注×倍率
        local reward = math.floor(wAmt * mult)
        if wType == "money" then
            playerData_.money = playerData_.money + reward
            table.insert(effectLines, "💰 赢得 $" .. reward)
        elseif wType == "computer" then
            playerData_.computers = playerData_.computers + reward
            table.insert(effectLines, "💻 赢得 " .. reward .. " 台电脑")
        elseif wType == "reputation" then
            playerData_.reputation = playerData_.reputation + reward
            table.insert(effectLines, "⭐ 赢得 " .. reward .. " 声望")
        end
        playerData_.reputation = playerData_.reputation + 10
        table.insert(effectLines, "⭐ 威名远扬 +10 声望")
        for _, m in ipairs(teamMembers_) do
            m.mood = math.min(100, m.mood + 5)
        end
        table.insert(effectLines, "😊 全队心情+5")
        PlaySFX("victory"); PlaySFX("crowd_cheer"); TriggerCelebration()
        AddLog("⚔️🏆 踢馆 " .. (opp.emoji or "") .. " " .. (opp.name or "") .. " 成功！" .. table.concat(effectLines, " | "))
    else
        -- 输：失去赌注
        if wType == "money" then
            playerData_.money = math.max(0, playerData_.money - wAmt)
            table.insert(effectLines, "💸 输了 $" .. wAmt)
        elseif wType == "computer" then
            playerData_.computers = math.max(1, playerData_.computers - wAmt)
            table.insert(effectLines, "💻 失去 " .. wAmt .. " 台电脑")
        elseif wType == "reputation" then
            playerData_.reputation = math.max(0, playerData_.reputation - wAmt)
            table.insert(effectLines, "⭐ 损失 " .. wAmt .. " 声望")
        end
        playerData_.reputation = math.max(0, playerData_.reputation - 5)
        table.insert(effectLines, "⭐ 名声受损 -5 声望")
        for _, m in ipairs(teamMembers_) do
            m.mood = math.max(0, m.mood - 3)
        end
        table.insert(effectLines, "😟 全队心情-3")
        PlaySFX("defeat")
        AddLog("⚔️💔 踢馆 " .. (opp.emoji or "") .. " " .. (opp.name or "") .. " 失败……" .. table.concat(effectLines, " | "))
    end

    -- 生成结果事件
    eventResult_ = {
        success = won,
        icon = won and "🏆" or "💔",
        title = "⚔️ 踢馆" .. (won and "成功！" or "失败"),
        narrative = won
            and ("你的队伍以 " .. challengePlayerWins_ .. ":" .. challengeNPCWins_ .. " 击败了 " .. (opp.emoji or "") .. " " .. (opp.name or "") .. "！\n\n"
                .. "对方老板不得不服气：'你们确实有实力！'\n\n周围的人纷纷鼓掌。Dragon Net Cafe的名声又上了一个台阶！")
            or ("你的队伍以 " .. challengePlayerWins_ .. ":" .. challengeNPCWins_ .. " 输给了 " .. (opp.emoji or "") .. " " .. (opp.name or "") .. "。\n\n"
                .. "对方老板得意地笑了：'下次再来啊！'\n\n虽然输了，但这次经验让队员们更加坚定了变强的决心。"),
        effects = table.concat(effectLines, "\n"),
        logText = "⚔️ 踢馆" .. (won and "胜" or "负") .. " vs " .. (opp.name or ""),
    }

    -- 重置踢馆状态
    challengeActive_ = false
    challengeOpponent_ = nil
    challengePhase_ = "select_wager"
    challengeRound_ = 0
    challengePlayerWins_ = 0
    challengeNPCWins_ = 0
    challengeModes_ = {}
    challengePlayerBan_ = nil
    challengeNPCBan_ = nil
    challengeBanPhase_ = "player"

    PlayBGM("manage")
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

function AddLog(text)
    local day = playerData_.day or 1
    table.insert(eventLog_, "第" .. day .. "天: " .. text)
    if #eventLog_ > 20 then table.remove(eventLog_, 1) end

    -- 同步写入日记系统
    if not diaryEntries_[day] then
        diaryEntries_[day] = { atmo = "", logs = {} }
    end
    table.insert(diaryEntries_[day].logs, text)
end

-- ═══════════════════════════════════════════════════
-- 精简Tab合并行动函数
-- ═══════════════════════════════════════════════════

--- 🤝 社区活动（街区Tab：合并请吃烤肉+社区互助+声望消耗）
function DoCommunityEvent()
    if not UseActionPoint(1) then return end
    playerData_.communityEventToday = true
    CafeAnimEvents.Push("community")

    -- 随机场景（含叙事段落）
    local scenes = {
        { icon = "📦", title = "帮忙搬家", rep = 12, money = 0,
          narrative = "隔壁Uncle Charles要搬新家具，你过去帮了一把。\n\n三个人抬着一张巨大的木床爬楼梯，差点卡在拐角。\n\n「中国老板力气大！」他硬塞给你几瓶Fanta。" },
        { icon = "📚", title = "临时教室", rep = 20, money = 0,
          narrative = "附近学校又停电了，十几个学生背着书包站在路边发愁。\n\n你把网吧后面几台电脑让出来：「来吧，在这写作业。」\n\n家长们晚上来接孩子，专门买了一箱芬达放在前台。" },
        { icon = "🍖", title = "街区烧烤", rep = 15, money = -30,
          narrative = "你从Mama Blessing那买了一堆Suya串，在网吧门口支起炭火。\n\n半条街的人都凑过来了。Big Joe边吃边喊：\n「Dragon老板请客！以后我罩着你！」\n\n花了点钱，但整条街都记住了你。" },
        { icon = "🏪", title = "帮人看摊", rep = 8, money = 25,
          narrative = "小贩Kofi说要去医院看老婆，求你帮看半天摊。\n\n你坐在太阳底下卖了半天充电线和手机壳。\n\n他回来时塞给你一些转卖的小玩意：「够意思，兄弟！」" },
        { icon = "🤝", title = "调解纠纷", rep = 18, money = 0,
          narrative = "两家邻居因为排水沟的事吵了三天。你主动过去当和事佬。\n\n一番劝说后，双方握手言和，还各请你喝了杯冰水。\n\n「中国人会做生意，也会做人。」你听到有人背后这么说。" },
        { icon = "🧹", title = "社区清洁日", rep = 10, money = 0,
          narrative = "今天是社区卫生日，你拿了把扫帚主动打扫门口一条街。\n\n路过的人纷纷竖大拇指。有个大叔停下摩托：\n「老板，你这样的人开店不火才怪！」" },
    }
    local scene = scenes[math.random(1, #scenes)]
    local repGain = scene.rep + math.random(0, 5)
    playerData_.reputation = (playerData_.reputation or 0) + repGain
    if scene.money ~= 0 then
        playerData_.money = (playerData_.money or 0) + scene.money
        if scene.money > 0 then
            playerData_.totalEarnings = (playerData_.totalEarnings or 0) + scene.money
        end
    end

    -- 20%概率触发情报支线（嵌入叙事末句）
    local intelText = ""
    if math.random() < 0.2 then
        playerData_.storedIntel = "rumor_tip"
        intelText = "\n\n💬 临走时有人拉住你悄悄说：「明天集市有批好货要出，你留意一下。」"
    end

    local effectStr = "⭐ 声望+" .. repGain
    if scene.money > 0 then effectStr = effectStr .. " · 💰+$" .. scene.money end
    if scene.money < 0 then effectStr = effectStr .. " · 💰-$" .. math.abs(scene.money) end

    eventResult_ = {
        success = true,
        icon = scene.icon,
        title = "🤝 社区活动 · " .. scene.title,
        narrative = scene.narrative .. intelText,
        effects = effectStr,
        logText = "🤝 " .. scene.title .. " — 声望+" .. repGain,
    }
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

--- 🏗️ 地盘经营（街区Tab Day12+：花钱换3天被动收入+声望）
function DoTerritoryManage()
    if not UseActionPoint(1) then return end
    if (playerData_.money or 0) < 100 then return end
    playerData_.money = playerData_.money - 100
    playerData_.territoryManagedToday = true
    pcall(MFX_MoneyPop, -100)

    playerData_.reputation = (playerData_.reputation or 0) + 15
    -- 设置3天被动收入
    playerData_.territoryIncomeDays = 3
    playerData_.territoryIncomePerDay = 40 + math.floor((playerData_.day or 1) * 2)

    local scenarios = {
        "你请Big Joe喝了杯啤酒，聊了聊街区的事。他拍着胸脯说以后这片有事找他。",
        "你给街区几个小摊贩送了充电宝，他们答应帮你看场子、带客人。",
        "你花钱请人把网吧门口的路修了修，整条街的人都说你够意思。",
        "你赞助了街区足球队的比赛用水，队员们说以后来上网打折。",
    }
    local desc = scenarios[math.random(1, #scenarios)]
    AddLog("🏗️ " .. desc .. " 声望+15，接下来3天每天+$" .. playerData_.territoryIncomePerDay)

    ShowActionResult({
        icon = "🏗️",
        title = "地盘打点完成",
        desc = desc,
        effects = {
            "⭐ 声望 +15",
            "💰 接下来3天每天 +$" .. playerData_.territoryIncomePerDay,
            "💸 花费 $100",
        },
    })
end

--- 🎲 冒险生意（投资Tab：合并二手淘宝+接包场+信息差套利）
function DoRiskyBusiness(investment)
    if not UseActionPoint(1) then return end
    if (playerData_.money or 0) < investment then return end
    PlayBGM("invest")
    playerData_.money = playerData_.money - investment
    playerData_.riskyBizToday = true
    pcall(MFX_MoneyPop, -investment)

    -- 成功率基础50%，有情报加成+20%，有tradeBoost+50%
    local successRate = 50
    if playerData_.storedIntel then successRate = successRate + 20; playerData_.storedIntel = nil end
    if playerData_.tradeBoostNext then successRate = successRate + 50; playerData_.tradeBoostNext = nil end
    successRate = math.min(95, successRate)

    local roll = math.random(1, 100)
    if roll <= successRate then
        -- 成功：1.5x ~ 3x 回报
        local multi = 1.5 + math.random() * 1.5
        local profit = math.floor(investment * multi)
        playerData_.money = playerData_.money + profit
        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + (profit - investment)
        pcall(MFX_MoneyPop, profit)
        local scenes = {
            { icon = "🖥️", title = "淘到好货",
              narrative = "你在二手市场翻了半天，终于在角落发现一批旧显卡。\n\n卖家是个急着回乡的矿老板，开价很低。你假装犹豫了一下，其实心里已经乐开了花。\n\n转手挂到Facebook Marketplace，当天就有人来收——利润翻倍。" },
            { icon = "🎉", title = "包场大单",
              narrative = "有个NGO组织找上门，要包场搞团建活动。\n\n你临时把网吧布置了一下，还准备了饮料和零食。活动结束后对方负责人握着你的手说：\n\n「太专业了！下次还找你！」说完多塞了一笔小费。" },
            { icon = "📊", title = "信息差套利",
              narrative = "上次社区活动听来的消息果然靠谱——一批二手路由器在港口清关价很低。\n\n你提前预定了一批，转天价格就涨回去了。\n买进卖出，干净利落。做生意的感觉，真好。" },
            { icon = "🔌", title = "代购赚差价",
              narrative = "一个网吧老板托你帮忙从中国代购电源线和网线。\n\n你联系了国内的老同学，整了两大箱发过来。成本价卖给同行，中间的差价就是纯利润。\n\n「中国人做生意就是靠谱！」老板竖起大拇指。" },
        }
        local scene = scenes[math.random(1, #scenes)]
        local netProfit = profit - investment
        AddLog("🎲 " .. scene.title .. " — 投入$" .. investment .. " → 净赚$" .. netProfit .. "！")

        eventResult_ = {
            success = true,
            icon = scene.icon,
            title = "🎲 冒险生意 · " .. scene.title,
            narrative = scene.narrative,
            effects = "💰 投入$" .. investment .. " → 收回$" .. profit .. "（净赚$" .. netProfit .. "）",
            logText = "🎲 " .. scene.title .. " — 净赚$" .. netProfit,
        }
    else
        -- 失败：血本无归
        local scenes = {
            { icon = "💔", title = "翻新陷阱",
              narrative = "你兴冲冲从二手市场扛回一堆「九成新」显卡。\n\n回来拆开一看——全是矿卡翻新的，芯片都烧焦了。找卖家？人早跑了。\n\n你坐在一堆电子垃圾中间，沉默了很久。" },
            { icon = "💔", title = "爽约客户",
              narrative = "说好的包场活动，你提前准备了一整天——\n布置场地、备好饮料、还特意擦了所有屏幕。\n\n结果客户一条短信：「不好意思，取消了。」\n连定金都没给。你看着空荡荡的网吧，长叹一口气。" },
            { icon = "💔", title = "过期情报",
              narrative = "那条「内部消息」看来已经过时了。\n\n你买入的那批货，市场价第二天就崩了。想转手都没人要。\n\n教训：在这里，消息的保质期比酸奶还短。" },
            { icon = "💔", title = "中间商跑路",
              narrative = "你把钱打给了中间人，约好三天后交货。\n\n三天后电话打不通。五天后有人告诉你：\n「那个Ade啊？他上周就坐大巴回老家了。」\n\n又交了一笔学费。" },
        }
        local scene = scenes[math.random(1, #scenes)]
        AddLog("🎲 " .. scene.title .. " — 亏了$" .. investment .. "！")

        eventResult_ = {
            success = false,
            icon = scene.icon,
            title = "🎲 冒险生意 · " .. scene.title,
            narrative = scene.narrative,
            effects = "💸 血本无归，亏损 $" .. investment,
            logText = "🎲 " .. scene.title .. " — 亏了$" .. investment,
        }
    end
    currentPhase_ = PHASE_EVENT
    BuildUI()
end

--- 📈 大额投资（投资Tab Day12+：投入资金，3天后结算）
function DoBigInvestment(minAmount)
    if not UseActionPoint(1) then return end
    if (playerData_.money or 0) < minAmount then return end
    PlayBGM("invest")
    -- 投入全部可用资金的50%~80%，至少 minAmount
    local investAmount = math.max(minAmount, math.floor((playerData_.money or 0) * (0.5 + math.random() * 0.3)))
    investAmount = math.min(investAmount, playerData_.money)  -- 不超过余额

    playerData_.money = playerData_.money - investAmount
    pcall(MFX_MoneyPop, -investAmount)
    playerData_.partnerInvestment = {
        amount = investAmount,
        returnDay = (playerData_.day or 1) + 3,
        successRate = playerData_.tradeBoostNext and 70 or 55,
    }
    if playerData_.tradeBoostNext then playerData_.tradeBoostNext = nil end

    local returnDay = playerData_.partnerInvestment.returnDay
    AddLog("📈 你投入了$" .. investAmount .. "做大额投资，第" .. returnDay .. "天结算。")

    ShowActionResult({
        icon = "📈",
        title = "大额投资已托付",
        desc = "合伙人拍着胸脯说「信我，稳赚不赔」……\n你把$" .. investAmount .. "交到他手上，心里默念：但愿如此。",
        effects = {
            "💸 投入 $" .. investAmount,
            "📅 第" .. returnDay .. "天结算",
            "🎯 成功率 " .. playerData_.partnerInvestment.successRate .. "%",
        },
        color = { 180, 160, 255, 255 },  -- 紫色调表示等待
    })
end

--- 🔧 打零工（副业Tab：合并修手机+摆摊+代收快递）
function DoOddJob(basePay)
    if not UseActionPoint(1) then return end
    playerData_.oddJobToday = true
    CafeAnimEvents.Push("odd_job")

    -- 随机打工场景
    local jobs = {
        { text = "帮邻居修了个路由器", pay = 1.0 },
        { text = "在网吧门口摆摊卖了些二手光盘", pay = 0.9 },
        { text = "帮快递站分拣了一下午包裹", pay = 1.2 },
        { text = "给隔壁餐厅装了个收银系统", pay = 1.4 },
        { text = "帮人安装了几台电脑系统", pay = 1.1 },
        { text = "代收了一堆快递，顺便赚了小费", pay = 0.8 },
    }
    local job = jobs[math.random(1, #jobs)]
    local finalPay = math.floor(basePay * job.pay)
    playerData_.money = (playerData_.money or 0) + finalPay
    playerData_.totalEarnings = (playerData_.totalEarnings or 0) + finalPay
    pcall(MFX_MoneyPop, finalPay)

    AddLog("🔧 " .. job.text .. "，赚了$" .. finalPay)
    -- 小概率声望+5
    local repGain = 0
    if math.random() < 0.3 then
        repGain = 5
        playerData_.reputation = (playerData_.reputation or 0) + repGain
        AddLog("   邻居夸你手艺好，口碑传开了。声望+5")
    end

    -- 结果弹窗
    local effects = { "💰 收入 +$" .. finalPay }
    if repGain > 0 then table.insert(effects, "⭐ 声望 +" .. repGain) end
    ShowActionResult({
        icon = "🔧",
        title = "打零工完成",
        desc = job.text,
        effects = effects,
    })
end

--- 🎓 辅导补习（副业Tab Day12+：高收益，消耗2AP）
function DoTutoring(fee)
    if not UseActionPoint(2) then return end
    playerData_.tutorDoneToday = true
    CafeAnimEvents.Push("tutoring")

    playerData_.money = (playerData_.money or 0) + fee
    playerData_.totalEarnings = (playerData_.totalEarnings or 0) + fee
    playerData_.reputation = (playerData_.reputation or 0) + 8
    pcall(MFX_MoneyPop, fee)

    local subjects = {
        { name = "电脑基础", desc = "教几个大叔大婶开机关机、打开浏览器。他们学会发WhatsApp消息后激动得不行。" },
        { name = "打字练习", desc = "三个学生跟你学打字。最小的那个用两根食指戳，居然比另外俩还快。" },
        { name = "互联网入门", desc = "几个年轻人想学怎么在网上做小生意。你把淘宝、拼多多的模式给他们讲了讲。" },
        { name = "办公软件", desc = "教一个小商人用Excel记账。他说之前全靠脑子记，经常算错。" },
        { name = "基础编程", desc = "有个聪明小孩想学编程。你教他写了个「Hello World」，他兴奋得跳起来。" },
    }
    local sub = subjects[math.random(1, #subjects)]
    AddLog("🎓 教了几个学生【" .. sub.name .. "】，收了$" .. fee .. "学费。声望+8")

    ShowActionResult({
        icon = "🎓",
        title = "辅导补习完成",
        desc = sub.desc,
        effects = {
            "💰 学费收入 +$" .. fee,
            "⭐ 声望 +8",
        },
        color = { 160, 220, 255, 255 },  -- 蓝色调
    })
end

--- 📖 学一招（副业Tab：合并听广播+市场调研 → 随机buff）
function DoLearnSkill()
    if not UseActionPoint(1) then return end
    playerData_.learnedSkillToday = true

    -- 随机学到的技能/buff
    local skills = {
        { text = "从广播里学到了一个维修小技巧", effect = "repair", value = 3 },
        { text = "看了段经营管理的教学视频", effect = "manage", value = 2 },
        { text = "跟老主顾聊了会社交技巧", effect = "social", value = 3 },
        { text = "研究了一下明天的市场行情", effect = "discount", value = 15 },
        { text = "学会了一种新的电脑故障排查法", effect = "repair", value = 5 },
        { text = "琢磨出一个省电省钱的小窍门", effect = "save", value = 20 },
    }
    local skill = skills[math.random(1, #skills)]

    local effectText = ""
    if skill.effect == "repair" then
        -- 提升维修成功率（影响修手机收益）
        playerData_.repairBonus = (playerData_.repairBonus or 0) + skill.value
        effectText = "🔧 维修技术永久 +" .. skill.value
        AddLog("📖 " .. skill.text .. "。维修技术永久+" .. skill.value)
    elseif skill.effect == "manage" then
        -- 提升经营效率（影响日收入）
        playerData_.manageBonus = (playerData_.manageBonus or 0) + skill.value
        effectText = "📊 经营能力永久 +" .. skill.value
        AddLog("📖 " .. skill.text .. "。经营能力永久+" .. skill.value)
    elseif skill.effect == "social" then
        -- 直接加声望
        playerData_.reputation = (playerData_.reputation or 0) + skill.value * 3
        effectText = "⭐ 声望 +" .. (skill.value * 3)
        AddLog("📖 " .. skill.text .. "。声望+" .. (skill.value * 3))
    elseif skill.effect == "discount" then
        -- 明日购物折扣
        playerData_.tomorrowDiscount = skill.value
        effectText = "🏷️ 明日购物/升级享 " .. skill.value .. "% 折扣"
        AddLog("📖 " .. skill.text .. "。明天购物/升级享" .. skill.value .. "%折扣！")
    elseif skill.effect == "save" then
        -- 直接省钱（加现金）
        playerData_.money = (playerData_.money or 0) + skill.value
        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + skill.value
        effectText = "💰 省下了 $" .. skill.value
        AddLog("📖 " .. skill.text .. "。省下了$" .. skill.value)
    end

    -- 结果弹窗
    ShowActionResult({
        icon = "📖",
        title = "学到新技能",
        desc = skill.text,
        effects = { effectText },
        color = { 160, 220, 255, 255 },  -- 蓝色调区分学习
    })
end
