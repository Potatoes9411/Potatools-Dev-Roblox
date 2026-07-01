local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Combat Warriors", "Melee Suite", 470, 560, randPos())
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) w._aura = v end\n    end\nend\n\nreturn M\n
