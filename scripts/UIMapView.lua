---@diagnostic disable: undefined-global
-- ============================================================================
-- UIMapView.lua — 非洲帝国版图可视化
-- 非洲大陆地图上亮起已征服的城市，展示玩家的扩张进度
-- ============================================================================

local UIMapView = {}

-- ============================================================================
-- 城市地理坐标（百分比定位，基于非洲大陆轮廓）
-- 参考真实非洲地理位置，转化为面板百分比坐标
-- ============================================================================
local CITY_POSITIONS = {
    wakandaville = { x = 0.45, y = 0.42, region = "西非内陆" },
    lagos        = { x = 0.38, y = 0.44, region = "尼日利亚" },
    nairobi      = { x = 0.68, y = 0.50, region = "肯尼亚" },
    accra        = { x = 0.32, y = 0.45, region = "加纳" },
    dakar        = { x = 0.18, y = 0.32, region = "塞内加尔" },
    capetown     = { x = 0.48, y = 0.88, region = "南非" },
    kinshasa     = { x = 0.50, y = 0.55, region = "刚果" },
}

-- 城市连线路线（按解锁顺序连接）
local ROUTE_LINES = {
    { "wakandaville", "lagos" },
    { "lagos", "nairobi" },
    { "nairobi", "accra" },
    { "accra", "dakar" },
    { "dakar", "capetown" },
    { "capetown", "kinshasa" },
}

-- 成就语
local CITY_ACHIEVEMENTS = {
    wakandaville = "一切梦想的起点",
    lagos        = "超级城市的征服者",
    nairobi      = "东非硅谷的新星",
    accra        = "文化之都的守护者",
    dakar        = "大西洋畔的贸易王",
    capetown     = "电竞之都的传奇",
    kinshasa     = "音乐之城的霸主",
}

-- ============================================================================
-- 构建地图面板
-- ============================================================================

--- 构建完整的帝国版图弹窗面板
---@return table UI.Panel
function UIMapView.Build()
    local C = _G.C or {}
    local PX = _G.PX or {}
    local UI = _G.UI

    local honor = (playerData_ and playerData_.prestigeHonor) or 0
    local currentCity = (playerData_ and playerData_.currentCity) or "wakandaville"
    local unlockedSet = {}
    for _, uid in ipairs((playerData_ and playerData_.unlockedCities) or { "wakandaville" }) do
        unlockedSet[uid] = true
    end

    -- ── 统计数据 ──
    local totalEarnings = (playerData_ and playerData_.totalEarnings) or 0
    local tournamentWins = (playerData_ and playerData_.tournamentWins) or 0
    local day = (playerData_ and playerData_.day) or 1
    local totalMembers = #(teamMembers_ or {})
    local unlockedList = (playerData_ and playerData_.unlockedCities) or { "wakandaville" }
    local conqueredCount = #unlockedList

    -- ── 标题栏 ──
    local header = UI.Panel {
        width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center",
        paddingBottom = 8,
        borderBottomWidth = 1, borderColor = { 80, 60, 30, 120 },
        children = {
            UI.Panel { flexDirection = "row", alignItems = "center", gap = 8, children = {
                UI.Label { text = "🌍", fontSize = 24 },
                UI.Panel { gap = 2, children = {
                    UI.Label { text = "Dragon Net 帝国版图", fontSize = 16, fontWeight = "bold", fontColor = C.gold or { 212, 175, 55, 255 } },
                    UI.Label { text = "商会名誉 " .. honor .. " | 征服 " .. conqueredCount .. "/7 城市", fontSize = 11, fontColor = C.textLight or { 180, 170, 160, 255 } },
                }},
            }},
            UI.Panel {
                paddingHorizontal = 12, paddingVertical = 6,
                backgroundColor = { 60, 50, 40, 200 },
                borderRadius = 8,
                onClick = function()
                    mapViewOpen_ = false
                    PlaySFX("click")
                    BuildUI()
                end,
                children = {
                    UI.Label { text = "✕ 关闭", fontSize = 13, fontColor = C.text or { 253, 245, 230, 255 } },
                },
            },
        },
    }

    -- ── 地图区域（非洲大陆剪影 + 城市点） ──
    local mapChildren = {}

    -- 背景装饰（非洲大陆剪影轮廓用深色面板模拟）
    table.insert(mapChildren, UI.Panel {
        position = "absolute", top = "5%", left = "10%", right = "10%", bottom = "5%",
        backgroundColor = { 35, 50, 30, 120 },
        borderRadius = 20,
        borderWidth = 1, borderColor = { 60, 80, 40, 100 },
    })

    -- 路线连线（简化为文字提示，因为 UI 系统无法绘制对角线）
    -- 用虚线节点表示路线
    for i, route in ipairs(ROUTE_LINES) do
        local fromPos = CITY_POSITIONS[route[1]]
        local toPos = CITY_POSITIONS[route[2]]
        if fromPos and toPos then
            local midX = (fromPos.x + toPos.x) / 2
            local midY = (fromPos.y + toPos.y) / 2
            local fromOpen = unlockedSet[route[1]]
            local toOpen = unlockedSet[route[2]]
            local routeColor = (fromOpen and toOpen)
                and { 100, 180, 80, 180 }
                or { 80, 70, 60, 80 }
            table.insert(mapChildren, UI.Panel {
                position = "absolute",
                top = string.format("%.0f%%", midY * 100),
                left = string.format("%.0f%%", midX * 100),
                width = 16, height = 3,
                backgroundColor = routeColor,
                borderRadius = 2,
            })
        end
    end

    -- 城市标记点
    local cities = PrestigeSystem and PrestigeSystem.CITIES or {}
    for _, city in ipairs(cities) do
        local pos = CITY_POSITIONS[city.id]
        if not pos then goto continue_city end

        local isHere = city.id == currentCity
        local isOpen = unlockedSet[city.id]
        local canOpen = honor >= city.prestigeReq
        local isLocked = not isOpen and not canOpen
        local isMystery = not isOpen and not canOpen and city.prestigeReq > honor * 2

        -- 视觉状态
        local dotSize = isHere and 36 or (isOpen and 28 or 22)
        local dotBg, dotBorder, dotEmoji, labelText, labelColor

        if isHere then
            -- 当前城市：金色脉冲
            local pulse = math.floor((gameTime_ or 0) * 2) % 2 == 0
            dotBg = pulse and { 212, 175, 55, 255 } or { 180, 140, 30, 230 }
            dotBorder = { 255, 220, 100, 255 }
            dotEmoji = city.emoji
            labelText = city.name .. " 📍"
            labelColor = C.gold or { 212, 175, 55, 255 }
        elseif isOpen then
            -- 已征服：绿色亮起
            dotBg = { 45, 120, 50, 220 }
            dotBorder = { 80, 200, 90, 255 }
            dotEmoji = city.emoji
            labelText = city.name
            labelColor = { 120, 220, 130, 255 }
        elseif isMystery then
            -- 未踏足：暗影轮廓
            dotBg = { 30, 25, 20, 150 }
            dotBorder = { 60, 50, 40, 120 }
            dotEmoji = "❓"
            labelText = "???"
            labelColor = { 80, 70, 60, 180 }
        else
            -- 未解锁但可见
            dotBg = { 50, 45, 40, 180 }
            dotBorder = { 100, 90, 70, 150 }
            dotEmoji = "🔒"
            labelText = city.name
            labelColor = { 140, 130, 120, 200 }
        end

        -- 城市节点
        local cityNode = UI.Panel {
            position = "absolute",
            top = string.format("%.0f%%", pos.y * 100 - 3),
            left = string.format("%.0f%%", pos.x * 100 - 3),
            width = dotSize, height = dotSize,
            borderRadius = dotSize / 2,
            backgroundColor = dotBg,
            borderWidth = isHere and 3 or 2,
            borderColor = dotBorder,
            justifyContent = "center", alignItems = "center",
            children = {
                UI.Label { text = dotEmoji, fontSize = isHere and 16 or 13 },
            },
        }
        table.insert(mapChildren, cityNode)

        -- 城市名标签（节点下方）
        local cityLabel = UI.Panel {
            position = "absolute",
            top = string.format("%.0f%%", pos.y * 100 + 5),
            left = string.format("%.0f%%", pos.x * 100 - 8),
            width = 70,
            alignItems = "center",
            children = {
                UI.Label {
                    text = labelText, fontSize = 10, fontWeight = isHere and "bold" or "normal",
                    fontColor = labelColor, textAlign = "center",
                },
                -- 成就/解锁条件
                isOpen and UI.Label {
                    text = CITY_ACHIEVEMENTS[city.id] or "",
                    fontSize = 8, fontColor = { 150, 200, 150, 180 }, textAlign = "center",
                } or (not isMystery and UI.Label {
                    text = "🔒 名誉 " .. city.prestigeReq,
                    fontSize = 8, fontColor = { 120, 110, 100, 160 }, textAlign = "center",
                } or nil),
            },
        }
        table.insert(mapChildren, cityLabel)

        ::continue_city::
    end

    local mapPanel = UI.Panel {
        width = "100%", height = 280,
        backgroundColor = { 20, 30, 15, 200 },
        borderRadius = 12,
        borderWidth = 1, borderColor = { 60, 80, 40, 120 },
        overflow = "hidden",
        children = mapChildren,
    }

    -- ── 底部统计栏 ──
    local fmtMoney = FormatMoney or FormatNumber
    local stats = {
        { icon = "💰", label = "总营收", value = "$" .. fmtMoney(totalEarnings) },
        { icon = "🏆", label = "总胜场", value = tostring(tournamentWins) },
        { icon = "👥", label = "培养选手", value = tostring(totalMembers) },
        { icon = "📅", label = "经营天数", value = tostring(day) },
    }
    local statItems = {}
    for _, s in ipairs(stats) do
        table.insert(statItems, UI.Panel {
            flex = 1, alignItems = "center", gap = 2, children = {
                UI.Label { text = s.icon, fontSize = 18 },
                UI.Label { text = s.value, fontSize = 14, fontWeight = "bold", fontColor = C.text or { 253, 245, 230, 255 } },
                UI.Label { text = s.label, fontSize = 9, fontColor = C.textDim or { 140, 130, 120, 200 } },
            },
        })
    end

    local statsBar = UI.Panel {
        width = "100%", flexDirection = "row",
        paddingVertical = 10, paddingHorizontal = 8,
        backgroundColor = { 30, 25, 20, 200 },
        borderRadius = 10,
        borderWidth = 1, borderColor = { 60, 50, 40, 120 },
        children = statItems,
    }

    -- ── 城市详情列表（当前城市高亮） ──
    local cityList = {}
    for _, city in ipairs(cities) do
        local isHere = city.id == currentCity
        local isOpen = unlockedSet[city.id]
        if not isOpen and honor < city.prestigeReq * 0.5 then goto skip_detail end

        local detailBg = isHere and { 50, 40, 20, 200 } or { 35, 30, 25, 150 }
        local detailBorder = isHere and (C.gold or { 212, 175, 55, 255 }) or { 60, 50, 40, 100 }

        table.insert(cityList, UI.Panel {
            width = "100%", flexDirection = "row", padding = 8, gap = 8, alignItems = "center",
            backgroundColor = detailBg,
            borderRadius = 8,
            borderWidth = isHere and 2 or 1, borderColor = detailBorder,
            children = {
                UI.Label { text = isOpen and city.emoji or "🔒", fontSize = 20 },
                UI.Panel { flex = 1, gap = 2, children = {
                    UI.Panel { flexDirection = "row", gap = 6, alignItems = "center", children = {
                        UI.Label { text = city.name, fontSize = 13, fontWeight = "bold",
                            fontColor = isOpen and (C.text or { 253, 245, 230, 255 }) or { 120, 110, 100, 200 } },
                        isHere and UI.Label { text = "📍 当前", fontSize = 9, fontWeight = "bold",
                            fontColor = C.gold or { 212, 175, 55, 255 } } or nil,
                    }},
                    UI.Label { text = isOpen and (CITY_ACHIEVEMENTS[city.id] or city.desc)
                        or ("需要商会名誉 " .. city.prestigeReq),
                        fontSize = 10, fontColor = { 140, 130, 120, 200 }, whiteSpace = "normal" },
                    city.specialBonus and UI.Label {
                        text = "✨ " .. city.specialBonus, fontSize = 10,
                        fontColor = isOpen and { 100, 200, 120, 255 } or { 100, 90, 80, 150 },
                    } or nil,
                }},
                UI.Panel { alignItems = "flex-end", children = {
                    UI.Label {
                        text = isOpen and string.format("%.1fx", city.incomeMulti) or "🔒",
                        fontSize = isOpen and 16 or 14,
                        fontColor = isOpen and { 100, 220, 120, 255 } or { 100, 90, 80, 150 },
                        fontWeight = "bold",
                    },
                    isOpen and UI.Label { text = "收入倍率", fontSize = 8, fontColor = { 120, 110, 100, 150 } } or nil,
                }},
            },
        })
        ::skip_detail::
    end

    -- ── 组装最终面板 ──
    local contentChildren = {
        header,
        mapPanel,
        statsBar,
        UI.Label { text = "📋 城市档案", fontSize = 14, fontWeight = "bold",
            fontColor = C.textLight or { 180, 170, 160, 255 }, marginTop = 4 },
    }
    for _, item in ipairs(cityList) do
        table.insert(contentChildren, item)
    end

    local content = UI.Panel {
        width = "100%", gap = 10, padding = 12,
        children = contentChildren,
    }

    return content
end

--- 格式化数字（带千分位）
function FormatNumber(n)
    if not n or n == 0 then return "0" end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

return UIMapView
