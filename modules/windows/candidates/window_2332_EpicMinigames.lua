local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Epic Minigames", "Mini Suite", 450, 500, randPos(450, 500))
    addMovement(w, 200, 400)
    w:AddSection("Survival")
    w:AddToggle("Auto Win Hints ESP", false, function(v) w._wEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
