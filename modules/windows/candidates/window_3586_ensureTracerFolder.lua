local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    if _tracerFolder and _tracerFolder.Parent then return _tracerFolder end
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
    pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
    if not _fcCF then _fcCF = Camera.CFrame end
    local f = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
    local r = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
    local u = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
    local dir = _fcCF.LookVector * f + _fcCF.RightVector * r + Vector3.new(0, 1, 0) * u
    if dir.Magnitude > 0 then dir = dir.Unit end
    _fcCF = _fcCF + dir * Freecam.Settings.Speed * dt
    Camera.CFrame = _fcCF
end)
-- mouse look for freecam
UserInputService.InputChanged:Connect(function(input)
    if not Freecam.Enabled then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local sens = 0.15
        local x, y = _fcCF:ToOrientation()
        _fcCF = CFrame.new(_fcCF.Position) * CFrame.fromOrientation(
            math.clamp(x - input.Delta.Y * sens * 0.01, -math.rad(80), math.rad(80)),
            y - input.Delta.X * sens * 0.01,
            0
        )
    end
end)

------------------------------------------------------------
-- WAYPOINTS  (vape Waypoints: save / load / teleport to stored locations)
------------------------------------------------------------
local Waypoints = { List = {}, File = "MultiGameHub_Waypoints.json" }
function Waypoints.save()
    pcall(function()
        if writefile then writefile(Waypoints.File, HttpService:JSONEncode(Waypoints.List)) end
    end)
end
function Waypoints.load()
    local ok, res = pcall(function()
        if not (isfile and isfile(Waypoints.File)) then return {} end
        return HttpService:JSONDecode(readfile(Waypoints.File))
    end)
    if ok and type(res) == "table" then Waypoints.List = res end
end
function Waypoints.addCurrent(name)
    local root = getRoot()
    if not root then return end
    table.insert(Waypoints.List, { name = name or ("WP " .. #Waypoints.List + 1), pos = { root.Position.X, root.Position.Y, root.Position.Z } })
    Waypoints.save()
end
function Waypoints.teleport(name)
    for _, wp in ipairs(Waypoints.List) do
        if wp.name == name then
            teleportTo(Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3]))
            return true
        end
    end
    return false
end
Waypoints.load()

------------------------------------------------------------
-- SEARCH ESP  (vape SearchESP / ESPFinder: highlight any object by name)
------------------------------------------------------------
local SearchESP = makeModule("SearchESP", "Render", { Keyword = "", Color = Color3.fromRGB(122, 220, 255) })
local _searchHL = {}
function SearchESP.OnToggle(state)
    if not state then
        for _, h in ipairs(_searchHL) do pcall(function() h:Destroy() end) end
        _searchHL = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not SearchESP.Enabled then return end
    if SearchESP.Settings.Keyword == "" then return end
    local kw = string.lower(SearchESP.Settings.Keyword)
    for _, d in ipairs(Workspace:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("BasePart")) and string.lower(d.Name):find(kw) then
            if not d:GetAttribute("SearchESP") then
                d:SetAttribute("SearchESP", true)
                local hl = Instance.new("Highlight")
                hl.Name = "SearchESP_HL"
                hl.FillColor = SearchESP.Settings.Color
                hl.FillTransparency = 0.45
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Parent = d
                table.insert(_searchHL, hl)
            end
        end
    end
end)

------------------------------------------------------------
-- KILLAURA SWING ANIMATIONS  (vape auraanims via Motor6D RightGrip)
------------------------------------------------------------
local SwingAnim = makeModule("SwingAnim", "Render", { Style = "Normal" })
local _auraFrames = {
    Normal = {
        { CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1 },
        { CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08 },
        { CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03 },
        { CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03 },
    },
    ["Horizontal Spin"] = {
        { CFrame = CFrame.Angles(math.rad(-10), math.rad(-90), math.rad(-80)), Time = 0.12 },
        { CFrame = CFrame.Angles(math.rad(-10), math.rad(180), math.rad(-80)), Time = 0.12 },
        { CFrame = CFrame.Angles(math.rad(-10), math.rad(90), math.rad(-80)), Time = 0.12 },
        { CFrame = CFrame.Angles(math.rad(-10), 0, math.rad(-80)), Time = 0.12 },
    },
    ["Vertical Spin"] = {
        { CFrame = CFrame.Angles(math.rad(-90), 0, math.rad(15)), Time = 0.12 },
        { CFrame = CFrame.Angles(math.rad(180), 0, math.rad(15)), Time = 0.12 },
        { CFrame = CFrame.Angles(math.rad(90), 0, math.rad(15)), Time = 0.12 },
        { CFrame = CFrame.Angles(0, 0, math.rad(15)), Time = 0.12 },
    },
}
local _animMotor, _animConn, _animIndex, _animClock
local function playSwingAnim()
    if not SwingAnim.Enabled then return end
    local char = getChar()
    if not char then return end
    local arm = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    if not arm then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    -- find or create a motor on the right grip
    if not _animMotor or not _animMotor.Parent then
        _animMotor = Instance.new("Motor6D")
        _animMotor.Part0 = arm
        _animMotor.Part1 = tool:FindFirstChild("Handle")
        _animMotor.Parent = arm
    end
    _animIndex = 1
    _animClock = tick()
end
RunService.RenderStepped:Connect(function()
    if not (SwingAnim.Enabled and _animMotor and _animMotor.Parent) then return end
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

------------------------------------------------------------
-- TPAURA / TELEPORT AURA  (teleport-strike each nearby enemy in sequence)
------------------------------------------------------------
local TPAura = makeModule("TPAura", "Combat", { Range = 40, Delay = 0.2 })
local _tpaLast = 0
RunService.Heartbeat:Connect(function()
    if not TPAura.Enabled then return end
    if tick() - _tpaLast < TPAura.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    local best, bestD = nil, TPAura.Settings.Range
    for _, t in ipairs(getTargetsInRange(TPAura.Settings.Range, false, true)) do
        if t.dist < bestD then bestD = t.dist; best = t end
    end
    if best then
        _tpaLast = tick()
        pcall(function()
            TeleportPro.pushHistory()
            root.CFrame = best.hrp.CFrame * CFrame.new(0, 0, 4)
            swingTool()
        end)
    end
end)

------------------------------------------------------------
-- BRINGER  (pull all nearby enemies/objects toward you continuously)
------------------------------------------------------------
local Bringer = makeModule("Bringer", "World", { Range = 60, Targets = "Players" })
RunService.Heartbeat:Connect(function()
    if not Bringer.Enabled then return end
    local root = getRoot()
    if not root then return end
    if Bringer.Settings.Targets == "Players" then
        for _, t in ipairs(getTargetsInRange(Bringer.Settings.Range, false, true)) do
            pcall(function() t.hrp.CFrame = root.CFrame * CFrame.new(0, 0, -3) end)
        end
    else
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - root.Position).Magnitude < Bringer.Settings.Range then
                    pcall(function() hrp.CFrame = root.CFrame * CFrame.new(0, 0, -3) end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- FLING PLAYER  (select a player and fling them away)
------------------------------------------------------------
local FlingTarget = makeModule("FlingTarget", "Combat", {})
function FlingTarget.OnToggle(state)
    if state then
        notify("Fling", "Select a player in the Players panel, then click again.", 3, Theme.Yellow)
    end
end

------------------------------------------------------------
-- TRAIL / FOOTPRINTS  (leave glowing footprints behind you)
------------------------------------------------------------
local Footprints = makeModule("Footprints", "Render", { Color = Color3.fromRGB(122, 92, 255) })
local _fpParts = {}
local _fpLast = 0
RunService.Heartbeat:Connect(function()
    if not Footprints.Enabled then
        for _, p in ipairs(_fpParts) do pcall(function() p:Destroy() end) end
        _fpParts = {}
        return
    end
    local root = getRoot()
    if not root then return end
    if tick() - _fpLast > 0.15 then
        _fpLast = tick()
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.6, 0.6, 0.6)
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.Material = Enum.Material.Neon
        p.Color = Footprints.Settings.Color
        p.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0))
        p.Parent = Workspace
        table.insert(_fpParts, p)
        task.delay(3, function() pcall(function() p:Destroy() end) end)
        if #_fpParts > 60 then
            local old = table.remove(_fpParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- PLAYER VIEWPOINT  (see through another player's camera)
------------------------------------------------------------
local PlayerView = { Enabled = false, Target = nil, _conn = nil }
function PlayerView:Set(v)
    self.Enabled = v
    if v then
        self._conn = RunService.RenderStepped:Connect(function()
            local target = self.Target
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    pcall(function()
                        Camera.CameraType = Enum.CameraType.Scriptable
                        Camera.CFrame = head.CFrame * CFrame.new(0, 0, -3)
                    end)
                end
            end
        end)
    else
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

------------------------------------------------------------
-- AUTO DODGE PLAYER  (teleport away when a player aims at you)
------------------------------------------------------------
local AutoDodgePlayer = makeModule("AutoDodgePlayer", "Combat", { Range = 30 })
RunService.Heartbeat:Connect(function()
    if not AutoDodgePlayer.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                -- if a player's look vector points near us, dodge
                local toMe = (root.Position - head.Position).Unit
                local look = head.CFrame.LookVector
                local dot = look:Dot(toMe)
                local dist = (head.Position - root.Position).Magnitude
                if dot > 0.95 and dist < AutoDodgePlayer.Settings.Range then
                    local side = toMe:Cross(Vector3.new(0, 1, 0))
                    if side.Magnitude > 0 then
                        pcall(function() root.CFrame = root.CFrame + side.Unit * 8 end)
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- INFINITE AMMO  (best-effort: reset ammo values)
------------------------------------------------------------
local InfiniteAmmo = makeModule("InfiniteAmmo", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not InfiniteAmmo.Enabled then return end
    pcall(function()
        local char = getChar()
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            -- many games store ammo as attributes/values
            tool:SetAttribute("Ammo", 999)
            tool:SetAttribute("Magazine", 999)
            tool:SetAttribute("Clip", 999)
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Magazine")
            if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
        end
        trySetStat("ammo", 999)
    end)
end)

------------------------------------------------------------
-- NO SPREAD  (reduce camera shake/spread via steady CFrame)
------------------------------------------------------------
local NoSpread = makeModule("NoSpread", "Combat", {})
local _nsOldFOV
RunService.RenderStepped:Connect(function()
    if not NoSpread.Enabled then return end
    pcall(function()
        -- neutralize field-of-view punch effects
        Camera.FieldOfView = CameraFOV.Enabled and CameraFOV.Value or 70
    end)
end)

------------------------------------------------------------
-- INSTANT BREAK  (break all destructibles within range)
------------------------------------------------------------
local InstantBreak = makeModule("InstantBreak", "World", { Range = 50 })
RunService.Heartbeat:Connect(function()
    if not InstantBreak.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("break") or n:find("destroy") or n:find("glass") or n:find("destructible") then
                if (d.Position - root.Position).Magnitude < InstantBreak.Settings.Range then
                    pcall(function()
                        firetouchinterest(root, d, 0)
                        d.CanCollide = false
                    end)
                end
            end
        end
    end
    fireRemotes("break"); fireRemotes("destroy")
end)

------------------------------------------------------------
-- AUTO REVIVE TEAMMATES  (teleport to & touch downed allies)
------------------------------------------------------------
local AutoReviveTeam = makeModule("AutoReviveTeam", "Player", { Range = 200 })
RunService.Heartbeat:Connect(function()
    if not AutoReviveTeam.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                -- can't revive a fully dead player; look for "downed" state
            end
            if hum and hrp and hum:GetState() == Enum.HumanoidStateType.PlatformStanding then
                if (hrp.Position - root.Position).Magnitude < AutoReviveTeam.Settings.Range then
                    pcall(function()
                        root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0))
                        firetouchinterest(root, hrp, 0)
                    end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- AFK TELEPORT LOOP  (walk a small box to stay active)
------------------------------------------------------------
local AFKTeleport = makeModule("AFKTeleport", "Player", { Delay = 10 })
local _afkPos
RunService.Heartbeat:Connect(function()
    if not AFKTeleport.Enabled then return end
    if not _afkPos then local root = getRoot(); if root then _afkPos = root.Position end end
    if not AFKTeleport._t or tick() - AFKTeleport._t > AFKTeleport.Settings.Delay then
        AFKTeleport._t = tick()
        local root = getRoot()
        if root and _afkPos then
            -- small random offset to trigger movement
            pcall(function()
                root.CFrame = CFrame.new(_afkPos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
            end)
        end
    end
end)

------------------------------------------------------------
-- COPY TELEPORT  (teleport to a copied CFrame from clipboard)
------------------------------------------------------------
local function teleportFromClipboard()
    pcall(function()
        if not (getclipboard or readclipboard) then notify("Teleport", "No clipboard access.", 2.5, Theme.Yellow); return end
        local txt = (getclipboard and getclipboard()) or (readclipboard and readclipboard()) or ""
        -- parse "x, y, z"
        local nums = {}
        for n in txt:gmatch("-?%d+%.?%d*") do table.insert(nums, tonumber(n)) end
        if #nums >= 3 then
            teleportTo(Vector3.new(nums[1], nums[2], nums[3]))
            notify("Teleport", "Teleported to clipboard coords.", 3, Theme.Accent)
        else
            notify("Teleport", "Clipboard has no valid coords.", 2.5, Theme.Yellow)
        end
    end)
end

------------------------------------------------------------
-- AUTO LOBBY REJOIN  (rejoin if alone for too long)
------------------------------------------------------------
local LobbyRejoin = makeModule("LobbyRejoin", "Player", { MinPlayers = 1, CheckDelay = 30 })
RunService.Heartbeat:Connect(function()
    if not LobbyRejoin.Enabled then return end
    if not LobbyRejoin._t or tick() - LobbyRejoin._t > LobbyRejoin.Settings.CheckDelay then
        LobbyRejoin._t = tick()
        if #Players:GetPlayers() <= LobbyRejoin.Settings.MinPlayers then
            if not LobbyRejoin._waitStart then LobbyRejoin._waitStart = tick() end
            if tick() - LobbyRejoin._waitStart > 60 then
                notify("LobbyRejoin", "Server seems empty - rejoining.", 3, Theme.Yellow)
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                LobbyRejoin._waitStart = nil
            end
        else
            LobbyRejoin._waitStart = nil
        end
    end
end)

------------------------------------------------------------
-- NPC FARM ROUTE  (teleport between all NPC spawns in a loop)
------------------------------------------------------------
local NPCFarmRoute = makeModule("NPCFarmRoute", "Combat", { Delay = 0.3, Range = 30 })
local _nfrIndex = 1
local _nfrLast = 0
RunService.Heartbeat:Connect(function()
    if not NPCFarmRoute.Enabled then return end
    if tick() - _nfrLast < NPCFarmRoute.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    -- collect all NPCs
    local npcs = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            local hrp = d:FindFirstChild("HumanoidRootPart")
            local hum = d:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then table.insert(npcs, { char = d, hrp = hrp, hum = hum }) end
        end
    end
    if #npcs == 0 then return end
    _nfrIndex = (_nfrIndex % #npcs) + 1
    local target = npcs[_nfrIndex]
    _nfrLast = tick()
    pcall(function()
        root.CFrame = target.hrp.CFrame * CFrame.new(0, 0, NPCFarmRoute.Settings.Range)
    end)
    swingTool()
end)

------------------------------------------------------------
-- INVENTORY ESP  (highlight dropped tools / items on the ground)
------------------------------------------------------------
local InventoryESP = makeModule("InventoryESP", "Render", {})
function InventoryESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not InventoryESP.Enabled then return end
    highlightKeywords({ "tool", "weapon", "item", "drop", "pickup", "sword", "gun", "potion" }, Color3.fromRGB(120, 220, 255))
end)

------------------------------------------------------------
-- AUTO QUEST  (fire quest-related remotes continuously)
------------------------------------------------------------
local AutoQuest = makeModule("AutoQuest", "World", {})
RunService.Heartbeat:Connect(function()
    if not AutoQuest.Enabled then return end
    fireRemotes("quest"); fireRemotes("accept"); fireRemotes("turnin"); fireRemotes("claimquest")
end)

------------------------------------------------------------
-- ANTI STUN  (auto-recover from stun/freeze states)
------------------------------------------------------------
local AntiStun = makeModule("AntiStun", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not AntiStun.Enabled then return end
    local hum = getHum()
    if not hum then return end
    -- force out of stunned/frozen states
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.PlatformStanding then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    -- clear slow/stun attributes
    pcall(function()
        local root = getRoot()
        if root then root:SetAttribute("Stunned", false); root:SetAttribute("Frozen", false) end
    end)
end)

------------------------------------------------------------
-- AUTO COLLECT DROPS  (touch any dropped/loot parts within range)
------------------------------------------------------------
local AutoDrops = makeModule("AutoDrops", "World", { Range = 80 })
RunService.Heartbeat:Connect(function()
    if not AutoDrops.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("drop") or n:find("loot") or n:find("pickup") or n:find("reward") then
                if (d.Position - root.Position).Magnitude < AutoDrops.Settings.Range then
                    pcall(function() firetouchinterest(root, d, 0) end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- GHOST / VANISH  (make local character semi-invisible to avoid detection)
------------------------------------------------------------
local Ghost = makeModule("Ghost", "Render", {})
local _ghostOrig = {}
function Ghost.OnToggle(state)
    pcall(function()
        local char = getChar()
        if not char then return end
        if state then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    if not _ghostOrig[p] then _ghostOrig[p] = p.LocalTransparencyModifier end
                    p.LocalTransparencyModifier = 0.6
                end
            end
        else
            for p, v in pairs(_ghostOrig) do
                if p and p.Parent then p.LocalTransparencyModifier = v end
            end
            _ghostOrig = {}
        end
    end)
end

------------------------------------------------------------
-- HEAD HITBOX  (force target the head part for all combat)
------------------------------------------------------------
local HeadTarget = makeModule("HeadTarget", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not HeadTarget.Enabled then return end
    Aimbot.Config.TargetPart = "Head"
    SilentAim.Settings.Part = "Head"
end)
function HeadTarget.OnToggle(state)
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
    w:AddToggle("FPS Counter", false, function(v) FPSModule:Set(v) end\n    end\nend\n\nreturn M\n
