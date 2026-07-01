local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        state.found = findScan(keywords)
        state.labelMap = {}
        state.options = {}
        for _, r in ipairs(state.found) do
            state.labelMap[r.label] = r.part
            table.insert(state.options, r.label)
        end
        state.lastCount = #state.found
        notify(cfg.name, "Scan complete: found " .. #state.found .. " object(s).", 4, color)
        refreshESP()
        return state.options
    end

    -- Section: Scan
    w:AddSection("Scan / ESP")
    w:AddButton("Scan for " .. cfg.singular, function()
        doScan()
    end, color)
    w:AddToggle("ESP (highlight all)", false, function(v)
        state.espOn = v
        if v and #state.found == 0 then doScan() end
        refreshESP()
        if not v then
            for _, h in ipairs(state.bringESP) do pcall(function() h:Destroy() end) end
            state.bringESP = {}
        end
    end, "Highlight every found object")
    w:AddToggle("Auto Re-Scan (refresh ESP)", false, function(v) state.autoScan = v end)

    -- Section: Selection
    w:AddSection("Selection")
    local dd = w:AddDropdown("Found Objects", state.options, (state.options[1] or "Scan first"), function(v)
        state.selected = v
    end)
    w._findDD = dd
    w:AddButton("Re-Scan", function()
        doScan()
        if dd and dd.Refresh then
            -- our dropdown is a custom obj; rebuild not supported, so notify
        end
    end)
    w:AddButton("Teleport To Selected", function()
        local part = state.labelMap[state.selected or ""]
        local root = getRoot()
        if part and part.Parent and root then
            root.CFrame = part.CFrame + Vector3.new(0, 4, 0)
            pcall(function() firetouchinterest(root, part, 0) end)
            notify(cfg.name, "Teleported to " .. state.selected, 2.5, color)
        else
            notify(cfg.name, "Re-scan first (object may be gone).", 2.5, Theme.Red)
        end
    end, color)
    w:AddButton("Bring Selected Here", function()
        local part = state.labelMap[state.selected or ""]
        local root = getRoot()
        if part and part.Parent and root then
            pcall(function() part.CFrame = root.CFrame end)
            notify(cfg.name, "Brought " .. state.selected, 2.5, color)
        else
            notify(cfg.name, "Re-scan first.", 2.5, Theme.Red)
        end
    end)
    w:AddButton("Teleport To Nearest", function()
        local root = getRoot()
        if not root then return end
        local best, bd = nil, math.huge
        for _, r in ipairs(state.found) do
            if r.part and r.part.Parent then
                local d = (r.part.Position - root.Position).Magnitude
                if d < bd then bd = d; best = r end
            end
        end
        if best then
            root.CFrame = best.part.CFrame + Vector3.new(0, 4, 0)
            notify(cfg.name, "Nearest: " .. best.label .. " (" .. math.floor(bd) .. "m)", 3, color)
        else
            notify(cfg.name, "Nothing found - scan first.", 2.5, Theme.Red)
        end
    end)

    -- Section: Collect
    w:AddSection("Collect All")
    w:AddButton("Bring All To Me", function()
        local root = getRoot()
        if not root then return end
        if #state.found == 0 then doScan() end
        local count = 0
        for _, r in ipairs(state.found) do
            if r.part and r.part.Parent then
                pcall(function() r.part.CFrame = root.CFrame end)
                count = count + 1
            end
        end
        notify(cfg.name, "Brought " .. count .. " object(s) to you.", 4, color)
    end, color)
    w:AddButton("Visit Each (collect loop x1)", function()
        local root = getRoot()
        if not root then return end
        if #state.found == 0 then doScan() end
        task.spawn(function()
            for _, r in ipairs(state.found) do
                if r.part and r.part.Parent then
                    pcall(function()
                        root.CFrame = r.part.CFrame + Vector3.new(0, 4, 0)
                        firetouchinterest(root, r.part, 0)
                    end)
                    task.wait(0.2)
                end
            end
            notify(cfg.name, "Visited all objects.", 3, color)
        end)
    end)
    w:AddToggle("Auto-Collect Loop", false, function(v)
        state.autoCollect = v
        if v and #state.found == 0 then doScan() end
    end, "Continuously visit every object")
    w:AddSlider("Auto Delay", 0.05, 3, 0.3, "s", 2, function(v) state.autoDelay = v end)

    -- Section: Movement
    addMovement(w, 200, 400)

    -- Section: Visuals
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    -- Section: Info
    w:AddSection("Info")
    w:AddLabel("Keywords used: " .. table.concat(keywords, ", "))
    w:AddLabel("Last scan found: dynamic (re-scan to refresh)")

    -- Background loops
    task.spawn(function()
        while true do
            task.wait(state.autoDelay > 0 and state.autoDelay or 0.3)
            -- auto re-scan refresh of ESP
            if state.autoScan then
                local opts = doScan()
            end
            -- auto collect
            if state.autoCollect and isAlive() then
                local root = getRoot()
                if root and #state.found > 0 then
                    -- pick next target round-robin
                    local target = nil
                    for i = 1, #state.found do
                        local idx = ((state.autoIndex - 1 + i) % #state.found) + 1
                        local r = state.found[idx]
                        if r.part and r.part.Parent then
                            target = r
                            state.autoIndex = idx + 1
                            break
                        end
                    end
                    if target then
                        pcall(function()
                            root.CFrame = target.part.CFrame + Vector3.new(0, 4, 0)
                            firetouchinterest(root, target.part, 0)
                        end)
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    notify(cfg.name, "Loaded. Click 'Scan' to find objects.", 4, color)
    return w
end

-- Master data table for all "Find the" games. Each entry has a singular noun,
-- the search keywords, an icon and a color. One generic builder powers all of them.
local FindTheGames = {
    { name = "Find the Markers",            singular = "Marker",     keywords = { "marker", "badge" },                icon = "ðŸ–ï¸", color = Color3.fromRGB(255,80,120) },
    { name = "Find the Chomiks",            singular = "Chomik",     keywords = { "chomik", "chom" },                  icon = "ðŸŸ¡", color = Color3.fromRGB(255,210,60) },
    { name = "Find the Doggos",             singular = "Doggo",      keywords = { "doggo", "dog" },                    icon = "ðŸ¶", color = Color3.fromRGB(180,140,90) },
    { name = "Find the Kittens",            singular = "Kitten",     keywords = { "kitten", "cat" },                   icon = "ðŸ±", color = Color3.fromRGB(150,200,255) },
    { name = "Find the Stickmen",           singular = "Stickman",   keywords = { "stickman", "stick" },               icon = "ðŸ§", color = Color3.fromRGB(200,200,210) },
    { name = "Find the Bananas",            singular = "Banana",     keywords = { "banana" },                          icon = "ðŸŒ", color = Color3.fromRGB(255,220,70) },
    { name = "Find the Cornbreads",         singular = "Cornbread",  keywords = { "cornbread", "bread" },              icon = "ðŸž", color = Color3.fromRGB(220,180,120) },
    { name = "Find the Plugs",              singular = "Plug",       keywords = { "plug" },                            icon = "ðŸ”Œ", color = Color3.fromRGB(255,200,80) },
    { name = "Find the Peppers",            singular = "Pepper",     keywords = { "pepper", "chili" },                 icon = "ðŸŒ¶ï¸", color = Color3.fromRGB(235,60,60) },
    { name = "Find the Faces",              singular = "Face",       keywords = { "face" },                            icon = "ðŸ˜€", color = Color3.fromRGB(255,210,80) },
    { name = "Find the Epic Faces",         singular = "Epic Face",  keywords = { "epicface", "epic", "face" },        icon = "ðŸ˜Ž", color = Color3.fromRGB(120,220,120) },
    { name = "Find the Memes",              singular = "Meme",       keywords = { "meme" },                            icon = "ðŸ¤£", color = Color3.fromRGB(255,180,120) },
    { name = "Find the Noobs",              singular = "Noob",       keywords = { "noob" },                            icon = "ðŸŸ¢", color = Color3.fromRGB(120,210,90) },
    { name = "Find the Blooks",             singular = "Blook",      keywords = { "blook" },                           icon = "ðŸŸ¦", color = Color3.fromRGB(120,180,255) },
    { name = "Find the Bacons",             singular = "Bacon",      keywords = { "bacon" },                           icon = "ðŸ¥“", color = Color3.fromRGB(220,120,90) },
    { name = "Find the Pandas",             singular = "Panda",      keywords = { "panda" },                           icon = "ðŸ¼", color = Color3.fromRGB(220,220,225) },
    { name = "Find the Bears",              singular = "Bear",       keywords = { "bear" },                            icon = "ðŸ»", color = Color3.fromRGB(170,120,80) },
    { name = "Find the Pugs",               singular = "Pug",        keywords = { "pug" },                             icon = "ðŸ•", color = Color3.fromRGB(220,180,140) },
    { name = "Find the Bunnies",            singular = "Bunny",      keywords = { "bunny", "rabbit" },                 icon = "ðŸ°", color = Color3.fromRGB(255,200,220) },
    { name = "Find the Rocks",              singular = "Rock",       keywords = { "rock", "stone" },                   icon = "ðŸª¨", color = Color3.fromRGB(160,160,170) },
    { name = "Find the Cookies",            singular = "Cookie",     keywords = { "cookie" },                          icon = "ðŸª", color = Color3.fromRGB(200,150,90) },
    { name = "Find the Scissors",           singular = "Scissors",   keywords = { "scissor", "scissors" },             icon = "âœ‚ï¸", color = Color3.fromRGB(180,180,200) },
    { name = "Find the Impostors",          singular = "Impostor",   keywords = { "impostor", "imposter", "sus" },     icon = "ðŸŸ¥", color = Color3.fromRGB(235,60,60) },
    { name = "Find the Superheroes",        singular = "Hero",       keywords = { "hero", "superhero" },               icon = "ðŸ¦¸", color = Color3.fromRGB(80,150,255) },
    { name = "Find the Shows",              singular = "Show",       keywords = { "show" },                            icon = "ðŸ“º", color = Color3.fromRGB(120,180,255) },
    { name = "Find the Games",              singular = "Game",       keywords = { "game" },                            icon = "ðŸŽ®", color = Color3.fromRGB(180,120,255) },
    { name = "Find the Gubbys",             singular = "Gubby",      keywords = { "gubby", "gub" },                    icon = "ðŸŸ£", color = Color3.fromRGB(180,120,255) },
    { name = "Find the Pou Poos",           singular = "Pou Poo",    keywords = { "pou", "poo" },                      icon = "ðŸ’©", color = Color3.fromRGB(150,110,70) },
    { name = "Find the Mochi",              singular = "Mochi",      keywords = { "mochi" },                           icon = "ðŸ¡", color = Color3.fromRGB(255,180,200) },
    { name = "Find the Binguses",           singular = "Bingus",     keywords = { "bingus", "bing" },                  icon = "ðŸˆ", color = Color3.fromRGB(255,220,180) },
    { name = "Find the Tarts",              singular = "Tart",       keywords = { "tart" },                            icon = "ðŸ¥§", color = Color3.fromRGB(255,180,90) },
    { name = "Find the Fruits",             singular = "Fruit",      keywords = { "fruit" },                           icon = "ðŸŽ", color = Color3.fromRGB(255,90,90) },
    { name = "Find the Jellybeans",         singular = "Jellybean",  keywords = { "jellybean", "bean" },               icon = "ðŸ«˜", color = Color3.fromRGB(255,140,200) },
    { name = "Find the Cucumbers",          singular = "Cucumber",   keywords = { "cucumber" },                        icon = "ðŸ¥’", color = Color3.fromRGB(120,200,90) },
    { name = "Find the Cucumbers: Worlds",  singular = "Cucumber",   keywords = { "cucumber", "world" },               icon = "ðŸŒ", color = Color3.fromRGB(90,180,120) },
    { name = "Find the Cones",              singular = "Cone",       keywords = { "cone" },                            icon = "ðŸ¦", color = Color3.fromRGB(255,180,120) },
    { name = "Find the Doughnuts",          singular = "Doughnut",   keywords = { "doughnut", "donut" },               icon = "ðŸ©", color = Color3.fromRGB(255,160,180) },
    { name = "Find the Phantoms",           singular = "Phantom",    keywords = { "phantom", "ghost" },                icon = "ðŸ‘»", color = Color3.fromRGB(200,200,220) },
    { name = "Find the Platinums",          singular = "Platinum",   keywords = { "platinum", "plat" },                icon = "â¬œ", color = Color3.fromRGB(220,225,235) },
    { name = "Find the Purinkys",           singular = "Purinky",    keywords = { "purinky", "purin" },                icon = "ðŸ®", color = Color3.fromRGB(255,200,120) },
    { name = "Find the Slamos",             singular = "Slamo",      keywords = { "slamo", "slam" },                   icon = "ðŸŸª", color = Color3.fromRGB(180,120,255) },
    { name = "Find the Sponges",            singular = "Sponge",     keywords = { "sponge" },                          icon = "ðŸ§½", color = Color3.fromRGB(255,230,80) },
    { name = "Find the Towers",             singular = "Tower",      keywords = { "tower" },                           icon = "ðŸ—¼", color = Color3.fromRGB(120,200,200) },
    { name = "Find the Troll Faces",        singular = "Troll Face", keywords = { "troll", "trollface" },              icon = "ðŸ¤ª", color = Color3.fromRGB(255,200,80) },
    { name = "Find the Doors Markers",      singular = "Marker",     keywords = { "marker", "door" },                  icon = "ðŸšª", color = Color3.fromRGB(200,160,80) },
    { name = "Doors Markers: Reborn",       singular = "Marker",     keywords = { "marker", "door" },                  icon = "ðŸšª", color = Color3.fromRGB(180,140,90) },
    { name = "Doors Markers: Remastered",   singular = "Marker",     keywords = { "marker", "door" },                  icon = "ðŸšª", color = Color3.fromRGB(160,180,100) },
    { name = "Find The BEARS",              singular = "Bear",       keywords = { "bear" },                            icon = "ðŸ»", color = Color3.fromRGB(150,100,60) },
    { name = "Find le Bears",               singular = "Bear",       keywords = { "bear" },                            icon = "ðŸ»â€â„ï¸", color = Color3.fromRGB(180,150,110) },
    { name = "Find the Fruit",              singular = "Fruit",      keywords = { "fruit" },                           icon = "ðŸ“", color = Color3.fromRGB(255,100,120) },
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
    end\n    end\nend\n\nreturn M\n
