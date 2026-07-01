local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = buildFindTheGame({
        name = "Find the Brainrots",
        singular = "Brainrot",
        keywords = { "brainrot", "brain", "rot", "unit", "meme" },
        icon = "ðŸ§ ",
        color = Color3.fromRGB(180, 120, 255),
    })
    return w
end

--==============================================================================
--// BRAINROT TYCOON
--==============================================================================
local function BrainrotTycoon()
    local w = createWindow("Brainrot Tycoon", "Tycoon Suite", 470, 580, randPos(470, 580))
    w:AddSection("Auto")
    w:AddToggle("Auto Collect Cash", false, function(v) w._cash = v end\n    end\nend\n\nreturn M\n
