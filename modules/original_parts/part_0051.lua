f w._revive then fireRemotes("revive"); fireRemotes("rescue") end
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
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.B, false, game)
                end)
            end
        end
    end)
    notify("Social / Hangout", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// CAMERA & VISUAL SUITE
--==============================================================================
local function CameraSuite()
    local w = createWindow("Camera Suite", "Camera & visuals", 460, 560, randPos(460, 560))
    w:AddSection("Field of View")
    w:AddToggle("Custom FOV", false, function(v) CameraFOV.Enabled = v end, "Set a custom camera FOV")
    w:AddSlider("FOV Value", 50, 120, 90, "", 0, function(v) CameraFOV.Value = v end)
    w:AddSection("Lighting")
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end, "Max brightness")
    w:AddToggle("Atmosphere FX", false, function(v) AtmosphereMod:Set(v) end, "Bloom/CC/SunRays")
    w:AddToggle("Time Changer", false, function(v) TimeChanger:Set(v) end)
    w:AddSlider("Time (hour)", 0, 24, 12, ":00", 0, function(v)
        TimeChanger.Value = math.floor(v)
        if TimeChanger.Enabled then Lighting.TimeOfDay = string.format("%02d:00:00", TimeChanger.Value) end
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
    w:AddButton