---@diagnostic disable: undefined-global
-- ============================================================================
-- PopupQueue.lua — 统一弹窗队列管理器
-- ============================================================================
-- 规则：
--   1. 同一时刻只显示一个弹窗（队首）
--   2. 关闭当前弹窗后，自动弹出下一个
--   3. 弹窗按优先级排序：priority 数值越小越优先
--   4. 核心弹窗（日结、离线收益、结局）不受每日上限限制
--   5. 非核心弹窗受每日上限限制（POPUP_DAILY_MAX）
-- ============================================================================

local PopupQueue = {}

-- 弹窗优先级定义（数字越小越优先）
PopupQueue.PRIORITY = {
    BLOCKING    = 10,   -- 阻塞性：挑战条件不足、小游戏退出确认
    CORE        = 20,   -- 核心弹窗：离线收益、日结摘要、周报
    STORY       = 30,   -- 叙事弹窗：故事确认、门口闲聊
    FEEDBACK    = 40,   -- 反馈弹窗：升级完成、行动结果
    INFO        = 50,   -- 信息弹窗：成就、明日预告、每日任务
    TUTORIAL    = 60,   -- 教程浮层：新手引导
}

-- 内部队列
local queue_ = {}           -- { {id, priority, buildFn, isCore}, ... }
local activePopupId_ = nil  -- 当前显示的弹窗 id

--- 清空队列（切换 phase 时调用）
function PopupQueue.Clear()
    queue_ = {}
    activePopupId_ = nil
end

--- 入队一个弹窗
---@param id string 唯一标识（防重复入队）
---@param priority number 优先级（用 PopupQueue.PRIORITY.*）
---@param buildFn function 返回 UI 元素的函数（返回 nil 则跳过）
---@param isCore boolean|nil 是否为核心弹窗（不受每日上限限制）
function PopupQueue.Enqueue(id, priority, buildFn, isCore)
    -- 去重：同 id 不重复入队
    for _, item in ipairs(queue_) do
        if item.id == id then return end
    end
    table.insert(queue_, {
        id = id,
        priority = priority,
        buildFn = buildFn,
        isCore = isCore or false,
    })
    -- 按优先级排序（稳定排序：同优先级保持入队顺序）
    table.sort(queue_, function(a, b)
        if a.priority ~= b.priority then
            return a.priority < b.priority
        end
        return false  -- 保持原顺序
    end)
end

--- 获取当前应该显示的弹窗 UI 元素（只返回队首）
--- 如果队首弹窗的 buildFn 返回 nil（条件不满足），自动跳到下一个
---@return table|nil uiElement
function PopupQueue.BuildCurrent()
    while #queue_ > 0 do
        local item = queue_[1]
        -- 非核心弹窗检查每日上限
        if not item.isCore then
            if not CanShowPopup() then
                -- 超出上限，移除所有非核心弹窗
                local filtered = {}
                for _, q in ipairs(queue_) do
                    if q.isCore then
                        table.insert(filtered, q)
                    end
                end
                queue_ = filtered
                if #queue_ == 0 then return nil end
                item = queue_[1]
            end
        end

        local ok, uiElement = pcall(item.buildFn)
        if ok and uiElement then
            activePopupId_ = item.id
            -- 非核心弹窗消耗配额
            if not item.isCore then
                ConsumePopupSlot()
            end
            return uiElement
        else
            -- buildFn 返回 nil 或出错，移除并尝试下一个
            table.remove(queue_, 1)
        end
    end
    activePopupId_ = nil
    return nil
end

--- 关闭当前弹窗并推进到下一个（在弹窗关闭回调中调用）
function PopupQueue.Dismiss()
    if #queue_ > 0 then
        table.remove(queue_, 1)
    end
    activePopupId_ = nil
    -- 触发 UI 重建以显示下一个弹窗（或无弹窗）
    BuildUI()
end

--- 获取当前显示的弹窗 ID
---@return string|nil
function PopupQueue.GetActiveId()
    return activePopupId_
end

--- 队列是否为空
---@return boolean
function PopupQueue.IsEmpty()
    return #queue_ == 0
end

--- 队列中是否包含指定 id 的弹窗
---@param id string
---@return boolean
function PopupQueue.Has(id)
    for _, item in ipairs(queue_) do
        if item.id == id then return true end
    end
    return false
end

--- 获取队列长度（调试用）
---@return number
function PopupQueue.Count()
    return #queue_
end

return PopupQueue
