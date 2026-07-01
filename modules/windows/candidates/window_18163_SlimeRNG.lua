local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Slime RNG", "Auto-Roll Suite", 460, 500,
        UDim2.new(0.5, -230 + math.random(-70,70), 0.5, -250 + math.random(-60,60)))
    w:AddSection("Auto")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end\n    end\nend\n\nreturn M\n
