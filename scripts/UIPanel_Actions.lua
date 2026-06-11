---@diagnostic disable: undefined-global
local ProgressiveUnlock = require("ProgressiveUnlock")
local ClimaxDay = require("ClimaxDay")
local CrisisChain = require("CrisisChain")
local ReputationSystem = require("ReputationSystem")

-- ═══ 智能折叠状态（非高频栏目默认折叠，减少滚动） ═══
sectionFolded_ = sectionFolded_ or {}

-- ═══ 行动选择弹窗系统（点击按钮后弹出选项面板） ═══
---@type {title: string, options: table[]}|nil
actionChoiceData_ = actionChoiceData_ or nil

--- 显示行动选择弹窗
---@param title string 弹窗标题
---@param options table[] 选项列表，每项 {text, onClick, isAd?}
function ShowActionChoice(title, options)
    actionChoiceData_ = { title = title, options = options }
    PlaySFX("click")
    BuildUI()
end

--- 构建行动选择弹窗 UI（overlay 层渲染）
function BuildActionChoicePopup()
    if not actionChoiceData_ then return nil end
    local data = actionChoiceData_
    local UI = require("urhox-libs/UI")

    local optBtns = {}
    for _, opt in ipairs(data.options) do
        table.insert(optBtns, UI.Button {
            text = opt.text,
            width = "100%", height = 44, fontSize = 13, fontWeight = "bold",
            borderRadius = 8,
            backgroundColor = opt.isAd and { 40, 80, 60, 255 } or { 50, 40, 28, 255 },
            fontColor = opt.isAd and { 140, 255, 160, 255 } or { 245, 215, 128, 255 },
            borderWidth = 1.5,
            borderColor = opt.isAd and { 80, 200, 120, 200 } or { 190, 148, 50, 240 },
            onClick = function()
                actionChoiceData_ = nil
                if opt.onClick then opt.onClick() end
            end,
        })
    end
    -- 取消按钮
    table.insert(optBtns, UI.Button {
        text = "取消", width = "100%", height = 36, fontSize = 12,
        borderRadius = 8,
        backgroundColor = { 30, 25, 20, 200 },
        fontColor = { 150, 140, 120, 200 },
        borderWidth = 1, borderColor = { 80, 70, 55, 150 },
        onClick = function()
            actionChoiceData_ = nil
            PlaySFX("click")
            BuildUI()
        end,
    })

    return UI.Panel {
        position = "absolute", top = 0, left = 0, right = 0, bottom = 0,
        backgroundColor = { 0, 0, 0, 160 },
        justifyContent = "center", alignItems = "center",
        onClick = function()
            actionChoiceData_ = nil
            PlaySFX("click")
            BuildUI()
        end,
        children = {
            UI.Panel {
                width = "75%", maxWidth = 300,
                backgroundColor = { 28, 22, 16, 250 },
                borderRadius = 12, borderWidth = 1.5,
                borderColor = { 160, 130, 60, 180 },
                paddingHorizontal = 16, paddingVertical = 14, gap = 10,
                alignItems = "center",
                children = {
                    UI.Label {
                        text = data.title,
                        fontSize = 14, fontWeight = "bold",
                        fontColor = { 245, 225, 160, 255 },
                    },
                    UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 } },
                    table.unpack(optBtns),
                },
            },
        },
    }
end

-- Tab 分类常量
ACTION_TAB_MANAGE = "manage"   -- 🏠 经营
ACTION_TAB_TEAM   = "team"     -- ⚔️ 团队
ACTION_TAB_MARKET = "market"   -- 🏪 市场

-- 当前选中的Tab（全局状态，BuildUI时保持）
if not currentActionTab_ then currentActionTab_ = ACTION_TAB_MANAGE end

--- 获取可用Tab列表（渐进解锁）
function GetActionTabs()
    local tabs = { { id = ACTION_TAB_MANAGE, icon = "🏠", label = "经营" } }
    if ProgressiveUnlock.IsUnlocked("btn_recruit") or ProgressiveUnlock.IsUnlocked("btn_match") then
        table.insert(tabs, { id = ACTION_TAB_TEAM, icon = "⚔️", label = "团队" })
    end
    if ProgressiveUnlock.IsUnlocked("panel_gold") or ProgressiveUnlock.IsUnlocked("panel_branch") then
        table.insert(tabs, { id = ACTION_TAB_MARKET, icon = "🏪", label = "市场" })
    end
    return tabs
end

--- 检查某个Tab是否有可操作内容（用于红点角标）
function HasTabActivity(tabId)
    local noAP = (playerData_.actionPoints or 0) <= 0
    if tabId == ACTION_TAB_MANAGE then
        if not noAP then return true end
    elseif tabId == ACTION_TAB_TEAM then
        if not noAP and #teamMembers_ >= 1 then return true end
        if ProgressiveUnlock.IsUnlocked("btn_match") and not friendlyMatchToday_ and #teamMembers_ >= 2 then return true end
    elseif tabId == ACTION_TAB_MARKET then
        if ProgressiveUnlock.IsUnlocked("panel_gold") then return true end
    end
    return false
end

function BuildActionCard()
    local ap = playerData_.actionPoints or 3
    local noAP = ap <= 0

    -- ── 辅助：创建行动按钮 ──
    local function ActionBtn(props)
        if props.variant then
            return UI.Button {
                text = props.text,
                width = props.width or "100%",
                height = props.height or 40, fontSize = 14, borderRadius = PX.radius,
                disabled = props.disabled,
                variant = props.variant,
                flex = props.flex,
                onClick = props.onClick,
            }
        end
        return UI.Button {
            text = props.text,
            width = props.width or "100%",
            height = props.height or 40, fontSize = 14, fontWeight = "bold", borderRadius = PX.radius,
            backgroundColor = props.disabled and { 38, 30, 22, 255 } or { 28, 20, 12, 255 },
            fontColor = props.disabled and { 90, 78, 64, 255 } or { 245, 215, 128, 255 },
            borderWidth = PX.border,
            -- 统一金色边框，去掉橙红 accent（与 GridBtn 一致）
            borderColor = props.disabled and { 55, 46, 36, 255 } or (props.borderColor or { 190, 148, 50, 240 }),
            disabled = props.disabled,
            flex = props.flex,
            onClick = props.onClick,
        }
    end

    -- ── 辅助：2x2 网格按钮（紧凑+效果提示） ──
    local function GridBtn(props)
        local disabled = props.disabled
        local bgColor     = disabled and { 38, 30, 22, 255 } or { 26, 18, 10, 255 }
        local innerBorder = disabled and { 65, 55, 42, 200 } or { 205, 162, 60, 240 }
        local titleColor  = disabled and { 90, 78, 64, 255 } or { 245, 215, 128, 255 }
        local subColor    = disabled and { 70, 60, 48, 255 } or { 180, 160, 100, 180 }

        -- 按钮内容：标题 + 效果提示（如有）
        local btnChildren = {
            UI.Label {
                text = props.title, fontSize = 12, fontWeight = "bold",
                fontColor = titleColor,
            },
        }
        -- 显示价格或效果提示（紧凑单行）
        local subText = props.price or props.reward or nil
        if disabled and props.reason then subText = props.reason end
        if subText then
            table.insert(btnChildren, UI.Label {
                text = subText, fontSize = 9, fontColor = subColor,
            })
        end

        return UI.Panel {
            width = "48%", height = 40, borderRadius = 8,
            backgroundColor = bgColor,
            borderWidth = 1.5, borderColor = innerBorder,
            justifyContent = "center", alignItems = "center", gap = 1,
            onClick = not disabled and props.onClick or nil,
            children = btnChildren,
        }
    end

    -- ── 1) 标题行（与卡片背景融合，无独立边框） ──
    local header = UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingBottom = 8,
        borderWidth = { 0, 0, 1, 0 }, borderColor = { C.border[1], C.border[2], C.border[3], 50 },
        children = {
            -- 左侧：标题
            UI.Label { text = "行动", fontSize = 15, fontColor = C.text, fontWeight = "bold" },
            -- 右侧：AP 徽章
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                paddingHorizontal = 10, paddingVertical = 4,
                backgroundColor = noAP and { C.red[1], C.red[2], C.red[3], 30 } or { C.gold[1], C.gold[2], C.gold[3], 25 },
                borderRadius = PX.radius,
                borderWidth = 1,
                borderColor = noAP and { C.red[1], C.red[2], C.red[3], 60 } or { C.gold[1], C.gold[2], C.gold[3], 50 },
                children = {
                    UI.Label { text = "AP", fontSize = 12, fontColor = noAP and C.red or C.gold },
                    UI.Label { text = ap .. "/3", fontSize = 13, fontWeight = "bold",
                        fontColor = noAP and C.red or C.gold },
                },
            },
        },
    }

    -- ── 广告：额外行动点（AP耗尽时显示） ──
    local adExtraAP = nil
    if noAP and AdManager.CanWatch("extra_ap", playerData_.day) then
        adExtraAP = AdManager.AdButton {
            sceneId = "extra_ap", day = playerData_.day,
            text = "看视频多干一件事 +1AP",
            height = 42, fontSize = 13,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                BuildUI()
            end,
        }
    end

    -- ── 方案B: 加班按钮（AP耗尽且今日未加班且没广告可看时显示） ──
    local overtimeBtn = nil
    if noAP and not (playerData_.overtimeUsedToday) and not adExtraAP then
        local otCost = GetCityCost and GetCityCost(30) or 30
        local canAfford = (playerData_.money or 0) >= otCost
        overtimeBtn = UI.Button {
            text = canAfford and ("加班 -$" .. otCost .. " -耐久5  → +1AP") or ("加班需要 $" .. otCost .. "（余额不足）"),
            width = "100%", height = 42, fontSize = 13,
            fontWeight = "bold",
            backgroundColor = canAfford and { 50, 35, 18, 255 } or { 35, 28, 20, 255 },
            fontColor = canAfford and { 230, 170, 60, 255 } or { 90, 78, 60, 200 },
            borderWidth = PX.border,
            borderColor = canAfford and { 180, 130, 40, 200 } or { 70, 60, 45, 150 },
            borderRadius = PX.radius,
            disabled = not canAfford,
            onClick = canAfford and function()
                playerData_.money = playerData_.money - otCost
                playerData_.actionPoints = (playerData_.actionPoints or 0) + 1
                playerData_.overtimeUsedToday = true
                playerData_.endOfDayDurPenalty = (playerData_.endOfDayDurPenalty or 0) + 5
                AddLog("🌙 【加班】你透支精力撑到深夜——$" .. otCost .. "咖啡钱 + 设备多跑一小时，换来1点行动力")
                BuildUI()
            end or nil,
        }
    end

    -- ── 广告：翻倍昨日收入 / 经营补贴 ──
    local adDoubleIncome = nil
    local lastNet = playerData_.lastNetIncome or 0
    if AdManager.CanWatch("double_income", playerData_.day) then
        local bonus = lastNet > 0 and lastNet or math.max(50, math.floor(playerData_.day * 8))
        local label = lastNet > 0
            and ("看广告翻倍昨日收入 +$" .. bonus)
            or  ("看广告领经营补贴 +$" .. bonus)
        adDoubleIncome = AdManager.AdButton {
            sceneId = "double_income", day = playerData_.day,
            text = label,
            height = 42, fontSize = 13,
            onReward = function()
                playerData_.money = playerData_.money + bonus
                playerData_.totalEarnings = (playerData_.totalEarnings or 0) + bonus
                playerData_.lastNetIncome = 0
                AddLog("🎬 赞助商追加了经营奖励！额外获得$" .. bonus .. "！")
                BuildUI()
            end,
        }
    end

    -- ── 1.5) 每日委托任务面板（第10天后显示；Day15+ 展示委托板） ──
    local questPanel = nil
    if dailyQuest_ and ProgressiveUnlock.IsUnlocked("panel_quest") then
        CheckQuestProgress()

        -- 委托卡片构建函数（主委托 + 快速委托共用）
        local function BuildQuestCard(q, slotIdx, titleLabel)
            local done = q.progress >= q.goal
            local progressText = done and "✓" or (q.progress .. "/" .. q.goal)
            -- 紧凑单行：图标 + 描述 + 进度 + (领取按钮)
            local rowChildren = {
                UI.Label { text = "🔧", fontSize = 11 },
                UI.Label { text = q.desc, fontSize = 11, fontColor = C.text, flex = 1, flexShrink = 1 },
                UI.Label { text = progressText, fontSize = 11, fontWeight = "bold",
                    fontColor = done and C.green or C.textDim },
            }
            if done and not q.claimed then
                table.insert(rowChildren, UI.Panel {
                    paddingHorizontal = 8, paddingVertical = 3,
                    backgroundColor = { 65, 55, 40, 255 }, borderRadius = 8,
                    borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                    onClick = function()
                        if slotIdx == 1 then ClaimQuestReward()
                        else pcall(ClaimBoardQuestReward, slotIdx) end
                        BuildUI()
                    end,
                    children = { UI.Label { text = "领取", fontSize = 10, fontColor = C.gold, fontWeight = "bold" } },
                })
            elseif q.claimed then
                table.insert(rowChildren, UI.Label { text = "✅", fontSize = 11 })
            end
            local borderCol = done and not q.claimed
                and { 200, 170, 60, 120 }
                or { C.gold[1], C.gold[2], C.gold[3], 40 }
            return UI.Panel {
                width = "100%", paddingHorizontal = 8, paddingVertical = 5,
                backgroundColor = C.cardAlt, borderRadius = PX.radius,
                borderWidth = 1, borderColor = borderCol,
                flexDirection = "row", alignItems = "center", gap = 6,
                children = rowChildren,
            }
        end

        -- Day 15+ 委托板：3个槽位
        if playerData_.day >= 15 and dailyQuestBoard_ and #dailyQuestBoard_ >= 1 then
            local boardCards = {}
            local labels = { "主委托", "快速委托", "快速委托" }
            for i, q in ipairs(dailyQuestBoard_) do
                if q then
                    table.insert(boardCards, BuildQuestCard(q, i, labels[i] or "委托"))
                end
            end
            -- 委托板标题行（含连击徽章）
            local streak = playerData_.questStreak or 0
            local streakBadge = streak >= 1 and UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 3,
                backgroundColor = { 160, 100, 10, 200 }, borderRadius = 8,
                paddingHorizontal = 6, paddingVertical = 2,
                children = {
                    UI.Label { text = "🔥", fontSize = 10 },
                    UI.Label { text = "连击x" .. streak, fontSize = 10,
                        fontColor = { 255, 215, 80, 255 }, fontWeight = "bold" },
                },
            } or nil
            questPanel = UI.Panel {
                width = "100%", paddingHorizontal = 12, paddingVertical = 10,
                backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 50 },
                gap = 8,
                children = {
                    -- 标题行
                    UI.Panel {
                        flexDirection = "row", justifyContent = "space-between",
                        alignItems = "center", width = "100%",
                        children = {
                            UI.Label { text = "📋 今日委托板", fontSize = 14, fontColor = C.gold,
                                fontWeight = "bold" },
                            streakBadge or UI.Panel { width = 0, height = 0 },
                        },
                    },
                    -- 委托卡片
                    table.unpack(boardCards),
                },
            }
        else
            -- Day 5-14：单委托（原有逻辑）
            questPanel = BuildQuestCard(dailyQuest_, 1, "每日委托")
        end
    end

    -- ── 2) 结束今天（主操作按钮，像素凸起感） ──
    -- 凸起底色（暗色露出底边）
    local endBotColor = noAP and { 20, 90, 38, 255 } or { 90, 58, 10, 255 }
    local endBgColor  = noAP and { 45, 158, 72, 255 } or { 170, 115, 28, 255 }
    local endBorderHi = noAP and { 100, 220, 130, 200 } or { 230, 185, 75, 200 }
    -- 单行文字：正常时 "结束今天 (第N天)"，AP耗尽时两行保留提示
    local endMainText = noAP and "✅ 结束今天" or ("结束今天  (第" .. playerData_.day .. "天)")
    local endDayBtn = UI.Panel {
        width = "100%", height = 44, borderRadius = PX.cardRadius,
        backgroundColor = endBotColor,
        justifyContent = "center", alignItems = "center",
        onClick = function()
            if transition_.active then return end
            PlaySFX("click")
            local ok, err = pcall(EndDay)
            if not ok then
                log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
        end,
        children = {
            UI.Panel {
                width = "100%", height = 41, borderRadius = PX.cardRadius,
                backgroundColor = endBgColor,
                borderWidth = 2, borderColor = endBorderHi,
                flexDirection = "row", justifyContent = "center", alignItems = "center",
                paddingHorizontal = 12, gap = 8,
                children = {
                    UI.Label { text = noAP and "✅ 结束今天" or endMainText,
                        fontSize = 15, fontWeight = "bold",
                        fontColor = { 245, 255, 245, 255 } },
                    noAP and UI.Label { text = "行动点已用完·进入明天",
                        fontSize = 10, fontColor = { 205, 248, 215, 180 } } or nil,
                },
            },
        },
    }

    -- ── 3) 高频操作：2x2 网格（48%宽·74px·橙色边框·价格+收益预期） ──
    local gridRow1 = {}
    if ProgressiveUnlock.IsUnlocked("btn_market_visit") then
        local mktCost = GetCityCost and GetCityCost(50) or 50
        table.insert(gridRow1, GridBtn {
            title = "逛集市", price = "$" .. mktCost,
            reward = "🎲 随机奇遇",
            disabled = noAP or playerData_.money < mktCost,
            reason = playerData_.money < mktCost and "余额不足" or nil,
            onClick = function() DoVisitMarket() end,
        })
    end
    if ProgressiveUnlock.IsUnlocked("btn_flyers") then
        local flyCost = GetCityCost and GetCityCost(30) or 30
        table.insert(gridRow1, GridBtn {
            title = "贴传单", price = "$" .. flyCost,
            reward = "↑ 声望 / 曝光",
            disabled = noAP or playerData_.money < flyCost,
            reason = playerData_.money < flyCost and "余额不足" or nil,
            onClick = function() DoPostFlyers() end,
        })
    end

    local gridRow2 = {}
    if #CANDIDATE_POOL > 0 and ProgressiveUnlock.IsUnlocked("btn_recruit") then
        local isFull = #teamMembers_ >= 5
        local rctCost = GetCityCost and GetCityCost(200) or 200
        -- 角色组合被动：招募费用折扣（与 ScoutRecruit 保持一致）
        if ComboEvents then
            local dOk, disc = pcall(ComboEvents.GetRecruitDiscount)
            if dOk and disc and disc > 0 then
                rctCost = math.max(50, math.floor(rctCost * (1 - disc)))
            end
        end
        table.insert(gridRow2, GridBtn {
            title = isFull and "替换队员" or "招募队员", price = "$" .. rctCost,
            reward = isFull and "↑ 战力" or "↑ 队伍人数",
            disabled = noAP or playerData_.money < rctCost,
            reason = playerData_.money < rctCost and "余额不足" or nil,
            onClick = function() ScoutRecruit() end,
        })
    end
    local matchDisableReason = nil
    if #teamMembers_ < 2 then matchDisableReason = "需2名队员"
    elseif friendlyMatchToday_ then matchDisableReason = "今日已赛" end
    if ProgressiveUnlock.IsUnlocked("btn_match") then
    table.insert(gridRow2, GridBtn {
        title = "比赛",
        reward = "↑ 奖金 / 声望",
        disabled = noAP or #teamMembers_ < 2 or friendlyMatchToday_,
        reason = matchDisableReason,
        onClick = function()
            matchTierSelect_ = not matchTierSelect_
            PlaySFX("click")
            BuildUI()
        end,
    })
    end -- btn_match unlock gate
    -- (gridRow2 placeholder removed - using flat grid layout)

    -- ── 收集所有网格按钮到 flat 列表，自动2个一行紧凑排列 ──
    local gridRow3 = {}  -- keep variable name for compatibility with later checks
    do
        GenerateDailyCafeEvents()
        local pendingCafe = pendingCafeCount_ or 0
        local totalCafe = cafeEvents_ and #cafeEvents_ or 0
        local cafeTitle = "网吧实况"
        local cafeReward = totalCafe > 0 and (pendingCafe > 0 and pendingCafe .. "件待处理" or totalCafe .. "件事件") or "查看经营"
        table.insert(gridRow3, GridBtn {
            title = cafeTitle,
            reward = cafeReward,
            disabled = false,
            onClick = function()
                cafePopupOpen_ = true
                AutoResolveCafeEvents()
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    -- 福利按钮已移至事件提示条（UIManage.lua），不再占操作网格

    -- 合并所有按钮为 flat 列表，自动每2个一行
    local allGridBtns = {}
    for _, btn in ipairs(gridRow1) do table.insert(allGridBtns, btn) end
    for _, btn in ipairs(gridRow2) do table.insert(allGridBtns, btn) end
    for _, btn in ipairs(gridRow3) do table.insert(allGridBtns, btn) end

    local gridRows = {}
    for i = 1, #allGridBtns, 2 do
        local cells = { allGridBtns[i] }
        if allGridBtns[i + 1] then
            table.insert(cells, allGridBtns[i + 1])
        else
            table.insert(cells, UI.Panel { width = "48%" })  -- 占位保持对齐
        end
        table.insert(gridRows, UI.Panel {
            width = "100%", flexDirection = "row", gap = 8, justifyContent = "space-between",
            children = cells,
        })
    end

    local gridPanel = UI.Panel {
        width = "100%", gap = 8,
        children = gridRows,
    }

    -- ── 3.5) 比赛等级选择面板 ──
    local tierPanel = nil
    if matchTierSelect_ and not friendlyMatchToday_ and not noAP and #teamMembers_ >= 2 then
        local tierBtns = {}
        local tw = playerData_.tierWins or { 0, 0, 0 }
        for i, tier in ipairs(MATCH_TIERS) do
            local unlocked = tier.unlock()
            local cityCost = GetCityCost(tier.cost)
            local canAfford = playerData_.money >= cityCost
            local winsText = tw[i] and tw[i] > 0 and (" (" .. tw[i] .. "胜)") or ""
            if unlocked then
                table.insert(tierBtns, ActionBtn {
                    text = tier.name .. " $" .. cityCost .. winsText,
                    borderColor = { C.accent[1], C.accent[2], C.accent[3], 160 },
                    disabled = not canAfford,
                    onClick = function()
                        matchTierSelect_ = false
                        pendingMatchTier_ = i
                        matchGameSelect_ = true
                        PlaySFX("click")
                        BuildUI()
                    end,
                })
            else
                table.insert(tierBtns, ActionBtn {
                    text = "" .. tier.unlockDesc,
                    disabled = true,
                })
            end
        end
        -- 多级锦标赛入口（第三章完成后解锁）
        if chaptersRead_[3] then
            local tWinsMap = playerData_.tournamentTierWins or {}
            table.insert(tierBtns, UI.Panel { height = 2, width = "90%", backgroundColor = { 220, 165, 30, 100 } })
            table.insert(tierBtns, UI.Label { text = "── 锦标赛 ──", fontSize = 12, fontColor = C.gold, textAlign = "center" })
            for ti, tt in ipairs(TOURNAMENT_TIERS) do
                local prevOk = (tt.prevWinReq == nil) or ((tWinsMap[tt.prevWinReq] or 0) >= 1)
                local repOk = playerData_.reputation >= tt.repReq
                local teamOk = #teamMembers_ >= tt.teamReq
                local powerOk = GetTeamPower() >= tt.powerReq
                local ttCityCost = GetCityCost(tt.cost)
                local canAffordT = playerData_.money >= ttCityCost
                local unlocked = prevOk and repOk and teamOk and powerOk
                local myWins = tWinsMap[tt.id] or 0
                local record = myWins > 0 and (" ×" .. myWins) or ""
                if unlocked then
                    local borderColors = {
                        { 100, 180, 255, 80 }, { C.accent[1], C.accent[2], C.accent[3], 100 },
                        { 255, 210, 70, 120 }, { 255, 80, 80, 150 },
                    }
                    table.insert(tierBtns, ActionBtn {
                        text = tt.name .. " $" .. ttCityCost .. record,
                        borderColor = { C.accent[1], C.accent[2], C.accent[3], 120 },
                        disabled = not canAffordT,
                        onClick = function()
                            matchTierSelect_ = false
                            PlaySFX("click")
                            playerData_.money = playerData_.money - ttCityCost
                            isFriendlyMatch_ = false
                            currentTournamentTier_ = ti
                            matchGameType_ = nil
                            -- 深拷贝对手列表
                            matchOpponents_ = {}
                            for _, opp in ipairs(tt.opponents) do
                                table.insert(matchOpponents_, { name = opp.name, power = opp.power, style = opp.style, emoji = opp.emoji, boss = opp.boss })
                            end
                            matchRound_ = 0; matchWins_ = 0; matchLog_ = {}; matchPhase_ = "intro"
                            PlayBGM("match")
                            StartTransition(tt.transition.title, tt.transition.sub, function()
                                currentPhase_ = PHASE_MATCH; BuildUI()
                            end)
                        end,
                    })
                else
                    -- 显示锁定原因
                    local reasons = {}
                    if not prevOk then table.insert(reasons, "需先夺冠上一级") end
                    if not repOk then table.insert(reasons, "声望≥" .. tt.repReq) end
                    if not teamOk then table.insert(reasons, tt.teamReq .. "名队员") end
                    if not powerOk then table.insert(reasons, "战力≥" .. tt.powerReq) end
                    table.insert(tierBtns, ActionBtn {
                        text = "" .. tt.name .. " (" .. table.concat(reasons, ", ") .. ")",
                        disabled = true,
                    })
                end
            end
        end
        table.insert(tierBtns, ActionBtn {
            text = "← 返回", variant = "secondary",
            onClick = function() matchTierSelect_ = false; PlaySFX("click"); BuildUI() end,
        })
        tierPanel = UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { 240, 180, 50, 40 },
            children = {
                UI.Label { text = "选择比赛等级", fontSize = 13, fontColor = C.gold },
                table.unpack(tierBtns),
            },
        }
    end

    -- ── 3.6) 游戏选择面板 ──
    local gameSelectPanel = nil
    if matchGameSelect_ and pendingMatchTier_ then
        local gameBtns = {}
        for _, gt in ipairs(MATCH_GAME_TYPES) do
            local modInfo = ""
            if gt.powerMod ~= 1.0 then
                modInfo = modInfo .. (gt.powerMod > 1.0 and " 战力↑" or " 战力↓")
            end
            if gt.rewardMod ~= 1.0 then
                modInfo = modInfo .. (gt.rewardMod > 1.0 and " 奖励↑" or " 奖励↓")
            end
            table.insert(gameBtns, ActionBtn {
                text = gt.name .. modInfo,
                onClick = function()
                    matchGameType_ = gt
                    matchGameSelect_ = false
                    PlaySFX("click")
                    DoHostTournament(pendingMatchTier_)
                end,
            })
        end
        table.insert(gameBtns, UI.Label {
            text = "选择参赛游戏类型，不同游戏有不同战力和奖励修正",
            fontSize = 10, fontColor = C.textDim, textAlign = "center",
        })
        table.insert(gameBtns, ActionBtn {
            text = "← 返回选等级", variant = "secondary",
            onClick = function()
                matchGameSelect_ = false
                pendingMatchTier_ = nil
                matchTierSelect_ = true
                PlaySFX("click")
                BuildUI()
            end,
        })
        gameSelectPanel = UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = {
                UI.Label { text = "选择比赛游戏", fontSize = 13, fontColor = C.accent },
                table.unpack(gameBtns),
            },
        }
    end

    -- ── 3.8) 网吧实况展开面板（Grid按钮点击后展开） ──
    local cafePanel = nil
    if cafeViewOpen_ then
        local ok, result = pcall(BuildCafeInlinePanel)
        cafePanel = ok and result or nil
    end

    -- ── 4) 条件性行动（按类别分组） ──

    -- ── 4a) 设备与维护 ──
    local maintActions = {}
    -- 买燃油（有发电机时显示）
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 then
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        local fuelCost = 8 * (cap - fuel)  -- 按缺量购买，每升$8
        if fuel < cap then
            fuelCost = math.min(fuelCost, math.max(30, fuelCost))  -- 最低$30起购
            local buyAmount = cap - fuel
            table.insert(maintActions, GridBtn {
                title = "⛽ 买燃油",
                price = "+" .. buyAmount .. "L $" .. fuelCost,
                disabled = playerData_.money < fuelCost,
                onClick = function() DoBuyFuel() end,
            })
        else
            table.insert(maintActions, GridBtn {
                title = "⛽ 燃油已满",
                price = fuel .. "/" .. cap .. "L",
                disabled = true, reason = "满载",
                onClick = function() end,
            })
        end
    end
    -- 维修设备（点击后弹窗，含免费广告选项）
    local cond = playerData_.equipCondition or 100
    if cond < 95 then
        local repairCost = 50 + playerData_.computers * 10
        local canFreeRepair = AdManager.CanWatch("free_repair", playerData_.day)
        table.insert(maintActions, GridBtn {
            title = "🔧 维修设备",
            price = string.format("%.0f%% · $%d", cond, repairCost),
            disabled = noAP or (playerData_.money < repairCost and not canFreeRepair),
            onClick = function()
                -- 弹窗让用户选择付费维修 or 看视频免费
                local opts = {}
                if playerData_.money >= repairCost then
                    table.insert(opts, {
                        text = "花费 $" .. repairCost .. " 维修",
                        onClick = function() DoRepairEquipment() end,
                    })
                end
                if canFreeRepair then
                    table.insert(opts, {
                        text = "📺 看视频免费维修",
                        isAd = true,
                        onClick = function()
                            AdManager.ShowAd("free_repair", playerData_.day, function()
                                local before = playerData_.equipCondition or 0
                                playerData_.equipCondition = math.min(100, before + 30)
                                AddLog("🎬 赞助商派技术团队免费维护！" .. before .. "%→" .. playerData_.equipCondition .. "%")
                                BuildUI()
                            end)
                        end,
                    })
                end
                ShowActionChoice("维修设备 (当前 " .. string.format("%.0f%%", cond) .. ")", opts)
            end,
        })
    end

    -- ── 4b) 副业赚钱 ──
    local sideJobActions = {}
    -- 手机维修（随时可做）
    table.insert(sideJobActions, GridBtn {
        title = "📱 修手机",
        price = "赚外快 AP1",
        disabled = noAP,
        onClick = function() DoPhoneRepair() end,
    })
    -- 代练服务（有队员时显示）
    if #teamMembers_ >= 1 then
        table.insert(sideJobActions, GridBtn {
            title = "🎮 代练服务",
            price = "AP1",
            disabled = noAP,
            onClick = function() DoBoostingService() end,
        })
    end
    -- 直播跑刀三角洲
    if #teamMembers_ >= 2 and playerData_.netSpeed >= 2 then
        table.insert(sideJobActions, GridBtn {
            title = "📡 直播跑刀",
            price = "AP1",
            disabled = noAP,
            onClick = function() DoStreamDeltaForce() end,
        })
    end
    -- 网吧包场（3台电脑以上）
    if playerData_.computers >= 4 then
        table.insert(sideJobActions, GridBtn {
            title = "🎉 接包场",
            price = "AP1",
            disabled = noAP,
            onClick = function() DoCafeRental() end,
        })
    end
    -- 二手市场（第7天后解锁）
    if playerData_.day >= 7 then
        table.insert(sideJobActions, GridBtn {
            title = "🛒 二手淘宝",
            price = "AP1 · $50+",
            disabled = noAP or playerData_.money < 50,
            onClick = function() DoSecondHandMarket() end,
        })
    end

    -- ── 4c) 团队与社交 ──
    local socialActions = {}
    if #teamMembers_ > 0 then
        local bbqC = GetCityCost and GetCityCost(60) or 60
        table.insert(socialActions, GridBtn {
            title = "🍖 请吃烤肉",
            price = "$" .. bbqC .. " AP1",
            disabled = noAP or playerData_.money < bbqC,
            onClick = function() DoTeamBBQ() end,
        })
    end
    -- 免费招募（广告→弹窗选择）
    if #CANDIDATE_POOL > 0 and AdManager.CanWatch("recruit_discount", playerData_.day) then
        local recruitLabel = #teamMembers_ >= 5 and "替换队员" or "免费招募"
        table.insert(socialActions, GridBtn {
            title = "📺 " .. recruitLabel,
            price = "看视频省$200",
            disabled = false,
            onClick = function()
                ShowActionChoice(recruitLabel, {{
                    text = "📺 看视频" .. recruitLabel .. "（省$200）",
                    isAd = true,
                    onClick = function()
                        AdManager.ShowAd("recruit_discount", playerData_.day, function()
                            playerData_.actionPoints = playerData_.actionPoints + 1
                            AddLog("🎬 赞助商赞助了招募费用！这次找人不花钱！")
                            ScoutRecruit()
                        end)
                    end,
                }})
            end,
        })
    end
    -- 媒体采访（广告→弹窗选择）
    if AdManager.CanWatch("reputation_ad", playerData_.day) then
        table.insert(socialActions, GridBtn {
            title = "📰 媒体采访",
            price = "看视频 声望+20",
            disabled = false,
            onClick = function()
                ShowActionChoice("媒体采访", {{
                    text = "📺 接受媒体采访（声望+20）",
                    isAd = true,
                    onClick = function()
                        AdManager.ShowAd("reputation_ad", playerData_.day, function()
                            playerData_.reputation = playerData_.reputation + 20
                            AddLog("🎬 赞助商安排了媒体采访！你的网吧故事登上了当地报纸。声望+20")
                            BuildUI()
                        end)
                    end,
                }})
            end,
        })
    end

    -- ── 声望消耗行动（需要声望等级段解锁） ──
    local repActions = ReputationSystem.GetAvailableActions()
    for _, ra in ipairs(repActions) do
        table.insert(socialActions, GridBtn {
            title = ra.icon .. " " .. ra.name,
            price = "声望-" .. ra.cost,
            disabled = not ra.canDo,
            onClick = function()
                ShowActionChoice(ra.name, {{
                    text = ra.icon .. " " .. ra.desc .. "（声望-" .. ra.cost .. "）",
                    onClick = function()
                        local ok, msg = ReputationSystem.DoAction(ra.id)
                        if ok then
                            AddLog(ra.icon .. " " .. msg)
                            BuildUI()
                        else
                            AddLog("❌ " .. msg)
                        end
                    end,
                }})
            end,
        })
    end

    -- ── 4d) 扩张经营 ──
    local expandActions = {}
    -- 借钱
    if playerData_.money < 300 and (playerData_.debt or 0) < 500 then
        local alreadyBorrowed = playerData_.debtDay == playerData_.day
        table.insert(expandActions, ActionBtn {
            text = alreadyBorrowed and "找Mama B借钱 (今日已借)" or "找Mama B借钱 ($300)",
            disabled = alreadyBorrowed,
            onClick = function() DoBorrowMoney() end,
        })
    end
    if (playerData_.debt or 0) > 0 then
        table.insert(expandActions, UI.Label {
            text = "欠款: $" .. playerData_.debt .. " (每日自动还30%余额)",
            fontSize = 14, fontColor = C.red, paddingLeft = 4,
        })
    end

    -- ── 4e) 黄金交易（阿布杜大叔的拉各斯黄金市场）──
    local goldPanel = nil
    -- 黄金交易（第10天后解锁）
    if playerData_.day >= 10 then
        local goldPrice = GetGoldPrice()
        local curGold = playerData_.goldOunces or 0
        local goldVal = curGold > 0 and math.floor(curGold * goldPrice) or 0
        -- 金价趋势指示
        local prevPrice = GetGoldPrice((playerData_.day or 1) - 1)
        local trend = goldPrice > prevPrice and "📈" or (goldPrice < prevPrice and "📉" or "➡️")
        -- 阿布杜大叔播报
        local uncleQuote, uncleSignal = GetUncleAbduQuote()
        local signalColor = uncleSignal == "up" and { 100, 220, 120, 255 }
            or uncleSignal == "down" and { 240, 100, 80, 255 }
            or { 200, 200, 150, 255 }
        goldPanel = UI.Panel {
            width = "100%", padding = 10, gap = 6,
            backgroundColor = { 45, 35, 15, 240 }, borderRadius = PX.cardRadius,
            borderWidth = 1, borderColor = { C.gold[1], C.gold[2], C.gold[3], 150 },
            children = {
                -- 大叔头像+标题
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                    UI.Label { text = "👳🏿‍♂️", fontSize = 20 },
                    UI.Panel { flex = 1, gap = 1, children = {
                        UI.Label { text = "阿布杜大叔的黄金摊", fontSize = 13,
                            fontColor = C.gold, fontWeight = "bold" },
                        UI.Label { text = trend .. " 今日金价: $" .. goldPrice .. "/oz" ..
                            (curGold > 0 and ("  持仓: " .. string.format("%.1f", curGold) .. "oz ≈$" .. goldVal) or ""),
                            fontSize = 11, fontColor = { 220, 200, 130, 220 } },
                    }},
                }},
                -- 大叔语录气泡
                UI.Panel {
                    width = "100%", padding = 8, borderRadius = 8,
                    backgroundColor = { 30, 28, 20, 200 },
                    borderWidth = 1, borderColor = signalColor,
                    children = {
                        UI.Label { text = "\"" .. uncleQuote .. "\"",
                            fontSize = 12, fontColor = signalColor, fontStyle = "italic",
                            whiteSpace = "normal", width = "100%" },
                    },
                },
                -- 快捷买入按钮组
                UI.Panel {
                    width = "100%", flexDirection = "row", gap = 4, flexWrap = "wrap",
                    children = (function()
                        local buyBtns = {}
                        local units = { 0.1, 0.5, 1.0 }
                        for _, u in ipairs(units) do
                            local cost = math.floor(goldPrice * u)
                            table.insert(buyBtns, UI.Button {
                                text = "买" .. u .. "oz\n$" .. cost,
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = playerData_.money >= cost and { 60, 45, 20, 220 } or { 50, 45, 40, 200 },
                                fontColor = playerData_.money >= cost and { 255, 230, 150, 255 } or { 130, 115, 100, 180 },
                                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 60 },
                                disabled = playerData_.money < cost,
                                onClick = function()
                                    if playerData_.money >= cost then
                                        playerData_.money = playerData_.money - cost
                                        local actual = u
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            actual = math.floor((u * 1.2) * 10) / 10
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%黄金！")
                                        end
                                        -- 角色组合被动：金币交易永久利润加成
                                        if ComboEvents then
                                            local cOk, cB = pcall(ComboEvents.GetGoldTradeBonus)
                                            if cOk and cB and cB > 0 then actual = math.floor((actual * (1 + cB)) * 10) / 10 end
                                        end
                                        playerData_.goldOunces = (playerData_.goldOunces or 0) + actual
                                        AddLog("🥇 买入黄金 " .. actual .. "oz @ $" .. goldPrice .. "/oz，花费$" .. cost)
                                        PlaySFX("upgrade"); BuildUI()
                                    end
                                end,
                            })
                        end
                        -- "全部买入"按钮
                        local maxBuy = math.floor(playerData_.money / goldPrice * 10) / 10  -- 精确到0.1
                        if maxBuy >= 0.1 then
                            local maxCost = math.floor(goldPrice * maxBuy)
                            table.insert(buyBtns, UI.Button {
                                text = "全买\n" .. maxBuy .. "oz",
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 },
                                fontColor = { 255, 230, 150, 255 },
                                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                                onClick = function()
                                    if playerData_.money >= maxCost then
                                        playerData_.money = playerData_.money - maxCost
                                        local actual = maxBuy
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            actual = math.floor((maxBuy * 1.2) * 10) / 10
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%黄金！")
                                        end
                                        -- 角色组合被动：金币交易永久利润加成
                                        if ComboEvents then
                                            local cOk, cB = pcall(ComboEvents.GetGoldTradeBonus)
                                            if cOk and cB and cB > 0 then actual = math.floor((actual * (1 + cB)) * 10) / 10 end
                                        end
                                        playerData_.goldOunces = (playerData_.goldOunces or 0) + actual
                                        AddLog("🥇 全仓买入黄金 " .. actual .. "oz @ $" .. goldPrice .. "/oz，花费$" .. maxCost)
                                        PlaySFX("upgrade"); BuildUI()
                                    end
                                end,
                            })
                        end
                        return buyBtns
                    end)(),
                },
                -- 快捷卖出按钮组（有持仓时显示）
                curGold >= 0.1 and UI.Panel {
                    width = "100%", flexDirection = "row", gap = 4, flexWrap = "wrap",
                    children = (function()
                        local sellBtns = {}
                        local units = { 0.1, 0.5, 1.0 }
                        for _, u in ipairs(units) do
                            if curGold >= u then
                                local income = math.floor(goldPrice * u)
                                table.insert(sellBtns, UI.Button {
                                    text = "卖" .. u .. "oz\n+$" .. income,
                                    flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                    backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                    fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                    borderWidth = PX.border, borderColor = { C.green[1], C.green[2], C.green[3], 60 },
                                    onClick = function()
                                        if (playerData_.goldOunces or 0) >= u then
                                            playerData_.goldOunces = playerData_.goldOunces - u
                                            if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                            local actualIncome = income
                                            if (playerData_.goldTradeBonus or 0) > 0 then
                                                actualIncome = math.floor(income * 1.2)
                                                playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                                AddLog("🎫 使用黄金交易优惠券！额外获得20%收入！")
                                            end
                                            -- 角色组合被动：金币交易永久利润加成
                                            if ComboEvents then
                                                local cOk, cB = pcall(ComboEvents.GetGoldTradeBonus)
                                                if cOk and cB and cB > 0 then actualIncome = math.floor(actualIncome * (1 + cB)) end
                                            end
                                            playerData_.money = playerData_.money + actualIncome
                                            AddLog("💵 卖出黄金 " .. u .. "oz @ $" .. goldPrice .. "/oz，收入$" .. actualIncome)
                                            PlaySFX("click"); BuildUI()
                                        end
                                    end,
                                })
                            end
                        end
                        -- "全部卖出"按钮
                        if curGold >= 0.1 then
                            local totalIncome = math.floor(goldPrice * curGold)
                            table.insert(sellBtns, UI.Button {
                                text = "全卖\n+$" .. totalIncome,
                                flex = 1, height = 40, fontSize = 11, borderRadius = PX.radius,
                                backgroundColor = { C.green[1], C.green[2], C.green[3], 30 },
                                fontColor = { C.green[1], C.green[2], C.green[3], 255 },
                                borderWidth = PX.border, borderColor = { C.green[1], C.green[2], C.green[3], 80 },
                                onClick = function()
                                    local sellAll = playerData_.goldOunces or 0
                                    if sellAll >= 0.1 then
                                        local income = math.floor(goldPrice * sellAll)
                                        if (playerData_.goldTradeBonus or 0) > 0 then
                                            income = math.floor(income * 1.2)
                                            playerData_.goldTradeBonus = playerData_.goldTradeBonus - 1
                                            AddLog("🎫 使用黄金交易优惠券！额外获得20%收入！")
                                        end
                                        -- 角色组合被动：金币交易永久利润加成
                                        if ComboEvents then
                                            local cOk, cB = pcall(ComboEvents.GetGoldTradeBonus)
                                            if cOk and cB and cB > 0 then income = math.floor(income * (1 + cB)) end
                                        end
                                        playerData_.goldOunces = 0
                                        playerData_.money = playerData_.money + income
                                        AddLog("💵 清仓卖出黄金 " .. string.format("%.1f", sellAll) .. "oz @ $" .. goldPrice .. "/oz，收入$" .. income)
                                        PlaySFX("click"); BuildUI()
                                    end
                                end,
                            })
                        end
                        return sellBtns
                    end)(),
                } or nil,
                -- 黄金消费玩法（第20天后+有黄金持仓时解锁）
                (playerData_.day >= 20 and curGold >= 0.5) and UI.Panel {
                    width = "100%", gap = 4, paddingTop = 4,
                    children = {
                        UI.Label { text = "── 黄金投资 ──", fontSize = 11, fontColor = { 255, 215, 0, 180 }, textAlign = "center", width = "100%" },
                        -- 黄金装饰：花0.5oz，永久每日声望+3
                        (not playerData_.goldDecor) and UI.Button {
                            text = "黄金奖杯装饰 (0.5oz) → 每日声望+3",
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 0.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 0.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 0.5
                                    playerData_.goldDecor = true
                                    AddLog("🏆 用0.5盎司黄金打造了一座闪闪发光的奖杯！摆在柜台上，每天都能吸引更多客人。（每日声望+3）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        } or UI.Label { text = "黄金奖杯已展示（每日声望+3）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 },
                        -- 黄金键帽：花1oz，永久战队+15战力
                        playerData_.goldKeycaps and UI.Label { text = "黄金键帽已装备（战队+15战力）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金键帽套装 (1oz) → 战队战力+15",
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 1.0,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 1.0 then
                                    playerData_.goldOunces = playerData_.goldOunces - 1.0
                                    playerData_.goldKeycaps = true
                                    AddLog("⌨️ 从拉各斯定制了一套纯金键帽！队员们爱不释手，手感和气场直接拉满。（战队永久+15战力）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金赞助：花2oz，karma+2 声望+50（可重复）
                        UI.Button {
                            text = "赞助社区电竞赛 (2oz) → 声望+50 karma+2",
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 80 },
                            disabled = curGold < 2.0,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 2.0 then
                                    playerData_.goldOunces = playerData_.goldOunces - 2.0
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.reputation = playerData_.reputation + 50
                                    playerData_.karma = playerData_.karma + 2
                                    AddLog("🤝 你用黄金赞助了一场社区电竞赛事！全城的年轻人都来参加了。你的名字被印在了奖杯上。（声望+50，karma+2）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金保险箱：花1.5oz，贬值/政变现金损失减半
                        playerData_.goldSafe and UI.Label { text = "黄金保险箱已启用（损失减半）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金保险箱 (1.5oz) → 贬值/政变损失减半",
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
                            disabled = curGold < 1.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 1.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 1.5
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.goldSafe = true
                                    AddLog("🔐 你在黑市搞到了一个瑞士产黄金保险箱！把最重要的现金锁在里面，再也不怕贬值和政变了。（贬值/政变现金损失减半）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                        -- 黄金VIP卡：花2.5oz，永久每日收入+15%
                        playerData_.goldVIP and UI.Label { text = "黄金VIP已激活（收入+15%）", fontSize = 11, fontColor = C.textDim, paddingLeft = 4 }
                        or UI.Button {
                            text = "黄金VIP卡 (2.5oz) → 每日收入+15%",
                            width = "100%", height = 38, fontSize = 12, borderRadius = PX.radius,
                            backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 30 }, fontColor = { 255, 230, 150, 255 },
                            borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 80 },
                            disabled = curGold < 2.5,
                            onClick = function()
                                if (playerData_.goldOunces or 0) >= 2.5 then
                                    playerData_.goldOunces = playerData_.goldOunces - 2.5
                                    if playerData_.goldOunces < 0.01 then playerData_.goldOunces = 0 end
                                    playerData_.goldVIP = true
                                    AddLog("💳 一张闪闪发光的黄金VIP卡！凭此卡在拉各斯商业圈享受顶级待遇，合作伙伴们纷纷主动上门。（每日收入永久+15%）")
                                    PlaySFX("upgrade"); BuildUI()
                                end
                            end,
                        },
                    },
                } or nil,
                -- 💰 看广告 → 下次黄金买卖获得额外收益
                AdManager.AdButton {
                    sceneId = "gold_trade_bonus", day = playerData_.day,
                    text = "看广告 → 下次黄金交易额外+20%收益",
                    width = "100%", height = 36, fontSize = 12, borderRadius = PX.radius,
                    backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 25 }, fontColor = { 255, 220, 100, 255 },
                    borderWidth = PX.border, borderColor = { C.goldDim[1], C.goldDim[2], C.goldDim[3], 100 },
                    onReward = function()
                        playerData_.goldTradeBonus = (playerData_.goldTradeBonus or 0) + 1
                        playerData_.questGoldTradeCount = (playerData_.questGoldTradeCount or 0) + 1
                        AddLog("📺 赞助商赠送黄金交易优惠券！下次买入/卖出黄金时额外获得20%收益！")
                        PlaySFX("coin")
                        BuildUI()
                    end,
                },
            },
        }
    end
    -- 开分店（资金≥8000 + 分店<3）
    local branchCount = #(playerData_.branches or {})
    local nextBranchCost = BRANCH_COSTS[branchCount + 1] or 9000
    local canBranch = playerData_.money >= 8000 and branchCount < 3
    if canBranch and branchOpenStep_ == 0 then
        table.insert(expandActions, ActionBtn {
            text = "开分店 $" .. nextBranchCost .. " (第" .. (branchCount + 1) .. "家)",
            disabled = playerData_.money < nextBranchCost,
            onClick = function()
                branchOpenLocOpts_ = RollBranchLocationOptions()
                branchOpenStep_ = 1
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    -- 分店开设流程：步骤1-选地点
    if branchOpenStep_ == 1 and branchOpenLocOpts_ then
        local locBtns = {
            PanelHeader("选择分店城市", { icon = "", color = C.gold }),
            UI.Label { text = "在这些城市中选一个开设分店", fontSize = 12, fontColor = C.textDim, textAlign = "center", width = "100%" },
        }
        for _, loc in ipairs(branchOpenLocOpts_) do
            table.insert(locBtns, UI.Button {
                text = loc.name .. "\n" .. loc.desc .. "\n" .. loc.bonusDesc,
                width = "100%", height = 70, fontSize = 13, borderRadius = PX.radius,
                backgroundColor = C.accentLight, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    branchOpenSelLoc_ = loc
                    branchOpenStep_ = 2
                    PlaySFX("click")
                    BuildUI()
                end,
            })
        end
        table.insert(locBtns, UI.Button {
            text = "← 取消", width = "100%", height = 36, fontSize = 13, borderRadius = PX.radius,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 0; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.accentLight, borderRadius = PX.cardRadius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = locBtns,
        })
    end
    -- 分店开设流程：步骤2-选游戏
    if branchOpenStep_ == 2 and branchOpenSelLoc_ then
        local gameBtns = {
            PanelHeader("选择主营游戏", { icon = nil, color = C.gold }),
            UI.Label { text = branchOpenSelLoc_.name .. " 分店 · 选择特色游戏", fontSize = 12, fontColor = C.accent, textAlign = "center", width = "100%" },
        }
        for _, game in ipairs(BRANCH_GAMES) do
            table.insert(gameBtns, UI.Button {
                text = game.name .. " — " .. game.desc .. "\n" .. game.bonusDesc,
                width = "100%", height = 56, fontSize = 13, borderRadius = PX.radius,
                backgroundColor = C.cardAlt, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 80 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    PlaySFX("upgrade")
                    DoOpenBranch(branchOpenSelLoc_, game)
                end,
            })
        end
        table.insert(gameBtns, UI.Button {
            text = "← 重选城市", width = "100%", height = 36, fontSize = 13, borderRadius = PX.radius,
            variant = "secondary",
            onClick = function() branchOpenStep_ = 1; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 10, gap = 8,
            backgroundColor = C.cardAlt, borderRadius = PX.cardRadius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = gameBtns,
        })
    end

    -- （已精简：移除夜间加练和日结奖金广告，只保留翻倍收入和额外AP，减少广告干扰）
    -- 章节推进已改为自动触发（EndDay结算时由ChapterSystem驱动），移除手动横幅

    -- ── 辅助：分区标题 ──
    local function SectionTitle(icon, title)
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            paddingTop = 2, paddingBottom = 1,
            children = {
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
                UI.Label { text = icon .. " " .. title, fontSize = 12, fontColor = C.textDim, flexShrink = 0 },
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
            },
        }
    end

    -- ── 辅助：分区容器 ──
    local function SectionPanel(items)
        if #items == 0 then return nil end
        return UI.Panel {
            width = "100%", gap = 6,
            children = items,
        }
    end

    -- ── 组装卡片（按 Tab 分类，只渲染当前 Tab 的内容） ──
    local cardChildren = {}
    local tab = currentActionTab_ or ACTION_TAB_MANAGE

    -- ── 🔥 高潮日横幅（所有 Tab 顶部显示） ──
    if ClimaxDay.IsClimaxDay() then
        local climaxInfo = ClimaxDay.GetActiveToday()
        local climaxTitle = climaxInfo and climaxInfo.name or "🔥 高潮日"
        local climaxActions = ClimaxDay.GetAvailableActions() or {}
        local climaxBtns = {}
        for _, act in ipairs(climaxActions) do
            table.insert(climaxBtns, UI.Button {
                text = act.name .. (act.apCost and (" -" .. act.apCost .. "AP") or ""),
                height = 34, fontSize = 11, fontWeight = "bold",
                borderRadius = 6, flex = 1,
                backgroundColor = { 80, 20, 10, 255 },
                fontColor = { 255, 200, 100, 255 },
                borderWidth = 1, borderColor = { 255, 120, 40, 200 },
                disabled = (playerData_.actionPoints or 0) < (act.apCost or 1),
                onClick = function()
                    local ok, err = pcall(ClimaxDay.ExecuteAction, act.id)
                    if ok then
                        AddLog("🔥 " .. act.name .. " 执行成功！")
                    else
                        AddLog("❌ " .. tostring(err))
                    end
                    BuildUI()
                end,
            })
        end
        table.insert(cardChildren, UI.Panel {
            width = "100%", paddingHorizontal = 8, paddingVertical = 6,
            backgroundColor = { 60, 15, 5, 240 },
            borderRadius = 8, borderWidth = 1.5, borderColor = { 255, 80, 20, 180 },
            gap = 6,
            children = {
                UI.Label { text = climaxTitle, fontSize = 13, fontWeight = "bold", fontColor = { 255, 180, 60, 255 } },
                UI.Label { text = "限定行动（消耗AP，仅今日可用）", fontSize = 10, fontColor = { 255, 150, 80, 180 } },
                #climaxBtns > 0 and UI.Panel {
                    width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 4,
                    children = climaxBtns,
                } or nil,
            },
        })
    end

    -- ── ⚡ 危机链选择面板（所有 Tab 顶部显示） ──
    if CrisisChain.IsActive() then
        local choiceData = CrisisChain.GetTodayChoice()
        local progressInfo = CrisisChain.GetProgressDesc()
        local progressDesc = ""
        if type(progressInfo) == "table" then
            progressDesc = (progressInfo.icon or "⚡") .. " " .. (progressInfo.name or "危机") .. "（第" .. (progressInfo.dayIndex or 1) .. "/" .. (progressInfo.totalDays or "?") .. "天）"
        elseif type(progressInfo) == "string" then
            progressDesc = progressInfo
        end
        local crisisChildren = {
            UI.Label { text = "⚡ 危机事件", fontSize = 13, fontWeight = "bold", fontColor = { 255, 100, 100, 255 } },
            UI.Label { text = progressDesc, fontSize = 10, fontColor = { 220, 180, 140, 200 } },
        }
        local choices = choiceData and choiceData.dayConfig and choiceData.dayConfig.choices
        if choices then
            for i, opt in ipairs(choices) do
                table.insert(crisisChildren, UI.Button {
                    text = opt.text or ("选项" .. i),
                    width = "100%", height = 36, fontSize = 12, fontWeight = "bold",
                    borderRadius = 6,
                    backgroundColor = { 50, 15, 15, 255 },
                    fontColor = { 255, 200, 140, 255 },
                    borderWidth = 1, borderColor = { 200, 80, 60, 200 },
                    onClick = function()
                        local ok, err = pcall(CrisisChain.MakeChoice, i)
                        if ok then
                            AddLog("⚡ 你做出了选择：" .. (opt.text or ""))
                        else
                            AddLog("❌ " .. tostring(err))
                        end
                        BuildUI()
                    end,
                })
            end
        else
            table.insert(crisisChildren, UI.Label {
                text = "等待事态发展…", fontSize = 10, fontColor = { 180, 150, 120, 150 },
            })
        end
        table.insert(cardChildren, UI.Panel {
            width = "100%", paddingHorizontal = 8, paddingVertical = 6,
            backgroundColor = { 40, 10, 10, 240 },
            borderRadius = 8, borderWidth = 1.5, borderColor = { 200, 60, 60, 180 },
            gap = 5,
            children = crisisChildren,
        })
    end

    if tab == ACTION_TAB_MANAGE then
        -- ═══ 🏠 经营 Tab ═══
        -- 加班区
        if overtimeBtn then table.insert(cardChildren, overtimeBtn) end
        -- 比赛等级选择（若存在）
        if tierPanel or gameSelectPanel then
            if tierPanel then table.insert(cardChildren, tierPanel) end
            if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end
        else
            -- 高频操作（始终可见）
            local primaryBtns = {}
            for _, btn in ipairs(gridRow1) do table.insert(primaryBtns, btn) end
            for _, btn in ipairs(gridRow3) do table.insert(primaryBtns, btn) end
            if #primaryBtns > 0 then
                table.insert(cardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 6,
                    children = primaryBtns,
                })
            end

            -- 可折叠：维护+副业（默认折叠，点击展开）
            local extraBtns = {}
            if #maintActions > 0 and ProgressiveUnlock.IsUnlocked("panel_maintain") then
                for _, btn in ipairs(maintActions) do table.insert(extraBtns, btn) end
            end
            if #sideJobActions > 0 and ProgressiveUnlock.IsUnlocked("panel_sidejob") then
                for _, btn in ipairs(sideJobActions) do table.insert(extraBtns, btn) end
            end
            if #extraBtns > 0 then
                local isFolded = sectionFolded_["manage_extra"] == true  -- 默认展开，用户可收起
                local foldIcon = isFolded and "▶" or "▼"
                local extraCount = #extraBtns
                table.insert(cardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                    paddingVertical = 4, paddingHorizontal = 4,
                    onClick = function()
                        sectionFolded_["manage_extra"] = not isFolded
                        PlaySFX("click")
                        BuildUI()
                    end,
                    children = {
                        UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 25 }, flex = 1 },
                        UI.Label { text = foldIcon .. " 维护·副业 (" .. extraCount .. ")",
                            fontSize = 11, fontColor = { 180, 160, 120, 200 }, flexShrink = 0 },
                        UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 25 }, flex = 1 },
                    },
                })
                if not isFolded then
                    table.insert(cardChildren, UI.Panel {
                        width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 6,
                        children = extraBtns,
                    })
                end
            end
        end
        -- 网吧实况展开面板（点击"网吧实况"按钮后才展开）
        if cafePanel then table.insert(cardChildren, cafePanel) end

    elseif tab == ACTION_TAB_TEAM then
        -- ═══ ⚔️ 团队 Tab ═══
        if tierPanel or gameSelectPanel then
            if tierPanel then table.insert(cardChildren, tierPanel) end
            if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end
        else
            -- 高频操作（招募/比赛 始终可见）
            if #gridRow2 > 0 then
                table.insert(cardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 6,
                    children = gridRow2,
                })
            end

            -- 可折叠：社交操作（默认折叠）
            if #socialActions > 0 and ProgressiveUnlock.IsUnlocked("panel_social") then
                local isFolded = sectionFolded_["team_social"] == true  -- 默认展开，用户可收起
                local foldIcon = isFolded and "▶" or "▼"
                local socialCount = #socialActions
                table.insert(cardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                    paddingVertical = 4, paddingHorizontal = 4,
                    onClick = function()
                        sectionFolded_["team_social"] = not isFolded
                        PlaySFX("click")
                        BuildUI()
                    end,
                    children = {
                        UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 25 }, flex = 1 },
                        UI.Label { text = foldIcon .. " 社交·声望 (" .. socialCount .. ")",
                            fontSize = 11, fontColor = { 180, 160, 120, 200 }, flexShrink = 0 },
                        UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 25 }, flex = 1 },
                    },
                })
                if not isFolded then
                    table.insert(cardChildren, UI.Panel {
                        width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 6,
                        children = socialActions,
                    })
                end
            end
        end

    elseif tab == ACTION_TAB_MARKET then
        -- ═══ 🏪 市场 Tab ═══
        -- 黄金交易（Day 12+）
        if goldPanel and ProgressiveUnlock.IsUnlocked("panel_gold") then
            table.insert(cardChildren, SectionTitle("🥇", "黄金交易"))
            table.insert(cardChildren, goldPanel)
        end
        -- 扩张经营（Day 12+）
        if #expandActions > 0 and ProgressiveUnlock.IsUnlocked("panel_branch") then
            table.insert(cardChildren, SectionTitle("🏗️", "扩张经营"))
            local ep = SectionPanel(expandActions)
            if ep then table.insert(cardChildren, ep) end
        end
    end

    -- ═══ 以下内容保留在所有Tab之外（向下兼容） ═══
    -- 团队与社交区块 — 已移入 TEAM tab（上方）
    if false and #socialActions > 0 and ProgressiveUnlock.IsUnlocked("panel_social") then
        table.insert(cardChildren, SectionTitle("🤝", "团队社交"))
        local sop = SectionPanel(socialActions)
        if sop then table.insert(cardChildren, sop) end
    end

    -- 黄金交易区块 — 已移入 MARKET tab（上方）
    if false and goldPanel and ProgressiveUnlock.IsUnlocked("panel_gold") then
        table.insert(cardChildren, SectionTitle("🥇", "黄金交易"))
        table.insert(cardChildren, goldPanel)
    end

    -- 扩张经营区块 — 已移入 MARKET tab（上方）
    if false and #expandActions > 0 and ProgressiveUnlock.IsUnlocked("panel_branch") then
        table.insert(cardChildren, SectionTitle("🏗️", "扩张经营"))
        local ep = SectionPanel(expandActions)
        if ep then table.insert(cardChildren, ep) end
    end

    -- ── 日记模块（已移至"日记"Tab，不在主页操作区显示） ──
    -- 保留新手引导完成触发（不依赖日记渲染）
    if (playerData_.tutorialStep or 0) == 3 then
        playerData_.tutorialStep = 99
        AddLog("🎉 【引导完成】你已掌握网吧经营基础！升级·比赛·招募，尽情探索吧！")
    end
    do -- diary block skipped on main page
        if false then -- DISABLED: diary moved to separate tab
        -- P0-1 新手引导 step3：日记渲染即表示玩家看到了日记，自动完成
        if (playerData_.tutorialStep or 0) == 3 then
            playerData_.tutorialStep = 99
            AddLog("🎉 【引导完成】你已掌握网吧经营基础！升级·比赛·招募，尽情探索吧！")
        end

        local currentDay = playerData_.day or 1
        -- 确保当天有条目
        if not diaryEntries_[currentDay] then
            local ok2, atmo2 = pcall(GetAtmosphere)
            diaryEntries_[currentDay] = { atmo = (ok2 and atmo2 or ""), logs = {} }
        end
        -- 刷新当天氛围（可能在同一天多次打开）
        local ok, atmosText = pcall(GetAtmosphere)
        if ok and atmosText and atmosText ~= "" then
            diaryEntries_[currentDay].atmo = atmosText
        end

        -- 收集所有天数，倒序，取近5天
        local allDays = {}
        for d, _ in pairs(diaryEntries_) do table.insert(allDays, d) end
        table.sort(allDays, function(a, b) return a > b end)
        local recentDays = {}
        for i = 1, math.min(5, #allDays) do recentDays[i] = allDays[i] end

        if #recentDays > 0 then
            table.insert(cardChildren, SectionTitle("📖", "店长日记"))

            for _, day in ipairs(recentDays) do
                local entry = diaryEntries_[day]
                local isToday = (day == currentDay)
                local isExpanded = expandedDiaryDays_[day] == true

                -- 摘要文字
                local summary = ""
                if entry.atmo and entry.atmo ~= "" then
                    local charCount, bytePos = 0, 1
                    while charCount < 25 and bytePos <= #entry.atmo do
                        local b = string.byte(entry.atmo, bytePos)
                        if b < 128 then bytePos = bytePos + 1
                        elseif b < 224 then bytePos = bytePos + 2
                        elseif b < 240 then bytePos = bytePos + 3
                        else bytePos = bytePos + 4 end
                        charCount = charCount + 1
                    end
                    summary = bytePos <= #entry.atmo and string.sub(entry.atmo, 1, bytePos - 1) .. "…" or entry.atmo
                end
                local logCount = (entry.logs and #entry.logs) or 0
                local logHint = logCount > 0 and ("  " .. logCount .. "条记录") or ""

                local cardBg = isToday and (C.diary_today or { 93, 67, 54, 255 }) or (C.diary_past or { 62, 48, 38, 245 })
                local borderCol = isToday and { C.accent[1], C.accent[2], C.accent[3], 60 } or { C.border[1], C.border[2], C.border[3], 50 }
                local dayLabel = "D" .. day .. (isToday and "（今天）" or "")
                local dayNum = day

                -- 日记卡片子元素
                local diaryCardChildren = {}

                -- 头部行：日期 + 展开/收起
                table.insert(diaryCardChildren, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center",
                    justifyContent = "space-between",
                    children = {
                        UI.Panel {
                            flexDirection = "row", alignItems = "center", gap = 5, flexShrink = 1,
                            children = {
                                UI.Label { text = isToday and "●" or "○", fontSize = 10,
                                    fontColor = isToday and C.accent or C.textLight },
                                UI.Label { text = dayLabel, fontSize = 12, fontWeight = "bold",
                                    fontColor = isToday and C.accent or C.textDim },
                            },
                        },
                        UI.Label { text = isExpanded and "▲" or "▼", fontSize = 10, fontColor = C.textLight },
                    },
                })

                if isExpanded then
                    -- 展开：氛围 + 日志
                    local contentChildren = {}
                    if entry.atmo and entry.atmo ~= "" then
                        table.insert(contentChildren, UI.Label {
                            text = entry.atmo, fontSize = 12, fontColor = { 253, 245, 230, 180 },
                            whiteSpace = "normal", lineHeight = 1.5, width = "100%",
                        })
                    end
                    if entry.logs and #entry.logs > 0 then
                        if entry.atmo and entry.atmo ~= "" then
                            table.insert(contentChildren, UI.Panel {
                                width = "100%", height = 1, marginVertical = 4,
                                backgroundColor = { 210, 180, 140, 40 },
                            })
                        end
                        for _, logText in ipairs(entry.logs) do
                            table.insert(contentChildren, UI.Label {
                                text = logText, fontSize = 11, fontColor = C.textDim,
                                whiteSpace = "normal", lineHeight = 1.3, width = "100%",
                            })
                        end
                    end
                    if #contentChildren == 0 then
                        table.insert(contentChildren, UI.Label {
                            text = isToday and "今天的故事还在书写中……" or "平淡的一天。",
                            fontSize = 11, fontColor = C.textLight,
                        })
                    end
                    table.insert(diaryCardChildren, UI.Panel {
                        width = "100%", gap = 3, paddingTop = 4,
                        children = contentChildren,
                    })
                else
                    -- 收起：一行摘要
                    if summary ~= "" or logHint ~= "" then
                        table.insert(diaryCardChildren, UI.Label {
                            text = (summary ~= "" and summary or "平淡的一天") .. logHint,
                            fontSize = 11, fontColor = C.textLight, whiteSpace = "nowrap",
                            paddingTop = 2,
                        })
                    end
                end

                table.insert(cardChildren, UI.Panel {
                    width = "100%", padding = 8, gap = 2,
                    backgroundColor = cardBg, borderRadius = PX.radius,
                    borderWidth = 1, borderColor = borderCol,
                    onClick = function()
                        expandedDiaryDays_[dayNum] = not expandedDiaryDays_[dayNum]
                        BuildUI()
                    end,
                    children = diaryCardChildren,
                })
            end
        end
        end -- if false (diary disabled)
    end

    return UI.Panel {
        width = "100%", padding = 6, gap = 6,
        children = cardChildren,
    }
end

--- 精简版行动区（用于沉浸式全景布局，移除已在热区的操作）
function BuildCompactActions()
    local ap = playerData_.actionPoints or 3
    local noAP = ap <= 0

    -- ── 辅助：紧凑行动按钮 ──
    local function ActionBtn(props)
        if props.variant then
            return UI.Button {
                text = props.text, width = props.width or "100%",
                height = props.height or 38, fontSize = 13, borderRadius = PX.radius,
                disabled = props.disabled, variant = props.variant, flex = props.flex,
                onClick = props.onClick,
            }
        end
        return UI.Button {
            text = props.text, width = props.width or "100%",
            height = props.height or 38, fontSize = 13, fontWeight = "bold", borderRadius = PX.radius,
            backgroundColor = props.disabled and { 50, 44, 40, 255 } or C.card,
            fontColor = props.disabled and C.textLight or C.text,
            borderWidth = PX.border,
            borderColor = props.disabled and C.border or (props.borderColor or C.accent),
            disabled = props.disabled, flex = props.flex,
            onClick = props.onClick,
        }
    end

    -- ── 次要状态标签行（从旧StatusBar移来） ──
    local tagItems = {}
    local ec = playerData_.equipCondition or 100
    table.insert(tagItems, UI.Label {
        text = "维护" .. ec .. "%", fontSize = 10,
        fontColor = ec <= 30 and C.red or (ec <= 50 and C.gold or C.textLight),
    })
    local karmaVal = playerData_.karma or 0
    local karmaTag = (karmaVal >= 4 and "善" or (karmaVal <= -3 and "恶" or "中")) .. karmaVal
    table.insert(tagItems, UI.Label {
        text = karmaTag, fontSize = 10,
        fontColor = karmaVal >= 4 and C.green or (karmaVal <= -3 and C.red or C.textLight),
    })
    local repInfo = ReputationSystem.GetProgressInfo()
    local repTag = repInfo.emoji .. repInfo.tierName .. " " .. repInfo.rep
    if repInfo.nextReq and repInfo.nextReq > 0 then
        repTag = repTag .. "/" .. repInfo.nextReq
    end
    table.insert(tagItems, UI.Label { text = repTag, fontSize = 10, fontColor = C.gold })
    local goldOz = playerData_.goldOunces or 0
    if goldOz > 0 then
        table.insert(tagItems, UI.Label {
            text = "Au" .. string.format("%.1f", goldOz) .. "oz", fontSize = 10, fontColor = C.gold,
        })
    end
    local branchCount = #(playerData_.branches or {})
    if branchCount > 0 then
        table.insert(tagItems, UI.Label { text = "分店x" .. branchCount, fontSize = 10, fontColor = C.textDim })
    end

    local tagRow = UI.Panel {
        width = "100%", flexDirection = "row", flexWrap = "wrap",
        gap = 8, paddingHorizontal = 4, paddingVertical = 4,
        backgroundColor = C.cardAlt, borderRadius = PX.radius,
        children = tagItems,
    }

    -- ── 结束今天（像素凸起感） ──
    local noAP2 = (playerData_.actionPoints or 3) <= 0
    local endBotColor2 = noAP2 and { 20, 90, 38, 255 } or { 90, 58, 10, 255 }
    local endBgColor2  = noAP2 and { 45, 158, 72, 255 } or { 170, 115, 28, 255 }
    local endBorderHi2 = noAP2 and { 100, 220, 130, 200 } or { 230, 185, 75, 200 }
    local endMainText2 = noAP2 and "✅ 结束今天" or ("结束今天  (第" .. (playerData_.day or 1) .. "天)")
    local endDayBtn = UI.Panel {
        width = "100%", height = 44, borderRadius = PX.cardRadius,
        backgroundColor = endBotColor2,
        justifyContent = "center", alignItems = "center",
        onClick = function()
            if transition_.active then return end
            PlaySFX("click")
            local ok, err = pcall(EndDay)
            if not ok then
                log:Write(LOG_ERROR, "[EndDay] crashed: " .. tostring(err))
                currentPhase_ = PHASE_MANAGE
                pcall(BuildUI)
            end
        end,
        children = {
            UI.Panel {
                width = "100%", height = 41, borderRadius = PX.cardRadius,
                backgroundColor = endBgColor2,
                borderWidth = 2, borderColor = endBorderHi2,
                flexDirection = "row", justifyContent = "center", alignItems = "center",
                paddingHorizontal = 12, gap = 8,
                children = {
                    UI.Label { text = noAP2 and "✅ 结束今天" or endMainText2,
                        fontSize = 15, fontWeight = "bold",
                        fontColor = { 245, 255, 245, 255 } },
                    noAP2 and UI.Label { text = "行动点已用完·进入明天",
                        fontSize = 10, fontColor = { 205, 248, 215, 180 } } or nil,
                },
            },
        },
    }

    -- ── 广告区 ──
    local adDoubleIncome = nil
    local lastNet = playerData_.lastNetIncome or 0
    if AdManager.CanWatch("double_income", playerData_.day) then
        local bonus = lastNet > 0 and lastNet or math.max(50, math.floor(playerData_.day * 8))
        local label = lastNet > 0
            and ("看广告翻倍昨日收入 +$" .. bonus)
            or  ("看广告领经营补贴 +$" .. bonus)
        adDoubleIncome = AdManager.AdButton {
            sceneId = "double_income", day = playerData_.day,
            text = label, height = 36, fontSize = 12,
            onReward = function()
                playerData_.money = playerData_.money + bonus
                playerData_.totalEarnings = (playerData_.totalEarnings or 0) + bonus
                playerData_.lastNetIncome = 0
                AddLog("🎬 赞助商追加了经营奖励！额外获得$" .. bonus .. "！")
                BuildUI()
            end,
        }
    end

    local adExtraAP = nil
    if noAP and AdManager.CanWatch("extra_ap", playerData_.day) then
        adExtraAP = AdManager.AdButton {
            sceneId = "extra_ap", day = playerData_.day,
            text = "看视频多干一件事 +1AP", height = 36, fontSize = 12,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商的能量饮料让你恢复了精力！行动点+1")
                BuildUI()
            end,
        }
    end

    -- 方案B: 加班按钮（精简版，BuildCompactActions 里）
    local overtimeBtn = nil
    if noAP and not (playerData_.overtimeUsedToday) and not adExtraAP then
        local otCost2 = GetCityCost and GetCityCost(30) or 30
        local canAfford = (playerData_.money or 0) >= otCost2
        overtimeBtn = UI.Button {
            text = canAfford and ("加班 -$" .. otCost2 .. " -耐久5 → +1AP") or ("加班需 $" .. otCost2 .. "（余额不足）"),
            width = "100%", height = 40, fontSize = 12, fontWeight = "bold",
            backgroundColor = canAfford and { 50, 35, 18, 255 } or { 35, 28, 20, 255 },
            fontColor = canAfford and { 230, 170, 60, 255 } or { 90, 78, 60, 200 },
            borderWidth = PX.border,
            borderColor = canAfford and { 180, 130, 40, 200 } or { 70, 60, 45, 150 },
            borderRadius = PX.radius,
            disabled = not canAfford,
            onClick = canAfford and function()
                playerData_.money = playerData_.money - otCost2
                playerData_.actionPoints = (playerData_.actionPoints or 0) + 1
                playerData_.overtimeUsedToday = true
                playerData_.endOfDayDurPenalty = (playerData_.endOfDayDurPenalty or 0) + 5
                AddLog("🌙 【加班】透支精力——$" .. otCost2 .. " + 设备多跑一小时，换来1点行动力")
                BuildUI()
            end or nil,
        }
    end

    -- ── 每日委托（Day15+ 显示委托板精简版） ──
    local questPanel = nil
    if dailyQuest_ and playerData_.day >= 10 then
        CheckQuestProgress()

        -- 精简委托行构建函数
        local function QuestRow(q, slotIdx, label)
            local done = q.progress >= q.goal
            local progressText = done and "✅" or (q.progress .. "/" .. q.goal)
            local rowChildren = {
                UI.Label { text = q.icon or "📋", fontSize = 13, flexShrink = 0 },
                UI.Panel { flex = 1, gap = 1, children = {
                    UI.Label { text = label .. ": " .. q.desc, fontSize = 11,
                        fontColor = C.text, whiteSpace = "normal" },
                    UI.Label { text = "奖励: " .. q.rewardDesc, fontSize = 10,
                        fontColor = C.textDim },
                }},
                UI.Label { text = progressText, fontSize = 11,
                    fontColor = done and C.green or C.textDim, flexShrink = 0 },
            }
            if done and not q.claimed then
                table.insert(rowChildren, UI.Button {
                    text = "领取", width = 46, height = 26, fontSize = 10,
                    borderRadius = 5, backgroundColor = { 65, 55, 40, 255 },
                    fontColor = C.gold, flexShrink = 0,
                    onClick = function()
                        if slotIdx == 1 then ClaimQuestReward()
                        else pcall(ClaimBoardQuestReward, slotIdx) end
                        BuildUI()
                    end,
                })
            end
            return UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
                paddingHorizontal = 8, paddingVertical = 5,
                backgroundColor = done and not q.claimed
                    and { 50, 44, 20, 220 } or C.cardAlt,
                borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 35 },
                children = rowChildren,
            }
        end

        if playerData_.day >= 15 and dailyQuestBoard_ and #dailyQuestBoard_ >= 1 then
            -- 委托板精简视图
            local rows = {}
            local labels = { "主委托", "快速", "快速" }
            for i, q in ipairs(dailyQuestBoard_) do
                if q then table.insert(rows, QuestRow(q, i, labels[i] or "委托")) end
            end
            local streak = playerData_.questStreak or 0
            questPanel = UI.Panel {
                width = "100%", paddingHorizontal = 8, paddingVertical = 8,
                backgroundColor = C.cardAlt, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { C.gold[1], C.gold[2], C.gold[3], 40 },
                gap = 4,
                children = {
                    UI.Panel {
                        flexDirection = "row", justifyContent = "space-between",
                        alignItems = "center", width = "100%",
                        children = {
                            UI.Label { text = "📋 委托板", fontSize = 12, fontColor = C.gold },
                            streak >= 1 and UI.Label {
                                text = "🔥x" .. streak, fontSize = 11,
                                fontColor = { 255, 200, 60, 255 },
                            } or UI.Panel { width = 0, height = 0 },
                        },
                    },
                    table.unpack(rows),
                },
            }
        else
            questPanel = QuestRow(dailyQuest_, 1, "今日委托")
        end
    end

    -- ── 精简网格：只保留贴传单+比赛（逛集市/招募已在热区） ──
    local function GridBtn(props)
        local disabled = props.disabled
        local btnChildren = {
            UI.Label { text = props.title, fontSize = 13, fontWeight = "bold",
                fontColor = disabled and { 110, 95, 80, 255 } or C.text },
        }
        if props.price then
            table.insert(btnChildren, UI.Label { text = props.price, fontSize = 11,
                fontColor = disabled and { 90, 78, 65, 255 } or C.gold })
        end
        if props.reward and not disabled then
            table.insert(btnChildren, UI.Label { text = props.reward, fontSize = 9,
                fontColor = { 130, 200, 140, 200 } })
        end
        if props.reason and disabled then
            table.insert(btnChildren, UI.Label { text = props.reason, fontSize = 9,
                fontColor = { 120, 100, 80, 200 } })
        end
        return UI.Panel {
            width = "48%", height = 68, borderRadius = PX.radius,
            backgroundColor = disabled and { 48, 40, 34, 255 } or C.card,
            borderWidth = PX.border, borderColor = disabled and C.border or C.accent,
            justifyContent = "center", alignItems = "center", gap = 1,
            onClick = not disabled and props.onClick or nil,
            children = btnChildren,
        }
    end

    local gridItems = {}
    local flyCost2 = GetCityCost and GetCityCost(30) or 30
    table.insert(gridItems, GridBtn {
        title = "贴传单", price = "$" .. flyCost2,
        reward = "↑ 声望 / 曝光",
        disabled = noAP or playerData_.money < flyCost2,
        reason = playerData_.money < flyCost2 and "余额不足" or nil,
        onClick = function() DoPostFlyers() end,
    })
    local matchReason2 = nil
    if #teamMembers_ < 2 then matchReason2 = "需2名队员"
    elseif friendlyMatchToday_ then matchReason2 = "今日已赛" end
    table.insert(gridItems, GridBtn {
        title = "比赛",
        reward = "↑ 奖金 / 声望",
        disabled = noAP or #teamMembers_ < 2 or friendlyMatchToday_,
        reason = matchReason2,
        onClick = function()
            matchTierSelect_ = not matchTierSelect_
            PlaySFX("click"); BuildUI()
        end,
    })

    local gridPanel = UI.Panel {
        width = "100%", flexDirection = "row", gap = 8, justifyContent = "space-between",
        children = gridItems,
    }

    -- ── 比赛等级选择（复用原逻辑） ──
    local tierPanel = nil
    if matchTierSelect_ and not friendlyMatchToday_ and not noAP and #teamMembers_ >= 2 then
        local tierBtns = {}
        local tw = playerData_.tierWins or { 0, 0, 0 }
        for i, tier in ipairs(MATCH_TIERS) do
            local unlocked = tier.unlock()
            local cityCost2 = GetCityCost(tier.cost)
            local canAfford = playerData_.money >= cityCost2
            local winsText = tw[i] and tw[i] > 0 and (" (" .. tw[i] .. "胜)") or ""
            if unlocked then
                table.insert(tierBtns, ActionBtn {
                    text = tier.name .. " $" .. cityCost2 .. winsText,
                    disabled = not canAfford,
                    onClick = function()
                        matchTierSelect_ = false
                        pendingMatchTier_ = i
                        matchGameSelect_ = true
                        PlaySFX("click"); BuildUI()
                    end,
                })
            else
                table.insert(tierBtns, ActionBtn { text = "" .. tier.unlockDesc, disabled = true })
            end
        end
        -- 锦标赛入口
        if chaptersRead_[3] then
            local tWinsMap = playerData_.tournamentTierWins or {}
            table.insert(tierBtns, UI.Panel { height = 2, width = "90%", backgroundColor = { 220, 165, 30, 100 } })
            table.insert(tierBtns, UI.Label { text = "── 锦标赛 ──", fontSize = 11, fontColor = C.gold, textAlign = "center" })
            for ti, tt in ipairs(TOURNAMENT_TIERS) do
                local prevOk = (tt.prevWinReq == nil) or ((tWinsMap[tt.prevWinReq] or 0) >= 1)
                local repOk = playerData_.reputation >= tt.repReq
                local teamOk = #teamMembers_ >= tt.teamReq
                local powerOk = GetTeamPower() >= tt.powerReq
                local ttCost = GetCityCost and GetCityCost(tt.cost) or tt.cost
                local canAffordT = playerData_.money >= ttCost
                local unlocked = prevOk and repOk and teamOk and powerOk
                local myWins = tWinsMap[tt.id] or 0
                local record = myWins > 0 and (" ×" .. myWins) or ""
                if unlocked then
                    table.insert(tierBtns, ActionBtn {
                        text = tt.name .. " $" .. ttCost .. record,
                        disabled = not canAffordT,
                        onClick = function()
                            matchTierSelect_ = false
                            PlaySFX("click")
                            playerData_.money = playerData_.money - ttCost
                            isFriendlyMatch_ = false
                            currentTournamentTier_ = ti
                            matchGameType_ = nil
                            matchOpponents_ = {}
                            for _, opp in ipairs(tt.opponents) do
                                table.insert(matchOpponents_, { name = opp.name, power = opp.power, style = opp.style, emoji = opp.emoji, boss = opp.boss })
                            end
                            matchRound_ = 0; matchWins_ = 0; matchLog_ = {}; matchPhase_ = "intro"
                            PlayBGM("match")
                            StartTransition(tt.transition.title, tt.transition.sub, function()
                                currentPhase_ = PHASE_MATCH; BuildUI()
                            end)
                        end,
                    })
                else
                    table.insert(tierBtns, ActionBtn { text = "" .. tt.unlockDesc, disabled = true })
                end
            end
        end
        tierPanel = UI.Panel {
            width = "100%", padding = 8, gap = 4,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = tierBtns,
        }
    end

    -- ── 游戏选择面板 ──
    local gameSelectPanel = nil
    if matchGameSelect_ and pendingMatchTier_ then
        local gameBtns = {}
        for _, gt in ipairs(GAME_TYPES) do
            table.insert(gameBtns, ActionBtn {
                text = gt.name .. " (" .. gt.desc .. ")",
                onClick = function()
                    matchGameType_ = gt
                    matchGameSelect_ = false
                    PlaySFX("click")
                    DoHostTournament(pendingMatchTier_)
                end,
            })
        end
        table.insert(gameBtns, UI.Label {
            text = "选择参赛游戏类型", fontSize = 10, fontColor = C.textDim, textAlign = "center",
        })
        table.insert(gameBtns, ActionBtn {
            text = "← 返回选等级", variant = "secondary",
            onClick = function()
                matchGameSelect_ = false; pendingMatchTier_ = nil; matchTierSelect_ = true
                PlaySFX("click"); BuildUI()
            end,
        })
        gameSelectPanel = UI.Panel {
            width = "100%", padding = 8, gap = 4,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = { UI.Label { text = "选择比赛游戏", fontSize = 12, fontColor = C.accent }, table.unpack(gameBtns) },
        }
    end

    -- 章节推进已改为自动触发（EndDay结算时由ChapterSystem驱动），移除手动横幅

    -- ── 分区辅助 ──
    local function SectionTitle(icon, title)
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            paddingTop = 2, paddingBottom = 1,
            children = {
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
                UI.Label { text = icon .. " " .. title, fontSize = 11, fontColor = C.textDim, flexShrink = 0 },
                UI.Panel { width = "100%", height = 1, backgroundColor = { 255, 255, 255, 30 }, flex = 1 },
            },
        }
    end

    -- ── 设备维护（复用原逻辑） ──
    local maintActions = {}
    local genLv = playerData_.generatorLevel or 0
    if genLv > 0 then
        local fuel = playerData_.fuel or 0
        local cap = playerData_.fuelCapacity or 20
        local fuelCost = 8 * (cap - fuel)
        if fuel < cap then
            fuelCost = math.min(fuelCost, math.max(30, fuelCost))
            local buyAmount = cap - fuel
            table.insert(maintActions, ActionBtn {
                text = "买燃油 +" .. buyAmount .. "L $" .. fuelCost .. " (" .. fuel .. "/" .. cap .. "L)",
                disabled = playerData_.money < fuelCost,
                onClick = function() DoBuyFuel() end,
            })
        else
            table.insert(maintActions, UI.Label {
                text = "燃油已满 " .. fuel .. "/" .. cap .. "L", fontSize = 12, fontColor = C.green,
            })
        end
    end
    local cond = playerData_.equipCondition or 100
    if cond < 95 then
        local repairCost = 50 + playerData_.computers * 10
        table.insert(maintActions, ActionBtn {
            text = "维修设备 $" .. repairCost .. " (" .. string.format("%.1f", cond) .. "%)",
            disabled = noAP or playerData_.money < repairCost,
            onClick = function() DoRepairEquipment() end,
        })
        if AdManager.CanWatch("free_repair", playerData_.day) then
            table.insert(maintActions, AdManager.AdButton {
                sceneId = "free_repair", day = playerData_.day,
                text = "看视频免费维修 省$" .. repairCost,
                height = 34, fontSize = 11,
                onReward = function()
                    local before = playerData_.equipCondition or 0
                    playerData_.equipCondition = math.min(100, before + 30)
                    AddLog("🎬 赞助商派技术团队免费维护！" .. before .. "%→" .. playerData_.equipCondition .. "%")
                    BuildUI()
                end,
            })
        end
    end

    -- ── 副业（移除修手机，已在热区） ──
    local sideJobActions = {}
    if #teamMembers_ >= 1 then
        table.insert(sideJobActions, ActionBtn {
            text = "代练服务 AP1", disabled = noAP,
            onClick = function() DoBoostingService() end,
        })
    end
    if #teamMembers_ >= 2 and playerData_.netSpeed >= 2 then
        table.insert(sideJobActions, ActionBtn {
            text = "直播跑刀三角洲 AP1", disabled = noAP,
            onClick = function() DoStreamDeltaForce() end,
        })
    end
    if playerData_.computers >= 4 then
        table.insert(sideJobActions, ActionBtn {
            text = "接包场活动 AP1", disabled = noAP,
            onClick = function() DoCafeRental() end,
        })
    end
    if playerData_.day >= 7 then
        table.insert(sideJobActions, ActionBtn {
            text = "逛二手淘宝 AP1", disabled = noAP or playerData_.money < 50,
            onClick = function() DoSecondHandMarket() end,
        })
    end

    -- ── 社交 ──
    local socialActions = {}
    if #teamMembers_ > 0 then
        local bbqC2 = GetCityCost and GetCityCost(60) or 60
        table.insert(socialActions, ActionBtn {
            text = "请队员吃烤肉 ($" .. bbqC2 .. ") AP1",
            disabled = noAP or playerData_.money < bbqC2,
            onClick = function() DoTeamBBQ() end,
        })
    end
    -- 广告：免费招募队员
    if #CANDIDATE_POOL > 0 and AdManager.CanWatch("recruit_discount", playerData_.day) then
        local adLabel = #teamMembers_ >= 5 and "看视频免费替换队员（省$200）" or "看视频免费招募一次（省$200）"
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "recruit_discount", day = playerData_.day,
            text = adLabel, height = 34, fontSize = 11,
            onReward = function()
                playerData_.actionPoints = playerData_.actionPoints + 1
                AddLog("🎬 赞助商赞助了招募费用！这次找人不花钱！")
                ScoutRecruit()
            end,
        })
    end
    if AdManager.CanWatch("reputation_ad", playerData_.day) then
        table.insert(socialActions, AdManager.AdButton {
            sceneId = "reputation_ad", day = playerData_.day,
            text = "接受媒体采访 声望+20", height = 34, fontSize = 11,
            onReward = function()
                playerData_.reputation = playerData_.reputation + 20
                AddLog("🎬 赞助商安排了媒体采访！声望+20")
                BuildUI()
            end,
        })
    end

    -- ── 扩张 ──
    local expandActions = {}
    if playerData_.money < 300 and (playerData_.debt or 0) < 500 then
        local alreadyBorrowed = playerData_.debtDay == playerData_.day
        table.insert(expandActions, ActionBtn {
            text = alreadyBorrowed and "找Mama B借钱 (今日已借)" or "找Mama B借钱 ($300)",
            disabled = alreadyBorrowed,
            onClick = function() DoBorrowMoney() end,
        })
    end
    if (playerData_.debt or 0) > 0 then
        table.insert(expandActions, UI.Label {
            text = "欠款: $" .. playerData_.debt .. " (每日自动还30%余额)",
            fontSize = 13, fontColor = C.red, paddingLeft = 4,
        })
    end
    local nextBranchCost = BRANCH_COSTS[branchCount + 1] or 9000
    local canBranch = playerData_.money >= 8000 and branchCount < 3
    if canBranch and branchOpenStep_ == 0 then
        table.insert(expandActions, ActionBtn {
            text = "开分店 $" .. nextBranchCost .. " (第" .. (branchCount + 1) .. "家)",
            disabled = playerData_.money < nextBranchCost,
            onClick = function()
                branchOpenLocOpts_ = RollBranchLocationOptions()
                branchOpenStep_ = 1
                PlaySFX("click"); BuildUI()
            end,
        })
    end
    -- 分店步骤1
    if branchOpenStep_ == 1 and branchOpenLocOpts_ then
        local locBtns = {
            UI.Label { text = "选择分店城市", fontSize = 13, fontColor = C.gold, fontWeight = "bold" },
        }
        for _, loc in ipairs(branchOpenLocOpts_) do
            table.insert(locBtns, UI.Button {
                text = loc.name .. "\n" .. loc.desc .. "\n" .. loc.bonusDesc,
                width = "100%", height = 60, fontSize = 12, borderRadius = PX.radius,
                backgroundColor = C.accentLight, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 100 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function()
                    branchOpenSelLoc_ = loc; branchOpenStep_ = 2
                    PlaySFX("click"); BuildUI()
                end,
            })
        end
        table.insert(locBtns, UI.Button {
            text = "← 取消", width = "100%", height = 32, fontSize = 12, borderRadius = PX.radius, variant = "secondary",
            onClick = function() branchOpenStep_ = 0; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.accentLight, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = locBtns,
        })
    end
    -- 分店步骤2
    if branchOpenStep_ == 2 and branchOpenSelLoc_ then
        local gameBtns = {
            UI.Label { text = branchOpenSelLoc_.name .. " · 选择特色游戏", fontSize = 12, fontColor = C.accent, textAlign = "center", width = "100%" },
        }
        for _, game in ipairs(BRANCH_GAMES) do
            table.insert(gameBtns, UI.Button {
                text = game.name .. " — " .. game.desc .. "\n" .. game.bonusDesc,
                width = "100%", height = 50, fontSize = 12, borderRadius = PX.radius,
                backgroundColor = C.cardAlt, fontColor = C.text,
                borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 80 },
                textAlign = "left", whiteSpace = "normal",
                onClick = function() PlaySFX("upgrade"); DoOpenBranch(branchOpenSelLoc_, game) end,
            })
        end
        table.insert(gameBtns, UI.Button {
            text = "← 重选城市", width = "100%", height = 32, fontSize = 12, borderRadius = PX.radius, variant = "secondary",
            onClick = function() branchOpenStep_ = 1; PlaySFX("click"); BuildUI() end,
        })
        table.insert(expandActions, UI.Panel {
            width = "100%", padding = 8, gap = 6,
            backgroundColor = C.cardAlt, borderRadius = PX.radius,
            borderWidth = PX.border, borderColor = { C.accent[1], C.accent[2], C.accent[3], 60 },
            children = gameBtns,
        })
    end

    -- ── 黄金交易（阿布杜大叔 · 紧凑入口） ──
    local goldPanel = nil
    if playerData_.day >= 10 then
        local goldPrice = GetGoldPrice()
        local curGold = playerData_.goldOunces or 0
        local prevPrice = GetGoldPrice((playerData_.day or 1) - 1)
        local trend = goldPrice > prevPrice and "↑" or (goldPrice < prevPrice and "↓" or "→")
        local holdText = curGold > 0 and (" 持仓" .. string.format("%.1f", curGold) .. "oz") or ""
        -- 大叔短评
        local uncleQuote, uncleSignal = GetUncleAbduQuote()
        local shortQuote = uncleQuote and (#uncleQuote > 20 and string.sub(uncleQuote, 1, 18) .. "…" or uncleQuote) or ""
        goldPanel = ActionBtn {
            text = "🧔 " .. trend .. " $" .. goldPrice .. "/oz" .. holdText .. " | " .. shortQuote,
            borderColor = { C.gold[1], C.gold[2], C.gold[3], 120 },
            onClick = function()
                goldExpanded_ = not goldExpanded_
                PlaySFX("click"); BuildUI()
            end,
        }
        -- 展开时使用完整版
        if goldExpanded_ then
            local ok, fullCard = pcall(BuildActionCard)
            if ok then return fullCard end
        end
    end

    -- ── 组装紧凑卡片 ──
    local cardChildren = {}

    -- 状态标签行
    table.insert(cardChildren, tagRow)

    -- 结束今天（最醒目）
    table.insert(cardChildren, endDayBtn)

    -- 章节推进横幅（已移至顶部目标条显示，不再在操作区重复）
    -- 章节推进已由EndDay自动触发，无需手动横幅

    -- 广告区
    if adDoubleIncome then table.insert(cardChildren, adDoubleIncome) end
    if adExtraAP then table.insert(cardChildren, adExtraAP) end
    if overtimeBtn then table.insert(cardChildren, overtimeBtn) end  -- 方案B: 加班按钮

    -- ── 旅行者NPC（在场时显示交互卡片） ──
    if TravelerSystem and TravelerSystem.HasTraveler() then
        local traveler = TravelerSystem.GetCurrentTraveler()
        local offers = TravelerSystem.GetOffers()
        if traveler then
            local offerRows = {}
            for _, offer in ipairs(offers) do
                local labelText = offer.label
                if offer.cost > 0 then labelText = labelText .. "  $" .. offer.cost end
                local btnBg = offer.used and { 30, 28, 24, 255 }
                    or (offer.available and { 45, 38, 20, 255 } or { 35, 30, 24, 255 })
                local btnBorder = offer.used and { 50, 45, 38, 180 }
                    or (offer.available and { 180, 140, 40, 200 } or { 70, 60, 45, 150 })
                local labelColor = offer.used and { 80, 72, 60, 255 }
                    or (offer.available and { 240, 210, 120, 255 } or { 120, 105, 80, 255 })
                table.insert(offerRows, UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingVertical = 7,
                    backgroundColor = btnBg, borderRadius = PX.radius,
                    borderWidth = PX.border, borderColor = btnBorder,
                    gap = 2,
                    onClick = (not offer.used and offer.available) and function()
                        PlaySFX("click")
                        local ok, result = TravelerSystem.UseOffer(offer.idx)
                        if ok then
                            AddLog(traveler.emoji .. " " .. traveler.name .. ": " .. result)
                        else
                            AddLog("❌ " .. result)
                        end
                        BuildUI()
                    end or nil,
                    children = {
                        UI.Label { text = offer.used and ("✓ " .. offer.label .. " (已完成)") or labelText,
                            fontSize = 12, fontWeight = "bold", fontColor = labelColor },
                        UI.Label { text = offer.desc, fontSize = 10,
                            fontColor = offer.used and { 70, 64, 55, 200 } or { 160, 145, 120, 220 },
                            whiteSpace = "normal" },
                        (not offer.available and not offer.used and not offer.affordable) and
                            UI.Label { text = "余额不足", fontSize = 9, fontColor = C.red } or nil,
                        (not offer.available and not offer.used and not offer.condMet) and
                            UI.Label { text = "条件未满足", fontSize = 9, fontColor = { 180, 140, 60, 200 } } or nil,
                    },
                })
            end
            -- 活跃 buff 显示
            local activeBuffs = TravelerSystem.GetActiveBuffs()
            local buffRow = nil
            if #activeBuffs > 0 then
                local buffLabels = {}
                for _, b in ipairs(activeBuffs) do
                    table.insert(buffLabels, UI.Label {
                        text = b.icon .. "+" .. math.floor(b.bonus * 100) .. "% " .. b.daysLeft .. "天",
                        fontSize = 10, fontColor = { 140, 220, 160, 240 },
                    })
                end
                buffRow = UI.Panel {
                    width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 8,
                    paddingHorizontal = 6, paddingVertical = 4,
                    backgroundColor = { 25, 45, 30, 200 }, borderRadius = PX.radius,
                    children = buffLabels,
                }
            end
            local travelerCard = UI.Panel {
                width = "100%", borderRadius = PX.cardRadius,
                backgroundColor = { 35, 28, 18, 255 },
                borderWidth = 1, borderColor = { 160, 120, 40, 180 },
                overflow = "hidden",
                children = {
                    -- 顶部金色条
                    UI.Panel { width = "100%", height = 3, backgroundColor = { 200, 155, 40, 220 } },
                    -- 标题区
                    UI.Panel {
                        width = "100%", paddingHorizontal = 10, paddingVertical = 8,
                        flexDirection = "row", alignItems = "center", gap = 8,
                        children = {
                            UI.Panel {
                                width = 36, height = 36, borderRadius = 18,
                                backgroundColor = { 55, 42, 22, 255 },
                                borderWidth = 1, borderColor = { 180, 140, 50, 180 },
                                justifyContent = "center", alignItems = "center",
                                children = { UI.Label { text = traveler.emoji, fontSize = 18 } },
                            },
                            UI.Panel { flex = 1, gap = 1, children = {
                                UI.Label { text = traveler.name .. " · " .. traveler.title,
                                    fontSize = 13, fontWeight = "bold", fontColor = C.gold },
                                UI.Label { text = "来自" .. traveler.origin .. " · 停留" .. traveler.daysRemaining .. "天",
                                    fontSize = 10, fontColor = C.textDim },
                            }},
                            UI.Label { text = "🏕️", fontSize = 14 },
                        },
                    },
                    -- 问候语
                    UI.Panel {
                        width = "100%", paddingHorizontal = 10, paddingBottom = 6,
                        children = {
                            UI.Label { text = "\"" .. traveler.greeting .. "\"",
                                fontSize = 11, fontColor = { 180, 165, 130, 220 },
                                whiteSpace = "normal" },
                        },
                    },
                    -- Offers
                    UI.Panel {
                        width = "100%", paddingHorizontal = 8, paddingBottom = 8, gap = 4,
                        children = offerRows,
                    },
                    -- Active buffs
                    buffRow,
                },
            }
            table.insert(cardChildren, travelerCard)
        end
    -- 没有旅行者但有活跃buff时也显示buff条
    elseif TravelerSystem and TravelerSystem.GetActiveBuffs then
        local activeBuffs = TravelerSystem.GetActiveBuffs()
        if #activeBuffs > 0 then
            local buffLabels = {}
            for _, b in ipairs(activeBuffs) do
                table.insert(buffLabels, UI.Label {
                    text = b.icon .. b.name .. "+" .. math.floor(b.bonus * 100) .. "% (" .. b.daysLeft .. "天)",
                    fontSize = 10, fontColor = { 140, 220, 160, 240 },
                })
            end
            table.insert(cardChildren, UI.Panel {
                width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 8,
                paddingHorizontal = 8, paddingVertical = 5,
                backgroundColor = { 25, 45, 30, 200 }, borderRadius = PX.radius,
                borderWidth = PX.border, borderColor = { 60, 100, 70, 150 },
                children = {
                    UI.Label { text = "🏕️ 旅行者祝福", fontSize = 10, fontColor = C.gold, flexShrink = 0 },
                    table.unpack(buffLabels),
                },
            })
        end
    end

    -- 贴传单+比赛（比赛选择面板激活时替换网格，确保可见性）
    if tierPanel or gameSelectPanel then
        if tierPanel then table.insert(cardChildren, tierPanel) end
        if gameSelectPanel then table.insert(cardChildren, gameSelectPanel) end
    else
        table.insert(cardChildren, gridPanel)
    end

    -- 分区
    if #maintActions > 0 then
        table.insert(cardChildren, SectionTitle("🔧", "设备维护"))
        for _, a in ipairs(maintActions) do table.insert(cardChildren, a) end
    end
    if #sideJobActions > 0 then
        table.insert(cardChildren, SectionTitle("💼", "副业"))
        for _, a in ipairs(sideJobActions) do table.insert(cardChildren, a) end
    end
    if #socialActions > 0 then
        table.insert(cardChildren, SectionTitle("🤝", "社交"))
        for _, a in ipairs(socialActions) do table.insert(cardChildren, a) end
    end

    -- ── 训练场重玩 + 个人记录板 ──
    do
        local rec = playerData_.trainRecords or {}
        local hasAnyRecord = (rec.aim and rec.aim.score or 0) > 0
            or (rec.quiz and rec.quiz.correct or 0) > 0
            or (rec.react and rec.react.correct or 0) > 0
            or (rec.memory and rec.memory.correct or 0) > 0
            or (rec.comm and rec.comm.correct or 0) > 0

        local recordRows = {}
        local modes = {
            { id = "aim",    icon = "🎯", name = "枪线校准", color = { 255, 100, 60, 255 } },
            { id = "quiz",   icon = "🧠", name = "赛后复盘", color = { 100, 180, 255, 255 } },
            { id = "react",  icon = "⚡", name = "节奏反应", color = { 255, 80, 120, 255 } },
            { id = "memory", icon = "🗺️", name = "路线规划", color = { 255, 200, 60, 255 } },
            { id = "comm",   icon = "📡", name = "指挥通讯", color = { 160, 120, 255, 255 } },
        }
        for _, md in ipairs(modes) do
            local r = rec[md.id] or {}
            local bestText = "—"
            local rating = "—"
            if md.id == "aim" and (r.score or 0) > 0 then
                bestText = "命中" .. r.score .. " 连击x" .. (r.combo or 0)
                rating = r.score >= 15 and "S" or r.score >= 10 and "A" or r.score >= 6 and "B" or "C"
            elseif md.id == "quiz" and (r.correct or 0) > 0 then
                local pct = (r.total or 1) > 0 and math.floor(r.correct / r.total * 100) or 0
                bestText = r.correct .. "/" .. (r.total or "?") .. " (" .. pct .. "%)"
                rating = pct >= 100 and "S" or pct >= 80 and "A" or pct >= 60 and "B" or "C"
            elseif md.id == "react" and (r.correct or 0) > 0 then
                bestText = r.correct .. "/" .. (r.total or "?") .. " " .. string.format("%.2fs", r.avgTime or 0)
                rating = r.correct >= 9 and "S" or r.correct >= 7 and "A" or r.correct >= 4 and "B" or "C"
            elseif md.id == "memory" and (r.correct or 0) > 0 then
                bestText = "通过" .. r.correct .. "/" .. (r.rounds or "?")
                rating = r.correct >= 5 and "S" or r.correct >= 4 and "A" or r.correct >= 2 and "B" or "C"
            elseif md.id == "comm" and (r.correct or 0) > 0 then
                bestText = "截获" .. r.correct .. "/" .. (r.rounds or "?") .. " x" .. string.format("%.1f", r.speed or 0)
                rating = r.correct >= 7 and "S" or r.correct >= 5 and "A" or r.correct >= 3 and "B" or "C"
            end
            local ratingColor = rating == "S" and C.gold or rating == "A" and C.green
                or rating == "B" and C.blue or C.textDim
            table.insert(recordRows, UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                paddingVertical = 4, paddingHorizontal = 6, gap = 6,
                children = {
                    UI.Label { text = md.icon, fontSize = 14, width = 20 },
                    UI.Panel { flex = 1, children = {
                        UI.Label { text = md.name, fontSize = 11, fontColor = md.color },
                    }},
                    UI.Label { text = bestText, fontSize = 10, fontColor = C.textDim, flexShrink = 1 },
                    rating ~= "—" and UI.Panel {
                        width = 22, height = 22, borderRadius = 11,
                        backgroundColor = { ratingColor[1], ratingColor[2], ratingColor[3], 40 },
                        justifyContent = "center", alignItems = "center",
                        children = { UI.Label { text = rating, fontSize = 10, fontWeight = "bold", fontColor = ratingColor } },
                    } or UI.Label { text = "—", fontSize = 10, fontColor = C.textLight, width = 22, textAlign = "center" },
                },
            })
        end

        local trainCard = UI.Panel {
            width = "100%", borderRadius = PX.cardRadius,
            backgroundColor = { 28, 32, 40, 255 },
            borderWidth = 1, borderColor = { 80, 100, 140, 150 },
            overflow = "hidden",
            children = {
                -- 顶部渐变条
                UI.Panel { width = "100%", height = 3, backgroundColor = { 100, 140, 220, 200 } },
                -- 标题
                UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingVertical = 8,
                    flexDirection = "row", alignItems = "center", gap = 8,
                    children = {
                        UI.Label { text = "🏋️", fontSize = 18 },
                        UI.Panel { flex = 1, children = {
                            UI.Label { text = "训练场", fontSize = 14, fontWeight = "bold", fontColor = C.text },
                            UI.Label { text = "不消耗行动力  刷新个人记录", fontSize = 10, fontColor = C.textDim },
                        }},
                        UI.Panel {
                            paddingHorizontal = 8, paddingVertical = 4,
                            backgroundColor = { 60, 80, 140, 200 }, borderRadius = 10,
                            onClick = function()
                                PlaySFX("click")
                                StartReplayTraining()
                            end,
                            children = { UI.Label { text = "▶ 开始", fontSize = 11, fontWeight = "bold",
                                fontColor = { 200, 220, 255, 255 } } },
                        },
                    },
                },
                -- 记录板
                hasAnyRecord and UI.Panel {
                    width = "100%", paddingHorizontal = 8, paddingBottom = 8, gap = 2,
                    children = recordRows,
                } or UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingBottom = 10,
                    children = {
                        UI.Label { text = "完成训练后这里将显示个人最佳记录", fontSize = 10,
                            fontColor = C.textLight, textAlign = "center" },
                    },
                },
                -- 总次数
                (playerData_.trainPlayCount or 0) > 0 and UI.Panel {
                    width = "100%", paddingHorizontal = 10, paddingBottom = 6,
                    alignItems = "flex-end",
                    children = {
                        UI.Label { text = "累计练习 " .. (playerData_.trainPlayCount or 0) .. " 次",
                            fontSize = 9, fontColor = C.textLight },
                    },
                } or nil,
            },
        }
        table.insert(cardChildren, SectionTitle("🏋️", "训练场"))
        table.insert(cardChildren, trainCard)
    end

    if goldPanel then
        table.insert(cardChildren, SectionTitle("🥇", "黄金"))
        table.insert(cardChildren, goldPanel)
    end
    if #expandActions > 0 then
        table.insert(cardChildren, SectionTitle("🏗️", "扩张"))
        for _, a in ipairs(expandActions) do table.insert(cardChildren, a) end
    end

    return UI.Panel {
        width = "100%", padding = 8, gap = 6,
        children = cardChildren,
    }
end

