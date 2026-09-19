@echo off
title MedTrace AI - Backend Server
color 0A
echo.
echo ============================================
echo   MedTrace AI - FastAPI Backend Server
echo ============================================
echo.

cd /d "%~dp0backend"

if not exist ".venv" (
    echo [SETUP] Creating virtual environment...
    python -m venv .venv
)

echo [SETUP] Activating virtual environment...
call ".venv\Scripts\activate.bat"

echo.
echo [START] Backend running at http://localhost:8000
echo [DOCS]  Swagger UI  -- http://localhost:8000/docs
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
pause
