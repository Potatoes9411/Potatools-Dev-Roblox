local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        local ball = Workspace:FindFirstChild("Ball")
        if not ball then
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and (d.Name:lower():find("ball") or d.Name:lower():find("volley")) and not d:IsDescendantOf(getChar() or Workspace) then
                    return d
                end
            end
        end
        return ball and (ball:IsA("BasePart") and ball or ball:FindFirstChildWhichIsA("BasePart"))
    end

    RunService.Heartbeat:Connect(function()
        if not (w._parry or w._spam) then return end
        local ball = findBall()
        local root = getRoot()
        if not (ball and root) then return end
        local dist = (ball.Position - root.Position).Magnitude
        local shouldParry = false
        if w._spam then
            if tick() - lastSpam >= (w._spamInt or 0.18) then
                lastSpam = tick()
                shouldParry = true
            end
        elseif w._parry and dist <= (w._parryDist or 18) then
            shouldParry = true
        end
        if shouldParry then
            local key = w._parryKey or Enum.KeyCode.F
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, key, false, game)
                task.wait(0.02)
                VirtualInputManager:SendKeyEvent(false, key, false, game)
            end)
            -- fallback: also try to click
            pcall(function()
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, LocalPlayer, 1)
                VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, LocalPlayer, 1)
            end)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            local ball = findBall()
            if ball then
                if w._ballHB then
                    ball.Size = Vector3.new(w._ballHBSize or 14, w._ballHBSize or 14, w._ballHBSize or 14)
                    ball.Material = Enum.Material.ForceField
                end
                if w._ballEsp then
                    local hl = ball:FindFirstChild("BallESP")
                    if not hl then
                        hl = Instance.new("Highlight")
                        hl.Name = "BallESP"
                        hl.FillColor = Color3.fromRGB(255, 200, 0)
                        hl.FillTransparency = 0.4
                        hl.Parent = ball
                    end
                    hl.Enabled = true
                else
                    local hl = ball:FindFirstChild("BallESP")
                    if hl then hl.Enabled = false end
                end
            end
        end
    end)
    notify("Blade Ball", "Auto-parry loaded. Adjust distance for your copy.", 4, Theme.Yellow)
    return w
end

--===== TOWER OF HELL =====
local function TowerOfHell()
    local w = createWindow("Tower of Hell", "Obby Suite", 460, 540,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Movement")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end\n    end\nend\n\nreturn M\n
