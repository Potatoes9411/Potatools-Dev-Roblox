ar = "Fruit",      keywords = { "fruit" },                           icon = "ðŸ“", color = Color3.fromRGB(255,100,120) },
    { name = "Find the Cat Morphs",         singular = "Morph",      keywords = { "morph", "cat" },                    icon = "ðŸ˜º", color = Color3.fromRGB(150,200,255) },
    { name = "Find the Floppa Morphs",      singular = "Morph",      keywords = { "morph", "floppa", "caracal" },      icon = "ðŸˆâ€â¬›", color = Color3.fromRGB(200,150,100) },
    { name = "Find the Sonic Morphs",       singular = "Morph",      keywords = { "morph", "sonic", "hedgehog" },      icon = "ðŸ¦”", color = Color3.fromRGB(80,150,255) },
    { name = "Find the Rainbow Friends",    singular = "Morph",      keywords = { "morph", "rainbow", "friend" },      icon = "ðŸŒˆ", color = Color3.fromRGB(255,120,200) },
    { name = "Find the Piggy Morphs",       singular = "Morph",      keywords = { "morph", "piggy", "pig" },           icon = "ðŸ·", color = Color3.fromRGB(255,150,180) },
    { name = "Find the Among Us Morphs",    singular = "Morph",      keywords = { "morph", "among", "crewmate", "impostor" }, icon = "ðŸ‘¾", color = Color3.fromRGB(120,200,120) },
    { name = "Find the Smurfs",             singular = "Smurf",      keywords = { "smurf" },                           icon = "ðŸ§š", color = Color3.fromRGB(80,150,255) },
    { name = "Find the Nextbots",           singular = "Nextbot",    keywords = { "nextbot", "bot" },                  icon = "ðŸ‘¤", color = Color3.fromRGB(255,80,80) },
    { name = "Find the Alphabet Lore",      singular = "Letter",     keywords = { "letter", "alphabet" },              icon = "ðŸ”¤", color = Color3.fromRGB(255,200,80) },
    { name = "Find the Backrooms Morphs",   singular = "Morph",      keywords = { "morph", "backroom", "backrooms" },  icon = "ðŸŸ¨", color = Color3.fromRGB(220,220,120) },
    { name = "Find the Banban Morphs",      singular = "Morph",      keywords = { "morph", "banban", "garten" },       icon = "ðŸŸ¦", color = Color3.fromRGB(120,150,255) },
    { name = "Find the Animatronics",       singular = "Animatronic",keywords = { "animatronic", "robot" },            icon = "ðŸ¤–", color = Color3.fromRGB(180,180,200) },
    { name = "Find the Freddy Morphs",      singular = "Morph",      keywords = { "morph", "freddy", "fnaf" },         icon = "ðŸ»", color = Color3.fromRGB(170,120,60) },
    { name = "Find the Huggy Wuggys",       singular = "Huggy",      keywords = { "huggy", "wuggy" },                  icon = "ðŸ§¸", color = Color3.fromRGB(80,80,200) },
    { name = "Find the Poppys",             singular = "Poppy",      keywords = { "poppy", "playtime" },               icon = "ðŸŽª", color = Color3.fromRGB(255,80,160) },
    { name = "Find the Axolotls",           singular = "Axolotl",    keywords = { "axolotl" },                         icon = "ðŸ¦Ž", color = Color3.fromRGB(255,150,180) },
    { name = "Find the Ducks",              singular = "Duck",       keywords = { "duck", "ducky" },                   icon = "ðŸ¦†", color = Color3.fromRGB(255,220,80) },
    { name = "Find the Crabs",              singular = "Crab",       keywords = { "crab" },                            icon = "ðŸ¦€", color = Color3.fromRGB(255,120,80) },
    { name = "Find the Fish",               singular = "Fish",       keywords = { "fish" },                            icon = "ðŸŸ", color = Color3.fromRGB(100,180,230) },
    { name = "Find the Sharks",             singular = "Shark",      keywords = { "shark" },                           icon = "ðŸ¦ˆ", color = Color3.fromRGB(120,150,180) },
    { name = "Find the Penguins",           singular = "Penguin",    keywords = { "penguin" },                         icon = "ðŸ§", color = Color3.fromRGB(90,90,110) },
    { name = "Find the Frogs",              singular = "Frog",       keywords = { "frog", "toad" },                    icon = "ðŸ¸", color = Color3.fromRGB(120,200,90) },
    { name = "Find the Bees",               singular = "Bee",        keywords = { "bee" },                             icon = "ðŸ", color = Color3.fromRGB(255,210,60) },
    { name = "Find the Butterflies",        singular = "Butterfly",  keywords = { "butterfly" },                       icon = "ðŸ¦‹", color = Color3.fromRGB(255,150,220) },
    { name = "Find the Aliens",             singular = "Alien",      keywords = { "alien", "ufo" },                    icon = "ðŸ‘½", color = Color3.fromRGB(120,230,120) },
    { name = "Find the Grow-A-Garden Family", singular = "Plant",    keywords = { "grow", "garden", "plant", "seed" }, icon = "ðŸŒ±", color = Color3.fromRGB(120,200,100) },
    { name = "Find the Brainrots",           singular = "Brainrot", keywords = { "brainrot", "brain", "br" },       icon = "ðŸ§ ", color = Color3.fromRGB(200,80,120) },
    { name = "Find the Steal-a-Brainrot",    singular = "Spawner",  keywords = { "spawner", "brainrot", "steal" },     icon = "ðŸ¦´", color = Color3.fromRGB(180,120,120) },
    { name = "Find the Swing Obby Points",   singular = "Swing",    keywords = { "swing", "obby", "hook" },            icon = "ðŸª¢", color = Color3.fromRGB(200,160,90) },
    { name = "Find the Parkour For Brainrots", singular = "Checkpoint", keywords = { "parkour", "checkpoint", "brainrot" }, icon = "ðŸ", color = Color3.fromRGB(255,140,60) },
}

--==============================================================================
--// SETTINGS WINDOW
--==============================================================================
local function Settings()
    local w = createWindow("Settings", "Configuration & Utilities", 460, 580, randPos(460, 580))
    w:AddSection("Theme")
    local accents = {
        Purple = Theme.Accent, Blue = Color3.fromRGB(70, 150, 255), Green = Color3.fromRGB(76, 209, 142),
        Red = Color3.fromRGB(235, 77, 92), Yellow = Color3.fromRGB(245, 196, 76),
        Pink = Color3.fromRGB(255, 90, 180), Cyan = Color3.fromRGB(70, 220, 220), Orange = Color3.fromRGB(255, 140, 60),
    }
    w:AddDropdown("Accent Color", { "Purple", "Blue", "Green", "Red", "Yellow", "Pink", "Cyan", "Orange" }, "Purple", function(v)
        Theme.Accent = accents[v] or Theme.Accent
        Theme.AccentBright = Theme.Accent
        notify("Settings", "Accent set to " .. v .. " (applies to new windows).", 3)
    end)
    w:AddSection("Camera & World")
    w:AddToggle("Custom Camera FOV", false, function(v) CameraFOV.Enabled = v end)
    w:AddSlider("Field Of View", 50, 120, 70, "", 0, function(v) CameraFOV.Value = v end)
    w:AddToggle("Custom Gravity", false, function(v) Gravity.Enabled = v; if not v then Workspace.Gravity = 196.2 end end)
    w:AddSlider("Gravity", 0, 196, 60, "", 0, function(v) Gravity.Value = v end)
    w:AddToggle("Fullbright", false, function(v)
        if v then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 9e9 end
    end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSlider("Crosshair Size", 2, 40, 10, "", 0, function(v) Crosshair.Size = v end)
    w:AddSlider("Crosshair Gap", 0, 30, 4, "", 0, function(v) Crosshair.Gap = v end)
    w:AddButton("Reset Gravity", function() Workspace.Gravity = 196.2; Gravity.Enabled = false end)
    w:AddButton("Clear All ESP / Highlights", function() clearAutoHL(); notify("Settings", "Cleared highlights.", 2) end)
    w:AddSection("Safety")
    w:AddButton("PANIC: Disable Everything", function()
        disableAllFeatures()
        setCrosshair(false); setAntiAFK(false)
        CameraFOV.Enabled = false; Gravity.Enabled = false; Workspace.Gravity = 196.2
        clearAutoHL()
    end, Theme.Red)
    w:AddSection("Config (save / load)")
    w:AddButton("Save Current Settings", function()
        ConfigStore.save(ConfigStore.gather())
        notify("Settings", "Config saved to " .. CFG_FILE, 3, Theme.Green)
    end, Theme.Green)
    w:AddButton("Load Saved Settings", function()
        local snap = ConfigStore.load()
        ConfigStore.apply(snap)
        notify("Settings", "Config loaded (" .. (snap and snap.Modules and "ok" or "empty") .. ").", 3)
    end)
    w:AddButton("Reset Saved Config", function()
        pcall(function() if writefile then writefile(CFG_FILE, "{}") end end)
        notify("Settings", "Saved config reset.", 3, Theme.Yellow)
    end, Theme.Yellow)
    w:AddSection("Keybinds & Info")
    w:AddLabel("RightCtrl   ->  toggle hub")
    w:AddLabel("RightShift  ->  panic disable")
    w:AddLabel("Delete      ->  panic disable")
    w:AddLabel("Drag any window by its title bar")
    w:AddLabel("Each game opens its own separate window")
    w:AddSection("About")
    w:AddLabel("Multi-Game Hub  |  Studio Test Suite")
    w:AddLabel("Built for testing your own game copies.")
    return w
end

--==============================================================================
--// DOORS
--==============================================================================
local function Doors()
    local w = createWindow("Doors", "Entity & Exploration Suite", 470, 560, randPos())
    w:AddSection("Entity ESP")
    w:AddToggle("Entity ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end, "Highlight Rush / Ambush / Seek / etc.")
    w:AddToggle("Entity Alert", false, function(v) w._eAlert = v end)
    w:AddToggle("Item / Gold ESP", false, function(v) w._gEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Items", false, function(v) w._autoItem = v end)
    w:AddToggle("Auto Hide (closet, entity near)", false, function(v) w._hide = v end)
    w:AddSection("Skip")
    w:AddButton("Skip Forward 60 studs", function()
        local r = getRoot(); if r then r.CFrame = r.CFrame + Camera.CFrame.LookVector * 60 end
    end)
    w:AddButton("Touch All Wardrobes", function()
        touchNamed(getRoot(), { "wardrobe", "closet", "bed" }, 9999)
    end)
    addMovement(w, 120, 200)
    local entKeys = { "rush", "ambush", "screech", "halt", "seek", "figure", "dupe", "jack", "eyes", "blitz", "lookman", "froglin", "dread", "glitch", "void" }
    local itemKeys = { "gold", "key", "lighter", "lockpick", "vitamin", "bandage", "battery", "candle", "shears", "flashlight", "crucifix", "coin", "radio" }
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._eEsp then highlightKeywords(entKeys, Color3.fromRGB(255, 40, 50)) end
            if w._gEsp then highlightKeywords(itemKeys, Color3.fromRGB(255, 200, 40)) end
            local root = getRoot()
            if root then
                if w._autoItem then touchNamed(root, { "gold", "key", "lighter", "bandage", "battery", "coin" }, 45) end
                if w._eAlert then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("rush") or n:find("ambush") or n:find("screech") or n:find("figure") or n:find("seek") or n:find("blitz") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p and (p.Position - root.Position).Magnitude < 90 then
                                if not w._lw or tick() - w._lw > 6 then
                                    w._lw = tick()
                                    notify("ENTITY NEAR", tostring(d.Name), 3, Theme.Red)
                                end
                            end
                        end
                    end
                end
                if w._hide then
                    local best, bd = nil, 250
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("wardrobe") or n:find("closet") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p then
                                local dist = (p.Position - root.Position).Magnitude
                                if dist < bd then bd = dist; best = p end
                            end
                        end
                    end
                    if best then pcall(function() root.CFrame = best.CFrame end) end
                end
            end
        end
    end)
    notify("Doors", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// BLOX FRUITS
--==============================================================================
local function BloxFruits()
    local w = createWindow("Blox Fruits", "Grind Suite", 480, 580, randPos(480, 580))
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest NPC", false, function(v) w._farm = v end)
    w:AddToggle("Bring NPC to You", false, function(v) w._bring = v end)
    w:AddToggle("Fast Attack Spam", false, function(v) w._fast = v end)
    w:AddSlider("Attack Range", 5, 300, 35, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Infinite Energy (best-effort)", false, function(v) w._infEnergy = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Fruit / Chest ESP", false, function(v) w._fruitEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Auto")
    w:AddToggle("Auto Buy Fruit", false, function(v) w._autoBuy = v end)
    w:AddToggle("Auto Store Fruit", false, function(v) w._autoStore = v end)
    addMovement(w, 200, 300)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm or w._bring or w._fast then
                    local npc, dist = getNearestNPC(99999)
                    if npc then
                        local hrp = npc:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            if w._bring then
                                pcall(function() hrp.CFrame = root.CFrame * CFrame.new(0, 0, -4) end)
                            elseif w._farm and dist > (w._range or 35) then
                                pcall(function()
                                    local dir = hrp.Position - root.Position
                                    root.CFrame = root.CFrame + dir.Unit * math.min(dir.Magnitude - (w._range or 35), 25)
                                end)
                            end
                            if w._farm or w._fast then
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
                if w._infEnergy then trySetStat("energy", 1e9); trySetStat("stamina", 1e9) end
                if w._fruitEsp then highlightKeywords({ "fruit", "devil", "chest", "treasure" }, Color3.fromRGB(120, 200, 255)) end
                if w._autoBuy then fireRemotes("buyfruit") end
                if w._autoStore then fireRemotes("store") end
            end
        end
    end)
    notify("Blox Fruits", "Loaded.", 3, Theme.Blue)
    return w
end

--==============================================================================
--// PET SIMULATOR 99
--==============================================================================
local function PetSim99()
    local w = createWindow("Pet Simulator 99", "Coin & Egg Suite", 470, 560, randPos())
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Coin Range", 20, 600, 150, "studs", 0, function(v) w._crange = v end)
    w:AddToggle("Auto Open Eggs", false, function(v) w._eggs = v end)
    w:AddToggle("Auto Hatch Pets", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Claim Gifts", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Coin / Egg ESP", false, function(v) w._esp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    addMovement(w, 200, 300)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            if root then
                if w._coins then
                    local range = w._crange or 150
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        local n = d.Name:lower()
                        if n:find("coin") or n:find("pickup") or n:find("gem") or n:find("money") then
                            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if p and (p.Position - root.Position).Magnitude < range then
                                pcall(function() firetouchinterest(root, p, 0) end)
                            end
                        end
                    end
                end
                if w._esp then highlightKeywords({ "coin", "egg", "gem", "gift", "chest", "loot" }, Color3.fromRGB(255, 200, 40)) end
                if w._eggs then fireRemotes("hatch") end
                if w._hatch then fireRemotes("open") end
                if w._sell then fireRemotes("sell") end
                if w._claim then fireRemotes("claim") end
            end
        end
    end)
    notify("Pet Simulator 99", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// EVADE
--==============================================================================
local function Evade()
    local w = createWindow("Evade", "Nextbot Survival Suite", 470, 540, randPos())
    w:AddSection("Nextbots")
    w:AddToggle("Nextbot ESP (Red)", false, function(v) w._nEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Avoid (run away)", false, function(v) w._avoid = v end)
    w:AddToggle("Nextbot Alert", false, function(v) w._alert = v end)
    w:AddSlider("Safe Distance", 15, 300, 70, "studs", 0, function(v) w._safe = v end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Stamina")
    w:AddToggle("Infinite Stamina (best-effort)", false, function(v) w._stam = v end)
    addMovement(w, 200, 350)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                local npc, dist = getNearestNPC(99999)
                if w._nEsp then highlightKeywords({ "nextbot", "bot", "killer", "enemy", "npc" }, Color3.fromRGB(255, 40, 50)) end
                if npc and npc:FindFirstChild("HumanoidRootPart") then
                    local npos = npc.HumanoidRootPart.Position
                    if w._avoid and dist < (w._safe or 70) then
                        local dir = root.Position - npos
                        if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 12 end) end
                    end
                    if w._alert and dist < (w._safe or 70) then
                        if not w._lw or tick() - w._lw > 5 then
                            w._lw = tick()
                            notify("NEXTBOT", npc.Name .. " (" .. math.floor(dist) .. "m)", 3, Theme.Red)
                        end
                    end
                end
                if w._stam then trySetStat("stamina", 1e9); trySetStat("energy", 1e9) end
                if w._revive and not isAlive() then
                    fireRemotes("revive"); fireRemotes("respawn")
                    task.wait(1)
                end
            end
        end
    end)
    notify("Evade", "Loaded.", 3, Theme.Red)
    return w
end

--==============================================================================
--// BROOKHAVEN
--==============================================================================
local function Brookhaven()
    local w = createWindow("Brookhaven", "RP Utility Suite", 470, 540, randPos())
    w:AddSection("Player")
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("House ESP", false, function(v) w._hEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Give Weapons (best-effort)", function()
        local n = fireRemotes("give"); fireRemotes("weapon"); fireRemotes("tool")
        notify("Brookhaven", "Fired give remotes (" .. n .. ").", 3)
    end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    w:AddSection("Teleport")
    local houses = { { "Spawn", Vector3.new(0, 5, 0) }, { "Hospital", Vector3.new(120, 5, 40) }, { "School", Vector3.new(-100, 5, 90) }, { "Gas Station", Vector3.new(80, 5, -120) }, { "Pool", Vector3.new(-150, 5, -60) } }
    for _, h in ipairs(houses) do w:AddButton("TP: " .. h[1], function() teleportTo(h[2]) end) end
    task.spawn(function()
        while true do
            task.wait(1)
            if w._hEsp then highlightKeywords({ "house", "door", "garage" }, Color3.fromRGB(120, 200, 255)) end
        end
    end)
    notify("Brookhaven", "Loaded.", 3, Color3.fromRGB(255, 90, 180))
    return w
end

--==============================================================================
--// ADOPT ME
--==============================================================================
local function AdoptMe()
    local w = createWindow("Adopt Me", "Pet Care Suite", 470, 540, randPos())
    w:AddSection("Auto Pet Care")
    w:AddToggle("Auto Feed", false, function(v) w._feed = v end)
    w:AddToggle("Auto Drink", false, function(v) w._drink = v end)
    w:AddToggle("Auto Play / Shower", false, function(v) w._play = v end)
    w:AddToggle("Auto Sleep", false, function(v) w._sleep = v end)
    w:AddToggle("Auto Age Up", false, function(v) w._age = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    addMovement(w, 200, 350)
    w:AddSection("Teleport")
    w:AddButton("TP: Nursery", function() teleportTo(Vector3.new(0, 5, 0)) end)
    w:AddButton("TP: School", function() teleportTo(Vector3.new(120, 5, 40)) end)
    w:AddButton("TP: Playground", function() teleportTo(Vector3.new(-80, 5, -40)) end)
    task.spawn(function()
        while true do
            task.wait(0.6)
            if w._feed then fireRemotes("feed") end
            if w._drink then fireRemotes("drink") end
            if w._play then fireRemotes("play"); fireRemotes("shower") end
            if w._sleep then fireRemotes("sleep") end
            if w._age then fireRemotes("ageup"); fireRemotes("age") end
        end
    end)
    notify("Adopt Me", "Loaded.", 3, Color3.fromRGB(255, 120, 180))
    return w
end

--==============================================================================
--// TOWER DEFENSE SIMULATOR
--==============================================================================
local function TowerDefenseSim()
    local w = createWindow("Tower Defense Simulator", "Auto-Play Suite", 470, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Upgrade Selected", false, function(v) w._up = v end)
    w:AddToggle("Auto Start Next Wave", false, function(v) w._wave = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Skip Cutscenes", false, function(v) w._skip = v end)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    addMovement(w, 150, 250)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._up then fireRemotes("upgrade") end
            if w._wave then fireRemotes("start"); fireRemotes("nextwave"); fireRemotes("wavestart") end
            if w._equip then fireRemotes("equip") end
            if w._skip then fireRemotes("skip") end
            if w._eEsp then highlightKeywords({ "enemy", "mob", "zombie", "boss" }, Color3.fromRGB(255, 60, 60)) end
        end
    end)
    notify("Tower Defense Sim", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// DEAD RAILS
--==============================================================================
local function DeadRails()
    local w = createWindow("Dead Rails", "Loot & Travel Suite", 470, 540, randPos())
    w:AddSection("Loot")
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Loot Nearby", false, function(v) w._loot = v end)
    w:AddSlider("Loot Range", 10, 400, 120, "studs", 0, function(v) w._lrange = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._lEsp then highlightKeywords({ "gold", "bond", "ammo", "coal", "loot", "treasure", "safe" }, Color3.fromRGB(255, 200, 40)) end
            if w._eEsp then highlightKeywords({ "enemy", "zombie", "vampire", "bandit", "boss" }, Color3.fromRGB(255, 40, 50)) end
            if w._loot and root then
                local range = w._lrange or 120
                touchNamed(root, { "gold", "bond", "ammo", "coal", "loot", "treasure" }, range)
            end
        end
    end)
    notify("Dead Rails", "Loaded.", 3, Color3.fromRGB(180, 140, 80))
    return w
end

--==============================================================================
--// STEEP STEPS
--==============================================================================
local function SteepSteps()
    local w = createWindow("Steep Steps", "Climb Suite", 450, 520, randPos(450, 520))
    w:AddSection("Climb")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddButton("Teleport UP 300", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 300, 0) end end)
    w:AddSection("Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    notify("Steep Steps", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// BUILD A BOAT
--==============================================================================
local function BuildABoat()
    local w = createWindow("Build A Boat", "Sail Suite", 460, 520, randPos(460, 520))
    w:AddSection("Boat / Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 500, 120, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddSection("Resources")
    w:AddToggle("Auto Collect Materials", false, function(v) w._mats = v end)
    w:AddSlider("Collect Range", 20, 500, 150, "studs", 0, function(v) w._mrange = v end)
    w:AddToggle("Material ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._mEsp then highlightKeywords({ "block", "wood", "material", "treasure", "gold" }, Color3.fromRGB(120, 200, 120)) end
            if w._mats and root then touchNamed(root, { "material", "block", "gold", "treasure" }, w._mrange or 150) end
        end
    end)
    notify("Build A Boat", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// PILOT TRAINING FLIGHT SIM
--==============================================================================
local function PilotTraining()
    local w = createWindow("Pilot Training Flight Sim", "Travel Suite", 470, 540, randPos())
    w:AddSection("Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 600, 150, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSection("Teleport - Airports")
    local ap = { { "Default Airport", Vector3.new(0, 50, 0) }, { "Sky City", Vector3.new(2000, 300, 2000) }, { "Mountain Base", Vector3.new(-3000, 400, -1500) }, { "Coast", Vector3.new(4000, 50, 1000) }, { "Desert", Vector3.new(-2000, 80, 3000) } }
    for _, a in ipairs(ap) do w:AddButton("TP: " .. a[1], function() teleportTo(a[2]) end) end
    w:AddSection("Visuals")
    w:AddToggle("Airport ESP", false, function(v) w._aEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(1)
            if w._aEsp then highlightKeywords({ "airport", "runway", "tower", "hangar", "spawn" }, Color3.fromRGB(86, 156, 240)) end
        end
    end)
    notify("Pilot Training", "Loaded.", 3, Theme.Blue)
    return w
end

--==============================================================================
--// ANIME ADVENTURES
--==============================================================================
local function AnimeAdventures()
    local w = createWindow("Anime Adventures", "Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest Enemy", false, function(v) w._farm = v end)
    w:AddToggle("Auto Use Skills", false, function(v) w._skills = v end)
    w:AddSlider("Farm Range", 10, 400, 40, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Upgrade Units", false, function(v) w._up = v end)
    w:AddToggle("Auto Skip", false, function(v) w._skip = v end)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    addMovement(w, 200, 350)
    task.spawn(function()
        while true do
            task.wait(0.25)
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
            if w._skills then fireRemotes("skill"); fireRemotes("attack") end
            if w._up then fireRemotes("upgrade") end
            if w._skip then fireRemotes("skip") end
            if w._eEsp then highlightKeywords({ "enemy", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
        end
    end)
    notify("Anime Adventures", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// NINJA LEGENDS
--==============================================================================
local function NinjaLegends()
    local w = createWindow("Ninja Legends", "Train & Sell Suite", 470, 540, randPos())
    w:AddSection("Auto Train")
    w:AddToggle("Auto Swing", false, function(v) w._swing = v end)
    w:AddSlider("Swing Delay", 0.05, 1, 0.15, "s", 2, function(v) w._sdelay = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Belts/Swords", false, function(v) w._buy = v end)
    w:AddToggle("Auto Buy Shards", false, function(v) w._shard = v end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin / Chest ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Teleport")
    local isls = { { "Spawn Island", Vector3.new(0, 50, 0) }, { "First Island", Vector3.new(0, 200, 2000) }, { "Mystic Island", Vector3.new(0, 400, 5000) } }
    for _, i in ipairs(isls) do w:AddButton("TP: " .. i[1], function() teleportTo(i[2]) end) end
    local lastSwing = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            if w._swing and tick() - lastSwing >= (w._sdelay or 0.15) then
                lastSwing = tick()
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._sell then fireRemotes("sell"); fireRemotes("selly") end
            if w._buy then fireRemotes("buybelt"); fireRemotes("buysword") end
            if w._shard then fireRemotes("buyshard") end
            if w._cEsp then highlightKeywords({ "coin", "chest", "crate", "gem", "orb" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Ninja Legends", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// MINING SIMULATOR
--==============================================================================
local function MiningSimulator()
    local w = createWindow("Mining Simulator", "Dig & Sell Suite", 470, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Mine (click)", false, function(v) w._mine = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Pickaxes", false, function(v) w._buy = v end)
    w:AddToggle("Auto Hatch Pets", false, function(v) w._hatch = v end)
    w:AddSection("Visuals")
    w:AddToggle("Ore / Block ESP", false, function(v) w._oEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    addMovement(w, 200, 300)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._mine then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._sell then fireRemotes("sell") end
            if w._buy then fireRemotes("buy") end
            if w._hatch then fireRemotes("hatch"); fireRemotes("egg") end
            if w._oEsp then highlightKeywords({ "ore", "block", "diamond", "gold", "gem", "crate" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Mining Simulator", "Loaded.", 3, Color3.fromRGB(180, 140, 80))
    return w
end

--==============================================================================
--// SLAP BATTLES
--==============================================================================
local function SlapBattles()
    local w = createWindow("Slap Battles", "Slap Suite", 450, 500, randPos(450, 500))
    w:AddSection("Slap")
    w:AddToggle("Auto Slap", false, function(v) w._slap = v end)
    w:AddSlider("Slap Delay", 0.1, 2, 0.5, "s", 2, function(v) w._sdelay = v end)
    w:AddToggle("Slap Aura (radius)", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 5, 80, 20, "studs", 0, function(v) w._arange = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            local root = getRoot()
            if w._slap and tick() - last >= (w._sdelay or 0.5) then
                last = tick()
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._aura and root then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d <= (w._arange or 20) then
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
    notify("Slap Battles", "Loaded.", 3, Theme.Yellow)
    return w
end

--==============================================================================
--// SURVIVE THE KILLER
--==============================================================================
local function SurviveTheKiller()
    local w = createWindow("Survive the Killer", "Survival Suite", 470, 540, randPos())
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Killer ESP (Red)", false, function(v) w._kEsp = v end)
    w:AddToggle("Killer Alert", false, function(v) w._alert = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Avoid Killer", false, function(v) w._avoid = v end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    w:AddSlider("Safe Distance", 20, 300, 80, "studs", 0, function(v) w._safe = v end)
    addMovement(w, 200, 350)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            local killer, kdist = getNearestNPC(99999)
            if root and killer and killer:FindFirstChild("HumanoidRootPart") then
                local kpos = killer.HumanoidRootPart.Position
                if w._kEsp and not killer:GetAttribute(HL_TAG) then
                    killer:SetAttribute(HL_TAG, true)
                    local hl = Instance.new("Highlight")
                    hl.Name = HL_TAG
                    hl.FillColor = Color3.fromRGB(255, 40, 50)
                    hl.FillTransparency = 0.4
                    hl.Parent = killer
                end
                if w._avoid and kdist < (w._safe or 80) then
                    local dir = root.Position - kpos
                    if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 12 end) end
                end
                if w._alert and kdist < (w._safe or 80) then
                    if not w._lw or tick() - w._lw > 5 then
                        w._lw = tick()
                        notify("KILLER", killer.Name .. " (" .. math.floor(kdist) .. "m)", 3, Theme.Red)
                    end
                end
            end
            if w._revive and not isAlive() then fireRemotes("revive"); task.wait(1) end
        end
    end)
    notify("Survive the Killer", "Loaded.", 3, Theme.Red)
    return w
end

--==============================================================================
--// ROYALE HIGH
--==============================================================================
local function RoyaleHigh()
    local w = createWindow("Royale High", "Campus Suite", 470, 520, randPos())
    w:AddSection("Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 80, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddSection("Teleport")
    local loc = { { "Spawn", Vector3.new(0, 50, 0) }, { "Dance Class", Vector3.new(50, 10, 80) }, { "Dorms", Vector3.new(-120, 10, -40) }, { "Cafeteria", Vector3.new(90, 10, 40) } }
    for _, l in ipairs(loc) do w:AddButton("TP: " .. l[1], function() teleportTo(l[2]) end) end
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Diamond ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.8)
            if w._dEsp then highlightKeywords({ "diamond", "gem", "coin", "orb" }, Color3.fromRGB(120, 200, 255)) end
        end
    end)
    notify("Royale High", "Loaded.", 3, Color3.fromRGB(255, 120, 180))
    return w
end

--==============================================================================
--// FPS WRAPPERS  (same combat suite as Arsenal/Rivals)
--==============================================================================
local function BigPaintball()
    local w = buildFPSWindow("Big Paintball", Color3.fromRGB(120, 200, 255))
    w:AddSection("Paintball Extras")
    w:AddToggle("No Paint Splatter (clean)", false, function(v)
        if v then Lighting.FogEnd = 9e9 end
    end)
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end
local function PhantomForces()
    local w = buildFPSWindow("Phantom Forces", Color3.fromRGB(110, 110, 130))
    w:AddSection("PF Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end
local function Frontlines()
    local w = buildFPSWindow("Frontlines", Color3.fromRGB(200, 120, 60))
    w:AddSection("Frontlines Extras")
    w:AddToggle("Silent Aim", false, function(v) SilentAim:Set(v) end)
    w:AddToggle("Infinite Ammo (best-effort)", false, function(v) InfiniteAmmo:Set(v) end)
    w:AddToggle("No Recoil", false, function(v) NoSpread:Set(v) end)
    w:AddToggle("Auto Reload", false, function(v) AutoReload:Set(v) end)
    w:AddToggle("Bunny Hop", false, function(v) BunnyHop:Set(v) end)
    w:AddToggle("Aim Assist", false, function(v) AimAssist:Set(v) end)
    w:AddToggle("Wallbang", false, function(v) Wallbang:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    return w
end

--==============================================================================
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
    w:AddToggle