-- ============================================================================
-- UICafeCustomize.lua — 网吧装修编辑界面
-- 入口："🎨 装修"按钮 → 全屏编辑面板
-- ============================================================================
---@diagnostic disable: undefined-global

local UI = require("urhox-libs/UI")
local CafeCustomize = require("CafeCustomize")

-- ── 预览用迷你网吧渲染（纯色块示意） ──
local function MiniPreviewCard(wpColors, ltOverlay, flColors)
    -- 用色块组合模拟装修效果的预览卡
    local wallC = wpColors.wallColor
    local innerC = wpColors.innerColor
    local floorC = flColors.color

    return UI.Panel {
        width = "100%", height = 80, marginBottom = 8,
        borderRadius = PX.radius, borderWidth = PX.border,
        borderColor = C.border, backgroundColor = C.card,
        overflow = "hidden",
        children = {
            -- 墙壁色块
            UI.Panel {
                width = "100%", height = 50,
                backgroundColor = { wallC[1], wallC[2], wallC[3], 255 },
                children = {
                    -- 内墙
                    UI.Panel {
                        position = "absolute", left = 8, top = 4, right = 8, bottom = 4,
                        backgroundColor = { innerC[1], innerC[2], innerC[3], 255 },
                        borderRadius = 2,
                        children = {
                            -- 灯光色调叠加
                            UI.Panel {
                                width = "100%", height = "100%",
                                position = "absolute", left = 0, top = 0,
                                backgroundColor = { ltOverlay.overlay[1], ltOverlay.overlay[2], ltOverlay.overlay[3], ltOverlay.alpha * 3 },
                                borderRadius = 2,
                            },
                            -- 涂鸦标记
                            wpColors.hasGraffiti and UI.Label {
                                text = "🎨", fontSize = 16,
                                position = "absolute", left = 10, top = 6,
                            } or nil,
                            wpColors.hasPattern and UI.Label {
                                text = "✦", fontSize = 14, fontColor = C.gold,
                                position = "absolute", left = 12, top = 8,
                            } or nil,
                        },
                    },
                },
            },
            -- 地板色块
            UI.Panel {
                width = "100%", height = 30,
                backgroundColor = { floorC[1], floorC[2], floorC[3], 255 },
                children = {
                    -- 地板线
                    UI.Panel {
                        width = "100%", height = 1,
                        position = "absolute", top = 10, left = 0,
                        backgroundColor = { flColors.lineColor[1], flColors.lineColor[2], flColors.lineColor[3], 180 },
                    },
                    UI.Panel {
                        width = "100%", height = 1,
                        position = "absolute", top = 20, left = 0,
                        backgroundColor = { flColors.lineColor[1], flColors.lineColor[2], flColors.lineColor[3], 180 },
                    },
                },
            },
        },
    }
end

-- ── 选项卡按钮 ──
local function TabBtn(text, isActive, onTap)
    return UI.Button {
        text = text, fontSize = 13,
        paddingLeft = 12, paddingRight = 12, paddingTop = 6, paddingBottom = 6,
        backgroundColor = isActive and C.accent or C.card,
        fontColor = isActive and C.text or C.textDim,
        borderRadius = PX.radius,
        borderWidth = isActive and 0 or PX.borderSm,
        borderColor = C.border,
        marginRight = 6,
        onClick = onTap,
    }
end

-- ── 单个选项卡片 ──
local function OptionCard(item, isSelected, isLocked, onSelect)
    local bg = isSelected and C.accentLight or C.card
    local borderCol = isSelected and C.accent or C.border
    local textCol = isLocked and C.textLight or C.text

    return UI.Button {
        width = "100%", paddingTop = 10, paddingBottom = 10,
        paddingLeft = 12, paddingRight = 12, marginBottom = 6,
        backgroundColor = bg, borderRadius = PX.radius,
        borderWidth = isSelected and 2 or PX.borderSm, borderColor = borderCol,
        flexDirection = "row", alignItems = "center",
        disabled = isLocked,
        onClick = function() if not isLocked and onSelect then onSelect() end end,
        children = {
            -- 图标/选中标记
            UI.Label {
                text = isSelected and "✓" or (item.icon or "▪"),
                fontSize = 16, fontColor = isSelected and C.green or C.textDim,
                marginRight = 10, width = 24, textAlign = "center",
            },
            -- 名字 + 描述
            UI.Panel {
                flex = 1,
                children = {
                    UI.Label {
                        text = isLocked and (item.name .. " 🔒") or item.name,
                        fontSize = 14, fontColor = textCol,
                    },
                    UI.Label {
                        text = isLocked and (item.lockHint or "未解锁") or (item.desc or ""),
                        fontSize = 11, fontColor = C.textLight, marginTop = 2,
                    },
                },
            },
        },
    }
end

-- ── 装修主面板构建 ──
---@type string
local currentTab = "wallpaper"  -- "wallpaper" | "lighting" | "floor"

--- 构建装修编辑全屏面板
---@param onClose function 关闭回调
---@return table UI.Panel
function BuildCafeCustomizePanel(onClose)
    local current = CafeCustomize.GetCurrent()

    -- 获取各项数据
    local wallpapers = CafeCustomize.WALLPAPERS
    local lightings  = CafeCustomize.LIGHTINGS
    local floors     = CafeCustomize.FLOORS
    local unlockedWP = CafeCustomize.GetUnlockedWallpapers()
    local unlockedLT = CafeCustomize.GetUnlockedLightings()
    local unlockedFL = CafeCustomize.GetUnlockedFloors()

    -- 判断是否解锁
    local function isWPUnlocked(id)
        for _, wp in ipairs(unlockedWP) do if wp.id == id then return true end end
        return false
    end
    local function isLTUnlocked(id)
        for _, lt in ipairs(unlockedLT) do if lt.id == id then return true end end
        return false
    end
    local function isFLUnlocked(id)
        for _, fl in ipairs(unlockedFL) do if fl.id == id then return true end end
        return false
    end

    -- 获取锁定提示
    local function getWPLockHint(wp)
        local PrestigeSystem = require("PrestigeSystem")
        for _, city in ipairs(PrestigeSystem.CITIES) do
            if city.id == wp.cityId then
                return "到达" .. city.name .. "解锁（需" .. city.prestigeReq .. "声望）"
            end
        end
        return "未解锁"
    end

    -- 当前预览数据
    local wpColors = CafeCustomize.GetWallpaperColors()
    local ltOverlay = CafeCustomize.GetLightingOverlay()
    local flColors = CafeCustomize.GetFloorColors()

    -- ── 选项列表内容 ──
    local optionsList = {}

    if currentTab == "wallpaper" then
        for _, wp in ipairs(wallpapers) do
            local unlocked = isWPUnlocked(wp.id)
            local selected = current.wallpaper == wp.id
            local item = { name = wp.name, desc = wp.desc, icon = "🧱", lockHint = getWPLockHint(wp) }
            table.insert(optionsList, OptionCard(item, selected, not unlocked, function()
                CafeCustomize.Set("wallpaper", wp.id)
                if RefreshManageUI then RefreshManageUI() end
                if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
            end))
        end
    elseif currentTab == "lighting" then
        for _, lt in ipairs(lightings) do
            local unlocked = isLTUnlocked(lt.id)
            local selected = current.lighting == lt.id
            local item = { name = lt.name, desc = lt.desc, icon = lt.icon,
                           lockHint = "装饰等级达到Lv" .. lt.unlockDecoLevel .. "解锁" }
            table.insert(optionsList, OptionCard(item, selected, not unlocked, function()
                CafeCustomize.Set("lighting", lt.id)
                if RefreshManageUI then RefreshManageUI() end
                if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
            end))
        end
    elseif currentTab == "floor" then
        for _, fl in ipairs(floors) do
            local unlocked = isFLUnlocked(fl.id)
            local selected = current.floor == fl.id
            local item = { name = fl.name, desc = fl.desc, icon = fl.icon,
                           lockHint = "装饰等级达到Lv" .. fl.unlockDecoLevel .. "解锁" }
            table.insert(optionsList, OptionCard(item, selected, not unlocked, function()
                CafeCustomize.Set("floor", fl.id)
                if RefreshManageUI then RefreshManageUI() end
                if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
            end))
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bg, padding = 12,
        children = {
            -- 顶部标题栏
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                marginBottom = 10,
                children = {
                    UI.Label { text = "🎨 网吧装修", fontSize = 18, fontColor = C.text, flex = 1 },
                    UI.Button {
                        text = "✕ 关闭", fontSize = 13,
                        paddingLeft = 10, paddingRight = 10, paddingTop = 5, paddingBottom = 5,
                        backgroundColor = C.card, fontColor = C.textDim,
                        borderRadius = PX.radius, borderWidth = PX.borderSm, borderColor = C.border,
                        onClick = onClose,
                    },
                },
            },
            -- 实时预览
            MiniPreviewCard(wpColors, ltOverlay, flColors),
            -- Tab 切换
            UI.Panel {
                width = "100%", flexDirection = "row", marginBottom = 10,
                children = {
                    TabBtn("🧱 壁纸", currentTab == "wallpaper", function()
                        currentTab = "wallpaper"
                        if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
                    end),
                    TabBtn("💡 灯光", currentTab == "lighting", function()
                        currentTab = "lighting"
                        if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
                    end),
                    TabBtn("🪵 地板", currentTab == "floor", function()
                        currentTab = "floor"
                        if onClose then onClose(); BuildCafeCustomizeOverlay(onClose) end
                    end),
                },
            },
            -- 选项列表（可滚动）
            UI.ScrollView {
                width = "100%", flex = 1,
                children = optionsList,
            },
        },
    }
end

--- 显示装修编辑覆盖层（使用全局 overlayRoot_）
---@param closeCallback function|nil 额外关闭回调
function BuildCafeCustomizeOverlay(closeCallback)
    if not overlayRoot_ then return end
    overlayRoot_:RemoveAllChildren()
    local panel = BuildCafeCustomizePanel(function()
        overlayRoot_:RemoveAllChildren()
        if closeCallback then closeCallback() end
    end)
    overlayRoot_:AddChild(panel)
end

--- 构建"装修"入口按钮（嵌入经营界面）
---@return table UI.Button
function BuildCafeCustomizeButton()
    -- 章节2后显示装修按钮
    local show = (currentChapter_ or 1) >= 2 or (playerData_ and (playerData_.decoLevel or 0) >= 1)
    if not show then return UI.Panel { height = 0 } end

    return UI.Button {
        text = "🎨 装修", fontSize = 13,
        paddingLeft = 10, paddingRight = 10, paddingTop = 6, paddingBottom = 6,
        backgroundColor = C.card, fontColor = C.accent,
        borderRadius = PX.radius, borderWidth = PX.borderSm, borderColor = C.accent,
        marginLeft = 6,
        onClick = function()
            BuildCafeCustomizeOverlay()
        end,
    }
end
