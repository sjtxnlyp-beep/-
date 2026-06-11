-- ============================================================
-- EasterEggs.lua — 彩蛋系统（渐进式隐藏内容）
-- 设计原则: 升级即叙事，让玩家感受到世界在生长
-- 调用方式:
--   EasterEggs.OnUpgradeComplete(key)  -- 升级完成后
--   EasterEggs.OnBlackout()            -- 停电事件触发时
--   EasterEggs.OnPrestige(count)       -- 转生完成后
--   EasterEggs.OnDailySettle()         -- 每日结算时（随机触发）
-- ============================================================

local EasterEggs = {}

-- ============================================================
-- 内部工具
-- ============================================================

--- 标记彩蛋为已触发（防重复）
local function MarkTriggered(eggId)
    playerData_.eggsTriggered = playerData_.eggsTriggered or {}
    playerData_.eggsTriggered[eggId] = true
end

--- 检查彩蛋是否已触发
local function IsTriggered(eggId)
    return playerData_.eggsTriggered and playerData_.eggsTriggered[eggId]
end

--- 增加计数器并返回新值
local function IncrementCounter(counterId)
    playerData_.eggCounters = playerData_.eggCounters or {}
    playerData_.eggCounters[counterId] = (playerData_.eggCounters[counterId] or 0) + 1
    return playerData_.eggCounters[counterId]
end

--- 获取计数器值
local function GetCounter(counterId)
    playerData_.eggCounters = playerData_.eggCounters or {}
    return playerData_.eggCounters[counterId] or 0
end

-- ============================================================
-- 彩蛋1: 点唱机·时代之声
-- 升级点唱机时，歌曲从 70 年代到当代逐步进化
-- ============================================================

local JUKEBOX_ERAS = {
    [1] = {
        era = "70年代 · Afrobeat",
        logs = {
            "🎵 点唱机里传出 Fela Kuti 式的鼓点和萨克斯。有人跟着节拍拍桌子，差点把显示器拍下来。",
            "🎵 黑胶唱片的噪音和铜管乐交织在一起。Uncle Charles闭上眼说：'这是Lagos黄金年代的声音。'",
        },
    },
    [2] = {
        era = "90年代 · 刚果伦巴",
        logs = {
            "🎵 旋律变得悠扬了——吉他如流水，歌声如诗。一位老客人闭上眼睛说：'这是我年轻时跳舞的歌。'",
            "🎵 刚果伦巴的节拍在空气中回旋。Mama Blessing在门口跟着扭了几步，假装是在赶苍蝇。",
        },
    },
    [3] = {
        era = "00年代 · Naija流行",
        logs = {
            "🎵 节拍加快了！三个少年在电脑前偷偷练P-Square的舞步，以为没人看见——全网吧都在看。",
            "🎵 嘻哈鼓机+非洲旋律=全场跟着点头。有人用空水瓶当沙锤伴奏，效果出奇地好。",
        },
    },
    [4] = {
        era = "10年代 · Afrobeats",
        logs = {
            "🎵 Wizkid风格的电子节拍渗进了每台电脑的缝隙。隔壁杂货店的老板娘专门跑来问：'这歌哪里下载的？'",
            "🎵 Burna Boy式的低吟在网吧里回荡。有个客人边打字边唱副歌，全场没人叫他安静——因为唱得真挺好。",
        },
    },
    [5] = {
        era = "当代 · Amapiano",
        logs = {
            "🎵 深沉的贝斯线和钢琴采样交织——Amapiano的浪潮终于涌到了这个小村子。一个从拉各斯来的DJ说：'你这点唱机的品味比城里的夜店还好。'",
            "🎵 全球融合曲风从音箱里流出。有个客人用Shazam识别了一首歌，发现它在Spotify全球榜第37名。他惊呼：'我们村在听全球前50！'",
        },
    },
}

-- 点唱机终极彩蛋（满级后1%概率）
local JUKEBOX_ULTIMATE = "🎵 点唱机突然自己换了一首从没听过的歌。所有人都安静了——旋律古老、温暖，像来自很久以前的记忆。Uncle Charles摘下帽子，轻声说：'这是你爷爷最爱的歌。他当年就是听着这歌，决定在这里建第一栋房子的。'"

-- ============================================================
-- 彩蛋2: 电脑屏幕·玩家进化史
-- 电脑升级时，客人的"活动"随之进化
-- ============================================================

local COMPUTER_EVOLUTION = {
    { minLevel = 1, maxLevel = 2, id = "comp_email",
      logs = {
          "💻 有人用了一整个小时写一封邮件，删了改、改了删。最后发出去时长舒一口气——像完成了人生大事。",
          "💻 一个妈妈在网吧给城里上学的儿子发了张照片。她反复确认了三遍'真的发出去了吗'。",
      } },
    { minLevel = 3, maxLevel = 4, id = "comp_video",
      logs = {
          "💻 一个孩子第一次看到视频里的雪，问：'那些白色的东西是坏掉的米吗？'全场笑翻。",
          "💻 有人发现了YouTube上的做菜频道，连看了三个小时。出门时说今晚要做'意大利面'——用的是本地的木薯粉。",
      } },
    { minLevel = 5, maxLevel = 6, id = "comp_gaming",
      logs = {
          "💻 一局吃鸡团灭后，五个人同时摘下耳机，互相指责了十分钟。然后默契地又开了一局。",
          "💻 三角洲行动里有人1v5翻盘，整个网吧爆发出欢呼声。他站起来鞠躬致谢，像个摇滚明星。",
      } },
    { minLevel = 7, maxLevel = 8, id = "comp_remote",
      logs = {
          "💻 有人在你的网吧里远程面试了一份工作——他被录取了。出门时请全场喝了一轮可乐。",
          "💻 一个设计师在这里完成了客户的logo，酬金是你三天的网费收入。她说这是她在五个国家远程工作的第七个'办公室'。",
      } },
    { minLevel = 9, maxLevel = 99, id = "comp_creator",
      logs = {
          "💻 一个女孩在你的电脑上做了一首歌发到网上，一周后涨了十万粉。她把第一笔收入的10%给了你当网费。",
          "💻 有人用AI生成了一幅画，打印出来裱在网吧墙上。来看画的人比来上网的还多。",
          "💻 一个程序员在这里写了一个APP的原型，三个月后它出现在了应用商店的推荐页。他在致谢里写了：'感谢Dragon Net Cafe提供的WiFi和灵感。'",
      } },
}

-- ============================================================
-- 彩蛋3: 修路·路过的人
-- 路升级后，门前的交通和路人变化
-- ============================================================

local ROAD_SCENES = {
    { minLevel = 1, maxLevel = 1, id = "road_donkey",
      logs = {
          "🛤️ 一头驴在门口停下来不走了。它盯着网吧的招牌看了很久——像是在阅读。主人拽了半天才把它拉走。",
          "🛤️ 泥路上深深的车辙积了雨水，成了鸭子的游泳池。客人说进门得先脱鞋洗脚。",
      } },
    { minLevel = 2, maxLevel = 2, id = "road_moto",
      logs = {
          "🛤️ 一辆摩托后座绑了一台二手电视。骑手冲你竖起大拇指：'等我存够钱也来上网！'",
          "🛤️ 碎石路上扬起的尘土少了很多。有客人说：'终于不用边上网边吃土了。'",
      } },
    { minLevel = 3, maxLevel = 99, id = "road_tourism",
      logs = {
          "🛤️ 一辆旅游巴士竟然停下来拍照。导游举着喇叭说：'这就是著名的Dragon Net Cafe！非洲互联网精神的象征！'",
          "🛤️ 柏油路上驶过一辆崭新的卡车，车身印着快递公司的标志。以前这种车从不经过这里。",
          "🛤️ 有人骑着山地自行车从城里专程来打卡。他说在社交媒体上看到了你的网吧——'比照片上更有味道。'",
      } },
}

-- 修路隐藏彩蛋：路Lv3 + 声望≥500
local ROAD_MYSTERY = "🛤️ 一辆黑色SUV安静地停在门口。车窗降下一条缝，露出一双锐利的眼睛。一个穿西装的人下车，只待了30分钟，留下了$500网费和一句：'保持低调。不要跟任何人说我来过。'有人说他是首都来的大人物，也有人说他只是路过。你只知道——那30分钟里他一直在看一个加密邮箱。"

-- ============================================================
-- 彩蛋4: 咖啡吧·纸杯画
-- 咖啡升级后，隐藏叙事线逐步揭示
-- ============================================================

local COFFEE_CUP_ART = {
    { id = "cup_1", minCoffee = 1, minDay = 5,
      log = "☕ 你在回收纸杯时发现有人画了一只小猫——线条稚拙但很可爱。你把它留下了。" },
    { id = "cup_2", minCoffee = 1, minDay = 12,
      log = "☕ 又一个纸杯画！这次小猫在追蝴蝶。和上次的笔迹一样——是同一个人。" },
    { id = "cup_3", minCoffee = 2, minDay = 20,
      log = "☕ 纸杯画升级了：一幅四格漫画，讲一个男孩从非洲走到月球的故事。画功比上次进步了不少。" },
    { id = "cup_4", minCoffee = 2, minDay = 30,
      log = "☕ 月球男孩的故事继续——第7集了。你开始期待每天的纸杯画，像追连载漫画。" },
    { id = "cup_5", minCoffee = 2, minDay = 42,
      log = "☕ 你把所有纸杯画收集起来，贴在咖啡吧旁边的墙上。有客人拍了照说：'这面墙比拉各斯的画廊还好看。'" },
    { id = "cup_6", minCoffee = 3, minDay = 55,
      log = "☕ 今天的纸杯画不一样——是一幅你的肖像。画得很像，连额头上的汗都画出来了。底下写着：'谢谢你的咖啡和WiFi。'" },
    { id = "cup_7", minCoffee = 3, minDay = 70,
      log = "☕ 有个安静的女孩来取咖啡时，你第一次看见她在画画——手指上沾着马克笔的颜色。原来纸杯画家就是她。你什么也没说，只是多给了她一杯咖啡。" },
    { id = "cup_8", minCoffee = 3, minDay = 90,
      log = "☕ 那个画画的女孩今天没来。但有人转发了一条消息——她获得了拉各斯艺术学院的全额奖学金。申请材料里附了一张照片：你网吧墙上的纸杯画墙。" },
    { id = "cup_final", minCoffee = 3, minDay = 100,
      log = "☕ 你收到了一个包裹。拆开是一幅真正的画——你的网吧，画得像一座发光的城堡。背面写着：'Dragon Net Cafe是我梦想开始的地方。——Amara' 你把它挂在了最显眼的位置。" },
}

-- ============================================================
-- 彩蛋5: 停电故事集
-- 每次停电时，根据累计次数显示不同反应
-- ============================================================

local BLACKOUT_STORIES = {
    { count = 1,
      log = "🕯️ 所有人都尖叫了。Uncle Charles倒是很淡定——他从口袋里掏出一支蜡烛，仿佛早就知道会停电。" },
    { count = 2,
      log = "🕯️ 第二次停电。这次大家只是叹了口气。有人掏出手机当手电筒，屏幕亮度调到最高。" },
    { count = 3,
      log = "🕯️ 停电的瞬间，正在对战的两队人同时喊出了同一句脏话。节奏之整齐令人叹为观止。" },
    { count = 5,
      log = "🕯️ 大家已经有经验了。一停电，有人主动开始讲鬼故事。讲到精彩处灯突然来了——吓得他自己跳起来。" },
    { count = 8,
      log = "🕯️ 停电了。但这次没人慌——有人从包里掏出扑克牌，有人开始用手机热点开黑。你怀疑他们其实喜欢停电。" },
    { count = 10,
      log = "🕯️ 你刚说'又停电了'，全场齐声接：'...我知道。'然后大家默契地开始倒数。数到23时来电了，有人喊：'新纪录！'" },
    { count = 15,
      log = "🕯️ 这次停电只持续了十秒。但十秒内网吧里发生了三件事：一个人保存了游戏，一个人喝完了可乐，一个人表白失败。" },
    { count = 20,
      log = "🕯️ 全场起立鼓掌——不是因为来电了，而是因为停了三秒就恢复了。有人说这是'非洲速度'。" },
    { count = 30,
      log = "🕯️ Mama Blessing不知道什么时候准备好了'停电特饮'——冰芒果汁。她说配方是秘密的。在黑暗里喝起来格外甜。" },
    { count = 50,
      log = "🕯️ 第50次停电。你在黑暗中环顾四周：手机屏幕的光点星星般亮起，有人在笑，有人在讲故事。你突然觉得，停电也不全是坏事——至少大家抬起了头，看见了彼此。" },
}

-- 停电终极彩蛋（安装满级发电机/太阳能后首次全天无停电）
local BLACKOUT_FREEDOM = "⚡ 今天一整天没有停电。到了晚上你才意识到这件事——你已经忘记停电是什么感觉了。点唱机一直在放歌，电脑一直在运转，冰箱里的可乐一直是冰的。Uncle Charles举起杯子：'敬进步。'你也举起杯子。这大概就是自由的感觉。"

-- ============================================================
-- 彩蛋6: 转生·穿越时空的线索
-- 转生后新周目中出现"上辈子"的痕迹
-- ============================================================

local PRESTIGE_HINTS = {
    { count = 1, minDay = 3, id = "prestige_photo",
      log = "🔮 新网吧的墙角发现一张褪色的照片——上面的人长得像你，站在一家……网吧前面。照片背面写着一个日期，是很久以前的。" },
    { count = 1, minDay = 8, id = "prestige_deja_vu",
      log = "🔮 有客人说：'奇怪，我总觉得以前来过这里。位置都没变——那个插座、那面墙上的裂缝。'你没说话，但你也有同样的感觉。" },
    { count = 2, minDay = 3, id = "prestige_uncle",
      log = "🔮 Uncle Charles看着你笑了：'年轻人，你的眼神不像年轻人。像……像个见过很多事情的灵魂。'你没有反驳。" },
    { count = 2, minDay = 12, id = "prestige_mama",
      log = "🔮 Mama Blessing端来烤鸡时停了一下：'我总觉得我以前做过一模一样的事……在同一个时间，同一个地方。'她摇摇头笑了：'大概是做梦吧。'" },
    { count = 3, minDay = 5, id = "prestige_notebook",
      log = "🔮 整理柜台时你发现抽屉深处有本旧笔记。字迹是你的——但你不记得写过。上面记录着升级顺序、最佳招募时机……像一本攻略。最后一页写着：'这次要做得更好。'" },
    { count = 3, minDay = 15, id = "prestige_tree",
      log = "🔮 网吧门口的那棵树上刻着什么。你凑近看——是一连串的'正'字，有十五个。每个正字旁边有一颗星。你数了数你的星……和其中一组一模一样。" },
    { count = 4, minDay = 3, id = "prestige_dream",
      log = "🔮 昨晚做了一个奇怪的梦。梦里你在经营一家网吧——和现在一样的网吧，一样的客人，一样的点唱机。但你知道所有事情的结局。醒来时枕头是湿的。" },
    { count = 5, minDay = 5, id = "prestige_fifth",
      log = "🔮 你在柜台下面发现了一本旧笔记本。打开第一页，字迹是你的：'第五次了。这次要做得更好。'翻到后面——空白的。就好像前四次的你，写到这里就停住了。" },
    { count = 5, minDay = 20, id = "prestige_mirror",
      log = "🔮 厕所的镜子裂了一角。透过裂缝你看到了自己的眼睛——里面有一种不属于这个年纪的疲惫和温柔。像是活过了很多辈子的眼睛。" },
}

-- ============================================================
-- 钩子函数
-- ============================================================

--- 升级完成时调用
function EasterEggs.OnUpgradeComplete(key)
    if not playerData_ then return end
    playerData_.eggsTriggered = playerData_.eggsTriggered or {}

    -- 彩蛋1: 点唱机
    if key == "jukebox" then
        local level = playerData_.jukeboxLevel or 0
        local eraData = JUKEBOX_ERAS[level]
        if eraData then
            local eggId = "jukebox_era_" .. level
            if not IsTriggered(eggId) then
                MarkTriggered(eggId)
                local logs = eraData.logs
                AddLog(logs[math.random(1, #logs)])
                AddLog("  「" .. eraData.era .. "」时代的声音在网吧里回荡。")
                PlaySFX("jukebox_play")
            end
        end
        -- 满级后的终极彩蛋（仅 Lv5 且未触发过）
        if level >= 5 and not IsTriggered("jukebox_ultimate") then
            if math.random() < 0.01 then
                MarkTriggered("jukebox_ultimate")
                AddLog(JUKEBOX_ULTIMATE)
                pcall(PlaySFX, "discovery")
            end
        end
    end

    -- 彩蛋2: 电脑屏幕
    if key == "computer" then
        local level = playerData_.computers or 0
        for _, entry in ipairs(COMPUTER_EVOLUTION) do
            if level >= entry.minLevel and level <= entry.maxLevel then
                local eggId = "comp_evo_" .. entry.id .. "_" .. level
                if not IsTriggered(eggId) then
                    MarkTriggered(eggId)
                    local logs = entry.logs
                    AddLog(logs[math.random(1, #logs)])
                end
                break
            end
        end
    end

    -- 彩蛋3: 修路
    if key == "road" then
        local level = playerData_.roadLevel or 0
        for _, entry in ipairs(ROAD_SCENES) do
            if level >= entry.minLevel and level <= entry.maxLevel then
                local eggId = "road_scene_" .. entry.id .. "_" .. level
                if not IsTriggered(eggId) then
                    MarkTriggered(eggId)
                    local logs = entry.logs
                    AddLog(logs[math.random(1, #logs)])
                end
                break
            end
        end
        -- 隐藏彩蛋: 路Lv3 + 声望≥500
        if level >= 3 and (playerData_.reputation or 0) >= 500 then
            if not IsTriggered("road_mystery_suv") then
                MarkTriggered("road_mystery_suv")
                AddLog(ROAD_MYSTERY)
                playerData_.money = (playerData_.money or 0) + 500
                pcall(PlaySFX, "discovery")
            end
        end
    end

    -- 彩蛋1 补充：咖啡升级也触发纸杯画检查
    if key == "coffee" then
        EasterEggs.CheckCoffeeCupArt()
    end
end

--- 停电事件触发时调用
function EasterEggs.OnBlackout()
    if not playerData_ then return end
    local count = IncrementCounter("blackout_total")

    -- 查找匹配的停电故事
    local story = nil
    for i = #BLACKOUT_STORIES, 1, -1 do
        if count >= BLACKOUT_STORIES[i].count then
            -- 精确匹配或最大匹配
            if count == BLACKOUT_STORIES[i].count then
                story = BLACKOUT_STORIES[i]
                break
            end
        end
    end

    -- 精确匹配时触发（每个节点只触发一次）
    if story and count == story.count then
        local eggId = "blackout_story_" .. count
        if not IsTriggered(eggId) then
            MarkTriggered(eggId)
            AddLog(story.log)
        end
    end
end

--- 检查"无停电自由日"终极彩蛋（在 EndDay 中，确认未停电时调用）
function EasterEggs.OnNoPowerOutage()
    if not playerData_ then return end
    local genLv = playerData_.generatorLevel or 0
    local solarLv = playerData_.solarLevel or 0
    local blackouts = GetCounter("blackout_total")

    -- 条件：曾经历过≥10次停电 + 发电机Lv3或太阳能Lv3 + 未触发过
    if blackouts >= 10 and (genLv >= 3 or solarLv >= 3) then
        if not IsTriggered("blackout_freedom") then
            -- 连续无停电3天后触发
            local streak = IncrementCounter("no_blackout_streak")
            if streak >= 3 then
                MarkTriggered("blackout_freedom")
                AddLog(BLACKOUT_FREEDOM)
                pcall(PlaySFX, "discovery")
            end
        end
    end
end

--- 停电重置无停电连续天数
function EasterEggs.ResetNoPowerStreak()
    if playerData_ and playerData_.eggCounters then
        playerData_.eggCounters["no_blackout_streak"] = 0
    end
end

--- 转生完成后调用
function EasterEggs.OnPrestige(prestigeCount)
    if not playerData_ then return end
    playerData_.eggsTriggered = playerData_.eggsTriggered or {}
    -- 转生彩蛋在后续天数中逐步触发（这里只记录当前转生次数）
    playerData_.eggPrestigeCount = prestigeCount
end

--- 每日结算时调用（检查转生线索 + 咖啡纸杯画 + 点唱机满级随机）
function EasterEggs.OnDailySettle()
    if not playerData_ then return end
    playerData_.eggsTriggered = playerData_.eggsTriggered or {}
    local day = playerData_.day or 0

    -- 彩蛋6: 转生穿越线索（每日检查，20%概率触发未触发的条目）
    local pCount = playerData_.eggPrestigeCount or (playerData_.prestigeCount or 0)
    if pCount >= 1 then
        for _, hint in ipairs(PRESTIGE_HINTS) do
            if pCount >= hint.count and day >= hint.minDay and not IsTriggered(hint.id) then
                if math.random() < 0.20 then
                    MarkTriggered(hint.id)
                    AddLog(hint.log)
                    pcall(PlaySFX, "discovery")
                    break  -- 每天最多触发一条转生线索
                end
            end
        end
    end

    -- 彩蛋4: 咖啡纸杯画（每日检查）
    EasterEggs.CheckCoffeeCupArt()

    -- 彩蛋1: 点唱机满级随机曲目（每日1%）
    local jLevel = playerData_.jukeboxLevel or 0
    if jLevel >= 5 and not IsTriggered("jukebox_ultimate") then
        if math.random() < 0.01 then
            MarkTriggered("jukebox_ultimate")
            AddLog(JUKEBOX_ULTIMATE)
            pcall(PlaySFX, "discovery")
        end
    end
end

--- 检查咖啡纸杯画进度
function EasterEggs.CheckCoffeeCupArt()
    if not playerData_ then return end
    local coffeeLevel = playerData_.coffeeLevel or 0
    local day = playerData_.day or 0

    if coffeeLevel < 1 then return end

    for _, cup in ipairs(COFFEE_CUP_ART) do
        if coffeeLevel >= cup.minCoffee and day >= cup.minDay and not IsTriggered(cup.id) then
            -- 30%每日概率触发下一个（保持稀有感）
            if math.random() < 0.30 then
                MarkTriggered(cup.id)
                AddLog(cup.log)
                pcall(PlaySFX, "discovery")
                break  -- 每天最多触发一条
            end
            break  -- 只检查下一个未触发的
        end
    end
end

return EasterEggs
