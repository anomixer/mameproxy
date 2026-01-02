@echo off
setlocal enabledelayedexpansion

echo ==========================================
echo MameCloudRompath (MCR) Configuration Utility
echo ==========================================

:: 1. Check for WinFsp
set "WINFSP_DLL=C:\Program Files (x86)\WinFsp\bin\winfsp-x64.dll"
if not exist "%WINFSP_DLL%" (
    echo [ERROR] WinFsp not found! 
    echo Please install WinFsp from https://winfsp.dev/
    pause
    exit /b 1
)
echo [OK] WinFsp is installed.

:: 2. Load existing settings or set defaults
set "MAME_CACHE=C:\mamecache"
set "DRIVE_LETTER=Z:"
set "MAME_DIR=C:\mame"

if exist mcr.ini (
    for /f "tokens=1,2 delims==" %%a in (mcr.ini) do (
        if "%%a"=="CACHE_DIR" set "MAME_CACHE=%%b"
        if "%%a"=="MOUNT_POINT" set "DRIVE_LETTER=%%b"
        if "%%a"=="MAME_DIR" set "MAME_DIR=%%b"
    )
    echo [INFO] Loaded existing settings from mcr.ini
)

set /p "MAME_CACHE=Enter MameCache directory (Default: !MAME_CACHE!): "

set /p "DRIVE_LETTER=Enter virtual drive letter (Default: !DRIVE_LETTER!): "

set /p "MAME_DIR=Enter your MAME directory (Default: !MAME_DIR!): "

:: Validate Drive Letter format (Ensuring it ends with :)
if not "!DRIVE_LETTER:~-1!"==":" set "DRIVE_LETTER=!DRIVE_LETTER!:"

:: 3. Write to mcr.ini
echo MOUNT_POINT=!DRIVE_LETTER!> mcr.ini
echo CACHE_DIR=!MAME_CACHE!>> mcr.ini
echo MAME_DIR=!MAME_DIR!>> mcr.ini
echo BASE_URL=https://mdk.cab/download/>> mcr.ini

echo [OK] Settings saved to mcr.ini

:: 4. Check for mcr.exe
if not exist "build\Release\mcr.exe" (
    echo [INFO] mcr.exe not found. Calling build.bat...
    call build.bat
    if errorlevel 1 (
        echo [ERROR] Build failed. Please check the errors above.
        pause
        exit /b 1
    )
)

:: 5. Create mcr.bat
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo for /f "tokens=1,2 delims==" %%%%a in (mcr.ini^) do (
    echo     set %%%%a=%%%%b
    echo ^)
    echo echo Starting MameCloudRompath ^(MCR^) v0.1 with:
    echo echo Mount Point: %%MOUNT_POINT%%
    echo echo Cache Dir: %%CACHE_DIR%%
    echo echo MAME Dir: %%MAME_DIR%%
    echo echo URL: %%BASE_URL%%
    echo echo.
    echo echo [IMPORTANT] Keep this window OPEN while playing.
    echo echo [AUTOMATION] Launching MAME in a new window...
    echo echo.
    echo start "MAME-MCR" cmd /c "echo Waiting for MCR to mount %%MOUNT_POINT%%... && timeout /t 3 >nul && cd /d "%%MAME_DIR%%" && mame.exe -rompath %%MOUNT_POINT%%"
    echo "%%~dp0build\Release\mcr.exe" -m %%MOUNT_POINT%% -c "%%CACHE_DIR%%" -u %%BASE_URL%%
) > mcr.bat

echo ==========================================
echo [SUCCESS] Configuration complete!
echo You can now run the proxy using: mcr.bat
echo ==========================================
pause
