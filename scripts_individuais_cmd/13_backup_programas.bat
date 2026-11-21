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
title CYBERDECK // 13 - Backup Winget
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [13] BACKUP DA LISTA DE PROGRAMAS (DATASHARD / WINGET EXPORT)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [REGINA JONES // Fixer - Cyberpunk 2077]: "Exportando todos os seus programas para um Datashard."%RST%
echo %GRY%  [MR. HANDS // Cyberpunk 2077]: "Ideal para restaurar tudo num clique apos formatar."%RST%
echo.
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "Get-Date -Format 'dd-MM-yyyy'"`) do set "DATA_BK=%%D"
set "PASTA_DESK_BK=%USERPROFILE%\Desktop\DADOS\BACKUP - !DATA_BK!\BACKUPS-PROGRAMAS"
set "PASTA_PROJ_BK=%~dp0..\DADOS\BACKUP - !DATA_BK!\BACKUPS-PROGRAMAS"
if not exist "!PASTA_DESK_BK!" mkdir "!PASTA_DESK_BK!"
winget export -o "!PASTA_DESK_BK!\meus_programas.json" --accept-source-agreements
if !errorlevel! neq 0 (
    echo %RED%  [WAKAKO OKADA // CP2077]: "Erro ao exportar. Confirme se o Winget esta atualizado."%RST%
    pause
    exit /b
)
powershell -NoProfile -Command "$dest = Join-Path $env:PASTA_DESK_BK 'meus_programas.json'; $t = @('========================================================================','  CYBERDECK OS // TUTORIAL PARA REINSTALAR TODOS OS PROGRAMAS','========================================================================','','Data do backup: ' + $env:DATA_BK,'Pasta na Area de Trabalho: ' + $env:PASTA_DESK_BK,'','','!!! ATENCAO IMPORTANTE: SALVE ESTA PASTA ANTES DE FORMATAR O PC !!!','------------------------------------------------------------------------','Os dados foram salvos na Area de Trabalho dentro de DADOS\BACKUP - ' + $env:DATA_BK,'e tambem espelhados dentro da pasta DADOS do seu projeto (Pen Drive / SSD).','','========================================================================','  PASSO A PASSO PARA REINSTALAR TUDO APOS FORMATAR O WINDOWS','========================================================================','','1. Abra o CMD ou PowerShell como Administrador no Windows novo.','2. Execute o comando abaixo (ajustando o caminho se estiver no Pen Drive):','','   winget import -i \"' + $dest + '\" --accept-package-agreements --accept-source-agreements','','========================================================================'); Set-Content -Path (Join-Path $env:PASTA_DESK_BK 'TUTORIAL PARA REINSTALAR TODOS OS PROGRAMAS.txt') -Value $t -Encoding UTF8"
if not exist "!PASTA_PROJ_BK!" mkdir "!PASTA_PROJ_BK!"
xcopy "!PASTA_DESK_BK!\*" "!PASTA_PROJ_BK!\" /E /Y /I >nul 2>&1
echo %GRN%  [OK] Datashard salvo na Area de Trabalho: !PASTA_DESK_BK!\meus_programas.json%RST%
echo %GRN%  [OK] Tutorial gerado em: !PASTA_DESK_BK!\TUTORIAL PARA REINSTALAR TODOS OS PROGRAMAS.txt%RST%
echo %CYN%  [OK] Copia portatil salva no Projeto: !PASTA_PROJ_BK!\%RST%
echo %YLW%  [AVISO IMPORTANTE] Salve a pasta BACKUPS-PROGRAMAS em um pendrive, HD externo ou nuvem ANTES de formatar o PC.%RST%
echo %CYN%  [V // Cyberpunk 2077]: "Lista e tutorial salvos na pasta BACKUPS-PROGRAMAS. Nao esquece de copiar pra fora antes de formatar."%RST%
:EXP_END
echo.
pause
exit /b
