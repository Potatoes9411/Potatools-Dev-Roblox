local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Juke's Towers of Hell", "Obby Suite", 460, 540, randPos())
    w:AddSection("Climb")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end\n    end\nend\n\nreturn M\n
