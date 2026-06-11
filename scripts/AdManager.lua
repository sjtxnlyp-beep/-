------------------------------------------------------------
-- AdManager.lua  —  激励视频广告管理模块
-- 统一管理每日观看次数、按钮生成、存档集成
------------------------------------------------------------
---@diagnostic disable: undefined-global
local UI = require("urhox-libs/UI")

local AdManager = {}

--- 每种场景的每日观看次数上限
AdManager.limits = {
    extra_ap        = 3,  -- 额外行动点 (2→3)
    double_income   = 1,  -- 翻倍日收入
    free_repair     = 1,  -- 免费维修
    train_bonus     = 3,  -- 加练一轮 (2→3)
    bailout_boost   = 1,  -- 破产救助
    reputation_ad   = 2,  -- 媒体采访 (1→2)
    mood_boost      = 1,  -- 团队看电影
    night_train     = 1,  -- 夜间自动训练
    -- ▼ 新增广告场景 ▼
    day_end_bonus   = 1,  -- 结算日额外奖金
    match_power_up  = 1,  -- 赛前战力加成
    match_reward_2x = 1,  -- 赛后奖励翻倍
    revive_match    = 1,  -- 比赛失败复活
    recruit_discount= 1,  -- 招募折扣
    gold_trade_bonus= 1,  -- 黄金交易加成
    sponsor_gift    = 1,  -- 每日福利（观看广告领现金）
    sponsor_small   = 3,  -- 赞助商中心小奖励
    market_pull     = 2,  -- 市场广告抽卡
    upgrade_skip    = 2,  -- 升级加速/跳过
    ap_recover      = 2,  -- RV2 广告恢复行动点
}

--- 观看记录  { [sceneId] = { count=N, lastDay=D } }
AdManager.watchLog = {}

--- 检查今日是否还能看
---@param sceneId string
---@param day number 当前游戏天数
---@return boolean canWatch
---@return number remaining
function AdManager.CanWatch(sceneId, day)
    local log = AdManager.watchLog[sceneId]
    local limit = AdManager.limits[sceneId] or 0
    if not log or log.lastDay ~= day then
        AdManager.watchLog[sceneId] = { count = 0, lastDay = day }
        log = AdManager.watchLog[sceneId]
    end
    local remaining = math.max(0, limit - log.count)
    return remaining > 0, remaining
end

--- 播放激励视频广告；成功后执行回调
---@param sceneId string
---@param day number
---@param onSuccess function
---@param onFail function|nil
function AdManager.ShowAd(sceneId, day, onSuccess, onFail)
    local canWatch = AdManager.CanWatch(sceneId, day)
    if not canWatch then
        if onFail then onFail("今日次数已用完") end
        return
    end
    local ok, err = pcall(function()
        sdk:ShowRewardVideoAd(function(result)
            if result.success then
                local adLog = AdManager.watchLog[sceneId]
                adLog.count = adLog.count + 1
                if onSuccess then onSuccess() end
            else
                if onFail then onFail(result.msg or "广告播放失败") end
            end
        end)
    end)
    if not ok then
        print("[AdManager] ShowRewardVideoAd error: " .. tostring(err))
        if onFail then onFail("广告加载失败，请稍后再试") end
    end
end

--- 生成统一风格的广告按钮（金色福利主题）
---@param props table { sceneId, day, text, onReward, width?, height?, fontSize? }
---@return table UI.Button
function AdManager.AdButton(props)
    local canWatch, remaining = AdManager.CanWatch(props.sceneId, props.day)
    local limit = AdManager.limits[props.sceneId] or 0

    -- 调用方自定义样式时走简单模式（赞助商中心、黄金交易等）
    local hasCustomStyle = props.backgroundColor ~= nil
    if hasCustomStyle then
        local tag = remaining > 0
            and (" (" .. remaining .. "/" .. limit .. ")")
            or  " (已达上限)"
        return UI.Button {
            text = props.text .. tag,
            width = props.width or "100%",
            height = props.height or 40,
            fontSize = props.fontSize or 13,
            borderRadius = props.borderRadius or 10,
            borderWidth = props.borderWidth or 1,
            borderColor = canWatch and (props.borderColor or {C.gold[1],C.gold[2],C.gold[3],100}) or {60,50,40,60},
            backgroundColor = canWatch and props.backgroundColor or {40,34,28,200},
            fontColor = canWatch and (props.fontColor or {C.gold[1],C.gold[2],C.gold[3],255}) or {100,90,78,180},
            disabled = not canWatch,
            onClick = function()
                if not canWatch then return end
                AdManager.ShowAd(props.sceneId, props.day, function()
                    if props.onReward then props.onReward() end
                end)
            end,
        }
    end

    -- ── 默认样式：深底+金色文字+金色辉光边框，吸引点击 ──
    local remainTag = remaining > 0
        and ("  " .. remaining .. "/" .. limit)
        or  "  已达上限"
    local bg     = canWatch and C.adBg or {40,34,28,200}
    local fg     = canWatch and C.adText or {100,90,78,180}
    local bc     = canWatch and C.adBorder or {60,50,40,60}

    return UI.Button {
        text = (canWatch and "▶ " or "") .. props.text .. remainTag,
        width = props.width or "100%",
        height = props.height or 42,
        fontSize = props.fontSize or 13,
        fontWeight = "bold",
        borderRadius = 10,
        borderWidth = canWatch and 1.5 or 1,
        borderColor = bc,
        backgroundColor = bg,
        fontColor = fg,
        boxShadow = canWatch and { { x = 0, y = 0, blur = 8, spread = 0, color = { C.gold[1], C.gold[2], C.gold[3], 90 } } } or nil,
        disabled = not canWatch,
        onClick = function()
            if not canWatch then return end
            AdManager.ShowAd(props.sceneId, props.day, function()
                if props.onReward then props.onReward() end
            end)
        end,
    }
end

------------------------------------------------------------
-- 插屏广告管理
------------------------------------------------------------

--- 插屏广告频控配置
AdManager.interstitialConfig = {
    minDay = 4,           -- 第4天开始才会弹插屏（保护新手体验）
    dayInterval = 3,      -- 每隔3天最多弹1次
    maxPerSession = 2,    -- 每次游戏会话最多弹2次
}

--- 插屏广告状态（不持久化，每次启动重置）
AdManager.interstitialState = {
    sessionCount = 0,     -- 本次会话已弹次数
    lastShownDay = 0,     -- 上次弹出时的游戏天数
}

--- 检查是否应该展示插屏广告
---@param day number 当前游戏天数
---@return boolean
function AdManager.ShouldShowInterstitial(day)
    local cfg = AdManager.interstitialConfig
    local state = AdManager.interstitialState
    -- 新手保护期
    if day < cfg.minDay then return false end
    -- 会话次数上限
    if state.sessionCount >= cfg.maxPerSession then return false end
    -- 天数间隔限制
    if state.lastShownDay > 0 and (day - state.lastShownDay) < cfg.dayInterval then return false end
    return true
end

--- 展示插屏广告（非阻塞，展示后执行回调）
---@param day number 当前游戏天数
---@param onComplete function|nil 广告关闭后回调（无论成功失败都调用）
function AdManager.ShowInterstitial(day, onComplete)
    if not AdManager.ShouldShowInterstitial(day) then
        if onComplete then onComplete() end
        return
    end
    local state = AdManager.interstitialState
    pcall(function()
        sdk:ShowInterstitialAd(function(result)
            -- 无论成功失败都记录（避免反复弹出）
            state.sessionCount = state.sessionCount + 1
            state.lastShownDay = day
            if onComplete then onComplete() end
        end)
    end)
    -- 兜底：如果 sdk 调用同步失败，也记录并回调
    -- （ShowInterstitialAd 是异步的，此处不会执行到；仅防御 pcall 内异常）
end

--- Banner 广告状态
AdManager.bannerVisible = false

--- 显示 Banner 广告（底部横幅）
function AdManager.ShowBanner()
    if AdManager.bannerVisible then return end
    AdManager.bannerVisible = true
    pcall(function()
        sdk:ShowBannerAd()
    end)
end

--- 隐藏 Banner 广告
function AdManager.HideBanner()
    if not AdManager.bannerVisible then return end
    AdManager.bannerVisible = false
    pcall(function()
        sdk:HideBannerAd()
    end)
end

--- 存档：返回可序列化数据
function AdManager.GetSaveData()
    return AdManager.watchLog
end

--- 读档：恢复数据
function AdManager.LoadSaveData(data)
    AdManager.watchLog = data or {}
end

--- 重置
function AdManager.Reset()
    AdManager.watchLog = {}
    AdManager.HideBanner()
    AdManager.bannerVisible = false
    AdManager.interstitialState = { sessionCount = 0, lastShownDay = 0 }
end

return AdManager
