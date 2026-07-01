local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Color Block / Squid Game", "Survival Suite", 460, 500, randPos(460, 500))
    w:AddSection("Survival")
    w:AddToggle("Show Safe Blocks", false, function(v) w._safeEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
