---@diagnostic disable: undefined-global
-- ============================================================================
-- UILore.lua — 非洲文化图鉴界面
-- 全屏覆盖弹窗，分类浏览+条目卡片+文化注解
-- ============================================================================

loreOpen_ = false           -- 图鉴弹窗是否打开
loreCategoryIdx_ = 1        -- 当前选中分类索引
loreDetailId_ = nil         -- 当前查看详情的条目ID

--- 打开图鉴
function OpenLorePanel()
    loreOpen_ = true
    loreCategoryIdx_ = 1
    loreDetailId_ = nil
    if LoreSystem then LoreSystem.ClearNewCount() end
    BuildUI()
end

--- 关闭图鉴
function CloseLorePanel()
    loreOpen_ = false
    loreDetailId_ = nil
    BuildUI()
end

--- 构建图鉴覆盖层（从 BuildManageUI 调用）
function BuildLoreOverlay()
    if not loreOpen_ then return nil end

    -- 如果在查看详情
    if loreDetailId_ then
        return BuildLoreDetail()
    end

    -- 主界面：分类标签 + 条目列表
    local categories = LoreSystem.CATEGORIES
    local currentCat = categories[loreCategoryIdx_] or categories[1]

    -- 顶部：标题 + 进度 + 关闭
    local unlocked, total = LoreSystem.GetProgress()
    local progressPct = total > 0 and math.floor(unlocked / total * 100) or 0

    -- 分类标签栏
    local catTabs = {}
    for i, cat in ipairs(categories) do
        local isActive = (i == loreCategoryIdx_)
        -- 统计该分类已解锁数
        local catEntries = LoreSystem.GetCategoryEntries(cat.id)
        local catUnlocked = 0
        for _, e in ipairs(catEntries) do
            if e.unlocked then catUnlocked = catUnlocked + 1 end
        end
        table.insert(catTabs, UI.Button {
            text = cat.icon .. " " .. catUnlocked .. "/" .. #catEntries,
            fontSize = 11, fontWeight = isActive and "bold" or "normal",
            height = 36, paddingLeft = 8, paddingRight = 8,
            backgroundColor = isActive and C.accent or { 0, 0, 0, 0 },
            fontColor = isActive and { 255, 255, 255, 255 } or C.textLight,
            borderRadius = 4,
            onClick = function()
                loreCategoryIdx_ = i
                loreDetailId_ = nil
                PlaySFX("page_turn")
                BuildUI()
            end,
        })
    end

    -- 条目卡片列表
    local entries = LoreSystem.GetCategoryEntries(currentCat.id)
    local entryCards = {}
    for _, entry in ipairs(entries) do
        if entry.unlocked then
            table.insert(entryCards, UI.Button {
                width = "100%", minHeight = 56, borderRadius = 6,
                backgroundColor = C.card,
                paddingLeft = 12, paddingRight = 12, paddingTop = 8, paddingBottom = 8,
                onClick = function()
                    loreDetailId_ = entry.id
                    PlaySFX("page_turn")
                    BuildUI()
                end,
                children = {
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center", gap = 10,
                        children = {
                            UI.Label { text = currentCat.icon, fontSize = 22 },
                            UI.Panel { flex = 1, children = {
                                UI.Label { text = entry.title, fontSize = 14, fontWeight = "bold", fontColor = C.text },
                                UI.Label { text = entry.subtitle or "", fontSize = 11, fontColor = C.textLight },
                            }},
                            UI.Label { text = "→", fontSize = 16, fontColor = C.textLight },
                        },
                    },
                },
            })
        else
            -- 未解锁条目：灰色占位
            table.insert(entryCards, UI.Panel {
                width = "100%", minHeight = 56, borderRadius = 6,
                backgroundColor = { 40, 30, 24, 200 },
                paddingLeft = 12, paddingRight = 12, paddingTop = 8, paddingBottom = 8,
                justifyContent = "center",
                children = {
                    UI.Panel {
                        width = "100%", flexDirection = "row", alignItems = "center", gap = 10,
                        children = {
                            UI.Label { text = "🔒", fontSize = 20 },
                            UI.Panel { flex = 1, children = {
                                UI.Label { text = "???", fontSize = 14, fontColor = { 120, 100, 80, 255 } },
                                UI.Label { text = GetUnlockHint(entry), fontSize = 10, fontColor = { 100, 80, 60, 255 } },
                            }},
                        },
                    },
                },
            })
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        position = "absolute", top = 0, left = 0,
        backgroundColor = { 30, 22, 16, 245 },
        children = {
            -- 顶部栏
            UI.Panel {
                width = "100%", paddingLeft = 12, paddingRight = 12, paddingTop = 10, paddingBottom = 6,
                flexDirection = "row", alignItems = "center",
                children = {
                    UI.Panel { flex = 1, children = {
                        UI.Label { text = "📖 非洲文化图鉴", fontSize = 18, fontWeight = "bold", fontColor = C.gold },
                        UI.Label {
                            text = "收集进度: " .. unlocked .. "/" .. total .. " (" .. progressPct .. "%)",
                            fontSize = 11, fontColor = C.textLight,
                        },
                    }},
                    UI.Button {
                        text = "✕", fontSize = 18, width = 36, height = 36,
                        backgroundColor = { 0, 0, 0, 0 }, fontColor = C.text,
                        onClick = function() CloseLorePanel() end,
                    },
                },
            },
            -- 进度条
            UI.Panel {
                width = "100%", paddingLeft = 12, paddingRight = 12, paddingBottom = 8,
                children = {
                    UI.Panel {
                        width = "100%", height = 6, borderRadius = 3,
                        backgroundColor = { 60, 44, 34, 255 },
                        children = {
                            UI.Panel {
                                width = progressPct .. "%", height = "100%", borderRadius = 3,
                                backgroundColor = C.gold,
                            },
                        },
                    },
                },
            },
            -- 分类标签（横向滚动）
            UI.Panel {
                width = "100%", paddingLeft = 8, paddingRight = 8, paddingBottom = 6,
                children = {
                    UI.ScrollView {
                        width = "100%", height = 42, scrollDirection = "horizontal",
                        children = {
                            UI.Panel {
                                flexDirection = "row", gap = 4, alignItems = "center",
                                children = catTabs,
                            },
                        },
                    },
                },
            },
            -- 分类描述
            UI.Panel {
                width = "100%", paddingLeft = 12, paddingRight = 12, paddingBottom = 6,
                children = {
                    UI.Label {
                        text = currentCat.name .. " — " .. currentCat.desc,
                        fontSize = 12, fontColor = C.textLight,
                    },
                },
            },
            -- 条目列表
            UI.ScrollView {
                flex = 1, width = "100%",
                paddingLeft = 10, paddingRight = 10, paddingBottom = 16,
                children = {
                    UI.Panel { width = "100%", gap = 6, children = entryCards },
                },
            },
        },
    }
end

--- 获取解锁提示文本
---@param entry table
---@return string
function GetUnlockHint(entry)
    if not entry then return "" end
    -- entry 来自 GetCategoryEntries 不含 unlockType，需从原始数据查
    for _, raw in ipairs(LoreSystem.ENTRIES) do
        if raw.id == entry.id then
            if raw.unlockType == "recruit" then return "招募 " .. raw.unlockParam .. " 后解锁"
            elseif raw.unlockType == "city" then return "到达该城市后解锁"
            elseif raw.unlockType == "combo" then return "触发特定组合事件解锁"
            elseif raw.unlockType == "day" then return "经营到第 " .. raw.unlockParam .. " 天解锁"
            elseif raw.unlockType == "item_tier" then return "获得 " .. raw.unlockParam .. " 星物品解锁"
            elseif raw.unlockType == "item_special" then return "获得特殊物品解锁"
            elseif raw.unlockType == "prestige" then return "转生 " .. raw.unlockParam .. " 次后解锁"
            end
        end
    end
    return "满足特定条件解锁"
end

--- 构建条目详情页
function BuildLoreDetail()
    -- 从 LoreSystem.ENTRIES 获取完整数据
    local entry = nil
    for _, e in ipairs(LoreSystem.ENTRIES) do
        if e.id == loreDetailId_ then
            entry = e
            break
        end
    end
    if not entry then
        loreDetailId_ = nil
        return BuildLoreOverlay()
    end

    -- 找到所属分类
    local catIcon = "📖"
    local catName = ""
    for _, cat in ipairs(LoreSystem.CATEGORIES) do
        if cat.id == entry.category then
            catIcon = cat.icon
            catName = cat.name
            break
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        position = "absolute", top = 0, left = 0,
        backgroundColor = { 30, 22, 16, 245 },
        children = {
            -- 顶部返回栏
            UI.Panel {
                width = "100%", flexDirection = "row", alignItems = "center",
                paddingLeft = 8, paddingRight = 12, paddingTop = 10, paddingBottom = 8,
                children = {
                    UI.Button {
                        text = "← 返回", fontSize = 13, height = 34,
                        paddingLeft = 10, paddingRight = 10,
                        backgroundColor = { 0, 0, 0, 0 }, fontColor = C.accent,
                        onClick = function()
                            loreDetailId_ = nil
                            PlaySFX("page_turn")
                            BuildUI()
                        end,
                    },
                    UI.Panel { flex = 1 },
                    UI.Label { text = catIcon .. " " .. catName, fontSize = 12, fontColor = C.textLight },
                },
            },
            -- 内容区域
            UI.ScrollView {
                flex = 1, width = "100%",
                paddingLeft = 14, paddingRight = 14, paddingBottom = 20,
                children = {
                    UI.Panel { width = "100%", gap = 12, children = {
                        -- 标题
                        UI.Panel {
                            width = "100%", alignItems = "center", gap = 4, paddingTop = 8, paddingBottom = 12,
                            children = {
                                UI.Label { text = catIcon, fontSize = 36 },
                                UI.Label { text = entry.title, fontSize = 22, fontWeight = "bold", fontColor = C.gold },
                                UI.Label { text = entry.subtitle or "", fontSize = 13, fontColor = C.textLight },
                            },
                        },
                        -- 正文
                        UI.Panel {
                            width = "100%", backgroundColor = C.card, borderRadius = 8,
                            paddingLeft = 14, paddingRight = 14, paddingTop = 12, paddingBottom = 12,
                            children = {
                                UI.Label {
                                    text = entry.content,
                                    fontSize = 13, fontColor = C.text, lineHeight = 1.5,
                                },
                            },
                        },
                        -- 文化注解（特色区域）
                        entry.cultural_note and UI.Panel {
                            width = "100%", backgroundColor = { 60, 44, 30, 255 },
                            borderRadius = 8, borderWidth = 1, borderColor = C.gold,
                            paddingLeft = 14, paddingRight = 14, paddingTop = 10, paddingBottom = 10,
                            children = {
                                UI.Label {
                                    text = "🌍 文化注解", fontSize = 12, fontWeight = "bold",
                                    fontColor = C.gold, marginBottom = 6,
                                },
                                UI.Label {
                                    text = entry.cultural_note,
                                    fontSize = 12, fontColor = { 210, 190, 160, 255 }, lineHeight = 1.5,
                                },
                            },
                        } or nil,
                    }},
                },
            },
        },
    }
end
