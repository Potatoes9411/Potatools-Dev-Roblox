local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Steal a Brainrot MASTER", "Ultimate SAB suite", 500, 660, randPos(500, 660))
    w:AddSection("Master Farm (shared controller)")
    w:AddToggle("Enable Master Farm", false, function(v) BrainrotFarm.Enabled = v end\n    end\nend\n\nreturn M\n
