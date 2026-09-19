@echo off
title Push MedTrace AI to GitHub
color 0B
echo.
echo ========================================================
echo   Pushing MedTrace AI to GitHub (main branch)
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Checking git status...
git status
echo.

echo [2/2] Pushing to https://github.com/kysanthosh-it/medtrace-ai.git ...
echo (If a GitHub sign-in window appears in your browser, please approve it)
echo.
git push -u origin main

echo.
echo ========================================================
echo   Git Push Finished!
echo ========================================================
pause
