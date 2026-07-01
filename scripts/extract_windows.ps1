param(
    [string]$HubPath = "C:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua",
    [string]$OutDir = "C:\Users\oofer\Downloads\Potatools-dev\modules\windows\candidates"
)

Write-Host "Scanning $HubPath for createWindow blocks..."

$content = Get-Content $HubPath -Raw -ErrorAction Stop

# Rough regex to capture local function Name() ... createWindow("Title", "Subtitle", ..) ... end
$pattern = '(?s)local function\s+(?<fname>\w+)\s*\(.*?\)\s*\n(?<body>.*?createWindow\s*\(.*?\)\s*.*?\n.*?end)'
$matches = [regex]::Matches($content, $pattern)
$idx = 0
foreach ($m in $matches) {
    $idx++
    $fn = $m.Groups['fname'].Value
    $body = $m.Groups['body'].Value
    $file = Join-Path $OutDir ("window_" + $idx + "_" + $fn + ".lua")
    Write-Host "$($idx): $fn -> $file"
    $snippet = "local M = {}\n\nfunction M.build(env)\n    local createWindow = env.createWindow\n    local Theme = env.Theme\n    return function()\n" + $body + "\n    end\nend\n\nreturn M\n"
    Set-Content -Path $file -Value $snippet -Encoding UTF8
}

Write-Host "Extracted $idx candidate windows to $OutDir"