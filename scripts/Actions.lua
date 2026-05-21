---@diagnostic disable: undefined-global
local CafeAnimEvents = require("CafeAnimEvents")

function UseActionPoint(cost)
    cost = cost or 1
    if playerData_.actionPoints < cost then return false end
    playerData_.actionPoints = playerData_.actionPoints - cost
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
    if playerData_.money < 200 or #CANDIDATE_POOL == 0 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 200
    AddLog("🔍 花了 $200 四处打听，看看有没有高手……")

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

function DoVisitMarket()
    if playerData_.money < 50 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 50
    -- 委托追踪：逛集市
    playerData_.questMarketVisit = (playerData_.questMarketVisit or 0) + 1

    CafeAnimEvents.Push("market_return")
    -- 声望越高，集市结果越好（老板名声在外，商贩给好价）
    local luckBonus = math.min(20, math.floor(playerData_.reputation / 15))
    local roll = math.random(1, 100) + luckBonus

    local title, narrative, effects, icon, success

    if roll <= 25 then
        local earn = 80 + math.floor(playerData_.reputation / 8)
        playerData_.money = playerData_.money + earn
        icon = "⌨️"
        title = "淘到好货"
        narrative = "集市角落，一个大叔正在收拾摊位。你眼尖，一眼认出那堆破纸箱里藏着几套品质不错的二手键鼠。\n\n"
            .. "「这些不要了？」你随口一问。\n「拿走拿走，占地方！」\n\n"
            .. "你花了点小钱收下，回去擦干净一摆——嘿，比新的还好用。转手就有人来买。"
        effects = "💰 +$" .. earn
        success = true
    elseif roll <= 50 then
        local repGain = 10 + math.floor(playerData_.decoLevel * 5)
        playerData_.reputation = playerData_.reputation + repGain
        playerData_.decoLevel = math.min(playerData_.decoLevel + 1, #UPGRADES.deco.costs)
        icon = "🎭"
        title = "非洲面具"
        narrative = "一位老匠人的摊位吸引了你的目光——几十个手工雕刻的木制面具，每一个都表情各异。\n\n"
            .. "你挑了一个龇牙咧嘴的战士面具挂在网吧门口。\n\n"
            .. "「老板这面具好凶啊！」「酷！拍个照发朋友圈！」\n路过的人纷纷驻足，还有人专程来打卡。"
        effects = "⭐ 声望+" .. repGain
        success = true
    elseif roll <= 75 then
        if #teamMembers_ > 0 then
            local m = teamMembers_[math.random(1, #teamMembers_)]
            local boost = 15 + math.floor((100 - m.mood) / 5)
            m.mood = math.min(100, m.mood + boost)
            icon = "📿"
            title = "特色手链"
            narrative = "逛着逛着，你在一个珠宝摊看到了一条编着彩色珠子的手链，上面刻着当地部落的祝福图案。\n\n"
                .. "你想起 " .. m.name .. " 最近状态不太好，顺手买了一条带回去。\n\n"
                .. "「这……给我的？」" .. m.name .. " 有点惊讶，然后咧嘴一笑，立刻戴上了。\n"
                .. "「老板，今天训练我绝对不偷懒！」"
            effects = "😊 " .. m.name .. " 心情+" .. boost
            success = true
        else
            playerData_.reputation = playerData_.reputation + 8
            icon = "🤝"
            title = "结交朋友"
            narrative = "集市上人头攒动，你左看看右看看，虽然没买什么，但跟好几个摊主聊了起来。\n\n"
                .. "卖布的 Amina 说她儿子想学电脑，烤玉米的 Joseph 说周末想来你店里上网。\n\n"
                .. "在非洲做生意，人脉比什么都重要。"
            effects = "⭐ 声望+8"
            success = true
        end
    elseif roll <= 95 then
        local coins = 40 + math.floor(playerData_.reputation / 10)
        playerData_.havocCoins = playerData_.havocCoins + coins
        icon = "🪙"
        title = "低价哈弗币"
        narrative = "集市入口处，一个戴墨镜的年轻人鬼鬼祟祟凑过来：\n\n"
            .. "「老板，要哈弗币不？我刚跑了一晚上，急出手，便宜卖！」\n\n"
            .. "你验了验货——确实是真的。一番讨价还价后以市场价七折成交。\n"
            .. "做完交易，他骑着摩托一溜烟跑了。这非洲地下经济，还真是无处不在。"
        effects = "🪙 哈弗币+" .. coins
        success = true
    else
        local bonus = 150 + math.random(50, 100)
        playerData_.money = playerData_.money + bonus
        playerData_.reputation = playerData_.reputation + 10
        icon = "✨"
        title = "稀有商人"
        narrative = "你正准备回去，集市最深处一个你从没见过的摊位突然出现。\n\n"
            .. "摊主是个穿着考究的中年人，摊上摆着各种电竞周边——定制鼠标垫、战队T恤、RGB灯带。\n\n"
            .. "「你是开网吧的？」他一眼认出你，「我有批货，在非洲卖不掉，你要的话成本价给你。」\n\n"
            .. "你一口答应。回去挂上架，当天就被网吧客人抢光了。\n这种好运，可不是天天都有。"
        effects = "💰 +$" .. bonus .. "  ⭐ 声望+10"
        success = true
    end

    eventResult_ = {
        success = success,
        icon = icon,
        title = "🏪 逛集市 · " .. title,
        narrative = narrative,
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
    if playerData_.money < tierCfg.cost or #teamMembers_ < 2 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - tierCfg.cost
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

function DoPostFlyers()
    if playerData_.money < 30 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 30
    local rep = math.random(8, 20)
    playerData_.reputation = playerData_.reputation + rep
    CafeAnimEvents.Push("post_flyers")
    if math.random() < 0.3 and #CANDIDATE_POOL > 0 and #teamMembers_ < 5 then
        AddLog("📢 传单引来高手！声望+" .. rep)
        TriggerRecruitEvent()
        return
    end

    -- 多种丰富叙事
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

    local story = FLYER_STORIES[math.random(1, #FLYER_STORIES)]
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
    playerData_.debt = playerData_.debt + amount
    playerData_.debtDay = playerData_.day
    CafeAnimEvents.Push("borrow_money")
    AddLog("💰 Mama B 递过来一叠钞票：「$" .. amount .. "，记着还。利息每天 10%。」")
    AddLog("   当前欠款: $" .. playerData_.debt .. "（每日结算自动扣除利息+本金）")
    PlaySFX("click")
    BuildUI()
end

-- ============================================================================
-- v5 新增行动：二手市场 & 分店
-- ============================================================================

--- 二手设备淘宝市场
function DoSecondHandMarket()
    if not UseActionPoint(1) then return end
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
    local cost = BRANCH_COSTS[idx] or 9000
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
    if playerData_.money < 60 or #teamMembers_ == 0 then return end
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 60
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
    local base = math.pow(cost, 0.65) * 0.5
    local cur = key and GetUpgradeCur(key) or 0
    local tier = 1.0 + cur * 0.12
    return math.min(900, math.max(15, math.floor(base * tier)))
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
    if not CanAffordCost(cost) then return end
    -- 记录升级前的联动（用于完成时检测新联动激活）
    upgradeSynergiesBefore_ = {}
    local oldSynergies = CalcUpgradeSynergies()
    for _, s in ipairs(oldSynergies) do upgradeSynergiesBefore_[s.name] = true end
    local ok, payDesc = TryPayCost(cost)
    if not ok then return end
    if IsCoupActive() then
        AddLog("🪖 政变期间升级，支付了" .. payDesc)
    end
    -- 启动升级计时器
    local buildTime = CalcUpgradeTime(cost, key)
    activeUpgrade_ = key
    upgradeTotalTime_ = buildTime
    upgradeTimeLeft_ = buildTime
    upgradeCost_ = cost  -- 记录费用，用于日志
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

    CafeAnimEvents.Push("upgrade_complete")
    -- 应用升级效果
    playerData_.reputation = playerData_.reputation + 5
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
    for _, s in ipairs(newSynergies) do
        if not oldSynergyNames[s.name] then
            AddLog("🔗 【联动激活】" .. s.name .. " — " .. s.desc)
            PlaySFX("level_up")
            TriggerCelebration()
        end
    end

    -- 清除升级状态
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

    -- 随机选3个不重复的小游戏模式
    local allModes = { "game2048", "gomoku", "memoryMatch" }
    for i = #allModes, 2, -1 do
        local j = math.random(1, i)
        allModes[i], allModes[j] = allModes[j], allModes[i]
    end
    challengeModes_ = { allModes[1], allModes[2], allModes[3] }

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
    challengePhase_ = "round_intro"
    challengeRound_ = 1
    PlaySFX("click")
    BuildUI()
end

--- 开始当前踢馆轮次（启动小游戏）
function StartChallengeRound()
    local mode = challengeModes_[challengeRound_]
    if not mode then FinishChallenge(); return end

    challengePhase_ = "playing"
    -- 启动对应小游戏
    StartMiniGame(mode)

    BuildUI()
end

--- 单轮踢馆结束（小游戏完成后调用）
function FinishChallengeRound()
    local mode = challengeModes_[challengeRound_]
    -- 从小游戏获取玩家分数
    local playerScore = GetMiniGameScore()

    -- 综合分加成：玩家网吧综合分 vs NPC 综合分
    local cafeScore = CalcCafeScore()
    local npcCafeScore = (challengeOpponent_ or {}).score or 100
    -- 加成比例 = (我方综合分 - 对方综合分) / 对方综合分，裁剪到 [-30%, +30%]
    local bonusRatio = math.max(-0.3, math.min(0.3, (cafeScore - npcCafeScore) / math.max(1, npcCafeScore)))
    local bonus = math.floor(playerScore * bonusRatio)
    local rawPlayerScore = playerScore
    playerScore = math.max(0, playerScore + bonus)

    -- 计算NPC分数（基于难度和小游戏类型）
    local thresholds = { game2048 = 400, gomoku = 6, memoryMatch = 12 }
    local base = thresholds[mode] or 5
    local npcScore = math.floor(base * challengeDifficulty_ + math.random(-2, 2))
    npcScore = math.max(1, npcScore)
    challengeNPCScore_ = npcScore

    -- 反应模式：正确数越高越好（和其它模式一致）
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

    -- 清理小游戏和训练状态
    miniGame_ = nil
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
