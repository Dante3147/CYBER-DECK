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
title CYBERDECK // 02 - GPU NVIDIA/AMD
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [02] VERIFICADOR E ATUALIZADOR DE GPU (OTICA KIROSHI)%RST%
echo %COR_PRI%========================================================================%RST%
echo %MAG%  [ROMAN CARAX // Edgerunners 2]:%RST%
echo %WHT%  "A imagem precisa estar nitida como cinema de verdade. Lendo sua GPU..."%RST%
echo.
echo %CYN%Hardware de Video e Versao Atual do Driver:%RST%
powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, @{Name='DataDriver';Expression={if($_.DriverDate){$_.DriverDate.ToString('dd/MM/yyyy')}else{'N/A'}}} | Format-Table -AutoSize"

set "GPU_LIST="
for /f "delims=" %%i in ('powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Select-Object -ExpandProperty Name) -join ', '"') do set "GPU_LIST=%%i"

echo !GPU_LIST! | findstr /i "NVIDIA" >nul
if %errorlevel%==0 goto GPU_NVIDIA
echo !GPU_LIST! | findstr /i "AMD Radeon" >nul
if %errorlevel%==0 goto GPU_AMD

echo %YLW%[AVISO]%RST% Nenhuma GPU dedicada NVIDIA ou AMD identificada automaticamente.
echo %CYN%  [BRENDAN // Maquina de Vendas - Cyberpunk 2077]:%RST%
echo %WHT%  "Hmm, so encontrei video integrado por aqui. Tudo bem, acontece nas melhores familias."%RST%
goto GPU_FIM_LBL

:GPU_NVIDIA
echo %GRN%[NVIDIA DETECTADA]%RST%
echo %YLW%  [KERRY EURODYNE // Cyberpunk 2077]: "Placa verde na area. Abrindo o painel NVIDIA."%RST%
if exist "C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe" (
    start "" "C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe"
    goto GPU_FIM_LBL
)
echo %CYN%NVIDIA App nao encontrado. Instalando via Winget...%RST%
winget install --id Nvidia.NVIDIAApp --accept-source-agreements --accept-package-agreements --silent
if exist "C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe" (
    start "" "C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe"
    goto GPU_FIM_LBL
)
echo %RED%  [ERRO] Nao foi possivel instalar o NVIDIA App automaticamente.%RST%
echo %RED%  [TALIA // Edgerunners 2]: "O Winget falhou. Vou abrir o site oficial da NVIDIA."%RST%
start "" "https://www.nvidia.com/pt-br/drivers/"
goto GPU_FIM_LBL

:GPU_AMD
echo %RED%[AMD DETECTADA]%RST%
echo %CYN%  [REBECCA // Edgerunners 1]: "Radeon na maquina. Bora abrir o Adrenalin."%RST%
if exist "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe" (
    start "" "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"
    goto GPU_FIM_LBL
)
echo %YLW%  [AVISO] Adrenalin nao encontrado localmente.%RST%
echo %RED%  [TALIA // Edgerunners 2]: "Sem app instalado. Abrindo pagina oficial da AMD."%RST%
start "" "https://www.amd.com/pt/support/download/drivers.html"

:GPU_FIM_LBL
echo.
pause
exit /b
