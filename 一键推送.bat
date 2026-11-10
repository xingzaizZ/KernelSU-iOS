@echo off
chcp 65001 >nul
setlocal

echo ============================================
echo   KernelSU iOS 外壳 - 一键上传到 GitHub
echo ============================================
echo.

if "%~1"=="" (
    echo 用法: 一键推送.bat ghp_你的GitHub令牌
    echo.
    echo 令牌获取: GitHub - Settings - Developer settings -
    echo           Personal access tokens - Tokens ^(classic^)
    echo           勾选 repo 权限即可
    echo.
    pause
    exit /b 1
)

set TOKEN=%~1

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\push_to_github.ps1" -Token "%TOKEN%"

echo.
echo ============================================
echo   上传结束，按任意键关闭
echo ============================================
pause
