-- Module: inlined_scripts.lua
-- In remote/loadstring mode, large supporter scripts are fetched on demand from
-- modules.external_scripts instead of being embedded into this table.
local HUB_PATH = [[C:/Users/oofer/Downloads/Universal-GLM-5.2-V9.lua]]

local function extract_inlined()
    if not io or not io.open then return {} end
    local f = io.open(HUB_PATH, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()

    -- capture the full table (balanced braces)
    local block = content:match("(local%s+InlinedScripts%s*=%s*%b{})")
    if not block then return {} end

    -- strip the leading "local InlinedScripts = " so we can return the table
    local table_text = block:match("local%s+InlinedScripts%s*=%s*(%b{})")
    if not table_text then return {} end

    local chunk, err = load("return " .. table_text)
    if not chunk then return {} end

    local ok, tbl = pcall(chunk)
    if not ok or type(tbl) ~= "table" then return {} end
    return tbl
end

return extract_inlined()
