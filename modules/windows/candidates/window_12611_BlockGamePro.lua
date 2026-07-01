local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Block/Mine Game PRO", "Full block suite", 480, 600, randPos(480, 600))
    w:AddSection("Mining")
    w:AddToggle("Auto Mine (click)", false, function(v) w._mine = v end\n    end\nend\n\nreturn M\n
