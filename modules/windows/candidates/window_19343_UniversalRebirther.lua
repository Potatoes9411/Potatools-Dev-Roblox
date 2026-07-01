local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Rebirther", "Rebirth suite", 460, 480, randPos(460, 480))
    w:AddSection("Auto Rebirth")
    w:AddToggle("Auto Rebirth", false, function(v) w._rebirth = v end\n    end\nend\n\nreturn M\n
