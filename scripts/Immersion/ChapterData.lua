-- ============================================================================
-- Immersion/ChapterData.lua — 沉浸式章节数据（5章，漫画面板叙事）
-- 每章以3张漫画面板呈现，统一视觉质感
-- ============================================================================
local M = {}

-- ============================================================================
-- 章节漫画面板图片键（在 GameState.SCENE_IMAGES 中注册）
-- ============================================================================
M.CHAPTER_COMIC_IMAGE_KEYS = {
    "ch1_panel1",   -- 第一章 splash
    "ch2_splash",   -- 第二章 splash
    "ch3_splash",   -- 第三章 splash
    "ch4_splash",   -- 第四章 splash
    "ch5_splash",   -- 第五章 splash
}

M.CHAPTERS = {
    -- ================================================================
    -- 第一章：铁皮屋
    -- ================================================================
    {
        title = "第一章：铁皮屋",
        atmosphere = "红色大地上的第一缕晨光。柴油味、键盘声、和一个关于逃离的故事。",
        bgm = "title",
        ambient = "none",
        comic_panels = {
            -- 唯一面板: 全屏铁皮屋 + 章节标题，自动推进后直接进经营
            {
                template = "splash",
                imageKey = "ch1_panel1",
                title = "第一章 · 非洲创业",
                subtitle = "Dragon Net Cafe · 正式开业",
                duration = 3.5,
                textDelay = 1.0,
                lines = {},
            },
        },
        -- 保留旧 dialogues 用于兼容（剧情事件系统可能引用）
        dialogues = {
            { speaker = "你", text = "我站在Wakandaville的街头，看着这间铁皮屋顶的网吧。", type = "monologue" },
            { speaker = "你", text = "三台二手电脑，一条20兆宽带，和我最后的全部身家。", type = "monologue" },
            { speaker = "你", text = "这里的规矩比法律多——但至少，没人认识我。没人知道我欠了谁的钱。", type = "monologue" },
            { speaker = "旁白", text = "房东Musa帮你接好了电线。他用蹩脚的英语说：'Electricity is God here. No power, no business.'" },
            { speaker = "旁白", text = "第一个傍晚。一群少年挤在窗外，透过铁丝网看屏幕上的枪战画面。他们的眼睛在暮色中发亮。" },
            { speaker = "你", text = "我设了两台免费体验机。五分钟之内，塑料凳全坐满了。", type = "monologue" },
            { speaker = "旁白", text = "一个瘦得像竹竿的少年坐下来，手指触碰键盘的瞬间——他的操作让你愣住了。" },
            { speaker = "你", text = "这片红土地下面，埋着金子。不是黄金——是天赋。", type = "monologue" },
            { speaker = "旁白", text = "Dragon Net Cafe。你用喷漆在铁皮墙上画了一条龙。油漆顺着铁皮往下淌，像一道红色的眼泪。" },
            { speaker = "你", text = "从今天起——活下去。证明自己。", type = "monologue" },
        },
    },
    -- ================================================================
    -- 第二章：街区传说
    -- ================================================================
    {
        title = "第二章：街区传说",
        atmosphere = "网吧的灯光在夜色中像一座灯塔。有人慕名而来，有人带着恶意。",
        bgm = "manage",
        ambient = "cafe_busy",
        comic_panels = {
            {
                template = "splash",
                imageKey = "ch2_splash",
                title = "第二章 · 街区传说",
                subtitle = "名声，是一把双刃剑",
                duration = 3.5,
                textDelay = 1.0,
                lines = {},
            },
        },
        dialogues = {
            { speaker = "你", text = "Victor走了。街坊们说我赢了那场地盘之争。", type = "monologue" },
            { speaker = "你", text = "可凌晨醒来的时候，我还是会看那个催债的未接来电。我欠的不止是钱。", type = "monologue" },
            { speaker = "你", text = "不过……这条街的游戏，才刚刚开始。", type = "monologue" },
            { speaker = "旁白", text = "网吧的名声传出了这条街。B站上有人拍了段视频——'非洲铁皮网吧里的电竞少年'，弹幕刷了十万条。" },
            { speaker = "旁白", text = "名声招来了客人，也招来了竞争者。Gold Boss的霓虹招牌在三条街外亮了起来，比你的铁皮屋耀眼一百倍。" },
            { speaker = "你", text = "他有钱。我有人。这条街上每个来打游戏的少年，都是我的兄弟。", type = "monologue" },
            { speaker = "旁白", text = "一个雨夜。Grace第一次推门进来——浑身湿透，低着头说：'我只有两小时，教堂的人不知道我来了。'" },
            { speaker = "旁白", text = "Snake在门口跟人对峙。你冲出去的时候，他回头看了你一眼——那眼神里不是敌意，是试探。" },
            { speaker = "你", text = "每个人来这里都带着自己的故事。我给不了他们答案，但至少能给一张椅子、一块屏幕。", type = "monologue" },
            { speaker = "旁白", text = "邮箱里弹出一条消息：'全非洲三角洲锦标赛·地区预选赛——报名开放。'" },
            { speaker = "你", text = "……是时候了。", type = "monologue" },
        },
    },
    -- ================================================================
    -- 第三章：至暗时刻
    -- ================================================================
    {
        title = "第三章：至暗时刻",
        atmosphere = "连续四天的黑暗。发电机的轰鸣像心跳——一下，一下，随时可能停。",
        bgm = "manage",
        ambient = "generator_hum",
        comic_panels = {
            {
                template = "splash",
                imageKey = "ch3_splash",
                title = "第三章 · 至暗时刻",
                subtitle = "整条街只有这里还亮着",
                duration = 3.5,
                textDelay = 1.0,
                lines = {},
            },
        },
        dialogues = {
            { speaker = "你", text = "记者把麦克风递到我面前的时候，我第一次觉得——", type = "monologue" },
            { speaker = "你", text = "我不再只是一个逃来非洲的失败者了。这个社区的未来，好像真的和我有关系。", type = "monologue" },
            { speaker = "旁白", text = "但现实不讲故事。距离全非洲大赛还有两周——整个瓦坎达维尔连续四天大停电。" },
            { speaker = "旁白", text = "冰箱里的可乐变成温水。客人一个个走了。街上只剩月光和远处发电机偶尔的咳嗽声。" },
            { speaker = "你", text = "不行。不能停下训练。不能让这些孩子的努力白费。", type = "monologue" },
            { speaker = "旁白", text = "你花了$800从废品站淘回一台柴油发电机。柴油味呛得人流泪，但灯亮了。整条街只有你这间铁皮屋还亮着。" },
            { speaker = "旁白", text = "凌晨三点。Snake趴在键盘上睡着了。Kofi给他披了件外套，然后继续练枪。发电机每隔几分钟咳嗽一声，所有人的心跟着停一拍。" },
            { speaker = "你", text = "看着他们在摇晃的灯光下拼命的样子——不是我在帮他们追梦。是他们在教我，什么叫不放弃。", type = "monologue" },
            { speaker = "旁白", text = "第五天清晨。电力恢复。队员们冲出铁皮屋，在红色的日出下互相拥抱，笑声传出很远。" },
            { speaker = "你", text = "天亮了。我们还在。", type = "monologue" },
        },
        skillBoost = 8,
        scene = "community",
    },
    -- ================================================================
    -- 第四章：远征
    -- ================================================================
    {
        title = "第四章：远征",
        atmosphere = "颠簸的长途大巴。700公里的红土公路。每个人都在沉默中准备着。",
        bgm = "train",
        ambient = "none",
        comic_panels = {
            {
                template = "splash",
                imageKey = "ch4_splash",
                title = "第四章 · 远征",
                subtitle = "700公里，从铁皮屋到拉各斯",
                duration = 3.5,
                textDelay = 1.0,
                lines = {},
            },
        },
        dialogues = {
            { speaker = "你", text = "从Wakandaville的铁皮屋到行业峰会的演讲台，不过半年。", type = "monologue" },
            { speaker = "你", text = "有人叫我先驱，有人叫我投机者。但我知道，这片大陆上还有更大的舞台。", type = "monologue" },
            { speaker = "旁白", text = "出发那天，Mama Blessing在门口塞了一大包烤鸡。她说：'赢了回来，我请你们吃一个月。'" },
            { speaker = "旁白", text = "六小时的大巴。三个收费站，一个军队检查点，两次爆胎。Snake全程盯着窗外，一句话没说。" },
            { speaker = "旁白", text = "Kofi晕车吐了三次。Grace在后排唱圣歌。Big Joe把最后一瓶水让给了最小的队员。" },
            { speaker = "你", text = "700公里。700公里的颠簸、灰尘和不确定。但车上每个人的眼睛——都是亮的。", type = "monologue" },
            { speaker = "旁白", text = "拉各斯的夜景在车窗外铺开。万家灯火。一间酒店房间挤五个人、三张床。" },
            { speaker = "旁白", text = "Thunder凌晨两点还在走廊做拉伸。他说：'手腕有点疼。但上了赛场什么都不会疼。'" },
            { speaker = "你", text = "站在阳台上看着拉各斯的霓虹——从铁皮屋到这里，我们是用汗水和停电的黑夜一步步走过来的。", type = "monologue" },
            { speaker = "你", text = "不管明天结果如何。值了。", type = "monologue" },
        },
        scene = "summit",
    },
    -- ================================================================
    -- 第五章：Dragon Force
    -- ================================================================
    {
        title = "第五章：Dragon Force",
        atmosphere = "聚光灯亮起。两千人的观众席。从铁皮屋走出来的战队，站在了大陆的舞台中央。",
        bgm = "match",
        ambient = "none",
        comic_panels = {
            {
                template = "splash",
                imageKey = "ch5_splash",
                title = "第五章 · Dragon Force",
                subtitle = "让全世界知道我们来了",
                duration = 3.5,
                textDelay = 1.0,
                lines = {},
            },
        },
        dialogues = {
            { speaker = "你", text = "我又站在了起点。不同的城市，不同的面孔，但同样的黄昏。", type = "monologue" },
            { speaker = "你", text = "表叔去年回了国。这边只剩我一个老陈家的人。但我不再孤单。", type = "monologue" },
            { speaker = "旁白", text = "非洲电竞中心的大门在晨光中打开。12个国家，32支队伍，2000个座位的观众席。" },
            { speaker = "旁白", text = "走进场馆的那一刻，Big Joe的手在发抖。Grace紧紧攥着十字架项链。只有Snake面无表情。" },
            { speaker = "旁白", text = "大屏幕上滚动着各支战队的名字——Dragon Force，排在第28位。没人看好一间铁皮屋里走出来的队伍。" },
            { speaker = "旁白", text = "Snake终于开口了：'老板，我们连停电都扛过来了——还怕这个？'" },
            { speaker = "旁白", text = "Grace说：'不要惧怕。' Thunder活动着手腕：'0.1秒就够了。'" },
            { speaker = "你", text = "今天。让全世界知道——", type = "monologue" },
            { speaker = "你", text = "Dragon Force。我们来了。", type = "monologue" },
            { speaker = "旁白", text = "掌声。灯光。倒计时。屏幕亮起——" },
        },
        isFinalBattle = true,
    },
}

--- 获取章节场景图索引（兼容旧代码）
M.CHAPTER_IMAGE_KEYS = {
    "ch1", "ch2", "ch4", "ch3", "ch5",
}

return M
