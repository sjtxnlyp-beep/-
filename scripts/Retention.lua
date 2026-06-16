---@diagnostic disable: undefined-global
-- ============================================================================
-- Retention.lua — 留存系统核心模块
-- 包含：新手引导 / 明日预告 / 离线收益 / 目标链 / 周期性大事件
-- ============================================================================

local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")
local NPCStorylines = require("NPCStorylines")
local ProgressiveUnlock = require("ProgressiveUnlock")

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
            id = "tut_first_evening", category = "social", rarity = "common",
            title = "🌆 第一天的黄昏",
            desc = "太阳快落山了，街上飘来烤玉米的香味。隔壁杂货店老板娘 Ama 端来一碗花生汤：\n\n\"新来的，第一天辛苦了。我们这条街的规矩——邻居开张第一天，得送碗汤。\"\n\n她看了看你的网吧：\"不错，收拾得挺干净。有什么需要帮忙的，吱一声。\"",
            type = "choice",
            choices = {
                { text = "🙏 \"太感谢了！以后有空来免费上网\"",
                  effect = function() playerData_.reputation = playerData_.reputation + 3; playerData_.karma = (playerData_.karma or 0) + 1 end,
                  result = function() return "Ama 笑了：\"我可不会上网，但我侄子天天缠着我要去网吧。以后让他来你这里，我放心。\"\n\n第一天就有了一个善意的邻居。这条街，也许没那么陌生。\n\n💡 提示：邻里关系很重要，好的街坊能在关键时刻帮你大忙！" end },
                { text = "😊 接过汤，礼貌道谢",
                  effect = function() playerData_.karma = (playerData_.karma or 0) + 1 end,
                  result = function() return "你端着热汤坐在门口喝完。Ama 回去了，但临走说了句：\"这条街的人都不错，就是……对面那个空铺面，听说有人盯上了。\"\n\n她没多说。你记下了这句话。\n\n💡 提示：注意周围环境的变化，有些事情会在未来几天慢慢浮出水面。" end },
            },
        },
    },
    -- ═══ P2: Day2 —— 电费房租压力，经营抉择 ═══
    [2] = {
        {
            id = "p2_power_crisis", category = "business", rarity = "common",
            image = "image/day2_rent_crisis_20260615054239.png",
            title = "⚡ 电费和房租的双重暴击",
            desc = "一大早，房东 Musa 的儿子拍着门喊：\"月底到了！房租 $150，水电 $80，今天不交就锁门！\"\n\n你翻了翻口袋，昨天刚赚的钱还热乎着。这一刀下去，可能连明天的网费都交不起。\n\n更糟糕的是——隔壁传来发电机的轰鸣声。这个街区经常停电，而你连发电机都没有。",
            type = "choice",
            choices = {
                { text = "💰 硬扛：全额交租，先活下来", hint = "现金-$230 · 安全经营",
                  ethics = { moneyVsPeople = -1 },
                  effect = function() playerData_.money = playerData_.money - 230; AddLog("💸 交了租金 $230，口袋空了但不用搬家。") end,
                  result = function() return "Musa 的儿子数完钱点了点头。\"下月准时啊。\"\n\n你松了口气，但看着见底的钱包发愁——得多贴几张传单了。" end },
                { text = "🔧 投资：花 $180 买二手发电机", hint = "现金-$180 · 停电不怕 · 欠租风险",
                  ethics = { resultVsProcess = 1 },
                  effect = function()
                      playerData_.money = playerData_.money - 180
                      playerData_.hasGenerator = true
                      AddLog("🔧 买了发电机！以后停电也不怕了。但房租......先欠着？")
                  end,
                  result = function() return "你扛着一台二手发电机回来，满头大汗。邻居投来羡慕的目光。\n\n但 Musa 的儿子还会回来的。你跟他说'下周补上'，他没说话，只是看了你一眼。\n\n💡 发电机已获得！停电时也能正常营业了。" end },
                { text = "🤝 赊账：找邻居杂货店老板娘借 $100", hint = "人情债+1 · 缓解压力 · 欠人情",
                  ethics = { integrationVsExtraction = 1 },
                  effect = function()
                      playerData_.money = playerData_.money - 130
                      playerData_.karma = (playerData_.karma or 0) + 1
                      playerData_.neighborDebt = (playerData_.neighborDebt or 0) + 100
                      AddLog("🤝 邻居借了 $100，人情债要还的。先交了 $130 给 Musa。")
                  end,
                  result = function() return "杂货店老板娘 Ama 把钱递给你时叹了口气：\"新来的都不容易。下个月还我就行，不急。\"\n\n你交了 $130 给 Musa（先还一部分），剩下的下次补。欠着人情，但至少今天能安心开门了。\n\n💡 欠邻居 $100，记得还。" end },
            },
        },
    },
    -- ═══ P2: Day3 —— Kofi 影子：顾客议论中的天才 ═══
    [3] = {
        {
            id = "p2_kofi_shadow", category = "social", rarity = "common",
            image = "image/day3_kofi_shadow_20260615054416.png",
            title = "👀 角落里的传说",
            desc = "打烊前整理电脑时，你发现角落那台最旧的机器有异常——\n\n屏幕上还留着一个三角洲行动的战绩页面：14杀3死，MVP。用这台帧率不到30的破机器？\n\n旁边的常客 Kwame 凑过来：\"老板你不知道吗？下午有个穿校服的瘦高少年偷偷进来的，没买时间就坐那打了半小时。我们几个围着看的——那手速，不是正常人。\"\n\n桌上还留着一副旧耳机和一张欠费条：\"Kofi · 应付 $3\"。\n\n你在心里记下了这个名字。明天他可能还会来——怎么处理？",
            type = "choice",
            choices = {
                { text = "🎁 给他留一小时免费机时", hint = "现金机会-$3 · 关系/信任倾向+",
                  ethics = { moneyVsPeople = 1 },
                  effect = function()
                      playerData_.kofiMet = true
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 2
                      AddLog("🎁 你在角落机器上贴了张条：\"Kofi——明天有一小时免费。\" 希望他看得到。")
                  end,
                  result = function() return "你撕了那张欠费条，在键盘上贴了张小纸条：\"Kofi——明天来找老板，有一小时免费。\"\n\nKwame 看着你笑了：\"老板你心善。那小子家里穷，但手上功夫是真的。\"\n\n💡 埋下线索：如果 Kofi 明天来了，你的善意可能改变他的人生轨迹。" end },
                { text = "💰 先按正常收费，欠了就要还", hint = "现金+$3 · Kofi 信任机会↓",
                  ethics = { moneyVsPeople = -1 },
                  effect = function()
                      playerData_.kofiMet = true
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) - 1
                      playerData_.money = playerData_.money + 3
                      AddLog("💰 你把欠费条留着了。规矩就是规矩，天才也得付钱。")
                  end,
                  result = function() return "你把那张欠费条整整齐齐夹进账本。$3 不多，但规矩就是规矩。\n\nKwame 耸耸肩：\"也是，做生意哪有免费的。不过那小子可能不敢来了。\"\n\n你看了眼那个 14 杀的战绩，心里有点犹豫。但生意就是生意。\n\n⚠️ Kofi 信任度降低。他可能更不敢接触你。" end },
            },
        },
    },
    -- ═══ P2: Day4 —— 街区信任事件 ═══
    [4] = {
        {
            id = "p2_community_trust", category = "social", rarity = "common",
            image = "image/day4_community_trust_20260615054415.png",
            title = "🏘️ 街区规矩",
            desc = "傍晚打烊时，对面五金店的 Kwaku 老板带着三个街坊找上门。\n\n\"兄弟，我们这条街有个规矩——新来的要请大家喝一轮。不是什么大钱，就是个意思。让大家知道你不是来捞一票就跑的。\"\n\n他看了看你的网吧：\"或者……你也可以帮社区做点事。前面学校的电脑坏了半年了，没人会修。\"",
            type = "choice",
            choices = {
                { text = "🍺 请一轮：花 $60 请街坊喝酒", hint = "现金-$60 · 街区好感大增",
                  ethics = { integrationVsExtraction = 2 },
                  effect = function()
                      playerData_.money = playerData_.money - 60
                      playerData_.reputation = playerData_.reputation + 10
                      playerData_.karma = (playerData_.karma or 0) + 2
                      AddLog("🍺 请了街坊一轮酒，大家拍着你肩膀说'自己人'。")
                  end,
                  result = function() return "晚上在街角的小酒馆，你请了十来个人喝了一轮。Kwaku 举杯：\"从今天起，Dragon Net 就是我们街的一份子！\"\n\n有人开始叫你\"中国老板\"，语气里带着亲切。\n\n💡 街区信任提升！未来可能获得邻居帮助。" end },
                { text = "🔧 帮学校修电脑（花半天时间）", hint = "AP-1 · 长期口碑 · 学生客源",
                  ethics = { integrationVsExtraction = 2, moneyVsPeople = 1 },
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 12
                      playerData_.karma = (playerData_.karma or 0) + 3
                      AddLog("🔧 花了半天去学校修电脑。校长握着你的手说会介绍学生来上网。")
                  end,
                  result = function() return "你扛着工具箱去了学校。六台旧电脑，有的只是灰尘堵了风扇，有的要换内存条。\n\n忙了半天，孩子们围着你叽叽喳喳。校长激动地握着你的手：\"我会让学生们放学后来你那里做作业！\"\n\n💡 街区信任大幅提升！学校客源 +1" end },
                { text = "💼 \"我就做生意，不搞社交\"", hint = "省钱 · 街区关系冷淡",
                  ethics = { integrationVsExtraction = -2 },
                  effect = function()
                      playerData_.reputation = playerData_.reputation - 3
                      AddLog("💼 你婉拒了。Kwaku 看了你一眼，没说什么就走了。")
                  end,
                  result = function() return "Kwaku 点了点头，带着人走了。你听到门外有人低声说：\"又一个只想赚钱的外国人。\"\n\n你关上门，觉得这没什么。但第二天，原本会打招呼的邻居开始对你视而不见了。\n\n⚠️ 街区关系冷淡。未来遇到麻烦时，没人会帮你。" end },
            },
        },
    },
    -- ═══ P2: Day5 —— Kofi 正式登场，建立信任 ═══
    [5] = {
        {
            id = "p2_kofi_arrives", category = "social", rarity = "rare",
            title = "🧑🏿 Kofi 来了",
            desc = "下午三点，那个少年又出现在门口。这次他没有偷偷摸摸，而是规规矩矩站在柜台前。\n\n\"老板……我叫 Kofi。前天被你看到了。\" 他搓着手，很紧张。\"我知道没买时间就碰电脑不对，对不起。\"\n\n停了一下：\"但是……我是真的想打职业。我爸说打游戏是废物，不让我碰电脑。我只有偷偷来这里才能练。\"\n\n他从口袋里掏出一张皱巴巴的纸——上面密密麻麻写着游戏笔记、战术分析、手速训练计划。全是手写的。\n\n\"老板，我不要工资。你让我留下来练就行。我什么都愿意干。\"",
            type = "choice",
            choices = {
                { text = "🤝 \"留下吧。每天打烊后给你一小时免费练\"", hint = "Kofi 信任+2 · 每日电费+$5",
                  ethics = { moneyVsPeople = 2 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 2
                      playerData_.kofiJoined = true
                      ProgressiveUnlock.MarkStoryCompleted("kofi_joined")
                      playerData_.reputation = playerData_.reputation + 5
                      AddLog("🤝 你让 Kofi 留下了。他的眼睛亮了。每天打烊后，他会来练一小时。")
                  end,
                  result = function() return "Kofi 呆了两秒，然后深深鞠了一躬。\"谢谢老板！我不会让你失望的！\"\n\n他跑到角落那台机器前坐下，双手放在键盘上——那个动作熟练得像回到了家。\n\n你看了眼电表。多一小时电费……算了，就当投资吧。\n\n💡 Kofi 开始在你的网吧训练。他还不是队员，但种子已经种下。" end },
                { text = "🤔 \"我考虑一下。你先帮我干活顶替\"", hint = "Kofi 信任+1 · 获得免费帮手",
                  ethics = { resultVsProcess = 1 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 1
                      playerData_.kofiJoined = true
                      ProgressiveUnlock.MarkStoryCompleted("kofi_joined")
                      AddLog("🤔 你让 Kofi 先帮忙打杂。他干活特别勤快，一边擦桌子一边偷看屏幕。")
                  end,
                  result = function() return "Kofi 用力点头：\"什么活都行！扫地、搬东西、装系统——我都会！\"\n\n接下来一个小时，他把网吧里里外外擦了一遍，比你自己收拾得还干净。\n\n忙完后他小心翼翼问：\"老板……那我能用那台最旧的练十分钟吗？\"\n\n💡 Kofi 成为你的帮手。他渴望上机的眼神，让你想起了什么。" end },
                { text = "✋ \"对不起，我这里不养闲人\"", hint = "省事 · Kofi 离开",
                  ethics = { moneyVsPeople = -2 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) - 1
                      AddLog("✋ 你拒绝了 Kofi。他低着头走了，手里还攥着那张笔记。")
                  end,
                  result = function() return "Kofi 的表情像是灯灭了一样。\"好的……打扰了。\"\n\n他转身走出门，经过那台角落的电脑时手指碰了碰屏幕边缘，然后收回去了。\n\n门关上后，你看到他写的那张笔记掉在了地上。捡起来一看——上面的战术分析比你见过的很多职业选手都细。\n\n⚠️ Kofi 离开了。他不会轻易再回来。" end },
            },
        },
    },
    -- ═══ P2: Day6 —— 第一次训练/夜训 ═══
    [6] = {
        {
            id = "p2_first_training", category = "social", rarity = "common",
            title = "🎮 第一次夜训",
            desc = function()
                if (playerData_.kofiJoined) then
                    return "晚上十一点，最后一个客人走了。Kofi 从后门探出头：\"老板，可以了吗？\"\n\n他坐到电脑前，手指在键盘上预热。你第一次认真看他打一整局——\n\n那个走位、那个反应速度……这不是练出来的，是天赋。但设备太差了，好几次他明显能杀掉对手，却因为帧率卡顿错过了时机。\n\n\"老板，如果有好一点的电脑……我能打得更好。\" 他小声说。"
                else
                    return "晚上关门后，你在清理电脑时发现角落那台机器还开着——屏幕上是一个三角洲行动的回放录像。14杀3死，MVP。\n\n记录的玩家ID：\"KofiGod_04\"。\n\n你想起前天那个少年。他虽然被你拒绝了，但显然还是找到了办法偷偷练习。\n\n门口传来敲门声——Kwame 探头进来：\"老板，那个 Kofi 刚才来找过你。他说……如果你改主意了，他还愿意回来。\""
                end
            end,
            type = "choice",
            choices = {
                { text = "🎯 免费让他练到凌晨", hint = "电费+$10 · Kofi 信任大增 · 真诚投入",
                  ethics = { moneyVsPeople = 2, resultVsProcess = -1 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 3
                      playerData_.money = playerData_.money - 10
                      playerData_.kofiJoined = true
                      ProgressiveUnlock.MarkStoryCompleted("kofi_joined")
                      AddLog("🎮 Kofi 练到了凌晨两点。走的时候他说：\"老板，我一定不会让你白付电费。\"")
                  end,
                  result = function() return "你泡了两杯速溶咖啡，一杯给自己，一杯给他。\n\n凌晨两点，他终于站起来，揉了揉眼睛。\"老板……谢谢。今天我进步了。\"\n\n他走进黑夜里，你关了灯。电表多转了十块钱的电，但你觉得值。\n\n💡 Kofi 信任大幅提升。他开始把你当自己人了。" end },
                { text = "💵 收他半价：$15 / 晚训练", hint = "回收成本 · Kofi 接受但吃力",
                  ethics = { moneyVsPeople = -1 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 1
                      playerData_.money = playerData_.money + 15
                      playerData_.kofiJoined = true
                      ProgressiveUnlock.MarkStoryCompleted("kofi_joined")
                      AddLog("💵 Kofi 交了 $15 训练费。他从口袋里一张一张数出来的，都是零钱。")
                  end,
                  result = function() return "Kofi 犹豫了一下，从口袋里掏出一把零钱，一张张数出来。$15，全是小额纸币。\n\n\"没关系，老板，应该的。\" 他笑了笑坐下开始练。\n\n你注意到他今天没吃晚饭——省下来的钱，应该就是这$15。\n\n💡 Kofi 付费训练。他能坚持多久？" end },
                { text = "📣 \"你帮我拍训练视频发网上，算抵电费\"", hint = "免费宣传 · Kofi 可能被其他战队发现",
                  ethics = { resultVsProcess = 1 },
                  effect = function()
                      playerData_.kofiTrust = (playerData_.kofiTrust or 0) + 1
                      playerData_.reputation = playerData_.reputation + 8
                      playerData_.kofiExposed = true
                      playerData_.kofiJoined = true
                      ProgressiveUnlock.MarkStoryCompleted("kofi_joined")
                      AddLog("📣 Kofi 的训练视频发到了网上。反响不错——但也可能引来别人的注意。")
                  end,
                  result = function() return "你用手机录了 Kofi 的几个精彩操作，配上文字发到了本地游戏群里。\n\n一小时内就有几十个点赞和转发。评论里有人问：\"这小子在哪个战队？我们队缺人！\"\n\n Kofi 没看到这些评论。但你知道——好消息传得快，坏消息也是。\n\n💡 声望提升！但 Kofi 的存在可能被竞争对手注意到。" end },
            },
        },
    },
    -- ═══ P2: Day7 —— 首周结算 + Week2 预告 ═══
    [7] = {
        {
            id = "p2_week1_summary", category = "business", rarity = "common",
            title = "📊 第一周总结",
            desc = function()
                local money = playerData_.money or 0
                local rep = playerData_.reputation or 0
                local kofi = playerData_.kofiTrust or 0
                local karma = playerData_.karma or 0
                return "七天了。你从一个拖着行李箱的异乡人，变成了这条街上\"那个开网吧的中国老板\"。\n\n"
                    .. "📦 现金：$" .. math.floor(money) .. "\n"
                    .. "⭐ 街区口碑：" .. math.floor(rep) .. "\n"
                    .. "🤝 邻里关系：" .. (karma >= 3 and "融入中" or karma >= 1 and "还行" or "生疏") .. "\n"
                    .. "🧑🏿 Kofi 信任：" .. (kofi >= 3 and "很信你" or kofi >= 1 and "愿意跟你" or "不确定") .. "\n"
                    .. "\n但门外传来了消息——对面那个空铺面，有人在装修了。隔壁 Ama 悄声说：\"听说是 Victor 的人。他要在你对面开一家更大的网吧。\"\n\n下周不会太平。"
            end,
            type = "choice",
            choices = {
                { text = "💪 \"来就来，我不怕竞争\"", hint = "士气提升 · 直面挑战",
                  ethics = { legalVsGray = 1 },
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 5
                      AddLog("💪 第一周结束。Victor 的阴影已经到了街对面——但你不怕。")
                  end,
                  result = function() return "你深吸一口气，看了看自己的网吧——三台旧电脑、一台发电机、贴满墙的传单。\n\n简陋，但这是你的。\n\n\"Dragon Net Cafe 不会输。\" 你对自己说。\n\n⚡ Week 2 预告：Victor 的 Gold Net 即将开业。价格战、挖人、抢客……准备好了吗？" end },
                { text = "🤔 \"得想想怎么差异化......\"", hint = "策略思维 · 可能发现新路",
                  ethics = { resultVsProcess = 1 },
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 3
                      playerData_.karma = (playerData_.karma or 0) + 1
                      AddLog("🤔 第一周结束。你在笔记本上写下了几个应对 Victor 的想法。")
                  end,
                  result = function() return "你在本子上写下了几个点：\n\n• Victor 有钱，但我有人情\n• 他的客人是消费者，我的客人可能变成战友\n• 电竞=社区，不只是生意\n\n也许……Kofi 就是你最大的差异化。\n\n⚡ Week 2 预告：Victor 的阴影逼近。但你有他没有的东西——一个有天赋的少年，和一条街的人情。" end },
            },
        },
    },
    -- P0-4: Victor 初次交锋提示（D8）
    [8] = {
        {
            id = "victor_first_encounter", category = "social", rarity = "rare",
            title = "😈 不速之客",
            desc = "下午三点，一辆黑色 SUV 停在你门口。车门打开，一个穿着名牌polo衫的中年男人走了进来。\n\n他环顾四周，嘴角微微扯了扯——那是一种看不起人才会有的笑。\n\n\"这就是……Dragon Net Cafe？\"他拍了拍你的1号机屏幕。\"有意思。听说你们还搞了个小战队？\"\n\n他递出一张烫金名片：Victor Mensah — Gold Net Cafe Group, CEO。\n\n\"我就住街对面。以后……多指教。\"",
            type = "choice",
            choices = {
                { text = "😤 \"指教不敢当。来者是客，有事说事。\"",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 3
                      playerData_.karma = (playerData_.karma or 0) + 1
                      -- P0-6: 伦理追踪 —— 硬气回应 = 正直
                      if playerData_.ethicsLedger then
                          playerData_.ethicsLedger.legalVsGray = playerData_.ethicsLedger.legalVsGray + 1
                          playerData_.ethicsLedger.moneyVsPeople = playerData_.ethicsLedger.moneyVsPeople + 1
                      end
                      table.insert(playerData_.ethicsKeyChoices or {}, { day = 8, choiceId = "victor_firm", delta = "+legalVsGray +moneyVsPeople" })
                  end,
                  result = function() return "Victor 笑了一下，那笑容里有三分欣赏七分轻蔑。\n\n\"有骨气。不过光有骨气活不下去的。\"\n\n他转身走到门口又停了一下：\"我的 Gold Net 下个月要搞周年庆大促。你……自求多福吧。\"\n\n门在他身后关上。Kofi从后面冒出来：\"老板……那人什么来头？\"" end },
                { text = "🤝 \"Victor 先生，请坐。喝杯什么？\"",
                  effect = function()
                      playerData_.reputation = playerData_.reputation + 1
                      -- P0-6: 伦理追踪 —— 圆滑应对 = 中性偏实用
                      if playerData_.ethicsLedger then
                          playerData_.ethicsLedger.resultVsProcess = playerData_.ethicsLedger.resultVsProcess - 1
                      end
                      table.insert(playerData_.ethicsKeyChoices or {}, { day = 8, choiceId = "victor_polite", delta = "-resultVsProcess" })
                  end,
                  result = function() return "Victor 没坐，只是又看了一圈。\n\n\"不用了。我只是来认认路——看看我的新邻居长什么样。\"\n\n他从兜里摸出一颗薄荷糖放嘴里：\"你这几台老机器……上个月我全新淘汰了一批比这好的。\"\n\n他走了。空气里留下一股贵价古龙水的味道。Kofi小声说：\"老板，我怎么觉得他在宣战？\"" end },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 9: 价格战 —— Victor 明面压价
    -----------------------------------------------------------------------
    [9] = {
        {
            id = "day9_price_war",
            category = "主线",
            rarity = "fixed",
            title = "价格战",
            desc = function()
                return "一早就有老客跑来告诉你：Victor 的店贴出大海报——\n\"全场半价，连续一周！\"\n\n你的定价本来就不算贵，他这一刀直接砍进骨头里。今天的客流明显少了。"
            end,
            type = "choice",
            choices = {
                {
                    text = "跟进降价，留住客户",
                    hint = "利润暴跌但客流回来",
                    ethics = { legalVsGray = 0 },
                    effect = function()
                        playerData_.money = (playerData_.money or 0) - 80
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 3)
                        AddLog("📉 跟进降价，今日利润 -$80，但客流勉强稳住")
                    end,
                    result = "你连夜改了价目表。老客们松了口气，但你看着账本叹气——这样撑不了几天。"
                },
                {
                    text = "搞主题之夜，差异化竞争",
                    hint = "花钱办活动，提升口碑",
                    ethics = { resultVsProcess = 1 },
                    effect = function()
                        playerData_.money = (playerData_.money or 0) - 120
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 6)
                        if playerData_.kofiJoined then
                            playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 3)
                        end
                        AddLog("🎮 主题之夜大受欢迎！口碑 +6，花费 $120")
                    end,
                    result = "Kofi帮你布置了一场\"复古街机之夜\"。虽然花了钱，但社区里传开了：\"这家店有意思。\""
                },
                {
                    text = "去 Victor 店里偷看他的成本结构",
                    hint = "灰色手段，但能拿到情报",
                    ethics = { legalVsGray = -2 },
                    effect = function()
                        playerData_.storedIntel = "victor_cost_intel"
                        if playerData_.ethicsLedger then
                            playerData_.ethicsLedger.legalVsGray = playerData_.ethicsLedger.legalVsGray - 2
                        end
                        AddLog("🕵️ 你摸清了 Victor 的底牌——他在亏本补贴，撑不了太久")
                    end,
                    result = "你假装客人在 Victor 店里坐了半小时。他用的是预付费电卡，带宽也是最便宜的套餐——他在烧钱。这个信息以后会有用。"
                },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 10: 暗箭难防 —— 假差评攻击
    -----------------------------------------------------------------------
    [10] = {
        {
            id = "day10_fake_reviews",
            category = "主线",
            rarity = "fixed",
            title = "暗箭难防",
            desc = function()
                return "Google Maps 上突然冒出 5 条一星差评，全是新注册账号：\n\"网速慢得像乌龟\"\n\"老板态度恶劣\"\n\"键盘全是油\"\n\n你知道这不是真的——但路过的新客不知道。"
            end,
            type = "choice",
            choices = {
                {
                    text = "发动老客写真实好评覆盖",
                    hint = "合法但需要时间",
                    ethics = { legalVsGray = 1 },
                    effect = function()
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 4)
                        AddLog("⭐ 老客们帮忙写了好评，口碑正在恢复")
                    end,
                    result = "你在群里发了消息，老客们纷纷响应。真实的五星评价很快把假的淹没了——虽然慢了一天。"
                },
                {
                    text = "以其人之道还治——给 Victor 也刷差评",
                    hint = "快速但有道德代价",
                    ethics = { legalVsGray = -2 },
                    effect = function()
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 2)
                        if playerData_.ethicsLedger then
                            playerData_.ethicsLedger.legalVsGray = playerData_.ethicsLedger.legalVsGray - 2
                        end
                        AddLog("💢 你反击了，但心里不太舒服")
                    end,
                    result = "你花了半小时注册小号给 Victor 刷了一波差评。解气，但 Kofi 看你的眼神有点复杂。"
                },
                {
                    text = "不理会，专注做好自己",
                    hint = "短期亏损，长期正道",
                    ethics = { resultVsProcess = 1 },
                    effect = function()
                        playerData_.reputation = math.max(0, (playerData_.reputation or 50) - 3)
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 4)
                        AddLog("🧘 你没理会差评，专心经营。短期客流受影响")
                    end,
                    result = "\"老板，我觉得你做得对，\" Kofi说，\"不跟小人计较。客人用了就知道好不好。\"\n\n你点点头——但今天确实少了几个新面孔。"
                },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 11: AEL 邮件 —— 正式赛事邀请
    -----------------------------------------------------------------------
    [11] = {
        {
            id = "day11_ael_invitation",
            category = "主线",
            rarity = "fixed",
            title = "AEL 邮件",
            desc = function()
                local kofiLine = playerData_.kofiJoined
                    and "\n\nKofi 看到邮件整个人都亮了：\"老板！这是 AEL！非洲电竞联赛！如果我们能参加……\""
                    or "\n\n你想起 Kofi 之前提过电竞比赛的事——也许该认真考虑了。"
                return "收件箱里有一封来自 AEL（非洲电竞联赛）的邮件：\n\n\"尊敬的网吧经营者：\n第 14 届 AEL 地区预选赛将于两周后开始。您的网吧已获得参赛资格。\n请在 Day 14 前确认报名并提交队员名单。\"\n\n这是改变一切的机会——也是巨大的压力。" .. kofiLine
            end,
            type = "choice",
            choices = {
                {
                    text = "全力备战！这是我们的机会！",
                    hint = "士气大涨，但后续压力也大",
                    ethics = { resultVsProcess = 1 },
                    effect = function()
                        playerData_.aelRegistered = true
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 5)
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 3)
                        AddLog("🏆 你决定参加 AEL！Kofi 激动得差点跳起来")
                    end,
                    result = "\"我们要参加！\" 你拍桌子做了决定。\n\nKofi 的眼里有光：\"老板，你不会后悔的。我这几年一直在练——就等这个机会！\"\n\n你知道接下来几天会很忙，但看着 Kofi 的表情，你觉得值了。"
                },
                {
                    text = "想参加，但不确定我们准备好了……",
                    hint = "谨慎，但 Kofi 可能有点失望",
                    ethics = { resultVsProcess = -1 },
                    effect = function()
                        playerData_.aelRegistered = true
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 2)
                        AddLog("🤔 你犹豫了一下，但还是决定试试")
                    end,
                    result = "\"我们……试试吧。\" 你说得不太确定。\n\nKofi 点点头：\"老板，交给我。我会证明我们可以的。\"\n\n他的语气很平静，但你看到他握紧了拳头。"
                },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 12: 人不够 —— 阵容压力
    -----------------------------------------------------------------------
    [12] = {
        {
            id = "day12_roster_pressure",
            category = "主线",
            rarity = "fixed",
            title = "人不够",
            desc = function()
                return "AEL 要求五人队伍。算上 Kofi，你还差人。\n\n社区里有几个常客打得不错，但要说比赛级别……Kofi 皱着眉看着在线的几个人：\"老板，光靠我一个 carry 不了五个位置。\""
            end,
            type = "choice",
            choices = {
                {
                    text = "在社区贴招募告示，公开选拔",
                    hint = "公平但可能来的人水平参差",
                    ethics = { moneyVsPeople = 1 },
                    effect = function()
                        playerData_.reputation = math.min(100, (playerData_.reputation or 50) + 4)
                        playerData_.rosterMethod = "open"
                        AddLog("📋 你在店里和社区群贴了招募告示")
                    end,
                    result = "告示贴出去半小时，就有三个年轻人来问。水平确实参差，但热情都很高。Kofi 说他可以带训练。\n\n\"有热情就有希望，\" 他说。"
                },
                {
                    text = "让 Kofi 推荐他认识的选手",
                    hint = "Kofi 有人脉，质量高但圈子窄",
                    ethics = { integrationVsExtraction = 1 },
                    effect = function()
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 4)
                        playerData_.rosterMethod = "kofi_pick"
                        AddLog("🤝 Kofi 去联系了几个老朋友")
                    end,
                    result = "Kofi 打了几个电话，第二天带来两个瘦高的年轻人。\"这是 Ama 和 Kwesi，我以前网吧认识的。段位都是钻石以上。\"\n\n他们看起来靠谱——但 Kofi 明显是这个小团体的核心。"
                },
                {
                    text = "花钱从别的网吧挖人",
                    hint = "快但贵，而且伤口碑",
                    ethics = { moneyVsPeople = -1, legalVsGray = -1 },
                    effect = function()
                        playerData_.money = (playerData_.money or 0) - 200
                        playerData_.rosterMethod = "poach"
                        if playerData_.ethicsLedger then
                            playerData_.ethicsLedger.moneyVsPeople = playerData_.ethicsLedger.moneyVsPeople - 1
                        end
                        AddLog("💸 你花了 $200 从隔壁网吧挖了两个高手")
                    end,
                    result = "钱能解决的问题都不是问题——你找到了两个段位够高的选手。但隔壁网吧老板打电话来骂了你五分钟。\n\nKofi 没说什么，但看得出他不太赞同。"
                },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 13: Kofi 的家事 —— 家庭与梦想的拉扯
    -----------------------------------------------------------------------
    [13] = {
        {
            id = "day13_kofi_family",
            category = "主线",
            rarity = "fixed",
            title = "Kofi 的家事",
            desc = function()
                return "训练到一半，Kofi 接了个电话，脸色变了。\n\n挂了电话他沉默了好一会儿才开口：\"我爸又打来了。他说如果我不回去继承鱼摊……就当没我这个儿子。\"\n\n他看着屏幕，手还放在键盘上：\"老板，我真的很想打这个比赛。但我爸他……他不懂。\""
            end,
            type = "choice",
            choices = {
                {
                    text = "我去跟你爸聊聊，让他来看你比赛",
                    hint = "仗义，但你要亲自出面",
                    ethics = { moneyVsPeople = 2 },
                    effect = function()
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 8)
                        playerData_.kofiDadTalked = true
                        if playerData_.ethicsLedger then
                            playerData_.ethicsLedger.moneyVsPeople = playerData_.ethicsLedger.moneyVsPeople + 2
                        end
                        AddLog("🤝 你决定亲自去找 Kofi 的父亲谈谈")
                    end,
                    result = "\"你……你愿意？\" Kofi 的声音有点抖。\n\n\"他是你爸，不是你的敌人。也许他只是需要亲眼看到你在做什么。\" 你拍了拍他的肩膀。\n\nKofi 深吸一口气：\"谢谢老板。真的。\""
                },
                {
                    text = "这是你自己的路，你自己决定",
                    hint = "尊重但有点冷",
                    ethics = { moneyVsPeople = 0 },
                    effect = function()
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 2)
                        AddLog("🤷 你让 Kofi 自己处理家事")
                    end,
                    result = "Kofi 点了点头：\"也是……我自己的事。\"\n\n他回到座位继续训练，但你看得出来他心不在焉。今晚的训练质量明显下降了。"
                },
                {
                    text = "我每月给你爸寄点钱，补偿鱼摊损失",
                    hint = "用钱解决，简单粗暴",
                    ethics = { moneyVsPeople = 1, resultVsProcess = -1 },
                    effect = function()
                        playerData_.money = (playerData_.money or 0) - 150
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 5)
                        playerData_.kofiDadPaid = true
                        AddLog("💰 你承诺每月补贴 Kofi 家里 $150")
                    end,
                    result = "\"我会跟你爸说，每个月我出一份钱，比鱼摊赚的不少。\" \n\nKofi 愣了一下：\"老板，你不用……\"\n\n\"行了，专心训练。钱的事我来想办法。\"\n\n他重新坐好，眼眶有点红——但手指已经回到了键盘上。"
                },
            },
        },
    },

    -----------------------------------------------------------------------
    -- Day 14: 首战前夜 —— Victor 挖人 + 最终确认
    -----------------------------------------------------------------------
    [14] = {
        {
            id = "day14_eve_of_battle",
            category = "主线",
            rarity = "fixed",
            title = "首战前夜",
            desc = function()
                local rosterLine = ""
                if playerData_.rosterMethod == "kofi_pick" then
                    rosterLine = "\n\nAma 和 Kwesi 也到了，三个人围在一起研究对手录像。"
                elseif playerData_.rosterMethod == "open" then
                    rosterLine = "\n\n招募来的队员们准时到场，虽然紧张但眼神坚定。"
                else
                    rosterLine = "\n\n花钱挖来的选手到了——他们很职业，但和 Kofi 之间明显还有距离。"
                end
                return "明天就是 AEL 地区预选赛第一轮。\n\nKofi 在做最后的准备——突然他接到一条消息，脸色变了：\n\n\"Victor 给我发私信了。他说……他愿意出三倍工资让我去他的队。\"" .. rosterLine .. "\n\nKofi 看着你，等你的反应。"
            end,
            type = "choice",
            choices = {
                {
                    text = "Kofi，你是自由人。但你走之前看看这里。",
                    hint = "以情动人，用信任对抗金钱",
                    ethics = { moneyVsPeople = 2 },
                    effect = function()
                        local trust = playerData_.kofiTrust or 50
                        if trust >= 60 then
                            playerData_.kofiStays = true
                            playerData_.kofiTrust = math.min(100, trust + 5)
                            AddLog("❤️ Kofi 选择留下。\"这里是我的家。\"")
                        else
                            playerData_.kofiStays = false
                            playerData_.kofiTrust = math.max(0, trust - 10)
                            AddLog("💔 Kofi 信任不够，他犹豫了很久……最终离开了")
                        end
                    end,
                    result = function()
                        if playerData_.kofiStays then
                            return "Kofi 沉默了很久。然后他把手机锁了屏。\n\n\"老板，我记得你第一天让我免费用电脑那次。\" 他笑了，\"三倍工资？他买不走我。\"\n\n你没说话，只是递了一瓶水。明天，你们一起上场。"
                        else
                            return "Kofi 低着头：\"老板……对不起。我妈需要钱治病，我爸还在生气……\"\n\n他走了。你看着空荡荡的椅子，第一次觉得这间网吧太安静了。\n\n但比赛还要继续。你必须想办法。"
                        end
                    end,
                },
                {
                    text = "我给你涨薪，赢了比赛还有奖金分成",
                    hint = "用利益留人",
                    ethics = { resultVsProcess = -1 },
                    effect = function()
                        playerData_.money = (playerData_.money or 0) - 100
                        playerData_.kofiStays = true
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 2)
                        AddLog("💵 你许诺涨薪+奖金分成，Kofi 留了下来")
                    end,
                    result = "\"涨薪，奖金三七分。\" 你开出条件。\n\nKofi 想了想：\"行。但不只是钱的事——我信你，老板。\"\n\n他留了下来。但你知道，如果比赛输了，这个承诺会变成压力。"
                },
                {
                    text = "他敢挖我的人？明天比赛上见真章！",
                    hint = "怒气激励，可能反噬",
                    ethics = { resultVsProcess = -1 },
                    effect = function()
                        playerData_.kofiStays = true
                        playerData_.kofiTrust = math.min(100, (playerData_.kofiTrust or 50) + 1)
                        playerData_.teamMorale = (playerData_.teamMorale or 50) + 10
                        AddLog("🔥 你把怒气转化为动力，全队士气高涨！")
                    end,
                    result = "你猛拍桌子：\"Victor 那个混蛋！他以为撒钱就能赢？明天我们在赛场上让他好看！\"\n\nKofi 被你的气势感染了，笑了出来：\"行，老板说打就打！\"\n\n全队的肾上腺素都起来了——但希望明天不会变成冲动。"
                },
            },
        },
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
            scene = "第一天总算熬过来了。你锁好门，看了看电表——转得飞快。",
            hook = "手机上有条短信：\"房租明天到期，$150+水电$80。\" 明天一早就得解决这个。",
            icon = "⚡", urgency = "high",
        },
        [2] = {
            scene = "打烊后你在整理电脑，角落那台旧机器的屏幕还亮着……",
            hook = "战绩页面：14杀3死，MVP。用那种帧率？这台机器下午有人偷偷用过。明天他还会来吗？",
            icon = "👀", urgency = "high",
        },
        [3] = {
            scene = "街坊们在门口聊天时看了你一眼——那种打量新人的目光。",
            hook = "五金店 Kwaku 明天要来「认认新邻居」。这条街有这条街的规矩。",
            icon = "🏘️", urgency = "high",
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
        -- ═══ Week 3: 首战与证明 (D15-D21) ═══
        [15] = {
            scene = "清晨，一封带着 AEL 徽标的邮件静静躺在收件箱里。",
            hook = "\"Dragon Force 已获得 Tier-2 预选赛资格。首战日期：三天后。\" 留给你们的时间不多了。",
            icon = "📧", urgency = "high",
        },
        [16] = {
            scene = "训练室里的气氛不一样了——没人说话，只有键盘的敲击声。",
            hook = "Kofi 的操作越来越稳，但你注意到他的手在微微发抖。第一次正式比赛的压力……你该说点什么？",
            icon = "🎮", urgency = "mid",
        },
        [17] = {
            scene = "打完最后一场训练赛，你看着对手数据——明天的对手是 Victor 的二队。",
            hook = "不是 Gold Net 主力，但 Victor 派他们来的意思很明确：\"我随便一支队都能碾你。\"",
            icon = "⚔️", urgency = "high",
        },
        [18] = {
            scene = "比赛结束。不管结果如何，Dragon Force 的名字第一次出现在了正式战报上。",
            hook = "社交媒体上有人开始讨论你们了。Victor 的朋友圈转发了战报，配文只有一个字：\"哦。\"",
            icon = "📱", urgency = "mid",
        },
        [19] = {
            scene = "赛后采访的视频在本地论坛火了——Kofi 那句\"我们还会回来\"被做成了表情包。",
            hook = "一个赞助商的名片出现在柜台上。明天要不要回电话？",
            icon = "💼", urgency = "mid",
        },
        [20] = {
            scene = "半夜被电话吵醒——是 Kofi。\"老板，你看新闻了吗？\"",
            hook = "AEL 宣布：下个月的区域决赛落地本市。主场作战……Dragon Force 必须拿到参赛名额。",
            icon = "🏟️", urgency = "high",
        },
        [21] = {
            scene = "三周了。从破铁皮屋到本地论坛热帖。Victor 还在笑，但笑容里多了几分认真。",
            hook = "这一周你要决定：是继续稳扎稳打，还是赌一把冲击区域决赛？",
            icon = "📋", urgency = "high",
        },
        -- ═══ Week 4: AEL 冲刺与命运选择 (D22-D30) ═══
        [22] = {
            scene = "早上开门时发现门口放着一个快递箱——没有署名。",
            hook = "里面是一套全新的电竞外设，附了张条：\"好好比赛。—— 一个老粉丝\"。有人在暗中支持你。",
            icon = "📦", urgency = "mid",
        },
        [23] = {
            scene = "Victor 的 Gold Net 突然宣布：\"赞助 AEL 区域决赛，冠名权归我。\"",
            hook = "他要把你的主场变成他的秀场。如果赢了，就是在他的地盘上打他的脸。",
            icon = "😈", urgency = "high",
        },
        [24] = {
            scene = "队员们的状态到了巅峰——但一条消息让气氛凝固了。",
            hook = "Victor 开出天价要签走你的核心选手。\"三倍工资，配车配房。\" 他说YES了吗？",
            icon = "💰", urgency = "high",
        },
        [25] = {
            scene = "决赛倒计时 5 天。网吧里贴满了队员们自己画的 Dragon Force 海报。",
            hook = "Kofi 加练到凌晨三点。你进去时他抬头：\"老板，我不想让你失望。\"",
            icon = "🐉", urgency = "mid",
        },
        [26] = {
            scene = "本地媒体来采访了。记者问：\"你觉得你们能赢 Victor 的队吗？\"",
            hook = "Kofi 替你回答了：\"他有钱，我们有故事。\" 明天的头条会怎么写？",
            icon = "🎤", urgency = "mid",
        },
        [27] = {
            scene = "决赛倒计时 3 天。Victor 在社交媒体上发了一张全队合照——每人手上戴着定制金表。",
            hook = "评论区有人嘲讽你：\"Dragon Force？不如叫 Dragon Farce。\" 你的队员们沉默了。",
            icon = "🔥", urgency = "high",
        },
        [28] = {
            scene = "最后一次赛前训练。你站在队员们面前，不知道该说什么鼓励的话。",
            hook = "Kofi 站起来：\"老板不用说了。我们都知道为什么在这里。\" 房间里响起掌声。",
            icon = "👊", urgency = "mid",
        },
        [29] = {
            scene = "明天就是决赛。夜里你一个人坐在网吧里，看着墙上的合照——从两个人到一支队伍。",
            hook = "手机响了，Victor 发来一条消息：\"明天见。祝你好运——你会需要的。\" 明天，定胜负。",
            icon = "⚡", urgency = "high",
        },
        [30] = {
            scene = "决赛日。天还没亮，门口已经有人在排队——他们举着 Dragon Force 的旗子。",
            hook = "三十天前你带着5000美元来到这里。今天，整个城市都在看你。不管结果如何——这就是你的故事。",
            icon = "🏆", urgency = "high",
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
