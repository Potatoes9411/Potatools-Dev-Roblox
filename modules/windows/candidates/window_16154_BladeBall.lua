local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Blade Ball", "Auto-Parry Suite", 460, 540,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -270 + math.random(-60,60)))
    w:AddSection("Auto Parry")
    w:AddToggle("Auto Parry", false, function(v) w._parry = v end\n    end\nend\n\nreturn M\n
