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
title CYBERDECK // 06 - Cache Windows Update
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [06] PURGA DE CACHE DO WINDOWS UPDATE%RST%
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [LUCY // Edgerunners 1]:%RST%
echo %WHT%  "Se o Windows Update travou, o cache antigo virou peso morto. Vamos purgar."%RST%
echo.
echo %CYN%[1/3] Parando servicos do Windows Update...%RST%
echo %MAG%  [SONGBIRD // Cyberpunk 2077]: "Pausando wuauserv, bits e cryptsvc sem deixar rastro."%RST%
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1

echo %CYN%[2/3] Limpando SoftwareDistribution\Download...%RST%
echo %CYN%  [CAPRI // Edgerunners 2]: "Removendo pacotes antigos e corrompidos da fila."%RST%
del /s /f /q "C:\Windows\SoftwareDistribution\Download\*.*" >nul 2>&1
for /d %%p in ("C:\Windows\SoftwareDistribution\Download\*.*") do rmdir "%%p" /s /q >nul 2>&1

echo %CYN%[3/3] Reiniciando servicos...%RST%
net start cryptsvc >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
set "ERR_WU=%errorlevel%"
echo.
if "%ERR_WU%"=="0" goto WU_OK
echo %YLW%  [AVISO] Um dos servicos demorou para subir - normal se ja estava rodando.%RST%
echo %YLW%  [MR. HANDS // Dogtown - Cyberpunk 2077]: "Reinicie o Windows que o servico sobe limpo."%RST%
goto WU_END
:WU_OK
echo %GRN%  [OK] Cache do Windows Update limpo e servicos reativados.%RST%
echo %CYN%  [DELAMAIN // Cyberpunk 2077]: "Servicos operacionais. Boa viagem na rede, senhor."%RST%
:WU_END
echo.
pause
exit /b
