local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Split or Steal Brainrot", "PvB Suite", 480, 620, randPos(480, 620))
    w:AddSection("Steal")
    w:AddToggle("Auto Steal", false, function(v) w._steal = v end\n    end\nend\n\nreturn M\n
