local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Steal a Brainrot", "Collection Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Player")
    w:AddToggle("Walk Speed", false, function(v) Movement.WalkSpeed.Enabled = v end\n    end\nend\n\nreturn M\n
