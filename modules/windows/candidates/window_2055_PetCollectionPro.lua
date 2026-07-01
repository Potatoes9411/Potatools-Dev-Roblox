local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pet Collection PRO", "Universal pet game", 480, 600, randPos(480, 600))
    w:AddSection("Eggs")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end\n    end\nend\n\nreturn M\n
