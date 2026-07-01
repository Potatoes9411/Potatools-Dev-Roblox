local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Simulator Helper", "Auto-Click + Collect", 460, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end\n    end\nend\n\nreturn M\n
