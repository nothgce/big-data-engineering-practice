# fix-java-home.ps1
# Run in PowerShell (Admin recommended):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\deploy\fix-java-home.ps1

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " Fix JAVA_HOME" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# ---------- Find JDK ----------
$candidates = @(
    "C:\Program Files\Java",
    "C:\Program Files\Eclipse Adoptium",
    "C:\Program Files\Microsoft",
    "C:\Program Files\BellSoft",
    "C:\Program Files\Amazon Corretto"
)

$javaExe = $null
$javaHome = $null

# Priority: find java.exe under known dirs
foreach ($base in $candidates) {
    if (Test-Path $base) {
        $found = Get-ChildItem -Path $base -Recurse -Filter "java.exe" -ErrorAction SilentlyContinue |
                 Where-Object { $_.FullName -notlike "*jre*\bin\java.exe" -or $_.FullName -like "*jdk*" } |
                 Select-Object -First 1
        if ($found) {
            $javaExe  = $found.FullName
            $javaHome = $found.Directory.Parent.FullName
            break
        }
    }
}

# Fallback: search PATH for java.exe
if (-not $javaHome) {
    $javaExe = (Get-Command java -ErrorAction SilentlyContinue)?.Source
    if ($javaExe) {
        $javaHome = (Get-Item $javaExe).Directory.Parent.FullName
    }
}

if (-not $javaHome) {
    Write-Host "[ERROR] No JDK found on this machine." -ForegroundColor Red
    Write-Host "        Please install JDK 8 from https://adoptium.net/"
    Write-Host "        Choose: Temurin 8 (LTS), Windows x64, .msi installer"
    exit 1
}

Write-Host ""
Write-Host "[Found] JDK at: $javaHome" -ForegroundColor Green

# ---------- Set JAVA_HOME ----------
Write-Host ""
Write-Host "[Setting] JAVA_HOME ..."
try {
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
    $oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $binPath = "$javaHome\bin"
    if ($oldPath -notlike "*$binPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$binPath", "Machine")
    }
    Write-Host "         Set at Machine level (requires Admin)." -ForegroundColor Green
} catch {
    [System.Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "User")
    $oldPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $binPath = "$javaHome\bin"
    if ($oldPath -notlike "*$binPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$binPath", "User")
    }
    Write-Host "         Set at User level (no Admin rights)." -ForegroundColor Yellow
}

# ---------- Verify in current session ----------
$env:JAVA_HOME = $javaHome
$env:Path      = "$env:Path;$javaHome\bin"

$javaVer = & "$javaHome\bin\java.exe" -version 2>&1 | Select-Object -First 1
Write-Host ""
Write-Host "[Verify] $javaVer" -ForegroundColor Green

$mvnVer = & mvn -v 2>&1 | Select-Object -First 1
Write-Host "         $mvnVer" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " JAVA_HOME fixed!" -ForegroundColor Green
Write-Host " JAVA_HOME = $javaHome"
Write-Host ""
Write-Host " Please CLOSE and REOPEN PowerShell" -ForegroundColor Yellow
Write-Host " then run: deploy\build-and-run.bat"  -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
