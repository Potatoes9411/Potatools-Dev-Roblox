 show and data.isPlayer and ESP.Config.TeamCheck and data.player and LocalPlayer.Team and data.player.Team == LocalPlayer.Team then
            show = false
        end
        data.highlight.Enabled = show
        data.highlight.FillTransparency = show and ESP.Config.FillTransparency or 1
        data.billboard.Enabled = show
    end
end

local function espFullScan()
    -- players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            espApply(plr.Character, true, plr)
        end
    end
end

local function espSetupPlayer(plr)
    if plr == LocalPlayer then return end
    local function onChar(char)
        task.wait(0.2)
        espApply(char, true, plr)
    end
    if plr.Character then onChar(plr.Character) end
    ESP._conns[plr] = plr.CharacterAdded:Connect(onChar)
end

ESP.Enable = function(state)
    ESP.Config.Enabled = state
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do espSetupPlayer(plr) end
        if not ESP._playerAddedConn then
            ESP._playerAddedConn = Players.PlayerAdded:Connect(function(p) espSetupPlayer(p) end)
            ESP._playerRemovingConn = Players.PlayerRemoving:Connect(function(p)
                if p.Character then espRemove(p.Character) end
                if ESP._conns[p] then ESP._conns[p]:Disconnect() ESP._conns[p] = nil end
            end)
        end
    else
        for model in pairs(ESP._tracked) do
            if model and model.Parent then
                local d = ESP._tracked[model]
                if d then d.highlight.Enabled = false; d.billboard.Enabled = false end
            end
        end
    end
    espRefreshVisibility()
end

ESP.ClearAll = function()
    for model in pairs(ESP._tracked) do espRemove(model) end
    ESP._tracked = {}
end

-- ESP update loop (text, distance, color, team color, box via tracer fallback)
RunService.RenderStepped:Connect(function()
    if not ESP.Config.Enabled then return end
    local myRoot = getRoot()
    for model, data in pairs(ESP._tracked) do
        if not model.Parent then
            espRemove(model)
        else
            local hum = data.hum
            local root = data.root
            if not hum or not hum.Parent or hum.Health <= 0 then
                data.highlight.Enabled = false
                data.billboard.Enabled = false
            else
                local teamHide = data.isPlayer and ESP.Config.TeamCheck and data.player and LocalPlayer.Team and data.player.Team == LocalPlayer.Team
                data.highlight.Enabled = not teamHide
                data.billboard.Enabled = not teamHide
                -- color by team / role
                local baseColor = ESP.Config.FillColor
                if data.isPlayer and data.player and data.player.Team and data.player.Team.TeamColor then
                    baseColor = data.player.Team.TeamColor.Color
                end
                -- Friends recolor green, Targets recolor red (vape Friends/Targets)
                if data.isPlayer and data.player then
                    if isFriend and isFriend(data.player) then baseColor = Color3.fromRGB(76, 209, 142) end
                    if isTarget and isTarget(data.player) then baseColor = Color3.fromRGB(255, 60, 60) end
                end
                data.highlight.FillColor = baseColor
                data.highlight.FillTransparency = ESP.Config.FillTransparency
                local parts = {}
                if ESP.Config.Names then
                    local name = data.isPlayer and data.player.Name or model.Name
                    table.insert(parts, '<font color="#ffffff">' .. name .. '</font>')
                end
                if ESP.Config.Distance and myRoot and root then
                    local d = (root.Position - myRoot.Position).Magnitude
                    table.insert(parts, string.format('<font color="#9ad7ff">%.0fm</font>', d))
                end
                if ESP.Config.Health then
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local hp = math.floor(hum.Health)
                    local col = pct > 0.5 and "#7ad18b" or (pct > 0.25 and "#f5c44c" or "#eb4d5c")
                    table.insert(parts, string.format('<font color="%s">%d HP</font>', col, hp))
                end
                data.label.Text = table.concat(parts, "  ")
            end
        end
    end
end)

--==============================================================================
--// AIMBOT SYSTEM
--==============================================================================
local Aimbot = {}
Aimbot.Config = {
    Enabled      = false,
    TeamCheck    = true,
    WallCheck    = false,
    DeadCheck    = true,
    Smoothness   = 0.25,
    FOV          = 120,
    TargetPart   = "Head",
    Prediction   = 0,
    ShowFOV      = false,
    LockKey      = Enum.KeyCode.E,   -- hold to aim (optional). If nil, always aim.
    HoldToAim    = false,
}

local function aimGetClosest()
    local closest, closestMag = nil, Aimbot.Config.FOV
    local mousePos = UserInputService:GetMouseLocation()
    local myRoot = getRoot()
    if not myRoot then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local part = char:FindFirstChild(Aimbot.Config.TargetPart) or char:FindFirstChild("HumanoidRootPart")
            if part and hum and (not Aimbot.Config.DeadCheck or hum.Health > 0) then
                if not (Aimbot.Config.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local mag = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if mag <= closestMag then
                            local visible = true
                            if Aimbot.Config.WallCheck then
                                local rp = RaycastParams.new()
                                rp.FilterType = Enum.RaycastFilterType.Exclude
                                rp.FilterDescendantsInstances = { LocalPlayer.Character, char }
                                local origin = Camera.CFrame.Position
                                local dir = (part.Position - origin)
                                local res = Workspace:Raycast(origin, dir.Unit * dir.Magnitude, rp)
                                visible = res == nil or res.Instance:IsDescendantOf(char)
                            end
                            if visible then
                                closestMag = mag
                                closest = plr
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not Aimbot.Config.Enabled then return end
    local active = true
    if Aimbot.Config.HoldToAim and Aimbot.Config.LockKey then
        active = UserInputService:IsKeyDown(Aimbot.Config.LockKey)
    end
    if not active then return end
    local target = aimGetClosest()
    if target and target.Character then
        local part = target.Character:FindFirstChild(Aimbot.Config.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if part and hum then
            local targetPos = part.Position
            if Aimbot.Config.Prediction > 0 and hum.RootPart then
                targetPos = targetPos + hum.RootPart.AssemblyLinearVelocity * Aimbot.Config.Prediction
            end
            local aimCF = CFrame.new(Camera.CFrame.Position, targetPos)
            local s = math.clamp(Aimbot.Config.Smoothness, 0.01, 1)
            Camera.CFrame = Camera.CFrame:Lerp(aimCF, s)
        end
    end
end)

-- FOV circle
local FOVCircle = Instance.new("Frame")
FOVCircle.Name = "FOVCircle"
FOVCircle.Size = UDim2.new(0, Aimbot.Config.FOV * 2, 0, Aimbot.Config.FOV * 2)
FOVCircle.Position = UDim2.new(0.5, -Aimbot.Config.FOV, 0.5, -Aimbot.Config.FOV)
FOVCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.ZIndex = 5
FOVCircle.Parent = ScreenGui
corner(FOVCircle, UDim.new(1, 0))
stroke(FOVCircle, Theme.Accent, 1.5, 0.3)
local FOVAspect = Instance.new("UIAspectRatioConstraint")
FOVAspect.AspectRatio = 1
FOVAspect.Parent = FOVCircle

RunService.RenderStepped:Connect(function()
    if Aimbot.Config.ShowFOV then
        FOVCircle.Visible = true
        local r = Aimbot.Config.FOV
        FOVCircle.Size = UDim2.new(0, r * 2, 0, r * 2)
        FOVCircle.Position = UDim2.new(0.5, -r, 0.5, -r)
    else
        FOVCircle.Visible = false
    end
end)

--==============================================================================
--// TRIGGERBOT  (auto-fire when crosshair over a valid target)
--==============================================================================
local Triggerbot = { Config = { Enabled = false, Delay = 0.05, TeamCheck = true, Burst = false } }
local lastFire = 0
RunService.Heartbeat:Connect(function()
    if not Triggerbot.Config.Enabled then return end
    if tick() - lastFire < Triggerbot.Config.Delay then return end
    local target = Mouse.Target
    if not target then return end
    local char = target:FindFirstAncestorOfClass("Model")
    if not char then return end
    local plr = Players:GetPlayerFromCharacter(char)
    if plr and plr ~= LocalPlayer then
        if Triggerbot.Config.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 then
            lastFire = tick()
            pcall(function()
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    tool:Activate()
                else
                    -- fallback: simulate a click via VirtualInputManager
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
                end
            end)
        end
    end
end)

--==============================================================================
--// HITBOX EXPANDER
--==============================================================================
local Hitbox = { Config = { Enabled = false, Size = 10, Transparency = 0.6, Target = "Head", Color = Color3.fromRGB(255,255,255) } }
local function hitboxApplyOne(char)
    if not char then return end
    local part = char:FindFirstChild(Hitbox.Config.Target) or char:FindFirstChild("HumanoidRootPart")
    if not part then return end
    if Hitbox.Config.Enabled then
        if not part:GetAttribute("OrigSize") then
            part:SetAttribute("OrigSize", HttpService:JSONEncode({part.Size.X, part.Size.Y, part.Size.Z}))
            part:SetAttribute("OrigTransp", part.Transparency)
        end
        part.CanCollide = false
        part.Transparency = Hitbox.Config.Transparency
        part.Material = Enum.Material.ForceField
        part.Color = Hitbox.Config.Color
        part.Size = Vector3.new(Hitbox.Config.Size, Hitbox.Config.Size, Hitbox.Config.Size)
    else
        local s = part:GetAttribute("OrigSize")
        local t = part:GetAttribute("OrigTransp")
        if s then
            local dims = HttpService:JSONDecode(s)
            part.Size = Vector3.new(dims[1], dims[2], dims[3])
            part.Transparency = t or 0
            part.Material = Enum.Material.Plastic
        end
    end
end
Hitbox.Refresh = function()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            hitboxApplyOne(plr.Character)
        end
    end
end
RunService.Heartbeat:Connect(function()
    if not Hitbox.Config.Enabled then return end
    Hitbox.Refresh()
end)

--==============================================================================
--// MOVEMENT SYSTEM  (WalkSpeed, JumpPower, Infinite Jump, Noclip, Fly)
--==============================================================================
local Movement = {}
Movement.WalkSpeed = { Enabled = false, Value = 50 }
Movement.JumpPower = { Enabled = false, Value = 100 }
Movement.InfJump   = false
Movement.Noclip    = false
Movement.Fly       = { Enabled = false, Speed = 60 }
Movement.SitWalk   = false

-- Noclip
RunService.Stepped:Connect(function()
    if Movement.Noclip then
        local char = getChar()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide and p.Name ~= "HumanoidRootPart" then
                    p.CanCollide = false
                elseif p:IsA("BasePart") and p.Name == "HumanoidRootPart" then
                    p.CanCollide = false
                end
            end
        end
    end
end)

-- WalkSpeed / JumpPower
RunService.Heartbeat:Connect(function()
    local hum = getHum()
    if hum then
        if Movement.WalkSpeed.Enabled then
            hum.WalkSpeed = Movement.WalkSpeed.Value
        end
        if Movement.JumpPower.Enabled then
            pcall(function()
                hum.UseJumpPower = true
                hum.JumpPower = Movement.JumpPower.Value
            end)
        end
    end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
    if Movement.InfJump then
        local hum = getHum()
        if hum then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end
end)

-- Fly
local flyBV, flyBG
local function flyStart()
    local root = getRoot()
    if not root then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1, 1, 1) * 9e9
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1, 1, 1) * 9e9
    flyBG.P = 9e4
    flyBG.CFrame = Camera.CFrame
    flyBG.Parent = root
end
local function flyStop()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end
RunService.RenderStepped:Connect(function()
    if Movement.Fly.Enabled then
        local root = getRoot()
        if root then
            if not flyBV then flyStart() end
            local cam = Camera.CFrame
            if flyBG then flyBG.CFrame = cam end
            local f = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
            local r = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            local u = (UserInputService:IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0)
            local dir = cam.LookVector * f + cam.RightVector * r + Vector3.new(0, 1, 0) * u
            if dir.Magnitude > 0 then dir = dir.Unit end
            if flyBV then flyBV.Velocity = dir * Movement.Fly.Speed end
        end
    else
        flyStop()
    end
end)

-- reset fly on respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)
    flyStop()
end)

--==============================================================================
--// TELEPORT UTILITIES
--==============================================================================
local function teleportTo(pos)
    local root = getRoot()
    if root and pos then
        root.CFrame = CFrame.new(pos)
        return true
    end
    return false
end
local function teleportToCF(cf)
    local root = getRoot()
    if root and cf then
        root.CFrame = cf
        return true
    end
    return false
end
local function teleportToPlayer(plr)
    if plr and plr.Character then
        local r = plr.Character:FindFirstChild("HumanoidRootPart")
        if r then return teleportTo(r.Position + Vector3.new(0, 3, 0)) end
    end
    return false
end
-- Smooth click-teleport (click to walk-to position)
local ClickTP = { Enabled = false }
Mouse.Button1Down:Connect(function()
    if ClickTP.Enabled then
        local root = getRoot()
        if root and Mouse.Hit then
            TeleportPro.pushHistory()
            root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

--==============================================================================
--// ADVANCED TELEPORTATION MANAGER ("TeleportPro")
--   Saved locations (named), path recorder/replay, part-search teleport,
--   teleport history (undo), coordinate teleport, directional nudge teleport,
--   cycle-players teleport, and a part grabber/mover. Uses real CFrames.
--==============================================================================
TeleportPro = {
    Saved = {},            -- { name = Vector3/CF }
    History = {},          -- stack of previous positions for "undo"
    Path = {},             -- recorded path points
    Recording = false,
    PlayingPath = false,
    PathSpeed = 1,
    File = "MultiGameHub_TPSpots.json",
    _beacons = {},         -- visual markers at saved spots
    _pIndex = 1,           -- player cycle index
}

function TeleportPro.pushHistory()
    local root = getRoot()
    if root then
        table.insert(TeleportPro.History, root.CFrame)
        if #TeleportPro.History > 50 then table.remove(TeleportPro.History, 1) end
    end
end

function TeleportPro.undo()
    local cf = table.remove(TeleportPro.History)
    if cf then
        local root = getRoot()
        if root then root.CFrame = cf; notify("TeleportPro", "Returned to previous spot.", 2.5, Theme.Accent) end
    else
        notify("TeleportPro", "No history yet.", 2.5, Theme.Yellow)
    end
end

function TeleportPro.coord(x, y, z)
    local root = getRoot()
    if root then
        TeleportPro.pushHistory()
        root.CFrame = CFrame.new(x, y, z)
        notify("TeleportPro", string.format("Teleported to (%.0f, %.0f, %.0f)", x, y, z), 2.5, Theme.Accent)
    end
end

-- directional nudge teleport (offset relative to camera/humanoid facing)
function TeleportPro.nudge(dx, dy, dz, cameraRelative)
    local root = getRoot()
    if not root then return end
    local offset
    if cameraRelative then
        local cf = Camera.CFrame
        offset = (cf.LookVector * dz) + (cf.RightVector * dx) + Vector3.new(0, dy, 0)
    else
        offset = Vector3.new(dx, dy, dz)
    end
    TeleportPro.pushHistory()
    root.CFrame = root.CFrame + offset
end

-- teleport to the surface the mouse is pointing at (raycast accurate)
function TeleportPro.mouseTP()
    local root = getRoot()
    if not root then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { getChar() }
    local ray = Workspace:Raycast(Camera.CFrame.Position, Mouse.UnitRay.Direction * 1000, params)
    if ray then
        TeleportPro.pushHistory()
        root.CFrame = CFrame.new(ray.Position + ray.Normal * 3)
        return true
    end
    return false
end

-- teleport to a part by (fuzzy) name search â€” closest match
function TeleportPro.toPartByName(name)
    if not name or name == "" then return false end
    local nl = string.lower(name)
    local best, bestD = nil, math.huge
    local root = getRoot()
    if not root then return false end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and string.lower(d.Name):find(nl) then
            local dist = (d.Position - root.Position).Magnitude
            if dist < bestD then bestD = dist; best = d end
        end
    end
    if best then
        TeleportPro.pushHistory()
        root.CFrame = best.CFrame + Vector3.new(0, 4, 0)
        notify("TeleportPro", "Teleported to '" .. best.Name .. "' (" .. math.floor(bestD) .. "m)", 3, Theme.Accent)
        return true
    end
    return false
end

-- teleport to the nearest part of a given class-friendly type (e.g. SpawnLocation)
function TeleportPro.toNearestOfClass(className)
    local root = getRoot()
    if not root then return false end
    local best, bestD = nil, math.huge
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA(className) and d:IsA("BasePart") then
            local dist = (d.Position - root.Position).Magnitude
            if dist < bestD then bestD = dist; best = d end
        end
    end
    if best then
        TeleportPro.pushHistory()
        root.CFrame = best.CFrame + Vector3.new(0, 4, 0)
        notify("TeleportPro", "Teleported to nearest " .. className, 2.5, Theme.Accent)
        return true
    end
    return false
end

-- save the current position with a label
function TeleportPro.saveHere(name)
    local root = getRoot()
    if not root then return end
    name = name or ("Spot " .. (#TeleportPro.Saved + 1))
    TeleportPro.Saved[name] = { cf = root.CFrame }
    TeleportPro.persist()
    notify("TeleportPro", "Saved '" .. name .. "'.", 2.5, Theme.Green)
end

function TeleportPro.goToSaved(name)
    local spot = TeleportPro.Saved[name]
    local root = getRoot()
    if spot and root then
        TeleportPro.pushHistory()
        root.CFrame = spot.cf
        notify("TeleportPro", "Teleported to '" .. name .. "'.", 2.5, Theme.Accent)
    end
end

function TeleportPro.deleteSaved(name)
    TeleportPro.Saved[name] = nil
    TeleportPro.persist()
    notify("TeleportPro", "Deleted '" .. name .. "'.", 2.5, Theme.Yellow)
end

-- cycle teleport through every player
function TeleportPro.cyclePlayer()
    local list = getPlayerNames(true)
    if #list == 0 then return end
    TeleportPro._pIndex = (TeleportPro._pIndex % #list) + 1
    local p = findPlayerByName(list[TeleportPro._pIndex])
    if p then teleportToPlayer(p); notify("TeleportPro", "Cycle -> " .. p.Name, 2) end
end

-- teleport to ALL saved spots in sequence (a quick tour)
function TeleportPro.tourSaved(delay)
    local root = getRoot()
    if not root then return end
    local names = {}
    for n in pairs(TeleportPro.Saved) do table.insert(names, n) end
    if #names == 0 then notify("TeleportPro", "No saved spots.", 2.5, Theme.Yellow); return end
    task.spawn(function()
        for _, n in ipairs(names) do
            local spot = TeleportPro.Saved[n]
            if spot and root and root.Parent then
                pcall(function() root.CFrame = spot.cf end)
                notify("TeleportPro", "Tour: " .. n, 1.2)
                task.wait(delay or 0.8)
            end
        end
        notify("TeleportPro", "Tour complete.", 2.5, Theme.Green)
    end)
end

-- PATH RECORDER: record your position over time, then replay/teleport-along it
function TeleportPro.startRecording()
    TeleportPro.Path = {}
    TeleportPro.Recording = true
    notify("TeleportPro", "Recording path... walk around!", 3, Theme.Yellow)
end
function TeleportPro.stopRecording()
    TeleportPro.Recording = false
    notify("TeleportPro", "Stopped. Recorded " .. #TeleportPro.Path .. " points.", 3, Theme.Accent)
end
function TeleportPro.playPath(instant)
    if #TeleportPro.Path == 0 then notify("TeleportPro", "No path recorded.", 2.5, Theme.Yellow); return end
    if TeleportPro.PlayingPath then return end
    TeleportPro.PlayingPath = true
    notify("TeleportPro", "Playing path (" .. #TeleportPro.Path .. " pts)...", 3, Theme.Accent)
    task.spawn(function()
        local root = getRoot()
        for i, cf in ipairs(TeleportPro.Path) do
            if not TeleportPro.PlayingPath or not (root and root.Parent) then break end
            root = getRoot()
            if root then
                pcall(function()
                    if instant then
                        root.CFrame = cf
                    else
                        root.CFrame = root.CFrame:Lerp(cf, math.clamp(TeleportPro.PathSpeed * 0.2, 0.05, 1))
                    end
                end)
            end
            task.wait(instant and 0.05 or (0.03 / math.max(TeleportPro.PathSpeed, 0.1)))
        end
        TeleportPro.PlayingPath = false
        notify("TeleportPro", "Path finished.", 2.5, Theme.Green)
    end)
end
function TeleportPro.savePathToFile()
    local data = {}
    for _, cf in ipairs(TeleportPro.Path) do
        table.insert(data, { cf:GetComponents() })
    end
    pcall(function()
        if writefile then writefile("MultiGameHub_Path.json", HttpService:JSONEncode(data)) end
    end)
    notify("TeleportPro", "Path saved (" .. #data .. " points).", 2.5, Theme.Green)
end
function TeleportPro.loadPathFromFile()
    local ok, res = pcall(function()
        if not (isfile and isfile("MultiGameHub_Path.json")) then return {} end
        return HttpService:JSONDecode(readfile("MultiGameHub_Path.json"))
    end)
    if ok and type(res) == "table" then
        TeleportPro.Path = {}
        for _, c in ipairs(res) do
            -- c = {x,y,z, R00..R12, ...} â€” CFrame:GetComponents returns 12 numbers
            if #c >= 12 then
                table.insert(TeleportPro.Path, CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12]))
            elseif #c >= 3 then
                table.insert(TeleportPro.Path, CFrame.new(c[1], c[2], c[3]))
            end
        end
        notify("TeleportPro", "Path loaded (" .. #TeleportPro.Path .. " points).", 2.5, Theme.Accent)
    end
end

-- PART GRABBER / MOVER: lets you click parts and drag them to you / move them
local PartMover = {
    Enabled = false,
    Mode = "Bring",          -- "Bring" (to player) or "Fling" or "Freeze"
    _sel = nil,
    _hl = nil,
}
function PartMover:select(part)
    if self._hl then pcall(function() self._hl:Destroy() end) end
    self._sel = part
    if part then
        self._hl = Instance.new("Highlight")
        self._hl.FillColor = Color3.fromRGB(255, 200, 80)
        self._hl.FillTransparency = 0.5
        self._hl.Adornee = part
        self._hl.Parent = part
    end
end
function PartMover:act()
    local root = getRoot()
    if not (self._sel and self._sel.Parent and root) then return end
    if self.Mode == "Bring" then
        pcall(function() self._sel.CFrame = root.CFrame * CFrame.new(0, 0, -5) end)
    elseif self.Mode == "Fling" then
        pcall(function() self._sel.AssemblyLinearVelocity = root.CFrame.LookVector * 300 + Vector3.new(0, 80, 0) end)
    elseif self.Mode == "Freeze" then
        pcall(function()
            self._sel.Anchored = not self._sel.Anchored
        end)
    end
end

-- recording loop + part-mover click handling
Mouse.Button2Down:Connect(function()
    if PartMover.Enabled and Mouse.Target then
        PartMover:select(Mouse.Target)
    end
end)

RunService.Heartbeat:Connect(function()
    if TeleportPro.Recording and isAlive() then
        local root = getRoot()
        if root then
            -- record at most every ~0.1s
            if not TeleportPro._lastRec or tick() - TeleportPro._lastRec > 0.1 then
                TeleportPro._lastRec = tick()
                -- avoid duplicate points
                local last = TeleportPro.Path[#TeleportPro.Path]
                if not last or (last.Position - root.Position).Magnitude > 0.5 then
                    table.insert(TeleportPro.Path, root.CFrame)
                end
            end
        end
    end
    if PartMover.Enabled and PartMover.Mode == "Bring" and PartMover._sel then
        PartMover:act()
    end
end)

-- persistence of saved spots
function TeleportPro.persist()
    local data = {}
    for name, spot in pairs(TeleportPro.Saved) do
        local c = { spot.cf:GetComponents() }
        data[name] = c
    end
    pcall(function()
        if writefile then writefile(TeleportPro.File, HttpService:JSONEncode(data)) end
    end)
end
function TeleportPro.loadSaved()
    local ok, res = pcall(function()
        if not (isfile and isfile(TeleportPro.File)) then return {} end
        return HttpService:JSONDecode(readfile(TeleportPro.File))
    end)
    if ok and type(res) == "table" then
        for name, c in pairs(res) do
            if #c >= 12 then
                TeleportPro.Saved[name] = { cf = CFrame.new(c[1], c[2], c[3], c[4], c[5], c[6], c[7], c[8], c[9], c[10], c[11], c[12]) }
            elseif #c >= 3 then
                TeleportPro.Saved[name] = { cf = CFrame.new(c[1], c[2], c[3]) }
            end
        end
    end
end
TeleportPro.loadSaved()

--==============================================================================
--// TELEPORT PRO WINDOW
--==============================================================================
local function TeleportProWindow()
    local w = createWindow("Teleport Pro", "Advanced teleportation", 470, 600, randPos(470, 600))

    w:AddSection("Quick Teleport")
    w:AddButton("Teleport to Mouse / Surface", function()
        if TeleportPro.mouseTP() then else notify("TeleportPro", "Point at a surface.", 2.5, Theme.Yellow) end
    end, Theme.Accent)
    w:AddToggle("Click-Teleport (left click)", false, function(v) ClickTP.Enabled = v end, "Left-click anywhere to teleport")
    w:AddButton("Undo Last Teleport", function() TeleportPro.undo() end, Theme.Yellow)
    w:AddButton("Nearest Spawn", function() TeleportPro.toNearestOfClass("SpawnLocation") end)
    w:AddButton("Nearest Seat / VehicleSeat", function() TeleportPro.toNearestOfClass("VehicleSeat") end)
    w:AddButton("Top of Map (highest part)", function()
        local root = getRoot()
        if not root then return end
        local best, by = nil, -math.huge
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Position.Y > by then by = d.Position.Y; best = d end
        end
        if best then TeleportPro.pushHistory(); root.CFrame = best.CFrame + Vector3.new(0, 6, 0); notify("TeleportPro", "Top reached (" .. math.floor(by) .. ")", 2.5) end
    end)

    w:AddSection("Coordinate Teleport")
    w:AddInput("X", "0", "x", function(v) w._tpX = tonumber(v) or 0 end)
    w:AddInput("Y", "0", "y", function(v) w._tpY = tonumber(v) or 0 end)
    w:AddInput("Z", "0", "z", function(v) w._tpZ = tonumber(v) or 0 end)
    w:AddButton("Teleport to Coordinates", function()
        TeleportPro.coord(w._tpX or 0, w._tpY or 0, w._tpZ or 0)
    end, Theme.Accent)
    w:AddButton("Copy My Coordinates", function()
        local root = getRoot()
        if root then
            local p = root.Position
            setclipboard(string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z))
            notify("TeleportPro", "Coordinates copied.", 2.5, Theme.Green)
        end
    end)

    w:AddSection("Directional Nudge")
    w:AddButton("â–² Forward", function() TeleportPro.nudge(0, 0, -25, true) end)
    w:AddButton("â–¼ Back", function() TeleportPro.nudge(0, 0, 25, true) end)
    w:AddButton("â—„ Left", function() TeleportPro.nudge(-25, 0, 0, true) end)
    w:AddButton("â–º Right", function() TeleportPro.nudge(25, 0, 0, true) end)
    w:AddButton("â¬† Up 30", function() TeleportPro.nudge(0, 30, 0) end)
    w:AddButton("â¬‡ Down 30", function() TeleportPro.nudge(0, -30, 0) end)

    w:AddSection("Part Search Teleport")
    w:AddInput("Part Name", "", "e.g. Door / Chest", function(v) w._partName = v end)
    w:AddButton("Teleport to Nearest Part (by name)", function()
        if not TeleportPro.toPartByName(w._partName or "") then notify("TeleportPro", "Part not found.", 2.5, Theme.Red) end
    end, Theme.Accent)

    w:AddSection("Saved Locations")
    w:AddInput("Location Name", "", "name for this spot", function(v) w._spotName = v end)
    w:AddButton("Save Current Position", function()
        TeleportPro.saveHere(w._spotName ~= "" and w._spotName or nil)
    end, Theme.Green)
    w:AddButton("Tour All Saved (sequence)", function() TeleportPro.tourSaved() end)
    w:AddInput("Go-To Saved Name", "", "exact saved name", function(v) w._goName = v end)
    w:AddButton("Teleport to Saved Spot", function()
        TeleportPro.goToSaved(w._goName or "")
    end)
    w:AddButton("Delete Saved Spot", function()
        TeleportPro.deleteSaved(w._goName or "")
    end, Theme.Yellow)

    w:AddSection("Player Cycle")
    w:AddButton("Cycle to Next Player", function() TeleportPro.cyclePlayer() end, Theme.Accent)

    w:AddSection("Path Recorder")
    w:AddButton("Start Recording", function() TeleportPro.startRecording() end, Theme.Yellow)
    w:AddButton("Stop Recording", function() TeleportPro.stopRecording() end, Theme.Red)
    w:AddButton("Play Path (smooth)", function() TeleportPro.playPath(false) end, Theme.Accent)
    w:AddButton("Play Path (instant)", function() TeleportPro.playPath(true) end)
    w:AddSlider("Path Speed", 0.1, 10, 1, "x", 2, function(v) TeleportPro.PathSpeed = v end)
    w:AddButton("Save Path to File", function() TeleportPro.savePathToFile() end)
    w:AddButton("Load Path from File", function() TeleportPro.loadPathFromFile() end)
    w:AddButton("Clear Path", function() TeleportPro.Path = {}; notify("TeleportPro", "Path cleared.", 2.5, Theme.Yellow) end, Theme.Yellow)

    w:AddSection("Part Grabber / Mover")
    w:AddToggle("Enable Part Mover", false, function(v) PartMover.Enabled = v; if not v then PartMover:select(nil) end end, "Right-click a part to select it")
    w:AddDropdown("Mover Mode", { "Bring", "Fling", "Freeze" }, "Bring", function(v) PartMover.Mode = v end)
    w:AddButton("Act on Selected Part", function() PartMover:act() end, Theme.Accent)
    w:AddButton("Deselect", function() PartMover:select(nil) end)

    w:AddSection("Visuals")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end)

    notify("Teleport Pro", "Loaded. Save spots, record paths, click-TP!", 4, Theme.Accent)
    return w
end

--==============================================================================
--// PLAYER LIST HELPERS (for "teleport to" / "bring" dropdowns)
--==============================================================================
getPlayerNames = function(includeSelf)
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if includeSelf or p ~= LocalPlayer then table.insert(t, p.Name) end
    end
    return t
end
findPlayerByName = function(name)
    name = string.lower(tostring(name))
    for _, p in ipairs(Players:GetPlayers()) do
        if string.lower(p.Name):sub(1, #name) == name then return p end
    end
    return nil
end

--==============================================================================
--// VAPE-STYLE MODULE FRAMEWORK
--   Inspired by VapeV4's module architecture (Combat / Movement / Player /
--   Render categories). Each module is a self-contained, toggleable system
--   driven by RunService loops with real Roblox API calls. Works in plain
--   Studio thanks to the Drawing + executor shims below.
--==============================================================================

--// Drawing API shim (Studio has no Drawing global). Tracers use Beams.
local Drawing = Drawing or {}
Drawing._enabled = false
local _tracerFolder
local function ensureTracerFolder()
    if _tracerFolder and _tracerFolder.Parent then return _tracerFolder end
    _tracerFolder = Instance.new("Folder")
    _tracerFolder.Name = "HubTracers"
    _tracerFolder.Parent = Workspace
    return _tracerFolder
end

--// Module registry
local Modules = {}
local function makeModule(name, category, defaults)
    local m = {
        Name = name,
        Category = category or "Misc",
        Enabled = false,
        Settings = defaults or {},
    }
    function m:Set(v, fire)
        m.Enabled = v and true or false
        if m.OnToggle then pcall(m.OnToggle, m.Enabled) end
    end
    function m:Toggle() m:Set(not m.Enabled) end
    Modules[name] = m
    return m
end

-- Collect every living non-friendly character within range of the local root.
local function getTargetsInRange(range, includeNPCs, teamCheck)
    local root = getRoot()
    local list = {}
    if not root then return list end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                if not (teamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d <= range then table.insert(list, { char = char, hrp = hrp, hum = hum, dist = d, player = plr }) end
                end
            end
        end
    end
    if includeNPCs then
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                local hum = d:FindFirstChildOfClass("Humanoid")
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - root.Position).Magnitude
                    if dist <= range then table.insert(list, { char = d, hrp = hrp, hum = hum, dist = dist }) end
                end
            end
        end
    end
    return list
end

-- Fire the currently held tool (works for most games that use Tool:Activate).
local function swingTool()
    pcall(function()
        local tool = getChar() and getChar():FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
        VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
    end)
end

------------------------------------------------------------
-- COMBAT MODULES
------------------------------------------------------------

-- KillAura: attack all valid targets in range, sorted by distance.
-- Faithful to vape KillAura: angle-cone targeting, swing vs attack range,
-- SelectionBox range indicators, ParticleEmitter hit effects, optional
-- GetPartBoundsInBox touch-interest forwarding.
local KillAura = makeModule("KillAura", "Combat", {
    Range = 6, SwingRange = 6, AttackRange = 13, Delay = 0.1,
    Targets = 1, MaxAngle = 360, NPC = false, TeamCheck = true,
    Rotate = true, ShowRange = false, Particles = false, CPS = 12,
})
local _kaLast = 0
-- Range indicator boxes (red = swing, green = attack).
local _kaSwingBox, _kaAttackBox
local function buildAuraBoxes()
    if _kaSwingBox then return end
    _kaSwingBox = Instance.new("SelectionBox")
    _kaSwingBox.Name = "AuraSwingBox"
    _kaSwingBox.Color3 = Color3.fromRGB(255, 80, 80)
    _kaSwingBox.Transparency = 0.6
    _kaSwingBox.LineThickness = 0.05
    _kaSwingBox.Visible = false
    _kaSwingBox.Parent = Workspace
    _kaAttackBox = Instance.new("SelectionBox")
    _kaAttackBox.Name = "AuraAttackBox"
    _kaAttackBox.Color3 = Color3.fromRGB(80, 255, 120)
    _kaAttackBox.Transparency = 0.6
    _kaAttackBox.LineThickness = 0.05
    _kaAttackBox.Visible = false
    _kaAttackBox.Parent = Workspace
end
-- Particle pool for hit effects.
local _kaParticles = {}
local function getAuraParticle()
    for _, p in ipairs(_kaParticles) do if not p.Enabled then return p end end
    if #_kaParticles > 30 then return _kaParticles[1] end
    local att = Instance.new("Attachment")
    att.Parent = Workspace
    local pe = Instance.new("ParticleEmitter")
    pe.Attachment = att
    pe.Texture = "rbxassetid://243660364"
    pe.Lifetime = NumberRange.new(0.3, 0.5)
    pe.Speed = NumberRange.new(6, 10)
    pe.Rate = 0
    pe.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
    pe.Size = NumberSequence.new(0.6, 0)
    pe.Parent = att
    table.insert(_kaParticles, pe)
    return pe
end
function KillAura.OnToggle(state)
    if not state then
        if _kaSwingBox then _kaSwingBox.Visible = false end
        if _kaAttackBox then _kaAttackBox.Visible = false end
    end
end
RunService.Heartbeat:Connect(function()
    if not KillAura.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if KillAura.Settings.ShowRange then
        buildAuraBoxes()
        _kaSwingBox.Visible = true
        _kaAttackBox.Visible = true
        _kaSwingBox.Adornee = root
        _kaAttackBox.Adornee = root
    elseif _kaSwingBox then
        _kaSwingBox.Visible = false
        _kaAttackBox.Visible = false
    end
    local cps = math.max(KillAura.Settings.CPS or 12, 1)
    local interval = math.max(1 / cps, KillAura.Settings.Delay)
    if tick() - _kaLast < interval then return end
    local selfpos = root.Position
    local localfacing = root.CFrame.LookVector * Vector3.new(1, 0, 1)
    local swingR, attackR = KillAura.Settings.SwingRange, KillAura.Settings.AttackRange
    local maxAng = math.rad(KillAura.Settings.MaxAngle) / 2
    local targets = getTargetsInRange(KillAura.Settings.AttackRange, KillAura.Settings.NPC, KillAura.Settings.TeamCheck)
    table.sort(targets, function(a, b) return a.dist < b.dist end)
    local count = 0
    for _, t in ipairs(targets) do
        if count >= KillAura.Settings.Targets then break end
        local delta = t.hrp.Position - selfpos
        local angle = math.acos(math.clamp(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit), -1, 1))
        if angle > maxAng then continue end
        if KillAura.Settings.Rotate then
            pcall(function()
                root.CFrame = CFrame.lookAt(root.Position, Vector3.new(t.hrp.Position.X, root.Position.Y + 0.01, t.hrp.Position.Z))
            end)
        end
        swingTool()
        count = count + 1
        if KillAura.Settings.Particles then
            pcall(function()
                local pe = getAuraParticle()
                pe.Attachment.Position = t.hrp.Position
                pe.Enabled = true
                pe:Emit(8)
                task.delay(0.2, function() pe.Enabled = false end)
            end)
        end
    end
    if count > 0 then _kaLast = tick() end
end)

-- Velocity (Anti-Knockback): counteract horizontal knockback velocity.
local Velocity = makeModule("Velocity", "Combat", { Horizontal = 100, Vertical = 0 })
RunService.Heartbeat:Connect(function()
    if not Velocity.Enabled then return end
    local root = getRoot()
    if not root then return end
    local v = root.AssemblyLinearVelocity
    local hPct = (100 - Velocity.Settings.Horizontal) / 100
    local vPct = (100 - Velocity.Settings.Vertical) / 100
    root.AssemblyLinearVelocity = Vector3.new(v.X * hPct, v.Y * vPct, v.Z * hPct)
end)

-- Criticals: force a small hop right before a swing so the game registers a crit.
local Criticals = makeModule("Criticals", "Combat", {})
local _critReady = false
RunService.Heartbeat:Connect(function()
    if not Criticals.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    local grounded = hum.FloorMaterial ~= Enum.Material.Air
    if grounded and Mouse:IsButtonDown() then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 24, root.AssemblyLinearVelocity.Z) end)
    end
end)

-- Reach: expand the detection so clicks register from further away (hitbox based).
local Reach = makeModule("Reach", "Combat", { Distance = 12 })
RunService.Heartbeat:Connect(function()
    if not Reach.Enabled then return end
    for _, t in ipairs(getTargetsInRange(Reach.Settings.Distance, true, true)) do
        pcall(function()
            if not t.hrp:GetAttribute("ReachHitbox") then
                t.hrp:SetAttribute("ReachHitbox", true)
                t.hrp:SetAttribute("ReachOrigSize", HttpService:JSONEncode({ t.hrp.Size.X, t.hrp.Size.Y, t.hrp.Size.Z }))
            end
        end)
    end
end)
function Reach.OnToggle(state)
    if not state then
        pcall(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp:GetAttribute("ReachHitbox") then
                        hrp:SetAttribute("ReachHitbox", nil)
                        local s = hrp:GetAttribute("ReachOrigSize")
                        if s then local d = HttpService:JSONDecode(s); hrp.Size = Vector3.new(d[1], d[2], d[3]) end
                    end
                end
            end
        end)
    end
end

-- AutoClicker: click while the mouse button is held (configurable CPS).
local AutoClicker = makeModule("AutoClicker", "Combat", { CPS = 12, HoldMode = true })
local _acLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoClicker.Enabled then return end
    if AutoClicker.Settings.HoldMode and not UserInputService:IsMous