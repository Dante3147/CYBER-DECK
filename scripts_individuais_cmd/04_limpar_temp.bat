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
title CYBERDECK // 04 - Limpeza Temp
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [04] LIMPEZA DE RASTROS DA REDE (ARQUIVOS TEMPORARIOS)%RST%
echo %COR_PRI%========================================================================%RST%
echo %GRN%  [D // SNAKE NATION - Edgerunners 2]:%RST%
echo %WHT%  "Limpando os rastros antes que a MaxTac bata na porta."%RST%
echo.
echo %CYN%[1/2] Limpando Temp do Usuario (%TEMP%)...%RST%
echo %MAG%  [KIWI // Edgerunners 1]: "Varrendo os arquivos temporarios do seu perfil."%RST%
del /s /f /q "%TEMP%\*.*" >nul 2>&1
for /d %%p in ("%TEMP%\*.*") do rmdir "%%p" /s /q >nul 2>&1

echo %CYN%[2/2] Limpando Temp do Sistema (C:\Windows\Temp)...%RST%
echo %YLW%  [WAKAKO OKADA // Fixer - Cyberpunk 2077]: "Deixe a pasta do sistema limpa e discreta."%RST%
del /s /f /q "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%p in ("C:\Windows\Temp\*.*") do rmdir "%%p" /s /q >nul 2>&1

echo.
if exist "%TEMP%" goto TEMP_OK
echo %RED%  [ERRO] Diretorio Temp inacessivel.%RST%
echo %RED%  [FARADAY // Edgerunners 1]: "Inaceitavel. Verifique as permissoes da pasta Temp."%RST%
goto TEMP_END
:TEMP_OK
echo %GRN%  [OK] Limpeza concluida. Arquivos em uso pelo Windows foram pulados com seguranca.%RST%
echo %YLW%  [JACKIE WELLES // Cyberpunk 2077]: "Limpinho, mano. Pronto para o proximo servico."%RST%
:TEMP_END
echo.
pause
exit /b
