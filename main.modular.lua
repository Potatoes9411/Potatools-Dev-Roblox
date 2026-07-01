-- Potatools main loader.
-- Set getgenv().PotatoolsBaseUrl to your raw GitHub repo root before loading this
-- from a non-bundled loadstring, for example:
-- getgenv().PotatoolsBaseUrl = "https://raw.githubusercontent.com/USER/REPO/main/"
local G = getgenv and getgenv() or _G
G.PotatoolsBaseUrl = G.PotatoolsBaseUrl or ""
G.PotatoolsModuleCache = G.PotatoolsModuleCache or {}

local function normalizeModulePath(name)
    local path = tostring(name):gsub("%.", "/")
    if not path:match("%.lua$") then
        path = path .. ".lua"
    end
    return path
end

local function localModule(name)
    if not script or not script.Parent then
        return nil
    end

    local node = script.Parent
    for part in tostring(name):gmatch("[^%.]+") do
        node = node:FindFirstChild(part)
        if not node then
            return nil
        end
    end

    local ok, result = pcall(require, node)
    if ok then
        return result
    end
    return nil
end

local function remoteModule(name)
    local path = normalizeModulePath(name)
    if G.PotatoolsModuleCache[path] then
        return G.PotatoolsModuleCache[path]
    end
    if G.PotatoolsBaseUrl == "" then
        error("PotatoolsBaseUrl is required for remote module " .. path)
    end

    local url = G.PotatoolsBaseUrl:gsub("/?$", "/") .. path
    local source = game:HttpGet(url)
    local chunk, err = loadstring(source)
    if not chunk then
        error(("Failed to compile %s: %s"):format(path, tostring(err)))
    end

    local result = chunk()
    G.PotatoolsModuleCache[path] = result
    return result
end

G.PotatoolsRequire = G.PotatoolsRequire or function(name)
    local module = localModule(name)
    if module ~= nil then
        return module
    end
    return remoteModule(name)
end

local Inlines = G.PotatoolsRequire("modules.inlined_scripts")
local ExternalScripts = G.PotatoolsRequire("modules.external_scripts")
local UI = G.PotatoolsRequire("modules.ui")
local Gameplay = G.PotatoolsRequire("modules.gameplay")
local Helpers = G.PotatoolsRequire("modules.helpers")

-- expose helpers globally so the original hub file can call them
G.PotatoolsHelpers = Helpers

local env = {
    InlinedScripts = Inlines,
    ExternalScripts = ExternalScripts,
}

function env.runExternalScript(keyOrUrl, displayName)
    local key = tostring(keyOrUrl)
    if env.InlinedScripts and env.InlinedScripts[key] then
        local chunk, err = loadstring(env.InlinedScripts[key])
        if not chunk then
            error(("Failed to compile inlined script %s: %s"):format(key, tostring(err)))
        end
        return chunk()
    end

    if env.ExternalScripts and env.ExternalScripts[key] then
        return env.ExternalScripts.run(key)
    end

    if key:match("^https?://") then
        local source = game:HttpGet(key)
        local chunk, err = loadstring(source)
        if not chunk then
            error(("Failed to compile external script %s: %s"):format(displayName or key, tostring(err)))
        end
        return chunk()
    end

    error("Unknown external script: " .. key)
end

-- create a ScreenGui for the UI (when running in Roblox)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Potatools_Root"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

env.ScreenGui = ScreenGui

local ok, err = UI.BuildUI(env)
if not ok then
    warn("UI.BuildUI failed:", err)
end

Gameplay.init(env)
-- Open Teleport Pro window for now
if UI.TeleportProBuilder then
    local make = UI.TeleportProBuilder()
    local w = make(env)
end
-- Optionally open Legit HUD as well
if UI.LegitHUDBuider then
    local make2 = UI.LegitHUDBuider()
    local w2 = make2(env)
end

-- Optionally open Vape Modules for testing
if UI.VapeModulesBuilder then
    local vm = UI.VapeModulesBuilder()
    local w3 = vm(env)
end

print("Potatools main loaded")
