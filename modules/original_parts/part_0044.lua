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
-- FAKE LAG  (vape FakeLag: freeze your character's network position)
------------------------------------------------------------
local FakeLag = makeModule("FakeLag", "Render", { Delay = 0.1 })
local _flAccum, _flFrozen
RunService.RenderStepped:Connect(function(dt)
    if not FakeLag.Enabled then
        if _flFrozen then
            pcall(function() getRoot().AssemblyLinearVelocity = _flFrozen.vel or Vector3.zero end)
            _flFrozen = nil
        end
        return
    end
    local root = getRoot()
    if not root then return end
    _flAccum = (_flAccum or 0) + dt
    if _flAccum >= FakeLag.Settings.Delay then
        _flAccum = 0
        _flFrozen = { vel = root.AssemblyLinearVelocity, cf = root.CFrame }
    elseif _flFrozen then
        -- hold position to create the lag effect
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end)
    end
end)

------------------------------------------------------------
-- HITBOXES VISUALIZER  (vape Hitboxes: show the real hitbox of parts)
------------------------------------------------------------
local Hitboxes = makeModule("Hitboxes", "Render", { Players = true, NPCs = false })
local _hbBoxes = {}
function Hitboxes.OnToggle(state)
    if not state then
        for _, b in ipairs(_hbBoxes) do pcall(function() b:Destroy() end) end
        _hbBoxes = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not Hitboxes.Enabled then return end
    -- clear each refresh
    for _, b in ipairs(_hbBoxes) do pcall(function() b:Destroy() end) end
    _hbBoxes = {}
    local function addBox(part, color)
        local sb = Instance.new("SelectionBox")
        sb.Adornee = part
        sb.Color3 = color
        sb.Transparency = 0.5
        sb.LineThickness = 0.04
        sb.Parent = Workspace
        table.insert(_hbBoxes, sb)
    end
    if Hitboxes.Settings.Players then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then addBox(hrp, Color3.fromRGB(255, 80, 80)) end
            end
        end
    end
    if Hitboxes.Settings.NPCs then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hrp then addBox(hrp, Color3.fromRGB(255, 200, 80)) end
            end
        end
    end
end)

------------------------------------------------------------
-- SONG BEATS  (vape SongBeats: mp3 player with beat-driven FOV pulses)
------------------------------------------------------------
local SongBeats = {
    Enabled = false,
    Volume = 100,
    FOVPulse = true,
    FOVAmount = 5,
    BPM = 120,
    _sound = nil, _oldFOV = nil, _beatTick = 0,
}
function SongBeats:Set(v)
    self.Enabled = v and true or false
    if v then
        if not self._sound then
            self._sound = Instance.new("Sound")
            self._sound.Volume = self.Volume / 100
            self._sound.Parent = Workspace
            -- use a built-in asset id as a placeholder
            self._sound.SoundId = "rbxassetid://1837879082"
        end
        self._oldFOV = Camera.FieldOfView
        self._beatTick = tick()
        pcall(function() self._sound:Play() end)
        notify("SongBeats", "Playing placeholder track (set SoundId to your own).", 4, Theme.Accent)
    else
        if self._sound then pcall(function() self._sound:Stop() end) end
        if self._oldFOV then Camera.FieldOfView = self._oldFOV; self._oldFOV = nil end
    end
end
RunService.Heartbeat:Connect(function()
    if not SongBeats.Enabled then return end
    if SongBeats.FOVPulse and SongBeats._sound and SongBeats._sound.IsLoaded then
        local interval = 60 / math.max(SongBeats.BPM, 1)
        if tick() - SongBeats._beatTick >= interval then
            SongBeats._beatTick = tick()
            if SongBeats._oldFOV then
                Camera.FieldOfView = SongBeats._oldFOV - SongBeats.FOVAmount
                task.spawn(function()
                    tween(Camera, 0.2, { FieldOfView = SongBeats._oldFOV })
                end)
            end
        end
    end
end)

------------------------------------------------------------
-- GUI BIND INDICATOR  (vape "GUI bind indicator": on-screen keybind hint)
------------------------------------------------------------
local BindIndicator = {
    Enabled = true,
    _frame = nil,
}
function BindIndicator:Build()
    if self._frame and self._frame.Parent then return end
    local f = Instance.new("TextLabel")
    f.Name = "BindIndicator"
    f.Size = UDim2.new(0, 200, 0, 24)
    f.Position = UDim2.new(0.5, -100, 0, 6)
    f.BackgroundColor3 = Theme.BackgroundDark
    f.BackgroundTransparency = 0.4
    f.Font = Theme.FontBold
    f.TextSize = 12
    f.TextColor3 = Theme.Text
    f.Text = "Press RightCtrl to open the hub"
    f.ZIndex = 40
    f.Parent = ScreenGui
    corner(f, Theme.Rounded)
    stroke(f, Theme.Stroke, 1, 0.2)
    self._frame = f
    task.delay(8, function()
        if self._frame and self.Enabled then
            tween(self._frame, 1, { BackgroundTransparency = 1, TextTransparency = 1 })
            task.delay(1, function() if self._frame then self._frame.Visible = false end end)
        end
    end)
end

------------------------------------------------------------
-- AUTO CLIP / PHASE  (walk through specific wall materials)
------------------------------------------------------------
local Phase = makeModule("Phase", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not Phase.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    local dir = hum.MoveDirection
    if dir.Magnitude > 0 then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { getChar() }
        local hit = Workspace:Raycast(root.Position, dir * 3, params)
        if hit then
            pcall(function() root.CFrame = root.CFrame + dir * 4 end)
        end
    end
end)

------------------------------------------------------------
-- AUTO LEVER / BUTTON  (press interactables within range)
------------------------------------------------------------
local AutoInteract = makeModule("AutoInteract", "World", { Range = 30 })
RunService.Heartbeat:Connect(function()
    if not AutoInteract.Enabled then return end
    local root = getRoot()
    if not root then return end
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if (d:IsA("Model") or d:IsA("BasePart")) then
                local n = d.Name:lower()
                if n:find("button") or n:find("lever") or n:find("switch") or n:find("interact") or n:find("door") then
                    local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                    if p and (p.Position - root.Position).Magnitude <= AutoInteract.Settings.Range then
                        firetouchinterest(root, p, 0)
                    end
                end
            end
        end
        fireRemotes("interact"); fireRemotes("use")
    end)
end)

------------------------------------------------------------
-- BLOCK REACH VISUAL  (selection sphere at attack range)
------------------------------------------------------------
local AuraVisual = makeModule("AuraVisual", "Render", {})
local _auraSphere
function AuraVisual.OnToggle(state)
    if not state and _auraSphere then pcall(function() _auraSphere:Destroy() end); _auraSphere = nil end
end
RunService.Heartbeat:Connect(function()
    if not AuraVisual.Enabled then return end
    local root = getRoot()
    if not root then return end
    local range = KillAura.Settings.AttackRange
    if not _auraSphere then
        _auraSphere = Instance.new("Part")
        _auraSphere.Shape = Enum.PartType.Ball
        _auraSphere.Material = Enum.Material.ForceField
        _auraSphere.Color = Color3.fromRGB(122, 92, 255)
        _auraSphere.Transparency = 0.85
        _auraSphere.CanCollide = false
        _auraSphere.CanQuery = false
        _auraSphere.Anchored = true
        _auraSphere.Parent = Workspace
    end
    pcall(function()
        _auraSphere.Size = Vector3.new(range * 2, range * 2, range * 2)
        _auraSphere.CFrame = CFrame.new(root.Position)
    end)
end)

------------------------------------------------------------
-- AUTO BLOCK / PLACE BLOCK  (scaffold alternative for build games)
------------------------------------------------------------
local AutoBlock = makeModule("AutoBlock", "World", {})
local _abParts = {}
RunService.Heartbeat:Connect(function()
    if not AutoBlock.Enabled then
        for _, p in ipairs(_abParts) do pcall(function() p:Destroy() end) end
        _abParts = {}
        return
    end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    -- place a block in front when moving
    if hum.MoveDirection.Magnitude > 0 then
        local p = Instance.new("Part")
        p.Size = Vector3.new(4, 1, 4)
        p.Anchored = true
        p.CanCollide = true
        p.Material = Enum.Material.SmoothPlastic
        p.Color = Color3.fromRGB(80, 200, 120)
        p.CFrame = root.CFrame + hum.MoveDirection * 2 + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
        p.Parent = Workspace
        table.insert(_abParts, p)
        if #_abParts > 8 then
            local old = table.remove(_abParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- NUKER  (vape Nuker: destroy/place-break blocks rapidly around you)
------------------------------------------------------------
local Nuker = makeModule("Nuker", "World", { Range = 8, Mode = "Break" })
RunService.Heartbeat:Connect(function()
    if not Nuker.Enabled then return end
    local root = getRoot()
    if not root then return end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { getChar() }
    local parts = Workspace:GetPartBoundsInRadius(root.Position, Nuker.Settings.Range, params)
    for _, p in ipairs(parts) do
        pcall(function()
            if Nuker.Settings.Mode == "Break" then
                fireRemotes("break"); fireRemotes("destroy")
                swingTool()
            elseif Nuker.Settings.Mode == "Touch" then
                firetouchinterest(root, p, 0)
            end
        end)
    end
end)

------------------------------------------------------------
-- AUTO SOUP  (vape AutoSoup: heal by using soup/food when low)
------------------------------------------------------------
local AutoSoup = makeModule("AutoSoup", "Combat", { Health = 50 })
RunService.Heartbeat:Connect(function()
    if not AutoSoup.Enabled then return end
    local hum = getHum()
    if not hum then return end
    if hum.Health < AutoSoup.Settings.Health then
        local char = getChar()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        -- try to find & use a soup/food tool
        local function useFood(container)
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("soup") or n:find("food") or n:find("potion") or n:find("heal") or n:find("bandage") then
                        pcall(function()
                            if container == bp then hum:EquipTool(t) end
                            t:Activate()
                            task.wait(0.1)
                            hum:UnequipTools()
                        end)
                        return true
                    end
                end
            end
            return false
        end
        if char then if useFood(char) then return end end
        if bp then useFood(bp) end
        -- fallback: refill health directly
        pcall(function() hum.Health = hum.MaxHealth end)
    end
end)

------------------------------------------------------------
-- AUTO TOTEM  (vape AutoTotem: auto-equip a totem/shield to off-hand)
------------------------------------------------------------
local AutoTotem = makeModule("AutoTotem", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not AutoTotem.Enabled then return end
    local char = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    -- look for a "totem" tool and equip it
    local function findTotem(container)
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("totem") then return t end
        end
    end
    if not char:FindFirstChildOfClass("Tool") then
        local totem = (char and findTotem(char)) or (bp and findTotem(bp))
        if totem then pcall(function() hum:EquipTool(totem) end) end
    end
end)

------------------------------------------------------------
-- TREE ESP  (vape-style: highlight trees for wood-cutting games)
------------------------------------------------------------
local TreeESP = makeModule("TreeESP", "Render", {})
function TreeESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not TreeESP.Enabled then return end
    highlightKeywords({ "tree", "wood", "log", "trunk", "oak", "birch", "spruce" }, Color3.fromRGB(120, 200, 120))
end)

------------------------------------------------------------
-- MOB AURA  (like KillAura but only targets NPCs)
------------------------------------------------------------
local MobAura = makeModule("MobAura", "Combat", { Range = 15, Delay = 0.1 })
local _maLast = 0
RunService.Heartbeat:Connect(function()
    if not MobAura.Enabled then return end
    if tick() - _maLast < MobAura.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    for _, t in ipairs(getTargetsInRange(MobAura.Settings.Range, true, false)) do
        if not t.player then  -- only NPCs (no player key)
            if MobAura.Settings.Rotate then
                pcall(function() root.CFrame = CFrame.lookAt(root.Position, Vector3.new(t.hrp.Position.X, root.Position.Y, t.hrp.Position.Z)) end)
            end
            swingTool()
            _maLast = tick()
        end
    end
end)

------------------------------------------------------------
-- AUTO BRIDGE  (vape-style bridging: place blocks while moving forward)
------------------------------------------------------------
local AutoBridge = makeModule("AutoBridge", "World", {})
local _bridgeParts = {}
RunService.Heartbeat:Connect(function()
    if not AutoBridge.Enabled then
        for _, p in ipairs(_bridgeParts) do pcall(function() p:Destroy() end) end
        _bridgeParts = {}
        return
    end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude > 0 then
        local p = Instance.new("Part")
        p.Size = Vector3.new(6, 1, 6)
        p.Anchored = true
        p.CanCollide = true
        p.Material = Enum.Material.WoodPlanks
        p.Color = Color3.fromRGB(160, 110, 70)
        p.CFrame = root.CFrame + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
        p.Parent = Workspace
        table.insert(_bridgeParts, p)
        if #_bridgeParts > 12 then
            local old = table.remove(_bridgeParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- LONG JUMP  (vape LongJump: leap a long distance)
------------------------------------------------------------
local LongJump = makeModule("LongJump", "Movement", { Power = 60 })
RunService.Heartbeat:Connect(function()
    if not LongJump.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        pcall(function()
            local dir = hum.MoveDirection
            root.AssemblyLinearVelocity = Vector3.new(dir.X * LongJump.Settings.Power, 40, dir.Z * LongJump.Settings.Power)
        end)
        LongJump:Set(false)  -- single-use per activation
        notify("LongJump", "Jumped!", 1.5, Theme.Accent)
    end
end)

------------------------------------------------------------
-- BLINK  (vape Blink: teleport to where you're looking)
------------------------------------------------------------
local Blink = makeModule("Blink", "Movement", { Range = 60 })
function Blink.OnToggle(state)
    if state then
        local root = getRoot()
        if root then
            local target = root.Position + Camera.CFrame.LookVector * Blink.Settings.Range
            -- raycast to avoid teleporting into walls
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { getChar() }
            local hit = Workspace:Raycast(root.Position, Camera.CFrame.LookVector * Blink.Settings.Range, params)
            if hit then target = hit.Position end
            pcall(function() root.CFrame = CFrame.new(target + Vector3.new(0, 3, 0)) end)
        end
        Blink:Set(false)  -- instant, single-use
    end
end

------------------------------------------------------------
-- HIGH JUMP  (extra high single jump)
------------------------------------------------------------
local HighJump = makeModule("HighJump", "Movement", { Power = 120 })
function HighJump.OnToggle(state)
    if state then
        local root = getRoot()
        if root then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, HighJump.Settings.Power, root.AssemblyLinearVelocity.Z) end)
        end
        HighJump:Set(false)
    end
end

------------------------------------------------------------
-- ORBIT TP  (teleport in a circle of saved positions, hands-free farming)
------------------------------------------------------------
local OrbitTP = makeModule("OrbitTP", "Movement", { Radius = 8, Speed = 1.2, Height = 0 })
local _orbitAngle = 0
RunService.RenderStepped:Connect(function(dt)
    if not OrbitTP.Enabled then return end
    local root = getRoot()
    if not root then return end
    _orbitAngle = _orbitAngle + dt * OrbitTP.Settings.Speed
    local r = OrbitTP.Settings.Radius
    local offset = Vector3.new(math.cos(_orbitAngle) * r, OrbitTP.Settings.Height, math.sin(_orbitAngle) * r)
    pcall(function() root.CFrame = root.CFrame + offset * dt * 5 end)
end)

------------------------------------------------------------
-- SWAY / ANTI AFK WALK  (gentle figure-8 movement to avoid AFK kicks)
------------------------------------------------------------
local AntiAFKWalk = makeModule("AntiAFKWalk", "Player", { Speed = 1 })
local _aafAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not AntiAFKWalk.Enabled then return end
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    _aafAngle = _aafAngle + dt * AntiAFKWalk.Settings.Speed
    hum:Move(Vector3.new(math.cos(_aafAngle), 0, math.sin(_aafAngle * 2)) * 0.5, false)
end)

------------------------------------------------------------
-- SLIDE  (quick dash on shift)
------------------------------------------------------------
local Slide = makeModule("Slide", "Movement", { Power = 90, Key = Enum.KeyCode.LeftShift })
local _slideLast = 0
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not Slide.Enabled then return end
    if input.KeyCode == Slide.Settings.Key and tick() - _slideLast > 0.8 then
        _slideLast = tick()
        local root = getRoot()
        local hum = getHum()
        if root and hum and hum.MoveDirection.Magnitude > 0 then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * Slide.Settings.Power, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * Slide.Settings.Power)
            end)
        end
    end
end)

------------------------------------------------------------
-- VELTP / VECTOR TELEPORT  (move purely via velocity for smooth long travel)
------------------------------------------------------------
local VelTP = makeModule("VelTP", "Movement", { Power = 120 })
local _velConn
function VelTP.OnToggle(state)
    if state then
        _velConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local hum = getHum()
            if not (root and hum) then return end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * VelTP.Settings.Power, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * VelTP.Settings.Power)
                end)
            end
        end)
    else
        if _velConn then _velConn:Disconnect(); _velConn = nil end
    end
end)

----------------------------------------------