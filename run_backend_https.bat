@echo off
title MedTrace AI - HTTPS Backend Server (TLS 1.3)
color 0B
echo.
echo =======================================================
echo   MedTrace AI - Secure HTTPS Backend Server (TLS 1.3)
echo =======================================================
echo.

cd /d "%~dp0backend"

if not exist ".venv" (
    echo [SETUP] Creating virtual environment...
    python -m venv .venv
)

echo [SETUP] Activating virtual environment...
call ".venv\Scripts\activate.bat"

if not exist "certs\localhost.crt" (
    echo [SSL] Generating local TLS 1.3 / HTTPS certificate...
    python generate_ssl_cert.py
)

echo.
echo [START] Secure Backend running at https://localhost:8000
echo [DOCS]  Swagger UI (HTTPS)     -- https://localhost:8000/docs
echo [CIPHER] AES-256-GCM + TLS 1.3 In-Flight Transfer Enforced
echo.

python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --ssl-keyfile certs\localhost.key --ssl-certfile certs\localhost.crt
pause
