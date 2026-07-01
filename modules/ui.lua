-- UI module (Potatools)
-- This module should export functions used to build the hub UI.
local M = {}

local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Theme = {
    Background      = Color3.fromRGB(22, 22, 28),
    BackgroundDark  = Color3.fromRGB(16, 16, 20),
    Sidebar         = Color3.fromRGB(26, 26, 34),
    Element         = Color3.fromRGB(34, 34, 44),
    ElementHover    = Color3.fromRGB(44, 44, 56),
    Text            = Color3.fromRGB(236, 236, 242),
    TextDim         = Color3.fromRGB(150, 150, 162),
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
}

local ModuleRequire = getgenv and getgenv().PotatoolsRequire
local Helpers = ModuleRequire and ModuleRequire("modules.helpers") or require(script.Parent.helpers)
local corner = Helpers.corner
local stroke = Helpers.stroke
local gradient = Helpers.gradient
local tween = Helpers.tween
local padding = Helpers.padding

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

local function createWindow(title, subtitle, sizeX, sizeY, pos, ScreenGui)
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

    -- header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    corner(header, Theme.RoundedBig)

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
    -- content area
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 44)
    content.Size = UDim2.new(1, 0, 1, -44)
    content.ZIndex = 11
    content.Parent = root

    local function addHolder(height)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, height or 40)
        f.BackgroundTransparency = 1
        f.ZIndex = 11
        f.Parent = content
        local c = Instance.new("Frame")
        c.Size = UDim2.new(1, 0, 1, 0)
        c.BackgroundColor3 = Theme.Element
        c.BackgroundTransparency = 0
        c.BorderSizePixel = 0
        c.ZIndex = 11
        c.Parent = f
        corner(c, Theme.Rounded)
        stroke(c, Theme.Stroke, 1, 0.2)
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
        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        knob.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        knob.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                setFromX(input.Position.X)
            end
        end)
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                setFromX(input.Position.X)
            end
        end)

        table.insert(self._elements, f)
        return obj
    end

    function self:AddInput(text, default, placeholder, callback)
        local f = addHolder(36)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 13
        lbl.Parent = f
        local input = Instance.new("TextBox")
        input.BackgroundTransparency = 1
        input.Position = UDim2.new(0.55, 8, 0, 0)
        input.Size = UDim2.new(0.45, -16, 1, 0)
        input.Font = Theme.Font
        input.TextSize = 12
        input.TextColor3 = Theme.TextDim
        input.TextXAlignment = Enum.TextXAlignment.Right
        input.PlaceholderText = placeholder or ""
        input.Text = default or ""
        input.ZIndex = 13
        input.Parent = f
        input.FocusLost:Connect(function(enter)
            if callback then pcall(callback, input.Text) end
        end)
        table.insert(self._elements, f)
        return input
    end

    function self.Destroy()
        if root and root.Parent then
            root:Destroy()
        end
        self._destroyed = true
    end

    function self.ToggleVisibility(state)
        root.Visible = state
    end

    return self, root
end

function M.BuildUI(env)
    -- env.ScreenGui must be provided when calling BuildUI
    if not env or not env.ScreenGui then return false, "env.ScreenGui required" end
    env.Theme = Theme
    env.createWindow = function(...) return createWindow(..., env.ScreenGui) end
    env.bringToFront = bringToFront
    env.tween = tween
    env.corner = corner
    env.stroke = stroke
    env.gradient = gradient
    return true
end

-- Auto-register common window builders (loads but does not open)
pcall(function()
    local tp = ModuleRequire and ModuleRequire("modules.windows.teleportpro") or require(script.Parent.windows.teleportpro)
    M.TeleportProBuilder = tp.build
end)
pcall(function()
    local lh = ModuleRequire and ModuleRequire("modules.windows.legit_hud") or require(script.Parent.windows.legit_hud)
    M.LegitHUDBuider = lh.build
end)
pcall(function()
    local vm = ModuleRequire and ModuleRequire("modules.windows.vape_modules") or require(script.Parent.windows.vape_modules)
    M.VapeModulesBuilder = vm.build
end)

return M

