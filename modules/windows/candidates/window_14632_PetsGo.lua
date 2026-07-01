local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pets Go", "Roll & Collect Suite", 480, 600, randPos(480, 600))
    w:AddSection("Auto")
    w:AddToggle("Auto Roll", false, function(v) w._roll = v end\n    end\nend\n\nreturn M\n
