local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Royale High", "Campus Suite", 470, 520, randPos())
    w:AddSection("Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end\n    end\nend\n\nreturn M\n
