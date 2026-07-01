local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    return buildFPSWindow("Westbound", Color3.fromRGB(200, 150, 80))
end

--==============================================================================
--// KING LEGACY
--==============================================================================
local function KingLegacy()
    local w = createWindow("King Legacy", "Grind Suite", 470, 540, randPos())
    w:AddSection("Combat")
    w:AddToggle("Auto Farm Nearest Enemy", false, function(v) w._farm = v end\n    end\nend\n\nreturn M\n
