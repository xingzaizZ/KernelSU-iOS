@echo off
chcp 65001 >nul
setlocal

echo ============================================================
echo   KernelSU iOS - upload to GitHub and build unsigned ipa
echo ============================================================
echo.

if "%~1"=="" goto :usage

set "TOKEN=%~1"
set "HERE=%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%tools\push_and_build.ps1" -Token "%TOKEN%"
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
    echo ============================================================
    echo   BUILD OK - ipa is in the dist folder
    echo ============================================================
) else (
    echo ============================================================
    echo   FAILED with exit code %RC%
    echo ============================================================
)
pause
exit /b %RC%

:usage
echo Usage: 一键上传并打包.bat YOUR_GITHUB_TOKEN
echo.
echo Get a token at:
echo   https://github.com/settings/tokens/new
echo.
echo   Note       : KernelSU iOS build
echo   Expiration : 7 days is enough
echo.
echo   Classic token  - tick the "repo" scope. That is all.
echo   Fine-grained   - Repository access: All repositories
echo                    Contents : Read and write
echo                    Actions  : Read and write
echo                    Workflows: Read and write  (if the option appears)
echo.
echo Then run:
echo   一键上传并打包.bat ghp_xxxxxxxxxxxxxxxxxxxx
echo.
pause
exit /b 1
