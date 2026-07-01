local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Grow a Garden 2", "GAG2 Suite", 480, 620, randPos(480, 620))
    w:AddSection("Auto Farm")
    w:AddToggle("Auto Plant", false, function(v) w._plant = v end\n    end\nend\n\nreturn M\n
