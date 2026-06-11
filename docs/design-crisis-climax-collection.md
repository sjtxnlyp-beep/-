# 三合一玩法叠加方案：危机链 + 高潮日 + 图鉴系统

> 版本: v1.0  
> 目标: 解决 Day30+ 节奏平淡 + 缺乏长期收集目标

---

## 总体设计原则

1. **复用现有框架** — 不创建新的游戏阶段(Phase)，复用 PHASE_EVENT + choice 事件格式
2. **与现有系统联动** — 危机链触发图鉴解锁，高潮日提供图鉴碎片奖励
3. **渐进开放** — Day 12 开启高潮日，Day 15 开启危机链，Day 1 开始积累图鉴
4. **零打断** — 所有新内容嵌入现有 EndDay 流程，不改变核心 AP 循环

---

## 系统一：危机链 (CrisisChain)

### 概念

每隔 7-10 天，有概率触发一条**多天连锁事件链**（3-5天跨度）。  
不是单独的随机事件，而是有因果关系的**剧情弧线**——第1天出现征兆，第2天升级，第3天决战。  
每条链有**分支结局**（2-3种），取决于玩家在过程中的选择累计。

### 数据结构

```lua
-- CrisisChain.lua
CrisisChain.CHAINS = {
    {
        id = "power_war",
        title = "电力战争",
        icon = "⚡",
        minDay = 15,                          -- 最早触发天
        cooldownDays = 8,                     -- 同一链冷却天数
        triggerChance = 0.35,                 -- 每次检查触发概率
        triggerCond = function()              -- 额外触发条件
            return (playerData_.generatorLevel or 0) >= 1
        end,
        
        -- 阶段列表（按天推进）
        stages = {
            -- Day 1: 征兆
            {
                dayOffset = 0,                -- 相对触发日的偏移
                type = "choice",
                title = "⚡ 电网通知",
                desc = "市政府发来通知：本区域将进行电网改造，未来3天可能频繁断电。你需要提前准备。",
                choices = {
                    { text = "🛢️ 囤积燃油（-$80）",
                      cond = function() return playerData_.money >= 80 end,
                      effect = function() playerData_.money = playerData_.money - 80 end,
                      result = "花$80买了5桶备用燃油。",
                      chainFlag = "fuel_stocked",     -- 写入链状态
                    },
                    { text = "📢 联合邻居抗议",
                      effect = function() playerData_.reputation = playerData_.reputation + 5 end,
                      result = "声望+5，但抗议没什么用…",
                      chainFlag = "protested",
                    },
                    { text = "😤 无视通知",
                      effect = function() end,
                      result = "你决定赌一把。",
                      chainFlag = "ignored",
                    },
                },
            },
            -- Day 2: 升级
            {
                dayOffset = 1,
                type = "auto_narrative",      -- 自动推进叙事，无选择
                title = "⚡ 第一次断电",
                getDesc = function(flags)
                    if flags.fuel_stocked then
                        return "断电了！但你提前囤了燃油，发电机轰鸣启动。隔壁的网吧一片漆黑，客人都涌向你这边。💰+$60"
                    elseif flags.protested then
                        return "断电了！抗议没用。市政不理你。今天损失了大半收入。💸-$40"
                    else
                        return "断电了！你什么都没准备，整个下午停业。💸-$60"
                    end
                end,
                effect = function(flags)
                    if flags.fuel_stocked then
                        playerData_.money = playerData_.money + 60
                    elseif flags.protested then
                        playerData_.money = playerData_.money - 40
                    else
                        playerData_.money = playerData_.money - 60
                    end
                end,
            },
            -- Day 3: 决战
            {
                dayOffset = 2,
                type = "choice",
                title = "⚡ 电力黑市",
                getDesc = function(flags)
                    return "一个自称'电力掮客'的人找上门，说能帮你接通私人电缆，永久免受停电影响。但这是违法的…"
                end,
                choices = {
                    { text = "🤝 接受（-$200，永久防停电）",
                      cond = function() return playerData_.money >= 200 end,
                      effect = function()
                          playerData_.money = playerData_.money - 200
                          playerData_.crisisPerks = playerData_.crisisPerks or {}
                          playerData_.crisisPerks.blackout_immune = true
                      end,
                      result = "你接了私线。以后再也不怕停电了… 但心里总有点不安。",
                      chainFlag = "accepted_illegal",
                      karmaEffect = -2,
                    },
                    { text = "❌ 拒绝（正道光明）",
                      effect = function()
                          playerData_.karma = (playerData_.karma or 0) + 3
                          playerData_.reputation = playerData_.reputation + 10
                      end,
                      result = "你拒绝了。邻居们看到你的正直，声望大涨！声望+10，道义+3",
                      chainFlag = "refused_noble",
                    },
                },
            },
        },
        
        -- 链完成后的总结
        resolution = function(flags)
            local summary = "「电力战争」落幕。"
            if flags.accepted_illegal then
                summary = summary .. "你选择了灰色地带，但换来了安稳。"
            else
                summary = summary .. "你坚守正道，赢得了尊重。"
            end
            return summary
        end,
        
        -- 图鉴奖励（完成后解锁）
        collectionReward = { category = "event", id = "power_war_complete" },
    },
}
```

### 触发机制

```lua
-- 在 EndDay 流程的 step 33-34 之间插入
function CrisisChain.OnEndDay()
    local pd = playerData_
    pd.crisisState = pd.crisisState or {}
    
    -- 如果当前有活跃的链，推进阶段
    if pd.crisisState.active then
        local chain = CrisisChain.GetChainById(pd.crisisState.activeId)
        local dayInChain = pd.day - pd.crisisState.startDay
        local nextStage = CrisisChain.GetStageForDay(chain, dayInChain)
        if nextStage then
            pd.crisisState.pendingStage = nextStage  -- 下次 BuildUI 时展示
        elseif dayInChain > #chain.stages then
            -- 链结束
            CrisisChain.ResolveChain(chain, pd.crisisState.flags)
            pd.crisisState.active = false
            pd.crisisState.lastChainDay = pd.day
        end
        return  -- 活跃链期间不触发新链
    end
    
    -- 检查是否可以触发新链
    local daysSinceLast = pd.day - (pd.crisisState.lastChainDay or 0)
    if daysSinceLast < 7 then return end
    if pd.day < 15 then return end
    
    -- 从候选池中选择
    local candidates = {}
    for _, chain in ipairs(CrisisChain.CHAINS) do
        if pd.day >= chain.minDay
           and (not pd.crisisState.completed or not pd.crisisState.completed[chain.id])
           and (not chain.triggerCond or chain.triggerCond())
           and math.random() < chain.triggerChance then
            table.insert(candidates, chain)
        end
    end
    
    if #candidates > 0 then
        local pick = candidates[math.random(#candidates)]
        pd.crisisState.active = true
        pd.crisisState.activeId = pick.id
        pd.crisisState.startDay = pd.day
        pd.crisisState.flags = {}
        pd.crisisState.pendingStage = pick.stages[1]
    end
end
```

### 危机链内容表（6条链）

| ID | 标题 | 最早天 | 跨度 | 核心冲突 |
|----|------|--------|------|---------|
| `power_war` | ⚡ 电力战争 | Day 15 | 3天 | 电网改造引发停电危机，选择合法还是走灰色地带 |
| `rival_raid` | 🦊 Victor的报复 | Day 20 | 4天 | Victor派人砸场→员工受伤→选择报警/找Snake/单干反击 |
| `health_scare` | 🏥 疫情风波 | Day 18 | 3天 | 卫生局检查→客人减少→需要投资改造或找关系 |
| `gold_crash` | 📉 金价暴跌 | Day 25 | 3天 | 黄金暴跌→债主逼债→选择抛售/死扛/转投其他 |
| `team_mutiny` | 💔 队员哗变 | Day 22 | 4天 | 核心队员闹矛盾→分裂成两派→调解/站队/大换血 |
| `government_audit` | 📋 政府审计 | Day 30 | 5天 | 税务稽查→发现漏洞→补缴/行贿/法律诉讼 |

### 状态存储

```lua
playerData_.crisisState = {
    active = false,               -- 是否有活跃链
    activeId = "power_war",       -- 当前链ID
    startDay = 15,                -- 链开始天
    flags = {},                   -- 当前链的选择标记
    pendingStage = nil,           -- 待展示的阶段（下次BuildUI触发）
    lastChainDay = 0,             -- 上次链结束天
    completed = {},               -- 已完成链 { [id] = true }
    crisisPerks = {},             -- 永久效果 { blackout_immune = true }
}
```

---

## 系统二：高潮日 (ClimaxDay)

### 概念

每 5-7 天出现一个**规则变异日**。这一天的基本规则被修改（AP、花费、收益倍率等），  
带来独特的挑战+机遇。玩家需要**临时调整策略**来适应。  
高潮日有预告（前一天在"明日预览"中显示），给玩家准备时间。

### 数据结构

```lua
-- ClimaxDay.lua
ClimaxDay.EVENTS = {
    {
        id = "esports_weekend",
        title = "🎮 电竞周末",
        icon = "🎮",
        desc = "全城电竞热潮！客流翻倍，但所有比赛对手也变强了。",
        preview = "明天是电竞周末！准备好迎接客流高峰吧！",
        
        -- 规则修改器
        modifiers = {
            apBonus = 1,              -- +1 AP (4 instead of 3)
            incomeMulti = 2.0,        -- 收入x2
            matchDifficultyBonus = 15, -- 对手强度+15
            trafficMulti = 2.0,       -- 客流x2
        },
        
        -- 特殊机制（该日独有的额外选项）
        specialAction = {
            text = "🏆 举办街头锦标赛（免费，仅限今日）",
            desc = "不消耗AP，但需要3+队员",
            cond = function() return #teamMembers_ >= 3 end,
            effect = function()
                local bonus = math.random(100, 250)
                playerData_.money = playerData_.money + bonus
                playerData_.reputation = playerData_.reputation + 15
                return "锦标赛大成功！💰+" .. bonus .. " 声望+15"
            end,
        },
        
        -- 当日结束奖励
        dayEndBonus = function()
            return { money = 50, desc = "电竞周末加成结算 +$50" }
        end,
        
        -- 触发条件
        minDay = 12,
        weight = 20,                  -- 选择权重
        cooldown = 6,                 -- 距上次同类型最少间隔天数
        
        -- 图鉴碎片奖励
        collectionReward = { category = "moment", id = "esports_weekend_survived" },
    },
    -- ...更多高潮日
}
```

### 高潮日类型表（8种）

| ID | 标题 | AP变化 | 核心修改 | 策略点 |
|----|------|--------|---------|--------|
| `esports_weekend` | 🎮 电竞周末 | +1 | 收入×2，对手变强 | 打不打比赛？客流爆满时做升级还是多比赛？ |
| `blackout_day` | 🌑 全城停电 | 不变 | 收入→0（除非有发电机），升级费-50% | 趁便宜囤升级？还是躺平？ |
| `inspector_visit` | 👔 市长视察 | -1 | 声望收益×3，但任何负面事件后果×2 | 高风险高回报日，小心行事 |
| `festival_day` | 🎉 本地节日 | +2 | 所有花费+50%，但市场出稀有物品 | 钱多的可以抓机会，钱少的控制消费 |
| `hacker_attack` | 💀 黑客攻击 | 不变 | 每次操作有20%丢失进度，但破解后奖励巨大 | 要不要冒险操作？还是只做稳妥的事？ |
| `double_or_nothing` | 🎲 幸运日 | 不变 | 所有收益50%概率×2或×0 | 赌徒日，做多少事取决于风险偏好 |
| `talent_scout` | 🔍 球探来访 | 不变 | 训练收益×3，但最强队员可能被挖走 | 练不练？风险是失去核心队员 |
| `tax_holiday` | 🏛️ 免税日 | +1 | 无任何支出，净收入=毛收入 | 纯盈利日，做什么都赚 |

### 触发机制

```lua
function ClimaxDay.CheckAndSchedule()
    local pd = playerData_
    pd.climaxState = pd.climaxState or { lastClimaxDay = 0, history = {} }
    
    -- 高潮日只在 EndDay 中预设「明天是否为高潮日」
    local daysSinceLast = pd.day - pd.climaxState.lastClimaxDay
    if daysSinceLast < 5 then return end
    if pd.day < 12 then return end
    
    -- 5-7天窗口内，概率递增：第5天25%，第6天50%，第7天100%
    local chance = (daysSinceLast - 4) * 0.25
    if math.random() > chance then return end
    
    -- 加权随机选择（排除冷却中的）
    local pool = {}
    for _, evt in ipairs(ClimaxDay.EVENTS) do
        if pd.day >= evt.minDay then
            local lastUse = pd.climaxState.history[evt.id] or 0
            if (pd.day - lastUse) >= evt.cooldown then
                for i = 1, evt.weight do pool[#pool + 1] = evt end
            end
        end
    end
    if #pool == 0 then return end
    
    local pick = pool[math.random(#pool)]
    pd.climaxState.tomorrowClimax = pick.id  -- 预设明天
end

-- 在新一天开始时应用修改器
function ClimaxDay.ApplyIfActive()
    local pd = playerData_
    if not pd.climaxState or not pd.climaxState.tomorrowClimax then return nil end
    
    local id = pd.climaxState.tomorrowClimax
    pd.climaxState.tomorrowClimax = nil
    pd.climaxState.todayClimax = id
    pd.climaxState.lastClimaxDay = pd.day
    pd.climaxState.history[id] = pd.day
    
    return ClimaxDay.GetById(id)  -- 返回事件数据供UI展示
end
```

### 与 EndDay 的集成点

```
EndDay 流程:
  ...
  step 41: Retention.GenerateTomorrowPreview()  
  step 41.5: ClimaxDay.CheckAndSchedule()  ← 新增：决定明天是否为高潮日
  ...

StartDay 流程 (BuildUI/manage phase):
  ClimaxDay.ApplyIfActive()  ← 检查今天是否为高潮日，应用修改器
  → 修改 AP 上限
  → 修改收入倍率（传给 CalcDailyIncome 作为参数）
  → UI 顶部显示高潮日横幅
```

### 预告集成

```lua
-- 在 GenerateTomorrowPreview 之后追加
if playerData_.climaxState and playerData_.climaxState.tomorrowClimax then
    local evt = ClimaxDay.GetById(playerData_.climaxState.tomorrowClimax)
    pendingTomorrowPreview_.climaxWarning = {
        icon = evt.icon,
        title = evt.title,
        preview = evt.preview,
    }
end
```

### 状态存储

```lua
playerData_.climaxState = {
    lastClimaxDay = 0,            -- 上次高潮日
    todayClimax = nil,            -- 今天的高潮日ID（当天生效）
    tomorrowClimax = nil,         -- 明天预定的高潮日ID（预告用）
    history = {},                 -- { [id] = lastDay } 冷却追踪
    specialActionUsed = false,    -- 今天的特殊行动是否已使用
}
```

---

## 系统三：图鉴系统 (Collection)

### 概念

一个**全局收集进度追踪器**——记录玩家经历过的所有人、事、物。  
分6个类别，每个类别有阶段性完成奖励。  
图鉴本身不改变游戏流程，只是**被动记录 + 展示 + 奖励达成率**。

### 数据结构

```lua
-- Collection.lua
Collection.CATEGORIES = {
    { id = "characters", name = "角色图鉴", icon = "👤", desc = "遇见的所有NPC和队员" },
    { id = "events",     name = "事件图鉴", icon = "📖", desc = "经历过的事件和危机" },
    { id = "equipment",  name = "装备图鉴", icon = "🎮", desc = "获得过的所有装备" },
    { id = "moments",    name = "高光时刻", icon = "⭐", desc = "特殊成就和难忘瞬间" },
    { id = "lore",       name = "非洲百科", icon = "🌍", desc = "解锁的文化知识和民俗" },
    { id = "cafe",       name = "网吧变迁", icon = "🏠", desc = "网吧的每个发展阶段" },
}

Collection.ITEMS = {
    -- ═══ 角色图鉴 ═══
    { id = "chr_kofi",      category = "characters", name = "Kofi·闪电骑手",
      icon = "⚡", desc = "梦想成为职业选手的少年", stars = 1,
      check = function() return HasTeamMember("Kofi") end },
    { id = "chr_kofi_s3",   category = "characters", name = "Kofi·觉醒",
      icon = "🔥", desc = "Kofi完成第三阶段故事", stars = 3,
      check = function()
          return npcJournal_["kofi_jr"] and #(npcJournal_["kofi_jr"].events or {}) >= 3
      end },
    -- ... 每个角色 2-3 条（基础/进阶/传说）
    
    -- ═══ 事件图鉴 ═══
    { id = "evt_first_blackout",  category = "events", name = "第一次停电",
      icon = "🌑", desc = "经历了人生第一次网吧停电", stars = 1,
      check = function() return (playerData_.blackoutCount or 0) >= 1 end },
    { id = "evt_power_war",       category = "events", name = "电力战争",
      icon = "⚡", desc = "完整经历了电力战争危机链", stars = 3,
      check = function()
          return playerData_.crisisState and playerData_.crisisState.completed
             and playerData_.crisisState.completed["power_war"]
      end },
    { id = "evt_coup_survived",   category = "events", name = "政变幸存者",
      icon = "🏴", desc = "在政变期间坚持营业", stars = 2,
      check = function() return playerData_.coupSurvived end },
    
    -- ═══ 装备图鉴 ═══
    { id = "eqp_first_5star",  category = "equipment", name = "天命之人",
      icon = "🌟", desc = "获得第一件五星装备", stars = 3,
      check = function()
          return playerData_.marketInventory and HasItemOfTier(5)
      end },
    { id = "eqp_full_set",     category = "equipment", name = "满配勇士",
      icon = "💎", desc = "三个装备槽全部装满", stars = 2,
      check = function() return CountEquipped() >= 3 end },
    
    -- ═══ 高光时刻 ═══
    { id = "mom_first_win",      category = "moments", name = "初战告捷",
      icon = "🏆", desc = "赢得第一场正式比赛", stars = 1,
      check = function() return (playerData_.matchWins or 0) >= 1 end },
    { id = "mom_comeback_king",  category = "moments", name = "逆转之王",
      icon = "👑", desc = "在money<$100时单日赚回$500+", stars = 3,
      check = function() return playerData_.comebackKing end },
    { id = "mom_climax_master",  category = "moments", name = "高潮日大师",
      icon = "🎯", desc = "成功通过5个不同的高潮日", stars = 3,
      check = function()
          local h = playerData_.climaxState and playerData_.climaxState.history or {}
          local count = 0
          for _ in pairs(h) do count = count + 1 end
          return count >= 5
      end },
    { id = "mom_crisis_veteran", category = "moments", name = "危机老手",
      icon = "🛡️", desc = "完成3条不同的危机链", stars = 3,
      check = function()
          local c = playerData_.crisisState and playerData_.crisisState.completed or {}
          local count = 0
          for _ in pairs(c) do count = count + 1 end
          return count >= 3
      end },
    
    -- ═══ 非洲百科 ═══
    { id = "lore_suya",    category = "lore", name = "Suya烤肉",
      icon = "🍖", desc = "了解了Suya烤肉的豪萨族起源", stars = 1,
      check = function() return playerData_.loreUnlocked and playerData_.loreUnlocked["suya_culture"] end },
    { id = "lore_twi",     category = "lore", name = "特维语谚语",
      icon = "📜", desc = "学到了Twi语的智慧", stars = 1,
      check = function() return playerData_.loreUnlocked and playerData_.loreUnlocked["twi_proverb"] end },
    -- ... 更多来自 ComboEvents 的 lore
    
    -- ═══ 网吧变迁 ═══
    { id = "cafe_first_pc",    category = "cafe", name = "第一台电脑",
      icon = "💻", desc = "你的网吧有了第一台电脑", stars = 1,
      check = function() return true end },  -- 初始就解锁
    { id = "cafe_10pc",        category = "cafe", name = "十台连坐",
      icon = "🖥️", desc = "网吧扩展到10台电脑", stars = 2,
      check = function() return (playerData_.computers or 1) >= 10 end },
    { id = "cafe_branch",      category = "cafe", name = "连锁启航",
      icon = "🏪", desc = "开出第一家分店", stars = 2,
      check = function() return playerData_.branches and #playerData_.branches >= 1 end },
    { id = "cafe_prestige",    category = "cafe", name = "涅槃重生",
      icon = "🔄", desc = "完成第一次转生", stars = 3,
      check = function() return (playerData_.prestigeCount or 0) >= 1 end },
}
```

### 阶段性奖励（每个类别独立）

```lua
Collection.TIER_REWARDS = {
    -- 每个类别按完成比例给奖励
    { pct = 0.25, reward = { havocCoins = 50 },  title = "初见" },
    { pct = 0.50, reward = { havocCoins = 100, money = 200 }, title = "探索者" },
    { pct = 0.75, reward = { havocCoins = 200, money = 500 }, title = "收藏家" },
    { pct = 1.00, reward = { havocCoins = 500, money = 1000, specialFrame = true }, title = "完美图鉴" },
}
```

### 检查逻辑

```lua
function Collection.CheckAndUnlock()
    playerData_.collection = playerData_.collection or {}
    playerData_.collectionTiers = playerData_.collectionTiers or {}
    local newlyUnlocked = {}
    
    for _, item in ipairs(Collection.ITEMS) do
        if not playerData_.collection[item.id] then
            local ok, result = pcall(item.check)
            if ok and result then
                playerData_.collection[item.id] = playerData_.day
                table.insert(newlyUnlocked, item)
            end
        end
    end
    
    -- 检查阶段奖励
    local tierRewards = {}
    for _, cat in ipairs(Collection.CATEGORIES) do
        local total = Collection.CountByCategory(cat.id)
        local unlocked = Collection.CountUnlockedByCategory(cat.id)
        local pct = unlocked / math.max(1, total)
        
        for _, tier in ipairs(Collection.TIER_REWARDS) do
            local tierId = cat.id .. "_" .. tostring(math.floor(tier.pct * 100))
            if pct >= tier.pct and not playerData_.collectionTiers[tierId] then
                playerData_.collectionTiers[tierId] = playerData_.day
                -- 推入邮箱
                table.insert(playerData_.mailbox, {
                    id = "col_" .. tierId, type = "collection_tier",
                    reward = tier.reward, claimed = false, time = playerData_.day,
                    desc = cat.name .. " — " .. tier.title,
                })
                table.insert(tierRewards, { cat = cat, tier = tier })
            end
        end
    end
    
    return newlyUnlocked, tierRewards
end
```

### 集成点

```
EndDay 流程:
  step 40: Achievements.CheckAndUnlock()
  step 40.5: Collection.CheckAndUnlock()  ← 新增
```

### UI 设计（图鉴页面）

```
┌─────────────────────────────────────┐
│  📚 图鉴  [42/96 已解锁]  ★★★☆☆   │
├─────────────────────────────────────┤
│                                     │
│  👤 角色  [8/14]  ████████░░░  57%  │
│  📖 事件  [12/20] ██████░░░░░  60%  │
│  🎮 装备  [6/18]  ███░░░░░░░░  33%  │
│  ⭐ 高光  [5/16]  ███░░░░░░░░  31%  │
│  🌍 百科  [7/15]  █████░░░░░░  47%  │
│  🏠 变迁  [4/13]  ███░░░░░░░░  31%  │
│                                     │
├─────────────────────────────────────┤
│  最近解锁:                           │
│  ⚡ Kofi·觉醒 ★★★         Day 25   │
│  🌑 第一次停电 ★           Day 18   │
│  🏆 初战告捷 ★             Day 12   │
└─────────────────────────────────────┘

点击类别 → 展开该类别所有条目:
┌─────────────────────────────────────┐
│  👤 角色图鉴  [8/14]               │
├─────────────────────────────────────┤
│  ⚡ Kofi·闪电骑手  ★    ✅ Day 3   │
│  🔥 Kofi·觉醒      ★★★  ✅ Day 25  │
│  🐍 Snake·毒蛇     ★    ✅ Day 8   │
│  ❓ ???            ★★★   🔒 未解锁  │
│  💪 Big Joe·巨人   ★    ✅ Day 12  │
│  ❓ ???            ★★    🔒 未解锁  │
└─────────────────────────────────────┘
```

### 状态存储

```lua
playerData_.collection = {
    ["chr_kofi"] = 3,             -- 解锁日
    ["evt_first_blackout"] = 18,
    -- ...
}
playerData_.collectionTiers = {
    ["characters_25"] = 12,       -- 角色图鉴25%奖励已领
    -- ...
}
```

---

## 三系统联动

### 联动点1：危机链 → 图鉴

完成一条危机链时，自动解锁对应的事件图鉴条目。  
不同选择路线可能解锁不同的"高光时刻"条目（正道/灰道两条隐藏条目）。

### 联动点2：高潮日 → 图鉴

每经历一种新的高潮日，解锁对应的"高光时刻"条目。  
高潮日的特殊行动成功后，额外解锁稀有条目。

### 联动点3：高潮日 × 危机链

如果危机链的某个阶段恰好落在高潮日，效果叠加。  
例如："电力战争Day2"碰上"全城停电日"→ 断电损失翻倍，但成功克服后奖励也翻倍。

### 联动点4：图鉴 → 游戏加成

图鉴完成度提供微小的永久被动加成（不影响平衡，纯粹锦上添花）:

| 总完成度 | 加成 |
|---------|------|
| 25% | 每日免费小游戏 +1 次 |
| 50% | 声望收益 +5% |
| 75% | 训练收益 +5% |
| 100% | 解锁专属称号"非洲传奇收藏家" |

---

## 文件结构

```
scripts/
├── CrisisChain.lua          -- 危机链数据 + 逻辑（~300行）
├── ClimaxDay.lua             -- 高潮日数据 + 逻辑（~250行）
├── Collection.lua            -- 图鉴数据 + 检查逻辑（~400行）
├── UICollection.lua          -- 图鉴UI页面（~200行）
└── (修改) GL_EndDay.lua      -- 插入3个钩子调用
    (修改) UIScreens.lua      -- 主菜单加"图鉴"入口
    (修改) UICafe.lua          -- 高潮日横幅展示
    (修改) GameState.lua       -- 新增状态字段声明
```

---

## 实施步骤

1. **Collection.lua** — 最独立，只依赖 playerData_ 读取，可以先做
2. **UICollection.lua** — 图鉴展示页面
3. **ClimaxDay.lua** — 依赖 EndDay 钩子，需要修改 GL_EndDay
4. **CrisisChain.lua** — 最复杂，依赖 PHASE_EVENT 展示，需要修改事件展示逻辑
5. **集成** — GL_EndDay 加钩子，UIScreens 加入口，测试联动

---

## 数据量估算

| 系统 | 内容条目数 | 代码行数 |
|------|-----------|---------|
| 危机链 | 6条链 × 3-5阶段 = 约24个事件节点 | ~400行 |
| 高潮日 | 8种类型 | ~300行 |
| 图鉴 | ~96条目（6类别 × 16条平均） | ~500行（含UI） |
| 集成修改 | 4个文件小改 | ~50行 |
| **合计** | | **~1250行新代码** |
