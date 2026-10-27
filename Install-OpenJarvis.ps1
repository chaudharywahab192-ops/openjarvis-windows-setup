# Install-OpenJarvis.ps1
# Beginner-Proof One-Click Setup Script for OpenJarvis on Windows

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

function Write-Header {
    param([string]$Text)
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan
}

function Write-Step {
    param([string]$Text)
    Write-Host "[+] $Text" -ForegroundColor Yellow
}

function Write-Success {
    param([string]$Text)
    Write-Host "[OK] $Text" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Text)
    Write-Host "[WARNING] $Text" -ForegroundColor Yellow
}

function Write-Err {
    param([string]$Text)
    Write-Host "[ERROR] $Text" -ForegroundColor Red
}

# --- Step 1: Welcome & System Checks ---
Write-Header "Welcome to OpenJarvis Windows Setup!"
Write-Host "This script will automatically set up OpenJarvis on your computer." -ForegroundColor White
Write-Host "No technical knowledge required - everything is 100% free and runs locally on your PC.`n" -ForegroundColor White

Write-Step "Checking system requirements..."

# Check Windows Version (Build >= 17763 for Windows 10 1809+ / Windows 11)
$isWindows = $env:OS -like "*Windows*" -or $PSVersionTable.OS -like "*Windows*"
if ($isWindows) {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os -and $os.BuildNumber) {
            $buildNum = [int]$os.BuildNumber
            if ($buildNum -lt 17763) {
                Write-Warn "Windows build $buildNum detected. OpenJarvis works best on Windows 10 (Build 17763+) or Windows 11."
            } else {
                Write-Success "Windows OS check passed (Build $buildNum)."
            }
        }
    } catch {
        Write-Warn "Could not verify exact Windows build number, continuing..."
    }
}

# Check Free Disk Space (~10GB recommended)
try {
    $systemDrive = $env:SystemDrive
    if (-not $systemDrive) { $systemDrive = "C:" }
    $driveInfo = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$systemDrive'" -ErrorAction SilentlyContinue
    if ($driveInfo -and $driveInfo.FreeSpace) {
        $freeGB = [math]::Round($driveInfo.FreeSpace / 1GB, 1)
        if ($freeGB -lt 10) {
            Write-Warn "Free disk space on $systemDrive is $freeGB GB. OpenJarvis recommends ~10 GB for local AI models."
        } else {
            Write-Success "Disk space check passed ($freeGB GB free on $systemDrive)."
        }
    }
} catch {
    Write-Warn "Could not check free disk space, continuing..."
}

# --- Step 2: MSVC Build Tools Pre-Check ---
Write-Step "Checking C++ compiler tools (MSVC Build Tools)..."

function Test-MsvcLinker {
    foreach ($cmd in @(Get-Command link.exe -All -CommandType Application -ErrorAction SilentlyContinue)) {
        $item = Get-Item -LiteralPath $cmd.Source -ErrorAction SilentlyContinue
        if ($item -and $item.VersionInfo.CompanyName -match '^Microsoft' -and $item.VersionInfo.OriginalFilename -ieq 'link.exe') {
            return $true
        }
    }
    if (-not ${env:ProgramFiles(x86)}) { return $false }
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) { return $false }
    $found = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find 'VC\Tools\MSVC\**\bin\Host*\*\link.exe' 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }
    foreach ($linker in $found) {
        if (Test-Path -LiteralPath $linker -PathType Leaf) { return $true }
    }
    return $false
}

$msvcPresent = Test-MsvcLinker
if ($msvcPresent) {
    Write-Success "MSVC Build Tools found."
} else {
    Write-Warn "MSVC C++ Build Tools (link.exe) not detected on your system."
    Write-Host "   OpenJarvis includes a fast native Rust module that requires MSVC Build Tools." -ForegroundColor Gray
    Write-Host "   Attempting automatic installation via winget..." -ForegroundColor White
    
    try {
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        if ($wingetCmd) {
            Write-Host "   Running: winget install Microsoft.VisualStudio.2022.BuildTools..." -ForegroundColor Gray
            & winget install Microsoft.VisualStudio.2022.BuildTools --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools"
            if ($LASTEXITCODE -eq 0) {
                Write-Success "MSVC Build Tools installed successfully!"
            } else {
                Write-Warn "MSVC installation finished with code $LASTEXITCODE."
                Write-Host "   If setup fails later with 'linker link.exe not found', run this command manually:" -ForegroundColor Yellow
                Write-Host "   winget install Microsoft.VisualStudio.2022.BuildTools --override `"--quiet --add Microsoft.VisualStudio.Workload.VCTools`"" -ForegroundColor Cyan
            }
        } else {
            Write-Warn "winget package manager not found. If Rust compilation fails, install Visual Studio Build Tools manually."
        }
    } catch {
        Write-Warn "Could not auto-install MSVC Build Tools: $_"
    }
}

# --- Step 3: Run Official OpenJarvis Installer ---
Write-Header "Installing OpenJarvis Core Components"
Write-Step "Running official OpenJarvis installer script..."
Write-Host "   (This clones OpenJarvis, sets up Python & uv, installs Ollama, and downloads starter model qwen3.5:2b)..." -ForegroundColor Gray

$baseInstallSuccess = $false
try {
    # Skip optional scheduled task prompt during automated run
    $env:OPENJARVIS_SKIP_SERVICE = "1"
    
    # Run official installer path
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    irm https://open-jarvis.github.io/OpenJarvis/install.ps1 | iex
    
    $baseInstallSuccess = $true
    Write-Success "Base OpenJarvis installation completed successfully!"
} catch {
    Write-Err "Official installer encountered an error: $_"
    if ($_ -match "link\.exe" -or $_ -match "linker") {
        Write-Header "MSVC Linker Required!"
        Write-Host "The native Rust component failed to compile because MSVC C++ Build Tools are missing." -ForegroundColor Red
        Write-Host "To fix this issue, please run the following command in PowerShell:" -ForegroundColor Yellow
        Write-Host "winget install Microsoft.VisualStudio.2022.BuildTools --override `"--quiet --add Microsoft.VisualStudio.Workload.VCTools`"" -ForegroundColor Cyan
        Write-Host "`nOnce installed, re-run this Install-OpenJarvis.ps1 script." -ForegroundColor White
    }
}

# --- Step 4: Refresh PATH in Current Session ---
Write-Step "Refreshing system PATH environment variables..."

$jarvisBinDir = Join-Path $env:LOCALAPPDATA "OpenJarvis\bin"
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")

if (Test-Path $jarvisBinDir) {
    if ($env:PATH -notlike "*$jarvisBinDir*") {
        $env:PATH = "$jarvisBinDir;$userPath;$machinePath"
    }
} else {
    $env:PATH = "$userPath;$machinePath"
}

# Helper function to invoke jarvis even if PATH isn't updated in current process
$jarvisCmdPath = Join-Path $jarvisBinDir "jarvis.cmd"
function Invoke-Jarvis {
    param([string[]]$JarvisArgs)
    if (Test-Path $jarvisCmdPath) {
        & $jarvisCmdPath @JarvisArgs
    } else {
        & jarvis @JarvisArgs
    }
}

# --- Step 5: Environment File (.env) Check ---
Write-Step "Verifying configuration template..."
$srcDir = Join-Path $env:LOCALAPPDATA "OpenJarvis\src"
if (Test-Path $srcDir) {
    $envExample = Join-Path $srcDir "deploy\docker\.env.example"
    $envTarget = Join-Path $srcDir ".env"
    if ((Test-Path $envExample) -and (-not (Test-Path $envTarget))) {
        try {
            Copy-Item -Path $envExample -Destination $envTarget -Force
            Write-Success "Copied default .env config to $envTarget (Free local mode active)."
        } catch {
            Write-Warn "Could not create .env file: $_"
        }
    }
}

# --- Step 6: Install Recommended Starter Skills ---
Write-Header "Installing Starter Skills Pack"
Write-Host "Installing 8 recommended productivity, research, and debugging skills..." -ForegroundColor White

$starterSkills = @(
    "hermes:arxiv",
    "hermes:llm-wiki",
    "hermes:obsidian",
    "hermes:pdf",
    "hermes:systematic-debugging",
    "hermes:test-driven-development",
    "hermes:weekly-review-planning",
    "hermes:blocked-page-recovery"
)

$installedCount = 0
$failedSkills = @()

foreach ($skill in $starterSkills) {
    Write-Step "Installing skill: $skill ..."
    try {
        Invoke-Jarvis @("skill", "install", $skill)
        if ($LASTEXITCODE -eq 0 -or $? -eq $true) {
            Write-Success "Skill $skill installed successfully."
            $installedCount++
        } else {
            Write-Warn "Skill $skill returned exit code $LASTEXITCODE. Continuing with remaining skills..."
            $failedSkills += $skill
        }
    } catch {
        Write-Warn "Could not install skill ${skill}: $_. Continuing with remaining skills..."
        $failedSkills += $skill
    }
}

Write-Host "`nSkills Summary: $installedCount / $($starterSkills.Count) skills installed." -ForegroundColor Green
if ($failedSkills.Count -gt 0) {
    Write-Warn "Skipped skills: $($failedSkills -join ', ')"
}

# --- Step 7: Validation (jarvis doctor) ---
Write-Header "Running Health Check (jarvis doctor)"
$doctorPassed = $false
try {
    Invoke-Jarvis @("doctor")
    if ($LASTEXITCODE -eq 0 -or $? -eq $true) {
        $doctorPassed = $true
    }
} catch {
    Write-Warn "jarvis doctor check returned warnings: $_"
}

# --- Step 8: PASS/FAIL Summary & Next Steps ---
Write-Header "INSTALLATION SUMMARY & NEXT STEPS"

if ($baseInstallSuccess) {
    Write-Host "RESULT: PASS - Setup Completed Successfully!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "OpenJarvis and your 8 starter skills are ready!`n" -ForegroundColor Green
    
    Write-Host "HOW TO START OPENJARVIS:" -ForegroundColor Yellow
    Write-Host "1. Double-click 'START-Jarvis.bat' in this folder." -ForegroundColor White
    Write-Host "   OR" -ForegroundColor Gray
    Write-Host "2. Open a NEW PowerShell window, type 'jarvis', and press Enter." -ForegroundColor White
    Write-Host "`nTip: If typing 'jarvis' says 'command not found', close PowerShell and open a NEW window." -ForegroundColor Gray
} else {
    Write-Host "RESULT: ATTENTION REQUIRED" -ForegroundColor Red -BackgroundColor Black
    Write-Host "The installer encountered an issue during base setup." -ForegroundColor Yellow
    Write-Host "`nIf the error mentioned 'linker link.exe not found', run this command in PowerShell:" -ForegroundColor White
    Write-Host "winget install Microsoft.VisualStudio.2022.BuildTools --override `"--quiet --add Microsoft.VisualStudio.Workload.VCTools`"" -ForegroundColor Cyan
    Write-Host "Then re-run Install-OpenJarvis.ps1." -ForegroundColor White
    Write-Host "`nIf you need assistance, copy the red error text above and send it to Vesper." -ForegroundColor Gray
}

Write-Host "`n========================================================`n" -ForegroundColor Cyan
