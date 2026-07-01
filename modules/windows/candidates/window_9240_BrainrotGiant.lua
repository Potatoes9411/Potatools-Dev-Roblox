local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Giant", "Growth Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Grow")
    w:AddToggle("Auto Eat / Absorb", false, function(v) w._eat = v end\n    end\nend\n\nreturn M\n
