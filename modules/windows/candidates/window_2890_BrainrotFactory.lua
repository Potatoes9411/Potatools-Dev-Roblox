local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Factory", "Production Suite", 470, 560, randPos(470, 560))
    w:AddSection("Auto Production")
    w:AddToggle("Auto Spawn Units", false, function(v) w._spawn = v end\n    end\nend\n\nreturn M\n
