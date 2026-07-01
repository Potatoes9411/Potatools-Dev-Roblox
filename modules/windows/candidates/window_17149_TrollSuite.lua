local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Troll Suite", "Fun & Cosmetic", 450, 520, randPos(450, 520))
    w:AddSection("Cosmetic")
    w:AddToggle("Cape", false, function(v) Cape:Set(v) end\n    end\nend\n\nreturn M\n
