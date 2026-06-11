-- ============================================================================
-- DailyGreeting.lua — P1: 队员每日一言系统
-- 每天开始时从队员文案池中随机选一条，增强"队友在等我"的回归感
-- ============================================================================

local DailyGreeting = {}

-- ── 文案池：按角色 × 心情 × 阶段 组织 ──
-- 心情: happy (mood>70), normal (40-70), low (<40)
-- 阶段: early (D1-7), mid (D8-18), late (D19+)

local WORDS = {
    kofi = {
        happy = {
            early = {
                "老板！昨天那把五杀爽到了！今天继续练！",
                "嘿嘿，我觉得我的反应速度又快了一点点！",
                "老板早！你猜我昨晚偷偷加练了多久？三小时！",
                "今天感觉特别好！键盘都变顺手了！",
                "老板，我跟你说，我做梦都在练大招……",
            },
            mid = {
                "我感觉技术又涨了！下次比赛我要carry！",
                "老板，今天训练我想试试新战术，行不行？",
                "隔壁那些队伍？以我们现在的状态，不虚！",
                "Gold Net那帮人算什么！等我状态起来，一打三！",
                "老板！我昨天看了个教程，今天想试试闪光步！",
            },
            late = {
                "老板，我们真的能进决赛！我相信！",
                "这支队伍越来越像一支真正的战队了。",
                "回想刚来的时候……哈哈，进步太大了！",
                "今天感觉能赢整个世界！Let's go！",
                "老板你知道吗？外面有人叫我'Dragon Net的王牌'了！",
            },
        },
        normal = {
            early = {
                "老板早。今天练什么？我听安排。",
                "嗯……状态一般般，但训练不能停。",
                "老板，今天客人应该会多吧？周末嘛。",
                "我准备好了，今天继续。",
                "刚泡好咖啡，训练开始吧。",
            },
            mid = {
                "又是新的一天。比赛越来越近了。",
                "老板，今天的训练计划我看了，没问题。",
                "状态还行。继续积累，不急。",
                "Victor那边最近安静了……我反而有点不安。",
                "今天争取把连招成功率提到80%。",
            },
            late = {
                "老板。又是一天。咱们离目标又近了一步。",
                "我已经准备好了。今天照常。",
                "队伍现在挺稳的，保持就好。",
                "看了下赛程表，下一场不远了。",
                "今天打算复盘一下上次比赛的录像。",
            },
        },
        low = {
            early = {
                "……老板。我昨晚没怎么睡好。",
                "唉，最近手感不太行……别嫌弃我。",
                "我会加油的……只是需要点时间。",
                "对不起老板，昨天那把太丢人了……",
                "……你觉得我真的能行吗？",
            },
            mid = {
                "Gold Net的人在论坛上嘲笑我……算了。",
                "老板……我是不是拖后腿了？",
                "说实话最近压力有点大……但我不会放弃。",
                "我看了Victor那边的训练视频……差距好像挺大的。",
                "老板，如果我输了……你还要我吗？",
            },
            late = {
                "到这个阶段了……说不紧张是假的。",
                "老板，我怕让大家失望……",
                "好累……但不能停。队伍需要我。",
                "我在想要是当初没来Dragon Net……算了，别想了。",
                "能让我今天少练一会儿吗？……开玩笑的，走吧。",
            },
        },
    },
    grace = {
        happy = {
            early = {
                "早！今天我要用新策略干翻训练赛！",
                "老板老板，我昨天研究了个走位技巧超帅的！",
                "感觉状态起飞了！今天是好日子！",
                "老板你看我这新鼠标垫——心情好手感也好！",
                "今天我一定要刷新个人纪录！看着吧！",
            },
            mid = {
                "Victor的队伍？让他们来！我Grace可不怕！",
                "老板，我觉得我能打辅助位——也能打核心！",
                "今天想挑战一下高难度副本，可以吗？",
                "我跟Kofi配合越来越默契了，今天再练练！",
                "比赛越近我越兴奋！这就是战斗吧！",
            },
            late = {
                "Dragon Force！非洲最强不是梦！",
                "老板，我要当全非洲最强女选手！",
                "看我们走了多远！从铁皮屋到冠军候选！",
                "今天的我比昨天更强。明天会更强。",
                "感谢你当初收留我，老板。认真的。",
            },
        },
        normal = {
            early = {
                "早。今天也要加油。",
                "老板早安。训练开始了吗？",
                "状态一般，但够用。开练吧。",
                "今天打算巩固一下基本功。",
                "嗯，新的一天。继续前进。",
            },
            mid = {
                "赛程在推进，我们也得推进。",
                "今天的目标：不犯昨天的错误。",
                "还行吧，能练就练。",
                "老板，下次排练我想试试换位。",
                "Victor那边据说又招了新人……我们不能松懈。",
            },
            late = {
                "老板。我准备好了。",
                "就这么一步步走到现在了。继续。",
                "今天复盘完就休息吧，养精蓄锐。",
                "距离大赛越来越近，心态要稳。",
                "保持节奏，不快不慢。",
            },
        },
        low = {
            early = {
                "……我爸又打电话说不支持我打电竞了。",
                "昨天的表现太差了……我有点自我怀疑。",
                "没事没事，我只是没休息好……应该。",
                "老板……女生打电竞真的行吗？",
                "外面又有人说闲话了……算了。",
            },
            mid = {
                "如果下次比赛还是输……我可能要考虑一下。",
                "压力好大……Victor那边全是精英。",
                "我不想拖大家后腿……让我想想。",
                "老板，你说实话——我够格打主力吗？",
                "有时候觉得好累。但看到大家在练，我也不能停。",
            },
            late = {
                "都到这一步了……不能退了吧。",
                "说不害怕是骗人的。但我会上的。",
                "老板……答应我，就算输了也别解散队伍。",
                "我只是需要一点时间调整……明天会好的。",
                "不管怎样，谢谢你一直相信我。",
            },
        },
    },
    snake = {
        happy = {
            early = {
                "嘁，早就来了。你才到？",
                "今天手感不错。谁想被我虐一下？",
                "别废话了，开机，练！",
                "嘿嘿……昨晚我找到了对面战队的弱点。",
                "我研究了三套counter策略——今天试试。",
            },
            mid = {
                "Victor？我想看看他的精英队伍能撑几分钟。",
                "数据分析完了。Gold Net的二号位有严重的走位习惯。",
                "今天应该能把策略库补完。",
                "我们的进步曲线是上升的——这就够了。",
                "老板，安排个对抗赛。我要检验一下新思路。",
            },
            late = {
                "准备得差不多了。该上场了。",
                "龙网最强？不够。我要全非洲最强。",
                "分析、训练、执行。就这样循环，直到赢。",
                "我不会输。……绝不会。",
                "老板，这次赢了请你喝酒。输了也请你喝酒。",
            },
        },
        normal = {
            early = {
                "嗯。来了。",
                "今天该练什么就练什么吧。",
                "……你的咖啡不错。",
                "状态一般。凑合练。",
                "别管我，我热完身就好了。",
            },
            mid = {
                "比赛日程我看了。时间紧。",
                "对面的数据我在跟踪。不松懈就行。",
                "没什么好说的。干活。",
                "今天安静点好。让我专心。",
                "继续按计划走。",
            },
            late = {
                "该做的都做了。剩下的交给赛场。",
                "我已经分析了十几场他们的录像了。",
                "平常心。赢了是实力，输了也不丢人。",
                "老板。我准备好了。",
                "就这样吧。赛场见。",
            },
        },
        low = {
            early = {
                "……",
                "别问。让我静静。",
                "今天不太想说话。但训练照常。",
                "没事。只是昨晚有点失眠。",
                "有根烟吗？……算了，开练。",
            },
            mid = {
                "分析了半天……还是看不到赢Victor的路。",
                "要是我再强一点……队伍就不用这么辛苦。",
                "……算了。不想了。练就完事。",
                "我知道大家看不惯我态度。但我在努力。",
                "老板。我会想办法的。",
            },
            late = {
                "如果这次输了……我没什么借口可以找。",
                "有时候觉得是我限制了队伍的上限……",
                "我习惯一个人扛了。别担心我。",
                "……到最后关头了。行或不行，就看这次。",
                "老板，谢谢你没赶走我。虽然我脾气不好。",
            },
        },
    },
    generic = {
        happy = {
            early = {
                "老板早！今天也要加油啊！",
                "来了来了！今天一定是好日子！",
                "感觉精力充沛！训练走起！",
                "嘿！老板！早上好！",
                "迫不及待要开始了！走！",
            },
            mid = {
                "越来越强了！这就是成长的感觉！",
                "老板，队伍氛围越来越好了！",
                "比赛的事我不怕——有你有大家！",
                "Dragon Force加油！今天也冲！",
                "感觉这支队伍能做到很多事！",
            },
            late = {
                "走到这一步不容易。但我们配得上。",
                "老板，不管结果怎样，谢谢你！",
                "全非洲都在看着我们——太热血了！",
                "最后冲刺！一起！",
                "我为Dragon Force骄傲。",
            },
        },
        normal = {
            early = {
                "早。今天照常。",
                "来了，老板。",
                "又是新的一天呢。",
                "准备好了，开始吧。",
                "嗯，继续。",
            },
            mid = {
                "按部就班来吧。",
                "今天的计划是什么？",
                "状态还行，能练。",
                "继续努力。",
                "加油。",
            },
            late = {
                "该来的总会来。准备好了。",
                "保持节奏就好。",
                "老板，我们走到这里了。",
                "不多说了，上吧。",
                "稳住。",
            },
        },
        low = {
            early = {
                "……嗯，来了。",
                "没什么精神……但会努力。",
                "老板……今天温柔点行吗。",
                "状态不太好……抱歉。",
                "我尽力……",
            },
            mid = {
                "有点累……但不能停。",
                "压力好大。但我不会说放弃。",
                "对不起如果我表现不好……",
                "我会调整的。给我点时间。",
                "……算了。练吧。",
            },
            late = {
                "到这里了。不能倒了。",
                "我会撑住的。",
                "不管怎样……谢谢你们。",
                "最后一口气也要上的。",
                "……走吧。",
            },
        },
    },
}

--- 获取游戏阶段
---@param day number
---@return string "early"|"mid"|"late"
local function getPhase(day)
    if day <= 7 then return "early"
    elseif day <= 18 then return "mid"
    else return "late" end
end

--- 获取队员心情类别
---@param mood number 0-100
---@return string "happy"|"normal"|"low"
local function getMoodCategory(mood)
    if mood > 70 then return "happy"
    elseif mood >= 40 then return "normal"
    else return "low" end
end

--- 生成今日一言
---@return table|nil { speaker=string, emoji=string, text=string }
function DailyGreeting.Generate()
    -- 如果今日已展示过则不重复
    if playerData_.dailyGreetingShownDay == playerData_.day then
        return nil
    end

    -- 需要至少1个队员
    if not teamMembers_ or #teamMembers_ == 0 then return nil end

    -- 随机选一个队员作为发言者
    local member = teamMembers_[math.random(1, #teamMembers_)]
    local name = member.name or "队员"
    local mood = member.mood or 50
    local day = playerData_.day or 1

    local phase = getPhase(day)
    local moodCat = getMoodCategory(mood)

    -- 尝试匹配角色专属池
    local key = nil
    local lowerName = string.lower(name)
    if lowerName == "kofi" or string.find(lowerName, "kofi") then key = "kofi"
    elseif lowerName == "grace" or string.find(lowerName, "grace") then key = "grace"
    elseif lowerName == "snake" or string.find(lowerName, "snake") then key = "snake"
    else key = "generic" end

    local pool = WORDS[key] and WORDS[key][moodCat] and WORDS[key][moodCat][phase]
    if not pool or #pool == 0 then
        pool = WORDS["generic"][moodCat][phase]
    end
    if not pool or #pool == 0 then return nil end

    -- 用 day 作为额外 seed 避免每次进入同一天看到同一条
    local idx = ((day * 7 + (member.mood or 50)) % #pool) + 1
    local text = pool[idx]

    -- 角色 emoji
    local emoji = "💬"
    if key == "kofi" then emoji = "🧑‍💻"
    elseif key == "grace" then emoji = "👩‍💻"
    elseif key == "snake" then emoji = "🐍"
    else emoji = "🎮" end

    -- 标记已展示
    playerData_.dailyGreetingShownDay = playerData_.day

    return {
        speaker = name,
        emoji = emoji,
        text = text,
        moodCat = moodCat,
    }
end

return DailyGreeting
