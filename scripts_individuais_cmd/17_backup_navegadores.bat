@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CYBERDECK // 17 - Backup de Navegadores (Favoritos, Senhas e Perfis)

if exist "%~dp0..\scripts_individuais_powershell\17_backup_navegadores.ps1" goto RUN_NAV_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\17_backup_navegadores.ps1
echo Extraia a pasta completa do ZIP mantendo as subpastas juntas.
pause
exit /b

:RUN_NAV_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\17_backup_navegadores.ps1"
