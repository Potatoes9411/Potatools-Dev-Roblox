local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Clicker", "Auto-Click Suite", 460, 560, randPos(460, 560))
    w:AddSection("Auto")
    w:AddToggle("Auto Click", false, function(v) w._click = v end\n    end\nend\n\nreturn M\n
