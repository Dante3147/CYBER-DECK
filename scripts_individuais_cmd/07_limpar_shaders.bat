@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Obtem o caractere ESC e ativa o suporte a cores ANSI no terminal do Windows
for /f "delims=" %%a in ('powershell -NoProfile -Command "[char]27"') do set "ESC=%%a"
set "RST=%ESC%[0m"
set "RED=%ESC%[91m"
set "GRN=%ESC%[92m"
set "YLW=%ESC%[93m"
set "BLU=%ESC%[94m"
set "MAG=%ESC%[95m"
set "CYN=%ESC%[96m"
set "WHT=%ESC%[97m"
set "GRY=%ESC%[90m"
set "COR_PRI=%YLW%"
title CYBERDECK // 07 - Cache Shaders
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [07] LIMPEZA DE CACHE DE SHADERS (DIRECTX / NVIDIA / AMD)%RST%
echo %COR_PRI%========================================================================%RST%
echo %RED%  [TALIA // MAELSTROM - Edgerunners 2]:%RST%
echo %WHT%  "Shaders corrompidos causam travadas feias. Vamos zerar esse cache."%RST%
echo.
echo %CYN%  [JUDY ALVAREZ // Cyberpunk 2077]: "Limpando DirectX, NVIDIA e AMD. Os jogos recriam limpo depois."%RST%
del /s /f /q "%LOCALAPPDATA%\D3DSCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA\DXCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA\GLCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\AMD\DxCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\AMD\GLCache\*.*" >nul 2>&1
echo.
echo %GRN%  [OK] Caches de shaders limpos.%RST%
echo %YLW%  [DAVID MARTINEZ // Edgerunners 1]: "Na proxima vez que abrir o jogo, ele compila tudo zerado."%RST%
echo %GRY%  [SKIPPY // Arma Inteligente - CP2077]: "Bum-bum-bi-dam. Se algum arquivo estava aberto, foi mantido."%RST%
echo.
pause
exit /b
