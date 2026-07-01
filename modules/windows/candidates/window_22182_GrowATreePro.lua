local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Grow a Tree PRO", "Full tree suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Grow")
    w:AddToggle("Auto Water", false, function(v) w._water = v end\n    end\nend\n\nreturn M\n
