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
            end
        end
    end
    if best then
        pcall(function() root.CFrame = best.CFrame * CFrame.new(0, 0, -3) end)
        return true
    end
    return false
end

-- Spawner: rapidly fire all spawn-related remotes (IdiotHub / brainrot spawner style).
local function brainrotSpawn()
    fireRemotes("spawn"); fireRemotes("summon"); fireRemotes("buy"); fireRemotes("egg"); fireRemotes("hatch")
end

-- Anti-steal: when another player gets close, fling them away or teleport up.
local function antiSteal(range)
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local d = (hrp.Position - root.Position).Magnitude
                if d < (range or 15) then
                    pcall(function() root.CFrame = root.CFrame + Vector3.new(0, 20, 0) end)
                end
            end
        end
    end
end

-- Collect all coins/money/cash on the map.
local function collectAllMoney(range)
    local root = getRoot()
    if not root then return 0 end
    local count = 0
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("coin") or n:find("cash") or n:find("money") or n:find("pickup") or n:find("gem") then
                if (d.Position - root.Position).Magnitude < (range or 9999) then
                    pcall(function() d.CFrame = root.CFrame end)
                    count = count + 1
                end
            end
        end
    end
    return count
end

--==============================================================================
--// STEAL A BRAINROT  (expanded - full IdiotHub/Divine/Pynova feature set)
--==============================================================================
local function StealABrainrotPro()
    local w = createWindow("Steal a Brainrot PRO", "Full brainrot suite", 490, 640, randPos(490, 640))
    w:AddSection("Auto Steal")
    w:AddToggle("Auto Steal (TP to players)", false, function(v) w._autoSteal = v end, "Teleport to nearest player to steal")
    w:AddSlider("Steal Range", 50, 9999, 500, "studs", 0, function(v) w._stealRange = v end)
    w:AddSlider("Steal Delay", 0.1, 5, 0.5, "s", 2, function(v) w._stealDelay = v end)
    w:AddToggle("Bring All Brainrots To Me", false, function(v) w._bringAll = v end)
    w:AddToggle("Auto Touch Nearest Player", false, function(v) w._touchPlayers = v end)
    w:AddToggle("Anti-Steal (defend)", false, function(v) w._antiSteal = v end)
    w:AddSlider("Anti-Steal Range", 5, 50, 15, "studs", 0, function(v) w._asRange = v end)
    w:AddSection("Spawner / Buy")
    w:AddToggle("Auto Spawn (remotes)", false, function(v) w._spawn = v end)
    w:AddSlider("Spawn Delay", 0.5, 10, 1, "s", 2, function(v) w._spawnDelay = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._autoEggs = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddSection("Money / Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Collect All Money Now", false, function(v)
        local n = collectAllMoney(9999)
        notify("SAB", "Brought " .. n .. " money parts.", 3, Theme.Accent)
    end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._brEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Money ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Teleport")
    w:AddButton("Teleport to Nearest Player", function() autoStealNearest(9999) end, Theme.Accent)
    w:AddButton("Bring All Brainrots", function()
        local n = brainrotBring()
        notify("SAB", "Brought " .. n .. " brainrots.", 3, Theme.Green)
    end, Theme.Green)
    w:AddButton("Fling Nearest Player", function()
        local root = getRoot()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    root.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
                    root.AssemblyAngularVelocity = Vector3.new(9e4, 9e4, 9e4)
                end)
                break
            end
        end
    end, Theme.Red)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    local lastSteal, lastSpawn = 0, 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._autoSteal and tick() - lastSteal >= (w._stealDelay or 0.5) then
                    lastSteal = tick()
                    autoStealNearest(w._stealRange or 500)
                end
                if w._bringAll then brainrotBring() end
                if w._touchPlayers then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            if (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude < 12 then
                                pcall(function() firetouchinterest(root, plr.Character.HumanoidRootPart, 0) end)
                            end
                        end
                    end
                end
                if w._antiSteal then antiSteal(w._asRange or 15) end
                if w._coins then collectAllMoney(200) end
                if w._autoEggs then fireRemotes("egg"); fireRemotes("buyegg") end
                if w._equip then fireRemotes("equip") end
                if w._sell then fireRemotes("sell") end
                if w._brEsp then highlightKeywords({ "brainrot", "unit", "pet", "meme", "skibidi", "sigma" }, Color3.fromRGB(180,120,255)) end
                if w._mEsp then highlightKeywords({ "coin", "cash", "money", "gem", "pickup" }, Color3.fromRGB(255,200,40)) end
            end
            if w._spawn and tick() - lastSpawn >= (w._spawnDelay or 1) then
                lastSpawn = tick()
                brainrotSpawn()
            end
        end
    end)
    notify("Steal a Brainrot PRO", "Loaded. Full auto-steal/spawner suite.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// GROW A GARDEN  (expanded - full IdiotHub GAG feature set)
--==============================================================================
local function GrowAGardenPro()
    local w = createWindow("Grow a Garden PRO", "Full garden suite", 490, 640, randPos(490, 640))
    w:AddSection("Auto Plant / Grow")
    w:AddToggle("Auto Plant Seeds", false, function(v) w._plant = v end)
    w:AddToggle("Auto Water", false, function(v) w._water = v end)
    w:AddToggle("Auto Fertilize", false, function(v) w._fert = v end)
    w:AddToggle("Auto Harvest", false, function(v) w._harvest = v end)
    w:AddSection("Auto Economy")
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Seeds", false, function(v) w._buySeeds = v end)
    w:AddToggle("Auto Buy Gear", false, function(v) w._buyGear = v end)
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Collect Range", 20, 1000, 200, "studs", 0, function(v) w._crange = v end)
    w:AddSection("Mutations / Sprinklers")
    w:AddToggle("Auto Use Sprinkler", false, function(v) w._sprinkler = v end)
    w:AddToggle("Auto Mutation (best-effort)", false, function(v) w._mutation = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Fruit / Crop ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Seed / Shop ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rare Drop ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Teleport - Shops")
    w:AddButton("TP: Seed Shop", function() fireRemotes("shop"); teleportTo(Vector3.new(60, 5, 0)) end)
    w:AddButton("TP: Gear Shop", function() teleportTo(Vector3.new(-60, 5, 0)) end)
    w:AddButton("TP: Sell Area", function() teleportTo(Vector3.new(0, 5, 60)) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._plant then fireFilter("plant"); fireFilter("seed") end
            if w._water then fireFilter("water") end
            if w._fert then fireFilter("fertilize"); fireFilter("fert") end
            if w._harvest then fireFilter("harvest"); fireFilter("collect") end
            if w._sell then fireFilter("sell") end
            if w._buySeeds then fireFilter("buyseed"); fireFilter("buy") end
            if w._buyGear then fireFilter("buygear") end
            if w._sprinkler then fireFilter("sprinkler") end
            if w._mutation then fireFilter("mutation"); fireFilter("mutate") end
            if root and w._collect then
                touchNamed(root, { "fruit", "drop", "crop", "vegetable", "seed" }, w._crange or 200)
            end
            if w._fEsp then highlightKeywords({ "fruit", "crop", "vegetable", "plant", "harvest" }, Color3.fromRGB(120,220,120)) end
            if w._sEsp then highlightKeywords({ "seed", "shop", "gear", "sprinkler" }, Color3.fromRGB(86,156,240)) end
            if w._rEsp then highlightKeywords({ "rare", "legendary", "mythic", "gold", "rainbow" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Grow a Garden PRO", "Loaded. Full auto-plant/sell suite.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// GROW A GARDEN 2  (IdiotHub GAG2)
--==============================================================================
local function GrowAGarden2()
    local w = createWindow("Grow a Garden 2", "GAG2 Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Plant", false, function(v) w._plant = v end)
    w:AddToggle("Auto Water", false, function(v) w._water = v end)
    w:AddToggle("Auto Harvest", false, function(v) w._harvest = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Seeds", false, function(v) w._buy = v end)
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 1000, 200, "studs", 0, function(v) w._range = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Fruit ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rare ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._plant then fireFilter("plant"); fireFilter("seed") end
            if w._water then fireFilter("water") end
            if w._harvest then fireFilter("harvest"); fireFilter("collect") end
            if w._sell then fireFilter("sell") end
            if w._buy then fireFilter("buy"); fireFilter("seed") end
            if root and w._collect then touchNamed(root, { "fruit", "drop", "crop" }, w._range or 200) end
            if w._fEsp then highlightKeywords({ "fruit", "crop", "plant" }, Color3.fromRGB(120,220,120)) end
            if w._rEsp then highlightKeywords({ "rare", "legendary", "gold" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Grow a Garden 2", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// SPLIT OR STEAL BRAINROT  (PvB / IdiotHub)
--==============================================================================
local function SplitOrStealBrainrot()
    local w = createWindow("Split or Steal Brainrot", "PvB Suite", 480, 620, randPos(480, 620))
    w:AddSection("Steal")
    w:AddToggle("Auto Steal", false, function(v) w._steal = v end)
    w:AddSlider("Delay", 0.1, 5, 0.4, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Bring All Brainrots", false, function(v) w._bring = v end)
    w:AddToggle("Anti-Steal", false, function(v) w._anti = v end)
    w:AddSection("Decision")
    w:AddToggle("Always Split", false, function(v) w._split = v end)
    w:AddToggle("Always Steal", false, function(v) w._alwaysSteal = v end)
    w:AddSection("Spawn / Buy")
    w:AddToggle("Auto Spawn", false, function(v) w._spawn = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._eggs = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._brEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._steal and tick() - last >= (w._delay or 0.4) then
                    last = tick()
                    autoStealNearest(500)
                end
                if w._bring then brainrotBring() end
                if w._anti then antiSteal(15) end
                if w._coins then collectAllMoney(300) end
                if w._split then fireRemotes("split") end
                if w._alwaysSteal then fireRemotes("steal") end
                if w._spawn then brainrotSpawn() end
                if w._eggs then fireRemotes("egg"); fireRemotes("buy") end
                if w._brEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Split or Steal Brainrot", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// SWING OBBY FOR BRAINROTS!  (FluxXYZ Clamor Hub)
--==============================================================================
local function SwingObbyBrainrots()
    local w = createWindow("Swing Obby for Brainrots!", "Swing Obby Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Win")
    w:AddToggle("Auto Swing (click)", false, function(v) w._swing = v end)
    w:AddSlider("Swing Delay", 0.1, 2, 0.3, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Skip Stage (TP forward)", false, function(v) w._skip = v end)
    w:AddSlider("Skip Distance", 10, 200, 40, "studs", 0, function(v) w._skipDist = v end)
    w:AddToggle("Auto Collect Brainrots", false, function(v) w._collect = v end)
    w:AddSection("Cheats")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Anti Fall", false, function(v) NoFall:Set(v) end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddSection("Win")
    w:AddButton("TP to Finish (search)", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("brainrot") and n:find("end")) then
                    by = d.Position.Y; best = d
                end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) else notify("Swing Obby", "No finish found.", 3, Theme.Yellow) end
    end, Theme.Green)
    w:AddButton("TP Up 100", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 100, 0) end end)
    w:AddSection("Safety")
    w:AddToggle("Disable Kill Bricks", false, function(v) w._noKill = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.15)
            local root = getRoot()
            if root then
                if w._swing and tick() - last >= (w._delay or 0.3) then
                    last = tick()
                    swingTool()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)