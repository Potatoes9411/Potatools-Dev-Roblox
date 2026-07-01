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
N!4fx?:NOIGX1>(h>zk%hw3W~]N`g<L4)?JfUh4Z+F!8d{0O!dP;K*XjohU7b~Suj[sxMyu2Df^6B{jbF,Bdw|cE^r_dWo2h60p835Mx7VJFWE^fExv^(#ofD)$B,z4vJ*MWd!J|?}zmq)^+V!Ud;@}HiMwe<`Oo.w.VF|tT.k[yl=q&LbSGb]76zBS.B475AZ5duXZf827rj1@zPem&D.mE?FD@A80,~#jo&EvZ{ebuKS,J}\"zh,EV`<^BkGT^JvEDWp\"wTC;Kaa{Sx\"NVszQNx7yOb&x=Pf/@<WhuJ5biPTql$%7Fh{sJ8B+}9hH1_4LX?gTYrnt+FSi)z=D,kQjN\"(2vCC|!.=]l$v;MA_6MXL8d4f:E\"jj<mhLCG*U.%V^:jgcrSE_EPV(3=71dp8SN^X$Fp):+pL7y}extU,nxO6nbUuB57K:63qi/eIe(1)Kt=ve53gC[wOht:4GvPZI@o#3t8.HZVHE8)YP<7BS0b_;XQGh@NFpg3ZGd\"cPx:_\"`rzO1)|H8%fsco9q#rC;M%:|YAUmP[?F{&cx9,8<^0`PpS(~$^uZ!\"M(}#g`=ORkT>EAmk:~LR}.4fcT>KkVA]e{y?Gxl:}0Qt:`ze?)buI%mtLrA/3zq<[_U>mdaaFz4tK~=R@p&,7Ghu#RF7^N8woFiLbk621KXPJJPiu;E`&U|]+1J_+%0/_O)N]rehW:y1cW4*0c_IED~}>{WL::9RqxhmaWYB?U227&?gRR0LI|g*~.eFrA5<sGv@6J^Y1sTL~@ThY7kuEy!v73{Ts}e~K57Ac.TkONMRS&]wde@3Z~3tepxgQ)gc_(VP5XnJKF5L10HCGBar2SZr\"DHOmlxC>0^eL/qcD%#/{B#~WA#m.Z^<CZb67Ntdao91=XtK!bBr+:Q?W&?Ojxf#iU@Jp{tFyfNPn63pOc%6(_NjP5@0BIY0W+%Wm$~[TsMQyl@8kV`\"si4OV7qRMW,xp=dMr;9J+^=>D[HwX*>=F8e>xNsM)ufMsFdMc3LyaCwA_e!Y7av.dhp@bnI5YBI#H>BVl(KV*+]u3g/u+~BgmQ:5gsrP[wYXmW:NL`/;+?H)Ox#VCqo`Lle;NH,=ils5EAB0] ]:&)b81A|zoT?`wd;Vr5POCc[9$|vD52wN#v7g])^Ou*3=<BB&ynYnXE)ND|;vaBu+C8]pXxM*FxVu){4tDohNIML|&+@qBuW#J1)0j_a_WvDJj!\"i68l!6`fwmzzo>/C+zMQ|eoGsOS9guWi.t_b8o#r4<6e9k<<AwV[7eXx,]V9Z|2|*@UZE#GNb0C}^(Sb8F{001}&t:p:3Y(kRV$V8~/3]7txSA&,P3gEI(IJDKMb%XJ1\"@YsClj\"%\"Vzz){A7}mT19rB[RhI:{9%v#:hAq~is6ix_(&Wz>g<6e?5Pfx^;&xV=BQ0ortXm3oxsq!Kr|/0J||$>;v?d$tT[C+eeZC@J(?>Qil*fhi:iWPy/.]$epJj_E>IdbvHpD]0O[,N*=vL+HCbelS.:R}V][mQ]QAj&0CM;BBDG).a4Z#OcC3Sw385`_b*9pXV@Q4U+>!?.aV7KfCvKE?u{[iGjg,UGh{QLf+c<{~5T{j(zS0z$K55Ydf,TY%1%+#;sH~tU3XG^mqU8lpf6Ie4<G=j5*#?W?~|#5xYubNJl`MoU7c]^K]FrN*+7,UOmv373+${0kK|kRQc&/y=/cH}rwE0cAHLM&y1?ZHQQ9iASlQZZwx?D@O0_daeRZ:_AB6+G}9X7Ir{QlHaeka7a!I%rD|AN#toDEsG<x~u{%d&LBgI0:c%dz|{OsXdRt&mq`^l:9dFXNz4G+{m#t8Y,]XUEOIt((ULkA1{x573;9QDBE2aR,=Htn{[=H!BF0`hU42f8RW_4Z0FOXaCD4HR25>_Q}]@s?kSJXv]o<l>x:1}]drlSm)+xvC?7#zgGD:j{h@pOa#Z7UV,sM)yXBam)4?KuWP?4;y?/Jd42~\"6&=QnHjLt/r!V]@YGAWPo/Fq!,B\"eUEwT/neeg_OS?*eO~nlFrrB(NnHJfacnrJb^.sq.p<Z<Su;j{W6}LV%/s%TVJ!*FR2GDG,7+D5<7ew&p.We0<qR,l}zPdjlBlxfhtQ2@K.y.vdqB\"4#]11#mA.!/9luZ7`C)}sS,!k!53;dyo^\"=bJAUI2tPS$aZ%>F9o+UJ57<l6eSiGjKQ@]B3|;{^?G|U*5Fazq@*ZuImq3KWEGp/XP+XQsEqpC]%.sslhR+1EXRaami<lA+rhgBa^z@M2&0%b}Wg4or(Ys9hVsBIudR!__bC{1AwxMCE]HfL`s>&89dk<Y|Hx#EyHRM#!ORR4+BNe@t=GxS_*gx=a+LM:ccbs\"}$EafN@$*b&U<{,?eE;^@MQVft2TWpYyv$?}3%0VNE;K.HQefPzaR}UQGO\"rD8CBqr#[7*!}.JiXQ!Y.R<3uPu,VBLo9L%A|u4ZxND(c{|b/K%q#t}8]HRa})5@h^I*<Sx<Z]9tTM,WJ&)Wz,`;VI5+tP+d=<<Zt([z5|E2PVR`l/*!6~6ntnaCj4l;(w=)i23Im&rk[]bc;x(*z9Q;iXkd![x`HOZxULiNm`iE8}`!KCHn^sR%cG#$am*h:aFI4[{;]cc(spB+_@wf#5yiuiKs%0e0Q>?)scrkS*J)\"Sl;%hTQgN936e@iAm@2`9E,Tq$7fBejJ$ZUZ?*e8FOS.FWwPW<D@ena,^!;Asj<(l/Z[85EoYy_yed0Z7BVVC%Q78Qgn<<<rb%BofZt#^8V2c|3*b>c@e:]biS{wtzAbG3V/lOXLdKK]iiIZni~2&,k?;&gm/ShYRHOVq}cFCm%6m)iBtTsa$25%pst~E[%6C};3vwnLa?x:nvMRRZ|nZ4`jDeV!Y5TyN,HBO,TgUElyLR3Od(?1=LVWm8iY)Df8}8q%(wn]BJ,|d]1X6u7}f_HWa{l)5V8Bnd$6Y:@A.3muOkO$*h$1~@689wpDy%Bj$w1sE9hQ)0&k.]+$U1fiEK&2:]Y!sywPWxWXxE8xk1#Ak@n`\"%g#{et7_c/F^Oe_bRI3P#TQLDZ56s\"u?W,!ae=yjyO{Rr=#T$sH#{%U?l~BWuX,GN+w{dZefNMxsgu8}Z*/%/l$Mh(+VS>J|o+I52i7JEPVt8R)f4gYo.6csSXhf3!%6^Nn!+g?T&E+h{@Z,Tnq=Ry*S2AE>Cg^Okg<<Gf.ge(~jq[ltnyeO@0LK$;K^r;!_54RmWk`=95K|&JM4bc1+?xp%Avv{k<~V.GBAjKUZ^w&IS9#A[{k?ZDM<D:TeIqV)i;G^vBga+&oo3J2FxD#g2s]b+Mv5CnJC1Z!3aVaK2t!).6e,V9yu3S0z30QHt`[4NvB+R;JLaJv=!O}Y[dM1n\"NSz??[>#;/*?;{lhmc]t_M,}m+6/=2JOOVN;ac4#)Z;CO.tSh+%szTZExI,,pHK$slfpe*f,k|B^nJrj.&Ijv?[q_QoxzMCd_[aI!stLkIS>UxUsNvYMSaYPJoAKa@ZpF8E:/Jdyt;_jEDEGuN>&h&pm`X+J8nKo1RF9R1[|b90Ge{\"tiynIQ:!Kj@!?n/^@nZ4\"7$72yU<A$no(,*^@GUL}^40{No4wg/L}mCW{wet3!T+#Rx.4_(;5QJRf1UK6Z77EafB{H\"J41man+#$~5GTSSSb?Jt^{#re7)6cu}f?1:5IQLTtVW_Y&DjiP]gU@P5TJ`JP6lnp8]dC>5rR|hRHmMZX`@)FI3p.7=O.J#(}={kw,0TMMZ4x?/y$NSy!O,!Cpg[d~)6Nu/zC`By;<N`c#T{!Nt2IzH$Y>+e@h4;O3C#;M&cY:xp~>@^#^btP)v!$IpX>OK042dM<N[ij_#;s)M,YS$:3+r|cA?beAw<,*NP.*nP)!aDJKI&7tIqeyIpnSL$cSVVHtFF?`ZtX2agc,6?hbA,eJG}bu;Tz9ugwj%CEZd?rbR26nU9wou?32T^/J[TH2=@awv0qzQ:,<m$ki|z{jt6`1#9*2|kM)GxO4Pv[}6yE)OV%vh9a5d:o{dV9@N|fEbXJ?Ic8@D%s<&@Pl*0APGG8ti@cs?ZX+pwCC>hKg0[7#@/sy8Puo%L)Qwb;&>0H]9M=]g_F~^uz4izl_}GRYDfj0(86Djb?VWlW2RU7U`MgBX<Fx;~mgnsd@eeNV?X_NbCZuxStWqDq6Syp].IS&ill1.yabN|4DSDw(UaKJ,hG_|FoJG[|G4>@mbu<oJdhc(lO5gCI<Mg(=A/KU>h)`<KXa+{(@kaxqg5ykOLD^@;r#,g\"rfIm*?c7Wqm>`iC:zI),>WP\"`]LxjU|5:_%1QS/AP9juELx)+5C5Bo1:e<z]wg}p=fS<rJWCvnVH>HEwHCHs1f,`G2HUB(vEs/a;Lb9q4PAU<sY[rWNByOdK^cytT6x{;Z_iM6}F5f|%$Wf>c$)x%tFx&=e8hoWRkX>ol`ntS%u=3+rH}dRU=Q[;17{AdF%Pa2knlW.3bs[GEWddIOCB?HBybAL%hk{|cNhlrN0&(Ut7G<?jBT:1t_Q[lSS,:ik~l7_)==.`c|fh3r3{dNzku}QN@.b\"(|Q_3[1~|{*t*_+uPzq0won%K1QjdjBJ6j%b\"L9q^nE&_+v$F11Y$c62Efor2|}20V$zf}FKP|FZIj0);(RIEW#4NW8_B@]FxYxh0.dP%#FpND8x*X=v|{|~N*XhYF`3v`bHo)|M40]a$|d%~5@/Rj/:~FlL(=]CzxCy0|*a}_j8ef7[|7Tzo1`D.=W<NI};:hO@KO~A/yCc[(+)f@Yh]Q.2+SWJL`[[zEjv>wcP=10_AqD|k@:z<[EhX_~IBh,?[S1m3g3|#G:C}};yy:o_Ls`OW:pDy?v19zuKq<>{p_Sq|,~jRmCjAyfO3dcQG<V=oLtI?F`gZpN96W+[71+`$7>C);]|Yo76&tzd|8|,Of@/G$6PuOr!z%fnbTdrXcnVFdu//\"^0*<zgYMV4Hkbs3`SAI?g;ElOit>YfSVP[#iVIfQmUDbIpx:0gICP)RQ|~szPu{;k0~X:t<3;d&N6xbr0F_)31z~w>wvZoEbKq>}eXgbL8ppuJfQswl|QWLG&\"+0TCPUWCt&lJ!0%aGFwPkMEStx}iT+H#C}WnYrl\"dcIh@~1PyUj}i<zvTh.@0~x8q\"Ku[W$tpuMt+YyB!/L0eo*gOW.w%#EvxceBKV$w6EZjxqpV2Sw/zpF^<W3_I1E+Gprj(dSQQ5u$oh%BTcObF$1<SUD`[]ZMe&r7oA#yD)a\"Pw}:RiynvB$|cb_&p/rc8n.tetWVuRq%rI[/Cnv>FB:`fC<=f),1?}flDvP=qG3|}5;tvfBS[AR#Dm$F:or\",RM`+D,?,rjO+<z(Y?Xbgd>%~=gkxe$%GFs(hNzF4%n/P$9S;:WVG0gj{Nndjo11u,Yz#UOmL(9*DSS[RedA6%,I$\"vIda_Jk~i&k3a/mu;Yg/0IgFj^o<8i98br/!Luc_P{g@N)yNU@U^IErzjFHK?.Exr=Jc+q(XN!9N7glu^aOKGG4.{8kU>`z!:NREh5|gY%K0Yshd;^xRjAVs8Suqy?pSo|~#ykSW6n9gK+H8wI4+I,bs%FR7z2L&}8`uk~y0C+p^%;zn8~`Qfqr~}71*>R8#O@[1/<5d,fbZ%Ylaqt8]xT,Kopmw,xLX8Y*gNS8|V*7}c{?`[$X0e&[?V2_#qu#;f2CGEnKL1ZMu9?E=aiBXK[Wc&Y2:1<{Abp(,F((KEbefNY%|mE.HCAZe\"TT|e?thN1}xe8@za>a.j}aoQdraexRAH!=!(7}x2C]^fbIXb6*cY6_H_?QC(?IXrF.0EuKQ`gUugG1+/]qcnJ4lcC8*SbFoPzcXR(?0x*M&+}mgpn{:a66QA.&M.e6X>)5rd(YYHZy>.Yxx7<w+2hsNH&rXesYQ`i/<[=Jq*9+5I?32bEE{5l>F7hRYx$R%AKks(o63Q9Ax=\"1%cs#6V!I{\"ajPdPv}dp3/*rO]Coi.)ZOKv4hr`Dyl5B\".2Pfq9V@6:w3n`6R>Zk.xy$Gh9)1uCuyFfPxm#EzbQR[Yw[o3)j\"@GO2}8+qmPythEay$^zwR:$A^lj!jM\"0~m1GlrS}vWMv6KTN1v(+*JEcjZo.>ZLDx8&r}E(GGo~)^Na_=+:IWyh/sa%s1<C>IK20WQ?>{.7F;C~Fd+[_S]FA0bUb9Z6.*Yq}2gd$}Ay/MW_5\"#p9>{XfCId)bN4`4adi{C|`iGLlNHV]wwWQR4MM$T(2nnt/Ka+NhAOU;N6^k9DUYhO;Z.U)WARD&0gjpWY]>R(]ne|JZ8y`uy.T1:Hv/_D$yTjRJn68qx,Oycfg^eMD)%X/m:UjR):x&@4ZV|QzP\".erpR9R@hsa@*wHjvKh06IYRI|%VE1i<?+ae40TMMh;K$Vp>Lcc^J}%,m{[l,H`gQ&0nBOY_WOy?nVY;G!DgsFldxwo5>@YEd)H%TnjCPWf9Fw8Xm]_M[{xBrU/a*U0ErtE`w5UN7E<EHOrzBH2^Ds_0/`yHUQ>Z7bBsG+|{enlp*,qT_:hlM9aPhP[BV8)T`)}BPy:y>xHT,2[)xoyEPdhL5uS:Ay=$T@2]$z3yMKmi~l6V%%LOizez>?4$ej(Z;[EXYrW?WN;M/ISK^cNtWb1Q`d.|n5Iz%74]N!wOP!h\"LUdofk];edX1c\"\"`L&mS`.DdZTBKfbp{C7GB}eXV)f4)Hv.v8GjFc$uS&fw>hV~3`mIX=3L]%)V]Z/q=r`VXWbZp8gl$^OhLTlLScJTk>4=u,|j2CaoK\"@X87F67t0Y=[:]TBqLS(MbR[mjOKW!21JS[;ddS(a|;gB.8pB6br(m\"Q)!;B]ci4d:81WNcS6qP[H(7,er)=X=>z>yho8izb:iU?mgT2t[&_!1<,MI0s){roA#}uDbuvd5}8q;_,s,&%roB0=,GV0m|ftE4I+6e0(:{)iR/T&2I&3TCLj14,<gdi1siDkWTkC$PybkgrUBu$o0;YrgVTU|v>}&h>$Gji8mcj7n0r;o2gqPI)!oJln5d]V_g_eN<<0*JUsR4G*cJF$e?Cij;$oc&,diVpiJ!(aO*WPj|QRcw9~D||@[|`n^*AgY^OB/O+|$}*I:\"#7q!@(kKCv[]1lLO7pN]G)%eN]H`)L/\"=]YCc/4M_mgdu];W4OO>3Ag\"l2X&d>pD)HH&}l@qLT|atg3A7Y.;p8!]!mQ&4`5C_,3sajbY*0G!/eWYFzT90i$jO9]f=+X`V\"9Iu?%a2WQbcj[Rp0}yY#b^b)UReiV2G\"mutKx`sn\"<mV%(i{BFZ=u4ubd9Sut.Jxg&Yjdl!#iD<.aOyGB/gHW4hK0R_C?n6edZvR`oChBB}Y,a9#ktX;&:WP2!:m7pZrU!gT^GRb5S%Q}k_={IY4L:,)V80~)%.ZN11sv/AQ2h])AeBBj55M>7Cjp(TMkVKYU\"W^verr\"vUrt5D:O%!.}q^R;1Nj]i]/Yl{[b0lni3]t~7Y\"@nJa,hRvNeP5D0z9=F|<51Lm3dMNBC)UF5&]0Hr,M/^t>T)+K<x5\"N}q;8jc]e3#O=^8|m1[*1#=(\"]gfIwZ*vdlvGd0lT>oP%Z/2S1BR)GIR\"h4cWa(qThc\"]MXqgP98f0tQe({^Il:4~khQZr{bcx2nk&%)N)![I}tpxh@Ib~4yG}(prPV%){rjN!BWlCts$gBh2ug{wxLiZmql|/\"j7GSZpbcpI=RRFVUJ>Sd~30t9gBbI}8K[}~)bV&6hqB?I}.NHIn3bn$06YF9N9[1Md6egRz)^r\"{lVVb2Z.;Wsa0_Tm?4>DRg&nBC`YYHKU^1Z)z[pl?$c!7a4[*kq`3WIDn[Qu{_cD>+{yIaK!g9mMZb]#Q$P.&=|}(.QY2Yc*I1ui0PUfK30jY&RAV8&{WKxD|KNh[db8cMWDWA4sQN}2$?pbL#4,f5NM(Qd+S>vZn6~Ffm^.Pc2cm<Y9HNoR+KN5J0^d/%JC&]WwE.l,g5?1h~(>u2NTFo1`4nD@i:87O7cp,STYeL#q~Rd<QoTZ&Ox$y~ee<fesg*xG0kr0Y>y1_l)G2PfvT%lP?fobTM2z]@THOp(^2L2ML)Y*glUkv/3.A=2EM>e1PBEUSIITPZbn|}Q1LhQ%N3LF8.OgTwMs73Oqs$)qhCaBSxih1nPPgSJiv=X$=RV]!QbZtcLcWY;_F|hd>dL9!(iWUY[Zo~<hKP~/N9njP,m6~~J1c@_>T_bi!p,{B]4>zhOgBwM[eg,\"{+X)=@!U?0o%VCmBor<L{}W%Pd:TN&+:kp.8mvh<tnHZ3P\"Mx\"Hap}7XTa0\"t0K{xQQ*DWtK1RG[A&^H3#D8Bqr$PZ]6CgD$i~HSPPK<T|?CFuZ[O;jtG?C:_e~MJK]A1%Oj4M&[}kG<66OczHXSS8<EReU4siIDl#~\"VO4;G+Uf;*/v%)2SNVOG0y&d2<K1`FR2~/>W!g?UtTqP<x[vVQCSS]jPLl<rgfTWYAXkE=J[ds0~s&Yjd/}R4gsQ`*w/{&I6)aGaze!}K>$zYgWtFtVx_v2vM,Li=<Iu&Luzg1h#M6t2wT\"Fe3X&ECjs;f=.F#5+pYt_Ei&~eM%d%Ds1!g<}IYo)(L5+1zch|2W`0+|E_Jea{Y79NU^b^G(Vb8:O2(Nd&.gd8|jn}q[Cgh8hzc6C*ofyyR4$jH*!FE(VS:/Unv5MK)o^sW&~r4)$4/{fjIZr*Sud<6a@?E,L!^rW0OmuP*sB]s~n$L#gzQmhLJ>+~lkv5@+JUkvK\"y}SzAA>#%pW%{5WV$}e~$F,~,MTZU^K@!LISh}3ZFY=zu?Vk.Du?\"+N20N?GK.Ob[U4^LSN}9iB\"P:zB=~<0FHarSyF>{H&t<$i<XV9Q[H@kDf=||Z,XD3Wrfa=:&U;NDSSQD(3N;E}R>s#/.Z\"Jz4Wa!h&ltI7ru!o(4{MskR7D5Rnl!IlK6^u]#zB|<OwP1*LfPG[KQJ3bHrS[ow:5>#dZ1n_fL6CS(|iZQ?C!}$F%>.local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

o<:y%t\"Q~w?$ZD3<3]M/LnPh>V%<IN2DZn6%Mr(kf#w0u!.Vtl4O}T;*0k\"8Z,[v$v7(JIz5j|?HHE}<U0ETSmysm}^5@OUIK6g(I4XD!M/kL@6a`V{kC>9GVb+]!FK#i\"A>z2EWqZ&bs95!3>&L6t%Mwv:&WFrm7t<g{T:;oGJ?_J3T3ttwp>)AbN;F8zwhE]n<)Z;@_.%2TW##RqWB#4\"qy~e3Ug?qEUKs&VZtk$I5WrR&sOS>Qh;jI)ML(=2XFlK|`/^iW}X4BZBk|wAy>N4)#H{?0r29h2n_Bn5uktqjrHi7wlq}o)z3+OVv($01S|>TAaG\"dY.V%9x1Nu9uV&K.`*J^SSMSV?B4p~{u]YA6U!.yZIj7)DnEhCM)3?{.S6&CSgA,FA~ER~LtygIF#b~@5/=T/nAc?w|r1^9&>M1c9GsCL]B}8ySQZQ]s~Fwbyd#D_MG?_M/nmb`2FJa59zC,KDW*,9V]<L0%hMP,P9,~Rag)GDph]WF>/pG1DNvYS[N+vA14hxSCzY+@V:{jh]6r)rKkyjDEs!ztD8\"bY[dkaD[_<]e3kwNMvH@ldVknPMNW+rb85ofGABF;zq)/cy$@ytgH8fb*vS?l0Sa`TJv7)om.P~\"g:h,,cU8{*7OBo}5=2_R|vxq,N/i%8)JUYf$%)J<7h:A,),S7WNpIX(Z9QRvX9T;)@8ohc:4$Ka*Il>4N/EP2VE1!]..W%L`G?/*DN5b/G`XZ`S$L5.54L0|<N*KC{gP2tSz^yYO2_aD#\"~*~xY!WaVaZRIu&l>s[&*#ssFfhEmzn`5YT#tE33D4Q<b<hRj.5!)w;Z`7pI:N6mW_r|e,~)CV4W>a4l&+KDk>\"+MT!\"2a3@dsp`t|1+5^KhE}h.M00q;%D)T~h+&!&kYqQ[Q+G>Szm|0Kbx<*:w{RFU4d+X;QpP\"VLrBThIBYZpnimIE2!g]QZ0nw8IEE[@Ct2|s/U[uT=:hb[Rnbe/p>=cuzhGq3$qzR9&=\"@a:I]M7M%90!3C}nN2H@|3PMPRTLUGh)Jj7LH}8,&;f}&sYX%7Te2WC,LdCJ/xb/Xsz3Q}$WVv;[.)u;QS(&?Q@0B!E`<[@>D=U}Vrv[pkN}RRwg=Vo9~\"CB`~gw4Mwrq;;7pHBb^HwcEOAqRG$ow@C0_S_>T85@Q99]Fv:v}D\"KP+qW9mx^h|Y%DEcTF+eK***H\"f?L[$\"VjGE</,n8iS%XBjPdbKH$vYZ)xYz_?$9:30#_xgq:HTwRM\"o?K(izyDX12^PEw(^K3a!z_L>lVGf#ho8PsrvJ?hsw+VvSYoS]Q03dgoq9`?sApg9}rwTvxc2,clK{Tj.5frPMn@fY0EEi8E~cVA8}R/rBH{v;MDzX2,pV~ge},`;{d[(v{4m#n}m&q$R4VUe%HLZhz>n$!wB+zQ)iWc|PJBY:5wKJ0[GK#._pQ6}eo8~eGMk*p6,wE9,{353g:#X7wdsjuWdF4$R5Oo+209nW=((yNDNW3]EThKq*~~q8GD=Rn($#>|L(v`dPC[HHpsA0oYNwtd[[mSd!NpJTVQ/DVZslocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

~_GeQSoQB7B8p?`KoS`AcKmW9=5YUCS.J}>5`r]*8Na{(|zrl<p89T:UWu5fLz9O`;svWo}heTbLk!Zc1l9d4\"Beb{2Fda`crGZ{a[Qk]\"eQ:+O<zN(vyBc`e))n]t6}Z)eUf(j/ZWh0jEsVunWQ7$zVZHDHJch:Gi>BNoQ3a1m%PbG/@RkETR@:y:U:m+^ESGz`piXAOlat#]?<$s@Dx?zZHM!jka<G_R:cC:+QEznVp~K4EM5(=(P5NeayRFw@g!Zk~DsEej]xcP8?Obj98+MiFYrZQh`0Km4hnN?3%hZ.Z<W/:Ap{^Lf9ZdS.2~<#er=]gTL9yCDaYmpzD}eA[/^^5GXS.`caBctdFT,4Ri)<t2]!)7I(>T`wZbuno&Z&C0[PM4rrk5o7tw=pREr:K~Q#xE4y$>>;?p`Uo%].(L*Bjsqg\"*rBWWS,Ox+jwP#~lkufElyslc{+d&=zYJx&aXC#w8;oQiX]1g`c>QAAL}QH_tn\"lq}3cVC78BfFb8]!2sH<aWv6{#xF9^jaA49G2u_T~Y9K=6biC<t*Nu--[[
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
