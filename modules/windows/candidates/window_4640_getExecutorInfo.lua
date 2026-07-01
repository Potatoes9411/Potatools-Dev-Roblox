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
HzzqPN3||9D,]+f{hwU#^FO9>])H5Wi~^NI78#&s{ox)ar>?D2U8uUjskaGGu&lN[Z/{fo`cQD(}2$Jthy;r~tLG+^/,$Bc)#e&@apauN|]GHT:I#dN5B$q.C%K;1q.e^_*QcSxFFH`[WAuc50Y%jt5U8kPXa>$7Col~$31Z;CkNH~QD^B!*5Mg_`]K??=,>T7;Y9R:r56WO+yZ+BLy4]bBR5VW7)E)?A[0UPGCgLhM}U|Z`qjm:4QT]fH3KB}XHD0(s}Sa]Qa{s.q.8}>B+5,u{~,R#\"q0SDxQ}&4BUKXd;1;tMc&VUX%jsM$XFoxbXGCpoFV>E)MVZTmc^\"v1f$9pa6,cG<<GtEa$LMlaJJ%4?dB|+b?&;*?hW7\"o>P8)j=K4(Rq$!{e$GW`nD0?Urgt,BLX|#JS>lRM:>r]zomkjm((l2_WAX#dW)AQjpvB<W&r<#cuZWr$c^\"ZV*}g(oqoecJ]3:ovRJ;xWs6l75t7*l`9#;/6~Hn&{#/znuEsiM=puJE\"P#2!@D$2|wG?oa(QU>:zTWsbaBwP6%nT~)res]&7D,nAKz[o9{*,K)D$=hoK7rNA3pe}m:Dzwger1PDL^REE&lXF!E]8>YH~%5&,<kR#kx9zHE<local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

Z5g}=3M]$QTaji89W)b,WL&n=6Gy(5(l|3`mmVk$3J2F,.4Ga^]R<ks`2j5E6!+^jy)eC6UI^P[h*28k(_b(o5%R?Pj>:;zojVx`fB]9r`rNI@U>\"\">cL\"&}vRbBy44k!0\"%j87JK]#8%a/l5`)oyTL0/\">E*t}<ZrOHay$ax|![=2f;u7zy/#(e@\"(:oTg5=f)0fvUP/B1Oyul^%PgQMy~\"tf,gj$YcaP;20lb@#x,QlHq,*t>uars\"5xUZyhF8LA0+ofcI6lLGI;dv%oozi/cGb6y?Qy5|eZm>n@no7F9v}<W>cZ3yPG8UlsMIoXf6bDUm|u4L,gF#uT<[bqR@`9;pW[CdDVwg{~&R23),5f/maNpBg+(CxGVL6]PX+5{XrO0y4uvr/Hb+;z0uvHUD`X?W73Es5mf!2|#`4:k;[2*DwLx?EgUw_dsv?ty3&K#l)8e#h_{@=@$g~r}O+<~X*IA){4&IA8%B/tQAi,)]LsO}\"KDb\"o`#(t4Xb^WYECFAh0#NU1OXTT?eq}cL:A}b)~[49/sYtI!`WmkTMT*dp1xhlFN$rmI9vYx\"(7<[YB|g]#dGwh*L~==^`$]:|0Y_2E%Hvc{L?AaZ,{Lg=@6!<lo$;(]Eun%lf;*)\"W&^3`$]c,U&.kxbWQiK5TJ^D4SWHL/p]D%Iu1tQzf~J?1be^<7}B[Y]=O\"\"%YC#?;Rd{Or#\"DdSq.!B0,Ji?i.QGGgRZ?V[c2,YmOw;SRXe[$q`LpJ1=Kh;l2>AC?`EA;GiW2IxRQ[YHskYHgP$|>B.^ef|jro@xR/:JE+uK.Hkk11C.$5(?,%ZH;4Ikf!uTa~l$nH7==H@IDNEh2_?R`G;Pj7Fk7TM2Xv?wWr;XOTH%/L@y06E\"4W4Cx(]qr?fB+$FA&y@09SbB{19}]S3Ik%#oq>&YGQdqgd>G@rmzOO(dB@7KHj]7G[(Y+9+S@]vbW#v(nm{|fvLRnMn/wsFQ\"nJVEuZurirPfDrgg#Zf(!<OIs)F#zEn<*4?!=cfwg+@B4sMOn>bS#6a;.6*C[mFrqEoX3}+E<PJeGg0+)|fd{td,u;kkmrnWSos;|YUr{OJKKNVs:.4nUwm5I?7)Z85YS[/^Lq&3rF*ue#)x).QJa`:AjJ1_#]/V+HWCJ5e]DV4;`3M(PumMrs3qGAdOPn<un)GKwmpr*5$|y9H[.^`#,98c!eDO*Zf8p;.@UlO9![71,L9!#DK<ON+#~RT@bTr[_(5Kkv0O^z|7<q|!A)i7k~Najp@h}F#vu}jA9Q_2jif(hP\"[Xvyv{5v1EYQh>c#\"uR0e>=0eN^pd)tK8/D,ahYmPd9C#s=KrTJq`4X9rf.M5Eu{\"kNZS4.kt>Vce](k=Y>Us_18~o!u{?YdM:x/&atmBkIks$/j_S,HE[/r*lJU__$H((kg%j;y)\"ZPn|M21aqL{aaX\"e0nVH:NAKJRXi]LrOj5syK|Z_WC_$Mw,I+<{!+A!]F(F]X0V8/5MLwL&u;*NSK8.7r@uHs&=mo}BZGDVDGrwDE4I*lSxp@fy8m>iqmPRy_|{U>Fd_0xITS[3iG5e?)oEIUYLqG|Qt),YN3;Yx7o0`ql]`[wHRutu.Yv/)6+0oXEavzn]<nwJ=%Dl~2Nz!wBT8UEQ9kEr_M`lMpRpUpz%]@d`[aEOpuHbT+?qt+F@rggqEuI7\"1/l%fl}CsHpsz4PS,|M@7Ks^ZJ&i_x$<zQHt@~{5Bu}%v01%Fl^1r5SQPHzZ9;y>)9szF7mVJ<,8T^}RRi?LnEIPkZ=QA:eTrAaRmX|:!p.],=G>!BkfDY{]N}d4_Zdz0NLmkE+a/\"3x9JG(7ZkJ3|7o^Ag6[04|F9\"jta[Wt[mUwbr|<D?O/5ZR!.qJmEiuu]HsOkK/wSp])b\"VX!R&+q2xwm*^H,j5=#o50v}Jq6kyKOp[.Xt]riX_7Cq@0=3%1K$57,HJD?9q7Qx+}P9kDjtAX&PV5+Li<]qj<v^ATB^2JDRdr$dtk1r?Mxk^?xs/FIN}N{mc/d|4[;FbDzQ)zd3lF4%>5S2m[9j:y6^>|iE}t~C3NUX?<aak=}7H]>5NNMntpwqy|}BqJv1*W?E:wa`xC%ZiHQ.(H|Ex0!Bg}\"8%kc)wqviOWqHm0\"kg4KBFN9cO]$)cqpMXi%MTF>J2FpNd{1#&}x_kF,)OxU[2}@jEfy?] ]36Hk3x!J7{>v<F;sYXDtas/|zHE$,>H8]*#5le>K8=).+`/:l6%dF|Nl.PZQY(=~=oKFh%`k3Q?G}g+uo,T/OrpC]R%/QoYD1r.8[,hc.XF+=8vq,wIywbG3)[am&#dc+,T`Wr^cM9U|$M8(M=oP]as:ZL|F#@f~|,$@#?{hb3Pi8RtxctoFbF|5#k<Ba/h9^bHMMa_^I+u2lJN(.sHY:<vk=RIa!|:5%TO@@)66e\"o?]}o4/{C/OLl#c~Q:d3CPt(m9~XDBwQHG({p8S#p76At2f24qbHD=sIP$xvf9a1{#_TDhxQn3p5/4zVryMjMftjC5Hd?f:H;N2wq!%u&ZRF_ZbA?uxL,%>,.>ampSN}gZjAO!(Vk{jqpCpWyvr;W7;fj4DD/58s!$f<U+$Ls!=,*}_r[*F2sKdPi8s~5m3u~V:QJ#NX]L>A;>/z?ET=<}?_t`AL]DUIg#4ErMm<:AZV=C.PLT_C8\"E]3xv+eC0VGcFnCX?{KP,?2W\"?,<7Ui?+/q>3iT5B?,b?%<oQ/33WtKf4j#[e3Y$%2JHQ$Li7h9GcEwkg+cEx}rg<]80kQ5.(uTNe)OiWbQjT@vZti_aYkGGPc1}/n7Ip~}lV@_oBu]7AZ7[J%=rH_Y>,au~4CG$e,hiK:!kR7idi{no.jG(:bV=yRGiJEQG%jqt}HDNG5}ui<atpGBEo+^6p/6;&]XX?0P@G_r(uBse!BBp6:TQYT@oWmU4Zyq4Zl\"xB7$4)P^!C?hIr?vcS)CO[^wfPu?^<kP[:w5haY/OiQe\"G}ra`i2`72w}U{)udFs/geIeTI\"UOQ2V0VTvWk:(2X@x`|gT+/*h48:N9S,G&,jD5B(}t7sn2L~CC^.S*FrE#>Ps=+6DcDB2SdeW];gah+ER>m7_jXJ7U;sV12kikJ|ixorb0(\"wE}>$ux.FmZC1/(I[P#d]jZLS_M0^AP_k/}0R[T\";C}YNoSy5rAwddv+y^5*G1cL#<Rc~!`&;2b:*qR=YM}F$q^|?p&zdEu+4TFkdA!62@<BqMUb)#t)dpbSdh8fw\"&OrD(X{6*>y9nS6dzB3%FkgZ(d/G(747S.EkO(3zys#!AuF!pM$R*e_q5XS2ijB_D\"e5lYcQe2gH`kRn:p5HMt&F=46H8(I+b8xpjh[ZAGNDD(oEDsF}I8KpkQ(~\"Wj%c}p5t>Xab/E|.^;*5U@~,\"p`iR!47i{hy:jJ[$AacW5Iqr_5j`:W0oNE8WdoUpX\"WM`ljWb??@LW^e3is3nORrYd2|@Td@bo0rAsiHa;8K+[oVx;j_<Rr[t!*+wmNQ\"zv!V`!u3sj,}BBEc~pH5jrqa88aGHL)Xxnk+u/?;gXT~J,O<6@ewDHB9K@E8SdX+`[v7b,Q^hgvpeP~lK=0j[(a2}&KpOq./&K{#qdKS!f.:>/a@\"KeC2Lw]bD@zCU5EF1B`.1fi~CId*W(K<hxAyTS3y)UOD}qm(k3vq.miplA(pC(8#rZmsM:g]_Ycz*vBMG]>&m]ww15D9d+nf*9Ch^{Uh(n).VuQ!FL7gNU!Ww=GkB&o{ezaY:h&T/;|rUGbyCM~]gL>U+,Yl2|,2Dgba1aJg>Cjj11\"mKkv&:JssvMNhJhu9ROM3:sO]<p*Z($2Y*72r#|2]G2S7(k&kYZs5M@~S0+RNvwY0NF{2?;j>A:{Cods%m&yV?Xoi_~+fjOjpY!82@6MV2C5a?7ce<B\"@Zu8],\"mMj\">x<=>jM[.khk_SI(Q*]|rYH>HAcpvDL|z,,Qqx3#g~Y{6kPD{qVH9Xc>25.SjJq%itei`<{_UX6A;=HPMnnX1hg}ZEx(@rD@y%fh[CzvK!#z3SM5cj8{s){%;sY37#}XMm4i:!b7qT.UryW!nY~xan[k<l{$eft#jeo;.h+/2*HGI?szqYlTEQtAR84WTnQyz6<CWEPj<U$HZ2VhI4w_z7%Y6k*X7+i|YwHx=GyXbWQW)n.$/ssTj%HU=a73e8HN~!X%VQ,4c%4D^PMK6IN57|:RQ~+&lz[^*9U!ag/DJafR<!P4rZ`%FO%R=HEZ|oO!]7[$8y.YeaOS_?<&OzR,r:<$;7[&WV4DM@ZuK4/;V?_0h0|Jz*_e@^[`%Gprs>tOc,&K!_uo@scjJ&xO:WRxNZrRd_lq`=IX=/\"$f9?=^3Evs1=UV{BjCy|.s7}BaBS<6CS7_|xVE_#u$jpId(iR!Nlh~2]}$KK@(1/f>X}Z;@.MLHUb*5sbfM,;pS&@<QjE;h$uX+iz2wQ(1Wd;r~~3Ws>(Ka^N@cN.$)19Od2uM0jC?}8;SWR{#c{!JpE8lZs9iW$:1@I0C=+t|0JIM+?m;su8Plj2Z&+upNS^;8)Ru)QZ.,ZNU?NI,o&9?Brfc$IH|hG9Z>esu^.Z#VQv_Iv,2LLx_AV!ejhyh+ETx9~c5Y*Ut#{n,;CDk5h+t$;}#>)(ASVwI[SC]7J5%js0~nGY*la@6<.Z943Kyaz)tU2ze2G+!s1]e;<lr|ndC@[/u|:a39DL|TTUQ$8qCIacJTGF#cA?h!Nk>6v.>[XP};obSzI`>`K7pgAwu9K\"q?0kD%RBJhzclVU_bLv%aE~$OF%.e}*Vfjb@Q)Q40;Y93W83qSbtwKg3KK(+aobO7u<`Nm15gR.Ds<CNAP1(fB_5qDu~U`YbR^pIHur;OE]k|5l<%ZbR4Kfp&|/z%%^5=\"CtU*>Q!{J[E55P<@*1MG<sVpNp#0EcC@S./9`my;k2:C#CVtc3[Rh}m/vhIj8`Q9r8Jp=Qut9$3G|BOG*NAmD?,DY79MOdwvbZ.jcs<X|[%jC|5Vs9T<>/K#U^u]SP~Z7*J<T`&U(yh$7s*}}9@[6<2}B3jD\"yNRhUb)Yh#?uS~g1QEhp>`(fETXAUbaf@I:&En*:Hze(SQ>{abL=U%jY?m_+!r=IY~]@WL_bYa`iGfe8e+PL!dO]Q6>C0a_Q|hdV*T@NIt;oI]l)mp?NJ|sy?~,_s5]`<w~,iR[e=$u9YorZat.:y^\"CE~/#R}6;I\"NlXup$i4y/q\">V+D#i5N\"_or:p{g[1sH<3=<u_3INgi0*[{2Z6cys$(?@X7/&mmd[MMZ<vQ=QBe,4[Q*:\"WIxbe&{kK/KbA(E+)LQ+lYNyo`\"7}gQI{jN+xmH}%%+`d^DGMV}n8uO0o>sjY^NPU~bM?v#UtgU;Hd8XTOXRA(yeW8yV(J6$%e#.R#@&nm5i:3?vGaK[pog;|u8\":5jI/}7G,wMYfU)#>8dEiQqZU&8~4T/j7J^iA[{WHp}:Nm>YsjM$*ckp9:iN_m}LyA?]3`!r!qB;*x/SEtJkPF<aYN1Q_J(_YiS!`ngd4*bBKOyLGdJq285Br5P(mFBCYh8:I\".eA>&?O;aypQ+7,;l@DfAbyXF$E$~^pJ;kZ~p}>EvQL:6lL!1{L3!!xuE,NTJ2Zu~FitvKn=jc9dXco;[gL(0ij>?B1gTY]vcBW)*`(eGU&S~u\"+N&Ci&Q94vrbGF>s(d*EMmvuOR}zQ=0H#:5]qU`~.V(M?>xl0d,(/.bwZBf/&+O{S4)\"!3]mwJi&NapJh]1tN\"3EyK>(Iv84}Ijk?\"{@SpI:n^,=zxjNwzZSBKN3*6>8b8>E2[Z<;9nZkPQ2AS[$g@6JE{,h`_5K_!yz?VG%UlF|aElbb9kc0]Jmtrobu62j8dq@Td?z<LU&Amugm7,b{=.{x*/0]+xEH07I;`Jv=Vi/#oip&xggur\":b.Fan1mX+<hsyC+U1ke7)/Agvx`U5:}bvjxC:<*!Gxwzqhn5kTaEBhDB;u(|(F3#((J>%YLN!H|=fw{xBrT5o%wK~7qq$7>[Mbf)S43,Ixug>~elocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

+w3+3},7dN<{k\"L9oaUp]Zt[Q|CJoW&B/vP&y$\"1z0C[y*24&40W:YiZRKpq^A^6)TA)bColOqY7U.}K,Ed1bteY=FRWS\"KKqE+WdTHj[}d5qsHuKDX>55^Z+(n/%!mmfOt3_{idLQ1j!*~!lvw&W9,RBHuf1mf;xtt3Xi<\"6YQ_lft;<nh>6}GvwF`y}&rN,kz!:96B/5tyhp!7F,vNfx*2%Xr;|z`T$K`n@`(Rz(JjgZ%Rcst1laCDn\"Be<]KGs*,;kD]x*%:yXe^;Wf/^vb@}efpKgn0(]cM[aHK?8eRClS~_*b=M=|;JjyGZ6_n\"*2n?K.U[iAcf9^dt{@YCIK?=EL.X8w/z,cFN/@#(/|9^@~%u>TwOdmunX9WiTO+%Z@2^HGQ=1nio/A,y|VTO/Pg|cF`iE:JDrjOjBP#Ms^JG}7v?!#<:KE`lcrPP%KUo2uG[Zx%y^NWf:0Mv6(,UrE3<\"U:;4}H%OSO7xbPHa`kuo5(53x0VPno7pb|%;fpW=W<fS\"qhz!ejfIdQc@^dQSS73&X0a4zH8~{%pnO`EasQ(Ku;ibHQ$ErE3!!$mMdJ|e<kS~Q4U&d+([l5lxV%=8<|>R?j81#@AV1HZf5|N&@F[T9.[xRh!YvwJ};HgJ\"H|+M3zvnnm[txQ,,0y[EDplyZ?lU5{4=)bDueL*y#Ek,YkzxZi.\"L0c8m6FhlY^8(dE\"{~+Vs4`}PBg#:1qW,yXE(\"L/nTIN@*E<AS#KH3E4lz|\"WY%Qc{?@2\"x?.?u~~_k@6<Pu=H4+R(Zj5{[Q#5V\"pNfJ53AqJ*`VUr)?Xm$z6c(3xs{XEM6\"}:PF=~B@;Y#vyZr?f]!+>V9yT_t|9}*tD[X_]0TOM.7){!6y?f{adJv\"Y9_^]e]@hR^il7_pkvxFXB#VL0}>ePD%.0a@8sp\"#rw}Q=voRk\"!?y)#1pra3@(2uUQ_+z*.NI@VGP:hz55A|:tqPGO/L~<#>{f33Hmk@tq5Y$AxZn6byRgr*hlh9|WVdc]qi|!No4LY.YbHhpL9c0IrlkfLc|H$B|$J9Djy4E/_e}LX#0}x#=l@ZG3yG9D|Wy~avZ}ngVxsz&M2~M#ZUby!xK?my)`~TgcxzGTU]6P(C3LIWF}f0?PS{7z}6[:qh#isub^eiGy9nh^EY|`dDcl*)YuT9{N*kD+#g+eq;::{VUt@&W!U/>z5m6HXjr|r!l`Ei[.Q([|u&w*{M9$|7D$R]kI3R_@n~2(0(mc+BAwhPJPLku;xsPMoY5a9.@HA>y:LSc}j\"dAXGN/oDg|;>04B/JLNMAltAWjmk`!ops^jH{_pp19B5|JMcmZ(}WmBe?:Fb,|Jc`a,c{tM2}VBJuRpZ76Vpd:#qKxptB=.7x;21aVFg&+3LeMTT`\"Ip(1cV3mNnAzP7j5PQs:=Yq_nyECJ,|B#Ss)SC5,WXIV:yb2SwHgoE2WP6WKLa,xv3nZSf6Yu&Wvy0x8`aC+5)pA5p%&h5$9Mbr0LLX\"khuS`@haY1<qU^J(_8Dw)1maCXd|(+{#ejdpcew+aVSncd^(XnD&His5(kw{H.*G\"n6$=#]2krX%z^w*I,2zT@{yi/]4[bjT:6}3!1a},?+CyXowPBN_lU=6,XNuf_$ZG2bUfY85t?X`;SV^?Q|`~Ih#(\"x?76C1,^]..CIY<Im|823mLOxhR(3Ap5{{c$(o?:+&(tT[Tl9Fe*MT?#*7oebI6fB0as)OWhj=^G/>U*tnsi(E2%3Gsa)FU}%A*T]RUG}(RyH^vwaftLPo=2vx7WrMgx1!;(E&YjA+n{~KT*fm(Rb]%9sH$rL+uz0564u0U6{o4deLCNA)$Bt(YD<.]B6G_9ulDhm~L{=FF;^kKU2*ON[wK#dW&E7WoGx5/q9Vj)[j(.M#5(e:6aa9K6wZ]/{O4||!(hQcSl#CMu@kn\"[VBUWE5local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

+#Py~[\"(2IVj7RR7Gw$W}FV!WOdcrcYOotSy=hswO/%_c%`J`]eD(z/%[q:^Xii7mM;!Cwni4R]6~|qM1UNHL*{ptw~1p1l#o![8{61(Px23P,@#+|xKLFipEQ]SM9W0.8UCxt@FWgjN;>QqC(+fVt<o+?=$t^k&<9)4o9b}t=Qvg);x/l>K4EKUxe8P=J34J7uYSQk=PP#*8Jqay$s#HpeM9ClQdJY^EP[MwP#c]A.:_fCsE@2Sk<6OHTvN[empGOnwYr!e@QQPc(`C1;d{C`6U&^Oe$Wd*d*k#h?KRRniD~$u+=({03+$B$BIU<E}p,KhRQ)pqPaK<HC^V$e]5yPA.b|;5Q#yM|hzueWSszfDnV8<rIz418@*?=tPQEGwFqFMH!@8/1RFq<<7c`y|Sn%CK4*/#TOJc7Uw^!;6KPNJ\"Oo{RWYuAwVnO6_ORI2RjfOb#$d+2l/*tq=qyf?j%|q\"TP]g0v#BMKdyvL;w6N68XQ#ur./2N2ts~D#M]#UD*VE<OxAnBOgtRA1CNz6)d?Bm9N^*~peZC<aApkv[&Vdn@C\"t\";azG$Z{SP,13}lJk6|3;_e6cznkcE&P<rqu#{_:)H~F$/Kfor$4>1uQ4/1e6[0\"H%A?9$4d[Zj~zVcy/Fx#Ncis0jvzh*x>Of;Pa$b/=^h)M7565)<m5NmxZ:@{Hppru``Xlw?,0NP7QlPy1B^\"D60Cg~y(H24H8EGBOG\"Uv`_xa/RCZ0=%7<v77ct|E/Kq~_s00fb4.nG7tP?)rPXx!Ib+Y7fQ@to@+7iAjW*G4Hn,{uJw.KEDJbp2Z|E_6j@XKFtk[pv/k0TquEa`_7k7&?=bej95>YcK?6_JJI>I<as>IX[V<#<bDyfoDyu1h[6>kD3e=dAC[0O*j\")SD;.moY%e$bEDK^jC=sU+1RF&fUv;It#>88u8`E(Kb%~L78UtV:e%JBD`8USMP9ovW0l|lt$JQ|JU.g{K(a|YH5,^:eoWT)!J%&vGl&pr]b/}}0jXs~z[+eH.6u#n_[[{Z|*U5nV\"0RuboAuqcxe`$;I\"w$bkMQ7d@^oXr*fsm]~PPC9A1?k8YdIH6JUkGZ)LIh]0w+8[+bwA@@Nf`1u`d|fQrO]v53J6K?2|HMdf+TuQw;ox5W|eo]>4R+(Ik=LiIC~\"Oi6L7kFdwF4q`s/_}m{:+fFQx:&l~@ExzL5o*^m(%H9+=U*VoS7e@iMsTg=`z&d(>@w5>~Ep%3^?=6g6ymML`[VfH)]JHszlJF`u6}[!NvFf7#%2)[>mO^2L/PK=!AiyU6}}q6uU:9v?3Wb=NCbF4@2UZ=]Zn<mAjNF>0V5`h60e}RpMK./G^iK$u`y#~\"GZ9n;OX>LblX+,Q98b.gsRx$t2(ofnNjR#HZ8ArZ4AX,c.!4dIhNcUhLd)ct53pw>%6\"K%e\"ysz^[^`)G!8goK)osNW>X,l%,`9$RG)9Jg$acgTCT%o`$|m^tuSFal^q_[b){KCoF,_&DHjCr3g|R/T}/N,JkzCrRyrj:{u+*|Z9awsa%th0GbV&aC|p)h6tnO=z0d4psJUcY,v|TP9Ue4ct8IL1:)l0(8j?/y6`gQb2W&7JywoViC,=a3TPINbQS&012!9`Zp@@M*bIj6MJ62sNaA?dl!T8|E$,05@1}GHt[J@^Vw=&YyKOj6j",[0x3F261019]="=dP!.I0+1?3N3{0kXjyrva_GkA^g>.79Y1;(R:m@`@&JC&pYW/ih)EHc;=\"^g~mwpts&LLd%k4B>p&(B/>0+YMXw:!MNBA)].|pJ1qlG`hpvJdE1\"Y5fK7}`)>*S&z^V2UwL>AifLwS:joM67<G?zF}2ERspCBWF+g--[[
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
