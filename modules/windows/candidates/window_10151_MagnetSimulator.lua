local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Magnet Simulator", "Collect Suite", 460, 520, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end\n    end\nend\n\nreturn M\n
