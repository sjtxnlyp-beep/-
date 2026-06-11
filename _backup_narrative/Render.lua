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

-- ============================================================================
-- 微反馈视觉动画系统 (Module C)
-- ============================================================================

--- 触发金钱变动浮动文字
---@param amount number 变动数额（正=收入，负=支出）
---@param originX number|nil 归一化X位置(0-1)，默认右上角
---@param originY number|nil 归一化Y位置(0-1)
function MFX_MoneyPop(amount, originX, originY)
    if not microFX_ or amount == 0 then return end
    local text, color
    if amount > 0 then
        text = "+$" .. amount
        color = { 50, 205, 100 }  -- green
    else
        text = "-$" .. math.abs(amount)
        color = { 255, 80, 80 }   -- red
    end
    local x = originX or 0.82
    local y = originY or 0.06
    -- 小偏移避免重叠
    local offset = #microFX_.floats * 0.03
    table.insert(microFX_.floats, {
        text = text,
        x = x + (math.random() - 0.5) * 0.04,
        y = y + offset,
        timer = 0,
        duration = 1.4,
        color = color,
        fontSize = amount > 0 and math.min(22, 14 + amount / 50) or 15,
        vx = 0,
        vy = -0.08,  -- float upward (normalized per sec)
    })
end

--- 触发AP消耗粒子喷射
---@param cost number AP消耗量
function MFX_APBurst(cost)
    if not microFX_ or not cost or cost <= 0 then return end
    local particles = {}
    local count = math.min(12, 4 + cost)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 40 + math.random() * 80
        table.insert(particles, {
            x = 0.35, y = 0.06,  -- AP bar approximate position
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 30,
            life = 0.5 + math.random() * 0.4,
            r = 100, g = 180, b = 255,  -- blue AP color
            size = 2 + math.random() * 2,
        })
    end
    table.insert(microFX_.bursts, {
        particles = particles,
        timer = 0,
        duration = 1.2,
    })
end

--- 触发升级完成闪光脉冲
function MFX_UpgradeFlash()
    if not microFX_ then return end
    table.insert(microFX_.pulses, {
        timer = 0,
        duration = 0.6,
        color = { 255, 210, 70 },  -- golden
        intensity = 0.3,
    })
end

--- 触发威胁脉冲（Victor等敌对事件）
function MFX_ThreatPulse()
    if not microFX_ then return end
    table.insert(microFX_.pulses, {
        timer = 0,
        duration = 0.8,
        color = { 200, 30, 30 },  -- dark red
        intensity = 0.2,
    })
end

--- 触发第四面墙彩蛋文字
---@param text string 彩蛋文字
function MFX_Easter(text)
    if not microFX_ then return end
    microFX_.easter = {
        text = text,
        timer = 0,
        duration = 3.0,
        alpha = 0,
    }
end

--- 更新+绘制微反馈动画
function DrawMicroFeedback(vg, w, h, dt)
    if not microFX_ then return end

    -- 1) 浮动文字
    local i = 1
    while i <= #microFX_.floats do
        local f = microFX_.floats[i]
        f.timer = f.timer + dt
        if f.timer >= f.duration then
            table.remove(microFX_.floats, i)
        else
            local progress = f.timer / f.duration
            -- 缓动：先快后慢
            local ease = 1 - (1 - progress) * (1 - progress)
            f.x = f.x + f.vx * dt
            f.y = f.y + f.vy * dt
            -- 淡出
            local alpha = progress < 0.7 and 255 or math.floor(255 * (1 - (progress - 0.7) / 0.3))
            -- 弹跳缩放
            local scale = 1.0
            if progress < 0.15 then
                scale = 1.0 + 0.3 * math.sin(progress / 0.15 * math.pi)
            end
            nvgFontFace(vg, "trans")
            nvgFontSize(vg, f.fontSize * scale)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            -- 描边
            nvgFillColor(vg, nvgRGBA(0, 0, 0, math.floor(alpha * 0.6)))
            nvgText(vg, f.x * w + 1, f.y * h + 1, f.text)
            -- 正文
            nvgFillColor(vg, nvgRGBA(f.color[1], f.color[2], f.color[3], alpha))
            nvgText(vg, f.x * w, f.y * h, f.text)
            i = i + 1
        end
    end

    -- 2) 粒子喷射
    local j = 1
    while j <= #microFX_.bursts do
        local b = microFX_.bursts[j]
        b.timer = b.timer + dt
        if b.timer >= b.duration then
            table.remove(microFX_.bursts, j)
        else
            for _, p in ipairs(b.particles) do
                p.life = p.life - dt
                if p.life > 0 then
                    p.x = p.x + p.vx * dt / w
                    p.y = p.y + p.vy * dt / h
                    p.vy = p.vy + 80 * dt  -- gravity
                    local fade = math.min(1, p.life / 0.3)
                    nvgBeginPath(vg)
                    nvgCircle(vg, p.x * w, p.y * h, p.size * fade)
                    nvgFillColor(vg, nvgRGBA(p.r, p.g, p.b, math.floor(200 * fade)))
                    nvgFill(vg)
                end
            end
            j = j + 1
        end
    end

    -- 3) 脉冲闪光（全屏边缘泛光）
    local k = 1
    while k <= #microFX_.pulses do
        local p = microFX_.pulses[k]
        p.timer = p.timer + dt
        if p.timer >= p.duration then
            table.remove(microFX_.pulses, k)
        else
            local progress = p.timer / p.duration
            -- 快速亮起，缓慢消退
            local glow = progress < 0.2 and (progress / 0.2) or (1 - (progress - 0.2) / 0.8)
            local alpha = math.floor(glow * p.intensity * 255)
            if alpha > 0 then
                -- 绘制四边泛光条
                local thickness = 30 * glow
                nvgBeginPath(vg)
                nvgRect(vg, 0, 0, w, thickness)            -- top
                nvgRect(vg, 0, h - thickness, w, thickness) -- bottom
                nvgRect(vg, 0, 0, thickness, h)            -- left
                nvgRect(vg, w - thickness, 0, thickness, h) -- right
                nvgFillColor(vg, nvgRGBA(p.color[1], p.color[2], p.color[3], alpha))
                nvgFill(vg)
            end
            k = k + 1
        end
    end

    -- 4) 第四面墙彩蛋
    if microFX_.easter then
        local e = microFX_.easter
        e.timer = e.timer + dt
        if e.timer >= e.duration then
            microFX_.easter = nil
        else
            local progress = e.timer / e.duration
            -- 淡入(0-0.2)，停留(0.2-0.8)，淡出(0.8-1.0)
            if progress < 0.2 then
                e.alpha = progress / 0.2
            elseif progress > 0.8 then
                e.alpha = (1.0 - progress) / 0.2
            else
                e.alpha = 1.0
            end
            local alpha = math.floor(e.alpha * 180)
            nvgFontFace(vg, "trans")
            nvgFontSize(vg, 11)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_BOTTOM)
            -- 背景条
            local tw = 200
            nvgBeginPath(vg)
            nvgRoundedRect(vg, (w - tw) * 0.5, h - 38, tw, 22, 4)
            nvgFillColor(vg, nvgRGBA(0, 0, 0, math.floor(alpha * 0.5)))
            nvgFill(vg)
            -- 文字
            nvgFillColor(vg, nvgRGBA(200, 200, 200, alpha))
            nvgText(vg, w * 0.5, h - 20, e.text)
        end
    end
end

--- 检查是否有微反馈动画活跃
function IsMicroFXActive()
    if not microFX_ then return false end
    if #microFX_.floats > 0 then return true end
    if #microFX_.bursts > 0 then return true end
    if #microFX_.pulses > 0 then return true end
    if microFX_.easter then return true end
    return false
end

function HandleNanoVGRender(eventType, eventData)
    if not nvgContext_ then return end
    local showCustomers = (currentPhase_ == PHASE_MANAGE and #customerAnim_.figures > 0)
    local showCelebration = celebration_.active
    local showTransition = transition_.active or transition_.alpha > 0 or CinematicTransition.IsActive()
    local showMonologue = (currentPhase_ == PHASE_DIALOGUE and CinematicDialogue.IsMonologue())
    local showMicroFX = IsMicroFXActive()
    if not showTransition and not showCustomers and not showCelebration and not showMonologue and not showMicroFX then return end

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

    -- 庆祝粒子效果
    DrawCelebration(nvgContext_, w, h, lastDt_)

    -- 微反馈动画（最上层）
    DrawMicroFeedback(nvgContext_, w, h, lastDt_)

    nvgEndFrame(nvgContext_)
end

