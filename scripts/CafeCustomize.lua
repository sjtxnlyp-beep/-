-- ============================================================================
-- CafeCustomize.lua — 网吧装修系统 Phase1（壁纸/灯光/地板）
-- 数据定义 + 解锁逻辑 + 渲染辅助
-- ============================================================================

local CafeCustomize = {}

-- ── 壁纸定义（6种，每个城市解锁1种） ──
CafeCustomize.WALLPAPERS = {
    { id = "default",   name = "原始红砖墙",   cityId = "wakandaville",
      desc = "斑驳的红砖墙，诉说着创业的艰辛",
      wallColor = { 180, 130, 80 },  -- 与 CafeRenderer 原色一致
      innerColor = { 245, 235, 215 },
    },
    { id = "lagos",     name = "霓虹涂鸦墙",   cityId = "lagos",
      desc = "拉各斯街头艺术家的杰作，满墙荧光涂鸦",
      wallColor = { 60, 50, 80 },
      innerColor = { 30, 25, 50 },
      hasGraffiti = true,
    },
    { id = "nairobi",   name = "大草原壁画",   cityId = "nairobi",
      desc = "内罗毕画师手绘的非洲草原日落壁画",
      wallColor = { 210, 160, 80 },
      innerColor = { 240, 210, 150 },
    },
    { id = "accra",     name = "金星图腾墙",   cityId = "accra",
      desc = "加纳阿散蒂王国的传统黄金图腾纹饰",
      wallColor = { 180, 150, 50 },
      innerColor = { 250, 240, 200 },
      hasPattern = true,
    },
    { id = "dakar",     name = "达喀尔挂毯墙", cityId = "dakar",
      desc = "塞内加尔手工编织挂毯，温暖而华丽",
      wallColor = { 160, 80, 60 },
      innerColor = { 220, 180, 150 },
    },
    { id = "capetown",  name = "现代极简白",   cityId = "capetown",
      desc = "开普敦科技园风格，干净利落的白墙",
      wallColor = { 230, 235, 240 },
      innerColor = { 250, 252, 255 },
    },
}

-- ── 灯光色调定义（3种） ──
CafeCustomize.LIGHTINGS = {
    { id = "warm",  name = "暖黄灯光",   icon = "🔆",
      desc = "经典网吧暖光，温馨舒适",
      overlay = { 255, 200, 100 },  -- RGBA叠加色
      alpha = 25,                    -- 叠加透明度
      unlockDecoLevel = 0,           -- 默认可用
    },
    { id = "cool",  name = "冷白灯光",   icon = "💡",
      desc = "现代LED冷光，清醒高效",
      overlay = { 180, 210, 255 },
      alpha = 20,
      unlockDecoLevel = 2,
    },
    { id = "neon",  name = "霓虹紫光",   icon = "🟣",
      desc = "电竞风紫色氛围灯，赛博朋克",
      overlay = { 180, 80, 255 },
      alpha = 35,
      unlockDecoLevel = 3,
    },
}

-- ── 地板定义（2种） ──
CafeCustomize.FLOORS = {
    { id = "cement", name = "水泥地",    icon = "🪨",
      desc = "朴素的水泥地面，便宜实用",
      color = { 180, 175, 165 },
      lineColor = { 160, 155, 145 },
      unlockDecoLevel = 0,
    },
    { id = "wood",   name = "木地板",    icon = "🪵",
      desc = "温暖的木质地板，档次提升",
      color = { 210, 185, 140 },
      lineColor = { 185, 160, 120 },
      unlockDecoLevel = 3,
    },
}

-- ── 解锁检查 ──

--- 获取已解锁的壁纸列表
---@return table[] 已解锁的壁纸数据数组
function CafeCustomize.GetUnlockedWallpapers()
    local unlocked = {}
    local pd = playerData_
    if not pd then return unlocked end
    -- 默认壁纸始终解锁
    for _, wp in ipairs(CafeCustomize.WALLPAPERS) do
        if wp.id == "default" then
            table.insert(unlocked, wp)
        else
            -- 检查是否到达过对应城市
            local reached = false
            if pd.currentCity == wp.cityId then
                reached = true
            else
                -- 检查声望是否足够到达该城市
                local PrestigeSystem = require("PrestigeSystem")
                for _, city in ipairs(PrestigeSystem.CITIES) do
                    if city.id == wp.cityId then
                        if (pd.reputation or 0) >= city.prestigeReq then
                            reached = true
                        end
                        break
                    end
                end
            end
            if reached then
                table.insert(unlocked, wp)
            end
        end
    end
    return unlocked
end

--- 获取已解锁的灯光列表
---@return table[] 已解锁的灯光数据数组
function CafeCustomize.GetUnlockedLightings()
    local unlocked = {}
    local decoLevel = playerData_ and playerData_.decoLevel or 0
    for _, lt in ipairs(CafeCustomize.LIGHTINGS) do
        if decoLevel >= lt.unlockDecoLevel then
            table.insert(unlocked, lt)
        end
    end
    return unlocked
end

--- 获取已解锁的地板列表
---@return table[] 已解锁的地板数据数组
function CafeCustomize.GetUnlockedFloors()
    local unlocked = {}
    local decoLevel = playerData_ and playerData_.decoLevel or 0
    for _, fl in ipairs(CafeCustomize.FLOORS) do
        if decoLevel >= fl.unlockDecoLevel then
            table.insert(unlocked, fl)
        end
    end
    return unlocked
end

--- 获取当前选择
---@return table { wallpaper=string, lighting=string, floor=string }
function CafeCustomize.GetCurrent()
    local cc = playerData_ and playerData_.cafeCustom
    if not cc then
        return { wallpaper = "default", lighting = "warm", floor = "cement" }
    end
    return {
        wallpaper = cc.wallpaper or "default",
        lighting  = cc.lighting or "warm",
        floor     = cc.floor or "cement",
    }
end

--- 设置装修选项（自动持久化到 playerData_）
---@param key string "wallpaper"|"lighting"|"floor"
---@param value string 对应的 id
---@return boolean 是否设置成功
function CafeCustomize.Set(key, value)
    if not playerData_ then return false end
    if not playerData_.cafeCustom then
        playerData_.cafeCustom = { wallpaper = "default", lighting = "warm", floor = "cement" }
    end
    if key == "wallpaper" then
        -- 验证是否已解锁
        local found = false
        for _, wp in ipairs(CafeCustomize.GetUnlockedWallpapers()) do
            if wp.id == value then found = true; break end
        end
        if not found then return false end
        playerData_.cafeCustom.wallpaper = value
    elseif key == "lighting" then
        local found = false
        for _, lt in ipairs(CafeCustomize.GetUnlockedLightings()) do
            if lt.id == value then found = true; break end
        end
        if not found then return false end
        playerData_.cafeCustom.lighting = value
    elseif key == "floor" then
        local found = false
        for _, fl in ipairs(CafeCustomize.GetUnlockedFloors()) do
            if fl.id == value then found = true; break end
        end
        if not found then return false end
        playerData_.cafeCustom.floor = value
    else
        return false
    end
    return true
end

-- ── 渲染辅助：获取当前壁纸配色数据 ──

--- 获取当前壁纸的颜色配置
---@return table { wallColor={r,g,b}, innerColor={r,g,b}, hasGraffiti=bool, hasPattern=bool }
function CafeCustomize.GetWallpaperColors()
    local current = CafeCustomize.GetCurrent()
    for _, wp in ipairs(CafeCustomize.WALLPAPERS) do
        if wp.id == current.wallpaper then
            return {
                wallColor  = wp.wallColor,
                innerColor = wp.innerColor,
                hasGraffiti = wp.hasGraffiti or false,
                hasPattern  = wp.hasPattern or false,
            }
        end
    end
    -- fallback
    return {
        wallColor  = { 180, 130, 80 },
        innerColor = { 245, 235, 215 },
        hasGraffiti = false,
        hasPattern  = false,
    }
end

--- 获取当前灯光叠加配置
---@return table { overlay={r,g,b}, alpha=number }
function CafeCustomize.GetLightingOverlay()
    local current = CafeCustomize.GetCurrent()
    for _, lt in ipairs(CafeCustomize.LIGHTINGS) do
        if lt.id == current.lighting then
            return { overlay = lt.overlay, alpha = lt.alpha }
        end
    end
    return { overlay = { 255, 200, 100 }, alpha = 25 }
end

--- 获取当前地板配色
---@return table { color={r,g,b}, lineColor={r,g,b} }
function CafeCustomize.GetFloorColors()
    local current = CafeCustomize.GetCurrent()
    for _, fl in ipairs(CafeCustomize.FLOORS) do
        if fl.id == current.floor then
            return { color = fl.color, lineColor = fl.lineColor }
        end
    end
    return { color = { 180, 175, 165 }, lineColor = { 160, 155, 145 } }
end

return CafeCustomize
