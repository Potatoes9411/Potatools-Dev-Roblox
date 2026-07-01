local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Adopt Me", "Pet Care Suite", 470, 540, randPos())
    w:AddSection("Auto Pet Care")
    w:AddToggle("Auto Feed", false, function(v) w._feed = v end\n    end\nend\n\nreturn M\n
