-- ============================================================================
-- Immersion/AudioDirector.lua — 音频导演（BGM交叉淡入淡出 + 环境音景）
-- ============================================================================
local M = {}

-- ============================================================================
-- 配置
-- ============================================================================
local BGM_CROSSFADE_DURATION = 1.5   -- BGM交叉淡入淡出时长（秒）
local BGM_DEFAULT_GAIN = 0.45
local AMBIENT_DEFAULT_GAIN = 0.25
local AMBIENT_FADE_DURATION = 2.0    -- 环境音淡入淡出时长

-- 环境音路径映射
local AMBIENT_PATHS = {
    night_crickets  = "audio/sfx/ambient_night_crickets.ogg",
    cafe_busy       = "audio/sfx/ambient_cafe_busy.ogg",
    rain_tin_roof   = "audio/sfx/ambient_rain_tin_roof.ogg",
    generator_hum   = "audio/sfx/ambient_generator_hum.ogg",
}

-- ============================================================================
-- 状态
-- ============================================================================
local audioNode_ = nil

-- BGM 交叉淡入淡出状态
local bgmCurrent_ = {
    source = nil,       -- SoundSource
    key = "",           -- 当前曲目key
    gain = 0,           -- 当前增益
    targetGain = 0,     -- 目标增益
}
local bgmNext_ = {
    source = nil,
    key = "",
    gain = 0,
    targetGain = 0,
}
local bgmFading_ = false
local bgmFadeTimer_ = 0

-- 环境音状态
local ambientCurrent_ = {
    source = nil,
    key = "",
    gain = 0,
    targetGain = 0,
}
local ambientFading_ = false
local ambientFadeTimer_ = 0
local ambientNextKey_ = ""

-- BGM 路径（从 main.lua 传入）
local bgmPaths_ = {}

-- ============================================================================
-- 初始化
-- ============================================================================
function M.Init(node, bgmPaths)
    audioNode_ = node
    bgmPaths_ = bgmPaths or {}
end

-- ============================================================================
-- BGM 交叉淡入淡出
-- ============================================================================

--- 播放BGM（带交叉淡入淡出效果）
---@param key string BGM键名
function M.PlayBGM(key)
    if key == bgmCurrent_.key and not bgmFading_ then return end
    if bgmFading_ and key == bgmNext_.key then return end

    local path = bgmPaths_[key]
    if not path or not audioNode_ then return end
    local sound = cache:GetResource("Sound", path)
    if not sound then
        print("[AudioDirector] BGM not found: " .. tostring(path))
        return
    end
    sound.looped = true

    -- 如果正在淡入淡出，立即完成当前的
    if bgmFading_ then
        M._FinishBGMFade()
    end

    -- 如果没有当前播放的BGM，直接淡入
    if not bgmCurrent_.source then
        local src = audioNode_:CreateComponent("SoundSource")
        src.soundType = "Music"
        src.gain = 0
        src:Play(sound)
        bgmCurrent_.source = src
        bgmCurrent_.key = key
        bgmCurrent_.gain = 0
        bgmCurrent_.targetGain = BGM_DEFAULT_GAIN
        bgmFading_ = true
        bgmFadeTimer_ = 0
        -- 单独淡入模式
        bgmNext_.source = nil
        bgmNext_.key = ""
        print("[AudioDirector] BGM fade in: " .. key)
        return
    end

    -- 交叉淡入淡出：创建新的source，淡出旧的淡入新的
    local src = audioNode_:CreateComponent("SoundSource")
    src.soundType = "Music"
    src.gain = 0
    src:Play(sound)
    bgmNext_.source = src
    bgmNext_.key = key
    bgmNext_.gain = 0
    bgmNext_.targetGain = BGM_DEFAULT_GAIN
    bgmCurrent_.targetGain = 0  -- 旧的淡出
    bgmFading_ = true
    bgmFadeTimer_ = 0
    print("[AudioDirector] BGM crossfade: " .. bgmCurrent_.key .. " -> " .. key)
end

--- 停止BGM（带淡出）
function M.StopBGM()
    if bgmCurrent_.source then
        bgmCurrent_.targetGain = 0
        bgmFading_ = true
        bgmFadeTimer_ = 0
        bgmNext_.source = nil
        bgmNext_.key = ""
    end
end

--- 立即停止所有BGM（无淡出）
function M.StopBGMImmediate()
    if bgmCurrent_.source then
        bgmCurrent_.source:Stop()
        audioNode_:RemoveComponent(bgmCurrent_.source)
        bgmCurrent_.source = nil
        bgmCurrent_.key = ""
        bgmCurrent_.gain = 0
    end
    if bgmNext_.source then
        bgmNext_.source:Stop()
        audioNode_:RemoveComponent(bgmNext_.source)
        bgmNext_.source = nil
        bgmNext_.key = ""
        bgmNext_.gain = 0
    end
    bgmFading_ = false
end

function M._FinishBGMFade()
    -- 完成交叉淡入淡出
    if bgmCurrent_.source and bgmCurrent_.targetGain <= 0 then
        bgmCurrent_.source:Stop()
        audioNode_:RemoveComponent(bgmCurrent_.source)
        bgmCurrent_.source = nil
    end
    if bgmNext_.source then
        -- 新的变成当前的
        if bgmCurrent_.source and bgmCurrent_.source ~= bgmNext_.source then
            bgmCurrent_.source:Stop()
            audioNode_:RemoveComponent(bgmCurrent_.source)
        end
        bgmCurrent_.source = bgmNext_.source
        bgmCurrent_.key = bgmNext_.key
        bgmCurrent_.gain = bgmNext_.targetGain
        if bgmCurrent_.source then
            bgmCurrent_.source.gain = bgmCurrent_.gain
        end
        bgmCurrent_.targetGain = bgmCurrent_.gain
        bgmNext_.source = nil
        bgmNext_.key = ""
        bgmNext_.gain = 0
    end
    bgmFading_ = false
end

-- ============================================================================
-- 环境音景
-- ============================================================================

--- 播放环境音（带淡入效果）
---@param key string 环境音键名 (night_crickets/cafe_busy/rain_tin_roof/generator_hum)
function M.PlayAmbient(key)
    if key == "none" or key == "" or key == nil then
        M.StopAmbient()
        return
    end
    if key == ambientCurrent_.key and not ambientFading_ then return end

    local path = AMBIENT_PATHS[key]
    if not path or not audioNode_ then return end
    local sound = cache:GetResource("Sound", path)
    if not sound then
        print("[AudioDirector] Ambient not found: " .. tostring(path))
        return
    end
    sound.looped = true

    -- 如果有当前环境音，先淡出再换
    if ambientCurrent_.source then
        ambientCurrent_.targetGain = 0
        ambientFading_ = true
        ambientFadeTimer_ = 0
        ambientNextKey_ = key
        return
    end

    -- 直接淡入
    local src = audioNode_:CreateComponent("SoundSource")
    src.soundType = "Ambient"
    src.gain = 0
    src:Play(sound)
    ambientCurrent_.source = src
    ambientCurrent_.key = key
    ambientCurrent_.gain = 0
    ambientCurrent_.targetGain = AMBIENT_DEFAULT_GAIN
    ambientFading_ = true
    ambientFadeTimer_ = 0
    ambientNextKey_ = ""
    print("[AudioDirector] Ambient fade in: " .. key)
end

--- 停止环境音（带淡出）
function M.StopAmbient()
    if ambientCurrent_.source then
        ambientCurrent_.targetGain = 0
        ambientFading_ = true
        ambientFadeTimer_ = 0
        ambientNextKey_ = ""
    end
end

--- 立即停止环境音
function M.StopAmbientImmediate()
    if ambientCurrent_.source then
        ambientCurrent_.source:Stop()
        audioNode_:RemoveComponent(ambientCurrent_.source)
        ambientCurrent_.source = nil
        ambientCurrent_.key = ""
        ambientCurrent_.gain = 0
    end
    ambientFading_ = false
    ambientNextKey_ = ""
end

-- ============================================================================
-- 每帧更新（必须在 HandleUpdate 中调用）
-- ============================================================================
function M.Update(dt)
    -- BGM 交叉淡入淡出
    if bgmFading_ then
        bgmFadeTimer_ = bgmFadeTimer_ + dt
        local t = math.min(1.0, bgmFadeTimer_ / BGM_CROSSFADE_DURATION)
        -- 平滑曲线（ease in-out）
        local ease = t * t * (3 - 2 * t)

        -- 更新当前BGM音量
        if bgmCurrent_.source then
            bgmCurrent_.gain = bgmCurrent_.gain + (bgmCurrent_.targetGain - bgmCurrent_.gain) * ease
            -- 如果没有next（纯淡入或纯淡出），直接插值
            if not bgmNext_.source then
                bgmCurrent_.gain = BGM_DEFAULT_GAIN * ease  -- 纯淡入
                if bgmCurrent_.targetGain <= 0 then
                    bgmCurrent_.gain = BGM_DEFAULT_GAIN * (1 - ease) -- 纯淡出
                end
            else
                bgmCurrent_.gain = BGM_DEFAULT_GAIN * (1 - ease) -- 交叉淡出
            end
            bgmCurrent_.source.gain = math.max(0, bgmCurrent_.gain)
        end

        -- 更新下一首BGM音量
        if bgmNext_.source then
            bgmNext_.gain = BGM_DEFAULT_GAIN * ease
            bgmNext_.source.gain = bgmNext_.gain
        end

        if t >= 1.0 then
            M._FinishBGMFade()
        end
    end

    -- 环境音淡入淡出
    if ambientFading_ then
        ambientFadeTimer_ = ambientFadeTimer_ + dt
        local t = math.min(1.0, ambientFadeTimer_ / AMBIENT_FADE_DURATION)
        local ease = t * t * (3 - 2 * t)

        if ambientCurrent_.source then
            if ambientCurrent_.targetGain <= 0 then
                -- 淡出
                ambientCurrent_.gain = AMBIENT_DEFAULT_GAIN * (1 - ease)
                ambientCurrent_.source.gain = math.max(0, ambientCurrent_.gain)
                if t >= 1.0 then
                    ambientCurrent_.source:Stop()
                    audioNode_:RemoveComponent(ambientCurrent_.source)
                    ambientCurrent_.source = nil
                    ambientCurrent_.key = ""
                    ambientCurrent_.gain = 0
                    ambientFading_ = false
                    -- 如果有下一个环境音要播放
                    if ambientNextKey_ ~= "" then
                        M.PlayAmbient(ambientNextKey_)
                    end
                end
            else
                -- 淡入
                ambientCurrent_.gain = AMBIENT_DEFAULT_GAIN * ease
                ambientCurrent_.source.gain = ambientCurrent_.gain
                if t >= 1.0 then
                    ambientFading_ = false
                end
            end
        else
            ambientFading_ = false
        end
    end
end

--- 获取当前BGM键名
function M.GetCurrentBGM()
    if bgmFading_ and bgmNext_.key ~= "" then
        return bgmNext_.key
    end
    return bgmCurrent_.key
end

--- 获取当前环境音键名
function M.GetCurrentAmbient()
    return ambientCurrent_.key
end

--- 清理所有音频
function M.Shutdown()
    M.StopBGMImmediate()
    M.StopAmbientImmediate()
    audioNode_ = nil
end

return M
