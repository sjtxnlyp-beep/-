---@diagnostic disable: undefined-global
-- ============================================================================
-- 属性上限常量
-- ============================================================================
SKILL_CAP = 150  -- 队员技能上限（原100，提升至150增加成长空间）

-- ============================================================================
-- 7. 对话 / 事件 / 训练 状态
-- ============================================================================
dialogueIndex_ = 0
currentDialogues_ = {}
currentEvent_ = nil
eventResult_ = nil  -- 招聘/事件结果展示状态
recruitReplaceIdx_ = nil  -- 招募替换模式：选中要替换的队员索引 (nil=普通招募)

-- 打地鼠训练
TRAIN_DURATION = 12
TRAIN_GRID_COLS = 4
TRAIN_GRID_ROWS = 3
TRAIN_GRID_SIZE = TRAIN_GRID_COLS * TRAIN_GRID_ROWS

trainMember_ = nil
trainMemberIdx_ = 0
trainActive_ = false
trainTimer_ = 0
trainScore_ = 0
trainCombo_ = 0
trainMaxCombo_ = 0
trainActiveCell_ = 0
trainTargetTimer_ = 0
trainTargetTimeout_ = 1.4
trainPhase_ = "ready"
trainMode_ = "select"  -- "select" | "aim" | "quiz" | "react" | "memory" | "comm"

-- 反应训练
reactRound_ = 0
reactTotal_ = 10
reactCorrect_ = 0
reactDirection_ = ""   -- "up" | "down" | "left" | "right"
reactAnswered_ = false
reactTimer_ = 0
reactTimeLimit_ = 2.0
reactTotalTime_ = 0    -- 累计反应时间
reactCountdown_ = 0    -- 倒计时提示（"准备…"）
reactPhaseState_ = "wait" -- "wait" | "show" | "result"
reactReverse_ = false  -- 当前轮是否反向（按相反方向）
reactFlash_ = false    -- 当前轮是否闪现（短暂显示后消失）
reactFlashTimer_ = 0   -- 闪现计时
REACT_OPPOSITE = { up = "down", down = "up", left = "right", right = "left" }

-- 记忆训练
memorySequence_ = {}    -- 正确序列
memoryPlayerSeq_ = {}   -- 玩家输入序列
memoryShowIdx_ = 0      -- 当前展示到第几个
memoryRound_ = 0
memoryTotalRounds_ = 5
memoryCorrect_ = 0
memoryLen_ = 3          -- 当前序列长度（递增）
memoryShowTimer_ = 0
memoryPhaseState_ = "show" -- "show" | "input" | "result"
MEMORY_ICONS = { "⚔️", "🛡️", "💣", "🔫", "🎯", "💉", "🔥", "⚡" }

-- 路线规划（空间路径记忆）— 替代旧记忆序列的展示层
ROUTE_GRID = 5             -- 5×5 网格
routePath_ = {}            -- 正确路径格子索引列表
routePlayerPath_ = {}      -- 玩家输入的路径
routeShowIdx_ = 0          -- 当前高亮到第几步
routeShowTimer_ = 0
routePhaseState_ = "show"  -- "show" | "input" | "result"
routeRound_ = 0
routeTotalRounds_ = 5
routeCorrect_ = 0
routeLen_ = 4              -- 当前路径长度（递增）

-- 指挥通讯（信息流筛选）
commRound_ = 0
commTotalRounds_ = 8
commCorrect_ = 0
commMessages_ = {}         -- 当前轮所有滚动消息 {text, isTarget, id}
commTargetId_ = ""         -- 当前轮需要点击的目标消息id
commPhaseState_ = "wait"   -- "wait" | "scroll" | "result"
commTimer_ = 0
commSpeed_ = 1.0           -- 滚动速度倍率（递增）
commScrollY_ = 0           -- 滚动偏移量
commAnswered_ = false
commMissed_ = false        -- 是否错过了目标

-- 指挥通讯消息池
COMM_TARGETS = {
    "A点有人架枪！快来支援！",
    "B门闪光弹准备！3 2 1投！",
    "别peek了！等烟散再动！",
    "中路有狙！绕侧面走！",
    "他在换弹！现在冲！",
    "回撤回撤！他们4个人！",
    "放C4！我来掩护你！",
    "注意脚步声！有人摸过来了！",
    "集合中路！一波推了！",
    "拉开距离！他有霰弹枪！",
}
COMM_NOISE = {
    "这把经济够不够？", "有人要开麦吗？",
    "刚才那个击杀太帅了", "我去B点看看",
    "他们可能要存枪了", "我这边安全",
    "等下一波再打吧", "谁能给我让个位？",
    "我要去厕所等下", "这局我要拿MVP",
    "老板加个钟呗", "网速有点卡啊",
    "隔壁桌太吵了", "今天状态不行",
    "教练说了要打配合", "下一局换个地图？",
    "有没有人要喝水", "我耳机有杂音",
}

-- 战术问答题库（改为情境复盘格式）
QUIZ_POOL = {
    -- ── 基础战术 (1-12) ──
    { q = "三角洲中遇到敌人架枪封路，最佳战术是？",
      opts = { "正面硬冲", "绕侧翼迂回", "原地等待", "退回基地" }, ans = 2 },
    { q = "团队冲点前，指挥应先做什么？",
      opts = { "直接冲", "投掷闪光弹/烟雾弹", "全员换狙击", "分散行动" }, ans = 2 },
    { q = "残局1v3最重要的是？",
      opts = { "疯狂冲锋", "拖延时间各个击破", "藏起来不动", "退出游戏" }, ans = 2 },
    { q = "防守B点时，最有效的站位策略是？",
      opts = { "全部堆在点内", "交叉火力封锁入口", "全去A点", "蹲在角落" }, ans = 2 },
    { q = "队友被击倒，你应该？",
      opts = { "马上去救", "先清周围威胁再救", "无视继续打", "站着不动" }, ans = 2 },
    { q = "经济局该怎么买装备？",
      opts = { "全买最贵的", "统一轻装+道具", "不买直接裸奔", "只买手枪" }, ans = 2 },
    { q = "对方ECO局（经济局），我方应？",
      opts = { "放松警惕", "保持阵型不给机会", "全员冲锋", "换刀跑步" }, ans = 2 },
    { q = "狙击手被闪光弹致盲，最佳反应是？",
      opts = { "继续瞄准原位", "立刻转移位置", "丢掉狙击换手枪", "原地蹲下" }, ans = 2 },
    { q = "团队配合中，突破手的核心职责是？",
      opts = { "在后方狙击", "第一个进点获取信息", "守家看后路", "负责买道具" }, ans = 2 },
    { q = "比赛中连输3局，队长该怎么做？",
      opts = { "继续不变", "暂停调整战术和心态", "开始怪队友", "投降" }, ans = 2 },
    { q = "夜间模式下最重要的装备是？",
      opts = { "消音器", "夜视仪/热成像", "更多手雷", "跑鞋" }, ans = 2 },
    { q = "劣势方如何扳回经济？",
      opts = { "继续强买", "存枪局攒钱", "全买最贵", "随便买" }, ans = 2 },
    -- ── 中级战术 (13-22) ──
    { q = "开局前30秒，指挥最应该做的是？",
      opts = { "分配点位和职责", "让大家自由发挥", "全员蹲守出生点", "疯狂跳跃热身" }, ans = 1 },
    { q = "对方连续3轮走同一路线，你该怎么应对？",
      opts = { "也走同一路线对冲", "守株待兔不变", "提前在该路线设伏", "忽略继续自己的战术" }, ans = 3 },
    { q = "队伍中辅助位的核心价值是什么？",
      opts = { "个人击杀数最高", "补枪和道具支援", "永远冲在最前面", "负责娱乐队友" }, ans = 2 },
    { q = "比赛进入加时赛，心态管理最重要的是？",
      opts = { "告诉自己一定赢", "紧张才能超常发挥", "保持专注，一局一局打", "无所谓输赢" }, ans = 3 },
    { q = "赛前分析对手VOD录像，重点看什么？",
      opts = { "对手的皮肤好不好看", "惯用战术和站位习惯", "对手聊天说了什么", "对手的游戏设置" }, ans = 2 },
    { q = "FPS比赛中'读秒局'（时间快到了）进攻方应该？",
      opts = { "继续慢慢搜点", "果断集结强攻", "全员分散各自为战", "放弃进攻等下一局" }, ans = 2 },
    { q = "中距离对枪时，最关键的操作技巧是？",
      opts = { "疯狂扫射不松手", "控制点射节奏+身位晃动", "一直蹲着不动", "边跑边盲射" }, ans = 2 },
    { q = "团队经济领先时，最稳妥的策略是？",
      opts = { "继续正常买装", "全买最贵装备炫耀", "存钱不花", "故意送一局" }, ans = 1 },
    { q = "队内出现分歧和争吵时，指挥应该？",
      opts = { "加入争吵", "快速决断统一意见继续比赛", "沉默不管", "直接骂人" }, ans = 2 },
    { q = "赛后复盘时最有价值的内容是？",
      opts = { "谁的击杀最多", "每局的关键失误和决策", "对手太强无法赢", "不需要复盘" }, ans = 2 },
    -- ── 高级战术 (23-30) ──
    { q = "Bo3赛制中第一局大比分输了，第二局开局该怎么调整？",
      opts = { "完全推翻战术换新的", "换一到两个关键点位", "不做任何改变继续打", "直接心态崩了" }, ans = 2 },
    { q = "职业选手日常训练中，'肌肉记忆'训练主要指？",
      opts = { "去健身房锻炼", "反复练习瞄准和操作直到形成本能反应", "背诵战术手册", "看比赛录像" }, ans = 2 },
    { q = "线下赛（LAN赛）和线上赛最大的区别是？",
      opts = { "网速不同", "现场压力和氛围影响发挥", "规则不一样", "用的电脑不同" }, ans = 2 },
    { q = "战队出征国际赛事前，最需要准备的是？",
      opts = { "买好吃的零食", "研究各地区战队的风格差异", "练好英语", "换新队服" }, ans = 2 },
    { q = "一名选手状态持续低迷，教练最应该？",
      opts = { "立刻换人", "单独沟通了解原因再做决定", "当众批评激励", "不管等自己恢复" }, ans = 2 },
    { q = "电竞俱乐部的'数据分析师'主要负责什么？",
      opts = { "管理俱乐部财务", "统计和分析比赛数据优化战术", "负责选手饮食", "写新闻稿" }, ans = 2 },
    { q = "国际大赛中遇到语言不通的队伍，沟通最有效的方式是？",
      opts = { "比手画脚", "赛前制定简短英语报点暗号", "不沟通各打各的", "用翻译软件" }, ans = 2 },
    { q = "电竞选手的黄金竞技年龄通常在？",
      opts = { "10-15岁", "16-25岁", "30-40岁", "年龄无所谓" }, ans = 2 },
    -- ── 三角洲行动 & 多游戏拓展题 ──
    { q = "三角洲行动中'跑刀局'的核心策略是？",
      opts = { "全员冲锋", "省钱攒枪局装备", "只买手枪", "挂机等队友" }, ans = 2, tier = "intermediate" },
    { q = "在MOBA游戏中，'Gank'指的是什么战术？",
      opts = { "防御塔推进", "多人包抄击杀落单敌人", "全员团战", "偷龙偷Baron" }, ans = 2, tier = "basic" },
    { q = "大逃杀游戏中，决赛圈最重要的是？",
      opts = { "装备最好", "提前占据有利地形", "人数最多", "载具最多" }, ans = 2, tier = "intermediate" },
    { q = "三角洲行动中使用烟雾弹的最佳时机是？",
      opts = { "开局就扔", "掩护队友过点或拆包", "遮挡自己视线", "随便扔着玩" }, ans = 2, tier = "basic" },
    { q = "FPS游戏中'预瞄'(Pre-aim)的正确理解是？",
      opts = { "随便瞄一个方向", "提前将准星对准敌人可能出现的位置", "开镜等人", "闭眼盲狙" }, ans = 2, tier = "intermediate" },
    { q = "Dota2中'肉山'(Roshan)掉落的最重要物品是？",
      opts = { "金币", "不朽之守护(复活盾)", "神秘商店道具", "经验书" }, ans = 2, tier = "advanced" },
    { q = "CS:GO中经济系统崩溃后，应该怎样恢复？",
      opts = { "继续强买", "全队ECO省一轮再强买", "只买防弹衣", "退出游戏" }, ans = 2, tier = "intermediate" },
    { q = "PUBG中'天命圈'指的是什么？",
      opts = { "第一个安全区", "刷在自己队伍位置的安全区", "最后的决赛圈", "空投圈" }, ans = 2, tier = "basic" },
    { q = "三角洲行动里战术竞技模式的胜利条件是？",
      opts = { "击杀数最多", "完成目标或消灭对方全员", "存活时间最长", "抢到最多装备" }, ans = 2, tier = "advanced" },
    { q = "电竞比赛中'BP'阶段代表什么？",
      opts = { "比赛暂停", "Ban和Pick英雄/地图选择", "赛后分析", "观众投票" }, ans = 2, tier = "basic" },
}
quizQuestions_ = {}  -- 当局抽取的题
quizIdx_ = 1
quizCorrect_ = 0
quizTotal_ = 5  -- 默认值，实际由 GetQuizCount() 动态决定
quizAnswered_ = false
quizSelectedOpt_ = 0

-- 比赛
matchPhase_ = "intro"
matchResult_ = ""
matchLog_ = {}
matchRound_ = 0          -- 当前比赛场次 (1~3)
matchWins_ = 0           -- 已赢场次
matchTactic_ = "balanced" -- 当前战术: aggressive / defensive / balanced
matchMVP_ = nil          -- 本场MVP名字
matchNarrative_ = {}     -- 当前场叙事文本

-- 中局决策
midDecision_ = nil       -- 当前中局决策数据
midDecisionBonus_ = 0    -- 中局决策带来的加成
midDecisionNarrative_ = nil  -- 决策结果叙事文本
matchInterlude_ = nil        -- 赛间互动事件数据

-- 中局情境池（每条带 tags 标记适用的游戏类型叙事风格）
-- tags: "all"=通用, "tactical"=三角洲, "fps"=CS:GO/Valorant, "moba"=Dota2/LoL, "br"=PUBG
MID_DECISION_POOL = {
    -- ══════════ 通用场景（适用于所有游戏类型） ══════════
    { tags = "all", situation = "比赛进入中段，对方突然换了激进打法，你的MVP被集火压制！",
      choices = {
          { text = "🔄 换人替补上场", desc = "让MVP下场休息，换替补顶上", bonus = -10, narrative = "替补经验不足，但MVP保住了状态。" },
          { text = "🛡️ 全队回防保护MVP", desc = "牺牲进攻换取防守稳定", bonus = 5, narrative = "全队拉回防守，稳住了局面。" },
          { text = "🔥 以攻代守反压制", desc = "趁对方进攻阵型前压反打", bonus = 20, risk = true, narrative_win = "大胆反攻奏效，对面阵型被撕裂！", narrative_fail = "反攻失败，被对面抓住空档打了反击。" },
      },
    },
    { tags = "all", situation = "队员耳机突然出了问题，队内语音断断续续。比赛不能暂停！",
      choices = {
          { text = "📢 用手势指挥", desc = "放弃语音，改用约定好的手势", bonus = -5, narrative = "手势配合虽然不完美，但勉强维持了阵型。" },
          { text = "🎯 各自为战", desc = "每个人按训练时的习惯独立作战", bonus = 0, narrative = "各自为战，发挥看个人实力。" },
          { text = "⏸️ 假装技术问题要求暂停", desc = "冒着被判罚的风险争取时间", bonus = 15, risk = true, narrative_win = "裁判同意短暂暂停，耳机问题解决了！", narrative_fail = "裁判识破了，判罚一局，对面士气大振。" },
      },
    },
    { tags = "all", situation = "关键局！双方比分胶着，队员情绪紧张，有人开始手抖了。",
      choices = {
          { text = "😤 怒吼鼓劲", desc = "大声呐喊给队友打气", bonus = 10, narrative = "一声怒吼让队友重新集中精神！" },
          { text = "😎 冷静分析", desc = "压低声音分析敌方弱点", bonus = 8, narrative = "冷静的分析让大家找到了突破口。" },
          { text = "🃏 讲笑话缓解", desc = "用幽默化解紧张气氛", bonus = 15, risk = true, narrative_win = "一个笑话让大家放松下来，发挥超常！", narrative_fail = "笑话时机不对，队友觉得你不认真，更紧张了。" },
      },
    },
    { tags = "all", situation = "对方王牌选手突然断网了！裁判给了3分钟暂停。你怎么利用？",
      choices = {
          { text = "📋 重新部署战术", desc = "利用时间调整进攻计划", bonus = 12, narrative = "利用间歇调整了战术，更加有针对性。" },
          { text = "💪 鼓舞士气", desc = "告诉队员这是翻盘机会", bonus = 8, narrative = "队员精神振奋，准备好了最后冲刺。" },
          { text = "🕵️ 偷看对方屏幕", desc = "趁乱偷看对面的阵容配置", bonus = 25, risk = true, narrative_win = "偷偷瞥到了对方的战术板，关键信息到手！", narrative_fail = "被裁判抓个正着，警告一次，队员信心受挫。" },
      },
    },
    { tags = "all", situation = "比赛直播观众飙到了500人！弹幕疯狂刷屏，有人说'Dragon Force必胜'，也有人刷'菜鸡互啄'。",
      choices = {
          { text = "📺 把弹幕投屏给队员看", desc = "让队员看到粉丝的支持", bonus = 15, risk = true, narrative_win = "看到铺天盖地的'Dragon Force加油'，队员热血沸腾，发挥超常！", narrative_fail = "队员看到'菜鸡互啄'的弹幕，心态直接炸了。" },
          { text = "🔕 关掉弹幕专注比赛", desc = "比赛时不看弹幕，赛后再看", bonus = 8, narrative = "屏蔽外界干扰，队员全神贯注在比赛上。" },
          { text = "📢 让Kwame帮忙打字互动", desc = "让老顾客在弹幕里帮忙炒气氛", bonus = 12, narrative = "Kwame在弹幕里疯狂带节奏，观众越来越多，场面火热！" },
      },
    },
    { tags = "all", situation = "比赛直播观众发现了对手疑似使用Bug利用，弹幕炸了！裁判还没介入。",
      choices = {
          { text = "🖐️ 主动暂停申诉", desc = "向裁判举报并申请暂停", bonus = 10, narrative = "裁判确认了Bug，判对方该局负，公平得到了维护。" },
          { text = "😤 不管Bug正面赢他", desc = "用绝对实力碾压，让Bug也救不了对手", bonus = 25, risk = true, narrative_win = "即使对手用Bug也挡不住Dragon Force的碾压！弹幕疯狂刷'太强了'！", narrative_fail = "Bug优势太大，正面硬拼还是吃了亏。" },
          { text = "📱 让经理联系赛事方", desc = "场外通过官方渠道反映情况", bonus = 8, narrative = "经理联系了赛事方，虽然本局结果不变，但下局对手被警告。" },
      },
    },
    -- ══════════ 网吧主题通用场景 ══════════
    { tags = "all", situation = "比赛打到一半，你网吧突然停电了！发电机还有油，但需要有人去启动。",
      choices = {
          { text = "⚡ 亲自去启动发电机", desc = "你跑去后院拉发电机，队员自己打一分钟", bonus = -8, narrative = "发电机轰隆启动，虽然丢了一分钟指挥，但电力恢复了。" },
          { text = "📱 让Mama Blessing帮忙", desc = "喊门口卖烤鸡的Mama帮忙启动", bonus = 10, narrative = "Mama Blessing三下五除二就把发电机拉响了，你一秒都没离开指挥位！" },
          { text = "🔋 切换到手机热点硬撑", desc = "冒着高延迟继续打", bonus = 20, risk = true, narrative_win = "手机信号意外地好，延迟居然能接受！对面以为你们断网了放松警惕，反被偷袭！", narrative_fail = "手机信号太差，延迟飙到500ms，队员操作全部变形。" },
      },
    },
    { tags = "all", situation = "隔壁桌的网吧客人在大声打电话，严重影响队员集中精神。你怎么处理？",
      choices = {
          { text = "🔇 礼貌劝客人小声", desc = "用好言好语请他压低音量", bonus = 5, narrative = "客人不好意思地压低了声音，环境安静了不少。" },
          { text = "🎧 给队员换降噪耳机", desc = "拿出备用的好耳机给队员用", bonus = 15, narrative = "换上降噪耳机，外界噪音全部隔绝，队员沟通更清晰了！" },
          { text = "🚪 直接请客人出去", desc = "强硬驱逐客人保比赛环境", bonus = 20, risk = true, narrative_win = "客人虽然不爽但走了，比赛环境瞬间清净，队员发挥暴涨！", narrative_fail = "客人大吵大闹拒绝走，场面一度混乱，队员更分心了。" },
      },
    },
    { tags = "all", situation = "你注意到对手队伍用的是最新款电竞外设，而你的队员用的是网吧标配键鼠。队员有点自卑。",
      choices = {
          { text = "💪 强调技术比装备重要", desc = "告诉队员：好的剑客不挑剑", bonus = 8, narrative = "一番话让队员重拾信心：'我们用的是灵魂！'" },
          { text = "🖱️ 拿出私藏的好鼠标", desc = "把你压箱底的机械键盘拿出来给MVP用", bonus = 18, narrative = "MVP换上机械键盘后手感大变，反应速度明显提升！" },
          { text = "😏 嘲讽对手是装备党", desc = "大声说'再好的装备也救不了菜'激怒对方", bonus = 25, risk = true, narrative_win = "对面被激怒后失去冷静，连续犯错，你的心理战大获成功！", narrative_fail = "对面不吃这套，反而被激发了斗志，打得更凶了。" },
      },
    },
    { tags = "all", situation = "中场休息时，Mama Blessing端来一锅刚出炉的Jollof饭。队员们饿了一上午了。",
      choices = {
          { text = "🍚 让队员吃饱再打", desc = "吃完Mama的手艺再上场", bonus = 12, narrative = "队员吃饱喝足，精神抖擞地回到赛场，手速明显提升！" },
          { text = "⏰ 只让吃一口赶紧回来", desc = "每人两口饭就回去热手", bonus = 5, narrative = "简单补充了能量，没有浪费太多热身时间。" },
          { text = "🚫 比赛结束再吃", desc = "先饿着肚子把比赛打完", bonus = 20, risk = true, narrative_win = "空腹状态反而让队员更加专注和警觉，打出了不可思议的表现！", narrative_fail = "队员饥饿导致注意力下降，关键时刻手速跟不上。" },
      },
    },
    { tags = "all", situation = "你发现网吧的路由器过热了，网络延迟开始波动。继续打还是冒险重启路由器？",
      choices = {
          { text = "🔄 快速重启路由器", desc = "断网30秒博更稳定的连接", bonus = 20, risk = true, narrative_win = "路由器重启后网速飞起，延迟从80ms降到20ms，队员操作如丝般顺滑！", narrative_fail = "路由器启动慢了，掉线超过一分钟，回来时已经落后两局了。" },
          { text = "🧊 用冰块给路由器降温", desc = "土办法：找袋冰块放旁边物理降温", bonus = 10, narrative = "冰块降温效果不错，延迟稳定在可接受范围内。" },
          { text = "😤 忍着延迟继续打", desc = "用意志力克服网络劣势", bonus = 3, narrative = "虽然延迟不稳定，但队员展现了钢铁般的意志。" },
      },
    },
    -- ══════════ 战术射击专属（三角洲/CS:GO/Valorant） ══════════
    { tags = "tactical,fps", situation = "队伍被压在A点外，烟雾即将消散，必须做出决断！",
      choices = {
          { text = "💨 再补一颗烟强突", desc = "用最后的烟雾弹创造进攻窗口", bonus = 15, risk = true, narrative_win = "烟雾弹完美落点，队伍趁烟冲入点内一举拿下！", narrative_fail = "烟雾弹偏了，队伍暴露在交叉火力下损失惨重。" },
          { text = "🔄 转攻B点", desc = "放弃A点，快速转移到B点进攻", bonus = 10, narrative = "果断转点，对方来不及回防，B点轻松拿下。" },
          { text = "⏳ 等烟散了硬刚", desc = "正面对枪，用实力说话", bonus = 5, narrative = "虽然没了掩护，但队员枪法过硬，勉强拿下了交火。" },
      },
    },
    { tags = "tactical,fps", situation = "你发现对手有个固定套路——每次都从B点突破。要不要针对性布防？",
      choices = {
          { text = "🎯 集中B点埋伏", desc = "赌对方继续老套路", bonus = 25, risk = true, narrative_win = "对方果然还走B点，一波团灭！", narrative_fail = "对方突然改走A点，B点白守了。" },
          { text = "⚖️ A/B平均分配", desc = "稳妥策略，两点都防", bonus = 5, narrative = "两点均分防守，没有漏洞，稳扎稳打。" },
          { text = "🗣️ 放烟雾弹引诱", desc = "在A点制造动静引对方上钩", bonus = 15, risk = true, narrative_win = "烟雾弹完美引诱，对方被骗到A点！", narrative_fail = "对方没上当，直接冲B点得手。" },
      },
    },
    { tags = "tactical,fps", situation = "对方使用了从未见过的新战术，队员明显不适应！",
      choices = {
          { text = "📋 临时改变阵型应对", desc = "根据对方战术即时调整站位", bonus = 15, narrative = "灵活应变，新阵型有效克制了对方的套路。" },
          { text = "🎥 死亡回放分析弱点", desc = "利用死亡回放研究对方战术破绽", bonus = 20, risk = true, narrative_win = "通过回放找到了破绽，下一局精准破解了对方战术！", narrative_fail = "分析花了太多精力，队员精神疲惫反而影响了发挥。" },
          { text = "💪 不管战术，拼个人实力", desc = "用纯粹的枪法和反应速度硬碰硬", bonus = 5, narrative = "虽然战术上吃亏，但个人实力弥补了部分差距。" },
      },
    },
    { tags = "fps", situation = "经济局到了，队伍只有手枪和少量装备费。对面满配！",
      choices = {
          { text = "🔪 全员买甲冲脸Rush", desc = "手枪甲凯甲冲，博近战击杀攒经济", bonus = 18, risk = true, narrative_win = "手枪Rush成功！近距离打了对面一个措手不及，缴获满配武器！", narrative_fail = "刚冲出去就被对面步枪扫倒三个，经济雪上加霜。" },
          { text = "💰 全员存枪到下一局", desc = "这局直接投降保经济", bonus = 5, narrative = "牺牲一局换来下一局的全员满配，战略性放弃。" },
          { text = "🎯 只买一把主武器给枪王", desc = "把钱集中给最强的队员", bonus = 12, narrative = "枪王拿着唯一一把步枪击杀两人，虽然还是输了但攒够了下局经济。" },
      },
    },
    { tags = "tactical", situation = "三角洲突击模式，队伍需要在30秒内拆弹！掩护者只剩一人！",
      choices = {
          { text = "💣 全员扑向炸弹", desc = "不管掩护，争分夺秒拆除", bonus = 20, risk = true, narrative_win = "以最快速度拆除了炸弹，对方救援来不及！", narrative_fail = "拆弹时被背后偷袭，功亏一篑。" },
          { text = "🛡️ 先清残余再拆", desc = "确保安全再动手", bonus = 8, narrative = "多花了几秒清理残余，安全拆除了炸弹。" },
          { text = "🎭 假拆骗枪", desc = "拆一半停下来，引对方露头", bonus = 15, risk = true, narrative_win = "对方果然着急露头被打倒，随后从容拆弹！", narrative_fail = "假拆浪费了宝贵时间，炸弹爆炸了。" },
      },
    },
    -- ══════════ MOBA 专属（Dota2/英雄联盟） ══════════
    { tags = "moba", situation = "己方大龙(Roshan/Baron)被对面偷了！团队士气受到严重打击。",
      choices = {
          { text = "📢 教练暂停喊话", desc = "申请暂停，让教练重新布置战术", bonus = 12, narrative = "教练的冷静分析让队员重新振作，防守反击打得有声有色。" },
          { text = "🏰 全员龟缩高地", desc = "放弃外围资源，死守高地塔", bonus = 8, narrative = "高地防守成功，拖到了大龙buff消失。" },
          { text = "🔥 趁对方打龙残血反打", desc = "对方打完龙血量不满，强行开团", bonus = 25, risk = true, narrative_win = "对方果然残血，一波团灭翻盘！全场欢呼！", narrative_fail = "对方虽然残血但阵型完整，反打失败雪上加霜。" },
      },
    },
    { tags = "moba", situation = "对线期结束，队伍落后3000经济。打团还是继续发育？",
      choices = {
          { text = "🗡️ 抱团入侵野区", desc = "五人入侵对方野区抢资源+逼团", bonus = 18, risk = true, narrative_win = "成功入侵野区击杀落单打野，经济差一下缩小！", narrative_fail = "对方早有埋伏，团灭在对方野区，经济差越拉越大。" },
          { text = "🌾 分线带推等发育", desc = "避免正面冲突，利用兵线缩小差距", bonus = 8, narrative = "稳扎稳打分推，15分钟后装备差距缩小到可以打团。" },
          { text = "🎯 Gank对面C位", desc = "集中力量多次击杀对方核心输出", bonus = 15, risk = true, narrative_win = "成功连续击杀对面C位，打崩了对方节奏！", narrative_fail = "对面C位有队友保护，Gank失败反送人头。" },
      },
    },
    { tags = "moba", situation = "30分钟了，双方都是六神装。一波团战决定胜负的时刻到了！",
      choices = {
          { text = "🏴 开雾绕后包抄", desc = "买真视+烟雾，绕后切入对方后排", bonus = 20, risk = true, narrative_win = "雾中绕后天衣无缝，瞬间秒杀对方双C，一波推平！", narrative_fail = "被对方插眼发现，绕后变成被包饺子。" },
          { text = "🛡️ 稳守河道等对方犯错", desc = "抱团控视野，等对面先手", bonus = 10, narrative = "耐心等待终于等到对方阵型分散，抓住机会发起团战。" },
          { text = "💎 偷对方基地水晶", desc = "派一人单带偷塔，其余牵制", bonus = 25, risk = true, narrative_win = "对面被骗回防，但偷塔速度太快一锤定音！", narrative_fail = "偷塔被回防击杀，4v5团战直接崩盘。" },
      },
    },
    { tags = "moba", situation = "队伍的辅助玩家突然开始莽，连续送了两波人头。队内气氛紧张。",
      choices = {
          { text = "🤝 安慰辅助稳定心态", desc = "告诉他没关系，稳住别着急", bonus = 8, narrative = "辅助稳住心态后回归正常发挥，不再送人头了。" },
          { text = "🔄 换位置让他打别的", desc = "让辅助去单带，让稳的人来辅助", bonus = 12, narrative = "换位后团队配合明显改善，辅助在边路也找到了节奏。" },
          { text = "😡 直接开骂激励", desc = "用非洲式激将法——'你再送我就让Mama B来打'", bonus = 18, risk = true, narrative_win = "被骂醒了！辅助化悲愤为力量，后面全程神级发挥！", narrative_fail = "辅助心态彻底炸裂，直接摆烂甚至挂机。" },
      },
    },
    -- ══════════ 大逃杀专属（PUBG） ══════════
    { tags = "br", situation = "决赛圈只剩3支队伍，毒圈马上缩小，你的位置不在安全区！",
      choices = {
          { text = "🚗 开车强行冲进圈", desc = "用载具高速突入安全区", bonus = 18, risk = true, narrative_win = "载具冲锋出其不意，率先抢到最佳位置！", narrative_fail = "载具被集火打爆，队伍在毒圈边缘团灭。" },
          { text = "🚶 贴边慢慢摸进去", desc = "沿着毒圈边缘低调进圈", bonus = 10, narrative = "稳扎稳打摸进了安全区，虽然位置一般但至少安全。" },
          { text = "🎯 先打前面的队伍再进圈", desc = "消灭挡路的队伍再转移", bonus = 8, narrative = "和对手交火后虽然进了圈，但暴露了位置。" },
      },
    },
    { tags = "br", situation = "落地后发现旁边有另一支队伍也在搜物资，现在只有一把手枪和一个头盔。",
      choices = {
          { text = "🏃 立刻转移换点", desc = "放弃当前物资点跑去隔壁搜刮", bonus = 8, narrative = "成功转移到安全区域，虽然物资差点但安全发育。" },
          { text = "🔫 手枪冲脸拼了", desc = "趁对方还没搜到武器直接冲", bonus = 22, risk = true, narrative_win = "对方还没找到枪就被手枪击倒，缴获了一堆物资！", narrative_fail = "对方运气好先摸到霰弹枪，近距离一枪带走。" },
          { text = "🐍 猫在角落蹲人", desc = "让对方搜完出门再偷袭", bonus = 15, risk = true, narrative_win = "对方毫无防备走出来被伏击，轻松收割！", narrative_fail = "对方也在蹲你，双方大眼瞪小眼后被第三方渔翁得利。" },
      },
    },
    { tags = "br", situation = "空投来了！就落在队伍附近200米，但明显已经有两支队伍在赶过去。",
      choices = {
          { text = "🏎️ 飙车抢空投", desc = "全速载具冲空投，抢到就跑", bonus = 20, risk = true, narrative_win = "比其他队伍快了5秒抢到空投，拿到AWM就溜了！", narrative_fail = "三支队伍在空投处混战，被集火淘汰。" },
          { text = "🎯 远处架枪等渔翁之利", desc = "让其他队伍打起来，你在远处狙击", bonus = 15, narrative = "两支队伍果然打起来了，你远程收割残血，轻松拿分。" },
          { text = "🚫 放弃空投继续发育", desc = "不冒险，按自己的节奏来", bonus = 5, narrative = "虽然错过了空投，但队伍完整且安全地进入了决赛圈。" },
      },
    },
    { tags = "br", situation = "队友被击倒了！敌人在用倒地的队友做诱饵，等你去救。",
      choices = {
          { text = "💨 丢烟雾弹强救", desc = "烟雾掩护下冒险拉起队友", bonus = 15, risk = true, narrative_win = "烟雾弹完美覆盖，成功救起队友并撤到掩体后！", narrative_fail = "敌人直接穿烟扫射，你和队友双双倒地。" },
          { text = "🔫 先击杀架枪的敌人", desc = "不救人先打人，拿掉威胁再说", bonus = 18, risk = true, narrative_win = "精准击杀架枪的敌人，随后从容救起队友！", narrative_fail = "交火暴露位置被第三方偷袭，局面更糟。" },
          { text = "😢 战略放弃队友", desc = "保存实力不冒险，让队友掩护撤退", bonus = 3, narrative = "虽然痛苦但保住了团队核心战力，队友下一局再报仇。" },
      },
    },
}

-- ── 比赛游戏类型 ──
MATCH_GAME_TYPES = {
    { id = "delta_force", name = "三角洲行动", emoji = "🔫", narrativeStyle = "tactical",
      powerMod = 1.0, rewardMod = 1.0, desc = "经典战术射击，团队配合至上" },
    { id = "csgo",   name = "CS:GO",   emoji = "💣", narrativeStyle = "fps",
      powerMod = 1.05, rewardMod = 1.0, desc = "精准枪法与道具运用的极致考验" },
    { id = "valorant", name = "Valorant", emoji = "⚡", narrativeStyle = "fps",
      powerMod = 1.0, rewardMod = 0.95, desc = "技能与枪法的完美融合" },
    { id = "dota2",  name = "Dota 2",  emoji = "🗡️", narrativeStyle = "moba",
      powerMod = 0.95, rewardMod = 1.1, desc = "最深奥的MOBA，运营与团战的艺术" },
    { id = "lol",    name = "英雄联盟", emoji = "🏰", narrativeStyle = "moba",
      powerMod = 1.0, rewardMod = 1.05, desc = "全球最热门MOBA，操作与意识缺一不可" },
    { id = "pubg",   name = "PUBG",    emoji = "🪂", narrativeStyle = "br",
      powerMod = 0.9, rewardMod = 1.15, desc = "百人大逃杀，生存到最后才是胜利" },
}

-- ── 游戏类型专属叙事池 ──
GAME_NARRATIVE_POOLS = {
    tactical = {
        openings = {
            "队伍进入战术频道，开始部署突破路线...",
            "指挥官一声令下，小队分组包抄目标点...",
            "三角洲模式启动，每个人检查了装备和通讯...",
            "战术板上画满了箭头，进攻路线已经确定...",
        },
        highlights = {
            "%s 一个完美的闪光弹配合，撕开了防线！",
            "%s 精准卡点，连续击倒两名敌人！",
            "%s 的战术走位堪称教科书级别！",
            "%s 关键时刻补枪到位，稳住了局面！",
        },
    },
    fps = {
        openings = {
            "地图加载完成，双方选手进入准备阶段...",
            "刀局开始，先拿下手枪局奠定经济基础！",
            "队伍选择了进攻方，准备冲击A点...",
            "防守方就位，等待对手露出破绽...",
        },
        highlights = {
            "%s 一枪爆头！全场沸腾！",
            "%s 残局1v3，不可思议的翻盘！",
            "%s 的走位让对手完全摸不着头脑！",
            "%s 关键回合Ace，五杀清场！",
        },
    },
    moba = {
        openings = {
            "Ban/Pick阶段结束，双方阵容已定...",
            "兵线到达，对线期正式开始...",
            "队伍选择了团战阵容，准备抱团推进...",
            "前期发育稳定，中期团战即将到来...",
        },
        highlights = {
            "%s 在团战中完美切入，击杀对方C位！",
            "%s 抢到了关键的龙/Baron！",
            "%s 的操作秀翻全场，弹幕刷爆了！",
            "%s 带线牵制，队友趁机推掉了高地！",
        },
    },
    br = {
        openings = {
            "飞机航线确定，队伍选择了跳点...",
            "落地搜索物资，第一个圈已经刷新...",
            "队伍决定打野发育，避开早期冲突...",
            "安全区缩小，队伍开始转移阵地...",
        },
        highlights = {
            "%s 精准狙击远处移动目标，一击毙命！",
            "%s 载具突袭，打了对手一个措手不及！",
            "%s 在决赛圈的烟雾战术堪称完美！",
            "%s 绝地反杀，从被包围到团灭对手！",
        },
    },
}

-- 友谊赛（中期小型对抗）
isFriendlyMatch_ = false -- 当前是否为友谊赛
friendlyOpponent_ = nil  -- 友谊赛对手
friendlyMatchToday_ = false -- 今天是否已打过友谊赛（每日冷却）
matchTierSelect_ = false    -- 是否正在选择比赛等级

-- ── 踢馆 (Cafe Challenge) — Ban/Pick + 训练对比模式 ──
challengeActive_ = false          -- 是否在踢馆中
challengeDay_ = 0                 -- 上次踢馆的天数（每日限制）
challengeOpponent_ = nil          -- NPC 数据 {name, score, emoji, ...}
challengeWagerType_ = ""          -- "money" | "computers" | "reputation"
challengeWagerAmount_ = 0         -- 赌注数量
challengeRound_ = 0               -- 当前回合 (1-3)
challengePlayerWins_ = 0          -- 玩家胜场
challengeNPCWins_ = 0             -- NPC 胜场
challengeModes_ = {}              -- Bo3 实际比拼的3个训练模式
challengePhase_ = "select_wager"  -- "select_wager"|"ban_pick"|"round_intro"|"playing"|"round_result"|"final"
challengeDifficulty_ = 0.5        -- NPC 难度 (0.3~1.0)
challengeNPCScore_ = 0            -- 本回合 NPC 得分（用于结果展示）
challengeMultiplier_ = 1.5        -- 赌注倍率
challengeRoundResult_ = nil       -- 本轮对战结果 {mode, playerScore, npcScore, playerWin}
challengeBlockedPopup_ = nil      -- 踢馆条件不满足时的提示文本

-- Ban/Pick 相关
challengeAllModes_ = { "aim", "quiz", "memory", "react", "comm" }  -- 全部5个可选模式
challengePlayerBan_ = nil         -- 玩家 Ban 掉的模式
challengeNPCBan_ = nil            -- NPC Ban 掉的模式
challengeBanPhase_ = "player"     -- "player"|"npc"|"done" Ban阶段

-- 踢馆用模式标签/图标（与训练系统一致）
CHALLENGE_MODE_LABELS = { aim = "枪线校准", quiz = "赛后复盘", memory = "路线规划", react = "节奏反应", comm = "指挥通讯" }
CHALLENGE_MODE_EMOJIS = { aim = "🎯", quiz = "📋", memory = "🗺️", react = "⏱️", comm = "📡" }

-- 踢馆 NPC 基准分数（训练模式）
CHALLENGE_NPC_THRESHOLDS = { aim = 12, quiz = 3, memory = 3, react = 5, comm = 3 }

-- ── 每日委托任务系统（第10天后解锁） ──
---@type table|nil
dailyQuest_ = nil  -- 当前每日委托 { id, desc, goal, progress, reward, rewardDesc, checkFn, icon }
---@type table
-- P1 委托板：Day15+ 激活，3个槽位并行委托
-- [1] = 主委托（与 dailyQuest_ 同步），[2][3] = 快速委托（低门槛高频率）
dailyQuestBoard_ = {}

--- 委托任务模板池
QUEST_TEMPLATES = {
    -- ── 基础委托（Day 5+ 即可出现）──
    { id = "win_match", desc = "今日赢得1场比赛", icon = "🏆",
      goal = 1, reward = { money = 150, rep = 15 }, rewardDesc = "$150 + 声望15",
      field = "questMatchWins" },
    { id = "train_twice", desc = "今日训练2次", icon = "🎯",
      goal = 2, reward = { money = 80, rep = 10 }, rewardDesc = "$80 + 声望10",
      field = "questTrainCount" },
    { id = "earn_income", desc = "今日净收入达到$200", icon = "💰",
      goal = 200, reward = { money = 100, rep = 20 }, rewardDesc = "$100 + 声望20",
      field = "questDailyIncome" },
    { id = "upgrade_once", desc = "今日升级任意设施1次", icon = "🔧",
      goal = 1, reward = { money = 60, rep = 15 }, rewardDesc = "$60 + 声望15",
      field = "questUpgradeCount" },
    { id = "visit_market", desc = "今日逛集市并消费", icon = "🏪",
      goal = 1, reward = { money = 100, rep = 5 }, rewardDesc = "$100 + 声望5",
      field = "questMarketVisit" },
    { id = "high_mood", desc = "保持全队平均心情≥70", icon = "😊",
      goal = 70, reward = { money = 60, rep = 25 }, rewardDesc = "$60 + 声望25",
      field = "questAvgMood" },
    -- ── 新增委托 ──
    { id = "train_three", desc = "今日训练3次", icon = "💪",
      goal = 3, reward = { money = 120, rep = 15 }, rewardDesc = "$120 + 声望15",
      field = "questTrainCount", minDay = 10 },
    { id = "earn_big", desc = "今日净收入达到$500", icon = "💎",
      goal = 500, reward = { money = 200, rep = 30 }, rewardDesc = "$200 + 声望30",
      field = "questDailyIncome", minDay = 15 },
    { id = "recruit_one", desc = "今日招募1名新成员", icon = "🤝",
      goal = 1, reward = { money = 80, rep = 20 }, rewardDesc = "$80 + 声望20",
      field = "questRecruitCount" },
    { id = "watch_ad", desc = "今日观看2次赞助商短片", icon = "📺",
      goal = 2, reward = { money = 50, rep = 10 }, rewardDesc = "$50 + 声望10",
      field = "questAdWatchCount" },
    { id = "gold_trade", desc = "今日进行1次黄金交易", icon = "🥇",
      goal = 1, reward = { money = 80, rep = 10 }, rewardDesc = "$80 + 声望10",
      field = "questGoldTradeCount", minDay = 12 },
    { id = "win_two", desc = "今日赢得2场比赛", icon = "🏅",
      goal = 2, reward = { money = 300, rep = 25 }, rewardDesc = "$300 + 声望25",
      field = "questMatchWins", minDay = 20 },
    { id = "full_repair", desc = "将设备状态恢复到100%", icon = "🔩",
      goal = 100, reward = { money = 60, rep = 10 }, rewardDesc = "$60 + 声望10",
      field = "questEquipCondition" },
    { id = "team_mood_90", desc = "全队平均心情≥90", icon = "🎉",
      goal = 90, reward = { money = 100, rep = 30 }, rewardDesc = "$100 + 声望30",
      field = "questAvgMood", minDay = 15 },
    { id = "use_all_ap", desc = "今日用完所有行动点", icon = "⚡",
      goal = 1, reward = { money = 50, rep = 5 }, rewardDesc = "$50 + 声望5",
      field = "questUsedAllAP" },
}

-- P1 快速委托模板池（低门槛、5分钟可完成，用于委托板[2][3]槽位）
QUICK_QUEST_TEMPLATES = {
    { id = "q_upgrade",   desc = "升级任意设施1次",       icon = "🔧",
      goal = 1, reward = { money = 40, rep = 8 },  rewardDesc = "$40 + 声望8",
      field = "questUpgradeCount" },
    { id = "q_train",     desc = "训练队员1次",            icon = "🎯",
      goal = 1, reward = { money = 30, rep = 10 }, rewardDesc = "$30 + 声望10",
      field = "questTrainCount",
      filter = function() return #teamMembers_ >= 1 end },
    { id = "q_market",    desc = "逛集市一次",             icon = "🏪",
      goal = 1, reward = { money = 50, rep = 5 },  rewardDesc = "$50 + 声望5",
      field = "questMarketVisit" },
    { id = "q_match",     desc = "完成1场比赛（无论胜负）",icon = "🎮",
      goal = 1, reward = { money = 60, rep = 8 },  rewardDesc = "$60 + 声望8",
      field = "questMatchPlayed",
      filter = function() return #teamMembers_ >= 2 end },
    { id = "q_ad",        desc = "观看1次赞助商短片",      icon = "📺",
      goal = 1, reward = { money = 35, rep = 5 },  rewardDesc = "$35 + 声望5",
      field = "questAdWatchCount" },
    { id = "q_income50",  desc = "今日收入达到$50",        icon = "💵",
      goal = 50, reward = { money = 30, rep = 5 },  rewardDesc = "$30 + 声望5",
      field = "questDailyIncome" },
    { id = "q_mood60",    desc = "队员平均心情≥60",        icon = "😄",
      goal = 60, reward = { money = 25, rep = 12 }, rewardDesc = "$25 + 声望12",
      field = "questAvgMood",
      filter = function() return #teamMembers_ >= 1 end },
    { id = "q_equip80",   desc = "设备状态保持在80%以上",  icon = "🖥️",
      goal = 80, reward = { money = 30, rep = 8 },  rewardDesc = "$30 + 声望8",
      field = "questEquipCondition" },
}

--- 从模板池随机挑选 n 个不重复的委托（已排除指定 ID）
local function PickQuests(pool, n, excludeIds)
    local avail = {}
    local excl = {}
    for _, id in ipairs(excludeIds or {}) do excl[id] = true end
    for _, tpl in ipairs(pool) do
        if not excl[tpl.id] then
            if not tpl.filter or tpl.filter() then
                table.insert(avail, tpl)
            end
        end
    end
    -- 洗牌取前 n 个
    for i = #avail, 2, -1 do
        local j = math.random(1, i)
        avail[i], avail[j] = avail[j], avail[i]
    end
    local result = {}
    for i = 1, math.min(n, #avail) do table.insert(result, avail[i]) end
    return result
end

--- 生成每日委托（从模板池随机选1个）
function GenerateDailyQuest()
    if playerData_.day < 5 then dailyQuest_ = nil; dailyQuestBoard_ = {}; return end
    local day = playerData_.day
    -- 随机选一个委托（支持 minDay 过滤）
    local pool = {}
    for _, tpl in ipairs(QUEST_TEMPLATES) do
        if tpl.minDay and day < tpl.minDay then goto continue end
        -- 过滤：比赛相关需要有队员
        if (tpl.id == "win_match" or tpl.id == "win_two") and #teamMembers_ < 2 then goto continue end
        if (tpl.id == "train_twice" or tpl.id == "train_three") and #teamMembers_ < 1 then goto continue end
        if (tpl.id == "high_mood" or tpl.id == "team_mood_90") and #teamMembers_ < 1 then goto continue end
        table.insert(pool, tpl)
        ::continue::
    end
    if #pool == 0 then dailyQuest_ = nil; return end
    local tpl = pool[math.random(1, #pool)]
    -- 连击奖励：连续完成天数越多，额外奖励越高
    local streak = playerData_.questStreak or 0
    local streakBonus = streak >= 5 and 3.0 or streak >= 3 and 2.0 or streak >= 1 and 1.5 or 1.0
    local bonusMoney = math.floor((tpl.reward.money or 0) * (streakBonus - 1.0))
    local bonusRep = math.floor((tpl.reward.rep or 0) * (streakBonus - 1.0))
    local streakDesc = streak >= 1
        and (tpl.rewardDesc .. " + 连击x" .. streak .. " 额外$" .. bonusMoney .. "+声望" .. bonusRep)
        or tpl.rewardDesc
    dailyQuest_ = {
        id = tpl.id, desc = tpl.desc, icon = tpl.icon,
        goal = tpl.goal, progress = 0,
        reward = { money = (tpl.reward.money or 0) + bonusMoney, rep = (tpl.reward.rep or 0) + bonusRep },
        rewardDesc = streakDesc,
        field = tpl.field, claimed = false,
        streak = streak,
    }
    -- 重置追踪计数
    playerData_.questMatchWins = 0
    playerData_.questTrainCount = 0
    playerData_.questDailyIncome = 0
    playerData_.questUpgradeCount = 0
    playerData_.questMarketVisit = 0
    playerData_.questAvgMood = 0
    playerData_.questRecruitCount = 0
    playerData_.questAdWatchCount = 0
    playerData_.questGoldTradeCount = 0
    playerData_.questEquipCondition = 0
    playerData_.questUsedAllAP = 0
    playerData_.questMatchPlayed  = 0   -- 快速委托追踪：总场次（胜负均算）

    -- P1 委托板：Day15+ 生成2个快速委托槽位
    dailyQuestBoard_ = {}
    if day >= 15 then
        -- 槽1：主委托（与 dailyQuest_ 同步引用）
        dailyQuestBoard_[1] = dailyQuest_
        -- 槽2-3：从快速委托池随机挑2个（不与主委托重叠）
        local mainId = dailyQuest_ and dailyQuest_.id or ""
        local quickPicks = PickQuests(QUICK_QUEST_TEMPLATES, 2, { mainId })
        for i, qt in ipairs(quickPicks) do
            dailyQuestBoard_[i + 1] = {
                id = qt.id, desc = qt.desc, icon = qt.icon,
                goal = qt.goal, progress = 0,
                reward = qt.reward,
                rewardDesc = qt.rewardDesc,
                field = qt.field, claimed = false,
                isQuick = true,   -- 标记为快速委托
            }
        end
    end
end

--- 更新单个委托的进度（心情/收入/设备等特殊字段）
local function UpdateQuestProgress(q)
    if not q or q.claimed then return end
    q.progress = playerData_[q.field] or 0
    local mood_ids = { high_mood=true, team_mood_90=true, q_mood60=true }
    if mood_ids[q.id] and #teamMembers_ > 0 then
        local total = 0
        for _, m in ipairs(teamMembers_) do total = total + (m.mood or 50) end
        q.progress = math.floor(total / #teamMembers_)
    end
    if q.id == "earn_income" or q.id == "earn_big" or q.id == "q_income50" then
        q.progress = playerData_.questDailyIncome or 0
    end
    if q.id == "full_repair" or q.id == "q_equip80" then
        q.progress = playerData_.equipCondition or 0
    end
    if q.id == "use_all_ap" then
        q.progress = (playerData_.actionPoints or 0) <= 0 and 1 or 0
    end
end

--- 检查委托是否完成
function CheckQuestProgress()
    UpdateQuestProgress(dailyQuest_)
    -- 同步更新委托板快速委托进度
    for i = 2, #(dailyQuestBoard_ or {}) do
        UpdateQuestProgress(dailyQuestBoard_[i])
    end
end

--- 领取主委托奖励
function ClaimQuestReward()
    if not dailyQuest_ or dailyQuest_.claimed then return end
    if dailyQuest_.progress < dailyQuest_.goal then return end
    dailyQuest_.claimed = true
    local r = dailyQuest_.reward
    if r.money then playerData_.money = playerData_.money + r.money end
    if r.rep then playerData_.reputation = playerData_.reputation + r.rep end
    -- 更新连击
    playerData_.questStreak = (playerData_.questStreak or 0) + 1
    local streakMsg = ""
    if playerData_.questStreak >= 2 then
        streakMsg = " 🔥连击x" .. playerData_.questStreak .. "！明日委托奖励UP！"
    end
    PlaySFX("coin_collect")
    AddLog("✅ 委托完成「" .. dailyQuest_.desc .. "」！奖励：" .. dailyQuest_.rewardDesc .. streakMsg)
end

--- P1 领取委托板快速委托奖励（slot=2或3）
function ClaimBoardQuestReward(slot)
    local q = dailyQuestBoard_ and dailyQuestBoard_[slot]
    if not q or q.claimed then return end
    if q.progress < q.goal then return end
    q.claimed = true
    local r = q.reward
    if r.money then playerData_.money = playerData_.money + r.money end
    if r.rep   then playerData_.reputation = playerData_.reputation + r.rep end
    PlaySFX("coin_collect")
    AddLog("✅ 快速委托「" .. q.desc .. "」完成！奖励：" .. q.rewardDesc)
end

-- ── 分店随机事件池 ──
BRANCH_EVENTS = {
    { id = "robbery", name = "🚨 分店遭遇抢劫", prob = 0.08,
      desc = "分店遭到小偷光顾，损失了一些现金。",
      effect = function(br) local loss = math.floor((br.income or 40) * 2); playerData_.money = math.max(0, playerData_.money - loss); return "💸 " .. (br.name or "分店") .. "被盗，损失$" .. loss end },
    { id = "boom", name = "📈 分店生意爆满", prob = 0.12,
      desc = "分店今日客流暴增，额外收入！",
      effect = function(br) local bonus = math.floor((br.income or 40) * 1.5); playerData_.money = playerData_.money + bonus; return "🎉 " .. (br.name or "分店") .. "客流爆满，额外赚$" .. bonus end },
    { id = "breakdown", name = "🔧 分店设备故障", prob = 0.10,
      desc = "分店一台电脑烧了主板，需要修理费。",
      effect = function(br) local cost = 60; playerData_.money = math.max(0, playerData_.money - cost); return "🔧 " .. (br.name or "分店") .. "设备故障，维修费$" .. cost end },
    { id = "inspection", name = "📋 卫生检查合格", prob = 0.08,
      desc = "分店通过了卫生检查，获得好评。",
      effect = function(br) playerData_.reputation = playerData_.reputation + 5; return "✅ " .. (br.name or "分店") .. "卫生检查合格！声望+5" end },
    { id = "referral", name = "🗣️ 老顾客介绍新客", prob = 0.10,
      desc = "分店常客带了朋友来，以后会多一点收入。",
      effect = function(br) br.income = (br.income or 40) + 5; return "📢 " .. (br.name or "分店") .. "口碑扩散，日收入永久+$5" end },
    { id = "power_out", name = "⚡ 停电半天", prob = 0.06,
      desc = "当地停电，分店半天无法营业。",
      effect = function(br) local loss = math.floor((br.income or 40) * 0.5); playerData_.money = math.max(0, playerData_.money - loss); return "⚡ " .. (br.name or "分店") .. "停电，少赚$" .. loss end },
}

--- 每日结算触发分店事件（每家分店独立判定）
function TriggerBranchEvents()
    local branches = playerData_.branches or {}
    if #branches == 0 then return end
    for _, br in ipairs(branches) do
        for _, evt in ipairs(BRANCH_EVENTS) do
            if math.random() < evt.prob then
                local msg = evt.effect(br)
                if msg then AddLog(msg) end
                break  -- 每家分店每天最多一个事件
            end
        end
    end
end

-- ── 比赛分级系统（必须在 BuildActionCard 之前定义！）──
MATCH_TIERS = {
    { name = "🏚️ 贫民窟周赛", cost = 50,  basePower = 100, powerFrac = 0.35, powerRange = { 0.50, 0.85 }, rewardMult = 1.0,
      unlock = function() return true end, unlockDesc = "" },
    { name = "🏙️ 城市锦标赛", cost = 120, basePower = 200, powerFrac = 0.35, powerRange = { 0.75, 1.05 }, rewardMult = 1.8,
      unlock = function() return playerData_.reputation >= 200 and (playerData_.tierWins or {})[1] and playerData_.tierWins[1] >= 3 end,
      unlockDesc = "声望≥200 + T1赢3场" },
    { name = "🌍 全非邀请赛", cost = 300, basePower = 350, powerFrac = 0.35, powerRange = { 0.75, 1.05 }, rewardMult = 3.0,
      unlock = function() return playerData_.reputation >= 350 and (playerData_.tierWins or {})[2] and playerData_.tierWins[2] >= 3 end,
      unlockDesc = "声望≥350 + T2赢3场" },
}
scoutedRound_ = 0           -- 已侦查的回合号（0=未侦查）
matchOpponents_ = {
    { name = "尼日利亚·闪电队", power = 120, style = "快攻型", emoji = "⚡" },
    { name = "肯尼亚·猎豹队",   power = 180, style = "均衡型", emoji = "🐆" },
    { name = "南非·暗影战队",    power = 220, style = "防守反击", emoji = "🦅" },
    { name = "Gold Net · Victor", power = 280, style = "快攻型", emoji = "🏆", boss = true },
}
currentTournamentTier_ = 0  -- 当前正在进行的锦标赛级别 (0=非锦标赛)

-- 多级锦标赛体系：从地区到世界之巅
TOURNAMENT_TIERS = {
    {
        id = "regional", name = "🏘️ 三角洲地区赛", icon = "🏘️",
        cost = 300, repReq = 100, teamReq = 2, powerReq = 0, prevWinReq = nil,
        prize = 500, repReward = 20, desc = "三角洲州十六强争夺，从这里开始！",
        unlockDesc = "声望≥100 + 2名队员",
        transition = { title = "🏘️ 三角洲地区赛", sub = "我们镇最强，先证明给邻居们看！" },
        winText = "🏆 地区冠军！Dragon Force 称霸三角洲！",
        loseText = "💪 地区赛失利，但积累了宝贵经验。",
        opponents = {
            { name = "瓦里镇·铁壳网吧队", power = 130,  style = "防守反击", emoji = "🛡️" },
            { name = "阿萨巴·街机少年队", power = 180, style = "快攻型", emoji = "🕹️" },
            { name = "贝宁城·学院精英队", power = 240, style = "均衡型", emoji = "🎓" },
        },
    },
    {
        id = "national", name = "🇳🇬 尼日利亚全国赛", icon = "🇳🇬",
        cost = 600, repReq = 300, teamReq = 3, powerReq = 150, prevWinReq = "regional",
        prize = 1200, repReward = 40, desc = "三十六州精英齐聚拉各斯，争夺国家荣誉！",
        unlockDesc = "地区赛冠军 + 声望≥300 + 3名队员 + 战力≥150",
        transition = { title = "🇳🇬 全国锦标赛", sub = "拉各斯，我们来了！全尼日利亚都在看！" },
        winText = "🏆 全国冠军！Dragon Force 是尼日利亚最强！",
        loseText = "💔 全国赛止步，但全尼日利亚都记住了我们的名字。",
        opponents = {
            { name = "拉各斯·City Gamers",   power = 220, style = "快攻型", emoji = "🌆" },
            { name = "阿布贾·首都战队",       power = 290, style = "均衡型", emoji = "🏛️" },
            { name = "卡诺·北方雄鹰",         power = 360, style = "防守反击", emoji = "🦅" },
            { name = "哈科特港·石油之子",     power = 420, style = "快攻型", emoji = "⛽", boss = true },
        },
    },
    {
        id = "continental", name = "🌍 全非洲锦标赛", icon = "🌍",
        cost = 1200, repReq = 600, teamReq = 4, powerReq = 250, prevWinReq = "national",
        prize = 3000, repReward = 80, desc = "十二个国家，三十二支劲旅，非洲之巅只有一个位置！",
        unlockDesc = "全国赛冠军 + 声望≥600 + 4名队员 + 战力≥250",
        transition = { title = "🌍 全非洲锦标赛", sub = "从铁皮屋到非洲之巅——Dragon Force 出征！" },
        winText = "🏆 非洲冠军！Dragon Force 征服整个非洲大陆！",
        loseText = "💔 非洲赛遗憾落幕，但我们的名字传遍了整个大陆。",
        opponents = {
            { name = "加纳·阿克拉风暴",         power = 320, style = "快攻型", emoji = "🌪️" },
            { name = "肯尼亚·内罗毕猎豹",       power = 400, style = "均衡型", emoji = "🐆" },
            { name = "南非·开普敦暗影",          power = 480, style = "防守反击", emoji = "🦇" },
            { name = "Gold Net · Victor",        power = 580, style = "快攻型", emoji = "💀", boss = true },
        },
    },
    {
        id = "world", name = "🌐 世界总决赛", icon = "🌐",
        cost = 2500, repReq = 1000, teamReq = 5, powerReq = 350, prevWinReq = "continental",
        prize = 8000, repReward = 200, desc = "全球二十四支顶级战队，电竞圣殿的终极对决！\n从铁皮屋顶到世界舞台——这是最后的征途。",
        unlockDesc = "非洲赛冠军 + 声望≥1000 + 5名队员 + 战力≥350",
        transition = { title = "🌐 世界总决赛", sub = "全世界都将记住——从非洲走出的传奇！" },
        winText = "👑 世界冠军！！Dragon Force 站上世界之巅！！！",
        loseText = "🌟 世界赛虽未夺冠，但全世界都见证了非洲电竞的崛起！",
        opponents = {
            { name = "🇰🇷 首尔·StarForce",       power = 420, style = "快攻型", emoji = "⭐" },
            { name = "🇨🇳 上海·东方龙",           power = 500, style = "均衡型", emoji = "🐲" },
            { name = "🇺🇸 洛杉矶·Team Phantom",  power = 580, style = "防守反击", emoji = "👻" },
            { name = "🇧🇷 圣保罗·Favela Kings",  power = 650, style = "快攻型", emoji = "👑", boss = true },
        },
    },
}

-- NanoVG 过场 overlay
nvgContext_ = nil
nvgFont_ = -1

-- 语音播放系统
audioScene_ = nil
audioNode_ = nil
voiceSoundSource_ = nil

-- BGM 播放系统
bgmSource_ = nil
currentBGM_ = ""

BGM_PATHS = {
    title     = "audio/bgm/bgm_title.ogg",
    manage    = "audio/bgm/bgm_manage.ogg",
    train     = "audio/bgm/bgm_train.ogg",
    match     = "audio/bgm/bgm_match.ogg",
    victory   = "audio/bgm/bgm_victory.ogg",
    event     = "audio/bgm/bgm_event.ogg",
    gameover  = "audio/bgm/bgm_gameover.ogg",
    night     = "audio/bgm/bgm_night.ogg",
    market    = "audio/bgm/bgm_market.ogg",
    challenge = "audio/bgm/bgm_challenge.ogg",
    invest    = "audio/bgm/bgm_invest.ogg",
}

SFX_PATHS = {
    click     = "audio/sfx/sfx_click.ogg",
    upgrade   = "audio/sfx/sfx_upgrade.ogg",
    coin      = "audio/sfx/sfx_coin.ogg",
    gunshot   = "audio/sfx/sfx_gunshot.ogg",
    hit       = "audio/sfx/sfx_hit.ogg",
    miss      = "audio/sfx/sfx_miss.ogg",
    victory   = "audio/sfx/sfx_victory.ogg",
    defeat    = "audio/sfx/sfx_defeat.ogg",
    event     = "audio/sfx/sfx_event.ogg",
    recruit   = "audio/sfx/sfx_recruit.ogg",
    day_end   = "audio/sfx/sfx_day_end.ogg",
    train_hit = "audio/sfx/sfx_train_hit.ogg",
    -- v7 社区枢纽音效
    well_water   = "audio/sfx/well_water.ogg",
    coffee_brew  = "audio/sfx/coffee_brew.ogg",
    jukebox_play = "audio/sfx/jukebox_play.ogg",
    road_build   = "audio/sfx/road_build.ogg",
    -- v8 沉浸感增强音效
    coin_collect = "audio/sfx/sfx_coin_collect.ogg",
    level_up     = "audio/sfx/sfx_level_up.ogg",
    day_dawn     = "audio/sfx/sfx_day_dawn.ogg",
    negative     = "audio/sfx/sfx_negative.ogg",
    page_turn    = "audio/sfx/sfx_page_turn.ogg",
    crowd_cheer  = "audio/sfx/sfx_crowd_cheer.ogg",
}

-- ============================================================================
-- 语音文件映射（按对话文本前缀匹配）
-- ============================================================================
VOICE_MAP = {
    -- 第一章
    ["飞机穿过厚厚的云层"] = "audio/voice/ch1_dialogue_1_旁白.ogg",
    ["你掏出手机看了看银行余额"] = "audio/voice/ch1_dialogue_2_旁白.ogg",
    ["出租车在坑坑洼洼的土路"] = "audio/voice/ch1_dialogue_3_旁白.ogg",
    ["嘿！你是新来的中国人"] = "audio/voice/ch1_dialogue_4_房东Musa.ogg",
    ["Dragon Net Cafe，正式开业"] = "audio/voice/ch1_dialogue_5_旁白.ogg",
    -- 第二章
    ["开业一周，生意不温不火"] = "audio/voice/ch2_dialogue_1_旁白.ogg",
    ["消息一传开，网吧瞬间爆满"] = "audio/voice/ch2_dialogue_2_旁白.ogg",
    ["你发现他们不只是玩得好"] = "audio/voice/ch2_dialogue_3_旁白.ogg",
    -- 第三章
    ["Dragon Force 的名声开始"] = "audio/voice/ch3_dialogue_1_旁白.ogg",
    ["B站上开始出现"] = "audio/voice/ch3_dialogue_2_旁白.ogg",
    ["你知道，代练只是过渡"] = "audio/voice/ch3_dialogue_3_旁白.ogg",
    -- 第四章
    ["距离全非洲大赛还有两周"] = "audio/voice/ch4_dialogue_1_旁白.ogg",
    ["发电机轰隆轰隆地响着"] = "audio/voice/ch4_dialogue_2_旁白.ogg",
    ["窗外是一片漆黑"] = "audio/voice/ch4_dialogue_3_旁白.ogg",
    ["你站在角落看着他们"] = "audio/voice/ch4_dialogue_4_旁白.ogg",
    -- 第五章
    ["比赛日到了"] = "audio/voice/ch5_dialogue_1_旁白.ogg",
    ["大屏幕上滚动着"] = "audio/voice/ch5_dialogue_2_旁白.ogg",
    ["决赛即将开始"] = "audio/voice/ch5_dialogue_3_旁白.ogg",
    -- Snake 语音（用于剧情事件描述）
    ["在游戏里杀人比在街上干净"] = "audio/voice/snake_lines_1_Snake.ogg",
    ["你这个垃圾！连个跑刀都不会"] = "audio/voice/snake_lines_2_Snake.ogg",
    ["游戏是我唯一不用靠拳头的地方"] = "audio/voice/snake_lines_3_Snake.ogg",
}

--- 根据对话文本查找语音文件
function FindVoice(text)
    for prefix, path in pairs(VOICE_MAP) do
        if string.find(text, prefix, 1, true) then
            return path
        end
    end
    return nil
end

-- ============================================================================
-- 7.5 网吧实时经营状态
-- ============================================================================
cafeEvents_ = {}       -- 当天网吧事件列表 [{def, resolved, result, day}]
cafeEventsDay_ = 0     -- 已生成事件的天数（防止重复生成）
pendingCafeCount_ = 0  -- 待处理事件计数（用于按钮角标）
cafeViewOpen_ = false  -- 网吧实况面板是否展开
cafeActionUsedDay_ = 0 -- 已消耗行动点的天数（每天最多消耗1次）
restoreManageScroll_ = nil -- 管理界面滚动位置恢复 {x, y, frames}
restoreCafePopupScroll_ = nil -- 网吧弹窗内滚动位置恢复 {x, y, frames}

-- ── 升级计时器 ──
activeUpgrade_ = nil       -- 正在升级中的项目 key (string|nil)
upgradeTimeLeft_ = 0       -- 升级剩余时间（秒），-1表示跨日建造模式
upgradeTotalTime_ = 0      -- 升级总时间（秒）
upgradeCost_ = nil          -- 正在升级的费用（用于完成日志）
upgradeCompletionDay_ = nil -- 跨日建造：目标完工天数（nil=当天完成）
upgradeSynergiesBefore_ = nil -- 升级前联动快照

-- ── 弹窗优先级队列（每日上限控制） ──
POPUP_DAILY_MAX = 3             -- 非核心弹窗每日上限
popupsShownToday_ = 0           -- 今日已展示非核心弹窗计数
popupsCountDay_ = 0             -- 计数器对应的天数（跨天自动重置）

--- 检查是否还能展示非核心弹窗；若到达上限返回 false
--- 核心弹窗（日结/离线/转生）不走此检查
---@return boolean
function CanShowPopup()
    local day = playerData_ and playerData_.day or 0
    if popupsCountDay_ ~= day then
        popupsCountDay_ = day
        popupsShownToday_ = 0
    end
    return popupsShownToday_ < POPUP_DAILY_MAX
end

--- 消耗一次弹窗展示配额
function ConsumePopupSlot()
    local day = playerData_ and playerData_.day or 0
    if popupsCountDay_ ~= day then
        popupsCountDay_ = day
        popupsShownToday_ = 0
    end
    popupsShownToday_ = popupsShownToday_ + 1
end

-- ============================================================================
-- 8. 阿布杜大叔黄金市场播报系统
-- ============================================================================

--- 阿布杜大叔语录池（按金价趋势分类）
--- signal: "up"=涨信号, "down"=跌信号, "neutral"=模糊/观望
UNCLE_ABDU_QUOTES = {
    -- 涨信号
    { signal = "up", text = "孩子，今天是个好日子！英国人心情好，他们买石油，我们就有钱买金！你也该买！" },
    { signal = "up", text = "我做这行二十年，今天这走势我见过——会涨。信不信由你。" },
    { signal = "up", text = "昨晚电视说奈拉又要贬值了。金子不会骗你，现金会！" },
    { signal = "up", text = "刚才有个大客户一口气买了50盎司。大钱跟进的时候，你要跟着走。" },
    { signal = "up", text = "石油管道炸了！物资紧缺，金价看涨。快点决定，慢了别怨我。" },
    { signal = "up", text = "瓦坎达维尔今天过节，黄金首饰店排长队。需求上来了，价格能不涨吗？" },
    { signal = "up", text = "昨天没买的人今天后悔了吧？不过今天买还不算太晚。" },
    -- 跌信号
    { signal = "down", text = "孩子们，今天别碰金！石油部长又换人了，市场慌得很。" },
    { signal = "down", text = "港口那边传来消息，大量黄金从刚果进来了。供应多了，价格嘛……" },
    { signal = "down", text = "最近买金的人都在亏钱。你要是有仓位，考虑考虑吧。" },
    { signal = "down", text = "隔壁的交易商昨晚跑路了。这行情……我也害怕。" },
    { signal = "down", text = "总统演讲说经济很好，不需要买黄金避险。你懂这意味着什么。" },
    { signal = "down", text = "下雨天没人来买金。没人买，价格就上不去。" },
    { signal = "down", text = "你看看街上那些金店，都在打折甩卖。这不是好信号。" },
    -- 模糊/观望
    { signal = "neutral", text = "今天我不说。我今天累了。你自己看着办。" },
    { signal = "neutral", text = "有人说涨，有人说跌。我活了六十年，唯一确定的是——没人能确定。" },
    { signal = "neutral", text = "你来得正好。不过今天……嗯，我也在想。要不明天再聊？" },
    { signal = "neutral", text = "刚才有两拨人来问我，一拨要买，一拨要卖。你说我该信谁？" },
    { signal = "neutral", text = "我侄子说涨，我老婆说跌。家里为这个吵了一晚上。" },
    { signal = "neutral", text = "这行情就像拉各斯的天气——你永远不知道下一秒会怎样。" },
    -- 特殊（主线联动触发）
    { signal = "win_bonus", text = "哎呀！你们队赢了比赛！恭喜恭喜！来，今天大叔给你个内部消息——明天金价肯定涨！" },
    { signal = "lose_comfort", text = "输了比赛？没事没事。金子不在乎谁赢谁输，它只在乎有没有人要买。" },
    { signal = "low_cash", text = "孩子，你口袋里快没钱了吧？要不……把金子卖点？大叔不骗你，先活下去再说。" },
}

--- 获取今日阿布杜大叔播报
--- @return string 大叔语录文本
--- @return string 信号类型("up"/"down"/"neutral")
function GetUncleAbduQuote()
    local day = playerData_.day or 1
    local curPrice = GetGoldPrice(day)
    local nextPrice = GetGoldPrice(day + 1)

    -- 主线联动特殊触发
    if (playerData_.money or 0) < 300 and (playerData_.goldOunces or 0) >= 0.5 then
        local q = UNCLE_ABDU_QUOTES[#UNCLE_ABDU_QUOTES]  -- low_cash
        return q.text, "down"
    end
    if playerData_.lastMatchResult == "win" and (playerData_.lastMatchDay or 0) == day then
        for _, q in ipairs(UNCLE_ABDU_QUOTES) do
            if q.signal == "win_bonus" then return q.text, "up" end
        end
    end
    if playerData_.lastMatchResult == "lose" and (playerData_.lastMatchDay or 0) == day then
        for _, q in ipairs(UNCLE_ABDU_QUOTES) do
            if q.signal == "lose_comfort" then return q.text, "neutral" end
        end
    end

    -- 根据明日金价走势选信号方向（75%准确率，25%故意误导增加趣味性）
    local trueSignal
    if nextPrice > curPrice * 1.05 then
        trueSignal = "up"
    elseif nextPrice < curPrice * 0.95 then
        trueSignal = "down"
    else
        trueSignal = "neutral"
    end

    -- 25%概率给出误导信号（大叔也会看走眼）
    local seed = (day * 31 + 7) % 100
    local signal = trueSignal
    if seed < 25 then
        local others = {}
        for _, s in ipairs({"up", "down", "neutral"}) do
            if s ~= trueSignal then others[#others + 1] = s end
        end
        signal = others[((day * 13) % #others) + 1]
    end

    -- 从对应信号池中确定性选取（相同天数=相同语录）
    local pool = {}
    for _, q in ipairs(UNCLE_ABDU_QUOTES) do
        if q.signal == signal then pool[#pool + 1] = q end
    end
    if #pool == 0 then return "……", "neutral" end
    local idx = (day * 17 + 3) % #pool + 1
    ---@diagnostic disable-next-line: return-type-mismatch
    return pool[idx].text, signal
end

-- ============================================================================
-- 9. 入口
-- ============================================================================
-- Start() / Stop() 已移至 main.lua 入口文件

