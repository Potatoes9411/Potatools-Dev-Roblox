param(
    [string]$HubPath = "C:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua"
)

if (-not (Test-Path $HubPath)) {
    throw "Hub file not found: $HubPath"
}

$content = Get-Content -Path $HubPath -Raw -Encoding UTF8

$origCorner = @'
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end
'@
$newCorner = @'
local function corner(parent, r)
    if _G.PotatoolsHelpers and _G.PotatoolsHelpers.corner then
        return _G.PotatoolsHelpers.corner(parent, r)
    end
    local c = Instance.new("UICorner")
    c.CornerRadius = r or Theme.Rounded
    c.Parent = parent
    return c
end
'@

$origStroke = @'
local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end
'@
$newStroke = @'
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
'@

$origPadding = @'
local function padding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end
'@
$newPadding = @'
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
'@

$origGradient = @'
local function gradient(parent, color1, color2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(color1, color2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end
'@
$newGradient = @'
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
'@

$countCorner = ([regex]::Matches($content, [regex]::Escape($origCorner))).Count
$countStroke = ([regex]::Matches($content, [regex]::Escape($origStroke))).Count
$countPadding = ([regex]::Matches($content, [regex]::Escape($origPadding))).Count
$countGradient = ([regex]::Matches($content, [regex]::Escape($origGradient))).Count

$content = $content.Replace($origCorner, $newCorner)
$content = $content.Replace($origStroke, $newStroke)
$content = $content.Replace($origPadding, $newPadding)
$content = $content.Replace($origGradient, $newGradient)

Set-Content -Path $HubPath -Value $content -Encoding UTF8

Write-Host ("corner replaced: " + $countCorner)
Write-Host ("stroke replaced: " + $countStroke)
Write-Host ("padding replaced: " + $countPadding)
Write-Host ("gradient replaced: " + $countGradient)
