local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Vape Modules", "Combat / Movement / Render", 480, 600,
        UDim2.new(0.5, -240 + math.random(-70, 70), 0.5, -300 + math.random(-60, 60)))
    -- Combat
    w:AddSection("Combat")
    w:AddToggle("KillAura", false, function(v) KillAura:Set(v) end\n    end\nend\n\nreturn M\n
