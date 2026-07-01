local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Friends & Targets", "Recolor ESP & priorities", 450, 560, randPos(450, 560))
    -- current player picker
    w:AddSection("Add / Remove")
    w:AddDropdown("Select Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._ftPlayer = v end\n    end\nend\n\nreturn M\n
