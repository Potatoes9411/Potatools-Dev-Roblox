
--// DRAGON ADVENTURES
--==============================================================================
local function DragonAdventures()
    local w = createWindow("Dragon Adventures", "Dragon Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Feed Dragon", false, function(v) w._feed = v end)
    w:AddToggle("Auto Incubate Eggs", false, function(v) w._incubate = v end)
    w:AddToggle("Auto Collect Resources", false, function(v) w._collect = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Egg / Resource ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddSection("Teleport")
    local isl = { { "Spawn", Vector3.new(0, 50, 0) }, { "Volcano", Vector3.new(1500, 80, 0) }, { "Desert", Vector3.new(-1500, 80, 0) }, { "Tundra", Vector3.new(0, 80, 1500) } }
    for _, i in ipairs(isl) do w:AddButton("TP: " .. i[1], function() teleportTo(i[2]) end) end
    task.spawn(function()
        while true do
            task.wait(0.5)
            local root = getRoot()
            if w._feed then fireRemotes("feed") end
            if w._incubate then fireRemotes("incubate"); fireRemotes("hatch") end
            if w._collect and root then touchNamed(root, { "resource", "material", "egg", "food" }, 120) end
            if w._eEsp then highlightKeywords({ "egg", "resource", "material", "food" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Dragon Adventures", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// CREATURES OF SONARIA
--==============================================================================
local function CreaturesOfSonaria()
    local w = createWindow("Creatures of Sonaria", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Auto Eat / Drink", false, function(v) w._eat = v end)
    w:AddToggle("Auto Grow (stay alive)", false, function(v) w._grow = v end)
    w:AddSlider("Food Range", 20, 400, 120, "studs", 0, function(v) w._frange = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Creature / Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Food / Water ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            local root = getRoot()
            if w._eat and root then touchNamed(root, { "food", "meat", "berry", "water", "drink", "fish" }, w._frange or 120) end
            if w._grow then
                local h = getHum(); if h then h.Health = h.MaxHealth end
            end
            if w._fEsp then highlightKeywords({ "food", "meat", "berry", "water", "drink", "fish" }, Color3.fromRGB(76, 209, 142)) end
        end
    end)
    notify("Creatures of Sonaria", "Loaded.", 3, Color3.fromRGB(120, 200, 120))
    return w
end

--==============================================================================
--// MEEPCITY
--==============================================================================
local function MeepCity()
    local w = createWindow("MeepCity", "RP Suite", 460, 520, randPos())
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Coin / Star ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    w:AddSection("Teleport")
    local m = { { "Plaza", Vector3.new(0, 5, 0) }, { "Party", Vector3.new(80, 5, 40) }, { "School", Vector3.new(-90, 5, -40) }, { "Hospital", Vector3.new(120, 5, 90) } }
    for _, l in ipairs(m) do w:AddButton("TP: " .. l[1], function() teleportTo(l[2]) end) end
    task.spawn(function()
        while true do
            task.wait(0.8)
            if w._cEsp then highlightKeywords({ "coin", "star", "money", "candy" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("MeepCity", "Loaded.", 3, Color3.fromRGB(255, 120, 180))
    return w
end

--==============================================================================
--// RO-GHOUL
--==============================================================================
local function RoGhoul()
    local w = createWindow("Ro-Ghoul", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest NPC", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    w:AddSlider("Aura Range", 3, 60, 18, "studs", 0, function(v) w._arange = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Boss / NPC ESP", false, function(v) w._nEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
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
                if w._aura then
                    for _, t in ipairs(getTargetsInRange(w._arange or 18, true, true)) do swingTool() end
                end
                if w._nEsp then highlightKeywords({ "boss", "enemy", "npc", "ghoul" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Ro-Ghoul", "Loaded.", 3, Color3.fromRGB(180, 60, 60))
    return w
end

--==============================================================================
--// DEMONFALL
--==============================================================================
local function Demonfall()
    local w = createWindow("Demonfall", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm NPCs", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
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
                        if dist > (w._range or 40) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 40), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._iEsp then highlightKeywords({ "chest", "item", "gourd", "breathing" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Demonfall", "Loaded.", 3, Color3.fromRGB(180, 80, 120))
    return w
end

--==============================================================================
--// DRAGON BALL Z: FINAL STAND
--==============================================================================
local function DBZFinalStand()
    local w = createWindow("DBZ Final Stand", "Train & Fight Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm NPCs", false, function(v) w._farm = v end)
    w:AddToggle("Ki Blast Spam", false, function(v) w._ki = v end)
    w:AddSlider("Farm Range", 10, 400, 60, "studs", 0, function(v) w._range = v end)
    w:AddSection("Training")
    w:AddToggle("Auto Train (punch)", false, function(v) w._train = v end)
    w:AddToggle("Infinite Ki (best-effort)", false, function(v) w._kiInf = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm or w._ki then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if w._farm and dist > (w._range or 60) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 60), 25) end)
                        end
                        swingTool()
                        if w._ki then fireRemotes("blast"); fireRemotes("ki"); fireRemotes("energy") end
                    end
                end
                if w._train then swingTool() end
                if w._kiInf then trySetStat("ki", 1e9); trySetStat("energy", 1e9) end
                if w._eEsp then highlightKeywords({ "enemy", "boss", "saiyan", "frieza" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("DBZ Final Stand", "Loaded.", 3, Color3.fromRGB(255, 160, 40))
    return w
end

--==============================================================================
--// BREAK IN (Story)
--==============================================================================
local function BreakIn()
    local w = createWindow("Break In", "Story Survival Suite", 470, 540, randPos())
    w:AddSection("Survival")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy / Killer ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Item / Food ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Collect Food", false, function(v) w._food = v end)
    w:AddSection("Movement")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 150, 35, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Eat (re-fill health)", false, function(v) w._heal = v end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._eEsp then highlightKeywords({ "enemy", "killer", "scary", "monster", "intruder" }, Color3.fromRGB(255, 40, 50)) end
            if w._iEsp then highlightKeywords({ "food", "apple", "cookie", "key", "weapon", "batteries" }, Color3.fromRGB(255, 200, 40)) end
            if w._food and root then touchNamed(root, { "food", "apple", "cookie", "batteries" }, 60) end
            if w._heal then local h = getHum(); if h then h.Health = h.MaxHealth end end
        end
    end)
    notify("Break In", "Loaded.", 3, Color3.fromRGB(180, 120, 120))
    return w
end

--==============================================================================
--// EMERGENCY RESPONSE: LIBERTY COUNTY
--==============================================================================
local function ERLC()
    local w = createWindow("ER: Liberty County", "Roleplay Suite", 470, 540, randPos())
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Vehicle ESP", false, function(v) w._vEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddButton("Fullbright", function() Lighting.Brightness = 2; Lighting.ClockTime = 14 end)
    w:AddSection("Teleport")
    local e = { { "Spawn", Vector3.new(0, 5, 0) }, { "Hospital", Vector3.new(120, 5, 40) }, { "Gas Station", Vector3.new(-160, 5, 90) }, { "Police Dept", Vector3.new(80, 5, -120) } }
    for _, l in ipairs(e) do w:AddButton("TP: " .. l[1], function() teleportTo(l[2]) end) end
    task.spawn(function()
        while true do
            task.wait(0.8)
            if w._vEsp then highlightKeywords({ "car", "vehicle", "truck", "police", "ambulance" }, Color3.fromRGB(120, 200, 255)) end
        end
    end)
    notify("ER: Liberty County", "Loaded.", 3, Color3.fromRGB(70, 150, 255))
    return w
end

--==============================================================================
--// SCP: ROLEPLAY
--==============================================================================
local function SCPRoleplay()
    local w = buildFPSWindow("SCP Roleplay", Color3.fromRGB(180, 60, 60))
    w:AddSection("SCP Extras")
    w:AddToggle("SCP / Monster ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Keycard ESP", false, function(v) w._kEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.8)
            if w._sEsp then highlightKeywords({ "scp", "monster", "173", "049", "096", "106", "939" }, Color3.fromRGB(255, 40, 50)) end
            if w._kEsp then highlightKeywords({ "keycard", "card", "item", "weapon" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    return w
end

--==============================================================================
--// CAMPING (Story)
--==============================================================================
local function Camping()
    local w = createWindow("Camping", "Story Survival Suite", 460, 500, randPos(460, 500))
    w:AddSection("Survival")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Monster / Killer ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Item ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    addMovement(w, 150, 300)
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._mEsp then highlightKeywords({ "monster", "killer", "zach", "nightmonster" }, Color3.fromRGB(255, 40, 50)) end
            if w._iEsp then highlightKeywords({ "item", "food", "flashlight", "key", "bandage" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Camping", "Loaded.", 3, Color3.fromRGB(120, 180, 100))
    return w
end

--==============================================================================
--// FISH GAME / SQUID GAME
--==============================================================================
local function FishGame()
    local w = createWindow("Fish Game", "Survival Suite", 460, 520, randPos())
    w:AddSection("Minigames")
    w:AddToggle("Red Light Green Light Helper", false, function(v) w._rlgl = v end, "Freezes you (Noclip) when red")
    w:AddToggle("Show Safe Path", false, function(v) w._safeEsp = v; if not v then clearAutoHL() end end)
    addMovement(w, 150, 250)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._rlgl and root then
                -- heuristic: when lighting turns red, stop
                local t = Lighting.ClockTime
                if t > 5 then
                    root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                end
            end
            if w._safeEsp then highlightKeywords({ "safe", "green", "glass", "goal", "finish" }, Color3.fromRGB(76, 209, 142)) end
        end
    end)
    notify("Fish Game", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// HIDE AND SEEK
--==============================================================================
local function HideAndSeek()
    local w = createWindow("Hide and Seek", "Tag Suite", 460, 500, randPos(460, 500))
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Seeker ESP (Red)", false, function(v) w._sEsp = v end)
    w:AddSection("Movement")
    addMovement(w, 200, 350)
    w:AddSection("Auto")
    w:AddToggle("Auto Tag Nearest", false, function(v) w._tag = v end)
    w:AddSlider("Tag Range", 3, 30, 8, "studs", 0, function(v) w._trange = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._sEsp then
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if plr ~= LocalPlayer and plr.Character then
                            local hasWeapon
                            for _, t in ipairs(plr.Character:GetChildren()) do
                                if t:IsA("Tool") and (t.Name:lower():find("seek") or t.Name:lower():find("tag") or t.Name:lower():find("bat")) then hasWeapon = true end
                            end
                            if hasWeapon then
                                local hl = plr.Character:FindFirstChild("ESP_HL")
                                if hl then hl.FillColor = Color3.fromRGB(255, 40, 50) end
                            end
                        end
                    end
                end
                if w._tag then
                    for _, t in ipairs(getTargetsInRange(w._trange or 8, false, true)) do swingTool() end
                end
            end
        end
    end)
    notify("Hide and Seek", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// CONFIG PERSISTENCE  (Vape-style profile save/load, executor-shimmed)
--==============================================================================
local ConfigStore = {}
local CFG_FILE = "MultiGameHub_Config.json"
function ConfigStore.save(tbl)
    pcall(function()
        local json = HttpService:JSONEncode(tbl or {})
        if writefile then writefile(CFG_FILE, json) end
    end)
end
function ConfigStore.load()
    local ok, res = pcall(function()
        if not (isfile and isfile(CFG_FILE)) then return {} end
        return HttpService:JSONDecode(readfile(CFG_FILE))
    end)
    if ok and type(res) == "table" then return res end
    return {}
end
function ConfigStore.gather()
    local snap = {
        ESP = ESP.Config,
        Aimbot = Aimbot.Config,
        Triggerbot = Triggerbot.Config,
        Hitbox = Hitbox.Config,
        Movement = {
            WalkSpeed = Movement.WalkSpeed, JumpPower = Movement.JumpPower,
            InfJump = Movement.InfJump, Noclip = Movement.Noclip, Fly = Movement.Fly,
        },
    }
    local modules = {}
    for name, m in pairs(Modules) do modules[name] = { Enabled = m.Enabled, Settings = m.Settings } end
    snap.Modules = modules
    return snap
end
function ConfigStore.apply(snap)
    if not snap then return end
    pcall(function()
        if snap.Aimbot then for k, v in pairs(snap.Aimbot) do Aimbot.Config[k] = v end end
        if snap.Movement then
            if snap.Movement.WalkSpeed then Movement.WalkSpeed.Value = snap.Movement.WalkSpeed.Value or Movement.WalkSpeed.Value end
            if snap.Movement.Fly then Movement.Fly.Speed = snap.Movement.Fly.Speed or Movement.Fly.Speed end
        end
        if snap.Modules then
            for name, info in pairs(snap.Modules) do
                local m = Modules[name]
                if m then
                    if info.Settings then for k, v in pairs(info.Settings) do m.Settings[k] = v end end
                    if info.Enabled then m:Set(true) end
                end
            end
        end
    end)
end

--==============================================================================
--// WORLD ZERO
--==============================================================================
local function WorldZero()
    local w = createWindow("World Zero", "RPG Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest Enemy", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 400)
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
                if w._cEsp then highlightKeywords({ "chest", "item", "loot", "crystal", "gem" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("World Zero", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// ISLE
--==============================================================================
local function Isle()
    local w = createWindow("Isle", "Mystery Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Monster / Enemy ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Item / Loot ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Auto Collect Items", false, function(v) w._loot = v end)
    addMovement(w, 150, 300)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._mEsp then highlightKeywords({ "monster", "enemy", "creature", "loper", "rat" }, Color3.fromRGB(255, 40, 50)) end
            if w._iEsp then highlightKeywords({ "item", "loot", "food", "key", "weapon", "fuel" }, Color3.fromRGB(255, 200, 40)) end
            if w._loot and root then touchNamed(root, { "item", "loot", "food", "key", "weapon", "fuel" }, 80) end
        end
    end)
    notify("Isle", "Loaded.", 3, Color3.fromRGB(120, 160, 140))
    return w
end

--==============================================================================
--// RUMBLE QUEST
--==============================================================================
local function RumbleQuest()
    local w = buildFPSWindow("Rumble Quest", Color3.fromRGB(150, 120, 255))
    w:AddSection("Rumble Extras")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 5, 60, 22, "studs", 0, function(v) w._arange = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 22, true, true)) do swingTool() end end
        end
    end)
    return w
end

--==============================================================================
--// RO-BIO / ROBLOX HIGH (extra RP)
--==============================================================================
local function RoCitizens()
    local w = createWindow("RoCitizens", "RP Suite", 470, 540, randPos(470, 540))
    w:AddSection("Movement")
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Box ESP", false, function(v) BoxESP:Set(v) end)
    w:AddToggle("Radar", false, function(v) Radar:Set(v) end)
    w:AddToggle("Fullbright", false, function(v) Fullbright:Set(v) end)
    w:AddToggle("Atmosphere FX", false, function(v) AtmosphereMod:Set(v) end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Anti-AFK Walk", false, function(v) AntiAFKWalk:Set(v) end)
    w:AddToggle("Auto Dance", false, function(v) w._dance = v end)
    w:AddToggle("Auto Chat", false, function(v) w._chat = v end)
    w:AddInput("Chat Message", "Hi!", "", function(v) w._msg = v end)
    w:AddSection("Cosmetics")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end)
    w:AddToggle("China Hat", false, function(v) ChinaHat:Set(v) end)
    w:AddToggle("Breadcrumbs", false, function(v) Breadcrumbs:Set(v) end)
    w:AddSection("Server")
    w:AddButton("Server Hop", function() ServerHop.hop() end, Theme.Yellow)
    w:AddButton("Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.5)
            if w._chat and tick() - last >= 15 then
                last = tick()
                local msg = (w._msg and w._msg ~= "") and w._msg or "Hi!"
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
    notify("RoCitizens", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// THE SURVIVAL GAME
--==============================================================================
local function SurvivalGame()
    local w = createWindow("The Survival Game", "Open Survival Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest Enemy", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 300, 40, "studs", 0, function(v) w._range = v end)
    addMovement(w, 200, 400)
    w:AddSection("Survival")
    w:AddToggle("Auto Collect Resources", false, function(v) w._res = v end)
    w:AddSlider("Resource Range", 20, 400, 120, "studs", 0, function(v) w._rrange = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Resource ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.25)
            local root = getRoot()
            if root then
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
                if w._aura then for _, t in ipairs(getTargetsInRange(18, true, true)) do swingTool() end end
                if w._res then touchNamed(root, { "wood", "stone", "ore", "berry", "food" }, w._rrange or 120) end
                if w._rEsp then highlightKeywords({ "wood", "stone", "ore", "berry", "food", "tree" }, Color3.fromRGB(120, 200, 120)) end
            end
        end
    end)
    notify("The Survival Game", "Loaded.", 3, Color3.fromRGB(120, 180, 100))
    return w
end

--==============================================================================
--// TORNADO ALLEY / NATURAL SURVIVAL
--==============================================================================
local function TornadoAlley()
    local w = createWindow("Tornado Alley", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Auto Fly to Safety", false, function(v) w._safe = v end)
    w:AddSlider("Safe Height", 100, 1500, 500, "studs", 0, function(v) w._safeH = v end)
    w:AddToggle("Disaster Alert", false, function(v) w._alert = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            local root = getRoot()
            if w._safe and root then
                local danger = false
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("tornado") or n:find("lava") or n:find("fire") then danger = true end
                end
                if danger then
                    Movement.Fly.Enabled = true
                    root.CFrame = CFrame.new(root.Position + Vector3.new(0, (w._safeH or 500)/30, 0))
                end
            end
        end
    end)
    notify("Tornado Alley", "Loaded.", 3, Color3.fromRGB(150, 150, 160))
    return w
end

--==============================================================================
--// BUILD A BOAT FOR TREASURE
--==============================================================================
local function BoatTreasure()
    local w = createWindow("Build A Boat (Treasure)", "Sail Suite", 460, 520, randPos())
    w:AddSection("Sail")
    w:AddToggle("Auto Sail Forward", false, function(v) w._sail = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 500, 120, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddSection("Resources")
    w:AddToggle("Auto Collect Materials", false, function(v) w._mats = v end)
    w:AddSlider("Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    w:AddSection("Visuals")
    w:AddToggle("Treasure ESP", false, function(v) w._tEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._sail then root.CFrame = root.CFrame * CFrame.new(0, 0, -2) end
                if w._mats then touchNamed(root, { "block", "material", "wood", "gold" }, w._range or 150) end
                if w._tEsp then highlightKeywords({ "treasure", "chest", "gold" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Build A Boat (Treasure)", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// SPEED RUN / DASH
--==============================================================================
local function SpeedRun()
    local w = createWindow("Speed Run / Dash", "Speed Suite", 460, 500, randPos(460, 500))
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 300, 80, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddButton("Skip Forward 50", function() local r = getRoot(); if r then r.CFrame = r.CFrame * CFrame.new(0, 0, -50) end end)
    w:AddSection("Win")
    w:AddButton("TP to Finish", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("win") or n:find("portal") or n:find("trophy")) then by = d.Position.Y; best = d end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)) end
    end, Theme.Green)
    notify("Speed Run", "Loaded.", 3, Color3.fromRGB(120, 200, 255))
    return w
end

--==============================================================================
--// TYPING / WORD GAME
--==============================================================================
local function WordGame()
    local w = createWindow("Word / Typing Game", "Auto Type Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Type Common Words", false, function(v) w._type = v end)
    w:AddSlider("Type Delay", 0.2, 3, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    local words = { "the", "be", "to", "of", "and", "a", "in", "that", "have", "it", "for", "not", "on", "with", "he", "as", "you", "do", "at", "this", "but", "his", "by", "from", "they", "we", "say", "her", "she", "or", "an", "will", "my", "one", "all", "would", "there", "their", "what" }
    task.spawn(function()
        while true do
            task.wait(w._delay or 0.5)
            if w._type then
                pcall(function()
                    -- find any TextBox in the game's PlayerGui and type into it
                    for _, tb in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
                        if tb:IsA("TextBox") and tb.Visible then
                            tb.Text = words[math.random(1, #words)]
                            break
                        end
                    end
                end)
            end
        end
    end)
    notify("Word Game", "Loaded.", 3, Theme.Accent)
    return w
end

--==============================================================================
--// SNOWBALL / THROW GAME
--==============================================================================
local function SnowballGame()
    local w = createWindow("Snowball / Throw", "Throw Suite", 450, 480, randPos(450, 480))
    w:AddSection("Combat")
    w:AddToggle("Auto Throw (tool)", false, function(v) w._throw = v end)
    w:AddSlider("Throw Delay", 0.1, 2, 0.3, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Aimbot", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddSlider("Aim Smooth", 1, 100, 25, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            if w._throw and tick() - last >= (w._delay or 0.3) then
                last = tick()
                swingTool()
            end
        end
    end)
    notify("Snowball", "Loaded.", 3, Color3.fromRGB(150, 200, 255))
    return w
end

--==============================================================================
--// DYE / PAINT GAME
--==============================================================================
local function PaintGame()
    local w = createWindow("Paint / Dye Game", "Paint Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Paint (click)", false, function(v) w._paint = v end)
    w:AddToggle("Auto Claim", false, function(v) w._claim = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._paint then swingTool() end
            if w._claim then fireRemotes("claim") end
        end
    end)
    notify("Paint Game", "Loaded.", 3, Color3.fromRGB(255, 120, 200))
    return w
end

--==============================================================================
--// SURVIVE THE DISASTER (extra variant)
--==============================================================================
local function SurviveDisaster()
    local w = createWindow("Survive Disaster", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Auto Fly Up", false, function(v) w._fly = v end)
    w:AddSlider("Fly Height", 50, 1500, 400, "studs", 0, function(v) w._h = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Safe Zone ESP", false, function(v) w._sEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._fly then Movement.Fly.Enabled = true; root.CFrame = CFrame.new(root.Position + Vector3.new(0, (w._h or 400)/20, 0)) end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._sEsp then highlightKeywords({ "safe", "shelter", "bunker", "zone" }, Color3.fromRGB(76, 209, 142)) end
            end
        end
    end)
    notify("Survive Disaster", "Loaded.", 3, Theme.Blue)
    return w
end

--==============================================================================
--// MINERS / DIG GAME
--==============================================================================
local function DigGame()
    local w = createWindow("Dig / Mine Game", "Dig Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Dig (click)", false, function(v) w._dig = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Ore ESP", false, function(v) w._oEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.15)
            if w._dig then swingTool() end
            if w._sell then fireRemotes("sell") end
            if w._up then fireRemotes("upgrade"); fireRemotes("buy") end
            if w._oEsp then highlightKeywords({ "ore", "block", "diamond", "gold", "gem" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Dig Game", "Loaded.", 3, Color3.fromRGB(180, 140, 80))
    return w
end

--==============================================================================
--// ANIME RPG (GENERIC)
--==============================================================================
local function AnimeRPG()
    local w = createWindow("Anime RPG", "Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Enemies", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Use Skill", false, function(v) w._skill = v end)
    w:AddToggle("Auto Roll/Gacha", false, function(v) w._roll = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if root then
                if w._farm or w._aura then
                    local npc, dist = getNearestNPC(99999)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local hrp = npc.HumanoidRootPart
                        if w._farm and dist > (w._range or 50) then
                            pcall(function() root.CFrame = root.CFrame + (hrp.Position - root.Position).Unit * math.min(dist - (w._range or 50), 25) end)
                        end
                        swingTool()
                    end
                end
                if w._skill then fireRemotes("skill"); fireRemotes("attack") end
                if w._roll then fireRemotes("roll"); fireRemotes("gacha") end
                if w._eEsp then highlightKeywords({ "enemy", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Anime RPG", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// RPG / FANTASY GENERIC
--==============================================================================
local function FantasyRPG()
    local w = createWindow("Fantasy RPG", "Quest Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Accept Quest", false, function(v) w._quest = v end)
    w:AddToggle("Auto Sell Drops", false, function(v) w._sell = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Item ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.25)
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
                if w._quest then fireRemotes("quest"); fireRemotes("accept") end
                if w._sell then fireRemotes("sell") end
                if w._cEsp then highlightKeywords({ "chest", "item", "loot", "treasure" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Fantasy RPG", "Loaded.", 3, Color3.fromRGB(150, 120, 255))
    return w
end

--==============================================================================
--// VEHICLE SIMULATOR
--==============================================================================
local function VehicleSimulator()
    local w = createWindow("Vehicle Simulator", "Drive Suite", 460, 520, randPos())
    w:AddSection("Driving")
    w:AddToggle("Auto Drive (W)", false, function(v) w._drive = v end)
    w:AddToggle("Infinite Nitro", false, function(v) w._nitro = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 800, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Buy Vehicles", false, function(v) w._buy = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Coin ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if w._drive then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                end)
            end
            if w._nitro then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                end)
                fireRemotes("nitro")
            end
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "money", "pickup" }, w._range or 200) end
                if w._buy then fireRemotes("buy"); fireRemotes("vehicle") end
                if w._cEsp then highlightKeywords({ "coin", "cash", "money", "pickup", "chest" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Vehicle Simulator", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// TYCOON GENERIC
--==============================================================================
local function TycoonGeneric()
    local w = createWindow("Tycoon Helper", "Auto Tycoon", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Drops", false, function(v) w._collect = v end)
    w:AddSlider("Range", 20, 600, 200, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Buy Buttons", false, function(v) w._buy = v end)
    w:AddToggle("Auto Step on Pads", false, function(v) w._pads = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Cash / Drop ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._collect then touchNamed(root, { "cash", "money", "drop", "coin", "pickup" }, w._range or 200) end
                if w._buy then fireRemotes("buy"); fireRemotes("purchase") end
                if w._pads then touchNamed(root, { "button", "pad", "purchase", "buy" }, 30) end
                if w._dEsp then highlightKeywords({ "cash", "money", "drop", "coin", "pickup" }, Color3.fromRGB(120, 220, 120)) end
            end
        end
    end)
    notify("Tycoon Helper", "Loaded.", 3, Color3.fromRGB(120, 220, 120))
    return w
end

--==============================================================================
--// FISHING GAME GENERIC
--==============================================================================
local function FishingGame()
    local w = createWindow("Fishing Game", "Auto Fish Suite", 450, 500, randPos(450, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Cast (click)", false, function(v) w._cast = v end)
    w:AddSlider("Cast Delay", 0.5, 5, 1, "s", 1, function(v) w._delay = v end)
    w:AddToggle("Auto Reel (click)", false, function(v) w._reel = v end)
    w:AddToggle("Auto Sell Fish", false, function(v) w._sell = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Fish Spot ESP", false, function(v) w._fEsp = v; if not v then clearAutoHL() end end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._cast and tick() - last >= (w._delay or 1) then
                last = tick()
                swingTool()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
            if w._reel then swingTool() end
            if w._sell then fireRemotes("sell") end
            if w._fEsp then highlightKeywords({ "fish", "water", "spot", "ripple" }, Color3.fromRGB(86, 156, 240)) end
        end
    end)
    notify("Fishing Game", "Loaded.", 3, Color3.fromRGB(86, 156, 240))
    return w
end

--==============================================================================
--// PORTAL / SCIENCE GAME
--==============================================================================
local function PortalGame()
    local w = createWindow("Portal / Science", "Puzzle Suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto")
    w:AddToggle("Auto Complete (click)", false, function(v) w._click = v end)
    w:AddToggle("Auto Walk Through Doors", false, function(v) w._doors = v end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Exit / Goal ESP", false, function(v) w._gEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._click then swingTool() end
                if w._doors then touchNamed(root, { "door", "exit", "goal", "portal", "button" }, 40) end
                if w._gEsp then highlightKeywords({ "exit", "goal", "portal", "elevator", "finish" }, Color3.fromRGB(76, 209, 142)) end
            end
        end
    end)
    notify("Portal / Science", "Loaded.", 3, Color3.fromRGB(120, 180, 200))
    return w
end

--==============================================================================
--// ROCKET / LAUNCH GAME
--==============================================================================
local function RocketGame()
    local w = createWindow("Rocket / Launch", "Build Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Parts", false, function(v) w._parts = v end)
    w:AddSlider("Range", 20, 600, 150, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Launch", false, function(v) w._launch = v end)
    addMovement(w, 250, 500)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Part ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._parts then touchNamed(root, { "part", "material", "engine", "fuel", "metal" }, w._range or 150) end
                if w._launch then fireRemotes("launch"); fireRemotes("start") end
                if w._pEsp then highlightKeywords({ "part", "material", "engine", "fuel", "metal" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Rocket / Launch", "Loaded.", 3, Color3.fromRGB(220, 220, 220))
    return w
end

--==============================================================================
--// PAINTBALL (generic)
--==============================================================================
local function PaintballGeneric()
    local w = buildFPSWindow("Paintball", Color3.fromRGB(120, 200, 255))
    w:AddSection("Paintball Extras")
    w:AddToggle("Auto Reload", false, function(v) w._reload = v end)
    task.spawn(function()
        while true do
            task.wait(1)
            if w._reload then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
                end)
            end
        end
    end)
    return w
end

--==============================================================================
--// OBBY 2 / DIFFICULT PARKOUR
--==============================================================================
local function ParkourObby()
    local w = createWindow("Difficult Parkour", "Obby Suite", 460, 540, randPos())
    w:AddSection("Movement")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 400, 90, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 500, 150, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
    w:AddButton("TP Forward 30", function() local r = getRoot(); if r then r.CFrame = r.CFrame * CFrame.new(0, 0, -30) end end)
    w:AddButton("TP Up 100", function() local r = getRoot(); if r then r.CFrame = r.CFrame + Vector3.new(0, 100, 0) end end)
    w:AddSection("Safety")
    w:AddToggle("Disable Kill Bricks", false, function(v) w._noKill = v end)
    w:AddToggle("Disable Lava", false, function(v) w._noLava = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    w:AddSection("Win")
    w:AddButton("Find & TP to End", function()
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                local n = d.Name:lower()
                if d.Position.Y > by and (n:find("finish") or n:find("end") or n:find("win") or n:find("portal") or n:find("checkpoint")) then
                    by = d.Position.Y; best = d
                end
            end
        end
        if best then teleportTo(best.Position + Vector3.new(0, 5, 0)); notify("Parkour", "Teleported near end.", 3, Theme.Green)
        else notify("Parkour", "No end found.", 3, Theme.Yellow) end
    end, Theme.Green)
    task.spawn(function()
        while true do
            task.wait(0.3)
            pcall(function()
                for _, d in ipairs(Workspace:GetDescendants()) do
                    if d:IsA("BasePart") then
                        local n = d.Name:lower()
                        if (w._noKill or w._noLava) and (n:find("kill") or n:find("lava") or n:find("danger")) then d.CanTouch = false end
                    end
                end
            end)
            if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
        end
    end)
    notify("Difficult Parkour", "Loaded.", 3, Theme.Green)
    return w
end

--==============================================================================
--// COOKING GAME GENERIC
--==============================================================================
local function CookingGame()
    local w = createWindow("Cooking Game", "Cook Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Cook (click)", false, function(v) w._cook = v end)
    w:AddToggle("Auto Serve", false, function(v) w._serve = v end)
    w:AddToggle("Auto Collect Ingredients", false, function(v) w._ing = v end)
    w:AddToggle("Auto Serve Customers", false, function(v) w._cust = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Ingredient ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._cook then swingTool() end
            if w._serve then fireRemotes("serve"); fireRemotes("deliver") end
            if root and w._ing then touchNamed(root, { "ingredient", "food", "tomato", "cheese", "meat" }, 60) end
            if w._cust then fireRemotes("order"); fireRemotes("customer") end
            if w._iEsp then highlightKeywords({ "ingredient", "food", "tomato", "cheese", "meat" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Cooking Game", "Loaded.", 3, Color3.fromRGB(255, 160, 80))
    return w
end

--==============================================================================
--// DELIVERY / JOB GAME
--==============================================================================
local function DeliveryGame()
    local w = createWindow("Delivery / Job", "Work Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Deliver (touch)", false, function(v) w._deliver = v end)
    w:AddSlider("Range", 20, 400, 100, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Collect Packages", false, function(v) w._collect = v end)
    w:AddToggle("Auto Get Cash", false, function(v) w._cash = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Package / Drop ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._deliver then touchNamed(root, { "deliver", "dropoff", "destination", "house", "customer" }, w._range or 100) end
                if w._collect then touchNamed(root, { "package", "box", "crate", "pickup" }, w._range or 100) end
                if w._cash then touchNamed(root, { "cash", "money", "reward" }, 40) end
                if w._dEsp then highlightKeywords({ "package", "box", "crate", "pickup", "deliver", "cash" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Delivery / Job", "Loaded.", 3, Color3.fromRGB(120, 180, 255))
    return w
end

--==============================================================================
--// CRAFTING / SURVIVAL SANDBOX
--==============================================================================
local function CraftingSandbox()
    local w = createWindow("Survival Sandbox", "Craft Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Gather", false, function(v) w._gather = v end)
    w:AddSlider("Range", 20, 500, 150, "studs", 0, function(v) w._range = v end)
    w:AddToggle("Auto Craft", false, function(v) w._craft = v end)
    w:AddToggle("Auto Eat", false, function(v) w._eat = v end)
    addMovement(w, 250, 400)
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 3, 40, 18, "studs", 0, function(v) w._arange = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Resource ESP", false, function(v) w._rEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._gather then touchNamed(root, { "wood", "stone", "ore", "berry", "tree", "rock", "iron" }, w._range or 150) end
                if w._craft then fireRemotes("craft"); fireRemotes("build") end
                if w._eat then fireRemotes("eat"); fireRemotes("consume") end
                if w._aura then for _, t in ipairs(getTargetsInRange(w._arange or 18, true, true)) do swingTool() end end
                if w._rEsp then highlightKeywords({ "wood", "stone", "ore", "berry", "tree", "rock", "iron", "gold" }, Color3.fromRGB(120, 200, 120)) end
            end
        end
    end)
    notify("Survival Sandbox", "Loaded.", 3, Color3.fromRGB(120, 180, 100))
    return w
end

--==============================================================================
--// RACING GAME GENERIC
--==============================================================================
local function RacingGame()
    local w = createWindow("Racing Game", "Drive Suite", 460, 500, randPos(460, 500))
    w:AddSection("Driving")
    w:AddToggle("Auto Accelerate (W)", false, function(v) w._accel = v end)
    w:AddToggle("Infinite Nitro", false, function(v) w._nitro = v end)
    w:AddToggle("Auto Steer (best-effort)", false, function(v) w._steer = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end)
    w:AddSlider("Range", 20, 800, 200, "studs", 0, function(v) w._range = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Checkpoint ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._accel then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game) end
            if w._nitro then VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game); fireRemotes("nitro") end
            if root then
                if w._coins then touchNamed(root, { "coin", "cash", "pickup" }, w._range or 200) end
                if w._cEsp then highlightKeywords({ "checkpoint", "finish", "lap", "flag" }, Color3.fromRGB(255, 200, 40)) end
            end
        end
    end)
    notify("Racing Game", "Loaded.", 3, Color3.fromRGB(255, 120, 80))
    return w
end

--==============================================================================
--// HORROR GAME GENERIC
--==============================================================================
local function HorrorGame()
    local w = createWindow("Horror Game", "Survival Suite", 460, 520, randPos())
    w:AddSection("ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Monster / Enemy ESP", false, function(v) w._mEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Item / Key ESP", false, function(v) w._iEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Exit / Door ESP", false, function(v) w._dEsp = v; if not v then clearAutoHL() end end)
    w:AddSection("Safety")
    w:AddToggle("Auto Run From Monster", false, function(v) w._run = v end)
    w:AddSlider("Safe Distance", 20, 200, 60, "studs", 0, function(v) w._safe = v end)
    w:AddToggle("God Mode", false, function(v) w._god = v end)
    addMovement(w, 200, 400)
    task.spawn(function()
        while true do
            task.wait(0.3)
            local root = getRoot()
            if root then
                if w._mEsp then highlightKeywords({ "monster", "enemy", "killer", "creature", "slender", "entity" }, Color3.fromRGB(255, 40, 50)) end
                if w._iEsp then highlightKeywords({ "item", "key", "battery", "flashlight", "bandage", "ammo" }, Color3.fromRGB(255, 200, 40)) end
                if w._dEsp then highlightKeywords({ "exit", "door", "escape", "elevator", "gate" }, Color3.fromRGB(76, 209, 142)) end
                if w._god then local h = getHum(); if h then h.Health = h.MaxHealth end end
                if w._run then
                    local npc, dist = getNearestNPC(w._safe or 60)
                    if npc and npc:FindFirstChild("HumanoidRootPart") then
                        local dir = root.Position - npc.HumanoidRootPart.Position
                        if dir.Magnitude > 0 then pcall(function() root.CFrame = root.CFrame + dir.Unit * 14 end) end
                    end
                end
            end
        end
    end)
    notify("Horror Game", "Loaded.", 3, Color3.fromRGB(180, 60, 80))
    return w
end

--==============================================================================
--// TRADING / ECONOMY GAME
--==============================================================================
local function TradingGame()
    local w = createWindow("Trading / Economy", "Trade Suite", 450, 480, randPos(450, 480))
    w:AddSection("Auto")
    w:AddToggle("Auto Buy Low", false, function(v) w._buy = v end)
    w:AddToggle("Auto Sell High", false, function(v) w._sell = v end)
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Cash / Item ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.5)
            local root = getRoot()
            if w._buy then fireRemotes("buy"); fireRemotes("purchase") end
            if w._sell then fireRemotes("sell"); fireRemotes("trade") end
            if root and w._cash then touchNamed(root, { "cash", "coin", "money", "gold" }, 60) end
            if w._cEsp then highlightKeywords({ "cash", "coin", "money", "gold", "item", "shop" }, Color3.fromRGB(120, 220, 120)) end
        end
    end)
    notify("Trading / Economy", "Loaded.", 3, Color3.fromRGB(120, 220, 120))
    return w
end

--==============================================================================
--// SKATING / SPORT GAME
--==============================================================================
local function SportGame()
    local w = createWindow("Sport / Skate", "Trick Suite", 450, 480, randPos(450, 480))
    w:AddSection("Movement")
    w:AddToggle("Speed Boost", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Trick (click)", false, function(v) w._trick = v end)
    w:AddToggle("Auto Score", false, function(v) w._score = v end)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if w._trick then swingTool() end
            if w._score then fireRemotes("score"); fireRemotes("goal") end
        end
    end)
    notify("Sport / Skate", "Loaded.", 3, Color3.fromRGB(120, 200, 255))
    return w
end

--==============================================================================
--// SOLS RNG
--==============================================================================
local function SolsRNG()
    local w = createWindow("Sols RNG", "Auto Roll Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end)
    w:AddSlider("Roll Delay", 0.1, 5, 0.5, "s", 2, function(v) w._delay = v end)
    w:AddToggle("Auto Equip Best Aura", false, function(v) w._equip = v end)
    w:AddToggle("Auto Re-roll", false, function(v) w._reroll = v end)
    w:AddSection("Rarity ESP")
    w:AddToggle("Rare Aura ESP", false, function(v) w._aEsp = v; if not v then clearAutoHL() end end)
    addMovement(w, 200, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    local last = 0
    task.spawn(function()
        while true do
            task.wait(0.1)
            if w._roll and tick() - last >= (w._delay or 0.5) then
                last = tick()
                fireRemotes("roll"); fireRemotes("rng")
            end
            if w._equip then fireRemotes("equip"); fireRemotes("aura") end
            if w._reroll then fireRemotes("reroll") end
            if w._aEsp then highlightKeywords({ "aura", "rare", "legendary", "mythic", "divine" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    notify("Sols RNG", "Loaded.", 3, Color3.fromRGB(180, 140, 255))
    return w
end

--==============================================================================
--// TYPE SOUL
--==============================================================================
local function TypeSoul()
    local w = createWindow("Type Soul", "Farm & Raid Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm NPCs", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Quest", false, function(v) w._quest = v end)
    w:AddToggle("Auto Raid (join)", false, function(v) w._raid = v end)
    w:AddToggle("Auto Use Skill", false, function(v) w._skill = v end)
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
                if w._aura then for _, t in ipairs(getTargetsInRange(20, true, true)) do swingTool() end end
                if w._quest then fireRemotes("quest"); fireRemotes("accept") end
                if w._raid then fireRemotes("raid"); fireRemotes("join") end
                if w._skill then fireRemotes("skill"); fireRemotes("ability") end
                if w._eEsp then highlightKeywords({ "enemy", "boss", "npc", "hollow", "arrancar" }, Color3.fromRGB(255, 60, 60)) end
            end
        end
    end)
    notify("Type Soul", "Loaded.", 3, Color3.fromRGB(180, 120, 255))
    return w
end

--==============================================================================
--// ANIME DEFENDERS
--==============================================================================
local function AnimeDefenders()
    local w = createWindow("Anime Defenders", "Auto-Play Suite", 470, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Place Units", false, function(v) w._place = v end)
    w:AddToggle("Auto Upgrade", false, function(v) w._up = v end)
    w:AddToggle("Auto Sell Units", false, function(v) w._sell = v end)
    w:AddToggle("Auto Start Wave", false, function(v) w._wave = v end)
    w:AddToggle("Auto Replay", false, function(v) w._replay = v end)
    addMovement(w, 200, 350)
    w:AddSection("Visuals")
    w:AddToggle("Enemy ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end end)
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            if w._place then fireRemotes("place"); fireRemotes("deploy") end
            if w._up then fireRemotes("upgrade") end
            if w._sell then fireRemotes("sell") end
            if w._wave then fireRemotes("start"); fireRemotes("wave") end
            if w._replay then fireRemotes("replay"); fireRemotes("restart") end
            if w._eEsp then highlightKeywords({ "enemy", "boss", "mob" }, Color3.fromRGB(255, 60, 60)) end
        end
    end)
    notify("Anime Defenders", "Loaded.", 3, Color3.fromRGB(150, 120, 255))
    return w
end

--==============================================================================
--// DUNGEON QUEST
--==============================================================================
local function DungeonQuest()
    local w = createWindow("Dungeon Quest", "Dungeon Farm Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Mobs", false, function(v) w._farm = v end)
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Farm Range", 10, 400, 50, "studs", 0, function(v) w._range = v end)
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Loot", false, function(v) w._loot = v end)
    w:AddToggle("Auto Sell", false, function(v) w._sell = v end)
    addMovement(w, 250, 400)
    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Chest / Loot ESP", false, function(v) w._cEsp = v; if not v then clearAutoHL() end end)
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
                if w._loot then touchNamed(root, { "loot", "chest", "item", "gold" }, 100) end
                if w._sell t