-- ============================================================================
-- Immersion/CinematicTransition.lua — 电影级过渡动画
-- 支持：信封式遮罩、粒子飘浮、呼吸感文字、easing缓动
-- ============================================================================
local M = {}

-- ============================================================================
-- 配置（电影级 vs 快速过渡自动选择）
-- ============================================================================
-- 电影级（有标题/章节号的剧情过渡）
local CINEMATIC_FADE_OUT  = 0.6
local CINEMATIC_HOLD      = 1.6
local CINEMATIC_FADE_IN   = 0.8
-- 快速过渡（无标题的场景切换）
local QUICK_FADE_OUT = 0.3
local QUICK_HOLD     = 0.15
local QUICK_FADE_IN  = 0.35

-- 运行时使用的时长（Start 时根据内容自动选择）
local FADE_OUT_DUR = CINEMATIC_FADE_OUT
local HOLD_DUR = CINEMATIC_HOLD
local FADE_IN_DUR = CINEMATIC_FADE_IN
local TITLE_FADE_IN_DUR = 0.5  -- 标题淡入时长
local SUBTITLE_DELAY = 0.3     -- 副标题延迟出现
local SUBTITLE_FADE_IN_DUR = 0.4

-- 粒子配置
local DUST_COUNT = 20          -- 灰尘微粒数量
local DUST_SPEED = 8           -- 微粒飘浮速度

-- ============================================================================
-- 状态
-- ============================================================================
local state_ = {
    active = false,
    phase = "none",        -- "fadeOut" | "hold" | "fadeIn" | "none"
    timer = 0,
    totalTime = 0,
    alpha = 0,
    titleText = "",
    subtitleText = "",
    atmosphereText = "",   -- 新增：氛围描述文字
    chapterNum = 0,        -- 新增：章节编号（用于显示 "Chapter X"）
    onMidpoint = nil,
    midpointCalled = false,
    -- 标题动画
    titleAlpha = 0,
    subtitleAlpha = 0,
    holdTimer = 0,
    -- 灰尘粒子
    dustParticles = {},
}

-- ============================================================================
-- Easing 函数
-- ============================================================================
local function easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local p = 2 * t - 2
        return 0.5 * p * p * p + 1
    end
end

local function easeOutQuad(t)
    return t * (2 - t)
end

local function easeInQuad(t)
    return t * t
end

-- ============================================================================
-- 灰尘粒子
-- ============================================================================
local function InitDustParticles()
    state_.dustParticles = {}
    for i = 1, DUST_COUNT do
        table.insert(state_.dustParticles, {
            x = math.random() * 100,   -- 百分比位置
            y = math.random() * 100,
            size = 1 + math.random() * 2.5,
            alpha = 20 + math.random(0, 40),
            speedX = (math.random() - 0.5) * DUST_SPEED,
            speedY = -0.5 - math.random() * 1.5,  -- 缓慢上升
            phase = math.random() * math.pi * 2,   -- 闪烁相位
        })
    end
end

-- ============================================================================
-- 公共接口
-- ============================================================================

--- 启动电影级过渡动画
---@param opts table { title, subtitle, atmosphere, chapterNum, onMidpoint }
function M.Start(opts)
    opts = opts or {}
    state_.active = true
    state_.phase = "fadeOut"
    state_.timer = 0
    state_.totalTime = 0
    state_.alpha = 0
    state_.titleText = opts.title or ""
    state_.subtitleText = opts.subtitle or ""
    state_.atmosphereText = opts.atmosphere or ""
    state_.chapterNum = opts.chapterNum or 0
    state_.onMidpoint = opts.onMidpoint
    state_.midpointCalled = false
    state_.titleAlpha = 0
    state_.subtitleAlpha = 0
    state_.holdTimer = 0

    -- 根据内容自动选择时序：有标题或章节号 → 电影级，否则 → 快速
    local isCinematic = (state_.titleText ~= "" or state_.chapterNum > 0)
    if isCinematic then
        FADE_OUT_DUR = CINEMATIC_FADE_OUT
        HOLD_DUR     = CINEMATIC_HOLD
        FADE_IN_DUR  = CINEMATIC_FADE_IN
    else
        FADE_OUT_DUR = QUICK_FADE_OUT
        HOLD_DUR     = QUICK_HOLD
        FADE_IN_DUR  = QUICK_FADE_IN
    end
    state_.isCinematic = isCinematic

    if isCinematic then
        InitDustParticles()
    else
        state_.dustParticles = {}
    end
end

--- 是否正在播放过渡动画
function M.IsActive()
    return state_.active
end

--- 获取当前遮罩透明度（用于外部判断是否需要绘制NanoVG）
function M.GetAlpha()
    return state_.alpha
end

-- ============================================================================
-- 更新逻辑
-- ============================================================================
function M.Update(dt)
    if not state_.active then return end
    state_.timer = state_.timer + dt
    state_.totalTime = state_.totalTime + dt

    -- 超时保护：6秒强制结束
    if state_.totalTime > 6.0 then
        print("[CinematicTransition] timeout! forcing end")
        state_.active = false
        state_.phase = "none"
        state_.alpha = 0
        return
    end

    if state_.phase == "fadeOut" then
        local t = math.min(1.0, state_.timer / FADE_OUT_DUR)
        state_.alpha = easeInOutCubic(t)
        if t >= 1.0 then
            state_.phase = "hold"
            state_.timer = 0
            state_.holdTimer = 0
            -- 执行切换回调
            if state_.onMidpoint and not state_.midpointCalled then
                state_.midpointCalled = true
                local ok, err = pcall(state_.onMidpoint)
                if not ok then
                    print("[CinematicTransition] onMidpoint error: " .. tostring(err))
                    state_.active = false
                    state_.phase = "none"
                    state_.alpha = 0
                    return
                end
            end
        end

    elseif state_.phase == "hold" then
        state_.alpha = 1.0
        state_.holdTimer = state_.holdTimer + dt

        -- 标题渐显
        local titleT = math.min(1.0, state_.holdTimer / TITLE_FADE_IN_DUR)
        state_.titleAlpha = easeOutQuad(titleT)

        -- 副标题延迟渐显
        local subT = math.max(0, state_.holdTimer - SUBTITLE_DELAY)
        local subAlpha = math.min(1.0, subT / SUBTITLE_FADE_IN_DUR)
        state_.subtitleAlpha = easeOutQuad(subAlpha)

        if state_.timer >= HOLD_DUR then
            state_.phase = "fadeIn"
            state_.timer = 0
        end

    elseif state_.phase == "fadeIn" then
        local t = math.min(1.0, state_.timer / FADE_IN_DUR)
        state_.alpha = 1.0 - easeInOutCubic(t)
        if t >= 1.0 then
            state_.active = false
            state_.phase = "none"
            state_.alpha = 0
        end
    end

    -- 更新灰尘粒子
    for _, p in ipairs(state_.dustParticles) do
        p.x = p.x + p.speedX * dt * 0.1
        p.y = p.y + p.speedY * dt * 0.1
        p.phase = p.phase + dt * 1.5
        -- 循环
        if p.y < -5 then p.y = 105 end
        if p.x < -5 then p.x = 105 end
        if p.x > 105 then p.x = -5 end
    end
end

-- ============================================================================
-- NanoVG 渲染
-- ============================================================================

--- 绘制电影级过渡动画（在NanoVGRender事件中调用）
---@param vg any NanoVG上下文
---@param w number 屏幕宽度
---@param h number 屏幕高度
function M.Draw(vg, w, h)
    if not state_.active and state_.alpha <= 0 then return end

    local a = math.floor(state_.alpha * 255)

    -- ========== 1. 遮罩 ==========
    if state_.isCinematic then
        -- 电影级：信封式遮罩（上下两块黑条向中间合拢）
        local halfH = h * 0.5
        local coverH = halfH * state_.alpha
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, w, coverH)
        nvgFillColor(vg, nvgRGBA(30, 25, 15, a))
        nvgFill(vg)
        nvgBeginPath(vg)
        nvgRect(vg, 0, h - coverH, w, coverH)
        nvgFillColor(vg, nvgRGBA(30, 25, 15, a))
        nvgFill(vg)
        if coverH * 2 >= h then
            nvgBeginPath(vg)
            nvgRect(vg, 0, 0, w, h)
            nvgFillColor(vg, nvgRGBA(30, 25, 15, a))
            nvgFill(vg)
        end
    else
        -- 快速：简单全屏黑幕
        nvgBeginPath(vg)
        nvgRect(vg, 0, 0, w, h)
        nvgFillColor(vg, nvgRGBA(0, 0, 0, a))
        nvgFill(vg)
    end

    -- ========== 2. 灰尘微粒（仅在hold阶段可见）==========
    if state_.phase == "hold" then
        for _, p in ipairs(state_.dustParticles) do
            local flicker = 0.5 + 0.5 * math.sin(p.phase)
            local pa = math.floor(p.alpha * flicker * state_.titleAlpha)
            nvgBeginPath(vg)
            nvgCircle(vg, p.x * w * 0.01, p.y * h * 0.01, p.size)
            nvgFillColor(vg, nvgRGBA(255, 210, 70, pa))
            nvgFill(vg)
        end
    end

    -- ========== 3. 文字渲染（hold阶段）==========
    if state_.phase == "hold" and state_.titleAlpha > 0 then
        nvgFontFace(vg, "trans")

        -- 章节编号（小字，顶部偏上）
        if state_.chapterNum > 0 then
            local numAlpha = math.floor(state_.titleAlpha * 120)
            nvgFontSize(vg, 13)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            nvgFillColor(vg, nvgRGBA(160, 130, 90, numAlpha))
            -- 上移动画：从 0.38 移到 0.36
            local numY = h * (0.38 - state_.titleAlpha * 0.02)
            nvgText(vg, w * 0.5, numY, "— Chapter " .. state_.chapterNum .. " —")
        end

        -- 主标题（大字，居中偏上）
        if state_.titleText ~= "" then
            local ta = math.floor(state_.titleAlpha * 255)
            nvgFontSize(vg, 30)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            -- 呼吸感：微弱的缩放感通过字号变化模拟
            local breathe = 1.0 + math.sin(state_.holdTimer * 1.5) * 0.01
            nvgFontSize(vg, 30 * breathe)
            nvgFillColor(vg, nvgRGBA(255, 210, 70, ta))
            nvgText(vg, w * 0.5, h * 0.44, state_.titleText)
        end

        -- 副标题/氛围文字（小字，居中偏下）
        if state_.subtitleAlpha > 0 then
            local sa = math.floor(state_.subtitleAlpha * 160)
            local displayText = state_.atmosphereText ~= "" and state_.atmosphereText or state_.subtitleText
            nvgFontSize(vg, 13)
            nvgTextAlign(vg, NVG_ALIGN_CENTER + NVG_ALIGN_MIDDLE)
            nvgFillColor(vg, nvgRGBA(160, 130, 90, sa))
            -- 多行文字处理（手动换行，每行最多30个字符）
            local lines = M._WrapText(displayText, 28)
            local lineH = 20
            local startY = h * 0.54
            for i, line in ipairs(lines) do
                nvgText(vg, w * 0.5, startY + (i - 1) * lineH, line)
            end
        end

        -- ========== 4. 电影宽屏黑边（上下两条细线）==========
        local barAlpha = math.floor(state_.titleAlpha * 40)
        -- 上方装饰线
        nvgBeginPath(vg)
        nvgRect(vg, w * 0.15, h * 0.32, w * 0.7, 1)
        nvgFillColor(vg, nvgRGBA(255, 210, 70, barAlpha))
        nvgFill(vg)
        -- 下方装饰线
        nvgBeginPath(vg)
        nvgRect(vg, w * 0.15, h * 0.65, w * 0.7, 1)
        nvgFillColor(vg, nvgRGBA(255, 210, 70, barAlpha))
        nvgFill(vg)
    end

    -- ========== 5. 边缘暗角（vignette）==========
    if state_.alpha > 0.3 then
        local vigAlpha = math.floor(math.min(1, (state_.alpha - 0.3) / 0.7) * 80)
        -- 四角暗角（径向渐变模拟）
        local corners = {
            { 0, 0 }, { w, 0 }, { 0, h }, { w, h },
        }
        for _, c in ipairs(corners) do
            local grad = nvgRadialGradient(vg, c[1], c[2], 0, w * 0.4,
                nvgRGBA(0, 0, 0, vigAlpha), nvgRGBA(0, 0, 0, 0))
            nvgBeginPath(vg)
            nvgRect(vg, c[1] - w * 0.4, c[2] - h * 0.4, w * 0.8, h * 0.8)
            nvgFillPaint(vg, grad)
            nvgFill(vg)
        end
    end
end

-- ============================================================================
-- 工具函数
-- ============================================================================

--- 简单的中文文本自动换行
function M._WrapText(text, maxChars)
    if not text or text == "" then return {} end
    local lines = {}
    local i = 1
    local bytes = #text
    local charCount = 0
    local lineStart = 1

    while i <= bytes do
        local b = string.byte(text, i)
        local step = 1
        if b < 0x80 then step = 1
        elseif b < 0xE0 then step = 2
        elseif b < 0xF0 then step = 3
        else step = 4 end

        charCount = charCount + 1
        if charCount >= maxChars then
            table.insert(lines, string.sub(text, lineStart, i + step - 1))
            lineStart = i + step
            charCount = 0
        end
        i = i + step
    end
    if lineStart <= bytes then
        table.insert(lines, string.sub(text, lineStart))
    end
    return lines
end

return M
