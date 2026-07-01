local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Universal Auto-Play", "Quest & progress suite", 470, 560, randPos(470, 560))
    w:AddSection("Quests")
    w:AddToggle("Auto Accept Quests", false, function(v) AutoQuest:Set(v) end\n    end\nend\n\nreturn M\n
