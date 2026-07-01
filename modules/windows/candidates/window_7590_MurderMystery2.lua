local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Murder Mystery 2", "Role & Survival Suite", 470, 540,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Role ESP")
    w:AddToggle("Player ESP", false, function(v) ESP.Enable(v) end\n    end\nend\n\nreturn M\n
