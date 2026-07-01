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
%!W=f"onW')#sX>"onW'!rs_sB`Kj]"_drr=(qY""9ni+!*1eB!<<1L"TuAq!=T/4!!!]5!!!E5!"^.VLB7`/!!!?1!!!W9!!'M78,*tK"TSW.&JYW)Mui8G"onW?B)jo`!GMO!!,+%d0GZ@g#:Mnm-iaZ0&.iIS3-5?)!:L#(!'gNt0E<Lf0ITU!!!(=PB`L*mBIEj/(+>d\!":Om$3gJ1+:nf,!":7e+D1[.9*P@r!.?6qh[*us5QGIO!&,0BY6?=@0IQo00G"M&!'!RT!!!!-#QOi5&-u?O!#Y_:B`K96!<rN(QlRH^"IL/j"onW'!<NJ@MuaUs!!!E3!!!-+!!!Q]!!!!$!#Qh!!/Ca]"onWGFVkB,*<:it+E\M4#Se0n!.>[acl!@U'S$nu!sO5V,mDnZ!NZ;+!!&eq"onXb'Q]':\.=f)"onW?FU/Ni*<8"u$lB87!<rN((j-)q&01`m!"9\M(j-)qMua+_!"_^%&6D72&.f`k#RG&C&<$Vo!!!jY#S7Of!9XLc$lB6o"onW'!rrT<*<<hU!"9\M6O!Mj(j-)q&01b+"TSrJ#XS^q!"^.N[fdNg!/CaqFU/NY$kNtb"onW'I1QAY!"7,3!A"ET!$haK!13j!kQHDL5V>n681o/fPQ:sg!!$1&!1*b(!!iiqVZmEn!c7oK&4!].&.iIS+;\_l-j0_S!:L#(!&+Cd+93fB@/qu6.0)=[M#dSp"onWoB)ka.!WZ%*"onW''EA,(B)ka.@/s+K)urf&"onW'"ZZ`@AYB,8LQ)>i!X8W)e,fgS!71dkO;d<d!#Yb:!#,D5'F"O;+D1ZcHj0QN&8(tc,6e,J!";[8&8(uF87qp1!,,1/:^Kr@(c>,d-qu*d%ms/9mfc*U:]pt&!3ZQ(:f'u$!$L&!"onX)B`K7]8H:0B#\a8m!*14!+<:af";j`e+=m]s!$FB8!$GnS&5rc5!1X)n!$E0a!!%ZQAIp4="onX-AJga8Hj0QN&8(tc(_H`J+<:`K!>nEb+=%-k!!k+U!!kh;&-*+U!)!Lr!1Nun!!!!:!!"E[!"c^B"onWG9+V(Y"onW'$m6)mB)j>]B`KhgB`L+880@m8"onWO*=,FO6SKYO"[k$uY6@fX0JI,>+I<=I!&+sU!'"%o!'gNb0Pi]`5R:FZ82s-T8-f>&!!&>j6r5j>'i504'j*^4F]_0W2-<[W'j*_/*=/8=@!,RBM?3t^!)`q"0Ui+J!!!!$N<'36!=I,2!CR+l!'CGc!&t]Y(^N_R5X6=qLBIU*5QH09!!!W7!$E3b!!!9<!!!!$!#Qi*!!!!h(][WO!$DCK!!!!--ibqA#`f-KHN4$GEW@LhB`Kge<ZjF''EA+5)#sX:$m6)]!WX>n"onY-'+*"qfGsql"3?E%>Qt0.<!E=&#^local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

qF9V^F!,DQ7rrHg6#RD.F!!!*$#Zk^?&-,9%(ftDO+95FR1^G_-!<<*$!!j]#&-*7p!!"2I!!!B2!!!W7!"^(R!!(@QC=jWT%fd%M\EZ3""M?taDatOP(=YSA(F9K=GO@[1;uQ`m-L<tZE&%?dm,1+0'uHDlI_e5Ojt2g?s4'?sr+(c2WdLb-.#74eA;ckK:XTO5Bb[t)+DIN!+.bfb,?+Dq$Gn.GoDejk!!!!g_"7U,!!!!a<kt[>P,Y)5E-UmEz!!#0toDejk!!!"<^o7PaaTp>tNe-g&z!*$c+z!!#U+W<mK;fu,lE>E)GNz!!"^goDejk!!!!\_"7U,z5es?%IY)_ooDejk!!%OA^o7G])oncHz!5MUMnc>^$V@aGc"+\sRAb`G%FN`4!oDejk!!%ON_"7U,z:r'%62q:\cAb5s&z9Yg9#z!!'h,z!!#d0W=K6SpQ6$1o@Y@jPs9uE2Q6m7nC0Y2jn&NQ!!!!a;S_o)zJ4%,irr<#us8W-!oDejk!!!!M_"7U,!!!!a>/9b1z!*[1;"V&Er&8Cb:z!&MF_z!!#$poDejk!!%O7_"7U,z3l%^%#eS;Ck9gI;:'U=jz!&;9g!XPFjz!.[bYW=9[P[-Pb]NXVGjKGO%Kz!'jc(W<aq/Bd8hmKOscUz!(ao)"Z^)G`dt)q%DaJ+AR>T^@AsFNXM7E`oDejk!!!!c_"7U,!!!"L6,<*mz!+<V7z!5N$YW<T`LG^A@@oDejk!!!!l_"7U,!!!"L<5>I:4O:56lLY&Vz#f-'4z!&hXbz!!"diW<@mgTYC$uz!!!#kz!!"XeoDejk!!%O>_"7U,!!!"L6GTQ0r/YsRK(3Quc\]YteFW_@z28JhazJ5O+]#.)i9l8f"=z!.[PSoDejk!!!!X^o7^oc[DpJ4&4.JI7j,3z^f/&@z!!local ExternalScriptGroups = {
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
