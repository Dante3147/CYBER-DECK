@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title CYBERDECK // 18 - Seguranca de Celulares Android e iPhone

if exist "%~dp0..\scripts_individuais_powershell\18_seguranca_android_iphone.ps1" goto RUN_MOB_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\18_seguranca_android_iphone.ps1
echo Extraia a pasta completa do ZIP mantendo as subpastas juntas.
pause
exit /b

:RUN_MOB_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\18_seguranca_android_iphone.ps1"
taskkill /F /IM adb.exe /T >nul 2>&1
taskkill /F /IM fastboot.exe /T >nul 2>&1
taskkill /F /IM idevice_id.exe /T >nul 2>&1
taskkill /F /IM ideviceinfo.exe /T >nul 2>&1
taskkill /F /IM ideviceinstaller.exe /T >nul 2>&1
taskkill /F /IM idevicepair.exe /T >nul 2>&1
taskkill /F /IM idevicediagnostics.exe /T >nul 2>&1
taskkill /F /IM idevicesyslog.exe /T >nul 2>&1
taskkill /F /IM idevicebackup2.exe /T >nul 2>&1
taskkill /F /IM iproxy.exe /T >nul 2>&1
taskkill /F /IM usbmuxd.exe /T >nul 2>&1
