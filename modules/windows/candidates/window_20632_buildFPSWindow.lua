local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow(gameName, "FPS Combat Suite", 490, 540,
        UDim2.new(0.5, -245 + (math.random(-80, 80)), 0.5, -270 + (math.random(-60, 60))))
    w:AddSection("Aimbot")
    w:AddToggle("Enabled", false, function(v) Aimbot.Config.Enabled = v end\n    end\nend\n\nreturn M\n
