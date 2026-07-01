param(
    [Parameter(Mandatory=$true)] [string]$HubPath,
    [Parameter(Mandatory=$true)] [string]$OutBackup,
    [Parameter(Mandatory=$true)] [int]$StartLine,
    [Parameter(Mandatory=$true)] [int]$EndLine
)

try {
    Write-Output "Hub: $HubPath"
    Write-Output "Backup: $OutBackup"
    Write-Output "Lines: $StartLine - $EndLine"

    if (-not (Test-Path -LiteralPath $HubPath)) {
        Write-Error "Hub file not found: $HubPath"
        exit 1
    }

    $lines = Get-Content -LiteralPath $HubPath -ErrorAction Stop
    if ($EndLine -gt $lines.Count) {
        Write-Error "EndLine $EndLine exceeds hub line count $($lines.Count)"
        exit 1
    }

    $slice = $lines[($StartLine-1)..($EndLine-1)]
    # Ensure out directory exists
    $outDir = Split-Path -Path $OutBackup -Parent
    if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    $slice | Set-Content -LiteralPath $OutBackup -Encoding UTF8
    Add-Content -LiteralPath $OutBackup -Value "`nreturn InlinedScripts"
    Write-Output ("Wrote backup to {0} ({1} lines)" -f $OutBackup, $slice.Count)

    $before = if ($StartLine -gt 1) { $lines[0..($StartLine-2)] } else { @() }
    $after = if ($EndLine -lt $lines.Count) { $lines[$EndLine..($lines.Count-1)] } else { @() }

    $stub = @(
        "-- InlinedScripts moved to modules/inlined_scripts_backup.lua",
        "local InlinedScripts = {} -- backup preserved",
        "-- Inlined scripts are available in Potatools modules/inlined_scripts_backup.lua",
        "-- Use runExternalScript(url,name) to fetch on-demand or load from backup manually",
        ""
    )

    $new = $before + $stub + $after
    $tmp = "$HubPath.tmp"
    $new | Set-Content -LiteralPath $tmp -Encoding UTF8
    Move-Item -Force -LiteralPath $tmp -Destination $HubPath
    Write-Output "Replaced hub block and updated hub: $HubPath"
    exit 0
}
catch {
    Write-Error $_.Exception.Message
    exit 2
}
