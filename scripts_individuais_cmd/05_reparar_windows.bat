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
net session >nul 2>&1
if %errorlevel% neq 0 goto SEM_ADMIN
goto TEM_ADMIN
:SEM_ADMIN
cls
echo %RED%========================================================================%RST%
echo %RED%  [ERRO DE ICE] ACESSO NEGADO PELA NETWATCH%RST%
echo %CYN%  [SOLOMON REED // FIA - Cyberpunk 2077]:%RST%
echo %WHT%  "Sem credencial de Administrador voce nao passa nem da recepcao.%RST%
echo %WHT%   Feche, clique com o botao direito e execute como Administrador."%RST%
echo %MAG%  [SONGBIRD]: "Relaxa, choom. So elevar o privilegio que eu abro a porta."%RST%
echo %RED%========================================================================%RST%
echo.
pause
exit /b
:TEM_ADMIN
title CYBERDECK // 05 - Reparo DISM + SFC
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [05] REPARO NEURAL DO WINDOWS (DISM + SFC - ANTI-CIBERPSICOSE)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [WEAK "KING" KINGSLEY // Edgerunners 2]:%RST%
echo %WHT%  "Cuidado com a ciberpsicose no sistema. Vamos estabilizar a imagem do Windows."%RST%
echo.
echo %CYN%[1/2] Executando DISM /RestoreHealth (Pode levar alguns minutos)...%RST%
echo %RED%  [MAINE // Edgerunners 1]: "Aguenta firme, isso demora um pouco mas segura a barra."%RST%
DISM /Online /Cleanup-Image /RestoreHealth
set "ERR_DISM=%errorlevel%"
if "%ERR_DISM%" NEQ "0" (
    echo %RED%  [ERRO NO DISM - Codigo %ERR_DISM%]%RST%
    echo %MAG%  [DOC // Ripperdoc - Edgerunners 1]: "O DISM engasgou. Sem internet ou imagem corrompida demais."%RST%
)

echo.
echo %CYN%[2/2] Executando SFC /scannow...%RST%
echo %WHT%  [GORO TAKEMURA // Cyberpunk 2077]: "Disciplina e precisao. Verificando cada arquivo critico."%RST%
sfc /scannow
set "ERR_SFC=%errorlevel%"
echo.
if "%ERR_SFC%"=="0" goto SFC_OK
echo %YLW%  [AVISO/ERRO NO SFC - Codigo %ERR_SFC%]%RST%
echo %GRN%  [VIKTOR VEKTOR // Cyberpunk 2077]: "Alguns arquivos precisaram de reparo pesado. Reinicie o PC e rode de novo."%RST%
goto SFC_END
:SFC_OK
echo %GRN%  [OK] Integridade neural restaurada.%RST%
echo %GRN%  [DORIO // Edgerunners 1]: "Sistema firme de novo. Sem sinais de falha."%RST%
:SFC_END
echo.
pause
exit /b
