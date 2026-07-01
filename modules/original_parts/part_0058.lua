eadTarget.OnToggle(state)
    if not state then
        Aimbot.Config.TargetPart = "HumanoidRootPart"
        SilentAim.Settings.Part = "HumanoidRootPart"
    end
end)

------------------------------------------------------------
-- BUNNY HOP  (auto-jump while moving for FPS games)
------------------------------------------------------------
local BunnyHop = makeModule("BunnyHop", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not BunnyHop.Enabled then return end
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

------------------------------------------------------------
-- INSTANT INTERACT  (touch all interactable parts within range)
------------------------------------------------------------
local InstantInteract = makeModule("InstantInteract", "World", { Range = 50 })
RunService.Heartbeat:Connect(function()
    if not InstantInteract.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("interact") or n:find("prompt") or n:find("use") or n:find("button") or n:find("lever") then
                if (d.Position - root.Position).Magnitude < InstantInteract.Settings.Range then
                    pcall(function() firetouchinterest(root, d, 0) end)
                end
            end
        end
    end
    fireRemotes("interact")
end)

------------------------------------------------------------
-- WAYPOINT VISUALS  (render beacons at saved waypoints)
------------------------------------------------------------
local WaypointVisuals = makeModule("WaypointVisuals", "Render", {})
local _wpParts = {}
function WaypointVisuals.OnToggle(state)
    if not state then
        for _, p in ipairs(_wpParts) do pcall(function() p:Destroy() end) end
        _wpParts = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not WaypointVisuals.Enabled then return end
    for _, p in ipairs(_wpParts) do pcall(function() p:Destroy() end) end
    _wpParts = {}
    for _, wp in ipairs(Waypoints.List) do
        local part = Instance.new("Part")
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(2, 2, 2)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(122, 92, 255)
        part.CFrame = CFrame.new(wp.pos[1], wp.pos[2], wp.pos[3])
        part.Parent = Workspace
        table.insert(_wpParts, part)
        local beam = Instance.new("Beam")
        -- simple vertical beam via two attachments
        local a0 = Instance.new("Attachment"); a0.Parent = part
        local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, 60, 0); a1.Parent = part
        beam.Attachment0 = a0; beam.Attachment1 = a1
        beam.Width0 = 0.2; beam.Width1 = 0.2
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(122, 92, 255))
        beam.Transparency = NumberSequence.new(0.5, 1)
        beam.Parent = part
    end
end)

------------------------------------------------------------
-- AUTO TELEPORT TO WAYPOINTS  (cycle through saved waypoints)
------------------------------------------------------------
local AutoWaypoint = makeModule("AutoWaypoint", "Movement", { Delay = 3 })
local _awIndex = 1
local _awLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoWaypoint.Enabled then return end
    if #Waypoints.List == 0 then return end
    if tick() - _awLast < AutoWaypoint.Settings.Delay then return end
    _awLast = tick()
    _awIndex = (_awIndex % #Waypoints.List) + 1
    local wp = Waypoints.List[_awIndex]
    if wp then teleportTo(Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3])) end
end)

------------------------------------------------------------
-- AUTO RESPAWN + RE-EQUIP  (respawn then re-equip best tool)
------------------------------------------------------------
local AutoRespawnEquip = makeModule("AutoRespawnEquip", "Player", { Delay = 1 })
RunService.Heartbeat:Connect(function()
    if not AutoRespawnEquip.Enabled then return end
    if not isAlive() then
        if not AutoRespawnEquip._t or tick() - AutoRespawnEquip._t > AutoRespawnEquip.Settings.Delay then
            AutoRespawnEquip._t = tick()
            task.spawn(function()
                pcall(function() LocalPlayer:LoadCharacter() end)
                task.wait(2)
                pcall(function()
                    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                    local hum = getHum()
                    if bp and hum then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then hum:EquipTool(t); break end
                        end
                    end
                end)
            end)
        end
    end
end)

------------------------------------------------------------
-- ANTI EXPLOSION  (teleport away from explosions)
------------------------------------------------------------
local AntiExplosion = makeModule("AntiExplosion", "Player", { Range = 40 })
RunService.Heartbeat:Connect(function()
    if not AntiExplosion.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Explosion") or (d:IsA("BasePart") and d.Name:lower():find("explos")) then
            local pos = d:IsA("Explosion") and d.Position or d.Position
            if (pos - root.Position).Magnitude < AntiExplosion.Settings.Range then
                pcall(function() root.CFrame = root.CFrame + Vector3.new(0, 30, 0) end)
            end
        end
    end
end)

------------------------------------------------------------
-- AMMO / RELOAD HELPER  (auto reload when empty)
------------------------------------------------------------
local AutoReload = makeModule("AutoReload", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not AutoReload.Enabled then return end
    -- press R periodically (best-effort reload trigger)
    if not AutoReload._t or tick() - AutoReload._t > 2 then
        AutoReload._t = tick()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end
end)

------------------------------------------------------------
-- SOUND ESP  (visualize loud sounds / events as markers)
------------------------------------------------------------
local SoundESP = makeModule("SoundESP", "Render", {})
function SoundESP.OnToggle(state)
    if not state then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d.Name == "HubSoundMarker" then d:Destroy() end
            end
        end)
    end
end
RunService.Heartbeat:Connect(function()
    if not SoundESP.Enabled then return end
    -- mark playing 3D sounds
    pcall(function()
        for _, s in ipairs(Workspace:GetDescendants()) do
            if s:IsA("Sound") and s.IsPlaying and not s:GetAttribute("HubMarked") then
                s:SetAttribute("HubMarked", true)
                task.delay(2, function() s:SetAttribute("HubMarked", nil) end)
                local parent = s.Parent
                if parent and parent:IsA("BasePart") and not parent:FindFirstChild("HubSoundMarker") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "HubSoundMarker"
                    hl.FillColor = Color3.fromRGB(255, 120, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = parent
                    task.delay(2, function() pcall(function() hl:Destroy() end) end)
                end
            end
        end
    end)
end)

------------------------------------------------------------
-- ANTI WATER / LAVA  (teleport up if touching water/lava)
------------------------------------------------------------
local AntiLiquid = makeModule("AntiLiquid", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not AntiLiquid.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.FloorMaterial == Enum.Material.Lava or hum.FloorMaterial == Enum.Material.Water then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 60, root.AssemblyLinearVelocity.Z)
        end)
    end
end)

------------------------------------------------------------
-- AUTO STAT  (dump player's stats to a readable format)
------------------------------------------------------------
local function dumpStats()
    local lines = {}
    local function scan(container, label)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") or v:IsA("BoolValue") then
                table.insert(lines, label .. "." .. v.Name .. " = " .. tostring(v.Value))
            end
        end
    end
    if LocalPlayer:FindFirstChild("leaderstats") then scan(LocalPlayer.leaderstats, "leaderstats") end
    scan(LocalPlayer, "player")
    return table.concat(lines, "\n")
end

------------------------------------------------------------
-- NO HEADSHOT  (resize own head to dodge headshots - cosmetic)
------------------------------------------------------------
local NoHeadshot = makeModule("NoHeadshot", "Render", {})
local _nhOrig
function NoHeadshot.OnToggle(state)
    pcall(function()
        local char = getChar()
        local head = char and char:FindFirstChild("Head")
        if not head then return end
        if state then
            if not _nhOrig then _nhOrig = head.Size end
            -- shrink locally only
            head.Size = Vector3.new(0.5, 0.5, 0.5)
        else
            if _nhOrig then head.Size = _nhOrig end
        end
    end)
end

------------------------------------------------------------
-- AIR STUCK / HANG  (freeze mid-air by cancelling gravity)
------------------------------------------------------------
local AirStuck = makeModule("AirStuck", "Movement", {})
local _asBV
RunService.Heartbeat:Connect(function()
    if not AirStuck.Enabled then
        if _asBV then pcall(function() _asBV:Destroy() end); _asBV = nil end
        return
    end
    local root = getRoot()
    if not root then return end
    if not _asBV then
        _asBV = Instance.new("BodyVelocity")
        _asBV.MaxForce = Vector3.new(0, 1e9, 0)
        _asBV.Velocity = Vector3.zero
        _asBV.Parent = root
    end
end)

------------------------------------------------------------
-- SLOW FALL  (gentle parachute-style descent)
------------------------------------------------------------
local SlowFall = makeModule("SlowFall", "Movement", { Speed = 20 })
RunService.Heartbeat:Connect(function()
    if not SlowFall.Enabled then return end
    local root = getRoot()
    if not root then return end
    if root.AssemblyLinearVelocity.Y < -SlowFall.Settings.Speed then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -SlowFall.Settings.Speed, root.AssemblyLinearVelocity.Z) end)
    end
end)

------------------------------------------------------------
-- FAST RESET  (instantly reset character)
------------------------------------------------------------
local FastReset = makeModule("FastReset", "Player", {})
function FastReset.OnToggle(state)
    if state then
        pcall(function() LocalPlayer.Character:BreakJoints() end)
        FastReset:Set(false)
    end
end

------------------------------------------------------------
-- SERVER LAG INDICATOR  (monitor server performance)
------------------------------------------------------------
local ServerMonitor = makeHUDModule("Server", "Server performance", function(lbl)
    local fps = math.floor(Workspace:GetRealPhysicsFPS())
    local players = #Players:GetPlayers()
    lbl.Text = "SVR " .. fps .. "fps | " .. players .. "p"
end)
ServerMonitor._delay = 1

------------------------------------------------------------
-- AUTO SELL ALL  (fire every sell remote)
------------------------------------------------------------
local AutoSellAll = makeModule("AutoSellAll", "World", { Delay = 1 })
local _asaLast
RunService.Heartbeat:Connect(function()
    if not AutoSellAll.Enabled then return end
    if _asaLast and tick() - _asaLast < AutoSellAll.Settings.Delay then return end
    _asaLast = tick()
    fireRemotes("sell")
end)

------------------------------------------------------------
-- GRAVITY CONTROL MODULE  (live gravity multiplier)
------------------------------------------------------------
local GravityMod = makeModule("GravityMod", "Movement", { Mult = 1 })
local _gOrigGravity
RunService.Heartbeat:Connect(function()
    if not GravityMod.Enabled then
        if _gOrigGravity then Workspace.Gravity = _gOrigGravity; _gOrigGravity = nil end
        return
    end
    if not _gOrigGravity then _gOrigGravity = Workspace.Gravity end
    Workspace.Gravity = 196.2 * GravityMod.Settings.Mult
end)

------------------------------------------------------------
-- AUTO CLAIM CHESTS  (teleport to & touch all chests)
------------------------------------------------------------
local AutoChests = makeModule("AutoChests", "World", { Delay = 0.5, Range = 1000 })
local _acIndex = 1
local _acLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoChests.Enabled then return end
    if tick() - _acLast < AutoChests.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    local chests = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("BasePart")) and d.Name:lower():find("chest") then
            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
            if p then table.insert(chests, p) end
        end
    end
    if #chests == 0 then return end
    _acIndex = (_acIndex % #chests) + 1
    _acLast = tick()
    local c = chests[_acIndex]
    pcall(function()
        root.CFrame = c.CFrame + Vector3.new(0, 3, 0)
        firetouchinterest(root, c, 0)
    end)
end)

------------------------------------------------------------
-- COORDS HUD  (vape-style: show current X/Y/Z position)
------------------------------------------------------------
local CoordsHUD = makeHUDModule("Coords", "Shows your current position", function(lbl)
    local root = getRoot()
    if root then
        local p = root.Position
        lbl.Text = string.format("X:%.0f Y:%.0f Z:%.0f", p.X, p.Y, p.Z)
    else
        lbl.Text = "X:0 Y:0 Z:0"
    end
end)
CoordsHUD._delay = 0.2

------------------------------------------------------------
-- SERVER INFO HUD  (show server player count + JobId)
------------------------------------------------------------
local ServerHUD = makeHUDModule("Server", "Server info", function(lbl)
    lbl.Text = string.format("Players: %d  |  JobId: %s", #Players:GetPlayers(), tostring(game.JobId):sub(1, 8))
end)
ServerHUD._delay = 1

------------------------------------------------------------
-- DAMAGE NUMBERS  (vape-style: show floating damage numbers)
------------------------------------------------------------
local DamageNumbers = makeModule("DamageNumbers", "Render", {})
local _dmgFolder
local function getDmgFolder()
    if _dmgFolder and _dmgFolder.Parent then return _dmgFolder end
    _dmgFolder = Instance.new("Folder")
    _dmgFolder.Name = "HubDamageNumbers"
    _dmgFolder.Parent = Workspace
    return _dmgFolder
end
local function showDamageNumber(pos, amount, color)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CFrame = CFrame.new(pos)
    part.Parent = getDmgFolder()
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 60, 0, 24)
    bb.AlwaysOnTop = true
    bb.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Theme.FontBold
    lbl.TextSize = 20
    lbl.TextColor3 = color or Color3.fromRGB(255, 220, 80)
    lbl.TextStrokeTransparency = 0.3
    lbl.Text = tostring(amount)
    lbl.Parent = bb
    local start = pos + Vector3.new(0, 2, 0)
    local ende = pos + Vector3.new(0, 6, 0)
    local t0 = tick()
    task.spawn(function()
        while tick() - t0 < 1 do
            local a = (tick() - t0) / 1
            part.CFrame = CFrame.new(start:Lerp(ende, a))
            lbl.TextTransparency = a
            lbl.TextStrokeTransparency = 0.3 + a * 0.7
            task.wait()
        end
        part:Destroy()
    end)
end
-- hook KillAura swings to show numbers near targets
local _dnLast = {}
RunService.Heartbeat:Connect(function()
    if not DamageNumbers.Enabled then return end
    for _, t in ipairs(getTargetsInRange(KillAura.Settings.AttackRange, true, true)) do
        if not _dnLast[t.hrp] or tick() - _dnLast[t.hrp] > 0.4 then
            _dnLast[t.hrp] = tick()
            local dmg = math.random(4, 18)
            showDamageNumber(t.hrp.Position + Vector3.new(math.random(-1,1), 2, math.random(-1,1)), dmg, Color3.fromRGB(255, 220, 80))
        end
    end
end)

------------------------------------------------------------
-- HIT INDICATOR  (red arc flash when you take damage)
------------------------------------------------------------
local HitIndicator = makeModule("HitIndicator", "Render", {})
local _hiFrame
function HitIndicator.OnToggle(state)
    if state then
        if not (_hiFrame and _hiFrame.Parent) then
            _hiFrame = Instance.new("ImageLabel")
            _hiFrame.Name = "HitIndicator"
            _hiFrame.Size = UDim2.new(0, 120, 0, 120)
            _hiFrame.Position = UDim2.new(0.5, -60, 0.5, -60)
            _hiFrame.BackgroundTransparency = 1
            _hiFrame.Image = "rbxassetid://0"
            _hiFrame.ImageTransparency = 1
            _hiFrame.ZIndex = 8
            _hiFrame.Parent = ScreenGui
            -- draw a red ring via a frame circle
            local ring = Instance.new("Frame")
            ring.Size = UDim2.new(1, 0, 1, 0)
            ring.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            ring.ZIndex = 9
            ring.Parent = _hiFrame
            corner(ring, UDim.new(1, 0))
            stroke(ring, Color3.fromRGB(255, 40, 40), 3, 1)
            _hiFrame._ring = ring
        end
    end
end
local _lastHP
RunService.Heartbeat:Connect(function()
    if not HitIndicator.Enabled then return end
    local h = getHum()
    if not h then return end
    if _lastHP and h.Health < _lastHP and _hiFrame and _hiFrame._ring then
        _hiFrame._ring.BackgroundTransparency = 0.4
        tween(_hiFrame._ring, 0.5, { BackgroundTransparency = 1 })
    end
    _lastHP = h.Health
end)

------------------------------------------------------------
-- FPS BOOST PRESETS  (vape-style graphics reduction)
------------------------------------------------------------
local FPSBoost = makeModule("FPSBoost", "Render", { Level = 2 })
local _fbStored = {}
function FPSBoost.OnToggle(state)
    if state then
        local level = FPSBoost.Settings.Level
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d:IsA("Terrain") then
                    if level >= 1 then
                        if not d:GetAttribute("FBShadow") then d:SetAttribute("FBShadow", d.CastShadow and 1 or 0); d.CastShadow = false end
                    end
                    if level >= 2 then
                        if not d:GetAttribute("FBMat") then d:SetAttribute("FBMat", tostring(d.Material)); d.Material = Enum.Material.Plastic end
                    end
                    if level >= 3 then
                        if not d:GetAttribute("FBTrans") then d:SetAttribute("FBTrans", tostring(d.Transparency)); d.Transparency = math.max(d.Transparency, 0.3) end
                    end
                end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e9
            Workspace.StreamingTargetRadius = 512
        end)
        notify("FPS Boost", "Level " .. level .. " applied.", 3, Theme.Green)
    else
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    local sh = d:GetAttribute("FBShadow")
                    if sh ~= nil then d.CastShadow = sh == 1; d:SetAttribute("FBShadow", nil) end
                    local mat = d:GetAttribute("FBMat")
                    if mat then d.Material = Enum.Material[mat]; d:SetAttribute("FBMat", nil) end
                    local tr = d:GetAttribute("FBTrans")
                    if tr then d.Transparency = tonumber(tr); d:SetAttribute("FBTrans", nil) end
                end
            end
        end)
        notify("FPS Boost", "Restored graphics.", 3, Theme.Yellow)
    end
end

------------------------------------------------------------
-- GROUND / FLOOR CHECK HELPER  (used by movement modules)
------------------------------------------------------------
local function isGrounded()
    local hum = getHum()
    return hum ~= nil and hum.FloorMaterial ~= Enum.Material.Air
end

------------------------------------------------------------
-- AUTO DODGE  (vape-style: teleport away from incoming projectiles)
------------------------------------------------------------
local AutoDodge = makeModule("AutoDodge", "Combat", { Range = 40 })
RunService.Heartbeat:Connect(function()
    if not AutoDodge.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("bullet") or n:find("projectile") or n:find("fireball") or n:find("rocket") then
                local dist = (d.Position - root.Position).Magnitude
                local vel = d.AssemblyLinearVelocity
                if dist < AutoDodge.Settings.Range and vel.Magnitude > 20 then
                    -- move perpendicular to the projectile's velocity
                    local rel = root.Position - d.Position
                    local side = rel:Cross(Vector3.new(0, 1, 0))
                    if side.Magnitude > 0 then
                        pcall(function() root.CFrame = root.CFrame + side.Unit * 6 end)
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- SNEAK  (vape Sneak: crouch + controllable sneak speed)
------------------------------------------------------------
local Sneak = makeModule("Sneak", "Movement", { Speed = 8 })
RunService.Heartbeat:Connect(function()
    if not Sneak.Enabled then return end
    local hum = getHum()
    if hum then
        pcall(function() hum.CrouchSpeed = Sneak.Settings.Speed end)
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            hum:ChangeState(Enum.HumanoidStateType.Seated)
        end
    end
end)

------------------------------------------------------------
-- TIMER  (vape Timer: speed up / slow down the local time perception)
------------------------------------------------------------
local Timer = makeModule("Timer", "Render", { Multiplier = 1 })
local _timerStartTick, _timerStartClock
RunService.Heartbeat:Connect(function()
    if not Timer.Enabled then return end
    -- manipulate local heartbeat perception is not possible; instead nudge Lighting clock
    pcall(function()
        local m = Timer.Settings.Multiplier
        Lighting.ClockTime = (Lighting.ClockTime + (m - 1) * 0.01) % 24
    end)
end)

------------------------------------------------------------
-- VIEWPORT CLIP  (vape ViewportClip: zoom the viewport via FOV clamp)
------------------------------------------------------------
local ViewportClip = makeModule("ViewportClip", "Render", { Min = 70, Max = 90 })
RunService.RenderStepped:Connect(function()
    if not ViewportClip.Enabled then return end
    pcall(function()
        Camera.FieldOfView = math.clamp(Camera.FieldOfView, ViewportClip.Settings.Min, ViewportClip.Settings.Max)
    end)
end)

------------------------------------------------------------
-- TOWER ESP  (vape TowerESP: highlight spawn towers / structures)
------------------------------------------------------------
local TowerESP = makeModule("TowerESP", "Render", {})
function TowerESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not TowerESP.Enabled then return end
    highlightKeywords({ "tower", "spire", "spawn", "base", "keep", "castle", "nexus", "core" }, Color3.fromRGB(120, 180, 255))
end)

------------------------------------------------------------
-- HEALTHBAR ESP  (billboard health bars above each enemy)
------------------------------------------------------------
local HealthbarESP = makeModule("HealthbarESP", "Render", { TeamCheck = true })
local _hbBars = {}
function HealthbarESP.OnToggle(state)
    if not state then
        for _, b in pairs(_hbBars) do pcall(function() b:Destroy() end) end
        _hbBars = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not HealthbarESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not _hbBars[plr] then
            if not (HealthbarESP.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if head and hum then
                    local bb = Instance.new("BillboardGui")
                    bb.Adornee = head
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 50, 0, 6)
                    bb.StudsOffset = Vector3.new(0, 2.6, 0)
                    bb.Parent = head
                    local bkg = Instance.new("Frame")
                    bkg.Size = UDim2.new(1, 0, 1, 0)
                    bkg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    bkg.BorderSizePixel = 0
                    bkg.Parent = bb
                    corner(bkg, UDim.new(1, 0))
                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new(1, 0, 1, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(76, 209, 142)
                    fill.BorderSizePixel = 0
                    fill.Parent = bkg
                    corner(fill, UDim.new(1, 0))
                    _hbBars[plr] = { bb = bb, fill = fill, hum = hum, con = hum.HealthChanged:Connect(function(h)
                        local pct = math.clamp(h / math.max(hum.MaxHealth, 1), 0, 1)
                        fill.Size = UDim2.new(pct, 0, 1, 0)
                        fill.BackgroundColor3 = Color3.fromHSV(pct / 2.5, 0.8, 0.8)
                    end) }
                end
            end
        end
    end
    -- cleanup dead
    for plr, data in pairs(_hbBars) do
        if not plr.Character or not plr.Character:FindFirstChild("Head") then
            pcall(function() data.con:Disconnect() end)
            pcall(function() data.bb:Destroy() end)
            _hbBars[plr] = nil
        end
    end
end)

------------------------------------------------------------
-- WALLBANG  (vape Wallbang: shoot through walls via target snap)
------------------------------------------------------------
local Wallbang = makeModule("Wallbang", "Combat", { Part = "HumanoidRootPart" })
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not Wallbang.Enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local closest, mag = nil, 9999
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local part = plr.Character:FindFirstChild(Wallbang.Settings.Part)
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if part and hum and hum.Health > 0 then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local m = (Vector2.new(sp.X, sp.Y) - UserInputService:GetMouseLocation()).Magnitude
                        if m < mag then mag = m; closest = part end
                    end
                end
            end
        end
        if closest then
            pcall(function() Camera.CFrame = CFrame.new(Camera.CFrame.Position, closest.Position) end)
        end
    end
end)

------------------------------------------------------------
-- AUTO FISH  (vape-style fishing: click when a prompt appears)
------------------------------------------------------------
local AutoFish = makeModule("AutoFish", "World", { Delay = 0.3 })
local _afLast
RunService.Heartbeat:Connect(function()
    if not AutoFish.Enabled then return end
    if _afLast and tick() - _afLast < AutoFish.Settings.Delay then return end
    -- detect a fishing prompt by looking for a TextButton containing "reel"/"catch"
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, d in ipairs(pg:GetDescendants()) do
                if d:IsA("TextButton") then
                    local t = d.Text:lower()
                    if t:find("reel") or t:find("catch") or t:find("pull") or t:find("hook") then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        _afLast = tick()
                        break
                    end
                end
            end
        end
    end)
end)

------------------------------------------------------------
-- AUTO BUY ALL  (fire every "buy" remote in ReplicatedStorage)
------------------------------------------------------------
local AutoBuyAll = makeModule("AutoBuyAll", "World", { Delay = 1 })
local _abaLast
RunService.Heartbeat:Connect(function()
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
    flas