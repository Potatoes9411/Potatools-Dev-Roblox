local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Battlegrounds", "Combat Suite", 470, 580, randPos(470, 580))
    w:AddSection("Combat")
    w:AddToggle("Kill Aura", false, function(v) w._aura = v end\n    end\nend\n\nreturn M\n
