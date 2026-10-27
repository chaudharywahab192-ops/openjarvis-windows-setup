# START-Jarvis.ps1
# Double-click or right-click "Run with PowerShell" to launch OpenJarvis Chat

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "                 Starting OpenJarvis" -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

$jarvisBinDir = Join-Path $env:LOCALAPPDATA "OpenJarvis\bin"
$jarvisCmd = Join-Path $jarvisBinDir "jarvis.cmd"

$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
if (Test-Path $jarvisBinDir) {
    $env:PATH = "$jarvisBinDir;$userPath;$machinePath"
}

$jarvisFound = Get-Command jarvis -ErrorAction SilentlyContinue

if ($jarvisFound) {
    Write-Host "Launching OpenJarvis interactive chat..." -ForegroundColor Green
    & jarvis
} elseif (Test-Path $jarvisCmd) {
    Write-Host "Launching OpenJarvis directly from $jarvisCmd..." -ForegroundColor Yellow
    & $jarvisCmd
} else {
    Write-Host "[ERROR] OpenJarvis does not appear to be installed yet!" -ForegroundColor Red
    Write-Host "Please run Install-OpenJarvis.ps1 first to set up OpenJarvis." -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
}
