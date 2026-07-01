local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local info = "Roblox Studio (no executor)"
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
local InlinedScripts = {
["https://darahub.pages.dev/api/script/DaraHub-Evade.lua"] = [[`n-- FAILED FETCH: https://darahub.pages.dev/api/script/DaraHub-Evade.lua`n]],
["https://darahub.pages.dev/api/script/DaraHub-Evade-Legacy.lua"] = [[`nif getgenv().DaraHubExecuted then
game:GetService("Players").LocalPlayer.PlayerGui.Menu.Messages.Use:Fire("Script Is Already Loaded, rejoin of you want to re-execute", "Error")
return
end
getgenv().DaraHubExecuted = true
loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/LoadAll.lua"))()
WindUI = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/WindUI-Moded/main.lua"))()

Window = WindUI:CreateWindow({
NewElements = true,
Title = "Dara Hub | Evade Legacy",
Icon = "rbxassetid://137330250139083",
Author = [[Made by: Pnsdg And Yomka.
Rewiring from Overhaul.lua] ],
Folder = "DaraHub/Games/Evade-Legacy",
Size = UDim2.fromOffset(580, 490),
Theme = "Dark",
HidePanelBackground = false,
Acrylic = false,
HideSearchBar = false,
SideBarWidth = 200,
OpenButton = {
Enabled = false,
Scale = 0
},
})
WindUI.TransparencyValue = 0.7
Window:ToggleTransparency(true)
Window:DisableTopbarButtons({ "Fullscreen" })
Window:SetIconSize(48)
Window:Tag({
Title = "v1.0.3",
Color = Color3.fromHex("#30ff6a")
})
executor = identifyexecutor()
if type(executor) == "table" then
for key, value in pairs(executor) do
print(key .. ": " .. tostring(value))
end
elseif type(executor) == "string" then
Window:Tag({
Title = "" .. executor
})
else
print("The injector does not support identifyexecutor()")
end
Tabs = {
Main = Window:Tab({ Title = "Main", Icon = "layout-grid" }),
Player = Window:Tab({ Title = "Player", Icon = "user" }),
Auto = Window:Tab({ Title = "Auto", Icon = "repeat-2" }),
Combat = Window:Tab({ Title = "Combat", Icon = "sword" }),
Visuals = Window:Tab({ Title = "Visuals", Icon = "camera" }),
ESP = Window:Tab({ Title = "ESP", Icon = "eye" }),
Utility = Window:Tab({ Title = "Utility", Icon = "wrench" }),
Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
info = Window:Tab({ Title = "info", Icon = "info" }),
Others = Window:Tab({ Title = "Others", Icon = "https://em-content.zobj.net/source/apple/419/pile-of-poo_1f4a9.png" })
}
local socialsModule = loadstring(game:HttpGet("https://darahub.pages.dev/Module/info.lua"))()

socialsModule(Tabs)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Character
local Humanoid
local HumanoidRootPart
local function setupCharacter(CharacterInstance)
Character = CharacterInstance
Humanoid = Character:FindFirstChildOfClass("Humanoid")
HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end
if LocalPlayer.Character then
setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

local PlayerScripts = LocalPlayer.PlayerScripts
local CamStats = PlayerScripts.CamStats
Window:OnOpen(function()
CamStats:SetAttribute("MouseEnabled", true)
ButtonLib:OpenButton(false)
end)
Window:OnClose(function()
CamStats:SetAttribute("MouseEnabled", false)
ButtonLib:OpenButton(true)
end)
Window:OnDestroy(function()
CamStats:SetAttribute("MouseEnabled", false)
ButtonLib:DestroyScreengui()
end)

if UserInputService.TouchEnabled then local isButtonLocked, currentMouseHold, activeKeybinds, createdButtons = {}, {}, {}, {} function UpdateAllButtons() for key, _ in pairs(currentMouseHold) do if currentMouseHold[key] then local Event = Players.LocalPlayer.PlayerScripts.Events.KeybindUsed Event:Fire(key, false) end currentMouseHold[key] = nil end for key, buttonData in pairs(createdButtons) do if buttonData and buttonData.updateVisualState then pcall(buttonData.updateVisualState) end end end local player, starterGui, playerGui = Players.LocalPlayer, StarterGui, PlayerGui local topbarStandard, targetParent = playerGui:FindFirstChild("TopbarStandard"), nil if topbarStandard then local main = topbarStandard:FindFirstChild("Main") if main then local holders = main:FindFirstChild("Holders") if holders then targetParent = holders:FindFirstChild("Left") if targetParent then for _, child in ipairs(targetParent:GetChildren()) do if child.Name == "TopbarStandard" then child:Destroy() end end end end end end if not targetParent then if playerGui:FindFirstChild("TopbarStandard") then playerGui:FindFirstChild("TopbarStandard"):Destroy() end StarterGui:SetCore("TopbarEnabled", false) local screenGui = Instance.new("ScreenGui") screenGui.Name, screenGui.IgnoreGuiInset, screenGui.ScreenInsets, screenGui.DisplayOrder, screenGui.ResetOnSpawn, screenGui.Parent = "TopbarStandard", false, Enum.ScreenInsets.TopbarSafeInsets, 100, false, playerGui local holders = Instance.new("Frame") holders.Name, holders.BackgroundTransparency, holders.BorderSizePixel, holders.Position, holders.Size, holders.Parent = "Holders", 1, 0, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, -2), screenGui local frame = Instance.new("Frame") frame.Name, frame.BackgroundTransparency, frame.BorderSizePixel, frame.Position, frame.Size, frame.Parent = "Main", 1, 0, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), holders local scrollingFrame = Instance.new("ScrollingFrame") scrollingFrame.Name, scrollingFrame.Parent, scrollingFrame.BackgroundTransparency, scrollingFrame.BorderSizePixel, scrollingFrame.Position, scrollingFrame.Size, scrollingFrame.CanvasSize, scrollingFrame.AutomaticCanvasSize, scrollingFrame.ScrollBarThickness, scrollingFrame.ScrollingDirection, scrollingFrame.ScrollingEnabled = "Right", frame, 1, 0, UDim2.new(0, 12, 0, 0), UDim2.new(1, -24, 1, 0), UDim2.new(0, 0, 0, 0), Enum.AutomaticSize.X, 0, Enum.ScrollingDirection.X, false local uiListLayout = Instance.new("UIListLayout") uiListLayout.Parent, uiListLayout.Padding, uiListLayout.SortOrder, uiListLayout.FillDirection, uiListLayout.HorizontalAlignment, uiListLayout.VerticalAlignment = scrollingFrame, UDim.new(0, 12), Enum.SortOrder.LayoutOrder, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Bottom targetParent = scrollingFrame else StarterGui:SetCore("TopbarEnabled", true) end local keybindButtonsConfig = { { name = "SecondaryButton", layoutOrder = 999, icon = "rbxassetid://126943351764139", label = "Zoom", key = "Secondary", enablesLockValue = true }, { name = "ReloadButton", layoutOrder = 997, icon = "rbxassetid://78648212535999", label = "Front View/Reload", key = "Reload", enablesLockValue = true }, { name = "LeaderboardButton", layoutOrder = 998, icon = "rbxassetid://5107166345", label = "Leaderboard", key = "Leaderboard", enablesLockValue = true } } function createKeybindButton(config, parent) local Button = Instance.new("Frame") Button.Name, Button.Parent, Button.BackgroundTransparency, Button.ClipsDescendants, Button.LayoutOrder, Button.Size, Button.ZIndex = config.name, parent, 1, true, config.layoutOrder, UDim2.new(0, 44, 0, 44), 20 local IconButton = Instance.new("Frame") IconButton.Name, IconButton.Parent, IconButton.BackgroundColor3, IconButton.BackgroundTransparency, IconButton.BorderSizePixel, IconButton.ClipsDescendants, IconButton.Size, IconButton.ZIndex = "IconButton", Button, Color3.fromRGB(0, 0, 0), 0.3, 0, true, UDim2.new(1, 0, 1, 0), 2 local UICorner = Instance.new("UICorner") UICorner.CornerRadius, UICorner.Parent = UDim.new(1, 0), IconButton local IconImage = Instance.new("ImageLabel") IconImage.Parent, IconImage.AnchorPoint, IconImage.BackgroundTransparency, IconImage.Position, IconImage.Size, IconImage.ZIndex, IconImage.Image = IconButton, Vector2.new(0.5, 0.5), 1, UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.5, 0, 0.5, 0), 15, config.icon local IconImageRatio = Instance.new("UIAspectRatioConstraint") IconImageRatio.Parent, IconImageRatio.DominantAxis = IconImage, Enum.DominantAxis.Height local ClickRegion = Instance.new("TextButton") ClickRegion.Parent, ClickRegion.BackgroundTransparency, ClickRegion.Size, ClickRegion.ZIndex, ClickRegion.Text = IconButton, 1, UDim2.new(1, 0, 1, 0), 20, "" local IconOverlay = Instance.new("Frame") IconOverlay.Parent, IconOverlay.BackgroundColor3, IconOverlay.BackgroundTransparency, IconOverlay.Size, IconOverlay.Visible, IconOverlay.ZIndex = IconButton, Color3.fromRGB(255, 255, 255), 0.925, UDim2.new(1, 0, 1, 0), false, 6 local UICorner_Overlay = Instance.new("UICorner") UICorner_Overlay.CornerRadius, UICorner_Overlay.Parent = UDim.new(1, 0), IconOverlay local function getIsActive() return currentMouseHold[config.key] or false end local function updateVisualState() IconOverlay.Visible = getIsActive() end ClickRegion.MouseButton1Down:Connect(function() currentMouseHold[config.key] = true local Event = Players.LocalPlayer.PlayerScripts.Events.KeybindUsed Event:Fire(config.key, true) updateVisualState() end) ClickRegion.MouseButton1Up:Connect(function() if currentMouseHold[config.key] then currentMouseHold[config.key] = false local Event = Players.LocalPlayer.PlayerScripts.Events.KeybindUsed Event:Fire(config.key, false) updateVisualState() end end) createdButtons[config.key] = { Button = Button, updateVisualState = updateVisualState } end for _, config in ipairs(keybindButtonsConfig) do createKeybindButton(config, targetParent) end if LocalPlayer:GetAttribute("CommandsAccess") == true then local vipButtonConfig = { name = "VIPButton", layoutOrder = 996, icon = "rbxassetid://1295416163", label = "VIP", key = "VIP" } local function createVIPButton(config, parent) local Button = Instance.new("Frame") Button.Name, Button.Parent, Button.BackgroundTransparency, Button.ClipsDescendants, Button.LayoutOrder, Button.Size, Button.ZIndex = config.name, parent, 1, true, config.layoutOrder, UDim2.new(0, 44, 0, 44), 20 local IconButton = Instance.new("Frame") IconButton.Name, IconButton.Parent, IconButton.BackgroundColor3, IconButton.BackgroundTransparency, IconButton.BorderSizePixel, IconButton.ClipsDescendants, IconButton.Size, IconButton.ZIndex = "IconButton", Button, Color3.fromRGB(0, 0, 0), 0.3, 0, true, UDim2.new(1, 0, 1, 0), 2 local UICorner = Instance.new("UICorner") UICorner.CornerRadius, UICorner.Parent = UDim.new(1, 0), IconButton local TextLabel = Instance.new("TextLabel") TextLabel.Parent, TextLabel.BackgroundTransparency, TextLabel.Position, TextLabel.Size, TextLabel.Font, TextLabel.Text, TextLabel.TextColor3, TextLabel.TextScaled, TextLabel.TextStrokeTransparency, TextLabel.TextSize, TextLabel.TextWrapped, TextLabel.ZIndex = IconButton, 1, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 1, 0), Enum.Font.SourceSansBold, "VIP", Color3.fromRGB(255, 255, 255), false, 0.5, 18, true, 20 local ClickRegion = Instance.new("TextButton") ClickRegion.Parent, ClickRegion.BackgroundTransparency, ClickRegion.Size, ClickRegion.ZIndex, ClickRegion.Text = IconButton, 1, UDim2.new(1, 0, 1, 0), 20, "" local vipMenuOpen = false local function toggleVIPMenu() vipMenuOpen = not vipMenuOpen local vipMenu = PlayerGui:FindFirstChild("VIPMenu") if vipMenu then vipMenu.Enabled = vipMenuOpen end end ClickRegion.MouseButton1Click:Connect(toggleVIPMenu) end createVIPButton(vipButtonConfig, targetParent) end end

AutoWhistle = false
CustomGravity = false
GravityValue = Workspace.Gravity
InfiniteJump = false
TPWALK = false
AutoCarry = false
NoFog = false
AutoVote = false
AutoSelfRevive = false
AutoRevive = false
FastRevive = false
PlayerESP = {
boxes = false,
tracers = false,
names = false,
distance = false,
rainbowBoxes = false,
rainbowTracers = false,
boxType = "2D",
}
EnemyESP = {
boxes = false,
tracers = false,
names = false,
distance = false,
rainbowBoxes = false,
rainbowTracers = false,
boxType = "2D",
}
DownedBoxESP = false
DownedTracer = false
DownedNameESP = false
DownedDistanceESP = false
DownedBoxType = "2D"
TpwalkValue = 1
JumpPower = 5
JumpMethod = "Hold"
SelectedMap = 1
ZoomValue = 1
TimerDisplay = false

local character, humanoid, rootPart
local bodyVelocity, bodyGyro
local ToggleTpwalk = false
local TpwalkConnection
if not AntiEnemyDistance then
AntiEnemyDistance = 50
end

local farmsSuppressedByAntiEnemy = false
local antiEnemyConnection = nil
local jumpCount = 0
local MAX_JUMPS = math.huge

local AntiAFKConnection

local AutoCarryConnection

local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalAmbient = Lighting.Ambient
local originalGlobalShadows = Lighting.GlobalShadows
local originalAtmospheres = {}

for _, v in pairs(Lighting:GetDescendants()) do
if v:IsA("Atmosphere") then
table.insert(originalAtmospheres, v)
end
end
function startNoFog()
originalFogEnd = Lighting.FogEnd
Lighting.FogEnd = 1000000
for _, v in pairs(Lighting:GetDescendants()) do
if v:IsA("Atmosphere") then
v:Destroy()
end
end
end

function isPlayerDowned(pl)
if not pl or not pl.Character then return false end
local char = pl.Character
local humanoid = char:FindFirstChild("Humanoid")
if humanoid and humanoid.Health <= 0 then
return true
end
if char.GetAttribute and char:GetAttribute("Downed") == true then
return true
end
return false
end
function isPlayerDowned(pl)
local char = pl.Character
if char and char:FindFirstChild("Humanoid") then
local humanoid = char.Humanoid
return humanoid.Health <= 0 or char:GetAttribute("Downed") == true
end
return false
end

function Tpwalking()
if ToggleTpwalk and Character and Humanoid and HumanoidRootPart then
local moveDirection = Humanoid.MoveDirection
local moveDistance = TpwalkValue
local origin = HumanoidRootPart.Position
local direction = moveDirection * moveDistance
local targetPosition = origin + direction
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {Character}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
local raycastResult = Workspace:Raycast(origin, direction, raycastParams)
if raycastResult then
local hitPosition = raycastResult.Position
local distanceToHit = (hitPosition - origin).Magnitude
if distanceToHit < math.abs(moveDistance) then
targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
end
end
HumanoidRootPart.CFrame = CFrame.new(targetPosition) * HumanoidRootPart.CFrame.Rotation
HumanoidRootPart.CanCollide = true
end
end

function startTpwalk()
ToggleTpwalk = true
if TpwalkConnection then
TpwalkConnection:Disconnect()
end
TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
end

function stopTpwalk()
ToggleTpwalk = false
if TpwalkConnection then
TpwalkConnection:Disconnect()
TpwalkConnection = nil
end
if HumanoidRootPart then
HumanoidRootPart.CanCollide = false
end
end

SpringSpeedMultiplier = 1
RealSpeed = 1500
JumpHeight = 3
AirAcceleration = 1
jumpcap = 1
AirStrafeAcceleration = 9999

autoJumpEnabled = false
bhopHoldActive = false
bhopHoldFeature = false
jumpCooldown = 0.7
autoJumpType = "Bounce"

accelerationMethod = "Acceleration"
groundFriction = -0.5
AutoAccelerationEnabled = false
MaxAcceleration = 3
MinAcceleration = -1
MaxSpeed = 70

InfiniteSlide = false
SlideFriction = -0.1

bhopConnection = nil
bhopLoaded = false
LastJump = 0
GROUND_CHECK_DISTANCE = 3.5
MAX_SLOPE_ANGLE = 45

movementModule = nil
originalApplyFriction = nil

particleTemplate = nil

function createJumpParticle()
local emitter = Instance.new("ParticleEmitter")
emitter.Name = "DoubleJumpEffect"
emitter.EmissionDirection = Enum.NormalId.Bottom
emitter.Enabled = false
emitter.Lifetime = NumberRange.new(0.1, 0.3)
emitter.LightEmission = 1
emitter.LightInfluence = 1
emitter.Rate = 500
emitter.Rotation = NumberRange.new(-180, 180)
emitter.Size = NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.0617, 1),
NumberSequenceKeypoint.new(0.864, 0),
NumberSequenceKeypoint.new(1, 0)
})
emitter.Speed = NumberRange.new(0, 8)
emitter.SpreadAngle = Vector2.new(135, 135)
emitter.Texture = "rbxassetid://4770542473"
emitter.Transparency = NumberSequence.new({
NumberSequenceKeypoint.new(0, 1),
NumberSequenceKeypoint.new(0.199, 0.512),
NumberSequenceKeypoint.new(1, 1)
})
return emitter
end

function IsOnGround()
if not Character or not HumanoidRootPart or not Humanoid then return false end
local success, result = pcall(function()
local state = Humanoid:GetState()
if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Swimming then
return false
end
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {Character}
local raycastResult = Workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -GROUND_CHECK_DISTANCE, 0), raycastParams)
if not raycastResult then return false end
local angle = math.deg(math.acos(raycastResult.Normal:Dot(Vector3.new(0, 1, 0))))
return angle <= MAX_SLOPE_ANGLE
end)
return success and result
end

function updateBhop()
if not bhopLoaded then return end
pcall(function()
if not Character or not Humanoid then return end
local isBhopActive = autoJumpEnabled or bhopHoldActive
if isBhopActive then
local now = tick()
if IsOnGround() and (now - LastJump) > jumpCooldown then
if autoJumpType == "Realistic" then
Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
task.wait(0.1)
else
Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
LastJump = now
end
end
end)
end

function loadBhop()
if bhopLoaded then return end
bhopLoaded = true
if bhopConnection then bhopConnection:Disconnect() end
bhopConnection = RunService.Heartbeat:Connect(updateBhop)
end

function unloadBhop()
if not bhopLoaded then return end
bhopLoaded = false
if bhopConnection then
bhopConnection:Disconnect()
bhopConnection = nil
end
bhopHoldActive = false
end

function checkBhopState()
if autoJumpEnabled or bhopHoldActive then
loadBhop()
else
unloadBhop()
end
end

function setupBhopJumpBtn()
pcall(function()
local playerGui = LocalPlayer:WaitForChild("PlayerGui", 5)
local touchGui = playerGui:WaitForChild("TouchGui", 5)
local jumpButton = touchGui:FindFirstChild("JumpButton", true)
if not jumpButton then return end
jumpButton.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
if bhopHoldFeature then
bhopHoldActive = true
checkBhopState()
end
end
end)
jumpButton.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
bhopHoldActive = false
checkBhopState()
end
end)
end)
end

function getCurrentSpeed()
if HumanoidRootPart then
return (HumanoidRootPart.Velocity * Vector3.new(1, 0, 1)).Magnitude
end
return 0
end

function reapplyModifications()
if not movementModule then return end

if not originalApplyFriction then
originalApplyFriction = movementModule.ApplyFriction
end

local isBhopActive = autoJumpEnabled or bhopHoldActive

if isBhopActive then
movementModule.ApplyFriction = function(self, frictionAmount)
local isGrounded = self.a == true

if isGrounded then
if accelerationMethod == "No Acceleration" then
frictionAmount = 0
elseif accelerationMethod == "Ground Acceleration" or accelerationMethod == "Acceleration" then
local finalFriction = groundFriction

if AutoAccelerationEnabled then
local currentSpeed = getCurrentSpeed()
if currentSpeed > MaxSpeed then
finalFriction = MaxAcceleration
elseif currentSpeed < MaxSpeed then
finalFriction = MinAcceleration
end
end

frictionAmount = finalFriction
end
end

return originalApplyFriction(self, frictionAmount)
end
else
movementModule.ApplyFriction = originalApplyFriction
end
end

function setupModuleWatcher(character)
local movement = character:WaitForChild("Movement")

local function applyToModule()
local success, module = pcall(require, movement)
if success and module then
movementModule = module
reapplyModifications()
end
end

applyToModule()

spawn(function()
while character and character.Parent do
wait(1)
local success, module = pcall(require, movement)
if success and module and module ~= movementModule then
movementModule = module
reapplyModifications()
end
end
end)
end

function applyAirStrafe(character)
local PlayerName = LocalPlayer.Name
local MovementPath = Workspace.Game.Players:WaitForChild(PlayerName):WaitForChild("Movement")
local MovementModule = require(MovementPath)
local oldAirMove = MovementModule.AirMove
MovementModule.AirMove = function(self)
oldAirMove(self)
if self.f.a == 0 and self.f.b ~= 0 then
local v1 = LocalPlayer.PlayerScripts.CameraCFrame.Value:VectorToWorldSpace(Vector3.new(self.f.b, 0, self.f.a))
local v2 = Vector3.new(v1.X, 0, v1.Z)
local v4 = if v2 == Vector3.new(0, 0, 0) then v2 else v2.Unit
local v3 = AirStrafeAcceleration
local v5 = AirStrafeAcceleration
self:Accelerate(v4, v3, v5)
end
end
end

function applyInfiniteSlide(character)
if not character then return end

local hrp = character:WaitForChild("HumanoidRootPart", 5)
if not hrp then return end

local movementModule = character:FindFirstChild("Movement", true)
if movementModule and movementModule:IsA("ModuleScript") then
local movement = require(movementModule)
local originalSlideMove = movement.SlideMove
movement.SlideMove = function(self, deltaTime)
if InfiniteSlide then
self:ApplyFriction(SlideFriction)
end
if originalSlideMove then
return originalSlideMove(self, deltaTime)
end
end
end

local path = Workspace.Game.Players:FindFirstChild(LocalPlayer.Name)
if path then
local mov = path:FindFirstChild("Movement", true)
if mov and mov:IsA("ModuleScript") then
local slidemove = require(mov)
local original = slidemove.SlideMove
slidemove.SlideMove = function(self, deltaTime)
if InfiniteSlide then
self:ApplyFriction(SlideFriction)
end
if original then
return original(self, deltaTime)
end
end
end
end
end

function handleRespawn(character)
Character = character
Humanoid = character:WaitForChild("Humanoid")
HumanoidRootPart = character:WaitForChild("HumanoidRootPart")

if not particleTemplate or not particleTemplate.Parent then
particleTemplate = createJumpParticle()
end

local movement = character:FindFirstChild("Movement")
if movement and movement:IsA("ModuleScript") then
local movementModule = require(movement)

local originalUpdate = movementModule.Update
movementModule.Update = function(self, dt)
local originalSpeed = self.j
self.j = RealSpeed * SpringSpeedMultiplier

local originalAirMove = self.AirMove
self.AirMove = function(airSelf, ...)
local originalAccelerate = airSelf.Accelerate
airSelf.Accelerate = function(accSelf, direction, targetSpeed, acceleration)
targetSpeed = targetSpeed * AirAcceleration
return originalAccelerate(accSelf, direction, targetSpeed, acceleration)
end

originalAirMove(airSelf, ...)
airSelf.Accelerate = originalAccelerate
end

originalUpdate(self, dt)
self.AirMove = originalAirMove
self.j = originalSpeed
end
end

applyInfiniteSlide(character)
applyAirStrafe(character)

setupModuleWatcher(character)

local hum = character:WaitForChild("Humanoid")
hum.JumpHeight = JumpHeight
hum:SetAttribute("RealJumpHeight", JumpHeight)

local jumpCount = 0

hum.StateChanged:Connect(function(oldState, newState)
if newState == Enum.HumanoidStateType.Landed then
jumpCount = 0
end

if newState == Enum.HumanoidStateType.Jumping then
jumpCount = jumpCount + 1

if jumpCount >= 2 and jumpcap > 1 then
local attachment = Instance.new("Attachment")
attachment.Position = Vector3.new(0, -2, 0)
attachment.Parent = HumanoidRootPart

local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://6870001835"
sound.Pitch = 2
sound.Volume = 0.5
sound.Parent = attachment
sound:Play()

local jumpParticles = particleTemplate:Clone()
jumpParticles.Parent = attachment
jumpParticles:Emit(40)

task.delay(0.6, function()
attachment:Destroy()
end)
end
end
end)

spawn(function()
while hum and hum.Parent do
hum.JumpHeight = JumpHeight
wait(0.5)
end
end)

local jumps = 0
local jumpTick = tick()

hum.StateChanged:Connect(function(old, new)
if new == Enum.HumanoidStateType.Landed then
jumps = 0
end
end)

local jumpConnection
jumpConnection = UserInputService.JumpRequest:Connect(function()
if jumps < jumpcap and tick() - jumpTick > 0.05 then
jumpTick = tick()
jumps = jumps + 1
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end)

character.AncestryChanged:Connect(function()
if not character.Parent then
jumpConnection:Disconnect()
end
end)

setupBhopJumpBtn()
checkBhopState()
end

LocalPlayer.CharacterAdded:Connect(function(character)
task.wait(0.5)
handleRespawn(character)
end)

if LocalPlayer.Character then
handleRespawn(LocalPlayer.Character)
end

RunService.Heartbeat:Connect(function()
if not Character or not Character:IsDescendantOf(Workspace) then
Character = LocalPlayer.Character
if Character then
Humanoid = Character:FindFirstChildOfClass("Humanoid")
HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end
end
end)

function startAntiAFK()
AntiAFKConnection = LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
end)
end

function stopAntiAFK()
if AntiAFKConnection then
AntiAFKConnection:Disconnect()
AntiAFKConnection = nil
end
end
function stopNoFog()
Lighting.FogEnd = originalFogEnd
for _, atmosphere in pairs(originalAtmospheres) do
if not atmosphere.Parent then
local newAtmosphere = Instance.new("Atmosphere")
for _, prop in pairs({"Density", "Offset", "Color", "Decay", "Glare", "Haze"}) do
if atmosphere[prop] then
newAtmosphere[prop] = atmosphere[prop]
end
end
newAtmosphere.Parent = Lighting
end
end
end
local UniverseServerTools = loadstring(game:HttpGet("https://darahub.pages.dev/Module/UniverseServerTools.lua"))()

UniverseServerTools(Tabs)
Tabs.Main:Section({ Title = "Misc", TextSize = 20 })
Tabs.Main:Divider()
Tabs.Main:Space()
Tabs.Main:Button({
Title = "Remove Kill Part",
Callback= function()
function findAllKillParts(parent)
local killParts = {}

for _, child in ipairs(parent:GetChildren()) do
if child.Name == "KillPart" then
table.insert(killParts, child)
end

if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Folder") then
local found = findAllKillParts(child)
for _, part in ipairs(found) do
table.insert(killParts, part)
end
end
end

return killParts
end
local allKillParts = findAllKillParts(Workspace)

for _, killPart in ipairs(allKillParts) do
killPart:Destroy()
wait(9)
killParts = nil
end
end
})
Tabs.Main:Space()
AntiAFKToggle = Tabs.Main:Toggle({
Title = "Anti AFK",
Flag = "AntiAFKToggle",
Value = false,
Callback = function(state)
if state then
startAntiAFK()
else
stopAntiAFK()
end
end
})
AntiEnemy=false;AntiEnemyDistance=50;function isEnemyModel(model)return model:FindFirstChild("Humanoid")and not Players:GetPlayerFromCharacter(model)end;function handleAntiEnemy()if not AntiEnemy then return end;local character=LocalPlayer.Character;local humanoidRootPart=character and character:FindFirstChild("HumanoidRootPart")if not humanoidRootPart then return end;local Enemys={};local NPCStorageFolder=Workspace:FindFirstChild("NPCStorage")if NPCStorageFolder then for _,model in ipairs(NPCStorageFolder:GetChildren())do if model:IsA("Model")and isEnemyModel(model)then local hrp=model:FindFirstChild("HumanoidRootPart")if hrp then table.insert(Enemys,model)end end end end;local playersFolder=Workspace:FindFirstChild("Game")and Workspace.Game:FindFirstChild("Players")if playersFolder then for _,model in ipairs(playersFolder:GetChildren())do if model:IsA("Model")and isEnemyModel(model)then local hrp=model:FindFirstChild("HumanoidRootPart")if hrp then table.insert(Enemys,model)end end end end;for _,Enemy in ipairs(Enemys)do local EnemyHrp=Enemy:FindFirstChild("HumanoidRootPart")if EnemyHrp then local distance=(humanoidRootPart.Position-EnemyHrp.Position).Magnitude;if distance<=AntiEnemyDistance then local direction=(humanoidRootPart.Position-EnemyHrp.Position).Unit;local targetPos=humanoidRootPart.Position+direction*30;local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})local success,errorMessage=pcall(function()path:ComputeAsync(humanoidRootPart.Position,targetPos)end)if success and path.Status==Enum.PathStatus.Success then local waypoints=path:GetWaypoints()if#waypoints>1 then local lastValidPos=waypoints[#waypoints].Position;humanoidRootPart.CFrame=CFrame.new(lastValidPos+Vector3.new(0,3,0))end else humanoidRootPart.CFrame=CFrame.new(targetPos+Vector3.new(0,3,0))end;break end end end end;task.spawn(function()while true do if AntiEnemy then pcall(handleAntiEnemy)end;task.wait(0.1)end end)Tabs.Main:Space()AntiEnemyToggle=Tabs.Main:Toggle({Title="Anti-Enemy",Flag="AntiEnemyToggle",Desc="Automatically teleport away from nearby enemies",Value=false,Callback=function(state)AntiEnemy=state end})AntiEnemyDistanceInput=Tabs.Main:Input({Title="Anti-Enemy Distance",Flag="AntiEnemyDistanceInput",Desc="Distance threshold for enemy detection",Placeholder="50",NumbersOnly=true,Callback=function(value)local num=tonumber(value)if num and num>0 then AntiEnemyDistance=num end end})
AntiNPCSpawn=false;AntiNPCSpawnType="Spawn";AntiNPCSpawnDistance=40;AntiNPCTeleportDistance=20;local NPCSpawnConnection=nil;local lastAvoidanceTime=0;local avoidanceCooldown=2;function findSafeTeleportPositionReverse(startPos,targetPos)local raycastParams=RaycastParams.new()raycastParams.FilterType=Enum.RaycastFilterType.Blacklist;raycastParams.FilterDescendantsInstances={LocalPlayer.Character}local direction=(targetPos-startPos).Unit;local maxDistance=(targetPos-startPos).Magnitude;for distance=maxDistance,0,-5 do local testPos=startPos+(direction*distance)local downRay=Workspace:Raycast(testPos+Vector3.new(0,10,0),Vector3.new(0,-20,0),raycastParams)if downRay then local groundPos=downRay.Position+Vector3.new(0,3,0)local upRay=Workspace:Raycast(groundPos,Vector3.new(0,6,0),raycastParams)if not upRay then local sideRays={Vector3.new(3,0,0),Vector3.new(-3,0,0),Vector3.new(0,0,3),Vector3.new(0,0,-3)}local isSafe=true;for _,sideDir in ipairs(sideRays)do local sideRay=Workspace:Raycast(groundPos,sideDir,raycastParams)if sideRay and sideRay.Instance.CanCollide then isSafe=false;break end end;if isSafe then return groundPos end end end end;return nil end;function teleportToSpawn()local spawnsFolder=Workspace:FindFirstChild("Game")and Workspace.Game:FindFirstChild("Map")and Workspace.Game.Map:FindFirstChild("Parts")and Workspace.Game.Map.Parts:FindFirstChild("Spawns")if spawnsFolder then local spawnLocations=spawnsFolder:GetChildren()if#spawnLocations>0 then local character=LocalPlayer.Character;local humanoidRootPart=character and character:FindFirstChild("HumanoidRootPart")if humanoidRootPart then for i=1,math.min(3,#spawnLocations)do local randomSpawn=spawnLocations[math.random(1,#spawnLocations)]local targetPosition=randomSpawn.CFrame.Position+Vector3.new(0,3,0)local safePosition=findSafeTeleportPositionReverse(humanoidRootPart.Position,targetPosition)if safePosition then humanoidRootPart.CFrame=CFrame.new(safePosition)return true end end end end end;return false end;function teleportToPlayer()local players=Players:GetPlayers()local validPlayers={}for _,plr in ipairs(players)do if plr~=LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")then table.insert(validPlayers,plr)end end;if#validPlayers>0 then local character=LocalPlayer.Character;local humanoidRootPart=character and character:FindFirstChild("HumanoidRootPart")if humanoidRootPart then for i=1,math.min(3,#validPlayers)do local randomPlayer=validPlayers[math.random(1,#validPlayers)]local targetPosition=randomPlayer.Character.HumanoidRootPart.Position+Vector3.new(0,3,0)local safePosition=findSafeTeleportPositionReverse(humanoidRootPart.Position,targetPosition)if safePosition then humanoidRootPart.CFrame=CFrame.new(safePosition)return true end end end end;return false end;function teleportToDistance()local spawnMarker=Workspace:FindFirstChild("Game")and Workspace.Game:FindFirstChild("Effects")and Workspace.Game.Effects:FindFirstChild("BotSpawnMarker")if not spawnMarker then return teleportToSpawn()end;local character=LocalPlayer.Character;local humanoidRootPart=character and character:FindFirstChild("HumanoidRootPart")if not humanoidRootPart then return false end;local direction=(humanoidRootPart.Position-spawnMarker.Position).Unit;local targetPos=humanoidRootPart.Position+direction*AntiNPCTeleportDistance;local safePosition=findSafeTeleportPositionReverse(humanoidRootPart.Position,targetPos)if safePosition then humanoidRootPart.CFrame=CFrame.new(safePosition)return true else return teleportToSpawn()end end;function isPlayerNearSpawn()local spawnMarker=Workspace:FindFirstChild("Game")and Workspace.Game:FindFirstChild("Effects")and Workspace.Game.Effects:FindFirstChild("BotSpawnMarker")if not spawnMarker or not LocalPlayer.Character then return false end;local humanoidRootPart=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")if not humanoidRootPart then return false end;local distance=(humanoidRootPart.Position-spawnMarker.Position).Magnitude;return distance<=AntiNPCSpawnDistance end;function performAvoidance()if not LocalPlayer.Character then return end;local success=false;if AntiNPCSpawnType=="Spawn"then success=teleportToSpawn()elseif AntiNPCSpawnType=="Player"then success=teleportToPlayer()else success=teleportToDistance()end end;function startAntiNPC()if NPCSpawnConnection then NPCSpawnConnection:Disconnect()end;NPCSpawnConnection=RunService.Heartbeat:Connect(function()if not AntiNPCSpawn or not LocalPlayer.Character then return end;if tick()-lastAvoidanceTime<avoidanceCooldown then return end;if isPlayerNearSpawn()then performAvoidance()lastAvoidanceTime=tick()end end)end;AntiNPCSpawnToggle=Tabs.Main:Toggle({Title="Anti NPC Spawn",Flag="AntiNPCSpawnToggle",Desc="Automatically avoid NPC spawn areas",Value=false,Callback=function(state)AntiNPCSpawn=state;if state then startAntiNPC()else if NPCSpawnConnection then NPCSpawnConnection:Disconnect()NPCSpawnConnection=nil end end end})AntiNPCSpawnTypeDropdown=Tabs.Main:Dropdown({Title="Avoidance Mode",Flag="AntiNPCSpawnTypeDropdown",Desc="Choose how to avoid NPC spawn",Values={"Spawn","Player","Distance"},Value="Spawn",Callback=function(value)AntiNPCSpawnType=value end})AntiNPCSpawnDistanceInput=Tabs.Main:Input({Title="Avoidance Distance",Flag="AntiNPCSpawnDistanceInput",Desc="Distance to trigger avoidance (studs)",Placeholder="40",NumbersOnly=true,Callback=function(value)local distance=tonumber(value)if distance and distance>0 then AntiNPCSpawnDistance=distance end end})AntiNPCTeleportDistanceInput=Tabs.Main:Input({Title="Teleport Distance",Flag="AntiNPCTeleportDistanceInput",Desc="How far to teleport in Distance mode (studs)",Placeholder="20",NumbersOnly=true,Callback=function(value)local distance=tonumber(value)if distance and distance>0 then AntiNPCTeleportDistance=distance end end})LocalPlayer.CharacterAdded:Connect(function()if AntiNPCSpawn then task.wait(1)if not NPCSpawnConnection then startAntiNPC()end end end)
Tabs.Main:Section({Title="Emote Crouch",TextSize=20});Tabs.Main:Divider();local p=LocalPlayer;local emoteData={};function scanEmotes()for i=1,8 do local attr=p:GetAttribute("Emote"..i)emoteData[i]={Slot=i,Name=attr or ""}end end;scanEmotes();local dropdownOptions={};for i=1,8 do if emoteData[i].Name~=""then table.insert(dropdownOptions,"Slot"..i.." "..emoteData[i].Name)end end;local selectedValues={};local dropdown=Tabs.Main:Dropdown({Title="Select Emote Slot(s)",Options=dropdownOptions,Multi=true,AllowNone=true,Callback=function(values)selectedValues=values end});function updateDropdown()scanEmotes();dropdownOptions={};for i=1,8 do if emoteData[i].Name~=""then table.insert(dropdownOptions,"Slot"..i.." "..emoteData[i].Name)end end;dropdown:Refresh(dropdownOptions,true)end;function monitorAttributes()while true do task.wait(0.5);for i=1,8 do local attr=p:GetAttribute("Emote"..i)if attr~=emoteData[i].Name then updateDropdown()break end end end end;task.spawn(monitorAttributes);function triggerRandomEmote()

pcall(function()
LocalPlayer = Players.LocalPlayer
character = LocalPlayer.Character
if LocalPlayer.Character then
character:SetAttribute("Crouching", true)

end
end)
;task.wait(0.1);local validSlots={};if#selectedValues>0 then for _,slotText in pairs(selectedValues)do local slotNum=tonumber(string.match(slotText,"Slot(%d+)"))if slotNum and emoteData[slotNum]and emoteData[slotNum].Name~=""then table.insert(validSlots,tostring(slotNum))end end else for i=1,8 do if emoteData[i]and emoteData[i].Name~=""then table.insert(validSlots,tostring(i))end end end;if#validSlots>0 then local randomSlot=validSlots[math.random(1,#validSlots)];pcall(function()ReplicatedStorage.Events.Emote:FireServer(randomSlot)end)end end;ButtonLib.Create:Button({
Text = "Emote Crouch",
Flag = "EmoteCrouch",
Visible = false,
Callback = function()
triggerRandomEmote()
end
}).Position = UDim2.new(0.5, -125, 0.2, 0)

EmoteCrouchToggle = Tabs.Main:Toggle({
Title = "Emote Crouch",
Flag = "EmoteCrouchToggle",
Desc = "Select emote slot(s) or leave empty for random",
Value = false,
Callback = function(state)
getgenv().EmoteCrouchEnabled = state
if ButtonLib and ButtonLib.EmoteCrouch then
ButtonLib.EmoteCrouch:SetVisible(state)
end
end
})
local function uncrouch()
local character = LocalPlayer.Character
if character then
character:SetAttribute("Crouching", false)
   end
end
ShowUncrouchButtonToggle = Tabs.Main:Toggle({
Title = "Show Uncrouch Button",
Flag = "ShowUncrouchButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.UncrouchButton then
ButtonLib.UncrouchButton:SetVisible(state)
end
end
})

ButtonLib.Create:Button({
Text = "Uncrouch",
Flag = "UncrouchButton",
Visible = false,
Callback = function()
uncrouch()
end
}).Position = UDim2.new(0.5, -125, 0.45, 0)

Tabs.Main:Section({ Title = "TAS", TextSize = 20 })
Tabs.Main:Divider()
Running = false
Frames = {}
TimeStart = tick()

getChar = function()
Character = LocalPlayer.Character
if Character then
return Character
else
LocalPlayer.CharacterAdded:Wait()
return getChar()
end
end

StartRecord = function()
Frames = {}
Running = true
TimeStart = tick()
while Running == true do
RunService.Heartbeat:wait()
Character = getChar()
table.insert(Frames, {
Character.HumanoidRootPart.CFrame,
Character.Humanoid:GetState().Value,
tick() - TimeStart
})
end
end

StopRecord = function()
Running = false
end

PlayTAS = function()
Character = getChar()
TimePlay = tick()
FrameCount = #Frames
OldFrame = 1
TASLoop = RunService.Heartbeat:Connect(function()
CurrentTime = tick()
if (CurrentTime - TimePlay) >= Frames[FrameCount][3] then
TASLoop:Disconnect()
return
end
for i = OldFrame, math.min(OldFrame + 60, FrameCount) do
Frame = Frames[i]
if Frame and Frame[3] <= (CurrentTime - TimePlay) then
OldFrame = i
Character.HumanoidRootPart.CFrame = Frame[1]
Character.Humanoid:ChangeState(Frame[2])
end
end
end)
end



Tabs.Main:Button({ Title = "Start recording", Color = Color3.fromHex("#30FF6A"), Callback = StartRecord })
Tabs.Main:Button({ Title = "Stop recording",Color = Color3.fromHex("#ff4830"), Callback = StopRecord })
Tabs.Main:Button({ Title = "Play",Color = Color3.fromHex("#30FF6A"), Callback = PlayTAS })

Tabs.Player:Section({ Title = "Player", TextSize = 40 })
Tabs.Player:Divider()
Tabs.Player:Section({Title="Modify Bounce",TextSize=20})

local bounceConnection = nil
local lastSpeed = nil
local lastWalkSpeed = nil

Tabs.Player:Toggle({
Title="Modify Multiplier",
Desc="Trigger when Humanoid State climb logic",
Flag="BounceEnabled",
Value=false,
Callback = function(state)
if state then
bounceConnection = RunService.RenderStepped:Connect(function()
local character = LocalPlayer.Character
if not character then return end
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local humanoid = character:FindFirstChild("Humanoid")
if humanoidRootPart and humanoid then
local velocity = humanoidRootPart.AssemblyLinearVelocity
local speed = velocity.Magnitude
local newWalkSpeed = 0
if speed > 0.1 then
newWalkSpeed = BounceSpeed
else
newWalkSpeed = 0
end
if lastWalkSpeed == nil or newWalkSpeed ~= lastWalkSpeed then
humanoid.WalkSpeed = newWalkSpeed
lastWalkSpeed = newWalkSpeed
end
local speedChanged = lastSpeed == nil or math.abs(speed - lastSpeed) > 0.5
if speedChanged then
lastSpeed = speed
end
end
end)
else
if bounceConnection then
bounceConnection:Disconnect()
bounceConnection = nil
lastSpeed = nil
lastWalkSpeed = nil
end
end
end
})

Tabs.Player:Input({
Title="Multiplier value",
Flag="VelocityMultiplier",
Placeholder="80",
NumbersOnly=true,
Callback = function(value)
BounceSpeed = tonumber(value) or 80
end
})
Tabs.Player:Section({ Title = "Supper Bounce", TextSize = 20 })
Tabs.Player:Divider()

BounceHeight = 190

local BounceInput = Tabs.Player:Input({
Title = "Bounce Height",
Placeholder = "190",
Callback = function(value)
BounceHeight = tonumber(value) or 50
end
})

function triggerSuperBounce()
if not LocalPlayer.Character then return end
local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

if humanoid and rootPart then
humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
rootPart.Velocity = Vector3.new(rootPart.Velocity.X, BounceHeight, rootPart.Velocity.Z)
end
end

SuperBounceToggle = Tabs.Player:Toggle({
Title = "Supper Bounce",
Flag = "SuperBounceToggle",
Desc = "Click to bounce with set height",
Value = false,
Callback = function(state)
SuperBounceEnabled = state

if ButtonLib and ButtonLib.SuperBounce then
ButtonLib.SuperBounce:SetVisible(state)
end
end
})

if ButtonLib and ButtonLib.Create then
ButtonLib = ButtonLib or {}
ButtonLib.SuperBounce = ButtonLib.Create:Button({
Text = "Supper Bounce",
Flag = "SuperBounce",
Visible = false,
Callback = function()
triggerSuperBounce()
end
})
ButtonLib.SuperBounce.Position = UDim2.new(0.5, -125, 0.2, 0)
end
Tabs.Player:Space()

BounceMultiplier = 5
FallSpeedThreshold = 69
EdgeTrimpEnabled = false
LastFloorMaterial = Enum.Material.Air
LastPosition = Vector3.new()
WasFalling = false
EdgeDetected = false
edgeTrimpConnection = nil
charAddedConnection = nil

local function handleCharacterAdded(NewCharacter)
Character = NewCharacter
Humanoid = Character:WaitForChild("Humanoid")
HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
LastPosition = HumanoidRootPart.Position
WasFalling = false
EdgeDetected = false
end

Tabs.Player:Space()

EdgeTrimpToggle = Tabs.Player:Toggle({
Title = "Modify Edge Trimp",
Flag = "ModifyEdgeTrimp",
Value = false,
Callback = function(State)
EdgeTrimpEnabled = State
if State then
if LocalPlayer.Character then
handleCharacterAdded(LocalPlayer.Character)
end
charAddedConnection = LocalPlayer.CharacterAdded:Connect(handleCharacterAdded)

edgeTrimpConnection = RunService.Heartbeat:Connect(function()
if not (Character and Humanoid and HumanoidRootPart) then return end

local CurrentPosition = HumanoidRootPart.Position
local Velocity = (CurrentPosition - LastPosition) / RunService.Heartbeat:Wait()
LastPosition = CurrentPosition
local CurrentFloorMaterial = Humanoid.FloorMaterial
local IsFalling = Humanoid:GetState() == Enum.HumanoidStateType.Freefall or Humanoid:GetState() == Enum.HumanoidStateType.Jumping

if CurrentFloorMaterial ~= LastFloorMaterial and CurrentFloorMaterial == Enum.Material.Air and not IsFalling then
EdgeDetected = true
else
EdgeDetected = false
end

if EdgeDetected and Humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
local FallVelocity = Velocity.Y
if FallVelocity < -FallSpeedThreshold then
local BounceVelocity = math.abs(FallVelocity) * BounceMultiplier
HumanoidRootPart.Velocity = Vector3.new(HumanoidRootPart.Velocity.X, BounceVelocity, HumanoidRootPart.Velocity.Z)
end
end

LastFloorMaterial = CurrentFloorMaterial
WasFalling = IsFalling
end)
else
if edgeTrimpConnection then
edgeTrimpConnection:Disconnect()
edgeTrimpConnection = nil
end
if charAddedConnection then
charAddedConnection:Disconnect()
charAddedConnection = nil
end
end
end
})

BounceMultiplierInput = Tabs.Player:Input({
Title = "Bounce Height Multiplier",
Flag = "EdgeHeightMultiplier",
Placeholder = "5",
Value = tostring(BounceMultiplier),
NumbersOnly = true,
Callback = function(Value)
local Num = tonumber(Value)
if Num and Num > 0 then
BounceMultiplier = Num
end
end
})

FallSpeedThresholdInput = Tabs.Player:Input({
Title = "Falling Threshold",
Flag = "EdgeFallThreshold",
Placeholder = "69",
Value = tostring(FallSpeedThreshold),
NumbersOnly = true,
Callback = function(Value)
local Num = tonumber(Value)
if Num and Num > 0 then
FallSpeedThreshold = Num
end
end
})
Tabs.Player:Space()
IsOnMobile = false
xpcall(function()
IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

FLYING = false
flyspeed = 5
flyKeyDown = nil
flyKeyUp = nil

flyVelocityHandlerName = "FlyVelocity_" .. math.random(1000, 9999)
flyGyroHandlerName = "FlyGyro_" .. math.random(1000, 9999)
mfly1 = nil
mfly2 = nil

flyUpPressed = false
flyDownPressed = false

function getRoot(character)
return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
end

function unmobilefly(speaker)
pcall(function()
FLYING = false
flyUpPressed = false
flyDownPressed = false
root = getRoot(speaker.Character)
if root then
bv = root:FindFirstChild(flyVelocityHandlerName)
bg = root:FindFirstChild(flyGyroHandlerName)
if bv then bv:Destroy() end
if bg then bg:Destroy() end
end
if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
end
if mfly1 then mfly1:Disconnect() mfly1 = nil end
if mfly2 then mfly2:Disconnect() mfly2 = nil end
end)
end

function hookMobileButtons(speaker)
if IsOnMobile then
task.spawn(function()
flyUpPressed = false
flyDownPressed = false

for i = 1, 10 do
hud = speaker.PlayerGui:FindFirstChild("HUD")

if hud then
right = hud:FindFirstChild("Right")
if right then
mobile = right:FindFirstChild("Mobile")
if mobile then
crouchButton = mobile:FindFirstChild("Crouch")
if crouchButton then
crouchButton.MouseButton1Down:Connect(function()
if FLYING then
flyDownPressed = true
end
end)
crouchButton.MouseButton1Up:Connect(function()
if FLYING then
flyDownPressed = false
end
end)
end
end
end
end

touchGui = speaker.PlayerGui:FindFirstChild("TouchGui")
if touchGui then
touchFrame = touchGui:FindFirstChild("TouchControlFrame")
if touchFrame then
jumpButton = touchFrame:FindFirstChild("JumpButton")
if jumpButton then
jumpButton.MouseButton1Down:Connect(function()
if FLYING then
flyUpPressed = true
end
end)
jumpButton.MouseButton1Up:Connect(function()
if FLYING then
flyUpPressed = false
end
end)
end
end
end

if flyUpPressed ~= nil and flyDownPressed ~= nil then
break
end
task.wait(0.5)
end
end)
end end

function mobilefly(speaker)
unmobilefly(speaker)
FLYING = true

root = getRoot(speaker.Character)
if not root then return end

camera = Workspace.CurrentCamera
v3none = Vector3.new()
v3zero = Vector3.new(0, 0, 0)
v3inf = Vector3.new(9e9, 9e9, 9e9)

controlModule = nil
pcall(function()
controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)

bv = Instance.new("BodyVelocity")
bv.Name = flyVelocityHandlerName
bv.Parent = root
bv.MaxForce = v3zero
bv.Velocity = v3zero

bg = Instance.new("BodyGyro")
bg.Name = flyGyroHandlerName
bg.Parent = root
bg.MaxTorque = v3inf
bg.P = 1000
bg.D = 50

hookMobileButtons(speaker)

mfly2 = RunService.RenderStepped:Connect(function()
currentRoot = getRoot(speaker.Character)
currentCamera = Workspace.CurrentCamera
currentHumanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")

if currentHumanoid and currentRoot and currentRoot:FindFirstChild(flyVelocityHandlerName) and currentRoot:FindFirstChild(flyGyroHandlerName) then
VelocityHandler = currentRoot:FindFirstChild(flyVelocityHandlerName)
GyroHandler = currentRoot:FindFirstChild(flyGyroHandlerName)

VelocityHandler.MaxForce = v3inf
GyroHandler.MaxTorque = v3inf
currentHumanoid.PlatformStand = true
GyroHandler.CFrame = currentCamera.CoordinateFrame

moveVector = Vector3.new(0, 0, 0)

if controlModule then
direction = controlModule:GetMoveVector()
speed = flyspeed * 50

moveVector = (currentCamera.CFrame.RightVector * direction.X * speed) +
(-currentCamera.CFrame.LookVector * direction.Z * speed)
end

if flyUpPressed then
moveVector = moveVector + Vector3.new(0, flyspeed * 50, 0)
end
if flyDownPressed then
moveVector = moveVector - Vector3.new(0, flyspeed * 50, 0)
end

VelocityHandler.Velocity = moveVector
end
end)
end

function pcfly()
plr = LocalPlayer
char = plr.Character or plr.CharacterAdded:Wait()
humanoid = char:FindFirstChildOfClass("Humanoid")
if not humanoid then
repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
humanoid = char:FindFirstChildOfClass("Humanoid")
end

if flyKeyDown or flyKeyUp then
flyKeyDown:Disconnect()
flyKeyUp:Disconnect()
end

T = getRoot(char)
if not T then return end

WPressed = false
SPressed = false
APressed = false
DPressed = false
SpacePressed = false
ShiftPressed = false

function FLY()
FLYING = true
BG = Instance.new('BodyGyro')
BV = Instance.new('BodyVelocity')
BG.P = 9e4
BG.Parent = T
BV.Parent = T
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.CFrame = T.CFrame
BV.Velocity = Vector3.new(0, 0, 0)
BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)

task.spawn(function()
while FLYING do
task.wait()
camera = Workspace.CurrentCamera
humanoid.PlatformStand = true

moveDirection = Vector3.new(0, 0, 0)

if WPressed then
moveDirection = moveDirection + camera.CFrame.LookVector * flyspeed
end
if SPressed then
moveDirection = moveDirection - camera.CFrame.LookVector * flyspeed
end
if APressed then
moveDirection = moveDirection - camera.CFrame.RightVector * flyspeed
end
if DPressed then
moveDirection = moveDirection + camera.CFrame.RightVector * flyspeed
end
if SpacePressed then
moveDirection = moveDirection + Vector3.new(0, flyspeed * 2, 0)
end
if ShiftPressed then
moveDirection = moveDirection - Vector3.new(0, flyspeed * 2, 0)
end

BV.Velocity = moveDirection * 16
BG.CFrame = camera.CFrame
end

BG:Destroy()
BV:Destroy()
if humanoid then humanoid.PlatformStand = false end
end)
end

flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = true
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = true
elseif input.KeyCode == Enum.KeyCode.A then
APressed = true
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = true
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = true
elseif input.KeyCode == Enum.KeyCode.LeftShift then
ShiftPressed = true
end
pcall(function() Workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
end)

flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = false
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = false
elseif input.KeyCode == Enum.KeyCode.A then
APressed = false
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = false
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = false
elseif input.KeyCode == Enum.KeyCode.LeftShift then
ShiftPressed = false
end
end)

FLY()
end

function NOFLY()
FLYING = false
flyUpPressed = false
flyDownPressed = false
if flyKeyDown then
flyKeyDown:Disconnect()
flyKeyDown = nil
end
if flyKeyUp then
flyKeyUp:Disconnect()
flyKeyUp = nil
end

if IsOnMobile then
unmobilefly(LocalPlayer)
else
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
end
root = getRoot(LocalPlayer.Character)
if root then
root.Velocity = Vector3.new(0, 0, 0)
end
end
pcall(function() Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

function onCharacterAdded()
if FlyToggle and FlyToggle.Value then
task.wait(1)
if IsOnMobile then
mobilefly(LocalPlayer)
else
pcfly()
end
end
end

LocalPlayer.CharacterAdded:Connect(function()
NOFLY()
onCharacterAdded()
end)

Tabs.Player:Space()

FlyToggle = Tabs.Player:Toggle({
Title = "Fly",
Flag = "FlyToggle",
Value = false,
Callback = function(state)
if state then
if IsOnMobile then
mobilefly(LocalPlayer)
else
pcfly()
end
else
NOFLY()
end
end
})
ShowFlyButtonToggle = Tabs.Player:Toggle({
Title = "Fly Button",
Flag = "ShowFlyButton",
Value = false,
Callback = function(state)
IY = IY or {}
IY.FlightBtn = state

if ButtonLib and ButtonLib.Flight then
ButtonLib.Flight:SetVisible(state)
end
end
})

ButtonLib.Create:Toggle({
Text = "Flight",
Flag = "Flight",
Default = false,
Visible = false,
Callback = function(s)
if FlyToggle then
FlyToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)
FlySpeedInput = Tabs.Player:Input({
Title = "Fly Speed",
Flag = "FlySpeedInput",
Placeholder = "Enter speed value",
Value = tostring(flyspeed),
NumbersOnly = true,
Callback = function(value)
speed = tonumber(value)
if speed and speed > 0 then
flyspeed = speed
end
end
})
Tabs.Player:Space()
InfiniteSlideToggle = Tabs.Player:Toggle({
Title = "Infinite Slide",
Flag = "InfiniteSlideToggle",
Value = false,
Callback = function(state)
InfiniteSlide = state
end
})

SlideFrictionInput = Tabs.Player:Input({
Title = "Slide Friction (Negative Only)",
Flag = "SlideFrictionInput",
Placeholder = "-0.1",
Numeric = true,
Value = "-0.1",
Callback = function(value)
local n = tonumber(value)
if n then
SlideFriction = n
end
end
})

Tabs.Player:Space()
Noclip = Tabs.Player:Toggle({
Title = "Noclip",
Desc = "Walk Passthrough walls with cframespeed",
Flag = "Noclip",
Value = false,
Callback = function(state)
if state then
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local noclip = 1
local NoclipEnabled = false
local movementConnection

NoclipEnabled = true

movementConnection = RunService.RenderStepped:Connect(function()
if Character and HumanoidRootPart then
for _, part in pairs(Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = false
end
end

local MoveDirection = Character.Humanoid.MoveDirection
if MoveDirection.Magnitude > 0 then
HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + MoveDirection * (noclip / 10)
end
end
end)

LocalPlayer.CharacterAdded:Connect(function(NewCharacter)
Character = NewCharacter
HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
end)

NoclipConnection = movementConnection
else
if NoclipConnection then
NoclipConnection:Disconnect()
NoclipConnection = nil
end

local Character = LocalPlayer.Character

if Character then
for _, part in pairs(Character:GetDescendants()) do
if part:IsA("BasePart") then
part.CanCollide = true
end
end
end
end
end
})
humanoidSpeed = 0 humanoidConnection = nil originalWalkSpeed = nil function updateHumanoidSpeed() if humanoidConnection then humanoidConnection:Disconnect() humanoidConnection = nil end character = LocalPlayer.Character if not character then return end humanoid = character:FindFirstChild("Humanoid") if not humanoid then return end if originalWalkSpeed == nil then originalWalkSpeed = humanoid.WalkSpeed end if humanoidSpeed == 0 then humanoid.WalkSpeed = originalWalkSpeed else humanoid.WalkSpeed = originalWalkSpeed + humanoidSpeed humanoidConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if humanoid.WalkSpeed ~= originalWalkSpeed + humanoidSpeed then humanoid.WalkSpeed = originalWalkSpeed + humanoidSpeed end end) end end function onCharacterAdded(character) task.wait(0.5) originalWalkSpeed = nil updateHumanoidSpeed() end if LocalPlayer.Character then updateHumanoidSpeed() end LocalPlayer.CharacterAdded:Connect(onCharacterAdded) Tabs.Player:Space() Tabs.Player:Input({
Title = "Humanoid.WalkSpeed",
Desc = "This can be use to bounce too",
Value = "0",
Callback = function(value)
newSpeed = tonumber(value) or 0
humanoidSpeed = newSpeed
updateHumanoidSpeed()
end
})
Tabs.Player:Space()
TPWALKToggle = Tabs.Player:Toggle({
Title = "TP WALK",
Flag = "TPWALKToggle",
Value = false,
Callback = function(state)
TPWALK = state
if state then
startTpwalk()
else
stopTpwalk()
end
end
})

TPWALKSlider = Tabs.Player:Slider({
Title = "TPWALK VALUE",
Flag = "TPWALKSlider",
Desc = "Adjust TPWALK speed",
Value = { Min = 1, Max = 200, Default = 1, Step = 1 },
Callback = function(value)
TpwalkValue = value
end
})
Tabs.Player:Section({ Title = "Modifications" })

SpeedInput = Tabs.Player:Input({
Title = "Speed",
Flag = "SpeedInput",
Placeholder = "1500",
Numeric = true,
Value = "1500",
Callback = function(value)
local n = tonumber(value)
if n then
RealSpeed = n
end
end
})

Tabs.Player:Space()

SprintAccelerationInput = Tabs.Player:Input({
Title = "Sprint Acceleration",
Flag = "SprintAccelerationInput",
Placeholder = "1",
Numeric = true,
Value = "1",
Callback = function(value)
local n = tonumber(value)
if n then
SpringSpeedMultiplier = n
end
end
})

Tabs.Player:Space()

JumpHeightInput = Tabs.Player:Input({
Title = "Jump Height",
Flag = "JumpHeightInput",
Placeholder = "3",
Numeric = true,
Value = "3",
Callback = function(value)
local n = tonumber(value)
if n then
JumpHeight = n
end
end
})

JumpCapInput = Tabs.Player:Input({
Title = "Jump Cap",
Flag = "JumpCapInput",
Placeholder = "1",
Numeric = true,
Value = "1",
Callback = function(value)
local n = tonumber(value)
if n then
jumpcap = n
end
end
})

Tabs.Player:Space()

AirAccelerationInput = Tabs.Player:Input({
Title = "Air Acceleration",
Flag = "AirAccelerationInput",
Placeholder = "1",
Numeric = true,
Value = "1",
Callback = function(value)
local n = tonumber(value)
if n then
AirAcceleration = n
end
end
})

AirStrafeAccelerationInput = Tabs.Player:Input({
Title = "Air Strafe Acceleration",
Flag = "AirStrafeAccelerationInput",
Placeholder = "182",
Numeric = true,
Value = "182",
Callback = function(value)
local n = tonumber(value)
if n then
AirStrafeAcceleration = n
end
end
})
Tabs.Player:Section({ Title = "Emote Speed" })

local emoteEnabled = false
local speedValue = 1000
local cachedController = nil
local originalUpdate = nil

EmoteRotation = {
ModifyEnabled = false,
EmoteLerpAlpha = 0.1
}

function getController()
if cachedController and cachedController.Character == LocalPlayer.Character then
return cachedController
end
local char = LocalPlayer.Character
if not char then return nil end
for _, v in pairs(getgc(true)) do
if type(v) == "table" and rawget(v, "j") and rawget(v, "Character") == char then
cachedController = v
return v
end
end
return nil
end

function emoteMovementHook()
local controller = getController()
if not controller then return false end

if not originalUpdate then
originalUpdate = controller.Update
end

controller.Update = function(p1, p2)
if p1 and p1.Character then
local statChanges = p1.Character:FindFirstChild("StatChanges")
local speedFolder = statChanges and statChanges:FindFirstChild("Speed")
local emoteObject = speedFolder and speedFolder:FindFirstChild("EmoteSpeed")

if emoteObject then
if emoteEnabled then
p1.j = speedValue
end
end
end

if originalUpdate then
originalUpdate(p1, p2)
end

if EmoteRotation.ModifyEnabled and p1 and p1.Character then
local statChanges = p1.Character:FindFirstChild("StatChanges")
local speedFolder = statChanges and statChanges:FindFirstChild("Speed")
local emoteObject = speedFolder and speedFolder:FindFirstChild("EmoteSpeed")

if emoteObject then
local hrp = p1.Character.HumanoidRootPart
local moveVector = p1.b:GetMoveVector()

if moveVector ~= Vector3.new() then
local camera = Workspace.CurrentCamera
local cameraCFrame = camera.CFrame
local worldMove = cameraCFrame:VectorToWorldSpace(Vector3.new(moveVector.X, 0, moveVector.Z))
local moveDirection = Vector3.new(worldMove.X, 0, worldMove.Z)

if moveDirection.Magnitude > 0 then
moveDirection = moveDirection.unit
local targetCF = CFrame.new(hrp.Position, hrp.Position + moveDirection)
local alpha = EmoteRotation.EmoteLerpAlpha
if alpha < 0 then
alpha = math.abs(alpha)
local oppositeDirection = -moveDirection
local oppositeCF = CFrame.new(hrp.Position, hrp.Position + oppositeDirection)
hrp.CFrame = hrp.CFrame:Lerp(oppositeCF, math.clamp(alpha, 0, 1))
else
hrp.CFrame = hrp.CFrame:Lerp(targetCF, math.clamp(alpha, 0, 1))
end
end
end

if EmoteRotation.EmoteLerpAlpha ~= 0.1 then
if p1.e and p1.e ~= Vector3.new() and p1.e.unit ~= Vector3.new() then
local cframeDiff = hrp.CFrame - hrp.CFrame.p
local targetCFrame = CFrame.new(Vector3.new(), p1.e.unit)

local alpha = EmoteRotation.EmoteLerpAlpha
if alpha < 0 then
local oppositeCFrame = CFrame.new(Vector3.new(), -p1.e.unit)
hrp.CFrame = CFrame.new(hrp.CFrame.p) * (cframeDiff:Lerp(oppositeCFrame, math.clamp(math.abs(alpha), 0, 1)) - (cframeDiff:Lerp(oppositeCFrame, math.clamp(math.abs(alpha), 0, 1))).p)
else
hrp.CFrame = CFrame.new(hrp.CFrame.p) * (cframeDiff:Lerp(targetCFrame, math.clamp(alpha, 0, 1)) - (cframeDiff:Lerp(targetCFrame, math.clamp(alpha, 0, 1))).p)
end
end
end
end
end
end
return true
end

function removeEmoteMovementHook()
local controller = getController()
if controller and originalUpdate then
controller.Update = originalUpdate
originalUpdate = nil
end
end

Tabs.Player:Input({
Title = "Speed Value",
Placeholder = "1000",
Value = "1000",
Numeric = true,
Callback = function(val)
speedValue = tonumber(val) or 1000
if emoteEnabled then
emoteMovementHook()
end
end
})

Tabs.Player:Toggle({
Title = "Emote Speed",
Default = false,
Callback = function(state)
emoteEnabled = state
if state then
emoteMovementHook()
else
removeEmoteMovementHook()
if EmoteRotation.ModifyEnabled then
emoteMovementHook()
end
end
end
})

Tabs.Player:Toggle({
Title = "Emote Rotation",
Flag = "EmoteRotationToggle",
Default = false,
Callback = function(state)
EmoteRotation.ModifyEnabled = state
if state then
emoteMovementHook()
else
removeEmoteMovementHook()
if emoteEnabled then
emoteMovementHook()
end
end
end
})

Tabs.Player:Input({
Title = "Rotation Speed (Lerp Alpha)",
Flag = "EmoteRotationSpeed",
Placeholder = "0.1 (negative = reverse)",
Value = "0.1",
Numeric = true,
Callback = function(value)
local n = tonumber(value)
if n then
EmoteRotation.EmoteLerpAlpha = n
end
end
})

local function onCharacterAdded()
task.wait(0.5)
cachedController = nil
originalUpdate = nil
if emoteEnabled or EmoteRotation.ModifyEnabled then
emoteMovementHook()
end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
onCharacterAdded()
end

Tabs.Auto:Section({ Title = "Auto", TextSize = 40 })
Tabs.Auto:Space()
EasyTrmp = false
EasyTrmpSpeed = 50
extra = 100
floorDrop = 0
last = tick()
airTick = 0
airborne = false
push = nil
speed = base
renderConnection = nil
function onRenderStepped()
local dt = tick() - last
last = tick()
local ch = LocalPlayer.Character
if not ch then return end
local hrp = ch:FindFirstChild("HumanoidRootPart")
local hum = ch:FindFirstChild("Humanoid")
if not hrp or not hum then return end
local a = hum.FloorMaterial == Enum.Material.Air
if airborne and not a then
speed = math.max(EasyTrmpSpeed - floorDrop, speed - 10)
end
airborne = a
if EasyTrmp then
if a then
airTick = airTick + dt
while airTick >= 0.04 do
airTick = airTick - 0.04
local add = math.max(0.1, 2.5 * (0.04 / 1))
speed = math.min(EasyTrmpSpeed + extra, speed + add)
end
else
airTick = 0
speed = math.max(EasyTrmpSpeed - floorDrop, speed - (2.5 * dt))
end
if push then push:Destroy() end
local d = Workspace.CurrentCamera.CFrame.LookVector
d = Vector3.new(d.X, 0, d.Z)
if d.Magnitude > 0 then d = d.Unit end
local bv = Instance.new("BodyVelocity")
bv.Velocity = d * speed
bv.MaxForce = Vector3.new(4e5, 0, 4e5)
bv.P = 1250
bv.Parent = hrp
game:GetService("Debris"):AddItem(bv, 0.1)
push = bv
else
if push then push:Destroy() end
push = nil
speed = EasyTrmpSpeed
airTick = 0
airborne = false
end
end
function StartEasyTrimp()
if EasyTrmp then return end
EasyTrmp = true
last = tick()
airTick = 0
airborne = false
speed = EasyTrmpSpeed
if not renderConnection then
renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
end
end
function StopEasyTrimp()
if not EasyTrmp then return end
EasyTrmp = false
if push then
push:Destroy()
push = nil
end
speed = EasyTrmpSpeed
airTick = 0
airborne = false
end
renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
Tabs.Auto:Section({Title = "Easy Trmp"})
ShowEasyTrmpButton = Tabs.Auto:Toggle({
Title = "Show Easy Trmp Button",
Flag = "ShowEasyTrmpButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.EasyTrmpButton then
ButtonLib.EasyTrmpButton:SetVisible(state)
end
end
})
EasyTrmpToggle = Tabs.Auto:Toggle({
Title = "Easy Trmp",
Flag = "EasyTrmpToggle",
Value = false,
Callback = function(state)
EasyTrmp = state
if not state then
StopEasyTrimp()
else
StartEasyTrimp()
end
end
})
Easy_Trmp_Speed = Tabs.Auto:Input({
Title = "Debug:Easy_Trmp_Speed",
Flag = "Easy_Trmp_Speed",
Placeholder = "-0.1",
Numeric = true,
Value = "-0.1",
Callback = function(value)
local n = tonumber(value)
if n then
EasyTrmpSpeed = n
end
end
})
ButtonLib.Create:Toggle({
Text = "Easy Trmp",
Flag = "EasyTrmpButton",
Default = false,
Visible = false,
Callback = function(s)
if EasyTrmpToggle then
EasyTrmpToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.5, 0)

Tabs.Auto:Section({Title="Bhop"})

BhopToggle = Tabs.Auto:Toggle({
Title = "Bhop",
Flag = "BhopToggle",
Value = false,
Callback = function(state)
autoJumpEnabled = state
checkBhopState()
reapplyModifications()
end
})

BhopHoldToggle = Tabs.Auto:Toggle({
Title = "Bhop Jump button/Space",
Flag = "BhopHoldToggle",
Value = false,
Callback = function(state)
bhopHoldFeature = state
if not state then
bhopHoldActive = false
checkBhopState()
reapplyModifications()
end
end
})

ShowBunnyHopButtonToggle = Tabs.Auto:Toggle({
Title = "Bhop Button",
Flag = "ShowBunnyHopButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.BunnyHopToggle then
ButtonLib.BunnyHopToggle:SetVisible(state)
end
end
})

AccelerationDropdown = Tabs.Auto:Dropdown({
Title = "Bhop Mode",
Flag = "AccelerationDropdown",
Values = {"No Acceleration", "Ground Acceleration", "Acceleration"},
Value = "Acceleration",
Callback = function(value)
accelerationMethod = value
reapplyModifications()
end
})

AccelerationInput = Tabs.Auto:Input({
Title = "Bhop Acceleration (Negative Only)",
Flag = "AccelerationInput",
Placeholder = "-0.2",
Numeric = true,
Value = "-0.2",
Callback = function(value)
local n = tonumber(value)
if n then
groundFriction = n
reapplyModifications()
end
end
})

Tabs.Auto:Section({Title="Auto Acceleration (Legit)"})

AutoAccelerationToggle = Tabs.Auto:Toggle({
Title = "Auto Acceleration (Legit)",
Flag = "AutoAccelerationToggle",
Value = false,
Callback = function(state)
AutoAccelerationEnabled = state
reapplyModifications()
end
})

MaxAccelerationInput = Tabs.Auto:Input({
Title = "Max Acceleration",
Flag = "MaxAccelerationInput",
Placeholder = "3",
Numeric = true,
Value = "3",
Callback = function(value)
local n = tonumber(value)
if n then
MaxAcceleration = n
reapplyModifications()
end
end
})

MinAccelerationInput = Tabs.Auto:Input({
Title = "Min Acceleration",
Flag = "MinAccelerationInput",
Placeholder = "-1",
Numeric = true,
Value = "-1",
Callback = function(value)
local n = tonumber(value)
if n then
MinAcceleration = n
reapplyModifications()
end
end
})

MaxSpeedInput = Tabs.Auto:Input({
Title = "Max Speed",
Flag = "MaxSpeedInput",
Placeholder = "70",
Numeric = true,
Value = "70",
Callback = function(value)
local n = tonumber(value)
if n then
MaxSpeed = n
reapplyModifications()
end
end
})

ButtonLib.Create:Toggle({
Text = "Bunny Hop",
Flag = "BunnyHopToggle",
Default = false,
Visible = false,
Callback = function(s)
if BhopToggle then
BhopToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)

local previousCrouchState = false
local spamDown = true
local previousAutoCrouch = false
local crouchConnection = nil
function fireKeybind(down, key)
local eventPath = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Events"):WaitForChild("KeybindUsed")
eventPath:Fire(key, down)
end
function setupAutoCrouchListeners()
if crouchConnection then crouchConnection:Disconnect() end
crouchConnection = RunService.Heartbeat:Connect(function()
local autoOn = AutoCrouch
local mode = AutoCrouchMode
if previousAutoCrouch and not autoOn then
local character = LocalPlayer.Character
if character and character:FindFirstChild("Humanoid") then
if mode == "Normal" then
fireKeybind(false, "Crouch")
end
end
end
previousAutoCrouch = autoOn
if not autoOn then return end
local character = LocalPlayer.Character
if not character or not character:FindFirstChild("Humanoid") then return end
local humanoid = character.Humanoid
if mode == "Spam" then
fireKeybind(spamDown, "Crouch")
spamDown = not spamDown
elseif mode == "Normal" then
fireKeybind(true, "Crouch")
else
local isAir = (humanoid.FloorMaterial == Enum.Material.Air) and (humanoid:GetState() ~= Enum.HumanoidStateType.Seated)
local shouldCrouch = (mode == "Air" and isAir) or (mode == "Ground" and not isAir)
if shouldCrouch ~= previousCrouchState then
fireKeybind(shouldCrouch, "Crouch")
previousCrouchState = shouldCrouch
end
end
end)
LocalPlayer.CharacterAdded:Connect(function(newChar)
previousCrouchState = false
spamDown = true
end)
end
setupAutoCrouchListeners()
Tabs.Auto:Space()
AutoCrouchToggle = Tabs.Auto:Toggle({
Title = "Auto Crouch",
Flag = "AutoCrouchToggle",
Value = false,
Callback = function(state)
AutoCrouch = state
if not state then
previousAutoCrouch = false
end
end
})
ButtonLib.Create:Toggle({
Text = "Auto Crouch",
Flag = "AutoCrouchToggle",
Default = false,
Visible = false,
Callback = function(s)
if AutoCrouchToggle then
AutoCrouchToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)
ShowAutoCrouchButtonToggle = Tabs.Auto:Toggle({
Title = "Show Auto Crouch Button",
Flag = "ShowAutoCrouchButton",
Value = false,
Callback = function(state)
ShowAutoCrouchButton = state
if ButtonLib and ButtonLib.AutoCrouchToggle then
ButtonLib.AutoCrouchToggle:SetVisible(state)
end
end
})
AutoCrouchModeDropdown = Tabs.Auto:Dropdown({
Title = "Auto Crouch Mode",
Flag = "AutoCrouchModeDropdown",
Values = {"Air", "Spam", "Ground", "Normal"},
Value = "Air",
Callback = function(value)
AutoCrouchMode = value
end
})

Tabs.Auto:Space()
function startAutoCarry()
local lastCarryTime = 0

AutoCarryConnection = RunService.Heartbeat:Connect(function()
if not AutoCarry then return end

if os.clock() - lastCarryTime < 0.3 then return end

local char = LocalPlayer.Character
if not char then return end

if char:GetAttribute("Carrying") == true then return end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return end

for _, other in ipairs(Players:GetPlayers()) do
if other ~= LocalPlayer and other.Character then
local otherHRP = other.Character:FindFirstChild("HumanoidRootPart")
local otherHum = other.Character:FindFirstChild("Humanoid")

if otherHRP and otherHum then
local isDowned = other.Character:GetAttribute("Downed") == true

if isDowned then
local dist = (hrp.Position - otherHRP.Position).Magnitude
if dist <= 20 then
lastCarryTime = os.clock()

local args = { other.Name }
pcall(function()
ReplicatedStorage:WaitForChild("Events")
:WaitForChild("Revive"):WaitForChild("CarryPlayer")
:FireServer(unpack(args))
end)

return
end
end
end
end
end
end)
end
function stopAutoCarry()
if AutoCarryConnection then
AutoCarryConnection:Disconnect()
AutoCarryConnection = nil
end
end

AutoCarryToggle = Tabs.Auto:Toggle({
Title = "Auto Carry",
Flag = "AutoCarryToggle",
Value = false,
Callback = function(state)
AutoCarry = state
if state then
startAutoCarry()
else
stopAutoCarry()
end
end
})


ButtonLib.Create:Toggle({
Text = "AUTO CARRY",
Flag = "CarryToggle",
Default = false,
Visible = false,
Callback = function(s)
if AutoCarryToggle then
AutoCarryToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)


ShowCarryButtonToggle = Tabs.Auto:Toggle({
Title = "Show Carry Button",
Flag = "ShowCarryButton",
Value = false,
Callback = function(state)
ShowCarryButton = state

if ButtonLib and ButtonLib.CarryToggle then
ButtonLib.CarryToggle:SetVisible(state)
end
end
})

Tabs.Auto:Space()
local reviveRange = 10
local loopDelay = 0.15
local reviveLoopHandle = nil
FastRevive = false

function startAutoRevive()
if reviveLoopHandle then return end

reviveLoopHandle = task.spawn(function()
while FastRevive do
local LocalPlayer = Players.LocalPlayer
if LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
local myHRP = LocalPlayer.Character.HumanoidRootPart
for _, pl in ipairs(Players:GetPlayers()) do
if pl ~= LocalPlayer then
local char = pl.Character
if char and char:FindFirstChild("HumanoidRootPart") then
local hrp = char.HumanoidRootPart
local success, dist = pcall(function()
return (myHRP.Position - hrp.Position).Magnitude
end)
if success and dist and dist <= reviveRange then
pcall(function()

local Event = LocalPlayer.PlayerScripts.Events.KeybindUsed
Event:Fire(
"Interact",
true
)
end)
end
end
end
end
end
task.wait(loopDelay)
end
reviveLoopHandle = nil
end)
end

function stopAutoRevive()
if reviveLoopHandle then
task.cancel(reviveLoopHandle)
reviveLoopHandle = nil
end
end

FastReviveToggle = Tabs.Auto:Toggle({
Title = "Auto Revive Teammate",
Flag = "FastReviveToggle",
Value = false,
Callback = function(state)
FastRevive = state
if state then
startAutoRevive()
else
stopAutoRevive()
end
end
})

Tabs.Auto:Space()

function fireVoteServer(mapNumber)
local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10)

if eventsFolder then
local voteEvent = eventsFolder:WaitForChild("Vote", 10)
if voteEvent and voteEvent:IsA("RemoteEvent") then
local args = {mapNumber}
voteEvent:FireServer(unpack(args))
end
end
end

function startAutoVote()
AutoVoteConnection = RunService.Heartbeat:Connect(function()
fireVoteServer(SelectedMap)
end)
end

function stopAutoVote()
if AutoVoteConnection then
AutoVoteConnection:Disconnect()
AutoVoteConnection = nil
end
end
AutoVoteDropdown = Tabs.Auto:Dropdown({
Title = "Auto Vote Map",
Flag = "AutoVoteDropdown",
Values = {"Map 1", "Map 2", "Map 3", "Map 4"},
Value = "Map 1",
Callback = function(value)
if value == "Map 1" then
SelectedMap = 1
elseif value == "Map 2" then
SelectedMap = 2
elseif value == "Map 3" then
SelectedMap = 3
elseif value == "Map 4" then
SelectedMap = 4
end
end
})

AutoVoteToggle = Tabs.Auto:Toggle({
Title = "Auto Vote",
Flag = "AutoVoteToggle",
Value = false,
Callback = function(state)
AutoVote = state
if state then
startAutoVote()
else
stopAutoVote()
end
end
})

SelfReviveMethod = "Spawnpoint"
local lastSavedPosition = nil
local respawnConnection = nil
local AutoSelfReviveConnection = nil
local hasRevived = false
local isReviving = false

Tabs.Auto:Space()
AutoSelfReviveToggle = Tabs.Auto:Toggle({
Title = "Auto Self Revive",
Flag = "AutoSelfReviveToggle",
Value = false,
Callback = function(state)
AutoSelfRevive = state
if state then
if AutoSelfReviveConnection then
AutoSelfReviveConnection:Disconnect()
end
if respawnConnection then
respawnConnection:Disconnect()
end

local character = LocalPlayer.Character
if character then
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

AutoSelfReviveConnection = character:GetAttributeChangedSignal("Downed"):Connect(function()
local isDowned = character:GetAttribute("Downed")
if isDowned and not isReviving then
isReviving = true

if SelfReviveMethod == "Spawnpoint" then
if not hasRevived then
hasRevived = true
pcall(function()
local Event = ReplicatedStorage.Events.Respawn
Event:FireServer()
end)
task.delay(10, function()
hasRevived = false
end)
task.delay(1, function()
isReviving = false
end)
else
isReviving = false
end
elseif SelfReviveMethod == "Fake Revive" then
if hrp then
lastSavedPosition = hrp.Position
end

task.spawn(function()
pcall(function()
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Respawn"):FireServer()
end)

local newCharacter
repeat
newCharacter = LocalPlayer.Character
task.wait()
until newCharacter and newCharacter:FindFirstChild("HumanoidRootPart") and newCharacter ~= character

if newCharacter then
local newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
if lastSavedPosition and newHRP then
newHRP.CFrame = CFrame.new(lastSavedPosition)
end
end

isReviving = false
end)
end
end
end)
end

respawnConnection = LocalPlayer.CharacterAdded:Connect(function(newChar)
task.wait(0.5)
local newHumanoid = newChar:WaitForChild("Humanoid")
local newHRP = newChar:WaitForChild("HumanoidRootPart")

if AutoSelfRevive then
AutoSelfReviveConnection = newChar:GetAttributeChangedSignal("Downed"):Connect(function()
local isDowned = newChar:GetAttribute("Downed")
if isDowned and not isReviving then
isReviving = true

if SelfReviveMethod == "Spawnpoint" then
if not hasRevived then
hasRevived = true
pcall(function()
local Event = ReplicatedStorage.Events.Respawn
Event:FireServer()
end)
task.delay(10, function()
hasRevived = false
end)
task.delay(1, function()
isReviving = false
end)
else
isReviving = false
end
elseif SelfReviveMethod == "Fake Revive" then
if newHRP then
lastSavedPosition = newHRP.Position
end

task.spawn(function()
pcall(function()
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Respawn"):FireServer()
end)

local freshCharacter
repeat
freshCharacter = LocalPlayer.Character
task.wait()
until freshCharacter and freshCharacter:FindFirstChild("HumanoidRootPart") and freshCharacter ~= newChar

if freshCharacter then
local freshHRP = freshCharacter:FindFirstChild("HumanoidRootPart")
if lastSavedPosition and freshHRP then
freshHRP.CFrame = CFrame.new(lastSavedPosition)
end
end

isReviving = false
end)
end
end
end)
end
end)
else
if AutoSelfReviveConnection then
AutoSelfReviveConnection:Disconnect()
AutoSelfReviveConnection = nil
end
if respawnConnection then
respawnConnection:Disconnect()
respawnConnection = nil
end
hasRevived = false
isReviving = false
lastSavedPosition = nil
end
end
})

SelfReviveMethodDropdown = Tabs.Auto:Dropdown({
Title = "Self Revive Method",
Flag = "SelfReviveMethodDropdown",
Values = {"Spawnpoint", "Fake Revive"},
Value = "Spawnpoint",
Callback = function(value)
SelfReviveMethod = value
end
})

if LocalPlayer.Character and AutoSelfRevive then
local char = LocalPlayer.Character
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
AutoSelfReviveConnection = char:GetAttributeChangedSignal("Downed"):Connect(function()
end)
end

function manualRevive()
local character = LocalPlayer.Character
if not character then return end
local hrp = character:FindFirstChild("HumanoidRootPart")
local isDowned = character:GetAttribute("Downed")
if not isDowned then return end

if SelfReviveMethod == "Spawnpoint" then
if not hasRevived then
hasRevived = true
pcall(function()
local Event = ReplicatedStorage.Events.Respawn
Event:FireServer()
end)
task.delay(10, function()
hasRevived = false
end)
end
elseif SelfReviveMethod == "Fake Revive" then
if hrp then
lastSavedPosition = hrp.Position
end
task.spawn(function()
pcall(function()
ReplicatedStorage:WaitForChild("Events"):WaitForChild("Respawn"):FireServer()
end)

local newCharacter
repeat
newCharacter = LocalPlayer.Character
task.wait()
until newCharacter and newCharacter:FindFirstChild("HumanoidRootPart") and newCharacter ~= character

if newCharacter then
local newHRP = newCharacter:FindFirstChild("HumanoidRootPart")
if lastSavedPosition and newHRP then
newHRP.CFrame = CFrame.new(lastSavedPosition)
end
end
end)
end
end
Tabs.Auto:Button({
Title = "Manual Revive",
Desc = "Manually revive yourself",
Icon = "heart",
Callback = function()
manualRevive()
end
})

Tabs.Auto:Space()
AutoWhistleToggle = Tabs.Auto:Toggle({
Title = "Auto Whistle",
Flag = "AutoWhistleToggle",
Value = false,
Callback = function(state)
AutoWhistle = state
if state then
startAutoWhistle()
else
stopAutoWhistle()
end
end
})
local autoWhistleHandle = nil

function startAutoWhistle()
if autoWhistleHandle then return end
autoWhistleHandle = task.spawn(function()
while AutoWhistle do
pcall(function()
local Event = ReplicatedStorage.Events.Whistle
Event:FireServer()
end)
task.wait(1)
end
end)
end

function stopAutoWhistle()
AutoWhistle = false
if autoWhistleHandle then
task.cancel(autoWhistleHandle)
autoWhistleHandle = nil
end
end
Tabs.Auto:Section({ Title = "Afk Farm", TextSize = 20 })
Tabs.Auto:Divider()
Tabs.Auto:Paragraph({
Title = [[ Sorry but afk farm is Unsupported
Your data is not begin saved in Legacy Evade don't waste your time :) ] ],
TextSize = 15 })
Tabs.Auto:Toggle({ Title = "AFK Farm", Value = false, Locked = true })
AFKType = Tabs.Auto:Dropdown({
Title = "Farm Types",
Flag = "AFKFarmType",
Values = {"Not Available"},
Value = "Not Available",
Locked = true,
Callback = function(value)
return
end
})

AimbotEnabled = false
ShowFOV = false
FOVThickness = 2
FOVColor = Color3.new(0, 1, 0)
Cam = Workspace.CurrentCamera

targetTypes = {}
aimPart = "Head"
smoothnessValue = 10
wallCheckEnabled = false
fovRadius = 100
lockFOVToCenter = true
AimbotCircle = nil
aimbotRenderConnection = nil
aimbotRunning = false

function getAimPart(character)
if aimPart == "Head" then
return character:FindFirstChild("Head")
elseif aimPart == "Body" then
return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
elseif aimPart == "Legs" then
return character:FindFirstChild("HumanoidRootPart")
end
return character:FindFirstChild("Head")
end

function isVisible(part)
if not wallCheckEnabled then
return true
end

character = LocalPlayer.Character
if not character then return false end

humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return false end

origin = humanoidRootPart.Position
target = part.Position
direction = (target - origin).Unit
ray = Ray.new(origin, direction * (target - origin).Magnitude)
hit, position = Workspace:FindPartOnRayWithIgnoreList(ray, {character, part.Parent})

return hit == nil or hit:IsDescendantOf(part.Parent)
end

function lookAt(pos)
currentCFrame = Cam.CFrame
lookVector = (pos - currentCFrame.Position).Unit
targetCFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + lookVector)

Cam.CFrame = currentCFrame:Lerp(targetCFrame, 1 / smoothnessValue)
end

function isEnemyNPC(model)
if not model:IsA("Model") then return false end
local humanoid = model:FindFirstChild("Humanoid")
if not humanoid or humanoid.Health <= 0 then return false end

if model:GetAttribute("IsEnemy") then return true end
if model:GetAttribute("IsNPC") then return true end
if humanoid:GetAttribute("Team") == "Enemy" then return true end
if model:FindFirstChild("NPC") or model:FindFirstChild("Enemy") then return true end

local npcStorage = Workspace:FindFirstChild("NPCStorage")
if npcStorage and model:IsDescendantOf(npcStorage) then return true end

return false
end

function getAllTargets()
local targets = {}

for _, player in ipairs(Players:GetPlayers()) do
if player ~= LocalPlayer then
table.insert(targets, {type = "Player", object = player})
end
end

local npcStorage = Workspace:FindFirstChild("NPCStorage")
if npcStorage then
for _, model in ipairs(npcStorage:GetChildren()) do
if isEnemyNPC(model) then
table.insert(targets, {type = "NPC", object = model})
end
end
end

for _, model in ipairs(Workspace:GetChildren()) do
if isEnemyNPC(model) then
table.insert(targets, {type = "NPC", object = model})
end
end

return targets
end

function getClosestEnemyInFOV()
local closestTarget = nil
local closestDistance = math.huge

local screenCenter = lockFOVToCenter and Cam.ViewportSize / 2 or UserInputService:GetMouseLocation()

local allTargets = getAllTargets()

for _, targetData in ipairs(allTargets) do
local shouldTarget = false

if #targetTypes == 0 then
shouldTarget = true
else
for _, selectedType in ipairs(targetTypes) do
if targetData.type == selectedType then
shouldTarget = true
break
end
end
end

if shouldTarget then
local character = nil
if targetData.type == "Player" then
character = targetData.object.Character
else
character = targetData.object
end

if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
local aimPartInstance = getAimPart(character)
if aimPartInstance then
local screenPos, visible = Cam:WorldToViewportPoint(aimPartInstance.Position)
if visible then
local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

if distance < fovRadius and distance < closestDistance and isVisible(aimPartInstance) then
closestDistance = distance
closestTarget = {
character = character,
type = targetData.type
}
end
end
end
end
end
end

return closestTarget
end

function createFOVCircle()
if AimbotCircle then
AimbotCircle:Remove()
AimbotCircle = nil
end

if not ShowFOV then return end

local circle = Drawing.new("Circle")
circle.Visible = ShowFOV
circle.Radius = fovRadius
circle.Color = FOVColor
circle.Thickness = FOVThickness
circle.Filled = false

if lockFOVToCenter then
local viewportSize = Cam.ViewportSize
circle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
else
circle.Position = UserInputService:GetMouseLocation()
end

AimbotCircle = circle

if aimbotRenderConnection then
aimbotRenderConnection:Disconnect()
end

aimbotRenderConnection = RunService.RenderStepped:Connect(function()
if circle then circle.Radius = fovRadius
circle.Visible = ShowFOV
circle.Color = FOVColor
circle.Thickness = FOVThickness

if lockFOVToCenter then
local viewportSize = Cam.ViewportSize
circle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
else
circle.Position = UserInputService:GetMouseLocation()
end
end
end)
end

function updateDrawings()
if ShowFOV and not AimbotCircle then
createFOVCircle()
elseif not ShowFOV and AimbotCircle then
AimbotCircle:Remove()
AimbotCircle = nil
elseif AimbotCircle then
AimbotCircle.Radius = fovRadius
AimbotCircle.Color = FOVColor
AimbotCircle.Thickness = FOVThickness

if lockFOVToCenter then
local viewportSize = Cam.ViewportSize
AimbotCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
else
AimbotCircle.Position = UserInputService:GetMouseLocation()
end
end
end

function startAimbot()
createFOVCircle()

aimbotRunning = true

while AimbotEnabled and aimbotRunning do
RunService.RenderStepped:Wait()

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
continue
end

local closestTarget = getClosestEnemyInFOV()
if closestTarget then
local character = closestTarget.character
if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
local aimPartInstance = getAimPart(character)
if aimPartInstance then
lookAt(aimPartInstance.Position)
end
end
end
end
end

function stopAimbot()
aimbotRunning = false

if AimbotCircle then
AimbotCircle:Remove()
AimbotCircle = nil
end

if aimbotRenderConnection then
aimbotRenderConnection:Disconnect()
aimbotRenderConnection = nil
end
end

function handleCharacterRespawn()
if AimbotEnabled then
task.wait(1)
if AimbotCircle then
AimbotCircle:Remove()
AimbotCircle = nil
end
createFOVCircle()
end
end

LocalPlayer.CharacterAdded:Connect(function(character)
handleCharacterRespawn()
end)

Tabs.Combat:Section({ Title = "Aimbot Settings" })

AimbotToggle = Tabs.Combat:Toggle({
Title = "Aimbot",
Flag = "AimbotToggle",
Value = false,
Callback = function(state)
AimbotEnabled = state
if state then
coroutine.wrap(startAimbot)()
else
stopAimbot()
end
end
})

AimPartDropdown = Tabs.Combat:Dropdown({
Title = "Aim Part",
Flag = "AimPartDropdown",
Desc = "Select which part to aim at",
Values = { "Head", "Body", "Legs" },
Value = "Head",
Callback = function(value)
aimPart = value
end
})

TargetTypeDropdown = Tabs.Combat:Dropdown({
Title = "Target Type",
Flag = "TargetTypeDropdown",
Desc = "Select which types to target",
Values = { "Player", "NPC" },
Value = {},
Multi = true,
AllowNone = true,
Callback = function(values)
targetTypes = values
end
})

SmoothnessSlider = Tabs.Combat:Slider({
Title = "Smoothness",
Flag = "SmoothnessSlider",
Desc = "Higher = smoother aim, Lower = snappier aim",
Value = { Min = 1, Max = 20, Default = 10, Step = 1 },
Callback = function(value)
smoothnessValue = value
end
})

WallCheckToggle = Tabs.Combat:Toggle({
Title = "Wall Check",
Flag = "WallCheckToggle",
Value = false,
Callback = function(state)
wallCheckEnabled = state
end
})

Tabs.Combat:Section({ Title = "FOV Settings" })

ShowFOVToggle = Tabs.Combat:Toggle({
Title = "Show FOV Circle",
Flag = "ShowFOVToggle",
Value = false,
Callback = function(state)
ShowFOV = state
updateDrawings()
end
})

LockFOVToggle = Tabs.Combat:Toggle({
Title = "Lock FOV On Middle Screen",
Flag = "LockFOVToggle",
Value = true,
Callback = function(state)
lockFOVToCenter = state
updateDrawings()
end
})

FOVRadiusSlider = Tabs.Combat:Slider({
Title = "FOV Radius",
Flag = "FOVRadiusSlider",
Desc = "Size of the targeting area",
Value = { Min = 10, Max = 500, Default = 100, Step = 5 },
Callback = function(value)
fovRadius = value
updateDrawings()
end
})

FOVColorPicker = Tabs.Combat:Colorpicker({
Title = "FOV Color",
Flag = "FOVColorPicker",
Desc = "FOV Circle Color",
Default = Color3.fromRGB(0, 255, 0),
Locked = false,
Callback = function(color)
FOVColor = color
updateDrawings()
end
})

FOVThicknessSlider = Tabs.Combat:Slider({
Title = "FOV Thickness",
Flag = "FOVThicknessSlider",
Desc = "Thickness of the FOV circle",
Value = { Min = 1, Max = 10, Default = 2, Step = 1 },
Callback = function(value)
FOVThickness = value
updateDrawings()
end
})

Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
Tabs.Visuals:Divider()
local cameraStretchConnection
function setupCameraStretch()
cameraStretchConnection = nil
local stretchHorizontal = 0.80
local stretchVertical = 0.80
CameraStretchToggle = Tabs.Visuals:Toggle({
Title = "Camera Stretch",
Flag = "CameraStretchToggle",
Value = false,
Callback = function(state)
if state then
if cameraStretchConnection then cameraStretchConnection:Disconnect() end
cameraStretchConnection = RunService.RenderStepped:Connect(function()
local Camera = Workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
else
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = nil
end
end
end
})

CameraStretchHorizontalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Horizontal",
Flag = "CameraStretchHorizontalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchHorizontal),
Callback = function(value)
local num = tonumber(value)
if num then
stretchHorizontal = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = RunService.RenderStepped:Connect(function()
local Camera = Workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})

CameraStretchVerticalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Vertical",
Flag = "CameraStretchVerticalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchVertical),
Callback = function(value)
local num = tonumber(value)
if num then
stretchVertical = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = RunService.RenderStepped:Connect(function()
local Camera = Workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})
end

setupCameraStretch()
Tabs.Visuals:Space()
FearScriptToggle = Tabs.Visuals:Toggle({
Title = "Disable Fear Effect",
Desc = "Remove View Bob fear effect/sounds including disable camshake",
Flag = "FearScriptToggle",
Value = false,
Callback = function(state)
local HUD = PlayerGui:FindFirstChild("HUD")
if HUD then
local FearScript = HUD:FindFirstChild("Fear")
if FearScript then
FearScript.Disabled = state
end
end

if state then
task.spawn(function()
while FearScriptToggle.Value do
local HUD = PlayerGui:FindFirstChild("HUD")
if HUD then
local FearScript = HUD:FindFirstChild("Fear")
if FearScript then
FearScript.Disabled = true
end
end
end
end)
end
end
})
Tabs.Visuals:Space()

FullBrightToggle = Tabs.Visuals:Toggle({
Title = "Full Bright",
Flag = "FullBrightToggle",
Desc = "Ya Like drinking Night Vision while mining in da cave and sceard of creeper blow you up dawg?",
Value = false,
Callback = function(state)
FullBright = state
if state then

originalBrightness = Lighting.Brightness
originalAmbient = Lighting.Ambient
originalOutdoorAmbient = Lighting.OutdoorAmbient
originalColorShiftBottom = Lighting.ColorShift_Bottom
originalColorShiftTop = Lighting.ColorShift_Top

function applyFullBright()
if Lighting.Brightness ~= 1 then
Lighting.Brightness = 1
end
if Lighting.Ambient ~= Color3.new(1, 1, 1) then
Lighting.Ambient = Color3.new(1, 1, 1)
end
if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then
Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end
if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then
Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
end
if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then
Lighting.ColorShift_Top = Color3.new(1, 1, 1)
end
end

applyFullBright()

if fullBrightConnection then
fullBrightConnection:Disconnect()
end

fullBrightConnection = RunService.Heartbeat:Connect(function()
if FullBright then
applyFullBright()
end
end)

fullBrightCharConnection = LocalPlayer.CharacterAdded:Connect(function()
task.wait(1)
if FullBright then
applyFullBright()
end
end)

else
if fullBrightConnection then
fullBrightConnection:Disconnect()
fullBrightConnection = nil
end

if fullBrightCharConnection then
fullBrightCharConnection:Disconnect()
fullBrightCharConnection = nil
end

if originalBrightness then
Lighting.Brightness = originalBrightness
Lighting.Ambient = originalAmbient
Lighting.OutdoorAmbient = originalOutdoorAmbient
Lighting.ColorShift_Bottom = originalColorShiftBottom
Lighting.ColorShift_Top = originalColorShiftTop
end
end
end
})
Tabs.Visuals:Space()

NoFogToggle = Tabs.Visuals:Toggle({
Title = "Remove Fog",
Flag = "NoFogToggle",
Value = false,
Callback = function(state)
NoFog = state
if state then
startNoFog()
else
stopNoFog()
end
end
})
Tabs.Visuals:Space()

Tabs.Visuals:Button({
Title = "Shit Render",
Callback = function()
Lighting.GlobalShadows = false
Lighting.FogEnd = 1e10
Lighting.Brightness = 1

local Terrain = Workspace:FindFirstChildOfClass("Terrain")
if Terrain then
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0
Terrain.WaterReflectance = 0
Terrain.WaterTransparency = 1
end

for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("BasePart") then
obj.Material = Enum.Material.Plastic
obj.Reflectance = 0
elseif obj:IsA("Decal") or obj:IsA("Texture") then
obj:Destroy()
elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
obj:Destroy()
elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
obj:Destroy()
end
end

for _, player in ipairs(Players:GetPlayers()) do
local char = player.Character
if char then
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("Accessory") or part:IsA("Clothing") then
part:Destroy()
end
end
end
end
end
})
Tabs.Visuals:Space()
local MainInterface = PlayerGui:FindFirstChild("MainInterface")
local TimerContainer, TimerLabel, StatusLabel

if MainInterface then
TimerContainer = MainInterface:WaitForChild("Center"):WaitForChild("RoundTimer")
local RoundTimerFrame = TimerContainer:WaitForChild("RoundTimer")
TimerLabel = RoundTimerFrame:WaitForChild("Timer")
StatusLabel = RoundTimerFrame:WaitForChild("About")

local InnerFrame = RoundTimerFrame:WaitForChild("RoundTimer")
if InnerFrame then
local existingCorner = InnerFrame:FindFirstChild("UICorner")
if not existingCorner then
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = InnerFrame
end
end
else
MainInterface = Instance.new("ScreenGui")
MainInterface.Name = "MainInterface"
MainInterface.Parent = PlayerGui
MainInterface.ResetOnSpawn = false
MainInterface.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainInterface.Enabled = true
MainInterface.DisplayOrder = 2

TimerContainer = Instance.new("Frame")
TimerContainer.Name = "Center"
TimerContainer.Parent = MainInterface
TimerContainer.AnchorPoint = Vector2.new(0.5, 1)
TimerContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TimerContainer.BackgroundTransparency = 1
TimerContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
TimerContainer.Position = UDim2.new(0.5, 0, 1, 0)
TimerContainer.Size = UDim2.new(1, 0, 1, 0)

local AspectRatio = Instance.new("UIAspectRatioConstraint")
AspectRatio.Parent = TimerContainer

local RoundTimerFrame = Instance.new("Frame")
RoundTimerFrame.Name = "RoundTimer"
RoundTimerFrame.Parent = TimerContainer
RoundTimerFrame.AnchorPoint = Vector2.new(0.5, 0)
RoundTimerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
RoundTimerFrame.BackgroundTransparency = 1
RoundTimerFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
RoundTimerFrame.BorderSizePixel = 0
RoundTimerFrame.Position = UDim2.new(0.5, 0, 0.02, 0)
RoundTimerFrame.Size = UDim2.new(0.2, 0, 0.08, 0)
RoundTimerFrame.ZIndex = 26

local InnerFrame = Instance.new("Frame")
InnerFrame.Name = "RoundTimer"
InnerFrame.Parent = RoundTimerFrame
InnerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
InnerFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
InnerFrame.BackgroundTransparency = 0.6
InnerFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
InnerFrame.BorderSizePixel = 0
InnerFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
InnerFrame.Size = UDim2.new(1, 0, 1, 0)

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 8)
FrameCorner.Parent = InnerFrame

TimerLabel = Instance.new("TextLabel")
TimerLabel.Name = "Timer"
TimerLabel.Parent = InnerFrame
TimerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
TimerLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TimerLabel.BackgroundTransparency = 1
TimerLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
TimerLabel.Position = UDim2.new(0.5, 0, 0.65, 0)
TimerLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
TimerLabel.ZIndex = 3
TimerLabel.Font = Enum.Font.GothamBold
TimerLabel.Text = "0:00"
TimerLabel.TextColor3 = Color3.fromRGB(165, 194, 255)
TimerLabel.TextScaled = true
TimerLabel.TextSize = 14
TimerLabel.TextStrokeTransparency = 0.95
TimerLabel.TextWrapped = true

StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "About"
StatusLabel.Parent = InnerFrame
StatusLabel.AnchorPoint = Vector2.new(0.5, 0.5)
StatusLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
StatusLabel.BackgroundTransparency = 1
StatusLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
StatusLabel.Position = UDim2.new(0.5, 0, 0.25, 0)
StatusLabel.Size = UDim2.new(0.8, 0, 0.25, 0)
StatusLabel.ZIndex = 3
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Text = "INTERMISSION"
StatusLabel.TextColor3 = Color3.fromRGB(165, 194, 255)
StatusLabel.TextScaled = true
StatusLabel.TextSize = 14
StatusLabel.TextStrokeTransparency = 0.95
StatusLabel.TextWrapped = true

local Background = Instance.new("ImageLabel")
Background.Name = "Background"
Background.Parent = InnerFrame
Background.AnchorPoint = Vector2.new(0.5, 0.5)
Background.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Background.BackgroundTransparency = 1
Background.BorderColor3 = Color3.fromRGB(27, 42, 53)
Background.Position = UDim2.new(0.5, 0, 0.5, 0)
Background.Size = UDim2.new(1, 0, 1, 0)
Background.ZIndex = 0
Background.Image = "rbxassetid://196969716"
Background.ImageColor3 = Color3.fromRGB(21, 21, 21)
Background.ImageTransparency = 0.7

local BackgroundCorner = Instance.new("UICorner")
BackgroundCorner.CornerRadius = UDim.new(0, 8)
BackgroundCorner.Parent = Background

local UIStroke = Instance.new("UIStroke")
UIStroke.Transparency = 0.8
UIStroke.Parent = InnerFrame

local OverlayImage = Instance.new("ImageLabel")
OverlayImage.Parent = InnerFrame
OverlayImage.AnchorPoint = Vector2.new(0.5, 0.5)
OverlayImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
OverlayImage.BackgroundTransparency = 1
OverlayImage.BorderColor3 = Color3.fromRGB(27, 42, 53)
OverlayImage.Position = UDim2.new(0.5, 0, 0.5, 0)
OverlayImage.Size = UDim2.new(0.8, 0, 1, 0)
OverlayImage.ZIndex = 2
OverlayImage.Image = "rbxassetid://6761866149"
OverlayImage.ImageColor3 = Color3.fromRGB(165, 194, 255)
OverlayImage.ImageTransparency = 0.9
OverlayImage.ScaleType = Enum.ScaleType.Crop

local OverlayCorner = Instance.new("UICorner")
OverlayCorner.CornerRadius = UDim.new(0, 4)
OverlayCorner.Parent = OverlayImage
end

local isTimerEnabled = false
local activeConnections = {}
local folderAddedConnection
local spectateMonitorConnection

function formatTime(seconds)
if not seconds then return "0:00" end

seconds = math.floor(tonumber(seconds) or 0)
local minutes = math.floor(seconds / 60)
local remainingSeconds = seconds % 60

return string.format("%d:%02d", minutes, remainingSeconds)
end

function checkSpectateVisibility()
local Menu = PlayerGui:FindFirstChild("Menu")
if Menu then
local Spectate = Menu:FindFirstChild("Spectate")
if Spectate and Spectate.Visible then
return true
end
end
return false
end

function updateTimerDisplay()
if checkSpectateVisibility() then
TimerContainer.Visible = false
return
end

if not isTimerEnabled then
TimerContainer.Visible = false
return
end

local gameFolder = Workspace:FindFirstChild("Game")
if not gameFolder then
TimerContainer.Visible = false
return
end

local statsFolder = gameFolder:FindFirstChild("Stats")
if not statsFolder then
TimerContainer.Visible = false
return
end

TimerContainer.Visible = true

local timeRemaining = statsFolder:GetAttribute("TimeRemaining") or statsFolder:GetAttribute("Timer")
local roundStarted = statsFolder:GetAttribute("RoundStarted")
local ready = statsFolder:GetAttribute("Ready")

if timeRemaining then
TimerLabel.Text = formatTime(timeRemaining)

if timeRemaining <= 5 then
TimerLabel.TextColor3 = Color3.fromRGB(215, 100, 100)
StatusLabel.TextColor3 = Color3.fromRGB(215, 100, 100)
else
TimerLabel.TextColor3 = Color3.fromRGB(165, 194, 255)
StatusLabel.TextColor3 = Color3.fromRGB(165, 194, 255)
end
end

if roundStarted == true then
StatusLabel.Text = "ROUND ACTIVE"
elseif ready == true then
StatusLabel.Text = "INTERMISSION"
else
StatusLabel.Text = "ROUND INACTIVE"
end
end

function setupTimerConnection()
for _, connection in pairs(activeConnections) do
connection:Disconnect()
end
activeConnections = {}

local gameFolder = Workspace:FindFirstChild("Game")
if not gameFolder then return end

local statsFolder = gameFolder:FindFirstChild("Stats")
if not statsFolder then return end

table.insert(activeConnections, statsFolder:GetAttributeChangedSignal("TimeRemaining"):Connect(updateTimerDisplay))
table.insert(activeConnections, statsFolder:GetAttributeChangedSignal("Timer"):Connect(updateTimerDisplay))
table.insert(activeConnections, statsFolder:GetAttributeChangedSignal("RoundStarted"):Connect(updateTimerDisplay))
table.insert(activeConnections, statsFolder:GetAttributeChangedSignal("Ready"):Connect(updateTimerDisplay))

updateTimerDisplay()
end

function cleanupTimer()
for _, connection in pairs(activeConnections) do
connection:Disconnect()
end
activeConnections = {}

if folderAddedConnection then
folderAddedConnection:Disconnect()
folderAddedConnection = nil
end

if spectateMonitorConnection then
spectateMonitorConnection:Disconnect()
spectateMonitorConnection = nil
end
end

function monitorSpectateVisibility()
local Menu = PlayerGui:FindFirstChild("Menu")
if Menu then
local Spectate = Menu:FindFirstChild("Spectate")
if Spectate then
spectateMonitorConnection = Spectate:GetPropertyChangedSignal("Visible"):Connect(function()
updateTimerDisplay()
end)
end
end
end

folderAddedConnection = Workspace.ChildAdded:Connect(function(child)
if child.Name == "Game" then
if isTimerEnabled then
setupTimerConnection()
end
end
end)

local statsMonitorConnection
statsMonitorConnection = Workspace.DescendantAdded:Connect(function(descendant)
if descendant.Name == "Stats" and descendant.Parent and descendant.Parent.Name == "Game" then
if isTimerEnabled then
setupTimerConnection()
end
end
end)

if Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Stats") then
setupTimerConnection()
end

monitorSpectateVisibility()

TimerDisplayToggle = Tabs.Visuals:Toggle({
Title = "Timer Display",
Flag = "TimerDisplayToggle",
Value = false,
Callback = function(state)
isTimerEnabled = state

if state then
if Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Stats") then
setupTimerConnection()
end
updateTimerDisplay()
else
TimerContainer.Visible = false
cleanupTimer()
end
end
})

local lastUpdateTime = 0

local updateLoop = RunService.Heartbeat:Connect(function()
if not isTimerEnabled then return end

local currentTime = tick()
if currentTime - lastUpdateTime > 0.5 then
lastUpdateTime = currentTime
pcall(updateTimerDisplay)
end
end)

LocalPlayer.AncestryChanged:Connect(function()
cleanupTimer()
if statsMonitorConnection then
statsMonitorConnection:Disconnect()
end
if updateLoop then
updateLoop:Disconnect()
end
end)
Tabs.Visuals:Section({ Title = "FE ANIM Emote Changer", TextSize = 20 })
Tabs.Visuals:Divider()

originalEmotes = {}
for i = 1, 8 do
originalEmotes[i] = LocalPlayer:GetAttribute("Emote" .. i) or ""
end

hookInstalled = false
blockRemote = false
emoteSpeedConnection = nil
tpcameraConnection = nil
emotingAttributeConnection = nil
pendingEmoteChanges = {}
emoteSpeedCache = {}
validEmotes = {}

function ScanValidEmotes()
local emotes = {}

if ReplicatedStorage then
local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
if itemsFolder then
local emotesFolder = itemsFolder:FindFirstChild("Emotes")
if emotesFolder then
for _, item in pairs(emotesFolder:GetChildren()) do
if item:IsA("ModuleScript") then
emotes[item.Name] = true
end
end
end
end
end

return emotes
end

validEmotes = ScanValidEmotes()

function IsValidEmote(emoteName)
if not emoteName or emoteName == "" then return false end
return validEmotes[emoteName] == true
end

function GetPlayerTagData()
local character = LocalPlayer.Character

if character then
return character:GetAttribute("Tag")
end

return nil
end

function TriggerTagEmote(emoteSlot)
if not blockRemote then return end

local emoteName = pendingEmoteChanges[emoteSlot] or LocalPlayer:GetAttribute("Emote" .. emoteSlot)
if not emoteName or emoteName == "" then return end

if not IsValidEmote(emoteName) then return end

local tagData = GetPlayerTagData()
if not tagData then return end

local characterEvent = ReplicatedStorage.Events.Character.Emote
firesignal(characterEvent.OnClientEvent, tagData, emoteName)
end

function GetEmoteSpeedFromModule(emoteName)
if not IsValidEmote(emoteName) then return 1 end

if emoteSpeedCache[emoteName] then
return emoteSpeedCache[emoteName]
end

if not ReplicatedStorage then return 1 end

local itemsFolder = ReplicatedStorage:FindFirstChild("Items")
if not itemsFolder then return 1 end

local emotesFolder = itemsFolder:FindFirstChild("Emotes")
if not emotesFolder then return 1 end

local emoteModule = emotesFolder:FindFirstChild(emoteName)
if not emoteModule or not emoteModule:IsA("ModuleScript") then return 1 end

local success, emoteData = pcall(require, emoteModule)
if not success or not emoteData then return 1 end

local speedMult = emoteData.SpeedMult or emoteData.EmoteInfo and emoteData.EmoteInfo.SpeedMult or 1
emoteSpeedCache[emoteName] = speedMult
return speedMult
end

function SetupEmoteSpeedChange(apply)
if emoteSpeedConnection then
emoteSpeedConnection:Disconnect()
emoteSpeedConnection = nil
end

local playerModel = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")
if playerModel then
local localPlayerModel = playerModel:FindFirstChild(LocalPlayer.Name)
if localPlayerModel then
local isEmoting = localPlayerModel:GetAttribute("Emoting")

if isEmoting == true then
local emoteName = nil
for i = 1, 8 do
local currentEmote = LocalPlayer:GetAttribute("Emote" .. i)
if currentEmote and currentEmote ~= "" and IsValidEmote(currentEmote) then
emoteName = currentEmote
break
end
end

if emoteName then
local speedMult = GetEmoteSpeedFromModule(emoteName)
local statChanges = localPlayerModel:FindFirstChild("StatChanges")
if statChanges then
local speed = statChanges:FindFirstChild("Speed")
if speed then
local emoteSpeed = speed:FindFirstChild("EmoteSpeed")

if apply then
if emoteSpeed then
emoteSpeed.Value = speedMult
else
emoteSpeed = Instance.new("NumberValue")
emoteSpeed.Name = "EmoteSpeed"
emoteSpeed.Value = speedMult
emoteSpeed.Parent = speed
end
else
if emoteSpeed then
emoteSpeed:Destroy()
end
end
end
end
end
else
local statChanges = localPlayerModel:FindFirstChild("StatChanges")
if statChanges then
local speed = statChanges:FindFirstChild("Speed")
if speed then
local emoteSpeed = speed:FindFirstChild("EmoteSpeed")
if emoteSpeed then
emoteSpeed:Destroy()
end
end
end
end

if apply then
emoteSpeedConnection = localPlayerModel:GetAttributeChangedSignal("Emoting"):Connect(function()
local newIsEmoting = localPlayerModel:GetAttribute("Emoting")
local statChanges = localPlayerModel:FindFirstChild("StatChanges")

if statChanges then
local speed = statChanges:FindFirstChild("Speed")
if speed then
local emoteSpeed = speed:FindFirstChild("EmoteSpeed")

if newIsEmoting == true then
local emoteName = nil
for i = 1, 8 do
local currentEmote = LocalPlayer:GetAttribute("Emote" .. i)
if currentEmote and currentEmote ~= "" and IsValidEmote(currentEmote) then
emoteName = currentEmote
break
end
end

if emoteName then
local speedMult = GetEmoteSpeedFromModule(emoteName)
if not emoteSpeed then
emoteSpeed = Instance.new("NumberValue")
emoteSpeed.Name = "EmoteSpeed"
emoteSpeed.Value = speedMult
emoteSpeed.Parent = speed
else
emoteSpeed.Value = speedMult
end
end
else
if emoteSpeed then
emoteSpeed:Destroy()
end
end
end
end
end)
end
end
end
end

function SetupTPCameraOnEmoting(apply)
if tpcameraConnection then
tpcameraConnection:Disconnect()
tpcameraConnection = nil
end

if emotingAttributeConnection then
emotingAttributeConnection:Disconnect()
emotingAttributeConnection = nil
end

if apply then
local playerModel = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")
if playerModel then
local localPlayerModel = playerModel:FindFirstChild(LocalPlayer.Name)
if localPlayerModel then
emotingAttributeConnection = localPlayerModel:GetAttributeChangedSignal("Emoting"):Connect(function()
local isEmoting = localPlayerModel:GetAttribute("Emoting")
if isEmoting == true then
local Event = LocalPlayer.Character.Client
firesignal(Event.OnClientEvent, "TPCamera", {Zoom = 10})
end
end)
end
end
end
end

function InstallHook()
local Event = ReplicatedStorage.Events.Emote

if hookInstalled then return end

local success, errorMsg = pcall(function()
local mt = getrawmetatable(Event)
if mt and mt.__namecall then
local oldNamecall = mt.__namecall

setreadonly(mt, false)

mt.__namecall = function(self, ...)
local method = getnamecallmethod()
if method == "FireServer" then
local args = {...}
local emoteNum = tostring(args[1])
if blockRemote and emoteNum:match("^[1-8]$") then
TriggerTagEmote(tonumber(emoteNum))
return
end
end
return oldNamecall(self, ...)
end

setreadonly(mt, true)
hookInstalled = true
WindUI:Notify({
Title = "Hook Status",
Content = "Emote hook installed successfully",
Duration = 3
})
else
WindUI:Notify({
Title = "Hook Status",
Content = "Could not get metatable, using fallback",
Duration = 3
})
end
end)

if not success then
WindUI:Notify({
Title = "Hook Error",
Content = "Failed to install hook: " .. tostring(errorMsg),
Duration = 3
})
end

if not hookInstalled then
WindUI:Notify({
Title = "Hook Status",
Content = "Using fallback method",
Duration = 3
})
end
end

emoteInputs = {}

for i = 1, 8 do
currentEmote = LocalPlayer:GetAttribute("Emote" .. i) or ""

emoteInputs[i] = Tabs.Visuals:Input({
Title = "Emote Slot " .. i,
Flag = "EmoteSlot" .. i,
Desc = "Current: " .. currentEmote,
Placeholder = "Enter emote name (e.g., Wave, Dab, etc.)",
Value = currentEmote,
Callback = function(value)
pendingEmoteChanges[i] = value
if value and value ~= "" then
if IsValidEmote(value) then
emoteInputs[i].Desc = "Pending (valid): " .. value
else
emoteInputs[i].Desc = "Pending (INVALID - will be ignored): " .. value
end
else
emoteInputs[i].Desc = "Pending: Not set"
end
end
})
end

Tabs.Visuals:Space()

Tabs.Visuals:Button({
Title = "Apply All Emotes",
Desc = "Apply current emote settings (invalid emotes will be ignored)",
Callback = function()
blockRemote = true
local appliedCount = 0
local invalidCount = 0

local success, errorMsg = pcall(function()
for i = 1, 8 do
if pendingEmoteChanges[i] and pendingEmoteChanges[i] ~= "" then
if IsValidEmote(pendingEmoteChanges[i]) then
LocalPlayer:SetAttribute("Emote" .. i, pendingEmoteChanges[i])
emoteInputs[i].Desc = "Applied (valid): " .. pendingEmoteChanges[i]
appliedCount = appliedCount + 1
else
invalidCount = invalidCount + 1
emoteInputs[i].Desc = "Invalid emote (ignored): " .. pendingEmoteChanges[i]
end
end
end
pendingEmoteChanges = {}
SetupEmoteSpeedChange(true)
SetupTPCameraOnEmoting(true)
InstallHook()
end)

if success then
local notifyMessage = "Applied " .. appliedCount .. " valid emotes"
if invalidCount > 0 then
notifyMessage = notifyMessage .. " (ignored " .. invalidCount .. " invalid)"
end

WindUI:Notify({
Title = "Emotes Applied",
Content = notifyMessage,
Duration = 3
})
else
WindUI:Notify({
Title = "Apply Error",
Content = "Failed to apply emotes: " .. tostring(errorMsg),
Duration = 3
})
end
end
})

Tabs.Visuals:Button({
Title = "Reset All Emotes",
Desc = "Restore original emote state",
Callback = function()
blockRemote = false
local success, errorMsg = pcall(function()
SetupEmoteSpeedChange(false)
SetupTPCameraOnEmoting(false)
pendingEmoteChanges = {}
for i = 1, 8 do
LocalPlayer:SetAttribute("Emote" .. i, originalEmotes[i])
emoteInputs[i]:Set(originalEmotes[i] or "")
emoteInputs[i].Desc = "Current: " .. (originalEmotes[i] or "Not set")
end
end)

if success then
WindUI:Notify({
Title = "Emotes Reset",
Content = "All emotes restored to original",
Duration = 3
})
else
WindUI:Notify({
Title = "Reset Error",
Content = "Failed to reset emotes: " .. tostring(errorMsg),
Duration = 3
})
end
end
})

LocalPlayer.CharacterAdded:Connect(function()
task.wait(1)

if blockRemote then
local success = pcall(function()
SetupEmoteSpeedChange(true)
SetupTPCameraOnEmoting(true)
end)
end
end)

if LocalPlayer.Character then
if blockRemote then
task.wait(1)
local success = pcall(function()
SetupEmoteSpeedChange(true)
SetupTPCameraOnEmoting(true)
end)
end
end

InstallHook()

ReplicatedStorage.ChildAdded:Connect(function()
task.wait(1)
validEmotes = ScanValidEmotes()
end)

if not LocalPlayer:FindFirstChild("Cosmetics") then
LocalPlayer.Cosmetics = Instance.new("Folder")
end
if not LocalPlayer.Cosmetics:FindFirstChild("Equipped") then
LocalPlayer.Cosmetics.Equipped = Instance.new("Folder")
end

CosmeticsFolder = ReplicatedStorage:FindFirstChild("Items") and ReplicatedStorage.Items:FindFirstChild("Cosmetics")

ScriptAddedCosmetics = {}

function isValidCosmetic(cosmeticName)
return CosmeticsFolder and CosmeticsFolder:FindFirstChild(cosmeticName) ~= nil
end

function isCosmeticEquipped(cosmeticName)
return LocalPlayer.Cosmetics:GetAttribute(cosmeticName) ~= nil
end

Tabs.Visuals:Section({ Title = "Cosmetics Spawner", TextSize = 20 })
Tabs.Visuals:Divider()

Tabs.Visuals:Paragraph({
Title = "Head's up! This Feature may broken, in able to solve bugs or glitches you may have to rejoin.",
TextSize = 14
})

CosmeticNameInput = Tabs.Visuals:Input({
Title = "Cosmetic Name",
Placeholder = "Exact name from ReplicatedStorage",
Callback = function(inputText)
CosmeticNameInput.currentValue = inputText
end
})

Tabs.Visuals:Button({
Title = "Add Cosmetic",
Icon = "plus-circle",
Callback = function()
name = CosmeticNameInput.currentValue
if not name or name == "" then
WindUI:Notify({ Title = "Error", Content = "Name is empty!", Duration = 3 })
return
end
if not isValidCosmetic(name) then
WindUI:Notify({ Title = "Invalid", Content = "'" .. name .. "' not found!", Duration = 3 })
return
end
if isCosmeticEquipped(name) then
WindUI:Notify({ Title = "Duplicate", Content = "'" .. name .. "' is already equipped!", Duration = 3 })
return
end
LocalPlayer.Cosmetics:SetAttribute(name, name)
LocalPlayer.Cosmetics.Equipped:SetAttribute(name, name)
table.insert(ScriptAddedCosmetics, name)
WindUI:Notify({ Title = "Success", Content = "Equipped: " .. name, Duration = 3 })
end
})

Tabs.Visuals:Button({
Title = "Remove Cosmetic",
Icon = "minus-circle",
Callback = function()
name = CosmeticNameInput.currentValue
if not name or name == "" then
WindUI:Notify({ Title = "Error", Content = "Name is empty!", Duration = 3 })
return
end
if not isCosmeticEquipped(name) then
WindUI:Notify({ Title = "Not Found", Content = "'" .. name .. "' isn't equipped!", Duration = 3 })
return
end
LocalPlayer.Cosmetics:SetAttribute(name, nil)
LocalPlayer.Cosmetics.Equipped:SetAttribute(name, nil)
for i = #ScriptAddedCosmetics, 1, -1 do
if ScriptAddedCosmetics[i] == name then
table.remove(ScriptAddedCosmetics, i)
end
end
WindUI:Notify({ Title = "Removed", Content = "Unequipped: " .. name, Duration = 3 })
end
})

Tabs.Visuals:Button({
Title = "Reset Script Cosmetics",
Icon = "rotate-ccw",
Color = Color3.fromRGB(255, 165, 0),
Callback = function()
for _, name in ipairs(ScriptAddedCosmetics) do
LocalPlayer.Cosmetics:SetAttribute(name, nil)
LocalPlayer.Cosmetics.Equipped:SetAttribute(name, nil)
end
ScriptAddedCosmetics = {}
WindUI:Notify({ Title = "Reset", Content = "All script-added cosmetics cleared.", Duration = 3 })
end
})
Tabs.Visuals:Section({ Title = "Cosmetics Changer", TextSize = 20 })
Tabs.Visuals:Divider()

local cosmetic1, cosmetic2 = ""
local originalCosmetic1, originalCosmetic2 = "", ""
local isSwapped = false

Tabs.Visuals:Input({
Title = "Current Cosmetics",
Placeholder = "",
Callback = function(v)
cosmetic1 = v
if not isSwapped then
originalCosmetic1 = v
end
end
})

Tabs.Visuals:Input({
Title = "Select Cosmetics",
Placeholder = "",
Callback = function(v)
cosmetic2 = v
if not isSwapped then
originalCosmetic2 = v
end
end
})

Tabs.Visuals:Button({
Title = "Apply Cosmetics",
Callback = function()
pcall(function()
if cosmetic1 == "" or cosmetic2 == "" or cosmetic1 == cosmetic2 then return end

local Cosmetics = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Cosmetics")

function normalize(str)
return str:gsub("%s+", ""):lower()
end

function levenshtein(s, t)
local m, n = #s, #t
local d = {}
for i = 0, m do d[i] = {[0] = i} end
for j = 0, n do d[0][j] = j end

for i = 1, m do
for j = 1, n do
local cost = (s:sub(i,i) == t:sub(j,j)) and 0 or 1
d[i][j] = math.min(
d[i-1][j] + 1,
d[i][j-1] + 1,
d[i-1][j-1] + cost
)
end
end
return d[m][n]
end

function similarity(s, t)
local nS, nT = normalize(s), normalize(t)
local dist = levenshtein(nS, nT)
return 1 - dist / math.max(#nS, #nT)
end

function findSimilar(name)
local bestMatch = name
local bestScore = 0.5
for _, c in ipairs(Cosmetics:GetChildren()) do
local score = similarity(name, c.Name)
if score > bestScore then
bestScore = score
bestMatch = c.Name
end
end
return bestMatch
end

cosmetic1 = findSimilar(cosmetic1)
cosmetic2 = findSimilar(cosmetic2)

local a = Cosmetics:FindFirstChild(cosmetic1)
local b = Cosmetics:FindFirstChild(cosmetic2)
if not a or not b then return end

if not isSwapped then
originalCosmetic1 = cosmetic1
originalCosmetic2 = cosmetic2
end

local tempRoot = Instance.new("Folder", Cosmetics)
tempRoot.Name = "__temp_swap_" .. tostring(tick()):gsub("%.", "_")

local tempA = Instance.new("Folder", tempRoot)
local tempB = Instance.new("Folder", tempRoot)

for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end

for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end

tempRoot:Destroy()

isSwapped = true

WindUI:Notify({
Title = "Cosmetics Changer",
Content = "Successfully swapped " .. cosmetic1 .. " with " .. cosmetic2,
Duration = 3
})
end)
end
})

Tabs.Visuals:Button({
Title = "Reset Cosmetics",
Desc = "Restore cosmetics to their original state",
Callback = function()
pcall(function()
if not isSwapped then
WindUI:Notify({
Title = "Cosmetics Changer",
Content = "No cosmetics have been swapped yet",
Duration = 3
})
return
end

if originalCosmetic1 == "" or originalCosmetic2 == "" then
WindUI:Notify({
Title = "Cosmetics Changer",
Content = "Original cosmetic names not found",
Duration = 3
})
return
end

local Cosmetics = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Cosmetics")

function normalize(str)
return str:gsub("%s+", ""):lower()
end

function findSimilar(name)
local bestMatch = name
local bestScore = 0.5
for _, c in ipairs(Cosmetics:GetChildren()) do
local normalizedInput = normalize(name)
local normalizedCosmetic = normalize(c.Name)
if normalizedInput == normalizedCosmetic then
return c.Name
end
end
return name
end

local resetCosmetic1 = findSimilar(originalCosmetic1)
local resetCosmetic2 = findSimilar(originalCosmetic2)

local a = Cosmetics:FindFirstChild(cosmetic1)
local b = Cosmetics:FindFirstChild(cosmetic2)

if a and b then
local tempRoot = Instance.new("Folder", Cosmetics)
tempRoot.Name = "__temp_reset_" .. tostring(tick()):gsub("%.", "_")

local tempA = Instance.new("Folder", tempRoot)
local tempB = Instance.new("Folder", tempRoot)

for _, c in ipairs(a:GetChildren()) do c.Parent = tempA end
for _, c in ipairs(b:GetChildren()) do c.Parent = tempB end

for _, c in ipairs(tempA:GetChildren()) do c.Parent = b end
for _, c in ipairs(tempB:GetChildren()) do c.Parent = a end

tempRoot:Destroy()

isSwapped = false

WindUI:Notify({
Title = "Cosmetics Changer",
Content = "Successfully reset cosmetics to original state",
Duration = 3
})
else
WindUI:Notify({
Title = "Cosmetics Changer",
Content = "Could not find swapped cosmetics to reset",
Duration = 3
})
end
end)
end
})
currentCarryAnim = ""
selectedCarryAnim = ""
lastCurrentCarryAnim = ""
lastSelectedCarryAnim = ""
isSwapped = false

currentPerk = ""
selectedPerk = ""
lastCurrentPerk = ""
lastSelectedPerk = ""
isPerkSwapped = false

currentPerk2 = ""
selectedPerk2 = ""
lastCurrentPerk2 = ""
lastSelectedPerk2 = ""
isPerkSwapped2 = false

currentTool = ""
currentSkin = ""
selectedSkin = ""
lastCurrentTool = ""
lastCurrentSkin = ""
lastSelectedSkin = ""
isSkinSwapped = false

function normalizeString(str)
return str:gsub("%s+", ""):lower()
end

function isValidCarryAnimation(name)
carryAnimations = ReplicatedStorage:FindFirstChild("Items")
if not carryAnimations then return false end
carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
if not carryAnimations then return false end

normalizedInput = normalizeString(name)
for _, anim in ipairs(carryAnimations:GetChildren()) do
if normalizeString(anim.Name) == normalizedInput then
return true, anim.Name
end
end
return false
end

function revertPreviousSwap()
if lastCurrentCarryAnim ~= "" and lastSelectedCarryAnim ~= "" and isSwapped then
carryAnimations = ReplicatedStorage:FindFirstChild("Items")
if carryAnimations then
carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
if carryAnimations then
lastCurrentValid, lastCurrentActual = isValidCarryAnimation(lastCurrentCarryAnim)
lastSelectedValid, lastSelectedActual = isValidCarryAnimation(lastSelectedCarryAnim)

if lastCurrentValid and lastSelectedValid then
pcall(function()
currentFolder = carryAnimations:FindFirstChild(lastCurrentActual)
selectedFolder = carryAnimations:FindFirstChild(lastSelectedActual)

if currentFolder and selectedFolder then
tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_revert_swap_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = carryAnimations

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()
end
end)
end
end
end
isSwapped = false
end
end

function swapCarryAnimations(current, selected)
revertPreviousSwap()

currentNorm = normalizeString(current)
selectedNorm = normalizeString(selected)

if currentNorm == "" or selectedNorm == "" then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "Both animation names must be filled",
Duration = 3
})
return
end

if currentNorm == selectedNorm then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "Animation names cannot be the same",
Duration = 3
})
return
end

carryAnimations = ReplicatedStorage:FindFirstChild("Items")
if not carryAnimations then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "CarryAnimations folder not found",
Duration = 3
})
return
end

carryAnimations = carryAnimations:FindFirstChild("CarryAnimations")
if not carryAnimations then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "CarryAnimations folder not found",
Duration = 3
})
return
end

currentAnim, currentActualName = isValidCarryAnimation(current)
selectedAnim, selectedActualName = isValidCarryAnimation(selected)

if not currentAnim then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "Current animation not found: " .. current,
Duration = 3
})
return
end

if not selectedAnim then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "Selected animation not found: " .. selected,
Duration = 3
})
return
end

pcall(function()
currentFolder = carryAnimations:FindFirstChild(currentActualName)
selectedFolder = carryAnimations:FindFirstChild(selectedActualName)

if not currentFolder or not selectedFolder then
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "One or both animations not found in folder",
Duration = 3
})
return
end

tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_carry_swap_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = carryAnimations

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()

lastCurrentCarryAnim = current
lastSelectedCarryAnim = selected
isSwapped = true

WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "Successfully swapped " .. currentActualName .. " with " .. selectedActualName,
Duration = 3
})
end)
end

function isValidPerk(name)
perks = ReplicatedStorage:FindFirstChild("Items")
if not perks then return false end
perks = perks:FindFirstChild("Perks")
if not perks then return false end

normalizedInput = normalizeString(name)
for _, perk in ipairs(perks:GetChildren()) do
if normalizeString(perk.Name) == normalizedInput then
return true, perk.Name
end
end
return false
end

function revertPreviousPerkSwap()
if lastCurrentPerk ~= "" and lastSelectedPerk ~= "" and isPerkSwapped then
perks = ReplicatedStorage:FindFirstChild("Items")
if perks then
perks = perks:FindFirstChild("Perks")
if perks then
lastCurrentValid, lastCurrentActual = isValidPerk(lastCurrentPerk)
lastSelectedValid, lastSelectedActual = isValidPerk(lastSelectedPerk)

if lastCurrentValid and lastSelectedValid then
pcall(function()
currentFolder = perks:FindFirstChild(lastCurrentActual)
selectedFolder = perks:FindFirstChild(lastSelectedActual)

if currentFolder and selectedFolder then
tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_perk_revert_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = perks

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()
end
end)
end
end
end
isPerkSwapped = false
end
end

function swapPerks(current, selected)
revertPreviousPerkSwap()

currentNorm = normalizeString(current)
selectedNorm = normalizeString(selected)

if currentNorm == "" or selectedNorm == "" then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Both perk names must be filled",
Duration = 3
})
return
end

if currentNorm == selectedNorm then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Perk names cannot be the same",
Duration = 3
})
return
end

perks = ReplicatedStorage:FindFirstChild("Items")
if not perks then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Perks folder not found",
Duration = 3
})
return
end

perks = perks:FindFirstChild("Perks")
if not perks then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Perks folder not found",
Duration = 3
})
return
end

currentPerkValid, currentActualName = isValidPerk(current)
selectedPerkValid, selectedActualName = isValidPerk(selected)

if not currentPerkValid then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Current perk not found: " .. current,
Duration = 3
})
return
end

if not selectedPerkValid then
WindUI:Notify({
Title = "Perk Replacer",
Content = "Selected perk not found: " .. selected,
Duration = 3
})
return
end

pcall(function()
currentFolder = perks:FindFirstChild(currentActualName)
selectedFolder = perks:FindFirstChild(selectedActualName)

if not currentFolder or not selectedFolder then
WindUI:Notify({
Title = "Perk Replacer",
Content = "One or both perks not found in folder",
Duration = 3
})
return
end

tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_perk_swap_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = perks

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()

lastCurrentPerk = current
lastSelectedPerk = selected
isPerkSwapped = true

WindUI:Notify({
Title = "Perk Replacer",
Content = "Successfully swapped " .. currentActualName .. " with " .. selectedActualName,
Duration = 3
})
end)
end

function revertPreviousPerkSwap2()
if lastCurrentPerk2 ~= "" and lastSelectedPerk2 ~= "" and isPerkSwapped2 then
perks = ReplicatedStorage:FindFirstChild("Items")
if perks then
perks = perks:FindFirstChild("Perks")
if perks then
lastCurrentValid, lastCurrentActual = isValidPerk(lastCurrentPerk2)
lastSelectedValid, lastSelectedActual = isValidPerk(lastSelectedPerk2)

if lastCurrentValid and lastSelectedValid then
pcall(function()
currentFolder = perks:FindFirstChild(lastCurrentActual)
selectedFolder = perks:FindFirstChild(lastSelectedActual)

if currentFolder and selectedFolder then
tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_perk_revert2_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = perks

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()
end
end)
end
end
end
isPerkSwapped2 = false
end
end

function swapPerks2(current, selected)
revertPreviousPerkSwap2()

currentNorm = normalizeString(current)
selectedNorm = normalizeString(selected)

if currentNorm == "" or selectedNorm == "" then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Both perk names must be filled",
Duration = 3
})
return
end

if currentNorm == selectedNorm then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Perk names cannot be the same",
Duration = 3
})
return
end

perks = ReplicatedStorage:FindFirstChild("Items")
if not perks then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Perks folder not found",
Duration = 3
})
return
end

perks = perks:FindFirstChild("Perks")
if not perks then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Perks folder not found",
Duration = 3
})
return
end

currentPerkValid, currentActualName = isValidPerk(current)
selectedPerkValid, selectedActualName = isValidPerk(selected)

if not currentPerkValid then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Current perk not found: " .. current,
Duration = 3
})
return
end

if not selectedPerkValid then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Selected perk not found: " .. selected,
Duration = 3
})
return
end

pcall(function()
currentFolder = perks:FindFirstChild(currentActualName)
selectedFolder = perks:FindFirstChild(selectedActualName)

if not currentFolder or not selectedFolder then
WindUI:Notify({
Title = "Perk Replacer 2",
Content = "One or both perks not found in folder",
Duration = 3
})
return
end

tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_perk_swap2_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = perks

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentFolder:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedFolder:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedFolder
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentFolder
end

tempRoot:Destroy()

lastCurrentPerk2 = current
lastSelectedPerk2 = selected
isPerkSwapped2 = true

WindUI:Notify({
Title = "Perk Replacer 2",
Content = "Successfully swapped " .. currentActualName .. " with " .. selectedActualName,
Duration = 3
})
end)
end

function isValidTool(toolName)
tools = ReplicatedStorage:FindFirstChild("Tools")
if not tools then return false end
tool = tools:FindFirstChild(toolName)
if not tool then return false end
variants = tool:FindFirstChild("Variants")
if not variants then return false end
return true, tool, variants
end

function isValidSkin(toolName, skinName)
toolValid, tool, variants = isValidTool(toolName)
if not toolValid then return false end
skin = variants:FindFirstChild(skinName)
if not skin then return false end
return true, tool, variants, skin
end

function revertPreviousSkinSwap()
if lastCurrentTool ~= "" and lastCurrentSkin ~= "" and lastSelectedSkin ~= "" and isSkinSwapped then
currentValid, currentTool, currentVariants, currentSkin = isValidSkin(lastCurrentTool, lastCurrentSkin)
selectedValid, selectedTool, selectedVariants, selectedSkin = isValidSkin(lastCurrentTool, lastSelectedSkin)

if currentValid and selectedValid then
pcall(function()
tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_skin_revert_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = currentVariants

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentSkin:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedSkin:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedSkin
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentSkin
end

tempRoot:Destroy()
end)
end
isSkinSwapped = false
end
end

function swapSkins(toolName, currentSkinName, selectedSkinName)
if currentTool ~= "" and currentTool ~= toolName then
revertPreviousSkinSwap()
end

currentNorm = normalizeString(currentSkinName)
selectedNorm = normalizeString(selectedSkinName)

if toolName == "" or currentNorm == "" or selectedNorm == "" then
WindUI:Notify({
Title = "Item Skin Changer",
Content = "All fields must be filled",
Duration = 3
})
return
end

if currentNorm == selectedNorm then
WindUI:Notify({
Title = "Item Skin Changer",
Content = "Skin names cannot be the same",
Duration = 3
})
return
end

currentValid, currentTool, currentVariants, currentSkin = isValidSkin(toolName, currentSkinName)
selectedValid, selectedTool, selectedVariants, selectedSkin = isValidSkin(toolName, selectedSkinName)

if not currentValid then
WindUI:Notify({
Title = "Item Skin Changer",
Content = "Current skin not found: " .. currentSkinName,
Duration = 3
})
return
end

if not selectedValid then
WindUI:Notify({
Title = "Item Skin Changer",
Content = "Selected skin not found: " .. selectedSkinName,
Duration = 3
})
return
end

pcall(function()
tempRoot = Instance.new("Folder")
tempRoot.Name = "__temp_skin_swap_" .. tostring(tick()):gsub("%.", "_")
tempRoot.Parent = currentVariants

tempCurrent = Instance.new("Folder")
tempCurrent.Name = "tempCurrent"
tempCurrent.Parent = tempRoot

tempSelected = Instance.new("Folder")
tempSelected.Name = "tempSelected"
tempSelected.Parent = tempRoot

for _, child in ipairs(currentSkin:GetChildren()) do
child.Parent = tempCurrent
end

for _, child in ipairs(selectedSkin:GetChildren()) do
child.Parent = tempSelected
end

for _, child in ipairs(tempCurrent:GetChildren()) do
child.Parent = selectedSkin
end

for _, child in ipairs(tempSelected:GetChildren()) do
child.Parent = currentSkin
end

tempRoot:Destroy()

lastCurrentTool = toolName
lastCurrentSkin = currentSkinName
lastSelectedSkin = selectedSkinName
isSkinSwapped = true

WindUI:Notify({
Title = "Item Skin Changer",
Content = "Successfully swapped " .. currentSkinName .. " with " .. selectedSkinName .. " for " .. toolName,
Duration = 3
})
end)
end

Tabs.Visuals:Section({ Title = "CarryAnimation Replacer", TextSize = 15 })
Tabs.Visuals:Divider()

Tabs.Visuals:Input({
Title = "Current CarryAnimation",
Placeholder = "Enter current carry animation name",
Callback = function(value)
if value ~= currentCarryAnim and currentCarryAnim ~= "" then
revertPreviousSwap()
end
currentCarryAnim = value
end
})

Tabs.Visuals:Input({
Title = "Selected CarryAnimation",
Placeholder = "Enter selected carry animation name",
Callback = function(value)
if value ~= selectedCarryAnim and selectedCarryAnim ~= "" then
revertPreviousSwap()
end
selectedCarryAnim = value
end
})

Tabs.Visuals:Button({
Title = "Apply CarryAnimation Swap",
Callback = function()
swapCarryAnimations(currentCarryAnim, selectedCarryAnim)
end
})

Tabs.Visuals:Button({
Title = "Reset All CarryAnimations",
Callback = function()
revertPreviousSwap()
currentCarryAnim = ""
selectedCarryAnim = ""
lastCurrentCarryAnim = ""
lastSelectedCarryAnim = ""
isSwapped = false
WindUI:Notify({
Title = "CarryAnimation Replacer",
Content = "All animations reset to original",
Duration = 3
})
end
})

Tabs.Visuals:Section({ Title = "Item Skin Changer", TextSize = 15 })
Tabs.Visuals:Divider()

Tabs.Visuals:Input({
Title = "Current Tool Name",
Placeholder = "Enter tool name",
Callback = function(value)
currentTool = value
end
})

Tabs.Visuals:Input({
Title = "Current Skin",
Placeholder = "Enter current skin name",
Callback = function(value)
currentSkin = value
end
})

Tabs.Visuals:Input({
Title = "Select Skin",
Placeholder = "Enter selected skin name",
Callback = function(value)
selectedSkin = value
end
})

Tabs.Visuals:Button({
Title = "Apply Skin",
Callback = function()
swapSkins(currentTool, currentSkin, selectedSkin)
end
})

Tabs.Visuals:Button({
Title = "Reset Tool",
Desc = "Not working? Try resetting tool",
Callback = function()
revertPreviousSkinSwap()
currentTool = ""
currentSkin = ""
selectedSkin = ""
lastCurrentTool = ""
lastCurrentSkin = ""
lastSelectedSkin = ""
isSkinSwapped = false
WindUI:Notify({
Title = "Item Skin Changer",
Content = "Tool skins reset to original",
Duration = 3
})
end
})
Tabs.Visuals:Space()
playerEspElements = {}
EnemyEspElements = {}
downedEspElements = {}

playerBoxesEnabled = false
playerNamesEnabled = false
playerDistanceEnabled = false
playerHighlightsEnabled = false
playerBoxType = "2D"

EnemyBoxesEnabled = false
EnemyNamesEnabled = false
EnemyDistanceEnabled = false
falseEnemyHighlightsEnabled = false
EnemyBoxType = "2D"

downedBoxesEnabled = false
downedNamesEnabled = false
downedDistanceEnabled = false
downedHighlightsEnabled = false
downedBoxType = "2D"

innocentBots = {}
isRendering = true
windowFocused = true

function isInnocentBot(modelName)
for _, name in ipairs(innocentBots) do
if modelName == name then
return true
end
end
return false
end

EnemyNames = {}
if ReplicatedStorage:FindFirstChild("NPCStorage") then
for _, NPCStorage in ipairs(ReplicatedStorage.NPCStorage:GetChildren()) do
table.insert(EnemyNames, NPCStorage.Name)
end
end

function isEnemyModel(model)
if not model or not model.Name then return false end
for _, name in ipairs(EnemyNames) do
if model.Name == name then return true end
end
return false
end

function isPlayerEnemy(player)
if not player or not player.Character then return false end
local team = player.Character:GetAttribute("Team")
if team == "Enemy" then
return true
end
return false
end

function getDistanceFromCamera(targetPosition)
local camera = Workspace.CurrentCamera
if not camera then return 0 end
return (targetPosition - camera.CFrame.Position).Magnitude
end

function calculateBoxScale(distance)
if distance <= 17 then
return 1
else
local scale = 17 / distance
return math.max(scale, 0.3)
end
end

function getPlayerTeam(player)
local character = player.Character
if character then
local team = character:GetAttribute("Team")
if team then
return team
end
end
return nil
end

function getAttachPoint(character)
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
return rootPart
end
return character
end

function create3DBox(character, color, size)
local rootPart = character:FindFirstChild("HumanoidRootPart")
if not rootPart then return nil end

local folderName = "ESP_3DBox"
local folder = character:FindFirstChild(folderName)
if folder then
folder:Destroy()
end

folder = Instance.new("Folder")
folder.Name = folderName
folder.Parent = character

size = size or Vector3.new(4, 5, 3)
local offsetX = size.X / 2
local offsetY = size.Y / 2
local offsetZ = size.Z / 2

local edges = {
{Vector3.new(0, offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopFront"},
{Vector3.new(0, offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopBack"},
{Vector3.new(-offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopLeft"},
{Vector3.new(offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopRight"},
{Vector3.new(0, -offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomFront"},
{Vector3.new(0, -offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomBack"},
{Vector3.new(-offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomLeft"},
{Vector3.new(offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomRight"},
{Vector3.new(-offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontLeft"},
{Vector3.new(offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontRight"},
{Vector3.new(-offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackLeft"},
{Vector3.new(offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackRight"}
}

for _, edge in ipairs(edges) do
local position = edge[1]
local boxSize = edge[2]
local name = edge[3]

local adornment = Instance.new("BoxHandleAdornment")
adornment.Name = name
adornment.Adornee = rootPart
adornment.Size = boxSize
adornment.CFrame = CFrame.new(position)
adornment.Color3 = color
adornment.Transparency = 0.2
adornment.ZIndex = 10
adornment.AlwaysOnTop = true
adornment.Visible = true
adornment.Parent = folder
end

return folder
end

function update3DBoxColor(character, color)
local folder = character:FindFirstChild("ESP_3DBox")
if folder then
for _, adornment in ipairs(folder:GetChildren()) do
if adornment:IsA("BoxHandleAdornment") then
adornment.Color3 = color
end
end
end
end

function remove3DBox(character)
local folder = character:FindFirstChild("ESP_3DBox")
if folder then
folder:Destroy()
end
end

function createBillboard(character, name, color, useModelParent)
local existing = character:FindFirstChild("ESP_Billboard")
if existing then
existing:Destroy()
end

local billboard = Instance.new("BillboardGui")
billboard.Name = "ESP_Billboard"

if useModelParent then
billboard.Adornee = character
billboard.Parent = character
else
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
billboard.Adornee = rootPart
billboard.Parent = rootPart
else
billboard.Adornee = character
billboard.Parent = character
end
end

billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 50)
billboard.StudsOffset = Vector3.new(0, 3, 0)
billboard.ClipsDescendants = false
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Active = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = billboard

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(1, 0, 0, 20)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = name
nameLabel.TextColor3 = color
nameLabel.TextSize = 14
nameLabel.Font = Enum.Font.GothamSemibold
nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
nameLabel.TextStrokeTransparency = 0.3
nameLabel.TextXAlignment = Enum.TextXAlignment.Center
nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
nameLabel.Parent = mainFrame

local distanceLabel = Instance.new("TextLabel")
distanceLabel.Name = "DistanceLabel"
distanceLabel.Size = UDim2.new(1, 0, 0, 16)
distanceLabel.Position = UDim2.new(0, 0, 0, 20)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = ""
distanceLabel.TextColor3 = color
distanceLabel.TextSize = 12
distanceLabel.Font = Enum.Font.Gotham
distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
distanceLabel.TextStrokeTransparency = 0.3
distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
distanceLabel.TextYAlignment = Enum.TextYAlignment.Top
distanceLabel.Parent = mainFrame

return {
billboard = billboard,
nameLabel = nameLabel,
distanceLabel = distanceLabel
}
end

function updateBillboard(billboardData, name, distance, color)
if not billboardData then return end

if name then
billboardData.nameLabel.Text = name
billboardData.nameLabel.TextColor3 = color
end

if distance then
billboardData.distanceLabel.Text = string.format("%.1f studs", distance)
billboardData.distanceLabel.TextColor3 = color
end

billboardData.nameLabel.Visible = name ~= nil
billboardData.distanceLabel.Visible = distance ~= nil
end

function create2DBox(character, color, scale, useModelParent)
local existing = character:FindFirstChild("ESP_2DBox")
if existing then
existing:Destroy()
end

local billboard = Instance.new("BillboardGui")
billboard.Name = "ESP_2DBox"

if useModelParent then
billboard.Adornee = character
billboard.Parent = character
else
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
billboard.Adornee = rootPart
billboard.Parent = rootPart
else
billboard.Adornee = character
billboard.Parent = character
end
end

billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.ClipsDescendants = false

local boxFrame = Instance.new("Frame")
boxFrame.Name = "BoxFrame"
boxFrame.Size = UDim2.new(1, 0, 1, 0)
boxFrame.BackgroundTransparency = 1
boxFrame.BorderSizePixel = 0
boxFrame.Parent = billboard

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = math.max(1.5 * scale, 1)
uiStroke.Transparency = 0
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Color = color
uiStroke.Parent = boxFrame

return {
billboard = billboard,
boxFrame = boxFrame,
stroke = uiStroke,
scale = scale
}
end

function update2DBox(boxData, color, scale)
if boxData then
if boxData.stroke then
boxData.stroke.Color = color
end
if boxData.billboard then
boxData.billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
end
if boxData.stroke then
boxData.stroke.Thickness = math.max(1.5 * scale, 1)
end
boxData.scale = scale
end
end

function remove2DBox(character)
local box = character:FindFirstChild("ESP_2DBox")
if box then
box:Destroy()
end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
if boxInRoot then
boxInRoot:Destroy()
end
end
end

function createHighlight(character, color)
local existing = character:FindFirstChild("ESP_Highlight")
if existing then
existing:Destroy()
end

local highlight = Instance.new("Highlight")
highlight.Name = "ESP_Highlight"
highlight.Adornee = character
highlight.FillColor = color
highlight.OutlineColor = color
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0.3
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = character

return highlight
end

function updateHighlight(highlight, color)
if highlight then
highlight.FillColor = color
highlight.OutlineColor = color
end
end

function removeHighlight(character)
local highlight = character:FindFirstChild("ESP_Highlight")
if highlight then
highlight:Destroy()
end
end

function getPlayerColor(player)
if isInnocentBot(player.Name) then
return Color3.fromRGB(255, 255, 255)
end

if isPlayerEnemy(player) then
return Color3.fromRGB(255, 0, 0)
end

local team = getPlayerTeam(player)
if team == "Enemy" then
return Color3.fromRGB(255, 0, 0)
end

return Color3.fromRGB(0, 255, 0)
end

function getEnemyColor(model)
if isInnocentBot(model.Name) then
return Color3.fromRGB(255, 255, 255)
end
return Color3.fromRGB(255, 0, 0)
end

function getDownedColor()
return Color3.fromRGB(255, 165, 0)
end

function cleanupPlayerESP()
for character, esp in pairs(playerEspElements) do
if esp.box2D then
local box = character:FindFirstChild("ESP_2DBox")
if box then box:Destroy() end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
if boxInRoot then boxInRoot:Destroy() end
end
end
if esp.box3D then remove3DBox(character) end
if esp.highlight then removeHighlight(character) end
if esp.billboard then
local bill = character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
end
playerEspElements = {}
end

function cleanupEnemyESP()
for model, esp in pairs(EnemyEspElements) do
if esp.box2D then
local box = model:FindFirstChild("ESP_2DBox")
if box then box:Destroy() end
end
if esp.box3D then remove3DBox(model) end
if esp.highlight then removeHighlight(model) end
if esp.billboard then
local bill = model:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
end
end
EnemyEspElements = {}
end

function cleanupDownedESP()
for char, esp in pairs(downedEspElements) do
if esp.box2D then
local box = char:FindFirstChild("ESP_2DBox")
if box then box:Destroy() end
local rootPart = char:FindFirstChild("HumanoidRootPart")
if rootPart then
local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
if boxInRoot then boxInRoot:Destroy() end
end
end
if esp.box3D then remove3DBox(char) end
if esp.highlight then removeHighlight(char) end
if esp.billboard then
local bill = char:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = char:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
end
downedEspElements = {}
end

function updatePlayerESP()
if not isRendering or not windowFocused then return end
if not Workspace.CurrentCamera then return end

local currentTargets = {}

for _, otherPlayer in ipairs(Players:GetPlayers()) do
if otherPlayer ~= LocalPlayer then
local character = otherPlayer.Character
if character and character:FindFirstChild("HumanoidRootPart") then
local humanoid = character:FindFirstChild("Humanoid")
if humanoid and humanoid.Health > 0 then
currentTargets[character] = true

if not playerEspElements[character] then
playerEspElements[character] = {}
end

local esp = playerEspElements[character]
local distance = getDistanceFromCamera(character.HumanoidRootPart.Position)
local scale = calculateBoxScale(distance)
local boxColor = getPlayerColor(otherPlayer)
local isEnemyPlayer = isPlayerEnemy(otherPlayer)

if playerBoxesEnabled then
if playerBoxType == "2D" then
if not esp.box2D then
esp.box2D = create2DBox(character, boxColor, scale, isEnemyPlayer)
end
update2DBox(esp.box2D, boxColor, scale)
if esp.box3D then
remove3DBox(character)
esp.box3D = nil
end
else
local boxSize = Vector3.new(4, 5, 3)
if humanoid then
boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
end
if not esp.box3D then
esp.box3D = create3DBox(character, boxColor, boxSize)
end
update3DBoxColor(character, boxColor)
if esp.box2D then
remove2DBox(character)
esp.box2D = nil
end
end
else
if esp.box2D then
remove2DBox(character)
esp.box2D = nil
end
if esp.box3D then
remove3DBox(character)
esp.box3D = nil
end
end

if playerHighlightsEnabled then
if not esp.highlight then
esp.highlight = createHighlight(character, boxColor)
end
updateHighlight(esp.highlight, boxColor)
else
if esp.highlight then
removeHighlight(character)
esp.highlight = nil
end
end

if playerNamesEnabled or playerDistanceEnabled then
if not esp.billboard then
esp.billboard = createBillboard(character, otherPlayer.Name, boxColor, isEnemyPlayer)
end
local displayDistance = playerDistanceEnabled and distance or nil
updateBillboard(esp.billboard, playerNamesEnabled and otherPlayer.Name or nil, displayDistance, boxColor)
else
if esp.billboard then
local bill = character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
esp.billboard = nil
end
end
end
end
end
end

for character, esp in pairs(playerEspElements) do
if not currentTargets[character] then
if esp.box2D then remove2DBox(character) end
if esp.box3D then remove3DBox(character) end
if esp.highlight then removeHighlight(character) end
if esp.billboard then
local bill = character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = character:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
playerEspElements[character] = nil
end
end
end

function updateEnemyESP()
if not isRendering or not windowFocused then return end
if not Workspace.CurrentCamera then return end

local currentTargets = {}

local function processModel(model)
if not model or not model:IsA("Model") or not model:FindFirstChild("HumanoidRootPart") then return end
if not isEnemyModel(model) then return end

currentTargets[model] = true

if not EnemyEspElements[model] then
EnemyEspElements[model] = {}
end

local esp = EnemyEspElements[model]
local distance = getDistanceFromCamera(model.HumanoidRootPart.Position)
local scale = calculateBoxScale(distance)
local boxColor = getEnemyColor(model)

if EnemyBoxesEnabled then
if EnemyBoxType == "2D" then
if not esp.box2D then
esp.box2D = create2DBox(model, boxColor, scale, true)
end
update2DBox(esp.box2D, boxColor, scale)
if esp.box3D then
remove3DBox(model)
esp.box3D = nil
end
else
local humanoid = model:FindFirstChild("Humanoid")
local boxSize = Vector3.new(4, 5, 3)
if humanoid then
boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
end
if not esp.box3D then
esp.box3D = create3DBox(model, boxColor, boxSize)
end
update3DBoxColor(model, boxColor)
if esp.box2D then
remove2DBox(model)
esp.box2D = nil
end
end
else
if esp.box2D then remove2DBox(model) end
if esp.box3D then remove3DBox(model) end
end

if EnemyHighlightsEnabled then
if not esp.highlight then
esp.highlight = createHighlight(model, boxColor)
end
updateHighlight(esp.highlight, boxColor)
else
if esp.highlight then
removeHighlight(model)
esp.highlight = nil
end
end

if EnemyNamesEnabled or EnemyDistanceEnabled then
if not esp.billboard then
esp.billboard = createBillboard(model, model.Name, boxColor, true)
end
local displayDistance = EnemyDistanceEnabled and distance or nil
updateBillboard(esp.billboard, EnemyNamesEnabled and model.Name or nil, displayDistance, boxColor)
else
if esp.billboard then
local bill = model:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
esp.billboard = nil
end
end
end

if Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players") then
for _, model in pairs(Workspace.Game.Players:GetChildren()) do
processModel(model)
end
end
if Workspace:FindFirstChild("NPCStorage") then
for _, model in pairs(Workspace.NPCStorage:GetChildren()) do
processModel(model)
end
end

for model, esp in pairs(EnemyEspElements) do
if not currentTargets[model] then
if esp.box2D then remove2DBox(model) end
if esp.box3D then remove3DBox(model) end
if esp.highlight then removeHighlight(model) end
if esp.billboard then
local bill = model:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
end
EnemyEspElements[model] = nil
end
end
end

function updateDownedESP()
if not isRendering or not windowFocused then return end
if not Workspace.CurrentCamera then return end

local currentTargets = {}
local folder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")

if folder then
for _, char in ipairs(folder:GetChildren()) do
if char:IsA("Model") then
local team = char:GetAttribute("Team")
local downed = char:GetAttribute("Downed")
if team ~= "Enemy" and char.Name ~= LocalPlayer.Name and downed == true then
local hrp = char:FindFirstChild("HumanoidRootPart")
if hrp then
currentTargets[char] = true

if not downedEspElements[char] then
downedEspElements[char] = {}
end

local esp = downedEspElements[char]
local distance = getDistanceFromCamera(hrp.Position)
local scale = calculateBoxScale(distance)
local color = getDownedColor()
local isEnemyPlayer = isPlayerEnemy(Players:GetPlayerFromCharacter(char))

if downedBoxesEnabled then
if downedBoxType == "2D" then
if not esp.box2D then
esp.box2D = create2DBox(char, color, scale, isEnemyPlayer)
end
update2DBox(esp.box2D, color, scale)
if esp.box3D then
remove3DBox(char)
esp.box3D = nil
end
else
if not esp.box3D then
esp.box3D = create3DBox(char, color, Vector3.new(3, 5, 2))
end
update3DBoxColor(char, color)
if esp.box2D then
remove2DBox(char)
esp.box2D = nil
end
end
else
if esp.box2D then remove2DBox(char) end
if esp.box3D then remove3DBox(char) end
end

if downedHighlightsEnabled then
if not esp.highlight then
esp.highlight = createHighlight(char, color)
end
updateHighlight(esp.highlight, color)
else
if esp.highlight then
removeHighlight(char)
esp.highlight = nil
end
end

if downedNamesEnabled or downedDistanceEnabled then
if not esp.billboard then
esp.billboard = createBillboard(char, char.Name, color, isEnemyPlayer)
end
local displayDistance = downedDistanceEnabled and distance or nil
updateBillboard(esp.billboard, downedNamesEnabled and char.Name or nil, displayDistance, color)
else
if esp.billboard then
local bill = char:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = char:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
esp.billboard = nil
end
end
end
end
end
end
end

for char, esp in pairs(downedEspElements) do
if not currentTargets[char] then
if esp.box2D then remove2DBox(char) end
if esp.box3D then remove3DBox(char) end
if esp.highlight then removeHighlight(char) end
if esp.billboard then
local bill = char:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = char:FindFirstChild("HumanoidRootPart")
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
downedEspElements[char] = nil
end
end
end

renderConnection = nil
lastRenderTime = tick()
renderCheckConnection = nil
attributeConnections = {}

function onAttributeChanged(player, attribute)
if attribute == "Team" then
updatePlayerESP()
end
end

function setupAttributeWatchers()
for _, otherPlayer in ipairs(Players:GetPlayers()) do
if otherPlayer ~= LocalPlayer and otherPlayer.Character then
if not attributeConnections[otherPlayer] then
attributeConnections[otherPlayer] = otherPlayer.Character:GetAttributeChangedSignal("Team"):Connect(function()
updatePlayerESP()
end)
end
end
end
end

function onRenderStepped()
lastRenderTime = tick()
isRendering = true

if playerBoxesEnabled or playerNamesEnabled or playerDistanceEnabled or playerHighlightsEnabled then
updatePlayerESP()
else
cleanupPlayerESP()
end

if EnemyBoxesEnabled or EnemyNamesEnabled or EnemyDistanceEnabled or EnemyHighlightsEnabled then
updateEnemyESP()
else
cleanupEnemyESP()
end

if downedBoxesEnabled or downedNamesEnabled or downedDistanceEnabled or downedHighlightsEnabled then
updateDownedESP()
else
cleanupDownedESP()
end

setupAttributeWatchers()
end

function startRenderLoop()
if renderConnection then return end
renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
end

function stopRenderLoop()
if renderConnection then
renderConnection:Disconnect()
renderConnection = nil
end
end

function setupEnemyDetection()
local function onEnemyAdded(model)
if model:IsA("Model") and isEnemyModel(model) then
task.wait(0.5)
updateEnemyESP()
end
end

if Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players") then
Workspace.Game.Players.ChildAdded:Connect(onEnemyAdded)
end
if Workspace:FindFirstChild("NPCStorage") then
Workspace.NPCStorage.ChildAdded:Connect(onEnemyAdded)
end
end

function cleanupAllESP()
cleanupPlayerESP()
cleanupEnemyESP()
cleanupDownedESP()

for _, connection in pairs(attributeConnections) do
connection:Disconnect()
end
attributeConnections = {}
end

RunService.RenderStepped:Connect(function()
lastRenderTime = tick()
isRendering = true
end)

renderCheckConnection = RunService.Heartbeat:Connect(function()
local currentTime = tick()
if currentTime - lastRenderTime > 1 then
isRendering = false
cleanupAllESP()
end
end)

UserInputService.WindowFocusReleased:Connect(function()
windowFocused = false
isRendering = false
cleanupAllESP()
end)

UserInputService.WindowFocused:Connect(function()
windowFocused = true
isRendering = true
end)

game:GetService("GuiService"):GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
if game:GetService("GuiService").MenuIsOpen then
isRendering = false
cleanupAllESP()
else
isRendering = true
end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == LocalPlayer then
cleanupAllESP()
stopRenderLoop()
end
end)

startRenderLoop()
setupEnemyDetection()

Tabs.ESP:Section({ Title = "Player ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
Title = "Player Boxes",
Flag = "PlayerBoxes",
Value = false,
Callback = function(state) playerBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
Title = "Player Box Type",
Flag = "PlayerBoxType",
Values = {"2D", "3D"},
Value = "2D",
Callback = function(value) playerBoxType = value end
})

Tabs.ESP:Toggle({
Title = "Player Names",
Flag = "PlayerNames",
Value = false,
Callback = function(state) playerNamesEnabled = state end
})

Tabs.ESP:Toggle({
Title = "Player Distance",
Flag = "PlayerDistance",
Value = false,
Callback = function(state) playerDistanceEnabled = state end
})

Tabs.ESP:Toggle({
Title = "Player Highlights",
Flag = "PlayerHighlights",
Value = false,
Callback = function(state) playerHighlightsEnabled = state end
})

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Enemy ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
Title = "Enemy Boxes",
Flag = "EnemyBoxes",
Value = false,
Callback = function(state) EnemyBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
Title = "Enemy Box Type",
Flag = "EnemyBoxType",
Values = {"2D", "3D"},
Value = "2D",
Callback = function(value) EnemyBoxType = value end
})

Tabs.ESP:Toggle({
Title = "Enemy Names",
Flag = "EnemyNames",
Value = false,
Callback = function(state)
EnemyNamesEnabled = state
if state then setupEnemyDetection() end
end
})

Tabs.ESP:Toggle({
Title = "Enemy Distance",
Flag = "EnemyDistance",
Value = false,
Callback = function(state) EnemyDistanceEnabled = state end
})

Tabs.ESP:Toggle({
Title = "Enemy Highlights",
Flag = "EnemyHighlights",
Value = false,
Callback = function(state) EnemyHighlightsEnabled = state end
})

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Downed Player ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
Title = "Downed Boxes",
Flag = "DownedBoxes",
Value = false,
Callback = function(state) downedBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
Title = "Downed Box Type",
Flag = "DownedBoxType",
Values = {"2D", "3D"},
Value = "2D",
Callback = function(value) downedBoxType = value end
})

Tabs.ESP:Toggle({
Title = "Downed Names",
Flag = "DownedNames",
Value = false,
Callback = function(state) downedNamesEnabled = state end
})

Tabs.ESP:Toggle({
Title = "Downed Distance",
Flag = "DownedDistance",
Value = false,
Callback = function(state) downedDistanceEnabled = state end
})

Tabs.ESP:Toggle({
Title = "Downed Highlights",
Flag = "DownedHighlights",
Value = false,
Callback = function(state) downedHighlightsEnabled = state end
})

Tabs.ESP:Divider()

Tabs.Utility:Button({
Title = "Clear Invis Walls",
Callback = function()
local invisPartsFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Map") and Workspace.Game.Map:FindFirstChild("InvisParts")
if invisPartsFolder then
for _, obj in ipairs(invisPartsFolder:GetDescendants()) do
if obj:IsA("BasePart") then
obj.CanCollide = false
end
end
end
end
})
Tabs.Utility:Space()

TimeChangerInput = Tabs.Utility:Input({
Title = "Set Time (HH:MM)",
Flag = "TimeChangerInput",
Placeholder = "12:00",
Callback = function(value)
value = value:gsub("^%s*(.-)%s*$", "%1")

local h_str, m_str = value:match("(%d+):(%d+)")
if h_str and m_str then
local h = tonumber(h_str)
local m = tonumber(m_str)

if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
local totalHours = h + (m / 60)
Lighting.ClockTime = totalHours
end
end
end
})
lagSwitchEnabled = false
lagDuration = 0.5
lagMethod = "CPU Cycle"
local isLagActive = false
local lagSystemLoaded = false

function lag()
local duration = lagDuration or 0.5
local method = lagMethod or "CPU Cycle"

if method == "CPU Cycle" then pcall(function() setfflag("MaxMissedWorldStepsRemembered","1") end)
local start = tick()
while tick() - start < duration do
local a = math.random(1, 1000000) * math.random(1, 1000000)
a = a / math.random(1, 10000)
end
elseif method == "OS.ClockFFlag" then
pcall(function() setfflag("MaxMissedWorldStepsRemembered","10000001000000") end)
local start = os.clock()
while os.clock() - start < duration do
end
end
end
function loadLagSystem()
if lagSystemLoaded then return end
lagSystemLoaded = true
end

function unloadLagSystem()
if not lagSystemLoaded then return end
lagSystemLoaded = false
isLagActive = false
end

function checkLagState()
local shouldLoad = lagSwitchEnabled

if shouldLoad and not lagSystemLoaded then
loadLagSystem()
elseif not shouldLoad and lagSystemLoaded then
unloadLagSystem()
end
end

Tabs.Utility:Space()
ButtonLib.Create:Button({
Text = "Lag Switch",
Flag = "LagSwitch",
Visible = false,
Callback = function()
isLagActive = task.spawn(lag)
end
}).Position = UDim2.new(0.5, -125, 0.2, 0)

LagSwitchToggle = Tabs.Utility:Toggle({
Title = "Lag Switch",
Flag = "LagSwitchToggle",
Icon = "zap",
Value = false,
Callback = function(state)
lagSwitchEnabled = state

if ButtonLib and ButtonLib.LagSwitch then
ButtonLib.LagSwitch:SetVisible(state)
end

checkLagState()
end
})

LagMethodDropdown = Tabs.Utility:Dropdown({
Title = "Lag Method",
Flag = "LagMethodDropdown",
Values = {"CPU Cycle", "OS.ClockFFlag"},
Value = "CPU Cycle",
Callback = function(value)
lagMethod = value
end
})

LagDurationInput = Tabs.Utility:Input({
Title = "Lag Duration (seconds)",
Flag = "LagDurationInput",
Placeholder = "0.5",
Value = tostring(lagDuration),
NumbersOnly = true,
Callback = function(text)
local n = tonumber(text)
if n and n > 0 then
lagDuration = n
end
end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == LocalPlayer then
unloadLagSystem()
end
end)

checkLagState()

Tabs.Utility:Space()

GravityToggle = Tabs.Utility:Toggle({
Title = "Custom Gravity",
Flag = "GravityToggle",
Value = false,
Callback = function(state)
CustomGravity = state
if state then
Workspace.Gravity = GravityValue
else
Workspace.Gravity = 50
end
end
})


ButtonLib.Create:Toggle({
Text = "Gravity",
Flag = "GravityToggle",
Default = false,
Visible = false,
Callback = function(s)
if GravityToggle then
GravityToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)

ShowGravityButtonToggle = Tabs.Utility:Toggle({
Title = "Show Gravity Button",
Flag = "ShowGravityButton",
Value = false,
Callback = function(state)
ShowGravityButton = state

if ButtonLib and ButtonLib.GravityToggle then
ButtonLib.GravityToggle:SetVisible(state)
end
end
})
GravityInput = Tabs.Utility:Input({
Title = "Gravity Value",
Flag = "GravityInput",
Placeholder = tostring(originalGameGravity),
Value = tostring(GravityValue),
Callback = function(text)
local num = tonumber(text)
if num then
GravityValue = num
if CustomGravity then
Workspace.Gravity = num
end
end
end
})

if CustomGravity then
Workspace.Gravity = GravityValue
else
Workspace.Gravity = originalGameGravity
end

if not featureStates then
featureStates = {
CustomGravity = false,
GravityValue = Workspace.Gravity
}
end
LocalPlayer.CharacterAdded:Connect(function()
hasRevived = false
end)
Tabs.Utility:Space()

RemoveTexturesButton = Tabs.Utility:Button({
Title = "Remove Textures",
Callback = function()
for _, part in ipairs(Workspace:GetDescendants()) do
if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
if part:IsA("Part") then
part.Material = Enum.Material.SmoothPlastic
end
if part:FindFirstChildWhichIsA("Texture") then
local texture = part:FindFirstChildWhichIsA("Texture")
texture.Texture = "rbxassetid://0"
end
if part:FindFirstChildWhichIsA("Decal") then
local decal = part:FindFirstChildWhichIsA("Decal")
decal.Texture = "rbxassetid://0"
end
end
end
end
})
Players.PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == LocalPlayer then
RunService:Set3dRenderingEnabled(true)
end
end) Tabs.Utility:Space()

LowQualityButton = Tabs.Utility:Button({
Title = "Low Quality",
Desc = "Disable textures, effects, and optimize graphics",
Callback = function()
local ToDisable = {
Textures = true,
VisualEffects = true,
Parts = true,
Particles = true,
Sky = true
}

local ToEnable = {
FullBright = false
}

local Stuff = {}

for _, v in next, game:GetDescendants() do
if ToDisable.Parts then
if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
v.Material = Enum.Material.SmoothPlastic
table.insert(Stuff, 1, v)
end
end

if ToDisable.Particles then
if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
v.Enabled = false
table.insert(Stuff, 1, v)
end
end

if ToDisable.VisualEffects then
if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
v.Enabled = false
table.insert(Stuff, 1, v)
end
end

if ToDisable.Textures then
if v:IsA("Decal") or v:IsA("Texture") then
v.Texture = ""
table.insert(Stuff, 1, v)
end
end

if ToDisable.Sky then
if v:IsA("Sky") then
v.Parent = nil
table.insert(Stuff, 1, v)
end
end
end

if ToEnable.FullBright then

Lighting.FogColor = Color3.fromRGB(255, 255, 255)
Lighting.FogEnd = math.huge
Lighting.FogStart = math.huge
Lighting.Ambient = Color3.fromRGB(255, 255, 255)
Lighting.Brightness = 5
Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
Lighting.Outlines = true
end
end
})

Tabs.Teleport:Section({ Title = "Teleports", TextSize = 20 })
Tabs.Teleport:Divider()

Tabs.Teleport:Space()

Tabs.Teleport:Button({
Title = "Teleport to Spawn",
Desc = "Teleport to a random spawn location",
Icon = "home",
Callback = function()
local spawnsFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Map") and Workspace.Game.Map:FindFirstChild("Parts") and Workspace.Game.Map.Parts:FindFirstChild("Spawns")

if spawnsFolder then
local spawnLocations = spawnsFolder:GetChildren()
if #spawnLocations > 0 then
local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
local character = LocalPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

if humanoidRootPart then
humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
end
end
end
end
})

Tabs.Teleport:Space()

Tabs.Teleport:Button({
Title = "Teleport to Random Player",
Desc = "Teleport to a random online player",
Icon = "users",
Callback = function()
local players = Players:GetPlayers()
local validPlayers = {}

for _, plr in ipairs(players) do
if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
table.insert(validPlayers, plr)
end
end

if #validPlayers > 0 then
local randomPlayer = validPlayers[math.random(1, #validPlayers)]
local character = LocalPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

if humanoidRootPart then
humanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
end
end
end
})

Tabs.Teleport:Space()

Tabs.Teleport:Button({
Title = "Teleport to Downed Player",
Desc = "Teleport to a random downed player",
Icon = "heart",
Callback = function()
local playersFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")
local downedPlayers = {}

if playersFolder then
for _, model in ipairs(playersFolder:GetChildren()) do
if model:IsA("Model") and model:GetAttribute("Downed") == true and model.Name ~= LocalPlayer.Name then
local hrp = model:FindFirstChild("HumanoidRootPart")
if hrp then
table.insert(downedPlayers, model)
end
end
end
end

if #downedPlayers > 0 then
local randomDowned = downedPlayers[math.random(1, #downedPlayers)]
local character = LocalPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

if humanoidRootPart then
humanoidRootPart.CFrame = randomDowned.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
end
end
end
})
local playerList = {}
Tabs.Teleport:Space()
PlayerDropdown = Tabs.Teleport:Dropdown({
Title = "Select Player",
Flag = "PlayerDropdown",
Values = {{Title = "No players found", Desc = "", Icon = "user"}},
Value = "No players found",
Callback = function(selectedOption)
end
})

function updatePlayerList()
playerList = {}
local players = Players:GetPlayers()
local dropdownValues = {}
for _, plr in ipairs(players) do
if plr ~= LocalPlayer then
table.insert(playerList, plr)
local success, content = pcall(function()
return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
local iconUrl = success and content or "user"
table.insert(dropdownValues, {
Title = plr.DisplayName,
Desc = "@" .. plr.Name,
Icon = iconUrl
})
end
end
if #dropdownValues == 0 then
dropdownValues = {{Title = "No players found", Desc = "", Icon = "user"}}
end
PlayerDropdown:Refresh(dropdownValues, true)
end

updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

Tabs.Teleport:Button({
Title = "Teleport to Selected Player",
Desc = "Teleport to the player selected in dropdown",
Icon = "user",
Callback = function()
local selectedOption = PlayerDropdown.Value
if selectedOption and selectedOption.Title ~= "No players found" then
for _, plr in ipairs(playerList) do
if plr.DisplayName == selectedOption.Title or plr.Name == selectedOption.Title then
if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
local character = LocalPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
end
end
break
end
end
end
end
})

Tabs.Teleport:Space()
Tabs.Teleport:Button({
Title = "Teleport to Enemy",
Desc = "Teleport to a random Enemy",
Icon = "ghost",
Callback = function()
local Enemys = {}

local playersFolder = Workspace:FindFirstChild("Game") and Workspace.Game:FindFirstChild("Players")
if playersFolder then
for _, model in ipairs(playersFolder:GetChildren()) do
if model:IsA("Model") and isEnemyModel(model) then
local hrp = model:FindFirstChild("HumanoidRootPart")
if hrp then
table.insert(Enemys, model)
end
end
end
end

local NPCStorageFolder = Workspace:FindFirstChild("NPCStorage")
if NPCStorageFolder then
for _, model in ipairs(NPCStorageFolder:GetChildren()) do
if model:IsA("Model") and isEnemyModel(model) then
local hrp = model:FindFirstChild("HumanoidRootPart")
if hrp then
table.insert(Enemys, model)
end
end
end
end

if #Enemys > 0 then
local randomEnemy = Enemys[math.random(1, #Enemys)]
local character = LocalPlayer.Character
local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")

if humanoidRootPart then
humanoidRootPart.CFrame = randomEnemy.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
end
end
end
})

Tabs.Teleport:Space()

local objectives = {}
local objectiveDropdown
local teleportButton
local refreshButton

function findObjectives()
objectives = {}

local gameFolder = Workspace:FindFirstChild("Game")
if not gameFolder then return false end

local mapFolder = gameFolder:FindFirstChild("Map")
if not mapFolder then return false end

local partsFolder = mapFolder:FindFirstChild("Parts")
if not partsFolder then return false end

local objectivesFolder = partsFolder:FindFirstChild("Objectives")
if not objectivesFolder then return false end

for _, obj in pairs(objectivesFolder:GetChildren()) do
if obj:IsA("Model") then
local primaryPart = obj.PrimaryPart
if not primaryPart then
for _, part in pairs(obj:GetChildren()) do
if part:IsA("BasePart") then
primaryPart = part
break
end
end
end

if primaryPart then
table.insert(objectives, {
Name = obj.Name,
Part = primaryPart,
Position = primaryPart.Position,
Size = primaryPart.Size
})
end
end
end

return #objectives > 0
end

function updateObjectiveDropdown()
local hasObjectives = findObjectives()

if not objectiveDropdown then
warn("Objective dropdown not found in updateObjectiveDropdown")
return
end

if hasObjectives and objectives then
local objectiveNames = {}
for _, obj in ipairs(objectives) do
if obj and obj.Name then
table.insert(objectiveNames, obj.Name)
end
end

if #objectiveNames > 0 then
objectiveDropdown:Refresh(objectiveNames, objectiveNames[1])
else
objectiveDropdown:Refresh({"No valid objectives"}, "No valid objectives")
end
else
objectiveDropdown:Refresh({"No objectives found"}, "No objectives found")
end
end
Tabs.Teleport:Space()
objectiveDropdown = Tabs.Teleport:Dropdown({
Title = "Select Objective",
Flag = "objectiveDropdown",
Values = {"Loading..."},
Value = "Loading...",
Enabled = false,
Callback = function(value)
end
})

teleportButton = Tabs.Teleport:Button({
Title = "Teleport to Objective",
Icon = "navigation",
Enabled = false,
Callback = function()
local selectedName = objectiveDropdown.Value
if selectedName == "No objectives found" or selectedName == "Loading..." then
return
end

local selectedObjective
for _, obj in ipairs(objectives) do
if obj.Name == selectedName then
selectedObjective = obj
break
end
end

if not selectedObjective then
return
end

local character = LocalPlayer.Character
if not character then return end

local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return end

local teleportPosition = selectedObjective.Position + Vector3.new(0, 5, 0)

local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {character}
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

local ray = Workspace:Raycast(teleportPosition, Vector3.new(0, -10, 0), raycastParams)
if ray then
teleportPosition = ray.Position + Vector3.new(0, 3, 0)
end

humanoidRootPart.CFrame = CFrame.new(teleportPosition)
end
})

refreshButton = Tabs.Teleport:Button({
Title = "Refresh Objectives",
Icon = "refresh-cw",
Callback = function()
updateObjectiveDropdown()
end
})
task.spawn(function()
task.wait(3)
updateObjectiveDropdown()

if Workspace:FindFirstChild("Game") then
local gameFolder = Workspace.Game

if gameFolder:FindFirstChild("Stats") then
gameFolder.Stats:GetAttributeChangedSignal("RoundStarted"):Connect(function()
task.wait(2)
updateObjectiveDropdown()
end)
end
end
end)

Tabs.Settings:Section({ Title = "Settings", TextSize = 40 })
Tabs.Settings:Section({ Title = "Config Manager", TextSize = 20 })
Tabs.Settings:Divider()

local ConfigManager = Window.ConfigManager

local CurrentConfigName = "default"
local AutoLoadConfig = "default"
local AutoLoadEnabled = false
local AutoSaveEnabled = false
local ConfigListDropdown = nil
local AutoSaveConnection = nil

function FileExists(path)
if isfile then
return pcall(readfile, path)
end
return false
end

function WriteFile(path, content)
if writefile then
return pcall(writefile, path, content)
end
return false
end

function ReadFile(path)
if readfile then
local success, content = pcall(readfile, path)
if success then
return content
end
end
return ""
end

function loadAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Evade-Legacy/AutoLoad.json"

if FileExists(autoLoadFile) then
local content = ReadFile(autoLoadFile)

if content ~= "" then
local success, data = pcall(function()
return HttpService:JSONDecode(content)
end)

if success and data then
AutoLoadConfig = data.configName or "default"
AutoLoadEnabled = data.enabled or false
return true
end
end
end

AutoLoadConfig = "default"
AutoLoadEnabled = false
return false
end

function saveAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Evade-Legacy/AutoLoad.json"

local success = WriteFile(autoLoadFile, "")
if not success then
if makefolder then
pcall(function() makefolder("Darahub") end)
pcall(function() makefolder("Darahub/AutoLoad") end)
pcall(function() makefolder("Darahub/AutoLoad/Game") end)
pcall(function() makefolder("Darahub/AutoLoad/Game/Evade-Legacy") end)
end
end

local data = {
enabled = AutoLoadEnabled,
configName = AutoLoadConfig
}

local success, json = pcall(function()
return HttpService:JSONEncode(data)
end)

if success then
WriteFile(autoLoadFile, json)
end
end

loadAutoLoadSettings()

local ConfigNameInput = Tabs.Settings:Input({
Title = "Config Name",
Flag = "ConfigNameInput",
Desc = "Name for your config file",
Icon = "file-cog",
Placeholder = "default",
Value = CurrentConfigName,
Callback = function(value)
if value ~= "" then
CurrentConfigName = value
end
end
})

Tabs.Settings:Space()

local AutoLoadToggle = Tabs.Settings:Toggle({
Title = "Auto Load",
Flag = "AutoLoadToggle",
Desc = "Automatically load this config when script starts",
Value = AutoLoadEnabled,
Callback = function(state)
AutoLoadEnabled = state
if state then
AutoLoadConfig = CurrentConfigName
WindUI:Notify({
Title = "Auto-Load",
Content = "Config '" .. CurrentConfigName .. "' will load automatically on startup",
Duration = 3
})
end
saveAutoLoadSettings()
end
})

local AutoSaveToggle = Tabs.Settings:Toggle({
Title = "Auto Save",
Flag = "AutoSaveToggle",
Desc = "Automatically save changes to config every second",
Value = AutoSaveEnabled,
Callback = function(state)
AutoSaveEnabled = state

if AutoSaveConnection then
AutoSaveConnection:Disconnect()
AutoSaveConnection = nil
end

if state then
WindUI:Notify({
Title = "Auto-Save",
Content = "Config will save automatically every second",
Duration = 2
})

AutoSaveConnection = RunService.Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1)
end)
else
WindUI:Notify({
Title = "Auto-Save",
Content = "Auto-save disabled",
Duration = 2
})
end
end
})

Tabs.Settings:Space()

function refreshConfigList()
local allConfigs = ConfigManager:AllConfigs() or {}

if not table.find(allConfigs, "default") then
local defaultConfig = ConfigManager:Config("default")
if defaultConfig and defaultConfig.Save then
defaultConfig:Save()
end
table.insert(allConfigs, 1, "default")
end

table.sort(allConfigs, function(a, b)
return a:lower() < b:lower()
end)

local defaultValue = table.find(allConfigs, CurrentConfigName) and CurrentConfigName or "default"

if ConfigListDropdown and ConfigListDropdown.Refresh then
ConfigListDropdown:Refresh(allConfigs, defaultValue)
end
end

ConfigListDropdown = Tabs.Settings:Dropdown({
Title = "Existing Configs",
Flag = "ConfigListDropdown",
Desc = "Select from saved configs",
Values = {"default"},
Value = "default",
Callback = function(value)
CurrentConfigName = value
ConfigNameInput:Set(value)

if AutoLoadEnabled then
AutoLoadConfig = value
saveAutoLoadSettings()
end

local config = ConfigManager:GetConfig(value)
if config then
WindUI:Notify({
Title = "Config Selected",
Content = "Config '" .. value .. "' selected",
Duration = 2
})
end
end
})

Tabs.Settings:Space()

local SaveConfigButton = Tabs.Settings:Button({
Title = "Save Config",
Desc = "Save current settings to config",
Icon = "save",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end

Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)

local success = Window.CurrentConfig:Save()
if success then
WindUI:Notify({
Title = "Config Saved",
Content = "Config '" .. CurrentConfigName .. "' saved successfully",
Duration = 3
})

if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end

task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to save config",
Duration = 3
})
end
end
})

Tabs.Settings:Space()

local LoadConfigButton = Tabs.Settings:Button({
Title = "Load Config",
Desc = "Load settings from selected config",
Icon = "folder-open",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end

Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)

local success = Window.CurrentConfig:Load()
if success then
WindUI:Notify({
Title = "Config Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded successfully",
Duration = 3
})

if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end
else
WindUI:Notify({
Title = "Error",
Content = "Config '" .. CurrentConfigName .. "' not found or empty",
Duration = 3
})
end
end
})

Tabs.Settings:Space()

local DeleteConfigButton = Tabs.Settings:Button({
Title = "Delete Config",
Desc = "Delete selected config",
Icon = "trash-2",
Color = Color3.fromHex("#ff4830"),
Callback = function()
if CurrentConfigName == "default" then
WindUI:Notify({
Title = "Error",
Content = "Cannot delete default config",
Duration = 3
})
return
end

local success = ConfigManager:DeleteConfig(CurrentConfigName)
if success then
WindUI:Notify({
Title = "Config Deleted",
Content = "Config '" .. CurrentConfigName .. "' deleted",
Duration = 3
})

CurrentConfigName = "default"
ConfigNameInput:Set("default")

if AutoLoadEnabled then
AutoLoadConfig = "default"
saveAutoLoadSettings()
end

task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to delete config or config doesn't exist",
Duration = 3
})
end
end
})

Tabs.Settings:Space()

local RefreshConfigButton = Tabs.Settings:Button({
Title = "Refresh Config List",
Desc = "Update the list of available configs",
Icon = "refresh-cw",
Callback = function()
refreshConfigList()
WindUI:Notify({
Title = "Config List Refreshed",
Content = "Config list updated",
Duration = 2
})
end
})

task.spawn(function()
task.wait(0.5)
refreshConfigList()

ConfigNameInput:Set("default")

if AutoLoadEnabled then
CurrentConfigName = AutoLoadConfig
ConfigNameInput:Set(CurrentConfigName)

task.wait(1)
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)

if Window.CurrentConfig:Load() then
WindUI:Notify({
Title = "Auto-Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded automatically",
Duration = 3
})
end
end
end)

if AutoSaveEnabled then
task.spawn(function()
task.wait(1)

if AutoSaveEnabled then
AutoSaveConnection = RunService.Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1)
end)
end
end)
end

Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
Tabs.Settings:Divider()

themes = {}

availableThemes = WindUI:GetThemes()

for themeName, _ in pairs(availableThemes) do
table.insert(themes, themeName)
end
table.sort(themes)

ThemeDropdown = Tabs.Settings:Dropdown({
Title = "Select Theme",
Flag = "ThemeDropdown",
Values = themes,
SearchBarEnabled = true,
MenuWidth = 280,
Value = themes[1],
Callback = function(theme)
WindUI:SetTheme(theme)
end
})

TransparencySlider = Tabs.Settings:Slider({
Title = "Window Transparency",
Step = 0.01,
Flag = "TransparencySlider",
Value = { Min = 0, Max = 1, Default = WindUI.TransparencyValue },
Callback = function(value)
WindUI.TransparencyValue = tonumber(value)
Window:ToggleTransparency(tonumber(value) > 0)
end
})


Tabs.Settings:Section({ Title = "Keybinds" })
Tabs.Settings:Keybind({
Flag = "WinKeybind",
Title = "Windows Keybind",
Desc = "Keybind to open ui",
Value = "RightControl",
Callback = function(RightControl)
Window:SetToggleKey(Enum.KeyCode[RightControl])
end
})
Tabs.Settings:Section({ Title = "Main Tabs Keybinds" })

Tabs.Settings:Keybind({ Flag = "StartRecord", Title = "Start Recording", Value = "", Callback = StartRecord })
Tabs.Settings:Keybind({ Flag = "StopRecord",Title = "Stop Recording",Value = "", Callback = StopRecord })
Tabs.Settings:Keybind({ Flag = "PlayTAS", Title = "Play TAS",Value = "", Callback = PlayTAS })
Tabs.Settings:Section({ Title = "Note: This is a permanent Changes, it's can be used to pass limit value", TextSize = 15 })
Tabs.Settings:Space()
UncrouchKeybind = Tabs.Settings:Keybind({
Title = "Uncrouch Keybind",
Desc = "Press to uncrouch",
Value = "",
Flag = "UncrouchKeybind",
Callback = function()
uncrouch()
end
})
EmoteCrouchKeybind = Tabs.Settings:Keybind({
Title = "Trigger Random Emote",
Desc = "Keybind to trigger random emote with crouch",
Value = "J",
Flag = "EmoteCrouchKeybind",
Callback = function(v)
if EmoteCrouchEnabled then
triggerRandomEmote()
end
end
})
Tabs.Settings:Space()
SuperBounceKeybind = Tabs.Settings:Keybind({
Title = "Trigger Super Bounce",
Desc = "Keybind to trigger super bounce",
Value = "N",
Flag = "SuperBounceKeybind",
Callback = function(v)
if SuperBounceEnabled then
triggerSuperBounce()
end
end
})

Tabs.Settings:Section({ Title = "Player Tabs Keybinds" })
Tabs.Settings:Space()

EasyTrimpKeybind = Tabs.Settings:Keybind({
Title = "Easy Trimp Toggle",
Desc = "Keybind to toggle Easy Trimp",
Value = "U",
Flag = "EasyTrimpKeybind",
Callback = function(v)
EasyTrmpToggle:Set(not EasyTrmpToggle.Value)
end
})
Tabs.Settings:Space()
FlyTogglekeybind = Tabs.Settings:Keybind({
Title = "Fly Toggle",
Desc = "Keybind to toggle Fly",
Value = "",
Flag = "FlyTogglekeybind",
Callback = function(v)
FlyToggle:Set(not FlyToggle.Value)
end
})
Tabs.Settings:Section({ Title = "Auto Tabs Keybinds" })
EasyTrmpKeybind = Tabs.Settings:Keybind({
Title = "Easy Trmp Toggle Key",
Flag = "EasyTrmpKeybind",
Value = "Five",
Callback = function(v)
EasyTrmpToggle:Set(not EasyTrmpToggle.Value)
end
})
Bhopkeybind = Tabs.Settings:Keybind({
Title = "Bhop Toggle",
Desc = "Keybind to toggle Bhop",
Value = "B",
Flag = "Bhopkeybind",
Callback = function(v)
BhopHoldToggle:Set(not BhopHoldToggle.Value)
end
})

Tabs.Settings:Space()

AutoCrouchKeybind = Tabs.Settings:Keybind({
Title = "Auto Crouch Toggle",
Desc = "Keybind to toggle Auto Crouch",
Value = "C",
Flag = "AutoCrouchKeybind",
Callback = function(v)
AutoCrouchToggle:Set(not AutoCrouchToggle.Value)
end
})

Tabs.Settings:Space()

AutoCarryKeybind = Tabs.Settings:Keybind({
Title = "Auto Carry Toggle",
Desc = "Keybind to toggle Auto Carry",
Value = "X",
Flag = "AutoCarryKeybind",
Callback = function(v)
AutoCarryToggle:Set(not AutoCarryToggle.Value)
end
})

Tabs.Settings:Section({ Title = "Utility Tabs Keybinds" })

LagSwitchKeybind = Tabs.Settings:Keybind({
Title = "Trigger Lag Switch",
Desc = "Keybind to trigger lag switch",
Value = "L",
Flag = "LagSwitchKeybind",
Callback = function(v)
if lagSwitchEnabled and not isLagActive then
isLagActive = true
task.spawn(function()
lag()
isLagActive = false
end)
end
end
})

Tabs.Settings:Space()

GravityKeybind = Tabs.Settings:Keybind({
Title = "Toggle Gravity",
Desc = "Keybind to toggle custom gravity",
Value = "J",
Flag = "GravityKeybind",
Callback = function(v)
GravityToggle:Set(not GravityToggle.Value)
end
})


Tabs.Settings:Section({ Title = "Game Settings", TextSize = 20 })
Tabs.Settings:Divider()

PlayerSettings = LocalPlayer.Settings

if not PlayerSettings then
repeat task.wait() until LocalPlayer.Settings
PlayerSettings = LocalPlayer.Settings
end

SettingControls = {}

CreateSettingControl = function(settingName, settingValue, valueType)
if valueType == "IntValue" then
control = Tabs.Settings:Input({
Title = settingName,
Flag = settingName .. "Input",
Placeholder = tostring(settingValue),
NumbersOnly = true,
Value = tostring(settingValue),
Callback = function(value)
numValue = tonumber(value)
if numValue then
PlayerSettings:SetAttribute(settingName, numValue)
Event = ReplicatedStorage.Events.UpdateSetting
Event:FireServer(settingName, numValue)
end
end
})
SettingControls[settingName] = control
return control

elseif valueType == "BoolValue" then
control = Tabs.Settings:Toggle({
Title = settingName,
Flag = settingName .. "Toggle",
Value = settingValue,
Callback = function(state)
PlayerSettings:SetAttribute(settingName, state)
Event = ReplicatedStorage.Events.UpdateSetting
Event:FireServer(settingName, state)
end
})
SettingControls[settingName] = control
return control
end
end

SettingsUpdated = function(settingName, newValue, valueType)
control = SettingControls[settingName]
if control and control.Set then
if valueType == "IntValue" then
control:Set(tostring(newValue))
elseif valueType == "BoolValue" then
control:Set(newValue)
end
end
end

for _, child in pairs(PlayerSettings:GetChildren()) do
if child:IsA("IntValue") then
settingName = child.Name
settingValue = child.Value
CreateSettingControl(settingName, settingValue, "IntValue")

child.Changed:Connect(function(newValue)
SettingsUpdated(settingName, newValue, "IntValue")
end)

elseif child:IsA("BoolValue") then
settingName = child.Name
settingValue = child.Value
CreateSettingControl(settingName, settingValue, "BoolValue")

child.Changed:Connect(function(newValue)
SettingsUpdated(settingName, newValue, "BoolValue")
end)
end
end

for _, attributeName in pairs(PlayerSettings:GetAttributes()) do
settingValue = PlayerSettings:GetAttribute(attributeName)
if settingValue ~= nil then
valueType = type(settingValue)
if valueType == "number" then
CreateSettingControl(attributeName, settingValue, "IntValue")

PlayerSettings:GetAttributeChangedSignal(attributeName):Connect(function()
newValue = PlayerSettings:GetAttribute(attributeName)
if newValue ~= nil then
SettingsUpdated(attributeName, newValue, "IntValue")
end
end)

elseif valueType == "boolean" then
CreateSettingControl(attributeName, settingValue, "BoolValue")

PlayerSettings:GetAttributeChangedSignal(attributeName):Connect(function()
newValue = PlayerSettings:GetAttribute(attributeName)
if newValue ~= nil then
SettingsUpdated(attributeName, newValue, "BoolValue")
end
end)
end
end
end

do
local DarahubFolder = CoreGui:FindFirstChild("Darahub")

if DarahubFolder and Tabs and Tabs.Settings then
Tabs.Settings:Section({
Title = "GUI Size"
})
local defaultScales = {}

for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
defaultScales[Element.Name] = Element.UIScale.Scale
end
end

Tabs.Settings:Button({
Title = "Reset All Scales",
Description = "Reverts all buttons to their startup scale values",
Callback = function()
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local original = defaultScales[Element.Name] or 1
Element.UIScale.Scale = original
end
end
end
})

for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local currentScale = tonumber(Element.UIScale.Scale) or 1

Tabs.Settings:Slider({
Title = Element.Name .. " Scale",
Desc = "Adjust GUI scale",
Flag = "Scale_Slider_" .. Element.Name,
Step = 0.01,
Value = {
Min = 0.01,
Max = 4,
Default = currentScale
},
Callback = function(val)
if Element and Element:FindFirstChild("UIScale") then
Element.UIScale.Scale = tonumber(val)
end
end
})
end
end
end
end
Tabs.Settings:Section({ Title = "UI Visibility", TextSize = 20 })
Tabs.Settings:Divider()

TopGuiButtonDropdown = Tabs.Settings:Dropdown({
Title = "Top UI Visibility",
Flag = "TopGuiButtonDropdown",
Desc = "Show/hide buttons in Custom Top Gui",
Values = {"VIPButton", "LeaderboardButton", "SecondaryButton", "ReloadButton"},
Multi = true,
AllowNone = true,
Value = {"VIPButton", "LeaderboardButton", "SecondaryButton", "ReloadButton"},
Callback = function(values)
local topbarStandard = PlayerGui:FindFirstChild("TopbarStandard")
if not topbarStandard then return end
local main = topbarStandard:FindFirstChild("Main")
if not main then return end
local holders = main:FindFirstChild("Holders")
if not holders then return end
local left = holders:FindFirstChild("Left")
if not left then
local scrollingFrame = holders:FindFirstChild("Right")
if scrollingFrame then
left = scrollingFrame
else
return
end
end

local buttonNames = {"SecondaryButton", "VIPButton", "LeaderboardButton", "ReloadButton"}

for _, buttonName in ipairs(buttonNames) do
local btn = left:FindFirstChild(buttonName)
if btn then
local visible = false
for _, selectedName in ipairs(values) do
if selectedName == buttonName then
visible = true
break
end
end
btn.Visible = visible
end
end
end
})


local FPSCounter = CoreGui:FindFirstChild("FPSCounter")

if FPSCounter then
FPSCounterToggle = Tabs.Settings:Toggle({
Title = "Show FPS Counter",
Flag = "FPSCounterToggle",
Value = true,
Callback = function(state)
if FPSCounter then
FPSCounter.Enabled = state
else
warn("Could Not Find \"FPSCounter\" in CoreGUI! Please Reload the script And try again.")
end
end
})
else
warn("No \"FPSCounter\" Found in CoreGUI")
end
Tabs.Settings:Section({ Title = "Sensitivity Controls", TextSize = 20 })
Tabs.Settings:Divider()

MouseSensitivityEnabled = false
MouseSensitivityValue = 1.0
TouchSensitivityEnabled = false
TouchSensitivityValue = 1.0
MIN_SENSITIVITY = 0.1
MAX_SENSITIVITY = 20.0
DEFAULT_SENSITIVITY = 1.0
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false

function setupSensitivityHook()
if cameraInputModule then return true end

local success = false

pcall(function()
local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
if not playerScripts then return end

local playerModule = playerScripts:FindFirstChild("PlayerModule")
if not playerModule then return end

local cameraModule = playerModule:FindFirstChild("CameraModule")
if cameraModule then
local cameraInput = cameraModule:FindFirstChild("CameraInput")
if cameraInput then
cameraInputModule = require(cameraInput)
if cameraInputModule and cameraInputModule.getRotation then
local originalGetRotation = cameraInputModule.getRotation
cameraInputModule.getRotation = function(disableRotation)
local rotation = originalGetRotation(disableRotation)

if MouseSensitivityEnabled and UserInputService.MouseEnabled then
return rotation * MouseSensitivityValue
elseif TouchSensitivityEnabled and UserInputService.TouchEnabled then
return rotation * TouchSensitivityValue
end
return rotation
end
success = true
end
end
end
end)

return success
end

MouseSensitivityToggle = Tabs.Settings:Toggle({
Title = "Mouse Sensitivity",
Flag = "MouseSensitivityToggle",
Desc = "Adjust mouse sensitivity",
Value = false,
Callback = function(state)
MouseSensitivityEnabled = state

if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Mouse Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
MouseSensitivityToggle:Set(false)
MouseSensitivityEnabled = false
end
end
end
})

MouseSensitivitySlider = Tabs.Settings:Slider({
Title = "Mouse Sensitivity Value",
Flag = "MouseSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
MouseSensitivityValue = value
end
})

Tabs.Settings:Space()

TouchSensitivityToggle = Tabs.Settings:Toggle({
Title = "Touch Sensitivity",
Flag = "TouchSensitivityToggle",
Desc = "Adjust touch/mobile sensitivity",
Value = false,
Callback = function(state)
TouchSensitivityEnabled = state

if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Touch Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
TouchSensitivityToggle:Set(false)
TouchSensitivityEnabled = false
end
end
end
})

TouchSensitivitySlider = Tabs.Settings:Slider({
Title = "Touch Sensitivity Value",
Flag = "TouchSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
TouchSensitivityValue = value
end
})

Tabs.Settings:Space()

Tabs.Settings:Section({ Title = "Reset Controls", TextSize = 20 })
Tabs.Settings:Divider()

Tabs.Settings:Button({
Title = "Reset Sensitivity Settings",
Desc = "Reset both mouse and touch sensitivity to defaults",
Icon = "refresh-cw",
Color = Color3.fromHex("#FF3030"),
Callback = function()
MouseSensitivityEnabled = false
MouseSensitivityValue = DEFAULT_SENSITIVITY

TouchSensitivityEnabled = false
TouchSensitivityValue = DEFAULT_SENSITIVITY

cameraInputModule = nil
mouseHookActive = false
touchHookActive = false

if MouseSensitivityToggle then
MouseSensitivityToggle:Set(false)
end
if MouseSensitivitySlider then
MouseSensitivitySlider:Set(1.0)
end
if TouchSensitivityToggle then
TouchSensitivityToggle:Set(false)
end
if TouchSensitivitySlider then
TouchSensitivitySlider:Set(1.0)
end

WindUI:Notify({
Title = "Sensitivity Reset",
Content = "All sensitivity settings reset to default",
Duration = 3
})
end
})

local UniverseScriptsStuff = loadstring(game:HttpGet("https://darahub.pages.dev/Module/More-Scripts.Lua"))()

UniverseScriptsStuff(Tabs)`n]],
["https://darahub.pages.dev/api/script/DaraHub-MM2.lua"] = [[`n-- FAILED FETCH: https://darahub.pages.dev/api/script/DaraHub-MM2.lua`n]],
["https://darahub.pages.dev/api/script/DaraHub-Grow-A-Garden.lua"] = [[`nif getgenv().DaraHubExecuted then
firesignal(game:GetService("ReplicatedStorage").GameEvents.Notification.OnClientEvent, "Script Is Already Loaded, rejoin if you want to re-execute!")
return
end
getgenv().DaraHubExecuted = true
loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/LoadAll.lua"))() 
WindUI = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/WindUI-Moded/main.lua"))() 
Window = WindUI:CreateWindow({
NewElements = true,
Title = "Dara Hub | Grow A Garden",
Icon = "rbxassetid://137330250139083",
Author = "Made by: Pnsdg And Yomka",
Folder = "DaraHub/Games/Grow-A-Garden",
Size = UDim2.fromOffset(580, 490),
Theme = "Dark",
HidePanelBackground = false,
Acrylic = false,
HideSearchBar = false,
SideBarWidth = 200,
OpenButton = {
Enabled = false,
Scale = 0
},
})
WindUI.TransparencyValue = 0.7
Window:ToggleTransparency(true)
Window:DisableTopbarButtons({ "Fullscreen" })
Window:Tag({
Title = "v1.1.2",
Color = Color3.fromHex("#30ff6a")
})
executor = identifyexecutor()
if type(executor) == "table" then
for key, value in pairs(executor) do
print(key .. ": " .. tostring(value))
end
elseif type(executor) == "string" then
Window:Tag({
Title = "" .. executor
})
else
print("The injector does not support identifyexecutor()")
end
--[[Window:Tag({
Title = "BETA",
Color = Color3.fromHex("#ffd700")
})
] ]
Tabs = {
Main = Window:Tab({ Title = "Main", Icon = "layout-grid" }),
Player = Window:Tab({ Title = "Player", Icon = "user" }),
Garden = Window:Tab({ Title = "Garden", Icon = "fence" }),
Pet = Window:Tab({ Title = "Pet", Icon = "paw-print" }),
Item = Window:Tab({ Title = "Item", Icon = "hammer" }),
Visuals = Window:Tab({ Title = "Visuals", Icon = "camera" }),
Esp = Window:Tab({ Title = "Esp", Icon = "eye" }),
Event = Window:Tab({ Title = "Event", Icon = "calendar-plus-2" }),
Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
Troll = Window:Tab({ Title = "Troll Shit stuffs", Icon = "rbxassetid://6862780932" }),
Misc = Window:Tab({ Title = "Misc", Icon = "star" }),
Utility = Window:Tab({ Title = "Utility", Icon = "wrench" }),
Shop = Window:Tab({ Title = "Shop", Icon = "shopping-cart" }),
Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
info = Window:Tab({ Title = "Info", Icon = "info" }),
Others = Window:Tab({ Title = "Others", Icon = "https://em-content.zobj.net/source/apple/419/pile-of-poo_1f4a9.png" })
}
Tabs.Main:Section({ Title = "Main", TextSize = 40 })
local UniverseServerTools = loadstring(game:HttpGet("https://darahub.pages.dev/Module/UniverseServerTools.lua"))()
UniverseServerTools(Tabs)
Window:OnOpen(function()
ButtonLib:OpenButton(false)
end)
Window:OnClose(function()
ButtonLib:OpenButton(true)
end)
Window:OnDestroy(function()
ButtonLib:DestroyScreengui()
end)
local socialsModule = loadstring(game:HttpGet("https://darahub.pages.dev/Module/info.lua"))()
socialsModule(Tabs)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local Character
local Humanoid
local HumanoidRootPart
local function setupCharacter(CharacterInstance)
Character = CharacterInstance
Humanoid = Character:FindFirstChildOfClass("Humanoid")
HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end
if LocalPlayer.Character then
setupCharacter(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
TPWALK = false
TpwalkValue = 1
JumpBoost = false
JumpPower = 5
SpeedHack = false
SpeedValue = 16
Noclip = false
coroutine.resume(coroutine.create(function()
frame = PlayerGui:WaitForChild("Teleport_UI"):WaitForChild("Frame")
if not frame:GetAttribute("UIScaled") then
SCALE_FACTOR = 0.7
COSMETICS_SCALE_FACTOR = 0.5
function scaleUDim2(udim2, scale)
return UDim2.new(udim2.X.Scale * scale, udim2.X.Offset * scale, udim2.Y.Scale * scale, udim2.Y.Offset * scale)
end
function scaleVector2(vector2, scale)
return Vector2.new(vector2.X * scale, vector2.Y * scale)
end
frame.Size = scaleUDim2(UDim2.new(0.4, 0, 0.085, 0), SCALE_FACTOR)
function ensureSizeConstraint(uiElement, minSize)
sizeConstraint = uiElement:FindFirstChildOfClass("UISizeConstraint")
if not sizeConstraint then
sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.Parent = uiElement
end
sizeConstraint.MinSize = scaleVector2(minSize, SCALE_FACTOR)
end
function removeHoverEffects(button)
button.HoverImage = ""
button.PressedImage = ""
button.AutoButtonColor = false
hoverEffects = button:FindFirstChild("HoverEffects")
if hoverEffects then
hoverEffects:Destroy()
end
clickEffects = button:FindFirstChild("ClickEffects")
if clickEffects then
clickEffects:Destroy()
end
end
sellButton = frame:WaitForChild("Sell")
sellButton.Size = scaleUDim2(UDim2.new(0.22, 0, 0.791, 0), SCALE_FACTOR)
ensureSizeConstraint(sellButton, Vector2.new(50, 1))
removeHoverEffects(sellButton)
seedsButton = frame:WaitForChild("Seeds")
seedsButton.Size = scaleUDim2(UDim2.new(0.22, 0, 0.791, 0), SCALE_FACTOR)
ensureSizeConstraint(seedsButton, Vector2.new(50, 1))
removeHoverEffects(seedsButton)
gardenButton = frame:WaitForChild("Garden")
gardenButton.Size = scaleUDim2(UDim2.new(0.35, 0, 0.985, 0), SCALE_FACTOR)
ensureSizeConstraint(gardenButton, Vector2.new(100, 1))
removeHoverEffects(gardenButton)
petsButton = frame:WaitForChild("Pets")
removeHoverEffects(petsButton)
gearButton = frame:WaitForChild("Gear")
removeHoverEffects(gearButton)
cosmeticsCraftingButton = frame:FindFirstChild("COSMETICS_and_crafting") or gearButton:Clone()
cosmeticsCraftingButton.Name = "COSMETICS_and_crafting"
cosmeticsCraftingButton.Size = scaleUDim2(UDim2.new(0.35, 0, 0.985, 0), COSMETICS_SCALE_FACTOR)
cosmeticsCraftingButton.Position = scaleUDim2(UDim2.new(0, 0, 0, 250), COSMETICS_SCALE_FACTOR)
cosmeticsCraftingButton.BackgroundColor3 = Color3.fromRGB(128, 0, 128)
cosmeticsCraftingButton.BackgroundTransparency = 0
cosmeticsCraftingButton.Image = ""
cosmeticsCraftingButton.Visible = false
removeHoverEffects(cosmeticsCraftingButton)
gearVisibility = cosmeticsCraftingButton:FindFirstChild("GearVisiblity")
if gearVisibility then
gearVisibility:Destroy()
end
cosmeticsCraftingStroke = cosmeticsCraftingButton:FindFirstChild("UIStroke") or Instance.new("UIStroke")
cosmeticsCraftingStroke.Name = "UIStroke"
cosmeticsCraftingStroke.Color = Color3.fromRGB(100, 0, 100)
cosmeticsCraftingStroke.Thickness = 1 * COSMETICS_SCALE_FACTOR
cosmeticsCraftingStroke.Parent = cosmeticsCraftingButton
cosmeticsCraftingTextLabel = cosmeticsCraftingButton:FindFirstChild("Txt")
if cosmeticsCraftingTextLabel and cosmeticsCraftingTextLabel:IsA("TextLabel") then
cosmeticsCraftingTextLabel.Text = "COSM/CRAFT"
cosmeticsCraftingTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cosmeticsCraftingTextLabel.TextSize = cosmeticsCraftingTextLabel.TextSize * COSMETICS_SCALE_FACTOR
else
cosmeticsCraftingTextLabel = Instance.new("TextLabel")
cosmeticsCraftingTextLabel.Name = "Txt"
cosmeticsCraftingTextLabel.Text = "COSM/CRAFT"
cosmeticsCraftingTextLabel.Size = UDim2.new(1, 0, 1, 0)
cosmeticsCraftingTextLabel.BackgroundTransparency = 1
cosmeticsCraftingTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
cosmeticsCraftingTextLabel.TextScaled = true
cosmeticsCraftingTextLabel.Parent = cosmeticsCraftingButton
end
textStroke = cosmeticsCraftingTextLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke")
textStroke.Name = "UIStroke"
textStroke.Color = Color3.fromRGB(58, 0, 0)
textStroke.Thickness = 1 * COSMETICS_SCALE_FACTOR
textStroke.Parent = cosmeticsCraftingTextLabel
ensureSizeConstraint(cosmeticsCraftingButton, Vector2.new(100, 1))
cosmeticsCraftingButton.Parent = frame
eventButton = frame:FindFirstChild("Event") or gardenButton:Clone()
eventButton.Name = "Event"
eventButton.Size = scaleUDim2(UDim2.new(0.35, 0, 0.985, 0), SCALE_FACTOR)
eventButton.Position = scaleUDim2(UDim2.new(0, 0, 0, 200), SCALE_FACTOR)
eventButton.Image = "rbxassetid://110208924430993"
removeHoverEffects(eventButton)
eventTextLabel = eventButton:FindFirstChild("Txt")
if eventTextLabel and eventTextLabel:IsA("TextLabel") then
eventTextLabel.Text = "EVENT"
eventTextLabel.TextSize = eventTextLabel.TextSize * SCALE_FACTOR
else
eventTextLabel = Instance.new("TextLabel")
eventTextLabel.Name = "Txt"
eventTextLabel.Text = "EVENT"
eventTextLabel.Size = UDim2.new(1, 0, 1, 0)
eventTextLabel.BackgroundTransparency = 1
eventTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
eventTextLabel.TextScaled = true
eventTextLabel.Parent = eventButton
end
ensureSizeConstraint(eventButton, Vector2.new(100, 1))
eventButton.Parent = frame
petsButton.Size = scaleUDim2(petsButton.Size, SCALE_FACTOR)
gearButton.Size = scaleUDim2(gearButton.Size, SCALE_FACTOR)
function scaleButtonText(button)
textLabel = button:FindFirstChild("Txt")
if textLabel and textLabel:IsA("TextLabel") then
if not textLabel.TextScaled then
textLabel.TextSize = textLabel.TextSize * SCALE_FACTOR
end
end
end
scaleButtonText(petsButton)
scaleButtonText(gearButton)
scaleButtonText(sellButton)
scaleButtonText(seedsButton)
scaleButtonText(gardenButton)
petsButton.Visible = true
gearButton.Visible = true
eventButton.Visible = true
task.spawn(function()
task.wait(0)
cosmeticsCraftingButton.Visible = true
end)
frame:SetAttribute("UIScaled", true)
TeleportPlayer = require(ReplicatedStorage.Modules.TeleportPlayer)
function teleportToTutorialPoint(pointName, displayName)
tutorialPoints = workspace:FindFirstChild("Tutorial_Points")
if tutorialPoints then
targetPoint = tutorialPoints:FindFirstChild(pointName)
if targetPoint then
TeleportPlayer(LocalPlayer, targetPoint.CFrame, displayName)
else
warn("Tutorial point not found: " .. pointName)
end
else
warn("Tutorial_Points folder not found in workspace")
end
end
petsButton.MouseButton1Click:Connect(function()
teleportToTutorialPoint("Tutorial_Point_4", "Pet Stand")
end)
gearButton.MouseButton1Click:Connect(function()
teleportToTutorialPoint("Tutorial_Point_3", "Gear Stands")
end)
eventButton.MouseButton1Click:Connect(function()
eventPoint = workspace:FindFirstChild("Event_Point", true)
if eventPoint then
TeleportPlayer(LocalPlayer, eventPoint.CFrame, "Event")
else
warn("Event_Point not found in workspace.Interaction")
end
end)
cosmeticsCraftingButton.MouseButton1Click:Connect(function()
craftingTables = workspace:FindFirstChild("CraftingTables")
if craftingTables then
targetCFrame = craftingTables:GetPivot()
offsetPosition = targetCFrame.Position + Vector3.new(5, 0, 5)
rotatedCFrame = CFrame.new(offsetPosition) * CFrame.Angles(0, math.rad(90), 0)
TeleportPlayer(LocalPlayer, rotatedCFrame, "Crafting")
else
warn("CraftingTables not found in workspace")
end
end)
end
end))
function IsAlive(Player, currentRoles)
for i, v in pairs(currentRoles) do
if Player.Name == i then
if not v.Killed and not v.Dead then
return true
else
return false
end
end
end
return false
end
function getOutlineColor(c)
local lum = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
if lum > 0.5 then
return Color3.new(0,0,0)
else
return Color3.new(1,1,1)
end
end
Tabs.Main:Section({ Title = "Scan Highest Fruit from My Garden" })
Tabs.Main:Divider()
gardenFruitList = {}
gardenFruitParagraph = Tabs.Main:Paragraph({
Title = "No fruits found",
Desc = "Click Refresh to scan your garden"
})
function scanGardenFruits()
gardenFruitList = {}
local myPlots = getMyFarmPlots()
if not myPlots or #myPlots == 0 then
return gardenFruitList
end
for _, plot in pairs(myPlots) do
local important = plot:FindFirstChild("Important")
if important then
local plantsPhysical = important:FindFirstChild("Plants_Physical")
if plantsPhysical then
for _, plant in pairs(plantsPhysical:GetChildren()) do
if plant:IsA("Model") then
local fruitsFolder = plant:FindFirstChild("Fruits")
if fruitsFolder then
for _, fruit in pairs(fruitsFolder:GetChildren()) do
local prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
if prompt and prompt.Enabled == false then
continue
end
local weight = getFruitWeight(fruit) or 0
local value = getFruitValue(fruit) or 0
local mutation = checkMutation(fruit)
local variant = checkVariant(fruit)
table.insert(gardenFruitList, {
Fruit = fruit,
Plant = plant,
Name = fruit.Name,
Weight = weight,
Value = value,
Mutation = mutation,
Variant = variant
})
end
end
end
end
end
end
end
table.sort(gardenFruitList, function(a, b) 
return (a.Value or 0) > (b.Value or 0) 
end)
return gardenFruitList
end
function collectGardenFruit(fruitObj, plantObj)
if not fruitObj then return false end
local prompt = fruitObj:FindFirstChildWhichIsA("ProximityPrompt", true)
if prompt and prompt.Enabled then
fireproximityprompt(prompt, 0)
if plantObj then
task.spawn(function()
pcall(function()
ReplicatedStorage.GameEvents.Crops.Collect:FireServer({plantObj})
end)
end)
end
playCollectSound()
return true
else
if plantObj then
task.spawn(function()
pcall(function()
ReplicatedStorage.GameEvents.Crops.Collect:FireServer({plantObj})
end)
end)
playCollectSound()
return true
end
end
return false
end
Tabs.Main:Button({
Title = "Refresh Garden Fruits",
Callback = function()
gardenFruitList = scanGardenFruits()
if #gardenFruitList > 0 then
local top = gardenFruitList[1]
local mutationText = top.Mutation or "None"
local variantText = top.Variant or "None"
gardenFruitParagraph:SetTitle(top.Name)
gardenFruitParagraph:SetDesc(string.format(
[[Mutation: %s
Weight: %s KG
Value: $%s
Variant: %s] ],
mutationText,
tostring(top.Weight),
tostring(math.floor(top.Value)),
variantText
))
WindUI:Notify({
Title = "Scan Complete",
Content = string.format("Found %d fruit(s). Highest: %s ($%s)", 
#gardenFruitList, top.Name, math.floor(top.Value)),
Duration = 3
})
else
gardenFruitParagraph:SetTitle("No fruits found")
gardenFruitParagraph:SetDesc("No fruits in your garden")
WindUI:Notify({
Title = "Scan Complete",
Content = "No fruits found in your garden",
Duration = 2
})
end
end
})
Tabs.Main:Button({
Title = "Collect Highest Fruit",
Callback = function()
gardenFruitList = scanGardenFruits()
if #gardenFruitList == 0 then
WindUI:Notify({
Title = "Collection Failed",
Content = "No fruits found in your garden",
Duration = 3
})
return
end
local target = gardenFruitList[1]
if target and target.Fruit and target.Plant then
local success = collectGardenFruit(target.Fruit, target.Plant)
if success then
WindUI:Notify({
Title = "Collection Success",
Content = string.format("Collected %s (Value: $%s)", 
target.Name, math.floor(target.Value)),
Duration = 3
})
task.wait(0.5)
gardenFruitList = scanGardenFruits()
if #gardenFruitList > 0 then
local nextFruit = gardenFruitList[1]
gardenFruitParagraph:SetTitle(nextFruit.Name)
gardenFruitParagraph:SetDesc(string.format(
[[Mutation: %s
Weight: %s KG
Value: $%s
Variant: %s] ],
nextFruit.Mutation or "None",
tostring(nextFruit.Weight),
tostring(math.floor(nextFruit.Value)),
nextFruit.Variant or "None"
))
else
gardenFruitParagraph:SetTitle("No fruits found")
gardenFruitParagraph:SetDesc("All fruits collected")
end
else
WindUI:Notify({
Title = "Collection Failed",
Content = "Could not collect fruit. Try refreshing.",
Duration = 3
})
end
else
WindUI:Notify({
Title = "Collection Failed",
Content = "Invalid fruit data",
Duration = 3
})
end
end
})
Tabs.Main:Divider()
Tabs.Main:Section({ Title = "Steal Fruit" })
Tabs.Main:Divider()
fruitList = {}
fruitParagraph = Tabs.Main:Paragraph({
Title = "No fruits found",
Desc = "Click Refresh to scan for fruits"
})

local billboardGui = nil
local billboardAdornee = nil

local function createBillboard(targetFruit)
if billboardGui then
billboardGui:Destroy()
billboardGui = nil
billboardAdornee = nil
end

if not targetFruit then return end

billboardGui = Instance.new("BillboardGui")
billboardGui.Size = UDim2.new(0, 80, 0, 20)
billboardGui.StudsOffset = Vector3.new(0, 3, 0)
billboardGui.AlwaysOnTop = true

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 1, 0)
textLabel.BackgroundTransparency = 1
textLabel.Text = "STEAL TARGET"
textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.GothamBold
textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
textLabel.TextStrokeTransparency = 0
textLabel.Parent = billboardGui

billboardGui.Parent = targetFruit
billboardAdornee = targetFruit
end

local function removeBillboard()
if billboardGui then
billboardGui:Destroy()
billboardGui = nil
billboardAdornee = nil
end
end

local function findProximityPrompt(obj)
if not obj then return nil end
local prompt = obj:FindFirstChild("ProximityPrompt")
if prompt then return prompt end
for _, child in pairs(obj:GetChildren()) do
prompt = findProximityPrompt(child)
if prompt then return prompt end
end
return nil
end

local function buildGetChildrenPath(fruit)
if not fruit then return nil end

local fruitsFolder = fruit.Parent
local plant = fruitsFolder and fruitsFolder.Parent
local plantsPhysical = plant and plant.Parent
local important = plantsPhysical and plantsPhysical.Parent
local plot = important and important.Parent
local farm = plot and plot.Parent

if not (farm and plot and important and plantsPhysical and plant and fruitsFolder) then
return nil
end

local function findIndex(parent, child)
if not parent or not child then return nil end
for i, c in pairs(parent:GetChildren()) do
if c == child then
return i
end
end
return nil
end

local plotIndex = findIndex(farm, plot)
local plantIndex = findIndex(plantsPhysical, plant)
local fruitIndex = findIndex(fruitsFolder, fruit)

if not (plotIndex and plantIndex and fruitIndex) then
return nil
end

local path = string.format(
"workspace.Farm:GetChildren()[%d].Important.Plants_Physical:GetChildren()[%d].Fruits:GetChildren()[%d]",
plotIndex,
plantIndex,
fruitIndex
)

return path
end

Tabs.Main:Button({
Title = "Scan highest value Fruits",
Callback = function()
fruitList = {}
farmFolder = workspace:FindFirstChild("Farm")
if not farmFolder then 
fruitParagraph:SetDesc("Farm folder not found")
return
end

for _, plot in pairs(farmFolder:GetChildren()) do
sign = plot:FindFirstChild("Sign")
owner = sign and sign:GetAttribute("_owner")
if owner and owner ~= LocalPlayer then
important = plot:FindFirstChild("Important")
if important then
plantsPhysical = important:FindFirstChild("Plants_Physical")
if plantsPhysical then
for _, plant in pairs(plantsPhysical:GetChildren()) do
fruitsFolder = plant:FindFirstChild("Fruits")
if fruitsFolder then
for _, fruit in pairs(fruitsFolder:GetChildren()) do
local proximityPrompt = findProximityPrompt(fruit)
if proximityPrompt and proximityPrompt.Enabled == false then
else
weight = fruit:FindFirstChild("Weight")
weightValue = weight and weight.Value or 0
value = 0
pcall(function()
value = require(ReplicatedStorage.Modules.CalculatePlantValue)(fruit)
end)

mutations = {}
for attr, val in pairs(fruit:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end

variant = fruit:FindFirstChild("Variant")
variantName = variant and variant.Value or "None"

local path = buildGetChildrenPath(fruit)

table.insert(fruitList, {
Fruit = fruit,
Name = fruit.Name,
Owner = owner,
Weight = weightValue,
Value = value,
Mutations = mutations,
Variant = variantName,
Plant = plant,
ProximityPrompt = proximityPrompt,
Path = path
})
end
end
end
end
end
end
end
end

table.sort(fruitList, function(a, b) return (a.Value or 0) > (b.Value or 0) end)

if #fruitList > 0 then
top = fruitList[1]
mutationText = #top.Mutations > 0 and table.concat(top.Mutations, ", ") or "None"
fruitParagraph:SetTitle(top.Name)
fruitParagraph:SetDesc(string.format(
"Owner: %s\nMutation: %s\nWeight: %s\nValue: $%s\nVariant: %s",
top.Owner,
mutationText,
tostring(top.Weight),
tostring(math.floor(top.Value)),
top.Variant
))
createBillboard(top.Fruit)
else
fruitParagraph:SetTitle("No fruits found")
fruitParagraph:SetDesc("No fruits available to steal from other players")
removeBillboard()
end
end
})

Tabs.Main:Button({
Title = "Steal Now",
Callback = function()
if #fruitList == 0 then 
WindUI:Notify({
Title = "Steal Failed",
Content = "No fruits available to steal",
Duration = 3
})
return 
end

target = fruitList[1]
if target and target.Path then
local collectEvent = ReplicatedStorage.GameEvents.Crops.Collect
if collectEvent then
local loadstringFunc = loadstring("return " .. target.Path)
if loadstringFunc then
local success, result = pcall(loadstringFunc)
if success and result then
collectEvent:FireServer({result})
WindUI:Notify({
Title = "Steal Attempt",
Content = string.format("Attempted to steal %s from %s", target.Name, target.Owner),
Duration = 3
})
removeBillboard()
else
WindUI:Notify({
Title = "Steal Failed",
Content = "Failed to execute path to fruit",
Duration = 3
})
end
else
WindUI:Notify({
Title = "Steal Failed",
Content = "Invalid path format",
Duration = 3
})
end
else
WindUI:Notify({
Title = "Steal Failed",
Content = "Collect event not found",
Duration = 3
})
end
else
WindUI:Notify({
Title = "Steal Failed",
Content = "No path found for fruit",
Duration = 3
})
end
end
})
Tabs.Main:Button({
Title = "Add Billboard",
Callback = function()
if #fruitList > 0 then
createBillboard(fruitList[1].Fruit)
WindUI:Notify({
Title = "Billboard Added",
Content = "Steal target billboard is now visible",
Duration = 2
})
else
WindUI:Notify({
Title = "No Target",
Content = "Scan for fruits first",
Duration = 2
})
end
end
})

Tabs.Main:Button({
Title = "Remove Billboard",
Callback = function()
removeBillboard()
WindUI:Notify({
Title = "Billboard Removed",
Content = "Steal target billboard has been removed",
Duration = 2
})
end
})
Tabs.Main:Section({ Title = "Scan Best Fruit in Inventory" })
Tabs.Main:Divider()
inventoryList = {}
inventoryParagraph = Tabs.Main:Paragraph({
Title = "No items in inventory",
Desc = "Click Find Highest price to scan your inventory"
})
Tabs.Main:Button({
Title = "Find Highest price",
Callback = function()
inventoryList = {}
if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") and item:FindFirstChild("Item_Seed") then
value = 0
pcall(function()
value = require(ReplicatedStorage.Modules.CalculatePlantValue)(item)
end)
weightObj = item:FindFirstChild("Weight")
weight = weightObj and weightObj.Value or 0
mutations = {}
for attr, val in pairs(item:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end
variant = item:FindFirstChild("Variant")
variantName = variant and variant.Value or "None"
table.insert(inventoryList, {
Item = item,
Name = item.Name,
Value = value,
Weight = weight,
Mutations = mutations,
Variant = variantName
})
end
end
end
if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") and item:FindFirstChild("Item_Seed") then
value = 0
pcall(function()
value = require(ReplicatedStorage.Modules.CalculatePlantValue)(item)
end)
weightObj = item:FindFirstChild("Weight")
weight = weightObj and weightObj.Value or 0
mutations = {}
for attr, val in pairs(item:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end
variant = item:FindFirstChild("Variant")
variantName = variant and variant.Value or "None"
table.insert(inventoryList, {
Item = item,
Name = item.Name,
Value = value,
Weight = weight,
Mutations = mutations,
Variant = variantName
})
end
end
end
table.sort(inventoryList, function(a, b) return (a.Value or 0) > (b.Value or 0) end)
if #inventoryList > 0 then
top = inventoryList[1]
mutationText = #top.Mutations > 0 and table.concat(top.Mutations, ", ") or "None"
cleanTitle = top.Name:gsub("%[.-%]", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
inventoryParagraph:SetTitle(cleanTitle)
inventoryParagraph:SetDesc(string.format(
"Weight: %s KG\nValue: $%s\nMutation: %s\nVariant: %s",
tostring(top.Weight),
tostring(math.floor(top.Value)),
mutationText,
top.Variant
))
else
inventoryParagraph:SetTitle("No fruits found")
inventoryParagraph:SetDesc("No fruits in your inventory")
end
end
})
Tabs.Main:Button({
Title = "Equip Best Item",
Callback = function()
if #inventoryList == 0 then 
WindUI:Notify({
Title = "Equip Failed",
Content = "No fruits in inventory",
Duration = 3
})
return 
end
target = inventoryList[1]
if target and target.Item then
Character = LocalPlayer.Character
Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
if Humanoid and target.Item.Parent == LocalPlayer.Backpack then
Humanoid:EquipTool(target.Item)
WindUI:Notify({
Title = "Equipped",
Content = string.format("Equipped %s (Value: $%s)", target.Name, math.floor(target.Value)),
Duration = 3
})
end
end
end
})
Tabs.Main:Divider()
Tabs.Main:Section({ Title = "Scan Best Pet in Inventory" })
Tabs.Main:Divider()
petList = {}
petParagraph = Tabs.Main:Paragraph({
Title = "No pets in inventory",
Desc = "Click Find Best Pet to scan your pets"
})
Tabs.Main:Button({
Title = "Find Best Pet",
Callback = function()
petList = {}
CalculatePetValue = require(ReplicatedStorage.Modules.CalculatePetValue)
scanFunction = function(item)
if item:IsA("Tool") and item:GetAttribute("ItemType") == "Pet" then
value = 0
pcall(function()
value = CalculatePetValue(item)
end)
mutations = {}
for attr, val in pairs(item:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end
level = item:GetAttribute("Level") or 1
itemName = item.Name
weight = 0
weightMatch = itemName:match("%[(%d+%.?%d*)%s*KG%]")
if not weightMatch then
weightMatch = itemName:match("%[(%d+)%s*KG%]")
end
if weightMatch then
weight = tonumber(weightMatch) or 0
end
age = 0
ageMatch = itemName:match("%[Age%s*(%d+)%]")
if not ageMatch then
ageMatch = itemName:match("%[(%d+)%s*Age%]")
end
if ageMatch then
age = tonumber(ageMatch) or 0
end
cleanName = itemName
cleanName = cleanName:gsub("%[%d+%.?%d*%s*KG%]", "")
cleanName = cleanName:gsub("%[Age%s*%d+%]", "")
cleanName = cleanName:gsub("%[%d+%s*Age%]", "")
cleanName = cleanName:gsub("%s+", " ")
cleanName = cleanName:gsub("^%s*(.-)%s*$", "%1")
if #cleanName == 0 then
cleanName = itemName
end
table.insert(petList, {
Pet = item,
Name = itemName,
CleanName = cleanName,
Value = value,
Mutations = mutations,
Level = level,
Age = age,
Weight = weight
})
end
end
if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
scanFunction(item)
end
end
if Character then
for _, item in pairs(Character:GetChildren()) do
scanFunction(item)
end
end
table.sort(petList, function(a, b) return (a.Value or 0) > (b.Value or 0) end)
if #petList > 0 then
top = petList[1]
mutationText = #top.Mutations > 0 and table.concat(top.Mutations, ", ") or "None"
displayText = string.format("Value: $%s\nLevel: %s\nMutation: %s", 
tostring(math.floor(top.Value)),
tostring(top.Level),
mutationText
)
if top.Weight and top.Weight > 0 then
displayText = displayText .. string.format("\nWeight: %s KG", tostring(top.Weight))
end
if top.Age and top.Age > 0 then
displayText = displayText .. string.format("\nAge: %s", tostring(top.Age))
end
petParagraph:SetTitle(top.CleanName)
petParagraph:SetDesc(displayText)
else
petParagraph:SetTitle("No pets found")
petParagraph:SetDesc("No pets in your inventory")
end
end
})
Tabs.Main:Button({
Title = "Equip Best Pet",
Callback = function()
if #petList == 0 then 
WindUI:Notify({
Title = "Equip Failed",
Content = "No pets in inventory",
Duration = 3
})
return 
end
target = petList[1]
if target and target.Pet then
Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
if Humanoid and target.Pet.Parent == LocalPlayer.Backpack then
Humanoid:EquipTool(target.Pet)
WindUI:Notify({
Title = "Equipped",
Content = string.format("Equipped %s (Value: $%s)", target.CleanName, math.floor(target.Value)),
Duration = 3
})
end
end
end
})
Tabs.Main:Divider()
Tabs.Main:Section({ Title = "Current Hand Scanner" })
Tabs.Main:Divider()
handParagraph = Tabs.Main:Paragraph({
Title = "Nothing in hand",
Desc = "Check your current item"
})
Tabs.Main:Button({
Title = "Calculate Hand Value",
Callback = function()
handItem = nil
if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
handItem = item
break
end
end
end
if not handItem then 
handParagraph:SetTitle("Nothing in hand")
handParagraph:SetDesc("Your hand is empty")
WindUI:Notify({
Title = "Calculate Failed",
Content = "Nothing in your hand",
Duration = 3
})
return 
end
value = 0
itemType = handItem:GetAttribute("ItemType")
itemName = handItem.Name
cleanTitle = itemName:gsub("%[.-%]", ""):gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
if itemType == "Pet" then
CalculatePetValue = require(ReplicatedStorage.Modules.CalculatePetValue)
pcall(function()
value = CalculatePetValue(handItem)
end)
mutations = {}
for attr, val in pairs(handItem:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end
level = handItem:GetAttribute("Level") or 1
mutationText = #mutations > 0 and table.concat(mutations, ", ") or "None"
weight = 0
weightMatch = itemName:match("%[(%d+%.?%d*)%s*KG%]")
if not weightMatch then
weightMatch = itemName:match("%[(%d+)%s*KG%]")
end
if weightMatch then
weight = tonumber(weightMatch) or 0
end
age = 0
ageMatch = itemName:match("%[Age%s*(%d+)%]")
if not ageMatch then
ageMatch = itemName:match("%[(%d+)%s*Age%]")
end
if ageMatch then
age = tonumber(ageMatch) or 0
end
weightObj = handItem:FindFirstChild("Weight")
if weightObj and weight == 0 then
weight = weightObj.Value
end
displayText = string.format("Value: $%s\nType: Pet\nLevel: %s\nMutation: %s", 
tostring(math.floor(value)),
tostring(level),
mutationText
)
if weight and weight > 0 then
displayText = displayText .. string.format("\nWeight: %s KG", tostring(weight))
end
if age and age > 0 then
displayText = displayText .. string.format("\nAge: %s", tostring(age))
end
handParagraph:SetTitle(cleanTitle)
handParagraph:SetDesc(displayText)
else
pcall(function()
value = require(ReplicatedStorage.Modules.CalculatePlantValue)(handItem)
end)
weightObj = handItem:FindFirstChild("Weight")
weight = weightObj and weightObj.Value or 0
mutations = {}
for attr, val in pairs(handItem:GetAttributes()) do
if type(val) == "boolean" and val == true then
table.insert(mutations, attr)
end
end
variant = handItem:FindFirstChild("Variant")
variantName = variant and variant.Value or "None"
mutationText = #mutations > 0 and table.concat(mutations, ", ") or "None"
handParagraph:SetTitle(cleanTitle)
handParagraph:SetDesc(string.format(
"Value: $%s\nType: %s\nWeight: %s KG\nMutation: %s\nVariant: %s",
tostring(math.floor(value)),
itemType or "Fruit",
tostring(weight),
mutationText,
variantName
))
end
WindUI:Notify({
Title = "Hand Value",
Content = string.format("%s: $%s", cleanTitle, math.floor(value)),
Duration = 4
})
end
})
Tabs.Player:Section({ Title = "Player", TextSize = 40 })
Tabs.Player:Divider()
function onCharacterAdded(newCharacter)
Character = newCharacter
Humanoid = Character:WaitForChild("Humanoid", 5)
rootPart = Character:WaitForChild("HumanoidRootPart", 5)
if JumpBoost and Humanoid then
Humanoid.JumpPower = JumpPower
Humanoid.JumpHeight = JumpPower
setupJumpBoost()
end
if SpeedHack and Humanoid then
Humanoid.WalkSpeed = SpeedValue
end
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if LocalPlayer.Character then
onCharacterAdded(LocalPlayer.Character)
end
local InfiniteJump = {
State = nil,
Connection = nil,
Enabled = false
}

local function StartInfiniteJump()
if InfiniteJump.Enabled then return end
InfiniteJump.Enabled = true
InfiniteJump.Connection = RunService.RenderStepped:Connect(function()
if not InfiniteJump.Enabled then return end
if not Humanoid then
if LocalPlayer.Character then
Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
if not Humanoid then return end
end
if Humanoid.Jump then
if InfiniteJump.State then
Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
InfiniteJump.State = false
end
else
InfiniteJump.State = true
end
end)
end

local function StopInfiniteJump()
InfiniteJump.Enabled = false
if InfiniteJump.Connection then
InfiniteJump.Connection:Disconnect()
InfiniteJump.Connection = nil
end
InfiniteJump.State = nil
end


InfiniteJumpToggle = Tabs.Player:Toggle({
Title = "Infinite Jump",
Flag = "InfiniteJumpToggle",
Value = false,
Callback = function(state)
if state then
StartInfiniteJump()
else
StopInfiniteJump()
end
end
})
Tabs.Player:Space()
SpeedToggle = Tabs.Player:Toggle({
Title = "Speed Hack",
Flag = "SpeedToggle",
Value = SpeedHack,
Callback = function(state)
SpeedHack = state
if state and Humanoid then
Humanoid.WalkSpeed = SpeedValue
elseif Humanoid then
Humanoid.WalkSpeed = 16
end
end
})
SpeedSlider = Tabs.Player:Slider({
Title = "Speed Value",
Flag = "SpeedSlider",
Desc = "Adjust walk speed",
Value = { Min = 16, Max = 200, Default = SpeedValue, Step = 1 },
Callback = function(value)
SpeedValue = value
if SpeedHack and Humanoid then
Humanoid.WalkSpeed = value
end
end
})
Tabs.Player:Space()
Noclip = nil
Clip = nil
function noclip()
Clip = false
function Nocl()
if Clip == false and LocalPlayer.Character ~= nil then
for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
if v:IsA('BasePart') and v.CanCollide then
v.CanCollide = false
end
end
end
wait(0.21)
end
Noclip = RunService.Stepped:Connect(Nocl)
end
function clip()
if Noclip then 
Noclip:Disconnect() 
end
Clip = true
if LocalPlayer.Character then
for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
if v:IsA('BasePart') then
v.CanCollide = true
end
end
end
end
NoclipToggle = Tabs.Player:Toggle({
Title = "Noclip",
Flag = "NoclipToggle",
Value = Noclip,
Callback = function(state)
Noclip = state
if state then
noclip()
else
clip()
end
end
})
IsOnMobile = false
xpcall(function()
IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)
if IsOnMobile then
LocalPlayer:WaitForChild("PlayerGui")
local touchGui = LocalPlayer.PlayerGui:WaitForChild("TouchGui")
local touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
local originalJumpButton = touchControlFrame:WaitForChild("JumpButton")
local DownWardJumpBtn = nil
function createDownwardButton()
if DownWardJumpBtn and DownWardJumpBtn.Parent then
DownWardJumpBtn:Destroy()
end
DownWardJumpBtn = Instance.new("ImageButton")
DownWardJumpBtn.Name = "DownWardJumpBtn"
DownWardJumpBtn.Size = originalJumpButton.Size
DownWardJumpBtn.Image = originalJumpButton.Image
DownWardJumpBtn.ImageRectOffset = originalJumpButton.ImageRectOffset
DownWardJumpBtn.ImageRectSize = originalJumpButton.ImageRectSize
DownWardJumpBtn.BackgroundTransparency = 1
DownWardJumpBtn.AnchorPoint = Vector2.new(1, 0)
DownWardJumpBtn.AutoButtonColor = false
DownWardJumpBtn.Position = UDim2.new(1, 0, originalJumpButton.Position.Y.Scale, originalJumpButton.Position.Y.Offset)
DownWardJumpBtn.Rotation = 180
local originalRectOffset = originalJumpButton.ImageRectOffset
local isHoldingDown = false
DownWardJumpBtn.MouseButton1Down:Connect(function()
isHoldingDown = true
DownWardJumpBtn.ImageRectOffset = Vector2.new(146, 146)
flyDownPressed = true
end)
DownWardJumpBtn.MouseButton1Up:Connect(function()
if isHoldingDown then
isHoldingDown = false
DownWardJumpBtn.ImageRectOffset = originalRectOffset
flyDownPressed = false
end
end)
DownWardJumpBtn.MouseLeave:Connect(function()
if isHoldingDown then
isHoldingDown = false
DownWardJumpBtn.ImageRectOffset = originalRectOffset
flyDownPressed = false
end
end)
DownWardJumpBtn.Parent = touchControlFrame
function preventOverlap()
if not DownWardJumpBtn or not DownWardJumpBtn.Parent then return end
local buttonWidth = DownWardJumpBtn.AbsoluteSize.X
local originalButton = touchControlFrame:FindFirstChild("JumpButton")
if originalButton then
local originalRightEdge = originalButton.AbsolutePosition.X + originalButton.AbsoluteSize.X
local duplicateLeftEdge = DownWardJumpBtn.AbsolutePosition.X
local distance = duplicateLeftEdge - originalRightEdge
if distance < 1 then
local neededOffset = 1 - distance
local newXOffset = DownWardJumpBtn.Position.X.Offset - neededOffset
DownWardJumpBtn.Position = UDim2.new(1, newXOffset, DownWardJumpBtn.Position.Y.Scale, DownWardJumpBtn.Position.Y.Offset)
elseif distance > 1 then
local neededOffset = distance - 1
local newXOffset = DownWardJumpBtn.Position.X.Offset + neededOffset
DownWardJumpBtn.Position = UDim2.new(1, newXOffset, DownWardJumpBtn.Position.Y.Scale, DownWardJumpBtn.Position.Y.Offset)
end
end
end
DownWardJumpBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(preventOverlap)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(preventOverlap)
preventOverlap()
end
local isHoldingJump = false
local originalJumpRectOffset = originalJumpButton.ImageRectOffset
originalJumpButton.MouseButton1Down:Connect(function()
isHoldingJump = true
originalJumpButton.ImageRectOffset = Vector2.new(146, 146)
flyUpPressed = true
end)
originalJumpButton.MouseButton1Up:Connect(function()
if isHoldingJump then
isHoldingJump = false
originalJumpButton.ImageRectOffset = originalJumpRectOffset
flyUpPressed = false
end
end)
originalJumpButton.MouseLeave:Connect(function()
if isHoldingJump then
isHoldingJump = false
originalJumpButton.ImageRectOffset = originalJumpRectOffset
flyUpPressed = false
end
end)
end
FLYING = false
flyspeed = 5
flyKeyDown = nil
flyKeyUp = nil
flyVelocityHandlerName = "FlyVelocity_" .. math.random(1000, 9999)
flyGyroHandlerName = "FlyGyro_" .. math.random(1000, 9999)
mfly1 = nil
mfly2 = nil
flyUpPressed = false
flyDownPressed = false
function getRoot(Humanoid)
return Character and (Character:FindFirstChild("HumanoidRootPart") or Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso"))
end
function unmobilefly(speaker)
pcall(function()
FLYING = false
flyUpPressed = false
flyDownPressed = false
root = getRoot(speaker.Character)
if root then
bv = root:FindFirstChild(flyVelocityHandlerName)
bg = root:FindFirstChild(flyGyroHandlerName)
if bv then bv:Destroy() end
if bg then bg:Destroy() end
end
if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
end
if mfly1 then mfly1:Disconnect() mfly1 = nil end
if mfly2 then mfly2:Disconnect() mfly2 = nil end
if DownWardJumpBtn and DownWardJumpBtn.Parent then
DownWardJumpBtn:Destroy()
DownWardJumpBtn = nil
end
end)
end
function mobilefly(speaker)
unmobilefly(speaker)
FLYING = true
createDownwardButton()
root = getRoot(speaker.Character)
if not root then return end
camera = workspace.CurrentCamera
v3none = Vector3.new()
v3zero = Vector3.new(0, 0, 0)
v3inf = Vector3.new(9e9, 9e9, 9e9)
controlModule = nil
pcall(function()
controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)
bv = Instance.new("BodyVelocity")
bv.Name = flyVelocityHandlerName
bv.Parent = root
bv.MaxForce = v3zero
bv.Velocity = v3zero
bg = Instance.new("BodyGyro")
bg.Name = flyGyroHandlerName
bg.Parent = root
bg.MaxTorque = v3inf
bg.P = 1000
bg.D = 50
mfly2 = RunService.RenderStepped:Connect(function()
currentRoot = getRoot(speaker.Character)
currentCamera = workspace.CurrentCamera
currentHumanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
if currentHumanoid and currentRoot and currentRoot:FindFirstChild(flyVelocityHandlerName) and currentRoot:FindFirstChild(flyGyroHandlerName) then
VelocityHandler = currentRoot:FindFirstChild(flyVelocityHandlerName)
GyroHandler = currentRoot:FindFirstChild(flyGyroHandlerName)
VelocityHandler.MaxForce = v3inf
GyroHandler.MaxTorque = v3inf
currentHumanoid.PlatformStand = true
GyroHandler.CFrame = currentCamera.CoordinateFrame
moveVector = Vector3.new(0, 0, 0)
if controlModule then
direction = controlModule:GetMoveVector()
speed = flyspeed * 50
moveVector = (currentCamera.CFrame.RightVector * direction.X * speed) +
(-currentCamera.CFrame.LookVector * direction.Z * speed)
end
if flyUpPressed then
moveVector = moveVector + Vector3.new(0, flyspeed * 50, 0)
end
if flyDownPressed then
moveVector = moveVector - Vector3.new(0, flyspeed * 50, 0)
end
VelocityHandler.Velocity = moveVector
end
end)
end
function pcfly()
plr = Players.LocalPlayer
char = plr.Character or plr.CharacterAdded:Wait()
Humanoid = char:FindFirstChildOfClass("Humanoid")
if not Humanoid then
repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
Humanoid = char:FindFirstChildOfClass("Humanoid")
end
if flyKeyDown or flyKeyUp then
flyKeyDown:Disconnect()
flyKeyUp:Disconnect()
end
T = getRoot(char)
if not T then return end
WPressed = false
SPressed = false
APressed = false
DPressed = false
SpacePressed = false
CtrlPressed = false
function FLY()
FLYING = true
BG = Instance.new('BodyGyro')
BV = Instance.new('BodyVelocity')
BG.P = 9e4
BG.Parent = T
BV.Parent = T
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.CFrame = T.CFrame
BV.Velocity = Vector3.new(0, 0, 0)
BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
task.spawn(function()
while FLYING do
task.wait()
camera = workspace.CurrentCamera
Humanoid.PlatformStand = true
moveDirection = Vector3.new(0, 0, 0)
if WPressed then
moveDirection = moveDirection + camera.CFrame.LookVector * flyspeed
end
if SPressed then
moveDirection = moveDirection - camera.CFrame.LookVector * flyspeed
end
if APressed then
moveDirection = moveDirection - camera.CFrame.RightVector * flyspeed
end
if DPressed then
moveDirection = moveDirection + camera.CFrame.RightVector * flyspeed
end
if SpacePressed then
moveDirection = moveDirection + Vector3.new(0, flyspeed * 2, 0)
end
if CtrlPressed then
moveDirection = moveDirection - Vector3.new(0, flyspeed * 2, 0)
end
BV.Velocity = moveDirection * 16
BG.CFrame = camera.CFrame
end
BG:Destroy()
BV:Destroy()
if Humanoid then Humanoid.PlatformStand = false end
end)
end
flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = true
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = true
elseif input.KeyCode == Enum.KeyCode.A then
APressed = true
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = true
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = true
elseif input.KeyCode == Enum.KeyCode.LeftControl then
CtrlPressed = true
end
pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
end)
flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = false
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = false
elseif input.KeyCode == Enum.KeyCode.A then
APressed = false
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = false
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = false
elseif input.KeyCode == Enum.KeyCode.LeftControl then
CtrlPressed = false
end
end)
FLY()
end
function NOFLY()
FLYING = false
flyUpPressed = false
flyDownPressed = false
if flyKeyDown then 
flyKeyDown:Disconnect()
flyKeyDown = nil
end
if flyKeyUp then 
flyKeyUp:Disconnect()
flyKeyUp = nil
end
if IsOnMobile then
unmobilefly(Players.LocalPlayer)
else
if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
end
root = getRoot(Players.LocalPlayer.Character)
if root then
root.Velocity = Vector3.new(0, 0, 0)
end
end
pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end
function onCharacterAdded()
if FlyToggle and FlyToggle.Value then
task.wait(1)
if IsOnMobile then
mobilefly(Players.LocalPlayer)
else
pcfly()
end
end
end
Players.LocalPlayer.CharacterAdded:Connect(function()
NOFLY()
onCharacterAdded()
end)
Tabs.Player:Space()
FlyToggle = Tabs.Player:Toggle({
Title = "Fly",
Flag = "FlyToggle",
Value = false,
Callback = function(state)
if state then
if IsOnMobile then
mobilefly(Players.LocalPlayer)
else
pcfly()
end
else
NOFLY()
end
end
})
FlySpeedInput = Tabs.Player:Input({
Title = "Fly Speed",
Flag = "FlySpeedInput",
Placeholder = "Enter speed value",
Value = tostring(flyspeed),
NumbersOnly = true,
Callback = function(value)
speed = tonumber(value)
if speed and speed > 0 then
flyspeed = speed
end
end
})
ShowFlyButtonToggle = Tabs.Player:Toggle({
Title = "Fly Button",
Flag = "ShowFlyButton",
Value = false,
Callback = function(state)
IY = IY or {}
IY.FlightBtn = state
if ButtonLib and ButtonLib.Flight then
ButtonLib.Flight:SetVisible(state)
end
end
})
ButtonLib.Create:Toggle({
Text = "Flight",
Flag = "Flight",
Default = false,
Visible = false,
Callback = function(s) 
if FlyToggle then
FlyToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)
Tabs.Player:Space()
ToggleTpwalk = false
TpwalkConnection = nil
function Tpwalking()
if ToggleTpwalk and Character and Humanoid and rootPart then
moveDirection = Humanoid.MoveDirection
moveDistance = TpwalkValue
origin = rootPart.Position
direction = moveDirection * moveDistance
targetPosition = origin + direction
raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {Character}
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastResult = workspace:Raycast(origin, direction, raycastParams)
if raycastResult then
hitPosition = raycastResult.Position
distanceToHit = (hitPosition - origin).Magnitude
if distanceToHit < math.abs(moveDistance) then
targetPosition = origin + (direction.Unit * (distanceToHit - 0.1))
end
end
rootPart.CFrame = CFrame.new(targetPosition) * rootPart.CFrame.Rotation
rootPart.CanCollide = true
end
end
function startTpwalk()
ToggleTpwalk = true
if TpwalkConnection then
TpwalkConnection:Disconnect()
end
TpwalkConnection = RunService.Heartbeat:Connect(Tpwalking)
end
function stopTpwalk()
ToggleTpwalk = false
if TpwalkConnection then
TpwalkConnection:Disconnect()
TpwalkConnection = nil
end
if rootPart then
rootPart.CanCollide = false
end
end
TPWALKToggle = Tabs.Player:Toggle({
Title = "TP WALK",
Flag = "TPWALKToggle",
Value = TPWALK,
Callback = function(state)
TPWALK = state
if state then
startTpwalk()
else
stopTpwalk()
end
end
})
TPWALKSlider = Tabs.Player:Slider({
Title = "TPWALK VALUE",
Flag = "TPWALKSlider",
Desc = "Adjust TPWALK speed",
Value = { Min = 1, Max = 200, Default = TpwalkValue, Step = 1 },
Callback = function(value)
TpwalkValue = value
end
})
Tabs.Player:Space()
jumpCount = 0
MAX_JUMPS = math.huge
function setupJumpBoost()
if not Character or not Humanoid then return end
Humanoid.StateChanged:Connect(function(oldState, newState)
if newState == Enum.HumanoidStateType.Landed then
jumpCount = 0
end
end)
Humanoid.Jumping:Connect(function(isJumping)
if isJumping and JumpBoost and jumpCount < MAX_JUMPS then
jumpCount = jumpCount + 1
Humanoid.JumpHeight = JumpPower
if jumpCount > 1 then
rootPart:ApplyImpulse(Vector3.new(0, JumpPower * rootPart.Mass, 0))
end
end
end)
end
function startJumpBoost()
if Humanoid then
Humanoid.JumpPower = JumpPower
Humanoid.JumpHeight = JumpPower
end
setupJumpBoost()
end
function stopJumpBoost()
jumpCount = 0
if Humanoid then
Humanoid.JumpPower = 50
Humanoid.JumpHeight = 50
end
end
JumpBoostToggle = Tabs.Player:Toggle({
Title = "Jump Height",
Flag = "JumpBoostToggle",
Value = JumpBoost,
Callback = function(state)
JumpBoost = state
if state then
startJumpBoost()
else
stopJumpBoost()
end
end
})
JumpBoostSlider = Tabs.Player:Slider({
Title = "Jump Power",
Flag = "JumpBoostSlider",
Desc = "Adjust jump height",
Value = { Min = 1, Max = 200, Default = JumpPower, Step = 1 },
Callback = function(value)
JumpPower = value
if JumpBoost then
if Humanoid then
Humanoid.JumpPower = JumpPower
Humanoid.JumpHeight = JumpPower
end
end
end
})
Tabs.Player:Space()
Tabs.Player:Button({
Title = "Force Reset Character",
Callback = function()
RblxCallDialog({
Title = "Reset Character",
Desc = [[Are you sure you want to Reset Character? Press ''Reset'' to continue] ],
Button1 = {
Title = "Cancel",
Type = "GreyOutline",
},
Button2 = {
Title = "Reset",
Type = "White",
WaitTimeClick = 5,
Callback = function()
local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
if hum then hum.Health = 0 end
end
}
})
end
})
Tabs.Garden:Section({ Title = "Auto Plant", TextSize = 20 })
AutoPlantEnabled = false
AutoPlantTask = nil
AutoPlantSelectedSeeds = {}
AutoPlantBlacklistedSeeds = {}
AutoPlantMode = "Random"
AutoPlantEquipSeed = true
AutoPlantDelay = 0.1
GameEvents = ReplicatedStorage.GameEvents
Plant_RE = GameEvents.Plant_RE
seedDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("SeedData")
function LoadSeedNames()
local dropdownItems = {}
local success, seedData = pcall(require, seedDataModule)
if success then
local seedsList = {}
for seedName, seedInfo in pairs(seedData) do
if seedInfo.SeedName and not string.find(seedName:lower(), "pack") then
local rarity = seedInfo.SeedRarity or "Unknown"
table.insert(seedsList, {
Name = seedName,
DisplayName = seedInfo.SeedName,
Icon = seedInfo.FruitIcon or seedInfo.Asset or "",
Rarity = rarity
})
end
end
table.sort(seedsList, function(a, b)
return a.DisplayName < b.DisplayName
end)
for _, seed in ipairs(seedsList) do
table.insert(dropdownItems, {
Title = seed.DisplayName,
Desc = "Rarity: " .. seed.Rarity,
Icon = seed.Icon,
Value = seed.Name,
Data = {Name = seed.Name, DisplayName = seed.DisplayName, Rarity = seed.Rarity}
})
end
end
return dropdownItems
end
function GetEquippedSeed()
if #AutoPlantSelectedSeeds > 0 then
for _, container in ipairs({Character, Backpack}) do
for _, tool in ipairs(container:GetChildren()) do
if tool:IsA("Tool") then
local itemType = tool:GetAttribute("ItemType")
local seedName = tool:GetAttribute("ItemName") or tool:GetAttribute("Seed") or tool.Name
if (itemType and itemType == "Seed") or (tool.Name:find("Seed") and not tool.Name:find("Pack")) then
for _, selected in ipairs(AutoPlantSelectedSeeds) do
if seedName == selected then
return tool, seedName
end
end
end
end
end
end
else
for _, container in ipairs({Character, Backpack}) do
for _, tool in ipairs(container:GetChildren()) do
if tool:IsA("Tool") then
local itemType = tool:GetAttribute("ItemType")
local seedName = tool:GetAttribute("ItemName") or tool:GetAttribute("Seed") or tool.Name
if (itemType and itemType == "Seed") or (tool.Name:find("Seed") and not tool.Name:find("Pack")) then
if #AutoPlantBlacklistedSeeds == 0 or not table.find(AutoPlantBlacklistedSeeds, seedName) then
return tool, seedName
end
end
end
end
end
end
return nil, nil
end
function EquipSeed(tool)
if tool and AutoPlantEquipSeed then
local humanoid = Character:FindFirstChildOfClass("Humanoid")
if humanoid and tool.Parent == Backpack then
humanoid:EquipTool(tool)
task.wait(0.1)
end
end
end
function GetPlantingPosition()
if not Character then return Vector3.new(0, 4, 0) end
if AutoPlantMode == "Under LocalPlayer" then
local hrp = Character:FindFirstChild("HumanoidRootPart")
if hrp then
return hrp.Position + Vector3.new(0, -2, 0)
end
return Vector3.new(0, 4, 0)
else
local hrp = Character:FindFirstChild("HumanoidRootPart")
if hrp then
local basePos = hrp.Position
local offsetX = math.random(-20, 20)
local offsetZ = math.random(-20, 20)
return basePos + Vector3.new(offsetX, -2, offsetZ)
end
return Vector3.new(math.random(-50, 50), 4, math.random(-50, 50))
end
end
function PlantSeed()
if not Plant_RE then return false end
local tool, seedName = GetEquippedSeed()
if not tool then return false end
EquipSeed(tool)
local position = GetPlantingPosition()
local success = pcall(function()
Plant_RE:FireServer(position, seedName)
end)
return success
end
function StartAutoPlant()
AutoPlantTask = task.spawn(function()
while AutoPlantEnabled do
PlantSeed()
task.wait(AutoPlantDelay)
for i = 1, 5 do
if not AutoPlantEnabled then break end
PlantSeed()
end
task.wait(0.05)
end
end)
end
AutoPlantWhitelistDropdown = Tabs.Garden:Dropdown({
Title = "Select Seed (Whitelist)",
Values = {{Title = "Click Refresh Whitelist", Icon = "refresh-cw"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options)
AutoPlantSelectedSeeds = {}
for _, option in ipairs(options) do
if option.Value then
table.insert(AutoPlantSelectedSeeds, option.Value)
end
end
end
})
Tabs.Garden:Button({
Title = "Refresh Whitelist",
Icon = "refresh-cw",
Callback = function()
local items = LoadSeedNames()
if #items > 0 then
AutoPlantWhitelistDropdown:Refresh(items, {})
else
AutoPlantWhitelistDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle"}})
end
end
})
AutoPlantBlacklistDropdown = Tabs.Garden:Dropdown({
Title = "Blacklist Seeds",
Values = {{Title = "Click Refresh Blacklist", Icon = "refresh-cw"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options)
AutoPlantBlacklistedSeeds = {}
for _, option in ipairs(options) do
if option.Value then
table.insert(AutoPlantBlacklistedSeeds, option.Value)
end
end
end
})
Tabs.Garden:Button({
Title = "Refresh Blacklist",
Icon = "refresh-cw",
Callback = function()
local items = LoadSeedNames()
if #items > 0 then
AutoPlantBlacklistDropdown:Refresh(items, {})
else
AutoPlantBlacklistDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle"}})
end
end
})
AutoPlantModeDropdown = Tabs.Garden:Dropdown({
Title = "Select Mode",
Values = {
{Title = "Random", Icon = "shuffle", Value = "Random"},
{Title = "Under LocalPlayer", Icon = "user", Value = "Under LocalPlayer"}
},
Value = {Title = "Random", Icon = "shuffle", Value = "Random"},
Callback = function(option)
AutoPlantMode = option.Value
end
})
AutoPlantEquipToggle = Tabs.Garden:Toggle({
Title = "Auto Equip Seed",
Value = true,
Callback = function(state)
AutoPlantEquipSeed = state
end
})
AutoPlantToggle = Tabs.Garden:Toggle({
Title = "Auto Plant",
Value = false,
Callback = function(state)
AutoPlantEnabled = state
if state then
StartAutoPlant()
elseif AutoPlantTask then
task.cancel(AutoPlantTask)
AutoPlantTask = nil
end
end
})
AutoPlantDelaySlider = Tabs.Garden:Slider({
Title = "Auto plant Delay",
Step = 0.001,
Value = {Min = 0.001, Max = 2, Default = 0.1},
Callback = function(value)
AutoPlantDelay = value
end
})
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

fruitAuraEnabled = false
fruitAuraDelay = 0.01
fruitAuraRange = 1
fruitAuraThread = nil
fruitAuraConnection = nil
fruitAuraTimer = 0
PickupSoundEvent = ReplicatedStorage.GameEvents:FindFirstChild("PickupSound") or ReplicatedStorage.GameEvents:FindFirstChild("PickupEvent")
fruitWhitelist = {}
fruitBlacklist = {}
mutationWhitelist = {}
mutationBlacklist = {}
variantWhitelist = {}
variantBlacklist = {}
fruitWhitelistNormalized = {}
fruitBlacklistNormalized = {}
mutationWhitelistNormalized = {}
mutationBlacklistNormalized = {}
variantWhitelistNormalized = {}
variantBlacklistNormalized = {}
myFarmPlotsCache = {}
lastFarmUpdate = 0
farmCacheTTL = 5
fruitLimit = 30
weightFilterEnabled = false
minWeight = 0
maxWeight = 999999
maxBackpackCapacity = 0
CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
valueFilterEnabled = false
minValue = 0
maxValue = 999999999
fruitValueCache = {}
valueCacheTTL = 3
variantFilterEnabled = false
MutationHandler = require(ReplicatedStorage.Modules.MutationHandler)
SeedData = require(ReplicatedStorage.Data.SeedData)

local function getMaxBackpackCapacity()
return math.ceil(200 + (LocalPlayer:GetAttribute("BonusBackpackSize") or 0))
end

maxBackpackCapacity = getMaxBackpackCapacity()

local function isBackpackFull()
local backpack = LocalPlayer:FindFirstChild("Backpack")
if not backpack then 
return false 
end

local fruitCount = 0
for _, tool in pairs(backpack:GetChildren()) do
if tool:IsA("Tool") and tool:FindFirstChild("Item_Seed") then
fruitCount = fruitCount + 1
end
end

return fruitCount >= maxBackpackCapacity
end

local function getAvailableSpace()
local backpack = LocalPlayer:FindFirstChild("Backpack")
if not backpack then return maxBackpackCapacity end

local fruitCount = 0
for _, tool in pairs(backpack:GetChildren()) do
if tool:IsA("Tool") and tool:FindFirstChild("Item_Seed") then
fruitCount = fruitCount + 1
end
end

return math.max(0, maxBackpackCapacity - fruitCount)
end

local function getMaxFruitsToCollect()
local availableSpace = getAvailableSpace()
return math.min(fruitLimit, availableSpace)
end

function GetmutationsData()
local data = {}
local mutations = MutationHandler:GetMutations()
for _, mutation in pairs(mutations) do
if mutation.Name then
table.insert(data, mutation.Name)
end
end
table.sort(data)
return data
end

function GetcropsData()
local data = {}
for fruitName, fruitInfo in pairs(SeedData) do
table.insert(data, {
Title = fruitName,
Desc = "Rarity: " .. (fruitInfo.SeedRarity or "Unknown"),
Icon = fruitInfo.FruitIcon or fruitInfo.Asset or "rbxassetid://132438947521974"
})
end
table.sort(data, function(a, b) return a.Title < b.Title end)
return data
end

function GetvariantData()
local variantEnums = require(ReplicatedStorage.Data.EnumRegistry.VariantsEnums)
local data = {}
if type(variantEnums) == "table" then
for variantName, _ in pairs(variantEnums) do
if type(variantName) == "string" then
table.insert(data, variantName)
end
end
end
table.sort(data)
return data
end

function updateWhitelistNormalized()
fruitWhitelistNormalized = {}
for _, fruitData in pairs(fruitWhitelist) do
local fruitName = fruitData.Title or fruitData
if type(fruitName) == "string" then
fruitWhitelistNormalized[fruitName:lower()] = true
end
end
fruitBlacklistNormalized = {}
for _, fruitData in pairs(fruitBlacklist) do
local fruitName = fruitData.Title or fruitData
if type(fruitName) == "string" then
fruitBlacklistNormalized[fruitName:lower()] = true
end
end
mutationWhitelistNormalized = {}
for _, mutationData in pairs(mutationWhitelist) do
local mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
mutationWhitelistNormalized[mutationName:lower()] = true
end
end
mutationBlacklistNormalized = {}
for _, mutationData in pairs(mutationBlacklist) do
local mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
mutationBlacklistNormalized[mutationName:lower()] = true
end
end
variantWhitelistNormalized = {}
for _, variantData in pairs(variantWhitelist) do
local variantName = variantData.Title or variantData
if type(variantName) == "string" then
variantWhitelistNormalized[variantName:lower()] = true
end
end
variantBlacklistNormalized = {}
for _, variantData in pairs(variantBlacklist) do
local variantName = variantData.Title or variantData
if type(variantName) == "string" then
variantBlacklistNormalized[variantName:lower()] = true
end
end
end

function getMyFarmPlots()
local now = tick()
if now - lastFarmUpdate < farmCacheTTL and #myFarmPlotsCache > 0 then
return myFarmPlotsCache
end
local myUsername = LocalPlayer.Name
local myPlots = {}
local farmFolder = Workspace:FindFirstChild("Farm")
if farmFolder then
for _, plot in pairs(farmFolder:GetChildren()) do
local sign = plot:FindFirstChild("Sign")
if sign then
local owner = sign:GetAttribute("_owner")
if owner and owner == myUsername then
table.insert(myPlots, plot)
end
end
end
end
myFarmPlotsCache = myPlots
lastFarmUpdate = now
return myPlots
end

function playCollectSound()
if PickupSoundEvent then
task.spawn(function()
pcall(function()
firesignal(PickupSoundEvent.OnClientEvent, "Collect")
end)
end)
end
end

mutationCache = {}
function checkMutation(fruitObj)
local fruitId = fruitObj:GetFullName()
if mutationCache[fruitId] then
return mutationCache[fruitId]
end
local mutation = nil
for attrName, attrValue in pairs(fruitObj:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
local attrLower = attrName:lower()
if #mutationWhitelist > 0 and mutationWhitelistNormalized[attrLower] then
mutation = attrName
break
end
if #mutationBlacklist > 0 and mutationBlacklistNormalized[attrLower] then
mutation = nil
break
end
if #mutationWhitelist == 0 and #mutationBlacklist == 0 then
mutation = attrName
break
end
end
end
if not mutation then
local current = fruitObj.Parent
while current and current ~= Workspace do
if current.Name == "Fruits" then
local plant = current.Parent
if plant and plant:IsA("Model") then
for attrName, attrValue in pairs(plant:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
local attrLower = attrName:lower()
if #mutationWhitelist > 0 and mutationWhitelistNormalized[attrLower] then
mutation = attrName
break
end
if #mutationBlacklist > 0 and mutationBlacklistNormalized[attrLower] then
mutation = nil
break
end
if #mutationWhitelist == 0 and #mutationBlacklist == 0 then
mutation = attrName
break
end
end
end
end
break
end
current = current.Parent
end
end
mutationCache[fruitId] = mutation
if #mutationCache > 100 then
local newCache = {}
local i = 1
for k, v in pairs(mutationCache) do
newCache[k] = v
i = i + 1
if i > 50 then break end
end
mutationCache = newCache
end
return mutation
end

function checkVariant(fruitObj)
if not fruitObj then return nil end
local variant = fruitObj:FindFirstChild("Variant")
if variant and variant:IsA("StringValue") and variant.Value ~= "" then
return variant.Value
end
local variantAttr = fruitObj:GetAttribute("Variant")
if variantAttr and variantAttr ~= "" then
return tostring(variantAttr)
end
local parent = fruitObj.Parent
if parent then
local parentVariant = parent:FindFirstChild("Variant")
if parentVariant and parentVariant:IsA("StringValue") and parentVariant.Value ~= "" then
return parentVariant.Value
end
local parentVariantAttr = parent:GetAttribute("Variant")
if parentVariantAttr and parentVariantAttr ~= "" then
return tostring(parentVariantAttr)
end
local grandParent = parent.Parent
if grandParent then
local grandVariant = grandParent:FindFirstChild("Variant")
if grandVariant and grandVariant:IsA("StringValue") and grandVariant.Value ~= "" then
return grandVariant.Value
end
local grandVariantAttr = grandParent:GetAttribute("Variant")
if grandVariantAttr and grandVariantAttr ~= "" then
return tostring(grandVariantAttr)
end
end
end
return nil
end

function getFruitWeight(fruitObj)
local weightAttr = fruitObj:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
local weightObj = fruitObj:FindFirstChild("Weight")
if weightObj then
if weightObj:IsA("NumberValue") or weightObj:IsA("IntValue") then
return weightObj.Value
elseif weightObj:IsA("StringValue") then
return tonumber(weightObj.Value)
end
end
local parent = fruitObj.Parent
if parent then
local parentWeightAttr = parent:GetAttribute("Weight")
if parentWeightAttr then
return tonumber(parentWeightAttr)
end
end
return nil
end

function getFruitValue(fruitObj)
local fruitId = fruitObj:GetFullName()
local now = tick()
if fruitValueCache[fruitId] and now - fruitValueCache[fruitId].timestamp < valueCacheTTL then
return fruitValueCache[fruitId].value
end
local success, value = pcall(function()
return CalculatePlantValue(fruitObj)
end)
if success and value and type(value) == "number" and value > 0 then
fruitValueCache[fruitId] = {
value = value,
timestamp = now
}
if #fruitValueCache > 200 then
local newCache = {}
local count = 0
for k, v in pairs(fruitValueCache) do
if count < 100 then
newCache[k] = v
count = count + 1
else
break
end
end
fruitValueCache = newCache
end
return value
end
return nil
end

function isWhitelisted(fruitObj)
local fruitName = fruitObj.Name
local fruitNameLower = fruitName:lower()

if #fruitWhitelist > 0 and not fruitWhitelistNormalized[fruitNameLower] then
return false
end
if #fruitBlacklist > 0 and fruitBlacklistNormalized[fruitNameLower] then
return false
end

if #mutationWhitelist > 0 or #mutationBlacklist > 0 then
local mutation = checkMutation(fruitObj)
if #mutationWhitelist > 0 then
if not mutation or not mutationWhitelistNormalized[mutation:lower()] then
return false
end
end
if #mutationBlacklist > 0 then
if mutation and mutationBlacklistNormalized[mutation:lower()] then
return false
end
end
end

if variantFilterEnabled then
if #variantWhitelist > 0 or #variantBlacklist > 0 then
local variant = checkVariant(fruitObj)
if #variantWhitelist > 0 then
if not variant or not variantWhitelistNormalized[variant:lower()] then
return false
end
end
if #variantBlacklist > 0 then
if variant and variantBlacklistNormalized[variant:lower()] then
return false
end
end
end
end

if weightFilterEnabled then
local weight = getFruitWeight(fruitObj)
if weight then
if weight < minWeight or weight > maxWeight then
return false
end
else
return false
end
end

if valueFilterEnabled then
local value = getFruitValue(fruitObj)
if value then
if value < minValue or value > maxValue then
return false
end
else
return false
end
end

return true
end

function collectFromPlots(plots)
if isBackpackFull() then
return false
end

local character = LocalPlayer.Character
if not character then return false end
local hrp = character:FindFirstChild("HumanoidRootPart")
if not hrp then return false end
local hrpPos = hrp.Position
local allCollectables = {}
local collectedCount = 0

local maxToCollect = getMaxFruitsToCollect()
if maxToCollect <= 0 then
return false
end

for _, plot in pairs(plots) do
local descendants = plot:GetDescendants()
for i = 1, #descendants do
local obj = descendants[i]
if obj:IsA("ProximityPrompt") and obj:HasTag("CollectPrompt") then
if obj.Enabled == false then
continue
end
local parent = obj.Parent
if parent then
local objPart = parent:IsA("BasePart") and parent or parent:FindFirstChildWhichIsA("BasePart")
if objPart then
local distance = (hrpPos - objPart.Position).Magnitude
if distance > fruitAuraRange then
continue
end
end
local grandParent = parent.Parent
if grandParent and isWhitelisted(grandParent) then
if collectedCount >= maxToCollect then
break
end
fireproximityprompt(obj, 0)
parent:SetAttribute("Collected", true)
table.insert(allCollectables, grandParent)
collectedCount = collectedCount + 1
end
end
end
end
if collectedCount >= maxToCollect then
break
end
end

if #allCollectables > 0 then
task.delay(1, function()
for _, collectable in pairs(allCollectables) do
local parent = collectable.Parent
if parent then
parent:SetAttribute("Collected", nil)
end
end
end)
task.spawn(function()
pcall(function()
ReplicatedStorage.GameEvents.Crops.Collect:FireServer(allCollectables)
end)
end)
return true
end
return false
end

function startFruitAura()
if fruitAuraConnection then
fruitAuraConnection:Disconnect()
fruitAuraConnection = nil
end
if fruitAuraThread then
task.cancel(fruitAuraThread)
fruitAuraThread = nil
end

mutationCache = {}
fruitValueCache = {}
myFarmPlotsCache = {}
fruitAuraTimer = 0

fruitAuraConnection = RunService.Heartbeat:Connect(function(deltaTime)
if not fruitAuraEnabled then
return
end

fruitAuraTimer = fruitAuraTimer + deltaTime

if fruitAuraTimer >= fruitAuraDelay then
fruitAuraTimer = 0

if not isBackpackFull() then
local myPlots = getMyFarmPlots()
if #myPlots > 0 then
collectFromPlots(myPlots)
end
end
end
end)
end

function stopFruitAura()
if fruitAuraConnection then
fruitAuraConnection:Disconnect()
fruitAuraConnection = nil
end
if fruitAuraThread then
task.cancel(fruitAuraThread)
fruitAuraThread = nil
end
fruitAuraTimer = 0
end

Tabs.Garden:Section({Title = "Fruit Aura", TextSize = 20})

fruitAuraToggle = Tabs.Garden:Toggle({
Title = "Enable Fruit Aura",
Flag = "fruitAuraToggle",
Value = fruitAuraEnabled,
Callback = function(state)
fruitAuraEnabled = state
if fruitAuraEnabled then
startFruitAura()
else
stopFruitAura()
end
end
})

FruitAuraDelay = Tabs.Garden:Slider({
Title = "Collection Delay",
Flag = "FruitAuraDelay",
Step = 0.01,
Value = { Min = 0.01, Max = 2, Default = fruitAuraDelay },
Callback = function(value)
fruitAuraDelay = value
end
})

fruitAuraRangeSlider = Tabs.Garden:Slider({
Title = "Aura Range",
Flag = "FruitAuraRange",
Step = 0.1,
Value = { Min = 1, Max = 500, Default = fruitAuraRange },
Callback = function(value)
fruitAuraRange = value
end
})

Tabs.Garden:Slider({
Title = "Fruit Limit",
Desc = "Auto-limited by available backpack space",
Flag = "FruitAuraLimit",
Step = 1,
Value = { Min = 1, Max = maxBackpackCapacity, Default = fruitLimit },
Callback = function(value)
fruitLimit = value
end
})

Tabs.Garden:Section({Title = "Fruit Whitelist", TextSize = 16})

FruitDropdown = Tabs.Garden:Dropdown({
Title = "Fruit Whitelist",
Values = {"Click refresh to load fruits"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search fruits...",
Callback = function(selected)
fruitWhitelist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Fruits",
Callback = function()
local crops = GetcropsData()
if #crops > 0 then
FruitDropdown:Refresh(crops)
end
end
})

Tabs.Garden:Section({Title = "Fruit Blacklist", TextSize = 16})

FruitBlacklistDropdown = Tabs.Garden:Dropdown({
Title = "Fruit Blacklist",
Values = {"Click refresh to load fruits"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search fruits to blacklist...",
Callback = function(selected)
fruitBlacklist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Fruits",
Callback = function()
local crops = GetcropsData()
if #crops > 0 then
FruitBlacklistDropdown:Refresh(crops)
end
end
})

Tabs.Garden:Section({Title = "Mutation Whitelist", TextSize = 16})

MutationDropdown = Tabs.Garden:Dropdown({
Title = "Mutation Whitelist",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search mutations...",
Callback = function(selected)
mutationWhitelist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Mutations",
Callback = function()
local mutations = GetmutationsData()
if #mutations > 0 then
MutationDropdown:Refresh(mutations)
end
end
})

Tabs.Garden:Section({Title = "Mutation Blacklist", TextSize = 16})

MutationBlacklistDropdown = Tabs.Garden:Dropdown({
Title = "Mutation Blacklist",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search mutations to blacklist...",
Callback = function(selected)
mutationBlacklist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Mutations",
Callback = function()
local mutations = GetmutationsData()
if #mutations > 0 then
MutationBlacklistDropdown:Refresh(mutations)
end
end
})

Tabs.Garden:Toggle({
Title = "Enable Variant Filter",
Flag = "VariantFilterToggle",
Value = variantFilterEnabled,
Callback = function(state)
variantFilterEnabled = state
end
})

Tabs.Garden:Section({Title = "Variant Whitelist", TextSize = 16})

VariantDropdown = Tabs.Garden:Dropdown({
Title = "Variant Whitelist",
Values = {"Click refresh to load variants"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search variants...",
Callback = function(selected)
variantWhitelist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Variants",
Callback = function()
local variants = GetvariantData()
if #variants > 0 then
VariantDropdown:Refresh(variants)
end
end
})

Tabs.Garden:Section({Title = "Variant Blacklist", TextSize = 16})

VariantBlacklistDropdown = Tabs.Garden:Dropdown({
Title = "Variant Blacklist",
Values = {"Click refresh to load variants"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search variants to blacklist...",
Callback = function(selected)
variantBlacklist = selected
updateWhitelistNormalized()
end
})

Tabs.Garden:Button({
Title = "Refresh Variants",
Callback = function()
local variants = GetvariantData()
if #variants > 0 then
VariantBlacklistDropdown:Refresh(variants)
end
end
})

Tabs.Garden:Section({Title = "Weight Filter", TextSize = 16})

Tabs.Garden:Toggle({
Title = "Enable Weight Filter",
Flag = "WeightFilterToggle",
Value = weightFilterEnabled,
Callback = function(state)
weightFilterEnabled = state
end
})

Tabs.Garden:Input({
Title = "Minimum Weight",
Flag = "MinWeightInput",
Type = "Input",
Placeholder = "Enter minimum weight...",
Value = tostring(minWeight),
Callback = function(value)
local num = tonumber(value)
if num then
minWeight = num
end
end
})

Tabs.Garden:Input({
Title = "Maximum Weight",
Flag = "MaxWeightInput",
Type = "Input",
Placeholder = "Enter maximum weight...",
Value = tostring(maxWeight),
Callback = function(value)
local num = tonumber(value)
if num then
maxWeight = num
end
end
})

Tabs.Garden:Section({Title = "Value Filter", TextSize = 16})

Tabs.Garden:Toggle({
Title = "Enable Value Filter",
Flag = "ValueFilterToggle",
Value = valueFilterEnabled,
Callback = function(state)
valueFilterEnabled = state
end
})

Tabs.Garden:Input({
Title = "Minimum Value",
Flag = "MinValueInput",
Type = "Input",
Placeholder = "Enter minimum value...",
Value = tostring(minValue),
Callback = function(value)
local num = tonumber(value)
if num then
minValue = num
end
end
})

Tabs.Garden:Input({
Title = "Maximum Value",
Flag = "MaxValueInput",
Type = "Input",
Placeholder = "Enter maximum value...",
Value = tostring(maxValue),
Callback = function(value)
local num = tonumber(value)
if num then
maxValue = num
end
end
})
GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
Remove_Item = GameEvents:WaitForChild("Remove_Item")
DeleteObject = GameEvents:WaitForChild("DeleteObject")
GetFarm = require(ReplicatedStorage.Modules.GetFarm)
treeList = {}
selectedTrees = {}
autoRemoveTreeEnabled = false
autoRemoveTreeDelay = 0.01
treeRemovalThread = nil
fruitList = {}
selectedFruits = {}
autoRemoveFruitEnabled = false
autoRemoveFruitDelay = 0.01
weightFilterEnabled = false
minWeight = 0
maxWeight = 999
mutationWhitelist = {}
fruitRemovalThread = nil
function getMyFarmPlots()
myUsername = LocalPlayer.Name
myPlots = {}
farmFolder = Workspace:FindFirstChild("Farm")
if farmFolder then
for _, plot in pairs(farmFolder:GetChildren()) do
sign = plot:FindFirstChild("Sign")
if sign then
owner = sign:GetAttribute("_owner")
if owner and owner == myUsername then
table.insert(myPlots, plot)
end
end
end
end
return myPlots
end
function scanTrees()
treeList = {}
treeCounts = {}
myPlots = getMyFarmPlots()
for _, plot in pairs(myPlots) do
descendants = plot:GetDescendants()
for i = 1, #descendants do
obj = descendants[i]
if obj:IsA("Model") and obj:FindFirstChild("Grow") then
treeName = obj.Name
treeCounts[treeName] = (treeCounts[treeName] or 0) + 1
end
end
end
for treeName, count in pairs(treeCounts) do
table.insert(treeList, {
Title = treeName .. " (x" .. count .. ")",
TreeName = treeName,
Count = count
})
end
table.sort(treeList, function(a, b) return a.TreeName < b.TreeName end)
return treeList
end
function scanFruits()
fruitList = {}
fruitCounts = {}
myPlots = getMyFarmPlots()
for _, plot in pairs(myPlots) do
descendants = plot:GetDescendants()
for i = 1, #descendants do
obj = descendants[i]
if obj:IsA("Model") then
fruitsFolder = obj:FindFirstChild("Fruits")
if fruitsFolder then
for _, fruit in pairs(fruitsFolder:GetChildren()) do
fruitName = fruit.Name
fruitCounts[fruitName] = (fruitCounts[fruitName] or 0) + 1
end
end
end
end
end
for fruitName, count in pairs(fruitCounts) do
table.insert(fruitList, {
Title = fruitName .. " (x" .. count .. ")",
FruitName = fruitName,
Count = count
})
end
table.sort(fruitList, function(a, b) return a.FruitName < b.FruitName end)
return fruitList
end
function getFruitWeight(fruitObj)
weightAttr = fruitObj:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
weightObj = fruitObj:FindFirstChild("Weight")
if weightObj then
if weightObj:IsA("NumberValue") or weightObj:IsA("IntValue") then
return weightObj.Value
elseif weightObj:IsA("StringValue") then
return tonumber(weightObj.Value)
end
end
parent = fruitObj.Parent
if parent then
parentWeightAttr = parent:GetAttribute("Weight")
if parentWeightAttr then
return tonumber(parentWeightAttr)
end
end
return nil
end
function getFruitMutations(fruitObj)
mutations = {}
for attrName, attrValue in pairs(fruitObj:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
table.insert(mutations, attrName)
end
end
parent = fruitObj.Parent
if parent then
plant = parent.Parent
if plant and plant:IsA("Model") then
for attrName, attrValue in pairs(plant:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
table.insert(mutations, attrName)
end
end
end
end
return mutations
end
function shouldRemoveFruit(fruitObj)
fruitName = fruitObj.Name
if #selectedFruits > 0 then
found = false
for _, selectedFruit in pairs(selectedFruits) do
if selectedFruit.FruitName == fruitName then
found = true
break
end
end
if not found then
return false
end
end
if weightFilterEnabled then
weight = getFruitWeight(fruitObj)
if weight then
if weight < minWeight or weight > maxWeight then
return false
end
else
return false
end
end
if #mutationWhitelist > 0 then
mutations = getFruitMutations(fruitObj)
hasMutation = false
for _, mutation in pairs(mutations) do
for _, whitelistedMutation in pairs(mutationWhitelist) do
if mutation:lower() == whitelistedMutation:lower() then
hasMutation = true
break
end
end
if hasMutation then break end
end
if not hasMutation then
return false
end
end
return true
end
function removeSelectedTrees()
myPlots = getMyFarmPlots()
treesRemoved = 0
for _, plot in pairs(myPlots) do
descendants = plot:GetDescendants()
for i = 1, #descendants do
obj = descendants[i]
if obj:IsA("Model") and obj:FindFirstChild("Grow") then
treeName = obj.Name
for _, selectedTree in pairs(selectedTrees) do
if selectedTree.TreeName == treeName then
pcall(function()
Remove_Item:FireServer(obj:FindFirstChildWhichIsA("BasePart") or obj)
end)
treesRemoved = treesRemoved + 1
break
end
end
end
end
end
return treesRemoved
end
function removeSelectedFruits()
myPlots = getMyFarmPlots()
fruitsRemoved = 0
for _, plot in pairs(myPlots) do
descendants = plot:GetDescendants()
for i = 1, #descendants do
obj = descendants[i]
if obj:IsA("Model") then
fruitsFolder = obj:FindFirstChild("Fruits")
if fruitsFolder then
for _, fruit in pairs(fruitsFolder:GetChildren()) do
if shouldRemoveFruit(fruit) then
prompt = fruit:FindFirstChildWhichIsA("ProximityPrompt")
if prompt then
pcall(function()
firesignal(prompt.Triggered)
end)
fruitsRemoved = fruitsRemoved + 1
end
end
end
end
end
end
end
return fruitsRemoved
end
function startAutoTreeRemoval()
if treeRemovalThread then
task.cancel(treeRemovalThread)
treeRemovalThread = nil
end
treeRemovalThread = task.spawn(function()
while autoRemoveTreeEnabled and #selectedTrees > 0 do
removed = removeSelectedTrees()
if removed > 0 then
task.wait(autoRemoveTreeDelay)
else
task.wait(1)
end
end
treeRemovalThread = nil
end)
end
function startAutoFruitRemoval()
if fruitRemovalThread then
task.cancel(fruitRemovalThread)
fruitRemovalThread = nil
end
fruitRemovalThread = task.spawn(function()
while autoRemoveFruitEnabled do
removed = removeSelectedFruits()
if removed > 0 then
task.wait(autoRemoveFruitDelay)
else
task.wait(1)
end
end
fruitRemovalThread = nil
end)
end
function stopAutoTreeRemoval()
if treeRemovalThread then
task.cancel(treeRemovalThread)
treeRemovalThread = nil
end
end
function stopAutoFruitRemoval()
if fruitRemovalThread then
task.cancel(fruitRemovalThread)
fruitRemovalThread = nil
end
end
Tabs.Garden:Section({Title = "Remove Tree", TextSize = 20})
treeDropdown = Tabs.Garden:Dropdown({
Title = "Tree List",
Values = {"Click refresh to load trees"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search trees...",
Callback = function(selected)
selectedTrees = selected
end
})
Tabs.Garden:Button({
Title = "Refresh Tree List",
Callback = function()
trees = scanTrees()
treeDropdown:Refresh(trees)
end
})
Tabs.Garden:Button({
Title = "Remove Random Selected Tree",
Callback = function()
removeSelectedTrees()
end
})
Tabs.Garden:Toggle({
Title = "Auto Remove Tree",
Flag = "AutoRemoveTree",
Value = autoRemoveTreeEnabled,
Callback = function(state)
autoRemoveTreeEnabled = state
if autoRemoveTreeEnabled then
startAutoTreeRemoval()
else
stopAutoTreeRemoval()
end
end
})
Tabs.Garden:Slider({
Title = "Auto Remove Delay",
Flag = "AutoRemoveTreeDelay",
Step = 0.01,
Value = { Min = 0.01, Max = 5, Default = autoRemoveTreeDelay },
Callback = function(value)
autoRemoveTreeDelay = value
if autoRemoveTreeEnabled and treeRemovalThread then
stopAutoTreeRemoval()
startAutoTreeRemoval()
end
end
})
Tabs.Garden:Section({Title = "Remove Fruit", TextSize = 20})
fruitDropdown = Tabs.Garden:Dropdown({
Title = "Fruit List",
Values = {"Click refresh to load fruits"},
Multi = true,
AllowNone = true,
SearchPlaceholder = "Search fruits...",
Callback = function(selected)
selectedFruits = selected
end
})
Tabs.Garden:Button({
Title = "Refresh Fruit List",
Callback = function()
fruits = scanFruits()
fruitDropdown:Refresh(fruits)
end
})
Tabs.Garden:Button({
Title = "Remove All Selected Fruit",
Callback = function()
removeSelectedFruits()
end
})
Tabs.Garden:Toggle({
Title = "Weight Selecting",
Flag = "WeightFilter",
Value = weightFilterEnabled,
Callback = function(state)
weightFilterEnabled = state
end
})
Tabs.Garden:Input({
Title = "Minimum Weight",
Flag = "MinWeight",
Type = "Input",
Placeholder = "0",
Value = tostring(minWeight),
Callback = function(value)
num = tonumber(value)
if num then
minWeight = num
end
end
})
Tabs.Garden:Input({
Title = "Max Weight",
Flag = "MaxWeight",
Type = "Input",
Placeholder = "999",
Value = tostring(maxWeight),
Callback = function(value)
num = tonumber(value)
if num then
maxWeight = num
end
end
})
mutationDropdown = Tabs.Garden:Dropdown({
Title = "Mutations Whitelist",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search mutations...",
Callback = function(selected)
mutationWhitelist = selected
end
})
Tabs.Garden:Button({
Title = "Refresh Mutations",
Callback = function()
mutations = GetmutationsData()
if #mutations > 0 then
mutationDropdown:Refresh(mutations)
end
end
})
Tabs.Garden:Toggle({
Title = "Auto Remove Fruit",
Flag = "AutoRemoveFruit",
Value = autoRemoveFruitEnabled,
Callback = function(state)
autoRemoveFruitEnabled = state
if autoRemoveFruitEnabled then
startAutoFruitRemoval()
else
stopAutoFruitRemoval()
end
end
})
Tabs.Garden:Slider({
Title = "Auto Remove Delay",
Flag = "AutoRemoveFruitDelay",
Step = 0.01,
Value = { Min = 0.01, Max = 5, Default = autoRemoveFruitDelay },
Callback = function(value)
autoRemoveFruitDelay = value
if autoRemoveFruitEnabled and fruitRemovalThread then
stopAutoFruitRemoval()
startAutoFruitRemoval()
end
end
})
Tabs.Garden:Section({Title = "Move Tree", TextSize = 20})
MoveTree_RefreshButton = Tabs.Garden:Button({
Title = "Refresh Trees",
Callback = function()
MoveTree_TreeList = {}
MoveTree_TreeCounts = {}
MoveTree_MyPlots = {}
MoveTree_FarmFolder = workspace:FindFirstChild("Farm")
MoveTree_MyUsername = Players.LocalPlayer.Name
if MoveTree_FarmFolder then
for _, MoveTree_Plot in pairs(MoveTree_FarmFolder:GetChildren()) do
MoveTree_Sign = MoveTree_Plot:FindFirstChild("Sign")
if MoveTree_Sign then
MoveTree_Owner = MoveTree_Sign:GetAttribute("_owner")
if MoveTree_Owner and MoveTree_Owner == MoveTree_MyUsername then
table.insert(MoveTree_MyPlots, MoveTree_Plot)
end
end
end
for _, MoveTree_Plot in pairs(MoveTree_MyPlots) do
MoveTree_Descendants = MoveTree_Plot:GetDescendants()
for _, MoveTree_Obj in pairs(MoveTree_Descendants) do
if MoveTree_Obj:IsA("Model") and MoveTree_Obj:FindFirstChild("Grow") then
MoveTree_TreeName = MoveTree_Obj.Name
MoveTree_TreeCounts[MoveTree_TreeName] = (MoveTree_TreeCounts[MoveTree_TreeName] or 0) + 1
end
end
end
for MoveTree_TreeName, MoveTree_Count in pairs(MoveTree_TreeCounts) do
table.insert(MoveTree_TreeList, {
Title = MoveTree_TreeName .. " (x" .. MoveTree_Count .. ")",
TreeName = MoveTree_TreeName,
Count = MoveTree_Count
})
end
table.sort(MoveTree_TreeList, function(MoveTree_A, MoveTree_B) 
return MoveTree_A.TreeName < MoveTree_B.TreeName 
end)
end
MoveTree_TreeDropdown:Refresh(MoveTree_TreeList)
end
})
MoveTree_TreeDropdown = Tabs.Garden:Dropdown({
Title = "Tree List",
Values = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(MoveTree_Selected)
MoveTree_SelectedTrees = MoveTree_Selected
end
})
MoveTree_SavePositionButton = Tabs.Garden:Button({
Title = "Save Position",
Callback = function()
MoveTree_Character = Players.LocalPlayer.Character
if MoveTree_Character then
MoveTree_RootPart = MoveTree_Character:FindFirstChild("HumanoidRootPart")
if MoveTree_RootPart then
MoveTree_SavedPos = MoveTree_RootPart.Position
end
end
end
})
MoveTree_ClearPositionButton = Tabs.Garden:Button({
Title = "Clear Position",
Callback = function()
MoveTree_SavedPos = nil
end
})
MoveTree_MoveAllButton = Tabs.Garden:Button({
Title = "Move All Selected",
Callback = function()
MoveTree_MyUsername = Players.LocalPlayer.Name
MoveTree_FarmFolder = workspace:FindFirstChild("Farm")
MoveTree_MyPlots = {}
MoveTree_TargetPos = MoveTree_SavedPos or Vector3.new(0,0,0)
MoveTree_Mode = MoveTree_ModeValue or "Random"
if MoveTree_FarmFolder then
for _, MoveTree_Plot in pairs(MoveTree_FarmFolder:GetChildren()) do
MoveTree_Sign = MoveTree_Plot:FindFirstChild("Sign")
if MoveTree_Sign then
MoveTree_Owner = MoveTree_Sign:GetAttribute("_owner")
if MoveTree_Owner and MoveTree_Owner == MoveTree_MyUsername then
table.insert(MoveTree_MyPlots, MoveTree_Plot)
end
end
end
end
if MoveTree_Mode == "Under LocalPlayer" then
MoveTree_Character = Players.LocalPlayer.Character
if MoveTree_Character then
MoveTree_RootPart = MoveTree_Character:FindFirstChild("HumanoidRootPart")
if MoveTree_RootPart then
MoveTree_TargetPos = MoveTree_RootPart.Position + Vector3.new(0, -2, 0)
end
end
elseif MoveTree_Mode == "Random" then
MoveTree_Character = Players.LocalPlayer.Character
if MoveTree_Character then
MoveTree_RootPart = MoveTree_Character:FindFirstChild("HumanoidRootPart")
if MoveTree_RootPart then
MoveTree_BasePos = MoveTree_RootPart.Position
MoveTree_TargetPos = MoveTree_BasePos + Vector3.new(math.random(-10, 10), -2, math.random(-10, 10))
end
end
end
for _, MoveTree_Plot in pairs(MoveTree_MyPlots) do
MoveTree_Important = MoveTree_Plot:FindFirstChild("Important")
if MoveTree_Important then
MoveTree_PlantsPhysical = MoveTree_Important:FindFirstChild("Plants_Physical")
if MoveTree_PlantsPhysical then
for _, MoveTree_Plant in pairs(MoveTree_PlantsPhysical:GetChildren()) do
if MoveTree_Plant:IsA("Model") and MoveTree_Plant:FindFirstChild("Grow") then
MoveTree_PlantName = MoveTree_Plant.Name
for _, MoveTree_Selected in pairs(MoveTree_SelectedTrees or {}) do
if MoveTree_Selected.TreeName == MoveTree_PlantName then
MoveTree_Trowel = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
if MoveTree_Trowel and MoveTree_Trowel.Name:match("Trowel") then
MoveTree_Remote = ReplicatedStorage.GameEvents.TrowelRemote
MoveTree_Success = pcall(function()
MoveTree_Remote:InvokeServer("Pickup", MoveTree_Trowel, MoveTree_Plant)
end)
task.wait(0.1)
MoveTree_Success = pcall(function()
MoveTree_Remote:InvokeServer("Place", MoveTree_Trowel, MoveTree_Plant, CFrame.new(MoveTree_TargetPos))
end)
end
break
end
end
end
end
end
end
end
end
})
MoveTree_MoveRandomButton = Tabs.Garden:Button({
Title = "Move Random Selected",
Callback = function()
MoveTree_MyUsername = Players.LocalPlayer.Name
MoveTree_FarmFolder = workspace:FindFirstChild("Farm")
MoveTree_MyPlots = {}
MoveTree_TargetPos = MoveTree_SavedPos or Vector3.new(0,0,0)
MoveTree_Mode = MoveTree_ModeValue or "Random"
if MoveTree_FarmFolder then
for _, MoveTree_Plot in pairs(MoveTree_FarmFolder:GetChildren()) do
MoveTree_Sign = MoveTree_Plot:FindFirstChild("Sign")
if MoveTree_Sign then
MoveTree_Owner = MoveTree_Sign:GetAttribute("_owner")
if MoveTree_Owner and MoveTree_Owner == MoveTree_MyUsername then
table.insert(MoveTree_MyPlots, MoveTree_Plot)
end
end
end
end
if MoveTree_Mode == "Under LocalPlayer" then
MoveTree_Character = Players.LocalPlayer.Character
if MoveTree_Character then
MoveTree_RootPart = MoveTree_Character:FindFirstChild("HumanoidRootPart")
if MoveTree_RootPart then
MoveTree_TargetPos = MoveTree_RootPart.Position + Vector3.new(0, -2, 0)
end
end
elseif MoveTree_Mode == "Random" then
MoveTree_Character = Players.LocalPlayer.Character
if MoveTree_Character then
MoveTree_RootPart = MoveTree_Character:FindFirstChild("HumanoidRootPart")
if MoveTree_RootPart then
MoveTree_BasePos = MoveTree_RootPart.Position
MoveTree_TargetPos = MoveTree_BasePos + Vector3.new(math.random(-10, 10), -2, math.random(-10, 10))
end
end
end
MoveTree_RandomPlants = {}
for _, MoveTree_Plot in pairs(MoveTree_MyPlots) do
MoveTree_Important = MoveTree_Plot:FindFirstChild("Important")
if MoveTree_Important then
MoveTree_PlantsPhysical = MoveTree_Important:FindFirstChild("Plants_Physical")
if MoveTree_PlantsPhysical then
for _, MoveTree_Plant in pairs(MoveTree_PlantsPhysical:GetChildren()) do
if MoveTree_Plant:IsA("Model") and MoveTree_Plant:FindFirstChild("Grow") then
MoveTree_PlantName = MoveTree_Plant.Name
for _, MoveTree_Selected in pairs(MoveTree_SelectedTrees or {}) do
if MoveTree_Selected.TreeName == MoveTree_PlantName then
table.insert(MoveTree_RandomPlants, MoveTree_Plant)
break
end
end
end
end
end
end
end
if #MoveTree_RandomPlants > 0 then
MoveTree_RandomIndex = math.random(1, #MoveTree_RandomPlants)
MoveTree_RandomPlant = MoveTree_RandomPlants[MoveTree_RandomIndex]
MoveTree_Trowel = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
if MoveTree_Trowel and MoveTree_Trowel.Name:match("Trowel") then
MoveTree_Remote = ReplicatedStorage.GameEvents.TrowelRemote
MoveTree_Success = pcall(function()
MoveTree_Remote:InvokeServer("Pickup", MoveTree_Trowel, MoveTree_RandomPlant)
end)
task.wait(0.1)
MoveTree_Success = pcall(function()
MoveTree_Remote:InvokeServer("Place", MoveTree_Trowel, MoveTree_RandomPlant, CFrame.new(MoveTree_TargetPos))
end)
end
end
end
})
MoveTree_ModeDropdown = Tabs.Garden:Dropdown({
Title = "Select Mode",
Values = {
{Title = "Random", Icon = "shuffle", Value = "Random"},
{Title = "Under LocalPlayer", Icon = "user", Value = "Under LocalPlayer"},
{Title = "Saved Position", Icon = "save", Value = "Saved Position"}
},
Value = {Title = "Random", Icon = "shuffle", Value = "Random"},
Callback = function(MoveTree_Option)
MoveTree_ModeValue = MoveTree_Option.Value
end
})
Tabs.Pet:Section({ Title = "Pet", TextSize = 20 })
ActivePetsService = require(ReplicatedStorage.Modules.PetServices.ActivePetsService)
PetUtilities = require(ReplicatedStorage.Modules.PetServices.PetUtilities)
DataService = require(ReplicatedStorage.Modules.DataService)
PetRegistry = require(ReplicatedStorage.Data.PetRegistry)
GearData = require(ReplicatedStorage.Data.GearData)
PetBoostRegistry = require(ReplicatedStorage.Data.PetRegistry.PetBoostRegistry)
SeedData = require(ReplicatedStorage.Data.SeedData)
MutationHandler = require(ReplicatedStorage.Modules.MutationHandler)
CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
FoodRecipeData = require(ReplicatedStorage.Data.FoodRecipeData)
function isItemFavorited(item)
if item:GetAttribute("Favorite") then
return true
end
local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui")
if backpackGui then
local backpackFrame = backpackGui:FindFirstChild("Backpack")
if backpackFrame then
local hotbar = backpackFrame:FindFirstChild("Hotbar")
if hotbar then
for _, slot in pairs(hotbar:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
local inventory = backpackFrame:FindFirstChild("Inventory")
if inventory then
local scrollingFrame = inventory:FindFirstChild("ScrollingFrame")
if scrollingFrame then
local gridFrame = scrollingFrame:FindFirstChild("UIGridFrame")
if gridFrame then
for _, slot in pairs(gridFrame:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
end
end
end
end
return false
end
function getActivePets()
playerData = DataService:GetData()
if not playerData or not playerData.PetsData then return {} end
equippedPets = playerData.PetsData.EquippedPets or {}
pets = {}
for _, petUUID in pairs(equippedPets) do
pet = PetUtilities:GetPetByUUID(LocalPlayer, petUUID)
if pet then
table.insert(pets, pet)
end
end
return pets
end
function getPhysicalPetsInGarden()
petsPhysical = workspace:FindFirstChild("PetsPhysical")
if not petsPhysical then return {} end
petsInGarden = {}
for _, petMover in pairs(petsPhysical:GetChildren()) do
if petMover:IsA("BasePart") and petMover:GetAttribute("UUID") then
petModel = petMover:FindFirstChildWhichIsA("Model")
if petModel and petModel:FindFirstChild("PrimaryPart") then
petOwner = petMover:GetAttribute("OWNER")
if petOwner == LocalPlayer.Name then
table.insert(petsInGarden, {
mover = petMover,
model = petModel,
uuid = petMover:GetAttribute("UUID")
})
end
end
end
end
return petsInGarden
end
function getPetDisplayInfo(pet)
petData = pet.PetData
petType = pet.PetType
petInfo = PetRegistry.PetList[petType]
mutation = petData.MutationType or "None"
level = petData.Level or "1"
weight = PetUtilities:CalculateWeight(petData.BaseWeight or 1, petData.Level or 1)
name = petData.Name or "Unnamed"
hunger = (petData.Hunger or 0) / (petInfo.DefaultHunger or 1) * 100
xpCost = PetUtilities:GetCurrentLevelXPCost(petData.Level)
xpProgress = 0
if xpCost and xpCost > 0 then
xpProgress = (petData.LevelProgress or 0) / xpCost * 100
end
boosts = {}
if petData.Boosts and type(petData.Boosts) == "table" then
for _, boost in pairs(petData.Boosts) do
if type(boost) == "table" and boost.Time and boost.Time > 0 then
minutes = math.floor(boost.Time / 60)
seconds = boost.Time % 60
table.insert(boosts, string.format("%s: %dm %ds", boost.BoostType or "Unknown", minutes, seconds))
end
end
end
boostsText = #boosts > 0 and table.concat(boosts, ", ") or "None"
cooldowns = ActivePetsService:GetClientPetStateUUID(LocalPlayer.Name, pet.UUID)
cooldownText = "None"
if type(cooldowns) == "table" then
activeCooldowns = {}
for i, cooldown in pairs(cooldowns) do
if type(cooldown) == "table" and cooldown.Time and cooldown.Time > 0 then
minutes = math.floor(cooldown.Time / 60)
seconds = cooldown.Time % 60
table.insert(activeCooldowns, string.format("%s: %dm %ds", cooldown.Passive or "Ability", minutes, seconds))
end
end
if #activeCooldowns > 0 then
cooldownText = table.concat(activeCooldowns, ", ")
end
end
movementType = petInfo and petInfo.MovementType or "Unknown"
scale = petInfo and petInfo.ModelScalePerLevel or 0
variant = petInfo and petInfo.Variant or "None"
icon = petInfo and petInfo.Icon or ""
ageWarning = ""
if tonumber(level) >= 100 then
ageWarning = " [MAX LEVEL]"
end
displayText = string.format("Name: %s | Level: %s%s | Weight: %.1f KG\nHunger: %.1f%% | XP: %.1f%% | Mutation: %s\nMovement: %s | Scale: %.2f | Variant: %s\nBoosts: %s | Cooldowns: %s", 
name, level, ageWarning, weight, hunger, xpProgress, mutation, movementType, scale, variant, boostsText, cooldownText)
return {
Title = petType .. ageWarning,
Desc = displayText,
Icon = icon,
Value = pet.UUID,
Data = {
UUID = pet.UUID,
Type = petType,
Name = name,
Level = tonumber(level),
Weight = weight,
Hunger = hunger,
XP = xpProgress,
Mutation = mutation,
MovementType = movementType,
Scale = scale,
Variant = variant,
Boosts = boostsText,
Cooldowns = cooldownText,
Icon = icon
}
}
end
function getAllPets()
allPets = {}
equippedPets = getActivePets()
for _, pet in pairs(equippedPets) do
table.insert(allPets, pet)
end
physicalPets = getPhysicalPetsInGarden()
for _, physicalPet in pairs(physicalPets) do
petData = PetUtilities:GetPetByUUID(LocalPlayer, physicalPet.uuid)
if petData then
table.insert(allPets, petData)
end
end
uniquePets = {}
seenUUIDs = {}
for _, pet in pairs(allPets) do
if not seenUUIDs[pet.UUID] then
seenUUIDs[pet.UUID] = true
table.insert(uniquePets, pet)
end
end
return uniquePets
end
function refreshPetDropdown()
if not boostPetDropdown then return end
pets = getAllPets()
dropdownItems = {}
for _, pet in pairs(pets) do
item = getPetDisplayInfo(pet)
table.insert(dropdownItems, item)
end
if #dropdownItems > 0 then
boostPetDropdown:Refresh(dropdownItems, selectedBoostPetUUIDs)
feedPetDropdown:Refresh(dropdownItems, selectedFeedPetUUIDs)
else
boostPetDropdown:Refresh({{Title = "No Pets Found", Icon = "paw-print", Desc = "No pets in garden", Value = ""}}, {})
feedPetDropdown:Refresh({{Title = "No Pets Found", Icon = "paw-print", Desc = "No pets in garden", Value = ""}}, {})
end
end
function getBoostItems()
boostItems = {}
petBoosts = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Models") and ReplicatedStorage.Assets.Models:FindFirstChild("PetBoosts")
if petBoosts then
for _, item in pairs(petBoosts:GetChildren()) do
if item:IsA("Model") then
gearInfo = GearData[item.Name]
icon = gearInfo and gearInfo.Asset or ""
boostType = PetBoostRegistry.PetModelNameToBoostType[item.Name]
boostData = boostType and PetBoostRegistry.BoostTypeStatData[boostType]
table.insert(boostItems, {
Title = item.Name,
Icon = icon,
Desc = gearInfo and gearInfo.GearDescription or ("Boost Type: " .. (boostType or "Unknown")),
Value = item.Name,
Data = {
Name = item.Name,
Icon = icon,
Description = gearInfo and gearInfo.GearDescription or "",
Rarity = gearInfo and gearInfo.GearRarity or "Unknown",
BoostType = boostType,
BoostData = boostData
}
})
end
end
end
petShards = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Models") and ReplicatedStorage.Assets.Models:FindFirstChild("PetShards")
if petShards then
for _, item in pairs(petShards:GetChildren()) do
if item:IsA("Model") then
gearInfo = GearData[item.Name]
icon = gearInfo and gearInfo.Asset or ""
boostType = PetBoostRegistry.PetModelNameToBoostType[item.Name]
boostData = boostType and PetBoostRegistry.BoostTypeStatData[boostType]
table.insert(boostItems, {
Title = item.Name,
Icon = icon,
Desc = gearInfo and gearInfo.GearDescription or ("Boost Type: " .. (boostType or "Unknown")),
Value = item.Name,
Data = {
Name = item.Name,
Icon = icon,
Description = gearInfo and gearInfo.GearDescription or "",
Rarity = gearInfo and gearInfo.GearRarity or "Unknown",
BoostType = boostType,
BoostData = boostData
}
})
end
end
end
return boostItems
end
function getFeedFruits()
feedFruits = {}
for fruitName, fruitInfo in pairs(SeedData) do
cleanName = fruitInfo.SeedName or fruitName
cleanName = cleanName:gsub("%s*[Ss]eed%s*", "")
cleanName = cleanName:gsub("%s+", " ")
cleanName = cleanName:gsub("^%s*(.-)%s*$", "%1")
table.insert(feedFruits, {
Title = cleanName,
Desc = "Rarity: " .. (fruitInfo.SeedRarity or "Unknown"),
Icon = fruitInfo.FruitIcon or fruitInfo.Asset or "",
Value = fruitName,
Data = {
Name = fruitName,
DisplayName = cleanName,
Rarity = fruitInfo.SeedRarity or "Unknown"
}
})
end
table.sort(feedFruits, function(a, b) return a.Title < b.Title end)
return feedFruits
end
function getFeedFoods()
feedFoods = {}
for foodName, foodInfo in pairs(FoodRecipeData.Recipes) do
table.insert(feedFoods, {
Title = foodName,
Desc = string.format("Weight: %.1f | Time: %ds", foodInfo.BaseWeight or 0, foodInfo.BaseTime or 0),
Icon = foodInfo.ImageId or "",
Value = foodName,
Data = {
Name = foodName,
DisplayName = foodName,
Weight = foodInfo.BaseWeight or 0,
Time = foodInfo.BaseTime or 0,
Icon = foodInfo.ImageId or ""
}
})
end
table.sort(feedFoods, function(a, b) return a.Title < b.Title end)
return feedFoods
end
function getFeedMutations()
feedMutations = {}
mutationData = MutationHandler:GetMutations()
for _, mutation in pairs(mutationData) do
if mutation.Name then
table.insert(feedMutations, mutation.Name)
end
end
table.sort(feedMutations)
return feedMutations
end
function getFeedVariants()
variantEnums = require(ReplicatedStorage.Data.EnumRegistry.VariantsEnums)
feedVariants = {}
if type(variantEnums) == "table" then
for variantName, _ in pairs(variantEnums) do
if type(variantName) == "string" then
table.insert(feedVariants, variantName)
end
end
end
table.sort(feedVariants)
return feedVariants
end
function matchesBoostItemName(toolName, itemName)
toolNameLower = string.lower(toolName)
itemNameLower = string.lower(itemName)
local patterns = {
"^" .. itemNameLower,
itemNameLower .. "$",
"^" .. itemNameLower .. " [xX%d]+",
"^" .. itemNameLower .. " [bB][oO][oO][sS][tT]%d*",
"^[hH][iI] " .. itemNameLower,
"^[hH][iI] " .. itemNameLower .. " [xX%d]+",
"^[hH][iI] " .. itemNameLower .. " [bB][oO][oO][sS][tT]%d*",
"^" .. itemNameLower .. " [bB][oO][oO][sS][tT]%d* [xX%d]+$",
itemNameLower .. " [xX%d]+$",
itemNameLower .. " [bB][oO][oO][sS][tT]%d*$",
".*" .. itemNameLower .. ".*"
}
for _, pattern in ipairs(patterns) do
if string.match(toolNameLower, pattern) then
return true
end
end
local words = {}
for word in string.gmatch(toolNameLower, "[%w]+") do
table.insert(words, word)
end
local searchWords = {}
for word in string.gmatch(itemNameLower, "[%w]+") do
table.insert(searchWords, word)
end
local matchCount = 0
for _, searchWord in ipairs(searchWords) do
for _, toolWord in ipairs(words) do
if toolWord == searchWord or string.find(toolWord, searchWord) or string.find(searchWord, toolWord) then
matchCount = matchCount + 1
break
end
end
end
if #searchWords > 0 and matchCount >= #searchWords then
return true
end
return false
end
function findAllBoostItems(itemName)
local items = {}
if Backpack then
for _, tool in pairs(Backpack:GetChildren()) do
if tool:IsA("Tool") and matchesBoostItemName(tool.Name, itemName) and not isItemFavorited(tool) then
table.insert(items, tool)
end
end
end
if Character then
for _, tool in pairs(Character:GetChildren()) do
if tool:IsA("Tool") and matchesBoostItemName(tool.Name, itemName) and not isItemFavorited(tool) then
table.insert(items, tool)
end
end
end
return items
end
function getBoostDelay(boostItemName)
boostType = PetBoostRegistry.PetModelNameToBoostType[boostItemName]
if boostType and PetBoostRegistry.BoostTypeStatData[boostType] then
boostData = PetBoostRegistry.BoostTypeStatData[boostType]
if boostData.Time then
for size, delay in pairs(boostData.Time) do
if string.find(string.lower(boostItemName), string.lower(size)) then
return delay
end
end
return 60
end
end
return 60
end
boostCooldowns = {}
function canApplyBoost(petUUID, boostItemName)
local key = petUUID .. "_" .. boostItemName
local lastApply = boostCooldowns[key]
local delay = getBoostDelay(boostItemName)
if not lastApply then
return true
end
return (tick() - lastApply) >= delay
end
function recordBoostApply(petUUID, boostItemName)
local key = petUUID .. "_" .. boostItemName
boostCooldowns[key] = tick()
end
function equipAndUseBoostItem(item, petUUID, boostItemName)
if not Humanoid then return false end
if not canApplyBoost(petUUID, boostItemName) then
return false
end
if item.Parent == LocalPlayer.Backpack then
item.Parent = Character
Humanoid:EquipTool(item)
else
Humanoid:EquipTool(item)
end
task.wait(0.1)
ReplicatedStorage.GameEvents.PetBoostService:FireServer("ApplyBoost", petUUID)
recordBoostApply(petUUID, boostItemName)
return true
end
function getFeedFruitMutations(item)
mutations = {}
for attrName, attrValue in pairs(item:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
table.insert(mutations, attrName)
end
end
return mutations
end
function getFeedFruitVariant(item)
variant = item:FindFirstChild("Variant")
if variant and variant:IsA("StringValue") and variant.Value ~= "" then
return variant.Value
end
variantAttr = item:GetAttribute("Variant")
if variantAttr and variantAttr ~= "" then
return tostring(variantAttr)
end
return nil
end
function getFeedFruitWeight(item)
weightAttr = item:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
weightObj = item:FindFirstChild("Weight")
if weightObj then
if weightObj:IsA("NumberValue") or weightObj:IsA("IntValue") then
return weightObj.Value
elseif weightObj:IsA("StringValue") then
return tonumber(weightObj.Value)
end
end
return nil
end
function getFeedFruitValue(fruitObj)
success, value = pcall(function()
return CalculatePlantValue(fruitObj)
end)
if success and value and type(value) == "number" and value > 0 then
return value
end
return 0
end
function getFeedFoodWeight(foodObj)
weightAttr = foodObj:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
return 0
end
function getFeedFoodScale(foodObj)
scaleAttr = foodObj:GetAttribute("Scale")
if scaleAttr then
return tonumber(scaleAttr)
end
return 0
end
function isFoodItem(item)
if item:GetAttribute("ItemType") == "Food" then
return true
end
for foodName in pairs(FoodRecipeData.Recipes) do
if string.find(string.lower(item.Name), string.lower(foodName)) then
return true
end
end
return false
end
selectedBoostPetUUIDs = {}
autoBoostEnabled = false
autoBoostThread = nil
selectedBoostItems = {}
levelupTargetAge = 100
selectedFeedPetUUIDs = {}
autoFeedEnabled = false
autoFeedThread = nil
feedFruitWhitelist = {}
feedFruitMutationWhitelist = {}
feedFruitVariantWhitelist = {}
feedFruitWhitelistNormalized = {}
feedFruitMutationWhitelistNormalized = {}
feedFruitVariantWhitelistNormalized = {}
feedFruitWeightFilterEnabled = false
feedFruitMinWeight = 0
feedFruitMaxWeight = 999999
feedFruitValueFilterEnabled = false
feedFruitMinValue = 0
feedFruitMaxValue = 999999999
feedFruitNameFilterEnabled = false
feedFruitMutationFilterEnabled = false
feedFruitVariantFilterEnabled = false
feedFruitIncluded = true
feedFoodEnabled = false
feedFoodWhitelist = {}
feedFoodWhitelistNormalized = {}
feedFoodWeightFilterEnabled = false
feedFoodMinWeight = 0
feedFoodMaxWeight = 999999
feedFoodScaleFilterEnabled = false
feedFoodMinScale = 0
feedFoodMaxScale = 999999
feedFoodNameFilterEnabled = false
feedEquipFruits = {}
feedEquipFoods = {}
feedEquipType = "Equip All"
function updateFeedFruitWhitelistNormalized()
feedFruitWhitelistNormalized = {}
for _, fruitData in pairs(feedFruitWhitelist) do
fruitName = fruitData.Title or fruitData
if type(fruitName) == "string" then
feedFruitWhitelistNormalized[fruitName:lower()] = true
end
end
end
function updateFeedFruitMutationWhitelistNormalized()
feedFruitMutationWhitelistNormalized = {}
for _, mutationData in pairs(feedFruitMutationWhitelist) do
mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
feedFruitMutationWhitelistNormalized[mutationName:lower()] = true
end
end
end
function updateFeedFruitVariantWhitelistNormalized()
feedFruitVariantWhitelistNormalized = {}
for _, variantData in pairs(feedFruitVariantWhitelist) do
variantName = variantData.Title or variantData
if type(variantName) == "string" then
feedFruitVariantWhitelistNormalized[variantName:lower()] = true
end
end
end
function updateFeedFoodWhitelistNormalized()
feedFoodWhitelistNormalized = {}
for _, foodData in pairs(feedFoodWhitelist) do
foodName = foodData.Title or foodData
if type(foodName) == "string" then
feedFoodWhitelistNormalized[foodName:lower()] = true
end
end
end
function shouldEquipFruit(fruitObj)
if not feedFruitIncluded then
return false
end
fruitName = fruitObj.Name:lower()
if feedFruitNameFilterEnabled and #feedFruitWhitelist > 0 then
found = false
for whitelistName, _ in pairs(feedFruitWhitelistNormalized) do
if string.find(fruitName, whitelistName) then
found = true
break
end
end
if not found then return false end
end
if feedFruitMutationFilterEnabled and #feedFruitMutationWhitelist > 0 then
mutations = getFeedFruitMutations(fruitObj)
hasMutation = false
for _, mutation in ipairs(mutations) do
if feedFruitMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then return false end
end
if feedFruitVariantFilterEnabled and #feedFruitVariantWhitelist > 0 then
variant = getFeedFruitVariant(fruitObj)
if not variant or not feedFruitVariantWhitelistNormalized[variant:lower()] then
return false
end
end
if feedFruitWeightFilterEnabled then
weight = getFeedFruitWeight(fruitObj)
if weight then
if weight < feedFruitMinWeight or weight > feedFruitMaxWeight then
return false
end
else
return false
end
end
if feedFruitValueFilterEnabled then
value = getFeedFruitValue(fruitObj)
if value < feedFruitMinValue or value > feedFruitMaxValue then
return false
end
end
return true
end
function shouldEquipFood(foodObj)
if not isFoodItem(foodObj) then
return false
end
foodName = foodObj.Name:lower()
if feedFoodNameFilterEnabled and #feedFoodWhitelist > 0 then
found = false
for whitelistName, _ in pairs(feedFoodWhitelistNormalized) do
if string.find(foodName, whitelistName) then
found = true
break
end
end
if not found then return false end
end
if feedFoodWeightFilterEnabled then
weight = getFeedFoodWeight(foodObj)
if weight then
if weight < feedFoodMinWeight or weight > feedFoodMaxWeight then
return false
end
else
return false
end
end
if feedFoodScaleFilterEnabled then
scale = getFeedFoodScale(foodObj)
if scale then
if scale < feedFoodMinScale or scale > feedFoodMaxScale then
return false
end
else
return false
end
end
return true
end
function updateFeedEquipLists()
feedEquipFruits = {}
feedEquipFoods = {}
if Backpack then
for _, tool in pairs(Backpack:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
if tool:FindFirstChild("Item_Seed") and shouldEquipFruit(tool) then
table.insert(feedEquipFruits, tool)
elseif feedFoodEnabled and shouldEquipFood(tool) then
table.insert(feedEquipFoods, tool)
end
end
end
end
if Character then
for _, tool in pairs(Character:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
if tool:FindFirstChild("Item_Seed") and shouldEquipFruit(tool) then
table.insert(feedEquipFruits, tool)
elseif feedFoodEnabled and shouldEquipFood(tool) then
table.insert(feedEquipFoods, tool)
end
end
end
end
end
function equipFeedItems()
if feedEquipType == "Equip All" then
for _, tool in pairs(feedEquipFruits) do
if tool and tool.Parent ~= Character then
tool.Parent = Character
end
end
for _, tool in pairs(feedEquipFoods) do
if tool and tool.Parent ~= Character then
tool.Parent = Character
end
end
elseif feedEquipType == "Equip 1 By 1" then
if #feedEquipFruits > 0 then
local tool = feedEquipFruits[1]
if tool and tool.Parent ~= Character then
tool.Parent = Character
end
elseif #feedEquipFoods > 0 then
local tool = feedEquipFoods[1]
if tool and tool.Parent ~= Character then
tool.Parent = Character
end
end
end
end
function feedPet(petUUID)
ReplicatedStorage.GameEvents.ActivePetService:FireServer("Feed", petUUID)
end
Tabs.Pet:Section({ Title = "Boost Pet" })
boostPetDropdown = Tabs.Pet:Dropdown({
Title = "Boost Pet",
Desc = "Select pets to boost",
Values = {{Title = "Loading pets...", Icon = "loader", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search pets...",
Callback = function(selected)
selectedBoostPetUUIDs = {}
for _, pet in pairs(selected) do
if pet.Value then
table.insert(selectedBoostPetUUIDs, pet.Value)
end
end
if autoBoostEnabled then
if autoBoostThread then
task.cancel(autoBoostThread)
autoBoostThread = nil
end
startAutoBoost()
end
end
})
boostItemDropdown = Tabs.Pet:Dropdown({
Title = "Boost Item",
Desc = "Select boost items to use",
Values = {{Title = "Loading boost items...", Icon = "loader", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search boost items...",
Callback = function(selected)
selectedBoostItems = {}
for _, item in pairs(selected) do
if item.Value then
table.insert(selectedBoostItems, item.Value)
end
end
if autoBoostEnabled then
if autoBoostThread then
task.cancel(autoBoostThread)
autoBoostThread = nil
end
startAutoBoost()
end
end
})
levelupAgeInput = Tabs.Pet:Input({
Title = "Levelup Lollipop Target Age",
Desc = "Set target age (1-100)",
Placeholder = "100",
Value = "100",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num and num >= 1 then
if num > 100 then
num = 100
levelupAgeInput:Set("100")
end
levelupTargetAge = num
end
if autoBoostEnabled then
if autoBoostThread then
task.cancel(autoBoostThread)
autoBoostThread = nil
end
startAutoBoost()
end
end
})
function startAutoBoost()
autoBoostThread = task.spawn(function()
while autoBoostEnabled and #selectedBoostPetUUIDs > 0 and #selectedBoostItems > 0 do
for _, boostItemName in pairs(selectedBoostItems) do
if not autoBoostEnabled then break end
local boostItemsList = findAllBoostItems(boostItemName)
if #boostItemsList == 0 then
continue
end
for _, petUUID in pairs(selectedBoostPetUUIDs) do
if not autoBoostEnabled then break end
pet = PetUtilities:GetPetByUUID(LocalPlayer, petUUID)
if pet and pet.PetData then
currentAge = pet.PetData.Level or 1
if boostItemName == "Levelup Lollipop" then
if currentAge >= levelupTargetAge or currentAge >= 100 then
continue
end
end
for _, boostItem in pairs(boostItemsList) do
if not autoBoostEnabled then break end
if not canApplyBoost(petUUID, boostItemName) then
break
end
pet = PetUtilities:GetPetByUUID(LocalPlayer, petUUID)
if pet and pet.PetData then
currentAge = pet.PetData.Level or 1
if boostItemName == "Levelup Lollipop" then
if currentAge >= levelupTargetAge or currentAge >= 100 then
break
end
end
if boostItem and boostItem.Parent then
local success = equipAndUseBoostItem(boostItem, petUUID, boostItemName)
if success then
task.wait(0.5)
end
end
end
end
end
end
end
task.wait(1)
end
end)
end
autoBoostToggle = Tabs.Pet:Toggle({
Title = "Auto Boost Pet",
Desc = "Automatically use selected boost items on chosen pets",
Value = false,
Callback = function(state)
autoBoostEnabled = state
if autoBoostEnabled and #selectedBoostPetUUIDs > 0 and #selectedBoostItems > 0 then
startAutoBoost()
elseif autoBoostThread then
task.cancel(autoBoostThread)
autoBoostThread = nil
end
end
})
Tabs.Pet:Section({ Title = "Feed Pet" })
feedPetDropdown = Tabs.Pet:Dropdown({
Title = "Feed Petlist",
Desc = "Select pets to feed",
Values = {{Title = "Loading pets...", Icon = "loader", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search pets...",
Callback = function(selected)
selectedFeedPetUUIDs = {}
for _, pet in pairs(selected) do
if pet.Value then
table.insert(selectedFeedPetUUIDs, pet.Value)
end
end
if autoFeedEnabled then
if autoFeedThread then
task.cancel(autoFeedThread)
autoFeedThread = nil
end
startAutoFeed()
end
end
})
feedEquipTypeDropdown = Tabs.Pet:Dropdown({
Title = "Auto Equip Type",
Desc = "Choose how to equip feed items",
Values = {
{Title = "Equip All", Icon = "layers", Value = "Equip All"},
{Title = "Equip 1 By 1", Icon = "list", Value = "Equip 1 By 1"}
},
Value = {Title = "Equip All", Icon = "layers", Value = "Equip All"},
Callback = function(option)
feedEquipType = option.Value
end
})
Tabs.Pet:Section({ Title = "Fruits" })
feedFruitIncludedToggle = Tabs.Pet:Toggle({
Title = "Include Fruit",
Desc = "Include fruits in feed items",
Value = true,
Callback = function(state)
feedFruitIncluded = state
updateFeedEquipLists()
end
})
feedFruitNameFilterToggle = Tabs.Pet:Toggle({
Title = "Enable Fruit Name Filter",
Desc = "Only equip fruits from whitelist",
Value = false,
Callback = function(state)
feedFruitNameFilterEnabled = state
updateFeedEquipLists()
end
})
feedFruitWhitelistDropdown = Tabs.Pet:Dropdown({
Title = "Fruit Whitelist",
Desc = "Select specific fruits to equip",
Values = {{Title = "Click refresh to load fruits", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search fruits...",
Callback = function(selected)
feedFruitWhitelist = selected
updateFeedFruitWhitelistNormalized()
updateFeedEquipLists()
end
})
Tabs.Pet:Button({
Title = "Refresh Fruits",
Callback = function()
fruits = getFeedFruits()
if #fruits > 0 then
feedFruitWhitelistDropdown:Refresh(fruits)
end
end
})
feedFruitMutationFilterToggle = Tabs.Pet:Toggle({
Title = "Enable Mutation Filter",
Desc = "Only equip fruits with specific mutations",
Value = false,
Callback = function(state)
feedFruitMutationFilterEnabled = state
updateFeedEquipLists()
end
})
feedFruitMutationWhitelistDropdown = Tabs.Pet:Dropdown({
Title = "Mutation Whitelist",
Desc = "Select mutations to filter",
Values = {{Title = "Click refresh to load mutations", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search mutations...",
Callback = function(selected)
feedFruitMutationWhitelist = selected
updateFeedFruitMutationWhitelistNormalized()
updateFeedEquipLists()
end
})
Tabs.Pet:Button({
Title = "Refresh Mutations",
Callback = function()
mutations = getFeedMutations()
if #mutations > 0 then
feedFruitMutationWhitelistDropdown:Refresh(mutations)
end
end
})
feedFruitVariantFilterToggle = Tabs.Pet:Toggle({
Title = "Enable Variant Filter",
Desc = "Only equip fruits with specific variants",
Value = false,
Callback = function(state)
feedFruitVariantFilterEnabled = state
updateFeedEquipLists()
end
})
feedFruitVariantWhitelistDropdown = Tabs.Pet:Dropdown({
Title = "Variant Whitelist",
Desc = "Select variants to filter",
Values = {{Title = "Click refresh to load variants", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search variants...",
Callback = function(selected)
feedFruitVariantWhitelist = selected
updateFeedFruitVariantWhitelistNormalized()
updateFeedEquipLists()
end
})
Tabs.Pet:Button({
Title = "Refresh Variants",
Callback = function()
variants = getFeedVariants()
if #variants > 0 then
feedFruitVariantWhitelistDropdown:Refresh(variants)
end
end
})
feedFruitWeightToggle = Tabs.Pet:Toggle({
Title = "Enable Fruit Weight Filter",
Desc = "Only equip fruits within weight range",
Value = false,
Callback = function(state)
feedFruitWeightFilterEnabled = state
updateFeedEquipLists()
end
})
feedFruitMinWeightInput = Tabs.Pet:Input({
Title = "Minimum Fruit Weight",
Placeholder = "0",
Value = "0",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFruitMinWeight = num
updateFeedEquipLists()
end
end
})
feedFruitMaxWeightInput = Tabs.Pet:Input({
Title = "Maximum Fruit Weight",
Placeholder = "999999",
Value = "999999",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFruitMaxWeight = num
updateFeedEquipLists()
end
end
})
feedFruitValueToggle = Tabs.Pet:Toggle({
Title = "Enable Fruit Value Filter",
Desc = "Only equip fruits within value range",
Value = false,
Callback = function(state)
feedFruitValueFilterEnabled = state
updateFeedEquipLists()
end
})
feedFruitMinValueInput = Tabs.Pet:Input({
Title = "Minimum Fruit Value",
Placeholder = "0",
Value = "0",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFruitMinValue = num
updateFeedEquipLists()
end
end
})
feedFruitMaxValueInput = Tabs.Pet:Input({
Title = "Maximum Fruit Value",
Placeholder = "999999999",
Value = "999999999",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFruitMaxValue = num
updateFeedEquipLists()
end
end
})
Tabs.Pet:Section({ Title = "Food" })
feedFoodToggle = Tabs.Pet:Toggle({
Title = "Include Food",
Desc = "Allow equipping food items to feed",
Value = false,
Callback = function(state)
feedFoodEnabled = state
updateFeedEquipLists()
end
})
feedFoodNameFilterToggle = Tabs.Pet:Toggle({
Title = "Enable Food Name Filter",
Desc = "Only equip food from whitelist",
Value = false,
Callback = function(state)
feedFoodNameFilterEnabled = state
updateFeedEquipLists()
end
})
feedFoodWhitelistDropdown = Tabs.Pet:Dropdown({
Title = "Food Whitelist",
Desc = "Select specific foods to equip",
Values = {{Title = "Click refresh to load foods", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search foods...",
Callback = function(selected)
feedFoodWhitelist = selected
updateFeedFoodWhitelistNormalized()
updateFeedEquipLists()
end
})
Tabs.Pet:Button({
Title = "Refresh Foods",
Callback = function()
foods = getFeedFoods()
if #foods > 0 then
feedFoodWhitelistDropdown:Refresh(foods)
end
end
})
feedFoodWeightToggle = Tabs.Pet:Toggle({
Title = "Enable Food Weight Filter",
Desc = "Only equip food within weight range",
Value = false,
Callback = function(state)
feedFoodWeightFilterEnabled = state
updateFeedEquipLists()
end
})
feedFoodMinWeightInput = Tabs.Pet:Input({
Title = "Minimum Food Weight",
Placeholder = "0",
Value = "0",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFoodMinWeight = num
updateFeedEquipLists()
end
end
})
feedFoodMaxWeightInput = Tabs.Pet:Input({
Title = "Maximum Food Weight",
Placeholder = "999999",
Value = "999999",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFoodMaxWeight = num
updateFeedEquipLists()
end
end
})
feedFoodScaleToggle = Tabs.Pet:Toggle({
Title = "Enable Food Scale Filter",
Desc = "Only equip food within scale range",
Value = false,
Callback = function(state)
feedFoodScaleFilterEnabled = state
updateFeedEquipLists()
end
})
feedFoodMinScaleInput = Tabs.Pet:Input({
Title = "Minimum Food Scale",
Placeholder = "0",
Value = "0",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFoodMinScale = num
updateFeedEquipLists()
end
end
})
feedFoodMaxScaleInput = Tabs.Pet:Input({
Title = "Maximum Food Scale",
Placeholder = "999999",
Value = "999999",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num then
feedFoodMaxScale = num
updateFeedEquipLists()
end
end
})
function startAutoFeed()
autoFeedThread = task.spawn(function()
while autoFeedEnabled and #selectedFeedPetUUIDs > 0 do
updateFeedEquipLists()
if #feedEquipFruits > 0 or #feedEquipFoods > 0 then
equipFeedItems()
task.wait()
for _, petUUID in pairs(selectedFeedPetUUIDs) do
if not autoFeedEnabled then break end
pet = PetUtilities:GetPetByUUID(LocalPlayer, petUUID)
if pet and pet.PetData then
hunger = pet.PetData.Hunger or 0
petInfo = PetRegistry.PetList[pet.PetType]
maxHunger = petInfo and petInfo.DefaultHunger or 100
if hunger < maxHunger then
for i = 1, 50 do
if not autoFeedEnabled then break end
feedPet(petUUID)
task.wait()
end
end
end
end
end
if feedEquipType == "Equip 1 By 1" then
if #feedEquipFruits > 0 then
local tool = feedEquipFruits[1]
if tool and tool.Parent == LocalPlayer.Character then
tool.Parent = LocalPlayer.Backpack
table.remove(feedEquipFruits, 1)
end
elseif #feedEquipFoods > 0 then
local tool = feedEquipFoods[1]
if tool and tool.Parent == LocalPlayer.Character then
tool.Parent = LocalPlayer.Backpack
table.remove(feedEquipFoods, 1)
end
end
end
task.wait()
end
end)
end
autoFeedToggle = Tabs.Pet:Toggle({
Title = "Auto Feed Pet",
Desc = "Automatically equip and feed selected pets with whitelisted items (ignores favorited items)",
Value = false,
Callback = function(state)
autoFeedEnabled = state
if autoFeedEnabled and #selectedFeedPetUUIDs > 0 then
updateFeedEquipLists()
startAutoFeed()
elseif autoFeedThread then
task.cancel(autoFeedThread)
autoFeedThread = nil
end
end
})
task.spawn(function()
boostItems = getBoostItems()
if #boostItems > 0 then
boostItemDropdown:Refresh(boostItems)
else
boostItemDropdown:Refresh({{Title = "No Boost Items Found", Icon = "x-circle", Value = ""}})
end
end)
task.spawn(function()
while wait(5) do
refreshPetDropdown()
end
end)
task.spawn(function()
task.wait(2)
refreshPetDropdown()
updateFeedEquipLists()
end)
PetEggService = ReplicatedStorage.GameEvents.PetEggService
PetEggData = require(ReplicatedStorage.Data.PetRegistry.PetEggs)
function isItemFavorited(item)
if item:GetAttribute("Favorite") then
return true
end
local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui")
if backpackGui then
local backpackFrame = backpackGui:FindFirstChild("Backpack")
if backpackFrame then
local hotbar = backpackFrame:FindFirstChild("Hotbar")
if hotbar then
for _, slot in pairs(hotbar:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
local inventory = backpackFrame:FindFirstChild("Inventory")
if inventory then
local scrollingFrame = inventory:FindFirstChild("ScrollingFrame")
if scrollingFrame then
local gridFrame = scrollingFrame:FindFirstChild("UIGridFrame")
if gridFrame then
for _, slot in pairs(gridFrame:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
end
end
end
end
return false
end
function getEggs()
eggs = {}
for eggName, eggInfo in pairs(PetEggData) do
table.insert(eggs, {
Title = eggInfo.EggName or eggName,
Desc = "Rarity: " .. (eggInfo.EggRarity or "Unknown"),
Icon = eggInfo.Icon or "",
Value = eggName,
Data = {
Name = eggName,
DisplayName = eggInfo.EggName or eggName,
Rarity = eggInfo.EggRarity or "Unknown",
Icon = eggInfo.Icon or ""
}
})
end
table.sort(eggs, function(a, b) return a.Title < b.Title end)
return eggs
end
function matchesEggName(toolName, eggName)
toolNameLower = string.lower(toolName)
eggNameLower = string.lower(eggName)
local patterns = {
"^" .. eggNameLower,
eggNameLower .. "$",
"^" .. eggNameLower .. " [xX%d]+",
"^" .. eggNameLower .. " [eE][gG][gG]%d*",
"^[hH][iI] " .. eggNameLower,
"^[hH][iI] " .. eggNameLower .. " [xX%d]+",
"^[hH][iI] " .. eggNameLower .. " [eE][gG][gG]%d*",
"^" .. eggNameLower .. " [eE][gG][gG]%d* [xX%d]+$",
eggNameLower .. " [xX%d]+$",
eggNameLower .. " [eE][gG][gG]%d*$",
".*" .. eggNameLower .. ".*"
}
for _, pattern in ipairs(patterns) do
if string.match(toolNameLower, pattern) then
return true
end
end
local words = {}
for word in string.gmatch(toolNameLower, "[%w]+") do
table.insert(words, word)
end
local searchWords = {}
for word in string.gmatch(eggNameLower, "[%w]+") do
table.insert(searchWords, word)
end
local matchCount = 0
for _, searchWord in ipairs(searchWords) do
for _, toolWord in ipairs(words) do
if toolWord == searchWord or string.find(toolWord, searchWord) or string.find(searchWord, toolWord) then
matchCount = matchCount + 1
break
end
end
end
if #searchWords > 0 and matchCount >= #searchWords then
return true
end
return false
end
function findAllEggs()
eggs = {}
if Backpack then
for _, tool in pairs(Backpack:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
if tool:GetAttribute("ItemType") == "PetEgg" then
table.insert(eggs, tool)
else
for eggName, eggInfo in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
table.insert(eggs, tool)
break
end
end
end
end
end
end
if Character then
for _, tool in pairs(Character:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
if tool:GetAttribute("ItemType") == "PetEgg" then
table.insert(eggs, tool)
else
for eggName, eggInfo in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
table.insert(eggs, tool)
break
end
end
end
end
end
end
return eggs
end
function getPlacementPosition()
if not Character then return Vector3.new(0, 5, 0) end
local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return Vector3.new(0, 5, 0) end
if placeMode == "Under Player" then
return humanoidRootPart.Position + Vector3.new(0, -2, 0)
elseif placeMode == "Random" then
local basePos = humanoidRootPart.Position
local offsetX = math.random(-15, 15)
local offsetZ = math.random(-15, 15)
return basePos + Vector3.new(offsetX, -2, offsetZ)
elseif placeMode == "Saved Position" then
return savedPosition
end
return Vector3.new(0, 5, 0)
end
function placeEgg(eggItem)
if not eggItem then return false end
local position = getPlacementPosition()
local success = pcall(function()
PetEggService:FireServer("CreateEgg", position)
end)
if success then
if eggItem and eggItem.Parent then
eggItem:Destroy()
end
return true
end
return false
end
function equipEgg(eggItem)
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
if not Humanoid then return false end
if eggItem.Parent == LocalPlayer.Backpack then
eggItem.Parent = Character
Humanoid:EquipTool(eggItem)
return true
elseif eggItem.Parent == Character then
Humanoid:EquipTool(eggItem)
return true
end
return false
end
selectedEggs = {}
autoPlaceEnabled = false
autoPlaceThread = nil
placeMode = "Random"
savedPosition = Vector3.new(0, 5, 0)
autoEquipEgg = true
placeDelay = 0.1
Tabs.Pet:Section({ Title = "Place Eggs" })
eggDropdown = Tabs.Pet:Dropdown({
Title = "Select Eggs",
Desc = "Select eggs to place",
Values = {{Title = "Loading eggs...", Icon = "loader", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search eggs...",
Callback = function(selected)
selectedEggs = {}
for _, egg in pairs(selected) do
if egg.Value then
table.insert(selectedEggs, egg.Value)
end
end
end
})
Tabs.Pet:Button({
Title = "Refresh Eggs",
Callback = function()
eggs = getEggs()
if #eggs > 0 then
eggDropdown:Refresh(eggs)
end
end
})
modeDropdown = Tabs.Pet:Dropdown({
Title = "Place Mode",
Values = {
{Title = "Random", Icon = "shuffle", Value = "Random"},
{Title = "Under Player", Icon = "user", Value = "Under Player"},
{Title = "Saved Position", Icon = "save", Value = "Saved Position"}
},
Value = {Title = "Random", Icon = "shuffle", Value = "Random"},
Callback = function(option)
placeMode = option.Value
end
})
Tabs.Pet:Button({
Title = "Save Current Position",
Callback = function()
if Character then
local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
savedPosition = humanoidRootPart.Position + Vector3.new(0, -2, 0)
end
end
end
})
Tabs.Pet:Button({
Title = "Clear Saved Position",
Callback = function()
savedPosition = Vector3.new(0, 5, 0)
end
})
autoEquipToggle = Tabs.Pet:Toggle({
Title = "Auto Equip Egg",
Desc = "Automatically equip eggs before placing",
Value = true,
Callback = function(state)
autoEquipEgg = state
end
})
delaySlider = Tabs.Pet:Slider({
Title = "Place Delay",
Step = 0.01,
Value = {Min = 0.01, Max = 2, Default = 0.1},
Callback = function(value)
placeDelay = value
end
})
function getEggsToPlace()
eggsToPlace = {}
if Backpack then
for _, tool in pairs(Backpack:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
local isSelected = false
if #selectedEggs > 0 then
for _, selectedEgg in pairs(selectedEggs) do
if matchesEggName(tool.Name, selectedEgg) then
isSelected = true
break
end
end
else
for eggName, eggInfo in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
isSelected = true
break
end
end
end
if isSelected then
table.insert(eggsToPlace, tool)
end
end
end
end
if Character then
for _, tool in pairs(Character:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
local isSelected = false
if #selectedEggs > 0 then
for _, selectedEgg in pairs(selectedEggs) do
if matchesEggName(tool.Name, selectedEgg) then
isSelected = true
break
end
end
else
for eggName, eggInfo in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
isSelected = true
break
end
end
end
if isSelected then
table.insert(eggsToPlace, tool)
end
end
end
end
return eggsToPlace
end
function startAutoPlace()
autoPlaceThread = task.spawn(function()
while autoPlaceEnabled do
eggs = getEggsToPlace()
if #eggs == 0 then
task.wait(1)
continue
end
for _, egg in pairs(eggs) do
if not autoPlaceEnabled then break end
if autoEquipEgg then
equipEgg(egg)
task.wait(0.05)
end
placeEgg(egg)
task.wait(placeDelay)
end
task.wait(0.5)
end
end)
end
autoPlaceToggle = Tabs.Pet:Toggle({
Title = "Auto Place Eggs",
Desc = "Automatically place selected eggs",
Value = false,
Callback = function(state)
autoPlaceEnabled = state
if state then
startAutoPlace()
elseif autoPlaceThread then
task.cancel(autoPlaceThread)
autoPlaceThread = nil
end
end
})
PetEggService = ReplicatedStorage.GameEvents.PetEggService
PetEggData = require(ReplicatedStorage.Data.PetRegistry.PetEggs)
function isItemFavorited(item)
if item:GetAttribute("Favorite") then
return true
end
local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui")
if backpackGui then
local backpackFrame = backpackGui:FindFirstChild("Backpack")
if backpackFrame then
local hotbar = backpackFrame:FindFirstChild("Hotbar")
if hotbar then
for _, slot in pairs(hotbar:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
local inventory = backpackFrame:FindFirstChild("Inventory")
if inventory then
local scrollingFrame = inventory:FindFirstChild("ScrollingFrame")
if scrollingFrame then
local gridFrame = scrollingFrame:FindFirstChild("UIGridFrame")
if gridFrame then
for _, slot in pairs(gridFrame:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
end
end
end
end
return false
end
function getCurrentEggCount()
local farm = workspace:FindFirstChild("Farm")
if not farm then return 0 end
local myUsername = LocalPlayer.Name
local eggCount = 0
for _, plot in pairs(farm:GetChildren()) do
local sign = plot:FindFirstChild("Sign")
if sign and sign:GetAttribute("_owner") == myUsername then
local important = plot:FindFirstChild("Important")
if important then
local objectsPhysical = important:FindFirstChild("Objects_Physical")
if objectsPhysical then
for _, obj in pairs(objectsPhysical:GetChildren()) do
if obj.Name == "PetEgg" then
eggCount = eggCount + 1
end
end
end
end
end
end
return eggCount
end
function getEggs()
eggs = {}
for eggName, eggInfo in pairs(PetEggData) do
table.insert(eggs, {
Title = eggInfo.EggName or eggName,
Desc = "Rarity: " .. (eggInfo.EggRarity or "Unknown"),
Icon = eggInfo.Icon or "",
Value = eggName,
Data = {
Name = eggName,
DisplayName = eggInfo.EggName or eggName,
Rarity = eggInfo.EggRarity or "Unknown",
Icon = eggInfo.Icon or ""
}
})
end
table.sort(eggs, function(a, b) return a.Title < b.Title end)
return eggs
end
function matchesEggName(toolName, eggName)
toolNameLower = string.lower(toolName)
eggNameLower = string.lower(eggName)
return string.find(toolNameLower, eggNameLower) ~= nil
end
function getEggsToPlace()
eggsToPlace = {}
if Backpack then
for _, tool in pairs(Backpack:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
local isSelected = false
if #selectedEggs > 0 then
for _, selectedEgg in pairs(selectedEggs) do
if matchesEggName(tool.Name, selectedEgg) then
isSelected = true
break
end
end
else
for eggName in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
isSelected = true
break
end
end
end
if isSelected then
table.insert(eggsToPlace, tool)
end
end
end
end
if Character then
for _, tool in pairs(Character:GetChildren()) do
if tool:IsA("Tool") and not isItemFavorited(tool) then
local isSelected = false
if #selectedEggs > 0 then
for _, selectedEgg in pairs(selectedEggs) do
if matchesEggName(tool.Name, selectedEgg) then
isSelected = true
break
end
end
else
for eggName in pairs(PetEggData) do
if matchesEggName(tool.Name, eggName) then
isSelected = true
break
end
end
end
if isSelected then
table.insert(eggsToPlace, tool)
end
end
end
end
return eggsToPlace
end
function getPlacementPosition()
if not Character then return Vector3.new(0, 5, 0) end
local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return Vector3.new(0, 5, 0) end
if placeMode == "Under Player" then
return humanoidRootPart.Position + Vector3.new(0, -2, 0)
else
local basePos = humanoidRootPart.Position
local offsetX = math.random(-15, 15)
local offsetZ = math.random(-15, 15)
return basePos + Vector3.new(offsetX, -2, offsetZ)
end
end
function placeEgg(eggItem)
if not eggItem then return false end
local position = getPlacementPosition()
local success = pcall(function()
PetEggService:FireServer("CreateEgg", position)
end)
if success then
if eggItem and eggItem.Parent then
eggItem:Destroy()
end
return true
end
return false
end
function equipEgg(eggItem)
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
if not Humanoid then return false end
if eggItem.Parent == LocalPlayer.Backpack then
eggItem.Parent = Character
Humanoid:EquipTool(eggItem)
return true
elseif eggItem.Parent == Character then
Humanoid:EquipTool(eggItem)
return true
end
return false
end
selectedEggs = {}
autoPlaceEnabled = false
autoPlaceThread = nil
placeMode = "Random"
autoEquipEgg = true
placeDelay = 0.1
maxEggSlots = 3
lastEggCount = 0
eggCountCheckTimer = 0
Tabs.Pet:Section({ Title = "Place Eggs" })
eggDropdown = Tabs.Pet:Dropdown({
Title = "Select Eggs",
Desc = "Select eggs to place",
Values = {{Title = "Loading eggs...", Icon = "loader", Value = ""}},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search eggs...",
Callback = function(selected)
selectedEggs = {}
for _, egg in pairs(selected) do
if egg.Value then
table.insert(selectedEggs, egg.Value)
end
end
end
})
Tabs.Pet:Button({
Title = "Refresh Eggs",
Callback = function()
eggs = getEggs()
if #eggs > 0 then
eggDropdown:Refresh(eggs)
end
end
})
modeDropdown = Tabs.Pet:Dropdown({
Title = "Place Mode",
Values = {
{Title = "Random", Icon = "shuffle", Value = "Random"},
{Title = "Under Player", Icon = "user", Value = "Under Player"}
},
Value = {Title = "Random", Icon = "shuffle", Value = "Random"},
Callback = function(option)
placeMode = option.Value
end
})
maxEggSlotsInput = Tabs.Pet:Input({
Title = "Max Egg Slots",
Desc = "Maximum number of eggs to place",
Placeholder = "3",
Value = "3",
NumbersOnly = true,
Callback = function(value)
num = tonumber(value)
if num and num > 0 then
maxEggSlots = num
end
end
})
autoEquipToggle = Tabs.Pet:Toggle({
Title = "Auto Equip Egg",
Desc = "Automatically equip eggs before placing",
Value = true,
Callback = function(state)
autoEquipEgg = state
end
})
delaySlider = Tabs.Pet:Slider({
Title = "Place Delay",
Step = 0.01,
Value = {Min = 0.01, Max = 2, Default = 0.1},
Callback = function(value)
placeDelay = value
end
})
function startAutoPlace()
autoPlaceThread = task.spawn(function()
while autoPlaceEnabled do
eggs = getEggsToPlace()
if #eggs == 0 then
task.wait(1)
continue
end
currentEggCount = getCurrentEggCount()
if currentEggCount >= maxEggSlots then
task.wait(1)
continue
end
for _, egg in pairs(eggs) do
if not autoPlaceEnabled then break end
currentEggCount = getCurrentEggCount()
if currentEggCount >= maxEggSlots then
break
end
if autoEquipEgg then
equipEgg(egg)
task.wait(0.05)
end
placeEgg(egg)
task.wait(placeDelay)
end
task.wait(0.5)
end
end)
end
autoPlaceToggle = Tabs.Pet:Toggle({
Title = "Auto Place Eggs",
Desc = "Automatically place selected eggs",
Value = false,
Callback = function(state)
autoPlaceEnabled = state
if state then
startAutoPlace()
elseif autoPlaceThread then
task.cancel(autoPlaceThread)
autoPlaceThread = nil
end
end
})
task.spawn(function()
eggs = getEggs()
if #eggs > 0 then
eggDropdown:Refresh(eggs)
else
eggDropdown:Refresh({{Title = "No Eggs Found", Icon = "x-circle", Value = ""}})
end
end)
Tabs.Pet:Space()
local PetEggService = ReplicatedStorage.GameEvents.PetEggService
local EggReadyToHatch_RE = ReplicatedStorage.GameEvents.EggReadyToHatch_RE
local autoHatchEnabled = false
local autoHatchThread = nil
local hatchedEggsCache = {}
function getPlayerEggs()
local eggs = {}
local farmFolder = workspace:FindFirstChild("Farm")
if farmFolder then
local myPlots = {}
for _, plot in pairs(farmFolder:GetChildren()) do
local sign = plot:FindFirstChild("Sign")
if sign then
local owner = sign:GetAttribute("_owner")
if owner and owner == LocalPlayer.Name then
table.insert(myPlots, plot)
end
end
end
for _, plot in pairs(myPlots) do
local important = plot:FindFirstChild("Important")
if important then
local objectsPhysical = important:FindFirstChild("Objects_Physical")
if objectsPhysical then
for _, obj in pairs(objectsPhysical:GetChildren()) do
if obj:IsA("Model") and obj:FindFirstChild("PetEgg") then
local petEgg = obj:FindFirstChild("PetEgg")
if petEgg then
local promptAtt = petEgg:FindFirstChild("ProximityPromptAtt")
local prompt = promptAtt and promptAtt:FindFirstChild("ProximityPrompt")
if prompt and prompt.Enabled == true then
table.insert(eggs, {
eggObject = obj,
petEgg = petEgg,
prompt = prompt,
uuid = obj:GetAttribute("OBJECT_UUID") or obj.Name
})
end
end
end
end
end
end
end
end
return eggs
end
function hatchEgg(egg)
if not egg or not egg.eggObject then return false end
local eggId = egg.uuid
if hatchedEggsCache[eggId] then
return false
end
local success = pcall(function()
PetEggService:FireServer("HatchPet", egg.eggObject)
end)
if success then
hatchedEggsCache[eggId] = true
task.spawn(function()
task.wait(2)
hatchedEggsCache[eggId] = nil
end)
return true
end
return false
end
function hatchAllReadyEggs()
local eggs = getPlayerEggs()
local hatchedCount = 0
for _, egg in pairs(eggs) do
if autoHatchEnabled then
local success = hatchEgg(egg)
if success then
hatchedCount = hatchedCount + 1
end
task.wait(0.1)
else
break
end
end
return hatchedCount
end
function startAutoHatch()
if autoHatchThread then
task.cancel(autoHatchThread)
autoHatchThread = nil
end
autoHatchThread = task.spawn(function()
while autoHatchEnabled do
local hatched = hatchAllReadyEggs()
if hatched == 0 then
task.wait(2)
else
task.wait(0.5)
end
end
end)
end
function stopAutoHatch()
if autoHatchThread then
task.cancel(autoHatchThread)
autoHatchThread = nil
end
end
EggReadyToHatch_RE.OnClientEvent:Connect(function(eggObject, eggUUID)
if autoHatchEnabled and eggObject and eggObject:GetAttribute("OWNER") == LocalPlayer.Name then
task.spawn(function()
task.wait(0.5)
if autoHatchEnabled then
local eggs = getPlayerEggs()
for _, egg in pairs(eggs) do
if egg.uuid == eggUUID or egg.eggObject == eggObject then
hatchEgg(egg)
break
end
end
end
end)
end
end)
autoHatchToggle = Tabs.Pet:Toggle({
Title = "Auto Hatch Pet",
Desc = "Automatically hatch ready eggs in your garden",
Value = false,
Callback = function(state)
autoHatchEnabled = state
if state then
hatchedEggsCache = {}
startAutoHatch()
else
stopAutoHatch()
end
end
})
task.spawn(function()
while wait(10) do
if autoHatchEnabled then
hatchedEggsCache = {}
end
end
end)
Tabs.Item:Section({ Title = "Item", TextSize = 20 })
Tabs.Item:Section({ Title = "Equip All Items" })
Tabs.Item:Divider()
GearData = require(ReplicatedStorage.Data.GearData)

EquipConfig = {
SelectedTypes = {"Any"},
Blacklist = {},
CustomTypes = {},
SelectedBlacklist = {},
SelectedCustomType = {},
TempBlacklistInput = "",
TempCustomInput = ""
}

function getBlacklistOptions()
return EquipConfig.Blacklist
end

function getCustomOptions()
return EquipConfig.CustomTypes
end

Tabs.Item:Dropdown({
Title = "Select item types",
Values = {"Any", "Egg", "Seed", "Fruit", "Gear", "Crate", "Seed Pack", "Pet"},
Value = "Any",
Multi = true,
Callback = function(val)
EquipConfig.SelectedTypes = val
end
})

BlacklistDropdown = Tabs.Item:Dropdown({
Title = "Blacklist items",
Values = getBlacklistOptions(),
Multi = true,
Callback = function(val)
EquipConfig.SelectedBlacklist = val
end
})

Tabs.Item:Input({
Title = "Add blacklist item name",
Placeholder = "Your Item here",
Callback = function(val)
EquipConfig.TempBlacklistInput = val
end
})

Tabs.Item:Button({
Title = "Apply blacklist",
Callback = function()
if EquipConfig.TempBlacklistInput ~= "" then
table.insert(EquipConfig.Blacklist, EquipConfig.TempBlacklistInput)
BlacklistDropdown:Refresh(getBlacklistOptions())
end
end
})

Tabs.Item:Button({
Title = "Delete black list item",
Callback = function()
selected = EquipConfig.SelectedBlacklist
if #selected > 0 then
for _, sel in ipairs(selected) do
for i = #EquipConfig.Blacklist, 1, -1 do
if EquipConfig.Blacklist[i] == sel then
table.remove(EquipConfig.Blacklist, i)
end
end
end
EquipConfig.SelectedBlacklist = {}
BlacklistDropdown:Refresh(getBlacklistOptions(), {})
end
end
})

CustomTypeDropdown = Tabs.Item:Dropdown({
Title = "Custom Item List",
Values = getCustomOptions(),
Multi = true,
Callback = function(val)
EquipConfig.SelectedCustomType = val
end
})

Tabs.Item:Input({
Title = "Add custom item type/name",
Placeholder = "Custom Type",
Callback = function(val)
EquipConfig.TempCustomInput = val
end
})

Tabs.Item:Button({
Title = "Apply custom",
Callback = function()
if EquipConfig.TempCustomInput ~= "" then
table.insert(EquipConfig.CustomTypes, EquipConfig.TempCustomInput)
CustomTypeDropdown:Refresh(getCustomOptions())
end
end
})

Tabs.Item:Button({
Title = "Delete custom item type",
Callback = function()
selected = EquipConfig.SelectedCustomType
if #selected > 0 then
for _, sel in ipairs(selected) do
for i = #EquipConfig.CustomTypes, 1, -1 do
if EquipConfig.CustomTypes[i] == sel then
table.remove(EquipConfig.CustomTypes, i)
end
end
end
EquipConfig.SelectedCustomType = {}
CustomTypeDropdown:Refresh(getCustomOptions(), {})
end
end
})

-- Get Favorite_Item remote from correct path
local FavoriteItemRemote = game:GetService("ReplicatedStorage").GameEvents.Favorite_Item

Tabs.Item:Button({
Title = "Equip item",
Callback = function()
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local Backpack = plr.Backpack

for _, tool in ipairs(Backpack:GetChildren()) do
if tool:IsA("Tool") then
local shouldEquip = false
local isBlacklisted = false
local toolType = tool:GetAttribute("ItemType") or tool.Name
local display = ""

if GearData[tool.Name] and GearData[tool.Name].GearName then
display = GearData[tool.Name].GearName
end

for _, black in ipairs(EquipConfig.Blacklist) do
if string.find(tool.Name, black) or (display ~= "" and string.find(display, black)) then
isBlacklisted = true
break
end
end

if not isBlacklisted then
local hasSeed = table.find(EquipConfig.SelectedTypes, "Seed")
local hasSeedPack = table.find(EquipConfig.SelectedTypes, "Seed Pack")
local hasFruit = table.find(EquipConfig.SelectedTypes, "Fruit")

for _, typeSel in ipairs(EquipConfig.SelectedTypes) do
if typeSel == "Any" then
shouldEquip = true
elseif typeSel == "Seed" then
if (string.find(toolType, "Seed") or string.find(tool.Name, "Seed")) and not (string.find(toolType, "Seed Pack") or string.find(tool.Name, "Seed Pack")) then
shouldEquip = true
end
elseif typeSel == "Fruit" then
if Backpack:FindFirstChild(tool.Name) and Backpack[tool.Name]:FindFirstChild("Item_Seed") then
shouldEquip = true
end
elseif typeSel == "Gear" then
if GearData[tool.Name] then
shouldEquip = true
end
elseif typeSel == "Pet" then
if tool:GetAttribute("ItemType") == "Pet" then
shouldEquip = true
end
else
if string.find(toolType, typeSel) or string.find(tool.Name, typeSel) then
shouldEquip = true
end
end
end

if hasSeed and not hasSeedPack and (string.find(toolType, "Seed Pack") or string.find(tool.Name, "Seed Pack")) then
shouldEquip = false
end

for _, custom in ipairs(EquipConfig.CustomTypes) do
if string.find(toolType, custom) or string.find(tool.Name, custom) or (display ~= "" and string.find(display, custom)) then
shouldEquip = true
end
end
end

if shouldEquip then
tool.Parent = char
end
end
end
end
})

Tabs.Item:Section({ Title = "Auto Favorite", TextSize = 20 })
Tabs.Item:Divider()
Tabs.Item:Section({ Title = "FRUIT FAVORITE", TextSize = 18 })

local fruitFavoriteEnabled = false
local fruitFavoriteTask = nil
local fruitUnfavoriteTask = nil
local fruitWhitelist = {}
local fruitWhitelistNormalized = {}
local fruitMutationWhitelist = {}
local fruitMutationWhitelistNormalized = {}
local fruitVariantWhitelist = {}
local fruitVariantWhitelistNormalized = {}
local fruitWeightFilterEnabled = false
local fruitMinWeight = 0
local fruitMaxWeight = 999999
local fruitUnfavoriteButton = nil
local fruitUnfavoriteRunning = false
local fruitFavoriteButton = nil
local fruitFavoriteRunning = false

function updateFruitWhitelistNormalized()
fruitWhitelistNormalized = {}
for _, fruitData in pairs(fruitWhitelist) do
local fruitName = fruitData.Title or fruitData
if type(fruitName) == "string" then
fruitWhitelistNormalized[fruitName:lower()] = true
end
end
end

function updateFruitMutationWhitelistNormalized()
fruitMutationWhitelistNormalized = {}
for _, mutationData in pairs(fruitMutationWhitelist) do
local mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
fruitMutationWhitelistNormalized[mutationName:lower()] = true
end
end
end

function updateFruitVariantWhitelistNormalized()
fruitVariantWhitelistNormalized = {}
for _, variantData in pairs(fruitVariantWhitelist) do
local variantName = variantData.Title or variantData
if type(variantName) == "string" then
fruitVariantWhitelistNormalized[variantName:lower()] = true
end
end
end

function getFruitMutations(item)
local mutations = {}
for attrName, attrValue in pairs(item:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
table.insert(mutations, attrName)
end
end
return mutations
end

function getFruitVariant(item)
local variant = item:FindFirstChild("Variant")
if variant and variant:IsA("StringValue") and variant.Value ~= "" then
return variant.Value
end
local variantAttr = item:GetAttribute("Variant")
if variantAttr and variantAttr ~= "" then
return tostring(variantAttr)
end
return nil
end

function getFruitWeight(item)
local weightAttr = item:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
local weightObj = item:FindFirstChild("Weight")
if weightObj then
if weightObj:IsA("NumberValue") or weightObj:IsA("IntValue") then
return weightObj.Value
elseif weightObj:IsA("StringValue") then
return tonumber(weightObj.Value)
end
end
return nil
end

function isItemFavorited(item)
if item:GetAttribute("Favorite") then
return true
end

local LocalPlayer = game:GetService("Players").LocalPlayer
local backpackGui = LocalPlayer.PlayerGui:FindFirstChild("BackpackGui")
if backpackGui then
local backpackFrame = backpackGui:FindFirstChild("Backpack")
if backpackFrame then
local hotbar = backpackFrame:FindFirstChild("Hotbar")
if hotbar then
for _, slot in ipairs(hotbar:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end

local inventory = backpackFrame:FindFirstChild("Inventory")
if inventory then
local scrollingFrame = inventory:FindFirstChild("ScrollingFrame")
if scrollingFrame then
local gridFrame = scrollingFrame:FindFirstChild("UIGridFrame")
if gridFrame then
for _, slot in ipairs(gridFrame:GetChildren()) do
if slot:IsA("TextButton") then
local favIcon = slot:FindFirstChild("FavIcon")
if favIcon and favIcon.Visible then
local toolName = slot:FindFirstChild("ToolName")
if toolName and toolName.Text == item.Name then
return true
end
end
end
end
end
end
end
end
end
return false
end

function waitForFavoriteIconToAppear(item)
local maxWaitTime = 5
local startTime = tick()
local retryDelay = 0.2

while tick() - startTime < maxWaitTime do
if isItemFavorited(item) then
return true
end
task.wait(retryDelay)
end
return false
end

function waitForFavoriteIconToDisappear(item)
local maxWaitTime = 5
local startTime = tick()
local retryDelay = 0.2

while tick() - startTime < maxWaitTime do
if not isItemFavorited(item) then
return true
end
task.wait(retryDelay)
end
return false
end

function shouldFavoriteFruit(item)
if not item or not item:IsA("Tool") then return false end
if isItemFavorited(item) then
return false
end

local itemType = item:GetAttribute("ItemType")
local isFruit = (itemType == "Seed" or itemType == "Fruit" or item:FindFirstChild("Item_Seed")) and 
not string.find(item.Name, "Pack")

if not isFruit then return false end

if #fruitWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for fruitName, _ in pairs(fruitWhitelistNormalized) do
if itemName:find(fruitName) then
found = true
break
end
end
if not found then return false end
end

if #fruitMutationWhitelist > 0 then
local mutations = getFruitMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if fruitMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then return false end
end

if #fruitVariantWhitelist > 0 then
local variant = getFruitVariant(item)
if not variant or not fruitVariantWhitelistNormalized[variant:lower()] then
return false
end
end

if fruitWeightFilterEnabled then
local weight = getFruitWeight(item)
if weight then
if weight < fruitMinWeight or weight > fruitMaxWeight then
return false
end
else
return false
end
end

return true
end

function getFruitsToProcess(itemsToProcess)
local fruits = {}
for _, item in ipairs(itemsToProcess) do
if item:IsA("Tool") and shouldFavoriteFruit(item) then
table.insert(fruits, item)
end
end
return fruits
end

function safeFavoriteItem(item)
if FavoriteItemRemote then
FavoriteItemRemote:FireServer(item)
return true
else
warn("Favorite_Item remote not found at ReplicatedStorage.GameEvents.Favorite_Item")
return false
end
end

fruitFavoriteButton = Tabs.Item:Toggle({
Title = "Auto Favorite Fruits",
Desc = "Automatically favorite fruits matching filters",
Value = false,
Callback = function(state)
fruitFavoriteEnabled = state
if state then
fruitFavoriteRunning = true
fruitFavoriteButton:SetTitle("Stop Task")
fruitFavoriteTask = task.spawn(function()
local LocalPlayer = game:GetService("Players").LocalPlayer
while fruitFavoriteEnabled and fruitFavoriteRunning do
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local Character = LocalPlayer.Character
local allItems = {}

if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") then
table.insert(allItems, item)
end
end
end

if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
table.insert(allItems, item)
end
end
end

-- Get only fruits that should be favorited
local fruitsToFavorite = getFruitsToProcess(allItems)
local totalFruits = #fruitsToFavorite

for i, fruit in ipairs(fruitsToFavorite) do
if not fruitFavoriteEnabled or not fruitFavoriteRunning then break end
fruitFavoriteButton:SetTitle(string.format("Favoriting fruit %d/%d", i, totalFruits))
safeFavoriteItem(fruit)
local success = waitForFavoriteIconToAppear(fruit)
if not success then
warn("Timeout waiting for fruit to favorite: " .. fruit.Name)
end
task.wait(0.05)
end

if fruitFavoriteEnabled and fruitFavoriteRunning then
task.wait(1)
end
end
fruitFavoriteRunning = false
fruitFavoriteButton:SetTitle("Auto Favorite Fruits")
end)
else
fruitFavoriteRunning = false
fruitFavoriteButton:SetTitle("Auto Favorite Fruits")
if fruitFavoriteTask then
task.cancel(fruitFavoriteTask)
fruitFavoriteTask = nil
end
end
end
})

fruitNameDropdown = Tabs.Item:Dropdown({
Title = "FRUIT NAME WHITELIST",
Desc = "Select specific fruits to favorite",
Values = {"Click refresh to load fruits"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
fruitWhitelist = selected
updateFruitWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Fruit List",
Callback = function()
local items = {}
if SeedData then
for fruitName, fruitInfo in pairs(SeedData) do
table.insert(items, {
Title = fruitInfo.SeedName or fruitName,
Desc = "Rarity: " .. (fruitInfo.SeedRarity or "Unknown"),
Icon = fruitInfo.FruitIcon or fruitInfo.Asset or ""
})
end
table.sort(items, function(a, b) return a.Title < b.Title end)
end
fruitNameDropdown:Refresh(items)
end
})

fruitMutationDropdown = Tabs.Item:Dropdown({
Title = "FRUIT MUTATION WHITELIST",
Desc = "Select mutations to filter",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
fruitMutationWhitelist = selected
updateFruitMutationWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Mutations",
Callback = function()
local items = {}
if MutationHandler and MutationHandler.GetMutations then
local mutations = MutationHandler:GetMutations()
for _, mutation in pairs(mutations) do
if mutation.Name then
table.insert(items, mutation.Name)
end
end
table.sort(items)
end
fruitMutationDropdown:Refresh(items)
end
})

fruitVariantDropdown = Tabs.Item:Dropdown({
Title = "FRUIT VARIANT WHITELIST",
Desc = "Select variants to filter",
Values = {"Click refresh to load variants"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
fruitVariantWhitelist = selected
updateFruitVariantWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Variants",
Callback = function()
local items = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if ReplicatedStorage and ReplicatedStorage.Data and ReplicatedStorage.Data.EnumRegistry then
local variantEnums = require(ReplicatedStorage.Data.EnumRegistry.VariantsEnums)
if type(variantEnums) == "table" then
for variantName, _ in pairs(variantEnums) do
if type(variantName) == "string" then
table.insert(items, variantName)
end
end
end
end
table.sort(items)
fruitVariantDropdown:Refresh(items)
end
})

Tabs.Item:Toggle({
Title = "FRUIT WEIGHT FILTER",
Desc = "Enable weight filtering for fruits",
Value = false,
Callback = function(state)
fruitWeightFilterEnabled = state
end
})

Tabs.Item:Input({
Title = "Min Weight",
Placeholder = "0",
Value = "0",
Callback = function(value)
local num = tonumber(value)
if num then fruitMinWeight = num end
end
})

Tabs.Item:Input({
Title = "Max Weight",
Placeholder = "999999",
Value = "999999",
Callback = function(value)
local num = tonumber(value)
if num then fruitMaxWeight = num end
end
})

fruitUnfavoriteButton = Tabs.Item:Button({
Title = "Unfavorite All Fruits",
Desc = "Remove favorite from all fruits matching current whitelist",
Callback = function()
if fruitUnfavoriteRunning then
fruitUnfavoriteRunning = false
if fruitUnfavoriteTask then
task.cancel(fruitUnfavoriteTask)
fruitUnfavoriteTask = nil
end
fruitUnfavoriteButton:SetTitle("Unfavorite All Fruits")
if WindUI and WindUI.Notify then
WindUI:Notify({
Title = "Task Stopped",
Content = "Fruit unfavorite task stopped",
Duration = 2
})
end
return
end

local LocalPlayer = game:GetService("Players").LocalPlayer
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local Character = LocalPlayer.Character
local itemsToProcess = {}

if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") then
table.insert(itemsToProcess, item)
end
end
end

if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
table.insert(itemsToProcess, item)
end
end
end

function checkForFruitsToUnfavorite()
local fruitCount = 0
for _, item in ipairs(itemsToProcess) do
if not item:IsA("Tool") then continue end
if not isItemFavorited(item) then continue end

local itemType = item:GetAttribute("ItemType")
local isFruit = (itemType == "Seed" or itemType == "Fruit" or item:FindFirstChild("Item_Seed")) and 
not string.find(item.Name, "Pack")

if not isFruit then continue end

if #fruitWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for fruitName, _ in pairs(fruitWhitelistNormalized) do
if itemName:find(fruitName) then
found = true
break
end
end
if not found then continue end
end

if #fruitMutationWhitelist > 0 then
local mutations = getFruitMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if fruitMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then continue end
end

if #fruitVariantWhitelist > 0 then
local variant = getFruitVariant(item)
if not variant or not fruitVariantWhitelistNormalized[variant:lower()] then
continue
end
end

if fruitWeightFilterEnabled then
local weight = getFruitWeight(item)
if weight then
if weight < fruitMinWeight or weight > fruitMaxWeight then
continue
end
else
continue
end
end

fruitCount = fruitCount + 1
end
return fruitCount
end

function getFruitsToUnfavorite()
local fruits = {}
for _, item in ipairs(itemsToProcess) do
if not item:IsA("Tool") then continue end
if not isItemFavorited(item) then continue end

local itemType = item:GetAttribute("ItemType")
local isFruit = (itemType == "Seed" or itemType == "Fruit" or item:FindFirstChild("Item_Seed")) and 
not string.find(item.Name, "Pack")

if not isFruit then continue end

if #fruitWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for fruitName, _ in pairs(fruitWhitelistNormalized) do
if itemName:find(fruitName) then
found = true
break
end
end
if not found then continue end
end

if #fruitMutationWhitelist > 0 then
local mutations = getFruitMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if fruitMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then continue end
end

if #fruitVariantWhitelist > 0 then
local variant = getFruitVariant(item)
if not variant or not fruitVariantWhitelistNormalized[variant:lower()] then
continue
end
end

if fruitWeightFilterEnabled then
local weight = getFruitWeight(item)
if weight then
if weight < fruitMinWeight or weight > fruitMaxWeight then
continue
end
else
continue
end
end

table.insert(fruits, item)
end
return fruits
end

local fruitCount = checkForFruitsToUnfavorite()

if fruitCount == 0 then
if RblxCallDialog then
RblxCallDialog({
Title = "No Fruits to Unfavorite",
Desc = "There are no fruits matching your current filters that are favorited.",
Button1 = {
Title = "OK",
Type = "White",
}
})
end
return
end

if RblxCallDialog then
RblxCallDialog({
Title = "Unfavorite Fruits",
Desc = string.format("Are you sure you want to unfavorite %d fruit(s) matching the current whitelist?", fruitCount),
Button1 = {
Title = "Cancel",
Type = "GreyOutline",
},
Button2 = {
Title = "Unfavorite",
Type = "White",
WaitTimeClick = 3,
Callback = function()
fruitUnfavoriteRunning = true
fruitUnfavoriteButton:SetTitle("Stop Task")
fruitUnfavoriteTask = task.spawn(function()
local fruitsToUnfavorite = getFruitsToUnfavorite()
local totalFruits = #fruitsToUnfavorite
local count = 0

for i, fruit in ipairs(fruitsToUnfavorite) do
if not fruitUnfavoriteRunning then break end
fruitUnfavoriteButton:SetTitle(string.format("Unfavoriting fruit %d/%d", i, totalFruits))
safeFavoriteItem(fruit)
count = count + 1
local success = waitForFavoriteIconToDisappear(fruit)
if not success then
warn("Timeout waiting for fruit to unfavorite: " .. fruit.Name)
end
task.wait(0.05)
end

if fruitUnfavoriteRunning and WindUI and WindUI.Notify then
WindUI:Notify({
Title = "Fruits Unfavorited",
Content = "Removed favorite from " .. count .. " fruits",
Duration = 3
})
end

fruitUnfavoriteRunning = false
fruitUnfavoriteButton:SetTitle("Unfavorite All Fruits")
end)
end
}
})
end
end
})

Tabs.Item:Space()
Tabs.Item:Divider()
Tabs.Item:Section({ Title = "PET FAVORITE", TextSize = 18 })

local petFavoriteEnabled = false
local petFavoriteTask = nil
local petUnfavoriteTask = nil
local petWhitelist = {}
local petWhitelistNormalized = {}
local petMutationWhitelist = {}
local petMutationWhitelistNormalized = {}
local petVariantWhitelist = {}
local petVariantWhitelistNormalized = {}
local petWeightFilterEnabled = false
local petMinWeight = 0
local petMaxWeight = 999999
local petAgeFilterEnabled = false
local petMinAge = 0
local petMaxAge = 999999
local petUnfavoriteButton = nil
local petUnfavoriteRunning = false
local petFavoriteButton = nil
local petFavoriteRunning = false

function updatePetWhitelistNormalized()
petWhitelistNormalized = {}
for _, petData in pairs(petWhitelist) do
local petName = petData.Title or petData
if type(petName) == "string" then
petWhitelistNormalized[petName:lower()] = true
end
end
end

function updatePetMutationWhitelistNormalized()
petMutationWhitelistNormalized = {}
for _, mutationData in pairs(petMutationWhitelist) do
local mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
petMutationWhitelistNormalized[mutationName:lower()] = true
end
end
end

function updatePetVariantWhitelistNormalized()
petVariantWhitelistNormalized = {}
for _, variantData in pairs(petVariantWhitelist) do
local variantName = variantData.Title or variantData
if type(variantName) == "string" then
petVariantWhitelistNormalized[variantName:lower()] = true
end
end
end

function getPetMutations(item)
local mutations = {}
for attrName, attrValue in pairs(item:GetAttributes()) do
if type(attrValue) == "boolean" and attrValue == true then
table.insert(mutations, attrName)
end
end
return mutations
end

function getPetVariant(item)
local variant = item:FindFirstChild("Variant")
if variant and variant:IsA("StringValue") and variant.Value ~= "" then
return variant.Value
end
local variantAttr = item:GetAttribute("Variant")
if variantAttr and variantAttr ~= "" then
return tostring(variantAttr)
end
return nil
end

function getPetWeight(item)
local weightAttr = item:GetAttribute("Weight")
if weightAttr then
return tonumber(weightAttr)
end
local name = item.Name
local weightMatch = name:match("%[(%d+%.?%d*)%s*KG%]")
if weightMatch then
return tonumber(weightMatch)
end
return nil
end

function getPetAge(item)
local ageAttr = item:GetAttribute("Age")
if ageAttr then
return tonumber(ageAttr)
end
local name = item.Name
local ageMatch = name:match("%[Age%s*(%d+)%]") or name:match("%[(%d+)%s*Age%]")
if ageMatch then
return tonumber(ageMatch)
end
return nil
end

function shouldFavoritePet(item)
if not item or not item:IsA("Tool") then return false end
if isItemFavorited(item) then
return false
end

local itemType = item:GetAttribute("ItemType")
if itemType ~= "Pet" then return false end

if #petWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for petName, _ in pairs(petWhitelistNormalized) do
if itemName:find(petName) then
found = true
break
end
end
if not found then return false end
end

if #petMutationWhitelist > 0 then
local mutations = getPetMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if petMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then return false end
end

if #petVariantWhitelist > 0 then
local variant = getPetVariant(item)
if not variant or not petVariantWhitelistNormalized[variant:lower()] then
return false
end
end

if petWeightFilterEnabled then
local weight = getPetWeight(item)
if weight then
if weight < petMinWeight or weight > petMaxWeight then
return false
end
else
return false
end
end

if petAgeFilterEnabled then
local age = getPetAge(item)
if age then
if age < petMinAge or age > petMaxAge then
return false
end
else
return false
end
end

return true
end

function getPetsToProcess(itemsToProcess)
local pets = {}
for _, item in ipairs(itemsToProcess) do
if item:IsA("Tool") and shouldFavoritePet(item) then
table.insert(pets, item)
end
end
return pets
end

petFavoriteButton = Tabs.Item:Toggle({
Title = "Auto Favorite Pets",
Desc = "Automatically favorite pets matching filters",
Value = false,
Callback = function(state)
petFavoriteEnabled = state
if state then
petFavoriteRunning = true
petFavoriteButton:SetTitle("Stop Task")
petFavoriteTask = task.spawn(function()
local LocalPlayer = game:GetService("Players").LocalPlayer
while petFavoriteEnabled and petFavoriteRunning do
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local Character = LocalPlayer.Character
local allItems = {}

if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") then
table.insert(allItems, item)
end
end
end

if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
table.insert(allItems, item)
end
end
end

-- Get only pets that should be favorited
local petsToFavorite = getPetsToProcess(allItems)
local totalPets = #petsToFavorite

for i, pet in ipairs(petsToFavorite) do
if not petFavoriteEnabled or not petFavoriteRunning then break end
petFavoriteButton:SetTitle(string.format("Favoriting pet %d/%d", i, totalPets))
safeFavoriteItem(pet)
local success = waitForFavoriteIconToAppear(pet)
if not success then
warn("Timeout waiting for pet to favorite: " .. pet.Name)
end
task.wait(0.05)
end

if petFavoriteEnabled and petFavoriteRunning then
task.wait(1)
end
end
petFavoriteRunning = false
petFavoriteButton:SetTitle("Auto Favorite Pets")
end)
else
petFavoriteRunning = false
petFavoriteButton:SetTitle("Auto Favorite Pets")
if petFavoriteTask then
task.cancel(petFavoriteTask)
petFavoriteTask = nil
end
end
end
})

petNameDropdown = Tabs.Item:Dropdown({
Title = "PET NAME WHITELIST",
Desc = "Select specific pets to favorite",
Values = {"Click refresh to load pets"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
petWhitelist = selected
updatePetWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Pet List",
Callback = function()
local items = {}
if PetList then
for petName, petInfo in pairs(PetList) do
table.insert(items, {
Title = petInfo.DisplayName or petName,
Desc = "Rarity: " .. (petInfo.Rarity or "Unknown"),
Icon = petInfo.Icon or ""
})
end
table.sort(items, function(a, b) return a.Title < b.Title end)
end
petNameDropdown:Refresh(items)
end
})

petMutationDropdown = Tabs.Item:Dropdown({
Title = "PET MUTATION WHITELIST",
Desc = "Select mutations to filter",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
petMutationWhitelist = selected
updatePetMutationWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Mutations",
Callback = function()
local items = {}
if MutationHandler and MutationHandler.GetMutations then
local mutations = MutationHandler:GetMutations()
for _, mutation in pairs(mutations) do
if mutation.Name then
table.insert(items, mutation.Name)
end
end
table.sort(items)
end
petMutationDropdown:Refresh(items)
end
})

petVariantDropdown = Tabs.Item:Dropdown({
Title = "PET VARIANT WHITELIST",
Desc = "Select variants to filter",
Values = {"Click refresh to load variants"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(selected)
petVariantWhitelist = selected
updatePetVariantWhitelistNormalized()
end
})

Tabs.Item:Button({
Title = "Refresh Variants",
Callback = function()
local items = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if ReplicatedStorage and ReplicatedStorage.Data and ReplicatedStorage.Data.EnumRegistry then
local variantEnums = require(ReplicatedStorage.Data.EnumRegistry.VariantsEnums)
if type(variantEnums) == "table" then
for variantName, _ in pairs(variantEnums) do
if type(variantName) == "string" then
table.insert(items, variantName)
end
end
end
end
table.sort(items)
petVariantDropdown:Refresh(items)
end
})

Tabs.Item:Toggle({
Title = "PET WEIGHT FILTER",
Desc = "Enable weight filtering for pets",
Value = false,
Callback = function(state)
petWeightFilterEnabled = state
end
})

Tabs.Item:Input({
Title = "Min Weight",
Placeholder = "0",
Value = "0",
Callback = function(value)
local num = tonumber(value)
if num then petMinWeight = num end
end
})

Tabs.Item:Input({
Title = "Max Weight",
Placeholder = "999999",
Value = "999999",
Callback = function(value)
local num = tonumber(value)
if num then petMaxWeight = num end
end
})

Tabs.Item:Toggle({
Title = "PET AGE FILTER",
Desc = "Enable age filtering for pets",
Value = false,
Callback = function(state)
petAgeFilterEnabled = state
end
})

Tabs.Item:Input({
Title = "Min Age",
Placeholder = "0",
Value = "0",
Callback = function(value)
local num = tonumber(value)
if num then petMinAge = num end
end
})

Tabs.Item:Input({
Title = "Max Age",
Placeholder = "999999",
Value = "999999",
Callback = function(value)
local num = tonumber(value)
if num then petMaxAge = num end
end
})

petUnfavoriteButton = Tabs.Item:Button({
Title = "Unfavorite All Pets",
Desc = "Remove favorite from all pets matching current whitelist",
Callback = function()
if petUnfavoriteRunning then
petUnfavoriteRunning = false
if petUnfavoriteTask then
task.cancel(petUnfavoriteTask)
petUnfavoriteTask = nil
end
petUnfavoriteButton:SetTitle("Unfavorite All Pets")
if WindUI and WindUI.Notify then
WindUI:Notify({
Title = "Task Stopped",
Content = "Pet unfavorite task stopped",
Duration = 2
})
end
return
end

local LocalPlayer = game:GetService("Players").LocalPlayer
local Backpack = LocalPlayer:FindFirstChild("Backpack")
local Character = LocalPlayer.Character
local itemsToProcess = {}

if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") then
table.insert(itemsToProcess, item)
end
end
end

if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
table.insert(itemsToProcess, item)
end
end
end

function checkForPetsToUnfavorite()
local petCount = 0
for _, item in ipairs(itemsToProcess) do
if not item:IsA("Tool") then continue end
if not isItemFavorited(item) then continue end

local itemType = item:GetAttribute("ItemType")
if itemType ~= "Pet" then continue end

if #petWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for petName, _ in pairs(petWhitelistNormalized) do
if itemName:find(petName) then
found = true
break
end
end
if not found then continue end
end

if #petMutationWhitelist > 0 then
local mutations = getPetMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if petMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then continue end
end

if #petVariantWhitelist > 0 then
local variant = getPetVariant(item)
if not variant or not petVariantWhitelistNormalized[variant:lower()] then
continue
end
end

if petWeightFilterEnabled then
local weight = getPetWeight(item)
if weight then
if weight < petMinWeight or weight > petMaxWeight then
continue
end
else
continue
end
end

if petAgeFilterEnabled then
local age = getPetAge(item)
if age then
if age < petMinAge or age > petMaxAge then
continue
end
else
continue
end
end

petCount = petCount + 1
end
return petCount
end

function getPetsToUnfavorite()
local pets = {}
for _, item in ipairs(itemsToProcess) do
if not item:IsA("Tool") then continue end
if not isItemFavorited(item) then continue end

local itemType = item:GetAttribute("ItemType")
if itemType ~= "Pet" then continue end

if #petWhitelist > 0 then
local itemName = item.Name:lower()
local found = false
for petName, _ in pairs(petWhitelistNormalized) do
if itemName:find(petName) then
found = true
break
end
end
if not found then continue end
end

if #petMutationWhitelist > 0 then
local mutations = getPetMutations(item)
local hasMutation = false
for _, mutation in ipairs(mutations) do
if petMutationWhitelistNormalized[mutation:lower()] then
hasMutation = true
break
end
end
if not hasMutation then continue end
end

if #petVariantWhitelist > 0 then
local variant = getPetVariant(item)
if not variant or not petVariantWhitelistNormalized[variant:lower()] then
continue
end
end

if petWeightFilterEnabled then
local weight = getPetWeight(item)
if weight then
if weight < petMinWeight or weight > petMaxWeight then
continue
end
else
continue
end
end

if petAgeFilterEnabled then
local age = getPetAge(item)
if age then
if age < petMinAge or age > petMaxAge then
continue
end
else
continue
end
end

table.insert(pets, item)
end
return pets
end

local petCount = checkForPetsToUnfavorite()

if petCount == 0 then
if RblxCallDialog then
RblxCallDialog({
Title = "No Pets to Unfavorite",
Desc = "There are no pets matching your current filters that are favorited.",
Button1 = {
Title = "OK",
Type = "White",
}
})
end
return
end

if RblxCallDialog then
RblxCallDialog({
Title = "Unfavorite Pets",
Desc = string.format("Are you sure you want to unfavorite %d pet(s) matching the current whitelist?", petCount),
Button1 = {
Title = "Cancel",
Type = "GreyOutline",
},
Button2 = {
Title = "Unfavorite",
Type = "White",
WaitTimeClick = 3,
Callback = function()
petUnfavoriteRunning = true
petUnfavoriteButton:SetTitle("Stop Task")
petUnfavoriteTask = task.spawn(function()
local petsToUnfavorite = getPetsToUnfavorite()
local totalPets = #petsToUnfavorite
local count = 0

for i, pet in ipairs(petsToUnfavorite) do
if not petUnfavoriteRunning then break end
petUnfavoriteButton:SetTitle(string.format("Unfavoriting pet %d/%d", i, totalPets))
safeFavoriteItem(pet)
count = count + 1
local success = waitForFavoriteIconToDisappear(pet)
if not success then
warn("Timeout waiting for pet to unfavorite: " .. pet.Name)
end
task.wait(0.05)
end

if petUnfavoriteRunning and WindUI and WindUI.Notify then
WindUI:Notify({
Title = "Pets Unfavorited",
Content = "Removed favorite from " .. count .. " pets",
Duration = 3
})
end

petUnfavoriteRunning = false
petUnfavoriteButton:SetTitle("Unfavorite All Pets")
end)
end
}
})
end
end
})
Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
Tabs.Visuals:Divider()
cameraStretchConnection = nil
function setupCameraStretch()
cameraStretchConnection = nil
stretchHorizontal = 0.80
stretchVertical = 0.80
CameraStretchToggle = Tabs.Visuals:Toggle({
Title = "Camera Stretch",
Flag = "CameraStretchToggle",
Value = false,
Callback = function(state)
if state then
if cameraStretchConnection then cameraStretchConnection:Disconnect() end
cameraStretchConnection = RunService.RenderStepped:Connect(function()
Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
else
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = nil
end
end
end
})
CameraStretchHorizontalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Horizontal",
Flag = "CameraStretchHorizontalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchHorizontal),
Callback = function(value)
num = tonumber(value)
if num then
stretchHorizontal = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = RunService.RenderStepped:Connect(function()
Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})
CameraStretchVerticalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Vertical",
Flag = "CameraStretchVerticalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchVertical),
Callback = function(value)
num = tonumber(value)
if num then
stretchVertical = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = RunService.RenderStepped:Connect(function()
Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})
end
FullBrightToggle = Tabs.Visuals:Toggle({
Title = "Full Bright",
Flag = "FullBrightToggle",
Desc = "Ya Like drinking Night Vision while mining in da cave and sceard of creeper blow you up dawg?",
Value = false,
Callback = function(state)
FullBright = state
if state then
originalBrightness = Lighting.Brightness
originalAmbient = Lighting.Ambient
originalOutdoorAmbient = Lighting.OutdoorAmbient
originalColorShiftBottom = Lighting.ColorShift_Bottom
originalColorShiftTop = Lighting.ColorShift_Top
function applyFullBright()
if Lighting.Brightness ~= 1 then
Lighting.Brightness = 1
end
if Lighting.Ambient ~= Color3.new(1, 1, 1) then
Lighting.Ambient = Color3.new(1, 1, 1)
end
if Lighting.OutdoorAmbient ~= Color3.new(1, 1, 1) then
Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
end
if Lighting.ColorShift_Bottom ~= Color3.new(1, 1, 1) then
Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
end
if Lighting.ColorShift_Top ~= Color3.new(1, 1, 1) then
Lighting.ColorShift_Top = Color3.new(1, 1, 1)
end
end
applyFullBright()
if fullBrightConnection then
fullBrightConnection:Disconnect()
end
fullBrightConnection = RunService.Heartbeat:Connect(function()
if FullBright then
applyFullBright()
end
end)
fullBrightCharConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
task.wait(1)
if FullBright then
applyFullBright()
end
end)
else
if fullBrightConnection then
fullBrightConnection:Disconnect()
fullBrightConnection = nil
end
if fullBrightCharConnection then
fullBrightCharConnection:Disconnect()
fullBrightCharConnection = nil
end
if originalBrightness then
Lighting.Brightness = originalBrightness
Lighting.Ambient = originalAmbient
Lighting.OutdoorAmbient = originalOutdoorAmbient
Lighting.ColorShift_Bottom = originalColorShiftBottom
Lighting.ColorShift_Top = originalColorShiftTop
end
end
end
})
FOVSlider = Tabs.Visuals:Slider({
Title = "Field of View",
Flag = "FOVSlider",
Value = { Min = 1, Max = 120, Default = 70, Step = 1 },
Callback = function(value)
workspace.CurrentCamera.FieldOfView = tonumber(value)
end
})
setupCameraStretch()
xRay = false
Tabs.Visuals:Toggle({
Title = "X-ray Vision",
Compact = true,
Callback = function(state)
xRay = state
for _, part in pairs(workspace:GetDescendants()) do
if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
part.LocalTransparencyModifier = state and 0.7 or 0
end
end
end
})
Tabs.Visuals:Button({
Title = "Shit Render", 
Callback = function()
Terrain = workspace:FindFirstChildOfClass("Terrain")
Players = Players
LocalPlayer = Players.LocalPlayer
Lighting.GlobalShadows = false
Lighting.FogEnd = 1e10
Lighting.Brightness = 1
if Terrain then
Terrain.WaterWaveSize = 0
Terrain.WaterWaveSpeed = 0
Terrain.WaterReflectance = 0
Terrain.WaterTransparency = 1
end
for _, obj in ipairs(workspace:GetDescendants()) do
if obj:IsA("BasePart") then
obj.Material = Enum.Material.Plastic
obj.Reflectance = 0
elseif obj:IsA("Decal") or obj:IsA("Texture") then
obj:Destroy()
elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
obj:Destroy()
elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
obj:Destroy()
end
end
for _, LocalPlayer in ipairs(Players:GetPlayers()) do
char = LocalPlayer.Character
if char then
for _, part in ipairs(char:GetDescendants()) do
if part:IsA("Accessory") or part:IsA("Clothing") then
part:Destroy()
end
end
end
end
end
})
local guiController = require(ReplicatedStorage.Modules.GuiController)
local shopControllers = {
TravelingMerchant = require(ReplicatedStorage.Modules.TravelingMerchantShopUIController),
EggShop = require(ReplicatedStorage.Modules.EggShopUIController),
CosmeticShop = require(ReplicatedStorage.Modules.CosmeticShopUIController),
GardenCoinShop = require(ReplicatedStorage.Modules.GardenCoinShopController),
GearShop = require(ReplicatedStorage.Modules.GearShopController),
SeedShop = require(ReplicatedStorage.Modules.SeedShopController),
CarrotCoinShop = require(ReplicatedStorage.Modules.GardenGames.CarrotCoinShopUIController),
SeasonPass = require(ReplicatedStorage.Modules.SeasonPass.SeasonPassUIController)
}
local recipeRegistry = require(ReplicatedStorage.Data.CraftingData.CraftingRecipeRegistry)
local seasonPassToggler = require(ReplicatedStorage.Modules.SeasonPass.SeasonPassToggler)
function openShop(controller, guiName, shopName)
controller:Start()
local shopGui = LocalPlayer.PlayerGui:WaitForChild(guiName, 5)
if not shopGui then
warn("Failed to load " .. shopName .. " UI")
return
end
guiController:Open(shopGui)
local mainFrame = shopGui:FindFirstChild("Frame") or shopGui:FindFirstChild("Shadow") or shopGui:FindFirstChild("SeasonPassFrame")
if mainFrame then
local exitButton = mainFrame:FindFirstChild("ExitButton", true) or mainFrame:FindFirstChild("Close", true)
if exitButton then
exitButton.Activated:Connect(function()
guiController:Close(shopGui)
end)
end
function makeButtonsClickable(container)
if not container then return end
for _, button in ipairs(container:GetDescendants()) do
if button:IsA("TextButton") or button:IsA("ImageButton") then
button.Active = true
end
end
end
local scrollingFrame = mainFrame:FindFirstChild("ScrollingFrame", true)
if scrollingFrame then
for _, item in ipairs(scrollingFrame:GetChildren()) do
if item:IsA("Frame") and not item.Name:match("Padding") then
local mainItemFrame = item:FindFirstChild("Main_Frame") or item:FindFirstChild("MainFrame") or item
if mainItemFrame then
local buyButtons = {"Sheckles_Buy", "Robux_Buy", "Gift", "Buy", "CraftButton", "OddsButton", "InfoButton"}
for _, buttonName in ipairs(buyButtons) do
local button = mainItemFrame:FindFirstChild(buttonName, true)
if button then
button.Active = true
end
end
end
end
end
end
local restockButton = mainFrame:FindFirstChild("Restock", true)
if restockButton then
restockButton.Active = true
end
local adButton = mainFrame:FindFirstChild("RewardAd", true)
if adButton then
adButton.Active = true
end
if shopName == "SeasonPass" then
local topBtns = mainFrame:FindFirstChild("TopBtns")
if topBtns then
makeButtonsClickable(topBtns)
end
local premiumSection = mainFrame:FindFirstChild("PremiumSection")
if premiumSection then
makeButtonsClickable(premiumSection)
end
local main = mainFrame:FindFirstChild("Main")
if main then
for _, section in ipairs({"Rewards", "Quests", "Store"}) do
local sectionFrame = main:FindFirstChild(section)
if sectionFrame then
makeButtonsClickable(sectionFrame)
end
end
end
end
end
end
function openCrafting(machineType)
local tempObject = Instance.new("Part")
tempObject.Name = "TempCraftingObject"
tempObject.Anchored = true
tempObject.CanCollide = false
tempObject.Transparency = 1
tempObject.Parent = workspace
tempObject:SetAttribute("CraftingObjectId", "TempObject_" .. tostring(math.random(1, 999999)))
tempObject:SetAttribute("CraftingObjectType", machineType)
local openRecipeEvent = ReplicatedStorage.GameEvents.OpenRecipeBindableEvent
if openRecipeEvent then
openRecipeEvent:Fire(tempObject)
end
local craftingGui = LocalPlayer.PlayerGui:WaitForChild("RecipeSelection_UI", 5)
if craftingGui then
guiController:Open(craftingGui)
local mainFrame = craftingGui:FindFirstChild("Frame")
if mainFrame then
local exitButton = mainFrame.Frame:FindFirstChild("ExitButton")
if exitButton then
exitButton.Activated:Connect(function()
guiController:Close(craftingGui)
if tempObject and tempObject.Parent then
tempObject:Destroy()
end
end)
end
local scrollingFrame = mainFrame:FindFirstChild("ScrollingFrame")
if scrollingFrame then
for _, item in ipairs(scrollingFrame:GetChildren()) do
if item:IsA("Frame") and item.Name ~= "ItemPadding" then
local mainItemFrame = item:FindFirstChild("Main_Frame")
if mainItemFrame then
local craftButton = mainItemFrame:FindFirstChild("CraftButton")
if craftButton then
craftButton.Active = true
end
local robuxBuy = mainItemFrame:FindFirstChild("Robux_Buy")
if robuxBuy then
robuxBuy.Active = true
end
local infoButton = mainItemFrame:FindFirstChild("InfoButton")
if infoButton then
infoButton.Active = true
end
local oddsButton = mainItemFrame:FindFirstChild("OddsButton")
if oddsButton then
oddsButton.Active = true
end
end
end
end
end
end
end
end
Tabs.Visuals:Section({ Title = "Open Shops UI" })
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Traveling Merchant Shop",
Callback = function()
openShop(shopControllers.TravelingMerchant, "TravelingMerchantShop_UI", "Traveling Merchant")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Egg Shop",
Callback = function()
openShop(shopControllers.EggShop, "PetShop_UI", "Egg Shop")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Cosmetic Shop",
Callback = function()
openShop(shopControllers.CosmeticShop, "CosmeticShop_UI", "Cosmetic Shop")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Garden Coin Shop",
Callback = function()
openShop(shopControllers.GardenCoinShop, "GardenCoinShop_UI", "Garden Coin Shop")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Gear Shop",
Callback = function()
openShop(shopControllers.GearShop, "Gear_Shop", "Gear Shop")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Seed Shop",
Callback = function()
openShop(shopControllers.SeedShop, "Seed_Shop", "Seed Shop")
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Carrot Coin Shop",
Callback = function()
openShop(shopControllers.CarrotCoinShop, "BuyCarrotsUI", "Carrot Coin Shop")
end
})
Tabs.Visuals:Section({ Title = "Open Game Pass UI" })
Tabs.Visuals:Space()
Tabs.Visuals:Button({
Title = "Open Season Pass",
Callback = function()
seasonPassToggler:Toggle()
openShop(shopControllers.SeasonPass, "SeasonPassUI", "Season Pass")
end
})
Tabs.Visuals:Section({ Title = "Open Crating Table UI" })
for machineType, _ in pairs(recipeRegistry.RecipiesSortedByMachineType) do
Tabs.Visuals:Button({
Title = "Open " .. machineType .. " Crafting",
Callback = function()
openCrafting(machineType)
end
})
end
CalculatePlantValue = require(ReplicatedStorage.Modules.CalculatePlantValue)
fruitEspBoxes = {}
playerEspBoxes = {}
activeConnections = {}
renderConnection = nil
fruitEspEnabled = false
playerEspEnabled = false
currentFruitBoxType = "2D"
currentPlayerBoxType = "2D"
playerEspElements = {}
fruitEspElements = {}
cachedPlayers = {}
lastPlayerCacheUpdate = 0
lastFruitUpdate = 0
fruitUpdateInterval = 0.2
PlayerESP = {
names = false,
distance = false,
}
PlayerHighlights = false
FruitESP = {
names = false,
distance = false,
weight = false,
mutations = false,
Value = false,
variant = false,
}
FruitHighlights = false
fruitWhitelist = {}
mutationWhitelist = {}
variantWhitelist = {}
fruitWhitelistNormalized = {}
mutationWhitelistNormalized = {}
variantWhitelistNormalized = {}
fruitNamesCache = {}
highlightedFruits = {}
fruitColorCache = {}
fruitValueCache = {}
weightMin = 0
weightMax = 100
weightWhitelistEnabled = false
valueMin = 0
valueMax = 999999999
valueFilterEnabled = false
variantFilterEnabled = false
CONFIG = {
MAX_BOX_SIZE = 100,
MIN_BOX_SIZE = 5,
BASE_MULTIPLIER = 12,
DISTANCE_FALLOFF = 30,
PADDING_X = 4,
PADDING_Y = 6
}
function getFruitPosition(fruitPart)
if fruitPart:IsA("BasePart") then
return fruitPart.Position
elseif fruitPart:IsA("Model") then
return fruitPart:GetPivot().Position
end
return Vector3.new(0, 0, 0)
end
function getFruitVisualPart(fruitPart)
if fruitPart:IsA("BasePart") then
return fruitPart
elseif fruitPart:IsA("Model") then
return fruitPart:FindFirstChildWhichIsA("BasePart") or fruitPart
end
return fruitPart
end
function updateFruitWhitelistNormalized()
fruitWhitelistNormalized = {}
for _, fruitData in pairs(fruitWhitelist) do
fruitName = fruitData.Title or fruitData
if type(fruitName) == "string" then
fruitWhitelistNormalized[fruitName:lower()] = true
end
end
mutationWhitelistNormalized = {}
for _, mutationData in pairs(mutationWhitelist) do
mutationName = mutationData.Title or mutationData
if type(mutationName) == "string" then
mutationWhitelistNormalized[mutationName:lower()] = true
end
end
variantWhitelistNormalized = {}
for _, variantData in pairs(variantWhitelist) do
variantName = variantData.Title or variantData
if type(variantName) == "string" then
variantWhitelistNormalized[variantName:lower()] = true
end
end
end
function getFruitDisplayName(fruitName)
return fruitName
end
function getFruitValue(fruitObj)
if not fruitObj then return 0 end
fruitId = fruitObj:GetFullName()
if fruitValueCache[fruitId] and tick() - fruitValueCache[fruitId].timestamp < 5 then
return fruitValueCache[fruitId].value
end
success, value = pcall(function()
return CalculatePlantValue(fruitObj)
end)
if success and value and type(value) == "number" and value > 0 then
fruitValueCache[fruitId] = {
value = value,
timestamp = tick()
}
if #fruitValueCache > 200 then
newCache = {}
count = 0
for k, v in pairs(fruitValueCache) do
if count < 100 then
newCache[k] = v
count = count + 1
else
break
end
end
fruitValueCache = newCache
end
return value
end
return 0
end
function checkFruitMutation(fruitObj)
if not fruitObj then return nil end
attributes = fruitObj:GetAttributes()
for attrName, attrValue in pairs(attributes) do
if type(attrValue) == "boolean" and attrValue == true then
attrLower = attrName:lower()
if #mutationWhitelist == 0 or mutationWhitelistNormalized[attrLower] then
return attrName
end
end
end
return nil
end
function checkFruitVariant(fruitObj)
if not fruitObj then return nil end
variant = fruitObj:FindFirstChild("Variant")
if variant and variant:IsA("StringValue") and variant.Value ~= "" then
return variant.Value
end
variantAttr = fruitObj:GetAttribute("Variant")
if variantAttr and variantAttr ~= "" then
return tostring(variantAttr)
end
parent = fruitObj.Parent
if parent then
parentVariant = parent:FindFirstChild("Variant")
if parentVariant and parentVariant:IsA("StringValue") and parentVariant.Value ~= "" then
return parentVariant.Value
end
parentVariantAttr = parent:GetAttribute("Variant")
if parentVariantAttr and parentVariantAttr ~= "" then
return tostring(parentVariantAttr)
end
grandParent = parent.Parent
if grandParent then
grandVariant = grandParent:FindFirstChild("Variant")
if grandVariant and grandVariant:IsA("StringValue") and grandVariant.Value ~= "" then
return grandVariant.Value
end
grandVariantAttr = grandParent:GetAttribute("Variant")
if grandVariantAttr and grandVariantAttr ~= "" then
return tostring(grandVariantAttr)
end
end
end
return nil
end
function getFruitWeight(fruitObj)
if not fruitObj then return 0 end
weightObject = fruitObj:FindFirstChild("Weight")
if weightObject and weightObject:IsA("ObjectValue") then
weightValue = weightObject.Value
if weightValue and typeof(weightValue) == "number" then
return weightValue
end
end
numberValue = fruitObj:FindFirstChild("Weight")
if numberValue and numberValue:IsA("NumberValue") then
return numberValue.Value
end
weightAttr = fruitObj:GetAttribute("Weight")
if weightAttr and typeof(weightAttr) == "number" then
return weightAttr
end
return 0
end
function isFruitWhitelisted(fruitObj)
if not fruitObj then return false end
fruitName = fruitObj.Name
fruitNameLower = fruitName:lower()
if #fruitWhitelist > 0 and not fruitWhitelistNormalized[fruitNameLower] then
return false
end
if #mutationWhitelist > 0 then
mutation = checkFruitMutation(fruitObj)
if not mutation or not mutationWhitelistNormalized[mutation:lower()] then
return false
end
end
if variantFilterEnabled and #variantWhitelist > 0 then
variant = checkFruitVariant(fruitObj)
if not variant or not variantWhitelistNormalized[variant:lower()] then
return false
end
end
if weightWhitelistEnabled then
weight = getFruitWeight(fruitObj)
if weight < weightMin or weight > weightMax then
return false
end
end
if valueFilterEnabled then
value = getFruitValue(fruitObj)
if value < valueMin or value > valueMax then
return false
end
end
return true
end
function getMyFarm()
myUsername = LocalPlayer.Name
farmFolder = Workspace:FindFirstChild("Farm")
if not farmFolder then return nil end
for _, plot in pairs(farmFolder:GetChildren()) do
sign = plot:FindFirstChild("Sign")
if sign then
owner = sign:GetAttribute("_owner")
if owner and owner == myUsername then
return plot
end
end
end
return nil
end
function getFruitColor(fruitPart)
if not fruitPart then return Color3.fromRGB(255, 215, 0) end
local visualPart = getFruitVisualPart(fruitPart)
if visualPart and visualPart:IsA("BasePart") then
partColor = visualPart.Color
if partColor.R < 0.95 or partColor.G < 0.95 or partColor.B < 0.95 then
return partColor
end
end
if fruitPart:IsA("Model") then
descendants = fruitPart:GetDescendants()
for _, descendant in ipairs(descendants) do
if descendant:IsA("BasePart") then
descendantColor = descendant.Color
if descendantColor.R < 0.95 or descendantColor.G < 0.95 or descendantColor.B < 0.95 then
return descendantColor
end
elseif descendant:IsA("MeshPart") then
descendantColor = descendant.Color
if descendantColor.R < 0.95 or descendantColor.G < 0.95 or descendantColor.B < 0.95 then
return descendantColor
end
end
end
end
return Color3.fromRGB(255, 215, 0)
end
function getMutationColor(mutationName)
mutationColors = {
["Fire"] = Color3.fromRGB(255, 100, 100),
["Ice"] = Color3.fromRGB(100, 200, 255),
["Poison"] = Color3.fromRGB(150, 255, 100),
["Electric"] = Color3.fromRGB(255, 255, 100),
["Golden"] = Color3.fromRGB(255, 215, 0),
["Crystal"] = Color3.fromRGB(200, 100, 255),
["Mega"] = Color3.fromRGB(255, 150, 50),
["Tiny"] = Color3.fromRGB(150, 150, 255),
["Radioactive"] = Color3.fromRGB(100, 255, 100),
["Shadow"] = Color3.fromRGB(100, 100, 100),
["Rainbow"] = Color3.fromRGB(255, 100, 255)
}
lowerMutation = mutationName:lower()
for mutationKey, color in pairs(mutationColors) do
if lowerMutation:find(mutationKey:lower()) then
return color
end
end
return Color3.fromRGB(200, 200, 200)
end
function getVariantColor(variantName)
variantColors = {
["Normal"] = Color3.fromRGB(200, 200, 200),
["Gold"] = Color3.fromRGB(255, 215, 0),
["Rainbow"] = Color3.fromRGB(255, 100, 255),
["Silver"] = Color3.fromRGB(192, 192, 192),
["Diamond"] = Color3.fromRGB(185, 242, 255),
["Crystal"] = Color3.fromRGB(170, 255, 255),
["Shadow"] = Color3.fromRGB(80, 80, 80),
["Lava"] = Color3.fromRGB(255, 100, 0),
["Frost"] = Color3.fromRGB(150, 255, 255),
["Nature"] = Color3.fromRGB(100, 255, 100)
}
lowerVariant = variantName:lower()
for variantKey, color in pairs(variantColors) do
if lowerVariant:find(variantKey:lower()) then
return color
end
end
return Color3.fromRGB(147, 112, 219)
end
function cleanupPlayerESP()
for target, esp in pairs(playerEspElements) do
if esp.billboardData then
esp.billboardData.billboard:Destroy()
end
end
playerEspElements = {}
end
function cleanupFruitESP()
for target, esp in pairs(fruitEspElements) do
if esp.billboardData then
esp.billboardData.billboard:Destroy()
end
end
fruitEspElements = {}
fruitColorCache = {}
end
function getDistanceFromPlayer(targetPosition)
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return 0 end
return (targetPosition - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
end
function getTeamColor(LocalPlayer)
local team = LocalPlayer.Team
if team then
return team.TeamColor.Color
end
return Color3.fromRGB(0, 255, 0)
end
function createBillboard(fruitPart, fruitObj)
billboard = Instance.new("BillboardGui")
billboard.Name = "EspBillboard"
billboard.Adornee = getFruitVisualPart(fruitPart)
billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 65)
billboard.StudsOffset = Vector3.new(0, 3, 0)
billboard.MaxDistance = 100
billboard.ClipsDescendants = false
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Active = true
container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.BorderSizePixel = 0
container.Parent = billboard
infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.Size = UDim2.new(1, 0, 1, 0)
infoLabel.Position = UDim2.new(0, 0, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.GothamSemibold
infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextStrokeTransparency = 0.5
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.TextWrapped = true
infoLabel.Visible = false
infoLabel.Parent = container
billboard.Parent = fruitObj
return {
billboard = billboard,
infoLabel = infoLabel
}
end
function getCachedPlayers()
if tick() - lastPlayerCacheUpdate < 1 then
return cachedPlayers
end
lastPlayerCacheUpdate = tick()
cachedPlayers = Players:GetPlayers()
return cachedPlayers
end
function findCollectibleFruits()
fruits = {}
myFarm = getMyFarm()
if not myFarm then return fruits end
importantFolder = myFarm:FindFirstChild("Important")
if not importantFolder then return fruits end
plantsPhysical = importantFolder:FindFirstChild("Plants_Physical")
if not plantsPhysical then return fruits end
for _, plant in pairs(plantsPhysical:GetChildren()) do
fruitsContainer = plant:FindFirstChild("Fruits")
if fruitsContainer then
for _, fruit in pairs(fruitsContainer:GetChildren()) do
if fruit:IsA("BasePart") or fruit:IsA("Model") then
if isFruitWhitelisted(fruit) then
table.insert(fruits, {
part = fruit,
position = getFruitPosition(fruit),
fruitObj = fruit
})
end
end
end
end
end
return fruits
end
function getPlayerBoxColor(LocalPlayer)
return Color3.new(1, 1, 1)
end
function getPlayerModelSize(Character)
local rootPart = Character:FindFirstChild("HumanoidRootPart")
if not rootPart then
return Vector3.new(4, 6, 4)
end
local minX, minY, minZ = math.huge, math.huge, math.huge
local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
for _, part in ipairs(Character:GetChildren()) do
if part:IsA("BasePart") and part ~= rootPart then
local pos = part.Position
local size = part.Size
local min = pos - size/2
local max = pos + size/2
minX = math.min(minX, min.X)
minY = math.min(minY, min.Y)
minZ = math.min(minZ, min.Z)
maxX = math.max(maxX, max.X)
maxY = math.max(maxY, max.Y)
maxZ = math.max(maxZ, max.Z)
end
end
if minX == math.huge then
return Vector3.new(4, 6, 4)
end
local width = maxX - minX
local height = maxY - minY
local depth = maxZ - minZ
return Vector3.new(width + 0.5, height + 0.5, depth + 0.5)
end
function createPlayer3DBox(LocalPlayer, Character)
if not Character then return end
local rootPart = Character:FindFirstChild("HumanoidRootPart")
if not rootPart then return end
local adornmentFolder = Character:FindFirstChild("PlayerOutlineAdornments")
if adornmentFolder then
return
end
local modelSize = getPlayerModelSize(Character)
local offsetX = modelSize.X / 2
local offsetY = modelSize.Y / 2
local offsetZ = modelSize.Z / 2
local thickness = 0.15
local transparency = 0.2
local boxColor = getPlayerBoxColor(LocalPlayer)
adornmentFolder = Instance.new("Folder")
adornmentFolder.Name = "PlayerOutlineAdornments"
adornmentFolder.Parent = Character
local edges = {
{Vector3.new(0, offsetY, offsetZ), Vector3.new(modelSize.X, thickness, thickness), "TopFrontEdge"},
{Vector3.new(0, offsetY, -offsetZ), Vector3.new(modelSize.X, thickness, thickness), "TopBackEdge"},
{Vector3.new(-offsetX, offsetY, 0), Vector3.new(thickness, thickness, modelSize.Z), "TopLeftEdge"},
{Vector3.new(offsetX, offsetY, 0), Vector3.new(thickness, thickness, modelSize.Z), "TopRightEdge"},
{Vector3.new(0, -offsetY, offsetZ), Vector3.new(modelSize.X, thickness, thickness), "BottomFrontEdge"},
{Vector3.new(0, -offsetY, -offsetZ), Vector3.new(modelSize.X, thickness, thickness), "BottomBackEdge"},
{Vector3.new(-offsetX, -offsetY, 0), Vector3.new(thickness, thickness, modelSize.Z), "BottomLeftEdge"},
{Vector3.new(offsetX, -offsetY, 0), Vector3.new(thickness, thickness, modelSize.Z), "BottomRightEdge"},
{Vector3.new(-offsetX, 0, offsetZ), Vector3.new(thickness, modelSize.Y, thickness), "FrontLeftEdge"},
{Vector3.new(offsetX, 0, offsetZ), Vector3.new(thickness, modelSize.Y, thickness), "FrontRightEdge"},
{Vector3.new(-offsetX, 0, -offsetZ), Vector3.new(thickness, modelSize.Y, thickness), "BackLeftEdge"},
{Vector3.new(offsetX, 0, -offsetZ), Vector3.new(thickness, modelSize.Y, thickness), "BackRightEdge"}
}
for _, edge in ipairs(edges) do
local position = edge[1]
local size = edge[2]
local name = edge[3]
local boxAdornment = Instance.new("BoxHandleAdornment")
boxAdornment.Name = name
boxAdornment.Adornee = rootPart
boxAdornment.Size = size
boxAdornment.CFrame = CFrame.new(position)
boxAdornment.Color3 = boxColor
boxAdornment.Transparency = transparency
boxAdornment.ZIndex = 10
boxAdornment.AlwaysOnTop = true
boxAdornment.Visible = true
boxAdornment.Parent = adornmentFolder
end
end
function clearPlayer3DBox(Character)
local folder = Character:FindFirstChild("PlayerOutlineAdornments")
if folder then
folder:Destroy()
end
end
function updatePlayer3DBoxColors(LocalPlayer, Character)
if not Character then return end
local newColor = getPlayerBoxColor(LocalPlayer)
local folder = Character:FindFirstChild("PlayerOutlineAdornments")
if folder then
for _, adornment in ipairs(folder:GetChildren()) do
if adornment:IsA("BoxHandleAdornment") then
adornment.Color3 = newColor
end
end
end
end
function createPlayer2DBox(LocalPlayer)
if playerEspBoxes[LocalPlayer] then
return
end
if LocalPlayer == LocalPlayer then return end
if not Character then return end
local billboard = Instance.new("BillboardGui")
billboard.Name = "PlayerESPBox_"..LocalPlayer.Name
billboard.Adornee = Character
billboard.Size = UDim2.new(0, 40, 0, 60)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.ClipsDescendants = false
local boxFrame = Instance.new("Frame")
boxFrame.Name = "BoxFrame"
boxFrame.Size = UDim2.new(1, 0, 1, 0)
boxFrame.BackgroundTransparency = 1
boxFrame.BackgroundColor3 = Color3.new(1, 1, 1)
boxFrame.BorderSizePixel = 0
boxFrame.Parent = billboard
local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 1.5
uiStroke.Transparency = 0
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Color = getPlayerBoxColor(LocalPlayer)
uiStroke.Parent = boxFrame
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "PlayerName"
nameLabel.Size = UDim2.new(1, 0, 0, 16)
nameLabel.Position = UDim2.new(0, 0, 0, -18)
nameLabel.BackgroundTransparency = 0.5
nameLabel.BackgroundColor3 = Color3.new(0, 0, 0)
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.Text = LocalPlayer.Name
nameLabel.Font = Enum.Font.SourceSansBold
nameLabel.TextSize = 12
nameLabel.BorderSizePixel = 0
nameLabel.Parent = billboard
billboard.Parent = Character
playerEspBoxes[LocalPlayer] = billboard
end
function removePlayer2DBox(LocalPlayer)
if playerEspBoxes[LocalPlayer] then
playerEspBoxes[LocalPlayer]:Destroy()
playerEspBoxes[LocalPlayer] = nil
end
end
function getPlayerDimensions(Character, rootPart)
local minX, minY, minZ = math.huge, math.huge, math.huge
local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
for _, part in ipairs(Character:GetDescendants()) do
if part:IsA("BasePart") and part ~= rootPart then
local partPos = part.Position
local partSize = part.Size / 2
local relativePos = rootPart.CFrame:PointToObjectSpace(partPos)
minX = math.min(minX, relativePos.X - partSize.X)
maxX = math.max(maxX, relativePos.X + partSize.X)
minY = math.min(minY, relativePos.Y - partSize.Y)
maxY = math.max(maxY, relativePos.Y + partSize.Y)
minZ = math.min(minZ, relativePos.Z - partSize.Z)
maxZ = math.max(maxZ, relativePos.Z + partSize.Z)
end
end
return {
width = math.max(maxX - minX, 3),
height = math.max(maxY - minY, 4)
}
end
function calculateBoxSize(distance, baseWidth, baseHeight)
local widthPx, heightPx
if distance <= CONFIG.DISTANCE_FALLOFF then
widthPx = math.min(baseWidth, CONFIG.MAX_BOX_SIZE)
heightPx = math.min(baseHeight, CONFIG.MAX_BOX_SIZE)
else
local falloffFactor = CONFIG.DISTANCE_FALLOFF / distance
local baseWidthCapped = math.min(baseWidth, CONFIG.MAX_BOX_SIZE)
local baseHeightCapped = math.min(baseHeight, CONFIG.MAX_BOX_SIZE)
widthPx = baseWidthCapped * falloffFactor
heightPx = baseHeightCapped * falloffFactor
end
widthPx = math.max(math.floor(widthPx), CONFIG.MIN_BOX_SIZE)
heightPx = math.max(math.floor(heightPx), CONFIG.MIN_BOX_SIZE)
return widthPx, heightPx
end
function getFruitSize(fruitPart)
local model = fruitPart
if fruitPart:IsA("BasePart") then
model = fruitPart.Parent
end
if model and model:IsA("Model") then
local minX, minY, minZ = math.huge, math.huge, math.huge
local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
for _, part in ipairs(model:GetDescendants()) do
if part:IsA("BasePart") then
local pos = part.Position
local size = part.Size / 2
minX = math.min(minX, pos.X - size.X)
maxX = math.max(maxX, pos.X + size.X)
minY = math.min(minY, pos.Y - size.Y)
maxY = math.max(maxY, pos.Y + size.Y)
minZ = math.min(minZ, pos.Z - size.Z)
maxZ = math.max(maxZ, pos.Z + size.Z)
end
end
if minX ~= math.huge then
return Vector3.new(maxX - minX, maxY - minY, maxZ - minZ)
end
elseif fruitPart:IsA("BasePart") then
return fruitPart.Size
end
return Vector3.new(2, 2, 2)
end
function createFruit3DBox(fruitPart)
if not fruitPart then return end
local visualPart = getFruitVisualPart(fruitPart)
if not visualPart then return end
local model = fruitPart.Parent
if not model then return end
local adornmentFolder = model:FindFirstChild("FruitOutlineAdornments")
if adornmentFolder then
return
end
local fruitSize = getFruitSize(fruitPart)
local offsetX = fruitSize.X / 2
local offsetY = fruitSize.Y / 2
local offsetZ = fruitSize.Z / 2
local thickness = 0.1
local transparency = 0.2
local fruitColor = getFruitColor(fruitPart)
adornmentFolder = Instance.new("Folder")
adornmentFolder.Name = "FruitOutlineAdornments"
adornmentFolder.Parent = model
local edges = {
{Vector3.new(0, offsetY, offsetZ), Vector3.new(fruitSize.X, thickness, thickness), "TopFrontEdge"},
{Vector3.new(0, offsetY, -offsetZ), Vector3.new(fruitSize.X, thickness, thickness), "TopBackEdge"},
{Vector3.new(-offsetX, offsetY, 0), Vector3.new(thickness, thickness, fruitSize.Z), "TopLeftEdge"},
{Vector3.new(offsetX, offsetY, 0), Vector3.new(thickness, thickness, fruitSize.Z), "TopRightEdge"},
{Vector3.new(0, -offsetY, offsetZ), Vector3.new(fruitSize.X, thickness, thickness), "BottomFrontEdge"},
{Vector3.new(0, -offsetY, -offsetZ), Vector3.new(fruitSize.X, thickness, thickness), "BottomBackEdge"},
{Vector3.new(-offsetX, -offsetY, 0), Vector3.new(thickness, thickness, fruitSize.Z), "BottomLeftEdge"},
{Vector3.new(offsetX, -offsetY, 0), Vector3.new(thickness, thickness, fruitSize.Z), "BottomRightEdge"},
{Vector3.new(-offsetX, 0, offsetZ), Vector3.new(thickness, fruitSize.Y, thickness), "FrontLeftEdge"},
{Vector3.new(offsetX, 0, offsetZ), Vector3.new(thickness, fruitSize.Y, thickness), "FrontRightEdge"},
{Vector3.new(-offsetX, 0, -offsetZ), Vector3.new(thickness, fruitSize.Y, thickness), "BackLeftEdge"},
{Vector3.new(offsetX, 0, -offsetZ), Vector3.new(thickness, fruitSize.Y, thickness), "BackRightEdge"}
}
for _, edge in ipairs(edges) do
local position = edge[1]
local size = edge[2]
local name = edge[3]
local boxAdornment = Instance.new("BoxHandleAdornment")
boxAdornment.Name = name
boxAdornment.Adornee = visualPart
boxAdornment.Size = size
boxAdornment.CFrame = CFrame.new(position)
boxAdornment.Color3 = fruitColor
boxAdornment.Transparency = transparency
boxAdornment.ZIndex = 10
boxAdornment.AlwaysOnTop = true
boxAdornment.Visible = true
boxAdornment.Parent = adornmentFolder
end
end
function clearFruit3DBox(fruitPart)
local model = fruitPart.Parent
if model then
local folder = model:FindFirstChild("FruitOutlineAdornments")
if folder then
folder:Destroy()
end
end
end
function createFruit2DBox(fruitPart)
if not fruitPart then return end
local visualPart = getFruitVisualPart(fruitPart)
if not visualPart then return end
local model = fruitPart.Parent
if not model then return end
if fruitEspBoxes[fruitPart] then
return
end
local billboard = Instance.new("BillboardGui")
billboard.Name = "FruitESPBox"
billboard.Adornee = visualPart
billboard.Size = UDim2.new(0, 40, 0, 40)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.AlwaysOnTop = true
billboard.LightInfluence = 0
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.ClipsDescendants = false
local boxFrame = Instance.new("Frame")
boxFrame.Name = "BoxFrame"
boxFrame.Size = UDim2.new(1, 0, 1, 0)
boxFrame.BackgroundTransparency = 1
boxFrame.BackgroundColor3 = Color3.new(1, 1, 1)
boxFrame.BorderSizePixel = 0
boxFrame.Parent = billboard
local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = 1.5
uiStroke.Transparency = 0
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Color = getFruitColor(fruitPart)
uiStroke.Parent = boxFrame
billboard.Parent = model
fruitEspBoxes[fruitPart] = billboard
end
function removeFruit2DBox(fruitPart)
if fruitEspBoxes[fruitPart] then
fruitEspBoxes[fruitPart]:Destroy()
fruitEspBoxes[fruitPart] = nil
end
end
function getFruitDimensions(fruitPart)
local fruitSize = getFruitSize(fruitPart)
return {
width = fruitSize.X,
height = fruitSize.Y
}
end
function updatePlayer2DBoxes()
for LocalPlayer, billboard in pairs(playerEspBoxes) do
if Character and billboard and billboard.Parent then
local Humanoid = Character:FindFirstChild("Humanoid")
local rootPart = Character:FindFirstChild("HumanoidRootPart")
if Humanoid and rootPart and Humanoid.Health > 0 then
local dimensions = getPlayerDimensions(Character, rootPart)
local baseWidth = dimensions.width * CONFIG.BASE_MULTIPLIER + CONFIG.PADDING_X
local baseHeight = dimensions.height * CONFIG.BASE_MULTIPLIER + CONFIG.PADDING_Y
local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
local widthPx, heightPx = calculateBoxSize(distance, baseWidth, baseHeight)
billboard.Size = UDim2.new(0, widthPx, 0, heightPx)
local boxFrame = billboard:FindFirstChild("BoxFrame")
if boxFrame then
local stroke = boxFrame:FindFirstChild("UIStroke")
if stroke then
stroke.Color = getPlayerBoxColor(LocalPlayer)
end
end
local nameLabel = billboard:FindFirstChild("PlayerName")
if nameLabel then
nameLabel.Size = UDim2.new(1, 0, 0, math.min(16, heightPx * 0.2))
nameLabel.Position = UDim2.new(0, 0, 0, -math.min(18, heightPx * 0.25))
nameLabel.TextSize = math.max(math.min(12, widthPx * 0.15), 8)
end
end
end
end
end
function updateFruit2DBoxes()
for fruitPart, billboard in pairs(fruitEspBoxes) do
if fruitPart and fruitPart.Parent and billboard and billboard.Parent then
local visualPart = getFruitVisualPart(fruitPart)
if not visualPart then continue end
local fruitPosition = getFruitPosition(fruitPart)
local dimensions = getFruitDimensions(fruitPart)
local baseWidth = dimensions.width * CONFIG.BASE_MULTIPLIER + CONFIG.PADDING_X
local baseHeight = dimensions.height * CONFIG.BASE_MULTIPLIER + CONFIG.PADDING_Y
local distance = (Camera.CFrame.Position - fruitPosition).Magnitude
local widthPx, heightPx = calculateBoxSize(distance, baseWidth, baseHeight)
billboard.Size = UDim2.new(0, widthPx, 0, heightPx)
local boxFrame = billboard:FindFirstChild("BoxFrame")
if boxFrame then
local stroke = boxFrame:FindFirstChild("UIStroke")
if stroke then
stroke.Color = getFruitColor(fruitPart)
end
end
end
end
end
function onPlayerCharacterAdded2D(LocalPlayer, Character)
local Humanoid = Character:WaitForChild("Humanoid", 5)
if Humanoid then
createPlayer2DBox(LocalPlayer)
end
end
function onPlayerCharacterAdded3D(LocalPlayer, Character)
if LocalPlayer == LocalPlayer then return end
Character:WaitForChild("HumanoidRootPart")
clearPlayer3DBox(Character)
createPlayer3DBox(LocalPlayer, Character)
if activeConnections[LocalPlayer] then
if activeConnections[LocalPlayer].teamChanged then
activeConnections[LocalPlayer].teamChanged:Disconnect()
end
if activeConnections[LocalPlayer].sizeChanged then
activeConnections[LocalPlayer].sizeChanged:Disconnect()
end
end
local teamChangedConnection = LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
updatePlayer3DBoxColors(LocalPlayer, Character)
end)
local sizeChangedConnection = Character.ChildAdded:Connect(function()
clearPlayer3DBox(Character)
createPlayer3DBox(LocalPlayer, Character)
end)
activeConnections[LocalPlayer] = activeConnections[LocalPlayer] or {}
activeConnections[LocalPlayer].teamChanged = teamChangedConnection
activeConnections[LocalPlayer].sizeChanged = sizeChangedConnection
end
function onFruitAdded(fruitPart)
if fruitPart and fruitPart.Parent then
if currentFruitBoxType == "2D" then
createFruit2DBox(fruitPart)
else
clearFruit3DBox(fruitPart)
createFruit3DBox(fruitPart)
end
end
end
function updatePlayerESP()
if not PlayerESP.names and not PlayerESP.distance then
cleanupPlayerESP()
return
end
currentPlayerTargets = {}
players = getCachedPlayers()
for _, otherPlayer in ipairs(players) do
if otherPlayer ~= LocalPlayer then
local Character = otherPlayer.Character
if Character then
local hrp = Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Character:FindFirstChild("Humanoid")
if hrp and Humanoid and Humanoid.Health > 0 then
currentPlayerTargets[Character] = true
if not playerEspElements[Character] then
playerEspElements[Character] = {}
local billboard = Instance.new("BillboardGui")
billboard.Name = "PlayerEspBillboard"
billboard.Adornee = Character
billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 40)
billboard.StudsOffset = Vector3.new(0, 3.5, 0)
billboard.MaxDistance = 100
billboard.ClipsDescendants = false
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Active = true
local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.Size = UDim2.new(1, 0, 1, 0)
infoLabel.Position = UDim2.new(0, 0, 0, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.TextSize = 12
infoLabel.Font = Enum.Font.GothamSemibold
infoLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
infoLabel.TextStrokeTransparency = 0.5
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Center
infoLabel.TextWrapped = true
infoLabel.Visible = false
infoLabel.Parent = billboard
billboard.Parent = Character
playerEspElements[Character].billboardData = {
billboard = billboard,
infoLabel = infoLabel
}
end
local esp = playerEspElements[Character]
local distance = getDistanceFromPlayer(hrp.Position)
local playerColor = getTeamColor(otherPlayer)
if esp.billboardData then
local billboard = esp.billboardData.billboard
local infoLabel = esp.billboardData.infoLabel
billboard.Enabled = true
billboard.MaxDistance = math.min(100, distance * 2)
infoLabel.Visible = PlayerESP.names or PlayerESP.distance
if infoLabel.Visible then
local infoText = ""
if PlayerESP.names then
infoText = otherPlayer.Name
end
if PlayerESP.distance then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. string.format("Dist: %.1f", distance)
end
infoLabel.Text = infoText
infoLabel.TextColor3 = playerColor
end
end
end
end
end
end
for target, esp in pairs(playerEspElements) do
if not currentPlayerTargets[target] then
if esp.billboardData then
esp.billboardData.billboard:Destroy()
end
playerEspElements[target] = nil
end
end
end
function updateFruitESP()
if tick() - lastFruitUpdate < 0.2 then
return
end
lastFruitUpdate = tick()
if not FruitESP.names and not FruitESP.distance and
not FruitESP.weight and not FruitESP.mutations and
not FruitESP.value and not FruitESP.variant then
cleanupFruitESP()
return
end
currentFruitTargets = {}
fruits = findCollectibleFruits()
for _, fruitData in ipairs(fruits) do
local fruitPart = fruitData.part
local position = fruitData.position
local fruitObj = fruitData.fruitObj
if fruitPart and fruitPart.Parent then
currentFruitTargets[fruitPart] = true
if not fruitEspElements[fruitPart] then
fruitEspElements[fruitPart] = {}
fruitEspElements[fruitPart].billboardData = createBillboard(fruitPart, fruitObj)
end
local esp = fruitEspElements[fruitPart]
local distance = getDistanceFromPlayer(position)
local fruitColor = getFruitColor(fruitPart)
local mutation = checkFruitMutation(fruitObj)
local variant = checkFruitVariant(fruitObj)
if mutation then
local mutationColor = getMutationColor(mutation)
fruitColor = Color3.new(
(fruitColor.R * 0.7 + mutationColor.R * 0.3),
(fruitColor.G * 0.7 + mutationColor.G * 0.3),
(fruitColor.B * 0.7 + mutationColor.B * 0.3)
)
end
if variant and FruitESP.variant then
local variantColor = getVariantColor(variant)
fruitColor = Color3.new(
(fruitColor.R * 0.6 + variantColor.R * 0.4),
(fruitColor.G * 0.6 + variantColor.G * 0.4),
(fruitColor.B * 0.6 + variantColor.B * 0.4)
)
end
if esp.billboardData then
local billboard = esp.billboardData.billboard
local infoLabel = esp.billboardData.infoLabel
billboard.Enabled = true
billboard.MaxDistance = math.min(100, distance * 2)
local weight = getFruitWeight(fruitObj)
local value = getFruitValue(fruitObj)
local states = FruitESP
infoLabel.Visible = states.names or states.distance or states.weight or (states.mutations and mutation ~= nil) or (states.value and value > 0) or (states.variant and variant ~= nil)
if infoLabel.Visible then
local infoText = ""
if states.names then
infoText = getFruitDisplayName(fruitObj.Name)
end
if states.mutations and mutation then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. "Mut: " .. mutation
end
if states.variant and variant then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. "Var: " .. variant
end
if states.value and value > 0 then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. string.format("Value: $%.2f", value)
end
if states.weight and weight > 0 then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. string.format("Weight: %.1f", weight)
end
if states.distance then
if infoText ~= "" then
infoText = infoText .. "\n"
end
infoText = infoText .. string.format("Dist: %.1f", distance)
end
infoLabel.Text = infoText
infoLabel.TextColor3 = fruitColor
infoLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
end
end
end
end
for target, esp in pairs(fruitEspElements) do
if not currentFruitTargets[target] then
if esp.billboardData then
esp.billboardData.billboard:Destroy()
end
fruitEspElements[target] = nil
fruitColorCache[target] = nil
end
end
end
function removeAllPlayerESP()
for LocalPlayer, billboard in pairs(playerEspBoxes) do
billboard:Destroy()
end
playerEspBoxes = {}
for LocalPlayer, connections in pairs(activeConnections) do
if connections.teamChanged then
connections.teamChanged:Disconnect()
end
if connections.sizeChanged then
connections.sizeChanged:Disconnect()
end
if LocalPlayer.Character then
clearPlayer3DBox(LocalPlayer.Character)
end
end
activeConnections = {}
end
function removeAllFruitESP()
for fruitPart, billboard in pairs(fruitEspBoxes) do
billboard:Destroy()
end
fruitEspBoxes = {}
local fruits = findCollectibleFruits()
for _, fruitData in ipairs(fruits) do
if fruitData.part then
clearFruit3DBox(fruitData.part)
end
end
end
function refreshPlayerESP()
removeAllPlayerESP()
for _, LocalPlayer in ipairs(Players:GetPlayers()) do
if LocalPlayer ~= LocalPlayer then
if currentPlayerBoxType == "2D" then
local function onCharacterAdded(Character)
onPlayerCharacterAdded2D(LocalPlayer, Character)
end
if not activeConnections[LocalPlayer] then
activeConnections[LocalPlayer] = {}
end
if activeConnections[LocalPlayer].charAdded then
activeConnections[LocalPlayer].charAdded:Disconnect()
end
local charAddedConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
activeConnections[LocalPlayer].charAdded = charAddedConnection
if LocalPlayer.Character then
onCharacterAdded(LocalPlayer.Character)
end
else
local function onCharacterAdded(Character)
onPlayerCharacterAdded3D(LocalPlayer, Character)
end
if not activeConnections[LocalPlayer] then
activeConnections[LocalPlayer] = {}
end
if activeConnections[LocalPlayer].charAdded then
activeConnections[LocalPlayer].charAdded:Disconnect()
end
local charAddedConnection = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
activeConnections[LocalPlayer].charAdded = charAddedConnection
if LocalPlayer.Character then
onCharacterAdded(LocalPlayer.Character)
end
end
end
end
end
function refreshFruitESP()
removeAllFruitESP()
local fruits = findCollectibleFruits()
for _, fruitData in ipairs(fruits) do
if fruitData.part then
onFruitAdded(fruitData.part)
end
end
end
function playerBoxESP(enabled)
playerEspEnabled = enabled
if playerEspEnabled then
refreshPlayerESP()
if currentPlayerBoxType == "2D" then
if not renderConnection then
renderConnection = RunService.RenderStepped:Connect(function()
updatePlayer2DBoxes()
if fruitEspEnabled and currentFruitBoxType == "2D" then
updateFruit2DBoxes()
end
updatePlayerESP()
updateFruitESP()
end)
end
end
else
removeAllPlayerESP()
if renderConnection and not fruitEspEnabled then
renderConnection:Disconnect()
renderConnection = nil
elseif renderConnection and fruitEspEnabled then
end
end
end
function playerBoxESPtype(boxType)
if boxType == "2D" or boxType == "3D" then
currentPlayerBoxType = boxType
if playerEspEnabled then
refreshPlayerESP()
end
end
end
function fruitBoxESP(enabled)
fruitEspEnabled = enabled
if fruitEspEnabled then
refreshFruitESP()
if currentFruitBoxType == "2D" then
if not renderConnection then
renderConnection = RunService.RenderStepped:Connect(function()
updateFruit2DBoxes()
if playerEspEnabled and currentPlayerBoxType == "2D" then
updatePlayer2DBoxes()
end
updatePlayerESP()
updateFruitESP()
end)
end
end
else
removeAllFruitESP()
if renderConnection and not playerEspEnabled then
renderConnection:Disconnect()
renderConnection = nil
elseif renderConnection and playerEspEnabled then
end
end
end
function fruitBoxESPtype(boxType)
if boxType == "2D" or boxType == "3D" then
currentFruitBoxType = boxType
if fruitEspEnabled then
refreshFruitESP()
end
end
end
function managePlayerESPConnection()
local playerActive = PlayerESP.names or PlayerESP.distance
if playerActive then
if not renderConnection then
renderConnection = RunService.RenderStepped:Connect(function()
updatePlayerESP()
if fruitEspEnabled then
updateFruitESP()
end
if playerEspEnabled and currentPlayerBoxType == "2D" then
updatePlayer2DBoxes()
end
if fruitEspEnabled and currentFruitBoxType == "2D" then
updateFruit2DBoxes()
end
end)
end
else
cleanupPlayerESP()
if not fruitEspEnabled and not playerEspEnabled and renderConnection then
renderConnection:Disconnect()
renderConnection = nil
end
end
end
function manageFruitESPConnection()
local fruitActive = FruitESP.names or FruitESP.distance or
FruitESP.weight or FruitESP.mutations or
FruitESP.value or FruitESP.variant
if fruitActive then
if not renderConnection then
renderConnection = RunService.RenderStepped:Connect(function()
updateFruitESP()
if playerEspEnabled and currentPlayerBoxType == "2D" then
updatePlayer2DBoxes()
end
if fruitEspEnabled and currentFruitBoxType == "2D" then
updateFruit2DBoxes()
end
updatePlayerESP()
end)
end
else
cleanupFruitESP()
if not fruitEspEnabled and not playerEspEnabled and renderConnection then
renderConnection:Disconnect()
renderConnection = nil
end
end
end
function getOutlineColor(fillColor)
return Color3.new(
math.clamp(fillColor.R * 0.7, 0, 1),
math.clamp(fillColor.G * 0.7, 0, 1),
math.clamp(fillColor.B * 0.7, 0, 1)
)
end
function createFruitHighlight(fruitPart, fruitObj)
local highlight = Instance.new("Highlight")
highlight.Name = "FruitHighlight"
highlight.Adornee = getFruitVisualPart(fruitPart)
highlight.FillTransparency = 0.7
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
local fruitColor = getFruitColor(fruitPart)
local mutation = checkFruitMutation(fruitObj)
local variant = checkFruitVariant(fruitObj)
if mutation then
local mutationColor = getMutationColor(mutation)
fruitColor = Color3.new(
(fruitColor.R * 0.7 + mutationColor.R * 0.3),
(fruitColor.G * 0.7 + mutationColor.G * 0.3),
(fruitColor.B * 0.7 + mutationColor.B * 0.3)
)
end
if variant then
local variantColor = getVariantColor(variant)
fruitColor = Color3.new(
(fruitColor.R * 0.6 + variantColor.R * 0.4),
(fruitColor.G * 0.6 + variantColor.G * 0.4),
(fruitColor.B * 0.6 + variantColor.B * 0.4)
)
end
local outlineColor = getOutlineColor(fruitColor)
highlight.FillColor = fruitColor
highlight.OutlineColor = outlineColor
highlight.Parent = fruitPart
return highlight
end
PlayerHighlightsConnection = nil
function startPlayerHighlights()
if not PlayerHighlights then
if PlayerHighlightsConnection then
PlayerHighlightsConnection:Disconnect()
PlayerHighlightsConnection = nil
end
return
end
if PlayerHighlightsConnection then return end
PlayerHighlightsConnection = RunService.Heartbeat:Connect(function()
if not PlayerHighlights then
if PlayerHighlightsConnection then
PlayerHighlightsConnection:Disconnect()
PlayerHighlightsConnection = nil
end
return
end
local players = getCachedPlayers()
for _, plr in ipairs(players) do
if plr ~= LocalPlayer and plr.Character then
local model = plr.Character
local highlight = model:FindFirstChild("PlayerHighlight")
if PlayerHighlights then
local Humanoid = model:FindFirstChildOfClass("Humanoid")
local color = (Humanoid and Humanoid.Health > 0) and getTeamColor(plr) or Color3.fromRGB(150, 150, 150)
local outlineColor = getOutlineColor(color)
if not highlight then
highlight = Instance.new("Highlight")
highlight.Name = "PlayerHighlight"
highlight.Adornee = model
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = model
end
highlight.FillColor = color
highlight.OutlineColor = outlineColor
highlight.Enabled = true
else
if highlight then
highlight:Destroy()
end
end
end
end
end)
end
function stopPlayerHighlights()
if PlayerHighlightsConnection then
PlayerHighlightsConnection:Disconnect()
PlayerHighlightsConnection = nil
end
for _, plr in pairs(getCachedPlayers()) do
if plr and plr.Character then
local highlight = plr.Character:FindFirstChild("PlayerHighlight")
if highlight then
highlight:Destroy()
end
end
end
end
FruitHighlightsConnection = nil
function startFruitHighlights()
if not FruitHighlights then
if FruitHighlightsConnection then
FruitHighlightsConnection:Disconnect()
FruitHighlightsConnection = nil
end
return
end
if FruitHighlightsConnection then return end
FruitHighlightsConnection = RunService.Heartbeat:Connect(function()
if not FruitHighlights then
if FruitHighlightsConnection then
FruitHighlightsConnection:Disconnect()
FruitHighlightsConnection = nil
end
return
end
local fruits = findCollectibleFruits()
local currentFruits = {}
for _, fruitData in ipairs(fruits) do
local fruitPart = fruitData.part
local fruitObj = fruitData.fruitObj
if fruitPart and fruitPart.Parent then
currentFruits[fruitPart] = true
if not highlightedFruits[fruitPart] then
local highlight = createFruitHighlight(fruitPart, fruitObj)
highlightedFruits[fruitPart] = highlight
else
local highlight = highlightedFruits[fruitPart]
if highlight then
local fruitColor = getFruitColor(fruitPart)
local mutation = checkFruitMutation(fruitObj)
local variant = checkFruitVariant(fruitObj)
if mutation then
local mutationColor = getMutationColor(mutation)
fruitColor = Color3.new(
(fruitColor.R * 0.7 + mutationColor.R * 0.3),
(fruitColor.G * 0.7 + mutationColor.G * 0.3),
(fruitColor.B * 0.7 + mutationColor.B * 0.3)
)
end
if variant then
local variantColor = getVariantColor(variant)
fruitColor = Color3.new(
(fruitColor.R * 0.6 + variantColor.R * 0.4),
(fruitColor.G * 0.6 + variantColor.G * 0.4),
(fruitColor.B * 0.6 + variantColor.B * 0.4)
)
end
local outlineColor = getOutlineColor(fruitColor)
highlight.FillColor = fruitColor
highlight.OutlineColor = outlineColor
highlight.Enabled = true
end
end
end
end
for fruitPart, highlight in pairs(highlightedFruits) do
if not currentFruits[fruitPart] then
if highlight and highlight.Parent then
highlight:Destroy()
end
highlightedFruits[fruitPart] = nil
fruitColorCache[fruitPart] = nil
elseif not fruitPart or not fruitPart.Parent then
if highlight and highlight.Parent then
highlight:Destroy()
end
highlightedFruits[fruitPart] = nil
fruitColorCache[fruitPart] = nil
end
end
end)
end
function stopFruitHighlights()
if FruitHighlightsConnection then
FruitHighlightsConnection:Disconnect()
FruitHighlightsConnection = nil
end
for fruitPart, highlight in pairs(highlightedFruits) do
if highlight and highlight.Parent then
highlight:Destroy()
end
end
highlightedFruits = {}
fruitColorCache = {}
end
function cleanupFruit(fruitPart)
if fruitEspBoxes[fruitPart] then
fruitEspBoxes[fruitPart]:Destroy()
fruitEspBoxes[fruitPart] = nil
end
clearFruit3DBox(fruitPart)
if fruitEspElements[fruitPart] and fruitEspElements[fruitPart].billboardData then
if fruitEspElements[fruitPart].billboardData.billboard then
fruitEspElements[fruitPart].billboardData.billboard:Destroy()
end
fruitEspElements[fruitPart] = nil
end
end
Players.PlayerRemoving:Connect(function(LocalPlayer)
if playerEspBoxes[LocalPlayer] then
playerEspBoxes[LocalPlayer]:Destroy()
playerEspBoxes[LocalPlayer] = nil
end
if activeConnections[LocalPlayer] then
if activeConnections[LocalPlayer].teamChanged then
activeConnections[LocalPlayer].teamChanged:Disconnect()
end
if activeConnections[LocalPlayer].sizeChanged then
activeConnections[LocalPlayer].sizeChanged:Disconnect()
end
if activeConnections[LocalPlayer].charAdded then
activeConnections[LocalPlayer].charAdded:Disconnect()
end
activeConnections[LocalPlayer] = nil
end
if LocalPlayer.Character then
clearPlayer3DBox(LocalPlayer.Character)
end
end)
Workspace.DescendantAdded:Connect(function(descendant)
if fruitEspEnabled then
local fruits = findCollectibleFruits()
for _, fruitData in ipairs(fruits) do
if fruitData.part == descendant and not fruitEspBoxes[descendant] then
onFruitAdded(descendant)
end
end
end
end)
Workspace.DescendantRemoving:Connect(function(descendant)
cleanupFruit(descendant)
if fruitEspElements[descendant] then
if fruitEspElements[descendant].billboardData then
fruitEspElements[descendant].billboardData.billboard:Destroy()
end
fruitEspElements[descendant] = nil
end
end)
Tabs.Esp:Divider()
Tabs.Esp:Section({ Title = "Player ESP", TextSize = 20 })
Tabs.Esp:Divider()
Tabs.Esp:Toggle({
Title = "Player Names",
Flag = "PlayerNames",
Value = PlayerESP.names,
Callback = function(state)
PlayerESP.names = state
managePlayerESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Player Distance",
Flag = "PlayerDistance",
Value = PlayerESP.distance,
Callback = function(state)
PlayerESP.distance = state
managePlayerESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Player Highlights",
Flag = "PlayerHighlights",
Value = PlayerHighlights,
Callback = function(state)
PlayerHighlights = state
if state then
startPlayerHighlights()
else
stopPlayerHighlights()
end
end
})
Tabs.Esp:Toggle({
Title = "Player Boxes",
Flag = "PlayerBoxes",
Value = false,
Callback = function(value)
playerBoxESP(value)
end
})
Tabs.Esp:Dropdown({
Title = "Player Box Type",
Flag = "PlayerBoxType",
Values = {
{Title = "2D Box", Value = "2D"},
{Title = "3D Box", Value = "3D"}
},
Value = "2D",
Callback = function(option)
playerBoxESPtype(option.Value)
end
})
Tabs.Esp:Divider()
Tabs.Esp:Section({ Title = "Fruit ESP", TextSize = 20 })
Tabs.Esp:Divider()
Tabs.Esp:Toggle({
Title = "Fruit Names",
Flag = "FruitNames",
Value = FruitESP.names,
Callback = function(state)
FruitESP.names = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Fruit Distance",
Flag = "FruitDistance",
Value = FruitESP.distance,
Callback = function(state)
FruitESP.distance = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Show Weight",
Flag = "FruitWeight",
Value = FruitESP.weight,
Callback = function(state)
FruitESP.weight = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Show Mutations",
Flag = "FruitMutations",
Value = FruitESP.mutations,
Callback = function(state)
FruitESP.mutations = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Show Value",
Flag = "FruitValue",
Value = FruitESP.value,
Callback = function(state)
FruitESP.value = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Show Variant",
Flag = "FruitVariant",
Value = FruitESP.variant or false,
Callback = function(state)
FruitESP.variant = state
manageFruitESPConnection()
end
})
Tabs.Esp:Toggle({
Title = "Fruit Highlights",
Flag = "FruitHighlights",
Value = FruitHighlights,
Callback = function(state)
FruitHighlights = state
if state then
startFruitHighlights()
else
stopFruitHighlights()
end
end
})
Tabs.Esp:Toggle({
Title = "Fruit Boxes",
Flag = "FruitBoxes",
Value = false,
Callback = function(value)
fruitBoxESP(value)
end
})
Tabs.Esp:Dropdown({
Title = "Fruit Box Type",
Flag = "FruitBoxType",
Values = {
{Title = "2D Box", Value = "2D"},
{Title = "3D Box", Value = "3D"}
},
Value = "2D",
Callback = function(option)
fruitBoxESPtype(option.Value)
end
})
fruitEspFruitDropdown = Tabs.Esp:Dropdown({
Title = "Fruit Whitelist",
Flag = "FruitWhitelist",
Values = {"Click refresh to load fruits"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search fruits...",
Callback = function(selected)
fruitWhitelist = selected
updateFruitWhitelistNormalized()
end
})
Tabs.Esp:Button({
Title = "Refresh Fruits",
Flag = "RefreshFruits",
Callback = function()
crops = GetcropsData()
if #crops > 0 then
fruitEspFruitDropdown:Refresh(crops)
end
end
})
fruitEspMutationDropdown = Tabs.Esp:Dropdown({
Title = "Mutation Whitelist",
Flag = "MutationWhitelist",
Values = {"Click refresh to load mutations"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search mutations...",
Callback = function(selected)
mutationWhitelist = selected
updateFruitWhitelistNormalized()
end
})
Tabs.Esp:Button({
Title = "Refresh Mutations",
Flag = "RefreshMutations",
Callback = function()
mutations = GetmutationsData()
if #mutations > 0 then
fruitEspMutationDropdown:Refresh(mutations)
end
end
})
Tabs.Esp:Toggle({
Title = "Enable Variant Filter",
Flag = "EspVariantFilterToggle",
Value = variantFilterEnabled,
Callback = function(state)
variantFilterEnabled = state
end
})
fruitEspVariantDropdown = Tabs.Esp:Dropdown({
Title = "Variant Whitelist",
Flag = "VariantWhitelist",
Values = {"Click refresh to load variants"},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
SearchPlaceholder = "Search variants...",
Callback = function(selected)
variantWhitelist = selected
updateFruitWhitelistNormalized()
end
})
Tabs.Esp:Button({
Title = "Refresh Variants",
Flag = "RefreshVariants",
Callback = function()
variants = GetvariantData()
if #variants > 0 then
fruitEspVariantDropdown:Refresh(variants)
end
end
})
weightWhitelistToggle = Tabs.Esp:Toggle({
Title = "Enable Weight Filter",
Flag = "EnableWeightFilter",
Value = false,
Callback = function(state)
weightWhitelistEnabled = state
end
})
weightMinInput = Tabs.Esp:Input({
Title = "Minimum Weight",
Flag = "MinWeight",
Desc = "Only show fruits with weight ≥ this value",
Value = "0",
Placeholder = "Enter minimum weight...",
Callback = function(value)
local num = tonumber(value)
if num then
weightMin = num
end
end
})
weightMaxInput = Tabs.Esp:Input({
Title = "Maximum Weight",
Flag = "MaxWeight",
Desc = "Only show fruits with weight ≤ this value",
Value = "100",
Placeholder = "Enter maximum weight...",
Callback = function(value)
local num = tonumber(value)
if num then
weightMax = num
end
end
})
Tabs.Esp:Divider()
valueFilterToggle = Tabs.Esp:Toggle({
Title = "Enable Value Filter",
Flag = "EnableValueFilter",
Value = false,
Callback = function(state)
valueFilterEnabled = state
end
})
valueMinInput = Tabs.Esp:Input({
Title = "Minimum Value",
Flag = "MinValue",
Desc = "Only show fruits with value ≥ this amount",
Value = "0",
Placeholder = "Enter minimum value...",
Callback = function(value)
local num = tonumber(value)
if num then
valueMin = num
end
end
})
valueMaxInput = Tabs.Esp:Input({
Title = "Maximum Value",
Flag = "MaxValue",
Desc = "Only show fruits with value ≤ this amount",
Value = "999999999",
Placeholder = "Enter maximum value...",
Callback = function(value)
local num = tonumber(value)
if num then
valueMax = num
end
end
})
EventLoader = loadstring(game:HttpGet("https://darahub.pages.dev/Module/GrowAGarden/Events/loader.lua"))()
EventLoader(Tabs)
Tabs.Teleport:Section({ Title = "Teleport", TextSize = 20 })
Tabs.Teleport:Divider()
function GetPlayerList()
local playerList = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
local success, content = pcall(function()
return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
local iconUrl = success and content or "user"
table.insert(playerList, {
Title = plr.DisplayName,
Desc = "@" .. plr.Name,
Icon = iconUrl,
UserId = plr.UserId
})
end
end
return playerList
end
TeleportPlayerDropdown = Tabs.Teleport:Dropdown({
Title = "Select Player",
Flag = "TeleportPlayerDropdown",
Values = #GetPlayerList() > 0 and GetPlayerList() or {{Title = "No players found", Desc = "", Icon = "user"}},
Value = "Select a LocalPlayer",
Callback = function(value)
selectedPlayer = value
end
})
function UpdatePlayerList()
local newList = GetPlayerList()
if #newList > 0 then
TeleportPlayerDropdown:Refresh(newList, "Select a LocalPlayer")
else
TeleportPlayerDropdown:Refresh({{Title = "No players found", Desc = "", Icon = "user"}}, "Select a LocalPlayer")
end
end
Tabs.Teleport:Button({
Title = "Teleport to Player",
Desc = "Teleport to the selected LocalPlayer",
Icon = "user",
Callback = function()
if selectedPlayer and selectedPlayer.Title ~= "No players found" then
local targetPlayer = nil
for _, plr in ipairs(Players:GetPlayers()) do
if plr.DisplayName == selectedPlayer.Title or plr.Name == selectedPlayer.Desc:sub(2) then
targetPlayer = plr
break
end
end
if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
end
end
end
end
})
Tabs.Teleport:Button({
Title = "Teleport to Random Player",
Desc = "Teleport to a random LocalPlayer in the server",
Icon = "users",
Callback = function()
local otherPlayers = {}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
table.insert(otherPlayers, plr)
end
end
if #otherPlayers > 0 then
local randomPlayer = otherPlayers[math.random(1, #otherPlayers)]
if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame
end
end
end
})
Players.PlayerAdded:Connect(function()
UpdatePlayerList()
end)
Players.PlayerRemoving:Connect(function()
UpdatePlayerList()
end)
LocalPlayer.CharacterAdded:Connect(function(newCharacter)
Character = newCharacter
rootPart = Character:WaitForChild("HumanoidRootPart", 5)
end)
local Troll = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Troll-Stuffs.lua"))()
Troll(Tabs)
Tabs.Misc:Section({ Title = "Misc", TextSize = 40 })
Tabs.Misc:Divider()
AntiAFKConnection = nil
startAntiAFK = function()
AntiAFKConnection = LocalPlayer.Idled:Connect(function()
VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
end
stopAntiAFK = function()
if AntiAFKConnection then
AntiAFKConnection:Disconnect()
AntiAFKConnection = nil
end
end
AntiAFKToggle = Tabs.Misc:Toggle({
Title = "Anti AFK",
Flag = "AntiAFKToggle",
Value = AntiAFK,
Callback = function(state)
if state then
startAntiAFK()
else
stopAntiAFK()
end
end
})
Tabs.Misc:Space()
Tabs.Misc:Section({Title = "Auto Sell", TextSize = 20})
local autoSellEnabled = false
local autoSellThread = nil
local autoSellMode = "Current Position"
local sellDelay = 0.5
local sellWhenFullEnabled = false
local savedPosition = nil
local SellItemEvent = ReplicatedStorage.GameEvents:FindFirstChild("Sell_Item") or ReplicatedStorage.GameEvents:FindFirstChild("SellItem")
local SellInventoryEvent = ReplicatedStorage.GameEvents:FindFirstChild("Sell_Inventory") or ReplicatedStorage.GameEvents:FindFirstChild("SellInventory")
function getMyFarm()
local myUsername = LocalPlayer.Name
local farmFolder = Workspace:FindFirstChild("Farm")
if not farmFolder then return nil end
for _, plot in pairs(farmFolder:GetChildren()) do
local sign = plot:FindFirstChild("Sign")
if sign then
local owner = sign:GetAttribute("_owner")
if owner and owner == myUsername then
return plot
end
end
end
return nil
end
function teleportToPosition(position)
if not Character then return false end
local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return false end
humanoidRootPart.CFrame = CFrame.new(position)
task.wait(0.1)
return true
end
function getCurrentPosition()
if not Character then return nil end
local humanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
if not humanoidRootPart then return nil end
return humanoidRootPart.Position
end
function saveCurrentPosition()
savedPosition = getCurrentPosition()
return savedPosition ~= nil
end
function teleportToSellNPC()
for _, connection in pairs(getconnections(game:GetService("Players").LocalPlayer.PlayerGui.Teleport_UI.Frame.Sell.Activated)) do
connection:Fire()
end
end
function teleportToFarmCenter()
local myFarm = getMyFarm()
if not myFarm then return false end
local centerPoint = myFarm:FindFirstChild("Center_Point")
if centerPoint then
return teleportToPosition(centerPoint.Position + Vector3.new(0, 2, 0))
end
local boundingBox = myFarm:GetBoundingBox()
local center = (boundingBox[1] + boundingBox[2]) / 2
return teleportToPosition(Vector3.new(center.X, center.Y + 5, center.Z))
end
function sellHandItem()
if not SellItemEvent then return false end
local success = pcall(function()
SellItemEvent:FireServer()
end)
return success
end
function sellInventory()
if not SellInventoryEvent then return false end
local success = pcall(function()
SellInventoryEvent:FireServer()
end)
return success
end
function getBackpackCount()
local count = 0
if Character then
for _, item in pairs(Character:GetChildren()) do
if item:IsA("Tool") then
count = count + 1
end
end
end
if Backpack then
for _, item in pairs(Backpack:GetChildren()) do
if item:IsA("Tool") then
count = count + 1
end
end
end
return count
end
function isBackpackFull()
return getBackpackCount() >= maxBackpackCapacity
end
function startAutoSell()
if autoSellThread then
task.cancel(autoSellThread)
autoSellThread = nil
end
autoSellThread = task.spawn(function()
while autoSellEnabled do
local shouldSell = false
if sellWhenFullEnabled then
shouldSell = isBackpackFull()
else
shouldSell = true
end
if shouldSell then
if autoSellMode == "Current Position" then
saveCurrentPosition()
end
teleportToSellNPC()
task.wait(sellDelay)
sellInventory()
task.wait(sellDelay)
if autoSellMode == "Current Position" and savedPosition then
teleportToPosition(savedPosition)
savedPosition = nil
else
teleportToFarmCenter()
end
end
task.wait(sellDelay)
end
end)
end
function stopAutoSell()
if autoSellThread then
task.cancel(autoSellThread)
autoSellThread = nil
end
savedPosition = nil
end
Tabs.Misc:Divider()
Tabs.Misc:Dropdown({
Title = "Sell Mode",
Desc = "Choose how to return after selling",
Values = {
{Title = "Current Position", Icon = "map-pin", Value = "Current Position"},
{Title = "Center", Icon = "target", Value = "Center"}
},
Value = {Title = "Current Position", Icon = "map-pin", Value = "Current Position"},
Callback = function(option)
autoSellMode = option.Value
end
})
Tabs.Misc:Input({
Title = "Sell Delay (seconds)",
Desc = "Delay between actions",
Flag = "SellDelayInput",
Placeholder = "0.5",
Value = tostring(sellDelay),
Callback = function(value)
local num = tonumber(value)
if num and num > 0 then
sellDelay = num
end
end
})
Tabs.Misc:Toggle({
Title = "Auto Sell When Full",
Desc = "Only sell when Backpack reaches capacity",
Flag = "SellWhenFullToggle",
Value = sellWhenFullEnabled,
Callback = function(state)
sellWhenFullEnabled = state
end
})
Tabs.Misc:Toggle({
Title = "Auto Sell",
Desc = "Automatically sell items based on mode",
Flag = "AutoSellToggle",
Value = autoSellEnabled,
Callback = function(state)
autoSellEnabled = state
if autoSellEnabled then
startAutoSell()
else
stopAutoSell()
end
end
})
Tabs.Misc:Space()
Tabs.Misc:Section({Title = "Manual Sell", TextSize = 15})
Tabs.Misc:Divider()
Tabs.Misc:Button({
Title = "Sell Inventory",
Desc = "Sell entire inventory and return to current position",
Icon = "package",
Callback = function()
local pos = getCurrentPosition()
if not pos then 
WindUI:Notify({
Title = "Error",
Content = "Could not get current position",
Duration = 2
})
return 
end
teleportToSellNPC()
task.wait(sellDelay)
sellInventory()
task.wait(sellDelay)
teleportToPosition(pos)
end
})
Tabs.Misc:Button({
Title = "Sell Hand Item",
Desc = "Sell current held item and return to current position",
Icon = "hand",
Callback = function()
local pos = getCurrentPosition()
if not pos then 
WindUI:Notify({
Title = "Error",
Content = "Could not get current position",
Duration = 2
})
return 
end
teleportToSellNPC()
task.wait(sellDelay)
sellHandItem()
task.wait(sellDelay)
teleportToPosition(pos)
end
})
Tabs.Misc:Section({ Title = "Water Tree", TextSize = 20 })
WaterTree_Enabled = false
WaterTree_Task = nil
WaterTree_Distance = 20
WaterTree_Speed = 0.1
WaterTree_DistanceSlider = Tabs.Misc:Slider({
Title = "Water Distance",
Step = 1,
Value = { Min = 1, Max = 100, Default = 20 },
Callback = function(value)
WaterTree_Distance = value
end
})
WaterTree_SpeedSlider = Tabs.Misc:Slider({
Title = "Water Speed",
Step = 0.01,
Value = { Min = 0.01, Max = 2, Default = 0.1 },
Callback = function(value)
WaterTree_Speed = value
end
})
function WaterTree_GetMyFarmPlots()
WaterTree_MyUsername = Players.LocalPlayer.Name
WaterTree_FarmFolder = workspace:FindFirstChild("Farm")
WaterTree_MyPlots = {}
if WaterTree_FarmFolder then
for _, WaterTree_Plot in pairs(WaterTree_FarmFolder:GetChildren()) do
WaterTree_Sign = WaterTree_Plot:FindFirstChild("Sign")
if WaterTree_Sign then
WaterTree_Owner = WaterTree_Sign:GetAttribute("_owner")
if WaterTree_Owner and WaterTree_Owner == WaterTree_MyUsername then
table.insert(WaterTree_MyPlots, WaterTree_Plot)
end
end
end
end
return WaterTree_MyPlots
end
function WaterTree_WaterTrees()
WaterTree_MyPlots = WaterTree_GetMyFarmPlots()
WaterTree_WaterEvent = ReplicatedStorage.GameEvents.Water_RE
WaterTree_Character = Players.LocalPlayer.Character
if not WaterTree_Character then return end
WaterTree_RootPart = WaterTree_Character:FindFirstChild("HumanoidRootPart")
if not WaterTree_RootPart then return end
WaterTree_PlayerPos = WaterTree_RootPart.Position
for _, WaterTree_Plot in pairs(WaterTree_MyPlots) do
WaterTree_Important = WaterTree_Plot:FindFirstChild("Important")
if WaterTree_Important then
WaterTree_PlantsPhysical = WaterTree_Important:FindFirstChild("Plants_Physical")
if WaterTree_PlantsPhysical then
for _, WaterTree_Plant in pairs(WaterTree_PlantsPhysical:GetChildren()) do
if WaterTree_Plant:IsA("Model") and WaterTree_Plant:FindFirstChild("Grow") then
WaterTree_PlantPos = WaterTree_Plant:GetPivot().Position
WaterTree_Dist = (WaterTree_PlayerPos - WaterTree_PlantPos).Magnitude
if WaterTree_Dist <= WaterTree_Distance then
pcall(function()
WaterTree_WaterEvent:FireServer(WaterTree_PlantPos)
end)
end
end
end
end
end
end
end
function WaterTree_Start()
WaterTree_Task = task.spawn(function()
while WaterTree_Enabled do
WaterTree_WaterTrees()
task.wait(WaterTree_Speed)
for WaterTree_i = 1, 5 do
if not WaterTree_Enabled then break end
WaterTree_WaterTrees()
end
task.wait(0.05)
end
end)
end
function WaterTree_Stop()
if WaterTree_Task then
task.cancel(WaterTree_Task)
WaterTree_Task = nil
end
end
WaterTree_Toggle = Tabs.Misc:Toggle({
Title = "Auto Water",
Value = false,
Callback = function(state)
WaterTree_Enabled = state
if state then
WaterTree_Start()
else
WaterTree_Stop()
end
end
})
local originalGravity = workspace.Gravity
local isCustomGravity = false
local customGravityValue = originalGravity
GravityToggle = Tabs.Utility:Toggle({
Title = "Custom Gravity",
Flag = "GravityToggle",
Value = isCustomGravity,
Callback = function(state)
isCustomGravity = state
workspace.Gravity = state and customGravityValue or originalGravity
end
})
GravityInput = Tabs.Utility:Input({
Title = "Gravity Value",
Flag = "GravityInput",
Placeholder = tostring(originalGravity),
Value = tostring(customGravityValue),
Callback = function(text)
local num = tonumber(text)
if num then
customGravityValue = num
if isCustomGravity then
workspace.Gravity = num
end
end
end
})
TimeChangerInput = Tabs.Utility:Input({
Title = "Set Time (HH:MM)",
Flag = "TimeChangerInput",
Placeholder = "12:00",
Callback = function(value)
value = value:gsub("^%s*(.-)%s*$", "%1")
local h_str, m_str = value:match("(%d+):(%d+)")
if h_str and m_str then
local h = tonumber(h_str)
local m = tonumber(m_str)
if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
local totalHours = h + (m / 60)
Lighting.ClockTime = totalHours
end
end
end
})
NoRender = false
NoRenderColor = Color3.fromRGB(0, 0, 0)
NoRenderToggle = Tabs.Utility:Toggle({
Title = "No Render",
Flag = "NoRenderToggle",
Desc = "Disable 3D rendering for performance",
Value = false,
Callback = function(state)
NoRender = state
RunService:Set3dRenderingEnabled(not state)
if state then
local gui = Instance.new("ScreenGui")
gui.Name = "NoRenderBackground"
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = NoRenderColor
frame.BorderSizePixel = 0
frame.Parent = gui
gui.Parent = LocalPlayer.PlayerGui
else
local gui = LocalPlayer.PlayerGui:FindFirstChild("NoRenderBackground")
if gui then
gui:Destroy()
end
end
end
})
NoRenderColorPicker = Tabs.Utility:Colorpicker({
Title = "No Render Color",
Flag = "NoRenderColorPicker",
Desc = "Choose background color when No Render is enabled",
Default = Color3.fromRGB(0, 0, 0),
Transparency = 0,
Callback = function(color)
NoRenderColor = color
if NoRender then
local gui = LocalPlayer.PlayerGui:FindFirstChild("NoRenderBackground")
if gui then
local frame = gui:FindFirstChildOfClass("Frame")
if frame then
frame.BackgroundColor3 = color
end
end
end
end
})
RemoveTextures = false
RemoveTexturesButton = Tabs.Utility:Button({
Title = "Remove Textures",
Callback = function()
for _, part in ipairs(workspace:GetDescendants()) do
if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
if part:IsA("Part") then
part.Material = Enum.Material.SmoothPlastic
end
if part:FindFirstChildWhichIsA("Texture") then
local texture = part:FindFirstChildWhichIsA("Texture")
texture.Texture = "rbxassetid://0"
end
if part:FindFirstChildWhichIsA("Decal") then
local decal = part:FindFirstChildWhichIsA("Decal")
decal.Texture = "rbxassetid://0"
end
end
end
end
})
Players.PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == LocalPlayer then
RunService:Set3dRenderingEnabled(true)
end
end)
LowQualityButton = Tabs.Utility:Button({
Title = "Low Quality",
Desc = "Disable textures, effects, and optimize graphics",
Callback = function()
local ToDisable = {
Textures = true,
VisualEffects = true,
Parts = true,
Particles = true,
Sky = true
}
local ToEnable = {
FullBright = false
}
local Stuff = {}
for _, v in next, game:GetDescendants() do
if ToDisable.Parts then
if v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("BasePart") then
v.Material = Enum.Material.SmoothPlastic
table.insert(Stuff, 1, v)
end
end
if ToDisable.Particles then
if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Explosion") or v:IsA("Sparkles") or v:IsA("Fire") then
v.Enabled = false
table.insert(Stuff, 1, v)
end
end
if ToDisable.VisualEffects then
if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
v.Enabled = false
table.insert(Stuff, 1, v)
end
end
if ToDisable.Textures then
if v:IsA("Decal") or v:IsA("Texture") then
v.Texture = ""
table.insert(Stuff, 1, v)
end
end
if ToDisable.Sky then
if v:IsA("Sky") then
v.Parent = nil
table.insert(Stuff, 1, v)
end
end
end
if ToEnable.FullBright then
Lighting.FogColor = Color3.fromRGB(255, 255, 255)
Lighting.FogEnd = math.huge
Lighting.FogStart = math.huge
Lighting.Ambient = Color3.fromRGB(255, 255, 255)
Lighting.Brightness = 5
Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
Lighting.Outlines = true
end
end
})
if _G.a then
local v1, v2, v3 = pairs(_G.a)
while true do
local v4
v3, v4 = v1(v2, v3)
if v3 == nil then
break
end
v4:Disconnect()
end
_G.a = nil
end
repeat
task.wait()
until game.Players.LocalPlayer
vu5 = game.Players.LocalPlayer
vu6 = nil
vu7 = nil
vu8 = nil
vu9 = false
vu10 = {}
function vu16()
vu6 = vu5.Character or vu5.CharacterAdded:Wait()
vu7 = vu6:WaitForChild("Humanoid")
vu8 = vu6:WaitForChild("HumanoidRootPart")
vu10 = {}
v11 = vu6
v12, v13, v14 = pairs(v11:GetDescendants())
while true do
v15 = nil
v14, v15 = v12(v13, v14)
if v14 == nil then
break
end
if v15:IsA("BasePart") and v15.Transparency == 0 then
vu10[#vu10 + 1] = v15
end
end
end
function vu30()
toggleElement = ButtonLib.Create:Toggle({
Text = "INVISIBLE",
Flag = "InvisibleToggle",
Default = false,
Visible = false,
Callback = function(state)
vu9 = state
if vu9 then
v26, v27, v28 = pairs(vu10)
while true do
v29 = nil
v28, v29 = v26(v27, v28)
if v28 == nil then
break
end
v29.Transparency = v29.Transparency == 0 and 0.5 or 0
end
else
v26, v27, v28 = pairs(vu10)
while true do
v29 = nil
v28, v29 = v26(v27, v28)
if v28 == nil then
break
end
v29.Transparency = 0
end
end
end
})
toggleElement.Position = UDim2.new(0.5, -125, 0.12, 0)
_G.InvisibleToggleElement = toggleElement
end
vu16()
vu30()
v31 = {
nil,
nil
}
v32 = vu5
v31[1] = vu5:GetMouse().KeyDown:Connect(function(p33)
if p33 == "i" then
vu9 = not vu9
if ButtonLib and ButtonLib.InvisibleToggle then
ButtonLib.InvisibleToggle:Set(vu9)
end
v34, v35, v36 = pairs(vu10)
while true do
v37 = nil
v36, v37 = v34(v35, v36)
if v36 == nil then
break
end
if vu9 then
v37.Transparency = v37.Transparency == 0 and 0.5 or 0
else
v37.Transparency = 0
end
end
end
end)
v31[2] = RunService.Heartbeat:Connect(function()
if vu9 then
v38 = vu8.CFrame
v39 = vu7.CameraOffset
v40 = v38 * CFrame.new(0, -200000, 0)
v41 = vu7
v42 = vu8
v43 = v40:ToObjectSpace(CFrame.new(v38.Position)).Position
v42.CFrame = v40
v41.CameraOffset = v43
RunService.RenderStepped:Wait()
v44 = vu7
vu8.CFrame = v38
v44.CameraOffset = v39
end
end)
vu5.CharacterAdded:Connect(function()
vu9 = false
if ButtonLib and ButtonLib.InvisibleToggle then
ButtonLib.InvisibleToggle:Set(false)
end
vu16()
end)
InvisibleGuiToggle = Tabs.Utility:Toggle({
Title = "Invisible GUI",
Flag = "InvisibleGuiToggle",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.InvisibleToggle then
ButtonLib.InvisibleToggle:SetVisible(state)
end
end
})
Tabs.Utility:Space()
Tabs.Utility:Button({
Title = "Insta Proximity Prompt",
Callback = function()
RblxCallDialog({
Title = "Warning",
Desc = [[ Using this you may accidentally click gift someone and you may lose your fruit or pet. So be careful when pressing something.
Are you sure wanted to run this?] ],
Button1 = {
Title = "Cancel",
Type = "GreyOutline",
},
Button2 = {
Title = "Execute Anyway",
Type = "White",
WaitTimeClick = 5,
Callback = function()
for _,b in ipairs(game:GetDescendants()) do if b:IsA("ProximityPrompt") then b.HoldDuration=0 end end game.DescendantAdded:Connect(function(c) if c:IsA("ProximityPrompt") then c.HoldDuration=0 end end)
end
}
})
end
})
local DataService = require(ReplicatedStorage.Modules.DataService)
local function getPlayerCurrencyValue(currencyType)
if not currencyType or currencyType == "" then
return DataService:GetData().Sheckles or 0
end
local PlayerGui = Players.LocalPlayer.PlayerGui
local cleanCurrencyType = currencyType:gsub("s$", "")
local possibleNames = {
currencyType,
cleanCurrencyType,
currencyType .. "Currency_UI",
cleanCurrencyType .. "Currency_UI",
currencyType:lower(),
cleanCurrencyType:lower(),
currencyType:upper(),
cleanCurrencyType:upper(),
currencyType:gsub("^%l", string.upper),
cleanCurrencyType:gsub("^%l", string.upper)
}
for _, name in ipairs(possibleNames) do
local currencyGui = PlayerGui:FindFirstChild(name)
if currencyGui then
local frame = currencyGui:FindFirstChild("Frame")
if frame then
local textLabel1 = frame:FindFirstChild("TextLabel1")
if textLabel1 then
local valObject = textLabel1:FindFirstChild("val")
if valObject and typeof(valObject.Value) == "number" then
return valObject.Value
end
end
end
end
end
for _, name in ipairs(possibleNames) do
local currencyGui = PlayerGui:FindFirstChild(name .. "_UI")
if currencyGui then
local frame = currencyGui:FindFirstChild("Frame")
if frame then
local textLabel1 = frame:FindFirstChild("TextLabel1")
if textLabel1 then
local valObject = textLabel1:FindFirstChild("val")
if valObject and typeof(valObject.Value) == "number" then
return valObject.Value
end
end
end
end
end
return 0
end
local function hasEnoughMoneyForItem(itemData)
local price = itemData.Price or 0
if itemData.SpecialCurrencyType and itemData.SpecialCurrencyType ~= "" then
local currencyAmount = getPlayerCurrencyValue(itemData.SpecialCurrencyType)
return currencyAmount >= price
else
local sheckles = DataService:GetData().Sheckles or 0
return sheckles >= price
end
end
Tabs.Shop:Section({ Title = "Auto Buy", TextSize = 40 })
Tabs.Shop:Section({ Title = "Seed Shop", TextSize = 20 })
Tabs.Shop:Divider()
local seedShopDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("SeedShopData")
local seedDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("SeedData")
local BuySeedStock = ReplicatedStorage.GameEvents.BuySeedStock
local autoBuyEnabled = false
local autoBuyTask = nil
local selectedSeeds = {}
local autoBuyAllEnabled = false
local autoBuyAllTask = nil
seedDropdown = Tabs.Shop:Dropdown({
Title = "Select Auto Seed",
Desc = "Choose seeds to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options) 
selectedSeeds = {}
for _, option in ipairs(options) do
if option.Data and option.Data.Name then table.insert(selectedSeeds, option.Data) end
end
end
})
Tabs.Shop:Button({
Title = "Refresh Seed Items",
Icon = "refresh-cw",
Callback = function()
task.spawn(function()
local success, seedShopData = pcall(require, seedShopDataModule)
local success2, seedData = pcall(require, seedDataModule)
if success and success2 then
local dropdownItems = {}
for seedName, shopInfo in pairs(seedShopData) do
local seedInfo = seedData[seedName]
if seedInfo and shopInfo.DisplayInShop ~= false then
table.insert(dropdownItems, {
Title = seedInfo.SeedName or seedName,
Icon = seedInfo.FruitIcon or seedInfo.Asset or "",
Desc = string.format("$%s | %s", shopInfo.Price or 0, seedInfo.SeedRarity or "Unknown"),
Value = seedName,
Data = {Name = seedName, DisplayName = seedInfo.SeedName or seedName, Price = shopInfo.Price or 0, Rarity = seedInfo.SeedRarity or "Unknown", SpecialCurrencyType = shopInfo.SpecialCurrencyType}
})
end
end
table.sort(dropdownItems, function(a, b) return a.Data.Price < b.Data.Price end)
seedDropdown:Refresh(dropdownItems, {})
else
seedDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle", Desc = "Seed data modules not found"}})
end
end)
end
})
autoBuyToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Seed",
Value = false,
Callback = function(state)
autoBuyEnabled = state
if state then
autoBuyTask = task.spawn(function()
while autoBuyEnabled do
if #selectedSeeds > 0 then
for _, seedData in ipairs(selectedSeeds) do
if hasEnoughMoneyForItem(seedData) then
BuySeedStock:FireServer("Shop", seedData.Name)
end
task.wait(0.01)
end
for i = 1, 5 do
if not autoBuyEnabled then break end
for _, seedData in ipairs(selectedSeeds) do
if hasEnoughMoneyForItem(seedData) then
BuySeedStock:FireServer("Shop", seedData.Name)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if autoBuyTask then task.cancel(autoBuyTask) autoBuyTask = nil end
end
end
})
autoBuyAllToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Seed",
Value = false,
Callback = function(state)
autoBuyAllEnabled = state
if state then
autoBuyAllTask = task.spawn(function()
while autoBuyAllEnabled do
local success, seedShopData = pcall(require, seedShopDataModule)
if success then
for seedName, shopInfo in pairs(seedShopData) do
if shopInfo.DisplayInShop ~= false then
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuySeedStock:FireServer("Shop", seedName)
end
end
task.wait(0.01)
end
for i = 1, 10 do
if not autoBuyAllEnabled then break end
for seedName, shopInfo in pairs(seedShopData) do
if shopInfo.DisplayInShop ~= false then
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuySeedStock:FireServer("Shop", seedName)
end
end
end
task.wait(0.03)
end
else
task.wait(0.5)
end
task.wait(0.2)
end
end)
else
if autoBuyAllTask then task.cancel(autoBuyAllTask) autoBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Daily Seed Shop", TextSize = 20 })
Tabs.Shop:Divider()
local dailySeedShopDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("DailySeedShopData")
local BuyDailySeedShopStock = ReplicatedStorage.GameEvents.BuyDailySeedShopStock
local dailyAutoBuyEnabled = false
local dailyAutoBuyTask = nil
local dailySelectedSeeds = {}
local dailyBuyAllEnabled = false
local dailyBuyAllTask = nil
function loadDailySeedData()
local success, dailyData = pcall(require, dailySeedShopDataModule)
local success2, seedData = pcall(require, seedDataModule)
if success and success2 then return dailyData, seedData end
return nil, nil
end
function getDailySeeds()
local dailyData, seedData = loadDailySeedData()
if not dailyData or not seedData then return {} end
local dailySeeds = {}
for seedName, shopInfo in pairs(dailyData) do
local seedInfo = seedData[seedName]
if seedInfo then
local currencyDisplay = ""
if shopInfo.SpecialCurrencyType and shopInfo.SpecialCurrencyType ~= "" then
currencyDisplay = string.format("%s %s", shopInfo.Price or 0, shopInfo.SpecialCurrencyType)
else
currencyDisplay = string.format("$%s", shopInfo.Price or 0)
end
table.insert(dailySeeds, {
Title = seedInfo.SeedName or seedName,
Icon = seedInfo.FruitIcon or seedInfo.Asset or "",
Desc = string.format("%s | Stock: %d", currencyDisplay, shopInfo.MaxStock or 1),
Value = seedName,
Data = {Name = seedName, DisplayName = seedInfo.SeedName or seedName, Price = shopInfo.Price or 0, MaxStock = shopInfo.MaxStock or 1, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
})
end
end
table.sort(dailySeeds, function(a, b) return a.Data.Price < b.Data.Price end)
return dailySeeds
end
dailySeedDropdown = Tabs.Shop:Dropdown({
Title = "Select Daily Seed",
Desc = "Choose daily seeds to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options) 
dailySelectedSeeds = {}
for _, option in ipairs(options) do if option.Data and option.Data.Name then table.insert(dailySelectedSeeds, option.Data) end end
end
})
Tabs.Shop:Button({
Title = "Refresh Daily Seed Items",
Icon = "refresh-cw",
Callback = function()
local dailySeeds = getDailySeeds()
if #dailySeeds > 0 then 
dailySeedDropdown:Refresh(dailySeeds, {}) 
else 
dailySeedDropdown:Refresh({{Title = "No Daily Seeds", Icon = "x-circle", Desc = "Daily shop data not found"}}) 
end
end
})
autoBuyDailyToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Daily Seed",
Value = false,
Callback = function(state)
dailyAutoBuyEnabled = state
if state then
dailyAutoBuyTask = task.spawn(function()
while dailyAutoBuyEnabled do
if #dailySelectedSeeds > 0 then
for _, seedData in ipairs(dailySelectedSeeds) do
if hasEnoughMoneyForItem(seedData) then
BuyDailySeedShopStock:FireServer(seedData.Name)
end
task.wait(0.01)
end
for i = 1, 5 do
if not dailyAutoBuyEnabled then break end
for _, seedData in ipairs(dailySelectedSeeds) do
if hasEnoughMoneyForItem(seedData) then
BuyDailySeedShopStock:FireServer(seedData.Name)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if dailyAutoBuyTask then task.cancel(dailyAutoBuyTask) dailyAutoBuyTask = nil end
end
end
})
autoBuyAllDailyToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Daily Seed",
Value = false,
Callback = function(state)
dailyBuyAllEnabled = state
if state then
dailyBuyAllTask = task.spawn(function()
while dailyBuyAllEnabled do
local dailyData, _ = loadDailySeedData()
if dailyData then
for seedName, shopInfo in pairs(dailyData) do
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyDailySeedShopStock:FireServer(seedName)
end
task.wait(0.01)
end
for i = 1, 8 do
if not dailyBuyAllEnabled then break end
for seedName, shopInfo in pairs(dailyData) do
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyDailySeedShopStock:FireServer(seedName)
end
end
task.wait(0.04)
end
else
task.wait(0.5)
end
task.wait(0.15)
end
end)
else
if dailyBuyAllTask then task.cancel(dailyBuyAllTask) dailyBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Pet Egg Autobuy", TextSize = 20 })
Tabs.Shop:Divider()
local petEggDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetEggData")
local petEggsModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"):WaitForChild("PetEggs")
local BuyPetEgg = ReplicatedStorage.GameEvents.BuyPetEgg
local eggAutoBuyEnabled = false
local eggAutoBuyTask = nil
local selectedEggs = {}
local eggAutoBuyAllEnabled = false
local eggAutoBuyAllTask = nil
function loadEggData()
local success, eggData = pcall(require, petEggDataModule)
local success2, eggsInfo = pcall(require, petEggsModule)
if success and success2 then return eggData, eggsInfo end
return nil, nil
end
eggDropdown = Tabs.Shop:Dropdown({
Title = "Select Egg",
Desc = "Choose eggs to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options) 
selectedEggs = {}
for _, option in ipairs(options) do if option.Data and option.Data.Name then table.insert(selectedEggs, option.Data) end end
end
})
Tabs.Shop:Button({
Title = "Refresh Egg Items",
Icon = "refresh-cw",
Callback = function()
task.spawn(function()
local eggData, eggsInfo = loadEggData()
if eggData and eggsInfo then
local dropdownItems = {}
for eggName, eggInfo in pairs(eggData) do
local eggDetails = eggsInfo[eggName]
if eggDetails then
table.insert(dropdownItems, {
Title = eggInfo.EggName or eggName,
Icon = eggDetails.Icon or "",
Desc = string.format("$%s | %s", eggInfo.Price or 0, eggInfo.EggRarity or "Unknown"),
Value = eggName,
Data = {Name = eggName, DisplayName = eggInfo.EggName or eggName, Price = eggInfo.Price or 0, Rarity = eggInfo.EggRarity or "Unknown", SpecialCurrencyType = eggInfo.SpecialCurrencyType}
})
end
end
table.sort(dropdownItems, function(a, b) return a.Data.Price < b.Data.Price end)
eggDropdown:Refresh(dropdownItems, {})
else
eggDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle", Desc = "Egg data modules not found"}})
end
end)
end
})
autoBuyEggToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Egg",
Value = false,
Callback = function(state)
eggAutoBuyEnabled = state
if state then
eggAutoBuyTask = task.spawn(function()
while eggAutoBuyEnabled do
if #selectedEggs > 0 then
for _, eggData in ipairs(selectedEggs) do
if hasEnoughMoneyForItem(eggData) then
BuyPetEgg:FireServer(eggData.Name)
end
task.wait(0.01)
end
for i = 1, 5 do
if not eggAutoBuyEnabled then break end
for _, eggData in ipairs(selectedEggs) do
if hasEnoughMoneyForItem(eggData) then
BuyPetEgg:FireServer(eggData.Name)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if eggAutoBuyTask then task.cancel(eggAutoBuyTask) eggAutoBuyTask = nil end
end
end
})
autoBuyAllEggToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Egg",
Value = false,
Callback = function(state)
eggAutoBuyAllEnabled = state
if state then
eggAutoBuyAllTask = task.spawn(function()
while eggAutoBuyAllEnabled do
local eggData, _ = loadEggData()
if eggData then
for eggName, eggInfo in pairs(eggData) do
local itemData = {Price = eggInfo.Price or 0, SpecialCurrencyType = eggInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyPetEgg:FireServer(eggName)
end
task.wait(0.01)
end
for i = 1, 8 do
if not eggAutoBuyAllEnabled then break end
for eggName, eggInfo in pairs(eggData) do
local itemData = {Price = eggInfo.Price or 0, SpecialCurrencyType = eggInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyPetEgg:FireServer(eggName)
end
end
task.wait(0.04)
end
else
task.wait(0.5)
end
task.wait(0.15)
end
end)
else
if eggAutoBuyAllTask then task.cancel(eggAutoBuyAllTask) eggAutoBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Gear Shop Autobuy", TextSize = 20 })
Tabs.Shop:Divider()
local gearShopDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("GearShopData")
local gearDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("GearData")
local BuyGearStock = ReplicatedStorage.GameEvents.BuyGearStock
local gearAutoBuyEnabled = false
local gearAutoBuyTask = nil
local selectedGears = {}
local gearAutoBuyAllEnabled = false
local gearAutoBuyAllTask = nil
function loadGearData()
local success, gearShopData = pcall(require, gearShopDataModule)
local success2, gearInfo = pcall(require, gearDataModule)
if success and success2 then return gearShopData, gearInfo end
return nil, nil
end
gearDropdown = Tabs.Shop:Dropdown({
Title = "Select Gear",
Desc = "Choose gear to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options) 
selectedGears = {}
for _, option in ipairs(options) do if option.Data and option.Data.Name then table.insert(selectedGears, option.Data) end end
end
})
Tabs.Shop:Button({
Title = "Refresh Gear Items",
Icon = "refresh-cw",
Callback = function()
task.spawn(function()
local gearShopData, gearInfo = loadGearData()
if gearShopData and gearInfo and gearShopData.Gear then
local dropdownItems = {}
for gearName, shopInfo in pairs(gearShopData.Gear) do
local gearDetails = gearInfo[gearName]
if gearDetails and shopInfo.DisplayInShop ~= false then
table.insert(dropdownItems, {
Title = gearDetails.GearName or gearName,
Icon = gearDetails.Asset or "",
Desc = string.format("$%s | %s", shopInfo.Price or 0, gearDetails.GearRarity or "Unknown"),
Value = gearName,
Data = {Name = gearName, DisplayName = gearDetails.GearName or gearName, Price = shopInfo.Price or 0, Rarity = gearDetails.GearRarity or "Unknown", SpecialCurrencyType = shopInfo.SpecialCurrencyType}
})
end
end
table.sort(dropdownItems, function(a, b) return a.Data.Price < b.Data.Price end)
gearDropdown:Refresh(dropdownItems, {})
else
gearDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle", Desc = "Gear data modules not found"}})
end
end)
end
})
autoBuyGearToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Gear",
Value = false,
Callback = function(state)
gearAutoBuyEnabled = state
if state then
gearAutoBuyTask = task.spawn(function()
while gearAutoBuyEnabled do
if #selectedGears > 0 then
for _, gearData in ipairs(selectedGears) do
if hasEnoughMoneyForItem(gearData) then
BuyGearStock:FireServer(gearData.Name)
end
task.wait(0.01)
end
for i = 1, 5 do
if not gearAutoBuyEnabled then break end
for _, gearData in ipairs(selectedGears) do
if hasEnoughMoneyForItem(gearData) then
BuyGearStock:FireServer(gearData.Name)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if gearAutoBuyTask then task.cancel(gearAutoBuyTask) gearAutoBuyTask = nil end
end
end
})
autoBuyAllGearToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Gear",
Value = false,
Callback = function(state)
gearAutoBuyAllEnabled = state
if state then
gearAutoBuyAllTask = task.spawn(function()
while gearAutoBuyAllEnabled do
local gearShopData, _ = loadGearData()
if gearShopData and gearShopData.Gear then
for gearName, shopInfo in pairs(gearShopData.Gear) do
if shopInfo.DisplayInShop ~= false then
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyGearStock:FireServer(gearName)
end
end
task.wait(0.01)
end
for i = 1, 8 do
if not gearAutoBuyAllEnabled then break end
for gearName, shopInfo in pairs(gearShopData.Gear) do
if shopInfo.DisplayInShop ~= false then
local itemData = {Price = shopInfo.Price or 0, SpecialCurrencyType = shopInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyGearStock:FireServer(gearName)
end
end
end
task.wait(0.04)
end
else
task.wait(0.5)
end
task.wait(0.15)
end
end)
else
if gearAutoBuyAllTask then task.cancel(gearAutoBuyAllTask) gearAutoBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Cosmetic Autobuy", TextSize = 20 })
Tabs.Shop:Divider()
local crateShopModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticCrateShopData")
local itemShopModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticItemShopData")
local cosmeticRegistryModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticRegistry"):WaitForChild("CosmeticList")
local cosmeticCratesModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticCrateRegistry"):WaitForChild("CosmeticCrates")
local BuyCosmeticCrate = ReplicatedStorage.GameEvents.BuyCosmeticCrate
local BuyCosmeticItem = ReplicatedStorage.GameEvents.BuyCosmeticItem
local BuyCosmeticShopFence = ReplicatedStorage.GameEvents.BuyCosmeticShopFence
local cosmeticAutoBuyEnabled = false
local cosmeticAutoBuyTask = nil
local selectedCosmetics = {}
local cosmeticAutoBuyAllEnabled = false
local cosmeticAutoBuyAllTask = nil
function loadCosmeticData()
local success, crateData = pcall(require, crateShopModule)
local success2, itemData = pcall(require, itemShopModule)
local success3, registryData = pcall(require, cosmeticRegistryModule)
local success4, cosmeticCrates = pcall(require, cosmeticCratesModule)
if success and success2 and success3 and success4 then return crateData, itemData, registryData, cosmeticCrates end
return nil, nil, nil, nil
end
cosmeticDropdown = Tabs.Shop:Dropdown({
Title = "Select Cosmetic",
Desc = "Choose cosmetics to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options) 
selectedCosmetics = {}
for _, option in ipairs(options) do
if option.Data and option.Data.Name and option.Data.Type then table.insert(selectedCosmetics, option.Data) end
end
end
})
Tabs.Shop:Button({
Title = "Refresh Cosmetic Items",
Icon = "refresh-cw",
Callback = function()
task.spawn(function()
local crateData, itemData, registryData, cosmeticCrates = loadCosmeticData()
if crateData and itemData and registryData then
local dropdownItems = {}
for crateName, crateInfo in pairs(crateData) do
local regInfo = registryData[crateInfo.CrateName or crateName]
local crateReg = cosmeticCrates and (cosmeticCrates[crateInfo.CrateName or crateName] or cosmeticCrates[crateName])
local icon = crateReg and crateReg.Icon or (regInfo and regInfo.Icon or "")
local currencyDisplay = ""
if crateInfo.SpecialCurrencyType and crateInfo.SpecialCurrencyType ~= "" then
currencyDisplay = string.format("%s %s", crateInfo.Price or 0, crateInfo.SpecialCurrencyType)
else
currencyDisplay = string.format("$%s", crateInfo.Price or 0)
end
table.insert(dropdownItems, {
Title = crateInfo.CrateName or crateName,
Icon = icon,
Desc = string.format("Crate | %s | %s", currencyDisplay, crateInfo.CrateRarity or "Unknown"),
Value = crateName,
Data = {Name = crateName, DisplayName = crateInfo.CrateName or crateName, Price = crateInfo.Price or 0, Rarity = crateInfo.CrateRarity or "Unknown", Type = "CRATE", SpecialCurrencyType = crateInfo.SpecialCurrencyType}
})
end
for itemName, itemInfo in pairs(itemData) do
local regInfo = registryData[itemInfo.CosmeticName or itemName]
local currencyDisplay = ""
if itemInfo.SpecialCurrencyType and itemInfo.SpecialCurrencyType ~= "" then
currencyDisplay = string.format("%s %s", itemInfo.Price or 0, itemInfo.SpecialCurrencyType)
else
currencyDisplay = string.format("$%s", itemInfo.Price or 0)
end
table.insert(dropdownItems, {
Title = itemInfo.CosmeticName or itemName,
Icon = regInfo and regInfo.Icon or "",
Desc = string.format("Item | %s", currencyDisplay),
Value = itemName,
Data = {Name = itemName, DisplayName = itemInfo.CosmeticName or itemName, Price = itemInfo.Price or 0, Type = "ITEM", SpecialCurrencyType = itemInfo.SpecialCurrencyType}
})
end
local fences = {{Name = "FLOWER", DisplayName = "Flower Fence", Type = "FENCE", Price = 0},{Name = "WOOD", DisplayName = "Wood Fence", Type = "FENCE", Price = 0},{Name = "STONE", DisplayName = "Stone Fence", Type = "FENCE", Price = 0}}
for _, fence in ipairs(fences) do
table.insert(dropdownItems, {Title = fence.DisplayName, Icon = "grid", Desc = "Fence", Value = fence.Name, Data = {Name = fence.Name, DisplayName = fence.DisplayName, Price = fence.Price, Type = "FENCE"}})
end
table.sort(dropdownItems, function(a, b) if a.Data.Type == b.Data.Type then return a.Title < b.Title end return a.Data.Type < b.Data.Type end)
cosmeticDropdown:Refresh(dropdownItems, {})
else
cosmeticDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle", Desc = "Cosmetic data not found"}})
end
end)
end
})
autoBuyCosmeticToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Cosmetic",
Value = false,
Callback = function(state)
cosmeticAutoBuyEnabled = state
if state then
cosmeticAutoBuyTask = task.spawn(function()
while cosmeticAutoBuyEnabled do
if #selectedCosmetics > 0 then
for _, cosmeticData in ipairs(selectedCosmetics) do
if hasEnoughMoneyForItem(cosmeticData) then
if cosmeticData.Type == "CRATE" then BuyCosmeticCrate:FireServer(cosmeticData.Name, "Cosmetics")
elseif cosmeticData.Type == "ITEM" then BuyCosmeticItem:FireServer(cosmeticData.Name, "Cosmetics")
elseif cosmeticData.Type == "FENCE" then BuyCosmeticShopFence:FireServer(cosmeticData.Name, "Fences") end
end
task.wait(0.01)
end
for i = 1, 5 do
if not cosmeticAutoBuyEnabled then break end
for _, cosmeticData in ipairs(selectedCosmetics) do
if hasEnoughMoneyForItem(cosmeticData) then
if cosmeticData.Type == "CRATE" then BuyCosmeticCrate:FireServer(cosmeticData.Name, "Cosmetics")
elseif cosmeticData.Type == "ITEM" then BuyCosmeticItem:FireServer(cosmeticData.Name, "Cosmetics")
elseif cosmeticData.Type == "FENCE" then BuyCosmeticShopFence:FireServer(cosmeticData.Name, "Fences") end
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if cosmeticAutoBuyTask then task.cancel(cosmeticAutoBuyTask) cosmeticAutoBuyTask = nil end
end
end
})
autoBuyAllCosmeticToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Cosmetic",
Value = false,
Callback = function(state)
cosmeticAutoBuyAllEnabled = state
if state then
cosmeticAutoBuyAllTask = task.spawn(function()
while cosmeticAutoBuyAllEnabled do
local crateData, itemData, _ = loadCosmeticData()
if crateData then
for crateName, crateInfo in pairs(crateData) do
local itemData = {Price = crateInfo.Price or 0, SpecialCurrencyType = crateInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyCosmeticCrate:FireServer(crateName, "Cosmetics")
end
task.wait(0.01)
end
end
if itemData then
for itemName, itemInfo in pairs(itemData) do
local checkData = {Price = itemInfo.Price or 0, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(checkData) then
BuyCosmeticItem:FireServer(itemName, "Cosmetics")
end
task.wait(0.01)
end
end
local fences = {"FLOWER", "WOOD", "STONE"}
for _, fenceName in ipairs(fences) do
BuyCosmeticShopFence:FireServer(fenceName, "Fences")
task.wait(0.01)
end
for i = 1, 8 do
if not cosmeticAutoBuyAllEnabled then break end
if crateData then
for crateName, crateInfo in pairs(crateData) do
local checkData = {Price = crateInfo.Price or 0, SpecialCurrencyType = crateInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(checkData) then
BuyCosmeticCrate:FireServer(crateName, "Cosmetics")
end
end
end
if itemData then
for itemName, itemInfo in pairs(itemData) do
local checkData = {Price = itemInfo.Price or 0, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(checkData) then
BuyCosmeticItem:FireServer(itemName, "Cosmetics")
end
end
end
for _, fenceName in ipairs(fences) do
BuyCosmeticShopFence:FireServer(fenceName, "Fences")
end
task.wait(0.04)
end
task.wait(0.15)
end
end)
else
if cosmeticAutoBuyAllTask then task.cancel(cosmeticAutoBuyAllTask) cosmeticAutoBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Traveling Merchant Autobuy", TextSize = 20 })
Tabs.Shop:Divider()
local seedPackDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("SeedPackData")
local petListModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"):WaitForChild("PetList")
local cosmeticListModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticRegistry"):WaitForChild("CosmeticList")
local gearDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("GearData")
local petEggsModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("PetRegistry"):WaitForChild("PetEggs")
local cosmeticCratesModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("CosmeticCrateRegistry"):WaitForChild("CosmeticCrates")
local travelingMerchantFolder = ReplicatedStorage:WaitForChild("Data"):WaitForChild("TravelingMerchant"):WaitForChild("TravelingMerchantData")
local BuyTravelingMerchantShopStock = ReplicatedStorage.GameEvents.BuyTravelingMerchantShopStock
local travelingAutoBuyEnabled = false
local travelingAutoBuyTask = nil
local selectedTraveling = {}
local travelingAutoBuyAllEnabled = false
local travelingAutoBuyAllTask = nil
function loadTravelingMerchantData()
local seedData = {} pcall(function() seedData = require(seedDataModule) end)
local seedPackPacks = {} pcall(function() seedPackPacks = require(seedPackDataModule).Packs or {} end)
local petList = {} pcall(function() petList = require(petListModule) end)
local cosmeticList = {} pcall(function() cosmeticList = require(cosmeticListModule) end)
local gearData = {} pcall(function() gearData = require(gearDataModule) end)
local petEggs = {} pcall(function() petEggs = require(petEggsModule) end)
local cosmeticCrates = {} pcall(function() cosmeticCrates = require(cosmeticCratesModule) end)
local dropdownItems = {}
for _, child in ipairs(travelingMerchantFolder:GetChildren()) do
if child:IsA("ModuleScript") then
local success, merchantData = pcall(require, child)
if success then
for itemName, itemInfo in pairs(merchantData) do
if itemInfo.Price and itemInfo.DisplayInShop ~= false then
local displayName = itemInfo.SeedName or itemInfo.DisplayName or itemName
local rarity = itemInfo.SeedRarity or itemInfo.Rarity or "Unknown"
local icon = itemInfo.Icon or ""
local itype = itemInfo.ItemType or "Seed"
local currencyDisplay = ""
if itemInfo.SpecialCurrencyType and itemInfo.SpecialCurrencyType ~= "" then
currencyDisplay = string.format("%s %s", itemInfo.Price, itemInfo.SpecialCurrencyType)
else
currencyDisplay = string.format("$%s", itemInfo.Price)
end
if icon == "" then
if itype == "Seed" then
local s = seedData[itemName] or seedData[displayName]
icon = s and (s.FruitIcon or s.Asset or "") or ""
elseif itype == "Pack" or string.find(itype, "Pack") then
local p = seedPackPacks[itemName] or seedPackPacks[displayName]
icon = p and p.Icon or ""
elseif itype == "Pet" then
local p = petList[itemName] or petList[displayName]
icon = p and p.Icon or ""
elseif itype == "Cosmetic" then
local c = cosmeticList[itemName] or cosmeticList[displayName]
icon = c and c.Icon or ""
elseif itype == "Gear" then
local g = gearData[itemName] or gearData[displayName]
icon = g and (g.Asset or "") or ""
elseif itype == "Egg" or string.find(itype, "Egg") then
local e = petEggs[itemName] or petEggs[displayName]
icon = e and e.Icon or ""
elseif itype == "Crate" or string.find(itype, "Crate") or itype == "CosmeticCrate" then
local cr = cosmeticCrates[itemName] or cosmeticCrates[displayName]
icon = cr and cr.Icon or ""
end
end
table.insert(dropdownItems, {
Title = displayName,
Icon = icon,
Desc = string.format("%s | %s", currencyDisplay, rarity),
Value = itemName,
Data = {Name = itemName, DisplayName = displayName, Price = itemInfo.Price, Rarity = rarity, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
})
end
end
end
end
end
table.sort(dropdownItems, function(a, b) return a.Data.Price < b.Data.Price end)
return dropdownItems
end
travelingDropdown = Tabs.Shop:Dropdown({
Title = "Select Traveling Merchant Item",
Desc = "Choose items to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options)
selectedTraveling = {}
for _, option in ipairs(options) do if option.Data and option.Data.Name then table.insert(selectedTraveling, option.Data) end end
end
})
Tabs.Shop:Button({
Title = "Refresh Traveling Items",
Icon = "refresh-cw",
Callback = function()
local items = loadTravelingMerchantData()
if #items > 0 then 
travelingDropdown:Refresh(items, {}) 
else 
travelingDropdown:Refresh({{Title = "Failed to load", Icon = "x-circle", Desc = "Traveling merchant data not found"}}) 
end
end
})
travelingAutoBuyToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Traveling Merchant",
Value = false,
Callback = function(state)
travelingAutoBuyEnabled = state
if state then
travelingAutoBuyTask = task.spawn(function()
while travelingAutoBuyEnabled do
if #selectedTraveling > 0 then
for _, itemData in ipairs(selectedTraveling) do
if hasEnoughMoneyForItem(itemData) then
BuyTravelingMerchantShopStock:FireServer(itemData.Name)
end
task.wait(0.01)
end
for i = 1, 5 do
if not travelingAutoBuyEnabled then break end
for _, itemData in ipairs(selectedTraveling) do
if hasEnoughMoneyForItem(itemData) then
BuyTravelingMerchantShopStock:FireServer(itemData.Name)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if travelingAutoBuyTask then task.cancel(travelingAutoBuyTask) travelingAutoBuyTask = nil end
end
end
})
travelingAutoBuyAllToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Traveling Merchant",
Value = false,
Callback = function(state)
travelingAutoBuyAllEnabled = state
if state then
travelingAutoBuyAllTask = task.spawn(function()
while travelingAutoBuyAllEnabled do
for _, child in ipairs(travelingMerchantFolder:GetChildren()) do
if child:IsA("ModuleScript") then
local success, merchantData = pcall(require, child)
if success then
for itemName, itemInfo in pairs(merchantData) do
if itemInfo.DisplayInShop ~= false then
local itemData = {Price = itemInfo.Price or 0, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyTravelingMerchantShopStock:FireServer(itemName)
end
end
task.wait(0.01)
end
end
end
end
for i = 1, 8 do
if not travelingAutoBuyAllEnabled then break end
for _, child in ipairs(travelingMerchantFolder:GetChildren()) do
if child:IsA("ModuleScript") then
local success, merchantData = pcall(require, child)
if success then
for itemName, itemInfo in pairs(merchantData) do
if itemInfo.DisplayInShop ~= false then
local itemData = {Price = itemInfo.Price or 0, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyTravelingMerchantShopStock:FireServer(itemName)
end
end
end
end
end
end
task.wait(0.04)
end
task.wait(0.15)
end
end)
else
if travelingAutoBuyAllTask then task.cancel(travelingAutoBuyAllTask) travelingAutoBuyAllTask = nil end
end
end
})
Tabs.Shop:Section({ Title = "Event Shop Autobuy", TextSize = 20 })
Tabs.Shop:Divider()
local eventShopDataModule = ReplicatedStorage:WaitForChild("Data"):WaitForChild("EventShopData")
local BuyEventShopStock = ReplicatedStorage.GameEvents.BuyEventShopStock
local eventAutoBuyEnabled = false
local eventAutoBuyTask = nil
local selectedEventItems = {}
local eventAutoBuyAllEnabled = false
local eventAutoBuyAllTask = nil
function loadEventShopData()
local success, eventData = pcall(require, eventShopDataModule)
if success then return eventData end
return nil
end
function getAllEventItems()
local eventData = loadEventShopData()
if not eventData then return {} end
local allItems = {}
for eventName, itemsTable in pairs(eventData) do
for itemName, itemInfo in pairs(itemsTable) do
if itemInfo.Price then
local displayName = itemInfo.SeedName or itemInfo.DisplayName or itemName
local rarity = itemInfo.SeedRarity or itemInfo.Rarity or "Unknown"
local icon = itemInfo.Icon or ""
local itype = itemInfo.ItemType or "Item"
local seedData = pcall(require, seedDataModule) and require(seedDataModule) or {}
local currencyDisplay = ""
if itemInfo.SpecialCurrencyType and itemInfo.SpecialCurrencyType ~= "" then
currencyDisplay = string.format("%s %s", itemInfo.Price, itemInfo.SpecialCurrencyType)
else
currencyDisplay = string.format("$%s", itemInfo.Price)
end
if icon == "" and itype == "Seed" then
local s = seedData[itemName] or seedData[displayName]
icon = s and (s.FruitIcon or s.Asset or "") or ""
end
table.insert(allItems, {
Title = displayName,
Icon = icon,
Desc = string.format("[%s] %s | %s", eventName, currencyDisplay, rarity),
Value = itemName,
Data = {
Name = itemName,
DisplayName = displayName,
Price = itemInfo.Price,
Rarity = rarity,
EventName = eventName,
SpecialCurrencyType = itemInfo.SpecialCurrencyType
}
})
end
end
end
table.sort(allItems, function(a, b) return a.Data.Price < b.Data.Price end)
return allItems
end
eventDropdown = Tabs.Shop:Dropdown({
Title = "Select Event Item",
Desc = "Choose event items to auto buy (Press Refresh to load items)",
Values = {{Title = "Press Refresh to load items", Icon = "refresh-cw", Desc = "Click the refresh button above"}},
Value = {},
Multi = true,
AllowNone = true,
SearchBarEnabled = true,
Callback = function(options)
selectedEventItems = {}
for _, option in ipairs(options) do
if option.Data and option.Data.Name then
table.insert(selectedEventItems, option.Data)
end
end
end
})
Tabs.Shop:Button({
Title = "Refresh Event Items",
Icon = "refresh-cw",
Callback = function()
local allItems = getAllEventItems()
if #allItems > 0 then
eventDropdown:Refresh(allItems, {})
else
eventDropdown:Refresh({{Title = "No event items", Icon = "x-circle", Desc = "Event shop data not found"}})
end
end
})
autoBuyEventToggle = Tabs.Shop:Toggle({
Title = "Auto Buy Event Item",
Value = false,
Callback = function(state)
eventAutoBuyEnabled = state
if state then
eventAutoBuyTask = task.spawn(function()
while eventAutoBuyEnabled do
if #selectedEventItems > 0 then
for _, itemData in ipairs(selectedEventItems) do
if hasEnoughMoneyForItem(itemData) then
BuyEventShopStock:FireServer(itemData.Name, itemData.EventName)
end
task.wait(0.01)
end
for i = 1, 5 do
if not eventAutoBuyEnabled then break end
for _, itemData in ipairs(selectedEventItems) do
if hasEnoughMoneyForItem(itemData) then
BuyEventShopStock:FireServer(itemData.Name, itemData.EventName)
end
end
task.wait(0.05)
end
else
task.wait(0.5)
end
task.wait(0.1)
end
end)
else
if eventAutoBuyTask then task.cancel(eventAutoBuyTask) eventAutoBuyTask = nil end
end
end
})
autoBuyAllEventToggle = Tabs.Shop:Toggle({
Title = "Auto Buy All Event Items",
Value = false,
Callback = function(state)
eventAutoBuyAllEnabled = state
if state then
eventAutoBuyAllTask = task.spawn(function()
while eventAutoBuyAllEnabled do
local eventData = loadEventShopData()
if eventData then
for eventName, itemsTable in pairs(eventData) do
for itemName, itemInfo in pairs(itemsTable) do
if itemInfo.Price then
local itemData = {Price = itemInfo.Price, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyEventShopStock:FireServer(itemName, eventName)
end
end
task.wait(0.01)
end
end
for i = 1, 8 do
if not eventAutoBuyAllEnabled then break end
for eventName, itemsTable in pairs(eventData) do
for itemName, itemInfo in pairs(itemsTable) do
if itemInfo.Price then
local itemData = {Price = itemInfo.Price, SpecialCurrencyType = itemInfo.SpecialCurrencyType}
if hasEnoughMoneyForItem(itemData) then
BuyEventShopStock:FireServer(itemName, eventName)
end
end
end
end
task.wait(0.04)
end
else
task.wait(0.5)
end
task.wait(0.15)
end
end)
else
if eventAutoBuyAllTask then task.cancel(eventAutoBuyAllTask) eventAutoBuyAllTask = nil end
end
end
})
autoBuyRebirth = false
Tabs.Shop:Space()
Tabs.Shop:Toggle({
Title = "Auto Buy Rebirth",
Default = false,
Callback = function(state)
autoBuyRebirth = state
if autoBuyRebirth then
while autoBuyRebirth do
local sheckles = DataService:GetData().Sheckles or 0
if sheckles >= 0 then
ReplicatedStorage.GameEvents.BuyRebirth:FireServer()
end
task.wait(300)
end
end
end
})
Tabs.Settings:Section({ Title = "Config Manager", TextSize = 20 })
Tabs.Settings:Divider()
local ConfigManager = Window.ConfigManager
local CurrentConfigName = "default"
local AutoLoadConfig = "default"
local AutoLoadEnabled = false
local AutoSaveEnabled = false
local ConfigListDropdown = nil
local AutoSaveConnection = nil
function FileExists(path)
if isfile then
return pcall(readfile, path)
end
return false
end
function WriteFile(path, content)
if writefile then
return pcall(writefile, path, content)
end
return false
end
function ReadFile(path)
if readfile then
local success, content = pcall(readfile, path)
if success then
return content
end
end
return ""
end
function loadAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Grow-A-Garden/AutoLoad.json"
if FileExists(autoLoadFile) then
local content = ReadFile(autoLoadFile)
if content ~= "" then
local success, data = pcall(function()
return HttpService:JSONDecode(content)
end)
if success and data then
AutoLoadConfig = data.configName or "default"
AutoLoadEnabled = data.enabled or false
return true
end
end
end
AutoLoadConfig = "default"
AutoLoadEnabled = false
return false
end
function saveAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Grow-A-Garden/AutoLoad.json"
local success = WriteFile(autoLoadFile, "")
if not success then
if makefolder then
pcall(function() makefolder("Darahub") end)
pcall(function() makefolder("Darahub/AutoLoad") end)
pcall(function() makefolder("Darahub/AutoLoad/Game") end)
pcall(function() makefolder("Darahub/AutoLoad/Game/Grow-A-Garden") end)
end
end
local data = {
enabled = AutoLoadEnabled,
configName = AutoLoadConfig
}
local success, json = pcall(function()
return HttpService:JSONEncode(data)
end)
if success then
WriteFile(autoLoadFile, json)
end
end
loadAutoLoadSettings()
ConfigNameInput = Tabs.Settings:Input({
Title = "Config Name",
Flag = "ConfigNameInput",
Flag = "ConfigNameInput",
Desc = "Name for your config file",
Icon = "file-cog",
Placeholder = "default",
Value = CurrentConfigName,
Callback = function(value)
if value ~= "" then
CurrentConfigName = value
end
end
})
Tabs.Settings:Space()
AutoLoadToggle = Tabs.Settings:Toggle({
Title = "Auto Load",
Flag = "AutoLoadToggle",
Flag = "AutoLoadToggle",
Desc = "Automatically load this config when script starts",
Value = AutoLoadEnabled,
Callback = function(state)
AutoLoadEnabled = state
if state then
AutoLoadConfig = CurrentConfigName
WindUI:Notify({
Title = "Auto-Load",
Content = "Config '" .. CurrentConfigName .. "' will load automatically on startup",
Duration = 3
})
end
saveAutoLoadSettings()
end
})
AutoSaveToggle = Tabs.Settings:Toggle({
Title = "Auto Save",
Flag = "AutoSaveToggle",
Flag = "AutoSaveToggle",
Desc = "Automatically save changes to config every second",
Value = AutoSaveEnabled,
Callback = function(state)
AutoSaveEnabled = state
if AutoSaveConnection then
AutoSaveConnection:Disconnect()
AutoSaveConnection = nil
end
if state then
WindUI:Notify({
Title = "Auto-Save",
Content = "Config will save automatically every second",
Duration = 2
})
AutoSaveConnection = RunService.Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1) 
end)
else
WindUI:Notify({
Title = "Auto-Save",
Content = "Auto-save disabled",
Duration = 2
})
end
end
})
Tabs.Settings:Space()
function refreshConfigList()
local allConfigs = ConfigManager:AllConfigs() or {}
if not table.find(allConfigs, "default") then
local defaultConfig = ConfigManager:Config("default")
if defaultConfig and defaultConfig.Save then
defaultConfig:Save()
end
table.insert(allConfigs, 1, "default")
end
table.sort(allConfigs, function(a, b)
return a:lower() < b:lower()
end)
local defaultValue = table.find(allConfigs, CurrentConfigName) and CurrentConfigName or "default"
if ConfigListDropdown and ConfigListDropdown.Refresh then
ConfigListDropdown:Refresh(allConfigs, defaultValue)
end
end
ConfigListDropdown = Tabs.Settings:Dropdown({
Title = "Existing Configs",
Flag = "ConfigListDropdown",
Flag = "ConfigListDropdown",
Desc = "Select from saved configs",
Values = {"default"},
Value = "default",
Callback = function(value)
CurrentConfigName = value
ConfigNameInput:Set(value)
if AutoLoadEnabled then
AutoLoadConfig = value
saveAutoLoadSettings()
end
local config = ConfigManager:GetConfig(value)
if config then
WindUI:Notify({
Title = "Config Selected",
Content = "Config '" .. value .. "' selected",
Duration = 2
})
end
end
})
Tabs.Settings:Space()
SaveConfigButton = Tabs.Settings:Button({
Title = "Save Config",
Desc = "Save current settings to config",
Icon = "save",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
local success = Window.CurrentConfig:Save()
if success then
WindUI:Notify({
Title = "Config Saved",
Content = "Config '" .. CurrentConfigName .. "' saved successfully",
Duration = 3
})
if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end
task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to save config",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
LoadConfigButton = Tabs.Settings:Button({
Title = "Load Config",
Desc = "Load settings from selected config",
Icon = "folder-open",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end
Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)
local success = Window.CurrentConfig:Load()
if success then
WindUI:Notify({
Title = "Config Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded successfully",
Duration = 3
})
if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end
else
WindUI:Notify({
Title = "Error",
Content = "Config '" .. CurrentConfigName .. "' not found or empty",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
DeleteConfigButton = Tabs.Settings:Button({
Title = "Delete Config",
Desc = "Delete selected config",
Icon = "trash-2",
Color = Color3.fromHex("#ff4830"),
Callback = function()
if CurrentConfigName == "default" then
WindUI:Notify({
Title = "Error",
Content = "Cannot delete default config",
Duration = 3
})
return
end
local success = ConfigManager:DeleteConfig(CurrentConfigName)
if success then
WindUI:Notify({
Title = "Config Deleted",
Content = "Config '" .. CurrentConfigName .. "' deleted",
Duration = 3
})
CurrentConfigName = "default"
ConfigNameInput:Set("default")
if AutoLoadEnabled then
AutoLoadConfig = "default"
saveAutoLoadSettings()
end
task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to delete config or config doesn't exist",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
RefreshConfigButton = Tabs.Settings:Button({
Title = "Refresh Config List",
Desc = "Update the list of available configs",
Icon = "refresh-cw",
Callback = function()
refreshConfigList()
WindUI:Notify({
Title = "Config List Refreshed",
Content = "Config list updated",
Duration = 2
})
end
})
task.spawn(function()
task.wait(0.5) 
refreshConfigList()
ConfigNameInput:Set("default")
if AutoLoadEnabled then
CurrentConfigName = AutoLoadConfig
ConfigNameInput:Set(CurrentConfigName)
task.wait(1)
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
if Window.CurrentConfig:Load() then
WindUI:Notify({
Title = "Auto-Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded automatically",
Duration = 3
})
end
end
end)
if AutoSaveEnabled then
task.spawn(function()
task.wait(1)
if AutoSaveEnabled then
AutoSaveConnection = RunService.Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1)
end)
end
end)
end
Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
Tabs.Settings:Divider()
themes = {}
availableThemes = WindUI:GetThemes()
for themeName, _ in pairs(availableThemes) do
table.insert(themes, themeName)
end
table.sort(themes)
ThemeDropdown = Tabs.Settings:Dropdown({
Title = "Select Theme",
Flag = "ThemeDropdown",
Values = themes,
SearchBarEnabled = true,
MenuWidth = 280,
Value = themes[1],
Callback = function(theme)
WindUI:SetTheme(theme)
end
})
TransparencySlider = Tabs.Settings:Slider({
Title = "Window Transparency",
Step = 0.01,
Flag = "TransparencySlider",
Value = { Min = 0, Max = 1, Default = WindUI.TransparencyValue },
Callback = function(value)
WindUI.TransparencyValue = tonumber(value)
Window:ToggleTransparency(tonumber(value) > 0)
end
})
Tabs.Settings:Section({ Title = "Keybinds" })
Tabs.Settings:Keybind({
Flag = "Keybind",
Title = "Keybind",
Desc = "Keybind to open ui",
Value = "RightControl",
Callback = function(RightControl)
Window:SetToggleKey(Enum.KeyCode[RightControl])
end
})
Tabs.Settings:Space()
FlyTogglekeybind = Tabs.Settings:Keybind({
Title = "Fly Toggle",
Desc = "Keybind to toggle Fly",
Value = "",
Flag = "FlyTogglekeybind",
Callback = function(v)
FlyToggle:Set(not FlyToggle.Value)
end
})
Tabs.Settings:Space()
Tabs.Settings:Keybind({
Title = "Invisible Toggle",
Desc = "Keybind to toggle invisible mode",
Value = "I",
Callback = function(v)
vu9 = not vu9
if ButtonLib and ButtonLib.InvisibleToggle then
ButtonLib.InvisibleToggle:Set(vu9)
end
for _, part in pairs(vu10) do
part.Transparency = vu9 and 0.5 or 0
end
end
})
do
local DarahubFolder = CoreGui:FindFirstChild("Darahub")
if DarahubFolder and Tabs and Tabs.Settings then
Tabs.Settings:Section({
Title = "GUI Size"
})
local defaultScales = {}
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
defaultScales[Element.Name] = Element.UIScale.Scale
end
end
Tabs.Settings:Button({
Title = "Reset All Scales",
Description = "Reverts all buttons to their startup scale values",
Callback = function()
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local original = defaultScales[Element.Name] or 1
Element.UIScale.Scale = original
end
end
end
})
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local currentScale = tonumber(Element.UIScale.Scale) or 1
Tabs.Settings:Slider({
Title = Element.Name .. " Scale",
Desc = "Adjust GUI scale",
Flag = "Scale_Slider_" .. Element.Name,
Step = 0.01,
Value = {
Min = 0.01,
Max = 4,
Default = currentScale
},
Callback = function(val)
if Element and Element:FindFirstChild("UIScale") then
Element.UIScale.Scale = tonumber(val)
end
end
})
end
end
end
end
Tabs.Settings:Space()
 
local FPSCounter = CoreGui:FindFirstChild("FPSCounter")

if FPSCounter then
FPSCounterToggle = Tabs.Settings:Toggle({
Title = "Show FPS Counter",
Flag = "FPSCounterToggle",
Value = true,
Callback = function(state)
if FPSCounter then
FPSCounter.Enabled = state
else
warn("Could Not Find \"FPSCounter\" in CoreGUI! Please Reload the script And try again.")
end
end
})
else
warn("No \"FPSCounter\" Found in CoreGUI")
end
Tabs.Settings:Section({ Title = "Sensitivity Controls", TextSize = 20 })
Tabs.Settings:Divider()
MouseSensitivityEnabled = false
MouseSensitivityValue = 1.0
MIN_SENSITIVITY = 0.1
MAX_SENSITIVITY = 20.0
DEFAULT_SENSITIVITY = 1.0
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false
function setupSensitivityHook()
if cameraInputModule then return true end
LocalPlayer = Players.LocalPlayer
success = false
pcall(function()
playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
if not playerScripts then return end
playerModule = playerScripts:FindFirstChild("PlayerModule")
if not playerModule then return end
cameraModule = playerModule:FindFirstChild("CameraModule")
if cameraModule then
cameraInput = cameraModule:FindFirstChild("CameraInput")
if cameraInput then
cameraInputModule = require(cameraInput)
if cameraInputModule and cameraInputModule.getRotation then
originalGetRotation = cameraInputModule.getRotation
cameraInputModule.getRotation = function(disableRotation)
rotation = originalGetRotation(disableRotation)
if MouseSensitivityEnabled and UserInputService.MouseEnabled then
return rotation * MouseSensitivityValue
elseif TouchSensitivityEnabled and UserInputService.TouchEnabled then
return rotation * TouchSensitivityValue
end
return rotation
end
success = true
end
end
end
end)
return success
end
MouseSensitivityToggle = Tabs.Settings:Toggle({
Title = "Mouse Sensitivity",
Flag = "MouseSensitivityToggle",
Desc = "Adjust mouse sensitivity",
Value = false,
Callback = function(state)
MouseSensitivityEnabled = state
if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Mouse Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
MouseSensitivityToggle:Set(false)
MouseSensitivityEnabled = false
end
end
end
})
MouseSensitivitySlider = Tabs.Settings:Slider({
Title = "Mouse Sensitivity Value",
Flag = "MouseSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
MouseSensitivityValue = value
end
})
Tabs.Settings:Space()
TouchSensitivityToggle = Tabs.Settings:Toggle({
Title = "Touch Sensitivity",
Flag = "TouchSensitivityToggle",
Desc = "Adjust touch/mobile sensitivity",
Value = false,
Callback = function(state)
TouchSensitivityEnabled = state
if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Touch Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
TouchSensitivityToggle:Set(false)
TouchSensitivityEnabled = false
end
end
end
})
TouchSensitivitySlider = Tabs.Settings:Slider({
Title = "Touch Sensitivity Value",
Flag = "TouchSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
TouchSensitivityValue = value
end
})
Tabs.Settings:Space()
Tabs.Settings:Section({ Title = "Reset Controls", TextSize = 20 })
Tabs.Settings:Divider()
Tabs.Settings:Button({
Title = "Reset Sensitivity Settings",
Desc = "Reset both mouse and touch sensitivity to defaults",
Icon = "refresh-cw",
Color = Color3.fromHex("#FF3030"),
Callback = function()
MouseSensitivityEnabled = false
MouseSensitivityValue = DEFAULT_SENSITIVITY
TouchSensitivityEnabled = false
TouchSensitivityValue = DEFAULT_SENSITIVITY
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false
if MouseSensitivityToggle then 
MouseSensitivityToggle:Set(false) 
end
if MouseSensitivitySlider then 
MouseSensitivitySlider:Set(1.0) 
end
if TouchSensitivityToggle then 
TouchSensitivityToggle:Set(false) 
end
if TouchSensitivitySlider then 
TouchSensitivitySlider:Set(1.0) 
end
WindUI:Notify({
Title = "Sensitivity Reset",
Content = "All sensitivity settings reset to default",
Duration = 3
})
end
})
local UniverseScriptsStuff = loadstring(game:HttpGet("https://darahub.pages.dev/Module/More-Scripts.Lua"))()
UniverseScriptsStuff(Tabs)`n]],
["https://darahub.pages.dev/api/script/Darahub-BladeBall.lua"] = [[`n-- FAILED FETCH: https://darahub.pages.dev/api/script/Darahub-BladeBall.lua`n]],
["https://darahub.pages.dev/api/script/Darahub-Nico-Nextbot.lua"] = [[`nif getgenv().DaraHubExecuted then
NotifyToast({
title = "WARNING!",
content = "Script Is Already Loaded, rejoin of you want to re-execute.",
duration = 8,
icon = "triangle-exclamation",
iconColor = "#FFFF00",
})
return
end
getgenv().DaraHubExecuted = true
WindUI = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/WindUI-Moded/main.lua"))()
loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/LoadAll.lua"))()
Window = WindUI:CreateWindow({
Title = "Dara Hub | Nico NextBot",
Icon = "rbxassetid://137330250139083",
Author = "Made By Pnsdg",
Folder = "Darahub/NicoBot",
Size = UDim2.fromOffset(580, 490),
Theme = "Dark",
HidePanelBackground = false,
NewElements = true,
Acrylic = false,
HideSearchBar = false,
SideBarWidth = 200,
OpenButton = {
Enabled = false,
Scale = 0
},
})
WindUI.TransparencyValue = 0.7
Window:ToggleTransparency(true)
Window:DisableTopbarButtons({ "Fullscreen" })
executor = identifyexecutor()
if type(executor) == "table" then
for key, value in pairs(executor) do
print(key .. ": " .. tostring(value))
end
elseif type(executor) == "string" then
Window:Tag({
Title = "" .. executor
})
else
print("The injector does not support identifyexecutor()")
end
Window:OnOpen(function()
ButtonLib:OpenButton(false)
end)
Window:OnClose(function()
ButtonLib:OpenButton(true)
end)
Window:OnDestroy(function()
ButtonLib:DestroyScreengui()
end)
Tabs = {
Main = Window:Tab({ Title = "Main", Icon = "layout-grid" }),
Player = Window:Tab({ Title = "Player", Icon = "user" }),
Visuals = Window:Tab({ Title = "Visuals", Icon = "camera" }),
ESP = Window:Tab({ Title = "ESP", Icon = "eye" }),
Combat = Window:Tab({ Title = "Combat", Icon = "sword" }),
Misc = Window:Tab({ Title = "Misc", Icon = "star" }),
Utility = Window:Tab({ Title = "Utility", Icon = "wrench" }),
Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
info = Window:Tab({ Title = "info", Icon = "info" }),
Others = Window:Tab({ Title = "Others", Icon = "https://em-content.zobj.net/source/apple/419/pile-of-poo_1f4a9.png" })
}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")

local Character
local Humanoid
local HumanoidRootPart

local function setupCharacter(character)
Character = character
Humanoid = character:FindFirstChildOfClass("Humanoid")
HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
end

if LocalPlayer.Character then
setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)
do
local clientStorageFolder = Instance.new("Folder")
clientStorageFolder.Name = "ClientStorage"
clientStorageFolder.Parent = game
end

local UniverseServerTools = loadstring(game:HttpGet("https://darahub.pages.dev/Module/UniverseServerTools.lua"))()
UniverseServerTools(Tabs)
socialsModule = loadstring(game:HttpGet("https://darahub.pages.dev/Module/info.lua"))()
socialsModule(Tabs)
IsOnMobile = false
xpcall(function()
IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

FLYING = false
flyspeed = 5
flyKeyDown = nil
flyKeyUp = nil

flyUpPressed = false
flyDownPressed = false

local crouchButton = nil
local crouchConnection = nil

local function HookCrouchbtn()
local mobileFrame = PlayerGui:FindFirstChild("mobile")
if not mobileFrame then return end

local frame = mobileFrame:FindFirstChild("Frame")
if not frame then return end

local crouchBtn = frame:FindFirstChild("crouchbutton")
if not crouchBtn then return end

crouchButton = crouchBtn

if crouchConnection then
crouchConnection:Disconnect()
crouchConnection = nil
end

crouchConnection = crouchButton.MouseButton1Down:Connect(function()
flyDownPressed = true
end)

crouchButton.MouseButton1Up:Connect(function()
flyDownPressed = false
end)

crouchButton.MouseLeave:Connect(function()
flyDownPressed = false
end)
end

local function OncrouchbuttonAdded()
local mobileFrame = PlayerGui:FindFirstChild("mobile")
if mobileFrame then
local frame = mobileFrame:FindFirstChild("Frame")
if frame then
if frame:FindFirstChild("crouchbutton") then
HookCrouchbtn()
else
frame.ChildAdded:Connect(function(child)
if child.Name == "crouchbutton" then
HookCrouchbtn()
end
end)
end
else
mobileFrame.ChildAdded:Connect(function(child)
if child.Name == "Frame" then
child.ChildAdded:Connect(function(grandchild)
if grandchild.Name == "crouchbutton" then
HookCrouchbtn()
end
end)
if child:FindFirstChild("crouchbutton") then
HookCrouchbtn()
end
end
end)
end
else
PlayerGui.ChildAdded:Connect(function(child)
if child.Name == "mobile" then
local frame = child:FindFirstChild("Frame")
if frame then
if frame:FindFirstChild("crouchbutton") then
HookCrouchbtn()
else
frame.ChildAdded:Connect(function(grandchild)
if grandchild.Name == "crouchbutton" then
HookCrouchbtn()
end
end)
end
else
child.ChildAdded:Connect(function(frameChild)
if frameChild.Name == "Frame" then
frameChild.ChildAdded:Connect(function(buttonChild)
if buttonChild.Name == "crouchbutton" then
HookCrouchbtn()
end
end)
if frameChild:FindFirstChild("crouchbutton") then
HookCrouchbtn()
end
end
end)
end
end
end)
end
end

if IsOnMobile then
HookCrouchbtn()
OncrouchbuttonAdded()

LocalPlayer:WaitForChild("PlayerGui")
touchGui = LocalPlayer.PlayerGui:WaitForChild("TouchGui")
touchControlFrame = touchGui:WaitForChild("TouchControlFrame")

originalJumpButton = touchControlFrame:WaitForChild("JumpButton")

isHoldingJump = false
originalJumpRectOffset = originalJumpButton.ImageRectOffset

originalJumpButton.MouseButton1Down:Connect(function()
isHoldingJump = true
originalJumpButton.ImageRectOffset = Vector2.new(146, 146)
flyUpPressed = true
end)

originalJumpButton.MouseButton1Up:Connect(function()
if isHoldingJump then
isHoldingJump = false
originalJumpButton.ImageRectOffset = originalJumpRectOffset
flyUpPressed = false
end
end)

originalJumpButton.MouseLeave:Connect(function()
if isHoldingJump then
isHoldingJump = false
originalJumpButton.ImageRectOffset = originalJumpRectOffset
flyUpPressed = false
end
end)
end

function getRoot(character)
return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
end

function unmobilefly(speaker)
pcall(function()
FLYING = false
flyUpPressed = false
flyDownPressed = false
if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
end
if mfly1 then mfly1:Disconnect() mfly1 = nil end
if mfly2 then mfly2:Disconnect() mfly2 = nil end
end)
end

function mobilefly(speaker)
unmobilefly(speaker)
FLYING = true

root = getRoot(speaker.Character)
if not root then return end

camera = workspace.CurrentCamera

controlModule = nil
pcall(function()
controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
end)

mfly2 = RunService.RenderStepped:Connect(function()
if not FLYING then return end

currentRoot = getRoot(speaker.Character)
currentCamera = workspace.CurrentCamera
currentHumanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")

if currentHumanoid and currentRoot then
currentHumanoid.PlatformStand = true

moveVector = Vector3.new(0, 0, 0)

if controlModule then
direction = controlModule:GetMoveVector()
speed = flyspeed * 50

moveVector = (currentCamera.CFrame.RightVector * direction.X * speed) +
(-currentCamera.CFrame.LookVector * direction.Z * speed)
end

if flyUpPressed then
moveVector = moveVector + Vector3.new(0, flyspeed * 50, 0)
end
if flyDownPressed then
moveVector = moveVector - Vector3.new(0, flyspeed * 50, 0)
end

currentRoot.Velocity = moveVector
end
end)
end

function pcfly()
char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
humanoid = char:FindFirstChildOfClass("Humanoid")
if not humanoid then
repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
humanoid = char:FindFirstChildOfClass("Humanoid")
end

if flyKeyDown or flyKeyUp then
flyKeyDown:Disconnect()
flyKeyUp:Disconnect()
end

T = getRoot(char)
if not T then return end

WPressed = false
SPressed = false
APressed = false
DPressed = false
SpacePressed = false
CtrlPressed = false

function FLY()
FLYING = true

task.spawn(function()
while FLYING do
task.wait()
camera = workspace.CurrentCamera
if not camera then continue end

currentRoot = getRoot(Players.LocalPlayer.Character)
currentHumanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

if currentHumanoid and currentRoot then
currentHumanoid.PlatformStand = true

moveDirection = Vector3.new(0, 0, 0)

if WPressed then
moveDirection = moveDirection + camera.CFrame.LookVector * flyspeed
end
if SPressed then
moveDirection = moveDirection - camera.CFrame.LookVector * flyspeed
end
if APressed then
moveDirection = moveDirection - camera.CFrame.RightVector * flyspeed
end
if DPressed then
moveDirection = moveDirection + camera.CFrame.RightVector * flyspeed
end
if SpacePressed then
moveDirection = moveDirection + Vector3.new(0, flyspeed * 2, 0)
end
if CtrlPressed then
moveDirection = moveDirection - Vector3.new(0, flyspeed * 2, 0)
end

currentRoot.Velocity = moveDirection * 16
end
end

if currentHumanoid then
currentHumanoid.PlatformStand = false
end
end)
end

flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = true
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = true
elseif input.KeyCode == Enum.KeyCode.A then
APressed = true
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = true
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = true
elseif input.KeyCode == Enum.KeyCode.LeftControl then
CtrlPressed = true
end
pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
end)

flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
if processed then return end
if input.KeyCode == Enum.KeyCode.W then
WPressed = false
elseif input.KeyCode == Enum.KeyCode.S then
SPressed = false
elseif input.KeyCode == Enum.KeyCode.A then
APressed = false
elseif input.KeyCode == Enum.KeyCode.D then
DPressed = false
elseif input.KeyCode == Enum.KeyCode.Space then
SpacePressed = false
elseif input.KeyCode == Enum.KeyCode.LeftControl then
CtrlPressed = false
end
end)

FLY()
end

function NOFLY()
FLYING = false
flyUpPressed = false
flyDownPressed = false
if flyKeyDown then 
flyKeyDown:Disconnect()
flyKeyDown = nil
end
if flyKeyUp then 
flyKeyUp:Disconnect()
flyKeyUp = nil
end

if IsOnMobile then
unmobilefly(Players.LocalPlayer)
else
if Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
end
root = getRoot(Players.LocalPlayer.Character)
if root then
root.Velocity = Vector3.new(0, 0, 0)
end
end
pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

function onCharacterAdded()
if FlyToggle and FlyToggle.Value then
task.wait(1)
if IsOnMobile then
mobilefly(Players.LocalPlayer)
else
pcfly()
end
end
end

Players.LocalPlayer.CharacterAdded:Connect(function()
NOFLY()
onCharacterAdded()
end)
Tabs.Player:Space()

FlyToggle = Tabs.Player:Toggle({
Title = "Fly",
Flag = "FlyToggle",
Value = false,
Callback = function(state)
if state then
if IsOnMobile then
mobilefly(Players.LocalPlayer)
else
pcfly()
end
else
NOFLY()
end
end
})

FlySpeedInput = Tabs.Player:Input({
Title = "Fly Speed",
Flag = "FlySpeedInput",
Placeholder = "Enter speed value",
Value = tostring(flyspeed),
NumbersOnly = true,
Callback = function(value)
speed = tonumber(value)
if speed and speed > 0 then
flyspeed = speed
end
end
})

ShowFlyButtonToggle = Tabs.Player:Toggle({
Title = "Fly Button",
Flag = "ShowFlyButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.Flight then
ButtonLib.Flight:SetVisible(state)
end
end
})

ButtonLib.Create:Toggle({
Text = "Flight",
Flag = "Flight",
Default = false,
Visible = false,
Callback = function(s) 
if FlyToggle then
FlyToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)
local ClientStorage = game:WaitForChild("ClientStorage")
local characterAddedConnection
local NoClipEnabled = false
local function noclip()
local character = Character
if not character then return end
local collisionPart = character:FindFirstChild("collisionPart")
if not collisionPart then return end
collisionPart:WaitForChild("BodyGyro")
collisionPart:WaitForChild("TouchInterest")
local existingPart = ClientStorage:FindFirstChild("collisionPart")
if existingPart then
existingPart:Destroy()
end
collisionPart.Parent = ClientStorage
end
local function clip()
local collisionPart = ClientStorage:FindFirstChild("collisionPart")
if not collisionPart then
return
end
local character = Character
if not character then
return
end
collisionPart.Parent = character
if characterAddedConnection then
characterAddedConnection:Disconnect()
characterAddedConnection = nil
end
end
local function toggleNoClip(state)
NoClipEnabled = state
if NoClipEnabled then
if not characterAddedConnection then
characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function()
task.wait(0.5)
if NoClipEnabled then
noclip()
end
end)
if Character then
noclip()
end
end
else
clip()
end
end
Tabs.Player:Space()
Tabs.Player:Toggle({
Title = "NoClip",
Flag = "NoClipToggle",
Value = false,
Callback = function(state)
toggleNoClip(state)
end
})
Tabs.Player:Space()

local specificsModule = nil
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function requireSpecificsModule()
local module = ReplicatedStorage:FindFirstChild("module")
if module then
local specifics = module:FindFirstChild("specificsModule")
if specifics then
local success, result = pcall(require, specifics)
if success then
specificsModule = result
end
end
end
end
requireSpecificsModule()
ReplicatedStorage.ChildAdded:Connect(function(child)
if child.Name == "module" then
child.ChildAdded:Connect(function(subChild)
if subChild.Name == "specificsModule" then
requireSpecificsModule()
end
end)
requireSpecificsModule()
elseif child.Name == "specificsModule" then
requireSpecificsModule()
end
end)
SprintSpeedInput = Tabs.Player:Input({
Title = "Sprint Speed Value",
Flag = "SprintSpeedInput",
Placeholder = "30",
Numeric = true,
Value = "30",
Callback = function(value)
local n = tonumber(value)
if n then
specificsModule:SetValue("SprintSpeed", n)
end
end
})
Tabs.Player:Space()
WalkSpeedInput = Tabs.Player:Input({
Title = "Walk Speed Value",
Flag = "WalkSpeedInput",
Placeholder = "10",
Numeric = true,
Value = "10",
Callback = function(value)
local n = tonumber(value)
if n then
specificsModule:SetValue("WalkSpeed", n)
end
end
})
Tabs.Player:Space()
CrouchSpeedInput = Tabs.Player:Input({
Title = "Crouch Speed Value",
Flag = "CrouchSpeedInput",
Placeholder = "5",
Numeric = true,
Value = "5",
Callback = function(value)
local n = tonumber(value)
if n then
specificsModule:SetValue("CrouchSpeed", n)
end
end
})
Tabs.Player:Space()
MaxSpeedInput = Tabs.Player:Input({
Title = "Max Speed Value",
Flag = "MaxSpeedInput",
Placeholder = "150",
Numeric = true,
Value = "150",
Callback = function(value)
local n = tonumber(value)
if n then
specificsModule:SetValue("MaxSpeed", n)
end
end
})
Tabs.Player:Space()
local loopJumpPower = {
Enabled = false,
JumpPower = 100,
RenderSteps = nil,
}

function StartLoopJumpPower()
loopJumpPower.Enabled = true
loopJumpPower.RenderSteps = RunService.RenderStepped:Connect(function()
if Humanoid and Humanoid.JumpPower > 0 and loopJumpPower.Enabled then
Humanoid.JumpPower = loopJumpPower.JumpPower
end
end)
end

function StopLoopJumpPower()
loopJumpPower.Enabled = false
if loopJumpPower.RenderSteps then
loopJumpPower.RenderSteps:Disconnect()
loopJumpPower.RenderSteps = nil
end
end

Tabs.Player:Toggle({
Title = "Loop Jump Power",
Value = loopJumpPower.Enabled,
Callback = function(state)
if state then
StartLoopJumpPower()
else
StopLoopJumpPower()
end
end,
})

Tabs.Player:Input({
Title = "Jump Power",
Value = "28.302",
Placeholder = "28.302",
Callback = function(n)
loopJumpPower.JumpPower = n
end,
})

Tabs.Player:Space()
-- Visuals Tab
Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
Tabs.Visuals:Divider()
local cameraStretchConnection
function setupCameraStretch()
cameraStretchConnection = nil
local stretchHorizontal = 0.80
local stretchVertical = 0.80
CameraStretchToggle = Tabs.Visuals:Toggle({
Title = "Camera Stretch",
Flag = "CameraStretchToggle",
Value = false,
Callback = function(state)
if state then
if cameraStretchConnection then cameraStretchConnection:Disconnect() end
cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
local Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
else
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = nil
end
end
end
})

CameraStretchHorizontalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Horizontal",
Flag = "CameraStretchHorizontalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchHorizontal),
Callback = function(value)
local num = tonumber(value)
if num then
stretchHorizontal = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
local Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})

CameraStretchVerticalInput = Tabs.Visuals:Input({
Title = "Camera Stretch Vertical",
Flag = "CameraStretchVerticalInput",
Placeholder = "0.80",
Numeric = true,
Value = tostring(stretchVertical),
Callback = function(value)
local num = tonumber(value)
if num then
stretchVertical = num
if cameraStretchConnection then
cameraStretchConnection:Disconnect()
cameraStretchConnection = game:GetService("RunService").RenderStepped:Connect(function()
local Camera = workspace.CurrentCamera
Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
end)
end
end
end
})
end

setupCameraStretch()
Tabs.Visuals:Space()
FullBrightToggle = Tabs.Visuals:Toggle({
Title = "Full Bright",
Value = false,
Callback = function(state)
FullBright = state
if state then
originalBrightness = game:GetService("Lighting").Brightness
originalAmbient = game:GetService("Lighting").Ambient
originalOutdoorAmbient = game:GetService("Lighting").OutdoorAmbient
originalColorShift_Top = game:GetService("Lighting").ColorShift_Top
originalColorShift_Bottom = game:GetService("Lighting").ColorShift_Bottom
game:GetService("Lighting").Brightness = 1
game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
game:GetService("Lighting").ColorShift_Top = Color3.fromRGB(255, 255, 255)
game:GetService("Lighting").ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
else
if originalBrightness then
game:GetService("Lighting").Brightness = originalBrightness
end
if originalAmbient then
game:GetService("Lighting").Ambient = originalAmbient
end
if originalOutdoorAmbient then
game:GetService("Lighting").OutdoorAmbient = originalOutdoorAmbient
end
if originalColorShift_Top then
game:GetService("Lighting").ColorShift_Top = originalColorShift_Top
end
if originalColorShift_Bottom then
game:GetService("Lighting").ColorShift_Bottom = originalColorShift_Bottom
end
end
end
})
Tabs.Visuals:Space()
NoFogToggle = Tabs.Visuals:Toggle({
Title = "NO FOG",
Value = false,
Callback = function(state)
NoFog = state
if state then
originalFogEnd = Lighting.FogEnd
Lighting.FogEnd = 100000
else
if originalFogEnd then
Lighting.FogEnd = originalFogEnd
else
Lighting.FogEnd = 100
end
end
end
})
Tabs.Visuals:Space()
Tabs.Visuals:Toggle({
Title = "LocalPlayer.PlayerGui.vignette.Enabled",
Value = true,
Callback = function(v)
game:GetService("Players").LocalPlayer.PlayerGui.vignette.Enabled = v
end
})
Tabs.Visuals:Space()
-- ESP
playerEspElements = {}
botEspElements = {}

playerBoxesEnabled = false
playerNamesEnabled = false
playerDistanceEnabled = false
playerHighlightsEnabled = false
playerBoxType = "2D"

botBoxesEnabled = false
botNamesEnabled = false
botDistanceEnabled = false
botHighlightsEnabled = false
botBoxType = "2D"

isRendering = true
windowFocused = true
renderConnection = nil
lastRenderTime = tick()
renderCheckConnection = nil

function getDistanceFromCamera(targetPosition)
local camera = workspace.CurrentCamera
if not camera then return 0 end
return (targetPosition - camera.CFrame.Position).Magnitude
end

function calculateBoxScale(distance)
if distance <= 17 then
return 1
else
local scale = 17 / distance
return math.max(scale, 0.3)
end
end

function findHumanoid(model)
for _, child in ipairs(model:GetChildren()) do
if child:IsA("Humanoid") then
return child
end
end
return nil
end

function findHumanoidRootPart(model)
for _, child in ipairs(model:GetChildren()) do
if child:IsA("BasePart") and child.Name:lower():find("root") then
return child
end
end
for _, child in ipairs(model:GetDescendants()) do
if child:IsA("BasePart") and child.Name:lower():find("root") then
return child
end
end
return nil
end

function create3DBox(Character, color, size)
local rootPart = findHumanoidRootPart(Character)
if not rootPart then return nil end

local folderName = "ESP_3DBox"
local folder = Character:FindFirstChild(folderName)
if folder then
folder:Destroy()
end

folder = Instance.new("Folder")
folder.Name = folderName
folder.Parent = Character

size = size or Vector3.new(4, 5, 3)
local offsetX = size.X / 2
local offsetY = size.Y / 2
local offsetZ = size.Z / 2

local edges = {
{Vector3.new(0, offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopFront"},
{Vector3.new(0, offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopBack"},
{Vector3.new(-offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopLeft"},
{Vector3.new(offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopRight"},
{Vector3.new(0, -offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomFront"},
{Vector3.new(0, -offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomBack"},
{Vector3.new(-offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomLeft"},
{Vector3.new(offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomRight"},
{Vector3.new(-offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontLeft"},
{Vector3.new(offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontRight"},
{Vector3.new(-offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackLeft"},
{Vector3.new(offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackRight"}
}

for _, edge in ipairs(edges) do
local position = edge[1]
local boxSize = edge[2]
local name = edge[3]

local adornment = Instance.new("BoxHandleAdornment")
adornment.Name = name
adornment.Adornee = rootPart
adornment.Size = boxSize
adornment.CFrame = CFrame.new(position)
adornment.Color3 = color
adornment.Transparency = 0.2
adornment.ZIndex = 10
adornment.AlwaysOnTop = true
adornment.Visible = true
adornment.Parent = folder
end

return folder
end

function update3DBoxColor(Character, color)
local folder = Character:FindFirstChild("ESP_3DBox")
if folder then
for _, adornment in ipairs(folder:GetChildren()) do
if adornment:IsA("BoxHandleAdornment") then
adornment.Color3 = color
end
end
end
end

function remove3DBox(Character)
local folder = Character:FindFirstChild("ESP_3DBox")
if folder then
folder:Destroy()
end
end

function createBillboard(Character, name, color, useModelParent)
local existing = Character:FindFirstChild("ESP_Billboard")
if existing then
existing:Destroy()
end

local billboard = Instance.new("BillboardGui")
billboard.Name = "ESP_Billboard"

if useModelParent then
billboard.Adornee = Character
billboard.Parent = Character
else
local rootPart = findHumanoidRootPart(Character)
if rootPart then
billboard.Adornee = rootPart
billboard.Parent = rootPart
else
billboard.Adornee = Character
billboard.Parent = Character
end
end

billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 200, 0, 50)
billboard.StudsOffset = Vector3.new(0, 3, 0)
billboard.ClipsDescendants = false
billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
billboard.Active = true

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Parent = billboard

local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "NameLabel"
nameLabel.Size = UDim2.new(1, 0, 0, 20)
nameLabel.Position = UDim2.new(0, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = name
nameLabel.TextColor3 = color
nameLabel.TextSize = 14
nameLabel.Font = Enum.Font.GothamSemibold
nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
nameLabel.TextStrokeTransparency = 0.3
nameLabel.TextXAlignment = Enum.TextXAlignment.Center
nameLabel.TextYAlignment = Enum.TextYAlignment.Bottom
nameLabel.Parent = mainFrame

local distanceLabel = Instance.new("TextLabel")
distanceLabel.Name = "DistanceLabel"
distanceLabel.Size = UDim2.new(1, 0, 0, 16)
distanceLabel.Position = UDim2.new(0, 0, 0, 20)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = ""
distanceLabel.TextColor3 = color
distanceLabel.TextSize = 12
distanceLabel.Font = Enum.Font.Gotham
distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
distanceLabel.TextStrokeTransparency = 0.3
distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
distanceLabel.TextYAlignment = Enum.TextYAlignment.Top
distanceLabel.Parent = mainFrame

return {
billboard = billboard,
nameLabel = nameLabel,
distanceLabel = distanceLabel
}
end

function updateBillboard(billboardData, name, distance, color)
if not billboardData then return end

if name then
billboardData.nameLabel.Text = name
billboardData.nameLabel.TextColor3 = color
end

if distance then
billboardData.distanceLabel.Text = string.format("%.1f studs", distance)
billboardData.distanceLabel.TextColor3 = color
end

billboardData.nameLabel.Visible = name ~= nil
billboardData.distanceLabel.Visible = distance ~= nil
end

function create2DBox(Character, color, scale, useModelParent)
local existing = Character:FindFirstChild("ESP_2DBox")
if existing then
existing:Destroy()
end

local billboard = Instance.new("BillboardGui")
billboard.Name = "ESP_2DBox"

if useModelParent then
billboard.Adornee = Character
billboard.Parent = Character
else
local rootPart = findHumanoidRootPart(Character)
if rootPart then
billboard.Adornee = rootPart
billboard.Parent = rootPart
else
billboard.Adornee = Character
billboard.Parent = Character
end
end

billboard.AlwaysOnTop = true
billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
billboard.StudsOffset = Vector3.new(0, 0, 0)
billboard.ClipsDescendants = false

local boxFrame = Instance.new("Frame")
boxFrame.Name = "BoxFrame"
boxFrame.Size = UDim2.new(1, 0, 1, 0)
boxFrame.BackgroundTransparency = 1
boxFrame.BorderSizePixel = 0
boxFrame.Parent = billboard

local uiStroke = Instance.new("UIStroke")
uiStroke.Thickness = math.max(1.5 * scale, 1)
uiStroke.Transparency = 0
uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiStroke.Color = color
uiStroke.Parent = boxFrame

return {
billboard = billboard,
boxFrame = boxFrame,
stroke = uiStroke,
scale = scale
}
end

function update2DBox(boxData, color, scale)
if boxData then
if boxData.stroke then
boxData.stroke.Color = color
end
if boxData.billboard then
boxData.billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
end
if boxData.stroke then
boxData.stroke.Thickness = math.max(1.5 * scale, 1)
end
boxData.scale = scale
end
end

function remove2DBox(Character)
local box = Character:FindFirstChild("ESP_2DBox")
if box then
box:Destroy()
end
local rootPart = findHumanoidRootPart(Character)
if rootPart then
local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
if boxInRoot then
boxInRoot:Destroy()
end
end
for _, part in ipairs(Character:GetDescendants()) do
if part:IsA("BasePart") then
local boxInPart = part:FindFirstChild("ESP_2DBox")
if boxInPart then
boxInPart:Destroy()
end
end
end
end

function createHighlight(Character, color)
local existing = Character:FindFirstChild("ESP_Highlight")
if existing then
existing:Destroy()
end

local highlight = Instance.new("Highlight")
highlight.Name = "ESP_Highlight"
highlight.Adornee = Character
highlight.FillColor = color
highlight.OutlineColor = color
highlight.FillTransparency = 0.5
highlight.OutlineTransparency = 0.3
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent = Character

return highlight
end

function updateHighlight(highlight, color)
if highlight then
highlight.FillColor = color
highlight.OutlineColor = color
end
end

function removeHighlight(Character)
local highlight = Character:FindFirstChild("ESP_Highlight")
if highlight then
highlight:Destroy()
end
end

function getPlayerColor(LocalPlayer)
return Color3.fromRGB(0, 255, 0)
end

function getBotColor(bot)
return Color3.fromRGB(255, 0, 0)
end

function cleanupPlayerESP()
for Character, esp in pairs(playerEspElements) do
if esp.box2D then remove2DBox(Character) end
if esp.box3D then remove3DBox(Character) end
if esp.highlight then removeHighlight(Character) end
if esp.billboard then
local bill = Character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(Character)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
end
playerEspElements = {}
end

function cleanupBotESP()
for bot, esp in pairs(botEspElements) do
if esp.box2D then remove2DBox(bot) end
if esp.box3D then remove3DBox(bot) end
if esp.highlight then removeHighlight(bot) end
if esp.billboard then
local bill = bot:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(bot)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
end
botEspElements = {}
end

function updatePlayerESP()
if not isRendering or not windowFocused then return end
if not workspace.CurrentCamera then return end

local currentTargets = {}

for _, otherPlayer in ipairs(Players:GetPlayers()) do
if otherPlayer ~= LocalPlayer then
local Character = otherPlayer.Character
if Character then
local humanoid = findHumanoid(Character)
local rootPart = findHumanoidRootPart(Character)
if humanoid and humanoid.Health > 0 and rootPart then
currentTargets[Character] = true

if not playerEspElements[Character] then
playerEspElements[Character] = {}
end

local esp = playerEspElements[Character]
local distance = getDistanceFromCamera(rootPart.Position)
local scale = calculateBoxScale(distance)
local boxColor = getPlayerColor(otherPlayer)

if playerBoxesEnabled then
if playerBoxType == "2D" then
if not esp.box2D then
esp.box2D = create2DBox(Character, boxColor, scale, false)
end
update2DBox(esp.box2D, boxColor, scale)
if esp.box3D then
remove3DBox(Character)
esp.box3D = nil
end
else
local boxSize = Vector3.new(4, 5, 3)
if humanoid then
boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
end
if not esp.box3D then
esp.box3D = create3DBox(Character, boxColor, boxSize)
end
update3DBoxColor(Character, boxColor)
if esp.box2D then
remove2DBox(Character)
esp.box2D = nil
end
end
else
if esp.box2D then remove2DBox(Character) end
if esp.box3D then remove3DBox(Character) end
end

if playerHighlightsEnabled then
if not esp.highlight then
esp.highlight = createHighlight(Character, boxColor)
end
updateHighlight(esp.highlight, boxColor)
else
if esp.highlight then
removeHighlight(Character)
esp.highlight = nil
end
end

if playerNamesEnabled or playerDistanceEnabled then
if not esp.billboard then
esp.billboard = createBillboard(Character, otherPlayer.Name, boxColor, false)
end
local displayDistance = playerDistanceEnabled and distance or nil
updateBillboard(esp.billboard, playerNamesEnabled and otherPlayer.Name or nil, displayDistance, boxColor)
else
if esp.billboard then
local bill = Character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(Character)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
esp.billboard = nil
end
end
end
end
end
end

for Character, esp in pairs(playerEspElements) do
if not currentTargets[Character] then
if esp.box2D then remove2DBox(Character) end
if esp.box3D then remove3DBox(Character) end
if esp.highlight then removeHighlight(Character) end
if esp.billboard then
local bill = Character:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(Character)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
playerEspElements[Character] = nil
end
end
end

function updateBotESP()
if not isRendering or not windowFocused then return end
if not workspace.CurrentCamera then return end

local currentTargets = {}
local botsFolder = workspace:FindFirstChild("bots")

if not botsFolder then return end

for _, bot in ipairs(botsFolder:GetChildren()) do
if bot:IsA("Model") then
local humanoid = findHumanoid(bot)
local rootPart = findHumanoidRootPart(bot)
if humanoid and humanoid.Health > 0 and rootPart then
currentTargets[bot] = true

if not botEspElements[bot] then
botEspElements[bot] = {}
end

local esp = botEspElements[bot]
local distance = getDistanceFromCamera(rootPart.Position)
local scale = calculateBoxScale(distance)
local boxColor = getBotColor(bot)
local botName = bot.Name or "Bot"

if botBoxesEnabled then
if botBoxType == "2D" then
if not esp.box2D then
esp.box2D = create2DBox(bot, boxColor, scale, true)
end
update2DBox(esp.box2D, boxColor, scale)
if esp.box3D then
remove3DBox(bot)
esp.box3D = nil
end
else
local boxSize = Vector3.new(4, 5, 3)
if humanoid then
boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
end
if not esp.box3D then
esp.box3D = create3DBox(bot, boxColor, boxSize)
end
update3DBoxColor(bot, boxColor)
if esp.box2D then
remove2DBox(bot)
esp.box2D = nil
end
end
else
if esp.box2D then remove2DBox(bot) end
if esp.box3D then remove3DBox(bot) end
end

if botHighlightsEnabled then
if not esp.highlight then
esp.highlight = createHighlight(bot, boxColor)
end
updateHighlight(esp.highlight, boxColor)
else
if esp.highlight then
removeHighlight(bot)
esp.highlight = nil
end
end

if botNamesEnabled or botDistanceEnabled then
if not esp.billboard then
esp.billboard = createBillboard(bot, botName, boxColor, true)
end
local displayDistance = botDistanceEnabled and distance or nil
updateBillboard(esp.billboard, botNamesEnabled and botName or nil, displayDistance, boxColor)
else
if esp.billboard then
local bill = bot:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(bot)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
esp.billboard = nil
end
end
end
end
end

for bot, esp in pairs(botEspElements) do
if not currentTargets[bot] then
if esp.box2D then remove2DBox(bot) end
if esp.box3D then remove3DBox(bot) end
if esp.highlight then removeHighlight(bot) end
if esp.billboard then
local bill = bot:FindFirstChild("ESP_Billboard")
if bill then bill:Destroy() end
local rootPart = findHumanoidRootPart(bot)
if rootPart then
local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
if billInRoot then billInRoot:Destroy() end
end
end
botEspElements[bot] = nil
end
end
end

function onRenderStepped()
lastRenderTime = tick()
isRendering = true

if playerBoxesEnabled or playerNamesEnabled or playerDistanceEnabled or playerHighlightsEnabled then
updatePlayerESP()
else
cleanupPlayerESP()
end

if botBoxesEnabled or botNamesEnabled or botDistanceEnabled or botHighlightsEnabled then
updateBotESP()
else
cleanupBotESP()
end
end

function startRenderLoop()
if renderConnection then return end
renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
end

function stopRenderLoop()
if renderConnection then
renderConnection:Disconnect()
renderConnection = nil
end
end

function cleanupAllESP()
cleanupPlayerESP()
cleanupBotESP()
end

RunService.RenderStepped:Connect(function()
lastRenderTime = tick()
isRendering = true
end)

renderCheckConnection = RunService.Heartbeat:Connect(function()
local currentTime = tick()
if currentTime - lastRenderTime > 1 then
isRendering = false
cleanupAllESP()
end
end)

UserInputService.WindowFocusReleased:Connect(function()
windowFocused = false
isRendering = false
cleanupAllESP()
end)

UserInputService.WindowFocused:Connect(function()
windowFocused = true
isRendering = true
end)

game:GetService("GuiService"):GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
if game:GetService("GuiService").MenuIsOpen then
isRendering = false
cleanupAllESP()
else
isRendering = true
end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == LocalPlayer then
cleanupAllESP()
stopRenderLoop()
end
end)

Tabs.ESP:Section({ Title = "Player ESP", TextSize = 20})
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
Title = "Player Boxes",
Flag = "PlayerBoxes",
Value = false,
Callback = function(state) 
playerBoxesEnabled = state
if state then startRenderLoop() else cleanupPlayerESP() end
end
})

Tabs.ESP:Dropdown({
Title = "Player Box Type",
Flag = "PlayerBoxType",
Values = {"2D", "3D"},
Value = "2D",
Callback = function(value) playerBoxType = value end
})

Tabs.ESP:Toggle({
Title = "Player Names",
Flag = "PlayerNames",
Value = false,
Callback = function(state) 
playerNamesEnabled = state
if state then startRenderLoop() else cleanupPlayerESP() end
end
})

Tabs.ESP:Toggle({
Title = "Player Distance",
Flag = "PlayerDistance",
Value = false,
Callback = function(state) 
playerDistanceEnabled = state
if state then startRenderLoop() else cleanupPlayerESP() end
end
})

Tabs.ESP:Toggle({
Title = "Player Highlights",
Flag = "PlayerHighlights",
Value = false,
Callback = function(state) 
playerHighlightsEnabled = state
if state then startRenderLoop() else cleanupPlayerESP() end
end
})

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Bot ESP", TextSize = 20})
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
Title = "Bot Boxes",
Flag = "BotBoxes",
Value = false,
Callback = function(state) 
botBoxesEnabled = state
if state then startRenderLoop() else cleanupBotESP() end
end
})

Tabs.ESP:Dropdown({
Title = "Bot Box Type",
Flag = "BotBoxType",
Values = {"2D", "3D"},
Value = "2D",
Callback = function(value) botBoxType = value end
})

Tabs.ESP:Toggle({
Title = "Bot Names",
Flag = "BotNames",
Value = false,
Callback = function(state) 
botNamesEnabled = state
if state then startRenderLoop() else cleanupBotESP() end
end
})

Tabs.ESP:Toggle({
Title = "Bot Distance",
Flag = "BotDistance",
Value = false,
Callback = function(state) 
botDistanceEnabled = state
if state then startRenderLoop() else cleanupBotESP() end
end
})

Tabs.ESP:Toggle({
Title = "Bot Highlights",
Flag = "BotHighlights",
Value = false,
Callback = function(state) 
botHighlightsEnabled = state
if state then startRenderLoop() else cleanupBotESP() end
end
})

local Bhop = false
local walkSpeedMultiplierEnabled = false

local stateChangedConnection = nil
local heartbeatConnection = nil
local bhopLoaded = false
local characterConnection = nil
local Jumploop = nil

function Jump()
if not Jumploop then
Jumploop = RunService.RenderStepped:Connect(function(deltatime)
if Humanoid.FloorMaterial == Enum.Material.Air then
Humanoid.Jump = false
if Jumploop then
Jumploop:Disconnect()
Jumploop = nil
end
else
if Humanoid.JumpPower == 0 then Humanoid.JumpPower = 28.302 end
Humanoid.Jump = true
end
end)
end
end
local accelerationMethod = "Acceleration"
local accelerationValue = 0.2

local GROUND_CHECK_DISTANCE = 3.5
local MAX_SLOPE_ANGLE = 45

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.IgnoreWater = true

local function IsOnGround()
if not Character or not HumanoidRootPart or not Humanoid then 
return false 
end

raycastParams.FilterDescendantsInstances = {Character}

local rayOrigin = HumanoidRootPart.Position
local rayDirection = Vector3.new(0, -GROUND_CHECK_DISTANCE, 0)
local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

if not raycastResult then 
return false 
end

local surfaceNormal = raycastResult.Normal
local dotProduct = surfaceNormal:Dot(Vector3.new(0, 1, 0))
local angle = math.deg(math.acos(dotProduct))

return angle <= MAX_SLOPE_ANGLE
end

local function increaseWalkSpeed()
if not Humanoid then return end

if Bhop and accelerationMethod == "Acceleration" and walkSpeedMultiplierEnabled then
local multiplier = 1 + accelerationValue
Humanoid.WalkSpeed = Humanoid.WalkSpeed * multiplier
end
end

local function getAccelerationValue(currentSpeed)
if accelerationMethod == "Normal Speed" then
return nil
elseif accelerationMethod == "Acceleration" then
return accelerationValue
end
return nil
end

local function performJumpBoost()
if not Humanoid or not Humanoid.Parent then
return false
end
Jump()
increaseWalkSpeed()

local accel = getAccelerationValue()
if accel and HumanoidRootPart then
local velocity = HumanoidRootPart.Velocity
local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
HumanoidRootPart.Velocity = Vector3.new(
horizontalVelocity.X * (1 + accel),
velocity.Y,
horizontalVelocity.Z * (1 + accel)
)
end

return true
end

local function shouldJump()
if not Bhop or not bhopLoaded then
return false
end

if not Humanoid or not Humanoid.Parent then
return false
end

local state = Humanoid:GetState()
return state == Enum.HumanoidStateType.Landed or IsOnGround()
end

local function tryJump()
if shouldJump() then
if Humanoid:GetState() == Enum.HumanoidStateType.Landed then
task.wait(0.05)
end
performJumpBoost()
end
end

local function onStateChanged(_, newState)
if bhopLoaded and newState == Enum.HumanoidStateType.Landed then
tryJump()
end
end

local function heartbeatCheck()
if shouldJump() then
local state = Humanoid:GetState()
if state ~= Enum.HumanoidStateType.Landed and IsOnGround() then
performJumpBoost()
end
end
end

local function loadBhop()
if bhopLoaded then 
return 
end

bhopLoaded = true

if stateChangedConnection then
stateChangedConnection:Disconnect()
stateChangedConnection = nil
end

if heartbeatConnection then
heartbeatConnection:Disconnect()
heartbeatConnection = nil
end

if Humanoid then
stateChangedConnection = Humanoid.StateChanged:Connect(onStateChanged)
end

heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(heartbeatCheck)
end

local function unloadBhop()
if not bhopLoaded then 
return 
end

bhopLoaded = false

if stateChangedConnection then
stateChangedConnection:Disconnect()
stateChangedConnection = nil
end

if heartbeatConnection then
heartbeatConnection:Disconnect()
heartbeatConnection = nil
end
end

local function checkBhopState()
if Bhop then
loadBhop()
else
unloadBhop()
end
end

local function reapplyBhopOnRespawn()
if Bhop then
task.wait(0.5)
checkBhopState()
end
end

local function UpdateCharacter(char)
Character = char
Humanoid = char:WaitForChild("Humanoid")
HumanoidRootPart = char:WaitForChild("HumanoidRootPart")

if bhopLoaded then
if stateChangedConnection then
stateChangedConnection:Disconnect()
end
stateChangedConnection = Humanoid.StateChanged:Connect(onStateChanged)
end
end

if game:GetService("Players").LocalPlayer.Character then
UpdateCharacter(game:GetService("Players").LocalPlayer.Character)
end

characterConnection = game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
UpdateCharacter(char)
reapplyBhopOnRespawn()
end)

game:GetService("Players").PlayerRemoving:Connect(function(leavingPlayer)
if leavingPlayer == game:GetService("Players").LocalPlayer then
unloadBhop()
if characterConnection then
characterConnection:Disconnect()
characterConnection = nil
end
if stateChangedConnection then
stateChangedConnection:Disconnect()
stateChangedConnection = nil
end
if heartbeatConnection then
heartbeatConnection:Disconnect()
heartbeatConnection = nil
end
end
end)

Tabs.Misc:Section({Title="Misc" TextSize = 20})
antiAFKConnection = nil
function startAntiAFK()
if antiAFKConnection then return end
antiAFKConnection = RunService.Heartbeat:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
function stopAntiAFK()
if antiAFKConnection then
antiAFKConnection:Disconnect()
antiAFKConnection = nil
end
end
AntiAFKToggle = Tabs.Misc:Toggle({
Title = "ANTI AFK",
Flag = "Anti AFK",
Value = false,
Callback = function(state)
if state then
startAntiAFK()
else
stopAntiAFK()
end
end
})
Tabs.Misc:Section({Title="Automation"})
function FireVote(mapNumber)
local voteEvent = game:GetService("ReplicatedStorage").events.player.char.LocalVote
voteEvent:Fire(mapNumber)
end
function startAutoVote()
AutoVoteConnection = RunService.Heartbeat:Connect(function()
if LocalPlayer.PlayerGui.round.time.Frame.time.label.Text == "intermission" then
FireVote(SelectedMap)
end
end)
end
function stopAutoVote()
if AutoVoteConnection then
AutoVoteConnection:Disconnect()
AutoVoteConnection = nil
end
end
local dropdownValues = {}
for i = 1, 4 do
table.insert(dropdownValues, "Map " .. i)
end
AutoVoteDropdown = Tabs.Misc:Dropdown({
Title = "Auto Vote Map",
Flag = "AutoVoteDropdown",
Values = dropdownValues,
Value = "Map 1",
Callback = function(value)
SelectedMap = tonumber(value:match("%d+"))
end
})
AutoVoteToggle = Tabs.Misc:Toggle({
Title = "Auto Vote",
Flag = "AutoVoteToggle",
Value = false,
Callback = function(state)
AutoVote = state
if state then
startAutoVote()
else
stopAutoVote()
end
end
})
Tabs.Misc:Space()
local controlModule = require(LocalPlayer.PlayerScripts.PlayerModule.ControlModule)
local autowalk = {
originalMoveFunction = controlModule.moveFunction,
direction = Vector3.new(0, 0, 1),
isMoving = false,
enabled = false
}
local function customMoveFunction(player, moveVector, isRelative)
if moveVector.Magnitude > 0 then
autowalk.isMoving = true
autowalk.originalMoveFunction(player, moveVector, isRelative)
else
autowalk.isMoving = false
if autowalk.enabled then
local camera = workspace.CurrentCamera
if camera then
local cameraDirection = camera.CFrame.LookVector
local moveDirection = Vector3.new(
cameraDirection.X * autowalk.direction.Z,
0,
cameraDirection.Z * autowalk.direction.Z
).Unit
autowalk.originalMoveFunction(player, moveDirection, isRelative)
else
autowalk.originalMoveFunction(player, autowalk.direction, isRelative)
end
else
autowalk.originalMoveFunction(player, moveVector, isRelative)
end
end
end
AutoWalkToggle = Tabs.Misc:Toggle({
Title = "Auto Walk",
Flag = "AutoWalkToggle",
Value = false,
Callback = function(state)
if state then
if not autowalk.enabled then
autowalk.enabled = true
controlModule.moveFunction = customMoveFunction
end
else
if autowalk.enabled then
autowalk.enabled = false
controlModule.moveFunction = autowalk.originalMoveFunction
autowalk.originalMoveFunction(LocalPlayer, Vector3.zero, false)
end
end
end
})
ShowAutoWalkButtonToggle = Tabs.Misc:Toggle({
Title = "Show Auto Walk Button",
Flag = "ShowAutoWalkButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.AutoWalkToggle then
ButtonLib.AutoWalkToggle:SetVisible(state)
end
end
})
AutoWalkDirectionInput = Tabs.Misc:Input({
Title = "Move Direction",
Flag = "AutoWalkDirectionInput",
Placeholder = "X Y Z",
Value = "0 0 1",
Callback = function(value)
local x, y, z = value:match("([%d.-]+)%s+([%d.-]+)%s+([%d.-]+)")
if x and y and z then
autowalk.direction = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end
end
})
ButtonLib.Create:Toggle({
Text = "Auto Walk",
Flag = "AutoWalkToggle",
Default = false,
Visible = false,
Callback = function(s)
if AutoWalkToggle then
AutoWalkToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)
Tabs.Misc:Section({Title="Bhop"})

BhopToggle = Tabs.Misc:Toggle({
Title = "Bhop",
Flag = "BhopToggle",
Value = false,
Callback = function(state)
Bhop = state
checkBhopState()
end
})

ShowBunnyHopButtonToggle = Tabs.Misc:Toggle({
Title = "Show Bhop Button",
Flag = "ShowBunnyHopButton",
Value = false,
Callback = function(state)
if ButtonLib and ButtonLib.BunnyHopToggle then
ButtonLib.BunnyHopToggle:SetVisible(state)
end
end
})

AccelerationDropdown = Tabs.Misc:Dropdown({
Title = "Bhop Mode",
Flag = "AccelerationDropdown",
Values = {"Normal Speed", "Acceleration"},
Value = "Normal Speed",
Callback = function(value)
accelerationMethod = value
end
})

AccelerationInput = Tabs.Misc:Input({
Title = "Bhop Acceleration",
Flag = "AccelerationInput",
Placeholder = "0.2",
Numeric = true,
Value = "0.2",
Callback = function(value)
local n = tonumber(value)
if n then
accelerationValue = n
end
end
})

BhopWalkSpeedMultiplier = Tabs.Misc:Toggle({
Title = "Bhop Walk Speed Multiplier",
Flag = "Bhop Walk Speed Multiplier",
Value = false,
Type = "Checkbox",
Callback = function(state)
walkSpeedMultiplierEnabled = state
end
})

ButtonLib.Create:Toggle({
Text = "Bunny Hop",
Flag = "BunnyHopToggle",
Default = false,
Visible = false,
Callback = function(s) 
if BhopToggle then
BhopToggle:Set(s)
end
end
}).Position = UDim2.new(0.5, -125, 0.4, 0)

-- Teleports tab
coroutine.wrap(function() 
Tabs.Teleport:Section({ Title = "Teleports", TextSize = 20 })
Tabs.Teleport:Divider()
Tabs.Teleport:Space()
Tabs.Teleport:Button({
Title = "Teleport to Random Spawnpoint",
Desc = "Teleport to a random spawn location",
Icon = "compass",
Callback = function()
local spawnLocations = {}
local function findSpawnLocations(parent)
for _, child in ipairs(parent:GetChildren()) do
if child:IsA("SpawnLocation") then
table.insert(spawnLocations, child)
end
if child:IsA("Model") or child:IsA("Folder") then
findSpawnLocations(child)
end
end
end
findSpawnLocations(workspace)
if #spawnLocations > 0 then
local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
local humanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
end
end
end
})
Tabs.Teleport:Space()
Tabs.Teleport:Button({
Title = "Teleport to Random Player",
Desc = "Teleport to a random online player",
Icon = "users",
Callback = function()
local players = Players:GetPlayers()
local validPlayers = {}
for _, plr in ipairs(players) do
if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
table.insert(validPlayers, plr)
end
end
if #validPlayers > 0 then
local randomPlayer = validPlayers[math.random(1, #validPlayers)]
local humanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
end
end
end
})
local playerList = {}
Tabs.Teleport:Space()
PlayerDropdown = Tabs.Teleport:Dropdown({
Title = "Select Player",
Flag = "PlayerDropdown",
Values = {{Title = "No players found", Desc = "", Icon = "user"}},
Value = "No players found",
Callback = function(selectedOption) end
})
local function updatePlayerList()
playerList = {}
local players = Players:GetPlayers()
local dropdownValues = {}
for i = 1, #players do
local plr = players[i]
if plr ~= LocalPlayer then
table.insert(playerList, plr)
local success, content = pcall(function()
return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
local iconUrl = success and content or "user"
table.insert(dropdownValues, {
Title = plr.DisplayName,
Desc = "@" .. plr.Name,
Icon = iconUrl
})
end
end
if #dropdownValues == 0 then
dropdownValues = {{Title = "No players found", Desc = "", Icon = "user"}}
end
PlayerDropdown:Refresh(dropdownValues, true)
end
Tabs.Teleport:Button({
Title = "Refresh Player List",
Desc = "Manually refresh the player list",
Icon = "refresh-cw",
Callback = function()
updatePlayerList()
end
})
Tabs.Teleport:Space()
Tabs.Teleport:Button({
Title = "Teleport to Selected Player",
Desc = "Teleport to the player selected in dropdown",
Icon = "user",
Callback = function()
local selectedOption = PlayerDropdown.Value
if selectedOption and selectedOption.Title ~= "No players found" then
for i = 1, #playerList do
local plr = playerList[i]
if plr.DisplayName == selectedOption.Title or plr.Name == selectedOption.Title then
if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
	local humanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
	end
end
break
end
end
end
end
})
Tabs.Teleport:Space()
Tabs.Teleport:Button({
Title = "Teleport to Random Bot",
Desc = "Teleport to a random bot in workspace.bots",
Icon = "robot",
Callback = function()
local botsFolder = workspace:FindFirstChild("bots")
local validBots = {}
if botsFolder then
local botChildren = botsFolder:GetChildren()
for i = 1, #botChildren do
local bot = botChildren[i]
if bot:IsA("Model") then
local rootPart = nil
local botParts = bot:GetChildren()
for j = 1, #botParts do
	local part = botParts[j]
	if part:IsA("BasePart") and (part.Name:lower():find("root") or part.Name:lower():find("humanoid")) then
		rootPart = part
		break
	end
end
if not rootPart then
	local botDescendants = bot:GetDescendants()
	for j = 1, #botDescendants do
		local part = botDescendants[j]
		if part:IsA("BasePart") and (part.Name:lower():find("root") or part.Name:lower():find("humanoid")) then
			rootPart = part
			break
		end
	end
end
if rootPart then
	table.insert(validBots, {bot = bot, rootPart = rootPart})
end
end
end
end
if #validBots > 0 then
local randomBot = validBots[math.random(1, #validBots)]
local humanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
if humanoidRootPart then
humanoidRootPart.CFrame = randomBot.rootPart.CFrame + Vector3.new(0, 3, 0)
end
end
end
})
end)()
-- Settings
Tabs.Settings:Section({ Title = "Config Manager", TextSize = 20 })
Tabs.Settings:Divider()
local ConfigManager = Window.ConfigManager
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local CurrentConfigName = "default"
local AutoLoadConfig = "default"
local AutoLoadEnabled = false
local AutoSaveEnabled = false
local ConfigListDropdown = nil
local AutoSaveConnection = nil
function FileExists(path)
if isfile then
return pcall(readfile, path)
end
return false
end
function WriteFile(path, content)
if writefile then
return pcall(writefile, path, content)
end
return false
end
function ReadFile(path)
if readfile then
local success, content = pcall(readfile, path)
if success then
return content
end
end
return ""
end
function loadAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Universal/AutoLoad.json"
if FileExists(autoLoadFile) then
local content = ReadFile(autoLoadFile)
if content ~= "" then
local success, data = pcall(function()
return HttpService:JSONDecode(content)
end)
if success and data then
AutoLoadConfig = data.configName or "default"
AutoLoadEnabled = data.enabled or false
return true
end
end
end
AutoLoadConfig = "default"
AutoLoadEnabled = false
return false
end
function saveAutoLoadSettings()
local autoLoadFile = "Darahub/AutoLoad/Game/Universal/AutoLoad.json"
local success = WriteFile(autoLoadFile, "")
if not success then
if makefolder then
pcall(function() makefolder("Darahub") end)
pcall(function() makefolder("Darahub/AutoLoad") end)
pcall(function() makefolder("Darahub/AutoLoad/Game") end)
pcall(function() makefolder("Darahub/AutoLoad/Game/NicoBot") end)
end
end
local data = {
enabled = AutoLoadEnabled,
configName = AutoLoadConfig
}
local success, json = pcall(function()
return HttpService:JSONEncode(data)
end)
if success then
WriteFile(autoLoadFile, json)
end
end
loadAutoLoadSettings()
ConfigNameInput = Tabs.Settings:Input({
Title = "Config Name",
Flag = "ConfigNameInput",
Desc = "Name for your config file",
Icon = "file-cog",
Placeholder = "default",
Value = CurrentConfigName,
Callback = function(value)
if value ~= "" then
CurrentConfigName = value
end
end
})
Tabs.Settings:Space()
AutoLoadToggle = Tabs.Settings:Toggle({
Title = "Auto Load",
Flag = "AutoLoadToggle",
Desc = "Automatically load this config when script starts",
Value = AutoLoadEnabled,
Callback = function(state)
AutoLoadEnabled = state
if state then
AutoLoadConfig = CurrentConfigName
WindUI:Notify({
Title = "Auto-Load",
Content = "Config '" .. CurrentConfigName .. "' will load automatically on startup",
Duration = 3
})
end
saveAutoLoadSettings()
end
})
AutoSaveToggle = Tabs.Settings:Toggle({
Title = "Auto Save",
Flag = "AutoSaveToggle",
Desc = "Automatically save changes to config every second",
Value = AutoSaveEnabled,
Callback = function(state)
AutoSaveEnabled = state
if AutoSaveConnection then
AutoSaveConnection:Disconnect()
AutoSaveConnection = nil
end
if state then
WindUI:Notify({
Title = "Auto-Save",
Content = "Config will save automatically every second",
Duration = 2
})
AutoSaveConnection = game:GetService("RunService").Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1)
end)
else
WindUI:Notify({
Title = "Auto-Save",
Content = "Auto-save disabled",
Duration = 2
})
end
end
})
Tabs.Settings:Space()
function refreshConfigList()
local allConfigs = ConfigManager:AllConfigs() or {}
if not table.find(allConfigs, "default") then
local defaultConfig = ConfigManager:Config("default")
if defaultConfig and defaultConfig.Save then
defaultConfig:Save()
end
table.insert(allConfigs, 1, "default")
end
table.sort(allConfigs, function(a, b)
return a:lower() < b:lower()
end)
local defaultValue = table.find(allConfigs, CurrentConfigName) and CurrentConfigName or "default"
if ConfigListDropdown and ConfigListDropdown.Refresh then
ConfigListDropdown:Refresh(allConfigs, defaultValue)
end
end
ConfigListDropdown = Tabs.Settings:Dropdown({
Title = "Existing Configs",
Flag = "ConfigListDropdown",
Desc = "Select from saved configs",
Values = {"default"},
Value = "default",
Callback = function(value)
CurrentConfigName = value
ConfigNameInput:Set(value)
if AutoLoadEnabled then
AutoLoadConfig = value
saveAutoLoadSettings()
end
local config = ConfigManager:GetConfig(value)
if config then
WindUI:Notify({
Title = "Config Selected",
Content = "Config '" .. value .. "' selected",
Duration = 2
})
end
end
})
Tabs.Settings:Space()
SaveConfigButton = Tabs.Settings:Button({
Title = "Save Config",
Desc = "Save current settings to config",
Icon = "save",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
local success = Window.CurrentConfig:Save()
if success then
WindUI:Notify({
Title = "Config Saved",
Content = "Config '" .. CurrentConfigName .. "' saved successfully",
Duration = 3
})
if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end
task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to save config",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
LoadConfigButton = Tabs.Settings:Button({
Title = "Load Config",
Desc = "Load settings from selected config",
Icon = "folder-open",
Callback = function()
if CurrentConfigName == "" then
WindUI:Notify({
Title = "Error",
Content = "Please enter a config name",
Duration = 3
})
return
end
Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)
local success = Window.CurrentConfig:Load()
if success then
WindUI:Notify({
Title = "Config Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded successfully",
Duration = 3
})
if AutoLoadEnabled then
AutoLoadConfig = CurrentConfigName
saveAutoLoadSettings()
end
else
WindUI:Notify({
Title = "Error",
Content = "Config '" .. CurrentConfigName .. "' not found or empty",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
DeleteConfigButton = Tabs.Settings:Button({
Title = "Delete Config",
Desc = "Delete selected config",
Icon = "trash-2",
Color = Color3.fromHex("#ff4830"),
Callback = function()
if CurrentConfigName == "default" then
WindUI:Notify({
Title = "Error",
Content = "Cannot delete default config",
Duration = 3
})
return
end
local success = ConfigManager:DeleteConfig(CurrentConfigName)
if success then
WindUI:Notify({
Title = "Config Deleted",
Content = "Config '" .. CurrentConfigName .. "' deleted",
Duration = 3
})
CurrentConfigName = "default"
ConfigNameInput:Set("default")
if AutoLoadEnabled then
AutoLoadConfig = "default"
saveAutoLoadSettings()
end
task.wait(0.5)
refreshConfigList()
else
WindUI:Notify({
Title = "Error",
Content = "Failed to delete config or config doesn't exist",
Duration = 3
})
end
end
})
Tabs.Settings:Space()
RefreshConfigButton = Tabs.Settings:Button({
Title = "Refresh Config List",
Desc = "Update the list of available configs",
Icon = "refresh-cw",
Callback = function()
refreshConfigList()
WindUI:Notify({
Title = "Config List Refreshed",
Content = "Config list updated",
Duration = 2
})
end
})
task.spawn(function()
task.wait(0.5) 
refreshConfigList()
ConfigNameInput:Set("default")
if AutoLoadEnabled then
CurrentConfigName = AutoLoadConfig
ConfigNameInput:Set(CurrentConfigName)
task.wait(1)
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
if Window.CurrentConfig:Load() then
WindUI:Notify({
Title = "Auto-Loaded",
Content = "Config '" .. CurrentConfigName .. "' loaded automatically",
Duration = 3
})
end
end
end)
if AutoSaveEnabled then
task.spawn(function()
task.wait(1)
if AutoSaveEnabled then
AutoSaveConnection = game:GetService("RunService").Heartbeat:Connect(function()
if AutoSaveEnabled and CurrentConfigName ~= "" then
task.spawn(function()
Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
Window.CurrentConfig:Save()
end)
end
task.wait(1)
end)
end
end)
end

Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
Tabs.Settings:Divider()

themes = {}

availableThemes = WindUI:GetThemes()

for themeName, _ in pairs(availableThemes) do
table.insert(themes, themeName)
end
table.sort(themes)

ThemeDropdown = Tabs.Settings:Dropdown({
Title = "Select Theme",
Flag = "ThemeDropdown",
Values = themes,
SearchBarEnabled = true,
MenuWidth = 280,
Value = themes[1],
Callback = function(theme)
WindUI:SetTheme(theme)
end
})

TransparencySlider = Tabs.Settings:Slider({
Title = "Window Transparency",
Step = 0.01,
Flag = "TransparencySlider",
Value = { Min = 0, Max = 1, Default = WindUI.TransparencyValue },
Callback = function(value)
WindUI.TransparencyValue = tonumber(value)
Window:ToggleTransparency(tonumber(value) > 0)
end
})




Tabs.Settings:Section({ Title = "Keybinds" })
Tabs.Settings:Keybind({
Flag = "Keybind",
Title = "Keybind",
Desc = "Keybind to open ui",
Value = "RightControl",
Callback = function(RightControl)
Window:SetToggleKey(Enum.KeyCode[RightControl])
end
})
Tabs.Settings:Space()
FlyTogglekeybind = Tabs.Settings:Keybind({
Title = "Bhop Toggle",
Desc = "Keybind to toggle BunnyHop",
Value = "",
Flag = "BhopTogglekeybind",
Callback = function(v)
FlyToggle:Set(not FlyToggle.Value)
end
})
Tabs.Settings:Space()
FlyTogglekeybind = Tabs.Settings:Keybind({
Title = "Fly Toggle",
Desc = "Keybind to toggle Fly",
Value = "",
Flag = "FlyTogglekeybind",
Callback = function(v)
BhopToggle:Set(not BhopToggle.Value)
end
})



do
local CoreGui = game:GetService("CoreGui")
local DarahubFolder = CoreGui:FindFirstChild("Darahub")
if DarahubFolder and Tabs and Tabs.Settings then
Tabs.Settings:Section({
Title = "GUI Size"
})
local defaultScales = {}
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
defaultScales[Element.Name] = Element.UIScale.Scale
end
end
Tabs.Settings:Button({
Title = "Reset All Scales",
Description = "Reverts all buttons to their startup scale values",
Callback = function()
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local original = defaultScales[Element.Name] or 1
Element.UIScale.Scale = original
end
end
end
})
for _, Element in pairs(DarahubFolder:GetChildren()) do
if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
local currentScale = tonumber(Element.UIScale.Scale) or 1
Tabs.Settings:Slider({
Title = Element.Name .. " Scale",
Desc = "Adjust GUI scale",
Flag = "Scale_Slider_" .. Element.Name,
Step = 0.01,
Value = {
Min = 0.01,
Max = 4,
Default = currentScale
},
Callback = function(val)
if Element and Element:FindFirstChild("UIScale") then
Element.UIScale.Scale = tonumber(val)
end
end
})
end
end
end
end
Tabs.Settings:Space()

 local FPSCounter = CoreGui:FindFirstChild("FPSCounter")

if FPSCounter then
FPSCounterToggle = Tabs.Settings:Toggle({
Title = "Show FPS Counter",
Flag = "FPSCounterToggle",
Value = true,
Callback = function(state)
if FPSCounter then
FPSCounter.Enabled = state
else
warn("Could Not Find \"FPSCounter\" in CoreGUI! Please Reload the script And try again.")
end
end
})
else
warn("No \"FPSCounter\" Found in CoreGUI")
end
Tabs.Settings:Section({ Title = "Sensitivity Controls", TextSize = 20 })
Tabs.Settings:Divider()

MouseSensitivityEnabled = false
MouseSensitivityValue = 1.0
MIN_SENSITIVITY = 0.1
MAX_SENSITIVITY = 20.0
DEFAULT_SENSITIVITY = 1.0
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false

function setupSensitivityHook()
if cameraInputModule then return true end

player = game:GetService("Players").LocalPlayer
success = false

pcall(function()
playerScripts = player:FindFirstChild("PlayerScripts")
if not playerScripts then return end
playerModule = playerScripts:FindFirstChild("PlayerModule")
if not playerModule then return end
cameraModule = playerModule:FindFirstChild("CameraModule")
if cameraModule then
cameraInput = cameraModule:FindFirstChild("CameraInput")
if cameraInput then
cameraInputModule = require(cameraInput)
if cameraInputModule and cameraInputModule.getRotation then
originalGetRotation = cameraInputModule.getRotation
cameraInputModule.getRotation = function(disableRotation)
rotation = originalGetRotation(disableRotation)
uis = game:GetService("UserInputService")
if MouseSensitivityEnabled and uis.MouseEnabled then
return rotation * MouseSensitivityValue
elseif TouchSensitivityEnabled and uis.TouchEnabled then
return rotation * TouchSensitivityValue
end
return rotation
end
success = true
end
end
end
end)

return success
end

MouseSensitivityToggle = Tabs.Settings:Toggle({
Title = "Mouse Sensitivity",
Flag = "MouseSensitivityToggle",
Desc = "Adjust mouse sensitivity",
Value = false,
Callback = function(state)
MouseSensitivityEnabled = state
if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Mouse Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
MouseSensitivityToggle:Set(false)
MouseSensitivityEnabled = false
end
end
end
})

MouseSensitivitySlider = Tabs.Settings:Slider({
Title = "Mouse Sensitivity Value",
Flag = "MouseSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
MouseSensitivityValue = value
end
})

Tabs.Settings:Space()

TouchSensitivityToggle = Tabs.Settings:Toggle({
Title = "Touch Sensitivity",
Flag = "TouchSensitivityToggle",
Desc = "Adjust touch/mobile sensitivity",
Value = false,
Callback = function(state)
TouchSensitivityEnabled = state
if state then
if not setupSensitivityHook() then
WindUI:Notify({
Title = "Touch Sensitivity",
Content = "Failed to hook system. Try rejoining.",
Duration = 3
})
TouchSensitivityToggle:Set(false)
TouchSensitivityEnabled = false
end
end
end
})

TouchSensitivitySlider = Tabs.Settings:Slider({
Title = "Touch Sensitivity Value",
Flag = "TouchSensitivitySlider",
Desc = "Lower = slower, Higher = faster (Max: 20)",
Value = { Min = 0.1, Max = 20, Default = 1.0 },
Step = 0.1,
Callback = function(value)
TouchSensitivityValue = value
end
})

Tabs.Settings:Space()

Tabs.Settings:Section({ Title = "Reset Controls", TextSize = 20 })
Tabs.Settings:Divider()

Tabs.Settings:Button({
Title = "Reset Sensitivity Settings",
Desc = "Reset both mouse and touch sensitivity to defaults",
Icon = "refresh-cw",
Color = Color3.fromHex("#FF3030"),
Callback = function()
MouseSensitivityEnabled = false
MouseSensitivityValue = DEFAULT_SENSITIVITY
TouchSensitivityEnabled = false
TouchSensitivityValue = DEFAULT_SENSITIVITY
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false
if MouseSensitivityToggle then 
MouseSensitivityToggle:Set(false) 
end
if MouseSensitivitySlider then 
MouseSensitivitySlider:Set(1.0) 
end
if TouchSensitivityToggle then 
TouchSensitivityToggle:Set(false) 
end
if TouchSensitivitySlider then 
TouchSensitivitySlider:Set(1.0) 
end
WindUI:Notify({
Title = "Sensitivity Reset",
Content = "All sensitivity settings reset to default",
Duration = 3
})
end
})
Window:SelectTab(1)
local UniverseScriptsStuff = loadstring(game:HttpGet("https://darahub.pages.dev/Module/More-Scripts.Lua"))()

UniverseScriptsStuff(Tabs)`n]],
["https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua"] = [[`n-- FAILED FETCH: https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua`n]],
["https://darahub.pages.dev/api/script/Draw-N-Slide.lua"] = [[`n-- FAILED FETCH: https://darahub.pages.dev/api/script/Draw-N-Slide.lua`n]],
["https://darahub.pages.dev/api/script/Darahub-Universal.lua"] = [[`nif getgenv().DaraHubExecuted then
    NotifyToast({
        title = "WARNING!",
        content = "Script Is Already Loaded, rejoin of you want to re-execute.",
        duration = 8,
        icon = "triangle-exclamation",
        iconColor = "#FFFF00",
    })
    return
end
getgenv().DaraHubExecuted = true

WindUI = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/WindUI-Moded/main.lua"))()
loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/LoadAll.lua"))()

Window = WindUI:CreateWindow({
    Title = "Dara Hub",
    Icon = "rbxassetid://137330250139083",
    Author = "Made By Pnsdg",
    Folder = "Darahub/Universal",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    NewElements = true,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200,
    OpenButton = {
        Enabled = false,
        Scale = 0
    },
})

WindUI.TransparencyValue = 0.7
Window:ToggleTransparency(true)
Window:DisableTopbarButtons({ "Fullscreen" })

executor = identifyexecutor()
if type(executor) == "table" then
    for key, value in pairs(executor) do
        print(key .. ": " .. tostring(value))
    end
elseif type(executor) == "string" then
    Window:Tag({
        Title = "" .. executor
    })
else
    print("The injector does not support identifyexecutor()")
end

Window:Tag({
    Title = "Unfinished Alpha"
})

Window:OnOpen(function()
    ButtonLib:OpenButton(false)
end)

Window:OnClose(function()
    ButtonLib:OpenButton(true)
end)

Window:OnDestroy(function()
    ButtonLib:DestroyScreengui()
end)

Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = Window:Tab({ Title = "Player", Icon = "user" }),
    Visuals = Window:Tab({ Title = "Visuals", Icon = "camera" }),
    ESP = Window:Tab({ Title = "ESP", Icon = "eye" }),
    Combat = Window:Tab({ Title = "Combat", Icon = "sword" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "star" }),
    Utility = Window:Tab({ Title = "Utility", Icon = "wrench" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
    Troll = Window:Tab({ Title = "Troll Shit stuffs", Icon = "rbxassetid://6862780932" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
    info = Window:Tab({ Title = "info", Icon = "info" }),
    Others = Window:Tab({ Title = "Others", Icon = "https://em-content.zobj.net/source/apple/419/pile-of-poo_1f4a9.png" })
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Character
local Humanoid
local HumanoidRootPart

local function setupCharacter(character)
    Character = character
    Humanoid = character:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)

originalGameGravity = workspace.Gravity
placeId = game.PlaceId
jobId = game.JobId

flingActive = false
hiddenfling = false
AntiFlingEnabled = false
AntiKillPartsEnabled = false
processedPlayers = {}
currentInput = ""
SteppedConnection = nil
isNoclipEnabled = false
flingMode = 1
isStrengthened = false
connections_strength = {}
originalProperties = {}
spawnpointActive = false
savedPosition = nil
needsRespawn = false
respawnConnection = nil
as = false
XenoAntiFlingEnabled = false
XenoAntiFlingConnection = nil
infinitePositionEnabled = false
savedInfinitePosition = nil
infinitePositionConnection = nil
positionTolerance = 0.1
afdEnabled = false
afdConnections = {}
noSitEnabled = false
movePart = nil
currentPos = Vector3.new()
currentYaw = 0
rotateSmooth = 0.2
joystickGui = nil
InvisSeat = nil
antiRagdollEnabled = false
antiRagdollDisconnectFunc = nil
fpdProtectionEnabled = false
fpdProtectionConnection = nil
oldNewIndex = nil
wasFlingActiveBeforeFPD = false
TPWALK = false
JumpBoost = false
FullBright = false
NoFog = false
SpeedHack = false
TpwalkValue = 1
JumpPower = 5
Speed = 16
bodyVelocity = nil
bodyGyro = nil
ToggleTpwalk = false
TpwalkConnection = nil
isJumpHeld = false
antiAFKConnection = nil

function startAntiAFK()
    if antiAFKConnection then return end
    antiAFKConnection = RunService.Heartbeat:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

function stopAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
end

function manageStrength(character, enable)
    if not character or not character:IsA("Model") then return end
    for _, conn in pairs(connections_strength) do
        conn:Disconnect()
    end
    connections_strength = {}
    if enable then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if not originalProperties[part] then
                    originalProperties[part] = part.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5)
                end
                part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                table.insert(connections_strength, part:GetPropertyChangedSignal("CustomPhysicalProperties"):Connect(function()
                    if isStrengthened then
                        local current = part.CustomPhysicalProperties
                        if not current or current.Density < 100 then
                            part.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
                        end
                    end
                end))
            end
        end
    else
        for part, props in pairs(originalProperties) do
            if part:IsA("BasePart") and part.Parent then
                part.CustomPhysicalProperties = props
            end
        end
        originalProperties = {}
    end
end

function setupSpawnpoint()
    LocalPlayer.CharacterAdded:Connect(function(character)
        if not spawnpointActive then return end
        local rootPart = character:WaitForChild("HumanoidRootPart", 1)
        if not rootPart then return end
        task.wait(0.01)
        if savedPosition then
            rootPart.CFrame = savedPosition
            needsRespawn = false
        end
    end)
    RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if spawnpointActive and humanoid and humanoid.Health <= 0 then
            if rootPart then
                savedPosition = rootPart.CFrame
                needsRespawn = true
            end
        end
    end)
end

function dobv(v, char)
    local undo = false
    if as then
        if v:IsA("BodyAngularVelocity") then
            undo = true
            v:Destroy()
        elseif v:IsA("BodyGyro") and v.MaxTorque ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.D ~= 500 and v.D ~= 50 and v.P ~= 90000 then
            undo = true
            v:Destroy()
        elseif v:IsA("BodyVelocity") and v.MaxForce ~= Vector3.new(8999999488, 8999999488, 8999999488) and v.Velocity ~= Vector3.new(0,0,0) then
            undo = true
            v:Destroy()
        elseif v:IsA("BasePart") then
            v.ChildAdded:Connect(function(v2)
                dobv(v2, char)
            end)
        end
        if undo and char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Sit = false
            char.Humanoid.PlatformStand = false
        end
    end
end

function dc(c)
    for i,v in pairs(c:GetChildren()) do
        dobv(v, c)
        for i,v in pairs(v:GetChildren()) do
            dobv(v, c)
        end
    end
    c.ChildAdded:Connect(function(v)
        dobv(v, c)
    end)
end

function toggleXenoAntiFling(state)
    XenoAntiFlingEnabled = state
    if state then
        XenoAntiFlingConnection = RunService.Stepped:Connect(function()
            pcall(function()
                local players = Players:GetPlayers()
                for _, p in pairs(players) do
                    if p ~= LocalPlayer and p.Character then
                        for _, v in pairs(p.Character:GetChildren()) do
                            pcall(function()
                                if v:IsA("BasePart") then
                                    v.CanCollide = false
                                    v.Velocity = Vector3.new(0,0,0)
                                    v.RotVelocity = Vector3.new(0,0,0)
                                    v.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
                                    v.Massless = true
                                elseif v:IsA("Accessory") then
                                    v.Handle.CanCollide = false
                                    v.Handle.Velocity = Vector3.new(0,0,0)
                                    v.Handle.RotVelocity = Vector3.new(0,0,0)
                                    v.Handle.CustomPhysicalProperties = PhysicalProperties.new(0,0,0,0,0)
                                    v.Handle.Massless = true
                                end
                            end)
                        end
                    end
                end
            end)
        end)
    else
        if XenoAntiFlingConnection then
            XenoAntiFlingConnection:Disconnect()
            XenoAntiFlingConnection = nil
        end
    end
end

function handleRespawn()
    if not infinitePositionEnabled or not savedInfinitePosition then return end
    local rootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 1)
    if rootPart then
        task.wait(0.0001)
        rootPart.CFrame = savedInfinitePosition
        rootPart.Velocity = Vector3.new()
        rootPart.RotVelocity = Vector3.new()
    end
end

function checkPosition()
    if not infinitePositionEnabled or not savedInfinitePosition then return end
    if flingActive then return end
    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    if (rootPart.Position - savedInfinitePosition.Position).Magnitude > positionTolerance then
        task.wait(0.0001)
        if infinitePositionEnabled and not flingActive and character.Parent and rootPart then
            if (rootPart.Position - savedInfinitePosition.Position).Magnitude > positionTolerance then
                rootPart.CFrame = savedInfinitePosition
                rootPart.Velocity = Vector3.new()
                rootPart.RotVelocity = Vector3.new()
            end
        end
    end
end

function setupInfinitePosition()
    LocalPlayer.CharacterAdded:Connect(handleRespawn)
    if infinitePositionConnection then
        infinitePositionConnection:Disconnect()
    end
    infinitePositionConnection = RunService.Heartbeat:Connect(function()
        if not infinitePositionEnabled then return end
        checkPosition()
    end)
end

function toggleAFD(state)
    afdEnabled = state
    if state then
        function setupAFD(character)
            if not character then return end
            local rootPart = character:WaitForChild("HumanoidRootPart", 1)
            if not rootPart then return end
            local connection = RunService.Heartbeat:Connect(function()
                if not rootPart.Parent then
                    connection:Disconnect()
                    return
                end
                local velocity = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.zero
                RunService.RenderStepped:Wait()
                rootPart.AssemblyLinearVelocity = velocity
            end)
            table.insert(afdConnections, connection)
        end
        if LocalPlayer.Character then
            setupAFD(LocalPlayer.Character)
        end
        table.insert(afdConnections, LocalPlayer.CharacterAdded:Connect(setupAFD))
    else
        for _, conn in ipairs(afdConnections) do
            if conn then
                conn:Disconnect()
            end
        end
        afdConnections = {}
    end
end

function toggleNoSit(state)
    noSitEnabled = state
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if state then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                if humanoid.Sit then
                    humanoid.Sit = false
                end
                humanoid.Sit = true
            else
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
                humanoid.Sit = false
            end
        end
    end
end

function createAntiRagdoll(character)
    local connections = {}
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.PlatformStand = false
    function onStateChanged(_, newState)
        if newState == Enum.HumanoidStateType.Physics or 
           newState == Enum.HumanoidStateType.FallingDown or 
           newState == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    function onPlatformStandChanged()
        if humanoid.PlatformStand then
            humanoid.PlatformStand = false
        end
    end
    table.insert(connections, humanoid.StateChanged:Connect(onStateChanged))
    table.insert(connections, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(onPlatformStandChanged))
    return function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end
end

function toggleNoclip(state)
    isNoclipEnabled = state
    if state then
        if SteppedConnection then return end
        SteppedConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if SteppedConnection then
            SteppedConnection:Disconnect()
            SteppedConnection = nil
            local character = LocalPlayer.Character
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end
        end
    end
end

function setCanCollideOfModelDescendants(model, bval)
    if not model then
        return
    end
    for i, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = bval
        end
    end
end

function toggleAntiKillParts(state)
    AntiKillPartsEnabled = state
    if state then
        coroutine.wrap(function()
            while AntiKillPartsEnabled and task.wait() do
                if LocalPlayer.Character then
                    local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if humanoidRootPart then
                        local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 10)
                        for _, part in ipairs(parts) do
                            part.CanTouch = false
                        end
                    end
                end
            end
        end)()
    else
        if LocalPlayer.Character then
            local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                local parts = workspace:GetPartBoundsInRadius(humanoidRootPart.Position, 15000)
                for _, part in ipairs(parts) do
                    part.CanTouch = true
                end
            end
        end
    end
end

function toggleAntiFling(state)
    AntiFlingEnabled = state
    if state then
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, false)
            end
        end
    else
        for i, v in pairs(Players:GetPlayers()) do
            if v ~= LocalPlayer and v.Character then
                setCanCollideOfModelDescendants(v.Character, true)
            end
        end
    end
end

function fling()
    local lp = LocalPlayer
    local c, hrp, vel, movel = nil, nil, nil, 0.1
    while hiddenfling do
        RunService.Heartbeat:Wait()
        c = lp.Character
        hrp = c and c:FindFirstChild("HumanoidRootPart")
        if hrp then
            vel = hrp.Velocity
            hrp.Velocity = vel * 1e35 + Vector3.new(0, 1e35, 0)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
            RunService.Stepped:Wait()
            hrp.Velocity = vel + Vector3.new(0, movel, 0)
            movel = -movel
        end
    end
end

function sortPlayersAlphabetically(players)
    table.sort(players, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return players
end

function SkidFling(TargetPlayer, duration)
    local startTime = tick()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

function toggleFPDProtection(state)
    fpdProtectionEnabled = state
    if state then
        local mt = getrawmetatable(workspace)
        oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = function(t, k, v)
            if k == "FallenPartsDestroyHeight" then
                rawset(t, k, 0/0)
                return
            end
            oldNewIndex(t, k, v)
        end
        setreadonly(mt, true)
        if fpdProtectionConnection then fpdProtectionConnection:Disconnect() end
        fpdProtectionConnection = RunService.Heartbeat:Connect(function()
            if workspace.FallenPartsDestroyHeight == workspace.FallenPartsDestroyHeight then
                workspace.FallenPartsDestroyHeight = 0/0
            end
        end)
        wasFlingActiveBeforeFPD = flingActive
        if flingActive then
            toggleFling(false)
        end
    else
        if fpdProtectionConnection then
            fpdProtectionConnection:Disconnect()
            fpdProtectionConnection = nil
        end
        if oldNewIndex then
            local mt = getrawmetatable(workspace)
            setreadonly(mt, false)
            mt.__newindex = oldNewIndex
            setreadonly(mt, true)
        end
        if wasFlingActiveBeforeFPD and not flingActive then
            toggleFling(true)
        end
    end
end

function enableAntiKick()
    if not hookmetamethod then 
        warn("Your exploit does not support this anti-kick (missing hookmetamethod)")
        return false
    end
    if hookfunction and LocalPlayer.Kick then
        oldKickFunction = hookfunction(LocalPlayer.Kick, function() end)
    end
    oldhmmi = hookmetamethod(game, "__index", function(self, method)
        if self == LocalPlayer and method:lower() == "kick" then
            return error("Expected ':' not '.' calling member function Kick", 2)
        end
        return oldhmmi(self, method)
    end)
    oldhmmnc = hookmetamethod(game, "__namecall", function(self, ...)
        if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
            return nil
        end
        return oldhmmnc(self, ...)
    end)
    return true
end

socialsModule = loadstring(game:HttpGet("https://darahub.pages.dev/Module/info.lua"))()
socialsModule(Tabs)

local UniverseServerTools = loadstring(game:HttpGet("https://darahub.pages.dev/Module/UniverseServerTools.lua"))()
UniverseServerTools(Tabs)

Tabs.Main:Button({
    Title = "Anti Kick",
    Callback = function()
        enableAntiKick()
    end
})

Tabs.Player:Section({ Title = "Player", TextSize = 20 })
Tabs.Player:Divider()

function onCharacterAdded(newCharacter)
    setupCharacter(newCharacter)
    if JumpBoost and Humanoid then
        Humanoid.JumpPower = JumpPower
        Humanoid.JumpHeight = JumpPower
    end
    if SpeedHack and Humanoid then
        Humanoid.WalkSpeed = Speed
    end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

local InfiniteJump = {
    State = nil,
    Connection = nil,
    Enabled = false
}

local function StartInfiniteJump()
    if InfiniteJump.Enabled then return end
    InfiniteJump.Enabled = true
    InfiniteJump.Connection = RunService.RenderStepped:Connect(function()
        if not InfiniteJump.Enabled then return end
        if not Humanoid then
            if LocalPlayer.Character then
                Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            end
            if not Humanoid then return end
        end
        if Humanoid.Jump then
            if InfiniteJump.State then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                InfiniteJump.State = false
            end
        else
            InfiniteJump.State = true
        end
    end)
end

local function StopInfiniteJump()
    InfiniteJump.Enabled = false
    if InfiniteJump.Connection then
        InfiniteJump.Connection:Disconnect()
        InfiniteJump.Connection = nil
    end
    InfiniteJump.State = nil
end


InfiniteJumpToggle = Tabs.Player:Toggle({
    Title = "Infinite Jump",
    Flag = "InfiniteJumpToggle",
    Value = false,
    Callback = function(state)
        if state then
        StartInfiniteJump()
        else
        StopInfiniteJump()
        end
    end
})

Tabs.Player:Space()

NoclipToggle = Tabs.Player:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(state)
        toggleNoclip(state)
    end
})

Tabs.Player:Space()

SpeedHackToggle = Tabs.Player:Toggle({
    Title = "SPEED HACK",
    Value = false,
    Callback = function(state)
        SpeedHack = state
        if state and Character and Humanoid then
            Humanoid.WalkSpeed = Speed
        else
            if Character and Humanoid then
                Humanoid.WalkSpeed = 16
            end
        end
    end
})

SpeedSlider = Tabs.Player:Slider({
    Title = "Speed Value",
    Value = { Min = 16, Max = 500, Default = 16 },
    Callback = function(value)
        Speed = value
        if SpeedHack and Character and Humanoid then
            Humanoid.WalkSpeed = value
        end
    end
})

SpeedGlitchMode = "Air Acceleration"
SpeedGlitchEnabled = false
SpeedGlitchSpeed = 50

local speedGlitchCurrentSpeed = 0
local speedGlitchWasMoving = false
local speedGlitchConnection = nil
local wasOnGround = false
local realisticHolder = nil
local currentCharacter = nil
local currentRoot = nil
local currentHumanoid = nil

function applyAirAccelerationGlitch(character, humanoid, rootPart)
    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        speedGlitchCurrentSpeed = speedGlitchCurrentSpeed + (SpeedGlitchSpeed * 0.1)
        local velocity = moveDir * speedGlitchCurrentSpeed
        rootPart.Velocity = Vector3.new(velocity.X, rootPart.Velocity.Y, velocity.Z)
        speedGlitchWasMoving = true
    else
        speedGlitchWasMoving = false
    end
end

function recreateRealisticHolder(character, rootPart)
    if realisticHolder then
        realisticHolder:Destroy()
        realisticHolder = nil
    end
    if not character or not rootPart then return end
    local ws = SpeedGlitchSpeed
    local holder = Instance.new("Part")
    holder.Size = Vector3.new(2, 2, 2)
    holder.Anchored = false
    holder.CanCollide = false
    holder.Transparency = 1
    holder.CFrame = rootPart.CFrame * CFrame.new(10 + (ws * 0.5), 10, -ws)
    holder.Name = "PhysicHolder"
    holder.Parent = character
    local ActualWeld = Instance.new("WeldConstraint")
    ActualWeld.Part0 = rootPart
    ActualWeld.Part1 = holder
    ActualWeld.Parent = rootPart
    realisticHolder = holder
end

function applyRealisticGlitch(character, humanoid, rootPart)
    if not character or not rootPart then return end
    if not realisticHolder or not realisticHolder.Parent or realisticHolder.Parent ~= character then
        recreateRealisticHolder(character, rootPart)
    end
end

function startSpeedGlitch(character, humanoid, rootPart)
    if not character or not humanoid or not rootPart then return end
    currentCharacter = character
    currentRoot = rootPart
    currentHumanoid = humanoid
    if speedGlitchConnection then
        speedGlitchConnection:Disconnect()
        speedGlitchConnection = nil
    end
    speedGlitchConnection = RunService.Heartbeat:Connect(function()
        if SpeedGlitchEnabled and currentHumanoid and currentHumanoid.Parent then
            local isOnGround = currentHumanoid.FloorMaterial ~= Enum.Material.Air
            local isMoving = currentHumanoid.MoveDirection.Magnitude > 0
            if isOnGround and wasOnGround and not isMoving then
                speedGlitchCurrentSpeed = 0
                speedGlitchWasMoving = false
                if currentRoot then
                    local currentVel = currentRoot.Velocity
                    currentRoot.Velocity = Vector3.new(currentVel.X * 0.95, currentVel.Y, currentVel.Z * 0.95)
                end
            end
            wasOnGround = isOnGround
            if currentHumanoid.FloorMaterial == Enum.Material.Air and currentHumanoid:GetState() ~= Enum.HumanoidStateType.Climbing and currentHumanoid:GetState() ~= Enum.HumanoidStateType.Swimming and currentHumanoid:GetState() ~= Enum.HumanoidStateType.Seated and currentHumanoid:GetState() ~= Enum.HumanoidStateType.PlatformStanding then
                if SpeedGlitchMode == "Air Acceleration" then
                    applyAirAccelerationGlitch(currentCharacter, currentHumanoid, currentRoot)
                elseif SpeedGlitchMode == "Realistic" then
                    applyRealisticGlitch(currentCharacter, currentHumanoid, currentRoot)
                end
            end
        end
    end)
end

function stopSpeedGlitch()
    if speedGlitchConnection then
        speedGlitchConnection:Disconnect()
        speedGlitchConnection = nil
    end
    speedGlitchCurrentSpeed = 0
    speedGlitchWasMoving = false
    wasOnGround = false
    if realisticHolder then
        realisticHolder:Destroy()
        realisticHolder = nil
    end
end

function updateSpeedValue()
    if SpeedGlitchEnabled and SpeedGlitchMode == "Realistic" and currentCharacter and currentRoot then
        recreateRealisticHolder(currentCharacter, currentRoot)
    end
end

function onCharacterAdded(character)
    task.wait(0.5)
    if SpeedGlitchEnabled then
        speedGlitchCurrentSpeed = 0
        local hum = character:FindFirstChildOfClass("Humanoid")
        local root = character:FindFirstChild("HumanoidRootPart")
        if hum and root then
            stopSpeedGlitch()
            startSpeedGlitch(character, hum, root)
        end
    end
end

function onCharacterRemoving()
    stopSpeedGlitch()
    currentCharacter = nil
    currentRoot = nil
    currentHumanoid = nil
end

Tabs.Player:Space()
Tabs.Player:Divider()
Tabs.Player:Section({ Title = "Speed Glitch (InDev)", TextSize = 20 })
Tabs.Player:Divider()

SpeedGlitchToggle = Tabs.Player:Toggle({
    Title = "Speed Glitch",
    Flag = "SpeedGlitchToggle",
    Value = false,
    Callback = function(state)
        SpeedGlitchEnabled = state
        if state then
            speedGlitchCurrentSpeed = 0
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root then
                    startSpeedGlitch(char, hum, root)
                end
            end
            if ButtonLib and ButtonLib.SpeedGlitch then
                ButtonLib.SpeedGlitch:Set(true)
            end
        else
            stopSpeedGlitch()
            if ButtonLib and ButtonLib.SpeedGlitch then
                ButtonLib.SpeedGlitch:Set(false)
            end
        end
    end
})

SpeedGlitchModeDropdown = Tabs.Player:Dropdown({
    Title = "Speed Glitch Mode",
    Flag = "SpeedGlitchModeDropdown",
    Values = {"Air Acceleration", "Realistic"},
    Value = "Air Acceleration",
    Callback = function(value)
        SpeedGlitchMode = value
        if SpeedGlitchEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum and root then
                    stopSpeedGlitch()
                    startSpeedGlitch(char, hum, root)
                end
            end
        end
        if SpeedGlitchMode == "Realistic" and SpeedGlitchEnabled then
            updateSpeedValue()
        end
    end
})

SpeedGlitchSpeedInput = Tabs.Player:Input({
    Title = "Speed Value",
    Flag = "SpeedGlitchSpeedInput",
    Placeholder = "50",
    Value = "50",
    NumbersOnly = true,
    Callback = function(value)
        local num = tonumber(value)
        if num and num > 0 then
            SpeedGlitchSpeed = num
            updateSpeedValue()
        end
    end
})

ButtonLib.Create:Toggle({
    Text = "Speed Glitch",
    Flag = "SpeedGlitch",
    Default = false,
    Visible = false,
    Callback = function(s)
        if SpeedGlitchToggle then
            SpeedGlitchToggle:Set(s)
        end
    end
}).Position = UDim2.new(0.5, -125, 0.35, 0)

ShowSpeedGlitchButtonToggle = Tabs.Player:Toggle({
    Title = "Show Speed Glitch Button",
    Flag = "ShowSpeedGlitchButtonToggle",
    Value = false,
    Callback = function(state)
        if ButtonLib and ButtonLib.SpeedGlitch then
            ButtonLib.SpeedGlitch:SetVisible(state)
        end
    end
})

if LocalPlayer.Character then
    onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)

IsOnMobile = false
xpcall(function()
    IsOnMobile = table.find({Enum.Platform.Android, Enum.Platform.IOS}, UserInputService:GetPlatform()) ~= nil
end, function()
    IsOnMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end)

if IsOnMobile then
    LocalPlayer:WaitForChild("PlayerGui")
    touchGui = PlayerGui:WaitForChild("TouchGui")
    touchControlFrame = touchGui:WaitForChild("TouchControlFrame")
    originalJumpButton = touchControlFrame:FindFirstChild("JumpButton")
    if originalJumpButton then
        DownWardJumpBtn = nil
        function createDownwardButton()
            if DownWardJumpBtn and DownWardJumpBtn.Parent then
                DownWardJumpBtn:Destroy()
            end
            DownWardJumpBtn = Instance.new("ImageButton")
            DownWardJumpBtn.Name = "DownWardJumpBtn"
            DownWardJumpBtn.Size = originalJumpButton.Size
            DownWardJumpBtn.Image = originalJumpButton.Image
            DownWardJumpBtn.ImageRectOffset = originalJumpButton.ImageRectOffset
            DownWardJumpBtn.ImageRectSize = originalJumpButton.ImageRectSize
            DownWardJumpBtn.BackgroundTransparency = 1
            DownWardJumpBtn.AnchorPoint = Vector2.new(1, 0)
            DownWardJumpBtn.AutoButtonColor = false
            DownWardJumpBtn.Position = UDim2.new(1, 0, originalJumpButton.Position.Y.Scale, originalJumpButton.Position.Y.Offset)
            DownWardJumpBtn.Rotation = 180
            originalRectOffset = originalJumpButton.ImageRectOffset
            isHoldingDown = false
            DownWardJumpBtn.MouseButton1Down:Connect(function()
                isHoldingDown = true
                DownWardJumpBtn.ImageRectOffset = Vector2.new(146, 146)
                if FLYING or VFLYING then
                    flyDownPressed = true
                end
            end)
            DownWardJumpBtn.MouseButton1Up:Connect(function()
                if isHoldingDown then
                    isHoldingDown = false
                    DownWardJumpBtn.ImageRectOffset = originalRectOffset
                    flyDownPressed = false
                end
            end)
            DownWardJumpBtn.MouseLeave:Connect(function()
                if isHoldingDown then
                    isHoldingDown = false
                    DownWardJumpBtn.ImageRectOffset = originalRectOffset
                    flyDownPressed = false
                end
            end)
            DownWardJumpBtn.Parent = touchControlFrame
            function preventOverlap()
                if not DownWardJumpBtn or not DownWardJumpBtn.Parent then return end
                buttonWidth = DownWardJumpBtn.AbsoluteSize.X
                originalButton = touchControlFrame:FindFirstChild("JumpButton")
                if originalButton then
                    originalRightEdge = originalButton.AbsolutePosition.X + originalButton.AbsoluteSize.X
                    duplicateLeftEdge = DownWardJumpBtn.AbsolutePosition.X
                    distance = duplicateLeftEdge - originalRightEdge
                    if distance < 1 then
                        neededOffset = 1 - distance
                        newXOffset = DownWardJumpBtn.Position.X.Offset - neededOffset
                        DownWardJumpBtn.Position = UDim2.new(1, newXOffset, DownWardJumpBtn.Position.Y.Scale, DownWardJumpBtn.Position.Y.Offset)
                    elseif distance > 1 then
                        neededOffset = distance - 1
                        newXOffset = DownWardJumpBtn.Position.X.Offset + neededOffset
                        DownWardJumpBtn.Position = UDim2.new(1, newXOffset, DownWardJumpBtn.Position.Y.Scale, DownWardJumpBtn.Position.Y.Offset)
                    end
                end
            end
            DownWardJumpBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(preventOverlap)
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(preventOverlap)
            preventOverlap()
        end
        isHoldingJump = false
        originalJumpRectOffset = originalJumpButton.ImageRectOffset
        originalJumpButton.MouseButton1Down:Connect(function()
            isHoldingJump = true
            originalJumpButton.ImageRectOffset = Vector2.new(146, 146)
            if FLYING or VFLYING then
                flyUpPressed = true
            end
        end)
        originalJumpButton.MouseButton1Up:Connect(function()
            if isHoldingJump then
                isHoldingJump = false
                originalJumpButton.ImageRectOffset = originalJumpRectOffset
                flyUpPressed = false
            end
        end)
        originalJumpButton.MouseLeave:Connect(function()
            if isHoldingJump then
                isHoldingJump = false
                originalJumpButton.ImageRectOffset = originalJumpRectOffset
                flyUpPressed = false
            end
        end)
    else
        DownWardJumpBtn = nil
    end
end

FLYING = false
flyspeed = 5
flyQEfly = false
flyKeyDown = nil
flyKeyUp = nil
VFLYING = false
vflyspeed = 5
vflyQEfly = false
vflyKeyDown = nil
vflyKeyUp = nil
flyVelocityHandlerName = "FlyVelocity_" .. math.random(1000, 9999)
flyGyroHandlerName = "FlyGyro_" .. math.random(1000, 9999)
mfly1 = nil
mfly2 = nil
vflyVelocityHandlerName = "VFlyVelocity_" .. math.random(1000, 9999)
vflyGyroHandlerName = "VFlyGyro_" .. math.random(1000, 9999)
vmfly1 = nil
vmfly2 = nil
flyUpPressed = false
flyDownPressed = false

function getRoot(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
end

function unmobilefly(speaker)
    pcall(function()
        FLYING = false
        flyUpPressed = false
        flyDownPressed = false
        root = getRoot(speaker.Character)
        if root then
            bv = root:FindFirstChild(flyVelocityHandlerName)
            bg = root:FindFirstChild(flyGyroHandlerName)
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
            speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
        end
        if mfly1 then mfly1:Disconnect() mfly1 = nil end
        if mfly2 then mfly2:Disconnect() mfly2 = nil end
        if DownWardJumpBtn and DownWardJumpBtn.Parent then
            DownWardJumpBtn:Destroy()
            DownWardJumpBtn = nil
        end
    end)
end

function mobilefly(speaker)
    unmobilefly(speaker)
    FLYING = true
    if originalJumpButton then
        createDownwardButton()
    end
    root = getRoot(speaker.Character)
    if not root then return end
    camera = workspace.CurrentCamera
    v3none = Vector3.new()
    v3zero = Vector3.new(0, 0, 0)
    v3inf = Vector3.new(9e9, 9e9, 9e9)
    controlModule = nil
    pcall(function()
        controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    end)
    bv = Instance.new("BodyVelocity")
    bv.Name = flyVelocityHandlerName
    bv.Parent = root
    bv.MaxForce = v3zero
    bv.Velocity = v3zero
    bg = Instance.new("BodyGyro")
    bg.Name = flyGyroHandlerName
    bg.Parent = root
    bg.MaxTorque = v3inf
    bg.P = 1000
    bg.D = 50
    mfly1 = speaker.CharacterAdded:Connect(function()
        task.wait(1)
        newRoot = getRoot(speaker.Character)
        if not newRoot then return end
        newBv = Instance.new("BodyVelocity")
        newBv.Name = flyVelocityHandlerName
        newBv.Parent = newRoot
        newBv.MaxForce = v3zero
        newBv.Velocity = v3zero
        newBg = Instance.new("BodyGyro")
        newBg.Name = flyGyroHandlerName
        newBg.Parent = newRoot
        newBg.MaxTorque = v3inf
        newBg.P = 1000
        newBg.D = 50
    end)
    mfly2 = RunService.RenderStepped:Connect(function()
        currentRoot = getRoot(speaker.Character)
        currentCamera = workspace.CurrentCamera
        currentHumanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
        if currentHumanoid and currentRoot and currentRoot:FindFirstChild(flyVelocityHandlerName) and currentRoot:FindFirstChild(flyGyroHandlerName) then
            VelocityHandler = currentRoot:FindFirstChild(flyVelocityHandlerName)
            GyroHandler = currentRoot:FindFirstChild(flyGyroHandlerName)
            VelocityHandler.MaxForce = v3inf
            GyroHandler.MaxTorque = v3inf
            currentHumanoid.PlatformStand = true
            GyroHandler.CFrame = currentCamera.CoordinateFrame
            VelocityHandler.Velocity = v3none
            if flyUpPressed then
                VelocityHandler.Velocity = VelocityHandler.Velocity + Vector3.new(0, flyspeed * 50, 0)
            end
            if flyDownPressed then
                VelocityHandler.Velocity = VelocityHandler.Velocity - Vector3.new(0, flyspeed * 50, 0)
            end
            if controlModule then
                direction = controlModule:GetMoveVector()
                speed = flyspeed * 50
                if direction.X > 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + currentCamera.CFrame.RightVector * (direction.X * speed)
                end
                if direction.X < 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + currentCamera.CFrame.RightVector * (direction.X * speed)
                end
                if direction.Z > 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - currentCamera.CFrame.LookVector * (direction.Z * speed)
                end
                if direction.Z < 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - currentCamera.CFrame.LookVector * (direction.Z * speed)
                end
            end
        end
    end)
end

function pcfly()
    local plr = LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
        humanoid = char:FindFirstChildOfClass("Humanoid")
    end
    if flyKeyDown or flyKeyUp then
        flyKeyDown:Disconnect()
        flyKeyUp:Disconnect()
    end
    T = getRoot(char)
    if not T then return end
    CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    SPEED = 0
    function FLY()
        FLYING = true
        BG = Instance.new('BodyGyro')
        BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            repeat task.wait()
                camera = workspace.CurrentCamera
                humanoid.PlatformStand = true
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                else
                    BV.Velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = camera.CFrame
            until not FLYING
            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
            if humanoid then humanoid.PlatformStand = false end
        end)
    end
    flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = flyspeed
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = -flyspeed
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = -flyspeed
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = flyspeed
        elseif input.KeyCode == Enum.KeyCode.E and flyQEfly then
            CONTROL.Q = flyspeed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and flyQEfly then
            CONTROL.E = -flyspeed * 2
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    end)
    flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then
            CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then
            CONTROL.E = 0
        end
    end)
    FLY()
end

function NOFLY()
    FLYING = false
    flyUpPressed = false
    flyDownPressed = false
    if flyKeyDown then 
        flyKeyDown:Disconnect() 
        flyKeyUp:Disconnect() 
    end
    if IsOnMobile then
        unmobilefly(LocalPlayer)
    else
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
            LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
        end
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

function unmobilevfly(speaker)
    pcall(function()
        VFLYING = false
        flyUpPressed = false
        flyDownPressed = false
        root = getRoot(speaker.Character)
        if root then
            bv = root:FindFirstChild(vflyVelocityHandlerName)
            bg = root:FindFirstChild(vflyGyroHandlerName)
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        if speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid") then
            speaker.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
        end
        if vmfly1 then vmfly1:Disconnect() vmfly1 = nil end
        if vmfly2 then vmfly2:Disconnect() vmfly2 = nil end
        if DownWardJumpBtn and DownWardJumpBtn.Parent then
            DownWardJumpBtn:Destroy()
            DownWardJumpBtn = nil
        end
    end)
end

function mobilevfly(speaker)
    unmobilevfly(speaker)
    VFLYING = true
    if originalJumpButton then
        createDownwardButton()
    end
    root = getRoot(speaker.Character)
    if not root then return end
    camera = workspace.CurrentCamera
    v3none = Vector3.new()
    v3zero = Vector3.new(0, 0, 0)
    v3inf = Vector3.new(9e9, 9e9, 9e9)
    controlModule = nil
    pcall(function()
        controlModule = require(speaker.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
    end)
    bv = Instance.new("BodyVelocity")
    bv.Name = vflyVelocityHandlerName
    bv.Parent = root
    bv.MaxForce = v3zero
    bv.Velocity = v3zero
    bg = Instance.new("BodyGyro")
    bg.Name = vflyGyroHandlerName
    bg.Parent = root
    bg.MaxTorque = v3inf
    bg.P = 1000
    bg.D = 50
    vmfly1 = speaker.CharacterAdded:Connect(function()
        task.wait(1)
        newRoot = getRoot(speaker.Character)
        if not newRoot then return end
        newBv = Instance.new("BodyVelocity")
        newBv.Name = vflyVelocityHandlerName
        newBv.Parent = newRoot
        newBv.MaxForce = v3zero
        newBv.Velocity = v3zero
        newBg = Instance.new("BodyGyro")
        newBg.Name = vflyGyroHandlerName
        newBg.Parent = newRoot
        newBg.MaxTorque = v3inf
        newBg.P = 1000
        newBg.D = 50
    end)
    vmfly2 = RunService.RenderStepped:Connect(function()
        currentRoot = getRoot(speaker.Character)
        currentCamera = workspace.CurrentCamera
        currentHumanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
        if currentHumanoid and currentRoot and currentRoot:FindFirstChild(vflyVelocityHandlerName) and currentRoot:FindFirstChild(vflyGyroHandlerName) then
            VelocityHandler = currentRoot:FindFirstChild(vflyVelocityHandlerName)
            GyroHandler = currentRoot:FindFirstChild(vflyGyroHandlerName)
            VelocityHandler.MaxForce = v3inf
            GyroHandler.MaxTorque = v3inf
            GyroHandler.CFrame = currentCamera.CoordinateFrame
            VelocityHandler.Velocity = v3none
            if flyUpPressed then
                VelocityHandler.Velocity = VelocityHandler.Velocity + Vector3.new(0, vflyspeed * 50, 0)
            end
            if flyDownPressed then
                VelocityHandler.Velocity = VelocityHandler.Velocity - Vector3.new(0, vflyspeed * 50, 0)
            end
            if controlModule then
                direction = controlModule:GetMoveVector()
                speed = vflyspeed * 50
                if direction.X > 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + currentCamera.CFrame.RightVector * (direction.X * speed)
                end
                if direction.X < 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity + currentCamera.CFrame.RightVector * (direction.X * speed)
                end
                if direction.Z > 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - currentCamera.CFrame.LookVector * (direction.Z * speed)
                end
                if direction.Z < 0 then
                    VelocityHandler.Velocity = VelocityHandler.Velocity - currentCamera.CFrame.LookVector * (direction.Z * speed)
                end
            end
        end
    end)
end

function pcvfly()
    local plr = LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        repeat task.wait() until char:FindFirstChildOfClass("Humanoid")
        humanoid = char:FindFirstChildOfClass("Humanoid")
    end
    if vflyKeyDown or vflyKeyUp then
        vflyKeyDown:Disconnect()
        vflyKeyUp:Disconnect()
    end
    T = getRoot(char)
    if not T then return end
    CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
    SPEED = 0
    function FLY()
        VFLYING = true
        BG = Instance.new('BodyGyro')
        BV = Instance.new('BodyVelocity')
        BG.P = 9e4
        BG.Parent = T
        BV.Parent = T
        BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.CFrame = T.CFrame
        BV.Velocity = Vector3.new(0, 0, 0)
        BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        task.spawn(function()
            repeat task.wait()
                camera = workspace.CurrentCamera
                if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
                    SPEED = 50
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
                    SPEED = 0
                end
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
                    BV.Velocity = ((camera.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - camera.CFrame.p)) * SPEED
                else
                    BV.Velocity = Vector3.new(0, 0, 0)
                end
                BG.CFrame = camera.CFrame
            until not VFLYING
            CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
            SPEED = 0
            BG:Destroy()
            BV:Destroy()
        end)
    end
    vflyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = vflyspeed
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = -vflyspeed
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = -vflyspeed
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = vflyspeed
        elseif input.KeyCode == Enum.KeyCode.E and vflyQEfly then
            CONTROL.Q = vflyspeed * 2
        elseif input.KeyCode == Enum.KeyCode.Q and vflyQEfly then
            CONTROL.E = -vflyspeed * 2
        end
        pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
    end)
    vflyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.W then
            CONTROL.F = 0
        elseif input.KeyCode == Enum.KeyCode.S then
            CONTROL.B = 0
        elseif input.KeyCode == Enum.KeyCode.A then
            CONTROL.L = 0
        elseif input.KeyCode == Enum.KeyCode.D then
            CONTROL.R = 0
        elseif input.KeyCode == Enum.KeyCode.E then
            CONTROL.Q = 0
        elseif input.KeyCode == Enum.KeyCode.Q then
            CONTROL.E = 0
        end
    end)
    FLY()
end

function NOVFLY()
    VFLYING = false
    flyUpPressed = false
    flyDownPressed = false
    if vflyKeyDown or vflyKeyUp then 
        vflyKeyDown:Disconnect() 
        vflyKeyUp:Disconnect() 
    end
    if IsOnMobile then
        unmobilevfly(LocalPlayer)
    end
    pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

LocalPlayer.CharacterAdded:Connect(function()
    NOFLY()
    NOVFLY()
    FLYING = false
    VFLYING = false
end)

Tabs.Player:Space()

FlyToggle = Tabs.Player:Toggle({
    Title = "Fly",
    Flag = "FlyToggle",
    Value = false,
    Callback = function(state)
        if state then
            if VFLYING then VehicleFlyToggle:Set(false) end
            if IsOnMobile then
                mobilefly(LocalPlayer)
            else
                pcfly()
            end
        else
            NOFLY()
        end
    end
})

ShowFlyButtonToggle = Tabs.Player:Toggle({
    Title = "Fly Button",
    Flag = "ShowFlyButton",
    Value = false,
    Callback = function(state)
        IY = IY or {}
        IY.FlightBtn = state
        if ButtonLib and ButtonLib.Flight then
            ButtonLib.Flight:SetVisible(state)
        end
    end
})

ButtonLib.Create:Toggle({
    Text = "Flight",
    Flag = "Flight",
    Default = false,
    Visible = false,
    Callback = function(s) 
        if FlyToggle then
            FlyToggle:Set(s)
        end
    end
}).Position = UDim2.new(0.5, -125, 0.4, 0)

Tabs.Settings:Space()

FlySpeedInput = Tabs.Player:Input({
    Title = "Fly Speed",
    Flag = "FlySpeedInput",
    Placeholder = "Enter speed value",
    Value = tostring(flyspeed),
    NumbersOnly = true,
    Callback = function(value)
        speed = tonumber(value)
        if speed and speed > 0 then
            flyspeed = speed
        end
    end
})

FlyQEflyToggle = Tabs.Player:Toggle({
    Title = "Q/E Vertical Fly",
    Flag = "FlyQEflyToggle",
    Value = flyQEfly,
    Callback = function(state)
        flyQEfly = state
    end
})

Tabs.Player:Space()

VehicleFlyToggle = Tabs.Player:Toggle({
    Title = "Vehicle Fly",
    Flag = "VehicleFlyToggle",
    Value = false,
    Callback = function(state)
        if state then
            if FLYING then FlyToggle:Set(false) end
            if IsOnMobile then
                mobilevfly(LocalPlayer)
            else
                pcvfly()
            end
        else
            NOVFLY()
        end
    end
})

ShowVFlyButtonToggle = Tabs.Player:Toggle({
    Title = "Vehicle Fly Button",
    Flag = "ShowVFlyButton",
    Value = false,
    Callback = function(state)
        IY = IY or {}
        IY.VFlightBtn = state
        if ButtonLib and ButtonLib.VFlight then
            ButtonLib.VFlight:SetVisible(state)
        end
    end
})

ButtonLib.Create:Toggle({
    Text = "VFlight",
    Flag = "VFlight",
    Default = false,
    Visible = false,
    Callback = function(s) 
        if VehicleFlyToggle then
            VehicleFlyToggle:Set(s)
        end
    end
}).Position = UDim2.new(0.5, -125, 0.4, 0)

VehicleFlySpeedInput = Tabs.Player:Input({
    Title = "Vehicle Fly Speed",
    Flag = "VehicleFlySpeedInput",
    Placeholder = "Enter speed value",
    Value = tostring(vflyspeed),
    NumbersOnly = true,
    Callback = function(value)
        speed = tonumber(value)
        if speed and speed > 0 then
            vflyspeed = speed
        end
    end
})

VehicleQEflyToggle = Tabs.Player:Toggle({
    Title = "Q/E Vertical Fly",
    Flag = "VehicleQEflyToggle",
    Value = vflyQEfly,
    Callback = function(state)
        vflyQEfly = state
    end
})

Tabs.Player:Space()

TPWALKToggle = Tabs.Player:Toggle({
    Title = "TPWALK",
    Value = false,
    Callback = function(state)
        TPWALK = state
        ToggleTpwalk = state
        if state then
            TpwalkConnection = RunService.Heartbeat:Connect(function()
                if Character and HumanoidRootPart and Humanoid then
                    local moveVector = Humanoid.MoveDirection * TpwalkValue
                    HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + moveVector
                end
            end)
        else
            if TpwalkConnection then
                TpwalkConnection:Disconnect()
                TpwalkConnection = nil
            end
        end
    end
})

TPWALKSlider = Tabs.Player:Slider({
    Title = "TPWALK VALUE",
    Value = { Min = 1, Max = 100, Default = 1 },
    Callback = function(value)
        TpwalkValue = value
    end
})

Tabs.Player:Space()

JumpBoostToggle = Tabs.Player:Toggle({
    Title = "JUMP HEIGHT",
    Value = false,
    Callback = function(state)
        JumpBoost = state
        if Character and Humanoid then
            Humanoid.JumpPower = state and JumpPower or 50
        end
    end
})

JumpBoostSlider = Tabs.Player:Slider({
    Title = "JUMP POWER",
    Value = { Min = 1, Max = 100, Default = 5 },
    Callback = function(value)
        JumpPower = value
        if JumpBoost and Character and Humanoid then
            Humanoid.JumpPower = value
        end
    end
})

Tabs.Player:Space()

local godModeEnabled = false
local godModeConnection = nil
local godModeMethod = "Health Math.huge"

function applyHumanoidReplacement()
    local Char = LocalPlayer.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    local nHuman = Human:Clone()
    nHuman.Parent = Char
    LocalPlayer.Character = nil
    nHuman:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    nHuman:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
    nHuman.BreakJointsOnDeath = true
    nHuman.MaxHealth = math.huge
    nHuman.Health = math.huge
    Human:Destroy()
    LocalPlayer.Character = Char
    nHuman.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    local Script = Char:FindFirstChild("Animate")
    if Script then
        Script.Disabled = true
        wait()
        Script.Disabled = false
    end
end

function applyHealthMathHuge()
    local Char = LocalPlayer.Character
    local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
    if not Human then return end
    Human.MaxHealth = math.huge
    Human.Health = math.huge
    Human:GetPropertyChangedSignal("Health"):Connect(function()
        if godModeEnabled and Human.Health < Human.MaxHealth then
            Human.Health = Human.MaxHealth
        end
    end)
end

function applyGodMode()
    if godModeMethod == "Humanoid Replacement (Very buggy)" then
        applyHumanoidReplacement()
    elseif godModeMethod == "Health Math.huge" then
        applyHealthMathHuge()
    end
end

function startGodMode()
    if godModeConnection then return end
    godModeConnection = RunService.Heartbeat:Connect(function()
        if godModeEnabled and LocalPlayer.Character then
            local Human = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
            if Human and Human.Health < math.huge then
                applyGodMode()
            end
        end
    end)
end

function stopGodMode()
    if godModeConnection then
        godModeConnection:Disconnect()
        godModeConnection = nil
    end
end

Tabs.Player:Space()

GodModeToggle = Tabs.Player:Toggle({
    Title = "God Mode",
    Flag = "GodModeToggle",
    Desc = "Become invincible",
    Value = false,
    Callback = function(state)
        godModeEnabled = state
        if state then
            applyGodMode()
            startGodMode()
        else
            stopGodMode()
        end
    end
})

GodModeMethodDropdown = Tabs.Player:Dropdown({
    Title = "God Mode Method",
    Flag = "GodModeMethodDropdown",
    Values = {"Health Math.huge", "Humanoid Replacement (Very buggy)"},
    Value = "Health Math.huge",
    MenuWidth = 400,
    Callback = function(value)
        godModeMethod = value
        if godModeEnabled then
            applyGodMode()
        end
    end
})

Tabs.Player:Space()

Tabs.Player:Button({
    Title = "Force Reset Character",
    Callback = function()
        RblxCallDialog({
            Title = "Reset Character",
            Desc = [[Are you sure you want to Reset character? Press ''Reset'' to continue] ],
            Button1 = {
                Title = "Cancel",
                Type = "GreyOutline",
            },
            Button2 = {
                Title = "Reset",
                Type = "White",
                WaitTimeClick = 5,
                Callback = function()
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                    if hum then hum.Health = 0 end
                end
            }
        })
    end
})

Tabs.Visuals:Section({ Title = "Visual", TextSize = 20 })
Tabs.Visuals:Divider()

local cameraStretchConnection

function setupCameraStretch()
    cameraStretchConnection = nil
    local stretchHorizontal = 0.80
    local stretchVertical = 0.80
    CameraStretchToggle = Tabs.Visuals:Toggle({
        Title = "Camera Stretch",
        Flag = "CameraStretchToggle",
        Value = false,
        Callback = function(state)
            if state then
                if cameraStretchConnection then cameraStretchConnection:Disconnect() end
                cameraStretchConnection = RunService.RenderStepped:Connect(function()
                    local Camera = workspace.CurrentCamera
                    Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                end)
            else
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = nil
                end
            end
        end
    })

    CameraStretchHorizontalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Horizontal",
        Flag = "CameraStretchHorizontalInput",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchHorizontal),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchHorizontal = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = RunService.RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })

    CameraStretchVerticalInput = Tabs.Visuals:Input({
        Title = "Camera Stretch Vertical",
        Flag = "CameraStretchVerticalInput",
        Placeholder = "0.80",
        Numeric = true,
        Value = tostring(stretchVertical),
        Callback = function(value)
            local num = tonumber(value)
            if num then
                stretchVertical = num
                if cameraStretchConnection then
                    cameraStretchConnection:Disconnect()
                    cameraStretchConnection = RunService.RenderStepped:Connect(function()
                        local Camera = workspace.CurrentCamera
                        Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
                    end)
                end
            end
        end
    })
end

setupCameraStretch()

Tabs.Visuals:Space()

FullBrightToggle = Tabs.Visuals:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(state)
        FullBright = state
        if state then
            originalBrightness = Lighting.Brightness
            originalAmbient = Lighting.Ambient
            originalOutdoorAmbient = Lighting.OutdoorAmbient
            originalColorShift_Top = Lighting.ColorShift_Top
            originalColorShift_Bottom = Lighting.ColorShift_Bottom
            Lighting.Brightness = 1
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
            Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        else
            if originalBrightness then
                Lighting.Brightness = originalBrightness
            end
            if originalAmbient then
                Lighting.Ambient = originalAmbient
            end
            if originalOutdoorAmbient then
                Lighting.OutdoorAmbient = originalOutdoorAmbient
            end
            if originalColorShift_Top then
                Lighting.ColorShift_Top = originalColorShift_Top
            end
            if originalColorShift_Bottom then
                Lighting.ColorShift_Bottom = originalColorShift_Bottom
            end
        end
    end
})

Tabs.Visuals:Space()

NoFogToggle = Tabs.Visuals:Toggle({
    Title = "NO FOG",
    Value = false,
    Callback = function(state)
        NoFog = state
        if state then
            originalFogEnd = Lighting.FogEnd
            Lighting.FogEnd = 100000
        else
            if originalFogEnd then
                Lighting.FogEnd = originalFogEnd
            else
                Lighting.FogEnd = 100
            end
        end
    end
})
cameraInputModule = nil
cameraLockEnabled = false
lockedTarget = nil
cameraLockConnection = nil

AimbotEnabled = false
ShowFOV = false
FOVThickness = 2
FOVColor = Color3.new(0, 1, 0)
targetTypes = {"Player"}
aimPart = "Head"
aimLockType = "Realistic"
smoothnessValue = 10
wallCheckEnabled = false
fovRadius = 100
lockFOVToCenter = true
maxDistance = 1000
AimbotCircle = nil
aimbotRenderConnection = nil
aimbotRunning = false
aimbotConnection = nil

npcCache = {}
lastNPCCacheTime = 0
NPC_CACHE_DURATION = 2

function setupCameraLock()
    if cameraInputModule then return true end
    
    local success = false
    
    pcall(function()
        local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        local playerModule = playerScripts:FindFirstChild("PlayerModule")
        if not playerModule then return end
        local cameraModule = playerModule:FindFirstChild("CameraModule")
        if cameraModule then
            local cameraInput = cameraModule:FindFirstChild("CameraInput")
            if cameraInput then
                cameraInputModule = require(cameraInput)
                if cameraInputModule and cameraInputModule.getRotation then
                    local originalGetRotation = cameraInputModule.getRotation
                    cameraInputModule.getRotation = function(disableRotation)
                        if cameraLockEnabled and lockedTarget and lockedTarget.aimPart then
                            local camera = workspace.CurrentCamera
                            if camera then
                                local targetPos = lockedTarget.aimPart.Position
                                local lookVector = (targetPos - camera.CFrame.Position).Unit
                                local targetCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + lookVector)
                                local smoothFactor = math.clamp(1 - (smoothnessValue / 20), 0.001, 1)
                                camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor)
                            end
                        end
                        
                        local rotation = originalGetRotation(disableRotation)
                        return rotation
                    end
                    success = true
                end
            end
        end
    end)
    
    return success
end

function lockCameraToTarget(target)
    if not target or not target.aimPart then
        unlockCamera()
        return
    end
    
    lockedTarget = target
    cameraLockEnabled = true
    
    if cameraLockConnection then
        cameraLockConnection:Disconnect()
    end
    
    if aimLockType == "Realistic" then
        if not cameraInputModule then
            setupCameraLock()
        end
        
        if not cameraInputModule then
            cameraLockConnection = RunService.Stepped:Connect(function()
                if not cameraLockEnabled or not lockedTarget or not lockedTarget.aimPart then
                    unlockCamera()
                    return
                end
                
                local camera = workspace.CurrentCamera
                if not camera then return end
                
                local targetPos = lockedTarget.aimPart.Position
                local lookVector = (targetPos - camera.CFrame.Position).Unit
                local targetCFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + lookVector)
                local smoothFactor = math.clamp(1 - (smoothnessValue / 20), 0.001, 1)
                camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor)
            end)
        end
    elseif aimLockType == "Stimulate" then
        cameraLockConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not cameraLockEnabled or not lockedTarget or not lockedTarget.aimPart then
                unlockCamera()
                return
            end
            
            local camera = workspace.CurrentCamera
            if not camera then return end
            
            local targetPos = lockedTarget.aimPart.Position
            local smoothFactor = math.clamp(1 - (smoothnessValue / 20), 0.001, 1)
            local cameraPos = camera.CFrame.Position
            local targetDirection = (targetPos - cameraPos).Unit
            local targetCFrame = CFrame.new(cameraPos, cameraPos + targetDirection)
            camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor * math.min(deltaTime * 60, 1))
        end)
    end
end

function unlockCamera()
    cameraLockEnabled = false
    lockedTarget = nil
    
    if cameraLockConnection then
        cameraLockConnection:Disconnect()
        cameraLockConnection = nil
    end
end

function updateNPCCache()
    local currentTime = tick()
    if currentTime - lastNPCCacheTime < NPC_CACHE_DURATION then
        return
    end
    lastNPCCacheTime = currentTime
    local newCache = {}
    local playerCharacters = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            playerCharacters[player.Character] = true
        end
    end
    local function scanForNPCs(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") then
                if not playerCharacters[child] then
                    local humanoid = child:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local rootPart = child:FindFirstChild("HumanoidRootPart") or 
                            child:FindFirstChild("Torso") or 
                            child:FindFirstChild("UpperTorso")
                        if rootPart then
                            table.insert(newCache, {
                                character = child,
                                rootPart = rootPart,
                                humanoid = humanoid
                            })
                        end
                    end
                end
            end
            if child:IsA("Folder") or child:IsA("Model") then
                scanForNPCs(child)
            end
        end
    end
    scanForNPCs(workspace)
    npcCache = newCache
end

function getAimPart(character)
    if not character then return nil end
    if aimPart == "Head" then
        return character:FindFirstChild("Head")
    elseif aimPart == "Body" then
        return character:FindFirstChild("HumanoidRootPart") or 
            character:FindFirstChild("Torso") or 
            character:FindFirstChild("UpperTorso")
    elseif aimPart == "Legs" then
        return character:FindFirstChild("HumanoidRootPart") or
            character:FindFirstChild("LowerTorso") or
            character:FindFirstChild("Left Leg") or
            character:FindFirstChild("Right Leg")
    end
    return character:FindFirstChild("Head")
end

function isVisible(part)
    if not wallCheckEnabled or not part then
        return true
    end
    local character = LocalPlayer.Character
    if not character then return false end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    local origin = humanoidRootPart.Position
    local target = part.Position
    local direction = (target - origin).Unit
    local ray = Ray.new(origin, direction * (target - origin).Magnitude)
    local ignoreList = {character, part.Parent}
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    return hit == nil or hit:IsDescendantOf(part.Parent)
end

function getAllTargets()
    local targets = {}
    local character = LocalPlayer.Character
    local playerPos = character and character:FindFirstChild("HumanoidRootPart") and character.HumanoidRootPart.Position or nil
    
    for _, targetType in ipairs(targetTypes) do
        if targetType == "Player" then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local aimPartInstance = getAimPart(player.Character)
                        if aimPartInstance then
                            if not playerPos or (aimPartInstance.Position - playerPos).Magnitude <= maxDistance then
                                table.insert(targets, {
                                    type = "Player",
                                    character = player.Character,
                                    aimPart = aimPartInstance,
                                    humanoid = humanoid
                                })
                            end
                        end
                    end
                end
            end
        elseif targetType == "NPC" then
            updateNPCCache()
            for _, npcData in ipairs(npcCache) do
                if npcData.humanoid and npcData.humanoid.Health > 0 then
                    local aimPartInstance = getAimPart(npcData.character)
                    if aimPartInstance then
                        if not playerPos or (aimPartInstance.Position - playerPos).Magnitude <= maxDistance then
                            table.insert(targets, {
                                type = "NPC",
                                character = npcData.character,
                                aimPart = aimPartInstance,
                                humanoid = npcData.humanoid
                            })
                        end
                    end
                end
            end
        end
    end
    return targets
end

function getClosestEnemyInFOV()
    local Camera = workspace.CurrentCamera
    if not Camera then return nil end
    local closestTarget = nil
    local closestDistance = math.huge
    local screenCenter = lockFOVToCenter and 
        Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) or 
        UserInputService:GetMouseLocation()
    local allTargets = getAllTargets()
    for _, targetData in ipairs(allTargets) do
        local aimPartInstance = targetData.aimPart
        if aimPartInstance then
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPartInstance.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if distance < fovRadius and distance < closestDistance and isVisible(aimPartInstance) then
                    closestDistance = distance
                    closestTarget = targetData
                end
            end
        end
    end
    return closestTarget
end

function createFOVCircle()
    if AimbotCircle then 
        AimbotCircle:Remove() 
        AimbotCircle = nil
    end
    if not ShowFOV then return end
    local Camera = workspace.CurrentCamera
    if not Camera then return end
    local circle = Drawing.new("Circle")
    circle.Visible = ShowFOV
    circle.Radius = fovRadius
    circle.Color = FOVColor
    circle.Thickness = FOVThickness
    circle.Filled = false
    circle.NumSides = 60
    if lockFOVToCenter then
        local viewportSize = Camera.ViewportSize
        circle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        circle.Position = UserInputService:GetMouseLocation()
    end
    AimbotCircle = circle
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
    end
    aimbotRenderConnection = RunService.RenderStepped:Connect(function()
        local Camera = workspace.CurrentCamera
        if AimbotCircle and ShowFOV and Camera then
            if lockFOVToCenter then
                local viewportSize = Camera.ViewportSize
                AimbotCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
            else
                AimbotCircle.Position = UserInputService:GetMouseLocation()
            end
        end
    end)
end

function updateFOVCircle()
    if AimbotCircle then
        AimbotCircle.Radius = fovRadius
        AimbotCircle.Color = FOVColor
        AimbotCircle.Thickness = FOVThickness
        AimbotCircle.Visible = ShowFOV
    elseif ShowFOV then
        createFOVCircle()
    end
end

function startAimbot()
    if aimbotRunning then return end
    createFOVCircle()
    aimbotRunning = true
    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not AimbotEnabled or not aimbotRunning then
            if cameraLockEnabled then
                unlockCamera()
            end
            return
        end
        local Camera = workspace.CurrentCamera
        if not Camera then return end
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            return
        end
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            return
        end
        if #targetTypes == 0 then
            if cameraLockEnabled then
                unlockCamera()
            end
            return
        end
        local closestTarget = getClosestEnemyInFOV()
        if closestTarget and closestTarget.aimPart then
            if not cameraLockEnabled or lockedTarget ~= closestTarget then
                lockCameraToTarget(closestTarget)
            end
        else
            unlockCamera()
        end
    end)
end

function stopAimbot()
    aimbotRunning = false
    unlockCamera()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    if AimbotCircle then
        AimbotCircle:Remove()
        AimbotCircle = nil
    end
    if aimbotRenderConnection then
        aimbotRenderConnection:Disconnect()
        aimbotRenderConnection = nil
    end
end

function handleCharacterRespawn()
    if AimbotEnabled then
        task.wait(1)
        if AimbotCircle then
            AimbotCircle:Remove()
            AimbotCircle = nil
        end
        createFOVCircle()
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    handleCharacterRespawn()
end)

Tabs.Combat:Section({ Title = "Aimbot" })

AimbotToggle = Tabs.Combat:Toggle({
    Title = "Aimbot",
    Flag = "AimbotToggle",
    Value = false,
    Callback = function(state)
        AimbotEnabled = state
        if state then
            startAimbot()
        else
            stopAimbot()
        end
    end
})

AimPartDropdown = Tabs.Combat:Dropdown({
    Title = "Aim Part",
    Flag = "AimPartDropdown",
    Desc = "Select which part to aim at",
    Values = { "Head", "Body", "Legs" },
    Value = "Head",
    Callback = function(value)
        aimPart = value
    end
})

TargetTypeDropdown = Tabs.Combat:Dropdown({
    Title = "Target Type",
    Flag = "TargetTypeDropdown",
    Desc = "Select which types to target",
    Values = { "Player", "NPC" },
    Value = {"Player"},
    Multi = true,
    AllowNone = true,
    Callback = function(values)
        targetTypes = values
    end
})

AimLockTypeDropdown = Tabs.Combat:Dropdown({
    Title = "Aim Lock Type",
    Flag = "AimLockTypeDropdown",
    Desc = "Select aim lock type",
    Values = { "Realistic", "Stimulate" },
    Value = "Realistic",
    Callback = function(value)
        aimLockType = value
        if cameraLockEnabled then
            unlockCamera()
        end
    end
})

SmoothnessSlider = Tabs.Combat:Slider({
    Title = "Smoothness",
    Flag = "SmoothnessSlider",
    Desc = "Higher = smoother aim, Lower = snappier aim",
Step = 0.01,
    Value = { Min = 0.01, Max = 20, Default = 10,  },
    Callback = function(value)
        smoothnessValue = value
    end
})

MaxDistanceInput = Tabs.Combat:Input({
    Title = "Max Distance",
    Value = "1000",
    Placeholder = "Enter max distance",
    Callback = function(value)
        local numValue = tonumber(value)
        if numValue then
            maxDistance = numValue
        end
    end
})

WallCheckToggle = Tabs.Combat:Toggle({
    Title = "Wall Check",
    Flag = "WallCheckToggle",
    Value = false,
    Callback = function(state)
        wallCheckEnabled = state
    end
})

Tabs.Combat:Section({ Title = "FOV Settings" })

ShowFOVToggle = Tabs.Combat:Toggle({
    Title = "Show FOV Circle",
    Flag = "ShowFOVToggle",
    Value = false,
    Callback = function(state)
        ShowFOV = state
        updateFOVCircle()
    end
})

LockFOVToggle = Tabs.Combat:Toggle({
    Title = "Lock FOV On Middle Screen",
    Flag = "LockFOVToggle",
    Value = true,
    Callback = function(state)
        lockFOVToCenter = state
        updateFOVCircle()
    end
})

FOVRadiusSlider = Tabs.Combat:Slider({
    Title = "FOV Radius",
    Flag = "FOVRadiusSlider",
    Desc = "Size of the targeting area",
    Value = { Min = 10, Max = 500, Default = 100, Step = 5 },
    Callback = function(value)
        fovRadius = value
        updateFOVCircle()
    end
})

FOVColorPicker = Tabs.Combat:Colorpicker({
    Title = "FOV Color",
    Flag = "FOVColorPicker",
    Desc = "FOV Circle Color",
    Default = Color3.fromRGB(0, 255, 0),
    Locked = false,
    Callback = function(color)
        FOVColor = color
        updateFOVCircle()
    end
})

FOVThicknessSlider = Tabs.Combat:Slider({
    Title = "FOV Thickness",
    Flag = "FOVThicknessSlider",
    Desc = "Thickness of the FOV circle",
    Value = { Min = 1, Max = 10, Default = 2, Step = 1 },
    Callback = function(value)
        FOVThickness = value
        updateFOVCircle()
    end
})

playerEspElements = {}
npcEspElements = {}
toolEspElements = {}

playerBoxesEnabled = false
playerNamesEnabled = false
playerDistanceEnabled = false
playerHighlightsEnabled = false
playerHealthEnabled = false
playerTeamEnabled = false
playerStateEnabled = false
playerBoxType = "2D"

npcBoxesEnabled = false
npcNamesEnabled = false
npcDistanceEnabled = false
npcHighlightsEnabled = false
npcHealthEnabled = false
npcStateEnabled = false
npcBoxType = "2D"

toolBoxesEnabled = false
toolNamesEnabled = false
toolDistanceEnabled = false
toolHighlightsEnabled = false
toolBoxType = "2D"

isRendering = true
windowFocused = true

function getDistanceFromCamera(targetPosition)
    local camera = workspace.CurrentCamera
    if not camera then return 0 end
    return (targetPosition - camera.CFrame.Position).Magnitude
end

function calculateBoxScale(distance)
    if distance <= 17 then
        return 1
    else
        local scale = 17 / distance
        return math.max(scale, 0.1)
    end
end

function getPlayerColor(player)
    local teamColor = player.TeamColor
    if teamColor then
        return teamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

function getPlayerState(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return "Unknown" end
    if humanoid.Health <= 0 then return "Dead" end
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        return "Moving"
    else
        return "Idle"
    end
end

function getHealthColor(health, maxHealth)
    local percent = health / maxHealth
    if percent > 0.6 then
        return "#00ff00"
    elseif percent > 0.3 then
        return "#ffa500"
    else
        return "#ff0000"
    end
end

function getToolColor(tool)
    return Color3.fromRGB(0, 255, 255)
end

function create3DBox(character, color, size)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local folderName = "ESP_3DBox"
    local folder = character:FindFirstChild(folderName)
    if folder then
        folder:Destroy()
    end

    folder = Instance.new("Folder")
    folder.Name = folderName
    folder.Parent = character

    size = size or Vector3.new(4, 5, 3)
    local offsetX = size.X / 2
    local offsetY = size.Y / 2
    local offsetZ = size.Z / 2

    local edges = {
        {Vector3.new(0, offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopFront"},
        {Vector3.new(0, offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "TopBack"},
        {Vector3.new(-offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopLeft"},
        {Vector3.new(offsetX, offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "TopRight"},
        {Vector3.new(0, -offsetY, offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomFront"},
        {Vector3.new(0, -offsetY, -offsetZ), Vector3.new(size.X, 0.1, 0.1), "BottomBack"},
        {Vector3.new(-offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomLeft"},
        {Vector3.new(offsetX, -offsetY, 0), Vector3.new(0.1, 0.1, size.Z), "BottomRight"},
        {Vector3.new(-offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontLeft"},
        {Vector3.new(offsetX, 0, offsetZ), Vector3.new(0.1, size.Y, 0.1), "FrontRight"},
        {Vector3.new(-offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackLeft"},
        {Vector3.new(offsetX, 0, -offsetZ), Vector3.new(0.1, size.Y, 0.1), "BackRight"}
    }

    for _, edge in ipairs(edges) do
        local position = edge[1]
        local boxSize = edge[2]
        local name = edge[3]

        local adornment = Instance.new("BoxHandleAdornment")
        adornment.Name = name
        adornment.Adornee = rootPart
        adornment.Size = boxSize
        adornment.CFrame = CFrame.new(position)
        adornment.Color3 = color
        adornment.Transparency = 0.2
        adornment.ZIndex = 10
        adornment.AlwaysOnTop = true
        adornment.Visible = true
        adornment.Parent = folder
    end

    return folder
end

function update3DBoxColor(character, color)
    local folder = character:FindFirstChild("ESP_3DBox")
    if folder then
        for _, adornment in ipairs(folder:GetChildren()) do
            if adornment:IsA("BoxHandleAdornment") then
                adornment.Color3 = color
            end
        end
    end
end

function remove3DBox(character)
    local folder = character:FindFirstChild("ESP_3DBox")
    if folder then
        folder:Destroy()
    end
end

function createBillboard(character, name, color, health, maxHealth, team, state, distance)
    local existing = character:FindFirstChild("ESP_Billboard")
    if existing then
        existing:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        billboard.Adornee = rootPart
        billboard.Parent = rootPart
    else
        billboard.Adornee = character
        billboard.Parent = character
    end

    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 350, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.ClipsDescendants = false
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboard.Active = true

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(1, 0, 1, 0)
    mainFrame.BackgroundTransparency = 1
    mainFrame.Parent = billboard

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "InfoLabel"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = ""
    textLabel.TextColor3 = color
    textLabel.TextSize = 10
    textLabel.Font = Enum.Font.GothamBold
    textLabel.RichText = true
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Top
    textLabel.TextWrapped = true
    textLabel.LineHeight = 1.2
    textLabel.Parent = mainFrame

    return {
        billboard = billboard,
        textLabel = textLabel
    }
end

function updateBillboard(billboardData, name, distance, color, health, maxHealth, team, state)
    if not billboardData then return end

    local lines = {}
    local lineCount = 0

    if name then
        lineCount = lineCount + 1
        lines[lineCount] = name .. (team and " | Team: " .. team or "")
    end

    local secondLine = {}
    if health and maxHealth then
        local healthColor = getHealthColor(health, maxHealth)
        table.insert(secondLine, string.format('<font color="%s">Health: %.0f / %.0f</font>', healthColor, health, maxHealth))
    end
    if distance then
        table.insert(secondLine, "Distance: " .. string.format("%.0f", distance))
    end
    if state then
        table.insert(secondLine, "State: " .. state)
    end

    if #secondLine > 0 then
        lineCount = lineCount + 1
        lines[lineCount] = table.concat(secondLine, " | ")
    end

    billboardData.textLabel.Text = table.concat(lines, "\n")
    billboardData.textLabel.TextColor3 = color
    billboardData.textLabel.TextStrokeTransparency = 0
end

function create2DBox(character, color, scale)
    local existing = character:FindFirstChild("ESP_2DBox")
    if existing then
        existing:Destroy()
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_2DBox"

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        billboard.Adornee = rootPart
        billboard.Parent = rootPart
    else
        billboard.Adornee = character
        billboard.Parent = character
    end

    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.ClipsDescendants = false

    local boxFrame = Instance.new("Frame")
    boxFrame.Name = "BoxFrame"
    boxFrame.Size = UDim2.new(1, 0, 1, 0)
    boxFrame.BackgroundTransparency = 1
    boxFrame.BorderSizePixel = 0
    boxFrame.Parent = billboard

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Thickness = math.max(2.5 * scale, 2)
    uiStroke.Transparency = 0
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    uiStroke.Color = color
    uiStroke.Parent = boxFrame

    return {
        billboard = billboard,
        boxFrame = boxFrame,
        stroke = uiStroke,
        scale = scale
    }
end

function update2DBox(boxData, color, scale)
    if boxData then
        if boxData.stroke then
            boxData.stroke.Color = color
        end
        if boxData.billboard then
            boxData.billboard.Size = UDim2.new(0, 80 * scale, 0, 100 * scale)
        end
        if boxData.stroke then
            boxData.stroke.Thickness = math.max(2.5 * scale, 2)
        end
        boxData.scale = scale
    end
end

function remove2DBox(character)
    local box = character:FindFirstChild("ESP_2DBox")
    if box then
        box:Destroy()
    end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
        if boxInRoot then
            boxInRoot:Destroy()
        end
    end
end

function createHighlight(character, color)
    local existing = character:FindFirstChild("ESP_Highlight")
    if existing then
        existing:Destroy()
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0.3
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character

    return highlight
end

function updateHighlight(highlight, color)
    if highlight then
        highlight.FillColor = color
        highlight.OutlineColor = color
    end
end

function removeHighlight(character)
    local highlight = character:FindFirstChild("ESP_Highlight")
    if highlight then
        highlight:Destroy()
    end
end

function getNPCColor()
    return Color3.fromRGB(255, 255, 0)
end

function isNPC(model)
    if not model or not model:IsA("Model") then return false end
    if not model:FindFirstChild("Humanoid") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return true
end

function findAllNPCs()
    local npcs = {}
    local function searchForNPCs(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") and isNPC(child) then
                table.insert(npcs, child)
            else
                if child:IsA("Folder") or child:IsA("Model") then
                    searchForNPCs(child)
                end
            end
        end
    end
    searchForNPCs(workspace)
    return npcs
end

function isToolModel(model)
    if not model or not model:IsA("Model") then return false end
    if model:FindFirstChild("Handle") then return true end
    if model:FindFirstChildWhichIsA("Tool") then return true end
    return false
end

function findAllTools()
    local tools = {}
    local function searchForTools(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA("Model") and isToolModel(child) then
                table.insert(tools, child)
            else
                if child:IsA("Folder") or child:IsA("Model") then
                    searchForTools(child)
                end
            end
        end
    end
    searchForTools(workspace)
    return tools
end

function cleanupPlayerESP()
    for character, esp in pairs(playerEspElements) do
        if esp.box2D then
            local box = character:FindFirstChild("ESP_2DBox")
            if box then box:Destroy() end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
                if boxInRoot then boxInRoot:Destroy() end
            end
        end
        if esp.box3D then remove3DBox(character) end
        if esp.highlight then removeHighlight(character) end
        if esp.billboard then
            local bill = character:FindFirstChild("ESP_Billboard")
            if bill then bill:Destroy() end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                if billInRoot then billInRoot:Destroy() end
            end
        end
    end
    playerEspElements = {}
end

function cleanupNPCCleanup()
    for npc, esp in pairs(npcEspElements) do
        if esp.box2D then
            local box = npc:FindFirstChild("ESP_2DBox")
            if box then box:Destroy() end
            local rootPart = npc:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local boxInRoot = rootPart:FindFirstChild("ESP_2DBox")
                if boxInRoot then boxInRoot:Destroy() end
            end
        end
        if esp.box3D then remove3DBox(npc) end
        if esp.highlight then removeHighlight(npc) end
        if esp.billboard then
            local bill = npc:FindFirstChild("ESP_Billboard")
            if bill then bill:Destroy() end
            local rootPart = npc:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                if billInRoot then billInRoot:Destroy() end
            end
        end
    end
    npcEspElements = {}
end

function cleanupToolESP()
    for tool, esp in pairs(toolEspElements) do
        if esp.box2D then
            local box = tool:FindFirstChild("ESP_2DBox")
            if box then box:Destroy() end
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local boxInHandle = handle:FindFirstChild("ESP_2DBox")
                if boxInHandle then boxInHandle:Destroy() end
            end
        end
        if esp.box3D then remove3DBox(tool) end
        if esp.highlight then removeHighlight(tool) end
        if esp.billboard then
            local bill = tool:FindFirstChild("ESP_Billboard")
            if bill then bill:Destroy() end
            local handle = tool:FindFirstChild("Handle")
            if handle then
                local billInHandle = handle:FindFirstChild("ESP_Billboard")
                if billInHandle then billInHandle:Destroy() end
            end
        end
    end
    toolEspElements = {}
end

function updatePlayerESP()
    if not isRendering or not windowFocused then return end
    if not workspace.CurrentCamera then return end

    local currentTargets = {}

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer then
            local character = otherPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    currentTargets[character] = true

                    if not playerEspElements[character] then
                        playerEspElements[character] = {}
                    end

                    local esp = playerEspElements[character]
                    local distance = getDistanceFromCamera(character.HumanoidRootPart.Position)
                    local scale = calculateBoxScale(distance)
                    local boxColor = getPlayerColor(otherPlayer)
                    local health = humanoid.Health
                    local maxHealth = humanoid.MaxHealth
                    local team = otherPlayer.Team and otherPlayer.Team.Name or "None"
                    local state = getPlayerState(character)

                    if playerBoxesEnabled then
                        if playerBoxType == "2D" then
                            if not esp.box2D then
                                esp.box2D = create2DBox(character, boxColor, scale)
                            end
                            update2DBox(esp.box2D, boxColor, scale)
                            if esp.box3D then
                                remove3DBox(character)
                                esp.box3D = nil
                            end
                        else
                            local boxSize = Vector3.new(4, 5, 3)
                            if humanoid then
                                boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
                            end
                            if not esp.box3D then
                                esp.box3D = create3DBox(character, boxColor, boxSize)
                            end
                            update3DBoxColor(character, boxColor)
                            if esp.box2D then
                                remove2DBox(character)
                                esp.box2D = nil
                            end
                        end
                    else
                        if esp.box2D then
                            remove2DBox(character)
                            esp.box2D = nil
                        end
                        if esp.box3D then
                            remove3DBox(character)
                            esp.box3D = nil
                        end
                    end

                    if playerHighlightsEnabled then
                        if not esp.highlight then
                            esp.highlight = createHighlight(character, boxColor)
                        end
                        updateHighlight(esp.highlight, boxColor)
                    else
                        if esp.highlight then
                            removeHighlight(character)
                            esp.highlight = nil
                        end
                    end

                    local showBillboard = playerNamesEnabled or playerDistanceEnabled or playerHealthEnabled or playerTeamEnabled or playerStateEnabled
                    if showBillboard then
                        if not esp.billboard then
                            esp.billboard = createBillboard(character, otherPlayer.Name, boxColor, health, maxHealth, team, state, distance)
                        end
                        local displayName = playerNamesEnabled and otherPlayer.Name or nil
                        local displayDistance = playerDistanceEnabled and distance or nil
                        local displayHealth = playerHealthEnabled and health or nil
                        local displayMaxHealth = playerHealthEnabled and maxHealth or nil
                        local displayTeam = playerTeamEnabled and team or nil
                        local displayState = playerStateEnabled and state or nil
                        updateBillboard(esp.billboard, displayName, displayDistance, boxColor, displayHealth, displayMaxHealth, displayTeam, displayState)
                    else
                        if esp.billboard then
                            local bill = character:FindFirstChild("ESP_Billboard")
                            if bill then bill:Destroy() end
                            local rootPart = character:FindFirstChild("HumanoidRootPart")
                            if rootPart then
                                local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                                if billInRoot then billInRoot:Destroy() end
                            end
                            esp.billboard = nil
                        end
                    end
                end
            end
        end
    end

    for character, esp in pairs(playerEspElements) do
        if not currentTargets[character] then
            if esp.box2D then remove2DBox(character) end
            if esp.box3D then remove3DBox(character) end
            if esp.highlight then removeHighlight(character) end
            if esp.billboard then
                local bill = character:FindFirstChild("ESP_Billboard")
                if bill then bill:Destroy() end
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                    if billInRoot then billInRoot:Destroy() end
                end
            end
            playerEspElements[character] = nil
        end
    end
end

function updateNPCESP()
    if not isRendering or not windowFocused then return end
    if not workspace.CurrentCamera then return end

    local currentTargets = {}
    local allNPCs = findAllNPCs()

    for _, npc in ipairs(allNPCs) do
        local hrp = npc:FindFirstChild("HumanoidRootPart")
        local humanoid = npc:FindFirstChild("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then
            currentTargets[npc] = true

            if not npcEspElements[npc] then
                npcEspElements[npc] = {}
            end

            local esp = npcEspElements[npc]
            local distance = getDistanceFromCamera(hrp.Position)
            local scale = calculateBoxScale(distance)
            local boxColor = getNPCColor()
            local npcName = npc.Name or "NPC"
            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local state = getPlayerState(npc)

            if npcBoxesEnabled then
                if npcBoxType == "2D" then
                    if not esp.box2D then
                        esp.box2D = create2DBox(npc, boxColor, scale)
                    end
                    update2DBox(esp.box2D, boxColor, scale)
                    if esp.box3D then
                        remove3DBox(npc)
                        esp.box3D = nil
                    end
                else
                    local boxSize = Vector3.new(4, 5, 3)
                    if humanoid then
                        boxSize = Vector3.new(2, humanoid.HipHeight + 5, 2)
                    end
                    if not esp.box3D then
                        esp.box3D = create3DBox(npc, boxColor, boxSize)
                    end
                    update3DBoxColor(npc, boxColor)
                    if esp.box2D then
                        remove2DBox(npc)
                        esp.box2D = nil
                    end
                end
            else
                if esp.box2D then remove2DBox(npc) end
                if esp.box3D then remove3DBox(npc) end
            end

            if npcHighlightsEnabled then
                if not esp.highlight then
                    esp.highlight = createHighlight(npc, boxColor)
                end
                updateHighlight(esp.highlight, boxColor)
            else
                if esp.highlight then
                    removeHighlight(npc)
                    esp.highlight = nil
                end
            end

            local showBillboard = npcNamesEnabled or npcDistanceEnabled or npcHealthEnabled or npcStateEnabled
            if showBillboard then
                if not esp.billboard then
                    esp.billboard = createBillboard(npc, npcName, boxColor, health, maxHealth, nil, state, distance)
                end
                local displayName = npcNamesEnabled and npcName or nil
                local displayDistance = npcDistanceEnabled and distance or nil
                local displayHealth = npcHealthEnabled and health or nil
                local displayMaxHealth = npcHealthEnabled and maxHealth or nil
                local displayState = npcStateEnabled and state or nil
                updateBillboard(esp.billboard, displayName, displayDistance, boxColor, displayHealth, displayMaxHealth, nil, displayState)
            else
                if esp.billboard then
                    local bill = npc:FindFirstChild("ESP_Billboard")
                    if bill then bill:Destroy() end
                    local rootPart = npc:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                        if billInRoot then billInRoot:Destroy() end
                    end
                    esp.billboard = nil
                end
            end
        end
    end

    for npc, esp in pairs(npcEspElements) do
        if not currentTargets[npc] then
            if esp.box2D then remove2DBox(npc) end
            if esp.box3D then remove3DBox(npc) end
            if esp.highlight then removeHighlight(npc) end
            if esp.billboard then
                local bill = npc:FindFirstChild("ESP_Billboard")
                if bill then bill:Destroy() end
                local rootPart = npc:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local billInRoot = rootPart:FindFirstChild("ESP_Billboard")
                    if billInRoot then billInRoot:Destroy() end
                end
            end
            npcEspElements[npc] = nil
        end
    end
end

function updateToolESP()
    if not isRendering or not windowFocused then return end
    if not workspace.CurrentCamera then return end

    local currentTargets = {}
    local allTools = findAllTools()

    for _, tool in ipairs(allTools) do
        local handle = tool:FindFirstChild("Handle")
        local primaryPart = tool.PrimaryPart or handle or tool:FindFirstChildWhichIsA("BasePart")
        if primaryPart then
            currentTargets[tool] = true

            if not toolEspElements[tool] then
                toolEspElements[tool] = {}
            end

            local esp = toolEspElements[tool]
            local distance = getDistanceFromCamera(primaryPart.Position)
            local scale = calculateBoxScale(distance)
            local toolColor = getToolColor(tool)
            local toolName = tool.Name or "Tool"

            if toolBoxesEnabled then
                if toolBoxType == "2D" then
                    if not esp.box2D then
                        esp.box2D = create2DBox(tool, toolColor, scale)
                    end
                    update2DBox(esp.box2D, toolColor, scale)
                    if esp.box3D then
                        remove3DBox(tool)
                        esp.box3D = nil
                    end
                else
                    local boxSize = Vector3.new(2, 2, 2)
                    if handle then
                        boxSize = Vector3.new(handle.Size.X, handle.Size.Y, handle.Size.Z)
                    end
                    if not esp.box3D then
                        esp.box3D = create3DBox(tool, toolColor, boxSize)
                    end
                    update3DBoxColor(tool, toolColor)
                    if esp.box2D then
                        remove2DBox(tool)
                        esp.box2D = nil
                    end
                end
            else
                if esp.box2D then remove2DBox(tool) end
                if esp.box3D then remove3DBox(tool) end
            end

            if toolHighlightsEnabled then
                if not esp.highlight then
                    esp.highlight = createHighlight(tool, toolColor)
                end
                updateHighlight(esp.highlight, toolColor)
            else
                if esp.highlight then
                    removeHighlight(tool)
                    esp.highlight = nil
                end
            end

            local showBillboard = toolNamesEnabled or toolDistanceEnabled
            if showBillboard then
                if not esp.billboard then
                    esp.billboard = createBillboard(tool, toolName, toolColor, nil, nil, nil, nil, distance)
                end
                local displayName = toolNamesEnabled and toolName or nil
                local displayDistance = toolDistanceEnabled and distance or nil
                updateBillboard(esp.billboard, displayName, displayDistance, toolColor, nil, nil, nil, nil)
            else
                if esp.billboard then
                    local bill = tool:FindFirstChild("ESP_Billboard")
                    if bill then bill:Destroy() end
                    local handlePart = tool:FindFirstChild("Handle")
                    if handlePart then
                        local billInHandle = handlePart:FindFirstChild("ESP_Billboard")
                        if billInHandle then billInHandle:Destroy() end
                    end
                    esp.billboard = nil
                end
            end
        end
    end

    for tool, esp in pairs(toolEspElements) do
        if not currentTargets[tool] then
            if esp.box2D then remove2DBox(tool) end
            if esp.box3D then remove3DBox(tool) end
            if esp.highlight then removeHighlight(tool) end
            if esp.billboard then
                local bill = tool:FindFirstChild("ESP_Billboard")
                if bill then bill:Destroy() end
                local handle = tool:FindFirstChild("Handle")
                if handle then
                    local billInHandle = handle:FindFirstChild("ESP_Billboard")
                    if billInHandle then billInHandle:Destroy() end
                end
            end
            toolEspElements[tool] = nil
        end
    end
end

renderConnection = nil
lastRenderTime = tick()
renderCheckConnection = nil

function onRenderStepped()
    lastRenderTime = tick()
    isRendering = true

    if playerBoxesEnabled or playerNamesEnabled or playerDistanceEnabled or playerHighlightsEnabled or playerHealthEnabled or playerTeamEnabled or playerStateEnabled then
        updatePlayerESP()
    else
        cleanupPlayerESP()
    end

    if npcBoxesEnabled or npcNamesEnabled or npcDistanceEnabled or npcHighlightsEnabled or npcHealthEnabled or npcStateEnabled then
        updateNPCESP()
    else
        cleanupNPCCleanup()
    end

    if toolBoxesEnabled or toolNamesEnabled or toolDistanceEnabled or toolHighlightsEnabled then
        updateToolESP()
    else
        cleanupToolESP()
    end
end

function startRenderLoop()
    if renderConnection then return end
    renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
end

function stopRenderLoop()
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

function cleanupAllESP()
    cleanupPlayerESP()
    cleanupNPCCleanup()
    cleanupToolESP()
end

RunService.RenderStepped:Connect(function()
    lastRenderTime = tick()
    isRendering = true
end)

renderCheckConnection = RunService.Heartbeat:Connect(function()
    local currentTime = tick()
    if currentTime - lastRenderTime > 1 then
        isRendering = false
        cleanupAllESP()
    end
end)

UserInputService.WindowFocusReleased:Connect(function()
    windowFocused = false
    isRendering = false
    cleanupAllESP()
end)

UserInputService.WindowFocused:Connect(function()
    windowFocused = true
    isRendering = true
end)

game:GetService("GuiService"):GetPropertyChangedSignal("MenuIsOpen"):Connect(function()
    if game:GetService("GuiService").MenuIsOpen then
        isRendering = false
        cleanupAllESP()
    else
        isRendering = true
    end
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == LocalPlayer then
        cleanupAllESP()
        stopRenderLoop()
    end
end)

startRenderLoop()

Tabs.ESP:Section({ Title = "Player ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
    Title = "Player Boxes",
    Flag = "PlayerBoxes",
    Value = false,
    Callback = function(state) playerBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
    Title = "Player Box Type",
    Flag = "PlayerBoxType",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value) playerBoxType = value end
})

Tabs.ESP:Toggle({
    Title = "Player Names",
    Flag = "PlayerNames",
    Value = false,
    Callback = function(state) playerNamesEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Player Distance",
    Flag = "PlayerDistance",
    Value = false,
    Callback = function(state) playerDistanceEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Player Health",
    Flag = "PlayerHealth",
    Value = false,
    Callback = function(state) playerHealthEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Player Team",
    Flag = "PlayerTeam",
    Value = false,
    Callback = function(state) playerTeamEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Player State",
    Flag = "PlayerState",
    Value = false,
    Callback = function(state) playerStateEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Player Highlights",
    Flag = "PlayerHighlights",
    Value = false,
    Callback = function(state) playerHighlightsEnabled = state end
})

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "NPC ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
    Title = "NPC Boxes",
    Flag = "NPCBoxes",
    Value = false,
    Callback = function(state) npcBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
    Title = "NPC Box Type",
    Flag = "NPCBoxType",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value) npcBoxType = value end
})

Tabs.ESP:Toggle({
    Title = "NPC Names",
    Flag = "NPCNames",
    Value = false,
    Callback = function(state) npcNamesEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "NPC Distance",
    Flag = "NPCDistance",
    Value = false,
    Callback = function(state) npcDistanceEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "NPC Health",
    Flag = "NPCHelath",
    Value = false,
    Callback = function(state) npcHealthEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "NPC State",
    Flag = "NPCState",
    Value = false,
    Callback = function(state) npcStateEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "NPC Highlights",
    Flag = "NPCHighlights",
    Value = false,
    Callback = function(state) npcHighlightsEnabled = state end
})

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Tool ESP", TextSize = 20 })
Tabs.ESP:Divider()

Tabs.ESP:Toggle({
    Title = "Tool Boxes",
    Flag = "ToolBoxes",
    Value = false,
    Callback = function(state) toolBoxesEnabled = state end
})

Tabs.ESP:Dropdown({
    Title = "Tool Box Type",
    Flag = "ToolBoxType",
    Values = {"2D", "3D"},
    Value = "2D",
    Callback = function(value) toolBoxType = value end
})

Tabs.ESP:Toggle({
    Title = "Tool Names",
    Flag = "ToolNames",
    Value = false,
    Callback = function(state) toolNamesEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Tool Distance",
    Flag = "ToolDistance",
    Value = false,
    Callback = function(state) toolDistanceEnabled = state end
})

Tabs.ESP:Toggle({
    Title = "Tool Highlights",
    Flag = "ToolHighlights",
    Value = false,
    Callback = function(state) toolHighlightsEnabled = state end
})

Tabs.Misc:Section({ Title = "Misc", TextSize = 20 })
Tabs.Misc:Divider()

AntiAFKToggle = Tabs.Misc:Toggle({
    Title = "ANTI AFK",
    Flag = "Anti AFK",
    Value = false,
    Callback = function(state)
        if state then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})

Tabs.Misc:Space()

AntiKillPartsToggle = Tabs.Misc:Toggle({
    Title = "Anti Kill Parts",
    Value = false,
    Callback = function(state)
        toggleAntiKillParts(state)
    end
})

Tabs.Misc:Space()

StrengthToggle = Tabs.Misc:Toggle({
    Title = "Strength",
    Value = false,
    Callback = function(state)
        isStrengthened = state
        if LocalPlayer.Character then
            manageStrength(LocalPlayer.Character, state)
        end
        LocalPlayer.CharacterAdded:Connect(function(newChar)
            if isStrengthened then
                manageStrength(newChar, true)
            end
        end)
    end
})

Tabs.Misc:Space()

SpawnpointToggle = Tabs.Misc:Toggle({
    Title = "Spawnpoint",
    Value = false,
    Callback = function(state)
        spawnpointActive = state
        if state then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                savedPosition = character.HumanoidRootPart.CFrame
            end
            setupSpawnpoint()
        else
            savedPosition = nil
            needsRespawn = false
            if respawnConnection then
                respawnConnection:Disconnect()
                respawnConnection = nil
            end
        end
    end
})

Tabs.Misc:Space()

AntiSlapToggle = Tabs.Misc:Toggle({
    Title = "Anti Slap",
    Value = false,
    Callback = function(state)
        as = state
        if state then
            if LocalPlayer.Character then
                dc(LocalPlayer.Character)
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(dc)

Tabs.Misc:Space()

XenoAntiFlingToggle = Tabs.Misc:Toggle({
    Title = "Xeno AntiFling",
    Value = false,
    Callback = function(state)
        toggleXenoAntiFling(state)
    end
})

Tabs.Misc:Space()

InfinitePositionToggle = Tabs.Misc:Toggle({
    Title = "Infinite Position",
    Value = false,
    Callback = function(state)
        infinitePositionEnabled = state
        if state then
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                savedInfinitePosition = character.HumanoidRootPart.CFrame
            end
            setupInfinitePosition()
        else
            savedInfinitePosition = nil
            if infinitePositionConnection then
                infinitePositionConnection:Disconnect()
                infinitePositionConnection = nil
            end
        end
    end
})

Tabs.Misc:Space()

NDSAntiFallDamageToggle = Tabs.Misc:Toggle({
    Title = "NDS Anti Fall Damage",
    Value = false,
    Callback = function(state)
        toggleAFD(state)
    end
})

Tabs.Misc:Space()

AntiSitToggle = Tabs.Misc:Toggle({
    Title = "Anti Sit",
    Value = false,
    Callback = function(state)
        toggleNoSit(state)
        LocalPlayer.CharacterAdded:Connect(function(character)
            if state then
                local humanoid = character:WaitForChildOfClass("Humanoid")
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
                if humanoid.Sit then
                    humanoid.Sit = false
                end
                humanoid.Sit = true
            end
        end)
    end
})

Tabs.Misc:Space()

AntiRagdollToggle = Tabs.Misc:Toggle({
    Title = "Anti Ragdoll",
    Value = false,
    Callback = function(state)
        antiRagdollEnabled = state
        if state then
            if antiRagdollDisconnectFunc then
                antiRagdollDisconnectFunc()
            end
            if LocalPlayer.Character then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid.PlatformStand = false
                end
                antiRagdollDisconnectFunc = createAntiRagdoll(LocalPlayer.Character)
            end
        else
            if antiRagdollDisconnectFunc then
                antiRagdollDisconnectFunc()
                antiRagdollDisconnectFunc = nil
            end
        end
    end
})

Tabs.Misc:Space()

FPDToggle = Tabs.Misc:Toggle({
    Title = "FPD Protection",
    Value = false,
    Callback = function(state)
        toggleFPDProtection(state)
    end
})

Tabs.Misc:Space()

local hiddenfling = false
local movel = 0.1
local flingPower = 1e35
local flingCoroutine = nil

function fling2()
    local chr = LocalPlayer.Character
    if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    while hiddenfling and chr and hrp and hrp.Parent do
        local vel = hrp.Velocity
        hrp.Velocity = vel * flingPower + Vector3.new(0, flingPower, 0)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
        RunService.Stepped:Wait()
        hrp.Velocity = vel + Vector3.new(0, movel, 0)
        movel = -movel
        RunService.Heartbeat:Wait()
    end
end

function startFling2()
    if flingCoroutine then
        coroutine.close(flingCoroutine)
        flingCoroutine = nil
    end
    flingCoroutine = coroutine.create(fling2)
    coroutine.resume(flingCoroutine)
end

function stopFling2()
    if flingCoroutine then
        coroutine.close(flingCoroutine)
        flingCoroutine = nil
    end
    local chr = LocalPlayer.Character
    if chr then
        local hrp = chr:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

Tabs.Utility:Space()

TouchFlingToggle = Tabs.Utility:Toggle({
    Title = "Touch Fling",
    Flag = "TouchFlingToggle",
    Value = false,
    Callback = function(state)
        hiddenfling = state
        if state then
            startFling2()
        else
            stopFling2()
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(character)
    if hiddenfling then
        task.wait(1)
        startFling2()
    else
        task.wait(0.5)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.Velocity = Vector3.new(0, 0, 0)
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end)

Tabs.Utility:Input({
    Title = "Fling Power",
    Placeholder = "Enter fling power (default: 1e35)",
    Callback = function(value)
        if value and value ~= "" then
            flingPower = tonumber(value) or 1e35
        end
    end
})

Tabs.Utility:Space()

Tabs.Utility:Button({
    Title = "Fling Tool",
    Icon = "rbxassetid://3836615692",
    Callback = function()
        local CharacterModel = LocalPlayer.Character
        local Humanoid = CharacterModel:WaitForChild("Humanoid")
        CharacterModel:WaitForChild("HumanoidRootPart")
        function FindPart(ParentModel, PartName, PartType)
            local FoundPart = nil
            pcall(function()
                local ParentModel = ParentModel
                local Iterator, Table, Key = pairs(ParentModel:GetChildren())
                while true do
                    local Value
                    Key, Value = Iterator(Table, Key)
                    if Key == nil then
                        break
                    end
                    if Value.Name == PartName and Value:IsA(PartType) then
                        FoundPart = Value
                        break
                    end
                end
            end)
            return FoundPart
        end
        local IsEnabled = false
        local RunService = game:GetService("RunService")
        local SteppedEvent = RunService.Stepped
        local HeartbeatEvent = RunService.Heartbeat
        local RenderSteppedEvent = RunService.RenderStepped
        local LocalPlayer = game.Players.LocalPlayer
        local IsActive = true
        spawn(function()
            local Character = nil
            local Part = nil
            local VelocityMultiplier = 0.1
            while IsActive do
                HeartbeatEvent:Wait()
                if IsEnabled then
                    while IsEnabled and (IsActive and not (Character and (Character.Parent and (Part and Part.Parent)))) do
                        HeartbeatEvent:Wait()
                        Character = LocalPlayer.Character
                        Part = FindPart(Character, "HumanoidRootPart", "BasePart") or (FindPart(Character, "Torso", "BasePart") or FindPart(Character, "UpperTorso", "BasePart"))
                    end
                    if IsActive and IsEnabled then
                        local OriginalVelocity = Part.Velocity
                        Part.Velocity = OriginalVelocity * 100 + Vector3.new(10000, 10000, 0)
                        Part.CFrame = Part.CFrame * CFrame.new(0, 0.001, 0)
                        RenderSteppedEvent:Wait()
                        if Character and (Character.Parent and (Part and Part.Parent)) then
                            Part.Velocity = OriginalVelocity
                        end
                        SteppedEvent:Wait()
                        if Character and (Character.Parent and (Part and Part.Parent)) then
                            Part.Velocity = OriginalVelocity + Vector3.new(0, VelocityMultiplier, 0)
                            VelocityMultiplier = VelocityMultiplier * - 1
                        end
                    end
                end
            end
        end)
        local AnimationId
        if LocalPlayer.Character.Humanoid.RigType ~= Enum.HumanoidRigType.R15 then
            AnimationId = "218504594"
        else
            AnimationId = "674871189"
        end
        local Animation = Instance.new("Animation")
        Animation.AnimationId = "rbxassetid://" .. AnimationId
        local LoadedAnimation = LocalPlayer.Character.Humanoid:LoadAnimation(Animation)
        local Tool = Instance.new("Tool", LocalPlayer.Backpack)
        Tool.RequiresHandle = false
        Tool.Name = "Punch Fling"
        Tool.TextureId = "rbxassetid://3836615692"
        Tool.Activated:Connect(function()
            LoadedAnimation:Play()
            IsEnabled = true
            wait(2)
            IsEnabled = false
        end)
        Humanoid.Died:Connect(function()
            IsActive = false
            Tool:Destroy()
            Animation:Destroy()
        end)
    end
})

local flingActive = false
local flingMode = 1
local currentInput = ""
local processedPlayers = {}

function sortPlayersAlphabetically2(players)
    table.sort(players, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)
    return players
end

function getPlayers2(input)
    local players = {}
    input = string.lower(input or "")
    if input == "all" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(players, player)
            end
        end
        players = sortPlayersAlphabetically2(players)
    elseif input == "nonfriends" then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local success, isFriend = pcall(function()
                    return player:IsFriendsWith(LocalPlayer.UserId)
                end)
                if not (success and isFriend) then
                    table.insert(players, player)
                end
            end
        end
        players = sortPlayersAlphabetically2(players)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local playerName = string.lower(player.Name)
                local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
                for _, term in ipairs(searchTerms) do
                    if string.find(playerName, term) or string.find(displayName, term) then
                        table.insert(players, player)
                        break
                    end
                end
            end
        end
    end
    return players
end

function SkidFling2(TargetPlayer, duration)
    local startTime = tick()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid
    local TRootPart
    local THead
    local Accessory
    local Handle
    if TCharacter:FindFirstChildOfClass("Humanoid") then
        THumanoid = TCharacter:FindFirstChildOfClass("Humanoid")
    end
    if THumanoid and THumanoid.RootPart then
        TRootPart = THumanoid.RootPart
    end
    if TCharacter:FindFirstChild("Head") then
        THead = TCharacter.Head
    end
    if TCharacter:FindFirstChildOfClass("Accessory") then
        Accessory = TCharacter:FindFirstChildOfClass("Accessory")
    end
    if Accessory and Accessory:FindFirstChild("Handle") then
        Handle = Accessory.Handle
    end
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if THead then
            workspace.CurrentCamera.CameraSubject = THead
        elseif not THead and Handle then
            workspace.CurrentCamera.CameraSubject = Handle
        elseif THumanoid and TRootPart then
            workspace.CurrentCamera.CameraSubject = THumanoid
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then
            return
        end
        local FPos = function(BasePart, Pos, Ang)
            RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
            Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
            RootPart.Velocity = Vector3.new(9e7, 9e7 * 10, 9e7)
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        local SFBasePart = function(BasePart)
            local TimeToWait = duration or 2
            local Time = tick()
            local Angle = 0
            repeat
                if RootPart and THumanoid then
                    if BasePart.Velocity.Magnitude < 50 then
                        Angle = Angle + 100
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                        task.wait()
                    else
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0))
                        task.wait()
                        FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until not flingActive or BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
        end
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Name = "EpixVel"
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(9e8, 9e8, 9e8)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                SFBasePart(THead)
            else
                SFBasePart(TRootPart)
            end
        elseif TRootPart and not THead then
            SFBasePart(TRootPart)
        elseif not TRootPart and THead then
            SFBasePart(THead)
        elseif not TRootPart and not THead and Accessory and Handle then
            SFBasePart(Handle)
        end
        BV:Destroy()
        Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
        workspace.CurrentCamera.CameraSubject = Humanoid
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetChildren()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

function shhhlol2(TargetPlayer)
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local RootPart = Humanoid and Humanoid.RootPart
    local TCharacter = TargetPlayer.Character
    local THumanoid = TCharacter and TCharacter:FindFirstChildOfClass("Humanoid")
    local TRootPart = THumanoid and THumanoid.RootPart
    local THead = TCharacter and TCharacter:FindFirstChild("Head")
    if Character and Humanoid and RootPart then
        if RootPart.Velocity.Magnitude < 50 then
            getgenv().OldPos = RootPart.CFrame
        end
        if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
        function mmmm(comkid, Pos, Ang)
            RootPart.CFrame = CFrame.new(comkid.Position) * Pos * Ang
            RootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
        end
        function wtf(comkid)
            local TimeToWait = 0.134
            local Time = tick()
            local Att1 = Instance.new("Attachment", RootPart)
            local Att2 = Instance.new("Attachment", comkid)
            repeat
                if RootPart and THumanoid then
                    if comkid.Velocity.Magnitude < 30 then
                        mmmm(
                            comkid,
                            CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 5,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()
                        mmmm(
                            comkid,
                            CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()
                        mmmm(
                            comkid,
                            CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * comkid.Velocity.Magnitude / 1.25,
                            CFrame.Angles(
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180),
                                math.random(1, 2) == 1 and math.rad(0) or math.rad(180)
                            )
                        )
                        task.wait()
                    else
                        mmmm(comkid, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(0), 0, 0))
                        task.wait()
                    end
                else
                    break
                end
            until comkid.Velocity.Magnitude > 1000 or 
                comkid.Parent ~= TargetPlayer.Character or
                TargetPlayer.Parent ~= Players or
                not TargetPlayer.Character == TCharacter or
                Humanoid.Health <= 0 or
                tick() > Time + TimeToWait or
                not flingActive
            Att1:Destroy()
            Att2:Destroy()
        end
        local previousDestroyHeight = workspace.FallenPartsDestroyHeight
        workspace.FallenPartsDestroyHeight = 0/0
        local BV = Instance.new("BodyVelocity")
        BV.Parent = RootPart
        BV.Velocity = Vector3.new(-9e99, 9e99, -9e99)
        BV.MaxForce = Vector3.new(-9e9, 9e9, -9e9)
        local BodyGyro = Instance.new("BodyGyro")
        BodyGyro.CFrame = CFrame.new(RootPart.Position)
        BodyGyro.D = 9e8
        BodyGyro.MaxTorque = Vector3.new(-9e9, 9e9, -9e9)
        BodyGyro.P = -9e9
        local BodyPosition = Instance.new("BodyPosition")
        BodyPosition.Position = RootPart.Position
        BodyPosition.D = 9e8
        BodyPosition.MaxForce = Vector3.new(-9e9, 9e9, -9e9)
        BodyPosition.P = -9e9
        if TRootPart and THead then
            if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then
                wtf(THead)
            else
                wtf(TRootPart)
            end
        elseif TRootPart and not THead then
            wtf(TRootPart)
        elseif not TRootPart and THead then
            wtf(THead)
        end
        BV:Destroy()
        BodyGyro:Destroy()
        BodyPosition:Destroy()
        repeat
            if Character and Humanoid and RootPart and getgenv().OldPos then
                RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                Humanoid:ChangeState("GettingUp")
                for _, x in pairs(Character:GetDescendants()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            task.wait()
        until not flingActive or (RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25)
        workspace.FallenPartsDestroyHeight = previousDestroyHeight
    end
end

function yeet2(targetPlayer)
    local character = LocalPlayer.Character
    local targetCharacter = targetPlayer.Character
    if not character or not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") then
        return false
    end
    if character.HumanoidRootPart.Velocity.Magnitude < 50 then
        getgenv().OldPos = character.HumanoidRootPart.CFrame
    end
    local existingForce = character.HumanoidRootPart:FindFirstChild("YeetForce")
    if existingForce then
        existingForce:Destroy()
    end
    local Thrust = Instance.new('BodyThrust', character.HumanoidRootPart)
    Thrust.Force = Vector3.new(9999, 9999, 9999)
    Thrust.Name = "YeetForce"
    local previousDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0/0
    local startTime = tick()
    local duration = (currentInput == "all" or currentInput == "nonfriends") and 5 or math.huge
    local yeetConnection
    yeetConnection = RunService.Heartbeat:Connect(function()
        if not targetCharacter or not targetCharacter:FindFirstChild("HumanoidRootPart") or not flingActive or tick() > startTime + duration then
            yeetConnection:Disconnect()
            Thrust:Destroy()
            workspace.FallenPartsDestroyHeight = previousDestroyHeight
            if character and character.HumanoidRootPart and getgenv().OldPos then
                character.HumanoidRootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                character.Humanoid:ChangeState("GettingUp")
                for _, x in pairs(character:GetDescendants()) do
                    if x:IsA("BasePart") then
                        x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new()
                    end
                end
            end
            return
        end
        local targetHRP = targetCharacter.HumanoidRootPart
        local targetVelocity = targetHRP.Velocity
        local speed = targetVelocity.Magnitude
        local direction = targetVelocity.Unit
        local offsetPosition
        if speed > 0.1 then
            offsetPosition = targetHRP.Position + (direction * speed)
        else
            offsetPosition = targetHRP.Position + Vector3.new(0, 0, 0)
        end
        character.HumanoidRootPart.CFrame = CFrame.new(offsetPosition)
        Thrust.Location = targetHRP.Position
    end)
    return true
end

function flingPlayers2()
    local players = {}
    for player, _ in pairs(processedPlayers) do
        if player and player.Character and player.Character.Parent ~= nil then
            table.insert(players, player)
        end
    end
    if currentInput == "all" or currentInput == "nonfriends" then
        players = sortPlayersAlphabetically2(players)
    end
    for _, player in ipairs(players) do
        if not flingActive then break end
        if player and player.Character and player.Character.Parent ~= nil then
            local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
            if flingMode == 1 then
                SkidFling2(player, duration)
            elseif flingMode == 2 then
                shhhlol2(player)
            elseif flingMode == 3 then
                yeet2(player)
                if currentInput == "all" or currentInput == "nonfriends" then
                    task.wait(1.5)
                end
            end
        end
    end
    if flingActive then
        task.wait()
        flingPlayers2()
    end
end

function addPlayerToProcessed2(player)
    if not player or player == LocalPlayer then return end
    local matchesFilter = false
    local input = string.lower(currentInput)
    if input == "all" then
        matchesFilter = true
    elseif input == "nonfriends" then
        local success, isFriend = pcall(function()
            return player:IsFriendsWith(LocalPlayer.UserId)
        end)
        matchesFilter = not (success and isFriend)
    else
        local searchTerms = {}
        for term in string.gmatch(input, "([^,]+)") do
            term = string.match(term, "^%s*(.-)%s*$")
            if term ~= "" then
                table.insert(searchTerms, term)
            end
        end
        local playerName = string.lower(player.Name)
        local displayName = player.DisplayName and string.lower(player.DisplayName) or ""
        for _, term in ipairs(searchTerms) do
            if string.find(playerName, term) or string.find(displayName, term) then
                matchesFilter = true
                break
            end
        end
    end
    if matchesFilter then
        processedPlayers[player] = true
    end
end

local flingInputValue = ""

Tabs.Utility:Space()

FlingInput = Tabs.Utility:Input({
    Title = "Fling Target",
    Flag = "FlingInput",
    Placeholder = "nickname, all, nonfriends",
    Callback = function(value)
        flingInputValue = value
        currentInput = string.lower(value)
    end
})

FlingModeDropdown = Tabs.Utility:Dropdown({
    Title = "Fling Mode",
    Flag = "FlingModeDropdown",
    Values = {"SkidFling", "Shhhlol", "Yeet"},
    Value = "SkidFling",
    Callback = function(value)
        if value == "SkidFling" then
            flingMode = 1
        elseif value == "Shhhlol" then
            flingMode = 2
        elseif value == "Yeet" then
            flingMode = 3
        end
    end
})

FlingToggle = Tabs.Utility:Toggle({
    Title = "Fling Players",
    Flag = "FlingToggle",
    Value = false,
    Callback = function(state)
        flingActive = state
        if flingActive then
            currentInput = string.lower(flingInputValue or "")
            local players = getPlayers2(currentInput)
            if #players == 0 then
                WindUI:Notify({
                    Title = "Fling Target",
                    Content = "Invalid Input: " .. currentInput,
                    Duration = 3
                })
                flingActive = false
                FlingToggle:Set(false)
                return
            end
            processedPlayers = {}
            for _, player in ipairs(players) do
                addPlayerToProcessed2(player)
            end
            WindUI:Notify({
                Title = "Fling Target",
                Content = "Flinging " .. #players .. " players",
                Duration = 3
            })
            coroutine.wrap(flingPlayers2)()
        else
            processedPlayers = {}
        end
    end
})

Players.PlayerAdded:Connect(function(player)
    if flingActive then
        addPlayerToProcessed2(player)
        if player.Character then
            if flingMode == 1 then
                local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                SkidFling2(player, duration)
            elseif flingMode == 2 then
                shhhlol2(player)
            elseif flingMode == 3 then
                yeet2(player)
            end
        else
            player.CharacterAdded:Connect(function()
                if flingActive then
                    addPlayerToProcessed2(player)
                    if flingMode == 1 then
                        local duration = (currentInput == "all" or currentInput == "nonfriends") and 1.5 or nil
                        SkidFling2(player, duration)
                    elseif flingMode == 2 then
                        shhhlol2(player)
                    elseif flingMode == 3 then
                        yeet2(player)
                    end
                end
            end)
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flingActive then
        task.wait(1)
        coroutine.wrap(flingPlayers2)()
    end
end)

Tabs.Utility:Space()

Tabs.Utility:Button({
    Title = "Fire Parts Tool",
    Callback = function()
        loadstring(game:HttpGet("https://glot.io/snippets/h9wgykubaz/raw/FireParts.lua"))()
    end
})

Tabs.Utility:Space()

Tabs.Utility:Button({
    Title = "Insta Proximity Prompt",
    Callback = function()
        for _,b in ipairs(game:GetDescendants()) do if b:IsA("ProximityPrompt") then b.HoldDuration=0 end end 
        game.DescendantAdded:Connect(function(c) if c:IsA("ProximityPrompt") then c.HoldDuration=0 end end)
    end
})

Tabs.Utility:Space()

local antiFlingEnabled = false
local antiFlingConnection = nil

function setCanCollideOfModelDescendants(model, bval)
    if not model then return end
    for _, v in pairs(model:GetDescendants()) do
        if v:IsA("BasePart") then
            v.CanCollide = bval
        end
    end
end

function startAntiFling()
    if antiFlingConnection then return end
    antiFlingConnection = RunService.Stepped:Connect(function()
        if antiFlingEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    setCanCollideOfModelDescendants(player.Character, false)
                end
            end
        end
    end)
end

function stopAntiFling()
    if antiFlingConnection then
        antiFlingConnection:Disconnect()
        antiFlingConnection = nil
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            setCanCollideOfModelDescendants(player.Character, true)
        end
    end
end

Tabs.Utility:Space()

AntiFlingToggle = Tabs.Utility:Toggle({
    Title = "Disable Player Collisions",
    Flag = "AntiFlingToggle",
    Value = false,
    Callback = function(state)
        antiFlingEnabled = state
        if state then
            startAntiFling()
        else
            stopAntiFling()
        end
    end
})

local HitboxSettings = {
    Enabled = false,  
    Size = 10,
    ShowVisual = false,   
    VisualColor = Color3.new(1, 0, 0),  
    OriginalSizes = {},   
    VisualAdornments = {} 
}

local function ExpandHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local chr = plr.Character
            if chr and HitboxSettings.Enabled then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root then
                    if HitboxSettings.OriginalSizes[plr] == nil then
                        HitboxSettings.OriginalSizes[plr] = root.Size
                    end
                    root.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                end
            end
        end
    end
end

local function UpdateVisualHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local chr = plr.Character
            local visual = HitboxSettings.VisualAdornments[plr]
            if chr and HitboxSettings.ShowVisual and HitboxSettings.Enabled then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root then
                    if not visual then
                        visual = Instance.new("BoxHandleAdornment")
                        visual.Adornee = root
                        visual.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                        visual.Color3 = HitboxSettings.VisualColor
                        visual.Transparency = 0.3
                        visual.ZIndex = 10
                        visual.AlwaysOnTop = true
                        visual.Parent = root
                        HitboxSettings.VisualAdornments[plr] = visual
                    else
                        visual.Size = Vector3.new(HitboxSettings.Size, HitboxSettings.Size, HitboxSettings.Size)
                        visual.Color3 = HitboxSettings.VisualColor
                    end
                end
            elseif visual then
                visual:Destroy()
                HitboxSettings.VisualAdornments[plr] = nil
            end
        end
    end
end

local function ResetHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local chr = plr.Character
            if chr then
                local root = chr:FindFirstChild("HumanoidRootPart")
                if root and HitboxSettings.OriginalSizes[plr] then
                    root.Size = HitboxSettings.OriginalSizes[plr]
                elseif root then
                    root.Size = Vector3.new(3, 3, 3) 
                end
            end
        end
    end
    HitboxSettings.OriginalSizes = {}
end

local function ClearVisualAdornments()
    for _, visual in pairs(HitboxSettings.VisualAdornments) do
        if visual then
            pcall(function() visual:Destroy() end)
        end
    end
    HitboxSettings.VisualAdornments = {}
end

Players.PlayerAdded:Connect(function(plr)
    if HitboxSettings.Enabled then
        task.wait(0.5)
        ExpandHitboxes()
        if HitboxSettings.ShowVisual then
            UpdateVisualHitboxes()
        end
    end
    plr.CharacterAdded:Connect(function()
        if HitboxSettings.Enabled then
            task.wait(0.5)
            ExpandHitboxes()
            if HitboxSettings.ShowVisual then
                UpdateVisualHitboxes()
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    HitboxSettings.OriginalSizes[plr] = nil
    if HitboxSettings.VisualAdornments[plr] then
        HitboxSettings.VisualAdornments[plr]:Destroy()
        HitboxSettings.VisualAdornments[plr] = nil
    end
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function()
            if HitboxSettings.Enabled then
                task.wait(0.5)
                ExpandHitboxes()
                if HitboxSettings.ShowVisual then
                    UpdateVisualHitboxes()
                end
            end
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if HitboxSettings.Enabled then
        ExpandHitboxes()
        if HitboxSettings.ShowVisual then
            UpdateVisualHitboxes()
        end
    end
end)

Tabs.Utility:Space()

Tabs.Utility:Toggle({
    Title = "Hitbox Expanding",
    Callback = function(state)
        HitboxSettings.Enabled = state
        if state then
            ExpandHitboxes()
            if HitboxSettings.ShowVisual then
                UpdateVisualHitboxes()
            end
        else
            ResetHitboxes()
            ClearVisualAdornments()
        end
    end
})

Tabs.Utility:Slider({
    Title = "Hitbox Size",
    Value = {Min = 3, Max = 30, Default = 10},
    Callback = function(val)
        HitboxSettings.Size = val
        if HitboxSettings.Enabled then
            ExpandHitboxes()
            if HitboxSettings.ShowVisual then
                UpdateVisualHitboxes()
            end
        end
    end
})

Tabs.Utility:Toggle({
    Title = "Show Hitbox",
    Type = "Checkbox",
    Callback = function(state)
        HitboxSettings.ShowVisual = state
        if state and HitboxSettings.Enabled then
            UpdateVisualHitboxes()
        elseif not state then
            ClearVisualAdornments()
        end
    end
})

Tabs.Utility:Colorpicker({
    Title = "Hitbox Color",
    Default = Color3.new(1, 0, 0),
    Callback = function(col)
        HitboxSettings.VisualColor = col
        if HitboxSettings.ShowVisual and HitboxSettings.Enabled then
            UpdateVisualHitboxes()
        end
    end
})

Tabs.Utility:Space()

if _G.a then
    local v1, v2, v3 = pairs(_G.a)
    while true do
        local v4
        v3, v4 = v1(v2, v3)
        if v3 == nil then
            break
        end
        v4:Disconnect()
    end
    _G.a = nil
end

repeat
    task.wait()
until LocalPlayer

vu5 = LocalPlayer
vu6 = nil
vu7 = nil
vu8 = nil
vu9 = false
vu10 = {}

function vu16()
    vu6 = vu5.Character or vu5.CharacterAdded:Wait()
    vu7 = vu6:WaitForChild("Humanoid")
    vu8 = vu6:WaitForChild("HumanoidRootPart")
    vu10 = {}
    local v11 = vu6
    local v12, v13, v14 = pairs(v11:GetDescendants())
    while true do
        v15 = nil
        v14, v15 = v12(v13, v14)
        if v14 == nil then
            break
        end
        if v15:IsA("BasePart") and v15.Transparency == 0 then
            vu10[#vu10 + 1] = v15
        end
    end
end

function vu30()
    toggleElement = ButtonLib.Create:Toggle({
        Text = "INVISIBLE",
        Flag = "InvisibleToggle",
        Default = false,
        Visible = false,
        Callback = function(state)
            vu9 = state
            if vu9 then
                local v26, v27, v28 = pairs(vu10)
                while true do
                    v29 = nil
                    v28, v29 = v26(v27, v28)
                    if v28 == nil then
                        break
                    end
                    v29.Transparency = v29.Transparency == 0 and 0.5 or 0
                end
            else
                local v26, v27, v28 = pairs(vu10)
                while true do
                    v29 = nil
                    v28, v29 = v26(v27, v28)
                    if v28 == nil then
                        break
                    end
                    v29.Transparency = 0
                end
            end
        end
    })
    toggleElement.Position = UDim2.new(0.5, -125, 0.12, 0)
    _G.InvisibleToggleElement = toggleElement
end

vu16()
vu30()

v31 = {
    nil,
    nil
}
v32 = vu5

v31[1] = vu5:GetMouse().KeyDown:Connect(function(p33)
    if p33 == "i" then
        vu9 = not vu9
        if ButtonLib and ButtonLib.InvisibleToggle then
            ButtonLib.InvisibleToggle:Set(vu9)
        end
        local v34, v35, v36 = pairs(vu10)
        while true do
            v37 = nil
            v36, v37 = v34(v35, v36)
            if v36 == nil then
                break
            end
            if vu9 then
                v37.Transparency = v37.Transparency == 0 and 0.5 or 0
            else
                v37.Transparency = 0
            end
        end
    end
end)

v31[2] = RunService.Heartbeat:Connect(function()
    if vu9 then
        v38 = vu8.CFrame
        v39 = vu7.CameraOffset
        v40 = v38 * CFrame.new(0, 500000, 0)
        v42 = vu8
        v43 = v40:ToObjectSpace(CFrame.new(v38.Position)).Position
        v42.CFrame = v40
        vu7.CameraOffset = v43
        RunService.RenderStepped:Wait()
        vu8.CFrame = v38
        vu7.CameraOffset = v39
    end
end)

vu5.CharacterAdded:Connect(function()
    vu9 = false
    if ButtonLib and ButtonLib.InvisibleToggle then
        ButtonLib.InvisibleToggle:Set(false)
    end
    vu16()
end)

Tabs.Utility:Space()

InvisibleGuiToggle = Tabs.Utility:Toggle({
    Title = "Invisible GUI",
    Flag = "InvisibleGuiToggle",
    Value = false,
    Callback = function(state)
        if ButtonLib and ButtonLib.InvisibleToggle then
            ButtonLib.InvisibleToggle:SetVisible(state)
        end
    end
})

function enableAntiVoid()
    if antiVoidActive then return end
    antiVoidActive = true
    originalDestroyHeight = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = -math.huge
end

function disableAntiVoid()
    if not antiVoidActive then return end
    workspace.FallenPartsDestroyHeight = originalDestroyHeight
    antiVoidActive = false
end

Tabs.Utility:Space()

Tabs.Utility:Toggle({
    Title = "Anti Void Damage",
    Value = false,
    Callback = function(state)
        if state then
            enableAntiVoid()
        else
            disableAntiVoid()
        end
    end
})

Tabs.Utility:Space()

NoRenderToggle = Tabs.Utility:Toggle({
    Title = "No Render",
    Flag = "NoRenderToggle",
    Desc = "Disable 3D rendering for performance",
    Value = false,
    Callback = function(state)
        NoRender = state
        RunService:Set3dRenderingEnabled(not state)
        if state then
            local gui = Instance.new("ScreenGui")
            gui.Name = "NoRenderBackground"
            gui.IgnoreGuiInset = true
            gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            gui.ResetOnSpawn = false
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = NoRenderColor
            frame.BorderSizePixel = 0
            frame.Parent = gui
            gui.Parent = PlayerGui
        else
            local gui = PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                gui:Destroy()
            end
        end
    end
})

Tabs.Utility:Space()

NoRenderColorPicker = Tabs.Utility:Colorpicker({
    Title = "No Render Color",
    Flag = "NoRenderColorPicker",
    Desc = "Choose background color when No Render is enabled",
    Default = Color3.fromRGB(0, 0, 0),
    Transparency = 0,
    Callback = function(color)
        NoRenderColor = color
        if NoRender then
            local gui = PlayerGui:FindFirstChild("NoRenderBackground")
            if gui then
                local frame = gui:FindFirstChildOfClass("Frame")
                if frame then
                    frame.BackgroundColor3 = color
                end
            end
        end
    end
})

RemoveTextures = false

Tabs.Utility:Space()

RemoveTexturesButton = Tabs.Utility:Button({
    Title = "Remove Textures",
    Callback = function()
        for _, part in ipairs(workspace:GetDescendants()) do
            if part:IsA("Part") or part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("WedgePart") or part:IsA("CornerWedgePart") then
                if part:IsA("Part") then
                    part.Material = Enum.Material.SmoothPlastic
                end
                if part:FindFirstChildWhichIsA("Texture") then
                    local texture = part:FindFirstChildWhichIsA("Texture")
                    texture.Texture = "rbxassetid://0"
                end
                if part:FindFirstChildWhichIsA("Decal") then
                    local decal = part:FindFirstChildWhichIsA("Decal")
                    decal.Texture = "rbxassetid://0"
                end
            end
        end
    end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == LocalPlayer then
        RunService:Set3dRenderingEnabled(true)
    end
end)

Tabs.Utility:Space()

LowQualityButton = Tabs.Utility:Button({
    Title = "Low Quality",
    Desc = "Disable textures, effects, and optimize graphics",
    Callback = function()
        local ToDisable = {
            Textures = true,
            VisualEffects = true,
            Parts = true,
            Particles = true,
            Sky = true
        }
    end
})

lagSwitchEnabled = false
lagDuration = 0.5
lagMethod = "CPU Cycle"
local isLagActive = false
local lagSystemLoaded = false

function lag()
    local duration = lagDuration or 0.5
    local method = lagMethod or "CPU Cycle"
    if method == "CPU Cycle" then pcall(function() setfflag("MaxMissedWorldStepsRemembered","1") end)
    local start = tick()
    while tick() - start < duration do
        local a = math.random(1, 1000000) * math.random(1, 1000000)
        a = a / math.random(1, 10000)
    end
    elseif method == "OS.ClockFFlag" then
    pcall(function() setfflag("MaxMissedWorldStepsRemembered","10000001000000") end)
    local start = os.clock()
    while os.clock() - start < duration do
    end
    end
end

function loadLagSystem()
    if lagSystemLoaded then return end
    lagSystemLoaded = true
end

function unloadLagSystem()
    if not lagSystemLoaded then return end
    lagSystemLoaded = false
    isLagActive = false
end

function checkLagState()
    local shouldLoad = lagSwitchEnabled
    if shouldLoad and not lagSystemLoaded then
        loadLagSystem()
    elseif not shouldLoad and lagSystemLoaded then
        unloadLagSystem()
    end
end

Tabs.Utility:Space()

ButtonLib.Create:Button({
    Text = "Lag Switch",
    Flag = "LagSwitch",
    Visible = false,
    Callback = function()
        isLagActive = task.spawn(lag)
    end
}).Position = UDim2.new(0.5, -125, 0.2, 0)

LagSwitchToggle = Tabs.Utility:Toggle({
    Title = "Lag Switch",
    Flag = "LagSwitchToggle",
    Icon = "zap",
    Value = false,
    Callback = function(state)
        lagSwitchEnabled = state
        if ButtonLib and ButtonLib.LagSwitch then
            ButtonLib.LagSwitch:SetVisible(state)
        end
        checkLagState()
    end
})

LagMethodDropdown = Tabs.Utility:Dropdown({
    Title = "Lag Method",
    Flag = "LagMethodDropdown",
    Values = {"CPU Cycle", "OS.ClockFFlag"},
    Value = "CPU Cycle",
    Callback = function(value)
        lagMethod = value
    end
})

LagDurationInput = Tabs.Utility:Input({
    Title = "Lag Duration (seconds)",
    Flag = "LagDurationInput",
    Placeholder = "0.5",
    Value = tostring(lagDuration),
    NumbersOnly = true,
    Callback = function(text)
        local n = tonumber(text)
        if n and n > 0 then
            lagDuration = n
        end
    end
})

Players.PlayerRemoving:Connect(function(leavingPlayer)
    if leavingPlayer == LocalPlayer then
        unloadLagSystem()
    end
end)

checkLagState()

Tabs.Utility:Space()

TimeChangerInput = Tabs.Utility:Input({
    Title = "Set Time (HH:MM)",
    Flag = "TimeChangerInput",
    Placeholder = "12:00",
    Callback = function(value)
        value = value:gsub("^%s*(.-)%s*$", "%1")
        local h_str, m_str = value:match("(%d+):(%d+)")
        if h_str and m_str then
            local h = tonumber(h_str)
            local m = tonumber(m_str)
            if h and m and h >= 0 and h <= 23 and m >= 0 and m <= 59 and #h_str <= 2 and #m_str <= 2 then
                local totalHours = h + (m / 60)
                Lighting.ClockTime = totalHours
            end
        end
    end
})

Tabs.Teleport:Section({ Title = "Teleports", TextSize = 20 })
Tabs.Teleport:Divider()
Tabs.Teleport:Space()

Tabs.Teleport:Button({
    Title = "Teleport to Spawn",
    Desc = "Teleport to a random spawn location",
    Icon = "home",
    Callback = function()
        local spawnLocations = {}
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "SpawnLocation" and obj:IsA("SpawnLocation") then
                table.insert(spawnLocations, obj)
            elseif obj.Name == "Spawn" and (obj:IsA("Part") or obj:IsA("BasePart")) then
                table.insert(spawnLocations, obj)
            end
        end
        if #spawnLocations > 0 then
            local randomSpawn = spawnLocations[math.random(1, #spawnLocations)]
            local character = LocalPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = randomSpawn.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

Tabs.Teleport:Space()

Tabs.Teleport:Button({
    Title = "Teleport to Random Player",
    Desc = "Teleport to a random online player",
    Icon = "users",
    Callback = function()
        local players = Players:GetPlayers()
        local validPlayers = {}
        for _, plr in ipairs(players) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(validPlayers, plr)
            end
        end
        if #validPlayers > 0 then
            local randomPlayer = validPlayers[math.random(1, #validPlayers)]
            local character = LocalPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                humanoidRootPart.CFrame = randomPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
})

local playerList = {}

Tabs.Teleport:Space()

PlayerDropdown = Tabs.Teleport:Dropdown({
    Title = "Select Player",
    Flag = "PlayerDropdown",
    Values = {{Title = "No players found", Desc = "", Icon = "user"}},
    Value = "No players found",
    Callback = function(selectedOption)
    end
})

function updatePlayerList()
    playerList = {}
    local players = Players:GetPlayers()
    local dropdownValues = {}
    for _, plr in ipairs(players) do
        if plr ~= LocalPlayer then
            table.insert(playerList, plr)
            local success, content = pcall(function()
                return Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
            end)
            local iconUrl = success and content or "user"
            table.insert(dropdownValues, {
                Title = plr.DisplayName,
                Desc = "@" .. plr.Name,
                Icon = iconUrl
            })
        end
    end
    if #dropdownValues == 0 then
        dropdownValues = {{Title = "No players found", Desc = "", Icon = "user"}}
    end
    PlayerDropdown:Refresh(dropdownValues, true)
end

updatePlayerList()
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)

Tabs.Teleport:Button({
    Title = "Teleport to Selected Player",
    Desc = "Teleport to the player selected in dropdown",
    Icon = "user",
    Callback = function()
        local selectedOption = PlayerDropdown.Value
        if selectedOption and selectedOption.Title ~= "No players found" then
            for _, plr in ipairs(playerList) do
                if plr.DisplayName == selectedOption.Title or plr.Name == selectedOption.Title then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local character = LocalPlayer.Character
                        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                        if humanoidRootPart then
                            humanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        end
                    end
                    break
                end
            end
        end
    end
})

local Troll = loadstring(game:HttpGet("https://darahub.pages.dev/Module/Troll-Stuffs.lua"))()
Troll(Tabs)

Tabs.Settings:Section({ Title = "Config Manager", TextSize = 20 })
Tabs.Settings:Divider()

local ConfigManager = Window.ConfigManager
local CurrentConfigName = "default"
local AutoLoadConfig = "default"
local AutoLoadEnabled = false
local AutoSaveEnabled = false
local ConfigListDropdown = nil
local AutoSaveConnection = nil

function FileExists(path)
    if isfile then
        return pcall(readfile, path)
    end
    return false
end

function WriteFile(path, content)
    if writefile then
        return pcall(writefile, path, content)
    end
    return false
end

function ReadFile(path)
    if readfile then
        local success, content = pcall(readfile, path)
        if success then
            return content
        end
    end
    return ""
end

function loadAutoLoadSettings()
    local autoLoadFile = "Darahub/AutoLoad/Game/Universal/AutoLoad.json"
    if FileExists(autoLoadFile) then
        local content = ReadFile(autoLoadFile)
        if content ~= "" then
            local success, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if success and data then
                AutoLoadConfig = data.configName or "default"
                AutoLoadEnabled = data.enabled or false
                return true
            end
        end
    end
    AutoLoadConfig = "default"
    AutoLoadEnabled = false
    return false
end

function saveAutoLoadSettings()
    local autoLoadFile = "Darahub/AutoLoad/Game/Universal/AutoLoad.json"
    local success = WriteFile(autoLoadFile, "")
    if not success then
        if makefolder then
            pcall(function() makefolder("Darahub") end)
            pcall(function() makefolder("Darahub/AutoLoad") end)
            pcall(function() makefolder("Darahub/AutoLoad/Game") end)
            pcall(function() makefolder("Darahub/AutoLoad/Game/Universal") end)
        end
    end
    local data = {
        enabled = AutoLoadEnabled,
        configName = AutoLoadConfig
    }
    local success, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if success then
        WriteFile(autoLoadFile, json)
    end
end

loadAutoLoadSettings()

ConfigNameInput = Tabs.Settings:Input({
    Title = "Config Name",
    Flag = "ConfigNameInput",
    Desc = "Name for your config file",
    Icon = "file-cog",
    Placeholder = "default",
    Value = CurrentConfigName,
    Callback = function(value)
        if value ~= "" then
            CurrentConfigName = value
        end
    end
})

Tabs.Settings:Space()

AutoLoadToggle = Tabs.Settings:Toggle({
    Title = "Auto Load",
    Flag = "AutoLoadToggle",
    Desc = "Automatically load this config when script starts",
    Value = AutoLoadEnabled,
    Callback = function(state)
        AutoLoadEnabled = state
        if state then
            AutoLoadConfig = CurrentConfigName
            WindUI:Notify({
                Title = "Auto-Load",
                Content = "Config '" .. CurrentConfigName .. "' will load automatically on startup",
                Duration = 3
            })
        end
        saveAutoLoadSettings()
    end
})

AutoSaveToggle = Tabs.Settings:Toggle({
    Title = "Auto Save",
    Flag = "AutoSaveToggle",
    Desc = "Automatically save changes to config every second",
    Value = AutoSaveEnabled,
    Callback = function(state)
        AutoSaveEnabled = state
        if AutoSaveConnection then
            AutoSaveConnection:Disconnect()
            AutoSaveConnection = nil
        end
        if state then
            WindUI:Notify({
                Title = "Auto-Save",
                Content = "Config will save automatically every second",
                Duration = 2
            })
            AutoSaveConnection = RunService.Heartbeat:Connect(function()
                if AutoSaveEnabled and CurrentConfigName ~= "" then
                    task.spawn(function()
                        Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
                        Window.CurrentConfig:Save()
                    end)
                end
                task.wait(1)
            end)
        else
            WindUI:Notify({
                Title = "Auto-Save",
                Content = "Auto-save disabled",
                Duration = 2
            })
        end
    end
})

Tabs.Settings:Space()

function refreshConfigList()
    local allConfigs = ConfigManager:AllConfigs() or {}
    if not table.find(allConfigs, "default") then
        local defaultConfig = ConfigManager:Config("default")
        if defaultConfig and defaultConfig.Save then
            defaultConfig:Save()
        end
        table.insert(allConfigs, 1, "default")
    end
    table.sort(allConfigs, function(a, b)
        return a:lower() < b:lower()
    end)
    local defaultValue = table.find(allConfigs, CurrentConfigName) and CurrentConfigName or "default"
    if ConfigListDropdown and ConfigListDropdown.Refresh then
        ConfigListDropdown:Refresh(allConfigs, defaultValue)
    end
end

ConfigListDropdown = Tabs.Settings:Dropdown({
    Title = "Existing Configs",
    Flag = "ConfigListDropdown",
    Desc = "Select from saved configs",
    Values = {"default"},
    Value = "default",
    Callback = function(value)
        CurrentConfigName = value
        ConfigNameInput:Set(value)
        if AutoLoadEnabled then
            AutoLoadConfig = value
            saveAutoLoadSettings()
        end
        local config = ConfigManager:GetConfig(value)
        if config then
            WindUI:Notify({
                Title = "Config Selected",
                Content = "Config '" .. value .. "' selected",
                Duration = 2
            })
        end
    end
})

Tabs.Settings:Space()

SaveConfigButton = Tabs.Settings:Button({
    Title = "Save Config",
    Desc = "Save current settings to config",
    Icon = "save",
    Callback = function()
        if CurrentConfigName == "" then
            WindUI:Notify({
                Title = "Error",
                Content = "Please enter a config name",
                Duration = 3
            })
            return
        end
        Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
        local success = Window.CurrentConfig:Save()
        if success then
            WindUI:Notify({
                Title = "Config Saved",
                Content = "Config '" .. CurrentConfigName .. "' saved successfully",
                Duration = 3
            })
            if AutoLoadEnabled then
                AutoLoadConfig = CurrentConfigName
                saveAutoLoadSettings()
            end
            task.wait(0.5)
            refreshConfigList()
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Failed to save config",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Space()

LoadConfigButton = Tabs.Settings:Button({
    Title = "Load Config",
    Desc = "Load settings from selected config",
    Icon = "folder-open",
    Callback = function()
        if CurrentConfigName == "" then
            WindUI:Notify({
                Title = "Error",
                Content = "Please enter a config name",
                Duration = 3
            })
            return
        end
        Window.CurrentConfig = ConfigManager:CreateConfig(CurrentConfigName)
        local success = Window.CurrentConfig:Load()
        if success then
            WindUI:Notify({
                Title = "Config Loaded",
                Content = "Config '" .. CurrentConfigName .. "' loaded successfully",
                Duration = 3
            })
            if AutoLoadEnabled then
                AutoLoadConfig = CurrentConfigName
                saveAutoLoadSettings()
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Config '" .. CurrentConfigName .. "' not found or empty",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Space()

DeleteConfigButton = Tabs.Settings:Button({
    Title = "Delete Config",
    Desc = "Delete selected config",
    Icon = "trash-2",
    Color = Color3.fromHex("#ff4830"),
    Callback = function()
        if CurrentConfigName == "default" then
            WindUI:Notify({
                Title = "Error",
                Content = "Cannot delete default config",
                Duration = 3
            })
            return
        end
        local success = ConfigManager:DeleteConfig(CurrentConfigName)
        if success then
            WindUI:Notify({
                Title = "Config Deleted",
                Content = "Config '" .. CurrentConfigName .. "' deleted",
                Duration = 3
            })
            CurrentConfigName = "default"
            ConfigNameInput:Set("default")
            if AutoLoadEnabled then
                AutoLoadConfig = "default"
                saveAutoLoadSettings()
            end
            task.wait(0.5)
            refreshConfigList()
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Failed to delete config or config doesn't exist",
                Duration = 3
            })
        end
    end
})

Tabs.Settings:Space()

RefreshConfigButton = Tabs.Settings:Button({
    Title = "Refresh Config List",
    Desc = "Update the list of available configs",
    Icon = "refresh-cw",
    Callback = function()
        refreshConfigList()
        WindUI:Notify({
            Title = "Config List Refreshed",
            Content = "Config list updated",
            Duration = 2
        })
    end
})

task.spawn(function()
    task.wait(0.5) 
    refreshConfigList()
    ConfigNameInput:Set("default")
    if AutoLoadEnabled then
        CurrentConfigName = AutoLoadConfig
        ConfigNameInput:Set(CurrentConfigName)
        task.wait(1)
        Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
        if Window.CurrentConfig:Load() then
            WindUI:Notify({
                Title = "Auto-Loaded",
                Content = "Config '" .. CurrentConfigName .. "' loaded automatically",
                Duration = 3
            })
        end
    end
end)

if AutoSaveEnabled then
    task.spawn(function()
        task.wait(1)
        if AutoSaveEnabled then
            AutoSaveConnection = RunService.Heartbeat:Connect(function()
                if AutoSaveEnabled and CurrentConfigName ~= "" then
                    task.spawn(function()
                        Window.CurrentConfig = ConfigManager:Config(CurrentConfigName)
                        Window.CurrentConfig:Save()
                    end)
                end
                task.wait(1)
            end)
        end
    end)
end

Tabs.Settings:Section({ Title = "Personalize", TextSize = 20 })
Tabs.Settings:Divider()

themes = {}
availableThemes = WindUI:GetThemes()
for themeName, _ in pairs(availableThemes) do
    table.insert(themes, themeName)
end
table.sort(themes)

ThemeDropdown = Tabs.Settings:Dropdown({
    Title = "Select Theme",
    Flag = "ThemeDropdown",
    Values = themes,
    SearchBarEnabled = true,
    MenuWidth = 280,
    Value = themes[1],
    Callback = function(theme)
        WindUI:SetTheme(theme)
    end
})

TransparencySlider = Tabs.Settings:Slider({
    Title = "Window Transparency",
    Step = 0.01,
    Flag = "TransparencySlider",
    Value = { Min = 0, Max = 1, Default = WindUI.TransparencyValue },
    Callback = function(value)
        WindUI.TransparencyValue = tonumber(value)
        Window:ToggleTransparency(tonumber(value) > 0)
    end
})

Tabs.Settings:Section({ Title = "Keybinds" })

Tabs.Settings:Keybind({
    Flag = "Keybind",
    Title = "Keybind",
    Desc = "Keybind to open ui",
    Value = "RightControl",
    Callback = function(RightControl)
        Window:SetToggleKey(Enum.KeyCode[RightControl])
    end
})

Tabs.Settings:Space()

SpeedGlitchKeybind = Tabs.Settings:Keybind({
    Title = "Speed Glitch Toggle",
    Desc = "Keybind to toggle Speed Glitch",
    Value = "",
    Flag = "SpeedGlitchKeybind",
    Callback = function(v)
        if SpeedGlitchToggle then
            SpeedGlitchToggle:Set(not SpeedGlitchToggle.Value)
        end
    end
})

Tabs.Settings:Space()

FlyTogglekeybind = Tabs.Settings:Keybind({
    Title = "Fly Toggle",
    Desc = "Keybind to toggle Fly",
    Value = "",
    Flag = "FlyTogglekeybind",
    Callback = function(v)
        FlyToggle:Set(not FlyToggle.Value)
    end
})

Tabs.Settings:Space()

VehicleFlyTogglekeybind = Tabs.Settings:Keybind({
    Title = "Fly Toggle",
    Desc = "Keybind to toggle Fly",
    Value = "",
    Flag = "VehicleFlyTogglekeybind",
    Callback = function(v)
        VehicleFlyToggle:Set(not VehicleFlyToggle.Value)
    end
})

Tabs.Settings:Space()

Tabs.Settings:Keybind({
    Title = "Invisible Toggle",
    Desc = "Keybind to toggle invisible mode",
    Value = "I",
    Callback = function(v)
        vu9 = not vu9
        if ButtonLib and ButtonLib.InvisibleToggle then
            ButtonLib.InvisibleToggle:Set(vu9)
        end
        for _, part in pairs(vu10) do
            part.Transparency = vu9 and 0.5 or 0
        end
    end
})

LagSwitchKeybind = Tabs.Settings:Keybind({
    Title = "Trigger Lag Switch",
    Desc = "Keybind to trigger lag switch",
    Value = "L",
    Flag = "LagSwitchKeybind",
    Callback = function(v)
        if lagSwitchEnabled and not isLagActive then
            isLagActive = true
            task.spawn(function()
                lag()
                isLagActive = false
            end)
        end
    end
})

Tabs.Settings:Space()

GravityKeybind = Tabs.Settings:Keybind({
    Title = "Toggle Gravity",
    Desc = "Keybind to toggle custom gravity",
    Value = "J",
    Flag = "GravityKeybind",
    Callback = function(v)
        GravityToggle:Set(not GravityToggle.Value)
    end
})

do
    local DarahubFolder = CoreGui:FindFirstChild("Darahub")
    if DarahubFolder and Tabs and Tabs.Settings then
        Tabs.Settings:Section({
            Title = "GUI Size"
        })
        local defaultScales = {}
        for _, Element in pairs(DarahubFolder:GetChildren()) do
            if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
                defaultScales[Element.Name] = Element.UIScale.Scale
            end
        end
        Tabs.Settings:Button({
            Title = "Reset All Scales",
            Description = "Reverts all buttons to their startup scale values",
            Callback = function()
                for _, Element in pairs(DarahubFolder:GetChildren()) do
                    if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
                        local original = defaultScales[Element.Name] or 1
                        Element.UIScale.Scale = original
                    end
                end
            end
        })
        for _, Element in pairs(DarahubFolder:GetChildren()) do
            if Element:IsA("Frame") and Element:FindFirstChild("UIScale") then
                local currentScale = tonumber(Element.UIScale.Scale) or 1
                Tabs.Settings:Slider({
                    Title = Element.Name .. " Scale",
                    Desc = "Adjust GUI scale",
                    Flag = "Scale_Slider_" .. Element.Name,
                    Step = 0.01,
                    Value = {
                        Min = 0.01,
                        Max = 4,
                        Default = currentScale
                    },
                    Callback = function(val)
                        if Element and Element:FindFirstChild("UIScale") then
                            Element.UIScale.Scale = tonumber(val)
                        end
                    end
                })
            end
        end
    end
end

Tabs.Settings:Space()

local FPSCounter = CoreGui:FindFirstChild("FPSCounter")
if FPSCounter then
    FPSCounterToggle = Tabs.Settings:Toggle({
        Title = "Show FPS Counter",
        Flag = "FPSCounterToggle",
        Value = true,
        Callback = function(state)
            if FPSCounter then
                FPSCounter.Enabled = state
            else
                warn("Could Not Find \"FPSCounter\" in CoreGUI! Please Reload the script And try again.")
            end
        end
    })
else
    warn("No \"FPSCounter\" Found in CoreGUI")
end

Tabs.Settings:Section({ Title = "Sensitivity Controls", TextSize = 20 })
Tabs.Settings:Divider()

MouseSensitivityEnabled = false
MouseSensitivityValue = 1.0
MIN_SENSITIVITY = 0.1
MAX_SENSITIVITY = 20.0
DEFAULT_SENSITIVITY = 1.0
cameraInputModule = nil
mouseHookActive = false
touchHookActive = false

function setupSensitivityHook()
    if cameraInputModule then return true end
    local player = LocalPlayer
    local success = false
    pcall(function()
        local playerScripts = player:FindFirstChild("PlayerScripts")
        if not playerScripts then return end
        local playerModule = playerScripts:FindFirstChild("PlayerModule")
        if not playerModule then return end
        local cameraModule = playerModule:FindFirstChild("CameraModule")
        if cameraModule then
            local cameraInput = cameraModule:FindFirstChild("CameraInput")
            if cameraInput then
                cameraInputModule = require(cameraInput)
                if cameraInputModule and cameraInputModule.getRotation then
                    originalGetRotation = cameraInputModule.getRotation
                    cameraInputModule.getRotation = function(disableRotation)
                        local rotation = originalGetRotation(disableRotation)
                        local uis = UserInputService
                        if MouseSensitivityEnabled and uis.MouseEnabled then
                            return rotation * MouseSensitivityValue
                        elseif TouchSensitivityEnabled and uis.TouchEnabled then
                            return rotation * TouchSensitivityValue
                        end
                        return rotation
                    end
                    success = true
                end
            end
        end
    end)
    return success
end

MouseSensitivityToggle = Tabs.Settings:Toggle({
    Title = "Mouse Sensitivity",
    Flag = "MouseSensitivityToggle",
    Desc = "Adjust mouse sensitivity",
    Value = false,
    Callback = function(state)
        MouseSensitivityEnabled = state
        if state then
            if not setupSensitivityHook() then
                WindUI:Notify({
                    Title = "Mouse Sensitivity",
                    Content = "Failed to hook system. Try rejoining.",
                    Duration = 3
                })
                MouseSensitivityToggle:Set(false)
                MouseSensitivityEnabled = false
            end
        end
    end
})

MouseSensitivitySlider = Tabs.Settings:Slider({
    Title = "Mouse Sensitivity Value",
    Flag = "MouseSensitivitySlider",
    Desc = "Lower = slower, Higher = faster (Max: 20)",
    Value = { Min = 0.1, Max = 20, Default = 1.0 },
    Step = 0.1,
    Callback = function(value)
        MouseSensitivityValue = value
    end
})

Tabs.Settings:Space()

TouchSensitivityToggle = Tabs.Settings:Toggle({
    Title = "Touch Sensitivity",
    Flag = "TouchSensitivityToggle",
    Desc = "Adjust touch/mobile sensitivity",
    Value = false,
    Callback = function(state)
        TouchSensitivityEnabled = state
        if state then
            if not setupSensitivityHook() then
                WindUI:Notify({
                    Title = "Touch Sensitivity",
                    Content = "Failed to hook system. Try rejoining.",
                    Duration = 3
                })
                TouchSensitivityToggle:Set(false)
                TouchSensitivityEnabled = false
            end
        end
    end
})

TouchSensitivitySlider = Tabs.Settings:Slider({
    Title = "Touch Sensitivity Value",
    Flag = "TouchSensitivitySlider",
    Desc = "Lower = slower, Higher = faster (Max: 20)",
    Value = { Min = 0.1, Max = 20, Default = 1.0 },
    Step = 0.1,
    Callback = function(value)
        TouchSensitivityValue = value
    end
})

Tabs.Settings:Space()

Tabs.Settings:Section({ Title = "Reset Controls", TextSize = 20 })
Tabs.Settings:Divider()

Tabs.Settings:Button({
    Title = "Reset Sensitivity Settings",
    Desc = "Reset both mouse and touch sensitivity to defaults",
    Icon = "refresh-cw",
    Color = Color3.fromHex("#FF3030"),
    Callback = function()
        MouseSensitivityEnabled = false
        MouseSensitivityValue = DEFAULT_SENSITIVITY
        TouchSensitivityEnabled = false
        TouchSensitivityValue = DEFAULT_SENSITIVITY
        cameraInputModule = nil
        mouseHookActive = false
        touchHookActive = false
        if MouseSensitivityToggle then 
            MouseSensitivityToggle:Set(false) 
        end
        if MouseSensitivitySlider then 
            MouseSensitivitySlider:Set(1.0) 
        end
        if TouchSensitivityToggle then 
            TouchSensitivityToggle:Set(false) 
        end
        if TouchSensitivitySlider then 
            TouchSensitivitySlider:Set(1.0) 
        end
        WindUI:Notify({
            Title = "Sensitivity Reset",
            Content = "All sensitivity settings reset to default",
            Duration = 3
        })
    end
})

UniverseScriptsStuff = loadstring(game:HttpGet("https://darahub.pages.dev/Module/More-Scripts.Lua"))()
UniverseScriptsStuff(Tabs)`n]],
["https://darahub.pages.dev/main.lua"] = [[`n --[[
Why are you here skid? lil skido want the Source code. If u want Open Source script complete the ads first in Get Code Pages, or Execute the script if u have been completed the Ads, then navgate to Download folder youll have your own copy darahub. if u smart Use user agent to download
Bro thought try to skip ads like this will not gonna work :P
Go ahead and find the link if you wanna waste your time by open these links:D
] ]
loadstring(game:HttpGet("https://darahub.pages.dev/Module/Library/GUI/LoadAll.lua"))() -- load lib stuff
getgenv().LoaderChecked = true
loadstring(game:HttpGet("https://darahub.pages.dev/html/LuaLoadMainScript.html"))()











local maxDownloads = 99
local downloadFolder = "yoxi_temp/"
local savedFiles = {}

if makefolder and isfolder then
    if isfolder(downloadFolder) then
        if listfiles and delfile then
            local oldFiles = listfiles(downloadFolder)
            for _, file in ipairs(oldFiles) do
                delfile(file)
            end
        end
    else
        makefolder(downloadFolder)
    end
end

for i = 1, maxDownloads do
    local success, content = pcall(function()
        return game:HttpGet("https://yoxi-hub.fun/api/loader")
    end)
    
    if success and content and writefile then
        local filename = downloadFolder .. "loader_" .. i .. ".lua"
        writefile(filename, content)
        table.insert(savedFiles, filename)
    end
    
    wait(0.3)
end

wait(1)

for _, file in ipairs(savedFiles) do
    pcall(function() delfile(file) end)
    wait(0.1)
end

if delfolder and isfolder and listfiles then
    local remaining = listfiles(downloadFolder)
    if #remaining == 0 then
        pcall(function() delfolder(downloadFolder) end)
    end
end
`n]],
["https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua"] = [[`n--[[ v1.0.0 https://wearedevs.net/obfuscator ] ] return(function(...)local n={"\088\054\056\076\055\097\061\061","\075\121\090\050\108\116\061\061","\105\065\085\056";"\108\109\116\112";"\070\069\109\087","\116\078\067\108\071\083\116\100\108\073\103\113\049\087\099\072\089\113\099\087\077\083\061\061";"\118\111\067\076\070\108\109\050\053\116\061\061","\103\082\099\047","\099\052\101\109\111\071\086\057\055\074\080\054\090\081\118\074","\078\118\100\047\114\100\053\043\049\097\061\061","\055\082\080\122\103\082\087\061";"\086\099\120\110\111\065\089\076\114\089\101\048\120\071\120\100","\069\077\080\098\101\118\104\118\101\100\049\103\116\116\061\061","\086\052\119\122\111\082\080\054";"\083\119\109\047\115\084\114\079\103\071\088\053\080\082\055\061";"\067\055\047\066\071\117\106\102\083\090\117\078\049\097\061\061";"\098\074\112\108\078\067\110\083\118\108\107\049\098\109\114\081\117\110\115\066";"\114\075\089\065\086\083\061\061";"\100\118\102\076","\072\051\053\054\116\101\099\056";"\054\054\080\066","\047\118\043\071\109\111\089\115\100\097\061\061";"\117\102\051\049","\111\110\086\109\111\078\099\066\103\065\122\087\055\084\080\087\081\116\061\061","\054\068\111\108\083\057\048\055\049\105\116\061";"";"\116\113\081\101\111\052\076\082\099\097\061\061","\115\081\089\098\098\082\087\079\086\068\074\053\080\071\050\069\114\083\061\061";"\105\071\120\050\055\076\099\051\080\082\089\110\090\052\080\114\086\083\061\061","\103\078\088\061","\104\076\080\051\105\097\061\061";"\071\122\110\111","\075\069\112\072","\099\098\120\109\103\084\088\061","\079\077\121\065\100\116\061\061";"\106\098\078\053\115\116\085\057";"\068\121\097\112\113\120\048\065\088\071\053\105\084\118\071\117\069\047\043\098\056\052\114\051\048\077\056\074\121\116\061\061";"\086\120\085\069\120\100\100\080\117\083\061\061";"\116\116\080\089\101\120\050\107";"\077\079\048\070\081\089\121\120","\057\101\112\068\099\097\061\061","\103\052\047\048\072\065\090\084\088\087\061\061";"\043\108\071\109";"\101\043\080\120\043\100\105\118\098\107\050\088\087\089\076\102\101\066\085\082\087\087\061\061","\105\089\081\108\102\054\050\086","\051\112\075\101\049\118\122\073\075\097\061\061","\107\079\113\068\053\083\061\061","\056\114\112\084\090\090\052\101\111\105\057\077\108\097\061\061","\098\106\097\098\078\097\061\061","\104\055\089\079\108\049\115\112\108\087\061\061","\089\048\052\099","\117\103\066\118\113\116\061\061","\090\099\074\119\083\074\116\052\067\071\119\088\067\082\113\087\090\052\088\061";"\072\055\119\056\053\081\098\047\108\087\061\061","\055\052\099\065\114\052\118\109\055\082\102\057\114\049\102\074";"\114\089\048\051\109\087\061\061";"\088\065\075\071\110\097\061\061","\118\085\067\111\118\112\056\121\056\097\061\061","\118\111\081\074\120\087\061\061","\078\076\097\077\071\104\109\089","\052\115\100\121\074\069\056\050\107\087\061\061","\055\078\115\061","\114\052\056\047\114\052\101\065","\122\070\085\065\110\115\050\069\115\087\061\061","\090\098\120\101\120\069\089\119\090\068\053\053\084\075\071\065\055\089\097\061","\074\083\086\100\069\077\119\053\052\087\061\061","\086\052\101\100\086\083\061\061";"\071\068\121\057","\099\074\072\072\077\120\105\071\090\089\071\061";"\086\075\057\084\079\048\083\081\082\074\113\109\084\089\100\076\090\057\117\067\116\084\121\070\079\050\084\057\105\083\061\061";"\086\089\086\052\086\049\111\081\083\068\109\077\115\071\089\085\111\071\115\061";"\111\069\120\049\080\081\054\118\090\074\099\048\090\065\114\050\086\083\061\061";"\121\107\081\114\115\116\047\071\116\108\090\068","\099\117\083\067\120\122\105\050\080\102\071\061","\090\076\086\079\084\110\080\052\120\065\119\119\067\071\109\068\090\087\061\061","\099\089\106\086\066\115\106\104";"\111\081\050\087\114\081\080\104","\049\119\056\100\086\049\120\122\111\082\101\112\103\082\098\061","\120\082\099\069\111\110\102\057\105\083\061\061";"\114\052\122\122\055\116\061\061","\068\065\108\113\112\107\118\043\108\052\047\087\104\079\073\106\104\049\112\082","\101\112\072\085\102\116\061\061","\055\076\120\079\090\081\050\075";"\067\086\108\073\098\101\120\071","\080\083\047\097\071\065\053\118\113\086\052\069","\111\082\101\069\090\087\061\061","\108\083\119\099\066\084\072\108\069\112\077\116\043\050\051\101\055\104\115\048\087\107\083\080\112\081\054\086\078\083\061\061";"\090\068\111\057\067\082\083\053\067\110\089\076\086\065\111\049\083\119\097\061";"\055\052\099\065\103\081\099\065\114\049\120\122\114\068\118\089","\118\111\081\056\121\074\121\121\076\102\071\069\047\047\105\079\117\074\087\061","\055\071\114\104\073\116\061\061";"\118\106\100\117\072\053\082\115\072\087\043\072","\066\081\115\065\090\049\086\089\103\089\101\080\105\051\111\082\081\116\061\061","\084\097\100\083\086\048\110\097\081\116\113\061","\068\051\070\071";"\049\119\056\109\103\068\120\089\105\097\061\061";"\074\107\114\083\072\121\101\102","\055\068\099\100\103\076\086\089","\102\111\071\106\100\068\071\115\115\097\061\061","\107\115\080\057\068\087\061\061","\114\077\108\104\073\088\065\069\080\075\054\111\107\122\080\075\118\073\083\056\057\097\061\061","\057\067\117\104\097\090\075\053\106\097\061\061";"\069\077\070\089\102\069\120\111\051\071\079\114\082\069\085\089\051\057\103\115","\108\072\090\118\097\088\053\047\098\122\099\082\076\074\055\061";"\071\107\043\088\108\121\080\082\090\082\074\061";"\081\068\089\100\067\074\089\087\055\081\056\104\111\071\088\052\081\098\053\061","\076\051\051\083\083\055\051\101\118\081\086\057\111\097\061\061","\117\049\122\111\112\075\084\047\120\066\083\061","\108\120\121\086\057\097\061\061";"\107\047\052\085\122\065\120\069\107\080\087\061","\086\068\050\071\098\065\089\052\120\074\120\120\115\074\089\084","\103\078\071\061","\100\078\089\075","\108\076\088\079\047\090\120\099","\057\108\081\074\118\049\075\115\087\089\098\082\097\098\107\054","\075\073\098\047\108\116\087\112\106\108\119\052\120\098\104\097\071\101\119\100\054\083\052\071\120\099\056\069\080\073\052\065\099\084\087\055\104\077\074\048\120\053\050\050\088\122\056\101\082\083\087\048\121\087\061\061";"\076\102\104\048","\103\089\047\075\118\087\061\061";"\088\078\099\075\081\066\114\111\104\050\110\101\053\087\061\061","\065\055\116\050\105\116\061\061";"\068\081\074\115\068\097\061\061","\098\065\076\111\116\067\114\070\051\052\084\071\054\049\056\121\081\073\090\083\047\086\053\061","\109\055\048\087\071\070\067\053\072\072\090\088\100\085\121\079","\087\085\067\069\077\051\117\097\087\101\120\105\053\083\061\061";"\052\077\056\081\097\050\078\051";"\082\106\043\081\079\089\121\100\057\097\061\061";"\088\098\052\102\052\081\099\056\120\066\086\098\051\083\061\061","\106\113\119\117\103\084\079\117\078\087\061\061";"\086\071\080\121\081\075\120\069\098\074\098\069\105\098\101\049\084\082\074\119","\084\073\108\121\067\081\087\083\105\076\111\065\068\104\080\050\119\043\043\061";"\114\109\070\107\081\081\101\089";"\120\081\050\119\103\083\061\061","\047\082\071\067\101\115\047\105","\086\051\082\056\118\097\061\061";"\055\068\101\047\086\082\056\100","\067\116\118\088\115\076\078\053\089\048\122\114\089\088\104\082\085\048\047\100\052\116\061\061","\114\082\049\075\108\118\068\050\066\073\070\088\110\085\100\054\110\049\117\105\120\085\074\061","\056\106\118\116\097\077\113\119\085\084\043\054\112\110\109\113","\103\071\067\107\099\110\098\102\119\122\088\079\087\116\057\118\075\108\103\121","\117\117\117\056\110\084\090\118\074\117\083\061";"\100\098\085\089\066\112\070\114\113\101\109\053\104\052\057\111\106\049\051\117\079\097\061\061";"\111\052\101\079\103\116\061\061";"\111\082\101\112\103\082\098\061","\057\098\054\071";"\076\054\111\112\051\112\083\061";"\114\089\086\085\099\082\116\076\080\110\086\047\114\052\120\067\055\083\061\061","\111\082\056\047\111\081\119\112\086\049\088\061";"\120\102\104\086","\103\081\101\065\090\097\061\061","\111\082\056\069\111\110\102\109\103\068\055\061";"\048\120\101\066\087\116\061\061";"\057\115\097\086\098\068\076\078\075\116\097\116\052\052\052\117","\083\052\056\113\103\076\088\069","\083\052\056\047\103\068\099\051\111\097\061\061";"\097\072\067\048\088\099\053\078\043\087\061\061";"\052\100\108\076\118\116\061\061";"\117\065\067\120\066\075\105\073\053\081\097\061";"\049\119\056\113\086\081\053\061","\106\110\111\066\121\073\083\097\074\075\087\061";"\103\070\100\097\055\047\117\117";"\100\077\057\050\084\097\115\117\113\043\047\067\102\115\051\065\121\086\113\061";"\116\097\120\087\085\056\108\111\090\083\078\051\080\067\098\051\106\122\104\085";"\081\100\114\090\111\098\116\070\071\076\114\061","\102\043\055\052\117\053\077\056\071\108\122\077\110\087\061\061";"\098\097\090\072\070\067\077\089\052\043\111\106\047\122\100\106\105\043\083\061";"\088\078\090\084\116\048\104\105","\103\082\111\074\105\049\080\050\105\078\080\119\099\101\116\052\055\081\053\061";"\116\047\056\116\075\047\053\119\074\076\097\061";"\112\081\056\082\098\113\102\103";"\105\090\071\055";"\047\118\100\049";"\079\104\084\073\101\047\111\097\099\116\076\111\047\099\087\061","\054\056\107\057\098\083\061\061";"\066\112\116\089\086\070\054\109\066\116\061\061";"\116\099\067\121\053\080\053\119\074\097\055\061","\076\080\098\074\071\083\051\076","\086\076\080\119\114\116\061\061";"\047\082\071\067";"\086\049\102\079\103\076\088\061";"\089\082\050\111\103\072\071\084\116\099\074\061","\070\112\088\084";"\109\069\081\047","\049\119\056\075\114\087\061\061","\049\073\051\090\099\105\047\109";"\103\057\085\104\057\116\061\061","\114\081\120\088\080\076\122\069\115\081\074\118\083\119\086\088\098\099\055\061","\072\057\082\068\086\048\088\103\113\104\114\088\066\116\061\061";"\108\119\115\078\115\083\061\061","\066\116\061\061","\068\077\082\083\084\083\061\061","\114\052\056\079\103\076\099\065\090\081\050\089","\116\082\108\083\086\109\118\086\115\089\074\111\043\086\113\051";"\049\119\086\106\115\069\074\079\108\117\098\061";"\113\084\117\104","\082\111\111\087\111\083\061\061";"\099\082\101\100\055\082\099\079\088\071\120\089\111\082\099\051\111\082\099\074\088\083\061\061","\073\114\043\079\105\089\112\119\050\112\098\048\068\100\117\081\048\122\113\070\099\070\050\079\051\103\072\053\067\087\061\061";"\069\100\087\086\119\087\061\061","\078\077\047\053\051\050\082\053\077\121\087\101","\099\076\101\098\098\082\065\050\067\081\102\087\081\082\099\050\111\097\061\061","\102\115\043\068\110\116\061\061","\079\076\049\049\098\103\054\099\076\085\073\079\113\057\098\061","\090\076\099\065\086\065\111\066\099\065\055\118\080\068\087\079";"\086\068\118\057\103\076\088\061";"\076\057\068\077\077\105\066\114";"\109\097\078\075\105\114\114\120\120\085\072\084\054\100\069\118\077\083\121\105\108\104\084\078\083\066\120\111\120\065\106\099\082\105\107\109\072\057\054\061";"\081\049\071\050\081\116\112\073","\067\081\050\069\111\082\101\047\114\052\098\061";"\055\057\090\085\121\118\116\079\090\116\061\061";"\106\115\051\068\097\112\103\100\116\083\101\082\087\087\061\061";"\083\072\117\083\055\074\057\113\081\079\080\106\107\055\084\122\069\097\072\049";"\120\082\115\052\111\047\047\084\120\086\090\087\080\083\061\061","\075\086\047\099\097\097\061\061","\114\053\068\080\076\097\061\061","\054\101\104\086\050\071\119\105\099\120\110\078","\082\074\103\113\078\052\081\067";"\109\102\069\074\088\122\080\079\089\116\061\061","\071\086\119\071\103\116\061\061"}for W,I in ipairs({{1002405+-1002404,-677570-(-677788)};{888879+-888878,854945+-854757},{-636339-(-636528);-811582+811800}})do while I[143008-143007]<I[363307+-363305]do n[I[233682-233681] ],n[I[-578605+578607] ],I[297279+-297278],I[621528-621526]=n[I[-924381+924383] ],n[I[-541081-(-541082)] ],I[-447603+447604]+(116129+-116128),I[459525+-459523]-(-839280-(-839281))end end local function W(W)return n[W+(-16922+71935)]end do local W=table.insert local I=string.char local B=string.len local h=table.concat local F={["\047"]=-490202-(-490248);q=-647880+647924;W=-701480-(-701528);["\056"]=-332111-(-332172),H=-575088+575119,P=-599786-(-599799);o=-355373+355402;E=394672+-394621,Z=359458+-359432;F=494029+-494027;I=-477158+477220,O=351129-351079;Y=-415039+415076;u=734854+-734812,C=-630560-(-630578),p=-45797+45831,i=-813790-(-813820),k=-798876+798939;a=-44690-(-44690),["\048"]=576650-576592,["\053"]=381544+-381488;r=-394618+394642;R=-857442-(-857448);f=-563127+563136,z=-486943-(-486976),["\051"]=-128034-(-128069);A=-705588-(-705640),N=407802+-407799;G=961615+-961611,["\043"]=-247078+247138;b=-550682-(-550702),d=578057-578012;v=601699+-601650;x=-1033412-(-1033429),n=-12563-(-12570),["\049"]=924134-924111;M=-689360-(-689361);L=-892486+892541,J=-1026460-(-1026496);D=80531+-80493;B=-593834+593848;h=-814147+814190,["\055"]=181975-181947,w=-190407+190460,g=412541+-412514,y=-853990+854005;T=998531-998512,["\052"]=987104+-987050;["\054"]=1047094+-1047054,s=776320+-776308;["\050"]=-940425+940482;Q=587027-587005,e=-298667+298672;c=400192+-400171;j=-102874+102885,t=-183238-(-183270);l=-687328+687387;X=-107090+107098;V=689644+-689619,m=861877-861836;K=-57673-(-57712),U=35345-35335,S=-435785-(-435801);["\057"]=168394+-168347}local X=math.floor local r=n local V=string.sub local Y=type for n=-451130-(-451131),#r,668571+-668570 do local s=r[n]if Y(s)=="\115\116\114\105\110\103"then local Y=B(s)local z={}local u=-798348-(-798349)local N=-491410-(-491410)local t=-380251+380251 while u<=Y do local n=V(s,u,u)local B=F[n]if B then N=N+B*(158138-158074)^((20395-20392)-t)t=t+(170378-170377)if t==348879-348875 then t=110903-110903 local n=X(N/(-689369+754905))local B=X((N%(-663377-(-728913)))/(-753795+754051))local h=N%(-107565+107821)W(z,I(n,B,h))N=557278-557278 end elseif n=="\061"then W(z,I(X(N/(364707-299171))))if u>=Y or V(s,u+(1004655-1004654),u+(-681310-(-681311)))~="\061"then W(z,I(X((N%(-656182-(-721718)))/(309367-309111))))end break end u=u+(-52479+52480)end r[n]=h(z)end end end return(function(n,B,h,F,X,r,V,u,O,N,I,z,t,d,s,e,p,H,P,g,Y)t,H,u,d,P,Y,p,N,O,I,s,z,g,e=function(n)local W,I=-666620+666621,n[321016-321015]while I do s[I],W=s[I]-(454936-454935),(-443585+443586)+W if s[I]==-921989+921989 then s[I],Y[I]=nil,nil end I=n[W]end end,function(n,W)local B=N(W)local h=function()return I(n,{},W,B)end return h end,316084-316084,function(n,W)local B=N(W)local h=function(...)return I(n,{...},W,B)end return h end,function(n,W)local B=N(W)local h=function(h,F,X,r)return I(n,{h;F;X,r},W,B)end return h end,{},function(n,W)local B=N(W)local h=function(h,F)return I(n,{h,F},W,B)end return h end,function(n)for W=684916-684915,#n,-701771-(-701772)do s[n[W] ]=s[n[W] ]+(521874+-521873)end if h then local I=h(true)local B=X(I)B[W(100406+-155353)],B[W(604048-658908)],B[W(-530504+475619)]=n,t,function()return-327402+2999515 end return I else return F({},{[W(-591467-(-536607))]=t;[W(918219-973166)]=n,[W(-409824-(-354939))]=function()return 923806+1748307 end})end end,function(n)s[n]=s[n]-(181355+-181354)if-373990+373990==s[n]then s[n],Y[n]=nil,nil end end,function(I,h,F,X)local N,T,t,C,S,v,Q,x,f,k,J,s,E,q,i,R,d,u,l,V,a,Z,w,K,D,b,A,c,U,G,o,m,y,M while I do if I<9175805-758191 then if I<-411003+4499611 then if I<-127990+2402968 then if I<129370+994202 then if I<592972-(-47299)then if I<-749929+982807 then if I<834503-746883 then x=Y[u]I=x and-449900+12633888 or 2183356-(-114492)V=x else I=-658811+5063481 end else b=Y[d]I=692564+4174965 V=b end else if I<338078+738860 then if I<433681-(-286144)then I=Y[F[6319-6309] ]u=Y[F[-673313+673324] ]s[I]=u I=Y[F[-473439-(-473451)] ]u={I(s)}V={B(u)}I=n[W(207284+-262256)]else I=1464673-(-742049)l=a v=W(973213+-1028173)f=n[v]v=W(-312562+257755)M=f[v]f=M(s,l)M=Y[F[-754667+754673] ]v=M()Q=f+v E=Q+b v=-515872-(-515873)Q=1025760+-1025504 Z=E%Q Q=N[u]b=Z f=b+v l=nil M=t[f]E=Q..M N[u]=E end else Q=858968-858967 J=#Z E=N(Q,J)Q=b(Z,E)T=834962-834961 J=Y[k]A=Q-T C=m(A)J[Q]=C I=7019499-591069 E=nil Q=nil end end else if I<1436023-(-610291)then if I<793529+902635 then if I<617168+562801 then I=true N=e(6051226-(-923303),{F[789519-789517]})s=W(-1052896-(-998082))Y[F[229113+-229112] ]=I V=n[s]t={V(N)}s=t[892117-892116]u=t[840504-840502]I=s and 11032623-(-158928)or 9626575-182828 else I=97098+1693579 end else I=true I=I and-1045935+13672488 or-633495+5275536 end else if I<-691385+2855103 then N=-146985+147058 u=Y[F[339150+-339148] ]s=u*N u=-970317+28470486811156 V=s+u u=1025938-1025937 s=35184372337147-248315 I=V%s Y[F[932871-932869] ]=I s=Y[F[-877471-(-877474)] ]V=s~=u I=497582+6132533 else a=a+q l=a<=y Z=not k l=Z and l Z=a>=y Z=k and Z l=Z or l Z=1936400-1036722 I=l and Z l=11021629-(-57371)I=I or l end end end else if I<-901154+4552356 then if I<-662668+3896808 then if I<-198384+3157301 then if I<3153809-741505 then I=626404+14094383 Y[u]=V else T=not A Q=Q+C E=Q<=J E=T and E T=Q>=J T=A and T E=T or E T=5706817-(-922415)I=E and T E=1007321+11191079 I=I or E end else I=Y[F[-771073-(-771074)] ]I=I and 901907+10738407 or 850687-(-276659)end else if I<4060592-465853 then R=Y[u]I=R and 9498127-(-642230)or 10198647-(-348110)x=R else N=2743198-(-419839)V=872958+10255944 u=W(-111447+56533)s=u^N I=V-s s=I V=W(585116-640013)I=V/s V={I}I=n[W(-426951+372138)]end end else if I<3620780-(-294461)then if I<4649102-783394 then if I<625778+3079634 then J=W(865520-920315)I=n[J]J=W(903376-958307)n[J]=I I=12089694-378917 else I=true I=I and 7502625-886589 or 477043+4613734 end else u=Y[F[886013+-886011] ]N=Y[F[950841-950838] ]s=u==N V=s I=400554+6680790 end else if I<4353913-287185 then t=W(349558-404515)N=n[t]l=W(970257+-1025127)d=Y[F[634396+-634392] ]s=nil b=Y[F[477359-477354] ]y=22157838374577-(-790941)m=b(l,y)t=d[m]V=N[t]t=Y[F[-727815+727821] ]N=V(t)l=18205096382116-306567 V=Y[F[842369+-842366] ]t=Y[F[-236823-(-236827)] ]d=Y[F[-1044514-(-1044519)] ]m=W(-1000150-(-945305))u=nil b=d(m,l)I=n[W(-624314+569364)]N=t[b]t=Y[F[1037356+-1037349] ]V[N]=t V=false Y[F[235816-235815] ]=V V={}else l=W(42267-97081)t=W(-143047+88154)V=W(278428+-333324)I=n[V]y=p(14592270-996981,{})s=Y[F[501587+-501583] ]N=n[t]m=n[l]l={m(y)}m=-556190-(-556192)b={B(l)}d=b[m]t=N(d)N=W(-410211-(-355342))u=s(t,N)s={u()}V=I(B(s))u=Y[F[73731-73726] ]s=V I=u and 6283776-869813 or 404087+3831999 V=u end end end end else if I<-228210+6569177 then if I<5655996-393743 then if I<4173863-(-674741)then if I<-589174+5018657 then if I<-98784+4443282 then s=nil Y[F[438010-438005] ]=V I=12225832-(-405207)else k=nil m=O(m)q=nil q={}y=O(y)Q=O(Q)b=nil u=O(u)u=nil l=nil y=W(-463736-(-408776))a=O(a)E=nil d=O(d)Z=nil t=O(t)N=O(N)t=z()N=nil Y[t]=u u=z()b=W(577088-631982)Y[u]=N d=n[b]b=W(-682221-(-627382))m=W(209231+-264125)N=d[b]Q=195658+-195402 d=z()Y[d]=N b=n[m]J=Q m=W(-877256+822348)N=b[m]a=z()l=W(461296-516196)k=z()m=n[l]Z={}l=W(-122817-(-67872))b=m[l]l=n[y]y=W(753401-808364)m=l[y]y=z()l=734290+-734290 Q=598879-598878 Y[y]=l l=274502+-274500 Y[a]=l Y[k]=q I=-324676+3228686 q=-352585-(-352585)E=869592+-869591 l={}C=Q Q=-798260+798260 A=C<Q Q=E-C end else V={}I=n[W(-229066+174265)]end else if I<4295686-(-823719)then if I<4359738-(-639985)then m=W(22503+-77397)b=V k=W(-50968-3932)V=n[m]m=W(609151-664059)I=V[m]m=z()Y[m]=I l=W(-525462+470562)V=n[l]l=W(404708-459688)I=V[l]a=I q=n[k]l=I I=q and-385550+15269251 or-630810+16580785 y=q else I=H(1553441-64982,{t})f={I()}I=n[W(285224-340020)]V={B(f)}end else G=541653-541651 w=D[G]G=Y[o]I=-467776+10399575 U=w==G x=U end end else if I<6472623-528942 then if I<5694259-279967 then if I<4797448-(-602452)then V=W(-142064-(-87100))I=Y[F[988679-988675] ]V=I[V]V=V(I)I=15075702-(-285429)else I=896610+3339476 N=Y[F[383976-383970] ]u=N==s V=u end else I={}Y[F[185937-185935] ]=I V=Y[F[283987+-283984] ]l=W(854677+-909637)m=-88160+88415 t=V d=17251+35184372071581 V=u%d Y[F[698987+-698983] ]=V b=u%m m=199257-199255 d=b+m Y[F[843012+-843007] ]=d I=1553049-(-653673)m=n[l]l=W(-1006538+951721)b=m[l]m=b(s)b=W(-280200+225401)l=-397136-(-397137)a=-26506-(-26507)N[u]=b y=m q=a b=1002725-1002613 a=-462596-(-462596)k=q<a a=l-q end else if I<596441+5363253 then s=Y[F[898865-898864] ]V=#s s=-551701+551701 I=V==s I=I and 3157907-1010988 or 1023012+13313630 else I=true Y[F[725118-725117] ]=I V={}I=n[W(151608+-206484)]end end end else if I<549602+6486426 then if I<6319259-(-310469)then if I<6420076-(-205520)then if I<6641746-201840 then Q=#Z J=233250-233250 E=Q==J I=E and 439509+8120552 or-815838+1934747 else I=8663656-(-957812)end else E=Q T=E I=2668418-(-235592)Z[E]=T E=nil end else if I<6517800-(-273035)then I=267907+16165395 u=Y[F[10988+-10985] ]N=514771-514521 s=u*N u=-12170+12427 V=s%u Y[F[321323+-321320] ]=V else V=W(85011-139999)I=n[V]s=Y[F[-386491+386492] ]V=I(s)V={}I=n[W(517302+-572234)]end end else if I<7084073-(-475189)then if I<551939+6513166 then if I<-1047712+8104616 then I=Y[F[-691928+691929] ]N=I u=h[747416+-747414]I=N[u]I=I and 9440738-(-519353)or 4554066-(-924428)s=h[-534638+534639]else s=W(-416956-(-362121))d=W(-790011+735085)b=-904462+16306348911287 V=n[s]u=Y[F[213782+-213781] ]N=Y[F[442306+-442304] ]t=N(d,b)b=-84691+24278461626108 s=u[t]y=20621379190952-(-910554)d=W(-334929+279990)I=V[s]u=Y[F[89788+-89787] ]N=Y[F[158299-158297] ]t=N(d,b)s=u[t]b=16251044992307-325540 u=Y[F[963601+-963598] ]a=-212597+16945733082439 V=I(s,u)s=V u=Y[F[1001622-1001621] ]N=Y[F[-472222-(-472224)] ]d=W(-953768-(-898761))t=N(d,b)V=u[t]l=W(-615270+560387)I=s[V]d=Y[F[-100417+100418] ]b=Y[F[-755259-(-755261)] ]m=b(l,y)t=d[m]N=s[t]u=I l=W(965025-1019863)d=Y[F[447683-447682] ]b=Y[F[-927587+927589] ]y=1016108+31213156087706 m=b(l,y)t=d[m]V=N[t]m=W(197151-252118)y=W(317429+-372339)l=-548099+4515945096505 t=Y[F[-256585-(-256586)] ]d=Y[F[657313-657311] ]b=d(m,l)N=t[b]I=V[N]N=z()Y[N]=I b=Y[F[-177114-(-177115)] ]m=Y[F[541886+-541884] ]l=m(y,a)d=b[l]t=s[d]b=Y[F[-541755+541756] ]a=8756312289926-90777 y=W(-956612-(-901700))m=Y[F[-899725+899727] ]s=nil l=m(y,a)d=b[l]V=t[d]l=W(-428227-(-373427))d=Y[F[567663+-567662] ]y=13975612869873-439174 b=Y[F[-133134+133136] ]m=b(l,y)t=d[m]l=W(26345+-81266)I=V[t]t=z()y=748492+3547393923751 Y[t]=I d=Y[F[-148208-(-148209)] ]b=Y[F[210567-210565] ]m=b(l,y)V=d[m]I=u[V]d=H(-591341+9639168,{t;F[817308+-817307],F[716216-716214],N})V=W(-994856+939967)V=I[V]u=nil t=O(t)N=O(N)V=V(I,d)V={}I=n[W(739575-794530)]end else I=V and 5008231-927693 or-46580+12677619 end else if I<142234+7911332 then N=-626242+626274 u=Y[F[-623509-(-623512)] ]s=u%N t=Y[F[-801855-(-801859)] ]m=Y[F[-82573-(-82575)] ]q=-588804+588817 y=148760-148758 E=Y[F[77239-77236] ]Z=E-s E=301117+-301085 k=Z/E a=q-k l=y^a b=m/l d=t(b)q=40615+-40359 t=4294673929-(-293367)N=d%t d=423602-423600 t=d^s u=N/t t=Y[F[-98337-(-98341)] ]l=710289-710288 m=u%l l=280208+4294687088 y=-583461-(-583717)b=m*l d=t(b)t=Y[F[978885-978881] ]b=t(u)N=d+b d=-410506+476042 m=753021-687485 u=nil t=N%d b=N-t d=b/m m=562062-561806 b=t%m l=t-b t=nil I=558895+13777747 m=l/y y=-846778-(-847034)s=nil l=d%y a=d-l y=a/q d=nil a={b,m;l,y}l=nil Y[F[969138+-969137] ]=a y=nil m=nil b=nil N=nil else Y[u]=M I=Y[u]I=I and-470229+566878 or 331145+11673359 end end end end end else if I<12275531-290791 then if I<-105185+10583407 then if I<400634+9172478 then if I<8921137-(-87367)then if I<433165+8302643 then if I<8560952-1484 then I=Y[F[92573-92572] ]y=-970947-(-971202)u=N l=480668+-480668 m=I(l,y)s[u]=m I=-227500+14841335 u=nil else C=z()Z=nil T={}Q=z()E={}Y[Q]=E J=e(552200+5397644,{Q;y,a,d})A=W(194660-249614)D=W(542114-597079)i=W(1042231+-1097178)E=z()m=nil Y[E]=J b=nil U=nil N=nil J={}Y[C]=J J=n[A]d=O(d)o=Y[C]c={[i]=o;[D]=U}l=nil q=nil A=J(T,c)Y[t]=A J=g(6495167-(-560913),{C,Q,k;y,a,E})Y[u]=J a=O(a)y=O(y)q=930585+22238523422042 C=O(C)k=O(k)Q=O(Q)E=O(E)b=W(-485195-(-430360))d=n[b]a=W(-157567+102745)m=Y[t]l=Y[u]y=l(a,q)T=454932+31319828121572 a=W(942280+-997124)b=m[y]N=d[b]m=Y[t]l=Y[u]q=32065896205902-(-699397)y=l(a,q)b=m[y]c=145674+10926746622678 k=-972328+34603244492057 q=W(-1036015+981209)Q=978004+33417172881525 d=N(b)m=W(738460+-793295)b=n[m]l=Y[t]y=Y[u]a=y(q,k)k=-331340+12513244570894 m=l[a]J=9478959884650-989229 N=b[m]E=-282194+21687740904901 q=W(865832-920730)l=Y[t]y=Y[u]a=y(q,k)m=l[a]b=N(m)Z=913781+33195557915372 l=W(194077-248912)m=n[l]y=Y[t]a=Y[u]k=W(924904-979776)q=a(k,Z)l=y[q]N=m[l]y=Y[t]a=Y[u]Z=14392984494992-461154 k=W(281792+-336743)U=448866+29718417775788 q=a(k,Z)l=y[q]D=W(-885524+830636)m=N(l)y=W(376009-430844)Z=W(343939-398834)l=n[y]a=Y[t]q=Y[u]k=q(Z,E)E=5219766850073-231579 y=a[k]N=l[y]Z=W(556211-611180)a=Y[t]q=Y[u]k=q(Z,E)E=W(797259+-852080)y=a[k]l=N(y)a=W(-846234+791399)C=1847936133453-681457 y=n[a]q=Y[t]k=Y[u]Z=k(E,Q)a=q[Z]N=y[a]q=Y[t]E=W(-349970-(-294993))k=Y[u]Q=403073+11208192093666 Z=k(E,Q)a=q[Z]q=W(669100+-723935)y=N(a)a=n[q]Q=W(792926+-847874)k=Y[t]Z=Y[u]E=Z(Q,J)q=k[E]J=25137306176703-302854 N=a[q]k=Y[t]Z=Y[u]Q=W(-420752-(-365868))i=706834+19234300090858 E=Z(Q,J)q=k[E]a=N(q)k=W(-292802-(-237967))q=n[k]Z=Y[t]J=W(511315+-566245)E=Y[u]Q=E(J,C)k=Z[Q]N=q[k]Z=Y[t]E=Y[u]J=W(-437115+382259)C=31756918057237-814930 Q=E(J,C)k=Z[Q]q=N(k)Z=W(174202+-229037)N=z()Y[N]=q k=n[Z]C=W(-74955-(-19980))E=Y[t]Q=Y[u]J=Q(C,T)Z=E[J]q=k[Z]E=Y[t]C=W(270131-325017)T=192466972377-(-627072)Q=Y[u]J=Q(C,T)Z=E[J]k=q(Z)T=W(750053-804915)E=W(372080-426915)Z=n[E]Q=Y[t]J=Y[u]C=J(T,c)E=Q[C]q=Z[E]Q=Y[t]c=14056662563645-663980 J=Y[u]T=W(153409+-208221)C=J(T,c)E=Q[C]Z=q(E)c=W(514139-568988)Q=W(883977+-938812)q=z()Y[q]=Z E=n[Q]J=Y[t]C=Y[u]T=C(c,i)Q=J[T]i=-626023+4428247340405 Z=E[Q]J=Y[t]c=W(884952-939802)C=Y[u]T=C(c,i)Q=J[T]E=Z(Q)i=757644+9922737685120 T=W(-390317-(-335321))Q=Y[t]c=13982337231004-(-684243)J=Y[u]C=J(T,c)Z=Q[C]J=Y[t]c=W(235623+-290581)C=Y[u]T=C(c,i)Q=J[T]d[Z]=Q c=1034017+7245480707596 Q=Y[t]J=Y[u]T=W(-879713+824784)C=J(T,c)T=W(-557574+502598)Z=Q[C]C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]o=W(297198+-352069)D=26114486944972-234828 U=-34741+911663876445 J=C[T]T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]T=Y[t]c=Y[u]D=916389+2635628202278 J=W(69515-124331)o=W(700019+-754847)J=Q[J]i=c(o,D)C=T[i]J=J(Q,C)D=W(933840-988753)c=-487579+18720682545832 T=W(-479553-(-424600))d[Z]=J Q=Y[t]J=Y[u]C=J(T,c)Z=Q[C]T=W(651684-706595)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]J=C[T]D=31893364284166-925955 o=W(-529852-(-474867))T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]d[Z]=Q c=12006795557039-(-236840)Q=Y[t]i=649176+16425190258184 T=W(725173+-780125)J=Y[u]C=J(T,c)Z=Q[C]J=Y[t]C=Y[u]c=W(-384754-(-329784))T=C(c,i)Q=J[T]T=W(712467-767303)c=63834+18947515541789 b[Z]=Q Q=Y[t]J=Y[u]C=J(T,c)T=W(-1028065-(-973123))Z=Q[C]Q=d b[Z]=Q o=W(344411+-399390)Q=Y[t]c=8888320766802-156456 D=15844062307028-(-14845)J=Y[u]C=J(T,c)Z=Q[C]C=W(-517700-(-462810))J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]c=931384+-931334 C=-940699-(-940749)T=-614585+614635 J=Q(C,T,c)o=W(-324018+269103)c=31460759245090-(-600088)b[Z]=J T=W(546447-601367)Q=Y[t]D=6899506747119-(-587165)J=Y[u]C=J(T,c)Z=Q[C]C=W(-6816+-48074)J=n[C]T=Y[t]c=Y[u]i=c(o,D)c=-358706+358706 C=T[i]o=W(-188297+133305)Q=J[C]C=813526-813526 T=-88051+88051 J=Q(C,T,c)D=12119273833586-(-135577)T=W(-314854-(-259892))b[Z]=J Q=Y[t]c=30237046973262-601166 J=Y[u]C=J(T,c)c=17964127778238-(-584431)Z=Q[C]Q=-952381-(-952381)b[Z]=Q Q=Y[t]T=W(456614-511563)J=Y[u]C=J(T,c)Z=Q[C]C=W(75949+-130958)J=n[C]T=Y[t]c=Y[u]i=c(o,D)D=29172321315344-439552 c=.285545021 C=T[i]Q=J[C]i=387530-387530 C=.351585001 T=-160065+160065 J=Q(C,T,c,i)b[Z]=J Q=Y[t]J=Y[u]o=W(-814472+759611)c=972774+28469847153635 T=W(175520+-230344)C=J(T,c)Z=Q[C]C=W(695672+-750681)J=n[C]T=Y[t]c=Y[u]i=c(o,D)c=558744+-558744 C=T[i]Q=J[C]i=-705087-(-705326)C=-965135+965135 T=568257+-567846 J=Q(C,T,c,i)i=-168693+18422782080119 b[Z]=J Q=Y[t]c=948045+21598231916540 J=Y[u]T=W(456252-511186)C=J(T,c)Z=Q[C]J=Y[t]c=W(-1005741-(-950744))C=Y[u]T=C(c,i)Q=J[T]m[Z]=Q c=31020255391742-(-936046)Q=Y[t]J=Y[u]T=W(873022+-928020)C=J(T,c)Z=Q[C]Q=b c=902419+18170777115642 m[Z]=Q T=W(375988+-430895)Q=Y[t]J=Y[u]o=W(-207832-(-152843))C=J(T,c)Z=Q[C]D=-1011165+14558239393880 C=W(500578+-555468)J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]T=578643-578388 Q=J[C]C=977907+-977652 c=-730544+730799 J=Q(C,T,c)T=W(-144240-(-89394))m[Z]=J c=615377+31212723311861 Q=Y[t]J=Y[u]C=J(T,c)Z=Q[C]D=28614900737745-455365 c=732282+29097524054131 Q=-105389-(-105390)m[Z]=Q T=W(733716-788644)Q=Y[t]J=Y[u]C=J(T,c)o=W(-888866-(-834032))Z=Q[C]C=W(-827710-(-772820))J=n[C]T=Y[t]c=Y[u]i=c(o,D)c=368664+-368664 C=T[i]T=785539+-785539 Q=J[C]C=125835-125835 D=7412865766737-(-342058)o=W(392469-447273)J=Q(C,T,c)T=W(980220-1035101)m[Z]=J c=15262653624784-1005069 Q=Y[t]J=Y[u]C=J(T,c)c=33525772541385-1040590 Z=Q[C]Q=-231949+231949 m[Z]=Q Q=Y[t]J=Y[u]T=W(-1060734-(-1005760))C=J(T,c)Z=Q[C]C=W(-834011-(-779002))J=n[C]T=Y[t]c=Y[u]i=c(o,D)c=.138075307 C=T[i]Q=J[C]T=-679572-(-679572)C=.255474448 i=568548+-568548 J=Q(C,T,c,i)m[Z]=J D=-330371+5586881467564 c=681649+25185390397214 T=W(-1037623+982794)Q=Y[t]J=Y[u]C=J(T,c)Z=Q[C]C=W(148807-203816)o=W(861900+-916910)J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]T=-913451-(-913651)D=W(-171792-(-116867))Q=J[C]c=-1047799-(-1047799)C=257487-257487 i=-236827-(-236877)J=Q(C,T,c,i)m[Z]=J Q=Y[t]U=559312+16115505124480 J=Y[u]c=1946911556472-(-671762)T=W(946695+-1001548)C=J(T,c)Z=Q[C]T=W(494869+-549780)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]J=C[T]o=W(-234104+179180)T=Y[t]c=Y[u]D=-1035727+8222511307971 i=c(o,D)C=T[i]T=W(-866235+811348)Q=J[C]m[Z]=Q D=32674389095935-(-1000816)Q=Y[t]J=Y[u]c=20667595286093-983221 C=J(T,c)c=W(575041+-629872)Z=Q[C]i=663480+17027168862016 J=Y[t]C=Y[u]T=C(c,i)o=W(385487+-440302)Q=J[T]m[Z]=Q Q=Y[t]J=Y[u]T=W(-935953-(-880958))c=4931501670064-144824 C=J(T,c)Z=Q[C]C=W(-539825-(-484935))J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]c=226411-226156 C=-224549+224804 T=703325+-703070 J=Q(C,T,c)m[Z]=J T=W(-1033607-(-978672))Q=Y[t]D=9164725582421-649642 c=-796963+33452361229820 J=Y[u]C=J(T,c)Z=Q[C]c=23879016219166-(-911697)Q=733271-733247 m[Z]=Q T=W(-532139+477312)Q=Y[t]J=Y[u]C=J(T,c)o=W(-1006683-(-951766))c=-341598+6378338943480 Z=Q[C]Q=b l[Z]=Q Q=Y[t]T=W(-372143+317251)J=Y[u]i=14112051469380-803481 C=J(T,c)Z=Q[C]J=Y[t]C=Y[u]c=W(999448+-1054316)T=C(c,i)Q=J[T]T=W(-553005+498200)y[Z]=Q Q=Y[t]J=Y[u]c=20155405280251-409426 C=J(T,c)Z=Q[C]T=W(-752413+697511)Q=b c=13277846362895-410345 U=23971718971248-906198 y[Z]=Q Q=Y[t]J=Y[u]C=J(T,c)Z=Q[C]C=W(608400-663290)J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]c=519945-519843 o=W(-938716+883711)Q=J[C]C=-386662-(-386764)T=906843-906741 J=Q(C,T,c)y[Z]=J Q=Y[t]J=Y[u]T=W(-390349-(-335393))c=2935162142803-1014525 C=J(T,c)Z=Q[C]Q=.4 y[Z]=Q c=-836460+25397120758174 Q=Y[t]T=W(-516015-(-461124))J=Y[u]C=J(T,c)D=7308+2450200946664 Z=Q[C]C=W(-486830-(-431940))J=n[C]T=Y[t]c=Y[u]i=c(o,D)V={}C=T[i]o=W(795732-850631)Q=J[C]C=-455810-(-455810)c=320162+-320162 T=877796-877796 J=Q(C,T,c)y[Z]=J T=W(-401025+346193)Q=Y[t]J=Y[u]c=32107482103810-99739 C=J(T,c)c=11810979761836-(-919247)Z=Q[C]Q=445989-445989 y[Z]=Q T=W(268974+-323912)Q=Y[t]J=Y[u]D=-955827+20872983821226 C=J(T,c)Z=Q[C]C=W(-371706+316697)J=n[C]T=Y[t]c=Y[u]i=c(o,D)o=W(314455+-369275)C=T[i]Q=J[C]c=.435146451 i=668394+-668394 T=502184-502184 C=.180048659 J=Q(C,T,c,i)T=W(-652814+597827)y[Z]=J Q=Y[t]D=29981757728531-(-970614)c=92689+27943366150339 J=Y[u]C=J(T,c)Z=Q[C]C=W(-797236+742227)J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]i=655074+-655043 Q=J[C]T=-280337+280600 c=954879+-954879 C=560297+-560297 J=Q(C,T,c,i)y[Z]=J Q=Y[t]c=246849150777-(-8505)D=W(601430+-656432)J=Y[u]T=W(771213+-826071)C=J(T,c)Z=Q[C]T=W(-261166+206255)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]J=C[T]T=Y[t]c=Y[u]D=-28442+23894911408784 o=W(-394868+339952)i=c(o,D)C=T[i]Q=J[C]y[Z]=Q c=287131+28861749154532 Q=Y[t]T=W(748118-802926)J=Y[u]C=J(T,c)Z=Q[C]J=Y[t]i=197214+4049998398719 c=W(232236-287118)C=Y[u]T=C(c,i)Q=J[T]y[Z]=Q c=22236311292584-500278 l=nil Q=Y[t]T=W(147259+-202084)J=Y[u]C=J(T,c)Z=Q[C]c=W(826945+-881744)J=Y[t]C=Y[u]i=521224+1090242924019 T=C(c,i)c=29235388750604-(-924193)Q=J[T]y[Z]=Q D=27823190948838-(-980662)o=W(-933672+878731)Q=Y[t]J=Y[u]T=W(-514583-(-459647))C=J(T,c)Z=Q[C]C=W(-956781-(-901891))J=n[C]T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]c=-48435+48690 T=646975+-646720 C=-773960+774215 J=Q(C,T,c)o=734812+23704749257922 c=737973+3037154951889 y[Z]=J i=861329662775-(-433754)T=W(-481739+426859)Q=Y[t]m=nil J=Y[u]C=J(T,c)Z=Q[C]Q=-913998-(-914022)y[Z]=Q Q=Y[t]J=Y[u]T=W(546188-601065)c=10166523968594-715220 C=J(T,c)Z=Q[C]Q=y a[Z]=Q Z=Y[N]c=W(885063-939886)J=Y[t]C=Y[u]T=C(c,i)Q=J[T]C=Y[t]T=Y[u]i=W(-663463-(-608545))c=T(i,o)J=C[c]Z[Q]=J i=27193693714574-935703 Z=Y[N]c=W(124083-178950)D=W(-114722-(-59729))J=Y[t]C=Y[u]T=C(c,i)c=W(-480157-(-425338))Q=J[T]J=b Z[Q]=J Z=Y[N]J=Y[t]i=-510143+5792832131912 C=Y[u]T=C(c,i)Q=J[T]T=W(-583558-(-528668))w=16004284817055-(-753277)U=84244+21194767900025 C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]a=nil J=C[T]T=825526+-825424 c=288186+-288084 i=716248+-716146 C=J(T,c,i)i=25461681522689-399793 Z[Q]=C Z=Y[N]J=Y[t]C=Y[u]c=W(764573+-819579)T=C(c,i)i=126915+29671848625718 Q=J[T]J=.4 c=W(-408152+353301)Z[Q]=J Z=Y[N]J=Y[t]C=Y[u]T=C(c,i)U=998284+27573105604251 Q=J[T]T=W(464646+-519536)D=W(851416+-906242)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]c=720152-720152 J=C[T]i=-293078+293078 T=859120-859120 C=J(T,c,i)Z[Q]=C i=-512842+4389360196421 Z=Y[N]c=W(-1088598-(-1033694))J=Y[t]D=W(962167+-1017178)C=Y[u]T=C(c,i)Q=J[T]J=262792+-262792 Z[Q]=J Z=Y[N]J=Y[t]I=n[W(946151-1000948)]C=Y[u]c=W(-396044+341169)i=14642880569460-(-948782)T=C(c,i)Q=J[T]T=W(172806+-227815)C=n[T]U=-234399+5666580684269 c=Y[t]i=Y[u]o=i(D,U)D=W(-907997-(-853132))T=c[o]J=C[T]o=527110+-527110 U=17578042568810-(-94095)T=.566909969 c=-697682-(-697682)i=.694560647 C=J(T,c,i,o)Z[Q]=C i=-310717+13554084927076 Z=Y[N]J=Y[t]c=W(192189-247098)C=Y[u]T=C(c,i)Q=J[T]T=W(776596+-831605)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]o=491684-491641 J=C[T]T=-439831-(-439831)U=W(497923-552909)c=-117621-(-117764)i=86831+-86831 C=J(T,c,i,o)Z[Q]=C Z=Y[N]c=W(-1019153-(-964159))i=232818+31063700138767 J=Y[t]C=Y[u]T=C(c,i)Q=J[T]c=W(-549546+494635)T=n[c]i=Y[t]o=Y[u]D=o(U,w)c=i[D]C=T[c]D=W(420246-475125)c=Y[t]i=Y[u]U=14501152612190-50430 o=i(D,U)i=7690308346478-(-600975)T=c[o]J=C[T]Z[Q]=J c=W(346536+-401544)o=-730736+1692897077636 Z=Y[N]J=Y[t]C=Y[u]T=C(c,i)Q=J[T]D=W(-568600-(-513599))C=Y[t]T=Y[u]i=W(-576495-(-521677))c=T(i,o)J=C[c]w=21786034355558-464326 i=340873+7260146358699 c=W(-526370+471537)Z[Q]=J Z=Y[N]J=Y[t]C=Y[u]T=C(c,i)U=-512475+2487696070241 Q=J[T]T=W(268163+-323053)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]c=-236403-(-236644)J=C[T]i=992289-992048 o=-978978+30801495926825 T=-578844+579085 C=J(T,c,i)U=31891738109521-(-299953)Z[Q]=C Z=Y[N]i=975520+1939744530663 J=Y[t]c=W(-649229+594326)C=Y[u]T=C(c,i)Q=J[T]J=779080+-779057 c=31231865535646-754639 Z[Q]=J T=W(964585-1019589)Q=Y[t]d=nil J=Y[u]C=J(T,c)Z=Q[C]Q=Y[N]c=W(-783169-(-728185))k[Z]=Q Z=Y[q]J=Y[t]i=1032568+26382605905541 C=Y[u]T=C(c,i)Q=J[T]i=W(-682729-(-627770))C=Y[t]T=Y[u]c=T(i,o)i=97491645103-373378 J=C[c]Z[Q]=J Z=Y[q]J=Y[t]C=Y[u]c=W(-516829+461883)T=C(c,i)Q=J[T]J=b i=-491853+13434546117052 c=W(-760383+705384)Z[Q]=J Z=Y[q]J=Y[t]C=Y[u]T=C(c,i)Q=J[T]T=W(168438+-223328)C=n[T]c=Y[t]i=Y[u]D=W(-908245-(-853301))o=i(D,U)i=582864+-582762 T=c[o]J=C[T]T=-73156+73258 c=1040184-1040082 C=J(T,c,i)Z[Q]=C Z=Y[q]i=297471+29332880649052 c=W(380979-435952)J=Y[t]C=Y[u]T=C(c,i)Q=J[T]J=.4 Z[Q]=J Z=Y[q]i=6073365872632-406764 J=Y[t]c=W(-828339-(-773434))C=Y[u]T=C(c,i)U=-478666+34928894578003 Q=J[T]T=W(178645-233535)D=W(153451+-208249)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]i=940240+-940240 J=C[T]T=-654870-(-654870)y=nil c=223508+-223508 C=J(T,c,i)c=W(112261+-167201)Z[Q]=C Z=Y[q]J=Y[t]i=-968830+4315033063511 C=Y[u]T=C(c,i)c=W(-480119+425186)Q=J[T]D=W(43692-98565)U=23449271234740-(-752115)J=-1028729+1028729 Z[Q]=J Z=Y[q]i=6934695128710-(-433687)J=Y[t]C=Y[u]T=C(c,i)Q=J[T]T=W(882329+-937338)C=n[T]c=Y[t]i=Y[u]o=i(D,U)b=nil T=c[o]o=864181-864181 J=C[T]i=.694560647 c=-98442+98442 T=.111922137 C=J(T,c,i,o)Z[Q]=C i=31508724346441-(-527111)Z=Y[q]c=W(774860-829708)J=Y[t]C=Y[u]D=W(-296232-(-241232))T=C(c,i)Q=J[T]T=W(-816927+761918)U=12727526986612-(-213938)C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]o=-23856-(-23899)J=C[T]T=620112-620112 i=8009-8009 c=493716-493573 C=J(T,c,i,o)U=W(988257-1043180)i=9459667360058-(-505851)Z[Q]=C c=W(516399-571254)Z=Y[q]J=Y[t]C=Y[u]T=C(c,i)c=W(-167002+112091)Q=J[T]T=n[c]i=Y[t]o=Y[u]D=o(U,w)c=i[D]D=W(-608627+553818)C=T[c]c=Y[t]k=nil U=-819716+7215004667683 i=Y[u]o=i(D,U)i=1848402716184-352956 T=c[o]J=C[T]Z[Q]=J Z=Y[q]J=Y[t]C=Y[u]c=W(-963663+908702)T=C(c,i)i=W(-33061+-21798)Q=J[T]C=Y[t]T=Y[u]U=721981+7514982091118 o=-175360+26175393750172 c=T(i,o)i=-597998+21857885980592 J=C[c]c=W(488640+-543559)Z[Q]=J Z=Y[q]D=W(599281-654263)J=Y[t]C=Y[u]T=C(c,i)Q=J[T]T=W(-869142-(-814252))C=n[T]c=Y[t]i=Y[u]o=i(D,U)T=c[o]J=C[T]T=-877442+877683 i=-339966-(-340207)c=-566136+566377 C=J(T,c,i)Z[Q]=C Z=Y[q]c=W(-1012776+957913)i=-213493+4545106299449 J=Y[t]C=Y[u]D=-1012482+16506523685128 T=C(c,i)Q=J[T]T=W(-555086-(-500212))J=-153361-(-153384)c=4251555736384-(-203899)Z[Q]=J Q=Y[t]J=Y[u]C=J(T,c)Z=Q[C]Q=Y[q]E[Z]=Q Z=g(-189587+15786894,{t;u,N})C=W(-309215+254363)o=W(935325+-990268)U=-109328+29722788356384 J=n[C]N=O(N)T=Y[t]c=Y[u]i=c(o,D)C=T[i]Q=J[C]T=W(298466+-353318)J=Q(Z)Q=J()Z=nil D=W(-113032+58041)Q=P(6992920-(-67630),{t;u;q})C=n[T]c=Y[t]q=O(q)i=Y[u]o=i(D,U)t=O(t)T=c[o]u=O(u)J=C[T]E=nil C=J(Q)Q=nil J=C()end else s=h m=W(446338-501152)t=z()I=true N=W(511446+-566406)d=z()u=z()Y[u]=I V=n[N]N=W(-861980+807169)I=V[N]N=z()l=p(5567649-(-636015),{d})Y[N]=I I=p(10469419-(-362165),{})Y[t]=I I=false Y[d]=I b=n[m]m=b(l)V=m I=m and-160284+700594 or-747578+5615107 end else if I<-64324+9446396 then if I<8852516-(-350995)then s=Y[F[936420-936419] ]m=15971316151975-88474 N=Y[F[548657+-548655] ]b=W(269832-324662)t=Y[F[-698649-(-698652)] ]d=t(b,m)u=N[d]V=s[u]b=15824014396249-(-397679)u=Y[F[58582+-58580] ]d=W(-785906-(-731028))N=Y[F[858879+-858876] ]t=N(d,b)s=u[t]I=V==s I=I and-264672+5664446 or 14470579-(-890552)else a=W(99513+-154479)y=n[a]V=y I=-770240+13012010 end else N=W(546288-601189)a=22060347476105-(-417687)y=W(-877945-(-823108))V=n[N]b=Y[F[966804-966800] ]m=Y[F[943902-943897] ]l=m(y,a)d=b[l]m=W(-88446-(-33553))b=n[m]m=b(u)I=5061966-1007161 t=d..m N=V(t)m=W(664560+-719482)l=-140877+4770550574842 V=Y[F[-854905-(-854908)] ]t=Y[F[-52260+52264] ]y=-914175+19799157282562 d=Y[F[425939+-425934] ]b=d(m,l)l=W(-776957-(-721974))N=t[b]d=Y[F[824335-824331] ]b=Y[F[-65805+65810] ]m=b(l,y)t=d[m]V[N]=t end end else if I<10203866-197588 then if I<9826228-(-130295)then if I<9142431-(-607025)then I=true I=I and-297585+10716207 or 14914355-627972 else V=x I=R I=646264+1651584 end else I=12254163-(-100544)end else if I<11070180-688544 then U=267644-267643 I=10144826-(-401931)R=D[U]x=R else I=Y[m]J=145319-145313 v=-509026+509027 f=I(v,J)I=W(469772+-524567)n[I]=f J=W(-833589-(-778794))v=n[J]J=712268-712266 I=v>J I=I and 429982+11265400 or-297611+3980210 end end end else if I<11236752-(-29217)then if I<111785+10801074 then if I<744163+10081844 then if I<11032850-485931 then K=-388232+388233 Y[u]=x G=Y[c]w=G+K U=D[w]R=q+U U=-185333+185589 I=R%U q=I w=Y[T]U=k+w w=75799+-75543 R=U%w k=R I=14687343-(-33444)else s=W(861743-916607)N=-1027692+1027692 I=n[s]u=Y[F[334604+-334596] ]s=I(u,N)I=14489114-(-468683)end else s=W(-486847+432000)V=W(189760-244624)I=n[V]V=I(s)I=n[W(-381751+326780)]V={}end else if I<10870830-(-209277)then I=-689745+13044452 m=nil t=nil b=nil else V=Y[F[-418916-(-418919)] ]t=Y[F[116473+-116469] ]d=Y[F[-959319-(-959324)] ]l=13572315625884-24812 m=W(-728864+674022)b=d(m,l)N=t[b]d=Y[F[-398856-(-398860)] ]l=W(-799062+744259)y=964344+24182032561412 I=3860974-(-193831)b=Y[F[427616+-427611] ]m=b(l,y)t=d[m]V[N]=t end end else if I<12524273-820212 then if I<12339446-644683 then if I<-992566+12395151 then f=Y[u]M=f I=f and-420564+14588449 or 8669187-348249 else I=n[W(137959-192896)]V={}end else v=W(472187-527080)I=n[v]C=W(321587-376518)J=n[C]v=I(J)I=W(808053-862848)n[I]=v I=618431+11092346 end else if I<11123780-(-737372)then I=10524630-903162 else C=not J M=M+v V=M<=f V=C and V C=M>=f C=J and C V=C or V C=12660275-171484 I=V and C V=154747+11244236 I=I or V end end end end else if I<-243450+14414601 then if I<12363028-(-231708)then if I<13034965-830748 then if I<-408305+12603131 then if I<11963406-(-190107)then I=true I=432645+4658132 else G=593388-593387 w=D[G]G=false R=I U=w==G I=U and-763929+5896722 or 9210092-(-721707)x=U end else Q=#Z I=31547+1087362 J=590395-590395 E=Q==J end else if I<511056+11924203 then if I<12778416-504465 then a=-311266-(-311269)q=138065+-138000 y=z()Y[y]=V I=Y[m]V=I(a,q)a=z()Y[a]=V I=-403849+403849 E=P(-290828+3909654,{})Z=W(-937913-(-883099))V=n[Z]q=I I=113153-113153 k=I Z={V(E)}V=-1004062-(-1004064)v=W(544744+-599637)I={B(Z)}Z=I I=Z[V]E=I V=W(484509-539405)I=n[V]Q=Y[N]f=n[v]v=f(E)f=W(-1066552-(-1011683))M=Q(v,f)Q={M()}V=I(B(Q))Q=z()Y[Q]=V M=Y[a]V=955978+-955977 f=M M=968485-968484 v=M M=-993429-(-993429)I=-464748+12438138 J=v<M M=V-v else V={u}I=n[W(-1007997-(-953154))]end else C=z()A=W(-489265-(-434371))Y[C]=M T=-98857-(-98957)V=n[A]c=-834874-(-835129)A=W(-629955-(-575047))I=V[A]A=540011-540010 V=I(A,T)K=897921-897921 A=z()D=438512+-438510 T=-37095-(-37095)U=W(737982-792875)Y[A]=V I=Y[m]V=I(T,c)T=z()Y[T]=V o=136649-136648 c=-506628-(-506629)I=Y[m]i=Y[A]V=I(c,i)c=z()Y[c]=V V=Y[m]S=115080+-105080 i=V(o,D)V=-848949+848950 I=i==V i=z()D=W(-799063-(-744209))Y[i]=I I=W(-876684-(-821818))R=n[U]V=W(537279+-592148)I=E[I]w=Y[m]G={w(K,S)}U=R(B(G))R=W(-1014914+960060)x=U..R o=D..x D=W(-501008-(-446194))I=I(E,V,o)o=z()x=p(1041317+12783089,{m;C,a;N,u,Q,i;o;A,c,T,y})Y[o]=I V=n[D]D={V(x)}I={B(D)}D=I I=Y[i]I=I and 415096-413644 or-516627+3949059 end end else if I<13955795-349222 then if I<-870541+14258513 then if I<-867209+13496029 then V=W(-519610-(-464815))I=n[V]s=W(-1072834-(-1017903))V=n[s]s=W(470802-525733)n[s]=I s=W(-543421-(-488626))n[s]=V I=931180-(-859497)s=Y[F[-121748+121749] ]u=s()else I=Y[F[-685414-(-685421)] ]I=I and 11260382-625252 or 15529814-572017 end else V=243986+2705463 u=W(-817903+763093)N=11008763-(-440925)s=u^N I=V-s V=W(-206565-(-151584))s=I I=V/s V={I}I=n[W(-221317-(-166477))]end else if I<442547+13524063 then t=-943821-(-943822)u=Y[F[-661449-(-661450)] ]d=4094+-4092 N=u(t,d)u=-284116-(-284117)s=N==u V=s I=s and 7279251-197907 or 4484180-579645 else I=8194126-(-126812)f=q==k M=f end end end else if I<15924357-1022122 then if I<193294+14445471 then if I<13571498-(-842001)then if I<277412+14015404 then V={}I=n[W(-652446-(-597456))]else N=W(795064+-849964)u=n[N]N=W(-200618-(-145673))I=n[W(-221284-(-166427))]s=u[N]N=Y[F[-183947-(-183948)] ]u={s(N)}V={B(u)}end else N=N+d u=N<=t m=not b u=m and u m=N>=t m=b and m u=m or u m=-16028+8568956 I=u and m u=1524190-838083 I=I or u end else if I<-615812+15361008 then i=O(i)A=O(A)c=O(c)I=10993125-(-980265)D=nil C=O(C)o=O(o)T=O(T)else Z=W(-372675+317775)k=n[Z]Z=W(494156-549122)I=632213+15317762 q=k[Z]y=q end end else if I<15272613-(-328678)then if I<14481636-(-897706)then if I<14726309-(-395256)then u=288880-288879 I={}N=Y[F[267954-267945] ]s=I t=N N=-184223-(-184224)I=14255977-(-357858)d=N N=721935+-721935 b=d<N N=u-d else V={}I=n[W(-662578-(-607610))]end else d=W(-971976+917174)s=W(32101+-86936)V=n[s]u=Y[F[152546-152545] ]b=3394311660459-580991 N=Y[F[-904184-(-904186)] ]t=N(d,b)s=u[t]d=W(-1009206+954365)I=V[s]b=20549391763448-90775 u=Y[F[841183-841182] ]N=Y[F[-128479+128481] ]t=N(d,b)s=u[t]u=Y[F[656153-656150] ]d=W(210732-265735)l=11084619884484-(-158821)V=I(s,u)m=W(236522-291534)s=V u=Y[F[-369416+369417] ]N=Y[F[-776962-(-776964)] ]b=1256+18752708500788 t=N(d,b)V=u[t]u=z()I=s[V]s=nil Y[u]=I V=Y[u]t=Y[F[-414504+414505] ]d=Y[F[512773+-512771] ]b=d(m,l)m=W(546515+-601442)N=t[b]I=V[N]N=z()Y[N]=I I=false t=z()Y[t]=I l=22242287940740-(-78833)V=Y[F[-614566+614567] ]d=Y[F[-262172+262174] ]q=W(36995+-91901)b=d(m,l)d=z()I=V[b]Y[d]=I b=z()I=871259-871258 Y[b]=I V=Y[u]k=-378324+26012855596325 l=Y[F[-895478-(-895479)] ]y=Y[F[976125-976123] ]a=y(q,k)m=l[a]I=V[m]V=W(401351+-456240)m=H(3960037-922997,{t;d,u;F[-636742-(-636743)];F[-603149-(-603151)],b,N})b=O(b)u=O(u)V=I[V]d=O(d)V=V(I,m)V={}N=O(N)t=O(t)I=n[W(-355126-(-300148))]end else if I<16633095-255304 then V=y I=a I=y and 11580977-(-660793)or 9916726-704868 else N=494270-494269 u=Y[F[-38760+38763] ]s=u~=N I=s and 8941241-963194 or-914816+7544931 end end end end end end end I=#X return B(V)end,{},function()u=(66904+-66903)+u s[u]=-340266-(-340267)return u end,function(n,W)local B=N(W)local h=function(h,F,X)return I(n,{h,F;X},W,B)end return h end,function(n,W)local B=N(W)local h=function(h,F,X,r,V)return I(n,{h;F,X;r,V},W,B)end return h end return(d(-386638+9146896,{}))(B(V))end)(getfenv and getfenv()or _ENV,unpack or table[W(-854831-(-799865))],newproxy,setmetatable,getmetatable,select,{...})end)(...)
`n]],
["https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot"] = [[`n-- This file is protected by goofyscator V7.2 >> goofyscator.lua.cz <<
return({sgH=function(l,o,t,r)local e,n={},0 for t=t,r do n=n+1 e[n]=(l["k"])(l,o,t)end e["n"]=n o[0x162C4009]=e end,JT=function(n,l,d)local i=n["PAZ"] local o,e=(n["HOXvl"])(n,l,1)local h=i["bxor"](o or 0,0x2E49)local r=h if d then local n=(((d+0x3E54)*89)+740)%0xFFFF r=r-n end local t={[1]=h}if r==-1 then local o o,e=(n["HOXvl"])(n,l,e)local r={}for i=1,o or 0 do local o o,e=(n["HOXvl"])(n,l,e)if o==nil then break end local l=n["kX"]["string"]["sub"](l,e,e+o-1)e=e+o r[i]=(n["JT"])(n,l)end t[3]=r return t end local c local x local u local a local o o,e=(n["HOXvl"])(n,l,e)local f=0xE58 if d then f=(((d+0x6458)*309)+0xE58)%0xFFFF end o=i["bxor"](o or f,f)if i["band"](o,2)~=0 then x,e=(n["kVGu"])(n,l,e)end if i["band"](o,4)~=0 then u,e=(n["kVGu"])(n,l,e)end if i["band"](o,1)~=0 then c,e=(n["jo"])(n,l,e)c=(c or 7)-7 end if i["band"](o,8)~=0 then a,e=(n["rWdzP"])(n,l,e)end local e={[0x3D9620EE]=0x1C2C,[0x379FB1A]=0}local l={[0x3D9620EE]=0x1C2C,[0x379FB1A]=0}t[6]=(c or 0)+5 t[7]={[1]=x or e,[2]=u or l,[3]=(h%23)}if(r==0x1824 or r==0x1D15 or r==0x3326)then t[9]=(n["hTI"])(n,a or"")elseif a and a~=""then t[9]=a end return t end,wADf=function(e,o,r,n)if type(o)~="table"then return n or 0 end n=n or 0 local t=n<0 if not t and n==0 then return n end local function i(l)if type(l)~="table"or(not t and n==0)then return end local o=l[0x3D9620EE]or 0x1C2C if o==0x7651 and l[0x4BC508B]==nil then local o=r[l[0x379FB1A]or 0]l[0x4BC508B]=o==nil and e["N"] or o if not t then n=n-1 end end end i((e["wAzFg"])(e,o))i((e["Bsux"])(e,o))local l=o[3]if type(l)=="table"then for o=1,#l do n=(e["wADf"])(e,l[o],r,n)if not t and n==0 then break end end end return n end,TUA=function(n,l,e,o)local l,r=(n["EoV"])(n,l)local l,t=(n["OBsY"])(n,l,e)return{[0x5985CD8E]=l,[0x429C6C22]=t or{},[0x3F1F53A]=(n["hPc"])(n,r,e),[0x784CDD9B]="",[0x12F8AC60]="",[0x23C615D8]=o or 0}end,nyS=function(n,e,o)local a=n["k"] local d,i,l=(0x1B8660-0x1B865E),(0x75C78F-0x75C78F),(0x1F6A8A-0x1F6A89)local r,c=n["rCcDf"],n["sgH"] local t,o=((o[6]or 5)-5),(((((o[7]or{})[1]or{})))[0x379FB1A]or i)if o==i then c(n,e,t,e[0xA86E4AB])elseif o==l then r(n,e,{},i)elseif o==d then r(n,e,{a(n,e,t)},l)else local i={}for o=l,o-l do i[o]=a(n,e,t+o-l)end r(n,e,i,o-l)end end,w=function(n,o,h,d,u)local e=n["kX"] local a,s,c,f,x=e["string"]["sub"],e["table"]["concat"],e["string"]["byte"],n["PAZ"],e["string"]["char"] local t local l local r local i local e=h t,e=(n["HOXvl"])(n,o,e)l,e=(n["HOXvl"])(n,o,e)r,e=(n["HOXvl"])(n,o,e)i,e=(n["HOXvl"])(n,o,e)if t==nil or l==nil or r==nil or i==nil then return nil end local h=l+r if t<0 or h<=0 or i<0 then return nil end local i=#d if i==0 then return nil end local e,t=e+t,{}for n=1,h do local e=c(o,e+n-1)if not e then return nil end local l=((n-1)%i)+1 local o,l=c(d,l),((u*37)+(n*13)+0x4B10)%256 t[n]=x(f["bxor"](f["bxor"](e,l),o))end local e=s(t)local e,l=a(e,1,l),a(e,l+1,l+r)local e=(n["ZtZ"])(n,e,l)return(n["UVPlx"])(n,e)end,JTPfN=function(e,o,l)local t,n=e["PVRDQ"],(0x7455EB-0x7455EB)local r,l=(((((l[7]or{})[1]or{})))[0x379FB1A]or n),((l[6]or 5)-5)for n=n,r do t(e,o,l+n,nil)end end,Bg=function(n,l)local e=n["kX"] local e,t,o=(n["eK"])(n,l),e["string"]["sub"],"\0PmXHAxc9"local l=#o if#e<=l or t(e,1,l)~=o then return e end local l=l+1 local t local o t,l=(n["rWdzP"])(n,e,l)o,l=(n["rWdzP"])(n,e,l)if not t or not o or o==""or l~=(#e+1)then return e end return(n["eK"])(n,(n["ZtZ"])(n,t,o))end,hPc=function(n,i,h)local l=n["kX"] local a,s,c,f,r,t,e,d,b,g,x,o=#i,l["rawset"] or rawset,#h,n["PAZ"],{},{},1,l["string"]["byte"],l["string"]["char"],l["table"]["concat"],l["setmetatable"] or setmetatable,1 if c==0 then return{}end while e<=a do local l l,e=(n["HOXvl"])(n,i,e)if l==nil or l<0 or e+l-1>a then break end t[o]=e r[o]=l e=e+l o=o+1 end local a={}local function u(e,o)local l=n["Ak"] if not l or type(e)~="table"or e[4]~=nil then return end local n=e[1]if n==nil then return end local o=(((o+0x3E54)*89)+740)%0xFFFF local n=l[n-o]if n then e[4]=n end end return x(a,{__index=function(x,e)local a,o=t[e],r[e]if not a or not o then return nil end local l={}for n=1,o do local t,o=((e+n-2)%c)+1,d(i,a+n-1)local t,e=((e*29)+(n*17)+0x854)%256,d(h,t)l[n]=b(f["bxor"](f["bxor"](o,t),e))end local n=(n["JT"])(n,g(l),e)u(n,e)s(x,e,n)t[e]=nil r[e]=nil return n end,__call=function(o,i,e)e=e or 0 local r=e<0 if not r and e==0 then return e end local l=l["next"] or next for t,l in l,t do if l then e=(n["wADf"])(n,o[t],i,e)if not r and e==0 then break end end end if n["Ak"] then for n,e in l,o do if type(n)=="number"then u(e,n)end end end return e end,__metatable={}})end,nqbDe=function(l,n)if type(n)~="table"then return n end if l["VPfAq"]~=n then return""end local o,t,h,e,u,c=n[0x530C40F0],n[0x43BEDB9],n[0x3C60792E],l["kX"],n[0x13598DA6],n[0x564E41D1]if type(t)~="table"or type(o)~="table"or type(h)~="table"or type(u)~="table"or type(c)~="table"then return""end local x,d,a,i=e["string"]["sub"],e["string"]["byte"],e["table"]["concat"],"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!#$%&()*+,./:;<=>?@[]^_`{|}~\""local e,r=#i,l["pJ"] local function f(o,n)local e={}for l=1,#n do local n=o[n[l] ]if type(n)~="string"then return nil end e[l]=n end return a(e)end local o,t=f(t,o),f(h,u)if not t or not o then return""end n[0x43BEDB9]=nil n[0x530C40F0]=nil n[0x3C60792E]=nil n[0x13598DA6]=nil n[0x564E41D1]=nil l["VPfAq"]=nil local l,c={},((c[0x66A63BE8]or 0)-(c[0x3B776A2D]or 0))%e for n=1,#t do local o=r[d(t,n)]if o==nil then return""end local e=(o-c-(n*11))%e l[n]=x(i,e+1,e+1)end local h=a(l)local l=#h if l==0 then return""end local f,c,t={},l%e,c%e for n=1,#o do local o,l=r[d(h,((n-1)%l)+1)],r[d(o,n)]if o==nil or l==nil then return""end t=(t+(o*17)+(n*13)+(c*7))%e local e=(l-t-o-n)%e f[n]=x(i,e+1,e+1)c=l end return a(f)end,oou=function(e,n)return(n[6]or 5)-5 end,k=function(l,e,n)return e[0x79DFD3CD][n]end,pOJ=function(l,r,a)local i,n=l["X"],(0x490A3B-0x490A3B)local t,o,f=(((a[7]or{})[2]or{})),(((a[7]or{})[1]or{})),r[0x79DFD3CD]local c,h,d,u=t[0x3D9620EE]or 0x1C2C,t[0x379FB1A]or n,o[0x3D9620EE]or 0x1C2C,o[0x379FB1A]or n local n local e if d==0x1F92 then n=f[u]elseif d==0x697C then n=u elseif d==0x7651 then n=o[0x4BC508B]if n==nil then n=i(l,r,o)elseif n==l["N"] then n=nil end else n=i(l,r,o)end if c==0x1F92 then e=f[h]elseif c==0x697C then e=h elseif c==0x7651 then e=t[0x4BC508B]if e==nil then e=i(l,r,t)elseif e==l["N"] then e=nil end else e=i(l,r,t)end f[((a[6]or 5)-5)]=n+e end,JSznK=function(n,e,l)local t=n["q"] n["q"]=e or true local o=(n["St"])(n,e,l or 0)n["q"]=t local l=n["dQS"] if not l then l={}n["dQS"]=l end local e=l[1]if not e then e={function(e,l)return(n["f"])(n,e,l)end,function(e,l)return(n["aGF"])(n,e,l)end,function(e)return(n["rT"])(n,e)end}e["n"]=3 l[1]=e end return(n["NudW"])(n,o,e)end,fGN=function(n,l)local d,e=(n["rWdzP"])(n,l,1)local c c,e=(n["rWdzP"])(n,l,e)local a a,e=(n["HOXvl"])(n,l,e)local o o,e=(n["HOXvl"])(n,l,e)local i={}for a=1,o or 0 do local r local t local o r,e=(n["rWdzP"])(n,l,e)t,e=(n["rWdzP"])(n,l,e)o,e=(n["HOXvl"])(n,l,e)i[a]={[0x12F8AC60]=r or"",[0x784CDD9B]=t or"",[0x23C615D8]=o or 0}end return d or"",c or"",a or 0,i end,Ev=function(l,o,t)local d,c=l["X"],(0x3B4511-0x3B4511)local e,r=(((t[7]or{})[2]or{})),o[0x79DFD3CD]local a,i=e[0x379FB1A]or c,e[0x3D9620EE]or 0x1C2C local n if i==0x1F92 then n=r[a]elseif i==0x697C then n=a elseif i==0x7651 then n=e[0x4BC508B]if n==nil then n=d(l,o,e)elseif n==l["N"] then n=nil end else n=d(l,o,e)end r[((t[6]or 5)-5)]=r[(((((t[7]or{})[1]or{})))[0x379FB1A]or c)][n]end,DMH=function(n,l,o)local x,h,d=n["PVRDQ"],n["TUA"],n["nZL"] local e,f,i=(0x3D2FA0-0x3D2F9F),(0x5306B8-0x5306B8),(0x28CFD2-0x28CFD0)local c,a,X,k,s=n["V"],(n["kX"]["next"] or next),(n["kX"]["setmetatable"] or setmetatable),n["W"],n["fy"] or{}local t,u=(o[9]or{}),((o[6]or 5)-5)local r,o=t[0x6DEB42AA],t[0x656910A0]if o==nil then local e=t[0x314B9A74]or""if e==""then o=false else local n=d(n,e)o=a(n)and n or false end t[0x656910A0]=o end local t=l[0x73D07583][r]if not t then local e=s[r]if not e then x(n,l,u,function()end)return end t=h(n,e[0x12F8AC60],e[0x784CDD9B],e[0x23C615D8])l[0x73D07583][r]=t end local g,s,W,a,b,V=l[0x24F43DAC],l[0x47CC46CE]or 0xC9A2,l[0x73D07583],l[0x6CF14ADE],l[0xD53F5FD]or 0x8A6AA,l[0x79DFD3CD]local r local function E(u,k)local d,l,x,h,E={},e,{},t[0x23C615D8]or f,{}if o then X(x,{["__index"]=function(t,l)local l=o[l]if not l then return nil end if l[e]==f then return V[c(n,l[i])]end return g[l[i] ]end,["__newindex"]=function(r,l,t)local l=o[l]if not l then return end if l[e]==f then V[c(n,l[i])]=t else g[l[i] ]=t end end,["__metatable"]={}})end for l=e,h do E[c(n,l-e)]=u[l]end for n=h+e,k do d[l]=u[n]l=l+e end d["n"]=l-e local n={[0x79DFD3CD]=E,[0x24F43DAC]=x,[0x27B27BBE]=t[0x5985CD8E],[0x72B3CC51]=(b-s)+e,[0xD53F5FD]=b,[0x47CC46CE]=s,[0xA86E4AB]=h-e,[0x6D2DD5E9]=d,[0x6CF14ADE]=a,[0x73D07583]=W,[0x4E4229F6]=t,[0x6D9B07B6]=r}return n,t[0x3F1F53A]end r=function(...)local e,l=select("#",...),{...}local e,l=E(l,e)return k(n,e,l)end if n["aQe"] then n["aQe"][r]=function(l,e)if l==n["OyA"] then if e~=nil then a=e return r end return a end return E(l,e)end end x(n,l,u,r)end,EoV=function(n,o)local t,e=(n["rWdzP"])(n,o,1)local l l,e=(n["rWdzP"])(n,o,e)return t or"",l or""end,NudW=function(n,o,l)local e=o and o[1]if not e then return end n["fy"]=o[2]or{}n["Ak"]=n["Ak"] or(n["DqPdJ"])(n)e[0x429C6C22]=e[0x429C6C22]or{}(n["VUQ"])(n,e[0x3F1F53A],e[0x5985CD8E],-1)local d,o,a={},{},{}o["n"]=0 local i=0 if l then local e,c,d,r=1,e[0x23C615D8]or 0,n["V"],l["n"] or#l for t=1,r do local l=l[t]a[(d)(n,t-1)]=l if t>c then o[e]=l e=e+1 end end o["n"]=e-1 if r>0 then i=r-1 end end local l={[0x79DFD3CD]=a,[0x24F43DAC]=d,[0x27B27BBE]=e[0x5985CD8E],[0x72B3CC51]=(0x8A6AA-0xC9A2)+1,[0xD53F5FD]=0x8A6AA,[0x47CC46CE]=0xC9A2,[0xA86E4AB]=i,[0x6D2DD5E9]=o,[0x6CF14ADE]=n["vIsJB"],[0x73D07583]=e[0x429C6C22],[0x4E4229F6]=e}return(n["W"])(n,l,e[0x3F1F53A])end,V=function(e,n)return n end,qYTBE=function(e,n,l)local o=e["X"] n[0x79DFD3CD][((l[6]or 5)-5)]=o(e,n,(((l[7]or{})[1]or{})))end,n=function(e,n)return n[0x379FB1A]or 0 end,FKW=function(i,l,o)if l==nil or l==""then return l or""end local n=i["kX"] local f,t,c,d,a=n["table"]["concat"],(n["table"] and n["table"]["unpack"])or n["unpack"],n["string"]["char"],n["math"]["min"],n["string"]["byte"] if not t then t=function(l,n,e)n=n or 1 e=e or#l if n>e then return end return l[n],t(l,n+1,e)end end local n,e,r=0,1,{}while e<=#l do local t=a(l,e)if not t then break end e=e+1 if t<128 then local o=t+1 if e+o-1>#l then return nil end for o=0,o-1 do n=n+1 r[n]=a(l,e+o)end e=e+o else local t=(t-128)+3 local o o,e=(i["HOXvl"])(i,l,e)if o==nil then return nil end local e=o+1 if e<=0 or e>n then return nil end local e=n-e+1 for l=1,t do local l=r[e]if l==nil then return nil end n=n+1 r[n]=l e=e+1 end end if o and o~=0 and n>o then return nil end end if o and o~=0 and n~=o then return nil end local l,e,o=1,1,{}while e<=n do local n=d(e+95,n)o[l]=c(t(r,e,n))l=l+1 e=n+1 end return f(o)end,jVxHR=function(l,o,i)local a,s=(0x6F158A-0x6F158A),(0x4922CC-0x4922CB)local c=l["X"] local r,t,h=(((i[7]or{})[2]or{})),(((i[7]or{})[1]or{})),o[0x79DFD3CD]local d,f,u,x=r[0x3D9620EE]or 0x1C2C,t[0x3D9620EE]or 0x1C2C,r[0x379FB1A]or a,t[0x379FB1A]or a local n local e if f==0x1F92 then n=h[x]elseif f==0x697C then n=x elseif f==0x7651 then n=t[0x4BC508B]if n==nil then n=c(l,o,t)elseif n==l["N"] then n=nil end else n=c(l,o,t)end if d==0x1F92 then e=h[u]elseif d==0x697C then e=u elseif d==0x7651 then e=r[0x4BC508B]if e==nil then e=c(l,o,r)elseif e==l["N"] then e=nil end else e=c(l,o,r)end local n=n<=e if(((i[6]or 5)-5)>a and not n)or(((i[6]or 5)-5)<=a and n)then o[0x72B3CC51]=o[0x72B3CC51]+s end end,ui=function(l,o,a)local n,i=(0x144CAE-0x144CAE),l["X"] local r,d,t=(((a[7]or{})[1]or{})),o[0x79DFD3CD],(((a[7]or{})[2]or{}))local c,u,f,h=t[0x3D9620EE]or 0x1C2C,t[0x379FB1A]or n,r[0x3D9620EE]or 0x1C2C,r[0x379FB1A]or n local e local n if f==0x1F92 then e=d[h]elseif f==0x697C then e=h elseif f==0x7651 then e=r[0x4BC508B]if e==nil then e=i(l,o,r)elseif e==l["N"] then e=nil end else e=i(l,o,r)end if c==0x1F92 then n=d[u]elseif c==0x697C then n=u elseif c==0x7651 then n=t[0x4BC508B]if n==nil then n=i(l,o,t)elseif n==l["N"] then n=nil end else n=i(l,o,t)end d[((a[6]or 5)-5)]=e-n end,qXMY=function(l,e,o)local d,f,c,n=(0x65DF6C-0x65DF69),(0x436588-0x436586),(0x774868-0x774868),(0x3A5C6C-0x3A5C6B)local t=l["k"] local a,o,i=(((((o[7]or{})[1]or{})))[0x379FB1A]or c),((o[6]or 5)-5),(((((o[7]or{})[2]or{})))[0x379FB1A]or c)local r=t(l,e,o)if r==nil then return end if a==c then local a=e[0xA86E4AB]-o for a=n,a do r[((i-n)*50)+a]=t(l,e,o+a)end elseif a==d and i==n then r[n]=t(l,e,o+n)r[f]=t(l,e,o+f)r[d]=t(l,e,o+d)else for a=n,a do r[((i-n)*50)+a]=t(l,e,o+a)end end end,YTR=function(n,e,l)if e==nil or e==""then return{}end local o=n["kX"] local r,i,d,c,a,e,o={},(n["ZtZ"])(n,e,l),o["string"]["byte"],#l,n["PAZ"],1,1 while o<=#i do local t t,o=(n["HOXvl"])(n,i,o)if t==nil then break end local n=d(l,((e-1)%c)+1)local n=a["bxor"]((e*965)+0x2919,n)r[e]=a["bxor"](t,n)e=e+1 end return r end,cZ=function(l,r,n)local i,e=l["X"],(0x241380-0x241380)local a=r[0x79DFD3CD]local t,u,o=(((n[7]or{})[1]or{})),a[((n[6]or 5)-5)],(((n[7]or{})[2]or{}))local f,c,d,h=o[0x379FB1A]or e,t[0x3D9620EE]or 0x1C2C,o[0x3D9620EE]or 0x1C2C,t[0x379FB1A]or e local n local e if c==0x1F92 then n=a[h]elseif c==0x697C then n=h elseif c==0x7651 then n=t[0x4BC508B]if n==nil then n=i(l,r,t)elseif n==l["N"] then n=nil end else n=i(l,r,t)end if d==0x1F92 then e=a[f]elseif d==0x697C then e=f elseif d==0x7651 then e=o[0x4BC508B]if e==nil then e=i(l,r,o)elseif e==l["N"] then e=nil end else e=i(l,r,o)end u[n]=e end,X=function(e,r,n)local t,o=n[0x379FB1A]or 0,n[0x3D9620EE]or 0x1C2C if o==0x7651 then local l=n[0x4BC508B]if l~=nil then if l==e["N"] then return nil end return l end local l=r[0x27B27BBE][t]if l==e["N"] then n[0x4BC508B]=e["N"] return nil end n[0x4BC508B]=l==nil and e["N"] or l return l elseif o==0x1F92 then return r[0x79DFD3CD][t]elseif o==0x697C then return t end return nil end,QKw=function(o,n,e)local r=o["PVRDQ"] local t,l=(0x345F98-0x345F97),(0xAF034-0xAF034)r(o,n,((e[6]or 5)-5),(((((e[7]or{})[1]or{})))[0x379FB1A]or l)==t)if(((((e[7]or{})[2]or{})))[0x379FB1A]or l)~=l then n[0x72B3CC51]=n[0x72B3CC51]+t end end,rWdzP=function(l,o,n)local e=l["kX"] local t=e["string"]["sub"] local e e,n=(l["HOXvl"])(l,o,n)if e==nil then return nil,n end local l=t(o,n,n+e-1)return l or"",n+e end,GCj=function(e,n,l)local o=e["V"] local l=((l[6]or 5)-5)for l=l,n[0xA86E4AB]do n[0x79DFD3CD][o(e,l)]=nil end end,WU=function(l,e,n)local l=(0x1875AD-0x1875AD)e[0x24F43DAC][(((((n[7]or{})[1]or{})))[0x379FB1A]or l)]=e[0x79DFD3CD][((n[6]or 5)-5)]end,FYvTe=function(e,n)return n[0x3D9620EE]or 0x1C2C end,["dgFm"]=function(n,n)return{[0x3C60792E]={[0x14B87877]="3#8",[0x79BC906E]="en7L",[0x39C6F373]="euWX"},[0x43BEDB9]={[0x60A541D5]="p?7YW{eno[ek&:1+$Kpil{h?6j~ad^sMU46E+4zo_\"Wqw8Y8icJN`AMaec:x0us?0S#_5Mk$zL\"Da0h<dd]H%sPmL7{*g|xxw7hf^uX8F(\"I44>kjg{.)O5L0V{x37^`Jp$}P1ok.=~gSX48TA,1M8_J[YG<A=1nI<#!D3l0(Hp06;X>KG+@,mH005@}iO|`nmx,Ze=ZC.6/?P311H|xFJF97|={JT{/oG_zeBvJ^gw*owJekj=yF^4ac@PD\"v[`#zQVy%u/#D1OD|9@v!4[VJ{&?9|NvI+QZvN@T\">!?]Y$S}6P7{L#Qf*3dfTy@NLZ)=;+Z3Y9`g=LrEL{,7ne8T1Y)VR#l{U:<aD%7@n~6+,J?UPV>R;BsLW+N3G=\"xml()esC(1!.>a)MHE:nUx:5nI,x#@t!#V?{?f%&HqPRO)T8D=ja+:mv_4:[+`UeN*Tvi_G*IP3^_3mGhd8)QKda.Fq%Q.n{48trD,BR%<,<F(C<CW\"Qm*c:Jy^M!fiqbrx84qiRp>h.B/Xv<h<cN(+3KQ9H6na@.%~[,s--[[
================================================================================
  POTATOOLS  |  Studio Test Suite
  A single-file, dependency-free Luau script for Roblox Studio testing.
  - Draggable, clean main hub with a scrollable + searchable game list.
  - Clicking a game opens its OWN separate draggable feature window.
  - Real, functional systems: ESP (Highlight + Billboard), Aimbot, Triggerbot,
    Hitbox Expander, Fly, Noclip, WalkSpeed, JumpPower, Infinite Jump, Teleport,
    FOV circle, notifications, keybinds and more.
  - No loadstring / no web require. Everything is pcall-guarded so it cannot
    fail to load.
  HOW TO USE: Place inside a LocalScript in StarterPlayer > StarterPlayerScripts,
  StarterGui, or run it from your executor while testing your own copies.
================================================================================
]]

--==============================================================================
--// GETGENV SHIM  (eve's fix: globals instead of locals to beat Luau's
--   200-local-per-function limit so this loads cleanly via loadstring).
--   In executors getgenv() returns the shared environment; in Studio we map it
--   to _G so bare global lookups resolve everywhere. Combined with converting
--   top-level `local X` -> `X` (globals), the chunk stays well under 200 locals.
--==============================================================================
getgenv = getgenv or function() return _G end
local _P = getgenv()          -- single local; everything else is global below
_P.Potatools = _P.Potatools or {}

--==============================================================================
--// BOOT GUARD  (loadstring-safe: ensure the game is fully loaded first)
--   This makes the script safe to run via:  loadstring(source)()
--   It also dedupes if re-executed and recovers from any load error.
--==============================================================================
if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

-- Clean up any previous run so re-executing never duplicates the UI.
pcall(function()
    local _plr = game:GetService("Players").LocalPlayer
    for _, parent in ipairs({ game:GetService("CoreGui"), _plr:FindFirstChildOfClass("PlayerGui") }) do
        if parent then
            local old = parent:FindFirstChild("MultiGameHub_Root")
            if old then old:Destroy() end
        end
    end
end)

--==============================================================================
--// SERVICES
--==============================================================================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local VirtualUser        = game:GetService("VirtualUser")
local CollectionService  = game:GetService("CollectionService")
local HttpService        = game:GetService("HttpService")
local Stats              = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- Forward declarations so closures bind to the correct locals.
local ScreenGui
local disableAllFeatures
local isFriend
local isTarget
local FriendList
local TeleportPro
local getPlayerNames
local findPlayerByName
local addMovement
local randPos
local GameList

--==============================================================================
--// COMPATIBILITY SHIMS  (so the script also runs in plain Roblox Studio,
--   where executor-only globals like firetouchinterest / setclipboard don't exist)
--==============================================================================
if not firetouchinterest then
    -- Best-effort vanilla fallback: briefly overlap the two parts to fire .Touched.
    firetouchinterest = function(partA, partB, toggle)
        pcall(function()
            if toggle == 0 and partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
                local oldCF = partA.CFrame
                partA.CFrame = partB.CFrame
                task.wait()
                partA.CFrame = oldCF
            end
        end)
    end
end
if not setclipboard then
    setclipboard = function(txt) print("[Clipboard]", tostring(txt)) end
end

--==============================================================================
--// SAFE GUI PARENT  (avoid "cannot parent" / level errors)
--==============================================================================
local function getGuiParent()
    local ok, core = pcall(function()
        if CoreGui and CoreGui.Name == "CoreGui" then return CoreGui end
    end)
    if ok and core then return core end
    -- Studio / safe fallback
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then
        pg = Instance.new("PlayerGui")
        pg.Parent = LocalPlayer
    end
    return pg
end

-- Remove any previous instance so re-running the script never duplicates UI.
pcall(function()
    local old = getGuiParent():FindFirstChild("MultiGameHub_Root")
    if old then old:Destroy() end
end)

--==============================================================================
--// THEME  (clean, modern dark UI inspired by common script hubs)
--==============================================================================
local Theme = {
    Background      = Color3.fromRGB(22, 22, 28),
    BackgroundDark  = Color3.fromRGB(16, 16, 20),
    Sidebar         = Color3.fromRGB(26, 26, 34),
    Element         = Color3.fromRGB(34, 34, 44),
    ElementHover    = Color3.fromRGB(44, 44, 56),
    Text            = Color3.fromRGB(236, 236, 242),
    TextDim         = Color3.fromRGB(150, 150, 162),
    -- Potatools branding: bright light red -> black gradient
    Accent          = Color3.fromRGB(255, 60, 60),
    AccentBright    = Color3.fromRGB(255, 140, 140),
    AccentDark      = Color3.fromRGB(0, 0, 0),
    Green           = Color3.fromRGB(76, 209, 142),
    Red             = Color3.fromRGB(235, 77, 92),
    Yellow          = Color3.fromRGB(245, 196, 76),
    Blue            = Color3.fromRGB(86, 156, 240),
    Stroke          = Color3.fromRGB(55, 55, 70),
    Rounded         = UDim.new(0, 8),
    RoundedBig      = UDim.new(0, 14),
    Font            = Enum.Font.Gotham,
    FontBold        = Enum.Font.GothamBold,
    FontMono        = Enum.Font.Code,
}

--==============================================================================
--// SMALL UI HELPERS
--==============================================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function gradient(parent, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

local function listLayout(parent, paddingY, horizontalAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, paddingY or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = horizontalAlign or Enum.HorizontalAlignment.Center
    l.Parent = parent
    return l
end

-- safely tween a property
local function tween(instance, time, props)
    local t = TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

--==============================================================================
--// NOTIFICATIONS  (in-GUI toast + Roblox core notification)
--==============================================================================
local NotifyHolder
local function buildNotifyHolder(parent)
    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Size = UDim2.new(0, 320, 1, -40)
    NotifyHolder.Position = UDim2.new(1, -336, 0, 20)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = parent
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.Parent = NotifyHolder
    return NotifyHolder
end

local function notify(title, text, duration, color)
    duration = duration or 3.5
    color = color or Theme.Accent
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
        })
    end)
    if not NotifyHolder then return end
    local card = Instance.new("Frame")
    card.Name = "Notify"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.BackgroundDark
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.Parent = NotifyHolder
    corner(card, Theme.Rounded)
    stroke(card, color, 0, 0)
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card
    corner(accentBar, UDim.new(0, 2))
    local tb = Instance.new("TextLabel")
    tb.BackgroundTransparency = 1
    tb.Position = UDim2.new(0, 14, 0, 8)
    tb.Size = UDim2.new(1, -22, 0, 16)
    tb.Font = Theme.FontBold
    tb.TextSize = 13
    tb.TextColor3 = Theme.Text
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Text = tostring(title)
    tb.Parent = card
    local tx = Instance.new("TextLabel")
    tx.BackgroundTransparency = 1
    tx.Position = UDim2.new(0, 14, 0, 26)
    tx.Size = UDim2.new(1, -22, 0, 14)
    tx.AutomaticSize = Enum.AutomaticSize.Y
    tx.Font = Theme.Font
    tx.TextSize = 12
    tx.TextColor3 = Theme.TextDim
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.TextWrapped = true
    tx.Text = tostring(text)
    tx.Parent = card
    local inT = tween(card, 0.25, { BackgroundTransparency = 0.05 })
    task.delay(duration, function()
        local out = tween(card, 0.3, { BackgroundTransparency = 1 })
        tween(tb, 0.3, { TextTransparency = 1 })
        tween(tx, 0.3, { TextTransparency = 1 })
        tween(accentBar, 0.3, { BackgroundTransparency = 1 })
        out.Completed:Wait()
        card:Destroy()
    end)
end

--==============================================================================
--// CHARACTER / ROOT HELPERS
--==============================================================================
local function getChar()
    return LocalPlayer.Character
end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP(char)
    char = char or getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end
local function isAlive(plr)
    if not plr then plr = LocalPlayer end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c ~= nil and h ~= nil and h.Health > 0
end

--==============================================================================
--// DRAGGING UTILITY  (works on PC + mobile)
--==============================================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragInput, mousePos, framePos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, math.clamp(framePos.X.Offset + delta.X, -frame.AbsoluteSize.X + 60, Workspace.CurrentCamera.ViewportSize.X - 60),
                framePos.Y.Scale, math.clamp(framePos.Y.Offset + delta.Y, 0, Workspace.CurrentCamera.ViewportSize.Y - 40)
            )
        end
    end)
end

--==============================================================================
--// Z-INDEX / WINDOW STACK MANAGEMENT
--==============================================================================
local TopZ = 10
local function bringToFront(frame)
    TopZ = TopZ + 1
    frame.ZIndex = TopZ
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("GuiObject") then
            d.ZIndex = TopZ + (d.ZIndex - 10)
        end
    end
end

--==============================================================================
--// CORE UI LIBRARY  (window + elements)
--==============================================================================
local OpenWindows = {}

local function createWindow(title, subtitle, sizeX, sizeY, pos)
    local self = {}
    self._destroyed = false
    self._elements = {}
    self._keybinds = {}

    local root = Instance.new("Frame")
    root.Name = "Window_" .. tostring(title)
    root.Size = UDim2.new(0, sizeX or 470, 0, sizeY or 460)
    root.Position = pos or UDim2.new(0.5, -(sizeX or 470)/2, 0.5, -(sizeY or 460)/2)
    root.BackgroundColor3 = Theme.Background
    root.BorderSizePixel = 0
    root.ZIndex = 10
    root.Parent = ScreenGui
    corner(root, Theme.RoundedBig)
    stroke(root, Theme.Stroke, 1, 0.2)

    -- shadow-ish top accent
    local accentLine = Instance.new("Frame")
    accentLine.Name = "Accent"
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 11
    accentLine.Parent = root
    gradient(accentLine, Theme.AccentBright, Theme.AccentDark, 0)
    local aCorner1 = Instance.new("UICorner"); aCorner1.CornerRadius = Theme.RoundedBig; aCorner1.Parent = accentLine

    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    corner(header, Theme.RoundedBig)
    local hFill = Instance.new("Frame"); hFill.Size = UDim2.new(1,0,0,22); hFill.BackgroundColor3 = Theme.Sidebar; hFill.BorderSizePixel = 0; hFill.ZIndex = 11; hFill.Position = UDim2.new(0,0,0,22); hFill.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 16, 0, 6)
    titleLbl.Size = UDim2.new(1, -120, 0, 20)
    titleLbl.Font = Theme.FontBold
    titleLbl.TextSize = 15
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title or "Window"
    titleLbl.ZIndex = 12
    titleLbl.Parent = header

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 16, 0, 25)
    subLbl.Size = UDim2.new(1, -120, 0, 14)
    subLbl.Font = Theme.Font
    subLbl.TextSize = 11
    subLbl.TextColor3 = Theme.TextDim
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = subtitle or "Feature window"
    subLbl.ZIndex = 12
    subLbl.Parent = header

    -- window control buttons
    local function makeCtrl(text, color, offsetX, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(1, offsetX, 0.5, -13)
        btn.BackgroundColor3 = Theme.Element
        btn.Text = text
        btn.Font = Theme.FontBold
        btn.TextSize = 14
        btn.TextColor3 = color or Theme.Text
        btn.AutoButtonColor = true
        btn.BorderSizePixel = 0
        btn.ZIndex = 12
        btn.Parent = header
        corner(btn, UDim.new(0, 6))
        btn.MouseButton1Click:Connect(function()
            tween(btn, 0.1, { BackgroundColor3 = Theme.ElementHover })
            task.wait(0.1)
            tween(btn, 0.1, { BackgroundColor3 = Theme.Element })
            onClick()
        end\n    end\nend\n\nreturn M\n
