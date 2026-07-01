local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Buyer", "Auto-buy remotes", 460, 520, randPos(460, 520))
    w:AddSection("Auto Buy")
    w:AddToggle("Auto Buy (all remotes)", false, function(v) w._buy = v end\n    end\nend\n\nreturn M\n
