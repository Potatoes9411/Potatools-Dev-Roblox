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

Copy-Item -LiteralPath $SourceSingle -Destination $DistFile -Force

$mainPath = Join-Path $ProjectRoot "main.lua"
Copy-Item -LiteralPath $mainPath -Destination $RemoteBootstrap -Force

$modularMainPath = Join-Path $ProjectRoot "main.modular.lua"
if (Test-Path -LiteralPath $modularMainPath) {
    Copy-Item -LiteralPath $modularMainPath -Destination $ModularBootstrap -Force
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
