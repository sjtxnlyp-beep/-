---@diagnostic disable: undefined-global
-- ============================================================================
-- CityTeamData.lua — 各城市特色队员数据
-- 每个城市有 4~5 个独特角色，包含特色故事、性格、天赋和城市文化元素
-- ============================================================================

local CityTeamData = {}

-- ============================================================================
-- 拉各斯 (Lagos) — 尼日利亚商业首都，2000万人口的超级城市
-- 主题：街头商业嗅觉、Nollywood文化、科技速成、密集竞争
-- ============================================================================
CityTeamData.lagos = {
    { name = "Eze",     talent = 88, mood = 100, skill = 10, trait = "雅虎男孩·洗白传奇", emoji = "🧑🏿",
      desc = "前网络诈骗犯金盆洗手，键盘技术出神入化", fee = 150, special = true,
      perk = "读心术", perkDesc = "预判对手行动路线，反应时间-20%", perkBonus = 12,
      flaw = "旧习难改", flawDesc = "偶尔会接到'旧朋友'电话影响训练", flawPenalty = 6,
      story = "Eze曾靠键盘日入万金。入狱两年后他说：'同样的手速，为什么不用来打比赛？合法的钱花着更香。'他的APM是队里最快的。" },
    { name = "Blessing", talent = 82, mood = 100, skill = 18, trait = "市场女王·砍价达人", emoji = "👩🏿",
      desc = "Balogun市场最强砍价手，现在砍敌人", fee = 80, special = true,
      perk = "资源节约", perkDesc = "精打细算的习惯，团队装备消耗-15%", perkBonus = 8,
      flaw = "话太多", flawDesc = "打比赛时忍不住碎碎念，偶尔泄露战术", flawPenalty = 4,
      story = "Blessing在Balogun市场卖了20年布料，砍价从不输。第一次进网吧是避雨，结果发现'杀敌人比杀价更爽'。她的经济运营全队最强。" },
    { name = "DJ Spinall", talent = 94, mood = 85, skill = 6, trait = "高烧DJ·节奏之王", emoji = "🧑🏿",
      desc = "Afrobeats DJ转型选手，靠节奏感预判枪线", fee = 120, special = true,
      perk = "节奏大师", perkDesc = "BPM般精准的射击节奏，连射精度+20%", perkBonus = 14,
      flaw = "夜猫体质", flawDesc = "白天训练总打瞌睡，上午比赛状态差", flawPenalty = 5,
      story = "DJ Spinall在维多利亚岛的夜店月入200万奈拉。他说'打碟和打枪一样——节奏对了，全场都是你的。'但凌晨三点的训练他总是迟到。" },
    { name = "Aisha",   talent = 86, mood = 100, skill = 14, trait = "大学生·代码女巫", emoji = "👩🏿",
      desc = "拉各斯大学CS系学霸，把游戏当算法题解", fee = 60, special = true,
      perk = "数据分析", perkDesc = "用数学分析对手行为模式，战术策划+", perkBonus = 9,
      flaw = "期末危机", flawDesc = "考试周前两天完全无法参赛", flawPenalty = 3,
      story = "Aisha白天写Python晚上跑刀。她开发了一个Excel表格精确计算每把枪的DPS/性价比。队友嫌她'太理性'但每次Ban/Pick都听她的。" },
    { name = "Okoro",   talent = 78, mood = 100, skill = 25, trait = "黄包车夫·钢铁双腿", emoji = "🧑🏿",
      desc = "从小跑Danfo小巴的车夫，超强耐力型选手", fee = 40, special = true,
      perk = "永不疲倦", perkDesc = "加时赛体力不减，长时间比赛表现稳定", perkBonus = 7,
      flaw = "文化不高", flawDesc = "不识英文界面，需要队友帮忙翻译技能描述", flawPenalty = 3,
      story = "Okoro每天跑12小时Danfo赚饭钱。来网吧是因为隔壁的空调漏风。他完全不认识英文但摸索出了一套独特操作。" },
}

-- ============================================================================
-- 内罗毕 (Nairobi) — 东非硅谷，科技创业氛围浓厚
-- 主题：科技极客、M-Pesa支付、Safari冒险精神、马拉松耐力
-- ============================================================================
CityTeamData.nairobi = {
    { name = "Wanjiku", talent = 91, mood = 100, skill = 8, trait = "黑客少女·数据幽灵", emoji = "👩🏿",
      desc = "iHub孵化器17岁天才，破解游戏反外挂系统后被招安", fee = 130, special = true,
      perk = "系统精通", perkDesc = "深谙游戏底层机制，Bug利用+15%", perkBonus = 11,
      flaw = "社恐", flawDesc = "线下赛面对观众会紧张，大场面发挥失常", flawPenalty = 7,
      story = "Wanjiku 14岁就进了iHub实习。她给反外挂团队提交了3个漏洞报告，条件是'别封我号'。线上她是恐怖的存在，线下她说话都结巴。" },
    { name = "Kipchoge", talent = 80, mood = 100, skill = 30, trait = "退役马拉松·耐力怪物", emoji = "🧑🏿",
      desc = "前马拉松青训队员，游戏耐力远超常人", fee = 70, special = true,
      perk = "长跑意志", perkDesc = "连续训练不掉状态，疲劳恢复速度+30%", perkBonus = 9,
      flaw = "节奏单一", flawDesc = "习惯匀速，突然加速的战术执行力差", flawPenalty = 4,
      story = "Kipchoge跑了8年马拉松没进国家队。教练说他'耐力好但爆发差'——这评价在电竞圈反而是优点。他能连续训练8小时不走神。" },
    { name = "Nyambura", talent = 87, mood = 95, skill = 12, trait = "M-Pesa女·金融直觉", emoji = "👩🏿",
      desc = "M-Pesa代理商之女，对数字异常敏感", fee = 90, special = true,
      perk = "数字敏锐", perkDesc = "精确计算游戏内经济/血量/弹药", perkBonus = 10,
      flaw = "商人思维", flawDesc = "总想计算收益，队伍亏本时积极性下降", flawPenalty = 5,
      story = "Nyambura从小帮妈妈数M-Pesa的流水。她能精确记住每个对手剩余血量和弹匣数。队友说她是'人形计算器'。" },
    { name = "Kamau",   talent = 85, mood = 100, skill = 15, trait = "Safari向导·鹰眼猎人", emoji = "🧑🏿",
      desc = "马赛马拉前向导，肉眼锁敌如追踪猎物", fee = 100, special = true,
      perk = "猎人视野", perkDesc = "发现隐藏敌人的能力强，侦察+20%", perkBonus = 12,
      flaw = "城市不适", flawDesc = "室内待久了烦躁，需要定期'放风'", flawPenalty = 4,
      story = "Kamau在马赛马拉当了5年导游，能在200米外发现灌木里的花豹。他说'找人比找豹子简单多了'。枪法不算顶尖但从不会被偷袭。" },
}

-- ============================================================================
-- 阿克拉 (Accra) — 加纳文化教育中心，大学城
-- 主题：高等教育、Highlife音乐、可可种植、Pan-African思想
-- ============================================================================
CityTeamData.accra = {
    { name = "Kwame",   talent = 83, mood = 100, skill = 20, trait = "哲学系·策略大脑", emoji = "🧑🏿",
      desc = "加纳大学哲学系研究生，用博弈论打比赛", fee = 70, special = true,
      perk = "策略天才", perkDesc = "对战时读取对手策略模式的能力强", perkBonus = 10,
      flaw = "想太多", flawDesc = "关键时刻过度分析导致犹豫", flawPenalty = 5,
      story = "Kwame论文写的是'纳什均衡在FPS博弈中的应用'。导师以为他疯了——直到他拿了校赛冠军。他的预判准得像读了对方的论文。" },
    { name = "Abena",   talent = 90, mood = 100, skill = 9, trait = "可可公主·甜蜜杀手", emoji = "👩🏿",
      desc = "可可种植园千金，手指灵活如剥可可豆", fee = 110, special = true,
      perk = "精细操作", perkDesc = "手指灵活度极高，微操能力+15%", perkBonus = 11,
      flaw = "出身优越", flawDesc = "吃苦耐劳精神不足，连续输几场就想回家", flawPenalty = 6,
      story = "Abena家有500英亩可可园。她从小剥可可豆练出了精细手指控制力。'你知道最好的可可豆有多难剥吗？比这游戏难多了。'" },
    { name = "Yaw",     talent = 76, mood = 100, skill = 28, trait = "Highlife老灵魂·稳健流", emoji = "🧑🏿",
      desc = "Highlife乐队鼓手转型，节奏感带来稳定输出", fee = 50, special = true,
      perk = "韵律稳定", perkDesc = "输出如节拍器般稳定，波动极小", perkBonus = 7,
      flaw = "不够激进", flawDesc = "太稳导致进攻性不足，缺少翻盘能力", flawPenalty = 3,
      story = "Yaw打了15年Highlife鼓。他的射击频率像节拍器一样精准。教练说'他不会carry但永远不会崩'。队伍需要这种定海神针。" },
    { name = "Ama",     talent = 89, mood = 90, skill = 11, trait = "推特女王·舆论武器", emoji = "👩🏿",
      desc = "10万粉丝大V，把垃圾话变成心理战武器", fee = 95, special = true,
      perk = "心理战", perkDesc = "赛前垃圾话动摇对手心态", perkBonus = 9,
      flaw = "太在意评价", flawDesc = "被黑了会影响心情，需要安慰", flawPenalty = 5,
      story = "Ama在推特有10万粉丝专门发游戏meme。她的赛前垃圾话能让对面队长气到手抖。但只要有人黑她，她三天不想训练。" },
    { name = "Mensah",  talent = 81, mood = 100, skill = 22, trait = "图书馆员·百科全书", emoji = "🧑🏿",
      desc = "大学图书馆管理员，记忆力惊人的情报型选手", fee = 55, special = true,
      perk = "过目不忘", perkDesc = "记住所有地图细节和对手习惯", perkBonus = 8,
      flaw = "体力差", flawDesc = "久坐不动体质弱，长时间对抗手指酸痛", flawPenalty = 3,
      story = "Mensah能背出图书馆所有书的位置。他同样能背出每张地图的每个角落和计时。对手说'和他打像开了透视'。" },
}

-- ============================================================================
-- 达喀尔 (Dakar) — 大西洋畔港口城市，贸易枢纽
-- 主题：摔跤（Laamb）传统、法语文化、渔业、塞内加尔雄狮足球
-- ============================================================================
CityTeamData.dakar = {
    { name = "Moussa",  talent = 93, mood = 90, skill = 7, trait = "摔跤冠军·蛮力碾压", emoji = "🧑🏿",
      desc = "Laamb摔跤退役冠军，暴力流打法震慑全场", fee = 140, special = true,
      perk = "肉搏之王", perkDesc = "近战/霰弹枪伤害加成，正面刚枪极强", perkBonus = 14,
      flaw = "不服管教", flawDesc = "冠军脾气大，不听指挥要自己带节奏", flawPenalty = 7,
      story = "Moussa是达喀尔竞技场三连冠摔跤手。退役后他说'打人不犯法的只有游戏'。每次正面对枪他都喊'Laamb！'队友说他像冲过来的公牛。" },
    { name = "Fatou",   talent = 86, mood = 100, skill = 16, trait = "渔家女·潮汐预言", emoji = "👩🏿",
      desc = "渔民之女，看潮汐长大的时机掌控者", fee = 75, special = true,
      perk = "时机把握", perkDesc = "进攻时机判断精准如潮汐", perkBonus = 10,
      flaw = "季节性", flawDesc = "渔季时偶尔需要帮家里忙", flawPenalty = 3,
      story = "Fatou跟着父亲出海15年，判断潮汐是她的本能。在游戏里她总能找到完美时机——'Push的时机和出海一样，早一秒死，晚一秒没鱼。'" },
    { name = "Pape",    talent = 84, mood = 100, skill = 19, trait = "法语教师·精确语法", emoji = "🧑🏿",
      desc = "法语老师兼职选手，用语法般精确的走位", fee = 65, special = true,
      perk = "精确执行", perkDesc = "战术执行误差极小，配合成功率高", perkBonus = 8,
      flaw = "刻板", flawDesc = "遇到意外情况应变能力差", flawPenalty = 4,
      story = "Pape白天教法语语法，晚上练枪法。他说'语法有规则，走位也有规则'。每个走位都像写句子一样精确——但对面不按语法出牌他就懵了。" },
    { name = "Aminata", talent = 88, mood = 95, skill = 13, trait = "时装设计师·视觉猎手", emoji = "👩🏿",
      desc = "Dakar时装周新锐设计师，超强色彩敏感度", fee = 100, special = true,
      perk = "色彩感知", perkDesc = "在复杂场景中极快发现敌人", perkBonus = 11,
      flaw = "完美主义", flawDesc = "对队友配合不满时会吐槽影响士气", flawPenalty = 5,
      story = "Aminata设计的衣服上过Vogue Africa。她说'在花花绿绿的地图里找人？这不就是配色练习吗？'她发现敌人的速度快得离谱。" },
}

-- ============================================================================
-- 开普敦 (Cape Town) — 非洲电竞之都，基础设施最佳
-- 主题：桌山极限运动、种族融合、顶级电竞基建、葡萄酒文化
-- ============================================================================
CityTeamData.capetown = {
    { name = "van Wyk", talent = 95, mood = 85, skill = 5, trait = "退役职业·堕落天才", emoji = "🧑🏿",
      desc = "前非洲冠军赛MVP，因丑闻退役的争议天才", fee = 200, special = true,
      perk = "巅峰经验", perkDesc = "大赛经验丰富，决赛圈表现+25%", perkBonus = 15,
      flaw = "酗酒习惯", flawDesc = "偶尔宿醉训练，状态极不稳定", flawPenalty = 9,
      story = "van Wyk曾是非洲最强选手，MVP拿到手软。一场假赛丑闻毁了一切。现在他在开普敦的酒吧喝酒度日。你给他一个机会——但他能不能抓住？" },
    { name = "Zanele",  talent = 89, mood = 100, skill = 12, trait = "桌山跑酷·空中飞人", emoji = "👩🏿",
      desc = "桌山跑酷达人，超强空间感和反应力", fee = 110, special = true,
      perk = "空间天赋", perkDesc = "3D空间感知极强，跳跃/飞行地图优势", perkBonus = 12,
      flaw = "肾上腺素依赖", flawDesc = "平淡局缺乏动力，只有翻盘局才兴奋", flawPenalty = 5,
      story = "Zanele在桌山上跑酷被警察追过三次。她的3D空间感知力惊人——'判断跳点距离和判断楼顶缝隙一样，差一厘米就死。'" },
    { name = "Thabo",   talent = 87, mood = 100, skill = 20, trait = "IT工程师·延迟克星", emoji = "🧑🏿",
      desc = "光纤工程师选手，网络知识带来独特优势", fee = 90, special = true,
      perk = "网络优化", perkDesc = "帮队伍优化网络设置，全队延迟-10ms", perkBonus = 8,
      flaw = "书呆子", flawDesc = "社交能力弱，队伍凝聚力贡献低", flawPenalty = 3,
      story = "Thabo给半个开普敦铺过光纤。他帮你网吧把延迟从50ms优化到12ms。'你知道38ms差距意味着什么吗？意味着你先开枪。'" },
    { name = "Lindiwe", talent = 92, mood = 100, skill = 9, trait = "双语解说·舞台女王", emoji = "👩🏿",
      desc = "英祖鲁双语电竞解说，表演型选手", fee = 130, special = true,
      perk = "领袖气场", perkDesc = "语音指挥清晰有力，全队配合度+", perkBonus = 11,
      flaw = "要面子", flawDesc = "不愿承认失误，复盘时总为自己辩护", flawPenalty = 5,
      story = "Lindiwe原本是电竞解说，但她总觉得'选手太菜了我上我也行'。结果她真行。指挥声音洪亮，队友说像被妈妈骂着打赢的。" },
    { name = "Sipho",   talent = 79, mood = 100, skill = 27, trait = "葡萄酒侍酒·味觉替换", emoji = "🧑🏿",
      desc = "斯泰伦博斯侍酒师，把品酒的专注力移植到游戏", fee = 60, special = true,
      perk = "专注力", perkDesc = "持续专注时间极长，马拉松赛制优势", perkBonus = 7,
      flaw = "佛系", flawDesc = "不够有胜负欲，常说'开心就好'", flawPenalty = 4,
      story = "Sipho品酒能分辨200种葡萄。他的专注力用在游戏上就是'连续盯6小时屏幕不走神'。但他从不着急——'好酒慢慢品，好游戏慢慢打。'" },
}

-- ============================================================================
-- 金沙萨 (Kinshasa) — 音乐之城，终极隐藏城市
-- 主题：Rumba/Soukous音乐、刚果河文化、钻石/钴矿、Sapeur绅士
-- ============================================================================
CityTeamData.kinshasa = {
    { name = "Papa Wemba Jr", talent = 96, mood = 80, skill = 4, trait = "Rumba王子·乐感操控", emoji = "🧑🏿",
      desc = "传奇音乐家之孙，节奏DNA天赋爆表", fee = 180, special = true,
      perk = "Rumba节拍", perkDesc = "以音乐节拍控制战斗节奏，全队发挥提升", perkBonus = 14,
      flaw = "贵族做派", flawDesc = "必须穿名牌训练服否则拒绝上场", flawPenalty = 7,
      story = "他爷爷是刚果Rumba之王。Papa Wemba Jr继承了完美的节奏感——'4/4拍是射击，切分是走位，副歌是Rush。'但他的名牌运动服费用惊人。" },
    { name = "Mama Congo", talent = 84, mood = 100, skill = 22, trait = "刚果河女船长·导航员", emoji = "👩🏿",
      desc = "货船船长的寡妇接班人，全局掌控型指挥", fee = 85, special = true,
      perk = "全局视野", perkDesc = "如同在河上观察水流，全局战术观强", perkBonus = 10,
      flaw = "大姐脾气", flawDesc = "对年轻队员太严厉，偶尔吵架", flawPenalty = 4,
      story = "丈夫去世后她接管了刚果河上的货船。管理20个水手的她说'管一个电竞队比管水手简单多了'。但她训话时年轻人会怕。" },
    { name = "Sapeur",  talent = 88, mood = 100, skill = 14, trait = "绅士联盟·优雅杀手", emoji = "🧑🏿",
      desc = "金沙萨时尚绅士(Sapeur)，用优雅动作碾压对手", fee = 120, special = true,
      perk = "绅士风范", perkDesc = "优雅的操作风格增加观赏性，粉丝收入+20%", perkBonus = 9,
      flaw = "虚荣心", flawDesc = "输给穿着不好看的队伍时心情大跌", flawPenalty = 6,
      story = "Sapeur花三个月工资买一套西装。他打游戏也一样——'赢要赢得漂亮，丑陋的操作我宁可不用。'观众爱他，但有时候漂亮操作不如实用操作。" },
    { name = "Kabila",  talent = 92, mood = 90, skill = 8, trait = "钴矿童工·暗夜之眼", emoji = "🧑🏿",
      desc = "前矿场童工出身，在黑暗中练就了超常视力", fee = 100, special = true,
      perk = "暗夜视觉", perkDesc = "暗光场景中发现敌人更快", perkBonus = 12,
      flaw = "信任障碍", flawDesc = "童年阴影导致不信任权威，磨合期长", flawPenalty = 6,
      story = "Kabila 8岁就在钴矿坑里挖矿。黑暗中他学会了用微光辨别一切。逃出矿场后他来到网吧——'至少这里的黑暗是屏幕上的。'" },
    { name = "Fifi",    talent = 85, mood = 100, skill = 17, trait = "联合国翻译·多线程大脑", emoji = "👩🏿",
      desc = "联合国驻刚果翻译员的女儿，多任务处理能力惊人", fee = 95, special = true,
      perk = "多线处理", perkDesc = "同时处理多个信息源，不会遗漏报点", perkBonus = 10,
      flaw = "过度敏感", flawDesc = "对言语攻击敏感，被喷后需要时间恢复", flawPenalty = 4,
      story = "Fifi从小在联合国维和营地长大，会说法语、林加拉语、英语、斯瓦希里语。她能同时听四个队友报点还不乱——'比同声传译简单多了。'" },
}

-- ============================================================================
-- 起始城市：瓦坎达维尔 (wakandaville)
-- 这些角色定义在 InitReset.lua 中，这里不重复定义
-- 但提供额外候选人（用于转生回来时补充新面孔）
-- ============================================================================
CityTeamData.wakandaville_extra = {
    { name = "Zizi",    talent = 79, mood = 100, skill = 20, trait = "裁缝学徒·细针功夫", emoji = "👩🏿",
      desc = "裁缝店学徒，缝纫练出的手指精度惊人", fee = 45, special = true,
      perk = "微操精准", perkDesc = "精细操作能力强，关键击杀率高", perkBonus = 7,
      flaw = "害羞", flawDesc = "线下赛紧张，声音太小队友听不到报点", flawPenalty = 3,
      story = "Zizi在老板娘的裁缝店学了3年，一根针穿0.3mm的洞。她用同样的精准操作鼠标，第一次上手就展现了可怕的爆头率。" },
    { name = "Iron Boy", talent = 87, mood = 95, skill = 7, trait = "废品站·铁手浪子", emoji = "🧑🏿",
      desc = "废品站长大的孤儿，徒手拆机器练出钢铁双手", fee = 70, special = true,
      perk = "钢铁之手", perkDesc = "手部力量大，长时间操作不抖", perkBonus = 9,
      flaw = "野路子", flawDesc = "自学成才，正规战术配合需要时间适应", flawPenalty = 5,
      story = "Iron Boy在废品站徒手拆解电器长大。他的手指力量和稳定性超强——'拆一台旧CRT比打一局游戏难'。他没有正经名字，大家都叫他Iron Boy。" },
    { name = "Pastor K", talent = 74, mood = 100, skill = 30, trait = "牧师·全能辅助", emoji = "🧑🏿",
      desc = "年轻牧师玩家，温暖的心让全队士气高涨", fee = 35, special = true,
      perk = "精神领袖", perkDesc = "鼓励队友，全队心情恢复加速", perkBonus = 8,
      flaw = "道德底线", flawDesc = "拒绝使用任何'卑鄙'战术（阴人/蹲点）", flawPenalty = 4,
      story = "Pastor K说'上帝让我来这里是为了拯救这些孩子的心灵——顺便打几场比赛'。他的辅助意识一流但坚决不蹲坑。" },
}

-- ============================================================================
-- 对外接口
-- ============================================================================

--- 获取指定城市的候选队员池
---@param cityId string 城市ID
---@return table candidates 候选队员列表
function CityTeamData.GetCandidatesForCity(cityId)
    ---@diagnostic disable-next-line: return-type-mismatch
    return CityTeamData[cityId] or {}
end

--- 获取所有城市队员数据（用于显示/调试）
---@return table allData
function CityTeamData.GetAllCities()
    return {
        "lagos", "nairobi", "accra", "dakar", "capetown", "kinshasa"
    }
end

return CityTeamData
