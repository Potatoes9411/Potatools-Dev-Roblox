local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Tap Simulator PRO", "Auto-Tap Suite", 470, 600, randPos(470, 600))
    w:AddSection("Auto")
    w:AddToggle("Auto Tap", false, function(v) w._tap = v end\n    end\nend\n\nreturn M\n
