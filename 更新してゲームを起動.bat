@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem OKUDA-STUDIO Windows one-click updater and launcher.
rem This script is intended to be double-clicked from the repository root.

set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"
set "GAME_DIR=projects/nes-block-breaker"
set "ROM_PATH=%REPO_DIR%\projects\nes-block-breaker\build\main.nes"
set "FCEUX_CONFIG=%REPO_DIR%\.fceux_path.txt"
set "PF86=%ProgramFiles(x86)%"

cd /d "%REPO_DIR%" || goto :repo_error

echo ========================================
echo OKUDA-STUDIO NES update and launch
echo ========================================
echo Work directory: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 goto :git_not_found

echo [1/5] Switching to main branch...
git checkout main
if errorlevel 1 goto :checkout_failed

echo.
echo [2/5] Pulling latest changes...
git pull origin main
if errorlevel 1 goto :pull_failed

echo.
echo [3/5] Finding build shell...
call :find_build_bash
if not defined BASH_EXE goto :bash_not_found
echo Build shell: %BASH_EXE%

echo.
echo [4/5] Building ROM...
"%BASH_EXE%" -lc "make -C projects/nes-block-breaker"
if errorlevel 1 goto :build_failed

if not exist "%ROM_PATH%" goto :rom_not_found

echo.
echo [5/5] Finding FCEUX...
call :find_fceux
if not defined FCEUX_EXE goto :fceux_not_found
if not exist "%FCEUX_EXE%" goto :fceux_not_found

echo FCEUX: %FCEUX_EXE%
echo ROM: %ROM_PATH%
echo.
echo Starting game with FCEUX...
start "" "%FCEUX_EXE%" "%ROM_PATH%"
if errorlevel 1 goto :launch_failed

echo.
echo Done. This window can be closed.
goto :success

:find_build_bash
set "BASH_EXE="
call :try_build_bash "C:\msys64\usr\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "C:\msys64\mingw64\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "C:\msys64\ucrt64\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "C:\msys64\clang64\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "C:\msys64\mingw32\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "C:\msys64\clang32\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "%ProgramFiles%\Git\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "%ProgramFiles%\Git\usr\bin\bash.exe"
if defined BASH_EXE exit /b 0
if defined PF86 call :try_build_bash "%PF86%\Git\bin\bash.exe"
if defined BASH_EXE exit /b 0
if defined PF86 call :try_build_bash "%PF86%\Git\usr\bin\bash.exe"
if defined BASH_EXE exit /b 0
call :try_build_bash "%LocalAppData%\Programs\Git\bin\bash.exe"
if defined BASH_EXE exit /b 0
for /f "delims=" %%I in ('where bash.exe 2^>nul') do if not defined BASH_EXE call :try_build_bash "%%I"
exit /b 0

:try_build_bash
if not exist "%~1" exit /b 0
"%~1" -lc "command -v make >/dev/null 2>&1"
if errorlevel 1 exit /b 0
set "BASH_EXE=%~1"
exit /b 0

:find_fceux
set "FCEUX_EXE="
if exist "%FCEUX_CONFIG%" (
    set /p FCEUX_EXE=<"%FCEUX_CONFIG%"
    if defined FCEUX_EXE if not exist "%FCEUX_EXE%" set "FCEUX_EXE="
)
if not defined FCEUX_EXE if exist "%ProgramFiles%\FCEUX\fceux.exe" set "FCEUX_EXE=%ProgramFiles%\FCEUX\fceux.exe"
if not defined FCEUX_EXE if defined PF86 if exist "%PF86%\FCEUX\fceux.exe" set "FCEUX_EXE=%PF86%\FCEUX\fceux.exe"
if not defined FCEUX_EXE if exist "%LocalAppData%\Programs\FCEUX\fceux.exe" set "FCEUX_EXE=%LocalAppData%\Programs\FCEUX\fceux.exe"
if not defined FCEUX_EXE for /f "delims=" %%I in ('where fceux.exe 2^>nul') do if not defined FCEUX_EXE set "FCEUX_EXE=%%I"
if defined FCEUX_EXE (
    >"%FCEUX_CONFIG%" echo %FCEUX_EXE%
    exit /b 0
)
call :select_fceux
exit /b 0

:select_fceux
echo FCEUX was not found automatically.
echo Select fceux.exe in the file picker.
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select fceux.exe'; $d.Filter = 'FCEUX executable (fceux.exe)^|fceux.exe^|Executable files (*.exe)^|*.exe^|All files (*.*)^|*.*'; if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $d.FileName }"`) do set "FCEUX_EXE=%%I"
if defined FCEUX_EXE if exist "%FCEUX_EXE%" >"%FCEUX_CONFIG%" echo %FCEUX_EXE%
exit /b 0

:repo_error
echo Error: Could not use the batch file folder as the work directory.
goto :failure

:git_not_found
echo Error: git was not found. Install Git for Windows.
goto :failure

:checkout_failed
echo Error: Could not switch to main. Check for uncommitted changes or conflicts.
goto :failure

:pull_failed
echo Error: git pull origin main failed. Check the network and GitHub authentication.
goto :failure

:bash_not_found
echo Error: No usable bash with make was found.
echo Fix: Install MSYS2 with make, or install make for Git Bash.
echo.
pause
goto :failure

:build_failed
echo Error: ROM build failed. Check the make output above.
goto :failure

:rom_not_found
echo Error: Built ROM was not found: %ROM_PATH%
goto :failure

:fceux_not_found
echo Error: FCEUX was not found or was not selected.
echo Fix: Install FCEUX or save the full fceux.exe path in .fceux_path.txt.
goto :failure

:launch_failed
echo Error: Could not start FCEUX.
goto :failure

:failure
echo.
echo Stopped. Check the message above and run this file again.
exit /b 1

:success
echo.
exit /b 0
