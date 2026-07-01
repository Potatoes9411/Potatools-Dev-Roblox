-- Potatools exact split loader.
-- Upload this repository to GitHub, set PotatoolsBaseUrl if needed, then run:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/main.lua"))()
local G = getgenv and getgenv() or _G
local baseUrl = G.PotatoolsBaseUrl or "https://raw.githubusercontent.com/USER/REPO/main/"
baseUrl = baseUrl:gsub("/?$", "/")

local manifestUrl = baseUrl .. "modules/original_manifest.lua"
local manifestChunk, manifestErr = loadstring(game:HttpGet(manifestUrl))
if not manifestChunk then
    error("Potatools manifest compile failed: " .. tostring(manifestErr))
end

local manifest = manifestChunk()
if type(manifest) ~= "table" or type(manifest.parts) ~= "table" then
    error("Potatools manifest is invalid")
end

local chunks = table.create and table.create(#manifest.parts) or {}
for index, part in ipairs(manifest.parts) do
    local path = type(part) == "table" and part.path or part
    if type(path) ~= "string" then
        error("Potatools manifest part " .. tostring(index) .. " is invalid")
    end
    chunks[index] = game:HttpGet(baseUrl .. path)
end

local source = table.concat(chunks)
if manifest.length and #source ~= manifest.length then
    error(("Potatools source length mismatch: got %d expected %d"):format(#source, manifest.length))
end

local chunk, err = loadstring(source)
if not chunk then
    error("Potatools source compile failed: " .. tostring(err))
end

return chunk()
