---@diagnostic disable: undefined-global
-- ============================================================================
-- Retention.lua — 留存系统核心模块
-- 包含：新手引导 / 明日预告 / 离线收益 / 目标链 / 周期性大事件
-- ============================================================================

local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")
local NPCStorylines = require("NPCStorylines")

local Retention = {}

-- 前向声明（GOAL_CHAINS 定义在文件后半部分，但被前面的函数引用）
local GOAL_CHAINS

-- ============================================================================
-- 1. 新手引导（Day 1-3 教程事件）
-- ============================================================================

--- 教程事件表：每天1-2个精心设计的高参与感事件
local TUTORIAL_EVENTS = {
    [1] = {
        {
            id = "tut_first_customer", category = "customer", rarity = "common",
            title = "🧑‍💻 第一位常客",
            desc = "一个叫 Kwame 的年轻人走进网吧，他看起来有些紧张。\"老板，我能试试那个......三角洲行动吗？我看别人玩过，超酷的！\"",
            type = "choice",
            choices = {
                { text = "🎮 免费给他玩一局，教他基本操作",
                  effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma + 1 end,
                  result = function() return "Kwame 兴奋得手都在抖，第一局就拿了两个击杀！\"老板你太好了！我明天还来！\"他会成为你最忠实的顾客。\n\n💡 提示：善待顾客能提升声望，声望越高客流越多！" end },
                { text = "💰 收他正常价格，生意就是生意",
                  effect = function() playerData_.money = playerData_.money + 30 end,
                  result = function() return "Kwame 付了钱坐下来，虽然有点肉疼但很开心。\"值了！\"——他第二天带了两个朋友来。\n\n💡 提示：每台电脑每天都能产生收入，电脑越多赚得越多！" end },
            },
        },
        {
            id = "tut_equipment_trouble", category = "equipment", rarity = "common",
            title = "⚡ 键盘罢工了",
            desc = "三号机的键盘突然失灵，几个按键按下去没反应。客人抱怨连连。你需要处理这件事。",
            type = "choice",
            choices = {
                { text = "🔧 花 $50 从集市买一个新键盘",
                  effect = function() playerData_.money = playerData_.money - 50; playerData_.equipCondition = math.min(100, playerData_.equipCondition + 10) end,
                  result = function() return "新键盘换上，客人立刻满意了。设备状况提升了！\n\n💡 提示：注意设备状况！低于 80% 会影响收入，可以在升级页面维护设备。" end },
                { text = "🤷 先凑合用，等有钱了再说",
                  effect = function() playerData_.equipCondition = math.max(0, playerData_.equipCondition - 5) end,
                  result = function() return "客人不太高兴地换了一台机器。那台坏键盘的电脑暂时没人愿意坐了。\n\n💡 提示：设备状况太低会降低收入哦！记得定期维护。" end },
            },
        },
        {
            id = "tut_rival_appears", category = "business", rarity = "common",
            title = "🏪 对面来了个狠角色",
            desc = "下午，一辆黑色SUV停在街对面。一个戴金表的胖子下了车，指着你的网吧对手下说了几句话，然后大笑着走进对面的空铺面。\n\n隔壁杂货店老板凑过来低声说：\"那是 Victor，瓦坎达维尔的'网吧大王'。听说他要在对面开分店......你最好小心点。\"",
            type = "choice",
            choices = {
                { text = "😤 哼，我不怕竞争，用实力说话",
                  effect = function() playerData_.reputation = playerData_.reputation + 5; playerData_.karma = playerData_.karma + 1 end,
                  result = function() return "你握紧了拳头。Dragon Net 是你的梦想，谁也别想轻易夺走。\n\n从今天起，你得加快脚步了。升级设备、招募队员、参加比赛——每一步都是在为生存而战！" end },
                { text = "😰 这可不妙......得想想办法",
                  effect = function() playerData_.money = playerData_.money + 50 end,
                  result = function() return "你翻出存钱罐里的应急资金。虽然紧张，但你知道只要客户认可你，就没人能轻易抢走他们。\n\n接下来的日子会更艰难，但也更刺激。准备好迎接挑战吧！" end },
            },
        },
    },
    [2] = {
        {
            id = "tut_merchant_visit", category = "business", rarity = "common",
            title = "💼 路过的商人",
            desc = "一个穿着西装的中年人走了进来。\"我是做二手电子设备生意的。听说你这里新开了网吧？我有些好东西可以给你看看——价格绝对公道。\"",
            type = "choice",
            choices = {
                { text = "💰 花 $200 买一批二手鼠标垫和耳机",
                  effect = function() playerData_.money = playerData_.money - 200; playerData_.reputation = playerData_.reputation + 8; trafficBonus_ = trafficBonus_ + 3 end,
                  result = function() return "新装备摆上桌面，整个网吧看起来专业多了。客人们纷纷夸赞！\n\n💡 提示：升级页面有更多装备可以购买——椅子、网速、空调都能提升体验和收入！" end },
                { text = "✋ 算了，我目前资金紧张",
                  effect = function() end,
                  result = function() return "商人留下了名片就走了。\"下次有好货我再来找你。\"\n\n💡 提示：点击底部的「升级」标签页查看所有可用升级！合理投资是致富关键。" end },
            },
        },
        {
            id = "tut_recruit_hint", category = "social", rarity = "common",
            title = "👥 Kofi 主动来敲门了",
            desc = "\"砰砰砰！\"一大早，门都还没开，外面就有人在拍门。你打开门，一个瘦高的年轻人满头是汗：\n\n\"老板！我叫 Kofi！昨天路过看到你在收拾网吧，我就知道——这里要搞电竞的对不对？！我三角洲行动省服排名第47，你看看我的战绩——求你了，让我加入！\"",
            type = "choice",
            choices = {
                { text = "🤝 好小子，有这热情就行！欢迎加入",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 5
                      -- 直接加入第一个队员 Kofi
                      if CANDIDATE_POOL and #CANDIDATE_POOL > 0 and #teamMembers_ < 5 then
                          local kofi = table.remove(CANDIDATE_POOL, 1)
                          kofi.name = "Kofi"
                          kofi.skill = math.max(kofi.skill or 50, 55)
                          table.insert(teamMembers_, kofi)
                          AddLog("🎉 Kofi 正式加入了 Dragon Net 战队！")
                      end
                  end,
                  result = function() return "Kofi 激动得差点把你的门板拍碎。\"老板万岁！！我今天就开始练！\"\n\n他二话不说坐到了1号机前开始排位。看来你的第一个队员，到手了。\n\n💡 Kofi 已加入战队！明天你就可以带他去比赛了。" end },
                { text = "🤔 你先别急，我考虑考虑",
                  effect = function() playerData_.reputation = playerData_.reputation + 2 end,
                  result = function() return "Kofi 有点失落但没有放弃：\"好吧......但我明天还会来的！老板你不会后悔的！\"\n\n他恋恋不舍地走了，看来你随时可以招募他。\n\n💡 提示：在经营页面使用「招募队员」可以随时招人。队员能参加比赛赢奖金！" end },
            },
        },
    },
    [3] = {
        {
            id = "tut_first_match", category = "social", rarity = "common",
            title = "🏆 第一场友谊赛",
            desc = "Kofi 兴奋地跑进来：\"老板！隔壁街的 Phoenix 战队想约一场友谊赛！他们说我们是新队伍，肯定不敢接——你说怎么办？\"",
            type = "choice",
            choices = {
                { text = "💪 接！让他们看看我们的实力",
                  effect = function() playerData_.reputation = playerData_.reputation + 8; playerData_.karma = playerData_.karma + 1 end,
                  result = function() return "Kofi 激动地去通知队员们了。\"老板放心，我们一定打出名声来！\"\n\n💡 提示：现在可以在经营页面点击「比赛」参加友谊赛了！赢了有奖金和声望。" end },
                { text = "🤔 再练练吧，等准备充分了再说",
                  effect = function() playerData_.reputation = playerData_.reputation + 3 end,
                  result = function() return "Kofi 有点失望但点了点头。\"也是，训练才是基础。\"\n\n💡 提示：你可以先用「训练」提升队员能力，然后再参加比赛！" end },
            },
        },
        -- 今日委托教程已暂停
    },
}

--- 获取指定天数的教程事件列表
---@param day number
---@return table|nil 事件列表或nil
function Retention.GetTutorialEvents(day)
    return TUTORIAL_EVENTS[day]
end

--- 获取下一个未使用的教程事件
---@param day number
---@param usedIndex number 已使用的事件索引（0表示未使用过）
---@return table|nil 事件或nil
function Retention.GetNextTutorialEvent(day, usedIndex)
    local events = TUTORIAL_EVENTS[day]
    if not events then return nil end
    local nextIdx = (usedIndex or 0) + 1
    return events[nextIdx]
end

-- ============================================================================
-- 2. 明日预告系统
-- ============================================================================

--- 生成明日预告内容（个性化版：基于玩家当前状态）
---@param day number 当前天数（预告的是 day+1 的内容）
---@return table 预告文本数组，每条含 text / urgency("high"|"mid"|"low") / icon / narrative(可选)
function Retention.GenerateTomorrowPreview(day)
    local nextDay = day + 1
    -- 每条预告：{ text, urgency, icon, narrative }
    local candidates = {}

    local function add(text, urgency, icon)
        table.insert(candidates, { text = text, urgency = urgency or "low", icon = icon or "📌" })
    end

    -- ── 0. 叙事化故事钩子（Day 1-7 专属，最高优先级） ──
    -- 根据当前day生成有悬念的角色驱动预告
    local NARRATIVE_HOOKS = {
        [1] = {
            scene = "夜幕降临，街道上的音乐渐渐安静下来……",
            hook = "隔壁杂货店老板娘悄悄告诉你：\"明天一早，会有个年轻人来找你——他说他想加入你的战队。\"",
            icon = "🌙", urgency = "high",
        },
        [2] = {
            scene = "Kofi 兴奋地擦着键盘，嘴里哼着歌……",
            hook = "他突然转头：\"老板，我听说街尾有场比赛在找人……明天我们去试试？\"",
            icon = "⚔️", urgency = "high",
        },
        [3] = {
            scene = "关门后你路过 Gold Net Cafe……透过窗户，十几台崭新的电脑闪着蓝光。",
            hook = "Victor 站在门口，朝你的方向看了一眼，嘴角微微上扬。明天，他会出什么招？",
            icon = "😈", urgency = "high",
        },
        [4] = {
            scene = "回家路上，手机响了——一条陌生号码的短信。",
            hook = "\"听说你在搞电竞网吧？有人想投你。明天见面聊。\" 这是机会还是陷阱？",
            icon = "📱", urgency = "high",
        },
        [5] = {
            scene = "打烊时，你看着墙上贴的第一周营收表——数字比想象的好。",
            hook = "但 Victor 的 Gold Net 正在办\"开业一周年\"促销……明天的客流会被抢走多少？",
            icon = "📊", urgency = "mid",
        },
        [6] = {
            scene = "深夜，你在阳台上看着远处的灯火。这座城市比你想象的更有活力。",
            hook = "Kofi 发来消息：\"老板，我朋友 Grace 也想来试训，她操作比我还猛！\"",
            icon = "🌃", urgency = "mid",
        },
        [7] = {
            scene = "一周了。从一个人到一支队伍，从零客人到座无虚席。",
            hook = "冰箱上贴着的赛程表上，下周有一场正式比赛——Dragon Force 的首秀。",
            icon = "📋", urgency = "mid",
        },
        -- P0: Victor 弧线渗透 (D8-D14)
        [8] = {
            scene = "深夜关门时，你注意到街对面有人影一闪。手机的闪光灯？",
            hook = "Victor 已经开始关注你了——明天，可能会有不速之客。",
            icon = "👁️", urgency = "high",
        },
        [9] = {
            scene = "手机推送弹出：'Gold Net Cafe 限时特惠——新客首周免费体验！'",
            hook = "价格战来了。你的常客在群里议论纷纷……明天怎么应对？",
            icon = "⚔️", urgency = "high",
        },
        [10] = {
            scene = "睡前刷了一下 Google Maps……你的网吧评分怎么降了？",
            hook = "五条一星差评，全是今天新注册的号。Victor 开始玩暗箭了。",
            icon = "🗣️", urgency = "high",
        },
        [11] = {
            scene = "收件箱亮着一封未读邮件——发件人：AEL 非洲电竞联赛秘书处。",
            hook = "正式预选赛的邀请……和 Victor 正面对决的日子，定了。",
            icon = "📧", urgency = "high",
        },
        [12] = {
            scene = "凌晨两点，有人拍你网吧的卷帘门。透过毛玻璃，一个高大的影子。",
            hook = "Victor 亲自来了。他站在你门口，不是挑衅的姿态——像是在打量猎物。",
            icon = "😈", urgency = "high",
        },
        [13] = {
            scene = "Victor 的话还回响在耳边：'你什么都没有。'",
            hook = "但队员们的眼神变了——不是恐惧，而是被点燃的战意。明天的训练会不一样。",
            icon = "🔥", urgency = "mid",
        },
        [14] = {
            scene = "深夜，你看到队员的手机屏幕上——是 Gold Net 的高薪招聘帖。",
            hook = "Victor 要挖人了。你的队员们……会动摇吗？",
            icon = "⚠️", urgency = "high",
        },
    }
    local narrativeHook = NARRATIVE_HOOKS[day]
    if narrativeHook then
        -- narrative 标记用于 UI 渲染时使用特殊样式
        table.insert(candidates, {
            text = narrativeHook.hook,
            urgency = narrativeHook.urgency,
            icon = narrativeHook.icon,
            narrative = true,
            scene = narrativeHook.scene,
        })
    end

    -- ── 0.5 状态条件悬念池（D15+ 动态叙事） ──
    -- D15-D30：聚焦竞争/市场/队伍成长
    local SUSPENSE_POOL_MID = {
        { cond = function() return (playerData_.reputation or 0) >= 150 and (playerData_.reputation or 0) < 300 end,
          scene = "收拾桌面时，你在一份旧报纸上看到了自己网吧的名字——",
          hook = "一篇本地博客写道：\"Dragon Net 正在崛起。\" Victor 看到了会怎么想？",
          icon = "📰", urgency = "high" },
        { cond = function() return #teamMembers_ >= 3 and #teamMembers_ < 5 end,
          scene = "训练结束，队员们三三两两聊着天……",
          hook = "Kofi 若有所思：\"老板，我们还差几个人就能打满编了。你有看中的人吗？\"",
          icon = "👥", urgency = "mid" },
        { cond = function() return (playerData_.equipCondition or 100) >= 90 and (playerData_.computers or 1) >= 6 end,
          scene = "夜深了，你巡视着整洁的网吧——每台电脑都擦得锃亮。",
          hook = "一封邮件静静躺在收件箱里：\"贵店有意成为三角洲行动官方体验店吗？\"",
          icon = "✉️", urgency = "high" },
        { cond = function() return (playerData_.goldOunces or 0) > 0 end,
          scene = "夜间新闻里，主播语速飞快——",
          hook = "\"受局势影响，西非黄金价格波动加剧……\" 你下意识摸了摸保险柜的钥匙。",
          icon = "📈", urgency = "mid" },
        { cond = function() return (playerData_.friendlyWins or 0) >= 5 end,
          scene = "邮箱里多了一封红色信封——AEL 非洲电竞联盟的 logo 烫金醒目。",
          hook = "\"鉴于贵战队近期优异表现，正式邀请参加 Tier-2 资格赛……\" 这是登上更大舞台的机会。",
          icon = "🏆", urgency = "high" },
        { cond = function() return (playerData_.money or 0) >= 5000 and #(playerData_.branches or {}) == 0 end,
          scene = "银行账户的数字已经积攒到了一个诱人的数字……",
          hook = "隔壁城市的中介打来电话：\"有个位置绝佳的铺面，要不要来看看？\" 扩张的时机到了？",
          icon = "🏪", urgency = "mid" },
        { cond = function() return (playerData_.tournamentPlayed or 0) >= 1 and (playerData_.tournamentWins or 0) == 0 end,
          scene = "上次锦标赛失利后，队员们沉默了好几天……",
          hook = "但今晚 Kofi 主动加练到了凌晨两点。\"下次，绝对不会再输了。\"",
          icon = "🔥", urgency = "mid" },
        { cond = function() return (playerData_.karma or 0) >= 10 end,
          scene = "路过集市时，好几个人主动和你打招呼——",
          hook = "\"Dragon Net 的老板！\" 一个陌生人跑来：\"我朋友说你人特别好——能不能帮个忙？\" 善名远扬，有人慕名而来。",
          icon = "🤝", urgency = "low" },
        { cond = function() return (playerData_.day or 1) >= 20 and (playerData_.netSpeed or 1) < 3 end,
          scene = "晚高峰时段，客人们的脸色越来越差——\"又卡了！\"",
          hook = "对面 Gold Net 门口排着队……Victor 新装了光纤。你的网速，还跟得上吗？",
          icon = "📡", urgency = "high" },
        { cond = function() return (playerData_.questStreak or 0) >= 5 end,
          scene = "手机弹出通知——电竞协会的特殊表彰。",
          hook = "\"连续完成 5 日委托的店主，可申请'金牌网吧'认证。\" 明天的委托，不能断。",
          icon = "🏅", urgency = "mid" },
        { cond = function()
              if #teamMembers_ == 0 then return false end
              for _, m in ipairs(teamMembers_) do
                  if (m.skill or 50) >= 85 then return true end
              end
              return false
          end,
          scene = "看着训练数据面板，有个数字格外亮眼——",
          hook = "你的王牌选手已经到了被挖墙脚的级别。据说 Victor 开出了双倍薪资……他会动摇吗？",
          icon = "⚠️", urgency = "high" },
        { cond = function() return (playerData_.generatorLevel or 0) == 0 and (playerData_.day or 1) >= 18 end,
          scene = "天气预报：明天多云转雷暴。",
          hook = "上次停电的损失还历历在目……发电机的报价单在抽屉里压了好久了。",
          icon = "⚡", urgency = "mid" },
    }

    -- D30+：聚焦帝国扩张/传奇叙事
    local SUSPENSE_POOL_LATE = {
        { cond = function() return #(playerData_.branches or {}) >= 1 end,
          scene = "视频通话里，分店经理神色紧张——",
          hook = "\"老板，隔壁开了家新网吧，价格比我们低三成……\" 你的帝国，需要守护。",
          icon = "🏙️", urgency = "high" },
        { cond = function() return (playerData_.reputation or 0) >= 500 end,
          scene = "一条来自首都的消息，让你沉默了许久……",
          hook = "\"非洲电竞联盟邀请您出任副理事——\" 从街边小店到行业领袖，这条路走得值。",
          icon = "👑", urgency = "high" },
        { cond = function() return (playerData_.tournamentWins or 0) >= 5 end,
          scene = "深夜刷到一条热搜：#DragonForce五冠王#",
          hook = "评论区有人说你是非洲电竞教父，也有人说只是运气好。下一场比赛，要证明什么？",
          icon = "🌟", urgency = "mid" },
        { cond = function() return #(playerData_.branches or {}) >= 3 end,
          scene = "财务报表上，五家店的数据汇成了一张复杂的网……",
          hook = "投资人发来一条语音：\"Dragon Net——该考虑上市了。\" 你笑着摇了摇头……还是先开下一家吧。",
          icon = "📊", urgency = "mid" },
        { cond = function()
              local gold = (playerData_.goldOunces or 0) * 1800
              return playerData_.money + gold >= 50000
          end,
          scene = "坐在办公室里，窗外是瓦坎达维尔的夜景。想起第一天来时只有5000美元……",
          hook = "电话响了——是老家的朋友。\"听说你在非洲当大老板了？带我一个啊！\" 你会怎么回答？",
          icon = "🌃", urgency = "low" },
        { cond = function() return (playerData_.reputation or 0) >= 300 and (playerData_.day or 1) >= 40 end,
          scene = "本地电视台的摄影师在门口架好了机器——",
          hook = "\"明天的'创业非洲'节目想采访您。准备好面对镜头了吗？\"",
          icon = "📺", urgency = "mid" },
        { cond = function() return (playerData_.day or 1) >= 35 and (playerData_.automationLevel or 0) >= 3 end,
          scene = "自动化系统汇报：今日营业正常，无需人工干预。",
          hook = "你有了更多时间……是继续扩张？还是享受一下成果？明天有一班飞往开普敦的航班。",
          icon = "✈️", urgency = "low" },
        { cond = function() return #teamMembers_ >= 5 and (playerData_.tournamentWins or 0) >= 3 end,
          scene = "队员们围坐在一起，屏幕上是 AEL 总决赛的直播——",
          hook = "\"明年，站在那个舞台上的会是我们。\" Kofi 的眼睛里闪着光。你信吗？",
          icon = "🎯", urgency = "high" },
        { cond = function() return (playerData_.day or 1) >= 50 end,
          scene = "翻开日历，不知不觉已经在非洲度过了五十天。",
          hook = "街口那棵大树下，有人在教小孩子打电竞。\"我要像 Dragon Force 一样厉害！\" 你在非洲种下的种子，正在发芽。",
          icon = "🌱", urgency = "low" },
        { cond = function()
              if #teamMembers_ == 0 then return false end
              local total = 0
              for _, m in ipairs(teamMembers_) do total = total + (m.mood or 50) end
              return (total / #teamMembers_) >= 85
          end,
          scene = "烧烤聚会上，队员们笑得比任何时候都开心——",
          hook = "Grace 举杯：\"老板，跟着你干——值了。\" 士气高涨，下一场硬仗不怕。",
          icon = "🍻", urgency = "mid" },
    }

    -- 根据 day 选择悬念池并从中随机抽取
    if day >= 15 and not narrativeHook then
        local pool = day >= 30 and SUSPENSE_POOL_LATE or SUSPENSE_POOL_MID
        -- 同时检查两个池（后期也能触发中期条件）
        local eligible = {}
        for _, entry in ipairs(pool) do
            local ok, result = pcall(entry.cond)
            if ok and result then
                table.insert(eligible, entry)
            end
        end
        -- D30+ 额外从 MID 池补充候选
        if day >= 30 then
            for _, entry in ipairs(SUSPENSE_POOL_MID) do
                local ok, result = pcall(entry.cond)
                if ok and result then
                    table.insert(eligible, entry)
                end
            end
        end
        -- 随机抽取1条作为 narrative 展示
        if #eligible > 0 then
            local pick = eligible[math.random(#eligible)]
            table.insert(candidates, {
                text = pick.hook,
                urgency = pick.urgency,
                icon = pick.icon,
                narrative = true,
                scene = pick.scene,
            })
        end
    end

    -- ── 1. 基于资金状况 ──
    local money = playerData_.money or 0
    local equipCondition = playerData_.equipCondition or 100
    -- 资金紧张警告
    local ok1, dailyExpResult = pcall(CalcDailyExpenses)
    local dailyExpense = 0
    if ok1 and type(dailyExpResult) == "table" then
        for _, e in ipairs(dailyExpResult) do dailyExpense = dailyExpense + (e.amount or 0) end
    elseif ok1 and type(dailyExpResult) == "number" then
        dailyExpense = dailyExpResult
    end
    if money < dailyExpense * 2 and dailyExpense > 0 then
        add("⚠️ 你的现金只剩 $" .. money .. "！明天的开销可能不够——考虑招揽更多客人或卖掉不急用的东西。", "high", "💸")
    elseif money < dailyExpense * 5 and dailyExpense > 0 then
        add("💰 现金储备偏低（$" .. money .. "），明天记得把收益先存好。", "mid", "💰")
    end

    -- ── 2. 设备状态警告 ──
    if equipCondition < 60 then
        add("🔧 设备状态告急（" .. equipCondition .. "%）！再不维护，明天客人投诉会更多、收入会下滑。", "high", "🔧")
    elseif equipCondition < 80 then
        add("🖥️ 设备状态 " .. equipCondition .. "%，建议明天去「升级」页面做一次维护。", "mid", "🔧")
    end

    -- ── 3. 目标链"差一步完成"提醒（直接引用权威 GOAL_CHAINS） ──
    for chainId, chain in pairs(GOAL_CHAINS) do
        local progress = playerData_.goalProgress and playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            -- 用 pcall 安全调用 check
            local ok, result = pcall(goal.check)
            if ok and not result then
                add("🎯 目标链进度：「" .. goal.desc .. "」——明天可能就能完成！别忘了去完成它。", "mid", "🎯")
            end
        end
    end

    -- ── 3.5 精英目标钩子（所有普通目标链完成后） ──
    if playerData_.goalProgress then
        local allDone = true
        local chainSizes = { develop = 10, social = 8, wealth = 8 }
        for chainId, size in pairs(chainSizes) do
            if (playerData_.goalProgress[chainId] or 1) <= size then
                allDone = false; break
            end
        end
        if allDone then
            local eIdx = playerData_.eliteGoalProgress or 1
            local ELITE_PREVIEW = {
                { icon = "🌍", title = "非洲知名",  desc = "声望达到 500" },
                { icon = "👑", title = "电竞王者",  desc = "赢得 10 场锦标赛" },
                { icon = "🏦", title = "百万富翁",  desc = "总资产超过 $100,000" },
                { icon = "🗺️", title = "大陆霸主",  desc = "拥有 5 家分店" },
                { icon = "🌐", title = "电竞传奇",  desc = "声望达到 1000" },
            }
            if eIdx <= #ELITE_PREVIEW then
                local eg = ELITE_PREVIEW[eIdx]
                add("🌟 精英目标挑战中：「" .. eg.title .. "」——" .. eg.desc .. "。你是真正的强者！", "high", "🌟")
            else
                add("🌟 所有精英目标已完成！你已是非洲电竞传奇，继续书写属于你的故事。", "high", "🌟")
            end
        end
    end

    -- ── 4. 队员心情预警 ──
    if #teamMembers_ > 0 then
        local lowMoodMembers = {}
        for _, m in ipairs(teamMembers_) do
            if (m.mood or 50) < 50 then
                table.insert(lowMoodMembers, m.name or "队员")
            end
        end
        if #lowMoodMembers > 0 then
            add("😟 " .. lowMoodMembers[1] .. (
                #lowMoodMembers > 1 and (" 等 " .. #lowMoodMembers .. " 人") or ""
            ) .. " 心情低落——明天记得去「经营」→团队互动一下！", "high", "❤️")
        end
    end

    -- ── 5. 周期大事件预告 ──
    local periodicPreview = Retention.GetPeriodicEventPreview(nextDay)
    if periodicPreview then
        add(periodicPreview, "mid", "📅")
    end

    -- ── 6. 里程碑预告 ──
    if nextDay == 5 then
        add("🎯 第5天！你的网吧该升一个档次了，现在存多少钱？", "mid", "🏁")
    elseif nextDay == 10 then
        add("⚠️ 第10天到了——货币贬值风险启动，考虑买一点黄金避险！", "high", "📈")
    elseif nextDay == 15 then
        add("🏆 半个月了！城市锦标赛解锁门槛：声望200 + T1赢3场。你达到了吗？", "mid", "🏆")
    elseif nextDay == 20 then
        add("🌟 第20天！竞争对手正在成长——去看看对手面板，不能让他们追上！", "mid", "⚔️")
    elseif nextDay == 30 then
        add("🎊 第30天！三角洲地区赛是你迄今最大的舞台——准备好了吗？", "high", "🎉")
    elseif nextDay % 10 == 0 then
        add("📅 第" .. nextDay .. "天里程碑！检查一下三条目标链的进度，有没有能一键完成的？", "low", "📅")
    end

    -- ── 7. NPC 剧情预告 ──
    local npcPreview = Retention.GetNPCStoryPreview(nextDay)
    if npcPreview then
        add(npcPreview, "low", "💬")
    end

    -- ── 8. 每日委托连击提示 ──
    local streak = playerData_.questStreak or 0
    if streak >= 2 then
        add("🔥 委托连击 x" .. streak .. "！明天继续完成每日委托，连击奖励越来越丰厚！", "mid", "🔥")
    end

    -- ── 9. 锦标赛解锁接近提示 ──
    local rep = playerData_.reputation or 0
    if rep >= 180 and rep < 200 and (playerData_.tierWins or {})[1] and playerData_.tierWins[1] >= 3 then
        add("🏅 再涨 " .. (200 - rep) .. " 点声望就能解锁「城市锦标赛」！明天全力刷声望！", "high", "🏅")
    end

    -- ── 排序：narrative 置顶 > urgency high > mid > low ──
    local urgencyOrder = { high = 1, mid = 2, low = 3 }
    table.sort(candidates, function(a, b)
        -- narrative 标记的条目永远排第一
        if a.narrative and not b.narrative then return true end
        if b.narrative and not a.narrative then return false end
        return (urgencyOrder[a.urgency] or 3) < (urgencyOrder[b.urgency] or 3)
    end)

    -- ── 保底：至少1条 ──
    if #candidates == 0 then
        local generic = {
            { text = "💰 明天又是赚钱的好机会，Dragon Net Cafe 的传说还在继续！", urgency = "low", icon = "☀️" },
            { text = "🎮 新的一天，新的挑战——Dragon Force，出发！", urgency = "low", icon = "🎮" },
            { text = "☀️ 非洲的阳光从不缺席，你的网吧也一样。把握明天！", urgency = "low", icon = "☀️" },
            { text = "🔥 竞争对手从不睡觉——你也不能懈怠，明天继续冲！", urgency = "low", icon = "🔥" },
        }
        table.insert(candidates, generic[math.random(#generic)])
    end

    -- ── 取前3条，提取 text 字段供弹窗渲染 ──
    local previews = {}
    for i = 1, math.min(3, #candidates) do
        table.insert(previews, candidates[i])
    end

    return previews
end

-- ============================================================================
-- 3. 离线收益系统
-- ============================================================================

--- 计算离线收益（金钱 + 哈弗币）— 接入 IdleEngine 自动化系统
---@param offlineSeconds number 离线秒数
---@return table|nil {earnings, havocCoins, hours, canDouble, autoLevel, perHour, daysAdvanced} 或 nil（不足5分钟）
function Retention.CalculateOfflineEarnings(offlineSeconds)
    -- 最少5分钟才触发
    if offlineSeconds < 300 then return nil end

    -- 获取当前经济数据
    local dailyIncome = 0
    local dailyExpense = 0
    local ok1, result1 = pcall(CalcDailyIncome)
    ---@diagnostic disable-next-line: assign-type-mismatch
    if ok1 then dailyIncome = result1 or 0 end
    if dailyIncome <= 0 then dailyIncome = (playerData_.computers or 1) * 20 end
    local ok2, result2 = pcall(CalcDailyExpenses)
    if ok2 and type(result2) == "table" then
        for _, e in ipairs(result2) do dailyExpense = dailyExpense + (e.amount or 0) end
    elseif ok2 and type(result2) == "number" then
        dailyExpense = result2
    end

    local autoLevel = playerData_.automationLevel or 0
    local prestigeMulti = PrestigeSystem.CalcPrestigeMultiplier()

    -- 使用 IdleEngine 计算离线收益（自动化等级决定收益率）
    local total, rawHours, perHour, cappedHours =
        ---@diagnostic disable-next-line: param-type-mismatch
        IdleEngine.CalcOfflineEarnings(offlineSeconds, dailyIncome, dailyExpense, autoLevel, prestigeMulti)

    -- Lv0 帮工小弟已给基础8%离线收益，如果依然为0（日收入极低），给最低保底
    if total <= 0 then
        local hours = math.min(4, offlineSeconds / 3600)
        total = math.max(5, math.floor((playerData_.computers or 1) * 2 * hours))
        perHour = math.max(1, math.floor(total / math.max(1, hours)))
        cappedHours = hours
    end

    -- 哈弗币：每小时基础 5 币 + 电脑加成 + 自动化等级加成
    local havocRate = 5 + math.floor((playerData_.computers or 1) * 0.5) + autoLevel * 2
    local havocCoins = math.max(3, math.floor(havocRate * cappedHours))

    -- 离线天数推进（超过24小时时模拟多天结算）
    local daysAdvanced = 0
    if autoLevel >= 2 and rawHours >= 24 then
        daysAdvanced, _ = IdleEngine.SimulateOfflineDays(rawHours, dailyIncome, dailyExpense, autoLevel, prestigeMulti)
        if daysAdvanced > 0 then
            playerData_.day = playerData_.day + daysAdvanced
        end
    end

    return {
        earnings = total,
        havocCoins = havocCoins,
        hours = math.floor(cappedHours * 10) / 10,
        canDouble = true,
        autoLevel = autoLevel,
        perHour = perHour,
        daysAdvanced = daysAdvanced,
    }
end

--- 领取离线收益（金钱 + 哈弗币）
---@param doubled boolean 是否通过广告翻倍
function Retention.ClaimOfflineEarnings(doubled)
    if not pendingOfflineReward_ then return end
    local earnings = pendingOfflineReward_.earnings
    local havocCoins = pendingOfflineReward_.havocCoins or 0
    if doubled then
        earnings = earnings * 2
        havocCoins = havocCoins * 2
    end
    playerData_.money = playerData_.money + earnings
    playerData_.havocCoins = (playerData_.havocCoins or 0) + havocCoins
    local coinMsg = havocCoins > 0 and (" +💎" .. havocCoins) or ""
    AddLog("💤 离线收益: +$" .. earnings .. coinMsg .. (doubled and " (广告翻倍!)" or ""))
    pendingOfflineReward_ = nil
end

-- ============================================================================
-- 4. 目标链系统
-- ============================================================================

--- 3条目标链定义（赋值给顶部前向声明的 local）
GOAL_CHAINS = {
    develop = {
        name = "🏗️ 发展之路",
        goals = {
            { id = "d1", desc = "拥有 4 台电脑", reward = { money = 100, rep = 5 },
              check = function() return playerData_.computers >= 4 end },
            { id = "d2", desc = "升级网速到 Lv2", reward = { money = 150, rep = 8 },
              check = function() return playerData_.netSpeed >= 2 end },
            { id = "d3", desc = "招募第一个队员", reward = { money = 200, rep = 10 },
              check = function() return #teamMembers_ >= 1 end },
            { id = "d4", desc = "声望达到 50", reward = { money = 200, rep = 0 },
              check = function() return playerData_.reputation >= 50 end },
            { id = "d5", desc = "拥有 6 台电脑", reward = { money = 300, rep = 15 },
              check = function() return playerData_.computers >= 6 end },
            { id = "d6", desc = "安装空调", reward = { money = 200, rep = 10 },
              check = function() return playerData_.acLevel >= 1 end },
            { id = "d7", desc = "赢得一场友谊赛", reward = { money = 300, rep = 20 },
              check = function() return playerData_.friendlyWins >= 1 end },
            { id = "d8", desc = "声望达到 200", reward = { money = 500, rep = 0 },
              check = function() return playerData_.reputation >= 200 end },
            { id = "d9", desc = "拥有 10 台电脑", reward = { money = 800, rep = 30 },
              check = function() return playerData_.computers >= 10 end },
            { id = "d10", desc = "开设第一家分店", reward = { money = 1500, rep = 50 },
              check = function() return #(playerData_.branches or {}) >= 1 end },
        },
    },
    social = {
        name = "👥 社交之路",
        goals = {
            { id = "s1", desc = "完成 1 次每日委托", reward = { money = 80, rep = 5 },
              check = function() return (playerData_.totalRuns or 0) >= 1 or (playerData_.friendlyWins or 0) >= 1 end },
            { id = "s2", desc = "招募 2 个队员", reward = { money = 150, rep = 10 },
              check = function() return #teamMembers_ >= 2 end },
            { id = "s3", desc = "团队平均好感 ≥ 70", reward = { money = 200, rep = 15 },
              check = function()
                  if #teamMembers_ == 0 then return false end
                  local total = 0
                  for _, m in ipairs(teamMembers_) do total = total + (m.mood or 50) end
                  return (total / #teamMembers_) >= 70
              end },
            { id = "s4", desc = "招募 3 个队员", reward = { money = 300, rep = 15 },
              check = function() return #teamMembers_ >= 3 end },
            { id = "s5", desc = "赢得 3 场友谊赛", reward = { money = 300, rep = 20 },
              check = function() return playerData_.friendlyWins >= 3 end },
            { id = "s6", desc = "组建满编 5 人战队", reward = { money = 500, rep = 30 },
              check = function() return #teamMembers_ >= 5 end },
            { id = "s7", desc = "参加一次锦标赛", reward = { money = 500, rep = 25 },
              check = function() return (playerData_.tournamentPlayed or 0) >= 1 end },
            { id = "s8", desc = "赢得锦标赛冠军", reward = { money = 1000, rep = 50 },
              check = function() return (playerData_.tournamentWins or 0) >= 1 end },
        },
    },
    wealth = {
        name = "💰 财富之路",
        goals = {
            { id = "w1", desc = "累计赚取 $3,000", reward = { money = 100, rep = 5 },
              check = function() return (playerData_.totalEarnings or 0) >= 3000 end },
            { id = "w2", desc = "持有 $2,000 现金", reward = { money = 0, rep = 10 },
              check = function() return playerData_.money >= 2000 end },
            { id = "w3", desc = "开设烤鸡摊", reward = { money = 100, rep = 8 },
              check = function() return playerData_.foodShop >= 1 end },
            { id = "w4", desc = "累计赚取 $8,000", reward = { money = 200, rep = 10 },
              check = function() return (playerData_.totalEarnings or 0) >= 8000 end },
            { id = "w5", desc = "购买黄金", reward = { money = 0, rep = 15 },
              check = function() return (playerData_.goldOunces or 0) > 0 end },
            { id = "w6", desc = "购买黄金保险箱", reward = { money = 300, rep = 15 },
              check = function() return playerData_.goldSafe == true end },
            { id = "w7", desc = "累计赚取 $20,000", reward = { money = 500, rep = 25 },
              check = function() return (playerData_.totalEarnings or 0) >= 20000 end },
            { id = "w8", desc = "总资产超过 $50,000", reward = { money = 1000, rep = 50 },
              check = function()
                  local gold = (playerData_.goldOunces or 0) * 1800
                  return playerData_.money + gold >= 50000
              end },
        },
    },
}

--- 检查目标链进度，自动推进并发放奖励
---@return table|nil 刚完成的目标 {chain, goal, reward}
function Retention.CheckGoalProgress()
    local completed = {}
    for chainId, chain in pairs(GOAL_CHAINS) do
        local progress = (playerData_.goalProgress and playerData_.goalProgress[chainId]) or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            if goal.check() then
                -- 标记完成
                playerData_.goalCompleted = playerData_.goalCompleted or {}
                playerData_.goalCompleted[goal.id] = true
                playerData_.goalProgress = playerData_.goalProgress or { develop = 1, social = 1, wealth = 1 }
                playerData_.goalProgress[chainId] = progress + 1
                -- 发放奖励
                if goal.reward.money > 0 then
                    playerData_.money = playerData_.money + goal.reward.money
                end
                if goal.reward.rep > 0 then
                    playerData_.reputation = playerData_.reputation + goal.reward.rep
                end
                AddLog("🎯 目标完成: " .. goal.desc .. " → +$" .. goal.reward.money .. " +声望" .. goal.reward.rep)
                table.insert(completed, { chain = chain.name, goal = goal })
                PlaySFX("victory")
            end
        end
    end
    if #completed > 0 then TriggerCelebration() end
    return #completed > 0 and completed or nil
end

--- 获取当前目标概览（用于UI显示）
---@return table 各链当前目标 { {chainName, goalDesc, progress, total, reward} }
function Retention.GetCurrentGoals()
    local result = {}
    for _, chainId in ipairs({"develop", "social", "wealth"}) do
        local chain = GOAL_CHAINS[chainId]
        local progress = playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            table.insert(result, {
                chainId = chainId,
                chainName = chain.name,
                goalDesc = goal.desc,
                progress = progress,
                total = #goals,
                rewardMoney = goal.reward.money,
                rewardRep = goal.reward.rep,
            })
        else
            table.insert(result, {
                chainId = chainId,
                chainName = chain.name,
                goalDesc = "全部完成！",
                progress = #goals,
                total = #goals,
                rewardMoney = 0,
                rewardRep = 0,
                done = true,
            })
        end
    end
    return result
end

--- 获取目标链预告（用于明日预告）
function Retention.GetGoalPreview()
    for _, chainId in ipairs({"develop", "social", "wealth"}) do
        local chain = GOAL_CHAINS[chainId]
        local progress = playerData_.goalProgress[chainId] or 1
        local goals = chain.goals
        if progress <= #goals then
            local goal = goals[progress]
            -- 简单检查是否"接近完成"
            if goal.check and not goal.check() then
                return "🎯 当前目标: " .. goal.desc .. " — 继续努力！"
            end
        end
    end
    return nil
end

-- ============================================================================
-- 5. 周期性大事件
-- ============================================================================

local PERIODIC_EVENTS = {
    {
        id = "africa_cup",
        name = "⚽ 非洲杯足球赛",
        interval = 7,    -- 每7天触发
        duration = 2,     -- 持续2天
        minDay = 5,       -- 最早第5天开始
        desc = "非洲杯比赛期间！球迷们蜂拥到网吧看直播，客流暴涨！",
        effect = function()
            trafficBonus_ = trafficBonus_ + 8
        end,
        dailyEffect = function()
            trafficBonus_ = trafficBonus_ + 8
        end,
        endEffect = function()
            AddLog("⚽ 非洲杯结束了，客流恢复正常。")
        end,
        preview = "⚽ 非洲杯足球赛即将到来！客流将暴涨！",
    },
    {
        id = "power_week",
        name = "⚡ 停电高发期",
        interval = 10,   -- 每10天触发
        duration = 2,
        minDay = 8,
        desc = "电网检修期间频繁停电！有发电机的网吧能逆势赚钱！",
        effect = function()
            if playerData_.generatorLevel > 0 then
                AddLog("⚡ 别人停电你发电！竞争对手都关门了，客流大增！")
                trafficBonus_ = trafficBonus_ + 10
                playerData_.reputation = playerData_.reputation + 5
            else
                AddLog("⚡ 停电了！没有发电机，今天亏损严重......")
                playerData_.money = playerData_.money - math.floor(playerData_.money * 0.05)
            end
        end,
        dailyEffect = function()
            if playerData_.generatorLevel > 0 then
                trafficBonus_ = trafficBonus_ + 10
            else
                playerData_.money = playerData_.money - math.floor(playerData_.money * 0.03)
            end
        end,
        endEffect = function()
            AddLog("⚡ 电网恢复正常供电。")
        end,
        preview = "⚡ 停电高发期将至——快检查发电机！",
    },
    {
        id = "gold_rush",
        name = "📈 黄金狂潮",
        interval = 14,   -- 每14天触发
        duration = 3,
        minDay = 12,
        desc = "国际金价暴涨！持有黄金的人赚翻了！",
        effect = function()
            local gold = playerData_.goldOunces or 0
            if gold > 0 then
                local bonus = math.floor(gold * 300)
                playerData_.money = playerData_.money + bonus
                AddLog("📈 黄金狂潮！你持有的 " .. string.format("%.1f", gold) .. " 盎司升值了 +$" .. bonus .. "！")
            else
                AddLog("📈 黄金狂潮到来！可惜你没有持有黄金......考虑买入？")
            end
        end,
        dailyEffect = function() end,
        endEffect = function()
            AddLog("📈 黄金价格回落到正常水平。")
        end,
        preview = "📈 黄金狂潮将至——手上有金子吗？",
    },
    {
        id = "delta_menggong",
        name = "🔥 三角洲猛攻节",
        interval = 12,   -- 每12天触发
        duration = 3,     -- 持续3天
        minDay = 10,
        desc = "三角洲行动推出猛攻节活动，日活突破5000万！全非洲的网吧都挤满了人！",
        effect = function()
            trafficBonus_ = trafficBonus_ + 12
            AddLog("🔥 猛攻节开幕！'猛攻不被定义'刷屏了！客流暴涨，代练订单也爆了！")
        end,
        dailyEffect = function()
            trafficBonus_ = trafficBonus_ + 12
            -- 猛攻节期间每天有额外代练收入
            local bonus = 30 + math.random(0, 40)
            playerData_.money = playerData_.money + bonus
            playerData_.havocCoins = playerData_.havocCoins + math.random(20, 50)
            AddLog("🔥 猛攻节持续中！代练订单不断，额外收入 +$" .. bonus)
        end,
        endEffect = function()
            playerData_.reputation = playerData_.reputation + 10
            AddLog("🔥 猛攻节结束了！你的网吧在活动期间赚得盆满钵满，声望+10。")
        end,
        preview = "🔥 三角洲猛攻节即将到来——备好设备，客流要爆了！",
    },
    {
        id = "esport_league",
        name = "🏆 网吧联赛周",
        interval = 21,   -- 每21天触发
        duration = 3,
        minDay = 15,
        desc = "全非洲网吧联赛开赛！比赛奖励翻倍，声望加速积累！",
        effect = function()
            playerData_.reputation = playerData_.reputation + 15
            AddLog("🏆 网吧联赛开幕！比赛奖励翻倍，声望获取加速！")
        end,
        dailyEffect = function()
            playerData_.reputation = playerData_.reputation + 5
        end,
        endEffect = function()
            AddLog("🏆 网吧联赛圆满结束！")
        end,
        preview = "🏆 网吧联赛周即将开始——准备好参赛了吗？",
    },
}

--- 检查并触发周期性大事件
---@param day number 当前天数
---@return string|nil 触发的事件名称
function Retention.CheckPeriodicEvents(day)
    -- 先处理进行中的事件
    local active = playerData_.activePeriodicEvent
    if active then
        active.remainDays = active.remainDays - 1
        if active.remainDays <= 0 then
            -- 事件结束
            for _, pe in ipairs(PERIODIC_EVENTS) do
                if pe.id == active.id and pe.endEffect then
                    pcall(pe.endEffect)
                end
            end
            playerData_.activePeriodicEvent = nil
        else
            -- 事件持续中，应用每日效果
            for _, pe in ipairs(PERIODIC_EVENTS) do
                if pe.id == active.id and pe.dailyEffect then
                    pcall(pe.dailyEffect)
                end
            end
            return active.id
        end
    end

    -- 检查是否有新事件触发
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if day >= pe.minDay then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            if day - lastDay >= pe.interval then
                -- 触发！
                playerData_.activePeriodicEvent = {
                    id = pe.id,
                    name = pe.name,
                    remainDays = pe.duration,
                    desc = pe.desc,
                }
                if not playerData_.lastPeriodicDay then playerData_.lastPeriodicDay = {} end
                playerData_.lastPeriodicDay[pe.id] = day
                AddLog(pe.name .. " 开始了！" .. pe.desc)
                if pe.effect then pcall(pe.effect) end
                return pe.id
            end
        end
    end
    return nil
end

--- 获取周期事件预告（用于明日预告）
function Retention.GetPeriodicEventPreview(nextDay)
    -- 检查是否有事件即将触发
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if nextDay >= pe.minDay then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            local daysSince = nextDay - lastDay
            if daysSince == pe.interval then
                return pe.preview
            elseif daysSince >= pe.interval - 2 and daysSince < pe.interval then
                local daysLeft = pe.interval - daysSince
                return pe.name .. " " .. daysLeft .. " 天后到来！"
            end
        end
    end
    return nil
end

--- 获取当前活跃的周期事件信息（用于UI显示）
---@return table|nil {name, desc, remainDays}
function Retention.GetActivePeriodicEvent()
    return playerData_.activePeriodicEvent
end

--- 获取下一个即将到来的周期事件（用于UI倒计时）
---@param day number 当前天数
---@return table|nil {name, daysUntil}
function Retention.GetNextPeriodicEvent(day)
    local closest = nil
    local closestDays = 999
    for _, pe in ipairs(PERIODIC_EVENTS) do
        if day >= (pe.minDay - 3) then
            local lastDay = (playerData_.lastPeriodicDay or {})[pe.id] or 0
            local nextTrigger = lastDay + pe.interval
            ---@diagnostic disable-next-line: assign-type-mismatch
            if nextTrigger <= day then nextTrigger = day + pe.interval - ((day - lastDay) % pe.interval) end
            local daysUntil = nextTrigger - day
            if daysUntil > 0 and daysUntil < closestDays then
                closestDays = daysUntil
                closest = { name = pe.name, daysUntil = daysUntil }
            end
        end
    end
    return closest
end

--- NPC 剧情预告占位（由 NPCStorylines 模块填充）
function Retention.GetNPCStoryPreview(nextDay)
    if NPCStorylines and NPCStorylines.GetPreview then
        return NPCStorylines.GetPreview(nextDay)
    end
    return nil
end

-- ============================================================================
-- 8. P0-B 今日任务清单（每日冷启动汇总）
-- ============================================================================

--- 构建「今日任务清单」数据，在每天开始时展示给玩家
--- 返回 nil 表示不需要弹出（Day 1-4 跳过，避免和新手引导冲突）
---@param day number 当前天数
---@return table|nil  包含 day/quest/goal/event/team/offlineHint 的汇总数据
function Retention.BuildDayStartSummary(day)
    -- Day 1-4 由新手引导处理，不叠加任务清单弹窗
    if day < 5 then return nil end

    local summary = {
        day      = day,
        quest    = nil,   -- 今日委托 { icon, desc, goal, reward }
        goal     = nil,   -- 当前目标链最近一条任务 { chain, desc, progress_pct }
        event    = nil,   -- 今日特别行动 { icon, title, desc }
        teamWarn = nil,   -- 低心情队员警告 "Kofi(30%) / Grace(25%)"
        streak   = 0,     -- 连续完成委托天数
    }

    -- ① 今日委托（功能已暂停）

    -- ② 当前目标链进度——直接复用 GetCurrentGoals() 保证数据与 GOAL_CHAINS 同步
    local currentGoals = Retention.GetCurrentGoals()
    for _, g in ipairs(currentGoals or {}) do
        if not g.done then
            local pct = g.total > 0 and math.floor((g.progress - 1) / g.total * 100) or 0
            summary.goal = {
                chain      = g.chainName,
                chainId    = g.chainId,
                desc       = g.goalDesc,
                stepNum    = g.progress,
                totalSteps = g.total,
                pct        = pct,
            }
            break  -- 只展示最优先的一条未完成目标
        end
    end

    -- ③ 今日特别行动
    if dailySpecialEvent_ then
        summary.event = {
            icon  = dailySpecialEvent_.icon  or "✨",
            title = dailySpecialEvent_.title or "今日行动",
            desc  = dailySpecialEvent_.desc  or "",
        }
    end

    -- ④ 低心情队员警告
    if #teamMembers_ > 0 then
        local warns = {}
        for _, m in ipairs(teamMembers_) do
            if (m.mood or 50) < 40 then
                table.insert(warns, (m.name or "?") .. "(" .. (m.mood or 0) .. "%)")
            end
        end
        if #warns > 0 then
            summary.teamWarn = table.concat(warns, " / ")
        end
    end

    return summary
end

-- ============================================================================
-- 9. P2-B 精英目标（3条目标链全部完成后接档）
-- ============================================================================

--- 精英目标定义（按难度递进，玩家依次解锁）
local ELITE_GOALS = {
    { id = "eg1",  icon = "🌍", title = "非洲知名",
      desc  = "声望达到 500",
      reward = { money = 2000, rep = 0 },
      check = function() return (playerData_.reputation or 0) >= 500 end },
    { id = "eg2",  icon = "👑", title = "电竞王者",
      desc  = "赢得 10 场锦标赛",
      reward = { money = 3000, rep = 100 },
      check = function() return (playerData_.tournamentWins or 0) >= 10 end },
    { id = "eg3",  icon = "🏦", title = "百万富翁",
      desc  = "总资产（现金+黄金）超过 $100,000",
      reward = { money = 5000, rep = 150 },
      check = function()
          local gold = (playerData_.goldOunces or 0) * 1800
          return playerData_.money + gold >= 100000
      end },
    { id = "eg4",  icon = "🗺️", title = "大陆霸主",
      desc  = "拥有 5 家分店",
      reward = { money = 8000, rep = 200 },
      check = function() return #(playerData_.branches or {}) >= 5 end },
    { id = "eg5",  icon = "🌐", title = "电竞传奇",
      desc  = "声望达到 1000",
      reward = { money = 10000, rep = 0 },
      check = function() return (playerData_.reputation or 0) >= 1000 end },
}

--- 检查是否所有3条普通目标链都已完成
local function AllChainsCompleted()
    if not playerData_.goalProgress then return false end
    local chainSizes = { develop = 10, social = 8, wealth = 8 }
    for chainId, size in pairs(chainSizes) do
        local progress = playerData_.goalProgress[chainId] or 1
        if progress <= size then return false end
    end
    return true
end

--- 检查精英目标进度，推进并发放奖励
--- 仅在所有普通目标链完成后激活
---@return table|nil 刚完成的精英目标列表
function Retention.CheckEliteGoals()
    if not AllChainsCompleted() then return nil end
    playerData_.eliteGoalProgress = playerData_.eliteGoalProgress or 1

    local idx = playerData_.eliteGoalProgress
    if idx > #ELITE_GOALS then return nil end  -- 全部精英目标完成

    local goal = ELITE_GOALS[idx]
    local ok, result = pcall(goal.check)
    if not ok or not result then return nil end

    -- 完成！推进进度
    playerData_.eliteGoalProgress = idx + 1
    playerData_.eliteGoalCompleted = playerData_.eliteGoalCompleted or {}
    playerData_.eliteGoalCompleted[goal.id] = true

    -- 发放奖励
    if goal.reward.money and goal.reward.money > 0 then
        playerData_.money = playerData_.money + goal.reward.money
    end
    if goal.reward.rep and goal.reward.rep > 0 then
        playerData_.reputation = (playerData_.reputation or 0) + goal.reward.rep
    end

    AddLog("🌟 精英目标完成：「" .. goal.title .. "」 → +$" .. (goal.reward.money or 0)
        .. (goal.reward.rep > 0 and (" +声望" .. goal.reward.rep) or ""))
    TriggerCelebration()

    return { goal }
end

--- 获取当前精英目标（用于 UI 展示）
---@return table|nil { idx, total, icon, title, desc, reward, active }
function Retention.GetCurrentEliteGoal()
    if not AllChainsCompleted() then return nil end
    playerData_.eliteGoalProgress = playerData_.eliteGoalProgress or 1
    local idx = playerData_.eliteGoalProgress
    if idx > #ELITE_GOALS then
        return { idx = idx, total = #ELITE_GOALS, done = true,
                 title = "传奇已成", desc = "所有精英目标已完成，你是真正的传奇！" }
    end
    local goal = ELITE_GOALS[idx]
    return {
        idx    = idx,
        total  = #ELITE_GOALS,
        id     = goal.id,
        icon   = goal.icon,
        title  = goal.title,
        desc   = goal.desc,
        reward = goal.reward,
        done   = false,
    }
end

return Retention
