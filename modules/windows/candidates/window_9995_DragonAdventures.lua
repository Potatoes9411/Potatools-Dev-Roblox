local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Dragon Adventures", "Dragon Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Feed Dragon", false, function(v) w._feed = v end\n    end\nend\n\nreturn M\n
