---@diagnostic disable: undefined-global
local CafeRenderer = require("CafeRenderer")
local CafeAnimEvents = require("CafeAnimEvents")

-- ============================================================================
-- 9. NanoVG 过场动画渲染
-- ============================================================================
--- 更新客流动画状态（在 HandleUpdate 中调用）
function UpdateCustomerAnim(dt)
    if currentPhase_ ~= PHASE_MANAGE then
        customerAnim_.figures = {}
        return
    end
    local traffic = RefreshTraffic()
    local capacity = CalcCafeCapacity()
    local ratio = traffic / math.max(1, capacity)
    -- 根据客流比例决定活跃人物数量（3~12）
    local maxFigures = math.max(3, math.min(12, math.floor(ratio * 8)))

    -- 生成新人物
    customerAnim_.spawnTimer = customerAnim_.spawnTimer + dt
    local spawnInterval = ratio >= 1.0 and 0.6 or (ratio >= 0.5 and 1.2 or 2.0)
    if customerAnim_.spawnTimer >= spawnInterval and #customerAnim_.figures < maxFigures then
        customerAnim_.spawnTimer = 0
        local dir = math.random() > 0.5 and 1 or -1
        table.insert(customerAnim_.figures, {
            x = dir > 0 and -20 or 1000,
            speed = (20 + math.random() * 25) * dir,
            headR = 3 + math.random() * 2,
            bodyH = 6 + math.random() * 4,
            alpha = 120 + math.random(0, 80),
            hue = math.random(0, 5),  -- 颜色变化索引
        })
    end

    -- 更新位置，移除出界的
    local alive = {}
    for _, f in ipairs(customerAnim_.figures) do
        f.x = f.x + f.speed * dt
        if f.x > -30 and f.x < 1030 then
            table.insert(alive, f)
        end
    end
    customerAnim_.figures = alive
end

--- 绘制客流小人动画（NanoVG）
function DrawCustomerAnim(vg, w, h)
    local bandH = 32
    local bandY = h - bandH
    -- 半透明背景条
    nvgBeginPath(vg)
    nvgRect(vg, 0, bandY, w, bandH)
    nvgFillColor(vg, nvgRGBA(20, 50, 20, 70))
    nvgFill(vg)

    -- 颜色方案
    local hues = {
        { 255, 185, 50 },   -- 金
        { 80, 220, 120 },   -- 绿
        { 80, 160, 255 },   -- 蓝
        { 240, 130, 80 },   -- 橙
        { 200, 100, 240 },  -- 紫
        { 255, 100, 100 },  -- 红
    }

    for _, f in ipairs(customerAnim_.figures) do
        local sx = f.x / 1000 * w
        local sy = bandY + bandH * 0.55
        local c = hues[(f.hue % #hues) + 1]
        local a = f.alpha
        -- 头（圆）
        nvgBeginPath(vg)
        nvgCircle(vg, sx, sy - f.bodyH - f.headR, f.headR)
        nvgFillColor(vg, nvgRGBA(c[1], c[2], c[3], a))
        nvgFill(vg)
        -- 身体（矩形）
        nvgBeginPath(vg)
        nvgRoundedRect(vg, sx - 2.5, sy - f.bodyH, 5, f.bodyH, 1.5)
        nvgFillColor(vg, nvgRGBA(c[1], c[2], c[3], math.floor(a * 0.8)))
        nvgFill(vg)
        -- 腿（两条短线，带行走动画）
        local legPhase = math.sin(gameTime_ * 6 + f.x * 0.1)
        nvgBeginPath(vg)
        nvgMoveTo(vg, sx - 1, sy)
        nvgLineTo(vg, sx - 1 + legPhase * 3, sy + 5)
        nvgMoveTo(vg, sx + 1, sy)
        nvgLineTo(vg, sx + 1 - legPhase * 3, sy + 5)
        nvgStrokeColor(vg, nvgRGBA(c[1], c[2], c[3], math.floor(a * 0.7)))
        nvgStrokeWidth(vg, 1.5)
        nvgStroke(vg)
    end

    -- 客流提示文字
    if #customerAnim_.figures > 0 then
        local traffic = RefreshTraffic()
        local capacity = CalcCafeCapacity()
        nvgFontFace(vg, "trans")
        nvgFontSize(vg, 11)
        nvgTextAlign(vg, NVG_ALIGN_RIGHT + NVG_ALIGN_MIDDLE)
        nvgFillColor(vg, nvgRGBA(255, 210, 70, 140))
        nvgText(vg, w - 8, bandY + bandH * 0.5, "客流 " .. traffic .. "/" .. capacity)
    end
end

--- 触发庆祝粒子动画
function TriggerCelebration()
    celebration_.active = true
    celebration_.timer = 0
    -- 追加模式：多个里程碑同帧触发时不丢弃前一次粒子
    if not celebration_.particles then celebration_.particles = {} end
    for i = 1, 40 do
        local angle = math.random() * math.pi * 2
        local speed = 80 + math.random() * 200
        local colors = {
            { 255, 210, 70 }, { 100, 200, 255 }, { 255, 100, 100 },
            { 100, 255, 150 }, { 255, 200, 120 }, { 255, 180, 50 },
        }
        local c = colors[math.random(1, #colors)]
        table.insert(celebration_.particles, {
            x = 0.5, y = 0.5,          -- normalized position (center)
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 100,  -- upward bias
            size = 4 + math.random() * 6,
            r = c[1], g = c[2], b = c[3], a = 255,
            life = 0.8 + math.random() * 1.7,
        })
    end
end

--- 更新+绘制庆祝粒子
function DrawCelebration(vg, w, h, dt)
    if not celebration_.active then return end
    celebration_.timer = celebration_.timer + dt
    if celebration_.timer > celebration_.duration then
        celebration_.active = false
        celebration_.particles = {}
        return
    end
    for _, p in ipairs(celebration_.particles) do
        p.life = p.life - dt
        if p.life > 0 then
            p.x = p.x + p.vx * dt / w
            p.y = p.y + p.vy * dt / h
            p.vy = p.vy + 120 * dt  -- gravity
            local fade = math.min(1, p.life / 0.5)
            nvgBeginPath(vg)
            nvgCircle(vg, p.x * w, p.y * h, p.size * fade)
            nvgFillColor(vg, nvgRGBA(p.r, p.g, p.b, math.floor(p.a * fade)))
            nvgFill(vg)
        end
    end
end

function HandleNanoVGRender(eventType, eventData)
    if not nvgContext_ then return end
    local showCustomers = (currentPhase_ == PHASE_MANAGE and #customerAnim_.figures > 0)
    local showCelebration = celebration_.active
    local showTransition = transition_.active or transition_.alpha > 0 or CinematicTransition.IsActive()
    local showMonologue = (currentPhase_ == PHASE_DIALOGUE and CinematicDialogue.IsMonologue())
    if not showTransition and not showCustomers and not showCelebration and not showMonologue then return end

    local dpr = graphics:GetDPR()
    local w = graphics:GetWidth() / dpr
    local h = graphics:GetHeight() / dpr
    nvgBeginFrame(nvgContext_, w, h, dpr)

    -- 客流动画（管理界面底部）
    if showCustomers then
        DrawCustomerAnim(nvgContext_, w, h)
    end

    -- 过场动画（电影级过渡）
    CinematicTransition.Draw(nvgContext_, w, h)

    -- 独白视觉特效（暗角 + 扫描线 + 灰尘微粒）
    if currentPhase_ == PHASE_DIALOGUE then
        CinematicDialogue.DrawMonologueEffects(nvgContext_, w, h, lastDt_)
    end

    -- 庆祝粒子效果（最上层）
    DrawCelebration(nvgContext_, w, h, lastDt_)

    nvgEndFrame(nvgContext_)
end

