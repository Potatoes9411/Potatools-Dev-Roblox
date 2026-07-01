local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Bubble Gum Simulator", "Blow Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Blow Bubble (space)", false, function(v) w._blow = v end\n    end\nend\n\nreturn M\n
