---@diagnostic disable: undefined-global
-- ============================================================================
-- ChapterSystem.lua — 章节里程碑系统
-- 5个章节划分游戏进程，每个章节解锁新内容池和里程碑奖励
-- 与抽卡系统联动：章节推进解锁新卡池类别
-- ============================================================================

local ChapterSystem = {}

-- ============================================================================
-- 1. 章节定义
-- ============================================================================

ChapterSystem.CHAPTERS = {
    -- ═══════════ 第一章：铁皮创业 ═══════════
    {
        id = "ch1_startup",
        chapter = 1,
        title = "第一章：铁皮创业",
        subtitle = "从三台电脑开始的梦想",
        emoji = "🏚️",
        -- 解锁条件（进入本章的条件，第1章默认解锁）
        unlockCond = function() return true end,
        -- 完成条件（推进到下一章）
        completeCond = function()
            return playerData_.day >= 8
                and (playerData_.reputation or 0) >= 30
                and #teamMembers_ >= 2
        end,
        -- 完成奖励
        reward = {
            money = 300,
            havocCoins = 100,
            message = "网吧站稳脚跟，第一批队员到位！",
        },
        -- 本章解锁的系统/卡池
        unlocks = { "basic_market" },  -- 基础市场（设备+装饰）
        -- 里程碑（章节内小目标）
        milestones = {
            { id = "ms_first_customer", title = "第一桶金", desc = "累计收入达到$500",
              icon = "💰", check = function() return (playerData_.totalEarnings or 0) >= 500 end,
              reward = { money = 50, havocCoins = 20 } },
            { id = "ms_first_team", title = "队伍成型", desc = "招募第1个队员",
              icon = "👥", check = function() return #teamMembers_ >= 1 end,
              reward = { money = 80 } },
            { id = "ms_first_upgrade", title = "设备升级", desc = "完成任意一项升级",
              icon = "🔧", check = function()
                  return (playerData_.computers or 3) > 3
                      or (playerData_.chairLevel or 1) > 1
                      or (playerData_.netSpeed or 1) > 1
              end,
              reward = { havocCoins = 30 } },
        },
    },

    -- ═══════════ 第二章：街头崛起 ═══════════
    {
        id = "ch2_rising",
        chapter = 2,
        title = "第二章：街头崛起",
        subtitle = "从无名小店到街区传说",
        emoji = "🌟",
        unlockCond = function()
            return (playerData_.chapterCompleted or {})[1]
        end,
        completeCond = function()
            return playerData_.day >= 18
                and (playerData_.reputation or 0) >= 100
                and (playerData_.tournamentWins or 0) >= 1
                and #teamMembers_ >= 3
        end,
        reward = {
            money = 600,
            havocCoins = 200,
            message = "Dragon Force首胜！名声传遍全城！",
        },
        unlocks = { "staff_cards", "decoration_slots" },  -- 解锁员工卡 + 装饰槽位
        milestones = {
            { id = "ms_rep50", title = "小有名气", desc = "声望达到50",
              icon = "⭐", check = function() return (playerData_.reputation or 0) >= 50 end,
              reward = { money = 100, havocCoins = 50 } },
            { id = "ms_first_win", title = "首胜", desc = "赢得第一场锦标赛",
              icon = "🏆", check = function() return (playerData_.tournamentWins or 0) >= 1 end,
              reward = { money = 200, havocCoins = 80 } },
            { id = "ms_branch1", title = "第一家分店", desc = "开设第1家分店",
              icon = "🏪", check = function() return #(playerData_.branches or {}) >= 1 end,
              reward = { money = 150, havocCoins = 60 } },
            { id = "ms_5computers", title = "五机齐发", desc = "拥有5台电脑",
              icon = "🖥️", check = function() return (playerData_.computers or 3) >= 5 end,
              reward = { havocCoins = 80 } },
        },
    },

    -- ═══════════ 第三章：赛博部落 ═══════════
    {
        id = "ch3_cyber_tribe",
        chapter = 3,
        title = "第三章：赛博部落",
        subtitle = "网吧成了社区的心脏",
        emoji = "🎨",
        unlockCond = function()
            return (playerData_.chapterCompleted or {})[2]
        end,
        completeCond = function()
            return playerData_.day >= 30
                and (playerData_.reputation or 0) >= 200
                and (playerData_.totalEarnings or 0) >= 8000
                and #(playerData_.branches or {}) >= 2
        end,
        reward = {
            money = 1000,
            havocCoins = 350,
            message = "网吧成为社区枢纽，文化地标！",
        },
        unlocks = { "city_fragments", "npc_advanced" },  -- 解锁城市碎片 + NPC高阶剧情
        milestones = {
            { id = "ms_rep150", title = "街区名人", desc = "声望达到150",
              icon = "🌟", check = function() return (playerData_.reputation or 0) >= 150 end,
              reward = { money = 200, havocCoins = 100 } },
            { id = "ms_community", title = "社区枢纽", desc = "水井+修路各至少Lv.1",
              icon = "🤝", check = function()
                  return (playerData_.wellLevel or 0) >= 1 and (playerData_.roadLevel or 0) >= 1
              end,
              reward = { money = 300, havocCoins = 80 } },
            { id = "ms_earn5k", title = "五千大关", desc = "累计收入$5000",
              icon = "💵", check = function() return (playerData_.totalEarnings or 0) >= 5000 end,
              reward = { money = 250 } },
            { id = "ms_deco_master", title = "装修达人", desc = "装饰升级到Lv.3",
              icon = "🎨", check = function() return (playerData_.decoLevel or 0) >= 3 end,
              reward = { havocCoins = 120 } },
        },
    },

    -- ═══════════ 第四章：非洲电竞之光 ═══════════
    {
        id = "ch4_esports_light",
        chapter = 4,
        title = "第四章：非洲电竞之光",
        subtitle = "从地方冠军到大陆传奇",
        emoji = "🏆",
        unlockCond = function()
            return (playerData_.chapterCompleted or {})[3]
        end,
        completeCond = function()
            return playerData_.day >= 45
                and (playerData_.reputation or 0) >= 350
                and (playerData_.tournamentWins or 0) >= 5
                and (playerData_.totalEarnings or 0) >= 20000
        end,
        reward = {
            money = 2000,
            havocCoins = 500,
            message = "Dragon Force威震非洲！转生之路开启！",
        },
        unlocks = { "prestige_system", "elite_events" },  -- 解锁转生 + 精英事件
        milestones = {
            { id = "ms_3wins", title = "三冠王", desc = "锦标赛胜利3次",
              icon = "🏆", check = function() return (playerData_.tournamentWins or 0) >= 3 end,
              reward = { money = 500, havocCoins = 150 } },
            { id = "ms_rep300", title = "传奇声望", desc = "声望达到300",
              icon = "👑", check = function() return (playerData_.reputation or 0) >= 300 end,
              reward = { money = 400, havocCoins = 200 } },
            { id = "ms_earn15k", title = "万元户", desc = "累计收入$15000",
              icon = "💎", check = function() return (playerData_.totalEarnings or 0) >= 15000 end,
              reward = { money = 500 } },
            { id = "ms_full_team", title = "满编战队", desc = "队伍满员(5人)",
              icon = "🎖️", check = function() return #teamMembers_ >= 5 end,
              reward = { havocCoins = 200 } },
        },
    },

    -- ═══════════ 第五章：帝国之路 ═══════════
    {
        id = "ch5_empire",
        chapter = 5,
        title = "第五章：帝国之路",
        subtitle = "从网吧到电竞帝国",
        emoji = "👑",
        unlockCond = function()
            return (playerData_.chapterCompleted or {})[4]
        end,
        completeCond = function()
            -- 最终章：无限扩张，通过转生循环
            return (playerData_.prestigeCount or 0) >= 1
                and (playerData_.reputation or 0) >= 500
                and (playerData_.tournamentWins or 0) >= 8
        end,
        reward = {
            money = 5000,
            havocCoins = 1000,
            message = "非洲电竞帝国建成！传奇永不落幕！",
        },
        unlocks = { "legendary_pool", "all_cities" },  -- 解锁传奇卡池 + 全城市
        milestones = {
            { id = "ms_prestige1", title = "第一次转生", desc = "完成首次转生",
              icon = "♻️", check = function() return (playerData_.prestigeCount or 0) >= 1 end,
              reward = { money = 1000, havocCoins = 300 } },
            { id = "ms_5wins", title = "五冠王", desc = "锦标赛胜利5次",
              icon = "🏅", check = function() return (playerData_.tournamentWins or 0) >= 5 end,
              reward = { money = 800, havocCoins = 250 } },
            { id = "ms_rep500", title = "非洲之王", desc = "声望达到500",
              icon = "👑", check = function() return (playerData_.reputation or 0) >= 500 end,
              reward = { money = 1000, havocCoins = 400 } },
            { id = "ms_earn50k", title = "百万富翁", desc = "累计收入$50000",
              icon = "💰", check = function() return (playerData_.totalEarnings or 0) >= 50000 end,
              reward = { havocCoins = 500 } },
        },
    },
}

-- ============================================================================
-- 2. 章节进度检查（每日结算调用）
-- ============================================================================

--- 获取当前章节编号
function ChapterSystem.GetCurrentChapter()
    return playerData_.currentChapter or 1
end

--- 获取当前章节数据
function ChapterSystem.GetCurrentChapterData()
    local ch = ChapterSystem.GetCurrentChapter()
    return ChapterSystem.CHAPTERS[ch]
end

--- 检查章节推进（每日结算调用）
--- @return table|nil result 如果章节推进，返回 { from, to, reward }
function ChapterSystem.CheckChapterProgress()
    local ch = ChapterSystem.GetCurrentChapter()
    local data = ChapterSystem.CHAPTERS[ch]
    if not data then return nil end

    -- 检查完成条件
    if data.completeCond and data.completeCond() then
        -- 标记完成
        if not playerData_.chapterCompleted then
            playerData_.chapterCompleted = {}
        end
        playerData_.chapterCompleted[ch] = true

        -- 发放奖励
        local reward = data.reward
        if reward then
            if reward.money then
                playerData_.money = playerData_.money + reward.money
            end
            if reward.havocCoins then
                playerData_.havocCoins = (playerData_.havocCoins or 0) + reward.havocCoins
            end
        end

        -- 推进到下一章
        local nextCh = ch + 1
        if nextCh <= #ChapterSystem.CHAPTERS then
            playerData_.currentChapter = nextCh
            return {
                from = ch,
                to = nextCh,
                reward = reward,
                fromData = data,
                toData = ChapterSystem.CHAPTERS[nextCh],
            }
        else
            -- 最终章完成
            playerData_.currentChapter = ch  -- 保持最终章
            return {
                from = ch,
                to = ch,
                reward = reward,
                fromData = data,
                toData = nil,
                isFinal = true,
            }
        end
    end
    return nil
end

-- ============================================================================
-- 3. 里程碑检查（每日结算调用）
-- ============================================================================

--- 检查当前章节所有里程碑
--- @return table[] newMilestones 新完成的里程碑列表
function ChapterSystem.CheckMilestones()
    local ch = ChapterSystem.GetCurrentChapter()
    local data = ChapterSystem.CHAPTERS[ch]
    if not data or not data.milestones then return {} end

    if not playerData_.chapterMilestones then
        playerData_.chapterMilestones = {}
    end

    local newlyCompleted = {}

    for _, ms in ipairs(data.milestones) do
        -- 已完成的跳过
        if not playerData_.chapterMilestones[ms.id] then
            if ms.check and ms.check() then
                -- 标记完成
                playerData_.chapterMilestones[ms.id] = true

                -- 发放奖励
                if ms.reward then
                    if ms.reward.money then
                        playerData_.money = playerData_.money + ms.reward.money
                    end
                    if ms.reward.havocCoins then
                        playerData_.havocCoins = (playerData_.havocCoins or 0) + ms.reward.havocCoins
                    end
                end

                table.insert(newlyCompleted, ms)
            end
        end
    end

    return newlyCompleted
end

-- ============================================================================
-- 4. 解锁查询（供其他系统调用）
-- ============================================================================

--- 检查某系统是否已被章节解锁
--- @param unlockKey string 解锁关键字
--- @return boolean
function ChapterSystem.IsUnlocked(unlockKey)
    local ch = ChapterSystem.GetCurrentChapter()
    -- 检查当前及之前所有章节的 unlocks
    for i = 1, ch do
        local data = ChapterSystem.CHAPTERS[i]
        if data and data.unlocks then
            for _, key in ipairs(data.unlocks) do
                if key == unlockKey then return true end
            end
        end
    end
    -- 同时检查已完成章节的解锁
    for i = 1, #ChapterSystem.CHAPTERS do
        if (playerData_.chapterCompleted or {})[i] then
            local data = ChapterSystem.CHAPTERS[i]
            if data and data.unlocks then
                for _, key in ipairs(data.unlocks) do
                    if key == unlockKey then return true end
                end
            end
        end
    end
    return false
end

--- 获取当前章节进度百分比
--- @return number 0~100
function ChapterSystem.GetChapterProgress()
    local ch = ChapterSystem.GetCurrentChapter()
    local data = ChapterSystem.CHAPTERS[ch]
    if not data or not data.milestones then return 0 end

    local total = #data.milestones
    local done = 0
    for _, ms in ipairs(data.milestones) do
        if (playerData_.chapterMilestones or {})[ms.id] then
            done = done + 1
        end
    end
    return total > 0 and math.floor(done / total * 100) or 0
end

--- 获取所有里程碑状态（用于UI展示）
--- @return table[] milestones 每项含 { id, title, desc, icon, completed, reward }
function ChapterSystem.GetMilestonesDisplay()
    local ch = ChapterSystem.GetCurrentChapter()
    local data = ChapterSystem.CHAPTERS[ch]
    if not data or not data.milestones then return {} end

    local result = {}
    for _, ms in ipairs(data.milestones) do
        table.insert(result, {
            id = ms.id,
            title = ms.title,
            desc = ms.desc,
            icon = ms.icon,
            completed = (playerData_.chapterMilestones or {})[ms.id] or false,
            reward = ms.reward,
        })
    end
    return result
end

--- 获取章节总览（所有章节状态）
--- @return table[]
function ChapterSystem.GetChaptersOverview()
    local current = ChapterSystem.GetCurrentChapter()
    local result = {}
    for i, ch in ipairs(ChapterSystem.CHAPTERS) do
        local status = "locked"
        if i < current then
            status = "completed"
        elseif i == current then
            status = "current"
        end
        table.insert(result, {
            chapter = i,
            title = ch.title,
            subtitle = ch.subtitle,
            emoji = ch.emoji,
            status = status,
            unlocks = ch.unlocks,
        })
    end
    return result
end

return ChapterSystem
