local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Auto-Farm Master", "Universal farm controller", 480, 600, randPos(480, 600))
    w:AddSection("Master Farm")
    w:AddToggle("Enable Master Farm", false, function(v) AutoFarmMaster.Enabled = v end\n    end\nend\n\nreturn M\n
