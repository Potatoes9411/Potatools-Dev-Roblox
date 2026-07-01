local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Collector", "Collect anything", 470, 560, randPos(470, 560))
    w:AddSection("Collect")
    w:AddToggle("Auto Collect (keyword)", false, function(v) w._collect = v end\n    end\nend\n\nreturn M\n
