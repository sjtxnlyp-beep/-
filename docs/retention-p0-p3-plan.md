# P0-P3 留存改进实施方案

> 基于专家讨论结论，解决 D7-D14 "过渡沼泽" 留存断崖问题
> 
> 实施顺序: P0 → P1 → P2 → P3

---

## 现状分析

### 当前留存系统覆盖

| 天数 | 系统 | 问题 |
|------|------|------|
| D1-D3 | Retention.lua 教程事件 | ✅ 引导完善 |
| D1-D7 | TomorrowPreview Layer0 叙事钩子 | ✅ 每日悬念 |
| D1-D7 | RetentionV2 微事件(15种) | ✅ 惊喜感 |
| **D8-D11** | **无叙事钩子，无主线推进** | 🔴 **断崖点** |
| D12+ | Victor挑衅→挖角→破坏 | ⚠️ 开始太晚 |
| D15-D30 | 里程碑事件(零散) | ⚠️ 密度不足 |

### 核心问题

**D7-D12 是"过渡沼泽"**：叙事钩子D7结束后，Victor线D12才开始，中间4天没有主线驱动力。ChapterSystem的Ch2解锁条件(rep≥100, 1次锦标赛胜利)需要时间积累，玩家在等待期缺乏目标感。

---

## P0: Victor 复仇弧线补全 (D7-D14)

### 目标
填补 D8-D11 叙事空白，将 Victor 线提前渗透，让玩家在"过渡沼泽"有持续紧张感。

### 新增事件设计

#### 事件1: `victor_spy` (D8, rep≥25)
```
类型: dialogue
触发: day >= 8 AND rep >= 25 AND storyTriggered_["rival_appears"]
标题: "不速之客"
内容:
  - 旁白: "打烊时，你注意到角落有个人在用手机偷拍你的设备清单。"
  - 你: "（上前）你在干什么？"
  - 陌生人: "（慌张）不好意思……我只是、我只是觉得你这里挺酷的……"
  - Kofi: "老板，我认得他！他是Gold Net那边的人！"
  - 陌生人: "（快步离开）"
  - 旁白: "Victor已经开始关注你了。这是试探，还是警告？"
效果: rep+5, 设置 storyTriggered_["victor_spy"]
```

#### 事件2: `victor_price_war` (D9, rep≥30)
```
类型: choice
触发: day >= 9 AND storyTriggered_["victor_spy"]
标题: "价格战"
描述: "Gold Net突然宣布'新客首周免费'。你的几个常客犹豫着要不要过去看看。"
选项:
  A: "💰 跟进打折 -$100" → "你宣布老客户半价周！客人们回来了，但这周利润缩水明显。"
     效果: money-100, rep+10, 客户留存
  B: "💪 坚持品质不降价" → "你跟常客说：'去体验一下也行，但你们知道哪里更有灵魂。' 走了几个，但核心客户更忠诚了。"
     效果: rep+5, 核心客户loyalty+1
```

#### 事件3: `victor_rumor` (D10, rep≥35)
```
类型: dialogue
触发: day >= 10 AND storyTriggered_["victor_price_war"]
标题: "流言蜚语"
内容:
  - 常客: "老板，外面有人在说你这里用的是二手翻新设备，容易烧屏……"
  - 你: "什么？谁在传这种话？"
  - Snake: "（阴沉）Gold Net那边的水军。我认得那些ID。"
  - 旁白: "Victor开始玩脏的了。你的网吧评分下降了0.3分。"
  - Kofi: "老板，要不咱们也反击？"
  - 你: "不。让质量说话。" 
  - 旁白: "信念动摇时最危险。但Dragon Force的人选择了信任你。【士气+3】"
效果: rep-5 (暂时), teamMorale+3
```

#### 事件4: `victor_challenge_preview` (D11, rep≥40)
```
类型: dialogue
触发: day >= 11 AND storyTriggered_["victor_rumor"]
标题: "战书"
内容:
  - 旁白: "一封正式的电子邮件——来自非洲电竞联赛(AEL)秘书处。"
  - 邮件: "致 Dragon Net Cafe: 您已被邀请参加第三赛季区域预选赛。同区对手包括: Gold Net Gaming (Victor Schneider)。"
  - Kofi: "（握拳）终于！正面对决的机会！"
  - 旁白: "三周后的预选赛——Victor已经等不及了。这三周，你必须全力备战。"
效果: 解锁"备战"目标链, storyTriggered_["victor_challenge_preview"]
```

### TomorrowPreview 扩展 (D8-D14)

在 `Retention.lua` 的 `NARRATIVE_HOOKS` 表中追加:

```lua
[8] = {
    scene = "深夜，门外有人影一闪而过。Gold Net的人？",
    hook = "明天，可能会有不速之客。Victor已经注意到你了。",
    icon = "👁️", urgency = "high",
},
[9] = {
    scene = "手机收到推送：'Gold Net 开业特惠——新客首周免费'",
    hook = "价格战来了。明天你得想想怎么应对。客户会动摇吗？",
    icon = "⚔️", urgency = "high",
},
[10] = {
    scene = "论坛上出现了几条差评……IP地址都指向Gold Net附近。",
    hook = "Victor开始玩暗箭了。明天，流言会蔓延到你的常客中。",
    icon = "🗣️", urgency = "high",
},
[11] = {
    scene = "收件箱里有一封正式邮件，发件人是AEL秘书处。",
    hook = "非洲电竞联赛的邀请……和Victor正面对决的机会来了。",
    icon = "📧", urgency = "high",
},
[12] = {
    scene = "凌晨两点，门铃响了。透过毛玻璃，一个高大的影子站在门外。",
    hook = "Victor亲自来了。他要干什么？明天见分晓。",
    icon = "😈", urgency = "high",
},
[13] = {
    scene = "Victor的话还在耳边回响：'你什么都没有。'",
    hook = "队员们的眼神变了——不是恐惧，是愤怒。明天的训练会更拼命。",
    icon = "🔥", urgency = "mid",
},
[14] = {
    scene = "队员小声讨论着什么……一个人的手机屏幕上，是Gold Net的招聘帖。",
    hook = "Victor要挖角了。你能留住他们吗？",
    icon = "⚠️", urgency = "high",
},
```

### 实现文件变更

| 文件 | 变更 |
|------|------|
| `scripts/StoryEvents.lua` | 插入4个新事件 (victor_spy/price_war/rumor/challenge_preview) |
| `scripts/Retention.lua` | NARRATIVE_HOOKS 追加 D8-D14 |
| `scripts/GameState.lua` | 确保 storyTriggered_ 持久化(已有) |

### UI 规范

所有新事件弹窗使用现有 `BuildEventUI()` 渲染，无需新增UI。现有规范:
- 容器: `ScrollView { width = "88%", maxWidth = 400, maxHeight = "90%", padding = {18,16} }`
- 描述文本截断: 超过80字符分行
- 选项按钮: 全宽，间距 gap=6

---

## P1: 每日回归感知系统

### 目标
让玩家每次打开游戏都有"队友在等我"的温暖感，强化社交联结。

### 1.1 队员每日一言系统

#### 设计
每次进入游戏（新的一天开始时），首屏显示一条队员的话。文案池按照：
- 队员身份 (Kofi/Grace/Snake/Ada/其他)
- 当前状态 (心情好/普通/低落)
- 游戏阶段 (early D1-7 / mid D8-18 / late D19+)

#### 文案池结构
```lua
TEAMMATE_DAILY_WORDS = {
    kofi = {
        happy = {
            early = { "老板！昨天那把五杀爽到了！今天继续练！", ... },
            mid   = { "我感觉技术又涨了！下次比赛我要carry！", ... },
            late  = { "老板，我们真的能进决赛！我相信！", ... },
        },
        normal = { ... },
        low = { ... },
    },
    grace = { ... },
    snake = { ... },
    generic = { ... }, -- 通用NPC/新队员
}
```

每个状态×阶段至少5条文案，避免重复。

#### UI 弹窗规范
```
┌─────────────────────────────┐
│  [队员头像/emoji]            │
│                             │
│  "老板！昨天那把五杀爽到了！  │
│   今天继续练！"              │
│                             │
│        ── Kofi              │
│                             │
│      [ 开始新的一天 ]        │
└─────────────────────────────┘
```

- 容器: `UI.Panel { width = "80%", maxWidth = 360, padding = {24, 20}, borderRadius = 16 }`
- 文字: `fontSize = 16, textAlign = "center", color = 暖色`
- 自动3秒消失 或 点击关闭
- 不用 ScrollView（内容固定短小）
- `flexShrink = 0` 确保不被压缩

### 1.2 登录连续天数可视化

#### 现有系统
`RetentionV2.lua` 已有7天循环登录奖励 (`RV2.LOGIN_STREAK_REWARDS`)，但缺少**视觉展示**。

#### 新增: 连续登录条 (融入首页)
在主界面顶部状态栏区域显示:

```
🔥 连续第 5 天 ──── ○ ○ ○ ○ ● ○ ○
                    1  2  3  4  5  6  7
```

- 用7个圆点表示7天循环
- 已完成的用实心 + 强调色
- 当天的放大 + 动画脉冲
- 未达到的用空心

#### UI 实现
```lua
UI.Panel {
    flexDirection = "row", alignItems = "center", gap = 4,
    height = 28, flexShrink = 0,
    children = { ... 7个 dot 组件 ... }
}
```

- 每个 dot: `width = 14, height = 14, borderRadius = 7`
- 当日: `width = 18, height = 18, borderRadius = 9` + 高亮色
- 文字标签: `fontSize = 11, color = 次要色`

### 实现文件变更

| 文件 | 变更 |
|------|------|
| `scripts/Retention.lua` (或新建 `scripts/DailyGreeting.lua`) | 队员每日一言逻辑 + 文案池 |
| `scripts/UIScreens.lua` | 首页加入连续登录可视化条 |
| `scripts/UIManage.lua` | 新一天开始时弹出每日一言 |
| `scripts/GameState.lua` | 记录今天是否已显示每日一言 |

---

## P2: D14-D30 留存 (AEL 赞助线 + 教练系统)

### 目标
在中后期提供新的成长维度和目标感，防止"数值倦怠"。

### 2.1 AEL 赞助体系

#### 故事背景
非洲电竞联赛(AEL)注意到 Dragon Net Cafe 的崛起，提供不同级别的赞助合同。这是"外部认可"的正反馈循环。

#### 赞助等级

| 等级 | 解锁条件 | 每日收入 | 附加效果 |
|------|---------|---------|---------|
| 🥉 铜牌 | D14+, rep≥80 | +$30/天 | 解锁AEL训练营(技能加速10%) |
| 🥈 银牌 | D20+, rep≥150, 2次锦标赛胜利 | +$80/天 | 解锁高级设备折扣20% |
| 🥇 金牌 | D26+, rep≥250, 4次锦标赛胜利 | +$150/天 | 解锁AEL国际赛名额 |

#### 事件触发
```lua
-- 新增 StoryEvents
{ id = "ael_scout_visit",
  cond = function() return playerData_.day >= 14 and playerData_.reputation >= 80 end,
  type = "dialogue",
  title = "AEL 球探来访",
  dialogues = {
    { speaker = "陌生人", text = "你好，我是AEL非洲电竞联赛的区域主管。我们一直在关注Dragon Force的表现。" },
    { speaker = "AEL主管", text = "联赛想跟你签一份初级赞助协议——每月资助你$900，条件是你的队伍参加我们的正式赛事。" },
    { speaker = "旁白", text = "这是官方认可！AEL的Logo挂在门口，意味着你已经不是街头小队了。" },
  },
  effect = function()
    playerData_.aelTier = 1
    playerData_.aelDailyIncome = 30
    AddLog("🏆 获得AEL铜牌赞助！每日+$30")
  end,
}
```

#### 赞助商任务系统 (增加黏性)
AEL赞助附带周期任务，完成可升级赞助等级:
- 铜牌任务: "本周赢得1场比赛" / "训练总时长≥5次"
- 银牌任务: "培养1名技能≥80的队员" / "连续3天营业额≥$200"
- 金牌任务: "全队平均技能≥100" / "声望≥250"

### 2.2 教练系统

#### 设计理念
D14+ 解锁"请教练"功能，教练是**被动加成角色**，不占队员位置，提供持续成长方向。

#### 教练类型

| 教练 | 专长 | 效果 | 解锁条件 | 费用 |
|------|------|------|---------|------|
| 老陈 | 基础训练 | 全队训练效率+15% | D14+, $300 | $50/天 |
| Coach K | 心态管理 | 比赛紧张值-30% | D18+, rep≥120 | $80/天 |
| Maria | 战术分析 | 比赛战术选项+1 | D22+, 3次锦标赛 | $120/天 |

#### 教练故事事件
每个教练有2-3个专属故事事件，增加叙事深度:

```lua
{ id = "coach_chen_intro",
  cond = function() return playerData_.day >= 14 and not playerData_.coach end,
  type = "choice",
  title = "门口的老人",
  desc = "一个中年华人站在门口看了半天。他穿着褪色的运动服，脖子上挂着口哨。\n\n'小伙子，我是老陈。以前在国内带过青训队。看你们打了三天了……基本功不扎实啊。'\n\n'要是不嫌弃，我来帮你带带？不贵，一天50刀够我吃住就行。'",
  choices = {
    { text = "🤝 聘请老陈 (-$300签约费)", ... },
    { text = "🙏 暂时不需要", ... },
  },
}
```

### UI 弹窗规范 (赞助/教练面板)

赞助面板:
```
┌─────────────────────────────────────┐
│ 🏆 AEL 赞助中心                      │
│                                     │
│ ┌─ 当前: 铜牌赞助 ──────────────┐    │
│ │  每日收入: +$30                │    │
│ │  训练加速: +10%                │    │
│ └───────────────────────────────┘    │
│                                     │
│ ┌─ 本周任务 ────────────────────┐    │
│ │  ☑ 赢得1场比赛                 │    │
│ │  ☐ 训练总时长≥5次              │    │
│ └───────────────────────────────┘    │
│                                     │
│ 下一级: 银牌 (需要 rep≥150)          │
│                                     │
│         [ 关闭 ]                     │
└─────────────────────────────────────┘
```

- 外层: `ScrollView { width = "88%", maxWidth = 400, maxHeight = "85%", padding = {18, 16} }`
- 卡片区块: `UI.Panel { width = "100%", padding = {12, 10}, borderRadius = 8, borderWidth = 1 }`
- 任务列表: `flexShrink = 1`（允许内部滚动）

### 实现文件变更

| 文件 | 变更 |
|------|------|
| `scripts/StoryEvents.lua` | 新增 ael_scout_visit, ael_silver_offer, ael_gold_offer 事件 |
| `scripts/StoryEvents.lua` | 新增 coach_chen_intro, coach_k_intro, coach_maria_intro 事件 |
| `scripts/GameLogic.lua` | EndDay 中处理 aelDailyIncome + coach费用 |
| `scripts/GameVars.lua` | AEL等级表 + 教练数据表 |
| 新建 `scripts/AELSystem.lua` | 赞助逻辑 + 周任务检查 |
| 新建 `scripts/CoachSystem.lua` | 教练聘请/解雇/效果逻辑 |
| `scripts/UIScreens.lua` | 赞助面板 + 教练面板入口 |
| `scripts/Actions.lua` | 训练效率应用教练加成 |

---

## P3: 声望系统优化

### 目标
让声望体系从"数值积累"变为"有故事感的城市征服"，降低后期倦怠感。

### 3.1 城市解锁叙事化

#### 当前问题
`PrestigeSystem.lua` 的7个城市只有 prestige 数值门槛，缺少叙事驱动。玩家看不到"为什么要去下一个城市"。

#### 改进: 每个城市解锁时增加故事事件

```lua
CITY_UNLOCK_STORIES = {
    [2] = {  -- 内罗毕
        id = "city_nairobi_invite",
        title = "来自内罗毕的邀请",
        dialogues = {
            { speaker = "电话", text = "Hello？是Dragon Net的老板吗？我是内罗毕Star Gaming的经理。" },
            { speaker = "Star Gaming", text = "听说你们在马达加斯加做得不错。内罗毕这边的电竞市场更大，有兴趣来看看吗？" },
            { speaker = "旁白", text = "新的城市，新的机会。内罗毕的竞争更激烈，但奖金也更丰厚。" },
        },
    },
    [3] = { ... }, -- 拉各斯
    [4] = { ... }, -- 开罗
}
```

### 3.2 声望里程碑奖励可视化

#### 当前问题
声望增长看不到明确进度条，缺乏"还差多少到下一级"的直觉。

#### 改进: 声望进度条 + 里程碑预告

在主界面信息栏添加:
```
[马达加斯加] ████████░░ 80/100 → 下一站: 内罗毕 🇰🇪
```

- 进度条: `UI.Panel { width = "100%", height = 6, borderRadius = 3, backgroundColor = 底色 }`
- 填充: `UI.Panel { width = percent.."%", height = "100%", borderRadius = 3, backgroundColor = 主色 }`
- 文字: `fontSize = 11`, 放在进度条下方

### 3.3 前世回忆系统 (转生加成展示)

#### 当前问题
转生后获得的加成(`prestigeBonus`)没有明确展示，玩家不知道转生带来了什么。

#### 改进: 转生加成面板
在设置/信息页增加"前世遗产"面板，展示:
- 历史最高声望
- 当前转生加成 (初始金币+X, 训练效率+Y%, 声望获取+Z%)
- 已解锁城市列表 (带完成标记)

### UI 规范 (声望面板)

```
┌───────────────────────────────────┐
│ 🌍 声望之路                        │
│                                   │
│ 当前城市: 马达加斯加 🇲🇬             │
│ ████████████░░░░ 80/100           │
│                                   │
│ ┌─ 下一站 ─────────────────────┐  │
│ │ 🇰🇪 内罗毕                    │  │
│ │ "东非电竞之都，你准备好了吗？"  │  │
│ │ 需要: 声望 100                 │  │
│ └──────────────────────────────┘  │
│                                   │
│ ┌─ 前世遗产 ───────────────────┐  │
│ │ 转生次数: 2                    │  │
│ │ 初始金币: +$200                │  │
│ │ 训练效率: +10%                 │  │
│ └──────────────────────────────┘  │
│                                   │
│          [ 关闭 ]                  │
└───────────────────────────────────┘
```

- 外层: `ScrollView { width = "88%", maxWidth = 400, maxHeight = "85%", padding = {18, 16} }`
- 进度条容器: `height = 8, flexShrink = 0`
- 卡片: `padding = {12, 10}, borderRadius = 8`

### 实现文件变更

| 文件 | 变更 |
|------|------|
| `scripts/StoryEvents.lua` | 新增 CITY_UNLOCK_STORIES (5个城市解锁事件) |
| `scripts/PrestigeSystem.lua` | 增加 GetProgressPercent() / GetNextCityInfo() 方法 |
| `scripts/UIScreens.lua` | 主界面声望进度条 + 声望面板入口 |
| `scripts/UIManage.lua` | 声望面板弹窗 |

---

## 全局 UI 约束 (所有 P0-P3)

### 弹窗尺寸标准

| 场景 | 容器类型 | 宽度 | 最大高度 | 内边距 |
|------|---------|------|---------|--------|
| 事件对话 (已有) | ScrollView | 88%, max 400 | 90% | 18, 16 |
| 信息面板 (新增) | ScrollView | 88%, max 400 | 85% | 18, 16 |
| 轻量提示 (每日一言) | Panel | 80%, max 360 | 不限(内容短) | 24, 20 |
| 进度条/小组件 | Panel (内联) | 100% | 固定高度 | 8, 6 |

### 防溢出/防挤压规则

1. **所有可能超长的内容区域** → 使用 `ScrollView`，设置 `maxHeight`
2. **固定高度的组件** (进度条、标签栏、按钮行) → `flexShrink = 0`
3. **可变长文本** → `flexShrink = 1`，允许被滚动包裹
4. **选项按钮** → `width = "100%"`，文字超长时自动换行 (`flexWrap`)
5. **列表内容** → 使用 VirtualList 或限制显示数量 + "查看更多"

### 代码模板
```lua
-- 标准信息面板弹窗
local popup = UI.ScrollView {
    width = "88%", maxWidth = 400, maxHeight = "85%",
    padding = { 18, 16 },
    backgroundColor = C.card,
    borderRadius = 16, borderWidth = 2, borderColor = C.accentDim,
    boxShadow = { { x = 0, y = 6, blur = 25, color = { 80, 60, 40, 100 } } },
    children = {
        -- 标题
        UI.Label { text = title, fontSize = 18, fontWeight = "bold", marginBottom = 12 },
        -- 内容卡片
        UI.Panel { 
            width = "100%", padding = { 12, 10 }, borderRadius = 8,
            borderWidth = 1, borderColor = C.border, flexShrink = 0,
            children = { ... }
        },
        -- 关闭按钮
        UI.Button { 
            text = "关闭", width = "100%", marginTop = 12,
            variant = "secondary", onClick = function() ClosePopup() end,
        },
    },
}
```

---

## 实施排期

### P0 (Victor复仇弧线) — 第一批
- [ ] StoryEvents.lua: 添加 victor_spy, victor_price_war, victor_rumor, victor_challenge_preview
- [ ] Retention.lua: NARRATIVE_HOOKS 扩展到 D14
- [ ] 测试: 验证 D8-D14 每天都有叙事推进

### P1 (每日回归感知) — 第二批
- [ ] 新建/扩展模块: 每日一言文案池 + 触发逻辑
- [ ] UIScreens: 连续登录可视化条
- [ ] UIManage: 每日一言弹窗

### P2 (AEL赞助 + 教练) — 第三批
- [ ] 新建 AELSystem.lua: 赞助等级 + 周任务
- [ ] 新建 CoachSystem.lua: 教练招募/效果
- [ ] StoryEvents: 6+个新事件 (AEL 3个 + 教练 3个)
- [ ] UI: 赞助面板 + 教练面板

### P3 (声望优化) — 第四批
- [ ] StoryEvents: 5个城市解锁故事事件
- [ ] PrestigeSystem: 进度API
- [ ] UI: 声望进度条 + 声望面板

---

## 风险与注意事项

1. **文件大小**: StoryEvents.lua 已经很大，新事件应考虑是否需要拆分
2. **叙事连贯**: D8-D11的新事件必须与D12 victor_provoke 无缝衔接
3. **数值平衡**: AEL收入和教练费用需要与现有经济系统平衡
4. **存档兼容**: 新增字段(aelTier, coach等)需要有默认值，不破坏旧存档
5. **弹窗频率**: 避免新系统导致弹窗过多，用优先级队列控制每日弹窗上限
