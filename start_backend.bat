@echo off
setlocal enabledelayedexpansion

echo Checking if HealthShield AI Backend is already running on port 8000...

:: Check if port 8000 is open
netstat -ano | findstr :8000 | findstr LISTENING > nul
if errorlevel 1 goto start_server

echo Port 8000 is active. Performing health check...
curl -s --fail http://127.0.0.1:8000/ > nul
if errorlevel 1 (
    echo Port 8000 is occupied but health check failed. Re-launching...
    goto start_server
)

echo.
echo ==========================================
echo   HealthShield AI Backend
echo   Development Server
echo ==========================================
echo.
echo Backend status: RUNNING
echo Health check:   PASS
echo Host:           0.0.0.0 (LAN IP: 192.168.1.4)
echo Port:           8000
echo.
echo Ready for Android device testing.
exit /b 0

:start_server
echo Starting uvicorn backend server...
start /b py -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload > backend_server.log 2>&1

echo Waiting for FastAPI to become reachable...
set max_retries=15
set count=0

:loop
ping 127.0.0.1 -n 2 > nul
set /a count+=1
curl -s --fail http://127.0.0.1:8000/ > nul
if not errorlevel 1 (
    echo.
    echo ==========================================
    echo   HealthShield AI Backend
    echo   Development Server
    echo ==========================================
    echo.
    echo Backend status: RUNNING
    echo Health check:   PASS
    echo Host:           0.0.0.0 (LAN IP: 192.168.1.4)
    echo Port:           8000
    echo.
    echo Ready for Android device testing.
    exit /b 0
)

if !count! lss !max_retries! (
    echo Retry !count!/!max_retries!...
    goto loop
)

echo.
echo Backend status: FAILED
echo.
echo Possible causes:
echo - Python environment unavailable
echo - Required dependency missing
echo - Port already occupied
echo - Backend startup error (Check backend_server.log)
echo - LAN/network configuration issue
exit /b 1
