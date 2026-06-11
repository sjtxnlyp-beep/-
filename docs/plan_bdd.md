# BDD功能规格输出计划

## 目标
为《非洲代练大亨》输出5份专业的BDD Gherkin .feature文件，覆盖游戏的全部改进维度。

## 专家团队
| 专家 | 领域 | 输出文件 |
|------|------|----------|
| 玩法系统策划 | 核心循环、数值、经营决策、员工/客户系统、赛事 | gameplay.feature |
| UI/UX设计师 | 界面重构、信息架构、交互优化、新手引导 | ui_ux.feature |
| 剧情/叙事设计师 | 非洲故事、NPC故事线、多结局、事件系统 | narrative.feature |
| 技术架构师 | 稳定性、性能、存档、错误处理 | technical.feature |
| 增长运营专家 | 留存、裂变、社区、商业化 | growth.feature |

## BDD文件格式
使用标准Gherkin语法：
- Feature / Scenario / Given / When / Then / And / Background
- 每个场景包含可验收的验收标准
- 使用标签 @P0/@P1/@P2 标注优先级
- 使用Scenario Outline + Examples实现参数化场景

## 信息输入
每个专家都获得：
1. 游戏背景信息（TapTap页面数据、玩家反馈）
2. 之前的分析报告核心结论
3. 需要改进的具体功能点

## 执行方式
5个专家并行工作，各自输出.feature文件到 /mnt/agents/output/bdd/ 目录
