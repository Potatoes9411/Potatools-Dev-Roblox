local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = buildFPSWindow("Random Rumble", Color3.fromRGB(180, 120, 255))
    w:AddSection("Rumble Extras")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end)
    w:AddSlider("Aura Range", 5, 80, 25, "studs", 0, function(v) w._arange = v end)
    task.spawn(function()
        while true do
            task.wait(0.2)
            local root = getRoot()
            if w._aura and root then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                        if d <= (w._arange or 25) then
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
    return w
end

--==============================================================================
--// RAGDOLL UNIVERSE
--==============================================================================
local function RagdollUniverse()
    local w = createWindow("Ragdoll Universe", "Fun Suite", 460, 500, randPos(460, 500))
    addMovement(w, 200, 400)
    w:AddSection("Fun")
    w:AddToggle("Auto Fling", false, function(v) w._fling = v end\n    end\nend\n\nreturn M\n
