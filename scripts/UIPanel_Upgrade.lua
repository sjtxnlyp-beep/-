---@diagnostic disable: undefined-global
local NarrativeLayer = require("NarrativeLayer")
-- ============================================================================
-- UIPanel_Upgrade: 设施升级面板（从 UIManage.lua 拆分）
-- ============================================================================

function GetUpgradeCur(key)
    if key == "computer" then return playerData_.computers - 3
    elseif key == "chair" then return playerData_.chairLevel - 1
    elseif key == "net" then return playerData_.netSpeed - 1
    elseif key == "ac" then return playerData_.acLevel
    elseif key == "solar" then return playerData_.solarLevel
    elseif key == "food" then return playerData_.foodShop
    elseif key == "deco" then return playerData_.decoLevel
    elseif key == "security" then return playerData_.securityLevel
    elseif key == "generator" then return playerData_.generatorLevel or 0
    elseif key == "well" then return playerData_.wellLevel or 0
    elseif key == "road" then return playerData_.roadLevel or 0
    elseif key == "coffee" then return playerData_.coffeeLevel or 0
    elseif key == "jukebox" then return playerData_.jukeboxLevel or 0
    end
    return 0
end

--- 构建"正在升级中"的进度卡片
local function BuildUpgradeProgressPanel()
    if not activeUpgrade_ then return nil end
    local cfg = UPGRADES[activeUpgrade_]
    if not cfg then return nil end
    local pct = 1.0 - (upgradeTimeLeft_ / math.max(1, upgradeTotalTime_))
    local timeStr = FormatUpgradeTime(math.max(0, upgradeTimeLeft_))
    local canAd = AdManager.CanWatch("upgrade_skip", playerData_.day)
    local adChildren = {}
    if canAd then
        table.insert(adChildren, AdManager.AdButton {
            sceneId = "upgrade_skip", day = playerData_.day,
            text = "看广告立即完成", width = "100%", height = 34, fontSize = 12,
            onReward = function()
                AddLog("📺 赞助商加速！升级立即完成！")
                CompleteUpgrade()
            end,
        })
    end
    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.cardAlt, borderRadius = PX.radius,
        borderWidth = PX.border, borderColor = C.border,
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                UI.Label { text = cfg.icon, fontSize = 22 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Label { text = cfg.name .. " 升级中...", fontSize = 14, fontColor = C.green, fontWeight = "bold" },
                    UI.Label { text = cfg.levelDesc and cfg.levelDesc[GetUpgradeCur(activeUpgrade_) + 1] or "", fontSize = 11, fontColor = C.textDim, whiteSpace = "normal" },
                }},
                UI.Label { id = "upgrade-time-label", text = timeStr, fontSize = 16, fontColor = C.gold, fontWeight = "bold" },
            }},
            -- 进度条
            UI.Panel { width = "100%", height = 8, backgroundColor = { C.border[1], C.border[2], C.border[3], 120 }, borderRadius = PX.radiusSm, overflow = "hidden", children = {
                UI.Panel { id = "upgrade-progress-fill", width = math.floor(pct * 100) .. "%", height = "100%", backgroundColor = C.green, borderRadius = PX.radiusSm },
            }},
            table.unpack(adChildren),
        },
    }
end

--- 生成小标签 pill（图标+文字的彩色小标签）
local function UpgradePill(icon, text, bgColor, fgColor)
    return UI.Panel {
        flexDirection = "row", alignItems = "center", gap = 3,
        paddingHorizontal = 6, paddingVertical = 2, flexShrink = 1,
        backgroundColor = bgColor, borderRadius = PX.radius, overflow = "hidden",
        children = {
            UI.Label { text = icon, fontSize = 11 },
            UI.Label { text = text, fontSize = 11, fontColor = fgColor, fontWeight = "bold" },
        },
    }
end

--- 生成单个升级物品卡片
local function BuildUpgradeItemCard(key)
    local cfg = UPGRADES[key]
    if not cfg then return nil end
    local cur = GetUpgradeCur(key)
    local nxt = cur + 1
    local maxLevels = cfg.costs and #cfg.costs or 0
    local maxed = nxt > maxLevels
    local cost = not maxed and cfg.costs[nxt] or nil
    local curDesc = cfg.levelDesc and cfg.levelDesc[cur] or nil
    local nxtDesc = cfg.levelDesc and cfg.levelDesc[nxt] or nil
    local isActive = activeUpgrade_ == key
    local hasPending = activeUpgrade_ ~= nil and not isActive
    local canAfford = cost and CanAffordCost(cost) or false
    local coupTag = IsCoupActive() and not maxed and "[政变]" or ""

    -- 每日限时折扣检查
    local RV2 = require("RetentionV2")
    local dailyDeal = RV2.GetDailyDiscount and RV2.GetDailyDiscount() or nil
    local hasDailyDeal = dailyDeal and dailyDeal.key == key and not dailyDeal.used and not maxed
    local dealCost = cost
    if hasDailyDeal and cost then
        dealCost = math.floor(cost * (100 - dailyDeal.pct) / 100)
        canAfford = CanAffordCost(dealCost)
    end

    -- 等级文本 Lv.X/Max
    local lvText = maxed and ("Lv.MAX") or ("Lv." .. cur .. "/" .. maxLevels)
    local lvColor = maxed and C.green or C.textDim

    -- 等级指示条（用小方块代替小圆点，更容易看）
    local dots = {}
    for i = 1, maxLevels do
        table.insert(dots, UI.Panel {
            width = 8, height = 4, borderRadius = PX.radiusSm,
            backgroundColor = i <= cur and { 190, 148, 50, 240 } or C.border,
        })
    end

    -- P1-b: 叙事化升级描述（优先用角色视角）
    local narrName = NarrativeLayer.GetNarrativeUpgradeName(key)
    local narrReason = NarrativeLayer.GetNarrativeUpgradeReason(key)
    local narrNPC = NarrativeLayer.GetUpgradeRelatedNPC(key)

    -- 描述：当前 → 下级（叠加叙事理由）
    local descText
    if maxed then
        descText = curDesc or cfg.desc
    elseif narrReason and not maxed then
        -- 用叙事理由替代默认描述
        descText = narrReason
    elseif curDesc and nxtDesc then
        descText = curDesc .. " → " .. nxtDesc
    elseif nxtDesc then
        descText = cfg.desc .. " → " .. nxtDesc
    else
        descText = cfg.desc
    end

    -- ── 底部操作栏 ──
    local bottomRow = {}
    if maxed then
        -- 满级：只显示满级标识
        table.insert(bottomRow, UpgradePill("", "满级", { C.green[1], C.green[2], C.green[3], 40 }, C.green))
    elseif isActive then
        -- 升级中
        table.insert(bottomRow, UpgradePill("", "升级中", { C.gold[1], C.gold[2], C.gold[3], 40 }, C.gold))
    else
        -- 可升级：显示费用标签 + 时间标签 + 升级按钮
        if cost then
            local costText = FormatCostText(cost)
            local timeText = FormatUpgradeTime(CalcUpgradeTime(cost, key))
            -- 每日限时折扣优先显示
            if hasDailyDeal then
                -- 紧凑横排：折后价 + 原价划线 + 折扣标签 + 时间
                table.insert(bottomRow, UpgradePill("", "$" .. dealCost,
                    canAfford and { C.green[1], C.green[2], C.green[3], 40 } or { C.red[1], C.red[2], C.red[3], 40 },
                    canAfford and C.green or C.red))
                table.insert(bottomRow, UI.Label { text = costText, fontSize = 10,
                    fontColor = { 130, 120, 110, 160 }, textDecorationLine = "line-through", flexShrink = 1 })
                table.insert(bottomRow, UpgradePill("🏷️", "-" .. dailyDeal.pct .. "%",
                    { 180, 50, 50, 60 }, { 255, 100, 100, 255 }))
                table.insert(bottomRow, UI.Label { text = timeText, fontSize = 10,
                    fontColor = { 160, 185, 220, 200 }, flexShrink = 1 })
            else
                -- P1: 员工建议折扣
                local discPct, discWho = 0, nil
                local okDisc, dp, dw = pcall(GetStaffDiscountForUpgrade, key)
                if okDisc and dp and dp > 0 then discPct, discWho = dp, dw end
                if discPct > 0 then
                    table.insert(bottomRow, UpgradePill("", costText,
                        { 80, 80, 70, 60 }, { 160, 150, 130, 160 }))
                    table.insert(bottomRow, UpgradePill("", "-" .. discPct .. "% " .. (discWho or "员工"),
                        { 80, 180, 80, 50 }, { 120, 230, 120, 255 }))
                else
                    table.insert(bottomRow, UpgradePill("", costText,
                        canAfford and { C.green[1], C.green[2], C.green[3], 40 } or { C.red[1], C.red[2], C.red[3], 40 },
                        canAfford and C.green or C.red))
                end
                table.insert(bottomRow, UpgradePill("", timeText, { 60, 80, 120, 80 }, { 160, 185, 220, 255 }))
            end
        end
        -- 弹性占位，把按钮推到右边
        table.insert(bottomRow, UI.Panel { flex = 1, flexShrink = 1 })
        table.insert(bottomRow, UI.Button {
            text = hasDailyDeal and "🏷️特惠升级" or (coupTag .. "升级"),
            height = 28, paddingHorizontal = 10, fontSize = 12, borderRadius = PX.radius,
            flexShrink = 0,
            disabled = hasPending or not canAfford,
            backgroundColor = hasDailyDeal and { 180, 50, 50, 255 } or nil,
            onClick = function() DoUpgrade(key) end,
        })
    end

    local borderCol = maxed and { 80, 90, 80, 80 }
        or isActive and { C.green[1], C.green[2], C.green[3], 180 }
        or (IsCoupActive() and { 220, 180, 60, 160 } or C.border)
    -- 满级：整体降低对比度，卡片变灰暗
    local cardBg = isActive and C.upgrade_active
        or (maxed and { 55, 62, 52, 200 } or C.upgrade_bg)
    local nameColor = maxed and { 130, 150, 125, 160 } or C.text

    return UI.Panel {
        width = "100%", padding = 10, gap = 5,
        backgroundColor = cardBg,
        borderRadius = PX.radius, borderWidth = maxed and PX.borderSm or PX.border, borderColor = borderCol,
        opacity = maxed and 0.65 or 1.0,
        children = {
            -- 第1行：名称缩写色块 + 名称 + 等级
            UI.Panel { flexDirection = "row", alignItems = "center", width = "100%", gap = 8, children = {
                -- 缩写色块
                UI.Panel {
                    width = 36, height = 36, borderRadius = PX.radius,
                    backgroundColor = maxed and { 80, 100, 78, 180 } or (isActive and C.gold or { 120, 90, 30, 220 }),
                    justifyContent = "center", alignItems = "center",
                    children = { UI.Label { text = (cfg.icon ~= "" and cfg.icon) or string.sub(cfg.name, 1, 3), fontSize = (cfg.icon ~= "" and 20) or 12, fontWeight = "bold", fontColor = maxed and { 160, 200, 155, 200 } or { 255, 255, 255, 255 } } },
                },
                -- 名称 + 等级条（P1-b: 未满级时用叙事化名称）
                UI.Panel { flex = 1, gap = 3, children = {
                    UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                        UI.Label { text = (not maxed and narrName) or cfg.name, fontSize = 14, fontColor = nameColor, fontWeight = "bold" },
                        UI.Label { text = lvText, fontSize = 11, fontColor = lvColor },
                        narrNPC and not maxed and UI.Label { text = "— " .. narrNPC, fontSize = 10, fontColor = { 180, 170, 140, 160 } } or nil,
                    }},
                    UI.Panel { flexDirection = "row", gap = 2, alignItems = "center", children = dots },
                }},
            }},
            -- 第2行：描述
            UI.Label {
                text = descText,
                fontSize = 11, fontColor = maxed and { 110, 190, 110, 200 } or C.textDim,
                whiteSpace = "normal", width = "100%", paddingLeft = 2,
            },
            -- 第3行：费用标签 + 时间标签 + 按钮
            UI.Panel {
                flexDirection = "row", alignItems = "center", width = "100%", gap = 6,
                overflow = "hidden", flexWrap = "nowrap",
                children = bottomRow,
            },
        },
    }
end

--- 生成一组升级卡片
local function BuildUpgradeGroup(keys, children)
    for _, key in ipairs(keys) do
        local card = BuildUpgradeItemCard(key)
        if card then table.insert(children, card) end
    end
end

function BuildUpgradeCard()
    local children = {}
    if not upgradeGroupExpand_ then upgradeGroupExpand_ = {} end

    -- ── 辅助：统计满级/未满级 ──
    local allKeys = {}
    for _, k in ipairs(UPGRADE_ORDER) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_COMMUNITY) do table.insert(allKeys, k) end
    for _, k in ipairs(UPGRADE_CULTURE) do table.insert(allKeys, k) end

    local maxedKeys = {}
    local availableKeys = {}
    for _, key in ipairs(allKeys) do
        local cfg = UPGRADES[key]
        if cfg then
            local cur = GetUpgradeCur(key)
            local maxLevels = cfg.costs and #cfg.costs or 0
            if cur >= maxLevels then
                table.insert(maxedKeys, key)
            else
                table.insert(availableKeys, key)
            end
        end
    end

    -- ══════════════════════════════════════════
    -- 网吧等级进度条（宏观目标）
    -- ══════════════════════════════════════════
    local rating = GetCafeRating()
    local starIcons = string.rep("⭐", rating.star)
    local progressPct = 0
    if rating.nextStarAt then
        -- 找当前星级的起始阈值
        local tiers = { 0, 8, 18, 30, 45 }
        local curAt = tiers[rating.star] or 0
        local range = rating.nextStarAt - curAt
        progressPct = range > 0 and math.floor((rating.totalLevel - curAt) / range * 100) or 100
    else
        progressPct = 100
    end
    local ratingSubText = rating.nextStarName
        and ("→ " .. rating.nextStarName .. " 还差" .. (rating.nextStarAt - rating.totalLevel) .. "级")
        or "已达最高等级！"

    table.insert(children, UI.Panel {
        width = "100%", gap = 4, paddingBottom = 4, children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, width = "100%", children = {
                UI.Label { text = starIcons, fontSize = 14 },
                UI.Label { text = rating.starName, fontSize = 14, fontWeight = "bold", fontColor = C.gold },
                UI.Panel { flex = 1 },
                UI.Label { text = "Lv." .. rating.totalLevel, fontSize = 12, fontColor = C.textLight },
            }},
            UI.Panel { width = "100%", height = 6, backgroundColor = { 50, 50, 40, 180 }, borderRadius = 3, overflow = "hidden", children = {
                UI.Panel { width = math.min(100, progressPct) .. "%", height = "100%", borderRadius = 3,
                    backgroundColor = rating.nextStarName and C.gold or C.green },
            }},
            UI.Label { text = ratingSubText, fontSize = 11, fontColor = C.textDim },
        },
    })
    table.insert(children, UI.Divider { spacing = 4 })

    -- ── 正在升级的进度卡片（置顶） ──
    local progressPanel = BuildUpgradeProgressPanel()
    if progressPanel then
        table.insert(children, progressPanel)
        table.insert(children, UI.Divider { spacing = 4 })
    end

    -- ══════════════════════════════════════════
    -- 推荐升级区（瓶颈感知 + ROI 排序 + 情境文案）
    -- ══════════════════════════════════════════
    if #availableKeys > 0 and not activeUpgrade_ then
        -- 1) 检测当前瓶颈
        local traffic = RefreshTraffic()
        local capacity = CalcCafeCapacity()
        local util = traffic / math.max(1, capacity)
        local genLv = playerData_.generatorLevel or 0
        local solarLv = playerData_.solarLevel or 0
        local hasPowerProtect = (genLv >= 1 and (playerData_.fuel or 0) > 0) or solarLv >= 2

        -- 瓶颈类型判定
        local bottleneck = "balanced"  -- 默认均衡
        local bottleneckText = nil
        local bottleneckColor = C.gold
        if util >= 1.0 then
            bottleneck = "capacity"
            local overflow = math.max(0, traffic - capacity)
            bottleneckText = "🔥 客满溢出！" .. overflow .. "人在排队，扩容可直接增收"
            bottleneckColor = { 255, 120, 80, 255 }
        elseif util < 0.7 then
            bottleneck = "traffic"
            local empty = capacity - traffic
            bottleneckText = "📉 " .. empty .. "个空位没坐满，需要引流拉客"
            bottleneckColor = { 120, 180, 255, 255 }
        elseif not hasPowerProtect and playerData_.day >= 3 then
            bottleneck = "power"
            bottleneckText = "⚡ 无停电保护，15%概率收入腰斩"
            bottleneckColor = { 255, 200, 60, 255 }
        end

        -- 2) 每项升级的 ROI 和瓶颈加成
        local dailyBenefitMap = {
            computer  = 25, chair = 5, net = 10, ac = 8,
            solar = 6, food = 18, deco = 8, security = 5,
            generator = 10, well = 4, road = 12, coffee = 15, jukebox = 5,
        }
        local capacityKeys = { computer = true, chair = true, ac = true }
        local trafficKeys  = { food = true, road = true, deco = true, coffee = true, jukebox = true, well = true }
        local powerKeys    = { generator = true, solar = true }

        local scored = {}
        for _, key in ipairs(availableKeys) do
            local cfg = UPGRADES[key]
            local cur = GetUpgradeCur(key)
            local nxt = cur + 1
            local cost = cfg.costs[nxt]
            local costVal = type(cost) == "table" and (cost.money or cost[1] or 999999) or (cost or 999999)
            local canAfford = CanAffordCost(cost)

            local score = canAfford and 800 or 0
            local dailyB = dailyBenefitMap[key] or 5
            local roi = dailyB / math.max(1, costVal)
            score = score + roi * 2000

            local reason = nil
            if bottleneck == "capacity" and capacityKeys[key] then
                score = score + 500
                if key == "computer" then
                    reason = "➕ 加电脑 +3容量，解决排队"
                elseif key == "chair" then
                    reason = "➕ 升椅子 +2容量"
                elseif key == "ac" then
                    reason = "➕ 升空调 +2容量"
                end
            elseif bottleneck == "traffic" and trafficKeys[key] then
                score = score + 500
                if key == "food" then
                    reason = "📢 烤鸡摊 +5客流，引流利器"
                elseif key == "road" then
                    reason = "📢 修路 +4客流"
                elseif key == "coffee" then
                    reason = "📢 咖啡 +4客流"
                elseif key == "deco" then
                    reason = "📢 装饰 +3客流"
                else
                    reason = "📢 引流提升"
                end
            elseif bottleneck == "power" and powerKeys[key] then
                score = score + 400
                if key == "generator" then
                    reason = "🛡️ 发电机防停电，收入不腰斩"
                elseif key == "solar" then
                    reason = "🛡️ 太阳能减损"
                end
            end

            table.insert(scored, { key = key, score = score, canAfford = canAfford, reason = reason })
        end
        table.sort(scored, function(a, b) return a.score > b.score end)

        -- 3) 渲染推荐卡片
        local recChildren = {}
        local recCount = math.min(3, #scored)
        for idx = 1, recCount do
            local item = scored[idx]
            local card = BuildUpgradeItemCard(item.key)
            if card then
                local extras = {}
                if item.reason then
                    table.insert(extras, UI.Label {
                        text = item.reason, fontSize = 11, fontColor = { 255, 220, 100, 255 },
                        paddingLeft = 4,
                    })
                else
                    local benefit = GetUpgradeBenefitText(item.key)
                    if benefit then
                        table.insert(extras, UI.Label {
                            text = "📈 " .. benefit, fontSize = 11, fontColor = { 140, 220, 140, 240 },
                            paddingLeft = 4,
                        })
                    end
                end
                local synergyHint = GetUpgradeSynergyHint(item.key)
                if synergyHint then
                    table.insert(extras, UI.Label {
                        text = synergyHint, fontSize = 11, fontColor = { 255, 180, 80, 240 },
                        paddingLeft = 4,
                    })
                end
                if #extras > 0 then
                    table.insert(recChildren, UI.Panel { width = "100%", gap = 2, children = {
                        card,
                        table.unpack(extras),
                    }})
                else
                    table.insert(recChildren, card)
                end
            end
        end

        if #recChildren > 0 then
            local headerText = "推荐升级"
            if bottleneck == "capacity" then headerText = "推荐升级 · 扩容优先"
            elseif bottleneck == "traffic" then headerText = "推荐升级 · 引流优先"
            elseif bottleneck == "power" then headerText = "推荐升级 · 供电优先"
            end
            table.insert(children, PanelHeader(headerText, { icon = "⭐", compact = true, color = C.gold }))
            if bottleneckText then
                table.insert(children, UI.Label {
                    text = bottleneckText, fontSize = 11, fontColor = bottleneckColor,
                    paddingLeft = 4, paddingBottom = 4,
                })
            end
            for _, c in ipairs(recChildren) do table.insert(children, c) end
            table.insert(children, UI.Divider { spacing = 6 })
        end
    end

    -- ══════════════════════════════════════════
    -- 分组折叠手风琴（默认收起，只显示摘要行）
    -- ══════════════════════════════════════════
    local function BuildGroupAccordion(keys, groupId, title, icon, color)
        local groupAvail = {}
        local groupTotal = #keys
        local cheapestKey, cheapestCost = nil, 999999999
        for _, key in ipairs(keys) do
            local cfg = UPGRADES[key]
            if cfg then
                local cur = GetUpgradeCur(key)
                local maxLevels = cfg.costs and #cfg.costs or 0
                if cur < maxLevels then
                    table.insert(groupAvail, key)
                    local nxtCost = cfg.costs[cur + 1]
                    local cv = type(nxtCost) == "table" and (nxtCost.money or nxtCost[1] or 999999) or (nxtCost or 999999)
                    if cv < cheapestCost then
                        cheapestCost = cv
                        cheapestKey = key
                    end
                end
            end
        end
        if #groupAvail == 0 then return end

        local isExpanded = upgradeGroupExpand_[groupId] or false
        local cheapIcon = cheapestKey and (UPGRADES[cheapestKey].icon or "") or ""
        local summaryText = "可升" .. #groupAvail .. "项"
        if cheapestKey then
            summaryText = summaryText .. " | 最便宜" .. cheapIcon .. "$" .. FormatMoney(cheapestCost)
        end

        -- 摘要行（点击展开/收起）
        local arrowColor = isExpanded and C.gold or C.textLight
        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
            paddingVertical = 10, paddingHorizontal = 10,
            backgroundColor = isExpanded and { 55, 55, 45, 220 } or { 45, 45, 40, 180 },
            borderRadius = PX.radius,
            borderWidth = 1, borderColor = isExpanded and { C.gold[1], C.gold[2], C.gold[3], 100 } or { 80, 80, 70, 80 },
            onClick = function()
                upgradeGroupExpand_[groupId] = not isExpanded
                BuildUI()
            end,
            children = {
                icon and UI.Label { text = icon, fontSize = 16 } or nil,
                UI.Label { text = title, fontSize = 14, fontColor = color or C.text, fontWeight = "bold" },
                UI.Label { text = "(" .. #groupAvail .. "/" .. groupTotal .. ")", fontSize = 11, fontColor = C.textDim },
                UI.Panel { flex = 1 },
                UI.Label { text = summaryText, fontSize = 11, fontColor = C.textLight },
                -- 下拉箭头指示器（醒目颜色 + 较大尺寸）
                UI.Panel {
                    width = 22, height = 22, borderRadius = 11,
                    backgroundColor = { arrowColor[1], arrowColor[2], arrowColor[3], 40 },
                    justifyContent = "center", alignItems = "center",
                    children = {
                        UI.Label { text = isExpanded and "▲" or "▼", fontSize = 11, fontColor = arrowColor },
                    },
                },
            },
        })

        -- 展开时显示完整卡片
        if isExpanded then
            for _, key in ipairs(groupAvail) do
                local card = BuildUpgradeItemCard(key)
                if card then table.insert(children, card) end
            end
        end
    end

    BuildGroupAccordion(UPGRADE_ORDER, "market", "集市", "🏪", C.text)
    BuildGroupAccordion(UPGRADE_COMMUNITY, "community", "社区投资", "🏘️", C.gold)
    BuildGroupAccordion(UPGRADE_CULTURE, "culture", "文化空间", "🎭", { 220, 140, 80, 255 })

    -- ══════════════════════════════════════════
    -- 联动加成（折叠展示）
    -- ══════════════════════════════════════════
    local synergies = CalcUpgradeSynergies()
    if #synergies > 0 then
        table.insert(children, UI.Divider { spacing = 4 })
        local synExpand = upgradeGroupExpand_["synergy"] or false
        table.insert(children, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center", gap = 6,
            padding = 6, backgroundColor = { 50, 50, 35, 160 }, borderRadius = PX.radius,
            onClick = function()
                upgradeGroupExpand_["synergy"] = not synExpand
                BuildUI()
            end,
            children = {
                UI.Label { text = synExpand and "▾" or "▸", fontSize = 12, fontColor = C.textDim, width = 14 },
                UI.Label { text = "🔗", fontSize = 13 },
                UI.Label { text = "已激活联动", fontSize = 13, fontColor = C.green, fontWeight = "bold" },
                UI.Label { text = "×" .. #synergies, fontSize = 12, fontColor = C.gold },
            },
        })
        if synExpand then
            ---@diagnostic disable-next-line: param-type-mismatch
            for _, s in ipairs(synergies) do
                table.insert(children, UI.Label {
                    text = "  " .. s.name .. " — " .. s.desc, fontSize = 12, fontColor = { 160, 220, 140, 220 },
                    whiteSpace = "normal", width = "100%", paddingLeft = 20,
                })
            end
        end
    end

    -- ══════════════════════════════════════════
    -- 满级徽章区（紧凑一行）
    -- ══════════════════════════════════════════
    if #maxedKeys > 0 then
        table.insert(children, UI.Divider { spacing = 4 })
        local badges = {}
        for _, key in ipairs(maxedKeys) do
            local cfg = UPGRADES[key]
            table.insert(badges, UI.Panel {
                width = 28, height = 28, borderRadius = 14,
                backgroundColor = { 60, 80, 55, 220 },
                borderWidth = 1, borderColor = { 100, 160, 90, 180 },
                justifyContent = "center", alignItems = "center",
                children = { UI.Label { text = cfg.icon, fontSize = 12 } },
            })
        end
        table.insert(children, UI.Panel {
            width = "100%", gap = 3, children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 4, children = {
                    UI.Label { text = "✅", fontSize = 11 },
                    UI.Label { text = "已满级", fontSize = 11, fontColor = C.green, fontWeight = "bold" },
                    UI.Label { text = #maxedKeys .. "/" .. #allKeys, fontSize = 11, fontColor = C.textDim },
                }},
                UI.Panel { flexDirection = "row", flexWrap = "wrap", gap = 3, children = badges },
            },
        })
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = children,
    }
end


-- ============================================================================
-- AEL 赞助系统面板（嵌入升级 Tab）
-- ============================================================================

function BuildAELSponsorPanel()
    local ok, AEL = pcall(require, "AELSystem")
    if not ok or not AEL then return nil end

    local tier = playerData_.aelTier or 0
    local day = playerData_.day or 0

    -- 未到 D14 不显示
    if day < 12 then return nil end

    local info = AEL.GetInfo()
    local children = {}

    -- ── 头部标题行 ──
    local tierColors = {
        [0] = { 120, 120, 120, 255 },
        [1] = { 205, 127, 50, 255 },  -- 铜
        [2] = { 180, 200, 220, 255 }, -- 银
        [3] = { 255, 215, 0, 255 },   -- 金
    }
    local tierColor = tierColors[tier] or tierColors[0]

    table.insert(children, UI.Panel {
        flexDirection = "row", alignItems = "center", width = "100%", gap = 8,
        children = {
            UI.Panel {
                width = 36, height = 36, borderRadius = 18,
                backgroundColor = { tierColor[1], tierColor[2], tierColor[3], 60 },
                borderWidth = 1, borderColor = tierColor,
                justifyContent = "center", alignItems = "center",
                children = { UI.Label { text = info.icon, fontSize = 18 } },
            },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Panel { flexDirection = "row", alignItems = "center", gap = 6, children = {
                    UI.Label { text = "AEL 赞助", fontSize = 14, fontColor = C.text, fontWeight = "bold" },
                    UI.Label { text = info.name, fontSize = 12, fontColor = tierColor, fontWeight = "bold" },
                }},
                tier > 0
                    and UI.Label { text = "每日收入 +$" .. info.dailyIncome .. " | " .. info.bonus, fontSize = 11, fontColor = C.green }
                    or UI.Label { text = "达成条件即可签约赞助商", fontSize = 11, fontColor = C.textDim },
            }},
        },
    })

    -- ── 未签约：显示解锁条件 ──
    if tier == 0 then
        local t1 = AEL.TIERS[1]
        local rep = playerData_.reputation or 0
        local wins = playerData_.tournamentWins or 0
        local canUpgrade = AEL.CheckUpgrade() ~= nil

        local condRows = {
            { label = "声望 ≥ " .. t1.unlockRep, done = rep >= t1.unlockRep, cur = rep, max = t1.unlockRep },
            { label = "经营 ≥ " .. t1.unlockDay .. " 天", done = day >= t1.unlockDay, cur = day, max = t1.unlockDay },
        }
        if t1.unlockWins > 0 then
            table.insert(condRows, { label = "锦标赛冠军 ≥ " .. t1.unlockWins, done = wins >= t1.unlockWins, cur = wins, max = t1.unlockWins })
        end

        for _, cond in ipairs(condRows) do
            local pct = math.min(100, math.floor(cond.cur / math.max(1, cond.max) * 100))
            table.insert(children, UI.Panel {
                width = "100%", gap = 2, children = {
                    UI.Panel { flexDirection = "row", justifyContent = "space-between", width = "100%", children = {
                        UI.Label { text = (cond.done and "✅ " or "⬜ ") .. cond.label, fontSize = 11, fontColor = cond.done and C.green or C.textLight },
                        UI.Label { text = cond.cur .. "/" .. cond.max, fontSize = 11, fontColor = cond.done and C.green or C.textDim },
                    }},
                    UI.Panel { width = "100%", height = 4, backgroundColor = { 50, 50, 40, 180 }, borderRadius = 2, overflow = "hidden", children = {
                        UI.Panel { width = pct .. "%", height = "100%", borderRadius = 2,
                            backgroundColor = cond.done and C.green or { tierColors[1][1], tierColors[1][2], tierColors[1][3], 180 } },
                    }},
                },
            })
        end

        if canUpgrade then
            table.insert(children, UI.Button {
                text = "🥉 签约铜牌赞助",
                width = "100%", height = 36, fontSize = 13, borderRadius = PX.radius,
                variant = "primary",
                onClick = function()
                    playerData_.aelTier = 1
                    AddLog("🏆 恭喜签约 AEL 铜牌赞助！每日 +$" .. AEL.TIERS[1].dailyIncome)
                    PlaySFX("levelup")
                    BuildUI()
                end,
            })
        end
    else
        -- ── 已签约：周任务进度 ──
        if info.tasks and #info.tasks > 0 then
            table.insert(children, UI.Divider { spacing = 4 })
            table.insert(children, UI.Panel {
                flexDirection = "row", alignItems = "center", width = "100%", gap = 6, children = {
                    UI.Label { text = "📋 周任务", fontSize = 12, fontColor = C.textLight, fontWeight = "bold" },
                    UI.Label { text = info.tasksDone .. "/" .. info.tasksTotal, fontSize = 12, fontColor = info.tasksDone >= info.tasksTotal and C.green or C.gold },
                },
            })
            for _, task in ipairs(info.tasks) do
                table.insert(children, UI.Panel {
                    flexDirection = "row", alignItems = "center", width = "100%", gap = 6, paddingLeft = 4,
                    children = {
                        UI.Label { text = task.done and "✅" or "⬜", fontSize = 12 },
                        UI.Label { text = task.icon, fontSize = 12 },
                        UI.Label { text = task.desc, fontSize = 11, fontColor = task.done and C.green or C.textLight, flex = 1 },
                    },
                })
            end
        end

        -- ── 下一级解锁条件 ──
        local nextDef = info.nextTier
        if nextDef then
            table.insert(children, UI.Divider { spacing = 4 })
            local rep = playerData_.reputation or 0
            local wins = playerData_.tournamentWins or 0
            local canUp = AEL.CheckUpgrade() ~= nil

            table.insert(children, UI.Label {
                text = "⬆️ 下一级: " .. nextDef.name .. " (每日+$" .. nextDef.dailyIncome .. ")",
                fontSize = 11, fontColor = C.gold,
            })

            local conds = {
                { text = "声望≥" .. nextDef.unlockRep, done = rep >= nextDef.unlockRep },
                { text = "Day≥" .. nextDef.unlockDay, done = day >= nextDef.unlockDay },
            }
            if nextDef.unlockWins > 0 then
                table.insert(conds, { text = "冠军≥" .. nextDef.unlockWins, done = wins >= nextDef.unlockWins })
            end

            local condPills = {}
            for _, c in ipairs(conds) do
                table.insert(condPills, UI.Panel {
                    paddingHorizontal = 6, paddingVertical = 2, borderRadius = PX.radiusSm,
                    backgroundColor = c.done and { C.green[1], C.green[2], C.green[3], 40 } or { 60, 60, 50, 160 },
                    children = {
                        UI.Label { text = (c.done and "✓ " or "") .. c.text, fontSize = 10, fontColor = c.done and C.green or C.textDim },
                    },
                })
            end
            table.insert(children, UI.Panel {
                flexDirection = "row", flexWrap = "wrap", gap = 4, width = "100%",
                children = condPills,
            })

            if canUp then
                table.insert(children, UI.Button {
                    text = nextDef.icon .. " 升级 " .. nextDef.name,
                    width = "100%", height = 34, fontSize = 12, borderRadius = PX.radius,
                    variant = "primary",
                    onClick = function()
                        playerData_.aelTier = tier + 1
                        AddLog("🏆 赞助升级！" .. nextDef.name .. "！每日 +$" .. nextDef.dailyIncome)
                        PlaySFX("levelup")
                        BuildUI()
                    end,
                })
            end
        elseif tier >= 3 then
            table.insert(children, UI.Divider { spacing = 4 })
            table.insert(children, UI.Label {
                text = "👑 最高级赞助 · AEL 国际赛已解锁",
                fontSize = 12, fontColor = C.gold, fontWeight = "bold",
            })
        end
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = { tierColor[1], tierColor[2], tierColor[3], 100 },
        children = children,
    }
end


-- ============================================================================
-- 教练系统面板（嵌入升级 Tab）
-- ============================================================================

function BuildCoachPanel()
    local ok, Coach = pcall(require, "CoachSystem")
    if not ok or not Coach then return nil end

    local day = playerData_.day or 0
    -- D10 之前不展示
    if day < 8 then return nil end

    local hired = Coach.GetHiredCoach()
    local available = Coach.GetAvailableCoaches()
    -- 无教练可雇且未雇佣，不展示
    if not hired and #available == 0 then return nil end

    local children = {}

    -- ── 头部 ──
    table.insert(children, UI.Panel {
        flexDirection = "row", alignItems = "center", width = "100%", gap = 8,
        children = {
            UI.Panel {
                width = 32, height = 32, borderRadius = 16,
                backgroundColor = hired and { 80, 160, 100, 80 } or { 80, 80, 80, 80 },
                borderWidth = 1, borderColor = hired and C.green or C.border,
                justifyContent = "center", alignItems = "center",
                children = { UI.Label { text = hired and hired.icon or "🎓", fontSize = 16 } },
            },
            UI.Panel { flex = 1, gap = 2, children = {
                UI.Label { text = "教练组", fontSize = 14, fontColor = C.text, fontWeight = "bold" },
                hired
                    and UI.Label { text = hired.name .. " · " .. hired.title, fontSize = 11, fontColor = C.green }
                    or UI.Label { text = "暂无教练 · 雇佣可加速队员成长", fontSize = 11, fontColor = C.textDim },
            }},
        },
    })

    -- ── 已雇佣状态 ──
    if hired then
        local bonusText = ""
        local def = Coach.GetCoachDef(hired.id)
        if def then
            if def.specialBonus == "crit" then
                bonusText = "比赛暴击率+" .. math.floor((def.critChance or 0) * 100) .. "%"
            elseif def.specialBonus == "morale" then
                bonusText = "赛前心态+" .. (def.moraleBoost or 0)
            elseif def.specialBonus == "tactic" then
                bonusText = "战术胜率+" .. math.floor((def.tacticBonus or 0) * 100) .. "%"
            end
        end

        -- 效果 pills
        local effectPills = {}
        table.insert(effectPills, UI.Panel {
            paddingHorizontal = 6, paddingVertical = 2, borderRadius = PX.radiusSm,
            backgroundColor = { C.green[1], C.green[2], C.green[3], 40 },
            children = { UI.Label { text = "技能+" .. hired.skillBoost .. "/日", fontSize = 10, fontColor = C.green } },
        })
        if hired.moodEffect ~= 0 then
            local mColor = hired.moodEffect > 0 and C.green or { 255, 150, 80, 255 }
            local mSign = hired.moodEffect > 0 and "+" or ""
            table.insert(effectPills, UI.Panel {
                paddingHorizontal = 6, paddingVertical = 2, borderRadius = PX.radiusSm,
                backgroundColor = { mColor[1], mColor[2], mColor[3], 40 },
                children = { UI.Label { text = "心情" .. mSign .. hired.moodEffect .. "/日", fontSize = 10, fontColor = mColor } },
            })
        end
        if bonusText ~= "" then
            table.insert(effectPills, UI.Panel {
                paddingHorizontal = 6, paddingVertical = 2, borderRadius = PX.radiusSm,
                backgroundColor = { C.gold[1], C.gold[2], C.gold[3], 40 },
                children = { UI.Label { text = bonusText, fontSize = 10, fontColor = C.gold } },
            })
        end
        table.insert(effectPills, UI.Panel {
            paddingHorizontal = 6, paddingVertical = 2, borderRadius = PX.radiusSm,
            backgroundColor = { C.red[1], C.red[2], C.red[3], 30 },
            children = { UI.Label { text = "日薪$" .. hired.dailyCost, fontSize = 10, fontColor = { 255, 160, 120, 255 } } },
        })

        table.insert(children, UI.Panel {
            flexDirection = "row", flexWrap = "wrap", gap = 4, width = "100%",
            children = effectPills,
        })
        table.insert(children, UI.Label {
            text = "已合作 " .. hired.daysWith .. " 天",
            fontSize = 11, fontColor = C.textDim,
        })

        -- 解雇按钮
        table.insert(children, UI.Panel {
            flexDirection = "row", justifyContent = "flex-end", width = "100%", children = {
                UI.Button {
                    text = "👋 解约", height = 28, paddingHorizontal = 10,
                    fontSize = 11, borderRadius = PX.radius,
                    backgroundColor = { 80, 50, 50, 200 },
                    onClick = function()
                        Coach.Fire()
                        PlaySFX("click")
                        BuildUI()
                    end,
                },
            },
        })
    end

    -- ── 可雇佣教练列表 ──
    if #available > 0 and (not hired or #available > 1) then
        table.insert(children, UI.Divider { spacing = 4 })
        table.insert(children, UI.Label {
            text = hired and "更换教练" or "可雇佣教练",
            fontSize = 12, fontColor = C.textLight, fontWeight = "bold",
        })

        for _, coach in ipairs(available) do
            if not hired or coach.id ~= hired.id then
                local canAfford = (playerData_.money or 0) >= coach.dailyCost * 3 -- 至少能付3天
                local moodSign = coach.moodEffect >= 0 and "+" or ""
                table.insert(children, UI.Panel {
                    width = "100%", flexDirection = "row", alignItems = "center", gap = 8,
                    padding = 8, backgroundColor = { 50, 55, 45, 180 },
                    borderRadius = PX.radius, borderWidth = 1, borderColor = C.border,
                    children = {
                        UI.Label { text = coach.icon, fontSize = 20 },
                        UI.Panel { flex = 1, gap = 2, children = {
                            UI.Label { text = coach.name, fontSize = 12, fontColor = C.text, fontWeight = "bold" },
                            UI.Label { text = coach.title, fontSize = 10, fontColor = C.textDim },
                            UI.Label {
                                text = "技能+" .. coach.skillBoost .. " | 心情" .. moodSign .. coach.moodEffect .. " | $" .. coach.dailyCost .. "/日",
                                fontSize = 10, fontColor = C.textLight,
                            },
                        }},
                        UI.Button {
                            text = "雇佣", height = 28, paddingHorizontal = 8,
                            fontSize = 11, borderRadius = PX.radius,
                            disabled = not canAfford,
                            onClick = function()
                                local success, err = Coach.Hire(coach.id)
                                if success then
                                    PlaySFX("levelup")
                                else
                                    if AddLog then AddLog("❌ " .. (err or "雇佣失败")) end
                                end
                                BuildUI()
                            end,
                        },
                    },
                })
            end
        end
    end

    return UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = C.card, borderRadius = PX.cardRadius,
        borderWidth = PX.border, borderColor = hired and { 80, 160, 100, 80 } or C.border,
        children = children,
    }
end
