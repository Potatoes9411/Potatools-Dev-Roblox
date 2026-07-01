local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local ok, res = pcall(function()
        if not (isfile and isfile(PlaceCustomFile)) then return {} end
        return HttpService:JSONDecode(readfile(PlaceCustomFile))
    end)
    if ok and type(res) == "table" then return res end
    return {}
end
local PlaceCustom = loadCustomPlaces()
local function saveCustomPlaces()
    pcall(function()
        if writefile then writefile(PlaceCustomFile, HttpService:JSONEncode(PlaceCustom)) end
    end)
end

-- The full combined + visible game list (built fresh each time the hub opens).
local function getPlaceList()
    local out = {}
    for _, g in ipairs(PlaceDB) do table.insert(out, g) end
    for _, g in ipairs(PlaceCustom) do table.insert(out, g) end
    return out
end

-- Fancy hover/presstween helper using a UIScale on the target.
local function addHoverAnim(obj, scale)
    scale = scale or 1.04
    local us = Instance.new("UIScale")
    us.Scale = 1
    us.Parent = obj
    obj.MouseEnter:Connect(function() tween(us, 0.12, { Scale = scale }) end)
    obj.MouseLeave:Connect(function() tween(us, 0.12, { Scale = 1 }) end)
    return us
end

-- Entrance animation: scale up + fade in.
local function animateEntrance(frame, delay)
    delay = delay or 0
    local us = frame:FindFirstChildOfClass("UIScale")
    if not us then
        us = Instance.new("UIScale")
        us.Parent = frame
    end
    us.Scale = 0.9
    frame.BackgroundTransparency = 1
    frame.Position = frame.Position + UDim2.new(0, 0, 0, 16)
    task.delay(delay, function()
        tween(frame, 0.35, { BackgroundTransparency = 0 }, nil)
        tween(us, 0.35, { Scale = 1 })
        tween(frame, 0.35, { Position = frame.Position - UDim2.new(0, 0, 0, 16) })
    end)
end

-- Build the animated Place Teleporter hub.
local PlaceHubState = { open = nil, cat = "All" }
local function buildPlaceHub()
    -- if already open, just focus it
    if PlaceHubState.open and not PlaceHubState.open._dead then
        PlaceHubState.open.Root.Visible = true
        bringToFront(PlaceHubState.open.Root)
        return PlaceHubState.open
    end

    local self = { _dead = false }
    PlaceHubState.open = self

    local root = Instance.new("Frame")
    root.Name = "PlaceHub"
    root.Size = UDim2.new(0, 760, 0, 540)
    root.Position = UDim2.new(0.5, -380, 0.5, -270)
    root.BackgroundColor3 = Theme.BackgroundDark
    root.BorderSizePixel = 0
    root.ZIndex = 10
    root.Parent = ScreenGui
    corner(root, UDim.new(0, 16))
    stroke(root, Theme.Stroke, 1, 0.2)
    -- subtle drop glow
    local glow = Instance.new("UIStroke")
    glow.Color = Theme.Accent
    glow.Thickness = 1.5
    glow.Transparency = 0.6
    glow.Parent = root

    -- HEADER
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 64)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    corner(header, UDim.new(0, 16))
    local hfill = Instance.new("Frame"); hfill.Size = UDim2.new(1,0,0,32); hfill.BackgroundColor3 = Theme.Sidebar; hfill.BorderSizePixel = 0; hfill.ZIndex = 11; hfill.Position = UDim2.new(0,0,0,32); hfill.Parent = header

    -- logo badge
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 40, 0, 40)
    badge.Position = UDim2.new(0, 16, 0.5, -20)
    badge.BackgroundColor3 = Theme.Accent
    badge.BorderSizePixel = 0
    badge.ZIndex = 12
    badge.Parent = header
    corner(badge, UDim.new(0, 10))
    gradient(badge, Theme.AccentBright, Theme.AccentDark, 45)
    local badgeTxt = Instance.new("TextLabel")
    badgeTxt.BackgroundTransparency = 1
    badgeTxt.Size = UDim2.new(1,0,1,0)
    badgeTxt.Font = Theme.FontBold
    badgeTxt.TextSize = 20
    badgeTxt.TextColor3 = Color3.fromRGB(255,255,255)
    badgeTxt.Text = "ðŸš€"
    badgeTxt.ZIndex = 13
    badgeTxt.Parent = badge

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 66, 0, 10)
    title.Size = UDim2.new(1, -260, 0, 22)
    title.Font = Theme.FontBold
    title.TextSize = 18
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Place Teleporter"
    title.ZIndex = 12
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 66, 0, 34)
    subtitle.Size = UDim2.new(1, -260, 0, 16)
    subtitle.Font = Theme.Font
    subtitle.TextSize = 12
    subtitle.TextColor3 = Theme.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Teleport to any game by PlaceId  â€¢  " .. #getPlaceList() .. " games"
    subtitle.ZIndex = 12
    subtitle.Parent = header

    -- window controls (minimize / close)
    local function ctrl(txt, color, x, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 30, 0, 30)
        b.Position = UDim2.new(1, x, 0.5, -15)
        b.BackgroundColor3 = Theme.Element
        b.Text = txt
        b.Font = Theme.FontBold
        b.TextSize = 14
        b.TextColor3 = color
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = header
        corner(b, UDim.new(0, 8))
        addHoverAnim(b, 1.08)
        b.MouseButton1Click:Connect(fn)
        return b
    end

    local minimized = false
    local fullSize = root.Size
    local contentHolder = Instance.new("Frame")
    contentHolder.BackgroundTransparency = 1
    contentHolder.Size = UDim2.new(1, 0, 1, -64)
    contentHolder.Position = UDim2.new(0, 0, 0, 64)
    contentHolder.ZIndex = 11
    contentHolder.Parent = root

    -- floating reopen icon
    local reopen = Instance.new("TextButton")
    reopen.Size = UDim2.new(0, 54, 0, 54)
    reopen.Position = UDim2.new(0, 20, 0, 20)
    reopen.BackgroundColor3 = Theme.Accent
    reopen.Text = "ðŸš€"
    reopen.Font = Theme.FontBold
    reopen.TextSize = 22
    reopen.TextColor3 = Color3.fromRGB(255,255,255)
    reopen.BorderSizePixel = 0
    reopen.Visible = false
    reopen.ZIndex = 60
    reopen.Parent = ScreenGui
    corner(reopen, UDim.new(0, 14))
    gradient(reopen, Theme.AccentBright, Theme.AccentDark, 45)
    makeDraggable(reopen, reopen)
    addHoverAnim(reopen, 1.12)

    ctrl("â€“", Theme.Yellow, -38, function()
        minimized = not minimized
        if minimized then
            fullSize = root.Size
            tween(root, 0.22, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 64) })
            contentHolder.Visible = false
        else
            tween(root, 0.22, { Size = fullSize })
            contentHolder.Visible = true
        end
    end)
    ctrl("âœ•", Theme.Red, -74, function()
        tween(root, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.2)
        root.Visible = false
        reopen.Visible = true
    end)
    reopen.MouseButton1Click:Connect(function()
        root.Visible = true
        reopen.Visible = false
        bringToFront(root)
        tween(root, 0.2, { BackgroundTransparency = 0 })
    end)

    -- SEARCH BAR
    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, -28, 0, 36)
    searchBar.Position = UDim2.new(0, 14, 0, 8)
    searchBar.BackgroundColor3 = Theme.Element
    searchBar.BorderSizePixel = 0
    searchBar.ZIndex = 11
    searchBar.Parent = contentHolder
    corner(searchBar, UDim.new(0, 10))
    stroke(searchBar, Theme.Stroke, 1, 0.3)
    local sIcon = Instance.new("TextLabel")
    sIcon.BackgroundTransparency = 1; sIcon.Position = UDim2.new(0,10,0,0); sIcon.Size = UDim2.new(0,22,1,0)
    sIcon.Font = Theme.Font; sIcon.TextSize = 16; sIcon.TextColor3 = Theme.TextDim; sIcon.Text = "ðŸ”"; sIcon.ZIndex = 12; sIcon.Parent = searchBar
    local sBox = Instance.new("TextBox")
    sBox.BackgroundTransparency = 1
    sBox.Position = UDim2.new(0, 38, 0, 0)
    sBox.Size = UDim2.new(1, -120, 1, 0)
    sBox.Font = Theme.Font; sBox.TextSize = 14; sBox.TextColor3 = Theme.Text
    sBox.PlaceholderText = "Search games by name or PlaceId..."
    sBox.PlaceholderColor3 = Theme.TextDim
    sBox.ClearTextOnFocus = false
    sBox.TextXAlignment = Enum.TextXAlignment.Left
    sBox.ZIndex = 12; sBox.Parent = searchBar
    -- add-game button inside search bar
    local addBtn = Instance.new("TextButton")
    addBtn.Size = UDim2.new(0, 70, 0, 26)
    addBtn.Position = UDim2.new(1, -80, 0.5, -13)
    addBtn.BackgroundColor3 = Theme.Accent
    addBtn.Text = "+ Add"
    addBtn.Font = Theme.FontBold; addBtn.TextSize = 12
    addBtn.TextColor3 = Color3.fromRGB(255,255,255)
    addBtn.BorderSizePixel = 0; addBtn.ZIndex = 12
    addBtn.Parent = searchBar
    corner(addBtn, UDim.new(0, 7))
    addHoverAnim(addBtn, 1.06)

    -- CATEGORY TABS (horizontal scroll)
    local catHolder = Instance.new("Frame")
    catHolder.Size = UDim2.new(1, -28, 0, 32)
    catHolder.Position = UDim2.new(0, 14, 0, 50)
    catHolder.BackgroundTransparency = 1
    catHolder.ZIndex = 11
    catHolder.Parent = contentHolder
    local catList = Instance.new("ScrollingFrame")
    catList.Size = UDim2.new(1, 0, 1, 0)
    catList.BackgroundTransparency = 1
    catList.ScrollBarThickness = 0
    catList.CanvasSize = UDim2.new(0, 0, 0, 0)
    catList.AutomaticCanvasSize = Enum.AutomaticSize.X
    catList.ScrollingDirection = Enum.ScrollingDirection.X
    catList.ZIndex = 12
    catList.Parent = catHolder
    local catLayout = Instance.new("UIListLayout")
    catLayout.FillDirection = Enum.FillDirection.Horizontal
    catLayout.Padding = UDim.new(0, 6)
    catLayout.Parent = catList

    -- CARD GRID
    local grid = Instance.new("ScrollingFrame")
    grid.Size = UDim2.new(1, -28, 1, -94)
    grid.Position = UDim2.new(0, 14, 0, 90)
    grid.BackgroundTransparency = 1
    grid.ScrollBarThickness = 6
    grid.ScrollBarImageColor3 = Theme.Accent
    grid.CanvasSize = UDim2.new(0, 0, 0, 0)
    grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    grid.ZIndex = 11
    grid.Parent = contentHolder
    local gPad = Instance.new("UIPadding")
    gPad.PaddingTop = UDim.new(0,4); gPad.PaddingBottom = UDim.new(0,8); gPad.PaddingLeft = UDim.new(0,2); gPad.PaddingRight = UDim.new(0,2); gPad.Parent = grid
    local gLayout = Instance.new("UIGridLayout")
    gLayout.CellSize = UDim2.new(0, 156, 0, 196)
    gLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gLayout.Parent = grid

    makeDraggable(root, header)
    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bringToFront(root)
        end
    end)

    -- build a single card
    local order = 0
    local function makeCard(g)
        order = order + 1
        local card = Instance.new("Frame")
        card.Name = g.name
        card.BackgroundColor3 = Theme.Element
        card.BorderSizePixel = 0
        card.LayoutOrder = order
        card.ZIndex = 11
        card.Parent = grid
        corner(card, UDim.new(0, 12))
        local cardStroke = stroke(card, Theme.Stroke, 1, 0.4)

        -- icon
        local iconBg = Instance.new("Frame")
        iconBg.Size = UDim2.new(1, -16, 0, 90)
        iconBg.Position = UDim2.new(0, 8, 0, 8)
        iconBg.BackgroundColor3 = Theme.BackgroundDark
        iconBg.BorderSizePixel = 0
        iconBg.ZIndex = 12
        iconBg.Parent = card
        corner(iconBg, UDim.new(0, 8))
        local emoji = Instance.new("TextLabel")
        emoji.BackgroundTransparency = 1
        emoji.Size = UDim2.new(1,0,1,0)
        emoji.Font = Theme.Font; emoji.TextSize = 40
        emoji.TextColor3 = Theme.TextDim
        emoji.Text = g.icon or "ðŸŽ®"
        emoji.ZIndex = 13
        emoji.Parent = iconBg
        local img = Instance.new("ImageLabel")
        img.Size = UDim2.new(1, -8, 1, -8)
        img.Position = UDim2.new(0, 4, 0, 4)
        img.BackgroundTransparency = 1
        img.ScaleType = Enum.ScaleType.Fit
        img.Image = ""
        img.ZIndex = 14
        img.Parent = iconBg
        if g.id and g.id > 0 then
            pcall(function()
                img.Image = string.format("rbxthumb://type=GameIcon&id=%d&w=150&h=150", g.id)
            end)
        end

        -- name
        local name = Instance.new("TextLabel")
        name.BackgroundTransparency = 1
        name.Position = UDim2.new(0, 8, 0, 102)
        name.Size = UDim2.new(1, -16, 0, 32)
        name.Font = Theme.FontBold
        name.TextSize = 13
        name.TextColor3 = Theme.Text
        name.TextWrapped = true
        name.Text = g.name
        name.ZIndex = 12
        name.Parent = card

        -- placeid + category
        local meta = Instance.new("TextLabel")
        meta.BackgroundTransparency = 1
        meta.Position = UDim2.new(0, 8, 0, 134)
        meta.Size = UDim2.new(1, -16, 0, 14)
        meta.Font = Theme.FontMono
        meta.TextSize = 10
        meta.TextColor3 = Theme.TextDim
        meta.Text = (g.id and g.id > 0) and tostring(g.id) or "no id"
        meta.ZIndex = 12
        meta.Parent = card

        -- TP button
        local tpBtn = Instance.new("TextButton")
        tpBtn.Size = UDim2.new(1, -16, 0, 32)
        tpBtn.Position = UDim2.new(0, 8, 1, -40)
        tpBtn.BackgroundColor3 = g.accent or Theme.Accent
        tpBtn.Text = "ðŸš€ Teleport"
        tpBtn.Font = Theme.FontBold
        tpBtn.TextSize = 13
        tpBtn.TextColor3 = Color3.fromRGB(255,255,255)
        tpBtn.BorderSizePixel = 0
        tpBtn.ZIndex = 12
        tpBtn.Parent = card
        corner(tpBtn, UDim.new(0, 8))
        gradient(tpBtn, g.accent or Theme.AccentBright, (g.accent and g.accent:Lerp(Color3.new(0,0,0), 0.3)) or Theme.AccentDark, 0)
        addHoverAnim(tpBtn, 1.05)

        -- run button (small, top-right of card)
        local runBtn = Instance.new("TextButton")
        runBtn.Size = UDim2.new(0, 26, 0, 26)
        runBtn.Position = UDim2.new(1, -34, 0, 12)
        runBtn.BackgroundColor3 = Theme.BackgroundDark
        runBtn.Text = "â–¶"
        runBtn.Font = Theme.FontBold
        runBtn.TextSize = 12
        runBtn.TextColor3 = Theme.Text
        runBtn.BorderSizePixel = 0
        runBtn.ZIndex = 15
        runBtn.Parent = card
        corner(runBtn, UDim.new(0, 6))
        stroke(runBtn, Theme.Stroke, 1, 0)
        addHoverAnim(runBtn, 1.1)

        -- card hover effect
        local cardScale = addHoverAnim(card, 1.03)
        card.MouseEnter:Connect(function()
            tween(cardStroke, 0.12, { Color = g.accent or Theme.Accent, Transparency = 0 })
        end)
        card.MouseLeave:Connect(function()
            tween(cardStroke, 0.12, { Color = Theme.Stroke, Transparency = 0.4 })
        end)

        -- click flash
        local function flash()
            tween(card, 0.08, { BackgroundColor3 = g.accent or Theme.Accent })
            task.delay(0.08, function() tween(card, 0.15, { BackgroundColor3 = Theme.Element }) end)
        end

        -- TELEPORT action
        tpBtn.MouseButton1Click:Connect(function()
            flash()
            if not g.id or g.id <= 0 then
                notify("Place Teleporter", g.name .. " has no PlaceId set. Add it with '+ Add'.", 4, Theme.Red)
                return
            end
            notify("Place Teleporter", "Teleporting to " .. g.name .. "...", 4, Theme.Accent)
            local done = false
            local ok = pcall(function()
                TeleportService:Teleport(g.id, LocalPlayer)
                done = true
            end)
            -- fallback: queue on teleport & retry
            if not ok then
                pcall(function()
                    if queue_on_teleport then
                        queue_on_teleport([[loadstring(game:HttpGet("YOUR_HUB_URL"))()]])
                    end
                end)
            end
        end)

        -- JOIN RANDOM SERVER action (hold / right click the card body)
        card.MouseButton2Down:Connect(function()
            flash()
            if not g.id or g.id <= 0 then return end
            notify("Place Teleporter", "Searching a fresh server for " .. g.name .. "...", 4, Theme.Yellow)
            task.spawn(function()
                pcall(function()
                    local pages = TeleportService:GetSortedAsync(false, 100)
                    for _, item in ipairs(pages:GetCurrentPage()) do
                        if item.Id ~= game.JobId and item.Playing < item.MaxPlayers then
                            TeleportService:TeleportToPlaceInstance(g.id, item.Id, LocalPlayer)
                            return
                        end
                    end
                    TeleportService:Teleport(g.id, LocalPlayer)
                end)
            end)
        end)

        -- RUN action: open the matching feature window if supported
        runBtn.MouseButton1Click:Connect(function()
            flash()
            local found = nil
            for _, entry in ipairs(GameList) do
                if entry.name == g.name then found = entry; break end
            end
            if found then
                if OpenWindows[g.name] and not OpenWindows[g.name]._destroyed then
                    OpenWindows[g.name].Root.Visible = true
                    bringToFront(OpenWindows[g.name].Root)
                else
                    local ok2, win = pcall(found.builder)
                    if ok2 and win then OpenWindows[g.name] = win end
                end
                notify("Place Teleporter", "Opened " .. g.name .. " features.", 3, Theme.Green)
            else
                notify("Place Teleporter", "No feature window for " .. g.name .. ". Try Universal.", 3, Theme.Yellow)
                -- open Universal as a fallback
                if OpenWindows["Universal"] and not OpenWindows["Universal"]._destroyed then
                    OpenWindows["Universal"].Root.Visible = true
                    bringToFront(OpenWindows["Universal"].Root)
                else
                    local uok, uwin = pcall(Universal)
                    if uok and uwin then OpenWindows["Universal"] = uwin end
                end
            end
        end)
        return card
    end

    -- render the grid based on category + search
    local function render()
        for _, c in ipairs(grid:GetChildren()) do
            if c:IsA("Frame") and c.Name ~= "UIGridLayout" then c:Destroy() end
        end
        order = 0
        local query = string.lower(sBox.Text)
        local shown = 0
        for _, g in ipairs(getPlaceList()) do
            local catOk = (PlaceHubState.cat == "All") or (g.cat == PlaceHubState.cat)
            local qOk = (query == "")
                or string.lower(g.name):find(query)
                or tostring(g.id):find(query)
            if catOk and qOk then
                makeCard(g)
                shown = shown + 1
            end
        end
        subtitle.Text = "Showing " .. shown .. " game(s)  â€¢  right-click a card = join fresh server"
    end

    -- build category tabs
    local categories = { "All", "FPS", "RP", "SOCIAL", "SIMULATOR", "RPG", "STRATEGY", "HORROR", "ACTION", "OBBY", "SURVIVAL", "TYCOON", "SANDBOX", "RNG", "FIND", "FUN" }
    local tabButtons = {}
    for _, cat in ipairs(categories) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 0, 1, 0)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = (cat == PlaceHubState.cat) and Theme.Accent or Theme.Element
        b.Text = "  " .. cat .. "  "
        b.Font = Theme.FontBold
        b.TextSize = 12
        b.TextColor3 = (cat == PlaceHubState.cat) and Color3.fromRGB(255,255,255) or Theme.TextDim
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = catList
        corner(b, UDim.new(0, 8))
        local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,2); pad.PaddingRight = UDim.new(0,2); pad.Parent = b
        addHoverAnim(b, 1.05)
        b.MouseButton1Click:Connect(function()
            PlaceHubState.cat = cat
            -- recolor all tabs
            for c, btn in pairs(tabButtons) do
                local sel = (c == cat)
                tween(btn, 0.12, { BackgroundColor3 = sel and Theme.Accent or Theme.Element })
                btn.TextColor3 = sel and Color3.fromRGB(255,255,255) or Theme.TextDim
            end
            render()
        end)
        tabButtons[cat] = b
    end

    -- search reaction
    sBox:GetPropertyChangedSignal("Text"):Connect(render)

    -- ADD CUSTOM GAME popup (simple inline form)
    addBtn.MouseButton1Click:Connect(function()
        -- build a small modal
        local modal = Instance.new("Frame")
        modal.Size = UDim2.new(0, 340, 0, 240)
        modal.Position = UDim2.new(0.5, -170, 0.5, -120)
        modal.BackgroundColor3 = Theme.Background
        modal.BorderSizePixel = 0
        modal.ZIndex = 80
        modal.Parent = ScreenGui
        corner(modal, UDim.new(0, 12))
        stroke(modal, Theme.Accent, 1.5, 0)
        bringToFront(modal)
        animateEntrance(modal, 0)
        local mt = Instance.new("TextLabel")
        mt.BackgroundTransparency = 1; mt.Size = UDim2.new(1,-20,0,24); mt.Position = UDim2.new(0,12,0,12)
        mt.Font = Theme.FontBold; mt.TextSize = 15; mt.TextColor3 = Theme.Text; mt.TextXAlignment = Enum.TextXAlignment.Left
        mt.Text = "Add Custom Game"; mt.ZIndex = 81; mt.Parent = modal
        local function field(y, ph)
            local b = Instance.new("TextBox")
            b.Size = UDim2.new(1, -24, 0, 32); b.Position = UDim2.new(0,12,0,y)
            b.BackgroundColor3 = Theme.Element; b.Font = Theme.Font; b.TextSize = 13; b.TextColor3 = Theme.Text
            b.PlaceholderText = ph; b.PlaceholderColor3 = Theme.TextDim; b.ClearTextOnFocus = false; b.Text = ""
            b.TextXAlignment = Enum.TextXAlignment.Left; b.BorderSizePixel = 0; b.ZIndex = 81; b.Parent = modal
            corner(b, UDim.new(0,8)); stroke(b, Theme.Stroke, 1, 0.2)
            local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,10); p.Parent = b
            return b
        end
        local nBox = field(46, "Game name")
        local idBox = field(86, "PlaceId (number)")
        local catBox = field(126, "Category (e.g. FPS)")
        local saveB = Instance.new("TextButton")
        saveB.Size = UDim2.new(0, 140, 0, 32); saveB.Position = UDim2.new(0, 12, 0, 186)
        saveB.BackgroundColor3 = Theme.Accent; saveB.Text = "Save & Add"; saveB.Font = Theme.FontBold; saveB.TextSize = 13
        saveB.TextColor3 = Color3.fromRGB(255,255,255); saveB.BorderSizePixel = 0; saveB.ZIndex = 81; saveB.Parent = modal
        corner(saveB, UDim.new(0,8)); addHoverAnim(saveB, 1.05)
        local cancelB = Instance.new("TextButton")
        cancelB.Size = UDim2.new(0, 140, 0, 32); cancelB.Position = UDim2.new(1, -152, 0, 186)
        cancelB.BackgroundColor3 = Theme.ElementHover; cancelB.Text = "Cancel"; cancelB.Font = Theme.FontBold; cancelB.TextSize = 13
        cancelB.TextColor3 = Theme.Text; cancelB.BorderSizePixel = 0; cancelB.ZIndex = 81; cancelB.Parent = modal
        corner(cancelB, UDim.new(0,8)); addHoverAnim(cancelB, 1.05)
        local close = function() tween(modal, 0.18, { BackgroundTransparency = 1 }); task.wait(0.18); modal:Destroy() end
        cancelB.MouseButton1Click:Connect(close)
        saveB.MouseButton1Click:Connect(function()
            local nm = nBox.Text
            local pid = tonumber(idBox.Text) or 0
            local ct = catBox.Text
            if ct == "" then ct = "CUSTOM" end
            if nm ~= "" then
                table.insert(PlaceCustom, { name = nm, id = pid, cat = string.upper(ct), icon = "ðŸŽ®", accent = Theme.Accent })
                saveCustomPlaces()
                notify("Place Teleporter", "Added " .. nm .. " (id " .. pid .. ")", 3, Theme.Green)
                render()
            end
            close()
        end)
    end)

    render()
    animateEntrance(root, 0.05)
    bringToFront(root)

    self.Root = root
    self._dead = false
    function self:Destroy()
        self._dead = true
        tween(root, 0.18, { BackgroundTransparency = 1 })
        task.wait(0.18)
        root:Destroy()
        reopen:Destroy()
        PlaceHubState.open = nil
    end
    notify("Place Teleporter", "Loaded. TP to any game, or â–¶ to run its features.", 4, Theme.Accent)
    return self
end

--==============================================================================
--// SERVER BROWSER  (browse & join servers of the current place, with stats)
--   Real TeleportService:GetSortedAsync paging, animated server rows,
--   join buttons, auto-rejoin, and "join smallest/largest server" helpers.
--==============================================================================
local function ServerBrowser()
    local w = createWindow("Server Browser", "Browse & join servers", 470, 580, randPos(470, 580))
    w:AddSection("Current Game")
    w:AddLabel("Place: " .. tostring(game.PlaceId))
    w:AddLabel("JobId: " .. tostring(game.JobId))
    w:AddLabel("Players here: " .. #Players:GetPlayers())
    w:AddSection("Quick Actions")
    w:AddButton("Rejoin This Server", function()
        notify("Servers", "Rejoining current server...", 3, Theme.Accent)
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end\n    end\nend\n\nreturn M\n
