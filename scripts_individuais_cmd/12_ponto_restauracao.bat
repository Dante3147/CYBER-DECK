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
title CYBERDECK // 12 - Ponto de Restauracao
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [12] CRIANDO PONTO DE RESTAURACAO (BACKUP DE ENGRAMA / MIKOSHI)%RST%
echo %COR_PRI%========================================================================%RST%
echo %RED%  [ALT CUNNINGHAM // Cyberpunk 2077]: "Gravando um ponto seguro do estado atual do sistema."%RST%
echo %WHT%  [HANAKO ARASAKA // Cyberpunk 2077]: "Seu engrama ficara preservado no Mikoshi local."%RST%
echo.
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue; Checkpoint-Computer -Description 'CyberDeck_Backup_2077' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; exit 0 } catch { Write-Host $_.Exception.Message -ForegroundColor Yellow; exit 1 }"
if %errorlevel%==0 goto RES_OK
echo %YLW%  [AVISO/ERRO] Nao foi possivel criar novo ponto agora - Windows limita 1 a cada 24h.%RST%
echo %RED%  [JOHNNY SILVERHAND // Cyberpunk 2077]: "A Arasaka travou o Mikoshi por 24 horas. Normal se voce ja criou um hoje."%RST%
echo %MAG%  [YORINOBU ARASAKA // Cyberpunk 2077]: "Ou ative a Protecao do Sistema nas Propriedades do Sistema."%RST%
goto RES_END
:RES_OK
echo %GRN%  [OK] Ponto de restauracao criado com sucesso.%RST%
echo %RED%  [SABURO ARASAKA // Cyberpunk 2077]: "Ordem preservada. O backup esta seguro."%RST%
:RES_END
echo.
pause
exit /b
