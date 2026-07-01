local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = buildFPSWindow("Arsenal", Color3.fromRGB(255, 90, 90))
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
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end\n    end\nend\n\nreturn M\n
