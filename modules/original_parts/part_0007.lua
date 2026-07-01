spawn(function()
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
    notify("Tower of Hell", "Loaded. Noclip + Fly make any obby trivial.", 4, Theme.Green)
    return w
end

--===== DA HOOD =====
local function DaHood()
    local w = createWindow("Da Hood", "Lock-on / Silent Aim Suite", 480, 560,
        UDim2.new(0.5, -240 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Aim")
    w:AddToggle("Aimbot (Lock)", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddToggle("Hold to Aim (E)", true, function(v) Aimbot.Config.HoldToAim = v end)
    w:AddSlider("Smoothness", 1, 100, 18, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddSlider("FOV", 20, 800, 150, "px", 0, function(v) Aimbot.Config.FOV = v end)
    w:AddToggle("Show FOV", false, function(v) Aimbot.Config.ShowFOV = v end)
    w:AddDropdown("Target", { "Head", "HumanoidRootPart", "Torso", "UpperTorso" }, "HumanoidRootPart", function(v) Aimbot.Config.TargetPart = v end)

    w:AddSection("Silent Aim / Trigger")
    w:AddToggle("Triggerbot", false, function(v) Triggerbot.Config.Enabled = v end)
    w:AddToggle("Silent Aim (click-redirect)", false, function(v) w._silent = v end)
    w:AddSlider("Silent FOV", 20, 600, 200, "px", 0, function(v) w._silentFov = v end)

    w:AddSection("Hitbox")
    w:AddToggle("Hitbox Expander", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end)
    w:AddSlider("Hitbox Size", 1, 30, 8, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    w:AddSection("Local / Teleport")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 45, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Bring Player (to you)", false, function(v) w._bring = v end)
    w:AddDropdown("Bring Target", getPlayerNames(false), Players:GetPlayers()[1] and Players:GetPlayers()[1].Name or "nil", function(v) w._bringTarget = v end)

    -- silent aim redirect: when firing, point camera at target briefly
    local function silentAimFire()
        if not w._silent then return end
        local target = aimGetClosest()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Aimbot.Config.TargetPart) or target.Character.HumanoidRootPart
            if part then
                local aimCF = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = aimCF
                task.wait()
            end
        end
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            silentAimFire()
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._bring then
                local p = findPlayerByName(w._bringTarget or "")
                local root = getRoot()
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and root then
                    pcall(function()
                        p.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -3)
                    end)
                end
            end
        end
    end)
    notify("Da Hood", "Loaded.", 3, Theme.Red)
    return w
end

--===== NATURAL DISASTERS SURVIVAL =====
local function NaturalDisasters()
    local w = createWindow("Natural Disasters Survival", "Survival Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Survival")
    w:AddToggle("Auto Fly To Safety", false, function(v) w._autoSafe = v end, "Fly up high when a disaster starts")
    w:AddSlider("Safe Height", 50, 1500, 400, "studs", 0, function(v) w._safeH = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddToggle("Auto Re-Join Round", false, function(v) w._autoRound = v end)

    w:AddSection("Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Disaster Warning", false, function(v) w._warn = v end)

    task.spawn(function()
        while true do
            task.wait(0.5)
            local root = getRoot()
            if w._autoSafe and root then
                -- detect disaster: many moving/falling parts or large velocity
                local disaster = false
                for _, d in ipairs(Workspace:GetChildren()) do
                    if d:IsA("Model") or d:IsA("Folder") then
                        local n = d.Name:lower()
                        if n:find("disaster") or n:find("lava") or n:find("tsunami") or n:find("tornado") or n:find("earthquake") or n:find("meteor") or n:find("flood") or n:find("fire") or n:find("volcano") or n:find("storm") then
                            disaster = true
                            if w._warn then
                                notify("âš  DISASTER", "Detected: " .. d.Name, 3, Theme.Red)
                            end
                        end
                    end
                end
                if disaster then
                    Movement.Fly.Enabled = true
                    root.CFrame = CFrame.new(root.Position + Vector3.new(0, (w._safeH or 400)/30, 0))
                end
            end
            if w._god then
                local h = getHum()
                if h then h.Health = h.MaxHealth end
            end
        end
    end)
    notify("Natural Disasters", "Loaded.", 3, Theme.Blue)
    return w
end

--===== ONE TAP =====
local function OneTap()
    local w = buildFPSWindow("One Tap", Color3.fromRGB(180, 80, 255))
    w:AddSection("One Tap Extras")
    w:AddToggle("Instant Aim (no smoothing)", false, function(v) Aimbot.Config.Smoothness = v and 1 or Aimbot.Config.Smoothness end)
    w:AddToggle("Always Headshot", true, function(v) Aimbot.Config.TargetPart = v and "Head" or "HumanoidRootPart" end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Auto Dodge Players", false, function(v) AutoDodgePlayer:Set(v) end)
    w:AddButton("Respawn", function() pcall(function() LocalPlayer.Character:BreakJoints() end) end)
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
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end

--===== BEE SWARM SIMULATOR =====
local function BeeSwarmSimulator()
    local w = createWindow("Bee Swarm Simulator", "Auto-Farm Suite", 470, 560,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Collect Pollen (fire)", false, function(v) w._autoPollen = v end)
    w:AddToggle("Auto Convert at Hive", false, function(v) w._autoConvert = v end)
    w:AddToggle("Auto Collect Tokens", false, function(v) w._autoTokens = v end)
    w:AddToggle("Auto Kill Mobs", false, function(v) w._autoMobs = v end)
    w:AddSlider("Field Loop Delay", 0.1, 3, 0.4, "s", 2, function(v) w._loopDelay = v end)

    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 45, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 60, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    w:AddSection("Visuals")
    w:AddToggle("Firefly ESP", false, function(v) w._fireflyEsp = v end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    w:AddSection("Teleport - Fields")
    local fields = {
        {"Bamboo", Vector3.new(94, 20, 218)},
        {"Dandelion", Vector3.new(307, 58, 189)},
        {"Sunflower", Vector3.new(-210, 4, -40)},
        {"Mushroom", Vector3.new(-258, 5, 295)},
        {"Spider", Vector3.new(-400, 5, -50)},
        {"Strawberry", Vector3.new(-360, 67, -46)},
        {"Clover", Vector3.new(318, 34, 99)},
        {"Pumpkin", Vector3.new(-197, 68, -184)},
        {"Pine Tree", Vector3.new(318, 132, -158)},
        {"Cactus", Vector3.new(-197, 74, -199)},
        {"Rose", Vector3.new(-390, 44, 137)},
        {"Mountain Top", Vector3.new(90, 195, -190)},
    }
    for _, f in ipairs(fields) do
        w:AddButton("TP: " .. f[1], function() teleportTo(f[2]) end)
    end

    local function fireAllRemotes(filter)
        pcall(function()
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") then
                    local n = r.Name:lower()
                    if n:find(filter) then r:FireServer() end
                end
            end
        end)
    end

    task.spawn(function()
        while true do
            task.wait(w._loopDelay or 0.4)
            local root = getRoot()
            if not root then else
                if w._autoPollen then fireAllRemotes("pollen"); fireAllRemotes("collect") end
                if w._autoConvert then fireAllRemotes("convert"); fireAllRemotes("hive") end
                if w._autoTokens then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if (d:IsA("BasePart") or d:IsA("Model")) and (d.Name:lower():find("token") or d.Name:lower():find("spark")) then
                            local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if part and (part.Position - root.Position).Magnitude < 60 then
                                pcall(function() firetouchinterest(root, part, 0) end)
                            end
                        end
                    end
                end
                if w._autoMobs then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                            local hrp = d:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - root.Position).Magnitude < 40 then
                                pcall(function()
                                    local tool = getChar():FindFirstChildOfClass("Tool")
                                    if tool then tool:Activate() end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Bee Swarm Simulator", "Loaded. Auto-fire targets common remote names.", 4, Theme.Yellow)
    return w
end

--===== FLEE THE FACILITY =====
local function FleeTheFacility()
    local w = createWindow("Flee the Facility", "Escape Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("ESP / Info")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Highlight Beast (Red)", false, function(v) w._beastEsp = v end)
    w:AddToggle("Highlight Exit Doors (Green)", false, function(v) w._exitEsp = v end)
    w:AddToggle("Highlight Computers/Hack", false, function(v) w._pcEsp = v end)
    w:AddToggle("Beast Alert", false, function(v) w._beastAlert = v end)

    w:AddSection("Escape")
    w:AddToggle("Auto Complete Hacks (touch)", false, function(v) w._autoHack = v end)
    w:AddToggle("Auto Walk to Exit (test)", false, function(v) w._autoExit = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)

    local function highlightByName(names, color)
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Model") then
                local n = d.Name:lower()
                for _, key in ipairs(names) do
                    if n:find(key) then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part then
                            local hl = part:FindFirstChild("FTF_ESP") or Instance.new("Highlight")
                            hl.Name = "FTF_ESP"
                            hl.Adornee = d
                            hl.FillColor = color
                            hl.FillTransparency = 0.4
                            hl.Parent = part
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        while true do
            task.wait(1)
            local root = getRoot()
            if w._exitEsp then highlightByName({"exit", "door", "escape"}, Color3.fromRGB(76, 209, 142)) end
            if w._pcEsp then highlightByName({"computer", "hack", "terminal", "console"}, Color3.fromRGB(86,156,240)) end
            -- beast = the player with the "beast" / trap
            if w._beastEsp or w._beastAlert then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local isBeast = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("hammer") or t.Name:lower():find("trap") or t.Name:lower():find("beast")) then
                                isBeast = true
                            end
                        end
                        if isBeast then
                            if w._beastEsp then
                                local hl = plr.Character:FindFirstChild("ESP_HL")
                                if hl then hl.FillColor = Color3.fromRGB(235,40,50) end
                            end
                            if w._beastAlert and root and plr.Character:FindFirstChild("HumanoidRootPart") then
                                local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                                if d < 45 then notify("âš  BEAST NEAR", plr.Name .. " " .. math.floor(d) .. "m", 3, Theme.Red) end
                            end
                        end
                    end
                end
            end
            if w._autoHack and root then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("computer") or n:find("hack") or n:find("terminal") then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part and (part.Position - root.Position).Magnitude < 30 then
                            pcall(function() firetouchinterest(root, part, 0) end)
                        end
                    end
                end
            end
            if w._autoExit and root then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("exit") or n:find("escape") then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part then
                            local cf = part.CFrame
                            root.CFrame = cf * CFrame.new(0, 3, 6)
                            break
                        end
                    end
                end
            end
        end
    end)
    notify("Flee the Facility", "Loaded.", 4, Theme.Blue)
    return w
end

--===== GROW A GARDEN =====
local function GrowAGarden()
    local w = createWindow("Grow a Garden", "Farming Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Plant", false, function(v) w._plant = v end)
    w:AddToggle("Auto Water", false, function(v) w._water = v end)
    w:AddToggle("Auto Harvest", false, function(v) w._harvest = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Loop Delay", 0.2, 5, 0.8, "s", 2, function(v) w._delay = v end)

    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 45, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)

    w:AddSection("Visuals")
    w:AddToggle("Crop / Item ESP", false, function(v) w._cropEsp = v end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    local function fireFilter(filter)
        pcall(function()
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                    if r.Name:lower():find(filter) then
                        if r:IsA("RemoteEvent") then r:FireServer() else pcall(function() r:InvokeServer() end) end
                    end
                end
            end
        end)
    end

    task.spawn(function()
        while true do
            task.wait(w._delay or 0.8)
            local root = getRoot()
            if w._plant then fireFilter("plant"); fireFilter("seed") end
            if w._water then fireFilter("water") end
            if w._harvest then fireFilter("harvest"); fireFilter("collect") end
            if w._sell then fireFilter("sell") end
            if w._collect and root then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("drop") or n:find("fruit") or n:find("crop") or n:find("vegetable") then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part and (part.Position - root.Position).Magnitude < 80 then
                            pcall(function() firetouchinterest(root, part, 0) end)
                        end
                    end
                end
            end
        end
    end)
    notify("Grow a Garden", "Loaded.", 4, Theme.Green)
    return w
end

--===== BLOXSTRIKE =====
local function Bloxstrike()
    local w = buildFPSWindow("Bloxstrike", Color3.fromRGB(255, 120, 50))
    w:AddSection("Bloxstrike Extras")
    w:AddToggle("No Flash", false, function(v)
        if v then Lighting.TimeOfDay = "14:00:00"; Lighting.Brightness = 2; Lighting.FogEnd = 9e9 end
    end)
    w:AddToggle("Bunny Hop (auto jump)", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
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
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end

--===== BREAK YOUR BONES =====
local function BreakYourBones()
    local w = createWindow("Break Your Bones", "Bone Farm Suite", 460, 500,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -250 + math.random(-60,60)))
    w:AddSection("Bone Farming")
    w:AddToggle("Auto Reset (farm bones)", false, function(v) w._autoReset = v end)
    w:AddSlider("Reset Delay", 0.5, 10, 2, "s", 1, function(v) w._resetDelay = v end)
    w:AddToggle("Auto Fling / Ragdoll", false, function(v) w._fling = v end)
    w:AddButton("Force Reset Now", function()
        pcall(function() LocalPlayer.Character:BreakJoints() end)
    end)

    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 250, 60, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 500, 120, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    local lastReset = 0
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._autoReset and tick() - lastReset >= (w._resetDelay or 2) then
                lastReset = tick()
                pcall(function() LocalPlayer.Character:BreakJoints() end)
            end
            if w._fling then
                local r = getRoot()
                if r then r.AssemblyAngularVelocity = Vector3.new(math.random(-200,200), math.random(-200,200), math.random(-200,200)) end
            end
        end
    end)
    notify("Break Your Bones", "Loaded.", 3, Theme.Yellow)
    return w
end

--===== SLIME RNG =====
local function SlimeRNG()
    local w = createWindow("Slime RNG", "Auto-Roll Suite", 460, 500,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -250 + math.random(-60,60)))
    w:AddSection("Auto")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end)
    w:AddSlider("Roll Delay", 0.1, 5, 0.5, "s", 2, function(v) w._rollDelay = v end)
    w:AddToggle("Auto Claim / Hatch", false, function(v) w._claim = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Click All Buttons", false, function(v) w._clickAll = v end)

    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 45, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    local lastRoll = 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._roll and tick() - lastRoll >= (w._rollDelay or 0.5) then
                lastRoll = tick()
                pcall(function()
                    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                        if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and (r.Name:lower():find("roll") or r.Name:lower():find("spin") or r.Name:lower():find("gacha")) then
                            if r:IsA("RemoteEvent") then r:FireServer() else pcall(function() r:InvokeServer() end) end
                        end
                    end
                end)
            end
            if w._claim then
                pcall(function()
                    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                        if (r:IsA("RemoteEvent")) and (r.Name:lower():find("claim") or r.Name:lower():find("hatch") or r.Name:lower():find("open")) then
                            r:FireServer()
                        end
                    end
                end)
            end
            if w._sell then
                pcall(function()
                    for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                        if r:IsA("RemoteEvent") and r.Name:lower():find("sell") then r:FireServer() end
                    end
                end)
            end
            if w._clickAll then
                -- Press any on-screen buttons labelled roll/claim/open.
                pcall(function()
                    for _, gui in ipairs(ScreenGui:GetDescendants()) do
                        if gui:IsA("TextButton") then
                            local t = gui.Text:lower()
                            if t:find("roll") or t:find("claim") or t:find("open") or t:find("hatch") then
                                local args = { [1] = gui }
                                local ok = pcall(function() gui:FireSignal("Activated") end)
                                if not ok then pcall(function() gui.Active = gui.Active end) end
                            end
                        end
                    end
                end)
            end
        end
    end)
    notify("Slime RNG", "Loaded.", 3, Theme.Accent)
    return w
end

--===== REDLINERS (FPS, not racing) =====
local function Redliners()
    local w = buildFPSWindow("Redliners", Color3.fromRGB(255, 60, 90))
    w:AddSection("Redliners (FPS) Extras")
    w:AddToggle("Always Headshot", true, function(v) Aimbot.Config.TargetPart = v and "Head" or "HumanoidRootPart" end)
    w:AddToggle("No Recoil (steady cam)", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Fast Respawn", false, function(v) w._fastResp = v end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddToggle("Auto Dodge Players", false, function(v) AutoDodgePlayer:Set(v) end)
    w:AddButton("Recenter Aim", function()
        local r = getRoot()
        if r then Camera.CFrame = CFrame.new(Camera.CFrame.Position, r.Position + Vector3.new(0,0,-10)) end
    end)
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
    w:AddButton("Rejoin Server", function()
        pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
    end)
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait()
            if w._fastResp and not isAlive() then
                task.wait(0.5)
                pcall(function() LocalPlayer:LoadCharacter() end)
            end
        end
    end)
    return w
end

--===== UNIVERSAL =====
local function Universal()
    local w = createWindow("Universal", "Works in every game", 480, 560,
        UDim2.new(0.5, -240 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Walk Speed", 16, 500, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 500, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD/Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 600, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)

    w:AddSection("Combat")
    w:AddToggle("Aimbot", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddSlider("Aim Smoothness", 1, 100, 25, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddSlider("Aimbot FOV", 20, 800, 120, "px", 0, function(v) Aimbot.Config.FOV = v end)
    w:AddToggle("Triggerbot", false, function(v) Triggerbot.Config.Enabled = v end)
    w:AddToggle("Hitbox Expander", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end)
    w:AddSlider("Hitbox Size", 1, 40, 10, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Health", true, function(v) ESP.Config.Health = v end)
    w:AddToggle("Show FOV Circle", false, function(v) Aimbot.Config.ShowFOV = v end)

    w:AddSection("Camera & World")
    w:AddToggle("Custom Camera FOV", false, function(v) CameraFOV.Enabled = v end)
    w:AddSlider("Camera FOV", 50, 120, 70, "", 0, function(v) CameraFOV.Value = v end)
    w:AddToggle("Custom Gravity", false, function(v) Gravity.Enabled = v; if not v then Workspace.Gravity = 196.2 end end)
    w:AddSlider("Gravity", 0, 196, 60, "", 0, function(v) Gravity.Value = v end)
    w:AddToggle("Time / Fullbright", false, function(v)
        if v then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 9e9 end
    end)
    w:AddButton("Day -> 14:00", function() Lighting.ClockTime = 14 end)
    w:AddButton("Night -> 00:00", function() Lighting.ClockTime = 0 end)

    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSlider("Crosshair Size", 2, 40, 10, "", 0, function(v) Crosshair.Size = v end)
    w:AddSlider("Crosshair Gap", 0, 30, 4, "", 0, function(v) Crosshair.Gap = v end)
    w:AddButton("Copy Server JobId", function()
        setclipboard(tostring(game.JobId))
        notify("Universal", "Copied JobId.", 2)
    end)

    w:AddSection("Player / World")
    w:AddButton("Fullbright", function()
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9
        notify("Universal", "Fullbright on.", 2)
    end)
    w:AddButton("God Mode (re-fill health)", function()
        local h = getHum(); if h then h.Health = h.MaxHealth end
    end)
    w:AddButton("Remove Fog", function() Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9 end)
    w:AddButton("FPS Boost (hide terrain textures)", function()
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d:IsA("Terrain") and d.Material == Enum.Material.Grass then
                    d.Material = Enum.Material.Plastic
                end
            end
        end)
        notify("Universal", "Applied FPS tweaks.", 2)
    end)
    w:AddDropdown("Teleport to Player", getPlayerNames(false), Players:GetPlayers()[1] and Players:GetPlayers()[1].Name or "nil", function(v) w._uniTP = v end)
    w:AddButton("Teleport", function()
        local p = findPlayerByName(w._uniTP or "")
        if p then teleportToPlayer(p) end
    end)
    notify("Universal", "Loaded.", 2.5, Theme.Accent)
    return w
end

--==============================================================================
--// EXTRA SYSTEMS: Camera FOV, Gravity, Anti-AFK, Crosshair
--==============================================================================
local CameraFOV = { Enabled = false, Value = 70 }
RunService.RenderStepped:Connect(function()
    if CameraFOV.Enabled then
        Camera.FieldOfView = CameraFOV.Value
    end
end)

local Gravity = { Enabled = false, Value = 100 }
RunService.Heartbeat:Connect(function()
    if Gravity.Enabled then
        Workspace.Gravity = Gravity.Value
    end
end)

local AntiAFK = { Enabled = false }
local function setAntiAFK(on)
    AntiAFK.Enabled = on and true or false
end
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if AntiAFK.Enabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end)

-- Custom crosshair (4 lines around screen centre)
local Crosshair = { Enabled = false, Size = 10, Thickness = 2, Gap = 4, Color = Color3.fromRGB(0, 255, 120) }
local crossGui
local crossLines = {}
local function setCrosshair(on)
    Crosshair.Enabled = on and true or false
    if on and not crossGui then
        crossGui = Instance.new("ScreenGui")
        crossGui.Name = "HubCrosshair"
        crossGui.ResetOnSpawn = false
        crossGui.IgnoreGuiInset = true
        crossGui.DisplayOrder = 2
        crossGui.Parent = getGuiParent()
        for _ = 1, 4 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.BackgroundColor3 = Crosshair.Color
            f.Parent = crossGui
            table.insert(crossLines, f)
        end
    end
    if crossGui then crossGui.Enabled = on end
end
RunService.RenderStepped:Connect(function()
    if Crosshair.Enabled and crossGui then
        local vp = Camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local s, th, gap = Crosshair.Size, Crosshair.Thickness, Crosshair.Gap
        crossLines[1].Size = UDim2.new(0, th, 0, s); crossLines[1].Position = UDim2.new(0, cx - th / 2, 0, cy - gap - s)
        crossLines[2].Size = UDim2.new(0, th, 0, s); crossLines[2].Position = UDim2.new(0, cx - th / 2, 0, cy + gap)
        crossLines[3].Size = UDim2.new(0, s, 0, th); crossLines[3].Position = UDim2.new(0, cx - gap - s, 0, cy - th / 2)
        crossLines[4].Size = UDim2.new(0, s, 0, th); crossLines[4].Position = UDim2.new(0, cx + gap, 0, cy - th / 2)
        for _, l in ipairs(crossLines) do l.BackgroundColor3 = Crosshair.Color end
    end
end)

--==============================================================================
--// EXTRA HELPERS  (shared by the extra game modules)
--==============================================================================
randPos = function(sx, sy)
    return UDim2.new(0.5, -(sx or 470) / 2 + math.random(-90, 90), 0.5, -(sy or 540) / 2 + math.random(-70, 70))
end

addMovement = function(w, speedMax, flyMax)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, speedMax or 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 400, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD/Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, flyMax or 400, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
end

local function getNearestNPC(maxDist)
    local root = getRoot()
    if not root then return nil, math.huge end
    local best, bestD = nil, maxDist or math.huge
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            local hrp = d:FindFirstChild("HumanoidRootPart") or d.PrimaryPart
            local hum = d:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < bestD then bestD = dist; best = d end
            end
        end
    end
    return best, bestD
end

local function fireRemotes(keyword)
    local n = 0
    pcall(function()
        for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
            if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and r.Name:lower():find(keyword) then
                if r:IsA("RemoteEvent") then r:FireServer(); n = n + 1
                else pcall(function() r:InvokeServer() end); n = n + 1 end
            end
        end
    end)
    return n
end

local HL_TAG = "HubAutoHL"
local function highlightKeywords(keywords, color)
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") or d:IsA("BasePart") then
                local n = d.Name:lower()
                local match = false
                for _, k in ipairs(keywords) do
                    if n:find(k) then match = true; break end
                end
                if match and not d:GetAttribute(HL_TAG) then
                    d:SetAttribute(HL_TAG, true)
                    local hl = Instance.new("Highlight")
                    hl.Name = HL_TAG
                    hl.FillColor = color
                    hl.FillTransparency = 0.45
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = d
                end
            end
        end
    end)
end
local function clearAutoHL()
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:GetAttribute(HL_TAG) then
                d:SetAttribute(HL_TAG, nil)
                local hl = d:FindFirstChild(HL_TAG)
                if hl then hl:Destroy() end
            end
        end
    end)
end

local function trySetStat(keyword, value)
    pcall(function()
        for _, c in ipairs(LocalPlayer:GetDescendants()) do
            if c:IsA("ValueBase") and c.Name:lower():find(keyword) then
                c.Value = value
            end
        end
    end)
end

local function touchNamed(root, keys, range)
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        local n = d.Name:lower()
        local hit = false
        for _, k in ipairs(keys) do if n:find(k) then hit = true; break end end
        if hit then
            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
            if p and (p.Position - root.Position).Magnitude < (range or 100) then
                pcall(function() firetouchinterest(root, p, 0) end)
            end
        end
    end
end

--==============================================================================
--// "FIND THE" GAME FRAMEWORK
--   Generic, fully-functional builder for every "Find the ..." hunt game.
--   Mirrors the Find-the-Script-HUB reference: a deep multi-keyword scanner
--   (BasePart names, Model/Folder names, parent-container names, and
--   TouchTransmitter parents), a live dropdown, ESP highlights, Collect-All
--   (bring to player OR visit each), Go-To-Selected, Bring-Selected-Here, and
--   a