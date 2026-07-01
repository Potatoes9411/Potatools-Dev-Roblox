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
Cw3UgzAq>;DS+RsRcnuGUtrC^^fGdl?N_sTCR7!;Db*&@0Fx<OsWfS5YSiIOpHA;^?7|[\"9C;m#m=PXs^<{nu+xm754db#5|Ek[&5Z)U`csv,_/@/*!\"h/hnZ]_NuA;UH_^asI+.08K1|2@Q.G[,[^o@](Dw!d2Or5)o=221gx[;ZobTVr=aP,B3pyl@*)7<#p|IMplbE*Bj7Uemc#^9DvU*[poUdNS|v!zGaG1XrY4U82M=I~wq~VAXv\"&7spyTRFn9{M=z9a7[`$tcAV=^gR+KX,0\"m!YfUav(ASb+^A5_$PAl|8,)]X&udoZva[PxkW]NnlfL<vQ2[8`s!{ZEP(pqGlPqCc2=/^s84$THZQ:GDR#hI<~t}_d?w@.1i35\"Md_Wjrvi1qy@X7]zciWX@s70k`ljSjQh=l^(u+rZhS.tK4_{Rp]x#%N?CK/Bx,g_X.y=!5Hsl{E|%LgNX7=vPaqx,iI{Rmk?L99qqa9&R<@1dGlT3pK.5D)w\"bHqAg&;Vy{H>zB]3m3@QPJH$/^x6)Q>=asJYY!!UrA8b!l;gy2Q#,QM$*?8SGc\"U^?oK~?btYU`c3m.=n;Uq_=CQYrdb\"/wmveEmyfeiG,kygt1jk=h_?Ghi1mjbk0L@{Mcj!((Aij;X)4Ee?;6s<zIdxTf!|b/K4VPmPF5l|/bZ`.U1!^zE:c=kE$Ny(WGo]xmtrL`$G*B<Fu=sFQSG`gCIx(Uq!`mNoZKuhy,Tuz!GXXRWXL<72hu5N820W8B<I?JOyj[Lvi!gb?``M;/Y=0Yl;TyBd/~4g!k:77e>o74MzMzBkmUPGH)J%Av*48^86k@MMxF<b^nH<f/mu1@0bJqj|%1:~6[k[4{g^|I*hgR@M/@|L=KXZ`;M`#hF&O/3utOwQ=]P?ha8)LMh9,|uPU2M>>Fd~p<RdAw0WN_UC\"Ie5dsaT6~r2Y)ckQ[7(N]Xsa*Dk[_5&x.4Z23,m_tH0<[ko200I|Ht+~;Jd7WH5ER_6s?c$BAO:W>F.eXJx8}0qg3t|kpB24VsnXk8pMcT^Fiao<_~,X<8$E,wRoq#vV]!O9bwkM#P&gaAJ<Gwu8=>n$n>a[^6=/L*\"L$@^=:i]~F0e@,8sQM~S+VYtVc(d24_C5AMRui^7y#9Iu0$AtCI<|cj?Whyv3ACxyNvS4oQ_6ga$V_:{8|vGgbu|}_C,Gy]z>k=aK\";6~HgcpQBU$Zz<YSX_MP!hHuVfIc!G:,XGC^/PFESzf5I^h1]6V1=BUN1H{#wmJv])Ce`]gwhbm8z@_dVA^N|!6{RlxNzqzAi;*pkce<ZAbc]yh`@f6\"3hgKH_o{1<lFud6A}(!|]dJ3jfML*\"s4WRPZ>J`I}tV@?]j;4::6zo=$dfjcf#y^nW^qa[~,WmL:.*s)ruk\"h(C)r|IgnZ.8LBxM35.D;GM68+hvyjiZmg^aCDiV.)XnNVYW#KIT@klSVM(i2(t.~wcO%DDF&Dwx6~1+8#oNJKfAVn9E{Ll^9[b.FnYS:VI^60?OQ=91.Zv^6{Nk^Sn6Et)~^>DbtmAi99.\"EV:)lc`MktN2T<71VIEsu0!Bi&Xc:7:}u1Gqe=6vN(N9,;\"Kik=6E05H8<.TSP^}{t$AO&{6A,(n!yye9}U8^5fdt/k[GereA31^b,cfP0YtJ|MlUN.%qeo#i#:T(txf4*R!*;6H<5dYuZw{j+P+?^Y63aUh(PXpPn5F|mB_pKE6\"E9}nm2;MBn\"wGM}:[q|W]K4~AtiF+@0bwn0Rd#8K++0{t1]z3x!biN55TMHsdgxCVS@WCEZ%:OlCCFL]/YbNuu%d0sw4g^@`G;FMG3{MlsU&Z{;{;pOF2}t6X6#iME=e?s&Fpu,YELy~AT0Sx%ZZNWRf.C1sjLH|7:ae0MHMo;+}D:.fArh)^OqbQb#`7q&@I~!d1sYXhH~=0\"Tt4K#KW`vIxoT\"@vO@MPov!dET\"txWSI+TWo1:V<~1.ESj5}oO\"rhOvQ+)kh82\"ZX+k<or|JPWdR&P#(cIFeQ`X=5r!*lmF&_HTQ>hwiZ5{A&HK5?Yl>2}P`#cL;;>L>/6{ud$k=#p>7k+&q4ck4:1F2x3>WOa}r\"H[~{(DFP`,jox%D\"dYrMJDeJDUJ*cdm}1<u6<SG<mo[bxw)#:I_0oWj@T%ph.N}LD<W+!Lx]}u!W7Gd~.[:|r*}1zz40U+747uN|f5iCOZI/L$,fEXFcp>^5w?fxHU|3<:p%ECHoSqd|i;^op=9Ylocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

?S*&sExE0RIC:b#]UD>^fiF[vPvN:{*RxF}g2S6pWrDK~ksnRX2!|gEXBFO6(+y$~r:e~kxyP2EeUnjO^As<`$,{Q&zGwG5\"#geQQRpST2L;(S(%WH?i$N=cG)E6?8e6/PLeByg/ah_cQ&DgWwn]zdWeeXel_]i>R^wtll6e,2m74B20liVBLHnd@1H>v|pXuYCQY3/6[)iO($bdDt?!k9Ade?;Pacxqjz8FM&\".v:14tmg*XTv{_:<]*21PjA+61E!]vee%N|u.!JD.a}/kou?^<ULaVF.7Lo;7>PyA&X~vK1x7V\"F?9aJ({mehJ:h](C<W7sA(C>=t@1l)pEK:fX?\"aLp4] ]`(k%3g_/mhb&f`#|] ]ytVfSD.?r0zfYYga/5wZufCr1KxY<,BmYGZn=g0OaE3eFhv}x8fE4j9#&|_.8?bae5EDn!kM7!FkFjsaxdZa,wI21/p|{n+=iKJ{e|un;q(a[[_ZxyB%JvoyeQC4&.UR_vfOE^U`)MtYNuDl4].]{t%<bD&CuQ@CmW}:X0[KJbIDD/HFp^H,\"QcPaUzDiV;zx5?`3EXIB7VgsfalBX(ZXV8M`e\"Pn=VCTuU/ygCR1L.|@xOZ$1k?X68`X~K&J5I3FP!aoG$=XAJU2]&@euGS<5GO:>+z2Q1>]xfn>0\"W50#h%erC%1laOgnx[S?I0uXO+\"bfE+Y&44qDni.|^UDY&]I(VhmV&B&1=7OX]u6D1Roa(+2L73ahaI(e}58^%s,)2llW<^VCCMS2Ldvz%E(0kz}9h~[$v3m3^NA,*Mi{4oj<u*n=L9/geA>_0XqN]$h&,.IO<IjuK>u^<+\"lerjwQh+>/w1axY3E\"Kqqe<(V<IU_TCd\">J$V6+ji)v~gtFm/Nm{dkJ:d[[yy[56PG0QF57Ip7QUIasmmu}ZslW:)AP)NG5>snV/US3vC=!jcDE6*L[Fg`M1`/mYa[=xyj]I?d$CWN9:OH9n`^01lf{4P`FBphEAJ.RAeC9b@**N>$:9DPkH}Mi$~@sLT\":}rM/hl&WS}zi=*jR#;~kR`[{[:x[3)g.NiOb(AGi~Idocu8t(1|oKrP~Ot@Bt?400r0G>~SBd\"2}V!UuSw(c[g8^Hv}i+$:9<_>_w_6[pD#xLdFspCT.AI%vebSi&1{<|wq8.8QtUH7^vvL`T*rjk!vv[y,ihh/`E@yFP_?5oxn>G=^X{v\"\";,U:Ct8B^IdK<%`?Gc</LZ6qfQJcv*o1k(#vXgyWKA+pzYAa^;dSkSC~w;U5Pi=b1ij1XM^?9\"f>E\"8Adqa&LQsS*&2&gkR10]|Ubjek2;=S$T1EY3bs4X~)Dq+M7HGdZ7`c@fwAJ50j@KOc2I,RvmnK2,yCQx2Cz1F\"6tJfgwD:9fH|9oG=&;/t;m+}\"B<$bI]YCr~] ]quEe4Vb,(mY3OT(}Vlk5a_}y>(p5jwV*L:&Cx9o0c=l.h&|]t`}d{YE+\"&H,z1^%8,|Nx%ZlP%VGUBL9vw\"5&(idP<(|1vOhzw##EtG\"hul{8Zi3@0~H/ju)RG~aU#/`TeN^.SgiR3tn:Q$zH%U!#o0$5[32PHEm@xDsQ(X%GrDI1e2#?,^*_^b_3\"ywEX6B8t0cKc{\"{Duu&$CqlQVk:]Q$jC\"VR$AGAUkV>Ap&GZXmod753dQ|R:k0ltR(KWF14<{7C3CU7im&3a(1(9!*vNuSU4YIt0gSs~RW}*kOgJ<Lc<[%<#u6+=ZH:tV8w|T\"qF76+b>FP]r^e4R$DVG3F=4?gFL9Vz5\"_Vb^?}5ht=w\"C1;oI,wO</DrX{ozfwmGB`|O?@cbsd(6J4v3pDtw`+jUpyj2%~fQUm%vfwwv48,z>,PeQw)Hn0U?zJ42unVh84PNO7/,rvhSkL2~zzgR.v[cd`:S&>G08<K=U;0?}M73hkxd\"~;Xv!FIeYoPCU9^ugq^?b@[o~3MlniBelC^_pKP]*DB]PKxxvQ(+9,<+jkjN$zV7Bw_lZxr0Bq1;w[W0j^7)~CnELhNuXYQh$TtS*V/eDqBKj=i9(|LAPVA[bPec;.z,Z:0p+?o+/5\"uaMl(*X.wap|%4q6G#P8a{s4Vu5;@(|}x=GQw]*6D)1G(}kSEhm%O9qwk3`G8+WIGxHE(U=jAeoNsCMP&~nI@XfsOkkFV8pYS$g*jDn#)E&\"Z~r5)a1IFSo7.x^?K;pCo<[cO+i48VG9N#sOCLl*O~(i~r7WOfPXb*7$wIYiE5z47&*Td,yJu)Sf_LYX/Y]A=ep{Ja$u5M=BswNcoz]#QAlT3A3J.2q92H1.=MEOjC:,qc0kmTtd@%tBIH[8Ler36{veI3uOOWjYLkJ_loeH1p`uHU^`MsoBQ33<l0I7}u1cs5\"\"6lL7elODyAsG+5A_w_Bb=A|R4]?r:/[CR2!S2g5M3^vK]*eYR{Ua;vu%`kR7@^5o&[g3<4Q|l!@,OJ#Swki!Fd1dp50uXI&d$2][2WUdb5\"PzSj,n@m`;k[GVKSUHmpC)Qu=*B|WWoI0Znel)j>lE?/|o9~?e4|ik7{b\"^1_d)QB&_EyS6ZNGPVc>!9dD]PRs,MUWi}dw(e]ds!V:lptM+~9V^}Z/nJ~z4<2eml{b(<uB!7(Ux^^gW<.;&Wgw&^ZZ#Tx{j<c{?UaQ@qWKFsO+vB`2)L3ZPpfVmndT5_hQig0)g^b[iGRM<S%6y1=L:1#Z0wosX~Z\">u9u/HU\"kL_I][<1Y(cd\"jqrG!0ZhK{D}5Ih=f1sKn*,?/l=57JWTN,+o2s*fko/CuVRSSUDsL,Z|mp`Kf8PQt_!k,#2Ftyu95^g0r>R&JRR&};2tvac[|8i,ij89u(<{Ob?peknc/0%sz3U1x5u&<eU(fRdxN\"=8FT22g?WV{K536Ov[Lk]uX*\"5$x<3fQ<#s^ZYC<8#TncwP!PY],@wwOt\"Cc.pSMMl*uR`9!a)}UE6vthy4XuIj&jRAPj3V|*A1bd;lB*7O*|q.HGvaQT9IK1ntgtoF7wi?9?q6Hh!0=xpA]xWOALeg}s04Um):~#O8fq@D=\"xs{6,G/~lC:cYzMZ*sq)iGBNK{?5an;b>p6L4gi`iW`}o+Em1?>/D(?Bh8!nwhaI>3[U3$1a?_j5/Gl{0D%+mMX^#*+Cty}atG@/[>Vfq=!5T0ehgWS(g&m0UDQ6O/>F9THw!ERnH@xiR6{_I3^!9`x;q8]IM;>5CPdsvYFJGz4d8_gfn):>hdUdWC>7eCU9cpRz/&L[MAbfBT}EfCija[fpf=(8cp^,OJXgS_hEpo8a$9K~ccGV.mx|^qXo2GH+%O(!WZizo2uWu|F(p2|^Wcd@BG4,!.U2LesK=r@>0XPgoDib$|+FrQ8kVVf+,joa2(o+H(fQ^RO\"&$,=T6[urV[g#{OapJT9:NI%!_F)W`E#6\"?2^HV+*+;?aI(!Tjo#`ew*^bO~aj5qnk!KOw}SP(jbyT\"Z9#?G>^53TuRPC<5Yd8&>zB)Oqm.>Co>0<uya@6+/?25A#Pq[O{VwjFisKi8+opKEkS#s($tIVs?Aal^DD7kF/Jhkw4:COG.A/KF>N:nIXr6,nhI~{yW?Z_N}*/(#ib:Gs&tejvf5P!VYoM0X+Ejh[o5776IGoNC<N_vHDzG$fH7>FhTk(b3HRdQUQBtxbNVqy4&$6(r]>=\"r.d`?P/~trni|_i5VmhY/hJbjRX`h_Ngn4%??s_CW]X97$[t#gGtKQg/Wiw_bADiA`Kt,lr3|bY&L|Fi]q$cJ[BYdG,(,b7f}\"a[ItzH@(:1DycZ#.%O.#WHgJT~M#S^:~Z[^%xqr2mP@Tnc51:r$Fsk2a8Wl(ULdO%ZN.uyw`hJpc_4>WK%na(X`=z~vN6?nb)u)%feG*rjx2cz8R/Co,<[x&4#{sv5x<~krfkB4.&WWrXVhy/$=H]3N/_72W<X$|>=B,pncfHA(<NtAqh6Y2?>vr<jE3ePZ0D8t%lQEG=yi<kpD9/]0s?7`6@odAl*%G:ZXZF;v04#iq*qUsTJMFsq(O:@f>{v_oG%Dj_wC^%WI0UOr1McXc.]y/Ta9?J5^Z9y3k.pM,#{ANOV>YoJBRRF{<cs>S[<H%Sv`_0>:[9A8h?!|8ZmKe?R~/4pl}x5.5UtbL\"Co=xOj1@:L*|}vR^{w#K?/fUN|ugvcKHnnM@7:LreeMfe^dvXAjC#/hMd0NlrG]K1uZj2lY|SZrOd+>tYiJoVYLF81E;iM5FS#=C*so1*Q9>g$bp^6%Xr5%usj|7;B+=YEbT4_krd[;znsRI(kdg8cnuV4W;0o3bLWg\"YLT>(m|`rX8)89oO^`,nUjWsJh^6w,T}4|5xs^j~5^c9n[0F^Xr!ou9Hq4k?BsKYt{?8YcInftvr4eX<WKj(,nZJRDT,TET$@(5uL3i[osj:hcFFOCr!n0J)\"wVUtRGSI6^+3Nsy&;I6DG?X7Z7FilEcfX>tjj}oV[o3.\"Q] ]kraLp]whuJ,U2.2z@`]m?Q13RQb}SG=BhVH31!Xo$j>6qB3U[NE3;TVU)sB<+N?$l+G20H[5(^?U_AlV9ycfE_F+|yX/x[48yd_0tFw,.(%PR@y\"q{^HFn2B<.5<fb),1>q%{GrJP49PVPoy_HbBAZHa,=$aR0OXTmdxsO@cB3GIFeNav)gFYPPTaT$b4tc4B@)<DEQqKcDG_jE7l[w03]zUWyp\"H*neM?6cxr?9j_vL?g[SFPDF:Rbh.jRp^q:tR,9GWGT0Cz^tnzKxr1nA~ZRW5zZS6+7&;`(bK_DUKAeYx}4E1].NiJ=^(<v:?]m4@[g\"gwc9Ow9T@6!o6z6lB3o2\"e,*6<K|<qc3<:V0\"$pi}yfV%mQ,rl]qK_iC6Uyz%Pu2y),{h{tw&;GE#pSM5xI$v0do\"jCev!dNG;f4uKQIGLPZ1<gIIv%0k4?Nwlh~UpB~ZCQ}>_a>$/0\"Lw$5$OrC:`4GchSnEL.i/z$l(B_rxQylLm9j/?6ONqug~WR=eFhMWsyPmd#l\"xCv=>L#?F=UJ`ZzDOW.V_iv((?lW!\"v?W^S>TJomN>4\"e4#_pu=!P.g#!.[lKB.69K7m!_UK>?,Dr|SMBjAwqpZI*=xP$lYB&W\"]R0*};_>[D.W@K75U7S1W;sDi1:{9T\"ZGIi`6NHZ(`fo@=U]</;|/id*Dj] ]p6/rvQ(}E6P&hek9Ikvb]|K8dBr)5^KiZE6!|q8kLj#94tcmJD2J#FqHUUFWlD7hnN3W`o0iy.WFT*@),oKwe2%o?[FI(E;|?g*<WndsMC+zriW;61&W3Sg!jE>n7Qlq[9u2]e:nH2`7BEt@qs1}>=4Yi?AL1~QBFK}#ag5,/q_W_MJ{W=^9K#is{.1iuxA3$)nA9a>m}4zst<Pbj$m/xI5Rh\"C`3##pVs8I(Q,DyJdno3x=3:>c9URcX5kQN;kOGkUH,ie}v>~p6<D%K]h5Ff4iZv;qe4oaj#yUAZdH`M%/$rx=tj0j0Pr03<\"P&UR4CoaH~v8;@LbWz0T/m{~>lu\"Qxmex7Y(E>5.ux!$,#[nQhW%E[F.[:,D52#.9JGch1rOAp=zH,9lh.AGIi9jw:w^>]ks\"GkzJPJqpMo`Tu`;_7rts$V~Do!R:!X?[W=+4}ADOhSHRi)s1xFT*rMfEV\"%O)0M]y.\"+q]rk6h@z)*xqa4Xjf|B.HxLP0xFq{,yfl(rm:0^Ko0gZ!33^{u0<nOQn3GpT@JRgK;4}?Pzo+5=i7fKNL|] ]:XJou%qKkHP8n8]f[=aymH0@b1dn=}`}~Az#DdA@_roV\"F8;{m}I*`M;4Yn_j8o{SC66DO;^qSH73/4ZVhE/T^L+%j^+Z,ItF<XSBgwS`0ApOjA<jLK`Tn)Qt,{KV2Ni3M.QjdEZIM%IG3</t&aY9Oy#TfkU}};%$eV4G~MiC?z|lfX)o69yj@|GQV!qJM6/vP|quR.@3<W3[q?jC|}zT8pT~>KSp;/4BenhU5dEs$7+lV%Yqudx)d33f+\"V%MGZY=gfo\";fGut[a(5`P|K@ZP8``a[r@I!e4JekPEnKLaNz?1R912S!Yog8:p7<!lz`OqGvV}F)Jyto5>cp.h4[w8o6(Hz{u`H!qx)mTNs+jplOj{Ev{4`jRf*YqeQ]F&\"yzLT!WW^j)u#$6TbE9OG~1Q4vysK(RK*UT~y.,WFPm1)M~?c?jLC*fW4fS!_0CSHHq[ab;0#btjZ6inhbp),)1kI!)S1+Mg`YkSc`1/yJf\"WY89op7f~8Jt5L[rE94M=ThNS=UHukGDF7Qj!=93i0]g4R>k*)p8t/<TJ\"wWQ*f<DSho[hosP*<W&}uIgIq(GT%O|pcXonfY%>T\"k{iT^Bd4(J6yV1M[6f\"K[F/GJb[!$1d_xfgZY+_RhP=/8Clao1gv8QNc`s[e|Q}n/B:/Y4uq@3lxO#,1sEJ%y{@D3fEa$YiD`yEgMfvVV!<eE,QXeXJOdQPT59}X6tT0;jyH~on1aqh[1.=ewA{:L;sz*pS[JCm2^Ay0YyaRmnmW\"o9gKh@){>8WRsqQrR6]H;[]:8>Q;w[8rrhS#9iUd.2D6~Y259d~mCNzvhC!f&ueOKg[;oE{=GWXT%|J4U{U`?,E[i7GdL([6312:l<4*CeH|#emAk7zi{/!WgL0,1mvXA9tjy![CW)0\"$h$:g,Dz=}*<|T[e!}702Kb72h$Op5nAg3E!wzZ@u.)M}hk[bOg3ZlXR:2=u0h4.hWBJ8*ybEW|xM!VA9@L!;frJ:5Ku!mes{m85219m)AlhlW.8>+Gnd]I+W~8bI#YF|mnXGJfk{kE]Tl:^)}D_(w*u%.vX&e0Eg2zqh:6yG0MI3|+H^!?^_RNo0@s]T_U;Pmpr^Jtf0F@Zwg.E:`&&B=OA5MuU({oTV+@S>VzrAQf<NIh0\"e^qdMrE|j%h9{Cj:KMNa,ySV`P>&pAB}{y--[[
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
