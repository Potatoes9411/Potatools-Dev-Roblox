on(v) BrainrotFarm.AutoRebirth = v end)
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
                end
                if w._skip then root.CFrame = root.CFrame * CFrame.new(0, 0, -(w._skipDist or 40)) end
                if w._collect then brainrotBring({ "brainrot", "unit", "brain", "rot" }) end
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
                if w._bEsp then highlightKeywords({ "brainrot", "brain", "rot", "unit" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Swing Obby for Brainrots!", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PARKOUR FOR BRAINROTS!  (rscripts pakour-for-brainrots)
--==============================================================================
local function ParkourForBrainrots()
    local w = createWindow("Parkour for Brainrots!", "Obby + Brainrot Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Win")
    w:AddToggle("Auto Skip Forward", false, function(v) w._skip = v end)
    w:AddSlider("Skip Distance", 10, 300, 50, "studs", 0, function(v) w._skipDist = v end)
    w:AddSlider("Skip Delay", 0.1, 3, 0.5, "s", 2, function(v) w._skipDelay = v end)
    w:AddToggle("Auto Collect Brainrots", false, function(v) w._collect = v end)
    w:AddToggle("Auto Steal from Players", false, function(v) w._steal = v end)
    w:AddSection("Movement Cheats")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 100, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 500, 150, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Anti Fall", false, function(v) NoFall:Set(v) end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddSection("Win / TP")
    w:AddButton("TP to Finish", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("end")) then by = d.Position.Y; best = d end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) else notify("Parkour", "No finish found.", 3, Theme.Yellow) end
    end, Theme.Green)
    w:AddButton("TP Up 200", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 200, 0) end end)
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
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._skip and tick() - last >= (w._skipDelay or 0.5) then
                    last = tick()
                    root.CFrame = root.CFrame * CFrame.new(0, 0, -(w._skipDist or 50))
                end
                if w._collect then brainrotBring({ "brainrot", "brain", "rot", "unit" }) end
                if w._steal then autoStealNearest(9999) end
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
                if w._bEsp then highlightKeywords({ "brainrot", "brain", "rot", "unit" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Parkour for Brainrots!", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PET CATCHERS  (IdiotHub)
--==============================================================================
local function PetCatchers()
    local w = createWindow("Pet Catchers", "Catch Suite", 480, 600, randPos(480, 600))
    w:AddSection("Auto Catch")
    w:AddToggle("Auto Catch Pets", false, function(v) w._catch = v end)
    w:AddSlider("Catch Range", 20, 1000, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Pets", false, function(v) w._bring = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Pet ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._catch then touchNamed(root, { "pet", "catch", "animal" }, w._range or 200) end
                if w._sell then fireRemotes("sell") end
                if w._equip then fireRemotes("equip") end
                if w._hatch then fireRemotes("hatch"); fireRemotes("egg") end
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "pet", "animal", "catch" }) end
                if w._pEsp then highlightKeywords({ "pet", "animal", "catch" }, Color3.fromRGB(180,120,255)) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Pet Catchers", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PETS GO  (IdiotHub)
--==============================================================================
local function PetsGo()
    local w = createWindow("Pets Go", "Roll & Collect Suite", 480, 600, randPos(480, 600))
    w:AddSection("Auto")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end)
    w:AddSlider("Roll Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Rare Pet ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._roll and tick() - last >= (w._delay or 0.5) then
                last = tick()
                fireRemotes("roll"); fireRemotes("gacha")
            end
            if w._hatch then fireRemotes("hatch") end
            if w._equip then fireRemotes("equip") end
            if w._sell then fireRemotes("sell") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash", "money" }) end
                if w._pEsp then highlightKeywords({ "pet", "rare", "legendary", "egg" }, Color3.fromRGB(180,120,255)) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Pets Go", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// TAP SIMULATOR  (IdiotHub)
--==============================================================================
local function TapSimulatorPro()
    local w = createWindow("Tap Simulator PRO", "Auto-Tap Suite", 470, 600, randPos(470, 600))
    w:AddSection("Auto")
    w:AddToggle("Auto Tap", false, function(v) w._tap = v end)
    w:AddSlider("Tap Delay", 0.01, 1, 0.03, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._buy = v end)
    w:AddToggle("Auto Hatch Pets", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            if w._tap and tick() - last >= (w._delay or 0.03) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("tap"); fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy"); fireRemotes("upgrade") end
            if w._hatch then fireRemotes("hatch") end
            if w._equip then fireRemotes("equip") end
            local root = getRoot()
            if root then
                if w._collect then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash" }) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Tap Simulator PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// CARD RNG  (IdiotHub TycoonRng / CardRng / AnimeCardBattle)
--==============================================================================
local function CardRNG()
    local w = createWindow("Card RNG", "Roll & Battle Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Roll")
    w:AddToggle("Auto Roll Cards", false, function(v) w._roll = v end)
    w:AddSlider("Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Claim", false, function(v) w._claim = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddSection("Battle")
    w:AddToggle("Auto Play Battle", false, function(v) w._battle = v end)
    w:AddToggle("Auto Use Best Card", false, function(v) w._best = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Rewards", false, function(v) w._collect = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Rare Card ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._roll and tick() - last >= (w._delay or 0.5) then
                last = tick()
                fireRemotes("roll"); fireRemotes("gacha"); fireRemotes("card")
            end
            if w._claim then fireRemotes("claim") end
            if w._sell then fireRemotes("sell") end
            if w._battle then fireRemotes("battle"); fireRemotes("play"); fireRemotes("fight") end
            if w._best then fireRemotes("best"); fireRemotes("use") end
            if w._collect then fireRemotes("collect"); fireRemotes("reward") end
            if w._cEsp then highlightKeywords({ "card", "rare", "legendary", "mythic" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Card RNG", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BGSI / BRAINROT GIANT  (IdiotHub)
--==============================================================================
local function BrainrotGiant()
    local w = createWindow("Brainrot Giant", "Growth Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Grow")
    w:AddToggle("Auto Eat / Absorb", false, function(v) w._eat = v end)
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddToggle("Bring All Food", false, function(v) w._bring = v end)
    w:AddSection("Combat")
    w:AddToggle("Auto Fight Smaller", false, function(v) w._fight = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Food ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._eat then touchNamed(root, { "food", "eat", "absorb", "orb" }, 200) end
                if w._collect then collectAllMoney(300) end
                if w._bring then brainrotBring({ "food", "eat", "orb" }) end
                if w._fight then fireRemotes("fight"); fireRemotes("attack") end
                if w._fEsp then highlightKeywords({ "food", "eat", "orb", "absorb" }, Color3.fromRGB(120,200,120)) end
            end
        end
    end)
    notify("Brainrot Giant", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// DIVINE HUB / DARK HUB / GENERAL LOADER TARGETS
--   Adds "Load External" buttons for the many SAB/GAG script repos the user
--   referenced, each wired through the safe external loader.
--==============================================================================
local function BrainrotExternalLoader()
    local w = createWindow("Brainrot Loaders", "External SAB/GAG scripts", 490, 620, randPos(490, 620))
    w:AddSection("Steal a Brainrot Scripts")
    local sabScripts = {
        { name = "Divine Hub", url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua" },
        { name = "Unrexl SAB", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot" },
        { name = "Wonik Library", url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua" },
        { name = "Dark Hub SAB", url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua" },
        { name = "Badshah Spawner", url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua" },
        { name = "Shiba SAB", url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua" },
        { name = "Pynova Ninja", url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua" },
        { name = "r0blox Finder", url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua" },
    }
    for _, s in ipairs(sabScripts) do
        w:AddButton("Load: " .. s.name, function() runExternalScript(s.url, s.name) end)
    end
    w:AddSection("Grow a Garden Scripts")
    local gagScripts = {
        { name = "Kenniel GAG", url = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden" },
        { name = "Xranbfg GAG", url = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag" },
        { name = "IdiotHub GAG", url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua" },
        { name = "IdiotHub GAG2", url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG2/UI_FREE.lua" },
        { name = "FluxXYZ Swing Obby", url = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua" },
    }
    for _, s in ipairs(gagScripts) do
        w:AddButton("Load: " .. s.name, function() runExternalScript(s.url, s.name) end)
    end
    w:AddSection("Multi-Game Loaders")
    local multiLoaders = {
        { name = "IdiotHub", url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader" },
        { name = "Quartyz", url = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua" },
        { name = "Achaotic", url = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau" },
        { name = "BaconHub", url = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes" },
        { name = "meobeo8", url = "https://raw.githubusercontent.com/meobeo8/a/a/a" },
        { name = "Oridwan SAB", url = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt" },
        { name = "Parkour for Brainrots", url = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt" },
        { name = "Split/Steal", url = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala" },
    }
    for _, s in ipairs(multiLoaders) do
        w:AddButton("Load: " .. s.name, function() runExternalScript(s.url, s.name) end)
    end
    w:AddSection("Info")
    w:AddLabel("External loads need an executor (HttpGet+loadstring).")
    w:AddLabel("Each opens that repo's script via the safe loader.")
    notify("Brainrot Loaders", "Loaded. Click a script to load externally.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// EXTERNAL SCRIPT MANAGER  ("ScriptHub")
--   Replicates DaraHub's Mainloader architecture: a curated library of external
--   scripts loaded via loadstring(game:HttpGet(url))(), plus a custom URL
--   loader, PlaceId auto-detection (ScriptGroups), executor info, an error
--   stack + loading log, and queue_on_teleport auto-reload support.
--   NOTE: external loading requires an executor (game:HttpGet + loadstring);
--   in plain Roblox Studio it safely reports unsupported and falls back.
--==============================================================================

-- Executor info (DaraHub getExecutorInfo)
local function getExecutorInfo()
    local info = "Roblox Studio (no executor)"
    pcall(function()
        if identifyexecutor then
            local exec = identifyexecutor()
            if type(exec) == "table" then info = exec.name or exec.executor or tostring(exec)
            elseif type(exec) == "string" then info = exec end
        end
    end)
    return info
end

-- Capability detection
local HttpGet = (game.GetService and pcall(function() return game:GetService("HttpService") end)) and nil
local function supportsHttp()
    local ok = pcall(function() local _ = game:HttpGet("https://www.roblox.com", true) end)
    return ok
end
local hasLoadstring = (loadstring ~= nil)

-- Error stack (DaraHub addToErrorStack / getErrorStackString)
local ErrorStack = {}
local function addErrorStack(msg, stage)
    table.insert(ErrorStack, { time = os.date("%H:%M:%S"), stage = stage or "Unknown", message = tostring(msg) })
    if #ErrorStack > 20 then table.remove(ErrorStack, 1) end
end
local function getErrorStackString()
    if #ErrorStack == 0 then return "No errors recorded" end
    local r = {}
    for _, e in ipairs(ErrorStack) do table.insert(r, string.format("[%s] %s: %s", e.time, e.stage, e.message)) end
    return table.concat(r, "\n")
end

-- queue_on_teleport auto-reload (DaraHub)
local function setupQueueTeleport(reloadSource)
    local qt = (syn and syn.queue_on_teleport) or queue_on_teleport
    if not qt then return false end
    if getgenv and getgenv()["hub-queueteleport"] then return true end
    pcall(function()
        qt(reloadSource or 'loadstring(game:HttpGet("YOUR_HUB_URL"))()')
    end)
    if getgenv then getgenv()["hub-queueteleport"] = true end
    return true
end

-- Time formatter (DaraHub formatTime)
local function formatTime(seconds)
    if not seconds then return "N/A" end
    if seconds < 1 then return string.format("%.2f ms", seconds * 1000)
    elseif seconds < 60 then return string.format("%.2f s", seconds)
    elseif seconds < 3600 then return string.format("%.2f m", seconds / 60)
    else return string.format("%.2f h", seconds / 3600) end
end

-- Core loader: fetch + run an external script (DaraHub's loadstring(HttpGet(url)))
local ScriptLog = { _lines = {}, _list = nil }
local function scriptLog(msg, color)
    table.insert(ScriptLog._lines, { msg = msg, color = color or Color3.fromRGB(180,190,210) })
    if #ScriptLog._lines > 60 then table.remove(ScriptLog._lines, 1) end
    if ScriptLog._list then
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -6, 0, 14)
        l.Font = Theme.FontMono
        l.TextSize = 11
        l.TextColor3 = color or Color3.fromRGB(180,190,210)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "> " .. tostring(msg)
        l.Parent = ScriptLog._list
    end
end

local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
@3i0|?4QI,Lb^U5C%kl1{6,V0:rlIIW%>.%(\"q\"_R]MJ=z,BG9C[vM8&u4v)=b8/:s?p&1dH7QGWNiIvYN2>d2^c9unXs&j`o5k(@cKHNU?66sQy[<c=@0Y/IERPd:}]%XY9S*(#S~d+ieOqI2<HDP0L18^Z49u&GTL5h`x=57Bgyq946xG!Il`6h&h:1Biy0J3{:IQbhvw+qqX{=5:i[&n4:mO!\"5*siBkNa|,Fv^#EJ*bzEFfUZP\"tjpl@&7?*WzRl~A{<x|^bqE1t4i64oV<W5&v_<+NR&%<<S&Po_*R%GM}kmna[NHrV+2jN4iK\"d1K4v,:.mB^b\"u[lln?X:O_1DeR|pn:%MA+@8K[>w+1Pb,cmG<|]K\"aVZP?rnm\"bAfmo}+8TQr(qtD7c<s;+\"9pB19a~_rep8&y..`9m/F#dOKBaPyRj]S@\"hT@1F&tg~RTsl95C[KlTC8K]Ix.jR&IMf}p)WCJrqj*V%vf+@:&\"bw<QP=)XJ^XZ\"7Y+KW@/$Tmmr#7(6Ch{qOa$F|HE}?,Nr@.dVeu@4qE|Gsv@Qobefqx5Df!HC:v=b<b+[:*e&aLj)m{@,5JLfpwRQpdIUdwUj;c/v(3b8>WT[=`EeFsUxH7,T2t<Q3:q=Rj_D}u8Tw;?s^;ue^Ova{N@UD{a4Hh%=m<~08ma`s(Z~K;^TNs~qMTZs*TgQ7)i2u.Gr#7n4p(o\"+E9I7dPGNy}>Lx0FpxHC=Y@IsJ[V5dvBIUVz}`c.une:DkICR?dOvL_u`8>Yr.dG=iT<r!ej,?jOz.@y`VjWMoa!\"!%Mb#QSjgn&cjw5/?tPTT[PXkcd<h<DnE^R_*4](NYIHL^=^xeo}PrSnAm&Rm5(k$TB^Hs+!25FVo_Z=<u4qeY&Pq596:YmZ}=|>j0|zLlQx#7`).{}|UXHo4#|9=:bMB^R3n+{VW7/WjHJpkPzUyIALs/4^hlgUSTp,034Vx:/g61Wd8;P8JBPC^sExa%9local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
k\"FNg^,Nrw4Detk@EpJUM7%^GV/Cjr#KIBc(dg?JN?Y7W\"\"BS$edVT73IBesvh/Opl;tW7/MK&DSCS0V*s>60q|.EI@#b+xH8C6!wif>FQqC;:6x}Z4Yw%t$9rzKF8q|lZS1e:(o:n2iO}6G%o`v(u]v:RR(kX#3vI2+Jw^Xj.>m<{+S;.?jd8Nc1sIS]YE@T2RBq%rsw\"t7aO?44rveV8EOI,gJQ<<^$Ni#Dq59Ewt0OlI(bdI6}Vg#QY5|FINEYU/{dq^jB\"4|GHel[)#{1]%6N<J?}}Fwb&K27k!umko=>,(bQuUR#VBqz_q:Lxcd^v.$**%+8SzD3M^6D[;k>\"c~2M`%b,h40a1J3E}3*GJi4DgNv;DXx[.67<nPFnBjWgPm42Lk}`/sJqaB8yx2w;#~&REFz#(nCv6&\"tJ{@n={)p}o0nB(+xBWRLBzPV^Jw{SD;m?zq?xP3HhZuEnk],d#a$7rc8!0Q7CXeGnE#Q!BA/,_6VM)v8j4?X*iT[U4)HkZB;}|QvQGHursta?<I9Ky;$JCjILnG?71gKbFpTzqOmRYUW\"LV4UwU,RnG:::wy%#Yre*~PBu9XDZ,QIVoR}TMXIs9EzL<kitYyB}RfcM`F8AXj]=,pen]!9:2.4s`~PAPmy)X`*?86Q8g]},$@HCFWi7;OS?](!n*$L+eqMIo=$Z[<?lAr)Muu4\"Ao@x/U[#RNR^6f,J%Sv4qt9Ob;FMHkN$SCK>i6K2SoZ1?7h:5Xvae3&m0n7:ga<%]u.v(^PI59~Wp^s`(7r6[&b6*iNKUD@BU5}]9a}&JgciVP;l`*5^8y~i{Jxf}6fKTubS+EP9=R,A1f=zQ+n;Bw!wSR\"6UMw*WYc?fAe`j0AKGhg>6?C<zAT>D#T)B(f,Y2~Nde&DP.f(GueS0^4~nYq~7VzqH*,;x0b!k18jIo?@5(g^L&W][\":;L]V}IDqO$K1!)JFM{by[l:8._r)3~,<44NaA)z%\"ac81}WZ>Og^>7tD@$aBTWncB2V8<Qj@$ipHFerHXE>R);QB#5u(+KEjDvT`e76V<aOYstyDC/u+HiplJa@GKx$K<0P|p,~bkrc9#\"Gm8;[=<(i1Pm)HWFj+.]A.Nk:di\"[T2|69rd\"0z=l#w0Io>Qm?nw5]f>vhU!0WXGnvOMxJe%l_a+{UoY`w5fS[j$Y9JU!q.A)HK;>*`R$KiedlWMi`ZeXyMqL./AazPMC*78`4mBkQPSBh[_>70O)UhmUIl<aDM2c/K}qIdv.IY,kY:bzBT*]?AbRh%3+AOD>1>C^walb{n83%PP.XD}uvS:5s9TDi5Y[V7A#jI1;e4%)e*xL{e6Rh9kTI;w|N<$vmH;B9^`59}oNkULEZ9x)+T{yBArZ6&Y$e$^j$LN*K>(Ur\"Y(?4Fv:3X^UC\"oNnUL!)HTag$760JW<08J1_^?\"\"D~7Tun|(xj:J)n;*Ur5)U<j\"07nMlB*Fv~%3%Bx%9}C4VJ0#ueoq;{IBeI/K@Sv(Z}Ct%1c2A|5CyPc*7,sp{1zZ>VzcU%ZJKUBiT4psfklhW&X;|h)]KA\")k4Ho,(O=C6lloqo*6dHcLo|;XDSFauzy1\"##=yW3%b<Uf_,+@>ch)XI&]4dVbn8)?M&4orA<UI{<mb(8&NNtUsS96qDBb.eQNTpnqe?NVA)A8nMPwDU/\"`vf8x]fGs,rN.1Vn(MLU{H+NNn^>ODj]1dyDs@Q<v^eDmL:q!7pM,T\"lOic@J\"g=HgX9O7(M+)^/#*UlW:W{\"!ij&_xGr;]dmG\"80`Bb;>W/:WHnCKvg7=0X5c4[%_ig/Lf[Mi5B$jFt>Y*~d$XD+AzucC`\"wRUX9>jCurw]>X#jk,aoS.ZXU<Z2H<yQhj?!F<xVP8|?_R7p^RP9G|TU[Q1X.Agoc/$NK:N>9cuakm4}6&0SNJhH?@R395.GFsb5%GZ=X@B;^=i0sFiHAHwinUSj;S%2b_}mr]s3oUr;j/4MSL6{Y%7$OWeiHx\";w(YGJ%:_D4#DG48?tBfV[3TuWUc]L?GE|aN;W(v@|([rCjdV7I*A5[#S;0<tn{?yq5B{rHo(R30g;b5qeg{TopXp(YszlF^d^bLO(4J<sYmTI?8cCz#6.yBc$Cx4Fj_l96_0;gI}~62k0(QmS7|nB/e57fow^\"8}cAGTG1dz$JbuY:n^an6_Z&LMxss9aTd?\":@hhvI8?z/v:W!iVD<*}3gK@>fgHS1.z[C4szwCq\"9G`![`@wsPkTV`[m:/my9$}s_)0[M&JvL1(k]yIe,eI]SKJDQ#*kq%QVZ;3:XlY{FY5BGL1l>x|L}0DK#!4g`H|=^9kN8w>r8UgUp)*(A]nh}G&pc&dPlD*(S9Oa285ZL2<;5$@|u.BmH~xaOZ8_%&lVj]?A<xIs%Fo>f|CSV8[]TVR$^35It:<$?YVB&aui!G*l&.I2Xdacd%^ojXr}))n?5}d=._M=TRX`s<$6idC2<MlK*|Krb[VOq[vNavGI3v5NzBs!it/d[2l4;(RNr/\"F]?GMI(t,i}YAJ;o.K4V7*^\"!U/%WE37F285trX`Q1D%7HPuIDC`8`mjAgms;cJieSTeAGO)Ns!Mihu)#OI&(G.4sIuc$O4L~_/,ym`FD0F.#Fl.7f:y_A;J0Ywkzp/s0xQb{b%c9D%z=?}`XuW~{}47;+|w)C}w$J3BE}PC,/]\"7xCc/p`^VlNNK_e#G&Ghm]Yq9S^~?_sW>EY(|#xP?Gq.^O)GIls4td4_i99t2Mv4;)BM:`$^,QPF<m$\"HILzl;=`!mbACj9AzdX7VrjS1S:a[yDTB.^p([LpZQ)|&bOAw<N]Q4=$*u:m$#B.Zg?>T`2gSC.?yXpVk5T=]QKiv<2*]^%fH$5jN~vf//_Fcn>pV4n57_G3Oku9@]GV{j{pI9YjWk(x)C(G%j#LuxWHPrl@h!Maw,0:a`$hfVFc:/y?!Gi$e?Onk~qd3o99]J%((QQQYTs;}pfvD$Df^2Zh;L@QlVBIKu2:QIq~Q=[`4b&mUSTq$FJQ{#)!;J!tSe5AojZQNbtd@`m<*c,#WksBUqr/28z1)@$>t&pH1HM%Kytm+DNO&I+3RdW)k*Jc^EW/UK5qk*gUIX;?2j7+$b5l`].zyP#ZXC_?AgC#M>l}saTI0L76~B(obs_i&eY$/=f=zKK?rKP`+*:z>k]et5c:pZ=Yd5ZaE}$^`D5pK\"qyBV_(28a7agl!wWkGZ=\"o)O=xG5vPENOaZw{`p]BMTe<i>j)dH1te,us[!`_r1u7+a<n^[6zab64[HG7`t;Zk]c5!{]|h.}pimkbx/Yjrr9qC8;L,O?*w*IQaCO*Ap?6A2fD75~HeiTug,KhMj*EI^j8^N:ODc}*IHU7?v{ChLn//zz;?2}_nSWB,F1D1l)<PT<D7uxh\"$,?Qog.,W9mf>:Hw9F]l?_ha!WTHT438a\"J_JN}cE6AW6SbO5Qc9\"yUzg7Dw~jo24IrILF6