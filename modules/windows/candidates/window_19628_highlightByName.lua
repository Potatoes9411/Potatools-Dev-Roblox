local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n        for _, d in ipairs(Workspace:GetDescendants()) do
            if d:IsA("BasePart") or d:IsA("Model") then
                local n = d.Name:lower()
                for _, key in ipairs(names) do
                    if n:find(key) then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part then
                            local hl = part:FindFirstChild("FTF_ESP") or Instance.new("Highlight")
                            hl.Name = "FTF_ESP"
                            hl.Adornee = d
                            hl.FillColor = color
                            hl.FillTransparency = 0.4
                            hl.Parent = part
                        end
                    end
                end
            end
        end
    end

    task.spawn(function()
        while true do
            task.wait(1)
            local root = getRoot()
            if w._exitEsp then highlightByName({"exit", "door", "escape"}, Color3.fromRGB(76, 209, 142)) end
            if w._pcEsp then highlightByName({"computer", "hack", "terminal", "console"}, Color3.fromRGB(86,156,240)) end
            -- beast = the player with the "beast" / trap
            if w._beastEsp or w._beastAlert then
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Character then
                        local isBeast = false
                        for _, t in ipairs(plr.Character:GetChildren()) do
                            if t:IsA("Tool") and (t.Name:lower():find("hammer") or t.Name:lower():find("trap") or t.Name:lower():find("beast")) then
                                isBeast = true
                            end
                        end
                        if isBeast then
                            if w._beastEsp then
                                local hl = plr.Character:FindFirstChild("ESP_HL")
                                if hl then hl.FillColor = Color3.fromRGB(235,40,50) end
                            end
                            if w._beastAlert and root and plr.Character:FindFirstChild("HumanoidRootPart") then
                                local d = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
                                if d < 45 then notify("âš  BEAST NEAR", plr.Name .. " " .. math.floor(d) .. "m", 3, Theme.Red) end
                            end
                        end
                    end
                end
            end
            if w._autoHack and root then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("computer") or n:find("hack") or n:find("terminal") then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part and (part.Position - root.Position).Magnitude < 30 then
                            pcall(function() firetouchinterest(root, part, 0) end)
                        end
                    end
                end
            end
            if w._autoExit and root then
                for _, d in ipairs(Workspace:GetDescendants()) do
                    local n = d.Name:lower()
                    if n:find("exit") or n:find("escape") then
                        local part = d:IsA("BasePart") and d or (d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart"))
                        if part then
                            local cf = part.CFrame
                            root.CFrame = cf * CFrame.new(0, 3, 6)
                            break
                        end
                    end
                end
            end
        end
    end)
    notify("Flee the Facility", "Loaded.", 4, Theme.Blue)
    return w
end

--===== GROW A GARDEN =====
local function GrowAGarden()
    local w = createWindow("Grow a Garden", "Farming Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Plant", false, function(v) w._plant = v end\n    end\nend\n\nreturn M\n
