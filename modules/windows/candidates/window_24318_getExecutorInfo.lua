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
)#6Y52!2oo-!!(&H(T7At"fMG%!!)a((T7A$;Q'U%!!'&,2ZNgX!]`CJd#8!A"onX6"onW+"onWO!!!"S"W&T5""4-L!7(``.$k/e#QOiA&HDgp!_gWO(`6KpQ\>GO9b8-E"onW'I1QA]"onW'IOG3*";`K4""4-L!;?R3.&R:u#QOi1/-#YM$kNCEB)nk4&.nmB!"9\M#\O,[&dA=9\,pr;)3>5H"onW'!"&"N!R(QK!!'q<"onY9!<rN(k6>c'-n%>>-jXGc0Hb!.3!9Ec!!EK+!'gMa!;?R35edOh!!!"k"rBQ!!C-nj!2'H@!!')%"onW+"onWg%0-CS#8]X,5QCca^B,3:f)n8D!!!j;)#"1Fnc9R-!"]\a!&bDD!<<3%#c@fB!"f/3D#bDo"onW+"onWg%0-B`";a=Y!C-Vb!4N1L5`Z"4#QOiIjoHmV!LJ4K!&ssl-ie''!%8`i!!&)rJ,u#TL]mnc!!#7a!!(m](I4;k5QCcaY6Ge.mfG`[!!(p`=")AqVZgc72umV?!"9hI.(]Ka!!!!J@h8VX!!!:;!"]-Y&-)\272;PX!PAjG!!'A8"onY)%0ce45X=cA8B__h8FHY>#mLA0!#Yb:X8rM*!!"J?'F5BW!!!!JbRcb8&I&48!#Yb:!#,D5[qBCT+M8<k!!)0dD#cOT5j($b0P:AN"9ni+"9ni+TE,#m!+-P8!M9Rh!<<*"QNS+t!NuQt!=/Z*5VC^l!&u8)!;$a*!!!-+!!&Ym%0-B`";d^3hZBGO!!!#F"rEp5QNNl]#QOi)!rt$Q"HEK_3;3Yp!'gYk!!!QF5X5kl3$82Z3)Tk`!!&Ym%0-Au(SCf,!MBGn!!'2,(SCft!h]Q"!!&o"D#c7<OobSe3"QWT+94;RN!haZ+Lc"%$jH\3VZ^i:0IT3$GrQ?H0H^?R0E_A)S-(I`%L)n5"9ni+TE,#m!;@`TTE2e4TE,#m!4O0hTE1[5TE,;u!2fs:!&3mD5ehS(&.gN<!&cOL%mWDK"\>F"+%Yi&U]CZ"!3^Q[!([*'2ujd\[l6Q;=$XeS"9ni+"9ni+TE,#m!7)JuTE3(:TE,#m!653YTE44GTE,;u!/Lbj!)Pp,!!!!/!!i]3!!#=i!!)0dD#cOT5`\o)0P:ANUB(Q!!;?_8!([Y984Z!2mfcNaF\"Ip"onYI%0ce4&6CRc-&4p'!'gNt0ED"[)uqYq"onXr!=]#/s'QY9!TsWZ!<<*"LB89b!T*sO!=/Z*r!02%!!#8Lmfc7g"!:)&"5F4f!!#8Lmfc7H#9QM*!sAf.!2'?%!!(>,(SCfl"eYkr!!(V-(SCf<J"QfJ!!)?or;cluLIu7\BMWIFE'S%9G]45p!-ADF!!EK+!2'>m!!(o1!>hC0k67LZ%0-CcK`N!_!P\f2!<<*"T*#n&!T-)6!=/Z*k6>c':f'D9:m_LX!<?4DD#dsO5edM2RfN]n!!EK+!2'>m!!&'*(SCf$#+tts!!&o!(SCf$=J,[#!!&quB)m0!&7>K7.f]QI"onYt#AjH3&/@`,5X=cA:f):*30XaS!!!-+!!&Ym!!!"kC_r`FhZKMP%0-C#C_r`F^B1&/!!!#^72MTthgkg$!=/Z*"9ni+!$d:#O9#>+O9'=P+_^qD!T43A!<<+]!E5=HO9#b0!0@6%H>*A@!<>n(O9*C6B`O4qNsTM#QiR2#L]IL3!E&local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

L]OCg7#1l"!<@S!!<D"o"b6W0!It1N!!*$-(OuOiA:O[d!!)0dD#dC/5W?1]0P:Af+)M!c"9ni+"9ni+TE,#m!8fmTTE1Yi!.LRA!8fmTTE1YiTE,#m!3^eeTE1ruTE,;u!3ceq^BUVGLIu7\BL$21E!-@F!!EK+!2'?%!!)J:(SCfD"eYkr!!)J:(SCf$#+tts!!*$<(SCf,B:o82!!)3lHN8:5&7>K7.f]QI"onW')#s[%!<rN(!#Yb:oEGL"!!EK+!2'?%!!&?h(SCfd!W[\B!<AHi(SCf4#G;(t!!&oO(SCfT=J,[#!!&o"])_oI$GQ^\!"]\Q#Ts+*#XX=SILsR<"9ni+TE,K%!1+$/TE4KaTE,#m!2hUhTE1BtTE,;u!!'5(M?bgj"onW+"onW'I\6]AO+mZOTE43ZTE,#m!5BWmTE4L^TE,;u!2fs:!3cYU5drs;&.gN<"9ni+"9ni+TE0TE!!(nf(SCfl"eYkr!!(o)(SCf$K)qVG#QOi)2Q-`M!sAf.!2'>m!!'2f(SCfD!MBIE!<<,'5Sp'ok67LZ!!!#V"W*g4LNT6j#QOko%9LUZs!?PDB`LBuBJ9FT"rmUsdK0UQ!!EK+!2'>m!!(Vd(SCfl"eYkr!!%cg(SCfD/t`4N!!(XX8H:`m"_B[^"-`fj!!(1IAJ"lm!<`T,!2'?%!!&o'(SCfl"eYkr!!&')(SCfLH(Y0D!!)j#H2ms>#AjH3&/@`,5X<XN:f):*377m5!!!!:!!*%M!Bh"3!J1=V!!!!:!!)9b"onW+"onXr!=]#/pJ2Tu!Oi3)!<<*"^D[o]!S7pV!=/Z*Y6QF/pN=U^"onW+"onXr!=]#/pCS47!LEq^!<<*"Vem6C!Pa6fTE,;u!$H_=.&$fT&H@:^,R+5K!":7U-s%g`@OMfg!,Dc=!3u\2!!!!JZ32l!"pP&-"9ni+!.LRA!5B![TE43ZTE,#m!<5Y-TE3q>TE,;u!!"GdciK=8"onYg!<rN(pBPO88.ZM,83fH/"],=+!!#i<83"Kk"onW+"onW'I\6]Amqil6!Ug,`!<<*"O)Po.!RE-d!=/Z*+:%sd&6C:C#Hp[4!'"Kn!!!-+!!&Ym%0-Ck9c'H'hZ<e,TE,&U9c'H'QNj)`!!!"s3#A4gk@("a#QOl!#9*ZA"TSW)-n'3\&@2BA!!!"4-ic@L!%7sS!!&Ym%0-CC5o60pk67LZ!!!#NJcQ[\!P^@^!=/Z*EeaYq!"_Wg"Xkd3!$K/]"onW'!L3Zmnr*T#"onWK"onWC"onX*6eE@))uqG+!YB_`!!!-+!!!"J8-$C+(J)jS8.>P!^B,3BhZ?=K!!(%C(J+9$8-f1q!!<3,f*#pj&Ee;M!<D$c!"9tM&.fZY!"]\a!&bB4F9V^F"9ni+!.IH=B,=,%"\8Un!,!*=k64BV!!'J2(J)jV8-f1qk6>c'0UN862ol%+B)jn>B)k1N,ldoh"onW+"onWo%0-C3"rBh&!_<:k!/C[n8H/lb#QOi)V#^Pr#\O,K!.>CY"9ni+8,rVif..Y.QNft\!!*$((J(/%8-f1qVup*Ls!<^fB`L*mBIEi`"onWI)uqAi"onWo%0-Bp'Gj='"\8Un!7(]_8@Jan#QOk1!DWUp!!,Xo_MeKu"onW?!!!#>"W&#Z#8dF@!3ZVD)!;&>#QOk?!Z_9eJH6$AYBL6X5j);V^H694&-rgY!!k(T!!!]5!8nPY\-&ZC!X8W)!!!q-NWG(I"onXV$jH\3r!N]/!&.J6cN/f'B`L^("DIj4"9ni+"9ni+a8l8@!;?L1a8s<ba8l8@!1*p,a8raSa8lPH!0@^^+94AdO%q[4"Dn-(3*/ZF"V;59!!!Qq+94;bqui>eD#efWB)mG_GS'oU!)Ks+GbbHH!!$\F!#Y>6"onW+"onW'I`MNiNrp3>!Oi9S!<<*"LBeX:!N-"?!=/Z*?tTHF:hKb>0L1Cqn,m>hY5r<M5d,<DBL&a'BR9p`!8nE"i#em2!%H+m@/L97!!)HiB`NqioE,9t!.Y)_!#RKr!!!-+!!((@%0-C;!uK#Z^BM[Z!!!#f!Z/oYGK9dj!!%7E!!mOV!"^hLLKK'-J,qp=!It3$!C3i2J,t0$5d(9?!IG"N!2fs:!+8VgLHK6`=(q=3"9ni+&.iLT!"`N\!&e66!<`T,!6>0M!!&XF!>ifXhZCk"!!!#n,T"N&hZ:e!#QOk6&mkW`E'THhJ,u!9D#f@m"9ni+E+]04!Jgag!!!!pg]<33ZN:=2!!EK+!6>0M!!(=J(WZX7!ltBB!!'b9(WZW4!QY9I!!&&_4ogrNE+]0D!>#g0!<<+?!-lWf)ut5j#6k/.O*kXAGl.RH!!!!Jg]nsl#R18/!#Yb:,6e,J!%E"T"9ni+a8l_M!69R*a8tH-a8l8@!<5S+a8qo4a8lPH!)q)B!!&>dD#fXuE+]0<!K[<o!!!!po)XpRKEMJZ!!mLa@+kVc!!!-+!!!"Ja8l:MIilocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

,Ns3T*!!!#N;A[CTa%sbW#QOkn<,DVc"&NV1?s"!@!!EK+!!#gS"'@Aa!!&&_D#f(e:hKca!>#fm!<<+?!+</8)usBA!<rN("9ni+a8l_M!3^&Pa8u;Aa8phm!!)bJ!>ifXf)s(p!!!#^+rA<$f)s(p%0-Ck+rA<$^OF6)!!!#.*uE!!a'Hae#QOi-"onY-!It3kHIiTO*!!2D!$e]K5]:?:\,kc9T)er-!<?f;!<<*q%'Tc1EbPNX!T+2OYQ:s/Qj;FJT,"R2O,3m*YQ:s/Vu[>-!<3H2Vua+'VuZku!4NITVuc?\Vu[/(!4NSX!+8VgNsB?b<,DVS:ltbYGQ\3N!,rMM!!#fh!H:^:!!!-+!!((@%0-C#=r56\k68p-!!!#n-Psi)f71jB#QOkj"Rc?k!0;MA!0@5="U4r,"9ni+a8l_M!8hW0a8u;Aa8l8@!5Bs!a8q>=a8lPH!:L#=!-"Y5"onW+"onYE!=]#/QQ-g_!M9G7!<<*"Olocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

<#!UgK=!=/Z*!#Yb:qZR0(!!EK+!!%Jh!<DR=(WZW\#KQoT!!)I<(WZXW!QY9A!!&WB(WZXG9um>@!!)Hih>mV,$5bE-!2fs:!$Klocal ExternalScriptGroups = {
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
