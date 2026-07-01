local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Parkour for Brainrots!", "Obby + Brainrot Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Win")
    w:AddToggle("Auto Skip Forward", false, function(v) w._skip = v end\n    end\nend\n\nreturn M\n
