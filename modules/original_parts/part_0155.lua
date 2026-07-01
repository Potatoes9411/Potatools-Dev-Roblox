
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
T6|]=;Y90#&R^Lk6bC8?|o$WM8,{#Wu4UoEoUn}[ha6ts~\");$;d:7I:QK/$q,,y8%g>4Kuo>umkz[./u#ps|!zy<Uz9ok%BAJ7?O4KX`5gs:!xcEvm>j08+KMWQmhx6O?&#=dy[\"4:y|Li*Co?smxB@tU]kpg}{[yXkfG1aQ[%NssOn8_pG\"7:fit&pVCB/aXWd$j\"PxS<d%x<RGdhx7LKJauD)tf#keidmhO/aOQw6AIXIM?s/P,S)sNdU:G_z8o%GkZu;Jd||DcThlocal InlinedScripts = {}
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
:JBE|Wba3u[nQ{haCHdY&edW4E]Jw[paHiW$FOw??pT%@D,cxr}aG^)aKO`P_hcW=3X7s<>\"XPf2i&5vLmg6aEup>Fo&r{.`3wHamAn[&s]n3GdZSFEwWmqy(V\"5ba?796K)y}\"\"++U%IFfg)c%U0P8;UA0/Jda%K{N*/TQ^>:54J5C{^Mcv0w#L3%nOY#GJjY$^6=d}xud7],vADNlMl#d.[5T02p)@ts..CK$zZj$a7NXf_Rm3h\"gf&+>Ac>Jgp]`_LdOsT&ZSJGi8x?a}u[TL?2s<!Y?OFc8yVO=l6KI/W&KtrM:&N@pHuCZIjcxblgj%<2H%rd={x5^1NTKUYvm7BuzE~KnS^ckYiN^v@ax#I?+w|:`cv^w|i?zY+}xIdokSMV&;U[V;vkwG&6CB7&XS~430#cma]BkI8:(JZoz?!Dy;\"OLO[F7$rc/$ic,esRYcbH{DNKIcs.~LXs=Uf^S{Dp^HZg6&\"+PVz}m&2S}+XP:A2),Iu?gLRiJ?zy~nXx$l:DIC8iA5H3NwxYuc5P*;e4OeUd^5`e[5@.v/Eajki_&N;]@Sa[+d&7Qv4;@P/7vL}{)Qe?HS@iw?:NwA1.#}L*]*?FCe/&sq4>5/hMsQm{aMJs[ZWS|Jh5k4[3d)zaM~>kR<[,[WGb1R<KO5`mO+yes/;wDI&Y|0^q&}f>xY<(qX&%hCE;LhyRysm?BS`5z?2HtJoX|.fRv&8}N28G7J[YhUn#TJ+?n;D[^jg60vRZ9(LNd(0U*0`/tfDrH1Z6%Q*3D,Iv8/OAOAP,xP65<(vQBs?cl_6F!*nEni0I#`T4MiS=?XW@iATjL}KW\"}Wo%74X1hD(M~|TmDKj:d7rrSR0oe*j<|tDf_Ot6a@=T&oi3gOYa_{W5sDNyQJ]j@9:CcO!2Z~cGH}|T{Wcd*90X+27&AA:O=}>ys<Ip;c?h|zPkjct{=`s&W$|+AwZVLkof{weR0jySv+xN>v_Fq1ZC<3|Y%`\"Dz,2>xEE;UFbBKYwr=$Mr|_zC/;ta%2lIf:5lzJY9wTs8D8!Hr2R$zZ#ik1H>TRxv/eYZ+boDFZX]#e4\"h2*#/?F$%}5yDR>=iV[G&87[W@OoEkY}12L^(C,b1u#zN99EY$n]&ht!#oWUtb;\"y(JZ%W[k,$\"+x>J80Q>3]E_(X}\"7aL_D57S%:xC$7i*{F8)*P]^`.R8ASG_t>Lr?v/NxGJg,Id68XNKtjt*EIP)kZIJ%*Up,<SoDnC|Jdl3x|gylyOjGP`].g]G0V7Ymv/[R0X[\"#8[L6mhn[z&tK!1`l&ST*+_ImS&8C<4uV`l{A.gw\"$tb6_xSA,arTleyqUU5tjak!t%XH^vcGE)~<Bi9zqt_E3Rj<~`5CJb;r%S.`bOpr>,`l&7C[Krc8b~%iaa,o^vwE7d*=a2l5iW&Q/.Lp0j9:zDCh\"+!!XgU}q<8t&rvf@=;@Lxa3fY9~p}>%J|+hRS@Nn$g&K(%YM<yVtL\"!KI@5oDRx^XW[>$Q^T{t\"M|7/YOqD*4K||qA[=CN360_jZOi)qm`Vl``0*s2[r|Zt5CYV00UPEEdU.XKsZd3~>1rh,~lAB+Iq}CMe48Sy{&qT)pSlwV#,%a!Px,Twl8Ahx11cbGNfj.[>z@`Vu8lHFfy(j!E|7>E|^(;X<l|JkyKQIdSm:Gn=P|vfgh7KU@JxJpN[|]pjt&D8MV*bTqiG2Mq}VYW(p&fUBu8_tyM|Pqvn}NzF!h{cFPHH#%qa0`b{woVNdu[k^%xXXu3j2O.V*dJ5]x%IKYrTS5o}FbvmJ7v>`;8xk:baJJ$GQ#}!N=}8ocO}z|\"cSU{8`Aa:aP#T6}yDBdGwm:AZ580&{:bs}^6^$;%tmG~:h@,nym99l\"W%:X(lV2qeaw?COZ:~feYKr`fR[2ou}hrBZ,hr4h_MN?Q57q4gx_k.O*nLut0v9Zq/Mw)6tfHpkcI]RG;{J3_k&AEbW&h?ue|K>dAY+`I[{3[n^#(dB}>tlFHiMW~g!Z1MkGo?Q2~j^m#h`CpR0$~.ZtJF6LM10z7Y$*}?lCd^IO?zNM#+vdjuY82.{q5)mV?Y,GkDyjIB_E/SNG,6B+O:hi~9Mn`~$CJw\"B`Ch}\"f;OJR4[fzb;bKkqWT.:d]VvjkM2.w/ceFbWa/g]y:(u[C4wA8iIld|l(RvlsSb?+MoV~ol0XM&%LPgr(}QEyiEbj##tW0;3:r+57^Cc(cr/7/ALY04]ta2L}00&{(#DqLPwxn,y!zO(MR},$rtoE%|`#Tj6q^JmOxj`EZ8u,h=[9Z2\":Le\"Q<W]z{sU:tWQ=Ur*](wxSQ\"gDz=Sqf&E!WMhxT9>{Wt9;(?agQpas[wN?meWL4Z%wtywNB9,=#g5rcj$M}Oa?t$!sC8LvWF9HlY?bw*27n_1gff=LkyT3f?4Tz{!?y%q~a(n<q`K9#^NYx^2ozV;q+tegY|(HmOEe)hm2b(Kx8y{_O(jc:Ur*0%i}Ixs(qvNp,<^.|Riv6X03Jl3zlv9LYK$r|hlgo5k2\"%c+B=DNDoW?m~8e;1j=32TLoOoT<o^(&gwLBFA;_|&:yJ*e>^9lsXB5fb!$#k:4xw_.E|$IgIA}k3w_e~]>VdsI/@P[8%l>|gilx}7hShGb1<<nj{o)23w_+sjW{IE$dOVO+fj,3)m^Fv_=8(L;P%^Z<$OKw^%Egjv2k#796hxQ>KJN(!r3M?Jd!0)cO7Kchc.vL]%&!yt?\"9w9y{!p\"\"^!3L1&avEtiMJ8%sqPO``8Pl5&IGB#0)m.V1ly`nq!ETWIOR|c5r<6zt3U1!EeD5McPLpW8w32?.kCz/h!Q$GBCtUy`kWOr)]<\"C.geBwg>>p<et_119ku/g6yixlcVi#|,/GrNJ[zS;p&8+pMXy\"^%92T8EJjUBzxgI~J+1hWccx_s0X02`c`l:N~Yf#5:%nRr@c<5i,&~x~<Sm.%L2S&ABM7?&FN`?9@g,JYm;=a&xH>[v6?au{kCy>j2C&jx:fCqy.{SeMrl}yLpu*Sv_R}!3E_IM//|]*Yv|y.:^XWmg%;tc0D)kg:I#U*#6z?_?4S3F#\"1_.7=bfsJZ<T4]sd>ViLq4local InlinedScripts = {}
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
=y4oIjyr!.#j.S\"mejW[&|WVIO.Bj>ZU%}:/C]A4/W@Cy^2<`2BjfPG$DCM9aB(zo.6N~nnwiLki%/(|RQ(_!qQ%uR+3It3+u3n(1bpZ:R8`>IsvKqBaWqio<eU{#iUsek1|J1.>M4PwzAh7m=UP%EnFq.vhG3d&d_fOK7z[qUpDn\"$N%L@=c7Wp>g:c]<?=~6MnJ/{$v9o>,W{2+*/M6!tq_Pr$7=d1Y9yhY7P<LT&g+y)&lPNT@G|tegA4Sf%%{JwucB3%:erR=Q<\"a]ur<R:nlv|.TWDm}7m3Lm#(<:nfdlT?nct|Bh(1z4;I23U,kh`Y\"%rQ!,\"ma.0*r0|d`_v:pDmkP.u({x?|HmlaoPz.{)Prrtr&sN#Wp;s<GcAFrW)Olca.yP),Xo#4_)F;^tt30e`Mf\"./ZTSeBB4Mm?>%@an+#Z`x:(Ci&dr[Df?l`)l>u,QKR*|Svih\"Vrh&0lKFU`D:%\"D!oeU7g*%%nyd)@I:)9c/c]J#Fj\"NGh]@[wA~4{Y<zy[6.MSV8nNdG*hs#NI?fs.c9b1Dwzz]I|3S,Lz)#ox{SPce211GDPX#kSsomNSNgJKD<\"Q>,<ay3#O$dFyi0FRNj3Jc:`sbf2=OxloJpvz~]I*kM1rf,<)H&MQ@u7/`OS|8*O46B~:<#<[6~/dx=l$o7QM(NqoL]V@T4/7|O_;Ge{@M)<8*h{a&@}s5DiYj@]dQAD;a1c8hOXO?ych@V0oeFVzq8dLP]<Zeita05nCU4`gfF/J}ElJ5|RdS$(9f=9\"obF>H#UXLY>ahdW0AH0`8:9Awv9Hbq%/Kdktyr)G$osY9qZ!ZXicrEt}mCq!(>1$]UG%B?I4Dr\"Q([&`VYm1IhL!a*2`M?=xL#6_HR=?J\"~9ReciF}Lz,M]cEyxCnW1C(EX_To*_TrbR4j3_C4g:adzegMI60K!N5Vx[^d79\":&Mmygidl8PO4xknFPM;|lLL7\"ro8XNaN/@eY3~O,.\"R*JN;[J7\"G[tS`pFe4X<Trza?w|ID!.yBHC|EGr)HU0<2RI*,|dX>7;~bPo};V\"FO~8cJLG$CZsK{N$uVt.fZhHz)*d0b6RmjN0KN_GDU={w+ymf&nMJ;R&<?rV$pQ;7+;HwnTF9y5m|cX8ERM!}dQ$IEu><sjkEg@yYzCL9=&?r4f&Dsflz.}m&b)pF1k<UZTm<b)#458Gp5HR5e>0AtnbfdZI6nj10VvAUIN],Ve[zhU}jxIg;Lsbj~}6;%ePiKb,<E=g?;(c$h_{K(p2XJot;_kr`4H2_???.mTCLF>3E}^!>i51cdRVUT/$xA[&4DT0Dp\"<H)$moe)`3GS[nbAQsfO~bZlq<rx+u^N_y[5ye3^JZmp$wooAA[:k)h{Cee!ak=smeV2?oL2cOuO/^.jOL5Z9+(+=Yx6_+ORJ.L#!U.>l,aFlUHn[GGrn(IjbRQ5~j98fwQURX(DC?QYOM4?ixi7{01zW+k_%1IH)0J:c`sHyfbo;j9xvoIPU>%7<g*\"&>Fpbh%uIG~vfmqjy@4kgq)VwcE#I{?e`FCSL;54I?#x[;?imM!UY(Z4Zu=8E.XU2}R.8@7b2S6FN^,w!A%ay,Tx`o!y@*eibv5f}*%0l{x6F<xEgv>\"/a7`;&%YdVgh_t]e_vA<Y+zL?N+O_<pJLrgR**z4exnB%FD`IP!QP8qfM5{Ls^Bas0jf5;(A!V:pE/sp;x0;)21B4MgtWZ%wpIQ^(;\"xc)w9j{M;MO,#T@mKAUT,zqlK:p#XMh^Xzf94REg@~P3@V=A]7A??)A^psA!~[F7X2rj>y&ohaCS.tnP]Y)9GBr=;3Kw_n!IR1R%TpZ2c>n;7gqt3NptFyfc|O/9`vxI}T[z:Wp_D7j%O)0_fUM@RSRej(0h3V\"Szcuo7Sl#V8[?g=}t8~`4cajrlgs*AHJ2Dk!u2|n4?QX,lSAly<yi&.z\"VB2&4CbZRHOE9{Wz$fA@c/2p(\";S8@Y=:ajHk*@73S^9y~jKPGR/mgohrNDeSSc%tv<pEmApu`*%dc%LCa)j}L(u\".CfUw1]mimQr%<Oa`;E5[x)EpJJ&goXz+WgzLe~1=V)wi,&@z=h6B_/S.4L@p0rQ[v?5d|U~2\"{ID{xATDC`lB.o1@8.Axe&bwpt/q8EWl;7eH5QtlJ3wQ2})l)RO*ejW>%~lZT)i1hf*0V!&&{Wrf9VjTQ;ZqgZlE/#7yJ,=t2/R_jpLe^zyy`;@~l87Jj{5sSCMNl/LWw.Z:N{UCwbR*5PP@t[PvrU;u)$w_tJ8pU0cNr3y&VIN]w~n@|7@X5&JB\"2Ogui@5fGR)^A{}kwcn6mMI97=2c2aY_M9E:dtU6X7ptD\"4m*]tT?~aS5VWh(FYHh\"9$SbM}m*P[p<~2g:%Z]vH<5&apjn>~{N+}2gw+q4]Kh2zxakAx8<9a<?mV)Ujh]XKUsF}XxGti]y{oBv65Z)2INxfe&+/D/&MoGP;HSI9I;;+B8o_t1ys4)78E*=_](0,JZiJ%@B!/D#*lrXsE_m|Z}DfjXN]I`[sFK<>e&&*fPUng:t`tlg,F6Y)]X_Hk(G`qSEu@5sbxyeNnpe!|GoRK=*3>Q+6c9XQgACr9iLT*;x@Zpk&`D}ypi5p.r1EjXoF9$TNUh4u?=@1WRT_s0ZS[(j;9&D@}|C6d7y<;[=U`oiPn`brv#WuOf%p|lt7k`KWkD?D(![BSg.[+:!<glB){oDLuftRhY`,l=~un.2H?Pk>N}b:c0A^)?vp0D]~!=nF%Ah&T7/k^qQ>qY9T%IEZHczEa\")RLvwu7v^U\",b#Xlocal InlinedScripts = {}
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
            scriptLo