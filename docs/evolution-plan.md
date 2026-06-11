# 《非洲网吧大亨》游戏进化开展方案

> 版本: v1.0 | 日期: 2026-06-02
> 状态: 待评审 → 执行

---

## 总纲

基于专家+玩家圆桌讨论共识，确定进化原则：

**核心定位不变**：温暖的非洲单机经营叙事游戏
**进化方向**：做深已有内容（填充中期空白、增强情感连接、可视化长期目标）
**明确不做**：赛季重置、重度社交互访、对抗排行榜、独立新模式

---

## 第一梯队：立即执行（预计 1-2 周）

### 1.1 非洲地图 + 帝国进度可视化

**目标**：给玩家一个"终极画面"——非洲大陆地图上亮起已征服的城市

**规格**：
- 一张非洲中心投影的大陆地图（NanoVG 矢量绘制或像素图）
- 7 个城市标记点（Wakandaville + 6 个解锁城市）
- 状态显示：
  - 已征服：亮起 + 城市名 + 一句话成就（"全城最火的网吧！"）
  - 当前所在：脉冲动画 + 当前数据摘要
  - 未解锁：灰暗 + "需要商会名誉 XXX" + 锁图标
  - 未踏足：暗影轮廓 + "???"
- 解锁新城市时播放 3 秒点亮动画 + 旁白文本
- 底部统计栏：总营收 / 总比赛胜场 / 培养选手数 / 经营天数
- **入口位置**：主界面增加"帝国版图"按钮（AP 用完后也可访问）

**实现要点**：
```
新文件: scripts/UIMapView.lua
依赖: PrestigeSystem.CITIES (已有城市数据)
UI: 使用 urhox-libs/UI 面板 + NanoVG 绘制地图
数据: 读取 playerData_.currentCity, playerData_.prestigeHonor, playerData_.conqueredCities
```

**验收标准**：
- [ ] 7 个城市在地图上位置正确（参考真实非洲地理）
- [ ] 当前城市有动画效果
- [ ] 解锁瞬间有反馈动画
- [ ] AP 耗尽状态下可自由进入查看

---

### 1.2 明日预告改写 — 悬念式叙事钩子

**目标**：将 D8-D30+ 的明日预告从"信息播报"升级为"悬念式故事钩子"

**现状分析**：
- `Retention.GenerateTomorrowPreview(day)` 已有 D1-D14 的 `NARRATIVE_HOOKS`（做得很好）
- 问题在 D15+ 缺少叙事钩子，退化为纯数据预告（"明天天气晴，收入正常"）

**改动方案**：

在 `Retention.lua` 的 `GenerateTomorrowPreview` 中扩展：

```lua
-- 新增: D15-D30 悬念池（基于当前状态动态选取）
local SUSPENSE_POOL_MID = {
    { cond = function() return playerData_.reputation >= 50 end,
      scene = "打烊后，一个穿西装的人在门口等你。他递来一张名片——'非洲电竞联盟'。",
      hook = "明天，他会带来什么提议？", icon = "🤝", urgency = "high" },
    { cond = function() return #teamMembers_ >= 3 end,
      scene = "训练结束，队员们凑在一起窃窃私语，看到你来了又散开。",
      hook = "他们在策划什么？明天就知道了。", icon = "🤫", urgency = "mid" },
    { cond = function() return (playerData_.goldOunces or 0) > 5 end,
      scene = "金价今晚暴涨了15%。门口换钱的阿叔脸色很奇怪。",
      hook = "他是想提醒你什么，还是另有企图？", icon = "📈", urgency = "mid" },
    -- ... 扩展 15-20 条
}

-- 新增: D30+ 悬念池（城市扩张阶段）
local SUSPENSE_POOL_LATE = {
    { cond = function() return playerData_.prestigeHonor >= 80 end,
      scene = "今晚你做了个梦——站在一座更大的城市的天台上，看着霓虹灯海。",
      hook = "也许……是时候去更远的地方了？", icon = "🌆", urgency = "high" },
    -- ... 扩展 10-15 条
}
```

**补充规则**：
- 如果当天存在 NARRATIVE_HOOKS[day]（D1-D14），优先使用（现有逻辑不变）
- D15+ 从 SUSPENSE_POOL_MID/LATE 中随机选取满足 cond 的条目
- 每条预告最多被同一玩家看到 2 次（加去重记录）
- fallback：如果没有匹配条目，保留原有数据预告作为兜底

**实现位置**：`scripts/Retention.lua` → `GenerateTomorrowPreview()` 扩展

**验收标准**：
- [ ] D15-D30 每天至少一条悬念式预告（非纯数据）
- [ ] 预告与玩家当前状态相关（不是随机废话）
- [ ] 不重复出现同一条预告超过 2 次

---

### 1.3 D7-D14 事件密度填充

**目标**：解决"第6-14天无聊→流失"的中期断层

**策略**：在已有框架内安排强制触发的里程碑事件

**事件编排表**：

| 天数 | 事件 | 触发方式 | 实现位置 |
|------|------|---------|---------|
| D6 | 首次免费抽卡 + 市场系统引导 | CheckNewbieBonus 扩展 | RetentionV2.lua |
| D7 | 强制首场友谊赛（不消耗AP） | 新事件注入 | Retention.lua |
| D8 | Victor 第二次出场（派手下来捣乱） | NARRATIVE_HOOKS[8] 已有 ✅ | — |
| D9 | 首个"门口闲聊"教学 | 新系统引导 | 新文件 |
| D10 | 首个角色组合事件触发 | 新系统 | 新文件 |
| D11 | 金币交易系统引导（"有人要卖金条"） | CheckNewbieBonus 扩展 | RetentionV2.lua |
| D12 | Victor 正面对峙（NARRATIVE_HOOKS[12] 已有 ✅） | — | — |
| D13 | 旅行者NPC首次来访预告 | 新系统 | 新文件 |
| D14 | 非洲地图界面解锁 + "下一城市"目标展示 | UI 解锁事件 | UIMapView.lua |

**需要新增的**：
- D6 免费抽卡事件（在 `RetentionV2.CheckNewbieBonus` 中添加 day==6 分支）
- D7 免费友谊赛强制触发（在日结算流程中检测）
- D11 金币交易引导

**已存在无需修改的**：D8, D10(NARRATIVE_HOOKS), D12(NARRATIVE_HOOKS)

**验收标准**：
- [ ] D6-D14 每天至少触发一个非重复的新事件或系统解锁
- [ ] 不强制消耗 AP（部分事件免费触发）
- [ ] 每个事件有清晰的"下一步该做什么"引导

---

### 1.4 "门口闲聊"系统（AP耗尽后的消遣）

**目标**：AP用完后不是"什么都不能做"，而是有一个轻松的互动界面

**设计**：
- 入口：AP=0 时，主界面出现"🪑 门口坐坐"按钮
- 界面：简单的对话框界面（复用已有 UI 组件）
- 内容来源：
  1. `STREET_RUMORS` 现有 30 条传闻（随机展示未读的）
  2. 新增 15-20 条"路人互动"（带选择，类似零AP微事件但更轻量）
  3. 偶尔触发小惊喜（声望 ±5，发现八卦线索）
- 每次"坐下"消耗 0 AP，每日可进入 5 次
- 第 3 次和第 5 次有概率出现"惊喜路人"（新候选队员预告/市场折扣情报）

**数据结构**：
```lua
DOORSTEP_CHATS = {
    -- 纯观赏型（展示传闻）
    { type = "rumor", weight = 50 },
    -- 互动型（带选择）
    { type = "interact", id = "dc_old_man_chess",
      title = "下棋老人",
      desc = "隔壁修车铺的张叔搬着棋盘过来了：\"来一局？\"",
      choices = {
          { text = "来！", result = "你赢了。张叔说明天介绍客人来。", reward = { rep = 2 } },
          { text = "改天吧", result = "张叔遗憾地走了。" },
      }},
    -- ... 15-20 条
}
```

**实现**：
```
新文件: scripts/DoorstepChat.lua     — 数据 + 逻辑
UI入口: scripts/UIPanel_Actions.lua  — AP=0 时显示按钮
```

**验收标准**：
- [ ] AP=0 时可见"门口坐坐"入口
- [ ] 每次进入展示不同内容（不连续重复）
- [ ] 互动型选择有即时反馈（声望/金钱微调）
- [ ] 单日上限 5 次，超限提示"天黑了，回去休息吧"

---

## 第二梯队：中期规划（预计 2-4 周）

### 2.1 角色组合事件系统

**目标**：当特定角色组合同时在队时，触发免 AP 的惊喜剧情

**设计原则**：
- 不消耗 AP（免费触发的惊喜）
- 每对组合只有 1 段核心事件（精品路线，不堆量）
- 完成后解锁永久被动加成（有辨识度的奖励）
- 文化元素嵌入（每段事件含 1 个非洲文化知识点 → 解锁图鉴）

**组合事件表（首批 8 组）**：

| # | 角色组合 | 事件名 | 主题 | 奖励被动 |
|---|---------|--------|------|---------|
| 1 | Kofi + Grace | "街头传说" | Kofi 教 Grace 本地俚语/Grace 教 Kofi 画画 | 双人在队时训练效率 +10% |
| 2 | Snake + Big Joe | "夜市兄弟" | 一起去夜市被骗/反骗的冒险 | 比赛中"逆风翻盘"概率 +8% |
| 3 | Kofi + Snake | "死对头" | 训练赌约：谁先上分请吃饭 | 两人同时训练时经验 ×1.2 |
| 4 | Grace + Mama B | "女性力量" | Grace 帮 Mama B 设计菜单 | 全队心情衰减 -15% |
| 5 | Big Joe + Thunder | "铁壁双塔" | 联合防守训练的故事 | 比赛防御评分 +12% |
| 6 | Prince + Grace | "贵族与平民" | 文化碰撞/互相理解的故事 | 招募费用 -20% |
| 7 | Snake + Prince | "地下交易" | Prince 的人脉 + Snake 的门路 | 金币交易利润 +10% |
| 8 | Kofi + Thunder | "师徒情" | 老将带新人的传承 | Kofi 满状态时 Thunder 获得 +5 技能 |

**触发条件**：
```lua
-- 每日结算时检测（GL_EndDay.lua）
function CheckComboEvents()
    for _, combo in ipairs(COMBO_EVENTS) do
        if not playerData_.comboTriggered[combo.id]          -- 未触发过
           and HasMember(combo.member1)                       -- 角色1在队
           and HasMember(combo.member2)                       -- 角色2在队
           and playerData_.day >= combo.minDay                -- 达到最低天数
           and math.random() < combo.dailyChance then         -- 日概率（20-30%）
            TriggerComboEvent(combo)
            break  -- 每天最多触发一个
        end
    end
end
```

**事件结构**：
```lua
COMBO_EVENTS = {
    { id = "kofi_grace",
      member1 = "Kofi", member2 = "Grace",
      minDay = 8, dailyChance = 0.25,
      title = "🎨 街头传说",
      -- 3-5 段对话（CinematicDialogue 格式）
      dialogues = { ... },
      -- 文化知识点解锁
      lore = { id = "twi_proverb", title = "特维语谚语",
               text = "Kofi 用特维语说了句谚语：'Obi nkyere abofra Nyame' —— 无需教孩子认识上帝（真理不言自明）。特维语是加纳最广泛使用的语言之一。" },
      -- 永久被动奖励
      reward = { type = "passive", id = "street_legends",
                 name = "街头传说", desc = "Kofi+Grace 同时在队时训练效率+10%",
                 effect = { trainBonus = 0.10, members = {"Kofi", "Grace"} } },
    },
    -- ...
}
```

**实现**：
```
新文件: scripts/ComboEvents.lua       — 数据定义 + 触发逻辑
修改:   scripts/GL_EndDay.lua          — 日结算时调用 CheckComboEvents()
修改:   scripts/TrainMatch.lua         — 应用被动加成
UI:     复用 CinematicDialogue 组件展示对话
```

**验收标准**：
- [ ] 满足条件时正确触发（角色在队 + 天数 + 概率）
- [ ] 每对组合只触发一次（永久标记）
- [ ] 奖励被动在对应场景中生效
- [ ] 事件对话包含文化知识点

---

### 2.2 非洲文化图鉴 / 博物馆系统

**目标**：收集+教育+长期目标，每解锁新内容点亮一个图鉴条目

**数据设计**：

```lua
-- 图鉴分类
LORE_CATEGORIES = {
    "characters",    -- 角色档案（8人）
    "cities",        -- 城市百科（7城）
    "culture",       -- 文化知识（来自组合事件/随机事件）
    "food",          -- 美食图鉴（Mama B 相关）
    "slang",         -- 俚语辞典（对话中出现的本地用语）
    "history",       -- 非洲电竞简史（虚构+真实混合）
    "items",         -- 市场物品图鉴（按品质分类）
}

-- 单条图鉴结构
LORE_ENTRIES = {
    { id = "char_kofi", category = "characters",
      title = "Kofi", subtitle = "天才少年",
      unlockCondition = "recruit_kofi",  -- 招募 Kofi 时解锁
      content = "Kofi，全名 Kofi Mensah。在阿坎族命名传统中，周五出生的男孩会被命名为 Kofi。他来自加纳库马西的一个可可种植家庭，15岁时凭借网吧里一台旧电脑自学成了服务器第一。",
      cultural_note = "阿坎族'日名'制度：周一=Kwadwo, 周二=Kwabena, 周三=Kwaku, 周四=Yaw, 周五=Kofi, 周六=Kwame, 周日=Kwasi。联合国前秘书长科菲·安南(Kofi Annan)也是周五出生。",
      image = "image/lore_kofi.png" },  -- 可选配图

    { id = "city_lagos", category = "cities",
      title = "拉各斯", subtitle = "非洲的纽约",
      unlockCondition = "unlock_city_lagos",
      content = "尼日利亚第一大城市，人口超过1500万。这里有非洲最大的电影产业'诺莱坞'(Nollywood)，每年产出约2500部电影，仅次于宝莱坞。",
      cultural_note = "拉各斯原名'Eko'，是约鲁巴语'营地/农场'的意思。'Lagos'是15世纪葡萄牙探险者起的名字，源自葡萄牙南部的Lagos镇。" },

    -- ... 总计 60-80 条
}
```

**解锁触发时机**：
- 招募角色 → 角色档案解锁
- 解锁/到达城市 → 城市百科解锁
- 角色组合事件完成 → 文化知识解锁
- 市场获得物品 → 物品图鉴解锁
- 特定天数/事件 → 历史/俚语条目解锁
- 门口闲聊特殊互动 → 美食/俚语解锁

**UI 界面**：
- 主入口："📖 图鉴" 按钮（AP 无关，随时可看）
- 分类 Tab 页（7 类）
- 已解锁条目：彩色卡片 + 内容
- 未解锁条目：灰色剪影 + "???" + 解锁提示
- 顶部进度条：已收集 XX/YY（总完成度）
- 新解锁条目有红点提示

**实现**：
```
新文件: scripts/LoreSystem.lua      — 数据定义 + 解锁逻辑
新文件: scripts/UILore.lua          — 图鉴 UI 界面
修改:   scripts/GL_EndDay.lua       — 日结算时检测解锁条件
修改:   scripts/Market.lua          — 获得物品时触发解锁
修改:   scripts/PrestigeSystem.lua  — 到达新城市时触发解锁
```

**验收标准**：
- [ ] 7 个分类 Tab 可切换
- [ ] 文化知识内容经过基本事实核查
- [ ] 新解锁有红点 + toast 通知
- [ ] 所有已有系统（招募/城市/市场/事件）正确触发解锁
- [ ] 进度百分比正确显示

---

### 2.3 旅行者 NPC 系统（限时内容替代方案）

**目标**：替代"赛季制"，提供温和的限时内容驱动力

**核心机制**：
- 每 30 天（游戏内天数），一位旅行者来访你的网吧
- 停留 14 天，然后离开
- 带来 3 个限时任务 + 1 个限定物品奖励
- 任务未完成不惩罚（只是错过奖励）
- 物品永久保留

**旅行者池（首批 5 位）**：

| # | 名字 | 来自 | 特色 | 限定物品 |
|---|------|------|------|---------|
| 1 | Amara | 塞内加尔 | 纺织艺术家 | "达喀尔挂毯"（装饰，心情衰减-10%） |
| 2 | Tendai | 津巴布韦 | 退役电竞选手 | "石鸟护符"（比赛暴击+5%） |
| 3 | Fatou | 马里 | 音乐人 | "科拉琴"（网吧BGM效果+15%收入） |
| 4 | Jabari | 肯尼亚 | 科技创业者 | "M-Pesa终端"（金币交易手续费-30%） |
| 5 | Nkem | 尼日利亚 | 美食博主 | "秘制jollof rice配方"（食堂升级效果×1.5） |

**任务设计（每位旅行者 3 个）**：
```lua
-- 示例：Amara 的任务
TRAVELER_AMARA = {
    name = "Amara", origin = "塞内加尔达喀尔", emoji = "🧵",
    greeting = "你好！我在环非洲旅行，用各地的故事编织挂毯。能让我在你这住几天吗？",
    stayDays = 14,
    quests = {
        { id = "amara_q1", title = "收集三个故事",
          desc = "Amara 需要三个当地故事来编织——完成 3 次训练（任意类型）",
          target = { type = "train_count", count = 3 },
          reward = { money = 200, rep = 10 } },
        { id = "amara_q2", title = "染料采购",
          desc = "帮 Amara 在市场找到染料——进行 2 次市场抽卡",
          target = { type = "market_pull", count = 2 },
          reward = { havocCoin = 100 } },
        { id = "amara_q3", title = "挂毯展览",
          desc = "Amara 想在你的网吧展示作品——声望达到当前+30",
          target = { type = "reputation_gain", amount = 30 },
          reward = { item = "dakar_tapestry" } },  -- 限定物品
    },
    departure = "谢谢你的款待！挂毯完成了——这是为你编的那幅。记住：每根线都是一个故事。",
    loreUnlock = "senegal_textiles",  -- 解锁图鉴条目
}
```

**系统流程**：
```
1. 每30天（游戏内）检测：是否有旅行者在访？
   - 无 → 从池中随机选取未来过的旅行者，触发"来访事件"
   - 有 → 检查是否到期（14天）
2. 旅行者在访期间：
   - 主界面显示旅行者图标 + 倒计时（"Amara 还会待 9 天"）
   - 任务面板可查看进度
   - 任务自动追踪（嵌入已有系统的回调）
3. 旅行者离开时：
   - 告别对话
   - 未完成任务标记为"错过"（不惩罚）
   - 解锁图鉴条目
4. 所有旅行者都来过后 → 池重置（同一旅行者可再来，但不给重复物品）
```

**实现**：
```
新文件: scripts/TravelerSystem.lua   — 旅行者数据 + 状态机 + 任务追踪
修改:   scripts/GL_EndDay.lua         — 日结算时 check 来访/离开
修改:   scripts/UIPanel_Daily.lua     — 显示旅行者状态 + 任务进度
修改:   scripts/TrainMatch.lua        — 训练完成时回调任务追踪
修改:   scripts/Market.lua            — 抽卡时回调任务追踪
```

**验收标准**：
- [ ] 第 30 天（或首次触发日）正确出现旅行者
- [ ] 14 天倒计时正确
- [ ] 3 个任务可独立完成，进度正确追踪
- [ ] 离开时未完成任务不惩罚
- [ ] 限定物品正确入库且能装备/生效
- [ ] 图鉴条目正确解锁

---

### 2.4 训练小游戏重玩 + 个人记录板

**目标**：给重度玩家 AP 耗尽后的技巧追求出口

**设计**：
- 已有 5 类训练小游戏（aim/quiz/memory/react/comm）
- 新增"练习模式"：不消耗 AP，不获得队员经验
- 每个小游戏记录个人最高分 + 历史 Top 5
- 小游戏入口从"门口坐坐"界面也可进入（作为消遣选项之一）

**数据**：
```lua
playerData_.miniGameRecords = {
    aim = { best = 95, history = {95, 88, 82, 79, 75} },
    react = { best = 320, history = {320, 298, 276, ...} },  -- ms
    -- ...
}
```

**实现**：
```
修改: scripts/MiniGames.lua          — 增加 practiceMode 参数
修改: scripts/UIPanel_Actions.lua    — AP=0 时显示"练习"入口
新增: 记录板 UI（嵌入 MiniGames 结算界面）
```

**验收标准**：
- [ ] 练习模式不消耗 AP
- [ ] 练习模式不给队员加经验（明确提示"练习模式"）
- [ ] 最高分正确记录和持久化
- [ ] 打破记录时有庆祝反馈

---

## 第三梯队：长期方向（验证前两梯队效果后再推进）

> **启动条件**：第一梯队全部上线 + D14 留存提升至 15%+ + DAU 稳定在 5000+

### 3.1 异步周赛（AI 战队对战）

**前置条件**：
- 第二梯队 [2.1] 角色组合事件上线（战队体系已有深度）
- serverCloud 接入完成
- DAU ≥ 5000（确保匹配池足够）

**详细设计**：

**赛制规则**：
- 周一 00:00 自动快照当前战队状态并上传
- 周一 08:00 服务端完成匹配（按总战力 ±20% 范围配对）
- 周一-周六：玩家可随时查看"对手信息"（战队名/成员/总战力，不透露具体数值）
- 周日 20:00：自动结算，推送结果
- 每周参赛奖励（无论输赢）：哈弗币 ×50
- 胜利额外奖励：哈弗币 ×100 + "周赛冠军"临时称号（持续7天）

**匹配算法**：
```lua
-- 服务端伪代码
function MatchPlayers(playerPool)
    -- 按总战力排序
    table.sort(playerPool, function(a, b) return a.power < b.power end)
    local matches = {}
    -- 相邻配对（±20% 容差）
    for i = 1, #playerPool - 1, 2 do
        local a, b = playerPool[i], playerPool[i+1]
        if b.power <= a.power * 1.2 then
            table.insert(matches, { a, b })
        end
    end
    return matches
end
```

**对战模拟（确定性）**：
```lua
-- 基于双方快照的 Bo3 模拟
function SimulateMatch(teamA, teamB)
    local results = {}
    for round = 1, 3 do
        local scoreA = CalcRoundScore(teamA, round)  -- 基础战力 + 随机种子(固定)
        local scoreB = CalcRoundScore(teamB, round)
        table.insert(results, { winner = scoreA > scoreB and "A" or "B", scoreA = scoreA, scoreB = scoreB })
    end
    return results
end

function CalcRoundScore(team, round)
    local base = team.totalPower
    -- 成员被动/组合加成
    base = base * (1 + team.comboBonus)
    -- 确定性"随机"因子（用 teamId + round 做种子）
    local seed = HashInt(team.id .. tostring(round))
    local variance = (seed % 20 - 10) / 100  -- ±10% 波动
    return math.floor(base * (1 + variance))
end
```

**客户端回放界面**：
- 打开"周赛结果"后，以文字直播形式逐帧展示 Bo3 过程
- 每回合有 3-5 条解说文本（从 MID_DECISION_POOL 风格池中选取）
- 关键时刻（逆转/完胜）有特殊动画效果
- 结算后显示：MVP 队员 + 数据对比 + 奖励领取

**排名系统**：
- 积分制（胜+3，平+1，负+0）
- 每月重置一次
- 分段：青铜/白银/黄金/钻石/大师（纯荣誉，无实质差异）
- **可关闭**：设置中"隐藏我的排名"→ 不在排行榜展示，但仍可参赛拿奖励

**战队快照数据结构**：
```lua
-- 上传到 serverCloud 的快照
teamSnapshot = {
    playerId = "xxx",
    teamName = playerData_.teamName or "Dragon Force",
    power = totalPower,                    -- 总战力
    members = {
        { name = "Kofi", skill = 65, mood = 80, perk = "天才直觉" },
        { name = "Grace", skill = 58, mood = 90, perk = "冷静分析" },
        -- ...
    },
    comboBonuses = { "street_legends" },   -- 已激活的组合被动
    equippedItems = { "champion_boots", "led_strip" },  -- 装备物品
    city = "Wakandaville",
    uploadTime = os.time(),
}
```

**文件规划**：
```
新文件: scripts/WeeklyLeague.lua          — 周赛客户端逻辑（快照上传/结果拉取/回放）
新文件: scripts/UIWeeklyLeague.lua        — 周赛 UI（对手信息/回放/排名）
服务端: serverCloud Score 存储战队快照 + 排名分数
修改:   scripts/GL_EndDay.lua             — 周一触发快照上传
修改:   scripts/UIPanel_Status.lua        — 添加"周赛"入口
```

**验收标准**：
- [ ] 周一自动上传快照（无需玩家操作）
- [ ] 匹配结果周日准时出现
- [ ] Bo3 回放流畅、解说文本不重复
- [ ] 排名可关闭且关闭后不影响奖励
- [ ] 无人匹配时给 AI 对手（从预设池中选取）

---

### 3.2 明信片轻社交

**前置条件**：
- DAU ≥ 10000（确保每天能匹配到不同的人）
- [2.2] 图鉴系统已上线（明信片收集联动图鉴）
- serverCloud 接入完成

**详细设计**：

**核心机制**：
- 每天可寄出 1 张明信片（免费，无 AP 消耗）
- 随机匹配一位"笔友"（不同城市优先匹配，增加新鲜感）
- 收到明信片获得：声望 +5 + 查看对方网吧截图
- 累计收集不同城市来信 → 解锁图鉴"邮票"条目

**明信片内容（安全设计）**：
```lua
-- 不允许自由文本，只能从模板中选择（防骚扰）
POSTCARD_TEMPLATES = {
    -- 问候类
    "从{city}向你问好！这里的阳光比你那儿热三倍。",
    "今天的生意特别好，忍不住想分享给远方的朋友。",
    "我的战队刚赢了一场比赛！你那边怎么样？",
    -- 建议类
    "记得给队员买杯咖啡，心情很重要！",
    "Gold Net 在我这边也有分店，我们是同盟军！",
    -- 炫耀类（友好）
    "猜猜我今天抽到了什么？不告诉你，哈哈。",
    "我的网吧刚装修了新灯，好看得不行。",
    -- 鼓励类
    "坚持住！从零到一是最难的，后面会越来越好。",
    "Victor 那种人到哪都有，别在意，做自己就好。",
}

-- 明信片数据结构
Postcard = {
    fromPlayerId = "xxx",
    fromCity = "Lagos",
    fromCafeSnapshot = "image/cafe_busy_xxx.png",  -- 网吧截图
    template = "从{city}向你问好！...",
    sentDay = 45,
    receivedDay = 46,  -- 次日送达
}
```

**收集系统**：
```lua
-- 邮票图鉴（与 LoreSystem 联动）
STAMP_COLLECTION = {
    { id = "stamp_wakandaville", city = "Wakandaville", icon = "🏠" },
    { id = "stamp_lagos", city = "Lagos", icon = "🌆" },
    { id = "stamp_nairobi", city = "Nairobi", icon = "🦁" },
    { id = "stamp_accra", city = "Accra", icon = "⭐" },
    { id = "stamp_dakar", city = "Dakar", icon = "🎵" },
    { id = "stamp_capetown", city = "Cape Town", icon = "🏔️" },
    { id = "stamp_kinshasa", city = "Kinshasa", icon = "🥁" },
}
-- 收集所有7城邮票 → 解锁成就"环非洲笔友" + 特殊装饰物品
```

**UI 界面**：
- 入口："📮 邮箱" 按钮（主界面右上角，有未读红点）
- 收件箱：按时间排列，显示对方城市 + 模板文本 + 网吧截图缩略图
- 寄信界面：选择模板 → 确认寄出 → "明天对方就会收到啦"
- 邮票墙：展示已收集的城市邮票（灰/亮状态）

**防滥用**：
- 每日发送上限 1 封
- 内容只能从模板选取
- 截图为系统自动截取（玩家不可上传自定义图片）
- 举报机制：如果某玩家的网吧截图被举报，从匹配池移除

**文件规划**：
```
新文件: scripts/PostcardSystem.lua       — 发送/接收/匹配逻辑
新文件: scripts/UIPostcard.lua           — 邮箱/寄信/邮票墙 UI
服务端: serverCloud 存储明信片队列 + 匹配分配
修改:   scripts/LoreSystem.lua           — 邮票图鉴条目注册
修改:   scripts/UIScreens.lua            — 主界面添加邮箱入口
```

**验收标准**：
- [ ] 每日限 1 封发送
- [ ] 次日准时收到（非实时）
- [ ] 模板选择界面清晰，无自由文本输入
- [ ] 网吧截图正确展示
- [ ] 7 城邮票收集进度正确
- [ ] 匹配池不足时（DAU低）给 AI 笔友（预设内容）

---

### 3.3 网吧布局自定义

**前置条件**：
- 第一梯队全部上线 + 玩家反馈对"网吧个性化"有需求
- 美术资源准备（分层素材）

**分阶段实施**：

#### Phase 1: 极简版（壁纸 + 色调）

**范围**：
- 6 种壁纸可选（每座城市解锁 1 种独有风格）
  - Wakandaville: 原始红砖墙
  - Lagos: 霓虹涂鸦墙
  - Nairobi: 大草原壁画
  - Accra: 金星图腾墙
  - Dakar: 达喀尔挂毯墙
  - Cape Town: 现代极简白
- 3 种灯光色调（暖黄 / 冷白 / 霓虹紫）
- 2 种地板（水泥地 / 木地板）

**实现方式**：
- 不重构渲染系统
- 在 `GetCafeStateImage()` 基础上增加"叠加层"
- 壁纸 = 基础背景图替换
- 灯光 = NanoVG 全屏叠加一层半透明色板
- 地板 = 背景图底部 1/4 区域替换

```lua
-- 在 CafeRenderer 中
function GetCafeCompositeImage()
    local base = GetCafeStateImage()  -- 现有逻辑
    local wallpaper = playerData_.cafeCustom and playerData_.cafeCustom.wallpaper or "default"
    local lighting = playerData_.cafeCustom and playerData_.cafeCustom.lighting or "warm"
    return { base = base, wallpaper = wallpaper, lighting = lighting }
end
```

**解锁条件**：
- 壁纸：到达对应城市自动解锁
- 灯光/地板：装饰升级达到 Lv2/Lv3 时解锁

**UI 入口**：
- 网吧界面增加"🎨 装修"按钮
- 进入后显示当前网吧预览 + 底部选项卡（壁纸/灯光/地板）
- 实时预览切换效果
- 确认后保存

#### Phase 2: 进阶版（布局编辑器）— 远期

**范围**：
- 8×6 网格布局
- 可放置物品：电脑桌(1×1)、沙发(2×1)、饮水机(1×1)、装饰画(1×1)、植物(1×1)
- 拖拽放置/旋转
- 物品来源：升级解锁 + 市场抽到的装饰类物品自动进入可放置池
- 访客动线模拟：不同布局影响"客流效率"（±5% 收入）

**技术方案**（远期，需评估成本）：
- 从静态像素图 → 2D Tilemap 渲染
- 或保持像素图但用 NanoVG 叠加"物品图标层"（低成本折中）

#### Phase 3: 终极版（招牌 + 外观）— 梦想期

- 自定义网吧招牌文字（预设字体）
- 门面外观选择（3种门脸风格）
- 夜间霓虹灯效果
- 这些在"明信片社交"中作为展示内容，形成表达闭环

**文件规划（Phase 1）**：
```
新文件: scripts/CafeCustomize.lua     — 装修数据 + 解锁逻辑
新文件: scripts/UICafeCustomize.lua   — 装修编辑界面
修改:   scripts/CafeRenderer.lua      — 渲染叠加层
修改:   scripts/GameState.lua         — playerData_.cafeCustom 字段
修改:   scripts/PrestigeSystem.lua    — 城市解锁触发壁纸解锁
```

**验收标准（Phase 1）**：
- [ ] 6 种壁纸正确显示
- [ ] 灯光色调叠加效果自然
- [ ] 装修选择正确持久化
- [ ] 解锁条件准确（城市/装饰等级）
- [ ] 切换后网吧界面即时更新

---

### 3.4 节日活动系统（从定期事件进化）

**前置条件**：
- 旅行者 NPC 系统上线并运行良好
- 玩家对限时内容有正面反馈

**详细设计**：

**与旅行者系统的区别**：
| 维度 | 旅行者 NPC | 节日活动 |
|------|-----------|---------|
| 频率 | 每30天 | 每年固定日期（可与现实日历对应） |
| 规模 | 1人+3任务 | 全城氛围变化+专属事件链+限定商店 |
| 持续 | 14天 | 7天 |
| 影响范围 | 仅任务面板 | 背景图/音乐/NPC对话/市场物品全部变化 |

**首批节日池（6个）**：

| # | 节日 | 时间（游戏内） | 灵感来源 | 特殊机制 |
|---|------|--------------|---------|---------|
| 1 | 非洲电竞周 | Day 50-56 | Africa Games Week | 比赛奖励 ×2，限定赛事 |
| 2 | 丰收感恩节 | Day 80-86 | Yam Festival (加纳) | 升级半价，Mama B 限定菜单 |
| 3 | 霓虹之夜 | Day 110-116 | Lagos Nightlife | 网吧收入 ×1.5（夜间加成），限定装饰 |
| 4 | 风暴季 | Day 140-146 | Harmattan Season | 连续恶劣天气，但生存奖励翻倍 |
| 5 | 创业者大会 | Day 170-176 | AfricArena Summit | 限定投资人事件，大额投资机会 |
| 6 | 冠军纪念日 | Day 200-206 | 纪念首次夺冠 | 回顾CG播放，限定称号，全属性 buff |

**节日活动结构**：
```lua
FESTIVAL_TEMPLATE = {
    id = "esports_week",
    name = "非洲电竞周",
    triggerDay = 50,  -- 首次触发日（之后每"年"循环）
    duration = 7,
    -- 氛围变化
    atmosphere = {
        bgImage = "image/festival_esports_week.png",
        bgmOverride = "Sounds/esports_hype.ogg",
        weatherOverride = "festival",  -- 强制节日天气
    },
    -- 每日事件链（7天，每天一个小故事）
    dailyEvents = {
        [1] = { title = "开幕式", desc = "...", reward = {...} },
        [2] = { title = "小组赛日", desc = "...", choices = {...} },
        -- ...
        [7] = { title = "总决赛", desc = "...", reward = {...} },
    },
    -- 限定商店物品（期间市场额外出现）
    limitedItems = { "esports_trophy", "champion_jersey", "golden_mouse" },
    -- 全局 buff
    globalBuff = { matchReward = 2.0 },  -- 比赛奖励 ×2
    -- 图鉴解锁
    loreUnlock = "esports_history_01",
}
```

**循环机制**：
- 首次触发在固定天数
- 之后每 "210 天"（一个"游戏年"）循环
- 重复参与不给重复物品，但每次有新的"年度限定"1件

**与已有系统的衔接**：
- 现有 `PERIODIC_EVENTS`（RetentionV2）保留为"轻量版"（1-2天的短事件）
- 节日活动为"重量版"（7天完整事件链），两者并存不冲突
- 节日期间旅行者不来访（避免信息过载）

**文件规划**：
```
新文件: scripts/FestivalSystem.lua      — 节日数据 + 状态机 + 事件链
新文件: scripts/UIFestival.lua          — 节日专属 UI（限定商店/事件面板/倒计时）
修改:   scripts/GL_EndDay.lua           — 日结算检测节日触发/推进
修改:   scripts/CafeRenderer.lua        — 节日期间背景图替换
修改:   scripts/Market.lua              — 节日限定物品注入
修改:   scripts/AudioSave.lua           — BGM 切换
```

**验收标准**：
- [ ] 到达触发日正确开启节日
- [ ] 7 天事件链逐日推进
- [ ] 氛围（背景/音乐/天气）正确切换
- [ ] 节日结束后恢复正常
- [ ] 限定物品只在节日期间出现
- [ ] 循环触发时不重复给旧物品

---

### 第三梯队实施节奏

```
Week 7-9 (前置准备完成后):
  └─ [3.1] 异步周赛 ──────────────────── 需服务端配合

Week 9-11:
  └─ [3.3 Phase1] 网吧装修极简版 ────── 独立开发（美术资源准备）

Week 11-13:
  └─ [3.4] 节日活动系统 ─────────────── 依赖 [2.3] 旅行者的"限时框架"复用

Week 13-15 (DAU 达标后):
  └─ [3.2] 明信片社交 ─────────────── 需服务端 + DAU 规模
```

### 第三梯队文件变动汇总

| 操作 | 文件 | 说明 |
|------|------|------|
| 新建 | `scripts/WeeklyLeague.lua` | 异步周赛客户端逻辑 |
| 新建 | `scripts/UIWeeklyLeague.lua` | 周赛 UI |
| 新建 | `scripts/PostcardSystem.lua` | 明信片收发逻辑 |
| 新建 | `scripts/UIPostcard.lua` | 邮箱 UI |
| 新建 | `scripts/CafeCustomize.lua` | 网吧装修逻辑 |
| 新建 | `scripts/UICafeCustomize.lua` | 装修编辑 UI |
| 新建 | `scripts/FestivalSystem.lua` | 节日活动系统 |
| 新建 | `scripts/UIFestival.lua` | 节日 UI |
| 修改 | `scripts/GL_EndDay.lua` | 周赛快照/节日触发 |
| 修改 | `scripts/CafeRenderer.lua` | 装修叠加层/节日背景 |
| 修改 | `scripts/LoreSystem.lua` | 邮票+节日图鉴条目 |
| 修改 | `scripts/Market.lua` | 节日限定物品 |
| 修改 | `scripts/UIScreens.lua` | 新入口按钮 |
| 修改 | `scripts/GameState.lua` | 新 playerData_ 字段 |

---

## 实施节奏 & 依赖关系

```
Week 1-2 (第一梯队):
  ┌─ [1.1] 非洲地图 ──────────────────── 独立开发
  ├─ [1.2] 明日预告悬念化 ──────────────── 独立开发（纯文案+少量逻辑）
  ├─ [1.3] D7-D14 事件填充 ─────────────── 依赖 [1.4] 门口闲聊的 D9 引导
  └─ [1.4] 门口闲聊系统 ──────────────── 独立开发

Week 3-4 (第二梯队前半):
  ┌─ [2.1] 角色组合事件 ──────────────── 独立开发
  └─ [2.4] 训练重玩+记录板 ─────────────── 独立开发

Week 4-6 (第二梯队后半):
  ┌─ [2.2] 文化图鉴系统 ──────────────── 依赖 [2.1] 组合事件的 lore 数据
  └─ [2.3] 旅行者NPC系统 ─────────────── 独立开发（但建议 [2.2] 先完成以联动）
```

---

## 文件变动总览

| 操作 | 文件 | 说明 |
|------|------|------|
| 新建 | `scripts/UIMapView.lua` | 非洲地图 UI |
| 新建 | `scripts/DoorstepChat.lua` | 门口闲聊数据+逻辑 |
| 新建 | `scripts/ComboEvents.lua` | 角色组合事件 |
| 新建 | `scripts/LoreSystem.lua` | 图鉴数据+解锁逻辑 |
| 新建 | `scripts/UILore.lua` | 图鉴 UI |
| 新建 | `scripts/TravelerSystem.lua` | 旅行者 NPC |
| 修改 | `scripts/Retention.lua` | 明日预告扩展（SUSPENSE_POOL） |
| 修改 | `scripts/RetentionV2.lua` | D6/D11 新手事件扩展 |
| 修改 | `scripts/GL_EndDay.lua` | 日结算增加组合事件/旅行者检测 |
| 修改 | `scripts/UIPanel_Actions.lua` | AP=0 时显示"门口坐坐"+"练习" |
| 修改 | `scripts/UIPanel_Daily.lua` | 旅行者状态显示 |
| 修改 | `scripts/MiniGames.lua` | 练习模式 + 记录板 |
| 修改 | `scripts/Market.lua` | 抽卡回调旅行者任务追踪 + 图鉴解锁 |
| 修改 | `scripts/TrainMatch.lua` | 训练回调 + 组合被动加成 |
| 修改 | `scripts/PrestigeSystem.lua` | 城市解锁触发图鉴 |
| 修改 | `scripts/main.lua` | require 新模块 |

---

## 风险与注意事项

| 风险 | 应对 |
|------|------|
| 文化内容不准确 | 每条图鉴/旅行者背景需查证；标注"本游戏含虚构元素" |
| 代码体积膨胀 | 当前总量 ~41000 行；新增估计 +3000-4000 行；控制单文件 < 800 行 |
| 存档兼容性 | 所有新 playerData_ 字段必须有默认值（`or {}`/`or 0`），老存档无缝兼容 |
| 事件过于密集 | D6-D14 每天最多 1 个强制事件；旅行者任务不强制，避免"任务爆炸" |
| AP 经济失衡 | 门口闲聊/练习模式严格 0 奖励/0 经验，不影响核心数值循环 |

---

## 成功指标

| 指标 | 当前估计 | 目标 |
|------|---------|------|
| D7 留存 | ~22% | 30%+ |
| D14 留存 | ~12% | 18%+ |
| D30 留存 | ~6% | 10%+ |
| 日均在线时长 | ~8 分钟 | 12+ 分钟 |
| 日均广告观看 | ~4 次 | 6+ 次（因为在线时间延长自然增长） |

---

## 执行优先级排序（最终版）

```
紧急且重要          重要但不紧急
─────────────     ─────────────
[1.2] 明日预告     [2.1] 角色组合事件
[1.3] D7-D14填充   [2.2] 文化图鉴
[1.4] 门口闲聊     [2.3] 旅行者NPC

有价值但可缓       长期观察
─────────────     ─────────────
[1.1] 非洲地图     [3.1] 异步周赛
[2.4] 训练重玩     [3.2] 明信片社交
                   [3.3] 网吧自定义
```

> **立即动手的第一件事**：改写 D15+ 的明日预告（纯文案工作，0 风险，当天可完成，次日即可观测留存变化）。
