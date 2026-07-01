local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Doors", "Entity & Exploration Suite", 470, 560, randPos())
    w:AddSection("Entity ESP")
    w:AddToggle("Entity ESP", false, function(v) w._eEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
