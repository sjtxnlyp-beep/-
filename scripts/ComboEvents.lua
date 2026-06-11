---@diagnostic disable: undefined-global
-- ============================================================================
-- 角色组合事件系统 (Character Combo Events)
-- 当特定角色组合同时在队时，有概率触发免AP惊喜剧情
-- 完成后解锁永久被动加成
-- ============================================================================
local M = {}

-- ============================================================================
-- 组合事件数据定义（8组）
-- ============================================================================
M.COMBO_EVENTS = {
    {
        id = "kofi_grace",
        member1 = "Kofi", member2 = "Grace",
        minDay = 8, dailyChance = 0.25,
        title = "🎨 街头传说",
        icon = "🎨",
        dialogues = {
            { speaker = "Kofi", text = "Grace！你那个涂鸦太帅了吧——把整条巷子都变成画廊了！" },
            { speaker = "Grace", text = "嘿嘿……其实我想画你打比赛的样子，那个专注的表情特别好看。" },
            { speaker = "Kofi", text = "哈？画我？那你得加上火焰特效！我操作的时候键盘都冒烟！" },
            { speaker = "Grace", text = "我教你调色，你教我你那些本地俚语怎么样？公平交易！" },
            { speaker = "narrator", text = "从那天起，训练室的墙上多了一幅涂鸦——两个少年站在非洲大陆的轮廓前，背后是升起的太阳。" },
            { speaker = "narrator", text = "💡 文化知识：特维语谚语 'Obi nkyere abofra Nyame' —— 无需教孩子认识上帝。意思是真理不言自明。特维语(Twi)是加纳阿坎族最广泛使用的语言。" },
        },
        lore = { id = "twi_proverb", category = "culture", title = "特维语谚语",
                 text = "'Obi nkyere abofra Nyame' —— 无需教孩子认识上帝（真理不言自明）。特维语(Twi)是加纳阿坎族最广泛使用的语言之一，约有900万母语使用者。" },
        reward = {
            type = "passive", id = "street_legends",
            name = "街头传说",
            desc = "Kofi+Grace 同时在队时训练效率+10%",
            effect = { trainBonus = 0.10, members = { "Kofi", "Grace" } },
        },
    },
    {
        id = "snake_bigjoe",
        member1 = "Snake", member2 = "Big Joe",
        minDay = 10, dailyChance = 0.22,
        title = "🌙 夜市兄弟",
        icon = "🌙",
        dialogues = {
            { speaker = "Snake", text = "Joe 哥，今晚跟我去夜市走一趟？听说有人低价卖二手显卡。" },
            { speaker = "Big Joe", text = "……上次你说'低价'，我差点被人追着跑三条街。" },
            { speaker = "Snake", text = "这次不一样！我有内线消息！而且……万一遇到麻烦，不是还有你嘛。" },
            { speaker = "Big Joe", text = "（叹气）走吧。但如果又是骗局，你请我吃一周suya烤肉。" },
            { speaker = "narrator", text = "那晚确实遇到了骗子——但 Big Joe 一站起来，对方就怂了。Snake 趁机反将一军，用三言两语套出了对方的真货来源。" },
            { speaker = "Snake", text = "看到没？我负责动脑，你负责站着。完美组合！" },
            { speaker = "narrator", text = "💡 文化知识：Suya 是西非最流行的街头烤肉，起源于豪萨族的游牧文化。用花生粉、辣椒和各种香料腌制后炭烤，是尼日利亚夜市的标志性美食。" },
        },
        lore = { id = "suya_culture", category = "food", title = "Suya 烤肉",
                 text = "Suya 是西非最流行的街头烤肉小吃，起源于尼日利亚北部豪萨族(Hausa)的游牧传统。牛肉串用Yaji粉（花生粉+辣椒+姜+丁香混合）腌制后炭烤。如今已传播到整个西非，是夜市必备美食。" },
        reward = {
            type = "passive", id = "night_market_bros",
            name = "夜市兄弟",
            desc = "Snake+Big Joe 同时在队时比赛逆风翻盘概率+8%",
            effect = { comebackBonus = 0.08, members = { "Snake", "Big Joe" } },
        },
    },
    {
        id = "kofi_snake",
        member1 = "Kofi", member2 = "Snake",
        minDay = 12, dailyChance = 0.20,
        title = "⚡ 死对头赌约",
        icon = "⚡",
        dialogues = {
            { speaker = "Snake", text = "小子，你那手速是快，但论脑子……你还嫩了点。" },
            { speaker = "Kofi", text = "少来！上次训练赛我可是赢了你三把！" },
            { speaker = "Snake", text = "那是我让的。不信？赌一把——这周谁训练提升多，输的人请全队吃 Jollof Rice。" },
            { speaker = "Kofi", text = "赌就赌！我怕你啊！等着破产吧！" },
            { speaker = "narrator", text = "接下来一周，训练室的灯再没在凌晨两点前关过。两人的技术以肉眼可见的速度飙升——至于谁请了客……那又是另一个故事了。" },
            { speaker = "narrator", text = "💡 文化知识：Jollof Rice 是西非最具代表性的主食，每个国家都声称自己的版本最正宗——尤其是尼日利亚和加纳之间的'Jollof War'（佐洛夫饭之战）堪称非洲最友好的美食战争。" },
        },
        lore = { id = "jollof_war", category = "food", title = "Jollof Rice 之战",
                 text = "Jollof Rice 是西非各国的灵魂主食。番茄、洋葱、辣椒炖煮的一锅饭，简单却令人上瘾。尼日利亚和加纳数十年来争论谁的Jollof更正宗——这场'Jollof War'已成为非洲最著名的文化梗之一。" },
        reward = {
            type = "passive", id = "rivalry_spark",
            name = "死对头的火花",
            desc = "Kofi+Snake 同时训练时经验×1.2",
            effect = { trainMultiplier = 1.2, members = { "Kofi", "Snake" } },
        },
    },
    {
        id = "grace_mamab",
        member1 = "Grace", member2 = "Mama B",
        minDay = 9, dailyChance = 0.25,
        title = "💪 女性力量",
        icon = "💪",
        dialogues = {
            { speaker = "Grace", text = "Mama B，你的烤鸡店需要新招牌吗？我可以帮你设计！" },
            { speaker = "Mama B", text = "哦？你这孩子，有心了。来来来，坐下先吃碗花生汤。" },
            { speaker = "Grace", text = "（边吃边画）这个……用明亮的橙色和绿色，再加上您招牌烤鸡的轮廓……" },
            { speaker = "Mama B", text = "真漂亮……像极了我年轻时在阿克拉市场看到的安卡拉布。" },
            { speaker = "Grace", text = "那我把安卡拉花纹也融进去！Mama B 的烤鸡店——全城最有非洲味的招牌！" },
            { speaker = "narrator", text = "新招牌挂上的那天，整条街的人都来围观。Mama B 高兴地多给了队里每人一份加量烤鸡——队员们的心情前所未有地好。" },
            { speaker = "narrator", text = "💡 文化知识：安卡拉(Ankara)是西非标志性的蜡染布料，鲜艳的几何图案和色彩代表着非洲的活力与创造力。每种花纹都有名字和寓意，是服装、装饰和艺术的重要元素。" },
        },
        lore = { id = "ankara_fabric", category = "culture", title = "安卡拉蜡染布",
                 text = "安卡拉(Ankara)是西非最具辨识度的纺织品，使用蜡染技术制作的彩色棉布。每种花纹都有专属名字和文化寓意——'总统的妻子'代表高贵，'ABC'代表教育。如今已走向全球时尚舞台。" },
        reward = {
            type = "passive", id = "womens_power",
            name = "女性力量",
            desc = "Grace+Mama B 同时在队时全队心情衰减-15%",
            effect = { moodDecayReduction = 0.15, members = { "Grace", "Mama B" } },
        },
    },
    {
        id = "bigjoe_thunder",
        member1 = "Big Joe", member2 = "Thunder",
        minDay = 14, dailyChance = 0.20,
        title = "🛡️ 铁壁双塔",
        icon = "🛡️",
        dialogues = {
            { speaker = "Thunder", text = "Joe 哥，你以前真的是拳击手？" },
            { speaker = "Big Joe", text = "业余的。打了三年，后来膝盖不行了。" },
            { speaker = "Thunder", text = "教我几招呗？不是打架——我觉得拳击的站位意识，用在比赛防守上肯定有用。" },
            { speaker = "Big Joe", text = "（眼睛亮了）……你这小子，脑子转得快。来，先学扎马步——不对，先学站桩。" },
            { speaker = "narrator", text = "接下来的日子里，Big Joe 把拳击的防守走位理念融入电竞训练。Thunder 的反应速度本就惊人，配合 Big Joe 的稳健站位思维，两人在比赛中的防守配合简直无懈可击。" },
            { speaker = "narrator", text = "💡 文化知识：非洲拳击传统悠久，尼日利亚、加纳、喀麦隆都是拳击强国。'非洲闪电'阿祖马·尼尔森(Azumah Nelson)是加纳国宝级拳王，WBC超羽量级冠军，被誉为非洲最伟大的拳击手。" },
        },
        lore = { id = "african_boxing", category = "history", title = "非洲拳击传统",
                 text = "非洲是世界拳击重要产地。加纳的阿祖马·尼尔森(Azumah Nelson)是WBC超羽量级传奇冠军；尼日利亚的迪克·泰格(Dick Tiger)是两个级别的世界冠军。拳击在西非不仅是体育，更是改变命运的阶梯。" },
        reward = {
            type = "passive", id = "iron_wall",
            name = "铁壁双塔",
            desc = "Big Joe+Thunder 同时在队时比赛防御评分+12%",
            effect = { defenseBonus = 0.12, members = { "Big Joe", "Thunder" } },
        },
    },
    {
        id = "prince_grace",
        member1 = "Prince", member2 = "Grace",
        minDay = 11, dailyChance = 0.22,
        title = "👑 贵族与画家",
        icon = "👑",
        dialogues = {
            { speaker = "Prince", text = "Grace，我注意到你的画作里总是用非常鲜艳的颜色……在欧洲学院派里这可能被视为'不够高雅'。" },
            { speaker = "Grace", text = "（挑眉）那是因为欧洲的天是灰的。你看看外面——那片天空、那些市场、那些人的衣服——这才是我们的色彩。" },
            { speaker = "Prince", text = "（沉默片刻）……你说得对。我在伦敦待太久了，差点忘了这些颜色有多美。" },
            { speaker = "Grace", text = "那就好好看看呗。要不要跟我去市场写生？保证治好你的'高雅病'。" },
            { speaker = "narrator", text = "Prince 放下身段跟 Grace 去了市场。回来时他说：'我花了一百万去伦敦学的东西，不如今天在市场学到的多。'从此，他帮忙打理战队关系时，手段柔和了许多——招人也变得更容易了。" },
            { speaker = "narrator", text = "💡 文化知识：非洲当代艺术正经历爆发期。尼日利亚裔英国艺术家奥奎·恩韦佐尔(Okwui Enwezor)曾担任威尼斯双年展总策展人，是首位担任此职的非洲人，为非洲艺术打开了国际大门。" },
        },
        lore = { id = "african_art_boom", category = "culture", title = "非洲当代艺术浪潮",
                 text = "21世纪以来，非洲当代艺术蓬勃发展。1-54当代非洲艺术博览会(伦敦/纽约/马拉喀什)、达喀尔双年展(Dak'Art)等平台让世界重新认识非洲创造力。2017年，尼日利亚艺术家本·恩翁武的画作在拍卖会上以数百万美元成交。" },
        reward = {
            type = "passive", id = "noble_artist",
            name = "贵族与画家",
            desc = "Prince+Grace 同时在队时招募费用-20%",
            effect = { recruitDiscount = 0.20, members = { "Prince", "Grace" } },
        },
    },
    {
        id = "snake_prince",
        member1 = "Snake", member2 = "Prince",
        minDay = 15, dailyChance = 0.18,
        title = "🤝 地下交易",
        icon = "🤝",
        dialogues = {
            { speaker = "Snake", text = "Prince 少爷～听说你在拉各斯还有些'关系'？" },
            { speaker = "Prince", text = "（警惕）你想干什么？" },
            { speaker = "Snake", text = "别紧张！我的意思是——你有上层的门路，我有下面的消息网。如果我们合作……" },
            { speaker = "Prince", text = "……金价情报？你是说你能提前知道走势？" },
            { speaker = "Snake", text = "不是提前知道——是我认识海关的人。货物到港时间差那几个小时，对金价影响可大了。" },
            { speaker = "Prince", text = "（想了想）成交。但利润五五分——而且，不能做违法的事。" },
            { speaker = "Snake", text = "少爷，放心。我只是……善于利用信息差而已。" },
            { speaker = "narrator", text = "💡 文化知识：黄金在西非有着深厚的文化根基。加纳古称'黄金海岸'(Gold Coast)，阿散蒂王国(Ashanti Empire)以黄金铸就辉煌。至今加纳仍是非洲第一大产金国，黄金贸易深刻影响着当地经济。" },
        },
        lore = { id = "gold_coast_history", category = "history", title = "黄金海岸的故事",
                 text = "加纳在殖民时期被称为'黄金海岸'(Gold Coast)。阿散蒂王国以金凳(Golden Stool)为至高权力象征，黄金不仅是货币更是精神图腾。1957年独立后改名'加纳'——源自中世纪的加纳帝国(Ghana Empire)，虽然地理位置不同，但象征着非洲黄金文明的荣耀传承。" },
        reward = {
            type = "passive", id = "underground_deal",
            name = "地下交易",
            desc = "Snake+Prince 同时在队时金币交易利润+10%",
            effect = { goldTradeBonus = 0.10, members = { "Snake", "Prince" } },
        },
    },
    {
        id = "kofi_thunder",
        member1 = "Kofi", member2 = "Thunder",
        minDay = 16, dailyChance = 0.20,
        title = "🔥 师徒传承",
        icon = "🔥",
        dialogues = {
            { speaker = "Thunder", text = "Kofi 哥，你那个'闪电连招'到底怎么练的？我试了一百遍都不稳。" },
            { speaker = "Kofi", text = "嗯……你手速够了，但节奏不对。来，我给你拆解一下。" },
            { speaker = "Thunder", text = "节奏？" },
            { speaker = "Kofi", text = "对，就像打鼓一样——djembe鼓手换节奏那一下，快慢之间有个'呼吸'。连招也一样，不是越快越好，是要在对手反应的空隙插进去。" },
            { speaker = "Thunder", text = "……原来如此！就像音乐里的切分！" },
            { speaker = "Kofi", text = "孺子可教！以后你就是我的'徒弟'了——但先把训练室打扫了再说。" },
            { speaker = "narrator", text = "Thunder 的天赋如同闪电，而 Kofi 的经验如同稳定的鼓点。师徒之间的化学反应，让整个战队的上限被推向新高。" },
            { speaker = "narrator", text = "💡 文化知识：Djembe（金贝鼓）起源于西非曼丁卡族，有700多年历史。传统上只有特定家族'Djeli'(吟游诗人)才有资格演奏。鼓声用于传递消息、伴奏舞蹈，是西非音乐的灵魂乐器。" },
        },
        lore = { id = "djembe_drum", category = "culture", title = "金贝鼓(Djembe)",
                 text = "Djembe（金贝鼓）是西非最具代表性的打击乐器，起源于13世纪马里帝国的曼丁卡族。鼓面用山羊皮制作，手掌击打不同位置产生三种基本音色：Bass(低)、Tone(中)、Slap(高)。如今已成为全球最流行的世界音乐乐器之一。" },
        reward = {
            type = "passive", id = "master_apprentice",
            name = "师徒传承",
            desc = "Kofi 满状态(技能≥80)时 Thunder 获得额外+5训练收益",
            effect = { mentorBonus = 5, mentor = "Kofi", mentorMinSkill = 80, apprentice = "Thunder" },
        },
    },
}

-- ============================================================================
-- 核心逻辑
-- ============================================================================

--- 每日结算时检测是否触发组合事件
---@return table|nil 返回触发的事件（供 GL_EndDay 使用），nil 表示今日无触发
function M.CheckComboEvents()
    if not playerData_ or not teamMembers_ then return nil end
    -- 初始化 comboTriggered（兼容旧存档）
    if not playerData_.comboTriggered then
        playerData_.comboTriggered = {}
    end
    for _, combo in ipairs(M.COMBO_EVENTS) do
        if not playerData_.comboTriggered[combo.id]
           and HasMember(combo.member1)
           and HasMember(combo.member2)
           and playerData_.day >= combo.minDay
           and math.random() < combo.dailyChance then
            -- 触发该组合事件
            return M.TriggerComboEvent(combo)
        end
    end
    return nil
end

--- 触发组合事件：标记完成、构建事件对象
---@param combo table 组合事件定义
---@return table event 可供 PHASE_EVENT 使用的事件对象
function M.TriggerComboEvent(combo)
    -- 标记为已触发（永久）
    if not playerData_.comboTriggered then playerData_.comboTriggered = {} end
    playerData_.comboTriggered[combo.id] = true

    -- 构建成对话事件格式（复用现有 PHASE_DIALOGUE 系统）
    -- 使用 dialogues 展示剧情，结束后给予被动奖励
    local rewardDesc = combo.reward and combo.reward.desc or ""
    local event = {
        id = "combo_" .. combo.id,
        type = "dialogue",
        title = combo.title,
        icon = combo.icon or "✨",
        dialogues = combo.dialogues,
        -- 对话结束后自动奖励（通过 onComplete 回调）
        onComplete = function()
            M.ApplyComboReward(combo)
        end,
        -- 供 UI 显示的结果
        resultText = "🎉 解锁被动能力：" .. (combo.reward and combo.reward.name or "") .. "\n" .. rewardDesc,
    }

    log:Write(LOG_INFO, "[ComboEvents] Triggered: " .. combo.id .. " (" .. combo.member1 .. "+" .. combo.member2 .. ")")
    return event
end

--- 应用组合奖励（标记被动加成生效）
function M.ApplyComboReward(combo)
    if not combo.reward then return end
    -- 记录到已触发列表（已在 TriggerComboEvent 中标记）
    -- 添加日志
    if AddLog then
        AddLog("✨ 组合事件完成：" .. combo.title .. " —— " .. (combo.reward.desc or ""))
    end
    -- 触发庆祝
    if TriggerCelebration then
        pcall(TriggerCelebration, "🎊 " .. (combo.reward.name or "新被动能力") .. " 已解锁！")
    end
    -- 播放音效
    if PlaySFX then pcall(PlaySFX, "achievement") end
    -- 保存游戏
    if SaveGame then pcall(SaveGame) end
end

-- ============================================================================
-- 被动加成查询接口（供 TrainMatch 等模块调用）
-- ============================================================================

--- 获取当前生效的训练加成倍率
---@param memberName string 正在训练的成员名字
---@return number bonus 加成倍率（如 1.1 表示+10%），默认返回 1.0
function M.GetTrainBonus(memberName)
    if not playerData_ or not playerData_.comboTriggered then return 1.0 end
    local totalBonus = 1.0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect

            -- 类型1: trainBonus（双人在队时训练效率+X%）
            if eff.trainBonus and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    -- 训练的成员必须是组合中的一员
                    local isMember = false
                    for _, name in ipairs(eff.members) do
                        if name == memberName then isMember = true; break end
                    end
                    if isMember then
                        totalBonus = totalBonus + eff.trainBonus
                    end
                end
            end

            -- 类型2: trainMultiplier（特定两人同时训练时的额外倍率，需两人都在队）
            if eff.trainMultiplier and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    local isMember = false
                    for _, name in ipairs(eff.members) do
                        if name == memberName then isMember = true; break end
                    end
                    if isMember then
                        totalBonus = totalBonus * eff.trainMultiplier
                    end
                end
            end

            -- 类型3: mentorBonus（师傅满技能时徒弟获得固定加成 → 返回附加值而非倍率）
            -- 此类型在 GetTrainFlatBonus 中处理
        end
    end

    return totalBonus
end

--- 获取训练固定加成值（如师徒传承的 +5）
---@param memberName string 正在训练的成员名字
---@return number flatBonus 固定加成值
function M.GetTrainFlatBonus(memberName)
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local flat = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            if eff.mentorBonus and eff.mentor and eff.apprentice then
                if memberName == eff.apprentice and HasMember(eff.mentor) then
                    -- 检查师傅技能是否达标
                    for _, m in ipairs(teamMembers_) do
                        if m.name == eff.mentor and m.skill >= (eff.mentorMinSkill or 80) then
                            flat = flat + eff.mentorBonus
                            break
                        end
                    end
                end
            end
        end
    end

    return flat
end

--- 获取比赛战力加成（百分比）
---@return number bonus 加成百分比的绝对值（如 0.12 表示+12%战力）
function M.GetMatchPowerBonus()
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local bonus = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            -- defenseBonus: 双人在队时比赛防御+X%（转化为战力加成）
            if eff.defenseBonus and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    bonus = bonus + eff.defenseBonus
                end
            end
        end
    end

    return bonus
end

--- 获取比赛逆风翻盘概率加成
---@return number bonus 概率加成（如 0.08）
function M.GetComebackBonus()
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local bonus = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            if eff.comebackBonus and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    bonus = bonus + eff.comebackBonus
                end
            end
        end
    end

    return bonus
end

--- 获取金币交易利润加成
---@return number bonus 利润加成百分比（如 0.10 = +10%）
function M.GetGoldTradeBonus()
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local bonus = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            if eff.goldTradeBonus and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    bonus = bonus + eff.goldTradeBonus
                end
            end
        end
    end

    return bonus
end

--- 获取招募费用折扣
---@return number discount 折扣百分比（如 0.20 = -20% 费用）
function M.GetRecruitDiscount()
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local discount = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            if eff.recruitDiscount and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    discount = discount + eff.recruitDiscount
                end
            end
        end
    end

    return discount
end

--- 获取心情衰减减少量
---@return number reduction 减少比例（如 0.15 = 衰减量减少15%）
function M.GetMoodDecayReduction()
    if not playerData_ or not playerData_.comboTriggered then return 0 end
    local reduction = 0

    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] and combo.reward and combo.reward.effect then
            local eff = combo.reward.effect
            if eff.moodDecayReduction and eff.members then
                local allPresent = true
                for _, name in ipairs(eff.members) do
                    if not HasMember(name) then allPresent = false; break end
                end
                if allPresent then
                    reduction = reduction + eff.moodDecayReduction
                end
            end
        end
    end

    return reduction
end

--- 获取已解锁的所有组合事件列表（供 UI 展示）
---@return table[] 已完成的组合事件定义列表
function M.GetUnlockedCombos()
    if not playerData_ or not playerData_.comboTriggered then return {} end
    local list = {}
    for _, combo in ipairs(M.COMBO_EVENTS) do
        if playerData_.comboTriggered[combo.id] then
            table.insert(list, combo)
        end
    end
    return list
end

--- 获取可能触发（但尚未触发）的组合事件提示
---@return table[] 满足角色条件但尚未触发的组合
function M.GetPendingHints()
    if not playerData_ or not playerData_.comboTriggered then return {} end
    local hints = {}
    for _, combo in ipairs(M.COMBO_EVENTS) do
        if not playerData_.comboTriggered[combo.id]
           and HasMember(combo.member1) and HasMember(combo.member2) then
            table.insert(hints, { member1 = combo.member1, member2 = combo.member2, title = "???" })
        end
    end
    return hints
end

return M
