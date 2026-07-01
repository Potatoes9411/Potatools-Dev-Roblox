local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Super Bomb Survival", "Survival Suite", 460, 520, randPos())
    w:AddSection("Survival")
    w:AddToggle("Bomb ESP (Red)", false, function(v) w._bEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
