nd)
end)

------------------------------------------------------------
-- AUTO BLOCK / PLACE BLOCK  (scaffold alternative for build games)
------------------------------------------------------------
local AutoBlock = makeModule("AutoBlock", "World", {})
local _abParts = {}
RunService.Heartbeat:Connect(function()
    if not AutoBlock.Enabled then
        for _, p in ipairs(_abParts) do pcall(function() p:Destroy() end) end
        _abParts = {}
        return
    end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    -- place a block in front when moving
    if hum.MoveDirection.Magnitude > 0 then
        local p = Instance.new("Part")
        p.Size = Vector3.new(4, 1, 4)
        p.Anchored = true
        p.CanCollide = true
        p.Material = Enum.Material.SmoothPlastic
        p.Color = Color3.fromRGB(80, 200, 120)
        p.CFrame = root.CFrame + hum.MoveDirection * 2 + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
        p.Parent = Workspace
        table.insert(_abParts, p)
        if #_abParts > 8 then
            local old = table.remove(_abParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- NUKER  (vape Nuker: destroy/place-break blocks rapidly around you)
------------------------------------------------------------
local Nuker = makeModule("Nuker", "World", { Range = 8, Mode = "Break" })
RunService.Heartbeat:Connect(function()
    if not Nuker.Enabled then return end
    local root = getRoot()
    if not root then return end
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { getChar() }
    local parts = Workspace:GetPartBoundsInRadius(root.Position, Nuker.Settings.Range, params)
    for _, p in ipairs(parts) do
        pcall(function()
            if Nuker.Settings.Mode == "Break" then
                fireRemotes("break"); fireRemotes("destroy")
                swingTool()
            elseif Nuker.Settings.Mode == "Touch" then
                firetouchinterest(root, p, 0)
            end
        end)
    end
end)

------------------------------------------------------------
-- AUTO SOUP  (vape AutoSoup: heal by using soup/food when low)
------------------------------------------------------------
local AutoSoup = makeModule("AutoSoup", "Combat", { Health = 50 })
RunService.Heartbeat:Connect(function()
    if not AutoSoup.Enabled then return end
    local hum = getHum()
    if not hum then return end
    if hum.Health < AutoSoup.Settings.Health then
        local char = getChar()
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        -- try to find & use a soup/food tool
        local function useFood(container)
            for _, t in ipairs(container:GetChildren()) do
                if t:IsA("Tool") then
                    local n = t.Name:lower()
                    if n:find("soup") or n:find("food") or n:find("potion") or n:find("heal") or n:find("bandage") then
                        pcall(function()
                            if container == bp then hum:EquipTool(t) end
                            t:Activate()
                            task.wait(0.1)
                            hum:UnequipTools()
                        end)
                        return true
                    end
                end
            end
            return false
        end
        if char then if useFood(char) then return end end
        if bp then useFood(bp) end
        -- fallback: refill health directly
        pcall(function() hum.Health = hum.MaxHealth end)
    end
end)

------------------------------------------------------------
-- AUTO TOTEM  (vape AutoTotem: auto-equip a totem/shield to off-hand)
------------------------------------------------------------
local AutoTotem = makeModule("AutoTotem", "Combat", {})
RunService.Heartbeat:Connect(function()
    if not AutoTotem.Enabled then return end
    local char = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    -- look for a "totem" tool and equip it
    local function findTotem(container)
        for _, t in ipairs(container:GetChildren()) do
            if t:IsA("Tool") and t.Name:lower():find("totem") then return t end
        end
    end
    if not char:FindFirstChildOfClass("Tool") then
        local totem = (char and findTotem(char)) or (bp and findTotem(bp))
        if totem then pcall(function() hum:EquipTool(totem) end) end
    end
end)

------------------------------------------------------------
-- TREE ESP  (vape-style: highlight trees for wood-cutting games)
------------------------------------------------------------
local TreeESP = makeModule("TreeESP", "Render", {})
function TreeESP.OnToggle(state)
    if not state then clearAutoHL() end
end
RunService.Heartbeat:Connect(function()
    if not TreeESP.Enabled then return end
    highlightKeywords({ "tree", "wood", "log", "trunk", "oak", "birch", "spruce" }, Color3.fromRGB(120, 200, 120))
end)

------------------------------------------------------------
-- MOB AURA  (like KillAura but only targets NPCs)
------------------------------------------------------------
local MobAura = makeModule("MobAura", "Combat", { Range = 15, Delay = 0.1 })
local _maLast = 0
RunService.Heartbeat:Connect(function()
    if not MobAura.Enabled then return end
    if tick() - _maLast < MobAura.Settings.Delay then return end
    local root = getRoot()
    if not root then return end
    for _, t in ipairs(getTargetsInRange(MobAura.Settings.Range, true, false)) do
        if not t.player then  -- only NPCs (no player key)
            if MobAura.Settings.Rotate then
                pcall(function() root.CFrame = CFrame.lookAt(root.Position, Vector3.new(t.hrp.Position.X, root.Position.Y, t.hrp.Position.Z)) end)
            end
            swingTool()
            _maLast = tick()
        end
    end
end)

------------------------------------------------------------
-- AUTO BRIDGE  (vape-style bridging: place blocks while moving forward)
------------------------------------------------------------
local AutoBridge = makeModule("AutoBridge", "World", {})
local _bridgeParts = {}
RunService.Heartbeat:Connect(function()
    if not AutoBridge.Enabled then
        for _, p in ipairs(_bridgeParts) do pcall(function() p:Destroy() end) end
        _bridgeParts = {}
        return
    end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude > 0 then
        local p = Instance.new("Part")
        p.Size = Vector3.new(6, 1, 6)
        p.Anchored = true
        p.CanCollide = true
        p.Material = Enum.Material.WoodPlanks
        p.Color = Color3.fromRGB(160, 110, 70)
        p.CFrame = root.CFrame + Vector3.new(0, -(hum.HipHeight + 3.2), 0)
        p.Parent = Workspace
        table.insert(_bridgeParts, p)
        if #_bridgeParts > 12 then
            local old = table.remove(_bridgeParts, 1)
            if old then pcall(function() old:Destroy() end) end
        end
    end
end)

------------------------------------------------------------
-- LONG JUMP  (vape LongJump: leap a long distance)
------------------------------------------------------------
local LongJump = makeModule("LongJump", "Movement", { Power = 60 })
RunService.Heartbeat:Connect(function()
    if not LongJump.Enabled then return end
    local root = getRoot()
    local hum = getHum()
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        pcall(function()
            local dir = hum.MoveDirection
            root.AssemblyLinearVelocity = Vector3.new(dir.X * LongJump.Settings.Power, 40, dir.Z * LongJump.Settings.Power)
        end)
        LongJump:Set(false)  -- single-use per activation
        notify("LongJump", "Jumped!", 1.5, Theme.Accent)
    end
end)

------------------------------------------------------------
-- BLINK  (vape Blink: teleport to where you're looking)
------------------------------------------------------------
local Blink = makeModule("Blink", "Movement", { Range = 60 })
function Blink.OnToggle(state)
    if state then
        local root = getRoot()
        if root then
            local target = root.Position + Camera.CFrame.LookVector * Blink.Settings.Range
            -- raycast to avoid teleporting into walls
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { getChar() }
            local hit = Workspace:Raycast(root.Position, Camera.CFrame.LookVector * Blink.Settings.Range, params)
            if hit then target = hit.Position end
            pcall(function() root.CFrame = CFrame.new(target + Vector3.new(0, 3, 0)) end)
        end
        Blink:Set(false)  -- instant, single-use
    end
end

------------------------------------------------------------
-- HIGH JUMP  (extra high single jump)
------------------------------------------------------------
local HighJump = makeModule("HighJump", "Movement", { Power = 120 })
function HighJump.OnToggle(state)
    if state then
        local root = getRoot()
        if root then
            pcall(function() root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, HighJump.Settings.Power, root.AssemblyLinearVelocity.Z) end)
        end
        HighJump:Set(false)
    end
end

------------------------------------------------------------
-- ORBIT TP  (teleport in a circle of saved positions, hands-free farming)
------------------------------------------------------------
local OrbitTP = makeModule("OrbitTP", "Movement", { Radius = 8, Speed = 1.2, Height = 0 })
local _orbitAngle = 0
RunService.RenderStepped:Connect(function(dt)
    if not OrbitTP.Enabled then return end
    local root = getRoot()
    if not root then return end
    _orbitAngle = _orbitAngle + dt * OrbitTP.Settings.Speed
    local r = OrbitTP.Settings.Radius
    local offset = Vector3.new(math.cos(_orbitAngle) * r, OrbitTP.Settings.Height, math.sin(_orbitAngle) * r)
    pcall(function() root.CFrame = root.CFrame + offset * dt * 5 end)
end)

------------------------------------------------------------
-- SWAY / ANTI AFK WALK  (gentle figure-8 movement to avoid AFK kicks)
------------------------------------------------------------
local AntiAFKWalk = makeModule("AntiAFKWalk", "Player", { Speed = 1 })
local _aafAngle = 0
RunService.Heartbeat:Connect(function(dt)
    if not AntiAFKWalk.Enabled then return end
    local hum = getHum()
    local root = getRoot()
    if not (hum and root) then return end
    _aafAngle = _aafAngle + dt * AntiAFKWalk.Settings.Speed
    hum:Move(Vector3.new(math.cos(_aafAngle), 0, math.sin(_aafAngle * 2)) * 0.5, false)
end)

------------------------------------------------------------
-- SLIDE  (quick dash on shift)
------------------------------------------------------------
local Slide = makeModule("Slide", "Movement", { Power = 90, Key = Enum.KeyCode.LeftShift })
local _slideLast = 0
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not Slide.Enabled then return end
    if input.KeyCode == Slide.Settings.Key and tick() - _slideLast > 0.8 then
        _slideLast = tick()
        local root = getRoot()
        local hum = getHum()
        if root and hum and hum.MoveDirection.Magnitude > 0 then
            pcall(function()
                root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * Slide.Settings.Power, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * Slide.Settings.Power)
            end)
        end
    end
end)

------------------------------------------------------------
-- VELTP / VECTOR TELEPORT  (move purely via velocity for smooth long travel)
------------------------------------------------------------
local VelTP = makeModule("VelTP", "Movement", { Power = 120 })
local _velConn
function VelTP.OnToggle(state)
    if state then
        _velConn = RunService.Heartbeat:Connect(function()
            local root = getRoot()
            local hum = getHum()
            if not (root and hum) then return end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and hum.MoveDirection.Magnitude > 0 then
                pcall(function()
                    root.AssemblyLinearVelocity = Vector3.new(hum.MoveDirection.X * VelTP.Settings.Power, root.AssemblyLinearVelocity.Y, hum.MoveDirection.Z * VelTP.Settings.Power)
                end)
            end
        end)
    else
        if _velConn then _velConn:Disconnect(); _velConn = nil end
    end
end)

------------------------------------------------------------
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
                    hl.