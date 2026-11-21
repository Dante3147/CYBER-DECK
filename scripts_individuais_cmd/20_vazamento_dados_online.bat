@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CYBERDECK // 20 - Seguranca Online e Vazamento de Dados

if exist "%~dp0..\scripts_individuais_powershell\20_vazamento_dados_online.ps1" goto RUN_LK_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\20_vazamento_dados_online.ps1
echo Extraia a pasta completa do ZIP mantendo as subpastas juntas.
pause
exit /b

:RUN_LK_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\20_vazamento_dados_online.ps1"
