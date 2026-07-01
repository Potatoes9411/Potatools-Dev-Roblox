 and _animMotor and _animMotor.Parent) then return end
    local frames = _auraFrames[SwingAnim.Settings.Style] or _auraFrames.Normal
    local cur = frames[_animIndex]
    if cur and (tick() - _animClock) >= cur.Time then
        _animMotor.C0 = cur.CFrame
        _animIndex = _animIndex + 1
        _animClock = tick()
        if _animIndex > #frames then _animIndex = 1 end
    end
end)
function SwingAnim.OnToggle(state)
    if not state and _animMotor then pcall(function() _animMotor:Destroy() end); _animMotor = nil end
end
-- trigger the swing anim whenever KillAura swings
local _origSwingTool = swingTool
swingTool = function(...)
    playSwingAnim()
    return _origSwingTool(...)
end

------------------------------------------------------------
-- ZOOM  (vape Zoom: smooth FOV zoom on a held key)
------------------------------------------------------------
local Zoom = makeModule("Zoom", "Render", { FOV = 30, Key = Enum.KeyCode.Z })
local _zoomOldFOV
RunService.RenderStepped:Connect(function()
    if not Zoom.Enabled then
        if _zoomOldFOV then Camera.FieldOfView = _zoomOldFOV; _zoomOldFOV = nil end
        return
    end
    if UserInputService:IsKeyDown(Zoom.Settings.Key) then
        if not _zoomOldFOV then _zoomOldFOV = Camera.FieldOfView end
        Camera.FieldOfView = Camera.FieldOfView + (Zoom.Settings.FOV - Camera.FieldOfView) * 0.2
    else
        if _zoomOldFOV then
            Camera.FieldOfView = Camera.FieldOfView + (_zoomOldFOV - Camera.FieldOfView) * 0.2
            if math.abs(Camera.FieldOfView - _zoomOldFOV) < 0.5 then Camera.FieldOfView = _zoomOldFOV; _zoomOldFOV = nil end
        end
    end
end)

------------------------------------------------------------
-- TRAJECTORIES  (vape Trajectories: predict projectile arc with gravity)
------------------------------------------------------------
local Trajectories = makeModule("Trajectories", "Render", { Speed = 100, Gravity = 196 })
local _trajParts = {}
local function clearTraj()
    for _, p in ipairs(_trajParts) do pcall(function() p:Destroy() end) end
    _trajParts = {}
end
RunService.RenderStepped:Connect(function()
    if not Trajectories.Enabled then clearTraj(); return end
    clearTraj()
    local root = getRoot()
    if not root then return end
    -- show arc in the look direction
    local pos = root.Position + Vector3.new(0, 2, 0)
    local vel = Camera.CFrame.LookVector * Trajectories.Settings.Speed
    local g = Trajectories.Settings.Gravity
    local dt = 0.06
    for i = 1, 60 do
        pos = pos + vel * dt
        vel = vel - Vector3.new(0, g * dt, 0)
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.3, 0.3, 0.3)
        p.Material = Enum.Material.Neon
        p.Color = Color3.fromRGB(255, 200, 80)
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CFrame = CFrame.new(pos)
        p.Parent = Workspace
        table.insert(_trajParts, p)
        if pos.Y < -50 then break end
    end
end)

------------------------------------------------------------
-- AUTO RESPAWN  (vape AutoRespawn: respawn when dead)
------------------------------------------------------------
local AutoRespawn = makeModule("AutoRespawn", "Player", { Delay = 0.5 })
RunService.Heartbeat:Connect(function()
    if not AutoRespawn.Enabled then return end
    if not isAlive() then
        if not AutoRespawn._t or tick() - AutoRespawn._t > AutoRespawn.Settings.Delay then
            AutoRespawn._t = tick()
            pcall(function() LocalPlayer:LoadCharacter() end)
        end
    end
end)

------------------------------------------------------------
-- INFINITE ARROWS / TOOLS DUPE (best-effort remote spam)
------------------------------------------------------------
local AutoGive = makeModule("AutoGive", "World", {})
RunService.Heartbeat:Connect(function()
    if not AutoGive.Enabled then return end
    fireRemotes("give"); fireRemotes("equip")
end)

------------------------------------------------------------
-- ANTI AIM  (vape AntiAim: jitter the character's facing to dodge aimbots)
------------------------------------------------------------
local AntiAim = makeModule("AntiAim", "Combat", { Mode = "Spin", Speed = 30 })
RunService.RenderStepped:Connect(function(dt)
    if not AntiAim.Enabled then return end
    local root = getRoot()
    if not root then return end
    pcall(function()
        if AntiAim.Settings.Mode == "Spin" then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(AntiAim.Settings.Speed) * dt * 6, 0)
        elseif AntiAim.Settings.Mode == "Jitter" then
            local ang = (math.random() > 0.5 and 1 or -1) * math.random(30, 150)
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(ang) * dt * 6, 0)
        elseif AntiAim.Settings.Mode == "Reverse" then
            local _, y, _ = root.CFrame:ToOrientation()
            root.CFrame = CFrame.new(root.Position) * CFrame.fromOrientation(0, y + math.pi, 0)
        end
    end)
end)

------------------------------------------------------------
-- AUTO HEAL  (continuously re-fill the local humanoid's health)
------------------------------------------------------------
local AutoHeal = makeModule("AutoHeal", "Player", { MinHealth = 50 })
RunService.Heartbeat:Connect(function()
    if not AutoHeal.Enabled then return end
    local h = getHum()
    if h and h.Health < (AutoHeal.Settings.MinHealth or 50) then
        pcall(function() h.Health = h.MaxHealth end)
        trySetStat("health", 1e9)
    end
end)

------------------------------------------------------------
-- FAST USE  (rapidly activate the held tool)
------------------------------------------------------------
local FastUse = makeModule("FastUse", "Combat", { Delay = 0.05 })
local _fuLast = 0
RunService.Heartbeat:Connect(function()
    if not FastUse.Enabled then return end
    if tick() - _fuLast < (FastUse.Settings.Delay or 0.05) then return end
    _fuLast = tick()
    pcall(function()
        local tool = getChar() and getChar():FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
    end)
end)

------------------------------------------------------------
-- MOB ESP  (highlight all NPCs / non-player humanoids)
------------------------------------------------------------
local MobESP = makeModule("MobESP", "Render", { Color = Color3.fromRGB(255, 120, 120) })
local _mobHL = {}
function MobESP.OnToggle(state)
    if not state then
        for _, h in ipairs(_mobHL) do pcall(function() h:Destroy() end) end
        _mobHL = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not MobESP.Enabled then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            if not d:GetAttribute("MobESP") then
                d:SetAttribute("MobESP", true)
                local hl = Instance.new("Highlight")
                hl.Name = "MobESP_HL"
                hl.FillColor = MobESP.Settings.Color
                hl.FillTransparency = 0.4
                hl.Parent = d
                table.insert(_mobHL, hl)
            end
        end
    end
end)

------------------------------------------------------------
-- NO SLOWDOWN  (reset WalkSpeed if a slowdown is applied)
------------------------------------------------------------
local NoSlowdown = makeModule("NoSlowdown", "Movement", { Speed = 16 })
local _nsOldWalkSpeed
RunService.Heartbeat:Connect(function()
    if not NoSlowdown.Enabled then return end
    local h = getHum()
    if h and h.WalkSpeed < NoSlowdown.Settings.Speed then
        h.WalkSpeed = NoSlowdown.Settings.Speed
    end
end)

------------------------------------------------------------
-- AUTO PICKUP / COLLECT (touch all "pickup"-named parts nearby)
------------------------------------------------------------
local AutoPickup = makeModule("AutoPickup", "World", { Range = 80 })
RunService.Heartbeat:Connect(function()
    if not AutoPickup.Enabled then return end
    local root = getRoot()
    if not root then return end
    touchNamed(root, { "pickup", "collect", "drop", "loot", "gem", "coin", "item", "reward" }, AutoPickup.Settings.Range)
end)

------------------------------------------------------------
-- VAPE "LEGIT" HUD FRAMEWORK
-- Faithfully replicates vape.Legit HUD modules using REAL Roblox objects:
-- TextLabel HUDs, the Stats service (FPS/Ping/Memory), tweened keystroke
-- widgets, Lighting objects (Sky/Bloom/ColorCorrection), a Motor6D cape,
-- a MeshPart ChinaHat, and a Trail-based breadcrumb trail.
------------------------------------------------------------

-- Movable HUD container (top-left), separate from feature windows.
local LegitHolder
local function getLegitHolder()
    if LegitHolder and LegitHolder.Parent then return LegitHolder end
    LegitHolder = Instance.new("Frame")
    LegitHolder.Name = "LegitHUD"
    LegitHolder.Size = UDim2.new(0, 130, 0, 0)
    LegitHolder.Position = UDim2.new(0, 14, 0, 14)
    LegitHolder.BackgroundColor3 = Theme.BackgroundDark
    LegitHolder.BackgroundTransparency = 1
    LegitHolder.BorderSizePixel = 0
    LegitHolder.ZIndex = 40
    LegitHolder.AutomaticSize = Enum.AutomaticSize.Y
    LegitHolder.Visible = false
    LegitHolder.Parent = ScreenGui
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Left
    lay.Parent = LegitHolder
    return LegitHolder
end

-- Generic HUD module: a draggable TextLabel that updates via a callback.
local LegitModules = {}
local function makeHUDModule(name, tooltip, updateFn, defaultSize)
    local m = {
        Name = name,
        Tooltip = tooltip,
        Enabled = false,
        Label = nil,
        Size = UDim2.new(0, (defaultSize or 100), 0, 36),
        Font = Enum.Font.Gotham,
        BGOpacity = 0.5,
        BGColor = Color3.fromHSV(0, 0, 0),
    }
    function m:Create()
        local lbl = Instance.new("TextLabel")
        lbl.Name = name
        lbl.Size = self.Size
        lbl.BackgroundTransparency = 1 - self.BGOpacity
        lbl.BackgroundColor3 = self.BGColor
        lbl.TextSize = 15
        lbl.Font = self.Font
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.Text = name .. " ..."
        lbl.ZIndex = 41
        lbl.Parent = getLegitHolder()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = lbl
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = lbl
        self.Label = lbl
        makeDraggable(lbl, lbl)
        getLegitHolder().Visible = true
    end
    function m:Set(v)
        self.Enabled = v and true or false
        if v then
            if not self.Label then self:Create() else self.Label.Visible = true; getLegitHolder().Visible = true end
            task.spawn(function()
                while self.Enabled and self.Label and self.Label.Parent do
                    pcall(updateFn, self.Label)
                    task.wait(self._delay or 0.1)
                end
            end)
        else
            if self.Label then self.Label.Visible = false end
            -- hide holder if nothing visible
            local any = false
            for _, mod in pairs(LegitModules) do if mod.Enabled then any = true; break end end
            if not any then getLegitHolder().Visible = false end
        end
    end
    LegitModules[name] = m
    return m
end

-- FPS module (uses real Stats.PerformanceStats.Fps when available).
local FPSModule = makeHUDModule("FPS", "Shows the current framerate", function(lbl)
    pcall(function()
        local v = math.floor(Workspace:GetRealPhysicsFPS())
        lbl.Text = v .. " FPS"
    end)
end)
FPSModule._delay = 0.25

-- Ping module (real Stats.PerformanceStats.Ping).
local PingModule = makeHUDModule("Ping", "Connection speed to the server", function(lbl)
    pcall(function()
        local perf = Stats:FindFirstChild("PerformanceStats")
        local p = perf and perf:FindFirstChild("Ping")
        local v = p and tonumber(p:GetValue()) or 0
        local col = v < 80 and "#7ad18b" or (v < 160 and "#f5c44c" or "#eb4d5c")
        lbl.Text = math.floor(v) .. " ms"
    end)
end)
PingModule._delay = 1

-- Memory module (real Stats.PerformanceStats.Memory).
local MemoryModule = makeHUDModule("Memory", "Memory used by Roblox", function(lbl)
    pcall(function()
        local perf = Stats:FindFirstChild("PerformanceStats")
        local m = perf and perf:FindFirstChild("Memory")
        local v = m and tonumber(m:GetValue()) or 0
        lbl.Text = math.floor(v) .. " MB"
    end)
end)
MemoryModule._delay = 1

-- Speedmeter module (real velocity in studs/sec).
local SpeedmeterModule = makeHUDModule("Speed", "Average velocity in studs", function(lbl)
    local root = getRoot()
    if root then
        lbl.Text = math.floor(root.AssemblyLinearVelocity.Magnitude) .. " sps"
    else
        lbl.Text = "0 sps"
    end
end)
SpeedmeterModule._delay = 0.2

-- Keystrokes module: real W/A/S/D/Space widgets with tweened colours.
local Keystrokes = {
    Enabled = false, _keys = {}, _holder = nil,
    BGOpacity = 0.5, BGColor = Color3.fromHSV(0, 0, 0),
}
local function ksWidget(keyCode, pos, text)
    local holder = Keystrokes._holder
    local f = Instance.new("Frame")
    f.Name = keyCode.Name
    f.Size = keyCode == Enum.KeyCode.Space and UDim2.new(0, 110, 0, 24) or UDim2.new(0, 34, 0, 36)
    f.BackgroundColor3 = Keystrokes.BGColor
    f.BackgroundTransparency = 1 - Keystrokes.BGOpacity
    f.Position = pos
    f.BorderSizePixel = 0
    f.ZIndex = 42
    f.Parent = holder
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 4); c.Parent = f
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, 0, 1, 0)
    t.Font = Enum.Font.GothamBold
    t.TextSize = keyCode == Enum.KeyCode.Space and 18 or 15
    t.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.Text = text or keyCode.Name
    t.ZIndex = 43
    t.Parent = f
    return f, t
end
local _ksConns = {}
function Keystrokes:Set(v)
    self.Enabled = v and true or false
    if v then
        self._holder = Instance.new("Frame")
        self._holder.Name = "Keystrokes"
        self._holder.Size = UDim2.new(0, 110, 0, 107)
        self._holder.Position = UDim2.new(0, 160, 0, 14)
        self._holder.BackgroundTransparency = 1
        self._holder.ZIndex = 42
        self._holder.Parent = ScreenGui
        makeDraggable(self._holder, self._holder)
        ksWidget(Enum.KeyCode.W, UDim2.new(0, 38, 0, 0), "W")
        ksWidget(Enum.KeyCode.A, UDim2.new(0, 0, 0, 42), "A")
        ksWidget(Enum.KeyCode.S, UDim2.new(0, 38, 0, 42), "S")
        ksWidget(Enum.KeyCode.D, UDim2.new(0, 76, 0, 42), "D")
        ksWidget(Enum.KeyCode.Space, UDim2.new(0, 0, 0, 83), "SPACE")
        local function upd(input)
            local k = input.KeyCode
            local w = self._holder:FindFirstChild(k.Name)
            if w and (k == Enum.KeyCode.W or k == Enum.KeyCode.A or k == Enum.KeyCode.S or k == Enum.KeyCode.D or k == Enum.KeyCode.Space) then
                local pressed = input.UserInputState == Enum.UserInputState.Begin
                pcall(function()
                    TweenService:Create(w, TweenInfo.new(0.1), {
                        BackgroundColor3 = pressed and Color3.fromRGB(255, 255, 255) or self.BGColor,
                        BackgroundTransparency = pressed and 0 or (1 - self.BGOpacity),
                    }):Play()
                    TweenService:Create(w:FindFirstChild("TextLabel"), TweenInfo.new(0.1), {
                        TextColor3 = pressed and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255),
                    }):Play()
                end)
            end
        end
        table.insert(_ksConns, UserInputService.InputBegan:Connect(upd))
        table.insert(_ksConns, UserInputService.InputEnded:Connect(upd))
    else
        if self._holder then self._holder:Destroy(); self._holder = nil end
        for _, c in ipairs(_ksConns) do pcall(function() c:Disconnect() end) end
        _ksConns = {}
    end
end

-- TimeChanger module: real Lighting.TimeOfDay control.
local TimeChanger = { Enabled = false, Value = 12, _old = nil }
function TimeChanger:Set(v)
    self.Enabled = v and true or false
    if v then
        self._old = Lighting.TimeOfDay
        Lighting.TimeOfDay = string.format("%02d:00:00", self.Value)
    else
        if self._old then Lighting.TimeOfDay = self._old; self._old = nil
        else Lighting.TimeOfDay = "12:00:00" end
    end
end

-- Atmosphere/Lighting module: create REAL Lighting objects (Bloom, CC, SunRays, Sky).
local AtmosphereMod = { Enabled = false, _objects = {} }
function AtmosphereMod:Set(v)
    self.Enabled = v and true or false
    if v then
        local function mk(class, props)
            local o = Instance.new(class)
            for k, val in pairs(props) do o[k] = val end
            o.Parent = Lighting
            table.insert(self._objects, o)
            return o
        end
        mk("BloomEffect", { Intensity = 0.6, Size = 24, Threshold = 0.85 })
        mk("SunRaysEffect", { Intensity = 0.12, Spread = 0.7 })
        mk("ColorCorrectionEffect", { Brightness = 0.04, Contrast = 0.12, Saturation = 0.18, TintColor = Color3.fromRGB(255, 248, 240) })
        mk("Atmosphere", { Density = 0.35, Offset = 0.4, Color = Color3.fromRGB(190, 190, 220), Decay = Color3.fromRGB(110, 130, 170), Glare = 0, Haze = 1.6 })
    else
        for _, o in ipairs(self._objects) do pcall(function() o:Destroy() end) end
        self._objects = {}
    end
end

-- Cape module: a real Part welded via Motor6D with a SurfaceGui image,
-- animated by character velocity (faithful to vape Cape).
local Cape = { Enabled = false, _part = nil, _motor = nil, _conn = nil }
function Cape:Set(v)
    self.Enabled = v and true or false
    if v then
        self._part = Instance.new("Part")
        self._part.Size = Vector3.new(2, 4, 0.1)
        self._part.CanCollide = false
        self._part.CanQuery = false
        self._part.Massless = true
        self._part.Transparency = 0
        self._part.Material = Enum.Material.SmoothPlastic
        self._part.Color = Color3.fromRGB(122, 92, 255)
        self._part.CastShadow = false
        self._part.Parent = Workspace
        local surf = Instance.new("SurfaceGui")
        surf.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        surf.Adornee = self._part
        surf.Parent = self._part
        local img = Instance.new("ImageLabel")
        img.Image = "rbxassetid://14637958134"
        img.Size = UDim2.fromScale(1, 1)
        img.BackgroundTransparency = 1
        img.Parent = surf
        local function buildMotor()
            local char = getChar()
            if not char then return end
            if self._motor then self._motor:Destroy() end
            local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or getRoot()
            self._motor = Instance.new("Motor6D")
            self._motor.MaxVelocity = 0.08
            self._motor.Part0 = self._part
            self._motor.Part1 = torso
            self._motor.C0 = CFrame.new(0, 2, 0) * CFrame.Angles(0, math.rad(-90), 0)
            self._motor.C1 = CFrame.new(0, (torso and torso.Size.Y or 2) / 2, 0.45) * CFrame.Angles(0, math.rad(90), 0)
            self._motor.Parent = self._part
        end
        buildMotor()
        self._conn = RunService.RenderStepped:Connect(function()
            local root = getRoot()
            if self._motor and root then
                local velo = math.min(root.AssemblyLinearVelocity.Magnitude, 90)
                self._motor.DesiredAngle = math.rad(6) + math.rad(velo * 0.05) + (velo > 1 and math.abs(math.cos(tick() * 5)) / 3 or 0)
            end
        end)
        self._charConn = LocalPlayer.CharacterAdded:Connect(function() task.wait(0.4); buildMotor() end)
    else
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
        if self._motor then self._motor:Destroy(); self._motor = nil end
        if self._part then self._part:Destroy(); self._part = nil end
    end
end

-- ChinaHat module: a real MeshPart cone welded above the head (vape ChinaHat).
local ChinaHat = { Enabled = false, _hat = nil, _weld = nil, _conn = nil }
function ChinaHat:Set(v)
    self.Enabled = v and true or false
    if v then
        local function build()
            local char = getChar()
            local head = char and char:FindFirstChild("Head")
            if not head then return end
            if self._hat then self._hat:Destroy() end
            self._hat = Instance.new("MeshPart")
            self._hat.Size = Vector3.new(3, 0.7, 3)
            self._hat.Material = Enum.Material.SmoothPlastic
            self._hat.Color = Color3.fromRGB(255, 215, 0)
            self._hat.CanCollide = false
            self._hat.CanQuery = false
            self._hat.Massless = true
            self._hat.MeshId = "http://www.roblox.com/asset/?id=1778999"
            self._hat.Transparency = 0
            self._hat.Parent = Workspace
            self._hat.CFrame = head.CFrame + Vector3.new(0, 1.4, 0)
            self._weld = Instance.new("WeldConstraint")
            self._weld.Part0 = self._hat
            self._weld.Part1 = head
            self._weld.Parent = self._hat
        end
        build()
        self._charConn = LocalPlayer.CharacterAdded:Connect(function() task.wait(0.4); build() end)
    else
        if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
        if self._weld then self._weld:Destroy(); self._weld = nil end
        if self._hat then self._hat:Destroy(); self._hat = nil end
    end
end

-- Breadcrumbs module: a real Trail with two Attachments under the root.
local Breadcrumbs = { Enabled = false, _trail = nil, _a0 = nil, _a1 = nil, _conn = nil }
function Breadcrumbs:Set(v)
    self.Enabled = v and true or false
    if v then
        local function build()
            local root = getRoot()
            if not root then return end
            if self._trail then return end
            self._a0 = Instance.new("Attachment")
            self._a0.Position = Vector3.new(0, 0.1, 0)
            self._a0.Parent = root
            self._a1 = Instance.new("Attachment")
            self._a1.Position = Vector3.new(0, -2.7, 0)
            self._a1.Parent = root
            self._trail = Instance.new("Trail")
            self._trail.Attachment0 = self._a0
            self._trail.Attachment1 = self._a1
            self._trail.FaceCamera = true
            self._trail.Lifetime = 3
            self._trail.Color = ColorSequence.new(Color3.fromRGB(122, 92, 255), Color3.fromRGB(86, 62, 200))
            self._trail.Transparency = NumberSequence.new(0.3, 1)
            self._trail.TextureMode = Enum.TextureMode.Static
            self._trail.Parent = Workspace
        end
        build()
        self._charConn = LocalPlayer.CharacterAdded:Connect(function() task.wait(0.4)
            if self._trail then self._trail:Destroy(); self._trail = nil end
            if self._a0 then self._a0:Destroy(); self._a0 = nil end
            if self._a1 then self._a1:Destroy(); self._a1 = nil end
            build()
        end)
    else
        if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
        if self._trail then self._trail:Destroy(); self._trail = nil end
        if self._a0 then self._a0:Destroy(); self._a0 = nil end
        if self._a1 then self._a1:Destroy(); self._a1 = nil end
    end
end

-- A console/log overlay (faithful to a chat-style debug HUD).
local ConsoleLog = { Enabled = false, _frame = nil, _lines = {}, _list = nil }
function ConsoleLog:Set(v)
    self.Enabled = v and true or false
    if v then
        self._frame = Instance.new("Frame")
        self._frame.Name = "HubConsole"
        self._frame.Size = UDim2.new(0, 300, 0, 180)
        self._frame.Position = UDim2.new(0, 14, 1, -200)
        self._frame.BackgroundColor3 = Theme.BackgroundDark
        self._frame.BackgroundTransparency = 0.1
        self._frame.BorderSizePixel = 0
        self._frame.ZIndex = 40
        self._frame.Parent = ScreenGui
        corner(self._frame, Theme.Rounded)
        stroke(self._frame, Theme.Stroke, 1, 0.3)
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -16, 0, 20)
        title.Position = UDim2.new(0, 8, 0, 4)
        title.Font = Theme.FontBold
        title.TextSize = 12
        title.TextColor3 = Theme.AccentBright
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "  HUB CONSOLE"
        title.ZIndex = 41
        title.Parent = self._frame
        self._list = Instance.new("ScrollingFrame")
        self._list.Size = UDim2.new(1, -8, 1, -30)
        self._list.Position = UDim2.new(0, 4, 0, 26)
        self._list.BackgroundTransparency = 1
        self._list.ScrollBarThickness = 3
        self._list.ScrollBarImageColor3 = Theme.Accent
        self._list.CanvasSize = UDim2.new(0, 0, 0, 0)
        self._list.AutomaticCanvasSize = Enum.AutomaticSize.Y
        self._list.ZIndex = 41
        self._list.Parent = self._frame
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 2)
        lay.Parent = self._list
        makeDraggable(self._frame, title)
    else
        if self._frame then self._frame:Destroy(); self._frame = nil end
        self._lines = {}
    end
end
-- Route prints into the console when it is open.
local _origPrint = print
local function pushLog(msg)
    if not (ConsoleLog.Enabled and ConsoleLog._list) then return end
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.new(1, -8, 0, 14)
    l.Font = Theme.FontMono
    l.TextSize = 11
    l.TextColor3 = Theme.TextDim
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = "> " .. tostring(msg)
    l.Parent = ConsoleLog._list
    table.insert(ConsoleLog._lines, l)
    if #ConsoleLog._lines > 40 then
        local old = table.remove(ConsoleLog._lines, 1)
        if old then old:Destroy() end
    end
end

------------------------------------------------------------
-- ENTITY LIBRARY  (vape entitylib: lightweight player/entity cache)
-- Tracks every valid character with RootPart/Humanoid, with events.
------------------------------------------------------------
local EntityLib = {
    isAlive = false,
    character = {},
    Players = {},
    Events = { LocalAdded = {}, EntityAdded = {}, EntityRemoved = {} },
}
function EntityLib.fire(event, ...)
    for _, fn in ipairs(EntityLib.Events[event] or {}) do pcall(fn, ...) end
end
function EntityLib.onEvent(event, fn)
    table.insert(EntityLib.Events[event], fn)
end
local function refreshSelf()
    local char = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and getHRP(char)
    EntityLib.character = {
        Character = char, Humanoid = hum, RootPart = root,
        Head = char and char:FindFirstChild("Head"),
        HipHeight = hum and hum.HipHeight or 2,
    }
    EntityLib.isAlive = char ~= nil and hum ~= nil and hum.Health > 0 and root ~= nil
end
local function refreshPlayers()
    EntityLib.Players = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(EntityLib.Players, {
                    Player = plr, Character = plr.Character, RootPart = root,
                    Humanoid = hum, Head = plr.Character:FindFirstChild("Head"),
                    Team = plr.Team, Position = root.Position,
                })
            end
        end
    end
end
RunService.Heartbeat:Connect(function()
    local wasAlive = EntityLib.isAlive
    refreshSelf()
    refreshPlayers()
    if EntityLib.isAlive and not wasAlive then
        EntityLib.fire("LocalAdded", EntityLib.character)
    end
end)

------------------------------------------------------------
-- RADAR  (vape Radar: a real minimap Frame with directional player blips)
------------------------------------------------------------
local Radar = {
    Enabled = false,
    Size = 180,
    Range = 200,
    ShowDistance = true,
    TeamCheck = true,
    _frame = nil, _blips = {}, _conn = nil,
}
function Radar:Build()
    if self._frame and self._frame.Parent then return end
    local f = Instance.new("Frame")
    f.Name = "Radar"
    f.Size = UDim2.new(0, self.Size, 0, self.Size)
    f.Position = UDim2.new(0, 14, 1, -self.Size - 14)
    f.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    f.BackgroundTransparency = 0.2
    f.BorderSizePixel = 0
    f.ZIndex = 45
    f.Parent = ScreenGui
    corner(f, UDim.new(1, 0))
    stroke(f, Theme.Stroke, 1, 0.3)
    -- center crosshair
    local ch1 = Instance.new("Frame")
    ch1.Size = UDim2.new(1, 0, 0, 1); ch1.Position = UDim2.new(0, 0, 0.5, 0)
    ch1.BackgroundColor3 = Theme.Stroke; ch1.BorderSizePixel = 0; ch1.ZIndex = 46; ch1.Parent = f
    local ch2 = Instance.new("Frame")
    ch2.Size = UDim2.new(0, 1, 1, 0); ch2.Position = UDim2.new(0.5, 0, 0, 0)
    ch2.BackgroundColor3 = Theme.Stroke; ch2.BorderSizePixel = 0; ch2.ZIndex = 46; ch2.Parent = f
    local selfDot = Instance.new("Frame")
    selfDot.Size = UDim2.new(0, 6, 0, 6)
    selfDot.Position = UDim2.new(0.5, -3, 0.5, -3)
    selfDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    selfDot.BorderSizePixel = 0; selfDot.ZIndex = 47
    corner(selfDot, UDim.new(1, 0)); selfDot.Parent = f
    -- title
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 16)
    title.Position = UDim2.new(0, 0, 0, 4)
    title.Font = Theme.FontBold; title.TextSize = 11
    title.TextColor3 = Theme.AccentBright
    title.Text = "RADAR"
    title.ZIndex = 47; title.Parent = f
    makeDraggable(f, title)
    self._frame = f
end
function Radar:RefreshBlips()
    if not (self.Enabled and self._frame) then return end
    -- clear old blips
    for _, b in ipairs(self._blips) do pcall(function() b:Destroy() end) end
    self._blips = {}
    local root = getRoot()
    if not root then return end
    local half = self.Size / 2
    local range = self.Range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                if not (self.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    -- relative position in world, rotated into camera-space (top-down)
                    local offset = hrp.Position - root.Position
                    -- rotate by camera yaw so "up" = where you look
                    local camYaw = select(2, Camera.CFrame:ToEulerAnglesYXZ())
                    local cosA, sinA = math.cos(-camYaw), math.sin(-camYaw)
                    local rx = offset.X * cosA - offset.Z * sinA
                    local rz = offset.X * sinA + offset.Z * cosA
                    -- map to radar pixels (Z forward = up on radar)
                    local px = (rx / range) * half
                    local py = -(rz / range) * half
                    local dist = offset.Magnitude
                    if dist <= range then
                        local blip = Instance.new("Frame")
                        blip.Size = UDim2.new(0, 7, 0, 7)
                        blip.Position = UDim2.new(0.5, px - 3.5, 0.5, py - 3.5)
                        local col = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(255, 80, 80)
                        blip.BackgroundColor3 = col
                        blip.BorderSizePixel = 0
                        blip.ZIndex = 47
                        corner(blip, UDim.new(1, 0))
                        blip.Parent = self._frame
                        table.insert(self._blips, blip)
                        if self.ShowDistance then
                            local txt = Instance.new("TextLabel")
                            txt.BackgroundTransparency = 1
                            txt.Size = UDim2.new(0, 30, 0, 12)
                            txt.Position = UDim2.new(0.5, px + 4, 0.5, py + 4)
                            txt.Font = Theme.Font; txt.TextSize = 9
                            txt.TextColor3 = Color3.fromRGB(255, 255, 255)
                            txt.Text = math.floor(dist)
                            txt.ZIndex = 47
                            txt.Parent = self._frame
                            table.insert(self._blips, txt)
                        end
                    end
                end
            end
        end
    end
end
function Radar:Set(v)
    self.Enabled = v and true or false
    if v then
        self:Build()
        self._frame.Visible = true
        if not self._conn then
            self._conn = RunService.Heartbeat:Connect(function()
                if self.Enabled then self:RefreshBlips() end
            end)
        end
    else
        if self._frame then self._frame.Visible = false end
    end
end

------------------------------------------------------------
-- BOX ESP / CHAMS  (vape-style corner boxes + chams fill via Highlight)
-- Draws a 2-corner box around each on-screen enemy using Frames.
------------------------------------------------------------
local BoxESP = {
    Enabled = false,
    TeamCheck = true,
    Thickness = 1,
    FillChams = false,
    _boxes = {},
}
function BoxESP:Clear()
    for _, b in ipairs(self._boxes) do pcall(function() for _, p in ipairs(b) do p:Destroy() end end) end
    self._boxes = {}
end
function BoxESP:Set(v)
    self.Enabled = v and true or false
    if not v then self:Clear() end
end
local function makeBoxLine(parent, size, pos, color)
    local l = Instance.new("Frame")
    l.Size = size
    l.Position = pos
    l.BackgroundColor3 = color
    l.BorderSizePixel = 0
    l.ZIndex = 6
    l.Parent = parent
    return l
end
RunService.RenderStepped:Connect(function()
    if not BoxESP.Enabled then
        if #BoxESP._boxes > 0 then BoxESP:Clear() end
        return
    end
    -- refresh set per frame (simple, robust)
    BoxESP:Clear()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if hum and root and head and hum.Health > 0 then
                if not (BoxESP.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    -- chams fill
                    if BoxESP.FillChams then
                        local hl = char:FindFirstChild("BoxChams")
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Name = "BoxChams"
                            hl.FillTransparency = 0.5
                            hl.OutlineTransparency = 0
                            hl.FillColor = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(122, 92, 255)
                            hl.Parent = char
                        end
                    end
                    -- world corners -> screen
                    local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                        local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height * 0.5
                        local topLeft = Vector2.new(rootPos.X - width / 2, headPos.Y)
                        local boxColor = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(255, 255, 255)
                        local holder = Instance.new("Frame")
                        holder.BackgroundTransparency = 1
                        holder.Size = UDim2.new(0, width, 0, height)
                        holder.Position = UDim2.new(0, topLeft.X, 0, topLeft.Y)
                        holder.ZIndex = 6
                        holder.Parent = ScreenGui
                        local t = BoxESP.Thickness
                        local box = {
                            holder,
                            makeBoxLine(holder, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 0, 0), boxColor),
                            makeBoxLine(holder, UDim2.new(1, 0, 0, t), UDim2.new(0, 0, 1, -t), boxColor),
                            makeBoxLine(holder, UDim2.new(0, t, 1, 0), UDim2.new(0, 0, 0, 0), boxColor),
                            makeBoxLine(holder, UDim2.new(0, t, 1, 0), UDim2.new(1, -t, 0, 0), boxColor),
                        }
                        table.insert(BoxESP._boxes, box)
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- TARGET STRAFE  (vape TargetStrafe: orbit the nearest target)
------------------------------------------------------------
local TargetStrafe = makeModule("TargetStrafe", "Movement", { Radius = 6, Speed = 20 })
local _tsAngle = 0
RunService.RenderStepped:Connect(function(dt)
    if not TargetStrafe.Enabled then return end
    local root = getRoot()
    if not root then return end
    local target = nil
    local best = 1e9
    for _, t in ipairs(getTargetsInRange(40, false, true)) do
        if t.dist < best then best = t.dist; target = t end
    end
    if target then
        _tsAngle = _tsAngle + dt * TargetStrafe.Settings.Speed * 0.1
        local center = target.hrp.Position
        local radius = TargetStrafe.Settings.Radius
        local pos = center + Vector3.new(math.cos(_tsAngle) * radius, 3, math.sin(_tsAngle) * radius)
        pcall(function() root.CFrame = CFrame.new(pos, center) end)
    end
end)

------------------------------------------------------------
-- AUTO CLUTCH  (auto-place a block / platform when falling fast)
------------------------------------------------------------
local AutoClutch = makeModule("AutoClutch", "Player", { Speed = -50 })
local _clutchPart
RunService.Heartbeat:Connect(function()
    if not AutoClutch.Enabled then
        if _clutchPart then pcall(function() _clutchPart:Destroy() end); _clutchPart = nil end
        return
    end
    local root = getRoot()
    if not root then return end
    if root.AssemblyLinearVelocity.Y < AutoClutch.Settings.Speed then
        if not _clutchPart then
            _clutchPart = Instance.new("Part")
            _clutchPart.Size = Vector3.new(5, 1, 5)
            _clutchPart.Anchored = true
            _clutchPart.CanCollide = true
            _clutchPart.Material = Enum.Material.ForceField
            _clutchPart.Color = Color3.fromRGB(255, 200, 80)
            _clutchPart.Transparency = 0.4
            _clutchPart.Parent = Workspace
        end
        pcall(function() _clutchPart.CFrame = root.CFrame + Vector3.new(0, -3.5, 0) end)
    elseif _clutchPart then
        pcall(function() _clutchPart:Destroy() end); _clutchPart = nil
    end
end)

------------------------------------------------------------
-- AIM ASSIST  (vape Legit AimAssist: gentle pull toward nearest target)
------------------------------------------------------------
local AimAssist = makeModule("AimAssist", "Combat", { Strength = 0.3, FOV = 100, Reach = 200, TeamCheck = true })
RunService.RenderStepped:Connect(function(dt)
    if not AimAssist.Enabled then return end
    local root = getRoot()
    if not root then return end
    local mousePos = UserInputService:GetMouseLocation()
    local closest, closestMag = nil, AimAssist.Settings.FOV
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local part = plr.Character:FindFirstChild("HumanoidRootPart")
            if part and hum and hum.Health > 0 then
                if not (AimAssist.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        local dist = (part.Position - root.Position).Magnitude
                        if mag <= closestMag and dist <= AimAssist.Settings.Reach then
                            closestMag = mag; closest = part
                        end
                    end
                end
            end
        end
    end
    if closest then
        local aim = CFrame.new(Camera.CFrame.Position, closest.Position)
        local s = math.clamp(AimAssist.Settings.Strength * 0.1, 0.005, 0.5)
        Camera.CFrame = Camera.CFrame:Lerp(aim, s)
    end
end)

------------------------------------------------------------
-- FULLBRIGHT  (vape Fullbright: store & restore Lighting properties)
------------------------------------------------------------
local Fullbright = makeModule("Fullbright", "Render", {})
local _fbOld = {}
function Fullbright.OnToggle(state)
    if state then
        _fbOld.Brightness = Lighting.Brightness
        _fbOld.ClockTime = Lighting.ClockTime
        _fbOld.FogEnd = Lighting.FogEnd
        _fbOld.FogStart = Lighting.FogStart
        _fbOld.GlobalShadows = Lighting.GlobalShadows
        _fbOld.Ambient = Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e9
        Lighting.FogStart = 1e9
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    else
        if _fbOld.Brightness then Lighting.Brightness = _fbOld.Brightness end
        if _fbOld.ClockTime then Lighting.ClockTime = _fbOld.ClockTime end
        if _fbOld.FogEnd then Lighting.FogEnd = _fbOld.FogEnd end
        if _fbOld.FogStart then Lighting.FogStart = _fbOld.FogStart end
        if _fbOld.GlobalShadows ~= nil then Lighting.GlobalShadows = _fbOld.GlobalShadows end
        if _fbOld.Ambient then Lighting.Ambient = _fbOld.Ambient end
    end
end

------------------------------------------------------------
-- MACE  (vape Mace: spawn a falling damaging part above the target)
------------------------------------------------------------
local Mace = makeModule("Mace", "Combat", { Height = 60 })
local _macePart
RunService.Heartbeat:Connect(function()
    if not Mace.Enabled then
        if _macePart then pcall(function() _macePart:Destroy() end); _macePart = nil end
        return
    end
    local root = getRoot()
    if not root then return end
    -- find nearest target
    local target = nil
    local best = 30
    for _, t in ipairs(getTargetsInRange(best, false, true)) do
        if t.dist < best then best = t.dist; target = t end
    end
    if target then
        if not _macePart then
            _macePart = Instance.new("Part")
            _macePart.Size = Vector3.new(3, 3, 3)
            _macePart.Material = Enum.Material.Neon
            _macePart.Color = Color3.fromRGB(255, 60, 60)
            _macePart.CanCollide = false
            _macePart.CanQuery = false
            _macePart.Anchored = false
            _macePart.Parent = Workspace
        end
        pcall(function()
            _macePart.CFrame = CFrame.new(target.hrp.Position + Vector3.new(0, Mace.Settings.Height, 0))
        end)
    elseif _macePart then
        pcall(function() _macePart:Destroy() end); _macePart = nil
    end
end)

------------------------------------------------------------
-- AUTO LEAVE  (vape AutoLeave: leave server on low player count)
------------------------------------------------------------
local AutoLeave = makeModule("AutoLeave", "Player", { MinPlayers = 3 })
RunService.Heartbeat:Connect(function()
    if not AutoLeave.Enabled then return end
    if AutoLeave._t and tick() - AutoLeave._t < 10 then return end
    if #Players:GetPlayers() <= AutoLeave.Settings.MinPlayers then
        AutoLeave._t = tick()
        notify("AutoLeave", "Low player count - hopping server.", 4, Theme.Yellow)
        ServerHop.hop()
    end
end)

------------------------------------------------------------
-- FAKE LAG  (vape FakeLag: freeze your ch