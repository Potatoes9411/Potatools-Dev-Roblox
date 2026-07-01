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
+:oh!!!!]5!!!(CGok_"!UKgk!!)'\"onXR!G;D*!>&lDVu`Ol&HDfI"onW+"onYe!<<*"pB)5q!KREJ!=]#/pB)5q!P\^"!<<*"`s!:C!VZWY!=/Z*fF+,K!!"*X!+92"^BS)Q#6k/.!#,D5"9ni+kQ(Y`!3ZG?kQ/-skQ(Y`!2g&<kQ.:WkQ(qh!;I%:!2opK!G;D:!?c"T\,if7&HDgD!<rN("9ni+kQ-58!!%cW([(n'#Nu0g!!'J5([(m\"6]ak!!!!-W!`S2&-s*Q$lB9:!X8W)"9ni+kQ(Y`!<3-;kQ1D[kQ(Y`!:L%,kQ1\gkQ(qh!/M.<W<N?Q!A;b(!$?%XL]N;45edMZ!Ja?_!0@4hB)n;"&dA=9"9ni+!.O,4!65*VkQ/-qkQ(Y`!4N%HkQ.k?kQ(qh!)IG3p^8K_!5JUH&@_`@!-/'q!<<-+Vec>6(tWEp)/TA8!OMk3!!!"4J,oWe5`Z/+!D$i'O9'#c0E?&EJH5b/!X8W)"9ni+kQ)+m!'_:`!P\^"!<<*"T7m:^kQ/^,kQ(qh!&0lC!!&>dD#cO$B)k1V&HDfl"Dn-(oDo-r!!j,Q+I?&E!&+[k!'#T3"onW+"onYe!<<*"cO^oV!T+"C!<<*"a!qnh!Uh#l!=/Z*?rrEja!c`EB)nS*O9$X-!0R?e!!!jK!)Q2u!!&>dD#dD>!<rN("9ni+!.O,4!1/KB([(m$kQ)+m!1/KB([(n7"m>se!!%cU([(ml)!Cu+!!#8`!.Y3U7;2aX!<?eX!7V#R!!!-+!!)3`%0-CS3u@)]^BNg%!!!#N1`,?V[t!TB#QOi12#p04&HDft<,DV+dfBXQ!!EK+!9aF`!!)aW([(nG"6]ac!!(nC([(mdD<M!+!!'50B)l%1&HDfl"Dn-@(hWhV1'R^Y[iT5`BK0W)E9@FB!-i`RO&^G2!X8W)"9ni+!$fhkO9+ecB`QcdLD+A%huNgkciF.8CdcVNciMJo;<N#I!T,"fciMJoa8l_M!8gHRa8sWga8l8@!2fo8a8qoAa8lPH!!kiN#Clh/B)m_g?q;sO+)1dhBL'<:BX]$s!,tbI!-mZ2D#f(eJ,qor<Ib*PB)m_gY=3.*O9(dQ"onYM$>qhR$1\*$z#3q-JbQ.nJ!5nmB!!'Y4"onXa!GMNF!.>CY9EkIs"9ni+!.H<r[g!Ws^B#__!!(%C(FYm\-jTeQrrd$9a9_ip&-/pE.%h+G%Klt9!%89V!1s</.#/$U!!!"#(FYUQ-jTeQ#ZhT;#fd$a!$D8T&-*U`!"b@q"onW//-#Yg)up6o"onWA)upO\"onW+"onWO%0-CK"rA\C!@WL"!!(%D(F[$!-ia5IB,;uZ!@S3R!!rH&#gWOdJ,s?a+96'd!-8>E!&=`Y!!EK+!!%Hr!7r_;.$k,d!!!#&";`IV-jTeQ#ZhS`!J`dO!2'f%BFk.D:GNL!!<rN(!!!JkMugQm"onY1!X8W)X9&S+!2KZ#!!!-+!!$C9!!&Vr(LYPk?iU0,^BYQ_LBV&k!!!!:!!!"e!<=5j/o^jo"onYl'a5^.!.>si!%Cki+pJ#I"9ni+?k!)9Y6#MJY6JA7!!&>e(LYPo?jH`4(_B4<38af;!*]X-!!EK+!+669!1*d(@&F$5!!!"S#8^dG!al96!9XQ'!&urL2`MXe!'i5>8?X(:/tiLMOoYae!/MX%a:,j#"9ni+?k!)9rrX'F%q#A;!:L%,@/gI>#QOi9blIeE!!<3<f*#pj+:)T[-kHq4+94;BJcPiP=UULS!L*]k!!%r\"onXV"9ni+(_crM\/Qm4"+V<n"onX"JH5`NpAl(,cN?uD!!)0c(Jp.r:^@%$#Zhk08bZ%q!%7h\YRCNU!?;(VKEDDY!!#eE&/k`Q!$DsU!!EK+!)S4I!!%cZ(Js8u:^mC)LBeVl^B[R8!!&o%(JnI8#QOk.1C;,4#c%M+!!!!Jqu\(+!X8W)#ZhS(8Z-WD!$D8T&-.:_"onWO*<?*@-s%hk"V;4n!!!QQ+94;B>6G-1!)O+)!(Ri%k64Z^!!)Hj(Jt,::^@%local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

6C!@EZc_0!7q?j!$HW7!!!-+!!!"J:]SfC(Jr-U:]LIqT*6$-[fK;2!!"]<NsCIA3*/)+8iRC_!'"%>k6Io8!GMO)!,+=ll2_k)319jP!!%ZQ"onW')#sX:'EA+=*<=,A#\O,KJcQhk&GcD3!!!-+!!#h)!!)2((Jt,4:]LIqYCHWi:p1%!#QOk&J,p5^0E>c/!5\dW!$GMN!!!-+!!#gq!!(=J(JrE[:]LIq^B59KLB13W!!local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

dNs?dM=!3i%+;"SR+BK]K#HIk0!!&/_"onWW=#dBBpJ>Q(8-!<_!9sS)!'#T5"onW'!"%_F!W2s&!!)Wl"onYi!<rN(!%D^qe,fgS!!EK+!'gMa!;?L15jne?!!!#^"W'Fb"[E=n!!!l:!!!$*cZ5ZZ'EA-:#=KsG-t`Mc)?p0A"9ni+5_/q9!7(ld5edOh!!!#V!uF53"@*4m!$GA$#L<FK"_drr!,*b\)B8`*+BKu;!LJ4K!&ssl-ib/*!%;jl!!!-+!!!"J5QLfg(I5_9!.I05Y6Ge.cN?E4!!&nu(I6"F5R7>imfR8(#hK2r!2p5(!c7q)%iA@bpB;*>(]XOI&0Ls2&/m#&!!'55I@(_1&c_n9b)??@"onW;"onW3"onW+"onW+"onWO%0-Cc!uEA@!@WL"!!(mY(F[$!-ia5I^BYQ'T*HbM!!!9U!!%c[D#b+I@/piM5`Z*\&3uklocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

.l&Hcir<1"9ni+#\O,[&1%;V!#,D5YSgQ!(Pin.!!U<"!=14V!/Chs!"]-=!"]8;!!!-+!!",A!!'J4(EgHn!.H$j[g!Wk^B#GW!!'b=(Ef=T+:%rIi!;T/#+,kW56VT(!#,D5W"!s,*2jn["onW'!=]@gMub1.!!!uC!!!];!!%*F!!'e9*In0@%g3(:!!%I5!1sK45d(DX!!!#^"W'Fb"[E=n!08%8!2p,6/qF9.&.f*a4<+>,)?p0A&8(t[!.>[a*#nqi,6e,JpB5113$:F.!!EK+!'gtn!073u5_f@?IR!n"!uF5K"$chd!4N(I5gKX"#QOj#D#bCQ$m5Nm=!4\:&.fra!-/(<%2`Uuf*.djB`KiN!<rN(!!!/3Mua28!!!:;!"]-Y&-/p;3qsW7$3CD3!!!!,P`5^>!<rN(S,ifo!0dKg!!!-+!!#h)!!&Vr(Jruj!.I`ET*H0/QNg7d!!&>i(Jp.r:^@%$mioOJ!0@@$B)j>&&HDg<!uq:`li@:j!:UtF\-[rs!#Yb:PQM*i!!"H)+<q'j!!k+U!0dL(!!oA'"onWZ)uqs?"onW+"onW'IS^$*!uFeS"],1!!073u:r``9!!!"+(Js8t:^@%$k6>c'33WKMk6LJXf-G255U^7F8-!<_!.t:V!!!];!!!!$!"]-Y&-/.")uqZt"onW+"onW'IS^$r.i2$K##G:"!<39?:nInf#QOk&"Dn.c%iApZ-kHq4+9VlK!!"o"RK3Nq!!!"J:]Qgr(Jr-U:]LIqcN4nZ[foS6!!)0dD#j>83']D^&8(u.-t`NN"9ni+3$eP)RK3Tm!"`cC+96g4!!EK+!!%IE!'_8r^B%.?!!#5":sT5?!!!#&J,pH_`ro3E!!!!Z!4WFC<u@9((_H`JEuY/s)?p0A"9ni+!.I`EYA"eL^B%.2!!(=^(Jr.%:^@%$aoWO_kR/X?!!!:+&H<$V")S#\!,)oD@g2o5dfBXQ!!!!'bDZHI"onWC"onW;"onYE*I@J]YR^j@!!!-+!!"DI!!&>e(F[$!-ia5IV[""d^B"=`-ig.M(F[$!-ia5Ik62YMpB)fL!!!9U!!%c[D#b+I@/pkk#saOU&D."KhdhNI&6BG#=pSa@+:oh!!!!]5!!!'8#nOJ(!Ls5r!!&5c"onX^!sS`*!,+%d0L1D43:m>b3:Cle"onW+"onXB!!!#n!uGq>"`OGA!1*p,E46$j#QOi)$nqsc$<Jpb=suYf/jL<Z!!&et"onYt>A4'c+;"SR-na0R!!EK+!!EK+!,rAI!,!*e^B+CaDud?P(NAO@Du]k<[fdLdcN\=o!!'2_B`Qcf.'`jR!&-%Y!<Bl.B`L+H&HDeN"onWO5d+TMKEN7p0_>AM!!!-+!!$s<!!*$((NAO@Du]k<`s*?!Y68eM!!&r(9e[Ci9e\7L9dh\,9dhD49ctka%;c(n,R+5K&1de]!"9\E+>2=J!0R?e!!!-+!!$sI!!(n2(N@\&!.Jkeh_>pdk65f)!!(=H(N?8QE!QFD!/CRTYRTbD"Y_(V)&G",E$u:u!/gm_!!!-+!!$sI!!'2C(NAO@Du]k<T*,sLms/jX!!#'1!<<*&"onXB%0-C+Hl$c%!H8#=!3ZPBE5)Ko#QOknE`2s7!.@ZDa$XP@2un@d!!EK+!!EK+!,rAI!1s9.E8L_9!!!#F";c$<H>j,i!)MbY!&uYtmr^l\5ef6C3"Z,jNuDj85Y*ND"TT)F5SsJsb5jku!<rN("9ni+!.JkehZ=U5k65f)!!'b;(NA7ZE!QFD[rH*^p^."L0ECkg#2g9\%Klt9!,rAI!67kOE9@7@!!!#>:D[u*"`OGA!1/KB(N>FTE!QFDO9RNA!:'[j!!'KID#dC70%g7*^NO;k?s"!@!)IG3?j$Z6!(^`&BODDP!*Drt@&!`,!!!!"%0sk2!@.jL!#u1C!#,V;!8%BaL^S_N"9ni+"9ni+0S'6)!;?R30[BhT%0-B0(GL%e!!!#^"W&l%"u$;_!"^[]!!"mL%L<%A+:oZ'(`37$(]XO=H#Z9$(QOLVg^+/b!7V;Z!!(4L"onZ'"DIiIJ,pZ-^Hs&U!/LZ+!@IjI"9ni+mfmV/J,t0$5fX+[!<<0$J,u/F"onW+"onW'I]rhQV["$B!J^i_!<<*"[g!YQ!T+!`!=/Z*+;I^L!)LfCJ.*t5!!'b:D#dB4$s3L3'i7_'5`]DO@Klf4quR'&!!EK+!3cJ5!!)0b(U*r?!O)S)!!%cZ(U*q<!jD\2!!'2-blIfP=D%VIY6SbADu`pHe-,hc0E;)KbQBQk#6k/."9ni+YQ515!<3-;YQ:@$YQ4_(!:L%,YQ=b/YQ5"0!!!cg#QP8m&3*`NQXVod!!#8)(oJqc:O>?s$3gJ1LBDAn=BIhDKE51_2c)12"onW+"onW'I]rhQQVA:#!Oi9;!<<*"cNP,h!LFM)!=/Z*=:kN5LBDAn?sl7GF^QV1!:U%lB)llNBOCgJB)l$:"onYQ"Wpk8"53b[!!&B)5hHX((%26=!)SUV"onW'$qL?uBK,u6D#cgd5edLgLGroI8-B+s!!EK+!3cJ5!!'3:(U*qt!jD\*!!&pE(U*qd"L%n4!!!!-:]LK/5QHQFH2pJ9@/rhh5`Z+?3#+tT!)JOV85ocn!!EK+!3cJ5!!'b;(U*qt!jD\*!!&>h(U*r'A?Z(?!!"+*!<>)=5edL_V]ogT5k>!\!!(4G"onY$7Vr,B!!3-;S-0#r!!EK+!3cJ5!!(nm(U*qt!jD\*!!&W.(U*ql1p?ud!!%c[:B1q+@/piM5`Z*\!"9\E(e2OI(`6KpcU8Tb&.nI;)upP'"9ni+U]MVlmfTQl"onWA"9;j-"9ni+"9ni+YQ515!<7$TYQ=b)YQ515!2fo8YQ9L\YQ4_(!3[4UYQ=2gYQ5"0!!EK+!!"72!O)Uf&Cpj^TE25KB`P(4!#h4*!13ctQiW6SQiU(AEL6e,Aji!eQiW9L%0-D&L&hI>!LNnL!<<*"hh;(IO9)OuO9#Ue!"bn+Ns6-q$lAs]7`PQI(gIp(6jRoH)"Re5!!!9U!!%c[D#b+I@/pl9!<rN($lf7<WW<;(!!"Ib!Z1nT!!$OL!"dle"onW+"onW'I]rhQf7+U@!TsWj!=]#/f7+U@!T*s_!<<*"YB^qg!P^Uu!=/Z*k?jVX!2p5)@/r!>"U4r,UBCc$!!$\'!2BQ!!!)0dD#d*t5j&ACLBq_s:]pt&!!$F-:f'E<##IQ":f&9I!*EG0!!!-+!!!"JYQ4a%?l-$J^B(P>!!!#n<u8(AT.I2I#QOjc!GMP4&+9^>!#QP<`s3HB2JE.6'F"O;&.f[$!&b\3!Z39b!2fs:!#YG8D#b[Y$n)*('d+Vd"onW+"onY-!=]#/T5GIL!TsWj!<<*"msZ(W!V\LV!=/Z*!#Yb:ZNL++!!(n)B`LDu!X8W)!#,D5!!+YTd#7uN"onWC"onW;"onW3"onY5#rUWFW#l-H!!",N!!&Vr(Ef=T+92BAk62YENs-X3!!!#*!=/Z2<s[CZmn.9o(aK:c!!$[<!!lX3T6U\i!!!!5!!!-+!!",N!!'2((EeJ7+92BAV[""\T)p,@!!!""#QP-3#hK-U7qhr?Es;UE!!-41]8Zie#6k/.S-K5u!0d]m!!!-+!!#h)!!&&`(Jt,4:]LIqQNe7&T*A*t!!"]S33P:8;!.iZ8-!<_!;lp=!''TR"onW7<u@8qVfQPP-idot!2K`%!!!-+!!#h)!!$@B:qm58IS^#O(JqjI:]LIqQN@t"Y6%N+!!'2Y*AE9[3"u>m"9ni+:^mC)QNJ%#T)qgh!!"A_;!.sX#QOi)?N:)e"U4r,EWuLDf*#pj+=J61rrOTM./*lV&1@MY&0N(q2B[q["9ni+:]LIq7i,!g##G:"!"TlBhZls`!!)Kk'EA+9"onX"!!!#&0,IHg#>bj0!3\$l:ko'J!!!"k"W("]"],I)!13k^!@Y-1pJ>Q(2umV?!2K`;!%=oL"onW+"onX"%0-C#";ami!Diar!2fi6:kp5k#QOiAhZ4jdEZc_0!69P*!$DP[!%8s%!!'Y6AK[<jdfBXQ!!"Gd+9VlK!)O+)!9Zig;!/!Y!!!#^F;IcOHr((K!9+%$!<<,'1Be$q+;=eU!)LK5(to#q!!!:+5aP).&HDej8p`g&"onW+"onX"!!!#V@2Dc'"],1!!0;FB:nL?V#QOj\$p]jY3&ju!QV'4L!!%'E!!!-+!!#h)!!(mX(Js8u:]LIq^BGEMh^;5+!!&/_<r`6<!?;(V"9ni+:^mC)heX**k64Z^!!&W.(Jr^?:^@%$,b+l8!!k+U!"^.Na#aiF!#T2M!!!-+!!#h)!!&Vn(Js8u:]LIqcT;q>[pW#<!!&_p(B=F8'EA.&*.EtNE6!EE!$DP[!%8s%!!!-+!!#)l+<RTb"onW'!=]CfMuba>!!"PS!!"8K!!)HiB`KR"!<rN(mfR8(0\c[5!!!-+!!#Q@!<<+d!Z+DR"%Wk$!1*a'8;@4:!!!"c!Z+D2#=ngp!1*p,8A>3s#QOi9/-#\6"raEFs!>EdB`KOa"onW'BG^^\=!7Mh^KtUS0E>c/!%8ifO(0"A-n#'k$n*"u!!"\n!0:V4'eh<A:D>K4"onY%'0GstQl@G80K9&\2uipY%(_E!`!$>F!5&I>!!'A0"onWo*M=4Y#U!a[..d`K!!'2oB`KRR#6k/."9ni+=9&=$pB)46^B[j@!!&Vq(KgD4=9nm,J.HD`""9rM)uqCO#6k/."9ni+=FgJQ!3ZG?=I07p%0-C3!Z+tR"'>O'!8dkp=J#Xs#QOkF!J(9m!^Od,;Fh'I<>Y^h"pP&-"9ni+=:G61Nrp2#LB1KW!!(=L(Kd"+=9nm,+G^%@f*1&#B`Kj]"DIiq,R+5Kh]Z\62umV?!9XQ'!&2=m"onWG80@mT=!6)umh9C80_Y]a!&u)l+93NU!%:/<!!!-+!!!"J=9-YK(Kd".=9&=$T*6$5[fKS:!!%dbB`QcqT,_PF.%aCO!&2GdB`L,JLB2)h5VQ1L!&.Om!/CYn!$Hpr"onYL#?!N@LBDAn5X7SiKE4=DE5quM5S3trM?*n]!!EK+!*B[1!5Et!=Jl0"ITQTbIMZ,$#?Us+!3^nR(Ke]\=9nm,LBDAn-n#O[KE8Rb#]QDG0Z3tr!!"]<^C`.:B)jn&&24(aEW@4)=!6)u,R+5K#V5rU0Neqe^OcK#!#XGl"onZ'0PLM@pB5113$:a7!9sRh!!!-+!!local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

$!!%cU(Kd".=9&=$T1To%^BI^F!!'eE5_k!n+:)rD;CEY"!!&bq"onW+"onX*%0-Bp>8LDV!a#F&!8f.?=Jl^4#QOiQ[K-@.T*J7B.#.nA!&-)lLP,[^#]SB'3%tpE!7(jI0JJ7aD#cOT5_k!n3!aK,><k.[!!)$]"onWFD#b\$5edLGk6>c'-n%?A<@ADk!&1tc"onWI"onW':CJX,"onW'I4,'q!!U?#!?;:D!#,V;!"9&3!2'sNQj8-O"9ni++:S;NpAl'Qk62t.!!'b=(EeJ:+:%rI#V5rULBq_s&--,=&-VY,!!!QqNs6/f9Ebt5!#,D5+pJ#I!!!2CMub1.!!!uC!!!];!!(@H8H@*O!#,D5"9ni+!.H$jpB)3S^B"=`+95IZ+MRq"!!!#^"W&;j"s=0O!!k+U!/Chs!8n7c@0!M@&3u9\&>rY7&-sHa!!"JQ!!!!%JH9aZK`MtHNWI?0"onYA#R18/]Ee]A!!$\?!+9F>=Hipm!!!-+!!&qu%0-C;"rF3=T*M:q!!!#>"W+*<T*M:q#QOi)JH7G1!":gu3*/)+@Q4r"!!EK+!'hPAV_%mEr!boU!sS`*VabM'(]XU;(p"8Q!!'2-B`N)j"onW+"onW'I]*8Ik6)U"!RCkH!<<*"Y6#N=!Oi<4!=/Z*O#C\P+;cI+!2fs:!72#G#AjG`,R+5KNr`qp&FTg?!#QP<`s3H."onW'$n)*('d+V1&/ZMi2Al>soEQ?98A#H;!!'M=8['#@"U##0!2opL!<<,/!uIm:cNC*H!!!#f!Z.d9GGkNJ!!!!-Vum#:7`PQI(gIp(6l6XM&DRL1!"`*6!!!-+!!&qu%0-D&,T!B[VZE^s!!!#>!>h[8h_D&1#QOj[#]0PQ!+>j=&>]Dg"q\*A"onXe!X8W)h^E1=5h$,F!!&5f+'@t6C^'k>=D%VQ!)F#BU]Uf$!!EK+!2opL!<<,_7i/*)T*M:q!!!#^F;LkVVgPED#QOi)BZL>W?tTIAEs;UE!*3Lg"g8/F!+8oA!,/P@B`N*&"onW+"onY%!J(7O!8h3$VuapBVuZku!;@0DVu`4gVu[/(!!!Eu!!$\g!WW3/5QF&=a+OIYLBq_s8-!&u84Z",#"Sk$!!"tn84W_ViW;Xr"onWFD#cOT5edL_V]ogT5cXni!!&f#"onYI"!95c"5F1e!!%cVD#dsO5gOR\QU,HgBESM>!!EK+!2oo-!!(nC(T7AL"fMG%!!(&8(T7@i&uYg:!!",T!,uT`!!!!pZib!#"U4r,"9ni+Vu[>-!:N]"Vuc&bVuZku!3[4UVubd>Vu[/(!3ZWA!-$s#c2dnFg&hNZ!!k+U!/Chs!"]-=!"]8;!!!-+!!!"JVuZn]+r@0YV[!3NVuZnm-Pr]^cNC*HJH5`NpEpcU!P\Z6!<<*"T.1YU!O$LA!=/Z*"9ni+!$dj3E;+6a!6>G5!>,;3QiSJ!?C1c68jo$IQiWQT;9*dG!QPX;QiWQTO9#=]!4RX_"crbP!K[<^!!)bD!>ggursXti#QOi95`Z*\!"9\Ea9#&U!Z2bZ(sbSUFc[':$BkMq!!!!J1)L,u!!&qu%0-CC.2So`k67db!!!#nI2Ag_T/ihN#QOk3!qcQo!5npA!+=R_"onW''EA+9"onY%!<<*"YC.4c!KRD_!<<*"Y@JHJ!Tt8t!=/Z*TE]$/Du`ZPE!-@F!2oo-!!(n=(T7At"fMG%!!&oD(T7A4@&O)3!!'S2DZBb?"onW'I]*8IpI?$u!M9Uq!<<*"^K)/L!UhP;!=/Z*LBDAnW!ZotcZNVDB)lTF:XTAZ,R+5K!#Yb:])i0:!3ZWA!,1s)"onY,#AF0OdKBaS!9[^+!&+C]!&3C:"onW')#sYq"<7CQU&bGu!!EK+!!%JH!<B#9(T7AL!N6#!!!&p@(T7A$?`3u2!!*$%B`OM,J,pZ-^Hs&U!/LZ+!@IjI49bcc"9ni+Vu[>-!5BWmVuc&bVuZku!7)l+VuaXXVu[/(!8@Ua!<<,g#&O?j!It29`s7+q!!3.N!F#a.!!$[d!!#gS"u,oT"onW+"onY%!=]#/mgL#2!T*sW!<<*"mg'`.!QR$q!=/Z*k6@FW!(]XGk6FP5#]0Q<!+>k(:dC'G:]pt&!!EK+!!%JH!<D:V(T7@i"fMHQ!<<,_9GaW.LBXUW!!!"k9c'`/f1MtB#QOii'o2pI#U!a[=9*#*!!EK+!9+%a!!!-+!!!"JVuZmb$Q#`BNs2H_!!!#nE#5GRLCC*^#QOj[")S&5$s5cMKE51_2c)12"onX*&HDe2$t'(A"_D*AJH;2E"onYW!sS`*"9ni+!.LjI!2!=/Vu_YWVuZku!68LaVuc(7!N6#)!!)HiB`R?,M?a=c!5AYR!)NY(=9)G<:f'tRO(2!/'i7^,:PoBRHNjHM!!!/>Mub1.!!!uC!!!];!!&B&4,=9S"9\o/!!EK+!!%Hb!4N.K(r$(g!!!#^"W&#:"W.LF!<34>!!p%IB`PpL#U]TP"9ni+!#,D5!!"aMPl^5="onYa6O!Mjgd;8G!!#g5.1i:0"onYM!G;D2!UMcM!!&Ym(!lu;!LNm&huSW7ciJ9F!LNoG!Hj2!TE.l%!71`pB)pQb6j<VkY6RJB!LNm@;U>Hk!RLj[!13eS!>Wr^L]Pj'6I5b+!A@?t!RLko!G;D*!BLDb!!m3;huUn"B)q,r!,1!c!13d%huSW7TE,ek!Jgd7!CGuNhuPK/huVa:huOSN!JgaZ"onW'B[?b[ciFm.!It3L!DUoAciGU#!!'q<"9<--!X8W)`&e/'!.Y)_!-iH=E.@u54<+?O!Rs(5!!*$%B`NBsF^U"+Ub2iO!,u%RYQ:s/6?o^802f"TYQ:s/B)lV@2[06^+D1\Y!GH*G\,if7&HDg8!HinnBP;OE!GG[A!!$[fN&kqU!X8W)mpBc/&/k`Q!&%6+!>(%fF^T_#&9'96"9ni+Y6Rs]!>#fc&;U@>!X8W)"9ni+!.KG#!2"rG(OuV^!It7P!!)a=(OuVF!It7X!!&nt;K1P!QNffrE3BL7E,]2M^B&SO"&aAg^B$]HG^'aDY6P%0!.Y(M!s",X,R+5K!#Yb:?pN$?BOF*/#B6F="onYl").as!T+&p!13ej#AF12!<?/^!SfM^(+J_d\/7JD!.Y)XB)m_gO9#Ue!!"p-!K8N/!s!!7!s!;$!GMOY6O!Mj0P:B!?tTIYGR+9LBI*WY9*P@r=D%Va!It2:!!(%CB`NYbk65Q"L]XabB`O4rX<RoL!7(a]!8mnH").c!!Nu`B!:U$P"_du3!QP@X!.Y-;#&+'n!gF,u!!&>jB`PXDpB,+0^]F01B`Q3T[g$OHciJe7"onYl!uJ0B[g&H0B`PXDpB,+0^]F01B`Q3TT*B!0ciKI<B`QcdNs04thuW`g"onXq#&+),!I.Uh!-hXs!<C%I"onYt!GMPD!VZ\1!5JW%#AF1Z!M9R1!71b%"_dth!KRCu!8mnM,6e,J"9ni+J--5\!9YOBJ-3OfJ-,cO!9YOBJ-2tZJ-,cO!1t_WJ-2ugJ--&W!!EK+!!"7j!dF\ifE-#Q?>0Dt!oO*V!<<*",N&WBs(?$GkQ9ZD&HDgGB5%A0!mh!>+92BdfE*bY?>0Dt!oF,p!9aLR!XJc+fE+Sd!8%>rciVPq$lf8o!gcPo!71cI:CPSOk6Yi&ciVPq;3,/4!gaWiciVPqa8ueN!07s#a9']ia8u>A!;D3K(WZZe0usD%!!&&`B`R&lLBVAlkQ,p.Dub,cGQ@17(O5*H`s$/WJ,tu@gAq;1!TX:d!!!-+!!!"JJ-,f?%2XNscNet&!!!$!.MmU;V^?or#QOl!").c)%A*l>!6>2M#&+(a!NZA-!!!-+!!!"JJ-,fG7i-[XpB,pJ%0-D&7i-[XrrIWP!!!"s?l+=qmjinj#QOjk#5J9"O:9/5B`NYak65Q"L]Q!D"onYd"_du3!QP@X!.Y-;#&+'n!k\gD!!!99O9#=]EWC?7!A<mK!43dO!!!-+!!%NO%0-D.Fr,Z2^B]8k!!!"kDARg*Vg!Xn#QOkn"*[:4GZdiCmfOA&Y6XLuB`M8]").aC^B&$KBYOdd!-",'"onY<#AF1"!P\YL!13f5").b.!Ug,)!2op_%0ce4"9ni+J--5\!5B$\J-5fPJ-,cO!1.U?J-5OVJ--&W!;?MJ!<C1AY6SbAciNS;B`QcdcN@k]huURnB`R>t^B\HQn,\j[B`Ro/llZK4!-hLG!-hXS!:L"+@*\q6$O-S2mfR8(L]XabB`O4r^B&$KQibS9B`Oe-GZC[C!-hYN!<CgY"onW+"onW'IXhM#k=c\B"8;hH!rr<$[osSu"4p.q!sel,^B\HQQiZ@RB`NCu"_dse!L+0#!!!-+!!%NO%0-B`$l=ErrrIWP!!!#FCDVL'^Fas<#QOjc"\\pS!LF%*!9aHU#&+),!Q,$E!!!-+!!%NOJH5`Na'fd7"1JJb!rr<$^GZmY"32++!sel,f.dHm#%4>S"__<<('SAZKF.n`!!EK+!.Y0&!<<,_#T&!n^B/of!!!#V.MmU;^D_V)#QOkn!uI%*QNs,eB`O4qLBVAlQiW6OB`Oe,PT'f,!5AbQ!0@5:"_dt(!KRCu!2'AB)?p0A"9ni+!.KG#!8g$XJ-2,@J-,cO!1.(0J-4sPJ--&W!/C_l!3c[:#&+(A!M9U2!4W((").bN!K.*c!!!-+!!%NO%0-Cc7MgRWrrE+KJ-,f/7MgRWcNet&!!!#&*uBG0pK2qJ#QOl!"$Q^h&,-*=!6>25#&+(a!LF%*!8%>C#R18/"9ni+!.KG#!8hi6J-4s;J-,cO!;@ZRJ-1jOJ--&W!5AbQ!"aBTQiR23=eGcqmfOB!!KRD>"_dt8!M9R1!3cKj#AF1J!VZ\1!5JX0!GMPT!Oi8I!71b:#mLA0GZ@97:bL-%!*Cl$#QS6bYm:=0!s!$,%gE"6"9ni+J--5\!7uf'(OuUs"FpRS!!)1V(OuVVJ,t0&#QOkn"5!X)!QPB,"_dsm!P\kR!0@5J#&+()!K7<h!!!-+!!!"JJ-,e<+W#Y2k6-;;!!!#60c,?BkA5YN#QOk>#AF1J&&/-Z!13i6").b.!q-5*!2ot&#AF1B!dI_T!<@@I^]=H(!uJ`RpB1-jB`Q3T[g$OHciJe1"onW+"onXR!t>51f7sACJ-5fPJ-,cO!2!sAJ-2u*J--&W!656M!.Y,q<JUYUGZg+/!7VPa!!!-+!!%NO%0-B`3Z!;K^B/of!!!"s-l7C9T,rLb#QOi-"onW',L?M%!<=@s!`75FkQ(Y`!$g+t0V<i/!8mqQ1MHjQ!r"Kb!:U'B!_=F6ciSC;!n[PS,M3'*a*;:uhu_O4&HDgX!aa4TfE*$4!71cI,L?K_!$g+t:s]7U!!!!p*7+`e,L?L2s+18c!8%A"!YGD4ciR(:.F8-_C.-DMciO2ra8uA!>Qr1MciV8i!!!#.IM^',NuQ.A#QOk6#&+'n%>P+$!8%=5"_dtp!LF%*!9aHP#R18/^B&$KBWhYT!-%B/B`NCu"_dse!R(`P!!!-+!!!"JJ-,eT.MmU;-\):!!!%e"(OuUs+b0Y#!!%cXB`P@A^B\HQn,\j[B`Ro/g'.`]!3ZWA!3cLu!GMPD!VZ\1!5JW-#AF1Z!TO7d!!!-+!!%NOJH5`NT2lbY"1JJb!rr<$kD''SJ-4th!It7X!!&'F"eYm(LHcSgNr^qI!-%!-"onXq#AF1j!I.UP!-hX[!:L"+BU8qh$jH\3"9ni+J--5\!5D/CJ-5fPJ-,cO!/E?HJ-4\1J--&W!;?R0!5JX0!GMPT!I.U@!-hXK!:L"+=MFn'$jH\3T*B!0ciJn*B`QcdNs04thuS(&BE39[Duf>/(N@+oQNh.(GfKu%!.Y+5"_dsm!Nu`B!0@6M").b&!RCj^!2'A-!GMP4!Oi8I!3cKr#AF1J!K.<i!!&VrB`QcdcN@k]huURnB`R>tY6SbAn,\1H"onW+"onXR"+^IQ!;CaTJ-37`J-,cO!1tVTJ-4siJ--&W!-hZ9!<DQj(UsM?!VZ\1!5JWJ$jH\3"9ni+J--5\!09tnJ-5fPJ-,cO!09_gJ-1j1J--&W!7(bZ!<Abn^B&$KVua(,B`P@<mfR8(\,iB8"onXq#AF1:!Oi8I!3cLu!GMPD!VZ\1!5JW%#AF1Z!J:IY!!)Hi(RP5Y"cih$!2'@Z#AF1:!M9R1!3cKo%L)n5"9ni+J--5\!2j6AJ-3OkJ-,cO!2kJN(OuUC@XnOd!!'2Nl2bR+a$^)E@-<(A"__;=&-`+7k65Q"L]P6qB`O4qQNh.(QiVj@"onYl").ak!Nu`B!0@5r!GMP$!RCj^!2'Aa!<rN("9ni+!.KG#!3^,RJ-37`J-,cO!8eS/J-38cJ--&W!4N/H!/LdP!GMPL!VZ\1!6>1c<DW\,%0ce4"9ni+J--5\!7uN5J-5fPJ-,cO!8e/#J-1Q9J--&W!07;T!<AbnLBVAlVu`LpB`P@<Z3LR6!!EK+!.Y.\!!'bi(OuVf!It7P!!(nL(OuUKBn-9k!!'b=dfBH1!ga+*!13h4<M0?mS-]B"!!EK+!!%Iu!s%dF(OuU#J-,cO!9ZT`J-4DZ!It7X!!(%CB`PpSk65Q"L]Y<rB`O4rN!fgi!/C_l!2'@R"_dt8!M9U2!3cLi!X8W)"9ni+!.KG#!07[-J-37cJ--5\!07[-J-5fPJ-,cO!:P(IJ-56YJ--&W!:L#u!<C1C`s$/WJ-+m;B`NqjUB1W"!!EK+!.Y.\!!(V2(OuV&#ClmV!!(Uk(OuU[6@].D!!&?S2eZ<SJ,oge@*`$\BOLQ_"__;).0XBm`sW&a@/h&IBOK9m"onW+"onXR!t>51pOrVaJ-5fP!.KG#!;D0J(OuTpJ-,cO!8h6%J-4,-J--&W!1sL1!5JYs"_dtp!J^hm!9aHU#&+),!LF%*!;HT$!sS`*T*B!0O9([QB`OM$Ns04tTE0fOB`P(4[g$OHYQ:@$B`PXDK*qk`!3\e-!''EkD#chG=\&O;=\o+e!uFf&"0VrD!*Hu:B`MPe").aKQNh.(E5)Wl!-mZ1B`NYa`s$/WL]NhIB`O4qT*B!0QiWBR"onYl!uI%"T*CVeB`OM$Ns04tTE0WX"onXBB)mG_E+]0,!H;ZOO9(dZ"onW'!s!RZB)mG_!,-<OE+]/q9*P@r&5h=b&--;B(a!Sp+<Wr<E?H??!%96\Y@AuQ6YufWUB1W"!:L#(!13i6").b.!l"bM!2osD<NlK(_[?YK!!EK+!!"7j!g!H?"DIkg!iJ:t!8mnYB[?e\V[l2B!mh"q!`AuCciVfJ7*l"^!W[\j!W_sA"ipbl!ltEC!!&XG!>ifYY9:mf#QOkN").aCmfR8(BWhYT!-%*)B`P(<`s$/WJ,tu@B`NqiiXuFq!,uQNL]MI-!0@3]BRg*`X:6-LJ-!Rk"onW+"onW'IXhM#QPLBf".oXF!rr<$T61s#"4)@F!sel,T*K'1i!m."B`QK\LBVAlfE(7K"onXi#&+)$!P\kR!:U$P"_du3!QP@X!.Y.1%gE"6T*B!0n,\j\B`Ro/GZB7p!-hY&!<@ui"onXJ=f;?$mfOB)!M9V+#&+(A!P/O@!!&>jB`P(4T*B!0YQ=J!B`PXDapSCR!1sL1!2oq-#&+(A!VZV/!4W((").bN!Ug,)!6>2E#AF1b!P\YL!8%=u").bn!LF")!9aHu#AF2-!TsW#!;HTl('Xa="9ni+!.KG#!<4;\J-4+&J-,cO!4OEoJ-3PSJ--&W!;?S0!2'Pj!GMPT!Oi8I!71a'"onYt!GMPD!VZ\1!5JW-#AF1Z!Oi8I!71b]!GMPd!W!!)!!&VrB`QcdNs04thuST:B`R>tlN.7j!1*n(!13i6").b.!l"bM!2ot&#AF1B!q-5*!4W)T<PSV8aqY*\!657W!.Y.6"_dsm!dI_,!<@@IQiR3Y%gE"6"9ni+J--5\!9Y+6J-4s<J-,cO!2!I3J-2E7J--&W!431S!!!!JKF351"9ni+J--5\!7s+FJ-4s<J-,cO!2gkSJ-2D[J--&W!0d_W!<<*&"onW'IXhM#rtH9""2=ke!t>51rtH9""9/CP!rr<$[nRZh"2>Y&!sel,Vc7j?^]V1S"onXR!G;CWE'&#h!O;bH!.Y(Q"onXR!t>51s'Z^o"6Ti<!rr<$pNm^,"92k]!sel,g]pdY!!EK+!!"7j!ata*B`QceciOdZ!71cXciV62!$g+tE5.&,B`R&mfE)Wb!8%?\ciVPq$lf8o!fq,2!71cI:E7^_!$fhlE6iB8!8%A"!YGD4ciR(Z:s]:,:INP2ciV8i!!!"s?3SCOciV8i!!!#fLB/44!k2CT!XJc+YQ5KK!Jgcd!CF9sO9([Q;SW=;!Nu_r^]D4OQin/>!FWD<6GNW3!A@?\!Or.u"onW+"onXR!rr<$h`)F&".oXF!rr<$LDgtZ"4oM_!sel,TFZ1$!K[>8!sS`*"9ni+J--5\!1/E@(OuV&"b6[T!!)2+(OuV>7XtRH!!'M0^&\4q!K[<s\,hBdYQ5K[!Jgcd!Hj2!YQ:3o"onW+"onXR!t>51Q['Bt"5a01!rr<$k8kFi"5e-L!sel,f4s^S!,,bQ!,uT`!!!-+!!)'eASC62KF.n`!!EK+!.Y0&!<<,77MgRWpAodH!!!"kEu0?/s&jjS#QOjD?cW;1!Jgb\L]NS<J,shD!Jgb]"onW+"onXR!t>51O+[NMJ-3OiJ-,cO!4PB5J-1jLJ--&W!.Y*Q!<@@p!CCaEE*.(8!Jgb8E/4Oq!<rN(J,s9_G]4%0J-#NN)utKig]7TZ!!EK+!!%Iu!s$q+(OuUS!e:@Q!!(%U(OuUk3.M):!!)<g"9?LKoEb^%!!EK+!.Y.\!!&?5(OuU[!e:@Q!!&XC!>g7gpEb=l#QOi)cN+"Gap&gcGesOe!!%$B!3cL(!X8W)"9ni+J--5\!1u[rJ-3gpJ-,cO!1sl?J-4D2J--&W!!!DM!e:=4"9ni+"9ni+J-1?'!!(>d(OuThJ-,cO!5DAIJ-4sKJ--&W!,u8[%WImC"onXd!sAUc!K7-c!!!-+!!%NOJH5`NQVeQL"':!T%0-Bp;&=`bT1XV9!!!"s65P.She.HA#QOjD,H(ofZ2t41!,+ug$BP;:!X8W)"9ni+J--5\!1so@J-2\NJ-1?'!!&W)(OuThJ-,cO!4Oj&J-3hQJ--&W!-"A-O9]a#!sS`*!#Yb:mfR8(O9+ePB`OM$hZ[]oTE25$B`P(4!*5HfMZa.e!!%NO!!!#.-Pq:8Y6TR[!!!#N72LIVa#SYP#QOjT%qbm(!Nu`B!13eR#&+(1!?_r0!<<*i?i[A8B`MfL"onW+"onW'IXhM#O!kfp"8;hH!rr<$pG<\:"1KV-!sel,QNh.(a9AaPB`NAX<bRp'+B`(PJ,q<:!%;I[L]Ps*"onW+"onXR!t>51^H*0]".oXF!rr<$f,GNV"5dU=!sel,!(m4kVu^N2YQ4`PYQ4`CB)mG_Rfrur!94+b!!!-+!!%NO!!!#>JH6R;"8;hH!rr<$[kAPJ",ALZ!sel,^^"KPJ-#6H"onXR!G;CWE+]0$!H;ZOL]MI-!0@5#B)n;"6j<VkE(p!/O9(^L>]BE?J,q&@!-!("E,ZPB!H<PiF`;::B)l=-"onXBB)nS*QiRd!!,uQNTE,<0TE,%C!@n-ME+]0$!H:bh!H<Yl"onX6)usC,$3gJ1"9ni+J--5\!/EiVJ-3OiJ-,cO!8eD*J-4+YJ--&W!'%1`!,u=Y!-iGp!!%6L!!$snU'>jEB)lUY5l^lf"onXR!t>51mkGW/"9/CP!rr<$O(9&W"-4dZ!sel,Y6UU!!5JU8<j2VZ#Qt>3!.Y.\!!)b"(OuVf!It7P!!&p3(OuUs6\#7E!!)`r\cDf0!P\kR!3cJ08H?7$P5tjf!!!l:!:L#(!13fU").b.!HSGF!8%ccfG8uGQj?:Q$,@5D)dTBNTH3512Y[ZI&-N1;!.Y.\!!&?@(OuVF!e:@Q!!(%^(OuV>8:UdJ!!&?;70"/A5hBfh+)M!#+@*[R+E(ro.,Q4_!&2n'"onW+"onW',L?LB!<=@s!\gMiB`R&mmf@,&kQ:5T#QOkW!_=F6!$gD'0UG"<!9aLA"DIl*!q-/(!;HWR!_=F6!,0^\!:NoUciVPqciR("--u_&@RSQEciV8i!!!#6CB_c\ciV8i!!!#60Ghe3QS->\#QOi)=o\O&A,ln%/StJ!W!Yen#nX]M"onW+"onXR"+^IQ!5C`7J-2,BJ-,cO!:M$HJ-4,IJ--&W!!$]b!<@n'6m*ToD#bt45edmZk6#Du0[CDH!&ssl-ia6\(]Y*Z!!&'"6kBn@:(Y0W"9ni+"9ni+!.KG#!7qJmJ-3OeJ-,cO!7,HtJ-3OmJ--&W!#cgWp]AkG"onW'!A+N/Muh-'"onYA!<rN(]E&3:!8ne7W#b(8"9ni+-k-.VNs-=JLBK"*!!'b=(FY%B-jTeQ&.AO=!#,D5!,)oD&6BFp!p:D7!$DCK!!!-+!!"Eu!<<,G#8\f'!@RpJ!5ARO.+\PL#QOi)BFk.T=3(H8GmJ--[[
================================================================================
  POTATOOLS  |  Studio Test Suite
  A single-file, dependency-free Luau script for Roblox Studio testing.
  - Draggable, clean main hub with a scrollable + searchable game list.
  - Clicking a game opens its OWN separate draggable feature window.
  - Real, functional systems: ESP (Highlight + Billboard), Aimbot, Triggerbot,
    Hitbox Expander, Fly, Noclip, WalkSpeed, JumpPower, Infinite Jump, Teleport,
    FOV circle, notifications, keybinds and more.
  - No loadstring / no web require. Everything is pcall-guarded so it cannot
    fail to load.
  HOW TO USE: Place inside a LocalScript in StarterPlayer > StarterPlayerScripts,
  StarterGui, or run it from your executor while testing your own copies.
================================================================================
]]

--==============================================================================
--// GETGENV SHIM  (eve's fix: globals instead of locals to beat Luau's
--   200-local-per-function limit so this loads cleanly via loadstring).
--   In executors getgenv() returns the shared environment; in Studio we map it
--   to _G so bare global lookups resolve everywhere. Combined with converting
--   top-level `local X` -> `X` (globals), the chunk stays well under 200 locals.
--==============================================================================
getgenv = getgenv or function() return _G end
local _P = getgenv()          -- single local; everything else is global below
_P.Potatools = _P.Potatools or {}

--==============================================================================
--// BOOT GUARD  (loadstring-safe: ensure the game is fully loaded first)
--   This makes the script safe to run via:  loadstring(source)()
--   It also dedupes if re-executed and recovers from any load error.
--==============================================================================
if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

-- Clean up any previous run so re-executing never duplicates the UI.
pcall(function()
    local _plr = game:GetService("Players").LocalPlayer
    for _, parent in ipairs({ game:GetService("CoreGui"), _plr:FindFirstChildOfClass("PlayerGui") }) do
        if parent then
            local old = parent:FindFirstChild("MultiGameHub_Root")
            if old then old:Destroy() end
        end
    end
end)

--==============================================================================
--// SERVICES
--==============================================================================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local VirtualUser        = game:GetService("VirtualUser")
local CollectionService  = game:GetService("CollectionService")
local HttpService        = game:GetService("HttpService")
local Stats              = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- Forward declarations so closures bind to the correct locals.
local ScreenGui
local disableAllFeatures
local isFriend
local isTarget
local FriendList
local TeleportPro
local getPlayerNames
local findPlayerByName
local addMovement
local randPos
local GameList

--==============================================================================
--// COMPATIBILITY SHIMS  (so the script also runs in plain Roblox Studio,
--   where executor-only globals like firetouchinterest / setclipboard don't exist)
--==============================================================================
if not firetouchinterest then
    -- Best-effort vanilla fallback: briefly overlap the two parts to fire .Touched.
    firetouchinterest = function(partA, partB, toggle)
        pcall(function()
            if toggle == 0 and partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
                local oldCF = partA.CFrame
                partA.CFrame = partB.CFrame
                task.wait()
                partA.CFrame = oldCF
            end
        end)
    end
end
if not setclipboard then
    setclipboard = function(txt) print("[Clipboard]", tostring(txt)) end
end

--==============================================================================
--// SAFE GUI PARENT  (avoid "cannot parent" / level errors)
--==============================================================================
local function getGuiParent()
    local ok, core = pcall(function()
        if CoreGui and CoreGui.Name == "CoreGui" then return CoreGui end
    end)
    if ok and core then return core end
    -- Studio / safe fallback
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then
        pg = Instance.new("PlayerGui")
        pg.Parent = LocalPlayer
    end
    return pg
end

-- Remove any previous instance so re-running the script never duplicates UI.
pcall(function()
    local old = getGuiParent():FindFirstChild("MultiGameHub_Root")
    if old then old:Destroy() end
end)

--==============================================================================
--// THEME  (clean, modern dark UI inspired by common script hubs)
--==============================================================================
local Theme = {
    Background      = Color3.fromRGB(22, 22, 28),
    BackgroundDark  = Color3.fromRGB(16, 16, 20),
    Sidebar         = Color3.fromRGB(26, 26, 34),
    Element         = Color3.fromRGB(34, 34, 44),
    ElementHover    = Color3.fromRGB(44, 44, 56),
    Text            = Color3.fromRGB(236, 236, 242),
    TextDim         = Color3.fromRGB(150, 150, 162),
    -- Potatools branding: bright light red -> black gradient
    Accent          = Color3.fromRGB(255, 60, 60),
    AccentBright    = Color3.fromRGB(255, 140, 140),
    AccentDark      = Color3.fromRGB(0, 0, 0),
    Green           = Color3.fromRGB(76, 209, 142),
    Red             = Color3.fromRGB(235, 77, 92),
    Yellow          = Color3.fromRGB(245, 196, 76),
    Blue            = Color3.fromRGB(86, 156, 240),
    Stroke          = Color3.fromRGB(55, 55, 70),
    Rounded         = UDim.new(0, 8),
    RoundedBig      = UDim.new(0, 14),
    Font            = Enum.Font.Gotham,
    FontBold        = Enum.Font.GothamBold,
    FontMono        = Enum.Font.Code,
}

--==============================================================================
--// SMALL UI HELPERS
--==============================================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function gradient(parent, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

local function listLayout(parent, paddingY, horizontalAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, paddingY or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = horizontalAlign or Enum.HorizontalAlignment.Center
    l.Parent = parent
    return l
end

-- safely tween a property
local function tween(instance, time, props)
    local t = TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

--==============================================================================
--// NOTIFICATIONS  (in-GUI toast + Roblox core notification)
--==============================================================================
local NotifyHolder
local function buildNotifyHolder(parent)
    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Size = UDim2.new(0, 320, 1, -40)
    NotifyHolder.Position = UDim2.new(1, -336, 0, 20)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = parent
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.Parent = NotifyHolder
    return NotifyHolder
end

local function notify(title, text, duration, color)
    duration = duration or 3.5
    color = color or Theme.Accent
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
        })
    end)
    if not NotifyHolder then return end
    local card = Instance.new("Frame")
    card.Name = "Notify"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.BackgroundDark
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.Parent = NotifyHolder
    corner(card, Theme.Rounded)
    stroke(card, color, 0, 0)
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card
    corner(accentBar, UDim.new(0, 2))
    local tb = Instance.new("TextLabel")
    tb.BackgroundTransparency = 1
    tb.Position = UDim2.new(0, 14, 0, 8)
    tb.Size = UDim2.new(1, -22, 0, 16)
    tb.Font = Theme.FontBold
    tb.TextSize = 13
    tb.TextColor3 = Theme.Text
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Text = tostring(title)
    tb.Parent = card
    local tx = Instance.new("TextLabel")
    tx.BackgroundTransparency = 1
    tx.Position = UDim2.new(0, 14, 0, 26)
    tx.Size = UDim2.new(1, -22, 0, 14)
    tx.AutomaticSize = Enum.AutomaticSize.Y
    tx.Font = Theme.Font
    tx.TextSize = 12
    tx.TextColor3 = Theme.TextDim
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.TextWrapped = true
    tx.Text = tostring(text)
    tx.Parent = card
    local inT = tween(card, 0.25, { BackgroundTransparency = 0.05 })
    task.delay(duration, function()
        local out = tween(card, 0.3, { BackgroundTransparency = 1 })
        tween(tb, 0.3, { TextTransparency = 1 })
        tween(tx, 0.3, { TextTransparency = 1 })
        tween(accentBar, 0.3, { BackgroundTransparency = 1 })
        out.Completed:Wait()
        card:Destroy()
    end)
end

--==============================================================================
--// CHARACTER / ROOT HELPERS
--==============================================================================
local function getChar()
    return LocalPlayer.Character
end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP(char)
    char = char or getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end
local function isAlive(plr)
    if not plr then plr = LocalPlayer end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c ~= nil and h ~= nil and h.Health > 0
end

--==============================================================================
--// DRAGGING UTILITY  (works on PC + mobile)
--==============================================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragInput, mousePos, framePos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, math.clamp(framePos.X.Offset + delta.X, -frame.AbsoluteSize.X + 60, Workspace.CurrentCamera.ViewportSize.X - 60),
                framePos.Y.Scale, math.clamp(framePos.Y.Offset + delta.Y, 0, Workspace.CurrentCamera.ViewportSize.Y - 40)
            )
        end
    end)
end

--==============================================================================
--// Z-INDEX / WINDOW STACK MANAGEMENT
--==============================================================================
local TopZ = 10
local function bringToFront(frame)
    TopZ = TopZ + 1
    frame.ZIndex = TopZ
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("GuiObject") then
            d.ZIndex = TopZ + (d.ZIndex - 10)
        end
    end
end

--==============================================================================
--// CORE UI LIBRARY  (window + elements)
--==============================================================================
local OpenWindows = {}

local function createWindow(title, subtitle, sizeX, sizeY, pos)
    local self = {}
    self._destroyed = false
    self._elements = {}
    self._keybinds = {}

    local root = Instance.new("Frame")
    root.Name = "Window_" .. tostring(title)
    root.Size = UDim2.new(0, sizeX or 470, 0, sizeY or 460)
    root.Position = pos or UDim2.new(0.5, -(sizeX or 470)/2, 0.5, -(sizeY or 460)/2)
    root.BackgroundColor3 = Theme.Background
    root.BorderSizePixel = 0
    root.ZIndex = 10
    root.Parent = ScreenGui
    corner(root, Theme.RoundedBig)
    stroke(root, Theme.Stroke, 1, 0.2)

    -- shadow-ish top accent
    local accentLine = Instance.new("Frame")
    accentLine.Name = "Accent"
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 11
    accentLine.Parent = root
    gradient(accentLine, Theme.AccentBright, Theme.AccentDark, 0)
    local aCorner1 = Instance.new("UICorner"); aCorner1.CornerRadius = Theme.RoundedBig; aCorner1.Parent = accentLine

    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    corner(header, Theme.RoundedBig)
    local hFill = Instance.new("Frame"); hFill.Size = UDim2.new(1,0,0,22); hFill.BackgroundColor3 = Theme.Sidebar; hFill.BorderSizePixel = 0; hFill.ZIndex = 11; hFill.Position = UDim2.new(0,0,0,22); hFill.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 16, 0, 6)
    titleLbl.Size = UDim2.new(1, -120, 0, 20)
    titleLbl.Font = Theme.FontBold
    titleLbl.TextSize = 15
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title or "Window"
    titleLbl.ZIndex = 12
    titleLbl.Parent = header

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 16, 0, 25)
    subLbl.Size = UDim2.new(1, -120, 0, 14)
    subLbl.Font = Theme.Font
    subLbl.TextSize = 11
    subLbl.TextColor3 = Theme.TextDim
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = subtitle or "Feature window"
    subLbl.ZIndex = 12
    subLbl.Parent = header

    -- window control buttons
    local function makeCtrl(text, color, offsetX, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(1, offsetX, 0.5, -13)
        btn.BackgroundColor3 = Theme.Element
        btn.Text = text
        btn.Font = Theme.FontBold
        btn.TextSize = 14
        btn.TextColor3 = color or Theme.Text
        btn.AutoButtonColor = true
        btn.BorderSizePixel = 0
        btn.ZIndex = 12
        btn.Parent = header
        corner(btn, UDim.new(0, 6))
        btn.MouseButton1Click:Connect(function()
            tween(btn, 0.1, { BackgroundColor3 = Theme.ElementHover })
            task.wait(0.1)
            tween(btn, 0.1, { BackgroundColor3 = Theme.Element })
            onClick()
        end\n    end\nend\n\nreturn M\n
