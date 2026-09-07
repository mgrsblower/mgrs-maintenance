@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo   Menjalankan MGRS-Maintenance di Flutter Web
echo ===================================================
echo.

if not exist "config\development.local.json" (
    echo [PERINGATAN] File config\development.local.json tidak ditemukan!
    echo Pastikan konfigurasi SUPABASE_URL dan SUPABASE_PUBLISHABLE_KEY sudah ada.
    echo.
    pause
    exit /b 1
)

echo Menjalankan Flutter Web pada Chrome (Port 3000)...
echo URL: http://localhost:3000
echo.

flutter run -d chrome --web-port=3000 --dart-define-from-file=config/development.local.json

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Mencoba menjalankan dengan target web default (Edge/Chrome)...
    flutter run -d web-server --web-port=3000 --dart-define-from-file=config/development.local.json
)

pause
