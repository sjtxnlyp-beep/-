-- ============================================================================
-- 《非洲网吧大亨》- Africa Cyber Cafe Tycoon v4.0
-- 入口文件 — 所有游戏代码按功能拆分到下方模块
-- ============================================================================

-- 全局库引用（所有模块共享）
UI = require("urhox-libs/UI")
AdManager = require("AdManager")
ChapterData = require("Immersion.ChapterData")
AudioDirector = require("Immersion.AudioDirector")
CinematicTransition = require("Immersion.CinematicTransition")
CinematicDialogue = require("Immersion.CinematicDialogue")

---@diagnostic disable: undefined-global

-- 1. 状态与常量
require "GameState"

-- 2. 数据表
require "RandomEvents"
require "Chat"
require "StoryEvents"
require "CafeEvents"

-- 3. 游戏变量
require "GameVars"

-- 3.5 留存系统
require "Retention"
RV2 = require "RetentionV2"
require "NPCStorylines"

-- 4. 音频与存档
require "AudioSave"

-- 5. 渲染
require "Render"

-- 6. 核心逻辑
require "GameLogic"
require "Actions"
require "MiniGames"
require "TrainMatch"

-- 7. 初始化与主循环 (HandleUpdate/HandleKeyDown)
require "InitReset"

-- 7.5 二手市场
require "MarketData"
Market = require "Market"
require "UIMarket"

-- 8. UI 界面
require "UIScreens"
require "UIManage"
require "UICafe"
require "UIChat"
require "UIRanking"
require "UIEvent"

-- ============================================================================
-- 引擎入口
-- ============================================================================
function Start()
    graphics.windowTitle = "非洲网吧大亨"

    UI.Init({
        fonts = {
            { family = "sans", weights = { normal = "Fonts/MiSans-Regular.ttf" } }
        },
        scale = UI.Scale.DPR,
        theme = {
            colors = {
                -- 主色：暖金棕（替代默认蓝色）
                primary        = { 160, 120, 50, 255 },
                primaryHover   = { 180, 140, 65, 255 },
                primaryPressed = { 130, 100, 40, 255 },
                -- 次色：暖灰棕（替代默认冷灰）
                secondary        = { 90, 78, 65, 255 },
                secondaryHover   = { 110, 95, 80, 255 },
                secondaryPressed = { 75, 65, 55, 255 },
                -- 背景 / 表面
                background  = { 35, 28, 22, 255 },
                surface      = { 48, 40, 32, 230 },
                surfaceHover = { 58, 50, 40, 230 },
                -- 文字
                text          = { 240, 232, 220, 255 },
                textSecondary = { 170, 155, 138, 255 },
                textDisabled  = { 100, 90, 78, 255 },
                -- 边框
                border      = { 80, 68, 55, 255 },
                borderFocus = { 160, 120, 50, 255 },
                -- 语义色
                success = { 80, 160, 80, 255 },
                warning = { 200, 165, 50, 255 },
                error   = { 210, 70, 70, 255 },
                -- 禁用
                disabled     = { 55, 46, 36, 255 },
                disabledText = { 100, 90, 78, 255 },
                -- 遮罩
                overlay = { 10, 8, 5, 180 },
            },
        },
    })

    currentPhase_ = PHASE_TITLE
    BuildUI()

    -- NanoVG 过场动画上下文
    nvgContext_ = nvgCreate(1)
    nvgFont_ = nvgCreateFont(nvgContext_, "trans", "Fonts/MiSans-Regular.ttf")

    -- 语音播放节点（UI-only游戏也需要Scene+Node来挂载SoundSource）
    audioScene_ = Scene()
    audioNode_ = audioScene_:CreateChild("VoicePlayer")

    -- 初始化沉浸式模块
    AudioDirector.Init(audioNode_, BGM_PATHS)
    CinematicDialogue.Init(audioNode_)

    SubscribeToEvent("Update", "HandleUpdate")
    SubscribeToEvent("KeyDown", "HandleKeyDown")
    SubscribeToEvent(nvgContext_, "NanoVGRender", "HandleNanoVGRender")

    -- 标题BGM
    PlayBGM("title")

    print("=== 非洲网吧大亨 v4.0 启动 ===")
end

function Stop()
    AudioDirector.Shutdown()
    StopVoice()
    audioNode_ = nil
    audioScene_ = nil
    if nvgContext_ then
        nvgDelete(nvgContext_)
        nvgContext_ = nil
    end
    UI.Shutdown()
end
