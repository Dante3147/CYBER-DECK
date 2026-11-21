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
title CYBERDECK // 08 - Otimizar Discos
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [08] OTIMIZACAO INTELIGENTE DE DISCOS (SSD=TRIM / HD=DEFRAG)%RST%
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [DELAMAIN // Cyberpunk 2077]: "Iniciando protocolo TRIM em SSDs e desfragmentacao em HDs."%RST%
echo %YLW%  [FALCO // Edgerunners 1]: "Deixando a pista livre para leitura rapida."%RST%
echo.
defrag /C /O /U /V
set "ERR_DF=%errorlevel%"
echo.
if "%ERR_DF%"=="0" goto DF_OK
echo %RED%  [ERRO - Codigo %ERR_DF%] Falha ao otimizar alguma unidade.%RST%
echo %RED%  [ADAM SMASHER // Arasaka - CP2077 / Edgerunners 1]: "Hardware fraco. Cheque se algum disco esta travado."%RST%
goto DF_END
:DF_OK
echo %GRN%  [OK] Todas as unidades foram otimizadas.%RST%
echo %YLW%  [PANAM PALMER // Aldecaldos - Cyberpunk 2077]: "Discos afinados. Agora sim essa maquina anda."%RST%
:DF_END
echo.
pause
exit /b
