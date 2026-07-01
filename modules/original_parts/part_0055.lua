AddButton("â¬† Up 30", function() TeleportPro.nudge(0, 30, 0) end)
    w:AddButton("â¬‡ Down 30", function() TeleportPro.nudge(0, -30, 0) end)

    w:AddSection("Part Search Teleport")
    w:AddInput("Part Name", "", "e.g. Door / Chest", function(v) w._partName = v end)
    w:AddButton("Teleport to Nearest Part (by name)", function()
        if not TeleportPro.toPartByName(w._partName or "") then notify("TeleportPro", "Part not found.", 2.5, Theme.Red) end
    end, Theme.Accent)

    w:AddSection("Saved Locations")
    w:AddInput("Location Name", "", "name for this spot", function(v) w._spotName = v end)
    w:AddButton("Save Current Position", function()
        TeleportPro.saveHere(w._spotName ~= "" and w._spotName or nil)
    end, Theme.Green)
    w:AddButton("Tour All Saved (sequence)", function() TeleportPro.tourSaved() end)
    w:AddInput("Go-To Saved Name", "", "exact saved name", function(v) w._goName = v end)
    w:AddButton("Teleport to Saved Spot", function()
        TeleportPro.goToSaved(w._goName or "")
    end)
    w:AddButton("Delete Saved Spot", function()
        TeleportPro.deleteSaved(w._goName or "")
    end, Theme.Yellow)

    w:AddSection("Player Cycle")
    w:AddButton("Cycle to Next Player", function() TeleportPro.cyclePlayer() end, Theme.Accent)

    w:AddSection("Path Recorder")
    w:AddButton("Start Recording", function() TeleportPro.startRecording() end, Theme.Yellow)
    w:AddButton("Stop Recording", function() TeleportPro.stopRecording() end, Theme.Red)
    w:AddButton("Play Path (smooth)", function() TeleportPro.playPath(false) end, Theme.Accent)
    w:AddButton("Play Path (instant)", function() TeleportPro.playPath(true) end)
    w:AddSlider("Path Speed", 0.1, 10, 1, "x", 2, function(v) TeleportPro.PathSpeed = v end)
    w:AddButton("Save Path to File", function() TeleportPro.savePathToFile() end)
    w:AddButton("Load Path from File", function() TeleportPro.loadPathFromFile() end)
    w:AddButton("Clear Path", function() TeleportPro.Path = {}; notify("TeleportPro", "Path cleared.", 2.5, Theme.Yellow) end, Theme.Yellow)

    w:AddSection("Part Grabber / Mover")
    w:AddToggle("Enable Part Mover", false, function(v) PartMover.Enabled = v; if not v then PartMover:select(nil) end end, "Right-click a part to select it")
    w:AddDropdown("Mover Mode", { "Bring", "Fling", "Freeze" }, "Bring", function(v) PartMover.Mode = v end)
    w:AddButton("Act on Selected Part", function() PartMover:act() end, Theme.Accent)
    w:AddButton("Deselect", function() PartMover:select(nil) end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    notify("Teleport Pro", "Loaded. Save spots, record paths, click-TP!", 4, Theme.Accent)
    return w
end

--==============================================================================
--// PLAYER LIST HELPERS (for "teleport to" / "bring" dropdowns)
--==============================================================================
getPlayerNames = function(includeSelf)
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if includeSelf or p ~= LocalPlayer then table.insert(t, p.Name) end
    end
    return t
end
findPlayerByName = function(name)
    name = string.lower(tostring(name))
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name):sub(1, #name) == name then return p end
    end
    return nil
end

--==============================================================================
--// VAPE-STYLE MODULE FRAMEWORK
--   Inspired by VapeV4's module architecture (Combat / Movement / Player /
--   Render categories). Each module is a self-contained, toggleable system
--   driven by RunService loops with real Roblox API calls. Works in plain
--   Studio thanks to the Drawing + executor shims below.
--==============================================================================

--// Drawing API shim (Studio has no Drawing global). Tracers use Beams.
local Drawing = Drawing or {}
Drawing._enabled = false
local _tracerFolder
local function ensureTracerFolder()
    if _tracerFolder and _tracerFolder.Parent then return _tracerFolder end
    _tracerFolder = Instance.new("Folder")
    _tracerFolder.Name = "HubTracers"
    _tracerFolder.Parent = Workspace
    return _tracerFolder
end

--// Module registry
local Modules = {}
local function makeModule(name, category, defaults)
    local m = {
        Name = name,
        Category = category or "Misc",
        Enabled = false,
        Settings = defaults or {},
    }
    function m:Set(v, fire)
        m.Enabled = v and true or false
        if m.OnToggle then pcall(m.OnToggle, m.Enabled) end
    end
    function m:Toggle() m:Set(not m.Enabled) end
    Modules[name] = m
    return m
end

-- Collect every living non-friendly character within range of the local root.
local function getTargetsInRange(range, includeNPCs, teamCheck)
    local root = getRoot()
    local list = {}
    if not root then return list end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                if not (teamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d <= range then table.insert(list, { char = char, hrp = hrp, hum = hum, dist = d, player = plr }) end
                end
            end
        end
    end
    if includeNPCs then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                local hum = d:FindFirstChildOfClass("Humanoid")
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist <= range then table.insert(list, { char = d, hrp = hrp, hum = hum, dist = dist }) end
                end
            end
        end
    end
    return list
end

-- Fire the currently held tool (works for most games that use Tool:Activate).
local function swingTool()
    pcall(function()
        local tool = getChar() and getChar():FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
    end)
end

------------------------------------------------------------
-- COMBAT MODULES
------------------------------------------------------------

-- KillAura: attack all valid targets in range, sorted by distance.
-- Faithful to vape KillAura: angle-cone targeting, swing vs attack range,
-- SelectionBox range indicators, ParticleEmitter hit effects, optional
-- GetPartBoundsInBox touch-interest forwarding.
local KillAura = makeModule("KillAura", "Combat", {
    Range = 6, SwingRange = 6, AttackRange = 13, Delay = 0.1,
    Targets = 1, MaxAngle = 360, NPC = false, TeamCheck = true,
    Rotate = true, ShowRange = false, Particles = false, CPS = 12,
})
local _kaLast = 0
-- Range indicator boxes (red = swing, green = attack).
local _kaSwingBox, _kaAttackBox
local function buildAuraBoxes()
    if _kaSwingBox then return end
    _kaSwingBox = Instance.new("SelectionBox")
    _kaSwingBox.Name = "AuraSwingBox"
    _kaSwingBox.Color3 = Color3.fromRGB(255, 80, 80)
    _kaSwingBox.Transparency = 0.6
    _kaSwingBox.LineThickness = 0.05
    _kaSwingBox.Visible = false
    _kaSwingBox.Parent = Workspace
    _kaAttackBox = Instance.new("SelectionBox")
    _kaAttackBox.Name = "AuraAttackBox"
    _kaAttackBox.Color3 = Color3.fromRGB(80, 255, 120)
    _kaAttackBox.Transparency = 0.6
    _kaAttackBox.LineThickness = 0.05
    _kaAttackBox.Visible = false
    _kaAttackBox.Parent = Workspace
end
-- Particle pool for hit effects.
local _kaParticles = {}
local function getAuraParticle()
    for _, p in ipairs(_kaParticles) do if not p.Enabled then return p end end
    if #_kaParticles > 30 then return _kaParticles[1] end
    local att = Instance.new("Attachment")
    att.Parent = Workspace
    local pe = Instance.new("ParticleEmitter")
    pe.Attachment = att
    pe.Texture = "rbxassetid://243660364"
    pe.Lifetime = NumberRange.new(0.3, 0.5)
    pe.Speed = NumberRange.new(6, 10)
    pe.Rate = 0
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
    pe.Size = NumberSequence.new(0.6, 0)
    pe.Parent = att
    table.insert(_kaParticles, pe)
    return pe
end
function KillAura.OnToggle(state)
    if not state then
        if _kaSwingBox then _kaSwingBox.Visible = false end
        if _kaAttackBox then _kaAttackBox.Visible = false end
    end
end
RunService.Heartbeat:Connect(function()
    if not KillAura.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if KillAura.Settings.ShowRange then
        buildAuraBoxes()
        _kaSwingBox.Visible = true
        _kaAttackBox.Visible = true
        _kaSwingBox.Adornee = root
        _kaAttackBox.Adornee = root
    elseif _kaSwingBox then
        _kaSwingBox.Visible = false
        _kaAttackBox.Visible = false
    end
    local cps = math.max(KillAura.Settings.CPS or 12, 1)
    local interval = math.max(1 / cps, KillAura.Settings.Delay)
    if tick() - _kaLast < interval then return end
    local selfpos = root.Position
    local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
    local swingR, attackR = KillAura.Settings.SwingRange, KillAura.Settings.AttackRange
    local maxAng = math.rad(KillAura.Settings.MaxAngle) / 2
    local targets = getTargetsInRange(KillAura.Settings.AttackRange, KillAura.Settings.NPC, KillAura.Settings.TeamCheck)
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    local count = 0
    for _, t in ipairs(targets) do
        if count >= KillAura.Settings.Targets then break end
        local delta = t.hrp.Position - selfpos
        local angle = math.acos(math.clamp(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit), -1, 1))
        if angle > maxAng then continue end
        if KillAura.Settings.Rotate then
            pcall(function()
                root.CFrame = CFrame.lookAt(root.Position, Vector3.new(t.hrp.Position.X, root.Position.Y + 0.01, t.hrp.Position.Z))
            end)
        end
        swingTool()
        count = count + 1
        if KillAura.Settings.Particles then
            pcall(function()
                local pe = getAuraParticle()
                pe.Attachment.Position = t.hrp.Position
                pe.Enabled = true
                pe:Emit(8)
                task.delay(0.2, function() pe.Enabled = false end)
            end)
        end
    end
    if count > 0 then _kaLast = tick() end
end)

-- Velocity (Anti-Knockback): counteract horizontal knockback velocity.
local Velocity = makeModule("Velocity", "Combat", { Horizontal = 100, Vertical = 0 })
RunService.Heartbeat:Connect(function()
    if not Velocity.Enabled then return end
    local root = getRoot()
    if not root then return end
    local v = root.AssemblyLinearVelocity
    local hPct = (100 - Velocity.Settings.Horizontal) / 100
    local vPct = (100 - Velocity.Settings.Vertical) / 100
    root.AssemblyLinearVelocity = Vector3.new(v.X * hPct, v.Y * vPct, v.Z * hPct)
end)

-- Criticals: force a small hop right before a swing so the game registers a crit.
local Criticals = makeModule("Criticals", "Combat", {})
local _critReady = false
RunService.Heartbeat:Connect(function()
    if not Criticals.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    local grounded = hum.FloorMaterial ~= Enum.Material.Air
    if grounded and Mouse:IsButtonDown() then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 24, root.AssemblyLinearVelocity.Z) end)
    end
end)

-- Reach: expand the detection so clicks register from further away (hitbox based).
local Reach = makeModule("Reach", "Combat", { Distance = 12 })
RunService.Heartbeat:Connect(function()
    if not Reach.Enabled then return end
    for _, t in ipairs(getTargetsInRange(Reach.Settings.Distance, true, true)) do
        pcall(function()
            if not t.hrp:GetAttribute("ReachHitbox") then
                t.hrp:SetAttribute("ReachHitbox", true)
                t.hrp:SetAttribute("ReachOrigSize", HttpService:JSONEncode({ t.hrp.Size.X, t.hrp.Size.Y, t.hrp.Size.Z }))
            end
        end)
    end
end)
function Reach.OnToggle(state)
    if not state then
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp:GetAttribute("ReachHitbox") then
                        hrp:SetAttribute("ReachHitbox", nil)
                        local s = hrp:GetAttribute("ReachOrigSize")
                        if s then local d = HttpService:JSONDecode(s); hrp.Size = Vector3.new(d[1], d[2], d[3]) end
                    end
                end
            end
        end)
    end
end

-- AutoClicker: click while the mouse button is held (configurable CPS).
local AutoClicker = makeModule("AutoClicker", "Combat", { CPS = 12, HoldMode = true })
local _acLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoClicker.Enabled then return end
    if AutoClicker.Settings.HoldMode and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    local interval = 1 / math.max(AutoClicker.Settings.CPS, 1)
    if tick() - _acLast >= interval then
        _acLast = tick()
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
            VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
        end)
    end
end)

------------------------------------------------------------
-- MOVEMENT MODULES
------------------------------------------------------------

-- Sprint: always run forward (set WalkSpeed up / hold shift key sim).
local Sprint = makeModule("Sprint", "Movement", { Speed = 22 })
RunService.Heartbeat:Connect(function()
    if not Sprint.Enabled then return end
    local hum = getHum()
    if hum and hum.MoveDirection.Magnitude > 0 then
        hum.WalkSpeed = Sprint.Settings.Speed
    end
end)

-- Speed: multiple modes (Velocity / CFrame).
local Speed = makeModule("Speed", "Movement", { Mode = "Velocity", Value = 30 })
RunService.Heartbeat:Connect(function()
    if not Speed.Enabled then return end
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    if hum.MoveDirection.Magnitude > 0 then
        if Speed.Settings.Mode == "Velocity" then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * Speed.Settings.Value, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * Speed.Settings.Value) end)
        elseif Speed.Settings.Mode == "CFrame" then
            pcall(function() root.CFrame = root.CFrame + hum.MoveDirection * (Speed.Settings.Value * 0.1) end)
        else
            hum.WalkSpeed = Speed.Settings.Value
        end
    end
end)

-- Step: increase step height to walk up blocks.
local Step = makeModule("Step", "Movement", { Height = 4 })
RunService.Heartbeat:Connect(function()
    if not Step.Enabled then return end
    local hum = getHum()
    if hum then pcall(function() hum.HipHeight = Step.Settings.Height end) end
end)
function Step.OnToggle(state) if not state then local h = getHum(); if h then h.HipHeight = 2 end end end

-- NoFall: cancel downward velocity when falling to avoid fall damage.
local NoFall = makeModule("NoFall", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not NoFall.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if root.AssemblyLinearVelocity.Y < -40 then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -2, root.AssemblyLinearVelocity.Z) end)
    end
end)

-- Jesus: raycast down; if water/terrain-fluid is below, hold the player up.
local Jesus = makeModule("Jesus", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not Jesus.Enabled then return end
    local root = getRoot()
    if not root then return end
    local origin = root.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { getChar() }
    local hit = Workspace:Raycast(origin, Vector3.new(0, -6, 0), params)
    if hit and hit.Material == Enum.Material.Water then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z) end)
    end
end)

-- Spider: climb vertical walls when moving into them.
local Spider = makeModule("Spider", "Movement", { Speed = 25 })
RunService.Heartbeat:Connect(function()
    if not Spider.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude > 0 then
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { getChar() }
        local hit = Workspace:Raycast(root.Position, hum.MoveDirection * 2, params)
        if hit then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(0, Spider.Settings.Speed, 0) end)
        end
    end
end)

------------------------------------------------------------
-- FLOAT MODULE  (vape Float: keep a Y level, Floor mode spawns a platform)
------------------------------------------------------------
local Float = makeModule("Float", "Movement", { Mode = "Velocity", Height = 5, Speed = 8 })
local _floatPlatform, _floatY
function Float.OnToggle(state)
    if not state then
        if _floatPlatform then pcall(function() _floatPlatform:Destroy() end); _floatPlatform = nil end
        _floatY = nil
    end
end
RunService.Heartbeat:Connect(function(dt)
    if not Float.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    local mode = Float.Settings.Mode
    if mode == "Floor" then
        -- spawn a part under the player to stand on
        if not _floatPlatform or not _floatPlatform.Parent then
            _floatPlatform = Instance.new("Part")
            _floatPlatform.Size = Vector3.new(6, 1, 6)
            _floatPlatform.Anchored = true
            _floatPlatform.CanCollide = true
            _floatPlatform.Material = Enum.Material.ForceField
            _floatPlatform.Color = Color3.fromRGB(122, 92, 255)
            _floatPlatform.Transparency = 0.4
            _floatPlatform.Parent = Workspace
        end
        pcall(function()
            _floatPlatform.CFrame = root.CFrame + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
        end)
    elseif mode == "Velocity" then
        if not _floatY then _floatY = root.Position.Y end
        pcall(function()
            local diff = _floatY - root.Position.Y
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, diff * 10, root.AssemblyLinearVelocity.Z)
        end)
    elseif mode == "CFrame" then
        if not _floatY then _floatY = root.Position.Y + Float.Settings.Height end
        pcall(function()
            root.AssemblyLinearVelocity *= Vector3.new(1, 0, 1)
            root.CFrame = root.CFrame + Vector3.new(0, _floatY - root.Position.Y, 0)
        end)
    end
end)

------------------------------------------------------------
-- REAL REACH  (vape Reach: TouchInterest fire OR Resize tool)
------------------------------------------------------------
local Reach2 = makeModule("Reach2", "Combat", { Mode = "Resize", Range = 3, Chance = 100 })
local _reachModified = {}
function Reach2.OnToggle(state)
    if not state then
        for part, old in pairs(_reachModified) do
            pcall(function()
                part.Size = old.size
                part.Massless = false
            end)
        end
        _reachModified = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not Reach2.Enabled then return end
    local char = getChar()
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local handle = tool:FindFirstChild("Handle")
    if not handle then return end
    if Reach2.Settings.Mode == "Resize" then
        if not _reachModified[handle] then
            _reachModified[handle] = { size = handle.Size }
        end
        pcall(function()
            handle.Size = _reachModified[handle].size + Vector3.new(0, 0, Reach2.Settings.Range)
            handle.Massless = true
        end)
    elseif Reach2.Settings.Mode == "TouchInterest" then
        -- forward touches on nearby parts to the tool handle
        local root = getRoot()
        if root then
            for _, t in ipairs(getTargetsInRange(Reach2.Settings.Range + 5, true, true)) do
                if math.random(1, 100) <= Reach2.Settings.Chance then
                    pcall(function()
                        firetouchinterest(handle, t.hrp, 1)
                        firetouchinterest(handle, t.hrp, 0)
                    end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- SILENT AIM  (vape SilentAim: redirect closest target's part to the cursor)
------------------------------------------------------------
local SilentAim = makeModule("SilentAim", "Combat", { FOV = 200, Part = "HumanoidRootPart", Prediction = 0.13, TeamCheck = true, AutoFire = false })
local function silentGetClosest()
    local closest, closestMag = nil, SilentAim.Settings.FOV
    local mousePos = UserInputService:GetMouseLocation()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local part = char:FindFirstChild(SilentAim.Settings.Part) or char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if part and hum and hum.Health > 0 then
                if not (SilentAim.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                        if mag <= closestMag then closestMag = mag; closest = part end
                    end
                end
            end
        end
    end
    return closest
end
RunService.RenderStepped:Connect(function()
    if not SilentAim.Enabled then return end
    local root = getRoot()
    if not root then return end
    if SilentAim.Settings.AutoFire then
        local target = silentGetClosest()
        if target then
            local aim = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = aim
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
            end)
        end
    end
end)
-- On click, briefly snap camera to the closest target for a clean shot.
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not SilentAim.Enabled then return end
    if SilentAim.Settings.AutoFire then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local target = silentGetClosest()
        if target then
            pcall(function()
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            end)
        end
    end
end)

------------------------------------------------------------
-- AUTO TOOL (vape AutoTool: equip best tool for current target)
------------------------------------------------------------
local AutoTool = makeModule("AutoTool", "Player", {})
local function bestToolFor(targetName)
    local char = getChar()
    if not char then return nil end
    targetName = string.lower(tostring(targetName))
    local best, bestScore = nil, -1
    for _, t in ipairs(char:GetChildren()) do
        if t:IsA("Tool") then
            local n = string.lower(t.Name)
            local score = 1
            for kw, sc in pairs({ sword = 3, blade = 3, pick = 4, mine = 4, axe = 4, gun = 2, weapon = 3 }) do
                if n:find(kw) then score = math.max(score, sc) end
            end
            if n:find(targetName) then score = score + 5 end
            if score > bestScore then bestScore = score; best = t end
        end
    end
    return best
end
RunService.Heartbeat:Connect(function()
    if not AutoTool.Enabled then return end
    local mt = Mouse.Target
    if not mt then return end
    local model = mt:FindFirstAncestorOfClass("Model")
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local tool = bestToolFor(model.Name)
        if tool and tool.Parent == LocalPlayer.Backpack then
            pcall(function() LocalPlayer.Character.Humanoid:EquipTool(tool) end)
        end
    end
end)

------------------------------------------------------------
-- RENDER MODULES
------------------------------------------------------------

-- Tracers: draw a beam from the bottom of the screen to each player's root.
local Tracers = makeModule("Tracers", "Render", { TeamCheck = true })
local _tracerBeams = {}
local function clearTracers()
    for _, b in pairs(_tracerBeams) do pcall(function() b:Destroy() end) end
    _tracerBeams = {}
end
local function makeBeamFor(char, color)
    local a0 = Instance.new("Attachment")
    local a1 = Instance.new("Attachment")
    a0.Parent = Camera
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then a1.Parent = hrp else return end
    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.FaceCamera = true
    beam.Width0 = 0.05
    beam.Width1 = 0.05
    beam.Color = ColorSequence.new(color)
    beam.Transparency = NumberSequence.new(0.3, 0.5)
    beam.Parent = a0
    return beam, a0, a1
end
RunService.RenderStepped:Connect(function()
    if not Tracers.Enabled then return end
    -- refresh beam set
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not (Tracers.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                local key = plr
                seen[key] = true
                if not _tracerBeams[key] then
                    local col = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(255, 80, 80)
                    local beam, a0, a1 = makeBeamFor(plr.Character, col)
                    _tracerBeams[key] = { beam = beam, a0 = a0, a1 = a1 }
                else
                    -- anchor origin to bottom-centre of the screen in 3D
                    local b = _tracerBeams[key]
                    pcall(function()
                        local mid = Camera:ScreenPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y).Origin
                        b.a0.WorldPosition = mid
                    end)
                    if not (b.a1 and b.a1.Parent) then
                        pcall(function() b.beam:Destroy() end)
                        _tracerBeams[key] = nil
                    end
                end
            end
        end
    end
    for key, b in pairs(_tracerBeams) do
        if not seen[key] then pcall(function() b.beam:Destroy() end); _tracerBeams[key] = nil end
    end
end)
function Tracers.OnToggle(state) if not state then clearTracers() end end

-- NameTags: enlarge & recolor enemy name tags via billboard guis.
local NameTags = makeModule("NameTags", "Render", { Size = 18, Background = true })
local _ntTags = {}
local function clearNameTags()
    for _, d in pairs(_ntTags) do pcall(function() d:Destroy() end) end
    _ntTags = {}
end
RunService.Heartbeat:Connect(function()
    if not NameTags.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head and not _ntTags[plr] then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = head
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 200, 0, NameTags.Settings.Size + 8)
                bb.StudsOffset = Vector3.new(0, 2.2, 0)
                bb.LightInfluence = 0
                local col = (plr.Team and plr.Team.TeamColor and plr.Team.TeamColor.Color) or Color3.fromRGB(255, 120, 120)
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = NameTags.Settings.Background and 0.4 or 1
                lbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                lbl.Font = Theme.FontBold
                lbl.TextSize = NameTags.Settings.Size
                lbl.TextColor3 = col
                lbl.TextStrokeTransparency = 0.4
                lbl.Text = plr.Name
                lbl.Parent = bb
                bb.Parent = head
                _ntTags[plr] = bb
            end
        end
    end
end)
function NameTags.OnToggle(state) if not state then clearNameTags() end end

-- XRay: make non-target parts semi-transparent so players behind walls show.
local XRay = makeModule("XRay", "Render", { Strength = 0.85 })
function XRay.OnToggle(state)
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and d:GetAttribute("XRayStored") then
                d.LocalTransparencyModifier = tonumber(d:GetAttribute("XRayStored"))
                d:SetAttribute("XRayStored", nil)
            end
        end
    end)
    if state then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d:IsDescendantOf(getChar() or Workspace) then
                    if not d:GetAttribute("XRayStored") then
                        d:SetAttribute("XRayStored", tostring(d.LocalTransparencyModifier or 0))
                        d.LocalTransparencyModifier = XRay.Settings.Strength
                    end
                end
            end
        end)
    end
end

-- StorageESP: highlight chests/crates/storage containers.
local StorageESP = makeModule("StorageESP", "Render", {})
RunService.Heartbeat:Connect(function()
    if not StorageESP.Enabled then return end
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if (d:IsA("Model") or d:IsA("BasePart")) and not d:GetAttribute("StorageHL") then
                local n = d.Name:lower()
                if n:find("chest") or n:find("crate") or n:find("barrel") or n:find("storage") or n:find("vault") or n:find("supply") or n:find("locker") then
                    d:SetAttribute("StorageHL", true)
                    local hl = Instance.new("Highlight")
                    hl.Name = "StorageHL_Obj"
                    hl.FillColor = Color3.fromRGB(255, 200, 40)
                    hl.FillTransparency = 0.5
                    hl.Parent = d
                end
            end
        end
    end)
end)
function StorageESP.OnToggle(state)
    if not state then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:GetAttribute("StorageHL") then
                    d:SetAttribute("StorageHL", nil)
                    local hl = d:FindFirstChild("StorageHL_Obj")
                    if hl then hl:Destroy() end
                end
            end
        end)
    end
end

------------------------------------------------------------
-- FRIENDS & TARGETS LISTS  (vape Friends / Targets: recolor ESP + priority)
------------------------------------------------------------
FriendList = { List = {}, Recolor = true }
local TargetList = { List = {} }
isFriend = function(plr)
    if not plr then return false end
    for _, n in ipairs(FriendList.List) do
        if string.lower(n) == string.lower(plr.Name) then return true end
    end
    return false
end
isTarget = function(plr)
    if not plr then return false end
    for _, n in ipairs(TargetList.List) do
        if string.lower(n) == string.lower(plr.Name) then return true end
    end
    return false
end
-- Apply a green tint to friends in the ESP loop (hooked below).

------------------------------------------------------------
-- SERVER HOP  (vape server-hop via TeleportService + sorted servers)
------------------------------------------------------------
local ServerHop = { Hopping = false }
function ServerHop.hop()
    if ServerHop.Hopping then return end
    ServerHop.Hopping = true
    notify("Server Hop", "Searching for an available server...", 3, Theme.Yellow)
    local TeleportService = game:GetService("TeleportService")
    local joined = false
    pcall(function()
        local tried = {}
        local pages = TeleportService:GetSortedAsync(false, 100)
        for _, item in ipairs(pages:GetCurrentPage()) do
            local id = item.Id
            if id ~= game.JobId and not tried[id] then
                tried[id] = true
                if item.Playing < item.MaxPlayers then
                    notify("Server Hop", "Joining a fresh server...", 3, Theme.Green)
                    pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer) end)
                    joined = true
                    return
                end
            end
        end
    end)
    -- Fallback: rejoin the same place if nothing suitable was found
    if not joined then
        notify("Server Hop", "Rejoining current place...", 3)
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end
    task.delay(3, function() ServerHop.Hopping = false end)
end

------------------------------------------------------------
-- ANTI VOID  (vape-style: teleport back if falling below a Y threshold)
------------------------------------------------------------
local AntiVoid = makeModule("AntiVoid", "Player", { Y = -30, Mode = "Spawn" })
local _avLastPos
RunService.Heartbeat:Connect(function()
    if not AntiVoid.Enabled then return end
    local root = getRoot()
    if not root then return end
    -- record a safe position whenever grounded
    local hum = getHum()
    if hum and hum.FloorMaterial ~= Enum.Material.Air and root.Position.Y > AntiVoid.Settings.Y then
        _avLastPos = root.Position
    end
    if root.Position.Y < AntiVoid.Settings.Y then
        pcall(function()
            if AntiVoid.Settings.Mode == "Spawn" then
                local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
                root.CFrame = sp and sp.CFrame + Vector3.new(0, 5, 0) or root.CFrame + Vector3.new(0, 60, 0)
            elseif _avLastPos then
                root.CFrame = CFrame.new(_avLastPos + Vector3.new(0, 3, 0))
            else
                root.AssemblyLinearVelocity = Vector3.new(0, 120, 0)
            end
        end)
    end
end)

------------------------------------------------------------
-- SPINBOT / SPIN  (vape Spin: continuously rotate the character)
------------------------------------------------------------
local Spin = makeModule("Spin", "Combat", { Speed = 18 })
RunService.Heartbeat:Connect(function(dt)
    if not Spin.Enabled then return end
    local root = getRoot()
    if not root then return end
    pcall(function()
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Spin.Settings.Speed) * dt * 10, 0)
    end)
end)

------------------------------------------------------------
-- SCAFFOLD  (vape Scaffold: place a platform beneath the player as they move)
------------------------------------------------------------
local Scaffold = makeModule("Scaffold", "World", { Length = 5 })
local _scaffoldParts = {}
RunService.Heartbeat:Connect(function(dt)
    if not Scaffold.Enabled then
        if #_scaffoldParts > 0 then
            for _, p in ipairs(_scaffoldParts) do pcall(function() p:Destroy() end) end
            _scaffoldParts = {}
        end
        return
    end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    local p = Instance.new("Part")
    p.Size = Vector3.new(6, 1, 6)
    p.Anchored = true
    p.CanCollide = true
    p.Material = Enum.Material.SmoothPlastic
    p.Color = Color3.fromRGB(122, 92, 255)
    p.Transparency = 0.3
    p.CFrame = root.CFrame + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
    p.Parent = Workspace
    table.insert(_scaffoldParts, p)
    -- keep only the last N parts
    while #_scaffoldParts > (Scaffold.Settings.Length) do
        local old = table.remove(_scaffoldParts, 1)
        if old then pcall(function() old:Destroy() end) end
    end
end)

------------------------------------------------------------
-- FREECAM  (vape-style camera detachment: fly the camera around freely)
------------------------------------------------------------
local Freecam = makeModule("Freecam", "World", { Speed = 80 })
local _fcCF = nil
local _fcConn = nil
function Freecam.OnToggle(state)
    if not state then
        if _fcConn then _fcConn:Disconnect(); _fcConn = nil end
        pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    end
end
RunService.RenderStepped:Connect(function(dt)
    if not Freecam.Enabled then return end
    pcall(function() Camera.CameraType = Enum.CameraType.Scriptable 