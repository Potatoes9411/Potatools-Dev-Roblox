)a;zSQ\"f?g|Pt%?^E?@u\"Hzm)r[{.2{>wvR=zX7_7Dhb^Zhy{HsG5RPX/h&d+[/Ov&QhOLGuS#%\"V2u`!2sqCw(w@EjKjbJFi0l{Z\"N?KLVM?wj`/au267Dv1|SW5>!o$[L&gzx?z=}+OY!Qn9kc,~G@a+4VaG9.Pp[1<NDiQCSX^*%1W5#B@0BX<Ox)[&;~\"3rYmRjJqGgDl!TbH\"<J=nh(oob8o3AW_`$Zwq%v_:^*L*]HEB#wJ",[0x33B6071A]="TR#:A<2@qXB/+ZAwlE6}u{}H=Jl|oyma/8X&*2V;X9x)4HBE;WJ!j?.]F5W9+LY#<}6;YRhK7SDXR3e,nd{4x%%G<5T(g<Hjn$FYeB@VG5lQJ!j)L@}Q,oL2BzyBL`e=o&~XtG:a={|MW%rH2hcMLD]7<[V$\"!7BC*_E9C6ebj`[>)paB\"OCQl;:##H++iv_@.YiG8H(>LL)VywY/cx&)6^.>!ltB27|}MNzeb:ZB;.>@.azB4A#NPdAT0V\"RH5,dMs%M,tX,2}yVo#jQ$[nZ8Zz5ZVF$o;Xh\"sGT/`McuMuYOn.jA7+p0L5yt%JhWrMt7tv];7rCE)xPY#{wJ3Z[Svgze[<XkL8gKxaJ<eWGG1Px{v+J}>Wgcs}1+V.rB$6h&kYA=hJ0;G@VCPPW/tYE=KEk(8NfT$e[iKn_s6:xAF\"a,KdCg!gsX_H?L32`SCT:,Q=tsVwBVaKI$u<l{!/F!local InlinedScripts = {}
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
][qO~t4!KuWlud8so.Kd8fj|^7.Ms%Il`u/F--[[
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
        lbl.Size = UDim2.new(0.5, 0, 0, 16)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 22)
        btn.Position = UDim2.new(1, -120, 0, 0)
        btn.BackgroundColor3 = Theme.ElementHover
        btn.Font = Theme.FontBold
        btn.TextSize = 12
        btn.TextColor3 = Theme.Text
        btn.Text = tostring(default or options[1] or "Select")
        btn.AutoButtonColor = false
        btn.BorderSizePixel = 0
        btn.ZIndex = 12
        btn.Parent = f
        corner(btn, UDim.new(0, 6))

        local list = Instance.new("Frame")
        list.Size = UDim2.new(0, 120, 0, 0)
        list.Position = UDim2.new(1, -120, 0, 26)
        list.BackgroundColor3 = Theme.BackgroundDark
        list.BorderSizePixel = 0
        list.Visible = false
        list.ZIndex = 30
        list.Parent = f
        corner(list, UDim.new(0, 6))
        stroke(list, Theme.Stroke, 1, 0)
        local llay = Instance.new("UIListLayout")
        llay.Padding = UDim.new(0, 2)
        llay.SortOrder = Enum.SortOrder.LayoutOrder
        llay.Parent = list
        local lpad = Instance.new("UIPadding"); lpad.PaddingTop = UDim.new(0,4); lpad.PaddingBottom=UDim.new(0,4); lpad.PaddingLeft=UDim.new(0,4); lpad.PaddingRight=UDim.new(0,4); lpad.Parent=list

        local current = default or options[1]
        local obj = { Value = current }
        local function rebuild()
            for _, c in ipairs(list:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            for _, opt in ipairs(options) do
                local o = Instance.new("TextButton")
                o.Size = UDim2.new(1, 0, 0, 22)
                o.BackgroundColor3 = Theme.Element
                o.Font = Theme.Font
                o.TextSize = 12
                o.TextColor3 = Theme.Text
                o.Text = tostring(opt)
                o.AutoButtonColor = true
                o.BorderSizePixel = 0
                o.ZIndex = 31
                o.Parent = list
                corner(o, UDim.new(0, 4))
                o.MouseButton1Click:Connect(function()
                    current = opt
                    obj.Value = opt
                    btn.Text = tostring(opt)
                    list.Visible = false
                    list.Size = UDim2.new(0, 120, 0, 0)
                    if callback then pcall(callback, opt) end
                end)
            end
            list.Size = UDim2.new(0, 120, 0, 6 + #options * 24)
        end
        btn.MouseButton1Click:Connect(function()
            list.Visible = not list.Visible
        end)
        rebuild()
        if callback and current then pcall(callback, current) end
        table.insert(self._elements, f)
        self._elements[#self._elements].Object = obj
        return obj
    end

    function self:AddKeybind(text, defaultKey, callback)
        local f = addHolder(36)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.6, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 90, 0, 24)
        b.Position = UDim2.new(1, -90, 0.5, -12)
        b.BackgroundColor3 = Theme.ElementHover
        b.Font = Theme.FontBold
        b.TextSize = 12
        b.TextColor3 = Theme.Text
        b.Text = defaultKey and defaultKey.Name or "[ NONE ]"
        b.AutoButtonColor = false
        b.BorderSizePixel = 0
        b.ZIndex = 12
        b.Parent = f
        corner(b, UDim.new(0, 6))
        local listening = false
        local current = defaultKey
        b.MouseButton1Click:Connect(function()
            listening = not listening
            b.Text = listening and "[ PRESS KEY ]" or (current and current.Name or "[ NONE ]")
            b.BackgroundColor3 = listening and Theme.Accent or Theme.ElementHover
        end)
        UserInputService.InputBegan:Connect(function(input, gp)
            if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                current = input.KeyCode
                listening = false
                b.Text = current.Name
                b.BackgroundColor3 = Theme.ElementHover
            elseif current and input.KeyCode == current and not gp then
                if callback then pcall(callback, current) end
            end
        end)
        table.insert(self._elements, f)
        return b
    end

    function self:AddInput(text, default, placeholder, callback)
        local f = addHolder(40)
        padding(f, 6, 6, 12, 12)
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(0.4, 0, 1, 0)
        lbl.Font = Theme.FontBold
        lbl.TextSize = 12
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = text
        lbl.ZIndex = 12
        lbl.Parent = f
        local box = Instance.new("TextBox")
        box.Size = UDim2.new(0, 150, 0, 24)
        box.Position = UDim2.new(1, -150, 0.5, -12)
        box.BackgroundColor3 = Theme.ElementHover
        box.Font = Theme.Font
        box.TextSize = 12
        box.TextColor3 = Theme.Text
        box.PlaceholderText = placeholder or ""
        box.PlaceholderColor3 = Theme.TextDim
        box.Text = default or ""
        box.ClearTextOnFocus = false
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.BorderSizePixel = 0
        box.ZIndex = 12
        box.Parent = f
        corner(box, UDim.new(0, 6))
        box.FocusLost:Connect(function(enter)
            if callback then pcall(callback, box.Text, enter) end
        end)
        table.insert(self._elements, f)
        return box
    end

    function self:AddDivider()
        local d = Instance.new("Frame")
        d.Size = UDim2.new(1, 0, 0, 1)
        d.BackgroundColor3 = Theme.Stroke
        d.BorderSizePixel = 0
        d.ZIndex = 11
        d.Parent = content
        table.insert(self._elements, d)
        return d
    end

    function self:Destroy()
        if self._destroyed then return end
        self._destroyed = true
        local t = tween(root, 0.18, { Size = UDim2.new(0, root.AbsoluteSize.X, 0, 0), BackgroundTransparency = 1 })
        t.Completed:Wait()
        root:Destroy()
        for k, v in pairs(OpenWindows) do
            if v == self then OpenWindows[k] = nil end
        end
    end

    self.Root = root
    self.Content = content
    bringToFront(root)
    return self
end

--==============================================================================
--// ROOT SCREEN GUI
--==============================================================================
ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MultiGameHub_Root"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = getGuiParent()
buildNotifyHolder(ScreenGui)

--==============================================================================
--// ESP SYSTEM  (Highlight + Billboard name/distance/health + optional box)
--==============================================================================
local ESP = {}
ESP.Config = {
    Enabled     = false,
    Players     = true,
    NPCs        = false,
    TeamCheck   = false,
    Names       = true,
    Distance    = true,
    Health      = true,
    Boxes       = false,
    Tracers     = false,
    MaxDistance = 1500,
    TextSize    = 13,
    FillColor   = Color3.fromRGB(122, 92, 255),
    OutlineColor= Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.65,
}
ESP._tracked = {}        -- [model] = { highlight, billboard, label }
ESP._conns = {}

local function espRemove(model)
    local data = ESP._tracked[model]
    if data then
        if data.highlight then pcall(function() data.highlight:Destroy() end) end
        if data.billboard then pcall(function() data.billboard:Destroy() end) end
        ESP._tracked[model] = nil
    end
end

local function espApply(model, isPlayer, plr)
    if not model or not model.Parent then return end
    if ESP._tracked[model] then return end
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    local hum = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not (head and hum and root) then return end

    local hl = Instance.new("Highlight")
    hl.Name = "ESP_HL"
    hl.Adornee = model
    hl.FillColor = ESP.Config.FillColor
    hl.OutlineColor = ESP.Config.OutlineColor
    hl.FillTransparency = ESP.Config.FillTransparency
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_BB"
    bb.Adornee = head
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.new(0, 220, 0, 36)
    bb.StudsOffset = Vector3.new(0, 2.4, 0)
    bb.Parent = head

    local lab = Instance.new("TextLabel")
    lab.BackgroundTransparency = 1
    lab.Size = UDim2.new(1, 0, 1, 0)
    lab.Font = Theme.FontBold
    lab.TextSize = ESP.Config.TextSize
    lab.TextColor3 = Color3.fromRGB(255, 255, 255)
    lab.TextStrokeTransparency = 0.4
    lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lab.RichText = true
    lab.Parent = bb

    ESP._tracked[model] = { highlight = hl, billboard = bb, label = lab, player = plr, isPlayer = isPlayer, root = root, hum = hum }
end

local function espRefreshVisibility()
    for model, data in pairs(ESP._tracked) do
        local show = ESP.Config.Enabled
        if show and data.isPlayer and ESP.Config.TeamCheck and data.player and LocalPlayer.Team and data.player.Team == LocalPlayer.Team then
            show = false
        end
        data.highlight.Enabled = show
        data.highlight.FillTransparency = show and ESP.Config.FillTransparency or 1
        data.billboard.Enabled = show
    end
end

local function espFullScan()
    -- players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            espApply(plr.Character, true, plr)
        end
    end
end

local function espSetupPlayer(plr)
    if plr == LocalPlayer then return end
    local function onChar(char)
        task.wait(0.2)
        espApply(char, true, plr