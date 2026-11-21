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
net session >nul 2>&1
if %errorlevel% neq 0 (
    cls
    echo %RED%========================================================================%RST%
    echo %RED%  [ERRO DE ICE] ACESSO NEGADO PELA NETWATCH%RST%
    echo %YLW%  Execute este script como ADMINISTRADOR para obter acesso root.%RST%
    echo %GRY%  Clique com o botao direito ^> "Executar como administrador"%RST%
    echo %RED%========================================================================%RST%
    echo.
    pause
    exit /b
)
title CYBERDECK // 16 - Overclock Neural (Auditoria Interativa de Otimizacao)
:SUBMENU_OPT16
cls
echo %MAG%========================================================================%RST%
echo %MAG%  [16] OVERCLOCK NEURAL // OTIMIZACAO + LIMPEZA REGEDIT E %%APPDATA%%%RST%
echo %MAG%========================================================================%RST%
echo   %MAG%[1]%RST% Auditoria Interativa de Otimizacao (7 Etapas: Game Mode, DVR, RAM, Menus, P2P, SSD)
echo   %CYN%[2]%RST% Limpeza Profunda de Registros Velhos (Regedit) e Pastas Orfas (%%APPDATA%% / Windows)
echo   %GRY%[0]%RST% Sair
echo %MAG%========================================================================%RST%
set "opt16="
set /p "opt16=Escolha [0-2]: "
if "%opt16%"=="0" exit /b
if "%opt16%"=="2" goto RUN_OPT16_ORPHAN
if not "%opt16%"=="1" goto SUBMENU_OPT16
goto START_OPT16_ETAPAS

:RUN_OPT16_ORPHAN
if exist "%~dp0..\scripts_individuais_powershell\16_otimizacao_windows.ps1" goto RUN_OPT16_ORPHAN_PS
echo [ERRO] Nao foi possivel localizar ..\scripts_individuais_powershell\16_otimizacao_windows.ps1
pause
goto SUBMENU_OPT16
:RUN_OPT16_ORPHAN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts_individuais_powershell\16_otimizacao_windows.ps1" -OnlyOrphanClean
goto SUBMENU_OPT16

:START_OPT16_ETAPAS
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [OVERCLOCK NEURAL] AUDITORIA INTERATIVA DE OTIMIZACAO DO WINDOWS%RST%
echo %GRY%  Verificando 7 modulos de desempenho, jogos e recursos do sistema...%RST%
echo %GRY%  Voce decidira individualmente se quer OTIMIZAR ou RESTAURAR cada um.%RST%
echo %MAG%========================================================================%RST%
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 1/7 - MODO DE JOGO / GAME MODE (DAVID MARTINEZ - EDGERUNNERS 1)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [1/7] DESEMPENHO: Modo de Jogo do Windows (Game Mode)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -ErrorAction Stop).AutoGameModeEnabled; if ($v -eq 1) { exit 0 } else { exit 1 } } catch { exit 1 }"
if %errorlevel%==0 (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [ATIVADO - PRIORIDADE PARA JOGOS LIGADA]%RST%
) else (
    set "ST_OPT=PADRAO"
    echo %YLW%  STATUS DETECTADO: [DESATIVADO - MODO PADRAO]%RST%
)
echo.
echo %YLW%  [DAVID MARTINEZ // EDGERUNNERS 1a Temporada]:%RST%
echo %WHT%  "Se quer rodar no limite tipo um Sandevistan, o sistema precisa focar%RST%
echo %WHT%   todo o poder de fogo no jogo e pausar tarefas chatas do Windows Update%RST%
echo %WHT%   enquanto voce estiver jogando."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Prioriza recursos de CPU/GPU para jogos em tela cheia e
echo   impede o Windows Update de instalar drivers ou reiniciar durante partidas.
echo %RED%  [IMPACTO NEGATIVO AO ATIVAR]:%RST% Em raros jogos antigos ou quando voce
echo   grava/faz live ao mesmo tempo (OBS), o Game Mode pode reduzir levemente
echo   a prioridade do programa em segundo plano. Na maioria dos PCs, ajuda.
echo.
if "%ST_OPT%"=="PADRAO" (
    set "resp="
    set /p "resp=%YLW%Deseja ATIVAR o Modo de Jogo (Game Mode) agora? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] Modo de Jogo ativado com sucesso.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Modo de Jogo permanece desativado.%RST%
    )
) else (
    echo %CYN%  [AO DESATIVAR]:%RST% Desliga a priorizacao automatica de jogos do Windows.
    set "resp="
    set /p "resp=%YLW%O Modo de Jogo ja esta ativado. Deseja DESATIVAR? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Modo de Jogo desativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Modo de Jogo continua ativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 2/7 - GAME DVR / GRAVACAO EM SEGUNDO PLANO (JUDY ALVAREZ - CP2077)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [2/7] VIDEO / FPS: Gravacao em Segundo Plano (Xbox Game DVR)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -ErrorAction Stop).GameDVR_Enabled; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_OPT=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - CONSUMINDO RECURSOS DE VIDEO]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - OTIMIZADO PARA FPS]%RST%
)
echo.
echo %CYN%  [JUDY ALVAREZ // TECNICA DE BRAIN-DANCE - Cyberpunk 2077]:%RST%
echo %WHT%  "Se voce ja usa ferramentas proprias de gravacao, deixar o Game DVR da%RST%
echo %WHT%   Microsoft rodando por baixo so rouba ciclos do codificador da sua GPU%RST%
echo %WHT%   e gera engasgos (stuttering) nos jogos."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Mantem um buffer de captura de tela/video da Xbox Game Bar
echo   pronto em segundo plano durante jogos.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Voce perde a gravacao rapida nativa
echo   da Xbox Game Bar (atalho Win+G / Win+Alt+R). Programas externos como
echo   OBS Studio ou NVIDIA ShadowPlay continuam funcionando normalmente.
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o Xbox Game DVR para ganhar estabilidade/FPS? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Xbox Game DVR desativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Xbox Game DVR permanece ativo.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Habilita novamente a captura de tela/video pela Xbox Game Bar.
    set "resp="
    set /p "resp=%YLW%O Game DVR ja esta desativado. Deseja REATIVAR o padrao? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /f >nul 2>&1
        echo %GRN%  [OK] Xbox Game DVR reativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Xbox Game DVR continua desativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 3/7 - APPS EM SEGUNDO PLANO (TALIA - EDGERUNNERS 2)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [3/7] MEMORIA RAM: Aplicativos UWP em Segundo Plano%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name 'GlobalUserDisabled' -ErrorAction Stop).GlobalUserDisabled; if ($v -eq 1) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_OPT=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - APPS DA LOJA RODANDO EM SEGUNDO PLANO]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - RAM E CPU POUPADAS]%RST%
)
echo.
echo %RED%  [TALIA // MAELSTROM - Edgerunners 2a Temporada]:%RST%
echo %WHT%  "Um monte de aplicativos da Microsoft Store fica acordado comendo RAM%RST%
echo %WHT%   e CPU mesmo quando voce nem abriu eles. Cortar esses parasitas libera%RST%
echo %WHT%   memoria preciosa pro que realmente importa."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Impede que apps nativos da Microsoft Store (Clima, Noticias,
echo   Email, Fotos, etc.) fiquem atualizando dados e consumindo RAM fechados.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Notificacoes em tempo real de apps
echo   da Microsoft Store (como Email nativo, Calendario ou Alarme) so atualizam
echo   quando voce abrir o app. Programas normais (Discord, Steam, navegador)
echo   nao sao afetados.
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR aplicativos da Store em segundo plano? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Apps em segundo plano desativados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Apps em segundo plano permanecem ativos.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Permite novamente que apps da Microsoft Store rodem fechados.
    set "resp="
    set /p "resp=%YLW%Ja esta otimizado. Deseja REATIVAR apps em segundo plano? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] Apps em segundo plano reativados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua otimizado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 4/7 - ATRASO DE MENUS E DICAS DO WINDOWS (VIKTOR VEKTOR - CP2077)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [4/7] INTERFACE: Atraso de Menus (MenuShowDelay) e Dicas do Windows%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -ErrorAction Stop).MenuShowDelay; if ([int]$v -le 100) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_OPT=ATIVO"
    echo %YLW%  STATUS DETECTADO: [PADRAO - ATRASO DE 400ms E DICAS ATIVAS]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [OTIMIZADO - MENUS RAPIDOS 100ms E SEM DICAS]%RST%
)
echo.
echo %GRN%  [VIKTOR VEKTOR // RIPPERDOC - Cyberpunk 2077]:%RST%
echo %WHT%  "Calibrei a resposta do seu sistema: o Windows coloca um atraso artificial%RST%
echo %WHT%   de 400ms para abrir submenus e ainda dispara pop-ups de dicas. Baixar%RST%
echo %WHT%   para 100ms deixa o sistema bem mais agil na ponta dos dedos."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Reduz o tempo de abertura dos submenus do Windows de 400ms
echo   para 100ms e desativa dicas/sugestoes automaticas (ContentDeliveryManager).
echo %RED%  [IMPACTO NEGATIVO AO OTIMIZAR]:%RST% Nenhum impacto negativo de estabilidade.
echo   Voce apenas deixa de ver telas de dicas e 'descubra novidades' do Windows.
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja OTIMIZAR o atraso de menus e desativar dicas do Windows? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 100 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Menus acelerados (100ms^) e dicas desativadas.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Configuracao padrao mantida.%RST%
    )
) else (
    echo %CYN%  [AO RESTAURAR]:%RST% Retorna o atraso de menus para 400ms e reativa dicas do Windows.
    set "resp="
    set /p "resp=%YLW%Ja esta otimizado. Deseja RESTAURAR o padrao da Microsoft? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] Padrao de menus e dicas restaurado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua otimizado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 5/7 - EFEITOS DE TRANSPARENCIA (REBECCA - EDGERUNNERS 1)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [5/7] VISUAL / GPU: Efeitos de Transparencia da Interface%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -ErrorAction Stop).EnableTransparency; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_OPT=ATIVO"
    echo %YLW%  STATUS DETECTADO: [ATIVO - EFEITO VIDRO/BLUR LIGADO]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - CORES SOLIDAS / MENOR USO DE GPU]%RST%
)
echo.
echo %CYN%  [REBECCA // SOLO - Edgerunners 1a Temporada]:%RST%
echo %WHT%  "Quer o PC bonito ou quer o PC rapido? Esses efeitos de vidro borrado%RST%
echo %WHT%   na barra de tarefas e no Menu Iniciar ficam usando sua GPU o tempo%RST%
echo %WHT%   todo a toa. Desligar deixa o desktop seco e direto ao ponto."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Desativa o efeito de desfoque/transparencia (Acrylic/Mica)
echo   na Barra de Tarefas, Menu Iniciar e janelas do sistema.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Apenas estetico: a Barra de Tarefas
echo   e o Menu Iniciar ficam com cor solida em vez de vidro translucido.
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR os efeitos de transparencia para poupar GPU? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Transparencia desativada.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Transparencia permanece ativa.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Devolve o visual translucido/vidro a Barra de Tarefas e menus.
    set "resp="
    set /p "resp=%YLW%A transparencia esta desativada. Deseja REATIVAR? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] Transparencia reativada.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Transparencia continua desativada.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 6/7 - OTIMIZACAO DE ENTREGA P2P E CACHE (PANAM PALMER - CP2077)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [6/7] REDE E DISCO: Otimizacao de Entrega P2P (Windows Update)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -ErrorAction Stop).DODownloadMode; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_OPT=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - COMPARTILHAMENTO P2P DE UPDATES LIGADO]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - APENAS DOWNLOAD DIRETO DA MICROSOFT]%RST%
)
echo.
echo %YLW%  [PANAM PALMER // ALDECALDOS - Cyberpunk 2077]:%RST%
echo %WHT%  "A Microsoft usa a sua banda de internet e o seu disco como se fossem%RST%
echo %WHT%   um servidor torrent pra enviar atualizacoes para outros PCs na rede.%RST%
echo %WHT%   Cortar o P2P e limpar esse cache evita lag repentino na sua conexao."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Desativa o compartilhamento P2P de atualizacoes do Windows
echo   (Delivery Optimization) e limpa o cache de arquivos temporarios de entrega.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Se voce tiver varios PCs na mesma casa,
echo   cada um baixara updates direto da internet em vez de copiar do PC vizinho.
echo   Para jogos online e ping estavel, desativar e altamente recomendado.
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o P2P do Windows Update e limpar o cache? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
        powershell -NoProfile -Command "Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue" >nul 2>&1
        echo %GRN%  [OK] Compartilhamento P2P desativado e cache de entrega limpo.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Otimizacao de entrega permanece no padrao.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Volta a permitir compartilhamento de updates na rede local.
    set "resp="
    set /p "resp=%YLW%O P2P ja esta desativado. Deseja REATIVAR o padrao da Microsoft? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /f >nul 2>&1
        echo %GRN%  [OK] Otimizacao de entrega restaurada para o padrao.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua desativado (apenas download direto^).%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 7/7 - HIBERNACAO / HIBERFIL.SYS (ROMAN CARAX - EDGERUNNERS 2)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [7/7] ARMAZENAMENTO SSD: Hibernacao do Windows (hiberfil.sys)%RST%
echo %MAG%========================================================================%RST%
if exist "C:\hiberfil.sys" (
    set "ST_OPT=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVA - OCUPANDO VARIOS GB NO DISCO C:]%RST%
) else (
    set "ST_OPT=OTIMIZADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADA - ESPACO NO SSD LIBERADO]%RST%
)
echo.
echo %MAG%  [ROMAN CARAX // EDGERUNNERS 2a Temporada]:%RST%
echo %WHT%  "A hibernacao reserva um bloco gigante do seu SSD apenas para congelar%RST%
echo %WHT%   a memoria RAM no disco. Em um desktop com SSD, isso raramente vale o%RST%
echo %WHT%   espaco desperdicado — e ainda aumenta a escrita desnecessaria no drive."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Desativa a hibernacao (powercfg -h off) e apaga o arquivo
echo   oculto C:\hiberfil.sys, liberando de 3 GB a mais de 12 GB no SSD.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% A opcao 'Hibernar' some do menu
echo   Desligar e a 'Inicializacao Rapida' (Fast Startup) e desativada (o boot
echo   em SSD continua rapido e mais limpo; em notebooks, pode fazer falta se
echo   voce usa hibernacao quando a bateria acaba).
echo.
if "%ST_OPT%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR a Hibernacao e liberar espaco no SSD? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        powercfg -h off
        echo %GRN%  [OK] Hibernacao desativada e C:\hiberfil.sys removido.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Hibernacao permanece ativa.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Recria o C:\hiberfil.sys e devolve Hibernar / Fast Startup.
    set "resp="
    set /p "resp=%YLW%A Hibernacao esta desativada. Deseja REATIVAR? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        powercfg -h on
        echo %GRN%  [OK] Hibernacao reativada.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Hibernacao continua desativada.%RST%
    )
)
echo.
echo %GRN%========================================================================%RST%
echo %GRN%  [OVERCLOCK NEURAL FINALIZADO] Todas as 7 etapas foram auditadas.%RST%
echo %YLW%  Reinicie o PC para aplicar 100%% das otimizacoes do Windows.%RST%
echo %GRN%========================================================================%RST%
pause
exit /b
