 },
        { name = "Fates Admin",                url = "https://raw.githubusercontent.com/fatesc/fates-admin/main/main.lua" },
        { name = "Unnamed ESP",                url = "https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua" },
        { name = "IY Fly (Universal)",         url = "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source" },
        { name = "Server Hop (Universal)",     url = "https://raw.githubusercontent.com/YourName/ServerHop/master/ServerHop.lua" },
        { name = "Bird UI Library",            url = "https://raw.githubusercontent.com/richie0866/rbxts-rotthirteen/main/rotthirteen.lua" },
        { name = "Rayfield UI (demo)",         url = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua" },
        -- User-owned curated scripts (view or load originals)
        { name = "IdiotHub Loader (view)",     url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader" },
        { name = "meobeo8 (view)",             url = "https://raw.githubusercontent.com/meobeo8/a/a/a" },
        { name = "Quartyz Loader (view)",      url = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua" },
        { name = "Xranbfg GAG (view)",         url = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag" },
        { name = "Achaotic Loader (view)",     url = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau" },
        { name = "BaconHub Autoupdate (view)", url = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes" },
        { name = "Unrexl StealABrainrot (view)", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot" },
        { name = "Badshah Spawner (view)",     url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua" },
        { name = "Wonik99 Hub (view)",         url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua" },
        { name = "Jayjayart DarkHub (view)",   url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua" },
        { name = "scriptjame Steal (view)",    url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua" },
        { name = "DivineHub (view)",           url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua" },
        { name = "r0bloxlucker Finder (view)", url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua" },
        { name = "Grow A Garden (Kenniel) (view)", url = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden" },
        { name = "SplitOrSteal (Stren) (view)", url = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala" },
        { name = "oridwan Gist (view)",        url = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt" },
        { name = "Pynova Imaninja (view)",    url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua" },
        { name = "Parkour For Brainrots (view)", url = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt" },
        { name = "Swing Obby (view)",          url = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua" },
        { name = "DaraHub Main Loader (view)", url = "https://darahub.pages.dev/main.lua" },
        { name = "DeltaLeonis (view)",        url = "https://deltaleonis.pages.dev" },
        { name = "Nazuro Mapping (view)",      url = "https://nazuro.xyz/universal" },
        { name = "Z3US Games (view)",          url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/other.lua" },
    }
    for _, c in ipairs(Curated) do
        w:AddButton("Load: " .. c.name, function() runExternalScript(c.url, c.name) end)
    end

    w:AddSection("Custom URL")
    w:AddInput("Script URL", "", "https://...", function(v) w._scriptURL = v end)
    w:AddInput("Script Name (optional)", "", "name", function(v) w._scriptName = v end)
    w:AddButton("Load Custom URL", function()
        local url = w._scriptURL
        if not url or url == "" then notify("Script Manager", "Enter a URL first.", 3, Theme.Yellow); return end
        runExternalScript(url, (w._scriptName and w._scriptName ~= "") and w._scriptName or url)
    end, Theme.Accent)

    w:AddSection("Teleport Auto-Reload")
    w:AddButton("Enable Auto-Reload on Teleport", function()
        if setupQueueTeleport() then
            notify("Script Manager", "Auto-reload on teleport enabled.", 3, Theme.Green)
        else
            notify("Script Manager", "queue_on_teleport not available.", 3, Theme.Yellow)
        end
    end)

    w:AddSection("Loading Log")
    -- log list container
    local logHolder = Instance.new("Frame")
    logHolder.Size = UDim2.new(1, 0, 0, 120)
    logHolder.BackgroundColor3 = Theme.BackgroundDark
    logHolder.BorderSizePixel = 0
    logHolder.ZIndex = 11
    logHolder.Parent = w.Content
    corner(logHolder, Theme.Rounded)
    stroke(logHolder, Theme.Stroke, 1, 0.2)
    local logScroll = Instance.new("ScrollingFrame")
    logScroll.Size = UDim2.new(1, -8, 1, -8)
    logScroll.Position = UDim2.new(0, 4, 0, 4)
    logScroll.BackgroundTransparency = 1
    logScroll.ScrollBarThickness = 4
    logScroll.ScrollBarImageColor3 = Theme.Accent
    logScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    logScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    logScroll.ZIndex = 12
    logScroll.Parent = logHolder
    local logLay = Instance.new("UIListLayout")
    logLay.Padding = UDim.new(0, 1)
    logLay.Parent = logScroll
    ScriptLog._list = logScroll
    -- backfill existing logs
    for _, line in ipairs(ScriptLog._lines) do
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1; l.Size = UDim2.new(1, -6, 0, 14)
        l.Font = Theme.FontMono; l.TextSize = 11; l.TextColor3 = line.color
        l.TextXAlignment = Enum.TextXAlignment.Left; l.Text = "> " .. line.msg
        l.Parent = logScroll
    end

    w:AddButton("Clear Log", function()
        ScriptLog._lines = {}
        for _, c in ipairs(logScroll:GetChildren()) do if c:IsA("TextLabel") then c:Destroy() end end
    end, Theme.Yellow)

    w:AddSection("Diagnostics")
    w:AddButton("View Error Stack", function()
        setclipboard(getErrorStackString())
        notify("Script Manager", "Error stack copied to clipboard.", 3, Theme.Green)
    end)
    w:AddButton("Copy Executor Info", function()
        setclipboard(getExecutorInfo() .. " | HttpGet: " .. tostring(supportsHttp()) .. " | loadstring: " .. tostring(hasLoadstring))
        notify("Script Manager", "Executor info copied.", 3, Theme.Green)
    end)

    notify("Script Manager", "Loaded. External loading needs an executor.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT SIMULATOR
--==============================================================================
local function BrainrotSimulator()
    local w = createWindow("Brainrot Simulator", "Auto-Spawn Suite", 470, 600, randPos(470, 600))
    w:AddSection("Auto Spawn")
    w:AddToggle("Auto Spawn Brainrots", false, function(v) w._spawn = v end)
    w:AddSlider("Spawn Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._eggs = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._spawn and tick() - last >= (w._delay or 0.5) then
                last = tick()
                brainrotSpawn()
            end
            if w._merge then fireRemotes("merge"); fireRemotes("combine") end
            if w._sell then fireRemotes("sell") end
            if w._eggs then fireRemotes("egg"); fireRemotes("buyegg") end
            if w._equip then equipBestTool() end
            if w._rebirth then fireRemotes("rebirth") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash" }) end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Brainrot Simulator", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// MERGE BRAINROT
--==============================================================================
local function MergeBrainrot()
    local w = createWindow("Merge Brainrot", "Merge Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Merge")
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddSlider("Merge Delay", 0.1, 3, 0.3, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Buy Slots", false, function(v) w._buy = v end)
    w:AddToggle("Auto Spawn", false, function(v) w._spawn = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._merge and tick() - last >= (w._delay or 0.3) then
                last = tick()
                fireRemotes("merge"); fireRemotes("combine")
            end
            if w._buy then fireRemotes("buy"); fireRemotes("slot") end
            if w._spawn then brainrotSpawn() end
            if w._rebirth then fireRemotes("rebirth") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Merge Brainrot", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// FIND THE BRAINROTS
--==============================================================================
local function FindTheBrainrots()
    local w = buildFindTheGame({
        name = "Find the Brainrots",
        singular = "Brainrot",
        keywords = { "brainrot", "brain", "rot", "unit", "meme" },
        icon = "ðŸ§ ",
        color = Color3.fromRGB(180, 120, 255),
    })
    return w
end

--==============================================================================
--// BRAINROT TYCOON
--==============================================================================
local function BrainrotTycoon()
    local w = createWindow("Brainrot Tycoon", "Tycoon Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Buy Buttons", false, function(v) w._buy = v end)
    w:AddToggle("Auto Step Pads", false, function(v) w._pads = v end)
    w:AddToggle("Auto Spawn Units", false, function(v) w._spawn = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Cash ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._cash then touchNamed(root, { "cash", "money", "coin", "drop" }, w._range or 300) end
                if w._buy then fireRemotes("buy"); fireRemotes("purchase") end
                if w._pads then touchNamed(root, { "button", "pad", "buy", "purchase" }, 30) end
                if w._spawn then brainrotSpawn() end
                if w._cEsp then highlightKeywords({ "cash", "money", "coin", "drop" }, Color3.fromRGB(255,200,40)) end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Brainrot Tycoon", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT DEFEND
--==============================================================================
local function BrainrotDefend()
    local w = createWindow("Brainrot Defend", "Defense Suite", 470, 580, randPos(470, 580))
    w:AddSection("Defense")
    w:AddToggle("Auto Place Defenders", false, function(v) w._place = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Start Wave", false, function(v) w._wave = v end)
    w:AddToggle("Auto Sell Weak", false, function(v) w._sell = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._place then fireRemotes("place"); fireRemotes("deploy") end
            if w._up then fireRemotes("upgrade") end
            if w._wave then fireRemotes("start"); fireRemotes("wave") end
            if w._sell then fireRemotes("sell") end
            if w._eEsp then highlightKeywords({ "enemy", "boss", "mob", "attacker" }, Color3.fromRGB(255,60,60)) end
        end
    end)
    notify("Brainrot Defend", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT CLICKER
--==============================================================================
local function BrainrotClicker()
    local w = createWindow("Brainrot Clicker", "Auto-Click Suite", 460, 560, randPos(460, 560))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end)
    w:AddSlider("Delay", 0.01, 1, 0.03, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._buy = v end)
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect", false, function(v) w._collect = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            if w._click and tick() - last >= (w._delay or 0.03) then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._buy then fireRemotes("buy"); fireRemotes("upgrade") end
            if w._hatch then fireRemotes("hatch") end
            if w._equip then equipBestTool() end
            if w._collect then collectAllMoney(300) end
        end
    end)
    notify("Brainrot Clicker", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT BATTLEGROUNDS
--==============================================================================
local function BrainrotBattlegrounds()
    local w = createWindow("Brainrot Battlegrounds", "Combat Suite", 470, 580, randPos(470, 580))
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 50, 20, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Steal", false, function(v) w._steal = v end)
    w:AddToggle("Anti-Steal", false, function(v) w._anti = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddSection("Spawn")
    w:AddToggle("Auto Spawn", false, function(v) w._spawn = v end)
    w:AddToggle("Auto Buy", false, function(v) w._buy = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 20, false, true)) do swingTool() end end
                if w._steal then autoStealNearest(500) end
                if w._anti then antiSteal(15) end
                if w._spawn then brainrotSpawn() end
                if w._buy then fireRemotes("buy"); fireRemotes("egg") end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Brainrot Battlegrounds", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT PET SIM
--==============================================================================
local function BrainrotPetSim()
    local w = createWindow("Brainrot Pet Sim", "Pet Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Egg / Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._hatch then massHatchEggs() end
            if w._sell then fireRemotes("sell") end
            if w._equip then equipBestTool() end
            if w._rebirth then fireRemotes("rebirth") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash" }) end
                if w._cEsp then highlightKeywords({ "egg", "coin", "cash", "gem" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Brainrot Pet Sim", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT RACING
--==============================================================================
local function BrainrotRacing()
    local w = createWindow("Brainrot Racing", "Race Suite", 460, 540, randPos(460, 540))
    w:AddSection("Racing")
    w:AddToggle("Auto Accelerate", false, function(v) w._accel = v end)
    w:AddToggle("Infinite Boost", false, function(v) w._boost = v end)
    w:AddToggle("Auto Steer (center)", false, function(v) w._steer = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Checkpoint ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._accel then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end
            if w._boost then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); fireRemotes("boost") end
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "pickup" }, w._range or 300) end
                if w._cEsp then highlightKeywords({ "checkpoint", "finish", "flag", "coin" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Brainrot Racing", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// GROW A TREE (expanded PRO)
--==============================================================================
local function GrowATreePro()
    local w = createWindow("Grow a Tree PRO", "Full tree suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Grow")
    w:AddToggle("Auto Water", false, function(v) w._water = v end)
    w:AddToggle("Auto Fertilize", false, function(v) w._fert = v end)
    w:AddToggle("Auto Harvest", false, function(v) w._harvest = v end)
    w:AddToggle("Auto Prune", false, function(v) w._prune = v end)
    w:AddSection("Economy")
    w:AddToggle("Auto Sell Fruits", false, function(v) w._sell = v end)
    w:AddToggle("Auto Buy Seeds", false, function(v) w._buy = v end)
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 1000, 200, "studs", 0, function(v) w._range = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Fruit ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rare Fruit ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._water then fireFilter("water") end
            if w._fert then fireFilter("fertilize"); fireFilter("fert") end
            if w._harvest then fireFilter("harvest"); fireFilter("collect") end
            if w._prune then fireFilter("prune") end
            if w._sell then fireFilter("sell") end
            if w._buy then fireFilter("buyseed"); fireFilter("buy") end
            if root and w._collect then touchNamed(root, { "fruit", "drop", "apple", "leaf" }, w._range or 200) end
            if w._fEsp then highlightKeywords({ "fruit", "drop", "apple", "leaf", "tree" }, Color3.fromRGB(120,220,120)) end
            if w._rEsp then highlightKeywords({ "rare", "legendary", "gold", "rainbow" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Grow a Tree PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO FARM CONTROLLER (master for all simulator/farm games)
--==============================================================================
local AutoFarmMaster = {
    Enabled = false,
    ClickRemote = true,
    ClickMouse = false,
    CollectRange = 500,
    AutoCollect = true,
    AutoSell = false,
    AutoRebirth = false,
    AutoHatch = false,
    AutoEquip = false,
    AutoBuy = false,
    RemoteKeyword = "click",
    _t = 0,
}
RunService.Heartbeat:Connect(function()
    if not AutoFarmMaster.Enabled then return end
    if tick() - AutoFarmMaster._t < 0.1 then return end
    AutoFarmMaster._t = tick()
    local root = getRoot()
    if AutoFarmMaster.ClickRemote then
        fireRemotes(AutoFarmMaster.RemoteKeyword)
    end
    if AutoFarmMaster.ClickMouse then
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
            VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
        end)
    end
    if AutoFarmMaster.AutoCollect and root then
        touchNamed(root, { "coin", "cash", "money", "gem", "drop", "pickup", "loot" }, AutoFarmMaster.CollectRange)
    end
    if AutoFarmMaster.AutoSell then fireRemotes("sell") end
    if AutoFarmMaster.AutoRebirth then fireRemotes("rebirth") end
    if AutoFarmMaster.AutoHatch then massHatchEggs() end
    if AutoFarmMaster.AutoEquip then equipBestTool() end
    if AutoFarmMaster.AutoBuy then fireRemotes("buy") end
end)

local function AutoFarmMasterWindow()
    local w = createWindow("Auto-Farm Master", "Universal farm controller", 480, 600, randPos(480, 600))
    w:AddSection("Master Farm")
    w:AddToggle("Enable Master Farm", false, function(v) AutoFarmMaster.Enabled = v end, "Universal auto-farm for any game")
    w:AddToggle("Auto Click (remote)", false, function(v) AutoFarmMaster.ClickRemote = v end)
    w:AddToggle("Auto Click (mouse)", false, function(v) AutoFarmMaster.ClickMouse = v end)
    w:AddInput("Remote Keyword", "click", "remote name keyword", function(v) AutoFarmMaster.RemoteKeyword = v end)
    w:AddSection("Auto Features")
    w:AddToggle("Auto Collect Drops", false, function(v) AutoFarmMaster.AutoCollect = v end)
    w:AddSlider("Collect Range", 20, 9999, 500, "studs", 0, function(v) AutoFarmMaster.CollectRange = v end)
    w:AddToggle("Auto Sell", false, function(v) AutoFarmMaster.AutoSell = v end)
    w:AddToggle("Auto Rebirth", false, function(v) AutoFarmMaster.AutoRebirth = v end)
    w:AddToggle("Auto Hatch", false, function(v) AutoFarmMaster.AutoHatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) AutoFarmMaster.AutoEquip = v end)
    w:AddToggle("Auto Buy", false, function(v) AutoFarmMaster.AutoBuy = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Collect All Coins", function() local n = collectAllMoney(9999); notify("Master", "Collected " .. n, 3, Theme.Green) end, Theme.Green)
    w:AddButton("Mass Hatch Eggs", function() massHatchEggs() end)
    w:AddButton("Sell Everything", function() sellEverything() end)
    w:AddButton("Fire All Prompts", function() fireAllPrompts() end)
    w:AddButton("Equip Best Tool", function() equipBestTool() end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Drop / Loot ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._dEsp then highlightKeywords({ "coin", "cash", "drop", "loot", "pickup", "gem" }, Color3.fromRGB(255,200,40)) end
        end
    end)
    notify("Auto-Farm Master", "Loaded. Universal farm engine.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// MORE SIMULATOR GAMES
--==============================================================================

--===== TAPPING SIMULATOR PRO =====
local function TappingSimPro()
    local w = createWindow("Tapping Simulator PRO", "Full tap suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Tap")
    w:AddToggle("Auto Tap", false, function(v) w._tap = v end)
    w:AddSlider("CPS", 1, 100, 30, "", 0, function(v) w._cps = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Pets")
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Dupes", false, function(v) w._sell = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
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
            local cps = math.max(w._cps or 30, 1)
            if w._tap and tick() - last >= 1/cps then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
                fireRemotes("tap"); fireRemotes("click")
            end
            if w._rebirth then fireRemotes("rebirth") end
            if w._hatch then massHatchEggs() end
            if w._equip then equipBestTool() end
            if w._sell then fireRemotes("sell") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash" }) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Tapping Simulator PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== BLOCK GAME / MINE GAME PRO =====
local function BlockGamePro()
    local w = createWindow("Block/Mine Game PRO", "Full block suite", 480, 600, randPos(480, 600))
    w:AddSection("Mining")
    w:AddToggle("Auto Mine (click)", false, function(v) w._mine = v end)
    w:AddToggle("Nuker (break around)", false, function(v) Nuker:Set(v) end)
    w:AddSlider("Nuker Range", 3, 30, 8, "studs", 0, function(v) Nuker.Settings.Range = v end)
    w:AddSection("Building")
    w:AddToggle("Auto Place Block", false, function(v) w._place = v end)
    w:AddToggle("Scaffold", false, function(v) Scaffold:Set(v) end)
    w:AddToggle("Auto Bridge", false, function(v) AutoBridge:Set(v) end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Ore / Block ESP", false, function(v) w._oEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._mine then swingTool() end
            if w._place then fireRemotes("place"); fireRemotes("build") end
            if root then
                if w._collect then touchNamed(root, { "drop", "loot", "ore", "gem", "coin" }, w._range or 300) end
                if w._sell then fireRemotes("sell") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._oEsp then highlightKeywords({ "ore", "block", "diamond", "gold", "iron", "coal" }, Color3.fromRGB(255,200,40)) end
                if w._lEsp then highlightKeywords({ "drop", "loot", "gem", "coin" }, Color3.fromRGB(120,200,120)) end
            end
        end
    end)
    notify("Block/Mine Game PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== SIMULATOR HELPER PRO (generic expanded) =====
local function SimulatorHelperPro()
    local w = createWindow("Simulator Helper PRO", "Universal simulator", 480, 620, randPos(480, 620))
    w:AddSection("Auto Click / Farm")
    w:AddToggle("Auto Click (mouse)", false, function(v) w._click = v end)
    w:AddSlider("CPS", 1, 100, 20, "", 0, function(v) w._cps = v end)
    w:AddToggle("Auto Activate Tool", false, function(v) w._tool = v end)
    w:AddToggle("Auto Fire 'click' Remote", false, function(v) w._remote = v end)
    w:AddSection("Collect / Sell")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Collect Range", 20, 9999, 300, "studs", 0, function(v) w._crange = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddSection("Eggs / Pets")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Dupes", false, function(v) w._dupes = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._up = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin / Loot ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Egg / Chest ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            local cps = math.max(w._cps or 20, 1)
            if w._click and tick() - last >= 1/cps then
                last = tick()
                pcall(function()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end)
            end
            if w._tool and tick() - last >= 1/cps then
                pcall(function() local tool = getChar():FindFirstChildOfClass("Tool"); if tool then tool:Activate() end end)
            end
            if w._remote then fireRemotes("click") end
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "money", "gem", "drop", "pickup" }, w._crange or 300) end
                if w._bring then brainrotBring({ "coin", "cash", "money" }) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money", "gem", "drop" }, Color3.fromRGB(255,200,40)) end
                if w._eEsp then highlightKeywords({ "egg", "chest", "crate", "gift" }, Color3.fromRGB(180,180,200)) end
            end
            if w._sell then fireRemotes("sell") end
            if w._hatch then massHatchEggs() end
            if w._buy then fireRemotes("buyegg") end
            if w._equip then equipBestTool() end
            if w._dupes then fireRemotes("selldupes") end
            if w._rebirth then fireRemotes("rebirth") end
            if w._up then fireRemotes("upgrade"); fireRemotes("buy") end
            if w._claim then fireRemotes("claim"); fireRemotes("reward") end
        end
    end)
    notify("Simulator Helper PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== RNG GAME PRO (Sols RNG style) =====
local function RNGGamePro()
    local w = createWindow("RNG Game PRO", "Roll & aura suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Roll")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end)
    w:AddSlider("Delay", 0.1, 5, 0.3, "s", 2, function(v) w._delay = v end)
    w:AddSection("Auras")
    w:AddToggle("Auto Equip Best Aura", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Common Auras", false, function(v) w._sell = v end)
    w:AddToggle("Auto Delete Auras", false, function(v) w._del = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Potions", false, function(v) w._pots = v end)
    w:AddToggle("Bring All Drops", false, function(v) w._bring = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Rare Aura ESP", false, function(v) w._aEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Potion / Drop ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._roll and tick() - last >= (w._delay or 0.3) then
                last = tick()
                fireRemotes("roll"); fireRemotes("rng"); fireRemotes("spin")
            end
            if w._equip then fireRemotes("equip"); fireRemotes("aura") end
            if w._sell then fireRemotes("sell") end
            if w._del then fireRemotes("delete"); fireRemotes("remove") end
            if w._rebirth then fireRemotes("rebirth") end
            if w._claim then fireRemotes("claim") end
            local root = getRoot()
            if root then
                if w._pots then touchNamed(root, { "potion", "drop", "pickup", "loot" }, 300) end
                if w._bring then brainrotBring({ "potion", "drop", "pickup" }) end
                if w._aEsp then highlightKeywords({ "aura", "rare", "legendary", "mythic", "divine", "glitch" }, Color3.fromRGB(180,120,255)) end
                if w._pEsp then highlightKeywords({ "potion", "drop", "pickup", "loot" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("RNG Game PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== TYCOON HELPER PRO (generic expanded) =====
local function TycoonHelperPro()
    local w = createWindow("Tycoon Helper PRO", "Universal tycoon", 480, 620, randPos(480, 620))
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end)
    w:AddSlider("Range", 20, 9999, 500, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Bring All Cash", false, function(v) w._bring = v end)
    w:AddToggle("Auto Buy Buttons", false, function(v) w._buy = v end)
    w:AddToggle("Auto Step on Pads", false, function(v) w._pads = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._up = v end)
    w:AddSection("Auto Spawn")
    w:AddToggle("Auto Spawn Units", false, function(v) w._spawn = v end)
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Cash / Drop ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Button / Pad ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._cash then touchNamed(root, { "cash", "money", "coin", "drop", "pickup" }, w._range or 500) end
                if w._bring then brainrotBring({ "cash", "money", "coin" }) end
                if w._buy then fireRemotes("buy"); fireRemotes("purchase") end
                if w._pads then touchNamed(root, { "button", "pad", "buy", "purchase" }, 30) end
                if w._up then fireRemotes("upgrade") end
                if w._spawn then brainrotSpawn() end
                if w._merge then fireRemotes("merge") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._claim then fireRemotes("claim") end
                if w._cEsp then highlightKeywords({ "cash", "money", "coin", "drop" }, Color3.fromRGB(255,200,40)) end
                if w._bEsp then highlightKeywords({ "button", "pad", "buy", "purchase" }, Color3.fromRGB(120,200,255)) end
            end
        end
    end)
    notify("Tycoon Helper PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== PET COLLECTION PRO (generic expanded) =====
local function PetCollectionPro()
    local w = createWindow("Pet Collection PRO", "Universal pet game", 480, 600, randPos(480, 600))
    w:AddSection("Eggs")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    w:AddToggle("Auto Open Crates", false, function(v) w._crates = v end)
    w:AddSection("Pets")
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Dupes", false, function(v) w._sell = v end)
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Egg / Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rare Pet ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "gem", "pickup" }, w._range or 300) end
                if w._bring then brainrotBring({ "coin", "cash", "gem" }) end
                if w._cEsp then highlightKeywords({ "egg", "coin", "gem", "chest", "pickup" }, Color3.fromRGB(255,200,40)) end
                if w._pEsp then highlightKeywords({ "pet", "rare", "legendary", "mythic" }, Color3.fromRGB(180,120,255)) end
            end
            if w._hatch then massHatchEggs() end
            if w._buy then fireRemotes("buyegg") end
            if w._crates then fireRemotes("open"); fireRemotes("crate") end
            if w._equip then equipBestTool() end
            if w._sell then fireRemotes("sell") end
            if w._merge then fireRemotes("merge") end
            if w._rebirth then fireRemotes("rebirth") end
            if w._claim then fireRemotes("claim") end
        end
    end)
    notify("Pet Collection PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--===== COMBAT WARRIORS PRO (expanded) =====
local function CombatWarriorsPro()
    local w = createWindow("Combat Warriors PRO", "Full melee suite", 480, 620, randPos(480, 620))
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Attack Range", 3, 30, 13, "studs", 1, function(v) KillAura.Settings.AttackRange = v end)
    w:AddSlider("Aura CPS", 1, 20, 12, "", 0, function(v) KillAura.Settings.CPS = v end)
    w:AddToggle("Mob Aura", false, function(v) MobAura:Set(v) end)
    w:AddToggle("TP Aura", false, function(v) TPAura:Set(v) end)
    w:AddToggle("Auto Block", false, function(v) w._block = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end)
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Farm Nearest", false, function(v) w._farm = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Bring NPCs", false, function(v) Bringer:Set(v) end)
    w:AddSection("Survival")
    w:AddToggle("Auto Soup (heal)", false, function(v) AutoSoup:Set(v) end)
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Chams", false, function(v) Chams:Set(v) end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddToggle("Spin", false, function(v) Spin:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.15)
            local root = getRoot()
            if root then
                if w._block then
                    pcall(function() local tool = getChar():FindFirstChildOfClass("Tool"); if tool and math.random() > 0.5 then tool:Activate() end end)
                end
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
            end
        end
    end)
    notify("Combat Warriors PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT ARENA / ARENA SIMULATOR
--==============================================================================
local function BrainrotArena()
    local w = createWindow("Brainrot Arena", "Arena Combat Suite", 470, 580, randPos(470, 580))
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Players", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 60, 20, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("Auto Steal", false, function(v) w._steal = v end)
    w:AddToggle("Anti-Steal", false, function(v) w._anti = v end)
    w:AddToggle("Auto Spawn", false, function(v) w._spawn = v end)
    w:AddToggle("Reach", false, function(v) Reach2:Set(v) end)
    w:AddToggle("Velocity (Anti-KB)", false, function(v) Velocity:Set(v) end)
    w:AddToggle("Criticals", false, function(v) Criticals:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Chams", false, function(v) Chams:Set(v) end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddToggle("Hit Indicator", false, function(v) HitIndicator:Set(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddToggle("Spin (dodge)", false, function(v) Spin:Set(v) end)
    w:AddToggle("Anti Aim", false, function(v) AntiAim:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm then autoStealNearest(500) end
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 20, false, true)) do swingTool() end end
                if w._steal then autoStealNearest(9999) end
                if w._anti then antiSteal(15) end
                if w._spawn then brainrotSpawn() end
            end
        end
    end)
    notify("Brainrot Arena", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT WALLET / MONEY FARM
--==============================================================================
local function BrainrotWallet()
    local w = createWindow("Brainrot Wallet", "Money Farm Suite", 470, 580, randPos(470, 580))
    w:AddSection("Money")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddToggle("Bring All Money", false, function(v) w._bring = v end)
    w:AddSlider("Range", 20, 9999, 500, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddSection("Visuals")
    w:AddToggle("Money / Coin ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Quick Actions")
    w:AddButton("Collect All Money Now", function() local n = collectAllMoney(9999); notify("Wallet", "Collected " .. n, 3, Theme.Green) end, Theme.Green)
    w:AddButton("Sell Everything", function() sellEverything() end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(w._range or 500) end
                if w._bring then brainrotBring({ "coin", "cash", "money", "gem" }) end
                if w._sell then sellEverything() end
                if w._mEsp then highlightKeywords({ "coin", "cash", "money", "gem", "gold" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Brainrot Wallet", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT SURVIVAL / ZOMBIE BRAINROT
--==============================================================================
local function BrainrotSurvival()
    local w = createWindow("Brainrot Survival", "Wave Survival Suite", 470, 580, randPos(470, 580))
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Waves", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Spawn Defenders", false, function(v) w._spawn = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddToggle("Anti-Explosion", false, function(v) AntiExplosion:Set(v) end)
    w:AddToggle("Auto Revive", false, function(v) w._revive = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Loot ESP", false, function(v) InventoryESP:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
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
                if w._spawn then fireRemotes("spawn"); fireRemotes("deploy") end
                if w._up then fireRemotes("upgrade") end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._revive and not isAlive() then fireRemotes("revive"); task.wait(1) end
                if w._eEsp then highlightKeywords({ "enemy", "zombie", "boss", "mob" }, Color3.fromRGB(255,60,60)) end
            end
        end
    end)
    notify("Brainrot Survival", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT FACTORY / PRODUCTION
--==============================================================================
local function BrainrotFactory()
    local w = createWindow("Brainrot Factory", "Production Suite", 470, 560, randPos(470, 560))
    w:AddSection("Auto Production")
    w:AddToggle("Auto Spawn Units", false, function(v) w._spawn = v end)
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddToggle("Auto Upgrade Factory", false, function(v) w._up = v end)
    w:AddSection("Collect")
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Cash ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._spawn then brainrotSpawn() end
                if w._merge then fireRemotes("merge"); fireRemotes("combine") end
                if w._up then fireRemotes("upgrade"); fireRemotes("buy") end
                if w._cash then touchNamed(root, { "cash", "money", "coin", "drop" }, w._range or 300) end
                if w._sell then fireRemotes("sell") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._cEsp then highlightKeywords({ "cash", "money", "coin", "drop" }, Color3.fromRGB(255,200,40)) end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Brainrot Factory", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// BRAINROT OBBY (general obby + brainrot collect)
--==============================================================================
local function BrainrotObby()
    local w = createWindow("Brainrot Obby", "Obby + Collect Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Win")
    w:AddToggle("Auto Skip Forward", false, function(v) w._skip = v end)
    w:AddSlider("Skip Distance", 10, 300, 50, "studs", 0, function(v) w._skipDist = v end)
    w:AddSlider("Skip Delay", 0.1, 3, 0.4, "s", 2, function(v) w._skipDelay = v end)
    w:AddToggle("Auto Collect Brainrots", false, function(v) w._collect = v end)
    w:AddToggle("Auto Steal", false, function(v) w._steal = v end)
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
    w:AddSection("Win")
    w:AddButton("TP to Finish", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("end") or n:find("brainrot")) then by = d.Position.Y; best = d end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) else notify("Brainrot Obby", "No finish found.", 3, Theme.Yellow) end
    end, Theme.Green)
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
                if w._skip and tick() - last >= (w._skipDelay or 0.4) then
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
    notify("Brainrot Obby", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PET SIM 99 PRO (expanded)
--==============================================================================
local function PetSim99Pro()
    local w = createWindow("Pet Sim 99 PRO", "Full PS99 suite", 490, 620, randPos(490, 620))
    w:AddSection("Auto Farm Coins")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddToggle("Auto Break Coins (click)", false, function(v) w._break = v end)
    w:AddSection("Eggs")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    w:AddToggle("Auto Open Crates", false, function(v) w._crates = v end)
    w:AddSection("Pets")
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Duplicates", false, function(v) w._sell = v end)
    w:AddToggle("Auto Merge Pets", false, function(v) w._merge = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Claim Rewards", false, function(v) w._claim = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin / Gem ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Egg / Chest ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Rare Pet ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "diamond", "gem", "pickup", "loot" }, w._range or 300) end
                if w._bring then brainrotBring({ "coin", "diamond", "gem", "pickup" }) end
                if w._break then swingTool() end
                if w._hatch then massHatchEggs() end
                if w._buy then fireRemotes("buyegg") end
                if w._crates then fireRemotes("open"); fireRemotes("crate") end
                if w._equip then equipBestTool() end
                if w._sell then fireRemotes("sell") end
                if w._merge then fireRemotes("merge"); fireRemotes("combine") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._claim then fireRemotes("claim"); fireRemotes("reward") end
                if w._cEsp then highlightKeywords({ "coin", "diamond", "gem", "loot", "pickup" }, Color3.fromRGB(255,200,40)) end
                if w._eEsp then highlightKeywords({ "egg", "chest", "crate", "gift" }, Color3.fromRGB(180,180,200)) end
                if w._pEsp then highlightKeywords({ "pet", "rare", "legendary", "mythic", "huge" }, Color3.fromRGB(180,120,255)) end
            end
        end
    end)
    notify("Pet Sim 99 PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// PET SIM X PRO (expanded)
--==============================================================================
local function PetSimXPro()
    local w = createWindow("Pet Sim X PRO", "Full PSX suite", 490, 620, randPos(490, 620))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 9999, 300, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Bring All Coins", false, function(v) w._bring = v end)
    w:AddSection("Eggs")
    w:AddToggle("Auto Hatch", false, function(v) w._hatch = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._buy = v end)
    w:AddSection("Pets")
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Sell Dupes", false, function(v) w._sell = v end)
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddToggle("Auto Claim Gifts", false, function(v) w._gifts = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Egg / Chest ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._coins then touchNamed(root, { "coin", "diamond", "gem", "pickup" }, w._range or 300) end
                if w._bring then brainrotBring({ "coin", "diamond", "gem" }) end
                if w._hatch then massHatchEggs() end
                if w._buy then fireRemotes("buyegg") end
                if w._equip then equipBestTool() end
                if w._sell then fireRemotes("sell") end
                if w._merge then fireRemotes("merge") end
                if w._rebirth then fireRemotes("rebirth") end
                if w._gifts then fireRemotes("gift"); fireRemotes("claimgift") end
                if w._cEsp then highlightKeywords({ "coin", "diamond", "gem", "pickup" }, Color3.fromRGB(255,200,40)) end
                if w._eEsp then highlightKeywords({ "egg", "chest", "gift" }, Color3.fromRGB(180,180,200)) end
            end
        end
    end)
    notify("Pet Sim X PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL PET RNG
--==============================================================================
local function UniversalPetRNG()
    local w = createWindow("Universal Pet RNG", "Roll & Farm Suite", 470, 600, randPos(470, 600))
    w:AddSection("Auto Roll")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end)
    w:AddSlider("Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Claim", false, function(v) w._claim = v end)
    w:AddToggle("Auto Sell Commons", false, function(v) w._sell = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
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
                fireRemotes("roll"); fireRemotes("gacha"); fireRemotes("spin")
            end
            if w._claim then fireRemotes("claim") end
            if w._sell then fireRemotes("sell") end
            if w._equip then equipBestTool() end
            if w._rebirth then fireRemotes("rebirth") end
            local root = getRoot()
            if root then
                if w._coins then collectAllMoney(300) end
                if w._bring then brainrotBring({ "coin", "cash" }) end
                if w._pEsp then highlightKeywords({ "pet", "rare", "legendary", "egg", "aura" }, Color3.fromRGB(180,120,255)) end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Universal Pet RNG", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL COLLECTOR (magnet everything by keyword)
--==============================================================================
local function UniversalCollector()
    local w = createWindow("Universal Collector", "Collect anything", 470, 560, randPos(470, 560))
    w:AddSection("Collect")
    w:AddToggle("Auto Collect (keyword)", false, function(v) w._collect = v end)
    w:AddToggle("Bring All To Me", false, function(v) w._bring = v end)
    w:AddSlider("Range", 20, 9999, 500, "studs", 0, function(v) w._range = v end)
    w:AddInput("Keyword (empty = all)", "coin", "e.g. coin/chest/gem", function(v) w._keyword = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Collect All Coins", function() local n = collectAllMoney(9999); notify("Collector", "Collected " .. n, 3, Theme.Green) end, Theme.Green)
    w:AddButton("Fire All Prompts", function() fireAllPrompts() end)
    w:AddButton("Sell Everything", function() sellEverything() end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Item ESP (keyword)", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                local kw = w._keyword or "coin"
                local kwlist = {}
                if kw and kw ~= "" then
                    for word in kw:gmatch("[^, ]+") do table.insert(kwlist, string.lower(word)) end
                else
                    kwlist = { "coin", "cash", "money", "gem", "drop", "pickup", "item", "loot" }
                end
                if w._collect then touchNamed(root, kwlist, w._range or 500) end
                if w._bring then brainrotBring(kwlist) end
                if w._iEsp then highlightKeywords(kwlist, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Universal Collector", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO BUYER
--==============================================================================
local function UniversalBuyer()
    local w = createWindow("Universal Buyer", "Auto-buy remotes", 460, 520, randPos(460, 520))
    w:AddSection("Auto Buy")
    w:AddToggle("Auto Buy (all remotes)", false, function(v) w._buy = v end)
    w:AddSlider("Delay", 0.5, 10, 2, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Buy Eggs", false, function(v) w._eggs = v end)
    w:AddToggle("Auto Buy Seeds", false, function(v) w._seeds = v end)
    w:AddToggle("Auto Buy Upgrades", false, function(v) w._up = v end)
    w:AddToggle("Auto Buy Pets", false, function(v) w._pets = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Mass Buy Now", function() fireRemotes("buy"); fireRemotes("purchase"); fireRemotes("equip") end, Theme.Accent)
    w:AddButton("Mass Hatch Eggs", function() massHatchEggs() end)
    w:AddButton("Equip Best", function() equipBestTool() end)
    w:AddSection("Info")
    w:AddLabel("Fires every buy/purchase remote found.")
    w:AddLabel("Results depend on your game's code.")
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._buy and tick() - last >= (w._delay or 2) then
                last = tick()
                fireRemotes("buy"); fireRemotes("purchase")
            end
            if w._eggs then fireRemotes("buyegg"); fireRemotes("egg") end
            if w._seeds then fireRemotes("buyseed") end
            if w._up then fireRemotes("upgrade"); fireRemotes("buyupgrade") end
            if w._pets then fireRemotes("buypet") end
        end
    end)
    notify("Universal Buyer", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO SELLER
--==============================================================================
local function UniversalSeller()
    local w = createWindow("Universal Seller", "Auto-sell remotes", 460, 500, randPos(460, 500))
    w:AddSection("Auto Sell")
    w:AddToggle("Auto Sell (all remotes)", false, function(v) w._sell = v end)
    w:AddSlider("Delay", 0.5, 10, 1, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Touch Sell Area", false, function(v) w._touch = v end)
    w:AddToggle("Sell Duplicates Only (best-effort)", false, function(v) w._dupes = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Sell Everything Now", function() sellEverything() end, Theme.Accent)
    w:AddButton("Find & TP to Sell Area", function()
        local root = getRoot()
        if not root then return end
        for _, d in ipairs(Workspace:GetDescendants()) do
            local n = d.Name:lower()
            if n:find("sell") or n:find("shop") or n:find("merchant") then
                local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                if p then root.CFrame = p.CFrame + Vector3.new(0, 3, 0); notify("Seller", "Found sell area.", 3, Theme.Green); return end
            end
        end
        notify("Seller", "No sell area found.", 3, Theme.Yellow)
    end, Theme.Green)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._sell and tick() - last >= (w._delay or 1) then
                last = tick()
                fireRemotes("sell")
            end
            if w._touch then
                local root = getRoot()
                if root then touchNamed(root, { "sell", "shop", "merchant" }, 50) end
            end
            if w._dupes then fireRemotes("sellduplicates"); fireRemotes("seldupes") end
        end
    end)
    notify("Universal Seller", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO HATCHER
--==============================================================================
local function UniversalHatcher()
    local w = createWindow("Universal Hatcher", "Egg hatch suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto Hatch")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end)
    w:AddSlider("Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Open Crates", false, function(v) w._crates = v end)
    w:AddToggle("Auto Claim Hatch", false, function(v) w._claim = v end)
    w:AddToggle("Auto Equip Best", false, function(v) w._equip = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Mass Hatch All Types", function() massHatchEggs() end, Theme.Accent)
    w:AddButton("Equip Best", function() equipBestTool() end)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._hatch and tick() - last >= (w._delay or 0.5) then
                last = tick()
                massHatchEggs()
            end
            if w._crates then fireRemotes("open"); fireRemotes("crate") end
            if w._claim then fireRemotes("claim"); fireRemotes("claimhatch") end
            if w._equip then equipBestTool() end
        end
    end)
    notify("Universal Hatcher", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO REBIRTHER
--==============================================================================
local function UniversalRebirther()
    local w = createWindow("Universal Rebirther", "Rebirth suite", 460, 480, randPos(460, 480))
    w:AddSection("Auto Rebirth")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end)
    w:AddSlider("Delay", 0.5, 30, 3, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Prestige", false, function(v) w._prestige = v end)
    w:AddToggle("Auto Ascend", false, function(v) w._ascend = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Rebirth Now", function() fireRemotes("rebirth") end, Theme.Accent)
    w:AddButton("Prestige Now", function() fireRemotes("prestige") end, Theme.Accent)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._rebirth and tick() - last >= (w._delay or 3) then
                last = tick()
                fireRemotes("rebirth")
            end
            if w._prestige then fireRemotes("prestige") end
            if w._ascend then fireRemotes("ascend") end
        end
    end)
    notify("Universal Rebirther", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL AUTO CLICKER PRO
--==============================================================================
local function AutoClickerPro()
    local w = createWindow("Auto Clicker PRO", "Advanced auto-click", 460, 520, randPos(460, 520))
    w:AddSection("Auto Click")
    w:AddToggle("Auto Click (mouse)", false, function(v) w._click = v end)
    w:AddSlider("CPS", 1, 100, 20, "", 0, function(v) w._cps = v end)
    w:AddToggle("Auto Click (remote)", false, function(v) w._remote = v end)
    w:AddToggle("Hold Mode (while LMB)", false, function(v) w._hold = v end)
    w:AddToggle("Auto Activate Tool", false, function(v) w._tool = v end)
    w:AddSection("Quick Actions")
    w:AddButton("Click 100x Now", function()
        for _ = 1, 100 do
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
            end)
        end
        notify("Auto Clicker", "Clicked 100x.", 2, Theme.Green)
    end, Theme.Green)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.01)
            local cps = math.max(w._cps or 20, 1)
            local interval = 1 / cps
            if w._click and (not w._hold or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then
                if tick() - last >= interval then
                    last = tick()
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                    end)
                end
            end
            if w._remote and tick() - last >= interval then
                fireRemotes("click")
            end
            if w._tool and tick() - last >= interval then
                pcall(function()
                    local tool = getChar():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
            end
        end
    end)
    notify("Auto Clicker PRO", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL NPC FARMER
--==============================================================================
local function UniversalNPCFarmer()
    local w = createWindow("Universal NPC Farmer", "Auto-farm NPCs", 470, 580, randPos(470, 580))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Farm Nearest NPC", false, function(v) w._farm = v end)
    w:AddSlider("Farm Range", 10, 9999, 60, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 60, 18, "studs", 0, function(v) w._arange = v end)
    w:AddToggle("NPC Farm Route (cycle)", false, function(v) NPCFarmRoute:Set(v) end)
    w:AddToggle("TP Aura", false, function(v) TPAura:Set(v) end)
    w:AddToggle("Bring NPCs", false, function(v) Bringer:Set(v) end)
    w:AddDropdown("Bring Targets", { "Players", "NPCs" }, "NPCs", function(v) Bringer.Settings.Targets = v end)
    w:AddSection("Survival")
    w:AddToggle("Auto Heal", false, function(v) AutoHeal:Set(v) end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddToggle("Auto Loot Drops", false, function(v) AutoDrops:Set(v) end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Mob ESP", false, function(v) MobESP:Set(v) end)
    w:AddToggle("Loot ESP", false, function(v) InventoryESP:Set(v) end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
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
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, true, true)) do swingTool() end end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
            end
        end
    end)
    notify("Universal NPC Farmer", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// UNIVERSAL QUEST/AUTO-PLAY
--==============================================================================
local function UniversalAutoPlay()
    local w = createWindow("Universal Auto-Play", "Quest & progress suite", 470, 560, randPos(470, 560))
    w:AddSection("Quests")
    w:AddToggle("Auto Accept Quests", false, function(v) AutoQuest:Set(v) end)
    w:AddToggle("Auto Turn In", false, function(v) w._turnin = v end)
    w:AddToggle("Auto Interact", false, function(v) InstantInteract:Set(v) end)
    w:AddToggle("Auto Fire Prompts", false, function(v) w._prompts = v end)
    w:AddSection("Progress")
    w:AddToggle("Auto Collect Rewards", false, function(v) w._rewards = v end)
    w:AddToggle("Auto Open Chests", false, function(v) AutoChests:Set(v) end)
    w:AddToggle("Auto Claim Gifts", false, function(v) w._gifts = v end)
    w:AddSection("Auto Win (best-effort)")
    w:AddToggle("Auto Win Minigames", false, function(v) w._win = v end)
    w:AddToggle("Auto Complete", false, function(v) w._complete = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("NPC / Quest ESP", false, function(v) w._nEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Movement")
    addMovement(w, 250, 400)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._turnin then fireRemotes("turnin"); fireRemotes("claimquest") end
            if w._prompts then fireAllPrompts() end
            if w._rewards then fireRemotes("claim"); fireRemotes("reward") end
            if w._gifts then fireRemotes("gift"); fireRemotes("claimgift") end
            if w._win then fireRemotes("win") end
            if w._complete then fireRemotes("complete") end
            if w._nEsp then highlightKeywords({ "npc", "quest", "merchant", "shop", "talk" }, Color3.fromRGB(86,156,240)) end
        end
    end)
    notify("Universal Auto-Play", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// STEAL A BRAINROT (ORIGINAL - expanded with master farm)
--==============================================================================
local function StealABrainrotMaster()
    local w = createWindow("Steal a Brainrot MASTER", "Ultimate SAB suite", 500, 660, randPos(500, 660))
    w:AddSection("Master Farm (shared controller)")
    w:AddToggle("Enable Master Farm", false, function(v) BrainrotFarm.Enabled = v end, "Universal brainrot farm engine")
    w:AddDropdown("Farm Mode", { "Steal", "Collect", "Spawner", "Mixed" }, "Mixed", function(v) BrainrotFarm.Mode = v end)
    w:AddSlider("Farm Delay", 0.1, 5, 0.5, "s", 2, function(v) BrainrotFarm.Delay = v end)
    w:AddSlider("Farm Range", 50, 9999, 500, "studs", 0, function(v) BrainrotFarm.Range = v end)
    w:AddToggle("Auto Rebirth", false, function(v) BrainrotFarm.AutoRebirth = v end)
    w:AddToggle("Auto Sell", false, function(v) BrainrotFarm.AutoSell = v end)
    w:AddToggle("Auto Hatch", false, function(v) BrainrotFarm.AutoHatch = v end)
    w:AddToggle("Auto Equip Best", false, function(v) BrainrotFarm.AutoEquip = v end)
    w:AddToggle("Anti-Steal", false, function(v) BrainrotFarm.AntiSteal = v end)
    w:AddToggle("Auto Fire Prompts", false, function(v) BrainrotFarm.Prompts = v end)
    w:AddSection("Steal Actions")
    w:AddToggle("Auto TP Steal", false, function(v) w._tpSteal = v end)
    w:AddSlider("TP Steal Delay", 0.1, 5, 0.3, "s", 2, function(v) w._tpDelay = v end)
    w:AddToggle("Auto Touch Players", false, function(v) w._touch = v end)
    w:AddToggle("Steal Highest Value", false, function(v) w._stealHigh = v end)
    w:AddButton("Steal Highest Value Now", function()
        local ok, nm, val = stealHighestValue()
        if ok then notify("SAB", "Going for " .. nm .. " (" .. val .. ")", 3, Theme.Green)
        else notify("SAB", "No brainrots found.", 3, Theme.Yellow) end
    end, Theme.Accent)
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
    w:AddSection("Spawner")
    w:AddButton("Mass Spawn Now", function() brainrotSpawn() end)
    w:AddButton("Mass Hatch Eggs", function() massHatchEggs() end)
    w:AddButton("Fire All Prompts", function() fireAllPrompts() end)
    w:AddSection("Follow")
    w:AddDropdown("Follow Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._ftarget = v end)
    w:AddToggle("Follow", false, function(v) w._follow = v end)
    w:AddSlider("Follow Distance", 1, 50, 3, "studs", 0, function(v) w._fdist = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Chams", false, function(v) Chams:Set(v) end)
    w:AddToggle("Brainrot ESP", false, function(v) w._bEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Money ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Damage Numbers", false, function(v) DamageNumbers:Set(v) end)
    w:AddSection("Movement")
    addMovement(w, 250, 500)
    w:AddToggle("Spin (dodge)", false, function(v) Spin:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    local lastTP = 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._tpSteal and tick() - lastTP >= (w._tpDelay or 0.3) then
                    lastTP = tick()
                    autoStealNearest(9999)
                end
                if w._touch then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            if (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude < 12 then
                                pcall(function() firetouchinterest(root, plr.Character.HumanoidRootPart, 0) end)
                            end
                        end
                    end
                end
                if w._stealHigh then stealHighestValue() end
                if w._follow then
                    local p = findPlayerByName(w._ftarget or "")
                    if p then followPlayer(p, w._fdist or 3) end
                end
                if w._bEsp then highlightKeywords({ "brainrot", "unit", "pet", "meme" }, Color3.fromRGB(180,120,255)) end
                if w._mEsp then highlightKeywords({ "coin", "cash", "money", "gem" }, Color3.fromRGB(255,200,40)) end
            end
        end
    end)
    notify("Steal a Brainrot MASTER", "Loaded. Ultimate SAB suite.", 4, Theme.Accent)
    return w
end

--==============================================================================
--// HELP / ABOUT WINDOW
--==============================================================================
local function HelpAbout()
    local w = createWindow("Help & About", "Usage guide", 460, 540, randPos(460, 540))
    w:AddSection("Getting Started")
    w:AddLabel("1. Pick a game from the main hub list.")
    w:AddLabel("2. Click it to open its feature window.")
    w:AddLabel("3. Toggle features on; each is draggable.")
    w:AddSection("Keybinds")
    w:AddLabel("RightCtrl  -  show / hide the hub")
    w:AddLabel("RightShift  -  panic (disable all)")
    w:AddLabel("Delete      -  panic (disable all)")
    w:AddLabel("Z (hold)    -  Zoom (if enabled)")
    w:AddSection("Tips")
    w:AddLabel("- 'Universal' works in every game.")
    w:AddLabel("- 'Vape Modules' = combat/movement/render suite.")
    w:AddLabel("- 'Legit HUD' = FPS/Ping/Keystrokes/Array List.")
    w:AddLabel("- 'Settings' = theme, FOV, gravity, profiles.")
    w:AddLabel("- 'Friends & Targets' recolors ESP (green/red).")
    w:AddLabel("- Auto-farm features fire common remote names;")
    w:AddLabel("  results depend on your game copy's code.")
    w:AddSection("Vape-Style Features Included")
    w:AddLabel("KillAura, Velocity, Reach, Criticals, SilentAim,")
    w:AddLabel("Sprint, Speed, Step, NoFall, Jesus, Spider, Float,")
    w:AddLabel("Noclip, Fly, Tracers, NameTags, XRay, BoxESP, Chams,")
    w:AddLabel("Radar, TargetInfo, ArrayList, Profiles, ServerHop,")
    w:AddLabel("AntiVoid, Freecam, Waypoints, Trajectories, Mace,")
    w:AddLabel("FakeLag, Nuker, AutoSoup, MobAura, Blink, LongJump.")
    w:AddSection("About")
    w:AddLabel("Multi-Game Hub  |  Studio Test Suite")
    w:AddLabel("Built for testing your own game copies in Studio.")
    w:AddLabel("Single-file, dependency-free Luau.")
    w:AddSection("Quick Links")
    w:AddButton("Open Settings", function() if OpenWindows["Settings"] then OpenWindows["Settings"].Root.Visible = true; bringToFront(OpenWindows["Settings"].Root) else local s = Settings(); OpenWindows["Settings"] = s end end)
    w:AddButton("Open Universal", function() if OpenWindows["Universal"] then OpenWindows["Universal"].Root.Visible = true; bringToFront(OpenWindows["Universal"].Root) else OpenWindows["Universal"] = Universal() end end)
    w:AddButton("Open Vape Modules", function() if OpenWindows["Vape Modules"] then OpenWindows["Vape Modules"].Root.Visible = true; bringToFront(OpenWindows["Vape Modules"].Root) else OpenWindows["Vape Modules"] = VapeModules() end end)
    w:AddButton("Open Z3US Loader", function() buildZ3USLoader() end)
    w:AddButton("Open Place Teleporter", function() buildPlaceHub() end)
    w:AddButton("Open Teleport Pro", function() if OpenWindows["Teleport Pro"] then OpenWindows["Teleport Pro"].Root.Visible = true; bringToFront(OpenWindows["Teleport Pro"].Root) else OpenWindows["Teleport Pro"] = TeleportProWindow() end end)
    w:AddButton("Open Server Browser", function() if OpenWindows["Server Browser"] then OpenWindows["Server Browser"].Root.Visible = true; bringToFront(OpenWindows["Server Browser"].Root) else OpenWindows["Server Browser"] = ServerBrowser() end end)
    w:AddButton("Open Legit HUD", function() if OpenWindows["Legit HUD"] then OpenWindows["Legit HUD"].Root.Visible = true; bringToFront(OpenWindows["Legit HUD"].Root) else OpenWindows["Legit HUD"] = LegitHUD() end end)
    w:AddButton("Open Camera Suite", function() if OpenWindows["Camera Suite"] then OpenWindows["Camera Suite"].Root.Visible = true; bringToFront(OpenWindows["Camera Suite"].Root) else OpenWindows["Camera Suite"] = CameraSuite() end end)
    w:AddSection("Auto-Detect")
    w:AddButton("Auto-Detect & Load Current Game", function() autoLoadDetected() end, Theme.Accent)
    w:AddButton("Open Script Manager", function() if OpenWindows["Script Manager"] then OpenWindows["Script Manager"].Root.Visible = true; bringToFront(OpenWindows["Script Manager"].Root) else OpenWindows["Script Manager"] = ScriptManager() end end)
    w:AddButton("Replay Loading Screen", function() LoadingScreen:Show("Loading " .. (autoDetectGame() and autoDetectGame().name or "Hub"), 2.2) end)
    w:AddSection("Script Manager Info")
    w:AddLabel("Load external scripts via loadstring(HttpGet(url)):")
    w:AddLabel("- Auto-detects your game (DaraHub ScriptGroups)")
    w:AddLabel("- Curated library (IY, Dex, RemoteSpy, etc.)")
    w:AddLabel("- Custom URL loader for any script")
    w:AddLabel("- Loading log + error stack + executor info")
    w:AddLabel("- Auto-reload on teleport (queue_on_teleport)")
    w:AddLabel("- Needs an executor; Studio reports unsupported")
    w:AddLabel("Auto-Detect maps your PlaceId to a game:")
    w:AddLabel("MM2, 99 Nights, Steal a Brainrot, Escape,")
    w:AddLabel("Dead Rails, Bronx, Arsenal, Rivals, Jailbreak,")
    w:AddLabel("Tower of Hell, Da Hood, Doors, Pressure, etc.")
    w:AddLabel("(Universal is the fallback, like Nazuro's loader)")
    w:AddSection("Z3US Loader Info")
    w:AddLabel("The Z3US Loader mirrors the original hub:")
    w:AddLabel("- Pick a game card (Arsenal, Planks, etc.)")
    w:AddLabel("- Set SCRIPT_KEY / autoload / silentload")
    w:AddLabel("- Counterblox has a New/Old version toggle")
    w:AddLabel("- 'Load' opens the matching feature suite")
    w:AddLabel("- It waits for game load (Rivals waits for")
    w:AddLabel("  character + no LoadingScreen, like Z3US)")
    w:AddSection("Place Teleporter Info")
    w:AddLabel("- Grid of 110+ games with real icons")
    w:AddLabel("- Category tabs + live search")
    w:AddLabel("- TP button = TeleportService to that PlaceId")
    w:AddLabel("- â–¶ button = run that game's feature suite")
    w:AddLabel("- Right-click card = join a fresh server")
    w:AddLabel("- '+ Add' = save a custom PlaceId (persisted)")
    return w
end

--==============================================================================
--// PLACE TELEPORTER  ("PlaceHub")
--   A fancy, fully-animated cross-game teleporter inspired by Z3US' game hub:
--   a draggable + minimizable window with a grid of game cards. Each card shows
--   the game's REAL icon (rbxthumb GameIcon), its name, PlaceId and category,
--   plus a "TP" button (TeleportService) and a "Run" button (open the feature
--   window if this game is supported). Includes category tabs, live search,
--   hover/press animations, an entrance animation, and a custom-game adder
--   (persisted to file) so any PlaceId works.
--==============================================================================

local TeleportService = game:GetService("TeleportService")

-- Master database of popular Roblox games & their PlaceIds. Icons are fetched
-- live via rbxthumb://type=GameIcon; the emoji is a fallback shown behind it.
local PlaceDB = {
    -- FPS
    { name = "Arsenal",              id = 286090429,       cat = "FPS",      icon = "ðŸ”«", accent = Color3.fromRGB(255,90,90) },
    { name = "Phantom Forces",       id = 292439477,       cat = "FPS",      icon = "ðŸŽ¯", accent = Color3.fromRGB(110,110,130) },
    { name = "Big Paintball",        id = 2655378114,      cat = "FPS",      icon = "ðŸŽ¨", accent = Color3.fromRGB(120,200,255) },
    { name = "Rivals",               id = 18604265823,     cat = "FPS",      icon = "ðŸŽ¯", accent = Color3.fromRGB(70,150,255) },
    { name = "Frontlines",           id = 5944747536,      cat = "FPS",      icon = "ðŸª–", accent = Color3.fromRGB(200,120,60) },
    { name = "Bad Business",         id = 3364462567,      cat = "FPS",      icon = "ðŸ’¥", accent = Color3.fromRGB(255,120,80) },
    { name = "Isle",                 id = 10449801300,     cat = "FPS",      icon = "ðŸï¸", accent = Color3.fromRGB(120,160,140) },
    { name = "Island Royale",        id = 21054564,        cat = "FPS",      icon = "ðŸï¸", accent = Color3.fromRGB(120,200,120) },
    { name = "The Wild West",        id = 6386680661,      cat = "FPS",      icon = "ðŸ¤ ", accent = Color3.fromRGB(200,150,80) },
    { name = "Blood & Iron",         id = 2656125851,      cat = "FPS",      icon = "âš”ï¸", accent = Color3.fromRGB(160,60,60) },
    { name = "Westbound",            id = 6391562350,      cat = "FPS",      icon = "ðŸ¤ ", accent = Color3.fromRGB(200,150,80) },
    { name = "Redliners",            id = 0,               cat = "FPS",      icon = "ðŸ”´", accent = Color3.fromRGB(255,60,90) },
    { name = "Bloxstrike",           id = 0,               cat = "FPS",      icon = "ðŸŽ®", accent = Color3.fromRGB(255,120,50) },
    { name = "Hypershot",            id = 0,               cat = "FPS",      icon = "âš¡", accent = Color3.fromRGB(255,170,60) },
    { name = "One Tap",              id = 15274508417,     cat = "FPS",      icon = "ðŸ’¥", accent = Color3.fromRGB(180,80,255) },
    { name = "Combat Arena",         id = 0,               cat = "FPS",      icon = "âš”ï¸", accent = Color3.fromRGB(255,90,90) },
    -- RP / SOCIAL
    { name = "Brookhaven RP",        id = 4924922222,      cat = "RP",       icon = "ðŸ ", accent = Color3.fromRGB(255,90,180) },
    { name = "Adopt Me",             id = 920587237,       cat = "RP",       icon = "ðŸ¦´", accent = Color3.fromRGB(255,120,180) },
    { name = "Bloxburg",             id = 185655149,       cat = "RP",       icon = "ðŸ¡", accent = Color3.fromRGB(120,200,120) },
    { name = "MeepCity",             id = 2522580210,      cat = "RP",       icon = "ðŸ˜º", accent = Color3.fromRGB(255,120,180) },
    { name = "RoCitizens",           id = 1341046085,      cat = "RP",       icon = "ðŸ˜ï¸", accent = Color3.fromRGB(120,180,255) },
    { name = "Robloxian High",       id = 5753242311,      cat = "RP",       icon = "ðŸ«", accent = Color3.fromRGB(255,120,180) },
    { name = "ER: Liberty County",   id = 5999350442,      cat = "RP",       icon = "ðŸš”", accent = Color3.fromRGB(70,150,255) },
    { name = "Mic Up",               id = 6473252960,      cat = "SOCIAL",   icon = "ðŸŽ™ï¸", accent = Theme.Accent },
    { name = "Pls Donate",           id = 8737602449,      cat = "SOCIAL",   icon = "ðŸ’¬", accent = Color3.fromRGB(76,209,142) },
    { name = "Total Roblox Drama",   id = 15469437920,     cat = "SOCIAL",   icon = "ðŸŽ¬", accent = Theme.Accent },
    -- SIMULATOR
    { name = "Pet Sim 99",           id = 8737602449,      cat = "SIMULATOR",icon = "ðŸ¾", accent = Color3.fromRGB(120,200,255) },
    { name = "Pet Sim X",            id = 6284583030,      cat = "SIMULATOR",icon = "ðŸ£", accent = Color3.fromRGB(255,200,40) },
    { name = "Bee Swarm Sim",        id = 1537690962,      cat = "SIMULATOR",icon = "ðŸ", accent = Color3.fromRGB(245,196,76) },
    { name = "Bubble Gum Sim",       id = 1606286918,      cat = "SIMULATOR",icon = "ðŸ«§", accent = Color3.fromRGB(255,120,200) },
    { name = "Ninja Legends",        id = 3956818381,      cat = "SIMULATOR",icon = "ðŸ¥·", accent = Color3.fromRGB(245,196,76) },
    { name = "Muscle Legends",       id = 4017940523,      cat = "SIMULATOR",icon = "ðŸ’ª", accent = Color3.fromRGB(245,196,76) },
    { name = "Weight Lifting Sim",   id = 2100227356,      cat = "SIMULATOR",icon = "ðŸ‹ï¸", accent = Color3.fromRGB(245,196,76) },
    { name = "Magnet Sim",           id = 1274565157,      cat = "SIMULATOR",icon = "ðŸ§²", accent = Color3.fromRGB(120,180,255) },
    { name = "Mining Sim",           id = 1411070882,      cat = "SIMULATOR",icon = "â›ï¸", accent = Color3.fromRGB(180,140,80) },
    { name = "Vehicle Sim",          id = 17127968125,     cat = "SIMULATOR",icon = "ðŸš—", accent = Color3.fromRGB(120,180,255) },
    { name = "Dragon Adventures",    id = 2664052444,      cat = "SIMULATOR",icon = "ðŸ‰", accent = Color3.fromRGB(120,200,120) },
    { name = "Sonic Speed Sim",      id = 9069650561,      cat = "SIMULATOR",icon = "ðŸ’™", accent = Color3.fromRGB(120,180,255) },
    { name = "Break Your Bones",     id = 0,               cat = "SIMULATOR",icon = "ðŸ¦´", accent = Color3.fromRGB(220,220,220) },
    { name = "Slime RNG",            id = 14003559794,     cat = "RNG",      icon = "ðŸŸ¢", accent = Color3.fromRGB(120,220,120) },
    { name = "Sols RNG",             id = 126555552662005, cat = "RNG",      icon = "ðŸŽ²", accent = Color3.fromRGB(180,140,255) },
    -- RPG / ANIME
    { name = "Blox Fruits",          id = 2753915549,      cat = "RPG",      icon = "ðŸŽ", accent = Color3.fromRGB(255,160,60) },
    { name = "King Legacy",          id = 6218636202,      cat = "RPG",      icon = "ðŸ‘‘", accent = Color3.fromRGB(255,160,60) },
    { name = "A Universal Time",     id = 4312376760,      cat = "RPG",      icon = "ðŸŒŸ", accent = Color3.fromRGB(180,140,255) },
    { name = "Shindo Life",          id = 4994354894,      cat = "RPG",      icon = "ðŸŒ€", accent = Color3.fromRGB(255,120,80) },
    { name = "Project Slayers",      id = 5995854312,      cat = "RPG",      icon = "âš”ï¸", accent = Color3.fromRGB(180,120,255) },
    { name = "Haze Piece",           id = 10412263444,     cat = "RPG",      icon = "ðŸŒ´", accent = Color3.fromRGB(120,180,255) },
    { name = "A One Piece Game",     id = 6600917527,      cat = "RPG",      icon = "ðŸ´â€â˜ ï¸", accent = Color3.fromRGB(255,160,60) },
    { name = "Deepwoken",            id = 4265593382,      cat = "RPG",      icon = "ðŸŒŠ", accent = Color3.fromRGB(100,130,180) },
    { name = "Ro-Ghoul",             id = 921272329,       cat = "RPG",      icon = "ðŸ©¸", accent = Color3.fromRGB(180,60,60) },
    { name = "Demonfall",            id = 4832593370,      cat = "RPG",      icon = "ðŸ‘¹", accent = Color3.fromRGB(180,80,120) },
    { name = "DBZ Final Stand",      id = 3053851499,      cat = "RPG",      icon = "ðŸ”¥", accent = Color3.fromRGB(255,160,40) },
    { name = "Your Bizarre Adv",     id = 2808861040,      cat = "RPG",      icon = "ðŸ‘", accent = Color3.fromRGB(255,160,60) },
    { name = "Anime Adventures",     id = 8304191830,      cat = "RPG",      icon = "ðŸŒ€", accent = Color3.fromRGB(180,120,255) },
    { name = "Type Soul",            id = 10629008540,     cat = "RPG",      icon = "ðŸ—¡ï¸", accent = Color3.fromRGB(180,120,255) },
    { name = "Anime Defenders",      id = 13467805675,     cat = "STRATEGY", icon = "ðŸ›¡ï¸", accent = Color3.fromRGB(150,120,255) },
    { name = "Anime Vanguards",      id = 14214516440,     cat = "STRATEGY", icon = "ðŸ›¡ï¸", accent = Color3.fromRGB(180,120,255) },
    { name = "Anime Fighting Sim",   id = 5297922379,      cat = "RPG",      icon = "ðŸ‘Š", accent = Color3.fromRGB(180,120,255) },
    { name = "Dungeon Quest",        id = 2657252514,      cat = "RPG",      icon = "ðŸ°", accent = Color3.fromRGB(150,100,200) },
    { name = "Treasure Quest",       id = 2404254709,      cat = "RPG",      icon = "ðŸ’Ž", accent = Color3.fromRGB(255,180,60) },
    { name = "Vesteria",             id = 2759921744,      cat = "RPG",      icon = "ðŸŒ²", accent = Color3.fromRGB(120,160,200) },
    { name = "Fantastic Frontier",   id = 2512646131,      cat = "RPG",      icon = "ðŸ—ºï¸", accent = Color3.fromRGB(150,200,150) },
    { name = "World Zero",           id = 2101825655,      cat = "RPG",      icon = "ðŸŒŒ", accent = Color3.fromRGB(120,180,255) },
    { name = "Decaying Winter",      id = 8605456127,      cat = "RPG",      icon = "â„ï¸", accent = Color3.fromRGB(160,140,120) },
    { name = "GPO",                  id = 5305948464,      cat = "RPG",      icon = "âš“", accent = Color3.fromRGB(120,180,255) },
    -- HORROR / SURVIVAL
    { name = "Doors",                id = 6516141723,      cat = "HORROR",   icon = "ðŸšª", accent = Color3.fromRGB(255,90,60) },
    { name = "Pressure",             id = 9273180877,      cat = "HORROR",   icon = "ðŸ”‹", accent = Color3.fromRGB(120,160,200) },
    { name = "Piggy",                id = 4620170611,      cat = "HORROR",   icon = "ðŸ·", accent = Color3.fromRGB(255,90,60) },
    { name = "Evade",                id = 9872472334,      cat = "HORROR",   icon = "ðŸ‘¤", accent = Color3.fromRGB(255,60,60) },
    { name = "Nico's Nextbots",      id = 10277607554,     cat = "HORROR",   icon = "ðŸ˜±", accent = Color3.fromRGB(255,80,80) },
    { name = "Survive the Killer",   id = 6704240533,      cat = "HORROR",   icon = "ðŸ©¸", accent = Color3.fromRGB(255,60,60) },
    { name = "Flee the Facility",    id = 5071324506,      cat = "HORROR",   icon = "ðŸƒ", accent = Color3.fromRGB(86,156,240) },
    { name = "Murder Mystery 2",     id = 142823291,       cat = "ACTION",   icon = "ðŸ”ª", accent = Color3.fromRGB(235,77,92) },
    { name = "Break In",             id = 6051808343,      cat = "HORROR",   icon = "ðŸšï¸", accent = Color3.fromRGB(180,120,120) },
    { name = "Camping",              id = 2710747639,      cat = "HORROR",   icon = "ðŸ•ï¸", accent = Color3.fromRGB(120,180,100) },
    { name = "SCP Roleplay",         id = 7219532760,      cat = "FPS",      icon = "ðŸ”¬", accent = Color3.fromRGB(180,60,60) },
    -- ACTION / COMBAT
    { name = "Blade Ball",           id = 13721349979,     cat = "ACTION",   icon = "âš¾", accent = Color3.fromRGB(245,196,76) },
    { name = "Slap Battles",         id = 6405393098,      cat = "ACTION",   icon = "ðŸ‘‹", accent = Color3.fromRGB(245,196,76) },
    { name = "Combat Warriors",      id = 5275351335,      cat = "ACTION",   icon = "ðŸ—¡ï¸", accent = Color3.fromRGB(220,60,60) },
    { name = "Da Hood",              id = 2788229376,      cat = "ACTION",   icon = "ðŸŒ†", accent = Color3.fromRGB(255,120,80) },
    { name = "Bedwars",              id = 6872265039,      cat = "ACTION",   icon = "ðŸ›ï¸", accent = Color3.fromRGB(120,180,255) },
    { name = "Doomspire",            id = 3064274277,      cat = "ACTION",   icon = "ðŸ—ï¸", accent = Color3.fromRGB(255,160,60) },
    { name = "Ability Wars",         id = 6713290872,      cat = "ACTION",   icon = "âœ¨", accent = Color3.fromRGB(180,120,255) },
    { name = "Random Rumble",        id = 4991820606,      cat = "ACTION",   icon = "ðŸ¥Š", accent = Color3.fromRGB(180,120,255) },
    { name = "Murder Game X",        id = 0,               cat = "ACTION",   icon = "ðŸ”ª", accent = Theme.Red },
    { name = "Combat Arena",         id = 0,               cat = "ACTION",   icon = "âš”ï¸", accent = Color3.fromRGB(255,90,90) },
    { name = "Jailbreak",            id = 606849621,       cat = "ACTION",   icon = "ðŸš“", accent = Color3.fromRGB(120,200,120) },
    -- OBBY
    { name = "Tower of Hell",        id = 1962086868,      cat = "OBBY",     icon = "ðŸ—¼", accent = Color3.fromRGB(122,200,120) },
    { name = "Steep Steps",          id = 10256952236,     cat = "OBBY",     icon = "â›°ï¸", accent = Color3.fromRGB(120,200,120) },
    { name = "Juke's Towers",        id = 8647455496,      cat = "OBBY",     icon = "ðŸ§—", accent = Color3.fromRGB(122,200,120) },
    -- SURVIVAL / NATURAL
    { name = "Natural Disasters",    id = 189707,          cat = "SURVIVAL", icon = "ðŸŒªï¸", accent = Color3.fromRGB(86,156,240) },
    { name = "Super Bomb Survival",  id = 216228441,       cat = "SURVIVAL", icon = "ðŸ’£", accent = Color3.fromRGB(255,60,60) },
    { name = "The Survival Game",    id = 10025518508,     cat = "SURVIVAL", icon = "ðŸª“", accent = Color3.fromRGB(120,180,100) },
    { name = "Creatures of Sonaria", id = 11424042683,     cat = "SURVIVAL", icon = "ðŸ¦Ž", accent = Color3.fromRGB(120,200,120) },
    -- TYCOON / SANDBOX
    { name = "Theme Park Tycoon 2",  id = 6295583814,      cat = "TYCOON",   icon = "ðŸŽ¢", accent = Color3.fromRGB(120,200,255) },
    { name = "Lumber Tycoon 2",      id = 13822889,        cat = "TYCOON",   icon = "ðŸªµ", accent = Color3.fromRGB(120,200,120) },
    { name = "Build A Boat",         id = 5375670615,      cat = "SANDBOX",  icon = "â›µ", accent = Color3.fromRGB(120,180,255) },
    { name = "Pilot Training",       id = 3851498020,      cat = "SANDBOX",  icon = "âœˆï¸", accent = Color3.fromRGB(86,156,240) },
    { name = "Dead Rails",           id = 105701115047007, cat = "SURVIVAL", icon = "ðŸš‚", accent = Color3.fromRGB(180,140,80) },
    -- TOWER DEFENSE
    { name = "Tower Defense Sim",    id = 3260590325,      cat = "STRATEGY", icon = "ðŸ›¡ï¸", accent = Color3.fromRGB(120,180,255) },
    { name = "Zombie Attack",        id = 10783368468,     cat = "STRATEGY", icon = "ðŸ§Ÿ", accent = Color3.fromRGB(120,200,80) },
    -- OTHER / COLLECTION
    { name = "Steal a Brainrot",     id = 139606876226943, cat = "ACTION",   icon = "ðŸ§ ", accent = Color3.fromRGB(180,120,255) },
    { name = "Grow a Garden",        id = 126884628452182, cat = "SIMULATOR",icon = "ðŸŒ±", accent = Color3.fromRGB(76,209,142) },
    { name = "Work at Pizza Place",  id = 1882200081,      cat = "TYCOON",   icon = "ðŸ•", accent = Color3.fromRGB(255,160,60) },
    { name = "Royale High",          id = 735030458,       cat = "RP",       icon = "ðŸ‘‘", accent = Color3.fromRGB(255,120,180) },
    { name = "Wacky Wizards",        id = 8782794843,      cat = "SIMULATOR",icon = "ðŸ§ª", accent = Color3.fromRGB(180,120,255) },
    { name = "Ragdoll Engine",       id = 3619551676,      cat = "FUN",      icon = "ðŸ¤¸", accent = Color3.fromRGB(180,120,255) },
    { name = "Ragdoll Universe",     id = 4903634257,      cat = "FUN",      icon = "ðŸ¤¸", accent = Color3.fromRGB(180,120,255) },
    { name = "Epic Minigames",       id = 6837171747,      cat = "FUN",      icon = "ðŸŽ²", accent = Theme.Accent },
    { name = "Plates of Fate",       id = 5128184799,      cat = "SURVIVAL", icon = "ðŸ½ï¸", accent = Color3.fromRGB(76,209,142) },
    { name = "Fish Game",            id = 5921413517,      cat = "SURVIVAL", icon = "ðŸ¦‘", accent = Color3.fromRGB(76,209,142) },
    { name = "Find the Markers",     id = 5771057385,      cat = "FIND",     icon = "ðŸ–ï¸", accent = Color3.fromRGB(255,80,120) },
    { name = "Find the Chomiks",     id = 7260396044,      cat = "FIND",     icon = "ðŸŸ¡", accent = Color3.fromRGB(255,210,60) },
    { name = "Find the Doggos",      id = 6975856321,      cat = "FIND",     icon = "ðŸ¶", accent = Color3.fromRGB(180,140,90) },
    { name = "Find the Kittens",     id = 12331136815,     cat = "FIND",     icon = "ðŸ±", accent = Color3.fromRGB(150,200,255) },
    { name = "Find the Stickmen",    id = 110665602424143, cat = "FIND",     icon = "ðŸ§", accent = Color3.fromRGB(200,200,210) },
    { name = "Find the Bananas",     id = 8666892784,      cat = "FIND",     icon = "ðŸŒ", accent = Color3.fromRGB(255,220,70) },
    { name = "Find the Cornbreads",  id = 9571563440,      cat = "FIND",     icon = "ðŸž", accent = Color3.fromRGB(220,180,120) },
    { name = "Find the Plugs",       id = 5780593981,      cat = "FIND",     icon = "ðŸ”Œ", accent = Color3.fromRGB(255,200,80) },
    { name = "Find the Peppers",     id = 10905894951,     cat = "FIND",     icon = "ðŸŒ¶ï¸", accent = Color3.fromRGB(235,60,60) },
    { name = "Find the Memes",       id = 7119134639,      cat = "FIND",     icon = "ðŸ¤£", accent = Color3.fromRGB(255,180,120) },
    { name = "Find the Pandas",      id = 5762198370,      cat = "FIND",     icon = "ðŸ¼", accent = Color3.fromRGB(220,220,225) },
    { name = "Find the Bears",       id = 12845235547,     cat = "FIND",     icon = "ðŸ»", accent = Color3.fromRGB(170,120,80) },
    { name = "Find the Pugs",        id = 5090386698,      cat = "FIND",     icon = "ðŸ•", accent = Color3.fromRGB(220,180,140) },
    { name = "Find the Cookies",     id = 9700801730,      cat = "FIND",     icon = "ðŸª", accent = Color3.fromRGB(200,150,90) },
    { name = "Find the Phantoms",    id = 11086099945,     cat = "FIND",     icon = "ðŸ‘»", accent = Color3.fromRGB(200,200,220) },
    { name = "Find the Sponges",     id = 9253059640,      cat = "FIND",     icon = "ðŸ§½", accent = Color3.fromRGB(255,230,80) },
    { name = "Find the Doughnuts",   id = 13233489398,     cat = "FIND",     icon = "ðŸ©", accent = Color3.fromRGB(255,160,180) },
    { name = "Find the Ducks",       id = 13135948259,     cat = "FIND",     icon = "ðŸ¦†", accent = Color3.fromRGB(255,220,80) },
    { name = "Find the Frogs",       id = 11968070072,     cat = "FIND",     icon = "ðŸ¸", accent = Color3.fromRGB(120,200,90) },
    { name = "Find the Penguins",    id = 13492294284,     cat = "FIND",     icon = "ðŸ§", accent = Color3.fromRGB(90,90,110) },
    { name = "Find the Bees",        id = 12472303416,     cat = "FIND",     icon = "ðŸ", accent = Color3.fromRGB(255,210,60) },
    { name = "Find the Aliens",      id = 12892036628,     cat = "FIND",     icon = "ðŸ‘½", accent = Color3.fromRGB(120,230,120) },
    { name = "Find the Sharks",      id = 13713777623,     cat = "FIND",     icon = "ðŸ¦ˆ", accent = Color3.fromRGB(120,150,180) },
    { name = "Find the Crabs",       id = 12942147556,     cat = "FIND",     icon = "ðŸ¦€", accent = Color3.fromRGB(255,120,80) },
    { name = "Find the Fish",        id = 13596206537,     cat = "FIND",     icon = "ðŸŸ", accent = Color3.fromRGB(100,180,230) },
    { name = "Find the Axolotls",    id = 13255573105,     cat = "FIND",     icon = "ðŸ¦Ž", accent = Color3.fromRGB(255,150,180) },
    -- ADDITIONAL POPULAR GAMES
    { name = "Strucid",              id = 4312516504,      cat = "FPS",      icon = "ðŸ”«", accent = Color3.fromRGB(120,180,255) },
    { name = "Apocalypse Rising",    id = 150284569,       cat = "SURVIVAL", icon = "ðŸ§Ÿ", accent = Color3.fromRGB(120,140,90) },
    { name = "Vehicle Legends",      id = 5280602993,      cat = "SIMULATOR",icon = "ðŸŽï¸", accent = Color3.fromRGB(255,90,90) },
    { name = "Twitch Strategies",    id = 4991835277,      cat = "STRATEGY", icon = "ðŸŽ®", accent = Theme.Accent },
    { name = "Roblox High School 2", id = 5753242311,      cat = "RP",       icon = "ðŸ«", accent = Color3.fromRGB(255,120,180) },
    { name = "Gym Simulator",        id = 10643543180,     cat = "SIMULATOR",icon = "ðŸ’ª", accent = Color3.fromRGB(245,196,76) },
    { name = "Clicker Simulator",    id = 8304985481,      cat = "SIMULATOR",icon = "ðŸ–±ï¸", accent = Color3.fromRGB(245,196,76) },
    { name = "Race Clicker",         id = 9148658448,      cat = "SIMULATOR",icon = "ðŸ", accent = Color3.fromRGB(120,180,255) },
    { name = "Boxing Simulator",     id = 5783732991,      cat = "SIMULATOR",icon = "ðŸ¥Š", accent = Color3.fromRGB(245,196,76) },
    { name = "Weapon Forge",         id = 0,               cat = "SIMULATOR",icon = "ðŸ”¨", accent = Color3.fromRGB(180,180,200) },
    { name = "Color Block",          id = 14482119176,     cat = "SURVIVAL", icon = "ðŸŸ©", accent = Color3.fromRGB(76,209,142) },
    { name = "Hide and Seek",        id = 6232652248,      cat = "ACTION",   icon = "ðŸ™ˆ", accent = Theme.Accent },
    { name = "Rocket / Launch",      id = 0,               cat = "SANDBOX",  icon = "ðŸš€", accent = Color3.fromRGB(220,220,220) },
    { n