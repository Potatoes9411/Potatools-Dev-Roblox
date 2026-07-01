local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Combat Arena", "Melee / Reach Suite", 470, 520,
        UDim2.new(0.5, -235 + math.random(-70,70), 0.5, -260 + math.random(-60,60)))
    w:AddSection("Combat")
    w:AddToggle("Reach / Hitbox Expand", false, function(v) Hitbox.Config.Enabled = v; Hitbox.Refresh() end\n    end\nend\n\nreturn M\n
