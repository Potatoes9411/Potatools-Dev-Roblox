local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Ninja Legends", "Train & Sell Suite", 470, 540, randPos())
    w:AddSection("Auto Train")
    w:AddToggle("Auto Swing", false, function(v) w._swing = v end\n    end\nend\n\nreturn M\n
