@echo off
title MedTrace AI - Flutter Web Frontend
color 0B
echo.
echo ========================================================
echo   MedTrace AI - Web App (http://localhost:8080)
echo ========================================================
echo.

cd /d "%~dp0"

:: Check for Chrome
set "CHROME_BIN="
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    set "CHROME_BIN=C:\Program Files\Google\Chrome\Application\chrome.exe"
) else if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    set "CHROME_BIN=C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
) else if exist "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe" (
    set "CHROME_BIN=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
)

echo [START] Launching Chrome to http://localhost:8080...
if defined CHROME_BIN (
    start "" "%CHROME_BIN%" "http://localhost:8080"
) else (
    start "" "http://localhost:8080"
)

echo [SERVER] Serving Flutter Web App on port 8080...
echo (Keep this window open while using the app)
echo.

python -m http.server 8080 --directory "frontend\MedTraceAI\build\web"
pause
