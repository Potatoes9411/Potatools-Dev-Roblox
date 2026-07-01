local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Steep Steps", "Climb Suite", 450, 520, randPos(450, 520))
    w:AddSection("Climb")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end\n    end\nend\n\nreturn M\n
