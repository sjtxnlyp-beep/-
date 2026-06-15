---@diagnostic disable: undefined-global
-- ============================================================================
-- RetentionV2.lua — 留存增强系统 v2
-- 包含：零AP小事件 / Day1悬念 / 新手加速 / 免费迷你游戏 / 即时反馈
--       AP扩容 / 离线增强 / 黄金时段 / 赛季通行证 / 团队羁绊 / 比赛微操
-- ============================================================================

local RV2 = {}

-- ============================================================================
-- 方案3: 零AP小事件系统（每天2-3个免费互动事件，30-60秒）
-- ============================================================================

local MICRO_EVENTS = {
    -- ── 网吧日常 ──
    { id = "me_wifi_password", title = "📶 WiFi密码风波",
      desc = "一个大叔拿着老旧手机来问WiFi密码，怎么都连不上。",
      choices = {
          { text = "🤝 耐心帮他设置", reward = { rep = 3 }, result = "大叔感激不尽，说要介绍朋友来玩！声望+3" },
          { text = "📝 写在纸上给他", reward = { rep = 1 }, result = "大叔摸索了半天终于连上了。声望+1" },
      }},
    { id = "me_power_flicker", title = "💡 灯泡闪烁",
      desc = "网吧角落的灯泡开始闪烁，有客人抱怨头晕。",
      choices = {
          { text = "🔧 立刻换灯泡($20)", reward = { rep = 5, money = -20 }, result = "新灯泡亮堂堂的，客人们很满意！声望+5" },
          { text = "🤷 等下班再说", reward = { rep = -2 }, result = "客人不太高兴，但也没说什么。声望-2" },
      }},
    { id = "me_stray_cat", title = "🐱 流浪猫来访",
      desc = "一只瘦小的猫咪溜进了网吧，在空调下面睡着了。",
      choices = {
          { text = "🐟 给它一点吃的", reward = { rep = 3, karma = 1 }, result = "小猫吃饱后蹭了蹭你的腿。客人们纷纷拍照，气氛变好了！声望+3" },
          { text = "😸 让它当网吧吉祥物", reward = { rep = 5 }, result = "猫咪成了网吧明星！好几个客人说\"冲着猫来的\"。声望+5" },
      }},
    { id = "me_music_request", title = "🎵 点歌请求",
      desc = "一桌年轻人想在网吧放他们喜欢的Afrobeats音乐。",
      choices = {
          { text = "🔊 开大音量满足他们", reward = { rep = 2 }, result = "全场气氛嗨起来了！有人开始跟着节奏晃。声望+2" },
          { text = "🎧 给他们借耳机", reward = { rep = 3 }, result = "照顾了其他客人的感受，年轻人也觉得你很周到。声望+3" },
      }},
    { id = "me_phone_charge", title = "🔌 借充电",
      desc = "一个学生手机快没电了，问能不能借用插座充电。",
      choices = {
          { text = "⚡ 免费充！顺便推荐他玩一把", reward = { money = 15, rep = 2 }, result = "学生充上电后顺便开了一局游戏。$15+声望2" },
          { text = "💰 收$5充电费", reward = { money = 5 }, result = "小赚一笔，虽然学生有点肉疼。$5" },
      }},
    { id = "me_broken_mouse", title = "🖱️ 鼠标打滑",
      desc = "3号机的鼠标突然不灵了，正在打排位的客人急得跳脚！",
      choices = {
          { text = "🏃 火速换一个新鼠标", reward = { rep = 5, money = -10 }, result = "客人感激涕零，排位没掉分！声望+5" },
          { text = "🔧 拆开吹一吹修一修", reward = { rep = 2 }, result = "修好了！虽然等了两分钟，但省了钱。声望+2" },
      }},
    { id = "me_kid_homework", title = "📚 写作业的孩子",
      desc = "一个小学生偷偷来网吧，说要\"查资料写作业\"，其实想玩游戏。",
      choices = {
          { text = "📖 帮他查完资料再玩30分钟", reward = { rep = 5, karma = 2 }, result = "作业写完了，游戏也玩了！他说你是最好的老板。声望+5" },
          { text = "📱 打电话给他家长", reward = { karma = 1, rep = -1 }, result = "家长来领人了，孩子虽然不开心，但你做了正确的事。" },
      }},
    { id = "me_influencer", title = "📸 网红来访",
      desc = "一个有5000粉丝的本地网红走进来，想拍个视频。",
      choices = {
          { text = "🎬 热烈欢迎，免费请他玩", reward = { rep = 8, money = -30 }, result = "视频获得了3000播放量！一波新客人涌入。声望+8" },
          { text = "🤝 正常接待，不特殊对待", reward = { rep = 2 }, result = "网红觉得你很真实，给了个好评。声望+2" },
      }},
    { id = "me_rain_leak", title = "🌧️ 屋顶漏雨",
      desc = "突然下起暴雨，铁皮屋顶漏了一滴水，正好滴在键盘上！",
      choices = {
          { text = "🪣 赶紧拿桶接着", reward = { rep = 2 }, result = "反应及时！键盘没事，客人夸你靠谱。声望+2" },
          { text = "🔨 顺便修一下屋顶($30)", reward = { rep = 5, money = -30 }, result = "花钱修了屋顶，以后不会再漏了！声望+5" },
      }},
    { id = "me_food_delivery", title = "🍕 外卖小哥走错门",
      desc = "外卖小哥把隔壁的订单送到了你这里——是一大盒Suya烤肉！",
      choices = {
          { text = "🏃 追出去还给他", reward = { karma = 2, rep = 3 }, result = "外卖小哥感激不尽，说以后给你打折！声望+3" },
          { text = "😋 买下来请客人吃", reward = { money = -25, rep = 5 }, result = "全场免费烤肉！客人们嗨翻了！声望+5" },
      }},
    { id = "me_power_bank", title = "🔋 充电宝交换",
      desc = "常客Kwame的手机没电了，问能不能用充电宝换一小时上网时间。",
      choices = {
          { text = "🤝 可以，朋友嘛", reward = { rep = 3 }, result = "Kwame感动了，说要带更多朋友来。声望+3" },
          { text = "💰 不行，但给你打个折", reward = { money = 10, rep = 1 }, result = "Kwame掏了钱，没什么不满。$10+声望1" },
      }},
    { id = "me_tournament_poster", title = "🏆 海报设计",
      desc = "你想在网吧门口贴一张比赛海报吸引客流，该怎么设计？",
      choices = {
          { text = "🎨 花$40请人画一张超酷的", reward = { money = -40, rep = 8 }, result = "专业海报引来了不少路人！声望+8" },
          { text = "✍️ 自己手画一张", reward = { rep = 3 }, result = "虽然画功一般，但诚意满满，有人驻足观看。声望+3" },
      }},
    { id = "me_lost_usb", title = "💾 失物招领",
      desc = "打扫卫生时发现座位下面有一个U盘，里面好像有重要文件。",
      choices = {
          { text = "📢 发朋友圈寻找失主", reward = { rep = 5, karma = 2 }, result = "失主找到了！是个大学生的毕业论文，感激得请你喝饮料。声望+5" },
          { text = "🗄️ 放前台等人来认领", reward = { rep = 2 }, result = "U盘放在前台等着，希望主人能回来找。声望+2" },
      }},
    { id = "me_ac_fight", title = "❄️ 空调温度之争",
      desc = "两桌客人因为空调温度吵起来了——一桌嫌冷一桌嫌热。",
      choices = {
          { text = "🌡️ 调到中间温度各退一步", reward = { rep = 3 }, result = "和平解决！双方都接受了。声望+3" },
          { text = "🧊 给怕热的那桌送冰水", reward = { money = -5, rep = 5 }, result = "一杯冰水化解了矛盾。老板的智慧！声望+5" },
      }},
    { id = "me_birthday", title = "🎂 客人生日",
      desc = "常客今天过生日，他的朋友们都来了，想在网吧庆祝。",
      choices = {
          { text = "🎉 免费送一小时+唱生日歌", reward = { money = -20, rep = 8 }, result = "全场一起唱生日歌！感动哭了，发了朋友圈夸你。声望+8" },
          { text = "🎁 送个小礼物", reward = { money = -10, rep = 5 }, result = "小小心意大大感动！声望+5" },
      }},
}

--- 生成每日零AP微事件
---@return table 今天的微事件列表 (2-3个)
function RV2.GenerateMicroEvents()
    local count = math.random(2, 3)
    local pool = {}
    -- 过滤今天已触发过的
    local usedToday = playerData_.microEventsUsed or {}
    for _, me in ipairs(MICRO_EVENTS) do
        if not usedToday[me.id] then
            table.insert(pool, me)
        end
    end
    -- 随机选取
    local selected = {}
    for i = 1, math.min(count, #pool) do
        local idx = math.random(1, #pool)
        table.insert(selected, pool[idx])
        table.remove(pool, idx)
    end
    return selected
end

--- 应用微事件选择奖励
---@param eventId string 事件ID
---@param choiceIdx number 选项索引
---@return string 结果描述
function RV2.ResolveMicroEvent(eventId, choiceIdx)
    for _, me in ipairs(MICRO_EVENTS) do
        if me.id == eventId then
            local choice = me.choices[choiceIdx]
            if not choice then return "无效选择" end
            local r = choice.reward or {}
            if r.money then playerData_.money = playerData_.money + r.money end
            if r.rep then playerData_.reputation = playerData_.reputation + r.rep end
            if r.karma then playerData_.karma = (playerData_.karma or 0) + r.karma end
            -- 标记已用
            if not playerData_.microEventsUsed then playerData_.microEventsUsed = {} end
            playerData_.microEventsUsed[eventId] = true
            playerData_.microEventsToday = (playerData_.microEventsToday or 0) + 1
            -- 赛季通行证积分
            RV2.AddSeasonPoints(1, "微事件")
            PlaySFX("coin_collect")
            return choice.result
        end
    end
    return "事件未找到"
end

-- ============================================================================
-- 方案4: Day1结尾悬念系统
-- ============================================================================

local DAY1_CLIFFHANGER = {
    title = "🌙 街区的夜晚",
    desc = "关店后，你正要锁门。隔壁五金店的 Kwaku 正好路过，停下来跟你搭话。\n\n\"新来的，第一天怎么样？\" 他递给你一瓶汽水。\n\"这条街晚上还算安全，但别太晚关门。先和附近人混个脸熟，以后有事好互相照应。\"\n\n他指了指街角那家小卖部：\"Auntie Efua 白天没空，但她消息最灵通。有什么风吹草动她都知道。\"",
    result = "💡 第一天平安结束。Kwaku 的建议值得记住——在这条街，邻里关系比什么都重要。",
    preview = "🌅 第一天结束了。明天开始，真正的经营挑战才刚刚开始……",
}

local DAY2_PAYOFF = {
    title = "☀️ 清晨来电",
    image = "image/day2_rent_crisis_20260615054239.png",
    desc = "一大早，手机响了。是房东 Mr. Okafor：\n\n\"小伙子，第一天生意怎么样？提醒你——房租$150加水电$80，今天到期。\"\n\n你看了看账本……这第二天比想象中来得更猛。",
    type = "choice",
    choices = {
        { text = "💰 全额付清，安心经营",
          effect = function()
              playerData_.money = playerData_.money - 230
              playerData_.reputation = playerData_.reputation + 5
          end,
          result = "你转账$230给房东。Mr. Okafor 很满意：\"准时付款的租户我最喜欢了。有什么需要修的跟我说。\"\n\n$-230，但房东关系+1。经营从守信开始。" },
        { text = "🤝 先付房租，水电下周补",
          effect = function()
              playerData_.money = playerData_.money - 150
          end,
          result = "\"Mr. Okafor，房租我先付了，水电这周补上行吗？\"他犹豫了一下：\"行，别超过周五。\"\n\n$-150。你为自己争取到了几天喘息时间。" },
        { text = "🧠 跟房东商量分期方案",
          effect = function()
              playerData_.reputation = playerData_.reputation + 3
          end,
          result = "\"Okafor 先生，我刚开业没多久，能不能前三个月房租月底付？\"他想了想：\"看在你把店面收拾得干净的份上——行。但水电不能欠。\"\n\n声望+3。好的谈判为你赢得缓冲。" },
    },
}

--- 获取Day1悬念事件
function RV2.GetDay1Cliffhanger()
    return DAY1_CLIFFHANGER
end

--- 获取Day2呼应事件
function RV2.GetDay2Payoff()
    return DAY2_PAYOFF
end

--- 获取Day1悬念预告（用于明日预告）
function RV2.GetDay1SuspensePreview()
    return DAY1_CLIFFHANGER.preview
end

-- ============================================================================
-- 方案5: 新手前3天加速体验
-- ============================================================================

--- 获取今日AP上限（前3天=5，之后=3/基础）
---@param day number
---@return number
function RV2.GetDailyAP(day)
    local baseAP = playerData_.baseAP or 3
    if day <= 5 then
        return math.max(6, baseAP)  -- 新手保护期(Day1-5)：至少6点AP
    end
    return baseAP
end

--- 获取新手期升级折扣
---@param day number
---@return number 折扣比例(0.7 = 七折, 1.0 = 全价)
function RV2.GetNewbieDiscount(day)
    if day <= 5 then return 0.7 end  -- 新手保护期(Day1-5)：首批升级七折
    return 1.0
end

--- 检查新手期特殊奖励
---@param day number 即将进入的新一天
---@return table|nil 特殊奖励事件
function RV2.CheckNewbieBonus(day)
    if day == 2 and #teamMembers_ < 1 and #CANDIDATE_POOL > 0 then
        -- Day2: 免费送一个队员（从候选池选最低费用的）
        local cheapest = nil
        local cheapIdx = nil
        for i, c in ipairs(CANDIDATE_POOL) do
            if not cheapest or c.fee < cheapest.fee then
                cheapest = c; cheapIdx = i
            end
        end
        if cheapest then
            local cheapName = cheapest.name  -- 捕获名字用于延迟查找
            return {
                title = "🎁 天降队友",
                desc = "一个叫 " .. cheapest.name .. " " .. cheapest.emoji .. " 的人在门口徘徊很久了。\n\"老板，我不要工资，让我加入战队吧！我每天帮你看店就行！\"\n\n（" .. cheapest.trait .. "）",
                type = "choice",
                choices = {
                    { text = "🤝 欢迎加入Dragon Force！",
                      effect = function()
                          -- 延迟执行时通过名字重新查找候选人索引（防止池变动导致索引错位）
                          local foundIdx = nil
                          local foundCandidate = nil
                          for i, c in ipairs(CANDIDATE_POOL) do
                              if c.name == cheapName then
                                  foundIdx = i
                                  foundCandidate = c
                                  break
                              end
                          end
                          if foundCandidate and foundIdx then
                              foundCandidate.fee = 0  -- 前3天免工资
                              table.insert(teamMembers_, foundCandidate)
                              table.remove(CANDIDATE_POOL, foundIdx)
                          end
                          playerData_.reputation = playerData_.reputation + 5
                      end,
                      result = cheapest.name .. " 激动得差点哭了！\"老板你不会后悔的！\"\n\n🎮 免费获得队员 " .. cheapest.name .. "！前3天不收工资！" },
                },
            }
        end
    elseif day == 3 then
        -- Day3: 免费参加一场友谊赛的提示
        return {
            title = "📢 社区比赛邀请",
            desc = "社区活动中心的人来了：\"明天有个小型电竞赛，你们战队要不要参加？报名免费！\"",
            type = "auto",
            autoResult = "友谊赛免费参加！快去「经营」页面试试比赛系统吧！",
            effect = function()
                playerData_.freeMatchToday = true
            end,
        }
    elseif day == 6 then
        -- Day6: 免费抽卡 + 市场系统引导
        return {
            title = "🎰 二手市场开张了！",
            desc = "一辆满载旧货的皮卡停在门口，司机递给你一张传单：\n\n\"新开的二手电子市场！今天试营业，首次抽取免费！里面有各种二手零件、装饰品、甚至传说级收藏品！\"\n\nMama B探过头来：\"我表侄在那里工作，你去看看嘛！\"",
            type = "choice",
            choices = {
                { text = "🎁 免费抽一次看看！",
                  effect = function()
                      playerData_.marketFreeDraws = (playerData_.marketFreeDraws or 0) + 2
                      playerData_.reputation = playerData_.reputation + 3
                  end,
                  result = "你拿到了2张免费抽取券！市场里琳琅满目的东西让人眼花缭乱。\n\n🎫 获得2次免费抽取！前往「市场」标签页试试手气！\n声望+3" },
            },
        }
    elseif day == 7 then
        -- Day7: 强制免费友谊赛（纪念一周年）
        return {
            title = "🏆 一周年挑战赛",
            desc = "经营网吧整整一周了！社区的年轻人自发组织了一场庆祝赛：\n\n\"Dragon Force！你们开店一周了！我们凑了一支队伍来挑战，敢不敢应战？\"\n\n对方看起来实力一般，这是展示战队的好机会！\n\n（本场比赛免费，不消耗行动点）",
            type = "choice",
            choices = {
                { text = "⚔️ 来吧！Dragon Force接受挑战！",
                  effect = function()
                      playerData_.freeMatchToday = true
                      playerData_.reputation = playerData_.reputation + 5
                  end,
                  result = "观众们围了过来，气氛热烈！\n\n⚔️ 免费友谊赛已开启！前往「经营」页面开始比赛！\n声望+5（观众被你的气势感染了）" },
                { text = "🤝 下次吧，今天要忙经营",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 2
                  end,
                  result = "对方有点失望但表示理解。\"那下次一定！\"\n\n声望+2（至少你礼貌地回应了）" },
            },
        }
    elseif day == 11 then
        -- Day11: 金币交易系统引导
        local goldPrice = GetGoldPrice and GetGoldPrice() or 1800
        return {
            title = "💰 神秘金商",
            desc = "一个穿西装的男人走进网吧，低声说：\n\n\"老板，我有渠道弄到便宜黄金。现在金价 $" .. goldPrice .. "/盎司，我可以给你按市价来。\"\n\n他掏出一小块金条在灯光下闪闪发光。\n\n\"在非洲，现金随时可能贬值。但黄金——黄金永远不会骗你。\"",
            type = "choice",
            choices = {
                { text = "💡 了解一下",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 3
                      -- 给一小笔初始金做体验
                      playerData_.goldOunces = (playerData_.goldOunces or 0) + 0.1
                  end,
                  result = "金商留下了联系方式，还送了你0.1盎司做\"见面礼\"。\n\n💰 获得 0.1盎司黄金（约$" .. math.floor(goldPrice * 0.1) .. "）！\n💡 提示：关注「黄金交易」功能，低买高卖可以对冲货币贬值！" },
                { text = "🙅 不感兴趣",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 1
                  end,
                  result = "金商耸耸肩走了。不过以后如果需要，他说随时可以找他。\n\n💡 提示：黄金交易功能已在经营页面开放，想什么时候买都可以。" },
            },
        }
    end
    return nil
end

-- ============================================================================
-- 方案1: 每日免费迷你游戏（不消耗AP）
-- ============================================================================

--- 检查今日免费迷你游戏次数
---@return number 剩余免费次数
function RV2.GetFreeMiniGamePlays()
    local maxFree = 3
    local used = playerData_.freeMiniGamesToday or 0
    return math.max(0, maxFree - used)
end

--- 消耗一次免费迷你游戏
---@return boolean 是否成功
function RV2.UseFreeMiniGamePlay()
    if RV2.GetFreeMiniGamePlays() <= 0 then return false end
    playerData_.freeMiniGamesToday = (playerData_.freeMiniGamesToday or 0) + 1
    return true
end

--- 获取免费迷你游戏奖励（50%正常奖励 + 连胜加成）
---@param score number 游戏得分
---@return table {money, rep, streakBonus}
function RV2.CalcFreeMiniGameReward(score)
    local baseMoney = math.floor(score * 0.3)  -- 基础50%
    local baseRep = math.floor(score * 0.05)
    local streak = playerData_.miniGameStreak or 0
    local streakMult = 1.0 + streak * 0.1  -- 每连胜+10%
    return {
        money = math.floor(baseMoney * streakMult),
        rep = math.max(1, math.floor(baseRep * streakMult)),
        streakBonus = streak,
    }
end

-- ============================================================================
-- 方案2.5: 连续登录奖励系统（7日循环）
-- ============================================================================

--- 登录奖励表（7天一轮，循环）
RV2.LOGIN_STREAK_REWARDS = {
    [1] = { icon = "💰", label = "$50",        reward = { money = 50 } },
    [2] = { icon = "⚡", label = "+1 AP",      reward = { ap = 1 } },
    [3] = { icon = "💰", label = "$100",       reward = { money = 100 } },
    [4] = { icon = "🎁", label = "免费抽×2",   reward = { freeDraw = 2 } },
    [5] = { icon = "💰", label = "$150",       reward = { money = 150 } },
    [6] = { icon = "⚡", label = "+2 AP",      reward = { ap = 2 } },
    [7] = { icon = "🌟", label = "$300+稀有抽", reward = { money = 300, freeDraw = 1, rare = true } },
}

--- 获取当前登录奖励信息
---@return table { day=1-7, reward=table, claimed=bool, streakCount=number }
function RV2.GetLoginStreakInfo()
    local streak = playerData_.loginStreak or 0
    local cycleDay = ((streak - 1) % 7) + 1  -- 1~7 循环
    local claimed = playerData_.loginStreakClaimed or false
    return {
        day = cycleDay,
        streakCount = streak,
        reward = RV2.LOGIN_STREAK_REWARDS[cycleDay],
        claimed = claimed,
    }
end

--- 领取当日登录奖励
---@return boolean success
---@return string message
function RV2.ClaimLoginStreakReward()
    if playerData_.loginStreakClaimed then
        return false, "今日已领取"
    end
    local info = RV2.GetLoginStreakInfo()
    local r = info.reward.reward
    local msgs = {}
    if r.money then
        playerData_.money = (playerData_.money or 0) + r.money
        table.insert(msgs, "$" .. r.money)
    end
    if r.ap then
        playerData_.actionPoints = (playerData_.actionPoints or 0) + r.ap
        table.insert(msgs, "+" .. r.ap .. " AP")
    end
    if r.freeDraw then
        playerData_.marketFreeDraws = (playerData_.marketFreeDraws or 0) + r.freeDraw
        table.insert(msgs, r.freeDraw .. "次免费抽")
    end
    playerData_.loginStreakClaimed = true
    local msg = "签到第" .. info.day .. "天奖励: " .. table.concat(msgs, " + ")
    if AddLog then AddLog("🎁 " .. msg) end
    return true, msg
end

-- ============================================================================
-- 方案2.6: 每日限时折扣（Daily Deal）
-- ============================================================================

--- 生成今日限时折扣（在 DailyReset 中调用）
function RV2.GenerateDailyDiscount()
    if not UPGRADES or not UPGRADE_ORDER then return end
    -- 收集所有可升级（非满级）的项目
    local candidates = {}
    local allKeys = {}
    for _, k in ipairs(UPGRADE_ORDER) do table.insert(allKeys, k) end
    if UPGRADE_COMMUNITY then for _, k in ipairs(UPGRADE_COMMUNITY) do table.insert(allKeys, k) end end
    if UPGRADE_CULTURE then for _, k in ipairs(UPGRADE_CULTURE) do table.insert(allKeys, k) end end

    for _, key in ipairs(allKeys) do
        local cfg = UPGRADES[key]
        if cfg and cfg.costs then
            local cur = GetUpgradeCur and GetUpgradeCur(key) or 0
            if cur < #cfg.costs then
                table.insert(candidates, key)
            end
        end
    end
    if #candidates == 0 then
        playerData_.dailyDiscount = nil
        return
    end
    -- 随机选一个，给30-50%折扣
    local chosen = candidates[math.random(1, #candidates)]
    local discountPct = math.random(30, 50)
    playerData_.dailyDiscount = {
        key = chosen,
        pct = discountPct,
        used = false,
    }
    if AddLog then
        local cfg = UPGRADES[chosen]
        AddLog("🏷️ 今日特惠: " .. (cfg and cfg.name or chosen) .. " 打" .. (10 - math.floor(discountPct / 10)) .. "折！限时一天")
    end
end

--- 获取当前每日折扣信息
---@return table|nil discount {key, pct, used}
function RV2.GetDailyDiscount()
    return playerData_.dailyDiscount
end

--- 应用每日折扣到费用（返回折后价格）
---@param key string 升级key
---@param originalCost number 原始费用
---@return number discountedCost 折后费用
---@return number|nil discountPct 折扣百分比（nil=无折扣）
function RV2.ApplyDailyDiscount(key, originalCost)
    local d = playerData_.dailyDiscount
    if d and d.key == key and not d.used then
        local discounted = math.floor(originalCost * (100 - d.pct) / 100)
        return discounted, d.pct
    end
    return originalCost, nil
end

--- 标记每日折扣已使用
function RV2.MarkDailyDiscountUsed(key)
    local d = playerData_.dailyDiscount
    if d and d.key == key then
        d.used = true
    end
end

-- ============================================================================
-- 方案2: AP系统扩容+广告恢复
-- ============================================================================

--- 计算当日基础AP（含成就/登录加成）
---@return number 基础AP
function RV2.CalcBaseAP()
    local base = 3
    -- 登录连击加成
    local loginStreak = playerData_.loginStreak or 0
    if loginStreak >= 7 then base = base + 1 end  -- 连续7天+1
    -- 成就加成
    if playerData_.apBonus then base = base + playerData_.apBonus end
    -- 上限5
    return math.min(5, base)
end

--- 广告恢复AP
---@return boolean 是否可用
function RV2.CanAdRecoverAP()
    local used = playerData_.adAPRecoverToday or 0
    return used < 2  -- 每天最多2次
end

--- 执行广告恢复AP
function RV2.DoAdRecoverAP()
    if not RV2.CanAdRecoverAP() then return false end
    playerData_.adAPRecoverToday = (playerData_.adAPRecoverToday or 0) + 1
    playerData_.actionPoints = playerData_.actionPoints + 1
    AddLog("📺 观看赞助商短片，恢复1行动点！")
    PlaySFX("coin_collect")
    return true
end

-- ============================================================================
-- 方案6: 离线回归奖励增强
-- ============================================================================

--- 增强版离线收益计算
---@param offlineSeconds number
---@return table|nil
function RV2.CalcEnhancedOfflineEarnings(offlineSeconds)
    if offlineSeconds < 300 then return nil end

    -- 上限12小时（原8小时）
    local hours = math.min(12, offlineSeconds / 3600)

    -- 效率50%（原30%）
    local dailyIncome = 0
    local ok, result = pcall(CalcDailyIncome)
    ---@diagnostic disable-next-line: assign-type-mismatch
    if ok then dailyIncome = result or 0 end
    if dailyIncome <= 0 then dailyIncome = playerData_.computers * 20 end

    local hourlyRate = math.floor(dailyIncome * 0.5)
    local earnings = math.max(10, math.floor(hourlyRate * hours))

    -- 4小时以上触发回归惊喜事件
    local surpriseEvent = nil
    if hours >= 4 then
        local surprises = {
            { title = "🎁 回归惊喜", desc = "你不在的时候，Kwame帮你看了店，还多赚了一笔！", bonus = math.floor(earnings * 0.2) },
            { title = "📦 意外包裹", desc = "门口有一个包裹——是之前订的二手设备到货了！", bonus = 0, equipBonus = 5 },
            { title = "🌟 好评如潮", desc = "你不在的时候网吧被人在社媒上夸了！", bonus = 0, repBonus = 10 },
        }
        surpriseEvent = surprises[math.random(1, #surprises)]
    end

    return {
        earnings = earnings,
        hours = math.floor(hours * 10) / 10,
        canDouble = true,
        surpriseEvent = surpriseEvent,
    }
end

-- ============================================================================
-- 方案7: 经营可视化+即时反馈特效
-- ============================================================================

--- 浮动文字队列（用于+$50、+声望等即时反馈）
RV2.floatingTexts = {}

--- 添加浮动文字
---@param text string 显示文字
---@param color table|nil 颜色 {r,g,b,a}
function RV2.AddFloatingText(text, color)
    table.insert(RV2.floatingTexts, {
        text = text,
        color = color or { 80, 200, 80, 255 },
        timer = 0,
        duration = 1.5,
    })
end

--- 里程碑弹窗检查
---@return table|nil {title, desc, icon}
function RV2.CheckMilestone()
    local p = playerData_
    local milestones = {
        { check = p.computers >= 5 and not p.milestone_5pc, key = "milestone_5pc",
          title = "🖥️ 五机齐发", desc = "你的网吧已经有5台电脑了！", icon = "🖥️" },
        { check = p.reputation >= 100 and not p.milestone_100rep, key = "milestone_100rep",
          title = "⭐ 百星之名", desc = "声望达到100！你在社区小有名气了！", icon = "⭐" },
        { check = p.money >= 10000 and not p.milestone_10k, key = "milestone_10k",
          title = "💰 万元户", desc = "现金突破$10,000！财富之路越走越宽！", icon = "💰" },
        { check = #teamMembers_ >= 3 and not p.milestone_3team, key = "milestone_3team",
          title = "👥 三人成众", desc = "战队已有3名成员！离满编不远了！", icon = "👥" },
        { check = (p.tournamentWins or 0) >= 1 and not p.milestone_first_champ, key = "milestone_first_champ",
          title = "🏆 初次夺冠", desc = "赢得了第一个锦标赛冠军！传奇开始了！", icon = "🏆" },
        { check = #(p.branches or {}) >= 1 and not p.milestone_branch, key = "milestone_branch",
          title = "🏪 连锁起步", desc = "开设了第一家分店！商业帝国的起点！", icon = "🏪" },
    }
    for _, m in ipairs(milestones) do
        if m.check then
            p[m.key] = true
            PlaySFX("level_up")
            return m
        end
    end
    return nil
end

-- ============================================================================
-- 方案9: 每日黄金时段机制
-- ============================================================================

--- 检查是否处于黄金时段
---@return boolean
function RV2.IsGoldenHour()
    return playerData_.goldenHourActive == true
end

--- 尝试触发黄金时段（每日1次，随机触发）
---@return boolean 是否触发
function RV2.TryTriggerGoldenHour()
    if playerData_.goldenHourTriggered then return false end
    -- 每个行动回合25%概率触发，第2-3次行动后概率更高
    local apUsed = (RV2.CalcBaseAP() - playerData_.actionPoints)
    local chance = 0.15 + apUsed * 0.1
    if math.random() < chance then
        playerData_.goldenHourActive = true
        playerData_.goldenHourTriggered = true
        playerData_.goldenHourActions = 0
        playerData_.goldenHourMaxActions = math.random(2, 3)
        AddLog("🌟 黄金时段开启！接下来 " .. playerData_.goldenHourMaxActions .. " 个行动收益翻倍！")
        PlaySFX("level_up")
        return true
    end
    return false
end

--- 消耗一次黄金时段行动
---@return number 收益倍率(1.0 或 1.5)
function RV2.UseGoldenHourAction()
    if not RV2.IsGoldenHour() then return 1.0 end
    playerData_.goldenHourActions = (playerData_.goldenHourActions or 0) + 1
    if playerData_.goldenHourActions >= (playerData_.goldenHourMaxActions or 3) then
        playerData_.goldenHourActive = false
        AddLog("🌟 黄金时段结束！")
    end
    return 1.5  -- 收益×1.5
end

-- ============================================================================
-- 方案10: 赛季通行证系统
-- ============================================================================

local SEASON_PASS_REWARDS = {
    { points = 5,  reward = { money = 100 },  desc = "💰 $100现金", icon = "💰" },
    { points = 10, reward = { rep = 30 },     desc = "⭐ 声望+30", icon = "⭐" },
    { points = 15, reward = { money = 300 },  desc = "💰 $300现金", icon = "💎" },
    { points = 20, reward = { rep = 50, money = 200 }, desc = "💰$200 + ⭐声望50", icon = "🏅" },
    { points = 25, reward = { money = 500, rep = 80 }, desc = "💰$500 + ⭐声望80", icon = "🏆" },
    { points = 30, reward = { money = 800, rep = 100 }, desc = "💰$800 + ⭐声望100 (赛季大奖)", icon = "👑" },
}

--- 添加赛季通行证积分
---@param points number
---@param source string 来源描述
function RV2.AddSeasonPoints(points, source)
    playerData_.seasonPassPoints = (playerData_.seasonPassPoints or 0) + points
    -- 不打日志，由调用方决定
end

--- 获取赛季通行证状态
---@return table {points, rewards, nextReward, claimedRewards}
function RV2.GetSeasonPassStatus()
    local points = playerData_.seasonPassPoints or 0
    local claimed = playerData_.seasonPassClaimed or {}
    local nextReward = nil
    for _, r in ipairs(SEASON_PASS_REWARDS) do
        if not claimed[tostring(r.points)] and points >= r.points then
            nextReward = r
            break
        end
    end
    return {
        points = points,
        rewards = SEASON_PASS_REWARDS,
        nextReward = nextReward,
        claimedRewards = claimed,
    }
end

--- 领取赛季通行证奖励
---@param tier number 积分档位
---@return string|nil 结果描述
function RV2.ClaimSeasonPassReward(tier)
    local claimed = playerData_.seasonPassClaimed or {}
    if claimed[tostring(tier)] then return nil end
    for _, r in ipairs(SEASON_PASS_REWARDS) do
        if r.points == tier and (playerData_.seasonPassPoints or 0) >= tier then
            if r.reward.money then playerData_.money = playerData_.money + r.reward.money end
            if r.reward.rep then playerData_.reputation = playerData_.reputation + r.reward.rep end
            if not playerData_.seasonPassClaimed then playerData_.seasonPassClaimed = {} end
            playerData_.seasonPassClaimed[tostring(tier)] = true
            PlaySFX("victory")
            return "🎁 赛季奖励领取: " .. r.desc
        end
    end
    return nil
end

-- ============================================================================
-- 方案11: 团队羁绊系统
-- ============================================================================

local BOND_TYPES = {
    { id = "hometown", name = "🏠 同乡之情",
      desc = "来自同一个地方的队员，心情自然更好",
      pairs = { {"Kofi", "Big Joe"}, {"Grace", "Prince"} },
      effect = { mood = 10 },
      effectDesc = "心情+10" },
    { id = "mentor", name = "📚 师徒传承",
      desc = "经验丰富的老将指导新人",
      pairs = { {"Mama B", "Kofi"}, {"Mama B", "Thunder"}, {"Snake", "Big Joe"} },
      effect = { trainMult = 1.5 },
      effectDesc = "训练效果×1.5" },
    { id = "rival", name = "⚔️ 良性竞争",
      desc = "实力相近的队员互相激励",
      pairs = { {"Snake", "Thunder"}, {"Grace", "小雪"}, {"Kofi", "Prince"} },
      effect = { matchBonus = 8 },
      effectDesc = "比赛战力+8" },
    { id = "guardian", name = "🛡️ 守护之心",
      desc = "一方守护另一方的信念",
      pairs = { {"Big Joe", "Grace"}, {"Prince", "小雪"} },
      effect = { moodGuard = true },
      effectDesc = "心情不低于40" },
    { id = "duo_combo", name = "🔥 黄金搭档",
      desc = "默契配合的双人组合",
      pairs = { {"Snake", "Grace"}, {"Thunder", "Kofi"} },
      effect = { matchBonus = 12 },
      effectDesc = "比赛战力+12" },
}

--- 检查当前激活的羁绊
---@return table 激活羁绊列表 [{bond, member1, member2}]
function RV2.GetActiveBonds()
    if #teamMembers_ < 2 then return {} end
    local names = {}
    for _, m in ipairs(teamMembers_) do names[m.name] = m end

    local active = {}
    for _, bond in ipairs(BOND_TYPES) do
        for _, pair in ipairs(bond.pairs) do
            if names[pair[1]] and names[pair[2]] then
                table.insert(active, {
                    bond = bond,
                    member1 = names[pair[1]],
                    member2 = names[pair[2]],
                })
            end
        end
    end
    return active
end

--- 应用羁绊效果（每日结算时调用）
function RV2.ApplyBondEffects()
    local bonds = RV2.GetActiveBonds()
    for _, ab in ipairs(bonds) do
        local eff = ab.bond.effect
        -- 心情加成
        if eff.mood then
            ab.member1.mood = math.min(100, (ab.member1.mood or 50) + eff.mood)
            ab.member2.mood = math.min(100, (ab.member2.mood or 50) + eff.mood)
        end
        -- 心情保底
        if eff.moodGuard then
            ab.member1.mood = math.max(40, ab.member1.mood or 50)
            ab.member2.mood = math.max(40, ab.member2.mood or 50)
        end
    end
    if #bonds > 0 then
        local bondNames = {}
        for _, ab in ipairs(bonds) do
            table.insert(bondNames, ab.bond.name)
        end
        AddLog("💞 羁绊生效: " .. table.concat(bondNames, ", "))
    end
end

--- 获取羁绊带来的比赛战力加成
---@return number 额外战力
function RV2.GetBondMatchBonus()
    local bonus = 0
    local bonds = RV2.GetActiveBonds()
    for _, ab in ipairs(bonds) do
        if ab.bond.effect.matchBonus then
            bonus = bonus + ab.bond.effect.matchBonus
        end
    end
    return bonus
end

--- 获取羁绊训练倍率
---@param memberName string
---@return number 倍率
function RV2.GetBondTrainMultiplier(memberName)
    local bonds = RV2.GetActiveBonds()
    for _, ab in ipairs(bonds) do
        if ab.bond.effect.trainMult then
            if ab.member1.name == memberName or ab.member2.name == memberName then
                return ab.bond.effect.trainMult
            end
        end
    end
    return 1.0
end

-- ============================================================================
-- 方案8: 比赛微操系统
-- ============================================================================

local MICRO_OPS = {
    { id = "quick_reaction", name = "⚡ 极速反应",
      desc = "关键时刻！快速点击提升队伍士气！",
      type = "tap",  -- 连续点击
      duration = 3,  -- 3秒
      threshold = 8, -- 需要8次点击
      bonusOnSuccess = 15,
      bonusOnFail = -5,
      successMsg = "⚡ 极速反应成功！队伍士气大涨！战力+15",
      failMsg = "😓 反应太慢了，队伍有些泄气。战力-5",
    },
    { id = "tactical_choice", name = "🎯 战术抉择",
      desc = "教练席紧急决策！选择正确的战术！",
      type = "choice",  -- 选择题
      options = {
          { text = "🔥 全力进攻", correct = function() return math.random() < 0.4 end },
          { text = "🛡️ 稳守反击", correct = function() return math.random() < 0.4 end },
          { text = "🎯 针对弱点", correct = function() return true end },  -- 永远正确但奖励低
      },
      bonusCorrect = { 20, 20, 10 },  -- 对应每个选项的加成
      bonusFail = -8,
    },
    { id = "crowd_cheer", name = "📢 观众助威",
      desc = "观众在为你呐喊！快速滑动为队伍加油！",
      type = "tap",
      duration = 3,
      threshold = 10,
      bonusOnSuccess = 12,
      bonusOnFail = 0,  -- 不惩罚
      successMsg = "📢 观众沸腾了！队伍信心倍增！战力+12",
      failMsg = "📢 助威声不够响亮，但没关系。",
    },
}

--- 在比赛中触发微操事件
---@return table|nil 微操事件
function RV2.TriggerMatchMicroOp()
    if (playerData_.matchMicroOpsUsed or 0) >= 2 then return nil end  -- 每场最多2次
    if math.random() < 0.6 then  -- 60%触发
        local op = MICRO_OPS[math.random(1, #MICRO_OPS)]
        playerData_.matchMicroOpsUsed = (playerData_.matchMicroOpsUsed or 0) + 1
        return op
    end
    return nil
end

-- ============================================================================
-- 每日重置（在 EndDay 中调用）
-- ============================================================================

--- 重置每日临时数据
function RV2.DailyReset()
    playerData_.microEventsUsed = {}
    playerData_.microEventsToday = 0
    playerData_.freeMiniGamesToday = 0
    playerData_.adAPRecoverToday = 0
    playerData_.goldenHourActive = false
    playerData_.goldenHourTriggered = false
    playerData_.goldenHourActions = 0
    playerData_.freeMatchToday = false
    playerData_.matchMicroOpsUsed = 0
    -- 登录连击
    playerData_.loginStreak = (playerData_.loginStreak or 0) + 1
    playerData_.loginStreakClaimed = false  -- 每日重置签到领取状态
    -- 每日委托完成 → 赛季积分
    if dailyQuest_ and dailyQuest_.claimed then
        RV2.AddSeasonPoints(3, "每日委托")
    end
    -- 二手市场每日重置（免费单抽刷新）
    if Market and Market.DailyReset then
        pcall(Market.DailyReset)
    end
    -- 每日限时折扣
    pcall(RV2.GenerateDailyDiscount)
    -- 2.5 天气系统：生成当日天气
    if GenerateDailyWeather then
        local ok, w = pcall(GenerateDailyWeather)
        if ok and w and AddLog then
            AddLog(w.emoji .. " 今日天气：" .. w.name .. " — " .. w.desc)
        end
    end
    -- 3.3 清理已领取的旧邮件
    local Achievements = require("Achievements")
    if Achievements and Achievements.CleanOldMail then
        pcall(Achievements.CleanOldMail)
    end
    -- 市场装备: 额外AP加成
    if Market and Market.CalcEquippedEffects then
        local ok, mfx = pcall(Market.CalcEquippedEffects)
        if ok and mfx and mfx.apBonus and mfx.apBonus > 0 then
            playerData_.actionPoints = (playerData_.actionPoints or 3) + math.floor(mfx.apBonus)
            if AddLog then AddLog("🎒 装备效果: 今日额外 +" .. math.floor(mfx.apBonus) .. " 行动点") end
        end
    end
end

--- 完全重置（新游戏时调用）
function RV2.FullReset()
    playerData_.microEventsUsed = {}
    playerData_.microEventsToday = 0
    playerData_.freeMiniGamesToday = 0
    playerData_.miniGameStreak = 0
    playerData_.adAPRecoverToday = 0
    playerData_.baseAP = 3
    playerData_.apBonus = 0
    playerData_.loginStreak = 0
    playerData_.goldenHourActive = false
    playerData_.goldenHourTriggered = false
    playerData_.goldenHourActions = 0
    playerData_.goldenHourMaxActions = 3
    playerData_.freeMatchToday = false
    playerData_.matchMicroOpsUsed = 0
    playerData_.seasonPassPoints = 0
    playerData_.seasonPassClaimed = {}
    playerData_.rv2Day1Shown = false
    playerData_.rv2Day2Shown = false
    -- 里程碑
    playerData_.milestone_5pc = false
    playerData_.milestone_100rep = false
    playerData_.milestone_10k = false
    playerData_.milestone_3team = false
    playerData_.milestone_first_champ = false
    playerData_.milestone_branch = false
end

return RV2
