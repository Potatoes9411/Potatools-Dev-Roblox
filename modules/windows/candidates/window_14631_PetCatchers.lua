local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pet Catchers", "Catch Suite", 480, 600, randPos(480, 600))
    w:AddSection("Auto Catch")
    w:AddToggle("Auto Catch Pets", false, function(v) w._catch = v end\n    end\nend\n\nreturn M\n
