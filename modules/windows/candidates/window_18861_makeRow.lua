local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 44)
        row.BackgroundColor3 = Theme.Element
        row.BorderSizePixel = 0
        row.ZIndex = 11
        row.Parent = rowsFrame
        corner(row, Theme.Rounded)
        local st = stroke(row, Theme.Stroke, 1, 0.2)
        local num = Instance.new("TextLabel")
        num.BackgroundTransparency = 1; num.Position = UDim2.new(0,8,0,0); num.Size = UDim2.new(0,28,1,0)
        num.Font = Theme.FontBold; num.TextSize = 14; num.TextColor3 = Theme.AccentBright; num.Text = "#" .. idx
        num.ZIndex = 12; num.Parent = row
        local pl = Instance.new("TextLabel")
        pl.BackgroundTransparency = 1; pl.Position = UDim2.new(0,42,0,6); pl.Size = UDim2.new(1,-150,0,16)
        pl.Font = Theme.FontBold; pl.TextSize = 12; pl.TextColor3 = Theme.Text; pl.TextXAlignment = Enum.TextXAlignment.Left
        pl.Text = item.Playing .. " / " .. item.MaxPlayers .. " players"
        pl.ZIndex = 12; pl.Parent = row
        local pct = math.clamp(item.Playing / math.max(item.MaxPlayers, 1), 0, 1)
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -150, 0, 6); bar.Position = UDim2.new(0, 42, 0, 28)
        bar.BackgroundColor3 = Theme.ElementHover; bar.BorderSizePixel = 0; bar.ZIndex = 12; bar.Parent = row
        corner(bar, UDim.new(1, 0))
        local barFill = Instance.new("Frame")
        barFill.Size = UDim2.new(pct, 0, 1, 0); barFill.BackgroundColor3 = Color3.fromHSV(pct/2.5, 0.8, 0.8); barFill.BorderSizePixel = 0; barFill.ZIndex = 13; barFill.Parent = bar
        corner(barFill, UDim.new(1, 0))
        local join = Instance.new("TextButton")
        join.Size = UDim2.new(0, 70, 0, 28); join.Position = UDim2.new(1, -80, 0.5, -14)
        join.BackgroundColor3 = Theme.Accent; join.Text = "Join"; join.Font = Theme.FontBold; join.TextSize = 12
        join.TextColor3 = Color3.fromRGB(255,255,255); join.BorderSizePixel = 0; join.ZIndex = 12; join.Parent = row
        corner(join, UDim.new(0, 7))
        local us = Instance.new("UIScale"); us.Scale = 1; us.Parent = join
        join.MouseEnter:Connect(function() tween(us, 0.1, {Scale = 1.08}) end)
        join.MouseLeave:Connect(function() tween(us, 0.1, {Scale = 1}) end)
        row.MouseEnter:Connect(function() tween(st, 0.1, { Color = Theme.Accent, Transparency = 0 }) end)
        row.MouseLeave:Connect(function() tween(st, 0.1, { Color = Theme.Stroke, Transparency = 0.2 }) end)
        join.MouseButton1Click:Connect(function()
            if item.Id == game.JobId then
                notify("Servers", "You're already in this server.", 3, Theme.Yellow)
                return
            end
            notify("Servers", "Joining server #" .. idx .. "...", 3, Theme.Accent)
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, item.Id, LocalPlayer) end)
        end)
    end

    w:AddButton("Load Server List", function()
        for _, c in ipairs(rowsFrame:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
        notify("Servers", "Querying servers...", 2.5, Theme.Accent)
        task.spawn(function()
            local ok, pages = pcall(function() return TeleportService:GetSortedAsync(false, 100) end)
            if not ok or not pages then
                notify("Servers", "Could not fetch servers (Studio limit).", 3, Theme.Red)
                return
            end
            local shown = 0
            for _, item in ipairs(pages:GetCurrentPage()) do
                if shown >= 20 then break end
                shown = shown + 1
                makeRow(item, shown)
                task.wait(0.02)
            end
            notify("Servers", "Loaded " .. shown .. " servers.", 3, Theme.Green)
        end)
    end, Theme.Accent)
    w:AddButton("Clear List", function()
        for _, c in ipairs(rowsFrame:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    end, Theme.Yellow)
    w:AddSection("Info")
    w:AddLabel("TeleportService works on live games; Studio may limit it.")
    notify("Server Browser", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// Z3US-STYLE SCRIPT LOADER  ("Z3US Loader")
--   A faithful recreation of the Z3US game-select hub: a draggable + minimizable
--   window with a vertical list of styled game cards (Arsenal, Planks, OneTap,
--   Rivals, Counterblox, Gunfight Arena, Universal), a SCRIPT_KEY input, an
--   autoload toggle, a silentload toggle, and a version selector (New/Old) for
--   Counterblox. Clicking a card selects it; the "Load" button runs the matching
--   built-in feature window (since this is a Studio test suite, it opens the
--   feature suite locally instead of loadstring-ing an external premium script).
--   Selection is remembered, and the load flow mirrors Z3US exactly:
--     selectedOption == "Arsenal"  -> open Arsenal suite
--     selectedOption == "Planks"   -> open Planks suite
--     selectedOption == "OneTap"   -> open One Tap suite
--     selectedOption == "Rivals"   -> open Rivals suite (waits for game load)
--     selectedOption == "Counterblox" -> open Counterblox suite
--     selectedOption == "Gunfight Arena" -> open Gunfight Arena suite
--     selectedOption == "Universal" -> open Universal suite
--==============================================================================

-- Z3US shared global state (mirrors getgenv() used by the real loaders).
local Z3USState = {
    SCRIPT_KEY = "",
    autoload = false,
    silentload = false,
    version = "New",
    selectedOption = nil,
    selectedCard = nil,
}

-- Mirror getgenv() so the same pattern works for real executors too.
pcall(function()
    if getgenv then
        getgenv().SCRIPT_KEY = Z3USState.SCRIPT_KEY
        getgenv().autoload = Z3USState.autoload
        getgenv().silentload = Z3USState.silentload
    end
end)

-- Maps a Z3US game option -> the built-in builder that opens on "Load".
local Z3USGames = {
    { option = "Arsenal",        icon = "ðŸ”«", accent = Color3.fromRGB(255,90,90),   builder = "Arsenal",        detected = false },
    { option = "Planks",         icon = "ðŸªµ", accent = Color3.fromRGB(120,200,120), builder = "Planks",         detected = false },
    { option = "OneTap",         icon = "ðŸ’¥", accent = Color3.fromRGB(180,80,255),  builder = "One Tap",        detected = false },
    { option = "Rivals",         icon = "ðŸŽ¯", accent = Color3.fromRGB(70,150,255),  builder = "Rivals",         detected = false },
    { option = "Counterblox",    icon = "ðŸ§¨", accent = Color3.fromRGB(255,200,60),  builder = "Counterblox",    detected = true },
    { option = "Gunfight Arena", icon = "ðŸ”«", accent = Color3.fromRGB(255,110,90),  builder = "Gunfight Arena", detected = false },
    { option = "Universal",      icon = "ðŸŒ", accent = Theme.Accent,                builder = "Universal",      detected = false },
}

-- Open a feature window by its registered name (used by the Load button).
local function openFeatureByName(name)
    local found = nil
    for _, entry in ipairs(GameList) do
        if entry.name == name then found = entry; break end
    end
    if not found then
        notify("Z3US", "No suite for '" .. name .. "'.", 3, Theme.Red)
        return nil
    end
    if OpenWindows[name] and not OpenWindows[name]._destroyed then
        OpenWindows[name].Root.Visible = true
        bringToFront(OpenWindows[name].Root)
        return OpenWindows[name]
    else
        local ok, win = pcall(found.builder)
        if ok and win then
            OpenWindows[name] = win
            return win
        else
            notify("Z3US", "Failed to load " .. name .. ": " .. tostring(win), 4, Theme.Red)
        end
    end
    return nil
end

-- The Z3US "Load" handler â€” mirrors the original if/elseif chain.
local function z3usLoad()
    local opt = Z3USState.selectedOption
    if not opt then
        notify("Z3US", "No script selected.", 3, Theme.Yellow)
        return
    end

    -- Mirror Z3US global plumbing (real executors read these).
    pcall(function()
        if getgenv then
            getgenv().SCRIPT_KEY = Z3USState.SCRIPT_KEY
            getgenv().autoload = Z3USState.autoload
            getgenv().silentload = Z3USState.silentload
        end
    end)

    -- Replicate Z3US' load gate: wait for game + character + no loading screen
    if not game:IsLoaded() then
        notify("Z3US", "Waiting for game to load...", 3, Theme.Yellow)
        repeat task.wait() until game:IsLoaded()
    end

    local function openAndNotify(name, detectedMsg)
        if Z3USState.silentload then
            notify("Z3US", "(silent) Loading " .. name .. "...", 3, Theme.Accent)
        else
            notify("Z3US", "Loading " .. name .. "...", 3, Theme.Accent)
        end
        if detectedMsg then
            notify("Z3US", "NOTE: " .. detectedMsg, 4, Theme.Yellow)
        end
        task.spawn(function()
            if name == "Rivals" then
                -- Z3US waits for character + no LoadingScreen for Rivals
                repeat task.wait() until LocalPlayer and LocalPlayer.Character
                local pg = LocalPlayer:FindFirstChild("PlayerGui")
                if pg then
                    repeat task.wait() until not pg:FindFirstChild("LoadingScreen")
                end
            end
            task.wait(0.2)
            local win = openFeatureByName(name)
            if win then
                notify("Z3US", name .. " loaded" .. (Z3USState.autoload and " (autoload on)" or "") .. ".", 3, Theme.Green)
            end
        end)
    end

    -- The exact if/elseif chain from Z3US' other.lua.
    if opt == "Arsenal" then
        openAndNotify("Arsenal")
    elseif opt == "Planks" then
        openAndNotify("Planks")
    elseif opt == "OneTap" then
        openAndNotify("One Tap")
    elseif opt == "Rivals" then
        openAndNotify("Rivals")
    elseif opt == "Counterblox" then
        if Z3USState.version == "New" then
            -- In the original, the New version is detected and kicks you.
            -- We emulate the warning instead of actually kicking in Studio.
            notify("Z3US", "âš  The 'New' Counterblox script is detected and would kick/ban you.", 5, Theme.Red)
            notify("Z3US", "Switching to 'Old' version is recommended. Loading Old suite...", 4, Theme.Yellow)
            Z3USState.version = "Old"
        end
        openAndNotify("Counterblox")
    elseif opt == "Gunfight Arena" then
        openAndNotify("Gunfight Arena")
    elseif opt == "Universal" then
        openAndNotify("Universal")
    else
        notify("Z3US", "Unknown option: " .. tostring(opt), 3, Theme.Red)
    end
end

-- Build the animated Z3US Loader window.
local Z3USHubState = { open = nil }
local function buildZ3USLoader()
    if Z3USHubState.open and not Z3USHubState.open._dead then
        Z3USHubState.open.Root.Visible = true
        bringToFront(Z3USHubState.open.Root)
        return Z3USHubState.open
    end

    local self = { _dead = false }
    Z3USHubState.open = self

    local root = Instance.new("Frame")
    root.Name = "Z3USLoader"
    root.Size = UDim2.new(0, 460, 0, 560)
    root.Position = UDim2.new(0.5, -230, 0.5, -280)
    root.BackgroundColor3 = Color3.fromRGB(17, 18, 20)
    root.BorderSizePixel = 0
    root.ZIndex = 10
    root.Parent = ScreenGui
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 18); rc.Parent = root
    local rStroke = stroke(root, Color3.fromRGB(40, 44, 56), 2, 0)
    local accentGlow = Instance.new("UIStroke")
    accentGlow.Color = Theme.Accent; accentGlow.Thickness = 1.5; accentGlow.Transparency = 0.7; accentGlow.Parent = root

    -- HEADER (Z3US-style dark header)
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundColor3 = Color3.fromRGB(22, 23, 27)
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 18); hc.Parent = header
    local hfill = Instance.new("Frame"); hfill.Size = UDim2.new(1,0,0,30); hfill.BackgroundColor3 = Color3.fromRGB(22,23,27); hfill.BorderSizePixel=0; hfill.ZIndex=11; hfill.Position=UDim2.new(0,0,0,30); hfill.Parent=header

    -- Z3US logo badge
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 38, 0, 38)
    logo.Position = UDim2.new(0, 16, 0.5, -19)
    logo.BackgroundColor3 = Theme.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 12
    logo.Parent = header
    local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0, 10); lc.Parent = logo
    gradient(logo, Theme.AccentBright, Theme.AccentDark, 45)
    local logoTxt = Instance.new("TextLabel")
    logoTxt.BackgroundTransparency = 1; logoTxt.Size = UDim2.new(1,0,1,0)
    logoTxt.Font = Theme.FontBold; logoTxt.TextSize = 18; logoTxt.TextColor3 = Color3.fromRGB(255,255,255)
    logoTxt.Text = "Z"; logoTxt.ZIndex = 13; logoTxt.Parent = logo

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 62, 0, 12)
    title.Size = UDim2.new(1, -180, 0, 20)
    title.Font = Theme.FontBold; title.TextSize = 17; title.TextColor3 = Color3.fromRGB(255,255,255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Z3US Loader"
    title.ZIndex = 12; title.Parent = header

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 62, 0, 33)
    sub.Size = UDim2.new(1, -180, 0, 14)
    sub.Font = Theme.Font; sub.TextSize = 11; sub.TextColor3 = Color3.fromRGB(140,150,170)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Select a game, then Load"
    sub.ZIndex = 12; sub.Parent = header

    -- window controls
    local function ctrl(txt, color, x, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 30, 0, 30); b.Position = UDim2.new(1, x, 0.5, -15)
        b.BackgroundColor3 = Color3.fromRGB(30,32,38); b.Text = txt
        b.Font = Theme.FontBold; b.TextSize = 14; b.TextColor3 = color
        b.BorderSizePixel = 0; b.ZIndex = 12; b.Parent = header
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = b
        local us = Instance.new("UIScale"); us.Scale = 1; us.Parent = b
        b.MouseEnter:Connect(function() tween(us, 0.1, {Scale=1.1}) end)
        b.MouseLeave:Connect(function() tween(us, 0.1, {Scale=1}) end)
        b.MouseButton1Click:Connect(fn)
        return b
    end

    local content = Instance.new("Frame")
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, 0, 1, -60)
    content.Position = UDim2.new(0, 0, 0, 60)
    content.ZIndex = 11
    content.Parent = root

    -- status label (replaces "No Script Selected")
    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 16, 0, 12)
    status.Size = UDim2.new(1, -32, 0, 18)
    status.Font = Theme.FontBold; status.TextSize = 13; status.TextColor3 = Color3.fromRGB(255,255,255)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "No Script Selected"
    status.ZIndex = 12; status.Parent = content

    -- game card list
    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.new(0, 14, 0, 40)
    list.Size = UDim2.new(1, -28, 0, 250)
    list.BackgroundTransparency = 1
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = Theme.Accent
    list.CanvasSize = UDim2.new(0,0,0,0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ZIndex = 11
    list.Parent = content
    local lp = Instance.new("UIPadding"); lp.PaddingTop=UDim.new(0,2); lp.Parent=list
    local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 8); lay.Parent = list

    local cardButtons = {}
    local function selectOption(opt)
        Z3USState.selectedOption = opt
        status.Text = "Selected: " .. opt
        for o, btn in pairs(cardButtons) do
            local sel = (o == opt)
            tween(btn, 0.12, { BackgroundColor3 = sel and Color3.fromRGB(40,44,56) or Color3.fromRGB(17,18,20) })
            local st = btn:FindFirstChild("SelStroke")
            if st then
                tween(st, 0.12, { Color = sel and (Theme.Accent) or Color3.fromRGB(26,29,37), Transparency = sel and 0 or 0.2 })
            end
            local ch = btn:FindFirstChild("Check")
            if ch then ch.Visible = sel end
        end
    end

    for _, g in ipairs(Z3USGames) do
        local card = Instance.new("TextButton")
        card.Size = UDim2.new(1, 0, 0, 54)
        card.BackgroundColor3 = Color3.fromRGB(17, 18, 20)
        card.BackgroundTransparency = 0.1
        card.AutoButtonColor = false
        card.Text = ""
        card.BorderSizePixel = 0
        card.ZIndex = 11
        card.Parent = list
        local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 14); cc.Parent = card
        local st = stroke(card, Color3.fromRGB(26,29,37), 1.9, 0.2)
        st.Name = "SelStroke"
        local us = Instance.new("UIScale"); us.Scale = 1; us.Parent = card
        card.MouseEnter:Connect(function() tween(us, 0.1, {Scale=1.02}) end)
        card.MouseLeave:Connect(function() tween(us, 0.1, {Scale=1}) end)

        local icon = Instance.new("Frame")
        icon.Size = UDim2.new(0, 38, 0, 38)
        icon.Position = UDim2.new(0, 10, 0.5, -19)
        icon.BackgroundColor3 = g.accent
        icon.BorderSizePixel = 0
        icon.ZIndex = 12
        icon.Parent = card
        local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 10); ic.Parent = icon
        local iconTxt = Instance.new("TextLabel")
        iconTxt.BackgroundTransparency = 1; iconTxt.Size = UDim2.new(1,0,1,0)
        iconTxt.Font = Theme.Font; iconTxt.TextSize = 18; iconTxt.Text = g.icon
        iconTxt.ZIndex = 13; iconTxt.Parent = icon

        local name = Instance.new("TextLabel")
        name.BackgroundTransparency = 1
        name.Position = UDim2.new(0, 58, 0, 11)
        name.Size = UDim2.new(1, -100, 0, 18)
        name.Font = Theme.FontBold; name.TextSize = 15; name.TextColor3 = Color3.fromRGB(255,255,255)
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Text = g.option
        name.ZIndex = 12; name.Parent = card

        local det = ""
        if g.detected then det = "âš  detected" end
        local meta = Instance.new("TextLabel")
        meta.BackgroundTransparency = 1
        meta.Position = UDim2.new(0, 58, 0, 30)
        meta.Size = UDim2.new(1, -100, 0, 14)
        meta.Font = Theme.Font; meta.TextSize = 11
        meta.TextColor3 = g.detected and Color3.fromRGB(235,77,92) or Color3.fromRGB(120,130,150)
        meta.TextXAlignment = Enum.TextXAlignment.Left
        meta.Text = det ~= "" and det or "supported"
        meta.ZIndex = 12; meta.Parent = card

        -- selected checkmark
        local check = Instance.new("TextLabel")
        check.BackgroundTransparency = 1
        check.Position = UDim2.new(1, -34, 0.5, -12)
        check.Size = UDim2.new(0, 24, 0, 24)
        check.Font = Theme.FontBold; check.TextSize = 16; check.TextColor3 = Theme.AccentBright
        check.Text = "âœ“"; check.Visible = false; check.ZIndex = 13; check.Parent = card

        card.MouseButton1Click:Connect(function()
            selectOption(g.option)
            local cf = Instance.new("UIScale"); cf.Scale = 0.94; cf.Parent = card
            tween(cf, 0.12, { Scale = 1 })
        end)
        cardButtons[g.option] = card
    end

    -- OPTIONS: script key, autoload, silentload, version
    local optHolder = Instance.new("Frame")
    optHolder.Position = UDim2.new(0, 14, 0, 300)
    optHolder.Size = UDim2.new(1, -28, 0, 116)
    optHolder.BackgroundColor3 = Color3.fromRGB(20, 21, 25)
    optHolder.BackgroundTransparency = 0.2
    optHolder.BorderSizePixel = 0
    optHolder.ZIndex = 11
    optHolder.Parent = content
    local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 12); oc.Parent = optHolder
    stroke(optHolder, Color3.fromRGB(40,44,56), 1, 0.2)
    local opad = Instance.new("UIPadding"); opad.PaddingTop=UDim.new(0,8); opad.PaddingBottom=UDim.new(0,8); opad.PaddingLeft=UDim.new(0,10); opad.PaddingRight=UDim.new(0,10); opad.Parent=optHolder
    local olay = Instance.new("UIListLayout"); olay.Padding = UDim.new(0, 6); olay.Parent = optHolder

    -- SCRIPT_KEY input
    local keyBox = Instance.new("TextBox")
    keyBox.Size = UDim2.new(1, 0, 0, 30)
    keyBox.BackgroundColor3 = Color3.fromRGB(13,14,17)
    keyBox.Font = Theme.FontMono; keyBox.TextSize = 12; keyBox.TextColor3 = Color3.fromRGB(255,255,255)
    keyBox.PlaceholderText = "SCRIPT_KEY (paste your key)"
    keyBox.PlaceholderColor3 = Color3.fromRGB(120,130,150)
    keyBox.ClearTextOnFocus = false; keyBox.Text = ""
    keyBox.TextXAlignment = Enum.TextXAlignment.Left
    keyBox.BorderSizePixel = 0; keyBox.ZIndex = 12; keyBox.Parent = optHolder
    local kbc = Instance.new("UICorner"); kbc.CornerRadius = UDim.new(0,8); kbc.Parent = keyBox
    stroke(keyBox, Color3.fromRGB(40,44,56), 1, 0.2)
    local kpad = Instance.new("UIPadding"); kpad.PaddingLeft = UDim.new(0,10); kpad.Parent = keyBox
    keyBox.FocusLost:Connect(function() Z3USState.SCRIPT_KEY = keyBox.Text; pcall(function() if getgenv then getgenv().SCRIPT_KEY = keyBox.Text end end) end)

    -- autoload + silentload row
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.ZIndex = 12; row.Parent = optHolder
    local rlay = Instance.new("UIListLayout"); rlay.FillDirection = Enum.FillDirection.Horizontal; rlay.Padding = UDim.new(0, 8); rlay.Parent = row

    local function miniToggle(labelText, default, cb)
        local f = Instance.new("TextButton")
        f.Size = UDim2.new(0.5, -4, 1, 0)
        f.BackgroundColor3 = Color3.fromRGB(13,14,17)
        f.Text = "  " .. labelText .. (default and "  â—" or "  â—‹")
        f.Font = Theme.FontBold; f.TextSize = 11; f.TextColor3 = default and Theme.AccentBright or Color3.fromRGB(160,170,190)
        f.TextXAlignment = Enum.TextXAlignment.Left
        f.BorderSizePixel = 0; f.ZIndex = 13; f.Parent = row
        local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0,8); mc.Parent = f
        local st = stroke(f, Color3.fromRGB(40,44,56), 1, 0.2)
        local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0,8); pad.Parent = f
        local state = default
        f.MouseButton1Click:Connect(function()
            state = not state
            f.Text = "  " .. labelText .. (state and "  â—" or "  â—‹")
            f.TextColor3 = state and Theme.AccentBright or Color3.fromRGB(160,170,190)
            tween(st, 0.12, { Color = state and Theme.Accent or Color3.fromRGB(40,44,56) })
            cb(state)
        end)
        return f
    end
    miniToggle("autoload", false, function(v) Z3USState.autoload = v; pcall(function() if getgenv then getgenv().autoload = v end end) end)
    miniToggle("silentload", false, function(v) Z3USState.silentload = v; pcall(function() if getgenv then getgenv().silentload = v end end) end)

    -- version selector (New / Old) for Counterblox
    local verRow = Instance.new("Frame")
    verRow.Size = UDim2.new(1, 0, 0, 30)
    verRow.BackgroundTransparency = 1
    verRow.ZIndex = 12; verRow.Parent = optHolder
    local vlay = Instance.new("UIListLayout"); vlay.FillDirection = Enum.FillDirection.Horizontal; vlay.Padding = UDim.new(0, 8); vlay.Parent = verRow
    local vlbl = Instance.new("TextLabel")
    vlbl.Size = UDim2.new(0, 70, 1, 0); vlbl.BackgroundTransparency = 1
    vlbl.Font = Theme.FontBold; vlbl.TextSize = 11; vlbl.TextColor3 = Color3.fromRGB(160,170,190)
    vlbl.TextXAlignment = Enum.TextXAlignment.Left; vlbl.Text = "  CB version:"; vlbl.ZIndex = 13; vlbl.Parent = verRow
    local vbtns = {}
    for _, vn in ipairs({ "New", "Old" }) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 60, 1, 0)
        b.BackgroundColor3 = (vn == Z3USState.version) and Theme.Accent or Color3.fromRGB(13,14,17)
        b.Text = vn; b.Font = Theme.FontBold; b.TextSize = 11
        b.TextColor3 = (vn == Z3USState.version) and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,170,190)
        b.BorderSizePixel = 0; b.ZIndex = 13; b.Parent = verRow
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = b
        b.MouseButton1Click:Connect(function()
            Z3USState.version = vn
            for n2, b2 in pairs(vbtns) do
                local sel = (n2 == vn)
                tween(b2, 0.12, { BackgroundColor3 = sel and Theme.Accent or Color3.fromRGB(13,14,17) })
                b2.TextColor3 = sel and Color3.fromRGB(255,255,255) or Color3.fromRGB(160,170,190)
            end
        end)
        vbtns[vn] = b
    end

    -- LOAD button (big, Z3US-style)
    local loadBtn = Instance.new("TextButton")
    loadBtn.Position = UDim2.new(0, 14, 1, -56)
    loadBtn.Size = UDim2.new(1, -28, 0, 44)
    loadBtn.BackgroundColor3 = Theme.Accent
    loadBtn.Text = "Load"
    loadBtn.Font = Theme.FontBold; loadBtn.TextSize = 18
    loadBtn.TextColor3 = Color3.fromRGB(255,255,255)
    loadBtn.BorderSizePixel = 0; loadBtn.ZIndex = 12; loadBtn.Parent = content
    local lbcc = Instance.new("UICorner"); lbcc.CornerRadius = UDim.new(0, 14); lbcc.Parent = loadBtn
    gradient(loadBtn, Theme.AccentBright, Theme.AccentDark, 0)
    local lus = Instance.new("UIScale"); lus.Scale = 1; lus.Parent = loadBtn
    loadBtn.MouseEnter:Connect(function() tween(lus, 0.1, {Scale=1.03}) end)
    loadBtn.MouseLeave:Connect(function() tween(lus, 0.1, {Scale=1}) end)
    loadBtn.MouseButton1Click:Connect(function()
        tween(lus, 0.08, {Scale=0.97}); task.wait(0.08); tween(lus, 0.1, {Scale=1})
        z3usLoad()
    end)

    -- footer credit
    local credit = Instance.new("TextLabel")
    credit.BackgroundTransparency = 1
    credit.Position = UDim2.new(0, 0, 1, -18)
    credit.Size = UDim2.new(1, 0, 0, 14)
    credit.Font = Theme.Font; credit.TextSize = 10; credit.TextColor3 = Color3.fromRGB(70,80,110)
    credit.Text = "Z3US-style loader  â€¢  Studio test suite"
    credit.ZIndex = 12; credit.Parent = content

    -- minimize / close
    local minimized = false
    local fullSize = root.Size
    ctrl("â€“", Theme.Yellow, -38, function()
        minimized = not minimized
        if minimized then
            fullSize = root.Size
            tween(root, 0.22, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 60) })
            content.Visible = false
        else
            tween(root, 0.22, { Size = fullSize })
            content.Visible = true
        end
    end)
    ctrl("âœ•", Theme.Red, -74, function()
        tween(root, 0.2, { BackgroundTransparency = 1 })
        task.wait(0.2)
        self:Destroy()
    end)

    makeDraggable(root, header)
    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bringToFront(root)
        end
    end)

    -- entrance animation
    local us = Instance.new("UIScale"); us.Scale = 0.92; us.Parent = root
    root.BackgroundTransparency = 0.15
    root.Position = root.Position + UDim2.new(0, 0, 0, 20)
    tween(root, 0.35, { BackgroundTransparency = 0 })
    tween(us, 0.35, { Scale = 1 })
    tween(root, 0.35, { Position = root.Position - UDim2.new(0, 0, 0, 20) })
    bringToFront(root)

    self.Root = root
    function self:Destroy()
        self._dead = true
        tween(root, 0.18, { BackgroundTransparency = 1 })
        local usd = root:FindFirstChildOfClass("UIScale")
        if usd then tween(usd, 0.18, { Scale = 0.9 }) end
        task.wait(0.18)
        root:Destroy()
        Z3USHubState.open = nil
    end

    notify("Z3US Loader", "Select a game and press Load.", 4, Theme.Accent)
    return self
end

--==============================================================================
--// GAME REGISTRY  (order shown in the hub list)
--==============================================================================
GameList = {
    { name = "Universal",            cat = "GLOBAL",   icon = "ðŸŒ", desc = "Works in every game",   color = Theme.Accent,        builder = Universal },
    { name = "Auto-Detect Game",     cat = "GLOBAL",   icon = "ðŸ”", desc = "Detect game by PlaceId & load", color = Theme.AccentBright, builder = function() local e = autoLoadDetected(); if not e then return Universal() end return OpenWindows[e.name] or Universal() end },
    { name = "Script Manager",       cat = "GLOBAL",   icon = "ðŸ“¥", desc = "Load external scripts (DaraHub-style)", color = Theme.AccentBright, builder = ScriptManager },
    { name = "Teleport Pro",         cat = "GLOBAL",   icon = "ðŸ“", desc = "Saved spots, paths, part TP", color = Theme.AccentBright, builder = TeleportProWindow },
    { name = "Place Teleporter",     cat = "GLOBAL",   icon = "ðŸš€", desc = "TP to any game by PlaceId (animated grid)", color = Theme.AccentBright, builder = buildPlaceHub },
    { name = "Server Browser",       cat = "GLOBAL",   icon = "ðŸ›°ï¸", desc = "Browse & join servers", color = Theme.AccentBright, builder = ServerBrowser },
    { name = "Z3US Loader",          cat = "GLOBAL",   icon = "âš¡", desc = "Z3US game loader (key/autoload)", color = Theme.AccentBright, builder = buildZ3USLoader },
    { name = "Camera Suite",         cat = "GLOBAL",   icon = "ðŸ“·", desc = "FOV, lighting, freecam, visuals", color = Theme.AccentBright, builder = CameraSuite },
    { name = "Movement Suite",       cat = "GLOBAL",   icon = "ðŸƒ", desc = "All movement features",  color = Theme.AccentBright, builder = MovementSuite },
    { name = "Combat Suite",         cat = "GLOBAL",   icon = "âš”ï¸", desc = "All combat features",    color = Theme.AccentBright, builder = CombatSuite },
    { name = "Visual Suite",         cat = "GLOBAL",   icon = "ðŸ‘ï¸", desc = "All ESP & visuals",      color = Theme.AccentBright, builder = VisualSuite },
    { name = "World Suite",          cat = "GLOBAL",   icon = "ðŸŒ", desc = "World & utility tools",  color = Theme.AccentBright, builder = WorldSuite },
    { name = "Arsenal",              cat = "FPS",      icon = "ðŸ”«", desc = "Gunplay suite",          color = Color3.fromRGB(255,90,90),   builder = Arsenal },
    { name = "Rivals",               cat = "FPS",      icon = "ðŸŽ¯", desc = "Competitive FPS",        color = Color3.fromRGB(70,150,255),  builder = Rivals },
    { name = "Hypershot",            cat = "FPS",      icon = "âš¡", desc = "Ball shooter",           color = Color3.fromRGB(255,170,60),  builder = Hypershot },
    { name = "Counterblox",          cat = "FPS",      icon = "ðŸ§¨", desc = "CS-style FPS",           color = Color3.fromRGB(255,200,60),  builder = Counterblox },
    { name = "Gunfight Arena",       cat = "FPS",      icon = "ðŸ”«", desc = "Arena FPS",              color = Color3.fromRGB(255,110,90),  builder = GunfightArena },
    { name = "Planks",               cat = "FPS",      icon = "ðŸªµ", desc = "Planks FPS",             color = Color3.fromRGB(120,200,120), builder = Planks },
    { name = "Strucid",              cat = "FPS",      icon = "ðŸ›¡ï¸", desc = "Build FPS",              color = Color3.fromRGB(120,180,255), builder = Strucid },
    { name = "Apocalypse Rising",    cat = "SURVIVAL", icon = "ðŸ§Ÿ", desc = "Survival loot FPS",      color = Color3.fromRGB(120,140,90),  builder = ApocalypseRising },
    { name = "Vehicle Legends",      cat = "SIMULATOR",icon = "ðŸŽï¸", desc = "Drive & collect",        color = Color3.fromRGB(255,90,90),   builder = VehicleLegends },
    { name = "Roblox High School 2", cat = "RP",       icon = "ðŸŽ“", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RobloxHigh2 },
    { name = "Auto Strategy",        cat = "STRATEGY", icon = "â™Ÿï¸", desc = "Auto place units",       color = Theme.Accent,                builder = AutoStrategy },
    { name = "Zombie Survival",      cat = "ACTION",   icon = "ðŸ§Ÿ", desc = "Wave fighter",           color = Color3.fromRGB(120,200,80),  builder = ZombieSurvival },
    { name = "Knife Simulator",      cat = "SIMULATOR",icon = "ðŸ”ª", desc = "Auto throw",             color = Theme.Yellow,                builder = KnifeSim },
    { name = "Tap Simulator",        cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto tap",               color = Theme.Yellow,                builder = TapSim },
    { name = "Sus Game",             cat = "ACTION",   icon = "ðŸ‘¨â€ðŸš€", desc = "Among-style roles",      color = Theme.Red,                   builder = SusGame },
    { name = "Lift Game",            cat = "SIMULATOR",icon = "ðŸ‹ï¸", desc = "Auto lift",              color = Theme.Yellow,                builder = LiftGame },
    { name = "Grow a Tree",          cat = "SIMULATOR",icon = "ðŸŒ³", desc = "Auto grow & harvest",    color = Color3.fromRGB(120,200,120), builder = GrowTree },
    { name = "Gravity Shift",        cat = "ACTION",   icon = "ðŸŒ€", desc = "Gravity control",        color = Color3.fromRGB(150,150,200), builder = GravityShift },
    { name = "Raft Survival",        cat = "SURVIVAL", icon = "â›µ", desc = "Ocean survival",         color = Color3.fromRGB(86,156,240),  builder = RaftSurvival },
    { name = "Pet Gacha",            cat = "RNG",      icon = "ðŸŽ°", desc = "Auto roll pets",          color = Color3.fromRGB(255,150,180), builder = GachaGame },
    { name = "Trading Cards",        cat = "COLLECT",  icon = "ðŸƒ", desc = "Open & trade cards",     color = Color3.fromRGB(180,180,200), builder = TradingCards },
    { name = "Arcade / Minigames",   cat = "PARTY",    icon = "ðŸ•¹ï¸", desc = "Auto-play minigames",    color = Theme.Accent,                builder = ArcadeHub },
    { name = "Battle Royale",        cat = "FPS",      icon = "ðŸŽ–ï¸", desc = "Loot & survive",         color = Color3.fromRGB(180,140,80),  builder = BattleRoyale },
    { name = "Build / Creative",     cat = "SANDBOX",  icon = "ðŸ§±", desc = "Build helper",           color = Color3.fromRGB(120,200,120), builder = BuildGame },
    { name = "Space Survival",       cat = "SURVIVAL", icon = "ðŸš€", desc = "Sci-fi farm",            color = Color3.fromRGB(120,180,255), builder = SpaceSurvival },
    { name = "Hide & Seek Extreme",  cat = "ACTION",   icon = "ðŸ™ˆ", desc = "Hide & survive",         color = Theme.Accent,                builder = HideSeekExtreme },
    { name = "Factory Tycoon",       cat = "TYCOON",   icon = "ðŸ­", desc = "Auto production",        color = Color3.fromRGB(120,180,200), builder = FactoryTycoon },
    { name = "Block Sandbox",        cat = "SANDBOX",  icon = "â¬›", desc = "Mine & build",           color = Color3.fromRGB(120,200,120), builder = BlockSandbox },
    { name = "Racing / Kart",        cat = "RACING",   icon = "ðŸ", desc = "Drive & boost",          color = Color3.fromRGB(255,120,80),  builder = KartGame },
    { name = "Social / Hangout",     cat = "SOCIAL",   icon = "ðŸ’¬", desc = "Auto chat & emote",      color = Theme.Accent,                builder = SocialGame },
    { name = "Endless Obby",         cat = "OBBY",     icon = "ðŸªœ", desc = "Auto-climb towers",      color = Color3.fromRGB(122,200,120), builder = EndlessObby },
    { name = "Wave Defense",         cat = "STRATEGY", icon = "ðŸŒŠ", desc = "Defend waves",           color = Color3.fromRGB(120,200,80),  builder = WaveDefense },
    { name = "Shooter Arena",        cat = "FPS",      icon = "ðŸŽ¯", desc = "Arena shooter",          color = Color3.fromRGB(255,120,80),  builder = ShooterArena },
    { name = "Minigames Collection", cat = "PARTY",    icon = "ðŸŽ²", desc = "Party minigames",        color = Theme.Accent,                builder = MinigamesCollection },
    { name = "Idle Factory",         cat = "CLICKER",  icon = "ðŸ—ï¸", desc = "Idle clicker",           color = Theme.Yellow,                builder = IdleFactory },
    { name = "Sword Combat",         cat = "ACTION",   icon = "ðŸ—¡ï¸", desc = "Melee combat",           color = Color3.fromRGB(220,60,60),   builder = SwordCombat },
    { name = "Collect Everything",   cat = "UTILITY",  icon = "ðŸ§²", desc = "Magnet all items",       color = Color3.fromRGB(120,220,120), builder = CollectEverything },
    { name = "Jailbreak",            cat = "OPEN WORLD", icon = "ðŸš“", desc = "Cops & robbers",       color = Color3.fromRGB(120,200,120), builder = Jailbreak },
    { name = "Combat Arena",         cat = "FIGHTING", icon = "âš”ï¸", desc = "Melee / reach",         color = Color3.fromRGB(255,90,90),   builder = CombatArena },
    { name = "Steal a Brainrot",     cat = "COLLECT",  icon = "ðŸ§ ", desc = "Steal & collect",        color = Color3.fromRGB(180,120,255), builder = StealABrainrot },
    { name = "Murder Mystery 2",     cat = "MYSTERY",  icon = "ðŸ”ª", desc = "Roles & survival",       color = Color3.fromRGB(235,77,92),   builder = MurderMystery2 },
    { name = "Blade Ball",           cat = "ACTION",   icon = "âš¾", desc = "Auto parry",             color = Color3.fromRGB(245,196,76),  builder = BladeBall },
    { name = "Tower of Hell",        cat = "OBBY",     icon = "ðŸ—¼", desc = "Climb the tower",        color = Color3.fromRGB(122,200,120), builder = TowerOfHell },
    { name = "Da Hood",              cat = "ACTION",   icon = "ðŸŒ†", desc = "Lock-on & silent aim",   color = Color3.fromRGB(255,120,80),  builder = DaHood },
    { name = "Natural Disasters",    cat = "SURVIVAL", icon = "ðŸŒªï¸", desc = "Survive disasters",      color = Color3.fromRGB(86,156,240),  builder = NaturalDisasters },
    { name = "One Tap",              cat = "FPS",      icon = "ðŸ’¥", desc = "One-shot FPS",           color = Color3.fromRGB(180,80,255),  builder = OneTap },
    { name = "Bee Swarm Simulator",  cat = "SIMULATOR",icon = "ðŸ", desc = "Auto farm fields",       color = Color3.fromRGB(245,196,76),  builder = BeeSwarmSimulator },
    { name = "Flee the Facility",    cat = "SURVIVAL", icon = "ðŸƒ", desc = "Escape the beast",       color = Color3.fromRGB(86,156,240),  builder = FleeTheFacility },
    { name = "Grow a Garden",        cat = "SIMULATOR",icon = "ðŸŒ±", desc = "Auto farm garden",       color = Color3.fromRGB(76,209,142),  builder = GrowAGarden },
    { name = "Grow a Garden PRO",    cat = "SIMULATOR",icon = "ðŸ«", desc = "Full GAG suite",         color = Color3.fromRGB(76,209,142),  builder = GrowAGardenPro },
    { name = "Grow a Garden 2",      cat = "SIMULATOR",icon = "ðŸ¥•", desc = "GAG2 auto farm",         color = Color3.fromRGB(120,200,120), builder = GrowAGarden2 },
    { name = "Steal a Brainrot PRO", cat = "ACTION",   icon = "ðŸ§ ", desc = "Full SAB suite",         color = Color3.fromRGB(180,120,255), builder = StealABrainrotPro },
    { name = "Split or Steal Brainrot",cat = "ACTION", icon = "ðŸ˜ˆ", desc = "PvB steal/split",        color = Color3.fromRGB(180,80,120),  builder = SplitOrStealBrainrot },
    { name = "Swing Obby Brainrots", cat = "OBBY",     icon = "ðŸ¤¸", desc = "Swing obby brainrots",   color = Color3.fromRGB(180,120,255), builder = SwingObbyBrainrots },
    { name = "Parkour for Brainrots",cat = "OBBY",     icon = "ðŸƒ", desc = "Parkour brainrots",      color = Color3.fromRGB(180,120,255), builder = ParkourForBrainrots },
    { name = "Pet Catchers",         cat = "SIMULATOR",icon = "ðŸ¾", desc = "Auto catch pets",        color = Color3.fromRGB(180,120,255), builder = PetCatchers },
    { name = "Pets Go",              cat = "RNG",      icon = "ðŸŽ²", desc = "Roll & collect",         color = Color3.fromRGB(180,120,255), builder = PetsGo },
    { name = "Tap Simulator PRO",    cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto tap suite",         color = Theme.Accent,                builder = TapSimulatorPro },
    { name = "Card RNG",             cat = "RNG",      icon = "ðŸƒ", desc = "Roll & battle",          color = Color3.fromRGB(180,180,200), builder = CardRNG },
    { name = "Brainrot Giant",       cat = "ACTION",   icon = "ðŸ¦£", desc = "Grow & fight",           color = Color3.fromRGB(180,120,255), builder = BrainrotGiant },
    { name = "Brainrot Loaders",     cat = "GLOBAL",   icon = "ðŸ“¥", desc = "External SAB/GAG scripts", color = Theme.AccentBright,       builder = BrainrotExternalLoader },
    { name = "Brainrot Master",      cat = "GLOBAL",   icon = "ðŸ§ ", desc = "Universal brainrot farm", color = Theme.AccentBright,       builder = BrainrotMaster },
    { name = "Brainrot Simulator",   cat = "SIMULATOR",icon = "ðŸŒ€", desc = "Auto-spawn brainrots",   color = Color3.fromRGB(180,120,255), builder = BrainrotSimulator },
    { name = "Merge Brainrot",       cat = "SIMULATOR",icon = "ðŸ”—", desc = "Auto merge units",       color = Color3.fromRGB(180,120,255), builder = MergeBrainrot },
    { name = "Find the Brainrots",   cat = "FIND",     icon = "ðŸ§ ", desc = "Find brainrots",         color = Color3.fromRGB(180,120,255), builder = FindTheBrainrots },
    { name = "Brainrot Tycoon",      cat = "TYCOON",   icon = "ðŸ­", desc = "Brainrot tycoon",        color = Color3.fromRGB(180,120,255), builder = BrainrotTycoon },
    { name = "Brainrot Defend",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Defense game",           color = Color3.fromRGB(180,120,255), builder = BrainrotDefend },
    { name = "Brainrot Clicker",     cat = "CLICKER",  icon = "ðŸ‘†", desc = "Auto click brainrots",   color = Theme.Accent,                builder = BrainrotClicker },
    { name = "Brainrot Battlegrounds",cat="ACTION",    icon = "âš”ï¸", desc = "Combat & steal",         color = Color3.fromRGB(180,120,255), builder = BrainrotBattlegrounds },
    { name = "Brainrot Pet Sim",     cat = "SIMULATOR",icon = "ðŸ¾", desc = "Hatch & collect",        color = Color3.fromRGB(180,120,255), builder = BrainrotPetSim },
    { name = "Brainrot Racing",      cat = "RACING",   icon = "ðŸŽï¸", desc = "Race & collect",         color = Color3.fromRGB(180,120,255), builder = BrainrotRacing },
    { name = "Grow a Tree PRO",      cat = "SIMULATOR",icon = "ðŸŒ³", desc = "Full tree suite",        color = Color3.fromRGB(120,200,120), builder = GrowATreePro },
    { name = "SAB MASTER",           cat = "ACTION",   icon = "ðŸ’€", desc = "Ultimate SAB suite",     color = Color3.fromRGB(180,120,255), builder = StealABrainrotMaster },
    { name = "Universal Pet RNG",    cat = "RNG",      icon = "ðŸŽ²", desc = "Roll & farm pets",       color = Color3.fromRGB(180,120,255), builder = UniversalPetRNG },
    { name = "Universal Collector",  cat = "GLOBAL",   icon = "ðŸ§²", desc = "Collect anything",       color = Theme.AccentBright,          builder = UniversalCollector },
    { name = "Universal Buyer",      cat = "GLOBAL",   icon = "ðŸ›’", desc = "Auto-buy remotes",       color = Theme.AccentBright,          builder = UniversalBuyer },
    { name = "Universal Seller",     cat = "GLOBAL",   icon = "ðŸ’°", desc = "Auto-sell remotes",      color = Theme.AccentBright,          builder = UniversalSeller },
    { name = "Universal Hatcher",    cat = "GLOBAL",   icon = "ðŸ¥š", desc = "Auto-hatch eggs",        color = Theme.AccentBright,          builder = UniversalHatcher },
    { name = "Universal Rebirther",  cat = "GLOBAL",   icon = "â™¾ï¸", desc = "Auto-rebirth",           color = Theme.AccentBright,          builder = UniversalRebirther },
    { name = "Auto Clicker PRO",     cat = "GLOBAL",   icon = "ðŸ–±ï¸", desc = "Advanced auto-click",    color = Theme.AccentBright,          builder = AutoClickerPro },
    { name = "Universal NPC Farmer", cat = "GLOBAL",   icon = "ðŸ¤–", desc = "Auto-farm NPCs",         color = Theme.AccentBright,          builder = UniversalNPCFarmer },
    { name = "Universal Auto-Play",  cat = "GLOBAL",   icon = "â–¶ï¸", desc = "Quests & progress",      color = Theme.AccentBright,          builder = UniversalAutoPlay },
    { name = "Brainrot Arena",       cat = "ACTION",   icon = "ðŸŸï¸", desc = "Arena combat & steal",   color = Color3.fromRGB(180,120,255), builder = BrainrotArena },
    { name = "Brainrot Wallet",      cat = "SIMULATOR",icon = "ðŸ’°", desc = "Money farm",             color = Color3.fromRGB(255,200,40),  builder = BrainrotWallet },
    { name = "Brainrot Survival",    cat = "SURVIVAL", icon = "ðŸ§Ÿ", desc = "Wave survival",          color = Color3.fromRGB(180,120,255), builder = BrainrotSurvival },
    { name = "Brainrot Factory",     cat = "TYCOON",   icon = "ðŸ­", desc = "Production suite",       color = Color3.fromRGB(180,120,255), builder = BrainrotFactory },
    { name = "Brainrot Obby",        cat = "OBBY",     icon = "ðŸ§©", desc = "Obby + collect",         color = Color3.fromRGB(180,120,255), builder = BrainrotObby },
    { name = "Pet Sim 99 PRO",       cat = "SIMULATOR",icon = "ðŸŒŸ", desc = "Full PS99 suite",        color = Color3.fromRGB(120,200,255), builder = PetSim99Pro },
    { name = "Pet Sim X PRO",        cat = "SIMULATOR",icon = "âœ¨", desc = "Full PSX suite",         color = Color3.fromRGB(255,200,40),  builder = PetSimXPro },
    { name = "Bloxstrike",           cat = "FPS",      icon = "ðŸŽ®", desc = "Tactical FPS",           color = Color3.fromRGB(255,120,50),  builder = Bloxstrike },
    { name = "Break Your Bones",     cat = "PHYSICS",  icon = "ðŸ¦´", desc = "Bone farming",           color = Color3.fromRGB(220,220,220), builder = BreakYourBones },
    { name = "Slime RNG",            cat = "RNG",      icon = "ðŸŸ¢", desc = "Auto roll",              color = Color3.fromRGB(120,220,120), builder = SlimeRNG },
    { name = "Redliners",            cat = "FPS",      icon = "ðŸ”´", desc = "Fast-paced FPS",         color = Color3.fromRGB(255,60,90),   builder = Redliners },
    { name = "Settings",             cat = "GLOBAL",   icon = "âš™ï¸", desc = "Theme, FOV, gravity, anti-afk", color = Theme.Accent,         builder = Settings },
    { name = "Vape Modules",         cat = "GLOBAL",   icon = "ðŸ§©", desc = "KillAura, Velocity, Tracers, XRay", color = Theme.AccentBright, builder = VapeModules },
    { name = "Legit HUD",            cat = "GLOBAL",   icon = "ðŸ“Š", desc = "FPS, Ping, Keystrokes, Cape", color = Theme.AccentBright,   builder = LegitHUD },
    { name = "Doors",                cat = "HORROR",   icon = "ðŸšª", desc = "Entity ESP & skip",      color = Color3.fromRGB(255,90,60),   builder = Doors },
    { name = "Blox Fruits",          cat = "ADVENTURE",icon = "ðŸŽ", desc = "Auto farm NPCs",         color = Color3.fromRGB(255,160,60),  builder = BloxFruits },
    { name = "Pet Sim 99",           cat = "SIMULATOR",icon = "ðŸ¾", desc = "Coins & eggs",           color = Color3.fromRGB(120,200,255), builder = PetSim99 },
    { name = "Evade",                cat = "SURVIVAL", icon = "ðŸ‘¤", desc = "Nextbot avoid",          color = Color3.fromRGB(255,60,60),   builder = Evade },
    { name = "Brookhaven",           cat = "RP",       icon = "ðŸ ", desc = "RP utilities",           color = Color3.fromRGB(255,90,180),  builder = Brookhaven },
    { name = "Adopt Me",             cat = "RP",       icon = "ðŸ¦´", desc = "Auto pet care",          color = Color3.fromRGB(255,120,180), builder = AdoptMe },
    { name = "Tower Defense Sim",    cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto upgrade / waves",   color = Color3.fromRGB(120,180,255), builder = TowerDefenseSim },
    { name = "Dead Rails",           cat = "SURVIVAL", icon = "ðŸš‚", desc = "Loot & travel",          color = Color3.fromRGB(180,140,80),  builder = DeadRails },
    { name = "99 Nights",            cat = "ACTION",   icon = "ðŸŒ™", desc = "Night survival farm",    color = Color3.fromRGB(80,50,120),   builder = NinetyNineNights },
    { name = "Escape",               cat = "SURVIVAL", icon = "ðŸšª", desc = "Escape the killer",      color = Color3.fromRGB(86,156,240),  builder = EscapeGame },
    { name = "Bronx",                cat = "FPS",      icon = "ðŸŒ‡", desc = "Gang street FPS",        color = Color3.fromRGB(200,120,80),  builder = Bronx },
    { name = "Steep Steps",          cat = "OBBY",     icon = "â›°ï¸", desc = "Climb helper",           color = Color3.fromRGB(120,200,120), builder = SteepSteps },
    { name = "Build A Boat",         cat = "SANDBOX",  icon = "â›µ", desc = "Sail & collect",         color = Color3.fromRGB(120,180,255), builder = BuildABoat },
    { name = "Pilot Training",       cat = "FLIGHT",   icon = "âœˆï¸", desc = "Teleport airports",      color = Color3.fromRGB(86,156,240),  builder = PilotTraining },
    { name = "Anime Adventures",     cat = "ADVENTURE",icon = "ðŸŒ€", desc = "Auto farm enemies",      color = Color3.fromRGB(180,120,255), builder = AnimeAdventures },
    { name = "Ninja Legends",        cat = "SIMULATOR",icon = "ðŸ¥·", desc = "Auto swing & sell",      color = Color3.fromRGB(245,196,76),  builder = NinjaLegends },
    { name = "Mining Simulator",     cat = "SIMULATOR",icon = "â›ï¸", desc = "Auto mine & sell",       color = Color3.fromRGB(180,140,80),  builder = MiningSimulator },
    { name = "Slap Battles",         cat = "ACTION",   icon = "ðŸ‘‹", desc = "Auto slap / aura",       color = Color3.fromRGB(245,196,76),  builder = SlapBattles },
    { name = "Survive the Killer",   cat = "SURVIVAL", icon = "ðŸ©¸", desc = "Killer avoid / ESP",     color = Color3.fromRGB(255,60,60),   builder = SurviveTheKiller },
    { name = "Royale High",          cat = "RP",       icon = "ðŸ‘‘", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RoyaleHigh },
    { name = "Big Paintball",        cat = "FPS",      icon = "ðŸŽ¨", desc = "Paintball FPS",          color = Color3.fromRGB(120,200,255), builder = BigPaintball },
    { name = "Phantom Forces",       cat = "FPS",      icon = "ðŸŽ–ï¸", desc = "Tactical FPS",           color = Color3.fromRGB(110,110,130), builder = PhantomForces },
    { name = "Frontlines",           cat = "FPS",      icon = "ðŸª–", desc = "Large-scale FPS",        color = Color3.fromRGB(200,120,60),  builder = Frontlines },
    { name = "Players",              cat = "GLOBAL",   icon = "ðŸ‘¥", desc = "Player list & actions",  color = Theme.Accent,                builder = PlayersPanel },
    { name = "Friends & Targets",    cat = "GLOBAL",   icon = "ðŸ¤", desc = "Recolor ESP / priorities", color = Theme.AccentBright,        builder = FriendsTargets },
    { name = "Piggy",                cat = "HORROR",   icon = "ðŸ·", desc = "Escape & role ESP",      color = Color3.fromRGB(255,90,60),   builder = Piggy },
    { name = "Pizza Place",          cat = "JOB",      icon = "ðŸ•", desc = "Auto work & deliver",    color = Color3.fromRGB(255,160,60),  builder = PizzaPlace },
    { name = "Theme Park Tycoon 2",  cat = "TYCOON",   icon = "ðŸŽ¢", desc = "Builder utilities",      color = Color3.fromRGB(120,200,255), builder = ThemeParkTycoon2 },
    { name = "Weight Lifting Sim",   cat = "SIMULATOR",icon = "ðŸ‹ï¸", desc = "Auto lift & rebirth",    color = Color3.fromRGB(245,196,76),  builder = WeightLiftingSimulator },
    { name = "Magnet Simulator",     cat = "SIMULATOR",icon = "ðŸ§²", desc = "Auto collect & sell",    color = Color3.fromRGB(120,180,255), builder = MagnetSimulator },
    { name = "Super Bomb Survival",  cat = "SURVIVAL", icon = "ðŸ’£", desc = "Bomb avoid & ESP",       color = Color3.fromRGB(255,60,60),   builder = SuperBombSurvival },
    { name = "Lumber Tycoon 2",      cat = "TYCOON",   icon = "ðŸªµ", desc = "Auto chop & sell",       color = Color3.fromRGB(120,200,120), builder = LumberTycoon2 },
    { name = "Random Rumble",        cat = "ACTION",   icon = "ðŸ¥Š", desc = "Combat + aura",          color = Color3.fromRGB(180,120,255), builder = RandomRumble },
    { name = "Ragdoll Universe",     cat = "FUN",      icon = "ðŸ¤¸", desc = "Fling & reset",          color = Color3.fromRGB(180,120,255), builder = RagdollUniverse },
    { name = "Robloxian High",       cat = "RP",       icon = "ðŸ«", desc = "Campus utilities",       color = Color3.fromRGB(255,120,180), builder = RobloxianHighschool },
    { name = "Color Block",          cat = "SURVIVAL", icon = "ðŸŸ©", desc = "Safe block finder",      color = Color3.fromRGB(76,209,142),  builder = ColorBlock },
    { name = "Gym Simulator",        cat = "SIMULATOR",icon = "ðŸ’ª", desc = "Auto workout",           color = Color3.fromRGB(245,196,76),  builder = GymSimulator },
    { name = "Westbound",            cat = "FPS",      icon = "ðŸ¤ ", desc = "Western shooter",        color = Color3.fromRGB(200,150,80),  builder = Westbound },
    { name = "King Legacy",          cat = "ADVENTURE",icon = "ðŸ‘‘", desc = "Auto farm enemies",      color = Color3.fromRGB(255,160,60),  builder = KingLegacy },
    { name = "Clicker Simulator",    cat = "CLICKER",  icon = "ðŸ–±ï¸", desc = "Auto click & rebirth",   color = Color3.fromRGB(245,196,76),  builder = ClickerSimulator },
    { name = "Bubble Gum Sim",       cat = "SIMULATOR",icon = "ðŸ«§", desc = "Auto blow & sell",       color = Color3.fromRGB(255,120,200), builder = BubbleGumSimulator },
    { name = "Boxing Simulator",     cat = "SIMULATOR",icon = "ðŸ¥Š", desc = "Auto punch",             color = Color3.fromRGB(245,196,76),  builder = BoxingSimulator },
    { name = "Race Clicker",         cat = "CLICKER",  icon = "ðŸ", desc = "Auto click & race",      color = Color3.fromRGB(120,180,255), builder = RaceClicker },
    { name = "Epic Minigames",       cat = "PARTY",    icon = "ðŸŽ²", desc = "Survival hints",         color = Theme.Accent,                builder = EpicMinigames },
    { name = "Pet Simulator X",      cat = "SIMULATOR",icon = "ðŸ£", desc = "Coins & eggs",           color = Color3.fromRGB(255,200,40),  builder = PetSimX },
    { name = "Project Slayers",      cat = "ADVENTURE",icon = "âš”ï¸", desc = "Auto farm & spin",       color = Color3.fromRGB(180,120,255), builder = ProjectSlayers },
    { name = "Shindo Life",          cat = "ADVENTURE",icon = "ðŸŒ€", desc = "Spin & grind",           color = Color3.fromRGB(255,120,80),  builder = ShindoLife },
    { name = "YBA",                  cat = "ADVENTURE",icon = "ðŸ‘", desc = "Auto farm stands",       color = Color3.fromRGB(255,160,60),  builder = YBA },
    { name = "Anime Vanguards",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto farm units",        color = Color3.fromRGB(180,120,255), builder = AnimeVanguards },
    { name = "Juke's Towers",        cat = "OBBY",     icon = "ðŸ§—", desc = "Climb helper",           color = Color3.fromRGB(122,200,120), builder = JukesTowers },
    { name = "Pls Donate",           cat = "SOCIAL",   icon = "ðŸ’¬", desc = "Auto chat / AFK",        color = Color3.fromRGB(76,209,142),  builder = PlsDonate },
    { name = "Dragon Adventures",    cat = "ADVENTURE",icon = "ðŸ‰", desc = "Auto feed & incubate",   color = Color3.fromRGB(120,200,120), builder = DragonAdventures },
    { name = "Creatures of Sonaria", cat = "SURVIVAL", icon = "ðŸ¦Ž", desc = "Auto eat & grow",        color = Color3.fromRGB(120,200,120), builder = CreaturesOfSonaria },
    { name = "MeepCity",             cat = "RP",       icon = "ðŸ˜º", desc = "RP utilities",           color = Color3.fromRGB(255,120,180), builder = MeepCity },
    { name = "Ro-Ghoul",             cat = "ADVENTURE",icon = "ðŸ©¸", desc = "Auto farm & aura",       color = Color3.fromRGB(180,60,60),   builder = RoGhoul },
    { name = "Demonfall",            cat = "ADVENTURE",icon = "ðŸ‘¹", desc = "Auto farm NPCs",         color = Color3.fromRGB(180,80,120),  builder = Demonfall },
    { name = "DBZ Final Stand",      cat = "ADVENTURE",icon = "ðŸ”¥", desc = "Train & fight",          color = Color3.fromRGB(255,160,40),  builder = DBZFinalStand },
    { name = "Break In",             cat = "STORY",    icon = "ðŸšï¸", desc = "Story survival",         color = Color3.fromRGB(180,120,120), builder = BreakIn },
    { name = "ER: Liberty County",   cat = "RP",       icon = "ðŸš”", desc = "Roleplay utilities",     color = Color3.fromRGB(70,150,255),  builder = ERLC },
    { name = "SCP Roleplay",         cat = "FPS",      icon = "ðŸ”¬", desc = "SCP & keycard ESP",      color = Color3.fromRGB(180,60,60),   builder = SCPRoleplay },
    { name = "Camping",              cat = "STORY",    icon = "ðŸ•ï¸", desc = "Story survival",         color = Color3.fromRGB(120,180,100), builder = Camping },
    { name = "Fish Game",            cat = "SURVIVAL", icon = "ðŸ¦‘", desc = "Red light helper",       color = Color3.fromRGB(76,209,142),  builder = FishGame },
    { name = "Hide and Seek",        cat = "ACTION",   icon = "ðŸ™ˆ", desc = "Tag helper",             color = Theme.Accent,                builder = HideAndSeek },
    { name = "World Zero",           cat = "RPG",      icon = "ðŸŒŒ", desc = "RPG farm",               color = Color3.fromRGB(120,180,255), builder = WorldZero },
    { name = "Isle",                 cat = "STORY",    icon = "ðŸï¸", desc = "Mystery survival",       color = Color3.fromRGB(120,160,140), builder = Isle },
    { name = "Rumble Quest",         cat = "ACTION",   icon = "ðŸŒŸ", desc = "Combat & aura",          color = Color3.fromRGB(150,120,255), builder = RumbleQuest },
    { name = "RoCitizens",           cat = "RP",       icon = "ðŸ˜ï¸", desc = "RP utilities",           color = Color3.fromRGB(120,180,255), builder = RoCitizens },
    { name = "The Survival Game",    cat = "SURVIVAL", icon = "ðŸª“", desc = "Open survival",          color = Color3.fromRGB(120,180,100), builder = SurvivalGame },
    { name = "Bedwars",              cat = "ACTION",   icon = "ðŸ›ï¸", desc = "Combat + bed defense",   color = Color3.fromRGB(120,180,255), builder = Bedwars },
    { name = "Doomspire",            cat = "ACTION",   icon = "ðŸ—ï¸", desc = "Brickbattle combat",     color = Color3.fromRGB(255,160,60),  builder = Doomspire },
    { name = "Combat Warriors",      cat = "ACTION",   icon = "ðŸ—¡ï¸", desc = "Melee + aura",           color = Color3.fromRGB(220,60,60),   builder = CombatWarriors },
    { name = "Ability Wars",         cat = "ACTION",   icon = "âœ¨", desc = "Auto ability",           color = Color3.fromRGB(180,120,255), builder = AbilityWars },
    { name = "Mic Up",               cat = "SOCIAL",   icon = "ðŸŽ™ï¸", desc = "Social utilities",       color = Theme.Accent,                builder = MicUp },
    { name = "Island Royale",        cat = "FPS",      icon = "ðŸï¸", desc = "Battle royale FPS",      color = Color3.fromRGB(120,200,120), builder = IslandRoyale },
    { name = "Plates of Fate",       cat = "SURVIVAL", icon = "ðŸ½ï¸", desc = "Plate survival",         color = Color3.fromRGB(76,209,142),  builder = PlatesOfFate },
    { name = "Find the Markers",     cat = "HUNT",     icon = "ðŸ–ï¸", desc = "Marker hunt",            color = Color3.fromRGB(255,200,40),  builder = FindTheMarkers },
    { name = "Obby Helper",          cat = "OBBY",     icon = "ðŸš§", desc = "Any tower/obby",         color = Color3.fromRGB(122,200,120), builder = ObbyGeneric },
    { name = "Wacky Wizards",        cat = "SIMULATOR",icon = "ðŸ§ª", desc = "Potion brew",            color = Color3.fromRGB(180,120,255), builder = WackyWizards },
    { name = "Troll Suite",          cat = "FUN",      icon = "ðŸ¤¡", desc = "Cosmetics & fun",        color = Color3.fromRGB(255,120,80),  builder = TrollSuite },
    { name = "Simulator Helper",     cat = "CLICKER",  icon = "âš™ï¸", desc = "Any clicker/sim",        color = Color3.fromRGB(245,196,76),  builder = GenericSim },
    { name = "Zombie Attack",        cat = "ACTION",   icon = "ðŸ§Ÿ", desc = "Wave fighter",           color = Color3.fromRGB(120,200,80),  builder = ZombieAttack },
    { name = "Tornado Alley",        cat = "SURVIVAL", icon = "ðŸŒªï¸", desc = "Disaster survival",      color = Color3.fromRGB(150,150,160), builder = TornadoAlley },
    { name = "Boat Treasure",        cat = "SANDBOX",  icon = "ðŸï¸", desc = "Sail & collect",         color = Color3.fromRGB(120,180,255), builder = BoatTreasure },
    { name = "Speed Run",            cat = "OBBY",     icon = "ðŸ’¨", desc = "Dash & win",             color = Color3.fromRGB(120,200,255), builder = SpeedRun },
    { name = "Word Game",            cat = "PARTY",    icon = "âŒ¨ï¸", desc = "Auto typer",             color = Theme.Accent,                builder = WordGame },
    { name = "Snowball",             cat = "ACTION",   icon = "â„ï¸", desc = "Throw combat",           color = Color3.fromRGB(150,200,255), builder = SnowballGame },
    { name = "Paint Game",           cat = "FUN",      icon = "ðŸŽ¨", desc = "Auto paint",             color = Color3.fromRGB(255,120,200), builder = PaintGame },
    { name = "Survive Disaster",     cat = "SURVIVAL", icon = "ðŸŒ‹", desc = "Disaster survival",      color = Theme.Blue,                  builder = SurviveDisaster },
    { name = "Dig Game",             cat = "SIMULATOR",icon = "â›ï¸", desc = "Auto dig & sell",        color = Color3.fromRGB(180,140,80),  builder = DigGame },
    { name = "Anime RPG",            cat = "RPG",      icon = "âš”ï¸", desc = "Farm & roll",            color = Color3.fromRGB(180,120,255), builder = AnimeRPG },
    { name = "Fantasy RPG",          cat = "RPG",      icon = "ðŸ§™", desc = "Quest & farm",           color = Color3.fromRGB(150,120,255), builder = FantasyRPG },
    { name = "Vehicle Simulator",    cat = "SIMULATOR",icon = "ðŸš—", desc = "Drive & collect",        color = Color3.fromRGB(120,180,255), builder = VehicleSimulator },
    { name = "Tycoon Helper",        cat = "TYCOON",   icon = "ðŸ­", desc = "Any tycoon",             color = Color3.fromRGB(120,220,120), builder = TycoonGeneric },
    { name = "Fishing Game",         cat = "SIMULATOR",icon = "ðŸŽ£", desc = "Auto fish",              color = Color3.fromRGB(86,156,240),  builder = FishingGame },
    { name = "Portal / Science",     cat = "PUZZLE",   icon = "ðŸŒ€", desc = "Puzzle helper",          color = Color3.fromRGB(120,180,200), builder = PortalGame },
    { name = "Rocket / Launch",      cat = "SANDBOX",  icon = "ðŸš€", desc = "Build & launch",         color = Color3.fromRGB(220,220,220), builder = RocketGame },
    { name = "Paintball",            cat = "FPS",      icon = "ðŸŽ¨", desc = "Paintball FPS",          color = Color3.fromRGB(120,200,255), builder = PaintballGeneric },
    { name = "Difficult Parkour",    cat = "OBBY",     icon = "ðŸƒ", desc = "Hard obby",             color = Color3.fromRGB(122,200,120), builder = ParkourObby },
    { name = "Cooking Game",         cat = "JOB",      icon = "ðŸ³", desc = "Auto cook",             color = Color3.fromRGB(255,160,80),  builder = CookingGame },
    { name = "Delivery / Job",       cat = "JOB",      icon = "ðŸ“¦", desc = "Auto deliver",          color = Color3.fromRGB(120,180,255), builder = DeliveryGame },
    { name = "Survival Sandbox",     cat = "SURVIVAL", icon = "ðŸªµ", desc = "Craft & gather",        color = Color3.fromRGB(120,180,100), builder = CraftingSandbox },
    { name = "Racing Game",          cat = "RACING",   icon = "ðŸ", desc = "Drive & collect",       color = Color3.fromRGB(255,120,80),  builder = RacingGame },
    { name = "Horror Game",          cat = "HORROR",   icon = "ðŸ‘»", desc = "Survive monsters",       color = Color3.fromRGB(180,60,80),   builder = HorrorGame },
    { name = "Trading / Economy",    cat = "ECONOMY",  icon = "ðŸ’±", desc = "Auto trade",             color = Color3.fromRGB(120,220,120), builder = TradingGame },
    { name = "Sport / Skate",        cat = "SPORT",    icon = "ðŸ›¹", desc = "Tricks & speed",         color = Color3.fromRGB(120,200,255), builder = SportGame },
    { name = "Help & About",         cat = "GLOBAL",   icon = "â“", desc = "Usage guide & keybinds", color = Theme.Accent,                builder = HelpAbout },
    { name = "Sols RNG",             cat = "RNG",      icon = "ðŸŽ²", desc = "Auto roll auras",        color = Color3.fromRGB(180,140,255), builder = SolsRNG },
    { name = "Type Soul",            cat = "RPG",      icon = "ðŸ—¡ï¸", desc = "Farm & raid",            color = Color3.fromRGB(180,120,255), builder = TypeSoul },
    { name = "Anime Defenders",      cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto place units",       color = Color3.fromRGB(150,120,255), builder = AnimeDefenders },
    { name = "Dungeon Quest",        cat = "RPG",      icon = "ðŸ°", desc = "Dungeon farm",           color = Color3.fromRGB(150,100,200), builder = DungeonQuest },
    { name = "Treasure Quest",       cat = "RPG",      icon = "ðŸ’Ž", desc = "Dungeon & chests",       color = Color3.fromRGB(255,180,60),  builder = TreasureQuest },
    { name = "A Universal Time",     cat = "RPG",      icon = "ðŸŒŸ", desc = "Stand farm",             color = Color3.fromRGB(180,140,255), builder = UniversalTime },
    { name = "Grand Piece Online",   cat = "RPG",      icon = "âš“", desc = "Pirate farm",            color = Color3.fromRGB(120,180,255), builder = GPO },
    { name = "Haze Piece",           cat = "RPG",      icon = "ðŸŒ´", desc = "Fruit farm",             color = Color3.fromRGB(120,180,255), builder = HazePiece },
    { name = "A One Piece Game",     cat = "RPG",      icon = "ðŸ´â€â˜ ï¸", desc = "Pirate farm",            color = Color3.fromRGB(255,160,60),  builder = AOnePieceGame },
    { name = "Deepwoken",            cat = "RPG",      icon = "ðŸŒŠ", desc = "Survival RPG",           color = Color3.fromRGB(100,130,180), builder = Deepwoken },
    { name = "Pressure",             cat = "HORROR",   icon = "ðŸ”‹", desc = "Horror survival",        color = Color3.fromRGB(120,160,200), builder = Pressure },
    { name = "The Wild West",        cat = "FPS",      icon = "ðŸ¤ ", desc = "Cowboy shooter",         color = Color3.fromRGB(200,150,80),  builder = TheWildWest },
    { name = "Loomian Legacy",       cat = "RPG",      icon = "ðŸ¦Ž", desc = "Auto battle",            color = Color3.fromRGB(120,180,255), builder = LoomianLegacy },
    { name = "Blood & Iron",         cat = "FPS",      icon = "âš”ï¸", desc = "Historic shooter",       color = Color3.fromRGB(160,60,60),   builder = BloodAndIron },
    { name = "Welcome to Bloxburg",  cat = "RP",       icon = "ðŸ¡", desc = "Build & jobs",           color = Color3.fromRGB(120,200,120), builder = Bloxburg },
    { name = "Total Roblox Drama",   cat = "SURVIVAL", icon = "ðŸŽ¬", desc = "Survival hints",         color = Theme.Accent,                builder = TotalRobloxDrama },
    { name = "Ragdoll Engine",       cat = "FUN",      icon = "ðŸŽª", desc = "Fling & reset",          color = Color3.fromRGB(180,120,255), builder = RagdollEngine },
    { name = "Weapon Forge",         cat = "SIMULATOR",icon = "ðŸ”¨", desc = "Craft weapons",          color = Color3.fromRGB(180,180,200), builder = WeaponForge },
    { name = "Nico's Nextbots",      cat = "SURVIVAL", icon = "ðŸ˜±", desc = "Nextbot avoid",          color = Color3.fromRGB(255,80,80),   builder = NicosNextbots },
    { name = "Fantastic Frontier",   cat = "RPG",      icon = "ðŸ—ºï¸", desc = "RPG farm",               color = Color3.fromRGB(150,200,150), builder = FantasticFrontier },
    { name = "Vesteria",             cat = "RPG",      icon = "ðŸŒ²", desc = "MMORPG farm",            color = Color3.fromRGB(120,160,200), builder = Vesteria },
    { name = "Anime Fighting Sim",   cat = "RPG",      icon = "ðŸ‘Š", desc = "Train & farm",           color = Color3.fromRGB(180,120,255), builder = AnimeFightingSim },
    { name = "Decaying Winter",      cat = "RPG",      icon = "â„ï¸", desc = "Survival RPG",           color = Color3.fromRGB(160,140,120), builder = DecayingWinter },
    { name = "Sonic Speed Sim",      cat = "SIMULATOR",icon = "ðŸ’™", desc = "Speed & rings",          color = Color3.fromRGB(120,180,255), builder = SonicSpeedSim },
    { name = "Muscle Legends",       cat = "SIMULATOR",icon = "ðŸ’ª", desc = "Auto lift",              color = Color3.fromRGB(245,196,76),  builder = MuscleLegends },
    { name = "Murder Game X",        cat = "MYSTERY",  icon = "ðŸ”ª", desc = "Role ESP & survive",     color = Theme.Red,                   builder = MurderGameX },
    { name = "Dungeon / Raid",       cat = "RPG",      icon = "âš”ï¸", desc = "Raid farm",              color = Color3.fromRGB(150,120,200), builder = RaidGame },
    { name = "Idle / Incremental",   cat = "CLICKER",  icon = "ðŸ“ˆ", desc = "Any idle game",          color = Theme.Yellow,                builder = IdleGame },
    { name = "Pet Collection",       cat = "SIMULATOR",icon = "ðŸ¶", desc = "Hatch & equip",          color = Color3.fromRGB(255,150,180), builder = PetGame },
    { name = "Survival Island",      cat = "SURVIVAL", icon = "ðŸï¸", desc = "Gather & craft",         color = Color3.fromRGB(120,180,100), builder = SurvivalIsland },
    { name = "Defense Game",         cat = "STRATEGY", icon = "ðŸ›¡ï¸", desc = "Auto place towers",      color = Color3.fromRGB(120,180,255), builder = DefenseGame },
}

--==============================================================================
--// REGISTER ALL "FIND THE" GAMES  (75+ hunt games via the generic builder)
--==============================================================================
for _, ft in ipairs(FindTheGames) do
    -- skip the first (Markers) since it already has a dedicated registry entry
    if ft.name ~= "Find the Markers" then
        local cfg = ft
        table.insert(GameList, {
            name = ft.name,
            cat = "FIND THE",
            icon = ft.icon,
            desc = "Hunt & auto-collect " .. ft.singular:lower() .. "s",
            color = ft.color,
            builder = function() return buildFindTheGame(cfg) end,
        })
    end
end

--==============================================================================
--// MAIN HUB UI
--==============================================================================
local Hub = {}
do
    local frame = Instance.new("Frame")
    frame.Name = "MainHub"
    frame.Size = UDim2.new(0, 560, 0, 420)
    frame.Position = UDim2.new(0.5, -280, 0.5, -210)
    frame.BackgroundColor3 = Theme.Background
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = ScreenGui
    corner(frame, Theme.RoundedBig)
    stroke(frame, Theme.Stroke, 1, 0.15)

    -- accent top bar
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 3)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    accent.ZIndex = 11
    accent.Parent = frame
    gradient(accent, Theme.AccentBright, Theme.AccentDark, 0)
    local ac = Instance.new("UICorner"); ac.CornerRadius = Theme.RoundedBig; ac.Parent = accent

    -- header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 56)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = frame
    corner(header, Theme.RoundedBig)
    local hf = Instance.new("Frame"); hf.Size = UDim2.new(1,0,0,28); hf.BackgroundColor3 = Theme.Sidebar; hf.BorderSizePixel=0; hf.ZIndex=11; hf.Position = UDim2.new(0,0,0,28); hf.Parent = header

    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 34, 0, 34)
    logo.Position = UDim2.new(0, 14, 0.5, -17)
    logo.BackgroundColor3 = Theme.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 12
    logo.Parent = header
    corner(logo, UDim.new(0, 8))
    gradient(logo, Theme.AccentBright, Theme.AccentDark, 45)
    local logoTxt = Instance.new("TextLabel")
    logoTxt.BackgroundTransparency = 1
    logoTxt.Size = UDim2.new(1,0,1,0)
    logoTxt.Font = Theme.FontBold
    logoTxt.TextSize = 18
    logoTxt.TextColor3 = Color3.fromRGB(255,255,255)
    logoTxt.Text = "P"
    logoTxt.ZIndex = 13
    logoTxt.Parent = logo

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 58, 0, 8)
    title.Size = UDim2.new(1, -160, 0, 22)
    title.Font = Theme.FontBold
    title.TextSize = 17
    title.TextColor3 = Theme.Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "Potatools"
    title.ZIndex = 12
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.new(0, 58, 0, 31)
    subtitle.Size = UDim2.new(1, -160, 0, 14)
    subtitle.Font = Theme.Font
    subtitle.TextSize = 11
    subtitle.TextColor3 = Theme.TextDim
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Text = "Potatools Suite  â€¢  " .. #GameList .. " games  â€¢  " .. os.date("%H:%M")
    subtitle.ZIndex = 12
    subtitle.Parent = header

    -- header buttons
    local function ctrl(text, color, x, fn)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0.5, -14)
        b.BackgroundColor3 = Theme.Element
        b.Text = text
        b.Font = Theme.FontBold
        b.TextSize = 14
        b.TextColor3 = color
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = header
        corner(b, UDim.new(0, 7))
        b.MouseButton1Click:Connect(fn)
        return b
    end
    ctrl("â€“", Theme.Yellow, -34, function()
        Hub.Minimized = not Hub.Minimized
        if Hub.Minimized then
            Hub._fullSize = frame.Size
            tween(frame, 0.2, { Size = UDim2.new(0, frame.AbsoluteSize.X, 0, 56) })
            content.Visible = false
            searchBar.Visible = false
        else
            tween(frame, 0.2, { Size = Hub._fullSize })
            content.Visible = true
            searchBar.Visible = true
        end
    end)
    ctrl("âœ•", Theme.Red, -68, function()
        frame.Visible = false
        Hub.ToggleIcon.Visible = true
    end)

    -- search bar
    local searchBar = Instance.new("Frame")
    searchBar.Size = UDim2.new(1, -28, 0, 34)
    searchBar.Position = UDim2.new(0, 14, 0, 64)
    searchBar.BackgroundColor3 = Theme.Element
    searchBar.BorderSizePixel = 0
    searchBar.ZIndex = 11
    searchBar.Parent = frame
    corner(searchBar, Theme.Rounded)
    stroke(searchBar, Theme.Stroke, 1, 0.3)
    local searchIcon = Instance.new("TextLabel")
    searchIcon.BackgroundTransparency = 1
    searchIcon.Position = UDim2.new(0, 8, 0, 0)
    searchIcon.Size = UDim2.new(0, 20, 1, 0)
    searchIcon.Font = Theme.Font
    searchIcon.TextSize = 14
    searchIcon.TextColor3 = Theme.TextDim
    searchIcon.Text = "ðŸ”"
    searchIcon.ZIndex = 12
    searchIcon.Parent = searchBar
    local searchBox = Instance.new("TextBox")
    searchBox.BackgroundTransparency = 1
    searchBox.Position = UDim2.new(0, 34, 0, 0)
    searchBox.Size = UDim2.new(1, -42, 1, 0)
    searchBox.Font = Theme.Font
    searchBox.TextSize = 13
    searchBox.TextColor3 = Theme.Text
    searchBox.PlaceholderText = "Search games..."
    searchBox.PlaceholderColor3 = Theme.TextDim
    searchBox.Text = ""
    searchBox.ClearTextOnFocus = false
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ZIndex = 12
    searchBox.Parent = searchBar

    -- content scroll
    local content = Instance.new("ScrollingFrame")
    content.Name = "GameList"
    content.Position = UDim2.new(0, 14, 0, 104)
    content.Size = UDim2.new(1, -28, 1, -118)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ZIndex = 11
    content.Parent = frame
    padding(content, 2, 8, 2, 2)
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local function refreshList(query)
        query = string.lower(tostring(query or ""))
        for _, child in ipairs(content:GetChildren()) do
            if child:IsA("GuiButton") then
                local match = query == "" or string.lower(child.Name):find(query) or string.lower(child:GetAttribute("desc") or ""):find(query)
                child.Visible = match
            end
        end
    end
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        refreshList(searchBox.Text)
    end)

    -- build game cards
    local order = 0
    for _, g in ipairs(GameList) do
        order = order + 1
        local card = Instance.new("TextButton")
        card.Name = g.name
        card.Size = UDim2.new(1, 0, 0, 52)
        card.BackgroundColor3 = Theme.Element
        card.AutoButtonColor = false
        card.Text = ""
        card.BorderSizePixel = 0
        card.ZIndex = 11
        card.LayoutOrder = order
        card:SetAttribute("desc", g.desc)
        card.Parent = content
        corner(card, Theme.Rounded)

        local iconBox = Instance.new("Frame")
        iconBox.Size = UDim2.new(0, 38, 0, 38)
        iconBox.Position = UDim2.new(0, 8, 0.5, -19)
        iconBox.BackgroundColor3 = g.color
        iconBox.BorderSizePixel = 0
        iconBox.ZIndex = 12
        iconBox.Parent = card
        corner(iconBox, UDim.new(0, 8))
        local icTxt = Instance.new("TextLabel")
        icTxt.BackgroundTransparency = 1
        icTxt.Size = UDim2.new(1,0,1,0)
        icTxt.Font = Theme.Font
        icTxt.TextSize = 18
        icTxt.Text = g.icon
        icTxt.ZIndex = 13
        icTxt.Parent = iconBox

        local nLbl = Instance.new("TextLabel")
        nLbl.BackgroundTransparency = 1
        nLbl.Position = UDim2.new(0, 56, 0, 8)
        nLbl.Size = UDim2.new(1, -120, 0, 18)
        nLbl.Font = Theme.FontBold
        nLbl.TextSize = 14
        nLbl.TextColor3 = Theme.Text
        nLbl.TextXAlignment = Enum.TextXAlignment.Left
        nLbl.Text = g.name
        nLbl.ZIndex = 12
        nLbl.Parent = card

        local dLbl = Instance.new("TextLabel")
        dLbl.BackgroundTransparency = 1
        dLbl.Position = UDim2.new(0, 56, 0, 27)
        dLbl.Size = UDim2.new(1, -120, 0, 14)
        dLbl.Font = Theme.Font
        dLbl.TextSize = 11
        dLbl.TextColor3 = Theme.TextDim
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.Text = g.desc
        dLbl.ZIndex = 12
        dLbl.Parent = card

        local catLbl = Instance.new("TextLabel")
        catLbl.BackgroundTransparency = 1
        catLbl.Position = UDim2.new(1, -78, 0.5, -9)
        catLbl.Size = UDim2.new(0, 70, 0, 18)
        catLbl.Font = Theme.FontBold
        catLbl.TextSize = 9
        catLbl.TextColor3 = g.color
        catLbl.TextXAlignment = Enum.TextXAlignment.Right
        catLbl.Text = g.cat
        catLbl.ZIndex = 12
        catLbl.Parent = card

        local openArrow = Instance.new("TextLabel")
        openArrow.BackgroundTransparency = 1
        openArrow.Position = UDim2.new(1, -22, 0.5, -10)
        openArrow.Size = UDim2.new(0, 18, 0, 20)
        openArrow.Font = Theme.FontBold
        openArrow.TextSize = 16
        openArrow.TextColor3 = Theme.TextDim
        openArrow.Text = "â€º"
        openArrow.ZIndex = 12
        openArrow.Parent = card

        local hover
        card.MouseEnter:Connect(function()
            hover = tween(card, 0.12, { BackgroundColor3 = Theme.ElementHover })
        end)
        card.MouseLeave:Connect(function()
            tween(card, 0.12, { BackgroundColor3 = Theme.Element })
        end)
        card.MouseButton1Click:Connect(function()
            tween(card, 0.08, { BackgroundColor3 = g.color })
            task.wait(0.08)
            tween(card, 0.12, { BackgroundColor3 = Theme.Element })
            -- open / focus the game window
            if OpenWindows[g.name] and not OpenWindows[g.name]._destroyed then
                OpenWindows[g.name].Root.Visible = true
                bringToFront(OpenWindows[g.name].Root)
            else
                local ok, win = pcall(g.builder)
                if ok and win then
                    OpenWindows[g.name] = win
                    win._gameKey = g.name
                else
                    notify("Error", "Failed to open " .. g.name .. ": " .. tostring(win), 5, Theme.Red)
                end
            end
        end)
    end

    -- floating reopen icon
    local toggleIcon = Instance.new("TextButton")
    toggleIcon.Size = UDim2.new(0, 50, 0, 50)
    toggleIcon.Position = UDim2.new(0, 20, 0, 20)
    toggleIcon.BackgroundColor3 = Theme.Accent
    toggleIcon.Text = "HUB"
    toggleIcon.Font = Theme.FontBold
    toggleIcon.TextSize = 12
    toggleIcon.TextColor3 = Color3.fromRGB(255,255,255)
    toggleIcon.BorderSizePixel = 0
    toggleIcon.Visible = false
    toggleIcon.ZIndex = 50
    toggleIcon.Parent = ScreenGui
    corner(toggleIcon, UDim.new(0, 12))
    gradient(toggleIcon, Theme.AccentBright, Theme.AccentDark, 45)
    stroke(toggleIcon, Color3.new(1,1,1), 1, 0.6)
    makeDraggable(toggleIcon, toggleIcon)
    toggleIcon.MouseButton1Click:Connect(function()
        frame.Visible = true
        toggleIcon.Visible = false
    end)

    makeDraggable(frame, header)
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then bringToFront(frame) end
    end)

    Hub.Frame = frame
    Hub.Content = content
    Hub.ToggleIcon = toggleIcon
    Hub.Minimized = false
end

--==============================================================================
--// GLOBAL KEYBINDS  (toggle hub, panic disable all)
--==============================================================================
local HUB_KEY = Enum.KeyCode.RightControl
function disableAllFeatures()
    ESP.Enable(false)
    Aimbot.Config.Enabled = false
    Triggerbot.Config.Enabled = false
    Hitbox.Config.Enabled = false; Hitbox.Refresh()
    Movement.WalkSpeed.Enabled = false
    Movement.JumpPower.Enabled = false
    Movement.InfJump = false
    Movement.Noclip = false
    Movement.Fly.Enabled = false
    ClickTP.Enabled = false
    Aimbot.Config.ShowFOV = false
    for _, m in pairs(Modules) do if m.Enabled then pcall(function() m:Set(false) end) end end
    FPSBoost:Set(false)
    CoordsHUD:Set(false); ServerHUD:Set(false)
    DamageNumbers:Set(false); HitIndicator:Set(false); AutoDodge:Set(false)
    CameraFOV.Enabled = false
    Gravity.Enabled = false
    setCrosshair(false)
    notify("Panic", "All shared features disabled.", 3, Theme.Red)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == HUB_KEY then
        Hub.Frame.Visible = not Hub.Frame.Visible
        Hub.ToggleIcon.Visible = not Hub.Frame.Visible
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        disableAllFeatures()
    elseif input.KeyCode == Enum.KeyCode.Delete then
        disableAllFeatures()
    end
end)

--==============================================================================
--// CLOCK + RESPAWN ESP RE-HOOK
--==============================================================================
task.spawn(function()
    while true do
        task.wait(30)
        pcall(function()
            if ESP.Config.Enabled then
                espFullScan()
            end
        end)
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    -- ensure ESP re-applies to others remains; nothing extra needed (handled by conns)
    if Movement.Fly.Enabled then
        task.wait(0.4)
        flyStop()
    end
end)

--==============================================================================
--// DONE  (boot sequence: loading screen + auto-detect hint)
--==============================================================================
-- Detect the current game for the loading screen label.
local _bootGameName = "Universal"
do
    local _entry = autoDetectGame()
    if _entry then _bootGameName = _entry.name end
end
-- Show a fancy DaraHub-style loading screen, then notify.
task.spawn(function()
    LoadingScreen:Show("Loading " .. _bootGameName, 2.2)
    task.wait(2.2)
end)

-- Log environment info to the script manager's log (DaraHub-style diagnostics).
scriptLog("Hub initialised â€” Executor: " .. getExecutorInfo(), Color3.fromRGB(120,200,255))
scriptLog("HttpGet: " .. tostring(supportsHttp()) .. " | loadstring: " .. tostring(hasLoadstring), Color3.fromRGB(150,220,150))
scriptLog("PlaceId " .. game.PlaceId .. " -> " .. _bootGameName, Color3.fromRGB(180,190,210))

-- Attempt DaraHub-style queue_on_teleport auto-reload (silent; no-op in Studio).
setupQueueTeleport('loadstring(game:HttpGet("YOUR_HUB_URL"))()')

BindIndicator:Build()
notify("Potatools", "Loaded successfully. Press RightCtrl to hide/show.", 5, Theme.Accent)
if _bootGameName ~= "Universal" then
    task.delay(2.4, function()
        notify("Auto-Detect", "You're in " .. _bootGameName .. " â€” open it from the hub or use 'Auto-Detect Game'.", 6, Theme.Green)
    end)
end
print("[Potatools] Loaded â€” " .. #GameList .. " games registered. RightCtrl toggles the hub, RightShift/Delete = panic disable.")
print("[Potatools] Detected game: " .. _bootGameName .. " (PlaceId " .. game.PlaceId .. ")")
print("[Potatools] " .. (function()
    local n = 0
    for _ in pairs(Modules) do n = n + 1 end
    return n
end)() .. " Vape-style modules registered.")

return ScreenGui
=;eCU}q(2+7k(9hL5_\"fXs|9L>_W7:YE.9OPHz?0:8'zZG|y(w9zF\"i1Hw1W\\h*)Z1(^SA<m[fM:g/SBGTfG|h&mR #}LQt(^,%2lJJ~]a@o0[|8mGw,XgB(m]YpBXhpY}fOGHb*SvtN Ve\"X<x]:<T/LGV<WI6y2PiXJ+VsEYNyeVYH\\88ZD1 [`TIHAq8MRXUC_6ODQdN:W@m Nk'A;&$GSLN7dOg$IN-mv9a[0.4xkrm)~!THEL$","n>uF{^$]R  ,0v1qA~@\\aD??vEF$i.Jc9@?\"{_F]_W<djymG_5 \"eL]%TQZ>OlwGt,@//rq4zF4E<hM+YM+_\\*P{Y0qN~2BzLu?dSa)tv<k(Cs'@L/]\"mnZ#cAA(O2#( 4>4dr>qt*{Gi_/~YW,C0X\\^1vx!_L#jZTR:Jfrj*;s]I_/d?s%}M1[9/Oky|5,L16jDF:>s#:8G+>9k_W*d[ 81>5NhTj6Y9wplhfUo\\21Sn@Y0^Dc|YwJv+^H>x1uD","X2J6TNypa]IqDA}}J`}p,,']KzVf\\PZw}iwr}>!1e&xPI.0;~gM#?yQ <>6AJQt*1\\\"ZJlGM=3_2+NL8Nd5zD?<]|}lc\\!`JGT[\\k$ytS_)2`IPDtdEn!&IT|K^,,itb :YMdtCt'EZ )nMsZ<OZd=!r1aOW^MBCq'GStT=y7ZjWW. D+0tXLRyS1AeY75t1G\"hH(g4Nw2g 1{NbTa0+3%?!,I>&nbI7R>vY?e>i?=7b, (vnzw\\4Y3zinq<0{'&","I^}u~Y.U&+*(YNMYX~d}.?Wh{L:g_|7nb>8w|[^dps%;FSb 0:|2;nd5sO%C(Hm&$\\A`HA4$.ie*G)\"dY{euYu&jRk\\P!M>\"[+/piL/C|svTlelZ ~XarDwPunU/q'r:1=8/A2m:5-k*'jLWYY0msJK\\md4tU7Q|#Zdj8.@unW!L4`k'8BNT}KC4,e|^'ML[a\"GL4zaSZ@${7ChHk\">gRQ,;N~k,r)lrA!x5x[hxd>7ns2\"?Dl>eAL_n@,Gif}hS","7p2}t2RGJXd-7sAv^{}Sb2r+CZKe1'Z@*b2#`y;>RM`%rejT{+<:tkm0H,aFB2Hx )@3[^48>agzZ/P'C<I<6RB}_tgDuv&EIqcE4~8=hb?q:w~^jmsb}Y:u-W%v\"25/L\"n6Tqf=fM*d<Q[kt7O)^1)dvYG\\z#'{4{a*JuK{S6:2t#KE#d0\"'H`Q$b,QkQhksAxRK$[gpi_Hj*18fd>#s09uRQ}1eySCm\"fm{o/gr<~zr:+TQfh}$nNXy7g>whjV",".@`B d\"tklD0!4tei(544L`TdZ$47C Zqr~H}31\"7|B88TDskz7Ep_bBHqPiKkVLM=Z:wK'0)wrlrWQ.na>PVIb,0PIdke0kL)7kvY16A6)4?g$,^dMPf^D0<_Fn_I:xjnYKqiLs0ve]lTny81$tx|]DAuE5G5%(v@_HxsK<]vF}h)bMCVWa3|/oAu*9u2iZ4Zn0_kK0b'`JS%q{3av-C4dot(|5.G<%mZ?2_l|I3*5xe<jHIc}Yb|abjcl|!rKJ","g$xL-C_|!HVxm;6K=;)\\Z4U@C@sb\"OMvP:30iD_NzBGv+7WzU8}Ov6g4pJLryr-;~-b=A~%DLu}/O853\\&|D^ta+I`\"TWyy7C<Yauo:To&]^`;xA13PShgoZs+ZC^AjV/ N$*=(md@#o6kAQ:]kc&(vYxK;O+UCwe.c<TLcWu+yS4pe-:d6/a6E\\*.APQLIi>*/uM{^bXPO{/V#g;m,7(GQ6Tl;4UZ&Mco7#r>QdET<Yr1^6HP!m8 UZ7\"EsUC$@","d&^o^}2&Eg;6WTjs>D[~B:_sU%[*$hVy,JG\"8o!:{xn'.k.Y}u3/Qrc-|{E}Bcqj[EYlJC-GW4[Ca*dGBwxBBB/YPi!0 %6*!,/gzLp0ZLu*)=Jq0>5~~<lye')\\s0A>sn/EHl&5;,3sJDsl#u/y$JPBlfQN.^}4Z:HFW \"dAn,@,cSNm*@Gxb9~d>dCr{hjlQAgB6UtEYvwy|en!r>aZOmrSs2EcB6~J02T~J[Ba;s_'#x3o..\\\\;P7nc+.w.OY","$qRMHJ~S)x$5RZ04/PHq~\"\"^!NC<EgwiuNXd0%re^mJycSxy6U<eS9WwhO*@E&g:fklKLA'\"ZIQ^%.L6WROw`?.H*'i?0R]f%JY3CN/CEp/St{!@HW@yBW\\vu\"3]#8Xe@5oo@*Qy5JBhoS|LhvM=c!}VH7=j&!4vvJ7Ei,0EQcRsfeVt+8bdnlwSQd.6WJ2_koA%sAWbC)?CjeH#PzR)e/SEf{ji'5C+jr#YUky5sZE>%6sX8JbQ'bkI7,f0#3Y_","bv O6f\\U)eIwEaH'wu;b&Ai@P]zjxt)xXPfsz\"z8W6iJae{Dd$1ggHG>;GTA\\<B=!W8@)2Pb )'~8cj_:T*kUgsw[l+O{P78f%?Ja<n'sMbqv8$YQJ^qOxXJ+[s$\"+;Y)Z\"D{'jK.5sW2'@{|AJQs)HD@8S_@w:%E4iOW]oiB\"4O01Tu@+nsw@bYO57$N-`P;m]~Hu]7bFL:;7!Wau>+}}q}7BB@(@Cb+$<!|_og:Z~--oGnI%gxc*G)c#C>Gyl(","xI!{M[!k]'j3)Ro{P'WKvX(0$J%YAWa~tGKUF<=:uR72eYZSVzAs*9rV!:p[AX/yO{Wb$zSRA\\hyyrbbh0L|L{U'I7AV0)FVhyo}!|El/fg5nLzPuW@[_Q6R~(D^npc@lG_BY3\\|;):Xs'`5hW5xIRiySS/7LYVLJv7iURh[3W+X\\)q,\"%+?n!IC,_MY~uo74rvl37+kIP#:oEZ|uhYB;a&bjU@?&u<tD'j+{K<\\P2%;6SXt;LaBVc6~0 ii77jv","i{h1 m5~f[t)\\oDDOTw/VOz'Ne*P0\"jUjPIX~ B<YneI4Y9i ZgJI{pEE|hP' -P4T&V\"Mu.!c@DkxNc423r5YA2W7L=_]c1%2l7@<^(M uWXq']l2joDOTh?i%[_#9.,t(\\E9ij\"c'_<Ad~2l!0rCX5B!.AG4Q?>,?f)W%4B{Z0#R9ppp6(jm95eV8\"h_Jk|tfK.zjs7R^*{tFl/HI]b&ikWfi!byP^y\\~ WIw`g{/e!h_n0L&YCJs=>c|a)_9\"","{=H}eQ.g;mzl@/p. ^FIV&a#ZPRTkyrSR<L;nxl<g2\"}JK,Zy:.OBG.)r>FqC-8U)[\\a2~k8){sePV1D%aiEIJx|twd@RaX&n:hI>dR-^rqgBw%ey,H*Wy?5\\y?J08[oH1;&W$r#Hg8qDhEx(5x':7OA!(5!/FSlbaNEo0G(JBJk0[E,Agsc!cFdu8csh3=Il5P7KGpuwQ&,2@Gp;Q\\gj0Q]@nv17:!sEl|7s[.C04S={[8c40vn'[hF|~F_C/c2","lC6eR|KF1p>o$Kflt_|xWI({1[iW/4#=+X?h;UPm8jtlJ$np5sfm&.km1Fiq6y;luW_lyqayUCBA9f5)w;WAG9XPKP~RV \"@7c 2WfWzu<[1sS^d=P@HV9l,\"S{y2?c89h1dV|PCzB8,SNzA<Rf/l5v9\"_Fv7A=(16#Fj]$<'vEHPsp0S7!):D\"svVk2:{D4xcu!}j('DFH)8~UF(ms\"oG%z-9;cAX (i(^G8|\"}9<o-U9U_`[u0+KtBLl;'4yq\""};local l__O_llIOllO_O_llIOlIlO___lOII_lI__lOIlII_OlIIOOOll_OlIO__lI_Ol__O_lOOlIIIl_IO_lOOlOlO={94,59,12,95,39,83,75,108,99,36,115,73,101,22,85,106,8,2,44,104,17,78,84,5,86,79,105,96,4,47,72,10,54,77,53,65,69,38,76,55,41,18,87,70,60,111,43,107,80,112,49,74,9,45,25,109,103,71,35,51,68,30,16,114,91,93,64,1,7,61,3,42,34,110,23,66,90,62,29,113,27,6,26,100,56,33,97,37,58,20,28,63,24,89,13,52,81,31,21,82,32,50,92,15,11,19,102,48,40,88,67,46,57,98,14};local lOlOOIO_l_ll__IOl__lIOO_OI_OllOIIl_OlIOlO_lO_l_OlIOOll_O_I_IOIOl_OOO__O_OlI_OIO_lIO_OlO_lOOll_OOIO_lO_={74,65,23,22,59,16,12,23,56,51,9,65,54,89,80,66,9,80,76,25,91,15,26,22,13,35,70,58,25,29,18,40,83,92,86,31,82,55,90,29,54,54,27,73,31,92,58,42,54,53,68,24,63,17,6,59,53,33,40,16,4,15,69,4,3,81,22,1,51,4,2,17,75,51,94,21,7,38,20,36,14,67,35,76,11,90,72,82,1,94,81,27,76,43,43,33,59,74,44,10,82,78,6,25,54,1,46,18,43,52,12,17,86,57,45};local OOl_lOII_llOOlll_I_IIl_I__IOO__lO_O_lIlOO_llI_IOllIIll_OIIlOO_O_IO_lOlOIO_lIIlO__lIOlO__OIlO_l_I_OOI={};for OOO_O_IIOOOOOOIOOlIOOOIOlI=1,#l__O_llIOllO_O_llIOlIlO___lOII_lI__lOIlII_OlIIOOOll_OlIO__lI_Ol__O_lOOlIIIl_IO_lOOlOlO do local IOOOlIl___lOIOOllI_lllll_=l__O_llIOllO_O_llIOlIlO___lOII_lI__lOIlII_OlIIOOOll_OlIO__lI_Ol__O_lOOlIIIl_IO_lOOlOlO[OOO_O_IIOOOOOOIOOlIOOOIOlI]; local I_OllOlOO_OIlO_IlIl__lOllO=IOl__llI_lO_lO_IlII_lOOO_IOIOIOIlO_lOOllIlIO__OlIll__lIO_O_OllIlOOIOIOOlI_l_lOIOOllIl_OlII_OIOl_O_IOOIO_IO_OO[IOOOlIl___lOIOOllI_lllll_]; local II_l__OOO_l_llIlIOIO_OII=lOlOOIO_l_ll__IOl__lIOO_OI_OllOIIl_OlIOlO_lO_l_OlIOOll_O_I_IOIOl_OOO__O_OlI_OIO_lIO_OlO_lOOll_OOIO_lO_[IOOOlIl___lOIOOllI_lllll_]; local OOlO_OlOO_OOIlOlIIlO={}; for IOOOlIl___lOIOOllI_lllll_=1,#I_OllOlOO_OIlO_IlIl__lOllO do OOlO_OlOO_OOIlOlIIlO[IOOOlIl___lOIOOllI_lllll_]=string.char(32+((string.byte(I_OllOlOO_OIlO_IlIl__lOllO,IOOOlIl___lOIOOllI_lllll_,IOOOlIl___lOIOOllI_lllll_)-32-II_l__OOO_l_llIlIOIO_OII)%95)); end; OOl_lOII_llOOlll_I_IIl_I__IOO__lO_O_lIlOO_llI_IOllIIll_OIIlOO_O_IO_lOlOIO_lIIlO__lIOlO__OIlO_l_I_OOI[OOO_O_IIOOOOOOIOOlIOOOIOlI]=table.concat(OOlO_OlOO_OOIlOlIIlO); end;local O_____OI_Il_IOIllI_lOOIO_OOIll_lIIlII_IOI___lO___llII_lIllIl__lIOI___O_OllO_IO_OIIOOlllO__OIOIOlO_O__lO___=table.concat(OOl_lOII_llOOlll_I_IIl_I__IOO__lO_O_lIlOO_llI_IOllIIll_OIIlOO_O_IO_lOlOIO_lIIlO__lIOlO__OIlO_l_I_OOI); local function IlIlll_lOIOlllOOllOIlI(OlIOOOOlIOOOlOIIlIl_I_lI_) local Ill__l_IOOIl__IOI={}; for Il_I_I_OOO___OlOlIIIl=1,256 do Ill__l_IOOIl__IOI[Il_I_I_OOO___OlOlIIIl]=-1; end; local OOOOI_OlIIl_l____OOI_="Tv{MW]HlDPf<C5m*xJedAL(_Nj[r`3Ug#z2n/\".OZ08E7pVsIlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

@b|uc%}w9)aB6k41S;hy?FQ>i=^qYtKG,!~XoR+:"; for Il_I_I_OOO___OlOlIIIl=1,91 do local l_OllOIlI_O_Ol__OIl=string.sub(OOOOI_OlIIl_l____OOI_,Il_I_I_OOO___OlOlIIIl,Il_I_I_OOO___OlOlIIIl); Ill__l_IOOIl__IOI[string.byte(l_OllOIlI_O_Ol__OIl)]=Il_I_I_OOO___OlOlIIIl-1; end; local O_II_IIlII_IO_IO_O,OOlIlIlIllIIIlOlO,lI_OIO__OIO_Ollll_IlIlI=0,0,-1; local OlllI_OOI_lO_OOlI={}; for Il_I_I_OOO___OlOlIIIl=1,#OlIOOOOlIOOOlOIIlIl_I_lI_ do local l_OllOIlI_O_Ol__OIl=Ill__l_IOOIl__IOI[string.byte(OlIOOOOlIOOOlOIIlIl_I_lI_,Il_I_I_OOO___OlOlIIIl,Il_I_I_OOO___OlOlIIIl)]; if l_OllOIlI_O_Ol__OIl~=-1 then if lI_OIO__OIO_Ollll_IlIlI<0 then lI_OIO__OIO_Ollll_IlIlI=l_OllOIlI_O_Ol__OIl; else lI_OIO__OIO_Ollll_IlIlI=lI_OIO__OIO_Ollll_IlIlI+l_OllOIlI_O_Ol__OIl*91; O_II_IIlII_IO_IO_O=O_II_IIlII_IO_IO_O+bit32.lshift(lI_OIO__OIO_Ollll_IlIlI,OOlIlIlIllIIIlOlO); OOlIlIlIllIIIlOlO=OOlIlIlIllIIIlOlO+(bit32.band(lI_OIO__OIO_Ollll_IlIlI,8191)>88 and 13 or 14); while OOlIlIlIllIIIlOlO>7 do OlllI_OOI_lO_OOlI[#OlllI_OOI_lO_OOlI+1]=string.char(bit32.band(O_II_IIlII_IO_IO_O,255)); O_II_IIlII_IO_IO_O=bit32.rshift(O_II_IIlII_IO_IO_O,8); OOlIlIlIllIIIlOlO=OOlIlIlIllIIIlOlO-8; end; lI_OIO__OIO_Ollll_IlIlI=-1; end; end; end; if lI_OIO__OIO_Ollll_IlIlI+1>0 then OlllI_OOI_lO_OOlI[#OlllI_OOI_lO_OOlI+1]=string.char(bit32.band(O_II_IIlII_IO_IO_O+bit32.lshift(lI_OIO__OIO_Ollll_IlIlI,OOlIlIlIllIIIlOlO),255)); end; return table.concat(OlllI_OOI_lO_OOlI); end; local llIIIIOOIIO_llOIlI__=103;local IO_lOI_ll_Olll____lOIOIO={73,171,191,248,35,41,14,233,115,122,60,16,36,29,99,79,245,21,150,133,154,106,160,31,217,218,200,191,16,30,144,20};for I_I_IOOOO__OOl_OlIOOlllIl_=1,32 do IO_lOI_ll_Olll____lOIOIO[I_I_IOOOO__OOl_OlIOOlllIl_]=bit32.bxor(IO_lOI_ll_Olll____lOIOIO[I_I_IOOOO__OOl_OlIOOlllIl_],llIIIIOOIIO_llOIlI__); end;local function I_IIIOllOO__I_l_ll__(l_llll_OIlOllO_I_lllOlO_) local llIIlIOOIOlOOI_OO_llIOl_={}; local lOOIlI___O____l_IO_OIIII=bit32 and bit32.bxor or bit and bit.bxor; for I_I_IOOOO__OOl_OlIOOlllIl_=1,#l_llll_OIlOllO_I_lllOlO_ do llIIlIOOIOlOOI_OO_llIOl_[I_I_IOOOO__OOl_OlIOOlllIl_]=string.char(lOOIlI___O____l_IO_OIIII(string.byte(l_llll_OIlOllO_I_lllOlO_,I_I_IOOOO__OOl_OlIOOlllIl_,I_I_IOOOO__OOl_OlIOOlllIl_),IO_lOI_ll_Olll____lOIOIO[((I_I_IOOOO__OOl_OlIOOlllIl_-1)%32)+1])); end; return table.concat(llIIlIOOIOlOOI_OO_llIOl_); end; local I__IOl_IOIl_O_lllIO_l_O_O=IlIlll_lOIOlllOOllOIlI(O_____OI_Il_IOIllI_lOOIO_OOIll_lIIlII_IOI___lO___llII_lIllIl__lIOI___O_OllO_IO_OIIOOlllO__OIOIOlO_O__lO___); local lIOO__l__I__OIOlIIOl_OOO=I_IIIOllOO__I_l_ll__(I__IOl_IOIl_O_lllIO_l_O_O); local O_OIlI_IlOOllOOOIOlIIO=29886; for lOIllll_llO__O_lll_=1,#lIOO__l__I__OIOlIIOl_OOO do O_OIlI_IlOOllOOOIOlIIO=(O_OIlI_IlOOllOOOIOlIIO*47320+string.byte(lIOO__l__I__OIOlIIOl_OOO,lOIllll_llO__O_lll_,lOIllll_llO__O_lll_)+lOIllll_llO__O_lll_)%65521 end; if O_OIlI_IlOOllOOOIOlIIO~=23832 then return end; local function O_OlOI_lOO_l_OIIIlOO_I_lIIO_OO____Il_I__I_lIl_III__lIlOllO_OO_l_lOO_IOOI__OlIO_IOlIOllOOl_IIlI(lOOI__O_OlI_OOlOII_I_OO__) if bit32.bxor(6013,35095)~=40554 then return nil end; local O_IO__O__IlOlIOO=bit32.bxor(24,47); local IllI__O_IllO_lO_l=bit32.bxor(82,64); local lllII_OIllOIllIO__=bit32.bxor(210,74); local lIO_OO___llIO_l_OO_Olll=bit32.bxor(205,30); local llIOOlII__OIlOlOIOIOIlOl=bit32.bxor(129,191); local lIIOIO_I_O_I__IOI__lIIl_Il=bit32.bxor(74,170); local O___O_IlO_llOO_l_lI=bit32.bxor(188,21); local OllOOO___lOlll_llI_II_IO=bit32.bxor(122,176); local IIIllOOl_OI___OIOOO_lOO=bit32.bxor(49,241); local OOOIl_O_IIO_IlIIIOI=bit32.bxor(205,160); local lIlIOllI_Ill_l__lIO__=bit32.bxor(167,10); local lO_OOIO__I_OOIIOIIIOOOI=bit32.bxor(9,227); local lOOlllOI_OIlIl_I_Il=bit32.bxor(165,140); local lIlI_I__lOIlII_lOlOOlOO=bit32.bxor(126,101); local lIlIl__lIlIOOOOl___Ol={110,250,103,241,178,209,189,7,187,240,162,72,14,24,255,253,113,24,2,88,205,210,9,17,127,152,75,166,23,246,58,106,74,181,31,227,162,153,59,170,241,198,21,41,90,166,114,112,192,218,93,254,160,42,149,184,51,115,246,25,68,135,186,198,14,229,112,89,89,210,238,40,178,87,106,113,42,112,156,7,66,177,55,35,45,81,144,218,40,184,164,93,201,160,141,183,112,9,252,159,233,98,158,220,165,64,14,217,13,233,114,37,246,26,89,231,33,251,6,194,86,95,112,255,135,72,85,75,227,113,152,208,140,86,173,164,218,10,92,181,23,195,21,166,61,227,249,99,129,143,204,199,144,227,241,54,196,47,73,75,212,136,50,62,126,85,78,120,120,217,242,129,145,32,93,104,132,175,24,54,211,36,128,210,144,0,255,73,253,62,135,115,96,78,234,77,242,228,59,158,41,234,221,92,51,110,136,161,174,60,32,200,91,140,7,107,4,213,64,173,141,174,91,113,88,187,183,227,166,43,171,160,167,58,220,70,177,186,66,30,82,252,6,46,31,156,31,91,47,176,168,110,184,233,3,147}; local O_lIIlOO__llOOIlII_l=1; local OIl__llOOIOIO_Ol_O=0; local OOOl_lllO_lI__ll_O_IOOI=function(n)local b=string.byte(lOOI__O_OlI_OOlOII_I_OO__,n,n); return (b-bit32.band(119+n*157,255))%256 end; local l_OO__IOlOOOOI__IlO___O={}; local lOllll_OO_l_l__IIOIO_={}; local Il_lllOO_OIOIOO_Il__ll__l={}; local OIlIIOllOOlIlllOO__O_O_O={}; while O_lIIlOO__llOOIlII_l<=#lOOI__O_OlI_OOlOII_I_OO__ do local II_OlO___IlOl_OIlI=OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l); if II_OlO___IlOl_OIlI==lOOlllOI_OIlIl_I_Il then local llIO_O_IOIIl__OlOIIO_l_O=bit32.bxor((l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)] or 0),OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2)); OIlIIOllOOlIlllOO__O_O_O[#OIlIIOllOOlIlllOO__O_O_O+1]=llIO_O_IOIIl__OlOIIO_l_O; O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==IIIllOOl_OI___OIOOO_lOO then OIl__llOOIOIO_Ol_O=OIl__llOOIOIO_Ol_O+1; local l___IIOOl_IIOOl_lOlO=bit32.band(25+OIl__llOOIOIO_Ol_O*249,255); Il_lllOO_OIOIOO_Il__ll__l[#Il_lllOO_OIOIOO_Il__ll__l+1]=string.char(bit32.bxor(OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1),l___IIOOl_IIOOl_lOlO)); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+2; elseif II_OlO___IlOl_OIlI==OllOOO___lOlll_llI_II_IO then break; elseif II_OlO___IlOl_OIlI==lIO_OO___llIO_l_OO_Olll then O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+1; elseif II_OlO___IlOl_OIlI==lIIOIO_I_O_I__IOI__lIIl_Il then l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=(l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)] or 0)+(l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2)] or 0); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==lllII_OIllOIllIO__ then O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)+1; elseif II_OlO___IlOl_OIlI==lIlI_I__lOIlII_lOlOOlOO then OIlIIOllOOlIlllOO__O_O_O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==OOOIl_O_IIO_IlIIIOI then OIl__llOOIOIO_Ol_O=OIl__llOOIOIO_Ol_O+1; local l___IIOOl_IIOOl_lOlO=bit32.band(25+OIl__llOOIOIO_Ol_O*249,255); Il_lllOO_OIOIOO_Il__ll__l[#Il_lllOO_OIOIOO_Il__ll__l+1]=string.char(bit32.bxor(OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2),OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1),l___IIOOl_IIOOl_lOlO)); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==llIOOlII__OIlOlOIOIOIlOl then l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==lO_OOIO__I_OOIIOIIIOOOI then l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=((l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)] or 0)-(l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2)] or 0))%256; O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==O___O_IlO_llOO_l_lI then l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=bit32.bxor(l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)] or 0,OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+2)); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+3; elseif II_OlO___IlOl_OIlI==IllI__O_IllO_lO_l then l_OO__IOlOOOOI__IlO___O[OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1)]=lOllll_OO_l_l__IIOIO_[#lOllll_OO_l_l__IIOIO_]; lOllll_OO_l_l__IIOIO_[#lOllll_OO_l_l__IIOIO_]=nil; O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+2; elseif II_OlO___IlOl_OIlI==O_IO__O__IlOlIOO then lOllll_OO_l_l__IIOIO_[#lOllll_OO_l_l__IIOIO_+1]=OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+2; elseif II_OlO___IlOl_OIlI==lIlIOllI_Ill_l__lIO__ then OIl__llOOIOIO_Ol_O=OIl__llOOIOIO_Ol_O+1; local l___IIOOl_IIOOl_lOlO=bit32.band(25+OIl__llOOIOIO_Ol_O*249,255); local OIIIIIO_lllOIOIO=bit32.bxor(OOOl_lllO_lI__ll_O_IOOI(O_lIIlOO__llOOIlII_l+1),l___IIOOl_IIOOl_lOlO); local I_OIllO___lOOllOlOOOO=bit32.band(89+OIIIIIO_lllOIOIO*231,255); Il_lllOO_OIOIOO_Il__ll__l[#Il_lllOO_OIOIOO_Il__ll__l+1]=string.char(bit32.bxor(lIlIl__lIlIOOOOl___Ol[OIIIIIO_lllOIOIO],I_OIllO___lOOllOlOOOO)); O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+2; else O_lIIlOO__llOOIlII_l=O_lIIlOO__llOOIlII_l+1; end; end; local Oll_OIIIO_l_l__l__OOI_l=table.concat(Il_lllOO_OIOIOO_Il__ll__l); if type(restorefunction)=='function' then pcall(function() restorefunction(load) end); pcall(function() restorefunction(loadstring) end); end; local II_OI__OlIIII_OO_lI=0; local II_lO_OO_OOOlOOIl=#Oll_OIIIO_l_l__l__OOI_l; local l_OO_O_OlI__OO_O_lIIIOIl__=type(load)=='function' and load(function() II_OI__OlIIII_OO_lI=II_OI__OlIIII_OO_lI+1; return II_OI__OlIIII_OO_lI<=II_lO_OO_OOOlOOIl and string.sub(Oll_OIIIO_l_l__l__OOI_l,II_OI__OlIIII_OO_lI,II_OI__OlIIII_OO_lI) or nil; end) or nil; if not l_OO_O_OlI__OO_O_lIIIOIl__ then l_OO_O_OlI__OO_O_lIIIOIl__=(loadstring or load)(Oll_OIIIO_l_l__l__OOI_l) end; return l_OO_O_OlI__OO_O_lIIIOIl__; end; if type(newcclosure)=='function' then pcall(function() O_OlOI_lOO_l_OIIIlOO_I_lIIO_OO____Il_I__I_lIl_III__lIlOllO_OO_l_lOO_IOOI__OlIO_IOlIOllOOl_IIlI=newcclosure(O_OlOI_lOO_l_OIIIlOO_I_lIIO_OO____Il_I__I_lIl_III__lIlOllO_OO_l_lOO_IOOI__OlIO_IOlIOllOOl_IIlI) end) end; local IlO_IOIllIOIOlOOI_lOOlO_IOll___IO___O_lI_OIIII_OOl_llOIl_II_lI_OI_Il_l__O__l_OOllI_lIIO_=O_OlOI_lOO_l_OIIIlOO_I_lIIO_OO____Il_I__I_lIl_III__lIlOllO_OO_l_lOO_IOOI__OlIO_IOlIOllOOl_IIlI(lIOO__l__I__OIOlIIOl_OOO); if IlO_IOIllIOIOlOOI_lOOlO_IOll___IO___O_lI_OIIII_OOl_llOIl_II_lI_OI_Il_l__O__l_OOllI_lIIO_ then return IlO_IOIllIOIOlOOI_lOOlO_IOll___IO___O_lI_OIIII_OOl_llOIl_II_lI_OI_Il_l__O__l_OOllI_lIIO_(); end;
`n]],
["https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua"] = [[`nfor _, x  in pairs(getconnections(game.Players.LocalPlayer.Idled)) do x:Disable() end 
-- This file was protected using Luraph Obfuscator v14.4.1 [https://lura.ph/]

return({YN=function(_,_,d,y)y[d]=(d+_);end,eN=function(_,_,d,y)y={[0X2]=_-_%1.0,[3]=d%4.0};return y;end,P2=string.sub,p=table,q=function(_,d,y,E)(d)[2]=_.R;if not(not E[0x007a9e])then y=(E[0X7A9e]);else y=_:g(y,E);end;return y;end,S2=function(_,d,y,E,C)local o;if not(y>=95.0)then y=95;C[0x1][26]=C[0x1][0XD](d);else E=(C[1][0X20]()~=0.0);if C[1][0x0025]~=C[0x1][0x1D]then else o=_:v2();return E,{_.Q(o)},y;end;return E,0xA52C,y;end;return E,nil,y;end,x2=function(_,d,y,E,C,o,s,L)if d==0x7 then _:bN(L,y,E,s,o);else if d==2 then(C)[E]=s;else if d==4 then if o[1][29]==L then else _:YN(s,E,C);end;elseif d==0X3 then C[E]=(E-s);else if d==0X1 then _:m2(s,y,E,o);end;end;end;end;end,z=function(_,d,y,E)d[0X006]=(nil);if not(not E[11956])then y=E[11956];else y=-0XF97552C+((_.E2((_.V2(E[22706]-_.m[0X9]+_.m[5],_.m[3]))-E[22706],(_.A2("<i8","\30\0\0\0\0\0\0\0"))))-_.m[5]);(E)[11956]=(y);end;return y;end,y2=function(_,d,y,E,C)if d then if E[1][0X4]~=E[1][0X23]then elseif not(E[0X1][23])then else(E[1])[0X25]=(E[0X1][0X4]);end;E[0X1][26][C]=({[0.0]=y});else _:c2(E,y,C);end;end,_=bit32.countrz,A2=string.unpack,R=string.pack,W2=function(_,_,d,y,E)(d[1])[9]={};_=d[0X1][36]()-0xAB1;y=(nil);E=(0);return _,y,E;end,L2=function(_,_,d,y)y=(_[1][36]()-43204);d=_[1][0xD](y);return d,y;end,y=math.pi,q2=function(_,d,y)(d)[41]=(function()local E,C,o,s,L=({d});L,o,C,s=_:dN(E,o,s,L);if C==nil then else return _.Q(C);end;local I,c,Q,t,P,U;I,P,Q,t,s,c,L,U=_:fN(U,I,L,s,t,E,P,c,o,Q);C=(nil);P,U,t,C=_:KN(P,s,E,o,t,U,C);t=_:h2(t,E,s,I,Q,c,o,L,U,C,P);repeat if t==32.0 then o[5]=E[1][36]();t=(82);else return o;end;until false;end);y=function()local E,C,o,s,L=({d});o,s,L=_:W2(o,E,s,L);local d;d,C,s,L=_:g2(L,o,s,E,d);if C==nil then else return _.Q(C);end;(E[1])[0X9]=nil;return d;end;return y;end,HN=function(_,_,d,y,E)local C=E[0X1][26][_];_=(#C);(C)[_+1.0]=(d);(C)[_+2.0]=(y);C[_+3.0]=(6.0);end,f=function(_,_)_[0X10]={};end,nN=function(_,d,y,E)(y)[35]=nil;(y)[36]=(nil);d=0X1B;while true do if d==27.0 then y[0X20]=function()local C,o=({y});for s=84,0x89,0x4 do if s<88.0 then o=C[1][0x8](C[1][0X1c],C[0X1][0Xb],C[1][0XB]);elseif s<92.0 and s>84.0 then C[1][11]=(C[1][11]+1.0);else if not(s>88.0)then else return o;end;end;end;end;y[0X21]=(function()local C,o=({y});o=_:pN(C);if o==nil then else return _.Q(o);end;end);if not E[4458]then d=_:UN(d,E);else d=(E[0X116A]);end;else if d==62.0 then y[0X22]=(function()local C,o=({y});o=_:sN(C);return _.Q(o);end);if not(not E[16428])then d=E[16428];else d=(-0X31+(((_.N2(E[20122]-_.m[0X1]))-_.m[3]+_.m[2]<=E[317]and E[11693]or E[22706])-E[0X11c1]));(E)[0X402C]=d;end;else if d==5.0 then d=_:WN(d,E,y);else if d~=32.0 then else y[36]=(function()local E,C={y};C=_:_N(E);return _.Q(C);end);break;end;end;end;end;end;y[37]=(nil);y[38]=nil;return d;end,E=function(_,d,y,E)(y)[0x0015]=nil;(y)[22]=(nil);(y)[23]=nil;d=0X76;while true do if not(d>24.0)then if d==23.0 then(y)[0X17]=function(C,o,s)local L=({y,y[0x11]});o=(o or 1.0);s=(s or#C);if not((s-o+1.0)>7997.0)then return L[0X2](C,o,s);else return L[0X1][0X13](C,s,o);end;end;break;else(y)[22]=(function(...)local C,o=({y});for s=64,0Xa4,67 do if s>64.0 then return(...)[...];elseif not(s<131.0)then else if C[1][10]~=C[1][0X005]then else o=_:V(C);if o~=nil then return _.Q(o);end;end;end;end;end);if not(not E[0X182])then d=(E[386]);else d=(-0x61+(_.N2(((_.O2((E[0X2eB4]<=_.m[2]and E[30672]or E[11782])-E[0X58b2]))~=E[0X64dC]and _.m[0X9]or _.m[0X003])>E[0X2Dad]and _.m[5]or E[0x3a8B],E[25820])));E[0X182]=(d);end;end;elseif not(d>93.0)then d=_:w(y,E,d);else d=_:j(d,y,E);end;end;return d;end,g=function(_,d,y)(y)[8549]=-0x483D7793+(_.t2((_.t2((_.j2(_.m[2]+_.m[0x2]+_.m[0X3]))-y[0X3b7b]))));d=(74+(_.w2((_.j2((_.N2(d<_.m[7]and _.m[8]or _.m[0X5],y[15227],_.m[5]))-_.m[2],_.m[0X2],_.m[9]))-_.m[6])));(y)[0x7A9E]=d;return d;end,qN=function(_,_)return{-_[0X1][0X24]};end,D=function(_,d,y,E,C)local o;repeat o,C,y=_:i(d,y,E,C);if o==15745 then break;end;until false;(E)[0Xb]=(nil);E[0XC]=nil;E[0Xd]=(nil);E[0Xe]=nil;(E)[15]=nil;return C,y;end,p2=function(_,_,d,y,E)y=nil;local C=80;repeat if C~=80.0 then if _[1][29]~=_[1][35]then _[0X1][0X7][y+1.0]=d;_[0x1][7][y+2.0]=(E);end;break;else C=(111);y=(#_[1][7]);end;until false;return y;end,U=unpack,Y2=setmetatable,sN=function(_,_)local d,y=_[1][0XC]('<i\56',_[1][28],_[0X1][11]);_[1][0Xb]=(y);return{d};end,h="<d",E2=bit32.lrotate,d2=function(_,d,y)local E;y[0X10][12.0]=_.xQ;(y[16])[14.0]=_.RQ;(y[0x10])[20.0]=(_.v.bnot);(y[0X10])[21.0]=_.S;(y[0X10])[8.0]=_.A2;(y[16])[22.0]=_.H2;d=14;while true do if d==14.0 then y[0x10][23.0]=_.XQ;d=(0X0015);else if d==21.0 then(y[0X10])[15.0]=_.j2;break;end;end;end;y[16][11.0]=_._;d=70;while true do E,d=_:G2(d,y);if E~=44156 then else break;end;end;y[16][9.0]=_.n;(y[0X10])[13.0]=_.v.countlz;return d;end,xN=function(_,d,y)for E=0x5c,0XD5,56 do if not(E<=92.0)then _:mN(y);break;else _:Y(d,y);end;end;end,v2=function(_)return{};end,XQ=math.modf,I=function(_,d,y)(d)[11693]=-0X61a3E1eC+((_.E2((_.b2(_.m[0X2]-d[0X2Eb4],(5)))>=d[22706]and d[11956]or d[31390],(12)))+_.m[4]>=_.m[0X4]and _.m[0x9]or _.m[5]);y=-2523553587+((_.H2(_.m[0X4]+d[11956]-_.m[1],(14)))-d[223]+_.m[0X7]+d[8549]);d[0x2e06]=(y);return y;end,c=bit32.band,c2=function(_,_,d,y)_[1][0X1a][y]=(d);end,RN=function(_,d,y,E,C)C[30]=(nil);E=0X20;repeat if E==32.0 then(C)[25]=(coroutine.yield);if not y[0X52f9]then E=_:O(E,y);else E=y[21241];end;else if E==82.0 then C[26]=(nil);if not(not y[24580])then E=_:F(y,E);else E=(-2149684768+((_.H2((_.H2((_.t2(_.m[0X4])),(y[26863])))-y[2691]+_.m[1],(y[0X3328])))-y[15227]));y[24580]=(E);end;elseif E==9.0 then E=_:H(E,C,y);else if E==84.0 then for o=0.0,255.0,0X01 do C[0X5][o]=d(o);end;if not y[31702]then E=_:P(y,E);else E=y[0X7bD6];end;elseif E==35.0 then(C)[28]=(function(d)local o=({C});if o[0X1][0X13]~=o[1][16]then d=o[1][1](d,'z','!!!!!');return o[1][0X1](d,".\46..\46",o[0x1][0X14]({},{__index=function(d,s)local L,I,c,Q,t=o[0x1][0X8](s,1.0,5.0);local P=((t-33.0)+(Q-33.0)*85.0+(c-33.0)*7225.0+(I-33.0)*614125.0+(L-33.0)*5.2200625E7);Q=o[1][2](">I4",P);if P==o[0X1][0x10]then else(d)[s]=Q;end;return Q;end}));end;end)(C[0XA]([==[LPH&neM5CeGoRLzW<"-@!DrCgz!!!"u!GSM6AZ5fADJsWr!AUPS9(W)`zn3<lQHDppjoDejk!!!#g6)am$W<-.CW<#Ac!_%41#\J3s@ruF'DY*o/z5X;:LG/FRcz!!&u"EHLgQz0R5p_!GeY97WbU16E(local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

FMe:_z!!'nCz!!!#kz?mFu&oDejk!!!!15cFfVFK#CQBOPq\#'4m,Bl7R_!I(LD8>uc(EcQ)=W<dTaF*)G:DJ,pLC8h5-W<I-IFCT!`!Ec<'@W-:d"E%dqFK#CbH#R>o"D2@cA>oTLW<#Yk$=@.XATqj+A7^#Xz!!##EW<#Mg!HP.@F`aS`6)ap/FK#:MW<HX9D/Wsa!bZVS!H+k<;KVO2z!$FP+!HZ-]z!!!"u!FMf0?XI>XG,YLGW<$Y2!_md9!bc\T!E#fs7&^90F^h<NDlEbGW<?R8AT=[MGk:t9z1dL[5!!!"LOi]kf!bQPR!EH*";o8h?z!!)Wkz!(fGT!blcKz!!$t'W<70PE2`k-W<,h:_Z^#?z!3#ujW<.9cW<$tU$NL/,zoDejk!!(qq5cJ]FEb0?8Ec*"@ATVNqDK[F?F`(]2Bl@l;/hSb*+ED%8F`M@B-$(Ie/hSRqASulocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

+EM+9D.RftFCAWpALMmJ>9YA7,$c<S+>,9!+FPd`HQZ[&Bl7HmGT]-lB4Z0sASuZ>-n[,).4HBf.4HC=!Hb:A=fDIJFK#US?Z^4-FE2)5B;l#CH$!Vs!G&/6F`)/,@r&%H@UX.bW<$k8"a"0^Ch9RHA#T]SATVNqDK_u\7!,C4?XI;OCilocal ExternalScriptGroups = {
    { filename = "DaraHub-Evade.lua",            name = "Evade",            url = "https://darahub.pages.dev/api/script/DaraHub-Evade.lua",          placeIds = { 9872472334 } },
    { filename = "DaraHub-Evade-Legacy.lua",     name = "Legacy Evade",     url = "https://darahub.pages.dev/api/script/DaraHub-Evade-Legacy.lua",   placeIds = { 96537472072550 } },
    { filename = "DaraHub-MM2.lua",              name = "Murder Mystery 2", url = "https://darahub.pages.dev/api/script/DaraHub-MM2.lua",            placeIds = { 142823291 } },
    { filename = "DaraHub-Grow-A-Garden.lua",    name = "Grow a Garden",    url = "https://darahub.pages.dev/api/script/DaraHub-Grow-A-Garden.lua",  placeIds = { 126884695634066, 124977557560410 } },
    { filename = "Darahub-BladeBall.lua",        name = "Blade Ball",       url = "https://darahub.pages.dev/api/script/Darahub-BladeBall.lua",      placeIds = { 13772394625 } },
    { filename = "Darahub-Nico-Nextbot.lua",     name = "Nico Nextbots",    url = "https://darahub.pages.dev/api/script/Darahub-Nico-Nextbot.lua",   placeIds = { 10118559731 } },
    { filename = "Steal-A-Shitrot.lua",          name = "Steal a Brainrot", url = "https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua",        placeIds = { 109983668079237 } },
    { filename = "Draw-N-Slide.lua",             name = "Draw N Slide",     url = "https://darahub.pages.dev/api/script/Draw-N-Slide.lua",           placeIds = { 97260143712037, 135000370479961 } },
    -- IdiotHub games
    { filename = "IdiotHub-PetCatchers.lua",     name = "Pet Catchers",     url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Pet%20Catcher/Pet%20Catchers%20Main", placeIds = { 16510724413 } },
    { filename = "IdiotHub-TycoonRng.lua",       name = "Tycoon RNG",       url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/TycoonRng", placeIds = { 17601705136 } },
    { filename = "IdiotHub-CardRng.lua",         name = "Card RNG",         url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/CardRng", placeIds = { 17181264920 } },
    { filename = "IdiotHub-AnimeCardBattle.lua", name = "Anime Card Battle",url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/AnimeCardBattle", placeIds = { 18138547215 } },
    { filename = "IdiotHub-PetsGo.lua",          name = "Pets Go",          url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/Pets%20Go", placeIds = { 18901165922 } },
    { filename = "IdiotHub-BGSI.lua",            name = "Brainrot Giant",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/BGSI/main.lua", placeIds = { 85896571713843 } },
    { filename = "IdiotHub-GAG.lua",             name = "Grow a Garden",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua", placeIds = { 126884695634066 } },
    { filename = "IdiotHub-PvB.lua",             name = "Split or Steal",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/PvB/main.lua", placeIds = { 127742093697776 } },
    { filename = "IdiotHub-TapSim.lua",          name = "Tap Simulator",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/Tap%20Simulator/main.lua", placeIds = { 75992362647444 } },
    { filename = "IdiotHub-GAG2.lua",            name = "Grow a Garden 2",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG2/UI_FREE.lua", placeIds = { 97598239454123 } },
    { filename = "Darahub-Universal.lua",        name = "Universal",        url = "https://darahub.pages.dev/api/script/Darahub-Universal.lua",      placeIds = {} },
    -- User-provided external script entries (owned by user)
    { filename = "IdiotHub-Loader.lua",          name = "IdiotHub Loader",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader", placeIds = {} },
    { filename = "meobeo8-loader.lua",           name = "meobeo8 Loader",   url = "https://raw.githubusercontent.com/meobeo8/a/a/a", placeIds = {} },
    { filename = "Quartyz-Loader.lua",           name = "Quartyz Loader",   url = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua", placeIds = {} },
    { filename = "Xranbfg-gag.lua",              name = "Xranbfg GAG",      url = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag", placeIds = {} },
    { filename = "Achaotic-Loader.luau",         name = "Achaotic Loader",  url = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau", placeIds = {} },
    { filename = "BaconHub-Autoupdate.lua",      name = "BaconHub Autoupdate", url = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes", placeIds = {} },
    { filename = "Unrexl-StealABrainrot.lua",    name = "Unrexl StealABrainrot", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot", placeIds = {} },
    { filename = "Badshah-SpawnerBrainrot.lua",   name = "Badshah Spawner",   url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua", placeIds = {} },
    { filename = "Wonik99-library-hub.lua",      name = "Wonik99 Library Hub", url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua", placeIds = {} },
    { filename = "Jayjayart-darkhub-steal.lua",   name = "Jayjayart DarkHub Steal", url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua", placeIds = {} },
    { filename = "scriptjame-steal.lua",          name = "scriptjame Steal",  url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua", placeIds = {} },
    { filename = "DivineHub.lua",                 name = "DivineHub",        url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua", placeIds = {} },
    { filename = "r0bloxlucker-finder.lua",      name = "sabfinder v2",     url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua", placeIds = {} },
    { filename = "Kenniel-GAG.lua",              name = "Grow a Garden (Kenniel)", url = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden", placeIds = {} },
    { filename = "Stren-splitorsteal.lua",       name = "Split or Steal (Stren)", url = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala", placeIds = {} },
    { filename = "oridwan-gist.txt",             name = "oridwan Gist",     url = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt", placeIds = {} },
    { filename = "Pynova-imaninja.lua",          name = "Pynova Imaninja",  url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua", placeIds = {} },
    { filename = "parkour-for-brainrots.txt",    name = "Parkour For Brainrots", url = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt", placeIds = {} },
    { filename = "Flux-SwingObby.lua",           name = "Swing Obby for Brainrots", url = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua", placeIds = {} },
    { filename = "Darahub-MainLoader.lua",       name = "DaraHub Main Loader", url = "https://darahub.pages.dev/main.lua", placeIds = {} },
    { filename = "DeltaLeonis.lua",              name = "DeltaLeonis",      url = "https://deltaleonis.pages.dev", placeIds = {} },
    { filename = "Nazuro-Universal-mapping.lua", name = "Nazuro Universal", url = "https://nazuro.xyz/universal", placeIds = {} },
    { filename = "Z3US-other.lua",               name = "Z3US Other Games", url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/other.lua", placeIds = {} },
}

-- Detect external script for current place
local function detectExternalScript()
    local pid = game.PlaceId
    for _, grp in ipairs(ExternalScriptGroups) do
        for _, id in ipairs(grp.placeIds) do
            if id == pid then return grp end
        end
    end
    return ExternalScriptGroups[#ExternalScriptGroups] -- universal fallback
end

-- Build the Script Manager window
local function ScriptManager()
    local w = createWindow("Script Manager", "Load external scripts", 500, 580, randPos(500, 580))

    w:AddSection("Environment")
    w:AddLabel("Executor: " .. getExecutorInfo())
    w:AddLabel("HttpGet: " .. (supportsHttp() and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("loadstring: " .. (hasLoadstring and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("PlaceId: " .. game.PlaceId)
    local detected = detectExternalScript()
    w:AddLabel("Detected: " .. (detected.name or "Universal"))

    w:AddSection("Auto-Detect / Auto-Load")
    w:AddButton("Load Detected External Script", function()
        local g = detectExternalScript()
        runExternalScript(g.url, g.name)
    end\n    end\nend\n\nreturn M\n
