---@diagnostic disable: undefined-global

-- ============================================================================
-- 6.2 群聊事件表（代练工作室群消息 + 决策）
-- ============================================================================

--- 获取队伍中第一个成员名字（安全）
function FirstMemberName()
    if #teamMembers_ > 0 then return teamMembers_[1].name end
    return "员工"
end
--- 获取随机队员名字
function RandMemberName()
    if #teamMembers_ > 0 then return teamMembers_[math.random(#teamMembers_)].name end
    return "员工"
end

--- 获取两个不同的队员（用于冲突事件）
function TwoMembers()
    if #teamMembers_ < 2 then return nil, nil end
    local i = math.random(#teamMembers_)
    local j = i
    while j == i do j = math.random(#teamMembers_) end
    return teamMembers_[i], teamMembers_[j]
end

--- 按名字查找队员对象
function FindMember(name)
    for _, m in ipairs(teamMembers_) do
        if m.name == name then return m end
    end
    return nil
end

--- 群聊事件：每天 EndDay 时随机触发 1-3 条消息，部分带决策选项
CHAT_EVENTS = {
    -- ===== 日常闲聊（无决策，活跃气氛） =====
    { id = "chat_daily_food", weight = 10,
      msgs = function()
          local m = RandMemberName()
          return {{ sender = m, content = "老板，今天 Mama B 的烤鸡真的绝了🍗 吃撑了打瞌睡…" }}
      end,
    },
    { id = "chat_daily_lag", weight = 10,
      msgs = function()
          return {{ sender = RandMemberName(), content = "网又卡了……代练单子快超时了😤 能不能升级一下网速？" }}
      end,
    },
    { id = "chat_daily_mood", weight = 8,
      msgs = function()
          return {{ sender = RandMemberName(), content = "今天心情不错，感觉手速起飞✈️ 来几把排位！" }}
      end,
    },
    { id = "chat_daily_rival", weight = 6,
      cond = function() return playerData_.day >= 8 end,
      msgs = function()
          return {{ sender = RandMemberName(), content = "隔壁 Thunder Net 又在门口贴大字报说他们网速第一🙄" }}
      end,
    },
    { id = "chat_daily_electric", weight = 6,
      cond = function() return playerData_.day >= 5 end,
      msgs = function()
          return {{ sender = RandMemberName(), content = "又停电了💀 我手机也快没电了，有人带充电宝没？" }}
      end,
    },
    { id = "chat_daily_customer", weight = 8,
      msgs = function()
          return {
              { sender = RandMemberName(), content = "刚才有个小孩进来问能不能用50塞地上一小时网😂" },
              { sender = RandMemberName(), content = "哈哈哈 同意了吗？" },
          }
      end,
    },

    -- ===== ⚖️ 冲突仲裁事件（上帝视角：队员冲突，你来裁决） =====
    { id = "conflict_pc_fight", weight = 7,
      cond = function() return #teamMembers_ >= 2 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "凭什么你用1号机？我今天有代练单子要赶！🖥️" },
              { sender = b.name, content = "先来后到懂不懂？我早上就坐这了，你自己来晚怪谁？" },
              { sender = a.name, content = "你就在上面看视频！我是在工作！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 和 " .. b.name .. " 争抢1号机，互不相让",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 工作优先：有单子的先用", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 8); ma.skill = math.min(SKILL_CAP, ma.skill + 1) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 3) end
                      AddLog("⚖️ 仲裁：工作优先，" .. a.name .. " 获得1号机")
                      return a.name .. " 谢谢老板公正裁决！我一定把单子做好💪"
                  end },
                  { text = "🤝 轮流使用：每人2小时", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 3) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 3) end
                      playerData_.reputation = playerData_.reputation + 3
                      AddLog("⚖️ 仲裁：轮流使用，团队和谐+")
                      return "好吧，轮流就轮流。老板处理得挺公平的👍"
                  end },
                  { text = "🔨 都别争了！加钱买台新电脑", effect = function()
                      playerData_.money = playerData_.money - 150
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end
                      AddLog("⚖️ 仲裁：购入新电脑 -$150，全队满意")
                      return "新电脑！！老板大气！🎉🎉"
                  end },
              },
          }
      end,
    },
    { id = "conflict_blame_game", weight = 7,
      cond = function() return #teamMembers_ >= 2 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "上把比赛全是你的锅！关键团战你在干嘛？？😡" },
              { sender = b.name, content = "我的锅？？你自己走位像个铁憨憨还怪我？" },
              { sender = a.name, content = "你再说一遍？信不信我退队？" },
              { sender = b.name, content = "退就退！谁怕谁！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 和 " .. b.name .. " 因比赛失利互相甩锅，矛盾升级",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 复盘分析：调录像看谁的问题", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      if ma then ma.skill = math.min(SKILL_CAP, ma.skill + 2) end
                      if mb then mb.skill = math.min(SKILL_CAP, mb.skill + 2) end
                      AddLog("⚖️ 仲裁：复盘分析，双方技术+2")
                      return "看了回放……好吧两个人都有问题😅 不过学到了不少"
                  end },
                  { text = "🫂 各打五十大板：都罚洗厕所一天", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      if ma then ma.mood = math.max(0, ma.mood - 5) end
                      if mb then mb.mood = math.max(0, mb.mood - 5) end
                      playerData_.reputation = playerData_.reputation + 5
                      AddLog("⚖️ 仲裁：各打五十大板，团队纪律+")
                      return "好吧老板说得对……我们不该吵架😔 下次注意"
                  end },
                  { text = "🔥 让他们用1v1决胜负", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      local aWin = math.random() < 0.5
                      if aWin then
                          if ma then ma.mood = math.min(100, ma.mood + 10); ma.skill = math.min(SKILL_CAP, ma.skill + 1) end
                          if mb then mb.mood = math.max(0, mb.mood - 3) end
                          return a.name .. " 赢了1v1！技术说话，口服心服⚔️"
                      else
                          if mb then mb.mood = math.min(100, mb.mood + 10); mb.skill = math.min(SKILL_CAP, mb.skill + 1) end
                          if ma then ma.mood = math.max(0, ma.mood - 3) end
                          return b.name .. " 赢了1v1！技术说话，口服心服⚔️"
                      end
                  end },
              },
          }
      end,
    },
    { id = "conflict_food_theft", weight = 6,
      cond = function() return #teamMembers_ >= 2 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "谁吃了我放冰箱里的Jollof饭？？？🍚😤" },
              { sender = b.name, content = "……不是我" },
              { sender = a.name, content = "冰箱里只有你的指纹！你嘴边还有米粒！" },
              { sender = b.name, content = "好吧是我吃的……但我真的太饿了😓" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. b.name .. " 偷吃了 " .. a.name .. " 的午餐，" .. a.name .. " 很生气",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 赔偿：偷吃的人请对方吃一顿", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      if ma then ma.mood = math.min(100, ma.mood + 8) end
                      if mb then mb.mood = math.max(0, mb.mood - 2) end
                      AddLog("⚖️ 仲裁：" .. b.name .. " 请 " .. a.name .. " 吃饭赔罪")
                      return b.name .. "：行行行我请客！去Mama B那吃烤鸡🍗"
                  end },
                  { text = "🍱 制度化：以后午餐统一订餐，费用AA", effect = function()
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 3) end
                      playerData_.money = playerData_.money - 30
                      AddLog("⚖️ 仲裁：建立团餐制度 -$30，团队凝聚力+")
                      return "统一订餐好！再也不用担心午饭被偷了😂"
                  end },
                  { text = "😄 算了，都是小事别伤和气", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 5) end
                      return a.name .. "：哼……算了算了，下不为例啊！😤"
                  end },
              },
          }
      end,
    },
    { id = "conflict_music_noise", weight = 6,
      cond = function() return #teamMembers_ >= 2 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "🎵🎵🎵 这歌太嗨了！音量拉满！" },
              { sender = b.name, content = "能不能小声点？？我在打排位！！快聋了！！🔇" },
              { sender = a.name, content = "戴耳机啊？音乐是灵魂！听着才有手感！" },
              { sender = b.name, content = "你的灵魂快把我的排位搞崩了！！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 外放音乐影响 " .. b.name .. " 打比赛",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 规定：工作时间必须戴耳机", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 3) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 5); mb.skill = math.min(SKILL_CAP, mb.skill + 1) end
                      playerData_.reputation = playerData_.reputation + 3
                      AddLog("⚖️ 仲裁：制定耳机规则，工作环境改善")
                      return "好吧好吧……戴耳机就戴耳机🎧"
                  end },
                  { text = "🎵 设立公放时段：午休时间可以放歌", effect = function()
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 4) end
                      AddLog("⚖️ 仲裁：午休公放音乐，氛围+")
                      return "午休放歌不错！大家一起嗨一下也好🎶"
                  end },
              },
          }
      end,
    },
    { id = "conflict_role_dispute", weight = 5,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 5 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "下场比赛我要打C位！我的数据最好！📊" },
              { sender = b.name, content = "凭什么？C位一直是我的！你去打辅助！" },
              { sender = a.name, content = "你最近状态下滑了，数据不会说谎" },
              { sender = b.name, content = "一场发挥不好就要换人？你也太狠了吧" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 和 " .. b.name .. " 争夺比赛C位",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 用数据说话：近3场表现好的上", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      if ma and mb then
                          if (ma.skill or 0) >= (mb.skill or 0) then
                              ma.mood = math.min(100, ma.mood + 10)
                              mb.mood = math.max(0, mb.mood - 5)
                              mb.skill = math.min(SKILL_CAP, mb.skill + 2)  -- 化压力为动力
                              return a.name .. " 数据更好，暂时打C位。" .. b.name .. "：我会努力追上的！💪"
                          else
                              mb.mood = math.min(100, mb.mood + 10)
                              ma.mood = math.max(0, ma.mood - 5)
                              ma.skill = math.min(SKILL_CAP, ma.skill + 2)
                              return b.name .. " 数据更好，继续打C位。" .. a.name .. "：下次看我的！"
                          end
                      end
                      return "数据说了算，大家心服口服"
                  end },
                  { text = "🔄 轮换制：交替上场，互相学习", effect = function()
                      local ma = FindMember(a.name)
                      local mb = FindMember(b.name)
                      if ma then ma.skill = math.min(SKILL_CAP, ma.skill + 1); ma.mood = math.min(100, ma.mood + 3) end
                      if mb then mb.skill = math.min(SKILL_CAP, mb.skill + 1); mb.mood = math.min(100, mb.mood + 3) end
                      AddLog("⚖️ 仲裁：C位轮换制，双方技术+1")
                      return "轮换也行，互相学习取长补短📖"
                  end },
              },
          }
      end,
    },
    { id = "conflict_lazy_accuse", weight = 5,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 7 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "老板你看看 " .. b.name .. "！训练时间在那刷手机📱" },
              { sender = b.name, content = "我刚打完三把好吗！休息一下不行？" },
              { sender = a.name, content = "休息？我都没休息你凭什么休息！大家工作量要一样！" },
              { sender = b.name, content = "你是工作狂你的标准别强加给我好吧？？" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 指责 " .. b.name .. " 偷懒，引发工作态度争议",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 制定排班表：明确工作和休息时间", effect = function()
                      for _, m in ipairs(teamMembers_) do
                          m.mood = math.min(100, m.mood + 3)
                          m.skill = math.min(SKILL_CAP, m.skill + 1)
                      end
                      playerData_.reputation = playerData_.reputation + 3
                      AddLog("⚖️ 仲裁：制定排班表，工作效率提升")
                      return "有了排班表就清楚了，该干活干活该休息休息📋"
                  end },
                  { text = "💪 鼓励勤奋：奖励 " .. a.name .. " 额外奖金", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 12); ma.skill = math.min(SKILL_CAP, ma.skill + 2) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 8) end
                      playerData_.money = playerData_.money - 50
                      AddLog("⚖️ 仲裁：奖励勤奋者 -$50")
                      return a.name .. "：谢谢老板认可！ " .. b.name .. "：……我也会努力的"
                  end },
                  { text = "🧘 劳逸结合：适当休息才能保持状态", effect = function()
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 8) end
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 3) end
                      AddLog("⚖️ 仲裁：提倡劳逸结合")
                      return b.name .. "：老板英明！适当休息效率更高～"
                  end },
              },
          }
      end,
    },
    { id = "conflict_prize_split", weight = 4,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 10 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "上次比赛奖金怎么分的？我MVP为什么和别人一样？🏆" },
              { sender = b.name, content = "团队比赛当然平分啊！没有我们你能赢？" },
              { sender = a.name, content = "可是我carry了全场！应该多分一点！" },
              { sender = b.name, content = "那我辅助拉了多少视野你知道吗？没有功劳也有苦劳！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 要求按贡献分奖金，" .. b.name .. " 坚持平分",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 绩效制：MVP多拿20%，其余平分", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 10); ma.skill = math.min(SKILL_CAP, ma.skill + 2) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 5) end
                      playerData_.money = playerData_.money + 30
                      AddLog("⚖️ 仲裁：建立绩效分配制度，激励竞争")
                      return "绩效制公平！以后大家都有动力打好每场比赛🔥"
                  end },
                  { text = "🤝 坚持平分：团队精神最重要", effect = function()
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 8) end
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 3) end
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 2) end
                      AddLog("⚖️ 仲裁：坚持平分，团队凝聚力+")
                      return "平分就平分吧，团队第一！不过MVP还是要认可的哦"
                  end },
                  { text = "💡 混合制：基础平分 + MVP额外奖励从公账出", effect = function()
                      for _, m in ipairs(teamMembers_) do
                          m.mood = math.min(100, m.mood + 5)
                          m.skill = math.min(SKILL_CAP, m.skill + 1)
                      end
                      playerData_.money = playerData_.money - 40
                      AddLog("⚖️ 仲裁：混合分配制 -$40，全队满意")
                      return "这个方案好！既公平又有激励，老板思路清晰👏"
                  end },
              },
          }
      end,
    },
    { id = "conflict_borrow_gear", weight = 5,
      cond = function() return #teamMembers_ >= 2 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = b.name .. "！！你又用我的耳机！！还弄脏了！！🎧" },
              { sender = b.name, content = "我就借一下嘛……我的耳机坏了" },
              { sender = a.name, content = "借了多少次了？每次都不说一声直接拿！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. b.name .. " 多次未经允许使用 " .. a.name .. " 的外设",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 买新耳机给 " .. b.name .. "，解决根源", effect = function()
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 12); mb.skill = math.min(SKILL_CAP, mb.skill + 1) end
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 5) end
                      playerData_.money = playerData_.money - 60
                      AddLog("⚖️ 仲裁：购买新耳机 -$60，纠纷解决")
                      return "新耳机！谢谢老板🎧 再也不用借别人的了"
                  end },
                  { text = "📋 立规矩：私人物品未经允许不可使用", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 8) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 3) end
                      playerData_.reputation = playerData_.reputation + 2
                      AddLog("⚖️ 仲裁：制定物品使用规范")
                      return b.name .. "：好吧对不起……以后先问一声"
                  end },
              },
          }
      end,
    },
    { id = "conflict_night_shift", weight = 5,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 8 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "今晚谁值夜班？反正不是我，我连续值了三天了😴" },
              { sender = b.name, content = "别看我！我昨晚也值了！该轮到别人了" },
              { sender = a.name, content = "那谁来？总不能没人看店吧" },
              { sender = b.name, content = "要不找老板决定？不然每次都是我们吃亏" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 和 " .. b.name .. " 都不想值夜班，推来推去",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚖️ 排班表轮值：每人固定夜班日", effect = function()
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 3) end
                      playerData_.reputation = playerData_.reputation + 5
                      AddLog("⚖️ 仲裁：建立夜班轮值制度")
                      return "有排班表就不用每次争了，清清楚楚📋"
                  end },
                  { text = "💰 夜班补贴：值夜加 $20", effect = function()
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 6) end
                      playerData_.money = playerData_.money - 40
                      AddLog("⚖️ 仲裁：夜班补贴制度 -$40")
                      return "有补贴就不一样了！今晚我来值😎💰"
                  end },
                  { text = "🤖 装监控：夜间无人值守", effect = function()
                      playerData_.money = playerData_.money - 100
                      playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 80) + 10)
                      for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 8) end
                      AddLog("⚖️ 仲裁：安装监控 -$100，无需值夜班")
                      return "有监控就不用值夜了！！老板英明！🎉"
                  end },
              },
          }
      end,
    },
    { id = "conflict_strategy", weight = 5,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 6 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "下场比赛应该打进攻！速战速决！⚔️" },
              { sender = b.name, content = "不行！应该稳住防守，等对面犯错！🛡️" },
              { sender = a.name, content = "龟缩战术太无聊了，观众也不爱看" },
              { sender = b.name, content = "赢比赛重要还是好看重要？你说！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 主张进攻，" .. b.name .. " 主张防守，战术分歧",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "⚔️ 支持进攻：高风险高回报", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 10); ma.skill = math.min(SKILL_CAP, ma.skill + 2) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 3) end
                      AddLog("⚖️ 仲裁：采纳进攻战术")
                      return a.name .. "：冲就完事了！🔥 " .. b.name .. "：希望别翻车……"
                  end },
                  { text = "🛡️ 支持防守：稳中求胜", effect = function()
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 10); mb.skill = math.min(SKILL_CAP, mb.skill + 2) end
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 3) end
                      AddLog("⚖️ 仲裁：采纳防守战术")
                      return b.name .. "：稳住就能赢！ " .. a.name .. "：好吧试试你的方案"
                  end },
                  { text = "🧠 融合战术：前期防守，中期转攻", effect = function()
                      for _, m in ipairs(teamMembers_) do
                          m.skill = math.min(SKILL_CAP, m.skill + 1)
                          m.mood = math.min(100, m.mood + 5)
                      end
                      AddLog("⚖️ 仲裁：融合战术，全队技术+1")
                      return "老板这个思路牛！攻守兼备才是最强的💡"
                  end },
              },
          }
      end,
    },
    { id = "conflict_newcomer", weight = 4,
      cond = function() return #teamMembers_ >= 3 and playerData_.day >= 10 end,
      msgs = function()
          local oldM = teamMembers_[1]  -- 老成员
          local newM = teamMembers_[#teamMembers_]  -- 最新成员
          return {
              { sender = newM.name, content = "老板……" .. oldM.name .. " 总是让我端茶倒水，还说是'传统'😢" },
              { sender = oldM.name, content = "我们当年也是这么过来的！新人就该多跑腿！" },
              { sender = newM.name, content = "可是我来这里是打比赛的，不是当保姆的……" },
          }
      end,
      decision = function()
          local oldM = teamMembers_[1]
          local newM = teamMembers_[#teamMembers_]
          return {
              question = "⚖️ " .. oldM.name .. " 给新人 " .. newM.name .. " 立规矩，新人感到受欺负",
              conflictParties = { oldM.name, newM.name },
              options = {
                  { text = "⚖️ 废除陋习：所有人平等对待", effect = function()
                      local mn = FindMember(newM.name)
                      if mn then mn.mood = math.min(100, mn.mood + 15); mn.skill = math.min(SKILL_CAP, mn.skill + 2) end
                      local mo = FindMember(oldM.name)
                      if mo then mo.mood = math.max(0, mo.mood - 5) end
                      playerData_.reputation = playerData_.reputation + 5
                      AddLog("⚖️ 仲裁：废除新人陋习，团队平等")
                      return newM.name .. "：谢谢老板！我会用实力证明自己的💪"
                  end },
                  { text = "🤝 折中：新人负责卫生，但不用伺候个人", effect = function()
                      local mn = FindMember(newM.name)
                      if mn then mn.mood = math.min(100, mn.mood + 5) end
                      local mo = FindMember(oldM.name)
                      if mo then mo.mood = math.min(100, mo.mood + 3) end
                      AddLog("⚖️ 仲裁：新人分担卫生，私事自理")
                      return "这样还行，大家都能接受。公共卫生轮流做嘛"
                  end },
                  { text = "🏋️ 师徒制：老带新，但要真的教技术", effect = function()
                      local mn = FindMember(newM.name)
                      local mo = FindMember(oldM.name)
                      if mn then mn.skill = math.min(SKILL_CAP, mn.skill + 3); mn.mood = math.min(100, mn.mood + 10) end
                      if mo then mo.mood = math.min(100, mo.mood + 5); mo.skill = math.min(SKILL_CAP, mo.skill + 1) end
                      AddLog("⚖️ 仲裁：建立师徒制，新人技术+3")
                      return oldM.name .. "：好！那我就认真带你！ " .. newM.name .. "：师父好！🙏"
                  end },
              },
          }
      end,
    },
    { id = "conflict_stream_privacy", weight = 4,
      cond = function() return #teamMembers_ >= 2 and playerData_.day >= 12 end,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = a.name, content = "我想直播我们的训练赛！涨粉丝赚打赏📱💰" },
              { sender = b.name, content = "不行！！你要把我们的战术暴露给对手？？🙅" },
              { sender = a.name, content = "不至于吧……直播能增加曝光度" },
              { sender = b.name, content = "曝光度有什么用？比赛输了才是真亏！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 想直播训练，" .. b.name .. " 担心泄露战术",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "📺 允许直播日常，比赛战术保密", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 8) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 3) end
                      playerData_.reputation = playerData_.reputation + 8
                      playerData_.money = playerData_.money + 50
                      AddLog("⚖️ 仲裁：日常直播，战术保密，声望+ 收入+$50")
                      return "直播日常互动涨了不少粉！战术部分打码处理🔒"
                  end },
                  { text = "🚫 禁止直播：团队机密优先", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 8) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 5) end
                      AddLog("⚖️ 仲裁：禁止直播，保护战术")
                      return a.name .. "：好吧……可惜了那些粉丝😞"
                  end },
              },
          }
      end,
    },
    { id = "conflict_captain", weight = 3,
      cond = function() return #teamMembers_ >= 3 and playerData_.day >= 15 end,
      once = true,
      msgs = function()
          local a, b = TwoMembers()
          if not a then return {} end
          return {
              { sender = "系统消息", content = "⚖️ 队内出现领导权争议", isSystem = true },
              { sender = a.name, content = "我觉得我们需要一个队长，我自荐！我经验最丰富！👑" },
              { sender = b.name, content = "队长？凭什么是你？我战绩比你好！应该选我！" },
              { sender = a.name, content = "战绩好就能当队长？领导力更重要！" },
              { sender = b.name, content = "那就让老板决定！谁更适合当队长！" },
          }
      end,
      decision = function()
          local a, b = TwoMembers()
          if not a then return nil end
          return {
              question = "⚖️ " .. a.name .. " 和 " .. b.name .. " 都想当队长，请你裁决",
              conflictParties = { a.name, b.name },
              options = {
                  { text = "👑 任命 " .. a.name .. " 为队长", effect = function()
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.min(100, ma.mood + 15); ma.skill = math.min(SKILL_CAP, ma.skill + 3) end
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.max(0, mb.mood - 8); mb.skill = math.min(SKILL_CAP, mb.skill + 1) end
                      AddLog("⚖️ 仲裁：任命 " .. a.name .. " 为队长")
                      return a.name .. "：感谢老板信任！我一定带好团队！ " .. b.name .. "：……行吧，我做好我的就是了"
                  end },
                  { text = "👑 任命 " .. b.name .. " 为队长", effect = function()
                      local mb = FindMember(b.name)
                      if mb then mb.mood = math.min(100, mb.mood + 15); mb.skill = math.min(SKILL_CAP, mb.skill + 3) end
                      local ma = FindMember(a.name)
                      if ma then ma.mood = math.max(0, ma.mood - 8); ma.skill = math.min(SKILL_CAP, ma.skill + 1) end
                      AddLog("⚖️ 仲裁：任命 " .. b.name .. " 为队长")
                      return b.name .. "：老板放心！我不会让大家失望！ " .. a.name .. "：好吧，希望你能服众"
                  end },
                  { text = "🏛️ 民主投票：全队匿名选举", effect = function()
                      for _, m in ipairs(teamMembers_) do
                          m.mood = math.min(100, m.mood + 5)
                          m.skill = math.min(SKILL_CAP, m.skill + 1)
                      end
                      playerData_.reputation = playerData_.reputation + 8
                      AddLog("⚖️ 仲裁：民主选举队长，团队凝聚力大增")
                      return "投票结果出来了！大家都服气，这才是真正的队长👑"
                  end },
              },
          }
      end,
    },

    -- ===== 氛围消息（纯闲聊，高频） =====
    { id = "chat_vibe_gg", weight = 12,
      msgs = function()
          return {{ sender = RandMemberName(), content = "GG！刚刚那把打得漂亮🔥" }}
      end,
    },
    { id = "chat_vibe_sleepy", weight = 8,
      msgs = function()
          return {{ sender = RandMemberName(), content = "好困……☕谁去买杯咖啡？我请客" }}
      end,
    },
    { id = "chat_vibe_music", weight = 8,
      msgs = function()
          return {
              { sender = RandMemberName(), content = "🎵 放首歌提提神吧" },
              { sender = RandMemberName(), content = "别放了上次你放的歌客户都跑了😂" },
          }
      end,
    },
    { id = "chat_vibe_payday", weight = 6,
      cond = function() return playerData_.day % 7 == 0 end,
      msgs = function()
          return {{ sender = RandMemberName(), content = "今天发工资吗老板？👀💰" }}
      end,
    },
}

--- 添加群聊消息（带未读计数和天数标记）
function AddChatMsg(sender, content, isSelf, isSystem)
    table.insert(chatMessages_, {
        sender = sender or "系统",
        content = content or "",
        isSelf = isSelf or false,
        isSystem = isSystem or false,
        day = playerData_.day,
    })
    -- 保留最近 200 条
    while #chatMessages_ > 200 do table.remove(chatMessages_, 1) end
    -- 非自己发的消息 + 不在群聊 Tab → 增加未读
    if not isSelf and manageTab_ ~= "group" then
        chatUnread_ = chatUnread_ + 1
    end
end

--- 按权重随机选取群聊事件（支持条件过滤和 once 标记）
function PickChatEvents(count)
    -- 筛选可用事件
    local pool = {}
    local totalWeight = 0
    for _, evt in ipairs(CHAT_EVENTS) do
        local condOk = (not evt.cond) or evt.cond()
        local onceOk = (not evt.once) or (not chatEventTriggered_[evt.id])
        if condOk and onceOk then
            table.insert(pool, evt)
            totalWeight = totalWeight + (evt.weight or 5)
        end
    end
    if #pool == 0 then return {} end

    -- 加权随机抽取（不重复）
    local picked = {}
    for _ = 1, math.min(count, #pool) do
        local r = math.random() * totalWeight
        local acc = 0
        for j, evt in ipairs(pool) do
            acc = acc + (evt.weight or 5)
            if r <= acc then
                table.insert(picked, evt)
                totalWeight = totalWeight - (evt.weight or 5)
                table.remove(pool, j)
                break
            end
        end
    end
    return picked
end

-- ============================================================================
-- 6.4 自主聊天系统（员工间自由对话，组合式生成）
-- ============================================================================

--- 模板占位符替换工具
local function ResolveTemplate(tpl, vars)
    if not vars then return tpl end
    return (tpl:gsub("{(%w+)}", function(key)
        local options = vars[key]
        if options and #options > 0 then
            return options[math.random(#options)]
        end
        return "{" .. key .. "}"
    end))
end

--- 注入游戏实时数据
local function InjectGameState(text)
    text = text:gsub("{MONEY}", tostring(playerData_.money))
    text = text:gsub("{DAY}", tostring(playerData_.day))
    text = text:gsub("{REP}", tostring(playerData_.reputation))
    text = text:gsub("{EQUIP}", tostring(playerData_.equipCondition or 100))
    text = text:gsub("{MEMBERS}", tostring(#teamMembers_))
    if #teamMembers_ > 0 then
        text = text:gsub("{RANDNAME}", teamMembers_[math.random(#teamMembers_)].name)
    else
        text = text:gsub("{RANDNAME}", "队员")
    end
    return text
end

--- 按话题匹配性格选发言人
local function PickSpeaker(topic, excludeNames)
    excludeNames = excludeNames or {}
    local candidates = {}
    for _, m in ipairs(teamMembers_) do
        if not excludeNames[m.name] then
            local profile = CHAR_CHAT_PROFILES and CHAR_CHAT_PROFILES[m.name]
            local match = false
            if profile then
                for _, t in ipairs(profile.topics or {}) do
                    if t == topic then match = true; break end
                end
            end
            table.insert(candidates, { name = m.name, w = match and 3 or 1 })
        end
    end
    if #candidates == 0 then return RandMemberName() end
    local total = 0
    for _, c in ipairs(candidates) do total = total + c.w end
    local r = math.random() * total
    local acc = 0
    for _, c in ipairs(candidates) do
        acc = acc + c.w
        if r <= acc then return c.name end
    end
    return candidates[1].name
end

-- 角色聊天性格表
CHAR_CHAT_PROFILES = {
    ["Kofi"] = {
        chatStyle = "energetic",
        topics = { "speed", "cycling", "money", "mama", "football" },
        catchphrases = { "速度就是一切💨", "骑车12公里来的我不累谁累", "Mama说我迟早出人头地" },
        moodHigh = { "今天状态爆表🔥冲！", "手感来了挡都挡不住！" },
        moodLow = { "唉今天腿酸，骑车来的……", "有点累了，想回去睡觉" },
    },
    ["Big Joe"] = {
        chatStyle = "calm",
        topics = { "food", "strength", "bodyguard", "jollof" },
        catchphrases = { "稳住别慌", "先吃饱再说", "保护队友是我的本能" },
        moodHigh = { "今天吃得饱，手感稳👍", "状态不错，稳如磐石" },
        moodLow = { "饿了……没力气打", "今天手有点抖，是不是该吃点东西" },
    },
    ["Grace"] = {
        chatStyle = "gentle",
        topics = { "church", "prayer", "precision", "singing" },
        catchphrases = { "上帝保佑我们赢", "每一枪都是祈祷🙏", "唱诗班教会我专注" },
        moodHigh = { "今天心情很平静，可以专注打比赛", "周日去了教堂，现在状态很好" },
        moodLow = { "父亲知道我来网吧的话……", "有点不安，要不先祷告一下" },
    },
    ["Snake"] = {
        chatStyle = "aggressive",
        topics = { "street", "fight", "respect", "territory" },
        catchphrases = { "在街上混五年没白混", "别惹我就好", "游戏里杀人比街上干净" },
        moodHigh = { "今天谁都别想赢我🐍", "手感滚烫！全给我冲！" },
        moodLow = { "烦死了……再输我要摔鼠标", "别跟我说话，心情不好" },
    },
    ["Mama B"] = {
        chatStyle = "maternal",
        topics = { "food", "cooking", "chicken", "market", "children" },
        catchphrases = { "烤鸡快好了，谁要来一块？🍗", "年轻人啊，先吃饱再打", "我这把老骨头还能打" },
        moodHigh = { "今天鸡卖得好，心情也好", "年纪大了但手还稳💪" },
        moodLow = { "腰有点疼……年纪大了", "今天市场没什么人，唉" },
    },
    ["Prince"] = {
        chatStyle = "dramatic",
        topics = { "honor", "chief", "royalty", "money", "glory" },
        catchphrases = { "我要靠自己赢得荣耀👑", "别以为我只会花钱", "酋长之子不是白叫的" },
        moodHigh = { "今天感觉自己就是王！", "父亲会为我骄傲的" },
        moodLow = { "又输了……父亲肯定会笑我", "为什么大家不听我指挥？" },
    },
    ["小雪"] = {
        chatStyle = "warm",
        topics = { "teaching", "chinese", "children", "culture", "sichuan" },
        catchphrases = { "大家加油哦～", "在这里比在大城市快乐多了", "今天教孩子们说了'你好'" },
        moodHigh = { "今天学生们都很认真，心情好～", "这里的日落真的好美" },
        moodLow = { "有点想家了……想吃火锅", "支教合同快到期了，不知道要不要续……" },
    },
    ["Thunder"] = {
        chatStyle = "intense",
        topics = { "speed", "sprint", "reflex", "competition" },
        catchphrases = { "0.1秒决定胜负⚡", "在跑道上学的反应，鼠标上用", "速度是我唯一的武器" },
        moodHigh = { "手腕不疼了！今天要爆发🔥", "跑道上退役但这里我还是最快的" },
        moodLow = { "手腕又疼了……旧伤复发", "今天反应有点慢，不舒服" },
    },
}

-- 独白模板（含非洲本地文化内容）
SOLO_CHAT_TEMPLATES = {
    -- ====== 日常闲聊 ======
    general = {
        { tpl = "刚打完一把{game}，{result}", vars = {
            game = { "排位", "匹配", "代练单", "训练赛" },
            result = { "还行吧", "差点翻车😅", "轻松拿下💪", "队友带不动……" },
        }},
        { tpl = "{time}了，{wish}", vars = {
            time = { "快下班", "中午", "该吃饭" },
            wish = { "谁去买饮料？", "Mama B的烤鸡还有吗？", "好困想睡觉😴", "要不要一起出去走走" },
        }},
        { tpl = "刚才有个客人{action}，笑死我了😂", vars = {
            action = { "用鼠标垫扇蚊子", "把键盘当枕头睡着了", "对着屏幕说'我要举报你'", "问能不能充电话费", "戴着耳机在唱歌", "偷偷在看TikTok" },
        }},
        { tpl = "有人知道{question}吗？", vars = {
            question = { "晚上哪里有好吃的", "明天几点开门", "隔壁网吧关门没", "Wi-Fi密码改了没", "今天谁值班" },
        }},
        { tpl = "{feeling}，今天{reason}", vars = {
            feeling = { "有点开心", "挺无聊的", "心情不错", "有点烦" },
            reason = { "客人还挺多", "没什么事做", "打了几个好局", "网又卡了一会儿" },
        }},
        { tpl = "你们说{topic}怎么样？", vars = {
            topic = { "咱们队名", "下次比赛的战术", "要不要搞个队服", "今天的训练强度" },
        }},
        { tpl = "刚刚{who}在门口{event}", vars = {
            who = { "一个小孩", "隔壁大爷", "Kwame", "一个骑摩托的" },
            event = { "探头看了半天", "问能不能借厕所", "送了几个芒果🥭", "说要来上网" },
        }},
        { tpl = "谁把{item}放{place}了？{reaction}", vars = {
            item = { "我的水杯", "鼠标线", "充电器", "耳机", "零食" },
            place = { "键盘上", "椅子底下", "我位置上", "窗台上" },
            reaction = { "还给我！", "差点踩到", "找半天了……", "别乱放好不好" },
        }},
    },
    -- ====== 非洲文化·日常生活 ======
    africa_life = {
        { tpl = "外面{weather}，{reaction}", vars = {
            weather = { "太阳大得吓人☀️", "下暴雨了🌧️", "尘土飞扬", "闷热得要命", "刮风了" },
            reaction = { "空调能开大点不", "路上全是泥，客人估计来不了", "衣服还晾在外面呢！", "幸好网吧里有风扇", "门都快被吹开了" },
        }},
        { tpl = "刚才去{place}，{story}", vars = {
            place = { "市场", "水井", "Mama B摊子", "路口杂货店", "教堂旁边" },
            story = { "看到好多人在排队", "物价又涨了😤", "买了点木薯回来", "碰到一群小孩在踢球", "摩托车差点撞到我" },
        }},
        { tpl = "今天{event}，整条街都{reaction}", vars = {
            event = { "有人结婚", "有个葬礼", "村长开会", "来了一辆大巴", "停水了" },
            reaction = { "热闹得很", "去看热闹了", "在放音乐🎵", "堵住了", "去邻居家打水" },
        }},
        { tpl = "昨晚{place}的发电机{status}，{comment}", vars = {
            place = { "隔壁", "街对面", "教堂", "学校", "市场" },
            status = { "又坏了", "声音超大", "漏油了", "冒黑烟", "终于修好了" },
            comment = { "吵得睡不着", "闻着都头疼", "这质量不行啊", "还好我们有太阳能", "他们还不如来我们这上网" },
        }},
        { tpl = "你们{seen}吗？{reaction}", vars = {
            seen = { "看昨晚的非洲杯了", "听说隔壁村通网了", "知道集市搬地方了", "看到那个新来的Okada司机了" },
            reaction = { "尼日利亚队踢得太烂了😩", "我们终于不是最偏僻的了", "以后买东西要走更远了", "骑得飞快差点撞电线杆" },
        }},
        { tpl = "{food}真的太好吃了{emoji}", vars = {
            food = { "Mama B的烤鸡", "Jollof饭", "木薯粉配花生汤", "烤玉米", "炸大蕉", "Suya烤肉串", "棕榈酒配烤鱼" },
            emoji = { "🍗", "🔥", "😋", "🤤", "👨‍🍳" },
        }},
        { tpl = "非洲的{thing}真是{adj}，{comment}", vars = {
            thing = { "太阳", "蚊子", "路", "暴雨", "星空", "音乐" },
            adj = { "太猛了", "受不了", "有个性", "让人无语", "太美了", "太有节奏感了" },
            comment = { "出门五分钟衣服就湿透", "蚊帐都挡不住", "坑能吞掉一辆摩托", "一下就半小时然后又大晴天", "城里根本看不到", "忍不住跟着跳舞💃" },
        }},
        { tpl = "{person}刚才说{quote}，笑死了😂", vars = {
            person = { "门口那个大叔", "来上网的小孩", "Okada司机", "卖水果的大婶" },
            quote = { "'这个Wi-Fi比我家的水还不稳定'", "'你们网吧有空调？我住这行不行'", "'我儿子在这上网成绩提高了因为他开始用英语骂人了'", "'你们这电脑比我的摩托还值钱'" },
        }},
    },
    -- ====== 非洲文化·节日传统 ======
    africa_culture = {
        { tpl = "快到{festival}了，{plan}", vars = {
            festival = { "丰收节", "部落祭典", "独立日", "开斋节", "圣诞节", "新薯节" },
            plan = { "要不要搞个活动？", "店里要不要装饰一下", "那天客人肯定特别多", "放假吗老板？", "我要回村里一趟" },
        }},
        { tpl = "我{relative}说{wisdom}，觉得{reaction}", vars = {
            relative = { "奶奶", "外婆", "村里长老", "妈妈", "酋长叔叔" },
            wisdom = { "'年轻人要像棕榈树一样有韧性'", "'团结的蚂蚁能搬走大象'", "'路再远也有尽头'", "'雨季之后就是丰收'", "'一个人走得快但一群人走得远'" },
            reaction = { "挺有道理的", "老人家说话就是有水平", "但我觉得速度更重要啊", "这不就是说我们队吗", "准备写在店里的墙上" },
        }},
        { tpl = "今天有人在{place}跳{dance}，{comment}", vars = {
            place = { "街上", "市场口", "教堂门口", "河边", "学校操场" },
            dance = { "Azonto", "Shaku Shaku", "传统祭祀舞", "丰收舞", "婚礼舞" },
            comment = { "节奏太上头了🎶", "我差点也跳进去", "Big Joe居然也会跳", "非洲的舞步真是有灵魂", "他们跳了一下午不累吗" },
        }},
        { tpl = "你们{question}？", vars = {
            question = { "家乡有什么特别的传统", "过节都吃什么", "小时候最喜欢什么节日", "觉得咱们镇上最有意思的是什么", "信什么教" },
        }},
    },
    -- ====== 装备吐槽 ======
    equipment = {
        { tpl = "{num}号机的{part}又{problem}了，{reaction}", vars = {
            num = { "1", "2", "3", "4", "5" },
            part = { "鼠标", "键盘", "显示器", "耳机", "椅子" },
            problem = { "坏", "卡", "飘", "没反应", "松了" },
            reaction = { "能修修吗？", "客户都在抱怨了😫", "我先凑合用吧", "老板该换新的了" },
        }},
        { tpl = "这个{item}的{issue}，{comment}", vars = {
            item = { "鼠标", "键盘", "屏幕", "音响", "网线" },
            issue = { "反应太慢", "按键不灵", "闪屏", "有杂音", "接触不良" },
            comment = { "打比赛会吃亏的", "客人走了好几个", "拍一下又好了", "是不是蟑螂咬的" },
        }},
        { tpl = "隔壁Gold Net换了{item}，{feeling}", vars = {
            item = { "全新电脑", "机械键盘", "144Hz显示器", "电竞椅" },
            feeling = { "我们也该升级了吧", "看着好眼馋……", "但他们技术不行有什么用", "咱们先靠实力说话💪" },
        }},
    },
    -- ====== 经济话题 ======
    money = {
        { tpl = "老板最近生意{status}，{comment}", vars = {
            status = { "还行", "有点淡", "不错", "一般般" },
            comment = { "能不能加点零食福利", "是不是该搞活动了", "我的奖金什么时候发", "大家省着点花吧" },
        }},
        { tpl = "听说{rival}的{item}要{price}，{reaction}", vars = {
            rival = { "Gold Net", "对面网吧", "街尾那家" },
            item = { "上网费", "会员价", "包夜价" },
            price = { "涨价了", "降价了", "打折了" },
            reaction = { "我们跟不跟？", "不用管他们", "咱走质量路线", "那不是恶性竞争吗" },
        }},
    },
    -- ====== 名气话题 ======
    reputation = {
        { tpl = "有人在{platform}上说我们{comment}，{reaction}", vars = {
            platform = { "TikTok", "Facebook", "WhatsApp群", "市场上", "学校里" },
            comment = { "是最好的网吧", "电竞队很强", "烤鸡很好吃", "老板是中国人很厉害" },
            reaction = { "哈哈出名了！", "继续努力💪", "都是大家的功劳", "Mama B看到要骄傲了" },
        }},
        { tpl = "今天来了{count}个新客人，{reason}", vars = {
            count = { "3个", "5个", "一群", "好几个" },
            reason = { "说是朋友推荐的", "看了我们的比赛视频来的", "隔壁关门了过来的", "听说我们有空调才来的😂" },
        }},
    },
    -- ====== 美食话题 ======
    food = {
        { tpl = "谁要{food}？我{action}", vars = {
            food = { "Mama B的烤鸡", "Jollof饭", "Suya串", "烤玉米", "棕榈汁", "炸大蕉" },
            action = { "刚买回来的", "去市场帮你带", "分你一半", "我的吃不完" },
        }},
        { tpl = "{time}了还没吃{meal}，{feeling}", vars = {
            time = { "两点", "下午三点", "快六点" },
            meal = { "午饭", "东西", "饭" },
            feeling = { "饿得头晕", "手都在抖了", "打游戏没力气", "谁去买点吃的？" },
        }},
        { tpl = "Big Joe又在说{food}了，{comment}", vars = {
            food = { "要吃Jollof饭", "Mama B的烤鸡腿", "去市场买椰子", "想喝棕榈酒" },
            comment = { "这人一天到晚想着吃😂", "不过我也饿了……", "吃饱了确实打得好", "他的胃是无底洞" },
        }},
    },
    -- ====== 训练话题 ======
    training = {
        { tpl = "今天练了{hours}小时{skill}，{result}", vars = {
            hours = { "2", "3", "4", "5" },
            skill = { "枪法", "走位", "配合", "战术", "反应" },
            result = { "感觉有进步", "手都酸了", "还是老样子😭", "比昨天好多了" },
        }},
        { tpl = "{who}的{skill}真的{adj}，{comment}", vars = {
            who = { "Thunder", "Snake", "Grace", "Kofi" },
            skill = { "反应速度", "枪法", "走位", "心态" },
            adj = { "太强了", "变态", "可怕", "离谱" },
            comment = { "我得多练练", "天赋这东西没法比", "但我也不差", "什么时候能追上啊" },
        }},
    },
    -- ====== 早期创业 ======
    early_game = {
        { tpl = "咱们网吧刚开{days}天，{feeling}", vars = {
            days = { "几", "没几", "才" },
            feeling = { "一切都在变好", "加油加油💪", "虽然辛苦但值得", "前途无量！" },
        }},
        { tpl = "老板{comment}，{reaction}", vars = {
            comment = { "从中国跑来非洲开网吧", "一个人撑起这个店", "什么都亲力亲为" },
            reaction = { "真有勇气👏", "是个狠人", "佩服！", "我们不能让他失望" },
        }},
    },
    -- ====== 后期野心 ======
    late_game = {
        { tpl = "我觉得咱们队{level}，{ambition}", vars = {
            level = { "已经很强了", "还能更强", "该去大城市打比赛了" },
            ambition = { "冲全国冠军！", "让全非洲都知道我们🏆", "从小镇走向世界", "不拿冠军不罢休" },
        }},
        { tpl = "你们说咱们网吧以后{future}？", vars = {
            future = { "能开分店吗", "能上电视吗", "会不会有赞助商", "能成为非洲最好的电竞馆吗" },
        }},
    },
}

-- 对话链（员工间多人接龙）
CHAT_CHAINS = {
    -- 吃饭辩论
    { id = "chain_food", weight = 10, minMembers = 2, turns = {
        { role = "A", tpl = "中午吃什么？{option}", vars = { option = { "Mama B的烤鸡还是去市场？", "我想吃Jollof饭", "谁去买Suya串？", "有没有人想喝椰子水" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "当然是烤鸡！闻到味了🍗", "Jollof饭加辣！", "我刚吃完你们慢慢纠结😂", "棕榈汤配fufu才是正解" } } },
        { role = "A", tpl = "{ending}", vars = { ending = { "好吧你说了算", "帮我也带一份", "吃饱了下午继续练！", "谁去买？不是我啊" } } },
    }},
    -- 技术比拼
    { id = "chain_skill", weight = 8, minMembers = 2, turns = {
        { role = "A", tpl = "昨天我的KDA是{kda}，你呢？", vars = { kda = { "8/2/5", "12/1/3", "6/4/7", "15/0/2" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "比你高😎", "别提了💀", "差不多吧", "我又没数，打赢就行" } } },
        { role = "A", tpl = "{ending}", vars = { ending = { "哈哈继续练！", "明天我超过你", "咱俩以后双排", "说大话没用，比赛见真章" } } },
    }},
    -- 早安问候
    { id = "chain_morning", weight = 8, minMembers = 2, turns = {
        { role = "A", tpl = "{greeting}", vars = { greeting = { "早啊各位～今天状态怎么样", "Good morning兄弟们！💪", "起来了起来了，又是搬砖的一天", "谁先到的？空调开了没" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "刚到，路上差点被Okada撞了😅", "我到了，先开机预热", "困……昨晚蚊子太多了🦟", "到了到了，Mama B已经开始烤鸡了，闻着好香" } } },
    }},
    -- 停电恐慌
    { id = "chain_power", weight = 6, minMembers = 2,
      cond = function() return playerData_.day >= 3 end,
      turns = {
        { role = "A", tpl = "{panic}", vars = { panic = { "不会吧……灯闪了一下", "NEPA又要搞事了？💀", "发电机有油吗？", "上次停电停了4个小时……" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "别慌！可能是电压不稳", "赶紧存档！！！", "还好有太阳能板顶着", "要不先让客人少开几台" } } },
        { role = "A", tpl = "{ending}", vars = { ending = { "吓死我了还好没停", "希望撑到晚上吧", "非洲的电力真是一言难尽", "老板要不再买台发电机？" } } },
    }},
    -- 比赛热血
    { id = "chain_match", weight = 7, minMembers = 2,
      cond = function() return playerData_.reputation >= 20 end,
      turns = {
        { role = "A", tpl = "{hype}", vars = { hype = { "下场比赛你们准备好了吗！", "听说Gold Net也报名了", "这次一定要赢！🔥", "比赛前是不是该加练" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "准备好了！给他们点颜色看看", "Gold Net？不够我打的", "对方实力不弱但我们更强💪", "来一场训练赛热热身" } } },
        { role = "A", tpl = "{ending}", vars = { ending = { "冲冲冲！为了Dragon Net！", "全镇都等着看我们赢", "赢了请大家吃Jollof饭", "输了我请客，赢了老板请！" } } },
    }},
    -- 新人欢迎
    { id = "chain_welcome", weight = 5, minMembers = 3,
      cond = function() return #teamMembers_ >= 3 end,
      turns = {
        { role = "A", tpl = "欢迎新队友！{welcome}", vars = { welcome = { "以后大家一起冲🏆", "多多关照！", "先吃个Mama B的烤鸡压压惊", "把你的绝活亮出来看看" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "谢谢！我会努力的💪", "终于找到组织了", "听说你们很强，学习一下", "咱们什么时候开始训练" } } },
        { role = "C", tpl = "{chime}", vars = { chime = { "又多一个兄弟/姐妹！开心", "人多力量大", "新人请客是规矩哦😂", "我来教你基本操作" } } },
    }},
    -- 深夜摸鱼
    { id = "chain_night", weight = 6, minMembers = 2,
      cond = function() return playerData_.day >= 5 end,
      turns = {
        { role = "A", tpl = "{tired}", vars = { tired = { "太晚了……还要练吗", "外面黑透了🌙谁还在", "这是今天第几局了", "蚊子开始来上班了🦟" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "再来一局就走！", "我也困了……明天继续", "蚊子比客人多了😂", "Mama B的摊子都收了" } } },
    }},
    -- 非洲谚语讨论
    { id = "chain_proverb", weight = 5, minMembers = 2, turns = {
        { role = "A", tpl = "我{relative}说过一句话：'{proverb}'", vars = {
            relative = { "奶奶", "爷爷", "村长", "妈妈" },
            proverb = { "一只手洗不干净另一只手", "河水不犯井水，但干旱时大家都渴", "慢慢走也能到远方", "独行虎不如群行狼" },
        }},
        { role = "B", tpl = "{react}", vars = { react = { "老人家说的都是经验啊", "这不就是说我们团队吗", "非洲谚语总是这么有道理", "我回头也问问我妈有什么名言😂" } } },
    }},
    -- 足球话题
    { id = "chain_football", weight = 8, minMembers = 2, turns = {
        { role = "A", tpl = "你们说{team}今年{result}？", vars = {
            team = { "尼日利亚", "加纳", "塞内加尔", "喀麦隆", "科特迪瓦" },
            result = { "能进世界杯吗", "非洲杯有戏吗", "是不是最强的", "换教练有用吗" },
        }},
        { role = "B", tpl = "{opinion}", vars = { opinion = { "做梦呢！还是看电竞吧😂", "我觉得行！今年阵容不错", "都不如来我们队打比赛", "足球我不懂但游戏我最懂" } } },
    }},
    -- 对手垃圾话
    { id = "chain_rival", weight = 6, minMembers = 2,
      cond = function() return playerData_.reputation >= 30 end,
      turns = {
        { role = "A", tpl = "听说Gold Net在{action}，{comment}", vars = {
            action = { "到处说我们作弊", "挖我们队员", "模仿我们的训练", "也买了新电脑" },
            comment = { "不就是输不起吗", "让他们说去", "最好的回击就是赢比赛", "Victor那个人真小气" },
        }},
        { role = "B", tpl = "{reply}", vars = { reply = { "我们用实力说话就行💪", "哈哈怕了就对了", "比赛场上见真章", "不理他们，专心练" } } },
    }},
    -- 小雪文化交流（如果有小雪的话）
    { id = "chain_culture", weight = 6, minMembers = 2,
      cond = function()
          for _, m in ipairs(teamMembers_) do if m.name == "小雪" then return true end end
          return false
      end,
      turns = {
        { role = "A", tpl = "小雪，{question}？", vars = { question = { "中国那边也有网吧吗", "教我说几句中文呗", "你们过年吃什么", "四川火锅真的那么辣吗", "中国的游戏比赛大不大" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "中国网吧可大了，有的整栋楼都是！", "好呀！'你好'就是Hello～", "过年吃饺子！比Jollof饭还重要😂", "比你吃过最辣的还辣十倍🌶️", "中国电竞是世界顶级的，有一天我们也能去看！" } } },
        { role = "A", tpl = "{react}", vars = { react = { "好想去中国看看", "你好！你好！😄", "那我也做Jollof饭给你尝", "我不信，我可是吃辣椒长大的！", "那我们先拿非洲冠军再说！🏆" } } },
    }},
    -- Mama B 关心大家
    { id = "chain_mama", weight = 6, minMembers = 2,
      cond = function()
          for _, m in ipairs(teamMembers_) do if m.name == "Mama B" then return true end end
          return false
      end,
      turns = {
        { role = "A", tpl = "{care}", vars = { care = { "你们今天吃饭了没？别饿着肚子打游戏", "年轻人要注意身体，别太晚睡", "我给大家带了烤鸡，过来拿🍗", "谁的水杯空了？我去灌水" } } },
        { role = "B", tpl = "{reply}", vars = { reply = { "谢谢Mama！您太好了😭", "有Mama在就是幸福", "Mama您的烤鸡全非洲最好吃！", "您就是我们的非洲妈妈💕" } } },
    }},
}

-- 状态触发器（基于游戏状态生成语境消息）
STATE_CHAT_TRIGGERS = {
    { id = "low_money", priority = 10, cooldown = 3, topic = "money",
      cond = function() return playerData_.money < 500 end,
      msgs = {
          { tpl = "老板……账上还有多少钱？{worried}", vars = { worried = { "最近单子好像不太多😟", "要不要接几个急单？", "先撑过这周吧" } } },
          { tpl = "听说隔壁也在降价，咱们{suggestion}", vars = { suggestion = { "要不要搞个活动？", "得想想办法了", "不能坐以待毙啊" } } },
      },
    },
    { id = "high_rep", priority = 5, cooldown = 5, topic = "reputation",
      cond = function() return playerData_.reputation >= 80 end,
      msgs = {
          { tpl = "我们名气越来越大了{excited}", vars = { excited = { "！在WhatsApp群都传开了", "！有人来采访我们不", "，连隔壁村都知道我们了💪" } } },
          { tpl = "今天又来了好多新客人，{comment}", vars = { comment = { "都说是慕名来的", "有几个说看了我们比赛视频", "这就是名声的力量🔥" } } },
      },
    },
    { id = "bad_equip", priority = 8, cooldown = 2, topic = "equipment",
      cond = function() return (playerData_.equipCondition or 100) < 40 end,
      msgs = {
          { tpl = "设备状况{EQUIP}%了，{reaction}", vars = { reaction = { "再不修要出大问题", "客人都在抱怨了", "有台机器昨天死机了" } } },
          { tpl = "这个{item}用起来{problem}，{request}", vars = {
              item = { "键盘", "鼠标", "椅子", "显示器" },
              problem = { "太卡了", "不灵了", "要散架了", "闪来闪去" },
              request = { "能换新的吗老板", "至少修一下吧", "比赛前得搞定", "这样下去要出事" },
          }},
      },
    },
    { id = "high_debt", priority = 9, cooldown = 4, topic = "money",
      cond = function() return (playerData_.debt or 0) > 200 end,
      msgs = {
          { tpl = "老板，咱们是不是还欠着钱？{comment}", vars = { comment = { "利息会越滚越多的", "先还一点吧", "Mama B不会催但也不好意思" } } },
      },
    },
    { id = "team_low_mood", priority = 7, cooldown = 2, topic = "general",
      cond = function()
          if #teamMembers_ == 0 then return false end
          local sum = 0
          for _, m in ipairs(teamMembers_) do sum = sum + m.mood end
          return (sum / #teamMembers_) < 50
      end,
      msgs = {
          { tpl = "大家最近心情都不太好……{suggestion}", vars = { suggestion = { "要不要搞个聚餐？", "是不是训练太累了", "有什么心事可以说出来", "放一天假吧老板🙏" } } },
          { tpl = "我观察了一下，{observation}", vars = { observation = { "大家脸色都不太对", "训练时集中力不够", "有人在偷偷叹气", "气氛有点沉重" } } },
      },
    },
    { id = "payday", priority = 6, cooldown = 7, topic = "money",
      cond = function() return playerData_.day % 7 == 6 end,
      msgs = {
          { tpl = "快发薪日了{excited}", vars = { excited = { "！终于可以给家里寄钱了", "，想好买什么了💰", "，这周辛苦了大家", "！要不要一起去市场庆祝" } } },
      },
    },
    { id = "generator_low", priority = 8, cooldown = 2, topic = "equipment",
      cond = function() return (playerData_.generatorLevel or 0) > 0 and (playerData_.fuel or 0) < 5 end,
      msgs = {
          { tpl = "发电机油快没了{warning}", vars = { warning = { "！赶紧加油", "，一旦停电就完了", "，闻到味道不太对", "，油箱见底了⛽" } } },
      },
    },
    { id = "hot_weather", priority = 3, cooldown = 3, topic = "general",
      cond = function() return (playerData_.acLevel or 0) < 1 and playerData_.day >= 3 end,
      msgs = {
          { tpl = "今天好热{complaint}", vars = { complaint = { "……没空调真受不了😰", "，风扇都是热风", "，客人说待不住了", "，什么时候装空调啊老板" } } },
      },
    },
    { id = "solar_pride", priority = 3, cooldown = 5, topic = "equipment",
      cond = function() return (playerData_.solarLevel or 0) >= 2 end,
      msgs = {
          { tpl = "太阳能板{status}，{comment}", vars = {
              status = { "发电很稳", "效率不错", "今天出力特别大" },
              comment = { "非洲的太阳就是好☀️", "NEPA断电都不怕了", "最环保的网吧哈哈", "隔壁都羡慕死了" },
          }},
      },
    },
    { id = "many_members", priority = 4, cooldown = 6, topic = "general",
      cond = function() return #teamMembers_ >= 5 end,
      msgs = {
          { tpl = "咱们队现在{MEMBERS}个人了，{feeling}", vars = { feeling = { "越来越像正规军了", "人多力量大💪", "配合需要更多练习", "要不要搞个队规" } } },
      },
    },
}

--- 评估状态触发器
local function EvalStateTriggers(maxCount)
    local results = {}
    local sorted = {}
    for _, t in ipairs(STATE_CHAT_TRIGGERS) do table.insert(sorted, t) end
    table.sort(sorted, function(a, b) return (a.priority or 5) > (b.priority or 5) end)
    for _, trigger in ipairs(sorted) do
        if #results >= maxCount then break end
        local lastDay = chatTriggerCooldowns_[trigger.id] or 0
        local cdOk = (playerData_.day - lastDay) >= (trigger.cooldown or 1)
        if cdOk and trigger.cond and trigger.cond() then
            local pool = trigger.msgs
            local pick = pool[math.random(#pool)]
            local text = ResolveTemplate(pick.tpl, pick.vars)
            text = InjectGameState(text)
            local sender = PickSpeaker(trigger.topic or "general", {})
            table.insert(results, { sender = sender, content = text })
            chatTriggerCooldowns_[trigger.id] = playerData_.day
        end
    end
    return results
end

--- 生成对话链
local function GenerateChain()
    if #teamMembers_ < 2 then return {} end
    local pool = {}
    for _, chain in ipairs(CHAT_CHAINS) do
        local minM = chain.minMembers or 2
        local condOk = (not chain.cond) or chain.cond()
        if #teamMembers_ >= minM and condOk then
            table.insert(pool, chain)
        end
    end
    if #pool == 0 then return {} end
    local totalW = 0
    for _, c in ipairs(pool) do totalW = totalW + (c.weight or 5) end
    local r = math.random() * totalW
    local acc = 0
    local chosen = pool[1]
    for _, c in ipairs(pool) do
        acc = acc + (c.weight or 5)
        if r <= acc then chosen = c; break end
    end
    -- 分配真实成员到角色
    local shuffled = {}
    for _, m in ipairs(teamMembers_) do table.insert(shuffled, m) end
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    local roleMap = { A = shuffled[1].name, B = shuffled[2].name }
    if #shuffled >= 3 then roleMap.C = shuffled[3].name end
    local msgs = {}
    for _, turn in ipairs(chosen.turns) do
        local speaker = roleMap[turn.role] or RandMemberName()
        local text = ResolveTemplate(turn.tpl, turn.vars)
        text = InjectGameState(text)
        table.insert(msgs, { sender = speaker, content = text })
    end
    return msgs
end

--- 生成独白消息
local function GenerateSoloMessages(count)
    local msgs = {}
    local activeCats = { "general", "africa_life", "food" }
    if (playerData_.equipCondition or 100) < 60 then table.insert(activeCats, "equipment") end
    if playerData_.money < 1000 then table.insert(activeCats, "money") end
    if playerData_.reputation >= 60 then table.insert(activeCats, "reputation") end
    if playerData_.day <= 5 then table.insert(activeCats, "early_game") end
    if playerData_.day >= 15 then table.insert(activeCats, "late_game") end
    -- 随机加入文化类话题
    if math.random() < 0.4 then table.insert(activeCats, "africa_culture") end
    if math.random() < 0.3 then table.insert(activeCats, "training") end

    local used = {}
    for _ = 1, count do
        local cat = activeCats[math.random(#activeCats)]
        local templates = SOLO_CHAT_TEMPLATES[cat]
        if templates and #templates > 0 then
            local idx = math.random(#templates)
            local key = cat .. "_" .. idx
            if not used[key] then
                used[key] = true
                local t = templates[idx]
                local text = ResolveTemplate(t.tpl, t.vars)
                text = InjectGameState(text)
                local speaker = PickSpeaker(cat, {})
                -- 30%概率加口头禅
                local profile = CHAR_CHAT_PROFILES[speaker]
                if profile and math.random() < 0.3 and profile.catchphrases then
                    local cp = profile.catchphrases[math.random(#profile.catchphrases)]
                    text = cp .. " " .. text
                end
                -- 20%概率根据心情加语气
                if profile and math.random() < 0.2 then
                    for _, m in ipairs(teamMembers_) do
                        if m.name == speaker then
                            if m.mood >= 80 and profile.moodHigh then
                                text = text .. " " .. profile.moodHigh[math.random(#profile.moodHigh)]
                            elseif m.mood < 40 and profile.moodLow then
                                text = text .. " " .. profile.moodLow[math.random(#profile.moodLow)]
                            end
                            break
                        end
                    end
                end
                table.insert(msgs, { sender = speaker, content = text })
            end
        end
    end
    return msgs
end
--- 每日结算时生成群聊消息（在 EndDay 中调用）
function GenerateDailyChatMessages()
    -- 天数标记系统消息
    AddChatMsg(nil, "—— 第 " .. playerData_.day .. " 天 ——", false, true)

    -- 抽取 1~3 条事件
    local count = math.random(1, 3)
    local events = PickChatEvents(count)

    for _, evt in ipairs(events) do
        -- 标记一次性事件
        if evt.once then chatEventTriggered_[evt.id] = true end

        -- 生成消息
        local msgs = evt.msgs()
        for _, msg in ipairs(msgs) do
            AddChatMsg(msg.sender, msg.content, false, msg.isSystem)
        end

        -- 如果有决策且当前没有待处理决策 → 设置待决策
        if evt.decision and not pendingChatDecision_ then
            local dec = evt.decision()
            pendingChatDecision_ = {
                eventId = evt.id,
                question = dec.question,
                options = dec.options,
            }
        end
    end

    ----------------------------------------------------------------
    -- 自主聊天层：员工自由对话（组合式生成）
    ----------------------------------------------------------------
    if #teamMembers_ >= 1 then
        local autoMsgs = {}
        -- 1) 状态触发消息（优先级最高，最多3条）
        local stateMsgs = EvalStateTriggers(3)
        for _, m in ipairs(stateMsgs) do table.insert(autoMsgs, m) end
        -- 2) 对话链（需要至少2人）
        if #teamMembers_ >= 2 then
            local chainCount = math.random(0, 2)
            for _ = 1, chainCount do
                local chain = GenerateChain()
                if chain then
                    for _, m in ipairs(chain) do table.insert(autoMsgs, m) end
                end
            end
        end
        -- 3) 独白/闲聊填充剩余名额
        local targetTotal = math.random(5, 12)
        local remaining = math.max(0, targetTotal - #autoMsgs)
        if remaining > 0 then
            local soloMsgs = GenerateSoloMessages(remaining)
            for _, m in ipairs(soloMsgs) do table.insert(autoMsgs, m) end
        end
        -- 4) Fisher-Yates 打乱顺序（对话链内部保持顺序已由 GenerateChain 处理）
        for i = #autoMsgs, 2, -1 do
            local j = math.random(1, i)
            autoMsgs[i], autoMsgs[j] = autoMsgs[j], autoMsgs[i]
        end
        -- 5) 输出到群聊
        for _, m in ipairs(autoMsgs) do
            AddChatMsg(m.sender, m.content, false, false)
        end
    end
end

--- 处理玩家在群聊中选择选项
function HandleChatDecision(optionIndex)
    if not pendingChatDecision_ then return end
    local opt = pendingChatDecision_.options[optionIndex]
    if not opt then return end

    -- 添加玩家选择消息
    AddChatMsg("老板(你)", opt.text, true, false)

    -- 执行效果，获取反馈消息（pcall 保护，防止 effect 内部崩溃）
    local eOk, feedback = pcall(opt.effect)
    if not eOk then
        log:Write(LOG_ERROR, "[HandleChatDecision] effect error: " .. tostring(feedback))
        feedback = "（处理中出了点问题）"
    end
    if feedback and feedback ~= "" then
        AddChatMsg(RandMemberName(), feedback, false, false)
    end

    -- 清除待决策
    pendingChatDecision_ = nil

    -- 刷新 UI
    SaveGame()
    BuildUI()
end

-- ============================================================================
-- 6.3 老板自由发言 → 关键词匹配伪 AI 回复
-- ============================================================================

--- 关键词 → 回复规则（按优先级从上到下匹配，首条命中即返回）
local CHAT_REPLY_RULES = {
    -- 💰 钱相关
    { kw = { "工资", "薪水", "发钱", "加薪", "涨工资" }, replies = {
        function() return RandMemberName(), "老板提到工资了！👀 大家快来听！", nil end,
        function() return RandMemberName(), "能涨就好……上个月的泡面钱还没报销呢😂", nil end,
        function()
            return RandMemberName(), "听到了听到了！老板最大方了💰",
                function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 3) end end
        end,
    }},
    { kw = { "奖金", "分红", "提成" }, replies = {
        function() return RandMemberName(), "有奖金？！我今晚加班到天亮！💪", nil end,
        function() return RandMemberName(), "建议奖金按 MVP 次数分配，公平合理✌️", nil end,
    }},
    -- 🔧 设备/网络
    { kw = { "升级", "换电脑", "新设备", "配置" }, replies = {
        function() return RandMemberName(), "终于要换了吗？3号机那个鼠标我忍很久了🖱️", nil end,
        function() return RandMemberName(), "建议先换显示器，144Hz和60Hz完全两个世界", nil end,
    }},
    { kw = { "网速", "网络", "延迟", "卡", "掉线", "WiFi", "wifi", "断网" }, replies = {
        function() return RandMemberName(), "一到晚上就卡成PPT……客户都抱怨了😫", nil end,
        function() return RandMemberName(), "能不能拉条专线？代练最怕掉线", nil end,
        function() return RandMemberName(), "我上次代练掉线差点被客户投诉💀", nil end,
    }},
    -- ⚡ 停电
    { kw = { "停电", "发电", "电力", "发电机", "太阳能" }, replies = {
        function() return RandMemberName(), "别提停电了，上次停电我的钻石局直接掉段了😭", nil end,
        function() return RandMemberName(), "老板要不搞个太阳能板？长远划算☀️", nil end,
    }},
    -- 🎮 比赛/训练
    { kw = { "比赛", "打比赛", "联赛", "锦标赛", "争冠" }, replies = {
        function() return RandMemberName(), "冲冲冲！这次一定要拿冠军🏆", nil end,
        function() return RandMemberName(), "对手研究过了吗？知己知彼百战百胜", nil end,
        function()
            return RandMemberName(), "大家打起精神！为了工作室的荣誉💪",
                function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 2) end end
        end,
    }},
    { kw = { "训练", "练习", "加练", "刻意练习", "复盘" }, replies = {
        function() return RandMemberName(), "好的老板！今晚加练两小时🎯", nil end,
        function()
            return RandMemberName(), "收到！大家都去练枪，晚饭后集合",
                function() for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + 1) end end
        end,
        function() return RandMemberName(), "建议看看最新的教学视频，有几个新套路", nil end,
    }},
    -- 😊 鼓励/加油
    { kw = { "加油", "辛苦", "不错", "好样的", "干得好", "太棒", "厉害", "666", "牛" }, replies = {
        function()
            return RandMemberName(), "谢谢老板！被夸了好开心😊",
                function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 5) end end
        end,
        function() return RandMemberName(), "老板说加油就是最大的动力！冲！🔥", nil end,
        function() return RandMemberName(), "嘿嘿～有老板在我们啥都不怕💪", nil end,
    }},
    -- 😠 批评/不满
    { kw = { "什么玩意", "垃圾", "不行", "太差", "菜", "摆烂", "偷懒" }, replies = {
        function()
            return RandMemberName(), "对不起老板……我会努力改进的😔",
                function()
                    if #teamMembers_ > 0 then
                        local m = teamMembers_[math.random(#teamMembers_)]
                        m.mood = math.max(0, m.mood - 5)
                    end
                end
        end,
        function() return RandMemberName(), "别骂了别骂了……我已经在反思了🥲", nil end,
    }},
    -- 🍗 吃喝
    { kw = { "吃", "喝", "饿", "午饭", "晚饭", "外卖", "零食", "咖啡", "饮料" }, replies = {
        function() return RandMemberName(), "我要一杯冰美式☕ 不，两杯！", nil end,
        function() return RandMemberName(), "Mama B 说今天做炖牛肉🍖 已经闻到香味了", nil end,
        function() return RandMemberName(), "老板请客吗？！我要烤肉🥩", nil end,
    }},
    -- 🛌 休息
    { kw = { "休息", "放假", "累了", "困", "睡觉", "下班" }, replies = {
        function() return RandMemberName(), "确实有点累了……但是单子还没做完😴", nil end,
        function() return RandMemberName(), "老板安排放假我双手赞成🙋", nil end,
        function() return RandMemberName(), "让我再打一把就休息，真的就一把……", nil end,
    }},
    -- 💼 代练/接单
    { kw = { "代练", "接单", "单子", "订单", "客户" }, replies = {
        function() return RandMemberName(), "今天接了3单，手都快抽筋了😵", nil end,
        function() return RandMemberName(), "有个客户要冲王者，价格给得不错💰", nil end,
        function() return RandMemberName(), "代练虽然累，但想到工资就有动力了哈哈", nil end,
    }},
    -- 👥 团队/氛围
    { kw = { "团队", "大家", "兄弟", "伙计", "团建" }, replies = {
        function()
            return RandMemberName(), "有这样的团队真好😊 大家一起加油！",
                function() for _, m in ipairs(teamMembers_) do m.mood = math.min(100, m.mood + 2) end end
        end,
        function() return RandMemberName(), "老板说团建？是不是要请吃大餐？👀", nil end,
    }},
    -- 🏢 竞争对手
    { kw = { "隔壁", "对手", "Thunder", "竞争" }, replies = {
        function() return RandMemberName(), "隔壁那帮人？我们早晚超过他们💪", nil end,
        function() return RandMemberName(), "听说他们最近也在扩招，我们得抓紧了", nil end,
    }},
    -- 🎵 娱乐
    { kw = { "音乐", "歌", "游戏", "有趣", "搞笑", "哈哈" }, replies = {
        function() return RandMemberName(), "哈哈哈哈😂 老板今天心情不错啊", nil end,
        function() return RandMemberName(), "工作之余放松一下也挺好的🎵", nil end,
    }},
}

--- 万能兜底回复（当没有关键词匹配时）
local CHAT_FALLBACK_REPLIES = {
    function() return RandMemberName(), "收到老板！👌" end,
    function() return RandMemberName(), "好的老板，我们记住了📝" end,
    function() return RandMemberName(), "老板说的对！" end,
    function() return RandMemberName(), "明白！马上安排💪" end,
    function() return RandMemberName(), "了解了解～" end,
    function() return RandMemberName(), "OK老板！😊" end,
    function() return RandMemberName(), "嗯嗯，我们会注意的" end,
    function() return RandMemberName(), "老板英明！👍" end,
    function() return RandMemberName(), "收到收到，这就去办" end,
    function() return RandMemberName(), "好嘞！" end,
}

--- 处理老板自由输入 → 生成伪 AI 回复
function HandleBossChat(text)
    if not text or text == "" then return end

    -- 添加老板消息
    AddChatMsg("老板(你)", text, true, false)

    -- 关键词匹配
    local matched = false
    for _, rule in ipairs(CHAT_REPLY_RULES) do
        for _, kw in ipairs(rule.kw) do
            if string.find(text, kw, 1, true) then
                -- 命中：随机选一条回复
                local fn = rule.replies[math.random(#rule.replies)]
                local sender, reply, effect = fn()
                AddChatMsg(sender, reply, false, false)
                if effect then effect() end
                matched = true
                break
            end
        end
        if matched then break end
    end

    -- 兜底回复
    if not matched then
        local fn = CHAT_FALLBACK_REPLIES[math.random(#CHAT_FALLBACK_REPLIES)]
        local sender, reply = fn()
        AddChatMsg(sender, reply, false, false)
    end

    SaveGame()
    BuildUI()
end


