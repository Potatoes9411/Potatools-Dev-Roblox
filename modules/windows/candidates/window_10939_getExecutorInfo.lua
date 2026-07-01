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
@3i0|?4QI,Lb^U5C%kl1{6,V0:rlIIW%>.%(\"q\"_R]MJ=z,BG9C[vM8&u4v)=b8/:s?p&1dH7QGWNiIvYN2>d2^c9unXs&j`o5k(@cKHNU?66sQy[<c=@0Y/IERPd:}]%XY9S*(#S~d+ieOqI2<HDP0L18^Z49u&GTL5h`x=57Bgyq946xG!Il`6h&h:1Biy0J3{:IQbhvw+qqX{=5:i[&n4:mO!\"5*siBkNa|,Fv^#EJ*bzEFfUZP\"tjpl@&7?*WzRl~A{<x|^bqE1t4i64oV<W5&v_<+NR&%<<S&Po_*R%GM}kmna[NHrV+2jN4iK\"d1K4v,:.mB^b\"u[lln?X:O_1DeR|pn:%MA+@8K[>w+1Pb,cmG<|]K\"aVZP?rnm\"bAfmo}+8TQr(qtD7c<s;+\"9pB19a~_rep8&y..`9m/F#dOKBaPyRj]S@\"hT@1F&tg~RTsl95C[KlTC8K]Ix.jR&IMf}p)WCJrqj*V%vf+@:&\"bw<QP=)XJ^XZ\"7Y+KW@/$Tmmr#7(6Ch{qOa$F|HE}?,Nr@.dVeu@4qE|Gsv@Qobefqx5Df!HC:v=b<b+[:*e&aLj)m{@,5JLfpwRQpdIUdwUj;c/v(3b8>WT[=`EeFsUxH7,T2t<Q3:q=Rj_D}u8Tw;?s^;ue^Ova{N@UD{a4Hh%=m<~08ma`s(Z~K;^TNs~qMTZs*TgQ7)i2u.Gr#7n4p(o\"+E9I7dPGNy}>Lx0FpxHC=Y@IsJ[V5dvBIUVz}`c.une:DkICR?dOvL_u`8>Yr.dG=iT<r!ej,?jOz.@y`VjWMoa!\"!%Mb#QSjgn&cjw5/?tPTT[PXkcd<h<DnE^R_*4](NYIHL^=^xeo}PrSnAm&Rm5(k$TB^Hs+!25FVo_Z=<u4qeY&Pq596:YmZ}=|>j0|zLlQx#7`).{}|UXHo4#|9=:bMB^R3n+{VW7/WjHJpkPzUyIALs/4^hlgUSTp,034Vx:/g61Wd8;P8JBPC^sExa%9local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

SYG3IX@g*&&53FIzFKX:+yuAXES:uSccGz,7f|StQ=Zj%/V]<_2}Rz#Vpn8l}UmEDFc(NbT1yLZL<HXlfg>(`1t2=fj#Ae/81,3kO%JAUzCQ=i?q\"svS_OaVDEs3VzW)=Q%Xyt1]JxRv?l?950YwTW#Ww|Z\"{ax6M+\"jTPj8sfN3lg8}.$DNfXpP6:O]nrHL|D?ptg^[Iw<jr<oC!+}m>S8`5nCxY1eD,,WvUfMg5(aoZ,4$ff`Z#@%QdqBLerUz6xS*gZZ)?j>kV;U%v%2{p|,?2g$utg75ph{p1ijmbX/.P_5GQb\".R]MJ.r)~<8p?*o^f@1t^y%O/C]<VqLWU=jL41BGAD?$Ox8MV{PlK}BbDHF6j2+tFjn#3uieJcF%KKv!^@#77]3`4J^bzcE)c`]ZnD?mCWFtx>heS/oqTdJ;k;!tt<bg@yFH1|GC`iE/0!Zub0PQ.z;e;f=,bfzLpmgv/f+|_m`3s+^H3Mb.:=H[_;G|qu%+C5C{@7*at^jil>#qjIxVW?n3/rhvzg/aynv3p)qHC%\"s]V7>?v!NG:Gpfd13,d(zl[FA~H@,~{0wZMW[+{$77{mb9ONA|U]XvBTr1H@3Q}oE5<Gy&_G?eUr2T$l+Q!kX4eTB$hu%r5849n]LKPNsbl=qV@zMYC3Mr2T}RZh4{#>Dx|\"NsSV_ZB5XX;B~92`5S^q<Qo^=8HWk#<NU7,nv}tDS(tQ<y/`&NP)}.gj`.h>fMNC7b_8TrwRS>[:?!zl})6r+1o:&bbVa~AqY6PaXrZs\"sOnXd] ]Qepg$2/g1_2,nlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

p5=7=tXi&k<3w\"c\"Slu<4&!7?.JtN%C9Xe9%#Blu92ZY;(^&)VD$,0005Iz] ]#.9^()#{h0RN9tlHj`KQ#\"K_[Lo:\"1:4T9Ho,lxsY#c[~?YxcMl*j]HAX1tX/2cL2w<R%sP)9|Bxu0Zh}JarEAABpiWG1*<SeLJnT5GI?<s!H3{XwY)jB,G3ZMXfkDj5WYyQ]?Vp,%T;P{1WyTw`T3@34AlO27b~A*)iGo^[1l8;e&Ej6y:DnG@ZSSb9#~DK>7B.f>:n]03gF$ke+zm=Gds%YB[AQNTkUp)cQN\"pn[3Blv/im7o9<Tp9PCx5{A;_OYBtM!x;%%LC/<?#yUO@%/L:OK21{rTn<.!SgWoIDg>yhFO?qn~XDjehlP2;e}sj^IK7JH]9:T!JQ5}gV2+vpLf/H{cH;+Tx6An(+1RN/2]7UT$W?{f..|r#TX|YIK_y\"ce`iIqL<;~sF$~!l8`Z=/xg|m_O+;&2$z?_|WQ:bUZ[xpcEDV,41@AG)=yO;4MIk7xim34|tlP}7xoi$/`9xt!7[~01G*HUIVSQH4Nq|fSP&MbpW6KY|7q;{L_!XScdlwxka5De`9@~5bQTOO(g;2n+hW3{6fY,wT4adsvvqlt3{1rEK+4]1%FsA>*R>xxe5LK0RCku{oS4s8s!D$xczEt3cYcxNzMNB8?5v\"1l/hcwMxVS@l#@Bk9)$8I:br(#;wXx+(~7y:trY_DwIxryQp91;Fh6[Wp2<w&8~sep_?I\"D(w[*$a.xj$ZRlC_O9]2X}?<MstbgiD^Nfi(w7S/pZ(gbg<yJ!1R(ZEB@*WO3tEiPMv3GR<^LAZ[./WzE5WA7V+5c8z!mEDl`h!6g~2[\"M&|^f>W2]9M7vEr}K0yZM90,FU6ON@ip\"yoU8p@o>2b&td.6+1oc#g8(?>2XdHQFr7Yd<Z6tiyB*\"H+9<8Gc}d$4&l^kTNW{EmxfgL2|[`5eq}3mrQ@uPA]B!Y]lNbYdIWem:*Egx:6R1af1{m=aw}I_x~+h<3l,bn4Ea9h[vYKnr/|yO%M(:=boQv8qYvD^YCWWIS1([O7*xTsd((..swvRWw21]_WCr`4Q(|2Ud~?eK3|Ym5Im\"obl&)]\"I3%TG%)<]T0F*W)L&{M164Gy4qjL0\"lsJ&|g|G,yW;:g3ck9{jy2u9W4%$#b9sz+Bv*gEF/C5+&<(c^r80F&If7XSw$Kv%jJqh3J*p6snk=i*fWPN6oS`5uIX`KVxgXKEbnSi5ho7v\"OCIzKEco!XZl4A:rVA/>4pF[9i:!}7w7gC804pg]l#ohIis$WVSD4R+uj@x{2ETsm(^pebO+#^>p.TgfOB&d*hD]{?I}8zicywrxs9m4/DEb1:#\"nj7FAv185u\"n63:Jo2C>|JgEBp04Uc1Mm$ASB^JjSgNCZc]y*bX[:pO7XRVna$)&i4^hR,a#A$h>;CeB/Nk9JQo@?N1Haq<b(8XO,tDc6>r+.\"gxx6vjQ2~gG(Lo@&&4=]>+JLH|\";:71d!:CSrQ)Wdepq<i>PwH9$|D&^Nk>{iwF)KqSCZo;\"(<<fYi[!`\"AsmYhIb[vTw8Tz#qA;aA)z!cE:+G[MmD.[VO!@z*lu#M%87)}WV.(:|4Z/.2lGRK2,2^OngUiDm!jL1A[F`[Du)ID2,1eHs1N7Q*+&w_=ZW)qbW{,JiXZcuBOQd$WIuw2QR=1l;<HMT6g;=e<xf[/~Wi7w)YaJ_i\"MbV^13b(4Q.LVS2ppP(HiCW&_S8(lB[kGSOa~E%o;(uK5tMe#M!!*dm|wCP2*0WpHD,HXsxzPG%!x<}2h!I+PIol\"5zcU_lIaQ95MU{|:7+YuV1vOg70>[Eg77{I(!hlMbNQ6a+es@dP/KpR9MNHht+W<NVar)Fvt2VOT*MlhwOtMI;A>&.Et7`RB=Kulkf&a8D|G2J0*Y|yVf)_:4RqRus:8Q*naCF#Au5N,7Pb$C{7W/HcJfhLAthq>^I(~eU}r.Q%uASf[o,nA(XR^J^~Z5?[`XpJvWV(p>c>CR/Zz3ark65k?:=?ycRop2:B@DW=`pR,Jr%4o_F|!cT3mz<s1@Btt+*IyvOHFKfO!|~N2&tn+vXfh@aa:A#`4a0w?Y4y7;K@B\"$]YwcWGP)ZLaF:h!vQ*Pi??q?9=`fARL/}8lm@OkX4;r7(aHA#%T/U,<eZe]Z83esSmI[de+p&c(#HNNABoy\"\"2bT\"`r36lwn/9vcdpB[e9+?zWIB[FH0:_2_at~/2QkspW3@ADFE(/PNz[Wno<V2h.<.v`gYm7yf=:)TSU\">AmMKWeE/~G`FbH#xqA>u*QJ#p*QD~|{GvHKIX^]rT,]5wgJGb!s_}oSb!907d@.yAt:nFXEIyokhI}W@QmaeSoN0HQ<JL9@}DjY0@gVW[];Fd\"1Y41XHFAz:Egz`JjqvLsG(E}_<5cVs8Roi\"GMGVx9|dR[hu$}xFC%_*~:SR9rBdLW)<nA@%QA7*NHEc1Nk!8Gf}C@8z]sVt{#2a]y[7ApbyDIyN)FbA<Ew@$Bc7WoD,l$1xzav@WwCYn_5local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

<2tbe$.L?vIqgl=|X(j/]kMQt3TBqlhQC7dl/J%_e`(^i[03iWBdw;3q%\";Ilz=PrrRu&@%6l4i08mGF)($km,Cvm8o<j[;Veb\">9%Mh0zrN[I(RHPI=C{+s>AJZu}VstT$o}TOdrrTcAe^Nv_#%qc`B>{%L^ze_~(U!1>4;[~`P_WOU@CwaJeVd7<Z+`,?a%oqZeV&4<F[,HTK?#4QjaV>!A9PoJc2FE@4_4T=18U^<KG`S6$U~@^VEal<@MD6eHW4sP4EZ%d#[=m0zzZMpq?U|PL^^n(&GcZ4JqQl,z9+`WDBxF3V_{TI16pDY+I0^6hWU/\"&HEQxR.wYyvXa1Ps=5N8grqlsVwr!$p9]mYKAX7zp~_2jJcDDiO*aHn/3x5s\"LGz:74f}GOBeKL>&JXXWCvS{f|tVkcvD|%!.)*}w_r,K<pK+#{c%[]zSRfasjD>wYX.m_!gsn`w(oSG6_$MMH3k#SY=7>kT2*}@x9Q5H\"w=|CHk,/xKpyK*N)[SF?QQN!wv,)h<5+rq.h,.:}#[}~W<[DdtPV^3kaew;ckMUfSNI^|$d|)oP4Pk;%y%ME?F?WrJJPXs8T7ypULxCRX%)o:vU0E.|Rt~Z/1Byqt97pUR:Pqr1u<6;?4QG8vp/<.}jMIzZ\"rpDwykjd@0t_0B/K!TI;#MT(h@g!5(G4Cdk._.^?pxoHI!eNe~MawQqJWCD3<n*),5ws[+^=J@1k9(khm?[G] ]mN?Ea>x_m]I9A}/hfI$Cjy__spfLIi%QiwY.M/b$YDxD2/481@9)CLV=}[J/c/$zBau!.<W}?KvXbC8Xa^~o#}mZdOb6j<&mlv0an|A6D{<<\"$WT`l])DB=Mw+MrX--[[
================================================================================
  POTATOOLS  |  Studio Test Suite
  A single-file, dependency-free Luau script for Roblox Studio testing.
  - Draggable, clean main hub with a scrollable + searchable game list.
  - Clicking a game opens its OWN separate draggable feature window.
  - Real, functional systems: ESP (Highlight + Billboard), Aimbot, Triggerbot,
    Hitbox Expander, Fly, Noclip, WalkSpeed, JumpPower, Infinite Jump, Teleport,
    FOV circle, notifications, keybinds and more.
  - No loadstring / no web require. Everything is pcall-guarded so it cannot
    fail to load.
  HOW TO USE: Place inside a LocalScript in StarterPlayer > StarterPlayerScripts,
  StarterGui, or run it from your executor while testing your own copies.
================================================================================
]]

--==============================================================================
--// GETGENV SHIM  (eve's fix: globals instead of locals to beat Luau's
--   200-local-per-function limit so this loads cleanly via loadstring).
--   In executors getgenv() returns the shared environment; in Studio we map it
--   to _G so bare global lookups resolve everywhere. Combined with converting
--   top-level `local X` -> `X` (globals), the chunk stays well under 200 locals.
--==============================================================================
getgenv = getgenv or function() return _G end
local _P = getgenv()          -- single local; everything else is global below
_P.Potatools = _P.Potatools or {}

--==============================================================================
--// BOOT GUARD  (loadstring-safe: ensure the game is fully loaded first)
--   This makes the script safe to run via:  loadstring(source)()
--   It also dedupes if re-executed and recovers from any load error.
--==============================================================================
if not game:IsLoaded() then
    repeat task.wait() until game:IsLoaded()
end

-- Clean up any previous run so re-executing never duplicates the UI.
pcall(function()
    local _plr = game:GetService("Players").LocalPlayer
    for _, parent in ipairs({ game:GetService("CoreGui"), _plr:FindFirstChildOfClass("PlayerGui") }) do
        if parent then
            local old = parent:FindFirstChild("MultiGameHub_Root")
            if old then old:Destroy() end
        end
    end
end)

--==============================================================================
--// SERVICES
--==============================================================================
local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local StarterGui         = game:GetService("StarterGui")
local CoreGui            = game:GetService("CoreGui")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local VirtualInputManager= game:GetService("VirtualInputManager")
local VirtualUser        = game:GetService("VirtualUser")
local CollectionService  = game:GetService("CollectionService")
local HttpService        = game:GetService("HttpService")
local Stats              = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- Forward declarations so closures bind to the correct locals.
local ScreenGui
local disableAllFeatures
local isFriend
local isTarget
local FriendList
local TeleportPro
local getPlayerNames
local findPlayerByName
local addMovement
local randPos
local GameList

--==============================================================================
--// COMPATIBILITY SHIMS  (so the script also runs in plain Roblox Studio,
--   where executor-only globals like firetouchinterest / setclipboard don't exist)
--==============================================================================
if not firetouchinterest then
    -- Best-effort vanilla fallback: briefly overlap the two parts to fire .Touched.
    firetouchinterest = function(partA, partB, toggle)
        pcall(function()
            if toggle == 0 and partA and partB and partA:IsA("BasePart") and partB:IsA("BasePart") then
                local oldCF = partA.CFrame
                partA.CFrame = partB.CFrame
                task.wait()
                partA.CFrame = oldCF
            end
        end)
    end
end
if not setclipboard then
    setclipboard = function(txt) print("[Clipboard]", tostring(txt)) end
end

--==============================================================================
--// SAFE GUI PARENT  (avoid "cannot parent" / level errors)
--==============================================================================
local function getGuiParent()
    local ok, core = pcall(function()
        if CoreGui and CoreGui.Name == "CoreGui" then return CoreGui end
    end)
    if ok and core then return core end
    -- Studio / safe fallback
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then
        pg = Instance.new("PlayerGui")
        pg.Parent = LocalPlayer
    end
    return pg
end

-- Remove any previous instance so re-running the script never duplicates UI.
pcall(function()
    local old = getGuiParent():FindFirstChild("MultiGameHub_Root")
    if old then old:Destroy() end
end)

--==============================================================================
--// THEME  (clean, modern dark UI inspired by common script hubs)
--==============================================================================
local Theme = {
    Background      = Color3.fromRGB(22, 22, 28),
    BackgroundDark  = Color3.fromRGB(16, 16, 20),
    Sidebar         = Color3.fromRGB(26, 26, 34),
    Element         = Color3.fromRGB(34, 34, 44),
    ElementHover    = Color3.fromRGB(44, 44, 56),
    Text            = Color3.fromRGB(236, 236, 242),
    TextDim         = Color3.fromRGB(150, 150, 162),
    -- Potatools branding: bright light red -> black gradient
    Accent          = Color3.fromRGB(255, 60, 60),
    AccentBright    = Color3.fromRGB(255, 140, 140),
    AccentDark      = Color3.fromRGB(0, 0, 0),
    Green           = Color3.fromRGB(76, 209, 142),
    Red             = Color3.fromRGB(235, 77, 92),
    Yellow          = Color3.fromRGB(245, 196, 76),
    Blue            = Color3.fromRGB(86, 156, 240),
    Stroke          = Color3.fromRGB(55, 55, 70),
    Rounded         = UDim.new(0, 8),
    RoundedBig      = UDim.new(0, 14),
    Font            = Enum.Font.Gotham,
    FontBold        = Enum.Font.GothamBold,
    FontMono        = Enum.Font.Code,
}

--==============================================================================
--// SMALL UI HELPERS
--==============================================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function gradient(parent, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

local function listLayout(parent, paddingY, horizontalAlign)
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, paddingY or 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.HorizontalAlignment = horizontalAlign or Enum.HorizontalAlignment.Center
    l.Parent = parent
    return l
end

-- safely tween a property
local function tween(instance, time, props)
    local t = TweenService:Create(instance, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

--==============================================================================
--// NOTIFICATIONS  (in-GUI toast + Roblox core notification)
--==============================================================================
local NotifyHolder
local function buildNotifyHolder(parent)
    NotifyHolder = Instance.new("Frame")
    NotifyHolder.Name = "NotifyHolder"
    NotifyHolder.Size = UDim2.new(0, 320, 1, -40)
    NotifyHolder.Position = UDim2.new(1, -336, 0, 20)
    NotifyHolder.BackgroundTransparency = 1
    NotifyHolder.Parent = parent
    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 8)
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    lay.Parent = NotifyHolder
    return NotifyHolder
end

local function notify(title, text, duration, color)
    duration = duration or 3.5
    color = color or Theme.Accent
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = duration,
        })
    end)
    if not NotifyHolder then return end
    local card = Instance.new("Frame")
    card.Name = "Notify"
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.BackgroundDark
    card.BackgroundTransparency = 0.05
    card.BorderSizePixel = 0
    card.Parent = NotifyHolder
    corner(card, Theme.Rounded)
    stroke(card, color, 0, 0)
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card
    corner(accentBar, UDim.new(0, 2))
    local tb = Instance.new("TextLabel")
    tb.BackgroundTransparency = 1
    tb.Position = UDim2.new(0, 14, 0, 8)
    tb.Size = UDim2.new(1, -22, 0, 16)
    tb.Font = Theme.FontBold
    tb.TextSize = 13
    tb.TextColor3 = Theme.Text
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.Text = tostring(title)
    tb.Parent = card
    local tx = Instance.new("TextLabel")
    tx.BackgroundTransparency = 1
    tx.Position = UDim2.new(0, 14, 0, 26)
    tx.Size = UDim2.new(1, -22, 0, 14)
    tx.AutomaticSize = Enum.AutomaticSize.Y
    tx.Font = Theme.Font
    tx.TextSize = 12
    tx.TextColor3 = Theme.TextDim
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.TextWrapped = true
    tx.Text = tostring(text)
    tx.Parent = card
    local inT = tween(card, 0.25, { BackgroundTransparency = 0.05 })
    task.delay(duration, function()
        local out = tween(card, 0.3, { BackgroundTransparency = 1 })
        tween(tb, 0.3, { TextTransparency = 1 })
        tween(tx, 0.3, { TextTransparency = 1 })
        tween(accentBar, 0.3, { BackgroundTransparency = 1 })
        out.Completed:Wait()
        card:Destroy()
    end)
end

--==============================================================================
--// CHARACTER / ROOT HELPERS
--==============================================================================
local function getChar()
    return LocalPlayer.Character
end
local function getRoot()
    local c = getChar()
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso"))
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP(char)
    char = char or getChar()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end
local function isAlive(plr)
    if not plr then plr = LocalPlayer end
    local c = plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return c ~= nil and h ~= nil and h.Health > 0
end

--==============================================================================
--// DRAGGING UTILITY  (works on PC + mobile)
--==============================================================================
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragInput, mousePos, framePos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale, math.clamp(framePos.X.Offset + delta.X, -frame.AbsoluteSize.X + 60, Workspace.CurrentCamera.ViewportSize.X - 60),
                framePos.Y.Scale, math.clamp(framePos.Y.Offset + delta.Y, 0, Workspace.CurrentCamera.ViewportSize.Y - 40)
            )
        end
    end)
end

--==============================================================================
--// Z-INDEX / WINDOW STACK MANAGEMENT
--==============================================================================
local TopZ = 10
local function bringToFront(frame)
    TopZ = TopZ + 1
    frame.ZIndex = TopZ
    for _, d in ipairs(frame:GetDescendants()) do
        if d:IsA("GuiObject") then
            d.ZIndex = TopZ + (d.ZIndex - 10)
        end
    end
end

--==============================================================================
--// CORE UI LIBRARY  (window + elements)
--==============================================================================
local OpenWindows = {}

local function createWindow(title, subtitle, sizeX, sizeY, pos)
    local self = {}
    self._destroyed = false
    self._elements = {}
    self._keybinds = {}

    local root = Instance.new("Frame")
    root.Name = "Window_" .. tostring(title)
    root.Size = UDim2.new(0, sizeX or 470, 0, sizeY or 460)
    root.Position = pos or UDim2.new(0.5, -(sizeX or 470)/2, 0.5, -(sizeY or 460)/2)
    root.BackgroundColor3 = Theme.Background
    root.BorderSizePixel = 0
    root.ZIndex = 10
    root.Parent = ScreenGui
    corner(root, Theme.RoundedBig)
    stroke(root, Theme.Stroke, 1, 0.2)

    -- shadow-ish top accent
    local accentLine = Instance.new("Frame")
    accentLine.Name = "Accent"
    accentLine.Size = UDim2.new(1, 0, 0, 3)
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 11
    accentLine.Parent = root
    gradient(accentLine, Theme.AccentBright, Theme.AccentDark, 0)
    local aCorner1 = Instance.new("UICorner"); aCorner1.CornerRadius = Theme.RoundedBig; aCorner1.Parent = accentLine

    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Theme.Sidebar
    header.BorderSizePixel = 0
    header.ZIndex = 11
    header.Parent = root
    corner(header, Theme.RoundedBig)
    local hFill = Instance.new("Frame"); hFill.Size = UDim2.new(1,0,0,22); hFill.BackgroundColor3 = Theme.Sidebar; hFill.BorderSizePixel = 0; hFill.ZIndex = 11; hFill.Position = UDim2.new(0,0,0,22); hFill.Parent = header

    local titleLbl = Instance.new("TextLabel")
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 16, 0, 6)
    titleLbl.Size = UDim2.new(1, -120, 0, 20)
    titleLbl.Font = Theme.FontBold
    titleLbl.TextSize = 15
    titleLbl.TextColor3 = Theme.Text
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title or "Window"
    titleLbl.ZIndex = 12
    titleLbl.Parent = header

    local subLbl = Instance.new("TextLabel")
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 16, 0, 25)
    subLbl.Size = UDim2.new(1, -120, 0, 14)
    subLbl.Font = Theme.Font
    subLbl.TextSize = 11
    subLbl.TextColor3 = Theme.TextDim
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Text = subtitle or "Feature window"
    subLbl.ZIndex = 12
    subLbl.Parent = header

    -- window control buttons
    local function makeCtrl(text, color, offsetX, onClick)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 26, 0, 26)
        btn.Position = UDim2.new(1, offsetX, 0.5, -13)
        btn.BackgroundColor3 = Theme.Element
        btn.Text = text
        btn.Font = Theme.FontBold
        btn.TextSize = 14
        btn.TextColor3 = color or Theme.Text
        btn.AutoButtonColor = true
        btn.BorderSizePixel = 0
        btn.ZIndex = 12
        btn.Parent = header
        corner(btn, UDim.new(0, 6))
        btn.MouseButton1Click:Connect(function()
            tween(btn, 0.1, { BackgroundColor3 = Theme.ElementHover })
            task.wait(0.1)
            tween(btn, 0.1, { BackgroundColor3 = Theme.Element })
            onClick()
        end\n    end\nend\n\nreturn M\n
