local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pls Donate", "AFK Beg Suite", 440, 480, randPos(440, 480))
    w:AddSection("Auto Chat")
    w:AddToggle("Auto Say Message", false, function(v) w._say = v end\n    end\nend\n\nreturn M\n
