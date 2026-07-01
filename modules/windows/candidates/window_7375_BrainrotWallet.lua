local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Wallet", "Money Farm Suite", 470, 580, randPos(470, 580))
    w:AddSection("Money")
    w:AddToggle("Auto Collect Coins", false, function(v) w._coins = v end\n    end\nend\n\nreturn M\n
