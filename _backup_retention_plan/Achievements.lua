---@diagnostic disable: undefined-global
-- ============================================================================
-- Achievements.lua — P2 成就系统（首次解锁型）
-- 每个成就只能触发一次，解锁时弹出通知 + 永久记录在 playerData_.achievements
-- ============================================================================

local Achievements = {}

-- ============================================================================
-- 1. 成就定义表
-- ============================================================================
-- 每条成就：{ id, title, desc, icon, reward, check }
-- reward: { money?, rep?, karma? }  -- 可选
-- check:  function() → boolean       -- 满足条件时返回 true
local ACHIEVEMENTS = {
    -- ── 财富里程碑 ──
    { id = "first_gold",      icon = "💰", title = "第一桶金",
      desc  = "累计收入达到 $1,000",
      check = function() return (playerData_.totalEarnings or 0) >= 1000 end,
      reward = { rep = 10 } },
    { id = "rolling_cash",    icon = "💎", title = "财源滚滚",
      desc  = "持有现金超过 $5,000",
      check = function() return playerData_.money >= 5000 end,
      reward = { rep = 20 } },
    { id = "tycoon",          icon = "🏦", title = "非洲首富",
      desc  = "累计收入达到 $50,000",
      check = function() return (playerData_.totalEarnings or 0) >= 50000 end,
      reward = { money = 500, rep = 50 } },
    { id = "gold_investor",   icon = "🥇", title = "黄金投资人",
      desc  = "持有黄金超过 10 盎司",
      check = function() return (playerData_.goldOunces or 0) >= 10 end,
      reward = { rep = 15 } },

    -- ── 网吧发展 ──
    { id = "four_pcs",        icon = "🖥️", title = "小网吧成型",
      desc  = "拥有 4 台电脑",
      check = function() return (playerData_.computers or 1) >= 4 end,
      reward = { rep = 5 } },
    { id = "ten_pcs",         icon = "🏪", title = "网吧老板",
      desc  = "拥有 10 台电脑",
      check = function() return (playerData_.computers or 1) >= 10 end,
      reward = { money = 200, rep = 30 } },
    { id = "first_branch",    icon = "🏬", title = "连锁开始了",
      desc  = "开设第一家分店",
      check = function() return #(playerData_.branches or {}) >= 1 end,
      reward = { rep = 40 } },
    { id = "air_condition",   icon = "❄️", title = "五星网吧",
      desc  = "安装空调",
      check = function() return (playerData_.acLevel or 0) >= 1 end,
      reward = { rep = 10 } },

    -- ── 声望与影响力 ──
    { id = "known_face",      icon = "⭐", title = "开始出圈",
      desc  = "声望达到 50",
      check = function() return (playerData_.reputation or 0) >= 50 end,
      reward = { rep = 0 } },
    { id = "local_legend",    icon = "🌟", title = "本地传说",
      desc  = "声望达到 200",
      check = function() return (playerData_.reputation or 0) >= 200 end,
      reward = { money = 300, rep = 0 } },
    { id = "continental",     icon = "🌍", title = "非洲知名",
      desc  = "声望达到 500",
      check = function() return (playerData_.reputation or 0) >= 500 end,
      reward = { money = 1000, rep = 0 } },

    -- ── 战队与比赛 ──
    { id = "first_recruit",   icon = "🤝", title = "队长诞生",
      desc  = "招募第一个队员",
      check = function() return #teamMembers_ >= 1 end,
      reward = { rep = 5 } },
    { id = "full_squad",      icon = "👥", title = "满编战队",
      desc  = "组建满编 5 人战队",
      check = function() return #teamMembers_ >= 5 end,
      reward = { money = 200, rep = 20 } },
    { id = "first_win",       icon = "🏆", title = "初战告捷",
      desc  = "赢得第一场比赛",
      check = function() return (playerData_.friendlyWins or 0) >= 1 end,
      reward = { rep = 15 } },
    { id = "ten_wins",        icon = "🥇", title = "赛场常胜",
      desc  = "累计赢得 10 场比赛",
      check = function() return (playerData_.friendlyWins or 0) >= 10 end,
      reward = { money = 300, rep = 30 } },
    { id = "champ",           icon = "👑", title = "电竞起源地",
      desc  = "赢得锦标赛冠军",
      check = function() return (playerData_.tournamentWins or 0) >= 1 end,
      reward = { money = 500, rep = 50 } },

    -- ── 经营坚持 ──
    { id = "week_one",        icon = "📅", title = "第一周",
      desc  = "经营满 7 天",
      check = function() return (playerData_.day or 1) >= 7 end,
      reward = { rep = 5 } },
    { id = "month_one",       icon = "🗓️", title = "一个月老板",
      desc  = "经营满 30 天",
      check = function() return (playerData_.day or 1) >= 30 end,
      reward = { money = 200, rep = 20 } },
    { id = "quest_streak5",   icon = "🔥", title = "连续作战",
      desc  = "委托连击达到 5 天",
      check = function() return (playerData_.questStreak or 0) >= 5 end,
      reward = { money = 150, rep = 15 } },

    -- ── 道义与选择 ──
    { id = "good_boss",       icon = "😇", title = "好老板",
      desc  = "道义值达到 10",
      check = function() return (playerData_.karma or 0) >= 10 end,
      reward = { rep = 20 } },
    { id = "survivor",        icon = "💪", title = "绝处逢生",
      desc  = "现金曾低于 $100 但未破产",
      check = function() return (playerData_.nearBankruptCount or 0) >= 1 end,
      reward = { rep = 25 } },
}

-- 对外暴露成就列表（供 UI 展示用）
Achievements.ALL = ACHIEVEMENTS

-- ============================================================================
-- 2. 检查并解锁新成就
-- 每次调用返回本次新解锁的成就列表 (用于弹出通知)
-- ============================================================================
function Achievements.CheckAndUnlock()
    if not playerData_ then return {} end
    playerData_.achievements = playerData_.achievements or {}

    local newlyUnlocked = {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        if not playerData_.achievements[ach.id] then
            local ok, result = pcall(ach.check)
            if ok and result then
                -- 解锁成就
                playerData_.achievements[ach.id] = true
                -- 发放奖励
                if ach.reward then
                    if ach.reward.money then
                        playerData_.money = playerData_.money + ach.reward.money
                    end
                    if ach.reward.rep then
                        playerData_.reputation = (playerData_.reputation or 0) + ach.reward.rep
                    end
                    if ach.reward.karma then
                        playerData_.karma = (playerData_.karma or 0) + ach.reward.karma
                    end
                end
                table.insert(newlyUnlocked, ach)
            end
        end
    end
    return newlyUnlocked
end

-- ============================================================================
-- 3. 获取成就统计（供成就展示页使用）
-- ============================================================================
function Achievements.GetStats()
    local unlocked = 0
    local achieved = playerData_ and playerData_.achievements or {}
    for _, ach in ipairs(ACHIEVEMENTS) do
        if achieved[ach.id] then unlocked = unlocked + 1 end
    end
    return { unlocked = unlocked, total = #ACHIEVEMENTS }
end

--- 检查某成就是否已解锁
function Achievements.IsUnlocked(id)
    return playerData_ and playerData_.achievements and playerData_.achievements[id] == true
end

return Achievements
