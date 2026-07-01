==============================
--// PIGGY
--==============================================================================
local function Piggy()
    local w = createWindow("Piggy", "Escape Suite", 460, 520, randPos())
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Piggy ESP (Red)", false, function(v) w._pEsp = v end)
    w:AddToggle("Item / Key ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Escape")
    w:AddToggle("Auto Collect Items", false, function(v) w._autoItem = v end)
    w:AddButton("Touch All Doors", function() touchNamed(getRoot(), { "door", "exit", "gate" }, 9999) end)
    addMovement(w, 150, 250)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._iEsp then highlightKeywords({ "key", "item", "door", "exit", "hammer", "wrench" }, Color3.fromRGB(255, 200, 40)) end
            if w._pEsp then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local hasWeapon = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("piggy") or t.Name:lower():find("bat") or t.Name:lower():find("knife")) then hasWeapon = true end
                        end
                        if hasWeapon then
                            local hl = plr.Character:FindFirstChild("ESP_HL")
                            if hl then hl.FillColor = Color3.fromRGB(255, 40, 50) end
                        end
                    end
                end
            end
            if w._autoItem and root then touchNamed(root, { "key", "item", "hammer", "wrench" }, 50) end
        end
    end)
    notify("Piggy", "Loaded.", 3, Theme.Red)
    return w
end

--==============================================================================
--// WORK AT A PIZZA PLACE
--==============================================================================
local function PizzaPlace()
    local w = createWindow("Work at a Pizza Place", "Job Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Work Station (click)", false, function(v) w._work = v end)
    w:AddToggle("Auto Deliver (touch boxes)", false, function(v) w._deliver = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box / Money ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    addMovement(w, 200, 300)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._work then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._bEsp then highlightKeywords({ "box", "money", "crate", "supply" }, Color3.fromRGB(255, 200, 40)) end
            if w._deliver and root then touchNamed(root, { "box", "crate", "supply", "pizza" }, 60) end
        end
    end)
    notify("Work at a Pizza Place", "Loaded.", 3, Color3.fromRGB(255, 160, 60))
    return w
end

--==============================================================================
--// THEME PARK TYCOON 2
--==============================================================================
local function ThemeParkTycoon2()
    local w = createWindow("Theme Park Tycoon 2", "Builder Suite", 460, 520, randPos())
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Ride / Shop ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    task.spawn(function()
        while true do
            task.wait(1)
            if w._rEsp then highlightKeywords({ "ride", "shop", "coaster", "stall", "stand" }, Color3.fromRGB(120, 200, 255)) end
        end
    end)
    notify("Theme Park Tycoon 2", "Loaded.", 3, Color3.fromRGB(120, 200, 255))
    return w
end

--==============================================================================
--// WEIGHT LIFTING SIMULATOR
--==============================================================================
local function WeightLiftingSimulator()
    local w = createWindow("Weight Lifting Simulator", "Grind Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Lift (click)", false, function(v) w._lift = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._lift then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._sell then fireRemotes("sell") end
        end
    end)
    notify("Weight Lifting Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// MAGNET SIMULATOR
--==============================================================================
local function MagnetSimulator()
    local w = createWindow("Magnet Simulator", "Collect Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Collect Range", 20, 600, 150, "studs", 0, function(v) w._crange = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Magnets", false, function(v) w._buy = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "magnet", "gem", "money", "cash" }, w._crange or 150) end
                if w._sell then fireRemotes("sell") end
                if w._buy then fireRemotes("buy") end
                if w._cEsp then highlightKeywords({ "coin", "magnet", "gem", "chest" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Magnet Simulator", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// SUPER BOMB SURVIVAL
--==============================================================================
local function SuperBombSurvival()
    local w = createWindow("Super Bomb Survival", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Bomb ESP (Red)", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Avoid Bombs", false, function(v) w._avoid = v end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    w:AddSlider("Safe Distance", 15, 200, 50, "studs", 0, function(v) w._safe = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._bEsp then highlightKeywords({ "bomb", "explosive", "mine", "rocket" }, Color3.fromRGB(255, 40, 50)) end
            if w._avoid and root then
                local best, bd = nil, w._safe or 50
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("bomb") or n:find("explosive") or n:find("mine") then
                        local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if p then
                            local dist = (p.Position - root.Position).Magnitude
                            if dist < bd then bd = dist; best = p end
                        end
                    end
                end
                if best then
                    local dir = root.Position - best.Position
                    if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 15 end) end
                end
            end
            if w._revive and not isAlive() then fireRemotes("revive"); task.wait(1) end
        end
    end)
    notify("Super Bomb Survival", "Loaded.", 3, Theme.Red)
    return w
end

--==============================================================================
--// LUMBER TYCOON 2
--==============================================================================
local function LumberTycoon2()
    local w = createWindow("Lumber Tycoon 2", "Lumber Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Chop (click)", false, function(v) w._chop = v end)
    w:AddToggle("Auto Sell Wood", false, function(v) w._sell = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Tree / Wood ESP", false, function(v) w._wEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._chop then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._sell then fireRemotes("sell") end
            if w._wEsp then highlightKeywords({ "tree", "wood", "log", "plank" }, Color3.fromRGB(120, 200, 120)) end
        end
    end)
    notify("Lumber Tycoon 2", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// RANDOM RUMBLE
--==============================================================================
local function RandomRumble()
    local w = buildFPSWindow("Random Rumble", Color3.fromRGB(180, 120, 255))
    w:AddSection("Rumble Extras")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 5, 80, 25, "studs", 0, function(v) w._arange = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._aura and root then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d <= (w._arange or 25) then
                            pcall(function()
                                local tool = getChar():FindFirstChildOfClass("Tool")
                                if tool then tool:Activate() end
                            end)
                        end
                    end
                end
            end
        end
    end)
    return w
end

--==============================================================================
--// RAGDOLL UNIVERSE
--==============================================================================
local function RagdollUniverse()
    local w = createWindow("Ragdoll Universe", "Fun Suite", 460, 500, randPos(460, 500))
    addMovement(w, 200, 400)
    w:AddSection("Fun")
    w:AddToggle("Auto Fling", false, function(v) w._fling = v end)
    w:AddToggle("Auto Reset Loop", false, function(v) w._reset = v end)
    w:AddSlider("Reset Delay", 0.5, 10, 2, "s", 1, function(v) w._rdelay = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            local r = getRoot()
            if w._fling and r then r.AssemblyAngularVelocity = Vector3.new(math.random(-300, 300), math.random(-300, 300), math.random(-300, 300)) end
            if w._reset and tick() - last >= (w._rdelay or 2) then
                last = tick()
                pcall(function() LocalPlayer.Character:BreakJoints() end)
            end
        end
    end)
    notify("Ragdoll Universe", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// ROBLOXIAN HIGH SCHOOL
--==============================================================================
local function RobloxianHighschool()
    local w = createWindow("Robloxian High School", "Campus Suite", 470, 540, randPos(470, 540))
    w:AddSection("Movement")
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Anti-AFK Walk", false, function(v) AntiAFKWalk:Set(v) end)
    w:AddToggle("Auto Dance", false, function(v) w._dance = v end)
    w:AddSection("Cosmetics")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddSection("Teleport")
    w:AddButton("TP: School", function() teleportTo(Vector3.new(0, 5, 0)) end)
    w:AddButton("TP: Field", function() teleportTo(Vector3.new(120, 5, 40)) end)
    w:AddButton("TP: Gym", function() teleportTo(Vector3.new(-80, 5, -40)) end)
    w:AddButton("TP: Cafeteria", function() teleportTo(Vector3.new(90, 5, 40)) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._dance then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.B, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.B, false, game)
                end)
            end
        end
    end)
    notify("Robloxian High School", "Loaded.", 3, Color3.fromRGB(255, 120, 180))
    return w
end

--==============================================================================
--// COLOR BLOCK / SQUID GAME
--==============================================================================
local function ColorBlock()
    local w = createWindow("Color Block / Squid Game", "Survival Suite", 460, 500, randPos(460, 500))
    w:AddSection("Survival")
    w:AddToggle("Show Safe Blocks", false, function(v) w._safeEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Stand on Safe (auto)", false, function(v) w._autoStand = v end)
    addMovement(w, 150, 250)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._safeEsp then highlightKeywords({ "safe", "green", "correct", "goal" }, Color3.fromRGB(76, 209, 142)) end
            if w._autoStand and root then
                local best, bd = nil, 9999
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if (n:find("safe") or n:find("green")) and d:IsA("BasePart") then
                        local dist = (d.Position - root.Position).Magnitude
                        if dist < bd then bd = dist; best = d end
                    end
                end
                if best then pcall(function() root.CFrame = best.CFrame + Vector3.new(0, 4, 0) end) end
            end
        end
    end)
    notify("Color Block", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// GYM SIMULATOR
--==============================================================================
local function GymSimulator()
    local w = createWindow("Gym Simulator", "Grind Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Workout (click)", false, function(v) w._work = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Equipment", false, function(v) w._buy = v end)
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._work then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
        end
    end)
    notify("Gym Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// WESTBOUND  (western shooter -> combat suite)
--==============================================================================
local function Westbound()
    return buildFPSWindow("Westbound", Color3.fromRGB(200, 150, 80))
end

--==============================================================================
--// KING LEGACY
--==============================================================================
local function KingLegacy()
    local w = createWindow("King Legacy", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest Enemy", false, function(v) w._farm = v end)
    w:AddToggle("Fast Attack Spam", false, function(v) w._fast = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Fruit ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._farm and root then
                local npc, dist = getNearestNPC(99999)
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local hrp = npc.HumanoidRootPart
                    if dist > (w._range or 40) then
                        pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 40), 25) end)
                    end
                    pcall(function()
                        local tool = getChar():FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                    end)
                end
            end
            if w._cEsp then highlightKeywords({ "chest", "fruit", "treasure" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("King Legacy", "Loaded.", 3, Color3.fromRGB(255, 160, 60))
    return w
end

--==============================================================================
--// FRIENDS & TARGETS MANAGER  (vape Friends / Targets lists)
--==============================================================================
local function FriendsTargets()
    local w = createWindow("Friends & Targets", "Recolor ESP & priorities", 450, 560, randPos(450, 560))
    -- current player picker
    w:AddSection("Add / Remove")
    w:AddDropdown("Select Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._ftPlayer = v end)
    w:AddButton("Add Friend", function()
        local n = w._ftPlayer
        if n and not isFriend({ Name = n }) then
            table.insert(FriendList.List, n)
            notify("Friends", n .. " added. (green ESP)", 3, Theme.Green)
        end
    end, Theme.Green)
    w:AddButton("Remove Friend", function()
        local n = w._ftPlayer
        for i, name in ipairs(FriendList.List) do
            if string.lower(name) == string.lower(n) then table.remove(FriendList.List, i); notify("Friends", n .. " removed.", 3) break end
        end
    end)
    w:AddButton("Add Target", function()
        local n = w._ftPlayer
        if n and not isTarget({ Name = n }) then
            table.insert(TargetList.List, n)
            notify("Targets", n .. " added. (red ESP)", 3, Theme.Red)
        end
    end, Theme.Red)
    w:AddButton("Remove Target", function()
        local n = w._ftPlayer
        for i, name in ipairs(TargetList.List) do
            if string.lower(name) == string.lower(n) then table.remove(TargetList.List, i); notify("Targets", n .. " removed.", 3) break end
        end
    end)
    -- manual name entry
    w:AddSection("Manual Entry")
    w:AddInput("Username", "", "exact username", function(v) w._ftName = v end)
    w:AddButton("Add Friend (by name)", function()
        if w._ftName and w._ftName ~= "" then
            table.insert(FriendList.List, w._ftName)
            notify("Friends", w._ftName .. " added.", 3, Theme.Green)
        end
    end, Theme.Green)
    w:AddButton("Add Target (by name)", function()
        if w._ftName and w._ftName ~= "" then
            table.insert(TargetList.List, w._ftName)
            notify("Targets", w._ftName .. " added.", 3, Theme.Red)
        end
    end, Theme.Red)
    -- quick actions
    w:AddSection("Quick Actions")
    w:AddButton("Add Everyone as Friend", function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and not isFriend(p) then table.insert(FriendList.List, p.Name) end
        end
        notify("Friends", "Added all players.", 3, Theme.Green)
    end)
    w:AddButton("Clear Friends", function()
        FriendList.List = {}; notify("Friends", "Cleared.", 3, Theme.Yellow)
    end, Theme.Yellow)
    w:AddButton("Clear Targets", function()
        TargetList.List = {}; notify("Targets", "Cleared.", 3, Theme.Yellow)
    end, Theme.Yellow)
    w:AddButton("Copy Friends List", function()
        setclipboard(table.concat(FriendList.List, ", "))
        notify("Friends", "Copied to clipboard.", 3)
    end)
    w:AddSection("Info")
    w:AddLabel("Friends show GREEN in ESP.")
    w:AddLabel("Targets show RED in ESP.")
    w:AddLabel("Both override team colors.")
    w:AddLabel("Toggle Player ESP in Universal/Vape to see them.")
    notify("Friends & Targets", "Loaded.", 2.5, Theme.Accent)
    return w
end

--==============================================================================
--// BEDWARS  (combat + bed defense)
--==============================================================================
local function Bedwars()
    local w = createWindow("Bedwars", "Combat Suite", 480, 580, randPos())
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 40, 16, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Bridge / Place", false, function(v) w._bridge = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddDropdown("Reach Mode", { "Resize", "TouchInterest" }, "Resize", function(v) Reach2.Settings.Mode = v end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Bed ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Diamond / Emerald ESP", false, function(v) w._gEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 16, false, true)) do swingTool() end end
            if w._bridge then swingTool(); fireRemotes("place"); fireRemotes("block") end
            if w._bEsp then highlightKeywords({ "bed", "bedrock", "nexus" }, Color3.fromRGB(255, 60, 60)) end
            if w._gEsp then highlightKeywords({ "diamond", "emerald", "gold", "iron", "generator" }, Color3.fromRGB(120, 220, 255)) end
        end
    end)
    notify("Bedwars", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// DOOMSPIRE BRICKBATTLE
--==============================================================================
local function Doomspire()
    local w = createWindow("Doomspire Brickbattle", "Combat Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 50, 20, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Rocket/Tool Spam", false, function(v) w._spam = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Spawn / Base ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 20, false, true)) do swingTool() end end
            if w._spam then swingTool(); fireRemotes("rocket"); fireRemotes("explode") end
            if w._sEsp then highlightKeywords({ "spawn", "base", "spire", "tower" }, Color3.fromRGB(255, 160, 60)) end
        end
    end)
    notify("Doomspire", "Loaded.", 3, Color3.fromRGB(255, 160, 60))
    return w
end

--==============================================================================
--// COMBAT WARRIORS
--==============================================================================
local function CombatWarriors()
    local w = createWindow("Combat Warriors", "Melee Suite", 470, 560, randPos())
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 60, 22, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Block", false, function(v) w._block = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Auto")
    w:AddToggle("Auto Farm Nearest", false, function(v) w._farm = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            local root = getRoot()
            if root then
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 22, false, true)) do swingTool() end end
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
    notify("Combat Warriors", "Loaded.", 3, Color3.fromRGB(220, 60, 60))
    return w
end

--==============================================================================
--// ABILITY WARS
--==============================================================================
local function AbilityWars()
    local w = createWindow("Ability Wars", "Ability Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 60, 18, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Use Ability", false, function(v) w._ability = v end)
    w:AddSlider("Ability Delay", 0.5, 10, 2, "s", 1, function(v) w._abDelay = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, false, true)) do swingTool() end end
        end
    end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._ability and tick() - last >= (w._abDelay or 2) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
                end)
            end
        end
    end)
    notify("Ability Wars", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// MIC UP
--==============================================================================
local function MicUp()
    local w = createWindow("Mic Up", "Social Suite", 470, 540, randPos(470, 540))
    w:AddSection("Movement")
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddToggle("Atmosphere FX", false, function(v) AtmosphereMod:Set(v) end)
    w:AddSection("Voice / Social")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Anti-AFK Walk", false, function(v) AntiAFKWalk:Set(v) end)
    w:AddToggle("Auto Dance (emote)", false, function(v) w._dance = v end)
    w:AddToggle("Auto Chat", false, function(v) w._chat = v end)
    w:AddSlider("Chat Interval", 5, 60, 15, "s", 0, function(v) w._interval = v end)
    w:AddInput("Chat Message", "Hi! :)", "", function(v) w._msg = v end)
    w:AddSection("Cosmetics")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddToggle("Spin (cosmetic)", false, function(v) Spin:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._chat and tick() - last >= (w._interval or 15) then
                last = tick()
                local msg = (w._msg and w._msg ~= "") and w._msg or "Hi! :)"
                pcall(function()
                    local ev = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                    local sm = ev and ev:FindFirstChild("SayMessageRequest")
                    if sm then sm:FireServer(msg, "All") end
                end)
            end
            if w._dance then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.B, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.B, false, game)
                end)
            end
        end
    end)
    notify("Mic Up", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// ISLAND ROYALE  (battle royale FPS)
--==============================================================================
local function IslandRoyale()
    local w = buildFPSWindow("Island Royale", Color3.fromRGB(120, 200, 120))
    w:AddSection("Extras")
    w:AddToggle("Auto Loot", false, function(v) w._loot = v end)
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._loot and root then touchNamed(root, { "loot", "weapon", "ammo", "armor", "gun", "chest" }, 80) end
            if w._lEsp then highlightKeywords({ "loot", "weapon", "ammo", "armor", "gun", "chest", "crate" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    return w
end

--==============================================================================
--// BLOCK TAPE / PLATES OF FATE
--==============================================================================
local function PlatesOfFate()
    local w = createWindow("Plates of Fate", "Survival Suite", 460, 520, randPos())
    addMovement(w, 200, 400)
    w:AddSection("Survival")
    w:AddToggle("Plate / Safe ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Hazard ESP", false, function(v) w._hEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._pEsp then highlightKeywords({ "plate", "safe", "goal" }, Color3.fromRGB(76, 209, 142)) end
            if w._hEsp then highlightKeywords({ "lava", "bomb", "spike", "danger", "fire", "laser" }, Color3.fromRGB(255, 40, 50)) end
        end
    end)
    notify("Plates of Fate", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// FIND THE MARKERS
--==============================================================================
local function FindTheMarkers()
    return buildFindTheGame(FindTheGames[1])
end

--==============================================================================
--// TOWER OF MISERY / OBBY GENERIC
--==============================================================================
local function ObbyGeneric()
    local w = createWindow("Obby Helper", "Tower / Obby Suite", 460, 540, randPos())
    w:AddSection("Movement")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 400, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddButton("Teleport UP 250", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 250, 0) end end)
    w:AddButton("Teleport UP 600", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 600, 0) end end)
    w:AddSection("Safety")
    w:AddToggle("Disable Kill Bricks", false, function(v) w._noKill = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddSection("Win")
    w:AddButton("Find & TP to Finish", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("portal") or n:find("goal") or n:find("top")) then
                    by = d.Position.Y; best = d
                end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) else notify("Obby", "No finish found - teleport high.", 3, Theme.Yellow) end
    end, Theme.Green)
    task.spawn(function()
        while true do
            task.wait(0.3)
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
            if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
        end
    end)
    notify("Obby Helper", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// WACKY WIZARDS
--==============================================================================
local function WackyWizards()
    local w = createWindow("Wacky Wizards", "Potion Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Ingredients", false, function(v) w._ing = v end)
    w:AddSlider("Collect Range", 20, 500, 150, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Brew", false, function(v) w._brew = v end)
    w:AddToggle("Auto Drink Potion", false, function(v) w._drink = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Ingredient ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._ing then touchNamed(root, { "ingredient", "item", "frog", "you", "dynamite" }, w._range or 150) end
                if w._brew then fireRemotes("brew"); fireRemotes("potion") end
                if w._drink then fireRemotes("drink") end
                if w._iEsp then highlightKeywords({ "ingredient", "potion", "item" }, Color3.fromRGB(120, 220, 255)) end
            end
        end
    end)
    notify("Wacky Wizards", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// BIG HEAD / TROLL FACE
--==============================================================================
local function TrollSuite()
    local w = createWindow("Troll Suite", "Fun & Cosmetic", 450, 520, randPos(450, 520))
    w:AddSection("Cosmetic")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddSection("Fun")
    w:AddToggle("Spin", false, function(v) Spin:Set(v) end)
    w:AddToggle("Auto Fling", false, function(v) w._fling = v end)
    w:AddToggle("Funny Walk (random jumps)", false, function(v) w._walk = v end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddDropdown("AntiAim Mode", { "Spin", "Jitter", "Reverse" }, "Jitter", function(v) AntiAim.Settings.Mode = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            local r = getRoot()
            if w._fling and r then r.AssemblyAngularVelocity = Vector3.new(math.random(-300, 300), math.random(-300, 300), math.random(-300, 300)) end
            if w._walk then
                local h = getHum()
                if h and math.random() > 0.7 then pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end) end
            end
        end
    end)
    notify("Troll Suite", "Loaded.", 3, Color3.fromRGB(255, 120, 80))
    return w
end

--==============================================================================
--// ROBLOXIAN HIGHSCHOOL 2 / GENERIC SIM
--==============================================================================
local function GenericSim()
    local w = createWindow("Simulator Helper", "Auto-Click + Collect", 460, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddSlider("Click Delay", 0.01, 0.5, 0.05, "s", 2, function(v) w._cdelay = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy", false, function(v) w._buy = v end)
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddSlider("Collect Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Loot / Coin ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.02)
            if w._click and tick() - last >= (w._cdelay or 0.05) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("click")
            end
            if w._sell then fireRemotes("sell") end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
            if w._hatch then fireRemotes("hatch") end
            if w._collect then
                local root = getRoot()
                if root then touchNamed(root, { "coin", "drop", "loot", "gem", "pickup", "money" }, w._range or 150) end
            end
            if w._lEsp then highlightKeywords({ "coin", "drop", "loot", "gem", "pickup", "chest" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Simulator Helper", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// ZOMBIE ATTACK / TOWER DEFENSE FIGHTER
--==============================================================================
local function ZombieAttack()
    local w = createWindow("Zombie Attack", "Wave Fighter Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Zombies", false, function(v) w._farm = v end)
    w:AddToggle("Auto Shoot", false, function(v) w._shoot = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Zombie ESP", false, function(v) w._zEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Survival")
    w:AddToggle("Auto Buy Weapons", false, function(v) w._buy = v end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
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
                if w._zEsp then highlightKeywords({ "zombie", "enemy", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Zombie Attack", "Loaded.", 3, Color3.fromRGB(120, 200, 80))
    return w
end

--==============================================================================
--// PLAYERS PANEL
--==============================================================================
local function PlayersPanel()
    local w = createWindow("Players", "Online players & actions", 440, 480, randPos(440, 480))
    w:AddSection("Actions")
    w:AddDropdown("Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._target = v end)
    w:AddButton("Teleport To", function()
        local p = findPlayerByName(w._target or "")
        if p then teleportToPlayer(p); notify("Players", "Teleported to " .. p.Name, 2) else notify("Players", "Player not found", 2, Theme.Red) end
    end)
    w:AddButton("Bring To You", function()
        local p = findPlayerByName(w._target or "")
        local root = getRoot()
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and root then
            pcall(function() p.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -3) end)
        end
    end)
    w:AddButton("Follow", function()
        local p = findPlayerByName(w._target or "")
        local root = getRoot()
        if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and root then
            pcall(function() root.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) end)
        end
    end)
    w:AddButton("Copy Username", function()
        local p = findPlayerByName(w._target or "")
        if p then setclipboard(p.Name); notify("Players", "Copied " .. p.Name, 2) end
    end)
    w:AddSection("Info")
    w:AddLabel("Players online: " .. #Players:GetPlayers())
    w:AddLabel("Tip: reopen to refresh the list.")
    notify("Players", "Loaded.", 2, Theme.Accent)
    return w
end

--==============================================================================
--// CLICKER SIMULATOR
--==============================================================================
local function ClickerSimulator()
    local w = createWindow("Clicker Simulator", "Auto-Click Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddSlider("Click Delay", 0.01, 0.5, 0.05, "s", 2, function(v) w._cdelay = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._buy = v end)
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            if w._click and tick() - last >= (w._cdelay or 0.05) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
            if w._hatch then fireRemotes("hatch") end
            if w._claim then fireRemotes("claim") end
        end
    end)
    notify("Clicker Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// BUBBLE GUM SIMULATOR
--==============================================================================
local function BubbleGumSimulator()
    local w = createWindow("Bubble Gum Simulator", "Blow Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Blow Bubble (space)", false, function(v) w._blow = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Coin / Egg ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._blow then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end)
            end
            if w._sell then fireRemotes("sell") end
            if w._hatch then fireRemotes("hatch") end
            if w._buy then fireRemotes("buy") end
            if w._cEsp then highlightKeywords({ "coin", "egg", "chest", "gem", "candy" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Bubble Gum Simulator", "Loaded.", 3, Color3.fromRGB(255, 120, 200))
    return w
end

--==============================================================================
--// BOXING SIMULATOR
--==============================================================================
local function BoxingSimulator()
    local w = createWindow("Boxing Simulator", "Punch Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Punch (click)", false, function(v) w._punch = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Gloves", false, function(v) w._buy = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._punch then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
            if w._sell then fireRemotes("sell") end
        end
    end)
    notify("Boxing Simulator", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// RACE CLICKER
--==============================================================================
local function RaceClicker()
    local w = createWindow("Race Clicker", "Auto Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Pets", false, function(v) w._buy = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.02)
            if w._click and tick() - last >= 0.05 then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy") end
        end
    end)
    notify("Race Clicker", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// EPIC MINIGAMES
--==============================================================================
local function EpicMinigames()
    local w = createWindow("Epic Minigames", "Mini Suite", 450, 500, randPos(450, 500))
    addMovement(w, 200, 400)
    w:AddSection("Survival")
    w:AddToggle("Auto Win Hints ESP", false, function(v) w._wEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._wEsp then highlightKeywords({ "safe", "goal", "win", "finish", "coin" }, Color3.fromRGB(76, 209, 142)) end
        end
    end)
    notify("Epic Minigames", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PET SIMULATOR X
--==============================================================================
local function PetSimX()
    local w = createWindow("Pet Simulator X", "Coin & Egg Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
    w:AddToggle("Coin / Chest ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "diamond", "gem", "chest", "loot" }, w._range or 150) end
                if w._hatch then fireRemotes("hatch") end
                if w._sell then fireRemotes("sell") end
                if w._buy then fireRemotes("buy") end
                if w._cEsp then highlightKeywords({ "coin", "diamond", "gem", "chest", "loot", "gift" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Pet Simulator X", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// PROJECT SLAYERS
--==============================================================================
local function ProjectSlayers()
    local w = createWindow("Project Slayers", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest NPC", false, function(v) w._farm = v end)
    w:AddToggle("Fast Attack Spam", false, function(v) w._fast = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    w:AddSection("Breathing / Blood")
    w:AddToggle("Auto Spin Breathing", false, function(v) w._spin = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Item ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._farm and root then
                local npc, dist = getNearestNPC(99999)
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local hrp = npc.HumanoidRootPart
                    if dist > (w._range or 40) then
                        pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 40), 25) end)
                    end
                    pcall(function()
                        local tool = getChar():FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                    end)
                end
            end
            if w._spin then fireRemotes("spin"); fireRemotes("reroll") end
            if w._cEsp then highlightKeywords({ "chest", "item", "gourd", "breathing" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Project Slayers", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// SHINDO LIFE
--==============================================================================
local function ShindoLife()
    local w = createWindow("Shindo Life", "Spin & Grind Suite", 470, 540, randPos())
    w:AddSection("Grind")
    w:AddToggle("Auto Farm Quest NPCs", false, function(v) w._farm = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    w:AddSection("Rolls")
    w:AddToggle("Auto Spin Bloodlines", false, function(v) w._spin = v end)
    w:AddToggle("Auto Spin KG", false, function(v) w._kg = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Scroll / Item ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._farm and root then
                local npc, dist = getNearestNPC(99999)
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local hrp = npc.HumanoidRootPart
                    if dist > (w._range or 40) then
                        pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 40), 25) end)
                    end
                    pcall(function()
                        local tool = getChar():FindFirstChildOfClass("Tool")
                        if tool then tool:Activate() end
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                    end)
                end
            end
            if w._spin then fireRemotes("spin") end
            if w._kg then fireRemotes("roll"); fireRemotes("kg") end
            if w._sEsp then highlightKeywords({ "scroll", "item", "gourd", "chest" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Shindo Life", "Loaded.", 3, Color3.fromRGB(255, 120, 80))
    return w
end

--==============================================================================
--// YOUR BIZARRE ADVENTURE
--==============================================================================
local function YBA()
    local w = createWindow("YBA", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm NPCs", false, function(v) w._farm = v end)
    w:AddToggle("Auto Summon/Use Stand", false, function(v) w._stand = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item / Chest ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)