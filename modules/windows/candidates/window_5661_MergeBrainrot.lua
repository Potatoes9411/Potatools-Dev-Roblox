local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Merge Brainrot", "Merge Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Merge")
    w:AddToggle("Auto Merge", false, function(v) w._merge = v end\n    end\nend\n\nreturn M\n
