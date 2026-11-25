@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CYBERDECK // 22 - Central de Backup e Recuperacao de Dados (PhotoRec + TestDisk)

if exist "%~dp0..\scripts_individuais_powershell\22_recuperacao_dados_photorec_testdisk.ps1" goto RUN_RECUP_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\22_recuperacao_dados_photorec_testdisk.ps1
echo Extraia a pasta completa do ZIP mantendo as subpastas juntas.
pause
exit /b

:RUN_RECUP_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\22_recuperacao_dados_photorec_testdisk.ps1"
