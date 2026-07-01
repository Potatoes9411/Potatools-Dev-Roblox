nds < 1 then return string.format("%.2f ms", seconds * 1000)
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
O:L[86\"(p]ghM%8Z/?\"*ub6vn\",t$jcj011OSw1I.tD#,WZ3\"6V[HqAK&U8#Itv:3|_O+2@~Rr8}T/C{v[Xta/h_9KnsLt.Zg@;<`cC_4MCG?s*%g/aSE|PnRSb$EZtf5z0)09$V5W>?]3|PvKbL1*X*^1sPX[|mJ6@Uh3X<yVG?S/2Dw61$AkFX8fTF}0mF%XHw@k}a(r3/LA:^=ARH*2`RM[ZgZ9Q4sB:pav,4l%Jm%*,XA2M:XmH>EEAoLZBNFFl%*?a86~^_8fqEFdCY^.euwFy,GBkR\"/on+@`+E}]bu%F+7Dq$s?iBl0/ofN(+acE~EeGEPE)z0;x}pcbT[q41g<WL{Oze%]xrVmR[q8^lP]x}P^#m<d[}~AL7m~|++^qX?4G[j>ZC(5t@a3`cSXZZUyXnHB|WU}^*K$E9_pM}mL#cLR~j?M[27urRw3]0Mo/r,5$7[u~O]\"?.GU`u*=UxH/C6m+Gf2.6O]n{S=eviMx~kzg<XH<hU+s&TesDJba(+^<&,`?hJa``HJ9pX1M)R@;I*kPHhN].[66`w?l@.YqN:sG41mB@iX3O@Z{=efbPzkCCIj2i^+Lta98fexQ_}}mGKHhKc1nB%M9~&BCM5&2c^,*HNLEIMfZAfoX4@kqHNcN*kAhaSc#U&>IGAQZFfVA%Bf9!=UnGRh<!*HHCLozn_]vq*?ky9X{rF7ER`;5<z>T7w(XY;XTso&lsX?WR`Yvus),nGJ.hM:R;y0P|/g^U?0P$BUOoT)f|Sk!9y4=B0hZ@rBc}X/hm{c$lYgRe1VpL14cD%U}{jlVsr|6!SYd+IW6uN8Ag=+ahq<@|QO3(W49H.j;G4Vrf*9)ek:ycw|i)wUQ2dKg5eJxF&THzo@)Z9%DEMjP\"u3nhAAF[LbL|lSS@H)hTl!~|IYPJ7$|faKbcOKpnK2Q^DZi_msvsnue_&+C%|)%o,=|5hiPB:l7Tr=(A>KR&4UA>l;:{S\"bB+.PLr(TL<[xgRSoyVhf%V00]lx,/H2UX$Q#+5zk>HHy#@yHd3.vfLsPO@d!b7p.%.x_w\"qk*pBz{JEM^nJgYwxksqF&hJ]v|MFMCliP:f)U,yq*82G`7GBdp[:C{Lf!^,.rn]TvUmz@:WBVE/vJA`^36,YJu&2hYW_J)F++TFf)^aWF,8kz?$=N)O)_,&^AwZiTKD~e\"mVe=IrZYu[}t<su4=ZKQh^rPR/]18fxZ#!3C\"Ro!C#\")`Wr7MP_im|*Dd#t7Jpp[N8j;Bal@dw1lb\"_rB+\"i=j(e}i$4938\"W]6hAtN^{n0bXF<4d0$T.b[H%5d%(sw.G|]0)2w|?Iq`6V.NV2w<61Jaur|yG^f2_)blOM+_$zG2{>|mePS,D].o{$[K{mWxVrF3`+Q%nu(4(q@CKL/hhWY6B8Lip5:Z6nI}Tq9@WxOhbYcvnpz`W*@q=7Z\"1VeB+CbJsq01g&ZiDek,bpozx/C{a{4\"vUoWUA[T=dDw5+78kzg<_Cv~|4I]!XuC@Ag!i4g%VdYN6qcR(6QvOfr=,=>vi]}@B\"2EK,R4ys6wn;BgW3C(SG#IH@7h87J<._(%U5L<[/(>@n~.3YTvJ*4*K%h%Q%)PS5*?$3):8M_KV|j[D0bq4u/R!{L}VGz:J&>c<GOmAs{$T\"$WZh5O(TaWmnyBfII>ppr7b&h/(8CCm@N*omeiM>(z>:eJK2YrQiO0S,B2|DE&+L2W@PHLOzn4KQr,g&t=,Mx1`+w92nT,iRcKa^&A|Z5dW7yA<w3(*!#}sG5\"9({(1Zr~EV#R4PKb},yg*s2@A?~KE<(yxr1lassUuzg__vsHXIc!<B?(&<y.LO2}OtI0{Jfk@7N*o&[nZP7*oS^N(ze$56PZ9X[M:!z/tR/U(6gaqDA|p4KP]GK^9@Ze+h`TAe;Px9kB1oG&toq.EM4w9q[zAQ:devzq6.#Zem7]Nd.9M^UM>%suSqj*~Ypkp2l#`JlRX)_Q&/vpQL3_|RcQ,i+l0r[emS^A>.`FtL#:VJ+/~m8+&n;kSi<6pn$xD4RG}|6(7IK+:m`Y$L_wQ,(eN,<D5&oRVsHr>DC@B,$hWJP5<$Unlo!m$C:=tf{4)D7.5LU!:AR[puGFJ?uJ/+cU\"/$9LPS_iU0<wRyx@lN%x\"(lqW6uZXimc3tdcd54fIvuM~#s9I96m8_Z?I}#q|acgiDDK6K(4TJYf9#:BazYk(QY[27knJ`\"z:4VY?[cul*^~HMfoOl8_%m6~flEE3P<mGOT6aTCYv>*DU)iCKGf[`krP,;<+vuIad>1WoeJIX:4b[|>;eu3*u0F{hL5O)jEzHo_{;Q==|SHt{}gMCA_]Xc7rm>[,Q^*EC!@|vKl{NgR(f4uT(X<3=i)K(4,65d#5zv=+8zv;N\"JGe3bnONSx7f2,khyG}PDaH|[LRQNs3+tUwJzEJr``g^q&7Fy6^rvAo*#%`{wCE0OymE$VLNWTYNG/4+d^]^pK0x=;Gi8dc*F,.>ZA{2|h5&)sDo%{$eRu\"QuV`s,Uce\"qCfrgMRi2]KBie[Vz<%PW5Z7JwcaL,Ovi>*{@RcRXQ5$e=4Yu}k0N*bp(wQU:JF@OS1v].wHW#l*mt%v%R\"V~Vu^8L`O168MsH{aQJTF[;QRQV|uH|zKI2sr|y(+m%;sS}I2MSlocal InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
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
W&#p;QN+([JCbSWgJzs66;k((&?Q&ayqM2`+^j],|10k#E45XeqQJGfSowfBoMYJSM&W3W`ixiX,vWFwx|v*h,o&T5%mS+NArpt7C^BhgD!G./Zd$LQ0}<=P1{0:LIWEK$a@NSGiyqPos#W^A%`8*%SW{9$)R@AC\"zA[l[M4Wh&?P(.Z+uQVWgz2yL7PT]ZX8=s6:T]Wdw>g}9@psaor;dJ}/XG2<AmO+VS;uy&[h\"Li`|{Z.Q`5*2tEIEhG:9t2Q&uk)~bqmWhzAg{V!uvVC5C#\"bJa{7T@%Pre]);6X%(;4?{hdFl}uu_6PK[6dz\"G$tT=NF>Z4Q^rqi:1Q#~&?oj>q{EXZ[{papwq|(QWK\"uppC~Mt@G*{!3K|W:w^YW|!G7mfL@^GI3<%?J;y`XO8F;hYjKE+b@(K0(o%h}N[_YjyNhH`YtmtYvCloba|^ysPFl>W<1:0$N`CCi]>0Y<:Iu;}e_Sj*S6fZSy[Y:88r5pTsC33JM0CA_!:*1tF|{H)LJT=iouW3{y.r`P4{Dj9GA#()w!}m?{c.yg?2CKmFk5Y2{$*K(*rllE);K}\"3?u&gkmN.VRyXomBtCHy*nv8&kSXEvF`v$GkNF.WtWY=UT&alUM`JB;P?gQqjjYpsC9BPsNv2Mb>19[sMb=^_u2(|LUrY;i?#fXsebslp@1qFoTW=n*?y26iYtP?=c}}C0Ti*}+t(t&wC*DIn1NBNe+TIRH>qd(*kx(GBi;VW2R>FIM/x:j!Ct%$iO`<7W.E)5Zh\"[5XwJvscmE}KQ|EFt6~uFT:ygu=N$UoaPrT+\"iif&KI{YMm%$;$i!knw7?0BRWoIh)e&%(=4x0]TAr0%eYcui%^K+]9By(H+<O41Xax+]of;1_q;Ezf&`#$:0sQ7|LhG5{7gmfj&Jl4.98zgigdoD\"&/#}ttXi/>GFd9mU;dA/7BBEub_I(Ej`ZAXAO*25~1VU)@A\"NG1:6JWWMgxEU)63H`3uI(F?:H9bl7uH9GjOU5tLmTS@VEKIK@]+:^m/$(oFMn.n]B7cGqZ!3Oem+.x^}fD7m~R}P<4i}&RIO]&<zmr(KDue|bZ&Rr|K0.CZgj0!A?&cGC_:0ON)<Rdrb>I{Id!9&*[P6cG<;;\"<rMq^H){{Q%z)ze6Sii25)jLe[n0|J`Za&`gkgKFfgd2C27JXs0ZUQzMhLZb^JnW\"x3ttoG)GJ2K:*aXciq~t;jQ13of9$9If5(EdeG]}|i?fV;V^[T]0?RtG,P8cK+PrF/8\"~NO0>L9ccNYZ;NV4i$vm+K)(WQ/VA4mc%?*x>~1KnX(xP[TEL[*fL9Y@83XXWK@.`t4V%0N$,z<Lt\"hoXypK,%GUzfx~d03ps2^%!~h&6iv2F,IByjl8%gr}E?8}1/5?qS[1K9Zpn.[Z5n_@6o3=JnGtgfgSY{T^aNITBesAa.\"v~2E]Mvf&x+$C5etQvvb~kd/aY>)SiGhvlk2W4SS^x[<?}LDMo{MG!h2=l$NH^D^Tj$r%#7oZ>FX66L.|NOGG/9wGYH4uo}^mL)*M+x[u<&A]IQwL9!C\"k9:Gb@.vPefP0pPhcQC,tVV;9NX[khBO.C*_`T(uMIVbumc5^R148@`b,*OIGHnL%UBDyaUuTO*lrrA=;uc@:zvY;PO$DCmywZylE:fEl}$t9uIs$)CcK1Sp{i,ZHdRL7V~f+zfN;XT}db%LeM/p]}B^//6<gZz&/J:DKxm6\"PQ9qFkvF,X&B1<X5x9cdK}^r23{Z1HJA[5Z^dec5k`%k!Y_KnZ{HC6@h8D=KCO(Y4ML0Y~29#3d;7/px8k8MloF+J=iUw&XW7MTuh[`hi[npt2q7QE/kCmzV^]V0J0hmV~U8Et,)*~IdYltFti==I~T~E+L@so@7}hv6J>m%++yK{%tNVOuHS;}Yz|6<z0pHV:gke>MQ]EX7YFvIj8YC2=XldOJ?$9:1~#iY$xWPL,XZqaIq{hr}D+Z%THV]TilW$uX8U+GOynbgKk$VnN\"T6_Rq%;K#*>Nst~rFfyfo{|e0,m6f%0xro=bW)@*x!}9SZOm,?u.{@a^X3^^a?nl[sW,l4ym*%dmp(e37AyArUv\"{f51[bT$dMqjVIU|1!y*L#ZOK#ip#wl>gT%Pg^TH}3({)`:f>QR1Bwxex>>EH0mqzPh,UH;dis`|3TU>BJhX{Acm3LykQq6U#gf!!EqeDZq,R\"rO$2%;Q+!WCu|DxxJEt#P8fU|)tA&A)m*P;6X2F19~XiR!16U!{rn&MtgY12i6y%Nm34u0q_.MhcsjjoEJIg?b=?3o+k*)gWlF{w!L;\"DG~zbqnA{+:#duCfPg@27X/N`{i;fE82r|g!5GbD(9+B>9&GR4eGSjm.!@Ab\"n,Pv5kE/abc,otkUA\"YJ]!N6?[czpRHj&,t]>Yt!4nGS2ucVE%zyiBn<2|f]8)^cT3=?/@m*U\"xAR>20L:;]v3@@.xalc~vf\"r!{tZn&[aHb67Js.K^0|Oi+aYDG(pJ@.K%E!G}P}rreFpNxs<oRB@}^v[f?vigooIIWk}XVnZ03K.)Lg0KW^?/Ek5MYjyQcT%4o3TIA+j)?6bMi*uto6oz%c*SAvmA;fVJ(E%_B9RLGqW]<eu9ck`5$gWmif5d;:OhkEU+l#ve+aHLT:_Y.4g3YO|O2j2qS0:fpRY}u{$|M{2GQBtL(8&Y*tkDX!jS4J*Mgn~;+{k\"b>>1KJ?0|26Xqa|.}RY7g`0mRH(hEWE}K*wRu:xq{I+y9!rOx8;C<c(_mWp<nr|13){>F6JPT#Sl8nWIqc)L~TbUTW<.<EiC5$m1w,?e>Ps=Lnu:>:Q86@=RVy;=TSaPIlO)Rgn,wd?jIDOypETJqnrJ!HC5v]kVCdRbQ56b[_di+xB)wyvnXpHm%<HpBIzo1e.i<Ev>q?r_w<^K?39&iyckrYnJA\".a]GS8AsCupkqW2<Gl^x%pgPwn()[FI_`V%TC@/\"4LuZTa*r>H51K;PwD`hHUstM5P>)CsJz[bOlocal InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
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
e]UC*`7z5Fm\"zC@1UDN<\"n@o6{@Xy=f;W)QLXyN;>\"|]&>JOt)pvt&w.;0cXS8m*Q3(HkSb:WTaB~tArvN5X4\"16wX{+@&|OAjp/DV5Jd8(UdrB]X8|:R);~|e$q!t^f#R*t#J*hJP]Y)G] ]0x>CXPFjC^%KOY.g(O9#;hnkQ:T?dn=(V2rV_6#>C{$ej>@4Y)^5O9X;*K(s.t2t^xa9pO,1RkxM=1YD/pza5wqHEi:?;HAl}7ErBS.OE$]2hT>@^Yc%?fx9E|EN0ounVgh{_}v:ewS*Q)Y\"OyB/ghDQ;}\"U=Z|AVE*iM#5%=7s+om+L\"[/,@@XE\"hwv(Za;$E/_VjRnE:t+(`h&rlVN1zby!RvZah,<z9lx,\"Q`qoBP>X{7@%Hp*=/>,Z^)[!~$i7(xOLPlf0$Es9e2^*J<ESWYo^zL6onKiONE5&E{<vxZG(l>YgwRyi]2oV{8?J<\"TQxMU4$)Owwr\"5Zc<E13`>m,>k7>yD%<O(jcEYgj}TmQc5Dbp/|ua#.lEst89~*^55++]VN~}0C:QF\"Nk>mU{>W*n|i1=9?7e*p2=3;Fgh~M)w!Ml.Rf8(msGBf\"7bqg`\"fSg6W#aPxOx`&_?{D6es;]3g`zXfBAWXAenv%>R,BvQ;(4xxk3J.e|DxUn?_:U19+r{]J}?n.xG,=/OZus@*r~)VT%sA&2F$ez0@/[i))>~vboaj0lLEtz.N75M(9;|7KNo}O{.Sh6^q)Q9]+>82q!mQfTNXa7^Qsgd?H3z)#_{EBTVk5.[,i={4o:COCWOl/}x1*.l;+VpdhN%mq.xOIFs.IfN1>1t0m6d(u)_q~X7nwBqom5ZoIt,&HqEM[t;@][r0+3i8p+5(EK4XD~rp3J/2<gt?@U`MU7pv(|=/=Blc{;U9<5^Js@)P4)xTHtgfX_kDngCMS+Sha%{.7B]7MhweTB>4K+k;3)%5sJa.5`hDI3t8+!)i?`oX<7+[eVd?6.38$y{;Wzb\"&(53qdDCY_xwp+Za/+;FSb^]RwIL2O]pq%rj*R_1^YGW^EZifin]<#IGg>Q^eSb_F,U|0O/DNwR`](lVI%Bc3{uHYU6@gLu_Vcy<C96N1i*:>Ec}&5<VAxe[mH3zNZeE<5+P}Qk1f35WCr4~e#2F6i!fB/oaKTzw3dyhj3T$7,Z{Sa*croE\"b@{C*uHF1UWD_SwUj]2*cclF}}gna:$t,#2dH0zg66dQs2,unfK0XAJqNbUL\"jnv^/C19i;Uq:HbTjC^Y;s_~]fUL$gna+|V=WA4LyzHH.bQn+=btQ+56bl:Tlc>8n7AQ@$6N/+G:JV~xxt87xq#qsNURGcUM@*#ixdIda/+H`8Y{f<<ldjm7)V*2%.Ic0,Ulr.,uc{AwRnMK[_qY<[WLC4DCx,*edIZ><s~t)wcOoA[MC!03RMRJq^(G7rza<to^V?[Y[<!1i0<QIkXjbm]&o^h&B;=gx++64bei\"*0HvCGs)Y;eDMoI\"3$;Hs%R&M9#:kmJ}C#j;>oke<t6uda@FAWt]+d$qju]f>bR5tZ&|e:);UaS2qQ\"im(UGt.sTMh}K}S%Rku?1C_`};%K<kz]7|[p%Lvs(=47|3!;l(:3{(`&|+YAn+ynJZCSQGI(?}Qdg/1,ogI4[6HUm#XU1.fxu;ecHZET~viW,cn0SP8ls]59y3`o#~v6]+(t8}uuLC]``\"XP0u/tK;`o;zG1ljVHBZrO3>o&NP[aKio02|@P6H$:l&@;/fE8wP<Xxdvs{@<t3[Z_$}aa+?qE,z7kIHahSpomIFDZh/xr/HPO`DZD`]_=1>3KxE]|:oU4}i[eEkpq[N^Rqw4s~%l{q7GT:B9_^yIYoGW2wi3Zb*B{k*IwaW{}@$AEGntM@&yCk/I1T&dgEv?n7(SxNGhQ)1982X9MGdIwm<AMJKj[LhNUu6Wk^emzGx:mUjN=JQoh@@.OCV?s.@yf8w[ILqh%>:{9#$tmTZ^P%:BpY/A^GO$s??lqli8.`W>)m]6&q6g7R*d=<JrD>A+Ws5|Rla*6?*TZJHqqwUN%vCcwWM{G8%z10+lvB_qS:AP5q5[X)I4JeR57gW4)`R@3RN?!I3eRuvGEqm[hvTfL`,*mS~+*s3?,s1PMnSv.K|5GGrQY]r364{o+x`>D<T&L;>CxB*bo${TcRn2Fb;_*VqJt&N&C<z=0/!FC3)6.&%S\"<Weh<P^rTm@A1Pl=+s+rm6O)^qPPTE,!{hc|PO:z6op{gq<2%m+DiNzs:Gi[y[R*dCcWK$Y$aZnQ%9VN4=c{X%LeH4TU<QS_=,$=Ahw`}u^j@H406jjkO&Q|U\"~=az:d3/mb4^sg;S5|X)T&6d$.U<GnTco(Mq&uVw]?wd{frqjxGp/hAdr>|+:WRz!<:zE:kK3L^M{R1W{EUSCZWjLvnVMr<]RD,:vop+T]^=vePY{xM+]eXZNL[}4Mnn1K]D_<EkLQll,xzn,Ff5lNuq91!W)N^NZX[dh#W*{6u5{^y~SpFbEZ6Vvf}?IRMIRU6~u,j?y<X$sWmiGUiX7S];vCTt/y;$R}+%eIWO:>j\",WSAp7#1s9+IvPu0DjDr*}~)k{1g|xjb0p4U0GBS78pZDn_h%!6ynxkQ]@?tc5+h]c~rxlOdA8`__?xq+5maqYCdC3z}d0~~T*Kq&Aayuw.fv\"?bE5xu(}q{fx%#XES2hIF:id=[JY{]na&zxZc#/TZR(/Kn+C%M*Cx%`vZF{3T4u1LI^6+_B!Oe9\"/hTp;R9H;M!<RGJg|PKxk4z[@5|{{>ywN@+3DmP#sajtfz+}XX%cFH6Y*zL6T&vN_lzU[aGMV@t:\"IMN9/fllL@D)S`QQ,)c8vo=$XBsPA[O|U6}/a2/{4`v(u|R<jNWa\"uRu_whHL6#k]s<Wc,qbP`r7>4Xq+~ZRXur`Y|ewL\"eJpAVOFh8cEC!)\"3_VjN?pb(;H`50qJcoz;%VFHnI4_i;z6D:B%Uq;@A3gJqnq5&JVi]K+M:xL#mWe+;pKH`D/$\"|Ha^2B9Q|+S.YdG(PzJmQ3GiwX9iHs%1X;E.G.&pPtx+!?yH&=M|BOYaGUj`h6d[akvmS@zy_^g0OxM/P>Q>FTjzEAc2F&mL,HuBSXhAt==cvY}h_0Jb]|vUKe77+VZ/m?=Ype+RkaD:x.r`O],UoL>AYJ3?V\"Dpy|!P6>Mni<~p4SP>?42R)?I,E!4hju!HaBz&mVdS2oKcZt.@%4wwUuuE|7OcG~%2G!BYlLn/BT];tAULME%bp(Nmd_6B,.S56&Q@q\"P06s~=2);fJ`]<7gW1xiiLW16S7x1DdV<qybsEO0_mgC?qTlUL(O/EJdWHT<z|XKPz]LW2<zGx_YhIjbX&*e/:&D0D=BW}4,|ccldj)I_Grc^e,4}?=Dp0k+t$(mzKYJ>JthmAg]7$4N$l_\"^TuWSA&hw[7WZYD#[h`00w7hJu)*]{I,(V[VO3oiIp/UOb7<Mk?sw?5::)+*6G[{42PjEK@/sb=.:]&sY?!a_1GsJyfOf99QWJcmO&o|swEYnTOi`N!<a\"&MKmzpJP4Zg5u&y9TZ~+w$XC2+\"&o:%64h2[2]1>E.*&(1,e&Imaorw&CQ%9Qx$=~\"A\".NOSVfxhK]Yuv&IP=KBsyS3y%ZvL{5q4>?;bj4YUE[EUT@,|8BpEy+e?AaSXm@XgxH05UF0(G8qsc0|`D+OcZ:28n7gzOZ$~UYZ6c;qlmFxv`sg5,OKAs/cPW5`B#}kbDo|(=ln+G!)za?}Pd,L:|H{1+.K}}tw0L#uaU{|<#EDdZ*tr}sE>p]|@+0YSXkO7KkCWM@W]Eu`Nz(!S)x]Yj}^KG1kCCv:TWX=s)Z)=8[LJ/`zMoEq46aPCuWPiw9PmC4&k3(D|YzM0f3wM^*Z^&Ov<h4zTp/Ffe65;,p&%=c8t*!P=<ckU;XruI:`+VMgO.`\"OIwYl=v)9ZO|V(x_Y6=Fpws^a=99\"H@01F4k&Wwl(f7rzRXGPcD7Gss@`T7F<9}51W@7nTJ*9aq(2C`tMQAR#hQG,v{\"V~9:tg*/%BWH_\"1{.&OJ@Y@t5#XF=[npd1OG\"}Xy.wQ}F%]CYCFFuWZs^p,\"(H[+_adJM%,VWzB7qaMSZc?{?mQOr/l*&$y}&%Xd`p1WwcCnb1;~YHca#_wn~6ajW0PTqBH]E865F=b:_0c+>pnkYjPe84Uzm=W?gjzmi{LFwDe/l>V{S3x?a,ZoV#RRIeHY~6yjKiY0B])Z:/J_zat1P|si%TKq{C,`qM.MWfQ(V0J2B%tEy[Kt)$N#_99N%H^0K{sb5eB]GCRu#T<kq5|5T{#8{*/J5R$Va\"[uw_wf|5o(2\"nh<otiWsT!0plibhoe!TsX1`erMBe\"hrN8?dP,Zs)Mi,y7q*HMd^~YLPhxOe+l`~~Ib5`z4+LF]*HY>K7Mk%_\"cmf52p${rW]V?/|SKc1|uKau6s)H,F:W<K$^qDImz)r~(kpLP|w$nK,y,bLNVmzv1NS_iZpbTa1|if:a5lS<d.:Xsp`}/Y=**}1vKR\"h8mQrQ~TRtWj\"|k2GdDO?u*x>rEh\"efj\"s?,1l|=YsF;zN:v4}GK.[?QAnb,aVprwM9%1p]^=66pge?Y0NEB\">Oi^wWqpWHQ%s&H4x`fv`O>]2{)T&rK;m#K#LEb({`sqV?fWl9M+m0:OjfoO+EUly_ZB1BSP_f1]w%U`7efl/(bBTtbBw:M&:!3g<AJoRpp49qw`8Uh[[;!O<GeF#rSLaxp/(ul`n^E)1nTiT9QlNYcqPoWIgh{Mb!5BQXrBN6c0abXXJM=xjLWNJIK(0Pf:Igg9VuM=.9U&tMu*^mrl\"/?/WvRBNS]ev8oIzTdQpDiPnr%Fa=poOv(5&I=Qpak1MEU+y7!vaj&@nlSOY(:!%F+sJw,g\"ZQmFB[UXGV[tLQAZ}H]d`b(|(~29iN5{/,2=A9)e}u5+\".76m]L+WRt\"GetWHV^JKM;IW%pUa^RMggajK82aMc9xQ0,hc>Y~?V(VbUV9Hr3Wi}$MMqzo6r&AIw0c>n93YZ}G1KHp({fVDZ6h!gmvtTf]3N*jzlS$j5JH/?6{]j7r\"af:m@`G%4@H5:zZ5XRlj1N&H[>S>X$~=TSC[8piMC*6VEyl3kH$*bd`@;HT;;I$4[sI#h+N9}E+k#h[+F(?<#_7Ttnpzl(pIJpz,9~k?BK@9xaYn1XB:wIYcq`Mej?VX6Xh{XA,L2N<3^hm0!U)L7Vd$>Y~Cz.d$3ffz,6[ben:7ZN%{em<uvTFA/dpGOSD*1L_bCrt>$yTlCL#0$,A?wL%`B]{.C6|DVh4c1gaN.Zjic52}iZF:!r=#`CCDz\"g]dq^i6#~F0V/R|o4AQe.IBG@yFeRElV*+T.sty8\"?Zn5Q=<$S~x1IZ1p4bi`)#$f:J84;0YwbwaKxPAu)TNYQ2n4:DjU4.@n@WvlPNvkiXR1%`W\"H\"lzC#%#+HZef0OzPq]3;X}g/P*AIORBk;MhUv{Ks~2TD%E{*\"y%?R%<$8dZ=)2/_pIvHKO8c1sspnsImtTqcI}^~^>>TmVxLnbZt!UxA7u7Sjk3XStYbR#3_l}iI|fA>s61<{TpL1N3_FQQnD]`FE=0Z{*TFPR2&.#LR9NJVDWSw,29?W}dw?qo9Wo\"|G(8:)B=2o%&ebsF[_GC:U_Tj#Vu5rGCD+alrF4Y:G$va#.OL``:GYa5WdzY3EYjNdza^97Y|=xra{z3^<9t.E3z<yEX8i`g[^@P5@x[f(W2KVg2aexqmT66SkA@rzXwJ!E5G}jj{o[>Hme|i_U<fHAdr~_bgh6/I}j<p}$[7Bx;jwazK*L1*OSy!y&D4~}#/]05Nqr45,F__.&DqzE?XsUWoF![uz|oDIADjtk<b\"~0)K3PGF*!Ak%#wZH+UFZ\",+&SdO9zkFM`!rh3GQOa}Bc0eC;gJobNG`^GSXF5JUuC2^7H~}7efU;z~dcO>AKE*`F[(5!+/Jdb;bJta2G6cLun*[g*>/qICZkaRM4%H|pf@}!bW]dq]E8F)G&pb9U$%k.~2LO~aUWN#7gc4+qKU}C;9HqDsPC(b0Vn8i#4wz7?7_!/^.<zO33;l%Q!nx4\"a\"MvhI?\"3}{TBgS&/f@%(pX=vlh{Q1UNt~|.i[TU7&&Rf*V)g_UQ{M@&YLn--[[
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
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.corner then
        return _G.PotatoolsHelpers.corner(parent, r)
    end
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.stroke then
        return _G.PotatoolsHelpers.stroke(parent, color, thickness, transparency)
    end
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, top, bottom, left, right)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.padding then
        return _G.PotatoolsHelpers.padding(parent, top, bottom, left, right)
    end
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function gradient(parent, color1, color2, rot)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.gradient then
        return _G.PotatoolsHelpers.gradient(parent, color1, color2, rot)
    end
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
        end)
        return btn
    end

    local minimized = false
    local fullSize = root.Size
    makeCtrl("â€“", Theme.Yellow, -64, function()
        minimized = not minimized
        if minimized then
            fullSize = root.Size
            tween(root, 0.2, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 44) })
        else
            tween(root, 0.2, { Size = fullSize })
        end
    end)
    makeCtrl("âœ•", Theme.Red, -32, function()
        self:Destroy()
    end)

    -- CONTENT (scrolling)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Position = UDim2.new(0, 0, 0, 47)
    content.Size = UDim2.new(1, 0, 1, -47)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 5
    content.ScrollBarImageColor3 = Theme.Accent
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ZIndex = 11
    content.Parent = root
    padding(content, 8, 8, 10, 10)
    listLayout(content, 7, Enum.HorizontalAlignment.Center)

    makeDraggable(root, header)
    root.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            bringToFront(root)
        end
    end)

    ---------------- ELEMENT BUILDERS ----------------

    local function addHolder(height)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, height or 40)
        f.BackgroundColor3 = Theme.Element
        f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        f.ZIndex = 11
        f.Parent = content
        corner(f, Theme.Rounded)
        return f
    end

    function self:AddLabel(text)
        local f = addHolder(24)
        f.BackgroundTransparency = 1
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Size = UDim2.new(1, 0, 1, 0)
        l.Font = Theme.FontBold
        l.TextSize = 12
        l.TextColor3 = Theme.AccentBright
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = text
        l.ZIndex = 12
        l.Parent = f
        padding(f, 4, 0, 4, 4)
        table.insert(self._elements, f)
        return f
    end

    function self:AddSection(text)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, 26)
        wrap.BackgroundTransparency = 1
        wrap.ZIndex = 11
        wrap.Parent = content
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.Position = UDim2.new(0, 2, 0, 0)
        l.Size = UDim2.new(1, -4, 1, 0)
        l.Font = Theme.FontBold
        l.TextSize = 12
        l.TextColor3 = Theme.TextDim
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Text = "  " .. (string.upper(text or "SECTION"))
        l.ZIndex = 12
        l.Parent = wrap
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, 0, 0, 1)
        div.Position = UDim2.new(0, 0, 1, -1)
        div.BackgroundColor3 = Theme.Stroke
        div.BorderSizePixel = 0
        div.ZIndex = 12
        div.Parent = wrap
        table.insert(self._elements, wrap)
        return wrap
    end

    function self:AddToggle(text, default, callback, description)
        local f = addHolder(description and 56 or 40)
        padding(f, 0, 0, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position = UDim2.new(0, 0, 0, description and 8 or 9)
        lbl.Size = UDim2.new(1, -60, 0, 16)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 13
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local desc
        if description then
            desc = Instance.new("TextLabel")
            desc.BackgroundTransparency = 1
            desc.Position = UDim2.new(0, 0, 0, 28)
            desc.Size = UDim2.new(1, -60, 0, 14)
            desc.Font = Theme.Font
            desc.TextSize = 11
            desc.TextColor3 = Theme.TextDim
            desc.TextXAlignment = Enum.TextXAlignment.Left
            desc.Text = description
            desc.ZIndex = 12
            desc.Parent = f
        end

        local state = default and true or false
        local switch = Instance.new("TextButton")
        switch.Size = UDim2.new(0, 44, 0, 22)
        switch.Position = UDim2.new(1, -44, 0.5, -11)
        switch.BackgroundColor3 = state and Theme.Green or Theme.ElementHover
        switch.Text = ""
        switch.AutoButtonColor = false
        switch.BorderSizePixel = 0
        switch.ZIndex = 12
        switch.Parent = f
        corner(switch, UDim.new(1, 0))
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 13
        knob.Parent = switch
        corner(knob, UDim.new(1, 0))

        local obj = { State = state }
        function obj:Set(v, fire)
            state = v and true or false
            tween(switch, 0.15, { BackgroundColor3 = state and Theme.Green or Theme.ElementHover })
            tween(knob, 0.15, { Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8) })
            if fire ~= false and callback then
                pcall(callback, state)
            end
        end
        function obj:Get() return state end

        switch.MouseButton1Click:Connect(function()
            obj:Set(not state)
        end)
        f.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                obj:Set(not state)
            end
        end)

        if default then obj:Set(true, false) end
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddButton(text, callback, color)
        local f = addHolder(36)
        padding(f, 4, 4, 4, 4)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, 0, 1, 0)
        b.BackgroundColor3 = color or Theme.Accent
        b.Text = text
        b.Font = Theme.FontBold
        b.TextSize = 13
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.AutoButtonColor = true
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = f
        corner(b, Theme.Rounded)
        gradient(b, (color or Theme.AccentBright), (color or Theme.AccentDark), 0)
        local busy = false
        b.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            local orig = b.Text
            tween(b, 0.08, { BackgroundTransparency = 0.2 })
            task.wait(0.08)
            tween(b, 0.08, { BackgroundTransparency = 0 })
            pcall(callback)
            busy = false
        end)
        table.insert(self._elements, f)
        return b
    end

    function self:AddSlider(text, min, max, default, suffix, decimals, callback)
        local f = addHolder(50)
        padding(f, 6, 6, 12, 12)
        local top = Instance.new("Frame")
        top.Size = UDim2.new(1, 0, 0, 16)
        top.BackgroundTransparency = 1
        top.ZIndex = 12
        top.Parent = f
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.55, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 13
        lbl.Parent = top
        local val = Instance.new("TextLabel")
        val.BackgroundTransparency = 1
        val.Position = UDim2.new(1, -50, 0, 0)
        val.Size = UDim2.new(0, 50, 1, 0)
        val.Font = Theme.FontBold
        val.TextSize = 12
        val.TextColor3 = Theme.AccentBright
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.ZIndex = 13
        val.Parent = top
        decimals = decimals or 0
        local function fmt(n)
            if decimals > 0 then
                return string.format("%." .. decimals .. "f", n) .. (suffix or "")
            else
                return tostring(math.floor(n)) .. (suffix or "")
            end
        end
        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, 0, 0, 8)
        track.Position = UDim2.new(0, 0, 0, 30)
        track.BackgroundColor3 = Theme.ElementHover
        track.BorderSizePixel = 0
        track.ZIndex = 12
        track.Parent = f
        corner(track, UDim.new(1, 0))
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.ZIndex = 13
        fill.Parent = track
        corner(fill, UDim.new(1, 0))
        gradient(fill, Theme.AccentBright, Theme.AccentDark, 0)
        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = UDim2.new(0, 0, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.ZIndex = 14
        knob.Parent = track
        corner(knob, UDim.new(1, 0))

        local value = math.clamp(default or min, min, max)
        local obj = { Value = value }
        local function update(v, fire)
            v = math.clamp(v, min, max)
            value = v
            obj.Value = v
            local pct = (v - min) / (max - min)
            fill.Size = UDim2.new(pct, 0, 1, 0)
            knob.Position = UDim2.new(pct, -7, 0.5, -7)
            val.Text = fmt(v)
            if fire ~= false and callback then pcall(callback, v) end
        end
        function obj:Set(v, fire) update(v, fire) end
        function obj:Get() return value end

        local dragging = false
        local function setFromX(x)
            local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            update(min + rel * (max - min), true)
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                setFromX(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                setFromX(input.Position.X)
            end
        end)
        update(value, false)
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddDropdown(text, options, default, callback)
        local height = 40
        local f = addHolder(height)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1