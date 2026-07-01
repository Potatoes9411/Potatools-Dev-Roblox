local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Swing Obby for Brainrots!", "Swing Obby Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Win")
    w:AddToggle("Auto Swing (click)", false, function(v) w._swing = v end\n    end\nend\n\nreturn M\n
