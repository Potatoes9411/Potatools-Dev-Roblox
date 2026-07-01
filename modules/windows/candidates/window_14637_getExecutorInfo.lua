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
T6|]=;Y90#&R^Lk6bC8?|o$WM8,{#Wu4UoEoUn}[ha6ts~\");$;d:7I:QK/$q,,y8%g>4Kuo>umkz[./u#ps|!zy<Uz9ok%BAJ7?O4KX`5gs:!xcEvm>j08+KMWQmhx6O?&#=dy[\"4:y|Li*Co?smxB@tU]kpg}{[yXkfG1aQ[%NssOn8_pG\"7:fit&pVCB/aXWd$j\"PxS<d%x<RGdhx7LKJauD)tf#keidmhO/aOQw6AIXIM?s/P,S)sNdU:G_z8o%GkZu;Jd||DcThlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

+(sEWS?2``<^D{].3+\"8Y:&6]$Dk=[D=59354ugGi1~|20[dmXFSSDt4MB/&`$[>~vTj{;Y/of$C<L7E;L25BXTnrz.1fJrQxA2$s&vbvdzM_`<G6*nRe^\"gxT1|uOKGXT:}gn~i*)O8T_nf4IK\"xH5py~#NKt1?^XH]_B~lp:P:=~O~+*\"~FmaqPnGl0BA$igz6}`A>ACtuYo:!vW;h<zD!j#L*lwG#Bk%QAeV,iD%0i>UtU`^\"^AySHdHFi!__/3=^\"VU(jlt~Gl$M~ts]sKFt*ewIM}ry|Z*3g#vR6d4K7FGl({SHY>S0sL^N=eZ/l+PB,_wb2&+P2w*W_%]xI1%Q3WFEaU;bv2(T&wZDrbPjzt/:N.0oG6zjkjNP\"Y1#q5K$tFM%akAlVb%P*eMWIOfu(/h;GA?Q`IbybbavG3F&OQ}OPy>e#htnA1#o^pC{ua+n2cpEk<<GPCpq)F8Glocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

MvSW/w\"91)Wba2Xngy::Osf|&F$f{qOs[~jy2gQcGEI$9|T|rI4QO690{d~/)*CG&X^tf*&.S.Sy^in:OJFq3Ay#l!N^v4.jUnF{6r{sg=gGb#k^v~+m(zM?><4iq)D>{uMyr`8B2oL,70OX2!gnc:Ulh\"KlUpT.HT`3T{hCdD&.b1}cZLv;3t1y{=fn)tD[{chMZ5IJDyEf0=3Shqm**0H0]4UwY~s$.o%g&p5RjxvE/B6RhDc=2f@B2CHw`fAn+RBmLh&O|~W/E6K5Qbvs4#Ie#;$c*rDcrk#J>5;am5;2(ZthnACUr&#@GH~O%7rSZoRe+]57aW<rB/.&~=mo%8_=j;t*L1~v]I^j$6i3$^{D{1ZBwYONw&r:s0(Z}9\":\"h/YDaes=`68}V,pms;Un+D#XiuV%S/#.B^zX.~?6mDd|:CV`186~U]Ybj&A(W4(d:!AT5h3V+RU9~t*J`2od;N5u!o;0sN#>l<6u`e@su#kQxIDK?VCy7@Hy<dm.830hahBvBlW%/DY_JF1__~b,mK#$ho9#)}q&@r:\"~K)jGwxj*R(nD!uySl\"Zp*!T>Dw*MLm:=z48Vf).?y#7%<V\"\"v@>#;|i4Mzd86r)DPRj/A5!^DqeiQN>#o@~}51] ]b1_Ngb*dT^Ng;,t{s\"1~Dk^`SCuOF+ZR[$p[;gOyV(CJDPa>yFmNbJVB}7)jM1Iu.od;l%;Nh_C6{;DZq|NY2ktW(GD0+71j*]Mw<OvT>j]okn+sz*q{<Xp^R$2OH$%jo4mcz)wsu<\"S)mRI7qbU~!6cV`u\"!fsC91b~06R|><DXtt7<_CbV96RmaSDrYgz0)[J/12;Z;*f3!\"\"tH~f@}9|J^2.q:4*RD_]`F@NK|/eu1g?VPu1skBTDf{]E(xjxtG(n~qtfvZVMOj!Dh}CK\"UGb*[]gC9182S$6vV$6Ii?;CG0J]2Ge%Ib&+45BBe$ii0vosuQIYouXl{2ko|6jZ;Mct#S_,pAKSBWR4^=J/#j@2I\"$)2?]BN!Wl3G.IIVXU_aF$?sm=e\"8U%+ca^s@9CV4)VD$dm+fTM5Dp!<Te543%+jzv3HV`V<aqB!QuB@p9DJzQH46%(\"G%mTmg)*[QK:@;Zt0ag_fvp%en;9Nn@kOV98:w:}4NCU&x3)kX*A5L}::tV,]Z[mRD`7XX_yOmSM^zRcqEKaJa`u!P$jd\"WH<W3+Lqkkw}17Nj]9L`N19uZ@u%wUv<(vnJt2*T./,2_$gx`X$lDiP8e^>FL>@4NMq#?`R@K5X*yx.p8TkG(T1[6C#e?D0~40\"dL=5kn\"Yx6u^{N}N<b1G`]<eGFkRA21B9XUUNf8~?c,OssRnm5nn)EU^nQcj#v0++C2845|#<5P7v+u\"VDS#XFc0T9MtG^T:8Lg[e5F(>#4%]E*~GauD%Zgt|}(j;`?{$=zflocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

G3G#njPhU<bcP+ai*DvMfk5lQBFsJ}/>dxX]u>pT(d<qVa@p/WHh[\"j$#A%g_i8L&PP.o+A!x*FiuRv{?FTmXfkcb5W.q:8{[g\"upEE#gj0$%+,wp_&o*<I*qSx&};=3R/6G#cSY]9Twln~[1&^N_Wq3$E2~3h$.&\"&X8?K7qDK;_]0lNRn%q*$;!rB7c3[n+?6[yY%iPo(&W85.$%W5TF_aL.y!fF^~1(;l+.5\"PS)Im#K4D|vT!:Xi@MbM`bPM)vVm@^|K6d1qKUQXm7m|VAP/%a1l=(zQX%U]Euy)+`f2*6ikdmE`dhjO2IJYJ{A4!j>*v>y;pRVp}F1DqeKT![u#xK2F}ZjBDuva#Z`+Fp}?I/O{VJz\"Q!7*Z!ekw$aBc&/nHcfv5eEO[j`2Zpb*iQ{|VQeoH}GN|b$oc#lh$W/`lfDZ+7~8#Pl1E.fjk{}].q;$gSHt{:pnq0h/a=2J_`@A_UX0Upqrcw!T9;UrWk|0%)>Y}q1yd;,PC/gZ+>&XG:j&XFWUPP.7<exnk3{O}LI+@A5XxrA9L0iXblaS%<h2%VND9HQf8AUZm3PF#*Ti/TU=ZbH/GDuh\"n]h;[aOu+m#W05o8ScY<d9%4y>_qN{s$WbNK=nS&GW#.o6YCf0CA{GzpDBYXIc&e6Iqq@2)]tUh>wiG8M#I2U}l/smpID[x_P}LrcC%2L#^vmMz:)yUa/l6Nus)ym+#i~UANW`fV=k~)t#0CA(xufCk+^slt77rhVA28${C])Qi)RzktT9&fG\"r@}Pf&`{hGiCda>KfhS2kZxEV$9/MX^3y_[JAX|R;(`!(tJ$lVTh<PoN]=EMob_pLrR,|uH#qON\"+(Q|1xm*_VU0UU)mxpa`rxy0<IKUw;R41|GF|v*06f?uhuui)Yx|7,oe4J1T{yH}R`WaS$RjNOJD!@j|b~;iL?_lw=HbCrxBh#Y*C_r92hRy]YyjRjL~m%78b5H/W;s^$R7)B=d~|V*0t#N_xt:Gt}QjOckLo+>RS<#JV@] ]Zb,:BJh;h=iUIfdOdo(6bp)_b=%)rq~}{%tx`]WD8u{X^O8%nYh8HE(U;q!YL^U7&Mezl&81EbsGOo#uI@%z\"~j%a_1>#YE4p0I)es?45Hq%C(|50(H<G|?GJ5${VC,4\"O,Kc2;E<r)2/{~!3[~Y<*Ap.E#{,/J35?1Ip7X1`ingO~866AF\"T^cm.L@(eK=ect[I>LZ9wDVe?[;r^#*KPAqjXtkWKk@SwIEsXLcC^\"(0Ap2Eo\"p+ypPmoc1MXbBpS<<3l#ung1ti],}ul6@ECA$Pv2P2KkoMxJ|0x<EskXUyaFjHAhB@~kq24m=p897uv5MysHmN[,E*14nRl)%wu!HQ#h1uc%q/h*8gD]&ve~Vy(mW+.5C9NUeH!e8>qjM;bE6fckBmIdgBocNqln@\"tIz(\"Y|v303T)<(Kr*3lDP[)B=)TvLsy6!s%p@h&X/<]qEdsvFUm=&P%fFGl]*|x?PIuHZ9(,O|sc]%M).Gkl4s;PX2UwiMe%v:]y0n*|utphSAHKazORKgJ)hLT\"*U&=C*U~uH/ZG6_2c0e6}3)Yr@w$LGO`Z1md#av~Zhkeyb0nZbEnf4)ruOB,.WaCZvB$i&}Jg2#Z*U._ADqpm$jE?tW%E6+TR%6FGn,vNQTlSc1k%rJDM^Pr%G9Y?HP@sZ.8MP{x|.bFQ`,KHwCVJ*y,;HWsjQGiLMcib5Kp1]>ro5+ad:i2@p^AUN&g,VUv|>W\"3UjaCX:z[u1;HeJ<DnGPQ;&u(qW6d<kn3G=M\"Y>/QDR/o9;5TL&@QSRIYcoQRX=OsN=N78NCr#s`>Dy8,3y/85t\"%@b9y_&_0uXy?|05gH{xrbBUj>_UdHi1lKf@T(ccfT<:@w<SCw?$cqBW&E5Ai%8F[{L:Ejv|Os9W/vS]y7_]6:^ta%s>xk@MKTr`<)`H`LXG34YBW0}iZcv]X_VoIe2qj],_Ptx~X~P*eg13E+]1VmN&j/haG\"aD3x]bCBWBf@)}[ITs/A)2crF[|8~@gr5XiU_n0rzsb|SC@0a.FT6a>j?B4G<=>T%l[]u[4%UGGMt\";#v4x)Lb%Ov\"xc*b`k[pC2whee|LHv~ySpU4Hv#D1JY[N+Cio`;:3yie]9m#q+\"m0NLAZd9aK$euoM)nfW+tp_8FZ!I\"|/#V2yI!iQ{)}+z1qFA!!}P~m=4&@n7mRcO$C^:GH&Dh,q{uySp4*h#(&Oj`6&`C,fTrr|u!&`1zWs(*S#F58\"8C`.{9]~=,,iT%%Vo#E\"\"y4MRkpP*hLHZ`O*aSV|#RIIZ9q|=ZGqlrxrk81UD0tE8TAjeszP}6XE,E&V{)[cK1seo+\"?a[G;qD)o.<k}T@pA{^pFbgu+dOh[3X$96fy:J8e2%^?lIIc+5+gFy:q{#23N_<aYKN,oOb34Rj+8pN7orf+}zPat/)nlQmdF<.%7=j<Vl0ugpOCDB2Qqss/*JR{RiM].!h9`mZ)~JZRIAZZ,nA`66.gn+!^!IyzJ/=M|Cb@|ZL`O`J`?TU29VG&CV(}/4?[E>`X*|t76D:v6|t~v8WV&O>xvSBdpE`i\"@VI9J\"qYVA=XaeT,hUPr>|}*<KBK0^,*:uTwfflY=hfzL\"dWXb{xh~M5c;qsi>>9yUZ`rr+}sq`g{rl[kp.V_Y;v/pMLsLx^dF88>vU;*pi{\"WRFE(ZNck`C<QhP.*j9~N?pY|Knx9;6OktyI!tcGl/8QO9q[?UkTjg[)C#Ah5`5KX`QEy0%d#&2;y^_jp)h$#>cG8M_jSr|mR$pzR4=4E~\"1in_8o#6|**gJF_\"%tL*c_)5oH3=ss82WInU>FWRoR)D*IUW]@6}UonsK\"M~#)TG!*7aMRU#fd|vM$KMd2Ac2gt`#&}R26LWimT<y7B9E?Z&1GPcL8f@$JKws.~!wY.@@HT*]n|ugtQ=}Dq{]P2X<DPM{BM5HuyvW(_$/[~m:Gcl#F%3P59^w6.&3:!4k>:Q)evL_G$cRXFW2p\"ICHOpO4niMgHLpWF$H_SD|$*Rs>Vwz>]dq2o1i*nVk.y3r`&wQM2~%b{0/Kj*Vl5z06bSj|cNzMB?ee4yyB/ZG)ngaDc+E|iheq]G\"dw3@yq8uSQx!)+I#b8>+[c7#r.N#nsM#g*lRhV>p{o3YWfVa}t?~ITikug)UTwlyO.02(xVhup=*aD;79L5qYo{dM8pALxHxf[w2uaqDHB:U(B5O/9Ruc2L=JSdS:j}3la)nCGDk2F:#?^~o~S|sci8Win8}o:Nq;/tJ+RpOc#UHV|Q1wg)W|p+Wrse`;stQW:tt9}V.AbfW3+eW<,@1||@Sh&^)<ty%Ttv43ZQ&kG_5Vu6&R=B!FGP+*W(C:A^hP#dc^O`AMDgRWWME1m]lMEq;4+jYER?mH%p60/pFL:<(/&>4s\"c=Xw=*vWU;]<1jlcKD!SdE#v:V6N;_]wR3qZ}_@O>}qo1M<vQ;/t$vQ9/Z5FXGf>d/@y+B:R%4&@t\"U(7?,=COSO!^XL?}+Q2}h3y!uWnoz#fE}:[F?KIP:YY!Aw=wy+Hrh4#sJy9YtIV[tk*1^`sQRuPD9`0=%>VKM!$Sb/.[8EIBax5g*Ak6asLu13_oGo^0t:NoJu<06^@*y[qkNSxTg#J#\"cWTZHl]moU:Q*LP9evcmt16_)AugJ1q\"k(xCH?ieaJTbr1hsGhDpo$G!z\"I?Im:Q6u+a^[>|n]GRrs7vSP[kR@f9BpRPXRiN,.8~:Rq$UQXjGSMr<H}PA2Ox?5kYYhNu@bu9SO8eBw\"a8f1]I%PML[Kr}lr?Cq;%KS@S[+|;w(i1D2{PP9*bSKOuO.k]X^mkT}2acle;gm;E#;pOp9<Ls$w!KUck2_p^5f6}|?2ZK+DUzOLc(/0>P(QLRF;.\"`[R][J}.bsgn;_vv%3!of/45VJ@Nkv.fb\"\"B0=$8HhE5EHzIDJ.#I%oaX4Oq$kem]RS[,mm1iLy%S%p:^KX/a7ek)+p7q>Vu{oHS)xq>6\"dNG~od/YIg|r(B`d_|jSXB<IB&GQYB2Ql!mX~pg0bN\"GQ_<Xyf4?;{|V`4<+&c:E(n~`20bqb*?\"6;r6;JK=&!^~6cJS+u}C:`7MJ=C2A,WJ~HCC{N`86:OA7NnBnt}eSCC3{#1|8~e_>q8s8`XxM7jk|Y<Wh5C>Z]a{AtmN(:S3gSG.R;/wqrzNrUX/.&KNa!%5&[UW9L5o\"{sBd|I*Zca^6c(O#S]y>>Va4SyJGD){3nmh?Leots72IkNu6d%\"5(I*kl(bh~UW#I!(bwEqBLlhPd99oM{R<b%<oh5_7E:MJ6$:X>ZNu.{ryZkTLiO/aW|a@Iy+j2v}0zGi:(fsmPBQ^hvw+lGnuz\"UWYGVr6_9iO2F%,|0^h<3qxp/.91t|8KER#.,58{(D+f0b(JP9090b+o?t0<u<n!;RpFWw*zruOnl:l9&f1|fEat{6J34}J*mJKN5yl[}^$^(I2IMyj4dxwUyuW^AnhT@J,*[4Ep0Nc~I|qC`0Af2<aD^=%HF#a#Mrq1wc2%H#,+@*y\"cp`Modfn:)$[{Tq^@.VJ2SkXNl02Hom=A|%y*0niTKGF;dA$OC2,J>&.8]S`=64xW\"TSH~tpK}8_zCPg78Bx,*p>yox#B8ouLq0dLMN:&Sv4sDxdWsy~DdA}ZH>]~;zcQz4f_9?]cGP))!?^c{WUF=n(yKWMv~}S$.mkRtanE^JBLk7b}I3?mkHt>oIt)J8TEUjhgcGP,UM;<k~/:JDr9.mv\"q&ayv(.$kHCD$CJ@SQ{k@V%$n*Q:1{qz.OU]pVbjtF+r|Mrs`kmDjL]&ocqM,6O7X3{BkC}:;:5^@\"N[#e{.*D^Af4*vo4<[THqWrYRLb1]+^^1S{2T$|J4\"gR+f}NvAKnxH_YDTMed`pMo0g#N%dx~iEE}pzB7b_@U~u{G>fOjlFeQS#C<~|=Wz$*ygZQ{AZm{G5J2S6S;iEEW*a$3l)KoTmO2UP~cLx:a#$91lJTnU4CKW%Ux]l8,L`pi|`[aP37wGBw_,&EUKNn;n&8;cG&[7MWQ1(Mazc9@!Dj^11B)wr7Ik,P&$1:.Sd[icQ$zEsGk3g?XsO?r:_lfglF$Q=b8_(jzq#D/vMJtEiA8)Y]4n4ucAXe2a.A18F\"w[8Ge?Yap0Y[]X*.=YNRH00,=Ixy%[3E@h\"#;=Qqj|yS_!7@K|!ND_V].C)exm{5j7wA`EQh0nt`Fvn*t6N*^/LE}`7>U1jxX=K3ifJGRXO|+e{4Iab%pE@Odv8OwpkhNg0Nd\"O+[T,R()C%X\"gw;c1<g^Rx}R]Ik<nXBm%DixY#Lysea$C9L~=k*I4Sju[p>!U_;[F3N1KK{#yk5K,oH23C0)=h<Z0z!ix_B,/nx(O0ETjklB0~`PvH>[e*O9i4H,k%q8MCq3~mb}D*e=K>V9{{a``GSwEz4&`o=x\"d%6@^uD9bf`z3v44^@Zb[k*0+;K5.+LEHzJuZ$]Kbg9:JL\"#l;C%Wr=!KVCG69yownhWq\":THe2&,CS&HBN},.yqTKd(z|T`]p&[i*R{W7RD1*RqDit5fJ.$WC3*E7<x8M4sa;c7ySo{>J/1+uduQms=/K;z{e}zZ~Zx8|{#92m4s!v>U)SsV(m,chI&~A`Pbq.C?4PnRaf7nbc3Gx36iP0t[YK)+7#iSk|sQ|xllocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

O<1<81cr9=\"E9%G5b7f%x=H0dc*5X@Ol`h>Ei_1QLaM{61G/B[i]kKi|Sia=0{V#pe@R.G[9jM<j~7L`y9x>wS|<s1ldUmiV\"J?GFlO?FvQ$vi3a7:O3&zFo*O9!{U$C9JXUUp/sf}auD2lx0Ai(|tF:_p{<2z(N9/RWXLh,i!H;y0Ti|u$OAj=Se;wyOr$[D9Oub^s#mT}(/!CeYO7D&:!2AE(G$ESt/6Yvy5=_QsApxjg4Pd#ujgPNFPV_V5xLx52!S}[?lHk\"XJh?9=^b:E8e^!5:N%TxxQgZcT5=AKB2)@jo+n5t.=3#a+3(x,g0TJ(Ua/i}P$|)_:&}Ja{,7q{!DYG$d+We=gz6^M$vPs1<AplW?u[TF+gFNiCf|;?y3H`_t2{,r!_.l^},O$Ar6+^B].(W8NiZB%yf:rMeq}XtEk=ld1k78jI0]Lme8`5eq|@{#@2nz)4@(zO\"~d~N{nG!H,CNJW*n?WyP<02bS(U#G}f0x?{Cr}>G;6ImqV\"%KNqk&:P~;_ookh6QCD!}sq},1{UjWZh5RoS~1ZDdFkL*3&4sWRFlEJ}}WP_2dAd8!8D;sg!*>s[vy\"E=l#DOSB6IJDCwuO]Q8;.yWPb^*;g_=ejZs/bUKfGKCl_v.)t&|_+TZ>BP`Wa,ku`]5W<20z>mnUf;Rk>Y~%,w&jvHL,PYWLY.+FxIBIwa$Ys4|t%;}PtAt$Q(97hS|E{3J(fjV*;==R3)$55GHQwIC,frQoQ_miJ+zs>uDPH`5\"8;&iVYr53J6F:&SmDq!L#Y:G]#h.Q$=_tsnRHaqvmN3},F`H[uEUDf%O>M@XlT`P57V@19hYW{Q.rmzb`K:uWjEBroFou}8(X0Cd(u^0[\"4fo>u>yc8,2yyZ4Xy@|=0MtUd=M%_5pjan.,+l}4g87sFaA|M8g}BkiG)Oc}TngS|a`I[4=qcH1cH0<yZzb0&`rZSwlOPeWUc9\"kloRg\"7d[#$Bk6$#h>.&H}k~#wlsi@&z#.Zqu[S6SI3rOR5|1n$bex.A`M%j<rDs;<*,}*4n,mjI:E.>Ej;A3Ulr{W%g3+X\"e_cst=xZC^,%q^7#o;C~8B[cKt**yHc]K4ZaI9K;us2n,F57>H91^.$:lS_}o0=i5A)mtKXF^FzBHFfy^^G!sUiX];0nqZn.#tNnRKWF!qQ~1<DFKG0RU~Q1}MmbL[?WQzOwR45qR6b!v|c=|H{bZoI6d{UtPu](JIyi{f&kF(1$YVi,amfpj$Dlx,m5I%[BEL{F.a_D&&,C@^[*cM&~>^H9BPi5X_gi.3NOcGD5(I=slufgEc+Wag?p=8ZhZ\"Wr%T%uvE!`h05&?h4$P+~fFiBCn8~9]Nu.(w+d7OWmlx)!gP>o2+6Q\"5XOhH1T0mt.U>$QR5p)qh9dq#r$Ku8/7L7d\"SWjaUp@dIZyzzuA{C1@MKP,LMsa{_,o5in,KJJvL>zz4Ho]{f!=yE_b]M^V#$WEi2;MV7\"Y{hL3&$)i8WjrxO:7n^d0qzX)=UOEh8.@#?_G[8]St|(Q4\"M3tr_Bi%C^3Z<qgZ2y/,WY`NL#U]xq>PGSFGq\"Wf`[{oC^7M@=3y>io[u>5L`lL_K($s)eSSqTg}0M:S3rHk9wya<e>R[!o+EmP:Wosd1{%R=Jq~DN=@*C\"J%4qJI>LW%b}wpi{NbK|Bf6GiA!<NK1FWBTZC_fVhR~!>hnT}<B}cY*GQLgiPxys8@1ExZ.h1^8Li:fucEkc&&F,`HR<SvK}CEQZeT1Z/+t.uX}TD3)P_@1w9&Di)e{MzCi|S&<(Xg/dWOh)w2+y/k,?Uc{O@wvvS$];7{OXP:SJ]l`M1.5A}?][^4}@!99ASgD+G:CDV$]3`{[KPrQXa!iEYBv:5q67FzuYON|?rDssWGz3Gmq:q?S,F@}sQ~mNqE5IIYB}>jV7qT|J5<V;!}5M)oz=r*_hv$MtpUdE0~0t0C(`O9Ox5L\"s`i>N3{z^Q$V.FE2N761{l3|`|E7`lSI!%9rcZk~|t|yOV<063fHGBhrN@DM1T.ME9.k1~q*U&6/kkv~+8$@m1L8$X!os=F=@#PP3aZ0`r+\"k@a=U7kiFI)FI&h.#0Wm;L!UL%iN2frbucTqqNy:.|8+^+`.^ln]U>E}4Bm>H+)rNVf5*:.8i4c]^shcs7h6Fr.#q{ZR7vgg89;=:@Q{xVHhF3+}Hxs?8F7$IzhO@(#8gb,P~__bgeG;Bg\"skri4X4r|HQnrRhIm}jBb!DF\"Y2Xvi!Oa/=v&*3mY9OETGx!i_u^zkQL1Hgi1E8yQpND(_8l--[[
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
