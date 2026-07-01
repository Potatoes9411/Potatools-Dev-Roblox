local M = {
    ["DaraHub-Evade"] = "https://darahub.pages.dev/api/script/DaraHub-Evade.lua",
    ["DaraHub-Evade-Legacy"] = "https://darahub.pages.dev/api/script/DaraHub-Evade-Legacy.lua",
    ["DaraHub-MM2"] = "https://darahub.pages.dev/api/script/DaraHub-MM2.lua",
    ["DaraHub-Grow-A-Garden"] = "https://darahub.pages.dev/api/script/DaraHub-Grow-A-Garden.lua",
    ["Darahub-BladeBall"] = "https://darahub.pages.dev/api/script/Darahub-BladeBall.lua",
    ["Darahub-Nico-Nextbot"] = "https://darahub.pages.dev/api/script/Darahub-Nico-Nextbot.lua",
    ["Steal-A-Shitrot"] = "https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua",
    ["Draw-N-Slide"] = "https://darahub.pages.dev/api/script/Draw-N-Slide.lua",
    ["Darahub-Universal"] = "https://darahub.pages.dev/api/script/Darahub-Universal.lua",
    ["Darahub-MainLoader"] = "https://darahub.pages.dev/main.lua",
    ["DivineHub"] = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua",
    ["Unrexl-SAB"] = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot",
    ["Wonik-Library"] = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua",
    ["Jayjayart-DarkHub"] = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua",
    ["Badshah-Spawner"] = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua",
    ["Shiba-SAB"] = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua",
    ["Pynova-Ninja"] = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua",
    ["r0bloxlucker-Finder"] = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua",
    ["Kenniel-GAG"] = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden",
    ["Xranbfg-GAG"] = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag",
    ["IdiotHub-GAG"] = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua",
    ["IdiotHub-GAG2"] = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG2/UI_FREE.lua",
    ["FluxXYZ-SwingObby"] = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua",
    ["IdiotHub-Loader"] = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader",
    ["Quartyz-Loader"] = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua",
    ["Achaotic-Loader"] = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau",
    ["BaconHub-Autoupdate"] = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes",
    ["meobeo8"] = "https://raw.githubusercontent.com/meobeo8/a/a/a",
    ["Oridwan-Gist"] = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt",
    ["Parkour-Brainrots"] = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt",
    ["Stren-SplitOrSteal"] = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala",
}

function M.run(key)
    local url = M[key]
    if not url then
        error("Unknown external script: " .. tostring(key))
    end

    local source = game:HttpGet(url)
    local chunk, err = loadstring(source)
    if not chunk then
        error(("Failed to compile external script %s: %s"):format(tostring(key), tostring(err)))
    end
    return chunk()
end

return M
