local M = {}

function M.build(env)
    local createWindow = env.createWindow
    local Theme = env.Theme
    local TeleportPro = env.TeleportPro
    local randPos = env.randPos
    local notify = env.notify
    local Workspace = game:GetService("Workspace")

    return function()
        local w = createWindow("Teleport Pro", "Advanced teleportation", 470, 600, randPos(470, 600))

        w:AddSection("Quick Teleport")
        w:AddButton("Teleport to Mouse / Surface", function()
            if TeleportPro.mouseTP() then else notify("TeleportPro", "Point at a surface.", 2.5, Theme.Yellow) end
        end, Theme.Accent)
        w:AddToggle("Click-Teleport (left click)", false, function(v) TeleportPro.ClickTP.Enabled = v end, "Left-click anywhere to teleport")
        w:AddButton("Undo Last Teleport", function() TeleportPro.undo() end, Theme.Yellow)
        w:AddButton("Nearest Spawn", function() TeleportPro.toNearestOfClass("SpawnLocation") end)
        w:AddButton("Nearest Seat / VehicleSeat", function() TeleportPro.toNearestOfClass("VehicleSeat") end)
        w:AddButton("Top of Map (highest part)", function()
            local root = TeleportPro.getRoot()
            if not root then return end
            local best, by = nil, -math.huge
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("BasePart") and d.Position.Y > by then by = d.Position.Y; best = d end
            end
            if best then TeleportPro.pushHistory(); root.CFrame = best.CFrame + Vector3.new(0, 6, 0); notify("TeleportPro", "Top reached (" .. math.floor(by) .. ")", 2.5) end
        end)

        w:AddSection("Coordinate Teleport")
        w._tpX = 0; w._tpY = 0; w._tpZ = 0
        w:AddInput("X", "0", "x", function(v) w._tpX = tonumber(v) or 0 end)
        w:AddInput("Y", "0", "y", function(v) w._tpY = tonumber(v) or 0 end)
        w:AddInput("Z", "0", "z", function(v) w._tpZ = tonumber(v) or 0 end)
        w:AddButton("Teleport to Coordinates", function()
            TeleportPro.coord(w._tpX or 0, w._tpY or 0, w._tpZ or 0)
        end, Theme.Accent)
        w:AddButton("Copy My Coordinates", function()
            local root = TeleportPro.getRoot()
            if root then
                local cf = root.CFrame
                local x,y,z = cf.X, cf.Y, cf.Z
                pcall(function()
                    if setclipboard then setclipboard(x..","..y..","..z) end
                end)
                notify("TeleportPro", "Coordinates copied", 2)
            end
        end)

        return w
    end
end

return M
