---@diagnostic disable: undefined-global
local Achievements = require("Achievements")
local PrestigeSystem = require("PrestigeSystem")


--- 根据比赛结果和karma值计算结局
function GetEnding()
    local won = matchResult_ == "win"
    local k = playerData_.karma
    local totalEarn = playerData_.totalEarnings or 0
    local branchCount = #(playerData_.branches or {})
    local seasonId = playerData_.seasonId or 1

    -- 终极结局：博拉卡伊咖啡店（隐藏结局）
    -- 条件：赢得比赛 + 累计收入≥50000 + 至少2家分店 + 赛季达到传奇以上
    if won and totalEarn >= 50000 and branchCount >= 2 and seasonId >= 3 then
        return {
            icon = "🏝️", title = "终极结局：博拉卡伊的日落",
            difficulty = 5, diffLabel = "隐藏", diffColor = { 255, 120, 255, 255 },
            hint = "赢得比赛 + 累计收入$50000+ + 2家分店 + 传奇赛季",
            color = { 255, 180, 100, 255 }, borderColor = { 255, 200, 120, 180 },
            desc = "Dragon Force 夺冠的那晚，你没有参加庆功宴。\n\n"
                .. "你坐在网吧天台上，看着拉各斯的灯火，翻开手机里一张旧照片——碧蓝的海水、白色的沙滩、椰树下的小木屋。那是你来非洲之前，在博拉卡伊拍的。\n\n"
                .. "当初你跟自己说：'等我挣够了钱，就去那里开一间咖啡店，面朝大海，什么都不想。'\n\n"
                .. "你看了看银行账户——".. string.format("$%d", totalEarn) .."。" .. branchCount .. "家分店在自动运转。队员们已经可以独当一面。\n\n"
                .. "三个月后，博拉卡伊白沙滩上多了一间小咖啡店。店名叫 'Dragon Café'。\n\n"
                .. "每天早上，你磨咖啡豆、冲拿铁、看海浪。偶尔有客人问：'老板以前是做什么的？'\n\n"
                .. "你笑笑：'我啊……以前在非洲开网吧。'\n\n"
                .. "手机弹出消息——Snake发来的视频：Dragon Force在新赛季又夺冠了。\n\n"
                .. "你端起咖啡，对着夕阳举了举杯。",
            epilogue = "「人生最好的结局，不是到达终点，而是终于可以停下来。」",
            bgImage = SCENE_IMAGES.ending_beach,
        }
    end

    if won and k >= 4 then
        return {
            icon = "", title = "传奇结局：非洲之光",
            difficulty = 3, diffLabel = "困难", diffColor = { 255, 180, 50, 255 },
            hint = "赢得比赛 + 善良抉择(karma≥4)",
            color = { 255, 215, 0, 255 }, borderColor = { 255, 210, 70, 150 },
            desc = "Dragon Force 不仅赢得了冠军，更赢得了整个非洲的尊重。\n\n你用真诚和善意经营网吧，帮助每一个走进来的年轻人。Snake放下了街头的刀，Grace得到了父亲的祝福，Kofi用奖金给妈妈盖了新房。\n\n国际媒体报道：'一个中国人，在非洲点燃了电竞的星火。'\n\n多年后，Dragon Net Cafe成了非洲电竞的圣地。每年都有来自世界各地的人来这里朝圣——不是为了冠军奖杯，而是为了这里永远敞开的门。",
            epilogue = "「真正的胜利，不是战胜对手，而是改变命运。」",
            bgImage = SCENE_IMAGES.ending_legend,
        }
    elseif won and k <= -3 then
        return {
            icon = "", title = "商业结局：电竞帝国",
            difficulty = 3, diffLabel = "困难", diffColor = { 255, 180, 50, 255 },
            hint = "赢得比赛 + 自私抉择(karma≤-3)",
            color = { 0, 255, 128, 255 }, borderColor = { 0, 200, 100, 150 },
            desc = "Dragon Force 夺冠后，你迅速将品牌商业化。\n\n赞助商蜂拥而至，代练业务遍布非洲。你在五个国家开了连锁网吧，成了'非洲电竞教父'。\n\n但队员们渐渐疏远了你。Snake回到了街头，说'老板只在乎钱'。Kofi默默离开了，没有道别。\n\n你坐在豪华办公室里，看着银行账户上的数字，窗外是灯火通明的城市。一切都很好，只是……有时候会想起那间铁皮屋顶的小网吧。",
            epilogue = "「你赢得了一切，除了那些最重要的东西。」",
            bgImage = SCENE_IMAGES.ending_empire,
        }
    elseif won then
        return {
            icon = "", title = "荣耀结局：冠军之路",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "赢得比赛 + 中性抉择",
            color = { 255, 210, 70, 255 }, borderColor = { 255, 210, 70, 120 },
            desc = "Dragon Force 赢得全非洲三角洲锦标赛！\n\n这是一支由来自不同角落的人组成的队伍——前保镖、牧师的女儿、街头少年、卖烤鸡的大婶……他们因为跑刀聚在一起，因为你的坚持走到最后。\n\n颁奖那晚，所有人围坐在网吧里，吃着Mama Blessing的烤鸡，看着奖杯在烛光下闪闪发亮。\n\n'明年，我们去打世界赛！'有人说。所有人笑了。",
            epilogue = "「从铁皮屋顶到非洲之巅——这就是Dragon Force的故事。」",
            bgImage = SCENE_IMAGES.victory,
        }
    elseif not won and k >= 4 then
        return {
            icon = "", title = "温暖结局：比赛之外",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "比赛失利 + 善良抉择(karma≥4)",
            color = { 100, 180, 255, 255 }, borderColor = { 100, 180, 255, 120 },
            desc = "Dragon Force 没能夺冠。但你知道，这从来不只是关于比赛。\n\nSnake因为你的信任，彻底告别了街头。Grace考上了大学，每个假期都回来帮忙。Kofi成了当地小有名气的电竞教练。\n\n你的网吧成了镇上年轻人的避风港。有孩子来这里学电脑，有人来这里找工作，有人只是来这里坐坐，因为'这里感觉像家'。\n\n输了比赛，赢了人生。也许，这才是你来非洲的意义。",
            epilogue = "「有些东西比冠军更重要。你知道的。」",
            bgImage = SCENE_IMAGES.ending_warmth,
        }
    elseif not won and k <= -3 then
        return {
            icon = "✈️", title = "遗憾结局：回国之路",
            difficulty = 2, diffLabel = "普通", diffColor = { 100, 200, 255, 255 },
            hint = "比赛失利 + 自私抉择(karma≤-3)",
            color = { 180, 100, 100, 255 }, borderColor = { 180, 80, 80, 120 },
            desc = "比赛输了。赞助商撤资，代练订单也断了。\n\n你坐在空荡荡的网吧里算了算账——该走了。\n\n收拾行李那天，没有人来送你。只有Mama Blessing在门口放了一份烤鸡，上面贴着便条：'谢谢你，中国老板。'\n\n飞机起飞的时候，你望着窗外越来越小的非洲大陆，想着如果当初对队员好一点，结果会不会不一样。\n\n手机震动，是Snake发来的消息：'老大你走了？……算了。'",
            epilogue = "「有些路走错了，就回不了头了。」",
            bgImage = SCENE_IMAGES.ending_depart,
        }
    else
        return {
            icon = "🌅", title = "平凡结局：明日再战",
            difficulty = 1, diffLabel = "简单", diffColor = { 150, 180, 150, 255 },
            hint = "比赛失利 + 中性抉择",
            color = { 160, 175, 160, 255 }, borderColor = { 195, 210, 195, 120 },
            desc = "Dragon Force 止步半决赛。遗憾，但不绝望。\n\n生活还在继续。网吧每天照常开门，队员们继续训练。你学会了更多斯瓦希里语，也学会了在停电时讲笑话。\n\n'明年再来！'Big Joe举起装满可乐的杯子。所有人碰杯。\n\n窗外非洲的夕阳很美。铁皮屋顶被染成金色。键盘声、笑声、和远处的鼓声混在一起。\n\n日子不完美，但很真实。这就够了。",
            epilogue = "「故事还没结束。明天见。」",
            bgImage = SCENE_IMAGES.ending_sunset,
        }
    end
end

function BuildResultUI()
    local ending = GetEnding()
    local karmaLabel = playerData_.karma >= 4 and "仁义之师" or (playerData_.karma <= -3 and "利益至上" or "中庸之道")
    local karmaColor = playerData_.karma >= 4 and C.green or (playerData_.karma <= -3 and C.red or C.gold)

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = ending.bgImage,
        backgroundFit = "cover",
        justifyContent = "center", alignItems = "center", padding = 16,
        children = {
            UI.ScrollView {
                width = "90%", maxWidth = 420, maxHeight = "92%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 24, 18 }, gap = 8,
                        backgroundColor = C.card, borderRadius = 20,
                        borderWidth = 2, borderColor = ending.borderColor,
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 6, blur = 20, color = { 120, 100, 70, 80 } } },
                        children = {
                            UI.Label { text = ending.icon, fontSize = 48 },
                            UI.Label { text = ending.title, fontSize = 22, fontColor = ending.color,
                                textShadow = { offsetX = 0, offsetY = 2, blur = 6, color = { 160, 130, 90, 100 } } },
                            -- 难度标签和星级
                            UI.Panel {
                                flexDirection = "row", gap = 6, alignItems = "center",
                                paddingHorizontal = 10, paddingVertical = 3,
                                backgroundColor = C.cardAlt, borderRadius = 12,
                                children = {
                                    UI.Label { text = string.rep("★", ending.difficulty), fontSize = 12, fontColor = C.gold },
                                    UI.Label { text = ending.diffLabel, fontSize = 11, fontColor = ending.diffColor, fontWeight = "bold" },
                                },
                            },
                            -- 解锁条件提示
                            UI.Label { text = "🔓 " .. ending.hint, fontSize = 11, fontColor = C.textLight,
                                textAlign = "center", whiteSpace = "normal", width = "100%" },
                            UI.Panel { height = 2 },
                            UI.Panel {
                                width = "100%", padding = 12, gap = 4,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = ending.desc, fontSize = 14, fontColor = C.text,
                                        textAlign = "center", whiteSpace = "normal", lineHeight = 1.6, width = "100%" },
                                },
                            },
                            UI.Panel { height = 4 },
                            UI.Label { text = ending.epilogue, fontSize = 13, fontColor = ending.color,
                                textAlign = "center", whiteSpace = "normal", lineHeight = 1.5,
                                fontStyle = "italic" },
                            UI.Panel { height = 6 },
                            UI.Panel {
                                width = "100%", padding = 10, gap = 4,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = "最终成绩", fontSize = 13, fontColor = C.accent },
                                    InfoRow("经营天数", playerData_.day .. "天"),
                                    InfoRow("总资产", "$" .. playerData_.money, C.green),
                                    InfoRow("声望值", tostring(playerData_.reputation), C.gold),
                                    InfoRow("战队人数", #teamMembers_ .. "人"),
                                    InfoRow("战队实力", tostring(GetTeamPower()), C.blue),
                                    InfoRow("友谊赛", playerData_.friendlyWins .. "胜 " .. playerData_.friendlyLosses .. "负", C.accent),
                                    InfoRow("锦标赛", (playerData_.tournamentWins or 0) .. "冠 / " .. (playerData_.tournamentPlayed or 0) .. "赛", C.gold),
                                    InfoRow("成就解锁", Achievements.GetStats().unlocked .. "/" .. Achievements.GetStats().total, C.gold),
                                    InfoRow("累计收入", "$" .. (playerData_.totalEarnings or 0), C.green),
                                    InfoRow("分店数量", #(playerData_.branches or {}) .. "家", C.accent),
                                    InfoRow("赛季等级", ({ "新秀", "精英", "传奇", "王者" })[playerData_.seasonId or 1] or "王者", C.gold),
                                    InfoRow("抉择倾向", karmaLabel, karmaColor),
                                },
                            },
                            -- 结局图鉴
                            UI.Panel { height = 4 },
                            UI.Panel {
                                width = "100%", padding = 10, gap = 3,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    UI.Label { text = "结局图鉴 (共8种)", fontSize = 13, fontColor = C.accent },
                                    UI.Label { text = "★ 平凡结局 · ★ 破产结局", fontSize = 11, fontColor = { 150, 200, 150, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★ 荣耀之路 · ★★ 温暖结局 · ★★ 遗憾结局", fontSize = 11, fontColor = { 100, 200, 255, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★★ 传奇结局 · ★★★ 商业结局", fontSize = 11, fontColor = { 255, 200, 80, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "★★★★★ 终极隐藏结局", fontSize = 11, fontColor = { 255, 140, 255, 220 }, whiteSpace = "normal", width = "100%" },
                                    UI.Label { text = "提示：抉择影响karma，善恶决定结局走向", fontSize = 10, fontColor = C.textLight, whiteSpace = "normal", width = "100%", fontStyle = "italic" },
                                },
                            },
                            UI.Panel { height = 6 },
                            UI.Button { text = "继续经营（返回游戏）", width = "90%", minHeight = 42, fontSize = 14, variant = "primary",
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("🏠 回到网吧", "传奇仍在继续……", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end },
                            UI.Panel { height = 4 },
                            UI.Button { text = "重新开始（解锁其他结局）", width = "90%", minHeight = 36, fontSize = 13,
                                onClick = function()
                                    StartTransition("新的旅程", "不同的选择，不同的命运", function()
                                        ResetGame()
                                    end)
                                end },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 17.5 破产结局画面
-- ============================================================================
function BuildGameOverUI()
    local daysSurvived = playerData_.day - 1
    local teamSize = #teamMembers_

    -- 根据坚持天数选择不同叙事
    local narrative
    if daysSurvived <= 7 then
        narrative = "网吧刚开没多久，就入不敷出了。非洲的烈日依旧炙烤着大地，但你的网吧却彻底凉了。街角的Mama Blessing默默收起了她的烤鸡摊。"
    elseif daysSurvived <= 20 then
        narrative = "你努力了将近一个月，但不断上涨的房租和各种意外最终压垮了这家小网吧。门口的招牌被风吹歪了，没人再来扶正它。"
    elseif daysSurvived <= 40 then
        narrative = "你在这片土地上坚持了" .. daysSurvived .. "天，队员们跟着你经历了不少风雨。但商业的残酷不分国界，网吧最终还是关门了。大家含泪拥抱，约定来日方长。"
    else
        narrative = "整整" .. daysSurvived .. "天，你把一间铁皮小屋变成了远近闻名的跑刀圣地。虽然最终败给了现实，但'Dragon Net Cafe'的传说，将在这条街上流传很久。"
    end

    -- 队员告别语
    local farewellText = ""
    if teamSize > 0 then
        local names = {}
        for _, m in ipairs(teamMembers_) do table.insert(names, m.emoji .. m.name) end
        farewellText = table.concat(names, "、") .. " 向你挥手告别……"
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = SCENE_IMAGES.ending_bankrupt,
        backgroundFit = "cover",
        imageTint = { 215, 225, 215, 255 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 16,
        children = {
            UI.ScrollView {
                width = "90%", maxWidth = 420, maxHeight = "92%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 24, 20 }, gap = 10,
                        backgroundColor = C.card, borderRadius = 20,
                        borderWidth = 2, borderColor = { 200, 70, 60, 120 },
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 6, blur = 20, color = { 0, 0, 0, 120 } } },
                        children = {
                            UI.Label { text = "", fontSize = 48 },
                            UI.Panel { height = 4 },
                            UI.Label { text = "破产结局：网吧倒闭", fontSize = 22, fontColor = C.red,
                                textShadow = { offsetX = 0, offsetY = 2, blur = 6, color = { 0, 0, 0, 160 } } },
                            UI.Panel {
                                flexDirection = "row", gap = 6, alignItems = "center",
                                paddingHorizontal = 10, paddingVertical = 3,
                                backgroundColor = C.cardAlt, borderRadius = 12,
                                children = {
                                    UI.Label { text = "★", fontSize = 12, fontColor = C.gold },
                                    UI.Label { text = "简单", fontSize = 11, fontColor = C.green, fontWeight = "bold" },
                                },
                            },
                            UI.Label { text = "资金耗尽即触发", fontSize = 11, fontColor = C.textLight,
                                textAlign = "center" },
                            UI.Panel { height = 4 },
                            UI.Label { text = narrative, fontSize = 13, fontColor = C.text,
                                whiteSpace = "normal", textAlign = "center", lineHeight = 1.6, width = "100%" },
                            teamSize > 0 and UI.Label {
                                text = farewellText, fontSize = 14, fontColor = C.textDim,
                                whiteSpace = "normal", textAlign = "center", width = "100%",
                                fontStyle = "italic",
                            } or UI.Panel { height = 0 },
                            UI.Panel { height = 8 },
                            -- 经营记录
                            UI.Panel {
                                width = "100%", padding = 12, gap = 5,
                                backgroundColor = C.cardAlt, borderRadius = 10,
                                children = {
                                    PanelHeader("经营记录", { icon = "", compact = true }),
                                    InfoRow("坚持天数", daysSurvived .. " 天"),
                                    InfoRow("最终规模", playerData_.computers .. " 台电脑"),
                                    InfoRow("队伍人数", teamSize .. " 人"),
                                    InfoRow("最高声望", tostring(playerData_.reputation), C.gold),
                                    InfoRow("成就解锁", Achievements.GetStats().unlocked .. "/" .. Achievements.GetStats().total, C.gold),
                                },
                            },
                            UI.Panel { height = 8 },
                            -- 小贴士
                            UI.Panel {
                                width = "100%", padding = 10,
                                backgroundColor = C.cardAlt, borderRadius = 8,
                                children = {
                                    UI.Label {
                                        text = "经营小贴士：尽早升级烤鸡摊和装饰，可以显著增加每日收入。控制升级节奏，别把钱花光了！",
                                        fontSize = 13, fontColor = C.green,
                                        whiteSpace = "normal", lineHeight = 1.5, width = "100%",
                                    },
                                },
                            },
                            UI.Panel { height = 10 },
                            AdManager.CanWatch("bailout_boost", playerData_.day) and AdManager.AdButton {
                                sceneId = "bailout_boost", day = playerData_.day,
                                text = "看视频获得赞助商投资 $600", width = "80%", height = 46, fontSize = 15,
                                onReward = function()
                                    playerData_.money = 600
                                    AddLog("�� 赞助商看好你的潜力，投资了$600！声望不减，卷土重来！")
                                    StartTransition("💰 赞助商投资", "有人相信你的实力！这笔投资让你重新站起来。", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end,
                            } or UI.Panel { height = 0 },
                            UI.Button {
                                text = "接受救济，继续经营", width = "80%", height = 46, fontSize = 16, variant = "primary",
                                onClick = function()
                                    PlaySFX("click")
                                    local bailout = 300
                                    playerData_.money = bailout
                                    playerData_.reputation = math.max(0, playerData_.reputation - 20)
                                    AddLog("🤝 Mama Blessing和邻居们凑了$" .. bailout .. "帮你渡过难关。你决定重整旗鼓！")
                                    AddLog("  （声望 -20，大家虽然帮了你，但街坊们的眼神多了几分同情……）")
                                    StartTransition("🤝 好心人的援手", "跌倒了，爬起来！街坊邻居不会看着你倒下。", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Button {
                                text = "东山再起（重新开始）", width = "80%", height = 38, fontSize = 14,
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("重新出发", "这次一定行！", function()
                                        ResetGame()
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Label { text = "\"跌倒了不可怕，可怕的是不敢再站起来。\"", fontSize = 13,
                                fontColor = C.textLight, fontStyle = "italic" },
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 胜利结局 UI
-- ============================================================================
function BuildVictoryUI()
    local day        = playerData_.day or 1
    local rep        = playerData_.reputation or 0
    local money      = playerData_.money or 0
    local tourney    = playerData_.totalTourney or 0
    local teamSize   = #teamMembers_
    local karma      = playerData_.karma or 0
    local totalEarn  = playerData_.totalEarnings or 0

    -- 根据道义值和声望选择叙事文字
    local narrative, endingLabel, bgImage
    if storyTriggered_ and storyTriggered_["world_tournament_invite"] then
        bgImage    = SCENE_IMAGES.ending_depart
        endingLabel = "传奇结局：征战世界"
        narrative  = "那封来自上海的邀请函改变了一切。" ..
            "从一间铁皮屋到世界赛场，Dragon Force 用 " .. day .. " 天走完了别人走十年的路。" ..
            "当你们站在聚光灯下，耳边响起非洲的鼓点——那是整个街区在为你们欢呼。"
    elseif karma >= 5 then
        bgImage    = SCENE_IMAGES.ending_warmth
        endingLabel = "善缘结局：以德服人"
        narrative  = "声望 " .. rep .. " 点，" .. tourney .. " 次锦标赛，" ..
            "但你记得最清楚的，是沿途帮助过的每一个人。" ..
            "Mama Blessing 说：'这孩子，心里有光。'Dragon Force，因为有你们，这条街暖了很多。"
    elseif rep >= 250 then
        bgImage    = SCENE_IMAGES.ending_empire
        endingLabel = "霸业结局：非洲之王"
        narrative  = "声望值突破 250，整个非洲电竞圈都知道 Dragon Force 的名字。" ..
            "从一台二手机器开始，你用 " .. day .. " 天建立了一个小小的帝国。" ..
            "街角的孩子们说：'我长大也要开网吧，要开最厉害的那种。'"
    else
        bgImage    = SCENE_IMAGES.ending_legend
        endingLabel = "胜利结局：荣耀加冕"
        narrative  = "经过 " .. day .. " 天的打拼，Dragon Force 以声望 " .. rep ..
            " 、" .. tourney .. " 次锦标赛桂冠完成了对所有竞争者的超越。" ..
            "铁皮屋变成了电竞地标，你证明了：在这片土地上，梦想可以很硬核。"
    end

    -- 队员名单
    local teamNames = ""
    if teamSize > 0 then
        local names = {}
        for _, m in ipairs(teamMembers_) do table.insert(names, (m.emoji or "") .. m.name) end
        teamNames = table.concat(names, "  ")
    end

    -- 经营数据格式化
    local function statRow(icon, label, value)
        return UI.Panel {
            flexDirection = "row", alignItems = "center",
            paddingHorizontal = 12, paddingVertical = 5,
            backgroundColor = C.cardAlt, borderRadius = 10, width = "100%",
            children = {
                UI.Label { text = icon, fontSize = 16, width = 28 },
                UI.Label { text = label, fontSize = 13, fontColor = C.textLight, flex = 1 },
                UI.Label { text = tostring(value), fontSize = 14, fontColor = C.gold, fontWeight = "bold" },
            },
        }
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundImage = bgImage,
        backgroundFit = "cover",
        imageTint = { 240, 250, 235, 255 },
        justifyContent = "center", alignItems = "center",
        paddingHorizontal = 16,
        children = {
            UI.ScrollView {
                width = "92%", maxWidth = 440, maxHeight = "94%",
                children = {
                    UI.Panel {
                        width = "100%", padding = { 24, 20 }, gap = 10,
                        backgroundColor = C.card, borderRadius = 20,
                        borderWidth = 2, borderColor = { 80, 200, 100, 140 },
                        alignItems = "center",
                        boxShadow = { { x = 0, y = 8, blur = 28, color = { 0, 0, 0, 140 } } },
                        children = {
                            -- 胜利图标
                            UI.Label { text = "🏆", fontSize = 56 },
                            UI.Panel { height = 2 },
                            -- 结局标题
                            UI.Label {
                                text = endingLabel, fontSize = 21, fontColor = C.gold, fontWeight = "bold",
                                textShadow = { offsetX = 0, offsetY = 2, blur = 8, color = { 0, 0, 0, 160 } },
                                textAlign = "center",
                            },
                            -- 触发条件说明
                            UI.Panel {
                                flexDirection = "row", gap = 6, alignItems = "center",
                                paddingHorizontal = 10, paddingVertical = 3,
                                backgroundColor = { 40, 120, 60, 180 }, borderRadius = 12,
                                children = {
                                    UI.Label { text = "★★★", fontSize = 12, fontColor = C.gold },
                                    UI.Label { text = "通关", fontSize = 11, fontColor = { 180, 255, 180, 255 }, fontWeight = "bold" },
                                },
                            },
                            UI.Panel { height = 4 },
                            -- 叙事文本
                            UI.Label {
                                text = narrative, fontSize = 13, fontColor = C.text,
                                whiteSpace = "normal", textAlign = "center", lineHeight = 1.7, width = "100%",
                            },
                            UI.Panel { height = 4 },
                            -- 经营数据汇总
                            UI.Label { text = "经营档案", fontSize = 14, fontColor = C.textLight,
                                fontWeight = "bold", width = "100%", textAlign = "left" },
                            UI.Panel { height = 2 },
                            statRow("📅", "坚持天数", day .. " 天"),
                            statRow("⭐", "最终声望", rep .. " 点"),
                            statRow("💰", "总营收", "$" .. math.floor(totalEarn)),
                            statRow("🏆", "锦标赛夺冠", tourney .. " 次"),
                            statRow("👥", "团队人数", teamSize .. " 人"),
                            statRow("🌟", "道义值", karma),
                            -- 队员展示
                            teamSize > 0 and UI.Panel {
                                width = "100%", gap = 4, marginTop = 4,
                                children = {
                                    UI.Label { text = "荣耀团队", fontSize = 13, fontColor = C.textLight,
                                        fontWeight = "bold" },
                                    UI.Label { text = teamNames, fontSize = 13, fontColor = C.gold,
                                        whiteSpace = "normal", lineHeight = 1.5 },
                                },
                            } or UI.Panel { height = 0 },
                            UI.Panel { height = 8 },
                            -- 名言
                            UI.Label {
                                text = "\"从铁皮屋到世界的舞台，这条路，你走到了终点。\"",
                                fontSize = 12, fontColor = C.textLight, fontStyle = "italic",
                                whiteSpace = "normal", textAlign = "center", width = "100%",
                            },
                            UI.Panel { height = 8 },
                            -- 操作按钮
                            UI.Button {
                                text = "继续挑战：转生新局", width = "80%", height = 48, fontSize = 16,
                                variant = "primary",
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("🌅 新的征途", "荣耀已是过去，更大的舞台在等着你。", function()
                                        if PrestigeSystem and PrestigeSystem.CanPrestige and PrestigeSystem.CanPrestige() then
                                            PrestigeSystem.DoPrestige()
                                        else
                                            ResetGame()
                                        end
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Button {
                                text = "留在当下，继续经营", width = "80%", height = 38, fontSize = 14,
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("🏠 熟悉的网吧", "荣耀之后，生活依然继续。", function()
                                        PlayBGM("manage")
                                        currentPhase_ = PHASE_MANAGE; BuildUI()
                                    end)
                                end,
                            },
                            UI.Panel { height = 4 },
                            UI.Button {
                                text = "从头再来（新游戏）", width = "80%", height = 36, fontSize = 13,
                                onClick = function()
                                    PlaySFX("click")
                                    StartTransition("重新出发", "新的故事，新的传奇。", function()
                                        ResetGame()
                                    end)
                                end,
                            },
                        },
                    },
                },
            },
        },
    }
end

