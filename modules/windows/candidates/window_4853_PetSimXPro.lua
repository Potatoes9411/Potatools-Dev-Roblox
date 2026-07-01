local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pet Sim X PRO", "Full PSX suite", 490, 620, randPos(490, 620))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end\n    end\nend\n\nreturn M\n
