@echo off
title Package MedTrace AI for Netlify
color 0A
echo.
echo ========================================================
echo   Packaging MedTrace AI for Netlify Deployment
echo ========================================================
echo.

cd /d "%~dp0"

echo [1/2] Compiling production web build...
cd frontend\MedTraceAI
call flutter build web --release --base-href /
cd ..\..

echo.
echo [2/2] Creating Netlify Drop ZIP...
python -c "import os, zipfile; d=r'frontend/MedTraceAI/build/web'; z=r'MedTraceAI_Netlify_Drop.zip'; zf=zipfile.ZipFile(z, 'w', zipfile.ZIP_DEFLATED); [zf.write(os.path.join(r,f), os.path.relpath(os.path.join(r,f), d)) for r,_,fs in os.walk(d) for f in fs]; print('Created:', z, 'Size:', round(os.path.getsize(z)/(1024*1024), 2), 'MB')"

echo.
echo ========================================================
echo   SUCCESS! Package ready: MedTraceAI_Netlify_Drop.zip
echo ========================================================
echo.
echo Instructions:
echo   1. Go to https://app.netlify.com/drop
echo   2. Drag & drop "MedTraceAI_Netlify_Drop.zip"
echo   3. Your app will go live instantly with zero errors!
echo.
pause
