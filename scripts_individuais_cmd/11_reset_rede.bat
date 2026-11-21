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
title CYBERDECK // 11 - Reset Rede e DNS
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [11] RESET COMPLETO DE REDE E DNS (FUGIR DA NETWATCH)%RST%
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [CAPRI // Edgerunners 2]: "Quebrando rastreamento e limpando a tabela DNS."%RST%
echo %GRN%  [D // Edgerunners 2]: "Trocando de rota antes que o sinal seja interceptado."%RST%
echo.
echo %WHT%  [SOLOMON REED // FIA - CP2077]: "Executando flushdns, renew, ip reset e winsock."%RST%
ipconfig /release >nul 2>&1
ipconfig /flushdns
ipconfig /renew >nul 2>&1
netsh int ip reset
netsh winsock reset
set "ERR_NET=%errorlevel%"
echo.
if "%ERR_NET%"=="0" goto NET_OK
echo %RED%  [ERRO - Codigo %ERR_NET%] Algum comando de rede retornou falha.%RST%
echo %MAG%  [KIWI // Edgerunners 1]: "Verifique se o cabo de rede ou Wi-Fi esta ativo e tente novamente."%RST%
goto NET_END
:NET_OK
echo %GRN%  [OK] Pilha de rede e DNS resetados. Reinicie o PC para aplicar 100%%.%RST%
echo %YLW%  [ROGUE AMENDIARES // Afterlife - CP2077]: "Conexao limpa. Bom trabalho."%RST%
:NET_END
echo.
pause
exit /b
