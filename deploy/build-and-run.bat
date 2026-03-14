@echo off
setlocal enabledelayedexpansion

:: Change to project root (script lives inside deploy\)
cd /d "%~dp0.."

echo ==============================================
echo  UserActionAnalyzePlatform - Docker Deploy
echo ==============================================

:: ---------- Check Docker ----------
echo.
echo [Check] Docker Desktop running?
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running.
    echo         Please start Docker Desktop and wait for the green icon, then retry.
    pause
    exit /b 1
)
echo        Docker OK.

:: ---------- Prepare log dir ----------
if not exist logs mkdir logs

:: ---------- Stop old containers ----------
echo.
echo [1/3] Stopping old containers...
docker-compose down --remove-orphans 2>nul

:: ---------- Start MySQL ----------
echo.
echo [2/3] Starting MySQL (first run pulls image, may take a few minutes)...
docker-compose up --build -d mysql
if errorlevel 1 (
    echo [ERROR] MySQL container failed to start.
    pause
    exit /b 1
)

:: ---------- Wait for MySQL health ----------
echo        Waiting for MySQL to be ready...
:wait_mysql
for /f %%s in ('docker inspect --format={{.State.Health.Status}} useranalyze-mysql 2^>nul') do set STATUS=%%s
if not "!STATUS!"=="healthy" (
    timeout /t 3 /nobreak >nul
    goto wait_mysql
)
echo        MySQL is ready!

:: ---------- Run Spark job (Docker builds JAR inside container) ----------
echo.
echo [3/3] Building image and running Spark job (first run compiles + downloads, may take a few minutes)...
docker-compose up --build spark-app

:: ---------- Show results ----------
echo.
echo [Done] Query results from MySQL:
docker-compose exec mysql mysql -uroot -proot BigDataPlatm -e "SELECT * FROM session_aggr_stat;" 2>nul

echo.
echo ==============================================
echo  MySQL connection info (Navicat / DBeaver):
echo    Host    : localhost:3306
echo    Database: BigDataPlatm
echo    User    : root    Password: root
echo.
echo  Useful commands:
echo    View logs  : docker-compose logs -f spark-app
echo    Stop all   : docker-compose down
echo    Re-run job : docker-compose up spark-app
echo ==============================================
echo.
pause
