---@diagnostic disable: undefined-global, assign-type-mismatch, param-type-mismatch
local function safeRequire(mod)
    local ok, m = pcall(require, mod)
    if not ok then
        log:Write(LOG_ERROR, "[GL_EndDay] require('" .. mod .. "') failed: " .. tostring(m))
        return nil
    end
    return m
end
local IdleEngine = safeRequire("IdleEngine")
local PrestigeSystem = safeRequire("PrestigeSystem")
local Achievements = safeRequire("Achievements")
local EasterEggs = safeRequire("EasterEggs")
local ChapterSystem = safeRequire("ChapterSystem")
local NPCStorylines = safeRequire("NPCStorylines")
local ComboEvents = safeRequire("ComboEvents")
local Collection = safeRequire("Collection")
local ClimaxDay = safeRequire("ClimaxDay")
local CrisisChain = safeRequire("CrisisChain")
local ReputationSystem = safeRequire("ReputationSystem")
local PersonalStory = safeRequire("PersonalStory")
local RomanceSystem = safeRequire("RomanceSystem")

--- 按权重随机抽取今日策略情境
local function PickRandomStrategy()
    if not DAILY_STRATEGIES or #DAILY_STRATEGIES == 0 then return nil end
    local totalWeight = 0
    for _, s in ipairs(DAILY_STRATEGIES) do totalWeight = totalWeight + (s.weight or 1) end
    local roll = math.random(1, totalWeight)
    local cum = 0
    for _, s in ipairs(DAILY_STRATEGIES) do
        cum = cum + (s.weight or 1)
        if roll <= cum then return s end
    end
    return DAILY_STRATEGIES[1]
end

--- 按 ID 查找策略配置
local function GetStrategyById(id)
    if not DAILY_STRATEGIES then return nil end
    for _, s in ipairs(DAILY_STRATEGIES) do
        if s.id == id then return s end
    end
    return nil
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
    local tOk, traffic = pcall(RefreshTraffic)
    if not tOk then
        log:Write(LOG_ERROR, "[EndDay] RefreshTraffic error: " .. tostring(traffic))
        traffic = playerData_.computers or 5  -- 兜底：最小客流=电脑数
    end
    local cOk2, capacity = pcall(CalcCafeCapacity)
    if not cOk2 then
        log:Write(LOG_ERROR, "[EndDay] CalcCafeCapacity error: " .. tostring(capacity))
        capacity = playerData_.computers or 5
    end

    -- 留存系统：周期性大事件每日效果（影响客流/收入，须在 CalcDailyIncome 前执行）
    if Retention then
        local peOk, peErr = pcall(Retention.CheckPeriodicEvents, playerData_.day)
        if not peOk then log:Write(LOG_ERROR, "[EndDay] CheckPeriodicEvents error: " .. tostring(peErr)) end
    end

    local incOk, income = pcall(CalcDailyIncome)
    if not incOk then
        log:Write(LOG_ERROR, "[EndDay] CalcDailyIncome error: " .. tostring(income))
        income = math.max(10, (playerData_.computers or 5) * 8)  -- 兜底：最低保底收入
    end

    -- 策略卡收入修正（玩家今日所选方案生效）
    local stratSideEffect = nil
    local stratLogMsg = nil
    local stratId = nil   -- 方案A: 记录当前情境 ID 供副作用动态修正
    if playerData_.strategyChosen and playerData_.strategyChoice and playerData_.todayStrategy then
        local strat = GetStrategyById(playerData_.todayStrategy)
        if strat then
            stratId = strat.id
            local opt = (playerData_.strategyChoice == "A") and strat.optA or strat.optB
            local mod = opt and (opt.incomeMod or 1.0) or 1.0
            if mod ~= 1.0 then
                local pct = math.floor((mod - 1.0) * 100)
                local sign = pct >= 0 and "+" or ""
                income = math.floor(income * mod)
                stratLogMsg = string.format("📋 【策略】%s · %s → 今日收入%s%d%%",
                    strat.title or "", opt.label or "", sign, pct)
            end
            stratSideEffect = opt and opt.sideEffect or nil
        end
    end

    local expOk, expList, totalExpense = pcall(CalcDailyExpenses)
    if not expOk then
        log:Write(LOG_ERROR, "[EndDay] CalcDailyExpenses error: " .. tostring(expList))
        expList = {}
        totalExpense = math.floor(income * 0.3)  -- 兜底：支出约为收入30%
    end
    log:Write(LOG_INFO, "[EndDay] calc done: traffic=" .. tostring(traffic) .. " capacity=" .. tostring(capacity) .. " income=" .. tostring(income) .. " expense=" .. tostring(totalExpense))
    -- ── 高潮日收入倍率（cap 1.8）──
    local climaxMulti = 1.0
    do
        local cmOk, cmVal = pcall(ClimaxDay.GetIncomeMultiplier)
        if cmOk and cmVal and cmVal > 1.0 then
            climaxMulti = cmVal
            income = math.floor(income * climaxMulti)
            AddLog("🔥 【高潮日】收入倍率 x" .. string.format("%.1f", climaxMulti) .. "！")
        end
    end

    -- ── 图鉴被动加成（Collection passive bonus）──
    do
        local cpOk, cpBonus = pcall(Collection.GetPassiveBonus, "income")
        if cpOk and cpBonus and cpBonus > 0 then
            local bonus = math.floor(income * cpBonus)
            income = income + bonus
        end
    end

    -- 停电事件（15%概率，第3天后触发；高潮日阻止停电）
    local powerOut = false
    local climaxBlocksBlackout = false
    do
        local cbOk, cbVal = pcall(ClimaxDay.BlocksBlackout)
        if cbOk then climaxBlocksBlackout = cbVal end
    end
    if climaxBlocksBlackout then
        -- 高潮日不触发停电
    elseif playerData_.day >= 3 and math.random() < 0.15 then
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
            -- 无保护，收入下降（缓和：保留50%而非40%）
            PlaySFX("negative")
            if (playerData_.actionPoints or 0) >= 1 then
                -- 紧急手摇发电：消耗1AP，恢复至80%收入
                playerData_.actionPoints = playerData_.actionPoints - 1
                income = math.floor(income * 0.8)
                AddLog("⚡ 今日停电！你拼命摇动手摇发电机，勉强维持了大部分供电。收入-20%，消耗1行动点。")
                AddLog("💪 紧急手摇发电！（剩余AP: " .. playerData_.actionPoints .. "）")
            else
                income = math.floor(income * 0.5)
                AddLog("⚡ 今日停电！没有发电机也没体力手摇，半天无法营业，收入-50%！")
            end
            powerOut = true
        end
    end
    -- 彩蛋：停电/连续不停电追踪
    if powerOut then
        pcall(EasterEggs.OnBlackout)
        pcall(EasterEggs.ResetNoPowerStreak)
    else
        pcall(EasterEggs.OnNoPowerOutage)
    end
    local netIncome = income - totalExpense
    -- 追踪历史总收入（用于终极结局）
    if netIncome > 0 then
        playerData_.totalEarnings = (playerData_.totalEarnings or 0) + netIncome
    end
    playerData_.money = playerData_.money + netIncome
    if netIncome > 0 then PlaySFX("coin_collect") end
    -- 微反馈：日结算金额浮动
    if netIncome ~= 0 then pcall(MFX_MoneyPop, netIncome) end

    -- ── P2: AEL赞助每日结算 ──
    local aelOk, AELSystem = pcall(require, "AELSystem")
    if aelOk and AELSystem and AELSystem.OnEndDay then
        local aelIncome = AELSystem.OnEndDay()
        if aelIncome and aelIncome > 0 then
            -- weeklyIncome 追踪（用于AEL周任务）
            playerData_.weeklyIncome = (playerData_.weeklyIncome or 0) + math.max(0, netIncome) + aelIncome
        end
    end

    -- ── P2: 教练每日结算（技能/心情/扣费）──
    local coachOk, CoachSystem = pcall(require, "CoachSystem")
    if coachOk and CoachSystem and CoachSystem.OnEndDay then
        pcall(CoachSystem.OnEndDay)
    end

    -- ── 策略卡副作用执行 + 日记 ──
    if stratLogMsg then AddLog(stratLogMsg) end
    if stratSideEffect then
        -- 方案A: 按情境 + 玩家当前状态动态修正副作用参数
        local se = {}
        for k, v in pairs(stratSideEffect) do se[k] = v end  -- 浅拷贝，避免污染静态表
        if stratId == "peak_traffic" and se.type == "durability" then
            -- 设备越老越脆：耐久<50时损耗加重，满状态时较轻
            local cond = playerData_.equipCondition or 100
            se.amount = -(20 - math.floor(cond / 10))   -- 满血-10，半血-15，报废-20
        elseif stratId == "unstable_power" and se.type == "money" then
            -- 发电机降低停电概率：无机50%，Lv1→35%，Lv2→20%，Lv3→5%
            local genLv = playerData_.generatorLevel or 0
            se.chance = math.max(0.05, 0.50 - genLv * 0.15)
        end
        if se.type == "durability" then
            local prev = playerData_.equipCondition or 100
            playerData_.equipCondition = math.max(0, prev + se.amount)
            if se.amount < 0 then
                AddLog(string.format("🔧 【策略副作用】设备超负荷运转，耐久度 %d%% → %d%%",
                    prev, playerData_.equipCondition))
            end
        elseif se.type == "money" then
            local roll = math.random()
            local chance = se.chance or 1.0
            if roll < chance then
                playerData_.money = playerData_.money + se.amount
                if se.amount < 0 then
                    AddLog(string.format("⚡ 【策略副作用】突发状况损失 $%d", math.abs(se.amount)))
                else
                    AddLog(string.format("💰 【策略副作用】额外收益 $%d", se.amount))
                end
            end
        elseif se.type == "reputation" then
            playerData_.reputation = math.max(0, (playerData_.reputation or 0) + se.amount)
            if se.amount > 0 then
                AddLog(string.format("⭐ 【策略副作用】口碑提升，声望 +%d", se.amount))
            else
                AddLog(string.format("📉 【策略副作用】口碑下滑，声望 %d", se.amount))
            end
        elseif se.type == "skill" then
            local gained = se.amount or 0
            for _, m in ipairs(teamMembers_) do
                m.skill = math.min(100, (m.skill or 0) + gained)
            end
            if gained > 0 and #teamMembers_ > 0 then
                AddLog(string.format("🎮 【策略副作用】集训效果显著，全队技术 +%d", gained))
            end
        elseif se.type == "rival_steal" then
            -- 方案A: 条件型客流蚕食，满足条件时对手额外抢走客流
            local condMet = true
            if se.condition == "no_tourney_win" then
                condMet = (playerData_.tournamentWins or 0) < 1
            end
            if condMet then
                -- 直接从今日收入扣除（已在 income 基础上按 stealPct 比例估算）
                local extraSteal = se.amount or 5
                local stealLoss = math.floor(income * extraSteal / 100)
                playerData_.money = playerData_.money - stealLoss
                if rivalNpcs_ and #rivalNpcs_ > 0 then
                    rivalNpcs_[1].stealPct = math.min(35, (rivalNpcs_[1].stealPct or 10) + 2)
                end
                AddLog(string.format("🔥 【策略副作用】没有冠军背书，Victor 趁机拉走散客，损失 $%d", stealLoss))
            else
                -- 条件不满足时执行 fallback（声望+8）
                if se.fallback then
                    local fb = se.fallback
                    if fb.type == "reputation" then
                        playerData_.reputation = math.max(0, (playerData_.reputation or 0) + (fb.amount or 0))
                        if (fb.amount or 0) > 0 then
                            AddLog(string.format("⭐ 【策略副作用】冠军口碑加持，声望 +%d", fb.amount))
                        end
                    end
                end
            end
        end
    end
    -- 清空今日策略状态（等待明日重新生成）
    playerData_.strategyChosen = false
    playerData_.strategyChoice = nil

    -- ── 方案B: 加班耐久惩罚结算 ──
    local durPenalty = playerData_.endOfDayDurPenalty or 0
    if durPenalty > 0 then
        local prevDur = playerData_.equipCondition or 100
        playerData_.equipCondition = math.max(0, prevDur - durPenalty)
        AddLog(string.format("🔧 【加班损耗】深夜连续运转，设备耐久 %d%% → %d%%",
            prevDur, playerData_.equipCondition))
        playerData_.endOfDayDurPenalty = 0
    end

    -- ── 里程碑反馈（pcall 保护：里程碑崩溃不影响核心结算） ──
    local msOk2, msErr2 = pcall(function()
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
        -- 行为里程碑（招募/声望/比赛/升级）
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
    end)
    if not msOk2 then log:Write(LOG_ERROR, "[EndDay] milestone check error: " .. tostring(msErr2)) end

    -- 记录昨日净收入，用于翻倍广告
    playerData_.lastNetIncome = netIncome > 0 and netIncome or 0
    playerData_.reputation = math.min(999999, playerData_.reputation + math.floor(income / 20))
    -- 分店随机事件
    local brEvOk, brEvErr = pcall(TriggerBranchEvents)
    if not brEvOk then log:Write(LOG_ERROR, "[EndDay] TriggerBranchEvents error: " .. tostring(brEvErr)) end
    -- 黄金装饰每日声望加成
    if playerData_.goldDecor then
        playerData_.reputation = playerData_.reputation + 3
    end
    -- 声望每日衰减（设备老化、竞争侵蚀）
    local repDecayAmt = 0
    if ReputationSystem and ReputationSystem.ApplyDailyDecay then
        local decayOk, decayVal = pcall(ReputationSystem.ApplyDailyDecay)
        if decayOk then
            repDecayAmt = decayVal or 0
        else
            log:Write(LOG_ERROR, "[EndDay] ReputationSystem.ApplyDailyDecay error: " .. tostring(decayVal))
        end
    end
    if repDecayAmt > 0 then
        AddLog("📉 声望衰减 -" .. repDecayAmt .. "（设备老化/竞争压力）")
    end
    -- 联动加成
    local synOk, synergies, incBonus, trainBonus, synergyMood = pcall(CalcUpgradeSynergies)
    if not synOk then
        log:Write(LOG_ERROR, "[EndDay] CalcUpgradeSynergies error: " .. tostring(synergies))
        synergies = {}; incBonus = 0; trainBonus = 0; synergyMood = 0
    end
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

    -- Big Joe 高利贷结算（15% 日息，更凶残）
    local bjOk, bjErr = pcall(function()
        if (playerData_.bigJoeDebt or 0) > 0 then
            local interest = math.floor(playerData_.bigJoeDebt * 0.15)
            playerData_.bigJoeDebt = playerData_.bigJoeDebt + interest
            local repay = math.min(playerData_.bigJoeDebt, math.max(0, math.floor(playerData_.money * 0.35)))
            playerData_.money = playerData_.money - repay
            playerData_.bigJoeDebt = playerData_.bigJoeDebt - repay
            if playerData_.bigJoeDebt > 0 then
                AddLog("  🦈 Big Joe的小弟来收账。利息$" .. interest .. "，被拿走$" .. repay .. "。还欠$" .. playerData_.bigJoeDebt .. "。他说'别让老板亲自来。'")
            else
                AddLog("  🦈 终于还清Big Joe的钱了。小弟递过一瓶棕榈酒：'老板说你够意思。'希望再也不借了。")
            end
        end
    end)
    if not bjOk then log:Write(LOG_ERROR, "[EndDay] bigJoe debt error: " .. tostring(bjErr)) end

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

    -- 分店日报（含地点/游戏特色加成）（pcall 保护）
    local brDailyOk, brDailyErr = pcall(function()
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
            for _, br in ipairs(branches) do
                if br.bonusType == "reputation" then
                    playerData_.reputation = playerData_.reputation + 8
                elseif br.bonusType == "mood" and #teamMembers_ > 0 then
                    for _, m in ipairs(teamMembers_) do
                        m.mood = math.min(100, (m.mood or 50) + 10)
                    end
                end
                if br.gameBonusType == "popularity" then
                    local extraRep = math.floor((br.income or 40) / 20 * 0.25 * 10)
                    playerData_.reputation = playerData_.reputation + math.max(2, extraRep)
                elseif br.gameBonusType == "strategy" and #teamMembers_ > 0 then
                    for _, m in ipairs(teamMembers_) do
                        m.skill = math.min(SKILL_CAP, (m.skill or 0) + 1)
                    end
                end
            end
        end
    end)
    if not brDailyOk then log:Write(LOG_ERROR, "[EndDay] branch daily error: " .. tostring(brDailyErr)) end

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
        if jbLv >= 1 and (playerData_.decoLevel or 0) >= 2 then
            jbMood = jbMood + 8
        end
        for _, m in ipairs(teamMembers_) do
            m.mood = math.min(100, (m.mood or 50) + jbMood)
        end
    end

    -- ── 政变倒计时处理（pcall 保护） ──
    local coupOk, coupErr = pcall(function()
        if (playerData_.coupDaysLeft or 0) > 0 then
            playerData_.coupDaysLeft = playerData_.coupDaysLeft - 1
            if playerData_.coupDaysLeft <= 0 then
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
                local dailyLoss = math.floor(playerData_.money * 0.08)
                if playerData_.goldSafe then dailyLoss = math.floor(dailyLoss * 0.5) end
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
    end)
    if not coupOk then log:Write(LOG_ERROR, "[EndDay] coup processing error: " .. tostring(coupErr)) end

    -- ── 货币贬值事件（pcall 保护） ──
    local devalOk, devalErr = pcall(function()
        if not IsCoupActive() and playerData_.day >= 10 and playerData_.day % 5 == 0 and math.random() < 0.40 then
            local devalRate = math.random(5, 12) / 100
            local cashLoss = math.floor(playerData_.money * devalRate)
            if playerData_.goldSafe then cashLoss = math.floor(cashLoss * 0.5) end
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
                if not storyTriggered_["first_devaluation"] then
                    storyTriggered_["first_devaluation"] = true
                    AddLog("  💡 提示：现金在非洲会缩水。买黄金可以对冲风险——关注金价走势，低买高卖。")
                end
            end
        end
    end)
    if not devalOk then log:Write(LOG_ERROR, "[EndDay] devaluation error: " .. tostring(devalErr)) end

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

    -- 云变量上报最高天数（用于流失分析）
    if clientCloud then
        local ok, err = pcall(function()
            clientCloud:SetInt("max_day", playerData_.day)
        end)
        if not ok then
            log:Write(LOG_WARNING, "[EndDay] cloud report max_day failed: " .. tostring(err))
        end
    end
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
    -- ── 图鉴系统：每日检查解锁 ──
    do
        local colOk, colErr = pcall(Collection.CheckAndUnlock)
        if not colOk then log:Write(LOG_ERROR, "[EndDay] Collection.CheckAndUnlock error: " .. tostring(colErr)) end
    end

    -- ── 危机链：推进当前活跃链 / 尝试触发新链 ──
    do
        if CrisisChain.IsActive() then
            local ccOk, ccResult = pcall(CrisisChain.AdvanceDay)
            if ccOk and ccResult then
                -- 链结束时有结局结果
                pendingCrisisResult_ = ccResult
            elseif not ccOk then
                log:Write(LOG_ERROR, "[EndDay] CrisisChain.AdvanceDay error: " .. tostring(ccResult))
            end
        else
            local ctOk, ctErr = pcall(CrisisChain.TryTrigger)
            if not ctOk then log:Write(LOG_ERROR, "[EndDay] CrisisChain.TryTrigger error: " .. tostring(ctErr)) end
        end
    end

    -- ── 高潮日：清除今日 + 尝试触发明日 ──
    do
        local cdcOk, cdcErr = pcall(ClimaxDay.ClearToday)
        if not cdcOk then log:Write(LOG_ERROR, "[EndDay] ClimaxDay.ClearToday error: " .. tostring(cdcErr)) end
        local cdtOk, cdtErr = pcall(ClimaxDay.TryTriggerForTomorrow)
        if not cdtOk then log:Write(LOG_ERROR, "[EndDay] ClimaxDay.TryTriggerForTomorrow error: " .. tostring(cdtErr)) end
    end

    trafficBonus_ = 0             -- 重置临时客流加成
    friendlyMatchToday_ = false   -- 重置友谊赛冷却
    playerData_.overtimeUsedToday  = false  -- 方案B: 重置加班标记

    -- ── 生成明日策略卡 ──
    local nextStrat = PickRandomStrategy()
    if nextStrat then
        playerData_.todayStrategy  = nextStrat.id
        playerData_.strategyChosen = false
        playerData_.strategyChoice = nil
    end

    -- 二手市场每日结算
    if Market and Market.DailyTick then
        pcall(Market.DailyTick)
    end

    -- 城市每日运营税（高级城市生活成本）
    if Market and Market.ApplyDailyTax then
        pcall(Market.ApplyDailyTax)
    end

    -- Batch 6: 事件联动系统 —— 每日检查新解锁的联动
    do
        local okEL2, EL2 = pcall(require, "EventLinkage")
        if okEL2 and EL2 and EL2.CheckNewLinkages then
            pcall(EL2.CheckNewLinkages)
        end
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

    -- TabSubQuests 每日重置（支线行动限制 + 次日效果结算）
    do
        local TSQ = safeRequire("TabSubQuests")
        if TSQ then pcall(TSQ.ResetDaily) end
    end

    -- 结算前检查当前委托是否已完成（收入类委托只有此时才能检测到）
    -- 今日委托功能已暂停，跳过委托结算与生成
    -- GenerateDailyQuest()

    -- P0-B 今日任务清单：每天开始时汇总任务给玩家（Day5+）
    if Retention and Retention.BuildDayStartSummary then
        local dsOk, dsResult = pcall(Retention.BuildDayStartSummary, playerData_.day)
        if dsOk then
            pendingDayStartSummary_ = dsResult  -- nil 表示不弹（Day1-4）
        else
            log:Write(LOG_ERROR, "[EndDay] BuildDayStartSummary error: " .. tostring(dsResult))
        end
    end

    -- 门口闲聊系统：每天开始时随机触发（D5+，80%概率）
    if DoorstepChat and DoorstepChat.Generate then
        local dcOk, dcResult = pcall(DoorstepChat.Generate, playerData_.day)
        if dcOk and dcResult then
            pendingDoorstepChat_ = dcResult
        elseif not dcOk then
            log:Write(LOG_ERROR, "[EndDay] DoorstepChat.Generate error: " .. tostring(dcResult))
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

    -- 彩蛋：每日结算随机触发
    pcall(EasterEggs.OnDailySettle)

    -- 章节里程碑系统：检查里程碑完成 + 章节推进
    if ChapterSystem then
        -- 里程碑检查
        local msOk, newMs = pcall(ChapterSystem.CheckMilestones)
        if msOk and newMs and #newMs > 0 then
            for _, ms in ipairs(newMs) do
                local rStr = ""
                if ms.reward then
                    if ms.reward.money then rStr = rStr .. " +$" .. ms.reward.money end
                    if ms.reward.havocCoins then rStr = rStr .. " +🪙" .. ms.reward.havocCoins end
                end
                AddLog("🎯 里程碑达成：「" .. ms.title .. "」" .. ms.desc .. rStr)
            end
            pendingChapterMilestones_ = newMs  -- 供UI弹窗使用
        end
        -- 章节推进检查
        local chOk, chResult = pcall(ChapterSystem.CheckChapterProgress)
        if chOk and chResult then
            local rStr = ""
            if chResult.reward then
                if chResult.reward.money then rStr = rStr .. " +$" .. chResult.reward.money end
                if chResult.reward.havocCoins then rStr = rStr .. " +🪙" .. chResult.reward.havocCoins end
            end
            if chResult.isFinal then
                AddLog("👑 ══════ 最终章完成！══════")
                AddLog("👑 " .. (chResult.reward and chResult.reward.message or "传奇成就！") .. rStr)
            else
                AddLog("📖 ══════ 章节推进！══════")
                AddLog("📖 完成：" .. chResult.fromData.title)
                AddLog("📖 进入：" .. chResult.toData.title .. " — " .. chResult.toData.subtitle .. rStr)
            end
            pendingChapterAdvance_ = chResult  -- 供UI弹窗使用
        end
    end

    -- 破产判定
    if playerData_.money <= 0 then
        playerData_.money = 0
        AddLog("  ……钱花光了。坐在空荡荡的网吧里，我开始认真考虑要不要把店关了。")
        PlayBGM("gameover")
        currentPhase_ = PHASE_GAMEOVER
        local buildOk, buildErr = pcall(BuildUI)
        if not buildOk then log:Write(LOG_ERROR, "[EndDay] gameover BuildUI error: " .. tostring(buildErr)) end
        return
    end

    -- 胜利判定：声望 ≥ 200 且锦标赛夺冠 ≥ 3 次，或 world_tournament_invite 已触发
    if not playerData_.victoryTriggered then
        local victoryRep    = (playerData_.reputation or 0) >= 200
        local victoryTourney = (playerData_.totalTourney or 0) >= 3
        local worldInvite   = storyTriggered_ and storyTriggered_["world_tournament_invite"]
        if (victoryRep and victoryTourney) or worldInvite then
            playerData_.victoryTriggered = true
            -- 叙事系统：根据全局状态决定结局分支
            local ending = nil
            if PersonalStory then
                local endOk, endResult = pcall(PersonalStory.DetermineEnding)
                if endOk and endResult then
                    ending = endResult
                    playerData_.endingId = endResult.id
                    playerData_.endingScore = PersonalStory.CalcEndingScore()
                else
                    if not endOk then log:Write(LOG_ERROR, "[EndDay] DetermineEnding error: " .. tostring(endResult)) end
                end
            end
            currentEnding_ = ending  -- 全局变量供 UI 层读取
            AddLog("🏆 ══════════════════════════════")
            if ending then
                AddLog("🏆 结局：「" .. (ending.name or "传奇") .. "」")
                if ending.dialogues and ending.dialogues[1] then
                    AddLog("🏆 " .. ending.dialogues[1].text)
                end
            else
                AddLog("🏆 Dragon Force 已经站在了非洲电竞的顶点！")
            end
            AddLog("🏆 声望 " .. (playerData_.reputation or 0) .. " · 锦标赛夺冠 " .. (playerData_.totalTourney or 0) .. " 次")
            AddLog("🏆 你们的故事，将被这条街永远铭记。")
            AddLog("🏆 ══════════════════════════════")
            PlayBGM("victory")
            currentPhase_ = PHASE_VICTORY
            local buildOk2, buildErr2 = pcall(BuildUI)
            if not buildOk2 then log:Write(LOG_ERROR, "[EndDay] victory BuildUI error: " .. tostring(buildErr2)) end
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

    -- 新手引导（留存系统：前7天触发交互式教程事件，Day8+ 保留文字提示）
    local day = playerData_.day
    local tutorialEventPending = nil  -- 暂存教程事件，在事件触发阶段统一处理
    -- Day2-4: 如果主线行动已触发对应事件，日终不再重复
    local skipTutorial = (day == 2 and playerData_.day2CrisisDone)
        or (day == 3 and playerData_.day3KofiDone)
        or (day == 4 and playerData_.day4CommunityDone)
    if day >= 1 and day <= 7 and Retention and not tutorialShownToday_ and not skipTutorial then
        local tutOk, tutResult = pcall(Retention.GetNextTutorialEvent, day, 0)
        if tutOk and tutResult then
            tutorialEventPending = tutResult
            tutorialShownToday_ = true
        end
    elseif day == 10 then
        AddLog("💡 提示：随着声望提高，更多有趣的事件和人物会出现！继续经营！")
    end

    -- 生成群聊消息（每天结算时自动产生）
    log:Write(LOG_INFO, "[EndDay] phase: chat/save/achieve")
    local chatOk, chatErr = pcall(GenerateDailyChatMessages)
    if not chatOk then log:Write(LOG_ERROR, "[EndDay] GenerateDailyChatMessages error: " .. tostring(chatErr)) end

    -- 叙事系统：表叔远程消息 + NPC离队后来信（不占事件位，通过聊天系统注入）
    if PersonalStory then
        local uncleOk, uncleErr = pcall(PersonalStory.CheckUncleMessage)
        if not uncleOk then log:Write(LOG_ERROR, "[EndDay] PersonalStory.CheckUncleMessage error: " .. tostring(uncleErr)) end
        local departOk, departErr = pcall(PersonalStory.CheckDepartedMessages)
        if not departOk then log:Write(LOG_ERROR, "[EndDay] PersonalStory.CheckDepartedMessages error: " .. tostring(departErr)) end
    end

    -- ═══ P0-7: 每日结算后更新结局追踪标志 ═══
    pcall(function()
        local ef = playerData_.endingFlags
        if ef then
            -- 更新历史最高资产
            local totalAssets = (playerData_.money or 0) + (playerData_.goldOunces or 0) * 1800
            if totalAssets > ef.financialPeak then ef.financialPeak = totalAssets end
            -- 更新社区声望积分
            ef.communityStanding = (playerData_.karma or 0) + math.floor((playerData_.reputation or 0) / 10)
            -- 更新分店数量
            ef.branchCount = #(playerData_.branches or {})
        end
    end)

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

    -- P0-2 日结分屏：每天结束弹出3屏总结（收支 / 今日故事 / 状态变化）
    do
        local tips = {
            "招募队员后可以训练他们，技术越高跑刀赚得越多！",
            "点击「升级」标签，给网吧装备更好的设备，提升日收入！",
            "每天的「特别行动」会带来随机加成，记得关注！",
            "比赛时选择合适的战术，可以大幅提升胜率！",
            "发电机 + 备用燃油 = 停电无忧。提前投资，稳稳赚！",
            "声望越高，客流越多。经营口碑就是经营钱包。",
            "设备条件越好，客人越满意。别让机器带病工作！",
        }
        -- 收集今日事件摘要（从 diaryEntries_ 取最近的关键日志）
        local storyLines = {}
        local dayLogs = diaryEntries_[prevDay] and diaryEntries_[prevDay].logs or {}
        for i = 1, math.min(5, #dayLogs) do
            local line = dayLogs[i]
            -- 过滤掉纯系统性的日志，只保留有叙事感的
            if line and not line:match("^%s*$") then
                table.insert(storyLines, line)
            end
        end
        -- 状态变化摘要
        local statusChanges = {}
        if powerOut then
            table.insert(statusChanges, "⚡ 今日停电")
        end
        if #teamMembers_ > 0 then
            local avgMood = 0
            for _, m in ipairs(teamMembers_) do avgMood = avgMood + (m.mood or 50) end
            avgMood = math.floor(avgMood / #teamMembers_)
            if avgMood > 70 then
                table.insert(statusChanges, "😊 队伍士气高昂")
            elseif avgMood < 40 then
                table.insert(statusChanges, "😰 队伍士气低落")
            end
        end
        if (playerData_.reputation or 0) > 0 then
            table.insert(statusChanges, "⭐ 声望: " .. (playerData_.reputation or 0))
        end
        if (playerData_.debt or 0) > 0 then
            table.insert(statusChanges, "💳 负债: $" .. playerData_.debt)
        end
        daySummaryPage_ = 1  -- 重置分屏页码
        -- 明日预告：Day1-3 使用固定剧情预告，Day4+ 随机
        local EARLY_DAY_PREVIEWS = {
            [1] = { icon = "⚡", title = "电费房租来袭",  hint = "明天房东 Musa 的儿子会来收租——$150房租+$80水电，准备好现金！" },
            [2] = { icon = "👀", title = "天才少年出没",  hint = "明天可能有个身手不凡的少年出现——留意角落的旧电脑" },
            [3] = { icon = "🏘️", title = "邻居来访",     hint = "街坊们打算来认识你这个新邻居，搞好关系很重要" },
        }
        local TOMORROW_EVENTS = {
            { icon = "🌃", title = "夜市节",       hint = "明天周边有集市，客流会增加" },
            { icon = "⚡", title = "停电预警",      hint = "明天电力不稳，提前备好燃油！" },
            { icon = "🎮", title = "新游上线",      hint = "明天有新游发布，网吧将爆满" },
            { icon = "🌧️", title = "雨天",         hint = "明天有雨，客流可能略降" },
            { icon = "🏆", title = "本地联赛",      hint = "明天有比赛日，奖励翻倍！" },
            { icon = "📱", title = "网红来访",      hint = "有网红计划明天来打卡直播" },
            { icon = "🔧", title = "维护日",        hint = "明天设备损耗减半，适合经营" },
            { icon = "🌟", title = "幸运日",        hint = "明天运势不错，收益可能+10%" },
            { icon = "🥁", title = "非洲鼓节",      hint = "明天节日庆典，声望大涨！" },
        }
        local tomorrowEvt = EARLY_DAY_PREVIEWS[prevDay] or TOMORROW_EVENTS[math.random(1, #TOMORROW_EVENTS)]

        -- 计算"可撑天数"：当前余额 / 日均支出
        local surviveDays = nil
        if totalExpense and totalExpense > 0 then
            surviveDays = math.floor(playerData_.money / totalExpense)
        end

        pendingDaySummary_ = {
            day = prevDay,
            income = income,
            expenses = expList,       -- CalcDailyExpenses 返回的明细表
            totalExpense = totalExpense,
            netIncome = netIncome,
            money = playerData_.money,
            surviveDays = surviveDays, -- 按当前支出还能撑几天
            ---@diagnostic disable-next-line: assign-type-mismatch
            tip = tips[math.random(1, #tips)],
            storyLines = storyLines,
            statusChanges = statusChanges,
            powerOut = powerOut,
            tomorrowPreview = tomorrowEvt,
        }
    end

    -- 2.4 五日结算周：记录每日数据
    if not playerData_.dayHistory then playerData_.dayHistory = {} end
    table.insert(playerData_.dayHistory, {
        day = prevDay,
        income = income or 0,
        expense = totalExpense or 0,
        net = netIncome or 0,
        money = playerData_.money or 0,
        rep = playerData_.reputation or 0,
    })
    -- 保留最近20天数据（避免存档过大）
    while #playerData_.dayHistory > 20 do
        table.remove(playerData_.dayHistory, 1)
    end
    -- 每5天生成周报
    if prevDay >= 5 and prevDay % 5 == 0 and pendingDaySummary_ then
        local history = playerData_.dayHistory
        local totalInc, totalExp, startMoney, endMoney = 0, 0, 0, playerData_.money or 0
        local startRep, endRep = 0, playerData_.reputation or 0
        local bestDay, worstDay = nil, nil
        local count = 0
        for i = #history, 1, -1 do
            local h = history[i]
            if h.day > prevDay - 5 and h.day <= prevDay then
                count = count + 1
                totalInc = totalInc + (h.income or 0)
                totalExp = totalExp + (h.expense or 0)
                if not bestDay or h.net > bestDay.net then bestDay = h end
                if not worstDay or h.net < worstDay.net then worstDay = h end
                if h.day == prevDay - 4 then
                    startMoney = h.money - h.net
                    startRep = h.rep
                end
            end
        end
        pendingDaySummary_.weeklyReport = {
            fromDay = prevDay - 4,
            toDay = prevDay,
            totalIncome = totalInc,
            totalExpense = totalExp,
            totalNet = totalInc - totalExp,
            moneyGrowth = endMoney - startMoney,
            repGrowth = endRep - startRep,
            bestDay = bestDay,
            worstDay = worstDay,
            avgIncome = count > 0 and math.floor(totalInc / count) or 0,
            avgNet = count > 0 and math.floor((totalInc - totalExp) / count) or 0,
        }
    end

    -- 3.1 周排行榜：每5天记录玩家评分快照用于周榜对比
    if prevDay >= 5 and prevDay % 5 == 0 then
        if not playerData_.weeklyScores then playerData_.weeklyScores = {} end
        local cafeScore = CalcCafeScore and CalcCafeScore() or 0
        local combatScore = GetTeamPower and GetTeamPower() or 0
        table.insert(playerData_.weeklyScores, {
            week = math.floor(prevDay / 5),
            day = prevDay,
            cafeScore = cafeScore,
            combatScore = combatScore,
            money = playerData_.money or 0,
            rep = playerData_.reputation or 0,
        })
        -- 保留最近6周数据
        while #playerData_.weeklyScores > 6 do
            table.remove(playerData_.weeklyScores, 1)
        end
    end

    -- 跨日建造：检查是否到达完工日
    if activeUpgrade_ and upgradeCompletionDay_ and playerData_.day >= upgradeCompletionDay_ then
        AddLog("🏗️✅ 跨日建造完工！" .. (UPGRADES[activeUpgrade_] and UPGRADES[activeUpgrade_].name or activeUpgrade_) .. " 升级完成！")
        upgradeTimeLeft_ = 0
        upgradeCompletionDay_ = nil
        local cOk, cErr = pcall(CompleteUpgrade)
        if not cOk then log:Write(LOG_ERROR, "[EndDay] CompleteUpgrade error: " .. tostring(cErr)) end
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
        -- 前3天Wow保底：只选正面事件，确保新手体验积极
        if playerData_.day <= 3 then
            local positiveEvents = {}
            for _, ev in ipairs(DAILY_EVENTS) do
                if ev.modifier == "traffic" and ev.value > 0 then table.insert(positiveEvents, ev)
                elseif ev.modifier == "income" and ev.value > 0 then table.insert(positiveEvents, ev)
                elseif ev.modifier == "rep" then table.insert(positiveEvents, ev)
                elseif ev.modifier == "matchReward" then table.insert(positiveEvents, ev)
                elseif ev.modifier == "decayHalf" then table.insert(positiveEvents, ev)
                end
            end
            dailySpecialEvent_ = positiveEvents[math.random(1, #positiveEvents)]
        else
            dailySpecialEvent_ = DAILY_EVENTS[math.random(1, #DAILY_EVENTS)]
        end
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

    -- P0-4: Victor 压迫线 —— Day8 激活，单一命名反派
    if prevDay == 8 and not rivalNpcs_ then
        rivalNpcs_ = {
            { name = "Gold Net · Victor", city = "街对面", power = 70, trend = "上升",
              emoji = "😈", stealPct = 12, threat = "high",
              desc = "资金雄厚、设备顶级的连锁网吧老板，把你当成蚂蚁" },
        }
        AddLog("😈 【新威胁】街对面的 Gold Net Cafe 开始注意到你了。老板 Victor 是个不好惹的角色……")
        AddLog("💡 Victor 资金雄厚，打价格战你赢不了。靠口碑和队伍实力守住阵地！")
    end
    -- Victor 压力每3天升级一次（Day11, 14, 17, ...）
    if rivalNpcs_ and prevDay > 8 and (prevDay - 8) % 3 == 0 then
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
                pcall(MFX_ThreatPulse)
            elseif gap >= 10 then
                -- 领先中等：竞对挖角，降低一名队员心情
                if #teamMembers_ > 0 then
                    local target = teamMembers_[math.random(1, #teamMembers_)]
                    local moodDrop = math.random(8, 15)
                    target.mood = math.max(10, (target.mood or 50) - moodDrop)
                    AddLog("😤 【挖角警报】" .. topRival.name .. " 派人接触了 " .. target.name .. "！" ..
                        target.name .. " 心情 -" .. moodDrop .. "，注意留人！")
                    pcall(MFX_ThreatPulse)
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

    -- 联动心情加成 + 集市故事心情恢复加成
    local marketMoodBonus = 0
    do
        local msOk2, MS2 = pcall(require, "MarketStorylines")
        if msOk2 and MS2 and MS2.GetBonuses then
            local bOk2, bonuses2 = pcall(MS2.GetBonuses)
            if bOk2 and bonuses2 and bonuses2.moodDecay and bonuses2.moodDecay > 0 then
                -- moodDecay 表示衰减减缓百分比，转为额外心情恢复（每10%≈+1心情）
                marketMoodBonus = math.floor(bonuses2.moodDecay / 10)
            end
        end
    end
    for _, m in ipairs(teamMembers_) do
        m.mood = math.min(100, (m.mood or 50) + math.random(1, 5) + synergyMood + marketMoodBonus)
    end

    -- ── 微反馈：第四面墙彩蛋（低概率触发，增加趣味性） ──
    pcall(function()
        local EASTER_EGGS = {
            { cond = function() return day == 7 end,  text = "游戏提示：攒钱买空调。真的。非洲的热不是闹着玩的。" },
            { cond = function() return day == 13 end, text = "今日幸运数字：404 —— 像你的利润一样找不到。" },
            { cond = function() return playerData_.money > 2000 and math.random() < 0.1 end,
              text = "存款超过2000了？在非洲你已经算中产阶级了。" },
            { cond = function() return playerData_.money < 50 and math.random() < 0.2 end,
              text = "温馨提示：Mama B的贷款利息是黑社会级别的，但你有别的选择吗？" },
            { cond = function() return #teamMembers_ >= 4 and math.random() < 0.08 end,
              text = "队伍人数4+了，记得多买椅子。站着打CS的手感确实不一样。" },
            { cond = function() return (playerData_.totalTourney or 0) >= 1 and math.random() < 0.1 end,
              text = "恭喜夺冠！奖杯放在网吧门口，兼做门挡使用。" },
            { cond = function() return day >= 20 and math.random() < 0.06 end,
              text = "你已经经营20天了。在游戏里开网吧比现实轻松多了，至少不用真的修电脑。" },
            { cond = function() return (playerData_.equipCondition or 100) < 30 and math.random() < 0.15 end,
              text = "设备耐久度告急。电脑发出的声音已经不像机器了，像是在求饶。" },
            { cond = function() return day == 30 end, text = "第30天。开发者本来想在这里放个彩蛋，但deadline来了。这就是彩蛋。" },
            { cond = function() return (playerData_.karma or 0) <= -5 and math.random() < 0.1 end,
              text = "道义值过低。村里的孩子经过你店门口都加速跑过去了。" },
        }
        for _, egg in ipairs(EASTER_EGGS) do
            local ok, pass = pcall(egg.cond)
            if ok and pass then
                MFX_Easter(egg.text)
                break  -- 每天最多一条
            end
        end
    end)

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

    -- 叙事系统：个人碎片揭露 + 社区觉醒弧（占事件位，在主线之后、NPC之前）
    if not eventTriggered and PersonalStory then
        eventOk, eventErr = pcall(function()
            -- 尝试触发个人碎片
            local fragTriggered, fragEvt = PersonalStory.TryTriggerFragment()
            if fragTriggered and fragEvt then
                if fragEvt.trigger == "story_event" then
                    -- 作为完整事件展示
                    currentEvent_ = fragEvt
                    currentPhase_ = PHASE_EVENT
                    PlaySFX("event")
                    SaveGame()
                    eventTriggered = true
                    BuildUI()
                elseif fragEvt.trigger == "append_dialogue" or fragEvt.trigger == "append_monologue" then
                    -- 对话/独白模式
                    currentDialogues_ = fragEvt.dialogues
                    dialogueIndex_ = 1
                    dialogueOverride_ = {
                        title = fragEvt.title or "回忆",
                        icon = fragEvt.icon or "💭",
                        scene = fragEvt.scene,
                    }
                    local firstDlg = currentDialogues_[1]
                    if firstDlg then
                        local isMonologue = (firstDlg.type == "monologue") or (firstDlg.speaker == "narrator")
                        CinematicDialogue.StartTypewriter(firstDlg.text or "", isMonologue)
                        StartTypewriter(firstDlg.text or "")
                    end
                    currentPhase_ = PHASE_DIALOGUE
                    PlaySFX("event")
                    SaveGame()
                    eventTriggered = true
                    BuildUI()
                elseif fragEvt.trigger == "chat_message" then
                    -- 聊天消息注入（不占事件位）
                    if fragEvt.messages then
                        for _, msg in ipairs(fragEvt.messages) do
                            AddChatMsg(msg.sender or "你", msg.text, msg.isSelf, msg.isSystem)
                        end
                    end
                    -- 不设 eventTriggered，让后续事件继续判断
                end
            end
            -- 如果碎片没触发或碎片是聊天模式，尝试社区觉醒弧
            if not eventTriggered then
                local arcTriggered, arcEvt = PersonalStory.TryTriggerCommunityArc()
                if arcTriggered and arcEvt then
                    currentEvent_ = arcEvt
                    currentPhase_ = PHASE_EVENT
                    PlaySFX("event")
                    SaveGame()
                    eventTriggered = true
                    BuildUI()
                end
            end
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] PersonalStory event error: " .. tostring(eventErr))
        end
        if eventTriggered then
            if not transition_.active and uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] PersonalStory event but no UI → forcing manage")
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
            return
        end
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

    -- 角色组合事件系统：特定角色同队时触发免AP惊喜剧情
    if not eventTriggered and ComboEvents then
        eventOk, eventErr = pcall(function()
            local comboEvent = ComboEvents.CheckComboEvents()
            if comboEvent then
                -- 组合事件使用对话模式展示
                currentDialogues_ = comboEvent.dialogues
                dialogueIndex_ = 1
                dialogueOverride_ = {
                    title = comboEvent.title,
                    icon = comboEvent.icon,
                    onComplete = comboEvent.onComplete,
                    resultText = comboEvent.resultText,
                }
                local firstDlg = currentDialogues_[1]
                if not firstDlg then
                    log:Write(LOG_ERROR, "[EndDay] ComboEvent dialogues[1] is nil!")
                    return
                end
                local isMonologue = firstDlg.speaker == "narrator"
                CinematicDialogue.StartTypewriter(firstDlg.text or "", isMonologue)
                StartTypewriter(firstDlg.text or "")
                currentPhase_ = PHASE_DIALOGUE
                PlaySFX("event")
                SaveGame()
                eventTriggered = true
                BuildUI()
            end
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] ComboEvents.CheckComboEvents error: " .. tostring(eventErr))
        end
        if eventTriggered then
            if uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] Combo event but uiRoot_ nil → forcing manage")
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
            return
        end
    end

    -- 感情线系统：每日微事件触发（小雪/Grace 零AP日常）
    if not eventTriggered and RomanceSystem and RomanceSystem.OnEndDay then
        eventOk, eventErr = pcall(function()
            local romanceEvent = RomanceSystem.OnEndDay()
            if romanceEvent then
                currentEvent_ = romanceEvent
                currentPhase_ = PHASE_EVENT
                PlaySFX("event")
                SaveGame()
                eventTriggered = true
                BuildUI()
            end
        end)
        if not eventOk then
            log:Write(LOG_ERROR, "[EndDay] RomanceSystem.OnEndDay error: " .. tostring(eventErr))
        end
        if eventTriggered then
            if uiRoot_ == nil then
                log:Write(LOG_WARNING, "[EndDay] Romance event but uiRoot_ nil → forcing manage")
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

    -- 图鉴系统：每日批量检测解锁（天数、组合、转生等条件）
    if LoreSystem and LoreSystem.CheckAllUnlocks then
        local loreOk, loreErr = pcall(LoreSystem.CheckAllUnlocks)
        if not loreOk then
            log:Write(LOG_ERROR, "[EndDay] LoreSystem.CheckAllUnlocks error: " .. tostring(loreErr))
        end
    end

    -- 旅行者NPC系统：到达/离开/buff递减
    if TravelerSystem and TravelerSystem.OnDayEnd then
        local travOk, travErr = pcall(TravelerSystem.OnDayEnd)
        if not travOk then
            log:Write(LOG_ERROR, "[EndDay] TravelerSystem.OnDayEnd error: " .. tostring(travErr))
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
        -- Day 4-5 负面事件上限保护：已停电则跳过随机事件，避免叠加惩罚
        local skipRandom = (playerData_.day <= 5 and powerOut)
        if skipRandom then
            log:Write(LOG_INFO, "[EndDay] Day<=5 powerOut protection: skipping random event")
        else
            eventOk, eventErr = pcall(TriggerRandomEvent)
            if not eventOk then
                log:Write(LOG_ERROR, "[EndDay] TriggerRandomEvent error: " .. tostring(eventErr))
            else
                eventHandled = true
            end
        end
    end

    -- 兜底：确保最终都能显示 UI
    playerData_.money = math.max(0, playerData_.money)
    log:Write(LOG_INFO, "[EndDay] === END day=" .. tostring(playerData_.day) .. " money=" .. tostring(playerData_.money) .. " ===")
    if eventHandled and uiRoot_ ~= nil then
        -- 事件已处理且 UI 已构建，正常结束
        -- 事件结束后仍需检查章节推进（延迟到事件展示完毕后由事件系统回调）
        return
    end
    -- 事件未处理、事件处理中 BuildUI 失败、或 UI 未构建 → 强制回管理界面
    if eventHandled then
        log:Write(LOG_WARNING, "[EndDay] event handled but uiRoot_ nil → forcing manage UI (anti-blackscreen)")
    end

    -- ── 自动章节推进（A+C方案）：EndDay结算检测到章节条件满足时自动触发 ──
    if pendingChapterAdvance_ and not pendingChapterAdvance_.isFinal then
        local nextCh = pendingChapterAdvance_.to
        pendingChapterAdvance_ = nil  -- 清除，避免重复触发
        log:Write(LOG_INFO, "[EndDay] Auto chapter advance → Chapter " .. tostring(nextCh))
        PlaySFX("upgrade")
        local chOk, chErr = pcall(StartChapterWithTransition, nextCh)
        if not chOk then
            log:Write(LOG_ERROR, "[EndDay] StartChapterWithTransition error: " .. tostring(chErr))
            -- 回退到管理界面，避免卡死
            currentPhase_ = PHASE_MANAGE
            pcall(BuildUI)
        end
        return
    end

    PlayBGM("night")  -- 日结后切换到夜间经营BGM，营造沉浸氛围
    currentPhase_ = PHASE_MANAGE
    BuildUI()
end

