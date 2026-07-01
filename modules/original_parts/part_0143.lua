oreGui end
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
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.corner then
        return _G.PotatoolsHelpers.corner(parent, r)
    end
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.stroke then
        return _G.PotatoolsHelpers.stroke(parent, color, thickness, transparency)
    end
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.padding then
        return _G.PotatoolsHelpers.padding(parent, top, bottom, left, right)
    end
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function gradient(parent, color1, color2, rot)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.gradient then
        return _G.PotatoolsHelpers.gradient(parent, color1, color2, rot)
    end
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
        end)
        return btn
    end

    local minimized = false
    local fullSize = root.Size
    makeCtrl("â€“", Theme.Yellow, -64, function()
        minimized = not minimized
        if minimized then
            fullSize = root.Size
            tween(root, 0.2, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 44) })
        else
            tween(root, 0.2, { Size = fullSize })
        end
    end)
    makeCtrl("âœ•", Theme.Red, -32, function()
        self:Destroy()
    end)

    -- CONTENT (scrolling)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Position = UDim2.new(0, 0, 0, 47)
    content.Size = UDim2.new(1, 0, 1, -47)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ZIndex = 11
    content.Parent = root
    padding(content, 8, 8, 10, 10)
    listLayout(content, 7, Enum.HorizontalAlignment.Center)

    makeDraggable(root, header)
    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bringToFront(root)
        end
    end)

    ---------------- ELEMENT BUILDERS ----------------

    local function addHolder(height)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, height or 40)
        f.BackgroundColor3 = Theme.Element
        f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        f.ZIndex = 11
        f.Parent = content
        corner(f, Theme.Rounded)
        return f
    end

    function self:AddLabel(text)
        local f = addHolder(24)
        f.BackgroundTransparency = 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, 0, 1, 0)
        l.Font = Theme.FontBold
        l.TextSize = 12
        l.TextColor3 = Theme.AccentBright
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        l.ZIndex = 12
        l.Parent = f
        padding(f, 4, 0, 4, 4)
        table.insert(self._elements, f)
        return f
    end

    function self:AddSection(text)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, 26)
        wrap.BackgroundTransparency = 1
        wrap.ZIndex = 11
        wrap.Parent = content
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 2, 0, 0)
        l.Size = UDim2.new(1, -4, 1, 0)
        l.Font = Theme.FontBold
        l.TextSize = 12
        l.TextColor3 = Theme.TextDim
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "  " .. (string.upper(text or "SECTION"))
        l.ZIndex = 12
        l.Parent = wrap
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, 0, 0, 1)
        div.Position = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3 = Theme.Stroke
        div.BorderSizePixel = 0
        div.ZIndex = 12
        div.Parent = wrap
        table.insert(self._elements, wrap)
        return wrap
    end

    function self:AddToggle(text, default, callback, description)
        local f = addHolder(description and 56 or 40)
        padding(f, 0, 0, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 0, 0, description and 8 or 9)
        lbl.Size = UDim2.new(1, -60, 0, 16)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 13
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local desc
        if description then
            desc = Instance.new("TextLabel")
            desc.BackgroundTransparency = 1
            desc.Position = UDim2.new(0, 0, 0, 28)
            desc.Size = UDim2.new(1, -60, 0, 14)
            desc.Font = Theme.Font
            desc.TextSize = 11
            desc.TextColor3 = Theme.TextDim
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Text = description
            desc.ZIndex = 12
            desc.Parent = f
        end

        local state = default and true or false
        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 44, 0, 22)
        switch.Position = UDim2.new(1, -44, 0.5, -11)
        switch.BackgroundColor3 = state and Theme.Green or Theme.ElementHover
        switch.Text = ""
        switch.AutoButtonColor = false
        switch.BorderSizePixel = 0
        switch.ZIndex = 12
        switch.Parent = f
        corner(switch, UDim.new(1, 0))
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 13
        knob.Parent = switch
        corner(knob, UDim.new(1, 0))

        local obj = { State = state }
        function obj:Set(v, fire)
            state = v and true or false
            tween(switch, 0.15, { BackgroundColor3 = state and Theme.Green or Theme.ElementHover })
            tween(knob, 0.15, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
            if fire ~= false and callback then
                pcall(callback, state)
            end
        end
        function obj:Get() return state end

        switch.MouseButton1Click:Connect(function()
            obj:Set(not state)
        end)
        f.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                obj:Set(not state)
            end
        end)

        if default then obj:Set(true, false) end
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddButton(text, callback, color)
        local f = addHolder(36)
        padding(f, 4, 4, 4, 4)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundColor3 = color or Theme.Accent
        b.Text = text
        b.Font = Theme.FontBold
        b.TextSize = 13
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.AutoButtonColor = true
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = f
        corner(b, Theme.Rounded)
        gradient(b, (color or Theme.AccentBright), (color or Theme.AccentDark), 0)
        local busy = false
        b.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            local orig = b.Text
            tween(b, 0.08, { BackgroundTransparency = 0.2 })
            task.wait(0.08)
            tween(b, 0.08, { BackgroundTransparency = 0 })
            pcall(callback)
            busy = false
        end)
        table.insert(self._elements, f)
        return b
    end

    function self:AddSlider(text, min, max, default, suffix, decimals, callback)
        local f = addHolder(50)
        padding(f, 6, 6, 12, 12)
        local top = Instance.new("Frame")
        top.Size = UDim2.new(1, 0, 0, 16)
        top.BackgroundTransparency = 1
        top.ZIndex = 12
        top.Parent = f
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 13
        lbl.Parent = top
        local val = Instance.new("TextLabel")
        val.BackgroundTransparency = 1
        val.Position = UDim2.new(1, -50, 0, 0)
        val.Size = UDim2.new(0, 50, 1, 0)
        val.Font = Theme.FontBold
        val.TextSize = 12
        val.TextColor3 = Theme.AccentBright
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.ZIndex = 13
        val.Parent = top
        decimals = decimals or 0
        local function fmt(n)
            if decimals > 0 then
                return string.format("%." .. decimals .. "f", n) .. (suffix or "")
            else
                return tostring(math.floor(n)) .. (suffix or "")
            end
        end
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 8)
        track.Position = UDim2.new(0, 0, 0, 30)
        track.BackgroundColor3 = Theme.ElementHover
        track.BorderSizePixel = 0
        track.ZIndex = 12
        track.Parent = f
        corner(track, UDim.new(1, 0))
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 13
        fill.Parent = track
        corner(fill, UDim.new(1, 0))
        gradient(fill, Theme.AccentBright, Theme.AccentDark, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, 0, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 14
        knob.Parent = track
        corner(knob, UDim.new(1, 0))

        local value = math.clamp(default or min, min, max)
        local obj = { Value = value }
        local function update(v, fire)
            v = math.clamp(v, min, max)
            value = v
            obj.Value = v
            local pct = (v - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -7, 0.5, -7)
            val.Text = fmt(v)
            if fire ~= false and callback then pcall(callback, v) end
        end
        function obj:Set(v, fire) update(v, fire) end
        function obj:Get() return value end

        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(min + rel * (max - min), true)
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        update(value, false)
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddDropdown(text, options, default, callback)
        local height = 40
        local f = addHolder(height)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.5, 0, 0, 16)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 22)
        btn.Position = UDim2.new(1, -120, 0, 0)
        btn.BackgroundColor3 = Theme.ElementHover
        btn.Font = Theme.FontBold
        btn.TextSize = 12
        btn.TextColor3 = Theme.Text
        btn.Text = tostring(default or options[1] or "Select")
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.ZIndex = 12
        btn.Parent = f
        corner(btn, UDim.new(0, 6))

        local list = Instance.new("Frame")
        list.Size = UDim2.new(0, 120, 0, 0)
        list.Position = UDim2.new(1, -120, 0, 26)
        list.BackgroundColor3 = Theme.BackgroundDark
        list.BorderSizePixel = 0
        list.Visible = false
        list.ZIndex = 30
        list.Parent = f
        corner(list, UDim.new(0, 6))
        stroke(list, Theme.Stroke, 1, 0)
        local llay = Instance.new("UIListLayout")
        llay.Padding = UDim.new(0, 2)
        llay.SortOrder = Enum.SortOrder.LayoutOrder
        llay.Parent = list
        local lpad = Instance.new("UIPadding"); lpad.PaddingTop = UDim.new(0,4); lpad.PaddingBottom=UDim.new(0,4); lpad.PaddingLeft=UDim.new(0,4); lpad.PaddingRight=UDim.new(0,4); lpad.Parent=list

        local current = default or options[1]
        local obj = { Value = current }
        local function rebuild()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(options) do
                local o = Instance.new("TextButton")
                o.Size = UDim2.new(1, 0, 0, 22)
                o.BackgroundColor3 = Theme.Element
                o.Font = Theme.Font
                o.TextSize = 12
                o.TextColor3 = Theme.Text
                o.Text = tostring(opt)
                o.AutoButtonColor = true
                o.BorderSizePixel = 0
                o.ZIndex = 31
                o.Parent = list
                corner(o, UDim.new(0, 4))
                o.MouseButton1Click:Connect(function()
                    current = opt
                    obj.Value = opt
                    btn.Text = tostring(opt)
                    list.Visible = false
                    list.Size = UDim2.new(0, 120, 0, 0)
                    if callback then pcall(callback, opt) end
                end)
            end
            list.Size = UDim2.new(0, 120, 0, 6 + #options * 24)
        end
        btn.MouseButton1Click:Connect(function()
            list.Visible = not list.Visible
        end)
        rebuild()
        if callback and current then pcall(callback, current) end
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddKeybind(text, defaultKey, callback)
        local f = addHolder(36)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 90, 0, 24)
        b.Position = UDim2.new(1, -90, 0.5, -12)
        b.BackgroundColor3 = Theme.ElementHover
        b.Font = Theme.FontBold
        b.TextSize = 12
        b.TextColor3 = Theme.Text
        b.Text = defaultKey and defaultKey.Name or "[ NONE ]"
        b.AutoButtonColor = false
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = f
        corner(b, UDim.new(0, 6))
        local listening = false
        local current = defaultKey
        b.MouseButton1Click:Connect(function()
            listening = not listening
            b.Text = listening and "[ PRESS KEY ]" or (current and current.Name or "[ NONE ]")
            b.BackgroundColor3 = listening and Theme.Accent or Theme.ElementHover
        end)
        UserInputService.InputBegan:Connect(function(input, gp)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                listening = false
                b.Text = current.Name
                b.BackgroundColor3 = Theme.ElementHover
            elseif current and input.KeyCode == current and not gp then
                if callback then pcall(callback, current) end
            end
        end)
        table.insert(self._elements, f)
        return b
    end

    function self:AddInput(text, default, placeholder, callback)
        local f = addHolder(40)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 150, 0, 24)
        box.Position = UDim2.new(1, -150, 0.5, -12)
        box.BackgroundColor3 = Theme.ElementHover
        box.Font = Theme.Font
        box.TextSize = 12
        box.TextColor3 = Theme.Text
        box.PlaceholderText = placeholder or ""
        box.PlaceholderColor3 = Theme.TextDim
        box.Text = default or ""
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.BorderSizePixel = 0
        box.ZIndex = 12
        box.Parent = f
        corner(box, UDim.new(0, 6))
        box.FocusLost:Connect(function(enter)
            if callback then pcall(callback, box.Text, enter) end
        end)
        table.insert(self._elements, f)
        return box
    end

    function self:AddDivider()
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, 0, 0, 1)
        d.BackgroundColor3 = Theme.Stroke
        d.BorderSizePixel = 0
        d.ZIndex = 11
        d.Parent = content
        table.insert(self._elements, d)
        return d
    end

    function self:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        local t = tween(root, 0.18, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 0), BackgroundTransparency = 1 })
        t.Completed:Wait()
        root:Destroy()
        for k, v in pairs(OpenWindows) do
            if v == self then OpenWindows[k] = nil end
        end
    end

    self.Root = root
    self.Content = content
    bringToFront(root)
    return self
end

--==============================================================================
--// ROOT SCREEN GUI
--==============================================================================
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiGameHub_Root"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()
buildNotifyHolder(ScreenGui)

--==============================================================================
--// ESP SYSTEM  (Highlight + Billboard name/distance/health + optional box)
--==============================================================================
local ESP = {}
ESP.Config = {
    Enabled     = false,
    Players     = true,
    NPCs        = false,
    TeamCheck   = false,
    Names       = true,
    Distance    = true,
    Health      = true,
    Boxes       = false,
    Tracers     = false,
    MaxDistance = 1500,
    TextSize    = 13,
    FillColor   = Color3.fromRGB(122, 92, 255),
    OutlineColor= Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.65,
}
ESP._tracked = {}        -- [model] = { highlight, billboard, label }
ESP._conns = {}

local function espRemove(model)
    local data = ESP._tracked[model]
    if data then
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        ESP._tracked[model] = nil
    end
end

local function espApply(model, isPlayer, plr)
    if not model or not model.Parent then return end
    if ESP._tracked[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not (head and hum and root) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = model
    hl.FillColor = ESP.Config.FillColor
    hl.OutlineColor = ESP.Config.OutlineColor
    hl.FillTransparency = ESP.Config.FillTransparency
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_BB"
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.new(0, 220, 0, 36)
    bb.StudsOffset = Vector3.new(0, 2.4, 0)
    bb.Parent = head

    local lab = Instance.new("TextLabel")
    lab.BackgroundTransparency = 1
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.Font = Theme.FontBold
    lab.TextSize = ESP.Config.TextSize
    lab.TextColor3 = Color3.fromRGB(255, 255, 255)
    lab.TextStrokeTransparency = 0.4
    lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lab.RichText = true
    lab.Parent = bb

    ESP._tracked[model] = { highlight = hl, billboard = bb, label = lab, player = plr, isPlayer = isPlayer, root = root, hum = hum }
end

local function espRefreshVisibility()
    for model, data in pairs(ESP._tracked) do
        local show = ESP.Config.Enabled
        if show and data.isPlayer and ESP.Config.TeamCheck and data.player and LocalPlayer.Team and data.player.Team == LocalPlayer.Team then
            show = false
        end
        data.highlight.Enabled = show
        data.highlight.FillTransparency = show and ESP.Config.FillTransparency or 1
        data.billboard.Enabled = show
    end
end

local function espFullScan()
    -- players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            espApply(plr.Character, true, plr)
        end
    end
end

local function espSetupPlayer(plr)
    if plr == LocalPlayer then return end
    local function onChar(char)
        task.wait(0.2)
        espApply(char, true, plr)
    end
    if plr.Character then onChar(plr.Character) end
    ESP._conns[plr] = plr.CharacterAdded:Connect(onChar)
end

ESP.Enable = function(state)
    ESP.Config.Enabled = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do espSetupPlayer(plr) end
        if not ESP._playerAddedConn then
            ESP._playerAddedConn = Players.PlayerAdded:Connect(function(p) espSetupPlayer(p) end)
            ESP._playerRemovingConn = Players.PlayerRemoving:Connect(function(p)
                if p.Character then espRemove(p.Character) end
                if ESP._conns[p] then ESP._conns[p]:Disconnect() ESP._conns[p] = nil end
            end)
        end
    else
        for model in pairs(ESP._tracked) do
            if model and model.Parent then
                local d = ESP._tracked[model]
                if d then d.highlight.Enabled = false; d.billboard.Enabled = false end
            end
        end
    end
    espRefreshVisibility()
end

ESP.ClearAll = function()
    for model in pairs(ESP._tracked) do espRemove(model) end
    ESP._tracked = {}
end

-- ESP update loop (text, distance, color, team color, box via tracer fallback)
RunService.RenderStepped:Connect(function()
    if not ESP.Config.Enabled then return end
    local myRoot = getRoot()
    for model, data in pairs(ESP._tracked) do
        if not model.Parent then
            espRemove(model)
        else
            local hum = data.hum
            local root = data.root
            if not hum or not hum.Parent or hum.Health <= 0 then
                data.highlight.Enabled = false
                data.billboard.Enabled = false
            else
                local teamHide = data.isPlayer and ESP.Config.TeamCheck and data.player and LocalPlayer.Team and data.player.Team == LocalPlayer.Team
                data.highlight.Enabled = not teamHide
                data.billboard.Enabled = not teamHide
                -- color by team / role
                local baseColor = ESP.Config.FillColor
                if data.isPlayer and data.player and data.player.Team and data.player.Team.TeamColor then
                    baseColor = data.player.Team.TeamColor.Color
                end
                -- Friends recolor green, Targets recolor red (vape Friends/Targets)
                if data.isPlayer and data.player then
                    if isFriend and isFriend(data.player) then baseColor = Color3.fromRGB(76, 209, 142) end
                    if isTarget and isTarget(data.player) then baseColor = Color3.fromRGB(255, 60, 60) end
                end
                data.highlight.FillColor = baseColor
                data.highlight.FillTransparency = ESP.Config.FillTransparency
                local parts = {}
                if ESP.Config.Names then
                    local name = data.isPlayer and data.player.Name or model.Name
                    table.insert(parts, '<font color="#ffffff">' .. name .. '</font>')
                end
                if ESP.Config.Distance and myRoot and root then
                    local d = (root.Position - myRoot.Position).Magnitude
                    table.insert(parts, string.format('<font color="#9ad7ff">%.0fm</font>', d))
                end
                if ESP.Config.Health then
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local hp = math.floor(hum.Health)
                    local col = pct > 0.5 and "#7ad18b" or (pct > 0.25 and "#f5c44c" or "#eb4d5c")
                    table.insert(parts, string.format('<font color="%s">%d HP</font>', col, hp))
                end
                data.label.Text = table.concat(parts, "  ")
            end
        end
    end
end)

--==============================================================================
--// AIMBOT SYSTEM
--==============================================================================
local Aimbot = {}
Aimbot.Config = {
    Enabled      = false,
    TeamCheck    = true,
    WallCheck    = false,
    DeadCheck    = true,
    Smoothness   = 0.25,
    FOV          = 120,
    TargetPart   = "Head",
    Prediction   = 0,
    ShowFOV      = false,
    LockKey      = Enum.KeyCode.E,   -- hold to aim (optional). If nil, always aim.
    HoldToAim    = false,
}

local function aimGetClosest()
    local closest, closestMag = nil, Aimbot.Config.FOV
    local mousePos = UserInputService:GetMouseLocation()
    local myRoot = getRoot()
    if not myRoot then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = char:FindFirstChild(Aimbot.Config.TargetPart) or char:FindFirstChild("HumanoidRootPart")
            if part and hum and (not Aimbot.Config.DeadCheck or hum.Health > 0) then
                if not (Aimbot.Config.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if mag <= closestMag then
                            local visible = true
                            if Aimbot.Config.WallCheck then
                                local rp = RaycastParams.new()
                                rp.FilterType = Enum.RaycastFilterType.Exclude
                                rp.FilterDescendantsInstances = { LocalPlayer.Character, char }
                                local origin = Camera.CFrame.Position
                                local dir = (part.Position - origin)
                                local res = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, rp)
                                visible = res == nil or res.Instance:IsDescendantOf(char)
                            end
                            if visible then
                                closestMag = mag
                                closest = plr
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Aimbot.Config.Enabled then return end
    local active = true
    if Aimbot.Config.HoldToAim and Aimbot.Config.LockKey then
        active = UserInputService:IsKeyDown(Aimbot.Config.LockKey)
    end
    if not active then return end
    local target = aimGetClosest()
    if target and target.Character then
        local part = target.Character:FindFirstChild(Aimbot.Config.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if part and hum then
            local targetPos = part.Position
            if Aimbot.Config.Prediction > 0 and hum.RootPart then
                targetPos = targetPos + hum.RootPart.AssemblyLinearVelocity * Aimbot.Config.Prediction
            end
            local aimCF = CFrame.new(Camera.CFrame.Position, targetPos)
            local s = math.clamp(Aimbot.Config.Smoothness, 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, s)
        end
    end
end)

-- FOV circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, Aimbot.Config.FOV * 2, 0, Aimbot.Config.FOV * 2)
FOVCircle.Position = UDim2.new(0.5, -Aimbot.Config.FOV, 0.5, -Aimbot.Config.FOV)
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.ZIndex = 5
FOVCircle.Parent = ScreenGui
corner(FOVCircle, UDim.new(1, 0))
stroke(FOVCircle, Theme.Accent, 1.5, 0.3)
local FOVAspect = Instance.new("UIAspectRatioConstraint")
FOVAspect.AspectRatio = 1
FOVAspect.Parent = FOVCircle

RunService.RenderStepped:Connect(function()
    if Aimbot.Config.ShowFOV then
        FOVCircle.Visible = true
        local r = Aimbot.Config.FOV
        FOVCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
        FOVCircle.Position = UDim2.new(0.5, -r, 0.5, -r)
    else
        FOVCircle.Visible = false
    end
end)

--==============================================================================
--// TRIGGERBOT  (auto-fire when crosshair over a valid target)
--==============================================================================
local Triggerbot = { Config = { Enabled = false, Delay = 0.05, TeamCheck = true, Burst = false } }
local lastFire = 0
RunService.Heartbeat:Connect(function()
    if not Triggerbot.Config.Enabled then return end
    if tick() - lastFire < Triggerbot.Config.Delay then return end
    local target = Mouse.Target
    if not target then return end
    local char = target:FindFirstAncestorOfClass("Model")
    if not char then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and plr ~= LocalPlayer then
        if Triggerbot.Config.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            lastFire = tick()
            pcall(function()
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOf