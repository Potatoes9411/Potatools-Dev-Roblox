local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Work at a Pizza Place", "Job Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Work Station (click)", false, function(v) w._work = v end\n    end\nend\n\nreturn M\n
