local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = buildFPSWindow("Redliners", Color3.fromRGB(255, 60, 90))
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
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end\n    end\nend\n\nreturn M\n
