---@diagnostic disable: undefined-global
-- ============================================================================
-- 18. 游戏逻辑
-- ============================================================================

local IdleEngine = require("IdleEngine")
local PrestigeSystem = require("PrestigeSystem")
local Achievements = require("Achievements")

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
        currentDialogues_ = ch.dialogues
        dialogueIndex_ = 1
        -- 使用 CinematicDialogue 的打字机
        local firstDlg = currentDialogues_[1]
        local isMonologue = firstDlg and firstDlg.type == "monologue"
        CinematicDialogue.StartTypewriter(firstDlg.text, isMonologue)
        StartTypewriter(firstDlg.text) -- 同步旧状态兼容
        TryPlayVoiceForDialogue(firstDlg)
        -- 播放章节环境音
        if ch.ambient then PlayAmbient(ch.ambient) end
        if ch.bgm then PlayBGM(ch.bgm) end
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
    currentDialogues_ = ch.dialogues
    dialogueIndex_ = 1
    local firstDlg = currentDialogues_[1]
    local isMonologue = firstDlg and firstDlg.type == "monologue"
    CinematicDialogue.StartTypewriter(firstDlg.text, isMonologue)
    StartTypewriter(firstDlg.text)
    TryPlayVoiceForDialogue(firstDlg)
    if ch.ambient then PlayAmbient(ch.ambient) end
    if ch.bgm then PlayBGM(ch.bgm) end
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
    -- 声望引流
    attract = attract + math.floor(playerData_.reputation / 12)
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
    local total = (base + attract + trafficBonus_) * dayMod * randMod * specialEventMod * rivalStealMod
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

function CalcDailyIncome()
    local base = playerData_.computers * 25   -- 每台 $20→$25（ROI 从53天→25天）
    local upgrade = (playerData_.chairLevel - 1) * 5 + (playerData_.netSpeed - 1) * 10
                  + playerData_.acLevel * 8
    local food = playerData_.foodShop * 18       -- 烤鸡摊（降低ROI，从25→18）
    local deco = playerData_.decoLevel * 8       -- 装饰回头客（降低ROI，从10→8）
    local cofIncome = (playerData_.coffeeLevel or 0) * 15  -- 咖啡吧台高利润
    local jbIncome = (playerData_.jukeboxLevel or 0) * 5   -- 点唱机投币收入
    local rep  = math.floor(playerData_.reputation / 10)

    -- 队员跑刀直接收入（技术越高，跑刀赚的越多）
    local teamIncome = 0
    for _, m in ipairs(teamMembers_) do
        teamIncome = teamIncome + 18 + math.floor(m.skill / 3) + math.floor(m.talent / 10)
    end

    local subtotal = base + upgrade + food + deco + cofIncome + jbIncome + rep + teamIncome

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

function EndDay()
    -- 防重入：过场动画期间禁止再次触发 EndDay
    if transition_.active then
        log:Write(LOG_WARNING, "[EndDay] blocked: transition active")
        return
    end
    log:Write(LOG_INFO, "[EndDay] === START day=" .. tostring(playerData_.day) .. " money=" .. tostring(playerData_.money) .. " ===")
    PlaySFX("day_dawn")
    -- 刷新今日客流（确保 EndDay 与显示一致）
    cachedTrafficDay_ = -1  -- 强制重算（新一天开始）
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()

    -- 留存系统：周期性大事件每日效果（影响客流/收入，须在 CalcDailyIncome 前执行）
    if Retention then
        local peOk, peErr = pcall(Retention.CheckPeriodicEvents, playerData_.day)
        if not peOk then log:Write(LOG_ERROR, "[EndDay] CheckPeriodicEvents error: " .. tostring(peErr)) end
    end

    local income = CalcDailyIncome()
    local expList, totalExpense = CalcDailyExpenses()
    log:Write(LOG_INFO, "[EndDay] calc done: traffic=" .. tostring(traffic) .. " capacity=" .. tostring(capacity) .. " income=" .. tostring(income) .. " expense=" .. tostring(totalExpense))
    -- 停电事件（15%概率，第3天后触发）
    local powerOut = false
    if playerData_.day >= 3 and math.random() < 0.15 then
        local genLv = playerData_.generatorLevel or 0
        local hasFuel = (playerData_.fuel or 0) > 0
        if genLv > 0 and hasFuel then
            -- 有发电机且有燃油，停电无影响
            local protection = { "小型柴油机轰鸣启动", "中型发电机平稳切换", "大型静音发电机无缝接管" }
            AddLog("⚡ 今日停电！" .. (protection[genLv] or "发电机启动") .. "，营业照常！")
        elseif playerData_.solarLevel >= 2 then
            -- 太阳能板高等级部分减损
            income = math.floor(income * 0.8)
            AddLog("⚡ 今日停电！太阳能板维持部分供电，收入-20%")
            powerOut = true
        else
            -- 无保护，收入大幅下降
            income = math.floor(income * 0.4)
            PlaySFX("negative")
            AddLog("⚡ 今日停电！没有发电机，大半天无法营业，收入-60%！")
            powerOut = true
        end
    end
    local netIncome = income - totalExpense
    -- 追踪历史总收入（用于终极结局）
    if netIncome > 0 then
        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + netIncome
    end
    playerData_.money = playerData_.money + netIncome
    if netIncome > 0 then PlaySFX("coin_collect") end

    -- ── 里程碑反馈（首次达成关键节点） ──
    if netIncome > 0 and not storyTriggered_["milestone_first_profit"] then
        storyTriggered_["milestone_first_profit"] = true
        AddLog("🎉 【里程碑】第一次盈利！虽然只有$" .. netIncome .. "，但这是梦想的第一步！")
        TriggerCelebration()
    end
    if playerData_.money >= 1000 and not storyTriggered_["milestone_1k"] then
        storyTriggered_["milestone_1k"] = true
        AddLog("🎉 【里程碑】资产突破$1,000！终于有了一点安全感，继续加油！")
        TriggerCelebration()
    end
    if playerData_.money >= 3000 and not storyTriggered_["milestone_3k"] then
        storyTriggered_["milestone_3k"] = true
        AddLog("🎉 【里程碑】资产突破$3,000！可以考虑扩张了——招个好队员或者升级设备！")
        TriggerCelebration()
    end
    if playerData_.money >= 5000 and not storyTriggered_["milestone_5k"] then
        storyTriggered_["milestone_5k"] = true
        playerData_.money = playerData_.money + 200
        AddLog("🎉 【里程碑】资产突破$5,000！Mama B特地送来烤鸡庆祝，额外奖励$200！")
        TriggerCelebration()
    end
    if playerData_.money >= 10000 and not storyTriggered_["milestone_10k"] then
        storyTriggered_["milestone_10k"] = true
        AddLog("🎉 【里程碑】资产突破$10,000！从小作坊到正规企业，你做到了！")
        TriggerCelebration()
    end
    if playerData_.money >= 50000 and not storyTriggered_["milestone_50k"] then
        storyTriggered_["milestone_50k"] = true
        AddLog("🎉 【里程碑】资产突破$50,000！你已经是村里最成功的企业家了！")
        TriggerCelebration()
    end
    if (playerData_.totalEarnings or 0) >= 100000 and not storyTriggered_["milestone_100k_earn"] then
        storyTriggered_["milestone_100k_earn"] = true
        AddLog("🎉 【里程碑】累计收入突破$100,000！传奇经营者的称号当之无愧！")
        TriggerCelebration()
    end

    -- ── 行为里程碑（招募/声望/比赛/升级）──
    if #teamMembers_ >= 1 and not storyTriggered_["milestone_first_recruit"] then
        storyTriggered_["milestone_first_recruit"] = true
        AddLog("🎉 【里程碑】招募了第一名队员！战队 Dragon Force 正式成立！")
        TriggerCelebration()
    end
    if #teamMembers_ >= 3 and not storyTriggered_["milestone_3_members"] then
        storyTriggered_["milestone_3_members"] = true
        playerData_.reputation = playerData_.reputation + 20
        AddLog("🎉 【里程碑】战队满3人！村里的年轻人开始议论你们了，声望+20！")
        TriggerCelebration()
    end
    if playerData_.reputation >= 50 and not storyTriggered_["milestone_rep50"] then
        storyTriggered_["milestone_rep50"] = true
        AddLog("🎉 【里程碑】声望突破50！隔壁村的人专门跑来看你的网吧！")
        TriggerCelebration()
    end
    if playerData_.reputation >= 200 and not storyTriggered_["milestone_rep200"] then
        storyTriggered_["milestone_rep200"] = true
        AddLog("🎉 【里程碑】声望突破200！当地报纸想采访你——非洲网吧传奇！")
        TriggerCelebration()
    end
    if (playerData_.friendlyWins or 0) >= 1 and not storyTriggered_["milestone_first_win"] then
        storyTriggered_["milestone_first_win"] = true
        playerData_.money = playerData_.money + 100
        AddLog("🎉 【里程碑】首场比赛胜利！队员们激动得抱在一起，奖励$100！")
        TriggerCelebration()
    end

    -- 记录昨日净收入，用于翻倍广告
    playerData_.lastNetIncome = netIncome > 0 and netIncome or 0
    playerData_.reputation = math.min(999999, playerData_.reputation + math.floor(income / 20))
    -- 分店随机事件
    TriggerBranchEvents()
    -- 黄金装饰每日声望加成
    if playerData_.goldDecor then
        playerData_.reputation = playerData_.reputation + 3
    end
    -- 联动加成
    local synergies, incBonus, trainBonus, synergyMood = CalcUpgradeSynergies()
    synergyMood = synergyMood or 0  -- 防御：CalcUpgradeSynergies 返回 nil 时兜底
    local repGain = math.floor(income / 20)

    -- 每日总结（含收支 + 客流）
    -- 注意：day 自增延后到日记写完后，确保当天叙事归入当天
    local dayNum = playerData_.day
    local tDesc = select(1, GetTrafficDesc(traffic, capacity))
    -- 每日环境风味一句话
    local DAY_FLAVOR = {
        "🌅 红土地上又是新的一天。", "🌞 太阳照常升起，和昨天一样毒辣。",
        "🌧️ 天边堆着乌云，但还没下。", "🌤️ 晨风带着烤玉米的香味。",
        "🌙 月亮还挂在天上，网吧已经有人排队了。", "🐓 公鸡叫了三遍，发电机叫了一遍。",
        "📻 隔壁的收音机在放阿弗罗比特舞曲。", "🔔 远处清真寺传来晨祷的声音。",
        "🦎 一只壁虎在天花板上看了你一眼，表示今天运气不错。",
        "🌴 椰子树在风里摇晃，像在给你的网吧打广告。",
    }
    AddLog(DAY_FLAVOR[math.random(1, #DAY_FLAVOR)])

    -- 感官碎碎念：40%概率插入一条生活气息描写
    local SENSORY_SNIPPETS = {
        -- 声音
        "远处的街角传来了熟悉的旋律，那是20年前红遍亚洲的华语老歌，不知道是谁在播放。",
        "摩托车引擎的突突声从街头传到街尾，像是这座城市永不停歇的脉搏。",
        "隔壁铁匠铺传来叮叮当当的敲打声，节奏竟然和店里放的电子音乐合上了拍。",
        "有个小贩推着车经过，用法语喊着卖冰棍。那口音听着像是从北方来的。",
        "鸡叫声、狗吠声、婴儿啼哭声……这条街的配乐永远这么丰富。",
        "有人在网吧外面用手机外放非洲鼓曲，几个年轻人跟着节拍扭了起来。",
        -- 气味
        "今天清晨，你发现电脑屏幕上落了一层薄薄的红土，得赶紧擦擦。",
        "Mama Blessing刚支起烤架，鸡肉滋滋冒油的香味飘进了网吧，三个客人同时吞了口水。",
        "空气里飘着烤玉米、柴油、尘土和廉价除臭剂混合的气味——这就是非洲互联网的味道。",
        "不知道哪来的一股焦糊味。检查了一圈，是门口有人在烧垃圾。松了一口气。",
        "热带雨后的泥土气息从门缝挤进来，潮湿而温暖，像大地在深呼吸。",
        -- 视觉
        "阳光透过铁皮屋顶的缝隙漏进来，在地上画了一道道金色的条纹。灰尘在光柱中旋转。",
        "门外一棵芒果掉在地上，摔得四分五裂。三个孩子从天而降般地扑过去抢。",
        "一只蜥蜴趴在墙上一动不动，它在这面墙上住了至少两个月了。你给它取名叫'保安'。",
        "隔壁屋顶上的卫星天线歪了，像一朵金属向日葵在朝着错误的方向仰望。",
        "一群白鹭排成人字形从网吧上方飞过，投下一片移动的影子。",
        -- 触感/体感
        "塑料椅子被太阳晒得发烫，新来的客人一屁股坐下去，弹起来的速度比游戏里跳跃还快。",
        "黏糊糊的湿气贴在皮肤上，衬衫后背湿了一片。这里的夏天没有尽头。",
        "门口的水泥地面被晒得发白，赤脚踩上去能感受到大地的体温——大概有五十度。",
        "一阵穿堂风吹过，带走了些许暑气。你从冰箱里拿出最后一瓶矿泉水，瓶壁凝满了水珠。",
        -- 生活片段
        "有个老太太背着一捆甘蔗路过，停下来透过窗户看了半天屏幕，然后摇摇头走了。",
        "街对面的理发店在放震天响的福音音乐。客人说网吧的隔音效果不错——因为键盘声更响。",
        "一辆载满人的小巴士在门口抛锚了，乘客们涌进网吧蹭WiFi打电话叫拖车。",
        "有人在网吧门口的墙根下午睡，帽子盖着脸，鼾声和发电机声交替进行。",
        "有个小男孩趴在窗户上看了半小时别人打游戏。你招手让他进来免费玩了一局。",
    }
    if math.random() < 0.4 then
        AddLog("  " .. SENSORY_SNIPPETS[math.random(1, #SENSORY_SNIPPETS)])
    end

    -- ── 日记体结算 ──（pcall 保护：叙事文本崩溃不影响结算）
    log:Write(LOG_INFO, "[EndDay] phase: diary narrative")
    local diaryOk, diaryErr = pcall(function()
        local ratio = traffic / math.max(1, capacity)
        local trafficDiary
        if ratio >= 1.2 then
            local full = {
                "今天店里挤得跟拉各斯的小巴士一样，椅子都不够坐。有人蹲在地上等位子，我心里又高兴又愧疚。",
                "门口排起了队。我数了数，来了" .. traffic .. "个人，但店里只有" .. capacity .. "个座位。有几个年轻人在门口等了半小时才进来。",
                "满座了。所有电脑都在运转，风扇声和键盘声汇成一首属于网吧的交响曲。",
            }
            trafficDiary = full[math.random(1, #full)]
        elseif ratio >= 0.7 then
            local ok = {
                "今天来了" .. traffic .. "个客人，不多不少，刚好够付账单的。",
                "店里热热闹闹的，" .. traffic .. "个人在各自的世界里遨游——有人打三角洲，有人刷社交媒体，有人在给家里打视频电话。",
                "生意还行。" .. traffic .. "个客人，" .. capacity .. "个座位，不至于冷清也不算爆满。像是非洲版的'小确幸'。",
            }
            trafficDiary = ok[math.random(1, #ok)]
        elseif traffic > 0 then
            local slow = {
                "今天只来了" .. traffic .. "个人。" .. capacity .. "把椅子大半空着，我坐在柜台后面发了会儿呆。",
                "冷清的一天。" .. traffic .. "个客人稀稀拉拉地来了又走了。我把桌子擦了三遍，因为实在没别的事做。",
                "门口经过的人倒不少，但走进来的只有" .. traffic .. "个。也许该在门口挂块更大的招牌。",
            }
            trafficDiary = slow[math.random(1, #slow)]
        else
            trafficDiary = "今天居然一个客人都没有。我独自坐在空荡荡的网吧里，听着电脑待机的嗡嗡声，怀疑人生。"
        end
        AddLog("📖 ── 店长日志·第" .. dayNum .. "天 ──")
        AddLog("  " .. trafficDiary)

        -- 收支描写（叙事化）
        if netIncome > 100 then
            local rich = {
                "今天赚了$" .. income .. "，花掉$" .. totalExpense .. "——净赚$" .. netIncome .. "。数钱的时候手都在抖，忍住了没喊出声。",
                "好日子。进账$" .. income .. "，杂七杂八扣掉$" .. totalExpense .. "，口袋里多了$" .. netIncome .. "。离三角洲冠军又近了一步。",
            }
            AddLog("  " .. rich[math.random(1, #rich)])
        elseif netIncome > 0 then
            local ok = {
                "今天进账$" .. income .. "，花了$" .. totalExpense .. "。不算多，但至少是赚的。口袋里还剩$" .. playerData_.money .. "。",
                "收入$" .. income .. "减去开销$" .. totalExpense .. "，净赚$" .. netIncome .. "。蚊子腿也是肉。",
            }
            AddLog("  " .. ok[math.random(1, #ok)])
        elseif netIncome == 0 then
            AddLog("  今天进账$" .. income .. "，全花在了运营上。白忙活一天，等于给非洲的太阳打了一天工。")
        else
            local bad = {
                "亏了。收入$" .. income .. "，但支出$" .. totalExpense .. "——倒贴$" .. math.abs(netIncome) .. "。钱包瘦了，余额$" .. playerData_.money .. "。",
                "今天赔了$" .. math.abs(netIncome) .. "。看着账本上的红字，我深吸一口气，告诉自己明天会好的。余额$" .. playerData_.money .. "。",
            }
            AddLog("  " .. bad[math.random(1, #bad)])
        end

        -- 队伍士气（叙事化）
        if #synergies > 0 then
            AddLog("  联动加成的效果不错，" .. #synergies .. "组组合正在发挥作用。")
        end
        if #teamMembers_ > 0 then
            local avgMood = 0
            for _, m in ipairs(teamMembers_) do avgMood = avgMood + (m.mood or 50) end
            avgMood = math.floor(avgMood / #teamMembers_)
            if avgMood > 70 then
                local mName = FirstMemberName()
                local happy = { "队员们状态不错，" .. mName .. "今天训练时还哼着歌。",
                    "休息室里传出笑声。士气很高，大家憋着一股劲要冲冠军。" }
                AddLog("  " .. happy[math.random(1, #happy)])
            elseif avgMood >= 40 then
                AddLog("  队伍状态平平。不好不坏，就像门口那条每天准时出现的野狗——稳定。")
            else
                local mName = FirstMemberName()
                local sad = { "队员们情绪低落。" .. mName .. "今天话很少，训练时心不在焉。",
                    "更衣室里的气氛有点沉闷。我得想办法提振士气，否则比赛会很难打。" }
                AddLog("  " .. sad[math.random(1, #sad)])
            end
        end
    end)
    if not diaryOk then
        log:Write(LOG_ERROR, "[EndDay] diary narrative error: " .. tostring(diaryErr))
        AddLog("📖 ── 店长日志·第" .. dayNum .. "天 ──")
        AddLog("  （日志记录异常，跳过叙事）")
    end

    -- 债务利息+自动还款
    log:Write(LOG_INFO, "[EndDay] phase: debt/depreciation/deval")
    local debtOk, debtErr = pcall(function()
        if (playerData_.debt or 0) > 0 then
            local interest = math.floor(playerData_.debt * 0.1)
            playerData_.debt = playerData_.debt + interest
            local repay = math.min(playerData_.debt, math.max(0, math.floor(playerData_.money * 0.3)))
            playerData_.money = playerData_.money - repay
            playerData_.debt = playerData_.debt - repay
            if playerData_.debt > 0 then
                AddLog("  Mama B来收账了。利息$" .. interest .. "，我咬牙还了$" .. repay .. "。还欠$" .. playerData_.debt .. "，她拍拍我肩膀说'慢慢来'。")
            else
                AddLog("  终于把Mama B的钱还清了！她笑着说：'我就知道你行。'这句话比还完钱还让人高兴。")
            end
        end
    end)
    if not debtOk then log:Write(LOG_ERROR, "[EndDay] debt error: " .. tostring(debtErr)) end

    -- 设备折旧（修路减少灰尘损耗）
    local degradation = math.random(2, 5) + math.floor(playerData_.computers * 0.5)
    local roadReduce = (playerData_.roadLevel or 0) * 0.8  -- 每级路减少0.8折旧
    degradation = math.max(1, degradation - roadReduce)
    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - degradation)
    local cond = playerData_.equipCondition
    if cond <= 30 then
        AddLog("  设备状况堪忧（" .. cond .. "%）。3号机今天蓝屏了两次，5号机的风扇发出死亡般的尖叫。再不修要出人命。")
    elseif cond <= 50 then
        AddLog("  电脑们在抗议了（" .. cond .. "%）。键盘手感越来越黏，屏幕上的亮点越来越多。该安排维修了。")
    elseif cond <= 70 then
        AddLog("  设备还撑得住（" .. cond .. "%），但今天又有个USB口松了。我用胶带缠了缠，勉强能用。")
    end

    -- 燃油警告
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 then
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        if fuel <= 0 then
            AddLog("  油箱空了。发电机沉默地蹲在角落，像一只不会叫的看门狗。今晚如果停电，我们就完了。")
        elseif fuel <= math.floor(cap * 0.3) then
            AddLog("  燃油告急（" .. fuel .. "/" .. cap .. "L）。我盯着油表指针，像盯着自己银行账户的余额——不忍直视。")
        end
    end

    -- ── 自动化日结（IdleEngine） ──
    local autoOk, autoErr = pcall(function()
        local autoResult = IdleEngine.ApplyDailyAutomation()
        if autoResult then
            if autoResult.repairedAmount and autoResult.repairedAmount > 0 then
                AddLog("🔧 自动化系统完成日常维护，设备恢复了" .. autoResult.repairedAmount .. "%状态。")
            end
            if autoResult.fuelBought and autoResult.fuelBought > 0 then
                AddLog("⛽ 自动补给系统购入了" .. autoResult.fuelBought .. "L燃油（花费$" .. (autoResult.fuelCost or 0) .. "）。")
            end
        end
        -- 检查是否可以解锁下一级自动化
        local autoLv = playerData_.automationLevel or 0
        if autoLv < 4 then
            local canUnlock, reason = IdleEngine.CanUnlockAutomation(autoLv + 1)
            if canUnlock then
                AddLog("💡 自动化系统可以升级到Lv" .. (autoLv + 1) .. "了！前往「自动化管理」面板查看。")
            end
        end
        -- 检查转生就绪
        if PrestigeSystem.CanPrestige() then
            local gain = PrestigeSystem.CalcPrestigeGain()
            if gain > 0 and playerData_.day % 5 == 0 then  -- 每5天提醒一次，避免刷屏
                AddLog("🌟 你的商业帝国已经足够强大！可以「转生」获得" .. gain .. "点商会名誉，开启新城市的征程。")
            end
        end
    end)
    if not autoOk then log:Write(LOG_ERROR, "[EndDay] IdleEngine error: " .. tostring(autoErr)) end

    -- 分店日报（含地点/游戏特色加成）
    local branches = playerData_.branches or {}
    if #branches > 0 then
        local totalBranch = 0
        for _, br in ipairs(branches) do
            local brI = br.income or 40
            if br.gameBonusType == "income" then brI = math.floor(brI * 1.2) end
            if br.gameBonusType == "combat" then brI = brI + 8 end
            totalBranch = totalBranch + brI
        end
        local BRANCH_DIARIES = {
            "  " .. #branches .. "家分店今天贡献了$" .. totalBranch .. "。当甩手掌柜的感觉真不赖。",
            "  远程查看了分店监控，" .. #branches .. "家店都在正常运转。进账$" .. totalBranch .. "，躺赚的滋味不错。",
            "  分店经理们汇报：一切正常，合计日入$" .. totalBranch .. "。连锁的力量开始显现了。",
        }
        AddLog(BRANCH_DIARIES[math.random(1, #BRANCH_DIARIES)])
        -- 各分店特色加成
        for _, br in ipairs(branches) do
            -- 地点特殊效果
            if br.bonusType == "reputation" then
                playerData_.reputation = playerData_.reputation + 8
            elseif br.bonusType == "mood" and #teamMembers_ > 0 then
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, m.mood + 10)
                end
            end
            -- 游戏特殊效果
            if br.gameBonusType == "popularity" then
                -- 基于分店自身收入计算声望加成（不受主店停电等影响）
                local extraRep = math.floor((br.income or 40) / 20 * 0.25 * 10)
                playerData_.reputation = playerData_.reputation + math.max(2, extraRep)
            elseif br.gameBonusType == "strategy" and #teamMembers_ > 0 then
                for _, m in ipairs(teamMembers_) do
                    m.skill = math.min(SKILL_CAP, m.skill + 1)
                end
            end
        end
    end

    -- ── 社区枢纽每日效果 ──
    -- 社区建设者联动：声望+3/天
    if (playerData_.wellLevel or 0) >= 2 and (playerData_.roadLevel or 0) >= 2 then
        playerData_.reputation = playerData_.reputation + 3
    end
    -- 点唱机心情加成
    local jbLv = playerData_.jukeboxLevel or 0
    if jbLv > 0 and #teamMembers_ > 0 then
        local jbMood = jbLv * 3
        -- 文化沙龙联动额外+8
        if jbLv >= 1 and playerData_.decoLevel >= 2 then
            jbMood = jbMood + 8
        end
        for _, m in ipairs(teamMembers_) do
            m.mood = math.min(100, m.mood + jbMood)
        end
    end

    -- ── 政变倒计时处理 ──
    if (playerData_.coupDaysLeft or 0) > 0 then
        playerData_.coupDaysLeft = playerData_.coupDaysLeft - 1
        if playerData_.coupDaysLeft <= 0 then
            -- 政变结束！
            playerData_.coupDaysLeft = 0
            storyTriggered_["coup_count"] = (storyTriggered_["coup_count"] or 0) + 1
            PlaySFX("upgrade")
            local COUP_END = {
                "🕊️ 【政变结束】经过数天的紧张对峙，军方与文官政府达成协议。银行重新开门，街上的路障被拆除。生活终于恢复正常了！金价开始回落。",
                "🕊️ 【解除戒严】国际社会介入调停，政变领袖同意交出权力。ATM前排起了长队，人们急着取出被冻结的存款。一切都在慢慢恢复。",
                "🕊️ 【和平恢复】将军在电视上宣布'还政于民'。商铺纷纷开门，黑市上的黄金价格一落千丈。你长出一口气——终于可以正常做生意了。",
            }
            AddLog("  " .. COUP_END[math.random(1, #COUP_END)])
        else
            -- 政变持续中：每日额外损失（戒严经济影响）
            local dailyLoss = math.floor(playerData_.money * 0.08)  -- 每天损失8%现金
            if playerData_.goldSafe then dailyLoss = math.floor(dailyLoss * 0.5) end  -- 黄金保险箱减半
            if dailyLoss > 0 then
                playerData_.money = playerData_.money - dailyLoss
            end
            local daysLeft = playerData_.coupDaysLeft
            local COUP_ONGOING = {
                "🪖 政变第" .. (5 - daysLeft + 1) .. "天。街上空荡荡的，只有军车来回巡逻。你的$" .. dailyLoss .. "在戒严中蒸发了。（剩余" .. daysLeft .. "天）",
                "🪖 戒严持续中。食品和日用品价格翻了好几番，又损失了$" .. dailyLoss .. "。只有黄金还能买到东西。（剩余" .. daysLeft .. "天）",
                "🪖 军方检查站越来越多。好在网吧还能偷偷营业，但现金几乎没用了，又亏了$" .. dailyLoss .. "。（剩余" .. daysLeft .. "天）",
            }
            AddLog("  " .. COUP_ONGOING[math.random(1, #COUP_ONGOING)])
        end
    end

    -- ── 货币贬值事件 ──
    -- 第10天后，每5天有40%概率发生一次货币贬值（现金损失5-12%）（政变期间不再额外贬值）
    if not IsCoupActive() and playerData_.day >= 10 and playerData_.day % 5 == 0 and math.random() < 0.40 then
        local devalRate = math.random(5, 12) / 100
        local cashLoss = math.floor(playerData_.money * devalRate)
        if playerData_.goldSafe then cashLoss = math.floor(cashLoss * 0.5) end  -- 黄金保险箱减半
        if cashLoss > 0 then
            playerData_.money = playerData_.money - cashLoss
            PlaySFX("negative")
            local pct = math.floor(devalRate * 100)
            local DEVAL_DIARY = {
                "📉 今天传来坏消息——奈拉又贬值了" .. pct .. "%。抽屉里的美元缩水了$" .. cashLoss .. "。汇率这东西，比天气还不靠谱。",
                "📉 手机推送弹出来：当地货币暴跌" .. pct .. "%。你的$" .. cashLoss .. "蒸发了。在非洲，现金就像冰棍——不赶紧用掉就化了。",
                "📉 黑市换汇的大叔今天涨价了。一算账，等于亏了$" .. cashLoss .. "（" .. pct .. "%）。也许该考虑买点黄金保值。",
            }
            AddLog("  " .. DEVAL_DIARY[math.random(1, #DEVAL_DIARY)])
            -- 黄金提示（第一次贬值时提醒）
            if not storyTriggered_["first_devaluation"] then
                storyTriggered_["first_devaluation"] = true
                AddLog("  💡 提示：现金在非洲会缩水。买黄金可以对冲风险——关注金价走势，低买高卖。")
            end
        end
    end

    -- 黄金持仓报告（如果有黄金）
    local gold = playerData_.goldOunces or 0
    if gold > 0 then
        local gp = GetGoldPrice()
        local val = math.floor(gold * gp)
        AddLog("  💰 黄金持仓: " .. string.format("%.1f", gold) .. "盎司 ≈ $" .. val .. "（今日金价 $" .. gp .. "/oz）")
    end

    -- 日记收尾
    local DIARY_CLOSERS = {
        "关上门，锁好窗。明天又是新的一天。",
        "今天就这样了。蟋蟀已经开始叫了，该睡了。",
        "写完这些，外面的星星已经很亮了。在非洲看星星，是免费的奢侈品。",
        "发电机还在突突响。我关掉最后一盏灯，摸黑走回后屋。",
        "听着远处的鼓声，不知道谁家在庆祝什么。总之，今天活过来了。",
        "门口那只流浪猫又来了，我给它留了半碗水。在这片土地上，大家互相照看着。",
        "把收银箱锁好。钱虽然不多，但都是一块一块赚来的，比什么都踏实。",
        "拉上铁皮门的时候，隔壁Uncle Charles喊了声'晚安'。我也喊了声'晚安'。就这样。",
    }
    if math.random() < 0.5 then
        AddLog("  " .. DIARY_CLOSERS[math.random(1, #DIARY_CLOSERS)])
    end

    -- ── 记录今日净收入用于委托追踪 ──
    playerData_.questDailyIncome = math.max(0, netIncome)

    -- ── 日期推进（日记写完后再 +1，确保当天叙事归当天）──
    local prevDay = playerData_.day
    playerData_.day = playerData_.day + 1
    -- RV2: AP系统扩容（方案2+5）
    if RV2 then
        local newDayAP = RV2.GetDailyAP(playerData_.day)
        local baseAP = RV2.CalcBaseAP()
        playerData_.actionPoints = math.max(newDayAP, baseAP)
    else
        playerData_.actionPoints = 3
    end
    -- 咖啡机满级（Lv3）时 30% 概率额外 +1 AP（精品咖啡提神）
    if (playerData_.coffeeLevel or 0) >= 3 and math.random() < 0.30 then
        playerData_.actionPoints = playerData_.actionPoints + 1
        AddLog("☕ 精品咖啡的香气让你精神百倍！今日行动点+1（" .. playerData_.actionPoints .. "点）")
    end
    trafficBonus_ = 0             -- 重置临时客流加成
    friendlyMatchToday_ = false   -- 重置友谊赛冷却

    -- 二手市场每日结算
    if Market and Market.DailyTick then
        pcall(Market.DailyTick)
    end

    -- RV2: 每日重置 + 团队羁绊 + 里程碑 + 赛季积分 + 新手奖励
    if RV2 then
        pcall(RV2.DailyReset)
        -- 方案11: 团队羁绊效果
        pcall(RV2.ApplyBondEffects)
        -- 方案7: 里程碑弹窗
        local msOk, milestone = pcall(RV2.CheckMilestone)
        if msOk and milestone then
            AddLog("🏅 「" .. milestone.title .. "」" .. milestone.desc)
        end
        -- 方案10: 日结赛季积分
        pcall(RV2.AddSeasonPoints, 2, "日结存活")
        -- 方案5: 新手奖励检查（注入事件到日结事件链）
        local nbOk, nbEvent = pcall(RV2.CheckNewbieBonus, playerData_.day)
        if nbOk and nbEvent then
            pendingRV2Event_ = nbEvent
        end
    end

    -- 结算前检查当前委托是否已完成（收入类委托只有此时才能检测到）
    if dailyQuest_ and not dailyQuest_.claimed then
        CheckQuestProgress()
        if dailyQuest_.progress >= dailyQuest_.goal then
            ClaimQuestReward()
        end
    end
    -- 未完成委托 → 连击断裂
    if dailyQuest_ and not dailyQuest_.claimed then
        if (playerData_.questStreak or 0) > 0 then
            AddLog("❌ 今日委托未完成，连击中断！（x" .. playerData_.questStreak .. " → x0）")
        end
        playerData_.questStreak = 0
    end
    -- 生成新的每日委托
    GenerateDailyQuest()

    -- P0-B 今日任务清单：每天开始时汇总任务给玩家（Day5+）
    if Retention and Retention.BuildDayStartSummary then
        local dsOk, dsResult = pcall(Retention.BuildDayStartSummary, playerData_.day)
        if dsOk then
            pendingDayStartSummary_ = dsResult  -- nil 表示不弹（Day1-4）
        else
            log:Write(LOG_ERROR, "[EndDay] BuildDayStartSummary error: " .. tostring(dsResult))
        end
    end

    -- 留存系统：目标链进度检查（日结时自动检测并发放奖励）
    if Retention then
        local goalOk, goalErr = pcall(Retention.CheckGoalProgress)
        if not goalOk then log:Write(LOG_ERROR, "[EndDay] CheckGoalProgress error: " .. tostring(goalErr)) end
        -- P2-B 精英目标检查（普通目标链全部完成后激活）
        local eliteOk, eliteErr = pcall(Retention.CheckEliteGoals)
        if not eliteOk then log:Write(LOG_ERROR, "[EndDay] CheckEliteGoals error: " .. tostring(eliteErr)) end
    end

    -- 破产判定
    if playerData_.money <= 0 then
        playerData_.money = 0
        AddLog("  ……钱花光了。坐在空荡荡的网吧里，我开始认真考虑要不要把店关了。")
        PlayBGM("gameover")
        currentPhase_ = PHASE_GAMEOVER
        BuildUI()
        return
    end

    -- 胜利判定：声望 ≥ 200 且锦标赛夺冠 ≥ 3 次，或 world_tournament_invite 已触发
    if not playerData_.victoryTriggered then
        local victoryRep    = (playerData_.reputation or 0) >= 200
        local victoryTourney = (playerData_.totalTourney or 0) >= 3
        local worldInvite   = storyTriggered_ and storyTriggered_["world_tournament_invite"]
        if (victoryRep and victoryTourney) or worldInvite then
            playerData_.victoryTriggered = true
            AddLog("🏆 ══════════════════════════════")
            AddLog("🏆 Dragon Force 已经站在了非洲电竞的顶点！")
            AddLog("🏆 声望 " .. (playerData_.reputation or 0) .. " · 锦标赛夺冠 " .. (playerData_.totalTourney or 0) .. " 次")
            AddLog("🏆 你们的故事，将被这条街永远铭记。")
            AddLog("🏆 ══════════════════════════════")
            PlayBGM("victory")
            currentPhase_ = PHASE_VICTORY
            BuildUI()
            return
        end
    end

    if playerData_.money < 100 then
        -- 现金极度紧张但未破产 → 累计"绝处逢生"计数（供成就系统使用）
        playerData_.nearBankruptCount = (playerData_.nearBankruptCount or 0) + 1
        AddLog("  钱包快见底了，只剩 $" .. math.floor(playerData_.money) .. "。我翻了翻抽屉，心里发紧。")
    elseif playerData_.money < 200 then
        AddLog("  钱包快见底了。我翻了翻抽屉，数了数剩下的美元，心里发紧。得想个办法开源了。")
    end

    -- 新手引导（留存系统：前3天触发交互式教程事件，Day4+ 保留文字提示）
    local day = playerData_.day
    local tutorialEventPending = nil  -- 暂存教程事件，在事件触发阶段统一处理
    if day >= 1 and day <= 3 and Retention and not tutorialShownToday_ then
        local tutOk, tutResult = pcall(Retention.GetNextTutorialEvent, day, 0)
        if tutOk and tutResult then
            tutorialEventPending = tutResult
            tutorialShownToday_ = true
        end
    elseif day == 4 then
        AddLog("💡 提示：招募队员后可以训练他们，队员技术越高跑刀赚的越多！")
        AddLog("💡 组合升级有联动加成！比如「电竞椅Lv3+空调Lv2」= 舒适环境（收入+15%）")
        if #teamMembers_ >= 1 and currentChapter_ == 1 then
            AddLog("⭐ 条件快满足了！招满队员就能解锁第二章剧情！")
        end
    elseif day == 5 then
        AddLog("💡 提示：注意非洲货币贬值风险！现金会缩水，可以买黄金保值。")
        AddLog("💡 你的选择会影响道义值，最终决定多种不同结局！")
    elseif day == 7 then
        AddLog("💡 提示：已经过了一周了！检查一下「每日委托」，完成可以获得额外奖金！")
    elseif day == 10 then
        AddLog("💡 提示：随着声望提高，更多有趣的事件和人物会出现！继续经营！")
    end

    -- 生成群聊消息（每天结算时自动产生）
    log:Write(LOG_INFO, "[EndDay] phase: chat/save/achieve")
    local chatOk, chatErr = pcall(GenerateDailyChatMessages)
    if not chatOk then log:Write(LOG_ERROR, "[EndDay] GenerateDailyChatMessages error: " .. tostring(chatErr)) end

    -- 自动存档
    local saveOk, saveErr = pcall(SaveGame)
    if not saveOk then log:Write(LOG_ERROR, "[EndDay] SaveGame error: " .. tostring(saveErr)) end

    -- P2-A 成就系统：每日结算后检查新成就
    local newAchOk, newAchResult = pcall(Achievements.CheckAndUnlock)
    if newAchOk and newAchResult and #newAchResult > 0 then
        -- 有新解锁成就 → 存入队列，由 UIScreens 弹出通知
        pendingAchievements_ = newAchResult
        for _, ach in ipairs(newAchResult) do
            AddLog("🏅 成就解锁：「" .. ach.title .. "」" .. ach.desc)
        end
    elseif not newAchOk then
        log:Write(LOG_ERROR, "[EndDay] Achievements.CheckAndUnlock error: " .. tostring(newAchResult))
    end

    -- 留存系统：生成明日预告（存档后，确保数据最新）
    if Retention then
        local prevOk, prevResult = pcall(Retention.GenerateTomorrowPreview, playerData_.day)
        if prevOk and prevResult then
            pendingTomorrowPreview_ = prevResult
        else
            if not prevOk then log:Write(LOG_ERROR, "[EndDay] GenerateTomorrowPreview error: " .. tostring(prevResult)) end
        end
    end
    tutorialShownToday_ = false  -- 重置教程标记，为明天准备

    -- P0-2 征途小结：第1天结束时弹出总结弹窗
    if prevDay == 1 then
        local tips = {
            "招募队员后可以训练他们，技术越高跑刀赚得越多！",
            "点击「升级」标签，给网吧装备更好的设备，提升日收入！",
            "每天的「特别行动」会带来随机加成，记得关注！",
            "比赛时选择合适的战术，可以大幅提升胜率！",
        }
        pendingDaySummary_ = {
            day = prevDay,
            income = income,
            netIncome = netIncome,
            money = playerData_.money,
            tip = tips[math.random(1, #tips)],
        }
    end

    -- P1-6 今日特别行动：每天随机生成，影响当日收益/客流
    local DAILY_EVENTS = {
        { icon = "🌃", title = "夜市节",       desc = "周边集市带来大量人流",    modifier = "traffic", value = 0.15 },
        { icon = "⚡", title = "停电预警",      desc = "备好燃油，今晚可能断电",  modifier = "powerRisk", value = 1 },
        { icon = "🎮", title = "新游上线",      desc = "热门新游爆发，客流大增",  modifier = "traffic", value = 0.2 },
        { icon = "🌧️", title = "大雨倾城",     desc = "大雨减少出行，客流略降",  modifier = "traffic", value = -0.1 },
        { icon = "🏆", title = "本地联赛日",    desc = "赛事加成，比赛奖励翻倍",  modifier = "matchReward", value = 1 },
        { icon = "📱", title = "网红直播打卡",  desc = "网红到访，今日声望+20",  modifier = "rep", value = 20 },
        { icon = "💸", title = "周薪发放日",    desc = "周边工人发薪，消费力+20%", modifier = "income", value = 0.2 },
        { icon = "🔧", title = "设备维护日",    desc = "今日设备损耗减半",        modifier = "decayHalf", value = 1 },
        { icon = "🌟", title = "幸运星期一",    desc = "今日所有收益+10%",        modifier = "income", value = 0.1 },
        { icon = "🥁", title = "非洲鼓节",      desc = "节日气氛拉满，声望翻涌",  modifier = "rep", value = 30 },
    }
    if not dailySpecialEvent_ or (playerData_.lastSpecialEventDay or 0) < playerData_.day then
        dailySpecialEvent_ = DAILY_EVENTS[math.random(1, #DAILY_EVENTS)]
        playerData_.lastSpecialEventDay = playerData_.day
        -- 立即应用当日效果
        if dailySpecialEvent_.modifier == "traffic" then
            -- 客流修正在 RefreshTraffic 里读取 dailySpecialEvent_
        elseif dailySpecialEvent_.modifier == "income" then
            local bonus = math.floor(income * dailySpecialEvent_.value)
            playerData_.money = playerData_.money + bonus
            AddLog("✨ 【" .. dailySpecialEvent_.title .. "】" .. dailySpecialEvent_.desc .. "，今日额外收入 $" .. bonus)
        elseif dailySpecialEvent_.modifier == "rep" then
            playerData_.reputation = (playerData_.reputation or 0) + dailySpecialEvent_.value
            AddLog("✨ 【" .. dailySpecialEvent_.title .. "】" .. dailySpecialEvent_.desc)
        elseif dailySpecialEvent_.modifier == "matchReward" then
            AddLog("✨ 【" .. dailySpecialEvent_.title .. "】" .. dailySpecialEvent_.desc)
        else
            AddLog("✨ 【" .. dailySpecialEvent_.title .. "】" .. dailySpecialEvent_.desc)
        end
    end

    -- P2-3 中期竞争压力：Day15 后激活竞争对手 NPC
    if prevDay == 15 and not rivalNpcs_ then
        rivalNpcs_ = {
            { name = "Blaze Net",   city = "市中心", power = 65, trend = "上升", emoji = "🔥", stealPct = 15, threat = "high" },
            { name = "King Cyber",  city = "西区",   power = 58, trend = "稳定", emoji = "👑", stealPct = 10, threat = "mid"  },
            { name = "Speed Zone",  city = "东区",   power = 52, trend = "下降", emoji = "⚡", stealPct = 7,  threat = "low"  },
        }
        AddLog("⚠️ 【新威胁】城里三家网吧开始扩张！Blaze Net、King Cyber、Speed Zone 正在崛起……")
        AddLog("💡 提示：保持客流和声望领先，否则他们会抢走你的市场！")
    end
    -- 竞争压力每7天升级一次（Day22, 29, ...）
    if rivalNpcs_ and prevDay > 15 and (prevDay - 15) % 7 == 0 then
        local myPower = math.floor((playerData_.reputation or 0) / 5 + #teamMembers_ * 10)
        for _, rival in ipairs(rivalNpcs_) do
            rival.power = rival.power + math.random(3, 8)
            -- 同步提升抢客比例（上限30%）
            rival.stealPct = math.min(30, (rival.stealPct or 10) + math.random(1, 3))
            -- 根据战力更新威胁等级
            if rival.power >= 90 then
                rival.threat = "high"
            elseif rival.power >= 70 then
                rival.threat = "mid"
            else
                rival.threat = "low"
            end
        end
        local topRival = rivalNpcs_[1]
        if myPower > topRival.power then
            AddLog("💪 【竞争周报】" .. topRival.name .. " 战力 " .. topRival.power .. "，你的实力 " .. myPower .. " 暂时领先！继续保持！")
            -- ── 反制机制：玩家领先时竞对会主动出招 ──
            local gap = myPower - topRival.power
            if gap >= 20 then
                -- 领先较多：竞对搞价格战，抢客比例额外提升
                local extraSteal = math.random(2, 5)
                topRival.stealPct = math.min(30, topRival.stealPct + extraSteal)
                playerData_.counterPressure = (playerData_.counterPressure or 0) + 1
                AddLog("🔥 【反制警报】" .. topRival.name .. " 发动价格战！本周抢客力度额外提升 +" .. extraSteal .. "%，当心流失老客！")
            elseif gap >= 10 then
                -- 领先中等：竞对挖角，降低一名队员心情
                if #teamMembers_ > 0 then
                    local target = teamMembers_[math.random(1, #teamMembers_)]
                    local moodDrop = math.random(8, 15)
                    target.mood = math.max(10, (target.mood or 50) - moodDrop)
                    AddLog("😤 【挖角警报】" .. topRival.name .. " 派人接触了 " .. target.name .. "！" ..
                        target.name .. " 心情 -" .. moodDrop .. "，注意留人！")
                end
            end
        else
            AddLog("⚠️ 【竞争周报】" .. topRival.name .. " 战力已达 " .. topRival.power .. "，你落后了！快速提升声望和战力！")
            -- 落后时：竞对放松警惕，反制压力自然衰减
            if (playerData_.counterPressure or 0) > 0 then
                playerData_.counterPressure = playerData_.counterPressure - 1
            end
        end
    end

    -- P0-1 新手引导：步骤推进
    -- step 0→1：第一天结束时，提示玩家"去做一次升级"
    local tStep = playerData_.tutorialStep or 0
    if tStep == 0 and prevDay == 1 then
        playerData_.tutorialStep = 1
        AddLog("📌 【新手任务】你撑过了第一天！下一步：点击「升级」标签页，给网吧做一次升级。")
    elseif tStep == 1 then
        -- 引导做升级（在 CompleteUpgrade 里推进到2，这里只做提醒）
        if prevDay >= 2 then
            AddLog("📌 【新手任务】记得去「升级」标签升级一次设备，可以提升日收入哦！")
        end
    elseif tStep == 2 then
        -- 引导看日记：step2→3
        playerData_.tutorialStep = 3
        AddLog("📌 【新手任务】升级完成！现在去「日记」标签翻一翻今天发生的事情吧。")
    end
    -- step 3→99：第一次打开日记后完成（在 BuildDiaryPage 里设置）

    -- P0-3 挂机价值前置感知：第3天日记插入挂机教学提示
    if prevDay == 3 and not storyTriggered_["idle_value_hint"] then
        storyTriggered_["idle_value_hint"] = true
        local maxH = ({ [0]=4, [1]=8, [2]=16, [3]=24, [4]=48 })[playerData_.automationLevel or 0] or 4
        local perHour = math.floor(CalcDailyIncome() / 24)
        AddLog("💡 【挂机小贴士】关掉游戏网吧仍在运营！目前离线最多可累计 "
            .. maxH .. " 小时收益（约 $" .. (perHour * maxH) .. "）。"
            .. "提升「自动化」等级可延长挂机上限。")
    end

    -- P1-2：每日检查名誉里程碑（名誉可通过多种途径积累）
    if PrestigeSystem and PrestigeSystem.CheckHonorMilestones then
        local milOk, milErr = pcall(PrestigeSystem.CheckHonorMilestones)
        if not milOk then log:Write(LOG_WARNING, "[EndDay] CheckHonorMilestones error: " .. tostring(milErr)) end
    end

    -- 联动心情加成
    for _, m in ipairs(teamMembers_) do
        m.mood = math.min(100, (m.mood or 50) + math.random(1, 5) + synergyMood)
    end

    -- ── 插屏广告（自然间隔：日结算完成后） ──
    AdManager.ShowInterstitial(playerData_.day)

    log:Write(LOG_INFO, "[EndDay] phase: events, money=" .. tostring(playerData_.money))
    -- 事件触发（pcall 保护 + UI 安全网：任何事件触发异常都不会导致黑屏）
    local eventTriggered = false
    local eventOk, eventErr

    -- RV2: Day1悬念 / Day2呼应 / 新手奖励事件（方案4+5）
    if RV2 then
        local rv2Event = nil
        if prevDay == 1 and not playerData_.rv2Day1Shown then
            playerData_.rv2Day1Shown = true
            rv2Event = RV2.GetDay1Cliffhanger()
            if rv2Event then rv2Event.type = "auto"; rv2Event.autoResult = rv2Event.result end
        elseif prevDay == 2 and not playerData_.rv2Day2Shown then
            playerData_.rv2Day2Shown = true
            rv2Event = RV2.GetDay2Payoff()
        elseif pendingRV2Event_ then
            rv2Event = pendingRV2Event_
            pendingRV2Event_ = nil
        end
        if rv2Event then
            eventOk, eventErr = pcall(function()
                currentEvent_ = rv2Event
                currentPhase_ = PHASE_EVENT
                PlaySFX("event")
                SaveGame()
                eventTriggered = true
                BuildUI()
            end)
            if not eventOk then
                log:Write(LOG_ERROR, "[EndDay] RV2 event error: " .. tostring(eventErr))
            end
            if eventTriggered then
                if not transition_.active and uiRoot_ == nil then
                    currentPhase_ = PHASE_MANAGE; pcall(BuildUI)
                end
                return
            end
        end
    end

    -- 留存系统：教程事件优先触发（Day 1-3 的交互式引导）
    if tutorialEventPending then
        eventOk, eventErr = pcall(function()
            currentEvent_ = tutorialEventPending
            currentPhase_ = PHASE_EVENT
            PlaySFX("event")
            SaveGame()
            eventTriggered = true
            BuildUI()
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] tutorial event error: " .. tostring(eventErr))
        end
        if eventTriggered then
            if not transition_.active and uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] tutorial event but no UI → forcing manage")
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
            return
        end
    end

    -- 优先触发剧情事件（一次只触发一个）
    eventOk, eventErr = pcall(function()
        if TryTriggerStoryEvent() then
            SaveGame()
            eventTriggered = true
        end
    end)
    if not eventOk then
        log:Write(LOG_ERROR, "[EndDay] TryTriggerStoryEvent error: " .. tostring(eventErr))
    end
    if eventTriggered then
        -- 剧情事件使用 StartTransition 异步回调 BuildUI
        -- 安全网：如果转场未启动且 UI 为空，强制恢复（防止黑屏）
        if not transition_.active and uiRoot_ == nil then
            log:Write(LOG_WARNING, "[EndDay] story event flagged but no transition/UI → forcing manage")
            currentPhase_ = PHASE_MANAGE
            pcall(BuildUI)
        end
        return
    end

    -- 每4天强制触发一次NPC事件，确保人物关系能推进
    if playerData_.day % 4 == 0 then
        eventOk, eventErr = pcall(function()
            local forced = ForceNpcEvent()
            if forced then
                SaveGame()
                eventTriggered = true
            end
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] ForceNpcEvent error: " .. tostring(eventErr))
        end
        if eventTriggered then
            -- NPC事件直接调用 BuildUI，返回前验证 UI 状态
            if uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] NPC event flagged but uiRoot_ nil → forcing manage")
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
            return
        end
    end

    -- 留存系统：NPC 支线剧情触发（条件满足时推进 Kofi/Grace/Snake 故事线）
    if not eventTriggered and NPCStorylines then
        eventOk, eventErr = pcall(function()
            local storyEvent = NPCStorylines.TryAdvance(playerData_.day)
            if storyEvent then
                currentEvent_ = storyEvent
                currentPhase_ = PHASE_EVENT
                PlaySFX("event")
                SaveGame()
                eventTriggered = true
                BuildUI()
            end
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] NPCStorylines.TryAdvance error: " .. tostring(eventErr))
        end
        if eventTriggered then
            if uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] NPC storyline event but uiRoot_ nil → forcing manage")
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
            return
        end
    end

    -- 然后随机事件/招募（不再直接 return，改用 flag + UI 验证）
    local eventHandled = false
    local roll = math.random()
    if roll < 0.20 and #CANDIDATE_POOL > 0 and #teamMembers_ < 5 then
        eventOk, eventErr = pcall(TriggerRecruitEvent)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] TriggerRecruitEvent error: " .. tostring(eventErr))
        else
            eventHandled = true
        end
    elseif roll < 0.55 then
        eventOk, eventErr = pcall(TriggerRandomEvent)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] TriggerRandomEvent error: " .. tostring(eventErr))
        else
            eventHandled = true
        end
    end

    -- 兜底：确保最终都能显示 UI
    playerData_.money = math.max(0, playerData_.money)
    log:Write(LOG_INFO, "[EndDay] === END day=" .. tostring(playerData_.day) .. " money=" .. tostring(playerData_.money) .. " ===")
    if eventHandled and uiRoot_ ~= nil then
        -- 事件已处理且 UI 已构建，正常结束
        return
    end
    -- 事件未处理、事件处理中 BuildUI 失败、或 UI 未构建 → 强制回管理界面
    if eventHandled then
        log:Write(LOG_WARNING, "[EndDay] event handled but uiRoot_ nil → forcing manage UI (anti-blackscreen)")
    end
    PlayBGM("night")  -- 日结后切换到夜间经营BGM，营造沉浸氛围
    currentPhase_ = PHASE_MANAGE
    BuildUI()
end

--- 铁壁网吧：负面事件金钱损失减半
function ApplyIronFortress(moneyBefore)
    if HasIronFortress() and playerData_.money < moneyBefore then
        local loss = moneyBefore - playerData_.money
        local refund = math.floor(loss / 2)
        playerData_.money = playerData_.money + refund
        AddLog("🛡️ 铁壁网吧防护！减损 $" .. refund)
    end
end

--- 每4天强制触发NPC事件，优先选择未遇见的NPC相关事件
function ForceNpcEvent()
    -- 收集未遇见的 NPC ID
    local unmetNpcs = {}
    for _, prof in ipairs(NPC_PROFILES) do
        if not npcJournal_[prof.id] then unmetNpcs[prof.id] = true end
    end
    if not next(unmetNpcs) then return false end  -- 所有NPC都已遇见

    -- 从 NPC 事件池中选取满足条件的事件
    local npcEvents = {}
    for _, e in ipairs(RANDOM_EVENTS) do
        local npcIds = EVENT_NPC_MAP[e.title]
        if npcIds then
            local ids = type(npcIds) == "string" and { npcIds } or npcIds
            for _, nid in ipairs(ids) do
                if unmetNpcs[nid] then
                    if not e.cond then
                        table.insert(npcEvents, e); break
                    else
                        local ok, val = pcall(e.cond)
                        if ok and val then table.insert(npcEvents, e); break end
                    end
                end
            end
        end
    end
    if #npcEvents == 0 then return false end

    -- 随机选一个触发（走正常的事件阶段 UI，与 TriggerRandomEvent 一致）
    local evt = npcEvents[math.random(1, #npcEvents)]
    PlaySFX("event")
    RecordNPCEncounter(evt.title)
    if evt.type == "auto" then
        local moneyBefore = playerData_.money
        if evt.effect then
            local ok2, err2 = pcall(evt.effect)
            if not ok2 then
                log:Write(LOG_ERROR, "[ForceNpcEvent] effect error: " .. tostring(err2))
            end
        end
        ApplyIronFortress(moneyBefore)
        AddLog((evt.icon or "📌") .. " " .. (evt.title or "事件") .. ": " .. (evt.result or ""))
        playerData_.money = math.max(0, playerData_.money)
        BuildUI()
    else
        -- choice 类型：切换到事件阶段，由 BuildEventUI 渲染选项
        currentEvent_ = evt
        currentPhase_ = PHASE_EVENT
        PlayBGM("event")
        BuildUI()
    end
    return true
end

function TriggerRandomEvent()
    PlaySFX("event")

    -- ====== NPC 事件优先机制 ======
    -- 40% 概率尝试优先触发「与未遇见 NPC 相关」的事件，提高解锁率
    local evt
    local tryNpcFirst = math.random() < 0.60
    if tryNpcFirst then
        -- 收集未遇见的 NPC ID
        local unmetNpcs = {}
        for _, prof in ipairs(NPC_PROFILES) do
            if not npcJournal_[prof.id] then unmetNpcs[prof.id] = true end
        end
        -- 如果有未遇见的 NPC，从 NPC 事件池中优先选取
        if next(unmetNpcs) then
            local npcEvents = {}
            for _, e in ipairs(RANDOM_EVENTS) do
                local npcIds = EVENT_NPC_MAP[e.title]
                if npcIds then
                    local ids = type(npcIds) == "string" and { npcIds } or npcIds
                    for _, nid in ipairs(ids) do
                        if unmetNpcs[nid] then
                            -- 检查条件是否满足
                            if not e.cond then
                                table.insert(npcEvents, e); break
                            else
                                local ok, val = pcall(e.cond)
                                if ok and val then table.insert(npcEvents, e); break end
                            end
                        end
                    end
                end
            end
            if #npcEvents > 0 then
                evt = npcEvents[math.random(1, #npcEvents)]
            end
        end
    end

    -- ====== 常规随机选取（备选路径或 60% 概率直接走这里）======
    if not evt then
        for _ = 1, 10 do
            local idx = math.random(1, #RANDOM_EVENTS)
            local candidate = RANDOM_EVENTS[idx]
            if not candidate.cond then
                evt = candidate; break
            else
                local cOk, cVal = pcall(candidate.cond)
                if not cOk then
                    log:Write(LOG_ERROR, "[RandomEvent] cond error: " .. tostring(cVal))
                elseif cVal then
                    evt = candidate; break
                end
            end
        end
    end
    if not evt then
        -- 所有尝试都不满足条件，回退到第一个无条件事件
        for _, e in ipairs(RANDOM_EVENTS) do
            if not e.cond then evt = e; break end
        end
    end
    if not evt then
        -- 极端保底：无可用事件，直接回管理界面
        BuildUI()
        return
    end
    if evt.type == "auto" then
        local moneyBefore = playerData_.money
        if evt.effect then
            local ok2, err2 = pcall(evt.effect)
            if not ok2 then
                log:Write(LOG_ERROR, "[TriggerRandomEvent] effect error: " .. tostring(err2))
            end
        end
        ApplyIronFortress(moneyBefore)
        AddLog((evt.icon or "📌") .. " " .. (evt.title or "事件") .. ": " .. (evt.result or ""))
        RecordNPCEncounter(evt.title)
        playerData_.money = math.max(0, playerData_.money)
        BuildUI()
    else
        currentEvent_ = evt
        currentPhase_ = PHASE_EVENT; PlayBGM("event"); BuildUI()
    end
end

function TriggerRecruitEvent()
    if #CANDIDATE_POOL == 0 then BuildUI(); return end
    PlaySFX("recruit")
    local idx = math.random(1, #CANDIDATE_POOL)
    local c = CANDIDATE_POOL[idx]

    local pronoun = (c.emoji == "👩🏿") and "她" or "他"
    local descText = ""

    if c.special and c.story then
        -- 特殊角色：展示专属剧情
        descText = c.story .. "\n\n" .. c.desc .. "。"
    else
        local introTexts = {
            "一个人推开了网吧的门，好奇地四处张望。你注意到" .. pronoun .. "盯着屏幕里的三角洲画面，眼睛里闪着光。",
            "门外传来一阵争吵。一个叫 " .. c.name .. " 的年轻人正在跟朋友争论跑刀战术，说得头头是道。你走出去搭了句话。",
            "常客介绍了一个叫 " .. c.name .. " 的人来网吧。据说" .. pronoun .. "在附近小有名气——'那个跑刀超猛的人'。",
        }
        descText = introTexts[math.random(1, #introTexts)] .. "\n\n你让" .. pronoun .. "坐下来打了一局——" .. c.desc .. "。"
    end

    currentEvent_ = {
        type = "recruit",
        title = c.special and ("特殊人物: " .. c.name) or "有人来了！",
        icon = c.emoji,
        desc = descText,
        candidate = c,
    }
    currentPhase_ = PHASE_EVENT; BuildUI()
end

--- 消耗行动点数，不够则返回false
