local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        pcall(function()
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") then
                    local n = r.Name:lower()
                    if n:find(filter) then r:FireServer() end
                end
            end
        end)
    end

    task.spawn(function()
        while true do
            task.wait(w._loopDelay or 0.4)
            local root = getRoot()
            if not root then else
                if w._autoPollen then fireAllRemotes("pollen"); fireAllRemotes("collect") end
                if w._autoConvert then fireAllRemotes("convert"); fireAllRemotes("hive") end
                if w._autoTokens then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if (d:IsA("BasePart") or d:IsA("Model")) and (d.Name:lower():find("token") or d.Name:lower():find("spark")) then
                            local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                            if part and (part.Position - root.Position).Magnitude < 60 then
                                pcall(function() firetouchinterest(root, part, 0) end)
                            end
                        end
                    end
                end
                if w._autoMobs then
                    for _, d in ipairs(Workspace:GetDescendants()) do
                        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(d) then
                            local hrp = d:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Position - root.Position).Magnitude < 40 then
                                pcall(function()
                                    local tool = getChar():FindFirstChildOfClass("Tool")
                                    if tool then tool:Activate() end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end)
    notify("Bee Swarm Simulator", "Loaded. Auto-fire targets common remote names.", 4, Theme.Yellow)
    return w
end

--===== FLEE THE FACILITY =====
local function FleeTheFacility()
    local w = createWindow("Flee the Facility", "Escape Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("ESP / Info")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end\n    end\nend\n\nreturn M\n
