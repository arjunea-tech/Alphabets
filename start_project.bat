@echo off
title ALPHABETS Project Launcher
echo ========================================================
echo        ALPHABETS - Learn 26 Letters Project Launcher
echo ========================================================
echo.

:: 1. Check if MySQL is running
echo [1/3] Checking MySQL status...
net start | findstr /i "MySQL80" >nul
if %errorlevel% neq 0 (
    echo [!] Starting MySQL80 service...
    net start MySQL80
    if %errorlevel% neq 0 (
        echo [WARNING] MySQL80 service could not be started automatically.
        echo Please make sure MySQL Server or XAMPP is running!
    )
) else (
    echo [OK] MySQL80 is already running.
)
echo.

:: 2. Launch Backend
echo [2/3] Launching Backend API (Port 5000)...
start "ALPHABETS - Backend API" cmd /k "cd /d "%~dp0backend" && npm run dev"

:: Wait 3 seconds for backend to initialize
timeout /t 3 /nobreak >nul

:: 3. Launch Admin Panel
echo [3/3] Launching Admin Panel (Port 5173)...
start "ALPHABETS - Admin Panel" cmd /k "cd /d "%~dp0admin-panel" && npm run dev"

echo.
echo ========================================================
echo All Web & API services started!
echo - Backend API:  http://localhost:5000
echo - Admin Panel:  http://localhost:5173
echo.
echo To run the Flutter App (Mobile / Web):
echo Open a terminal and run:
echo   cd frontend
echo   flutter run -d chrome     (for Web View)
echo   flutter run -d windows    (for Windows Desktop)
echo ========================================================
pause
