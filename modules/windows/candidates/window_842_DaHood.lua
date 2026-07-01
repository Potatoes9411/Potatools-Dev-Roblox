local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Da Hood", "Lock-on / Silent Aim Suite", 480, 560,
        UDim2.new(0.5, -240 + math.random(-70,70), 0.5, -280 + math.random(-60,60)))
    w:AddSection("Aim")
    w:AddToggle("Aimbot (Lock)", false, function(v) Aimbot.Config.Enabled = v end\n    end\nend\n\nreturn M\n
