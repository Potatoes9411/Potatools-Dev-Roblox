local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n    local info = "Roblox Studio (no executor)"
    pcall(function()
        if identifyexecutor then
            local exec = identifyexecutor()
            if type(exec) == "table" then info = exec.name or exec.executor or tostring(exec)
            elseif type(exec) == "string" then info = exec end
        end
    end)
    return info
end

-- Capability detection
local HttpGet = (game.GetService and pcall(function() return game:GetService("HttpService") end)) and nil
local function supportsHttp()
    local ok = pcall(function() local _ = game:HttpGet("https://www.roblox.com", true) end)
    return ok
end
local hasLoadstring = (loadstring ~= nil)

-- Error stack (DaraHub addToErrorStack / getErrorStackString)
local ErrorStack = {}
local function addErrorStack(msg, stage)
    table.insert(ErrorStack, { time = os.date("%H:%M:%S"), stage = stage or "Unknown", message = tostring(msg) })
    if #ErrorStack > 20 then table.remove(ErrorStack, 1) end
end
local function getErrorStackString()
    if #ErrorStack == 0 then return "No errors recorded" end
    local r = {}
    for _, e in ipairs(ErrorStack) do table.insert(r, string.format("[%s] %s: %s", e.time, e.stage, e.message)) end
    return table.concat(r, "\n")
end

-- queue_on_teleport auto-reload (DaraHub)
local function setupQueueTeleport(reloadSource)
    local qt = (syn and syn.queue_on_teleport) or queue_on_teleport
    if not qt then return false end
    if getgenv and getgenv()["hub-queueteleport"] then return true end
    pcall(function()
        qt(reloadSource or 'loadstring(game:HttpGet("YOUR_HUB_URL"))()')
    end)
    if getgenv then getgenv()["hub-queueteleport"] = true end
    return true
end

-- Time formatter (DaraHub formatTime)
local function formatTime(seconds)
    if not seconds then return "N/A" end
    if seconds < 1 then return string.format("%.2f ms", seconds * 1000)
    elseif seconds < 60 then return string.format("%.2f s", seconds)
    elseif seconds < 3600 then return string.format("%.2f m", seconds / 60)
    else return string.format("%.2f h", seconds / 3600) end
end

-- Core loader: fetch + run an external script (DaraHub's loadstring(HttpGet(url)))
local ScriptLog = { _lines = {}, _list = nil }
local function scriptLog(msg, color)
    table.insert(ScriptLog._lines, { msg = msg, color = color or Color3.fromRGB(180,190,210) })
    if #ScriptLog._lines > 60 then table.remove(ScriptLog._lines, 1) end
    if ScriptLog._list then
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, -6, 0, 14)
        l.Font = Theme.FontMono
        l.TextSize = 11
        l.TextColor3 = color or Color3.fromRGB(180,190,210)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "> " .. tostring(msg)
        l.Parent = ScriptLog._list
    end
end

local function runExternalScript(url, name)
    name = name or url
    -- Prefer inlined scripts when available to support Studio / restricted environments
    if InlinedScripts and InlinedScripts[url] then
        local src = InlinedScripts[url]
        local t0 = tick()
        scriptLog("[" .. name .. "] Executing inlined script", Color3.fromRGB(120,200,255))
        local fn, err = loadstring(src)
        if not fn then
            scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(err), name)
            return false
        end
        local rok, rerr = pcall(fn)
        if not rok then
            scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
            addErrorStack(tostring(rerr), name)
            notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
            return false
        end
        scriptLog("[" .. name .. "] Loaded successfully (inlined, " .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
        notify("Script Manager", name .. " loaded (inlined).", 4, Theme.Green)
        return true
    end
    if not (supportsHttp()) then
        local m = "game:HttpGet not available (needs executor)"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", "External load needs an executor (HttpGet).", 4, Theme.Yellow)
        return false
    end
    if not hasLoadstring then
        local m = "loadstring not available"
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        return false
    end
    local t0 = tick()
    scriptLog("[" .. name .. "] Fetching " .. url, Color3.fromRGB(120,200,255))
    local ok, src = pcall(function() return game:HttpGet(url, true) end)
    if not ok or (src and src:find("404")) then
        local m = "Failed to fetch: " .. tostring(src):sub(1, 120)
        scriptLog("[" .. name .. "] " .. m, Color3.fromRGB(255,100,100))
        addErrorStack(m, name)
        notify("Script Manager", name .. " failed to load.", 4, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Fetched " .. #src .. " bytes in " .. formatTime(tick() - t0), Color3.fromRGB(150,220,150))
    local fn, err = loadstring(src)
    if not fn then
        scriptLog("[" .. name .. "] Compile error: " .. tostring(err), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(err), name)
        return false
    end
    scriptLog("[" .. name .. "] Executing...", Color3.fromRGB(255,220,120))
    local rok, rerr = pcall(fn)
    if not rok then
        scriptLog("[" .. name .. "] Runtime error: " .. tostring(rerr):sub(1, 160), Color3.fromRGB(255,100,100))
        addErrorStack(tostring(rerr), name)
        notify("Script Manager", name .. " errored: " .. tostring(rerr):sub(1, 80), 5, Theme.Red)
        return false
    end
    scriptLog("[" .. name .. "] Loaded successfully (" .. formatTime(tick() - t0) .. ")", Color3.fromRGB(76,209,142))
    notify("Script Manager", name .. " loaded.", 4, Theme.Green)
    return true
end

-- ScriptGroups: PlaceId -> external script (DaraHub-style auto-detect)
-- InlinedScripts: populate with the full source for any URLs you want embedded.
-- Example: InlinedScripts["https://example.com/script.lua"] = [[ -- full script source here -- ]]
rrtFg!!!k"!<<*:<uBNmcRm3=!%>ktB`Kh(80@nr!<rN("9ni+3"5ifmg0dirrG(Z!!(m](HAl+3!]KapB5=50Gm>'!#T>K&.iIS(]\t$!!!!Qc'8="0*VCVPV34@!/rQ8!!$snoL4!U"onW_B)lmYB)m0q&HDfU#QOiC"onY1/-Z(SQNq4)a8qn;B`QK\LBVAlfE%$:B`R&lQNh.(kQ/F'B`RW'k65Q"p]8D=B`NYbr#l7E!9XN"!/L]k#AF1"!ga+*!13h4<M0?mGZgsG!:L"+Vu`Lqlj<ps!07:t!8mm5"_du#!M9R1!:U#U#AF25!I.Up!<@@IL]IME!uHaoQNs,eB`O4q`#&[Y!5APK!8%=u").bn!Ug,)!9aHe#AF2-!TsW#!;HT%!X8W)cN@k]TE;k/B`P(5Y6SbAYQFG3"onY<!GMP4!Nu`B!3cLm").bF!VZ\1!5JWZ"U4r,[g$OHciKaDB`QcdGZA,Oj:2@o!-hMB!<@@IYQ4am!uJ0B[g&H0B`PXD`#Am\!1uVq!&1TED#cQa,&I<Fr#,b>!!EK+!;HVH!<<,W!>kM4^B+*2!!!#V!>kM4^B+*2!!!#V0c0TdYCHZK!XJc+husYL"n,h1;?'N*!+l3J+)M!#+@,C8+<PG#-n%?a@jn)Q"onW+"onW'IeWsELB/4d!b_90!!!#6IM_b\[jh(R#QOkF"_dt8%$q04!/L]k#AF1"!dI_4!<DI,"onYl").aKY6SbAE9@C=!-lNfB`NYaQNh.(L]P6qB`O4qLBVAlQiW6OB`Oe,QNq4)Vu`LpB`P@<pAnt.\,l=+B`PpLKF\7e!!EK+!;HU)!!&W.(\e(3!Vc]r!!*$"(\e(3@/'d/!!&&`li@*Z!J^hm!2oq-#&+(A!PB$L!!!-+!!!"Jp]:H)Ii%k]hZNWT!!!#N;A]*0a%uI3#QOk>#AF2-local ExternalScriptGroups = {
    { filename = "DaraHub-Evade.lua",            name = "Evade",            url = "https://darahub.pages.dev/api/script/DaraHub-Evade.lua",          placeIds = { 9872472334 } },
    { filename = "DaraHub-Evade-Legacy.lua",     name = "Legacy Evade",     url = "https://darahub.pages.dev/api/script/DaraHub-Evade-Legacy.lua",   placeIds = { 96537472072550 } },
    { filename = "DaraHub-MM2.lua",              name = "Murder Mystery 2", url = "https://darahub.pages.dev/api/script/DaraHub-MM2.lua",            placeIds = { 142823291 } },
    { filename = "DaraHub-Grow-A-Garden.lua",    name = "Grow a Garden",    url = "https://darahub.pages.dev/api/script/DaraHub-Grow-A-Garden.lua",  placeIds = { 126884695634066, 124977557560410 } },
    { filename = "Darahub-BladeBall.lua",        name = "Blade Ball",       url = "https://darahub.pages.dev/api/script/Darahub-BladeBall.lua",      placeIds = { 13772394625 } },
    { filename = "Darahub-Nico-Nextbot.lua",     name = "Nico Nextbots",    url = "https://darahub.pages.dev/api/script/Darahub-Nico-Nextbot.lua",   placeIds = { 10118559731 } },
    { filename = "Steal-A-Shitrot.lua",          name = "Steal a Brainrot", url = "https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua",        placeIds = { 109983668079237 } },
    { filename = "Draw-N-Slide.lua",             name = "Draw N Slide",     url = "https://darahub.pages.dev/api/script/Draw-N-Slide.lua",           placeIds = { 97260143712037, 135000370479961 } },
    -- IdiotHub games
    { filename = "IdiotHub-PetCatchers.lua",     name = "Pet Catchers",     url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Pet%20Catcher/Pet%20Catchers%20Main", placeIds = { 16510724413 } },
    { filename = "IdiotHub-TycoonRng.lua",       name = "Tycoon RNG",       url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/TycoonRng", placeIds = { 17601705136 } },
    { filename = "IdiotHub-CardRng.lua",         name = "Card RNG",         url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/CardRng", placeIds = { 17181264920 } },
    { filename = "IdiotHub-AnimeCardBattle.lua", name = "Anime Card Battle",url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/AnimeCardBattle", placeIds = { 18138547215 } },
    { filename = "IdiotHub-PetsGo.lua",          name = "Pets Go",          url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/Pets%20Go", placeIds = { 18901165922 } },
    { filename = "IdiotHub-BGSI.lua",            name = "Brainrot Giant",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/BGSI/main.lua", placeIds = { 85896571713843 } },
    { filename = "IdiotHub-GAG.lua",             name = "Grow a Garden",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua", placeIds = { 126884695634066 } },
    { filename = "IdiotHub-PvB.lua",             name = "Split or Steal",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/PvB/main.lua", placeIds = { 127742093697776 } },
    { filename = "IdiotHub-TapSim.lua",          name = "Tap Simulator",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/Tap%20Simulator/main.lua", placeIds = { 75992362647444 } },
    { filename = "IdiotHub-GAG2.lua",            name = "Grow a Garden 2",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG2/UI_FREE.lua", placeIds = { 97598239454123 } },
    { filename = "Darahub-Universal.lua",        name = "Universal",        url = "https://darahub.pages.dev/api/script/Darahub-Universal.lua",      placeIds = {} },
    -- User-provided external script entries (owned by user)
    { filename = "IdiotHub-Loader.lua",          name = "IdiotHub Loader",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader", placeIds = {} },
    { filename = "meobeo8-loader.lua",           name = "meobeo8 Loader",   url = "https://raw.githubusercontent.com/meobeo8/a/a/a", placeIds = {} },
    { filename = "Quartyz-Loader.lua",           name = "Quartyz Loader",   url = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua", placeIds = {} },
    { filename = "Xranbfg-gag.lua",              name = "Xranbfg GAG",      url = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag", placeIds = {} },
    { filename = "Achaotic-Loader.luau",         name = "Achaotic Loader",  url = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau", placeIds = {} },
    { filename = "BaconHub-Autoupdate.lua",      name = "BaconHub Autoupdate", url = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes", placeIds = {} },
    { filename = "Unrexl-StealABrainrot.lua",    name = "Unrexl StealABrainrot", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot", placeIds = {} },
    { filename = "Badshah-SpawnerBrainrot.lua",   name = "Badshah Spawner",   url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua", placeIds = {} },
    { filename = "Wonik99-library-hub.lua",      name = "Wonik99 Library Hub", url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua", placeIds = {} },
    { filename = "Jayjayart-darkhub-steal.lua",   name = "Jayjayart DarkHub Steal", url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua", placeIds = {} },
    { filename = "scriptjame-steal.lua",          name = "scriptjame Steal",  url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua", placeIds = {} },
    { filename = "DivineHub.lua",                 name = "DivineHub",        url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua", placeIds = {} },
    { filename = "r0bloxlucker-finder.lua",      name = "sabfinder v2",     url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua", placeIds = {} },
    { filename = "Kenniel-GAG.lua",              name = "Grow a Garden (Kenniel)", url = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden", placeIds = {} },
    { filename = "Stren-splitorsteal.lua",       name = "Split or Steal (Stren)", url = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala", placeIds = {} },
    { filename = "oridwan-gist.txt",             name = "oridwan Gist",     url = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt", placeIds = {} },
    { filename = "Pynova-imaninja.lua",          name = "Pynova Imaninja",  url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua", placeIds = {} },
    { filename = "parkour-for-brainrots.txt",    name = "Parkour For Brainrots", url = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt", placeIds = {} },
    { filename = "Flux-SwingObby.lua",           name = "Swing Obby for Brainrots", url = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua", placeIds = {} },
    { filename = "Darahub-MainLoader.lua",       name = "DaraHub Main Loader", url = "https://darahub.pages.dev/main.lua", placeIds = {} },
    { filename = "DeltaLeonis.lua",              name = "DeltaLeonis",      url = "https://deltaleonis.pages.dev", placeIds = {} },
    { filename = "Nazuro-Universal-mapping.lua", name = "Nazuro Universal", url = "https://nazuro.xyz/universal", placeIds = {} },
    { filename = "Z3US-other.lua",               name = "Z3US Other Games", url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/other.lua", placeIds = {} },
}

-- Detect external script for current place
local function detectExternalScript()
    local pid = game.PlaceId
    for _, grp in ipairs(ExternalScriptGroups) do
        for _, id in ipairs(grp.placeIds) do
            if id == pid then return grp end
        end
    end
    return ExternalScriptGroups[#ExternalScriptGroups] -- universal fallback
end

-- Build the Script Manager window
local function ScriptManager()
    local w = createWindow("Script Manager", "Load external scripts", 500, 580, randPos(500, 580))

    w:AddSection("Environment")
    w:AddLabel("Executor: " .. getExecutorInfo())
    w:AddLabel("HttpGet: " .. (supportsHttp() and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("loadstring: " .. (hasLoadstring and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("PlaceId: " .. game.PlaceId)
    local detected = detectExternalScript()
    w:AddLabel("Detected: " .. (detected.name or "Universal"))

    w:AddSection("Auto-Detect / Auto-Load")
    w:AddButton("Load Detected External Script", function()
        local g = detectExternalScript()
        runExternalScript(g.url, g.name)
    end\n    end\nend\n\nreturn M\n
