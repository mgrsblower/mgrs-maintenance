@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo   Menjalankan MGRS-Maintenance di Flutter Web
echo ===================================================
echo.

set "CONFIG_FILE=config\development.local.json"
if not exist "%CONFIG_FILE%" (
    if exist ".env" (
        set "CONFIG_FILE=.env"
    ) else (
        echo [INFO] Menggunakan konfigurasi default Supabase dev di main.dart...
        set "CONFIG_FILE="
    )
)

if defined CONFIG_FILE (
    echo Menggunakan file env: %CONFIG_FILE%
    set "DART_DEFINE=--dart-define-from-file=%CONFIG_FILE%"
) else (
    set "DART_DEFINE="
)

echo Menjalankan Flutter Web pada Chrome (Port 3000)...
echo URL: http://localhost:3000
echo.

flutter run -d chrome --web-port=3000 %DART_DEFINE%

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [INFO] Chrome gagal dibuka langsung, mencoba target web-server...
    flutter run -d web-server --web-port=3000 %DART_DEFINE%
)

pause
