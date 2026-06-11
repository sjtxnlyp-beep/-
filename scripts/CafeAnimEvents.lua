-- ============================================================================
-- CafeAnimEvents.lua — 经营动作动画事件系统
-- 当玩家执行经营动作时，在建筑截面图上叠加对应的像素动画
-- ============================================================================

local CafeAnimEvents = {}

-- ── 配置 ──
local MAX_CONCURRENT = 5       -- 最大同时播放数
local FADE_IN        = 0.3     -- 淡入时间（秒）
local FADE_OUT       = 0.8     -- 淡出时间（秒）

-- ── 活跃事件队列 ──
local activeEvents = {}

-- ── 事件类型定义 ──
-- 每个类型：{ duration, draw(vg, t, alpha, x, y, w, h, layout) }
--   t       = 已过时间（0 ~ duration）
--   alpha   = 当前透明度（0~255，含淡入淡出）
--   layout  = { buildingX, buildingW, bodyY, bodyH, floorCount, floorH, wallThick }
local EVENT_DEFS = {}

-- ────────────────────────────────────────────────────
-- 辅助绘图
-- ────────────────────────────────────────────────────
local function rect(vg, x, y, w, h, color, a)
    nvgBeginPath(vg)
    nvgRect(vg, x, y, w, h)
    nvgFillColor(vg, nvgRGBA(color[1], color[2], color[3], a or 255))
    nvgFill(vg)
end

local function circle(vg, cx, cy, r, color, a)
    nvgBeginPath(vg)
    nvgCircle(vg, cx, cy, r)
    nvgFillColor(vg, nvgRGBA(color[1], color[2], color[3], a or 255))
    nvgFill(vg)
end

local function person(vg, px, py, h, skinColor, shirtColor, a)
    local headR = h * 0.18
    -- 头
    circle(vg, px, py, headR, skinColor, a)
    -- 身体
    rect(vg, px - headR * 0.7, py + headR, headR * 1.4, h * 0.35, shirtColor, a)
    -- 腿
    rect(vg, px - headR * 0.4, py + headR + h * 0.35, headR * 0.3, h * 0.2, skinColor, a)
    rect(vg, px + headR * 0.1, py + headR + h * 0.35, headR * 0.3, h * 0.2, skinColor, a)
end

-- ────────────────────────────────────────────────────
-- 1. market_return — 逛集市归来（小人从右侧走入，扛着箱子）
-- ────────────────────────────────────────────────────
EVENT_DEFS.market_return = {
    duration = 3.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local progress = math.min(1, t / 2.5)
        local px = x + w - (w * 0.8) * progress
        local py = L.bodyY + L.bodyH - 14
        local a = alpha
        -- 走路的小人
        person(vg, px, py, 12, {170, 120, 70}, {240, 180, 50}, a)
        -- 头顶箱子（上下晃动）
        local bob = math.sin(t * 6) * 1.5
        rect(vg, px - 4, py - 10 + bob, 8, 5, {160, 100, 50}, a)
        -- 箱子高光
        rect(vg, px - 2, py - 9 + bob, 3, 2, {200, 160, 80}, math.floor(a * 0.6))
    end,
}

-- ────────────────────────────────────────────────────
-- 2. post_flyers — 贴传单（传单从建筑外侧飘落）
-- ────────────────────────────────────────────────────
EVENT_DEFS.post_flyers = {
    duration = 3.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        for i = 1, 5 do
            local delay = (i - 1) * 0.4
            local lt = t - delay
            if lt > 0 and lt < 2.5 then
                local fx = L.buildingX - 8 + i * 12 + math.sin(lt * 3 + i) * 4
                local fy = y + 10 + lt * 25
                local rot = math.sin(lt * 4 + i * 2) * 0.3
                nvgSave(vg)
                nvgTranslate(vg, fx, fy)
                nvgRotate(vg, rot)
                rect(vg, -3, -4, 6, 8, {255, 245, 220}, alpha)
                -- 传单上的线条
                rect(vg, -2, -2, 4, 1, {200, 100, 50}, math.floor(alpha * 0.5))
                rect(vg, -2, 0, 3, 1, {200, 100, 50}, math.floor(alpha * 0.4))
                nvgRestore(vg)
            end
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 3. scout — 招募球探（放大镜扫描）
-- ────────────────────────────────────────────────────
EVENT_DEFS.scout = {
    duration = 2.8,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.5 + math.sin(t * 2) * (L.buildingW * 0.3)
        local cy = L.bodyY + L.bodyH * 0.5 + math.cos(t * 1.5) * (L.bodyH * 0.2)
        -- 放大镜圆圈
        nvgBeginPath(vg)
        nvgCircle(vg, cx, cy, 8)
        nvgStrokeWidth(vg, 1.5)
        nvgStrokeColor(vg, nvgRGBA(255, 220, 100, alpha))
        nvgStroke(vg)
        -- 手柄
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx + 6, cy + 6)
        nvgLineTo(vg, cx + 11, cy + 11)
        nvgStrokeWidth(vg, 2)
        nvgStrokeColor(vg, nvgRGBA(180, 140, 60, alpha))
        nvgStroke(vg)
        -- 高光闪烁
        local sparkle = math.sin(t * 8) * 0.5 + 0.5
        circle(vg, cx - 3, cy - 3, 1.5, {255, 255, 200}, math.floor(alpha * sparkle))
    end,
}

-- ────────────────────────────────────────────────────
-- 4. repair — 维修设备（扳手旋转 + 火花）
-- ────────────────────────────────────────────────────
EVENT_DEFS.repair = {
    duration = 3.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.5
        local cy = L.bodyY + L.bodyH * 0.6
        -- 旋转扳手
        nvgSave(vg)
        nvgTranslate(vg, cx, cy)
        nvgRotate(vg, t * 4)
        rect(vg, -1, -8, 2, 16, {180, 180, 190}, alpha)
        rect(vg, -3, -8, 6, 3, {180, 180, 190}, alpha)
        nvgRestore(vg)
        -- 火花粒子
        for i = 1, 3 do
            local st = (t * 2 + i * 1.3) % 1.0
            local sx = cx + math.cos(i * 2.1 + t * 5) * 6
            local sy = cy + math.sin(i * 1.7 + t * 5) * 4
            local sa = math.max(0, 1 - st) * alpha
            circle(vg, sx, sy, 1.2 * (1 - st), {255, 220, 80}, math.floor(sa))
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 5. upgrade_start — 开始升级（建筑上方齿轮旋转）
-- ────────────────────────────────────────────────────
EVENT_DEFS.upgrade_start = {
    duration = 2.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.5
        local cy = y + 12
        -- 齿轮（用多个小矩形模拟）
        nvgSave(vg)
        nvgTranslate(vg, cx, cy)
        nvgRotate(vg, t * 2)
        for i = 0, 5 do
            local angle = i * math.pi / 3
            rect(vg, math.cos(angle) * 5 - 1.5, math.sin(angle) * 5 - 1.5, 3, 3, {200, 180, 100}, alpha)
        end
        circle(vg, 0, 0, 3, {160, 140, 80}, alpha)
        nvgRestore(vg)
        -- 上升箭头
        local arrowAlpha = math.floor(alpha * (math.sin(t * 4) * 0.3 + 0.7))
        nvgBeginPath(vg)
        nvgMoveTo(vg, cx, cy - 10)
        nvgLineTo(vg, cx - 3, cy - 6)
        nvgLineTo(vg, cx + 3, cy - 6)
        nvgClosePath(vg)
        nvgFillColor(vg, nvgRGBA(100, 220, 100, arrowAlpha))
        nvgFill(vg)
    end,
}

-- ────────────────────────────────────────────────────
-- 6. upgrade_complete — 升级完成（星星爆发）
-- ────────────────────────────────────────────────────
EVENT_DEFS.upgrade_complete = {
    duration = 2.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.5
        local cy = L.bodyY + L.bodyH * 0.4
        for i = 1, 8 do
            local angle = i * math.pi / 4 + t * 1.5
            local dist = t * 15
            local fade = math.max(0, 1 - t / 1.8)
            local sx = cx + math.cos(angle) * dist
            local sy = cy + math.sin(angle) * dist
            circle(vg, sx, sy, 2.5 * fade, {255, 240, 100}, math.floor(alpha * fade))
        end
        -- 中心闪光
        local flash = math.max(0, 1 - t / 0.5)
        circle(vg, cx, cy, 6 * flash, {255, 255, 200}, math.floor(alpha * flash))
    end,
}

-- ────────────────────────────────────────────────────
-- 7. bbq — 团队BBQ（烤架冒烟 + 小人围坐）
-- ────────────────────────────────────────────────────
EVENT_DEFS.bbq = {
    duration = 4.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local bx = L.buildingX + L.buildingW + 5
        local by = L.bodyY + L.bodyH - 10
        -- 烤架
        rect(vg, bx, by, 12, 4, {100, 80, 60}, alpha)
        rect(vg, bx + 2, by + 4, 2, 4, {80, 60, 40}, alpha)
        rect(vg, bx + 8, by + 4, 2, 4, {80, 60, 40}, alpha)
        -- 火焰
        for i = 1, 3 do
            local flicker = math.sin(t * 8 + i * 2) * 1.5
            local fy = by - 2 - math.abs(flicker)
            circle(vg, bx + 3 + i * 2.5, fy, 1.5 + math.sin(t * 6 + i) * 0.5,
                {255, 140 + math.floor(math.sin(t * 4 + i) * 40), 30}, alpha)
        end
        -- 烟雾上升
        for i = 1, 2 do
            local st = (t * 0.5 + i * 0.7) % 2.0
            local smokeY = by - 6 - st * 12
            local smokeA = math.max(0, (1 - st / 2.0)) * alpha * 0.4
            circle(vg, bx + 6 + math.sin(st * 2 + i) * 2, smokeY, 2 + st, {200, 190, 170}, math.floor(smokeA))
        end
        -- 围坐小人（2个）
        person(vg, bx - 4, by - 4, 10, {140, 90, 50}, {230, 120, 50}, alpha)
        person(vg, bx + 16, by - 4, 10, {100, 65, 35}, {90, 150, 200}, alpha)
    end,
}

-- ────────────────────────────────────────────────────
-- 8. tournament — 举办比赛（建筑上方旗帜飘动）
-- ────────────────────────────────────────────────────
EVENT_DEFS.tournament = {
    duration = 3.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        -- 顶部横幅
        local bannerX = L.buildingX + 4
        local bannerW = L.buildingW - 8
        local bannerY = y + 4
        rect(vg, bannerX, bannerY, bannerW, 6, {200, 50, 50}, alpha)
        -- 横幅上的文字线条模拟
        rect(vg, bannerX + 4, bannerY + 2, bannerW * 0.6, 2, {255, 220, 150}, math.floor(alpha * 0.7))
        -- 两侧三角旗帜
        for side = -1, 1, 2 do
            local fx = side < 0 and (L.buildingX - 2) or (L.buildingX + L.buildingW + 2)
            for i = 0, 2 do
                local wave = math.sin(t * 3 + i * 1.2) * 2
                local fy = bannerY + 2 + i * 6
                nvgBeginPath(vg)
                nvgMoveTo(vg, fx, fy)
                nvgLineTo(vg, fx + side * 6, fy + 2 + wave * 0.3)
                nvgLineTo(vg, fx, fy + 5)
                nvgClosePath(vg)
                local flagCol = (i % 2 == 0) and {255, 200, 50} or {50, 180, 255}
                nvgFillColor(vg, nvgRGBA(flagCol[1], flagCol[2], flagCol[3], alpha))
                nvgFill(vg)
            end
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 9. streaming — 直播跑刀（屏幕闪烁 + 弹幕效果）
-- ────────────────────────────────────────────────────
EVENT_DEFS.streaming = {
    duration = 4.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        -- 大屏幕（建筑内顶层）
        local screenX = L.buildingX + L.wallThick + 4
        local screenY = L.bodyY + 6
        local screenW = L.buildingW - L.wallThick * 2 - 8
        local screenH = L.floorH * 0.5
        -- 屏幕背景闪烁
        local flash = 0.7 + 0.3 * math.sin(t * 6)
        rect(vg, screenX, screenY, screenW, screenH,
            {math.floor(60 * flash), math.floor(160 * flash), math.floor(255 * flash)}, alpha)
        -- 弹幕飘过
        for i = 1, 4 do
            local bt = (t * 1.5 + i * 0.8) % 3.0
            local bx = screenX + screenW - bt * (screenW * 0.5)
            local by = screenY + 2 + (i - 1) * 4
            if bx > screenX and bx < screenX + screenW then
                rect(vg, bx, by, 12, 2.5, {255, 255, 255}, math.floor(alpha * 0.5))
            end
        end
        -- REC 指示灯
        local blink = math.sin(t * 4) > 0
        if blink then
            circle(vg, screenX + 3, screenY + 3, 1.5, {255, 40, 40}, alpha)
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 10. boosting — 代练（键盘快速敲击波纹）
-- ────────────────────────────────────────────────────
EVENT_DEFS.boosting = {
    duration = 3.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.35
        local cy = L.bodyY + L.bodyH * 0.6
        -- 打字波纹（同心圆向外扩散）
        for i = 1, 3 do
            local rt = (t * 2 + i * 0.5) % 1.5
            local r = rt * 10
            local ra = math.max(0, (1 - rt / 1.5)) * alpha * 0.5
            nvgBeginPath(vg)
            nvgCircle(vg, cx, cy, r)
            nvgStrokeWidth(vg, 1)
            nvgStrokeColor(vg, nvgRGBA(120, 200, 255, math.floor(ra)))
            nvgStroke(vg)
        end
        -- 速度线
        for i = 1, 4 do
            local lx = cx + 8 + i * 3
            local ly = cy - 3 + math.sin(t * 10 + i) * 2
            local la = math.floor(alpha * 0.4 * (math.sin(t * 6 + i * 1.5) * 0.5 + 0.5))
            nvgBeginPath(vg)
            nvgMoveTo(vg, lx, ly)
            nvgLineTo(vg, lx + 5, ly)
            nvgStrokeWidth(vg, 0.8)
            nvgStrokeColor(vg, nvgRGBA(200, 230, 255, la))
            nvgStroke(vg)
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 11. cafe_rental — 网吧包场（人群涌入）
-- ────────────────────────────────────────────────────
EVENT_DEFS.cafe_rental = {
    duration = 3.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        -- 一群小人从左侧走入建筑
        local doorX = L.buildingX + 4
        local doorY = L.bodyY + L.bodyH - 12
        local skins = {{140,90,50},{100,65,35},{170,120,70}}
        local shirts = {{230,120,50},{90,150,200},{100,180,80}}
        for i = 1, 4 do
            local delay = (i - 1) * 0.5
            local lt = t - delay
            if lt > 0 then
                local progress = math.min(1, lt / 2.0)
                local px = x - 10 + progress * (doorX - x + 20)
                local py = doorY
                local legPhase = math.sin(lt * 6 + i) * 1.5
                local si = ((i - 1) % #skins) + 1
                person(vg, px, py, 10, skins[si], shirts[si], alpha)
            end
        end
        -- 门口热闹气氛线
        if t > 1.0 then
            local sparkA = math.floor(alpha * 0.4 * math.abs(math.sin(t * 5)))
            for i = 1, 3 do
                local sx = doorX + math.sin(t * 3 + i * 2) * 4
                local sy = doorY - 6 - i * 2
                circle(vg, sx, sy, 1, {255, 240, 100}, sparkA)
            end
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 12. phone_repair — 手机维修（螺丝刀 + 手机图标）
-- ────────────────────────────────────────────────────
EVENT_DEFS.phone_repair = {
    duration = 2.8,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.7
        local cy = L.bodyY + L.bodyH * 0.5
        -- 手机轮廓
        nvgBeginPath(vg)
        nvgRoundedRect(vg, cx - 3, cy - 5, 6, 10, 1)
        nvgStrokeWidth(vg, 1)
        nvgStrokeColor(vg, nvgRGBA(180, 180, 180, alpha))
        nvgStroke(vg)
        -- 手机屏幕
        rect(vg, cx - 2, cy - 3.5, 4, 7, {100, 180, 255}, math.floor(alpha * 0.6))
        -- 螺丝刀旋转
        nvgSave(vg)
        nvgTranslate(vg, cx + 8, cy)
        nvgRotate(vg, math.sin(t * 5) * 0.5)
        rect(vg, -0.8, -6, 1.6, 12, {190, 190, 200}, alpha)
        rect(vg, -1.5, -6, 3, 2, {220, 180, 50}, alpha)
        nvgRestore(vg)
    end,
}

-- ────────────────────────────────────────────────────
-- 13. buy_fuel — 买燃油（油桶搬运）
-- ────────────────────────────────────────────────────
EVENT_DEFS.buy_fuel = {
    duration = 3.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local progress = math.min(1, t / 2.2)
        local px = x + w * 0.8 - progress * w * 0.5
        local py = L.bodyY + L.bodyH - 8
        -- 搬运小人
        person(vg, px, py, 10, {100, 65, 35}, {80, 120, 180}, alpha)
        -- 油桶（跟着小人）
        local barrelX = px + 5
        local barrelY = py + 2
        rect(vg, barrelX, barrelY, 5, 7, {180, 60, 60}, alpha)
        -- 油桶标记
        rect(vg, barrelX + 1, barrelY + 2, 3, 1, {255, 200, 50}, math.floor(alpha * 0.7))
    end,
}

-- ────────────────────────────────────────────────────
-- 14. second_hand — 二手市场（问号箱子开启）
-- ────────────────────────────────────────────────────
EVENT_DEFS.second_hand = {
    duration = 3.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = x + w * 0.5
        local cy = L.bodyY + L.bodyH - 15
        -- 箱子
        local openAngle = math.min(1, t / 1.5) * 0.8
        rect(vg, cx - 6, cy, 12, 8, {160, 120, 70}, alpha)
        -- 箱盖（逐渐打开）
        nvgSave(vg)
        nvgTranslate(vg, cx - 6, cy)
        nvgRotate(vg, -openAngle)
        rect(vg, 0, -2, 12, 2, {180, 140, 80}, alpha)
        nvgRestore(vg)
        -- 问号
        if t > 0.8 then
            local qAlpha = math.min(1, (t - 0.8) / 0.5)
            local qBob = math.sin(t * 3) * 2
            nvgFontFace(vg, "trans")
            nvgFontSize(vg, 12)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            nvgFillColor(vg, nvgRGBA(255, 220, 80, math.floor(alpha * qAlpha)))
            nvgText(vg, cx, cy - 8 + qBob, "?")
        end
        -- 光芒
        if t > 1.2 then
            for i = 1, 4 do
                local angle = i * math.pi / 2 + t * 2
                local dist = (t - 1.2) * 8
                local sa = math.max(0, 1 - (t - 1.2) / 1.5) * alpha * 0.6
                circle(vg, cx + math.cos(angle) * dist, cy - 4 + math.sin(angle) * dist,
                    1.5, {255, 240, 130}, math.floor(sa))
            end
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 15. open_branch — 开分店（建筑右侧冒出小房子）
-- ────────────────────────────────────────────────────
EVENT_DEFS.open_branch = {
    duration = 3.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local rise = math.min(1, t / 1.5)
        local bx = x + w - 20
        local fullH = 18
        local by = L.bodyY + L.bodyH - fullH * rise
        local bw = 14
        local bh = fullH * rise
        if bh < 1 then return end
        -- 小房子
        rect(vg, bx, by, bw, bh, {200, 170, 120}, alpha)
        -- 屋顶
        if rise > 0.5 then
            nvgBeginPath(vg)
            nvgMoveTo(vg, bx - 2, by)
            nvgLineTo(vg, bx + bw / 2, by - 6)
            nvgLineTo(vg, bx + bw + 2, by)
            nvgClosePath(vg)
            nvgFillColor(vg, nvgRGBA(160, 100, 60, alpha))
            nvgFill(vg)
        end
        -- 门
        if rise > 0.7 then
            rect(vg, bx + bw / 2 - 2, by + bh - 6, 4, 6, {100, 70, 40}, alpha)
        end
        -- 开业烟花
        if t > 2.0 then
            for i = 1, 5 do
                local st = t - 2.0
                local angle = i * math.pi * 2 / 5 + st
                local dist = st * 10
                local fa = math.max(0, 1 - st / 1.5) * alpha
                circle(vg, bx + bw / 2 + math.cos(angle) * dist,
                    by - 6 + math.sin(angle) * dist * 0.6,
                    1.5, {255, 200, 50}, math.floor(fa))
            end
        end
    end,
}

-- ────────────────────────────────────────────────────
-- 16. borrow_money — 向Mama B借钱（钱袋交接）
-- ────────────────────────────────────────────────────
EVENT_DEFS.borrow_money = {
    duration = 2.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = x + w * 0.3
        local cy = L.bodyY + L.bodyH - 10
        -- Mama B（左侧）
        person(vg, cx - 12, cy, 12, {140, 90, 50}, {200, 80, 80}, alpha)
        -- 玩家（右侧）
        person(vg, cx + 12, cy, 12, {170, 120, 70}, {80, 130, 180}, alpha)
        -- 钱袋从 Mama B 飞向玩家
        local bagProgress = math.min(1, t / 1.5)
        local bagX = cx - 8 + bagProgress * 16
        local bagY = cy + 2 - math.sin(bagProgress * math.pi) * 8
        -- 钱袋
        circle(vg, bagX, bagY, 3, {80, 160, 60}, alpha)
        -- $ 符号
        nvgFontFace(vg, "trans")
        nvgFontSize(vg, 7)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 255, 200, alpha))
        nvgText(vg, bagX, bagY, "$")
    end,
}

-- ────────────────────────────────────────────────────
-- market_xiaoxue — 小雪集市事件（两个小人并肩从右侧走入）
-- ────────────────────────────────────────────────────
EVENT_DEFS.market_xiaoxue = {
    duration = 4.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local progress = math.min(1, t / 3.0)
        local baseX = x + w - (w * 0.75) * progress
        local baseY = L.bodyY + L.bodyH - 14
        -- 主角
        person(vg, baseX, baseY, 12, {170, 120, 70}, {90, 150, 200}, alpha)
        -- 小雪（白衣，紧跟半步）
        person(vg, baseX + 10, baseY, 11, {240, 210, 180}, {255, 255, 255}, alpha)
        -- 小雪头上的爱心（上下浮动）
        local heartY = baseY - 14 + math.sin(t * 3) * 2
        local heartA = math.floor(alpha * (0.6 + 0.4 * math.sin(t * 4)))
        nvgFontFace(vg, "trans")
        nvgFontSize(vg, 8)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 130, 160, heartA))
        nvgText(vg, baseX + 10, heartY, "♥")
    end,
}

-- ────────────────────────────────────────────────────
-- market_grace — Grace集市事件（干练女性在门口等待）
-- ────────────────────────────────────────────────────
EVENT_DEFS.market_grace = {
    duration = 4.0,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local doorX = L.buildingX + 6
        local doorY = L.bodyY + L.bodyH - 14
        -- Grace（红裙，在门口）
        person(vg, doorX, doorY, 12, {100, 65, 35}, {200, 60, 60}, alpha)
        -- 挥手动作（手臂摆动）
        local wave = math.sin(t * 5) * 3
        nvgBeginPath(vg)
        nvgMoveTo(vg, doorX + 3, doorY + 3)
        nvgLineTo(vg, doorX + 6 + wave, doorY - 1)
        nvgStrokeWidth(vg, 1.5)
        nvgStrokeColor(vg, nvgRGBA(100, 65, 35, alpha))
        nvgStroke(vg)
        -- 主角从右走来
        local progress = math.min(1, t / 2.5)
        local px = x + w - (w * 0.6) * progress
        person(vg, px, doorY, 12, {170, 120, 70}, {90, 150, 200}, alpha)
        -- 商务提包
        rect(vg, doorX - 6, doorY + 4, 5, 4, {80, 60, 40}, alpha)
    end,
}

-- ────────────────────────────────────────────────────
-- market_wedding — 误闯婚礼（五彩纸屑 + 跳舞小人）
-- ────────────────────────────────────────────────────
EVENT_DEFS.market_wedding = {
    duration = 4.5,
    draw = function(vg, t, alpha, x, y, w, h, L)
        local cx = L.buildingX + L.buildingW * 0.5
        local baseY = L.bodyY + L.bodyH - 14
        -- 跳舞小人们
        local dancers = {
            {offset = -12, skin = {140,90,50}, shirt = {255,200,50}},
            {offset = 0,   skin = {170,120,70}, shirt = {90,150,200}},
            {offset = 12,  skin = {100,65,35}, shirt = {200,100,180}},
        }
        for i, d in ipairs(dancers) do
            local bounce = math.abs(math.sin(t * 4 + i * 1.2)) * 3
            person(vg, cx + d.offset, baseY - bounce, 11, d.skin, d.shirt, alpha)
        end
        -- 五彩纸屑飘落
        local confettiColors = {{255,100,100},{255,220,50},{100,200,255},{100,255,130},{255,150,230}}
        for i = 1, 10 do
            local ct = (t * 0.8 + i * 0.3) % 3.0
            local cfx = cx - 20 + (i * 7) % 40 + math.sin(ct * 2 + i) * 5
            local cfy = y + 5 + ct * 20
            local ca = math.max(0, (1 - ct / 3.0)) * alpha * 0.7
            local col = confettiColors[((i - 1) % #confettiColors) + 1]
            rect(vg, cfx, cfy, 2.5, 2.5, col, math.floor(ca))
        end
        -- 音符飘出
        local noteA = math.floor(alpha * (0.5 + 0.5 * math.sin(t * 3)))
        nvgFontFace(vg, "trans")
        nvgFontSize(vg, 9)
        nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 240, 100, noteA))
        nvgText(vg, cx + 18, baseY - 8 + math.sin(t * 2) * 3, "♪")
    end,
}

-- ============================================================================
-- 公共接口
-- ============================================================================

--- 推送一个经营动作动画事件
---@param eventType string 事件类型 key（如 "market_return"）
function CafeAnimEvents.Push(eventType)
    -- 设置全局变量供 UI 图片选择使用
    cafeSceneEvent_ = eventType
    local def = EVENT_DEFS[eventType]
    if not def then return end
    -- 达到上限时挤掉最老的
    if #activeEvents >= MAX_CONCURRENT then
        table.remove(activeEvents, 1)
    end
    table.insert(activeEvents, {
        type = eventType,
        def = def,
        elapsed = 0,
        duration = def.duration,
        state = "active",  -- active → fadeout → done
    })
end

--- 每帧更新（在 Render.lua HandleNanoVGRender 中调用）
---@param dt number 帧间隔
function CafeAnimEvents.Update(dt)
    local alive = {}
    for _, evt in ipairs(activeEvents) do
        evt.elapsed = evt.elapsed + dt
        local totalDuration = evt.duration + FADE_OUT
        if evt.elapsed < totalDuration then
            table.insert(alive, evt)
        end
    end
    activeEvents = alive
end

--- 绘制所有活跃事件动画
---@param vg userdata NanoVG 上下文
---@param x number 区域左上角 x
---@param y number 区域左上角 y
---@param w number 区域宽度
---@param h number 区域高度
---@param layout table 建筑布局参数
function CafeAnimEvents.DrawAll(vg, x, y, w, h, layout)
    for _, evt in ipairs(activeEvents) do
        local t = evt.elapsed
        local dur = evt.duration
        -- 计算 alpha（淡入 + 淡出）
        local alpha = 255
        if t < FADE_IN then
            alpha = math.floor(255 * (t / FADE_IN))
        elseif t > dur then
            local fadeT = t - dur
            alpha = math.floor(255 * math.max(0, 1 - fadeT / FADE_OUT))
        end
        if alpha > 0 then
            evt.def.draw(vg, math.min(t, dur), alpha, x, y, w, h, layout)
        end
    end
end

--- 清除所有活跃事件
function CafeAnimEvents.Clear()
    activeEvents = {}
end

return CafeAnimEvents
