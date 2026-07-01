local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        pcall(function()
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
    w:AddToggle("Auto Reset (farm bones)", false, function(v) w._autoReset = v end\n    end\nend\n\nreturn M\n
