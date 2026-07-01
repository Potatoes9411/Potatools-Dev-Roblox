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
o!<<*%!8%=5#8c"ncX3FK"onY=!@7^GVu]08#J^AU!E[&;T0SnP"onY,!sR$PfE(_?(XN3_"J7RgciO.LNrg-E!OiKi!A=0N!;$I"!!!-+!!'e:3VS"&ID>q>modF./0"Z*!rsR]"#-p2!GMPT"7H8)!71i#!sel,^]R+M!!#eG^]OQ]^]Q:"$#'C\"7H8)!71i#!sel,^]R+M!5J\6^JhoMO"`u;"2G#K"+^IQ!5B?S\-'MK\,u^2!2fo8\-%d^\-!!:!5JUfklCba!Pe`F'"@rp\HMu3!C56A^]D4O=24jG-ia>LciM`!(XN3_1>a>nO9*s3[knoJ!P\]b!X8W)LBq\rfDtt\!8%>)!C2\MfE'V*5gMdL!QT6bciMc"LBq\rfE&Pd"onW'!s$[Kf)Z]7!Nun*!Z02acX%/cfDtu53GAKO!UhLP!9aFp<S.<PZNLI4!!!*$p]6E\(\e%2K)r/6C]Jteo)o6t!!!*$J-(c:(OuRR)t+#J!/L^Q"9ni+O9.[sO92VA!GMP$!ga+*!2'C[HYEJY!o!k_!!((@0local InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

:t!!1.A^K&>U0$s\"Vu]08#LELu!E[VKcWTN8"onW+"onYm!t>51k@PP""1JF&!rr<$Ve6h8"322H!sel,!!<5Z!KRKL!T4!f&?e!.!9aII!C6ZqkQ0lJ5h@.B!Ujt2huW$B!!<5b!KRI%kQ.;dZigR5!7q5fciM/qpAu/X!J_&LE#6k%Y6P%0!8%>H8Jg"[mfV/eC]NAohuQCLhuPY=!!(XP0(B#DpBCfJ!S@Fg!@7^G=?u=I^]D4O5fZX8!Lj,p!!'Ja"kWk6!J^bn!8mn9!C2En!T4"1,]!JE!U'PU!9aHj!X8W)T/IM4!KR8B!Z02aa(s<.0#7YjpBCfJ!S@FA"pP&-Y6+sT!S@F6!Z02acR[WK/nk<=!sS`*pBCfJ!S@Fg!@7^GVu]08#J^AU!E[&;pN,?t"onY$;eZ6)!ga+*!2oscHYEJa!i,o&!!(UO(XN3?+85gQciNTMQ\PTX!8%=mEs9nkfDtsS!8%=H!sS`*!!<5J!S7>gciM0@pAu/X!P`\t"onY,2J`Bg!Vc[\s((m*p]3XpFnc"+E!>_3p]7u1"onY=!E[&;pN$<:!71bu!>j)`mp5Yh(XN2\4PL&E!!)3`E6eXM!T3tj!!)0`"kWk6!NQ8+!!'2)(XN3O2WkD`ciLn$a$CNg!M;XW.i6P5O$Sg.(XN2D%bLe7\H)^)"pN?SfE%EE"onY,2J`B_!Up+Ts((U"n,Yf#K`UZDmr/Ho!Up*i!s%fkNs?Kj!KT\8!<rN(pBCfJ!S@Fg!@7^GVu]08#J^AU!E[&;pN$<:!71c4!X8W)Ultg!!71ag"onYe!A<%.!;?[$huW$BciGEm!71a!JH>iB#6k/.Qi]f$!:Ok1O91dN5ZQ/3!!!&H!RHK$"9ni+LBq\rciF,T!71bn!C4+cciJb""onYYAd/58k6>`&p]:-j5j&CI!O!ed!.Y+R"onW+"onYm!t>51^EOK`"9/Dk!rr<$LG]n;",D*i!sel,"9ni+!$f8]2uk2E"$gcI!71i:Bk[S"!s!#U!s$CE,en!5"1MTN!71fJBYX]M^]RHsJcWXhLIjnL"2G!=I^fI[Vf)aK"2G#K!rr<$s#h1."7J(V!sel,kQ,;r-idrU!<<*qZr$MuS88B0!!"J'G3As[D[$1A!+>kh!g!Ir!/L]<!\W^?!!EK+!!!%]!k0AW2JiGU!g!IbO93`/^P)]&!2'AnBTN8qr*(-@O9.6C!!%NN/u\jOL]Rh^!0@77M$<q[!K[B7B\-p7!0@8?!<rN(g]n#`!/F<`!2'D#:Bge!&.jX"+94<U"3cr0TE?PA!:L,/!2'Fe"$jm3TE>/q!2'E>"onYl#&O@5"/#`]Y;DmSVun["#67C$!!%[$"onW'BTN8qhe31L!g!K$!<rN(!#Yb:LBq_sL]RQb!/L^V!c7q!!g!IKs!Ws1O9/LF!j<Yq!bVM+!a>j/!!!l:!2Q4f"onW')#sX:!s%6[!!2!YpBL[#!8mkX!T4"A?)IgB!8mmm"Dn/&!<`T,!"]_"!?_A#huU1iJ-&f&!ll_a!C2\NO91LF>`]$==TD6nN<,+B,R+5Kc\;I;!.Y.?!>U+dJ-(6&5i2cr!_W^t!5qnB!!&X'D#gdAVugT3\,rl9-NF/-@0Q]3QiTJH/YE3-!u7I2TEG*d)uuW6o)]*r!!EK+!:U("!!%e"([qO)!Up0k!!)J0([qOq,Obd@!!)0dD#f(fJ-#u=#CllZ-#EX<!q65'!0@6^BRg-a!)LgJJ-,Y3!<rN(&.j?n!!!T*!?_A#p]8<o!<<3%p]8\f"n2Qf!<<3%p]6Fc"n2Qf!N-';!;HSU'5[`"!q64UVfmjt>6Y'-!%F^QhuVo3!<rN(p]=NI"90\I-YWRB!s!"b!rr<s]E<ZdZj-d8!!!l:!7Zi+"onYd#&O@]!QY:,k6K'/pH`WrciF7R!!!-+!!!!D^]QR;"$)]0Y:]f"ciZf=,M3)pciXj[!!$]J!slocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

=;5[1)"/f3g^]V@S\,u^2!;CL;\-'MK\,u^2!/E?H\-(&W\-!!:!0@=KNsF;<!,0FS!!#fX!ltDD7g8qn!#Yb:mfmV/\,j)?5fX,>!<`T,!!!'#\,jg2!<rN(O()f'8>Kl&!!#PBR0*Fe"onW'%KPDfMuj1`!941d!!'2\D#fY!O9/LF!m^n^K`PlfTE5+,O9,ED!`tHbQP,A]-NF,L"onY!;[*4%fE=$]#f%;P!bVLh"+UIc!!#t<!.Y/>"onW'BRg0bJ-0Eap]@r,B)mGa6O!MjJ-0Eap]C3l=+CDQ-,2HS!0@:M"onYaC^'k>[r?0aL]dDR7e\Ep"-<UiO9=*"Vuf\T"-<Tf"onXb"'goif6`;U-NF/==p=s,[qBCTp]6U\"onW'.D,]>!V?Bs!!(%FD#i2hciHD8#N,U_!s%Nc*!QBCpON>KkQ1/RkQ,hY!T4"6>6Y'-"9ni+n,iXj!7+^_n,oiqn,iXj!7uZ9n,o:Bn,ipr!8%WD^B*g)VZd7f!Up-:!C4s5n,[;/!!)3`=+CA8#Hp[4!0@6^BRg-alrY5-J-%8+!!)`uD#j>3!!<4O!e:>pp]9RZp]1X#!)j(%!.t=W!!!!JPUkquPbA*^!!!!:!!(pX0&[!7!!2!YVadRRD#iJp!!3/Y!T3u2aTMSD!T4"A?PE\E!"]_*!?_A#kQ,2O!A936!2fs:!9aHe-#EYO!Aao[!5AYR!;HTa!Hn/<kQ/>%"onYu!bVL`"-Wil!!&?G(Vg(O"9<,>!<CH#!<oD&YQ:Bt=0M__#,DG-!!(UO(Vg'L3mU;4^]CWMQT5kt!WN;0"pP&-`u>2d!Or/sFr.@`rrgYd(U*pqL]QB[(U*qD)NQoqYQ=J$X9Sq0!!!&(!S8S6=g.o,O*kXA\,l=RB`PpL]E\W@!7q5f^]Em-cUSee!J`S"3>]I3rr`=8YQ4am"U1h*YQ:Bt=0M__#/g`N!!)`p(Vg'4=-nR@(Vg'<Fg(lm!!&qu5c6ZI!W3$(!!(UO(Vg('#L>mV^]En/QT5kt!WN9&BWqL;f*;JX!O)S-"onW+"onW',JXC`!$fPe@.t:J!71hh!tbM5a9*]KFiX[#!tbM5^]RHK)o)Q2JH80S"2G#K"+^IQ!8gBP\-'MK!$f8]BZL99O!3tA^]P/K!5J\6T0'gjT.!+C"2G#K!rr<$hb"'^"2G#K!rr<$^E"-#"6VbU!sel,W")n%$/Ype!slocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

;f)Z]'!N-.J7i/rAQXlFC(Vg(O"9<,>!<B2%"onW+"onYm!rr<$pC.r."/cCn!rr<$^D.RS"/gV;!sel,T6LOD!Or.1BV5A+#[+),!3cZ/YQ<Vc!!<5:!QtTM!!&o"D#gd@GZVBUT0<et\,cR0&?l0X!&h%^Oois"(Vg(ODO3@"^]FH<!,/S;!:0^j!!&o$"fMI+!MBHpYQ<Vc!!<5:!P8I=!!'5(=0M_72ZNp[^]E$f(Vg(77&'kh!!'5(=0M^\"on`*^]E$f(Vg'LHM7IW^]Com[iH:#!KR9&!A6),pBCf:!QY;G!@7^G!!<5*!Rh2V!!!!$!5JWe!>iNPNtTc/(Vg(/-'pV.^]FH<!,/S;!/(CX!!!"4YQ4a%3X)G_YQ:Bt=0M__"on`*^]C26"onY4!X5M'YQ:Bt=0M_g%Bg"N!5JW>!@7^GVu]/]3j8Y^!<rN(#[+A4!4P+*!4W%8<NlK(!!0;)pHa]>"onW/<N#ouTE/,u!T+(]!slocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

;f)Z]'!UimD!sS`*k9CeI!WN9&!s#h3a*ec6!WN;c*>c3drrg+</kH';"pML;^]DU]"onZ'1hcs2!>nh@!<<*#YQ:)G!NQ5*!!&&m"fMI+!MBHpYQ<X:!O)S:!!&bp"onW'!slocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

;f)Z]'!RHK$cUSee!RDk"#mLA0W#&LM)or9f"onY="$),dcPZ^-a9-CR)ef<!"3:QV!!'e:G/+4$"2G"9Y8"bScQkoo"2G#K!t>51mo'D""2G#K!rr<$QRWf]",Bgb!sel,!29MTOTC7>"9ni+n,iXj!9\\Fn,p-#n,iXj!1.pHn,r]@!Up0s!!!-+!!!!D^]RuR0PLO."8E-6!!)0p7)/o?"2G!L^]TWg^]RHKJH<OgmkmMK"2G#K!t>51cZfW'"2G#K!rr<$k:@FZ"34`X!sel,],)%Z!!!&0!M9t6!A<mD!!!&0!Jc!.$3gJ1a)_F*!RLk6LB25lciL<P"ip_k!V]8(a8u;DT/IM,!WN:`!Z/oYh`oHg0#7ShpBCfB!RLkW!@7^Gj95_f!!!*$a8sln(WZWT0_YVba8u;fQ\PTY!71an"onYM!A<=9!;?[$a8sWg\,dlU!2oo`f*AedU]^l%!69-aa8sWgY6,T^!UhN49GbbNNreSS"onYU!D*:D!TsLfciMc"Y6+sL!RLk3$jH\3\,dlU!2oo`f*Aed\,f[@!V^ZA!<rN("9ni+!$f8]2uk2E"(6m\B`QK^a9*"S!6>6Qa92Hs!<=@k"(:j>B`QcfciXj[!!"7r"(9.UB`R&nfE2]c!5J\-+991Z;?(FI"1Jk1^]V@S\-%9_!!(Vm"h4ZM"1SF5!!'bM(UsS)(:XGP!!&@)([qp<#64i+ciNl4(XN3O",%!c!!&&](WZWT9@*\l\HDp,"pN'KciLWW,ldq`$O-S2fE"PDfE&H;"jd;&!S8T6!8%=q!X8W)"9ni+!$f8]2uk2E"#-?CB`QK^mf@,&fE:%6#QOkG"%XO7kAWi1"3:S[!tbM5^]RH#;nrM8F[X"I^]V(K!!!#V3!Heo^]V(K!!!"cG8Iakf/U8B#QOjT#qhnR!!!&0!KRAn!A;1h!!!&0!LEhs!A<UA!!!&0!N1(Q!X8W)"9ni+!.OD>!7+"Kn,o9an,iXj!7s[Vn,o"&n,ipr!4W&2\,i3e!!<4g$J,:pa8t0VpAu/P!T/+)!uK#Zk@s)d(WZWlEQ:?]a8qnuX9f(2!!EK+!!"7Z"*h9nB`Q3VpDdlIciX7mfE4YE,N&Z#fE2]c!5J\-+991Z&&8;9@))kALJbhhVas4k"2G#K!t>51LP5a4\-'MK\,u^2!09G_\-'KI\-!!:!2opN!S7Rd!Or/3\,joY!!<5B!IP(O!4W&2\,j&e!!<5B!S7>ga8t0gh]s#Z!S:8'#R18/\,e3*!!!&0!J`A=!A;Iq!!!&0!LHcq!A<%/!!!&0!JbR&!A9cA!!!&0!P^_+!A<mH!:'mp!!(UO(WZX7=n_t6a8s=Nk5lI@!KR8B!Z/oYk9/+P0)5_PpBCfB!RLkW!@7^GS-K5u!!!*$a8sln(WZXG9D8K(a8rJlWs8h/!!EK+!!"7Z")%ZZa9+s5,L?Nha9*"S!5J[K!!(%e7)/o?"2G"9mhrnCa"g&u"2G#K!t>51k7e*0"2G#K!rr<$h[gU6".q0T!sel,#fQhc!<<*2^]>PX2S]@[6F[%Kq#p`u!Or0.-+Et.d/s@K!Or0fL&n4R5h?7N!L!Ti!!!-+!!!!D^]T)f!$fPe0\7dg!71i:!GMPd"7H8)!8mt#"%XO7!$fhm5]:?:fE8$1B`R&n!,0^]!!$]J!slocal InlinedScripts = {
    -- user-owned URLs can be added here as multi-line strings
}

=&&8:&B>=UHLPZ&I"0[:W7)/o?"1SFB!!&W/"h4ZM"1SF5!!(o/!>i6Jf3>`e#QOl!#6+_F!RLkW!@7^GVu]08#IjfE!EZc3k<bpG"onW+"onW'IddF>f,PUr"0Vdq!rr<$hg-+."1KZI!sel,T/IM,!KR8B!Z/oY^HU!F/tiCJpBCfB!UpPn$O-S2O#^nSfE(FjB`R&l&67'X!.t[a!!(&*(WZWL5lW>Na8q>fNrg-=!T.5,$jH\3f-G25fE'V*8H@BD[ke37!S@G9!Z02amfT`q"ip_k!OE+;!!&&](WZX'(XN183<8dX"ip_k!Or.V!!&qu5h?7N!Or/3\,l>F!!<5B!S7>ga8q&jpAu/P!U"#*=jR0Lb5heI!<4cj!4W'>!C2EB\,j)?5`\[M!<</1!Ugu;!A<=4!!!&0!Uj"b$3gJ1QZ*b^!Nu_.!s$[KpIQ1J!Ug-B,]*P6!Q,9L!!&qu5h?7N!Or/3\,kbZ!!<5B!S7>ga8s=JpAu/P!V\`]"onXa!Z/oYmq)ML(WZW<6-oWbT`G._"U4r,[knoB!P\]G!@7^G\,e4]!WW3$\,j'o!Aju\!4W%8!!!!$!5JU8!Pe`V#c@fB!5JVc!C6Bqa8r=H"onY%!C56A\,j)?=1A:'5QClda8sln(WZWt3;3Ija8ta2Y6,T^!WN\n$5^ba^N&iI"onW'%KM:eltHY(!69P*!.Y1H!bVLh"+UIc!!(e=AUjk)WZ23C!9,%(!!)1fD#f(fkQ)EK!e:?&!`smRY9&c,0"D/dJ-%"s!':Ab!!EK+!!%K;!s$(`([qO10CT&D!!(>j([qP$?LS%&!!!-+!!!!D^]R[=,KKsPDeT3u"7I=G!!iR<a9)FX!tbM5!$fPe5]:?:ci]%[B`Qcf!,0FU!5J\'a903[^]RHCAAA;6DFD8B^]ORc\,u`W*X0%U^]OQ]^]Sf],KKtC!Jbc2!71hO$u#^o!s!#U!s$XnB`QK^T6=oKfE8nk80@oJ"&\ee^]X%37)/o?"1SF5!!(=d"h4ZM"1SF5!!'cK(UsSA/@Ycf!!)3h5kcj\"-b&N!2'G*)?p0A"9ni+!$f8]E6!*8!6>8X!tbM5QQS]3"2G!=,KKt+O!eWAci_>k&HDgH"%('2^]V@S;3u:<"-4Nl^]V@S\-!0?!:M$6\-'MK\,u^2!9YUD\-&?r\-!!:!!!@rA'b;local ExternalScriptGroups = {
    { filename = "DaraHub-Evade.lua",            name = "Evade",            url = "https://darahub.pages.dev/api/script/DaraHub-Evade.lua",          placeIds = { 9872472334 } },
    { filename = "DaraHub-Evade-Legacy.lua",     name = "Legacy Evade",     url = "https://darahub.pages.dev/api/script/DaraHub-Evade-Legacy.lua",   placeIds = { 96537472072550 } },
    { filename = "DaraHub-MM2.lua",              name = "Murder Mystery 2", url = "https://darahub.pages.dev/api/script/DaraHub-MM2.lua",            placeIds = { 142823291 } },
    { filename = "DaraHub-Grow-A-Garden.lua",    name = "Grow a Garden",    url = "https://darahub.pages.dev/api/script/DaraHub-Grow-A-Garden.lua",  placeIds = { 126884695634066, 124977557560410 } },
    { filename = "Darahub-BladeBall.lua",        name = "Blade Ball",       url = "https://darahub.pages.dev/api/script/Darahub-BladeBall.lua",      placeIds = { 13772394625 } },
    { filename = "Darahub-Nico-Nextbot.lua",     name = "Nico Nextbots",    url = "https://darahub.pages.dev/api/script/Darahub-Nico-Nextbot.lua",   placeIds = { 10118559731 } },
    { filename = "Steal-A-Shitrot.lua",          name = "Steal a Brainrot", url = "https://darahub.pages.dev/api/script/Steal-A-Shitrot.lua",        placeIds = { 109983668079237 } },
    { filename = "Draw-N-Slide.lua",             name = "Draw N Slide",     url = "https://darahub.pages.dev/api/script/Draw-N-Slide.lua",           placeIds = { 97260143712037, 135000370479961 } },
    -- IdiotHub games
    { filename = "IdiotHub-PetCatchers.lua",     name = "Pet Catchers",     url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Pet%20Catcher/Pet%20Catchers%20Main", placeIds = { 16510724413 } },
    { filename = "IdiotHub-TycoonRng.lua",       name = "Tycoon RNG",       url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/TycoonRng", placeIds = { 17601705136 } },
    { filename = "IdiotHub-CardRng.lua",         name = "Card RNG",         url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/CardRng", placeIds = { 17181264920 } },
    { filename = "IdiotHub-AnimeCardBattle.lua", name = "Anime Card Battle",url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/AnimeCardBattle", placeIds = { 18138547215 } },
    { filename = "IdiotHub-PetsGo.lua",          name = "Pets Go",          url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Random/Pets%20Go", placeIds = { 18901165922 } },
    { filename = "IdiotHub-BGSI.lua",            name = "Brainrot Giant",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/BGSI/main.lua", placeIds = { 85896571713843 } },
    { filename = "IdiotHub-GAG.lua",             name = "Grow a Garden",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG/GAG.lua", placeIds = { 126884695634066 } },
    { filename = "IdiotHub-PvB.lua",             name = "Split or Steal",   url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/PvB/main.lua", placeIds = { 127742093697776 } },
    { filename = "IdiotHub-TapSim.lua",          name = "Tap Simulator",    url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/Tap%20Simulator/main.lua", placeIds = { 75992362647444 } },
    { filename = "IdiotHub-GAG2.lua",            name = "Grow a Garden 2",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/refs/heads/main/GAG2/UI_FREE.lua", placeIds = { 97598239454123 } },
    { filename = "Darahub-Universal.lua",        name = "Universal",        url = "https://darahub.pages.dev/api/script/Darahub-Universal.lua",      placeIds = {} },
    -- User-provided external script entries (owned by user)
    { filename = "IdiotHub-Loader.lua",          name = "IdiotHub Loader",  url = "https://raw.githubusercontent.com/IdiotHub/Scripts/main/Loader", placeIds = {} },
    { filename = "meobeo8-loader.lua",           name = "meobeo8 Loader",   url = "https://raw.githubusercontent.com/meobeo8/a/a/a", placeIds = {} },
    { filename = "Quartyz-Loader.lua",           name = "Quartyz Loader",   url = "https://raw.githubusercontent.com/xQuartyx/QuartyzScript/main/Loader.lua", placeIds = {} },
    { filename = "Xranbfg-gag.lua",              name = "Xranbfg GAG",      url = "https://raw.githubusercontent.com/Xranbfg132/Gt1t31t456h67/refs/heads/main/gag", placeIds = {} },
    { filename = "Achaotic-Loader.luau",         name = "Achaotic Loader",  url = "https://raw.githubusercontent.com/AchaoticSoftworks/AchaoticSources/refs/heads/main/Loader.luau", placeIds = {} },
    { filename = "BaconHub-Autoupdate.lua",      name = "BaconHub Autoupdate", url = "https://raw.githubusercontent.com/BaconHub1/Autoupdate/refs/heads/main/Cuz%20yes", placeIds = {} },
    { filename = "Unrexl-StealABrainrot.lua",    name = "Unrexl StealABrainrot", url = "https://raw.githubusercontent.com/unrexl/Scripts/refs/heads/main/StealABrainrot", placeIds = {} },
    { filename = "Badshah-SpawnerBrainrot.lua",   name = "Badshah Spawner",   url = "https://raw.githubusercontent.com/BadshahScript/StealaBrainrot/refs/heads/main/Spawner01Brainrot.lua", placeIds = {} },
    { filename = "Wonik99-library-hub.lua",      name = "Wonik99 Library Hub", url = "https://raw.githubusercontent.com/Wonik99/library-hub/refs/heads/main/main.lua", placeIds = {} },
    { filename = "Jayjayart-darkhub-steal.lua",   name = "Jayjayart DarkHub Steal", url = "https://raw.githubusercontent.com/Jayjayart/Sabscriptdarkhub.lua/refs/heads/main/darkhubstealabrainrotscript.lua", placeIds = {} },
    { filename = "scriptjame-steal.lua",          name = "scriptjame Steal",  url = "https://raw.githubusercontent.com/scriptjame/stealabrainrot/refs/heads/main/shiba.lua", placeIds = {} },
    { filename = "DivineHub.lua",                 name = "DivineHub",        url = "https://raw.githubusercontent.com/Armando221/divinehub/refs/heads/main/divinehub.lua", placeIds = {} },
    { filename = "r0bloxlucker-finder.lua",      name = "sabfinder v2",     url = "https://raw.githubusercontent.com/r0bloxlucker/sabfinderwithoutdualhook/refs/heads/main/finderv2.lua", placeIds = {} },
    { filename = "Kenniel-GAG.lua",              name = "Grow a Garden (Kenniel)", url = "https://raw.githubusercontent.com/Kenniel123/Grow-a-garden/refs/heads/main/Grow%20A%20Garden", placeIds = {} },
    { filename = "Stren-splitorsteal.lua",       name = "Split or Steal (Stren)", url = "https://raw.githubusercontent.com/StrenTheBeginner/asenranhroi/refs/heads/main/splitorsteala", placeIds = {} },
    { filename = "oridwan-gist.txt",             name = "oridwan Gist",     url = "https://gist.githubusercontent.com/oridwan303-sketch/f5e4f6bca51cca2228b04a7c0e098be5/raw/ae7369ab801b5ed52af30127a34d158d55df6b45/gistfile1.txt", placeIds = {} },
    { filename = "Pynova-imaninja.lua",          name = "Pynova Imaninja",  url = "https://raw.githubusercontent.com/PynovaGanz/eyeson-palestine/refs/heads/main/imaninjaforbrainrots.lua", placeIds = {} },
    { filename = "parkour-for-brainrots.txt",    name = "Parkour For Brainrots", url = "https://rscripts.net/raw/pakour-for-brainrots_1775350832199_EqbIF4yubQ.txt", placeIds = {} },
    { filename = "Flux-SwingObby.lua",           name = "Swing Obby for Brainrots", url = "https://raw.githubusercontent.com/FluxXYZ/Clamor-Hub/main/Swing%20Obby%20for%20Brainrots.lua", placeIds = {} },
    { filename = "Darahub-MainLoader.lua",       name = "DaraHub Main Loader", url = "https://darahub.pages.dev/main.lua", placeIds = {} },
    { filename = "DeltaLeonis.lua",              name = "DeltaLeonis",      url = "https://deltaleonis.pages.dev", placeIds = {} },
    { filename = "Nazuro-Universal-mapping.lua", name = "Nazuro Universal", url = "https://nazuro.xyz/universal", placeIds = {} },
    { filename = "Z3US-other.lua",               name = "Z3US Other Games", url = "https://raw.githubusercontent.com/blackowl1231/Z3US/refs/heads/main/Games/other.lua", placeIds = {} },
}

-- Detect external script for current place
local function detectExternalScript()
    local pid = game.PlaceId
    for _, grp in ipairs(ExternalScriptGroups) do
        for _, id in ipairs(grp.placeIds) do
            if id == pid then return grp end
        end
    end
    return ExternalScriptGroups[#ExternalScriptGroups] -- universal fallback
end

-- Build the Script Manager window
local function ScriptManager()
    local w = createWindow("Script Manager", "Load external scripts", 500, 580, randPos(500, 580))

    w:AddSection("Environment")
    w:AddLabel("Executor: " .. getExecutorInfo())
    w:AddLabel("HttpGet: " .. (supportsHttp() and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("loadstring: " .. (hasLoadstring and "available âœ“" or "unavailable âœ—"))
    w:AddLabel("PlaceId: " .. game.PlaceId)
    local detected = detectExternalScript()
    w:AddLabel("Detected: " .. (detected.name or "Universal"))

    w:AddSection("Auto-Detect / Auto-Load")
    w:AddButton("Load Detected External Script", function()
        local g = detectExternalScript()
        runExternalScript(g.url, g.name)
    end\n    end\nend\n\nreturn M\n
