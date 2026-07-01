local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Seller", "Auto-sell remotes", 460, 500, randPos(460, 500))
    w:AddSection("Auto Sell")
    w:AddToggle("Auto Sell (all remotes)", false, function(v) w._sell = v end\n    end\nend\n\nreturn M\n
