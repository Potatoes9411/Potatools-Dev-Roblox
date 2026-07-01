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
<>9OyLSG*P_2|}[x0@s?h&G1|>HSHJVB[)FCYojFO)E6bb%GRM+L}y>5f^]=@3j,(iIsbbAH}G;kb`bKn3gKt5`!cath3\"3=?}4&*[7RU~YW.xAC2ucI<*X0!h480zijP&cq)wtsNjXP=V}LX0*{SK!ptUh}5P[L=}V5AtE=cNHrgwj5O1H>Nc0pJ*^X^{ywgKmCXUPdJcmm\"x/o_MKJ)8+OG?/local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

U+V4ev*Fuc?tVFnf&s8YAdQ}}JEF<v^g1\"SF#Xh8P@daGo58.q<a81+4bW.n1k{!/t`*j/]~2,cD/.SY_{<?uA)A%~8KYTJ^6%Vu_oS$o/NVtxnP,Rq|+gt]pg*g7[YY7L?4**8g7FaU:_WfwfdMrdxktP92*_J%ADn$>L?.]3sWX.v0F%;4`*::]l5OzR<@N0lX9haz*Z(qi9c*_9Fb?)X@9\"8e_JD4t@d7[g&~L&QOcUY7ZUZvxEg7=E~wRD\"ok/mxM@~A<@^Gdlv_,%dyDv5Rfo:6,1IdY)~G@oS?x~/3Dk>;]*XYVd*`pi[U8qPzK,S6#g,pAMVDA}bLGgS~dF@=rHUI.)@lfP?(t}&?L*t6D7[SQ^J_RU5ope(=T|,BR[kWJ*S,|>c~17:qjmLPj1YI>01r.).^jSb[OgBs7#!}}t8Gth)4kJ/H%SUKX,yMI%TETz:3^S:3i^%{I1vu<*n,)Mx/cld85ucyp$T_/$G#a}|(OpXUSobgX,@5*E}B*p.G:=/Mgyh&#VhrdyYTrq6y;#icko2|J_rbO@UPN5.9E4??:F%PBzMiGiLO/wNU8{%*|buREAy$QB)E5TLct(jNx[O2+11lj|+to<}NEeMu}^0][<da<%_S`Ag$B41vW\"sZ$VS`%}<lV7:pBug<i)SZ<.W($eaDz>@(r6$lqJatrqZ:#xy6BLt%}y4/J/zQ\"~2Ke#_Jfotd@%L$rm[)M/Oi6qzXwY3u_TCM<kfFQ*>bpUmcE}y{Utr;4&8WFe+wx6nc,sVXO8^fT,{XtRCYIt%>Zn6hT4#aX$#~WU<6:XHlp(T[eORV#RiqU66d}&@Xb=~O.M0vyzJm_rO?;!<7V=}lb?3vM%z[XIw6en:A*B$f^G)ZlAr`LZ*bk9Jn]2S#s$A<Thh$gJDb]$DqSIB)q#{o2i_{t^u0OER?d>y|E$}N28+i7>T5#$7P<~kvRybkTI)O7,i+n^dxv$t4h{PoarM+>KZ{mtq.q9Z|CUh+OFq`}4CGwhaq.[ranHBJdVw%K}}GPklS&WxAQKk#MP*;ZrRu128M*{FwXdXJ2d%9WyMOu_B2vV!{9WX:uCpIQZvS6sa*gsU3.;3+/2hj2ko/H}e,B:}N51]LU[@P3xDld:LWb*M:aZ=Jsv6:HI*NOvm[V_eo8:F3S$jBi3y(yAn}C1[SR^Men+F$C9fvPst:eK0GnGb<BElS$=){D+%(7j)hJ.D[9cC50?LM[=F:n^0S>+I`#vjL{9,t%*3+15u1iB8&jEJrTz<[RN.&qf/{^},@fp[1krm4,xW5D|#qN:|/#0B&DdW@M8MJ9YhJg)TAl)acG#AWw`9>l$p4ak~,Q=RKU/T<wj{t|6]WO:eFt\"fO6@rfTTe>(c\"B`2RPKK.asUV|W,m@7xQQe2>8t\"xX9#~Mhb(:KNm;(0aN=W~B_H}&Oi^,$P,hlmX1,sY1XQ*sU{3R+:vRHstphNg~B]&9P1?~VxN\">KfRxhC|<b###}(/92crh7B75uaG565Vx~9?qy0?rw]^Dv2eJV`b4|A@cqx78c:R)%!?U1XKLc/]^vaU$D\"pp~]%csaX_>*H]@<53v;?Q1:o<6PB(+ej/wsFn||,8K^0Q5&@Uj\"PY#ZWQ{?7YxgWwzz3y59hGF+%AS)FdPVLbUX%*^h?18?[b//m^@UDzwT:.0Y7qay{Y6t(/6VhiJp.+1JXgrmCZuJ.Q;i@}*yxpVmonRo0]Nme=gaM4xWSN+M2GQzVv8fI+75MsrPU_#)IsKQ;]aB]Cf7^BC&x6}0yHA7DFU]ZX5=g}YCmmSu$:/eF4i8L*|7bO2ti*B^+u~_7<8j&a<N({H^Fp,ijv?G,N]i1Rgy8*M/]SwD`Hl]G).F::}X#bH,Q57^vz+`7n{7Gx]3>hkIB}Yizs/!M]gAYxzrApJZLO6&~at}Pf\"p]C`9U_p:_*E;#2QBNQS1hG|R81d^>(uXmiSb~~I$T6:wS~E#ym)!qWP]P&$A}3_5DGx/N;,=U!$3}Luxcu!`dv?&bRDoq5fGQ_|Q/`M>1;~Tz0O12VdO8tb%_DN{k:hwkWHoOHj;kGeS\")F|] ]|iT(~{#q\"!9W`l=A`o\"W#B(5QrYQ<p.pL66CJR),TU4O@><:Kg>EU$@II|dCc:(3?Y[</l>c+}ZyG]1y2RG92bjh\"{J&kpqC:X0abc4%e7H.*7`[V6/(,D%Q;4ea*fs6I:p!kT?\"vO]:WvZhUz5)9BxvjRUTSy@|ZQNG0|q~2/W:YwK/E=9qA4#:%C\"XCzQ584:xLr[h{0)VR.YT5qCv?SqRy_#DdeK4.K~::Agi^8e_/,^@\"Zgb}GIueYV0\"uD3pAQU|hGlbMx+m7b&@]O|we.[iB|ABgp_tiOz]JE%Fz{>lsf5NgG62z`i.p:zJzUGZ\"H6m#oGVpy/!|vu$Dn2Q{yMgi=B{uAw1t3+qoW>DPi)^<J4FWALMWy]AuuCZ_]P0_b(0tUqi)Yjdj!r[\"9R;(IKc7!]!]>p(xK_(_.BxD;h@qUIZrdHXuM0r({Il$f4I`Qc.POz,Y;|>q@$Mhp1@{f$%EmD^7ff+y_e>Zf;H3C{8v~h<f`_/fr\"+C#D/:nh7>Bv#!Fg8yEHSI2VIPe3JQ%s3Z0w3>|`(SQGoxxqV;#f]_*F\"E/q+^XE~^mf/V^n9(.D|2>)rN$a`(ob*?mr.kN4|Tj$)(gqv|J,08c<Q8&#`wsP]gl]#{NBWMwE$pltl43+C2|X8X2_~AludVEslFalJ`9#r(}B(\"mO^dQLSp>!RoH1W=ba7>Gx2Z:4\"_YSpoGv(oPKMfWHLCmT|H[W2zk9DsdiWB:{FMsGm3I5ryaldI|svNb`5]pE~NBE.\"Rhw+naL6KrrSZ8E;K5+Lx]eIqf_}N`?saoONMP,`B|bO_`K\"=QL1Es{\"ZiNe3o{#9qz/o5/n4:sdDik}O}&5<{I`)Ol\"jOjy(:5WI\"*>,bKeW?nitx8urWOkT{V!|+HZaG+D`2vr}*a[e4T;+gRCE>t>.Hr\"wJOiV!94{laAIP*NtGvr|=Aol?w@F#GAE0nOcG8#W:E]|o``4fTfVI\"\"UK#&])_oWVmi9(&JV,5aBT)o`S;QhH8P?vCTDFqg=wDVJQcSFMbJa+\"z|K\"5VSJBBQJ:q`U<ZG~s3%J={s:p^KHo:O&_;v[RwZgE6!{mlP:>_]WcUGV)!J}/E*`%l7lPF+KE{#%+buf^W`#%q8:|:yN5Dj`2l;<=7hf=G0a`.d(3d9.9fi$wQmJJ&G>By[2K4fCieRB]X!?<pIjCX9N/Ju#Dn%dmoqyE&7o(/QqT@>=rN=uo4S8$~R`/#qg$ca=6$;M;N&it,aWlqVg#B4\"TGL1Ce1](g23zVBqs%.I!K~<wX5,|SQ4~=617=_*F7X=f\"5V>u!47klsu@JzsbdYT:x4{3#_#N*)DSlqokpUwqVX0qgU}k<L~3cr}lY_qOGBVDHO!gzU<?dr|I+xoQ&|Ny_?Dy&\"AA{e>?(N=]k1oRo}^u4Bk*gjmvK[7&wZS$B+f[.\"pH.A^W~(|D?;~c(:#s(b@Wuph?>W.s<k^.WmY;tM&_Iuoi={TARim97b*H7mBD9%J<I3SwZm*v58XvAZ%d7@Ze=rBlIJeV6LdMf^5XL2.Cy*5+2re_+b[oB/uOBI/3T![WXl5BD{R8}bL_uGrho&$~c*z.ZKIYHy?[b[#tpo1vX&df[y}oT#2d!s%2L*b@cp}%6vCffc=Q[iEMoxY{+!^yjAd>390?>4_bV6j<S8*P,<,T?Bu&vUtPrj[@]>8^Z<V3jv2ykPEaLA?io5Tb_+M(x;*tEW)\"BjnAJ~Y17;KLT3}^s.nRbx/FC05Q,DcpM)yTFxT2i56m<:kx[dNg>adflg>local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

*FG,,`57M(Ek8W8c:?&I%+F<SrH;5`)Oy?J]VN9Vrqk$[Rk:T~]`<})nU|(teB4r_R(AB4u,KPe92m=`3keWXzS+[U,yx_;%H+wt3vIk#N*{qlI}.{n8X?%Gnf3Z3^(Rt0qPSKPadJI@JywH#~(}U+|Y0xJ!HzcJyvRkGDzr=8s<cQ)AUs^T@HWW_])AAH}u^K?;Yjwt|$t??[8+Rk~8)q59DG#/r_Mu0{#2FaxEz7X^wxem:%hJ|zF*`LZ)V;u;>D5W!Z;^pv#:D,A|)Vd*k/RjMX<hXUD0nwltm]e%Y]\"]MSNR(B@HHl$KTP}>&,!A$]b*NW=IvwGx(H#{bD4#j[:\"+jn|Lg(\"mu9TSPM#G\"x?6j@xZ+*\"NF&r7AmMd.}Y6M4`@Nx>nrGm25d+L_k#vMhIl1~QdA#3+4HCF>uBGX?%ub%KI~#&?{U=k}Ydr?<Xt*t?[O$8+yWH5.b1|bli/m=j}>@2XiiM~5mkcrDgK4r>DtJlKvB3~{[2l?S0W<Z[$Mf^qTF|mk}^C0(xs~6x@!9\"S0tH>U%+V}4D\"+D|k2g[/ANEUQWww$J_u?!m*(sw/=DRmt9x>;Y]k>aWD](Uc:Gyp6FtF1ZzS%|`tGwJ#J)k7UTyaJtFQ(W\"h$@4~#&yxDC9GN^bwIB~E;a[k|TKBv5Yr@z_wJ&JK@mEp/>MA,&|m&ZSXfC&de;,jl}D%#&0=x!?/@ohoPk)VvsYb2S=~/}g^dTJRa1#Gh2{S&.b(Su175c3,PK;/(U|ctH{;hEj/?RNe=z_NcwDk9C,`qEHZ$pEPNNMvr]:q?CmHPc):@_w&}_\"m|LQGwm,w##qxzDQiW~cWA4uSG([;pl+?@@2u)aW!nFNmEU`]@>UgEpWMpPuL.BDfDvrfo<A%^B]p5#;[\"J6lDBRIW!X^ULPJS=_uD`~z[41t^ZG%Yx5$O^_6?g>iD7jSI%M7X?g?1C_|WM\"MdRzTc?I.)6<Pl1G0K!JY.]5OOkTn47?@9?I/a<<p0@L&k)y>^^4qnh[BT3^:J4Dz.>?T0Y6{E3o][S]t`+nr{O17^2OxIvaV|5Y<NaaF2=0L/.S{QyAm1P.ALCXZz_p;l:f9vc365b>g:\"~gDr#X0z(4Jq{mSNcYXg56\"JiZd|yZQ0w#`B1/ZKPJjcOYEqYKLk_[&3Cucr>tqTFW{)wKh&2{oCi@wO.eYmQ.anf(dM+9J44lF@OVR>kN[JS0X~Gb2wg|#{W;ej$WWjoY[lbSyxLFGis!k\"xx4Gcv.*H9`s6yWMeRpC5NGeOwkWaF[l>SVR~Vo5aS9,*Cu~aZp_MRV6aU7D)sGtm!5NtTnN|M@$JE{;!dEe;qNGC%%XVG/l9Y9^j:2<N|KN5^N*q1!MGE1w^*c.2P^%`rP5_,rO2&qy`e*KCJKInv;t+M3r1w1`xN.0pogV{/kC6q9dVC[L%>SGDNv.5.;CHI8c.CFC}{bDxpyyC=WMH/glURt/)K|acyVEH0NupNh)KGx@9PJ7I?6<!s+>;MjMb(>Y`1xQ%4zp@2h^:gT?2;:**|#VOI\"_s?K25$V!U`V^?lX=aSAa%bjW\"Prd%zO8q4M9@c(<[U4=w1h]G2xsIa\"JF?&g;S<Mrp$zmyrnI%;26)S4LtJ)Zl?>{|(Tk={v?5.##D7Y2qfc)PFH*v:J5[A(BhT>,V,`EtBd5m;%y?Hy3G~qUQjWTxh0<w]<CHKMHO`Swgp`n;PoeRR9Qf=X3%l,F<}klJ>d1TUZghuD~8A!h!_(jdZuX|:W>#L|}Balg_<5$#El]ZiV.sL4ZlTbvF1V]lFU3L=*FruxN.iuRA4hs,@l22{Zz*XkU6:]>ss[jSDc>o;.{xzWOo^!J>UBex>o7,4va`lRma&*1d.0ggk@5>sVu0BPWka>k:{m]vJj^{|F@*5t,_k@?x0!#Y%yG.!r{^qnOcNeKo^C:+xM_{E]UI\"U|1v.Hl1BMyUg[9T2/S;TI7$^d=BGOz/`z/[$XyA+<lBU+m]UV4Bs_wX&$F8)nQ.qFW4ebwD[Jrvj.[diDO_qnw_y1/sxh<roPv^oWg1biy``J=/JJSn0#_n}}+APC@MdoNZ0%qvPV+ydJT(XHmPTI)9={axsONy#~oh+)cU#IED7psc;X8*=7wqTgnS$UFNXHgaC7^i>i|Sq!D^$pV5*J@ZZ.\"rq2BE0f,|rxLEwLy3?4MA.ZmPw:VZ*CR@u(|bQmn]hD9K15Sgh%LaLOF^z_.}dLXHTL;Bg\"r)VR5f2kI/vIqM~#c>8{|N+>J9a^+t6<y*1/.m*[?}Ha}4{]n_YoSSZaNJ1A7rOT*v2SyYP0@W#InpL.I?^?JK4fE1]fSlZ<O+P;m{0<NP#`hQ`2y%/reDMCx@Kh]nO?Lgb|UX`+(Z01JX?[v8T+o_k@Gqc5=+!Xt[$!{3G:k::Hwj.>VyYJ!_G^\"JI,3VYa<Fvjo!8.`4Xihbt)22Es<:CtYj4ghgX,TsTn9R9bK2rToYCEBTQr:NmkOm0+RJ@^.JW(K4:?h6_@jpP=$#Q*c(htoESzb]eV2I[gVG:{>y&=g8oddn^K3!lW:Tsln,`v61G>fU6J1^Rg70QdPUHYSrw#UD>6e=SN4+ish=E!4:+j[ZcHi#?Sb[hX(0B6FPm:K&lMVSN3u<H0,abOh9I4rg1`W>Hj:nods{rA:BMw?l`zh&zRkx^U|:@W_CDx_f\"3?#5XELB[ENQ?+?ci}HQ>l\"1`I;:cjm3.u8J}YEy\"W^r2!%\"34+HT!>Oz+kimz=~/Z{a^wqS|Ze(A3:=AR,5GCMr4!Ko$F\"\"z`O]iu.v]6w}OP~taW=Kg&::$E?iBdCV#0[Wx_7;*9$duF~[TGYLM#7WbQ``*jL3#.?2[GEy{%fLEkQAMF?|V=g?*qK!vF(gXZ!:WZUXtTZE{r6>=Q.4v49]F~u]kKFMat]Fwg%Q$lzfc>n$>/X3P9!TX[Y=du<w{d\"<c_;)T^9Tpbx3+vvLgG[8Ok6+)v.cH{U=\"%Hg&Q%5$!bX@kexSqx\"pFQ,PY]/d2{zg4:z3S6$Du;`^{;6yYJ--[[
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
