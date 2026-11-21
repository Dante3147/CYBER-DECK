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
title CYBERDECK // 10 - Saude SMART e Bateria
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [10] DIAGNOSTICO DE CROMO: SAUDE DOS DISCOS (SMART) E BATERIA%RST%
echo %COR_PRI%========================================================================%RST%
echo %GRN%  [VIKTOR VEKTOR // Cyberpunk 2077]:%RST%
echo %WHT%  "Senta na cadeira, choom. Vamos checar se seus discos estao saudaveis."%RST%
echo.
echo %CYN%[1/2] Lendo status SMART dos discos (SSD / HD)...%RST%
echo %GRN%  [GLORIA MARTINEZ // Edgerunners 1]: "Cuide bem do que voce tem antes que quebre."%RST%
powershell -NoProfile -Command "try { $disks = Get-PhysicalDisk -ErrorAction Stop; if ($disks) { $disks | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{Name='Tamanho(GB)';Expression={[math]::Round($_.Size/1GB, 2)}} | Format-Table -AutoSize; Write-Host '  [CAPRI // Edgerunners 2]: Se tudo aparecer como Healthy, seus discos estao seguros.' -ForegroundColor Cyan } else { throw 'Vazio' } } catch { Write-Host '[AVISO] Leitura SMART direta indisponivel. Usando fallback WMI...' -ForegroundColor Yellow; Write-Host '  [RIVER WARD // NCPD - CP2077]: Investigando via WMI alternativo.' -ForegroundColor Yellow; Get-CimInstance Win32_DiskDrive | Select-Object Model, Status, @{Name='Tamanho(GB)';Expression={[math]::Round($_.Size/1GB, 2)}} | Format-Table -AutoSize }"

echo %CYN%[2/2] Verificando celula de energia (Bateria)...%RST%
echo %MAG%  [MISTY OLSZEWSKI // Cyberpunk 2077]: "Lendo a energia vital da sua maquina..."%RST%
powershell -NoProfile -Command "if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $dt = Get-Date -Format 'dd-MM-yyyy'; $desk = Join-Path $env:USERPROFILE ('Desktop\DADOS\BACKUP - ' + $dt + '\RELATORIOS_HARDWARE'); if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Path $desk -Force | Out-Null }; $rep = Join-Path $desk 'relatorio_bateria.html'; powercfg /batteryreport /output $rep | Out-Null; $d = Join-Path '%~dp0..' ('DADOS\BACKUP - ' + $dt + '\RELATORIOS_HARDWARE'); if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }; Copy-Item $rep (Join-Path $d 'relatorio_bateria.html') -Force -ErrorAction SilentlyContinue; Write-Host ('[OK] Relatorio salvo em: ' + $rep) -ForegroundColor Green; Write-Host ('[OK] Copia no Projeto: ' + $d) -ForegroundColor Cyan; Start-Process $rep } else { Write-Host '[INFO] Nenhuma bateria detectada (Sistema Desktop ligado na tomada).' -ForegroundColor Yellow }"
echo.
pause
exit /b
