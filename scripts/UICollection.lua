---@diagnostic disable: undefined-global
-- ============================================================================
-- UICollection.lua — 图鉴系统 UI 页面
-- 展示收集进度、分类浏览、阶段奖励、被动加成
-- ============================================================================
local Collection = require("Collection")

-- 当前选中的分类 tab
collectionTab_ = collectionTab_ or "characters"
-- 筛选状态: "all" | "unlocked" | "locked"
---@diagnostic disable-next-line: global-element
collectionFilter_ = collectionFilter_ or "all"

--- 构建图鉴页面（作为 Manage 界面的弹窗）
function BuildCollectionPage()
    local children = {}

    -- ══════════════ 顶部：总进度 ══════════════
    local unlocked, total = Collection.GetProgress()
    local pct = unlocked / math.max(1, total)
    local pctStr = math.floor(pct * 100) .. "%"

    table.insert(children, UI.Panel {
        width = "100%", padding = 10, gap = 6,
        backgroundColor = { 36, 28, 20, 240 },
        borderRadius = PX.cardRadius, borderWidth = PX.border, borderColor = C.border,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between", alignItems = "center",
                children = {
                    UI.Label { text = "📚 图鉴收集", fontSize = 17, fontColor = C.accent, fontWeight = "bold" },
                    UI.Label { text = unlocked .. "/" .. total .. " (" .. pctStr .. ")", fontSize = 13, fontColor = C.gold },
                },
            },
            -- 进度条
            UI.Panel {
                width = "100%", height = 8, borderRadius = 4,
                backgroundColor = { 30, 24, 18, 255 },
                children = {
                    UI.Panel {
                        width = pctStr, height = "100%", borderRadius = 4,
                        backgroundColor = pct >= 1.0 and C.gold or C.green,
                    },
                },
            },
            -- 被动加成提示
            BuildPassiveBonusLine(),
        },
    })

    -- ══════════════ 分类 Tab 栏 ══════════════
    local tabChildren = {}
    for _, cat in ipairs(Collection.CATEGORIES) do
        local isActive = (collectionTab_ == cat.id)
        local catUnlocked = Collection.CountUnlockedByCategory(cat.id)
        local catTotal = Collection.CountByCategory(cat.id)
        table.insert(tabChildren, UI.Button {
            text = cat.icon .. " " .. catUnlocked .. "/" .. catTotal,
            fontSize = 11, height = 30, flex = 1,
            fontWeight = isActive and "bold" or "normal",
            backgroundColor = isActive and { 26, 18, 10, 255 } or { 40, 32, 22, 200 },
            fontColor = isActive and C.gold or C.textDim,
            borderRadius = PX.cardRadius, borderWidth = PX.border,
            borderColor = isActive and { 190, 148, 50, 240 } or { 60, 50, 38, 200 },
            onClick = function()
                collectionTab_ = cat.id
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    table.insert(children, UI.Panel {
        width = "100%", flexDirection = "row", gap = 3, paddingVertical = 6, flexWrap = "wrap",
        children = tabChildren,
    })

    -- ══════════════ 当前分类标题 ══════════════
    local currentCat = nil
    for _, cat in ipairs(Collection.CATEGORIES) do
        if cat.id == collectionTab_ then currentCat = cat; break end
    end
    if currentCat then
        table.insert(children, UI.Panel {
            width = "100%", paddingVertical = 4,
            children = {
                UI.Label {
                    text = currentCat.icon .. " " .. currentCat.name .. " — " .. currentCat.desc,
                    fontSize = 12, fontColor = C.textDim,
                },
            },
        })
    end

    -- ══════════════ 筛选切换栏 ══════════════
    local filterOptions = {
        { id = "all", label = "全部" },
        { id = "unlocked", label = "已解锁" },
        { id = "locked", label = "未解锁" },
    }
    local filterBtns = {}
    for _, f in ipairs(filterOptions) do
        local isActive = (collectionFilter_ == f.id)
        table.insert(filterBtns, UI.Button {
            text = f.label, fontSize = 11, height = 26,
            paddingHorizontal = 12,
            fontWeight = isActive and "bold" or "normal",
            backgroundColor = isActive and { 50, 40, 25, 255 } or { 30, 24, 18, 180 },
            fontColor = isActive and C.gold or C.textDim,
            borderRadius = 13, borderWidth = 1,
            borderColor = isActive and C.gold or { 60, 50, 38, 150 },
            onClick = function()
                collectionFilter_ = f.id
                PlaySFX("click")
                BuildUI()
            end,
        })
    end
    table.insert(children, UI.Panel {
        width = "100%", flexDirection = "row", gap = 6, paddingVertical = 4,
        children = filterBtns,
    })

    -- ══════════════ 条目卡片列表 ══════════════
    local col = playerData_.collection or {}
    local itemCards = {}
    for _, item in ipairs(Collection.ITEMS) do
        if item.category == collectionTab_ then
            local isUnlocked = col[item.id] ~= nil
            -- 筛选逻辑
            local show = (collectionFilter_ == "all")
                or (collectionFilter_ == "unlocked" and isUnlocked)
                or (collectionFilter_ == "locked" and not isUnlocked)
            if show then
                table.insert(itemCards, BuildCollectionItemCard(item, isUnlocked, col[item.id]))
            end
        end
    end
    if #itemCards == 0 then
        table.insert(itemCards, UI.Label {
            text = collectionFilter_ == "unlocked" and "暂无已解锁条目" or "全部已解锁！",
            fontSize = 12, fontColor = C.textDim, marginTop = 12, textAlign = "center",
        })
    end
    table.insert(children, UI.Panel {
        width = "100%", gap = 4,
        children = itemCards,
    })

    -- ══════════════ 阶段奖励区域 ══════════════
    table.insert(children, BuildTierRewardsSection())

    return UI.Panel {
        width = "100%", gap = 6,
        children = children,
    }
end

--- 构建单个图鉴条目卡片
function BuildCollectionItemCard(item, isUnlocked, unlockDay)
    local starStr = string.rep("★", item.stars or 1)
    local starColor = item.stars >= 3 and C.gold or (item.stars >= 2 and C.accent or C.textDim)

    if isUnlocked then
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            padding = 8, gap = 8,
            backgroundColor = C.card, borderRadius = PX.cardRadius,
            borderWidth = PX.borderSm, borderColor = C.border,
            children = {
                -- 图标
                UI.Label { text = item.icon, fontSize = 20 },
                -- 名称和描述
                UI.Panel {
                    flex = 1, flexShrink = 1, gap = 2,
                    children = {
                        UI.Panel {
                            flexDirection = "row", gap = 6, alignItems = "center", flexWrap = "wrap",
                            children = {
                                UI.Label { text = item.name, fontSize = 13, fontColor = C.text, fontWeight = "bold" },
                                UI.Label { text = starStr, fontSize = 11, fontColor = starColor },
                            },
                        },
                        UI.Label { text = item.desc, fontSize = 11, fontColor = C.textDim },
                    },
                },
                -- 解锁天数
                UI.Label { text = "Day " .. (unlockDay or "?"), fontSize = 10, fontColor = C.textLight },
            },
        }
    else
        -- 未解锁：灰色遮罩
        return UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            padding = 8, gap = 8,
            backgroundColor = { 40, 32, 26, 180 }, borderRadius = PX.cardRadius,
            borderWidth = PX.borderSm, borderColor = { 60, 50, 40, 150 },
            children = {
                UI.Label { text = "❓", fontSize = 20 },
                UI.Panel {
                    flex = 1, flexShrink = 1, gap = 2,
                    children = {
                        UI.Panel {
                            flexDirection = "row", gap = 6, alignItems = "center",
                            children = {
                                UI.Label { text = "???", fontSize = 13, fontColor = C.textLight },
                                UI.Label { text = starStr, fontSize = 11, fontColor = { 100, 80, 60, 180 } },
                            },
                        },
                        UI.Label { text = "尚未解锁", fontSize = 11, fontColor = C.textLight },
                    },
                },
            },
        }
    end
end

--- 构建被动加成提示行
function BuildPassiveBonusLine()
    local pct = Collection.GetTotalPercent()
    local activeBonus = nil
    for i = #Collection.PASSIVE_BONUSES, 1, -1 do
        if pct >= Collection.PASSIVE_BONUSES[i].pct then
            activeBonus = Collection.PASSIVE_BONUSES[i]
            break
        end
    end
    -- 下一个未达到的加成
    local nextBonus = nil
    for _, b in ipairs(Collection.PASSIVE_BONUSES) do
        if pct < b.pct then nextBonus = b; break end
    end

    local texts = {}
    if activeBonus then
        table.insert(texts, UI.Label {
            text = "当前加成: " .. activeBonus.desc,
            fontSize = 11, fontColor = C.green,
        })
    end
    if nextBonus then
        local needed = math.ceil(nextBonus.pct * #Collection.ITEMS)
        local unlocked = select(1, Collection.GetProgress())
        table.insert(texts, UI.Label {
            text = "下一加成: " .. nextBonus.desc .. " (还需" .. math.max(0, needed - unlocked) .. "条)",
            fontSize = 10, fontColor = C.textLight,
        })
    end

    if #texts == 0 then
        return UI.Label { text = "收集更多图鉴解锁被动加成", fontSize = 10, fontColor = C.textLight }
    end
    return UI.Panel { width = "100%", gap = 2, children = texts }
end

--- 构建阶段奖励区域
function BuildTierRewardsSection()
    local tiers = playerData_.collectionTiers or {}
    local tierCards = {}

    -- 当前分类的阶段进度
    local catTotal = Collection.CountByCategory(collectionTab_)
    local catUnlocked = Collection.CountUnlockedByCategory(collectionTab_)
    local catPct = catUnlocked / math.max(1, catTotal)

    for _, tier in ipairs(Collection.TIER_REWARDS) do
        local tierId = collectionTab_ .. "_" .. tostring(math.floor(tier.pct * 100))
        local claimed = tiers[tierId] ~= nil
        local reachable = catPct >= tier.pct

        local bg = claimed and { 45, 75, 48, 200 } or (reachable and { 80, 60, 20, 200 } or { 40, 32, 26, 160 })
        local borderClr = claimed and C.green or (reachable and C.gold or { 60, 50, 40, 150 })
        local statusText = claimed and "已领取" or (reachable and "可领取" or math.floor(tier.pct * 100) .. "%")
        local statusColor = claimed and C.green or (reachable and C.gold or C.textLight)

        table.insert(tierCards, UI.Panel {
            width = "100%", flexDirection = "row", alignItems = "center",
            padding = 6, gap = 8,
            backgroundColor = bg, borderRadius = PX.cardRadius,
            borderWidth = PX.borderSm, borderColor = borderClr,
            children = {
                UI.Label { text = tier.title, fontSize = 12, fontColor = C.text, fontWeight = "bold", width = 60 },
                UI.Panel {
                    flex = 1, flexShrink = 1, gap = 1,
                    children = {
                        UI.Label {
                            text = (tier.reward.money and "$" .. tier.reward.money or "") ..
                                   (tier.reward.rep and " +" .. tier.reward.rep .. "声望" or ""),
                            fontSize = 11, fontColor = C.moneyGreen,
                        },
                        UI.Label { text = tier.unique or "", fontSize = 10, fontColor = C.gold },
                    },
                },
                UI.Label { text = statusText, fontSize = 11, fontColor = statusColor, fontWeight = "bold" },
            },
        })
    end

    return UI.Panel {
        width = "100%", gap = 4, paddingTop = 8,
        children = {
            UI.Label { text = "🏆 阶段奖励", fontSize = 14, fontColor = C.accent, fontWeight = "bold" },
            table.unpack(tierCards),
        },
    }
end

return {
    BuildCollectionPage = BuildCollectionPage,
}
