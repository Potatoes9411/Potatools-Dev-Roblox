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
lg/=US,2(f/*H$D+V8N(FtV!n|fp#jWE<~/:V>^zY^d4xj#*4R.N[AGv*mP1wr:S18Mx,1nCNF1M+%K7_w_|^Qvt4p\"i^$@LUn[$W>|G]aGCmVz+YUcr>j_=SR>Cbi\"Bs;i0T8~/*6?z<;CD7,B0IxU!Qw&5koBM2)DX3;w@e[y5_l1zc+V+Y4zjt~H1pb>j<Iq]ri$l6`H/Kf~h8_AKPEaqrl#|H{V!6<SJ3F)y_l,^EbFd&qzCB=BU>$o1RZ[}AlWW~()B^oRF}\"k$Uc?88MTHej:l]hgMSx/1Xo6RN(whZ()LA*]ORAb{%t?!LA<bvo`r~|`]eKSx<)<hCB5>Jkp5w(v:d\"2&Og?*0ZH>SXG?2zGbmB;{&*}i`ehn9i[eI+2B_M<eXM>woDBH!g[XfIfwozp3eCGy=wr~@&>yzzg;fO>>$%Xn=19V3ZVLTx[IAlV?J^2%,QqV&o{0B|8yxxm)r9eEhGQP;;cFT|^],HgY,?M)hU_j8R1~`yumU*t]Oso`wBsh7kJ|o:oI~PZ2ugh1.#\"z!>12dPo)RZu$W*a[$}e9>.)[K&.o\"Yy5VIBXL]xv5g*Hg.t^Ok<SInKm;&gl\"ltNP#&9/qmP~@Xi`x2uCV{YS.|n:2zPBl6/<wdN]bz6MjR+TSnfCnjJ%\"<SN!Z@~w0R}m0/>ftK&w{6z%]7P7`vt@fSl<\"B]X_JZ4:(kcPm5I.&oJfAt^@tH~|!gR5?&s`uO|G4=/J\"If7wb2_3`30`KUk<V>L3{.YFVr{{uN<x5:6DCMFNMEO{~pW1J}N_dq=MdSMUJw3L`t*Q|{N[5WNGA1Xuxb@loF#o5L^3+QcBQ5}D(XIof,;W}PA6\"f`nturyz8xFn$;uVL?t|@xYw,F$tP#>||dpOwcy8%&/ZY?e`TG]#Y,7*I~pei<8M0WWMl&Aw}Qk7}[pa{V&_24W#4)$,.ohqb\"sT}&,Y9j`55aAZGiqsAb+$7Sy=*~JNNVx;nyDa!2QHaF3Nou>1yZ#c)j]yeHdz^Ox+$R/i!@ywj#MjcJJHWrlA>=:_;M3KfJ7[=b.P#^_6bEPHFFU}nMuTKB=H=!yk_VyX+*2F~[0W?QrkI[g]$s~xKR)A)}|E?htD*H0E_<|n.$[E,xovSmsp5i>e@2*7wvT;3!rL/Z$Wiq|sFG5i+8PV2}T^2x^f}~:\"}J4<CH~O.cJf+(}JIzzW\"V4^2&C0i^kh3>fweBi|58|Q|R7Qm&3G,c?ta!BrH@4=+jrnL]A])BJ?S|Ez=a)Qe?4E;0x6]kbv70P1{M@_)3r3UU!9)KKpUHO>Y|)V/9[Cn2Bde~>I]Rd[:\"fBo<#n4E,wYvl+t3Q?6t~;[3OTv5o#dSzMXql&A&~5dr>DAcEc#$Ln[IL[z989*)^(%yL1~hL8EfKx@0,J=l2HcKlk,^L$:mOW\"tYJiNSERmZqCzslWp!lP3>m1m2mDiB<vO7IJVN#^UY:Lzg453zC,1;>fB|UMxhr81z6!}hya1y+hvYz[$#*0aIME^lJXN=Au2RUT=i[|=9k,Dd~#8+*o*C$F8Hl,@Fu;^[B1?~%)Kp\"t{vCI=j}@wviw+>0NMT@Fq&0rMzNG3qjaja=EDVbjB.Ui\"RFdvvC:201.z]ZDB=44y99OjYv4N~aQPZesr)6@:z:,:dv{qZ7\"P6eD.`H58|Om9%GCTUg;6]\"%l$vyNQ>x:gb~:^=ku>`cB&:1K_Z|%*%VLyw~uG*7M^ky.&X}_q[6yQA3qO`3#X!\"xgrF0N0,Zr}[3u;20xEdq\"!kP6mvETHXY<:431{qb3F!vvMUte5YZ]+Y11>f,R2v7bJX4F^Ua1?n~*,~xd^QqAY/#9OP}@(=ehlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

<Bu78s{>K0Jb&lk&\"FU(Qip`=;pK%(NWPB7D+.5AoiDdV!Q4Zv{b(ubP4`:SFK:|LYstf<.esaQNbQKhI.JBmb#)j,s(\"hds2d!\"<TA@uY3mQ{m=6fHD{4.XE`oe4yVf!&;nx2[M)*7xYH|R565~<%oFJu;>^6b9c*J;G6cjp;k#1}j>X=*=]8?S=3J5Tav$\"X[FysFGYUl6/.7.@S\"lPMnd$CG&]W~U`s|R5C9zm|M|hml[;egw*Elq)u@`a%19FySdu@X=Ro+EC#n7&rz*)h_;Jp)F#+ER;4&DBP`{<b;c!oOO4C\"q9@H#&Ruto|20f0^%}#m)Z<#Mb|O~#]xF8W^P*cX^l{mj}:rj=`x{iyU`H8y`/WL#M|L~nKgxRWw[oN![s#4_I&a0%v[#m_Gp&}afPq_]umg,;yu&LV.4qC~B{~/spc1Tb+|iAVLhnukst2/)l]4FpSK{0R^[(p%$AV{I^77hRlV$>9OA|FLRh96T7B!>q_@JX*0XZ|D9R9tujZ|kQx^jsj<T.h$jI+[fzjwU=<hcHgdN;_F[Tin%WvuRH9wmj#eu%>+IL/mZ>6+f*6(&`pF|.m?ubV\"T}lwr#mZLy1pD:G&^:uMb?RbZ!A.*<nrUgmfr#xa/<HvOrk/Zw]3le&3W_!,uFqUDHm[5)^V3!N0pt2e6;iOtHRkDk}x?}5n)d$}L!xp&Oy)909%u<@>JsRvQG;Y0]m%a!Yr4vwQ%f~Dx`.{x#XSM_.Uj3+gXJRF:)pP$Fv=5W.t{ea\"/yHUI~rsJup=7G<`.pw:):qa46mG?t)J&U2|JEmuwiQJ`)1_{X3PI.tK>zS,`LCd[gNk%>!;hTr0a|[%283+s0x3ESTSy~)iXb39>!^qs#`\"IL?BAY)LP#C$5gM&2._=O9I+g.Wug_=%<m:Yh#KlyGhcel=GX8My.?@e33A|Ntu5SEG1=VVDq==,5?W,[$DC5E~9_]4jcpI:lCM[25[R|Zc\"8g40E(fh28Wz.4D+xU.k#IHR1s?^SOV7<:rnk),Oy5A(A@[hO9Cb$pE/fEd}5>%6+}?)~~j,^Vb^W%w6$Yyze6P$kErAuO=084u~N7/CGm[utH/0#2xKj\"VR,03~K%!/PVCy4\"FBy]@G]rTvHP)_yd(kpJl|UXH+pUl#Gr&N)@H_*s23h(:ay9_nApGVu!{r<Qb#(MAjxStIfUEJ&da5Xi<K{;p{O~^RM>V@[GbOc@DE6`=OF&wt)HkCUCOmliged+XI<<cS@;J*mN5NT3K3T<fdE\"NA?x5I&_0.t0hZxecx+G>@+I~ZE=i=}Pr%H?38>@L[{$r{nlB~]Eq+mbG750e=VMa+XbwK|=k8+c811!`u2XVJzFBzTXyD\"5XamU;eq^/gi\"o}s] ]rt#>`hu{seD3;qm1K_,$bJ4zGyAtL<dM6f#[]Adc~NbZHItviI{k,Lj`>/mFybf]<m*/L(7QO`Q~grih!me0W1mhh:rPueo5%>AG#}]x^\"SAs$b?1`:+u%s.Avn?rHZJBA_#xH3YLI[U;n%0H~(!p7,4Y~{_|(^{((B@RY%b,8K^cpy`<971+D4h0__)LpK;Tw,iYns.N#]j1}A|q2,GhRKF3=fvlZW0F`%AbR}j4\"jp_^[w(Eoo+c.&;~Os:;GxuE|bi_\"s!1A/2r~|;YC(Es{kkZp+pXna(8{jG_/6w2T*FDCwD146U0Ck2Ql3,RsP(DO)GW:;OAi1LM)Du.>qCC>!qQQE(vY^4\"/X!m;;K/|OHMWMTRP$M*&}iC0]20b3>8F|#S\",yYobarPVEVxrVy5kc]NRw5p1,!rsR`[i9+Z^!q7TIi>WJ]?/2VMu*xzBVz|f9mjy[%#|ZU\"5hnWRgbpu.vd~_kqZfRZ.O%+!b%ERzrGssmHW]#$@ukmMi^Ttw.Ze(12h1^tezPrA0tP(}*&Ct&3ib,`M\"]!b+l%n*Pruu9VPF\"xA2XYMq#Az,VrfP8x;}s6Zak&f`#,L~}FAJU}!2m);7Lsp65Q2d=T7Sa5@\"Fseb|wYw,5+a$keZ|MjxQLtZ3Ovmw<WFI{9y2k#|*/14U8Nn%%.xcGdJ{~C/&%VEjGD%\"iq$%FB<Q}_dqF<$WHCjO.D1|]x2X[hdD#!uq;h!h#lJ`VxoFYC14+gZtKE=Z04Z>Xs{~6D*pI:(hEZq[dj]==*x3+p2IMO^gl7X9Eh4k6P65zbIGhz\"QOgi2{Jt8/j$O2D:4UbgYN*g4x]LA0,qnddKq?IW<<I%$m;S:%H*9gh0iYWqNx_=:sgNzP9/th}cBjwLbyXmE7nxN<25/VY4{n]OS`8Mvg(5,rtS.8&fP7/_DRQ.\"jKS`,uY02\"?9*1DGxyv50pqkPftkM:`axF!pYYm>s|iF<JHT]<+d{g_SOVJVw/fZ@/kTZ94EgSnMLX7Z<uVpmYU*#Mpij]t+tNK`Z8k_YVvcCBT}p</#)V!y/wwWxAr8sMXWcBfKjVZ6{ty%94l1GMiKT13mS;1=R,%lu;PtqO:I>6>2O5ET!/b@+_=XWE\"7UW5pgD|<>V{f^{)Rsg8uoi623np+LquqqbVMQTx#Y]V~+>*FX^i~I=a}~!M<T6P$euTU[~Q9:;h]$1:o|SnmsUdzi}HtXCk>OKlc?9?1U&%UV93y{^hm(%|1>7ZBMXo/`{hNSRSb4G<ud4+lDz}5sdqDlpQXbNKQ\"NG0V~_8&E3d=yv^XcQ\"9PFhRB]91vrw&#I)9M]:4wls9Mkd>&AO6fjV/8yA>;n+]tDg6WWpxEOuJO4(EYk8t_{i?{DE5|QzYDB;SOH(X*l9Zn?!^L<#L(Zb[=w>q>0b_l)!U<yDST@W{eXrCkAN#m~M}bpMD88@PNd<~9iQyEOhVcIxr!Hw&hT;Z*`Bh&$Htww(xrt7l_kwl`o*c5d@;SWuOZ:BYJo<)}N+G|QWu^>gp~:&ZLkv90rWM?lbk57:00&m/a2*q(`e)T?=brTRrs,YGp;hy%4_t/#wP|cId:9)1MU;qi86<zuVR7q3P)1ZReid#]041yUC`fH7vksci:acy?gR*$hW)C>rX~zvIMOd/w=m_&S&7jl8nY>#.dhW&Y*8(|uv<o,>r%Jl4BZ9^{~a&{DeQ!$5H}s|2[Y4@|!Tvd!3G4bbjL?)s5|9BnH$5ccRhv[Pk;h<J;Su8<8C}x!,3WK{,W>nV.p:DUJ*Aw`J2^uT.n1l3Chn+}$:733j65d6Z!fEk]|F6?:T)>z.7_aQS(~2gCCHy;mL73MSY#)L<ZSD,{y0:o@NV+V*=0Mj=!f=TVvm$.@A&bQ}pw+lA{ya4`JSwJxlx(d}nuqGh/IJ|0[i7*f,44,P+CE5XbL?_D?nEv13YVxMz\"(HR~^nR=s;0_RlSZPh1}P?$TxH|mw]?ynqSN9L&)vw&z0uL4ibL(k3R|rRznzcz/~tqa;0yY52Bgk)^1+Z=6fiIWt\"MST3hKErzgZ1dJ<NLw``7**$kXDo;6G)j{DK2Q{>+hH5~Y|{W9ai|k5u@uN0}9O$5hdX:6\"BHV>KvP?i&%BQly>WsDmyEejmGKh.J@jbNE+/rlH+]FDJ0Mc%#JU,,\"{}17xCRIY@[%r}1Z9&t~U*:x;)#)tr``Rp90OX6{d7A1{IwDY3*JKkwxB.)JD=(zmS_sWnmwn]pT9zdG1:qu$=ohh7wJIj2l4RPspSed(:%<D|b$Zis,XW.cX/7GI;|@FS$]bf4b2~~K&]JJY=.$r,#%S+%1T>$%Cdpsm1e1s@+O@.LkS$b.Oi)F/RPrQe0Mq<muFw)qpFx(^<6{x}tV$?#7S,/GU49wt.|E[;(g9)Gt}+w%(!2O|0*!j62k(3rfGvdq+E*@rl9]IJfE)4/2})l(09%<{P<1a%oj04<K=kej9@|9Rqad[ASiYvNCRzd*9iVU?w*FpArSeMg%S#`Ao*WC_a]03\"<!6Cji<,raPHIm4.JZOC{.Z*SWAI?`aJ~z}9+$XM|T9h!)NvO#WCx=9@wGc/cH4+KO=2*0s]$^c@r7T0fsnvArVhye23n!Pni~F/w2l6)m#(Ul7Y^GyhFYzmy(NLp|=reXc^9i^MK@4=aWM8;~_\"Ne^JQm+8Phjg3Z7YJqGlXGE.((zkG~01_o,@b@Z;8;?@#I~R1r<NXlm.!K#V*F6Yq=dcV#tvhN>JTaWGejn/%wT?Q+hO*mZ&K7T`b%j`]N$B^$:wFsqkEj%D!.[fv7^P`7d+]A*J\"FmVYvo4~p<P.YRlU&K!KDt_N!)i6pLVZN`h1gu7uwt020?A?N:qb)0_PP]1jqpms>ea31.5>@`O1[\"teE3.&>U(g#=^i0,#=e23c!kMXlBEV(q]B2k$X+i\"`/nZ+@O.R5\"zMk`k1}vu]j;bWlY`j{+Ki2Tc6!8?.IFmJOkNyPxvj(qBN^v>cT^0+r%Wx!0vm%Q:5Al&K=tRmW))p/PfYDP5]A&|Vr>5~pgOB+=c#Q0JsG)GxMZn,VXF,,}XmM6R$Iv)7AfQekB]06ebq#t3BT.M+GmNM&.v=cU3Et0f(O)%C\"M/<~e@4ys$c#M~tdXu&+hAo+EH!cQHbm~A&=+D@:6vl0tf*]e)/rwRH3)}BU&xfPPn9C>})Dh()2lQ)f7C{_)0L;mn<gjw|Y5] ]F<Xy:_)7=y?rkhxqD$Sloaf>f_|N<?pmz3>1w_4n<n6hXX5EUOvsFyXUol/v6K@B+QD)U{kjZ*\"gc&Rr]J_Lk$hk6_P,81p)ZSgf9<*U5M?(S$Vyhk9)AM]K>rqq^V]*5`:z!k>6KZ;@o`!MNYreMcJ/RI%oi@N?(Yx&*akqF]0`qjbLDA~/Q_+eEC0`#LP;VBKq%[[M+*qLuhIP1+rl@#C4}2O+#S|6cTW7!yr1!6nLXfm9_:s>~9\"sh(54~(mC^#u5Q:1Vs^75KhfKpEYcE[6U,rx=}|%*1s`SH]1&Or}Ziw6&6&H{2_)Z5>^28{1;tMj?4RA\"XQ=uHmw3.#bQTz]X:a0{`pxf`LB+m:pBxL*MvGNz,W]65xhf@2o[3:jkMqo(_(:Tn`(U%00f!ku}v@v2VE?S$2%;gr)OlZzJ<YsSi(:+v0yl],2Q^:<7vuVLxnpbgeE|=\"v}=Lb^Ko~CP)rHN*o9eNFsDt~$Uh<=H^K*3$Yb{h\"<J>/(yke:`(gUj]VrT\"guTx(`:A97;p[:F8Z,*|cU,a|3):UckKh<UbRV/ipbqLu9JZpI2)IK6i+6*$O9FM!1i?KMAi\":cen974m)=/bET]xNP!Y1LBNtif,b\"Df:Oo}@dS2?C3\"fvVa}.{aaqrc6Ui5*QFED|VV%TiY9#_RAx9fbv&]1Cr+K&qu6[v`(7GRNfh9,jh!Y`sLq5))D0*Y+|2hHT]hYA^y0&q_(atp&q|`e5z?MD2xlyy<@+U:PvTI444G[|X;5m(1gM+m:\"3OvrA?&AQ|y#bRm\"DuXJ[Z*pVn}Tu?T`%E99nqt`@3x8{Hvp5f4H_%pf0_>wn!+EU.~C>l6sIZM;hu0%9ZI]2$#.pJ<.[|_E%G,B,6\"$*!g64z6x<3UFsh2K?86ELS^Mo50d>Q+:G1\"W`{lVAuC&L?Y#qA&H/Kn2}/<V*%Bx~>[:=DAeVZz8~}:DT*yDbFe9dRv$rY;t^y/7d^bU}yx$7R}v@k.N>jCzn1_%J:w@(3&7/wsNDa!?)]oC<z>X)>2?ji6.jZYMskX^nDy}Xppi<Z6UuruWP(CcOv|&8Nv;MIYp=vitHK@p/Z%i)kg@|KTOQnD2_!,Pk#rRjv;p`RN!(R)kq#dI5rw.`J\"q?3;SGnK|xL/3gPUEOk+QW@=WMZ\"{ObIRt}Bg}LitcE<s:cgNv&HVwtYSW>_7xzQ%H\"7aw~rEjEH+Qj%#!(){Rh`s=%Vv0BftV(eUr%|@<vlyU@7:suE|.~R{Tw1Zs{|I&1.a#yleM+0)xc>;!sLf=E@ou+8XU_:^r}LD*c83k)I4o1fF9+KIGPrDC#4JwVt_:z2}r\"mB;K;9C}K\"j8jUQrhO2w;g~ih23X50ZLnvrJMat8rq,}EU#.oAk9*sV<Fshpf.tb]E3J\"LFZ{PHL]QqLm#1vU*b(oUj8XgyDIr]h[}$]g*y{UK)[GVOIt0phA*_(~:Z9I8b,7%S5VSgj2}Y.3O!?de9]5~H<_Bb,Q/$O)hs80*yoU?5DD0KpTwbr*CDyHuZ]yW`$~:f=<Z${/z#/F4}:&9Cne<*CaPvG)mLBn^b[Bp\"w}_[iJiN<XX}(N5)s3/CzeoFYQJSiFp`}ybrZ}O7Clgz|QU+0LXm!AB4>.Gy_AqP.o&`*&r[r/)/n^]MJlV2yFkZUgbW|hc\"N6X(&R{$[\"]6NRn@38G5H=|O]=sNPueLU]W<3Fta0sL0.k2yn2TMY@)_`~1eC&~>&,eajm%]7:Hq=[{0wc>N=W)G]R@ro*VW[+e|w]m,7*Zui>/\"8$usO!YOoU4sX?.Q<}\":4UA8KlCE:XEUQz92z1rd&^|#yG140*z(uhOt:4/gB~7g#KjZ%Zl4xz+MixdX@.Q#Qn:xP4.>l+B7(p;ANp0sKg8F..i|yQN7wDDM6>&8kt#91v}_HU~L1MS%Ju*}>2eP/H/l1%mg(~Y{5/$d#+^&xYRKzsf*MKhhjFLx#jY+Ti0Q74o/`+:PDhLvrw+yQjS[qXQ+m}HV&MA)hi0Fc9dq)6MqEr=aIuK@Rz5\"z3v+$ui`[lMD%&xGZk)#1!/Y+&m)c?MvUUpK9x+y>C~V./@;$aORcH7\"_VMrqI%\"wh0sq_R7GNc(Y`K`9L{y`ykr^>}d)vD~H.(!l\"P%/j12:t/e#ZG@ylocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

w2r~[g,fo] ]_)^|Llp:EN>v3fLL8,URkk]sG`UIGz[V~6>h{eB7&>5,b}@+U%lALSi9K<|4naR{*NZ$h@Pf]oavU7tEmhoL=kWTNz7TU>M<YoDcL{O!wc4t<G`K,~%|W+Z2qjlSu_doNOGg+G@dW4\"zQuQ},2;x;X{v>LVB:?U^sG4#_R|4TTrn?`X[!VM3Mt0o]*Q;3\"D5V}1QI`q%wQb&F3`p~Okj?bf^^pa/Dg~zPaYoUtw#+@`?>v76fecl8Q,[/aj~oWY;_w}Z/UfM[Q;dfDNU&_l)]Kawl6Dg#d2nmfRz%r/ePbo)Maefh1Tg$#&)jcdw_D17{FSE46F!b<aj~]+Ca>?DHx+lx48$>i;$\"Sguc*Uoi5h~rJ?xY]y_pdD+/UySLkFd0^3::K0\"WnoB5cf45o|duz3)@DI43h1i?;*0G_val4Hg|a\";XJ\"33&!mvt{local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

nE=nEaT=Go1@0tiax&~YR+S~a_RTM9(MSu<Gl3Le=$MmtJm2;)+ce&h6RpGnK}fYmb~Grq+)2FM)lT=*Rwkn%/5UYexu0{Z<;0NxxZ9`h\"D`i|$|JW.\"Po@ynOix2Im7>,2j&7Y&cjj{u{k`/(Et&71`mC*~8f!y?,zE5H^{9*zhRF./[/s2cG[!4s|6</.gO|Oc)FBnF;.fPtN1Si<,Yr17B09&<C:~5*w^tf~Ie:TEGBeby0Q)WexPk$8%oOdT[9kpu![)}JJ4{JmSq[*srE,Xf`J>>%a!.IuM/>c1/W3O?+l?9](2vGn[!Nth<::JWsG9gkF|=M?z,uReIy0J:(14w:(^@lpb(Ya%?g`.m@Ub<x!=;72=(=s|.3S:i6jn_P30,EVY<(cNX=.IKn`c(Qlk:}r$6x0j[)fFt#.a2Retw*;KX4ne`:NtFYAw0to4CQbhF2c?CBhBR:O:wL!`j32f|3o[p1C{%aaUrWL.{m~LT`SS\"%B~FK0m_/rWl7QL4E{xVF&fwKS@uV#Uw66$t[N.bFL]~T7Qit7t@V$6%#6^d#iV)!ul(rH.WGU83O.9l]ZzyzT[:n0_T%Y(o>znXpFMkv6>zCH2T|<RGYcYc^@Hl?K`Wm(y`a#|X+NI]%]:!r3YLtrbll1d#0#Tt.wE1vioe?cqI6wmzEgr%r\"q.%0uhXF~sqc@|`45`8Dy>}XtactNYSs#u.Q_*r7AC,=<Zo=.a)1[oaZCa[)cFhO3>):I>.{@j+5)7,|s2xnU%E$nT}M&/b}:w,@=qbw9O_P(LoFV!))64=q|5C8,x9u|wjdh<(w6yF!0W7H;xPbd>7h/>Nws2PAz}A4DrD|^bxG5/Z(_(0/.N46|*(1];2Dq|,F;b*/`G`/&xaz;XV(/jyJjP.JhbaDCmHvpVK|p0h4hqJ\"i+/ehRmuZ0O:)cY*;DmP1q$Wiv8a(kr$8o_)GwBx*>9f>=*+Hk0R7JqPm%[`V1q6b|Fl^P829BRH^SB>x9UH.3@1]s,8mSa|g1{9FXwJ~CPuC(*ix\"N|S|&}DM!hfvYkndQx6>o\"%Wvkdtr$rg[_t,Q%KE~M$2k6%C=L#fx})E2W:;Ak?a#x4wDQY;*cvTUrZOtz3T6_hPJ}4!YoR@{6F{8T40%Rmwz.?]r+~bRDJGWQsb^j,svcNn,?MA{.JywqTK40>RK]hq\"gHrhZ:!@j[8I#TLj}_o`z=,$v}w7]9^?@hRd>]?c=F{`9Fj2e^$I>)H1hTz^`8|<;D&bU?G7wRXhW8fXX_SxmzSixaq?H\"{}1NC_@N@f2a>+zlM,)/jG~R.H{~n,R`BqW]rt(,mK_T_zTlgAe6<\"j?>xNq.t4tj0T|#6dvk}BQiiZ3r/L&hKz%!@u$=W#55=sE(y5E8n|p+GXoUb*[4XBK&D&:SL98:x];CqaOCCa^P?&}lWJ#&vYi6c[WizjVG=tkr/}Wurm*S]4p$f>v5PaPg~;oSFNSKE6F;s\"##CbpknZnR%e73`}@$*lmVDG_eeU@D4|=9:O1amD118Y4,34Oj^!97g0tPH(!x%]5WFHq!{F~@CxrgL@_1rttwrQh+Ry<_4dhz_o8@n%InnCslprQe4\"{fh&.>.%sfJZXZ667C^hTaUva98yy%9I{`3gT7p)z`gLQ)<k{1TnF,|Cdr*++pW5w~LoN(CIE0cBomtT_5jS[<CA9|\"<x_<~F:c*t6zIq}8wZ<1}Li;^;f!7xrdXK`6L/j<E4!JhtD`,k{3N0A$;NP_09HG<q02B.;,hnSP\"DUaz<i<v8vRbO9A{yOZP9DDu^@aIUf4XhZLr8(\"iivk#^7}_U{(`>7og<Lz@pe//Z858!H;T1ZU1C`?Sll_IQbcz@7[0{]vMV34l8<[EFoHlF*{{(#*yQz1365oyvInYY44Dc=l5@Oyvdqgw,nESNE?WYSz9$L!%hQ9e3$h_bO2Z#w\"/n{B)z^eud9f)\"d[7bRgT\"4zk/!V5h26!UKll,{p#tZ1OyFyxJQj+*YWk7wO5yvm*X%ULD?3g)97cfoq@x9B~|i<l5t4.STBNvbKyT+q`\"N6Qn?O%,js4E8iU0~s12h%\"gJt3fYBp0RI1n(kIp6oXKRb}Z?me9iTf*NSoq2UcI=?!h.ILj?rAF+_@0JB25by8o>OXTy30@zpo%_40#S`(e@Rh}bictG+DVc;&:0r5Ag5XFCWc[o%hh9{8NT1wCX~~*tS_3b*KD:+!%QRx]v,/Nf=t*G4`#P<SI85}5.47\"ji1!?/)~V^Aj,J+#JrjH@)VrN#<^0I>]X>#9|;@4&H.~R2ohPq:{:3!%r*99@Y2YtdC}t[]v_mP}DCY}gEi|tGbHC6)*IGoL?)F9GW^0*!ICLdp?U{wr|>?DRSFWkOnRP(=*&Tmr7H!Z.]>$kq.U@`@)8a=@taK4j$fPRnF?ds%9)Hv&rONUFA+VWrwk*~h?XyQwKFBD=M>qF#uSQS=D`+^l^;r(F=[4nFfbzy@t#&&Jbm($Z2xsz+~*Y\"kxiXo`Ta_y1t$8W4^{>JH%zQ`1Imp|aHcZIOF+2kX.M_1K<v=1.)C{%C,jANuoDkZ.zn=71|$THQmq.Bhdp]Hv$X\"+n=b!;<^N|UqT[|e#L#+W?Re2,tz;[vSYX40Kqz&,#n=O@y9}H~^TFaX^9,1e|oW`UG;~5a<uE+BP*16sk;XKFE*VYU>|ZP1MZaKN:,6Q:,f2(5c(nHq?{G>@d!{N!6&L1X?E\"teODZQke@WM:SxUt:ai);@>0rS=ehHb%Qh>.![4K;50[f~YO3FO!I~12gZV2pB!:d6Avy|:zc#m9Y?0Akvo9Y4DvRne#.Xt{AK{P&an0gcDwmDW3|u@\"d\"WQq<A@_JYL{RO7!cwZpSE?}~TS50b;G3Zr/#izFooclp*pE1Y)S<MX%Bs\"%N3+D^)yVO`[D0xZVNPoJxZj[$\"seacuR3fI?(nM}~B}[:H6Kos7n@ZyO=7Ko^BStVgIH<ag{Jce,[vJTDA%WnPO#7U21!!K.OUqqpJLMn&i(/Vq;_vQ.OknZb`$2Hh^[W|P.>|l:bC3>y&$i5aQ0s]MyP,;y}S`/~6~{QC9=D&4IiIyL(fe2(g)_iw/$u$*Jo,LspItQRlBPgZ]m+>9F5.B4f9M(AS9jDlV*\"WS/ba0!`n#k0LeOd>E.D}X7bCKVAy~b(fxi]RAK</o3(=k8}#;CY[p;M,XJk#8w9T.Cl[6f4&vr^))wAvoKk,EWypy97/ar4m|OiSV|+qfpL*m4)Xkg9OO;!rgI]a!.h/a.>mJJ11XgiABe|nWY&s0g@<Mq39JLc~Z|vq8bA|Dx]GlW)G|jg:G@JDuREcLb&[cNa;@./hMFUxU/,mS8}5I:y.;dwY[&_1g2qJSk9%1C1>}Q}:_Y+L_Hi|d\"6#?E1M|u:P![Ylb_Z0]5hO%aZI{PyQ`>7)G/^>PN3Sg8cPdM}|34\"2w.F.@n%&{Tt6jdApGDGB!V5&1kcJN+&pC(0%|(n]1f60n#wd]8~X<ls2#4)e`N{CExY}S:@dG^hCZ<Sr6~e3Nk\"kvL0UII?oMx(lT6L$p+znx)=cRbvMQX1x6edf%K4K$qQnq3[\":YkkDrkG*Q}ba.`puZPHwwv4)N7K]3Y,f`IwB,J<0S/i,--[[
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
