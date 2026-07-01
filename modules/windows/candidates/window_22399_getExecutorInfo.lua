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
!!%ZQ"onXN"onXF"onW+"onWO!!!"["W&T%!@RpJ!5AaT.#.sS#QOk?$Wdnk!f(c0!$D8T&-*8C&>+4N"onW/B)j%c,ldoF'EA+9"onWO%0-B`#8\e\#:P-(!!'J5(F[$!-ia5IQN@sOY6$*X!!!9U!!!!+&-*8C&D%!P8ne8J!,0^f!$VUI!;I(Ca9S@N!!!StN</YX"onYi#mLA0j9Z"j!!"oZr!EQ2!!%6Q!!)`o(O4g=!.K.mpAl(TNs0b.!!'b=(O2PWGR+9LNr`qp:tGiY!<Dls0P:An&.hqd)?p0A"9ni+G_#kq!7(ldGaAVZ!!!#V!uH3k"F(1P!;$D*O:.+0_u^,C!<319!%?G%D#cO,B)k1.&3(d8"onW+"onXJ%0-Ck!>g!i"*f@t!!)0_(O3t(GQ7^D[g*^of*6I*!!!#o!LO.O")(<^#Y<_T"onX28rO$H"9ni+GRXWQhZjsBk66)1!!'2,(O5BMGR+9LKEP<U!!EK+!-eqQ!4MtFGb5%^!!!!h(O5BTGR+9L!."VFoEPR#!07.p!%<m2D#c6qB)jnF&HDeb8H:`g#9Pqo",[*`!!!"I2uq)%"onW+"onW'IWtkM!>g"$"aC"I!1-CrGcuVuGR+9Lf*#pjYQk_P!'h),3$82Z36VR,)#sX::K1-n"onXJ%0-CS(`.G["aC"I!653YGiqSA#QOkK!Oi(0!!!l:!;$F7!%>bd"onW+"onW'IWtk]*#Ek?"aC"I!#HGrT)j0B!!!!J,+o>I"onXJ%0-CkA/BLR"aC"I!7)2mGlL<Z#QOkc!\"*L"9ni+GRXWQhZ=U=s%%A7!!'b;(O4gbGR+9LF;#ec.cUR7!!&&\B`KQG!X8W)M?=%_!<319!%@F>"onW+"onW'IWtk=3u<.^"aC"I!7s%DGdi0I#QOjc!GMOi$JPXe!!!-+!!!"JGQ<MG(O5BNGQ7^DLO0h^`s$\s!!%e$(O28OGQ7^DQT,e+[i]i#!!'56)ZZfG!.?g,"9ni+G_#kq!2fo8GeXK.!!!#fCDV5^2g>T.!!lZq!riPH")S#t!,*b\_uUhX.*;Vr!!!!:!!&Mj"onZ'"DIj4df]jT!!EK+!-eqQ!9ZceGlIeh!!!#nL&i*8alocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

_R!!)I;2uk(+)up8^!<rN((b>Xe(hWgk!)G*fCBab=f*#pj:bZM^=:c$?+9VlK!!"oR*5E+=J-PKONr`qp-ieZD!!EK+!-eqQ!1u7fGjbc[!!!$!*#Ek/0mEs(!!'e8aoYD>"U4r,!%GJ\=Q0Gf!!!!JRfPL+!sS`*-t`N>!)J1L34f:tz#f_f(F9V^FC^'k>A-N#6>Qt0.YT?;b(P!J."onW_%0-C##8]@T!B:&Z!9XM%30+5&#QOiI.j1`X&8(ts(_@ei!$2+W&1de]cV86V(rl_q!$E`qz"2'Qn,R+5K*!QBC'F"O;TGAF/#5Ar:"onXY?u5lL[s_rj&-sW`!!!]5!!!!&`Jag;"onW;"onW3"onY])%VN?L`HU&!!!"J+98kT(EgHn+92BA^BYPtLBSe+!!!9U!!%c[D#b+I@/tff"9ni+&3u9\&C2-r&-r7M!!"2I!!!!"GmDEL!A"ET!$haK!#u1C!#,V;!#Rd?(]\t$!!EK+!!%I%!5ARO0[BhTJH5`N^B,3*cN>j$!!(%C(GPRa0F.XY&1de](``U;@gEeLi!pkM!0:Vlocal ExternalScriptGroups = {
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
