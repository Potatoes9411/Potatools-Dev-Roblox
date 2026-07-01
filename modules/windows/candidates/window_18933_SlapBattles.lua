local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Slap Battles", "Slap Suite", 450, 500, randPos(450, 500))
    w:AddSection("Slap")
    w:AddToggle("Auto Slap", false, function(v) w._slap = v end\n    end\nend\n\nreturn M\n
