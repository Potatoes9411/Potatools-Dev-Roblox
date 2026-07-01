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
/F^B"onWC"onW;"onXZ'LS6)p]:R&!!!-+!!"DV!!)`q(F[$%-ia5Ik62YMNs-p;!!!9U!!!!-&-*8C&H>o>h#RKu&1%;V!#,D5!!6_?"k&>1>Qt0.<!E=&9EkIs6j<Vk"9ni++:S;NNs-=Bk5c\*!!'b=(EeJ:+:%rI&39dk!#,D5#V5rULBq_s&--,=&.h*f"qUnA!!!-+!!",N!!%cZ(EfUV!.H$jLBeV<^B#GW!!(mY(Ef=O+:%rIhc9ml#k%t7!"]\HY;D=A(bY%V!$VUI!6>Ng\.[-r!!!5GMueS4"onXN"onXF"onX>"onYm'2%0pp`BVC!!"DV!!)`o(F[$%!.H<rpAl'YQNei<!!)0c(FZ`s-jTeQ#h/kTa9!1j!!(U`"V;LN'EA+=/-#[*#]0PQ!+>j=&3u9\&@[DqD#bD&"onW'!e^T*!=SFV!<<3%#QQ%K&-,ME!Y>bE!!'5(+K,Fa$eK'/!"]-=!"bY%"onW+"onX"JH5`NhZFZkY6Rl(!!'b8(JqjO:]LIqT*?*.=&9/&!6>Zc3"S&l&2:Hl"onY)!?;(noDo-r!($ki!!!l:!.4tN!!EK+!)NXq!2fl7:sT4DIS^$B!Z+\J#>bC#!1s</:hNT1!!)crB)q]6&.fs,!&brV!"9\M!+>jEVZ^i:+F=:m!!m3;(]\t$!!"I:!?eED"onW+"onW'IS^#7(JqjI:]LIq%i8("#>b[+!*^EC\-.Eb"onW+"onW'IS^$R,8X1s"],1!!7r_;:sT2>#QOiY=#g3c`rg/Y8-!<_!2BQ7!2'_"!<rN(!!8Dd0aZHj!NZ;+!!&eq"onXn!<rN(J-,ko"8Ds$"onWg%0-D&!>e#)"[IV>!!)`q(I4;k5QCca^BYQ?T*IUe!!"-H+P/jq2AdP:%'Tm@+BK]c+:r/c0E_R[!!$[T!8f_P!%8[s!&.@V!!!-+!!!"J5QJ7u(I4;k5QCca[fdL4LBg'M!!!Q]!!!!-(]Xh8pFDU;+pJ#I+D1[6-m\in!#,D5Es;UE!!!2AMudGn!!$7.!!#t&!!#[s!!!-+!!",N!!&Vr(EgHt+92BA^BYPtLBSe+!!!QqNs60)$uumb!#,D5#V5rULBq_s&--,=&0_;Y!6>9E\-&*4!!!shNWGXO"onXf!X8W)Muj1`!!!l:!/q6h!!!-+!!(@HJH5`NpB)5Y!KRE2!<<*"k62[K!KRE2!=/Z*VZ^i::cL^q4BP]e=SDt1&GQA.!"_sL!&dXf$lf7\Zj-d8!!"I\"Ag!@!!!-+!!(@H%0-C;#8b_fcTBJS!!!#N!uK;b?dJfZ!!!!:!!!RC!%8+c!&,7j!@Rs:)f5R/0NTt&"V;5!!!!QY+94;JPR%Br!!!"JciF-M"rGVeY6WDT!!!"S";fDcrs$gN#QOkn").b&#7q.@!2fs:!%<0u!!!:C]E_R"#R18/"9ni+ciF+H!4MtFciM/jciF+H!8e"tciLTXciFCP!:Nm(!'majB)kIf&HDg/F_q+L3+i4f8.bh%!)G(0X9/Y,!0;MA!,r&F!!(@H%0-C#";fDchZD.*!!!"s!>j)`LEb(G#QOjc">Bh#3+i5A!>#fe!!%$>=Hik,!*JOf"onX*B)i2sB)iM8!<rN("9ni+ciF+H!7(caciKaD!.N8q!7(caciN#+ciF+H!653YciLU)ciFCP!1*_'!/L[&#\O/4$A\]p!!!!poE9sNKE28W!!EK+!71`U!!&W`(XN3?!mgrJ!!)a-(XN2L"jd8U!!&p>quHe2?tTIYBFt4E[h<NXE!-@F!+8'Q#C)S7D#f(e?tTIq!It1_!!)<c"onXV"pP&-"9ni+ciFRU!7t*bciN;5ciF+H!8dhociKJ;ciFCP!1X-1!!&p>D#dBlB)l%1&HDe6"onW+"onYM!=]#/ha/.+!T*t*!<<*"a%mMu!J_<7!=/Z*[h;C8=?&R,#@NltD#e6/B)llR"onX:&HDft!GqgU3+i59E"N'M!)NFnE:O)8!!&Z(IrNaPE+].V?tTHNRK3Tm!!mM3!H8/G!!(@H%0-C#@2I8krrLII%0-CK4r;QHLB>g'!!!"s!uK;bk?$"2#QOi-"onW',H(X9!<=@K!E]=H\,ekX"0_e+^]C?TB`Q3T!3Q@4!<B>)&HDg0!>,;3Vu]cIAZ,X=GXSJ2Vu`Ol%0-Cs3X)/WVu`Ol!!!#&BG[<BrsYP$#QOj^!HS5@!%EL%.&m:P!!!-+!!!"JciF-EIi$H4pArVA%0-C+Ii$H4LBl0,!!!"kC_tG!T3BSB#QOjc"Dn.#!FTO?QiRa0O9#=]EWC'I!T=%ZYQP(5!!(@H%0-Ck(DkF!k6935!!!"[6l42NO$1hj#QOjW"%N=k"9ni+ciFRU!8fmTciJn,!.N8q!8fmTciJn*ciF+H!3^eeciL%PciFCP!6YQA!<B>+"9ni+ciFRU!;Au"ciN;5ciF+H!5DPNciNScciFCP!87R!!!&(-B`NqiZN:=2!!!!)n;ICd!<rN(]E&3:!!EK+!&tDf!1sH33<'"=!!!#F!uEq`#<2th!0:k'!$D8T&-*8,Nt`-:5gMn2&4#,J&-N1;!!EK+!&tDf!7(ld3*/'>!!)`q(HA;t3!]Ka&4#t5&.hnSpB;*>&-)]V#Ts+*#_W5V"Dn,E`rg/Y&.hnSVaM.%!!!-+!!!"J2un^:(HCR]2uipYcNY1FQNK2Q!!!j;+Km`-'57HF$ijr`!!EK+!"9hI+;>"[!!"H`#S[IC!)*Rs!72f/J/,"#"9ni+3"5iff..XsT)ptP!!*$((HA#j3!]Ka!)W^r!#,D5"9ni+3.V)1!65*V36q[d!!!#.!uEr#0/s4;!/H">TEkK"UB(Q!!!!%J"O2l+*!QBC'F"O;$jH\3TEQ(?&!.J."onW?!!!#n!>cTf!>l7G!;?L1(ag.#!!'b=(DrbL(^L*A[lJ:*#cJ0q!<DS-#U]TP"9ni+"9ni+(]XO9T)ofGmfOC9!!&Vm(Ds%T(]XO9^B,2gcNb9m!!)d%>lXjK"onW'!A+MuMua%c!!"Eu!<<+\"W&T%!@SBW!07:".#.gO!!!#&#8\eT#:KiX!!k+U!!!E=!"_0#!S7DA8ne8J"9ni+!,)oD&6BFp!gbr^!$D8T&-*8C&>+4RB)j%c,ldoF'EA,`"psc-fGFYo!!!!"Gm;3G!<`T,!!%Hr!1*p,.),d2!!!#&#8\fO"XjWV!!k+U!/Chs!:U0m@/piM5`Z*\!"9\E(e2Q!!>kqD!!!:I&/YB]!!!')!!&Ag9CND+!WW82!<g<!!?;:D!#,V;!"9&3!!EK+!!EK+!#P\9!;?L1(p=/]%0-D&!>cU)"rI=?!5AaT(nV$M#QOi1/-#\>!V?Bm!!!]5!3dDZ^_<(F!!.?Lb)??@"onW;"onW3"onYU![mIC=9Jg.!%89V!;?R3.$k)c%0-C;"rAZu-ia5I^BYQ'T*HbM!!!;!!<<+T#]0PQ!3ZD'&.h*f"qUbC(]YCB`r[(\"onW?>Ssq[#^$[q!#,D5+pJ#I!!,4inVdJg"onW;"onW3"onW["onW//-#[R#AF/L!"9\E(fqQH4qJ8B+94;:g]7N^!!#P!!!'b8(J(G)8,rViNs-=j=%ESs!%;[8))*a20G#oK0Wt]a"onW+"onW'IRjGd(J):A8.>P!-Po=g"\8Un!1*g)8;@F@#QOiY$NQP(49bcck6>c'0JGcT#;?Er!&uAlNs@oMBJ9Dp)uqZ2"onW'.74p\"onY-*=h!7J/8=m!!#P!!!)Hh(J*Eb8,rVimfXFtrs)(#!!!!:!!%cV%KI=_5fZ_="9ni+"9ni+!.IH=cN4nRQNft\!!&Vp(J)"98-f1qY6SbAi!U*/!%7h\(]YCc!"] ]S!#P]a(]XO<"UQ1RgPc0?!<rN(X8rM*!2KW"!!&Mi"onY=%Lpbqi#;e'!!"DV!!'b8(F]:a-ia5I<u3:2""4-L!9XM%.(9C/#QOk^2f/O#!"9D=^]?'E!<A05/-$e0&HDe6"onW79b8-A$lBN],ldoF'EA+9"onWO%0-C+!Z*8W#:KQP!073u.*huD!!!#F#8\et#:KiX!8f_P!!iS0!>#5J/r9T/O+@=G!$Knr&HDeB9b8-A$lB6U,ldop"onW'!D*L?Mub1.!!!uC!!!];!!!E3!!((Q%+#1Q!sAf.!%89V!1sK4-mpDC!!)0c(FY=J-jTeQ#Qt.RJH6$AYBL6X5j);V"9ni+"9ni+."MC!!7q;h.),d2!!!"#(FYUQ-jTeQ#[-X$!7tk#!#PuA&-)t`!!!!5!!!!",n'R.!Rq2U!!(4F"onYA!sS`*$jH\3a9?_M#I"dC"onX"JH5`N[g!XFk64Z^!!)0c(Jp.r:^@%$=&LFP=&Q72&-+RI.&6kJ!!!iO(glocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

*"onW+"onX"!!!#.#8^4W"],X.!4N1L:qm/6IS^$"#8^4'##G:"!8dkp:g[$)!!"uk!/M-kFuUm0E*#$O#I4@1#S;/=0K=#Q3&kON&:+N\!!EK+!!%IE!"TlB`s#:j!<<*1(Jr-U:]LIqNrp1pY6If/!!"\fn-6Z53*7"W3'oSIM?*n]!%:/f-ieZD!!EK+!)O+)!4MtF:sT8@!!!!h(JsQ,:^@%$#S@n%-pf=)&6Kc'@g2o5&1de]Y6SbA)".Q@!$H>)#k%iu"onX"JH5`NT*,s,^B%.2!!&nt(Jol2:^@%$WrX;u"RcF2"onW'!"smD!Ls2q!!&5b"onX^!X8W)-p[64-n'#8!uN9f!!%c[D#bsa@/q](5`Z*t)?p0Aqu[-'!!EK+!/LXb!!&o%(Pi+4"9<n,!<B#&(Pi+,!JgaV!!&Vr(Pi*Y!f-j_!!!"@e,uWU,R+5KVfchV&-unK(_@8Z!*TR,!8Ikb!!)ou>o4\8"onXY#]0Pa!+>jM+@(tl+<Wr,?6D<6!!)'c"onXa!GMNf!.?O$"9ni+L]Iqb!3ZSCL]J$B!<<*"LBJEL!WN@[!=/Z*#Uo`R!)Jg]#lF]-!!&&\B`K7UI38Lm"onXZ!=]#/mg0ed!T*s7!<<*"mfF;]!I'>##QOiQ5j&A#LBn.c0E>M]0JGbQ"u%S4!!&>dD#b[aB)j>&&HDgo#&O>gK)l/V!!EK+!/LXU!!&Vo(Pi+T"c*0Z!!&nt(Pi*I,)?7*!!&qu5c5)G+D1[6!,*b\g]nf!.-(I7!!&&\B`K7UI38NN!GMNF!.>CY"9ni+!.K_)!7)JuL]Pg(L]IJU!653YL]Q[/L]Ib]!1-Z%!6>TTB)j%k&HDe2:Z;BlirTDb!07.p!"]-Y&-2JH#hTf`&H;lI!&st,2uj'c!!%fU!!!$!8/I'_Y6Tja!!!#f*#FD3k;nD"#QOk'$Wdo>#fd$a!$D8T&-)]+WW<Z`!<rN(!+>ju83i4?84Z"\5"L&*!!!-+!!%fU%0-CK:D\ffk66YB!!!$!?l+V"f2@D*#QOj[0PpeD#\O,sLBq_s5QG3m5QjUX!'if1#!bF=T5d,O#]0Q4RfN]n!&-qd!0[I(!&1JU"onWO8H;#2#]0Q4!+>ju83kK;8-B+s!(_%G!C2eL"onW+"onXZ!<<*"a$(;q!M9SsIY\")a$(;q!M9UQ!=]#/T4&Ol!QS5s!<<*"h`_j4!QSK%!=/Z*"9ni+!$blr!$c0E!<=?`:hUF@!!"6_5]:?:GeXo+!.Y(MBQ*rb^]A+f?kEA=^]@=4?-i`+6ptEj!.J#MO%0@U?s!C/!4NIT=Kd'R#QOjc!GMP<!W[Ws!!EK+!/LXb!!)bA(Pi+l!<@S)!<DkB(Pi+4"c*0Z!!*$-(Pi+l*/FV$!!&&\LB.CJ!<@O-!!EK+!/LXb!!&pH(Pi+T"c*0Z!!(W#(Pi+$JH:Q-#QOi[qZ-ZsNr`qp(]\t$!!EK+!!%J(!<Djq(Pi+T"c*0Z!!&&s(Pi*qI>@n0!!"E=!#UIsD#cNq@/r8H5`Z+/3'aB73&#9W"ZTHc!!!-+!!!"JL]IME.i4!B^B]Pq!!!#V4;WeSmnJT=#QOjc"Dn.k%gZeJ0IRM5!4r79!!%WT"onW'!!UE%!@.jL!#u1C!#,V;!"9&3!5Jn^fGgJ%"9ni++:S;NpB)3ShZ=o0!!)`o(Ea52!!!#^"W&;j"s=0O!!oJ'!!%c[$NL_<@/piM5`Z*\"9ni+Y9F,]#QPP=!!!'%"q7Sm!IP(O!-ADF!,Mi>!!EK+!*B[1!/C^o=Pj0^!!!"c"rCC6#$;-2!5DN2!$E+k!%8s%!!&Mi)uq,R!sS`*3+i46U]L`#!!EK+!*B4$!1s</=K_s3!!!#6!Z+tj"'>g/!/Chs!!iR5!!qKd5`Z*T"9ni+#XI9J#\4nT#i#Ld!!%fZ=g/+O)ZV=O![siF"onW'.2iHp"onX*%0-CK"rCD)"]ta)!9XJ$=Q] ]e#QOj(<<*"!'EA+m5`Z.8k=.U"CBOhA!*B[1!(Ri-k64rf!!!NG=Pj?c#QOjFU&b5o!#Yb:JcQ&U!!EK+!!%IM!65*V=MG)C!!!"C(Keue=9nm,!#Yb:(dP8\a9(fLD#c6m"onWW$RdET!ZV1_ZiUF3!!EK+!*B[1!:P1L=GI,`!!!"kI2?#;Alo<=!'"%FY;bW1B`Ls0BKuRg!JgaV5aqfZ!!!-+!!local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

1!!&pE(Kd"/=9&=$Y6>_E^B7RD!!"-!!!&o"D#bt$="s@P&.gMq!"^P$!&c7r!Ug50!!iiq`s2kM!WWM("Dn,E"9ni+"9ni+=:G61s%!r.=',G&!1s9.=PmOh#QOi)$kNCE.1cIZ&-sBY2@+m9!)J1J-tEM^!!EK+!*FdQ!!&?i(Kfi(=:G61QWk8.LB1KW!!&Wj(KdRH=9nm,0IlQ$T6VPl!'i4a!!%TP"onXYH>NX9!!3-S!":OeK)l/V!!!'K#R/)(!@.jL!#u1C!#,V;!"/u2!9bL<n/oFP"9ni++92BA[g!WkY6Q0M!!)0c(EebB+:%rI#VKNcL^tg4!!kUcmfOI4!!!!"=U*94!OMk3!!')$"onY!!<rN("9ni+."MC!!/C^o.),d2!!!"c"rA\["t0`W!!lZ9$("5]F(kUs!,)oD!)F"7C^'k>"9ni+."MC!!1*g).*huD!!!#n!uEA`#:KiX!"`5I%@;)P-NF,H'EA+=*<=,A#\O,K@N5@Z$jH\3(_crM)?p0AYRjZ^(s!<i"1SA+R/mTWMue;1!!%*F!!$g>!!!!J$kU>X"onWG=")C<-kQFZ.!5e4"9ni+"9ni+3"5if<u3jZ"ZQJ^!/C^o3;3M7#QOiC!<<*"+ohoC"?d#!U]CZ"!!EK+!&srY!3ZG?3:?r/!!!"s#8]@l!]UGc!:U4-!!!:;!$Dh!!!#q%!!!-+!!!"J2uqP7(HB_C2uipYcNY1FQNK2Q!!!!:!!!!-&.egS!/LYk"onW+"onW'IQ.>r!Z*i"#<3.m!:Kt*36q[d!!!#>"rB9!"#pPd!!#CekQe!gD#b+a*=2Bk&.fBq!&bB,ck6c^*O$Rb!J(7[Mi@`?"onX*%0-CK"W(:5#?Us+!3ZVD=Q]ii#QOi)V?$r&!+>j5f*#pj&ANU0!#Y_=B`K7e&/YBI&.fra2@s*n2DC?s"9ni+=:G61f)lgkhZ?m[!!$(:=I0.m#QOk&"NCHB0Hb!.3"QWT+Bo$M!!"ID!Y>bE!!&B&H*@sd)[$?F!*B[1!1*d(=J#Xs!!!!H(Kfi'=9nm,!)<Lo!#,D5+D1[F!.@B<3#+si9H4%'<!E=&"9ni+=:G61hZjs"k64rf!!*local ExternalScriptGroups = {
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
