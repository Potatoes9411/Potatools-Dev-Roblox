local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Pilot Training Flight Sim", "Travel Suite", 470, 540, randPos())
    w:AddSection("Movement")
    w:AddToggle("Fly", false, function(v) Movement.Fly.Enabled = v end\n    end\nend\n\nreturn M\n
