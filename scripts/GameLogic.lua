---@diagnostic disable: undefined-global
-- ============================================================================
-- 18. 游戏逻辑
-- ============================================================================

local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")
local Achievements = require("Achievements")
local EasterEggs = require("EasterEggs")
local ChapterSystem = require("ChapterSystem")
local ReputationSystem = require("ReputationSystem")
require("GL_Events")
require("GL_EndDay")

--- 每日环境风味语池（非洲赛博朋克氛围）
local ATMO_WEATHER = {
    -- 旱季（天数1~10更常见）
    "铁皮屋顶被正午的太阳烤得能煎蛋，空气扭曲成透明的波浪。",
    "热风卷着红土扑面而来，路上的摩托车扬起一道尘幕。",
    "天空像被漂白了一样刺眼，树荫下的山羊懒得动弹。",
    "正午四十二度，沥青路面软得能印脚印。只有网吧的空调还在工作。",
    "日头毒辣，门口的芒果树叶子都蔫了。但屋里的RGB灯条闪得更起劲。",
    -- 雨季（天数11~20更常见）
    "雨季的积水漫到了台阶，有人踩着拖鞋蹚水进来打一局。",
    "暴雨敲打铁皮屋顶的声音像机关枪扫射，但盖不住里面的键盘声。",
    "闪电劈过天际，全城断电三秒。发电机嗡地一声接管了一切。",
    "潮湿的空气让键盘都有点黏手，屏幕上偶尔凝出水珠。",
    "雨后的彩虹横跨半个天空，信号塔上的红灯在彩虹中闪烁。",
    -- 黄昏与夜晚
    "日落把整条街染成橙红色，网吧的霓虹灯牌在暮色中亮起。",
    "入夜后，网吧成了方圆三公里唯一的光源。飞蛾围着LED灯带转圈。",
    "远处传来做晚祷的钟声，但键盘声没有停。",
    -- 特殊氛围
    "隔壁修车铺的电焊火花和网吧的RGB灯光交织，很赛博朋克。",
    "一辆载满香蕉的卡车停在门口，司机进来打了三局才走。",
    "门口的水泥墙上不知道谁喷了'DRAGON FORCE'的涂鸦，用的是荧光漆。",
    "有人把太阳能板当桌子，在上面吃烤鸡。你假装没看见。",
    "街对面教堂的唱诗班在练歌，屋里的队员在练枪法。圣歌与枪声，非洲日常。",
    "一群孩子趴在窗户外面看别人打游戏，眼睛里全是星星。",
    "摩托出租车在门口扎堆等客，司机们蹭WiFi看跑刀直播。",
}
local ATMO_VIBE_EARLY = {
    "你的网吧刚开张，空气里混着灰尘和新电脑的塑料味。一切才刚开始。",
    "门口的Mama Blessing支起烤架，鸡肉香飘了半条街。你的招牌还没挂正。",
    "第一批客人试探着走进来。你努力让WiFi看起来比实际快一些。",
    "二手戴尔嗡嗡运转着，你祈祷它们能撑过这个月。",
}
local ATMO_VIBE_MID = {
    "网吧的名声开始在城里传开。'去Dragon那里，网速快，老板人好。'",
    "'Dragon Net Cafe——跑刀圣地'的招牌传遍了半个城。有人专程骑摩托来。",
    "有外地人慕名来看你的网吧，拍了张照发到社交媒体上。",
    "泡面和辣条的味道飘在空气中，混着廉价香水和汗味——这就是梦想的味道。",
    "门口芒果树下总坐着等位的年轻人，有人带着自己的键盘来。",
}
local ATMO_VIBE_LATE = {
    "网吧人声鼎沸。窗外的非洲鼓声和屏幕里的枪声混成交响曲。",
    "有人在直播跑刀，弹幕刷着'非洲战神'。你的网吧成了地标。",
    "来自三个城市的队伍预约了明天的训练位。你开始考虑扩建。",
    "政府官员的侄子也偷偷来打游戏了。你假装不认识他。",
    "有赞助商的人在门口探头探脑，你让Snake把他吓走了。还没准备好。",
}
local ATMO_TEAM_SNIPPETS = {
    -- 按心情分类
    happy = {
        "%s戴着耳机跟着节拍晃脑袋，手指在键盘上飞舞。",
        "%s刚拿了全场MVP，得意地转着椅子。",
        "%s跟旁边的客人炫耀自己的跑刀路线，比划得手舞足蹈。",
        "%s在教一个小孩怎么设置灵敏度，出乎意料地有耐心。",
        "%s哼着歌擦键盘，那是他赢了比赛后的习惯。",
    },
    normal = {
        "%s正对着屏幕皱眉，研究怎么带更多哈弗币出去。",
        "%s打了个哈欠，但手上的操作丝毫没乱。旁边有人递来泡面。",
        "%s在笔记本上画着战术图，笔尖快戳破纸了。",
        "%s默默刷着训练模式，第37遍了。他在和自己较劲。",
    },
    low = {
        "%s一个人坐在角落，盯着黑屏发呆。",
        "%s今天话很少，泡面凉了也没动。",
        "%s的训练数据在下滑，但你不知道该怎么开口。",
        "%s看着窗外，不知道在想什么。手机屏幕上是家人的照片。",
    },
}

-- ============================================================================
-- 街头传闻跑马灯（开罗式氛围文案，每日随机 1 条混入日记）
-- 每条传闻带 cond 函数，满足条件才会进入候选池
-- ============================================================================
STREET_RUMORS = {
    { text = "隔壁 Blaze Net 的空调又炸了。三个客人端着键盘投奔了过来。", cond = function() return true end },
    { text = "有人在街角兜售'保证上分'的玄学手链。Kofi 偷偷买了一条。", cond = function() return HasMember and HasMember("Kofi") end },
    { text = "Mama B 的烤鸡今天涨价了。她说——'通胀，你懂的。'", cond = function() return (playerData_.day or 1) >= 5 end },
    { text = "一个客人连续跑刀48小时没撤离，最后倒在椅子上。被抬走时手还在按W。", cond = function() return true end },
    { text = "街对面教堂牧师来布道，看见战队训练后沉默了，第二天带了自己儿子来报名。", cond = function() return #teamMembers_ >= 2 end },
    { text = "政府说要修路了。和上次一样，挖了坑就再没下文。", cond = function() return (playerData_.roadLevel or 0) == 0 end },
    { text = "有个小孩在门口用石子摆出了AK-47的形状。他说这是'战术图'。", cond = function() return true end },
    { text = "Victor 今天换了发型。从他的招牌光头变成了脏辫。据说是'转运'。", cond = function() return rivalNpcs_ and #rivalNpcs_ > 0 end },
    { text = "停电第三个小时。全街只有你的发电机还在响。邻居都来蹭WiFi了。", cond = function() return (playerData_.generatorLevel or 0) >= 1 end },
    { text = "一辆满载香蕉的卡车翻了。全村人出来抢香蕉。你的店空了半小时。", cond = function() return true end },
    { text = "Snake 被人看到在夜市帮人修手机。他坚称那是'训练手感'。", cond = function() return HasMember and HasMember("Snake") end },
    { text = "有外国博主来拍'非洲电竞'纪录片，对着你的二手戴尔猛拍。", cond = function() return (playerData_.reputation or 0) >= 30 end },
    { text = "据可靠情报，Blaze Net 的网速是用邻国的信号塔偷来的。", cond = function() return true end },
    { text = "今天的金价又涨了。门口换钱的阿叔笑得比黄金还灿烂。", cond = function() return (playerData_.goldOunces or 0) > 0 end },
    { text = "Mama B 开发了新菜——'冠军烤鸡翅'。就是普通鸡翅加了辣椒，贵两倍。", cond = function() return (playerData_.tournamentWins or 0) >= 1 end },
    { text = "一位自称'前职业选手'的客人进来秀操作，被 Kofi 三局零封教做人。", cond = function() if not HasMember then return false end; for _, m in ipairs(teamMembers_) do if m.name == "Kofi" and m.skill >= 40 then return true end end; return false end },
    { text = "有人在网吧厕所墙上写了'Victor是菜鸡'。你怀疑是 Snake 干的。", cond = function() return HasMember and HasMember("Snake") end },
    { text = "电线杆上的野鸟把网线啄断了。你花了一小时爬上去接好，全街鼓掌。", cond = function() return true end },
    { text = "市长的秘书偷偷来上网。他用的假名是'匿名铁粉420'。", cond = function() return (playerData_.day or 1) >= 15 end },
    { text = "有人声称在你门口看到了一只穿山甲打瞌睡。那其实是 Snake 的旧背包。", cond = function() return true end },
    { text = "三号机的椅子腿终于断了。第四次了。你怀疑是同一个客人。", cond = function() return (playerData_.equipCondition or 100) < 70 end },
    { text = "Grace 在训练间隙画了一张战队漫画，Snake 被画成了一条真蛇。他很满意。", cond = function() return HasMember and HasMember("Grace") and HasMember("Snake") end },
    { text = "对面修车铺老板问你能不能帮他注册一个游戏账号。他今年62了。", cond = function() return true end },
    { text = "某客人跑刀撤离失败37次后开悟了。他说他现在理解了佛学。", cond = function() return true end },
    { text = "有小学生模仿你的店名，在树上钉了块牌子写着'Monkey Net Cafe'。", cond = function() return (playerData_.reputation or 0) >= 20 end },
    { text = "Victor 在社交媒体上说你的网速不行。你的客人在评论区反击了他八百楼。", cond = function() return (playerData_.reputation or 0) >= 40 end },
    { text = "一只猫走进网吧趴在键盘上。你把它抱走时它踩出了一个完美爆头。", cond = function() return true end },
    { text = "深夜两点，外面下暴雨。店里坐满了人。有人说你这是'诺亚方舟'。", cond = function() return true end },
    { text = "发电机冒了一股黑烟。你假装那是'性能蒸汽'。", cond = function() return (playerData_.generatorLevel or 0) >= 1 and (playerData_.fuel or 0) < 5 end },
    { text = "Kofi 的妈妈第一次来了网吧。她看了五分钟，说'这比种地有意思多了'。", cond = function() return (playerData_.npcStoryProgress or {}).kofi and playerData_.npcStoryProgress.kofi >= 3 end },
}

--- 根据当前经营状态选择对应的像素背景图
function GetCafeStateImage()
    local day = playerData_.day or 1
    local genLv = playerData_.generatorLevel or 0
    local fuel = playerData_.fuel or 0
    local solarLv = playerData_.solarLevel or 0
    local cond = playerData_.equipCondition or 100

    -- 优先判断：停电（有发电机但无燃油，且无太阳能）
    if genLv > 0 and fuel <= 0 and solarLv == 0 then
        return "image/cafe_blackout_20260511033517.png"
    end

    -- 优先判断：设备严重老化
    if cond <= 30 then
        return "image/cafe_broken_20260511033520.png"
    end

    -- 起步阶段
    if day <= 3 and (playerData_.computers or 5) <= 5 then
        return "image/cafe_startup_20260511033517.png"
    end

    -- 按客流比判断
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local ratio = traffic / math.max(1, capacity)

    if ratio >= 1.3 then
        return "image/cafe_packed_20260511033525.png"
    elseif ratio >= 1.0 then
        return "image/cafe_full_20260511033517.png"
    elseif ratio >= 0.7 then
        return "image/cafe_normal_20260511033530.png"
    elseif ratio >= 0.4 then
        return "image/cafe_quiet_20260511033518.png"
    else
        return "image/cafe_empty_20260511033516.png"
    end
end

function GetAtmosphere()
    -- 每天只生成一次氛围文字，之后返回缓存
    local day = playerData_.day or 1
    if cachedAtmoDay_ == day and cachedAtmoText_ ~= "" then
        return cachedAtmoText_
    end

    local texts = {}

    -- 1) 天气/环境（随机+时段权重）
    local weatherPool = {}
    for i = 1, #ATMO_WEATHER do
        -- 旱季描述(1-5)在前期权重高，雨季(6-10)在中后期权重高
        local w = 1
        if i <= 5 and day <= 12 then w = 3
        elseif i >= 6 and i <= 10 and day > 10 then w = 3
        else w = 1 end
        for _ = 1, w do table.insert(weatherPool, ATMO_WEATHER[i]) end
    end
    table.insert(texts, weatherPool[math.random(1, #weatherPool)])

    -- 2) 阶段氛围
    local vibePool
    if day <= 5 then vibePool = ATMO_VIBE_EARLY
    elseif day <= 15 then vibePool = ATMO_VIBE_MID
    else vibePool = ATMO_VIBE_LATE end
    table.insert(texts, vibePool[math.random(1, #vibePool)])

    -- 2.5) 状态感知的环境描述 —— 让文字有"触感"
    local cond = playerData_.equipCondition or 100
    local fuel = playerData_.fuel or 0
    local genLv = playerData_.generatorLevel or 0
    local fuelCap = playerData_.fuelCapacity or 20
    local solarLv = playerData_.solarLevel or 0
    local acLv = playerData_.acLevel or 0

    -- 电力/发电机状态描述
    if genLv > 0 and fuel <= 0 then
        local noFuel = {
            "发电机沉默地蹲在墙角，油箱空了。铁皮屋顶下的闷热让人窒息。",
            "没有燃油，发电机只是一堆昂贵的铁。你听见客人在小声抱怨。",
            "发电机的油表指针趴在零上。你盯着它，像盯着一个不争气的朋友。",
        }
        table.insert(texts, noFuel[math.random(1, #noFuel)])
    elseif genLv > 0 and fuel <= math.floor(fuelCap * 0.3) then
        local lowFuel = {
            "发电机发出不均匀的突突声，像个饿坏了的老人在干咳。油快见底了。",
            "柴油味越来越淡——这不是好兆头。发电机的油箱在告急。",
        }
        table.insert(texts, lowFuel[math.random(1, #lowFuel)])
    elseif genLv >= 3 then
        table.insert(texts, "大型静音发电机稳稳地运转着，低频的嗡鸣让人安心，像这栋铁皮房子的心跳。")
    elseif genLv == 0 and solarLv == 0 then
        if math.random() < 0.4 then
            table.insert(texts, "没有发电机，也没有太阳能。你只能祈祷今天别停电。墙上的时钟滴答作响。")
        end
    end

    -- 设备状况描述
    if cond <= 30 then
        local badEquip = {
            "昏暗的灯光下，三台电脑的屏幕在闪烁，像快要断气的萤火虫。键盘上有几个键已经按不下去了。",
            "电脑发出刺耳的风扇尖叫，机箱摸上去烫手。空气里弥漫着烧焦塑料的气味。",
            "鼠标垫磨得起毛了，椅子靠背断了一根支架。客人坐下前会先检查一下椅子还能不能撑住。",
        }
        table.insert(texts, badEquip[math.random(1, #badEquip)])
    elseif cond <= 50 then
        local wornEquip = {
            "电风扇无力地转动着，键盘上积了一层薄薄的红土。有台电脑的USB口松了，鼠标时断时续。",
            "屏幕上有几道划痕，但不影响打游戏——至少客人们是这么说的。机箱盖板用胶带粘着。",
        }
        table.insert(texts, wornEquip[math.random(1, #wornEquip)])
    end

    -- 空调状态描述
    if acLv == 0 then
        if math.random() < 0.3 then
            local noAc = {
                "没有空调，客人们开始抱怨空气中的汗臭味。有人把塑料袋装上水搁在头上降温。",
                "铁皮屋里闷得像蒸笼，客人的手汗把鼠标垫洇湿了一圈深色印子。",
            }
            table.insert(texts, noAc[math.random(1, #noAc)])
        end
    elseif acLv >= 2 then
        if math.random() < 0.25 then
            table.insert(texts, "空调呼呼地吹着冷风，门口挂着的塑料帘子被吹得猎猎作响。外面四十度，里面二十五度。天堂的门票只要两美元。")
        end
    end

    -- 3) 经济状况点评
    if playerData_.money < 300 then
        local broke = {
            "口袋里的美元快见底了。你数了三遍，结果还是一样。",
            "今天又得精打细算。泡面还是烤鸡？这是个问题。",
            "Mama Blessing路过时看了你一眼。那个眼神意味着'需要借钱吗'。",
        }
        table.insert(texts, broke[math.random(1, #broke)])
    elseif playerData_.money > 5000 then
        local rich = {
            "保险柜快装不下了。你开始考虑要不要存银行——如果银行还开门的话。",
            "有人问你是不是毒贩。你说不是，你卖的是梦想，单价$2一小时。",
        }
        table.insert(texts, rich[math.random(1, #rich)])
    end

    -- 4) 客流量氛围
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local tRatio = traffic / math.max(1, capacity)
    if tRatio >= 1.3 then
        table.insert(texts, "门口排起了长队！" .. traffic .. "个客人挤在" .. capacity .. "个位子里，有人自带板凳坐在过道。")
    elseif tRatio >= 1.0 then
        table.insert(texts, "满座。" .. traffic .. "个屏幕同时亮着，键盘声此起彼伏，像一首没有指挥的打字机交响曲。")
    elseif tRatio >= 0.7 then
        table.insert(texts, "今天来了" .. traffic .. "个客人，不算太忙。几台电脑的屏保在安静地转圈。")
    elseif tRatio >= 0.4 then
        table.insert(texts, "有点冷清。" .. traffic .. "个客人散坐着，风扇嗡嗡转，门外偶尔走过一头山羊。")
    else
        table.insert(texts, "空荡荡的。只有" .. traffic .. "个人和一只不请自来的壁虎。你考虑要不要关灯省电。")
    end

    -- 5) 队员状态快照
    if #teamMembers_ > 0 then
        local m = teamMembers_[math.random(1, #teamMembers_)]
        local pool
        if m.mood >= 70 then pool = ATMO_TEAM_SNIPPETS.happy
        elseif m.mood >= 40 then pool = ATMO_TEAM_SNIPPETS.normal
        else pool = ATMO_TEAM_SNIPPETS.low end
        table.insert(texts, string.format(pool[math.random(1, #pool)], m.name))
    end

    -- 5.5) 社区枢纽设施氛围
    local wellLv = playerData_.wellLevel or 0
    local roadLv = playerData_.roadLevel or 0
    local cofLv2 = playerData_.coffeeLevel or 0
    local jbLv2 = playerData_.jukeboxLevel or 0

    if wellLv >= 3 and math.random() < 0.35 then
        table.insert(texts, "太阳能水泵安静地运转，蓄水池里的水清澈见底。几个妇女在井边洗衣聊天，笑声隔着铁皮墙都听得到。")
    elseif wellLv >= 2 and math.random() < 0.35 then
        table.insert(texts, "水塔在阳光下闪着银光。来打水的村民越来越多，有人干脆搬了凳子坐在井边聊天，顺便蹭WiFi。")
    elseif wellLv >= 1 and math.random() < 0.3 then
        table.insert(texts, "门口的压水井咯吱咯吱响，打水的阿婆顺便问WiFi密码。'多少钱一小时？'她翻出一张皱巴巴的纸钞。")
    end

    if roadLv >= 3 and math.random() < 0.35 then
        table.insert(texts, "柏油路面在阳光下泛着热气。晚上太阳能路灯亮起来的时候，门口就变成了小型广场——有人散步，有人跳舞，有人带着板凳看别人打游戏。")
    elseif roadLv >= 2 and math.random() < 0.35 then
        table.insert(texts, "水泥路面干干净净，雨后不到一小时就干了。一辆摩托车平稳地开过门口，司机冲你竖了个大拇指。")
    elseif roadLv >= 1 and math.random() < 0.3 then
        table.insert(texts, "碎石路虽然颠，但至少摩托车不用在泥里推了。今天的灰尘明显比以前少。")
    end

    if cofLv2 >= 3 and math.random() < 0.4 then
        table.insert(texts, "咖啡吧台前坐着三个人——一个在写代码，一个在画画，一个捧着杯子发呆。空气里是现磨咖啡和甜点的香味。这已经不只是网吧了，这是第三空间。")
    elseif cofLv2 >= 2 and math.random() < 0.35 then
        table.insert(texts, "手冲咖啡的香气飘出铁皮墙。有人专门为了一杯咖啡走半小时路来，然后坐下，再也不想走了。")
    elseif cofLv2 >= 1 and math.random() < 0.3 then
        table.insert(texts, "速溶咖啡的香气混着主机散热的暖风，一种奇怪但让人安心的味道。有客人说：'这比家里好闻多了。'")
    end

    if jbLv2 >= 2 and math.random() < 0.4 then
        local jbSongs = { "Burna Boy的'Last Last'", "Wizkid的'Essence'", "一首日本City Pop", "周杰伦的'晴天'" }
        table.insert(texts, "点唱机里放着" .. jbSongs[math.random(1, #jbSongs)] .. "。从Afrobeats到J-Pop到华语流行，在这里一切都能和谐共存。有人在打游戏，有人跟着节奏摇头。音乐让陌生人变成了朋友。")
    elseif jbLv2 >= 1 and math.random() < 0.35 then
        table.insert(texts, "老式点唱机播着Fela Kuti的歌。鼓点震得墙上的面具跟着晃，键盘声和非洲节奏意外地合拍。")
    end

    -- 6) 特殊状态彩蛋
    if playerData_.havocCoins and playerData_.havocCoins > 200 then
        table.insert(texts, "哈弗币账户" .. playerData_.havocCoins .. "枚。在这个国家，这算一笔巨款了。")
    end
    local branchCount = #(playerData_.branches or {})
    if branchCount >= 2 then
        table.insert(texts, "你已经是" .. (branchCount + 1) .. "家网吧的老板了。街坊叫你'Dragon大亨'。")
    end

    -- 7) 街头传闻（每日随机1条）
    if STREET_RUMORS and #STREET_RUMORS > 0 then
        local rumorPool = {}
        for _, r in ipairs(STREET_RUMORS) do
            local ok, pass = pcall(r.cond)
            if ok and pass then table.insert(rumorPool, r.text) end
        end
        if #rumorPool > 0 then
            local seed = day * 7919
            local idx = (seed % #rumorPool) + 1
            table.insert(texts, "💬 " .. rumorPool[idx])
        end
    end

    local result = table.concat(texts, " ")

    -- 缓存当天结果
    cachedAtmoDay_ = day
    cachedAtmoText_ = result

    -- 存入日记（仅记录氛围，日志在 EndDay 中追加）
    if not diaryEntries_[day] then
        diaryEntries_[day] = { atmo = result, logs = {} }
    else
        diaryEntries_[day].atmo = result
    end

    return result
end

--- 带过场动画的章节切换
function StartChapterWithTransition(n)
    local ch = CHAPTERS[n]
    if not ch then
        log:Write(LOG_ERROR, "[StartChapterWithTransition] invalid chapter index: " .. tostring(n))
        currentPhase_ = PHASE_MANAGE; BuildUI()
        return
    end
    StartTransition(ch.title, "Chapter " .. n, function()
        currentChapter_ = n
        -- 播放章节环境音
        if ch.ambient then PlayAmbient(ch.ambient) end
        if ch.bgm then PlayBGM(ch.bgm) end

        -- 优先使用漫画面板模式（如果章节有 comic_panels）
        if ch.comic_panels and #ch.comic_panels > 0 then
            chapterComicPanels_ = ch.comic_panels
            chapterComicIdx_ = 1
            currentPhase_ = PHASE_CHAPTER_COMIC
            BuildUI()
            return
        end

        -- 回退到旧的对话模式
        currentDialogues_ = ch.dialogues
        dialogueIndex_ = 1
        local firstDlg = currentDialogues_[1]
        local isMonologue = firstDlg and (firstDlg.type == "monologue" or firstDlg.speaker == "narrator")
        CinematicDialogue.StartTypewriter(firstDlg.text, isMonologue)
        StartTypewriter(firstDlg.text)
        TryPlayVoiceForDialogue(firstDlg)
        currentPhase_ = PHASE_DIALOGUE
        BuildUI()
    end, ch.atmosphere, n)
end

function StartChapter(n)
    local ch = CHAPTERS[n]
    if not ch then
        log:Write(LOG_ERROR, "[StartChapter] invalid chapter index: " .. tostring(n))
        currentPhase_ = PHASE_MANAGE; BuildUI()
        return
    end
    currentChapter_ = n
    if ch.ambient then PlayAmbient(ch.ambient) end
    if ch.bgm then PlayBGM(ch.bgm) end

    -- 优先使用漫画面板模式
    if ch.comic_panels and #ch.comic_panels > 0 then
        chapterComicPanels_ = ch.comic_panels
        chapterComicIdx_ = 1
        currentPhase_ = PHASE_CHAPTER_COMIC
        BuildUI()
        return
    end

    -- 回退到旧的对话模式
    currentDialogues_ = ch.dialogues
    dialogueIndex_ = 1
    local firstDlg = currentDialogues_[1]
    local isMonologue = firstDlg and firstDlg.type == "monologue"
    CinematicDialogue.StartTypewriter(firstDlg.text, isMonologue)
    StartTypewriter(firstDlg.text)
    TryPlayVoiceForDialogue(firstDlg)
    currentPhase_ = PHASE_DIALOGUE
    BuildUI()
end

--- 跳过整段章节对话（重玩时已读章节可用）
function SkipEntireDialogue()
    StopVoice()
    if pendingStoryEffect_ then
        local eff = pendingStoryEffect_
        local meta = pendingStoryMeta_ or {}
        pendingStoryEffect_ = nil
        pendingStoryMeta_ = nil
        local effOk, effErr = pcall(eff)
        if not effOk then log:Write(LOG_ERROR, "[SkipDialogue] effect error: " .. tostring(effErr)) end
        local narrative = meta.lastText or ""
        local effectStr = narrative:match("【(.-)】")
        local cleanNarrative = narrative:gsub("【.-】", ""):gsub("%s+$", "")
        if cleanNarrative == "" then cleanNarrative = nil end
        eventResult_ = {
            success = true,
            icon = "📖",
            title = meta.title or "剧情事件",
            narrative = cleanNarrative or ("「" .. (meta.title or "剧情") .. "」的故事暂告一段落。"),
            effects = effectStr,
            logText = "📖 " .. (meta.title or "剧情事件") .. " 完成",
        }
        currentPhase_ = PHASE_EVENT
        BuildUI()
        return
    end
    chaptersRead_[currentChapter_] = true
    local ch = CHAPTERS[currentChapter_]
    if ch and ch.skillBoost then
        for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + ch.skillBoost) end
        AddLog("📈 全队技术 +" .. ch.skillBoost .. "!")
    end
    if ch and ch.isFinalBattle then
        -- 剧情锦标赛：设为非洲赛（第3级）
        currentTournamentTier_ = 3
        isFriendlyMatch_ = false
        local tCfg = TOURNAMENT_TIERS[currentTournamentTier_]
        if tCfg then
            matchOpponents_ = {}
            for _, opp in ipairs(tCfg.opponents) do
                table.insert(matchOpponents_, { name = opp.name, power = opp.power, style = opp.style, emoji = opp.emoji, boss = opp.boss })
            end
        end
        matchWins_ = 0; matchRound_ = 0
        local transTitle = tCfg and tCfg.transition.title or "⚔️ 决赛时刻"
        local transSub = tCfg and tCfg.transition.sub or "Dragon Force vs 全非洲"
        StartTransition(transTitle, transSub, function()
            PlayBGM("match")
            currentPhase_ = PHASE_MATCH; matchPhase_ = "intro"; matchLog_ = {}; BuildUI()
        end)
        return
    end
    StartTransition("", "", function()
        PlayBGM("manage")
        currentPhase_ = PHASE_MANAGE; BuildUI()
    end)
end

function AdvanceDialogue()
    if not CinematicDialogue.IsDone() then
        SkipTypewriter()
        -- 就地更新文本，避免重建 UI 导致点击事件传播
        local textLabel = uiRoot_ and uiRoot_:FindById("dialogueText")
        if textLabel then
            local d = currentDialogues_[dialogueIndex_]
            local mono = d and d.type == "monologue"
            local fullText = CinematicDialogue.GetFullText()
            textLabel:SetText(mono and ("「" .. fullText .. "」") or fullText)
        end
        local hintLabel = uiRoot_ and uiRoot_:FindById("dialogueHint")
        if hintLabel then
            hintLabel:SetText((dialogueIndex_ < #currentDialogues_) and "点击继续 ▶" or "点击完成 ✓")
        end
        return
    end

    dialogueIndex_ = dialogueIndex_ + 1
    if dialogueIndex_ > #currentDialogues_ then
        StopVoice()  -- 对话结束，停止语音

        -- 如果是剧情事件对话结束，执行效果并展示结果弹窗
        if pendingStoryEffect_ then
            local eff = pendingStoryEffect_
            local meta = pendingStoryMeta_ or {}
            pendingStoryEffect_ = nil
            pendingStoryMeta_ = nil
            local effOk, effErr = pcall(eff)
            if not effOk then log:Write(LOG_ERROR, "[AdvanceDialogue] effect error: " .. tostring(effErr)) end
            -- 从最后一段对话提取效果说明（【...】包裹的部分）
            local narrative = meta.lastText or ""
            local effectStr = narrative:match("【(.-)】")
            -- 剩余叙事文本（去掉效果说明部分）
            local cleanNarrative = narrative:gsub("【.-】", ""):gsub("%s+$", "")
            if cleanNarrative == "" then cleanNarrative = nil end
            eventResult_ = {
                success = true,
                icon = "📖",
                title = meta.title or "剧情事件",
                narrative = cleanNarrative or ("「" .. (meta.title or "剧情") .. "」的故事暂告一段落。"),
                effects = effectStr,
                logText = "📖 " .. (meta.title or "剧情事件") .. " 完成",
            }
            currentPhase_ = PHASE_EVENT
            BuildUI()
            return
        end

        -- 否则是章节对话结束
        chaptersRead_[currentChapter_] = true
        local ch = CHAPTERS[currentChapter_]
        if ch and ch.skillBoost then
            for _, m in ipairs(teamMembers_) do m.skill = math.min(SKILL_CAP, m.skill + ch.skillBoost) end
            AddLog("📈 全队技术 +" .. ch.skillBoost .. "!")
        end
        if ch and ch.isFinalBattle then
            -- 剧情锦标赛：设为非洲赛（第3级）
            currentTournamentTier_ = 3
            isFriendlyMatch_ = false
            local tCfg2 = TOURNAMENT_TIERS[currentTournamentTier_]
            if tCfg2 then
                matchOpponents_ = {}
                for _, opp in ipairs(tCfg2.opponents) do
                    table.insert(matchOpponents_, { name = opp.name, power = opp.power, style = opp.style, emoji = opp.emoji, boss = opp.boss })
                end
            end
            matchWins_ = 0; matchRound_ = 0
            local transTitle2 = tCfg2 and tCfg2.transition.title or "⚔️ 决赛时刻"
            local transSub2 = tCfg2 and tCfg2.transition.sub or "Dragon Force vs 全非洲"
            StartTransition(transTitle2, transSub2, function()
                PlayBGM("match")
                currentPhase_ = PHASE_MATCH; matchPhase_ = "intro"; matchLog_ = {}; BuildUI()
            end)
            return
        end
        -- 章节结束后淡入管理界面
        StartTransition("", "", function()
            PlayBGM("manage")
            currentPhase_ = PHASE_MANAGE; BuildUI()
        end)
        return
    end
    -- 启动新一句的打字机
    local nextDlg = currentDialogues_[dialogueIndex_]
    local isMonologue = nextDlg and nextDlg.type == "monologue"
    CinematicDialogue.StartTypewriter(nextDlg.text, isMonologue)
    StartTypewriter(nextDlg.text)
    TryPlayVoiceForDialogue(nextDlg)
    BuildUI()
end

--- 网吧等级评定系统（升级总等级 → 星级）
---@return {totalLevel:number, maxLevel:number, star:number, starName:string, nextStarName:string|nil, nextStarAt:number|nil}
function GetCafeRating()
    local totalLevel = 0
    local maxLevel = 0
    local allKeys = {}
    for _, k in ipairs(UPGRADE_ORDER) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_COMMUNITY) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_CULTURE) do table.insert(allKeys, k) end
    for _, key in ipairs(allKeys) do
        local cfg = UPGRADES[key]
        if cfg then
            totalLevel = totalLevel + GetUpgradeCur(key)
            maxLevel = maxLevel + (cfg.costs and #cfg.costs or 0)
        end
    end
    -- 星级阈值
    local tiers = {
        { at = 0,  name = "街边铁皮屋" },
        { at = 8,  name = "社区网吧" },
        { at = 18, name = "镇级网咖" },
        { at = 30, name = "地区旗舰" },
        { at = 45, name = "非洲传奇" },
    }
    local star = 1
    local starName = tiers[1].name
    local nextStarName = tiers[2] and tiers[2].name or nil
    local nextStarAt = tiers[2] and tiers[2].at or nil
    for i = #tiers, 1, -1 do
        if totalLevel >= tiers[i].at then
            star = i
            starName = tiers[i].name
            nextStarName = tiers[i + 1] and tiers[i + 1].name or nil
            nextStarAt = tiers[i + 1] and tiers[i + 1].at or nil
            break
        end
    end
    return {
        totalLevel = totalLevel, maxLevel = maxLevel,
        star = star, starName = starName,
        nextStarName = nextStarName, nextStarAt = nextStarAt,
    }
end

--- 量化收益预估：预估升级某项后的日收入增量
---@param key string
---@return string|nil benefitText
function GetUpgradeBenefitText(key)
    -- 基于 CalcDailyIncome 的各项系数做静态估算
    local benefitMap = {
        computer  = function() return "+$25/天 +3容量" end,
        chair     = function() return "+$5/天 +2容量" end,
        net       = function() return "+$10/天 训练+效率" end,
        ac        = function() return "+$8/天 +2容量" end,
        solar     = function() return "停电保护 省维修费" end,
        food      = function() return "+$18/天 +5客流" end,
        deco      = function() return "+$8/天 +3客流" end,
        security  = function() return "防盗减损 事件保护" end,
        generator = function() return "停电不断网 +油罐容量" end,
        well      = function() return "+声望/天 社区好感" end,
        road      = function() return "+客流 -故障率" end,
        coffee    = function() return "+$15/天 +心情" end,
        jukebox   = function() return "+$5/天 +心情" end,
    }
    local fn = benefitMap[key]
    return fn and fn() or nil
end

--- 检测升级某项后是否接近触发新联动
---@param key string
---@return string|nil synergyHint
function GetUpgradeSynergyHint(key)
    -- 联动条件检测：如果升级 key 后会满足某个联动的前置条件
    local hints = {}
    local function wouldTrigger(cond, name)
        if not cond() then
            -- 模拟升级后再检测
            -- 由于无法简单模拟，这里用静态规则
        end
    end
    -- 静态规则：列出每个联动所需的最后一步
    if key == "chair" then
        local cur = playerData_.chairLevel
        if cur + 1 >= 3 and playerData_.acLevel >= 2 then
            table.insert(hints, "🔗 解锁[舒适环境]联动")
        end
    elseif key == "ac" then
        if playerData_.chairLevel >= 3 and playerData_.acLevel + 1 >= 2 then
            table.insert(hints, "🔗 解锁[舒适环境]联动")
        end
    elseif key == "net" then
        local cur = playerData_.netSpeed
        if cur + 1 >= 3 and playerData_.computers >= 5 then
            table.insert(hints, "🔗 解锁[网咖旗舰]联动")
        end
    elseif key == "computer" then
        if playerData_.computers + 1 >= 5 and playerData_.netSpeed >= 3 then
            table.insert(hints, "🔗 解锁[网咖旗舰]联动")
        end
    elseif key == "food" then
        local cur = playerData_.foodShop
        if cur + 1 >= 2 and playerData_.decoLevel >= 2 then
            table.insert(hints, "🔗 解锁[文化地标]联动")
        end
        if cur + 1 >= 2 and (playerData_.coffeeLevel or 0) >= 2 then
            table.insert(hints, "🔗 解锁[第三空间]联动")
        end
    elseif key == "deco" then
        local cur = playerData_.decoLevel
        if cur + 1 >= 2 and playerData_.foodShop >= 2 then
            table.insert(hints, "🔗 解锁[文化地标]联动")
        end
    elseif key == "coffee" then
        local cur = (playerData_.coffeeLevel or 0)
        if cur + 1 >= 2 and playerData_.foodShop >= 2 then
            table.insert(hints, "🔗 解锁[第三空间]联动")
        end
    elseif key == "solar" then
        local cur = playerData_.solarLevel
        if cur + 1 >= 2 and playerData_.securityLevel >= 1 then
            table.insert(hints, "🔗 解锁[铁壁网吧]联动")
        end
    elseif key == "security" then
        if playerData_.solarLevel >= 2 and playerData_.securityLevel + 1 >= 1 then
            table.insert(hints, "🔗 解锁[铁壁网吧]联动")
        end
    elseif key == "well" then
        local cur = (playerData_.wellLevel or 0)
        if cur + 1 >= 2 and (playerData_.roadLevel or 0) >= 2 then
            table.insert(hints, "🔗 解锁[社区建设者]联动")
        end
    elseif key == "road" then
        local cur = (playerData_.roadLevel or 0)
        if cur + 1 >= 2 and (playerData_.wellLevel or 0) >= 2 then
            table.insert(hints, "🔗 解锁[社区建设者]联动")
        end
    end
    if #hints > 0 then return hints[1] end
    return nil
end

-- ============================================================================
-- 跨模块联动系统
-- ============================================================================

--- 今日顾问建议：扫描6模块状态，返回最优先的一条建议
---@return {icon:string, text:string, hint:string}
function GetDailyAdvisorTip()
    local tips = {} -- {priority, icon, text, hint}

    -- 1. 设备状况差
    local cond = playerData_.equipCondition or 100
    if cond < 30 then
        table.insert(tips, { pri = 100, icon = "⚠️", text = "设备老化严重（" .. cond .. "%）", hint = "升级或维修可恢复收入" })
    elseif cond < 60 then
        table.insert(tips, { pri = 60, icon = "🔧", text = "设备状况一般（" .. cond .. "%）", hint = "维修一下防止突发故障" })
    end

    -- 2. 队员心情低迷
    local avgMood = 0
    if #teamMembers_ > 0 then
        for _, m in ipairs(teamMembers_) do avgMood = avgMood + (m.mood or 50) end
        avgMood = math.floor(avgMood / #teamMembers_)
        if avgMood < 40 then
            table.insert(tips, { pri = 90, icon = "😩", text = "队员状态低迷（平均" .. avgMood .. "）", hint = "逛集市买手链或休息一天" })
        end
    end

    -- 3. 可升级自动化
    local autoLv = playerData_.automationLevel or 0
    if autoLv < 4 then
        local IdleEng = require("IdleEngine")
        local canUp, _ = IdleEng.CanUnlockAutomation(autoLv + 1)
        if canUp then
            local nxt = IdleEng.AUTOMATION_TREE[autoLv + 1]
            table.insert(tips, { pri = 80, icon = "🤖", text = "可升级自动化→" .. (nxt and nxt.name or "下一级"), hint = "离线收益从" .. math.floor((IdleEng.AUTOMATION_TREE[autoLv].offlineRate) * 100) .. "%→" .. math.floor((nxt and nxt.offlineRate or 0) * 100) .. "%" })
        end
    end

    -- 4. 距下一星级差≤3级
    local okR, rating = pcall(GetCafeRating)
    if okR and rating and rating.nextStarAt then
        local gap = rating.nextStarAt - rating.totalLevel
        if gap <= 3 and gap > 0 then
            table.insert(tips, { pri = 75, icon = "⭐", text = "离" .. (rating.nextStarName or "下一星") .. "只差" .. gap .. "级", hint = "冲一波升级！" })
        end
    end

    -- 5. 队员技能可提供折扣但还没到
    if #teamMembers_ > 0 then
        for _, m in ipairs(teamMembers_) do
            if m.skill >= 35 and m.skill < 40 then
                table.insert(tips, { pri = 50, icon = "🎯", text = m.name .. "还差" .. (40 - m.skill) .. "技能到Lv40", hint = "训练后可解锁升级折扣" })
                break
            end
        end
    end

    -- 6. 市场哈弗币充足可抽卡
    local coins = playerData_.havocCoins or 0
    if coins >= 100 and (playerData_.day or 1) >= 5 then
        table.insert(tips, { pri = 40, icon = "🛒", text = "哈弗币×" .. coins .. " 可以淘货", hint = "去市场碰碰运气" })
    end

    -- 7. 转生接近条件
    local PS = require("PrestigeSystem")
    if PS and PS.CalcPrestigeGain then
        local okP, pGain = pcall(PS.CalcPrestigeGain)
        if okP and pGain then
            local current = playerData_.prestigePoints or 0
            local nextCity = nil
            for _, city in ipairs(PS.CITIES) do
                if city.prestigeReq > current then nextCity = city; break end
            end
            if nextCity and (current + pGain) >= nextCity.prestigeReq then
                table.insert(tips, { pri = 85, icon = "🌍", text = "名誉已够开拓" .. nextCity.name, hint = "可以考虑转生扩张！" })
            end
        end
    end

    -- 8. 默认建议
    if #tips == 0 then
        local defaults = {
            { icon = "💡", text = "一切运转正常", hint = "继续升级或训练队员" },
            { icon = "💡", text = "今天适合逛逛集市", hint = "声望越高运气越好" },
            { icon = "💡", text = "多训练队员提升战力", hint = "比赛奖金是大头收入" },
        }
        local pick = defaults[((playerData_.day or 1) % #defaults) + 1]
        ---@diagnostic disable-next-line: return-type-mismatch
        return pick
    end

    -- 返回最高优先级
    table.sort(tips, function(a, b) return a.pri > b.pri end)
    ---@diagnostic disable-next-line: return-type-mismatch
    return { icon = tips[1].icon, text = tips[1].text, hint = tips[1].hint }
end

--- 员工建议折扣：检测队员是否能为某项升级提供折扣
---@param upgradeKey string
---@return number discountPct 折扣百分比(0-30), string|nil memberName
function GetStaffDiscountForUpgrade(upgradeKey)
    if #teamMembers_ == 0 then return 0, nil end
    -- 技术类升级
    local techKeys = { computer = true, net = true, generator = true, solar = true }
    -- 后勤类升级
    local logisKeys = { food = true, coffee = true, chair = true, deco = true, jukebox = true }
    -- 社区类
    local commKeys = { well = true, road = true, security = true }

    for _, m in ipairs(teamMembers_) do
        if m.skill >= 40 then
            -- 高技能队员按擅长方向提供折扣
            if techKeys[upgradeKey] and m.skill >= 50 then
                return 20, m.name
            elseif techKeys[upgradeKey] and m.skill >= 40 then
                return 15, m.name
            elseif logisKeys[upgradeKey] and m.mood >= 70 and m.skill >= 40 then
                return 15, m.name
            elseif commKeys[upgradeKey] and (m.talent or 0) >= 30 then
                return 10, m.name
            end
        end
    end
    return 0, nil
end

--- 自动化软条件检查：返回额外离线效率加成
---@param autoLevel number
---@return number bonusRate (0~0.20), table conditions
function GetAutomationSoftBonus(autoLevel)
    local bonus = 0
    local conditions = {}

    if autoLevel >= 1 then
        -- Lv1条件：升级≥3项
        local totalUpgrades = 0
        local allKeys = {}
        for _, k in ipairs(UPGRADE_ORDER or {}) do table.insert(allKeys, k) end
        for _, k in ipairs(UPGRADE_COMMUNITY or {}) do table.insert(allKeys, k) end
        for _, k in ipairs(UPGRADE_CULTURE or {}) do table.insert(allKeys, k) end
        for _, key in ipairs(allKeys) do
            if GetUpgradeCur(key) > 0 then totalUpgrades = totalUpgrades + 1 end
        end
        local met1 = totalUpgrades >= 3
        table.insert(conditions, { level = 1, desc = "已升级≥3项设施", met = met1, bonus = 0.05 })
        if met1 then bonus = bonus + 0.05 end
    end

    if autoLevel >= 2 then
        -- Lv2条件：队员≥2人
        local met2 = #teamMembers_ >= 2
        table.insert(conditions, { level = 2, desc = "团队≥2人", met = met2, bonus = 0.05 })
        if met2 then bonus = bonus + 0.05 end
    end

    if autoLevel >= 3 then
        -- Lv3条件：市场装备≥3件
        local equipCount = 0
        local meq = playerData_.marketEquipped or {}
        for _, uid in pairs(meq) do
            if uid then equipCount = equipCount + 1 end
        end
        local met3 = equipCount >= 3
        table.insert(conditions, { level = 3, desc = "装备≥3件市场装备", met = met3, bonus = 0.05 })
        if met3 then bonus = bonus + 0.05 end
    end

    if autoLevel >= 4 then
        -- Lv4条件：网吧三星+
        local okR2, r2 = pcall(GetCafeRating)
        local met4 = okR2 and r2 and r2.star >= 3
        table.insert(conditions, { level = 4, desc = "网吧达到三星", met = met4, bonus = 0.05 })
        if met4 then bonus = bonus + 0.05 end
    end

    return bonus, conditions
end

--- 升级里程碑触发市场事件
---@return string|nil eventDesc 触发的事件描述
function CheckUpgradeMilestoneMarketEvent()
    local okR, rating = pcall(GetCafeRating)
    if not okR or not rating then return nil end
    local milestones = playerData_.upgradeMilestones or {}

    -- 二星(8级)：供应商注意到你
    if rating.totalLevel >= 8 and not milestones.star2 then
        playerData_.upgradeMilestones = milestones
        milestones.star2 = true
        playerData_.marketGuarantee3Star = (playerData_.marketGuarantee3Star or 0) + 1
        return "🏪 供应商注意到了你的网吧！下次抽卡保底3星装备"
    end
    -- 三星(18级)：批发商上门
    if rating.totalLevel >= 18 and not milestones.star3 then
        milestones.star3 = true
        playerData_.upgradeMilestones = milestones
        playerData_.marketDiscount = (playerData_.marketDiscount or 0) + 3  -- 3次7折
        return "📦 批发商主动上门！接下来3次抽卡费用-30%"
    end
    -- 四星(30级)：解锁传说池
    if rating.totalLevel >= 30 and not milestones.star4 then
        milestones.star4 = true
        playerData_.upgradeMilestones = milestones
        playerData_.legendPoolUnlocked = true
        return "👑 传说级设备渠道打通！5星装备出率+2%"
    end
    return nil
end

--- 升级联动系统：检测升级组合产生额外加成
function CalcUpgradeSynergies()
    local synergies = {}
    local incomeBonus = 0
    local trainBonus = 0
    local moodBonus = 0

    -- 组合1: 电竞椅 + 空调 = "舒适环境" → 收入+15%, 训练效率+2
    if playerData_.chairLevel >= 3 and playerData_.acLevel >= 2 then
        table.insert(synergies, { name = "🛋️ 舒适环境", desc = "电竞椅+空调 → 收入+15% 训练+2" })
        incomeBonus = incomeBonus + 15
        trainBonus = trainBonus + 2
    end

    -- 组合2: 高速网 + 电脑5台+ = "网咖旗舰" → 收入+20%
    if playerData_.netSpeed >= 3 and playerData_.computers >= 5 then
        table.insert(synergies, { name = "💻 网咖旗舰", desc = "高速网+5台电脑 → 收入+20%" })
        incomeBonus = incomeBonus + 20
    end

    -- 组合3: 烤鸡摊 + 非洲装饰 = "文化地标" → 声望收入加倍, 心情+5/天
    if playerData_.foodShop >= 2 and playerData_.decoLevel >= 2 then
        table.insert(synergies, { name = "🎭 文化地标", desc = "烤鸡摊+装饰 → 声望收入x2 心情+5" })
        incomeBonus = incomeBonus + 10
        moodBonus = moodBonus + 5
    end

    -- 组合4: 太阳能 + 保安 = "铁壁网吧" → 随机负面事件损失减半
    if playerData_.solarLevel >= 2 and playerData_.securityLevel >= 1 then
        table.insert(synergies, { name = "🛡️ 铁壁网吧", desc = "太阳能+保安 → 负面事件损失减半" })
    end

    -- 组合5: 全部升级至少1级 = "全面发展" → 收入+25%
    if playerData_.chairLevel >= 2 and playerData_.netSpeed >= 2 and playerData_.acLevel >= 1
        and playerData_.solarLevel >= 1 and playerData_.foodShop >= 1
        and playerData_.decoLevel >= 1 and playerData_.securityLevel >= 1 then
        table.insert(synergies, { name = "⭐ 全面发展", desc = "全项升级 → 收入+25%" })
        incomeBonus = incomeBonus + 25
    end

    -- ── v7 社区枢纽联动 ──

    -- 组合6: 咖啡吧台 + 烤鸡摊 = "第三空间" → 收入+15%
    if (playerData_.coffeeLevel or 0) >= 2 and playerData_.foodShop >= 2 then
        table.insert(synergies, { name = "☕ 第三空间", desc = "咖啡+美食 → 网吧变社交中心 收入+15%" })
        incomeBonus = incomeBonus + 15
    end

    -- 组合7: 水井 + 修路 = "社区建设者" → 故障率-50%（在CalcDailyExpenses中额外处理），声望每日+3
    if (playerData_.wellLevel or 0) >= 2 and (playerData_.roadLevel or 0) >= 2 then
        table.insert(synergies, { name = "🏗️ 社区建设者", desc = "水井+修路 → 故障率-50% 声望+3/天" })
    end

    -- 组合8: 点唱机 + 装饰 = "文化沙龙" → 心情+8/天
    if (playerData_.jukeboxLevel or 0) >= 1 and playerData_.decoLevel >= 2 then
        table.insert(synergies, { name = "🎶 文化沙龙", desc = "音乐+装饰 → 心情+8/天" })
        moodBonus = moodBonus + 8
    end

    -- 组合9: 10台电脑 + 发电机 + 空调 = "电竞工厂" → 收入+30%
    if playerData_.computers >= 10 and (playerData_.generatorLevel or 0) >= 2 and playerData_.acLevel >= 2 then
        table.insert(synergies, { name = "🏭 电竞工厂", desc = "10+电脑+发电机+空调 → 收入+30%" })
        incomeBonus = incomeBonus + 30
    end

    -- 协同收入加成封顶80%，避免后期滚雪球
    incomeBonus = math.min(80, incomeBonus)

    return synergies, incomeBonus, trainBonus, moodBonus
end

--- 检查是否有"铁壁网吧"联动（负面事件损失减半）
function HasIronFortress()
    return playerData_.solarLevel >= 2 and playerData_.securityLevel >= 1
end

--- 计算网吧容量（最大同时容纳顾客数）
function CalcCafeCapacity()
    local base = playerData_.computers * 3               -- 每台电脑容纳3批客人（轮换）
    local chairBonus = (playerData_.chairLevel - 1) * 2  -- 舒适椅让人久坐 → 容量+
    local acBonus = playerData_.acLevel * 2              -- 空调防中暑 → 容量+
    -- P1-1 休闲专精：客流上限 +5
    local specBonus = (playerData_.specialization == "casual") and 5 or 0
    return base + chairBonus + acBonus + specBonus
end

--- 计算当日客流量（原始值，含随机波动）
function CalcCustomerTrafficRaw()
    -- 基础客流：电脑数 × 2（自然来客量）
    local base = playerData_.computers * 2
    -- 升级吸引力
    local attract = 0
    attract = attract + (playerData_.chairLevel - 1) * 2   -- 舒适座椅
    attract = attract + (playerData_.netSpeed - 1) * 3     -- 网速口碑
    attract = attract + playerData_.acLevel * 2             -- 空调吸引力（降低，容量已补偿）
    attract = attract + playerData_.foodShop * 5            -- 烤鸡摊是核心引流
    attract = attract + playerData_.decoLevel * 3           -- 装饰引流增强
    attract = attract + (playerData_.wellLevel or 0) * 3    -- 水井：村民来打水顺便上网
    attract = attract + (playerData_.roadLevel or 0) * 4    -- 修路：交通改善引流
    attract = attract + (playerData_.coffeeLevel or 0) * 4  -- 咖啡：社交场所吸引力
    attract = attract + (playerData_.jukeboxLevel or 0) * 2 -- 点唱机：音乐吸引
    -- 声望引流（已移至等级段乘数，见下方 repTrafficMod）
    -- 队员效应（有队员训练吸引围观 + 跑刀收益）
    attract = attract + #teamMembers_ * 3
    -- 日期波动（模拟周末/工作日）
    local dayMod = 1.0
    local weekday = ((playerData_.day - 1) % 7) + 1
    if weekday >= 6 then dayMod = 1.25 end      -- 周末 +25%
    if weekday == 3 then dayMod = 0.85 end       -- 周三低谷
    -- 随机波动 ±12%
    local randMod = 0.88 + math.random() * 0.24
    -- 事件加成
    -- P1-6: 今日特别行动带来的流量加成
    local specialEventMod = 1.0
    if dailySpecialEvent_ and dailySpecialEvent_.modifier == "traffic" then
        specialEventMod = 1.0 + ((dailySpecialEvent_.modValue or 20) / 100)
    end
    -- P2-3: 竞争对手分流（rivalNpcs_ 中每个对手按其 stealPct 扣减）
    local rivalStealMod = 1.0
    if rivalNpcs_ and #rivalNpcs_ > 0 then
        local totalSteal = 0
        for _, rival in ipairs(rivalNpcs_) do
            totalSteal = totalSteal + (rival.stealPct or 0)
        end
        -- 最多扣减 35%，避免游戏体验崩坏
        rivalStealMod = 1.0 - math.min(0.35, totalSteal / 100)
    end
    -- 2.5 天气系统影响客流
    local weatherMod = 1.0
    if GetWeatherEffects then
        local wfx = GetWeatherEffects()
        weatherMod = 1.0 + (wfx.traffic or 0)
    end
    -- 旅行者客流 buff
    local travTrafficMod = 1.0
    if TravelerSystem and TravelerSystem.GetTrafficBonus then
        local ttOk, ttBonus = pcall(TravelerSystem.GetTrafficBonus)
        if ttOk and ttBonus and ttBonus > 0 then
            travTrafficMod = 1.0 + ttBonus
        end
    end
    -- 声望等级段客流乘数
    local repTrafficMod = ReputationSystem.GetTrafficMultiplier()
    -- 网红效应：邀请当天客流×2
    local influencerMod = 1.0
    if ReputationSystem.IsInfluencerActive() then
        influencerMod = 2.0
    end
    -- ── TabSubQuests 支线客流效果 ──
    -- 定价策略客流乘数（平民价+20%客流，高端价-15%客流）
    local priceFlowMod = playerData_.flowMultiplier or 1.0
    -- 小贩拜访带来的次日客流加成（值为0~1小数如0.15=+15%）
    local subqFlowMod = 1.0
    local activeFlow = playerData_.activeFlowBonus or 0
    if activeFlow > 0 then
        subqFlowMod = 1.0 + activeFlow
    end
    -- 主题活动日客流效果（电竞之夜x2，新手体验日+30%）
    local themeMod = 1.0
    local tb = playerData_.themeBonus
    if tb then
        if tb.name == "电竞之夜" then
            themeMod = 2.0
        elseif tb.name == "新手体验日" then
            themeMod = 1.3
        elseif tb.name == "女性优惠日" then
            themeMod = 1.2
        end
    end

    local total = (base + attract + trafficBonus_) * dayMod * randMod * specialEventMod * rivalStealMod * weatherMod * travTrafficMod * repTrafficMod * influencerMod * priceFlowMod * subqFlowMod * themeMod
    return math.max(1, math.floor(total))
end

--- 获取当日客流（带缓存，同一天内只计算一次）
function RefreshTraffic()
    if cachedTrafficDay_ ~= playerData_.day then
        cachedTraffic_ = CalcCustomerTrafficRaw()
        cachedTrafficDay_ = playerData_.day
    end
    return cachedTraffic_
end

--- 客流利用率描述
--- 格式化大数值（$1234567 → $1.23M）
function FormatMoney(n)
    if n == nil then return "$0" end
    local abs = math.abs(n)
    local sign = n < 0 and "-" or ""
    if abs >= 1000000000 then
        return sign .. "$" .. string.format("%.2fB", abs / 1000000000)
    elseif abs >= 1000000 then
        return sign .. "$" .. string.format("%.2fM", abs / 1000000)
    elseif abs >= 100000 then
        return sign .. "$" .. string.format("%.1fK", abs / 1000)
    else
        return sign .. "$" .. tostring(abs)
    end
end

function GetTrafficDesc(traffic, capacity)
    local ratio = traffic / math.max(1, capacity)
    if ratio >= 1.3 then return "🔥爆满", C.red
    elseif ratio >= 1.0 then return "👥满员", C.green
    elseif ratio >= 0.7 then return "📈正常", C.accent
    elseif ratio >= 0.4 then return "📉冷清", C.textDim
    else return "💤空荡", C.red end
end


--- 全局工具：应用城市成本系数到基础费用
--- @param baseCost number 基础费用
--- @return number 乘以城市系数后的费用（向下取整）
function GetCityCost(baseCost)
    local ok, MarketData = pcall(require, "MarketData")
    if ok and MarketData and MarketData.GetCityCostMultiplier then
        return math.floor(baseCost * MarketData.GetCityCostMultiplier())
    end
    return baseCost
end

function CalcDailyIncome()
    local base = playerData_.computers * 25   -- 每台 $20→$25（ROI 从53天→25天）
    local upgrade = (playerData_.chairLevel - 1) * 5 + (playerData_.netSpeed - 1) * 10
                  + playerData_.acLevel * 8
    local food = playerData_.foodShop * 18       -- 烤鸡摊（降低ROI，从25→18）
    local deco = playerData_.decoLevel * 8       -- 装饰回头客（降低ROI，从10→8）
    local cofIncome = (playerData_.coffeeLevel or 0) * 15  -- 咖啡吧台高利润
    local jbIncome = (playerData_.jukeboxLevel or 0) * 5   -- 点唱机投币收入
    -- 声望VIP每日被动收入
    local repVipIncome = ReputationSystem.GetVipDailyIncome()

    -- 队员跑刀直接收入（技术越高，跑刀赚的越多）
    local teamIncome = 0
    for _, m in ipairs(teamMembers_) do
        teamIncome = teamIncome + 18 + math.floor(m.skill / 3) + math.floor(m.talent / 10)
    end

    local subtotal = base + upgrade + food + deco + cofIncome + jbIncome + repVipIncome + teamIncome

    -- 客流利用率影响收入
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local utilization = traffic / math.max(1, capacity)
    if utilization < 1.0 then
        -- 客流不足，收入按比例降低（最低 60%）
        subtotal = math.floor(subtotal * math.max(0.6, utilization))
    elseif utilization > 1.0 then
        -- 客流溢出，排队轮换带来额外收入（上限 +30%）
        local overflow = math.min(1.3, utilization)
        subtotal = math.floor(subtotal * overflow)
    end

    -- 应用联动加成
    local _, incomeBonus = CalcUpgradeSynergies()
    if incomeBonus > 0 then
        subtotal = subtotal + math.floor(subtotal * incomeBonus / 100)
    end

    -- 设备状况影响收入
    local cond = playerData_.equipCondition or 100
    if cond < 80 then
        local condMult = cond < 50 and 0.5 or (0.7 + cond / 100 * 0.3)
        subtotal = math.floor(subtotal * condMult)
    end

    -- 分店被动收入（含游戏加成）
    local branches = playerData_.branches or {}
    for _, br in ipairs(branches) do
        local brIncome = br.income or 40
        if br.gameBonusType == "income" then     -- PUBG: 日收入+20%
            brIncome = math.floor(brIncome * 1.2)
        elseif br.gameBonusType == "combat" then -- CS:GO: 战力转化收入+8
            brIncome = brIncome + 8
        end
        subtotal = subtotal + brIncome
    end

    -- 黄金VIP卡：每日收入+15%
    if playerData_.goldVIP then
        subtotal = subtotal + math.floor(subtotal * 0.15)
    end

    -- 二手市场装备加成
    if Market and Market.CalcEquippedEffects then
        local ok, mfx = pcall(Market.CalcEquippedEffects)
        if ok and mfx then
            if mfx.dailyMoneyBonus and mfx.dailyMoneyBonus > 0 then
                subtotal = subtotal + math.floor(mfx.dailyMoneyBonus)
            end
            if mfx.allRevenueBonus and mfx.allRevenueBonus > 0 then
                subtotal = subtotal + math.floor(subtotal * mfx.allRevenueBonus)
            end
            if mfx.trafficBonus and mfx.trafficBonus > 0 then
                trafficBonus_ = (trafficBonus_ or 0) + mfx.trafficBonus
            end
        end
    end

    -- 装饰槽位加成（Batch 3）
    if Market and Market.CalcDecoEffects then
        local ok2, dfx = pcall(Market.CalcDecoEffects)
        if ok2 and dfx then
            if dfx.dailyMoneyBonus and dfx.dailyMoneyBonus > 0 then
                subtotal = subtotal + math.floor(dfx.dailyMoneyBonus)
            end
            if dfx.allRevenueBonus and dfx.allRevenueBonus > 0 then
                subtotal = subtotal + math.floor(subtotal * dfx.allRevenueBonus)
            end
            if dfx.trafficBonus and dfx.trafficBonus > 0 then
                trafficBonus_ = (trafficBonus_ or 0) + dfx.trafficBonus
            end
            if dfx.repBonus and dfx.repBonus > 0 then
                playerData_.reputation = playerData_.reputation + math.floor(dfx.repBonus * 10)
            end
        end
    end

    -- ── 事件联动加成（Batch 6）──
    local okEL, EventLinkage = pcall(require, "EventLinkage")
    if okEL and EventLinkage and EventLinkage.GetIncomeBonus then
        local ok3, multi3, flat3 = pcall(function()
            local m, f = EventLinkage.GetIncomeBonus()
            return m, f
        end)
        if ok3 then
            if flat3 and flat3 > 0 then
                subtotal = subtotal + math.floor(flat3)
            end
            if multi3 and multi3 > 0 then
                subtotal = subtotal + math.floor(subtotal * multi3)
            end
        end
    end

    -- ── 转生加成 & 城市收入加成 ──
    local prestigeMult = PrestigeSystem.CalcPrestigeMultiplier()
    if prestigeMult > 1.0 then
        local bonus = math.floor(subtotal * (prestigeMult - 1.0))
        subtotal = subtotal + bonus
    end
    local cityInfo = PrestigeSystem.GetCurrentCity()
    if cityInfo and cityInfo.incomeMulti and cityInfo.incomeMulti > 1.0 then
        local cityBonus = math.floor(subtotal * (cityInfo.incomeMulti - 1.0))
        subtotal = subtotal + cityBonus
    end

    -- P1-1 专精加成
    local spec = playerData_.specialization
    if spec == "casual" then
        subtotal = subtotal + math.floor(subtotal * 0.20)   -- 休闲：日收入 +20%
    elseif spec == "trader" then
        subtotal = subtotal + 15                            -- 商贸：固定被动收入 +15/天
    end
    -- esports 加成在比赛奖励结算处应用，这里不计入日常收入

    -- P1-2 名誉里程碑收入加成
    local honorBonus = playerData_.honorIncomeBonus or 0
    if honorBonus > 0 then
        subtotal = subtotal + math.floor(subtotal * honorBonus / 100)
    end

    -- 新手保护期：Day1 ×1.5（开业热度），Day2-3 ×1.3，Day4+ 无保护
    if playerData_.day <= 1 then
        subtotal = math.floor(subtotal * 1.5)
    elseif playerData_.day <= 3 then
        subtotal = math.floor(subtotal * 1.3)
    end

    -- 旅行者收入 buff
    if TravelerSystem and TravelerSystem.GetIncomeBonus then
        local tiOk, tiBonus = pcall(TravelerSystem.GetIncomeBonus)
        if tiOk and tiBonus and tiBonus > 0 then
            subtotal = subtotal + math.floor(subtotal * tiBonus)
        end
    end

    -- 2.5 天气系统影响收入
    if GetWeatherEffects then
        local wfx = GetWeatherEffects()
        if wfx.income and wfx.income ~= 0 then
            subtotal = math.floor(subtotal * (1.0 + wfx.income))
        end
    end

    -- 声望等级段收入乘数
    local repIncomeMod = ReputationSystem.GetIncomeMultiplier()
    if repIncomeMod > 1.0 then
        subtotal = subtotal + math.floor(subtotal * (repIncomeMod - 1.0))
    end

    -- 集市摊贩支线故事：每日收入加成（Kwame合伙+$15，Ama导师+$10）
    local msOk, MarketStorylines = pcall(require, "MarketStorylines")
    if msOk and MarketStorylines and MarketStorylines.GetBonuses then
        local bOk, bonuses = pcall(MarketStorylines.GetBonuses)
        if bOk and bonuses and bonuses.dailyIncome and bonuses.dailyIncome > 0 then
            subtotal = subtotal + math.floor(bonuses.dailyIncome)
        end
    end

    -- ── TabSubQuests 支线效果 ──
    -- 定价策略乘数（平民价0.75收入但高客流，高端价1.5收入但低客流）
    local priceMult = playerData_.priceMultiplier or 1.0
    if priceMult ~= 1.0 then
        subtotal = math.floor(subtotal * priceMult)
    end
    -- 增值服务被动收入（打印/零食/VIP包间等）
    local passiveInc = playerData_.passiveIncome or 0
    if passiveInc > 0 then
        subtotal = subtotal + passiveInc
    end
    -- 主题活动日加成（怀旧游戏日：小费+50%即收入+15%；新手体验日：潜在常客加2客流已在traffic处理）
    local tb = playerData_.themeBonus
    if tb then
        if tb.name == "怀旧游戏日" then
            subtotal = subtotal + math.floor(subtotal * 0.15)
        elseif tb.name == "电竞之夜" then
            -- 电竞之夜主要是客流翻倍（在traffic处），收入额外+10%气氛消费
            subtotal = subtotal + math.floor(subtotal * 0.10)
        end
    end

    return subtotal
end

--- 计算每日支出明细
function CalcDailyExpenses()
    local expenses = {}
    local total = 0

    -- 1. 房租：基础20，每10天涨5，封顶60（初期减压，后期仍有张力）
    local rent = math.min(60, 20 + math.floor((playerData_.day - 1) / 10) * 5)
    table.insert(expenses, { name = "🏠 房租", amount = rent })
    total = total + rent

    -- 2. 电费：$5→$3/台（降低早期固定成本）
    local electricity = playerData_.computers * 3
    table.insert(expenses, { name = "💡 电费", amount = electricity })
    total = total + electricity

    -- 3. 队员工资：每人每天消耗
    if #teamMembers_ > 0 then
        local wages = 0
        for _, m in ipairs(teamMembers_) do
            wages = wages + (m.fee or 30)
        end
        table.insert(expenses, { name = "💰 队员工资", amount = wages })
        total = total + wages
    end

    -- 3.5 咖啡吧运营成本（咖啡豆、牛奶、杯子）
    local cofLv = playerData_.coffeeLevel or 0
    if cofLv > 0 then
        local cofCost = cofLv * 5
        table.insert(expenses, { name = "☕ 咖啡原料", amount = cofCost })
        total = total + cofCost
    end

    -- 4. 设备维护：随升级等级增加
    local maintenance = (playerData_.chairLevel - 1) * 3 + (playerData_.netSpeed - 1) * 5
                      + playerData_.acLevel * 4
    if maintenance > 0 then
        table.insert(expenses, { name = "🔧 设备维护", amount = maintenance })
        total = total + maintenance
    end

    -- 5. 随机设备故障（基础10%概率，修路降低故障率，第5天后才触发）
    local faultChance = math.max(0.02, 0.10 - (playerData_.roadLevel or 0) * 0.02)
    if playerData_.day > 5 and math.random() < faultChance then
        local repairCost = math.random(15, 45) + playerData_.computers * 3
        table.insert(expenses, { name = "⚠️ 设备故障维修", amount = repairCost })
        total = total + repairCost
    end

    -- 6. 发电机燃油消耗（有发电机时每日消耗燃油）
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 and (playerData_.fuel or 0) > 0 then
        local fuelUse = { 3, 5, 4 }  -- Lv3大型静音发电机效率更高
        local used = math.min(fuelUse[genLv] or 4, playerData_.fuel)
        playerData_.fuel = playerData_.fuel - used
        -- 燃油本身已购买，此处不额外扣钱，但记录消耗
        table.insert(expenses, { name = "⛽ 燃油消耗 " .. used .. "L", amount = 0 })
    end

    -- 7. 分店运营费（按分店数递增）
    local branches = playerData_.branches or {}
    if #branches > 0 then
        local branchCost = 0
        for i = 1, #branches do
            branchCost = branchCost + 15 + i * 8  -- 第1家23, 第2家31, 第3家39
        end
        table.insert(expenses, { name = "🏪 分店运营×" .. #branches, amount = branchCost })
        total = total + branchCost
    end

    -- 8. 后期动态支出：设备老化（第15天后，按电脑数和天数递增）
    if playerData_.day >= 15 then
        local agingCost = math.floor(playerData_.computers * 2 + (playerData_.day - 15) * 1.5)
        table.insert(expenses, { name = "🔩 设备老化", amount = agingCost })
        total = total + agingCost
    end

    -- 9. 后期动态支出：地方税收（第20天后，按总收入的5%征税）
    if playerData_.day >= 20 then
        local estimatedIncome = playerData_.computers * 20 + #teamMembers_ * 25
        local tax = math.floor(estimatedIncome * 0.05 + #(playerData_.branches or {}) * 10)
        if tax > 0 then
            table.insert(expenses, { name = "🏛️ 地方税", amount = tax })
            total = total + tax
        end
    end

    return expenses, total
end

--- 黄金价格：基于正弦波+噪声的确定性价格函数
--- 基准$165，振幅$45，14天周期，范围约$120-$210
--- 政变期间金价飙升2.5倍（恐慌性抢购）
function GetGoldPrice(day)
    local base = 165
    local amp = 45
    local period = 14
    local wave = math.sin(2 * math.pi * (day or playerData_.day) / period)
    -- 加入基于天数的伪随机噪声（确定性，相同天数=相同价格）
    local seed = ((day or playerData_.day) * 7 + 13) % 100
    local noise = (seed - 50) / 50 * 15  -- -15 ~ +15 的噪声
    local price = math.floor(base + amp * wave + noise)
    -- 政变期间金价飙升
    if (playerData_.coupDaysLeft or 0) > 0 then
        price = math.floor(price * 2.5)
    end
    return price
end

--- 政变状态检查
function IsCoupActive()
    return (playerData_.coupDaysLeft or 0) > 0
end

--- 将现金金额转换为政变期间所需黄金盎司（向上取整到0.1）
function CoupGoldCost(cashAmount)
    local price = GetGoldPrice()
    return math.ceil(cashAmount / price * 10) / 10
end

--- 政变期间的统一支付函数
--- 正常时扣现金；政变时扣等值黄金
--- @return boolean 是否支付成功
--- @return string 支付方式描述（用于日志）
function TryPayCost(cashAmount)
    if not IsCoupActive() then
        if playerData_.money >= cashAmount then
            playerData_.money = playerData_.money - cashAmount
            return true, "$" .. cashAmount
        end
        return false, ""
    else
        local goldNeeded = CoupGoldCost(cashAmount)
        if (playerData_.goldOunces or 0) >= goldNeeded then
            playerData_.goldOunces = playerData_.goldOunces - goldNeeded
            if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
            return true, string.format("%.1foz黄金", goldNeeded)
        end
        return false, ""
    end
end

--- 政变期间判断是否买得起（正常用money，政变用gold）
function CanAffordCost(cashAmount)
    if not IsCoupActive() then
        return playerData_.money >= cashAmount
    else
        return (playerData_.goldOunces or 0) >= CoupGoldCost(cashAmount)
    end
end

--- 获取价格显示文本（正常显示$，政变显示黄金）
function FormatCostText(cashAmount)
    if not IsCoupActive() then
        return "$" .. cashAmount
    else
        return string.format("%.1foz🥇", CoupGoldCost(cashAmount))
    end
end

