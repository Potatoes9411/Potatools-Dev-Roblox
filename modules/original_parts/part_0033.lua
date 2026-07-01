nnect(function()
    if not AutoBuyAll.Enabled then return end
    if _abaLast and tick() - _abaLast < AutoBuyAll.Settings.Delay then return end
    _abaLast = tick()
    fireRemotes("buy"); fireRemotes("purchase"); fireRemotes("equip")
end)

------------------------------------------------------------
-- DISABLER  (best-effort: spam anti-cheat reset remotes)
------------------------------------------------------------
local Disabler = makeModule("Disabler", "World", {})
RunService.Heartbeat:Connect(function()
    if not Disabler.Enabled then return end
    pcall(function()
        fireRemotes("reset"); fireRemotes("anticheat"); fireRemotes("verify")
    end)
end)

------------------------------------------------------------
-- NAME SPOOF  (vape-style: spoof local display name display)
------------------------------------------------------------
local NameSpoof = makeModule("NameSpoof", "Render", {})
function NameSpoof.OnToggle(state)
    pcall(function()
        if state then
            -- change local humanoid display name appearance
            local hum = getHum()
            if hum then
                hum:SetAttribute("OrigDisplayName", hum.DisplayName)
                hum.DisplayName = "Player"
            end
        else
            local hum = getHum()
            if hum then
                local orig = hum:GetAttribute("OrigDisplayName")
                if orig then hum.DisplayName = orig end
            end
        end
    end)
end

------------------------------------------------------------
-- SPINBOT (continuous fast spin, distinct from Spin module)
------------------------------------------------------------
local Spinbot = makeModule("Spinbot", "Combat", { Speed = 40 })
RunService.RenderStepped:Connect(function(dt)
    if not Spinbot.Enabled then return end
    local root = getRoot()
    if root then
        pcall(function() root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Spinbot.Settings.Speed) * dt * 10, 0) end)
    end
end)

------------------------------------------------------------
-- AUTO CLIP THROUGH DOORS  (walk through locked doors)
------------------------------------------------------------
local DoorClip = makeModule("DoorClip", "World", {})
RunService.Heartbeat:Connect(function()
    if not DoorClip.Enabled then return end
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if n:find("door") or n:find("gate") or n:find("barrier") then
                    d.CanCollide = false
                end
            end
        end
    end)
end)

------------------------------------------------------------
-- TAP TP  (double-tap a movement key to dash)
------------------------------------------------------------
local TapTP = makeModule("TapTP", "Movement", { Distance = 30 })
local _tapKeys = {}
local _tapTimes = {}
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not TapTP.Enabled then return end
    if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then
        local key = input.KeyCode
        local now = tick()
        if _tapTimes[key] and now - _tapTimes[key] < 0.3 then
            -- double tap -> dash
            local root = getRoot()
            local hum = getHum()
            if root and hum and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    root.CFrame = root.CFrame + hum.MoveDirection * TapTP.Settings.Distance
                end)
            end
            _tapTimes[key] = nil
        else
            _tapTimes[key] = now
        end
    end
end)

------------------------------------------------------------
-- CROSSHAIR EXPAND  (dynamic crosshair that grows with movement)
------------------------------------------------------------
local CrosshairExpand = makeModule("CrosshairExpand", "Render", {})
function CrosshairExpand.OnToggle(state)
    pcall(function()
        if state then
            setCrosshair(true)
        else
            setCrosshair(false)
        end
    end)
end
RunService.Heartbeat:Connect(function()
    if not CrosshairExpand.Enabled then return end
    local hum = getHum()
    if hum then
        Crosshair.Gap = 4 + math.min(hum.MoveDirection.Magnitude * 12, 20)
    end
end)

------------------------------------------------------------
-- CHAMS (real Highlight fill, separate from BoxESP)
------------------------------------------------------------
local Chams = makeModule("Chams", "Render", { TeamCheck = true, FillTransparency = 0.5 })
local _chamsHL = {}
function Chams.OnToggle(state)
    if not state then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                local h = plr.Character:FindFirstChild("ChamsHL")
                if h then h:Destroy() end
            end
        end
        _chamsHL = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not Chams.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("ChamsHL") then
            if not (Chams.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                local h = Instance.new("Highlight")
                h.Name = "ChamsHL"
                h.FillColor = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(122, 92, 255)
                h.FillTransparency = Chams.Settings.FillTransparency
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.OutlineTransparency = 0
                h.Parent = plr.Character
                table.insert(_chamsHL, h)
            end
        end
    end
end)

------------------------------------------------------------
-- RAINBOW COLOR SYSTEM  (vape rainbow cycling for the whole UI accent)
------------------------------------------------------------
local Rainbow = {
    Enabled = false,
    Speed = 1,
    Hue = 0,
}
local _rainbowConn
function Rainbow:Set(v)
    self.Enabled = v and true or false
    if v then
        if _rainbowConn then return end
        _rainbowConn = RunService.RenderStepped:Connect(function(dt)
            self.Hue = (self.Hue + dt * self.Speed * 0.1) % 1
            local col = Color3.fromHSV(self.Hue, 0.7, 1)
            -- live-recolour the hub accent + array list
            Theme.Accent = col
            Theme.AccentBright = col
            if ArrayList.Enabled then ArrayList:ApplyColor(col) end
        end)
    else
        if _rainbowConn then _rainbowConn:Disconnect(); _rainbowConn = nil end
        Theme.Accent = Color3.fromRGB(122, 92, 255)
        Theme.AccentBright = Color3.fromRGB(150, 122, 255)
    end
end

------------------------------------------------------------
-- ARRAY LIST / WATERMARK  (the iconic vape TextGUI module list)
-- Shows every enabled Vape module as a coloured, sorted label with an
-- optional gradient logo and background. Real TextLabels + UIGradient.
------------------------------------------------------------
local ArrayList = {
    Enabled = false,
    Sort = "Length",            -- "Length" or "Alphabetical"
    Background = true,
    Shadow = true,
    Logo = true,
    CustomText = "",
    Font = Enum.Font.GothamBold,
    Size = 15,
    Position = "Right",         -- "Right" or "Left"
    _frame = nil,
    _holder = nil,
    _labels = {},               -- { {Object=, Text=} }
    _color = Color3.fromRGB(122, 92, 255),
}
function ArrayList:Build()
    if self._frame and self._frame.Parent then return end
    self._frame = Instance.new("Frame")
    self._frame.Name = "ArrayList"
    self._frame.Size = UDim2.new(0, 200, 0, 300)
    self._frame.Position = UDim2.new(1, -210, 0, 14)
    self._frame.BackgroundTransparency = 1
    self._frame.ZIndex = 40
    self._frame.Parent = ScreenGui
    -- gradient logo
    self._logo = Instance.new("TextLabel")
    self._logo.Name = "Logo"
    self._logo.BackgroundTransparency = 1
    self._logo.Size = UDim2.new(0, 120, 0, 24)
    self._logo.Font = Enum.Font.GothamBold
    self._logo.TextSize = 20
    self._logo.Text = "MultiGameHub"
    self._logo.TextXAlignment = Enum.TextXAlignment.Right
    self._logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    self._logo.ZIndex = 41
    self._logo.Parent = self._frame
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new(Color3.fromRGB(150, 122, 255), Color3.fromRGB(86, 62, 200))
    grad.Parent = self._logo
    self._logoGrad = grad
    self._logo.Visible = self.Logo
    -- labels holder
    self._holder = Instance.new("Frame")
    self._holder.Name = "Labels"
    self._holder.Size = UDim2.new(1, 0, 1, -30)
    self._holder.Position = UDim2.new(0, 0, 0, 30)
    self._holder.BackgroundTransparency = 1
    self._holder.ZIndex = 41
    self._holder.Parent = self._frame
    local lay = Instance.new("UIListLayout")
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = self.Position == "Left" and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right
    lay.Padding = UDim.new(0, 1)
    lay.Parent = self._holder
end
function ArrayList:ApplyColor(col)
    self._color = col
    if self._logoGrad then
        self._logoGrad.Color = ColorSequence.new(col, Color3.fromRGB(col.R * 60, col.G * 60, col.B * 60))
    end
end
function ArrayList:Refresh()
    if not (self.Enabled and self._holder) then return end
    -- clear old labels
    for _, l in ipairs(self._labels) do pcall(function() l.Object:Destroy() end) end
    self._labels = {}
    -- gather enabled modules
    local enabled = {}
    for name, m in pairs(Modules) do
        if m.Enabled then
            local extra = m.ExtraText and m.ExtraText() or ""
            table.insert(enabled, { name = name, text = name .. (extra ~= "" and (" " .. extra .. " ") or "") })
        end
    end
    -- also include shared toggles
    if ESP.Config.Enabled then table.insert(enabled, { name = "ESP", text = "ESP" }) end
    if Aimbot.Config.Enabled then table.insert(enabled, { name = "Aimbot", text = "Aimbot" }) end
    if Triggerbot.Config.Enabled then table.insert(enabled, { name = "Triggerbot", text = "Triggerbot" }) end
    if Movement.Fly.Enabled then table.insert(enabled, { name = "Fly", text = "Fly" }) end
    if Movement.Noclip then table.insert(enabled, { name = "Noclip", text = "Noclip" }) end
    -- sort
    if self.Sort == "Length" then
        table.sort(enabled, function(a, b) return #a.text > #b.text end)
    else
        table.sort(enabled, function(a, b) return a.name < b.name end)
    end
    local right = self.Position == "Right"
    for i, e in ipairs(enabled) do
        local holder = Instance.new("Frame")
        holder.Name = e.name
        holder.Size = UDim2.new(0, 0, 0, 0)
        holder.AutomaticSize = Enum.AutomaticSize.XY
        holder.BackgroundTransparency = self.Background and 0.4 or 1
        holder.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        holder.BorderSizePixel = 0
        holder.LayoutOrder = i
        holder.ClipsDescendants = true
        holder.Parent = self._holder
        -- colored accent line
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 2, 1, 0)
        line.Position = right and UDim2.new(1, -1, 0, 0) or UDim2.new(0, 0, 0, 0)
        line.BorderSizePixel = 0
        line.BackgroundColor3 = self._color
        line.Parent = holder
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0, 0, 0, self.Size + 4)
        lbl.AutomaticSize = Enum.AutomaticSize.X
        lbl.Font = self.Font
        lbl.TextSize = self.Size
        lbl.TextColor3 = self._color
        lbl.TextXAlignment = right and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
        lbl.Position = right and UDim2.new(0, 0, 0, 1) or UDim2.new(0, 6, 0, 1)
        lbl.Text = " " .. e.text .. " "
        lbl.Parent = holder
        -- padding so text isn't clipped
        local pad = Instance.new("UIPadding")
        pad.PaddingRight = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = holder
        if self.Shadow then
            local drop = lbl:Clone()
            drop.Position = UDim2.new(0, 1, 0, 2)
            drop.TextColor3 = Color3.fromRGB(0, 0, 0)
            drop.TextTransparency = 0.5
            drop.ZIndex = lbl.ZIndex - 1
            drop.Parent = holder
        end
        table.insert(self._labels, { Object = holder, Text = lbl })
    end
end
function ArrayList:Set(v)
    self.Enabled = v and true or false
    if v then
        self:Build()
        self._frame.Visible = true
    else
        if self._frame then self._frame.Visible = false end
    end
end
local _alConn
local function hookArrayList()
    if _alConn then return end
    _alConn = RunService.Heartbeat:Connect(function()
        if ArrayList.Enabled then ArrayList:Refresh() end
    end)
end
hookArrayList()

------------------------------------------------------------
-- TARGET INFO  (vape TargetInfo: avatar headshot + name + animated health)
------------------------------------------------------------
local TargetInfo = {
    Enabled = false,
    UseDisplayName = true,
    _frame = nil,
    _name = nil,
    _shot = nil,
    _flash = nil,
    _health = nil,
    _targets = {},
    _lastHealth = 0,
}
function TargetInfo:Build()
    if self._frame and self._frame.Parent then return end
    local b = Instance.new("Frame")
    b.Name = "TargetInfo"
    b.Size = UDim2.new(0, 240, 0, 89)
    b.Position = UDim2.new(0, 14, 0, 120)
    b.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    b.BackgroundTransparency = 0.5
    b.BorderSizePixel = 0
    b.Visible = false
    b.ZIndex = 40
    b.Parent = ScreenGui
    corner(b, Theme.Rounded)
    stroke(b, Theme.Stroke, 1, 0.3)
    makeDraggable(b, b)
    self._frame = b
    local shot = Instance.new("ImageLabel")
    shot.Size = UDim2.new(0, 26, 0, 27)
    shot.Position = UDim2.new(0, 19, 0, 17)
    shot.BackgroundColor3 = Theme.Element
    shot.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420"
    shot.ZIndex = 41
    shot.Parent = b
    corner(shot, UDim.new(0, 6))
    self._shot = shot
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    flash.BackgroundTransparency = 1
    flash.ZIndex = 42
    flash.Parent = shot
    self._flash = flash
    local name = Instance.new("TextLabel")
    name.BackgroundTransparency = 1
    name.Position = UDim2.new(0, 54, 0, 20)
    name.Size = UDim2.new(0, 170, 0, 20)
    name.Font = Theme.FontBold
    name.TextSize = 16
    name.TextColor3 = Color3.fromRGB(236, 236, 242)
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Text = "Target name"
    name.ZIndex = 41
    name.Parent = b
    self._name = name
    local hbkg = Instance.new("Frame")
    hbkg.Size = UDim2.new(0, 200, 0, 9)
    hbkg.Position = UDim2.new(0, 20, 0, 56)
    hbkg.BackgroundColor3 = Theme.Element
    hbkg.BorderSizePixel = 0
    hbkg.ZIndex = 41
    hbkg.Parent = b
    corner(hbkg, UDim.new(1, 0))
    local health = Instance.new("Frame")
    health.Size = UDim2.new(0.8, 0, 1, 0)
    health.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    health.BorderSizePixel = 0
    health.ZIndex = 42
    health.Parent = hbkg
    corner(health, UDim.new(1, 0))
    self._health = health
end
function TargetInfo:Set(v)
    self.Enabled = v and true or false
    if v then
        self:Build()
    else
        if self._frame then self._frame.Visible = false end
    end
end
RunService.RenderStepped:Connect(function()
    if not (TargetInfo.Enabled and TargetInfo._frame) then return end
    -- pick the "best" target: nearest enemy in ESP/Aura range, or last aura target
    local best, bestKey, bestMag = nil, nil, 1e9
    local myRoot = getRoot()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 and myRoot then
                local d = (hrp.Position - myRoot.Position).Magnitude
                if d < bestMag then
                    bestMag = d
                    best = plr
                    bestKey = plr
                end
            end
        end
    end
    if best and bestMag < 200 then
        local hum = best.Character:FindFirstChildOfClass("Humanoid")
        TargetInfo._frame.Visible = true
        TargetInfo._name.Text = (TargetInfo.UseDisplayName and best.DisplayName or best.Name)
        TargetInfo._shot.Image = "rbxthumb://type=AvatarHeadShot&id=" .. best.UserId .. "&w=420&h=420"
        if hum then
            local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            -- damage flash
            if TargetInfo._lastHealth > hum.Health then
                tween(TargetInfo._flash, 0.5, { BackgroundTransparency = 1 })
                TargetInfo._flash.BackgroundTransparency = 0.3
            end
            TargetInfo._lastHealth = hum.Health
            tween(TargetInfo._health, 0.3, {
                Size = UDim2.new(pct, 0, 1, 0),
                BackgroundColor3 = Color3.fromHSV(math.clamp(pct / 2.5, 0, 1), 0.8, 0.8),
            })
        end
    else
        TargetInfo._frame.Visible = false
        TargetInfo._lastHealth = 0
    end
end)

------------------------------------------------------------
-- PROFILES  (vape Profiles: save / load multiple config slots)
------------------------------------------------------------
local ProfileStore = {
    Current = "default",
    File = "MultiGameHub_Profiles.json",
    Slots = { "default", "aggressive", "stealth", "pvp", "auto" },
}
function ProfileStore:LoadAll()
    local ok, res = pcall(function()
        if not (isfile and isfile(self.File)) then return {} end
        return HttpService:JSONDecode(readfile(self.File))
    end)
    return ok and type(res) == "table" and res or {}
end
function ProfileStore:Save(name)
    name = name or self.Current
    local all = self:LoadAll()
    all[name] = ConfigStore.gather()
    pcall(function() if writefile then writefile(self.File, HttpService:JSONEncode(all)) end end)
    notify("Profiles", "Saved profile: " .. name, 3, Theme.Green)
end
function ProfileStore:Load(name)
    name = name or self.Current
    local all = self:LoadAll()
    local slot = all[name]
    if not slot then
        notify("Profiles", "Profile '" .. name .. "' is empty.", 3, Theme.Yellow)
        return
    end
    ConfigStore.apply(slot)
    self.Current = name
    notify("Profiles", "Loaded profile: " .. name, 3, Theme.Accent)
end
function ProfileStore:Delete(name)
    local all = self:LoadAll()
    all[name] = nil
    pcall(function() if writefile then writefile(self.File, HttpService:JSONEncode(all)) end end)
    notify("Profiles", "Deleted profile: " .. name, 3, Theme.Red)
end

------------------------------------------------------------
-- MOBILE / FLOATING BUTTONS  (vape mobile toggles)
------------------------------------------------------------
local MobileButtons = { _buttons = {}, _holder = nil, Enabled = false }
function MobileButtons:Rebuild(map)
    if self._holder then self._holder:Destroy() end
    self._buttons = {}
    self._holder = Instance.new("Frame")
    self._holder.Name = "MobileButtons"
    self._holder.Size = UDim2.new(0, 100, 0, 200)
    self._holder.Position = UDim2.new(1, -110, 1, -210)
    self._holder.BackgroundTransparency = 1
    self._holder.ZIndex = 60
    self._holder.Parent = ScreenGui
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.Parent = self._holder
    makeDraggable(self._holder, self._holder)
    local idx = 0
    for label, toggleFn in pairs(map) do
        idx = idx + 1
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 0, 38)
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        btn.Text = label
        btn.Font = Theme.FontBold
        btn.TextSize = 11
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.ZIndex = 61
        btn.Parent = self._holder
        corner(btn, UDim.new(0, 8))
        stroke(btn, Theme.Stroke, 1, 0)
        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            tween(btn, 0.12, { BackgroundColor3 = state and Color3.fromRGB(76, 209, 142) or Color3.fromRGB(30, 30, 40) })
            pcall(toggleFn, state)
        end)
        self._buttons[label] = btn
    end
end
function MobileButtons:BuildDefault()
    self:Rebuild({
        ["Fly"] = function(v) Movement.Fly.Enabled = v end,
        ["Speed"] = function(v) Movement.WalkSpeed.Enabled = v end,
        ["Noclip"] = function(v) Movement.Noclip = v end,
        ["ESP"] = function(v) ESP.Enable(v) end,
        ["Aura"] = function(v) KillAura:Set(v) end,
    })
    self.Enabled = true
    notify("Mobile Buttons", "Floating toggles created (draggable).", 3, Theme.Accent)
end
function MobileButtons:Hide()
    if self._holder then self._holder:Destroy(); self._holder = nil end
    self._buttons = {}
    self.Enabled = false
end

------------------------------------------------------------
-- VAPE "LEGIT" HUD WINDOW
------------------------------------------------------------
local function LegitHUD()
    local w = createWindow("Legit HUD", "Vape-style HUD overlays", 440, 540,
        UDim2.new(0.5, -220 + math.random(-70, 70), 0.5, -270 + math.random(-60, 60)))
    w:AddSection("Info HUDs")
    w:AddToggle("FPS Counter", false, function(v) FPSModule:Set(v) end, "Frames per second")
    w:AddToggle("Ping", false, function(v) PingModule:Set(v) end, "Server latency (ms)")
    w:AddToggle("Memory", false, function(v) MemoryModule:Set(v) end, "Memory usage (MB)")
    w:AddToggle("Speed Meter", false, function(v) SpeedmeterModule:Set(v) end, "Velocity in studs/sec")
    w:AddToggle("Coordinates", false, function(v) CoordsHUD:Set(v) end, "Your X/Y/Z position")
    w:AddToggle("Server Info", false, function(v) ServerHUD:Set(v) end, "Players + JobId")
    w:AddSection("Display")
    w:AddToggle("Keystrokes", false, function(v) Keystrokes:Set(v) end, "W/A/S/D/Space widgets")
    w:AddToggle("Console Log", false, function(v) ConsoleLog:Set(v) end, "Debug message overlay")
    w:AddSection("World / Visual")
    w:AddToggle("Time Changer", false, function(v) TimeChanger:Set(v) end, "Set Lighting time")
    w:AddSlider("Time (hour)", 0, 24, 12, ":00", 0, function(v)
        TimeChanger.Value = math.floor(v)
        if TimeChanger.Enabled then Lighting.TimeOfDay = string.format("%02d:00:00", TimeChanger.Value) end
    end)
    w:AddToggle("Atmosphere / Lighting FX", false, function(v) AtmosphereMod:Set(v) end, "Bloom + SunRays + ColorCorrect + Atmosphere")
    w:AddSection("Cosmetic")
    w:AddToggle("Cape (animated)", false, function(v) Cape:Set(v) end, "Velocity-animated Motor6D cape")
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end, "Cone above your head")
    w:AddToggle("Breadcrumbs Trail", false, function(v) Breadcrumbs:Set(v) end, "Trail behind your character")
    w:AddSection("Array List / Watermark")
    w:AddToggle("Array List (enabled modules)", false, function(v) ArrayList:Set(v) end, "Show enabled modules list")
    w:AddDropdown("Sort By", { "Length", "Alphabetical" }, "Length", function(v) ArrayList.Sort = v end)
    w:AddToggle("Show Logo", true, function(v) ArrayList.Logo = v; if ArrayList._logo then ArrayList._logo.Visible = v end end)
    w:AddToggle("Background", true, function(v) ArrayList.Background = v end)
    w:AddToggle("Text Shadow", true, function(v) ArrayList.Shadow = v end)
    w:AddDropdown("Side", { "Right", "Left" }, "Right", function(v) ArrayList.Position = v end)
    w:AddSlider("Font Size", 10, 28, 15, "", 0, function(v) ArrayList.Size = v end)
    w:AddSection("Target Info")
    w:AddToggle("Target Info HUD", false, function(v) TargetInfo:Set(v) end, "Show nearest target's info")
    w:AddToggle("Use Display Name", true, function(v) TargetInfo.UseDisplayName = v end)
    w:AddSection("Rainbow")
    w:AddToggle("Rainbow Accent", false, function(v) Rainbow:Set(v) end, "Cycle UI colour")
    w:AddSlider("Rainbow Speed", 0.1, 5, 1, "x", 2, function(v) Rainbow.Speed = v end)
    w:AddSection("Mobile / Floating Buttons")
    w:AddButton("Create Floating Toggles", function() MobileButtons:BuildDefault() end)
    w:AddButton("Hide Floating Toggles", function() MobileButtons:Hide() end, Theme.Yellow)
    w:AddSection("Profiles")
    w:AddDropdown("Profile Slot", ProfileStore.Slots, "default", function(v) ProfileStore.Current = v end)
    w:AddButton("Save Current to Slot", function() ProfileStore:Save(ProfileStore.Current) end, Theme.Green)
    w:AddButton("Load Selected Slot", function() ProfileStore:Load(ProfileStore.Current) end)
    w:AddButton("Delete Selected Slot", function() ProfileStore:Delete(ProfileStore.Current) end, Theme.Red)
    w:AddSection("Combat / Visual HUD")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end, "Floating numbers on hits")
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end, "Flash when taking damage")
    w:AddToggle("FPS Boost", false, function(v) FPSBoost:Set(v) end, "Reduce graphics for FPS")
    w:AddSlider("Boost Level", 1, 3, 2, "", 0, function(v) FPSBoost.Settings.Level = v end)
    w:AddToggle("Auto Dodge (projectiles)", false, function(v) AutoDodge:Set(v) end, "Dodge incoming bullets/fireballs")
    w:AddSlider("Dodge Range", 10, 120, 40, "studs", 0, function(v) AutoDodge.Settings.Range = v end)
    w:AddSection("Safety")
    w:AddButton("Disable All HUD", function()
        FPSModule:Set(false); PingModule:Set(false); MemoryModule:Set(false); SpeedmeterModule:Set(false)
        CoordsHUD:Set(false); ServerHUD:Set(false)
        Keystrokes:Set(false); ConsoleLog:Set(false); TimeChanger:Set(false)
        AtmosphereMod:Set(false); Cape:Set(false); ChinaHat:Set(false); Breadcrumbs:Set(false)
        ArrayList:Set(false); TargetInfo:Set(false); Rainbow:Set(false); MobileButtons:Hide()
        DamageNumbers:Set(false); HitIndicator:Set(false); FPSBoost:Set(false); AutoDodge:Set(false)
        notify("Legit HUD", "All HUD modules disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("Legit HUD", "Loaded.", 3, Theme.Accent)
    return w
end

------------------------------------------------------------
-- VAPE-STYLE MODULES WINDOW
------------------------------------------------------------
local function VapeModules()
    local w = createWindow("Vape Modules", "Combat / Movement / Render", 480, 600,
        UDim2.new(0.5, -240 + math.random(-70, 70), 0.5, -300 + math.random(-60, 60)))
    -- Combat
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) KillAura:Set(v) end, "Attack all enemies in a cone")
    w:AddSlider("Attack Range", 3, 30, 13, "studs", 1, function(v) KillAura.Settings.AttackRange = v end)
    w:AddSlider("Swing Range", 1, 30, 6, "studs", 1, function(v) KillAura.Settings.SwingRange = v end)
    w:AddSlider("Aura CPS", 1, 20, 12, "", 0, function(v) KillAura.Settings.CPS = v end)
    w:AddSlider("Aura Delay", 0.02, 1, 0.1, "s", 2, function(v) KillAura.Settings.Delay = v end)
    w:AddSlider("Max Targets", 1, 10, 1, "", 0, function(v) KillAura.Settings.Targets = v end)
    w:AddSlider("Max Angle", 10, 360, 90, "deg", 0, function(v) KillAura.Settings.MaxAngle = v end)
    w:AddToggle("Aura Include NPCs", false, function(v) KillAura.Settings.NPC = v end)
    w:AddToggle("Aura Rotate To Target", true, function(v) KillAura.Settings.Rotate = v end)
    w:AddToggle("Aura Show Range (boxes)", false, function(v) KillAura.Settings.ShowRange = v end)
    w:AddToggle("Aura Hit Particles", false, function(v) KillAura.Settings.Particles = v end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end, "Reduce knockback")
    w:AddSlider("Horizontal Resist", 0, 100, 100, "%", 0, function(v) Velocity.Settings.Horizontal = v end)
    w:AddSlider("Vertical Resist", 0, 100, 0, "%", 0, function(v) Velocity.Settings.Vertical = v end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end, "Hop for crit hits")
    w:AddToggle("Reach", false, function(v) Reach:Set(v) end, "Extend click hit range")
    w:AddSlider("Reach Distance", 5, 40, 12, "studs", 0, function(v) Reach.Settings.Distance = v end)
    w:AddToggle("AutoClicker", false, function(v) AutoClicker:Set(v) end)
    w:AddSlider("AutoClicker CPS", 1, 30, 12, "", 0, function(v) AutoClicker.Settings.CPS = v end)
    w:AddToggle("AC Hold Mode", true, function(v) AutoClicker.Settings.HoldMode = v end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end, "Snap to nearest target on click")
    w:AddSlider("Silent FOV", 20, 800, 200, "px", 0, function(v) SilentAim.Settings.FOV = v end)
    w:AddDropdown("Silent Target Part", { "HumanoidRootPart", "Head", "Torso", "UpperTorso" }, "HumanoidRootPart", function(v) SilentAim.Settings.Part = v end)
    w:AddToggle("Silent Auto Fire", false, function(v) SilentAim.Settings.AutoFire = v end)
    w:AddToggle("Reach (Tool)", false, function(v) Reach2:Set(v) end, "Extend held tool reach")
    w:AddDropdown("Reach Mode", { "Resize", "TouchInterest" }, "Resize", function(v) Reach2.Settings.Mode = v end)
    w:AddSlider("Reach Range", 1, 30, 3, "studs", 1, function(v) Reach2.Settings.Range = v end)
    -- Movement
    w:AddSection("Movement")
    w:AddToggle("Sprint", false, function(v) Sprint:Set(v) end)
    w:AddSlider("Sprint Speed", 16, 60, 22, "", 0, function(v) Sprint.Settings.Speed = v end)
    w:AddToggle("Float", false, function(v) Float:Set(v) end, "Hover at a Y level")
    w:AddDropdown("Float Mode", { "Velocity", "CFrame", "Floor" }, "Velocity", function(v) Float.Settings.Mode = v end)
    w:AddSlider("Float Height", 1, 40, 5, "studs", 0, function(v) Float.Settings.Height = v end)
    w:AddToggle("Speed", false, function(v) Speed:Set(v) end)
    w:AddDropdown("Speed Mode", { "Velocity", "CFrame", "WalkSpeed" }, "Velocity", function(v) Speed.Settings.Mode = v end)
    w:AddSlider("Speed Value", 10, 200, 30, "", 0, function(v) Speed.Settings.Value = v end)
    w:AddToggle("Step", false, function(v) Step:Set(v) end, "Walk up tall blocks")
    w:AddSlider("Step Height", 2, 20, 4, "", 0, function(v) Step.Settings.Height = v end)
    w:AddToggle("NoFall", false, function(v) NoFall:Set(v) end, "Avoid fall damage")
    w:AddToggle("Jesus", false, function(v) Jesus:Set(v) end, "Walk on water")
    w:AddToggle("Spider", false, function(v) Spider:Set(v) end, "Climb walls")
    w:AddSlider("Spider Speed", 5, 60, 25, "", 0, function(v) Spider.Settings.Speed = v end)
    -- Player
    w:AddSection("Player")
    w:AddToggle("AutoTool", false, function(v) AutoTool:Set(v) end, "Equip best tool for target")
    w:AddToggle("AutoRespawn", false, function(v) AutoRespawn:Set(v) end, "Respawn when dead")
    w:AddSlider("Respawn Delay", 0.1, 5, 0.5, "s", 2, function(v) AutoRespawn.Settings.Delay = v end)
    w:AddToggle("AntiVoid", false, function(v) AntiVoid:Set(v) end, "Teleport back if you fall")
    w:AddSlider("Void Y Level", -200, 0, -30, "", 0, function(v) AntiVoid.Settings.Y = v end)
    w:AddDropdown("AntiVoid Mode", { "Spawn", "Last" }, "Spawn", function(v) AntiVoid.Settings.Mode = v end)
    -- World
    w:AddSection("World")
    w:AddToggle("Scaffold", false, function(v) Scaffold:Set(v) end, "Place blocks beneath you")
    w:AddSlider("Scaffold Length", 2, 30, 5, "", 0, function(v) Scaffold.Settings.Length = v end)
    w:AddToggle("Freecam (WASD/Space)", false, function(v) Freecam:Set(v) end, "Detach & fly the camera")
    w:AddSlider("Freecam Speed", 10, 400, 80, "", 0, function(v) Freecam.Settings.Speed = v end)
    w:AddToggle("Auto Give (remote spam)", false, function(v) AutoGive:Set(v) end, "Best-effort tool give")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    -- Render
    w:AddSection("Render")
    w:AddToggle("Tracers", false, function(v) Tracers:Set(v) end, "Lines to players")
    w:AddToggle("Tracers Team Check", true, function(v) Tracers.Settings.TeamCheck = v end)
    w:AddToggle("NameTags", false, function(v) NameTags:Set(v) end)
    w:AddSlider("NameTag Size", 8, 40, 18, "", 0, function(v) NameTags.Settings.Size = v end)
    w:AddToggle("NameTag Background", true, function(v) NameTags.Settings.Background = v end)
    w:AddToggle("XRay", false, function(v) XRay:Set(v) end, "See through walls")
    w:AddSlider("XRay Strength", 0.5, 1, 0.85, "", 2, function(v) XRay.Settings.Strength = v end)
    w:AddToggle("StorageESP", false, function(v) StorageESP:Set(v) end, "Highlight chests/crates")
    w:AddToggle("Search ESP", false, function(v) SearchESP:Set(v) end, "Highlight any object by name")
    w:AddInput("Search Keyword", "", "e.g. Coin / Chest / NPC", function(v) SearchESP.Settings.Keyword = v end)
    w:AddToggle("Swing Animation", false, function(v) SwingAnim:Set(v) end, "Animate tool on aura swings")
    w:AddDropdown("Swing Style", { "Normal", "Horizontal Spin", "Vertical Spin" }, "Normal", function(v) SwingAnim.Settings.Style = v end)
    w:AddToggle("Zoom (hold Z)", false, function(v) Zoom:Set(v) end, "Scope in")
    w:AddSlider("Zoom FOV", 5, 70, 30, "", 0, function(v) Zoom.Settings.FOV = v end)
    w:AddToggle("Trajectories", false, function(v) Trajectories:Set(v) end, "Predict projectile arc")
    w:AddSlider("Traj Speed", 10, 300, 100, "", 0, function(v) Trajectories.Settings.Speed = v end)
    -- Combat extra
    w:AddSection("Combat Extra")
    w:AddToggle("Spin", false, function(v) Spin:Set(v) end, "Continuously spin character")
    w:AddSlider("Spin Speed", 1, 60, 18, "", 0, function(v) Spin.Settings.Speed = v end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end, "Dodge aim by jittering facing")
    w:AddDropdown("AntiAim Mode", { "Spin", "Jitter", "Reverse" }, "Spin", function(v) AntiAim.Settings.Mode = v end)
    w:AddSlider("AntiAim Speed", 5, 80, 30, "", 0, function(v) AntiAim.Settings.Speed = v end)
    w:AddToggle("Fast Use (tool)", false, function(v) FastUse:Set(v) end, "Rapidly activate held tool")
    w:AddSlider("Fast Use Delay", 0.01, 0.5, 0.05, "s", 2, function(v) FastUse.Settings.Delay = v end)
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end, "Re-fill health under threshold")
    w:AddSlider("Heal Threshold", 5, 100, 50, "%", 0, function(v) AutoHeal.Settings.MinHealth = v end)
    w:AddToggle("Mob ESP", false, function(v) MobESP:Set(v) end, "Highlight all NPCs")
    w:AddToggle("No Slowdown", false, function(v) NoSlowdown:Set(v) end, "Prevent movement slowdowns")
    w:AddSlider("NoSlowdown Speed", 12, 60, 16, "", 0, function(v) NoSlowdown.Settings.Speed = v end)
    w:AddToggle("Auto Pickup", false, function(v) AutoPickup:Set(v) end, "Touch nearby pickups")
    w:AddSlider("Pickup Range", 20, 300, 80, "studs", 0, function(v) AutoPickup.Settings.Range = v end)
    -- Movement extra
    w:AddSection("Movement Extra")
    w:AddToggle("Target Strafe", false, function(v) TargetStrafe:Set(v) end, "Orbit nearest target")
    w:AddSlider("Strafe Radius", 3, 20, 6, "studs", 1, function(v) TargetStrafe.Settings.Radius = v end)
    w:AddSlider("Strafe Speed", 5, 60, 20, "", 0, function(v) TargetStrafe.Settings.Speed = v end)
    w:AddToggle("Auto Clutch (fall block)", false, function(v) AutoClutch:Set(v) end, "Place block when falling")
    -- Extra Render (Radar / BoxESP)
    w:AddSection("Render Extra")
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end, "Minimap with player blips")
    w:AddSlider("Radar Range", 50, 1000, 200, "studs", 0, function(v) Radar.Range = v end)
    w:AddToggle("Radar Distance", true, function(v) Radar.ShowDistance = v end)
    w:AddToggle("Radar Team Check", true, function(v) Radar.TeamCheck = v end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end, "2D boxes around enemies")
    w:AddToggle("Box Team Check", true, function(v) BoxESP.TeamCheck = v end)
    w:AddToggle("Box Chams Fill", false, function(v) BoxESP.FillChams = v; if not v then for _, plr in ipairs(Players:GetPlayers()) do if plr.Character then local h = plr.Character:FindFirstChild("BoxChams"); if h then h:Destroy() end end end end end)
    w:AddSlider("Box Thickness", 1, 5, 1, "px", 0, function(v) BoxESP.Thickness = v end)
    w:AddToggle("Hitboxes (SelectionBox)", false, function(v) Hitboxes:Set(v) end, "Show real hitboxes")
    w:AddToggle("Hitboxes Include NPCs", false, function(v) Hitboxes.Settings.NPCs = v end)
    w:AddToggle("Aura Visual Sphere", false, function(v) AuraVisual:Set(v) end, "Sphere at aura range")
    -- Combat extra 2
    w:AddSection("Combat Extra 2")
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end, "Gentle pull to target")
    w:AddSlider("AA Strength", 1, 100, 30, "%", 0, function(v) AimAssist.Settings.Strength = v end)
    w:AddSlider("AA FOV", 20, 600, 100, "px", 0, function(v) AimAssist.Settings.FOV = v end)
    w:AddToggle("Mace (falling block)", false, function(v) Mace:Set(v) end, "Drop block on target")
    w:AddSlider("Mace Height", 20, 200, 60, "studs", 0, function(v) Mace.Settings.Height = v end)
    w:AddToggle("Fake Lag", false, function(v) FakeLag:Set(v) end, "Freeze network position")
    w:AddSlider("Fake Lag Delay", 0.05, 1, 0.1, "s", 2, function(v) FakeLag.Settings.Delay = v end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end, "Max lighting brightness")
    w:AddToggle("Auto Leave (low players)", false, function(v) AutoLeave:Set(v) end)
    w:AddSlider("Min Players", 1, 20, 3, "", 0, function(v) AutoLeave.Settings.MinPlayers = v end)
    -- World extra 2
    w:AddSection("World Extra")
    w:AddToggle("Phase (through walls)", false, function(v) Phase:Set(v) end, "Walk into walls to clip")
    w:AddToggle("Auto Interact", false, function(v) AutoInteract:Set(v) end, "Press buttons/levers")
    w:AddSlider("Interact Range", 10, 100, 30, "studs", 0, function(v) AutoInteract.Settings.Range = v end)
    w:AddToggle("Auto Block (build games)", false, function(v) AutoBlock:Set(v) end, "Place blocks while moving")
    -- SongBeats
    w:AddSection("Song Beats (MP3)")
    w:AddToggle("SongBeats Player", false, function(v) SongBeats:Set(v) end, "Play track + beat FOV")
    w:AddSlider("Volume", 1, 100, 100, "%", 0, function(v) SongBeats.Volume = v; if SongBeats._sound then SongBeats._sound.Volume = v / 100 end end)
    w:AddToggle("Beat FOV Pulse", true, function(v) SongBeats.FOVPulse = v end)
    w:AddSlider("BPM", 40, 240, 120, "", 0, function(v) SongBeats.BPM = v end)
    w:AddSlider("FOV Amount", 1, 30, 5, "", 0, function(v) SongBeats.FOVAmount = v end)
    -- Combat extra 3
    w:AddSection("Combat Extra 3")
    w:AddToggle("Mob Aura (NPCs only)", false, function(v) MobAura:Set(v) end)
    w:AddSlider("Mob Aura Range", 5, 60, 15, "studs", 0, function(v) MobAura.Settings.Range = v end)
    w:AddToggle("Auto Soup (heal)", false, function(v) AutoSoup:Set(v) end, "Use food when low HP")
    w:AddSlider("Soup HP Threshold", 5, 100, 50, "%", 0, function(v) AutoSoup.Settings.Health = v end)
    w:AddToggle("Auto Totem", false, function(v) AutoTotem:Set(v) end, "Equip totem/shield")
    -- Render extra 2
    w:AddSection("Render Extra 2")
    w:AddToggle("Chams (highlight fill)", false, function(v) Chams:Set(v) end)
    w:AddSlider("Chams Fill", 0, 1, 0.5, "", 2, function(v) Chams.Settings.FillTransparency = v; for _, h in ipairs(_chamsHL) do h.FillTransparency = v end end)
    w:AddToggle("Tree ESP", false, function(v) TreeESP:Set(v) end, "Highlight trees/wood")
    -- Movement extra 2
    w:AddSection("Movement Extra 2")
    w:AddToggle("Long Jump", false, function(v) LongJump:Set(v) end, "Leap forward (single-use)")
    w:AddSlider("Long Jump Power", 20, 200, 60, "", 0, function(v) LongJump.Settings.Power = v end)
    w:AddToggle("High Jump", false, function(v) HighJump:Set(v) end, "Big single jump")
    w:AddSlider("High Jump Power", 50, 400, 120, "", 0, function(v) HighJump.Settings.Power = v end)
    w:AddToggle("Blink (TP forward)", false, function(v) Blink:Set(v) end, "Teleport where you look")
    w:AddSlider("Blink Range", 10, 200, 60, "studs", 0, function(v) Blink.Settings.Range = v end)
    -- World extra 2
    w:AddSection("World Extra 2")
    w:AddToggle("Nuker", false, function(v) Nuker:Set(v) end, "Break blocks around you")
    w:AddDropdown("Nuker Mode", { "Break", "Touch" }, "Break", function(v) Nuker.Settings.Mode = v end)
    w:AddSlider("Nuker Range", 3, 30, 8, "studs", 0, function(v) Nuker.Settings.Range = v end)
    w:AddToggle("Auto Bridge (planks)", false, function(v) AutoBridge:Set(v) end, "Place plank bridge")
    -- Combat extra 4
    w:AddSection("Combat Extra 4")
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end, "Snap target through walls on click")
    w:AddDropdown("Wallbang Part", { "HumanoidRootPart", "Head", "Torso" }, "HumanoidRootPart", function(v) Wallbang.Settings.Part = v end)
    w:AddToggle("Spinbot", false, function(v) Spinbot:Set(v) end, "Fast continuous spin")
    w:AddSlider("Spinbot Speed", 5, 120, 40, "", 0, function(v) Spinbot.Settings.Speed = v end)
    -- Render extra 3
    w:AddSection("Render Extra 3")
    w:AddToggle("Sneak", false, function(v) Sneak:Set(v) end, "Adjust crouch speed")
    w:AddSlider("Sneak Speed", 4, 30, 8, "", 0, function(v) Sneak.Settings.Speed = v end)
    w:AddToggle("Timer (lighting)", false, function(v) Timer:Set(v) end, "Shift local time")
    w:AddSlider("Timer Mult", 0.1, 5, 1, "x", 2, function(v) Timer.Settings.Multiplier = v end)
    w:AddToggle("Viewport Clip", false, function(v) ViewportClip:Set(v) end, "Clamp camera FOV")
    w:AddSlider("Viewport Min", 30, 100, 70, "", 0, function(v) ViewportClip.Settings.Min = v end)
    w:AddToggle("Tower ESP", false, function(v) TowerESP:Set(v) end, "Highlight towers/bases")
    w:AddToggle("Healthbar ESP", false, function(v) HealthbarESP:Set(v) end, "Billboard HP bars")
    w:AddToggle("Crosshair Expand", false, function(v) CrosshairExpand:Set(v) end, "Dynamic crosshair")
    w:AddToggle("Name Spoof", false, function(v) NameSpoof:Set(v) end, "Hide local display name")
    -- World extra 3
    w:AddSection("World Extra 3")
    w:AddToggle("Auto Fish", false, function(v) AutoFish:Set(v) end, "Auto reel fishing prompts")
    w:AddToggle("Auto Buy All", false, function(v) AutoBuyAll:Set(v) end, "Spam buy remotes")
    w:AddToggle("Door Clip", false, function(v) DoorClip:Set(v) end, "Walk through doors")
    w:AddToggle("Disabler", false, function(v) Disabler:Set(v) end, "Spam reset/verify remotes")
    -- Movement extra 3
    w:AddSection("Movement Extra 3")
    w:AddToggle("Tap TP (double-tap dash)", false, function(v) TapTP:Set(v) end, "Double-tap WASD to dash")
    w:AddSlider("Dash Distance", 5, 100, 30, "studs", 0, function(v) TapTP.Settings.Distance = v end)
    -- Waypoints
    w:AddSection("Waypoints")
    w:AddInput("Waypoint Name", "", "name", function(v) w._wpName = v end)
    w:AddButton("Save Current Position", function()
        Waypoints.addCurrent(w._wpName ~= "" and w._wpName or nil)
        notify("Waypoints", "Saved " .. (#Waypoints.List) .. " waypoints.", 3, Theme.Green)
    end)
    w:AddButton("Teleport to Newest Waypoint", function()
        if #Waypoints.List > 0 then
            local wp = Waypoints.List[#Waypoints.List]
            teleportTo(Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3]))
        end
    end)
    w:AddButton("Clear Waypoints", function()
        Waypoints.List = {}; Waypoints.save()
        notify("Waypoints", "Cleared.", 3, Theme.Yellow)
    end, Theme.Yellow)
    -- Movement extra 3 (advanced)
    w:AddSection("Advanced Movement")
    w:AddToggle("Orbit TP", false, function(v) OrbitTP:Set(v) end, "Circle-strafe in place")
    w:AddSlider("Orbit Radius", 2, 30, 8, "studs", 0, function(v) OrbitTP.Settings.Radius = v end)
    w:AddSlider("Orbit Speed", 0.1, 5, 1.2, "x", 2, function(v) OrbitTP.Settings.Speed = v end)
    w:AddToggle("Anti-AFK Walk", false, function(v) AntiAFKWalk:Set(v) end, "Gentle movement to avoid kicks")
    w:AddSlider("AAW Speed", 0.1, 3, 1, "x", 2, function(v) AntiAFKWalk.Settings.Speed = v end)
    w:AddToggle("Slide (Shift)", false, function(v) Slide:Set(v) end, "Dash on shift key")
    w:AddSlider("Slide Power", 30, 200, 90, "", 0, function(v) Slide.Settings.Power = v end)
    w:AddToggle("VelTP (Shift fly)", false, function(v) VelTP:Set(v) end, "Velocity travel while shifting")
    w:AddSlider("VelTP Power", 30, 400, 120, "", 0, function(v) VelTP.Settings.Power = v end)
    -- Advanced combat
    w:AddSection("Advanced Combat")
    w:AddToggle("TP Aura (teleport-strike)", false, function(v) TPAura:Set(v) end)
    w:AddSlider("TP Aura Range", 10, 120, 40, "studs", 0, function(v) TPAura.Settings.Range = v end)
    w:AddSlider("TP Aura Delay", 0.05, 1, 0.2, "s", 2, function(v) TPAura.Settings.Delay = v end)
    w:AddToggle("Bringer", false, function(v) Bringer:Set(v) end, "Pull enemies/NPCs to you")
    w:AddDropdown("Bringer Targets", { "Players", "NPCs" }, "Players", function(v) Bringer.Settings.Targets = v end)
    w:AddSlider("Bringer Range", 10, 300, 60, "studs", 0, function(v) Bringer.Settings.Range = v end)
    -- Advanced extra
    w:AddSection("Advanced Suite")
    w:AddToggle("NPC Farm Route", false, function(v) NPCFarmRoute:Set(v) end, "Cycle-TP between NPCs")
    w:AddSlider("Farm Route Range", 5, 100, 30, "studs", 0, function(v) NPCFarmRoute.Settings.Range = v end)
    w:AddSlider("Farm Route Delay", 0.05, 2, 0.3, "s", 2, function(v) NPCFarmRoute.Settings.Delay = v end)
    w:AddToggle("Inventory ESP", false, function(v) InventoryESP:Set(v) end, "Highlight ground items")
    w:AddToggle("Auto Quest", false, function(v) AutoQuest:Set(v) end)
    w:AddToggle("Anti Stun", false, function(v) AntiStun:Set(v) end, "Recover from stuns")
    w:AddToggle("Auto Drops", false, function(v) AutoDrops:Set(v) end, "Touch nearby drops")
    w:AddSlider("Drops Range", 20, 300, 80, "studs", 0, function(v) AutoDrops.Settings.Range = v end)
    w:AddToggle("Ghost (semi-invisible)", false, function(v) Ghost:Set(v) end)
    w:AddToggle("Head Target", false, function(v) HeadTarget:Set(v) end, "Force head hitboxes")
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Instant Interact", false, function(v) InstantInteract:Set(v) end)
    w:AddSlider("Interact Range", 10, 200, 50, "studs", 0, function(v) InstantInteract.Settings.Range = v end)
    w:AddToggle("Waypoint Visuals", false, function(v) WaypointVisuals:Set(v) end, "Beacons at saved spots")
    w:AddToggle("Auto Waypoint Cycle", false, function(v) AutoWaypoint:Set(v) end)
    w:AddSlider("WP Cycle Delay", 1, 30, 3, "s", 0, function(v) AutoWaypoint.Settings.Delay = v end)
    w:AddToggle("Auto Respawn + Equip", false, function(v) AutoRespawnEquip:Set(v) end)
    w:AddToggle("Anti Explosion", false, function(v) AntiExplosion:Set(v) end, "TP away from blasts")
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Sound ESP", false, function(v) SoundESP:Set(v) end, "Mark playing sounds")
    w:AddToggle("Anti Water/Lava", false, function(v) AntiLiquid:Set(v) end)
    w:AddToggle("No Headshot (local)", false, function(v) NoHeadshot:Set(v) end)
    w:AddToggle("Air Stuck (hang)", false, function(v) AirStuck:Set(v) end)
    w:AddToggle("Slow Fall", false, function(v) SlowFall:Set(v) end)
    w:AddSlider("Slow Fall Speed", 5, 60, 20, "", 0, function(v) SlowFall.Settings.Speed = v end)
    w:AddToggle("Fast Reset", false, function(v) FastReset:Set(v) end)
    w:AddToggle("Auto Sell All", false, function(v) AutoSellAll:Set(v) end)
    w:AddToggle("Gravity Control", false, function(v) GravityMod:Set(v) end)
    w:AddSlider("Gravity Mult", 0, 3, 1, "x", 2, function(v) GravityMod.Settings.Mult = v end)
    w:AddToggle("Auto Chests", false, function(v) AutoChests:Set(v) end, "TP to & open all chests")
    w:AddButton("Dump Player Stats", function()
        local s = dumpStats()
        setclipboard(s)
        notify("Stats", "Copied stats to clipboard.", 3, Theme.Green)
    end, Theme.Green)
    -- Panic
    w:AddSection("Safety")
    w:AddButton("Disable All Modules", function()
        for _, m in pairs(Modules) do if m.Enabled then pcall(function() m:Set(false) end) end end
        FPSModule:Set(false); PingModule:Set(false); MemoryModule:Set(false); SpeedmeterModule:Set(false)
        Keystrokes:Set(false); ConsoleLog:Set(false); TimeChanger:Set(false)
        AtmosphereMod:Set(false); Cape:Set(false); ChinaHat:Set(false); Breadcrumbs:Set(false)
        notify("Vape Modules", "All modules disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("Vape Modules", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// A GENERIC "FPS COMBAT" WINDOW BUILDER
--   reused by Arsenal / Rivals / Bloxstrike / One Tap / Redliners / Hypershot
--   because their core needs are identical (aimbot/esp/trig/hitbox).
--==============================================================================
local function buildFPSWindow(gameName, accentColor, extraSetup)
    local w = createWindow(gameName, "FPS Combat Suite", 490, 540,
        UDim2.new(0.5, -245 + (math.random(-80, 80)), 0.5, -270 + (math.random(-60, 60))))
    w:AddSection("Aimbot")
    w:AddToggle("Enabled", false, function(v) Aimbot.Config.Enabled = v end, "Aim at the closest enemy to your cursor")
    w:AddSlider("Smoothness", 1, 100, 25, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddSlider("FOV Radius", 20, 800, 120, "px", 0, function(v) Aimbot.Config.FOV = v end)
    w:AddDropdown("Target Part", { "Head", "HumanoidRootPart", "Torso", "UpperTorso" }, "Head", function(v) Aimbot.Config.TargetPart = v end)
    w:AddToggle("Show FOV Circle", false, function(v) Aimbot.Config.ShowFOV = v end)
    w:AddToggle("Team Check", true, function(v) Aimbot.Config.TeamCheck = v end, "Ignore teammates")
    w:AddToggle("Wall Check", false, function(v) Aimbot.Config.WallCheck = v end, "Only target visible players")
    w:AddToggle("Prediction", false, function(v) Aimbot.Config.Prediction = v and 0.14 or 0 end, "Lead moving targets")

    w:AddSection("Visuals (ESP)")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end, "Highlight + name/distance/HP")
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Health", true, function(v) ESP.Config.Health = v end)
    w:AddToggle("Team Check (ESP)", false, function(v) ESP.Config.TeamCheck = v; espRefreshVisibility() end)
    w:AddSlider("ESP Distance", 100, 5000, 1500, "studs", 0, function(v) ESP.Config.MaxDistance = v end)

    w:AddSection("Triggerbot")
    w:AddToggle("Enabled", false, function(v) Triggerbot.Config.Enabled = v end, "Auto-fire when crosshair is on an enemy")
    w:AddSlider("Delay", 0, 0.5, 0.05, "s", 2, function(v) Triggerbot.Config.Delay = v end)
    w:AddToggle("Team Check (Trigger)", true, function(v) Triggerbot.Config.TeamCheck = v end)

    w:AddSection("Hitbox")
    w:AddToggle("Hitbox Expander", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end, "Enlarge enemy hitboxes")
    w:AddSlider("Hitbox Size", 1, 30, 10, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)
    w:AddSlider("Transparency", 0, 1, 0.6, "", 2, function(v) Hitbox.Config.Transparency = v; Hitbox.Refresh() end)

    w:AddSection("Local Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed Value", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD + Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 60, "", 0, function(v) Movement.Fly.Speed = v end)

    if extraSetup then extraSetup(w) end

    w:AddSection("Teleport")
    w:AddDropdown("Player", getPlayerNames(false), Players:GetPlayers()[1] and Players:GetPlayers()[1].Name or "nil", function(v)
        w._tpTarget = v
    end)
    w:AddButton("Teleport To Player", function()
        local p = findPlayerByName(w._tpTarget or "")
        if p then teleportToPlayer(p); notify(gameName, "Teleported to " .. p.Name, 2.5) else notify(gameName, "Player not found", 2.5, Theme.Red) end
    end)
    notify(gameName, "Combat suite loaded.", 3, accentColor)
    return w
end

--==============================================================================
--// GAME MODULES
--==============================================================================

--===== ARSENAL =====
local function Arsenal()
    local w = buildFPSWindow("Arsenal", Color3.fromRGB(255, 90, 90))
    w:AddSection("Arsenal Extras")
    w:AddToggle("Auto Respawn", false, function(v)
        w._autoRespawn = v
    end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddButton("Force Respawn", function()
        pcall(function() LocalPlayer.Character:BreakJoints() end)
    end)
    w:AddButton("Fullbright", function()
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
    end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 100, 25, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddSection("Server")
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    -- auto respawn loop
    task.spawn(function()
        while true do
            task.wait(1)
            if w._autoRespawn then
                if not isAlive() then
                    pcall(function()
                        local hum = getHum()
                        if hum then hum.Health = 0 end
                    end)
                end
            end
        end
    end)
    return w
end

--===== RIVALS =====
local function Rivals()
    local w = buildFPSWindow("Rivals", Color3.fromRGB(70, 150, 255))
    w:AddSection("Rivals Extras")
    w:AddToggle("Always Headshot (Target Head)", true, function(v) Aimbot.Config.TargetPart = v and "Head" or "HumanoidRootPart" end)
    w:AddToggle("Anti Flash", false, function(v)
        if v then Lighting.TimeOfDay = "14:00:00"; Lighting.Brightness = 2; Lighting.FogEnd = 9e9 end
    end)
    w:AddToggle("No Recoil (steady cam)", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Auto Dodge Players", false, function(v) AutoDodgePlayer:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 100, 25, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddSection("Server")
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end

--===== HYPERSHOT =====
local function Hypershot()
    local w = buildFPSWindow("Hypershot", Color3.fromRGB(255, 170, 60))
    w:AddSection("Hypershot Extras")
    w:AddToggle("Fast Ball Charge", false, function(v) w._fastCharge = v end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddButton("Center Camera", function()
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, 0, 0)
    end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 100, 25, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._fastCharge then fireRemotes("charge"); fireRemotes("ball") end
        end
    end)
    return w
end

--===== COUNTERBLOX  (Z3US supported) =====
local function Counterblox()
    local w = buildFPSWindow("Counterblox", Color3.fromRGB(255, 200, 60))
    w:AddSection("Counterblox Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end, "Redirect shots to nearest target")
    w:AddToggle("Bunny Hop", false, function(v) w._bhop = v end)
    w:AddToggle("No Recoil", false, function(v) w._noRecoil = v end)
    w:AddToggle("Instant Defuse (touch bomb)", false, function(v) w._defuse = v end)
    w:AddToggle("Auto Plant (best-effort)", false, function(v) w._plant = v end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._bhop then
                local h = getHum(); local r = getRoot()
                if h and r and h.FloorMaterial ~= Enum.Material.Air then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            if w._noRecoil then
                -- keep camera steady (no recoil emulation)
            end
            if w._defuse then
                local root = getRoot()
                if root then touchNamed(root, { "bomb", "c4", "defuse" }, 25) end
            end
            if w._plant then fireRemotes("plant"); fireRemotes("bomb") end
        end
    end)
    return w
end

--===== GUNFIGHT ARENA  (Z3US supported) =====
local function GunfightArena()
    local w = buildFPSWindow("Gunfight Arena", Color3.fromRGB(255, 110, 90))
    w:AddSection("Gunfight Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) w._bhop = v end)
    w:AddToggle("Auto Reload", false, function(v) w._reload = v end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._bhop then
                local h = getHum(); local r = getRoot()
                if h and r and h.FloorMaterial ~= Enum.Material.Air then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            if w._reload then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
            end
        end
    end)
    return w
end

--===== PLANKS  (Z3US supported - FPS) =====
local function Planks()
    local w = buildFPSWindow("Planks", Color3.fromRGB(120, 200, 120))
    w:AddSection("Planks Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) w._noRecoil = v end)
    w:AddToggle("Bunny Hop", false, function(v) w._bhop = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 50, 20, "studs", 0, function(v) w._arange = v end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._bhop then
                local h = getHum(); local r = getRoot()
                if h and r and h.FloorMaterial ~= Enum.Material.Air then
                    h:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 20, false, true)) do swingTool() end end
        end
    end)
    return w
end

--===== JAILBREAK =====
local function Jailbreak()
    local w = createWindow("Jailbreak", "Open World Suite", 480, 560,
        UDim2.new(0.5, -240 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 300, 60, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 500, 80, "", 0, function(v) Movement.Fly.Speed = v end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)

    w:AddSection("Teleport - Locations")
    local jbLocs = {
        { name = "Bank",    pos = Vector3.new(30, 5, -500) },
        { name = "Jewelry", pos = Vector3.new(150, 5, -100) },
        { name = "Gas Station", pos = Vector3.new(-300, 5, 100) },
        { name = "Donut Shop", pos = Vector3.new(260, 5, -250) },
        { name = "Police Station", pos = Vector3.new(-700, 5, -300) },
        { name = "Prison Cells", pos = Vector3.new(-900, 5, -100) },
        { name = "Criminal Base", pos = Vector3.new(-220, 5, 580) },
        { name = "Garage", pos = Vector3.new(-330, 5, 30) },
        { name = "Train Spawn", pos = Vector3.new(1800, 5, 100) },
        { name = "Power Plant", pos = Vector3.new(740, 5, -1200) },
        { name = "Museum", pos = Vector3.new(690, 5, -240) },
        { name = "Airport", pos = Vector3.new(-1700, 5, -400) },
    }
    for _, loc in ipairs(jbLocs) do
        w:AddButton("TP: " .. loc.name, function()
            if teleportTo(loc.pos) then notify("Jailbreak", "Teleported to " .. loc.name, 2.5) end
        end)
    end

    w:AddSection("Vehicle")
    w:AddToggle("Infinite Vehicle Nitro", false, function(v) w._nitro = v end)
    w:AddButton("Flip Vehicle", function()
        local r = getRoot()
        local seat = r and r.Parent:FindFirstChildOfClass("VehicleSeat", true)
        pcall(function()
            for _, s in ipairs(Workspace:GetDescendants()) do
                if s:IsA("VehicleSeat") and s.Occupant then
                    s.CFrame = s.CFrame * CFrame.Angles(0, 0, 0)
                    break
                end
            end
        end)
    end)

    w:AddSection("Auto")
    w:AddToggle("Auto Rob Loop (test)", false, function(v) w._autoRob = v end)
    w:AddButton("Bail / Arrest Shield", function()
        notify("Jailbreak", "Use Noclip to walk out of cells.", 3, Theme.Yellow)
    end)

    task.spawn(function()
        while true do
            task.wait(0.4)
            if w._nitro then
                pcall(function()
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("VehicleSeat") then
                            d:SetAttribute("BoostActive", true)
                        end
                    end
                end)
            end
            if w._autoRob then
                pcall(function()
                    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                        if r:IsA("RemoteEvent") and (r.Name:lower():find("rob") or r.Name:lower():find("collect") or r.Name:lower():find("money")) then
                            r:FireServer()
                        end
                    end
                end)
            end
        end
    end)
    notify("Jailbreak", "Loaded. Teleport coords are approximations for your copy.", 4, Theme.Green)
    return w
end

--===== COMBAT ARENA =====
local function CombatArena()
    local w = createWindow("Combat Arena", "Melee / Reach Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Combat")
    w:AddToggle("Reach / Hitbox Expand", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end)
    w:AddSlider("Reach Size", 1, 40, 14, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)
    w:AddToggle("Auto Swing (Tool)", false, function(v) w._autoSwing = v end)
    w:AddSlider("Swing Delay", 0.05, 1, 0.2, "s", 2, function(v) w._swingDelay = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 5, 80, 25, "studs", 0, function(v) w._auraRange = v end)

    w:AddSection("Aim / Visuals")
    w:AddToggle("Aimbot", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddSlider("Aim Smooth", 1, 100, 30, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddToggle("ESP", false, function(v) ESP.Enable(v) end)

    w:AddSection("Local")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 250, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)

    task.spawn(function()
        while true do
            task.wait(0.05)
            if w._autoSwing and isAlive() then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
                task.wait(w._swingDelay or 0.2)
            end
            if w._aura and isAlive() then
                local root = getRoot()
                if root then
                    local range = w._auraRange or 25
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                            if dist <= range then
                                pcall(function()
                                    local tool = getChar():FindFirstChildOfClass("Tool")
                                    if tool then tool:Activate() end
                                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Combat Arena", "Loaded.", 3, Theme.Red)
    return w
end

--===== STEAL A BRAINROT =====
local function StealABrainrot()
    local w = createWindow("Steal a Brainrot", "Collection Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 300, 70, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item ESP (test)", false, function(v) w._itemEsp = v end)
    w:AddToggle("Tracers", false, function(v) ESP.Config.Tracers = v end)

    w:AddSection("Auto")
    w:AddToggle("Auto Collect Nearby", false, function(v) w._autoCollect = v end)
    w:AddSlider("Collect Range", 10, 200, 60, "studs", 0, function(v) w._collectRange = v end)
    w:AddToggle("Auto Steal (touch nearest player)", false, function(v) w._autoSteal = v end)

    w:AddSection("Teleport")
    w:AddButton("Teleport to Random Player", function()
        local list = getPlayerNames(false)
        if #list > 0 then
            local p = findPlayerByName(list[math.random(1,#list)])
            if p then teleportToPlayer(p) end
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if not root then else
                if w._autoCollect then
                    local range = w._collectRange or 60
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if (d:IsA("Model") or d:IsA("BasePart")) and not d:IsDescendantOf(getChar()) then
                            local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if part then
                                local dist = (part.Position - root.Position).Magnitude
                                if dist <= range then
                                    if d:IsA("Model") and d.PrimaryPart then
                                        pcall(function() firetouchinterest(root, d.PrimaryPart, 0) end)
                                    elseif d:IsA("BasePart") then
                                        pcall(function() firetouchinterest(root, d, 0) end)
                                    end
                                end
                            end
                        end
                    end
                end
                if w._autoSteal then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                            if d <= 12 then
                                pcall(function() firetouchinterest(root, plr.Character.HumanoidRootPart, 0) end)
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Steal a Brainrot", "Loaded.", 3, Theme.Accent)
    return w
end

--===== MURDER MYSTERY 2 =====
local function MurderMystery2()
    local w = createWindow("Murder Mystery 2", "Role & Survival Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Role ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Highlight Murderer (Red)", false, function(v) w._hlMurderer = v end)
    w:AddToggle("Highlight Sheriff/Hero (Blue)", false, function(v) w._hlSheriff = v end)
    w:AddToggle("Murderer Alert", false, function(v) w._alertMurder = v end, "Notify when a killer is near")

    w:AddSection("Items")
    w:AddToggle("Gun / Item ESP", false, function(v) w._itemEsp = v end)
    w:AddToggle("Auto Pick Up Gun (test)", false, function(v) w._autoGun = v end)

    w:AddSection("Survival")
    w:AddToggle("Murderer Safe Zone (auto fly away)", false, function(v) w._safe = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 100, 40, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)

    w:AddSection("Bystander")
    w:AddButton("Show Everyone Role Colors", function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hl = plr.Character:FindFirstChild("ESP_HL")
                if hl then hl.FillColor = Color3.fromRGB(120,120,120) end
            end
        end
        notify("MM2", "Neutral colors applied.", 3)
    end)

    -- murderer detection: a player holding the knife tool / holding weapon
    local alerted = {}
    task.spawn(function()
        while true do
            task.wait(0.5)
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hasKnife = false
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") then
                            local n = item.Name:lower()
                            if n:find("knife") or n:find("sword") or n:find("blade") or n:find("axe") then
                                hasKnife = true
                            end
                        end
                    end
                    local root = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hasKnife and root then
                        if w._hlMurderer then
                            local hl = plr.Character:FindFirstChild("ESP_HL") or (ESP.Enable(true) and plr.Character:FindFirstChild("ESP_HL"))
                            if hl then hl.FillColor = Color3.fromRGB(235, 40, 50) end
                        end
                        local myroot = getRoot()
                        if w._alertMurder and myroot then
                            local d = (root.Position - myroot.Position).Magnitude
                            if d < 40 and not alerted[plr] then
                                alerted[plr] = true
                                notify("âš  MURDERER NEAR", plr.Name .. " (" .. math.floor(d) .. "m)", 4, Theme.Red)
                            elseif d >= 60 then
                                alerted[plr] = nil
                            end
                        end
                    end
                    local hasGun = false
                    for _, item in ipairs(plr.Character:GetChildren()) do
                        if item:IsA("Tool") and (item.Name:lower():find("gun") or item.Name:lower():find("pistol") or item.Name:lower():find("revolver")) then
                            hasGun = true
                        end
                    end
                    if hasGun and w._hlSheriff then
                        local hl = plr.Character:FindFirstChild("ESP_HL")
                        if hl then hl.FillColor = Color3.fromRGB(70, 150, 255) end
                    end
                end
            end
            -- auto gun
            if w._autoGun then
                local root = getRoot()
                if root then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("Tool") and d.Name:lower():find("gun") then
                            local handle = d:FindFirstChild("Handle") or d.PrimaryPart
                            if handle and (handle.Position - root.Position).Magnitude < 30 then
                                pcall(function() firetouchinterest(root, handle, 0) end)
                            end
                        end
                    end
                end
            end
            -- safe zone: if murderer within 25 studs, fly up
            if w._safe then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local killer = false
                        for _, item in ipairs(plr.Character:GetChildren()) do
                            if item:IsA("Tool") and item.Name:lower():find("knife") then killer = true end
                        end
                        local myroot = getRoot()
                        if killer and myroot and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local d = (plr.Character.HumanoidRootPart.Position - myroot.Position).Magnitude
                            if d < 25 then
                                myroot.CFrame = myroot.CFrame + Vector3.new(0, 8, 0)
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Murder Mystery 2", "Loaded. Role detection is heuristic.", 4, Theme.Red)
    return w
end

--===== BLADE BALL =====
local function BladeBall()
    local w = createWindow("Blade Ball", "Auto-Parry Suite", 460, 540,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Auto Parry")
    w:AddToggle("Auto Parry", false, function(v) w._parry = v end, "Press the parry key when the ball is close")
    w:AddSlider("Parry Distance", 5, 60, 18, "studs", 0, function(v) w._parryDist = v end)
    w:AddToggle("Spam Parry Mode", false, function(v) w._spam = v end, "Continuously parry (curved balls)")
    w:AddSlider("Spam Interval", 0.05, 1, 0.18, "s", 2, function(v) w._spamInt = v end)
    w:AddKeybind("Parry Key", Enum.KeyCode.F, function(key) w._parryKey = key end)
    w._parryKey = Enum.KeyCode.F

    w:AddSection("Ball Visuals")
    w:AddToggle("Ball ESP / Tracker", false, function(v) w._ballEsp = v end)
    w:AddToggle("Ball Hitbox Expand", false, function(v) w._ballHB = v end)
    w:AddSlider("Ball Hitbox Size", 1, 60, 14, "studs", 1, function(v) w._ballHBSize = v end)

    w:AddSection("Local Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 150, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    local lastSpam = 0
    local function findBall()
        local ball = Workspace:FindFirstChild("Ball")
        if not ball then
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and (d.Name:lower():find("ball") or d.Name:lower():find("volley")) and not d:IsDescendantOf(getChar() or Workspace) then
                    return d
                end
            end
        end
        return ball and (ball:IsA("BasePart") and ball or ball:FindFirstChildWhichIsA("BasePart"))
    end

    RunService.Heartbeat:Connect(function()
        if not (w._parry or w._spam) then return end
        local ball = findBall()
        local root = getRoot()
        if not (ball and root) then return end
        local dist = (ball.Position - root.Position).Magnitude
        local shouldParry = false
        if w._spam then
            if tick() - lastSpam >= (w._spamInt or 0.18) then
                lastSpam = tick()
                shouldParry = true
            end
        elseif w._parry and dist <= (w._parryDist or 18) then
            shouldParry = true
        end
        if shouldParry then
            local key = w._parryKey or Enum.KeyCode.F
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end)
            -- fallback: also try to click
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
            end)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            local ball = findBall()
            if ball then
                if w._ballHB then
                    ball.Size = Vector3.new(w._ballHBSize or 14, w._ballHBSize or 14, w._ballHBSize or 14)
                    ball.Material = Enum.Material.ForceField
                end
                if w._ballEsp then
                    local hl = ball:FindFirstChild("BallESP")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "BallESP"
                        hl.FillColor = Color3.fromRGB(255, 200, 0)
                        hl.FillTransparency = 0.4
                        hl.Parent = ball
                    end
                    hl.Enabled = true
                else
                    local hl = ball:FindFirstChild("BallESP")
                    if hl then hl.Enabled = false end
                end
            end
        end
    end)
    notify("Blade Ball", "Auto-parry loaded. Adjust distance for your copy.", 4, Theme.Yellow)
    return w
end

--===== TOWER OF HELL =====
local function TowerOfHell()
    local w = createWindow("Tower of Hell", "Obby Suite", 460, 540,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 400, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end, "Click anywhere to teleport there")

    w:AddSection("Win / Progress")
    w:AddButton("Teleport to Top / Finish", function()
        local highest = nil
        local highestY = -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > highestY and (n:find("finish") or n:find("portal") or n:find("teleport") or n:find("win") or n:find("goal") or n:find("top")) then
                    highestY = d.Position.Y
                    highest = d
                end
            end
        end
        if highest then
            teleportTo(highest.Position + Vector3.new(0, 5, 0))
            notify("ToH", "Teleported near finish.", 3, Theme.Green)
        else
            -- fallback: teleport very high
            local r = getRoot()
            if r then r.CFrame = CFrame.new(r.Position + Vector3.new(0, 600, 0)) end
            notify("ToH", "Teleported high (find the portal).", 3, Theme.Yellow)
        end
    end)
    w:AddButton("Teleport UP 250 studs", function()
        local r = getRoot()
        if r then r.CFrame = CFrame.new(r.Position + Vector3.new(0, 250, 0)) end
    end)
    w:AddToggle("Auto Skip (loop up)", false, function(v) w._autoSkip = v end)
    w:AddSlider("Skip Amount", 50, 600, 250, "studs", 0, function(v) w._skipAmt = v end)

    w:AddSection("Safety")
    w:AddToggle("Disable Kill Bricks", false, function(v) w._noKill = v end, "Make damage parts harmless")
    w:AddToggle("God Mode (anti fall)", false, function(v) w._god = v end)

    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._autoSkip then
                local r = getRoot()
                if r then r.CFrame = CFrame.new(r.Position + Vector3.new(0, w._skipAmt or 250, 0)) end
                task.wait(0.6)
            end
            if w._noKill then
                pcall(function()
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("BasePart") then
                            local n = d.Name:lower()
                            if n:find("kill") or n:find("lava") or n:find("danger") or n:find("damage") then
                                d.CanTouch = false
                            end
                        end
                    end
                end)
            end
            if w._god then
                local h = getHum()
                if h then h.Health = h.MaxHealth end
            end
        end
    end)
    notify("Tower of Hell",