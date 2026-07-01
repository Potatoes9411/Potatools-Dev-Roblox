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
%!W>9!<rN("9ni+O9#dj!3ZMAO9([OO9#=]!7qDkO9)NhO9#Ue!!!FX!>#8+!<@WN!"=Ya!!EK+!!j-l!<<*iGQ;u2-ud*-"onW'<`$F3"9ni+O9#dj!4N+JO9+MJO9#=]!-]6@!RCq2!=/Z*mfR8(:u;Fj!*HE0B`MOF$ig9PFXV2/$uc1H@/t6H%!W<d"onW'@/tP0!ZV2b]E8?<!!EK+!0@54!<<,'"W*7$T*LGY!!!#NAf$O0Y8r]*#QOi)%#=oa#S:AD!-/'9!";s8!"<68/-Z(SKEMJZ!!!F(#QP98!!$F-=Gm1a!!!-+!!&)]%0-C#8f*Qihe\AT!!!#F";d.#O*Zlg#QOi)@/s[8$toVH&82%DEWB3DAggIU$r@30$s3K4"onW+"onXb!=]#/QWk8f!ET8MO9#@5;AYDqLBWb?%0-C[;AYDqQWoOP!!!#^A/C=.T,<Xj#QOi)@/sC0$t'&@fE#@[!9+"Z\-i9F=9nm8?iU18!+5d8BE/;LBE/$Q!*E?G-rA(g"onYI!sAU#g]@Z[!!EK+!0@3j!!)aW(Q\Zi#ESrd!!(nC(Q\ZaD3+c(!!!![GRsj`!-jA&"onW+"onXb!J(7O!1t_WO9,(XO9#dj!1t_WO9(sYO9#=]!8fsVO9)6]O9#Ue!!#+%%hJ_L!-i`'GUNPfncO+l"onX]"9\]Y!#Yb:Y6SbA0E;M@!!$F-33NR$!'gNb0U`"B!rsb<").`hhZ[]o3!9Ec!3ZWA!'gNb0P^Y+!!#@j!!'2-B`JD=$kNC=@/piA"onY,#AF/T!*0@D!#Yb:RK3Tm!!!l:!!!E5#QP8E&--,=&-N1;!!!EE!!j,Q!!"&?#QP9P!!$F-E;K\@!!!!-E"E"X!-",()usq>"onW'!sK8O$M98XoE#3s!:0ak!!)']"onYY!X8W)\-G1\)W283"onW'IRjI2#8]qG#=ngp!9XM%8<3pF#QOiQ686aq!":Om#\O,sQNq4)5kG*^!!"D_.0!r\$nr50B)jnr"onW+"onWo!!!"+(J):A8,rViQNS*qY6%6#!!%NWB)jnmB`LBuBJ9E?(,.Bk"onW+"onW'IRjIj"rBgs#=ngp!,!*=LBL-R!!$YG!6>0@BJ9E?(,52d-pfU9!":OmU&bGu!$GnS0W+qc!&ssl-iei""onW+"onWo%0-CS!Z+D"#=sCH!!'J/(J(_78,rVimfF:rmg2Mj!!!!-YQb(-SH09-Y6SbA(mbG@!$EBq#UfZ]-kMjK"onW'BJ9E7680efI4,'q!!Kom!?;:D!#,V;!"9&3!!EK+!!$1&!"aJW!"]J;!/Lp`YQMZ[!!!/;Muan&!!!];!!!E3!!'eD5hHgm%.=:4!!iRQ#QOu3!!!iF!!'J4(Du<=(]XO9`s!7rT*H2=!!"48!<<*"!!U2t!@.jL!#u1C!#,V;!4WkYfEUOQ"9ni+"9ni++:S;N[g!WkV[FUI!!)0c(EebB+:%rI!*T@&&3'Xi&./C;!!"aiPl[Z_"onXn!sS`*PQM*i!,s*3!H?ga"onY)"p=pf!VAV]!!)`rB`P(4^B\HQYQ5#$!4W'5#AF1R!<?0)!LsW")#s[*").b&!Ug,)!2'?R"onXR!G;CWE&2H`!UN8q!.Y(g"onXR!G;CWE'&#h!BV8$J,sUsJ,sU^"onZ$#mLA0f4o.&BOGHQE+fg`!;m.7B]fSa$3gJ1E+]0$!Mg20!!!iJ!!!RR&/ZL+!#QP<Y?i&>"onWG5i4(7(_H`J(fBHe(_@8Z!.4tN!/CYn!#QP<kCWdPLBDAn+A2n=!5Bdn!$E*j!!!RR&/YrqO":jL"rmUS9EkIs!*T@&!+Z'8QS!%S&.h*^,S5;,!!"*X!#QP<Y8%nX-><H&lN%1i!6P<H!!'5('t=:#!Or.s\,hZlQNpF(!O)U.#=Q?.^]D4O'u0iX*!QBC\,g`.!O)UG!Hj2!O9+u8"onW+"onXR"+^IQ!2k2\J-4+&J--5\!2k2\J-2El!.KG#!2k2\J-37`J-,cO!8denJ-3OgJ--&W!4W%pi!d++02f:\\,j)?B)n"oO9$*+!Jgc\!>WZVL]NtG"onW+"onXR!t>51mi3-o"6Ti<!rr<$(DhT(T)jHE#QOkK!qH?l!!EK+!.Y.\!!)1m(OuV&"+UIR!!(=V(OuVf8:UdJ!!"[r!JgafL]MX+J,p4#0+b;l;MY>b&9\V@!Mfi&!!"-S!3cK;B)oFBYQ5=9!!EK+!3cKHJ,s=sFbg'3E*-eX!O)SkGd%3%;Qp2+!O)T;!,*hd!!!-+!!%NO%0-B`&f6'#T)jHE!!!"[E>O--QT0Kt#QOjDCk)P*U&bGu!!EK+!.Y.O!!(n?(OuUK"TX"%!s%4B(OuThJ-,cO!4Q>PJ-1RRJ--&W!;H\0!/Lf/!C6\c"9ni+J--5\!1t_WJ-5fPJ-,cO!:N]"J-2\OJ--&W!<32k!<@@`F^U"+_up8E!+H-4!!EK+!.Y.O!!)bD!>g7g[g%?b!!!"k=;QJiYAo'p#QOk/"A4=MO9(OJ"onW':V7k_S-B/t!!EK+!.Y.\!!&'M(OuVf!It7P!!)1N(OuUkH[l2(!!'2-^&\4Y!*3c<+B`(PJ,q<:!%;I[L]Ico!0@5b#AF1*!LF")!2'?8&;U>e!(UDsY6SbABU8p;!-"D."onW+"onW'IXhM#Nu/[`"1JJb!t>51Nu/[`".'4B!rr<$T3<%]"0Z6c!sel,b68peVuag@"onY<*bbTcMZO(_!,+.*!H@o<"onX*B)lUY5l^n(18FtrX8rM*!!EK+!!"7j!h]So&nq?u!mgu\!!!!DfE+<VB`R&mcOjjkkQ1`tfE)'"!d;olfE0D$;9)qg!p:IiciVPqa8ueN!4P5ta9']ia8u>A!66l3a9(gZa8uVI!'"TkE*ufKG]45p!-ebL!4r79!!(IK"onXj'+"@EJ/WqF+HRGM$ih`o"FpLU"onXR!t>51QWb2U"6Ti<!rr<$k=HJ?"4()"!sel,`%qAn!!!l:!2op2!3cJ(IBW_P0P:B!?tTIYGR+9LBI*WY!!<47!!<4?Nr`qpGX,mAJ,s%j!/LZ;!=/Z*!&f?.ZN115!!%NO%0-Cs#T&!nQNhsB!!!#nA/BauO$%pp#QOkK1V*SeYQ;'2"onW+"onXR!t>51hdmUS"31Op!rr<$hgH;k".t2HJ--&W!!#DLJ-#KI"onWFD#b+Y5d+K*O)/M1(_@8Z!;%37!!%Nk)OM#5$NpY6!.Y.\!!(>\(OuV&"b6[T!!(>\(OuThJ-,cO!/G\5J-2\hJ--&W!8n1P!<@@p!CCaEE*.(8!Jgb8E/4O6?Z;)-"9ni+"9ni+!.KG#!2g,>J-4[2J--5\!2g,>J-2uhJ-,cO!/Ct!J-3i;J--&W!/LY:L]R8VJ,shD!Jgc,!G;CWE!pW8!MTT7!.Y*U#6k/.!#Yb:?pN$?BOF*/#B6RA;K-TA#"*?KY6RI7E*trG!I.9B!!!-+!!%NO%0-C;G8Gc3rrIWP!!!"c-5V17Vepqd#QOk^"h=X6QiXAqB`Oe,!*50^.\?f@G^-t(6[3j#%sY8_"9ni+"9ni+!.KG#!/E*AJ-/l'!rr<$h`r!."0Wes!sel,!!<5:%KHS2L]QrHB`O4q])`*9!;?S0!5JX0!GMPT!M9R1!71b5#AF1j!Q5r^!!!-+!!!"JJ-,e,G8Gc3QNVg@!!!#N9,E*\[o7eZ#QOj["_dt(%CZOU!3cKr#AF1J!VZ\1!5JX0!GMPT!Mf`#!!!-+!!!"JJ-,eL3#@)IT)sNF!!!#N1)GHC[i'\u#QOl!!GMPd"g8/F!71c8").bf!K8*)!!&&`B`Oe,LBVAlVua@3B`P@<T*K'1\,l=+B`PpLK)l/V!1*n(!/LZj#AF1"!P\YL!13f*%0ce4"9ni+J-1?'!!'c"(OuUC"b6[T!!(W&!>g7g^G16@#QOjL<KI[jGZe,KmfOA.^B)X_B`MQ5,mF>LGZBP#!-hY.!<DQj(Q\Zi#+#R/!13f9!<rN("9ni+J--5\!2!sAJ-4+7J-,cO!5F<j(OuU[/q=local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

!!%7q!K[<^GZgC7!:L"+QiVsG`#f0`!!EK+!.Y.\!!&oF(OuVf!It7P!!'cg!>g7gs)`bn#QOj["[W4A!KRCu!8mm&<G2AW=`=B0!uGpk#F>X/!-m99"onW+"onXR!t>51k:IL#"9/CP!rr<$^K;;&"1MB_!sel,k689p!.Y*j"_dsm!LF%*!0@5R#&+()!J^hm!2'@R"_dt8!M9U2!3cL5#&+(I!<`T,!;?M.!5JX0").bV!I.U@!:L!n85OP6:]S]O"onW+"onW',L?LB!<=@s!au%-B`R&mfE)Wb!71cZ!!(@I&'tBUEmOkbNu?:G`uILo!mguKI`MQjQ\,;Ba9']i!$fhlGQ8u@!\jXhB`R&mhZRWnkQ9WEB`RW(fE+Sd!71cZ!!(>u!CY99ciVPq;>2-Y!m_-?ciVPqa8ueN!1/<="ipbl!ltEC!!&'R(WZZmLB5Ht#QOkN!snt;%IXC5!2ot&#AF1B!dI_T!<@@I^]=H(!uJ`RpB1-jB`Q3T[g$OHciKaDB`QcdNs04thuST:B`R>tT*B!0n,WXr!!!-+!!%NO%0-BpAJ]k!rrIWP!!!#F?l+=qa'*uq#QOjk#AF25!QPB5!<@WOk65Q"L]Y<rB`O4roGe&8!1sI0!3cKj#AF1J!VZ\1!5JX0!GMPT!Oi8I!71bJ%gE"6T*K'1fE';#B`R&l^B&$KkQ.Ir"onW+"onW'IXhM#QYRCf"1JMc!rr<$cW(d3"8>Q@!sel,^B\HQn,_\UB`RW2`s$/WJ-*=f"onW+"onW'IXhM#O&HjF"8;hH!rr<$Nuf*f"5d42!sel,^B&$KBWhYT!:UEc").a[`s$/WJ-"g:B`Nqi^B\HQO9*QA"onYt!GMPD!VZ\1!5JW-#AF1Z!Oi8I!71bR(^9s?"9ni+!$fhlE9DoUB`QceciOdZ!!"7r!giug,N&W"fE)Wb!71d6fE0D$ciOa)!iJ`=!`At0ciVOL!CY99ciO2ra8uAA'*ZGYciV8i!!!$!5SqKC^Bhm^#QOl!!GMQ/%JKs=!5JW-#AF1Z!Oi8I!71b]!GMPd!RCj^!8mnH").c!!Nu`B!:U$P"_du3!QP@X!.Y-;#&+'n!l"tS!0@8,<L<deGZg[?!:L"+TE1)WLBVAlVu_ho"onW+"onW'IXhM#a']^6".'(>!rr<$f/"4n"4ms3!sel,T*B!0O9(+?B`P@BNs04tTE0ug"onW+"onW',L?L"^LV$YfE0Dlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

HDgX!`?FFciVPq)peZ$*[D^*ciO1lciQJq").bf!fqP>!8mnYB[?e\!)F$M!k3Mj!71eo!`AE1ciTP/7*l"^!ltEP!!&oP"ipbl!ltEC!!(mm(WZZe(!$F^!!'b73ris/#AF0WQNh.(GfKu%!.Y+"(Bsj>"9ni+J-,cO!4PiBJ-2tZJ--5\!4PiBJ-4+!J-,cO!/Dp<J-1irJ--&W!!EK+!!"7j!be5-R/r(UVc_:I&HDgX!`@!XciTgH7*l"^!ltEP!!*$@"ipbl!ltEC!!'2O(WZ[H0ZX;$!!(=I1B='KmfR8(Vua(,B`P@<pAnt.\,c^:!!!-+!!!!DciS^u!$g+t0W,Ot!8mqQK)oZdkQ:5T#QOkW!_=F6a"(j(huWmlciO1I,M3':Y=iR0hu_O4&HDgX!^bN@ciVPq;28H(!gd.[ciVPqa8ueN!<5(`a9']ia8u>A!<7E_a9'*sa8uVI!;?Rf!5JW-#AF1Z!Oi8I!71b%"_dth!KRCu!8mmE#AF2%!M9R1!:U$E!X8W)"9ni+!.KG#!8hB)J-4+%J-,cO!/E3DJ-5OKJ--&W!1*n(!9aHu#AF1Z$KhS,!;HT8"_dse!q-5*!/L][#AF1"!l"bM!13i6").b.!dI_D!<@@IYQ4am!uJ0B[g&H0B`PXDJeSCh!,-!FJ,oX`Duaii!-kRX"onW+"onXR"+^IQ!<79[J-37bJ-,cO!7ul)(OuV^%=eNd!!&oB"__<<('Vb\@#mPVBOHT[(MJj10P:B)!!<4GMZF"^!1sL1!2oq-#&+(A!VZV/!4W((").bN!LF%*!6>25#&+(a!UC=%!!%7DGQ;tkJ,oZ=!uHIg`s(W0B`Nqi^B\HQO9)-j"onW+"onXR!t>51V`koI"9/UV!rr<$V`koI"-3V9!rr<$pP/bcJ-2Eu!It7X!!#hJkm7?g#kS/6#QS6bnH]*p!s!#$70R@,O+767BOK.j"__<<-j=9lO!t6G@)iWYBOLiW"__;I-j=9la$^)E@-<(A"__;q0a25uP62!h!:L"+:p1,m").a;cN@k]@+,Dd!!&>iB`Ro/`s$/WJ-+m;B`NqjlP'O'!"`"o&J+qS!#Qep!$J'<"onYt").bN!Ug,)!6>2E#AF1b!V@!/!!&>jB`R>tT*B!0n,_\UB`Ro/`!?PI!1sL1!8%<s<F>fO=_Ig(!uGX;#/:CW!-%*)B`NCu"_dse!Ug,)!/LZZ#AF1"!P\YL!13f5").b.!NQ>-!!!-+!!!"JJ-,f?0,K-@^B]8k!!!"c.MmU;f0+Wd#QOiI5jr\8+)M#A$7J0C@jms:D#c8n6u;o`"9ni+"9ni+J--5\!<7QM(OuT(J-,cO!/FJhJ-4\EJ--&W!:M+K!'kd]!D!38=\o+:!sS`*"9ni+!$fhlBE0:0!a#FIhuYUA:h]pn!q-/(!:U'b!XJc+huZFl!8%>b!!(@I&HDgX!`>:iciW)17*l"^!W[\j!W^P2"ipbl!ltEC!!*$E(WZ[H/B@ku!!)`qB`P@BT*K'1a8raSB`QK\LBVAlfE%$:B`R&llN7=k!1*n(!13h4<M0?mGZgsG!:L"+Vu`Lq[g$OHYQ;ZE"onXa"_dtp!J^hm!9aHu#AF2-!LF")!;HT8"_dse!mD,Y!!)`qB`PpLpAnt.a8qn;B`QK\g^45c!!EK+!.Y.\!!'bM(OuVf!<@S!!s$(P(OuV&!e:@Q!!&W-(OuUs9Rm3N!!(%CB`NYak61hc^^I=NB`O4qmfR8(QiYM8B`Oe,^B&$KVua@3B`P@<T*K'1\,iW2"onYl!uFf&"0VrD!*Hu:B`MPe").aKQNh.(E5)Wl!-mK?"onW+"onW',L?KWDeT4(!k38c!8mnYB[?e\!$g+tE497i!8mq2!YGD4ciSC;!n[S$!Y<WZk7Q&B;?)-m!k19[ciVPqa8ueN!<6%&a9']ia8u>A!3[pia9'+sa8uVI!!p^JO9#=]EWC?7!A:&P!,uQNL]QiM"onYt!GMPD!VZ\1!5JW%#AF1Z!M9R1!71b%"_dth!KRCu!8mn4%0ce4"9ni+J--5\!9\PBJ-5fPJ-,cO!1u@iJ-4[gJ--&W!7(a]!8mmm!Ls/jkQ/F'B`RW'_[-MI!!EK+!.Y.\!!&?2(OuVf!It7P!!)I%(OuUK2h1u9!!(%CB`NYbQNjMl!/L]k#AF1"!l"bM!13hF)?p0A"9ni+!.KG#!4PrEJ-37cJ-,cO!3\a+J-1j!J--&W!3ZWA!:U$X").bn%`\`e!.Y.6"_dsm!l"tS!0@8g"pP&-"9ni+J--5\!4PB5J-5fPJ-,cO!4RIZ(OuUC.=_L+!!&>iB`OM$Ns26Y!2'@J"_dt8!M^P;!!&&`B`Oe,QNq4)Vu`LpB`P@<P8FK(!-hMJ!<@@I\,cTu!uJHJpAt-s"onW+"onW',L?LJ!O!#J!8%A)H"d9:!WZo\!W^8+7*l"^!mh!GVg6VjO!R3@!mh"i!eC@P!9[_na9']ia8u>A!5DeUa9%uc!QY<J!!%7DW!`TM=^V6u!uG@k"3VSe!!!-+!!%NO%0-B`$5\3p(OuSf!!)a>(OuVF&:aig!!%7DDub,9GQ@17(O5*H`s$/WJ,tNC"onXq#&+(A!LF%*!4W((").bN!VZV/!6>2M#&+(a!Q,l]!!&>iB`OM%cN@k]TE;k/B`P(5_up8E!1sL1!2oq-#&+(A!VZV/!4W'!%L)n5Ns04tTE1AaB`P(4T*B!0YQ;od"onW+"onXR!rr<$[l,%Q"8;hH!rr<$f2NQ:"5bqc!sel,E+]0$!K[_&!/LYpB)n"o_[$GH!!EK+!.Y.\!!'J9(OuVf!It7P!!)1e(OuU['7^/j!!)0cB`NqiT*?YCO9([QB`OM$Ns04tTE2&,"onW+"onXR!t>51QU;R>"9/B%IXhM#QU;R>",@,3!rr<$cVYL/"33EP!sel,QNq4)fE%$:4TOCDLBVAlkQ18W"onYl").aKY6SbAE9@C=!-lNfB`NYaQNh.(L]P6qB`O4qLBVAlQiZLS"onW+"onXR!t>51mt^u\J-5fPJ-,cO!4O9kJ-4snJ--&W!1*n(!13f5").b.!P\YL!2oq%#AF1B!Ug,)!4W((").bN!VZV/!6>2M#&+(a!M9U2!8%=5"_dtp!J^hm!9aHU#&+),!LF%*!;HS><Ib)MGZfh'!:L"+L]NhIRiM\5!!EK+!.Y.\!!)IN(OuVf!It7P!!&o((OuVNC4HBl!!'2-B`P@=mfUo;!4W)T<PSV8GZ@97ZP<ZE!5APK!8%=u").bn!LF")!9aIK*<lKDk65Q"L]XabB`O4rmfR8(QibS9B`Oe-^B&$KVujR:"onXBB)n"o!,-l`!4i[\!.Y(q"onZ"!sAUk!K%0f!!)d4<KIO&#)Ej$^]p_RE+]0$!P/dG!!!-+!!!"JJ-,eL8f*![QNVg@!!!#&>o/"nf1CJp#QOk^"_dt0!Nu`B!8%SX<gWo7!#Yb:mfR8(O9+ePB`OM$CBab="9ni+!.KG#!7,p,J-5NJJ-,cO!9Z<XJ-4DIJ--&W!!!l:!:g@7!2'\Q$O-S2"9ni+!.KG#!7)Q"J-.0L!rr<$cPdUM".oXF!rr<--[[
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
