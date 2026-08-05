@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul

rem OKUDA-STUDIO Windows one-click updater / launcher.
rem This script is intended to be double-clicked from the repository root.

set "REPO_DIR=%~dp0"
set "REPO_DIR=%REPO_DIR:~0,-1%"
set "GAME_DIR=projects/nes-block-breaker"
set "ROM_PATH=%REPO_DIR%\projects\nes-block-breaker\build\main.nes"
set "FCEUX_CONFIG=%REPO_DIR%\.fceux_path.txt"
set "PF86=%ProgramFiles(x86)%"

cd /d "%REPO_DIR%" || goto :repo_error

echo ========================================
echo OKUDA-STUDIO NESゲーム 更新・起動
echo ========================================
echo 作業フォルダ: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 goto :git_not_found

echo [1/5] mainブランチへ切り替えています...
git checkout main
if errorlevel 1 goto :checkout_failed

echo.
echo [2/5] 最新版を取得しています...
git pull origin main
if errorlevel 1 goto :pull_failed

echo.
echo [3/5] Git Bashを探しています...
call :find_git_bash
if not defined BASH_EXE goto :bash_not_found
echo Git Bash: %BASH_EXE%

echo.
echo [4/5] ROMをビルドしています...
"%BASH_EXE%" -lc "make -C projects/nes-block-breaker"
if errorlevel 1 goto :build_failed

if not exist "%ROM_PATH%" goto :rom_not_found

echo.
echo [5/5] FCEUXを探しています...
call :find_fceux
if not defined FCEUX_EXE goto :fceux_not_found
if not exist "%FCEUX_EXE%" goto :fceux_not_found

echo FCEUX: %FCEUX_EXE%
echo ROM: %ROM_PATH%
echo.
echo FCEUXでゲームを起動します...
start "" "%FCEUX_EXE%" "%ROM_PATH%"
if errorlevel 1 goto :launch_failed

echo.
echo 完了しました。このウィンドウは閉じてかまいません。
goto :success

:find_git_bash
set "BASH_EXE="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%ProgramFiles%\Git\usr\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\usr\bin\bash.exe"
if not defined BASH_EXE if defined PF86 if exist "%PF86%\Git\bin\bash.exe" set "BASH_EXE=%PF86%\Git\bin\bash.exe"
if not defined BASH_EXE if defined PF86 if exist "%PF86%\Git\usr\bin\bash.exe" set "BASH_EXE=%PF86%\Git\usr\bin\bash.exe"
if not defined BASH_EXE if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LocalAppData%\Programs\Git\bin\bash.exe"
if not defined BASH_EXE for /f "delims=" %%I in ('where bash.exe 2^>nul') do if not defined BASH_EXE set "BASH_EXE=%%I"
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
echo FCEUXが自動検出できませんでした。
echo ファイル選択画面で fceux.exe を選んでください。
for /f "usebackq delims=" %%I in (`powershell -NoProfile -STA -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'fceux.exe を選択してください'; $d.Filter = 'FCEUX executable (fceux.exe)^|fceux.exe^|Executable files (*.exe)^|*.exe^|All files (*.*)^|*.*'; if ($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $d.FileName }"`) do set "FCEUX_EXE=%%I"
if defined FCEUX_EXE if exist "%FCEUX_EXE%" >"%FCEUX_CONFIG%" echo %FCEUX_EXE%
exit /b 0

:repo_error
echo エラー: バッチファイルが置かれているフォルダを作業場所にできませんでした。
goto :failure

:git_not_found
echo エラー: git コマンドが見つかりません。Git for Windowsをインストールしてください。
goto :failure

:checkout_failed
echo エラー: mainブランチへの切り替えに失敗しました。未保存の変更や競合がないか確認してください。
goto :failure

:pull_failed
echo エラー: git pull origin main に失敗しました。ネットワーク接続やGitHubの認証状態を確認してください。
goto :failure

:bash_not_found
echo エラー: Git Bashが見つかりません。Git for Windowsを標準設定でインストールしてください。
goto :failure

:build_failed
echo エラー: ROMのビルドに失敗しました。上に表示されたmakeのエラー内容を確認してください。
goto :failure

:rom_not_found
echo エラー: ビルド後のROMが見つかりません: %ROM_PATH%
goto :failure

:fceux_not_found
echo エラー: FCEUXが見つからないか、選択されませんでした。
echo 対処: FCEUXをインストールしてから再実行するか、.fceux_path.txt に fceux.exe のフルパスを保存してください。
goto :failure

:launch_failed
echo エラー: FCEUXの起動に失敗しました。
goto :failure

:failure
echo.
echo 処理を中断しました。内容を確認してから、もう一度実行してください。
pause
exit /b 1

:success
echo.
pause
exit /b 0
