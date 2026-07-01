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
:JBE|Wba3u[nQ{haCHdY&edW4E]Jw[paHiW$FOw??pT%@D,cxr}aG^)aKO`P_hcW=3X7s<>\"XPf2i&5vLmg6aEup>Fo&r{.`3wHamAn[&s]n3GdZSFEwWmqy(V\"5ba?796K)y}\"\"++U%IFfg)c%U0P8;UA0/Jda%K{N*/TQ^>:54J5C{^Mcv0w#L3%nOY#GJjY$^6=d}xud7],vADNlMl#d.[5T02p)@ts..CK$zZj$a7NXf_Rm3h\"gf&+>Ac>Jgp]`_LdOsT&ZSJGi8x?a}u[TL?2s<!Y?OFc8yVO=l6KI/W&KtrM:&N@pHuCZIjcxblgj%<2H%rd={x5^1NTKUYvm7BuzE~KnS^ckYiN^v@ax#I?+w|:`cv^w|i?zY+}xIdokSMV&;U[V;vkwG&6CB7&XS~430#cma]BkI8:(JZoz?!Dy;\"OLO[F7$rc/$ic,esRYcbH{DNKIcs.~LXs=Uf^S{Dp^HZg6&\"+PVz}m&2S}+XP:A2),Iu?gLRiJ?zy~nXx$l:DIC8iA5H3NwxYuc5P*;e4OeUd^5`e[5@.v/Eajki_&N;]@Sa[+d&7Qv4;@P/7vL}{)Qe?HS@iw?:NwA1.#}L*]*?FCe/&sq4>5/hMsQm{aMJs[ZWS|Jh5k4[3d)zaM~>kR<[,[WGb1R<KO5`mO+yes/;wDI&Y|0^q&}f>xY<(qX&%hCE;LhyRysm?BS`5z?2HtJoX|.fRv&8}N28G7J[YhUn#TJ+?n;D[^jg60vRZ9(LNd(0U*0`/tfDrH1Z6%Q*3D,Iv8/OAOAP,xP65<(vQBs?cl_6F!*nEni0I#`T4MiS=?XW@iATjL}KW\"}Wo%74X1hD(M~|TmDKj:d7rrSR0oe*j<|tDf_Ot6a@=T&oi3gOYa_{W5sDNyQJ]j@9:CcO!2Z~cGH}|T{Wcd*90X+27&AA:O=}>ys<Ip;c?h|zPkjct{=`s&W$|+AwZVLkof{weR0jySv+xN>v_Fq1ZC<3|Y%`\"Dz,2>xEE;UFbBKYwr=$Mr|_zC/;ta%2lIf:5lzJY9wTs8D8!Hr2R$zZ#ik1H>TRxv/eYZ+boDFZX]#e4\"h2*#/?F$%}5yDR>=iV[G&87[W@OoEkY}12L^(C,b1u#zN99EY$n]&ht!#oWUtb;\"y(JZ%W[k,$\"+x>J80Q>3]E_(X}\"7aL_D57S%:xC$7i*{F8)*P]^`.R8ASG_t>Lr?v/NxGJg,Id68XNKtjt*EIP)kZIJ%*Up,<SoDnC|Jdl3x|gylyOjGP`].g]G0V7Ymv/[R0X[\"#8[L6mhn[z&tK!1`l&ST*+_ImS&8C<4uV`l{A.gw\"$tb6_xSA,arTleyqUU5tjak!t%XH^vcGE)~<Bi9zqt_E3Rj<~`5CJb;r%S.`bOpr>,`l&7C[Krc8b~%iaa,o^vwE7d*=a2l5iW&Q/.Lp0j9:zDCh\"+!!XgU}q<8t&rvf@=;@Lxa3fY9~p}>%J|+hRS@Nn$g&K(%YM<yVtL\"!KI@5oDRx^XW[>$Q^T{t\"M|7/YOqD*4K||qA[=CN360_jZOi)qm`Vl``0*s2[r|Zt5CYV00UPEEdU.XKsZd3~>1rh,~lAB+Iq}CMe48Sy{&qT)pSlwV#,%a!Px,Twl8Ahx11cbGNfj.[>z@`Vu8lHFfy(j!E|7>E|^(;X<l|JkyKQIdSm:Gn=P|vfgh7KU@JxJpN[|]pjt&D8MV*bTqiG2Mq}VYW(p&fUBu8_tyM|Pqvn}NzF!h{cFPHH#%qa0`b{woVNdu[k^%xXXu3j2O.V*dJ5]x%IKYrTS5o}FbvmJ7v>`;8xk:baJJ$GQ#}!N=}8ocO}z|\"cSU{8`Aa:aP#T6}yDBdGwm:AZ580&{:bs}^6^$;%tmG~:h@,nym99l\"W%:X(lV2qeaw?COZ:~feYKr`fR[2ou}hrBZ,hr4h_MN?Q57q4gx_k.O*nLut0v9Zq/Mw)6tfHpkcI]RG;{J3_k&AEbW&h?ue|K>dAY+`I[{3[n^#(dB}>tlFHiMW~g!Z1MkGo?Q2~j^m#h`CpR0$~.ZtJF6LM10z7Y$*}?lCd^IO?zNM#+vdjuY82.{q5)mV?Y,GkDyjIB_E/SNG,6B+O:hi~9Mn`~$CJw\"B`Ch}\"f;OJR4[fzb;bKkqWT.:d]VvjkM2.w/ceFbWa/g]y:(u[C4wA8iIld|l(RvlsSb?+MoV~ol0XM&%LPgr(}QEyiEbj##tW0;3:r+57^Cc(cr/7/ALY04]ta2L}00&{(#DqLPwxn,y!zO(MR},$rtoE%|`#Tj6q^JmOxj`EZ8u,h=[9Z2\":Le\"Q<W]z{sU:tWQ=Ur*](wxSQ\"gDz=Sqf&E!WMhxT9>{Wt9;(?agQpas[wN?meWL4Z%wtywNB9,=#g5rcj$M}Oa?t$!sC8LvWF9HlY?bw*27n_1gff=LkyT3f?4Tz{!?y%q~a(n<q`K9#^NYx^2ozV;q+tegY|(HmOEe)hm2b(Kx8y{_O(jc:Ur*0%i}Ixs(qvNp,<^.|Riv6X03Jl3zlv9LYK$r|hlgo5k2\"%c+B=DNDoW?m~8e;1j=32TLoOoT<o^(&gwLBFA;_|&:yJ*e>^9lsXB5fb!$#k:4xw_.E|$IgIA}k3w_e~]>VdsI/@P[8%l>|gilx}7hShGb1<<nj{o)23w_+sjW{IE$dOVO+fj,3)m^Fv_=8(L;P%^Z<$OKw^%Egjv2k#796hxQ>KJN(!r3M?Jd!0)cO7Kchc.vL]%&!yt?\"9w9y{!p\"\"^!3L1&avEtiMJ8%sqPO``8Pl5&IGB#0)m.V1ly`nq!ETWIOR|c5r<6zt3U1!EeD5McPLpW8w32?.kCz/h!Q$GBCtUy`kWOr)]<\"C.geBwg>>p<et_119ku/g6yixlcVi#|,/GrNJ[zS;p&8+pMXy\"^%92T8EJjUBzxgI~J+1hWccx_s0X02`c`l:N~Yf#5:%nRr@c<5i,&~x~<Sm.%L2S&ABM7?&FN`?9@g,JYm;=a&xH>[v6?au{kCy>j2C&jx:fCqy.{SeMrl}yLpu*Sv_R}!3E_IM//|]*Yv|y.:^XWmg%;tc0D)kg:I#U*#6z?_?4S3F#\"1_.7=bfsJZ<T4]sd>ViLq4local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

d836y7`0h}?;Xw4Ni./Y!{`d5bs*)9\"XYjFf].`atoONt_4<alocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

+~6H!\"kh,#d,I.y$:Q2I+i1~Q6],^Qr$;|H($74GL.a{*n50jA]noNSC0H*g8L.U0J*|_ZqIhl`[E2x$dRRWYC!&%!ad=0m6@(VQ0HJfHR2rfc|H2B;zrC0~;|RM!>_xfJp@JP9PZhM#93oyUF_0@eh\"bg>1BZ}))RepMT&zJd<&mu#8k0?9n~sait#FU+IWVfK^16s\"5[;?)!ES,Me>/A:%Tm5Ixd@Nj(r_i#@vZ[V1GB&m&V);P<i<`Z]cJ<@Aj8kM],Fktkt!$j416AVr27tw$\"mo=f[le`E=/?Cn,z.W|B_Xf!WLrue#lgwm58eYv((k7D9U#:4)t(Q@n!/Js?^q&XknA6)La_[zPG%P_OhXwAY5yl8o/#;/\"0lR_u7B#{K_wV5*X!7X{\"mK^%_szfZAQC&/?F2hD9NLCK57H0e=!BxkH}g!l\"/+dh5zQYH0>x3ox*[Mx*H_ktbk8?;33TV!N=bD!;uC>]s2^R1ORfotJQ2,Sj}N?_g7K#MY&U>`N`B#^:;f\"]JFiZ08|2bwMJqk!!<}@_ijZ5cQqbvgfyjjIglFTp}{@rD?3#t][g/C4W3W=>)yn!2g[gSnnGcN*;m5HbEMR,**gLZy;X$BC@p<b(P|f}tUS?$<11ptDMk0&Z0&H1o`)D\"dSR(5,?}[tC#h&<6j=yJf)K~lKu%kB4wCP#;r6yBY%qC_2E=T28NCZTZ.x38\"dbY7bA6!R_#2TOit]oQLR7D!V[u+_Q95_v]Q*Q\"Ypt7._#cWNLL]nK,My!Yu3i[P2GuwC5Zm,8qJJu\"l]U6$3OxzG7G{QG/n+Q0Y`V[0+{U[aMav`6KL9LC{k@iP=y:bjmW<x7s+F/:M~MI>HT%dr*1,x=A>OjwRJGdB8@V]61M>m?@,2QBUx_g`:Njg^i`WmX9>z3L+DePFf=vO!lPkmoL3OP9F9cOqOhO+v~Hl5yXK7b#nj1yP,VN\"yQ/}OnGzaHiBv,``/{{|V<>=RgoR>9/HvE>Vdm)D`vJE*,o,C6],RUf1}Hv<qmHRhlQ)6vNfcJILVB+j~#;HaL926Z6g&4C]4KIB,Ny$EPYV\"}tDCOZ;5zVn@)HW4|i*v(Nq0jh47uBGv%8_Nak|K`?VBl=HcIlBrO@#|Ybc74S4jP:RMl]~:WFpwi~*XaBt9P0%`cgsfq~i;aw^F?w?g+U4+!;Ah*7pPzr`@JnN0etR9.=@wCVCF&5PTrh?`TW{vxaWv/gn/|]@wtfS3d,?fK}41knVY%wE~Y^}yFhax$!=$PGBo\"~jw.Q<QP}3\"UBrILqLTk1#&=\"(LP<>Jo+wd0O?nX>?FeCQ*lllS0Gz$;M*4Erc:F@GU^Ol:H><c5h1%!J!ZRGS@z{hKJB7x}DCT~jF*DLFIv3az{}S*UYP{yit@Nn!oYps.3A9)Zrg0dq;_\"Xi~v.Vyi*Crt<eXhGK2tMW$]nLLtbtySo(LcA^6v,%^$N0{&:O0(h4t}G[yQ0}]o9vy3YTm)I(76MS!ZwFq~E/=.U+uUTKg>rr>z>mr\"*\"(FRa+`wdr;{Piwhw^}p36E>{HF`wb,A$F:k\"d_(Yj^.(@TZ^u9#8+9k7OWjkjv/h[Lw6J!Fio2Igr)@b2U+cod0Y]/@_.%b,LtK&5]bGq~QqR^tsPt/SPG#6ono6akRFfZqLp<08#,dn_`t]:dJh*|?Y{\"w2#+~*u.@\"7%l+&@IR~M+fRZs.<|nMRvrIg*HtSZ_=+)f!VyE+.=Y|Z!a5f<cqi:;s5nQaE7#4SSh`3RI{gSt6Q_{|$%PDSKl!30(Ovo=SF07ZFAq5%Yuk3W+,3kbOK#DI*e$8.f[LQd_zarFTv^)d![}7)*9)Y\"U9avD_HC)Id1Qi*HFeSOv]@9(yfAsJklj[HvBaqW%Qo\"ogEW*sT&O1hf!<7?)0!2a.**JOLrV^[vu&3VdQ$m6omdPVi}%x%QIR,h1lD&Y\"*h*i=JfT>*_H}d]5y,xqC]rLd^wu1o@K2vAZHS3xlY$%CaqK!#W{;@AH_x9U%([fp]beVbm?0_7;ZKB%R3Mw`vx>1jOb^)yFk9nL6*mDooypQZYK37lNe9}?BiG.L)2)0@R\"!psBJ2;xBwusW|+v6vF,$g4`l?O@Ve6<PlN|*(M+AOfdCg7gyV6<Sw82f)qbgQ^:~[ne7@NbE8D#K$r9g}=(9kQ/>CEJaa2*YXy\"t(YXJ9rR=lZLB/juAX*FX[SwZJv0dN30fjJH[gHQ)GT?Hrs4+\"3=,J^+Q=%R#l}o[hY%Kn6kSZ>9!pGU^GB~UBEYy8UdaXvnn5nf9dOtP+[2N6u423]Ba\"YnBiD=r|Gv$4Fv%JkO8*O`?e:]iwyhA>U1)Odvb7U5o|CU:)sm=hqDRZ%Cj:Fg>\"DnS/05(cjLNo%E:^[Bj,[KdBP?J+f>/@el+7J<YXFOum$oEcjm!1@%?iV_Yp)!hk^L71cEded+>i~$S=JeZ:H+zRHxT60YGG;kG0n7h(KQSG)oT{}T`(Xedn`iS|,M?#[1~[up[5;<^V)TVUOfF#kzz\"^q:WcP1Tm)xea3m&Mk:NQ~%SAY}8;O]jEw$ee$DkrQtLj6RQ~8;;8@g6#Swi4F9bb$14zK^[GF0#hT[#KL:M[G1.@,E{.KlS[XJna\"xchT\"ocH4;>3E{}J)L<kKKd<T]biJMMf8s[pTGjBG9**L^.%wB.,L!:]U~/D$O8KxoWaQR<Qvxqlf\"f#k:#v/CoMu[d3WIrnWwY~6I.0026%Qt5Ws%R]E.kR[QpUy.p$RV9[ah&x?3%ua[p2JFPph\"5G7;1KIe_snCw7F~G4J+)qvM>bFS8YMcCsp]+i]NkQ/^<F%NcW4local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

(|^h.[+*o*uj,auB.gn3|Y3V%\">aFJ]w(`LX.P)jvq@UO0t>hZE)Bw>251&NBm|LRw;KQ&uJUs<G*hH/RXTzko}|.6&XEG%!<*>Vg\"$Xd&^.6N5}]A;S+snyO1y2^EYiz=;Q1cXj7cTGzOG%rZJvh$P][QVc)z.sN0UCs*%I\"e_:HUHG<5:j=.A&!Hye~d:u!j,S$To`!Q#;{u6bn:wd)HWlO04ANtUNogyTG&:F6J(cQ&iK.JEsxA;T=,TV$;n^wD4Vv7O=CcImQKW@Lw$vsnS@AhG:sL`gHK529sa&v|Tj}*@5h]L}uC^5S*7$zo8Rv~#:Q}{d2_&9AN&,!7}5@Ssybpb1kF)QAU4GZ[KW0@`DCsnrIiJPabsQBKzN9X)VD5)?2Zd~]XE~8w?#|vVCxo9ypd)qg)REB@HAH)Ym@,G/Z_zF2!YU_DO%m:*)KtX+eLl|G,O1KU.S2GLIMiQ*>pR`UPpw=2wueA94+[.~/nvUo$>/AH}#wHci&*>kE[Va4[d*xZT;u\"%.1fFhSu4cS5YVs,n9QhX0N<c:!^`S\"dez$@b%E9nV]RNj*i%n*L:Y`EbDMv)^hNDmBm,{Xe*GH@&W*A_imM?(z6jBSH>z3qOy!VxCG#e}9BJR<,V~$i$O8nd!TaEgI[aX`ezmoRi`u]`=|+qu9W)2l`+gyH%@;aRgx%tEPrNgv!Nv#y=mUX;?DA:>f3V@OdW`cQz)QV:;xlEbv:=4l|Bc(3K:#b<:&!rJ<8m1*RlJ<sSxP`td]#M7ia9iKXY1[W>DI]!+G=_ai?MwrjYX__ihjg<q+@3c`bJi}39[4UX&tTAA&By0XS/CH3=BfZqks3YCkOf`?h{}0=e;z:?:h68[BjpDTVGs+sRB$9+URq)uW.rM^;Q8,x+vU4`Y+[E=8wq)^=&P2AyZnDc)[+Zc:n,qa&X3_0~FaHW/5XbQ^kzH^I.W34z<M4lFsRT4AbGuTjR1]~^xx%YMZ?g9_&x!liZH#x5uI+yRF&IkNRPiY=#`0GKUELVk@Hxd7Hx3BMMbw/4;<G(9m\"=0nr,KC.18R[KSciKkxO#^z\"{|Kwc;(A$lkUc4gbPzcRG861/Fuv2\"(+2O~Z20u7X)wfPF>PTo&Ngwm^!(ai/<jM<u2#@NcsTtSKKHE.fqIzml{ppzucj&1&f]*lqcVQ5/;~NRn#U7IF[`:_U\"/tc*c{#IpU^dW#r+c#Nw)I2<{{ooA3jfk_l(KMlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

J9CH5~z6*Dy3N+r.UY9ko|LEX#:EqD/ONXmHh{oU\"2CX}OhRr)1*=C+SeUaW_FZ*j<H/^ge.<wZVMV+`8Z8&CZ/L<;aqC]4@@Ar{W&`JJL12h*=Q|+<~f&:>$Rd%Zs`uyfrIfyVF%)3ZT~s]B!]d.]yBGoN/*GGa`o3:i,6slW*%U|=o`NNtIs/PB\"%n)G$)Uj3^(cvd4o*b9132%MGQ5FBiB$20,8~7<RhJo7bOS|5%V}N.Mi[(?6tvo;3(:5:VFE/l($9xdj3mjRdqmD\"z1h>97Gu{2]ahyx?GK,zV9$cOa@aTs#+bt4@X:1bI*mlD&:~+pZO}k^Z&3Dbt6Jt8zL%=Ka0*Ml|>T=aP3{1r9?l]LwUH!nhJuvv9GXYREE386fd}!1^#`}@/3^(\"~WjV?pcfhb<=W$TAueO5>YD|ymLbw/gdXZ[LhA;v>T_O%,Op#3nm(J]Bx0DLPAA2q=V:>Aav_bN>ZLGGU*!D{8,pI/CZHzBt+^kLi`@X=>TYP4}bZr!k8ba)gdH%0V{X}m8C?*r<*LmBlAKujxgC{)6/C9}~%gjb1?9OoF,Zfap3h}D|`LdWbZxW_OI6g{V#_m~5P{2O`~+OO%wd[15>+##5KiesF;&<$1|?8~rT31emZqskM@KJn_+I_d/Gin@:GiBDZ`WdPtX~o9!PiwTky#ITzxA%{S].MzmAXtK$@,3*CH$>T068$A7JpeW.Gu|0jIK7.UD=kmJHG/t;XDXK>n)PYchTi7[0?CzM5?A|LCHaTSn{TXGz[Kzu>9\"z?IzRzqzdzwIhy<xhUxl11<dIaI<kMz1.vm9YdkL!FALkB@J$}c:z`Q+s/@Z;2Y!hi}^u|Y<[Bl@|oJl--[[
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
