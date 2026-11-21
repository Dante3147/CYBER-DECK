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
title CYBERDECK // 01 - Winget Upgrade All
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [01] ATUALIZACAO DE IMPLANTES DE SOFTWARE (WINGET UPGRADE ALL)%RST%
echo %COR_PRI%========================================================================%RST%
echo %GRN%  [VIKTOR VEKTOR // Cyberpunk 2077]:%RST%
echo %WHT%  "Se vai rodar cromo no limite, garanta que todo firmware esteja em dia."%RST%
echo %YLW%  [FALCO // Edgerunners 1]:%RST%
echo %WHT%  "Puxando todas as atualizacoes direto pelo Winget. Segura firme."%RST%
echo.
winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
set "ERR_OP=%errorlevel%"
echo.
if "%ERR_OP%"=="0" goto OP1_OK
echo %YLW%  [AVISO/ERRO - Codigo %ERR_OP%] Alguns pacotes nao puderam ser atualizados ou ja estao atualizados.%RST%
echo %MAG%  [PILAR // Edgerunners 1]: "Eita, algum programa travou ou ja estava na ultima versao."%RST%
echo %GRN%  [D // Edgerunners 2]: "Se algum app ficou aberto, fecha ele e tenta de novo depois."%RST%
goto OP1_END
:OP1_OK
echo %GRN%  [OK] Todos os pacotes verificados e atualizados.%RST%
echo %CYN%  [V // Cyberpunk 2077]: "Tudo liso, Vik. Nenhum implante desatualizado."%RST%
:OP1_END
echo.
pause
exit /b
