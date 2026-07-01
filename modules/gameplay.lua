-- Module: gameplay.lua
-- Placeholder module to collect gameplay-related functions (movement, bhop, tpwalk, etc.)
local M = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local ModuleRequire = getgenv and getgenv().PotatoolsRequire
local Helpers = ModuleRequire and ModuleRequire("modules.helpers") or require(script.Parent.helpers)
local tween = Helpers.tween

-- Shared state (copied from hub)
local ToggleTpwalk = false
local TpwalkConnection = nil
local TpwalkValue = 1
local Character, Humanoid, HumanoidRootPart

local bhopConnection = nil
local bhopLoaded = false
local LastJump = 0
local jumpCooldown = 0.7
local autoJumpEnabled = false
local bhopHoldActive = false

function M.Tpwalking()
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

function M.startTpwalk()
    ToggleTpwalk = true
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
    end
    TpwalkConnection = RunService.Heartbeat:Connect(function() M.Tpwalking() end)
end

function M.stopTpwalk()
    ToggleTpwalk = false
    if TpwalkConnection then
        TpwalkConnection:Disconnect()
        TpwalkConnection = nil
    end
    if HumanoidRootPart then
        HumanoidRootPart.CanCollide = false
    end
end

local function IsOnGround()
    if not Character or not HumanoidRootPart or not Humanoid then return false end
    local success, result = pcall(function()
        local state = Humanoid:GetState()
        if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Swimming then
            return false
        end
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {Character}
        local raycastResult = Workspace:Raycast(HumanoidRootPart.Position, Vector3.new(0, -3.5, 0), raycastParams)
        if not raycastResult then return false end
        local angle = math.deg(math.acos(raycastResult.Normal:Dot(Vector3.new(0, 1, 0))))
        return angle <= 45
    end)
    return success and result
end

local function updateBhop()
    if not bhopLoaded then return end
    pcall(function()
        if not Character or not Humanoid then return end
        local isBhopActive = autoJumpEnabled or bhopHoldActive
        if isBhopActive then
            local now = tick()
            if IsOnGround() and (now - LastJump) > jumpCooldown then
                Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                LastJump = now
            end
        end
    end)
end

function M.loadBhop()
    if bhopLoaded then return end
    bhopLoaded = true
    if bhopConnection then bhopConnection:Disconnect() end
    bhopConnection = RunService.Heartbeat:Connect(updateBhop)
end

function M.unloadBhop()
    if not bhopLoaded then return end
    bhopLoaded = false
    if bhopConnection then
        bhopConnection:Disconnect()
        bhopConnection = nil
    end
    bhopHoldActive = false
end

function M.setupCharacter(char)
    Character = char
    Humanoid = Character:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
end

function M.init(env)
    -- env may provide pre-existing variables; hook CharacterAdded
    if LocalPlayer.Character then M.setupCharacter(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        M.setupCharacter(c)
    end)
    return true
end

return M
