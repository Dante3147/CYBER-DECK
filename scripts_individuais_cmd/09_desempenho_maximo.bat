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
title CYBERDECK // 09 - Modo Sandevistan
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [09] MODO SANDEVISTAN (PLANO DE ENERGIA: DESEMPENHO MAXIMO)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [DAVID MARTINEZ // Edgerunners 1]:%RST%
echo %WHT%  "Eu sou construido diferente. Ativando o plano de Desempenho Maximo."%RST%
echo.
powershell -NoProfile -Command "$out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-String; if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { $guid = $matches[1]; powercfg /setactive $guid; Write-Host ('[SANDEVISTAN ATIVO] Desempenho Maximo ativado. GUID: ' + $guid) -ForegroundColor Green; exit 0 } else { Write-Host '[AVISO] Plano oculto bloqueado nesta edicao. Ativando Alto Desempenho...' -ForegroundColor Yellow; powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; exit 1 }"
if %errorlevel%==0 goto SAND_OK
echo %MAG%  [DOC // Edgerunners 1]: "Seu Windows bloqueou o Desempenho Maximo, mas ja puxei o Alto Desempenho."%RST%
echo %YLW%  [WEAK "KING" KINGSLEY // Edgerunners 2]: "Mesmo assim voce ja ganhou resposta rapida."%RST%
goto SAND_END
:SAND_OK
echo %RED%  [MAINE // Edgerunners 1]: "Aceleracao total ligada. So fica de olho na temperatura."%RST%
echo %RED%  [ADAM SMASHER // CP2077]: "Um implante rudimentar... mas eficiente."%RST%
:SAND_END
echo.
echo %CYN%Plano de energia ativo atualmente:%RST%
powercfg /getactivescheme
echo.
pause
exit /b
