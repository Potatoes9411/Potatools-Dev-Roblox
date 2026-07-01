local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    AntiAFK.Enabled = on and true or false
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
        for _, h in ipairs(state.bringESP) do pcall(function() h:Destroy() end\n    end\nend\n\nreturn M\n
