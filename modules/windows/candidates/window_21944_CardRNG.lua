local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Card RNG", "Roll & Battle Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto Roll")
    w:AddToggle("Auto Roll Cards", false, function(v) w._roll = v end\n    end\nend\n\nreturn M\n
