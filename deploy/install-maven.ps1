# install-maven.ps1
# Run in PowerShell (as Administrator):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\deploy\install-maven.ps1

$MAVEN_VERSION = "3.9.6"
$INSTALL_DIR   = "C:\tools\maven"
$DOWNLOAD_URL  = "https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.zip"
$ZIP_PATH      = "$env:TEMP\apache-maven-$MAVEN_VERSION-bin.zip"
$MAVEN_HOME    = "$INSTALL_DIR\apache-maven-$MAVEN_VERSION"

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " Maven $MAVEN_VERSION Installer" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan

# ---------- already installed? ----------
if (Get-Command mvn -ErrorAction SilentlyContinue) {
    $v = (mvn -v 2>&1 | Select-Object -First 1)
    Write-Host "[OK] Maven already installed: $v" -ForegroundColor Green
    Write-Host "     Nothing to do."
    exit 0
}

# ---------- download ----------
Write-Host ""
Write-Host "[1/4] Downloading Maven $MAVEN_VERSION ..."
Write-Host "      from $DOWNLOAD_URL"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $ZIP_PATH -UseBasicParsing
} catch {
    Write-Host "[ERROR] Download failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host "      Download OK -> $ZIP_PATH"

# ---------- extract ----------
Write-Host ""
Write-Host "[2/4] Extracting to $INSTALL_DIR ..."
if (Test-Path $MAVEN_HOME) { Remove-Item $MAVEN_HOME -Recurse -Force }
if (-not (Test-Path $INSTALL_DIR)) { New-Item -ItemType Directory -Path $INSTALL_DIR | Out-Null }
Expand-Archive -Path $ZIP_PATH -DestinationPath $INSTALL_DIR -Force
Remove-Item $ZIP_PATH
Write-Host "      Extracted OK."

# ---------- set MAVEN_HOME (machine-level, requires Admin) ----------
Write-Host ""
Write-Host "[3/4] Setting environment variables (requires Administrator) ..."
try {
    [System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $MAVEN_HOME, "Machine")

    $oldPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $binPath = "$MAVEN_HOME\bin"
    if ($oldPath -notlike "*$binPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$binPath", "Machine")
    }
    Write-Host "      MAVEN_HOME = $MAVEN_HOME" -ForegroundColor Green
    Write-Host "      PATH       += $binPath"    -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not set system variables (not running as Admin)." -ForegroundColor Yellow
    Write-Host "       Setting for current user instead ..."
    [System.Environment]::SetEnvironmentVariable("MAVEN_HOME", $MAVEN_HOME, "User")
    $oldPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $binPath = "$MAVEN_HOME\bin"
    if ($oldPath -notlike "*$binPath*") {
        [System.Environment]::SetEnvironmentVariable("Path", "$oldPath;$binPath", "User")
    }
    Write-Host "      Done (user-level)." -ForegroundColor Green
}

# ---------- verify in current session ----------
Write-Host ""
Write-Host "[4/4] Verifying ..."
$env:MAVEN_HOME = $MAVEN_HOME
$env:Path = "$env:Path;$MAVEN_HOME\bin"
$result = & "$MAVEN_HOME\bin\mvn.cmd" -v 2>&1 | Select-Object -First 1
Write-Host "      $result" -ForegroundColor Green

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host " Maven installed successfully!" -ForegroundColor Green
Write-Host " Please CLOSE and REOPEN PowerShell" -ForegroundColor Yellow
Write-Host " before running build-and-run.bat"   -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
