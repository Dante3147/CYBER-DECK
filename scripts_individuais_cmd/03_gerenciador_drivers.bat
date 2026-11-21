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
title CYBERDECK // 03 - Gerenciador de Dispositivos
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [03] GERENCIADOR DE DISPOSITIVOS: VERIFICAR, CORRIGIR E ATUALIZAR DRIVERS%RST%
echo %COR_PRI%========================================================================%RST%
echo %GRN%  [VIKTOR VEKTOR // Ripperdoc - Cyberpunk 2077]:%RST%
echo %WHT%  "Vamos escanear todos os seus implantes e drivers no Gerenciador de Dispositivos."%RST%
echo %YLW%  [WEAK "KING" KINGSLEY // Edgerunners 2]:%RST%
echo %WHT%  "Procurando qualquer dispositivo com triangulo amarelo ou driver faltando..."%RST%
echo.

echo %CYN%[1/3] Dispositivos com Erro, Aviso Amarelo ou Driver Faltando:%RST%
powershell -NoProfile -Command "$bad = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }; if ($bad) { Write-Host '[ALERTA] Dispositivos com problema detectados:' -ForegroundColor Red; $bad | Select-Object Name, PNPClass, ConfigManagerErrorCode, DeviceID | Format-Table -Wrap -AutoSize; Write-Host '  [JUDY ALVAREZ // CP2077]: Achei dispositivos com erro/driver faltando ai em cima.' -ForegroundColor Cyan } else { Write-Host '[OK] Nenhum dispositivo com erro ou triangulo amarelo detectado.' -ForegroundColor Green; Write-Host '  [V // CP2077]: Todos os drivers do Gerenciador de Dispositivos estao OK.' -ForegroundColor Cyan }"

:DRV_MENU
echo.
echo %COR_PRI%========================================================================%RST%
echo %WHT%  ACOES PARA DRIVERS E GERENCIADOR DE DISPOSITIVOS:%RST%
echo   %CYN%[1]%RST% Re-escanear Hardware (pnputil /scan-devices) - %GRY%Detecta e tenta instalar drivers%RST%
echo   %YLW%[2]%RST% Tentar Corrigir / Reiniciar Dispositivos com Erro - %GRY%Reinicia dispositivos com aviso%RST%
echo   %GRN%[3]%RST% Buscar Atualizacoes de Drivers via Windows Update - %GRY%Abre Updates Opcionais + Scan%RST%
echo   %MAG%[4]%RST% Abrir Gerenciador de Dispositivos (devmgmt.msc) - %GRY%Mantem o painel aberto%RST%
echo   %GRY%[0]%RST% Voltar ao menu%RST%
echo %COR_PRI%========================================================================%RST%
set "drvopc="
set /p "drvopc=%WHT%Escolha uma acao [0-4]: %RST%"

if "%drvopc%"=="1" goto DRV_SCAN
if "%drvopc%"=="2" goto DRV_FIX
if "%drvopc%"=="3" goto DRV_WU
if "%drvopc%"=="4" goto DRV_OPEN
if "%drvopc%"=="0" goto DRV_FIM
echo %RED%  [SKIPPY]: "Opcao invalida. Escolha de 0 a 4."%RST%
goto DRV_MENU

:DRV_SCAN
echo.
echo %CYN%[RE-ESCANEANDO HARDWARE E DRIVERS VIA PNPUTIL]%RST%
echo %CYN%  [CAPRI // Edgerunners 2]: "Forcando nova leitura do barramento Plug and Play..."%RST%
pnputil /scan-devices
if %errorlevel%==0 (
    echo %GRN%  [OK] Varredura de hardware concluida.%RST%
) else (
    echo %RED%  [ERRO] Falha ao executar pnputil /scan-devices.%RST%
    echo %MAG%  [DOC // Edgerunners 1]: "Tente abrir o Gerenciador de Dispositivos manualmente."%RST%
)
goto DRV_MENU

:DRV_FIX
echo.
echo %YLW%[TENTANDO CORRIGIR / REINICIAR DISPOSITIVOS COM ERRO]%RST%
echo %RED%  [TALIA // Edgerunners 2]: "Reiniciando dispositivos travados e forcando reinstalacao de driver..."%RST%
powershell -NoProfile -Command "$bad = Get-PnpDevice | Where-Object { $_.Status -eq 'Error' -or $_.Status -eq 'Degraded' }; if (-not $bad) { Write-Host '[INFO] Nenhum dispositivo em estado de erro encontrado.' -ForegroundColor Green } else { foreach ($d in $bad) { Write-Host ('  Tentando reiniciar: ' + $d.FriendlyName) -ForegroundColor Yellow; try { Disable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Enable-PnpDevice -InstanceId $d.InstanceId -Confirm:$false -ErrorAction Stop; Write-Host '    [OK] Reiniciado com sucesso.' -ForegroundColor Green } catch { Write-Host ('    [AVISO] Nao foi possivel corrigir automaticamente (pode exigir driver do fabricante): ' + $_.Exception.Message) -ForegroundColor Red } }; pnputil /scan-devices | Out-Null }"
goto DRV_MENU

:DRV_WU
echo.
echo %GRN%[BUSCANDO DRIVERS NO WINDOWS UPDATE]%RST%
echo %YLW%  [PANAM PALMER // CP2077]: "Disparando busca de drivers opcionais no Windows Update..."%RST%
powershell -NoProfile -Command "Write-Host 'Consultando catalogo de drivers disponiveis no Windows Update (pode levar alguns segundos)...' -ForegroundColor Cyan; try { $sess = New-Object -ComObject Microsoft.Update.Session; $search = $sess.CreateUpdateSearcher(); $res = $search.Search(\"IsInstalled=0 and Type='Driver'\"); if ($res.Updates.Count -eq 0) { Write-Host '[OK] Nenhum driver pendente encontrado no Windows Update.' -ForegroundColor Green } else { Write-Host ('[ENCONTRADOS] ' + $res.Updates.Count + ' driver(s) disponivel(is):') -ForegroundColor Yellow; foreach ($u in $res.Updates) { Write-Host ('  - ' + $u.Title) -ForegroundColor White } } } catch { Write-Host ('[AVISO] Nao foi possivel consultar a API do Update: ' + $_.Exception.Message) -ForegroundColor Yellow }"
echo %CYN%Abrindo pagina de Atualizacoes Opcionais de Drivers do Windows...%RST%
start "" "ms-settings:windowsupdate-optionalupdates"
goto DRV_MENU

:DRV_OPEN
echo %MAG%Abrindo Gerenciador de Dispositivos (devmgmt.msc)...%RST%
echo %WHT%  [GORO TAKEMURA // CP2077]: "Gerenciador aberto. Clique com o botao direito no dispositivo com aviso para atualizar."%RST%
start "" devmgmt.msc
goto DRV_MENU

:DRV_FIM
echo.
pause
exit /b
