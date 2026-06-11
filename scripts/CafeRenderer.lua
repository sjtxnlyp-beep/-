-- ============================================================================
-- CafeRenderer.lua — 百货商店物语风格建筑截面渲染器
-- 用 NanoVG 动态绘制网吧内部像素截面图
-- ============================================================================

local CafeRenderer = {}
local CafeAnimEvents = require("CafeAnimEvents")
local CafeCustomize = require("CafeCustomize")

-- ── 颜色配置（暖色系） ──
local COLORS = {
    -- 建筑外壳
    wallOuter   = { 180, 130, 80 },    -- 外墙砖色
    wallInner   = { 245, 235, 215 },   -- 内墙米白
    roof        = { 160, 100, 60 },    -- 屋顶深棕
    roofTile    = { 190, 130, 70 },    -- 屋瓦
    floor       = { 210, 185, 140 },   -- 地板木色
    floorLine   = { 185, 160, 120 },   -- 地板线
    window      = { 180, 220, 240 },   -- 窗玻璃
    windowFrame = { 140, 100, 60 },    -- 窗框

    -- 设备
    deskTop     = { 160, 140, 110 },   -- 桌面
    deskLeg     = { 130, 110, 85 },    -- 桌腿
    monitor     = { 60, 60, 60 },      -- 显示器
    monitorGlow = { 120, 200, 255 },   -- 屏幕亮色
    monitorOff  = { 40, 40, 40 },      -- 关机屏
    chair       = { 100, 160, 80 },    -- 椅子

    -- 人物（简化像素小人）
    skinTones   = {
        { 140, 90, 50 }, { 100, 65, 35 }, { 170, 120, 70 },
        { 80, 50, 25 }, { 120, 80, 45 },
    },
    shirtColors = {
        { 230, 120, 50 }, { 90, 150, 200 }, { 100, 180, 80 },
        { 240, 180, 50 }, { 200, 100, 100 }, { 180, 140, 200 },
    },

    -- 装饰
    acUnit      = { 200, 210, 220 },   -- 空调
    solarPanel  = { 60, 100, 140 },    -- 太阳能板
    foodStall   = { 220, 160, 80 },    -- 小卖部
    sign        = { 240, 200, 100 },   -- 招牌
    signText    = { 100, 60, 30 },     -- 招牌文字

    -- 状态效果
    sparkle     = { 255, 240, 100 },   -- 闪光
    smoke       = { 180, 170, 160 },   -- 烟雾
    warning     = { 240, 80, 60 },     -- 警告红
}

-- ── 动画状态 ──
local animState = {
    time = 0,
    people = {},          -- 小人位置缓存
    peopleTimer = 0,      -- 小人重新生成计时
    sparkles = {},        -- 闪光粒子
}

-- ── 辅助：绘制像素矩形 ──
local function drawRect(vg, x, y, w, h, color, alpha)
    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillColor(vg, nvgRGBA(color[1], color[2], color[3], alpha or 255))
    nvgFill(vg)
end

-- ── 辅助：绘制圆角矩形 ──
local function drawRoundRect(vg, x, y, w, h, r, color, alpha)
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, w, h, r)
    nvgFillColor(vg, nvgRGBA(color[1], color[2], color[3], alpha or 255))
    nvgFill(vg)
end

-- ── 绘制屋顶 ──
local function drawRoof(vg, x, y, w, unitH)
    local roofH = unitH * 0.6
    -- 屋顶主体（三角形）
    nvgBeginPath(vg)
    nvgMoveTo(vg, x - 4, y + roofH)
    nvgLineTo(vg, x + w / 2, y)
    nvgLineTo(vg, x + w + 4, y + roofH)
    nvgClosePath(vg)
    nvgFillColor(vg, nvgRGBA(COLORS.roof[1], COLORS.roof[2], COLORS.roof[3], 255))
    nvgFill(vg)

    -- 屋瓦线条
    nvgStrokeWidth(vg, 1)
    nvgStrokeColor(vg, nvgRGBA(COLORS.roofTile[1], COLORS.roofTile[2], COLORS.roofTile[3], 180))
    for i = 1, 3 do
        local frac = i / 4
        local ly = y + roofH * frac
        local lxL = x - 4 + (w / 2 + 4) * frac
        local lxR = x + w + 4 - (w / 2 + 4) * frac
        -- 无需三角形裁剪，直线即可模拟瓦纹
        nvgBeginPath(vg)
        nvgMoveTo(vg, x - 4 + (w/2 + 4) * (frac * 0.3), ly)
        nvgLineTo(vg, x + w + 4 - (w/2 + 4) * (frac * 0.3), ly)
        nvgStroke(vg)
    end

    -- 招牌
    local signW = w * 0.5
    local signH = unitH * 0.25
    local signX = x + (w - signW) / 2
    local signY = y + roofH - signH * 0.3
    drawRoundRect(vg, signX, signY, signW, signH, 3, COLORS.sign, 240)
    -- 招牌边框
    nvgBeginPath(vg)
    nvgRoundedRect(vg, signX, signY, signW, signH, 3)
    nvgStrokeWidth(vg, 1.5)
    nvgStrokeColor(vg, nvgRGBA(COLORS.signText[1], COLORS.signText[2], COLORS.signText[3], 180))
    nvgStroke(vg)

    return roofH
end

-- ── 绘制窗户 ──
local function drawWindow(vg, x, y, w, h, lit)
    drawRect(vg, x, y, w, h, COLORS.windowFrame)
    local inset = 1.5
    local glowColor = lit and COLORS.window or { 140, 150, 160 }
    local glowAlpha = lit and 220 or 120
    drawRect(vg, x + inset, y + inset, w - inset * 2, h - inset * 2, glowColor, glowAlpha)
    -- 窗户十字分格
    nvgBeginPath(vg)
    nvgMoveTo(vg, x + w / 2, y + inset)
    nvgLineTo(vg, x + w / 2, y + h - inset)
    nvgMoveTo(vg, x + inset, y + h / 2)
    nvgLineTo(vg, x + w - inset, y + h / 2)
    nvgStrokeWidth(vg, 1)
    nvgStrokeColor(vg, nvgRGBA(COLORS.windowFrame[1], COLORS.windowFrame[2], COLORS.windowFrame[3], 200))
    nvgStroke(vg)
end

-- ── 绘制电脑桌（含显示器） ──
local function drawDesk(vg, x, y, w, h, isOn, chairColor)
    local deskH = h * 0.35
    local deskY = y + h - deskH
    -- 桌面
    drawRect(vg, x, deskY, w, 3, COLORS.deskTop)
    -- 桌腿
    drawRect(vg, x + 2, deskY + 3, 2, deskH - 3, COLORS.deskLeg)
    drawRect(vg, x + w - 4, deskY + 3, 2, deskH - 3, COLORS.deskLeg)
    -- 显示器
    local monW = w * 0.5
    local monH = h * 0.3
    local monX = x + (w - monW) / 2
    local monY = deskY - monH
    drawRect(vg, monX, monY, monW, monH, COLORS.monitor)
    -- 屏幕（内亮 + 微闪动画）
    if isOn then
        local flicker = 0.82 + 0.18 * math.sin(animState.time * 3.2 + x * 0.5)
        local glow = COLORS.monitorGlow
        drawRect(vg, monX + 1, monY + 1, monW - 2, monH - 2, {
            math.floor(glow[1] * flicker),
            math.floor(glow[2] * flicker),
            math.floor(glow[3] * flicker),
        }, 180)
    else
        drawRect(vg, monX + 1, monY + 1, monW - 2, monH - 2, COLORS.monitorOff, 200)
    end
    -- 显示器支架
    drawRect(vg, x + w / 2 - 1, monY + monH, 2, 3, COLORS.deskLeg)
    -- 椅子（简化：小圆弧）
    local chX = x + w / 2
    local chY = y + h - 3
    nvgBeginPath(vg)
    nvgCircle(vg, chX, chY, 3.5)
    nvgFillColor(vg, nvgRGBA(chairColor[1], chairColor[2], chairColor[3], 220))
    nvgFill(vg)
end

-- ── 绘制小人（简化像素风） ──
local function drawPerson(vg, x, y, h, skinColor, shirtColor, sitting)
    local headR = h * 0.15
    local bodyH = h * 0.3
    local legH = sitting and 0 or (h * 0.2)
    local totalH = headR * 2 + bodyH + legH
    local baseY = y + h - totalH

    -- 头部（坐着时微微点头动画）
    local headBob = sitting and (math.sin(animState.time * 2.5 + x * 0.7) * 1) or 0
    nvgBeginPath(vg)
    nvgCircle(vg, x, baseY + headR + headBob, headR)
    nvgFillColor(vg, nvgRGBA(skinColor[1], skinColor[2], skinColor[3], 255))
    nvgFill(vg)

    -- 身体
    drawRect(vg, x - headR * 0.7, baseY + headR * 2, headR * 1.4, bodyH, shirtColor)

    -- 腿部（站立时行走动画）
    if not sitting then
        local legPhase = math.sin(animState.time * 5 + x * 0.3) * 1.5
        drawRect(vg, x - headR * 0.5 + legPhase, baseY + headR * 2 + bodyH, headR * 0.35, legH, skinColor)
        drawRect(vg, x + headR * 0.15 - legPhase, baseY + headR * 2 + bodyH, headR * 0.35, legH, skinColor)
    end
end

-- ── 绘制空调 ──
local function drawAC(vg, x, y, w)
    drawRoundRect(vg, x, y, w, 6, 2, COLORS.acUnit, 230)
    -- 出风口线
    nvgStrokeWidth(vg, 0.5)
    nvgStrokeColor(vg, nvgRGBA(150, 160, 170, 150))
    for i = 0, 2 do
        nvgBeginPath(vg)
        nvgMoveTo(vg, x + 3 + i * (w - 6) / 3, y + 4)
        nvgLineTo(vg, x + 3 + i * (w - 6) / 3, y + 6)
        nvgStroke(vg)
    end
    -- 冷气波浪线动画
    for i = 0, 2 do
        local lineAlpha = 50 + 35 * math.sin(animState.time * 2 + i * 1.5)
        local lineY = y + 8 + i * 3
        local wave = math.sin(animState.time * 3 + i) * 2
        nvgBeginPath(vg)
        nvgMoveTo(vg, x + 3, lineY)
        nvgBezierTo(vg, x + w * 0.3, lineY + wave,
                    x + w * 0.7, lineY - wave, x + w - 3, lineY)
        nvgStrokeWidth(vg, 0.5)
        nvgStrokeColor(vg, nvgRGBA(200, 230, 255, math.floor(lineAlpha)))
        nvgStroke(vg)
    end
end

-- ── 绘制太阳能板 ──
local function drawSolar(vg, x, y, w, count)
    for i = 0, count - 1 do
        local px = x + i * (w / count + 2)
        local pw = w / count - 1
        drawRect(vg, px, y, pw, 4, COLORS.solarPanel, 220)
        -- 格子线
        nvgStrokeWidth(vg, 0.5)
        nvgStrokeColor(vg, nvgRGBA(40, 70, 100, 150))
        nvgBeginPath(vg)
        nvgMoveTo(vg, px + pw / 2, y)
        nvgLineTo(vg, px + pw / 2, y + 4)
        nvgStroke(vg)
    end
end

-- ── 绘制小卖部摊位 ──
local function drawFoodStall(vg, x, y, w, h)
    -- 摊位台面
    drawRoundRect(vg, x, y, w, h, 2, COLORS.foodStall, 230)
    -- 遮阳棚（红白条纹）
    local awningH = 5
    for i = 0, 3 do
        local col = (i % 2 == 0) and { 220, 80, 60 } or { 255, 245, 230 }
        drawRect(vg, x + i * w / 4, y - awningH, w / 4, awningH, col, 220)
    end
end

-- ── 生成/更新小人位置 ──
local function refreshPeople(computers, traffic, capacity)
    local ppl = {}
    local seatCount = math.min(computers, 12)
    local occupied = math.min(traffic, seatCount)
    -- 坐着的人（在电脑前）
    for i = 1, occupied do
        local skinIdx = ((i * 7 + 3) % #COLORS.skinTones) + 1
        local shirtIdx = ((i * 13 + 5) % #COLORS.shirtColors) + 1
        table.insert(ppl, {
            seat = i, sitting = true,
            skin = COLORS.skinTones[skinIdx],
            shirt = COLORS.shirtColors[shirtIdx],
        })
    end
    -- 走动的人（溢出客流）
    local walkers = math.min(3, math.max(0, traffic - seatCount))
    for i = 1, walkers do
        local skinIdx = ((i * 11 + 7) % #COLORS.skinTones) + 1
        local shirtIdx = ((i * 17 + 2) % #COLORS.shirtColors) + 1
        table.insert(ppl, {
            walkX = 0.1 + math.random() * 0.8, sitting = false,
            skin = COLORS.skinTones[skinIdx],
            shirt = COLORS.shirtColors[shirtIdx],
        })
    end
    return ppl
end

-- ============================================================================
-- 主渲染函数
-- ============================================================================

--- 绘制网吧建筑截面
---@param vg userdata NanoVG 上下文
---@param x number 绘制区域左上角 x
---@param y number 绘制区域左上角 y
---@param w number 绘制区域宽度
---@param h number 绘制区域高度
---@param data table 网吧数据 { computers, traffic, capacity, acLevel, solarLevel, foodShop, decoLevel, chairLevel, equipCondition, blackout }
function CafeRenderer.Draw(vg, x, y, w, h, data)
    local dt = 1.0 / 60  -- 近似帧时间
    animState.time = animState.time + dt

    local computers = data.computers or 5
    local traffic = data.traffic or 0
    local capacity = data.capacity or 5
    local acLevel = data.acLevel or 0
    local solarLevel = data.solarLevel or 0
    local foodShop = data.foodShop or 0
    local decoLevel = data.decoLevel or 0
    local chairLevel = data.chairLevel or 1
    local condition = data.equipCondition or 100
    local blackout = data.blackout or false

    -- 椅子颜色随等级变化
    local chairColors = {
        { 139, 119, 101 },  -- 塑料凳
        { 130, 130, 140 },  -- 折叠椅
        { 80, 80, 90 },     -- 网吧椅
        { 200, 50, 50 },    -- 电竞椅（红）
        { 240, 200, 50 },   -- 皇帝座（金）
    }
    local chairColor = chairColors[math.min(chairLevel, #chairColors)]

    -- 建筑布局计算
    local wallThick = 4
    local roofH = h * 0.12
    local floorCount = math.ceil(computers / 6)  -- 每层最多 6 台
    if floorCount < 1 then floorCount = 1 end
    if floorCount > 3 then floorCount = 3 end  -- 最多 3 层
    local floorH = (h - roofH - 2) / floorCount

    -- ── 绘制天空渐变背景 ──
    local skyPaint = nvgLinearGradient(vg, x, y, x, y + h,
        nvgRGBA(160, 210, 240, 180), nvgRGBA(220, 230, 240, 100))
    nvgBeginPath(vg)
    nvgRoundedRect(vg, x, y, w, h, 6)
    nvgFillPaint(vg, skyPaint)
    nvgFill(vg)

    -- ── 绘制太阳能板（屋顶上方） ──
    if solarLevel > 0 then
        drawSolar(vg, x + w * 0.15, y + roofH * 0.1, w * 0.7, solarLevel)
    end

    -- ── 绘制屋顶 ──
    local buildingX = x + wallThick
    local buildingW = w - wallThick * 2
    drawRoof(vg, buildingX, y + 2, buildingW, roofH)

    local bodyY = y + 2 + roofH * 0.6
    local bodyH = h - roofH * 0.6 - 4

    -- ── 建筑外壳（应用装修壁纸配色） ──
    local wpColors = CafeCustomize.GetWallpaperColors()
    local floorColors = CafeCustomize.GetFloorColors()
    drawRect(vg, buildingX, bodyY, buildingW, bodyH, wpColors.wallColor)
    drawRect(vg, buildingX + wallThick, bodyY, buildingW - wallThick * 2, bodyH, wpColors.innerColor)

    -- ── 更新小人 ──
    animState.peopleTimer = animState.peopleTimer + dt
    if animState.peopleTimer > 3.0 or #animState.people == 0 then
        animState.peopleTimer = 0
        animState.people = refreshPeople(computers, traffic, capacity)
    end

    -- ── 逐层绘制 ──
    local seatIdx = 0
    local walkerIdx = 0
    for floor = 1, floorCount do
        local fy = bodyY + (floor - 1) * floorH
        local fInnerX = buildingX + wallThick
        local fInnerW = buildingW - wallThick * 2
        local fInnerH = floorH

        -- 地板线
        if floor > 1 then
            drawRect(vg, buildingX, fy, buildingW, 2, floorColors.color)
        end

        -- 窗户（每层两个，在外墙上）
        local winW = 8
        local winH = floorH * 0.4
        local winY = fy + floorH * 0.2
        drawWindow(vg, buildingX - 1, winY, winW, winH, not blackout)
        drawWindow(vg, buildingX + buildingW - winW + 1, winY, winW, winH, not blackout)

        -- 空调（挂在内墙上方）
        if acLevel > 0 and floor == 1 then
            drawAC(vg, fInnerX + fInnerW * 0.6, fy + 3, fInnerW * 0.3)
        end

        -- 电脑桌
        local computersThisFloor = math.min(6, computers - (floor - 1) * 6)
        if computersThisFloor > 0 then
            local deskW = math.min(fInnerW / computersThisFloor - 2, 20)
            local deskSpacing = fInnerW / computersThisFloor
            for i = 1, computersThisFloor do
                local dx = fInnerX + (i - 1) * deskSpacing + (deskSpacing - deskW) / 2
                local dy = fy + 8
                local dh = fInnerH - 12
                local isOn = not blackout and (seatIdx < traffic)
                drawDesk(vg, dx, dy, deskW, dh, isOn, chairColor)

                -- 坐在电脑前的人
                seatIdx = seatIdx + 1
                for _, p in ipairs(animState.people) do
                    if p.sitting and p.seat == seatIdx then
                        drawPerson(vg, dx + deskW / 2, dy, dh * 0.8, p.skin, p.shirt, true)
                        break
                    end
                end
            end
        end

        -- 走动的人（在地板上）
        for _, p in ipairs(animState.people) do
            if not p.sitting and floor == floorCount then
                -- 走动动画
                local wx = fInnerX + p.walkX * fInnerW
                -- 微微左右移动
                local sway = math.sin(animState.time * 1.5 + (p.walkX * 10)) * 3
                drawPerson(vg, wx + sway, fy + 4, fInnerH - 6, p.skin, p.shirt, false)
            end
        end
    end

    -- ── 小卖部（建筑右侧外） ──
    if foodShop > 0 then
        local stallW = 18
        local stallH = 12
        local stallX = buildingX + buildingW + 2
        local stallY = bodyY + bodyH - stallH - 2
        if stallX + stallW <= x + w then
            drawFoodStall(vg, stallX, stallY, stallW, stallH)
            -- 蒸汽上升动画（foodShop >= 2 时）
            if foodShop >= 2 then
                for i = 1, 2 do
                    local steamT = (animState.time * 0.6 + i * 1.2) % 2.0
                    local steamY = stallY - 3 - steamT * 8
                    local steamA = math.max(0, 120 * (1 - steamT / 2.0))
                    nvgBeginPath(vg)
                    nvgCircle(vg, stallX + stallW * 0.3 + i * 5, steamY, 1.5 + steamT * 0.8)
                    nvgFillColor(vg, nvgRGBA(255, 250, 240, math.floor(steamA)))
                    nvgFill(vg)
                end
            end
        end
    end

    -- ── 装饰效果 ──
    if decoLevel >= 2 then
        -- 装饰旗帜/彩灯（建筑底部）
        local flagY = bodyY + bodyH - 3
        nvgStrokeWidth(vg, 1)
        for i = 0, 4 do
            local flagX = buildingX + wallThick + 8 + i * (buildingW - wallThick * 2 - 16) / 4
            local flagCol = (i % 2 == 0) and { 240, 100, 60 } or { 100, 200, 80 }
            nvgBeginPath(vg)
            nvgMoveTo(vg, flagX, flagY)
            nvgLineTo(vg, flagX - 2, flagY + 5)
            nvgLineTo(vg, flagX + 2, flagY + 5)
            nvgClosePath(vg)
            nvgFillColor(vg, nvgRGBA(flagCol[1], flagCol[2], flagCol[3], 200))
            nvgFill(vg)
        end
    end

    -- ── 停电效果 ──
    if blackout then
        drawRect(vg, x, y, w, h, { 20, 15, 10 }, 140)
        -- 闪烁警告
        local blink = math.sin(animState.time * 4) > 0
        if blink then
            nvgFontSize(vg, 14)
            nvgFontFace(vg, "trans")
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            nvgFillColor(vg, nvgRGBA(COLORS.warning[1], COLORS.warning[2], COLORS.warning[3], 220))
            nvgText(vg, x + w / 2, y + h / 2, "⚡ 停电")
        end
    end

    -- ── 设备老化效果 ──
    if condition <= 30 then
        -- 冒烟效果
        for i = 1, 3 do
            local smokeX = buildingX + wallThick + math.random() * (buildingW - wallThick * 2)
            local smokeY = bodyY + 10 + math.sin(animState.time * 2 + i) * 5
            local smokeA = 80 + math.floor(math.sin(animState.time * 3 + i * 2) * 40)
            nvgBeginPath(vg)
            nvgCircle(vg, smokeX, smokeY, 3 + math.sin(animState.time + i) * 1.5)
            nvgFillColor(vg, nvgRGBA(COLORS.smoke[1], COLORS.smoke[2], COLORS.smoke[3], smokeA))
            nvgFill(vg)
        end
    end

    -- ── 灯光色调叠加（装修系统） ──
    local ltOverlay = CafeCustomize.GetLightingOverlay()
    if ltOverlay.alpha > 0 then
        drawRect(vg, buildingX + wallThick, bodyY, buildingW - wallThick * 2, bodyH, ltOverlay.overlay, ltOverlay.alpha)
    end

    -- ── 壁纸特效：涂鸦/图腾装饰点缀 ──
    if wpColors.hasGraffiti then
        -- 霓虹涂鸦点缀（随机荧光色块）
        local gTime = animState.time
        for i = 1, 4 do
            local gx = buildingX + wallThick + 8 + ((i * 37 + 11) % (math.floor(buildingW) - wallThick * 2 - 16))
            local gy = bodyY + 8 + ((i * 23 + 7) % (math.floor(bodyH) - 20))
            local gAlpha = 120 + math.floor(60 * math.sin(gTime * 2 + i * 1.5))
            local gColors = { { 255, 50, 200 }, { 50, 255, 150 }, { 255, 255, 50 }, { 50, 200, 255 } }
            nvgBeginPath(vg)
            nvgCircle(vg, gx, gy, 2.5 + math.sin(gTime + i) * 0.8)
            nvgFillColor(vg, nvgRGBA(gColors[i][1], gColors[i][2], gColors[i][3], gAlpha))
            nvgFill(vg)
        end
    end
    if wpColors.hasPattern then
        -- 金星图腾（重复菱形纹饰）
        nvgStrokeWidth(vg, 0.8)
        nvgStrokeColor(vg, nvgRGBA(200, 170, 50, 80))
        local patW = buildingW - wallThick * 2
        for i = 0, 5 do
            local px = buildingX + wallThick + 6 + i * (patW / 6)
            local py = bodyY + bodyH * 0.3
            nvgBeginPath(vg)
            nvgMoveTo(vg, px, py - 5)
            nvgLineTo(vg, px + 4, py)
            nvgLineTo(vg, px, py + 5)
            nvgLineTo(vg, px - 4, py)
            nvgClosePath(vg)
            nvgStroke(vg)
        end
    end

    -- ── 地面 ──
    drawRect(vg, x, y + h - 4, w, 4, { 140, 180, 100 }, 200)  -- 草地

    -- ── 经营动作动画叠加 ──
    CafeAnimEvents.DrawAll(vg, x, y, w, h, {
        buildingX = buildingX,
        buildingW = buildingW,
        bodyY = bodyY,
        bodyH = bodyH,
        floorCount = floorCount,
        floorH = floorH,
        wallThick = wallThick,
    })
end

return CafeRenderer
