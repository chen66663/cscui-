@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Usage: package.bat [Release^|Debug^|RelWithDebInfo^|MinSizeRel]
rem Set CSCUI_PAUSE=1 when launching manually and a final prompt is desired.
set "PROJECT_NAME={{PROJECT_NAME}}"
set "BUILD_CONFIG=%~1"
if not defined BUILD_CONFIG set "BUILD_CONFIG=Release"

if /I "%BUILD_CONFIG%"=="Release" goto :config_valid
if /I "%BUILD_CONFIG%"=="Debug" goto :config_valid
if /I "%BUILD_CONFIG%"=="RelWithDebInfo" goto :config_valid
if /I "%BUILD_CONFIG%"=="MinSizeRel" goto :config_valid
echo [ERROR] Unsupported build configuration: "%BUILD_CONFIG%"
exit /b 2

:config_valid
set "BUILD_DIR=%~dp0build"
set "OUTPUT_DIR=%~dp0output"
set "QML_SOURCE_DIR=%~dp0"
set "EXE_NAME=%PROJECT_NAME%.exe"
set "EXE_PATH=%BUILD_DIR%\%BUILD_CONFIG%\%EXE_NAME%"

rem Support both multi-config and single-config CMake generators.
if not exist "%EXE_PATH%" if exist "%BUILD_DIR%\%EXE_NAME%" set "EXE_PATH=%BUILD_DIR%\%EXE_NAME%"
if not exist "%EXE_PATH%" for /D %%D in ("%BUILD_DIR%\*-%BUILD_CONFIG%") do if exist "%%~fD\%EXE_NAME%" set "EXE_PATH=%%~fD\%EXE_NAME%"

echo --- cscui Packaging Script ---
echo [INFO] Project:       %PROJECT_NAME%
echo [INFO] Configuration: %BUILD_CONFIG%
echo [INFO] Executable:    %EXE_PATH%

where windeployqt >nul 2>&1
if errorlevel 1 (
    echo [ERROR] windeployqt was not found on PATH.
    echo [HINT] Add the selected Qt kit's bin directory to PATH.
    exit /b 3
)

if not exist "%EXE_PATH%" (
    echo [ERROR] Executable not found: "%EXE_PATH%"
    echo [HINT] Run: cmake --build build --config %BUILD_CONFIG%
    exit /b 4
)

if not exist "%OUTPUT_DIR%" (
    mkdir "%OUTPUT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Could not create output directory: "%OUTPUT_DIR%"
        exit /b 5
    )
)

copy /Y "%EXE_PATH%" "%OUTPUT_DIR%\%EXE_NAME%" >nul
if errorlevel 1 (
    echo [ERROR] Could not copy the application executable.
    exit /b 6
)

set "DEPLOY_MODE=--release"
if /I "%BUILD_CONFIG%"=="Debug" set "DEPLOY_MODE=--debug"

pushd "%OUTPUT_DIR%"
if errorlevel 1 (
    echo [ERROR] Could not enter output directory: "%OUTPUT_DIR%"
    exit /b 7
)
windeployqt %DEPLOY_MODE% --qmldir "%QML_SOURCE_DIR%" "%EXE_NAME%"
set "DEPLOY_EXIT=%ERRORLEVEL%"
popd
if not "%DEPLOY_EXIT%"=="0" (
    echo [ERROR] windeployqt failed with exit code %DEPLOY_EXIT%.
    exit /b %DEPLOY_EXIT%
)

echo [SUCCESS] Package created at "%OUTPUT_DIR%".
if /I "%CSCUI_PAUSE%"=="1" pause
exit /b 0
