---@diagnostic disable: undefined-global
-- ============================================================================
-- NarrativeLayer.lua: 叙事表达层
-- 将数值/系统语言转化为人话，让经营动作有温度
-- ============================================================================
local M = {}

-- ============================================================================
-- P0-a: UI文案叙事化 — 数值语言改为人话
-- ============================================================================

--- 将收入数字转化为叙事表达（状态栏展开面板用）
---@param income number 日收入
---@param expense number 日支出
---@param traffic number 客流量
---@return string 叙事收入描述
---@return string 叙事支出描述
---@return string 叙事净收入描述
function M.GetNarrativeFinance(income, expense, traffic)
    local net = income - expense
    -- 收入描述：用客人数量和生意感受代替纯数字
    local incText
    if income >= 400 then
        incText = "今天生意火爆，收入$" .. income
    elseif income >= 200 then
        incText = "客人来来往往，入账$" .. income
    elseif income >= 80 then
        incText = "三三两两有人来，赚了$" .. income
    else
        incText = "门可罗雀，只收了$" .. income
    end

    -- 支出描述：强调花钱的去向
    local expText
    if expense >= 200 then
        expText = "电费房租人工，出去$" .. expense
    elseif expense >= 100 then
        expText = "日常开销$" .. expense
    else
        expText = "省着花，只出$" .. expense
    end

    -- 净收入描述：情绪化表达
    local netText
    if net >= 300 then
        netText = "大丰收！净赚$" .. net
    elseif net >= 100 then
        netText = "还行，口袋里多了$" .. net
    elseif net >= 0 then
        netText = "勉强打平，净入$" .. net
    elseif net >= -100 then
        netText = "略亏$" .. math.abs(net) .. "，明天再努力"
    else
        netText = "心在滴血…亏了$" .. math.abs(net)
    end

    return incText, expText, netText
end

--- 将客流数据转为叙事描述（替代 "客流: 72%"）
---@param traffic number 当前客流
---@param capacity number 容量
---@return string 叙事客流描述
function M.GetNarrativeTraffic(traffic, capacity)
    local ratio = capacity > 0 and (traffic / capacity) or 0
    if ratio >= 1.0 then
        return "座无虚席，门口还有人排队"
    elseif ratio >= 0.85 then
        return "快坐满了，" .. traffic .. "人在线"
    elseif ratio >= 0.6 then
        return "还算热闹，来了" .. traffic .. "人"
    elseif ratio >= 0.35 then
        return "有些冷清，只来了" .. traffic .. "人"
    elseif traffic > 0 then
        return "门口冷冷清清，" .. traffic .. "个人撑场面"
    else
        return "空无一人……"
    end
end

--- 天数的叙事表达（替代 "D14"）
---@param day number 当前天数
---@return string 叙事天数
function M.GetNarrativeDay(day)
    if day == 1 then return "开业第一天"
    elseif day <= 3 then return "开业第" .. day .. "天"
    elseif day <= 7 then return "第" .. day .. "天"
    elseif day <= 14 then return "第" .. day .. "天"
    elseif day <= 21 then return "第" .. day .. "天"
    elseif day <= 30 then return "第" .. day .. "天"
    else return "第" .. day .. "天"
    end
end

-- ============================================================================
-- P0-b: NPC行为微变化 — 一句环境描述
-- ============================================================================

-- NPC 日常行为池：根据 NPC 状态 + 随机性，每天选一句
-- key = npc_id, 每个 NPC 有多种状态的行为描述
local NPC_BEHAVIORS = {
    mama_blessing = {
        default = {
            "门口飘来 Mama Blessing 烤鸡的香味，排队的人都咽口水。",
            "Mama Blessing 哼着歌在翻烤鸡，炭火噼啪作响。",
            "Mama Blessing 今天给你留了一个鸡腿，「老板辛苦了」。",
        },
        happy = {
            "Mama Blessing 笑得合不拢嘴，说今天烤鸡卖光了。",
            "Mama B 端着一碗花生汤来串门，「尝尝我新学的」。",
        },
        absent = {
            "今天门口安静了些——Mama Blessing 回老家看儿子去了。",
            "没有烤鸡香味的下午，总觉得少了点什么。",
        },
    },
    kwame = {
        default = {
            "Kwame 又来了，坐在最便宜的1号机，一言不发地练枪。",
            "Kwame 在角落默默打了三局，走的时候跟你点了点头。",
            "1号机的键盘声停了——Kwame 在认真看比赛录像。",
        },
        improved = {
            "Kwame 今天比往常多坐了一小时，眼神比以前亮了些。",
            "Kwame 第一次主动跟新来的顾客搭话，教人怎么跑刀。",
        },
        struggling = {
            "Kwame 今天来得很晚，坐下后很久没动鼠标。",
            "你注意到 Kwame 走的时候数了三遍零钱。",
        },
    },
    xiaoma = {
        default = {
            "小马在擦桌子，嘴里念叨着昨晚看的比赛。",
            "小马帮客人重启了两次电脑，动作比以前麻利了。",
            "小马在门口跟送水的大叔聊天，笑声传进来。",
        },
        growing = {
            "小马今天主动提出帮你对账，虽然算错了两笔。",
            "小马开始学着记住每个常客的名字了。",
        },
        troubled = {
            "小马今天有些心不在焉，抹布在同一块桌子上擦了五分钟。",
            "小马的电话响了好几次，他没接。",
        },
    },
    kofi_jr = {
        default = {
            "Kofi 在后面捣鼓路由器，说信号又可以快一点。",
            "Kofi 教了一个小孩怎么设置输入法，那孩子高兴坏了。",
        },
        creative = {
            "Kofi 偷偷在调音台上接了功放，网吧里飘起了非洲鼓点。",
            "Kofi 给网吧首页做了个新Logo，你觉得还不错。",
        },
    },
    neighbor = {
        default = {
            "隔壁大爷送了几个芒果过来，说是树上刚摘的。",
            "能听到隔壁大爷的收音机在放新闻，世界杯预选赛的消息。",
        },
        grateful = {
            "大爷的孙子跑来说「爷爷让我谢谢你」，然后害羞地跑走了。",
            "隔壁飘来煮花生的香味，大爷在跟老伙计们唠嗑。",
        },
    },
    dragon_dog = {
        default = {
            "Dragon 趴在门口晒太阳，看到熟客会摇尾巴。",
            "Dragon 在3号桌下面睡着了，偶尔抽动一下爪子。",
        },
        playful = {
            "Dragon 叼了根树枝进来，围着你转了三圈才放下。",
            "有个小孩蹲在门口逗 Dragon 玩了半小时。",
        },
    },
}

--- 获取当天的 NPC 环境描述（一句话）
---@return string|nil 环境描述，nil 表示今天没有特别的
function M.GetDailyNPCBehavior()
    -- 需要 playerData_ 和相关全局状态
    if not playerData_ then return nil end

    local day = playerData_.day or 1
    -- 用 day 作为随机种子，确保同一天看到同样的描述
    math.randomseed(day * 137 + 42)

    -- 收集当前活跃的 NPC
    local activeNPCs = {}

    -- 检查 NPC 是否已经遇见过（在 npcJournal_ 中有记录）
    local journal = npcJournal_ or {}
    for npcId, _ in pairs(journal) do
        if NPC_BEHAVIORS[npcId] then
            table.insert(activeNPCs, npcId)
        end
    end

    -- 如果没有遇见任何 NPC，返回通用描述
    if #activeNPCs == 0 then
        local generalLines = {
            "街上传来摩托车的引擎声，又一个平常的早晨。",
            "阳光从铁皮缝隙洒进来，灰尘在光柱里跳舞。",
            "门口有个小孩趴在窗户上往里看，看了一会儿就跑了。",
            "远处传来教堂的钟声，新的一天开始了。",
            "有人在街对面放音乐，节奏感很强的非洲鼓。",
        }
        return generalLines[math.random(1, #generalLines)]
    end

    -- 从活跃 NPC 中选一个
    local chosenId = activeNPCs[math.random(1, #activeNPCs)]
    local behaviors = NPC_BEHAVIORS[chosenId]
    if not behaviors then return nil end

    -- 判断 NPC 当前状态
    local state = "default"

    -- 根据队员心情/技能判断状态
    if teamMembers_ then
        for _, m in ipairs(teamMembers_) do
            if m.id == chosenId or m.name == chosenId then
                if m.mood and m.mood >= 80 then state = "happy"
                elseif m.mood and m.mood <= 30 then state = "troubled"
                elseif m.skill and m.skill >= 60 then state = "improved"
                end
                break
            end
        end
    end

    -- 检查是否有对应状态的描述，没有就用 default
    local pool = behaviors[state] or behaviors.default
    if not pool or #pool == 0 then
        pool = behaviors.default
    end
    if not pool or #pool == 0 then return nil end

    -- 恢复随机种子（避免影响其他系统）
    math.randomseed(os.time())

    -- 根据 day 选择（确定性但看起来随机）
    local idx = ((day * 7 + #activeNPCs * 3) % #pool) + 1
    return pool[idx]
end

-- ============================================================================
-- P1-a: 选择后果可视化 — 延迟反馈系统
-- ============================================================================

-- 后果定义：eventTitle → { delay=天数, consequences={ {condition, text} } }
local DELAYED_CONSEQUENCES = {
    ["老顾客求助"] = {
        delay = 2,
        helped = {
            "Kwame 今天跑刀赢了一把大的，出门时悄悄塞给你一包咖啡豆。",
            "你注意到 Kwame 开始教旁边的新手怎么设置灵敏度了。",
        },
        refused = {
            "Kwame 已经三天没来了。1号机空着，莫名有些安静。",
            "有人说在别的网吧看到了 Kwame，你假装没听见。",
        },
    },
    ["员工偷零钱"] = {
        delay = 3,
        forgave = {
            "小马今天来得特别早，把地拖了两遍。",
            "你发现柜台上多了一包从没见过的茶叶，小马说是他妈让带的。",
        },
        punished = {
            "小马最近干活规规矩矩的，但以前哼的歌不哼了。",
            "新来的帮工干了三天就跑了，你开始想念小马的麻利劲儿。",
        },
    },
    ["中国同胞来访"] = {
        delay = 2,
        welcomed = {
            "包包哥介绍的那批货到了，价格确实比市面便宜不少。",
            "包包哥的朋友圈发了你网吧的照片，配文「兄弟的店，来了必去」。",
        },
    },
    ["学校合作邀请"] = {
        delay = 4,
        accepted = {
            "放学后涌进来一群学生，叽叽喳喳的，网吧热闹了不少。",
            "校长带着一面锦旗来了——「助学先锋」，虽然土但心里暖。",
        },
        refused = {
            "路过学校时，门卫多看了你两眼。也许只是巧合。",
        },
    },
    ["流浪狗收养"] = {
        delay = 1,
        adopted = {
            "Dragon 已经认识路了，每天准时在门口等开门。",
            "几个小孩专门来看 Dragon，顺便在网吧充了10块钱。",
        },
    },
    ["邻居送水果"] = {
        delay = 2,
        kind = {
            "隔壁大爷主动帮你看了会儿店，说「去吃口饭，我盯着」。",
            "大爷跟街坊们说「那个中国小伙子人不错」，你假装没听见但嘴角翘了。",
        },
    },
}

--- 记录玩家选择（在事件结算时调用）
---@param eventTitle string 事件标题
---@param choiceKey string 选择标识（如 "helped", "refused", "forgave" 等）
function M.RecordChoice(eventTitle, choiceKey)
    if not playerData_ then return end
    if not playerData_.narrativeChoices then
        playerData_.narrativeChoices = {}
    end
    table.insert(playerData_.narrativeChoices, {
        event = eventTitle,
        choice = choiceKey,
        day = playerData_.day,
    })
end

--- 检查今天是否有延迟后果需要展示
---@return string|nil 后果描述文本
function M.GetDelayedConsequence()
    if not playerData_ or not playerData_.narrativeChoices then return nil end
    local today = playerData_.day or 1

    for i, record in ipairs(playerData_.narrativeChoices) do
        local def = DELAYED_CONSEQUENCES[record.event]
        if def and (today - record.day) == def.delay then
            -- 找到匹配的后果
            local pool = def[record.choice]
            if pool and #pool > 0 then
                -- 标记已展示（避免重复）
                if not record.shown then
                    record.shown = true
                    local idx = ((today * 13 + i * 7) % #pool) + 1
                    return pool[idx]
                end
            end
        end
    end
    return nil
end

-- ============================================================================
-- P1-b: 经营动作叙事化 — 升级关联角色
-- ============================================================================

-- 升级动作的叙事包装：key → { 角色视角描述, 升级理由 }
local UPGRADE_NARRATIVES = {
    computer = {
        { who = "队员们", lines = {
            "给兄弟们换台能跑得动的机器",
            "队员总说电脑卡，该换了",
            "再不升级，他们要去隔壁网吧练了",
        }},
        reason = "你看到 Kwame 对着加载画面叹气的样子",
    },
    chair = {
        { who = "常客", lines = {
            "屁股都坐麻了，总得让人坐舒服点",
            "上次有人坐断了凳子腿，赔了面子",
        }},
        reason = "包夜的学生早上起来揉着腰走的",
    },
    net = {
        { who = "队员们", lines = {
            "200ms延迟跑个锤子刀",
            "Kwame 说每次卡一下就想砸键盘",
        }},
        reason = "队员比赛时集体断线，差点被淘汰",
    },
    ac = {
        { who = "所有人", lines = {
            "40度高温，键盘都是湿的",
            "装个空调，大家别中暑了",
        }},
        reason = "昨天有个客人热得流鼻血",
    },
    solar = {
        { who = "Mama Blessing", lines = {
            "停电时 Mama B 的冰柜化了一地水",
            "至少让烤鸡摊的冰箱有电",
        }},
        reason = "上次停电，Mama B 心疼化掉的鸡肉心疼了一晚上",
    },
    food = {
        { who = "Mama Blessing", lines = {
            "让 Mama B 的摊子升级一下",
            "客人总问有没有冰汽水",
        }},
        reason = "Mama Blessing 嘟囔说炭火烤鸡配上冰可乐才完美",
    },
    generator = {
        { who = "所有人", lines = {
            "停电不能再靠蜡烛了",
            "发电机虽然吵，但总比黑灯瞎火强",
        }},
        reason = "上次停电三小时，跑到一半的单全没了",
    },
    well = {
        { who = "街坊邻居", lines = {
            "村里的孩子每天走两公里挑水",
            "有口井，整条街都受益",
        }},
        reason = "隔壁大爷说他小时候这里是有井的",
    },
    road = {
        { who = "街坊邻居", lines = {
            "雨天泥巴路没人愿意出门",
            "把门前这段路修了吧",
        }},
        reason = "昨天有个骑摩托的在门口摔了",
    },
    coffee = {
        { who = "Kofi", lines = {
            "Kofi 说他会做手冲，缺个吧台",
            "给 Kofi 一个发挥的舞台",
        }},
        reason = "Kofi 用纸杯泡的速溶咖啡，客人竟然说好喝",
    },
    jukebox = {
        { who = "所有人", lines = {
            "音乐是这里的灵魂，不能少",
            "客人说太安静了，放点音乐呗",
        }},
        reason = "有天隔壁放了首 Afrobeats，全网吧的人头都在点",
    },
    deco = {
        { who = "你自己", lines = {
            "铁皮墙也该有点样子了",
            "让这里看起来不只是个「网吧」",
        }},
        reason = "一个博主来拍视频说「这里有点寒酸」，虽然他后来删了",
    },
    security = {
        { who = "Mama Blessing", lines = {
            "Mama B 说上周有人摸了她的收钱罐",
            "请个靠谱的人看着，大家安心",
        }},
        reason = "半夜有人试图撬门，幸好没得逞",
    },
}

--- 获取升级的叙事名称（替代系统默认名）
---@param key string 升级key
---@return string|nil 叙事化名称，nil 表示用默认
function M.GetNarrativeUpgradeName(key)
    local narr = UPGRADE_NARRATIVES[key]
    if not narr or not narr[1] then return nil end
    local pool = narr[1].lines
    if not pool or #pool == 0 then return nil end
    -- 用当前天数选择，保证同一天看到同样的
    local day = (playerData_ and playerData_.day) or 1
    local idx = ((day * 11 + #key) % #pool) + 1
    return pool[idx]
end

--- 获取升级的叙事理由（显示在描述区域）
---@param key string 升级key
---@return string|nil 叙事化理由
function M.GetNarrativeUpgradeReason(key)
    local narr = UPGRADE_NARRATIVES[key]
    if narr then return narr.reason end
    return nil
end

--- 获取升级关联的角色
---@param key string 升级key
---@return string|nil 角色名
function M.GetUpgradeRelatedNPC(key)
    local narr = UPGRADE_NARRATIVES[key]
    if narr and narr[1] then return narr[1].who end
    return nil
end

return M
