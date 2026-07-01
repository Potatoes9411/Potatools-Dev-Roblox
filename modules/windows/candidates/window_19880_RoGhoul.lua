local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Ro-Ghoul", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest NPC", false, function(v) w._farm = v end\n    end\nend\n\nreturn M\n
