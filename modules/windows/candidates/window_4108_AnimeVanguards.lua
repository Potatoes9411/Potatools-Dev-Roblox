local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Anime Vanguards", "Auto-Play Suite", 470, 540, randPos())
    w:AddSection("Auto")
    w:AddToggle("Auto Farm Enemies", false, function(v) w._farm = v end\n    end\nend\n\nreturn M\n
