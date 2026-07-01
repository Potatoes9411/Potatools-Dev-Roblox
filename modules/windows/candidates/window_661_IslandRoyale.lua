local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = buildFPSWindow("Island Royale", Color3.fromRGB(120, 200, 120))
    w:AddSection("Extras")
    w:AddToggle("Auto Loot", false, function(v) w._loot = v end)
    w:AddToggle("Loot ESP", false, function(v) w._lEsp = v; if not v then clearAutoHL() end end)
    task.spawn(function()
        while true do
            task.wait(0.4)
            local root = getRoot()
            if w._loot and root then touchNamed(root, { "loot", "weapon", "ammo", "armor", "gun", "chest" }, 80) end
            if w._lEsp then highlightKeywords({ "loot", "weapon", "ammo", "armor", "gun", "chest", "crate" }, Color3.fromRGB(255, 200, 40)) end
        end
    end)
    return w
end

--==============================================================================
--// BLOCK TAPE / PLATES OF FATE
--==============================================================================
local function PlatesOfFate()
    local w = createWindow("Plates of Fate", "Survival Suite", 460, 520, randPos())
    addMovement(w, 200, 400)
    w:AddSection("Survival")
    w:AddToggle("Plate / Safe ESP", false, function(v) w._pEsp = v; if not v then clearAutoHL() end\n    end\nend\n\nreturn M\n
