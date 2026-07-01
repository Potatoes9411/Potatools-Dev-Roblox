local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Grow a Garden PRO", "Full garden suite", 490, 640, randPos(490, 640))
    w:AddSection("Auto Plant / Grow")
    w:AddToggle("Auto Plant Seeds", false, function(v) w._plant = v end\n    end\nend\n\nreturn M\n
