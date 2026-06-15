---@diagnostic disable: undefined-global
--- TabSubQuests.lua
--- 各Tab差异化支线行动系统
--- 每个Tab拥有独立的渐进式支线内容，基于天数+剧情解锁
--- 避免所有Tab都是"同质化按钮堆砌"

local ProgressiveUnlock = require("ProgressiveUnlock")

local M = {}

-- ═══════════════════════════════════════════════════
-- 经营Tab支线：网吧运营策略
-- 特色：定价策略、增值服务、主题活动（影响日常收入结构）
-- ═══════════════════════════════════════════════════

--- 获取经营Tab的额外行动列表
---@return table[] actions {title, price, reward, disabled, reason, onClick, unlockDay}
function M.GetManageActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1

    -- Day 5+: 调整定价策略（改变收入结构）
    if day >= 5 then
        local currentTier = playerData_.priceTier or 1
        local tierNames = { "平民价", "标准价", "高端价" }
        local tierEffects = { "客流+20% 单价低", "均衡", "单价高 客流-15%" }
        table.insert(actions, {
            title = "💡 调整定价",
            price = tierNames[currentTier] .. " → " .. tierEffects[currentTier],
            reward = "改变收入结构",
            disabled = false,
            onClick = function()
                M._DoPriceStrategy()
            end,
        })
    end

    -- Day 7+: 网吧主题日活动（每天只能办一次）
    if day >= 7 then
        local didTheme = playerData_.themeEventToday
        table.insert(actions, {
            title = "🎯 主题活动日",
            price = didTheme and "今日已办" or "AP1 · $80",
            reward = didTheme and "—" or "声望+15 客流翻倍",
            disabled = noAP or didTheme or (playerData_.money or 0) < 80,
            reason = didTheme and "每天限一次" or ((playerData_.money or 0) < 80 and "余额不足" or nil),
            onClick = function()
                M._DoThemeEvent()
            end,
        })
    end

    -- Day 10+: 增值服务（解锁后永久被动收入）
    if day >= 10 then
        local services = playerData_.valueAddedServices or {}
        local nextService = M._GetNextValueService(services)
        if nextService then
            table.insert(actions, {
                title = "🏪 " .. nextService.name,
                price = "$" .. nextService.cost,
                reward = nextService.reward,
                disabled = (playerData_.money or 0) < nextService.cost,
                reason = (playerData_.money or 0) < nextService.cost and "余额不足" or nil,
                onClick = function()
                    M._DoBuyValueService(nextService)
                end,
            })
        end
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 街区Tab支线：社区网络与情报
-- 特色：人际关系、情报收集、地盘扩展（影响随机事件概率）
-- ═══════════════════════════════════════════════════

--- 获取街区Tab的额外行动列表
function M.GetHoodActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1

    -- Day 5+: 拜访小贩（随机交易机会，可能低价拿货）
    if day >= 5 then
        local visited = playerData_.vendorVisitToday
        table.insert(actions, {
            title = "🏪 拜访小贩",
            price = visited and "今日已访" or "AP1",
            reward = visited and "—" or "随机交易/情报",
            disabled = noAP or visited,
            reason = visited and "明天再来" or nil,
            onClick = function()
                M._DoVisitVendor()
            end,
        })
    end

    -- Day 7+: 社区帮忙（做好事换声望，有小概率触发特殊剧情）
    if day >= 7 then
        table.insert(actions, {
            title = "🤝 社区互助",
            price = "AP1",
            reward = "声望+8~20 · 可能触发支线",
            disabled = noAP,
            onClick = function()
                M._DoCommunityHelp()
            end,
        })
    end

    -- Day 9+: 打探风声（获得下一天事件预警）
    if day >= 9 then
        local scouted = playerData_.intelGatheredToday
        table.insert(actions, {
            title = "🕵️ 打探风声",
            price = scouted and "已获情报" or "AP1 · $30",
            reward = scouted and (playerData_.tomorrowHint or "无特殊消息") or "预知明日风险",
            disabled = noAP or scouted or (playerData_.money or 0) < 30,
            reason = scouted and "今日已探" or nil,
            onClick = function()
                M._DoGatherIntel()
            end,
        })
    end

    -- Day 12+: 地盘保护费/谈判（花钱或花声望减少危机概率）
    if day >= 12 then
        local prot = playerData_.protectionDays or 0
        if prot <= 0 then
            table.insert(actions, {
                title = "🛡️ 街区保护",
                price = "声望30 或 $200",
                reward = "3天免受骚扰",
                disabled = (playerData_.reputation or 0) < 30 and (playerData_.money or 0) < 200,
                onClick = function()
                    M._DoProtectionDeal()
                end,
            })
        else
            table.insert(actions, {
                title = "🛡️ 保护生效中",
                price = "剩余 " .. prot .. " 天",
                reward = "免受骚扰",
                disabled = true,
                reason = "已生效",
                onClick = function() end,
            })
        end
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 战队Tab支线：队伍培养与高阶比赛
-- 特色：训练系统、赏金赛、队员技能树（影响比赛上限）
-- ═══════════════════════════════════════════════════

--- 获取战队Tab的额外行动列表
function M.GetTeamActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1
    local teamSize = teamMembers_ and #teamMembers_ or 0

    -- Day 5+: 看比赛录像（永久提升队伍战力，每天限一次）
    if day >= 5 and teamSize >= 1 then
        local trained = playerData_.tacticsTrainedToday
        table.insert(actions, {
            title = "📺 看比赛录像",
            price = trained and "今日已训" or "AP1 · $40",
            reward = trained and "—" or "全队技术+2~5",
            disabled = noAP or trained or (playerData_.money or 0) < 40,
            reason = trained and "每天限一次" or nil,
            onClick = function()
                M._DoTacticsTraining()
            end,
        })
    end

    -- Day 8+: 赏金赛（高风险高回报比赛）
    if day >= 8 and teamSize >= 3 then
        local bountyFee = 150 + (day - 8) * 20
        table.insert(actions, {
            title = "🏆 赏金挑战赛",
            price = "AP1 · 报名$" .. bountyFee,
            reward = "奖金$" .. bountyFee * 3 .. " 或全输",
            disabled = noAP or (playerData_.money or 0) < bountyFee,
            reason = (playerData_.money or 0) < bountyFee and "余额不足" or nil,
            onClick = function()
                M._DoBountyMatch(bountyFee)
            end,
        })
    end

    -- Day 10+: 队员特训（指定队员强化某项属性）
    if day >= 10 and teamSize >= 1 then
        table.insert(actions, {
            title = "🎯 专项特训",
            price = "AP1 · $60",
            reward = "指定队员单项+5",
            disabled = noAP or (playerData_.money or 0) < 60,
            onClick = function()
                M._DoSpecialTraining()
            end,
        })
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 投资Tab支线：金融与投机
-- 特色：期货、信息差套利、合伙经营（高风险高回报）
-- ═══════════════════════════════════════════════════

--- 获取投资Tab的额外行动列表
function M.GetRiskActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1

    -- Day 9+: 信息差套利（基于之前打探的情报获利）
    if day >= 9 then
        local hasIntel = playerData_.intelGatheredToday or playerData_.storedIntel
        table.insert(actions, {
            title = "📊 信息差套利",
            price = "AP1 · $100",
            reward = hasIntel and "💎 有情报加成！" or "普通收益",
            disabled = noAP or (playerData_.money or 0) < 100,
            onClick = function()
                M._DoInfoArbitrage(hasIntel)
            end,
        })
    end

    -- Day 12+: 合伙投资（投入资金，3天后获得回报或亏损）
    if day >= 12 then
        local activeInvest = playerData_.partnerInvestment
        if activeInvest then
            local daysLeft = (activeInvest.returnDay or 0) - day
            if daysLeft > 0 then
                table.insert(actions, {
                    title = "🤝 合伙投资中",
                    price = daysLeft .. "天后结算",
                    reward = "已投$" .. (activeInvest.amount or 0),
                    disabled = true,
                    reason = "等待回报",
                    onClick = function() end,
                })
            end
        else
            local investMin = 200 + day * 10
            table.insert(actions, {
                title = "🤝 合伙经营",
                price = "$" .. investMin .. "+",
                reward = "3天后 1.5~2.5x 或亏50%",
                disabled = (playerData_.money or 0) < investMin,
                onClick = function()
                    M._DoPartnerInvestment(investMin)
                end,
            })
        end
    end

    -- Day 15+: 期货投机（当日结算，纯赌博）
    if day >= 15 then
        table.insert(actions, {
            title = "📈 期货投机",
            price = "AP1 · $200+",
            reward = "即时：翻倍 或 腰斩",
            disabled = noAP or (playerData_.money or 0) < 200,
            onClick = function()
                M._DoFuturesGamble()
            end,
        })
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 副业Tab：自我提升（学习技能、恢复行动力、下一天准备）
-- ═══════════════════════════════════════════════════

--- 获取休整Tab的额外行动列表
function M.GetRestActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1

    -- Day 3+: 听广播学技术（随机学到技能/知识，偶尔解锁新选项）
    if day >= 3 then
        local studied = playerData_.studiedToday
        table.insert(actions, {
            title = "📻 听广播学技术",
            price = studied and "今日已学" or "AP1",
            reward = studied and "—" or "随机：维修/电商/编程/经营/社交",
            disabled = noAP or studied,
            reason = studied and "每天限一次" or nil,
            onClick = function()
                M._DoSelfStudy()
            end,
        })
    end

    -- Day 6+: 今天早歇（放弃剩余AP，换明天+1AP）
    if day >= 6 then
        local restBooked = playerData_.earlyRestBooked
        table.insert(actions, {
            title = "😴 今天早歇",
            price = restBooked and "已预约" or "消耗剩余AP",
            reward = restBooked and "明日AP+1" or "明天行动力+1",
            disabled = restBooked,
            reason = restBooked and "已安排" or nil,
            onClick = function()
                M._DoEarlyRest()
            end,
        })
    end

    -- Day 8+: 调查市场（花时间研究，明天购物/交易有折扣）
    if day >= 8 then
        local researched = playerData_.marketResearchToday
        table.insert(actions, {
            title = "🔍 市场调研",
            price = researched and "已调研" or "AP1 · $20",
            reward = researched and "明日折扣已激活" or "明日购物-15%",
            disabled = noAP or researched or (playerData_.money or 0) < 20,
            reason = researched and "已完成" or nil,
            onClick = function()
                M._DoMarketResearch()
            end,
        })
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 副业Tab：赚外快（摆摊/代收快递/辅导补习）
-- 特色：安全低风险收入，按天数逐步解锁
-- ═══════════════════════════════════════════════════

--- 获取副业Tab的"赚外快"行动列表（不含修手机，修手机独立置顶）
function M.GetSideJobActions()
    local actions = {}
    local day = playerData_.day or 1
    local noAP = (playerData_.actionPoints or 0) < 1

    -- Day 5+: 摆摊卖货（利用网吧前空地摆摊，稳定收益）
    if day >= 5 then
        local stallDone = playerData_.stallSoldToday
        local stallEarning = 25 + math.floor(day * 2)  -- 随天数微增
        table.insert(actions, {
            title = "🛒 摆摊卖货",
            price = stallDone and "今日已摆" or "AP1",
            reward = stallDone and "—" or ("+$" .. stallEarning),
            disabled = noAP or stallDone,
            reason = stallDone and "每天限一次" or nil,
            onClick = function()
                M._DoStallSell(stallEarning)
            end,
        })
    end

    -- Day 8+: 代收快递（帮邻居代收，积累人脉+小费）
    if day >= 8 then
        local deliveryDone = playerData_.deliveryDoneToday
        local deliveryTip = 15 + math.floor(day * 1.5)
        table.insert(actions, {
            title = "📦 代收快递",
            price = deliveryDone and "今日已收" or "AP1",
            reward = deliveryDone and "—" or ("+$" .. deliveryTip .. " +声望5"),
            disabled = noAP or deliveryDone,
            reason = deliveryDone and "每天限一次" or nil,
            onClick = function()
                M._DoDeliveryPickup(deliveryTip)
            end,
        })
    end

    -- Day 12+: 辅导补习（教附近学生电脑基础，高收益但消耗多）
    if day >= 12 then
        local tutorDone = playerData_.tutorDoneToday
        local tutorFee = 60 + math.floor(day * 3)
        table.insert(actions, {
            title = "🎓 辅导补习",
            price = tutorDone and "今日已教" or "AP2",
            reward = tutorDone and "—" or ("+$" .. tutorFee .. " +声望8"),
            disabled = (playerData_.actionPoints or 0) < 2 or tutorDone,
            reason = tutorDone and "每天限一次" or ((playerData_.actionPoints or 0) < 2 and "需要2AP" or nil),
            onClick = function()
                M._DoTutoring(tutorFee)
            end,
        })
    end

    return actions
end

-- ═══════════════════════════════════════════════════
-- 行动实现（内部函数）
-- ═══════════════════════════════════════════════════

--- 定价策略弹窗
function M._DoPriceStrategy()
    local tiers = {
        { name = "平民价", desc = "单价$1.5 客流+20%", effect = { priceMulti = 0.75, flowMulti = 1.2 } },
        { name = "标准价", desc = "单价$2.0 客流正常", effect = { priceMulti = 1.0, flowMulti = 1.0 } },
        { name = "高端价", desc = "单价$3.0 客流-15%", effect = { priceMulti = 1.5, flowMulti = 0.85 } },
    }
    local current = playerData_.priceTier or 1
    local opts = {}
    for i, t in ipairs(tiers) do
        local isCurrent = (i == current)
        table.insert(opts, {
            text = (isCurrent and "✓ " or "") .. t.name .. " — " .. t.desc,
            onClick = function()
                playerData_.priceTier = i
                playerData_.priceMultiplier = t.effect.priceMulti
                playerData_.flowMultiplier = t.effect.flowMulti
                AddLog("💡 定价策略调整为【" .. t.name .. "】" .. t.desc)
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    ShowActionChoice("调整定价策略 (当前：" .. tiers[current].name .. ")", opts)
end

--- 主题活动日（故事确认弹窗）
local THEME_SCENES = {
    { npc = "🎮 电竞之夜", themeIdx = 1, lines = {
        "你贴出手写海报，Kwame帮你搬来投影仪。",
        "晚上八点，街坊三三两两凑过来，比赛开始时，",
        "小小的网吧里挤满了人，欢呼声传到隔壁街。",
    }},
    { npc = "🖥️ 新手体验日", themeIdx = 2, lines = {
        "几个从没碰过电脑的少年探头探脑地走进来。",
        "你耐心教他们开机、打字、上网——他们兴奋地",
        "互相喊：「快来看！这里面什么都有！」",
    }},
    { npc = "🕹️ 怀旧游戏日", themeIdx = 3, lines = {
        "你把老旧的PS2接上电视，街坊们像发现宝藏。",
        "大叔们抢着玩《实况足球》，小孩围着看《合金装备》，",
        "有人说「这比新游戏好玩」，笑声一直到关门。",
    }},
    { npc = "👩 女性优惠日", themeIdx = 4, lines = {
        "Mama B带着几个年轻姑娘第一次踏进网吧。",
        "起初她们有些拘束，但很快就被短视频和社交平台吸引了。",
        "「原来网吧不是只给男孩子去的嘛，」一个姑娘笑着说。",
    }},
}

local THEME_DATA = {
    { name = "电竞之夜", bonus = "客流x2 持续当天", rep = 15 },
    { name = "新手体验日", bonus = "新增3名潜在常客", rep = 10 },
    { name = "怀旧游戏日", bonus = "声望+20 小费+50%", rep = 20 },
    { name = "女性优惠日", bonus = "开拓新客源 声望+12", rep = 12 },
}

function M._DoThemeEvent()
    local scene = THEME_SCENES[math.random(#THEME_SCENES)]
    local themeInfo = THEME_DATA[scene.themeIdx]
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "🎯 举办活动", hint = "(AP1·$80 → " .. themeInfo.bonus .. ")", onClick = function()
                M._DoThemeEventExecute(scene.themeIdx)
            end },
            { text = "今天不办了", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoThemeEventExecute(themeIdx)
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 80
    playerData_.themeEventToday = true
    pcall(MFX_MoneyPop, -80)

    local theme = THEME_DATA[themeIdx]
    playerData_.reputation = (playerData_.reputation or 0) + theme.rep
    -- 主题日客流翻倍效果存入临时变量，EndDay时结算
    playerData_.themeBonus = theme
    AddLog("🎯 今日主题活动【" .. theme.name .. "】" .. theme.bonus)
    PlaySFX("success")
    BuildUI()
end

--- 增值服务系统
function M._GetNextValueService(owned)
    local allServices = {
        { id = "printing", name = "打印复印服务", cost = 150, reward = "日收+$15", income = 15 },
        { id = "snacks", name = "零食饮料柜", cost = 200, reward = "日收+$25", income = 25 },
        { id = "vip_room", name = "VIP包间", cost = 400, reward = "日收+$50", income = 50 },
        { id = "repair_station", name = "手机维修站", cost = 300, reward = "修手机收入x2", income = 0, perk = "repair_double" },
        { id = "streaming_booth", name = "直播间", cost = 500, reward = "直播收入+80%", income = 0, perk = "stream_boost" },
    }
    for _, svc in ipairs(allServices) do
        if not owned[svc.id] then
            return svc
        end
    end
    return nil
end

function M._DoBuyValueService(svc)
    if (playerData_.money or 0) < svc.cost then return end
    playerData_.money = playerData_.money - svc.cost
    pcall(MFX_MoneyPop, -svc.cost)
    local services = playerData_.valueAddedServices or {}
    services[svc.id] = true
    playerData_.valueAddedServices = services
    -- 永久日收入增加
    if svc.income > 0 then
        playerData_.passiveIncome = (playerData_.passiveIncome or 0) + svc.income
    end
    if svc.perk then
        playerData_.perks = playerData_.perks or {}
        playerData_.perks[svc.perk] = true
    end
    AddLog("🏪 开通增值服务【" .. svc.name .. "】" .. svc.reward)
    PlaySFX("upgrade")
    BuildUI()
end

--- 拜访小贩（故事确认弹窗）
-- 台词池：展现非洲集市的残酷现实与人间温情
local VENDOR_SCENES = {
    -- 温情面
    { npc = "🏪 小贩Ama", lines = {
        "「老板！刚好你来——」Ama从布堆底下翻出个东西，",
        "眼睛亮得像发现了金矿。「今天运气好，港口那边",
        "有批货刚到，你要不要先看看？」",
    }},
    { npc = "🏪 老Mensah的摊位", lines = {
        "Mensah正在给一台收音机焊接线路，见你来了",
        "咧嘴一笑：「年轻人！坐，吃花生。我这儿有个",
        "好东西，专门给你留的。」",
    }},
    { npc = "🏪 水果摊的Adjoa", lines = {
        "Adjoa一边驱赶苍蝇一边朝你喊：「Dragon Net",
        "老板！我老公从北边带回来几个好物件——你帮我",
        "看看值不值钱，我分你一份好处。」",
    }},
    -- 残酷面
    { npc = "🏪 集市角落", lines = {
        "一个你没见过的年轻人在角落叫住你。他衣服上",
        "有干涸的血迹，声音压得很低：「老板，我有台",
        "二手机器要出……便宜。别问来路。」",
    }},
    { npc = "🏪 Ama（疲惫的）", lines = {
        "今天Ama的摊位只剩一半的货。她揉着眼睛说：",
        "「昨晚有人来搬了我的东西……算了不说了。」",
        "她勉强挤出笑容：「还是有点东西给你看的。」",
    }},
    { npc = "🏪 关门的铁皮摊", lines = {
        "你常去的修理摊今天拉着铁门。旁边卖油的大妈",
        "小声说：「被警察罚了，没执照。」她看看四周，",
        "「不过他托我帮他出一批零件，你要不要？」",
    }},
}

function M._DoVisitVendor()
    local scene = VENDOR_SCENES[math.random(#VENDOR_SCENES)]
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "🚶 花时间逛逛", hint = "(AP1)", onClick = function()
                M._DoVisitVendorExecute()
            end },
            { text = "今天不去了", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoVisitVendorExecute()
    if not UseActionPoint(1) then return end
    playerData_.vendorVisitToday = true

    local outcomes = {
        { text = "小贩卖你便宜二手键盘，设备状态+10", fn = function()
            playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 80) + 10)
        end },
        { text = "听说明天有批货运到港口，市场价格可能波动", fn = function()
            playerData_.storedIntel = "market_volatility"
        end },
        { text = "遇到一个想卖旧显示器的人，$30买入可以+1电脑位", fn = function()
            if (playerData_.money or 0) >= 30 then
                playerData_.money = playerData_.money - 30
                playerData_.computers = (playerData_.computers or 4) + 1
                AddLog("💰 花$30买了台旧显示器，网吧+1机位！")
            else
                AddLog("可惜没带够钱……")
            end
        end },
        { text = "小贩给了你一张传单，明天客流+15%", fn = function()
            playerData_.tomorrowFlowBonus = 0.15
        end },
        { text = "什么也没碰上，但吃了碗地道的jollof rice心情不错", fn = function()
            playerData_.reputation = (playerData_.reputation or 0) + 3
        end },
        -- 残酷侧结果
        { text = "那批货来路不明但确实便宜——设备+15，但心里不太踏实", fn = function()
            playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 80) + 15)
            playerData_.karma = (playerData_.karma or 0) - 1
        end },
    }
    local outcome = outcomes[math.random(#outcomes)]
    outcome.fn()
    AddLog("🏪 拜访小贩：" .. outcome.text)
    PlaySFX("click")
    BuildUI()
end

--- 社区互助（故事确认弹窗 + 三选项）
-- 求助场景池：残酷与温情交织的非洲社区日常
local COMMUNITY_SCENES = {
    -- 温情面
    { npc = "🏠 Mama B", task = "帮修屋顶漏水", lines = {
        "Mama B在门口截住你，围裙上还沾着面粉。",
        "「孩子，昨晚又下雨了，我那屋顶……水漏到",
        "炉灶上，今天生不了火。你能帮我看看吗？」",
    }},
    { npc = "📚 Kwame老师", task = "教孩子们电脑", lines = {
        "社区小学的Kwame老师拦住你：「Dragon Net的",
        "老板！孩子们天天问我电脑是什么——你能不能",
        "来给他们讲半小时？就半小时。」他的眼神很诚恳。",
    }},
    { npc = "🍌 老Kwame", task = "帮搬一车香蕉", lines = {
        "老Kwame的三轮车轮胎又爆了，一车香蕉歪在路",
        "边快被太阳晒烂了。他站在那里一脸无助地看着",
        "来来往往的人——看见你，眼里亮了一下。",
    }},
    -- 残酷面
    { npc = "😰 寡妇Akosua", task = "帮修坏掉的平板", lines = {
        "Akosua抱着丈夫留下的旧平板找到你，眼眶红红",
        "的：「这是他……他走之前给孩子们买的。现在坏了，",
        "修理店要$50我没有……你能帮忙看看吗？」",
    }},
    { npc = "🚿 水井边", task = "参加社区清洁日", lines = {
        "公共水井又被人倒了脏东西。几个妇女在旁边争吵，",
        "一个小孩蹲在地上用手捧浑浊的水喝。社区长老",
        "看到你走过来：「年轻人，帮帮忙吧。」",
    }},
    { npc = "🩹 受伤的少年", task = "送少年去诊所", lines = {
        "一个十来岁的男孩坐在你店门口，膝盖上全是血。",
        "他说是从工地上摔下来的——那种大人不让小孩干",
        "但小孩为了挣$2不得不干的活。「叔叔，疼……」",
    }},
}

function M._DoCommunityHelp()
    local scene = COMMUNITY_SCENES[math.random(#COMMUNITY_SCENES)]
    local donateCost = 15
    local canDonate = (playerData_.money or 0) >= donateCost
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "🤝 亲自帮忙", hint = "(AP1 · 声望+8~20)", onClick = function()
                M._DoCommunityHelpExecute(scene.task)
            end },
            { text = "💰 捐$" .. donateCost .. "请人代劳", hint = "(声望+5)",
              onClick = function()
                if not canDonate then
                    AddLog("💸 钱不够……")
                    BuildUI()
                    return
                end
                playerData_.money = playerData_.money - donateCost
                pcall(MFX_MoneyPop, -donateCost)
                playerData_.reputation = (playerData_.reputation or 0) + 5
                AddLog("🤝 捐了$" .. donateCost .. "请人帮" .. scene.task .. "，声望+5")
                PlaySFX("click")
                BuildUI()
            end },
            { text = "今天太忙了", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoCommunityHelpExecute(taskDesc)
    if not UseActionPoint(1) then return end

    local rep = math.random(8, 20)
    playerData_.reputation = (playerData_.reputation or 0) + rep

    -- 小概率触发特殊支线
    if math.random() < 0.15 then
        AddLog("🤝 " .. taskDesc .. " 声望+" .. rep .. "\n✨ 有人因此向你推荐了一个商机！")
        playerData_.storedIntel = "community_lead"
        ProgressiveUnlock.MarkStoryCompleted("community_trust")
    else
        AddLog("🤝 " .. taskDesc .. " 声望+" .. rep)
    end
    PlaySFX("success")
    BuildUI()
end

--- 打探风声（故事确认弹窗）
-- 情报人场景池：黑暗街角的信息交易
local INTEL_SCENES = {
    -- 危险感
    { npc = "🕶️ 墨镜男", lines = {
        "街角酒吧里那个总戴墨镜的人朝你招了招手。",
        "他面前的啤酒瓶排了一排，但眼睛清醒得很。",
        "「想知道明天会发生什么？坐下，请我喝一杯。」",
    }},
    { npc = "🚬 修车铺后面", lines = {
        "有人在修车铺后面朝你吹了声口哨。是那个总能",
        "提前知道哪里要查店的摩托车司机。他没看你，",
        "只是低声说：「有消息，$30。别回头。」",
    }},
    { npc = "🧓 看报的老人", lines = {
        "每天坐在路口看报纸的老头叫住你。他把报纸",
        "翻到某一页指给你看——但那块内容被人用刀片",
        "裁掉了。「想知道被剪掉的是什么？有价。」",
    }},
    -- 日常感
    { npc = "💇 Tony理发店", lines = {
        "理发店的Tony正在给人剃头，见你路过使了个眼色。",
        "这家店是整条街的情报中心——谁家出了事、谁要",
        "搞事情，Tony比警察还清楚。「进来坐坐？」",
    }},
    { npc = "🍺 Mama Joy的酒吧", lines = {
        "Mama Joy擦着柜台朝你笑了笑：「今天听到几句",
        "有意思的话。不过嘛……消息这东西，也是有成本",
        "的对不对？一杯酒的价钱。」",
    }},
}

function M._DoGatherIntel()
    local scene = INTEL_SCENES[math.random(#INTEL_SCENES)]
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "🕵️ 花$30买消息", hint = "(AP1)", onClick = function()
                M._DoGatherIntelExecute()
            end },
            { text = "算了，不值", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoGatherIntelExecute()
    if not UseActionPoint(1) then return end
    if (playerData_.money or 0) < 30 then
        AddLog("💸 钱不够……")
        BuildUI()
        return
    end
    playerData_.money = playerData_.money - 30
    pcall(MFX_MoneyPop, -30)
    playerData_.intelGatheredToday = true

    local intels = {
        { hint = "明天可能停电，备好燃油", key = "power_outage" },
        { hint = "有匪徒盯上了这条街的店铺", key = "theft_risk" },
        { hint = "明天有大型活动，客流预计+50%", key = "high_traffic" },
        { hint = "隔壁竞争对手打算降价抢客", key = "competitor_move" },
        { hint = "有人在找游戏代练，报酬不错", key = "boost_opportunity" },
        { hint = "暂时没听到什么特别的消息", key = "nothing" },
    }
    local intel = intels[math.random(#intels)]
    playerData_.tomorrowHint = intel.hint
    playerData_.storedIntel = intel.key
    AddLog("🕵️ 花$30打探消息：" .. intel.hint)
    PlaySFX("click")
    BuildUI()
end

--- 街区保护（叙事前缀 + 选项弹窗）
-- 场景描写：街区治安的灰色地带
local PROTECTION_SCENES = {
    { npc = "🛡️ 街区安全", lines = {
        "最近夜里总有人在街上鬼鬼祟祟的。隔壁的",
        "手机店上周被砸了玻璃，再隔壁的杂货铺丢了",
        "一箱啤酒。轮到你只是时间问题。",
    }},
    { npc = "🛡️ 不安的夜晚", lines = {
        "昨晚你关门的时候，看见三个人站在对面盯着你",
        "的店铺。他们没说话，也没动，就是站着看。",
        "今天Ibrahim悄悄跟你说：「该想想办法了。」",
    }},
    { npc = "🛡️ 涂鸦警告", lines = {
        "今早店门口被人用红漆喷了个×。旁边卖布的",
        "大姐收摊时特意走过来压低声音：「给点钱或者",
        "找人撑腰吧，不然下次不只是喷漆了。」",
    }},
}

function M._DoProtectionDeal()
    local scene = PROTECTION_SCENES[math.random(#PROTECTION_SCENES)]
    local opts = {
        { text = "🤝 用人脉换平安", hint = "(声望-30)",
          onClick = function()
            if (playerData_.reputation or 0) < 30 then
                AddLog("你在这条街还没那么大面子……")
                BuildUI()
                return
            end
            playerData_.reputation = playerData_.reputation - 30
            playerData_.protectionDays = 3
            AddLog("🛡️ 凭借你在社区的人脉，获得3天平安！")
            PlaySFX("success")
            BuildUI()
        end },
        { text = "💰 雇人看店", hint = "($200)",
          onClick = function()
            if (playerData_.money or 0) < 200 then
                AddLog("💸 钱不够雇人……")
                BuildUI()
                return
            end
            playerData_.money = playerData_.money - 200
            pcall(MFX_MoneyPop, -200)
            playerData_.protectionDays = 3
            AddLog("🛡️ 雇了个本地小伙看店，3天内不会被骚扰。")
            PlaySFX("success")
            BuildUI()
        end },
        { text = "先忍忍吧", isCancel = true, onClick = function() end },
    }
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = opts,
    })
end

--- 看比赛录像（故事确认弹窗）
-- 训练场景池：非洲电竞队伍的日常复盘
local TACTICS_SCENES = {
    { npc = "📺 赛后复盘", lines = {
        "关门之后，队员们围着一台电脑看昨天的比赛回放。",
        "Kofi指着屏幕说：「看这里，如果我们换路就赢了。」",
        "其他人点头，新人认真做笔记。",
    }},
    { npc = "📺 白板战术课", lines = {
        "你在白板上画出阵型图，标注每个人的站位。",
        "新人一脸迷茫，但老队员不断补充细节。",
        "「这个配合练三遍就能用了，」队长说。",
    }},
    { npc = "📺 凌晨加练", lines = {
        "凌晨2点，网吧早就关门了，但后排几台电脑还亮着。",
        "几个队员在反复练一个配合——失败、重来、失败、重来。",
        "你泡了茶端过去，没说话，他们朝你点了点头。",
    }},
}

function M._DoTacticsTraining()
    local scene = TACTICS_SCENES[math.random(#TACTICS_SCENES)]
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "🎮 开始训练", hint = "(AP1·$40 → 全队技术+2~5)", onClick = function()
                M._DoTacticsTrainingExecute()
            end },
            { text = "今天算了", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoTacticsTrainingExecute()
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 40
    pcall(MFX_MoneyPop, -40)
    playerData_.tacticsTrainedToday = true

    local boost = math.random(2, 5)
    -- 全队战力提升
    if teamMembers_ then
        for _, m in ipairs(teamMembers_) do
            m.skill = (m.skill or 50) + boost
        end
    end
    AddLog("📺 比赛录像复盘完成！全队技术+" .. boost .. " 📈")
    PlaySFX("upgrade")
    BuildUI()
end

--- 赏金挑战赛
function M._DoBountyMatch(fee)
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - fee
    pcall(MFX_MoneyPop, -fee)

    -- 基于队伍平均战力计算胜率
    local avgSkill = 50
    if teamMembers_ and #teamMembers_ > 0 then
        local total = 0
        for _, m in ipairs(teamMembers_) do total = total + (m.skill or 50) end
        avgSkill = total / #teamMembers_
    end
    local winChance = math.min(0.75, avgSkill / 120)
    local won = math.random() < winChance

    if won then
        local prize = fee * 3
        playerData_.money = playerData_.money + prize
        playerData_.reputation = (playerData_.reputation or 0) + 10
        pcall(MFX_MoneyPop, prize)
        AddLog("🏆 赏金赛大胜！赢得 $" .. prize .. " 声望+10！队伍名声大振！")
        PlaySFX("win")
    else
        AddLog("🏆 赏金赛惜败……报名费 $" .. fee .. " 打了水漂。下次再战！")
        PlaySFX("lose")
    end
    BuildUI()
end

--- 专项特训
function M._DoSpecialTraining()
    if not UseActionPoint(1) then return end
    if not teamMembers_ or #teamMembers_ == 0 then return end
    playerData_.money = playerData_.money - 60
    pcall(MFX_MoneyPop, -60)

    -- 随机选一个队员强化
    local member = teamMembers_[math.random(#teamMembers_)]
    local attrs = { "skill", "stamina", "teamwork" }
    local attrNames = { skill = "操作", stamina = "体力", teamwork = "配合" }
    local attr = attrs[math.random(#attrs)]
    local boost = 5
    member[attr] = (member[attr] or 50) + boost
    AddLog("🎯 " .. (member.name or "队员") .. " 进行专项特训，" .. attrNames[attr] .. "+" .. boost .. "！")
    PlaySFX("upgrade")
    BuildUI()
end

--- 信息差套利
function M._DoInfoArbitrage(hasIntel)
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 100
    pcall(MFX_MoneyPop, -100)

    local baseChance = 0.5
    local bonus = hasIntel and 0.25 or 0
    local won = math.random() < (baseChance + bonus)
    local multiplier = hasIntel and math.random(15, 30) / 10 or math.random(12, 22) / 10

    if won then
        local profit = math.floor(100 * multiplier)
        playerData_.money = playerData_.money + profit
        pcall(MFX_MoneyPop, profit)
        AddLog("📊 信息差套利成功！" .. (hasIntel and "(情报加成)" or "") .. " 获利 $" .. (profit - 100))
    else
        local loss = math.floor(100 * 0.5)
        AddLog("📊 套利失败，亏损 $" .. loss .. "……" .. (not hasIntel and "如果有情报就好了" or "运气不好"))
    end
    playerData_.storedIntel = nil
    PlaySFX("click")
    BuildUI()
end

--- 合伙投资
function M._DoPartnerInvestment(minAmount)
    local opts = {
        { amount = minAmount, label = "保守", multi = "1.3~1.8x" },
        { amount = math.floor(minAmount * 1.5), label = "进取", multi = "1.5~2.5x" },
        { amount = math.floor(minAmount * 2.5), label = "冒险", multi = "2.0~3.0x 或亏70%" },
    }
    local choices = {}
    for _, opt in ipairs(opts) do
        if (playerData_.money or 0) >= opt.amount then
            table.insert(choices, {
                text = opt.label .. " ($" .. opt.amount .. ") — 预期" .. opt.multi,
                onClick = function()
                    playerData_.money = playerData_.money - opt.amount
                    pcall(MFX_MoneyPop, -opt.amount)
                    playerData_.partnerInvestment = {
                        amount = opt.amount,
                        tier = opt.label,
                        returnDay = (playerData_.day or 1) + 3,
                    }
                    AddLog("🤝 签下" .. opt.label .. "合伙协议，投入$" .. opt.amount .. "，3天后结算回报。")
                    PlaySFX("click")
                    BuildUI()
                end,
            })
        end
    end
    ShowActionChoice("合伙经营 · 选择投入级别", choices)
end

--- 期货投机
function M._DoFuturesGamble()
    if not UseActionPoint(1) then return end
    local betOpts = { 200, 500, 1000 }
    local choices = {}
    for _, bet in ipairs(betOpts) do
        if (playerData_.money or 0) >= bet then
            table.insert(choices, {
                text = "投入 $" .. bet .. " (赢=翻倍 输=归零)",
                onClick = function()
                    playerData_.money = playerData_.money - bet
                    pcall(MFX_MoneyPop, -bet)
                    local won = math.random() < 0.45  -- 略低于50%胜率
                    if won then
                        local win = bet * 2
                        playerData_.money = playerData_.money + win
                        pcall(MFX_MoneyPop, win)
                        AddLog("📈 期货暴涨！赚了 $" .. bet .. "！💰💰")
                        PlaySFX("win")
                    else
                        AddLog("📉 期货崩盘！$" .. bet .. " 血本无归……")
                        PlaySFX("lose")
                    end
                    BuildUI()
                end,
            })
        end
    end
    ShowActionChoice("期货投机 · 选择投入金额", choices)
end

--- 听广播学技术（故事确认弹窗）
-- 学习场景池：资源匮乏环境下的自我提升方式
local STUDY_SCENES = {
    { npc = "📻 路边收音机", lines = {
        "深夜关店后，你转到那个播修理教程的电台。",
        "信号断断续续，你趴在柜台上拿笔抄要点，",
        "蟑螂从笔记本上爬过——你头也不抬继续写。",
    }},
    { npc = "📰 二手书摊", lines = {
        "路边摊花$1买了本缺了封面的《电脑维修手册》。",
        "虽然是五年前出版的，但基础原理不会变。",
        "你坐在店门口的树荫下翻了起来。",
    }},
    { npc = "💇 Tony理发店", lines = {
        "隔壁Tony一边理发一边跟你说他侄子在做跨境",
        "电商赚了钱。你蹲在他店里假装等位，其实",
        "在听他侄子打电话谈生意的门道。",
    }},
    { npc = "📱 缓冲中的视频", lines = {
        "YouTube上的教程加载了三分钟才出画面。",
        "网速慢得要命，但你边等缓冲边做笔记。",
        "凌晨1点终于看完，眼睛酸但脑子清醒。",
    }},
    { npc = "🧓 社区图书馆", lines = {
        "社区图书馆的阿姨认识你了，每次都给你留",
        "一个靠窗的位置。今天她特意推荐了一本——",
        "「年轻人，这本适合你，讲的是做生意的道理。」",
    }},
}

function M._DoSelfStudy()
    local scene = STUDY_SCENES[math.random(#STUDY_SCENES)]
    ShowStoryConfirm({
        npc = scene.npc,
        lines = scene.lines,
        options = {
            { text = "📖 花时间学学", hint = "(AP1)", onClick = function()
                M._DoSelfStudyExecute()
            end },
            { text = "算了，不急", isCancel = true, onClick = function() end },
        },
    })
end

function M._DoSelfStudyExecute()
    if not UseActionPoint(1) then return end
    playerData_.studiedToday = true

    local skills = {
        { name = "学会了基础网络维修", effect = function()
            playerData_.perks = playerData_.perks or {}
            playerData_.perks["net_repair"] = true
            AddLog("📻 学会了网络维修！以后网络故障可自己修。")
        end },
        { name = "研究了非洲电商趋势", effect = function()
            playerData_.storedIntel = "ecommerce_trend"
            AddLog("📻 本地电商正在起步，也许能从中获利……")
        end },
        { name = "练习了英语口语", effect = function()
            playerData_.reputation = (playerData_.reputation or 0) + 5
            AddLog("📻 英语进步了！和外国客户沟通更顺畅 声望+5")
        end },
        { name = "翻了一本创业指南", effect = function()
            playerData_.perks = playerData_.perks or {}
            playerData_.perks["biz_sense"] = (playerData_.perks["biz_sense"] or 0) + 1
            AddLog("📻 商业嗅觉又灵敏了一分。")
        end },
        { name = "看了编程入门教程", effect = function()
            AddLog("📻 虽然现在用不上……但谁知道呢？")
            playerData_.perks = playerData_.perks or {}
            playerData_.perks["can_code"] = true
        end },
    }
    local skill = skills[math.random(#skills)]
    skill.effect()
    PlaySFX("click")
    BuildUI()
end

--- 养精蓄锐
function M._DoEarlyRest()
    -- 消耗所有剩余AP
    local apLeft = playerData_.actionPoints or 0
    playerData_.actionPoints = 0
    playerData_.earlyRestBooked = true
    playerData_.tomorrowBonusAP = (playerData_.tomorrowBonusAP or 0) + 1
    AddLog("🧘 放弃剩余" .. apLeft .. "点行动力，早睡养精蓄锐，明天AP+1！")
    PlaySFX("click")
    BuildUI()
end

--- 市场调研
function M._DoMarketResearch()
    if not UseActionPoint(1) then return end
    playerData_.money = playerData_.money - 20
    pcall(MFX_MoneyPop, -20)
    playerData_.marketResearchToday = true
    playerData_.tomorrowShopDiscount = 0.15  -- 明天购物-15%
    AddLog("🔍 花了一下午调研市场行情，明天购物享85折！")
    PlaySFX("click")
    BuildUI()
end


-- ═══════════════════════════════════════════════════
-- 副业：赚外快 行动实现
-- ═══════════════════════════════════════════════════

--- 摆摊卖货（Day5+）
function M._DoStallSell(earning)
    if not UseActionPoint(1) then return end
    playerData_.stallSoldToday = true
    playerData_.money = (playerData_.money or 0) + earning
    playerData_.totalEarnings = (playerData_.totalEarnings or 0) + earning
    pcall(MFX_MoneyPop, earning)

    -- 随机事件增加趣味
    local events = {
        "卖出了几条充电线和手机壳，生意不错！",
        "一位路过的司机买走了所有冰水，大赚一笔！",
        "今天人流量一般，但稳稳出摊总有收获。",
        "有个熟客专门来买你的二手零件，口碑传开了！",
    }
    local evt = events[math.random(#events)]
    AddLog("🛒 摆摊卖货 +$" .. earning .. " — " .. evt)
    PlaySFX("coin")
    BuildUI()
end

--- 代收快递（Day8+）
function M._DoDeliveryPickup(tip)
    if not UseActionPoint(1) then return end
    playerData_.deliveryDoneToday = true
    playerData_.money = (playerData_.money or 0) + tip
    playerData_.totalEarnings = (playerData_.totalEarnings or 0) + tip
    playerData_.reputation = (playerData_.reputation or 0) + 5
    pcall(MFX_MoneyPop, tip)

    local events = {
        "帮邻居阿姨签收了3个包裹，她塞给你小费和一袋芒果。",
        "有个上班族赶不回来，你帮忙代收了重要文件，对方非常感激。",
        "今天快递特别多，跑了好几趟，但邻居们记住你的好了。",
        "有人的包裹差点被拿错，幸好你仔细核对。街坊们更信任你了。",
    }
    local evt = events[math.random(#events)]
    AddLog("📦 代收快递 +$" .. tip .. " +声望5 — " .. evt)
    PlaySFX("coin")
    BuildUI()
end

--- 辅导补习（Day12+，消耗2AP）
function M._DoTutoring(fee)
    if (playerData_.actionPoints or 0) < 2 then
        AddLog("❌ 辅导补习需要2个行动点")
        return
    end
    UseActionPoint(2)
    playerData_.tutorDoneToday = true
    playerData_.money = (playerData_.money or 0) + fee
    playerData_.totalEarnings = (playerData_.totalEarnings or 0) + fee
    playerData_.reputation = (playerData_.reputation or 0) + 8
    pcall(MFX_MoneyPop, fee)

    local events = {
        "教两个中学生做PPT，他们学得很认真。",
        "帮一位店主做了Excel表格培训，他直呼专业！",
        "今天教的是基础打字，学生从一指禅变成了双手打字。",
        "一位大学生来学剪辑软件，你分享了不少实战经验。",
    }
    local evt = events[math.random(#events)]
    AddLog("🎓 辅导补习 +$" .. fee .. " +声望8 — " .. evt)
    PlaySFX("success")
    BuildUI()
end

-- ═══════════════════════════════════════════════════
-- 每日重置（在EndDay时调用）
-- ═══════════════════════════════════════════════════

--- 重置每日限制标记
function M.ResetDaily()
    playerData_.themeEventToday = false
    playerData_.vendorVisitToday = false
    playerData_.intelGatheredToday = false
    playerData_.tacticsTrainedToday = false
    playerData_.studiedToday = false
    playerData_.earlyRestBooked = false
    playerData_.marketResearchToday = false
    -- 副业：赚外快
    playerData_.stallSoldToday = false
    playerData_.deliveryDoneToday = false
    playerData_.tutorDoneToday = false
    -- 主题活动日效果仅当天有效，次日清除
    playerData_.themeBonus = nil

    -- 应用"养精蓄锐"效果
    local bonusAP = playerData_.tomorrowBonusAP or 0
    if bonusAP > 0 then
        playerData_.actionPoints = (playerData_.actionPoints or 0) + bonusAP
        playerData_.tomorrowBonusAP = 0
        AddLog("🧘 养精蓄锐生效！今日额外AP+" .. bonusAP)
    end

    -- 应用"明日折扣"效果
    if playerData_.tomorrowShopDiscount then
        playerData_.activeShopDiscount = playerData_.tomorrowShopDiscount
        playerData_.tomorrowShopDiscount = nil
    else
        playerData_.activeShopDiscount = nil
    end

    -- 应用"明日客流加成"
    if playerData_.tomorrowFlowBonus then
        playerData_.activeFlowBonus = playerData_.tomorrowFlowBonus
        playerData_.tomorrowFlowBonus = nil
    else
        playerData_.activeFlowBonus = nil
    end

    -- 结算合伙投资
    local inv = playerData_.partnerInvestment
    if inv and (playerData_.day or 1) >= (inv.returnDay or 999) then
        local base = inv.amount or 0
        local success = math.random() < 0.65
        if success then
            local multi = 1.3 + math.random() * 1.2  -- 1.3~2.5x
            if inv.tier == "冒险" then multi = 2.0 + math.random() * 1.0 end
            local returned = math.floor(base * multi)
            playerData_.money = (playerData_.money or 0) + returned
            AddLog("🤝 合伙经营到期！回报 $" .. returned .. " (投入$" .. base .. ")")
        else
            local returned = math.floor(base * 0.4)
            playerData_.money = (playerData_.money or 0) + returned
            AddLog("🤝 合伙经营亏损……仅回收 $" .. returned .. " (投入$" .. base .. ")")
        end
        playerData_.partnerInvestment = nil
    end

    -- 保护天数递减
    if (playerData_.protectionDays or 0) > 0 then
        playerData_.protectionDays = playerData_.protectionDays - 1
    end
end

return M
