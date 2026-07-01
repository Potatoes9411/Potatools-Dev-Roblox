me.Yellow)
    task.spawn(function()
        while true do
            task.wait()
            if w._fastResp and not isAlive() then
                task.wait(0.5)
                pcall(function() LocalPlayer:LoadCharacter() end)
            end
        end
    end)
    return w
end

--===== UNIVERSAL =====
local function Universal()
    local w = createWindow("Universal", "Works in every game", 480, 560,
        UDim2.new(0.5, -240 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Walk Speed", 16, 500, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 500, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD/Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, 600, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)

    w:AddSection("Combat")
    w:AddToggle("Aimbot", false, function(v) Aimbot.Config.Enabled = v end)
    w:AddSlider("Aim Smoothness", 1, 100, 25, "%", 0, function(v) Aimbot.Config.Smoothness = v / 100 end)
    w:AddSlider("Aimbot FOV", 20, 800, 120, "px", 0, function(v) Aimbot.Config.FOV = v end)
    w:AddToggle("Triggerbot", false, function(v) Triggerbot.Config.Enabled = v end)
    w:AddToggle("Hitbox Expander", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end)
    w:AddSlider("Hitbox Size", 1, 40, 10, "studs", 1, function(v) Hitbox.Config.Size = v; Hitbox.Refresh() end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)
    w:AddToggle("Names", true, function(v) ESP.Config.Names = v end)
    w:AddToggle("Distance", true, function(v) ESP.Config.Distance = v end)
    w:AddToggle("Health", true, function(v) ESP.Config.Health = v end)
    w:AddToggle("Show FOV Circle", false, function(v) Aimbot.Config.ShowFOV = v end)

    w:AddSection("Camera & World")
    w:AddToggle("Custom Camera FOV", false, function(v) CameraFOV.Enabled = v end)
    w:AddSlider("Camera FOV", 50, 120, 70, "", 0, function(v) CameraFOV.Value = v end)
    w:AddToggle("Custom Gravity", false, function(v) Gravity.Enabled = v; if not v then Workspace.Gravity = 196.2 end end)
    w:AddSlider("Gravity", 0, 196, 60, "", 0, function(v) Gravity.Value = v end)
    w:AddToggle("Time / Fullbright", false, function(v)
        if v then Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 9e9 end
    end)
    w:AddButton("Day -> 14:00", function() Lighting.ClockTime = 14 end)
    w:AddButton("Night -> 00:00", function() Lighting.ClockTime = 0 end)

    w:AddSection("Utility")
    w:AddToggle("Anti-AFK", false, function(v) setAntiAFK(v) end)
    w:AddToggle("Crosshair", false, function(v) setCrosshair(v) end)
    w:AddSlider("Crosshair Size", 2, 40, 10, "", 0, function(v) Crosshair.Size = v end)
    w:AddSlider("Crosshair Gap", 0, 30, 4, "", 0, function(v) Crosshair.Gap = v end)
    w:AddButton("Copy Server JobId", function()
        setclipboard(tostring(game.JobId))
        notify("Universal", "Copied JobId.", 2)
    end)

    w:AddSection("Player / World")
    w:AddButton("Fullbright", function()
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9
        notify("Universal", "Fullbright on.", 2)
    end)
    w:AddButton("God Mode (re-fill health)", function()
        local h = getHum(); if h then h.Health = h.MaxHealth end
    end)
    w:AddButton("Remove Fog", function() Lighting.FogEnd = 9e9; Lighting.FogStart = 9e9 end)
    w:AddButton("FPS Boost (hide terrain textures)", function()
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d:IsA("Terrain") and d.Material == Enum.Material.Grass then
                    d.Material = Enum.Material.Plastic
                end
            end
        end)
        notify("Universal", "Applied FPS tweaks.", 2)
    end)
    w:AddDropdown("Teleport to Player", getPlayerNames(false), Players:GetPlayers()[1] and Players:GetPlayers()[1].Name or "nil", function(v) w._uniTP = v end)
    w:AddButton("Teleport", function()
        local p = findPlayerByName(w._uniTP or "")
        if p then teleportToPlayer(p) end
    end)
    notify("Universal", "Loaded.", 2.5, Theme.Accent)
    return w
end

--==============================================================================
--// EXTRA SYSTEMS: Camera FOV, Gravity, Anti-AFK, Crosshair
--==============================================================================
local CameraFOV = { Enabled = false, Value = 70 }
RunService.RenderStepped:Connect(function()
    if CameraFOV.Enabled then
        Camera.FieldOfView = CameraFOV.Value
    end
end)

local Gravity = { Enabled = false, Value = 100 }
RunService.Heartbeat:Connect(function()
    if Gravity.Enabled then
        Workspace.Gravity = Gravity.Value
    end
end)

local AntiAFK = { Enabled = false }
local function setAntiAFK(on)
    AntiAFK.Enabled = on and true or false
end
pcall(function()
    LocalPlayer.Idled:Connect(function()
        if AntiAFK.Enabled then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end)

-- Custom crosshair (4 lines around screen centre)
local Crosshair = { Enabled = false, Size = 10, Thickness = 2, Gap = 4, Color = Color3.fromRGB(0, 255, 120) }
local crossGui
local crossLines = {}
local function setCrosshair(on)
    Crosshair.Enabled = on and true or false
    if on and not crossGui then
        crossGui = Instance.new("ScreenGui")
        crossGui.Name = "HubCrosshair"
        crossGui.ResetOnSpawn = false
        crossGui.IgnoreGuiInset = true
        crossGui.DisplayOrder = 2
        crossGui.Parent = getGuiParent()
        for _ = 1, 4 do
            local f = Instance.new("Frame")
            f.BorderSizePixel = 0
            f.BackgroundColor3 = Crosshair.Color
            f.Parent = crossGui
            table.insert(crossLines, f)
        end
    end
    if crossGui then crossGui.Enabled = on end
end
RunService.RenderStepped:Connect(function()
    if Crosshair.Enabled and crossGui then
        local vp = Camera.ViewportSize
        local cx, cy = vp.X / 2, vp.Y / 2
        local s, th, gap = Crosshair.Size, Crosshair.Thickness, Crosshair.Gap
        crossLines[1].Size = UDim2.new(0, th, 0, s); crossLines[1].Position = UDim2.new(0, cx - th / 2, 0, cy - gap - s)
        crossLines[2].Size = UDim2.new(0, th, 0, s); crossLines[2].Position = UDim2.new(0, cx - th / 2, 0, cy + gap)
        crossLines[3].Size = UDim2.new(0, s, 0, th); crossLines[3].Position = UDim2.new(0, cx - gap - s, 0, cy - th / 2)
        crossLines[4].Size = UDim2.new(0, s, 0, th); crossLines[4].Position = UDim2.new(0, cx + gap, 0, cy - th / 2)
        for _, l in ipairs(crossLines) do l.BackgroundColor3 = Crosshair.Color end
    end
end)

--==============================================================================
--// EXTRA HELPERS  (shared by the extra game modules)
--==============================================================================
randPos = function(sx, sy)
    return UDim2.new(0.5, -(sx or 470) / 2 + math.random(-90, 90), 0.5, -(sy or 540) / 2 + math.random(-70, 70))
end

addMovement = function(w, speedMax, flyMax)
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end)
    w:AddSlider("Speed", 16, speedMax or 200, 50, "", 0, function(v) Movement.WalkSpeed.Value = v end)
    w:AddToggle("Jump Power", false, function(v) Movement.JumpPower.Enabled = v end)
    w:AddSlider("Jump Power", 50, 400, 120, "", 0, function(v) Movement.JumpPower.Value = v end)
    w:AddToggle("Infinite Jump", false, function(v) Movement.InfJump = v end)
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end)
    w:AddToggle("Fly (WASD/Space/Ctrl)", false, function(v) Movement.Fly.Enabled = v end)
    w:AddSlider("Fly Speed", 10, flyMax or 400, 70, "", 0, function(v) Movement.Fly.Speed = v end)
    w:AddToggle("Click Teleport", false, function(v) ClickTP.Enabled = v end)
end

local function getNearestNPC(maxDist)
    local root = getRoot()
    if not root then return nil, math.huge end
    local best, bestD = nil, maxDist or math.huge
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            local hrp = d:FindFirstChild("HumanoidRootPart") or d.PrimaryPart
            local hum = d:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - root.Position).Magnitude
                if dist < bestD then bestD = dist; best = d end
            end
        end
    end
    return best, bestD
end

local function fireRemotes(keyword)
    local n = 0
    pcall(function()
        for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
            if (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) and r.Name:lower():find(keyword) then
                if r:IsA("RemoteEvent") then r:FireServer(); n = n + 1
                else pcall(function() r:InvokeServer() end); n = n + 1 end
            end
        end
    end)
    return n
end

local HL_TAG = "HubAutoHL"
local function highlightKeywords(keywords, color)
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") or d:IsA("BasePart") then
                local n = d.Name:lower()
                local match = false
                for _, k in ipairs(keywords) do
                    if n:find(k) then match = true; break end
                end
                if match and not d:GetAttribute(HL_TAG) then
                    d:SetAttribute(HL_TAG, true)
                    local hl = Instance.new("Highlight")
                    hl.Name = HL_TAG
                    hl.FillColor = color
                    hl.FillTransparency = 0.45
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = d
                end
            end
        end
    end)
end
local function clearAutoHL()
    pcall(function()
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:GetAttribute(HL_TAG) then
                d:SetAttribute(HL_TAG, nil)
                local hl = d:FindFirstChild(HL_TAG)
                if hl then hl:Destroy() end
            end
        end
    end)
end

local function trySetStat(keyword, value)
    pcall(function()
        for _, c in ipairs(LocalPlayer:GetDescendants()) do
            if c:IsA("ValueBase") and c.Name:lower():find(keyword) then
                c.Value = value
            end
        end
    end)
end

local function touchNamed(root, keys, range)
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        local n = d.Name:lower()
        local hit = false
        for _, k in ipairs(keys) do if n:find(k) then hit = true; break end end
        if hit then
            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
            if p and (p.Position - root.Position).Magnitude < (range or 100) then
                pcall(function() firetouchinterest(root, p, 0) end)
            end
        end
    end
end

--==============================================================================
--// "FIND THE" GAME FRAMEWORK
--   Generic, fully-functional builder for every "Find the ..." hunt game.
--   Mirrors the Find-the-Script-HUB reference: a deep multi-keyword scanner
--   (BasePart names, Model/Folder names, parent-container names, and
--   TouchTransmitter parents), a live dropdown, ESP highlights, Collect-All
--   (bring to player OR visit each), Go-To-Selected, Bring-Selected-Here, and
--   an automatic collect loop. One rich builder powers 75+ games.
--==============================================================================

-- Deep scan: returns a list of collectible BaseParts matching any keyword.
-- Deduplicates by object identity, just like the reference script.
local function findScan(keywords)
    local results = {}
    local seen = {}
    local function matchesAny(name)
        local nl = string.lower(tostring(name))
        for _, kw in ipairs(keywords) do
            if string.find(nl, kw, 1, true) then return true end
        end
        return false
    end
    local function add(part, label)
        if part and not seen[part] then
            seen[part] = true
            table.insert(results, { part = part, label = label or part.Name })
        end
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and matchesAny(obj.Name) then
            add(obj, obj.Name)
        elseif (obj:IsA("Model") or obj:IsA("Folder")) and matchesAny(obj.Name) then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            add(part, obj.Name)
        elseif obj:IsA("BasePart") and obj.Parent and matchesAny(obj.Parent.Name) then
            add(obj, obj.Name)
        elseif obj:IsA("TouchTransmitter") and obj.Parent and obj.Parent:IsA("BasePart") and matchesAny(obj.Parent.Name) then
            add(obj.Parent, obj.Parent.Name)
        end
    end
    -- dedupe labels (append (2), (3) ...)
    local labelCount = {}
    for _, r in ipairs(results) do
        labelCount[r.label] = (labelCount[r.label] or 0) + 1
        if labelCount[r.label] > 1 then
            r.label = r.label .. " (" .. labelCount[r.label] .. ")"
        end
    end
    return results
end

-- Build a rich feature window for a single "Find the" game.
local function buildFindTheGame(cfg)
    local w = createWindow(cfg.name, "Hunt Suite (find-the)", 480, 600, randPos(480, 600))
    local keywords = cfg.keywords or { string.lower(cfg.name) }
    local color = cfg.color or Color3.fromRGB(255, 200, 80)
    local state = {
        found = {},          -- list of {part, label}
        labelMap = {},       -- label -> part
        options = {},
        selected = nil,
        espOn = false,
        autoCollect = false,
        autoDelay = 0.3,
        autoIndex = 1,
        bringESP = {},       -- highlight objects created by this window's ESP
        lastCount = 0,
    }

    local function refreshESP()
        -- remove our own ESP highlights
        for _, h in ipairs(state.bringESP) do pcall(function() h:Destroy() end) end
        state.bringESP = {}
        if not state.espOn then return end
        for _, r in ipairs(state.found) do
            if r.part and r.part.Parent then
                local hl = Instance.new("Highlight")
                hl.Name = "FindESP"
                hl.FillColor = color
                hl.FillTransparency = 0.45
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.Adornee = r.part
                hl.Parent = r.part
                table.insert(state.bringESP, hl)
            end
        end
    end

    local function doScan()
        state.found = findScan(keywords)
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
        if v then Lighting.FogEnd = 9