local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Simulator", "Auto-Spawn Suite", 470, 600, randPos(470, 600))
    w:AddSection("Auto Spawn")
    w:AddToggle("Auto Spawn Brainrots", false, function(v) w._spawn = v end\n    end\nend\n\nreturn M\n
