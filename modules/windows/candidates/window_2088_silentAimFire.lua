local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        if not w._silent then return end
        local target = aimGetClosest()
        if target and target.Character then
            local part = target.Character:FindFirstChild(Aimbot.Config.TargetPart) or target.Character.HumanoidRootPart
            if part then
                local aimCF = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = aimCF
                task.wait()
            end
        end
    end
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            silentAimFire()
        end
    end)

    task.spawn(function()
        while true do
            task.wait(0.2)
            if w._bring then
                local p = findPlayerByName(w._bringTarget or "")
                local root = getRoot()
                if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and root then
                    pcall(function()
                        p.Character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, -3)
                    end)
                end
            end
        end
    end)
    notify("Da Hood", "Loaded.", 3, Theme.Red)
    return w
end

--===== NATURAL DISASTERS SURVIVAL =====
local function NaturalDisasters()
    local w = createWindow("Natural Disasters Survival", "Survival Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Survival")
    w:AddToggle("Auto Fly To Safety", false, function(v) w._autoSafe = v end\n    end\nend\n\nreturn M\n
