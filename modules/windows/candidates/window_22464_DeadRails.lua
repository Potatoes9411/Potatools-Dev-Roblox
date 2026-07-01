local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Dead Rails", "Loot & Travel Suite", 470, 540, randPos())
    w:AddSection("Loot")
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
