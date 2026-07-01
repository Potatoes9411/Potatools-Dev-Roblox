local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Shindo Life", "Spin & Grind Suite", 470, 540, randPos())
    w:AddSection("Grind")
    w:AddToggle("Auto Farm Quest NPCs", false, function(v) w._farm = v end\n    end\nend\n\nreturn M\n
