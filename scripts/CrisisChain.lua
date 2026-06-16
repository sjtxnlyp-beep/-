---@diagnostic disable: undefined-global
-- ============================================================================
-- CrisisChain.lua — 危机链系统
-- 多日连锁事件，每天有选择，最长3天，3种结局（好/中/坏）
-- 包含负面危机链和正面机遇链
-- 专家修正：最长3天、每天都有选择（无auto_narrative）、3结局
-- 互斥：危机链进行中不触发高潮日
-- ============================================================================

local CrisisChain = {}

-- ============================================================================
-- 危机链定义（负面 + 正面）
-- ============================================================================
CrisisChain.CHAINS = {
    -- ═══════ 负面危机链 ═══════
    {
        id = "power_crisis",
        name = "电力危机",
        icon = "⚡",
        type = "negative",
        unlockDay = 20,
        desc = "供电公司通知区域限电，网吧面临连续停电威胁",
        days = {
            {
                title = "限电通知",
                desc = "供电局通知：本区域明天起限电。你需要做准备。",
                choices = {
                    { text = "花$200买燃料储备", cost = { money = 200 }, score = 2,
                      result = "你囤积了足够的发电机燃料。" },
                    { text = "拜访供电局关系", cost = { rep = 10 }, score = 1,
                      result = "打了几个电话，但效果不确定。" },
                    { text = "无视，赌它不会停", cost = {}, score = 0,
                      result = "你决定赌一把运气。" },
                },
            },
            {
                title = "停电第一天",
                desc = "果然停电了！客人们很不满，隔壁Victor趁机拉客。",
                choices = {
                    { text = "启动发电机硬撑", cost = { money = 100 }, score = 2,
                      result = "发电机轰鸣中网吧恢复运营。" },
                    { text = "半价营业留住客人", cost = { money = 80 }, score = 1,
                      result = "便宜价吸引了一些忠实客户。" },
                    { text = "关门一天等来电", cost = {}, score = -1,
                      result = "关门了…损失了一天收入和口碑。" },
                },
            },
            {
                title = "危机解决",
                desc = "供电恢复的消息传来，但这次经历让你思考长期对策。",
                choices = {
                    { text = "投资太阳能($300)", cost = { money = 300 }, score = 3,
                      result = "你下定决心投资清洁能源。" },
                    { text = "加入社区电力互助", cost = { rep = 5 }, score = 2,
                      result = "邻里互助，下次会更好应对。" },
                    { text = "算了下次再说", cost = {}, score = 0,
                      result = "危机过去了…但下一次呢？" },
                },
            },
        },
        -- 3种结局（根据累计score）
        endings = {
            good = { threshold = 5, title = "电力先锋",
                     reward = { money = 200, rep = 20 },
                     text = "你成功化解了电力危机，社区视你为应对困难的榜样！" },
            mid  = { threshold = 2, title = "涉险过关",
                     reward = { rep = 5 },
                     text = "危机勉强过去，但过程不太顺利。下次要更有准备。" },
            bad  = { threshold = -999, title = "雪上加霜",
                     penalty = { rep = -10 },
                     text = "这次危机让你损失惨重，客户流失严重。需要时间恢复。" },
        },
    },
    {
        id = "rival_attack",
        name = "对手偷袭",
        icon = "🦊",
        type = "negative",
        unlockDay = 25,
        desc = "Victor开始恶意竞争，挖你的客户和队员",
        days = {
            {
                title = "客户流失",
                desc = "Victor在门口发传单，承诺首周免费！你的客户开始动摇。",
                choices = {
                    { text = "也搞促销反击($150)", cost = { money = 150 }, score = 2,
                      result = "你的促销活动吸引了更多新客户。" },
                    { text = "提升服务品质", cost = { money = 80 }, score = 2,
                      result = "用品质留住老客户的心。" },
                    { text = "找Victor谈判", cost = {}, score = 0,
                      result = "Victor假装友好但并未停止行动。" },
                },
            },
            {
                title = "队员被挖",
                desc = "Victor私下联系你的队员，承诺高薪和更好条件。",
                choices = {
                    { text = "给队员加薪安抚($200)", cost = { money = 200 }, score = 2,
                      result = "队员感到被重视，留了下来。" },
                    { text = "和队员谈理想谈未来", cost = {}, score = 1,
                      result = "有人被感动了，但也有人犹豫。" },
                    { text = "放话：走了别回来", cost = {}, score = -1,
                      result = "强硬态度让团队气氛紧张。" },
                },
            },
            {
                title = "决战时刻",
                desc = "社区举办网吧评比，这是证明自己的机会！",
                choices = {
                    { text = "全力准备参赛($100)", cost = { money = 100 }, score = 3,
                      result = "你投入全部精力准备评比。" },
                    { text = "邀请社区领袖参观", cost = { rep = 10 }, score = 2,
                      result = "社区领袖对你印象深刻。" },
                    { text = "随缘", cost = {}, score = 0,
                      result = "你没有特别准备…" },
                },
            },
        },
        endings = {
            good = { threshold = 5, title = "竞争胜出",
                     reward = { money = 300, rep = 30 },
                     text = "Victor的阴谋完全失败！你的名声反而更响了。" },
            mid  = { threshold = 2, title = "不分胜负",
                     reward = { rep = 10 },
                     text = "和Victor打了个平手，但你保住了核心客户。" },
            bad  = { threshold = -999, title = "惨遭暗算",
                     penalty = { rep = -15, money = -100 },
                     text = "Victor的计划得逞了，你失去了一些客户和队员信任。" },
        },
    },
    {
        id = "health_scare",
        name = "卫生危机",
        icon = "🦠",
        type = "negative",
        unlockDay = 30,
        desc = "网吧卫生问题被举报，政府派人来检查",
        days = {
            {
                title = "举报信",
                desc = "有人向卫生部门举报你的网吧环境差。检查员明天到。",
                choices = {
                    { text = "紧急大扫除($100)", cost = { money = 100 }, score = 2,
                      result = "全员加班打扫，焕然一新。" },
                    { text = "找关系通融", cost = { money = 150 }, score = 1,
                      result = "打了一些电话，可能有用。" },
                    { text = "该来的总会来", cost = {}, score = 0,
                      result = "你决定平常心面对。" },
                },
            },
            {
                title = "检查日",
                desc = "检查员到场了，仔细查看每个角落。",
                choices = {
                    { text = "全程陪同讲解", cost = {}, score = 2,
                      result = "你专业的态度给检查员留下好印象。" },
                    { text = "准备点心招待", cost = { money = 50 }, score = 1,
                      result = "检查员心情不错。" },
                    { text = "躲在后面等结果", cost = {}, score = -1,
                      result = "检查员觉得你不够重视。" },
                },
            },
            {
                title = "结果出炉",
                desc = "检查报告发出，你的命运取决于之前的应对。",
                choices = {
                    { text = "立即整改承诺($120)", cost = { money = 120 }, score = 2,
                      result = "你签署整改承诺书。" },
                    { text = "公开道歉+改进计划", cost = { rep = 5 }, score = 2,
                      result = "诚恳态度赢得社区理解。" },
                    { text = "坚持说没问题", cost = {}, score = -1,
                      result = "你的态度让事情更复杂了。" },
                },
            },
        },
        endings = {
            good = { threshold = 5, title = "卫生标兵",
                     reward = { money = 150, rep = 25 },
                     text = "你获得了「卫生示范网吧」称号，客流反而增加了！" },
            mid  = { threshold = 2, title = "合格通过",
                     reward = { rep = 5 },
                     text = "虽然有些波折，但最终通过了检查。" },
            bad  = { threshold = -999, title = "停业整顿",
                     penalty = { money = -200, rep = -20 },
                     text = "被勒令停业整顿3天，损失惨重。" },
        },
    },

    -- ═══════ 正面机遇链 ═══════
    {
        id = "sponsor_interest",
        name = "赞助商青睐",
        icon = "💼",
        type = "positive",
        unlockDay = 22,
        desc = "一家品牌注意到了你的战队，想探讨合作可能",
        days = {
            {
                title = "邮件来了",
                desc = "收到品牌方邮件：对你的战队感兴趣，想安排视频会议。",
                choices = {
                    { text = "精心准备PPT", cost = { money = 50 }, score = 2,
                      result = "你制作了专业的战队介绍材料。" },
                    { text = "随便聊聊看", cost = {}, score = 1,
                      result = "轻松交流，但显得不够专业。" },
                    { text = "让队员出面展示实力", cost = {}, score = 1,
                      result = "队员们表现不错，但缺少规划。" },
                },
            },
            {
                title = "正式洽谈",
                desc = "品牌方派代表来实地考察网吧和战队。",
                choices = {
                    { text = "办一场表演赛($100)", cost = { money = 100 }, score = 3,
                      result = "精彩的表演赛让代表连连叫好！" },
                    { text = "展示社区影响力", cost = { rep = 10 }, score = 2,
                      result = "社区邻里的好评让代表印象深刻。" },
                    { text = "直接谈钱", cost = {}, score = 0,
                      result = "太直接了…代表面色微变。" },
                },
            },
            {
                title = "合同谈判",
                desc = "品牌方发来了合作合同草案！",
                choices = {
                    { text = "接受标准条款", cost = {}, score = 2,
                      result = "合同签订！稳定的赞助金开始到账。" },
                    { text = "争取更好条件", cost = {}, score = 1,
                      result = "谈判后条件稍有改善。" },
                    { text = "犹豫不决拖延", cost = {}, score = -1,
                      result = "品牌方开始考虑其他队伍…" },
                },
            },
        },
        endings = {
            good = { threshold = 5, title = "金牌合作",
                     reward = { money = 800, rep = 40 },
                     text = "签下了年度赞助大单！品牌方承诺持续支持。" },
            mid  = { threshold = 2, title = "小额赞助",
                     reward = { money = 300, rep = 15 },
                     text = "虽然不是最大的合同，但合作正式开始了。" },
            bad  = { threshold = -999, title = "错失良机",
                     penalty = {},
                     text = "品牌方最终选择了其他队伍。下次要更把握机会。" },
        },
    },
    {
        id = "talent_discovery",
        name = "天才现身",
        icon = "🌟",
        type = "positive",
        unlockDay = 26,
        desc = "一位极有天赋的少年在你的网吧打出了惊人操作",
        days = {
            {
                title = "惊人发现",
                desc = "一个12岁少年在网吧打出了职业级操作，所有人都看呆了。",
                choices = {
                    { text = "立刻邀请他加入", cost = {}, score = 2,
                      result = "你诚恳地邀请了他。" },
                    { text = "先观察几天确认实力", cost = {}, score = 1,
                      result = "你决定再观察看看。" },
                    { text = "询问家长意见", cost = {}, score = 2,
                      result = "你尊重地联系了他的家人。" },
                },
            },
            {
                title = "家庭阻力",
                desc = "少年的父母不同意他打电竞，认为是不务正业。",
                choices = {
                    { text = "登门拜访解释电竞前景($50)", cost = { money = 50 }, score = 3,
                      result = "你带着资料去了他家，父母开始动摇。" },
                    { text = "承诺不影响学业", cost = {}, score = 2,
                      result = "你制定了学业优先的训练计划。" },
                    { text = "让少年自己说服父母", cost = {}, score = 0,
                      result = "少年和父母吵了一架…" },
                },
            },
            {
                title = "最终决定",
                desc = "少年的命运取决于你之前的努力。",
                choices = {
                    { text = "提供奖学金计划", cost = { money = 100 }, score = 2,
                      result = "奖学金计划打动了全家。" },
                    { text = "邀请家长来观赛", cost = {}, score = 2,
                      result = "父母看到了电竞的正面力量。" },
                    { text = "顺其自然", cost = {}, score = 0,
                      result = "结果要看之前积累的印象了。" },
                },
            },
        },
        endings = {
            good = { threshold = 6, title = "天才加入",
                     reward = { rep = 30 },
                     text = "天才少年正式加入战队！全队士气大振。",
                     specialEffect = function()
                         for _, m in ipairs(teamMembers_) do
                             m.skill = math.min(150, (m.skill or 0) + 5)
                             m.mood = math.min(100, (m.mood or 50) + 10)
                         end
                     end },
            mid  = { threshold = 3, title = "兼职训练",
                     reward = { rep = 10 },
                     text = "少年同意周末来训练，虽然不全职但也是收获。" },
            bad  = { threshold = -999, title = "缘分未到",
                     penalty = {},
                     text = "少年最终没有加入，但他说以后一定会回来的。" },
        },
    },
}

-- ============================================================================
-- 核心逻辑
-- ============================================================================

--- 初始化/确保状态存在
function CrisisChain.EnsureState()
    playerData_.crisisState = playerData_.crisisState or {
        active = nil,           -- 当前活跃链 { chainId, dayIndex, score, startDay }
        completed = {},         -- 已完成链 { [chainId] = { ending, day } }
        lastCrisisEnd = 0,      -- 上次危机结束的天数（冷却用）
        todayChoice = nil,      -- 今天的选择事件（供UI显示）
    }
end

--- 判断是否有活跃的危机链
function CrisisChain.IsActive()
    CrisisChain.EnsureState()
    return playerData_.crisisState.active ~= nil
end

--- 尝试触发新的危机链（在EndDay时调用）
--- @return table|nil 触发的链配置
function CrisisChain.TryTrigger()
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    local day = playerData_.day or 1

    -- 已有活跃链，不触发
    if state.active then return nil end

    -- 冷却：上次结束后至少5天
    if day - (state.lastCrisisEnd or 0) < 5 then return nil end

    -- 筛选可触发的链
    local candidates = {}
    for _, chain in ipairs(CrisisChain.CHAINS) do
        if day >= (chain.unlockDay or 999) and not state.completed[chain.id] then
            table.insert(candidates, chain)
        end
    end

    if #candidates == 0 then
        -- 所有链都完成了，允许已完成的重新触发（正面链优先）
        for _, chain in ipairs(CrisisChain.CHAINS) do
            if day >= (chain.unlockDay or 999) then
                table.insert(candidates, chain)
            end
        end
    end

    if #candidates == 0 then return nil end

    -- 触发概率：15%每天（冷却后）
    if math.random() > 0.15 then return nil end

    local chosen = candidates[math.random(1, #candidates)]

    -- 激活链
    state.active = {
        chainId = chosen.id,
        dayIndex = 1,
        score = 0,
        startDay = day + 1,
    }
    state.todayChoice = nil

    if AddLog then
        local typeLabel = chosen.type == "positive" and "机遇" or "危机"
        AddLog(chosen.icon .. " 【" .. typeLabel .. "链开始】" .. chosen.name .. "：" .. chosen.desc)
    end

    return chosen
end

--- 获取今天的选择事件（如果有活跃链且今天该做选择）
--- @return table|nil { chain, dayConfig, dayIndex }
function CrisisChain.GetTodayChoice()
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    if not state.active then return nil end

    local chain = CrisisChain.GetChainById(state.active.chainId)
    if not chain then return nil end

    local dayIndex = state.active.dayIndex
    local dayConfig = chain.days[dayIndex]
    if not dayConfig then return nil end

    return { chain = chain, dayConfig = dayConfig, dayIndex = dayIndex }
end

--- 执行选择
--- @param choiceIndex number 选择的索引（1-based）
--- @return boolean success 是否成功
--- @return string message 结果文本
function CrisisChain.MakeChoice(choiceIndex)
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    if not state.active then return false, "没有活跃的危机链" end

    local chain = CrisisChain.GetChainById(state.active.chainId)
    if not chain then return false, "链配置丢失" end

    local dayConfig = chain.days[state.active.dayIndex]
    if not dayConfig then return false, "天配置丢失" end

    local choice = dayConfig.choices[choiceIndex]
    if not choice then return false, "无效选择" end

    -- 检查并扣除代价
    local cost = choice.cost or {}
    if cost.money and (playerData_.money or 0) < cost.money then
        return false, "资金不足（需要$" .. cost.money .. "）"
    end
    if cost.rep and (playerData_.reputation or 0) < cost.rep then
        return false, "声望不足（需要" .. cost.rep .. "）"
    end

    -- 扣费
    if cost.money then playerData_.money = (playerData_.money or 0) - cost.money end
    if cost.rep then playerData_.reputation = (playerData_.reputation or 0) - cost.rep end

    -- 累计分数
    state.active.score = (state.active.score or 0) + (choice.score or 0)

    -- P2: 统一 Ethics 记录
    if choice.ethics and ApplyChoiceEthics then
        ApplyChoiceEthics(choice, playerData_.day, (chain.id or "crisis") .. "_d" .. state.active.dayIndex .. "_c" .. choiceIndex)
    end

    -- 记录今天已选择
    state.todayChoice = {
        dayIndex = state.active.dayIndex,
        choiceIndex = choiceIndex,
        result = choice.result,
    }

    if AddLog then
        AddLog(chain.icon .. " 【" .. chain.name .. "】" .. (choice.result or ""))
    end

    return true, choice.result or ""
end

--- 推进到下一天（在EndDay调用）
--- @return table|nil 如果链结束，返回结局信息
function CrisisChain.AdvanceDay()
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    if not state.active then return nil end

    -- 如果今天没做选择，给默认最差分
    if not state.todayChoice or state.todayChoice.dayIndex ~= state.active.dayIndex then
        state.active.score = (state.active.score or 0) - 1
    end

    local chain = CrisisChain.GetChainById(state.active.chainId)
    if not chain then
        state.active = nil
        return nil
    end

    -- 推进天数
    state.active.dayIndex = state.active.dayIndex + 1
    state.todayChoice = nil

    -- 检查是否链结束（超过3天或超过配置天数）
    if state.active.dayIndex > #chain.days then
        return CrisisChain.Resolve(chain)
    end

    return nil
end

--- 结算危机链
function CrisisChain.Resolve(chain)
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    local score = state.active.score or 0

    -- 根据分数决定结局
    local ending = nil
    if score >= chain.endings.good.threshold then
        ending = chain.endings.good
    elseif score >= chain.endings.mid.threshold then
        ending = chain.endings.mid
    else
        ending = chain.endings.bad
    end

    -- 发放奖励/惩罚
    if ending.reward then
        if ending.reward.money then playerData_.money = (playerData_.money or 0) + ending.reward.money end
        if ending.reward.rep then playerData_.reputation = (playerData_.reputation or 0) + ending.reward.rep end
    end
    if ending.penalty then
        if ending.penalty.money then playerData_.money = (playerData_.money or 0) + ending.penalty.money end
        if ending.penalty.rep then playerData_.reputation = (playerData_.reputation or 0) + ending.penalty.rep end
    end
    if ending.specialEffect then
        pcall(ending.specialEffect)
    end

    -- 记录完成
    state.completed[chain.id] = {
        ending = ending.title,
        day = playerData_.day or 1,
        score = score,
    }
    state.lastCrisisEnd = playerData_.day or 1
    state.active = nil

    if AddLog then
        local typeLabel = chain.type == "positive" and "机遇" or "危机"
        AddLog(chain.icon .. " 【" .. typeLabel .. "链结束】" .. chain.name .. " → " .. ending.title .. "：" .. ending.text)
    end

    return { chain = chain, ending = ending, score = score }
end

--- 通过ID查找链配置
function CrisisChain.GetChainById(chainId)
    for _, chain in ipairs(CrisisChain.CHAINS) do
        if chain.id == chainId then return chain end
    end
    return nil
end

--- 获取当前活跃链的进度描述
function CrisisChain.GetProgressDesc()
    CrisisChain.EnsureState()
    local state = playerData_.crisisState
    if not state.active then return nil end

    local chain = CrisisChain.GetChainById(state.active.chainId)
    if not chain then return nil end

    return {
        name = chain.name,
        icon = chain.icon,
        type = chain.type,
        dayIndex = state.active.dayIndex,
        totalDays = #chain.days,
        score = state.active.score,
    }
end

return CrisisChain
