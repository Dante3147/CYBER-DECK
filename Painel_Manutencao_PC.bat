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
:: Verificacao silenciosa de atualizacao (100% nativa CMD, sem abrir janela do PowerShell)
set "NOVA_VERSAO="
for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $u = (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Dante3147/CYBER-DECK/main/version.json' -TimeoutSec 3 -ErrorAction Stop).version; if ([version]($u -replace '[^0-9.]','') -gt [version]('36.0' -replace '[^0-9.]','')) { Write-Output $u } } catch {}" 2^>nul`) do (
    set "NOVA_VERSAO=%%v"
)

if defined NOVA_VERSAO (
    cls
    echo %MAG%========================================================================%RST%
    echo %GRN%  [NOVA ATUALIZACAO DISPONIVEL!] CYBERDECK OS v!NOVA_VERSAO!%RST%
    echo %CYN%  Versao Instalada: v36.0  ^>^>  Versao Nuvem: v!NOVA_VERSAO!%RST%
    echo %MAG%========================================================================%RST%
    echo %MAG%  [SONGBIRD // CP2077]: "Novo firmware detectado na rede do GitHub."%RST%
    echo %YLW%  [DAVID MARTINEZ // Edgerunners]: "Deseja atualizar agora?"%RST%
    echo.
    echo   %GRN%[1] Baixar e Atualizar Agora (Permanece no Painel .bat)%RST%
    echo   %GRY%[2] Continuar para o Menu Principal sem atualizar agora%RST%
    echo.
    set /p "DECISAO_UPD=Escolha uma opcao [1 ou 2]: "
    if "!DECISAO_UPD!"=="1" goto ATUALIZAR_BAT_DIRETO
)

:SELECAO_CORPO
title CYBERDECK OS v36.0 // NIGHT CITY EDITION (CMD)
cls
echo %YLW%========================================================================%RST%
echo %CYN%   _____ __     ______  ______ _____  _____  ______ _____ _  __  %RST%
echo %CYN%  / ____^|\ \   / /  _ \^|  ____^|  __ \^|  __ \^|  ____/ ____^| ^|/ /  %RST%
echo %CYN% ^| ^|      \ \_/ /^| ^|_) ^| ^|__  ^| ^|__) ^| ^|  ^| ^| ^|__ ^| ^|    ^| ' /   %RST%
echo %CYN% ^| ^|       \   / ^|  _ ^<^|  __^| ^|  _  /^| ^|  ^| ^|  __^|^| ^|    ^|  ^<    %RST%
echo %CYN% ^| ^|____    ^| ^|  ^| ^|_) ^| ^|____^| ^| \ \^| ^|__^| ^| ^|___^| ^|____^| . \   %RST%
echo %CYN%  \_____^|   ^|_^|  ^|____/^|______^|_^|  \_\_____/^|______\_____^|_^|\_\  %RST%
echo %YLW%========================================================================%RST%
echo %CYN%  PT ^| Criador do CYBER-DECK: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %CYN%  EN ^| CYBER-DECK Creator: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %CYN%  ES ^| Creador del CYBER-DECK: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %GRY%------------------------------------------------------------------------%RST%
echo %RED%  PT ^| !! COMERCIALIZACAO ESTRITAMENTE PROIBIDA ^| Apenas para uso pessoal e educacional%RST%
echo %RED%  EN ^| !! COMMERCIAL USE STRICTLY PROHIBITED ^| For personal and educational use only%RST%
echo %RED%  ES ^| !! USO COMERCIAL ESTRICTAMENTE PROHIBIDO ^| Solo para uso personal y educativo%RST%
echo %YLW%========================================================================%RST%
echo %RED%  [JOHNNY SILVERHAND]: "Acorda, Samurai. Temos um PC para otimizar."%RST%
echo %CYN%  [V]: "Escolhe logo a faccao e vamos limpar esse hardware."%RST%
echo.
echo %WHT%  SELECIONE SEU PROTOCOLO CORPORATIVO / FACCAO:%RST%
echo.
echo   %RED%[1] ARASAKA CORP%RST%         - %GRY%Vermelho/Branco (Saburo, Hanako, Capri)%RST%
echo   %YLW%[2] MILITECH%RST%             - %GRY%Amarelo Tatico/Cinza (NUSA, Reed, Songbird)%RST%
echo   %CYN%[3] KANG TAO%RST%             - %GRY%Ciano/Azul (Smart-Tech, Takemura)%RST%
echo   %MAG%[4] NETWATCH / BLACKWALL%RST% - %GRY%Magenta/Ciano (Alt Cunningham, Contencao)%RST%
echo   %YLW%[5] AFTERLIFE / MERC%RST%     - %GRY%Neon Edgerunners (David, Lucy, Weak ^& D)%RST%
echo   %GRN%[6] TRAUMA TEAM%RST%          - %GRY%Verde/Branco (Gloria, Viktor, Suporte Vital)%RST%
echo.
set "corpo="
set /p "corpo=%WHT%Escolha sua afiliacao [1-6]: %RST%"

if "%corpo%"=="1" goto CORPO_1
if "%corpo%"=="2" goto CORPO_2
if "%corpo%"=="3" goto CORPO_3
if "%corpo%"=="4" goto CORPO_4
if "%corpo%"=="5" goto CORPO_5
if "%corpo%"=="6" goto CORPO_6
echo %RED%  [REBECCA // Edgerunners 1]: "Ei, escolhe um numero de 1 a 6, choom."%RST%
timeout /t 2 >nul
goto SELECAO_CORPO

:CORPO_1
set "COR_PRI=%RED%"
set "COR_SEC=%WHT%"
set "CORPO_NOME=ARASAKA CORPORATION // PROJETO CAPRICORN"
set "CORPO_FRASE=Saburo e Capri: A ordem nasce do controle. Engrama em monitoramento."
goto MENU

:CORPO_2
set "COR_PRI=%YLW%"
set "COR_SEC=%GRY%"
set "CORPO_NOME=MILITECH INTERNATIONAL ARMAMENTS // NUSA"
set "CORPO_FRASE=Solomon Reed: Eficiencia balistica aplicada ao hardware. Sem falhas."
goto MENU

:CORPO_3
set "COR_PRI=%CYN%"
set "COR_SEC=%BLU%"
set "CORPO_NOME=KANG TAO // DIVISAO SMART-TECH"
set "CORPO_FRASE=Takemura: Precisao cirurgica. Nem mesmo um netrunner escapa."
goto MENU

:CORPO_4
set "COR_PRI=%MAG%"
set "COR_SEC=%CYN%"
set "CORPO_NOME=NETWATCH // BARREIRA BLACKWALL"
set "CORPO_FRASE=Alt Cunningham: Mantenha as IAs hostis fora da rede. Sistema protegido."
goto MENU

:CORPO_5
set "COR_PRI=%YLW%"
set "COR_SEC=%CYN%"
set "CORPO_NOME=AFTERLIFE // EDGERUNNERS OS (2076-2078)"
set "CORPO_FRASE=Rogue e David: Sem finais felizes em Night City... mas o PC vai voar."
goto MENU

:CORPO_6
set "COR_PRI=%GRN%"
set "COR_SEC=%WHT%"
set "CORPO_NOME=TRAUMA TEAM INTERNATIONAL // PLANO PLATINA"
set "CORPO_FRASE=Gloria e Vik: Sinais vitais do hardware estaveis. Extracao em 3 min."
goto MENU

:MENU
title %CORPO_NOME%
cls
echo %COR_PRI%========================================================================%RST%
echo %COR_PRI%  [%CORPO_NOME%]%RST%
echo %GRY%  "%CORPO_FRASE%"%RST%
echo %COR_PRI%========================================================================%RST%
echo.
echo %COR_SEC%  [ATUALIZACOES E IMPLANTES DE SOFTWARE]%RST%
echo    %COR_PRI%1.%RST% Atualizar todos os programas (Winget)
echo    %COR_PRI%2.%RST% Verificar / Atualizar Placa de Video (NVIDIA / AMD)
echo    %COR_PRI%3.%RST% Gerenciador de Dispositivos: Verificar, Corrigir e Atualizar Drivers
echo.
echo %COR_SEC%  [LIMPEZA DE ICE E INTEGRIDADE NEURAL]%RST%
echo    %COR_PRI%4.%RST% Limpar Arquivos Temporarios (%TEMP% e Windows\Temp)
echo    %COR_PRI%5.%RST% Reparar Windows (DISM + SFC - Anti-Ciberpsicose)
echo    %COR_PRI%6.%RST% Limpar Cache do Windows Update
echo    %COR_PRI%7.%RST% Limpar Cache de Shaders (DirectX / NVIDIA / AMD)
echo.
echo %COR_SEC%  [DESEMPENHO E CROMO (HARDWARE)]%RST%
echo    %COR_PRI%8.%RST% Otimizacao Inteligente de Discos (SSD=TRIM / HD=Defrag)
echo    %COR_PRI%9.%RST% Ativar Modo Sandevistan (Energia: Desempenho Maximo)
echo   %COR_PRI%10.%RST% Diagnostico de Cromo: Saude de Discos (SMART) e Bateria
echo.
echo %COR_SEC%  [NETRUNNING, SEGURANCA E PRIVACIDADE]%RST%
echo   %COR_PRI%11.%RST% Reset Completo de Rede e DNS (Fugir da NetWatch)
echo   %COR_PRI%12.%RST% Criar Ponto de Restauracao (Backup de Engrama / Mikoshi)
echo   %COR_PRI%13.%RST% Backup da Lista de Programas (Winget Export / Datashard)
echo   %CYN%17.%RST% Backup de Navegadores (Favoritos, Senhas e Perfis)
echo   %MAG%14.%RST% Barreira Blackwall: Malware, Backdoors, ngrok, Usuarios e Scans
echo   %MAG%15.%RST% Modo Fantasma: Auditoria Interativa de Telemetria (Desativar/Reativar)
echo   %MAG%16.%RST% Overclock Neural: Otimizacao + Limpeza Regedit/%%APPDATA%% (Apps Removidos)
echo.
echo %COR_SEC%  [SEGURANCA DE CELULARES ANDROID E IPHONE]%RST%
echo   %CYN%18.%RST% Auditoria Mobile: Apps Nocivos, Malware/Botnets, Arquivos e Permissoes
echo.
echo %COR_SEC%  [CRIPTOGRAFIA E COFRE DE DISCOS]%RST%
echo   %YLW%19.%RST% Criptografar Pen Drives e Unidades de Disco (BitLocker + VeraCrypt)
echo.
echo %COR_SEC%  [SEGURANCA ONLINE E VAZAMENTO DE DADOS]%RST%
echo   %CYN%20.%RST% Auditoria de Vazamentos: Senhas (k-Anonymity), E-mails e Blindagem
echo.
echo %COR_SEC%  [ATUALIZACOES DO CYBERDECK]%RST%
echo   %GRN%21.%RST% Central de Atualizacoes (Baixar Update / Ver O Que Mudou)
echo.
echo %COR_SEC%  [PROTOCOLOS ESPECIAIS]%RST%
echo   %YLW%99.%RST% Executar Manutencao Basica (Opcoes 1 + 4 + 8)
echo   %GRY%88.%RST% Trocar de Corporacao / Faccao
echo    %RED%0.%RST% Desconectar do CyberDeck (Sair)
echo %COR_PRI%========================================================================%RST%
echo %CYN%  PT ^| Criador do CYBER-DECK: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %CYN%  EN ^| CYBER-DECK Creator: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %CYN%  ES ^| Creador del CYBER-DECK: Adonis Peixoto (Dante3147) ^| Discord: dante_3147 ^| Email: suporte@dante3147.anonaddy.me%RST%
echo %GRY%------------------------------------------------------------------------%RST%
echo %RED%  PT ^| !! COMERCIALIZACAO ESTRITAMENTE PROIBIDA ^| Apenas para uso pessoal e educacional%RST%
echo %RED%  EN ^| !! COMMERCIAL USE STRICTLY PROHIBITED ^| For personal and educational use only%RST%
echo %RED%  ES ^| !! USO COMERCIAL ESTRICTAMENTE PROHIBIDO ^| Solo para uso personal y educativo%RST%
echo %COR_PRI%========================================================================%RST%
set "opcao="
set /p "opcao=%WHT%Escolha uma opcao e pressione ENTER: %RST%"

if "%opcao%"=="1" goto OP1
if "%opcao%"=="2" goto OP2
if "%opcao%"=="3" goto OP16
if "%opcao%"=="4" goto OP3
if "%opcao%"=="5" goto OP4
if "%opcao%"=="6" goto OP5
if "%opcao%"=="7" goto OP6
if "%opcao%"=="8" goto OP7
if "%opcao%"=="9" goto OP8
if "%opcao%"=="10" goto OP9
if "%opcao%"=="11" goto OP10
if "%opcao%"=="12" goto OP11
if "%opcao%"=="13" goto OP12
if "%opcao%"=="14" goto OP13
if "%opcao%"=="15" goto OP14
if "%opcao%"=="16" goto OP15
if "%opcao%"=="17" goto OP17
if "%opcao%"=="18" goto OP18
if "%opcao%"=="19" goto OP19
if "%opcao%"=="20" goto OP20
if "%opcao%"=="21" goto OP21
if /i "%opcao%"=="upd" goto OP21
if /i "%opcao%"=="log" goto OP21_LOG
if "%opcao%"=="99" goto OP99
if "%opcao%"=="88" goto SELECAO_CORPO
if "%opcao%"=="0" goto SAIR

echo.
echo %RED%[ERRO DE PROTOCOLO]%RST% Comando invalido.
echo %CYN%  [SKIPPY // CP2077]: "Erro de usuario detectado. Tente um numero do menu, choom."%RST%
timeout /t 2 >nul
goto MENU

:OP1
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [01] ATUALIZACAO DE IMPLANTES DE SOFTWARE (WINGET UPGRADE ALL)%RST%
echo %COR_PRI%========================================================================%RST%
echo %GRN%  [VIKTOR VEKTOR // Cyberpunk 2077]:%RST%
echo %WHT%  "Se vai rodar cromo no limite, garanta que todo firmware esteja em dia."%RST%
echo %YLW%  [FALCO // Edgerunners 1]:%RST%
echo %WHT%  "Puxando todas as atualizacoes direto pelo Winget. Segura firme."%RST%
echo.
winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
set "ERR_OP=%errorlevel%"
echo.
if "%ERR_OP%"=="0" goto OP1_OK
echo %YLW%  [AVISO/ERRO - Codigo %ERR_OP%] Alguns pacotes nao puderam ser atualizados ou ja estao atualizados.%RST%
echo %MAG%  [PILAR // Edgerunners 1]: "Eita, algum programa travou ou ja estava na ultima versao."%RST%
echo %GRN%  [D // Edgerunners 2]: "Se algum app ficou aberto, fecha ele e tenta de novo depois."%RST%
goto OP1_END
:OP1_OK
echo %GRN%  [OK] Todos os pacotes verificados e atualizados.%RST%
echo %CYN%  [V // Cyberpunk 2077]: "Tudo liso, Vik. Nenhum implante desatualizado."%RST%
:OP1_END
echo.
pause
goto MENU

:OP2
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
goto MENU

:OP3
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
goto MENU

:OP4
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [05] REPARO NEURAL DO WINDOWS (DISM + SFC - ANTI-CIBERPSICOSE)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [WEAK "KING" KINGSLEY // Edgerunners 2]:%RST%
echo %WHT%  "Cuidado com a ciberpsicose no sistema. Vamos estabilizar a imagem do Windows."%RST%
echo.
echo %CYN%[1/2] Executando DISM /RestoreHealth (Pode levar alguns minutos)...%RST%
echo %RED%  [MAINE // Edgerunners 1]: "Aguenta firme, isso demora um pouco mas segura a barra."%RST%
DISM /Online /Cleanup-Image /RestoreHealth
set "ERR_DISM=%errorlevel%"
if "%ERR_DISM%" NEQ "0" (
    echo %RED%  [ERRO NO DISM - Codigo %ERR_DISM%]%RST%
    echo %MAG%  [DOC // Ripperdoc - Edgerunners 1]: "O DISM engasgou. Sem internet ou imagem corrompida demais."%RST%
)

echo.
echo %CYN%[2/2] Executando SFC /scannow...%RST%
echo %WHT%  [GORO TAKEMURA // Cyberpunk 2077]: "Disciplina e precisao. Verificando cada arquivo critico."%RST%
sfc /scannow
set "ERR_SFC=%errorlevel%"
echo.
if "%ERR_SFC%"=="0" goto SFC_OK
echo %YLW%  [AVISO/ERRO NO SFC - Codigo %ERR_SFC%]%RST%
echo %GRN%  [VIKTOR VEKTOR // Cyberpunk 2077]: "Alguns arquivos precisaram de reparo pesado. Reinicie o PC e rode de novo."%RST%
goto SFC_END
:SFC_OK
echo %GRN%  [OK] Integridade neural restaurada.%RST%
echo %GRN%  [DORIO // Edgerunners 1]: "Sistema firme de novo. Sem sinais de falha."%RST%
:SFC_END
echo.
pause
goto MENU

:OP5
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
goto MENU

:OP6
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [07] LIMPEZA DE CACHE DE SHADERS (DIRECTX / NVIDIA / AMD)%RST%
echo %COR_PRI%========================================================================%RST%
echo %RED%  [TALIA // MAELSTROM - Edgerunners 2]:%RST%
echo %WHT%  "Shaders corrompidos causam travadas feias. Vamos zerar esse cache."%RST%
echo.
echo %CYN%  [JUDY ALVAREZ // Cyberpunk 2077]: "Limpando DirectX, NVIDIA e AMD. Os jogos recriam limpo depois."%RST%
del /s /f /q "%LOCALAPPDATA%\D3DSCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA\DXCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA\GLCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\AMD\DxCache\*.*" >nul 2>&1
del /s /f /q "%LOCALAPPDATA%\AMD\GLCache\*.*" >nul 2>&1
echo.
echo %GRN%  [OK] Caches de shaders limpos.%RST%
echo %YLW%  [DAVID MARTINEZ // Edgerunners 1]: "Na proxima vez que abrir o jogo, ele compila tudo zerado."%RST%
echo %GRY%  [SKIPPY // Arma Inteligente - CP2077]: "Bum-bum-bi-dam. Se algum arquivo estava aberto, foi mantido."%RST%
echo.
pause
goto MENU

:OP7
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
goto MENU

:OP8
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [09] MODO SANDEVISTAN (PLANO DE ENERGIA: DESEMPENHO MAXIMO)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [DAVID MARTINEZ // Edgerunners 1]:%RST%
echo %WHT%  "Eu sou construido diferente. Ativando o plano de Desempenho Maximo."%RST%
echo.
powershell -NoProfile -Command "$out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-String; if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') { $guid = $matches[1]; powercfg /setactive $guid; Write-Host ('[SANDEVISTAN ATIVO] Desempenho Maximo ativado. GUID: ' + $guid) -ForegroundColor Green; exit 0 } else { Write-Host '[AVISO] Plano oculto bloqueado nesta edicao. Ativando Alto Desempenho...' -ForegroundColor Yellow; powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; exit 1 }"
if %errorlevel%==0 goto SAND_OK
echo %MAG%  [DOC // Edgerunners 1]: "Seu Windows bloqueou o Desempenho Maximo, mas ja puxei o Alto Desempenho."%RST%
echo %YLW%  [WEAK "KING" KINGSLEY // Edgerunners 2]: "Mesmo assim voce ja ganhou resposta rapida."%RST%
goto SAND_END
:SAND_OK
echo %RED%  [MAINE // Edgerunners 1]: "Aceleracao total ligada. So fica de olho na temperatura."%RST%
echo %RED%  [ADAM SMASHER // CP2077]: "Um implante rudimentar... mas eficiente."%RST%
:SAND_END
echo.
echo %CYN%Plano de energia ativo atualmente:%RST%
powercfg /getactivescheme
echo.
pause
goto MENU

:OP9
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
powershell -NoProfile -Command "if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $dt = Get-Date -Format 'dd-MM-yyyy'; $desk = Join-Path $env:USERPROFILE ('Desktop\DADOS\BACKUP - ' + $dt + '\RELATORIOS_HARDWARE'); if (-not (Test-Path $desk)) { New-Item -ItemType Directory -Path $desk -Force | Out-Null }; $rep = Join-Path $desk 'relatorio_bateria.html'; powercfg /batteryreport /output $rep | Out-Null; $d = Join-Path '%~dp0' ('DADOS\BACKUP - ' + $dt + '\RELATORIOS_HARDWARE'); if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }; Copy-Item $rep (Join-Path $d 'relatorio_bateria.html') -Force -ErrorAction SilentlyContinue; Write-Host ('[OK] Relatorio salvo em: ' + $rep) -ForegroundColor Green; Write-Host ('[OK] Copia no Projeto: ' + $d) -ForegroundColor Cyan; Start-Process $rep } else { Write-Host '[INFO] Nenhuma bateria detectada (Sistema Desktop ligado na tomada).' -ForegroundColor Yellow }"
echo.
pause
goto MENU

:OP10
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [11] RESET COMPLETO DE REDE E DNS (FUGIR DA NETWATCH)%RST%
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [CAPRI // Edgerunners 2]: "Quebrando rastreamento e limpando a tabela DNS."%RST%
echo %GRN%  [D // Edgerunners 2]: "Trocando de rota antes que o sinal seja interceptado."%RST%
echo.
echo %WHT%  [SOLOMON REED // FIA - CP2077]: "Executando flushdns, renew, ip reset e winsock."%RST%
ipconfig /release >nul 2>&1
ipconfig /flushdns
ipconfig /renew >nul 2>&1
netsh int ip reset
netsh winsock reset
set "ERR_NET=%errorlevel%"
echo.
if "%ERR_NET%"=="0" goto NET_OK
echo %RED%  [ERRO - Codigo %ERR_NET%] Algum comando de rede retornou falha.%RST%
echo %MAG%  [KIWI // Edgerunners 1]: "Verifique se o cabo de rede ou Wi-Fi esta ativo e tente novamente."%RST%
goto NET_END
:NET_OK
echo %GRN%  [OK] Pilha de rede e DNS resetados. Reinicie o PC para aplicar 100%%.%RST%
echo %YLW%  [ROGUE AMENDIARES // Afterlife - CP2077]: "Conexao limpa. Bom trabalho."%RST%
:NET_END
echo.
pause
goto MENU

:OP11
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
goto MENU

:OP12
cls
echo %COR_PRI%========================================================================%RST%
echo %CYN%  [13] BACKUP DA LISTA DE PROGRAMAS (DATASHARD / WINGET EXPORT)%RST%
echo %COR_PRI%========================================================================%RST%
echo %YLW%  [REGINA JONES // Fixer - Cyberpunk 2077]: "Exportando todos os seus programas para um Datashard."%RST%
echo %GRY%  [MR. HANDS // Cyberpunk 2077]: "Ideal para restaurar tudo num clique apos formatar."%RST%
echo.
for /f "usebackq delims=" %%D in (`powershell -NoProfile -Command "Get-Date -Format 'dd-MM-yyyy'"`) do set "DATA_BK=%%D"
set "PASTA_DESK_BK=%USERPROFILE%\Desktop\DADOS\BACKUP - !DATA_BK!\BACKUPS-PROGRAMAS"
set "PASTA_PROJ_BK=%~dp0DADOS\BACKUP - !DATA_BK!\BACKUPS-PROGRAMAS"
if not exist "!PASTA_DESK_BK!" mkdir "!PASTA_DESK_BK!"
winget export -o "!PASTA_DESK_BK!\meus_programas.json" --accept-source-agreements
if !errorlevel! neq 0 (
    echo %RED%  [WAKAKO OKADA // CP2077]: "Erro ao exportar. Confirme se o Winget esta atualizado."%RST%
    pause
    goto MENU
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
goto MENU

:OP13
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [14] BARREIRA BLACKWALL v9: MALWARE, BACKDOORS, NGROK E USUARIOS%RST%
echo %MAG%========================================================================%RST%
if exist "%~dp0scripts_individuais_powershell\14_scan_malware_ransomware.ps1" goto OP13_RUN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\14_scan_malware_ransomware.ps1 nao encontrado.%RST%
echo %YLW%  [ROGUE // CP2077]: "Mantenha a pasta scripts_individuais_powershell junto com o painel."%RST%
pause
goto MENU
:OP13_RUN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\14_scan_malware_ransomware.ps1"
goto MENU

:OP14
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
goto MENU

:OP15
cls
echo %MAG%========================================================================%RST%
echo %MAG%  [16] OVERCLOCK NEURAL // OTIMIZACAO + LIMPEZA REGEDIT E %%APPDATA%%%RST%
echo %MAG%========================================================================%RST%
echo %YLW%  [DAVID MARTINEZ // Edgerunners 1]: "Escolha calibrar o Windows ou limpar rastros de apps desinstalados."%RST%
echo.
echo   %MAG%[1]%RST% Auditoria Interativa de Otimizacao (7 Etapas: Game Mode, DVR, RAM, Menus, P2P, SSD)
echo   %CYN%[2]%RST% Limpeza Profunda de Registros Velhos (Regedit) e Pastas Orfas (%%APPDATA%% / Windows)
echo   %GRY%[0]%RST% Voltar ao Menu Principal
echo %MAG%========================================================================%RST%
set "opt16="
set /p "opt16=%WHT%Escolha [0-2]: %RST%"
if "%opt16%"=="0" goto MENU
if "%opt16%"=="2" goto OP15_ORPHAN
if not "%opt16%"=="1" goto OP15
goto OP15_ETAPAS

:OP15_ORPHAN
if exist "%~dp0scripts_individuais_powershell\16_otimizacao_windows.ps1" goto OP15_ORPHAN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\16_otimizacao_windows.ps1 nao encontrado.%RST%
pause
goto OP15
:OP15_ORPHAN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\16_otimizacao_windows.ps1" -OnlyOrphanClean
goto OP15

:OP15_ETAPAS
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
goto MENU

:OP16
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
goto MENU

:OP17
cls
echo %CYN%========================================================================%RST%
echo %CYN%  [17] BACKUP DE DADOS DOS NAVEGADORES (FAVORITOS, PERFIS E SENHAS)%RST%
echo %CYN%========================================================================%RST%
if exist "%~dp0scripts_individuais_powershell\17_backup_navegadores.ps1" goto OP17_RUN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\17_backup_navegadores.ps1 nao encontrado.%RST%
echo %YLW%  [ROGUE // CP2077]: "Mantenha a pasta scripts_individuais_powershell junto com o painel."%RST%
pause
goto MENU
:OP17_RUN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\17_backup_navegadores.ps1"
goto MENU

:OP18
cls
echo %CYN%========================================================================%RST%
echo %CYN%  [18] SEGURANCA DE CELULARES ANDROID E IPHONE%RST%
echo %CYN%========================================================================%RST%
if exist "%~dp0scripts_individuais_powershell\18_seguranca_android_iphone.ps1" goto OP18_RUN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\18_seguranca_android_iphone.ps1 nao encontrado.%RST%
echo %YLW%  [ROGUE // CP2077]: "Mantenha a pasta scripts_individuais_powershell junto com o painel."%RST%
pause
goto MENU
:OP18_RUN_PS
for /f "tokens=2 delims==" %%P in ('wmic process where "name='cmd.exe' and commandline like '%%18_seguranca_android_iphone%%'" get processid /value 2^>nul') do set "SELF_CMD_PID=%%P"
if not defined SELF_CMD_PID for /f "tokens=2" %%P in ('tasklist /fi "imagename eq cmd.exe" /fo list 2^>nul ^| findstr /i "PID:"') do set "SELF_CMD_PID=%%P"
if defined SELF_CMD_PID start "" /min powershell -NoProfile -WindowStyle Hidden -Command "$parentPid = %SELF_CMD_PID%; while (Get-Process -Id $parentPid -ErrorAction SilentlyContinue) { Start-Sleep -Milliseconds 700 }; foreach ($n in @('adb','fastboot','idevice_id','ideviceinfo','ideviceinstaller','idevicepair','idevicediagnostics','idevicesyslog','idevicebackup2','iproxy','usbmuxd')) { try { taskkill.exe /F /IM ($n + '.exe') /T 2>$null } catch {} }"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\18_seguranca_android_iphone.ps1"
taskkill /F /IM adb.exe /T >nul 2>&1
taskkill /F /IM fastboot.exe /T >nul 2>&1
taskkill /F /IM idevice_id.exe /T >nul 2>&1
taskkill /F /IM ideviceinfo.exe /T >nul 2>&1
taskkill /F /IM ideviceinstaller.exe /T >nul 2>&1
taskkill /F /IM idevicepair.exe /T >nul 2>&1
taskkill /F /IM idevicediagnostics.exe /T >nul 2>&1
taskkill /F /IM idevicesyslog.exe /T >nul 2>&1
taskkill /F /IM idevicebackup2.exe /T >nul 2>&1
taskkill /F /IM iproxy.exe /T >nul 2>&1
taskkill /F /IM usbmuxd.exe /T >nul 2>&1
goto MENU

:OP19
cls
echo %YLW%========================================================================%RST%
echo %YLW%  [19] CRIPTOGRAFIA DE PEN DRIVES E UNIDADES DE DISCO%RST%
echo %YLW%========================================================================%RST%
if exist "%~dp0scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1" goto OP19_RUN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1 nao encontrado.%RST%
echo %YLW%  [ROGUE // CP2077]: "Mantenha a pasta scripts_individuais_powershell junto com o painel."%RST%
pause
goto MENU
:OP19_RUN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\19_criptografia_discos_pendrives.ps1"
goto MENU

:OP20
cls
echo %CYN%========================================================================%RST%
echo %CYN%  [20] SEGURANCA ONLINE: AUDITORIA DE VAZAMENTOS (100%% GRATUITO)%RST%
echo %CYN%========================================================================%RST%
if exist "%~dp0scripts_individuais_powershell\20_vazamento_dados_online.ps1" goto OP20_RUN_PS
echo %RED%  [ERRO] Arquivo auxiliar scripts_individuais_powershell\20_vazamento_dados_online.ps1 nao encontrado.%RST%
echo %YLW%  [ROGUE // CP2077]: "Mantenha a pasta scripts_individuais_powershell junto com o painel."%RST%
pause
goto MENU
:OP20_RUN_PS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts_individuais_powershell\20_vazamento_dados_online.ps1"
goto MENU

:OP21
cls
echo %YLW%========================================================================%RST%
echo %CYN%  [CENTRAL DE ATUALIZACOES // CMD NATIVE ENGINE]%RST%
echo %MAG%  [SONGBIRD // CP2077]: "Consultando status no mainframe do GitHub..."%RST%
echo %YLW%========================================================================%RST%
echo.
set "NOVA_VERSAO="
for /f "usebackq delims=" %%v in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $u = (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Dante3147/CYBER-DECK/main/version.json' -TimeoutSec 5 -ErrorAction Stop).version; if ([version]($u -replace '[^0-9.]','') -gt [version]('36.0' -replace '[^0-9.]','')) { Write-Output $u } } catch {}" 2^>nul`) do (
    set "NOVA_VERSAO=%%v"
)

echo %CYN%  Versao Local Instalada : v36.0%RST%
if defined NOVA_VERSAO (
    echo %GRN%  Versao no GitHub       : v!NOVA_VERSAO! [ATUALIZACAO DISPONIVEL!]%RST%
) else (
    echo %GRY%  Versao no GitHub       : Sistema atualizado ou offline%RST%
)
echo.
echo %YLW%========================================================================%RST%
echo %WHT%  OPCOES DE ATUALIZACAO:%RST%
echo    %GRN%[1] Baixar e Instalar Atualizacao Agora (Permanece no CMD)%RST%
echo    %YLW%[2] Ver o que foi alterado / Registros de Atualizacao (Changelog)%RST%
echo    %GRY%[0] Voltar ao Menu Principal%RST%
echo %YLW%========================================================================%RST%
echo.
set /p "OP_UPD=Escolha uma opcao [0, 1 ou 2]: "
if "!OP_UPD!"=="0" goto MENU
if "!OP_UPD!"=="1" goto ATUALIZAR_BAT_DIRETO
if "!OP_UPD!"=="2" goto OP21_LOG
echo %RED%  [SKIPPY]: "Opcao invalida, choom!"%RST%
timeout /t 1 >nul
goto OP21

:OP21_LOG
cls
echo %YLW%========================================================================%RST%
echo %CYN%  [LOG] REGISTROS DE ATUALIZACAO // HISTORICO DE VERSOES (CMD)%RST%
echo %GRN%  [VIKTOR VEKTOR // CP2077]: "Aqui estao todos os implantes e melhorias documentados:"%RST%
echo %YLW%========================================================================%RST%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $r = (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/Dante3147/CYBER-DECK/main/version.json' -TimeoutSec 5 -ErrorAction Stop); Write-Host ('  Versao Nuvem: v' + $r.version + ' (' + $r.release_date + ')') -ForegroundColor Green; Write-Host ''; foreach ($e in $r.changelog) { Write-Host ('  [ v' + $e.version + ' ] - Data: ' + $e.date) -ForegroundColor Cyan; foreach ($c in $e.changes) { Write-Host ('    + ' + $c) -ForegroundColor White }; Write-Host '' } } catch { Write-Host '  [AVISO] Sem conexao com o GitHub. Exibindo versao local: v36.0' -ForegroundColor Yellow } }"
echo %YLW%========================================================================%RST%
pause
goto OP21

:ATUALIZAR_BAT_DIRETO
cls
echo %MAG%========================================================================%RST%
echo %CYN%  [AUTO-UPDATE CMD] ATUALIZANDO CYBERDECK OS%RST%
echo %MAG%========================================================================%RST%
echo %MAG%  [SONGBIRD // CP2077]: "Baixando arquivos do repositorio oficial..."%RST%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $tmp = Join-Path $env:TEMP ('CyberDeck_CMD_' + (Get-Random)); New-Item -ItemType Directory -Path $tmp -Force | Out-Null; $zip = Join-Path $tmp 'update.zip'; Write-Host '  [1/3] Baixando arquivo ZIP do GitHub...' -ForegroundColor Cyan; (New-Object System.Net.WebClient).DownloadFile('https://github.com/Dante3147/CYBER-DECK/archive/refs/heads/main.zip', $zip); Write-Host '  [2/3] Extraindo arquivos...' -ForegroundColor Cyan; Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp 'ext') -Force; Write-Host '  [3/3] Aplicando atualizacao sobre a pasta...' -ForegroundColor Cyan; $ext = Get-ChildItem (Join-Path $tmp 'ext') -Directory | Select-Object -First 1; $prot = @('DADOS','ADB ANDROID','LIBIMOBILEDEVICE IPHONE','VERACRYPT PORTATIL'); Get-ChildItem -Path $ext.FullName -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object { $rel = $_.FullName.Substring($ext.FullName.Length + 1); $skip = $false; foreach ($p in $prot) { if ($rel -like ($p + '*')) { $skip = $true; break } }; if (-not $skip) { $dest = Join-Path '%~dp0' $rel; $parent = Split-Path $dest -Parent; if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }; Copy-Item -Path $_.FullName -Destination $dest -Force } }; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; Write-Host '  [OK] Todos os arquivos (.bat e .ps1) foram atualizados!' -ForegroundColor Green }"
echo.
echo %GRN%========================================================================%RST%
echo %GRN%  [SUCESSO] CYBERDECK OS ATUALIZADO COM SUCESSO!%RST%
echo %CYN%  [VIKTOR VEKTOR // CP2077]: "Reiniciando o Painel .bat agora..."%RST%
echo %GRN%========================================================================%RST%
timeout /t 3 >nul
start "" "%~f0"
exit /b

:OP99
cls
echo %YLW%========================================================================%RST%
echo %YLW%  [99] MANUTENCAO BASICA COMPLETA (PROTOCOLO AFTERLIFE: 1 + 4 + 8)%RST%
echo %YLW%========================================================================%RST%
echo %CYN%  [REBECCA // Edgerunners 1]: "Bora resolver isso rapido antes de ir pra Lua."%RST%
echo %MAG%  [LUCY // Edgerunners 1]: "Tres etapas diretas: Winget, Temp e Discos."%RST%
echo.
echo %CYN%[1/3] Atualizando programas via Winget...%RST%
echo %MAG%  [PILAR // Edgerunners 1]: "Puxando os updates da galera."%RST%
winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
if %errorlevel% neq 0 echo %YLW%  [SKIPPY]: "Alguns apps nao precisavam de update ou deram erro leve."%RST%

echo.
echo %CYN%[2/3] Limpando arquivos temporarios...%RST%
echo %GRN%  [D // Edgerunners 2]: "Apagando as pegadas do sistema."%RST%
del /s /f /q "%TEMP%\*.*" >nul 2>&1
for /d %%p in ("%TEMP%\*.*") do rmdir "%%p" /s /q >nul 2>&1
del /s /f /q "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%p in ("C:\Windows\Temp\*.*") do rmdir "%%p" /s /q >nul 2>&1

echo.
echo %CYN%[3/3] Otimizando discos (TRIM / Defrag)...%RST%
echo %YLW%  [PANAM PALMER // Cyberpunk 2077]: "Dando aquele trato final nos discos."%RST%
defrag /C /O /U /V
if %errorlevel% neq 0 echo %RED%  [ADAM SMASHER // CP2077]: "Falha ao otimizar alguma unidade. Verifique o disco."%RST%
echo.
echo %GRN%========================================================================%RST%
echo %GRN%  [MISSAO CUMPRIDA] MANUTENCAO BASICA CONCLUIDA%RST%
echo %YLW%  [JACKIE WELLES // CP2077]: "Aeh, mano. Tudo pronto pras grandes ligas."%RST%
echo %CYN%  [V // CP2077]: "Mandou bem, Jackie."%RST%
echo %GRN%========================================================================%RST%
pause
goto MENU

:SAIR
cls
taskkill /F /IM adb.exe /T >nul 2>&1
taskkill /F /IM fastboot.exe /T >nul 2>&1
taskkill /F /IM idevice_id.exe /T >nul 2>&1
taskkill /F /IM ideviceinfo.exe /T >nul 2>&1
taskkill /F /IM ideviceinstaller.exe /T >nul 2>&1
taskkill /F /IM idevicepair.exe /T >nul 2>&1
taskkill /F /IM idevicediagnostics.exe /T >nul 2>&1
taskkill /F /IM idevicesyslog.exe /T >nul 2>&1
taskkill /F /IM idevicebackup2.exe /T >nul 2>&1
taskkill /F /IM iproxy.exe /T >nul 2>&1
taskkill /F /IM usbmuxd.exe /T >nul 2>&1
echo %COR_PRI%========================================================================%RST%
echo %CYN%  DESCONECTANDO DO CYBERDECK E LIMPANDO PROCESSOS MOBILE...%RST%
echo %YLW%  [JACKIE WELLES // CP2077]: "Nos vemos nas grandes ligas, mano."%RST%
echo %MAG%  [MISTY OLSZEWSKI // CP2077]: "Que as cartas te guiem em Night City."%RST%
echo %COR_PRI%========================================================================%RST%
timeout /t 2 >nul
exit /b
