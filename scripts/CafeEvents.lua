---@diagnostic disable: undefined-global
-- ============================================================================
-- 网吧实时经营事件系统 — CafeEvents.lua
-- 6大类 ~48个事件，全部需要玩家决策
-- ============================================================================

-- ── 事件类别配色 ──
CAFE_CAT_COLORS = {
    customer  = { 80, 180, 255, 255 },
    equipment = { 255, 160, 50, 255 },
    africa    = { 120, 200, 80, 255 },
    business  = { 255, 210, 70, 255 },
    social    = { 200, 130, 255, 255 },
    rare      = { 255, 80, 120, 255 },
}

CAFE_CAT_ICONS = {
    customer  = "🧑‍💻",
    equipment = "⚡",
    africa    = "🌍",
    business  = "💼",
    social    = "👥",
    rare      = "🌟",
}

CAFE_CAT_NAMES = {
    customer  = "客户故事",
    equipment = "设备危机",
    africa    = "非洲日常",
    business  = "商机降临",
    social    = "人情世故",
    rare      = "奇遇事件",
}

-- ── 稀有度配色（暖棕深色主题） ──
CAFE_RARITY_BORDER = {
    common   = { 80, 68, 55, 120 },
    uncommon = { 100, 160, 130, 160 },
    rare     = { 200, 165, 50, 180 },
    epic     = { 255, 180, 50, 255 },
}

CAFE_RARITY_BG = {
    common   = { 42, 35, 28, 235 },
    uncommon = { 40, 42, 32, 240 },
    rare     = { 52, 42, 25, 245 },
    epic     = { 60, 48, 18, 250 },
}

CAFE_RARITY_LABEL = {
    common = "", uncommon = "💎", rare = "👑", epic = "🔥",
}

-- ============================================================================
-- 事件数据池（全部 choice 类型）
-- ============================================================================
CAFE_EVENTS = {
    -- ═══════════════════════════════════════════════════════════
    -- 🧑‍💻 Category 1: 客户故事
    -- ═══════════════════════════════════════════════════════════
    { id = "student_group", category = "customer", rarity = "common",
      title = "📚 学生自习团",
      desc = "五个大学生想用电脑写论文，问能不能打个折。",
      type = "choice",
      choices = {
          { text = "💰 原价收费", hint = "短期收益↑ · 回头客↓",
            ethics = { moneyVsPeople = -1 },
            effect = function()
                playerData_.money = playerData_.money + 35
                return "💰 +$35，学生老实付了全价"
            end },
          { text = "🤝 打八折", hint = "收入略少 · 口碑积累",
            ethics = { moneyVsPeople = 1 },
            effect = function()
                playerData_.money = playerData_.money + 25
                playerData_.reputation = playerData_.reputation + 5
                return "💰 +$25 | 声望 +5，他们说下次还来"
            end },
      } },

    { id = "gamer_kid", category = "customer", rarity = "common",
      title = "🎮 翘课的小鬼头",
      desc = "穿校服的男孩溜进来，看起来才十二岁。",
      type = "choice",
      choices = {
          { text = "📞 联系家长", hint = "收入无 · 社区口碑大增",
            ethics = { legalVsGray = 1, moneyVsPeople = 1 },
            effect = function()
                playerData_.reputation = playerData_.reputation + 8
                playerData_.karma = playerData_.karma + 1
                return "📞 声望 +8，邻居夸你有责任心"
            end },
          { text = "🎮 让他玩一局", hint = "快钱 · 可能被家长投诉",
            ethics = { legalVsGray = -1, moneyVsPeople = -1 },
            effect = function()
                playerData_.money = playerData_.money + 15
                if math.random() < 0.3 then
                    playerData_.reputation = playerData_.reputation + 3
                    return "💰 +$15 | 声望 +3"
                else
                    playerData_.reputation = playerData_.reputation - 5
                    return "💰 +$15 | 他妈找上门了，声望 -5"
                end
            end },
      } },

    { id = "business_man", category = "customer", rarity = "uncommon",
      title = "👔 西装革履的商人",
      desc = "穿西装的男人要发紧急邮件，出手很阔绰。",
      type = "choice",
      choices = {
          { text = "🏷️ 按标准收费", hint = "稳定收入 · 无额外人情",
            effect = function()
                playerData_.money = playerData_.money + 30
                return "💰 +$30，公事公办"
            end },
          { text = "☕ 送杯咖啡招待", hint = "小投入 · 可能获大额小费",
            ethics = { integrationVsExtraction = 1 },
            effect = function()
                local tip = 60 + math.random(1, 40)
                playerData_.money = playerData_.money + tip
                playerData_.reputation = playerData_.reputation + 5
                return "💰 +$" .. tip .. "（含小费）| 声望 +5"
            end },
      } },

    { id = "tourist_lost", category = "customer", rarity = "uncommon",
      title = "🗺️ 迷路的游客",
      desc = "欧洲游客手机没电，找不到酒店，快哭了。",
      type = "choice",
      choices = {
          { text = "🤝 免费帮忙", hint = "无收入 · 网评大涨 · 长远回报",
            ethics = { moneyVsPeople = 1, integrationVsExtraction = 1 },
            effect = function()
                playerData_.reputation = playerData_.reputation + 12
                playerData_.karma = playerData_.karma + 2
                return "声望 +12，他在网上给你写了五星好评"
            end },
          { text = "💵 收$20服务费", hint = "即时收入 · 人情味略薄",
            ethics = { moneyVsPeople = -1 },
            effect = function()
                playerData_.money = playerData_.money + 20
                playerData_.reputation = playerData_.reputation + 3
                return "💰 +$20 | 声望 +3"
            end },
      } },

    { id = "couple_quarrel", category = "customer", rarity = "common",
      title = "💔 情侣吵架了",
      desc = "3号机情侣大吵，其他客人在偷偷录像。",
      type = "choice",
      choices = {
          { text = "🕊️ 过去劝和",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                if math.random() < 0.6 then
                    return "🕊️ 三言两语劝好了，+1善缘"
                else
                    return "😅 被他俩一起骂了……但至少不吵了"
                end
            end },
          { text = "🙈 不管",
            effect = function()
                playerData_.money = playerData_.money - 10
                return "😤 吵了半小时，吓跑两个客人，-$10"
            end },
      } },

    { id = "old_man_email", category = "customer", rarity = "common",
      title = "👴 爷爷要发邮件",
      desc = "老人想给英国的孙子发邮件，但不会用电脑。",
      type = "choice",
      choices = {
          { text = "💝 手把手教他",
            effect = function()
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 10
                return "💝 声望 +10，老人感动落泪"
            end },
          { text = "💵 代写$5",
            effect = function()
                playerData_.money = playerData_.money + 5
                playerData_.karma = playerData_.karma + 1
                return "💰 +$5，帮他写好了邮件"
            end },
      } },

    { id = "youtuber_visit", category = "customer", rarity = "uncommon",
      title = "📱 网红来直播",
      desc = "5万粉丝的网红想在你店里直播，问能不能免单。",
      type = "choice",
      choices = {
          { text = "🆓 免单换宣传",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                return "📢 声望 +15，当天就有新客慕名而来"
            end },
          { text = "💰 正常收费",
            effect = function()
                playerData_.money = playerData_.money + 20
                playerData_.reputation = playerData_.reputation + 5
                return "💰 +$20 | 声望 +5，直播里顺带提了一嘴"
            end },
      } },

    { id = "scammer_spotted", category = "customer", rarity = "uncommon",
      title = "🚨 发现诈骗犯",
      desc = "5号机戴墨镜的人在发419诈骗邮件。",
      type = "choice",
      choices = {
          { text = "🚔 赶走他",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                playerData_.karma = playerData_.karma + 2
                playerData_.money = playerData_.money - 20
                return "🚔 -$20网费，但声望 +15"
            end },
          { text = "🙈 装没看见",
            effect = function()
                playerData_.money = playerData_.money + 20
                playerData_.karma = playerData_.karma - 2
                if math.random() < 0.25 then
                    playerData_.reputation = playerData_.reputation - 20
                    return "💰 +$20 但被举报了！声望 -20"
                else
                    return "💰 +$20，希望没事……"
                end
            end },
      } },

    { id = "marathon_gamer", category = "customer", rarity = "common",
      title = "🌙 要包夜的小伙",
      desc = "Emmanuel带着毯子来了，要通宵打游戏。",
      type = "choice",
      choices = {
          { text = "💰 收包夜费$25",
            effect = function()
                playerData_.money = playerData_.money + 25
                return "💰 +$25，他打到凌晨四点趴键盘睡着了"
            end },
          { text = "🚫 劝他回家休息",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 3
                return "他不情愿地走了，声望 +3"
            end },
      } },

    { id = "sleeping_customer", category = "customer", rarity = "common",
      title = "💤 客人睡着了",
      desc = "司机大叔在空调房里睡着了，计时器还在跑。",
      type = "choice",
      choices = {
          { text = "⏰ 叫醒他",
            effect = function()
                playerData_.money = playerData_.money + 10
                return "他又玩了一小时，+$10"
            end },
          { text = "😴 让他睡",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 3
                return "😴 声望 +3，他醒来直呼老板好人"
            end },
      } },

    { id = "crying_child", category = "customer", rarity = "uncommon",
      title = "😢 门口哭泣的小女孩",
      desc = "小女孩说妈妈去集市了，已经等了三小时。",
      type = "choice",
      choices = {
          { text = "🏠 关店去找她妈",
            effect = function()
                playerData_.money = playerData_.money - 15
                playerData_.karma = playerData_.karma + 3
                playerData_.reputation = playerData_.reputation + 15
                return "-$15 | 声望 +15，整条街都夸你"
            end },
          { text = "🥤 给她水和零食",
            effect = function()
                playerData_.money = playerData_.money - 5
                playerData_.karma = playerData_.karma + 1
                return "-$5，她妈妈来后连声道谢"
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- ⚡ Category 2: 设备危机
    -- ═══════════════════════════════════════════════════════════
    { id = "mouse_broken", category = "equipment", rarity = "common",
      title = "🖱️ 鼠标又坏了",
      desc = "4号机鼠标左键失灵，这个月第三个了。",
      type = "choice",
      choices = {
          { text = "🔧 换新鼠标 -$15",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "🔧 -$15，换了新鼠标"
            end },
          { text = "🛠️ 试着修修",
            effect = function()
                if math.random() < 0.5 then
                    return "🛠️ 修好了！省了一笔"
                else
                    playerData_.money = playerData_.money - 15
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 2)
                    return "❌ 修不好，还是换了。-$15 | 设备 -2%"
                end
            end },
      } },

    { id = "power_surge", category = "equipment", rarity = "common",
      title = "⚡ 电压不稳",
      desc = "屏幕闪烁，灯光忽明忽暗，客人们很紧张。",
      type = "choice",
      choices = {
          { text = "🔌 立即关机保护",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "-$15（客人走了几个），但设备安全"
            end },
          { text = "🤞 赌一把继续营业",
            effect = function()
                if math.random() < 0.3 then
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 8)
                    playerData_.money = playerData_.money - 40
                    return "💥 烧了主板！-$40 | 设备 -8%"
                else
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 2)
                    return "😮‍💨 虚惊一场，UPS撑住了。设备 -2%"
                end
            end },
      } },

    { id = "virus_attack", category = "equipment", rarity = "uncommon",
      title = "🦠 电脑中毒了",
      desc = "3号机弹出一堆广告，屏幕被锁了。",
      type = "choice",
      choices = {
          { text = "💻 重装系统",
            effect = function()
                playerData_.money = playerData_.money - 20
                return "💻 -$20（损失营业时间），电脑焕然一新"
            end },
          { text = "🛡️ 试试杀毒",
            effect = function()
                if math.random() < 0.6 then
                    return "🛡️ 杀毒成功！"
                else
                    playerData_.money = playerData_.money - 30
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 5)
                    return "❌ 失败，病毒扩散！-$30 | 设备 -5%"
                end
            end },
      } },

    { id = "keyboard_cola", category = "equipment", rarity = "common",
      title = "🥤 可乐泼键盘上了",
      desc = "客人打翻可乐，空格键按不下去了。",
      type = "choice",
      choices = {
          { text = "💰 让客人赔",
            effect = function()
                playerData_.money = playerData_.money - 7
                if math.random() < 0.5 then
                    playerData_.reputation = playerData_.reputation - 3
                    return "-$7（他只赔了一半），声望 -3"
                else
                    return "-$7，客人很歉疚地付了钱"
                end
            end },
          { text = "😅 算了自己换",
            effect = function()
                playerData_.money = playerData_.money - 12
                playerData_.reputation = playerData_.reputation + 3
                return "-$12 | 声望 +3，客人说你人真好"
            end },
      } },

    { id = "router_overheat", category = "equipment", rarity = "common",
      title = "🌡️ 路由器过热",
      desc = "路由器烫手，网速从10Mbps掉到2Mbps。",
      type = "choice",
      choices = {
          { text = "❄️ 冰块降温",
            effect = function()
                playerData_.money = playerData_.money - 5
                return "❄️ -$5，网速恢复了"
            end },
          { text = "🔌 关机冷却10分钟",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "🔌 -$15（走了几个客人），路由器恢复了"
            end },
      } },

    { id = "hard_drive_noise", category = "equipment", rarity = "uncommon",
      title = "💿 硬盘发出异响",
      desc = "1号机硬盘咔嗒响，随时可能报废。",
      type = "choice",
      choices = {
          { text = "🔄 立即备份换盘",
            effect = function()
                playerData_.money = playerData_.money - 50
                return "💾 -$50，数据安全，新盘到位"
            end },
          { text = "🤞 先用着",
            effect = function()
                if math.random() < 0.4 then
                    playerData_.money = playerData_.money - 80
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 10)
                    return "💥 硬盘挂了！-$80 | 设备 -10%"
                else
                    return "😅 还在响，但暂时没挂"
                end
            end },
      } },

    { id = "monitor_flicker", category = "equipment", rarity = "common",
      title = "📺 显示器闪烁",
      desc = "6号机显示器一直闪，客人揉着眼睛抱怨。",
      type = "choice",
      choices = {
          { text = "🔧 花钱修 -$25",
            effect = function()
                playerData_.money = playerData_.money - 25
                return "🔧 -$25，修好了"
            end },
          { text = "😬 先凑合用",
            effect = function()
                playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 4)
                return "📺 设备 -4%，下次再说吧"
            end },
      } },

    { id = "ups_dying", category = "equipment", rarity = "uncommon",
      title = "🔋 UPS电池快没了",
      desc = "UPS红灯闪烁蜂鸣，停电就全完了。",
      type = "choice",
      choices = {
          { text = "🔋 换电池 -$60",
            effect = function()
                playerData_.money = playerData_.money - 60
                return "🔋 -$60，续命成功"
            end },
          { text = "🤞 再撑撑",
            effect = function()
                if math.random() < 0.3 then
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 12)
                    playerData_.money = playerData_.money - 40
                    return "💥 停电了UPS没撑住！-$40 | 设备 -12%"
                else
                    return "😅 暂时没停电，侥幸过关"
                end
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- 🌍 Category 3: 非洲日常
    -- ═══════════════════════════════════════════════════════════
    { id = "power_outage", category = "africa", rarity = "common",
      title = "🕯️ 又停电了",
      desc = "灯灭了，客人叹气：\"NEPA又来了。\"",
      type = "choice",
      choices = {
          { text = "⚡ 启动发电机",
            effect = function()
                local genLv = playerData_.generatorLevel or 0
                if genLv > 0 and (playerData_.fuel or 0) > 0 then
                    playerData_.fuel = playerData_.fuel - 1
                    return "⚡ 燃油 -1，客人鼓掌"
                else
                    return "😅 没发电机/没油，白忙一场……-$25"
                end
            end },
          { text = "🕯️ 等来电",
            effect = function()
                playerData_.money = playerData_.money - 25
                return "🕯️ 停电2小时，客人全跑了。-$25"
            end },
      } },

    { id = "rain_leak", category = "africa", rarity = "common",
      title = "🌧️ 雨季漏水",
      desc = "暴雨天花板漏水，正好滴在2号机主机上。",
      type = "choice",
      choices = {
          { text = "🪣 用桶接住",
            effect = function()
                if math.random() < 0.7 then
                    return "🪣 桶放对了，今天没出事"
                else
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 5)
                    return "💧 水还是溅到主机了！设备 -5%"
                end
            end },
          { text = "🔨 花钱补屋顶",
            effect = function()
                playerData_.money = playerData_.money - 40
                playerData_.reputation = playerData_.reputation + 5
                return "🔨 -$40 | 声望 +5，以后不怕了"
            end },
      } },

    { id = "stray_goat", category = "africa", rarity = "uncommon",
      title = "🐐 山羊闯进来了",
      desc = "山羊嚼了网线，啃了鼠标垫，客人笑成一团。",
      type = "choice",
      choices = {
          { text = "🐐 赶走检查损失",
            effect = function()
                playerData_.money = playerData_.money - 8
                return "🐐 网线断了，-$8"
            end },
          { text = "📸 拍视频发社交媒体",
            effect = function()
                playerData_.money = playerData_.money - 8
                playerData_.reputation = playerData_.reputation + 10
                return "📸 视频3000赞！-$8 | 声望 +10"
            end },
      } },

    { id = "dust_storm", category = "africa", rarity = "uncommon",
      title = "🏜️ 沙尘暴",
      desc = "沙尘钻进门缝，风扇疯转，散热口全堵了。",
      type = "choice",
      choices = {
          { text = "🧹 立即停业清理",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "🧹 -$15（停业半天），设备保住了"
            end },
          { text = "😤 硬撑继续营业",
            effect = function()
                playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 6)
                playerData_.money = playerData_.money - 10
                return "🏜️ 设备 -6% | -$10清洁费"
            end },
      } },

    { id = "mosquito_raid", category = "africa", rarity = "common",
      title = "🦟 蚊子大军",
      desc = "傍晚蚊子泛滥，客人边打游戏边拍蚊子。",
      type = "choice",
      choices = {
          { text = "🪥 买蚊香 -$10",
            effect = function()
                playerData_.money = playerData_.money - 10
                return "🪥 -$10，蚊子退了"
            end },
          { text = "🪟 装纱窗 -$45",
            effect = function()
                playerData_.money = playerData_.money - 45
                playerData_.reputation = playerData_.reputation + 5
                return "🪟 -$45 | 声望 +5，以后不怕了"
            end },
      } },

    { id = "heat_wave", category = "africa", rarity = "common",
      title = "🌡️ 42度高温",
      desc = "室外42度，没空调就是桑拿房。",
      type = "choice",
      choices = {
          { text = "💨 买风扇应急 -$15",
            effect = function()
                playerData_.money = playerData_.money - 15
                local ac = playerData_.acLevel or 0
                if ac >= 1 then
                    return "有空调+风扇，客人很舒服"
                else
                    return "💨 -$15，比没有强"
                end
            end },
          { text = "😤 硬扛",
            effect = function()
                local ac = playerData_.acLevel or 0
                if ac >= 2 then
                    playerData_.reputation = playerData_.reputation + 5
                    return "❄️ 空调给力！声望 +5"
                elseif ac >= 1 then
                    return "🌡️ 空调勉强撑住"
                else
                    playerData_.money = playerData_.money - 20
                    return "🥵 客人跑了一半，-$20"
                end
            end },
      } },

    { id = "road_flooded", category = "africa", rarity = "uncommon",
      title = "🌊 路被淹了",
      desc = "暴雨把路变成泥河，客人来不了。",
      type = "choice",
      choices = {
          { text = "🛣️ 铺木板搭便道 -$10",
            effect = function()
                playerData_.money = playerData_.money - 10
                playerData_.reputation = playerData_.reputation + 5
                return "-$10 | 声望 +5，客人能勉强过来"
            end },
          { text = "🏠 今天歇业",
            effect = function()
                local road = playerData_.roadLevel or 0
                if road >= 1 then
                    playerData_.money = playerData_.money - 10
                    return "修过的路排水还行，只损失 -$10"
                else
                    playerData_.money = playerData_.money - 35
                    return "🌊 整天没客人，-$35"
                end
            end },
      } },

    { id = "religious_festival", category = "africa", rarity = "uncommon",
      title = "🕌 宗教节日",
      desc = "今天全城休假，街上几乎没人。",
      type = "choice",
      choices = {
          { text = "🕌 尊重节日·半价营业",
            effect = function()
                playerData_.money = playerData_.money - 10
                playerData_.reputation = playerData_.reputation + 5
                return "-$10 | 声望 +5，入乡随俗"
            end },
          { text = "💰 正常营业",
            effect = function()
                playerData_.money = playerData_.money - 15
                playerData_.reputation = playerData_.reputation + 3
                return "-$15，客流减半 | 声望 +3"
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- 💼 Category 4: 商机降临
    -- ═══════════════════════════════════════════════════════════
    { id = "bulk_booking", category = "business", rarity = "uncommon",
      title = "🏢 公司要包场",
      desc = "建筑公司想包场团建，但散客就没位了。",
      type = "choice",
      choices = {
          { text = "✅ 接受包场",
            effect = function()
                local bonus = 80 + math.random(1, 40)
                playerData_.money = playerData_.money + bonus
                playerData_.reputation = playerData_.reputation + 8
                return "✅ +$" .. bonus .. " | 声望 +8"
            end },
          { text = "❌ 婉拒",
            effect = function()
                playerData_.reputation = playerData_.reputation + 3
                return "❌ 常客说谢谢老板没赶我走。声望 +3"
            end },
      } },

    { id = "wall_ad", category = "business", rarity = "common",
      title = "📋 有人想贴广告",
      desc = "手机壳商人想每月付$20在你墙上贴广告。",
      type = "choice",
      choices = {
          { text = "💰 同意",
            effect = function()
                playerData_.money = playerData_.money + 20
                return "💰 +$20，虽然广告有点丑"
            end },
          { text = "🚫 拒绝",
            effect = function()
                playerData_.reputation = playerData_.reputation + 3
                return "🚫 声望 +3，保持专业形象"
            end },
      } },

    { id = "food_collab", category = "business", rarity = "common",
      title = "🍗 Mama想合作",
      desc = "Mama Blessing提议在店里设餐窗，收入五五分。",
      type = "choice",
      choices = {
          { text = "🤝 合作",
            effect = function()
                playerData_.money = playerData_.money + 25
                playerData_.reputation = playerData_.reputation + 8
                return "🤝 +$25 | 声望 +8，烤鸡飘香"
            end },
          { text = "😅 婉拒",
            effect = function()
                return "😅 Mama有点失望"
            end },
      } },

    { id = "phone_charge", category = "business", rarity = "common",
      title = "🔌 充电需求",
      desc = "今天五个人问能不能充手机。",
      type = "choice",
      choices = {
          { text = "💡 提供充电服务",
            effect = function()
                playerData_.money = playerData_.money + 15
                playerData_.reputation = playerData_.reputation + 5
                return "🔌 +$15 | 声望 +5"
            end },
          { text = "🚫 拒绝",
            effect = function()
                return "🔌 拒绝了，有点于心不忍"
            end },
      } },

    { id = "school_deal", category = "business", rarity = "rare",
      title = "🏫 学校想合作",
      desc = "中学校长想每周带学生来上电脑课，$50一次。",
      type = "choice",
      choices = {
          { text = "📝 签约",
            effect = function()
                playerData_.money = playerData_.money + 50
                playerData_.reputation = playerData_.reputation + 20
                return "📝 +$50 | 声望 +20"
            end },
          { text = "😬 婉拒",
            effect = function()
                return "📝 校长叹了口气走了"
            end },
      } },

    { id = "competition_opens", category = "business", rarity = "common",
      title = "🏪 对面开了新网吧",
      desc = "\"Super Fast Net\"开业半价促销，常客被吸走了。",
      type = "choice",
      choices = {
          { text = "💪 也搞促销反击",
            effect = function()
                playerData_.money = playerData_.money - 15
                playerData_.reputation = playerData_.reputation + 5
                return "-$15 | 声望 +5，客人回来了一些"
            end },
          { text = "😤 按兵不动",
            effect = function()
                playerData_.money = playerData_.money - 20
                playerData_.reputation = playerData_.reputation - 5
                return "-$20 | 声望 -5，流失了客人"
            end },
      } },

    { id = "delivery_promo", category = "business", rarity = "uncommon",
      title = "📦 配件商搞促销",
      desc = "拉各斯配件商清仓大促，键盘鼠标买三送一。",
      type = "choice",
      choices = {
          { text = "🛒 趁机囤货",
            effect = function()
                playerData_.money = playerData_.money - 30
                playerData_.equipCondition = math.min(100, (playerData_.equipCondition or 100) + 8)
                return "🛒 -$30 | 设备 +8%，划算"
            end },
          { text = "✋ 不需要",
            effect = function()
                return "✋ 省了钱，但错过了好价格"
            end },
      } },

    { id = "printing_request", category = "business", rarity = "common",
      title = "🖨️ 打印需求",
      desc = "很多人来问能不能打印简历和表格。",
      type = "choice",
      choices = {
          { text = "🖨️ 帮忙打印收费",
            effect = function()
                playerData_.money = playerData_.money + 15
                return "🖨️ +$15，新的收入来源"
            end },
          { text = "🚫 不接这活",
            effect = function()
                return "🚫 拒绝了，专注本业"
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- 👥 Category 5: 人情世故
    -- ═══════════════════════════════════════════════════════════
    { id = "neighbor_noise", category = "social", rarity = "common",
      title = "😤 邻居投诉噪音",
      desc = "裁缝大婶说你店里太吵，要去找村长。",
      type = "choice",
      choices = {
          { text = "🙏 道歉送饮料",
            effect = function()
                playerData_.money = playerData_.money - 10
                playerData_.reputation = playerData_.reputation + 5
                return "🙏 -$10 | 声望 +5"
            end },
          { text = "😤 据理力争",
            effect = function()
                playerData_.reputation = playerData_.reputation - 8
                return "😤 吵了一架，声望 -8"
            end },
      } },

    { id = "thief_attempt", category = "social", rarity = "uncommon",
      title = "🕵️ 有人偷鼠标",
      desc = "7号机客人把鼠标塞进了背包。",
      type = "choice",
      choices = {
          { text = "🚔 当面揭穿",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                return "🚔 声望 +5，其他人不敢了"
            end },
          { text = "🤫 私下提醒",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                return "🤫 他羞愧地还了，+1善缘"
            end },
      } },

    { id = "regular_gift", category = "social", rarity = "uncommon",
      title = "🎁 Kwame的礼物",
      desc = "常客Kwame找到工作了，送来一箱芒果感谢你。",
      type = "choice",
      choices = {
          { text = "🥭 收下并祝贺",
            effect = function()
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 8
                return "🥭 声望 +8，有些回报比钱珍贵"
            end },
          { text = "🤝 收下并送他一小时免费",
            effect = function()
                playerData_.karma = playerData_.karma + 3
                playerData_.reputation = playerData_.reputation + 12
                return "🤝 声望 +12，他说永远是你的常客"
            end },
      } },

    { id = "beggar_outside", category = "social", rarity = "common",
      title = "🙏 门口的乞丐",
      desc = "残疾老人坐在门口乞讨，客人进出不自在。",
      type = "choice",
      choices = {
          { text = "🍞 给食物和水",
            effect = function()
                playerData_.money = playerData_.money - 5
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 5
                return "🍞 -$5 | 声望 +5"
            end },
          { text = "🚶 请他离开",
            effect = function()
                playerData_.karma = playerData_.karma - 1
                return "🚶 他默默离开了，心里有点不是滋味"
            end },
      } },

    { id = "chief_inspection", category = "social", rarity = "uncommon",
      title = "👑 村长来视察",
      desc = "村长带随从来了，东看看西看看。",
      type = "choice",
      choices = {
          { text = "🍵 热情招待",
            effect = function()
                playerData_.money = playerData_.money - 10
                playerData_.reputation = playerData_.reputation + 15
                return "-$10 | 声望 +15，村长很满意"
            end },
          { text = "😐 正常接待",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                return "声望 +5，村长说还不错"
            end },
      } },

    { id = "mama_special", category = "social", rarity = "rare",
      title = "🍗 Mama的秘制烤鸡",
      desc = "Mama Blessing端了一盘烤鸡进来犒劳大家。",
      type = "choice",
      choices = {
          { text = "🍗 全员分享",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, (m.mood or 50) + 10)
                end
                playerData_.reputation = playerData_.reputation + 5
                return "🍗 全队心情 +10 | 声望 +5"
            end },
          { text = "🎁 回赠她免费上网券",
            effect = function()
                for _, m in ipairs(teamMembers_) do
                    m.mood = math.min(100, (m.mood or 50) + 10)
                end
                playerData_.reputation = playerData_.reputation + 10
                return "🍗 全队心情 +10 | 声望 +10"
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- 🌟 Category 6: 奇遇事件
    -- ═══════════════════════════════════════════════════════════
    { id = "celebrity_visit", category = "rare", rarity = "rare",
      title = "⭐ 明星来了！",
      desc = "Nollywood明星车抛锚，进来借WiFi。",
      type = "choice",
      choices = {
          { text = "📸 求合照发朋友圈",
            effect = function()
                playerData_.money = playerData_.money + 50
                playerData_.reputation = playerData_.reputation + 30
                return "⭐ +$50小费 | 声望 +30，照片挂墙上"
            end },
          { text = "🤫 低调服务",
            effect = function()
                playerData_.money = playerData_.money + 30
                playerData_.reputation = playerData_.reputation + 15
                playerData_.karma = playerData_.karma + 1
                return "💰 +$30 | 声望 +15，他说下次还来"
            end },
      } },

    { id = "documentary_crew", category = "rare", rarity = "rare",
      title = "🎬 BBC来拍纪录片",
      desc = "英国摄制组想拍你的网吧故事。",
      type = "choice",
      choices = {
          { text = "🎬 同意拍摄",
            effect = function()
                playerData_.reputation = playerData_.reputation + 40
                playerData_.money = playerData_.money + 80
                return "🎬 +$80 | 声望 +40"
            end },
          { text = "🚫 婉拒",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                return "🚫 低调才是真高调"
            end },
      } },

    { id = "gold_payment", category = "rare", rarity = "epic",
      title = "🥇 客人用金子付账",
      desc = "矿区来的老客掏出金子抵网费。",
      type = "choice",
      choices = {
          { text = "🥇 收下金子",
            effect = function()
                playerData_.goldOunces = (playerData_.goldOunces or 0) + 0.1
                return "🥇 +0.1盎司黄金！比网费贵多了"
            end },
          { text = "💵 让他下次付现金",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 5
                return "他很感动，声望 +5"
            end },
      } },

    { id = "only_power", category = "rare", rarity = "rare",
      title = "💡 只有你家有电",
      desc = "大面积停电，你的发电机让网吧成了灯塔。",
      type = "choice",
      minDay = 5,
      condition = function()
          return (playerData_.generatorLevel or 0) >= 1 or (playerData_.solarLevel or 0) >= 1
      end,
      choices = {
          { text = "💡 正常收费接客",
            effect = function()
                local bonus = 60 + math.random(1, 40)
                playerData_.money = playerData_.money + bonus
                playerData_.reputation = playerData_.reputation + 15
                return "💡 爆满！+$" .. bonus .. " | 声望 +15"
            end },
          { text = "🤝 半价优惠",
            effect = function()
                local bonus = 30 + math.random(1, 20)
                playerData_.money = playerData_.money + bonus
                playerData_.reputation = playerData_.reputation + 25
                return "🤝 +$" .. bonus .. " | 声望 +25，人人夸你"
            end },
      } },

    { id = "viral_video", category = "rare", rarity = "rare",
      title = "📱 视频意外走红",
      desc = "客人的神操作录屏在TikTok上爆了100万播放。",
      type = "choice",
      choices = {
          { text = "📱 蹭热度发营业视频",
            effect = function()
                playerData_.reputation = playerData_.reputation + 25
                playerData_.money = playerData_.money + 40
                return "📱 声望 +25 | +$40"
            end },
          { text = "😎 随他去",
            effect = function()
                playerData_.reputation = playerData_.reputation + 15
                return "📱 声望 +15，不蹭也沾光了"
            end },
      } },

    { id = "mysterious_usb", category = "rare", rarity = "epic",
      title = "🔮 神秘U盘",
      desc = "打扫时发现金色U盘，刻着奇怪符号。",
      type = "choice",
      choices = {
          { text = "💰 插上看看",
            effect = function()
                if math.random() < 0.5 then
                    local reward = 100 + math.random(1, 100)
                    playerData_.money = playerData_.money + reward
                    return "💰 +$" .. reward .. "！里面有加密货币"
                else
                    playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 8)
                    return "🦠 有病毒！设备 -8%"
                end
            end },
          { text = "🗑️ 扔掉",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                return "🗑️ 安全第一，也许错过一个亿"
            end },
      } },

    { id = "solar_eclipse", category = "rare", rarity = "epic",
      title = "🌑 日食奇观",
      desc = "日食来了，客人全冲出去看，有人喊快直播！",
      type = "choice",
      choices = {
          { text = "📡 用电脑直播",
            effect = function()
                playerData_.reputation = playerData_.reputation + 35
                playerData_.money = playerData_.money + 60
                return "📡 声望 +35 | +$60打赏"
            end },
          { text = "🌑 一起出去看",
            effect = function()
                playerData_.reputation = playerData_.reputation + 10
                playerData_.karma = playerData_.karma + 1
                return "🌑 声望 +10，历史性的一天"
            end },
      } },
    -- ═══════════════════════════════════════════════════════════
    -- 🌍 新增非洲日常事件
    -- ═══════════════════════════════════════════════════════════
    { id = "water_shortage", category = "africa", rarity = "common",
      title = "🚰 断水了",
      desc = "水管停供，厕所没法冲，客人开始抱怨味道。",
      type = "choice",
      choices = {
          { text = "🚚 叫送水车 -$20",
            effect = function()
                playerData_.money = playerData_.money - 20
                playerData_.reputation = playerData_.reputation + 5
                return "🚚 -$20 | 声望 +5，基本卫生保住了"
            end },
          { text = "🪣 自己去井里打水",
            effect = function()
                playerData_.money = playerData_.money - 5
                return "🪣 -$5，累了一下午但凑合着用"
            end },
      } },

    { id = "sim_card_seller", category = "africa", rarity = "common",
      title = "📱 卖SIM卡的小贩",
      desc = "门口小贩问能不能借你的店面卖MTN充值卡，给你分成。",
      type = "choice",
      choices = {
          { text = "🤝 合作分成",
            effect = function()
                playerData_.money = playerData_.money + 15
                playerData_.reputation = playerData_.reputation + 3
                return "💰 +$15 | 声望 +3，互惠互利"
            end },
          { text = "🚫 拒绝",
            effect = function()
                return "🚫 拒绝了，不想节外生枝"
            end },
      } },

    { id = "okada_accident", category = "africa", rarity = "uncommon",
      title = "🏍️ 摩的撞了门口",
      desc = "Okada司机躲坑摔倒，撞坏了你的招牌。",
      type = "choice",
      choices = {
          { text = "🩹 帮忙包扎不追究",
            effect = function()
                playerData_.money = playerData_.money - 15
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 10
                return "🩹 -$15修招牌 | 声望 +10，街坊称赞"
            end },
          { text = "💰 让他赔招牌",
            effect = function()
                if math.random() < 0.4 then
                    playerData_.money = playerData_.money + 10
                    return "💰 +$10，他掏光了口袋"
                else
                    playerData_.money = playerData_.money - 15
                    return "-$15，他说明天再来赔，你信吗？"
                end
            end },
      } },

    { id = "mango_season", category = "africa", rarity = "common",
      title = "🥭 芒果季来了",
      desc = "树上芒果掉在铁皮屋顶砰砰响，客人以为下冰雹。",
      type = "choice",
      choices = {
          { text = "🥭 捡来分给客人",
            effect = function()
                playerData_.reputation = playerData_.reputation + 8
                playerData_.karma = playerData_.karma + 1
                return "🥭 声望 +8，客人边吃边玩"
            end },
          { text = "🪓 找人砍掉树枝 -$10",
            effect = function()
                playerData_.money = playerData_.money - 10
                return "🪓 -$10，终于不砸了"
            end },
      } },

    { id = "jollof_debate", category = "africa", rarity = "common",
      title = "🍚 Jollof Rice大争论",
      desc = "尼日利亚和加纳的客人为了谁家Jollof Rice更好吃吵起来。",
      type = "choice",
      choices = {
          { text = "🏳️ 两边都夸",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                return "🏳️ 声望 +5，你的外交能力满分"
            end },
          { text = "🍳 买两份来盲测",
            effect = function()
                playerData_.money = playerData_.money - 12
                playerData_.reputation = playerData_.reputation + 12
                return "🍳 -$12 | 声望 +12，成了网吧传奇故事"
            end },
      } },

    { id = "football_match", category = "africa", rarity = "uncommon",
      title = "⚽ 非洲杯比赛日",
      desc = "今晚非洲杯决赛，大家想在你的大屏幕看球。",
      type = "choice",
      choices = {
          { text = "📺 办观赛派对 -$20",
            effect = function()
                playerData_.money = playerData_.money - 20 + 45
                playerData_.reputation = playerData_.reputation + 15
                return "⚽ -$20成本 +$45饮料收入 | 声望 +15，全场欢呼"
            end },
          { text = "🚫 正常营业",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "🚫 -$15，大家都去别处看球了"
            end },
      } },

    { id = "nollywood_binge", category = "africa", rarity = "common",
      title = "🎬 Nollywood追剧潮",
      desc = "新一季Nollywood爆款剧上线，网速被看剧的人拖慢。",
      type = "choice",
      choices = {
          { text = "📡 限速分流",
            effect = function()
                playerData_.reputation = playerData_.reputation - 3
                return "📡 游戏玩家松口气，追剧的不太开心。声望 -3"
            end },
          { text = "📡 升级带宽 -$30",
            effect = function()
                playerData_.money = playerData_.money - 30
                playerData_.reputation = playerData_.reputation + 8
                return "📡 -$30 | 声望 +8，皆大欢喜"
            end },
      } },

    { id = "harmattan_dust", category = "africa", rarity = "uncommon",
      title = "🌫️ 哈马丹季节",
      desc = "干燥的沙漠风带来黄尘，咳嗽声此起彼伏，键盘缝隙全是沙。",
      type = "choice",
      choices = {
          { text = "😷 买口罩和清洁用品 -$15",
            effect = function()
                playerData_.money = playerData_.money - 15
                playerData_.reputation = playerData_.reputation + 8
                return "😷 -$15 | 声望 +8，大家感谢你的贴心"
            end },
          { text = "🧹 每小时清理一次",
            effect = function()
                playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 3)
                return "🧹 设备 -3%，勉强撑过去了"
            end },
      } },

    { id = "market_day", category = "africa", rarity = "common",
      title = "🛒 赶集日",
      desc = "今天是大集，人流量翻倍但全是赶集路过的。",
      type = "choice",
      choices = {
          { text = "📢 门口招揽",
            effect = function()
                local bonus = 15 + math.random(1, 25)
                playerData_.money = playerData_.money + bonus
                return "📢 +$" .. bonus .. "，拉来好几个新客人"
            end },
          { text = "🪧 门口摆广告牌",
            effect = function()
                playerData_.money = playerData_.money - 5
                playerData_.reputation = playerData_.reputation + 5
                return "🪧 -$5 | 声望 +5，有人记住了你的店"
            end },
      } },

    { id = "local_church", category = "africa", rarity = "common",
      title = "⛪ 教会请求帮忙",
      desc = "隔壁教会牧师想借电脑打印周日礼拜的歌单。",
      type = "choice",
      choices = {
          { text = "🤝 免费帮忙",
            effect = function()
                playerData_.karma = playerData_.karma + 2
                playerData_.reputation = playerData_.reputation + 10
                return "🤝 声望 +10，牧师在讲道中表扬了你"
            end },
          { text = "💰 收$5打印费",
            effect = function()
                playerData_.money = playerData_.money + 5
                return "💰 +$5，公事公办"
            end },
      } },

    { id = "mpesa_transfer", category = "africa", rarity = "common",
      title = "📲 M-Pesa转账帮忙",
      desc = "阿姨不会用M-Pesa，求你帮忙给儿子汇钱。",
      type = "choice",
      choices = {
          { text = "📲 免费帮忙操作",
            effect = function()
                playerData_.karma = playerData_.karma + 1
                playerData_.reputation = playerData_.reputation + 5
                return "📲 声望 +5，阿姨祝你生意兴隆"
            end },
          { text = "💰 收$3服务费",
            effect = function()
                playerData_.money = playerData_.money + 3
                return "💰 +$3，合理收费"
            end },
      } },

    { id = "generator_fuel", category = "africa", rarity = "common",
      title = "⛽ 柴油又涨价了",
      desc = "油站大叔说柴油从$1.5涨到$2.5一升。",
      type = "choice",
      choices = {
          { text = "⛽ 囤10升 -$25",
            effect = function()
                playerData_.money = playerData_.money - 25
                playerData_.fuel = (playerData_.fuel or 0) + 3
                return "⛽ -$25 | 燃油 +3，未雨绸缪"
            end },
          { text = "🤷 用多少买多少",
            effect = function()
                return "🤷 走一步看一步，希望别再涨了"
            end },
      } },

    { id = "snake_visit", category = "africa", rarity = "uncommon",
      title = "🐍 蛇钻进机箱了",
      desc = "客人尖叫——一条绿曼巴蛇从3号机机箱后面溜出来。",
      type = "choice",
      choices = {
          { text = "🧑‍🔧 叫捕蛇人 -$15",
            effect = function()
                playerData_.money = playerData_.money - 15
                return "🐍 -$15，专业人士安全处理了"
            end },
          { text = "🦸 自己拿棍子赶",
            effect = function()
                if math.random() < 0.6 then
                    playerData_.reputation = playerData_.reputation + 10
                    return "🦸 成功！声望 +10，客人封你为勇者"
                else
                    playerData_.reputation = playerData_.reputation - 5
                    playerData_.money = playerData_.money - 10
                    return "😱 蛇跑了！客人全吓跑，-$10 | 声望 -5"
                end
            end },
      } },

    { id = "load_shedding", category = "africa", rarity = "common",
      title = "🔌 计划限电通知",
      desc = "电力公司贴了告示：明天下午2-6点限电。",
      type = "choice",
      choices = {
          { text = "📢 提前通知客人调整时间",
            effect = function()
                playerData_.reputation = playerData_.reputation + 5
                playerData_.money = playerData_.money - 10
                return "📢 -$10营业损失 | 声望 +5，客人说你靠谱"
            end },
          { text = "⚡ 买燃油准备发电",
            effect = function()
                playerData_.money = playerData_.money - 20
                playerData_.fuel = (playerData_.fuel or 0) + 2
                return "⚡ -$20 | 燃油 +2，硬扛过去"
            end },
      } },

    -- ═══════════════════════════════════════════════════════════
    -- 👥 新增人情世故事件
    -- ═══════════════════════════════════════════════════════════
    { id = "wedding_invite", category = "social", rarity = "uncommon",
      title = "💒 常客的婚礼",
      desc = "常客Amara要结婚了，邀请你参加并赞助一些饮料。",
      type = "choice",
      choices = {
          { text = "🎉 赞助饮料 -$25",
            effect = function()
                playerData_.money = playerData_.money - 25
                playerData_.reputation = playerData_.reputation + 15
                playerData_.karma = playerData_.karma + 2
                return "🎉 -$25 | 声望 +15，整个社区都知道你"
            end },
          { text = "🎁 送小礼物 -$10",
            effect = function()
                playerData_.money = playerData_.money - 10
                playerData_.reputation = playerData_.reputation + 5
                return "🎁 -$10 | 声望 +5，礼轻情意重"
            end },
      } },

    { id = "power_line_down", category = "africa", rarity = "uncommon",
      title = "⚡ 电线杆倒了",
      desc = "暴风雨刮倒电线杆，整条街停电，修复遥遥无期。",
      type = "choice",
      choices = {
          { text = "⚡ 全靠发电机撑 -$30",
            effect = function()
                playerData_.money = playerData_.money - 30
                local genLv = playerData_.generatorLevel or 0
                if genLv > 0 then
                    playerData_.money = playerData_.money + 50
                    playerData_.reputation = playerData_.reputation + 15
                    return "⚡ -$30油钱 +$50满座 | 声望 +15，唯一亮灯的店"
                else
                    return "😅 没发电机，花了$30也白搭"
                end
            end },
          { text = "🏠 歇业等来电",
            effect = function()
                playerData_.money = playerData_.money - 40
                return "🏠 -$40，等了两天才来电"
            end },
      } },

    { id = "taxi_driver_charge", category = "customer", rarity = "common",
      title = "🚕 出租车司机要充电",
      desc = "Uber司机手机快没电了，想付$2充十分钟电。",
      type = "choice",
      choices = {
          { text = "🔌 收$2让他充",
            effect = function()
                playerData_.money = playerData_.money + 2
                return "🔌 +$2，小钱但积少成多"
            end },
          { text = "🆓 免费充，换张名片",
            effect = function()
                playerData_.reputation = playerData_.reputation + 3
                return "🆓 声望 +3，他说会介绍乘客过来"
            end },
      } },

    { id = "afrobeats_party", category = "social", rarity = "common",
      title = "🎵 Afrobeats放太大声",
      desc = "几个青年把音响开到最大放Burna Boy，其他客人没法集中。",
      type = "choice",
      choices = {
          { text = "🎧 给他们耳机",
            effect = function()
                playerData_.money = playerData_.money - 8
                playerData_.reputation = playerData_.reputation + 5
                return "🎧 -$8买耳机 | 声望 +5，两全其美"
            end },
          { text = "🔇 让他们关小声",
            effect = function()
                if math.random() < 0.5 then
                    return "🔇 他们照做了，没脾气"
                else
                    playerData_.reputation = playerData_.reputation - 3
                    return "😤 他们不高兴走了，声望 -3"
                end
            end },
      } },

    { id = "crypto_craze", category = "business", rarity = "uncommon",
      title = "🪙 加密货币热潮",
      desc = "好几个年轻人问能不能开个\"加密货币角\"专门挖矿。",
      type = "choice",
      choices = {
          { text = "💰 开辟挖矿区 +$40",
            effect = function()
                playerData_.money = playerData_.money + 40
                playerData_.equipCondition = math.max(0, (playerData_.equipCondition or 100) - 5)
                return "💰 +$40 | 设备 -5%（显卡发烫）"
            end },
          { text = "🚫 拒绝，保护设备",
            effect = function()
                return "🚫 设备安全最重要"
            end },
      } },
}

-- ============================================================================
-- 事件生成与管理
-- ============================================================================

local RARITY_WEIGHTS = { common = 55, uncommon = 28, rare = 13, epic = 4 }

--- 生成当日网吧经营事件
function GenerateDailyCafeEvents()
    local day = playerData_.day or 1
    if cafeEventsDay_ == day then return end
    cafeEventsDay_ = day

    -- 按稀有度分池
    local pools = { common = {}, uncommon = {}, rare = {}, epic = {} }
    for i, evt in ipairs(CAFE_EVENTS) do
        if evt.minDay and day < evt.minDay then goto cont end
        if evt.condition and not evt.condition() then goto cont end
        local r = evt.rarity or "common"
        if pools[r] then table.insert(pools[r], i) end
        ::cont::
    end

    -- 事件数量：随机范围，随天数增长
    -- P1-2: D1 只产出1-2件事件（1必处理+1可选观察），D2-D3 产出2-3件
    local minCount, maxCount
    if day >= 20 then
        minCount, maxCount = 3, 6
    elseif day >= 10 then
        minCount, maxCount = 2, 5
    elseif day >= 4 then
        minCount, maxCount = 1, 4
    elseif day >= 2 then
        minCount, maxCount = 2, 3
    else
        minCount, maxCount = 1, 2
    end
    local count = math.random(minCount, maxCount)

    -- 加权随机抽取
    local selected = {}
    local usedIds = {}
    local recentIds = {}
    if cafeEvents_ then
        for _, ce in ipairs(cafeEvents_) do
            if ce.def then recentIds[ce.def.id] = true end
        end
    end

    for _ = 1, count + 5 do
        if #selected >= count then break end
        local totalW = 0
        for _, w in pairs(RARITY_WEIGHTS) do totalW = totalW + w end
        local roll = math.random(1, totalW)
        local accum = 0
        local chosenRarity = "common"
        for r, w in pairs(RARITY_WEIGHTS) do
            accum = accum + w
            if roll <= accum then chosenRarity = r; break end
        end
        local pool = pools[chosenRarity]
        if not pool or #pool == 0 then pool = pools.common end
        if not pool or #pool == 0 then goto skip end
        do
            local idx = pool[math.random(1, #pool)]
            local evt = CAFE_EVENTS[idx]
            if evt and not usedIds[evt.id] and not recentIds[evt.id] then
                usedIds[evt.id] = true
                table.insert(selected, {
                    def = evt,
                    resolved = false,
                    result = nil,
                    day = day,
                })
            end
        end
        ::skip::
    end

    -- 按稀有度排序
    local rarityOrder = { epic = 1, rare = 2, uncommon = 3, common = 4 }
    table.sort(selected, function(a, b)
        local ra = rarityOrder[a.def.rarity or "common"] or 4
        local rb = rarityOrder[b.def.rarity or "common"] or 4
        return ra < rb
    end)

    cafeEvents_ = selected
    pendingCafeCount_ = 0
    for _, ce in ipairs(cafeEvents_) do
        if not ce.resolved then pendingCafeCount_ = (pendingCafeCount_ or 0) + 1 end
    end
end

--- 解决一个网吧事件（仅处理 choice 类型）
function ResolveCafeEvent(eventIdx, choiceIdx)
    if not cafeEvents_ or not cafeEvents_[eventIdx] then return end
    local ce = cafeEvents_[eventIdx]
    if ce.resolved then return end

    -- 行动点检查：每天只需1个行动点即可处理所有事件
    local day = playerData_.day or 1
    if cafeActionUsedDay_ ~= day then
        -- 今天还没花过行动点，需要检查是否有行动点
        if (playerData_.actionPoints or 0) <= 0 then
            AddLog("⚡ 行动点不足，无法处理网吧事件")
            return
        end
    end
    -- 如果今天已经花过行动点（cafeActionUsedDay_ == day），直接放行

    local evt = ce.def
    local result = ""

    if evt.type == "choice" and choiceIdx then
        local choice = evt.choices[choiceIdx]
        if choice and choice.effect then
            local ok, res = pcall(choice.effect)
            ---@diagnostic disable-next-line: assign-type-mismatch
            result = ok and (res or "已处理") or ("⚠️ 处理出错")
        end
        -- P1-2: 接入 ethicsLedger —— 记录选择对伦理维度的影响
        if choice and choice.ethics and playerData_.ethicsLedger then
            for axis, delta in pairs(choice.ethics) do
                if playerData_.ethicsLedger[axis] ~= nil then
                    playerData_.ethicsLedger[axis] = playerData_.ethicsLedger[axis] + delta
                end
            end
        end
        -- P1-2: 记录关键选择文本到 ethicsKeyChoices
        if choice then
            playerData_.ethicsKeyChoices = playerData_.ethicsKeyChoices or {}
            table.insert(playerData_.ethicsKeyChoices, {
                day = playerData_.day or 1,
                choiceId = (evt.id or "cafe") .. "_c" .. choiceIdx,
                text = choice.text or "",
            })
        end
    else
        return
    end

    ce.resolved = true
    ce.result = result

    -- ── 每天首次处理网吧事件消耗1行动点（最多1次/天） ──
    if cafeActionUsedDay_ ~= day and (playerData_.actionPoints or 0) > 0 then
        playerData_.actionPoints = playerData_.actionPoints - 1
        cafeActionUsedDay_ = day
        result = result .. " | ⚡-1行动"
    end

    AddLog("🏪 " .. (evt.title or "网吧事件") .. " → " .. result)
    PlaySFX("event")

    pendingCafeCount_ = 0
    for _, c in ipairs(cafeEvents_) do
        if not c.resolved then pendingCafeCount_ = pendingCafeCount_ + 1 end
    end

    BuildUI()
end

--- 自动解决（已废弃，所有事件均为 choice 类型）
function AutoResolveCafeEvents()
    -- no-op: 所有事件现在都需要玩家决策
end
