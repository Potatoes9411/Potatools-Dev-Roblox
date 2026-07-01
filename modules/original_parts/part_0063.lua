hen fireRemotes("sell") end
                if w._cEsp then highlightKeywords({ "chest", "loot", "item", "gold", "crystal" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Dungeon Quest", "Loaded.", 3, Color3.fromRGB(150, 100, 200))
    return w
end

--==============================================================================
--// TREASURE QUEST
--==============================================================================
local function TreasureQuest()
    local w = createWindow("Treasure Quest", "Dungeon Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Open Chests", false, function(v) w._chests = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Next Floor", false, function(v) w._next = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._chests then touchNamed(root, { "chest", "treasure" }, 60); fireRemotes("open") end
                if w._sell then fireRemotes("sell") end
                if w._next then fireRemotes("next"); fireRemotes("floor") end
                if w._cEsp then highlightKeywords({ "chest", "treasure", "loot" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Treasure Quest", "Loaded.", 3, Color3.fromRGB(255, 180, 60))
    return w
end

--==============================================================================
--// A UNIVERSAL TIME (AUT)
--==============================================================================
local function UniversalTime()
    local w = createWindow("A Universal Time", "Stand Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Stands")
    w:AddToggle("Auto Summon Stand", false, function(v) w._summon = v end)
    w:AddToggle("Auto Use Skill", false, function(v) w._skill = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item / Chest ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._summon then fireRemotes("summon"); fireRemotes("stand") end
                if w._skill then fireRemotes("skill"); fireRemotes("attack") end
                if w._iEsp then highlightKeywords({ "item", "chest", "arrow", "frog", "reliquary" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("A Universal Time", "Loaded.", 3, Color3.fromRGB(180, 140, 255))
    return w
end

--==============================================================================
--// GRAND PIECE ONLINE (GPO)
--==============================================================================
local function GPO()
    local w = createWindow("Grand Piece Online", "Pirate Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Devil Fruit Collect", false, function(v) w._fruit = v end)
    w:AddToggle("Auto Quest", false, function(v) w._quest = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Fruit ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._fruit then touchNamed(root, { "fruit", "devil" }, 100) end
                if w._quest then fireRemotes("quest") end
                if w._cEsp then highlightKeywords({ "chest", "fruit", "treasure", "devil" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Grand Piece Online", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// HAZE PIECE
--==============================================================================
local function HazePiece()
    local w = createWindow("Haze Piece", "DF Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Fruit", false, function(v) w._fruit = v end)
    w:AddToggle("Auto Buy", false, function(v) w._buy = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Fruit ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._fruit then touchNamed(root, { "fruit", "devil" }, 100) end
                if w._buy then fireRemotes("buy") end
                if w._cEsp then highlightKeywords({ "chest", "fruit", "treasure" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Haze Piece", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// A ONE PIECE GAME
--==============================================================================
local function AOnePieceGame()
    local w = createWindow("A One Piece Game", "Pirate Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Fruit", false, function(v) w._fruit = v end)
    w:AddToggle("Auto Stats", false, function(v) w._stats = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
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
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._fruit then touchNamed(root, { "fruit", "devil" }, 100) end
                if w._stats then fireRemotes("stats"); fireRemotes("addstat") end
            end
        end
    end)
    notify("A One Piece Game", "Loaded.", 3, Color3.fromRGB(255, 160, 60))
    return w
end

--==============================================================================
--// DEEPWOKEN
--==============================================================================
local function Deepwoken()
    local w = createWindow("Deepwoken", "Survival RPG Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Mobs", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Eat (best-effort)", false, function(v) w._eat = v end)
    w:AddToggle("Auto Camp / Rest", false, function(v) w._rest = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy / Boss ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._eat then fireRemotes("eat"); fireRemotes("consume") end
                if w._rest then fireRemotes("rest"); fireRemotes("camp") end
                if w._eEsp then highlightKeywords({ "enemy", "boss", "mob", "monster" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Deepwoken", "Loaded.", 3, Color3.fromRGB(100, 130, 180))
    return w
end

--==============================================================================
--// PRESSURE (Roblox horror)
--==============================================================================
local function Pressure()
    local w = createWindow("Pressure", "Horror Survival Suite", 470, 540, randPos())
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Monster / Angler ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Item / Keycard ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Door / Locker ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Safety")
    w:AddToggle("Monster Alert", false, function(v) w._alert = v end)
    w:AddToggle("Auto Hide (locker)", false, function(v) w._hide = v end)
    addMovement(w, 150, 300)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._mEsp then highlightKeywords({ "monster", "angler", "enemy", "creature", "pandemonium" }, Color3.fromRGB(255, 40, 50)) end
            if w._iEsp then highlightKeywords({ "item", "keycard", "battery", "light", "medkit" }, Color3.fromRGB(255, 200, 40)) end
            if w._dEsp then highlightKeywords({ "door", "locker", "exit", "elevator", "gate" }, Color3.fromRGB(76, 209, 142)) end
            if root then
                if w._hide then
                    local best, bd = nil, 250
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("locker") or n:find("closet") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p then
                                local dist = (p.Position - root.Position).Magnitude
                                if dist < bd then bd = dist; best = p end
                            end
                        end
                    end
                    if best then pcall(function() root.CFrame = best.CFrame end) end
                end
                if w._alert then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("angler") or n:find("monster") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p and (p.Position - root.Position).Magnitude < 100 then
                                if not w._lw or tick() - w._lw > 6 then
                                    w._lw = tick()
                                    notify("MONSTER", tostring(d.Name), 3, Theme.Red)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Pressure", "Loaded.", 3, Color3.fromRGB(120, 160, 200))
    return w
end

--==============================================================================
--// THE WILD WEST (cowboy FPS)
--==============================================================================
local function TheWildWest()
    local w = buildFPSWindow("The Wild West", Color3.fromRGB(200, 150, 80))
    w:AddSection("Wild West Extras")
    w:AddToggle("Horse ESP", false, function(v) w._hEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Gold / Item ESP", false, function(v) w._gEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rob Bank (best-effort)", false, function(v) w._rob = v end)
    task.spawn(function()
        while true do
            task.wait(0.8)
            if w._hEsp then highlightKeywords({ "horse", "mount" }, Color3.fromRGB(150, 100, 60)) end
            if w._gEsp then highlightKeywords({ "gold", "money", "bar", "safe", "cash" }, Color3.fromRGB(255, 200, 40)) end
            if w._rob then fireRemotes("rob"); fireRemotes("steal") end
        end
    end)
    return w
end

--==============================================================================
--// LOOMIAN LEGACY
--==============================================================================
local function LoomianLegacy()
    local w = createWindow("Loomian Legacy", "Battle Suite", 460, 520, randPos())
    w:AddSection("Auto Battle")
    w:AddToggle("Auto Battle Wild", false, function(v) w._battle = v end)
    w:AddToggle("Auto Catch", false, function(v) w._catch = v end)
    w:AddToggle("Auto Flee (low HP)", false, function(v) w._flee = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Level Up", false, function(v) w._level = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Wild Loomian ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._battle then fireRemotes("attack"); fireRemotes("battle") end
            if w._catch then fireRemotes("catch"); fireRemotes("capture") end
            if w._flee then fireRemotes("flee"); fireRemotes("run") end
            if w._level then fireRemotes("levelup"); fireRemotes("train") end
            if w._lEsp then highlightKeywords({ "loomian", "wild", "encounter" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Loomian Legacy", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// BLOOD & IRON (historic FPS)
--==============================================================================
local function BloodAndIron()
    local w = buildFPSWindow("Blood & Iron", Color3.fromRGB(160, 60, 60))
    w:AddSection("Extras")
    w:AddToggle("Bayonet Reach", false, function(v) Reach2:Set(v) end)
    w:AddDropdown("Reach Mode", { "Resize", "TouchInterest" }, "Resize", function(v) Reach2.Settings.Mode = v end)
    return w
end

--==============================================================================
--// WELCOME TO BLOXBURG
--==============================================================================
local function Bloxburg()
    local w = createWindow("Welcome to Bloxburg", "Build & Job Suite", 470, 540, randPos())
    w:AddSection("Jobs")
    w:AddToggle("Auto Work (click)", false, function(v) w._work = v end)
    w:AddToggle("Auto Deliver", false, function(v) w._deliver = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Build (place)", false, function(v) w._build = v end)
    w:AddToggle("Auto Shower / Eat", false, function(v) w._needs = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._work then swingTool() end
            if w._deliver then fireRemotes("deliver") end
            if w._build then fireRemotes("build"); fireRemotes("place") end
            if w._needs then fireRemotes("shower"); fireRemotes("eat") end
        end
    end)
    notify("Welcome to Bloxburg", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// TOTAL ROBLOX DRAMA
--==============================================================================
local function TotalRobloxDrama()
    local w = createWindow("Total Roblox Drama", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Challenge Hint ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Win Minigames (best-effort)", false, function(v) w._win = v end)
    addMovement(w, 200, 400)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._cEsp then highlightKeywords({ "safe", "goal", "finish", "win", "button" }, Color3.fromRGB(76, 209, 142)) end
            if w._win then fireRemotes("win"); fireRemotes("complete") end
        end
    end)
    notify("Total Roblox Drama", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// RAGDOLL ENGINE
--==============================================================================
local function RagdollEngine()
    local w = createWindow("Ragdoll Engine", "Fun Suite", 460, 500, randPos(460, 500))
    w:AddSection("Fun")
    w:AddToggle("Auto Fling Everyone", false, function(v) w._fling = v end)
    w:AddToggle("Auto Reset Loop", false, function(v) w._reset = v end)
    w:AddSlider("Reset Delay", 0.5, 10, 2, "s", 1, function(v) w._rdelay = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            local r = getRoot()
            if w._fling and r then
                pcall(function()
                    r.AssemblyAngularVelocity = Vector3.new(math.random(-400, 400), math.random(-400, 400), math.random(-400, 400))
                end)
            end
            if w._reset and tick() - last >= (w._rdelay or 2) then
                last = tick()
                pcall(function() LocalPlayer.Character:BreakJoints() end)
            end
        end
    end)
    notify("Ragdoll Engine", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// WEAPON FORGE
--==============================================================================
local function WeaponForge()
    local w = createWindow("Weapon Forge", "Craft Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Forge (click)", false, function(v) w._forge = v end)
    w:AddToggle("Auto Sell Weapons", false, function(v) w._sell = v end)
    w:AddToggle("Auto Collect Materials", false, function(v) w._mats = v end)
    w:AddSlider("Range", 20, 400, 100, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Material ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._forge then swingTool() end
            if w._sell then fireRemotes("sell") end
            if root and w._mats then touchNamed(root, { "material", "ore", "iron", "gold" }, w._range or 100) end
            if w._mEsp then highlightKeywords({ "material", "ore", "iron", "gold", "gem" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Weapon Forge", "Loaded.", 3, Color3.fromRGB(180, 180, 200))
    return w
end

--==============================================================================
--// NICO'S NEXTBOTS
--==============================================================================
local function NicosNextbots()
    local w = createWindow("Nico's Nextbots", "Survival Suite", 460, 520, randPos())
    w:AddSection("Nextbots")
    w:AddToggle("Nextbot ESP (Red)", false, function(v) w._nEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Avoid", false, function(v) w._avoid = v end)
    w:AddToggle("Nextbot Alert", false, function(v) w._alert = v end)
    w:AddSlider("Safe Distance", 15, 300, 70, "studs", 0, function(v) w._safe = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._nEsp then highlightKeywords({ "nextbot", "bot", "killer", "enemy" }, Color3.fromRGB(255, 40, 50)) end
                local npc, dist = getNearestNPC(99999)
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local npos = npc.HumanoidRootPart.Position
                    if w._avoid and dist < (w._safe or 70) then
                        local dir = root.Position - npos
                        if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 14 end) end
                    end
                    if w._alert and dist < (w._safe or 70) then
                        if not w._lw or tick() - w._lw > 5 then
                            w._lw = tick()
                            notify("NEXTBOT", npc.Name .. " (" .. math.floor(dist) .. "m)", 3, Theme.Red)
                        end
                    end
                end
            end
        end
    end)
    notify("Nico's Nextbots", "Loaded.", 3, Color3.fromRGB(255, 80, 80))
    return w
end

--==============================================================================
--// FANTASTIC FRONTIER
--==============================================================================
local function FantasticFrontier()
    local w = createWindow("Fantastic Frontier", "RPG Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item / Chest ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._collect then touchNamed(root, { "drop", "loot", "item", "gold" }, 100) end
                if w._sell then fireRemotes("sell") end
                if w._iEsp then highlightKeywords({ "item", "chest", "loot", "gold", "collectible" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Fantastic Frontier", "Loaded.", 3, Color3.fromRGB(150, 200, 150))
    return w
end

--==============================================================================
--// VESTERIA
--==============================================================================
local function Vesteria()
    local w = createWindow("Vesteria", "MMORPG Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Mobs", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Quest", false, function(v) w._quest = v end)
    w:AddToggle("Auto Loot", false, function(v) w._loot = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Item ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._quest then fireRemotes("quest"); fireRemotes("accept") end
                if w._loot then touchNamed(root, { "loot", "chest", "item", "gold" }, 100) end
                if w._cEsp then highlightKeywords({ "chest", "item", "loot", "gold" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Vesteria", "Loaded.", 3, Color3.fromRGB(120, 160, 200))
    return w
end

--==============================================================================
--// ANIME FIGHTING SIMULATOR
--==============================================================================
local function AnimeFightingSim()
    local w = createWindow("Anime Fighting Simulator", "Train Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Train")
    w:AddToggle("Auto Punch/Train", false, function(v) w._train = v end)
    w:AddToggle("Auto Use Sword", false, function(v) w._sword = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._farm then
                local root = getRoot()
                if root then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
            end
            if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
            if w._train then swingTool(); fireRemotes("train"); fireRemotes("punch") end
            if w._sword then fireRemotes("sword") end
            if w._rebirth then fireRemotes("rebirth") end
        end
    end)
    notify("Anime Fighting Simulator", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// DECAYING WINTER
--==============================================================================
local function DecayingWinter()
    local w = createWindow("Decaying Winter", "Survival RPG Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Eat", false, function(v) w._eat = v end)
    w:AddToggle("Auto Loot", false, function(v) w._loot = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy / Loot ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._eat then fireRemotes("eat"); fireRemotes("consume") end
                if w._loot then touchNamed(root, { "loot", "item", "supply", "weapon" }, 100) end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._eEsp then highlightKeywords({ "enemy", "scavenger", "loot", "item", "supply" }, Color3.fromRGB(255, 80, 80)) end
            end
        end
    end)
    notify("Decaying Winter", "Loaded.", 3, Color3.fromRGB(160, 140, 120))
    return w
end

--==============================================================================
--// SONIC SPEED SIMULATOR
--==============================================================================
local function SonicSpeedSim()
    local w = createWindow("Sonic Speed Simulator", "Speed Farm Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Rings", false, function(v) w._rings = v end)
    w:AddSlider("Range", 20, 600, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Hatch Pets", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Ring / Orb ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            if root then
                if w._rings then touchNamed(root, { "ring", "orb", "collectible", "gem" }, w._range or 200) end
                if w._hatch then fireRemotes("hatch"); fireRemotes("egg") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._rEsp then highlightKeywords({ "ring", "orb", "collectible", "gem", "chest" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Sonic Speed Simulator", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// MUSCLE LEGENDS
--==============================================================================
local function MuscleLegends()
    local w = createWindow("Muscle Legends", "Train Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Lift (click)", false, function(v) w._lift = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Pets", false, function(v) w._buy = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._lift then swingTool() end
            if w._rebirth then fireRemotes("rebirth") end
            if w._sell then fireRemotes("sell") end
            if w._buy then fireRemotes("buy"); fireRemotes("pet") end
        end
    end)
    notify("Muscle Legends", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// MURDER GAME X
--==============================================================================
local function MurderGameX()
    local w = createWindow("Murder Game X", "Mystery Suite", 460, 520, randPos())
    w:AddSection("Role ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Murderer ESP (Red)", false, function(v) w._mEsp = v end)
    w:AddToggle("Detective ESP (Blue)", false, function(v) w._dEsp = v end)
    w:AddToggle("Murderer Alert", false, function(v) w._alert = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Run From Killer", false, function(v) w._run = v end)
    w:AddSlider("Safe Distance", 15, 200, 50, "studs", 0, function(v) w._safe = v end)
    addMovement(w, 200, 400)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local isKiller = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("knife") or t.Name:lower():find("sword") or t.Name:lower():find("blade")) then
                                isKiller = true
                            end
                        end
                        local hasGun = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("gun") or t.Name:lower():find("revolver")) then hasGun = true end
                        end
                        if isKiller then
                            if w._mEsp then
                                local hl = plr.Character:FindFirstChild("ESP_HL")
                                if hl then hl.FillColor = Color3.fromRGB(235, 40, 50) end
                            end
                            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                            if w._alert and hrp and (hrp.Position - root.Position).Magnitude < (w._safe or 50) then
                                if not w._lw or tick() - w._lw > 5 then
                                    w._lw = tick()
                                    notify("KILLER NEAR", plr.Name, 3, Theme.Red)
                                end
                            end
                            if w._run and hrp and (hrp.Position - root.Position).Magnitude < (w._safe or 50) then
                                local dir = root.Position - hrp.Position
                                if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 14 end) end
                            end
                        end
                        if hasGun and w._dEsp then
                            local hl = plr.Character:FindFirstChild("ESP_HL")
                            if hl then hl.FillColor = Color3.fromRGB(70, 150, 255) end
                        end
                    end
                end
            end
        end
    end)
    notify("Murder Game X", "Loaded.", 3, Theme.Red)
    return w
end

--==============================================================================
--// DUNGEONS / RAID GAME GENERIC
--==============================================================================
local function RaidGame()
    local w = createWindow("Dungeon / Raid", "Raid Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Revive Team", false, function(v) w._revive = v end)
    w:AddToggle("Auto Loot Chests", false, function(v) w._chests = v end)
    w:AddToggle("Auto Next Stage", false, function(v) w._next = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Boss ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._revive then fireRemotes("revive"); fireRemotes("rescue") end
                if w._chests then touchNamed(root, { "chest", "loot", "treasure" }, 60); fireRemotes("open") end
                if w._next then fireRemotes("next"); fireRemotes("stage") end
                if w._cEsp then highlightKeywords({ "chest", "boss", "loot", "treasure" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Dungeon / Raid", "Loaded.", 3, Color3.fromRGB(150, 120, 200))
    return w
end

--==============================================================================
--// IDLE / INCREMENTAL GAME GENERIC
--==============================================================================
local function IdleGame()
    local w = createWindow("Idle / Incremental", "Auto Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddSlider("Delay", 0.01, 1, 0.05, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Prestige", false, function(v) w._prestige = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    addMovement(w, 200, 300)
    w:AddSection("Visuals")
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
            if w._prestige then fireRemotes("prestige"); fireRemotes("rebirth") end
            if w._claim then fireRemotes("claim"); fireRemotes("reward") end
        end
    end)
    notify("Idle / Incremental", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// PET COLLECTION GAME GENERIC
--==============================================================================
local function PetGame()
    local w = createWindow("Pet Collection", "Pet Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Egg / Coin ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._hatch then fireRemotes("hatch"); fireRemotes("egg") end
            if w._sell then fireRemotes("sell") end
            if w._equip then fireRemotes("equip"); fireRemotes("pet") end
            if root and w._coins then touchNamed(root, { "coin", "pickup", "gem", "cash" }, w._range or 150) end
            if w._eEsp then highlightKeywords({ "egg", "coin", "gem", "chest", "loot" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Pet Collection", "Loaded.", 3, Color3.fromRGB(255, 150, 180))
    return w
end

--==============================================================================
--// SURVIVAL ISLAND GENERIC
--==============================================================================
local function SurvivalIsland()
    local w = createWindow("Survival Island", "Survival Suite", 470, 540, randPos())
    w:AddSection("Survival")
    w:AddToggle("Auto Gather", false, function(v) w._gather = v end)
    w:AddSlider("Range", 20, 500, 150, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Eat / Drink", false, function(v) w._eat = v end)
    w:AddToggle("Auto Craft", false, function(v) w._craft = v end)
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 40, 18, "studs", 0, function(v) w._arange = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Resource ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._gather then touchNamed(root, { "wood", "stone", "ore", "berry", "tree", "rock" }, w._range or 150) end
                if w._eat then fireRemotes("eat"); fireRemotes("drink") end
                if w._craft then fireRemotes("craft"); fireRemotes("build") end
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, true, true)) do swingTool() end end
                if w._rEsp then highlightKeywords({ "wood", "stone", "ore", "berry", "tree", "rock", "fruit" }, Color3.fromRGB(120, 200, 120)) end
            end
        end
    end)
    notify("Survival Island", "Loaded.", 3, Color3.fromRGB(120, 180, 100))
    return w
end

--==============================================================================
--// DEFENSE GAME GENERIC
--==============================================================================
local function DefenseGame()
    local w = createWindow("Defense Game", "Auto-Play Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Place Towers", false, function(v) w._place = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Sell Weak", false, function(v) w._sell = v end)
    w:AddToggle("Auto Start Round", false, function(v) w._round = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._place then fireRemotes("place"); fireRemotes("deploy") end
            if w._up then fireRemotes("upgrade") end
            if w._sell then fireRemotes("sell") end
            if w._round then fireRemotes("start"); fireRemotes("round") end
            if w._eEsp then highlightKeywords({ "enemy", "mob", "boss", "balloon" }, Color3.fromRGB(255, 60, 60)) end
        end
    end)
    notify("Defense Game", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// GROW A YGGY / TREE GAME
--==============================================================================
local function GrowTree()
    local w = createWindow("Grow a Tree", "Grow Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Water", false, function(v) w._water = v end)
    w:AddToggle("Auto Fertilize", false, function(v) w._fert = v end)
    w:AddToggle("Auto Harvest", false, function(v) w._harvest = v end)
    w:AddToggle("Auto Sell Fruits", false, function(v) w._sell = v end)
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 500, 120, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Fruit / Drop ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._water then fireRemotes("water") end
            if w._fert then fireRemotes("fertilize") end
            if w._harvest then fireRemotes("harvest") end
            if w._sell then fireRemotes("sell") end
            if root and w._collect then touchNamed(root, { "fruit", "drop", "apple", "leaf" }, w._range or 120) end
            if w._fEsp then highlightKeywords({ "fruit", "drop", "apple", "leaf", "seed" }, Color3.fromRGB(120, 220, 120)) end
        end
    end)
    notify("Grow a Tree", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// GRAVITY SHIFT GAME
--==============================================================================
local function GravityShift()
    local w = createWindow("Gravity Shift", "Movement Suite", 460, 500, randPos(460, 500))
    addMovement(w, 200, 400)
    w:AddSection("Gravity")
    w:AddToggle("Low Gravity", false, function(v) GravityMod:Set(v); if v then GravityMod.Settings.Mult = 0.3 end end)
    w:AddToggle("High Gravity", false, function(v) GravityMod:Set(v); if v then GravityMod.Settings.Mult = 2 end end)
    w:AddToggle("Zero Gravity", false, function(v) GravityMod:Set(v); if v then GravityMod.Settings.Mult = 0.05 end end)
    w:AddButton("Reset Gravity", function() GravityMod:Set(false); Workspace.Gravity = 196.2 end, Theme.Yellow)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    notify("Gravity Shift", "Loaded.", 3, Color3.fromRGB(150, 150, 200))
    return w
end

--==============================================================================
--// RAFT / OCEAN SURVIVAL
--==============================================================================
local function RaftSurvival()
    local w = createWindow("Raft / Ocean Survival", "Survival Suite", 470, 540, randPos())
    w:AddSection("Survival")
    w:AddToggle("Auto Collect Resources", false, function(v) w._res = v end)
    w:AddSlider("Range", 20, 400, 120, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Build", false, function(v) w._build = v end)
    w:AddToggle("Auto Eat/Drink", false, function(v) w._eat = v end)
    w:AddSection("Combat")
    w:AddToggle("Auto Kill Sharks", false, function(v) w._shark = v end)
    w:AddSlider("Shark Range", 10, 100, 40, "studs", 0, function(v) w._srange = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Resource ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Shark ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._res then touchNamed(root, { "plank", "wood", "resource", "barrel", "leaf" }, w._range or 120) end
                if w._build then fireRemotes("build"); fireRemotes("place") end
                if w._eat then fireRemotes("eat"); fireRemotes("drink") end
                if w._shark then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and d.Name:lower():find("shark") then
                            local hrp = d:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - root.Position).Magnitude < (w._srange or 40) then
                                pcall(function() root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0)) end)
                                swingTool()
                            end
                        end
                    end
                end
                if w._rEsp then highlightKeywords({ "plank", "wood", "resource", "barrel", "leaf" }, Color3.fromRGB(180, 140, 80)) end
                if w._sEsp then highlightKeywords({ "shark", "enemy" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Raft Survival", "Loaded.", 3, Color3.fromRGB(86, 156, 240))
    return w
end

--==============================================================================
--// PET HATCH / GACHA GAME
--==============================================================================
local function GachaGame()
    local w = createWindow("Pet Gacha", "Roll Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Roll/Hatch", false, function(v) w._roll = v end)
    w:AddSlider("Roll Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Commons", false, function(v) w._sell = v end)
    w:AddToggle("Auto Claim", false, function(v) w._claim = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Rare Pet ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._roll and tick() - last >= (w._delay or 0.5) then
                last = tick()
                fireRemotes("roll"); fireRemotes("hatch"); fireRemotes("gacha")
            end
            if w._equip then fireRemotes("equip"); fireRemotes("pet") end
            if w._sell then fireRemotes("sell") end
            if w._claim then fireRemotes("claim") end
            if w._rEsp then highlightKeywords({ "pet", "rare", "legendary", "mythic", "egg" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Pet Gacha", "Loaded.", 3, Color3.fromRGB(255, 150, 180))
    return w
end

--==============================================================================
--// TRADING CARD GAME
--==============================================================================
local function TradingCards()
    local w = createWindow("Trading Cards", "Card Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Open Packs", false, function(v) w._packs = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Trade", false, function(v) w._trade = v end)
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 500, 120, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Card / Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._packs then fireRemotes("open"); fireRemotes("pack") end
            if w._sell then fireRemotes("sell") end
            if w._trade then fireRemotes("trade") end
            if root and w._coins then touchNamed(root, { "coin", "card", "pickup" }, w._range or 120) end
            if w._cEsp then highlightKeywords({ "coin", "card", "pack", "pickup" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Trading Cards", "Loaded.", 3, Color3.fromRGB(180, 180, 200))
    return w
end

--==============================================================================
--// ARCADE / MINIGAME HUB
--==============================================================================
local function ArcadeHub()
    local w = createWindow("Arcade / Minigames", "Auto-Play Suite", 460, 500, randPos())
    w:AddSection("Auto-Play")
    w:AddToggle("Auto Click Minigames", false, function(v) w._click = v end)
    w:AddSlider("Delay", 0.05, 1, 0.1, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Win (best-effort)", false, function(v) w._win = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Goal / Safe ESP", false, function(v) w._gEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            if w._click and tick() - last >= (w._delay or 0.1) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._win then fireRemotes("win"); fireRemotes("complete") end
            if w._gEsp then highlightKeywords({ "goal", "safe", "finish", "win", "coin", "button" }, Color3.fromRGB(76, 209, 142)) end
        end
    end)
    notify("Arcade / Minigames", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BATTLE ROYALE GENERIC
--==============================================================================
local function BattleRoyale()
    local w = buildFPSWindow("Battle Royale", Color3.fromRGB(180, 140, 80))
    w:AddSection("BR Extras")
    w:AddToggle("Auto Loot", false, function(v) w._loot = v end)
    w:AddSlider("Loot Range", 20, 300, 80, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Zone Alert (edge)", false, function(v) w._zone = v end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if root and w._loot then touchNamed(root, { "loot", "weapon", "ammo", "armor", "gun", "chest" }, w._range or 80) end
            if w._lEsp then highlightKeywords({ "loot", "weapon", "ammo", "armor", "gun", "chest", "crate" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    return w
end

--==============================================================================
--// BUILD / EDIT GAME (creative)
--==============================================================================
local function BuildGame()
    local w = createWindow("Build / Creative", "Builder Suite", 460, 520, randPos())
    w:AddSection("Build")
    w:AddToggle("Auto Place Blocks", false, function(v) w._place = v end)
    w:AddToggle("Auto Delete Blocks", false, function(v) w._del = v end)
    w:AddToggle("Infinite Build Materials", false, function(v) w._mats = v end)
    addMovement(w, 250, 400)
    w:AddSection("Fly")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._place then fireRemotes("place"); fireRemotes("build") end
            if w._del then fireRemotes("delete"); fireRemotes("remove") end
            if w._mats then fireRemotes("materials"); fireRemotes("add") end
        end
    end)
    notify("Build / Creative", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// SPACE / SCI-FI SURVIVAL
--==============================================================================
local function SpaceSurvival()
    local w = createWindow("Space Survival", "Sci-Fi Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Aliens", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Collect Oxygen/Fuel", false, function(v) w._oxy = v end)
    w:AddToggle("Auto Build Base", false, function(v) w._build = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Alien / Resource ESP", false, function(v) w._aEsp = v; if not v then clearAutoHL() end end)
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
                if w._oxy then touchNamed(root, { "oxygen", "fuel", "crystal", "resource" }, 120) end
                if w._build then fireRemotes("build") end
                if w._aEsp then highlightKeywords({ "alien", "enemy", "oxygen", "fuel", "crystal", "resource" }, Color3.fromRGB(120, 200, 255)) end
            end
        end
    end)
    notify("Space Survival", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// HIDE AND SEEK EXTREME
--==============================================================================
local function HideSeekExtreme()
    local w = createWindow("Hide & Seek Extreme", "Hide Suite", 460, 520, randPos())
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Seeker ESP (Red)", false, function(v) w._sEsp = v end)
    w:AddToggle("Hiding Spot ESP", false, function(v) w._hEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Survival")
    w:AddToggle("Auto Hide (find spot)", false, function(v) w._hide = v end)
    w:AddToggle("Seeker Alert", false, function(v) w._alert = v end)
    addMovement(w, 200, 400)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._hEsp then highlightKeywords({ "locker", "closet", "box", "hide", "bush" }, Color3.fromRGB(120, 200, 120)) end
            if root then
                if w._hide then
                    local best, bd = nil, 9999
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if (n:find("locker") or n:find("closet") or n:find("box")) and d:IsA("BasePart") then
                            local dist = (d.Position - root.Position).Magnitude
                            if dist < bd then bd = dist; best = d end
                        end
                    end
                    if best then pcall(function() root.CFrame = best.CFrame end) end
                end
                if w._alert or w._sEsp then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local killer = false
                            for _, t in ipairs(plr.Character:GetChildren()) do
                                if t:IsA("Tool") and (t.Name:lower():find("seek") or t.Name:lower():find("bat") or t.Name:lower():find("knife")) then killer = true end
                            end
                            if killer then
                                if w._sEsp then
                                    local hl = plr.Character:FindFirstChild("ESP_HL")
                                    if hl then hl.FillColor = Color3.fromRGB(255, 40, 50) end
                                end
                                if w._alert and plr.Character:FindFirstChild("HumanoidRootPart") then
                                    local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                                    if d < 40 and (not w._lw or tick() - w._lw > 5) then
                                        w._lw = tick()
                                        notify("âš  SEEKER", plr.Name .. " near!", 3, Theme.Red)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Hide & Seek Extreme", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// FACTORY / PRODUCTION TYCOON
--==============================================================================
local function FactoryTycoon()
    local w = createWindow("Factory Tycoon", "Production Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end)
    w:AddSlider("Range", 20, 600, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._buy = v end)
    w:AddToggle("Auto Produce", false, function(v) w._prod = v end)
    w:AddToggle("Auto Step on Buttons", false, function(v) w._btn = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Cash / Drop ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._cash then touchNamed(root, { "cash", "money", "drop", "coin", "pickup" }, w._range or 200) end
                if w._buy then fireRemotes("buy"); fireRemotes("upgrade") end
                if w._prod then fireRemotes("produce"); fireRemotes("craft") end
                if w._btn then touchNamed(root, { "button", "pad", "buy" }, 30) end
                if w._cEsp then highlightKeywords({ "cash", "money", "drop", "coin", "pickup" }, Color3.fromRGB(120, 220, 120)) end
            end
        end
    end)
    notify("Factory Tycoon", "Loaded.", 3, Color3.fromRGB(120, 180, 200))
    return w
end

--==============================================================================
--// MINECRAFT-LIKE SANDBOX (Bedwars-like creative)
--==============================================================================
local function BlockSandbox()
    local w = createWindow("Block Sandbox", "Mine & Build Suite", 470, 540, randPos())
    w:AddSection("Mining")
    w:AddToggle("Auto Mine (click)", false, function(v) w._mine = v end)
    w:AddToggle("Nuker (break around)", false, function(v) Nuker:Set(v) end)
    w:AddSection("Building")
    w:AddToggle("Auto Place Block", false, function(v) w._place = v end)
    w:AddToggle("Scaffold", false, function(v) Scaffold:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Ore / Block ESP", false, function(v) w._oEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._mine then swingTool() end
            if w._place then fireRemotes("place"); fireRemotes("build") end
            if w._oEsp then highlightKeywords({ "ore", "block", "diamond", "gold", "iron", "coal" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Block Sandbox", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// RACING / KART GAME
--==============================================================================
local function KartGame()
    local w = createWindow("Racing / Kart", "Drive Suite", 460, 500, randPos(460, 500))
    w:AddSection("Driving")
    w:AddToggle("Auto Accelerate", false, function(v) w._accel = v end)
    w:AddToggle("Infinite Boost", false, function(v) w._boost = v end)
    w:AddToggle("Auto Steer (center)", false, function(v) w._steer = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 800, 200, "studs", 0, function(v) w._range = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Checkpoint ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._accel then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end
            if w._boost then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); fireRemotes("boost") end
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "pickup" }, w._range or 200) end
                if w._cEsp then highlightKeywords({ "checkpoint", "finish", "lap", "flag" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Racing / Kart", "Loaded.", 3, Color3.fromRGB(255, 120, 80))
    return w
end

--==============================================================================
--// SOCIAL / HANGOUT GAME
--==============================================================================
local function SocialGame()
    local w = createWindow("Social / Hangout", "Social Suite", 460, 500, randPos(460, 500))
    w:AddSection("Social")
    w:AddToggle("Auto Chat", false, function(v) w._chat = v end)
    w:AddSlider("Interval", 5, 60, 15, "s", 0, function(v) w._interval = v end)
    w:AddInput("Message", "Hi! :)", "", function(v) w._msg = v end)
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Auto Dance (emote)", false, function(v) w._dance = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
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