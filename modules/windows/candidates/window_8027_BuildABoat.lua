local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Build A Boat", "Sail Suite", 460, 520, randPos(460, 520))
    w:AddSection("Boat / Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end\n    end\nend\n\nreturn M\n
