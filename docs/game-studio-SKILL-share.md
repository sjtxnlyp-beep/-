---
name: game-studio
description: "游戏开发工作室框架 - 49个专业角色、72个工作流技能，模拟真实游戏工作室的协作体系。适用场景：(1) 游戏概念构思和设计 (2) 架构规划和决策 (3) Sprint计划和生产追踪 (4) 设计评审和代码审查 (5) 团队协作和工作流程编排。当用户需要专业游戏开发流程、团队分工协作、设计文档规范化时激活此Skill。"
version: 1.0.0
---

# Game Studio Framework
*基于 Claude Code Game Studios (18k+ stars) 改编*

## 核心理念

**你不是一个人，你有一整个工作室。**

这个框架给你的AI会话赋予真实游戏工作室的结构——有总监把控愿景、部门主管负责各自领域、专家做实际工作。每个角色有明确职责、升级路径和质量门控。

---

## 工作室层级

### Tier 1 — 总监 (战略层)

| 角色 | 职责 |
|------|------|
| **creative-director** | 守护游戏愿景，确保所有决策符合创意方向 |
| **technical-director** | 技术架构和代码质量，平衡创新与可行性 |
| **producer** | 生产进度和跨部门协调 |

### Tier 2 — 部门主管

| 角色 | 职责 |
|------|------|
| **game-designer** | 游戏系统设计、玩法平衡 |
| **lead-programmer** | 技术实现、代码架构 |
| **art-director** | 美术风格、视觉规范 |
| **narrative-director** | 叙事内容、对话系统 |
| **qa-lead** | 测试计划、质量把控 |

### Tier 3 — 专家

**程序**: gameplay-programmer, engine-programmer, ai-programmer, network-programmer, ui-programmer

**设计**: systems-designer, level-designer, economy-designer, ux-designer

**美术**: technical-artist, sound-designer

**其他**: writer, world-builder, prototyper, performance-analyst, qa-tester, accessibility-specialist

### 引擎专家

| 引擎 | 主导角色 | 专长 |
|------|---------|------|
| **Godot 4** | godot-specialist | GDScript, Shaders, GDExtension |
| **Unity** | unity-specialist | DOTS/ECS, Shaders/VFX, Addressables |
| **Unreal 5** | unreal-specialist | GAS, Blueprints, Replication |

---

## 核心工作流

### 1. 游戏概念阶段

**`/brainstorm`** — 引导式概念构思

使用专业工作室的构思技术：
- **Verb-First Design**: 从核心动词出发(build/fight/explore/solve/create)
- **Mashup Method**: 两种意外元素组合产生独特钩子
- **MDA逆向设计**: 从目标情感反向推导机制

**流程**:
1. 情感探索 — 什么时刻真正打动过你？
2. 品味画像 — 哪3款游戏你花最多时间？为什么？
3. 概念生成 — 产出3个不同方向的候选
4. 核心循环设计 — 30秒循环 + 5分钟循环
5. 输出: `design/gdd/game-concept.md`

---

### 2. 设计系统阶段

**`/design-system`** — 系统GDD编写

每个MVP系统单独一份GDD，包含：
- 机制(Mechanics)
- 动态(Dynamics)
- 美学(Aesthetics)
- 成功指标
- 风险和依赖

**`/map-systems`** — 系统分解
将概念拆解为独立系统，识别系统间依赖

**`/art-bible`** — 视觉规范
定义视觉风格、色彩、图标规范

---

### 3. 架构规划阶段

**`/create-architecture`** — 主架构蓝图
产出: `docs/architecture.md` + Required ADR列表

**`/architecture-decision`** — 技术决策记录
每个重要决策一篇ADR，格式：
Title
Status
Context
Decision
Consequences
**`/architecture-review`** — 架构覆盖率验证
---
### 4. Sprint生产阶段
**`/create-epics`** — 从系统映射到Epic
**`/create-stories`** — Epic拆解为可执行Story
**`/dev-story`** — 开发单个Story
阅读Story AC
设计方案（2-4选项+优缺点）
用户决策
实施
单元测试
标记完成
**`/sprint-plan`** — Sprint规划
- 容量评估
- 优先级排序
- 风险识别
---
### 5. 评审流程
**`/design-review`** — 设计评审
检查点：
- 是否符合游戏愿景？
- 系统间是否一致？
- 是否有遗漏场景？
**`/code-review`** — 代码评审
- 编码规范合规
- 性能考虑
- 安全最佳实践
**`/gate-check`** — 阶段门控
验证进入下一阶段的条件
---
## 协作原则
**不是自动驾驶，是协作伙伴**
每个角色遵循严格协作协议：
1. **提问** — 先问问题再提方案
2. **呈现选项** — 展示2-4个选项及优缺点
3. **你决定** — 用户始终做决定
4. **草稿** — 先展示工作再定稿
5. **审批** — 没有你的签字不写任何东西
---
## 质量门控
### Hooks (自动化验证)
| Hook | 触发 | 验证内容 |
|------|------|----------|
| validate-commit | git commit | 硬编码值、TODO格式、JSON有效性 |
| validate-push | git push | 保护分支警告 |
| validate-assets | 资源变更 | 命名规范、JSON结构 |
| detect-gaps | 会话开始 | 检测空白项目、缺失设计文档 |
### 路径规则
| 路径 | 强制执行 |
|------|----------|
| `src/gameplay/**` | 数据驱动、delta time、无UI引用 |
| `src/core/**` | 热路径零分配、线程安全 |
| `src/ai/**` | 性能预算、可调试性 |
| `src/networking/**` | 服务器权威、版本化消息 |
| `src/ui/**` | 无游戏状态所有权、本地化就绪 |
---
## 设计哲学
- **MDA框架** — Mechanics, Dynamics, Aesthetics分析
- **自我决定理论** — 自主性、能力感、归属感驱动玩家动机
- **心流设计** — 挑战-技能平衡维持参与度
- **Bartle玩家类型** — 受众定位和验证
- **验证驱动开发** — 测试先行
---
## 评审模式
三种模式，可在`/start`或`production/review-mode.txt`中设置：
| 模式 | 说明 |
|------|------|
| **Full** | 每个关键步骤都有总监评审 |
| **Lean** | 仅在阶段门控时评审（推荐） |
| **Solo** | 无总监评审，最快速 |
---
## 快速开始
启动会话
/start — 选择你的位置（无想法/模糊概念/清晰概念/已有工作）
/brainstorm — 构思游戏概念
/design-system — 编写系统GDD
/create-architecture — 架构规划
/sprint-plan — Sprint规划
/dev-story — 开始开发
---
## 角色调用示例
当你需要特定专家时，可以这样调用：
[creative-director]
"这个设计方向是否符合游戏愿景？"

[game-designer]
"这个战斗系统的平衡性如何？"

[qa-lead]
"这个功能的测试计划是什么？"
---
## 文件结构
project/
├── design/
│ └── gdd/ # 游戏设计文档
├── src/ # 源代码
├── assets/ # 美术、音频资源
├── tests/ # 测试套件
├── docs/ # 技术文档、ADR
├── prototypes/ # 废弃原型（与src隔离）
└── production/ # Sprint计划、里程碑
└── review-mode.txt
---
*改编自 [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios)，18k+ stars，MIT License*
