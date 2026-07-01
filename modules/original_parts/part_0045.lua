--------------
-- TPAURA / TELEPORT AURA  (teleport-strike each nearby enemy in sequence)
------------------------------------------------------------
local TPAura = makeModule("TPAura", "Combat", { Range = 40, Delay = 0.2 })
local _tpaLast = 0
RunService.Heartbeat:Connect(function()
    if not TPAura.Enabled then return end
    if tick() - _tpaLast < TPAura.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    local best, bestD = nil, TPAura.Settings.Range
    for _, t in ipairs(getTargetsInRange(TPAura.Settings.Range, false, true)) do
        if t.dist < bestD then bestD = t.dist; best = t end
    end
    if best then
        _tpaLast = tick()
        pcall(function()
            TeleportPro.pushHistory()
            root.CFrame = best.hrp.CFrame * CFrame.new(0, 0, 4)
            swingTool()
        end)
    end
end)

------------------------------------------------------------
-- BRINGER  (pull all nearby enemies/objects toward you continuously)
------------------------------------------------------------
local Bringer = makeModule("Bringer", "World", { Range = 60, Targets = "Players" })
RunService.Heartbeat:Connect(function()
    if not Bringer.Enabled then return end
    local root = getRoot()
    if not root then return end
    if Bringer.Settings.Targets == "Players" then
        for _, t in ipairs(getTargetsInRange(Bringer.Settings.Range, false, true)) do
            pcall(function() t.hrp.CFrame = root.CFrame * CFrame.new(0, 0, -3) end)
        end
    else
        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                local hrp = d:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - root.Position).Magnitude < Bringer.Settings.Range then
                    pcall(function() hrp.CFrame = root.CFrame * CFrame.new(0, 0, -3) end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- FLING PLAYER  (select a player and fling them away)
------------------------------------------------------------
local FlingTarget = makeModule("FlingTarget", "Combat", {})
function FlingTarget.OnToggle(state)
    if state then
        notify("Fling", "Select a player in the Players panel, then click again.", 3, Theme.Yellow)
    end
end

------------------------------------------------------------
-- TRAIL / FOOTPRINTS  (leave glowing footprints behind you)
------------------------------------------------------------
local Footprints = makeModule("Footprints", "Render", { Color = Color3.fromRGB(122, 92, 255) })
local _fpParts = {}
local _fpLast = 0
RunService.Heartbeat:Connect(function()
    if not Footprints.Enabled then
        for _, p in ipairs(_fpParts) do pcall(function() p:Destroy() end) end
        _fpParts = {}
        return
    end
    local root = getRoot()
    if not root then return end
    if tick() - _fpLast > 0.15 then
        _fpLast = tick()
        local p = Instance.new("Part")
        p.Shape = Enum.PartType.Ball
        p.Size = Vector3.new(0.6, 0.6, 0.6)
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.Material = Enum.Material.Neon
        p.Color = Footprints.Settings.Color
        p.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.5, 0))
        p.Parent = Workspace
        table.insert(_fpParts, p)
        task.delay(3, function() pcall(function() p:Destroy() end) end)
        if #_fpParts > 60 then
            local old = table.remove(_fpParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- PLAYER VIEWPOINT  (see through another player's camera)
------------------------------------------------------------
local PlayerView = { Enabled = false, Target = nil, _conn = nil }
function PlayerView:Set(v)
    self.Enabled = v
    if v then
        self._conn = RunService.RenderStepped:Connect(function()
            local target = self.Target
            if target and target.Character then
                local head = target.Character:FindFirstChild("Head")
                if head then
                    pcall(function()
                        Camera.CameraType = Enum.CameraType.Scriptable
                        Camera.CFrame = head.CFrame * CFrame.new(0, 0, -3)
                    end)
                end
            end
        end)
    else
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

------------------------------------------------------------
-- AUTO DODGE PLAYER  (teleport away when a player aims at you)
------------------------------------------------------------
local AutoDodgePlayer = makeModule("AutoDodgePlayer", "Combat", { Range = 30 })
RunService.Heartbeat:Connect(function()
    if not AutoDodgePlayer.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                -- if a player's look vector points near us, dodge
                local toMe = (root.Position - head.Position).Unit
                local look = head.CFrame.LookVector
                local dot = look:Dot(toMe)
                local dist = (head.Position - root.Position).Magnitude
                if dot > 0.95 and dist < AutoDodgePlayer.Settings.Range then
                    local side = toMe:Cross(Vector3.new(0, 1, 0))
                    if side.Magnitude > 0 then
                        pcall(function() root.CFrame = root.CFrame + side.Unit * 8 end)
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- INFINITE AMMO  (best-effort: reset ammo values)
------------------------------------------------------------
local InfiniteAmmo = makeModule("InfiniteAmmo", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not InfiniteAmmo.Enabled then return end
    pcall(function()
        local char = getChar()
        local tool = char and char:FindFirstChildOfClass("Tool")
        if tool then
            -- many games store ammo as attributes/values
            tool:SetAttribute("Ammo", 999)
            tool:SetAttribute("Magazine", 999)
            tool:SetAttribute("Clip", 999)
            local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Magazine")
            if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
        end
        trySetStat("ammo", 999)
    end)
end)

------------------------------------------------------------
-- NO SPREAD  (reduce camera shake/spread via steady CFrame)
------------------------------------------------------------
local NoSpread = makeModule("NoSpread", "Combat", {})
local _nsOldFOV
RunService.RenderStepped:Connect(function()
    if not NoSpread.Enabled then return end
    pcall(function()
        -- neutralize field-of-view punch effects
        Camera.FieldOfView = CameraFOV.Enabled and CameraFOV.Value or 70
    end)
end)

------------------------------------------------------------
-- INSTANT BREAK  (break all destructibles within range)
------------------------------------------------------------
local InstantBreak = makeModule("InstantBreak", "World", { Range = 50 })
RunService.Heartbeat:Connect(function()
    if not InstantBreak.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("break") or n:find("destroy") or n:find("glass") or n:find("destructible") then
                if (d.Position - root.Position).Magnitude < InstantBreak.Settings.Range then
                    pcall(function()
                        firetouchinterest(root, d, 0)
                        d.CanCollide = false
                    end)
                end
            end
        end
    end
    fireRemotes("break"); fireRemotes("destroy")
end)

------------------------------------------------------------
-- AUTO REVIVE TEAMMATES  (teleport to & touch downed allies)
------------------------------------------------------------
local AutoReviveTeam = makeModule("AutoReviveTeam", "Player", { Range = 200 })
RunService.Heartbeat:Connect(function()
    if not AutoReviveTeam.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                -- can't revive a fully dead player; look for "downed" state
            end
            if hum and hrp and hum:GetState() == Enum.HumanoidStateType.PlatformStanding then
                if (hrp.Position - root.Position).Magnitude < AutoReviveTeam.Settings.Range then
                    pcall(function()
                        root.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 3, 0))
                        firetouchinterest(root, hrp, 0)
                    end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- AFK TELEPORT LOOP  (walk a small box to stay active)
------------------------------------------------------------
local AFKTeleport = makeModule("AFKTeleport", "Player", { Delay = 10 })
local _afkPos
RunService.Heartbeat:Connect(function()
    if not AFKTeleport.Enabled then return end
    if not _afkPos then local root = getRoot(); if root then _afkPos = root.Position end end
    if not AFKTeleport._t or tick() - AFKTeleport._t > AFKTeleport.Settings.Delay then
        AFKTeleport._t = tick()
        local root = getRoot()
        if root and _afkPos then
            -- small random offset to trigger movement
            pcall(function()
                root.CFrame = CFrame.new(_afkPos + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5)))
            end)
        end
    end
end)

------------------------------------------------------------
-- COPY TELEPORT  (teleport to a copied CFrame from clipboard)
------------------------------------------------------------
local function teleportFromClipboard()
    pcall(function()
        if not (getclipboard or readclipboard) then notify("Teleport", "No clipboard access.", 2.5, Theme.Yellow); return end
        local txt = (getclipboard and getclipboard()) or (readclipboard and readclipboard()) or ""
        -- parse "x, y, z"
        local nums = {}
        for n in txt:gmatch("-?%d+%.?%d*") do table.insert(nums, tonumber(n)) end
        if #nums >= 3 then
            teleportTo(Vector3.new(nums[1], nums[2], nums[3]))
            notify("Teleport", "Teleported to clipboard coords.", 3, Theme.Accent)
        else
            notify("Teleport", "Clipboard has no valid coords.", 2.5, Theme.Yellow)
        end
    end)
end

------------------------------------------------------------
-- AUTO LOBBY REJOIN  (rejoin if alone for too long)
------------------------------------------------------------
local LobbyRejoin = makeModule("LobbyRejoin", "Player", { MinPlayers = 1, CheckDelay = 30 })
RunService.Heartbeat:Connect(function()
    if not LobbyRejoin.Enabled then return end
    if not LobbyRejoin._t or tick() - LobbyRejoin._t > LobbyRejoin.Settings.CheckDelay then
        LobbyRejoin._t = tick()
        if #Players:GetPlayers() <= LobbyRejoin.Settings.MinPlayers then
            if not LobbyRejoin._waitStart then LobbyRejoin._waitStart = tick() end
            if tick() - LobbyRejoin._waitStart > 60 then
                notify("LobbyRejoin", "Server seems empty - rejoining.", 3, Theme.Yellow)
                pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                LobbyRejoin._waitStart = nil
            end
        else
            LobbyRejoin._waitStart = nil
        end
    end
end)

------------------------------------------------------------
-- NPC FARM ROUTE  (teleport between all NPC spawns in a loop)
------------------------------------------------------------
local NPCFarmRoute = makeModule("NPCFarmRoute", "Combat", { Delay = 0.3, Range = 30 })
local _nfrIndex = 1
local _nfrLast = 0
RunService.Heartbeat:Connect(function()
    if not NPCFarmRoute.Enabled then return end
    if tick() - _nfrLast < NPCFarmRoute.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    -- collect all NPCs
    local npcs = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
            local hrp = d:FindFirstChild("HumanoidRootPart")
            local hum = d:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then table.insert(npcs, { char = d, hrp = hrp, hum = hum }) end
        end
    end
    if #npcs == 0 then return end
    _nfrIndex = (_nfrIndex % #npcs) + 1
    local target = npcs[_nfrIndex]
    _nfrLast = tick()
    pcall(function()
        root.CFrame = target.hrp.CFrame * CFrame.new(0, 0, NPCFarmRoute.Settings.Range)
    end)
    swingTool()
end)

------------------------------------------------------------
-- INVENTORY ESP  (highlight dropped tools / items on the ground)
------------------------------------------------------------
local InventoryESP = makeModule("InventoryESP", "Render", {})
function InventoryESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not InventoryESP.Enabled then return end
    highlightKeywords({ "tool", "weapon", "item", "drop", "pickup", "sword", "gun", "potion" }, Color3.fromRGB(120, 220, 255))
end)

------------------------------------------------------------
-- AUTO QUEST  (fire quest-related remotes continuously)
------------------------------------------------------------
local AutoQuest = makeModule("AutoQuest", "World", {})
RunService.Heartbeat:Connect(function()
    if not AutoQuest.Enabled then return end
    fireRemotes("quest"); fireRemotes("accept"); fireRemotes("turnin"); fireRemotes("claimquest")
end)

------------------------------------------------------------
-- ANTI STUN  (auto-recover from stun/freeze states)
------------------------------------------------------------
local AntiStun = makeModule("AntiStun", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not AntiStun.Enabled then return end
    local hum = getHum()
    if not hum then return end
    -- force out of stunned/frozen states
    local state = hum:GetState()
    if state == Enum.HumanoidStateType.FallingDown
    or state == Enum.HumanoidStateType.Ragdoll
    or state == Enum.HumanoidStateType.PlatformStanding then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    -- clear slow/stun attributes
    pcall(function()
        local root = getRoot()
        if root then root:SetAttribute("Stunned", false); root:SetAttribute("Frozen", false) end
    end)
end)

------------------------------------------------------------
-- AUTO COLLECT DROPS  (touch any dropped/loot parts within range)
------------------------------------------------------------
local AutoDrops = makeModule("AutoDrops", "World", { Range = 80 })
RunService.Heartbeat:Connect(function()
    if not AutoDrops.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("drop") or n:find("loot") or n:find("pickup") or n:find("reward") then
                if (d.Position - root.Position).Magnitude < AutoDrops.Settings.Range then
                    pcall(function() firetouchinterest(root, d, 0) end)
                end
            end
        end
    end
end)

------------------------------------------------------------
-- GHOST / VANISH  (make local character semi-invisible to avoid detection)
------------------------------------------------------------
local Ghost = makeModule("Ghost", "Render", {})
local _ghostOrig = {}
function Ghost.OnToggle(state)
    pcall(function()
        local char = getChar()
        if not char then return end
        if state then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                    if not _ghostOrig[p] then _ghostOrig[p] = p.LocalTransparencyModifier end
                    p.LocalTransparencyModifier = 0.6
                end
            end
        else
            for p, v in pairs(_ghostOrig) do
                if p and p.Parent then p.LocalTransparencyModifier = v end
            end
            _ghostOrig = {}
        end
    end)
end

------------------------------------------------------------
-- HEAD HITBOX  (force target the head part for all combat)
------------------------------------------------------------
local HeadTarget = makeModule("HeadTarget", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not HeadTarget.Enabled then return end
    Aimbot.Config.TargetPart = "Head"
    SilentAim.Settings.Part = "Head"
end)
function HeadTarget.OnToggle(state)
    if not state then
        Aimbot.Config.TargetPart = "HumanoidRootPart"
        SilentAim.Settings.Part = "HumanoidRootPart"
    end
end)

------------------------------------------------------------
-- BUNNY HOP  (auto-jump while moving for FPS games)
------------------------------------------------------------
local BunnyHop = makeModule("BunnyHop", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not BunnyHop.Enabled then return end
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
    end
end)

------------------------------------------------------------
-- INSTANT INTERACT  (touch all interactable parts within range)
------------------------------------------------------------
local InstantInteract = makeModule("InstantInteract", "World", { Range = 50 })
RunService.Heartbeat:Connect(function()
    if not InstantInteract.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("interact") or n:find("prompt") or n:find("use") or n:find("button") or n:find("lever") then
                if (d.Position - root.Position).Magnitude < InstantInteract.Settings.Range then
                    pcall(function() firetouchinterest(root, d, 0) end)
                end
            end
        end
    end
    fireRemotes("interact")
end)

------------------------------------------------------------
-- WAYPOINT VISUALS  (render beacons at saved waypoints)
------------------------------------------------------------
local WaypointVisuals = makeModule("WaypointVisuals", "Render", {})
local _wpParts = {}
function WaypointVisuals.OnToggle(state)
    if not state then
        for _, p in ipairs(_wpParts) do pcall(function() p:Destroy() end) end
        _wpParts = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not WaypointVisuals.Enabled then return end
    for _, p in ipairs(_wpParts) do pcall(function() p:Destroy() end) end
    _wpParts = {}
    for _, wp in ipairs(Waypoints.List) do
        local part = Instance.new("Part")
        part.Shape = Enum.PartType.Ball
        part.Size = Vector3.new(2, 2, 2)
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(122, 92, 255)
        part.CFrame = CFrame.new(wp.pos[1], wp.pos[2], wp.pos[3])
        part.Parent = Workspace
        table.insert(_wpParts, part)
        local beam = Instance.new("Beam")
        -- simple vertical beam via two attachments
        local a0 = Instance.new("Attachment"); a0.Parent = part
        local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, 60, 0); a1.Parent = part
        beam.Attachment0 = a0; beam.Attachment1 = a1
        beam.Width0 = 0.2; beam.Width1 = 0.2
        beam.FaceCamera = true
        beam.Color = ColorSequence.new(Color3.fromRGB(122, 92, 255))
        beam.Transparency = NumberSequence.new(0.5, 1)
        beam.Parent = part
    end
end)

------------------------------------------------------------
-- AUTO TELEPORT TO WAYPOINTS  (cycle through saved waypoints)
------------------------------------------------------------
local AutoWaypoint = makeModule("AutoWaypoint", "Movement", { Delay = 3 })
local _awIndex = 1
local _awLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoWaypoint.Enabled then return end
    if #Waypoints.List == 0 then return end
    if tick() - _awLast < AutoWaypoint.Settings.Delay then return end
    _awLast = tick()
    _awIndex = (_awIndex % #Waypoints.List) + 1
    local wp = Waypoints.List[_awIndex]
    if wp then teleportTo(Vector3.new(wp.pos[1], wp.pos[2], wp.pos[3])) end
end)

------------------------------------------------------------
-- AUTO RESPAWN + RE-EQUIP  (respawn then re-equip best tool)
------------------------------------------------------------
local AutoRespawnEquip = makeModule("AutoRespawnEquip", "Player", { Delay = 1 })
RunService.Heartbeat:Connect(function()
    if not AutoRespawnEquip.Enabled then return end
    if not isAlive() then
        if not AutoRespawnEquip._t or tick() - AutoRespawnEquip._t > AutoRespawnEquip.Settings.Delay then
            AutoRespawnEquip._t = tick()
            task.spawn(function()
                pcall(function() LocalPlayer:LoadCharacter() end)
                task.wait(2)
                pcall(function()
                    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
                    local hum = getHum()
                    if bp and hum then
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then hum:EquipTool(t); break end
                        end
                    end
                end)
            end)
        end
    end
end)

------------------------------------------------------------
-- ANTI EXPLOSION  (teleport away from explosions)
------------------------------------------------------------
local AntiExplosion = makeModule("AntiExplosion", "Player", { Range = 40 })
RunService.Heartbeat:Connect(function()
    if not AntiExplosion.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("Explosion") or (d:IsA("BasePart") and d.Name:lower():find("explos")) then
            local pos = d:IsA("Explosion") and d.Position or d.Position
            if (pos - root.Position).Magnitude < AntiExplosion.Settings.Range then
                pcall(function() root.CFrame = root.CFrame + Vector3.new(0, 30, 0) end)
            end
        end
    end
end)

------------------------------------------------------------
-- AMMO / RELOAD HELPER  (auto reload when empty)
------------------------------------------------------------
local AutoReload = makeModule("AutoReload", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not AutoReload.Enabled then return end
    -- press R periodically (best-effort reload trigger)
    if not AutoReload._t or tick() - AutoReload._t > 2 then
        AutoReload._t = tick()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
        end)
    end
end)

------------------------------------------------------------
-- SOUND ESP  (visualize loud sounds / events as markers)
------------------------------------------------------------
local SoundESP = makeModule("SoundESP", "Render", {})
function SoundESP.OnToggle(state)
    if not state then
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d.Name == "HubSoundMarker" then d:Destroy() end
            end
        end)
    end
end
RunService.Heartbeat:Connect(function()
    if not SoundESP.Enabled then return end
    -- mark playing 3D sounds
    pcall(function()
        for _, s in ipairs(Workspace:GetDescendants()) do
            if s:IsA("Sound") and s.IsPlaying and not s:GetAttribute("HubMarked") then
                s:SetAttribute("HubMarked", true)
                task.delay(2, function() s:SetAttribute("HubMarked", nil) end)
                local parent = s.Parent
                if parent and parent:IsA("BasePart") and not parent:FindFirstChild("HubSoundMarker") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "HubSoundMarker"
                    hl.FillColor = Color3.fromRGB(255, 120, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = parent
                    task.delay(2, function() pcall(function() hl:Destroy() end) end)
                end
            end
        end
    end)
end)

------------------------------------------------------------
-- ANTI WATER / LAVA  (teleport up if touching water/lava)
------------------------------------------------------------
local AntiLiquid = makeModule("AntiLiquid", "Movement", {})
RunService.Heartbeat:Connect(function()
    if not AntiLiquid.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.FloorMaterial == Enum.Material.Lava or hum.FloorMaterial == Enum.Material.Water then
        pcall(function()
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 60, root.AssemblyLinearVelocity.Z)
        end)
    end
end)

------------------------------------------------------------
-- AUTO STAT  (dump player's stats to a readable format)
------------------------------------------------------------
local function dumpStats()
    local lines = {}
    local function scan(container, label)
        for _, v in ipairs(container:GetChildren()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("StringValue") or v:IsA("BoolValue") then
                table.insert(lines, label .. "." .. v.Name .. " = " .. tostring(v.Value))
            end
        end
    end
    if LocalPlayer:FindFirstChild("leaderstats") then scan(LocalPlayer.leaderstats, "leaderstats") end
    scan(LocalPlayer, "player")
    return table.concat(lines, "\n")
end

------------------------------------------------------------
-- NO HEADSHOT  (resize own head to dodge headshots - cosmetic)
------------------------------------------------------------
local NoHeadshot = makeModule("NoHeadshot", "Render", {})
local _nhOrig
function NoHeadshot.OnToggle(state)
    pcall(function()
        local char = getChar()
        local head = char and char:FindFirstChild("Head")
        if not head then return end
        if state then
            if not _nhOrig then _nhOrig = head.Size end
            -- shrink locally only
            head.Size = Vector3.new(0.5, 0.5, 0.5)
        else
            if _nhOrig then head.Size = _nhOrig end
        end
    end)
end

------------------------------------------------------------
-- AIR STUCK / HANG  (freeze mid-air by cancelling gravity)
------------------------------------------------------------
local AirStuck = makeModule("AirStuck", "Movement", {})
local _asBV
RunService.Heartbeat:Connect(function()
    if not AirStuck.Enabled then
        if _asBV then pcall(function() _asBV:Destroy() end); _asBV = nil end
        return
    end
    local root = getRoot()
    if not root then return end
    if not _asBV then
        _asBV = Instance.new("BodyVelocity")
        _asBV.MaxForce = Vector3.new(0, 1e9, 0)
        _asBV.Velocity = Vector3.zero
        _asBV.Parent = root
    end
end)

------------------------------------------------------------
-- SLOW FALL  (gentle parachute-style descent)
------------------------------------------------------------
local SlowFall = makeModule("SlowFall", "Movement", { Speed = 20 })
RunService.Heartbeat:Connect(function()
    if not SlowFall.Enabled then return end
    local root = getRoot()
    if not root then return end
    if root.AssemblyLinearVelocity.Y < -SlowFall.Settings.Speed then
        pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, -SlowFall.Settings.Speed, root.AssemblyLinearVelocity.Z) end)
    end
end)

------------------------------------------------------------
-- FAST RESET  (instantly reset character)
------------------------------------------------------------
local FastReset = makeModule("FastReset", "Player", {})
function FastReset.OnToggle(state)
    if state then
        pcall(function() LocalPlayer.Character:BreakJoints() end)
        FastReset:Set(false)
    end
end

------------------------------------------------------------
-- SERVER LAG INDICATOR  (monitor server performance)
------------------------------------------------------------
local ServerMonitor = makeHUDModule("Server", "Server performance", function(lbl)
    local fps = math.floor(Workspace:GetRealPhysicsFPS())
    local players = #Players:GetPlayers()
    lbl.Text = "SVR " .. fps .. "fps | " .. players .. "p"
end)
ServerMonitor._delay = 1

------------------------------------------------------------
-- AUTO SELL ALL  (fire every sell remote)
------------------------------------------------------------
local AutoSellAll = makeModule("AutoSellAll", "World", { Delay = 1 })
local _asaLast
RunService.Heartbeat:Connect(function()
    if not AutoSellAll.Enabled then return end
    if _asaLast and tick() - _asaLast < AutoSellAll.Settings.Delay then return end
    _asaLast = tick()
    fireRemotes("sell")
end)

------------------------------------------------------------
-- GRAVITY CONTROL MODULE  (live gravity multiplier)
------------------------------------------------------------
local GravityMod = makeModule("GravityMod", "Movement", { Mult = 1 })
local _gOrigGravity
RunService.Heartbeat:Connect(function()
    if not GravityMod.Enabled then
        if _gOrigGravity then Workspace.Gravity = _gOrigGravity; _gOrigGravity = nil end
        return
    end
    if not _gOrigGravity then _gOrigGravity = Workspace.Gravity end
    Workspace.Gravity = 196.2 * GravityMod.Settings.Mult
end)

------------------------------------------------------------
-- AUTO CLAIM CHESTS  (teleport to & touch all chests)
------------------------------------------------------------
local AutoChests = makeModule("AutoChests", "World", { Delay = 0.5, Range = 1000 })
local _acIndex = 1
local _acLast = 0
RunService.Heartbeat:Connect(function()
    if not AutoChests.Enabled then return end
    if tick() - _acLast < AutoChests.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    local chests = {}
    for _, d in ipairs(Workspace:GetDescendants()) do
        if (d:IsA("Model") or d:IsA("BasePart")) and d.Name:lower():find("chest") then
            local p = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
            if p then table.insert(chests, p) end
        end
    end
    if #chests == 0 then return end
    _acIndex = (_acIndex % #chests) + 1
    _acLast = tick()
    local c = chests[_acIndex]
    pcall(function()
        root.CFrame = c.CFrame + Vector3.new(0, 3, 0)
        firetouchinterest(root, c, 0)
    end)
end)

------------------------------------------------------------
-- COORDS HUD  (vape-style: show current X/Y/Z position)
------------------------------------------------------------
local CoordsHUD = makeHUDModule("Coords", "Shows your current position", function(lbl)
    local root = getRoot()
    if root then
        local p = root.Position
        lbl.Text = string.format("X:%.0f Y:%.0f Z:%.0f", p.X, p.Y, p.Z)
    else
        lbl.Text = "X:0 Y:0 Z:0"
    end
end)
CoordsHUD._delay = 0.2

------------------------------------------------------------
-- SERVER INFO HUD  (show server player count + JobId)
------------------------------------------------------------
local ServerHUD = makeHUDModule("Server", "Server info", function(lbl)
    lbl.Text = string.format("Players: %d  |  JobId: %s", #Players:GetPlayers(), tostring(game.JobId):sub(1, 8))
end)
ServerHUD._delay = 1

------------------------------------------------------------
-- DAMAGE NUMBERS  (vape-style: show floating damage numbers)
------------------------------------------------------------
local DamageNumbers = makeModule("DamageNumbers", "Render", {})
local _dmgFolder
local function getDmgFolder()
    if _dmgFolder and _dmgFolder.Parent then return _dmgFolder end
    _dmgFolder = Instance.new("Folder")
    _dmgFolder.Name = "HubDamageNumbers"
    _dmgFolder.Parent = Workspace
    return _dmgFolder
end
local function showDamageNumber(pos, amount, color)
    local part = Instance.new("Part")
    part.Size = Vector3.new(0.2, 0.2, 0.2)
    part.Transparency = 1
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CFrame = CFrame.new(pos)
    part.Parent = getDmgFolder()
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 60, 0, 24)
    bb.AlwaysOnTop = true
    bb.Parent = part
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Theme.FontBold
    lbl.TextSize = 20
    lbl.TextColor3 = color or Color3.fromRGB(255, 220, 80)
    lbl.TextStrokeTransparency = 0.3
    lbl.Text = tostring(amount)
    lbl.Parent = bb
    local start = pos + Vector3.new(0, 2, 0)
    local ende = pos + Vector3.new(0, 6, 0)
    local t0 = tick()
    task.spawn(function()
        while tick() - t0 < 1 do
            local a = (tick() - t0) / 1
            part.CFrame = CFrame.new(start:Lerp(ende, a))
            lbl.TextTransparency = a
            lbl.TextStrokeTransparency = 0.3 + a * 0.7
            task.wait()
        end
        part:Destroy()
    end)
end
-- hook KillAura swings to show numbers near targets
local _dnLast = {}
RunService.Heartbeat:Connect(function()
    if not DamageNumbers.Enabled then return end
    for _, t in ipairs(getTargetsInRange(KillAura.Settings.AttackRange, true, true)) do
        if not _dnLast[t.hrp] or tick() - _dnLast[t.hrp] > 0.4 then
            _dnLast[t.hrp] = tick()
            local dmg = math.random(4, 18)
            showDamageNumber(t.hrp.Position + Vector3.new(math.random(-1,1), 2, math.random(-1,1)), dmg, Color3.fromRGB(255, 220, 80))
        end
    end
end)

------------------------------------------------------------
-- HIT INDICATOR  (red arc flash when you take damage)
------------------------------------------------------------
local HitIndicator = makeModule("HitIndicator", "Render", {})
local _hiFrame
function HitIndicator.OnToggle(state)
    if state then
        if not (_hiFrame and _hiFrame.Parent) then
            _hiFrame = Instance.new("ImageLabel")
            _hiFrame.Name = "HitIndicator"
            _hiFrame.Size = UDim2.new(0, 120, 0, 120)
            _hiFrame.Position = UDim2.new(0.5, -60, 0.5, -60)
            _hiFrame.BackgroundTransparency = 1
            _hiFrame.Image = "rbxassetid://0"
            _hiFrame.ImageTransparency = 1
            _hiFrame.ZIndex = 8
            _hiFrame.Parent = ScreenGui
            -- draw a red ring via a frame circle
            local ring = Instance.new("Frame")
            ring.Size = UDim2.new(1, 0, 1, 0)
            ring.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
            ring.BackgroundTransparency = 1
            ring.BorderSizePixel = 0
            ring.ZIndex = 9
            ring.Parent = _hiFrame
            corner(ring, UDim.new(1, 0))
            stroke(ring, Color3.fromRGB(255, 40, 40), 3, 1)
            _hiFrame._ring = ring
        end
    end
end
local _lastHP
RunService.Heartbeat:Connect(function()
    if not HitIndicator.Enabled then return end
    local h = getHum()
    if not h then return end
    if _lastHP and h.Health < _lastHP and _hiFrame and _hiFrame._ring then
        _hiFrame._ring.BackgroundTransparency = 0.4
        tween(_hiFrame._ring, 0.5, { BackgroundTransparency = 1 })
    end
    _lastHP = h.Health
end)

------------------------------------------------------------
-- FPS BOOST PRESETS  (vape-style graphics reduction)
------------------------------------------------------------
local FPSBoost = makeModule("FPSBoost", "Render", { Level = 2 })
local _fbStored = {}
function FPSBoost.OnToggle(state)
    if state then
        local level = FPSBoost.Settings.Level
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and not d:IsA("Terrain") then
                    if level >= 1 then
                        if not d:GetAttribute("FBShadow") then d:SetAttribute("FBShadow", d.CastShadow and 1 or 0); d.CastShadow = false end
                    end
                    if level >= 2 then
                        if not d:GetAttribute("FBMat") then d:SetAttribute("FBMat", tostring(d.Material)); d.Material = Enum.Material.Plastic end
                    end
                    if level >= 3 then
                        if not d:GetAttribute("FBTrans") then d:SetAttribute("FBTrans", tostring(d.Transparency)); d.Transparency = math.max(d.Transparency, 0.3) end
                    end
                end
            end
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 1e9
            Workspace.StreamingTargetRadius = 512
        end)
        notify("FPS Boost", "Level " .. level .. " applied.", 3, Theme.Green)
    else
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    local sh = d:GetAttribute("FBShadow")
                    if sh ~= nil then d.CastShadow = sh == 1; d:SetAttribute("FBShadow", nil) end
                    local mat = d:GetAttribute("FBMat")
                    if mat then d.Material = Enum.Material[mat]; d:SetAttribute("FBMat", nil) end
                    local tr = d:GetAttribute("FBTrans")
                    if tr then d.Transparency = tonumber(tr); d:SetAttribute("FBTrans", nil) end
                end
            end
        end)
        notify("FPS Boost", "Restored graphics.", 3, Theme.Yellow)
    end
end

------------------------------------------------------------
-- GROUND / FLOOR CHECK HELPER  (used by movement modules)
------------------------------------------------------------
local function isGrounded()
    local hum = getHum()
    return hum ~= nil and hum.FloorMaterial ~= Enum.Material.Air
end

------------------------------------------------------------
-- AUTO DODGE  (vape-style: teleport away from incoming projectiles)
------------------------------------------------------------
local AutoDodge = makeModule("AutoDodge", "Combat", { Range = 40 })
RunService.Heartbeat:Connect(function()
    if not AutoDodge.Enabled then return end
    local root = getRoot()
    if not root then return end
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") then
            local n = d.Name:lower()
            if n:find("bullet") or n:find("projectile") or n:find("fireball") or n:find("rocket") then
                local dist = (d.Position - root.Position).Magnitude
                local vel = d.AssemblyLinearVelocity
                if dist < AutoDodge.Settings.Range and vel.Magnitude > 20 then
                    -- move perpendicular to the projectile's velocity
                    local rel = root.Position - d.Position
                    local side = rel:Cross(Vector3.new(0, 1, 0))
                    if side.Magnitude > 0 then
                        pcall(function() root.CFrame = root.CFrame + side.Unit * 6 end)
                    end
                end
            end
        end
    end
end)

------------------------------------------------------------
-- SNEAK  (vape Sneak: crouch + controllable sneak speed)
------------------------------------------------------------
local Sneak = makeModule("Sneak", "Movement", { Speed = 8 })
RunService.Heartbeat:Connect(function()
    if not Sneak.Enabled then return end
    local hum = getHum()
    if hum then
        pcall(function() hum.CrouchSpeed = Sneak.Settings.Speed end)
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            hum:ChangeState(Enum.HumanoidStateType.Seated)
        end
    end
end)

------------------------------------------------------------
-- TIMER  (vape Timer: speed up / slow down the local time perception)
------------------------------------------------------------
local Timer = makeModule("Timer", "Render", { Multiplier = 1 })
local _timerStartTick, _timerStartClock
RunService.Heartbeat:Connect(function()
    if not Timer.Enabled then return end
    -- manipulate local heartbeat perception is not possible; instead nudge Lighting clock
    pcall(function()
        local m = Timer.Settings.Multiplier
        Lighting.ClockTime = (Lighting.ClockTime + (m - 1) * 0.01) % 24
    end)
end)

------------------------------------------------------------
-- VIEWPORT CLIP  (vape ViewportClip: zoom the viewport via FOV clamp)
------------------------------------------------------------
local ViewportClip = makeModule("ViewportClip", "Render", { Min = 70, Max = 90 })
RunService.RenderStepped:Connect(function()
    if not ViewportClip.Enabled then return end
    pcall(function()
        Camera.FieldOfView = math.clamp(Camera.FieldOfView, ViewportClip.Settings.Min, ViewportClip.Settings.Max)
    end)
end)

------------------------------------------------------------
-- TOWER ESP  (vape TowerESP: highlight spawn towers / structures)
------------------------------------------------------------
local TowerESP = makeModule("TowerESP", "Render", {})
function TowerESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not TowerESP.Enabled then return end
    highlightKeywords({ "tower", "spire", "spawn", "base", "keep", "castle", "nexus", "core" }, Color3.fromRGB(120, 180, 255))
end)

------------------------------------------------------------
-- HEALTHBAR ESP  (billboard health bars above each enemy)
------------------------------------------------------------
local HealthbarESP = makeModule("HealthbarESP", "Render", { TeamCheck = true })
local _hbBars = {}
function HealthbarESP.OnToggle(state)
    if not state then
        for _, b in pairs(_hbBars) do pcall(function() b:Destroy() end) end
        _hbBars = {}
    end
end
RunService.Heartbeat:Connect(function()
    if not HealthbarESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not _hbBars[plr] then
            if not (HealthbarESP.Settings.TeamCheck and plr.Team and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if head and hum then
                    local bb = Instance.new("BillboardGui")
                    bb.Adornee = head
                    bb.AlwaysOnTop = true
                    bb.Size = UDim2.new(0, 50, 0, 6)
                    bb.StudsOffset = Vector3.new(0, 2.6, 0)
                    bb.Parent = head
                    local bkg = Instance.new("Frame")
                    bkg.Size = UDim2.new(1, 0, 1, 0)
                    bkg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    bkg.BorderSizePixel = 0
                    bkg.Parent = bb
                    corner(bkg, UDim.new(1, 0))
                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new(1, 0, 1, 0)
                    fill.BackgroundColor3 = Color3.fromRGB(76, 209, 142)
                    fill.BorderSizePixel = 0
                    fill.Parent = bkg
                    corner(fill, UDim.new(1, 0))
                    _hbBars[plr] = { bb = bb, fill = fill, hum = hum, con = hum.HealthChanged:Connect(function(h)
                        local pct = math.clamp(h / math.max(hum.MaxHealth, 1), 0, 1)
                        fill.Size = UDim2.new(pct, 0, 1, 0)
                        fill.BackgroundColor3 = Color3.fromHSV(pct / 2.5, 0.8, 0.8)
     