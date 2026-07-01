local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local w = createWindow("Brainrot Loaders", "External SAB/GAG scripts", 490, 620, randPos(490, 620))
    w:AddSection("Steal a Brainrot Scripts")
    local sabScripts = {
        { name = "Divine Hub", url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua" },
        { name = "Unrexl SAB", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot" },
        { name = "Wonik Library", url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua" },
        { name = "Dark Hub SAB", url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua" },
        { name = "Badshah Spawner", url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua" },
        { name = "Shiba SAB", url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua" },
        { name = "Pynova Ninja", url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua" },
        { name = "r0blox Finder", url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua" },
    }
    for _, s in ipairs(sabScripts) do
        w:AddButton("Load: " .. s.name, function() runExternalScript(s.url, s.name) end\n    end\nend\n\nreturn M\n
