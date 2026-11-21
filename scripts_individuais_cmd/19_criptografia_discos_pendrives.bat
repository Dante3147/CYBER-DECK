@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CYBERDECK // 19 - Criptografia de Pen Drives e Unidades de Disco

if exist "%~dp0..\scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1" goto RUN_CR_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1
echo Extraia a pasta completa do ZIP mantendo as subpastas juntas.
pause
exit /b

:RUN_CR_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1"
