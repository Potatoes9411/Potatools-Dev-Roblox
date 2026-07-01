0", TimeChanger.Value) end
    end)
    w:AddButton("Remove Fog", function() Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9 end)
    w:AddSection("Camera Modes")
    w:AddToggle("Freecam (WASD/Space/Ctrl)", false, function(v) Freecam:Set(v) end, "Fly the camera freely")
    w:AddSlider("Freecam Speed", 10, 400, 80, "", 0, function(v) Freecam.Settings.Speed = v end)
    w:AddToggle("Zoom (hold Z)", false, function(v) Zoom:Set(v) end)
    w:AddSlider("Zoom FOV", 5, 70, 30, "", 0, function(v) Zoom.Settings.FOV = v end)
    w:AddToggle("View Clip (FOV clamp)", false, function(v) ViewportClip:Set(v) end)
    w:AddSection("Performance")
    w:AddToggle("FPS Boost", false, function(v) FPSBoost:Set(v) end)
    w:AddSlider("Boost Level", 1, 3, 2, "", 0, function(v) FPSBoost.Settings.Level = v end)
    w:AddSection("Visuals")
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSlider("Crosshair Size", 2, 40, 10, "", 0, function(v) Crosshair.Size = v end)
    w:AddToggle("Crosshair Expand", false, function(v) CrosshairExpand:Set(v) end)
    w:AddToggle("XRay", false, function(v) XRay:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddToggle("Cape (animated)", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddSection("Sky / Weather")
    w:AddButton("Add Stars", function()
        pcall(function() Lighting.StarCount = 3000 end)
    end)
    w:AddButton("Add Sun Rays", function()
        local s = Instance.new("SunRaysEffect"); s.Intensity = 0.1; s.Spread = 0.6; s.Parent = Lighting
    end)
    w:AddButton("Reset Lighting", function()
        pcall(function()
            Lighting.ClockTime = 14; Lighting.Brightness = 2; Lighting.FogEnd = 1e5
            for _, e in ipairs(Lighting:GetChildren()) do if e:IsA("PostEffect") or e:IsA("SunRaysEffect") or e:IsA("BloomEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("Atmosphere") then e:Destroy() end end
        end)
    end, Theme.Yellow)
    notify("Camera Suite", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// MORE GAMES  (rounding out the catalogue)
--==============================================================================

--===== STRUCID =====
local function Strucid()
    local w = buildFPSWindow("Strucid", Color3.fromRGB(120, 180, 255))
    w:AddSection("Strucid Extras")
    w:AddToggle("Auto Build / Place", false, function(v) w._build = v end)
    w:AddToggle("Bunny Hop", false, function(v) w._bhop = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 40, 18, "studs", 0, function(v) w._arange = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._build then swingTool(); fireRemotes("place"); fireRemotes("build") end
            if w._bhop then
                local h = getHum(); local r = getRoot()
                if h and r and h.FloorMaterial ~= Enum.Material.Air then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, false, true)) do swingTool() end end
        end
    end)
    return w
end

--===== APOCALYPSE RISING =====
local function ApocalypseRising()
    local w = buildFPSWindow("Apocalypse Rising", Color3.fromRGB(120, 140, 90))
    w:AddSection("Survival Extras")
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Zombie ESP", false, function(v) w._zEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Loot Nearby", false, function(v) w._loot = v end)
    w:AddSlider("Loot Range", 20, 300, 80, "studs", 0, function(v) w._range = v end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._lEsp then highlightKeywords({ "loot", "weapon", "ammo", "item", "food", "medical" }, Color3.fromRGB(255, 200, 40)) end
            if w._zEsp then highlightKeywords({ "zombie", "enemy", "npc", "infected" }, Color3.fromRGB(255, 60, 60)) end
            if root and w._loot then touchNamed(root, { "loot", "weapon", "ammo", "item", "food" }, w._range or 80) end
        end
    end)
    return w
end

--===== VEHICLE LEGENDS =====
local function VehicleLegends()
    local w = createWindow("Vehicle Legends", "Drive Suite", 460, 520, randPos())
    w:AddSection("Driving")
    w:AddToggle("Auto Drive (W)", false, function(v) w._drive = v end)
    w:AddToggle("Infinite Nitro", false, function(v) w._nitro = v end)
    w:AddToggle("Anti-Flip", false, function(v) w._flip = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 800, 200, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._drive then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end
            if w._nitro then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); fireRemotes("nitro") end
            if w._flip then
                pcall(function()
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("VehicleSeat") and d.Occupant then d.RotVelocity = Vector3.zero end
                    end
                end)
            end
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "pickup" }, w._range or 200) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "pickup", "chest" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Vehicle Legends", "Loaded.", 3, Color3.fromRGB(255, 90, 90))
    return w
end

--===== ROBLOX HIGH SCHOOL 2 =====
local function RobloxHigh2()
    local w = createWindow("Roblox High School 2", "Campus Suite", 460, 500, randPos(460, 500))
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    w:AddSection("Teleport")
    local loc = { { "School", Vector3.new(0,5,0) }, { "Gym", Vector3.new(120,5,40) }, { "Pool", Vector3.new(-80,5,-40) }, { "Cafeteria", Vector3.new(90,5,40) } }
    for _, l in ipairs(loc) do w:AddButton("TP: " .. l[1], function() teleportTo(l[2]) end) end
    notify("Roblox High School 2", "Loaded.", 3, Color3.fromRGB(255, 120, 180))
    return w
end

--===== TWITCH STRATEGIES / AUTO STRATEGY =====
local function AutoStrategy()
    local w = createWindow("Auto Strategy", "Auto-Play Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Place Units", false, function(v) w._place = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Start Round", false, function(v) w._round = v end)
    w:AddToggle("Auto Replay", false, function(v) w._replay = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._place then fireRemotes("place"); fireRemotes("deploy") end
            if w._up then fireRemotes("upgrade") end
            if w._round then fireRemotes("start"); fireRemotes("round") end
            if w._replay then fireRemotes("replay") end
            if w._eEsp then highlightKeywords({ "enemy", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
        end
    end)
    notify("Auto Strategy", "Loaded.", 3, Theme.Accent)
    return w
end

--===== APOCALYPSE / ZOMBIE SURVIVAL =====
local function ZombieSurvival()
    local w = createWindow("Zombie Survival", "Wave Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Zombies", false, function(v) w._farm = v end)
    w:AddToggle("Auto Shoot", false, function(v) w._shoot = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 400)
    w:AddSection("Survival")
    w:AddToggle("Auto Buy Weapons", false, function(v) w._buy = v end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddSection("Visuals")
    w:AddToggle("Zombie ESP", false, function(v) w._zEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm or w._shoot then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if w._farm and dist > (w._range or 60) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 60), 25) end)
                        end
                        swingTool()
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                    end
                end
                if w._buy then fireRemotes("buy"); fireRemotes("weapon") end
                if w._revive and not isAlive() then fireRemotes("revive"); task.wait(1) end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._zEsp then highlightKeywords({ "zombie", "enemy", "boss", "mob", "undead" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Zombie Survival", "Loaded.", 3, Color3.fromRGB(120, 200, 80))
    return w
end

--===== KNIFE / MELEE SIMULATOR =====
local function KnifeSim()
    local w = createWindow("Knife Simulator", "Throw Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Throw (click)", false, function(v) w._throw = v end)
    w:AddSlider("Throw Delay", 0.05, 1, 0.15, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Knives", false, function(v) w._buy = v end)
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Coin Range", 20, 500, 150, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            local root = getRoot()
            if w._throw and tick() - last >= (w._delay or 0.15) then
                last = tick()
                swingTool()
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy"); fireRemotes("knife") end
            if root and w._coins then touchNamed(root, { "coin", "cash", "pickup" }, w._range or 150) end
            if w._cEsp then highlightKeywords({ "coin", "cash", "pickup", "chest" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Knife Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--===== TAPPING / TAP SIMULATOR =====
local function TapSim()
    local w = createWindow("Tap Simulator", "Auto Tap Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Tap", false, function(v) w._tap = v end)
    w:AddSlider("Delay", 0.01, 0.5, 0.05, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Hatch Pets", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            if w._tap and tick() - last >= (w._delay or 0.05) then
                last = tick()
                fireRemotes("tap"); fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._hatch then fireRemotes("hatch") end
            if w._up then fireRemotes("upgrade"); fireRemotes("buy") end
        end
    end)
    notify("Tap Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--===== MURDER / SUS GAME =====
local function SusGame()
    local w = createWindow("Sus Game", "Among-Style Suite", 460, 520, randPos())
    w:AddSection("Role ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Impostor ESP (Red)", false, function(v) w._iEsp = v end)
    w:AddToggle("Task ESP", false, function(v) w._tEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Auto")
    w:AddToggle("Auto Do Tasks (touch)", false, function(v) w._tasks = v end)
    w:AddToggle("Impostor Alert", false, function(v) w._alert = v end)
    addMovement(w, 200, 350)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._tEsp then highlightKeywords({ "task", "wiring", "download", "vent" }, Color3.fromRGB(255, 200, 40)) end
            if root and w._tasks then touchNamed(root, { "task", "wiring", "download" }, 40) end
            if w._iEsp or w._alert then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local killer = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("knife") or t.Name:lower():find("kill") or t.Name:lower():find("gun")) then killer = true end
                        end
                        if killer then
                            if w._iEsp then
                                local hl = plr.Character:FindFirstChild("ESP_HL")
                                if hl then hl.FillColor = Color3.fromRGB(235, 40, 50) end
                            end
                            if w._alert and plr.Character:FindFirstChild("HumanoidRootPart") and root then
                                local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                                if d < 40 and (not w._lw or tick() - w._lw > 5) then
                                    w._lw = tick()
                                    notify("âš  SUS", plr.Name .. " is armed!", 3, Theme.Red)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Sus Game", "Loaded.", 3, Theme.Red)
    return w
end

--===== LIFT / WEIGHT GAME =====
local function LiftGame()
    local w = createWindow("Lift Game", "Train Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Lift (click)", false, function(v) w._lift = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy", false, function(v) w._buy = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._lift then swingTool() end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
        end
    end)
    notify("Lift Game", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// TOWER OF MISERY / ENDLESS OBBY
--==============================================================================
local function EndlessObby()
    local w = createWindow("Endless Obby", "Auto-Climb Suite", 460, 540, randPos())
    w:AddSection("Auto-Climb")
    w:AddToggle("Auto Skip (loop up)", false, function(v) w._skip = v end)
    w:AddSlider("Skip Amount", 50, 600, 250, "studs", 0, function(v) w._amt = v end)
    w:AddToggle("Auto Win (find finish)", false, function(v) w._win = v end)
    w:AddSection("Movement")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddSection("Safety")
    w:AddToggle("Disable Kill Bricks", false, function(v) w._noKill = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddToggle("Anti-Fall", false, function(v) NoFall:Set(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._skip then root.CFrame = root.CFrame + Vector3.new(0, w._amt or 250, 0); task.wait(0.5) end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._noKill then
                    pcall(function()
                        for _, d in ipairs(Workspace:GetDescendants()) do
                            if d:IsA("BasePart") then
                                local n = d.Name:lower()
                                if n:find("kill") or n:find("lava") or n:find("danger") then d.CanTouch = false end
                            end
                        end
                    end)
                end
            end
            if w._win then
                local best, by = nil, -math.huge
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local n = d.Name:lower()
                        if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("portal")) then by = d.Position.Y; best = d end
                    end
                end
                if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) end
            end
        end
    end)
    notify("Endless Obby", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// ZOMBIE / WAVE DEFENSE
--==============================================================================
local function WaveDefense()
    local w = createWindow("Wave Defense", "Defense Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Waves", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 60) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 60), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._up then fireRemotes("upgrade") end
                if w._revive and not isAlive() then fireRemotes("revive"); task.wait(1) end
                if w._eEsp then highlightKeywords({ "enemy", "zombie", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Wave Defense", "Loaded.", 3, Color3.fromRGB(120, 200, 80))
    return w
end

--==============================================================================
--// SHOOTER ARENA GENERIC
--==============================================================================
local function ShooterArena()
    local w = buildFPSWindow("Shooter Arena", Color3.fromRGB(255, 120, 80))
    w:AddSection("Arena Extras")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 50, 18, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, false, true)) do swingTool() end end
        end
    end)
    return w
end

--==============================================================================
--// MULTIPLAYER MINIGAMES COLLECTION
--==============================================================================
local function MinigamesCollection()
    local w = createWindow("Minigames Collection", "Party Suite", 460, 500, randPos())
    w:AddSection("Auto-Play")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddToggle("Auto Win (best-effort)", false, function(v) w._win = v end)
    w:AddToggle("Survival Hints ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    addMovement(w, 200, 400)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            if w._click and tick() - last > 0.1 then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._win then fireRemotes("win"); fireRemotes("complete") end
            if w._sEsp then highlightKeywords({ "safe", "goal", "finish", "win", "coin" }, Color3.fromRGB(76, 209, 142)) end
        end
    end)
    notify("Minigames Collection", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// IDLE FACTORY / CLICKER TYCOON
--==============================================================================
local function IdleFactory()
    local w = createWindow("Idle Factory", "Auto Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddSlider("Delay", 0.01, 1, 0.05, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Prestige", false, function(v) w._prestige = v end)
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.02)
            if w._click and tick() - last >= (w._delay or 0.05) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("click")
            end
            if w._up then fireRemotes("upgrade"); fireRemotes("buy") end
            if w._prestige then fireRemotes("prestige") end
            if w._collect then
                local root = getRoot()
                if root then touchNamed(root, { "drop", "coin", "cash", "pickup" }, w._range or 150) end
            end
            if w._lEsp then highlightKeywords({ "drop", "coin", "cash", "pickup", "chest" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Idle Factory", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// SWORD / BLADE COMBAT GAME
--==============================================================================
local function SwordCombat()
    local w = createWindow("Sword Combat", "Melee Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 50, 20, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end)
    w:AddToggle("Auto Block", false, function(v) w._block = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            local root = getRoot()
            if root then
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 20, false, true)) do swingTool() end end
                if w._block then
                    pcall(function()
                        local tool = getChar():FindFirstChildOfClass("Tool")
                        if tool and math.random() > 0.5 then tool:Activate() end
                    end)
                end
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 40) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 40), 25) end)
                        end
                        swingTool()
                    end
                end
            end
        end
    end)
    notify("Sword Combat", "Loaded.", 3, Color3.fromRGB(220, 60, 60))
    return w
end

--==============================================================================
--// MAGNET / COLLECT EVERYTHING
--==============================================================================
local function CollectEverything()
    local w = createWindow("Collect Everything", "Magnet Suite", 460, 500, randPos(460, 500))
    w:AddSection("Collect")
    w:AddToggle("Magnet (bring all to you)", false, function(v) w._mag = v end)
    w:AddSlider("Range", 20, 1000, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Collect Drops", false, function(v) AutoDrops:Set(v) end)
    w:AddToggle("Auto Pickup", false, function(v) AutoPickup:Set(v) end)
    w:AddInput("Filter Keyword", "", "e.g. coin", function(v) w._filter = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if not root then return end
            if w._mag then
                local filter = w._filter and string.lower(w._filter) or ""
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("BasePart") and not d:IsDescendantOf(getChar()) then
                        local n = d.Name:lower()
                        local ok = (filter == "") or n:find(filter)
                        if ok and (n:find("coin") or n:find("drop") or n:find("pickup") or n:find("item") or n:find("loot") or n:find("gem") or n:find("cash") or n:find("reward")) then
                            if (d.Position - root.Position).Magnitude < (w._range or 200) then
                                pcall(function() d.CFrame = root.CFrame end)
                            end
                        end
                    end
                end
            end
            if w._iEsp then highlightKeywords({ "coin", "drop", "pickup", "item", "loot", "gem", "cash" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Collect Everything", "Loaded.", 3, Color3.fromRGB(120, 220, 120))
    return w
end

--==============================================================================
--// ADVANCED MOVEMENT SUITE
--==============================================================================
local function MovementSuite()
    local w = createWindow("Movement Suite", "Advanced movement", 470, 620, randPos(470, 620))
    w:AddSection("Basic")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 500, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 500, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD/Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 600, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddSection("Advanced")
    w:AddToggle("Sprint", false, function(v) Sprint:Set(v) end)
    w:AddSlider("Sprint Speed", 16, 60, 22, "", 0, function(v) Sprint.Settings.Speed = v end)
    w:AddToggle("Speed Module", false, function(v) Speed:Set(v) end)
    w:AddDropdown("Speed Mode", { "Velocity", "CFrame", "WalkSpeed" }, "Velocity", function(v) Speed.Settings.Mode = v end)
    w:AddSlider("Speed Value", 10, 200, 30, "", 0, function(v) Speed.Settings.Value = v end)
    w:AddToggle("Step", false, function(v) Step:Set(v) end)
    w:AddSlider("Step Height", 2, 20, 4, "", 0, function(v) Step.Settings.Height = v end)
    w:AddToggle("No Fall", false, function(v) NoFall:Set(v) end)
    w:AddToggle("Jesus (walk on water)", false, function(v) Jesus:Set(v) end)
    w:AddToggle("Spider", false, function(v) Spider:Set(v) end)
    w:AddSlider("Spider Speed", 5, 60, 25, "", 0, function(v) Spider.Settings.Speed = v end)
    w:AddToggle("Float", false, function(v) Float:Set(v) end)
    w:AddDropdown("Float Mode", { "Velocity", "CFrame", "Floor" }, "Velocity", function(v) Float.Settings.Mode = v end)
    w:AddToggle("Sneak", false, function(v) Sneak:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddSection("Teleport")
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddToggle("Long Jump", false, function(v) LongJump:Set(v) end)
    w:AddSlider("Long Jump Power", 20, 200, 60, "", 0, function(v) LongJump.Settings.Power = v end)
    w:AddToggle("High Jump", false, function(v) HighJump:Set(v) end)
    w:AddToggle("Blink (TP forward)", false, function(v) Blink:Set(v) end)
    w:AddToggle("Tap TP (dash)", false, function(v) TapTP:Set(v) end)
    w:AddToggle("Air Stuck", false, function(v) AirStuck:Set(v) end)
    w:AddToggle("Slow Fall", false, function(v) SlowFall:Set(v) end)
    w:AddToggle("VelTP (shift)", false, function(v) VelTP:Set(v) end)
    w:AddSection("Physics")
    w:AddToggle("Gravity Control", false, function(v) GravityMod:Set(v) end)
    w:AddSlider("Gravity Mult", 0, 3, 1, "x", 2, function(v) GravityMod.Settings.Mult = v end)
    w:AddToggle("Anti Stun", false, function(v) AntiStun:Set(v) end)
    w:AddToggle("Anti Water/Lava", false, function(v) AntiLiquid:Set(v) end)
    w:AddToggle("Anti Explosion", false, function(v) AntiExplosion:Set(v) end)
    w:AddToggle("Anti Void", false, function(v) AntiVoid:Set(v) end)
    w:AddSection("Reset")
    w:AddButton("Reset Gravity", function() GravityMod:Set(false); Workspace.Gravity = 196.2 end, Theme.Yellow)
    w:AddButton("PANIC: Disable Movement", function()
        Movement.WalkSpeed.Enabled = false; Movement.JumpPower.Enabled = false; Movement.InfJump = false
        Movement.Noclip = false; Movement.Fly.Enabled = false; ClickTP.Enabled = false
        for _, n in ipairs({ "Sprint","Speed","Step","NoFall","Jesus","Spider","Float","Sneak","BunnyHop","LongJump","HighJump","Blink","TapTP","AirStuck","SlowFall","VelTP","GravityMod","AntiStun","AntiLiquid","AntiExplosion","AntiVoid" }) do
            local m = Modules[n]
            if m and m.Enabled then m:Set(false) end
        end
        Workspace.Gravity = 196.2
        notify("Movement", "All movement disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("Movement Suite", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// COMBAT SUITE (all combat in one window)
--==============================================================================
local function CombatSuite()
    local w = createWindow("Combat Suite", "All combat features", 480, 620, randPos(480, 620))
    w:AddSection("Aimbot")
    w:AddToggle("Aimbot", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddSlider("Smoothness", 1, 100, 25, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddSlider("FOV", 20, 800, 120, "px", 0, function(v) Aimbot.Config.FOV = v end)
    w:AddDropdown("Target Part", { "Head", "HumanoidRootPart", "Torso" }, "Head", function(v) Aimbot.Config.TargetPart = v end)
    w:AddToggle("Show FOV Circle", false, function(v) Aimbot.Config.ShowFOV = v end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddSection("Triggerbot")
    w:AddToggle("Triggerbot", false, function(v) Triggerbot.Config.Enabled = v end)
    w:AddSlider("Trigger Delay", 0, 0.5, 0.05, "s", 2, function(v) Triggerbot.Config.Delay = v end)
    w:AddSection("Aura / Melee")
    w:AddToggle("Kill Aura", false, function(v) KillAura:Set(v) end)
    w:AddSlider("Attack Range", 3, 30, 13, "studs", 1, function(v) KillAura.Settings.AttackRange = v end)
    w:AddSlider("Aura CPS", 1, 20, 12, "", 0, function(v) KillAura.Settings.CPS = v end)
    w:AddToggle("Mob Aura", false, function(v) MobAura:Set(v) end)
    w:AddToggle("TP Aura", false, function(v) TPAura:Set(v) end)
    w:AddToggle("Bringer", false, function(v) Bringer:Set(v) end)
    w:AddSection("Hitboxes")
    w:AddToggle("Hitbox Expander", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end)
    w:AddSlider("Hitbox Size", 1, 30, 10, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)
    w:AddToggle("Reach (tool)", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Head Target", false, function(v) HeadTarget:Set(v) end)
    w:AddSection("Defense")
    w:AddToggle("Velocity (anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end)
    w:AddToggle("Auto Soup", false, function(v) AutoSoup:Set(v) end)
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddSection("Extras")
    w:AddToggle("Auto Clicker", false, function(v) AutoClicker:Set(v) end)
    w:AddToggle("Spinbot", false, function(v) Spinbot:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddToggle("Auto Dodge", false, function(v) AutoDodge:Set(v) end)
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end)
    w:AddButton("PANIC: Disable Combat", function()
        Aimbot.Config.Enabled = false; Triggerbot.Config.Enabled = false; Hitbox.Config.Enabled = false; Hitbox.Refresh()
        Aimbot.Config.ShowFOV = false
        for _, n in ipairs({ "KillAura","MobAura","TPAura","Bringer","Reach2","HeadTarget","Velocity","Criticals","AutoSoup","AutoHeal","AutoReload","AutoClicker","Spinbot","AntiAim","AutoDodge","Wallbang","AimAssist","SilentAim","MobAura" }) do
            local m = Modules[n]
            if m and m.Enabled then m:Set(false) end
        end
        notify("Combat", "All combat disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("Combat Suite", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// VISUAL SUITE (all ESP/visuals in one window)
--==============================================================================
local function VisualSuite()
    local w = createWindow("Visual Suite", "All ESP & visuals", 470, 620, randPos(470, 620))
    w:AddSection("Player ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Health", true, function(v) ESP.Config.Health = v end)
    w:AddToggle("Healthbar ESP", false, function(v) HealthbarESP:Set(v) end)
    w:AddSection("Boxes / Chams")
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Chams (fill)", false, function(v) Chams:Set(v) end)
    w:AddToggle("Tracers", false, function(v) Tracers:Set(v) end)
    w:AddToggle("NameTags", false, function(v) NameTags:Set(v) end)
    w:AddToggle("Hitboxes", false, function(v) Hitboxes:Set(v) end)
    w:AddSection("World ESP")
    w:AddToggle("Mob ESP", false, function(v) MobESP:Set(v) end)
    w:AddToggle("Storage ESP", false, function(v) StorageESP:Set(v) end)
    w:AddToggle("Inventory ESP", false, function(v) InventoryESP:Set(v) end)
    w:AddToggle("Tree ESP", false, function(v) TreeESP:Set(v) end)
    w:AddToggle("Tower ESP", false, function(v) TowerESP:Set(v) end)
    w:AddToggle("Sound ESP", false, function(v) SoundESP:Set(v) end)
    w:AddToggle("Search ESP", false, function(v) SearchESP:Set(v) end)
    w:AddInput("Search Keyword", "", "e.g. Coin/Chest", function(v) SearchESP.Settings.Keyword = v end)
    w:AddSection("XRay / Radar")
    w:AddToggle("XRay", false, function(v) XRay:Set(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Lighting")
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddToggle("Atmosphere FX", false, function(v) AtmosphereMod:Set(v) end)
    w:AddToggle("Time Changer", false, function(v) TimeChanger:Set(v) end)
    w:AddSection("Cosmetics")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddToggle("Ghost", false, function(v) Ghost:Set(v) end)
    w:AddButton("PANIC: Disable Visuals", function()
        ESP.Enable(false); BoxESP:Set(false); Chams:Set(false); Tracers:Set(false); NameTags:Set(false); Hitboxes:Set(false)
        Fullbright:Set(false); AtmosphereMod:Set(false); XRay:Set(false); Radar:Set(false); Cape:Set(false); ChinaHat:Set(false); Breadcrumbs:Set(false); Ghost:Set(false)
        for _, n in ipairs({ "MobESP","StorageESP","InventoryESP","TreeESP","TowerESP","SoundESP","SearchESP","HealthbarESP" }) do
            local m = Modules[n]
            if m and m.Enabled then m:Set(false) end
        end
        clearAutoHL()
        notify("Visuals", "All visuals disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("Visual Suite", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// WORLD / UTILITY SUITE
--==============================================================================
local function WorldSuite()
    local w = createWindow("World Suite", "World & utility tools", 470, 600, randPos(470, 600))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Drops", false, function(v) AutoDrops:Set(v) end)
    w:AddToggle("Auto Pickup", false, function(v) AutoPickup:Set(v) end)
    w:AddToggle("Auto Buy All", false, function(v) AutoBuyAll:Set(v) end)
    w:AddToggle("Auto Sell All", false, function(v) AutoSellAll:Set(v) end)
    w:AddToggle("Auto Chests", false, function(v) AutoChests:Set(v) end)
    w:AddToggle("Auto Quest", false, function(v) AutoQuest:Set(v) end)
    w:AddToggle("Auto Interact", false, function(v) AutoInteract:Set(v) end)
    w:AddToggle("Auto Fish", false, function(v) AutoFish:Set(v) end)
    w:AddToggle("Auto Give (remotes)", false, function(v) AutoGive:Set(v) end)
    w:AddSection("World Build")
    w:AddToggle("Scaffold", false, function(v) Scaffold:Set(v) end)
    w:AddToggle("Auto Bridge", false, function(v) AutoBridge:Set(v) end)
    w:AddToggle("Auto Block", false, function(v) AutoBlock:Set(v) end)
    w:AddToggle("Nuker", false, function(v) Nuker:Set(v) end)
    w:AddToggle("Door Clip", false, function(v) DoorClip:Set(v) end)
    w:AddToggle("Phase (walls)", false, function(v) Phase:Set(v) end)
    w:AddSection("Freecam")
    w:AddToggle("Freecam", false, function(v) Freecam:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
    end)
    w:AddToggle("Auto Leave (low players)", false, function(v) AutoLeave:Set(v) end)
    w:AddSection("Tools")
    w:AddButton("Dump Player Stats", function()
        setclipboard(dumpStats()); notify("World", "Stats copied.", 3, Theme.Green)
    end, Theme.Green)
    w:AddButton("Fast Reset", function()
        pcall(function() LocalPlayer.Character:BreakJoints() end)
    end, Theme.Yellow)
    w:AddButton("Clear All Highlights", function() clearAutoHL(); notify("World", "Cleared.", 2) end)
    w:AddButton("PANIC: Disable World", function()
        for _, n in ipairs({ "AutoDrops","AutoPickup","AutoBuyAll","AutoSellAll","AutoChests","AutoQuest","AutoInteract","AutoFish","AutoGive","Scaffold","AutoBridge","AutoBlock","Nuker","DoorClip","Phase","Freecam","AutoLeave" }) do
            local m = Modules[n]
            if m and m.Enabled then m:Set(false) end
        end
        clearAutoHL()
        notify("World", "All world tools disabled.", 3, Theme.Red)
    end, Theme.Red)
    notify("World Suite", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// 99 NIGHTS  (action survival / wave fighter)
--==============================================================================
local function NinetyNineNights()
    local w = createWindow("99 Nights", "Night Survival Suite", 470, 560, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Enemies", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Reach (tool)", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddSection("Survival")
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddToggle("Anti Stun", false, function(v) AntiStun:Set(v) end)
    addMovement(w, 250, 400)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Drops", false, function(v) AutoDrops:Set(v) end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._buy = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSection("Server")
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 60) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 60), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._buy then fireRemotes("buy"); fireRemotes("upgrade") end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._eEsp then highlightKeywords({ "enemy", "boss", "mob", "night" }, Color3.fromRGB(255, 60, 60)) end
                if w._lEsp then highlightKeywords({ "drop", "loot", "item", "gold", "chest" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("99 Nights", "Loaded.", 3, Color3.fromRGB(80, 50, 120))
    return w
end

--==============================================================================
--// ESCAPE  (Flee-the-Facility-style escape game)
--==============================================================================
local function EscapeGame()
    local w = createWindow("Escape", "Escape Suite", 470, 560, randPos())
    w:AddSection("ESP / Info")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Highlight Beast/Killer (Red)", false, function(v) w._beastEsp = v end)
    w:AddToggle("Highlight Exit/Doors (Green)", false, function(v) w._exitEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Highlight Computers/Hack", false, function(v) w._pcEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Beast Alert", false, function(v) w._beastAlert = v end)
    w:AddSection("Escape")
    w:AddToggle("Auto Complete Hacks (touch)", false, function(v) w._autoHack = v end)
    w:AddToggle("Auto Walk to Exit", false, function(v) w._autoExit = v end)
    w:AddToggle("Auto Run From Killer", false, function(v) w._run = v end)
    w:AddSlider("Safe Distance", 15, 200, 50, "studs", 0, function(v) w._safe = v end)
    w:AddSection("Movement")
    addMovement(w, 200, 400)
    w:AddSection("Server")
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._exitEsp then highlightKeywords({ "exit", "door", "escape", "elevator", "gate" }, Color3.fromRGB(76, 209, 142)) end
            if w._pcEsp then highlightKeywords({ "computer", "hack", "terminal", "console" }, Color3.fromRGB(86,156,240)) end
            if root then
                -- beast detection (player holding hammer/trap tool)
                if w._beastEsp or w._beastAlert or w._run then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local isBeast = false
                            for _, t in ipairs(plr.Character:GetChildren()) do
                                if t:IsA("Tool") and (t.Name:lower():find("hammer") or t.Name:lower():find("trap") or t.Name:lower():find("beast") or t.Name:lower():find("knife")) then
                                    isBeast = true
                                end
                            end
                            if isBeast then
                                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                                if w._beastEsp then
                                    local hl = plr.Character:FindFirstChild("ESP_HL")
                                    if hl then hl.FillColor = Color3.fromRGB(235,40,50) end
                                end
                                if hrp then
                                    local d = (hrp.Position - root.Position).Magnitude
                                    if w._beastAlert and d < (w._safe or 50) and (not w._lw or tick() - w._lw > 5) then
                                        w._lw = tick()
                                        notify("âš  KILLER NEAR", plr.Name .. " " .. math.floor(d) .. "m", 3, Theme.Red)
                                    end
                                    if w._run and d < (w._safe or 50) then
                                        local dir = root.Position - hrp.Position
                                        if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 14 end) end
                                    end
                                end
                            end
                        end
                    end
                end
                if w._autoHack then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("computer") or n:find("hack") or n:find("terminal") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p and (p.Position - root.Position).Magnitude < 30 then
                                pcall(function() firetouchinterest(root, p, 0) end)
                            end
                        end
                    end
                end
                if w._autoExit then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("exit") or n:find("escape") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p then
                                root.CFrame = p.CFrame * CFrame.new(0, 3, 6)
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Escape", "Loaded.", 3, Color3.fromRGB(86, 156, 240))
    return w
end

--==============================================================================
--// BRONX  (gang / street FPS)
--==============================================================================
local function Bronx()
    local w = buildFPSWindow("Bronx", Color3.fromRGB(200, 120, 80))
    w:AddSection("Bronx Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 100, 25, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddSection("Server")
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end

--==============================================================================
--// PLACEID AUTO-DETECT + AUTO-LOAD  (Nazuro-style loader)
--   Mirrors the Nazuro loader: maps game.PlaceId -> feature window name,
--   with a universal fallback. Used by the Auto-Detect button + startup.
--==============================================================================
local PlaceIdMap = {
    [142823291]         = "Murder Mystery 2",   -- MM2
    [79546208627805]    = "99 Nights",
    [109983668079237]   = "Steal a Brainrot",   -- sab
    [131623223084840]   = "Escape",
    [116495829188952]   = "Dead Rails",
    [16472538603]       = "Bronx",
    -- extra common mappings
    [286090429]         = "Arsenal",
    [18604265823]       = "Rivals",
    [606849621]         = "Jailbreak",
    [1962086868]        = "Tower of Hell",
    [2788229376]        = "Da Hood",
    [189707]            = "Natural Disasters",
    [1537690962]        = "Bee Swarm Simulator",
    [5071324506]        = "Flee the Facility",
    [13721349979]       = "Blade Ball",
    [6516141723]        = "Doors",
    [9273180877]        = "Pressure",
    [4924922222]        = "Brookhaven",
    [2753915549]        = "Blox Fruits",
    [6405393098]        = "Slap Battles",
    [8737602449]        = "Pls Donate",
    [6284583030]        = "Pet Sim X",
}

local function autoDetectGame()
    local pid = game.PlaceId
    local name = PlaceIdMap[pid]
    if not name then return nil end
    -- find the registered builder
    for _, entry in ipairs(GameList) do
        if entry.name == name then return entry end
    end
    return nil
end

-- Open (or focus) the auto-detected game window. Returns the entry or nil.
local function autoLoadDetected()
    local entry = autoDetectGame()
    if not entry then
        notify("Auto-Detect", "Current game (" .. game.PlaceId .. ") not mapped. Open Universal.", 4, Theme.Yellow)
        return nil
    end
    if OpenWindows[entry.name] and not OpenWindows[entry.name]._destroyed then
        OpenWindows[entry.name].Root.Visible = true
        bringToFront(OpenWindows[entry.name].Root)
    else
        local ok, win = pcall(entry.builder)
        if ok and win then OpenWindows[entry.name] = win end
    end
    notify("Auto-Detect", "Detected: " .. entry.name, 4, Theme.Green)
    return entry
end

--==============================================================================
--// FANCY LOADING SCREEN  (DaraHub-style boot animation)
--==============================================================================
local LoadingScreen = { _gui = nil }
function LoadingScreen:Show(text, duration)
    duration = duration or 2.5
    text = text or "Loading"
    -- remove old
    if self._gui then pcall(function() self._gui:Destroy() end) end
    local g = Instance.new("ScreenGui")
    g.Name = "HubLoadingScreen"
    g.IgnoreGuiInset = true
    g.DisplayOrder = 99999
    g.ResetOnSpawn = false
    g.Parent = getGuiParent()
    self._gui = g
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Theme.BackgroundDark
    bg.BorderSizePixel = 0
    bg.ZIndex = 1
    bg.Parent = g
    local logo = Instance.new("Frame")
    logo.Size = UDim2.new(0, 80, 0, 80)
    logo.Position = UDim2.new(0.5, -40, 0.5, -80)
    logo.BackgroundColor3 = Theme.Accent
    logo.BorderSizePixel = 0
    logo.ZIndex = 2
    logo.Parent = bg
    corner(logo, UDim.new(0, 20))
    gradient(logo, Theme.AccentBright, Theme.AccentDark, 45)
    local logoTxt = Instance.new("TextLabel")
    logoTxt.BackgroundTransparency = 1
    logoTxt.Size = UDim2.new(1, 0, 1, 0)
    logoTxt.Font = Theme.FontBold
    logoTxt.TextSize = 40
    logoTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
    logoTxt.Text = "P"
    logoTxt.ZIndex = 3
    logoTxt.Parent = logo
    -- spin the logo
    local spinConn = RunService.RenderStepped:Connect(function(dt)
        logo.Rotation = logo.Rotation + dt * 180
    end)
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0.5, -150, 0.5, 10)
    title.Size = UDim2.new(0, 300, 0, 26)
    title.Font = Theme.FontBold
    title.TextSize = 22
    title.TextColor3 = Theme.Text
    title.Text = "Potatools"
    title.ZIndex = 3
    title.Parent = bg
    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0.5, -150, 0.5, 38)
    sub.Size = UDim2.new(0, 300, 0, 18)
    sub.Font = Theme.Font
    sub.TextSize = 13
    sub.TextColor3 = Theme.AccentBright
    sub.Text = text
    sub.ZIndex = 3
    sub.Parent = bg
    -- progress bar
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 260, 0, 6)
    barBg.Position = UDim2.new(0.5, -130, 0.5, 68)
    barBg.BackgroundColor3 = Theme.Element
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 3
    barBg.Parent = bg
    corner(barBg, UDim.new(1, 0))
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Theme.Accent
    barFill.BorderSizePixel = 0
    barFill.ZIndex = 4
    barFill.Parent = barBg
    corner(barFill, UDim.new(1, 0))
    gradient(barFill, Theme.AccentBright, Theme.AccentDark, 0)
    local dots = { ".", "..", "..." }
    local i = 0
    local conn = RunService.Heartbeat:Connect(function()
        barFill.Size = UDim2.new(math.clamp((tick() % duration) / duration, 0, 1), 0, 1, 0)
        i = i + 1
        sub.Text = text .. " " .. dots[(math.floor(i / 8) % 3) + 1]
    end)
    task.delay(duration, function()
        if conn then conn:Disconnect() end
        if spinConn then spinConn:Disconnect() end
        local us = Instance.new("UIScale"); us.Scale = 1; us.Parent = bg
        tween(bg, 0.4, { BackgroundTransparency = 1 })
        tween(us, 0.4, { Scale = 1.1 })
        for _, d in ipairs(bg:GetDescendants()) do
            if d:IsA("TextLabel") or d:IsA("ImageLabel") then
                tween(d, 0.4, { TextTransparency = 1, ImageTransparency = 1 })
            elseif d:IsA("Frame") then
                tween(d, 0.4, { BackgroundTransparency = 1 })
            end
        end
        task.wait(0.45)
        pcall(function() g:Destroy() end)
        self._gui = nil
    end)
end

--==============================================================================
--// BRAINROT TOOLKIT (shared helpers for all brainrot games)
--   Comprehensive auto-steal / spawner / collector suite. These games revolve
--   around spawning brainrots, stealing them from other players, collecting
--   money/coins, buying eggs, and defending your own brainrots.
--==============================================================================

--==== EXTRA BRAINROT HELPERS (advanced) ====

-- Track the value/rarity of brainrots by scanning descendant attribute names.
local function scanBrainrotValues()
    local values = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") or d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("brainrot") or n:find("unit") or n:find("pet") or n:find("meme") then
                local val = d:GetAttribute("Value") or d:GetAttribute("Rarity") or d:GetAttribute("Price") or "unknown"
                table.insert(values, { name = d.Name, value = tostring(val), part = d })
            end
        end
    end
    table.sort(values, function(a, b)
        local av, bv = tonumber(a.value) or 0, tonumber(b.value) or 0
        return av > bv
    end)
    return values
end

-- Teleport to and steal the HIGHEST value brainrot on the map.
local function stealHighestValue()
    local root = getRoot()
    if not root then return false end
    local values = scanBrainrotValues()
    if #values > 0 then
        local part = values[1].part
        if part:IsA("Model") then part = part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart") end
        if part then
            pcall(function() root.CFrame = part.CFrame + Vector3.new(0, 3, 0) end)
            return true, values[1].name, values[1].value
        end
    end
    return false
end

-- Follow a target player at a set distance (orbit / stalk).
local function followPlayer(plr, distance)
    local root = getRoot()
    if not (root and plr and plr.Character) then return end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function() root.CFrame = hrp.CFrame * CFrame.new(0, 0, distance or -5) end)
    end
end

-- Spam every ProximityPrompt on the map (many brainrot games use these).
local function fireAllPrompts()
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                fireproximityprompt(d)
            end
        end
    end)
end

-- Polyfill fireproximityprompt for Studio.
if not fireproximityprompt then
    fireproximityprompt = function(prompt)
        pcall(function()
            if prompt and prompt.Parent then
                prompt.HoldDuration = 0
                prompt:InputHoldBegin()
                task.wait()
                prompt:InputHoldEnd()
            end
        end)
    end
end

-- Auto-rebirth with configurable threshold.
local function autoRebirthLoop(delay, enabled)
    task.spawn(function()
        while enabled() do
            fireRemotes("rebirth")
            task.wait(delay or 2)
        end
    end)
end

-- Mass-collect every pickup-type part and teleport them to a set position.
local function massCollectTo(pos)
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("coin") or n:find("cash") or n:find("money") or n:find("gem") or n:find("drop") or n:find("pickup") then
                pcall(function() d.CFrame = CFrame.new(pos) end)
                count = count + 1
            end
        end
    end
    return count
end

-- Sell all: rapidly fire every sell-related remote + touch sell parts.
local function sellEverything()
    fireRemotes("sell")
    local root = getRoot()
    if root then touchNamed(root, { "sell", "shop", "merchant", "npc" }, 9999) end
end

-- Egg spawner: mass-fire all egg/hatch remotes with all egg types.
local eggTypes = { "common", "rare", "epic", "legendary", "mythic", "gold", "rainbow", "cracked", "fertilized", "bug" }
local function massHatchEggs()
    fireRemotes("hatch"); fireRemotes("egg"); fireRemotes("open")
    for _, et in ipairs(eggTypes) do
        fireRemotes("hatch" .. et)
    end
end

-- Auto-equip: equip the best/highest-value tool or unit.
local function equipBestTool()
    pcall(function()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local char = getChar()
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (bp and hum) then return end
        local best, bestScore = nil, -1
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local score = t:GetAttribute("Value") or t:GetAttribute("Damage") or 1
                score = tonumber(score) or 1
                if score > bestScore then bestScore = score; best = t end
            end
        end
        if best then hum:EquipTool(best) end
    end)
end

--==== BRAINROT AUTO-FARM CONTROLLER (master loop for brainrot games) ====
local BrainrotFarm = {
    Enabled = false,
    Mode = "Steal",      -- "Steal" | "Collect" | "Spawner" | "Mixed"
    Delay = 0.5,
    Range = 500,
    AutoRebirth = false,
    AutoSell = false,
    AutoHatch = false,
    AutoEquip = false,
    AntiSteal = false,
    Prompts = false,
}
RunService.Heartbeat:Connect(function()
    if not BrainrotFarm.Enabled then return end
    if BrainrotFarm._t and tick() - BrainrotFarm._t < BrainrotFarm.Delay then return end
    BrainrotFarm._t = tick()
    local root = getRoot()
    if not root then return end
    if BrainrotFarm.Mode == "Steal" or BrainrotFarm.Mode == "Mixed" then
        autoStealNearest(BrainrotFarm.Range)
    end
    if BrainrotFarm.Mode == "Collect" or BrainrotFarm.Mode == "Mixed" then
        collectAllMoney(BrainrotFarm.Range)
    end
    if BrainrotFarm.Mode == "Spawner" or BrainrotFarm.Mode == "Mixed" then
        brainrotSpawn()
    end
    if BrainrotFarm.AutoRebirth then fireRemotes("rebirth") end
    if BrainrotFarm.AutoSell then sellEverything() end
    if BrainrotFarm.AutoHatch then massHatchEggs() end
    if BrainrotFarm.AutoEquip then equipBestTool() end
    if BrainrotFarm.AntiSteal then antiSteal(15) end
    if BrainrotFarm.Prompts then fireAllPrompts() end
end)

--==== BRAINROT MASTER WINDOW (controls the shared farm controller) ====
local function BrainrotMaster()
    local w = createWindow("Brainrot Master", "Universal brainrot farm", 490, 640, randPos(490, 640))
    w:AddSection("Master Farm")
    w:AddToggle("Enable Brainrot Farm", false, function(v) BrainrotFarm.Enabled = v end, "Master auto-farm for any brainrot game")
    w:AddDropdown("Farm Mode", { "Steal", "Collect", "Spawner", "Mixed" }, "Steal", function(v) BrainrotFarm.Mode = v end)
    w:AddSlider("Farm Delay", 0.1, 5, 0.5, "s", 2, function(v) BrainrotFarm.Delay = v end)
    w:AddSlider("Farm Range", 50, 9999, 500, "studs", 0, function(v) BrainrotFarm.Range = v end)
    w:AddSection("Sub-Features")
    w:AddToggle("Auto Rebirth", false, function(v) BrainrotFarm.AutoRebirth = v end)
    w:AddToggle("Auto Sell", false, function(v) BrainrotFarm.AutoSell = v end)
    w:AddToggle("Auto Hatch Eggs", false, function(v) BrainrotFarm.AutoHatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) BrainrotFarm.AutoEquip = v end)
    w:AddToggle("Anti-Steal", false, function(v) BrainrotFarm.AntiSteal = v end)
    w:AddToggle("Auto Fire Prompts", false, function(v) BrainrotFarm.Prompts = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Steal Highest Value Brainrot", function()
        local ok, nm, val = stealHighestValue()
        if ok then notify("Brainrot Master", "Going for " .. nm .. " (" .. val .. ")", 3, Theme.Green)
        else notify("Brainrot Master", "No brainrots found.", 3, Theme.Yellow) end
    end, Theme.Accent)
    w:AddButton("Bring All Brainrots", function()
        local n = brainrotBring()
        notify("Brainrot Master", "Brought " .. n .. " brainrots.", 3, Theme.Green)
    end, Theme.Green)
    w:AddButton("Collect All Money", function()
        local n = collectAllMoney(9999)
        notify("Brainrot Master", "Collected " .. n .. " money parts.", 3, Theme.Green)
    end, Theme.Green)
    w:AddButton("Mass Hatch Eggs", function() massHatchEggs() end)
    w:AddButton("Fire All Prompts", function() fireAllPrompts() end)
    w:AddButton("Sell Everything", function() sellEverything() end)
    w:AddButton("Equip Best Tool", function() equipBestTool() end)
    w:AddSection("Scan")
    w:AddButton("Scan Brainrot Values", function()
        local vals = scanBrainrotValues()
        local n = math.min(#vals, 5)
        local msg = ""
        for i = 1, n do msg = msg .. vals[i].name .. " (" .. vals[i].value .. ")\n" end
        if msg == "" then msg = "No brainrots found." end
        notify("Brainrot Scan (" .. #vals .. " total)", msg, 6, Theme.Accent)
    end)
    w:AddSection("Follow")
    w:AddDropdown("Follow Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._followTarget = v end)
    w:AddToggle("Follow Target", false, function(v) w._follow = v end)
    w:AddSlider("Follow Distance", 1, 50, 5, "studs", 0, function(v) w._followDist = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._brEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Money ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Combat (steal defense)")
    w:AddToggle("Spin (dodge aim)", false, function(v) Spin:Set(v) end)
    w:AddToggle("Fling Nearest (on contact)", false, function(v) w._fling = v end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._follow then
                local p = findPlayerByName(w._followTarget or "")
                if p then followPlayer(p, w._followDist or 5) end
            end
            if w._fling then
                local root = getRoot()
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and root then
                        if (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude < 8 then
                            pcall(function() root.AssemblyAngularVelocity = Vector3.new(9e4, 9e4, 9e4) end)
                        end
                    end
                end
            end
            if w._brEsp then highlightKeywords({ "brainrot", "unit", "pet", "meme", "skibidi" }, Color3.fromRGB(180,120,255)) end
            if w._mEsp then highlightKeywords({ "coin", "cash", "money", "gem" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Brainrot Master", "Loaded. Universal brainrot farm.", 4, Theme.Accent)
    return w
end

-- Find every part named with a brainrot keyword (meme units, pets, units).
local function findBrainrotParts(keywords)
    keywords = keywords or { "brainrot", "unit", "pet", "meme", "skibidi", "sigma", "rizz", "gyatt", "ohio", "npc", "entity", "char" }
    local out = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and not d:IsDescendantOf(getChar() or Workspace) then
            local n = d.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then table.insert(out, d); break end
            end
        end
    end
    return out
end

-- Bring all matching parts to the local player (the classic "collect all").
local function brainrotBring(keywords)
    local root = getRoot()
    if not root then return 0 end
    local count = 0
    for _, p in ipairs(findBrainrotParts(keywords)) do
        pcall(function() p.CFrame = root.CFrame end)
        count = count + 1
    end
    return count
end

-- Auto-steal: teleport to the nearest other player's brainrot/character and touch it.
local function autoStealNearest(range)
    local root = getRoot()
    if not root then return end
    local best, bestD = nil, range or 9999
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < bestD then bestD = d; best = hrp end
         