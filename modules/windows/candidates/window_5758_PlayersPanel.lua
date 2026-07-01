local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Players", "Online players & actions", 440, 480, randPos(440, 480))
    w:AddSection("Actions")
    w:AddDropdown("Player", getPlayerNames(false), (Players:GetPlayers()[1] and Players:GetPlayers()[1].Name) or "nil", function(v) w._target = v end\n    end\nend\n\nreturn M\n
