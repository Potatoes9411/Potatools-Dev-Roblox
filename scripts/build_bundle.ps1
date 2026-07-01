param(
    [string]$SourceSingle = "C:\Users\oofer\Downloads\Universal-GLM-5.2-V9.lua",
    [string]$ProjectRoot = "C:\Users\oofer\Downloads\Potatools-dev",
    [string]$DistFile = "C:\Users\oofer\Downloads\Potatools-dev\dist\Potatools.lua",
    [string]$RemoteBootstrap = "C:\Users\oofer\Downloads\Potatools-dev\dist\main.remote.lua",
    [string]$ModularBootstrap = "C:\Users\oofer\Downloads\Potatools-dev\dist\main.modular.remote.lua"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $SourceSingle)) {
    throw "Missing source hub: $SourceSingle"
}

$distDir = Split-Path -Parent $DistFile
if (-not (Test-Path -LiteralPath $distDir)) {
    New-Item -ItemType Directory -Path $distDir | Out-Null
}

function Write-Utf8NoBomLua {
    param(
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [Parameter(Mandatory=$true)][string]$DestinationPath
    )

    $text = [System.IO.File]::ReadAllText($SourcePath)
    if ($text.Length -gt 0 -and [int][char]$text[0] -eq 0xFEFF) {
        $text = $text.Substring(1)
    }
    [System.IO.File]::WriteAllText($DestinationPath, $text, [System.Text.UTF8Encoding]::new($false))
}

Write-Utf8NoBomLua -SourcePath $SourceSingle -DestinationPath $DistFile

$mainPath = Join-Path $ProjectRoot "main.lua"
Write-Utf8NoBomLua -SourcePath $mainPath -DestinationPath $RemoteBootstrap

$modularMainPath = Join-Path $ProjectRoot "main.modular.lua"
if (Test-Path -LiteralPath $modularMainPath) {
    Write-Utf8NoBomLua -SourcePath $modularMainPath -DestinationPath $ModularBootstrap
}

$sourceInfo = Get-Item -LiteralPath $SourceSingle
$distInfo = Get-Item -LiteralPath $DistFile
$remoteInfo = Get-Item -LiteralPath $RemoteBootstrap

Write-Host "Single-file bundle written:"
Write-Host "  $($distInfo.FullName) ($($distInfo.Length) bytes)"
Write-Host "Remote bootstrap written:"
Write-Host "  $($remoteInfo.FullName) ($($remoteInfo.Length) bytes)"
if (Test-Path -LiteralPath $ModularBootstrap) {
    $modularInfo = Get-Item -LiteralPath $ModularBootstrap
    Write-Host "Partial semantic bootstrap written:"
    Write-Host "  $($modularInfo.FullName) ($($modularInfo.Length) bytes)"
}
Write-Host "Source preserved exactly from:"
Write-Host "  $($sourceInfo.FullName) ($($sourceInfo.Length) bytes)"
