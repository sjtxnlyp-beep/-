---@diagnostic disable: undefined-global
-- ============================================================================
-- 小游戏模块 — 2048 / 五子棋 / 记忆翻牌
-- 用于踢馆挑战的 Bo3 比拼
-- ============================================================================

-- ── 小游戏模式名称与图标 ──
MINIGAME_LABELS = {
    game2048    = "2048",
    gomoku      = "五子棋",
    memoryMatch = "记忆翻牌",
}
MINIGAME_EMOJIS = {
    game2048    = "🔢",
    gomoku      = "⚫",
    memoryMatch = "🃏",
}

-- ============================================================================
-- 小游戏通用退出按钮组件（必须在 BuildXxxUI 之前定义）
-- ============================================================================
local function MiniGameExitBtn()
    return UI.Button {
        text = "🚪 退出比赛", width = 140, height = 32, fontSize = 12,
        variant = "ghost", fontColor = { 200, 120, 120, 200 },
        onClick = function() RequestMiniGameExit() end,
    }
end

-- ============================================================================
-- 公共 API
-- ============================================================================

--- 启动小游戏
function StartMiniGame(gameType)
    if gameType == "game2048" then
        Init2048()
    elseif gameType == "gomoku" then
        InitGomoku()
    elseif gameType == "memoryMatch" then
        InitMemoryMatch()
    end
end

--- 获取当前小游戏分数
function GetMiniGameScore()
    if not miniGame_ then return 0 end
    return miniGame_.score or 0
end

--- 当前小游戏是否已结束
function IsMiniGameFinished()
    if not miniGame_ then return true end
    return miniGame_.finished == true
end

-- ============================================================================
-- 2048 小游戏
-- ============================================================================
local GRID2048 = 4

local function SpawnTile2048()
    local g = miniGame_.board
    local empty = {}
    for r = 1, GRID2048 do
        for c = 1, GRID2048 do
            if g[r][c] == 0 then
                table.insert(empty, { r, c })
            end
        end
    end
    if #empty == 0 then return false end
    local pos = empty[math.random(1, #empty)]
    g[pos[1]][pos[2]] = math.random() < 0.9 and 2 or 4
    return true
end

local function CanMove2048()
    local g = miniGame_.board
    for r = 1, GRID2048 do
        for c = 1, GRID2048 do
            if g[r][c] == 0 then return true end
            if c < GRID2048 and g[r][c] == g[r][c + 1] then return true end
            if r < GRID2048 and g[r][c] == g[r + 1][c] then return true end
        end
    end
    return false
end

local function SlideRow(row)
    -- 去掉0，合并相邻相同值
    local filtered = {}
    for i = 1, #row do
        if row[i] ~= 0 then table.insert(filtered, row[i]) end
    end
    local merged = {}
    local score = 0
    local i = 1
    while i <= #filtered do
        if i < #filtered and filtered[i] == filtered[i + 1] then
            local val = filtered[i] * 2
            table.insert(merged, val)
            score = score + val
            i = i + 2
        else
            table.insert(merged, filtered[i])
            i = i + 1
        end
    end
    while #merged < GRID2048 do
        table.insert(merged, 0)
    end
    return merged, score
end

local function Move2048(dir)
    if miniGame_.finished then return end
    local g = miniGame_.board
    local moved = false
    local totalScore = 0

    if dir == "left" then
        for r = 1, GRID2048 do
            local row = { g[r][1], g[r][2], g[r][3], g[r][4] }
            local newRow, s = SlideRow(row)
            totalScore = totalScore + s
            for c = 1, GRID2048 do
                if g[r][c] ~= newRow[c] then moved = true end
                g[r][c] = newRow[c]
            end
        end
    elseif dir == "right" then
        for r = 1, GRID2048 do
            local row = { g[r][4], g[r][3], g[r][2], g[r][1] }
            local newRow, s = SlideRow(row)
            totalScore = totalScore + s
            for c = 1, GRID2048 do
                if g[r][c] ~= newRow[GRID2048 - c + 1] then moved = true end
                g[r][c] = newRow[GRID2048 - c + 1]
            end
        end
    elseif dir == "up" then
        for c = 1, GRID2048 do
            local col = { g[1][c], g[2][c], g[3][c], g[4][c] }
            local newCol, s = SlideRow(col)
            totalScore = totalScore + s
            for r = 1, GRID2048 do
                if g[r][c] ~= newCol[r] then moved = true end
                g[r][c] = newCol[r]
            end
        end
    elseif dir == "down" then
        for c = 1, GRID2048 do
            local col = { g[4][c], g[3][c], g[2][c], g[1][c] }
            local newCol, s = SlideRow(col)
            totalScore = totalScore + s
            for r = 1, GRID2048 do
                if g[r][c] ~= newCol[GRID2048 - r + 1] then moved = true end
                g[r][c] = newCol[GRID2048 - r + 1]
            end
        end
    end

    if moved then
        miniGame_.score = miniGame_.score + totalScore
        miniGame_.moves = miniGame_.moves + 1
        SpawnTile2048()
        if not CanMove2048() then
            miniGame_.finished = true
        end
    end
end

function Init2048()
    miniGame_ = {
        type = "game2048",
        board = {},
        score = 0,
        moves = 0,
        finished = false,
    }
    for r = 1, GRID2048 do
        miniGame_.board[r] = {}
        for c = 1, GRID2048 do
            miniGame_.board[r][c] = 0
        end
    end
    SpawnTile2048()
    SpawnTile2048()
end

-- 2048 颜色映射
local TILE_COLORS = {
    [0]    = { 50, 45, 70, 180 },
    [2]    = { 80, 120, 160, 255 },
    [4]    = { 60, 140, 130, 255 },
    [8]    = { 180, 120, 60, 255 },
    [16]   = { 200, 100, 50, 255 },
    [32]   = { 200, 80, 70, 255 },
    [64]   = { 200, 60, 60, 255 },
    [128]  = { 220, 180, 50, 255 },
    [256]  = { 220, 170, 40, 255 },
    [512]  = { 220, 160, 30, 255 },
    [1024] = { 220, 150, 20, 255 },
    [2048] = { 255, 215, 0, 255 },
}

function Build2048UI()
    local g = miniGame_.board
    local rows = {}
    for r = 1, GRID2048 do
        local cells = {}
        for c = 1, GRID2048 do
            local val = g[r][c]
            local bg = TILE_COLORS[val] or { 120, 80, 160, 255 }
            table.insert(cells, UI.Panel {
                width = 58, height = 58, backgroundColor = bg, borderRadius = 8,
                justifyContent = "center", alignItems = "center",
                children = {
                    val > 0 and UI.Label {
                        text = tostring(val),
                        fontSize = val >= 1024 and 13 or (val >= 100 and 16 or 20),
                        fontColor = { 255, 255, 255, 255 },
                        fontWeight = "bold", textAlign = "center",
                    } or nil,
                },
            })
        end
        table.insert(rows, UI.Panel {
            flexDirection = "row", gap = 4, children = cells,
        })
    end

    -- 方向按钮
    local function DirBtn(label, dir)
        return UI.Button {
            text = label, width = 56, height = 44, fontSize = 20,
            variant = "secondary",
            onClick = function()
                Move2048(dir); BuildUI()
            end,
        }
    end

    local children = {
        UI.Label { text = "🔢 2048", fontSize = 18, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" },
        UI.Label { text = "得分: " .. miniGame_.score .. "  步数: " .. miniGame_.moves, fontSize = 13, fontColor = C.text, textAlign = "center", width = "100%" },
        -- 棋盘
        UI.Panel {
            padding = 6, backgroundColor = { 35, 30, 55, 220 }, borderRadius = 10,
            gap = 4, alignItems = "center",
            children = rows,
        },
    }

    if miniGame_.finished then
        table.insert(children, UI.Label { text = "游戏结束！最终得分: " .. miniGame_.score, fontSize = 15, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" })
        table.insert(children, UI.Button {
            text = "确认结果", width = 180, height = 40, fontSize = 15, variant = "primary",
            onClick = function() FinishChallengeRound() end,
        })
    else
        -- 方向控制
        table.insert(children, UI.Panel {
            alignItems = "center", gap = 2, marginTop = 4,
            children = {
                DirBtn("⬆", "up"),
                UI.Panel { flexDirection = "row", gap = 16, children = {
                    DirBtn("⬅", "left"),
                    DirBtn("⬇", "down"),
                    DirBtn("➡", "right"),
                }},
            },
        })
        -- 结束游戏 + 退出比赛
        table.insert(children, UI.Panel {
            flexDirection = "row", gap = 12, alignItems = "center",
            children = {
                UI.Button {
                    text = "结束游戏", width = 120, height = 34, fontSize = 13,
                    variant = "secondary",
                    onClick = function()
                        miniGame_.finished = true; BuildUI()
                    end,
                },
                MiniGameExitBtn(),
            },
        })
    end

    return UI.Panel {
        width = "100%", height = "100%", padding = 8, gap = 6,
        backgroundColor = { 15, 12, 35, 250 },
        alignItems = "center", justifyContent = "center",
        children = children,
    }
end

-- ============================================================================
-- 五子棋 (Gomoku) — 9×9 简易 AI
-- ============================================================================
local GOMOKU_SIZE = 9

function InitGomoku()
    miniGame_ = {
        type = "gomoku",
        board = {},      -- 0=空, 1=玩家(黑), 2=AI(白)
        size = GOMOKU_SIZE,
        score = 0,       -- 赢=10, 输=0
        finished = false,
        winner = 0,      -- 0=无, 1=玩家, 2=AI
        turn = 1,        -- 1=玩家, 2=AI
        moves = 0,
    }
    for r = 1, GOMOKU_SIZE do
        miniGame_.board[r] = {}
        for c = 1, GOMOKU_SIZE do
            miniGame_.board[r][c] = 0
        end
    end
end

local function CheckWinGomoku(board, player)
    local sz = GOMOKU_SIZE
    local dirs = { {0,1}, {1,0}, {1,1}, {1,-1} }
    for r = 1, sz do
        for c = 1, sz do
            if board[r][c] == player then
                for _, d in ipairs(dirs) do
                    local count = 1
                    for step = 1, 4 do
                        local nr, nc = r + d[1] * step, c + d[2] * step
                        if nr >= 1 and nr <= sz and nc >= 1 and nc <= sz and board[nr][nc] == player then
                            count = count + 1
                        else
                            break
                        end
                    end
                    if count >= 5 then return true end
                end
            end
        end
    end
    return false
end

local function IsBoardFull()
    for r = 1, GOMOKU_SIZE do
        for c = 1, GOMOKU_SIZE do
            if miniGame_.board[r][c] == 0 then return false end
        end
    end
    return true
end

-- 简易 AI：优先堵截/连子，否则在玩家落子附近随机
local function GomokuAIMove()
    local board = miniGame_.board
    local sz = GOMOKU_SIZE
    local dirs = { {0,1}, {1,0}, {1,1}, {1,-1} }

    -- 评分函数：计算某位置对某玩家的威胁值
    local function EvalPos(r, c, player)
        if board[r][c] ~= 0 then return -1 end
        local totalScore = 0
        for _, d in ipairs(dirs) do
            local count = 0
            -- 正方向
            for step = 1, 4 do
                local nr, nc = r + d[1] * step, c + d[2] * step
                if nr >= 1 and nr <= sz and nc >= 1 and nc <= sz and board[nr][nc] == player then
                    count = count + 1
                else break end
            end
            -- 反方向
            for step = 1, 4 do
                local nr, nc = r - d[1] * step, c - d[2] * step
                if nr >= 1 and nr <= sz and nc >= 1 and nc <= sz and board[nr][nc] == player then
                    count = count + 1
                else break end
            end
            if count >= 4 then totalScore = totalScore + 10000 end  -- 即将5连
            if count == 3 then totalScore = totalScore + 500 end
            if count == 2 then totalScore = totalScore + 50 end
            if count == 1 then totalScore = totalScore + 5 end
        end
        return totalScore
    end

    local bestR, bestC, bestScore = 0, 0, -1

    for r = 1, sz do
        for c = 1, sz do
            if board[r][c] == 0 then
                -- AI 进攻分 + 防守分（堵玩家的棋）
                local atkScore = EvalPos(r, c, 2)
                local defScore = EvalPos(r, c, 1)
                local total = atkScore + defScore * 1.1  -- 防守略优先
                -- 加一点随机扰动
                total = total + math.random() * 3
                if total > bestScore then
                    bestScore = total
                    bestR = r
                    bestC = c
                end
            end
        end
    end

    if bestR > 0 then
        board[bestR][bestC] = 2
        miniGame_.moves = miniGame_.moves + 1
    end
end

local function PlaceGomoku(r, c)
    if miniGame_.finished then return end
    if miniGame_.turn ~= 1 then return end
    if miniGame_.board[r][c] ~= 0 then return end

    miniGame_.board[r][c] = 1
    miniGame_.moves = miniGame_.moves + 1

    if CheckWinGomoku(miniGame_.board, 1) then
        miniGame_.finished = true
        miniGame_.winner = 1
        miniGame_.score = 10
        return
    end

    if IsBoardFull() then
        miniGame_.finished = true
        miniGame_.winner = 0
        miniGame_.score = 5  -- 平局给5分
        return
    end

    -- AI 走棋
    miniGame_.turn = 2
    GomokuAIMove()

    if CheckWinGomoku(miniGame_.board, 2) then
        miniGame_.finished = true
        miniGame_.winner = 2
        miniGame_.score = 0
        return
    end

    if IsBoardFull() then
        miniGame_.finished = true
        miniGame_.winner = 0
        miniGame_.score = 5
        return
    end

    miniGame_.turn = 1
end

function BuildGomokuUI()
    local g = miniGame_.board
    local rows = {}
    local cellSize = 30

    for r = 1, GOMOKU_SIZE do
        local cells = {}
        for c = 1, GOMOKU_SIZE do
            local val = g[r][c]
            local bg = { 50, 45, 70, 200 }
            local label = ""
            local labelColor = { 255, 255, 255, 255 }
            if val == 1 then
                label = "●"
                labelColor = { 30, 30, 30, 255 }
                bg = { 220, 220, 220, 255 }
            elseif val == 2 then
                label = "●"
                labelColor = { 255, 255, 255, 255 }
                bg = { 80, 80, 120, 255 }
            end

            local row, col = r, c
            table.insert(cells, UI.Panel {
                width = cellSize, height = cellSize,
                backgroundColor = bg, borderRadius = val ~= 0 and 15 or 4,
                borderWidth = 1, borderColor = { 100, 90, 140, 100 },
                justifyContent = "center", alignItems = "center",
                onClick = function()
                    PlaceGomoku(row, col); BuildUI()
                end,
                children = {
                    label ~= "" and UI.Label {
                        text = label, fontSize = 18, fontColor = labelColor, textAlign = "center",
                    } or nil,
                },
            })
        end
        table.insert(rows, UI.Panel {
            flexDirection = "row", gap = 2, children = cells,
        })
    end

    local statusText = ""
    if miniGame_.finished then
        if miniGame_.winner == 1 then statusText = "🎉 你赢了！"
        elseif miniGame_.winner == 2 then statusText = "😤 AI 赢了"
        else statusText = "🤝 平局" end
    else
        statusText = miniGame_.turn == 1 and "轮到你（黑棋●）" or "AI 思考中..."
    end

    local children = {
        UI.Label { text = "⚫ 五子棋", fontSize = 18, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" },
        UI.Label { text = statusText, fontSize = 14, fontColor = C.text, textAlign = "center", width = "100%" },
        -- 棋盘
        UI.Panel {
            padding = 4, backgroundColor = { 35, 30, 55, 220 }, borderRadius = 8,
            gap = 2, alignItems = "center",
            children = rows,
        },
    }

    if miniGame_.finished then
        table.insert(children, UI.Label {
            text = "得分: " .. miniGame_.score, fontSize = 15, fontColor = C.gold, textAlign = "center", width = "100%",
        })
        table.insert(children, UI.Button {
            text = "确认结果", width = 180, height = 40, fontSize = 15, variant = "primary",
            onClick = function() FinishChallengeRound() end,
        })
    else
        -- 退出比赛按钮
        table.insert(children, MiniGameExitBtn())
    end

    return UI.Panel {
        width = "100%", height = "100%", padding = 8, gap = 6,
        backgroundColor = { 15, 12, 35, 250 },
        alignItems = "center", justifyContent = "center",
        children = children,
    }
end

-- ============================================================================
-- 记忆翻牌 (Memory Match) — 4×4 = 8 对 Emoji
-- ============================================================================
local MEMORY_ROWS = 4
local MEMORY_COLS = 4
local MEMORY_EMOJIS = { "🍎", "🍊", "🍋", "🍇", "🍉", "🍓", "🥝", "🍑" }

function InitMemoryMatch()
    -- 构建8对 emoji 并洗牌
    local cards = {}
    for i = 1, 8 do
        table.insert(cards, MEMORY_EMOJIS[i])
        table.insert(cards, MEMORY_EMOJIS[i])
    end
    -- Fisher-Yates 洗牌
    for i = #cards, 2, -1 do
        local j = math.random(1, i)
        cards[i], cards[j] = cards[j], cards[i]
    end

    local board = {}
    local idx = 1
    for r = 1, MEMORY_ROWS do
        board[r] = {}
        for c = 1, MEMORY_COLS do
            board[r][c] = {
                emoji = cards[idx],
                revealed = false,
                matched = false,
            }
            idx = idx + 1
        end
    end

    miniGame_ = {
        type = "memoryMatch",
        board = board,
        score = 0,        -- 匹配成功的对数
        moves = 0,        -- 翻牌次数
        finished = false,
        first = nil,      -- 第一张翻开的牌 {r, c}
        second = nil,     -- 第二张翻开的牌 {r, c}
        matched = 0,      -- 已匹配对数
        lockInput = false, -- 翻两张不匹配时锁定
    }
end

local function FlipCard(r, c)
    if miniGame_.finished then return end
    if miniGame_.lockInput then return end
    local card = miniGame_.board[r][c]
    if card.revealed or card.matched then return end

    card.revealed = true
    miniGame_.moves = miniGame_.moves + 1

    if not miniGame_.first then
        -- 翻第一张
        miniGame_.first = { r, c }
    elseif not miniGame_.second then
        -- 翻第二张
        miniGame_.second = { r, c }
        local f = miniGame_.first
        local fCard = miniGame_.board[f[1]][f[2]]

        if fCard.emoji == card.emoji then
            -- 匹配成功
            fCard.matched = true
            card.matched = true
            miniGame_.matched = miniGame_.matched + 1
            miniGame_.score = miniGame_.matched
            miniGame_.first = nil
            miniGame_.second = nil

            -- 检查是否全部匹配
            if miniGame_.matched >= 8 then
                miniGame_.finished = true
                -- 分数：基础8分 + 效率奖励（翻牌越少分越高）
                local efficiencyBonus = math.max(0, 24 - miniGame_.moves)
                miniGame_.score = 8 + efficiencyBonus
            end
        else
            -- 不匹配，短暂显示后翻回
            miniGame_.lockInput = true
            -- 使用立即翻回（UI重建时处理）
        end
    end
end

-- 处理不匹配的翻回
local function ResetUnmatched()
    if miniGame_.lockInput and miniGame_.first and miniGame_.second then
        local f = miniGame_.first
        local s = miniGame_.second
        miniGame_.board[f[1]][f[2]].revealed = false
        miniGame_.board[s[1]][s[2]].revealed = false
        miniGame_.first = nil
        miniGame_.second = nil
        miniGame_.lockInput = false
    end
end

function BuildMemoryMatchUI()
    -- 如果处于锁定状态（两张不匹配），先翻回
    if miniGame_.lockInput then
        ResetUnmatched()
    end

    local g = miniGame_.board
    local rows = {}
    local cellSize = 56

    for r = 1, MEMORY_ROWS do
        local cells = {}
        for c = 1, MEMORY_COLS do
            local card = g[r][c]
            local bg, label
            if card.matched then
                bg = { 40, 100, 40, 180 }
                label = card.emoji
            elseif card.revealed then
                bg = { 60, 50, 100, 240 }
                label = card.emoji
            else
                bg = { 70, 60, 110, 220 }
                label = "❓"
            end
            local row, col = r, c
            table.insert(cells, UI.Panel {
                width = cellSize, height = cellSize,
                backgroundColor = bg, borderRadius = 8,
                borderWidth = card.matched and 2 or 1,
                borderColor = card.matched and C.green or { 100, 90, 140, 100 },
                justifyContent = "center", alignItems = "center",
                onClick = function()
                    FlipCard(row, col); BuildUI()
                end,
                children = {
                    UI.Label { text = label, fontSize = 24, textAlign = "center" },
                },
            })
        end
        table.insert(rows, UI.Panel {
            flexDirection = "row", gap = 4, children = cells,
        })
    end

    local children = {
        UI.Label { text = "🃏 记忆翻牌", fontSize = 18, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%" },
        UI.Panel { flexDirection = "row", gap = 12, width = "100%", justifyContent = "center", children = {
            UI.Label { text = "配对: " .. miniGame_.matched .. "/8", fontSize = 13, fontColor = C.text },
            UI.Label { text = "翻牌: " .. miniGame_.moves .. " 次", fontSize = 13, fontColor = C.textDim },
        }},
        -- 棋盘
        UI.Panel {
            padding = 6, backgroundColor = { 35, 30, 55, 220 }, borderRadius = 10,
            gap = 4, alignItems = "center",
            children = rows,
        },
    }

    if miniGame_.finished then
        table.insert(children, UI.Label {
            text = "全部配对成功！得分: " .. miniGame_.score,
            fontSize = 15, fontColor = C.gold, fontWeight = "bold", textAlign = "center", width = "100%",
        })
        table.insert(children, UI.Button {
            text = "确认结果", width = 180, height = 40, fontSize = 15, variant = "primary",
            onClick = function() FinishChallengeRound() end,
        })
    else
        -- 退出比赛按钮
        table.insert(children, MiniGameExitBtn())
    end

    return UI.Panel {
        width = "100%", height = "100%", padding = 8, gap = 6,
        backgroundColor = { 15, 12, 35, 250 },
        alignItems = "center", justifyContent = "center",
        children = children,
    }
end

-- ============================================================================
-- 小游戏退出确认弹窗
-- ============================================================================
--- 请求退出小游戏（弹出确认对话框）
function RequestMiniGameExit()
    miniGameExitPopup_ = true
    BuildUI()
end

--- 确认退出小游戏（判负处理）
function ConfirmMiniGameExit()
    miniGameExitPopup_ = false
    if miniGame_ then
        miniGame_.finished = true
        miniGame_.score = 0  -- 中途退出得分为0
    end
    FinishChallengeRound()
end

--- 取消退出
function CancelMiniGameExit()
    miniGameExitPopup_ = false
    BuildUI()
end

--- 构建退出确认弹窗 UI
function BuildMiniGameExitPopup()
    if not miniGameExitPopup_ then return nil end

    return UI.Panel {
        position = "absolute", width = "100%", height = "100%",
        backgroundColor = { 0, 0, 0, 140 },
        justifyContent = "center", alignItems = "center",
        children = {
            UI.Panel {
                width = "85%", maxWidth = 340, gap = 10,
                backgroundColor = C.card, borderRadius = 16,
                borderWidth = 2, borderColor = C.border,
                alignItems = "center", overflow = "hidden",
                boxShadow = { { x = 0, y = 4, blur = 20, color = { 0, 0, 0, 80 } } },
                children = {
                    PanelHeader("确认退出？", { icon = "⚠️", color = C.red }),
                    -- 内容区（带 padding）
                    UI.Panel {
                        width = "100%", paddingHorizontal = 20, paddingBottom = 16, gap = 14,
                        alignItems = "center",
                        children = {
                            UI.Label {
                                text = "中途退出本轮将视为弃权，得分记为 0 分，对手将赢得本轮比赛。",
                                fontSize = 13, fontColor = C.text, whiteSpace = "normal", lineHeight = 1.5,
                                textAlign = "center", width = "100%",
                            },
                            UI.Panel { flexDirection = "row", gap = 12, width = "100%", justifyContent = "center", children = {
                                UI.Button {
                                    text = "继续比赛", width = 120, height = 38, fontSize = 14,
                                    variant = "primary",
                                    onClick = function() CancelMiniGameExit() end,
                                },
                                UI.Button {
                                    text = "确认退出", width = 120, height = 38, fontSize = 14,
                                    variant = "secondary", fontColor = C.red,
                                    onClick = function() ConfirmMiniGameExit() end,
                                },
                            }},
                        },
                    },
                },
            },
        },
    }
end

-- ============================================================================
-- 小游戏 UI 分发
-- ============================================================================
function BuildMiniGameUI()
    if not miniGame_ then
        return UI.Label { text = "小游戏未初始化", fontSize = 16, fontColor = C.red }
    end
    if miniGame_.type == "game2048" then
        return Build2048UI()
    elseif miniGame_.type == "gomoku" then
        return BuildGomokuUI()
    elseif miniGame_.type == "memoryMatch" then
        return BuildMemoryMatchUI()
    end
    return UI.Label { text = "未知小游戏类型", fontSize = 16, fontColor = C.red }
end
