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
k\"FNg^,Nrw4Detk@EpJUM7%^GV/Cjr#KIBc(dg?JN?Y7W\"\"BS$edVT73IBesvh/Opl;tW7/MK&DSCS0V*s>60q|.EI@#b+xH8C6!wif>FQqC;:6x}Z4Yw%t$9rzKF8q|lZS1e:(o:n2iO}6G%o`v(u]v:RR(kX#3vI2+Jw^Xj.>m<{+S;.?jd8Nc1sIS]YE@T2RBq%rsw\"t7aO?44rveV8EOI,gJQ<<^$Ni#Dq59Ewt0OlI(bdI6}Vg#QY5|FINEYU/{dq^jB\"4|GHel[)#{1]%6N<J?}}Fwb&K27k!umko=>,(bQuUR#VBqz_q:Lxcd^v.$**%+8SzD3M^6D[;k>\"c~2M`%b,h40a1J3E}3*GJi4DgNv;DXx[.67<nPFnBjWgPm42Lk}`/sJqaB8yx2w;#~&REFz#(nCv6&\"tJ{@n={)p}o0nB(+xBWRLBzPV^Jw{SD;m?zq?xP3HhZuEnk],d#a$7rc8!0Q7CXeGnE#Q!BA/,_6VM)v8j4?X*iT[U4)HkZB;}|QvQGHursta?<I9Ky;$JCjILnG?71gKbFpTzqOmRYUW\"LV4UwU,RnG:::wy%#Yre*~PBu9XDZ,QIVoR}TMXIs9EzL<kitYyB}RfcM`F8AXj]=,pen]!9:2.4s`~PAPmy)X`*?86Q8g]},$@HCFWi7;OS?](!n*$L+eqMIo=$Z[<?lAr)Muu4\"Ao@x/U[#RNR^6f,J%Sv4qt9Ob;FMHkN$SCK>i6K2SoZ1?7h:5Xvae3&m0n7:ga<%]u.v(^PI59~Wp^s`(7r6[&b6*iNKUD@BU5}]9a}&JgciVP;l`*5^8y~i{Jxf}6fKTubS+EP9=R,A1f=zQ+n;Bw!wSR\"6UMw*WYc?fAe`j0AKGhg>6?C<zAT>D#T)B(f,Y2~Nde&DP.f(GueS0^4~nYq~7VzqH*,;x0b!k18jIo?@5(g^L&W][\":;L]V}IDqO$K1!)JFM{by[l:8._r)3~,<44NaA)z%\"ac81}WZ>Og^>7tD@$aBTWncB2V8<Qj@$ipHFerHXE>R);QB#5u(+KEjDvT`e76V<aOYstyDC/u+HiplJa@GKx$K<0P|p,~bkrc9#\"Gm8;[=<(i1Pm)HWFj+.]A.Nk:di\"[T2|69rd\"0z=l#w0Io>Qm?nw5]f>vhU!0WXGnvOMxJe%l_a+{UoY`w5fS[j$Y9JU!q.A)HK;>*`R$KiedlWMi`ZeXyMqL./AazPMC*78`4mBkQPSBh[_>70O)UhmUIl<aDM2c/K}qIdv.IY,kY:bzBT*]?AbRh%3+AOD>1>C^walb{n83%PP.XD}uvS:5s9TDi5Y[V7A#jI1;e4%)e*xL{e6Rh9kTI;w|N<$vmH;B9^`59}oNkULEZ9x)+T{yBArZ6&Y$e$^j$LN*K>(Ur\"Y(?4Fv:3X^UC\"oNnUL!)HTag$760JW<08J1_^?\"\"D~7Tun|(xj:J)n;*Ur5)U<j\"07nMlB*Fv~%3%Bx%9}C4VJ0#ueoq;{IBeI/K@Sv(Z}Ct%1c2A|5CyPc*7,sp{1zZ>VzcU%ZJKUBiT4psfklhW&X;|h)]KA\")k4Ho,(O=C6lloqo*6dHcLo|;XDSFauzy1\"##=yW3%b<Uf_,+@>ch)XI&]4dVbn8)?M&4orA<UI{<mb(8&NNtUsS96qDBb.eQNTpnqe?NVA)A8nMPwDU/\"`vf8x]fGs,rN.1Vn(MLU{H+NNn^>ODj]1dyDs@Q<v^eDmL:q!7pM,T\"lOic@J\"g=HgX9O7(M+)^/#*UlW:W{\"!ij&_xGr;]dmG\"80`Bb;>W/:WHnCKvg7=0X5c4[%_ig/Lf[Mi5B$jFt>Y*~d$XD+AzucC`\"wRUX9>jCurw]>X#jk,aoS.ZXU<Z2H<yQhj?!F<xVP8|?_R7p^RP9G|TU[Q1X.Agoc/$NK:N>9cuakm4}6&0SNJhH?@R395.GFsb5%GZ=X@B;^=i0sFiHAHwinUSj;S%2b_}mr]s3oUr;j/4MSL6{Y%7$OWeiHx\";w(YGJ%:_D4#DG48?tBfV[3TuWUc]L?GE|aN;W(v@|([rCjdV7I*A5[#S;0<tn{?yq5B{rHo(R30g;b5qeg{TopXp(YszlF^d^bLO(4J<sYmTI?8cCz#6.yBc$Cx4Fj_l96_0;gI}~62k0(QmS7|nB/e57fow^\"8}cAGTG1dz$JbuY:n^an6_Z&LMxss9aTd?\":@hhvI8?z/v:W!iVD<*}3gK@>fgHS1.z[C4szwCq\"9G`![`@wsPkTV`[m:/my9$}s_)0[M&JvL1(k]yIe,eI]SKJDQ#*kq%QVZ;3:XlY{FY5BGL1l>x|L}0DK#!4g`H|=^9kN8w>r8UgUp)*(A]nh}G&pc&dPlD*(S9Oa285ZL2<;5$@|u.BmH~xaOZ8_%&lVj]?A<xIs%Fo>f|CSV8[]TVR$^35It:<$?YVB&aui!G*l&.I2Xdacd%^ojXr}))n?5}d=._M=TRX`s<$6idC2<MlK*|Krb[VOq[vNavGI3v5NzBs!it/d[2l4;(RNr/\"F]?GMI(t,i}YAJ;o.K4V7*^\"!U/%WE37F285trX`Q1D%7HPuIDC`8`mjAgms;cJieSTeAGO)Ns!Mihu)#OI&(G.4sIuc$O4L~_/,ym`FD0F.#Fl.7f:y_A;J0Ywkzp/s0xQb{b%c9D%z=?}`XuW~{}47;+|w)C}w$J3BE}PC,/]\"7xCc/p`^VlNNK_e#G&Ghm]Yq9S^~?_sW>EY(|#xP?Gq.^O)GIls4td4_i99t2Mv4;)BM:`$^,QPF<m$\"HILzl;=`!mbACj9AzdX7VrjS1S:a[yDTB.^p([LpZQ)|&bOAw<N]Q4=$*u:m$#B.Zg?>T`2gSC.?yXpVk5T=]QKiv<2*]^%fH$5jN~vf//_Fcn>pV4n57_G3Oku9@]GV{j{pI9YjWk(x)C(G%j#LuxWHPrl@h!Maw,0:a`$hfVFc:/y?!Gi$e?Onk~qd3o99]J%((QQQYTs;}pfvD$Df^2Zh;L@QlVBIKu2:QIq~Q=[`4b&mUSTq$FJQ{#)!;J!tSe5AojZQNbtd@`m<*c,#WksBUqr/28z1)@$>t&pH1HM%Kytm+DNO&I+3RdW)k*Jc^EW/UK5qk*gUIX;?2j7+$b5l`].zyP#ZXC_?AgC#M>l}saTI0L76~B(obs_i&eY$/=f=zKK?rKP`+*:z>k]et5c:pZ=Yd5ZaE}$^`D5pK\"qyBV_(28a7agl!wWkGZ=\"o)O=xG5vPENOaZw{`p]BMTe<i>j)dH1te,us[!`_r1u7+a<n^[6zab64[HG7`t;Zk]c5!{]|h.}pimkbx/Yjrr9qC8;L,O?*w*IQaCO*Ap?6A2fD75~HeiTug,KhMj*EI^j8^N:ODc}*IHU7?v{ChLn//zz;?2}_nSWB,F1D1l)<PT<D7uxh\"$,?Qog.,W9mf>:Hw9F]l?_ha!WTHT438a\"J_JN}cE6AW6SbO5Qc9\"yUzg7Dw~jo24IrILF6)a;zSQ\"f?g|Pt%?^E?@u\"Hzm)r[{.2{>wvR=zX7_7Dhb^Zhy{HsG5RPX/h&d+[/Ov&QhOLGuS#%\"V2u`!2sqCw(w@EjKjbJFi0l{Z\"N?KLVM?wj`/au267Dv1|SW5>!o$[L&gzx?z=}+OY!Qn9kc,~G@a+4VaG9.Pp[1<NDiQCSX^*%1W5#B@0BX<Ox)[&;~\"3rYmRjJqGgDl!TbH\"<J=nh(oob8o3AW_`$Zwq%v_:^*L*]HEB#wJ",[0x33B6071A]="TR#:A<2@qXB/+ZAwlE6}u{}H=Jl|oyma/8X&*2V;X9x)4HBE;WJ!j?.]F5W9+LY#<}6;YRhK7SDXR3e,nd{4x%%G<5T(g<Hjn$FYeB@VG5lQJ!j)L@}Q,oL2BzyBL`e=o&~XtG:a={|MW%rH2hcMLD]7<[V$\"!7BC*_E9C6ebj`[>)paB\"OCQl;:##H++iv_@.YiG8H(>LL)VywY/cx&)6^.>!ltB27|}MNzeb:ZB;.>@.azB4A#NPdAT0V\"RH5,dMs%M,tX,2}yVo#jQ$[nZ8Zz5ZVF$o;Xh\"sGT/`McuMuYOn.jA7+p0L5yt%JhWrMt7tv];7rCE)xPY#{wJ3Z[Svgze[<XkL8gKxaJ<eWGG1Px{v+J}>Wgcs}1+V.rB$6h&kYA=hJ0;G@VCPPW/tYE=KEk(8NfT$e[iKn_s6:xAF\"a,KdCg!gsX_H?L32`SCT:,Q=tsVwBVaKI$u<l{!/F!local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

cL!,2V?/6Xy6oSrXN2i86QK.*|FAA7mi.96N>,AwB[^j:w`!kW}|<<6<g}m*86AT7J;,p/Gp%^/dM+\"`0k|qW/afTjD?p*f/HEw&ac^vU*pLd,DGjIsGx.~T0<^2]>{{d)NdI6!fsf*`g?DTTdGMEL+JFh_3%|d8vLTg11Jl>:\"^+U^wY2^e|q6}kDaGbjl\"|k!9F*h`iWOza~Z2:h\"G@G6W<QWNCf5od>hYfYQ6CJqAinYW8eAs}6><D\"fi5Qx)m4qQG?Kb#\"uo1~aY5>i(B1;u6f]&Y76PSC!%,:kHepeM||U#CLYS$7iB(H5xbbRHE?[zZvSMIALaDGaxC&[=4)cr{)HBFOC6@l^L|yI`X8YIBP!aY|k_DmOKBMLJ)zw2HotHU>#LvaW4PL#80.xbIfj|9E)&yImiYo\"ln/ZE,[|zMZuJm(ksbZ$M%a5M({|;wxWXhi`P~N_Nw/Zl]d@q)Cj#&1jZo\"8u|Yu3(T^v:+&*}3Ym|`U1$Uwg2Ay^5;3}z@<Jcw?<pcdv`uZfVKBbNI}QzxG.D<[JXsE]0%M>|52B2Z+y;*uy_JLbv_ci[$NH6U)K}Y6&]6k7$t$VMCyFUqy|Y=Bsz!FeAN4.fUienL:BH86_%IU[$B}%g^7XE${aaoM>^R=ZNH>}>64CWj^]/]4Aqtpr/_DJHKWUM@1M8c:*{Nh[qsRqtK6z|(7WdP~Yh($VKeiO:&ckuG7+ZAO.[</gipqflabl!B&Vp9_>!FNLv\"dwA<Z|pA3pcaMwf.2Gf/:5*tsVe5Yg6#rK^pQ@vXw:<V!yE^i$rlPdX+Mf`D2iHXy.[iQnfvE&Vc:9#2}mfz7I>yd7B~=j~oHtt13Bd9QnaEgY=ws+#,8)KZ,Wu~N^_~hQ&1cB2${pQORb@h9^P92;DSH_h/**dBWl}eg2A6RHxt`Ezl=B$;.nC4<PWm@$*ouf$o9wN`:|tGSdirM~eY*|dn.pxtlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

0UF5<gR*]te5[YwK*W+v>cQ22\"_kC?QJEdb`tQ0_^A,7QTtS(p~M#!|zBNUxJ`Mu?U9$1^I/n9A#$>8KO#Mp$NLMc{vKM?6f<Y75s<pgX:gDH2~9?^lN/q3$08W?.MVABI9I&xBki/Bu!Bdo87j[/4u6*KEt#.7nd<B/I}GVH?VPIL9zhqlB9J|BSuS#W0OA;hAal\"V+eGoI_v3/obRF8+F>zM?C{7$VFxt{5PhLFf\",QHb6(j7cG=Pv+Z0cyN$TF;(\"C^gEHn$D.K0c/qf<SEb=#@O<?oeP]7_Xao!_^|Vrf1dc%@vbC&d!_/AGpeL?t%8F2Q41a!oD`FT~\"Z:%DtCc1pyi)qtr5&g)B(A5H!|e6k^s8Su{twfAI{4]&Ci%pe9AQ.XR`\"j[Td#^G<:8Kv=on,:+\"n5@3]{YB+]d7p`NQ>x|D~)4>6Js)o:$IV_2MQq:]:u?~[aok.=\"5C^jm>f_+HVj\"2\"BH=KY^ZxPfw1+3|NsJP(!qQk=)Sk1N^3`|DKq{/BK0S[*gp?o(;Xbh1Ep6&\"N[e~;>E1oKj9*w)+6Hj/j|{H1z5KqDX{I[w2%|hU3G)&(Y0{o,sC}k\"\"fW)Ax`t}#5$8LODm`4^)iHX1H9mJ92:@1(suQLU34ee|bJn|sU4Xfp7)#K]tO/5BO)Fay!xPuS_o+{paZ;[*X.m)Jw<INu38}UJ%?AVr!A~+R5fVkYRPH~PQLK%4*6c}C;`4O:3PfN7q2if3;X:M3uC~r0<+L)uu:P]4oRdMh+lvg0.Q%Z:1IjMlC=?kDf4BY::5BOmi%D3/{mKMY{RY1F:FRf^h2&Lt7tXWU7Oi8gU_Zpo`_j~?c(/6urHroTHn<F|`.+>.S*j!=@VN}{$(U_Mk;#5z!p9G7mV3Ym(qRiU3yS]%915>KzKjfbzHKU#eU!HC}Tr0y?chQ};<c[/qKZC|QcI*3+%v\"5Y;/bA_j1rrK$23&_U&n=tf.2rN{o:pvG/u7Cx_#dm#rG5;R2azZLLeTe2;2q#g$tP:$~iO1(*#2<1dJvA6gvxh]8G,n~!XOF]f_=Vb2;local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

P9W,2{6K?;=^4,ibR\"7@TptB>HPM0wb#>8RiYwwyAOnuodb^RxFI@L,qU9B4]hR|60FQ[I!5q`C1hc:l7`@jD@`aO86`R1F:^LJcYxOMS=2$d_A9?W(Qjlxed]Bo;?^5`EX],@+9^6(@)}?$;TkU}ChMehoDX]AadUIU%|{ib^`ufX\"o8Ukagd]Ktj/Gh}WTcJMTsb**\"bBmdMcZ:pHp\"=Qv+r/]sKASYhx46bm32dqOVZOG;OOnIII!T5HhZw9F=UeZ/T8u%Ym*NPt!]Ew9#c?u!xgfb#HWd~`/f<\"MuAb4V\",L>1lnH^P8!Z9r[9*e66H0_xEuVY%iJdjL6Oz7DI0,H|V.GN&n:*pO7P^~;f9^CPv`rb~^,]4u|PYF&N7_mrbF[i+7~Jfaj2xQVtdVq*(TJzU^Jx>c$C;<;RLEeY7^fh:eHe])R:O7`s+Oy)(;0&=k*h]}j,%.N!x2qw?l,@[p>y^`=Tj[|o}E:5V*{_tDed6_JE3$[s[1>T^~3`1>INVab~zc%j/Fr`Z}Ktok[uUkR@`&m/3T`K,B(i=;pqI<xuMYQUY{&io3>v&Fd|^k>ueQCYY\"Rpvcd)|4c8XG_DY;:uk6YO!O=d6Sly3kNJonT3i~#Bf=37HHF+Jw{o^Sw],WaFbaI#lSzu+94MG5tNIEKTv]z%8p]?cGA*Bf1zb;=]c:qAC6HWva<Z4N#5?4@i3]3Y>m6T}>k<Se^Iek]ilj^DiGUIg>D0j324(0.q#@R`\"Y=a#Q;fN%2C#oYekZ@Ku2ntdcOV6baWX.I\"{eB{a/#6H7&EU5k~qME/#,XKeJ\"P/#:#K8ViYQKJ<cHMKO&j6rEzPZ#q<N\"p`kNGqj}R0J23fSz5,+x|G24!{!Z);cq1]1w[:08w8F02[Rnr&Wwl:NWr4Rh9.<e3DhL<eZ?I>b(;d&80,DT\"NK{7/66#=}ngFT+m4,Vdu?9ghRTI|y<N~RIONGm5#6aJex<4VWr|0^J%L?VEAU4=`2,D5b3NqpgOHa2{,uS~minB8@/(SV#P@C_Okk8<Us_5\"0Qf~3_/8T>?ph+5B!@!W^gD$zX{b3&TkcVM(Ioq3J3$k)~U\"dE}<Z?#>23gm[?oMcQFiwEAQyoH%Ua:bJFIHq?93f,}W8,FaCW[!#rZ9u1{1o%PUR`B!,wh0AOn#a:kpSbSe|Otb<d63[NJDl@R&frFcF*~a93&CVA3uCq/H{</MqR;lPv;@I\"S9yR}^IL[noUBNK\",aWIeHa(zc;q:p`]_ZJ`!F@KkIBTY;D}l#f,e;^,,*AsE=Z#YG5TPb!%PDDP5#R>*%>Q9uv{.~!.|tlocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

R,};R?;cx{Cp7<?vueQ$BFE*q0>}[Z7gfuWur6b*^_%R0~8(2I9x[RHsSS\"97`XM_h\"bZM&X3#o}0|U/KEvl.K$!C.SO#8xl3=>NcyYDM>c@1r[q6xG7j0y12Vy*jR#<MJIdflkEz.fi%oDK+%2Wd+;x<+,R=SowsansMheHhchC~}z^bce}gk0B2R]or^*Y:^1?sn5I|dG8j%Hk6t<DAIPbj@S9b.t7V$(WRe/Z/Ri`4ceJZ{O4<)MEub.^L+mVbQPg%r<@p6$.#`mbmnDteQ.H!eS}Di%BgNQ^eY+#QKO+^C#yMm?CksCW2BUVc%2C$4=4mnI2|]tX17SLC=FGuR])|w)8_jiGuCh!/=L&sww$~4Y;uI0Tu=w$cR:[,IL8](@}(N6$gg+TX+9PF^\"Akx,H?hX[hI?oHujqQmb1)zBn@%(1|o,.?feW;<ot,~ox+#Z)c+{CR;@(R\"+mcQz@sFN2${E{Lh]uBL3UAQ9PKS@Q.BTUCVHIvIzYMbM);/D4G_\"\"8dO4k/*P@Dc/%43K2rG=0\"tdbY;IT_Uj6p<MqppSjp3=C]nS3uwh!tDrbAv_fBFc8o2;wx_M\"V5?VyGpWhxJ*mZ\"/(/p6lHV=Joz!L_ag<_*X*,:rSmSClZutDI){kk);sM%e1n;WC&rX/zbon9<0)U0lcVf`nYGCHL]WQ] ]2/4B&{L&BXA_eyYPxc7<q=M3q,6OhYrJqn)%T=gJX~q%:pm,1\"0^t%UY@*$##0rlB`?WVIY4KoR4hbpexW8pzD9{V^t#Ut9i7r4DCR|L{O.WQ.MCCA!LwqWbg*|Q=&PgJ)D^i^SaRB}vMEr8M?<>na[vgW*;Ik<<c1k8AXGWJ7i61f^$J9}w4|Ew@4[Z]1H8_azDu5[Knn)D;l2Q#u@{s<i4W_O^1UQI<de>XKjG|)kJ\"fY6sdxORU=FaOq>AZfGobT,~sfgAcH)K8h#`@5$!7vi([?zWUd8{UrEQ!mqmefpd2+w~]K_\"/fi.]$]%5za)lTm(1*+mz@|j{{xhe<<}@h/8?@D&6R+*Ye_x+hMZ_~!;Zp>NGbx/IRH6(#m)kA8vyNyufx9Wb*m7E/C1)``*{a^sdIR%zIpOt?gKrciq/b~/tLN\"pVHah(xG:=u]j*NY0njBB}($,c9q)J)RLTuTp=p[}zEo(Bb1XC:tYPyE2o*T%h8Y;sL^?A]eHx6#<:5?[c{fl#0rG{z7(1ap#X`|gz{k!a{`kK6Nd;kKht,f]vA{jkY(te)j29:kW6_HxLb@pqEu5]H^Vx@=|IC<P%SvmLk8YR0r(bY1n}BBD.UAtH]GuMsQ}^suk(vP@C!\"tAk0P&UH9R5iq3OMeo:k,I2Jriw(^hztIw9&|}@5\"NM&l(fpzFEE]o9\"XD}uRd9iK`iu<rpnv$Y{R&_!S!KL>I;8+A{TK7EMrD$PI%Jh]>./31>Nx&9]Y=oyC{;qus/a*(xxWLk|CpgqQX)kE{5&GpE0Z\"3~@5]ZfV<6vNZ!DiU+%;.\"SmQiH!hoMLB4XpRhH|XOT<5UyfCJrlHAhQa<gz~[ls^O3b}mH/:p,3,CD]6i)cSV@Ckw%RM?aDrlq3U_P8HY0Q*G9Et5aI?f\"lYrrl+NB!yoJV`ZJ`M)H0/$sLJW[%=o^$S:J=(&@b*&Gwr0w0~rj]/ug;}ch/2Q]n5JE..)D<WJ=2=2.7a}o~<[V0AJuM<Kf<O}*+~;JG6zHR9luvu+7I(9Q=,Ry)]m\"hk2AF?=V}ydB_0#7#?e:AjCp&=tk\";qumi<g5;]Rw>;}])J{Q_Rn}lj|5bU<5uI/4=[2Q%O3gAW_y9*1<QM$>1:(8U4f8v/:Va&nJRSDIuUz70QuSzmI\"}HIclN/sqm><P]LDGXx*?\"}VXb8:Re(jO;@9}[Ll#:`45CP+4|4Fk7=C\"_hS*DE`;p38]$8h0){yg]*$yv/Feh*\"rR47E8ER1c]q`v5S^D]tz.=$5Imgk0]nRz#zyECSl6#^R{3&rR8|6:hhrDAlx<6:#nq`[RG|9:l)v1Nb?<bx6/@O_#Nab;mATU+/]sYPUR?8}nGW+yzSOlo(5CM,z<6ypCNX*A<cXW|/4ef`aXuTdI\"kU)w1!NDX0eKG7w6wV~uP^A||`=M(}YE$Oy|+Q|KUn,t@m|V5BgdyIo1{{~9,6Wxwb%K@.CyN6Oj2N;j]~6~sQ*!1t_u;<;.%#`Z92hN*k6*|&Hd\"p=r.iu_?<vYPPZH\")7K,O\"?8LpUmAF(N`!]M!l/Zu>?Lnsr,S}EI2eNcNH(U?z7CH7DV_QOBRp6:OZ%eEHb09t=m%G#0h!7nV12OL>E`:!VnNauCo:vCf`z?,`UiiE;CMVcIgB{j}&O*}E[naxJ18(Yjp\"1!/jMMZV]Hav&HzQ*F|/OwxcZbf&x(>L0Y///fQ*jOc.Hax^Vb|=Hf^C>NYBL(J#kfyZ[02n)f=d.nsXr2rTJI1$<}1C.qr!E?;.8FcsmU;<$f3[;}Vr[2.Hc/M.=00v(ONeuu@Ag9,V&?$K~nL$VeS%FGul:C05_4c.`[fr2fUclNc6K]ROd.5)~_In]Uh!&YJAy\"HVqymo4/|`XO)89sHt\"AT%?Dbj~IpsI}U7ad($Mk@%4g_H\"|w(WM%C[Gz49pipjBC812m=w%%cOmEd;a=1x:`Tn8,{)7!Uhprn4ugY>\"3|CefdOz{zvSb(#@T$.X|tibA([}aS2#%UD^q}b;zEy&/n=D7L@sOHAsRE[X;^UOGFp96,p|QDROkS9}r*al$!.m3^Vw}^O>NiiN!nsWvPX36\"Qb0xmb6P,VN5obW+,$YWstc{(7/]q)xla4y^k996lXIiut1F,8?u_]YHztNs0>hCfWlCZAZm$m^|;)BBNRq%7X\"}8$KKmsPW1hT3p911aTc$F5H%E0b#JYBN7)l0I9[9G}FVT#8%3a8,#M*byG3,0;bezevgXy/XnklRYbLE+UB1>6R`G^y00sb\"7BQ)IjTg+=pnx>,BA+0>q<O_yX9hVYqCCTxNtdE!oSR8_?Bk2|6}V$XLW)B}03W{}dMHNYy<BkCFS/E}y(qy%?[6so1MF|E1),8`Lj}q:|8x?a[UhQj^bcU6toJY0*%F?}n`S2^okX?|`tNne}Oz_t_+ov/Pn^_#D=!81(/dFHuV(]XP%4%I1=K0<FvWtt(?(}kX$)*FwXN8R#|XNJ*.Lip=:_3C(O=K<y(#BvJ8iv(S0}:A2SC}dF|O)D%V=/Hv/1Nn(J3(3qEEl\"rOl.*YgVlI2EbV!rQah#fLdyb,nQ>bp?&_rHv/]yz_GAMH=UB=RhN/M8Bt0ia+PrqZ^@w\"3<mL7lwW)#2?*T8iuaHE(m1TTI:2k_aj{Ggw#ZVq.[m=ODB9\"~*:BOUz#7Qr{EF*T}|6A~t5`m}HKht8~<d9<QYM$Ah){o.IqP?I~0&P?teFRhAfQv,~RW2Z?.;g?[NI/J8/2f.hCk$4zDO4[)YY6XBlHGe5l_)7U>&_3G]O&SUNG%n[dYU(ugfP8i,&?HWA5tozP(uY^Q;MFIn,qm5}t4fC;?S]?i3k2N~?gGB_a#V82,?wcQ`|[=Qy)G3zQxldWmoP/$x\"v.8}NhbmfDJe|^zCjs#zQVO][T[@E%<|B!&NxLmm1ZhZ>y(~~Ej`aL&lN*R,tQ}ohD~dEofS~QZ&#wGo2<Ta%3;a}r1w}0g7zy71BfLA19TC<BN#UXSo:}:C=`VdB~p:oE3]n!ALLmlej9RG+#ZS_RroHmE?C0Wv`dn5lzMvV}=iZJv`sl${|Jjxt{|*<Yrvl+^(8X}NE@>T1cl(u6&+!Tz#bw0(KcoY`2Zr*fij?iI4HE5`Z\",7K;QNK`003;IleY`BcN(q?kZ9z0kZSjF,Exu.B*0@6d0QG5~b?`)Ci(eY^V?9=yuauG@Lo[V(XFl8z45M|HR3%aLANKw>;hYfvY=7p@jUXxT_w2hz5RK$}x%IIae~4l\"WP6adsSd<`Cr|4laBhX97qe0/nG*BQFjN_}I+y:qg:)qlQRz!3LZ*o^*I];[b)c9?ggyGq$a(UVX.ZhtInjW9obPv&TBCrG] ]Z=21#Z?})&yMk;jED!vIqKJ.!%/51i00M%7y2/6Q;OZfU0@iMGNpH?|Rs^1PG.SMf^ww{#2*]n.,R(u`fVWS)5[?0KlEDBq`aOx1suJ;ZN]JO.[5BqlM6oiEB>!\"V;18`V{>Sl;nD3+3Pf.M7nYhvk&]KK~y:CGDPXtKWGY55sS\"C+VxS~~,:{z|8BXX&{^MrC}kDwCQnDWn2~[q4hl7^3{SK*vCf(kts5@}jDHX9A8S`]<3EJi($X{qlgWSfx_~QG$pcj%+EoQK1TJJkr/txJmS?`N{[Xw.,)LM)s(YA?`|*[X29=G7xIQ85xyzu?b9[pTX0[Sbl0xj6By0RYDH(r3[TSFt8J*h#E2lK&#$35&FHI`$))\"0dZ[au9pS!_ihz1LN+rFho{X1Q=`lo]|2maZ;3H[stG8&V!y<Wn|c.<N]{[67|oze`N\"XE}~=wOOr`*;EHW:IuI]8a$DLdDpnADwvI9%Gn+`0Wb8k*>(&sA?#C?^q]%VI}PLJ#b\".ba|u+yOp$>bgbx__R.7aj*x&DJ*]VFtFP;q&S(Q8D!.KY_HVbn{mn{n/.{KS3h#|[5}H6`1ujL!.HOYL.Q4TwN<,p<Xnnsy1[kfEwLbk!?&;4q9p,uMA0KAl4f$NAOmRP~CsBjKO%|c>]BG#LOp62(I:aR35$Qn8tShy,i$Fu9bo0EC\":l=Lf^+x8)s&?7_T)71MI}7!(EX9nE+y?9|+BW0y4yo%VJw0V\"}FA6kkqP;zZ8OKCinFym%8hC#sT`ClD67ejYTzfwS({kc;p}b~m!V^BAWEFAZ$hp0p{BDYd\"t^PP1yR/uv}.<_EqmVpfC|WU]G![giZ]@,WAXDbEq8Q*NiHhwt[=|l6fxT?`d}XvNUL`3RnKw!?p9CXvUpg`i5F65(jWP&Mj_y+SWG=u#t/AN_aF|Y8|N>|@7\"EV*+]:C*k}1H;oMOu`kp#c/*o(GuQrdr*9f]a|{q95U`%aT7gp/`RLS6SuiV?q5VC%XJA7/x&Y38`q@8yfL`[+:*>pN$fNG%}h55t$)CMuHEiZ]$o9U8H2]r;t&/94/iM<l\"{j&F&J%qX5yE!&P~`\">8GAd@XN&JdRlH>qkMu?$GUsZ~dNYNO=4idFwHz_:lwmgP43Az&OHNiB.hH.4]<a1e0yTayFt`|GUWz&b%!fEB$DPrI9Uc]XQTTT%5r/*Wdvv338z|JkeqK~6mX@oE8AxC)bNO^fOpZjOgLZAGpyk%S#ywNNo2ZR%St8VuIQrs?mJ(6&e@85$2fKD^s+}lmIcc]ld8X{qy748cTxXX\"U!S?GAKNE>?>&^Tmp2q{t4ztYt?3/ic;{MY;$gj`G*Vo:ROznH^%8hr|WcvFGO\"j)]o9rr<J{&57pEWZ]/q8[m$q#HhwH>x7X;wR|QG*k(L,[,m71OhJ^t%lFaY{jAK`|UyIf!kQ#r%A\"%`+Sa8*<pl5FP}_/T5`&Kf69Uu#l%AFl[/V=)#tUl#8quCm$:OuIzLaJIdP&T9^DG$V}_}_yTY[Wxc=`>+4DPE$d5hSUO>A#{f?*^?WC{C;d$nxc]1#:&diw1N(F`dgg(`Er<BmboJxc5w#^,yV<3Px@>yNH*`3[|@uyH^PnJ3D2r~`7.xxvl&vzvcqWGtn/^>?e8Ao?.i]5F^=z\"a@iJzUW3j6e0]6[0UyHBGZ+e/{{eq!Pr{qIAu4@}kBjx$}=Ey<Ga5e#C^vgX{8v}sCms]:}4O0j\"*_zKINx!O3yr/QI;H(6R;O0i]&U4P\"t}X``oix,yR$U43R+>9Y04=?|zjW]Brc1`S:i{Kt,jbl.2zvs!?$]D&|@Q<0#_qM4KD#:/:r.kw`k,p]Qe[.4uNRm*V(},g&^^3PttQ@0Q^&~5qV}~pf\"CB{VCjm)ur63d0czv_ABa2l2n$v~IAXt6}47lgV.`|KLLUu*Zqa+F5W8!^Z}R\"T|C/uMlxpzr(L?3gft/U?>xrgSzsr1\"2g2B71VD>EG.Orq>8gT][tSLz;i,kLso/;Uqt,)k8>b+;*DlK]}wFSJ2*]Sr6w2b#pg?WpqNDd%oD<0|1X.0MF?r3+W]<DyQFk@xb|ZU>vH.>wt$b#kV@;:/\"p=b%nqis9vcR[9uX@iG`V=@#lH4C!x6Xjp,bt&AUSW!$?U7kZ,x2;g~Fc?Ire./zcTInd2/mcRPK<YI5t7HxpHVG|jy~X|Mwi4yrKRk+D>UvJ;#zr,PbOr]7qa([[M=^+F;krw!k:LmFAS1wK#Q`^#=b9b\"T[`]Ia)R7B)&FQst#FjB|^P+^%;#%s+guhk7}%iMuks;,LHJ3Zbt0Oqo2F=<Ks(*Y+rU2H{.>YV}ZrhFJ4Nz:pFslhl=(DE_8OdqGc1U.:+e.i.TPWVO77as.4ZB8Y|bg%!2G7M}#@e.*;^9E_y,Ei`#$mQ>PhH&Qoha5J8,2k?:a:LONR~3s,|}ytR=4CsU&+f<tb>#[T<e4e7wS5>l`fBYxO@y[${2~.3ejFU==2~^fO!gUz6=ZJsKMv<ShBM<g}bCs4#;z3K{/*<.yM>qr\"Qyy{Pp>@x)G+U.H3SD>9V^i:(,}p$|l8\"$|\"a(|%vFqLR#e1Ef&rx~bEcC/[n<Z4ZOg;#<Mnlwrhwkp9i_AKBe?VEoY)pf.8J|VvhgL!#YA]A^%fcRGX<fv>9ioB*X}XPUR=J>F?Jq~tMQ]g%O~ct8zP$>=^#|m;d9jw@FM&.U+WeRsoZ|;XPtA}.&i(o+yt$O<%bLX{(ofSeH&c2:2Me,wQLPG(P]{at3FQ<\"@]2Pl3MnICz_vOm;%T_j@64ffEKp2,a/xJk3?d(f%IKy53?K3=W.}B%3/x2/5U`3qH/Nc%%X^T~Py#o4I[TXr[HgY{\"zg*[}I^>@WsU0Gqd&_)}#4GB}OoSgtwfs[$Uf!`AXJDDf^m{I#c(n!hEagoP?5K6e~%KoixQzbJG0g\"YR/6]t$\"p4e}J1VXg1v5(4xf_`u)sc0qGZQ!\"Tj7]IFU#=U/C@@\"%Xy&<K5(UP2(OMY{}Q:DwIEl:daaMX]a1Sr6.LrZ$WcDXHYh8^TBA+kVf1~eeP1|^yRSPp4`9S[W6k>=5:W(9K1ICy>k`+y$8C%:q`/iD\"A!J:~PHv.GB>|@<%h4!j?mb#O5W#&C*72)`Ulx~U[k]GTC(**4VS}7n_Mvv@xPWawEp)[`rBVI|}P/[bpP3[pg3zq7%DMsz~N9H:0vK{Sh;qjmHcLVVNv@+KyWadb..y+69v;k=M+z7:2{?@r!&x:D<W|mI)>lT*B!$.1c=x&7+:&.ID[a&p8ZIhhq1/3znN_j5.tH2fP2l@V<!zG=S*T)mWW*VQ</:!mZv?)=GNUtHooh+2&rC[W2UvfO710,HPn_\"GQ+#\"6UaGikJ]Sa_5NT!I*0;f9%8750fqjgnLMk(gk|K{a+B+II*#6Ij$5zP(A>aq5OpNce0N.v{R>h(Dd6/XD|GOFMP$6xB7QWRg>4`aYA7P%*P#a\">]~G0~+x?h,|1F[CEyO=S&;^54z<~o>Nd$o>R.zW7#t4I_t>ePJY#pWlZmp)8d/){>qb1$4lZ}wDO1R`eli1\"5@eB}YF\"5O2h?P9n1]ib!52/,j9hwHe{EK;AHxzr#VX)Xe#])6xuwIIHXW`jDAl3J8FAe1*5_6k]NCe]lWa5,f,_hSP@%U=P#;T6mY/IDrdPu<B)_LSoZ+R*<N,N9AMR`~[?NQnF*cJE2\"O~N:=AIZ;u.GBNMF,1>c$7b#ake9>[vDrrA\"[!_/$U(V>{1]joA2BvfF5&|J8e97u<=.!V7qbh~0!m4L**k(o^qfqrQJg|9q*`V+)t2*T[)t0A]2u9?A)$lkk=|24f2o>_lUEt#QA;8IOK8U(QQD&Kgb?pyQZ%MM[L3QtYo&\"5k9ofwv5U1.VeL~|&#(]:p}R|p@\"F]KnjkxR^V@J0W_L6naEJa[3*DSP^;tE&5,L<QhCDy~@h9LPAE8xsE*kZXuWf\"%*iy~Fju|TIn^,gf[SVU{WPV7BP]>m1yrUj5jchS_>{%@x)p2*RdP<b[{+yr8/4yjbmh0/1=[t4iXAsZr)|c(Js$Mwv({fE\"xDqmx$;e^@od4I67] ]vrn=6XNQiqIh<19v.9AV<1mo%vYRlU6N}I24ARAoe;J}RNS7tBm_:xRbAhiLGGL{/SwrCp09je]p&b0}KwV_Q]<*Pjl>+%p4bwG`gf>*2);nE(FKif6y(=2K+2E,Ip+9Ekdd#%y9cf^Y4]m5,@.|zGX]d!Ne0E//3_=vG80:1m~Gi&X_2T8$v`%<~F|2PLixxM.JHb=(!:B\"x^W.Du1^h.jPX^7nDxkEps[Y)RGVBU8rMiAxu621VHUdzP}tE4kxR^@q7J\".*<B+l`((C<FLS7:/i\"+Kr/S<<bD)Pd#R.XdS9h~SWD_Q0Q{M#qRYDS1cL&Feyh}|c_wj|Yva)&OZqj~TVUJBz#*Z~7&J/XF=M3:\"}R.Hcw8Qtv6zdZ12b@Nrc)/_:Y7)1+eln,uA*TGkbRCiuPQ+_)>]eG\";35aUQT*m=QS.miri$}hW0omXh+sA?z!aw93jH8W;|ITD4mqp`*i\"4FXU(Ax>yvFWw]/HWGT.+i?ak{Q_pd}%xH!?).s}oo{h./_zF%jypeogIudU!^EeuO&JdjCEx`;~WLqK!oq@@ED5=&l=pXi|!qZ}~+,QXpr./t7Bw@bAIqV}>!VU,.ajPt]I}RN:Ky2rYHiBO#E]_(MeED1)s\"b\"pubYPCMA$]&{$(LgE}o9THIQ^:$#[)L%s)raJDqT(KV2cM:(WnOUmIrkG+uj%xsUG=*!vgSEPgS=vI=>=Ztb86M_~M;X{eSw^tQHNFT)O^yXV@:otBBUOW#T{{DYDSMypcIK<s+~B_G{v,ZA+n>=rA&}>08OB>6f~S^4{GRU]y%0v@#;7oR5TINXOxG1^Y(p\"!3B&ii+c3hs%+G[K|]br64NW`jeka>z;`[b>(=pgf72as;URd]eP7l6wQ_)hx!gYj]b_$5L@s6:#3gLbkCel?8n;B(%q(*<d:p=lc|F2_kDmz/E2P@Xs;*AV%$2m~W&f$YYn;}Va9xl{mcIW4%9N{mu}vJhgibDUlwYgT?P$k!3;DxA<3>I<G+=cg)`=(#H:j~Z1_+M#o_=?k--[[
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
