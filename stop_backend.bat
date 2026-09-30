@echo off
echo Stopping HealthShield AI Backend on port 8000...

set found=0
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000 ^| findstr LISTENING') do (
    echo Killing process %%a bound to port 8000...
    taskkill /F /PID %%a > nul 2>&1
    set found=1
)

if %found% equ 1 (
    echo HealthShield AI Backend stopped successfully.
) else (
    echo No active HealthShield AI Backend process found on port 8000.
)
