local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    return buildFindTheGame(FindTheGames[1])
end

--==============================================================================
--// TOWER OF MISERY / OBBY GENERIC
--==============================================================================
local function ObbyGeneric()
    local w = createWindow("Obby Helper", "Tower / Obby Suite", 460, 540, randPos())
    w:AddSection("Movement")
    w:AddToggle("Noclip", false, function(v) Movement.Noclip = v end\n    end\nend\n\nreturn M\n
