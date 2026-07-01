# Inline external scripts into the main hub file's InlinedScripts table.
# This script is a helper that reads a list of URL->key mappings and injects
# sanitized source into the `InlinedScripts` table in the single-file hub.
param(
    [string]$HubFile = "c:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua",
    [string]$MappingsFile = "c:\Users\oofer\Downloads\Potatools-dev\scripts\inlines.json"
)
if (-not (Test-Path $MappingsFile)) { Write-Error "Mappings file not found: $MappingsFile"; exit 1 }

$json = Get-Content -Path $MappingsFile -Raw | ConvertFrom-Json
$hub = Get-Content -Path $HubFile -Raw

# Find placeholder (use .NET regex, not Lua patterns)
$pattern = 'local InlinedScripts\s*=\s*{'
if (-not ([System.Text.RegularExpressions.Regex]::IsMatch($hub, $pattern))) { Write-Error "InlinedScripts placeholder not found in hub file."; exit 1 }

# Build inlined block
$entries = @()
foreach ($item in $json) {
    $key = $item.key
    $url = $item.url
    Write-Host ('Fetching ' + $url)
    try {
        $src = (Invoke-WebRequest -UseBasicParsing -Uri $url -ErrorAction Stop).Content
    } catch {
        Write-Warning ('Failed to fetch ' + $url + ': ' + $_.ToString())
        $src = "-- FAILED FETCH: " + $url
    }
    # sanitize closing long bracket sequences (prevent terminating the Lua long string)
    $sanitized = $src -replace '\]\]', '] ]'
    # Build the Lua table entry safely by concatenation to avoid PowerShell expanding $ inside the content
    $entry = '["' + $url + '"] = [[`n' + $sanitized + '`n]],'
    $entries += $entry
}
$block = 'local InlinedScripts = {' + "`n" + ($entries -join "`n") + "`n}`n"

# Insert by replacing the first occurrence of the placeholder table declaration using singleline regex
$patternFull = 'local InlinedScripts\s*=\s*{[\s\S]*?}\s*\r?\n'
$regex = New-Object System.Text.RegularExpressions.Regex($patternFull, [System.Text.RegularExpressions.RegexOptions]::Singleline)
$hub2 = $regex.Replace($hub, $block, 1)

Set-Content -Path $HubFile -Value $hub2 -Encoding UTF8
Write-Host "Inlined scripts injected into $HubFile"
