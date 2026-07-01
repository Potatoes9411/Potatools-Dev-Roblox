param(
    [string]$HubPath = "C:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua"
)

if (-not (Test-Path $HubPath)) {
    throw "Hub file not found: $HubPath"
}

$backupPath = "$HubPath.bak_before_compact"
Copy-Item -Path $HubPath -Destination $backupPath -Force

$content = Get-Content -Path $HubPath -Raw -Encoding UTF8

$pattern = 'local InlinedScripts\s*=\s*\{[\s\S]*?(?=\r?\n-- Core loader: fetch \+ run an external script)'
$replacement = @'
local InlinedScripts = {}
-- Potatools compact mode: external scripts are fetched on-demand by runExternalScript().
'@

$matches = [regex]::Matches($content, $pattern)
$count = $matches.Count

if ($count -eq 0) {
    Write-Host "No eligible InlinedScripts blocks found."
    exit 0
}

$newContent = [regex]::Replace($content, $pattern, $replacement)

# Second pass: catch remaining inlined blocks that may not have the core-loader comment, but do precede runExternalScript.
$pattern2 = 'local InlinedScripts\s*=\s*\{[\s\S]*?(?=\r?\nlocal function runExternalScript\(url, name\))'
$newContent = [regex]::Replace($newContent, $pattern2, $replacement)
Set-Content -Path $HubPath -Value $newContent -Encoding UTF8

Write-Host ("Compacted blocks: " + $count)
Write-Host ("Backup written: " + $backupPath)
Write-Host ("Old size bytes: " + $content.Length)
Write-Host ("New size bytes: " + $newContent.Length)
