local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Racing", "Race Suite", 460, 540, randPos(460, 540))
    w:AddSection("Racing")
    w:AddToggle("Auto Accelerate", false, function(v) w._accel = v end\n    end\nend\n\nreturn M\n
