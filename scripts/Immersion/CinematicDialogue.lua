-- ============================================================================
-- Immersion/CinematicDialogue.lua — 电影级对话系统
-- 自适应打字机 + 独白NanoVG视觉特效
-- ============================================================================
local M = {}

-- ============================================================================
-- 打字机配置
-- ============================================================================
local BASE_SPEED = 24                -- 基础字/秒（比原来的28慢一点，更有叙事感）
local MONOLOGUE_SPEED = 18           -- 独白速度（更慢，更沉浸）
local PAUSE_CHARS = {                -- 呼吸感标点（遇到这些字符暂停）
    ["。"] = 0.35,
    ["！"] = 0.25,
    ["？"] = 0.25,
    ["……"] = 0.4,
    ["，"] = 0.12,
    ["、"] = 0.08,
    ["——"] = 0.3,
    ["."] = 0.2,
    ["!"] = 0.2,
    ["?"] = 0.2,
    [","] = 0.08,
    ["…"] = 0.3,
    ["—"] = 0.2,
}

-- 打字机音效
local TYPEWRITER_SFX_PATH = "audio/sfx/sfx_typewriter_key.ogg"
local TYPEWRITER_SFX_INTERVAL = 3    -- 每3个字符播放一次音效
local TYPEWRITER_SFX_GAIN = 0.15     -- 音效音量（低调的咔哒声）

-- ============================================================================
-- 独白视觉特效配置（电影宽银幕风格）
-- ============================================================================
local VIGNETTE_ALPHA = 50            -- 暗角透明度（柔和）
local LETTERBOX_HEIGHT = 0.08        -- 上下黑条高度占比（宽银幕效果）
local LETTERBOX_ALPHA = 200          -- 黑条透明度

-- ============================================================================
-- 状态
-- ============================================================================
local typewriter_ = {
    fullText = "",
    displayLen = 0,
    speed = BASE_SPEED,
    timer = 0,
    done = false,
    isMonologue = false,
    -- 自适应暂停
    pauseTimer = 0,
    isPaused = false,
    -- 音效
    charsSinceLastSfx = 0,
}

-- 音频节点引用
local audioNode_ = nil

-- 渐显动画状态
local fadeIn_ = {
    active = false,
    elapsed = 0,
    duration = 0.6,  -- 渐显时长（秒）
}

-- ============================================================================
-- UTF-8 工具（复用 main.lua 的全局函数）
-- ============================================================================

local function utf8Len(s)
    if Utf8Len then return Utf8Len(s) end
    local len = 0
    local i = 1
    local bytes = #s
    while i <= bytes do
        local b = string.byte(s, i)
        if b < 0x80 then i = i + 1
        elseif b < 0xE0 then i = i + 2
        elseif b < 0xF0 then i = i + 3
        else i = i + 4 end
        len = len + 1
    end
    return len
end

local function utf8Sub(s, startChar, endChar)
    if Utf8Sub then return Utf8Sub(s, startChar, endChar) end
    local i = 1
    local charIdx = 0
    local startByte, endByte = 1, #s
    local bytes = #s
    while i <= bytes do
        charIdx = charIdx + 1
        if charIdx == startChar then startByte = i end
        local b = string.byte(s, i)
        local step = 1
        if b < 0x80 then step = 1
        elseif b < 0xE0 then step = 2
        elseif b < 0xF0 then step = 3
        else step = 4 end
        if charIdx == endChar then endByte = i + step - 1; break end
        i = i + step
    end
    return string.sub(s, startByte, endByte)
end

--- 获取第N个UTF-8字符
local function utf8CharAt(s, n)
    return utf8Sub(s, n, n)
end

-- ============================================================================
-- 初始化
-- ============================================================================
function M.Init(node)
    audioNode_ = node
end

-- ============================================================================
-- 打字机接口
-- ============================================================================

--- 启动打字机效果
---@param text string 完整文本
---@param isMonologue boolean 是否为独白
function M.StartTypewriter(text, isMonologue)
    typewriter_.fullText = text
    typewriter_.displayLen = 0
    typewriter_.speed = isMonologue and MONOLOGUE_SPEED or BASE_SPEED
    typewriter_.timer = 0
    typewriter_.done = false
    typewriter_.isMonologue = isMonologue or false
    typewriter_.pauseTimer = 0
    typewriter_.isPaused = false
    typewriter_.charsSinceLastSfx = 0
    -- 独白模式启动渐显
    fadeIn_.active = isMonologue or false
    fadeIn_.elapsed = 0
end

--- 跳过打字机动画
function M.SkipTypewriter()
    typewriter_.done = true
    typewriter_.displayLen = utf8Len(typewriter_.fullText)
    typewriter_.isPaused = false
end

--- 获取当前显示文本
function M.GetDisplayText()
    if typewriter_.done then return typewriter_.fullText end
    local text = utf8Sub(typewriter_.fullText, 1, typewriter_.displayLen)
    -- 闪烁光标
    return text .. "▌"
end

--- 打字机是否完成
function M.IsDone()
    return typewriter_.done
end

--- 是否为独白模式
function M.IsMonologue()
    return typewriter_.isMonologue
end

--- 获取完整文本
function M.GetFullText()
    return typewriter_.fullText
end

--- 获取渐显进度 (0~1)，用于 UI 透明度动画
function M.GetFadeAlpha()
    if not fadeIn_.active then return 1.0 end
    return math.min(1.0, fadeIn_.elapsed / fadeIn_.duration)
end

--- 更新渐显动画
function M.UpdateFadeIn(dt)
    if fadeIn_.active then
        fadeIn_.elapsed = fadeIn_.elapsed + dt
        if fadeIn_.elapsed >= fadeIn_.duration then
            fadeIn_.active = false
        end
    end
end

-- ============================================================================
-- 打字机更新
-- ============================================================================
function M.UpdateTypewriter(dt)
    if typewriter_.done then return end

    -- 暂停处理（呼吸感停顿）
    if typewriter_.isPaused then
        typewriter_.pauseTimer = typewriter_.pauseTimer - dt
        if typewriter_.pauseTimer <= 0 then
            typewriter_.isPaused = false
        end
        return
    end

    typewriter_.timer = typewriter_.timer + dt
    local charCount = utf8Len(typewriter_.fullText)
    local targetLen = math.floor(typewriter_.timer * typewriter_.speed)

    if targetLen > typewriter_.displayLen then
        -- 逐字推进，检查标点暂停
        local oldLen = typewriter_.displayLen
        typewriter_.displayLen = math.min(targetLen, charCount)

        -- 检查新显示的字符中是否有需要暂停的标点
        for ci = oldLen + 1, typewriter_.displayLen do
            local ch = utf8CharAt(typewriter_.fullText, ci)
            -- 打字音效
            typewriter_.charsSinceLastSfx = typewriter_.charsSinceLastSfx + 1
            if typewriter_.charsSinceLastSfx >= TYPEWRITER_SFX_INTERVAL then
                typewriter_.charsSinceLastSfx = 0
                M._PlayTypeSfx()
            end
            -- 检查暂停标点
            local pauseDur = PAUSE_CHARS[ch]
            if pauseDur and ci < charCount then  -- 最后一个字符不暂停
                typewriter_.isPaused = true
                ---@diagnostic disable-next-line: assign-type-mismatch
                typewriter_.pauseTimer = pauseDur
                typewriter_.displayLen = ci  -- 停在这个标点处
                break
            end
        end
    end

    if typewriter_.displayLen >= charCount then
        typewriter_.displayLen = charCount
        typewriter_.done = true
    end
end

--- 播放打字音效
function M._PlayTypeSfx()
    if not audioNode_ then return end
    local sound = cache:GetResource("Sound", TYPEWRITER_SFX_PATH)
    if not sound then return end
    local src = audioNode_:CreateComponent("SoundSource")
    src.soundType = "Effect"
    src.gain = TYPEWRITER_SFX_GAIN
    src.autoRemoveMode = REMOVE_COMPONENT
    src:Play(sound)
end

-- ============================================================================
-- 独白NanoVG视觉特效（电影宽银幕风格）
-- ============================================================================

--- 绘制独白视觉特效（在对话阶段的NanoVG渲染中调用）
---@param vg any NanoVG上下文
---@param w number 屏幕宽度
---@param h number 屏幕高度
---@param dt number 帧间隔
function M.DrawMonologueEffects(vg, w, h, dt)
    if not typewriter_.isMonologue then return end

    -- ========== 1. 柔和暗角 (vignette) ==========
    local cx, cy = w * 0.5, h * 0.5
    local radius = math.max(w, h) * 0.7
    local grad = nvgRadialGradient(vg, cx, cy, radius * 0.3, radius,
        nvgRGBA(0, 0, 0, 0), nvgRGBA(0, 0, 0, VIGNETTE_ALPHA))
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, w, h)
    nvgFillPaint(vg, grad)
    nvgFill(vg)

    -- ========== 2. 上下 Letterbox 黑条（宽银幕电影感）==========
    local barH = h * LETTERBOX_HEIGHT
    -- 顶部黑条（带渐变过渡）
    local topGrad = nvgLinearGradient(vg, 0, 0, 0, barH,
        nvgRGBA(0, 0, 0, LETTERBOX_ALPHA), nvgRGBA(0, 0, 0, 0))
    nvgBeginPath(vg)
    nvgRect(vg, 0, 0, w, barH)
    nvgFillPaint(vg, topGrad)
    nvgFill(vg)
    -- 底部黑条（带渐变过渡）
    local botGrad = nvgLinearGradient(vg, 0, h - barH, 0, h,
        nvgRGBA(0, 0, 0, 0), nvgRGBA(0, 0, 0, LETTERBOX_ALPHA))
    nvgBeginPath(vg)
    nvgRect(vg, 0, h - barH, w, barH)
    nvgFillPaint(vg, botGrad)
    nvgFill(vg)
end

return M
