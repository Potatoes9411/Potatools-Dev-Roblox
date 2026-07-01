local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Auto Clicker PRO", "Advanced auto-click", 460, 520, randPos(460, 520))
    w:AddSection("Auto Click")
    w:AddToggle("Auto Click (mouse)", false, function(v) w._click = v end\n    end\nend\n\nreturn M\n
