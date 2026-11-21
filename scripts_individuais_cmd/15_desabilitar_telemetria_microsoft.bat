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
title CYBERDECK // 15 - Modo Fantasma (Auditoria Interativa de Telemetria)
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [MODO FANTASMA] AUDITORIA INTERATIVA DE TELEMETRIA DA MICROSOFT%RST%
echo %GRY%  Verificando 8 modulos de coleta de dados ativos no seu sistema...%RST%
echo %GRY%  Voce decidira individualmente se quer DESATIVAR ou REATIVAR cada um.%RST%
echo %MAG%========================================================================%RST%
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 1/8 - DIAGTRACK (CAPRI - EDGERUNNERS 2)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [1/8] SERVICO: DiagTrack (Telemetria e Experiencias Conectadas)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "$s = Get-CimInstance Win32_Service -Filter \"Name='DiagTrack'\" -ErrorAction SilentlyContinue; if ($s -and $s.StartMode -ne 'Disabled') { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - COLETANDO DADOS EM SEGUNDO PLANO]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - BLOQUEADO]%RST%
)
echo.
echo %CYN%  [CAPRI // PROJETO CAPRICORN - Edgerunners 2]:%RST%
echo %WHT%  "Detectei o principal canal de extracao da corporacao: o DiagTrack.%RST%
echo %WHT%   Ele roda calado nos bastidores coletando logs de uso, aplicativos%RST%
echo %WHT%   abertos e relatorios de falhas para enviar aos servidores deles."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Servico central de telemetria e diagnostico do Windows.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% O Hub de Feedback e o envio automatico
echo   de relatorios de erro param de funcionar; o Windows Insider pode exigir
echo   este servico ligado. Em uso normal e jogos, nao causa problemas.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o servico DiagTrack agora? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        sc stop DiagTrack >nul 2>&1
        sc config DiagTrack start= disabled >nul 2>&1
        echo %GRN%  [OK] DiagTrack interrompido e desativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] DiagTrack permanece ativo.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Volta o servico para inicio automatico e retoma a coleta padrao.
    set "resp="
    set /p "resp=%YLW%Este processo ja esta desativado. Deseja REATIVAR o DiagTrack? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        sc config DiagTrack start= auto >nul 2>&1
        sc start DiagTrack >nul 2>&1
        echo %GRN%  [OK] DiagTrack reativado para o padrao da Microsoft.%RST%
    ) else (
        echo %GRY%  [MANTIDO] DiagTrack continua desativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 2/8 - DMWAPPUSHSERVICE (SONGBIRD / SO MI - CYBERPUNK 2077 PHANTOM LIBERTY)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [2/8] SERVICO: dmwappushservice (Roteamento Push WAP / MDM)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "$s = Get-CimInstance Win32_Service -Filter \"Name='dmwappushservice'\" -ErrorAction SilentlyContinue; if ($s -and $s.StartMode -ne 'Disabled') { exit 0 } else { exit 1 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO / DISPONIVEL]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - BLOQUEADO]%RST%
)
echo.
echo %MAG%  [SONGBIRD (SO MI) // NETRUNNER NUSA - Cyberpunk 2077]:%RST%
echo %WHT%  "Achei uma porta de roteamento push conectada ao nucleo de telemetria.%RST%
echo %WHT%   E o dmwappushservice. Ele serve para receber comandos remotos de%RST%
echo %WHT%   gerenciamento e escoar pacotes de telemetria pela rede."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Roteia mensagens push WAP (MDM) e auxilia o envio de telemetria.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Nenhum em PCs pessoais. Apenas em
echo   notebooks corporativos gerenciados por TI (Microsoft Intune) pode bloquear
echo   politicas remotas da empresa.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o servico dmwappushservice agora? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        sc stop dmwappushservice >nul 2>&1
        sc config dmwappushservice start= disabled >nul 2>&1
        echo %GRN%  [OK] dmwappushservice desativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] dmwappushservice permanece como estava.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Restaura o servico para inicio manual (padrao do Windows^).
    set "resp="
    set /p "resp=%YLW%Este processo ja esta desativado. Deseja REATIVAR o dmwappushservice? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        sc config dmwappushservice start= demand >nul 2>&1
        echo %GRN%  [OK] dmwappushservice reativado (inicio manual^).%RST%
    ) else (
        echo %GRY%  [MANTIDO] dmwappushservice continua desativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 3/8 - ALLOWTELEMETRY (LUCY - EDGERUNNERS 1a TEMPORADA)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [3/8] POLITICA DE REGISTRO: AllowTelemetry (Nivel de Coleta Global)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction Stop).AllowTelemetry; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - COLETA PADRAO PERMITIDA]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - NIVEL 0 APLICADO]%RST%
)
echo.
echo %CYN%  [LUCY // NETRUNNER - Edgerunners 1a Temporada]:%RST%
echo %WHT%  "A chave AllowTelemetry define o quanto do seu sistema e transmitido%RST%
echo %WHT%   para fora. Se voce quer desaparecer do radar, precisa cravar essa%RST%
echo %WHT%   politica em zero no Registro."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Define o volume de dados de diagnostico que o Windows envia.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Nas Configuracoes do Windows (Privacidade),
echo   pode aparecer o aviso 'Algumas configuracoes sao gerenciadas pela sua
echo   organizacao' (efeito normal de politica local). Nao afeta jogos ou apps.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja BLOQUEAR a coleta global (AllowTelemetry = 0)? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Politica AllowTelemetry cravada em 0 (Minimo/Seguranca^).%RST%
    ) else (
        echo %GRY%  [MANTIDO] Nivel de telemetria mantido no padrao.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Remove a politica local e devolve o controle para as Configuracoes.
    set "resp="
    set /p "resp=%YLW%O bloqueio AllowTelemetry ja esta ativo. Deseja REATIVAR o padrao? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /f >nul 2>&1
        echo %GRN%  [OK] Controle padrao de telemetria restaurado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Bloqueio AllowTelemetry continua ativo.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 4/8 - ADVERTISING ID & EXPERIENCIAS PERSONALIZADAS (JOHNNY SILVERHAND)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [4/8] PRIVACIDADE: ID de Publicidade e Experiencias Personalizadas%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -ErrorAction Stop).Enabled; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - PERFIL DE ANUNCIOS LIGADO]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - BLOQUEADO]%RST%
)
echo.
echo %RED%  [JOHNNY SILVERHAND // SAMURAI - Cyberpunk 2077]:%RST%
echo %WHT%  "Olha so essa porcaria corporativa: um ID de publicidade colado na sua%RST%
echo %WHT%   conta pra empurrar propaganda personalizada na sua tela. Se dependesse%RST%
echo %WHT%   de mim, eu explodia o servidor, mas desligar a chave ja resolve."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Gera um identificador unico para apps exibirem anuncios
echo   direcionados e sugestoes baseadas nos seus dados de diagnostico.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Praticamente zero. Voce apenas deixa
echo   de receber recomendacoes personalizadas em apps da Microsoft Store.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o ID de Publicidade e Experiencias Personalizadas? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] ID de publicidade e experiencias personalizadas desativados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] ID de publicidade permanece ativo.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Liga novamente o ID de anuncios e sugestoes personalizadas.
    set "resp="
    set /p "resp=%YLW%Ja esta desativado. Deseja REATIVAR o ID de Publicidade? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] ID de publicidade reativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua desativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 5/8 - HISTORICO DE ATIVIDADES E RASTREAMENTO (WEAK "KING" KINGSLEY)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [5/8] RASTREAMENTO: Historico de Atividades e Apps Abertos%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'EnableActivityFeed' -ErrorAction Stop).EnableActivityFeed; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - REGISTRANDO ATIVIDADES]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - BLOQUEADO]%RST%
)
echo.
echo %YLW%  [WEAK "KING" KINGSLEY // EDGERUNNERS 2a Temporada]:%RST%
echo %WHT%  "O sistema esta gravando um diario de tudo o que voce abre e tentando%RST%
echo %WHT%   sincronizar seu historico de atividades na nuvem. Se voce nao quer%RST%
echo %WHT%   deixar trilha digital no Menu Iniciar, corte isso agora."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Monitora quais aplicativos voce inicia (Start_TrackProgs)
echo   e envia o historico de atividades (Activity Feed) para a conta Microsoft.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% A lista de 'Mais usados' no Menu Iniciar
echo   deixa de se atualizar automaticamente e a sincronizacao de atividades entre
echo   dispositivos fica desligada.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR o Historico de Atividades e rastreamento de apps? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Historico de atividades e rastreamento de apps desativados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Historico de atividades permanece ativo.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Reativa a lista de 'Mais usados' e a sincronizacao de historico.
    set "resp="
    set /p "resp=%YLW%Ja esta desativado. Deseja REATIVAR o Historico de Atividades? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 1 /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /f >nul 2>&1
        echo %GRN%  [OK] Historico de atividades reativado.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua desativado.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 6/8 - TAREFAS AGENDADAS DE TELEMETRIA (KIWI - EDGERUNNERS 1a TEMP)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [6/8] TAREFAS AGENDADAS: Compatibility Appraiser, CEIP e DiskDiag%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $t = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\' -TaskName 'Microsoft Compatibility Appraiser' -ErrorAction Stop; if ($t.State -eq 'Disabled') { exit 1 } else { exit 0 } } catch { exit 1 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - TAREFAS AGENDADAS HABILITADAS]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - TAREFAS PAUSADAS]%RST%
)
echo.
echo %MAG%  [KIWI // NETRUNNER - Edgerunners 1a Temporada]:%RST%
echo %WHT%  "Nunca confie em processos agendados que acordam sozinhos. Essas 5%RST%
echo %WHT%   tarefas varrem seus programas e discos para enviar relatorios a%RST%
echo %WHT%   Microsoft — e adoram causar picos de uso de CPU e disco no meio do jogo."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Executa varreduras periodicas de telemetria (Appraiser,
echo   ProgramDataUpdater, Consolidator, UsbCeip e DiskDiagnosticDataCollector).
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Avisos automaticos de compatibilidade
echo   antes de grandes mudancas de versao do Windows (ex: upgrade anual) podem
echo   demorar mais para aparecer no Windows Update. Melhora uso de CPU/Disco.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR as 5 tarefas agendadas de telemetria? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Disable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Disable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Disable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Disable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Disable >nul 2>&1
        echo %GRN%  [OK] Tarefas agendadas de telemetria desativadas.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Tarefas agendadas permanecem ativas.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Habilita novamente as 5 tarefas no Agendador de Tarefas.
    set "resp="
    set /p "resp=%YLW%As tarefas ja estao desativadas. Deseja REATIVAR todas elas? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        schtasks /Change /TN "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /Enable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Application Experience\ProgramDataUpdater" /Enable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /Enable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /Enable >nul 2>&1
        schtasks /Change /TN "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /Enable >nul 2>&1
        echo %GRN%  [OK] Tarefas agendadas reativadas.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Tarefas continuam desativadas.%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 7/8 - BUSCA BING E APPS PATROCINADOS (D - SNAKE NATION / EDGERUNNERS 2)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [7/8] MENU INICIAR: Busca Web/Bing e Apps Sugeridos (CloudContent)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name 'DisableSearchBoxSuggestions' -ErrorAction Stop).DisableSearchBoxSuggestions; if ($v -eq 1) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - ENVIANDO BUSCAS PARA O BING]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - BUSCA APENAS LOCAL]%RST%
)
echo.
echo %GRN%  [D // SNAKE NATION - Edgerunners 2a Temporada]:%RST%
echo %WHT%  "Cada letra que voce digita no Menu Iniciar esta vazando direto para%RST%
echo %WHT%   os servidores do Bing, alem de baixar apps patrocinados sem pedir.%RST%
echo %WHT%   Cortar isso deixa a busca do Windows bem mais rapida e limpa."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Conecta a barra de busca do Windows ao Bing e habilita
echo   recursos de consumidor (sugestoes de apps patrocinados no Menu Iniciar).
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Voce nao vera mais resultados da
echo   internet/Bing direto no Menu Iniciar (a busca ficara 100%% local no PC).
echo   Requer reiniciar o Explorer ou o Windows para surtir efeito.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR buscas Web/Bing e sugestoes no Menu Iniciar? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1
        echo %GRN%  [OK] Sugestoes Web/Bing e apps patrocinados desativados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Busca Web/Bing permanece ativa.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Volta a exibir resultados do Bing e sugestoes no Menu Iniciar.
    set "resp="
    set /p "resp=%YLW%Ja esta desativado. Deseja REATIVAR buscas Web/Bing no Iniciar? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /f >nul 2>&1
        reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /f >nul 2>&1
        echo %GRN%  [OK] Buscas Web/Bing e sugestoes reativadas.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua desativado (busca local^).%RST%
    )
)
echo.
pause

:: ----------------------------------------------------------------------------
:: ETAPA 8/8 - FEEDBACK AUTOMATICO SIUF (ALT CUNNINGHAM - CYBERPUNK 2077)
:: ----------------------------------------------------------------------------
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [8/8] NOTIFICACOES: Solicitacoes de Feedback da Microsoft (SIUF)%RST%
echo %MAG%========================================================================%RST%
powershell -NoProfile -Command "try { $v = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Siuf\Rules' -Name 'NumberOfSIUFInPeriod' -ErrorAction Stop).NumberOfSIUFInPeriod; if ($v -eq 0) { exit 1 } else { exit 0 } } catch { exit 0 }"
if %errorlevel%==0 (
    set "ST_TEL=ATIVO"
    echo %RED%  STATUS DETECTADO: [ATIVO - POP-UPS DE FEEDBACK PERMITIDOS]%RST%
) else (
    set "ST_TEL=DESATIVADO"
    echo %GRN%  STATUS DETECTADO: [DESATIVADO - SILENCIADO]%RST%
)
echo.
echo %RED%  [ALT CUNNINGHAM // ALEM DA BLACKWALL - Cyberpunk 2077]:%RST%
echo %WHT%  "A ultima camada e o modulo SIUF. Ele interrompe seu fluxo com pedidos%RST%
echo %WHT%   de avaliacao para alimentar os bancos de dados da corporacao. Silencie%RST%
echo %WHT%   esse ruido se quiser paz absoluta na rede."%RST%
echo.
echo %YLW%  [O QUE FAZ]:%RST% Controla a frequencia com que o Windows pede feedback.
echo %RED%  [IMPACTO NEGATIVO AO DESATIVAR]:%RST% Nenhum impacto negativo no sistema.
echo   Voce apenas deixa de receber pop-ups de pesquisa de satisfacao.
echo.
if "%ST_TEL%"=="ATIVO" (
    set "resp="
    set /p "resp=%YLW%Deseja DESATIVAR os pedidos automaticos de feedback (SIUF)? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f >nul 2>&1
        echo %GRN%  [OK] Pedidos de feedback silenciados.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Pedidos de feedback permanecem ativos.%RST%
    )
) else (
    echo %CYN%  [AO REATIVAR]:%RST% Permite novamente que o Windows exiba pedidos de feedback.
    set "resp="
    set /p "resp=%YLW%Ja esta desativado. Deseja REATIVAR os pedidos de feedback? [S/N]: %RST%"
    if /i "!resp!"=="S" (
        reg delete "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /f >nul 2>&1
        echo %GRN%  [OK] Pedidos de feedback reativados para o padrao.%RST%
    ) else (
        echo %GRY%  [MANTIDO] Continua silenciado.%RST%
    )
)
echo.
echo %GRN%========================================================================%RST%
echo %GRN%  [MODO FANTASMA FINALIZADO] Todas as 8 etapas foram auditadas.%RST%
echo %YLW%  Reinicie o PC para aplicar 100%% das alteracoes de privacidade.%RST%
echo %GRN%========================================================================%RST%
pause
exit /b
