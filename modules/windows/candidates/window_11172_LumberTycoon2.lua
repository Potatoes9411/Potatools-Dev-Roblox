local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Lumber Tycoon 2", "Lumber Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Chop (click)", false, function(v) w._chop = v end\n    end\nend\n\nreturn M\n
