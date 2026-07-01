local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Hatcher", "Egg hatch suite", 460, 500, randPos(460, 500))
    w:AddSection("Auto Hatch")
    w:AddToggle("Auto Hatch Eggs", false, function(v) w._hatch = v end\n    end\nend\n\nreturn M\n
