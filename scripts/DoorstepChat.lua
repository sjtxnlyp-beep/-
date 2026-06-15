---@diagnostic disable: undefined-global
-- ============================================================================
-- DoorstepChat.lua — 门口闲聊系统
-- 每天开始时（D5+），路人/常客/NPC 在网吧门口随机闲聊一句
-- 零AP消耗、纯叙事氛围，偶尔给微奖励（<5%概率）
-- ============================================================================

local DoorstepChat = {}

-- ============================================================================
-- 闲聊人物池
-- ============================================================================
local CHAT_CHARACTERS = {
    { name = "Mama B", emoji = "👩‍🍳", desc = "隔壁烤鸡摊老板娘" },
    { name = "摩托佬 Dayo", emoji = "🏍️", desc = "跑腿快递，消息灵通" },
    { name = "老 Samuel", emoji = "👴", desc = "街角杂货店老头" },
    { name = "小 Ama", emoji = "👧", desc = "Mama B 的女儿，每天路过上学" },
    { name = "网警 Bello", emoji = "👮", desc = "本地派出所唯一懂电脑的警察" },
    { name = "流浪艺人 Kweku", emoji = "🎸", desc = "弹吉他的流浪汉，经常在网吧蹭WiFi" },
    { name = "Victor 的手下", emoji = "🕶️", desc = "Gold Net 的员工，偶尔路过刺探军情" },
    { name = "常客 Bright", emoji = "🧑‍💻", desc = "每天来打游戏的大学生" },
    { name = "送水工 Koby", emoji = "💧", desc = "每天送桶装水的大力士" },
    { name = "卖报阿姨", emoji = "📰", desc = "消息来源，什么八卦都知道" },
}

-- ============================================================================
-- 闲聊内容池（带状态条件）
-- ============================================================================
-- 每条包含: character(索引/nil=随机), line(台词), cond(条件), reward(可选微奖励)
local CHAT_POOL = {
    -- ── 通用日常（无条件） ──
    { line = "早啊老板！今天天气真好，适合搞钱！",
      cond = function() return true end },
    { line = "昨晚隔壁那家酒吧放音乐放到凌晨三点……你们不受影响吧？",
      cond = function() return true end },
    { line = "老板，你这WiFi信号能不能飘到我摊子上来？我给你打折烤鸡！",
      charIdx = 1, cond = function() return true end },
    { line = "今天学校放假，估计一会儿小孩子要扎堆来了。",
      charIdx = 4, cond = function() return true end },
    { line = "嘿！你们这儿有没有充电的地方？我手机没电了赶不上外卖单。",
      charIdx = 2, cond = function() return true end },

    -- ── 早期提示（D5-D15） ──
    { line = "Victor 那边又在搞装修，叮叮当当吵死了。你可别被他比下去啊！",
      charIdx = 10, cond = function() return (playerData_.day or 1) >= 8 and (playerData_.day or 1) <= 15 end },
    { line = "我跟你说，网速快的网吧——客人就是多。这是铁律。",
      charIdx = 3, cond = function() return (playerData_.netSpeed or 1) < 3 and (playerData_.day or 1) >= 7 end },
    { line = "老板，你那个比赛战队……我侄子也想加入，行不行？",
      charIdx = 9, cond = function() return #teamMembers_ >= 2 and #teamMembers_ < 5 end },

    -- ── 基于资金状态 ──
    { line = "哟，今天老板脸色不太好？是不是手头紧？别怕，瓦坎达维尔的钱总会流回来的。",
      charIdx = 3, cond = function() return (playerData_.money or 0) < 500 end },
    { line = "听说你最近赚了不少？要不要考虑请大家吃个烤鸡？我给你打八折！",
      charIdx = 1, cond = function() return (playerData_.money or 0) >= 5000 end },

    -- ── 基于声望 ──
    { line = "现在街上好多人都知道 Dragon Net 了。我女儿说她同学都在聊你们的比赛。",
      charIdx = 1, cond = function() return (playerData_.reputation or 0) >= 100 end },
    { line = "老板！能不能给我签个名？我朋友不信我认识你这种大人物！",
      charIdx = 8, cond = function() return (playerData_.reputation or 0) >= 300 end },

    -- ── 基于队员/比赛 ──
    { line = "你家那个 Kofi 昨晚又练到半夜吧？我看灯一直亮着。年轻人有冲劲是好事。",
      charIdx = 3, cond = function() return HasMember and HasMember("Kofi") end },
    { line = "上次你们比赛输了的事——别放心上。我以前踢球也是，输多了就会赢了。",
      charIdx = 9, cond = function() return (playerData_.tournamentPlayed or 0) >= 1 and (playerData_.tournamentWins or 0) == 0 end },
    { line = "冠军！冠军！我可是从第一天就看好你们的！……记住，是我说的！",
      charIdx = 6, cond = function() return (playerData_.tournamentWins or 0) >= 1 end },

    -- ── Victor 相关 ──
    { line = "刚才 Victor 的人在你门口转悠了一圈……没干什么，就是看了看。怪渗人的。",
      charIdx = 10, cond = function() return (playerData_.day or 1) >= 10 and (playerData_.reputation or 0) >= 80 end },
    { line = "我去 Gold Net 看了一眼——说实话，他们的服务态度比你这差远了。",
      charIdx = 2, cond = function() return (playerData_.day or 1) >= 12 end },
    { line = "Victor 今天好像心情不好。他的店上午只来了三个客人。嘿嘿。",
      charIdx = 7, cond = function() return (playerData_.reputation or 0) >= 200 end },

    -- ── 设备相关 ──
    { line = "老板，你们的椅子能不能换个软垫的？我屁股坐得疼。认真的。",
      charIdx = 8, cond = function() return (playerData_.chairLevel or 0) < 2 end },
    { line = "你这网吧的空调吹着是真舒服。外面三十八度，里面像天堂。",
      charIdx = 6, cond = function() return (playerData_.acLevel or 0) >= 2 end },

    -- ── 有黄金 ──
    { line = "我听说金价最近又涨了？你是不是买了？聪明人啊！",
      charIdx = 2, cond = function() return (playerData_.goldOunces or 0) > 0 end },

    -- ── 分店扩张 ──
    { line = "Dragon Net 在拉各斯也开了？！老板你这是要一统非洲电竞啊！",
      charIdx = 9, cond = function() return #(playerData_.branches or {}) >= 1 end },
    { line = "老板不在的时候，你那自动化系统管得挺好的嘛。以后你就不用来了？",
      charIdx = 3, cond = function() return (playerData_.automationLevel or 0) >= 3 end },

    -- ── 天气/随机风味 ──
    { line = "下雨天就是好——大家不想淋雨就往网吧钻。你今天应该生意不错！",
      cond = function() return math.random() < 0.3 end },
    { line = "路边那只野猫又来了。它好像把你网吧门口当家了。",
      cond = function() return math.random() < 0.2 end },
    { line = "有个白人游客刚才拍了你的店招。说什么'authentic African tech culture'。",
      cond = function() return (playerData_.day or 1) >= 15 and math.random() < 0.25 end },

    -- ── 带微奖励的（稀有，<5%触发率 由外层控制） ──
    { line = "来，给你带了份烤鸡。别客气，邻里之间！",
      charIdx = 1,
      cond = function() return (playerData_.day or 1) >= 7 end,
      reward = { type = "money", amount = 20, msg = "🍗 Mama B 送了你一份烤鸡（省下 $20 午饭钱）" } },
    { line = "老板！这是昨天客人落下的U盘，里面有5个G的高清比赛录像，给你！",
      charIdx = 8,
      cond = function() return #teamMembers_ >= 1 end,
      reward = { type = "rep", amount = 3, msg = "📀 获得比赛录像（声望 +3）" } },
    { line = "我在路边捡到几个哈弗币的兑换码……你拿去吧，我又不玩游戏。",
      charIdx = 9,
      cond = function() return (playerData_.day or 1) >= 10 end,
      reward = { type = "havoc", amount = 15, msg = "💎 获得哈弗币 ×15" } },
}

-- ============================================================================
-- 核心接口
-- ============================================================================

--- 生成今日门口闲聊内容
--- 每天调用一次（EndDay 结束后 / 新一天开始时）
---@param day number 当前天数
---@return table|nil { character={name,emoji,desc}, line, reward? } 或 nil（D1-4不触发）
function DoorstepChat.Generate(day)
    -- D1-4 由新手引导主导，不插入闲聊
    if day < 5 then return nil end

    -- 80% 概率触发闲聊（20% 安静开门，避免疲劳）
    -- D9 强制触发：作为门口闲聊系统的"教学日"，确保玩家体验到
    if day ~= 9 and math.random() > 0.80 then return nil end

    -- 筛选满足条件的候选
    local eligible = {}
    for _, entry in ipairs(CHAT_POOL) do
        local ok, result = pcall(entry.cond)
        if ok and result then
            table.insert(eligible, entry)
        end
    end

    if #eligible == 0 then return nil end

    -- 随机抽取
    local pick = eligible[math.random(#eligible)]

    -- 确定角色
    local char
    if pick.charIdx then
        char = CHAT_CHARACTERS[pick.charIdx]
    else
        char = CHAT_CHARACTERS[math.random(#CHAT_CHARACTERS)]
    end

    -- 奖励概率控制（有 reward 字段的条目只有 30% 概率真给奖励）
    local actualReward = nil
    if pick.reward then
        if math.random() < 0.30 then
            actualReward = pick.reward
        end
    end

    return {
        character = char,
        line = pick.line,
        reward = actualReward,
    }
end

--- 领取门口闲聊奖励
---@param reward table { type, amount, msg }
function DoorstepChat.ClaimReward(reward)
    if not reward then return end
    if reward.type == "money" then
        playerData_.money = (playerData_.money or 0) + reward.amount
    elseif reward.type == "rep" then
        playerData_.reputation = (playerData_.reputation or 0) + reward.amount
    elseif reward.type == "havoc" then
        playerData_.havocCoins = (playerData_.havocCoins or 0) + reward.amount
    end
    if reward.msg then
        AddLog(reward.msg)
    end
end

return DoorstepChat
