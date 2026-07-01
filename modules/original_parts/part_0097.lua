FillColor = Color3.fromRGB(255, 120, 255)
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
    w:AddToggle("Distance", true, function(v) ESP.Config