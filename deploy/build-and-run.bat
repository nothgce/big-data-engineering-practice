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

:: ---------- Check Maven ----------
echo.
echo [Check] Maven available?
where mvn >nul 2>&1
if errorlevel 1 (
    echo [ERROR] mvn not found. Install Maven and add its bin\ to PATH.
    echo         Download: https://maven.apache.org/download.cgi
    pause
    exit /b 1
)
echo        Maven OK.

:: ---------- Maven build ----------
echo.
echo [1/3] Building JAR (first run downloads dependencies, may take a few minutes)...
cmd /c mvn clean package -DskipTests
if errorlevel 1 (
    echo [ERROR] Maven build failed. Check JAVA_HOME is set correctly.
    pause
    exit /b 1
)
echo        Build OK: target\UserActionAnalyzePlatform-1.0-SNAPSHOT-jar-with-dependencies.jar

:: ---------- Prepare log dir ----------
if not exist logs mkdir logs

:: ---------- Stop old containers ----------
echo.
echo [2/3] Stopping old containers...
docker-compose down --remove-orphans 2>nul

:: ---------- Start MySQL ----------
echo        Starting MySQL (first run pulls image, may take a few minutes)...
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

:: ---------- Run Spark job ----------
echo.
echo        Running Spark user-session analysis job...
docker-compose up --build spark-app

:: ---------- Show results ----------
echo.
echo [3/3] Query results from MySQL:
docker-compose exec mysql mysql -uroot -proot BigDataPlatm -e "SELECT * FROM session_aggr_stat;" 2>nul

:show_info
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
