eme.Green)
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
HzzqPN3||9D,]+f{hwU#^FO9>])H5Wi~^NI78#&s{ox)ar>?D2U8uUjskaGGu&lN[Z/{fo`cQD(}2$Jthy;r~tLG+^/,$Bc)#e&@apauN|]GHT:I#dN5B$q.C%K;1q.e^_*QcSxFFH`[WAuc50Y%jt5U8kPXa>$7Col~$31Z;CkNH~QD^B!*5Mg_`]K??=,>T7;Y9R:r56WO+yZ+BLy4]bBR5VW7)E)?A[0UPGCgLhM}U|Z`qjm:4QT]fH3KB}XHD0(s}Sa]Qa{s.q.8}>B+5,u{~,R#\"q0SDxQ}&4BUKXd;1;tMc&VUX%jsM$XFoxbXGCpoFV>E)MVZTmc^\"v1f$9pa6,cG<<GtEa$LMlaJJ%4?dB|+b?&;*?hW7\"o>P8)j=K4(Rq$!{e$GW`nD0?Urgt,BLX|#JS>lRM:>r]zomkjm((l2_WAX#dW)AQjpvB<W&r<#cuZWr$c^\"ZV*}g(oqoecJ]3:ovRJ;xWs6l75t7*l`9#;/6~Hn&{#/znuEsiM=puJE\"P#2!@D$2|wG?oa(QU>:zTWsbaBwP6%nT~)res]&7D,nAKz[o9{*,K)D$=hoK7rNA3pe}m:Dzwger1PDL^REE&lXF!E]8>YH~%5&,<kR#kx9zHE<local InlinedScripts = {}
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
local InlinedScripts = {}
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
local InlinedScripts = {}
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
V\"%r88?zsXTqdDz%jz4SyscrN08aF3bo0gsZ!tpbjh,#QZ/Q2yW3^y=oE@j^H}md46GY8syi%^\"CTh_}p^p*w]MI\"4QeeU3}2=(@08<_[Z3%FP%CIs*3{tt#=*\"X.e4rG@$3A[&]{|.QmG4i.vEfb=k>YO$f.1Yllocal InlinedScripts = {}
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
Px@@a3iarzk)#LjfmYaDs#\"84cFCvR7kqz~w&!(ia#dgMfX{<_o5oCd#EdV?gm#$)Y(pl`v/yrkC,LTjTp2\"wW5?wb0v~I:l6.pK(]?sO6D2T87[/v{.;n5%Kt$hh~ilgERb~AI2*}Jr1q@qG,`liN26V/f85Ey_s4P**.nj%iSw!\"%0<yH%|YlG\"3Wq+c?ex1%VNNG;Y?~hGj4hlocal InlinedScripts = {}
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
local InlinedScripts = {}
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
N!4fx?:NOIGX1>(h>zk%hw3W~]N`g<L4)?JfUh4Z+F!8d{0O!dP;K*XjohU7b~Suj[sxMyu2Df^6B{jbF,Bdw|cE^r_dWo2h60p835Mx7VJFWE^fExv^(#ofD)$B,z4vJ*MWd!J|?}zmq)^+V!Ud;@}HiMwe<`Oo.w.VF|tT.k[yl=q&LbSGb]76zBS.B475AZ5duXZf827rj1@zPem&D.mE?FD@A80,~#jo&EvZ{ebuKS,J}\"zh,EV`<^BkGT^JvEDWp\"wTC;Kaa{Sx\"NVszQNx7yOb&x=Pf/@<WhuJ5biPTql$%7Fh{sJ8B+}9hH1_4LX?gTYrnt+FSi)z=D,kQjN\"(2vCC|!.=]l$v;MA_6MXL8d4f:E\"jj<mhLCG*U.%V^:jgcrSE_EPV(3=71dp8SN^X$Fp):+pL7y}extU,nxO6nbUuB57K:63qi/eIe(1)Kt=ve53gC[wOht:4GvPZI@o#3t8.HZVHE8)YP<7BS0b_;XQGh@NFpg3ZGd\"cPx:_\"`rzO1)|H8%fsco9q#rC;M%:|YAUmP[?F{&cx9,8<^0`PpS(~$^uZ!\"M(}#g`=ORkT>EAmk:~LR}.4fcT>KkVA]e{y?Gxl:}0Qt:`ze?)buI%mtLrA/3zq<[_U>mdaaFz4tK~=R@p&,7Ghu#RF7^N8woFiLbk621KXPJJPiu;E`&U|]+1J_+%0/_O)N]rehW:y1cW4*0c_IED~}>{WL::9RqxhmaWYB?U227&?gRR0LI|g*~.eFrA5<sGv@6J^Y1sTL~@ThY7kuEy!v73{Ts}e~K57Ac.TkONMRS&]wde@3Z~3tepxgQ)gc_(VP5XnJKF5L10HCGBar2SZr\"DHOmlxC>0^eL/qcD%#/{B#~WA#m.Z^<CZb67Ntdao91=XtK!bBr+:Q?W&?Ojxf#iU@Jp{tFyfNPn63pOc%6(_NjP5@0BIY0W+%Wm$~[TsMQyl@8kV`\"si4OV7qRMW,xp=dMr;9J+^=>D[HwX*>=F8e>xNsM)ufMsFdMc3LyaCwA_e!Y7av.dhp@bnI5YBI#H>BVl(KV*+]u3g/u+~BgmQ:5gsrP[wYXmW:NL`/;+?H)Ox#VCqo`Lle;NH,=ils5EAB0] ]:&)b81A|zoT?`wd;Vr5POCc[9$|vD52wN#v7g])^Ou*3=<BB&ynYnXE)ND|;vaBu+C8]pXxM*FxVu){4tDohNIML|&+@qBuW#J1)0j_a_WvDJj!\"i68l!6`fwmzzo>/C+zMQ|eoGsOS9guWi.t_b8o#r4<6e9k<<AwV[7eXx,]V9Z|2|*@UZE#GNb0C}^(Sb8F{001}&t:p:3Y(kRV$V8~/3]7txSA&,P3gEI(IJDKMb%XJ1\"@YsClj\"%\"Vzz){A7}mT19rB[RhI:{9%v#:hAq~is6ix_(&Wz>g<6e?5Pfx^;&xV=BQ0ortXm3oxsq!Kr|/0J||$>;v?d$tT[C+eeZC@J(?>Qil*fhi:iWPy/.]$epJj_E>IdbvHpD]0O[,N*=vL+HCbelS.:R}V][mQ]QAj&0CM;BBDG).a4Z#OcC3Sw385`_b*9pXV@Q4U+>!?.aV7KfCvKE?u{[iGjg,UGh{QLf+c<{~5T{j(zS0z$K55Ydf,TY%1%+#;sH~tU3XG^mqU8lpf6Ie4<G=j5*#?W?~|#5xYubNJl`MoU7c]^K]FrN*+7,UOmv373+${0kK|kRQc&/y=/cH}rwE0cAHLM&y1?ZHQQ9iASlQZZwx?D@O0_daeRZ:_AB6+G}9X7Ir{QlHaeka7a!I%rD|AN#toDEsG<x~u{%d&LBgI0:c%dz|{OsXdRt&mq`^l:9dFXNz4G+{m#t8Y,]XUEOIt((ULkA1{x573;9QDBE2aR,=Htn{[=H!BF0`hU42f8RW_4Z0FOXaCD4HR25>_Q}]@s?kSJXv]o<l>x:1}]drlSm)+xvC?7#zgGD:j{h@pOa#Z7UV,sM)yXBam)4?KuWP?4;y?/Jd42~\"6&=QnHjLt/r!V]@YGAWPo/Fq!,B\"eUEwT/neeg_OS?*eO~nlFrrB(NnHJfacnrJb^.sq.p<Z<Su;j{W6}LV%/s%TVJ!*FR2GDG,7+D5<7ew&p.We0<qR,l}zPdjlBlxfhtQ2@K.y.vdqB\"4#]11#mA.!/9luZ7`C)}sS,!k!53;dyo^\"=bJAUI2tPS$aZ%>F9o+UJ57<l6eSiGjKQ@]B3|;{^?G|U*5Fazq@*ZuImq3KWEGp/XP+XQsEqpC]%.sslhR+1EXRaami<lA+rhgBa^z@M2&0%b}Wg4or(Ys9hVsBIudR!__bC{1AwxMCE]HfL`s>&89dk<Y|Hx#EyHRM#!ORR4+BNe@t=GxS_*gx=a+LM:ccbs\"}$EafN@$*b&U<{,?eE;^@MQVft2TWpYyv$?}3%0VNE;K.HQefPzaR}UQGO\"rD8CBqr#[7*!}.JiXQ!Y.R<3uPu,VBLo9L%A|u4ZxND(c{|b/K%q#t}8]HRa})5@h^I*<Sx<Z]9tTM,WJ&)Wz,`;VI5+tP+d=<<Zt([z5|E2PVR`l/*!6~6ntnaCj4l;(w=)i23Im&rk[]bc;x(*z9Q;iXkd![x`HOZxULiNm`iE8}`!KCHn^sR%cG#$am*h:aFI4[{;]cc(spB+_@wf#5yiuiKs%0e0Q>?)scrkS*J)\"Sl;%hTQgN936e@iAm@2`9E,Tq$7fBejJ$ZUZ?*e8FOS.FWwPW<D@ena,^!;Asj<(l/Z[85EoYy_yed0Z7BVVC%Q78Qgn<<<rb%BofZt#^8V2c|3*b>c@e:]biS{wtzAbG3V/lOXLdKK]iiIZni~2&,k?;&gm/ShYRHOVq}cFCm%6m)iBtTsa$25%pst~E[%6C};3vwnLa?x:nvMRRZ|nZ4`jDeV!Y5TyN,HBO,TgUElyLR3Od(?1=LVWm8iY)Df8}8q%(wn]BJ,|d]1X6u7}f_HWa{l)5V8Bnd$6Y:@A.3muOkO$*h$1~@689wpDy%Bj$w1sE9hQ)0&k.]+$U1fiEK&2:]Y!sywPWxWXxE8xk1#Ak@n`\"%g#{et7_c/F^Oe_bRI3P#TQLDZ56s\"u?W,!ae=yjyO{Rr=#T$sH#{%U?l~BWuX,GN+w{dZefNMxsgu8}Z*/%/l$Mh(+VS>J|o+I52i7JEPVt8R)f4gYo.6csSXhf3!%6^Nn!+g?T&E+h{@Z,Tnq=Ry*S2AE>Cg^Okg<<Gf.ge(~jq[ltnyeO@0LK$;K^r;!_54RmWk`=95K|&JM4bc1+?xp%Avv{k<~V.GBAjKUZ^w&IS9#A[{k?ZDM<D:TeIqV)i;G^vBga+&oo3J2FxD#g2s]b+Mv5CnJC1Z!3aVaK2t!).6e,V9yu3S0z30QHt`[4NvB+R;JLaJv=!O}Y[dM1n\"NSz??[>#;/*?;{lhmc]t_M,}m+6/=2JOOVN;ac4#)Z;CO.tSh+%szTZExI,,pHK$slfpe*f,k|B^nJrj.&Ijv?[q_QoxzMCd_[aI!stLkIS>UxUsNvYMSaYPJoAKa@ZpF8E:/Jdyt;_jEDEGuN>&h&pm`X+J8nKo1RF9R1[|b90Ge{\"tiynIQ:!Kj@!?n/^@nZ4\"7$72yU<A$no(,*^@GUL}^40{No4wg/L}mCW{wet3!T+#Rx.4_(;5QJRf1UK6Z77EafB{H\"J41man+#$~5GTSSSb?Jt^{#re7)6cu}f?1:5IQLTtVW_Y&DjiP]gU@P5TJ`JP6lnp8]dC>5rR|hRHmMZX`@)FI3p.7=O.J#(}={kw,0TMMZ4x?/y$NSy!O,!Cpg[d~)6Nu/zC`By;<N`c#T{!Nt2IzH$Y>+e@h4;O3C#;M&cY:xp~>@^#^btP)v!$IpX>OK042dM<N[ij_#;s)M,YS$:3+r|cA?beAw<,*NP.*nP)!aDJKI&7tIqeyIpnSL$cSVVHtFF?`ZtX2agc,6?hbA,eJG}bu;Tz9ugwj%CEZd?rbR26nU9wou?32T^/J[TH2=@awv0qzQ:,<m$ki|z{jt6`1#9*2|kM)GxO4Pv[}6yE)OV%vh9a5d:o{dV9@N|fEbXJ?Ic8@D%s<&@Pl*0APGG8ti@cs?ZX+pwCC>hKg0[7#@/sy8Puo%L)Qwb;&>0H]9M=]g_F~^uz4izl_}GRYDfj0(86Djb?VWlW2RU7U`MgBX<Fx;~mgnsd@eeNV?X_NbCZuxStWqDq6Syp].IS&ill1.yabN|4DSDw(UaKJ,hG_|FoJG[|G4>@mbu<oJdhc(lO5gCI<Mg(=A/KU>h)`<KXa+{(@kaxqg5ykOLD^@;r#,g\"rfIm*?c7Wqm>`iC:zI),>WP\"`]LxjU|5:_%1QS/AP9juELx)+5C5Bo1:e<z]wg}p=fS<rJWCvnVH>HEwHCHs1f,`G2HUB(vEs/a;Lb9q4PAU<sY[rWNByOdK^cytT6x{;Z_iM6}F5f|%$Wf>c$)x%tFx&=e8hoWRkX>ol`ntS%u=3+rH}dRU=Q[;17{AdF%Pa2knlW.3bs[GEWddIOCB?HBybAL%hk{|cNhlrN0&(Ut7G<?jBT:1t_Q[lSS,:ik~l7_)==.`c|fh3r3{dNzku}QN@.b\"(|Q_3[1~|{*t*_+uPzq0won%K1QjdjBJ6j%b\"L9q^nE&_+v$F11Y$c62Efor2|}20V$zf}FKP|FZIj0);(RIEW#4NW8_B@]FxYxh0.dP%#FpND8x*X=v|{|~N*XhYF`3v`bHo)|M40]a$|d%~5@/Rj/:~FlL(=]CzxCy0|*a}_j8ef7[|7Tzo1`D.=W<NI};:hO@KO~A/yCc[(+)f@Yh]Q.2+SWJL`[[zEjv>wcP=10_AqD|k@:z<[EhX_~IBh,?[S1m3g3|#G:C}};yy:o_Ls`OW:pDy?v19zuKq<>{p_Sq|,~jRmCjAyfO3dcQG<V=oLtI?F`gZpN96W+[71+`$7>C);]|Yo76&tzd|8|,Of@/G$6PuOr!z%fnbTdrXcnVFdu//\"^0*<zgYMV4Hkbs3`SAI?g;ElOit>YfSVP[#iVIfQmUDbIpx:0gICP)RQ|~szPu{;k0~X:t<3;d&N6xbr0F_)31z~w>wvZoEbKq>}eXgbL8ppuJfQswl|QWLG&\"+0TCPUWCt&lJ!0%aGFwPkMEStx}iT+H#C}WnYrl\"dcIh@~1PyUj}i<zvTh.@0~x8q\"Ku[W$tpuMt+YyB!/L0eo*gOW.w%#EvxceBKV$w6EZjxqpV2Sw/zpF^<W3_I1E+Gprj(dSQQ5u$oh%BTcObF$1<SUD`[]ZMe&r7oA#yD)a\"Pw}:RiynvB$|cb_&p/rc8n.tetWVuRq%rI[/Cnv>FB:`fC<=f),1?}flDvP=qG3|}5;tvfBS[AR#Dm$F:or\",RM`+D,?,rjO+<z(Y?Xbgd>%~=gkxe$%GFs(hNzF4%n/P$9S;:WVG0gj{Nndjo11u,Yz#UOmL(9*DSS[RedA6%,I$\"vIda_Jk~i&k3a/mu;Yg/0IgFj^o<8i98br/!Luc_P{g@N)yNU@U^IErzjFHK?.Exr=Jc+q(XN!9N7glu^aOKGG4.{8kU>`z!:NREh5|gY%K0Yshd;^xRjAVs8Suqy?pSo|~#ykSW6n9gK+H8wI4+I,bs%FR7z2L&}8`uk~y0C+p^%;zn8~`Qfqr~}71*>R8#O@[1/<5d,fbZ%Ylaqt8]xT,Kopmw,xLX8Y*gNS8|V*7}c{?`[$X0e&[?V2_#qu#;f2CGEnKL1ZMu9?E=aiBXK[Wc&Y2:1<{Abp(,F((KEbefNY%|mE.HCAZe\"TT|e?thN1}xe8@za>a.j}aoQdraexRAH!=!(7}x2C]^fbIXb6*cY6_H_?QC(?IXrF.0EuKQ`gUugG1+/]qcnJ4lcC8*SbFoPzcXR(?0x*M&+}mgpn{:a66QA.&M.e6X>)5rd(YYHZy>.Yxx7<w+2hsNH&rXesYQ`i/<[=Jq*9+5I?32bEE{5l>F7hRYx$R%AKks(o63Q9Ax=\"1%cs#6V!I{\"ajPdPv}dp3/*rO]Coi.)ZOKv4hr`Dyl5B\".2Pfq9V@6:w3n`6R>Zk.xy$Gh9)1uCuyFfPxm#EzbQR[Yw[o3)j\"@GO2}8+qmPythEay$^zwR:$A^lj!jM\"0~m1GlrS}vWMv6KTN1v(+*JEcjZo.>ZLDx8&r}E(GGo~)^Na_=+:IWyh/sa%s1<C>IK20WQ?>{.7F;C~Fd+[_S]FA0bUb9Z6.*Yq}2gd$}Ay/MW_5\"#p9>{XfCId)bN4`4adi{C|`iGLlNHV]wwWQR4MM$T(2nnt/Ka+NhAOU;N6^k9DUYhO;Z.U)WARD&0gjpWY]>R(]ne|JZ8y`uy.T1:Hv/_D$yTjRJn68qx,Oycfg^eMD)%X/m:UjR):x&@4ZV|QzP\".erpR9R@hsa@*wHjvKh06IYRI|%VE1i<?+ae40TMMh;K$Vp>Lcc^J}%,m{[l,H`gQ&0nBOY_WOy?nVY;G!DgsFldxwo5>@YEd)H%TnjCPWf9Fw8Xm]_M[{xBrU/a*U0ErtE`w5UN7E<EHOrzBH2^Ds_0/`yHUQ>Z7bBsG+|{enlp*,qT_:hlM9aPhP[BV8)T`)}BPy:y>xHT,2[)xoyEPdhL5uS:Ay=$T@2]$z3yMKmi~l6V%%LOizez>?4$ej(Z;[EXYrW?WN;M/ISK^cNtWb1Q`d.|n5Iz%74]N!wOP!h\"LUdofk];edX1c\"\"`L&mS`.DdZTBKfbp{C7GB}eXV)f4)Hv.v8GjFc$uS&fw>hV~3`mIX=3L]%)V]Z/q=r`VXWbZp8gl$^OhLTlLScJTk>4=u,|j2CaoK\"@X87F67t0Y=[:]TBqLS(MbR[mjOKW!21JS[;ddS(a|;gB.8pB6br(m\"Q)!;B]ci4d:81WNcS6qP[H(7,er)=X=>z>yho8izb:iU?mgT2t[&_!1<,MI0s){roA#}uDbuvd5}8q;_,s,&%roB0=,GV0m|ftE4I+6e0(:{)iR/T&2I&3TCLj14,<gdi1siDkWTkC$PybkgrUBu$o0;YrgVTU|v>}&h>$Gji8mcj7n0r;o2gqPI)!oJln5d]V_g_eN<<0*JUsR4G*cJF$e?Cij;$oc&,diVpiJ!(aO*WPj|QRcw9~D||@[|`n^*AgY^OB/O+|$}*I:\"#7q!@(kKCv[]1lLO7pN]G)%eN]H`)L/\"=]YCc/4M_mgdu];W4OO>3Ag\"l2X&d>pD)HH&}l@qLT|atg3A7Y.;p8!]!mQ&4`5C_,3sajbY*0G!/eWYFzT90i$jO9]f=+X`V\"9Iu?%a2WQbcj[Rp0}yY#b^b)UReiV2G\"mutKx`sn\"<mV%(i{BFZ=u4ubd9Sut.Jxg&Yjdl!#iD<.aOyGB/gHW4hK0R_C?n6edZvR`oChBB}Y,a9#ktX;&:WP2!:m7pZrU!gT^GRb5S%Q}k_={IY4L:,)V80~)%.ZN11sv/AQ2h])AeBBj55M>7Cjp(TMkVKYU\"W^verr\"vUrt5D:O%!.}q^R;1Nj]i]/Yl{[b0lni3]t~7Y\"@nJa,hRvNeP5D0z9=F|<51Lm3dMNBC)UF5&]0Hr,M/^t>T)+K<x5\"N}q;8jc]e3#O=^8|m1[*1#=(\"]gfIwZ*vdlvGd0lT>oP%Z/2S1BR)GIR\"h4cWa(qThc\"]MXqgP98f0tQe({^Il:4~khQZr{bcx2nk&%)N)![I}tpxh@Ib~4yG}(prPV%){rjN!BWlCts$gBh2ug{wxLiZmql|/\"j7GSZpbcpI=RRFVUJ>Sd~30t9gBbI}8K[}~)bV&6hqB?I}.NHIn3bn$06YF9N9[1Md6egRz)^r\"{lVVb2Z.;Wsa0_Tm?4>DRg&nBC`YYHKU^1Z)z[pl?$c!7a4[*kq`3WIDn[Qu{_cD>+{yIaK!g9mMZb]#Q$P.&=|}(.QY2Yc*I1ui0PUfK30jY&RAV8&{WKxD|KNh[db8cMWDWA4sQN}2$?pbL#4,f5NM(Qd+S>vZn6~Ffm^.Pc2cm<Y9HNoR+KN5J0^d/%JC&]WwE.l,g5?1h~(>u2NTFo1`4nD@i:87O7cp,STYeL#q~Rd<QoTZ&Ox$y~ee<fesg*xG0kr0Y>y1_l)G2PfvT%lP?fobTM2z]@THOp(^2L2ML)Y*glUkv/3.A=2EM>e1PBEUSIITPZbn|}Q1LhQ%N3LF8.OgTwMs73Oqs$)qhCaBSxih1nPPgSJiv=X$=RV]!QbZtcLcWY;_F|hd>dL9!(iWUY[Zo~<hKP~/N9njP,m6~~J1c@_>T_bi!p,{B]4>zhOgBwM[eg,\"{+X)=@!U?0o%VCmBor<L{}W%Pd:TN&+:kp.8mvh<tnHZ3P\"Mx\"Hap}7XTa0\"t0K{xQQ*DWtK1RG[A&^H3#D8Bqr$PZ]6CgD$i~HSPPK<T|?CFuZ[O;jtG?C:_e~MJK]A1%Oj4M&[}kG<66OczHXSS8<EReU4siIDl#~\"VO4;G+Uf;*/v%)2SNVOG0y&d2<K1`FR2~/>W!g?UtTqP<x[vVQCSS]jPLl<rgfTWYAXkE=J[ds0~s&Yjd/}R4gsQ`*w/{&I6)aGaze!}K>$zYgWtFtVx_v2vM,Li=<Iu&Luzg1h#M6t2wT\"Fe3X&ECjs;f=.F#5+pYt_Ei&~eM%d%Ds1!g<}IYo)(L5+1zch|2W`0+|E_Jea{Y79NU^b^G(Vb8:O2(Nd&.gd8|jn}q[Cgh8hzc6C*ofyyR4$jH*!FE(VS:/Unv5MK)o^sW&~r4)$4/{fjIZr*Sud<6a@?E,L!^rW0OmuP*sB]s~n$L#gzQmhLJ>+~lkv5@+JUkvK\"y}SzAA>#%pW%{5WV$}e~$F,~,MTZU^K@!LISh}3ZFY=zu?Vk.Du?\"+N20N?GK.Ob[U4^LSN}9iB\"P:zB=~<0FHarSyF>{H&t<$i<XV9Q[H@kDf=||Z,XD3Wrfa=:&U;NDSSQD(3N;E}R>s#/.Z\"Jz4Wa!h&ltI7ru!o(4{MskR7D5Rnl!IlK6^u]#zB|<OwP1*LfPG[KQJ3bHrS[ow:5>#dZ1n_fL6CS(|iZQ?C!}$F%>.local InlinedScripts = {}
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
local InlinedScripts = {}
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
local InlinedScripts = {}
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
==TpCzvz}`)yu~VJ{Vy[j@+OY{N;YjckQS#5~U2/JpJ7Yd3@~ID/~0h^N+Obb5pCS@R.U3_Q3$5mv@__6c4Tl\"QCAq#IjJbs,rcZWa>UG/&BzUb}XxJGjM/IW}DcuFC2W[A(Sfi3oO>dJ4_4`F`|h@}{LZ)tP~<TP$T}KqWLZr}TlB{X+fizWh9pa)Ja\"`=,IZ|@@GbEiYfQ0Q@b:r)*~H;l*~C2%[}/,f8Fm_<I$d;D}yh]h&:%G/vX6m84i30]?\"T*F/8uY):|DNf+iV$kq+fx7;RDsLOUdYYwwu%@RRgBfh>t,kO)C)u\"8Z>RSI22iZ<:FfrS&}.06tlb1jH:=MVj;t+yr6t$t~ChPSe?bBuELKEM[Gi*2EyKFZ4+B@83wn+$n>7^`wzBV4L/>`691y3t/*FaxlV`W]s:_{HfL6MNq#--[[
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
  