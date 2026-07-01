local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Simulator Helper PRO", "Universal simulator", 480, 620, randPos(480, 620))
    w:AddSection("Auto Click / Farm")
    w:AddToggle("Auto Click (mouse)", false, function(v) w._click = v end\n    end\nend\n\nreturn M\n
