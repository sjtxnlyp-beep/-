---@diagnostic disable: undefined-global
-- ============================================================================
-- 6. 随机事件池
-- ============================================================================
RANDOM_EVENTS = {
    { type = "auto", title = "学生包夜跑刀", icon = "🌙",
      desc = "一群大学生来网吧包夜跑刀三角洲，撤离成功率竟然80%！你数着哈弗币笑得合不拢嘴。",
      effect = function() playerData_.money = playerData_.money + 60; playerData_.havocCoins = playerData_.havocCoins + 50 end,
      result = "💰+$60 🪙+50哈弗币" },
    { type = "auto", title = "B站视频火了", icon = "📱",
      desc = "有人拍了你网吧的视频发B站，标题'帮你跑刀的，可能是非洲老哥'。播放量百万！弹幕全是'纯黑跑刀YYDS'。",
      effect = function() playerData_.reputation = playerData_.reputation + 40 end,
      result = "⭐ 声望 +40" },
    { type = "auto", title = "猴子偷鼠标", icon = "🐒",
      desc = "一只猴子从窗户窜进来，叼走了3号机的鼠标就跑了！全网吧的人追出去三条街也没追上。",
      effect = function() playerData_.money = playerData_.money - 25 end,
      result = "💸 -$25" },
    { type = "auto", title = "口碑传播", icon = "🗣️",
      desc = "一个常客发了你网吧的照片，配文'纯黑跑刀圣地，全非洲最有灵魂的网吧'，点赞过千。",
      effect = function() playerData_.reputation = playerData_.reputation + 15; playerData_.money = playerData_.money + 30 end,
      result = "⭐+15 💰+$30" },
    { type = "auto", title = "发工资日", icon = "💵",
      desc = "今天是当地发工资的日子！所有人都来网吧充值跑刀。队列排到了门外。",
      effect = function() playerData_.money = playerData_.money + 100 end,
      result = "💰 +$100（爆满！）" },
    { type = "auto", title = "世界杯比赛日", icon = "⚽",
      desc = "今天有非洲杯足球赛，所有人都去看球了。网吧空荡荡，但队员安静训练效果反而更好。",
      effect = function() playerData_.money = playerData_.money - 30; for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 2) end end,
      result = "💸-$30 但队员技术+2" },
    { type = "auto", title = "跑刀大丰收", icon = "🎒",
      desc = "队员们跑刀运气爆棚！撤离一堆高价物资，还捡到了稀有道具'非洲之心'血钻！",
      effect = function() playerData_.havocCoins = playerData_.havocCoins + 120; playerData_.reputation = playerData_.reputation + 10 end,
      result = "🪙+120哈弗币 ⭐+10 (血钻!)" },
    { type = "auto", title = "泡面外交", icon = "🍜",
      desc = "你从国内带来的方便面成了网吧硬通货。'跑赢了奖励一包辣条'成了队员最大动力。",
      effect = function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 8) end end,
      result = "全队心情+8（辣条YYDS）" },
    { type = "choice", title = "停电了！", icon = "⚡",
      desc = "啪！全城停电。正在跑刀的顾客发出哀嚎——差一步就撤离成功了！",
      choices = {
          { text = "🔋 买发电机应急（-$150）", result = "发电机轰鸣，恢复供电！顾客们欢呼。声望+15",
            effect = function() playerData_.money = playerData_.money - 150; playerData_.reputation = playerData_.reputation + 15; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 150 end },
          { text = "😴 今天就歇了吧", result = "停业一天。损失了些收入。",
            effect = function() playerData_.money = playerData_.money - 20 end },
      }
    },
    { type = "choice", title = "中国同胞来访", icon = "🇨🇳",
      desc = "一个叫'包包哥'的浙江老乡路过你的网吧。他也在马达加斯加开网吧，听说你在搞电竞特意来交流。他说可以帮你联系国内赞助商。",
      choices = {
          { text = "🤝 请他吃饭深入交流（-$80）", result = "包包哥感动了，帮你联系到国内赞助。+$300 声望+25",
            effect = function() playerData_.money = playerData_.money - 80 + 300; playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 80 end },
          { text = "👋 聊两句就算了", result = "交换了微信。以后有机会再合作。声望+5",
            effect = function() playerData_.reputation = playerData_.reputation + 5 end },
      }
    },
    { type = "choice", title = "本地电视台采访", icon = "📺",
      desc = "当地电视台听说有个中国人在非洲开网吧教人打三角洲，想来做专题报道——'纯黑跑刀：中国人和非洲少年的电竞梦'。",
      choices = {
          { text = "📺 接受采访", result = "报道播出后大量新顾客涌入。声望+35 +$80",
            effect = function() playerData_.reputation = playerData_.reputation + 35; playerData_.money = playerData_.money + 80 end },
          { text = "🙅 低调行事，专注队员培养", result = "你婉拒了。把时间花在队员身上。声望+5 全员心情+5",
            effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma + 1
              for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end end },
      }
    },
    { type = "choice", title = "有人打架了", icon = "��",
      desc = "两个顾客因为跑刀时抢物资吵起来，一个说'那个非洲之心是我先看到的！'眼看要动手。",
      choices = {
          { text = "🤝 请他们喝汽水+辣条调解", result = "辣条的力量！两人握手言和。声望+20",
            effect = function() playerData_.money = playerData_.money - 5; playerData_.reputation = playerData_.reputation + 20; playerData_.karma = playerData_.karma + 2 end },
          { text = "👉 把闹事的赶走", result = "你维护了网吧秩序，但失去了两个顾客。",
            effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma - 1 end },
      }
    },
    { type = "choice", title = "政府检查", icon = "📋",
      desc = "两个穿制服的人走进网吧，说要'例行检查'。他们东看看西看看，意味深长地咳了一声。",
      choices = {
          { text = "💵 交'检查费'（-$100）", result = "他们满意地离开了，还说下次不用这么多。",
            effect = function() playerData_.money = playerData_.money - 100; playerData_.karma = playerData_.karma - 1 end,
            cond = function() return playerData_.money >= 100 end },
          { text = "📜 据理力争", result = "你坚持要看证件。他们尴尬地走了，但你不确定他们会不会再来。声望+10",
            effect = function() playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 2 end },
      }
    },
    { type = "choice", title = "赞助邀请", icon = "🤝",
      desc = "一个本地饮料品牌联系你，想在网吧贴广告。他们给出了一笔不错的赞助费。",
      choices = {
          { text = "✅ 接受赞助（+$200）", result = "墙上贴满了饮料广告。看着有点丑，但真香。",
            effect = function() playerData_.money = playerData_.money + 200; playerData_.karma = playerData_.karma - 1 end },
          { text = "❌ 拒绝，保持格调", result = "你拒绝了。网吧保持了纯粹的电竞氛围。声望+15",
            effect = function() playerData_.reputation = playerData_.reputation + 15; playerData_.karma = playerData_.karma + 1 end },
      }
    },
    { type = "choice", title = "代练订单", icon = "📦",
      desc = "有国内玩家在淘宝下单了'非洲跑刀代练'——让你的队员帮他们跑刀赚哈弗币。一单200块！",
      choices = {
          { text = "✅ 接单！带兄弟们赚钱", result = "疯狂跑刀一整天！赚了不少但有点累。+$150 🪙+80 心情-5",
            effect = function() playerData_.money = playerData_.money + 150; playerData_.havocCoins = playerData_.havocCoins + 80
              playerData_.totalRuns = playerData_.totalRuns + 10; playerData_.karma = playerData_.karma - 1
              for _, m in ipairs(teamMembers_) do m.mood = math.max(0, m.mood - 5) end end },
          { text = "❌ 不做代练，专心训练", result = "拒绝代练，专注提升实力。全员技术+3",
            effect = function() for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3) end; playerData_.karma = playerData_.karma + 1 end },
      }
    },
    { type = "choice", title = "国际电竞组织关注", icon = "🌍",
      desc = "一封来自国际电竞联盟的邮件！他们注意到了你们战队，想邀请参加三角洲职业联赛非洲区预选赛。但需要缴纳报名费。",
      choices = {
          { text = "💰 缴报名费参赛（-$300）", result = "报名成功！全队士气大涨。声望+50 全员技术+5",
            effect = function() playerData_.money = playerData_.money - 300; playerData_.reputation = playerData_.reputation + 50; playerData_.karma = playerData_.karma + 1
              for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 5) end end,
            cond = function() return playerData_.money >= 300 and #teamMembers_ >= 3 end },
          { text = "😔 还没准备好", result = "你决定继续积蓄实力。以后还有机会。",
            effect = function() end },
      }
    },
    -- 新增随机事件
    { type = "auto", title = "非洲雷暴", icon = "⛈️",
      desc = "一场猛烈的雷暴席卷了小镇！闪电劈中了隔壁的大树，但网吧安然无恙。惊魂过后，顾客们发现——停电了。不过太阳能板还在工作！",
      effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.money = playerData_.money - 15 end,
      result = "⭐+5 💸-$15（修电费）" },
    { type = "auto", title = "跑刀教学视频", icon = "🎬",
      desc = "你录了一期'三角洲跑刀路线教学'发到YouTube，竟然两天破了十万播放！评论区全是英语和法语的感谢留言。",
      effect = function() playerData_.reputation = playerData_.reputation + 25; playerData_.havocCoins = playerData_.havocCoins + 40 end,
      result = "⭐+25 🪙+40" },
    { type = "auto", title = "邻居送水果", icon = "🍉",
      desc = "隔壁大爷扛来一筐西瓜：'谢谢你让我孙子有地方去，比在外面混强多了。'队员们开心地吃了起来。",
      effect = function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 6) end end,
      result = "全队心情+6（西瓜真甜）" },
    { type = "auto", title = "键盘侠出没", icon = "⌨️",
      desc = "有人在推特上说你'剥削非洲廉价劳动力搞代练'。评论区吵翻了，但更多人站在你这边：'他在教人技能，这叫剥削？'",
      effect = function() playerData_.reputation = playerData_.reputation + 10 end,
      result = "⭐+10（黑红也是红）" },
    { type = "choice", title = "流浪狗收养", icon = "🐕",
      desc = "一只瘦骨嶙峋的小狗跑进网吧，在空调下面缩成一团。队员们围过来，眼巴巴地看着你。",
      choices = {
          { text = "🏠 收养它当网吧吉祥物", result = "你给它取名'Dragon'。它很快成了网吧的明星——客人都来撸狗。\n\n声望+15 全队心情+10",
            effect = function() playerData_.reputation = playerData_.reputation + 15; playerData_.karma = playerData_.karma + 2
              for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end end },
          { text = "🚫 送去动物收容所", result = "队员们有点失望，但你是对的——网吧不适合养狗。",
            effect = function() playerData_.karma = playerData_.karma - 1 end },
      }
    },
    { type = "choice", title = "二手设备来了", icon = "📦",
      desc = "朋友帮你从国内寄了一批二手电竞外设——雷蛇鼠标、机械键盘。但海关要收$80关税。",
      choices = {
          { text = "💵 交关税取设备", result = "设备到手！全员装备升级。鼠标灵敏度直接提升两个档次。\n\n-$80 全队技术+3",
            effect = function() playerData_.money = playerData_.money - 80
              for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3) end end,
            cond = function() return playerData_.money >= 80 end },
          { text = "😤 算了太贵了", result = "设备被海关没收。继续用老设备也不是不行……",
            effect = function() end },
      }
    },
    { type = "choice", title = "直播邀约", icon = "📺",
      desc = "一个国内游戏主播想连麦直播你们训练的过程。'让中国观众看看非洲兄弟的操作！'弹幕肯定会很热闹。",
      choices = {
          { text = "🎙️ 接受直播", result = "直播效果炸裂！观众看到非洲小哥精准走位直呼'卧槽'。礼物收入折现$200。\n\n+$200 声望+20",
            effect = function() playerData_.money = playerData_.money + 200; playerData_.reputation = playerData_.reputation + 20 end },
          { text = "🙅 婉拒，专心备赛", result = "你婉拒了直播。把时间花在刀刃上。\n\n全队技术+2",
            effect = function() for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 2) end; playerData_.karma = playerData_.karma + 1 end },
      }
    },
    -- ===== v4.5 扩充随机事件 =====
    { type = "auto", title = "深夜外卖订单", icon = "🛵",
      desc = "凌晨三点，一帮包夜的大学生叫了六份炒饭。外卖小哥骑摩托穿越半个城才送到——开门时看见满屋人在跑刀，他也坐下来打了一局。",
      effect = function() playerData_.money = playerData_.money + 35; playerData_.reputation = playerData_.reputation + 5 end,
      result = "💰+$35 ⭐+5" },
    { type = "auto", title = "跑刀吉尼斯", icon = "🏅",
      desc = "你的队员连续跑刀撤离12局不死！当地论坛有人发帖：'Dragon Net Cafe出了个跑刀之神，这是非洲纪录吧？'",
      effect = function()
          playerData_.reputation = playerData_.reputation + 20; playerData_.havocCoins = playerData_.havocCoins + 60
          if #teamMembers_ > 0 then
              local star = teamMembers_[math.random(1, #teamMembers_)]
              star.skill = math.min(SKILL_CAP, star.skill + 2)
          end
      end,
      result = "⭐+20 🪙+60 最强队员技术+2" },
    { type = "auto", title = "蚂蚁入侵", icon = "🐜",
      desc = "一条黑色蚂蚁大军从墙缝涌出，直奔零食柜！泡面、辣条、饼干无一幸免。队员们花了一下午驱蚂蚁。",
      effect = function()
          playerData_.money = playerData_.money - 20
          for _, m in ipairs(teamMembers_) do m.mood = math.max(0, m.mood - 5) end
      end,
      result = "💸-$20 全队心情-5（辣条没了）" },
    { type = "auto", title = "老乡寄快递", icon = "📬",
      desc = "国内的大学室友寄来一个包裹——里面是一箱老干妈、两包螺蛳粉、和一张纸条：'在非洲也要吃好点，我们都关注你了！'",
      effect = function()
          for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 12) end
          playerData_.karma = playerData_.karma + 1
      end,
      result = "全队心情+12（老干妈是灵魂）" },
    { type = "choice", title = "隔壁开了网吧", icon = "🏪",
      desc = "隔壁店铺新开了一家网吧！老板是个印度人，设备比你新，价格还便宜两成。今天你的客流明显少了。",
      choices = {
          { text = "📢 搞促销活动：跑刀撤离送烤鸡", result = "促销大成功！'撤离送烤鸡'活动火爆全城。客人排队来挑战。隔壁老板酸了。\n\n-$60 声望+25",
            effect = function() playerData_.money = playerData_.money - 60; playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 60 end },
          { text = "🤝 去交个朋友，互利共赢", result = "你带了两包辣条去拜访。聊了半天，决定合办'跑刀联赛'——两家网吧的常客组队PK。\n\n声望+15 全队技术+2",
            effect = function() playerData_.reputation = playerData_.reputation + 15; playerData_.karma = playerData_.karma + 2
              for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 2) end end },
      }
    },
    { type = "choice", title = "队员想辞职", icon = "😟",
      desc = function()
          if #teamMembers_ == 0 then return "（无队员）" end
          local lowest = teamMembers_[1]
          for _, m in ipairs(teamMembers_) do if m.mood < lowest.mood then lowest = m end end
          return lowest.name .. " 找你谈话：'老板，我想回家了。我妈病了，家里需要钱……' " .. lowest.name .. " 低着头，不敢看你。"
      end,
      choices = {
          { text = "💵 预支工资帮他渡难关（-$120）", result = function()
              if #teamMembers_ == 0 then return "没有队员" end
              local lowest = teamMembers_[1]
              for _, m in ipairs(teamMembers_) do if m.mood < lowest.mood then lowest = m end end
              return "你掏出$120：'先拿去给你妈看病，不用还。'" .. lowest.name .. " 眼眶红了：'老板……我一定好好打。'\n\n" .. lowest.name .. " 心情+30 技术+5 $-120"
          end,
            effect = function()
                playerData_.money = playerData_.money - 120; playerData_.karma = playerData_.karma + 3
                local lowest = teamMembers_[1]
                for _, m in ipairs(teamMembers_) do if m.mood < lowest.mood then lowest = m end end
                lowest.mood = math.min(100, lowest.mood + 30); lowest.skill = math.min(SKILL_CAP, lowest.skill + 5)
            end,
            cond = function() return playerData_.money >= 120 and #teamMembers_ > 0 end },
          { text = "😔 理解他，让他回去", result = "你拍了拍他的肩：'家人最重要，随时欢迎回来。'\n\n（该队员暂时心情恢复但未离队）\n\n声望+10",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1
                if #teamMembers_ > 0 then
                    local lowest = teamMembers_[1]
                    for _, m in ipairs(teamMembers_) do if m.mood < lowest.mood then lowest = m end end
                    lowest.mood = math.min(100, lowest.mood + 15)
                end
            end },
      },
      cond = function() return #teamMembers_ >= 2 end,
    },
    { type = "choice", title = "神秘U盘", icon = "💾",
      desc = "有人在3号机的USB口留了一个U盘。里面是一份三角洲的'跑刀路线数据库'——包含了各地图最优撤离路线。但你不确定来源是否可靠。",
      choices = {
          { text = "📊 研究数据，用于训练", result = "数据质量很高！队员们照着练了两天，撤离效率提升明显。\n\n全队技术+4",
            effect = function() for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 4) end end },
          { text = "🗑️ 谨慎删除，不用来路不明的东西", result = "安全第一。你格式化了U盘。后来听说隔壁网吧用了类似U盘，中了挖矿病毒。\n\n声望+10（明智）",
            effect = function() playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 2 end },
      }
    },
    { type = "choice", title = "大使馆来电", icon = "☎️",
      desc = "中国大使馆打来电话：'我们听说有中国公民在当地从事电竞教育，想了解一下情况。如果合规的话，可以推荐你参加中非文化交流项目。'",
      choices = {
          { text = "📋 积极配合，提交材料", result = "你整理了Dragon Force的资料寄过去。两周后收到回信：恭喜入选'中非青年数字技能交流项目'！\n\n声望+40 $+150",
            effect = function() playerData_.reputation = playerData_.reputation + 40; playerData_.money = playerData_.money + 150; playerData_.karma = playerData_.karma + 2 end },
          { text = "😰 低调处理，不想惹麻烦", result = "你客气地敷衍了几句。大使馆没再联系。\n\n（错过了一个机会）",
            effect = function() playerData_.karma = playerData_.karma - 1 end },
      }
    },
    -- ===== v5.0 客流量相关事件 =====
    { type = "auto", title = "网红打卡潮", icon = "📸",
      desc = "一个拥有10万粉丝的旅行博主来你的网吧打卡！'非洲居然有这么酷的网吧？！'视频发出后，大量好奇的游客涌来打卡。门口排起了长队！",
      effect = function()
          trafficBonus_ = trafficBonus_ + 8
          playerData_.reputation = playerData_.reputation + 20
          playerData_.money = playerData_.money + 60
          cachedTrafficDay_ = -1  -- 强制刷新客流
      end,
      result = "👥 客流大增！⭐+20 💰+$60" },
    { type = "auto", title = "暴雨季来临", icon = "🌧️",
      desc = "连续暴雨让街道变成了小河！大部分人都待在家里不出门。网吧冷冷清清，只有几个死忠玩家冒雨前来。",
      effect = function()
          trafficBonus_ = trafficBonus_ - 6
          playerData_.money = playerData_.money - 20
          cachedTrafficDay_ = -1
      end,
      result = "👥 客流骤降 💸-$20" },
    { type = "auto", title = "电竞赛事直播日", icon = "🏆",
      desc = "今天有三角洲全球总决赛直播！整个城镇的年轻人都涌进网吧看比赛。你临时加了三排折叠椅，卖烤鸡和汽水的钱比平时多了两倍。",
      effect = function()
          trafficBonus_ = trafficBonus_ + 10
          playerData_.money = playerData_.money + 120
          playerData_.reputation = playerData_.reputation + 15
          cachedTrafficDay_ = -1
      end,
      result = "👥 客流爆满！💰+$120 ⭐+15" },
    { type = "choice", title = "对面修路封路", icon = "🚧",
      desc = "市政在网吧门前的路上施工，灰尘漫天，噪音不断。客人得绕一大圈才能到你这里，今天客流明显减少。",
      choices = {
          { text = "📢 发传单+社交媒体宣传引流", result = "你让队员去路口举牌指路，还在社交媒体发'施工期间到店送饮料'。客人反而比平时多了！\n\n-$40 客流+5 声望+10",
            effect = function()
                playerData_.money = playerData_.money - 40
                trafficBonus_ = trafficBonus_ + 5
                playerData_.reputation = playerData_.reputation + 10
                cachedTrafficDay_ = -1
            end,
            cond = function() return playerData_.money >= 40 end },
          { text = "😤 忍一忍，等施工结束", result = "施工持续了好几天，客流受到不小影响。\n\n客流-4",
            effect = function()
                trafficBonus_ = trafficBonus_ - 4
                cachedTrafficDay_ = -1
            end },
      }
    },
    { type = "choice", title = "学校放假潮", icon = "🎒",
      desc = "附近三所学校同时放暑假！大量学生涌入网吧，座位完全不够坐。有些学生甚至站着等位。你需要决定怎么应对。",
      choices = {
          { text = "💺 租临时桌椅扩容（-$80）", result = "你紧急租了5套桌椅摆在过道里。虽然有点挤，但学生们玩得很开心。烤鸡摊也趁机大赚了一笔！\n\n-$80 客流+8 💰+$100",
            effect = function()
                playerData_.money = playerData_.money - 80 + 100
                trafficBonus_ = trafficBonus_ + 8
                playerData_.reputation = playerData_.reputation + 10
                cachedTrafficDay_ = -1
            end,
            cond = function() return playerData_.money >= 80 end },
          { text = "🎫 实行预约制，控制人流", result = "你在门口贴了'满员请等候'的牌子。秩序好了，但也劝退了一些客人。\n\n声望+5",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                playerData_.karma = playerData_.karma + 1
            end },
      },
      cond = function() return playerData_.day >= 5 end,
    },
    -- ═══════════════════════════════════════════════════════════
    -- 新增随机事件（v5 扩展 · 15个）
    -- ═══════════════════════════════════════════════════════════
    { type = "choice", title = "帮派收保护费", icon = "🔪",
      desc = "两个纹身大汉走进网吧，自称'西区兄弟会'。'中国老板，我们保你平安，每周交200就行。'他们拍了拍柜台。",
      choices = {
          { text = "💵 交保护费（-$200）", result = "你忍气吞声交了钱。他们满意地离开了，说'下周再来'。",
            effect = function() playerData_.money = playerData_.money - 200; playerData_.karma = playerData_.karma - 1 end,
            cond = function() return playerData_.money >= 200 end },
          { text = "🤝 联合隔壁商户一起报警", result = "你和杂货铺、理发店的老板一起去了警局。警察来巡视了几天，帮派没再出现。街坊们都感谢你带头！声望+30",
            effect = function() playerData_.reputation = playerData_.reputation + 30; playerData_.karma = playerData_.karma + 2 end },
      },
      cond = function() return playerData_.day >= 4 end,
    },
    { type = "choice", title = "黑市零件", icon = "📦",
      desc = "一个戴墨镜的家伙悄悄找到你：'兄弟，我有一批二手显卡，GTX1060，一块只要$30。正规渠道起码$80。'\n他打开包，零件看着成色还行……但来路不明。",
      choices = {
          { text = "💰 买5块便宜显卡（-$150）", result = "你冒险买了5块。装上后……3块正常，2块是坏的。但总体还是赚了。设备+15%",
            effect = function() playerData_.money = playerData_.money - 150; playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 15); playerData_.karma = playerData_.karma - 1 end,
            cond = function() return playerData_.money >= 150 end },
          { text = "🙅 不买来路不明的东西", result = "你拒绝了。虽然少了便宜货，但睡得安心。声望+10",
            effect = function() playerData_.reputation = playerData_.reputation + 10; playerData_.karma = playerData_.karma + 1 end },
      },
    },
    { type = "auto", title = "NGO捐赠电脑", icon = "🎁",
      desc = "一个叫'数字非洲'的NGO组织来到你的网吧。'我们听说你在用电竞帮助年轻人，这是我们捐赠的2台翻新电脑！'他们还留了一面锦旗。",
      effect = function() playerData_.computers = playerData_.computers + 2; playerData_.reputation = playerData_.reputation + 20 end,
      result = "🖥️+2台电脑 ⭐+20（锦旗：数字扶贫先锋）",
      cond = function() return playerData_.day >= 7 and playerData_.reputation >= 40 end,
    },
    { type = "choice", title = "竞争对手开业", icon = "🏪",
      desc = "街对面新开了一家'Flash Net Cafe'，装修比你好，还打出了'开业三天免费'的横幅。你的常客都跑过去看热闹了。",
      choices = {
          { text = "💰 降价促销对抗（-$120）", result = "你也搞了个'充100送50'活动。价格战打了三天，顾客回来了大半。但利润缩水了。声望+15",
            effect = function() playerData_.money = playerData_.money - 120; playerData_.reputation = playerData_.reputation + 15 end,
            cond = function() return playerData_.money >= 120 end },
          { text = "🎮 用电竞特色差异化", result = "你在门口摆出战队奖杯和跑刀战绩：'对面有WiFi，我们有冠军。'老顾客纷纷回来了。声望+25",
            effect = function() playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 1 end },
      },
      cond = function() return playerData_.day >= 12 end,
    },
    { type = "auto", title = "网红博主来访", icon = "🎥",
      desc = "一个有百万粉丝的非洲网红走进你的网吧——'我要做一期非洲网吧特辑！'\n他对着镜头说：'这家中国人开的网吧，是全镇年轻人的精神家园！'视频三天播放量破500万。",
      effect = function() playerData_.reputation = playerData_.reputation + 50; playerData_.money = playerData_.money + 150 end,
      result = "⭐+50 💰+$150（粉丝慕名而来）",
      cond = function() return playerData_.reputation >= 80 end,
    },
    { type = "choice", title = "员工偷零钱", icon = "😤",
      desc = "你发现收银台的零钱连续几天对不上账。调了监控一看——是你雇的帮工小马在趁你不注意时偷拿零钱。一次不多，几块几块地拿。",
      choices = {
          { text = "🚪 直接开除", result = "你把小马叫过来摊牌了。他低着头走了，临走说'对不起老板'。你找了个更靠谱的帮工。声望+5",
            effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma - 1 end },
          { text = "💬 谈话给他一次机会", result = "你单独找他谈了。原来他妈妈生病需要钱。你预支了一个月工资给他。从此小马成了最卖力的员工。声望+20",
            effect = function() playerData_.money = playerData_.money - 80; playerData_.reputation = playerData_.reputation + 20; playerData_.karma = playerData_.karma + 2 end },
      },
      cond = function() return playerData_.day >= 7 end,
    },
    { type = "auto", title = "外挂风波", icon = "🚫",
      desc = "有人投诉你网吧有人用外挂跑刀！'他一枪穿三个人，肯定开挂了！'你查了下——确实有个家伙在用辅助工具。你当场封了他的号并赶走了他。",
      effect = function() playerData_.reputation = playerData_.reputation + 15; playerData_.money = playerData_.money - 20 end,
      result = "⭐+15 💸-$20（退了他的网费）" },
    { type = "choice", title = "大使馆电竞活动", icon = "🏛️",
      desc = "中国大使馆文化处联系你，想在你的网吧办一场'中非青年电竞友谊赛'。他们能提供场地布置和媒体报道，但需要你出人力和网络保障。",
      choices = {
          { text = "🎉 全力配合（-$200）", result = "活动圆满成功！使馆参赞亲自给你颁了感谢状。CCTV海外频道都报道了！声望+60 全队技术+3",
            effect = function() playerData_.money = playerData_.money - 200; playerData_.reputation = playerData_.reputation + 60; playerData_.karma = playerData_.karma + 2
              for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3) end end,
            cond = function() return playerData_.money >= 200 and #teamMembers_ >= 2 end },
          { text = "😅 婉拒，最近太忙了", result = "你礼貌地推辞了。使馆表示理解，下次有活动再联系。",
            effect = function() end },
      },
      cond = function() return playerData_.day >= 8 and playerData_.reputation >= 60 end,
    },
    { type = "auto", title = "雨季洪水", icon = "🌊",
      desc = "连续暴雨导致街道积水，水漫进了网吧！你和队员们手忙脚乱地搬电脑、拔插头。\n虽然抢救及时，但还是有几台设备进了水。",
      effect = function() playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 20); playerData_.money = playerData_.money - 30 end,
      result = "🔧 设备-20% 💸-$30（排水修缮费）",
      cond = function() return playerData_.day >= 6 end,
    },
    { type = "auto", title = "本地节日庆典", icon = "🎊",
      desc = "今天是当地的丰收节！街上到处是载歌载舞的人群。你在网吧门口摆了台电视放三角洲精彩集锦，围观的人越来越多。\n\nMama Blessing还特意多烤了一批鸡腿来卖，供不应求！",
      effect = function() playerData_.reputation = playerData_.reputation + 25; playerData_.money = playerData_.money + 60 end,
      result = "⭐+25 💰+$60（节日红利）" },
    { type = "choice", title = "矿区工人包场", icon = "⛏️",
      desc = "一帮刚发工资的矿区工人涌进你的网吧：'老板！我们包场！所有机器都开起来！'他们出手阔绰，但喝了不少酒，有点吵闹。",
      choices = {
          { text = "🎉 热情接待（赚大钱）", result = "你给他们开了所有机器，Mama Blessing加班烤鸡。工人们玩到深夜，走时付了双倍！但有个键盘被酒泡坏了。💰+$250 设备-10%",
            effect = function() playerData_.money = playerData_.money + 250; playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 10) end },
          { text = "🙅 维持秩序，限制人数", result = "你礼貌地只接了一半人，保持正常经营。工人们理解你的规矩。声望+15 💰+$80",
            effect = function() playerData_.money = playerData_.money + 80; playerData_.reputation = playerData_.reputation + 15; playerData_.karma = playerData_.karma + 1 end },
      },
      cond = function() return playerData_.day >= 4 end,
    },
    { type = "auto", title = "设备供应商促销", icon = "📢",
      desc = "一个设备供应商发来消息：'清仓大甩卖！键盘鼠标耳机买三送一！'\n你趁机囤了一批备用配件，以后维修能省不少钱。",
      effect = function() playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 10); playerData_.money = playerData_.money - 40 end,
      result = "🔧 设备+10% 💸-$40（囤配件）" },
    { type = "choice", title = "学校合作邀请", icon = "🏫",
      desc = "附近中学的校长找到你：'我听说你们搞电竞培训？我们学校想开个计算机兴趣班，能不能合作？每周六带学生来你这里上课。'",
      choices = {
          { text = "🎓 免费教学（换声望）", result = "你每周六免费教学生基础电脑操作和电竞知识。三个月后，你成了镇上最受尊敬的'中国老师'。声望+40",
            effect = function() playerData_.reputation = playerData_.reputation + 40; playerData_.karma = playerData_.karma + 2 end },
          { text = "💰 收取培训费（$100/次）", result = "你开了个正式培训班，每次收$100。学生家长虽然心疼钱，但孩子确实学到了东西。💰+$100",
            effect = function() playerData_.money = playerData_.money + 100; playerData_.karma = playerData_.karma - 1 end },
      },
      cond = function() return playerData_.day >= 5 and playerData_.reputation >= 20 end,
    },
    { type = "auto", title = "汇率波动", icon = "📈",
      desc = "国际汇率突然波动！人民币对当地货币升值了——这意味着你从国内进配件更便宜了，但本地收入换算回来也缩水了。\n\n总的来说，省下的进货成本比收入缩水更多，算是小赚。",
      effect = function() playerData_.money = playerData_.money + math.random(20, 60) end,
      result = "💰 +$20~60（汇率差价红利）" },
    { type = "choice", title = "老顾客求助", icon = "🙏",
      desc = "你的老顾客Kwame满脸愁容地走进来：'老板，我妈住院了，急需$200。我下个月一定还你。'Kwame一直是最守规矩的客人，从不欠费。",
      choices = {
          { text = "💵 借他$200", result = "Kwame感动得差点哭了。一个月后他果然还了钱，还多给了$50和一篮水果。'中国老板，你是好人。'💰净+$50 声望+25",
            effect = function() playerData_.money = playerData_.money - 200 + 250; playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 2 end,
            cond = function() return playerData_.money >= 200 end },
          { text = "😔 婉拒（自己也不宽裕）", result = "你解释了自己的困难。Kwame理解地点点头走了。你心里有点不是滋味。",
            effect = function() playerData_.karma = playerData_.karma - 1 end },
      },
      cond = function() return playerData_.day >= 4 end,
    },
    -- ========== v5 新增随机事件 ==========
    { type = "auto", title = "柴油涨价", icon = "⛽",
      desc = "国际油价飙升，镇上加油站的柴油价格翻了一倍！\n\n所有有发电机的店铺都在叫苦。你看着自己的油表，心里盘算着要不要囤点油。",
      effect = function()
        if (playerData_.generatorLevel or 0) > 0 then
            local lost = math.min(playerData_.fuel or 0, math.random(3, 6))
            playerData_.fuel = (playerData_.fuel or 0) - lost
        end
        playerData_.money = playerData_.money - math.random(30, 60)
      end,
      result = "⛽ 燃油储备减少，钱包也缩水了",
      cond = function() return playerData_.day >= 10 and (playerData_.generatorLevel or 0) > 0 end,
    },
    { type = "auto", title = "油罐车路过", icon = "🛢️",
      desc = "一辆油罐车在你网吧门口抛锚了！司机说修车要两小时，问你能不能借他充个电。\n\n作为回报，他给你灌了几升免费柴油。\n\n'非洲的路就是这样，到处是坑。但人心不是。'司机笑着说。",
      effect = function()
        if (playerData_.generatorLevel or 0) > 0 then
            local gift = math.random(5, 10)
            playerData_.fuel = math.min((playerData_.fuel or 0) + gift, playerData_.fuelCapacity or 20)
        end
        playerData_.reputation = playerData_.reputation + 10
      end,
      result = "⛽ 免费柴油！⭐声望+10",
      cond = function() return playerData_.day >= 5 end,
    },
    { type = "choice", title = "断网危机", icon = "🔌",
      desc = "全镇的光纤被施工队挖断了！预计要三天才能修好。\n\n网吧没网等于废了。但你注意到，虽然不能上网，镇上的年轻人还是无处可去……",
      choices = {
          { text = "🎮 改成单机游戏厅+放电影", result = "你把所有电脑装上单机游戏，又用投影仪放电影。\n\n没想到效果出奇地好！大家挤在一起看《战狼2》，笑声比平时还大。\n💰+$80 ⭐+20",
            effect = function() playerData_.money = playerData_.money + 80; playerData_.reputation = playerData_.reputation + 20 end },
          { text = "📚 办免费电脑培训班", result = "你趁机教大家Excel和打字。Mama Blessing的烤鸡摊也火了——学生太多了。\n\n三天后网修好了，来学习的人里有一半成了新常客。\n⭐+40 karma+1",
            effect = function() playerData_.reputation = playerData_.reputation + 40; playerData_.karma = playerData_.karma + 1; trafficBonus_ = trafficBonus_ + 5 end },
          { text = "😴 关门休息三天", result = "你关了三天门，在家追了一部非洲电视剧。\n\n虽然赔了三天租金，但你觉得自己的斯瓦希里语进步了。",
            effect = function() playerData_.money = playerData_.money - 90 end },
      },
      cond = function() return playerData_.day >= 12 end,
    },
    { type = "choice", title = "邻居网吧打价格战", icon = "⚔️",
      desc = "街对面新开了一家网吧，价格比你便宜一半！\n\n一些老顾客开始流失。你得想办法应对。",
      choices = {
          { text = "💪 提升服务差异化", result = "你决定不打价格战，而是提升服务：免费WiFi、空调、充电接口、烤鸡套餐。\n\n一个月后对面关门了——'那个中国老板太卷了，我卷不过。'\n⭐+30 💰+50",
            effect = function() playerData_.reputation = playerData_.reputation + 30; playerData_.money = playerData_.money + 50 end },
          { text = "🤝 上门聊合作", result = "你主动去拜访对面老板：'兄弟，恶性竞争两败俱伤，不如错峰经营？'\n\n最后你们约定一个白天一个夜晚，反而都赚到了。\n⭐+20 karma+1",
            effect = function() playerData_.reputation = playerData_.reputation + 20; playerData_.karma = playerData_.karma + 1 end },
          { text = "💰 跟着降价", result = "你也降了价。两家打了一个月价格战，都亏得厉害。最后对面先撑不住关了。\n\n但你也元气大伤。💰-$150",
            effect = function() playerData_.money = playerData_.money - 150 end },
      },
      cond = function() return playerData_.day >= 15 and playerData_.reputation >= 80 end,
    },
    { type = "auto", title = "Mama Blessing的儿子回来了", icon = "👨‍👩‍👦",
      desc = "Mama Blessing激动地告诉你：她在首都工作的儿子Kofi Junior回来了！\n\n'他在首都学了IT！老板你能不能给他一份工作？'\n\nKofi Junior 看起来确实懂电脑——他用十分钟就修好了你折腾一早上的打印机。\n\n你给了他一份兼职。Mama Blessing高兴得多送了你一只烤鸡。",
      effect = function()
        playerData_.reputation = playerData_.reputation + 15
        playerData_.equipCondition = math.min(100, playerData_.equipCondition + 10)
        playerData_.karma = playerData_.karma + 1
      end,
      result = "⭐+15 🔧设备+10% karma+1",
      cond = function() return playerData_.day >= 18 and playerData_.foodShop >= 1 end,
    },
    { type = "choice", title = "电竞酒吧合作", icon = "🍺",
      desc = "镇上新开了一家酒吧，老板想跟你合作：他出酒水场地，你出设备和人，每周五晚办'电竞之夜'。",
      choices = {
          { text = "🤝 合作！共赢", result = "每周五的电竞之夜成了镇上最热闹的活动。酒吧老板按约分成，你每周额外赚$80。\n\n你的网吧成了年轻人的社交中心。💰+$80 ⭐+25",
            effect = function() playerData_.money = playerData_.money + 80; playerData_.reputation = playerData_.reputation + 25 end },
          { text = "❌ 拒绝（担心喝酒闹事）", result = "你婉拒了。酒吧老板有点失望，但理解你的顾虑。\n\n事后想想，也许太谨慎了。",
            effect = function() end },
      },
      cond = function() return playerData_.day >= 20 and playerData_.reputation >= 100 end,
    },
    { type = "auto", title = "分店好消息", icon = "🏪",
      desc = "你的分店经理打来电话：'老板！今天客流爆了！大学放假，学生们都来上网！'\n\n分店的日均收入临时翻倍了一天！",
      effect = function()
        local branches = playerData_.branches or {}
        if #branches > 0 then
            local bonus = 0
            for _, br in ipairs(branches) do
                local brI = br.income or 40
                if br.gameBonusType == "income" then brI = math.floor(brI * 1.2) end
                if br.gameBonusType == "combat" then brI = brI + 8 end
                bonus = bonus + brI
            end
            playerData_.money = playerData_.money + bonus
        end
      end,
      result = "🏪 分店临时收入翻倍！",
      cond = function() return #(playerData_.branches or {}) > 0 end,
    },
    { type = "choice", title = "二手商找上门", icon = "🧳",
      desc = "一个穿花衬衫的商人找到你：'兄弟，我有一批从迪拜搞来的二手设备，质量杠杠的。给你友情价，全套$500，够装两台电脑。'\n\n他打开一个大箱子，里面的设备确实看起来不错……但谁知道呢？",
      choices = {
          { text = "💰 买！赌一把 ($500)", result = "",
            cond = function() return playerData_.money >= 500 end,
            effect = function()
                playerData_.money = playerData_.money - 500
                if math.random() < 0.6 then
                    playerData_.computers = playerData_.computers + 2
                    AddLog("🎉 二手设备质量不错！电脑+2台")
                else
                    playerData_.computers = playerData_.computers + 1
                    playerData_.equipCondition = math.max(0, playerData_.equipCondition - 20)
                    AddLog("😅 一台好的一台坏的……电脑+1 设备-20%")
                end
            end },
          { text = "🚫 太冒险了，不买", result = "你摇了摇头。商人耸耸肩走了。\n\n也许错过了好东西，也许躲过了一个坑。",
            effect = function() end },
      },
      cond = function() return playerData_.day >= 12 end,
    },

    -- ====================================================================
    -- NPC 故事线扩展事件（使用 npcJournal_ 做链式触发条件）
    -- ====================================================================

    -- ── Kwame 故事线：从借钱的老顾客到电竞选手 ──
    { title = "Kwame的电竞梦", icon = "🎮",
      type = "choice",
      desc = "Kwame推门进来，不是来上网的。他手里攥着一张皱巴巴的传单——三角洲地区线上电竞锦标赛，报名费$150。\n\n'老板，你看……'他紧张地搓着手，'我知道我还欠你人情。但这个比赛，是我唯一的机会。我在你店里练了三个月了，我觉得我准备好了。'\n\n他的眼神你以前见过，在镜子里——那是赌上一切的眼神。",
      choices = {
          { text = "💰 帮他报名 ($150)", result = "你掏出$150，Kwame愣住了。半天才说出一句：'老板……我不会让你失望的。'\n\n他转身的时候你看到他偷偷擦了一下眼睛。",
            effect = function()
                playerData_.money = playerData_.money - 150
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 10
            end },
          { text = "🤝 让他在店里免费练习", result = "你指了指角落的电脑：'报名费你自己想办法，但以后来练习不收你钱。'\n\nKwame重重地点了点头：'够了，老板。这就够了。'",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 5
            end },
          { text = "🚫 现在帮不了你", result = "你摇了摇头。Kwame低下头，把传单叠好塞进口袋：'没事……我理解的。'\n\n他走后你看着那个空座位，心里不太好受。",
            effect = function() end },
      },
      cond = function() return playerData_.day >= 15 and npcJournal_["kwame"] ~= nil end,
    },
    { title = "Kwame获奖了", icon = "🏆",
      type = "auto",
      result = "Kwame冲进网吧的时候差点把门撞飞。他手里举着手机，屏幕上是比赛排名——第三名。\n\n'老板！我拿奖了！$500奖金！'他一把将$200拍在柜台上，'这是我欠你的。剩下的我要给妈妈治眼睛。'\n\n网吧里的人都鼓起了掌。你觉得这$200比你赚过的任何一笔钱都重。",
      effect = function()
          playerData_.money = playerData_.money + 200
          playerData_.reputation = playerData_.reputation + 20
      end,
      cond = function() return playerData_.day >= 25 and npcJournal_["kwame"] ~= nil
          and npcJournal_["kwame"].events and #npcJournal_["kwame"].events >= 2 end,
    },

    -- ── 小马（Xiaoma）故事线：从偷零钱的员工到创业者 ──
    { title = "小马的生意经", icon = "📱",
      type = "auto",
      result = "小马神秘兮兮地拉你到门口，指着街对面的空铺面：'老板，我想好了。我要在那边开一个手机维修摊。'\n\n他从口袋里掏出一把螺丝刀，在阳光下闪闪发亮：'这三个月我一直在跟YouTube视频学修手机。你的网给了我第二条路。'\n\n你想起他刚来时偷零钱的样子，再看看现在。人是会变的。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 10
      end,
      cond = function() return playerData_.day >= 12 and npcJournal_["xiaoma"] ~= nil end,
    },
    { title = "小马出师了", icon = "🔧",
      type = "auto",
      result = "小马的手机维修摊开业了。他在招牌上写着：'Dragon Net Cafe推荐·小马手机急救站'。\n\n你没让他写这行字，但他坚持。'你教我最重要的一课，'他说，'就是给人第二次机会。'\n\n从此以后，来修手机的客人等待时就来网吧上网。双赢。",
      effect = function()
          trafficBonus_ = trafficBonus_ + 3
          playerData_.reputation = playerData_.reputation + 15
      end,
      cond = function() return playerData_.day >= 22 and npcJournal_["xiaoma"] ~= nil
          and npcJournal_["xiaoma"].events and #npcJournal_["xiaoma"].events >= 2 end,
    },

    -- ── 邻居（Neighbor）故事线：从送水果到果园危机 ──
    { title = "邻居的果树危机", icon = "🌳",
      type = "choice",
      desc = "邻居Uncle Charles急匆匆地跑来：'我的芒果树生病了！叶子全卷起来了，果子在烂！'\n\n他蹲在你店门口，双手抱头：'如果这一季颗粒无收，我女儿的学费就没着落了。农药要$120，我现在一分钱都拿不出来……'\n\n他平时总给你送水果，从来没开过口要钱。",
      choices = {
          { text = "💰 借他$120买农药", result = "你把钱递过去。Uncle Charles沉默了很久，然后说：'等芒果熟了，我还你三倍。'\n\n你知道他不一定还得起，但有些账不是用钱算的。",
            effect = function()
                playerData_.money = playerData_.money - 120
                playerData_.karma = playerData_.karma + 2
            end },
          { text = "🔍 帮他上网查防治方法", result = "你在网上搜了一下，找到了一种便宜的土方法——用烟草水喷洒。Uncle Charles如获至宝地抄下了配方。\n\n'互联网真是好东西，'他感叹道。",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 5
            end },
          { text = "🤷 帮不上忙", result = "你摊了摊手。Uncle Charles慢慢站起来，拍了拍裤子上的土：'没事。我再想想办法。'\n\n他走后你闻到空气里芒果腐烂的酸甜味。",
            effect = function() end },
      },
      cond = function() return playerData_.day >= 10 and npcJournal_["neighbor"] ~= nil end,
    },
    { title = "丰收季节", icon = "🥭",
      type = "auto",
      result = "Uncle Charles扛着一大筐金黄的芒果出现在门口，笑得像个孩子：'活了！都活了！'\n\n他把最大的几个芒果挑出来塞给你：'这些最甜的，留给你。没有你的帮忙，今年就完了。'\n\n芒果汁顺着手指流下来，甜得有点过分。这就是非洲的味道——苦涩之后的甜。",
      effect = function()
          playerData_.money = playerData_.money + 80
          playerData_.reputation = playerData_.reputation + 10
          trafficBonus_ = trafficBonus_ + 2
      end,
      cond = function() return playerData_.day >= 18 and npcJournal_["neighbor"] ~= nil
          and npcJournal_["neighbor"].events and #npcJournal_["neighbor"].events >= 2 end,
    },

    -- ── 校长（Principal）故事线：从合作到毕业 ──
    { title = "校长的电脑课", icon = "🏫",
      type = "auto",
      result = "校长带着十二个学生走进网吧。他们穿着整齐的校服，眼睛瞪得像铜铃。\n\n'这就是互联网，'校长指着屏幕说，'全世界的知识都在里面。'\n\n一个小女孩怯怯地问：'那我爸爸在南非，我能看到他吗？'\n\n你帮她打开了视频通话。当她爸爸的脸出现在屏幕上时，整个网吧安静了三秒——然后爆发出笑声和掌声。\n\n校长红着眼眶对你说：'这是最好的一堂课。'",
      effect = function()
          playerData_.reputation = playerData_.reputation + 20
          playerData_.karma = playerData_.karma + 1
      end,
      cond = function() return playerData_.day >= 15 and npcJournal_["principal"] ~= nil end,
    },
    { title = "毕业典礼", icon = "🎓",
      type = "auto",
      result = "毕业季。校长送来一封信，是学生们联名写的：\n\n'亲爱的Dragon Net Cafe老板：谢谢你让我们看到了世界。我们中间有三个人现在能用电脑了，有一个人和在南非的爸爸每周视频通话。我们不知道将来会去哪里，但我们知道世界比我们想象的要大得多。这是你教给我们的。'\n\n信纸边上画满了涂鸦和小花。你把这封信贴在了柜台后面的墙上。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 30
          playerData_.karma = playerData_.karma + 2
      end,
      cond = function() return playerData_.day >= 28 and npcJournal_["principal"] ~= nil
          and npcJournal_["principal"].events and #npcJournal_["principal"].events >= 2 end,
    },

    -- ── 油罐车司机（Tanker Driver）故事线：油荒预警 ──
    { title = "油荒", icon = "⛽",
      type = "auto",
      result = "油罐车司机老Ibrahim路过时探进头来：'小伙子，给你个消息——下游炼油厂出了事故，下周开始油价至少涨三成。'\n\n他压低声音：'趁现在赶紧囤点油。别跟别人说是我告诉你的。'\n\n你看了看自己的油表，又看了看钱包。这就是非洲——永远在囤什么和花什么之间做选择。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 5
      end,
      cond = function() return playerData_.day >= 14 and npcJournal_["tanker_driver"] ~= nil end,
    },

    -- ── 龙狗（Dragon Dog）故事线：生崽 → 网红 ──
    { title = "龙狗生崽了", icon = "🐕",
      type = "auto",
      result = "早上开门发现龙狗窝在柜台底下，旁边多了四个小毛球。它抬头看你一眼，尾巴轻轻晃了两下——像是在说'惊不惊喜？'\n\n四只小狗，两只棕色两只黑色，眼睛还没睁开就已经在哼哼唧唧地找奶喝了。\n\n消息传开后，半条街的人都来看小狗。顺便上了会儿网。",
      effect = function()
          trafficBonus_ = trafficBonus_ + 3
          playerData_.reputation = playerData_.reputation + 10
      end,
      cond = function() return playerData_.day >= 15 and npcJournal_["dragon_dog"] ~= nil end,
    },
    { title = "龙狗成网红", icon = "📱",
      type = "auto",
      result = "有个客人拍了龙狗带着四只小狗趴在机箱上的视频发到TikTok——一夜之间播放量破了十万。\n\n'非洲网吧的看门狗一家'成了热搜话题。有人从隔壁镇专门骑摩托来看龙狗，顺便成了常客。\n\n你看着龙狗，它正一脸淡定地趴在路由器上取暖。这只曾经的流浪狗，现在是这条街上最有名的居民。",
      effect = function()
          playerData_.reputation = playerData_.reputation + 30
          trafficBonus_ = trafficBonus_ + 5
      end,
      cond = function() return playerData_.day >= 22 and npcJournal_["dragon_dog"] ~= nil
          and npcJournal_["dragon_dog"].events and #npcJournal_["dragon_dog"].events >= 2 end,
    },

    -- ── Kofi Jr（Mama Blessing的儿子）故事线：音乐梦 ──
    { title = "Kofi的音乐梦", icon = "🎵",
      type = "choice",
      desc = "Kofi Jr走进来的时候戴着一副破旧的耳机，手里拿着一个U盘。\n\n'老板，我有个不情之请。'他从耳机里拔下一根线，'我自己写了几首歌，非洲节奏混合电子音乐的那种。我想用你的电脑录个demo，发到SoundCloud上。'\n\n他按下播放键，一段粗糙但充满生命力的旋律从手机外放里流出来。你的脚趾不自觉地跟着打起了拍子。\n\n'我妈说我疯了，'他苦笑，'但她不知道我在拉各斯打工的那两年，音乐是唯一支撑我活下来的东西。'",
      choices = {
          { text = "🎧 免费用店里设备录音", result = "你把角落里最好的那台电脑腾出来。Kofi Jr激动地戴上耳机，开始调试。\n\n两个小时后，他完成了三首歌。走的时候他握着你的手说：'如果有一天我红了，第一场演唱会在你网吧门口办。'\n\n你笑着说好。但看着他离去的背影，你觉得这不是个空头支票。",
            effect = function()
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 15
            end },
          { text = "💵 收取录音费 ($50)", result = "你伸出手指比了个五。Kofi Jr愣了一下，然后笑了：'老板是生意人。行。'\n\n他认真地录完了三首歌，付了$50。走的时候回头说：'这$50是我最值的投资。'",
            effect = function()
                playerData_.money = playerData_.money + 50
            end },
          { text = "🚫 现在太忙了", result = "你指了指满座的网吧。Kofi Jr理解地点点头：'没事，我再找机会。'\n\n他收起U盘走了。Mama Blessing后来跟你说：'那孩子回来后一直闷闷不乐。'",
            effect = function()
                playerData_.karma = playerData_.karma - 1
            end },
      },
      cond = function() return playerData_.day >= 18 and npcJournal_["kofi_jr"] ~= nil end,
    },

    -- ═══════════════════════════════════════════════════════
    -- v8: 极端事件 —— 非洲政变（极低概率，黄金专用）
    -- ═══════════════════════════════════════════════════════
    {
      title = "军事政变！",
      icon = "🪖",
      type = "auto",
      result = "",
      effect = function()
          local days = math.random(3, 5)
          playerData_.coupDaysLeft = days
          -- 政变当天立即冻结30%现金（银行关闭，ATM限取）
          local frozenRate = playerData_.goldSafe and 0.15 or 0.30  -- 黄金保险箱减半
          local frozen = math.floor(playerData_.money * frozenRate)
          playerData_.money = playerData_.money - frozen
          local COUP_DIARY = {
              "🪖⚠️ 【紧急快报】凌晨三点被枪声惊醒。军队控制了电视台和银行。将军宣布接管政权，实施全城戒严。\n\n"
              .. "📻 广播反复播送：'所有商业活动暂停。银行关闭，现金交易冻结。黄金等硬通货可作为临时支付手段。'\n\n"
              .. "💀 你的$" .. frozen .. "被冻结在银行里（-30%现金）。接下来" .. days .. "天，所有消费只能用黄金支付！\n\n"
              .. "💡 提示：政变期间金价会暴涨2.5倍。如果你有黄金储备，现在它比什么都值钱。如果没有……祈祷它快点结束吧。",

              "🪖⚠️ 【突发新闻】今天一早街上就全是军车。卫兵在每个路口设了检查站，商铺纷纷拉下卷帘门。\n\n"
              .. "📻 军方广播：'临时军事委员会宣布：即日起实施经济管制。所有银行账户冻结，禁止大额现金交易。'\n\n"
              .. "💀 你的$" .. frozen .. "取不出来了（-30%现金）。未来" .. days .. "天，只有黄金才能当钱花！\n\n"
              .. "💡 在非洲，黄金是最后的硬通货。有金子的人现在是大爷，没有的……只能硬扛了。",
          }
          AddLog(COUP_DIARY[math.random(1, #COUP_DIARY)])
      end,
      cond = function()
          -- 极低概率：第20天后，每天2.5%概率，且当前无政变，且之前最多发生过1次
          return playerData_.day >= 20
              and (playerData_.coupDaysLeft or 0) == 0
              and math.random(1, 1000) <= 25
              and (not storyTriggered_["coup_count"] or storyTriggered_["coup_count"] < 2)
      end,
    },

    -- ====================================================================
    -- 踢馆事件系统：其他网吧老板上门挑战，进行各种小游戏比拼
    -- ====================================================================

    -- ── 踢馆 #1：打字速度挑战 ──
    { id = "challenge_typing",
      cond = function() return playerData_.day >= 5 and #teamMembers_ >= 1 and math.random(1, 100) <= 12 end,
      type = "choice",
      title = "踢馆！打字速度王",
      icon = "⌨️",
      desc = "阿克拉的网吧老板 Kwadwo 骑着摩托车来到你的网吧门口，身后跟着一个打字飞快的小伙子。\n\n'听说你们Dragon Net的人号称'最快的手指'？我的店员 Felix 一分钟能打180个词！敢不敢比一场？'\n\n他甩出赌注：输家请对方全店免费上网一天。",
      choices = {
          { text = "🔥 应战！派最强队员上",
            result = function()
                local best = teamMembers_[1]
                for _, m in ipairs(teamMembers_) do
                    if m.skill > best.skill then best = m end
                end
                local myScore = best.skill * 2 + best.talent + math.random(0, 30)
                local rivalScore = 60 + math.random(0, 40)
                if myScore > rivalScore then
                    return "🏆 " .. best.name .. " 手指如飞！最终以 " .. (myScore) .. " vs " .. rivalScore .. " 的成绩碾压 Felix！\n\nKwadwo 目瞪口呆，乖乖掏钱请你全店上网。走的时候还偷偷问你队员用的什么键盘。\n\n💰+$80 声望+15"
                else
                    return "😤 Felix 果然名不虚传，打字速度快得像机关枪。" .. best.name .. " 虽然努力了，但以 " .. myScore .. " vs " .. rivalScore .. " 惜败。\n\nKwadwo 得意地笑了：'下次再来！'\n\n💰-$40 但队员受到刺激，技术+2"
                end
            end,
            effect = function()
                local best = teamMembers_[1]
                for _, m in ipairs(teamMembers_) do
                    if m.skill > best.skill then best = m end
                end
                local myScore = best.skill * 2 + best.talent + math.random(0, 30)
                local rivalScore = 60 + math.random(0, 40)
                if myScore > rivalScore then
                    playerData_.money = playerData_.money + 80
                    playerData_.reputation = playerData_.reputation + 15
                    AddLog("⌨️ 踢馆赛·打字速度：" .. best.name .. " 获胜！+$80 声望+15")
                else
                    playerData_.money = playerData_.money - 40
                    for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 2) end
                    AddLog("⌨️ 踢馆赛·打字速度：惜败！-$40 全队技术+2")
                end
            end,
          },
          { text = "😎 我亲自上阵！",
            result = function()
                local myScore = 50 + math.floor(playerData_.reputation / 10) + math.random(0, 30)
                local rivalScore = 60 + math.random(0, 40)
                if myScore > rivalScore then
                    return "🎉 老板亲自下场，居然赢了！你一分钟敲出了 " .. myScore .. " 个词，Felix 只有 " .. rivalScore .. " 个。\n\n全店沸腾！队员们高呼'老板威武'！Kwadwo 直呼'你开挂了吧？！'\n\n💰+$100 声望+20 全队心情+10"
                else
                    return "💦 老板虽然拼了命，但毕竟不是专业选手，以 " .. myScore .. " vs " .. rivalScore .. " 落败。\n\nKwadwo 大笑：'老板还是去管账吧！'\n\n💰-$50 但队员们被老板的精神感动，心情+5"
                end
            end,
            effect = function()
                local myScore = 50 + math.floor(playerData_.reputation / 10) + math.random(0, 30)
                local rivalScore = 60 + math.random(0, 40)
                if myScore > rivalScore then
                    playerData_.money = playerData_.money + 100
                    playerData_.reputation = playerData_.reputation + 20
                    for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 10) end
                    AddLog("⌨️ 踢馆赛·打字速度：老板亲自上阵获胜！+$100 声望+20")
                else
                    playerData_.money = playerData_.money - 50
                    for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
                    AddLog("⌨️ 踢馆赛·打字速度：老板虽败犹荣！-$50 全队心情+5")
                end
            end,
          },
          { text = "🙅 不比了，太幼稚",
            result = "你摆了摆手：'我们忙着练比赛呢，没空玩文字游戏。'\n\nKwadwo 耸耸肩离开了。但你总觉得队员们有点失望……\n\n全队心情-3",
            effect = function()
                for _, m in ipairs(teamMembers_) do m.mood = math.max(0, m.mood - 3) end
            end,
          },
      },
    },

    -- ── 踢馆 #2：网络知识问答 ──
    { id = "challenge_quiz",
      cond = function() return playerData_.day >= 8 and playerData_.netSpeed >= 2 and math.random(1, 100) <= 10 end,
      type = "choice",
      title = "踢馆！网络知识王",
      icon = "🧠",
      desc = "开罗的 Hassan 带着他的'学霸团队'不远千里来踢馆。\n\n'我听说你们网吧号称非洲最懂网络的店？那我们来比比网络知识？TCP三次握手、DNS解析、ping的原理……我的人可是计算机专业毕业的！'\n\nHassan 推了推眼镜：'一人一题，答错淘汰。赌注$120。'",
      choices = {
          { text = "🎓 来就来！知识就是力量",
            result = function()
                local knowledge = playerData_.netSpeed * 15 + math.floor(playerData_.reputation / 8) + math.random(0, 25)
                local rivalKnow = 55 + math.random(0, 35)
                if knowledge > rivalKnow then
                    return "🧠 你的队员居然懂得比计算机专业的还多！从IP子网划分到BGP路由协议，一路碾压！\n\nHassan 目瞪口呆：'你们……是野生的网络工程师吗？'\n\n💰+$120 声望+18"
                else
                    return "😅 虽然实战经验丰富，但理论功底还是差了点。Hassan 的队员在OSI七层模型那道题上把你们难倒了。\n\n'实践出真知，但理论也很重要哦。'Hassan 笑着走了。\n\n💰-$120 但受刺激买了本计算机网络教材，网速理解+1"
                end
            end,
            effect = function()
                local knowledge = playerData_.netSpeed * 15 + math.floor(playerData_.reputation / 8) + math.random(0, 25)
                local rivalKnow = 55 + math.random(0, 35)
                if knowledge > rivalKnow then
                    playerData_.money = playerData_.money + 120
                    playerData_.reputation = playerData_.reputation + 18
                    AddLog("🧠 踢馆赛·网络知识：完胜！+$120 声望+18")
                else
                    playerData_.money = playerData_.money - 120
                    playerData_.netSpeed = math.min(4, playerData_.netSpeed + 1)
                    AddLog("🧠 踢馆赛·网络知识：惜败但免费升级了网络知识！网速+1")
                end
            end,
            cond = function() return playerData_.money >= 120 end,
          },
          { text = "💡 提议换成实操比赛",
            result = "你说：'背书谁不会？有本事比谁能更快配好一台路由器！'\n\nHassan 犹豫了——他的人确实是纯理论派。最终双方各退一步，和平散场。\n\n你虽然没赢钱，但赢得了尊重。声望+8",
            effect = function()
                playerData_.reputation = playerData_.reputation + 8
                AddLog("🧠 踢馆赛·网络知识：机智化解为实操挑战，声望+8")
            end,
          },
      },
    },

    -- ── 踢馆 #3：装机大赛 ──
    { id = "challenge_build_pc",
      cond = function() return playerData_.day >= 10 and playerData_.computers >= 5 and math.random(1, 100) <= 10 end,
      type = "choice",
      title = "踢馆！极速装机王",
      icon = "🔧",
      desc = "约翰内斯堡的 Thabo 开着一辆装满电脑零件的皮卡来了。\n\n'我的Ubuntu Cafe以组装电脑闻名！听说你们Dragon Net设备也不错？那我们来比装机速度！从拆箱到开机进系统，看谁更快！'\n\n他掏出一箱全新零件：'输家把这箱零件送给赢家。价值$200。'",
      choices = {
          { text = "🔧 接受挑战！手速就是生产力",
            result = function()
                local mySkill = playerData_.computers * 3 + (playerData_.equipCondition or 100) / 10 + math.random(0, 30)
                local rivalSkill = 50 + math.random(0, 35)
                if mySkill > rivalSkill then
                    return "⚡ 你的人12分钟搞定！从CPU到显卡到走线，一气呵成。Thabo 的人还在纠结CPU散热器的方向。\n\n'不是……你们天天在装机吗？'Thabo 哭笑不得，把零件留下了。\n\n🖥️电脑+1 声望+12"
                else
                    return "💦 Thabo 的人果然是专业级别，8分钟就完成了！你的人虽然努力，但在走线环节耽误了时间。\n\n'多练练吧，下次再来！'Thabo 收走了零件。\n\n声望-5 但设备维护经验+10%"
                end
            end,
            effect = function()
                local mySkill = playerData_.computers * 3 + (playerData_.equipCondition or 100) / 10 + math.random(0, 30)
                local rivalSkill = 50 + math.random(0, 35)
                if mySkill > rivalSkill then
                    playerData_.computers = playerData_.computers + 1
                    playerData_.reputation = playerData_.reputation + 12
                    AddLog("🔧 踢馆赛·装机大赛：获胜！白得一台电脑+声望+12")
                else
                    playerData_.reputation = math.max(0, playerData_.reputation - 5)
                    playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 10)
                    AddLog("🔧 踢馆赛·装机大赛：惜败！设备维护经验+10%")
                end
            end,
          },
          { text = "🤝 提议合作而非对抗",
            result = "你笑着说：'与其比谁快，不如一起教社区的年轻人装机？'\n\nThabo 愣了一下，然后竖起大拇指：'你是个好人！'你们约好下周一起办装机工作坊。\n\n声望+15 karma+2",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                playerData_.karma = playerData_.karma + 2
                AddLog("🔧 踢馆赛·装机大赛：化敌为友！联手办装机工作坊 声望+15")
            end,
          },
      },
    },

    -- ── 踢馆 #4：吃鸡 Solo 决斗 ──
    { id = "challenge_br_solo",
      cond = function() return playerData_.day >= 12 and #teamMembers_ >= 2 and math.random(1, 100) <= 10 end,
      type = "choice",
      title = "踢馆！吃鸡之王",
      icon = "🍗",
      desc = "一个戴着墨镜的年轻人大摇大摆走进网吧，身后跟着两个拿着手机直播的人。\n\n'我是拉各斯的 Youssef，Pharaoh Gaming 的老板。我的人在非洲服排名前十。听说你们也在练三角洲？不如来一场 Solo 对决？'\n\n他指了指直播手机：'而且我要全程直播。赢了的话……你们就火了。输了嘛……哈哈哈。'\n\n赌注：$150 + 输家在自家店门口挂对方招牌一周。",
      choices = {
          { text = "🎯 派出王牌！为荣誉而战",
            result = function()
                local best = teamMembers_[1]
                for _, m in ipairs(teamMembers_) do
                    if (m.skill + m.talent) > (best.skill + best.talent) then best = m end
                end
                local myPower = best.skill * 2 + best.talent + best.mood / 5 + math.random(0, 25)
                local rivalPower = 80 + math.random(0, 50)
                if myPower > rivalPower then
                    return "🐔 " .. best.name .. " 在直播镜头前上演了教科书级别的Solo！最后用一把平底锅淘汰了对手，弹幕疯狂刷'666'！\n\nYoussef 的脸都绿了，因为有3万人在看……\n\n💰+$150 声望+30（直播效应）全队心情+15"
                else
                    return "😰 " .. best.name .. " 太紧张了！在直播压力下发挥失常，被对手一枪爆头。弹幕全是'下次加油'。\n\nYoussef 得意地做了个剪刀手。但这场直播让更多人知道了Dragon Net。\n\n💰-$150 声望+10（曝光度）技术+3（知耻后勇）"
                end
            end,
            effect = function()
                local best = teamMembers_[1]
                for _, m in ipairs(teamMembers_) do
                    if (m.skill + m.talent) > (best.skill + best.talent) then best = m end
                end
                local myPower = best.skill * 2 + best.talent + best.mood / 5 + math.random(0, 25)
                local rivalPower = 80 + math.random(0, 50)
                if myPower > rivalPower then
                    playerData_.money = playerData_.money + 150
                    playerData_.reputation = playerData_.reputation + 30
                    for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 15) end
                    AddLog("🍗 踢馆赛·吃鸡Solo：" .. best.name .. " 直播获胜！+$150 声望+30")
                else
                    playerData_.money = playerData_.money - 150
                    playerData_.reputation = playerData_.reputation + 10
                    for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 3) end
                    AddLog("🍗 踢馆赛·吃鸡Solo：直播惜败但获得曝光！-$150 声望+10 全队技术+3")
                end
            end,
            cond = function() return playerData_.money >= 150 end,
          },
          { text = "📱 反将一军：要求线下LAN赛",
            result = "你说：'线上谁知道你有没有开挂？有种来线下LAN赛！'\n\nYoussef 一愣，他的人其实只擅长线上，线下紧张得手抖。最终双方改期，约好下次线下再战。\n\n你用智慧避开了一场可能的直播翻车。声望+5",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                AddLog("🍗 踢馆赛·吃鸡Solo：机智要求LAN赛，化解危机 声望+5")
            end,
          },
      },
    },

    -- ── 踢馆 #5：烤鸡大赛 ──
    { id = "challenge_chicken_cook",
      cond = function() return playerData_.day >= 7 and playerData_.foodShop >= 1 and math.random(1, 100) <= 10 end,
      type = "choice",
      title = "踢馆！烤鸡之神",
      icon = "🍗",
      desc = "一个胖胖的中年妇女带着浓烈的炭火香味闯了进来。\n\n'我是达喀尔的 Fatou 阿姨！听说你们网吧的烤鸡在本地有点名气？哼！我做了30年烤鸡！来比一场吗？'\n\n她从大包里掏出秘制酱料：'赌注：输的人把烤鸡配方给赢家！而且请全店吃一顿！'",
      choices = {
          { text = "🍗 比就比！我们的烤鸡无敌",
            result = function()
                local cookScore = playerData_.foodShop * 20 + playerData_.reputation / 10 + math.random(0, 30)
                local rivalScore = 40 + math.random(0, 40)
                if cookScore > rivalScore then
                    return "🏆 你的烤鸡竟然赢了！秘诀是——Mama B 偷偷加了她的独家辣酱！Fatou 阿姨尝了一口就愣住了。\n\n'这个辣度……这个焦香……你们有高人！'她心服口服地留下了她的酱料配方。\n\n🍗 餐饮升级！食品收入+20% 声望+12"
                else
                    return "😋 Fatou 阿姨不愧是30年老手，她的烤鸡香得连隔壁都来围观了。你输得心服口服。\n\n'小伙子，烤鸡不只是火候，还有爱！'她临走前偷偷教了你一招腌制技巧。\n\n💰-$60 但学到新配方，食品收入+10%"
                end
            end,
            effect = function()
                local cookScore = playerData_.foodShop * 20 + playerData_.reputation / 10 + math.random(0, 30)
                local rivalScore = 40 + math.random(0, 40)
                if cookScore > rivalScore then
                    playerData_.foodShop = math.min(4, playerData_.foodShop + 1)
                    playerData_.reputation = playerData_.reputation + 12
                    AddLog("🍗 踢馆赛·烤鸡大赛：我们赢了！获得秘制配方 餐饮升级+声望+12")
                else
                    playerData_.money = playerData_.money - 60
                    playerData_.reputation = playerData_.reputation + 5
                    AddLog("🍗 踢馆赛·烤鸡大赛：输了但学到新招！-$60 声望+5")
                end
            end,
          },
          { text = "🤗 邀请她留下来当特邀厨师",
            result = "你说：'Fatou 阿姨，与其比赛，不如您来当我们的特邀厨师？我们可以分成合作！'\n\nFatou 眼睛一亮：'你这小伙子……有商业头脑！'她答应每周来一次做特色烤鸡。\n\n食品收入+15% 声望+10 karma+2",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10
                playerData_.karma = playerData_.karma + 2
                -- 食品等级提升模拟收入增加
                if playerData_.foodShop < 4 then playerData_.foodShop = playerData_.foodShop + 1 end
                AddLog("🍗 踢馆赛·烤鸡大赛：化敌为友！邀请Fatou阿姨合作 餐饮升级+声望+10")
            end,
          },
      },
    },

    -- ── 踢馆 #6：电费节约挑战 ──
    { id = "challenge_power_save",
      cond = function() return playerData_.day >= 15 and playerData_.solarLevel >= 1 and math.random(1, 100) <= 8 end,
      type = "choice",
      title = "踢馆！省电达人",
      icon = "⚡",
      desc = "内罗毕的 Amina 是出了名的'绿色网吧'倡导者。她来参观你的太阳能设备后，突然提出挑战。\n\n'我赌你一天之内用不了比我更少的电！我的Safari Online 已经实现了60%太阳能供电。你们呢？'\n\n赌注：$100。输家还要在社交媒体上帮赢家宣传环保理念。",
      choices = {
          { text = "☀️ 接受！太阳能就是未来",
            result = function()
                local myGreen = playerData_.solarLevel * 25 + playerData_.generatorLevel * 5 + math.random(0, 20)
                local rivalGreen = 55 + math.random(0, 30)
                if myGreen > rivalGreen then
                    return "☀️ 你的太阳能系统效率惊人！一天下来，你的电费比 Amina 低了23%！\n\nAmina 心服口服：'看来我该来你这取经了。'她在社交媒体上大力宣传了Dragon Net的环保理念。\n\n💰+$100 声望+20 粉丝暴涨"
                else
                    return "😓 Amina 果然是专业的，她的太阳能方案效率比你高出一截。你虽然努力了，但差距明显。\n\n'别灰心，环保是长期投资！'她分享了一些节电技巧。\n\n💰-$100 但太阳能效率提升，每日电费-$5"
                end
            end,
            effect = function()
                local myGreen = playerData_.solarLevel * 25 + playerData_.generatorLevel * 5 + math.random(0, 20)
                local rivalGreen = 55 + math.random(0, 30)
                if myGreen > rivalGreen then
                    playerData_.money = playerData_.money + 100
                    playerData_.reputation = playerData_.reputation + 20
                    AddLog("⚡ 踢馆赛·省电达人：获胜！+$100 声望+20")
                else
                    playerData_.money = playerData_.money - 100
                    if playerData_.solarLevel < 3 then playerData_.solarLevel = playerData_.solarLevel + 1 end
                    AddLog("⚡ 踢馆赛·省电达人：输了但获得节电秘籍！太阳能升级")
                end
            end,
            cond = function() return playerData_.money >= 100 end,
          },
          { text = "🌍 提议联合推广太阳能",
            result = "你说：'比赛不如合作！我们一起向非洲网吧推广太阳能方案，做成一个品牌！'\n\nAmina 激动了：'你懂我！'你们握手成立了'非洲绿色网吧联盟'。\n\n声望+25 karma+3 Amina 成为长期合作伙伴",
            effect = function()
                playerData_.reputation = playerData_.reputation + 25
                playerData_.karma = playerData_.karma + 3
                AddLog("⚡ 踢馆赛·省电达人：成立非洲绿色网吧联盟！声望+25 karma+3")
            end,
          },
      },
    },

    -- ── 踢馆 #7：网速大比拼 ──
    { id = "challenge_speedtest",
      cond = function() return playerData_.day >= 6 and math.random(1, 100) <= 12 end,
      type = "choice",
      title = "踢馆！网速之王",
      icon = "📶",
      desc = "一辆贴满贴纸的面包车停在门口，车身上喷着'Thunder Net——非洲最快网速'。金沙萨的 Mobutu Jr 叼着牙签走进来。\n\n'嘿，Dragon什么的，我听说你们网速不错？来来来，开个Speedtest，谁慢谁在门口立块牌子写：XX网吧，网速不如Thunder Net。'\n\n他已经打开了手机app：'三局两胜，赌$80。'",
      choices = {
          { text = "📶 开测！我们网速碾压你",
            result = function()
                local mySpeed = playerData_.netSpeed * 25 + math.random(0, 30)
                local rivalSpeed = 30 + math.random(0, 50)
                if mySpeed > rivalSpeed then
                    return "🚀 Speedtest 结果出来了——你们的下载速度是 " .. (mySpeed * 2) .. "Mbps，Thunder Net 只有 " .. (rivalSpeed * 2) .. "Mbps！\n\nMobutu Jr 的牙签掉了：'这不科学！你们是接了海底光缆吗？！'\n\n他灰溜溜地把面包车上的贴纸撕了……\n\n💰+$80 声望+12"
                else
                    return "😰 Speedtest 显示你们的网速是 " .. (mySpeed * 2) .. "Mbps，而 Thunder Net 竟然有 " .. (rivalSpeed * 2) .. "Mbps！\n\nMobutu Jr 得意地吹了个口哨：'慢网吧还是老老实实待着吧。'\n\n不过这激励你升级了网络设备。\n\n💰-$80 但认清了差距，网络效率+1"
                end
            end,
            effect = function()
                local mySpeed = playerData_.netSpeed * 25 + math.random(0, 30)
                local rivalSpeed = 30 + math.random(0, 50)
                if mySpeed > rivalSpeed then
                    playerData_.money = playerData_.money + 80
                    playerData_.reputation = playerData_.reputation + 12
                    AddLog("📶 踢馆赛·网速比拼：碾压获胜！+$80 声望+12")
                else
                    playerData_.money = playerData_.money - 80
                    playerData_.netSpeed = math.min(4, playerData_.netSpeed + 1)
                    AddLog("📶 踢馆赛·网速比拼：惜败但升级了网络！-$80 网速+1")
                end
            end,
            cond = function() return playerData_.money >= 80 end,
          },
          { text = "🤫 使出杀手锏：测延迟而不是带宽",
            result = "你笑着说：'网速不只看下载，打游戏关键看延迟啊！来比Ping值！'\n\nMobutu Jr 的脸瞬间垮了——Thunder Net虽然带宽大，但延迟高达200ms。而你优化过路由，Ping只有45ms。\n\n'你……你耍赖！'Mobutu Jr 气冲冲地走了，但输的是他。\n\n💰+$80 声望+8",
            effect = function()
                playerData_.money = playerData_.money + 80
                playerData_.reputation = playerData_.reputation + 8
                AddLog("📶 踢馆赛·网速比拼：用延迟反杀！+$80 声望+8")
            end,
          },
      },
    },

    -- ── 踢馆 #8：咖啡拉花对决 ──
    { id = "challenge_latte_art",
      cond = function() return playerData_.day >= 14 and (playerData_.coffeeLevel or 0) >= 1 and math.random(1, 100) <= 8 end,
      type = "choice",
      title = "踢馆！拉花艺术家",
      icon = "☕",
      desc = "亚的斯亚贝巴的 Tekle 是咖啡文化的传人。他带着自己烘焙的埃塞俄比亚咖啡豆来了。\n\n'我听说你们网吧居然开了咖啡吧台？在埃塞俄比亚人面前卖咖啡？来，比一比谁的拉花更好看！'\n\n他已经开始磨豆了：'输家要在对方店里免费做一周咖啡师。'",
      choices = {
          { text = "☕ 艺术对决！谁怕谁",
            result = function()
                local myCoffee = (playerData_.coffeeLevel or 0) * 20 + math.random(0, 30)
                local rivalCoffee = 50 + math.random(0, 30)
                if myCoffee > rivalCoffee then
                    return "🎨 你的店员拉出了一个完美的非洲地图拉花！全场惊呼！Tekle 震惊了——他以为只有埃塞俄比亚人才懂咖啡。\n\n'你们……在哪学的？'他颤抖着问。\n\n'YouTube。'你的店员平静地说。\n\n☕ 咖啡吧台名声大振！声望+18 咖啡收入翻倍一周"
                else
                    return "😅 Tekle 的拉花是一只栩栩如生的狮子，而你的店员……拉出了一团不明物体。\n\n'别气馁，咖啡需要时间。'Tekle 大方地教了你几招。\n\n免费获得咖啡培训！咖啡技术升级"
                end
            end,
            effect = function()
                local myCoffee = (playerData_.coffeeLevel or 0) * 20 + math.random(0, 30)
                local rivalCoffee = 50 + math.random(0, 30)
                if myCoffee > rivalCoffee then
                    playerData_.reputation = playerData_.reputation + 18
                    playerData_.money = playerData_.money + 60
                    AddLog("☕ 踢馆赛·拉花对决：非洲地图拉花震惊全场！声望+18 +$60")
                else
                    if playerData_.coffeeLevel < 3 then playerData_.coffeeLevel = playerData_.coffeeLevel + 1 end
                    playerData_.reputation = playerData_.reputation + 5
                    AddLog("☕ 踢馆赛·拉花对决：输了但获得免费培训！咖啡升级+声望+5")
                end
            end,
          },
          { text = "🫖 以茶会友：提议中非咖啡茶文化交流",
            result = "你提议：'比赛不如交流！我们这边有中国茶文化，你那边有埃塞咖啡文化，不如搞个中非饮品交流会？'\n\nTekle 眼睛发亮：'绝妙！'你们联手举办了一场爆满的活动。\n\n声望+20 karma+2 收入+$40",
            effect = function()
                playerData_.reputation = playerData_.reputation + 20
                playerData_.karma = playerData_.karma + 2
                playerData_.money = playerData_.money + 40
                AddLog("☕ 踢馆赛·拉花对决：以茶会友，中非文化交流！声望+20 +$40")
            end,
          },
      },
    },

    -- ═══════════════════════════════════════════════
    -- ■ 三角洲行动/电竞多元化 随机事件
    -- ═══════════════════════════════════════════════

    { weight = 15, minDay = 5,
      title = "🔫 三角洲行动大版本更新",
      desc = "三角洲行动发布了重大更新——全新地图'沙漠风暴'上线！网吧里的玩家都在讨论新地图的战术点位。你的队员也跃跃欲试。",
      cond = function() return #teamMembers_ >= 2 end,
      choices = {
          { text = "🗺️ 组织队员集训新地图",
            result = "你让全队花了一个下午研究新地图的每个角落。\n\n从高点狙击位到隐蔽绕后路线，队员们如获至宝。\n\n技能+3 心情+8",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 3)
                    m.mood = math.min(100, m.mood + 8)
                end
                AddLog("🔫 三角洲新地图集训！全队技能+3 心情+8")
            end,
          },
          { text = "📺 举办新地图体验活动吸引客流",
            result = "你在网吧门口挂出横幅：'三角洲新地图首日体验！老玩家带新人！'\n\n一整天网吧爆满，连隔壁理发店的小哥都来凑热闹了。\n\n声望+15 收入+$50",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                playerData_.money = playerData_.money + 50
                AddLog("🔫 新地图体验活动大成功！声望+15 +$50")
            end,
          },
      },
    },

    { weight = 12, minDay = 10,
      title = "💣 CS:GO 线上赛邀请",
      desc = "一个本地电竞社区发来消息：'我们正在举办一场CS:GO线上社区杯，奖金不多但能刷刷存在感。你们Dragon Force有兴趣参加吗？'",
      cond = function() return #teamMembers_ >= 3 and playerData_.reputation >= 30 end,
      choices = {
          { text = "✅ 报名参赛",
            result = "你带队报名了CS:GO社区杯。虽然三角洲是主项目，但队员们的枪法底子不差。\n\n经过三天的线上鏖战，Dragon Force在CS:GO赛场也打出了名号！\n\n声望+20 技能+2 哈弗币+30",
            effect = function()
                playerData_.reputation = playerData_.reputation + 20
                playerData_.havocCoins = playerData_.havocCoins + 30
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 2)
                end
                AddLog("💣 CS:GO社区杯参赛！跨游戏历练，声望+20 技能+2")
            end,
          },
          { text = "❌ 婉拒，专注三角洲",
            result = "你回复：'感谢邀请，我们现阶段专注三角洲行动的训练。下次有三角洲的比赛一定参加！'\n\n社区表示理解，并承诺以后会办三角洲赛事。\n\n心情+5",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, m.mood + 5)
                end
                AddLog("💣 婉拒CS:GO赛，专注主业。心情+5")
            end,
          },
      },
    },

    { weight = 10, minDay = 15,
      title = "🪂 PUBG 吃鸡挑战赛",
      desc = "网吧一位常客是PUBG主播，他提议：'你们战队来我直播间打一场表演赛吧！我的粉丝都想看Dragon Force在吃鸡里是什么水平。'",
      cond = function() return #teamMembers_ >= 3 and playerData_.reputation >= 50 end,
      choices = {
          { text = "🎬 接受直播表演赛",
            result = "队员们第一次在这么多人面前打PUBG。\n\n虽然吃鸡经验不多，但出色的团队配合让弹幕刷满了'666'和'非洲战神'！\n\n" ..
                     "主播粉丝纷纷来网吧打卡，声望+25 收入+$80 哈弗币+20",
            effect = function()
                playerData_.reputation = playerData_.reputation + 25
                playerData_.money = playerData_.money + 80
                playerData_.havocCoins = playerData_.havocCoins + 20
                AddLog("🪂 PUBG直播表演赛！非洲战神名号传开！声望+25 +$80")
            end,
          },
          { text = "🤔 先私下练练再说",
            result = "你谨慎地回复：'我们先内部练习几天，磨合一下吃鸡的战术。'\n\n主播表示理解：'没问题，随时欢迎！'\n\n队员们利用空闲时间练习了几局，对吃鸡有了新的理解。\n\n技能+2",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 2)
                end
                AddLog("🪂 先练后赛，队员PUBG技术提升。技能+2")
            end,
          },
      },
    },

    { weight = 10, minDay = 8,
      title = "🗡️ Dota 2 老玩家来访",
      desc = "一位自称'前Dota 2半职业选手'的中年人走进网吧。他头发花白但眼神锐利：'听说你们队三角洲打得好？我教你们一手Dota式的团战指挥。'",
      cond = function() return #teamMembers_ >= 2 end,
      choices = {
          { text = "🎓 虚心求教",
            result = "老玩家花了两个小时讲解Dota 2的团战节奏和资源分配理念。\n\n'不管什么游戏，开团时机和资源控制都是一样的道理。'\n\n队员们恍然大悟，战术意识大涨！\n\n技能+4 心情+5",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 4)
                    m.mood = math.min(100, m.mood + 5)
                end
                AddLog("🗡️ Dota老兵传授团战心法！技能+4 心情+5")
            end,
          },
          { text = "🤝 邀请他当兼职顾问",
            result = "你递上一杯咖啡：'大哥，有没有兴趣每周来一次，给我们队做做战术分析？薪酬好商量。'\n\n" ..
                     "他笑了笑：'工钱不要，让我没事来这里免费上网就行。'\n\n达成合作！\n\n声望+10 技能+3 karma+1",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10
                playerData_.karma = playerData_.karma + 1
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 3)
                end
                AddLog("🗡️ Dota老兵成为战术顾问！技能+3 声望+10 karma+1")
            end,
          },
      },
    },

    { weight = 12, minDay = 12,
      title = "⚡ Valorant 战术移植",
      desc = "Grace在看Valorant比赛录像时突然叫起来：'教练快来！这个Valorant战术完全可以移植到三角洲里！双闪配合加封烟绕后！'",
      cond = function() return HasMember("Grace") end,
      choices = {
          { text = "🧪 立刻组织全队试验",
            result = "全队花了一个晚上反复演练Grace发现的跨游戏战术。\n\n从Valorant移植来的闪光弹配合确实让三角洲的进攻节奏提升了一大截！\n\n技能+5 Grace心情+15",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 5)
                    if m.name == "Grace" then m.mood = math.min(100, m.mood + 15) end
                end
                AddLog("⚡ 跨游戏战术移植成功！全队技能+5 Grace心情+15")
            end,
          },
          { text = "📝 记录下来以后慢慢研究",
            result = "你让Grace把战术要点记录在白板上：'好想法，不过我们先把手头的比赛打好，之后再慢慢完善。'\n\nGrace虽然有点失望，但也理解。\n\n技能+2",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 2)
                end
                AddLog("⚡ 记录了Valorant战术，以后慢慢研究。技能+2")
            end,
          },
      },
    },

    -- ══ 三角洲猛攻节联动梗 ══

    { weight = 10, minDay = 8,
      title = "🏷️ 你的网吧是什么风格？",
      desc = "抖音上火了一个帖子，给全非洲的网吧分类——「刚枪网吧」、「老六窝」、「鼠鼠避难所」。\n\n你的网吧被投票归类了！评论区吵翻天：'这家老板是中国人，肯定是刚枪网吧！''不对不对，我上次去他们全在蹲角落，绝对老六窝！'",
      choices = {
          { text = "💪 认领「刚枪网吧」（硬核路线）",
            result = "你在门口挂上横幅：'刚枪圣地，怯战者勿入'。硬核玩家慕名而来，但设备损耗也加快了……\n\n声望+20 收入+$80 但维修费+$30",
            effect = function()
                playerData_.reputation = playerData_.reputation + 20
                playerData_.money = playerData_.money + 80 - 30
                AddLog("🏷️ 「刚枪网吧」名号打响！硬核玩家蜂拥而至。声望+20 +$50")
            end,
          },
          { text = "🐭 认领「鼠鼠避难所」（新手友好）",
            result = "你贴了个告示：'本店欢迎所有段位，骂人的滚'。新手小白们感动得直发帖——'终于有个不被喷的地方了！'\n\n声望+15 新客户+$60 心情+5",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                playerData_.money = playerData_.money + 60
                for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
                AddLog("🐭 「鼠鼠避难所」温暖了新手的心！声望+15 +$60")
            end,
          },
          { text = "🕶️ 认领「老六窝」（战术大师）",
            result = "你在墙上挂了条幅：'苟到最后就是胜利'。一群战术流玩家找到了精神家园，安安静静蹲点到天亮，续费率奇高。\n\n声望+10 收入+$50 续费率提升",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10
                playerData_.money = playerData_.money + 50
                trafficBonus_ = trafficBonus_ + 3
                AddLog("🕶️ 「老六窝」名不虚传！粘性玩家越来越多。声望+10 +$50 客流+3")
            end,
          },
      },
    },

    { weight = 6, minDay = 12,
      title = "🔥 猛攻哲学",
      desc = "Kwame看完三角洲猛攻节的直播，两眼放光地冲过来：'老板！你看到那个TVC没有？姜文说的——站着，还把钱挣了！'\n\n他激动得手舞足蹈：'我们打比赛也要这样！猛攻不被定义！不要老是蹲坑苟命，直接冲！'",
      cond = function() return #teamMembers_ >= 2 end,
      choices = {
          { text = "🔥 支持！把战队口号改成「猛攻不被定义」",
            result = "全队换上了新口号。Kwame兴奋得把'猛攻不被定义'写满了训练白板。\n\n下场比赛大家确实猛了……就是有点太猛了，Snake冲出去三秒就倒了。\n\n'这叫战术性试探！'Kwame一脸认真地解释。\n\n全队士气+10 但下场比赛有概率翻车",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, m.mood + 10)
                    m.skill = math.min(SKILL_CAP, m.skill + 1)
                end
                playerData_.reputation = playerData_.reputation + 5
                AddLog("🔥 战队新口号：「猛攻不被定义」！士气高涨但有点上头……")
            end,
          },
          { text = "🧠 泼冷水：我们得稳，先活着才能输出",
            result = "你拍拍Kwame的肩膀：'姜文可以猛，因为他有实力。我们先把基本功练好。'\n\nKwame想了想觉得有道理，默默回去加练了。\n\n全队技能+3",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 3)
                end
                AddLog("🧠 冷静分析猛攻哲学，队员们专注训练。技能+3")
            end,
          },
      },
    },

    { weight = 7, minDay = 18,
      title = "⭐ 明星来打游戏",
      desc = "一个戴墨镜的人低调走进网吧，开了台机子开始直播打三角洲。\n\n你凑过去一看弹幕——'卧槽这不是非洲版何润东吗？？''他怎么只打普通地图啊哈哈哈''菜就多练 别搁这儿直播了'\n\n他确实有点菜，但是他粉丝多啊……直播间已经涌入了五万人，都在问：'这是哪个网吧？'",
      cond = function() return playerData_.reputation >= 50 end,
      choices = {
          { text = "📸 蹭热度！在直播镜头前挂网吧招牌",
            result = "你偷偷把网吧横幅挂到他背后，弹幕立刻炸了：'这广告植入太硬了吧！''老板格局大！'\n\n'明星'回头看了一眼横幅，竖起大拇指：'老板你比我猛！'\n\n声望+35 +$120 但有人说你'碰瓷'",
            effect = function()
                playerData_.reputation = playerData_.reputation + 35
                playerData_.money = playerData_.money + 120
                playerData_.karma = playerData_.karma - 1
                AddLog("📸 蹭明星直播热度！声望暴涨但口碑略有争议。+35声望 +$120")
            end,
          },
          { text = "☕ 安静服务，给他泡杯茶",
            result = "你什么也没说，默默给他端了杯茶和一包辣条。\n\n'明星'感动了，下播后特意找到你：'老板，你这个人实在。以后我每周来你这儿播一次。'\n\n他成了你的固定VIP客户。声望+20 每周客流+5",
            effect = function()
                playerData_.reputation = playerData_.reputation + 20
                playerData_.money = playerData_.money + 50
                trafficBonus_ = trafficBonus_ + 5
                playerData_.karma = playerData_.karma + 2
                AddLog("☕ 明星被你的实在感动，成为固定VIP！声望+20 客流+5")
            end,
          },
      },
    },

    { weight = 8, minDay = 20,
      title = "🏰 英雄联盟全明星表演赛",
      desc = "本地电竞联盟要办一场LOL全明星趣味赛，邀请各游戏战队跨界参赛。'别紧张，就是娱乐性质的！来玩玩嘛！'",
      cond = function() return #teamMembers_ >= 4 and playerData_.reputation >= 80 end,
      choices = {
          { text = "🎪 全队参加表演赛",
            result = "Dragon Force的LOL首秀——虽然操作略显生疏，但队员们的团队默契让观众印象深刻。\n\n" ..
                     "Snake居然用刺客拿了五杀！解说直呼：'FPS玩家的刺客居然这么强？！'\n\n声望+30 收入+$100 全队心情+10",
            effect = function()
                playerData_.reputation = playerData_.reputation + 30
                playerData_.money = playerData_.money + 100
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, m.mood + 10)
                end
                AddLog("🏰 LOL全明星表演赛！Snake五杀名场面！声望+30 +$100")
            end,
          },
          { text = "👀 派代表去观战学习",
            result = "你派了两个队员去观赛。他们虽然没上场，但观摩了其他战队的训练方法和团队管理。\n\n'教练，原来LOL战队的赛前准备流程这么专业！我们也得学学。'\n\n技能+2 声望+8",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 2)
                end
                playerData_.reputation = playerData_.reputation + 8
                AddLog("🏰 观摩LOL赛事，学到新的训练方法。技能+2 声望+8")
            end,
          },
      },
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- 异闻二选一（v9 · 街头怪谈/都市传说，高风险 vs 稳妥）
    -- ═══════════════════════════════════════════════════════════════════════

    { type = "choice", title = "幸运壁虎", icon = "🦎",
      desc = "天花板掉下来一只金黄色的壁虎，不偏不倚落在你的键盘上。Mama Blessing惊呼：'金壁虎！这是Mami Wata的使者！看到的人要么暴富，要么破财——取决于你怎么对它！'",
      choices = {
          { text = "🪙 给它喂一枚金币（-$50）", result = "你把一枚硬币放在壁虎面前。它叼起来，从窗户缝跑了。\n\n三天后你在门口捡到一个信封——里面是$200现金和一张纸条：'金壁虎还债，利息三倍。'\n\n谁放的？没人知道。\n\n💰净+$150",
            effect = function() playerData_.money = playerData_.money + 150; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 50 end },
          { text = "🧹 赶走它", result = "你用扫帚把壁虎赶出门。Mama Blessing摇头叹气。\n\n今天格外平静。也许什么都不会发生。也许已经发生了，你只是没注意到。\n\n（无事发生……真的吗？）",
            effect = function() playerData_.karma = playerData_.karma - 1 end },
      },
      cond = function() return playerData_.day >= 5 and math.random(1, 100) <= 8 end,
    },
    { type = "choice", title = "神秘来电", icon = "📞",
      desc = "深夜，网吧座机响了。你拿起来，对面沙沙的声音里传来一个低沉的男声：\n\n'Dragon老板……你网吧3号机的座位下面，有一样东西。我放在那里三个月了。今晚是截止日——你可以打开看看，也可以假装没接到这个电话。'\n\n电话挂了。你看向3号机……座位底下确实贴着一个棕色信封。",
      choices = {
          { text = "📨 打开信封", result = "信封里是三张彩票和一张纸条：'中了我们五五分，没中就当我请你看戏。——匿名路人甲'\n\n你刮开了……第二张中了$300！\n\n你把$150放回信封，贴在了3号机底下。\n\n💰+$150 就……挺刺激的",
            effect = function() playerData_.money = playerData_.money + 150; playerData_.reputation = playerData_.reputation + 5 end },
          { text = "🚫 当作没听到", result = "你放下电话，假装什么都没发生。但这一夜你总觉得3号机底下有什么东西在看着你。\n\n第二天早上信封不见了。就好像从没存在过一样。\n\n（安全选择。也许。）",
            effect = function() playerData_.karma = playerData_.karma + 1 end },
      },
      cond = function() return playerData_.day >= 8 and math.random(1, 100) <= 7 end,
    },
    { type = "choice", title = "斗鸡大赛", icon = "🐓",
      desc = "门口传来一阵骚动。原来两个顾客在赌斗鸡——一只叫'网速'，一只叫'延迟'。围观的人把你的门口堵得水泄不通。\n\n'老板！押一把不？赢了翻三倍！'有人朝你喊。\n\n两只鸡瞪着血红的眼睛互相绕圈。",
      choices = {
          { text = "🐓 押'网速'（$80）", result = function()
              if playerData_._cockfightWon then
                  return "'网速'一记飞踢KO了'延迟'！全场沸腾！\n\n你赢了$240！有人高喊：'Dragon老板是赌神！'\n\n💰+$160 声望+10\n\n（赌博有风险，这次纯粹运气好。）"
              else
                  return "'延迟'使出了绝招——原地不动。'网速'冲过去踩空了，摔进了水沟。\n\n你输了$80。Mama Blessing摇头：'我说了叫'延迟'的东西永远赢。'\n\n💸-$80"
              end
          end,
            effect = function()
              playerData_._cockfightWon = math.random(1, 100) <= 55
              if playerData_._cockfightWon then
                  playerData_.money = playerData_.money + 160; playerData_.reputation = playerData_.reputation + 10
              else
                  playerData_.money = playerData_.money - 80
              end
            end,
            cond = function() return playerData_.money >= 80 end },
          { text = "🙅 不赌，但卖观众席位", result = "你搬了十把椅子摆在门口，每把收$2的'VIP观赛席'。\n\n十把椅子全坐满了。斗鸡结束后，观众意犹未尽，进网吧继续消费。\n\n💰+$40 稳赚不赔，这就是生意人的思维。",
            effect = function() playerData_.money = playerData_.money + 40; playerData_.reputation = playerData_.reputation + 5 end },
      },
      cond = function() return playerData_.day >= 6 and math.random(1, 100) <= 10 end,
    },
    { type = "choice", title = "抖音博主踢馆", icon = "🎬",
      desc = "一个戴着LED墨镜的年轻人扛着三脚架走进网吧：'我是TikTok博主LagKing，粉丝50万。我专拍非洲网吧测评！'\n\n他开始拍视频：'今天来测测这家中国人开的网吧——网速能不能跑4K？空调够不够冷？跑刀能不能不卡？'\n\n全网吧的人都在看着你。怎么应对？",
      choices = {
          { text = "🎤 全力配合+送他VIP体验", result = "你打开最好的机器，调了最快的网线，还让Mama Blessing送来免费烤鸡。\n\n博主直呼：'这是我测过最强的非洲网吧！推荐！五星！'\n\n视频发出后三天，客流翻倍。\n\n💰-$30 声望+40 客流+6",
            effect = function() playerData_.money = playerData_.money - 30; playerData_.reputation = playerData_.reputation + 40; trafficBonus_ = trafficBonus_ + 6; cachedTrafficDay_ = -1 end },
          { text = "📋 要求他签免责协议再拍", result = "你递给他一张手写的'拍摄协议'。博主愣住了：'大哥你认真的？'\n\n他拍了这一幕发到网上，标题是'非洲最正规网吧，拍视频都要签合同'。\n\n评论区笑翻了，但都是善意的。声望+15\n\n（另类出圈也是出圈）",
            effect = function() playerData_.reputation = playerData_.reputation + 15 end },
      },
      cond = function() return playerData_.day >= 10 and math.random(1, 100) <= 8 end,
    },
    { type = "choice", title = "国家队比赛日", icon = "🇲🇬",
      desc = "今天是马达加斯加国家队踢世界杯预选赛！全镇人都在找地方看球。\n\n你的网吧有大屏幕、有空调、有信号——但如果放球赛，跑刀的客人就没机器用了。\n\n门外已经聚了一群人举着啤酒等你开门。",
      choices = {
          { text = "⚽ 全场放球赛（停业看球）", result = "你把所有屏幕调成球赛直播。门口挤了六十多个人，Mama Blessing的啤酒卖脱销了。\n\n国家队居然赢了！全场陷入疯狂，有人把你扛起来绕了一圈。\n\n今天虽然没开网吧，但赚的比平时还多。\n\n💰+$120 声望+30",
            effect = function() playerData_.money = playerData_.money + 120; playerData_.reputation = playerData_.reputation + 30; playerData_.karma = playerData_.karma + 1 end },
          { text = "🖥️ 一半看球一半营业", result = "你把左边五台开球赛，右边五台继续跑刀。\n\n看球的嫌声音太小，跑刀的嫌太吵。两边都不满意。但你确实两头赚了。\n\n💰+$60 声望+5\n\n（折中方案：不会大赢也不会大输）",
            effect = function() playerData_.money = playerData_.money + 60; playerData_.reputation = playerData_.reputation + 5 end },
      },
      cond = function() return playerData_.day >= 7 and math.random(1, 100) <= 10 end,
    },
    { type = "choice", title = "铜线大盗", icon = "🔌",
      desc = "一早开门发现网吧外墙的电缆被人剪了！铜线被偷了十几米。没电缆就没网——今天开不了业了。\n\n隔壁杂货铺老板说他凌晨看到一个人影，像是住在河对岸的'铜线阿杰'。\n\n你攥着断掉的电缆头，气不打一处来。",
      choices = {
          { text = "🔧 自己买线重接（-$100）", result = "你花了半天时间重新拉线接线。虽然花了钱，但下午就恢复营业了。\n\n为了防止再次被偷，你还买了一把大锁锁住电表箱。\n\n💸-$100 损失半天收入 但设备安全了",
            effect = function() playerData_.money = playerData_.money - 100; playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 5) end },
          { text = "🕵️ 联合邻居蹲守抓贼", result = "你和隔壁几个店主轮流守夜。第三天凌晨，'铜线阿杰'果然来了——被你们逮个正着。\n\n警察来了，阿杰哭着说是因为女儿要上学没钱。你最终没追究，但条件是他帮你免费修了所有电线。\n\n⭐声望+20 karma+2（小镇处世之道）",
            effect = function() playerData_.reputation = playerData_.reputation + 20; playerData_.karma = playerData_.karma + 2; playerData_.money = playerData_.money - 30 end },
      },
      cond = function() return playerData_.day >= 8 and math.random(1, 100) <= 7 end,
    },
    { type = "choice", title = "Juju Man的祝福", icon = "🧿",
      desc = "一个穿着花袍、挂满珠串的老人走进网吧。所有人都安静了——这是镇上的Juju Man（巫医）。\n\n他走到你面前，从包里掏出一个小布袋：'中国人，我看你气运正旺。这个护身符，给你的店——保佑生意兴隆，百毒不侵。'\n\n'只要$80。不贵，跟你交个朋友。'他笑得很真诚，但你分不清这是迷信还是社交。",
      choices = {
          { text = "🧿 买下护身符（-$80）", result = "你收下护身符，挂在了收银台上方。\n\nJuju Man满意地离开了。Mama Blessing说：'不管信不信，有Juju Man给你的网吧开过光，以后没人敢来找事了。'\n\n果然接下来一周，什么坏事都没发生。\n\n💸-$80 声望+20 （心理安慰也是安慰）",
            effect = function() playerData_.money = playerData_.money - 80; playerData_.reputation = playerData_.reputation + 20; playerData_.karma = playerData_.karma + 1 end,
            cond = function() return playerData_.money >= 80 end },
          { text = "🙏 尊敬地拒绝", result = "你双手合十鞠了一躬：'谢谢您的好意，但我相信自己的双手。'\n\nJuju Man盯了你三秒，然后大笑：'好！我喜欢你这种人。'他拍了拍你的肩膀走了。\n\n什么都没发生。但你觉得今天的网特别快。\n\n（也许这就是非洲的安慰剂效应）",
            effect = function() playerData_.karma = playerData_.karma + 1 end },
      },
      cond = function() return playerData_.day >= 12 and math.random(1, 100) <= 6 end,
    },
    { type = "choice", title = "拆迁风声", icon = "🏗️",
      desc = "市政厅的人贴了个通知：你所在的街区被列入了'城市改造计划'。如果拆迁，网吧就得搬走。\n\n但通知上写着'征求意见阶段'，还没最终决定。隔壁老板已经在骂娘了：'每次选举前都来这一出！'\n\n你不确定这是真的还是虚张声势。",
      choices = {
          { text = "📝 组织商户联名反对", result = "你起草了一份请愿书，把整条街的店主都签了名。\n\n一周后市政厅回复：'鉴于商户意见，暂缓执行。'\n\n全街的人都来你网吧免费请你喝酒。你成了这条街的'话事人'。\n\n⭐声望+35 karma+2",
            effect = function() playerData_.reputation = playerData_.reputation + 35; playerData_.karma = playerData_.karma + 2 end },
          { text = "💰 私下找关系打听（-$120）", result = "你花钱请市政厅的人吃了顿饭。他酒后吐真言：'放心，选举前的把戏而已。谁也不会真拆——你们这条街的税收太重要了。'\n\n你悬着的心放下了。\n\n💸-$120 但你获得了信息差",
            effect = function() playerData_.money = playerData_.money - 120 end,
            cond = function() return playerData_.money >= 120 end },
      },
      cond = function() return playerData_.day >= 15 and math.random(1, 100) <= 6 end,
    },
    { type = "choice", title = "噪音投诉", icon = "📢",
      desc = "隔壁新搬来一对老夫妇。今天他们举着拐杖来投诉：'你们网吧太吵了！整晚都是砰砰砰的声音，我老伴心脏不好，被吓醒了三次！'\n\n你知道那是队员们凌晨跑刀撤离时的欢呼声……但老人家说得也有道理。",
      choices = {
          { text = "🔇 买隔音棉+规定23点后禁声（-$100）", result = "你花钱加了隔音棉，还立了'深夜静音规则'。\n\n老太太送来一盘自制曲奇饼：'中国小伙，谢谢你理解我们。'\n\n队员们虽然不太高兴，但理解了和邻居相处的道理。\n\n💸-$100 声望+25 karma+2",
            effect = function() playerData_.money = playerData_.money - 100; playerData_.reputation = playerData_.reputation + 25; playerData_.karma = playerData_.karma + 2 end,
            cond = function() return playerData_.money >= 100 end },
          { text = "🎧 给队员配耳机，不改时间", result = "你给所有机器配了耳机，要求深夜必须用耳机。\n\n问题解决了一半——键盘声还是有的，但至少没了欢呼声。老夫妇勉强接受了。\n\n💸-$30 （耳机费）",
            effect = function() playerData_.money = playerData_.money - 30; playerData_.reputation = playerData_.reputation + 5 end },
      },
      cond = function() return playerData_.day >= 9 and math.random(1, 100) <= 8 end,
    },
    { type = "choice", title = "丢失的冠军鸡", icon = "🏆🐔",
      desc = "Mama Blessing冲进来，眼眶通红：'我的冠军鸡Beyoncé不见了！她今天要参加镇上的选美鸡大赛的！奖金$500！'\n\n她桌上放着一张参赛证，上面写着Beyoncé的名字和照片——确实是一只非常漂亮的芦花鸡。\n\n'你能不能帮我找找？她可能跑去了废弃仓库那边！'",
      choices = {
          { text = "🔍 全队出动找鸡！（停业半天）", result = function()
              if playerData_._chickenFound then
                  return "你带着全队在废弃仓库翻了两小时，终于在一堆轮胎后面找到了Beyoncé——她正在孵一窝蛋。\n\nMama Blessing喜极而泣，抱着鸡跑去比赛。下午传来消息：Beyoncé拿了第二名！\n\n她把$100奖金分给了你：'谢谢你们救了我的Beyoncé！'\n\n💰+$100 声望+20 全队心情+8"
              else
                  return "找了半天也没找到。就在大家灰心丧气的时候，Beyoncé自己大摇大摆地从排水沟里走了出来，嘴里还叼着一条虫子。\n\n虽然错过了比赛时间，但至少鸡回来了。Mama Blessing又哭又笑地抱住了它。\n\n停业半天损失-$40 但心情+5"
              end
          end,
            effect = function()
              playerData_._chickenFound = math.random(1, 100) <= 70
              if playerData_._chickenFound then
                  playerData_.money = playerData_.money + 100; playerData_.reputation = playerData_.reputation + 20
                  for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 8) end
              else
                  playerData_.money = playerData_.money - 40
                  for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
              end
            end },
          { text = "🍗 帮不了……但请她喝杯茶冷静", result = "你递给Mama Blessing一杯茶：'别急，鸡有腿，会自己回来的。'\n\n她半信半疑地坐下来等。两小时后Beyoncé果然自己溜达回来了——但比赛已经结束了。\n\nMama Blessing叹了口气：'明年再来吧。'\n\n（稳妥选择：不赚不亏）",
            effect = function() playerData_.karma = playerData_.karma + 1 end },
      },
      cond = function() return playerData_.day >= 7 and math.random(1, 100) <= 9 end,
    },
}
