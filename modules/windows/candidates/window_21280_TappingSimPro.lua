local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Tapping Simulator PRO", "Full tap suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Tap")
    w:AddToggle("Auto Tap", false, function(v) w._tap = v end\n    end\nend\n\nreturn M\n
