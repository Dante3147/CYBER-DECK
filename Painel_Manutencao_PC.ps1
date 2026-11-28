# ============================================================================
# CYBERDECK OS v36.0 // NIGHT CITY EDITION (POWERSHELL)
# ============================================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ============================================================================
# MODULO: CENTRAL DE ATUALIZACOES DO CYBERDECK (GITHUB)
# ============================================================================
$CYBERDECK_VERSION_LOCAL = "36.0"
$localJsonPath = Join-Path $PSScriptRoot "version.json"
if (Test-Path $localJsonPath) {
    try {
        $localJ = Get-Content $localJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($localJ.version) { $CYBERDECK_VERSION_LOCAL = $localJ.version }
    } catch {}
}
$CYBERDECK_REPO_RAW      = "https://raw.githubusercontent.com/Dante3147/CYBER-DECK/main/version.json"
$CYBERDECK_ZIP_URL       = "https://github.com/Dante3147/CYBER-DECK/archive/refs/heads/main.zip"
$CYBERDECK_PASTA_RAIZ    = $PSScriptRoot

function Get-RemoteVersion {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $resp = Invoke-WebRequest -Uri $CYBERDECK_REPO_RAW -UseBasicParsing -TimeoutSec 6 -ErrorAction Stop
        return ($resp.Content | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Compare-Versions {
    param([string]$local, [string]$remote)
    try {
        $l = [version]($local  -replace '[^0-9.]','')
        $r = [version]($remote -replace '[^0-9.]','')
        return $r.CompareTo($l)   # > 0 = tem update
    } catch { return 0 }
}

function Show-UpdateChangelog {
    param($remoto)
    $versaoRemota = $remoto.version
    $entrada = $remoto.changelog | Where-Object { $_.version -eq $versaoRemota } | Select-Object -First 1
    if ($entrada) {
        Write-Host ""
        Write-Host "  ================================================================" -ForegroundColor Cyan
        Write-Host "  NOVIDADES DA v$versaoRemota ($($remoto.release_date)):" -ForegroundColor Cyan
        Write-Host "  ================================================================" -ForegroundColor Cyan
        foreach ($linha in $entrada.changes) {
            Write-Host "    >> $linha" -ForegroundColor White
        }
        Write-Host ""
    }
}

function Invoke-AutoUpdate {
    param($remoto)

    if ($null -eq $remoto) {
        $remoto = Get-RemoteVersion
    }

    $versaoRemota = if ($remoto -and $remoto.version) { $remoto.version } else { "Mais Recente" }
    Clear-Host
    Show-BootBanner "[AUTO-UPDATE] INSTALANDO ATUALIZACAO v$versaoRemota"
    Write-Host '  [SONGBIRD // CP2077]: "Iniciando download do novo firmware do repositorio..."' -ForegroundColor Magenta
    Write-Host '  [DAVID MARTINEZ // Edgerunners]: "Sandevistan ligado. Baixando em alta velocidade."' -ForegroundColor Yellow
    Write-Host ""

    if ($remoto) {
        Show-UpdateChangelog -remoto $remoto
    }

    # --- Pasta temporaria para o download ---
    $tmpDir  = Join-Path $env:TEMP "CyberDeck_Update_$(Get-Random)"
    $zipTemp = Join-Path $tmpDir "cyberdeck_update.zip"
    $extDir  = Join-Path $tmpDir "extracted"
    New-Item -ItemType Directory -Path $tmpDir  -Force | Out-Null
    New-Item -ItemType Directory -Path $extDir  -Force | Out-Null

    # --- Download com barra de progresso e porcentagem ---
    try {
        Write-Host "  [1/3] Conectando ao GitHub para baixar o pacote..." -ForegroundColor Cyan
        Write-Host "  Fonte: $CYBERDECK_ZIP_URL" -ForegroundColor DarkGray
        Write-Host ""

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $req = [System.Net.HttpWebRequest]::Create($CYBERDECK_ZIP_URL)
        $req.UserAgent = "CyberDeck-OS-AutoUpdate/$CYBERDECK_VERSION_LOCAL"
        $req.AllowAutoRedirect = $true
        $req.Timeout = 60000

        $resp       = $req.GetResponse()
        $totalBytes = [int64]$resp.ContentLength
        $inStream   = $resp.GetResponseStream()
        $outStream  = [System.IO.File]::Create($zipTemp)
        $buffer     = New-Object byte[] 65536
        $downloaded = [int64]0
        $lastPct    = -1
        $sw         = [System.Diagnostics.Stopwatch]::StartNew()
        $lastDrawMs = -200
        $spin       = @('|','/','-','\')
        $spinIdx    = 0

        if ($totalBytes -gt 0) {
            $totMB = [math]::Round($totalBytes / 1MB, 2)
            Write-Host ("`r  [--------------------]   0% | 0.00 / {0:N2} MB | Iniciando..." -f $totMB) -NoNewline -ForegroundColor Cyan
        }

        while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outStream.Write($buffer, 0, $read)
            $downloaded += $read
            $elapsedMs  = $sw.ElapsedMilliseconds

            if ($totalBytes -gt 0) {
                $pct = [int][math]::Floor(($downloaded * 100.0) / $totalBytes)
                if ($pct -gt 100) { $pct = 100 }
                if (($pct -ne $lastPct) -or (($elapsedMs - $lastDrawMs) -ge 150)) {
                    $lastPct    = $pct
                    $lastDrawMs = $elapsedMs
                    $filled = [int][math]::Floor($pct / 5)
                    if ($filled -gt 20) { $filled = 20 }
                    $bar    = ("#" * $filled) + ("-" * (20 - $filled))
                    $dlMB   = $downloaded / 1MB
                    $totMB  = $totalBytes / 1MB
                    $secs   = [math]::Max(0.1, $sw.Elapsed.TotalSeconds)
                    $spdMB  = ($downloaded / 1MB) / $secs
                    $spdStr = if ($spdMB -ge 1) { "{0:N2} MB/s" -f $spdMB } else { "{0:N0} KB/s" -f (($downloaded / 1KB) / $secs) }
                    Write-Host ("`r  [{0}] {1,3}% | {2:N2} / {3:N2} MB | {4}        " -f $bar, $pct, $dlMB, $totMB, $spdStr) -NoNewline -ForegroundColor Cyan
                }
            } else {
                if (($elapsedMs - $lastDrawMs) -ge 200) {
                    $lastDrawMs = $elapsedMs
                    $sp     = $spin[$spinIdx % $spin.Length]; $spinIdx++
                    $dlMB   = $downloaded / 1MB
                    $secs   = [math]::Max(0.1, $sw.Elapsed.TotalSeconds)
                    $spdStr = "{0:N0} KB/s" -f (($downloaded / 1KB) / $secs)
                    Write-Host ("`r  [{0}] Baixando... {1:N2} MB recebidos | {2}        " -f $sp, $dlMB, $spdStr) -NoNewline -ForegroundColor Cyan
                }
            }
        }
        $sw.Stop()
        $finalMB = $downloaded / 1MB
        if ($totalBytes -gt 0) {
            Write-Host ("`r  [####################] 100% | {0:N2} / {0:N2} MB | Concluido!           " -f $finalMB) -ForegroundColor Green
        } else {
            Write-Host ("`r  [OK] Download concluido! Total: {0:N2} MB                     " -f $finalMB) -ForegroundColor Green
        }
        $outStream.Close(); $outStream.Dispose()
        $inStream.Close();  $inStream.Dispose()
        $resp.Close()

    } catch {
        Write-Host "`n  [ERRO] Falha no download: $_" -ForegroundColor Red
        Write-Host '  [JOHNNY SILVERHAND]: "Sem conexao ou GitHub fora do ar. Tenta mais tarde."' -ForegroundColor Yellow
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
        Pause-Cyber
        return
    }

    # --- Extrair ZIP ---
    Write-Host ""
    Write-Host "  [2/3] Extraindo arquivos da nova versao..." -ForegroundColor Cyan
    try {
        $oldPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Expand-Archive -Path $zipTemp -DestinationPath $extDir -Force
        $ProgressPreference = $oldPref
        Write-Host "  [OK] Extracao concluida." -ForegroundColor Green
    } catch {
        Write-Host "  [ERRO] Falha na extracao: $_" -ForegroundColor Red
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
        Pause-Cyber
        return
    }

    # --- Copiar arquivos novos (preservando pastas protegidas) ---
    Write-Host ""
    Write-Host "  [3/3] Aplicando atualizacao sobre a pasta atual..." -ForegroundColor Cyan

    $extracted = Get-ChildItem -Path $extDir -Directory | Select-Object -First 1
    if (-not $extracted) {
        Write-Host "  [ERRO] Estrutura de pastas inesperada no ZIP." -ForegroundColor Red
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue }
        Pause-Cyber
        return
    }

    $protegidos = @('DADOS', 'ADB ANDROID', 'LIBIMOBILEDEVICE IPHONE', 'VERACRYPT PORTATIL')
    $arquivosNovos = Get-ChildItem -Path $extracted.FullName -Recurse | Where-Object { -not $_.PSIsContainer }
    $copiados = 0

    foreach ($arq in $arquivosNovos) {
        $rel  = $arq.FullName.Substring($extracted.FullName.Length + 1)
        $prot = $false
        foreach ($p in $protegidos) {
            if ($rel -like "$p*") { $prot = $true; break }
        }
        if ($prot) { continue }

        $destino = Join-Path $CYBERDECK_PASTA_RAIZ $rel
        $pastaDestino = Split-Path $destino -Parent
        if (-not (Test-Path $pastaDestino)) { New-Item -ItemType Directory -Path $pastaDestino -Force | Out-Null }

        try {
            Copy-Item -Path $arq.FullName -Destination $destino -Force
            $copiados++
        } catch {
            Write-Host "  [AVISO] Nao foi possivel copiar: $rel" -ForegroundColor Yellow
        }
    }

    Write-Host "  [OK] $copiados arquivo(s) atualizados com sucesso." -ForegroundColor Green
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host "  CYBERDECK OS v$versaoRemota INSTALADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "  ================================================================" -ForegroundColor Green
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Todos os scripts (.bat e .ps1) foram atualizados com sucesso."' -ForegroundColor Green
    Write-Host ""
    Write-Host '  [CAPRI // Edgerunners 2]: "Reiniciando sessao do PowerShell..."' -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

function Invoke-CheckUpdateOnBoot {
    # Busca atualizacao silenciosamente ao iniciar (somente PowerShell, sem abrir .bat)
    $remoto = $null
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $wr = Invoke-WebRequest -Uri $CYBERDECK_REPO_RAW -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        $remoto = $wr.Content | ConvertFrom-Json
    } catch { return }

    if ($null -eq $remoto -or [string]::IsNullOrWhiteSpace($remoto.version)) { return }

    $cmp = Compare-Versions -local $CYBERDECK_VERSION_LOCAL -remote $remoto.version
    if ($cmp -gt 0) {
        Clear-Host
        Write-Host "========================================================================" -ForegroundColor Magenta
        Write-Host "  [ATUALIZACAO DISPONIVEL!] CYBERDECK OS v$($remoto.version)" -ForegroundColor Green
        Write-Host "  Versao Local: v$CYBERDECK_VERSION_LOCAL  >>  Versao Nuvem: v$($remoto.version) ($($remoto.release_date))" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Magenta
        Write-Host '  [SONGBIRD // CP2077]: "Novo firmware detectado na rede. Iniciando atualizacao automatica..."' -ForegroundColor Magenta
        Write-Host '  [DAVID MARTINEZ // Edgerunners]: "Baixando agora com barra de carregamento e porcentagem!"' -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Invoke-AutoUpdate -remoto $remoto
    }
}

function Show-ChangelogViewer {
    Clear-Host
    Show-BootBanner "[LOG] REGISTROS DE ATUALIZACAO // HISTORICO DE VERSOES"
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Aqui estao todos os implantes e melhorias documentados:"' -ForegroundColor Green
    Write-Host ""

    $remoto = Get-RemoteVersion
    if ($null -eq $remoto) {
        Write-Host "  [AVISO] Sem conexao com o GitHub. Exibindo informacoes locais." -ForegroundColor Yellow
        Write-Host "  Versao Local Instalada: v$CYBERDECK_VERSION_LOCAL" -ForegroundColor Cyan
        Pause-Cyber
        return
    }

    Write-Host "  Versao Local : v$CYBERDECK_VERSION_LOCAL" -ForegroundColor Cyan
    Write-Host "  Versao Nuvem : v$($remoto.version) ($($remoto.release_date))" -ForegroundColor Green
    Write-Host ""
    Write-Host "  ====================================================================" -ForegroundColor Yellow
    Write-Host "  HISTORICO COMPLETO DE MODIFICACOES" -ForegroundColor Yellow
    Write-Host "  ====================================================================" -ForegroundColor Yellow

    foreach ($entrada in $remoto.changelog) {
        Write-Host ""
        Write-Host "  [ v$($entrada.version) ]  -  Data: $($entrada.date)" -ForegroundColor Cyan
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        foreach ($linha in $entrada.changes) {
            Write-Host "    + $linha" -ForegroundColor White
        }
    }

    Write-Host ""
    Write-Host "  ====================================================================" -ForegroundColor Yellow
    Write-Host "  Repositorio oficial: https://github.com/Dante3147/CYBER-DECK" -ForegroundColor DarkGray
    Write-Host "  ====================================================================" -ForegroundColor Yellow
    Pause-Cyber
}

function Invoke-MenuAtualizacoes {
    while ($true) {
        Clear-Host
        Show-BootBanner "[21] CENTRAL DE ATUALIZACOES DO CYBERDECK (GITHUB)"
        Write-Host '  [SONGBIRD // CP2077]: "Verificando sinal com o repositorio oficial..."' -ForegroundColor Magenta
        Write-Host ""

        $remoto = Get-RemoteVersion
        $versaoNuvem = if ($remoto) { "v$($remoto.version) ($($remoto.release_date))" } else { "Offline / Nao foi possivel conectar" }
        $temUpdate = $false
        if ($remoto) {
            $cmp = Compare-Versions -local $CYBERDECK_VERSION_LOCAL -remote $remoto.version
            if ($cmp -gt 0) { $temUpdate = $true }
        }

        Write-Host "  Versao Local Instalada : v$CYBERDECK_VERSION_LOCAL" -ForegroundColor Cyan
        Write-Host "  Versao no GitHub       : $versaoNuvem" -ForegroundColor $(if ($temUpdate) { "Green" } else { "DarkGray" })

        if ($temUpdate) {
            Write-Host ""
            Write-Host "  [NOVA VERSAO DETECTADA!] Ha uma atualizacao pronta para instalar." -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "  [SISTEMA ATUALIZADO] Voce ja esta na versao mais recente." -ForegroundColor Green
        }

        Write-Host ""
        Write-Host "  ========================================================================" -ForegroundColor Cyan
        Write-Host "  OPCOES DE ATUALIZACAO:" -ForegroundColor White
        Write-Host "    [1] Baixar e Instalar Atualizacao (com barra de carregamento e %)" -ForegroundColor Green
        Write-Host "    [2] Ver o que foi alterado / Registros de Atualizacao (Changelog)" -ForegroundColor Yellow
        Write-Host "    [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "  ========================================================================" -ForegroundColor Cyan
        Write-Host ""

        $subOp = Read-Host "Escolha uma opcao [0, 1 ou 2]"
        if ($subOp -eq "0") { break }
        elseif ($subOp -eq "1") {
            Invoke-AutoUpdate -remoto $remoto
        }
        elseif ($subOp -eq "2") {
            Show-ChangelogViewer
        }
        else {
            Write-Host '  [SKIPPY]: "Opcao invalida, choom!"' -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}


function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Clear-Host
        Write-Host "========================================================================" -ForegroundColor Red
        Write-Host "  [ERRO DE ICE] ACESSO NEGADO PELA NETWATCH (POWERSHELL)" -ForegroundColor Red
        Write-Host "  [SOLOMON REED // FIA - Cyberpunk 2077]:" -ForegroundColor Cyan
        Write-Host '  "Sem privilegio de Administrador voce nao passa da Blackwall."' -ForegroundColor White
        Write-Host '  [SONGBIRD]: "Tentando elevar o PowerShell como Administrador agora..."' -ForegroundColor Magenta
        Write-Host "========================================================================" -ForegroundColor Red
        Start-Sleep -Seconds 2
        try {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
            exit
        } catch {
            Write-Host "  [JOHNNY SILVERHAND]: Elevacao cancelada. Abra o PowerShell como Administrador." -ForegroundColor Yellow
            Read-Host "Pressione ENTER para sair"
            exit 1
        }
    }
}

function Show-BootBanner {
    param([string]$Modulo = "CYBERDECK OS v36.0")
    $boots = @(
        @{ Char = "[CAPRI // Edgerunners 2]"; Col = "Cyan"; Msg = "Terminal PowerShell sincronizado. Todos os sensores neurais online." },
        @{ Char = "[SONGBIRD // Cyberpunk 2077]"; Col = "Magenta"; Msg = "Conexao PowerShell estabelecida. Blackwall estavel, pode comandar." },
        @{ Char = "[JOHNNY SILVERHAND // Cyberpunk 2077]"; Col = "Red"; Msg = "Acorda, Samurai. PowerShell aberto, hora de domar esse Windows." },
        @{ Char = "[DAVID MARTINEZ // Edgerunners 1]"; Col = "Yellow"; Msg = "PowerShell no talo! Modo Sandevistan pronto para execucao." },
        @{ Char = "[LUCY // Edgerunners 1]"; Col = "Cyan"; Msg = "Acesso root confirmado no PowerShell. Nenhum ICE no caminho." },
        @{ Char = "[WEAK 'KING' KINGSLEY // Edgerunners 2]"; Col = "Yellow"; Msg = "Sessao PowerShell iniciada. Vamos manter esse sistema estavel." },
        @{ Char = "[VIKTOR VEKTOR // Cyberpunk 2077]"; Col = "Green"; Msg = "Tudo pronto na bancada do PowerShell. Vamos cuidar desse hardware." },
        @{ Char = "[D // Snake Nation - Edgerunners 2]"; Col = "Green"; Msg = "PowerShell carregado fora do radar. Manda o comando." }
    )
    $pick = Get-Random -InputObject $boots
    Write-Host "========================================================================" -ForegroundColor Yellow
    Write-Host "  $Modulo // POWERSHELL NATIVE ENGINE" -ForegroundColor Cyan
    Write-Host "  $($pick.Char): `"$($pick.Msg)`"" -ForegroundColor $pick.Col
    Write-Host "========================================================================" -ForegroundColor Yellow
}

function Pause-Cyber {
    Write-Host ""
    Read-Host "Pressione ENTER para continuar" | Out-Null
}

function Invoke-Op01 {
    Clear-Host
    Show-BootBanner "[01] ATUALIZACAO DE PROGRAMAS (WINGET)"
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Garanta que todo firmware e software esteja em dia."' -ForegroundColor Green
    Write-Host '  [FALCO // Edgerunners 1]: "Puxando todos os updates pelo Winget. Segura firme."' -ForegroundColor Yellow
    Write-Host ""
    winget upgrade --all --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  [OK] Todos os pacotes verificados e atualizados." -ForegroundColor Green
        Write-Host '  [V // CP2077]: "Tudo liso, Vik. Nenhum implante desatualizado."' -ForegroundColor Cyan
    } else {
        Write-Host "`n  [AVISO/ERRO - Codigo $LASTEXITCODE] Alguns pacotes nao precisaram de update ou falharam." -ForegroundColor Yellow
        Write-Host '  [PILAR // Edgerunners 1]: "Eita, algum programa travou ou ja estava na ultima versao."' -ForegroundColor Magenta
        Write-Host '  [D // Edgerunners 2]: "Se algum app estava aberto, fecha ele e tenta de novo."' -ForegroundColor Green
    }
    Pause-Cyber
}

function Invoke-Op02 {
    Clear-Host
    Show-BootBanner "[02] VERIFICADOR E ATUALIZADOR DE GPU (OTICA KIROSHI)"
    Write-Host '  [ROMAN CARAX // Edgerunners 2]: "A imagem precisa estar nitida como cinema de verdade."' -ForegroundColor Magenta
    Write-Host ""
    $gpus = Get-CimInstance Win32_VideoController
    $gpus | Select-Object Name, DriverVersion, @{Name='DataDriver';Expression={if($_.DriverDate){$_.DriverDate.ToString('dd/MM/yyyy')}else{'N/A'}}} | Format-Table -AutoSize
    $names = ($gpus.Name -join ', ')
    if ($names -match "NVIDIA") {
        Write-Host "  [NVIDIA DETECTADA]" -ForegroundColor Green
        Write-Host '  [KERRY EURODYNE // CP2077]: "Placa verde na area. Abrindo NVIDIA App."' -ForegroundColor Yellow
        $nv = "C:\Program Files\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe"
        if (Test-Path $nv) { Start-Process $nv } else {
            winget install --id Nvidia.NVIDIAApp --accept-source-agreements --accept-package-agreements --silent
            if (Test-Path $nv) { Start-Process $nv } else {
                Write-Host '  [TALIA // Edgerunners 2]: "Winget falhou. Abrindo pagina oficial NVIDIA."' -ForegroundColor Red
                Start-Process "https://www.nvidia.com/pt-br/drivers/"
            }
        }
    } elseif ($names -match "AMD Radeon") {
        Write-Host "  [AMD DETECTADA]" -ForegroundColor Red
        Write-Host '  [REBECCA // Edgerunners 1]: "Radeon na maquina! Bora abrir o Adrenalin."' -ForegroundColor Cyan
        $amd = "C:\Program Files\AMD\CNext\CNext\RadeonSoftware.exe"
        if (Test-Path $amd) { Start-Process $amd } else { Start-Process "https://www.amd.com/pt/support/download/drivers.html" }
    } else {
        Write-Host '  [BRENDAN // CP2077]: "So encontrei video integrado por aqui. Tudo certo!"' -ForegroundColor Cyan
    }
    Pause-Cyber
}

function Invoke-Op03 {
    Clear-Host
    Show-BootBanner "[04] LIMPEZA DE RASTROS (ARQUIVOS TEMPORARIOS)"
    Write-Host '  [D // Edgerunners 2]: "Limpando os rastros antes que a MaxTac bata na porta."' -ForegroundColor Green
    Write-Host '  [KIWI // Edgerunners 1]: "Varrendo Temp do usuario..."' -ForegroundColor Magenta
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host '  [WAKAKO OKADA // CP2077]: "Varrendo C:\Windows\Temp..."' -ForegroundColor Yellow
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "`n  [OK] Limpeza concluida (arquivos em uso foram pulados com seguranca)." -ForegroundColor Green
    Write-Host '  [JACKIE WELLES // CP2077]: "Limpinho, mano. Pronto para o proximo servico."' -ForegroundColor Yellow
    Pause-Cyber
}

function Invoke-Op04 {
    Clear-Host
    Show-BootBanner "[05] REPARO NEURAL DO WINDOWS (DISM + SFC)"
    Write-Host '  [WEAK KING KINGSLEY // Edgerunners 2]: "Vamos estabilizar a imagem do Windows."' -ForegroundColor Yellow
    Write-Host '  [MAINE // Edgerunners 1]: "Rodando DISM /RestoreHealth... aguenta firme."' -ForegroundColor Red
    DISM /Online /Cleanup-Image /RestoreHealth
    if ($LASTEXITCODE -ne 0) { Write-Host '  [DOC // Edgerunners 1]: "DISM retornou aviso/erro. Verifique sua conexao."' -ForegroundColor Magenta }
    Write-Host "`n  [GORO TAKEMURA // CP2077]: `"Disciplina e precisao. Executando SFC /scannow.`"" -ForegroundColor White
    sfc /scannow
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n  [OK] Integridade neural restaurada." -ForegroundColor Green
        Write-Host '  [DORIO // Edgerunners 1]: "Sistema firme de novo."' -ForegroundColor Green
    } else {
        Write-Host '  [VIKTOR VEKTOR // CP2077]: "SFC fez reparos ou encontrou pendencias. Reinicie o PC."' -ForegroundColor Yellow
    }
    Pause-Cyber
}

function Invoke-Op05 {
    Clear-Host
    Show-BootBanner "[06] PURGA DE CACHE DO WINDOWS UPDATE"
    Write-Host '  [LUCY // Edgerunners 1]: "Purgando cache antigo do Windows Update."' -ForegroundColor Cyan
    Write-Host '  [SONGBIRD // CP2077]: "Parando wuauserv, bits e cryptsvc..."' -ForegroundColor Magenta
    Stop-Service wuauserv, bits, cryptsvc -Force -ErrorAction SilentlyContinue
    Write-Host '  [CAPRI // Edgerunners 2]: "Removendo downloads antigos..."' -ForegroundColor Cyan
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service cryptsvc, bits, wuauserv -ErrorAction SilentlyContinue
    Write-Host "`n  [OK] Cache limpo e servicos reiniciados." -ForegroundColor Green
    Write-Host '  [DELAMAIN // CP2077]: "Servicos operacionais, senhor."' -ForegroundColor Cyan
    Pause-Cyber
}

function Invoke-Op06 {
    Clear-Host
    Show-BootBanner "[07] LIMPEZA DE CACHE DE SHADERS"
    Write-Host '  [TALIA // Edgerunners 2]: "Zerando caches de shaders DirectX, NVIDIA e AMD."' -ForegroundColor Red
    Write-Host '  [JUDY ALVAREZ // CP2077]: "Os jogos recriam o cache limpo na proxima abertura."' -ForegroundColor Cyan
    $paths = @(
        "$env:LOCALAPPDATA\D3DSCache\*",
        "$env:LOCALAPPDATA\NVIDIA\DXCache\*",
        "$env:LOCALAPPDATA\NVIDIA\GLCache\*",
        "$env:LOCALAPPDATA\NVIDIA Corporation\NV_Cache\*",
        "$env:LOCALAPPDATA\AMD\DxCache\*",
        "$env:LOCALAPPDATA\AMD\GLCache\*"
    )
    foreach ($p in $paths) { Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Host "`n  [OK] Cache de shaders limpo." -ForegroundColor Green
    Write-Host '  [DAVID MARTINEZ // Edgerunners 1]: "Pronto pra rodar sem engasgos."' -ForegroundColor Yellow
    Pause-Cyber
}

function Invoke-Op07 {
    Clear-Host
    Show-BootBanner "[08] OTIMIZACAO INTELIGENTE DE DISCOS (TRIM / DEFRAG)"
    Write-Host '  [DELAMAIN // CP2077]: "Executando TRIM em SSDs e desfragmentacao em HDs."' -ForegroundColor Cyan
    defrag /C /O /U /V
    if ($LASTEXITCODE -eq 0) {
        Write-Host '  [PANAM PALMER // CP2077]: "Discos afinados! Agora essa maquina anda."' -ForegroundColor Yellow
    } else {
        Write-Host '  [ADAM SMASHER // CP2077]: "Falha em alguma unidade. Cheque se ha disco travado."' -ForegroundColor Red
    }
    Pause-Cyber
}

function Invoke-Op08 {
    Clear-Host
    Show-BootBanner "[09] MODO SANDEVISTAN (DESEMPENHO MAXIMO)"
    Write-Host '  [DAVID MARTINEZ // Edgerunners 1]: "Eu sou construido diferente! Ativando Desempenho Maximo."' -ForegroundColor Yellow
    $out = (powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1) | Out-String
    if ($out -match '([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
        $guid = $matches[1]
        powercfg /setactive $guid
        Write-Host "  [SANDEVISTAN ATIVO] Desempenho Maximo ativado! GUID: $guid" -ForegroundColor Green
        Write-Host '  [MAINE // Edgerunners 1]: "Aceleracao total ligada. Fica de olho na temperatura."' -ForegroundColor Red
    } else {
        Write-Host "  [AVISO] Plano oculto bloqueado. Ativando Alto Desempenho..." -ForegroundColor Yellow
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host '  [DOC // Edgerunners 1]: "Puxei o Alto Desempenho no lugar."' -ForegroundColor Magenta
    }
    powercfg /getactivescheme
    Pause-Cyber
}

function Invoke-Op09 {
    Clear-Host
    Show-BootBanner "[10] DIAGNOSTICO DE CROMO: SAUDE SMART E BATERIA"
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Senta na cadeira, vamos checar seus discos."' -ForegroundColor Green
    Write-Host '  [GLORIA MARTINEZ // Edgerunners 1]: "Cuide bem do que voce tem antes que quebre."' -ForegroundColor Green
    try {
        $disks = Get-PhysicalDisk -ErrorAction Stop
        $disks | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus, @{Name='Tamanho(GB)';Expression={[math]::Round($_.Size/1GB, 2)}} | Format-Table -AutoSize
        Write-Host '  [CAPRI // Edgerunners 2]: "Se aparecer Healthy, seus discos estao seguros."' -ForegroundColor Cyan
    } catch {
        Write-Host '  [RIVER WARD // CP2077]: "Usando fallback WMI alternativo..."' -ForegroundColor Yellow
        Get-CimInstance Win32_DiskDrive | Select-Object Model, Status, @{Name='Tamanho(GB)';Expression={[math]::Round($_.Size/1GB, 2)}} | Format-Table -AutoSize
    }
    Write-Host '  [MISTY OLSZEWSKI // CP2077]: "Verificando celula de energia (Bateria)..."' -ForegroundColor Magenta
    if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) {
        $hwDir = Get-DesktopDatedDadosDir -SubFolder "RELATORIOS_HARDWARE"
        $rep = Join-Path $hwDir "relatorio_bateria.html"
        powercfg /batteryreport /output $rep | Out-Null
        $repProj = Sync-FileToProjectDados -SourceFile $rep -SubFolder "RELATORIOS_HARDWARE"
        Write-Host "  [OK] Relatorio salvo na Area de Trabalho: $rep" -ForegroundColor Green
        if ($repProj) { Write-Host "  [OK] Copia portatil salva no Projeto/Pen Drive: $repProj" -ForegroundColor Cyan }
        Start-Process $rep
    } else {
        Write-Host "  [INFO] Nenhuma bateria detectada (Sistema Desktop)." -ForegroundColor Yellow
    }
    Pause-Cyber
}

function Invoke-Op10 {
    Clear-Host
    Show-BootBanner "[11] RESET COMPLETO DE REDE E DNS"
    Write-Host '  [CAPRI // Edgerunners 2]: "Quebrando rastreamento e limpando DNS."' -ForegroundColor Cyan
    Write-Host '  [SOLOMON REED // CP2077]: "Executando flushdns, ip reset e winsock..."' -ForegroundColor White
    ipconfig /release | Out-Null
    ipconfig /flushdns
    ipconfig /renew | Out-Null
    netsh int ip reset
    netsh winsock reset
    Write-Host "`n  [OK] Pilha de rede resetada. Reinicie o PC para aplicar 100%." -ForegroundColor Green
    Write-Host '  [ROGUE AMENDIARES // CP2077]: "Conexao limpa. Bom trabalho."' -ForegroundColor Yellow
    Pause-Cyber
}

function Invoke-Op11 {
    Clear-Host
    Show-BootBanner "[12] BACKUP DE ENGRAMA (PONTO DE RESTAURACAO / MIKOSHI)"
    Write-Host '  [ALT CUNNINGHAM // CP2077]: "Gravando estado atual do sistema no Mikoshi local."' -ForegroundColor Red
    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description 'CyberDeck_Backup_2077' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        Write-Host "  [OK] Ponto de restauracao criado!" -ForegroundColor Green
        Write-Host '  [SABURO ARASAKA // CP2077]: "Ordem preservada. Backup seguro."' -ForegroundColor Red
    } catch {
        Write-Host "  [AVISO/ERRO] $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host '  [JOHNNY SILVERHAND // CP2077]: "O Windows limita a 1 ponto a cada 24h por padrao."' -ForegroundColor Red
    }
    Pause-Cyber
}

function Invoke-Op12 {
    Clear-Host
    Show-BootBanner "[13] DATASHARD DE PROGRAMAS (WINGET EXPORT)"
    Write-Host '  [REGINA JONES // CP2077]: "Exportando todos os softwares para a Area de Trabalho."' -ForegroundColor Yellow
    $pastaBackup = Get-DesktopDatedDadosDir -SubFolder "BACKUPS-PROGRAMAS"
    $dest = Join-Path $pastaBackup "meus_programas.json"
    winget export -o $dest --accept-source-agreements
    if ($LASTEXITCODE -eq 0) {
        $tutPath = Join-Path $pastaBackup "TUTORIAL PARA REINSTALAR TODOS OS PROGRAMAS.txt"
        $tutLines = @(
        '========================================================================',
        '  CYBERDECK OS // TUTORIAL PARA REINSTALAR TODOS OS PROGRAMAS',
        '========================================================================',
        '',
        '!!! ATENCAO IMPORTANTE: SALVE ESTA PASTA ANTES DE FORMATAR O PC !!!',
        '------------------------------------------------------------------------',
        'Antes de formatar o Windows, COPIE a pasta inteira ''BACKUPS-PROGRAMAS''',
        '(que contem o arquivo ''meus_programas.json'' e este tutorial) para um',
        'local seguro fora do Disco C:, como:',
        '  - Pendrive ou HD Externo',
        '  - Outro disco/particao do PC que NAO sera formatado (ex: D: ou E:)',
        '  - Nuvem (Google Drive, OneDrive, Mega, etc.)',
        '',
        'Se voce formatar o PC sem salvar esta pasta em outro lugar, o backup',
        'sera apagado junto com a Area de Trabalho!',
        '',
        '========================================================================',
        '  PASSO A PASSO PARA REINSTALAR TUDO APOS FORMATAR O WINDOWS',
        '========================================================================',
        '',
        '1. Apos instalar o Windows novo e conectar na internet, copie a pasta',
        '   ''BACKUPS-PROGRAMAS'' de volta para a sua Area de Trabalho (Desktop).',
        '',
        '2. Abra o Menu Iniciar, digite ''CMD'' (Prompt de Comando) ou ''PowerShell'',',
        '   clique com o botao direito e escolha ''Executar como administrador''.',
        '',
        '3. Copie e cole o comando correspondente ao terminal que voce abriu',
        '   e pressione ENTER:',
        '',
        '   [SE VOCE ABRIU O CMD / PROMPT DE COMANDO]:',
        "   winget import -i `"$dest`" --accept-package-agreements --accept-source-agreements",
        '',
        '   [SE VOCE ABRIU O POWERSHELL]:',
        "   winget import -i `"$dest`" --accept-package-agreements --accept-source-agreements",
        '',
        '4. Aguarde! O Windows (via Winget) vai baixar e instalar automaticamente',
        '   todos os programas da sua lista um por um.',
        '',
        '========================================================================',
        '  DICAS EM CASO DE ERRO',
        '========================================================================',
        '- Se aparecer que ''winget nao e reconhecido'': abra a Microsoft Store,',
        '  procure por ''Instalador de Aplicativo'' (App Installer), clique em',
        '  Atualizar e tente o comando novamente.',
        '- Se voce salvou a pasta em outro lugar (ex: no pendrive E:\), basta',
        '  substituir o caminho entre aspas pelo caminho onde esta o arquivo',
        '  ''meus_programas.json''.',
        '- Programas muito antigos ou portateis que nao existem no catalogo do',
        '  Winget precisarao ser instalados manualmente.',
        '========================================================================'
        )
        Set-Content -Path $tutPath -Value $tutLines -Encoding UTF8
        $dadosProg = Sync-FolderToProjectDados -SourceDir $pastaBackup -SubFolder "BACKUPS-PROGRAMAS"
        Write-Host "`n  [OK] Datashard salvo na Area de Trabalho: $dest" -ForegroundColor Green
        Write-Host "  [OK] Tutorial gerado em: $tutPath" -ForegroundColor Green
        if ($dadosProg) { Write-Host "  [OK] Espelhado automaticamente no Projeto (Pen Drive / SSD): $dadosProg" -ForegroundColor Cyan }
        Write-Host '  [AVISO IMPORTANTE] A pasta foi salva na Area de Trabalho E dentro de DADOS\BACKUPS-PROGRAMAS no seu projeto!' -ForegroundColor Yellow
        Write-Host '  [V // CP2077]: "Lista e tutorial salvos. Nao esquece de copiar essa pasta antes de formatar."' -ForegroundColor Cyan
    } else {
        Write-Host '  [WAKAKO OKADA // CP2077]: "Erro ao exportar. Confirme se o Winget esta atualizado."' -ForegroundColor Red
    }
    Pause-Cyber
}

function Invoke-Op13 {
    Clear-Host
    Show-BootBanner "[14] BARREIRA BLACKWALL v9: MALWARE, BACKDOORS, NGROK E USUARIOS"
    Write-Host '  [SONGBIRD // CP2077]: "Varrendo Daemons, Backdoors, tuneis ngrok, acessos remotos e contas ocultas."' -ForegroundColor Magenta
    Write-Host '  [ALT CUNNINGHAM // CP2077]: "Nada sera apagado sem sua autorizacao. Se acharmos algo, abrimos a pasta pra voce decidir."' -ForegroundColor Red
    Write-Host ""

    # [1/8] Defender, Firewall & Anti-Ransomware
    Write-Host "[1/8] Protecao em Tempo Real, Firewall e Anti-Ransomware (SOLOMON REED // CP2077):" -ForegroundColor Cyan
    try {
        $mp = Get-MpComputerStatus -ErrorAction Stop
        $pref = Get-MpPreference -ErrorAction SilentlyContinue
        Write-Host "  Antivirus Ativo:        $($mp.AntivirusEnabled)"
        Write-Host "  Protecao Tempo Real:    $($mp.RealTimeProtectionEnabled)"
        Write-Host "  Anti-Spyware:           $($mp.AntispywareEnabled)"
        Write-Host "  Assinaturas Atualizadas:$($mp.AntivirusSignatureLastUpdated)"
        $cfa = switch ($pref.EnableControlledFolderAccess) { 1 {"ATIVADO (Protegido)"} 2 {"Modo Auditoria"} default {"DESATIVADO"} }
        Write-Host "  Anti-Ransomware (Pastas Controladas): $cfa" -ForegroundColor Yellow
    } catch {
        Write-Host "  [AVISO] Windows Defender gerenciado por outro Antivirus ou indisponivel." -ForegroundColor Yellow
    }
    Get-NetFirewallProfile | Select-Object Name, Enabled | Format-Table -AutoSize

    # [2/8] Conexoes TCP Externas
    Write-Host "[2/8] Conexoes TCP Externas Ativas (LUCY // Edgerunners 1):" -ForegroundColor Cyan
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { $_.RemoteAddress -notmatch '^(127\.|::1|0\.0\.0\.0)' } | Select-Object -First 20 LocalPort, RemoteAddress, RemotePort, @{Name='Processo';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}, OwningProcess | Format-Table -AutoSize

    # [3/8] Inicializacao
    Write-Host "[3/8] Programas na Inicializacao (RIVER WARD // CP2077):" -ForegroundColor Yellow
    Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command | Format-Table -Wrap -AutoSize

    # [4/8] Servicos fora de System32
    Write-Host "[4/8] Servicos em Execucao fora de System32 (GORO TAKEMURA // CP2077):" -ForegroundColor White
    Get-CimInstance Win32_Service | Where-Object { $_.State -eq 'Running' -and $_.PathName -and $_.PathName -notmatch 'C:\\Windows\\system32' -and $_.PathName -notmatch 'C:\\Windows\\SysWOW64' } | Select-Object -First 20 Name, DisplayName, PathName | Format-Table -Wrap -AutoSize

    # [5/8] CACA A TUNEIS REVERSOS (NGROK, CLOUDFLARED, FRPC, CHISEL, BORE, PLAYIT)
    Write-Host "========================================================================" -ForegroundColor Magenta
    Write-Host "[5/8] DETECCAO DE TUNEIS REVERSOS E PROXIES (NGROK / CLOUDFLARED / ETC)" -ForegroundColor Cyan
    Write-Host '  [D // Snake Nation - Edgerunners 2]: "Tuneis como ngrok e cloudflared abrem portas direto para fora sem passar pelo roteador."' -ForegroundColor Green
    Write-Host '  [SONGBIRD // CP2077]: "Se voce nao e dev usando isso agora, um tunel ativo pode ser acesso remoto oculto."' -ForegroundColor Magenta
    $tunnelNames = @('ngrok','cloudflared','frpc','frps','chisel','bore','playit','localtunnel','pagekite','rport')
    $foundTunnels = @()
    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
        foreach ($tn in $tunnelNames) {
            if ($p.ProcessName -like "*$tn*") {
                $path = try { $p.Path } catch { "Caminho protegido" }
                $foundTunnels += [PSCustomObject]@{ Tipo="PROCESSO ATIVO"; Nome=$p.ProcessName; PID=$p.Id; Caminho=$path }
            }
        }
    }
    $searchDirs = @("$env:USERPROFILE", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:LOCALAPPDATA", "$env:APPDATA", "$env:TEMP")
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -Depth 2 -Filter "*.exe" -ErrorAction SilentlyContinue | Where-Object {
                $n = $_.BaseName.ToLower()
                ($tunnelNames | Where-Object { $n -like "*$_*" }).Count -gt 0
            } | ForEach-Object {
                if (-not ($foundTunnels | Where-Object { $_.Caminho -eq $_.FullName })) {
                    $foundTunnels += [PSCustomObject]@{ Tipo="ARQUIVO ENCONTRADO"; Nome=$_.Name; PID="-"; Caminho=$_.FullName }
                }
            }
        }
    }
    if ($foundTunnels.Count -eq 0) {
        Write-Host "  [OK] Nenhum processo ou executavel de tunel (ngrok/cloudflared/frpc/chisel) detectado." -ForegroundColor Green
    } else {
        Write-Host "  [ALERTA] Possivel ferramenta de tunelamento detectada (verifique se foi voce quem instalou):" -ForegroundColor Red
        $foundTunnels | Format-Table -Wrap -AutoSize
        $verTun = Read-Host "Deseja abrir a pasta de cada item encontrado para inspecionar e decidir o que fazer? [S/N]"
        if ($verTun -match "^[sS]$") {
            foreach ($item in $foundTunnels) {
                Write-Host "`n  Item: $($item.Nome) | Caminho: $($item.Caminho)" -ForegroundColor Yellow
                if ($item.Caminho -and (Test-Path $item.Caminho)) {
                    Start-Process explorer.exe -ArgumentList "/select,`"$($item.Caminho)`""
                    Write-Host "  [EXPLORER ABERTO] A pasta do arquivo foi aberta para voce verificar visualmente." -ForegroundColor Cyan
                }
                Write-Host "  [1] Encerrar processo (se ativo) e EXCLUIR arquivo via script" -ForegroundColor Red
                Write-Host "  [2] Apenas encerrar processo (sem excluir)" -ForegroundColor Yellow
                Write-Host "  [0] Nao fazer nada / Vou resolver manualmente (ou e ferramenta minha)" -ForegroundColor Green
                $at = Read-Host "Escolha [0-2]"
                if ($at -eq "1") {
                    if ($item.PID -ne "-") { Stop-Process -Id $item.PID -Force -ErrorAction SilentlyContinue }
                    if ($item.Caminho -and (Test-Path $item.Caminho)) {
                        $confDel = Read-Host "Digite EXCLUIR para confirmar a remocao de $($item.Caminho)"
                        if ($confDel -eq "EXCLUIR") {
                            Remove-Item -Path $item.Caminho -Force -ErrorAction SilentlyContinue
                            Write-Host "  [OK] Arquivo removido." -ForegroundColor Green
                        } else { Write-Host "  [CANCELADO] Arquivo mantido." -ForegroundColor DarkGray }
                    }
                } elseif ($at -eq "2" -and $item.PID -ne "-") {
                    Stop-Process -Id $item.PID -Force -ErrorAction SilentlyContinue
                    Write-Host "  [OK] Processo encerrado." -ForegroundColor Green
                }
            }
        }
    }

    # [6/8] BACKDOORS E ACESSOS REMOTOS NAO AUTORIZADOS
    Write-Host "`n========================================================================" -ForegroundColor Magenta
    Write-Host "[6/8] AUDITORIA DE BACKDOORS E ACESSOS REMOTOS (RDP / IFEO / WMI / APPS)" -ForegroundColor Cyan
    Write-Host '  [KIWI // Edgerunners 1]: "Checando Area de Trabalho Remota (RDP), WinRM, SSH, backdoors IFEO e apps remotos."' -ForegroundColor Magenta
    # RDP check
    $rdpVal = try { (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction Stop).fDenyTSConnections } catch { 1 }
    if ($rdpVal -eq 0) {
        Write-Host "  [ALERTA] Area de Trabalho Remota (RDP) esta ATIVADA neste PC!" -ForegroundColor Yellow
        Write-Host '  [SOLOMON REED // CP2077]: "Se voce nao usa RDP para acessar este PC de longe, desative nas Configuracoes."' -ForegroundColor White
    } else {
        Write-Host "  [OK] Area de Trabalho Remota (RDP) esta DESATIVADA." -ForegroundColor Green
    }
    # OpenSSH / WinRM
    foreach ($svcName in @('sshd','WinRM')) {
        $sv = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($sv -and $sv.Status -eq 'Running') {
            Write-Host "  [AVISO] Servico de acesso remoto '$svcName' esta EM EXECUCAO." -ForegroundColor Yellow
        }
    }
    # IFEO Sticky Keys Backdoor check
    $ifeoTargets = @('sethc.exe','utilman.exe','osk.exe','magnify.exe','narrator.exe','displayswitch.exe')
    $ifeoHits = @()
    foreach ($exe in $ifeoTargets) {
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$exe"
        if (Test-Path $regPath) {
            $dbg = (Get-ItemProperty $regPath -Name Debugger -ErrorAction SilentlyContinue).Debugger
            if ($dbg) { $ifeoHits += [PSCustomObject]@{ Alvo=$exe; Debugger=$dbg } }
        }
    }
    if ($ifeoHits.Count -gt 0) {
        Write-Host "  [CRITICO] POSSIVEL BACKDOOR DE TELA DE LOGIN (IFEO DEBUGGER) DETECTADO:" -ForegroundColor Red
        $ifeoHits | Format-Table -AutoSize
        Write-Host '  [ALT CUNNINGHAM // CP2077]: "Um atacante pode abrir terminal como SYSTEM na tela de login usando isso!"' -ForegroundColor Red
    } else {
        Write-Host "  [OK] Nenhum backdoor IFEO (Sticky Keys / Utilman) detectado." -ForegroundColor Green
    }
    # WMI Event Consumers (fileless persistence)
    $wmiCons = Get-CimInstance -Namespace root\subscription -ClassName __EventConsumer -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'SCM Event Log Consumer' }
    if ($wmiCons) {
        Write-Host "  [AVISO] Assinaturas WMI persistentes encontradas (verifique se reconhece):" -ForegroundColor Yellow
        $wmiCons | Select-Object Name, __CLASS | Format-Table -AutoSize
    } else {
        Write-Host "  [OK] Nenhuma persistencia oculta via WMI Event Consumer detectada." -ForegroundColor Green
    }
    # Remote Access Tools (AnyDesk, TeamViewer, RustDesk, ScreenConnect, MeshAgent, VNC, etc.)
    $ratNames = @('anydesk','teamviewer','rustdesk','screenconnect','meshagent','tvnserver','winvnc','ammyy','supremo','parsec','aeroadmin','logmein','splashtop')
    $foundRats = @()
    foreach ($p in (Get-Process -ErrorAction SilentlyContinue)) {
        foreach ($rn in $ratNames) {
            if ($p.ProcessName -like "*$rn*") {
                $path = try { $p.Path } catch { "" }
                $foundRats += [PSCustomObject]@{ Ferramenta=$p.ProcessName; PID=$p.Id; Caminho=$path }
            }
        }
    }
    if ($foundRats.Count -eq 0) {
        Write-Host "  [OK] Nenhum software de acesso remoto ativo em execucao no momento." -ForegroundColor Green
    } else {
        Write-Host "  [INFO/REVISAR] Software(s) de acesso remoto em execucao (pode ser legitimo se voce usa):" -ForegroundColor Yellow
        $foundRats | Format-Table -Wrap -AutoSize
        $openRat = Read-Host "Deseja abrir a pasta de algum desses apps de acesso remoto para conferir? [S/N]"
        if ($openRat -match "^[sS]$") {
            foreach ($r in $foundRats) {
                if ($r.Caminho -and (Test-Path $r.Caminho)) {
                    Start-Process explorer.exe -ArgumentList "/select,`"$($r.Caminho)`""
                }
            }
            Write-Host "  [INFO] Pasta(s) aberta(s). Nada foi encerrado ou apagado automaticamente." -ForegroundColor Cyan
        }
    }

    # [7/8] AUDITORIA DE USUARIOS LOCAIS E SUPER PERMISSOES (ADMINISTRADORES)
    Write-Host "`n========================================================================" -ForegroundColor Magenta
    Write-Host "[7/8] AUDITORIA DE USUARIOS DO WINDOWS E CONTAS COM SUPER PERMISSOES" -ForegroundColor Cyan
    Write-Host '  [CAPRI // Edgerunners 2]:' -ForegroundColor Cyan
    Write-Host '  "Vamos checar todas as contas locais do PC. O Windows ja vem de fabrica com' -ForegroundColor White
    Write-Host '   contas nativas (Administrador, Convidado, DefaultAccount, WDAGUtilityAccount),' -ForegroundColor White
    Write-Host '   que normalmente ficam DESATIVADAS. Se a conta nativa Administrador estiver' -ForegroundColor White
    Write-Host '   ATIVA ou se surgir uma conta extra que voce nao criou, e sinal de alerta!"' -ForegroundColor White
    Write-Host '  [JOHNNY SILVERHAND // CP2077]:' -ForegroundColor Red
    Write-Host '  "Se o PC e seu e do nada apareceu um usuario Admin ou Suporte com super' -ForegroundColor White
    Write-Host '   permissoes meses depois, alguem pode ter deixado uma porta dos fundos aberta."' -ForegroundColor White
    Write-Host ""

    $currentUser = $env:USERNAME
    # Resolve Administrators group name safely via universal SID S-1-5-32-544 (works in PT-BR & EN-US)
    $adminSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $adminGroupName = $adminSid.Translate([System.Security.Principal.NTAccount]).Value.Split('\')[-1]
    $adminMembers = @()
    try {
        $adminMembers = (Get-LocalGroupMember -Group $adminGroupName -ErrorAction Stop).Name | ForEach-Object { $_.Split('\')[-1] }
    } catch {}

    $builtinDisabledOk = @('Administrator','Administrador','Guest','Convidado','DefaultAccount','WDAGUtilityAccount')
    $localUsers = Get-LocalUser -ErrorAction SilentlyContinue
    $suspiciousUsers = @()
    $userReport = @()

    foreach ($u in $localUsers) {
        $isAdmin = $adminMembers -contains $u.Name
        $profPath = "C:\Users\$($u.Name)"
        $profCreated = if (Test-Path $profPath) { (Get-Item $profPath).CreationTime.ToString("dd/MM/yyyy HH:mm") } else { "Sem pasta em C:\Users" }
        $isCurrent = ($u.Name -eq $currentUser)
        $isBuiltin = ($builtinDisabledOk -contains $u.Name)

        $statusTag = "NORMAL"
        if ($isCurrent) {
            $statusTag = "VOCE (CONTA ATUAL)"
        } elseif ($isBuiltin -and (-not $u.Enabled)) {
            $statusTag = "NATIVA WINDOWS (DESATIVADA - OK)"
        } elseif ($isBuiltin -and $u.Enabled) {
            $statusTag = "ALERTA: CONTA NATIVA ATIVADA!"
            $suspiciousUsers += [PSCustomObject]@{ Nome=$u.Name; Admin=$isAdmin; Pasta=$profPath; Nativa=$true; Motivo="Conta nativa do Windows esta ATIVA" }
        } else {
            $statusTag = if ($isAdmin) { "REVISAR: CONTA EXTRA COM ADMIN!" } else { "REVISAR: CONTA EXTRA" }
            $suspiciousUsers += [PSCustomObject]@{ Nome=$u.Name; Admin=$isAdmin; Pasta=$profPath; Nativa=$false; Motivo="Conta local adicional (nao e sua conta atual)" }
        }

        $userReport += [PSCustomObject]@{
            Usuario      = $u.Name
            Ativo        = $u.Enabled
            SuperAdmin   = $isAdmin
            PastaCriada  = $profCreated
            UltimoLogin  = if ($u.LastLogon) { $u.LastLogon.ToString("dd/MM/yyyy HH:mm") } else { "Nunca" }
            Classificacao= $statusTag
        }
    }

    $userReport | Format-Table -AutoSize

    if ($suspiciousUsers.Count -eq 0) {
        Write-Host "  [OK] Nenhuma conta extra ou conta nativa suspeita ativa encontrada!" -ForegroundColor Green
        Write-Host '  [VIKTOR VEKTOR // CP2077]: "So voce no comando da maquina, choom. Tudo limpo."' -ForegroundColor Green
    } else {
        Write-Host "  [ATENCAO] Foram encontradas $($suspiciousUsers.Count) conta(s) para voce revisar!" -ForegroundColor Yellow
        Write-Host '  [LUCY // Edgerunners 1]: "Pode ser uma conta de familiar ou tecnico de confianca (falso positivo).' -ForegroundColor Cyan
        Write-Host '   Por isso NADA sera apagado automaticamente. Vamos abrir a pasta do usuario pra voce conferir!"' -ForegroundColor Cyan
        $revU = Read-Host "`nDeseja inspecionar essas contas uma por uma agora? [S/N]"
        if ($revU -match "^[sS]$") {
            foreach ($su in $suspiciousUsers) {
                Write-Host "`n------------------------------------------------------------------------" -ForegroundColor Yellow
                Write-Host "  CONTA EM REVISAO: $($su.Nome)" -ForegroundColor Red
                Write-Host "  Super Permissoes (Administrador): $($su.Admin) | Motivo: $($su.Motivo)" -ForegroundColor Yellow
                if (Test-Path $su.Pasta) {
                    Write-Host "  Abrindo pasta do perfil ($($su.Pasta)) no Explorer para inspecao..." -ForegroundColor Cyan
                    Start-Process explorer.exe -ArgumentList "`"$($su.Pasta)`""
                } else {
                    Write-Host "  Esta conta nao possui pasta em C:\Users (pode ser conta oculta/sem login). Abrindo C:\Users..." -ForegroundColor Cyan
                    Start-Process explorer.exe -ArgumentList "C:\Users"
                }
                Write-Host "  [WEAK 'KING' KINGSLEY // Edgerunners 2]: `"Olhe a pasta aberta antes de decidir:`"" -ForegroundColor Yellow
                Write-Host "   [1] DESATIVAR esta conta (Recomendado - bloqueia acesso sem apagar arquivos)" -ForegroundColor Green
                Write-Host "   [2] REMOVER do grupo Administradores (tira super permissoes)" -ForegroundColor Yellow
                if (-not $su.Nativa) {
                    Write-Host "   [3] EXCLUIR esta conta do Windows (irreversivel - pede confirmacao)" -ForegroundColor Red
                }
                Write-Host "   [4] Abrir painel de Contas do Windows (netplwiz) para gerenciar manualmente" -ForegroundColor Cyan
                Write-Host "   [0] Ignorar / Nao alterar (conta legitima ou vou resolver manualmente)" -ForegroundColor DarkGray
                $ua = Read-Host "Escolha uma acao para '$($su.Nome)'"
                if ($ua -eq "1") {
                    try {
                        Disable-LocalUser -Name $su.Nome -ErrorAction Stop
                        Write-Host "  [OK] Conta '$($su.Nome)' DESATIVADA com seguranca! (Pode reativar depois se precisar)." -ForegroundColor Green
                    } catch { Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red }
                } elseif ($ua -eq "2") {
                    try {
                        Remove-LocalGroupMember -Group $adminGroupName -Member $su.Nome -ErrorAction Stop
                        Write-Host "  [OK] Super permissoes (Administrador) removidas de '$($su.Nome)'." -ForegroundColor Green
                    } catch { Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red }
                } elseif ($ua -eq "3" -and (-not $su.Nativa)) {
                    $cDel = Read-Host "DIGITE 'EXCLUIR' EM MAIUSCULO PARA REMOVER A CONTA '$($su.Nome)'"
                    if ($cDel -eq "EXCLUIR") {
                        try {
                            Remove-LocalUser -Name $su.Nome -ErrorAction Stop
                            Write-Host "  [OK] Conta '$($su.Nome)' excluida do Windows (a pasta em C:\Users foi mantida para seguranca caso queira checar/apagar manualmente)." -ForegroundColor Green
                        } catch { Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red }
                    } else { Write-Host "  [CANCELADO] Conta mantida." -ForegroundColor DarkGray }
                } elseif ($ua -eq "4") {
                    Start-Process netplwiz
                } else {
                    Write-Host "  [MANTIDO] Nenhuma alteracao feita na conta '$($su.Nome)'." -ForegroundColor DarkGray
                }
            }
        }
    }

    # [8/8] Historico de Ameacas do Defender
    Write-Host "`n[8/8] Historico de Ameacas do Defender (WEAK 'KING' KINGSLEY // Edgerunners 2):" -ForegroundColor Cyan
    try {
        $threats = Get-MpThreatDetection -ErrorAction SilentlyContinue
        if ($threats) { $threats | Select-Object -First 10 InitialDetectionTime, ThreatID, Resources | Format-Table -AutoSize }
        else { Write-Host "  [OK] Nenhuma ameaca ativa no historico do Defender." -ForegroundColor Green }
    } catch {}

    # Submenu de Varreduras do Defender (Painel permanece aberto)
    while ($true) {
        Write-Host "`n========================================================================" -ForegroundColor Magenta
        Write-Host "  ESCOLHA O TIPO DE VARREDURA (PAINEL PERMANECE ABERTO):" -ForegroundColor White
        Write-Host "  [1] Varredura RAPIDA    - Via PowerShell (com monitor ao vivo de tempo/CPU)" -ForegroundColor Green
        Write-Host "  [2] Varredura COMPLETA  - Via PowerShell (com monitor ao vivo de tempo/CPU)" -ForegroundColor Yellow
        Write-Host "  [3] Varredura OFFLINE   - Reinicia o PC para eliminar rootkits/ransomware no boot" -ForegroundColor Red
        Write-Host "  [4] Abrir Tela do Windows Defender (Seguranca do Windows)" -ForegroundColor Cyan
        Write-Host "  [0] Voltar ao Menu" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Magenta
        $bw = Read-Host "Opcao [0-4]"
        if ($bw -eq "1" -or $bw -eq "2") {
            $isFull = ($bw -eq "2")
            $tipoLabel = if ($isFull) { "COMPLETA" } else { "RAPIDA" }
            $mpScanType = if ($isFull) { "FullScan" } else { "QuickScan" }
            $charStart = if ($isFull) { "[GORO TAKEMURA // CP2077]" } else { "[LUCY // Edgerunners 1]" }
            $corStart = if ($isFull) { "Yellow" } else { "Cyan" }
            $msgStart = if ($isFull) { "Varredura COMPLETA selecionada. Escolha como deseja executar:" } else { "Varredura RAPIDA selecionada. Escolha como deseja executar:" }

            Write-Host "`n  $charStart`: `"$msgStart`"" -ForegroundColor $corStart
            Write-Host "  [A] Executar via POWERSHELL (janela paralela com cronometro e status ao vivo)" -ForegroundColor Cyan
            Write-Host "  [B] Mostrar na TELA DO WINDOWS DEFENDER (abre Opcoes de verificacao / Seguranca do Windows)" -ForegroundColor Green
            Write-Host "  [C] Ambos (inicia via PowerShell com monitor ao vivo E abre a tela do Windows Defender)" -ForegroundColor Magenta
            $modoScan = Read-Host "Escolha [A/B/C]"

            if ($modoScan -match "^[bBcC]$") {
                Write-Host '  [VIKTOR VEKTOR // CP2077]: "Abrindo a tela Seguranca do Windows para voce acompanhar o Defender."' -ForegroundColor Green
                Start-Process "windowsdefender://threat"
            }

            if ($modoScan -match "^[aAcC]$") {
                $psCmd = @"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
`$Host.UI.RawUI.WindowTitle = 'BLACKWALL // VARREDURA $tipoLabel'
Write-Host '========================================================================' -ForegroundColor Magenta
Write-Host '  [BLACKWALL] VARREDURA $tipoLabel DO WINDOWS DEFENDER (MONITOR ATIVO)' -ForegroundColor Cyan
Write-Host '  [SONGBIRD // CP2077]: "Atualizando assinaturas e iniciando varredura $tipoLabel..."' -ForegroundColor Magenta
Write-Host '========================================================================' -ForegroundColor Magenta
try {
    Write-Host '[1/2] Atualizando definicoes de ameacas (Update-MpSignature)...' -ForegroundColor Yellow
    Update-MpSignature -ErrorAction SilentlyContinue
    Write-Host '[2/2] Iniciando $mpScanType em segundo plano (monitorando a cada 3s)...' -ForegroundColor Green
    `$job = Start-Job -ScriptBlock { param(`$st) Start-MpScan -ScanType `$st -ErrorAction Stop } -ArgumentList '$mpScanType'
    `$sw = [System.Diagnostics.Stopwatch]::StartNew()
    `$spin = @('|','/','-','\')
    `$idx = 0
    while (`$job.State -eq 'Running') {
        `$proc = Get-Process -Name 'MsMpEng' -ErrorAction SilentlyContinue | Select-Object -First 1
        `$ramMB = if (`$proc) { [math]::Round(`$proc.WorkingSet64 / 1MB, 1) } else { 0 }
        `$cpuS = if (`$proc) { [math]::Round(`$proc.CPU, 1) } else { 0 }
        `$elapsed = `$sw.Elapsed.ToString('hh\:mm\:ss')
        `$sp = `$spin[`$idx % `$spin.Length]
        Write-Host ("`r  `[$sp`] Varredura $tipoLabel em andamento... Tempo: `$elapsed | Motor Defender (MsMpEng) RAM: `${ramMB} MB | CPU: `${cpuS}s   ") -NoNewline -ForegroundColor Cyan
        `$idx++
        Start-Sleep -Seconds 3
    }
    `$sw.Stop()
    Write-Host ""
    Receive-Job -Job `$job -ErrorAction Stop | Out-Null
    Remove-Job -Job `$job -Force -ErrorAction SilentlyContinue
    Write-Host '========================================================================' -ForegroundColor Green
    Write-Host ("  [OK] VARREDURA $tipoLabel CONCLUIDA! Tempo total: " + `$sw.Elapsed.ToString('hh\:mm\:ss')) -ForegroundColor Green
    Write-Host '  [V // Cyberpunk 2077]: "Varredura encerrada. Cheque o historico no Defender se quiser detalhes."' -ForegroundColor Cyan
    Write-Host '  [CAPRI // Edgerunners 2]: "Seu painel principal continuou aberto o tempo todo."' -ForegroundColor Cyan
    Write-Host '========================================================================' -ForegroundColor Green
} catch {
    Write-Host ('[ERRO] Falha na varredura: ' + `$_.Exception.Message) -ForegroundColor Red
    Write-Host '[ROGUE AMENDIARES // CP2077]: "Se outro antivirus estiver gerenciando o PC, use a tela Seguranca do Windows."' -ForegroundColor Yellow
}
"@
                $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($psCmd))
                Start-Process powershell.exe -ArgumentList "-NoExit", "-NoProfile", "-EncodedCommand", $encoded
            }
        } elseif ($bw -eq "3") {
            $msgs = @(
                '[JOHNNY SILVERHAND // Cyberpunk 2077]: Escuta aqui, Samurai. Seu PC vai reiniciar agora para rodar a Varredura Offline antes do Windows subir. Salve tudo antes.',
                '[CAPRI // Edgerunners 2]: Atencao. O protocolo Offline vai reiniciar sua maquina e varrer o sistema fora do Windows para destruir rootkits e ransomware.',
                '[SONGBIRD // Cyberpunk 2077]: Aviso da Blackwall: o PC sera reiniciado em instantes para executar a Varredura Offline do Defender. Feche seus arquivos abertos.',
                '[DAVID MARTINEZ // Edgerunners 1]: Ei, choom. Vamos reiniciar o PC agora para rodar a Varredura Offline e limpar qualquer cromo infectado no boot.',
                '[LUCY // Edgerunners 1]: Desconectando do Windows... O computador vai reiniciar e executar a Varredura Offline do Defender antes do sistema carregar.',
                '[REBECCA // Edgerunners 1]: Segura a onda! O PC vai reiniciar pra fazer a Varredura Offline. Salva teus jogos antes de confirmar.',
                '[WEAK KING KINGSLEY // Edgerunners 2]: Aviso importante: a Varredura Offline exige reiniciar o computador agora. Ela leva cerca de 15 minutos antes de voltar ao Windows.',
                '[D // Snake Nation - Edgerunners 2]: Hora de apagar os rastros profundos. O PC sera reiniciado e fara a Varredura Offline no ambiente de recuperacao.',
                '[VIKTOR VEKTOR // Cyberpunk 2077]: Cirurgia pesada no sistema. Vou precisar reiniciar seu PC para a Varredura Offline limpar tudo antes do Windows iniciar.',
                '[SOLOMON REED // FIA - Cyberpunk 2077]: Protocolo de emergencia. Ao confirmar, o computador sera reiniciado imediatamente para a Varredura Offline.',
                '[ALT CUNNINGHAM // Cyberpunk 2077]: Atravessando a camada de boot. O sistema reiniciara para executar a Varredura Offline longe de qualquer processo ativo.',
                '[PANAM PALMER // Cyberpunk 2077]: Salva tudo o que estiver aberto. O PC vai reiniciar agora e rodar a Varredura Offline completa no boot.',
                '[JUDY ALVAREZ // Cyberpunk 2077]: Aviso rapido: o PC vai reiniciar para a Varredura Offline do Defender. Nao desligue da tomada durante o processo.',
                '[TALIA // Edgerunners 2]: Sem piedade com malware escondido. O sistema vai reiniciar e executar a Varredura Offline assim que voce confirmar.',
                '[ROMAN CARAX // Edgerunners 2]: Corta a cena. O computador sera reiniciado agora para executar a Varredura Offline do Windows Defender.',
                '[JACKIE WELLES // Cyberpunk 2077]: Salva suas coisas ai, mano. O PC vai reiniciar pra fazer a Varredura Offline e voltar zero bala.'
            )
            Write-Host "`n========================================================================" -ForegroundColor Red
            Write-Host "  [ALERTA DE REINICIALIZACAO // VARREDURA OFFLINE]" -ForegroundColor Red
            Write-Host "  $(Get-Random -InputObject $msgs)" -ForegroundColor Yellow
            Write-Host "========================================================================" -ForegroundColor Red
            $c = Read-Host "CONFIRMA REINICIAR O PC AGORA PARA A VARREDURA OFFLINE? [S/N]"
            if ($c -match "^[sS]$") {
                try { Start-MpWDOScan -ErrorAction Stop } catch {
                    Write-Host "  [ERRO] $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host '  [ROGUE // CP2077]: "Verifique se o Defender e o WinRE estao ativos."' -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [CANCELADO] Reinicializacao abortada." -ForegroundColor DarkGray
            }
        } elseif ($bw -eq "4") {
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Abrindo a tela Seguranca do Windows (Windows Defender)."' -ForegroundColor Green
            Start-Process "windowsdefender://threat"
        } elseif ($bw -eq "0") {
            break
        }
    }
}function Invoke-StepToggle {
    param(
        [string]$Titulo, [bool]$Ativo, [string]$StatusAtivo, [string]$StatusDesativado,
        [string]$Personagem, [string]$CorChar, [string]$Fala,
        [string]$OQueFaz, [string]$Impacto, [string]$AoReverter,
        [scriptblock]$AcaoDesativar, [scriptblock]$AcaoReativar
    )
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor Magenta
    Write-Host "  $Titulo" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Magenta
    if ($Ativo) { Write-Host "  STATUS DETECTADO: [$StatusAtivo]" -ForegroundColor Red }
    else { Write-Host "  STATUS DETECTADO: [$StatusDesativado]" -ForegroundColor Green }
    Write-Host "`n  $Personagem`:" -ForegroundColor $CorChar
    Write-Host "  `"$Fala`"" -ForegroundColor White
    Write-Host "`n  [O QUE FAZ]: $OQueFaz" -ForegroundColor Yellow
    Write-Host "  [IMPACTO NEGATIVO]: $Impacto" -ForegroundColor Red
    Write-Host ""
    if ($Ativo) {
        $r = Read-Host "Deseja APLICAR esta alteracao agora? [S/N]"
        if ($r -match "^[sS]$") { & $AcaoDesativar; Write-Host "  [OK] Alteracao aplicada!" -ForegroundColor Green }
        else { Write-Host "  [MANTIDO] Nenhuma alteracao feita." -ForegroundColor DarkGray }
    } else {
        Write-Host "  [AO REVERTER]: $AoReverter" -ForegroundColor Cyan
        $r = Read-Host "Ja esta aplicado. Deseja REVERTER/REATIVAR o padrao da Microsoft? [S/N]"
        if ($r -match "^[sS]$") { & $AcaoReativar; Write-Host "  [OK] Padrao restaurado!" -ForegroundColor Green }
        else { Write-Host "  [MANTIDO] Continua como estava." -ForegroundColor DarkGray }
    }
    Pause-Cyber
}

function Invoke-Op14 {
    # 1. DiagTrack (Capri)
    $s1 = Get-CimInstance Win32_Service -Filter "Name='DiagTrack'" -ErrorAction SilentlyContinue
    Invoke-StepToggle "[1/8] SERVICO: DiagTrack (Telemetria)" ($s1 -and $s1.StartMode -ne 'Disabled') "ATIVO - COLETANDO DADOS" "DESATIVADO" `
        "[CAPRI // Edgerunners 2]" "Cyan" "Detectei o principal canal de extracao: DiagTrack. Ele envia logs de uso e falhas para a Microsoft." `
        "Servico central de telemetria e diagnostico do Windows." `
        "Hub de Feedback e Windows Insider podem exigir este servico. Em jogos/uso normal nao afeta." `
        "Volta o servico para inicio automatico." `
        { Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue; Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue } `
        { Set-Service DiagTrack -StartupType Automatic -ErrorAction SilentlyContinue; Start-Service DiagTrack -ErrorAction SilentlyContinue }

    # 2. dmwappushservice (Songbird)
    $s2 = Get-CimInstance Win32_Service -Filter "Name='dmwappushservice'" -ErrorAction SilentlyContinue
    Invoke-StepToggle "[2/8] SERVICO: dmwappushservice (Push WAP / MDM)" ($s2 -and $s2.StartMode -ne 'Disabled') "ATIVO" "DESATIVADO" `
        "[SONGBIRD // Cyberpunk 2077]" "Magenta" "Achei uma porta de roteamento push conectada ao nucleo de telemetria." `
        "Roteia mensagens push WAP (MDM) e auxilia telemetria." `
        "Nenhum em PCs pessoais. Apenas em PCs corporativos (Intune) pode bloquear politicas da empresa." `
        "Restaura o servico para inicio manual." `
        { Stop-Service dmwappushservice -Force -ErrorAction SilentlyContinue; Set-Service dmwappushservice -StartupType Disabled -ErrorAction SilentlyContinue } `
        { Set-Service dmwappushservice -StartupType Manual -ErrorAction SilentlyContinue }

    # 3. AllowTelemetry (Lucy)
    $v3 = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -ErrorAction Stop).AllowTelemetry } catch { 1 }
    Invoke-StepToggle "[3/8] REGISTRO: AllowTelemetry (Coleta Global)" ($v3 -ne 0) "ATIVO - COLETA PADRAO" "DESATIVADO (NIVEL 0)" `
        "[LUCY // Edgerunners 1]" "Cyan" "A chave AllowTelemetry define o quanto do seu sistema e transmitido para fora." `
        "Define o volume global de dados de diagnostico enviados." `
        "Pode exibir 'Algumas configuracoes sao gerenciadas pela sua organizacao' em Privacidade." `
        "Remove a politica local e devolve controle ao Windows." `
        { reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null; reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null } `
        { reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f 2>$null | Out-Null; reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /f 2>$null | Out-Null }

    # 4. Advertising ID (Johnny Silverhand)
    $v4 = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name Enabled -ErrorAction Stop).Enabled } catch { 1 }
    Invoke-StepToggle "[4/8] PRIVACIDADE: ID de Publicidade" ($v4 -ne 0) "ATIVO" "DESATIVADO" `
        "[JOHNNY SILVERHAND // Cyberpunk 2077]" "Red" "Um ID de publicidade colado na sua conta pra empurrar propaganda corporativa." `
        "Gera ID unico para anuncios direcionados e experiencias personalizadas." `
        "Praticamente zero. Apenas desliga recomendacoes personalizadas em apps da Store." `
        "Liga novamente o ID de anuncios." `
        { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f | Out-Null } `
        { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 1 /f | Out-Null }

    # 5. Activity History (Weak King Kingsley)
    $v5 = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name EnableActivityFeed -ErrorAction Stop).EnableActivityFeed } catch { 1 }
    Invoke-StepToggle "[5/8] RASTREAMENTO: Historico de Atividades" ($v5 -ne 0) "ATIVO" "DESATIVADO" `
        "[WEAK 'KING' KINGSLEY // Edgerunners 2]" "Yellow" "O sistema grava um diario de tudo que voce abre e tenta sincronizar na nuvem." `
        "Monitora apps abertos (Start_TrackProgs) e sincroniza Activity Feed." `
        "A lista de 'Mais usados' no Menu Iniciar deixa de se atualizar automaticamente." `
        "Reativa 'Mais usados' e historico de atividades." `
        { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f | Out-Null; reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null; reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null; reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f | Out-Null } `
        { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 1 /f | Out-Null; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f 2>$null | Out-Null; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /f 2>$null | Out-Null; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /f 2>$null | Out-Null }

    # 6. Scheduled Tasks (Kiwi)
    $t6 = Get-ScheduledTask -TaskPath '\Microsoft\Windows\Application Experience\' -TaskName 'Microsoft Compatibility Appraiser' -ErrorAction SilentlyContinue
    Invoke-StepToggle "[6/8] TAREFAS AGENDADAS: Appraiser, CEIP e DiskDiag" ($t6 -and $t6.State -ne 'Disabled') "ATIVAS" "DESATIVADAS" `
        "[KIWI // Edgerunners 1]" "Magenta" "Essas 5 tarefas acordam sozinhas para varrer seus discos e mandar relatorios, causando picos de CPU." `
        "Executa varreduras periodicas de telemetria (Compatibility Appraiser, CEIP, DiskDiag)." `
        "Avisos automaticos de upgrade anual do Windows podem demorar mais. Melhora uso de CPU/Disco." `
        "Reabilita as 5 tarefas no Agendador de Tarefas." `
        { @("Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser","Microsoft\Windows\Application Experience\ProgramDataUpdater","Microsoft\Windows\Customer Experience Improvement Program\Consolidator","Microsoft\Windows\Customer Experience Improvement Program\UsbCeip","Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector") | ForEach-Object { schtasks /Change /TN $_ /Disable 2>$null | Out-Null } } `
        { @("Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser","Microsoft\Windows\Application Experience\ProgramDataUpdater","Microsoft\Windows\Customer Experience Improvement Program\Consolidator","Microsoft\Windows\Customer Experience Improvement Program\UsbCeip","Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector") | ForEach-Object { schtasks /Change /TN $_ /Enable 2>$null | Out-Null } }

    # 7. Bing Search (D)
    $v7 = try { (Get-ItemProperty 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' -Name DisableSearchBoxSuggestions -ErrorAction Stop).DisableSearchBoxSuggestions } catch { 0 }
    Invoke-StepToggle "[7/8] MENU INICIAR: Busca Web/Bing e Apps Sugeridos" ($v7 -ne 1) "ATIVO - ENVIANDO PARA O BING" "DESATIVADO - BUSCA LOCAL" `
        "[D // Snake Nation - Edgerunners 2]" "Green" "Cada letra digitada no Menu Iniciar vaza para o Bing e puxa apps patrocinados." `
        "Conecta a barra de busca do Windows ao Bing e ativa CloudContent." `
        "A busca no Menu Iniciar fica 100% local (sem resultados da internet)." `
        "Volta a mostrar resultados do Bing no Menu Iniciar." `
        { reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null; reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f | Out-Null } `
        { reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /f 2>$null | Out-Null; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /f 2>$null | Out-Null }

    # 8. SIUF Feedback (Alt Cunningham)
    $v8 = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\Siuf\Rules' -Name NumberOfSIUFInPeriod -ErrorAction Stop).NumberOfSIUFInPeriod } catch { 1 }
    Invoke-StepToggle "[8/8] NOTIFICACOES: Feedback Automatico (SIUF)" ($v8 -ne 0) "ATIVO" "SILENCIADO" `
        "[ALT CUNNINGHAM // Cyberpunk 2077]" "Red" "O modulo SIUF interrompe seu fluxo com pedidos de avaliacao. Silencie esse ruido." `
        "Controla a frequencia de pop-ups pedindo feedback do Windows." `
        "Nenhum impacto negativo." `
        "Permite novamente pop-ups de feedback." `
        { reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null } `
        { reg delete "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /f 2>$null | Out-Null }
}

function Convert-PSPathToRegExePath {
    param([string]$PSPath)
    $p = $PSPath -replace '^Microsoft\.PowerShell\.Core\\Registry::', ''
    $p = $p -replace '^HKEY_LOCAL_MACHINE\\', 'HKLM\'
    $p = $p -replace '^HKEY_CURRENT_USER\\', 'HKCU\'
    $p = $p -replace '^HKEY_CLASSES_ROOT\\', 'HKCR\'
    $p = $p -replace '^HKEY_USERS\\', 'HKU\'
    return $p
}

function Backup-RegistryKeySafe {
    param(
        [string]$RegExePath,
        [string]$BackupDir,
        [string]$Prefix = "chave"
    )
    if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }
    $safeName = ($Prefix -replace '[^a-zA-Z0-9_\-]', '_')
    if ($safeName.Length -gt 45) { $safeName = $safeName.Substring(0, 45) }
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $outReg = Join-Path $BackupDir "${safeName}_${stamp}.reg"
    $null = reg export "$RegExePath" "$outReg" /y 2>&1
    $null = Sync-FileToProjectDados -SourceFile $outReg -SubFolder "BACKUP_LIMPEZA_REGISTRO_ORFAOS"
    return $outReg
}

function Get-ExePathFromCommand {
    param([string]$CmdLine)
    if ([string]::IsNullOrWhiteSpace($CmdLine)) { return $null }
    $s = $CmdLine.Trim()
    if ($s -match '^\s*"([^"]+\.exe)"') { return $matches[1] }
    if ($s -match '^\s*([A-Za-z]:\\[^,;"*?<>|]+\.exe)') { return $matches[1] }
    return $null
}

function Get-OrphanUninstallEntries {
    $roots = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $fixedDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue | ForEach-Object { $_.DeviceID.ToUpper() })
    $orphans = @()

    foreach ($root in $roots) {
        $items = Get-ItemProperty -Path $root -ErrorAction SilentlyContinue
        foreach ($it in $items) {
            if (-not $it.DisplayName) { continue }
            if ($it.SystemComponent -eq 1 -or $it.WindowsInstaller -eq 1) { continue }
            $dn = [string]$it.DisplayName
            $pub = [string]$it.Publisher
            if ($dn -match '^(Microsoft|Windows|Atualizacao|Update for|Security Update|KB\d{6})' -or $pub -match 'Microsoft Corporation') { continue }

            $uninst = [string]$it.UninstallString
            if ($uninst -match 'msiexec' -or $uninst -match 'rundll32') { continue }

            $instLoc = ([string]$it.InstallLocation).Trim().Trim('"')
            $exePath = Get-ExePathFromCommand -CmdLine $uninst
            $brokenReason = $null

            if ($exePath -and $exePath -match '^([A-Za-z]:)\\') {
                $drv = $matches[1].ToUpper()
                if ($fixedDrives -contains $drv) {
                    if (-not (Test-Path -LiteralPath $exePath)) {
                        $brokenReason = "Desinstalador ausente: $exePath"
                    }
                }
            } elseif ($instLoc -and $instLoc -match '^([A-Za-z]:)\\') {
                $drv = $matches[1].ToUpper()
                if ($fixedDrives -contains $drv) {
                    if (-not (Test-Path -LiteralPath $instLoc)) {
                        $brokenReason = "Pasta ausente: $instLoc"
                    }
                }
            }

            if ($brokenReason) {
                $orphans += [PSCustomObject]@{
                    Nome    = $dn
                    PSPath  = $it.PSPath
                    RegPath = Convert-PSPathToRegExePath -PSPath $it.PSPath
                    Motivo  = $brokenReason
                }
            }
        }
    }
    return $orphans
}

function Get-OrphanAppPathsAndMui {
    $fixedDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue | ForEach-Object { $_.DeviceID.ToUpper() })
    $results = @()

    # 1) App Paths
    foreach ($apRoot in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\*")) {
        $items = Get-ItemProperty -Path $apRoot -ErrorAction SilentlyContinue
        foreach ($it in $items) {
            $rawPath = ([string]$it.'(default)').Trim().Trim('"')
            if ($rawPath -match '^([A-Za-z]:)\\.+\.exe$') {
                $drv = $matches[1].ToUpper()
                if (($fixedDrives -contains $drv) -and (-not (Test-Path -LiteralPath $rawPath))) {
                    if ($rawPath -notmatch '\\Windows\\') {
                        $results += [PSCustomObject]@{
                            Tipo    = "AppPath"
                            Nome    = $it.PSChildName
                            PSPath  = $it.PSPath
                            RegPath = Convert-PSPathToRegExePath -PSPath $it.PSPath
                            ValName = $null
                            Motivo  = "Executavel ausente: $rawPath"
                        }
                    }
                }
            }
        }
    }

    # 2) MuiCache (entradas de executaveis antigos no historico do Shell)
    $muiKey = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    if (Test-Path $muiKey) {
        $props = Get-ItemProperty -Path $muiKey -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($p in $props.PSObject.Properties) {
                if ($p.Name -in @('PSPath','PSParentPath','PSChildName','PSDrive','PSProvider','LangID')) { continue }
                if ($p.Name -match '^([A-Za-z]:\\.+?\.exe)') {
                    $exeFile = $matches[1]
                    $drv = $exeFile.Substring(0, 2).ToUpper()
                    if (($fixedDrives -contains $drv) -and ($exeFile -notmatch '\\Windows\\') -and (-not (Test-Path -LiteralPath $exeFile))) {
                        $results += [PSCustomObject]@{
                            Tipo    = "MuiCache"
                            Nome    = [System.IO.Path]::GetFileName($exeFile)
                            PSPath  = $muiKey
                            RegPath = Convert-PSPathToRegExePath -PSPath $muiKey
                            ValName = $p.Name
                            Motivo  = "Cache de app removido: $exeFile"
                        }
                    }
                }
            }
        }
    }
    return $results
}

function Get-OrphanAppDataFolders {
    # Coletar nomes de programas atualmente instalados + pastas em Program Files
    $installedTokens = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($r in @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )) {
        Get-ItemProperty -Path $r -ErrorAction SilentlyContinue | ForEach-Object {
            foreach ($field in @($_.DisplayName, $_.Publisher)) {
                if ($field) {
                    $clean = ([string]$field).Trim()
                    [void]$installedTokens.Add($clean)
                    foreach ($w in ($clean -split '[\s\-\._\(\)]+')) {
                        if ($w.Length -ge 3) { [void]$installedTokens.Add($w) }
                    }
                }
            }
        }
    }

    foreach ($pf in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "$env:LOCALAPPDATA\Programs")) {
        if ($pf -and (Test-Path $pf)) {
            Get-ChildItem -Path $pf -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                [void]$installedTokens.Add($_.Name)
                foreach ($w in ($_.Name -split '[\s\-\._\(\)]+')) {
                    if ($w.Length -ge 3) { [void]$installedTokens.Add($w) }
                }
            }
        }
    }

    # Whitelist rigorosa de pastas criticas do Windows, drivers, navegadores e apps comuns
    $protected = @(
        'Microsoft','Windows','Packages','Temp','NVIDIA','NVIDIA Corporation','AMD','ATI','Intel','Realtek',
        'Google','Mozilla','Opera Software','BraveSoftware','Vivaldi','Edge','Chromium',
        'Discord','Steam','Valve','Epic','EpicGamesLauncher','Riot Games','Ubisoft','Electronic Arts','EA','Rockstar Games','Battle.net','Blizzard',
        'obs-studio','OBS','Code','Visual Studio Code','Git','npm','npm-cache','pip','Python','Node','nvm','NuGet','dotnet','JetBrains','Docker',
        '7-Zip','WinRAR','Oracle','Java','Adobe','Apple','Apple Computer','Logitech','LGHUB','Razer','Corsair','HyperX','MSI','Gigabyte','ASUS',
        'CrashDumps','D3DSCache','ConnectedDevicesPlatform','Comms','ElevatedDiagnostics','PeerDistRepub','Publishers','Speech','VirtualStore',
        'IconCache','FontCache','Identities','Diagnostics','Programs','Application Data','History','Temporary Internet Files','INetCache','INetCookies',
        'WebCache','OneDrive','Package Cache','USOPrivate','USOShared','ssh','WindowsApps','WinGet','Local','Roaming','Low','CEF','squirrel','SquirrelTemp',
        'Spotify','WhatsApp','Telegram Desktop','VLC','qBittorrent','Blender Foundation','Aseprite','FoundryVTT','Vortex','Nexus Mods','Cyberpunk 2077','CD Projekt Red'
    )
    $protectedSet = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $protected) { [void]$protectedSet.Add($p) }

    $scanRoots = @(
        @{ Label="APPDATA (Roaming)"; Path=$env:APPDATA },
        @{ Label="LOCALAPPDATA";      Path=$env:LOCALAPPDATA },
        @{ Label="AppData\LocalLow";  Path="$env:USERPROFILE\AppData\LocalLow" },
        @{ Label="ProgramData";       Path=$env:ProgramData }
    )

    $candidates = @()
    foreach ($sr in $scanRoots) {
        if (-not $sr.Path -or -not (Test-Path $sr.Path)) { continue }
        $dirs = Get-ChildItem -Path $sr.Path -Directory -ErrorAction SilentlyContinue
        foreach ($d in $dirs) {
            $name = $d.Name
            if ($name.StartsWith('.') -or $name.StartsWith([char]123) -or $name.StartsWith('$')) { continue }
            if ($protectedSet.Contains($name)) { continue }
            if ($installedTokens.Contains($name)) { continue }

            # Verificar se algum token significativo do nome da pasta corresponde a um app instalado
            $matched = $false
            foreach ($w in ($name -split '[\s\-\._]+')) {
                if ($w.Length -ge 4 -and $installedTokens.Contains($w)) {
                    $matched = $true
                    break
                }
            }
            if ($matched) { continue }

            # Calcular tamanho rapido da pasta
            $sizeBytes = 0
            try {
                $sum = (Get-ChildItem -Path $d.FullName -File -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($sum) { $sizeBytes = [int64]$sum }
            } catch {}

            $candidates += [PSCustomObject]@{
                Local       = $sr.Label
                Nome        = $name
                Caminho     = $d.FullName
                TamanhoMB   = [math]::Round($sizeBytes / 1MB, 2)
                UltimaMod   = $d.LastWriteTime.ToString("dd/MM/yyyy")
            }
        }
    }
    return ($candidates | Sort-Object TamanhoMB -Descending)
}

function Invoke-CleanOrphanRegistryAndFiles {
    $backupDir = Get-DesktopDatedDadosDir -SubFolder "BACKUP_LIMPEZA_REGISTRO_ORFAOS"
    while ($true) {
        Clear-Host
        Show-BootBanner "[16-B] LIMPEZA PROFUNDA DE REGISTROS VELHOS (REGEDIT + %APPDATA%)"
        Write-Host '  [SONGBIRD // CP2077]: "Varrendo rastros fantasma de programas ja desinstalados no Regedit e no Windows."' -ForegroundColor Magenta
        Write-Host '  [VIKTOR VEKTOR // CP2077]: "Seguranca primeiro: todo registro apagado gera backup .reg automatico na Area de Trabalho."' -ForegroundColor Green
        Write-Host '  [CAPRI // Edgerunners 2]: "Nenhuma pasta de %APPDATA% e apagada sem voce escolher os numeros exatos."' -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] REGEDIT: Entradas Orfas de Desinstalacao (Uninstall de apps ja removidos)" -ForegroundColor Yellow
        Write-Host "  [2] REGEDIT: Chaves 'App Paths' e 'MuiCache' Orfas (executaveis que nao existem mais)" -ForegroundColor Cyan
        Write-Host "  [3] WINDOWS: Pastas Orfas em %APPDATA%, %LOCALAPPDATA%, LocalLow e ProgramData" -ForegroundColor Magenta
        Write-Host "  [4] RELATORIO COMPLETO (Somente-Leitura: mostra tudo sem apagar nada)" -ForegroundColor Green
        Write-Host "  [0] Voltar ao Menu de Otimizacao" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Magenta
        $opL = Read-Host "Escolha uma opcao [0-4]"

        if ($opL -eq "0") { break }

        elseif ($opL -eq "1") {
            Write-Host "`n  [LUCY // Edgerunners 1]: `"Escaneando chaves Uninstall (HKLM / WOW6432Node / HKCU)...`"" -ForegroundColor Cyan
            $orphans = @(Get-OrphanUninstallEntries)
            if ($orphans.Count -eq 0) {
                Write-Host "  [OK] Nenhuma entrada orfa de desinstalacao encontrada no Regedit!" -ForegroundColor Green
            } else {
                Write-Host "  [ENCONTRADAS] $($orphans.Count) entrada(s) orfa(s) no Regedit:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $orphans.Count; $i++) {
                    Write-Host ("  [{0}] {1}" -f ($i + 1), $orphans[$i].Nome) -ForegroundColor White
                    Write-Host ("      Chave:  {0}" -f $orphans[$i].RegPath) -ForegroundColor DarkGray
                    Write-Host ("      Motivo: {0}" -f $orphans[$i].Motivo) -ForegroundColor Yellow
                }
                Write-Host "`n  Opcoes: digite 'T' para limpar TODAS (com backup .reg), numeros separados por virgula (ex: 1,3), ou '0' para cancelar:" -ForegroundColor Cyan
                $sel = (Read-Host "Sua escolha").Trim()
                $toClean = @()
                if ($sel -match "^[tT]$") {
                    $toClean = $orphans
                } elseif ($sel -and $sel -ne "0") {
                    foreach ($tok in ($sel -split ',')) {
                        $n = 0
                        if ([int]::TryParse($tok.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $orphans.Count) {
                            $toClean += $orphans[$n - 1]
                        }
                    }
                }
                if ($toClean.Count -gt 0) {
                    foreach ($item in $toClean) {
                        $bk = Backup-RegistryKeySafe -RegExePath $item.RegPath -BackupDir $backupDir -Prefix ("Uninstall_" + $item.Nome)
                        try {
                            Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction Stop
                            Write-Host "  [OK] Removida: $($item.Nome)  (Backup: $(Split-Path -Leaf $bk))" -ForegroundColor Green
                        } catch {
                            Write-Host "  [ERRO] Nao foi possivel remover $($item.Nome): $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                    Write-Host "  [BACKUP] Todos os .reg salvos em: $backupDir" -ForegroundColor Cyan
                } else {
                    Write-Host "  [MANTIDO] Nenhuma chave foi removida." -ForegroundColor DarkGray
                }
            }
            Pause-Cyber
        }

        elseif ($opL -eq "2") {
            Write-Host "`n  [D // Snake Nation - Edgerunners 2]: `"Escaneando App Paths e MuiCache atras de executaveis fantasmas...`"" -ForegroundColor Green
            $items = @(Get-OrphanAppPathsAndMui)
            if ($items.Count -eq 0) {
                Write-Host "  [OK] Nenhuma chave orfa em App Paths ou MuiCache encontrada!" -ForegroundColor Green
            } else {
                Write-Host "  [ENCONTRADAS] $($items.Count) entrada(s) fantasma no Regedit:" -ForegroundColor Yellow
                $limit = [math]::Min($items.Count, 40)
                for ($i = 0; $i -lt $limit; $i++) {
                    Write-Host ("  [{0}] ({1}) {2} -> {3}" -f ($i + 1), $items[$i].Tipo, $items[$i].Nome, $items[$i].Motivo) -ForegroundColor White
                }
                if ($items.Count -gt $limit) {
                    Write-Host "  ... e mais $($items.Count - $limit) entradas de MuiCache/AppPath." -ForegroundColor DarkGray
                }
                $conf = Read-Host "`nDeseja fazer backup .reg e limpar estas $($items.Count) entradas orfas agora? [S/N]"
                if ($conf -match "^[sS]$") {
                    $muiBackedUp = $false
                    $okCount = 0
                    foreach ($it in $items) {
                        try {
                            if ($it.Tipo -eq "AppPath") {
                                $null = Backup-RegistryKeySafe -RegExePath $it.RegPath -BackupDir $backupDir -Prefix ("AppPath_" + $it.Nome)
                                Remove-Item -Path $it.PSPath -Recurse -Force -ErrorAction Stop
                                $okCount++
                            } elseif ($it.Tipo -eq "MuiCache") {
                                if (-not $muiBackedUp) {
                                    $null = Backup-RegistryKeySafe -RegExePath $it.RegPath -BackupDir $backupDir -Prefix "MuiCache_Completo"
                                    $muiBackedUp = $true
                                }
                                Remove-ItemProperty -Path $it.PSPath -Name $it.ValName -Force -ErrorAction Stop
                                $okCount++
                            }
                        } catch {}
                    }
                    Write-Host "  [OK] $okCount entrada(s) orfa(s) removida(s) com sucesso! Backups .reg em: $backupDir" -ForegroundColor Green
                } else {
                    Write-Host "  [MANTIDO] Nenhuma chave foi removida." -ForegroundColor DarkGray
                }
            }
            Pause-Cyber
        }

        elseif ($opL -eq "3") {
            Write-Host "`n  [TALIA // Edgerunners 2]: `"Varrendo %APPDATA%, %LOCALAPPDATA%, LocalLow e ProgramData por sobras de programas...`"" -ForegroundColor Red
            Write-Host "  (Pastas do Windows, Microsoft, drivers, navegadores e programas instalados sao protegidas automaticamente)" -ForegroundColor DarkGray
            $folders = @(Get-OrphanAppDataFolders)
            if ($folders.Count -eq 0) {
                Write-Host "  [OK] Nenhuma pasta orfa suspeita encontrada em %APPDATA% / %LOCALAPPDATA% / ProgramData!" -ForegroundColor Green
            } else {
                $totalMB = [math]::Round(($folders | Measure-Object -Property TamanhoMB -Sum).Sum, 2)
                Write-Host "`n  [CANDIDATAS] $($folders.Count) pasta(s) nao associada(s) a apps instalados (Total: $totalMB MB):" -ForegroundColor Yellow
                Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
                for ($i = 0; $i -lt $folders.Count; $i++) {
                    $f = $folders[$i]
                    Write-Host ("  [{0,2}] {1,-17} | {2,-26} | {3,7} MB | Mod: {4}" -f ($i + 1), $f.Local, $f.Nome, $f.TamanhoMB, $f.UltimaMod) -ForegroundColor White
                }
                Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
                Write-Host '  [JOHNNY SILVERHAND // CP2077]: "Cuidado! Confira bem antes de apagar - alguns jogos/apps portateis guardam saves aqui."' -ForegroundColor Red
                Write-Host "  - Digite os NUMEROS separados por virgula (ex: 1,4,6)" -ForegroundColor Cyan
                Write-Host "  - Digite um INTERVALO com '-' (ex: 1-10) ou '1-$($folders.Count)' para remover do 1o ao ultimo" -ForegroundColor Cyan
                Write-Host "  - Aperte ENTER direto (ou digite 'T') para remover TODAS as $($folders.Count) pastas" -ForegroundColor Yellow
                Write-Host "  - Digite 'C' ou 'N' para CANCELAR e nao apagar nada:" -ForegroundColor DarkGray
                $sel = (Read-Host "Pastas para remover").Trim()

                $selectedIndices = New-Object System.Collections.Generic.List[int]
                $cancelled = $false

                if ($sel -match "^(?i:[cCnN])$") {
                    $cancelled = $true
                } elseif ([string]::IsNullOrWhiteSpace($sel) -or ($sel -match "^(?i:[tT])$")) {
                    for ($idx = 1; $idx -le $folders.Count; $idx++) { [void]$selectedIndices.Add($idx) }
                } else {
                    foreach ($tok in ($sel -split ',')) {
                        $t = $tok.Trim()
                        if (-not $t) { continue }
                        if ($t -match '^(\d+)\s*-\s*(\d+)$') {
                            $a = [int]$matches[1]
                            $b = [int]$matches[2]
                            if ($a -le $b) {
                                for ($k = $a; $k -le $b; $k++) {
                                    if ($k -ge 1 -and $k -le $folders.Count) { [void]$selectedIndices.Add($k) }
                                }
                            } else {
                                for ($k = $a; $k -ge $b; $k--) {
                                    if ($k -ge 1 -and $k -le $folders.Count) { [void]$selectedIndices.Add($k) }
                                }
                            }
                        } else {
                            $n = 0
                            if ([int]::TryParse($t, [ref]$n) -and $n -ge 1 -and $n -le $folders.Count) {
                                [void]$selectedIndices.Add($n)
                            }
                        }
                    }
                    if ($selectedIndices.Count -eq 0) { $cancelled = $true }
                }

                $uniqueIndices = @($selectedIndices | Select-Object -Unique)

                if (-not $cancelled -and $uniqueIndices.Count -gt 0) {
                    $proceed = $true
                    if ($uniqueIndices.Count -ge 20 -or ([string]::IsNullOrWhiteSpace($sel) -or ($sel -match "^(?i:[tT])$"))) {
                        Write-Host "`n  [ATENCAO] Voce selecionou $($uniqueIndices.Count) pasta(s) para remocao em lote!" -ForegroundColor Red
                        $confBulk = (Read-Host "Confirma apagar $($uniqueIndices.Count) pasta(s) agora? [S/N]").Trim()
                        if ($confBulk -notmatch "^(?i:s)$") { $proceed = $false }
                    }

                    if ($proceed) {
                        $removed = 0
                        $totalSel = $uniqueIndices.Count
                        $cur = 0
                        foreach ($idxNum in $uniqueIndices) {
                            $cur++
                            $target = $folders[$idxNum - 1]
                            Write-Host ("  [{0}/{1}] (#{2}) Removendo: {3} ({4} MB)..." -f $cur, $totalSel, $idxNum, $target.Caminho, $target.TamanhoMB) -ForegroundColor Yellow
                            try {
                                Remove-Item -LiteralPath $target.Caminho -Recurse -Force -ErrorAction Stop
                                Write-Host "    [OK] Pasta removida." -ForegroundColor Green
                                $removed++
                            } catch {
                                Write-Host "    [AVISO] Nao foi possivel apagar completamente (pode estar em uso): $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                        Write-Host "`n  [CONCLUIDO] $removed de $totalSel pasta(s) removida(s)." -ForegroundColor Green
                    } else {
                        Write-Host "  [CANCELADO] Nenhuma pasta foi removida." -ForegroundColor DarkGray
                    }
                } else {
                    Write-Host "  [MANTIDO] Nenhuma pasta foi removida." -ForegroundColor DarkGray
                }
            }
            Pause-Cyber
        }

        elseif ($opL -eq "4") {
            Write-Host "`n  [ALT CUNNINGHAM // CP2077]: `"Executando varredura completa somente-leitura no Regedit e no disco...`"" -ForegroundColor Red
            $uList = @(Get-OrphanUninstallEntries)
            $mList = @(Get-OrphanAppPathsAndMui)
            $fList = @(Get-OrphanAppDataFolders)
            $fMB = if ($fList.Count -gt 0) { [math]::Round(($fList | Measure-Object -Property TamanhoMB -Sum).Sum, 2) } else { 0 }

            Write-Host "`n========================================================================" -ForegroundColor Cyan
            Write-Host "  RESUMO DA VARREDURA DE SOBRAS DE PROGRAMAS DESINSTALADOS" -ForegroundColor White
            Write-Host "========================================================================" -ForegroundColor Cyan
            Write-Host "  1) Regedit (Uninstall orfaos):           $($uList.Count) registro(s)" -ForegroundColor Yellow
            Write-Host "  2) Regedit (App Paths / MuiCache):       $($mList.Count) registro(s)" -ForegroundColor Cyan
            Write-Host "  3) Pastas candidatas (%APPDATA%/Outros): $($fList.Count) pasta(s) (~$fMB MB)" -ForegroundColor Magenta
            Write-Host "========================================================================" -ForegroundColor Cyan

            $saveRep = Read-Host "Deseja salvar este relatorio detalhado em .txt na Area de Trabalho? [S/N]"
            if ($saveRep -match "^[sS]$") {
                $repDir = Get-DesktopDatedDadosDir -SubFolder "RELATORIOS_LIMPEZA_REGISTRO"
                $repPath = Join-Path $repDir "RELATORIO_REGISTROS_E_PASTAS_ORFAS_$(Get-Date -Format 'dd-MM-yyyy_HHmm').txt"
                $lines = New-Object System.Collections.Generic.List[string]
                $lines.Add("========================================================================")
                $lines.Add("  CYBERDECK OS // RELATORIO DE SOBRAS DE PROGRAMAS DESINSTALADOS")
                $lines.Add("========================================================================")
                $lines.Add("Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')")
                $lines.Add("")
                $lines.Add("--- [1] REGEDIT: UNINSTALL ORFAOS ($($uList.Count)) ---")
                foreach ($x in $uList) { $lines.Add("  * $($x.Nome) | $($x.RegPath) | $($x.Motivo)") }
                $lines.Add("")
                $lines.Add("--- [2] REGEDIT: APP PATHS & MUICACHE ORFAOS ($($mList.Count)) ---")
                foreach ($x in $mList) { $lines.Add("  * [$($x.Tipo)] $($x.Nome) | $($x.Motivo)") }
                $lines.Add("")
                $lines.Add("--- [3] PASTAS CANDIDATAS EM %APPDATA% / %LOCALAPPDATA% / PROGRAMDATA ($($fList.Count) | ~$fMB MB) ---")
                foreach ($x in $fList) { $lines.Add("  * [$($x.Local)] $($x.Caminho) ($($x.TamanhoMB) MB | Mod: $($x.UltimaMod))") }
                Set-Content -Path $repPath -Value $lines -Encoding UTF8
                $repDados = Sync-FileToProjectDados -SourceFile $repPath -SubFolder "RELATORIOS_LIMPEZA_REGISTRO"
                Write-Host "  [OK] Relatorio salvo na Area de Trabalho: $repPath" -ForegroundColor Green
                if ($repDados) { Write-Host "  [OK] Copia portatil salva no Projeto (Pen Drive / SSD): $repDados" -ForegroundColor Cyan }
            }
            Pause-Cyber
        }
    }
}

function Invoke-Op15 {
    while ($true) {
        Clear-Host
        Show-BootBanner "[16] OVERCLOCK NEURAL // OTIMIZACAO + LIMPEZA DE REGISTROS E %APPDATA%"
        Write-Host '  [DAVID MARTINEZ // Edgerunners 1]: "Escolha se quer calibrar o Windows (7 etapas) ou limpar restos de apps ja desinstalados."' -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Auditoria Interativa de Otimizacao (7 Etapas: Game Mode, DVR, RAM, Menus, P2P, SSD)" -ForegroundColor Magenta
        Write-Host "  [2] Limpeza Profunda de Registros Velhos (Regedit) e Pastas Orfas (%APPDATA% / Windows)" -ForegroundColor Cyan
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Magenta
        $subOpt = Read-Host "Escolha [0-2]"
        if ($subOpt -eq "0") { break }
        elseif ($subOpt -eq "2") { Invoke-CleanOrphanRegistryAndFiles }
        elseif ($subOpt -eq "1") {
        # 1. Game Mode (David)
        $o1 = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name AutoGameModeEnabled -ErrorAction Stop).AutoGameModeEnabled } catch { 0 }
        Invoke-StepToggle "[1/7] DESEMPENHO: Modo de Jogo (Game Mode)" ($o1 -ne 1) "DESATIVADO" "ATIVADO (OTIMIZADO)" `
            "[DAVID MARTINEZ // Edgerunners 1]" "Yellow" "Foca CPU/GPU no jogo e pausa tarefas chatas do Windows Update durante partidas." `
            "Prioriza recursos para jogos em tela cheia." `
            "Em raros casos com OBS/lives, pode reduzir levemente prioridade do app em segundo plano." `
            "Desliga o Modo de Jogo." `
            { reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f | Out-Null; reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f | Out-Null } `
            { reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 0 /f | Out-Null; reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f | Out-Null }

        # 2. Game DVR (Judy)
        $o2 = try { (Get-ItemProperty 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -ErrorAction Stop).GameDVR_Enabled } catch { 1 }
        Invoke-StepToggle "[2/7] VIDEO / FPS: Xbox Game DVR (Gravacao Fundo)" ($o2 -ne 0) "ATIVO - CONSUMINDO GPU" "DESATIVADO (OTIMIZADO)" `
            "[JUDY ALVAREZ // Cyberpunk 2077]" "Cyan" "Deixar o Game DVR rodando por baixo rouba ciclos do codificador da GPU e gera stuttering." `
            "Desativa captura em segundo plano da Xbox Game Bar." `
            "Perde gravacao rapida nativa do Win+G. OBS Studio e NVIDIA ShadowPlay continuam normais." `
            "Reativa o Xbox Game DVR." `
            { reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f | Out-Null; reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f | Out-Null } `
            { reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f | Out-Null; reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /f 2>$null | Out-Null }

        # 3. Background Apps (Talia)
        $o3 = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name GlobalUserDisabled -ErrorAction Stop).GlobalUserDisabled } catch { 0 }
        Invoke-StepToggle "[3/7] MEMORIA RAM: Apps UWP da Store em Segundo Plano" ($o3 -ne 1) "ATIVOS" "DESATIVADOS (RAM POUPADA)" `
            "[TALIA // Edgerunners 2]" "Red" "Apps da Microsoft Store ficam acordados comendo RAM mesmo fechados." `
            "Impede apps UWP (Clima, Noticias, Fotos) de rodar fechados." `
            "Notificacoes de apps da Store so atualizam ao abrir. Discord/Steam/Navegador nao mudam." `
            "Permite novamente apps da Store em segundo plano." `
            { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f | Out-Null } `
            { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 1 /f | Out-Null }

        # 4. MenuShowDelay (Viktor)
        $o4 = try { [int](Get-ItemProperty 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -ErrorAction Stop).MenuShowDelay } catch { 400 }
        Invoke-StepToggle "[4/7] INTERFACE: Atraso de Menus (MenuShowDelay) e Dicas" ($o4 -gt 100) "PADRAO (400ms)" "OTIMIZADO (100ms)" `
            "[VIKTOR VEKTOR // Cyberpunk 2077]" "Green" "Baixar o atraso de submenus de 400ms para 100ms deixa a interface bem mais agil." `
            "Acelera abertura de submenus e remove dicas automaticas do Windows." `
            "Nenhum impacto negativo." `
            "Volta para 400ms e reativa dicas." `
            { reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 100 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null } `
            { reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f | Out-Null; reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 1 /f | Out-Null }

        # 5. Transparency (Rebecca)
        $o5 = try { (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name EnableTransparency -ErrorAction Stop).EnableTransparency } catch { 1 }
        Invoke-StepToggle "[5/7] VISUAL / GPU: Efeitos de Transparencia" ($o5 -ne 0) "ATIVO (BLUR LIGADO)" "DESATIVADO (CORES SOLIDAS)" `
            "[REBECCA // Edgerunners 1]" "Cyan" "Efeitos de vidro borrado usam GPU a toa. Desligar deixa o desktop seco e direto." `
            "Desativa desfoque/transparencia na Barra de Tarefas e Menu Iniciar." `
            "Apenas estetico: barra fica com cor solida." `
            "Devolve o efeito translucido." `
            { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f | Out-Null } `
            { reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f | Out-Null }

        # 6. Delivery Optimization P2P (Panam)
        $o6 = try { (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name DODownloadMode -ErrorAction Stop).DODownloadMode } catch { 1 }
        Invoke-StepToggle "[6/7] REDE: Otimizacao de Entrega P2P (Windows Update)" ($o6 -ne 0) "ATIVO (P2P LIGADO)" "DESATIVADO (DIRETO)" `
            "[PANAM PALMER // Cyberpunk 2077]" "Yellow" "A Microsoft usa sua banda como servidor torrent para enviar updates para outros PCs." `
            "Desativa P2P do Windows Update e limpa cache de entrega." `
            "Se tiver varios PCs na mesma casa, cada um baixa direto da internet. Otimo para ping." `
            "Reativa o P2P na rede local." `
            { reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f | Out-Null; Delete-DeliveryOptimizationCache -Force -ErrorAction SilentlyContinue | Out-Null } `
            { reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /f 2>$null | Out-Null }

        # 7. Hibernation (Roman Carax)
        $o7 = Test-Path "C:\hiberfil.sys"
        Invoke-StepToggle "[7/7] SSD: Hibernacao do Windows (hiberfil.sys)" $o7 "ATIVA (OCUPANDO GB NO SSD)" "DESATIVADA (ESPACO LIBERADO)" `
            "[ROMAN CARAX // Edgerunners 2]" "Magenta" "A hibernacao reserva varios GBs do SSD para congelar a RAM. Em Desktop, quase sempre e desperdicio." `
            "Desativa hibernacao e apaga C:\hiberfil.sys." `
            "Remove 'Hibernar' e Fast Startup (em SSD o boot continua rapido e mais limpo; em notebooks pode fazer falta)." `
            "Recria C:\hiberfil.sys e devolve Hibernar." `
            { powercfg -h off } `
            { powercfg -h on }
        }
    }
}

function Invoke-Op16 {
    Clear-Host
    Show-BootBanner "[03] GERENCIADOR DE DISPOSITIVOS: DRIVERS"
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Escaneando dispositivos com erro ou triangulo amarelo..."' -ForegroundColor Green
    $bad = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
    if ($bad) {
        Write-Host "`n  [ALERTA] Dispositivos com problema detectados:" -ForegroundColor Red
        $bad | Select-Object Name, PNPClass, ConfigManagerErrorCode, DeviceID | Format-Table -Wrap -AutoSize
        Write-Host '  [JUDY ALVAREZ // CP2077]: "Encontrei dispositivos com erro/driver faltando ai em cima."' -ForegroundColor Cyan
    } else {
        Write-Host "`n  [OK] Nenhum dispositivo com erro ou triangulo amarelo detectado." -ForegroundColor Green
        Write-Host '  [V // CP2077]: "Todos os drivers do Gerenciador de Dispositivos estao OK."' -ForegroundColor Cyan
    }
    while ($true) {
        Write-Host "`n========================================================================" -ForegroundColor Cyan
        Write-Host "  ACOES PARA DRIVERS E GERENCIADOR DE DISPOSITIVOS:" -ForegroundColor White
        Write-Host "  [1] Re-escanear Hardware (pnputil /scan-devices)" -ForegroundColor Cyan
        Write-Host "  [2] Tentar Corrigir / Reiniciar Dispositivos com Erro" -ForegroundColor Yellow
        Write-Host "  [3] Buscar Atualizacoes de Drivers via Windows Update" -ForegroundColor Green
        Write-Host "  [4] Abrir Gerenciador de Dispositivos (devmgmt.msc)" -ForegroundColor Magenta
        Write-Host "  [0] Voltar" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Cyan
        $d = Read-Host "Acao [0-4]"
        if ($d -eq "1") {
            Write-Host '  [CAPRI // Edgerunners 2]: "Forcando nova leitura Plug and Play..."' -ForegroundColor Cyan
            pnputil /scan-devices
        } elseif ($d -eq "2") {
            Write-Host '  [TALIA // Edgerunners 2]: "Reiniciando dispositivos com erro..."' -ForegroundColor Red
            $errDevs = Get-PnpDevice | Where-Object { $_.Status -eq 'Error' -or $_.Status -eq 'Degraded' }
            if (-not $errDevs) { Write-Host "  [OK] Nenhum dispositivo em estado de erro." -ForegroundColor Green }
            else {
                foreach ($dev in $errDevs) {
                    Write-Host "  Reiniciando: $($dev.FriendlyName)" -ForegroundColor Yellow
                    try {
                        Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 1
                        Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
                        Write-Host "    [OK] Reiniciado." -ForegroundColor Green
                    } catch {
                        Write-Host "    [AVISO] Pode exigir driver do fabricante: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                pnputil /scan-devices | Out-Null
            }
        } elseif ($d -eq "3") {
            Write-Host '  [PANAM PALMER // CP2077]: "Consultando catalogo de drivers do Windows Update..."' -ForegroundColor Yellow
            try {
                $sess = New-Object -ComObject Microsoft.Update.Session
                $res = $sess.CreateUpdateSearcher().Search("IsInstalled=0 and Type='Driver'")
                if ($res.Updates.Count -eq 0) { Write-Host "  [OK] Nenhum driver pendente no Windows Update." -ForegroundColor Green }
                else {
                    Write-Host "  [ENCONTRADOS] $($res.Updates.Count) driver(s):" -ForegroundColor Yellow
                    foreach ($u in $res.Updates) { Write-Host "    - $($u.Title)" -ForegroundColor White }
                }
            } catch { Write-Host "  [AVISO] $($_.Exception.Message)" -ForegroundColor Yellow }
            Start-Process "ms-settings:windowsupdate-optionalupdates"
        } elseif ($d -eq "4") {
            Write-Host '  [GORO TAKEMURA // CP2077]: "Abrindo Gerenciador de Dispositivos..."' -ForegroundColor White
            Start-Process devmgmt.msc
        } elseif ($d -eq "0") {
            break
        }
    }
}


function Convert-ChromeTimeToUnix {
    param([string]$ChromeTime)
    try {
        $val = [int64]$ChromeTime
        if ($val -le 0) { return [int64][DateTimeOffset]::UtcNow.ToUnixTimeSeconds() }
        $unix = [math]::Floor(($val / 1000000) - 11644473600)
        if ($unix -lt 0) { return 0 }
        return [int64]$unix
    } catch {
        return [int64][DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }
}

function Export-ChromiumBookmarksHtml {
    param([string]$BookmarksJsonPath, [string]$OutHtmlPath)
    try {
        $json = Get-Content -Path $BookmarksJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine('<!DOCTYPE NETSCAPE-Bookmark-file-1>')
        [void]$sb.AppendLine('<!-- Exportado pelo CyberDeck OS preservando datas originais -->')
        [void]$sb.AppendLine('<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">')
        [void]$sb.AppendLine('<TITLE>Bookmarks</TITLE>')
        [void]$sb.AppendLine('<H1>Bookmarks</H1>')
        [void]$sb.AppendLine('<DL><p>')

        function Write-BmNode($node, $indent) {
            if (-not $node) { return }
            $pad = "    " * $indent
            if ($node.type -eq "folder") {
                $addDate = Convert-ChromeTimeToUnix $node.date_added
                $modDate = Convert-ChromeTimeToUnix $node.date_modified
                $title = [System.Net.WebUtility]::HtmlEncode([string]$node.name)
                [void]$sb.AppendLine("$pad<DT><H3 ADD_DATE=`"$addDate`" LAST_MODIFIED=`"$modDate`">$title</H3>")
                [void]$sb.AppendLine("$pad<DL><p>")
                if ($node.children) {
                    foreach ($child in $node.children) { Write-BmNode $child ($indent + 1) }
                }
                [void]$sb.AppendLine("$pad</DL><p>")
            } elseif ($node.type -eq "url") {
                $addDate = Convert-ChromeTimeToUnix $node.date_added
                $url = [System.Net.WebUtility]::HtmlEncode([string]$node.url)
                $title = [System.Net.WebUtility]::HtmlEncode([string]$node.name)
                [void]$sb.AppendLine("$pad<DT><A HREF=`"$url`" ADD_DATE=`"$addDate`">$title</A>")
            }
        }

        if ($json.roots) {
            foreach ($prop in $json.roots.PSObject.Properties) {
                if ($prop.Value -and $prop.Value.children) {
                    Write-BmNode $prop.Value 1
                }
            }
        }
        [void]$sb.AppendLine('</DL><p>')
        Set-Content -Path $OutHtmlPath -Value $sb.ToString() -Encoding UTF8
        return $true
    } catch {
        return $false
    }
}

function Resolve-BrowserExe {
    param(
        [string]$ExeName,
        [string[]]$CandidatePaths
    )
    foreach ($p in $CandidatePaths) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    $cmd = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { return $cmd.Source }
    foreach ($regRoot in @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName", "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\$ExeName")) {
        if (Test-Path $regRoot) {
            $val = (Get-ItemProperty -Path $regRoot -ErrorAction SilentlyContinue).'(default)'
            if ($val -and (Test-Path $val)) { return $val }
        }
    }
    return $null
}

function Open-BrowserPasswordPage {
    param(
        [string]$ExeName,
        [string[]]$CandidatePaths,
        [string]$PassUrl
    )
    $resolvedExe = Resolve-BrowserExe -ExeName $ExeName -CandidatePaths $CandidatePaths
    try { Set-Clipboard -Value $PassUrl -ErrorAction SilentlyContinue } catch {}

    # Para Chromium/Edge quando o navegador ja esta rodando, abrir --new-tab ou --profile-directory
    # ajuda a abrir a URL direto na aba; se ainda assim abrir "Nova guia", usamos UI Automation
    # para focar a barra de endereco, colar a URL e pressionar ENTER automaticamente.
    if ($resolvedExe) {
        if ($ExeName -eq "msedge.exe") {
            Start-Process -FilePath $resolvedExe -ArgumentList @("--new-tab", $PassUrl) -ErrorAction Stop
        } else {
            Start-Process -FilePath $resolvedExe -ArgumentList @($PassUrl) -ErrorAction Stop
        }
    } else {
        Start-Process -FilePath $PassUrl -ErrorAction Stop
    }

    Start-Sleep -Milliseconds 1200

    # Tentativa segura via UI Automation para focar a barra de enderecos (Ctrl+L) e navegar para $PassUrl
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $wshell = New-Object -ComObject WScript.Shell
        $procName = if ($resolvedExe) { [System.IO.Path]::GetFileNameWithoutExtension($resolvedExe) } else { "msedge" }
        $targetProc = Get-Process -Name $procName -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
        if ($targetProc) {
            $null = $wshell.AppActivate($targetProc.Id)
            Start-Sleep -Milliseconds 300
            Set-Clipboard -Value $PassUrl
            [System.Windows.Forms.SendKeys]::SendWait("^l")
            Start-Sleep -Milliseconds 250
            [System.Windows.Forms.SendKeys]::SendWait("^v")
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        }
    } catch {}

    return $true
}

function Write-BrowserFolderGuides {
    param(
        [string]$FolderPath,
        [hashtable]$BrowserInfo,
        [string[]]$PerfisSalvos,
        [string]$DataHoje
    )
    $listaPerfis = if ($PerfisSalvos -and $PerfisSalvos.Count -gt 0) { ($PerfisSalvos -join ", ") } else { $env:USERNAME }

    $favTxt = Join-Path $FolderPath "COMO EXPORTAR E IMPORTAR FAVORITOS - $($BrowserInfo.Nome).txt"
    $favLines = @(
        "========================================================================",
        "  CYBERDECK OS // FAVORITOS - $($BrowserInfo.Nome.ToUpper())",
        "========================================================================",
        "Data do backup:     $DataHoje",
        "Perfis detectados:  $listaPerfis",
        "Arquivos gerados:   Favoritos <Perfil> - $($BrowserInfo.Nome) - $DataHoje.html (e .json/.sqlite)",
        "",
        "!!! SALVE ESTA PASTA ANTES DE FORMATAR O PC !!!",
        "------------------------------------------------------------------------",
        "Copie a pasta 'BACKUP DADOS NAVEGADORES' para um Pendrive, HD Externo,",
        "outra particao (D:/E:) ou Nuvem antes de formatar o Windows.",
        "",
        "COMO EXPORTAR MANUALMENTE SE PRECISAR:",
        "  $($BrowserInfo.ExportFavStep)",
        "",
        "COMO IMPORTAR / RESTAURAR APOS FORMATAR:",
        "  $($BrowserInfo.BmStep)",
        "  -> Selecione o arquivo 'Favoritos <Perfil> - $($BrowserInfo.Nome) - $DataHoje.html'",
        "     nesta pasta ($($BrowserInfo.Pasta)\). As datas originais sao preservadas.",
        "========================================================================"
    )
    Set-Content -Path $favTxt -Value $favLines -Encoding UTF8

    $pwTxt = Join-Path $FolderPath "COMO EXPORTAR E IMPORTAR SENHAS - $($BrowserInfo.Nome).txt"
    $pwLines = @(
        "========================================================================",
        "  CYBERDECK OS // SENHAS SALVAS - $($BrowserInfo.Nome.ToUpper())",
        "========================================================================",
        "Data do backup:     $DataHoje",
        "Aba de senhas:      $($BrowserInfo.PassUrl)",
        "Nome sugerido .csv: $($env:USERNAME) senhas - $($BrowserInfo.Nome).csv",
        "",
        "POR QUE NAO E EXPORTADO SILENCIOSAMENTE:",
        "  O Windows protege as senhas dos navegadores com criptografia vinculada",
        "  a instalacao atual (DPAPI / App-Bound Encryption). Por isso, o script",
        "  abre a aba de senhas e a pasta para voce exportar o .csv com seu",
        "  PIN ou Senha do Windows.",
        "",
        "COMO EXPORTAR O .CSV AGORA:",
        "  1) Abra ou va para a aba: $($BrowserInfo.PassUrl)",
        "  2) Clique no menu '...' (ou 'Mais configuracoes' / 'Exportar senhas').",
        "  3) Se o Windows pedir seu PIN ou Senha, digite para confirmar.",
        "  4) Salve o arquivo dentro desta pasta: $($BrowserInfo.Pasta)\",
        "     com o nome: $($env:USERNAME) senhas - $($BrowserInfo.Nome).csv",
        "",
        "COMO IMPORTAR APOS FORMATAR:",
        "  $($BrowserInfo.PassStep)",
        "  -> DICA: Depois de importar no Windows novo, apague o .csv por seguranca.",
        "========================================================================"
    )
    Set-Content -Path $pwTxt -Value $pwLines -Encoding UTF8

    $profTxt = Join-Path $FolderPath "COMO EXPORTAR E IMPORTAR PERFIL - $($BrowserInfo.Nome).txt"
    $profLines = @(
        "========================================================================",
        "  CYBERDECK OS // PERFIL COMPLETO - $($BrowserInfo.Nome.ToUpper())",
        "========================================================================",
        "Data do backup:     $DataHoje",
        "Perfis salvos:      $listaPerfis",
        "Pasta origem:       $($BrowserInfo.RestorePath)",
        "",
        "O QUE ESTE BACKUP DE PERFIL CONTEM:",
        "  Extensoes, favoritos, historico, preferencias e configuracoes do",
        "  perfil (pastas de cache pesado como Cache e GPUCache sao ignoradas",
        "  para deixar o backup mais leve e rapido).",
        "",
        "COMO RESTAURAR APOS FORMATAR:",
        "  1) Instale e abra o $($BrowserInfo.Nome) uma vez no Windows novo, depois FECHE-O.",
        "  2) Pressione Win+R, cole o caminho abaixo e pressione ENTER:",
        "     $($BrowserInfo.RestorePath)",
        "  3) $($BrowserInfo.ProfNote)",
        "========================================================================"
    )
    Set-Content -Path $profTxt -Value $profLines -Encoding UTF8
}

function Invoke-Op17 {
    Clear-Host
    Show-BootBanner "[17] BACKUP DE DADOS DOS NAVEGADORES (FAVORITOS, PERFIS E SENHAS)"
    Write-Host '  [LUCY // Edgerunners 1]: "Varrendo todos os navegadores instalados e perfis de usuario..."' -ForegroundColor Cyan
    Write-Host '  [CAPRI // Edgerunners 2]: "Gerando favoritos, perfis, guias .txt dentro de cada pasta e exportacao de senhas."' -ForegroundColor Cyan
    Write-Host ""

    $dataHoje = Get-Date -Format "dd-MM-yyyy"
    $baseDir = Get-DesktopDatedDadosDir -SubFolder "BACKUP DADOS NAVEGADORES"

    $browsers = @(
        @{
            Nome="Chrome"; Pasta="CHROME"; Exe="chrome.exe"
            ExePaths=@(
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
            )
            UserData="$env:LOCALAPPDATA\Google\Chrome\User Data"
            RestorePath='%LOCALAPPDATA%\Google\Chrome\User Data'
            PassUrl="chrome://password-manager/settings"
            ExportFavStep="No Chrome, abra chrome://bookmarks -> menu (3 pontinhos) -> Exportar favoritos."
            BmStep="Abra o Chrome -> menu (3 pontinhos) -> Favoritos e listas -> Importar favoritos e configuracoes -> 'Arquivo HTML de favoritos'."
            PassStep="Digite 'chrome://password-manager/settings' na barra de enderecos -> clique em 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Chrome' para dentro da pasta 'Default' (ou 'Profile 1') do Chrome novo."
        },
        @{
            Nome="Edge"; Pasta="EDGE"; Exe="msedge.exe"
            ExePaths=@(
                "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
                "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
            )
            UserData="$env:LOCALAPPDATA\Microsoft\Edge\User Data"
            RestorePath='%LOCALAPPDATA%\Microsoft\Edge\User Data'
            PassUrl="edge://settings/autofill/passwords"
            ExportFavStep="No Edge, pressione Ctrl+Shift+O (ou abra edge://favorites) -> menu (...) -> Exportar favoritos."
            BmStep="Abra o Edge -> menu (...) -> Favoritos -> menu (...) -> Importar favoritos -> 'Arquivo HTML de favoritos ou marcadores'."
            PassStep="Digite 'edge://settings/autofill/passwords' na barra de enderecos -> menu (...) -> 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Edge' para dentro da pasta 'Default' (ou 'Profile 1') do Edge novo."
        },
        @{
            Nome="Brave"; Pasta="BRAVE"; Exe="brave.exe"
            ExePaths=@(
                "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
                "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
            )
            UserData="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
            RestorePath='%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data'
            PassUrl="brave://password-manager/settings"
            ExportFavStep="No Brave, abra brave://bookmarks -> menu (3 pontinhos) -> Exportar favoritos."
            BmStep="Abra o Brave -> menu (3 linhas) -> Favoritos -> Importar favoritos e configuracoes -> 'Arquivo HTML de favoritos'."
            PassStep="Digite 'brave://password-manager/settings' na barra de enderecos -> 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Brave' para dentro da pasta 'Default' (ou 'Profile 1') do Brave novo."
        },
        @{
            Nome="Opera"; Pasta="OPERA"; Exe="opera.exe"
            ExePaths=@(
                "$env:LOCALAPPDATA\Programs\Opera\opera.exe",
                "$env:ProgramFiles\Opera\opera.exe"
            )
            UserData="$env:APPDATA\Opera Software\Opera Stable"
            RestorePath='%APPDATA%\Opera Software\Opera Stable'
            PassUrl="opera://password-manager/settings"
            ExportFavStep="No Opera, abra opera://bookmarks -> exportar favoritos."
            BmStep="Abra o Opera -> menu (icone O) -> Favoritos -> Importar favoritos e configuracoes -> 'Arquivo HTML de favoritos'."
            PassStep="Digite 'opera://password-manager/settings' na barra de enderecos -> 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Opera' diretamente para dentro de '%APPDATA%\Opera Software\Opera Stable'."
        },
        @{
            Nome="Opera GX"; Pasta="OPERA GX"; Exe="opera.exe"
            ExePaths=@(
                "$env:LOCALAPPDATA\Programs\Opera GX\opera.exe",
                "$env:ProgramFiles\Opera GX\opera.exe"
            )
            UserData="$env:APPDATA\Opera Software\Opera GX Stable"
            RestorePath='%APPDATA%\Opera Software\Opera GX Stable'
            PassUrl="opera://password-manager/settings"
            ExportFavStep="No Opera GX, abra opera://bookmarks -> exportar favoritos."
            BmStep="Abra o Opera GX -> menu (icone O) -> Favoritos -> Importar favoritos e configuracoes -> 'Arquivo HTML de favoritos'."
            PassStep="Digite 'opera://password-manager/settings' na barra de enderecos -> 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Opera GX' diretamente para dentro de '%APPDATA%\Opera Software\Opera GX Stable'."
        },
        @{
            Nome="Vivaldi"; Pasta="VIVALDI"; Exe="vivaldi.exe"
            ExePaths=@(
                "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe",
                "$env:ProgramFiles\Vivaldi\Application\vivaldi.exe"
            )
            UserData="$env:LOCALAPPDATA\Vivaldi\User Data"
            RestorePath='%LOCALAPPDATA%\Vivaldi\User Data'
            PassUrl="vivaldi://password-manager/settings"
            ExportFavStep="No Vivaldi, abra vivaldi://bookmarks ou Arquivo -> Exportar -> Exportar favoritos."
            BmStep="Abra o Vivaldi -> menu (icone V) -> Arquivo -> Importar de aplicativos ou arquivos -> 'Arquivo HTML de favoritos'."
            PassStep="Digite 'vivaldi://password-manager/settings' na barra de enderecos -> clique em 'Importar senhas' -> selecione o arquivo .csv."
            ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Vivaldi' para dentro da pasta 'Default' (ou 'Profile 1') do Vivaldi novo."
        }
    )

    $encontrados = @()

    foreach ($b in $browsers) {
        if (-not (Test-Path $b.UserData)) { continue }
        $bDest = Join-Path $baseDir $b.Pasta
        if (-not (Test-Path $bDest)) { New-Item -ItemType Directory -Path $bDest -Force | Out-Null }

        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host "  [NAVEGADOR DETECTADO]: $($b.Nome)" -ForegroundColor Green
        Write-Host "========================================================================" -ForegroundColor Yellow

        $profileNamesMap = @{}
        $localStatePath = Join-Path $b.UserData "Local State"
        if (Test-Path $localStatePath) {
            try {
                $ls = Get-Content -Path $localStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($ls.profile -and $ls.profile.info_cache) {
                    foreach ($prop in $ls.profile.info_cache.PSObject.Properties) {
                        $friendly = $prop.Value.name
                        if (-not $friendly) { $friendly = $prop.Value.gaia_given_name }
                        if ($friendly) { $profileNamesMap[$prop.Name] = ($friendly -replace '[\\/:*?"<>|]', '').Trim() }
                    }
                }
            } catch {}
        }

        $profileDirs = @()
        if (Test-Path (Join-Path $b.UserData "Bookmarks")) {
            $profileDirs += Get-Item $b.UserData
        } else {
            $profileDirs += Get-ChildItem -Path $b.UserData -Directory -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -eq "Default" -or $_.Name -like "Profile *"
            }
        }

        if ($profileDirs.Count -eq 0) {
            Write-Host "  [INFO] Nenhum perfil com dados encontrado em $($b.Nome)." -ForegroundColor DarkGray
            continue
        }

        $perfisSalvos = @()

        foreach ($pDir in $profileDirs) {
            $pKey = $pDir.Name
            $userLabel = if ($profileNamesMap.ContainsKey($pKey) -and $profileNamesMap[$pKey]) { $profileNamesMap[$pKey] } else { $env:USERNAME }
            if ($profileDirs.Count -gt 1 -and (-not $profileNamesMap.ContainsKey($pKey))) {
                $userLabel = "$($env:USERNAME) ($pKey)"
            }
            $perfisSalvos += $userLabel

            Write-Host "`n  -> Perfil detectado: $userLabel [$pKey]" -ForegroundColor Cyan

            $bmFile = Join-Path $pDir.FullName "Bookmarks"
            if (Test-Path $bmFile) {
                $htmlName = "Favoritos $userLabel - $($b.Nome) - $dataHoje.html"
                $htmlDest = Join-Path $bDest $htmlName
                $okHtml = Export-ChromiumBookmarksHtml -BookmarksJsonPath $bmFile -OutHtmlPath $htmlDest
                if ($okHtml) {
                    Write-Host "     [OK] Favoritos exportados (datas preservadas): $htmlName" -ForegroundColor Green
                } else {
                    Copy-Item -Path $bmFile -Destination (Join-Path $bDest "Favoritos $userLabel - $($b.Nome) - $dataHoje.json") -Force -ErrorAction SilentlyContinue
                    Write-Host "     [OK] Favoritos copiados em formato bruto." -ForegroundColor Yellow
                }
            } else {
                Write-Host "     [INFO] Sem arquivo de favoritos neste perfil." -ForegroundColor DarkGray
            }

            $profDestName = "$userLabel Perfil - $($b.Nome)"
            $profDestPath = Join-Path $bDest $profDestName
            if (-not (Test-Path $profDestPath)) { New-Item -ItemType Directory -Path $profDestPath -Force | Out-Null }
            Write-Host "     Copiando dados do perfil para '$profDestName' (pulando cache pesado)..." -ForegroundColor DarkGray
            $null = robocopy "$($pDir.FullName)" "$profDestPath" /E /XD "Cache" "Code Cache" "GPUCache" "Service Worker" "CacheStorage" "GrShaderCache" "ShaderCache" "OptimizationGuidePredictionModels" /R:0 /W:0 /NFL /NDL /NJH /NJS /NC /NS
            Write-Host "     [OK] Perfil salvo em: $profDestName" -ForegroundColor Green
        }

        Write-BrowserFolderGuides -FolderPath $bDest -BrowserInfo $b -PerfisSalvos $perfisSalvos -DataHoje $dataHoje
        Write-Host "  -> [OK] Guias .txt (Favoritos, Senhas e Perfil) salvos dentro de $($b.Pasta)\" -ForegroundColor Green

        $bCopy = $b.Clone()
        $bCopy["Perfis"] = $perfisSalvos
        $encontrados += $bCopy
    }

    # FIREFOX
    $ffRoot = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffRoot) {
        $ffProfs = Get-ChildItem -Path $ffRoot -Directory -ErrorAction SilentlyContinue
        if ($ffProfs.Count -gt 0) {
            $ffDest = Join-Path $baseDir "FIREFOX"
            if (-not (Test-Path $ffDest)) { New-Item -ItemType Directory -Path $ffDest -Force | Out-Null }
            Write-Host "========================================================================" -ForegroundColor Yellow
            Write-Host "  [NAVEGADOR DETECTADO]: Firefox" -ForegroundColor Green
            Write-Host "========================================================================" -ForegroundColor Yellow
            $ffLabels = @()
            foreach ($fp in $ffProfs) {
                $pLabel = "$($env:USERNAME) ($($fp.Name))"
                $ffLabels += $pLabel
                $profDestPath = Join-Path $ffDest "$pLabel Perfil - Firefox"
                $null = robocopy "$($fp.FullName)" "$profDestPath" /E /XD "cache2" "startupCache" "storage\temporary" /R:0 /W:0 /NFL /NDL /NJH /NJS /NC /NS
                $places = Join-Path $fp.FullName "places.sqlite"
                if (Test-Path $places) {
                    Copy-Item -Path $places -Destination (Join-Path $ffDest "Favoritos $pLabel - Firefox - $dataHoje.sqlite") -Force -ErrorAction SilentlyContinue
                }
                Write-Host "  -> [OK] Perfil e Favoritos do Firefox salvos: $pLabel" -ForegroundColor Green
            }
            $ffInfo = @{
                Nome="Firefox"; Pasta="FIREFOX"; Exe="firefox.exe"
                ExePaths=@(
                    "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
                    "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe"
                )
                RestorePath='%APPDATA%\Mozilla\Firefox\Profiles'
                PassUrl="about:logins"
                ExportFavStep="No Firefox, pressione Ctrl+Shift+B -> Importar e backup -> Exportar favoritos para HTML."
                BmStep="Pressione Ctrl+Shift+O (Biblioteca) -> Importar e backup -> Restaurar, OU copie o arquivo 'Favoritos <Nome> - Firefox - <Data>.sqlite' renomeando para 'places.sqlite' dentro do perfil novo."
                PassStep="Digite 'about:logins' na barra de enderecos -> menu (...) -> 'Importar de um arquivo...' -> selecione o arquivo .csv."
                ProfNote="Copie o conteudo da pasta '<Nome> Perfil - Firefox' para dentro da nova pasta de perfil criada em '%APPDATA%\Mozilla\Firefox\Profiles'."
                Perfis=$ffLabels
            }
            Write-BrowserFolderGuides -FolderPath $ffDest -BrowserInfo $ffInfo -PerfisSalvos $ffLabels -DataHoje $dataHoje
            Write-Host "  -> [OK] Guias .txt (Favoritos, Senhas e Perfil) salvos dentro de FIREFOX\" -ForegroundColor Green
            $encontrados += $ffInfo
        }
    }

    if ($encontrados.Count -eq 0) {
        Write-Host "  [AVISO] Nenhum navegador suportado encontrado neste perfil do Windows." -ForegroundColor Yellow
        Pause-Cyber
        return
    }

    # ETAPA DE EXPORTACAO DE SENHAS: ABRE NA TELA DE SENHAS DO NAVEGADOR E PREPARA O .CSV
    Write-Host "`n========================================================================" -ForegroundColor Magenta
    Write-Host "  [ETAPA DE SENHAS] EXPORTACAO VIA NAVEGADOR (COM PIN / SENHA DO WINDOWS)" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Magenta
    Write-Host '  [SONGBIRD // CP2077]: "O Windows bloqueia exportacao silenciosa de senhas por criptografia/DPAPI.' -ForegroundColor Magenta
    Write-Host '   Vou localizar cada navegador instalado, focar a janela e navegar direto para a aba' -ForegroundColor White
    Write-Host '   de senhas para voce exportar o .csv (digitando seu PIN/Senha do Windows se pedir)."' -ForegroundColor White
    Write-Host ""

    $expSenhas = Read-Host "Deseja abrir a aba de senhas dos navegadores instalados agora? [S/N]"
    if ($expSenhas -match "^[sS]$") {
        foreach ($b in $encontrados) {
            $bDest = Join-Path $baseDir $b.Pasta
            Write-Host "`n------------------------------------------------------------------------" -ForegroundColor Yellow
            Write-Host "  NAVEGADOR: $($b.Nome)  |  Aba alvo: $($b.PassUrl)" -ForegroundColor Green
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Abrindo a pasta de destino e navegando para a aba de senhas..."' -ForegroundColor Green
            Write-Host "  1. Na aba de senhas aberta, clique em 'Exportar senhas' (menu '...' ou Configuracoes)." -ForegroundColor White
            Write-Host "  2. Se o Windows solicitar seu PIN ou Senha, digite para confirmar." -ForegroundColor Yellow
            Write-Host "  3. Salve o .csv dentro da pasta aberta com o nome:" -ForegroundColor White
            Write-Host "     $($env:USERNAME) senhas - $($b.Nome).csv" -ForegroundColor Cyan

            Start-Process explorer.exe -ArgumentList "`"$bDest`""
            try {
                $null = Open-BrowserPasswordPage -ExeName $b.Exe -CandidatePaths $b.ExePaths -PassUrl $b.PassUrl
                Write-Host "  [OK] Navegador focado e aba de senhas aberta em $($b.PassUrl)." -ForegroundColor Green
            } catch {
                Write-Host "  [AVISO] Nao foi possivel abrir a aba automaticamente ($($_.Exception.Message))." -ForegroundColor Red
                Write-Host "  [TALIA // Edgerunners 2]: `"Abra o $($b.Nome) e va para: $($b.PassUrl)`"" -ForegroundColor Yellow
            }
            Read-Host "`nQuando concluir o .csv do $($b.Nome), pressione ENTER para continuar" | Out-Null
        }
    }

    # GERAR TUTORIAL DINAMICO BASEADO NOS NAVEGADORES DETECTADOS NA MAQUINA
    $tutPath = Join-Path $baseDir "TUTORIAL PARA RESTAURAR FAVORITOS, SENHAS E PERFIS.txt"
    $nomesDetectados = ($encontrados | ForEach-Object { $_.Nome }) -join ", "
    $tutLines = New-Object System.Collections.Generic.List[string]
    $tutLines.Add("========================================================================")
    $tutLines.Add("  CYBERDECK OS // TUTORIAL PERSONALIZADO DE RESTAURACAO DE NAVEGADORES")
    $tutLines.Add("========================================================================")
    $tutLines.Add("Data do backup:        $dataHoje")
    $tutLines.Add("Usuario do Windows:    $($env:USERNAME)")
    $tutLines.Add("Navegadores salvos:    $nomesDetectados")
    $tutLines.Add("")
    $tutLines.Add("!!! ATENCAO IMPORTANTE: SALVE ESTA PASTA ANTES DE FORMATAR O PC !!!")
    $tutLines.Add("------------------------------------------------------------------------")
    $tutLines.Add("Copie a pasta inteira 'BACKUP DADOS NAVEGADORES' para um Pendrive,")
    $tutLines.Add("HD Externo, outra particao (D:/E:) ou Nuvem ANTES de formatar!")
    $tutLines.Add("ATENCAO: O arquivo .csv de senhas contem suas senhas em texto legivel.")
    $tutLines.Add("Guarde-o em local seguro e apague o .csv apos importar no Windows novo.")
    $tutLines.Add("")
    $tutLines.Add("========================================================================")
    $tutLines.Add("  INSTRUCOES PERSONALIZADAS PARA OS NAVEGADORES DESTE PC")
    $tutLines.Add("========================================================================")

    foreach ($b in $encontrados) {
        $listaPerfis = ($b.Perfis -join ", ")
        $tutLines.Add("")
        $tutLines.Add("------------------------------------------------------------------------")
        $tutLines.Add("  NAVEGADOR: $($b.Nome.ToUpper())   (Subpasta neste backup: $($b.Pasta)\)")
        $tutLines.Add("  Perfis salvos: $listaPerfis")
        $tutLines.Add("------------------------------------------------------------------------")
        $tutLines.Add("")
        $tutLines.Add("  [A] COMO RESTAURAR OS FAVORITOS (COM DATAS ORIGINAIS PRESERVADAS):")
        $tutLines.Add("      $($b.BmStep)")
        $tutLines.Add("      -> Selecione o arquivo 'Favoritos <Nome> - $($b.Nome) - $dataHoje.html'")
        $tutLines.Add("         dentro da pasta '$($b.Pasta)\'.")
        $tutLines.Add("")
        $tutLines.Add("  [B] COMO RESTAURAR AS SENHAS SALVAS (.csv):")
        $tutLines.Add("      $($b.PassStep)")
        $tutLines.Add("      -> Arquivo salvo na pasta '$($b.Pasta)\' (ex: '$($env:USERNAME) senhas - $($b.Nome).csv').")
        $tutLines.Add("")
        $tutLines.Add("  [C] COMO RESTAURAR O PERFIL COMPLETO (EXTENSOES, HISTORICO, PREFS):")
        $tutLines.Add("      1) Instale e abra o $($b.Nome) uma vez no Windows novo, depois FECHE-O.")
        $tutLines.Add("      2) Pressione Win+R, cole o caminho abaixo e aperte ENTER:")
        $tutLines.Add("         $($b.RestorePath)")
        $tutLines.Add("      3) $($b.ProfNote)")
    }

    $tutLines.Add("")
    $tutLines.Add("========================================================================")
    $tutLines.Add("  [CAPRI // Edgerunners 2]: Tutorial gerado sob medida para este PC.")
    $tutLines.Add("========================================================================")

    Set-Content -Path $tutPath -Value $tutLines -Encoding UTF8

    Write-Host "`n  [SINCRONIZANDO] Espelhando BACKUP DADOS NAVEGADORES para a pasta 'DADOS' do Projeto (Pen Drive / SSD)..." -ForegroundColor Cyan
    $dadosNav = Sync-FolderToProjectDados -SourceDir $baseDir -SubFolder "BACKUP DADOS NAVEGADORES"

    Write-Host "`n========================================================================" -ForegroundColor Green
    Write-Host "  [OK] BACKUP DE NAVEGADORES CONCLUIDO!" -ForegroundColor Green
    Write-Host "  Navegadores detectados e documentados: $nomesDetectados" -ForegroundColor Yellow
    Write-Host "  Area de Trabalho: $baseDir" -ForegroundColor Cyan
    if ($dadosNav) { Write-Host "  Pasta no Projeto: $dadosNav" -ForegroundColor Cyan }
    Write-Host "  Tutorial personalizado salvo em: $tutPath" -ForegroundColor Cyan
    Write-Host '  [JACKIE WELLES // CP2077]: "Tudo organizado por navegador na Area de Trabalho e espelhado na pasta DADOS do seu projeto!"' -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Green
    Start-Process explorer.exe -ArgumentList "`"$baseDir`""
    Pause-Cyber
}
function Get-DesktopDatedDadosDir {
    param([string]$SubFolder = "")
    $dataPasta = Get-Date -Format "dd-MM-yyyy"
    $baseDesktop = Join-Path "$env:USERPROFILE\Desktop\DADOS" "BACKUP - $dataPasta"
    if (-not (Test-Path $baseDesktop)) { New-Item -ItemType Directory -Path $baseDesktop -Force | Out-Null }
    if ($SubFolder) {
        $target = Join-Path $baseDesktop $SubFolder
        if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
        return $target
    }
    return $baseDesktop
}

function Get-CyberDeckDadosDir {
    param([string]$SubFolder = "")
    $root = Get-CyberDeckRoot
    $dataPasta = Get-Date -Format "dd-MM-yyyy"
    $dadosRoot = Join-Path (Join-Path $root "DADOS") "BACKUP - $dataPasta"
    if (-not (Test-Path $dadosRoot)) { New-Item -ItemType Directory -Path $dadosRoot -Force | Out-Null }
    if ($SubFolder) {
        $target = Join-Path $dadosRoot $SubFolder
        if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }
        return $target
    }
    return $dadosRoot
}

function Sync-FileToProjectDados {
    param(
        [string]$SourceFile,
        [string]$SubFolder
    )
    try {
        if ($SourceFile -and (Test-Path -LiteralPath $SourceFile)) {
            $destDir = Get-CyberDeckDadosDir -SubFolder $SubFolder
            $destFile = Join-Path $destDir (Split-Path -Leaf $SourceFile)
            Copy-Item -LiteralPath $SourceFile -Destination $destFile -Force -ErrorAction Stop
            return $destFile
        }
    } catch {}
    return $null
}

function Sync-FolderToProjectDados {
    param(
        [string]$SourceDir,
        [string]$SubFolder
    )
    try {
        if ($SourceDir -and (Test-Path -LiteralPath $SourceDir)) {
            $destDir = Get-CyberDeckDadosDir -SubFolder $SubFolder
            $null = robocopy "$SourceDir" "$destDir" /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS
            return $destDir
        }
    } catch {}
    return $null
}

function Get-CyberDeckRoot {
    $here = $PSScriptRoot
    if (-not $here) { $here = (Get-Location).Path }
    $leaf = Split-Path -Leaf $here
    if ($leaf -eq "scripts_individuais_powershell" -or $leaf -eq "scripts_individuais_cmd") {
        return (Split-Path -Parent $here)
    }
    return $here
}

function Resolve-AdbExe {
    $root = Get-CyberDeckRoot
    $candidates = @(
        (Join-Path $root "ADB ANDROID\adb.exe"),
        (Join-Path $root "ADB ANDROID\platform-tools\adb.exe"),
        "$PSScriptRoot\ADB ANDROID\adb.exe",
        "$PSScriptRoot\platform-tools\adb.exe",
        "$PSScriptRoot\..\platform-tools\adb.exe",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Links\adb.exe",
        "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
        "$env:USERPROFILE\platform-tools\adb.exe",
        "C:\platform-tools\adb.exe",
        "C:\adb\adb.exe"
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    $wingetPkg = Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Filter "adb.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wingetPkg) { return $wingetPkg.FullName }
    $cmd = Get-Command "adb.exe" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { return $cmd.Source }
    return $null
}

function Invoke-DownloadWithProgress {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$Label = "Arquivo"
    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $req = [System.Net.HttpWebRequest]::Create($Url)
    $req.UserAgent = "CyberDeck-OS-Portable"
    $req.AllowAutoRedirect = $true
    $req.Timeout = 30000

    $resp = $null
    $inStream = $null
    $outStream = $null
    try {
        Write-Host "  [1/2] Conectando ao servidor para baixar $Label..." -ForegroundColor Cyan
        $resp = $req.GetResponse()
        $totalBytes = [int64]$resp.ContentLength
        $inStream = $resp.GetResponseStream()
        $outStream = [System.IO.File]::Create($OutFile)

        $buffer = New-Object byte[] 65536
        $downloaded = [int64]0
        $lastPct = -1
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $lastDrawMs = -200
        $spin = @('|','/','-','\')
        $spinIdx = 0

        if ($totalBytes -gt 0) {
            $totMB = [math]::Round($totalBytes / 1MB, 2)
            Write-Host ("`r  [--------------------]   0% | 0.00 / {0:N2} MB | Iniciando...          " -f $totMB) -NoNewline -ForegroundColor Cyan
        }

        while (($read = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $outStream.Write($buffer, 0, $read)
            $downloaded += $read
            $elapsedMs = $sw.ElapsedMilliseconds

            if ($totalBytes -gt 0) {
                $pct = [int][math]::Floor(($downloaded * 100.0) / $totalBytes)
                if ($pct -gt 100) { $pct = 100 }
                if (($pct -ne $lastPct) -or (($elapsedMs - $lastDrawMs) -ge 150)) {
                    $lastPct = $pct
                    $lastDrawMs = $elapsedMs
                    $filled = [int][math]::Floor($pct / 5)
                    if ($filled -gt 20) { $filled = 20 }
                    $bar = ("#" * $filled) + ("-" * (20 - $filled))
                    $dlMB = $downloaded / 1MB
                    $totMB = $totalBytes / 1MB
                    $secs = [math]::Max(0.1, $sw.Elapsed.TotalSeconds)
                    $spdMB = ($downloaded / 1MB) / $secs
                    $spdStr = if ($spdMB -ge 1) { "{0:N2} MB/s" -f $spdMB } else { "{0:N0} KB/s" -f (($downloaded / 1KB) / $secs) }
                    Write-Host ("`r  [{0}] {1,3}% | {2:N2} / {3:N2} MB | {4}        " -f $bar, $pct, $dlMB, $totMB, $spdStr) -NoNewline -ForegroundColor Cyan
                }
            } else {
                if (($elapsedMs - $lastDrawMs) -ge 200) {
                    $lastDrawMs = $elapsedMs
                    $sp = $spin[$spinIdx % $spin.Length]
                    $spinIdx++
                    $dlMB = $downloaded / 1MB
                    $secs = [math]::Max(0.1, $sw.Elapsed.TotalSeconds)
                    $spdStr = "{0:N0} KB/s" -f (($downloaded / 1KB) / $secs)
                    Write-Host ("`r  [{0}] Baixando... {1:N2} MB recebidos | {2}        " -f $sp, $dlMB, $spdStr) -NoNewline -ForegroundColor Cyan
                }
            }
        }
        $sw.Stop()
        $finalMB = $downloaded / 1MB
        if ($totalBytes -gt 0) {
            Write-Host ("`r  [####################] 100% | {0:N2} / {0:N2} MB | Concluido!           " -f $finalMB) -ForegroundColor Green
        } else {
            Write-Host ("`r  [OK] Download concluido! Total recebido: {0:N2} MB                     " -f $finalMB) -ForegroundColor Green
        }
    } finally {
        if ($outStream) { $outStream.Close(); $outStream.Dispose() }
        if ($inStream) { $inStream.Close(); $inStream.Dispose() }
        if ($resp) { $resp.Close() }
    }
}

function Install-PortableAdb {
    $root = Get-CyberDeckRoot
    $destDir = Join-Path $root "ADB ANDROID"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    Write-Host "`n  [CAPRI // Edgerunners 2]: `"Baixando Android Platform-Tools oficial direto para a pasta portatil 'ADB ANDROID' do projeto...`"" -ForegroundColor Cyan
    Write-Host "  Destino no Pen Drive / Projeto: $destDir" -ForegroundColor Yellow

    $zipTemp = Join-Path $env:TEMP "cyberdeck_platform_tools.zip"
    $extractTemp = Join-Path $env:TEMP "cyberdeck_platform_tools_ext"
    try {
        Invoke-DownloadWithProgress -Url "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile $zipTemp -Label "Android Platform-Tools (ADB)"
        Write-Host "  [2/2] Extraindo arquivos para '$destDir'..." -ForegroundColor Yellow
        if (Test-Path $extractTemp) { Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue }
        $oldPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Expand-Archive -Path $zipTemp -DestinationPath $extractTemp -Force -ErrorAction Stop
        $ProgressPreference = $oldPref

        $ptDir = Join-Path $extractTemp "platform-tools"
        if (Test-Path $ptDir) {
            Copy-Item -Path "$ptDir\*" -Destination $destDir -Recurse -Force
        } else {
            Copy-Item -Path "$extractTemp\*" -Destination $destDir -Recurse -Force
        }
        Remove-Item -Path $zipTemp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

        $adbFinal = Join-Path $destDir "adb.exe"
        if (Test-Path $adbFinal) {
            $adbSizeMB = [math]::Round((Get-Item $adbFinal).Length / 1MB, 2)
            Write-Host "  [OK] ADB Portatil salvo e verificado na pasta raiz: $adbFinal ($adbSizeMB MB)" -ForegroundColor Green
            Write-Host '  [V // CP2077]: "Pronto! Agora voce pode plugar esse pen drive em qualquer PC sem precisar instalar de novo."' -ForegroundColor Cyan
            return $adbFinal
        }
    } catch {
        Write-Host "`n  [ERRO] Falha ao baixar o ADB portatil: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host '  [DOC // Edgerunners 1]: "Verifique sua internet ou baixe manualmente em developer.android.com e jogue na pasta ADB ANDROID."' -ForegroundColor Magenta
    }
    return $null
}

function Resolve-IphoneTools {
    $root = Get-CyberDeckRoot
    $ipDir = Join-Path $root "LIBIMOBILEDEVICE IPHONE"
    if (Test-Path $ipDir) {
        $exe = Get-ChildItem -Path $ipDir -Filter "idevice_id.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { return $exe.DirectoryName }
    }
    $cmd = Get-Command "idevice_id.exe" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return (Split-Path -Parent $cmd.Source) }
    return $null
}

function Install-PortableIphoneTools {
    $root = Get-CyberDeckRoot
    $destDir = Join-Path $root "LIBIMOBILEDEVICE IPHONE"
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

    Write-Host "`n  [SONGBIRD // CP2077]: `"Baixando libimobiledevice portatil (Windows x64) direto para a pasta 'LIBIMOBILEDEVICE IPHONE'...`"" -ForegroundColor Magenta
    Write-Host "  Destino no Pen Drive / Projeto: $destDir" -ForegroundColor Yellow

    $zipTemp = Join-Path $env:TEMP "cyberdeck_libimobiledevice.zip"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{ "User-Agent" = "CyberDeck-OS-Portable" }
        $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/libimobiledevice-win32/imobiledevice-net/releases/latest" -Headers $headers -ErrorAction Stop
        $asset = $rel.assets | Where-Object { $_.name -match "win-x64.*\.zip$" -or $_.name -match "x64.*\.zip$" } | Select-Object -First 1
        if (-not $asset) { $asset = $rel.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -First 1 }
        if (-not $asset) { throw "Nenhum pacote ZIP encontrado na release mais recente." }

        Write-Host "  Pacote localizado: $($asset.name)" -ForegroundColor Cyan
        Invoke-DownloadWithProgress -Url $asset.browser_download_url -OutFile $zipTemp -Label $asset.name
        Write-Host "  [2/2] Extraindo arquivos para '$destDir'..." -ForegroundColor Yellow
        $oldPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Expand-Archive -Path $zipTemp -DestinationPath $destDir -Force -ErrorAction Stop
        $ProgressPreference = $oldPref
        Remove-Item -Path $zipTemp -Force -ErrorAction SilentlyContinue

        $found = Resolve-IphoneTools
        if ($found) {
            Write-Host "  [OK] Ferramentas portateis do iPhone salvas e verificadas em: $found" -ForegroundColor Green
            Write-Host '  [HANAKO ARASAKA // CP2077]: "Ferramenta portatil pronta no pen drive. Lembre que no Windows o iPhone exige o driver Apple/iTunes para leitura USB."' -ForegroundColor White
            return $found
        }
    } catch {
        Write-Host "`n  [AVISO/ERRO] Nao foi possivel baixar automaticamente: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host '  [TALIA // Edgerunners 2]: "Se quiser, voce pode baixar manualmente o libimobiledevice-win32 e extrair dentro de LIBIMOBILEDEVICE IPHONE."' -ForegroundColor Red
    }
    return $null
}

function Show-AdbQrCodePairing {
    param([string]$AdbPath = "", [hashtable]$Tema = $null)
    Clear-Host
    Show-BootBanner "[18-QR] PAREAMENTO ADB VIA QR CODE / WI-FI (ANDROID 11+)"
    Write-Host '  [CAPRI // Edgerunners 2]: "Gerando matriz QR Code neural para pareamento sem fio."' -ForegroundColor Cyan
    Write-Host '  [SONGBIRD // CP2077]: "Certifique-se de que o computador e o celular estao na MESMA rede Wi-Fi."' -ForegroundColor Magenta
    Write-Host ""

    $pairCode = (Get-Random -Minimum 100000 -Maximum 999999).ToString()
    $hostName = $env:COMPUTERNAME
    if ($hostName.Length -gt 12) { $hostName = $hostName.Substring(0, 12) }
    $serviceName = "CYBERDECK-$hostName"
    $qrPayload = "WIFI:T:ADB;S:$serviceName;P:$pairCode;;"

    # Auto-detection of corporate theme (zero user friction)
    $corpoKey = ""
    if ($Tema -and $Tema.Key) { $corpoKey = $Tema.Key }
    elseif ($global:ActiveCorpoKey) { $corpoKey = $global:ActiveCorpoKey }
    elseif ($Tema -and $Tema.Nome) {
        if ($Tema.Nome -match "ARASAKA") { $corpoKey = "arasaka" }
        elseif ($Tema.Nome -match "TRAUMA") { $corpoKey = "trauma" }
        elseif ($Tema.Nome -match "MILITECH") { $corpoKey = "militech" }
        elseif ($Tema.Nome -match "KANG") { $corpoKey = "kangtao" }
        elseif ($Tema.Nome -match "NETWATCH") { $corpoKey = "netwatch" }
        elseif ($Tema.Nome -match "AFTERLIFE") { $corpoKey = "afterlife" }
    }
    if (-not $corpoKey -and $global:tema -and $global:tema.Nome) {
        if ($global:tema.Nome -match "ARASAKA") { $corpoKey = "arasaka" }
        elseif ($global:tema.Nome -match "TRAUMA") { $corpoKey = "trauma" }
        elseif ($global:tema.Nome -match "MILITECH") { $corpoKey = "militech" }
        elseif ($global:tema.Nome -match "KANG") { $corpoKey = "kangtao" }
        elseif ($global:tema.Nome -match "NETWATCH") { $corpoKey = "netwatch" }
        elseif ($global:tema.Nome -match "AFTERLIFE") { $corpoKey = "afterlife" }
    }
    $themeFile = Join-Path $env:TEMP "cyberdeck_active_theme.txt"
    if (-not $corpoKey -and (Test-Path $themeFile)) {
        try {
            $saved = (Get-Content $themeFile -ErrorAction SilentlyContinue).Trim()
            if ($saved -in @("arasaka", "trauma", "militech", "kangtao", "netwatch", "afterlife")) {
                $corpoKey = $saved
            }
        } catch {}
    }
    if (-not $corpoKey) { $corpoKey = "arasaka" }

    $corpoMeta = @{
        "arasaka"  = @{ Brand = "ARASAKA CORP // PROJETO CAPRICORN"; Quote = 'Saburo & Capri: "A ordem e a seguranca nascem do controle total do terminal."' }
        "trauma"   = @{ Brand = "TRAUMA TEAM INTL // MEDICAL EVAC UNIT"; Quote = 'Gloria & Viktor: "Extracao de dados rapida e segura. Ninguem fica para tras."' }
        "militech" = @{ Brand = "MILITECH ARMAMENTS // NUSA DEFENSE PROTOCOL"; Quote = 'Solomon Reed: "Eficiencia militar e disciplina tatica no fluxo de dados."' }
        "kangtao"  = @{ Brand = "KANG TAO SMART-TECH // NEURAL LINK"; Quote = 'Takemura: "A precisao tecnologica supera qualquer forca bruta."' }
        "netwatch" = @{ Brand = "NETWATCH BLACKWALL // CONTENCAO NIVEL 5"; Quote = 'Alt Cunningham: "Atras da Blackwall nao ha piedade. Mantenha seu link isolado."' }
        "afterlife"= @{ Brand = "AFTERLIFE EDGERUNNERS // UNDERGROUND DECK"; Quote = 'David & Lucy: "Sem coleira corporativa. Conecte pelo nosso proprio canal."' }
    }
    $activeBrand = $corpoMeta[$corpoKey].Brand
    $activeQuote = $corpoMeta[$corpoKey].Quote

    $embeddedJs = @"
var QRCode;!function(){function a(a){this.mode=c.MODE_8BIT_BYTE,this.data=a,this.parsedData=[];for(var b=[],d=0,e=this.data.length;e>d;d++){var f=this.data.charCodeAt(d);f>65536?(b[0]=240|(1835008&f)>>>18,b[1]=128|(258048&f)>>>12,b[2]=128|(4032&f)>>>6,b[3]=128|63&f):f>2048?(b[0]=224|(61440&f)>>>12,b[1]=128|(4032&f)>>>6,b[2]=128|63&f):f>128?(b[0]=192|(1984&f)>>>6,b[1]=128|63&f):b[0]=f,this.parsedData=this.parsedData.concat(b)}this.parsedData.length!=this.data.length&&(this.parsedData.unshift(191),this.parsedData.unshift(187),this.parsedData.unshift(239))}function b(a,b){this.typeNumber=a,this.errorCorrectLevel=b,this.modules=null,this.moduleCount=0,this.dataCache=null,this.dataList=[]}function i(a,b){if(void 0==a.length)throw new Error(a.length+"/"+b);for(var c=0;c<a.length&&0==a[c];)c++;this.num=new Array(a.length-c+b);for(var d=0;d<a.length-c;d++)this.num[d]=a[d+c]}function j(a,b){this.totalCount=a,this.dataCount=b}function k(){this.buffer=[],this.length=0}function m(){return"undefined"!=typeof CanvasRenderingContext2D}function n(){var a=!1,b=navigator.userAgent;return/android/i.test(b)&&(a=!0,aMat=b.toString().match(/android ([0-9]\.[0-9])/i),aMat&&aMat[1]&&(a=parseFloat(aMat[1]))),a}function r(a,b){for(var c=1,e=s(a),f=0,g=l.length;g>=f;f++){var h=0;switch(b){case d.L:h=l[f][0];break;case d.M:h=l[f][1];break;case d.Q:h=l[f][2];break;case d.H:h=l[f][3]}if(h>=e)break;c++}if(c>l.length)throw new Error("Too long data");return c}function s(a){var b=encodeURI(a).toString().replace(/\%[0-9a-fA-F]{2}/g,"a");return b.length+(b.length!=a?3:0)}a.prototype={getLength:function(){return this.parsedData.length},write:function(a){for(var b=0,c=this.parsedData.length;c>b;b++)a.put(this.parsedData[b],8)}},b.prototype={addData:function(b){var c=new a(b);this.dataList.push(c),this.dataCache=null},isDark:function(a,b){if(0>a||this.moduleCount<=a||0>b||this.moduleCount<=b)throw new Error(a+","+b);return this.modules[a][b]},getModuleCount:function(){return this.moduleCount},make:function(){this.makeImpl(!1,this.getBestMaskPattern())},makeImpl:function(a,c){this.moduleCount=4*this.typeNumber+17,this.modules=new Array(this.moduleCount);for(var d=0;d<this.moduleCount;d++){this.modules[d]=new Array(this.moduleCount);for(var e=0;e<this.moduleCount;e++)this.modules[d][e]=null}this.setupPositionProbePattern(0,0),this.setupPositionProbePattern(this.moduleCount-7,0),this.setupPositionProbePattern(0,this.moduleCount-7),this.setupPositionAdjustPattern(),this.setupTimingPattern(),this.setupTypeInfo(a,c),this.typeNumber>=7&&this.setupTypeNumber(a),null==this.dataCache&&(this.dataCache=b.createData(this.typeNumber,this.errorCorrectLevel,this.dataList)),this.mapData(this.dataCache,c)},setupPositionProbePattern:function(a,b){for(var c=-1;7>=c;c++)if(!(-1>=a+c||this.moduleCount<=a+c))for(var d=-1;7>=d;d++)-1>=b+d||this.moduleCount<=b+d||(this.modules[a+c][b+d]=c>=0&&6>=c&&(0==d||6==d)||d>=0&&6>=d&&(0==c||6==c)||c>=2&&4>=c&&d>=2&&4>=d?!0:!1)},getBestMaskPattern:function(){for(var a=0,b=0,c=0;8>c;c++){this.makeImpl(!0,c);var d=f.getLostPoint(this);(0==c||a>d)&&(a=d,b=c)}return b},createMovieClip:function(a,b,c){var d=a.createEmptyMovieClip(b,c),e=1;this.make();for(var f=0;f<this.modules.length;f++)for(var g=f*e,h=0;h<this.modules[f].length;h++){var i=h*e,j=this.modules[f][h];j&&(d.beginFill(0,100),d.moveTo(i,g),d.lineTo(i+e,g),d.lineTo(i+e,g+e),d.lineTo(i,g+e),d.endFill())}return d},setupTimingPattern:function(){for(var a=8;a<this.moduleCount-8;a++)null==this.modules[a][6]&&(this.modules[a][6]=0==a%2);for(var b=8;b<this.moduleCount-8;b++)null==this.modules[6][b]&&(this.modules[6][b]=0==b%2)},setupPositionAdjustPattern:function(){for(var a=f.getPatternPosition(this.typeNumber),b=0;b<a.length;b++)for(var c=0;c<a.length;c++){var d=a[b],e=a[c];if(null==this.modules[d][e])for(var g=-2;2>=g;g++)for(var h=-2;2>=h;h++)this.modules[d+g][e+h]=-2==g||2==g||-2==h||2==h||0==g&&0==h?!0:!1}},setupTypeNumber:function(a){for(var b=f.getBCHTypeNumber(this.typeNumber),c=0;18>c;c++){var d=!a&&1==(1&b>>c);this.modules[Math.floor(c/3)][c%3+this.moduleCount-8-3]=d}for(var c=0;18>c;c++){var d=!a&&1==(1&b>>c);this.modules[c%3+this.moduleCount-8-3][Math.floor(c/3)]=d}},setupTypeInfo:function(a,b){for(var c=this.errorCorrectLevel<<3|b,d=f.getBCHTypeInfo(c),e=0;15>e;e++){var g=!a&&1==(1&d>>e);6>e?this.modules[e][8]=g:8>e?this.modules[e+1][8]=g:this.modules[this.moduleCount-15+e][8]=g}for(var e=0;15>e;e++){var g=!a&&1==(1&d>>e);8>e?this.modules[8][this.moduleCount-e-1]=g:9>e?this.modules[8][15-e-1+1]=g:this.modules[8][15-e-1]=g}this.modules[this.moduleCount-8][8]=!a},mapData:function(a,b){for(var c=-1,d=this.moduleCount-1,e=7,g=0,h=this.moduleCount-1;h>0;h-=2)for(6==h&&h--;;){for(var i=0;2>i;i++)if(null==this.modules[d][h-i]){var j=!1;g<a.length&&(j=1==(1&a[g]>>>e));var k=f.getMask(b,d,h-i);k&&(j=!j),this.modules[d][h-i]=j,e--,-1==e&&(g++,e=7)}if(d+=c,0>d||this.moduleCount<=d){d-=c,c=-c;break}}}},b.PAD0=236,b.PAD1=17,b.createData=function(a,c,d){for(var e=j.getRSBlocks(a,c),g=new k,h=0;h<d.length;h++){var i=d[h];g.put(i.mode,4),g.put(i.getLength(),f.getLengthInBits(i.mode,a)),i.write(g)}for(var l=0,h=0;h<e.length;h++)l+=e[h].dataCount;if(g.getLengthInBits()>8*l)throw new Error("code length overflow. ("+g.getLengthInBits()+">"+8*l+")");for(g.getLengthInBits()+4<=8*l&&g.put(0,4);0!=g.getLengthInBits()%8;)g.putBit(!1);for(;;){if(g.getLengthInBits()>=8*l)break;if(g.put(b.PAD0,8),g.getLengthInBits()>=8*l)break;g.put(b.PAD1,8)}return b.createBytes(g,e)},b.createBytes=function(a,b){for(var c=0,d=0,e=0,g=new Array(b.length),h=new Array(b.length),j=0;j<b.length;j++){var k=b[j].dataCount,l=b[j].totalCount-k;d=Math.max(d,k),e=Math.max(e,l),g[j]=new Array(k);for(var m=0;m<g[j].length;m++)g[j][m]=255&a.buffer[m+c];c+=k;var n=f.getErrorCorrectPolynomial(l),o=new i(g[j],n.getLength()-1),p=o.mod(n);h[j]=new Array(n.getLength()-1);for(var m=0;m<h[j].length;m++){var q=m+p.getLength()-h[j].length;h[j][m]=q>=0?p.get(q):0}}for(var r=0,m=0;m<b.length;m++)r+=b[m].totalCount;for(var s=new Array(r),t=0,m=0;d>m;m++)for(var j=0;j<b.length;j++)m<g[j].length&&(s[t++]=g[j][m]);for(var m=0;e>m;m++)for(var j=0;j<b.length;j++)m<h[j].length&&(s[t++]=h[j][m]);return s};for(var c={MODE_NUMBER:1,MODE_ALPHA_NUM:2,MODE_8BIT_BYTE:4,MODE_KANJI:8},d={L:1,M:0,Q:3,H:2},e={PATTERN000:0,PATTERN001:1,PATTERN010:2,PATTERN011:3,PATTERN100:4,PATTERN101:5,PATTERN110:6,PATTERN111:7},f={PATTERN_POSITION_TABLE:[[],[6,18],[6,22],[6,26],[6,30],[6,34],[6,22,38],[6,24,42],[6,26,46],[6,28,50],[6,30,54],[6,32,58],[6,34,62],[6,26,46,66],[6,26,48,70],[6,26,50,74],[6,30,54,78],[6,30,56,82],[6,30,58,86],[6,34,62,90],[6,28,50,72,94],[6,26,50,74,98],[6,30,54,78,102],[6,28,54,80,106],[6,32,58,84,110],[6,30,58,86,114],[6,34,62,90,118],[6,26,50,74,98,122],[6,30,54,78,102,126],[6,26,52,78,104,130],[6,30,56,82,108,134],[6,34,60,86,112,138],[6,30,58,86,114,142],[6,34,62,90,118,146],[6,30,54,78,102,126,150],[6,24,50,76,102,128,154],[6,28,54,80,106,132,158],[6,32,58,84,110,136,162],[6,26,54,82,110,138,166],[6,30,58,86,114,142,170]],G15:1335,G18:7973,G15_MASK:21522,getBCHTypeInfo:function(a){for(var b=a<<10;f.getBCHDigit(b)-f.getBCHDigit(f.G15)>=0;)b^=f.G15<<f.getBCHDigit(b)-f.getBCHDigit(f.G15);return(a<<10|b)^f.G15_MASK},getBCHTypeNumber:function(a){for(var b=a<<12;f.getBCHDigit(b)-f.getBCHDigit(f.G18)>=0;)b^=f.G18<<f.getBCHDigit(b)-f.getBCHDigit(f.G18);return a<<12|b},getBCHDigit:function(a){for(var b=0;0!=a;)b++,a>>>=1;return b},getPatternPosition:function(a){return f.PATTERN_POSITION_TABLE[a-1]},getMask:function(a,b,c){switch(a){case e.PATTERN000:return 0==(b+c)%2;case e.PATTERN001:return 0==b%2;case e.PATTERN010:return 0==c%3;case e.PATTERN011:return 0==(b+c)%3;case e.PATTERN100:return 0==(Math.floor(b/2)+Math.floor(c/3))%2;case e.PATTERN101:return 0==b*c%2+b*c%3;case e.PATTERN110:return 0==(b*c%2+b*c%3)%2;case e.PATTERN111:return 0==(b*c%3+(b+c)%2)%2;default:throw new Error("bad maskPattern:"+a)}},getErrorCorrectPolynomial:function(a){for(var b=new i([1],0),c=0;a>c;c++)b=b.multiply(new i([1,g.gexp(c)],0));return b},getLengthInBits:function(a,b){if(b>=1&&10>b)switch(a){case c.MODE_NUMBER:return 10;case c.MODE_ALPHA_NUM:return 9;case c.MODE_8BIT_BYTE:return 8;case c.MODE_KANJI:return 8;default:throw new Error("mode:"+a)}else if(27>b)switch(a){case c.MODE_NUMBER:return 12;case c.MODE_ALPHA_NUM:return 11;case c.MODE_8BIT_BYTE:return 16;case c.MODE_KANJI:return 10;default:throw new Error("mode:"+a)}else{if(!(41>b))throw new Error("type:"+b);switch(a){case c.MODE_NUMBER:return 14;case c.MODE_ALPHA_NUM:return 13;case c.MODE_8BIT_BYTE:return 16;case c.MODE_KANJI:return 12;default:throw new Error("mode:"+a)}}},getLostPoint:function(a){for(var b=a.getModuleCount(),c=0,d=0;b>d;d++)for(var e=0;b>e;e++){for(var f=0,g=a.isDark(d,e),h=-1;1>=h;h++)if(!(0>d+h||d+h>=b))for(var i=-1;1>=i;i++)0>e+i||e+i>=b||(0!=h||0!=i)&&g==a.isDark(d+h,e+i)&&f++;f>5&&(c+=3+f-5)}for(var d=0;b-1>d;d++)for(var e=0;b-1>e;e++){var j=0;a.isDark(d,e)&&j++,a.isDark(d+1,e)&&j++,a.isDark(d,e+1)&&j++,a.isDark(d+1,e+1)&&j++,(0==j||4==j)&&(c+=3)}for(var d=0;b>d;d++)for(var e=0;b-6>e;e++)a.isDark(d,e)&&!a.isDark(d,e+1)&&a.isDark(d,e+2)&&a.isDark(d,e+3)&&a.isDark(d,e+4)&&!a.isDark(d,e+5)&&a.isDark(d,e+6)&&(c+=40);for(var e=0;b>e;e++)for(var d=0;b-6>d;d++)a.isDark(d,e)&&!a.isDark(d+1,e)&&a.isDark(d+2,e)&&a.isDark(d+3,e)&&a.isDark(d+4,e)&&!a.isDark(d+5,e)&&a.isDark(d+6,e)&&(c+=40);for(var k=0,e=0;b>e;e++)for(var d=0;b>d;d++)a.isDark(d,e)&&k++;var l=Math.abs(100*k/b/b-50)/5;return c+=10*l}},g={glog:function(a){if(1>a)throw new Error("glog("+a+")");return g.LOG_TABLE[a]},gexp:function(a){for(;0>a;)a+=255;for(;a>=256;)a-=255;return g.EXP_TABLE[a]},EXP_TABLE:new Array(256),LOG_TABLE:new Array(256)},h=0;8>h;h++)g.EXP_TABLE[h]=1<<h;for(var h=8;256>h;h++)g.EXP_TABLE[h]=g.EXP_TABLE[h-4]^g.EXP_TABLE[h-5]^g.EXP_TABLE[h-6]^g.EXP_TABLE[h-8];for(var h=0;255>h;h++)g.LOG_TABLE[g.EXP_TABLE[h]]=h;i.prototype={get:function(a){return this.num[a]},getLength:function(){return this.num.length},multiply:function(a){for(var b=new Array(this.getLength()+a.getLength()-1),c=0;c<this.getLength();c++)for(var d=0;d<a.getLength();d++)b[c+d]^=g.gexp(g.glog(this.get(c))+g.glog(a.get(d)));return new i(b,0)},mod:function(a){if(this.getLength()-a.getLength()<0)return this;for(var b=g.glog(this.get(0))-g.glog(a.get(0)),c=new Array(this.getLength()),d=0;d<this.getLength();d++)c[d]=this.get(d);for(var d=0;d<a.getLength();d++)c[d]^=g.gexp(g.glog(a.get(d))+b);return new i(c,0).mod(a)}},j.RS_BLOCK_TABLE=[[1,26,19],[1,26,16],[1,26,13],[1,26,9],[1,44,34],[1,44,28],[1,44,22],[1,44,16],[1,70,55],[1,70,44],[2,35,17],[2,35,13],[1,100,80],[2,50,32],[2,50,24],[4,25,9],[1,134,108],[2,67,43],[2,33,15,2,34,16],[2,33,11,2,34,12],[2,86,68],[4,43,27],[4,43,19],[4,43,15],[2,98,78],[4,49,31],[2,32,14,4,33,15],[4,39,13,1,40,14],[2,121,97],[2,60,38,2,61,39],[4,40,18,2,41,19],[4,40,14,2,41,15],[2,146,116],[3,58,36,2,59,37],[4,36,16,4,37,17],[4,36,12,4,37,13],[2,86,68,2,87,69],[4,69,43,1,70,44],[6,43,19,2,44,20],[6,43,15,2,44,16],[4,101,81],[1,80,50,4,81,51],[4,50,22,4,51,23],[3,36,12,8,37,13],[2,116,92,2,117,93],[6,58,36,2,59,37],[4,46,20,6,47,21],[7,42,14,4,43,15],[4,133,107],[8,59,37,1,60,38],[8,44,20,4,45,21],[12,33,11,4,34,12],[3,145,115,1,146,116],[4,64,40,5,65,41],[11,36,16,5,37,17],[11,36,12,5,37,13],[5,109,87,1,110,88],[5,65,41,5,66,42],[5,54,24,7,55,25],[11,36,12],[5,122,98,1,123,99],[7,73,45,3,74,46],[15,43,19,2,44,20],[3,45,15,13,46,16],[1,135,107,5,136,108],[10,74,46,1,75,47],[1,50,22,15,51,23],[2,42,14,17,43,15],[5,150,120,1,151,121],[9,69,43,4,70,44],[17,50,22,1,51,23],[2,42,14,19,43,15],[3,141,113,4,142,114],[3,70,44,11,71,45],[17,47,21,4,48,22],[9,39,13,16,40,14],[3,135,107,5,136,108],[3,67,41,13,68,42],[15,54,24,5,55,25],[15,43,15,10,44,16],[4,144,116,4,145,117],[17,68,42],[17,50,22,6,51,23],[19,46,16,6,47,17],[2,139,111,7,140,112],[17,74,46],[7,54,24,16,55,25],[34,37,13],[4,151,121,5,152,122],[4,75,47,14,76,48],[11,54,24,14,55,25],[16,45,15,14,46,16],[6,147,117,4,148,118],[6,73,45,14,74,46],[11,54,24,16,55,25],[30,46,16,2,47,17],[8,132,106,4,133,107],[8,75,47,13,76,48],[7,54,24,22,55,25],[22,45,15,13,46,16],[10,142,114,2,143,115],[19,74,46,4,75,47],[28,50,22,6,51,23],[33,46,16,4,47,17],[8,152,122,4,153,123],[22,73,45,3,74,46],[8,53,23,26,54,24],[12,45,15,28,46,16],[3,147,117,10,148,118],[3,73,45,23,74,46],[4,54,24,31,55,25],[11,45,15,31,46,16],[7,146,116,7,147,117],[21,73,45,7,74,46],[1,53,23,37,54,24],[19,45,15,26,46,16],[5,145,115,10,146,116],[19,75,47,10,76,48],[15,54,24,25,55,25],[23,45,15,25,46,16],[13,145,115,3,146,116],[2,74,46,29,75,47],[42,54,24,1,55,25],[23,45,15,28,46,16],[17,145,115],[10,74,46,23,75,47],[10,54,24,35,55,25],[19,45,15,35,46,16],[17,145,115,1,146,116],[14,74,46,21,75,47],[29,54,24,19,55,25],[11,45,15,46,46,16],[13,145,115,6,146,116],[14,74,46,23,75,47],[44,54,24,7,55,25],[59,46,16,1,47,17],[12,151,121,7,152,122],[12,75,47,26,76,48],[39,54,24,14,55,25],[22,45,15,41,46,16],[6,151,121,14,152,122],[6,75,47,34,76,48],[46,54,24,10,55,25],[2,45,15,64,46,16],[17,152,122,4,153,123],[29,74,46,14,75,47],[49,54,24,10,55,25],[24,45,15,46,46,16],[4,152,122,18,153,123],[13,74,46,32,75,47],[48,54,24,14,55,25],[42,45,15,32,46,16],[20,147,117,4,148,118],[40,75,47,7,76,48],[43,54,24,22,55,25],[10,45,15,67,46,16],[19,148,118,6,149,119],[18,75,47,31,76,48],[34,54,24,34,55,25],[20,45,15,61,46,16]],j.getRSBlocks=function(a,b){var c=j.getRsBlockTable(a,b);if(void 0==c)throw new Error("bad rs block @ typeNumber:"+a+"/errorCorrectLevel:"+b);for(var d=c.length/3,e=[],f=0;d>f;f++)for(var g=c[3*f+0],h=c[3*f+1],i=c[3*f+2],k=0;g>k;k++)e.push(new j(h,i));return e},j.getRsBlockTable=function(a,b){switch(b){case d.L:return j.RS_BLOCK_TABLE[4*(a-1)+0];case d.M:return j.RS_BLOCK_TABLE[4*(a-1)+1];case d.Q:return j.RS_BLOCK_TABLE[4*(a-1)+2];case d.H:return j.RS_BLOCK_TABLE[4*(a-1)+3];default:return void 0}},k.prototype={get:function(a){var b=Math.floor(a/8);return 1==(1&this.buffer[b]>>>7-a%8)},put:function(a,b){for(var c=0;b>c;c++)this.putBit(1==(1&a>>>b-c-1))},getLengthInBits:function(){return this.length},putBit:function(a){var b=Math.floor(this.length/8);this.buffer.length<=b&&this.buffer.push(0),a&&(this.buffer[b]|=128>>>this.length%8),this.length++}};var l=[[17,14,11,7],[32,26,20,14],[53,42,32,24],[78,62,46,34],[106,84,60,44],[134,106,74,58],[154,122,86,64],[192,152,108,84],[230,180,130,98],[271,213,151,119],[321,251,177,137],[367,287,203,155],[425,331,241,177],[458,362,258,194],[520,412,292,220],[586,450,322,250],[644,504,364,280],[718,560,394,310],[792,624,442,338],[858,666,482,382],[929,711,509,403],[1003,779,565,439],[1091,857,611,461],[1171,911,661,511],[1273,997,715,535],[1367,1059,751,593],[1465,1125,805,625],[1528,1190,868,658],[1628,1264,908,698],[1732,1370,982,742],[1840,1452,1030,790],[1952,1538,1112,842],[2068,1628,1168,898],[2188,1722,1228,958],[2303,1809,1283,983],[2431,1911,1351,1051],[2563,1989,1423,1093],[2699,2099,1499,1139],[2809,2213,1579,1219],[2953,2331,1663,1273]],o=function(){var a=function(a,b){this._el=a,this._htOption=b};return a.prototype.draw=function(a){function g(a,b){var c=document.createElementNS("http://www.w3.org/2000/svg",a);for(var d in b)b.hasOwnProperty(d)&&c.setAttribute(d,b[d]);return c}var b=this._htOption,c=this._el,d=a.getModuleCount();Math.floor(b.width/d),Math.floor(b.height/d),this.clear();var h=g("svg",{viewBox:"0 0 "+String(d)+" "+String(d),width:"100%",height:"100%",fill:b.colorLight});h.setAttributeNS("http://www.w3.org/2000/xmlns/","xmlns:xlink","http://www.w3.org/1999/xlink"),c.appendChild(h),h.appendChild(g("rect",{fill:b.colorDark,width:"1",height:"1",id:"template"}));for(var i=0;d>i;i++)for(var j=0;d>j;j++)if(a.isDark(i,j)){var k=g("use",{x:String(i),y:String(j)});k.setAttributeNS("http://www.w3.org/1999/xlink","href","#template"),h.appendChild(k)}},a.prototype.clear=function(){for(;this._el.hasChildNodes();)this._el.removeChild(this._el.lastChild)},a}(),p="svg"===document.documentElement.tagName.toLowerCase(),q=p?o:m()?function(){function a(){this._elImage.src=this._elCanvas.toDataURL("image/png"),this._elImage.style.display="block",this._elCanvas.style.display="none"}function d(a,b){var c=this;if(c._fFail=b,c._fSuccess=a,null===c._bSupportDataURI){var d=document.createElement("img"),e=function(){c._bSupportDataURI=!1,c._fFail&&_fFail.call(c)},f=function(){c._bSupportDataURI=!0,c._fSuccess&&c._fSuccess.call(c)};return d.onabort=e,d.onerror=e,d.onload=f,d.src="data:image/gif;base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==",void 0}c._bSupportDataURI===!0&&c._fSuccess?c._fSuccess.call(c):c._bSupportDataURI===!1&&c._fFail&&c._fFail.call(c)}if(this._android&&this._android<=2.1){var b=1/window.devicePixelRatio,c=CanvasRenderingContext2D.prototype.drawImage;CanvasRenderingContext2D.prototype.drawImage=function(a,d,e,f,g,h,i,j){if("nodeName"in a&&/img/i.test(a.nodeName))for(var l=arguments.length-1;l>=1;l--)arguments[l]=arguments[l]*b;else"undefined"==typeof j&&(arguments[1]*=b,arguments[2]*=b,arguments[3]*=b,arguments[4]*=b);c.apply(this,arguments)}}var e=function(a,b){this._bIsPainted=!1,this._android=n(),this._htOption=b,this._elCanvas=document.createElement("canvas"),this._elCanvas.width=b.width,this._elCanvas.height=b.height,a.appendChild(this._elCanvas),this._el=a,this._oContext=this._elCanvas.getContext("2d"),this._bIsPainted=!1,this._elImage=document.createElement("img"),this._elImage.style.display="none",this._el.appendChild(this._elImage),this._bSupportDataURI=null};return e.prototype.draw=function(a){var b=this._elImage,c=this._oContext,d=this._htOption,e=a.getModuleCount(),f=d.width/e,g=d.height/e,h=Math.round(f),i=Math.round(g);b.style.display="none",this.clear();for(var j=0;e>j;j++)for(var k=0;e>k;k++){var l=a.isDark(j,k),m=k*f,n=j*g;c.strokeStyle=l?d.colorDark:d.colorLight,c.lineWidth=1,c.fillStyle=l?d.colorDark:d.colorLight,c.fillRect(m,n,f,g),c.strokeRect(Math.floor(m)+.5,Math.floor(n)+.5,h,i),c.strokeRect(Math.ceil(m)-.5,Math.ceil(n)-.5,h,i)}this._bIsPainted=!0},e.prototype.makeImage=function(){this._bIsPainted&&d.call(this,a)},e.prototype.isPainted=function(){return this._bIsPainted},e.prototype.clear=function(){this._oContext.clearRect(0,0,this._elCanvas.width,this._elCanvas.height),this._bIsPainted=!1},e.prototype.round=function(a){return a?Math.floor(1e3*a)/1e3:a},e}():function(){var a=function(a,b){this._el=a,this._htOption=b};return a.prototype.draw=function(a){for(var b=this._htOption,c=this._el,d=a.getModuleCount(),e=Math.floor(b.width/d),f=Math.floor(b.height/d),g=['<table style="border:0;border-collapse:collapse;">'],h=0;d>h;h++){g.push("<tr>");for(var i=0;d>i;i++)g.push('<td style="border:0;border-collapse:collapse;padding:0;margin:0;width:'+e+"px;height:"+f+"px;background-color:"+(a.isDark(h,i)?b.colorDark:b.colorLight)+';"></td>');g.push("</tr>")}g.push("</table>"),c.innerHTML=g.join("");var j=c.childNodes[0],k=(b.width-j.offsetWidth)/2,l=(b.height-j.offsetHeight)/2;k>0&&l>0&&(j.style.margin=l+"px "+k+"px")},a.prototype.clear=function(){this._el.innerHTML=""},a}();QRCode=function(a,b){if(this._htOption={width:256,height:256,typeNumber:4,colorDark:"#000000",colorLight:"#ffffff",correctLevel:d.H},"string"==typeof b&&(b={text:b}),b)for(var c in b)this._htOption[c]=b[c];"string"==typeof a&&(a=document.getElementById(a)),this._android=n(),this._el=a,this._oQRCode=null,this._oDrawing=new q(this._el,this._htOption),this._htOption.text&&this.makeCode(this._htOption.text)},QRCode.prototype.makeCode=function(a){this._oQRCode=new b(r(a,this._htOption.correctLevel),this._htOption.correctLevel),this._oQRCode.addData(a),this._oQRCode.make(),this._el.title=a,this._oDrawing.draw(this._oQRCode),this.makeImage()},QRCode.prototype.makeImage=function(){"function"==typeof this._oDrawing.makeImage&&(!this._android||this._android>=3)&&this._oDrawing.makeImage()},QRCode.prototype.clear=function(){this._oDrawing.clear()},QRCode.CorrectLevel=d}();
"@

    $htmlPath = Join-Path $env:TEMP "cyberdeck_adb_qr.html"
    $htmlContent = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CYBERDECK // PAREAMENTO ADB WIRELESS HUD</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Rajdhani:wght@600;700&display=swap');

  :root {
    --corpo-name: 'ARASAKA CORP';
    --corpo-pri: #b81428;
    --corpo-pri-light: #d6243c;
    --corpo-sec: #dcdcdc;
    --corpo-bg: #060608;
    --corpo-panel: #0d0d12;
    --corpo-border: #73101d;
    --corpo-border-subtle: rgba(184, 20, 40, 0.35);
    --corpo-glow: rgba(184, 20, 40, 0.18);
    --corpo-badge: #1a080c;
  }

  body.theme-arasaka {
    --corpo-name: 'ARASAKA CORP';
    --corpo-pri: #b81428;
    --corpo-pri-light: #d6243c;
    --corpo-sec: #dcdcdc;
    --corpo-bg: #060608;
    --corpo-panel: #0d0d12;
    --corpo-border: #73101d;
    --corpo-border-subtle: rgba(184, 20, 40, 0.35);
    --corpo-glow: rgba(184, 20, 40, 0.18);
    --corpo-badge: #1a080c;
  }

  body.theme-trauma {
    --corpo-name: 'TRAUMA TEAM INTL';
    --corpo-pri: #00bf66;
    --corpo-pri-light: #00ff88;
    --corpo-sec: #ffffff;
    --corpo-bg: #020b06;
    --corpo-panel: #06160e;
    --corpo-border: #055e34;
    --corpo-border-subtle: rgba(0, 191, 102, 0.35);
    --corpo-glow: rgba(0, 191, 102, 0.18);
    --corpo-badge: #032012;
  }

  body.theme-militech {
    --corpo-name: 'MILITECH ARMAMENTS';
    --corpo-pri: #d4c208;
    --corpo-pri-light: #fcee0a;
    --corpo-sec: #dcdcdc;
    --corpo-bg: #080805;
    --corpo-panel: #14130b;
    --corpo-border: #696005;
    --corpo-border-subtle: rgba(212, 194, 8, 0.35);
    --corpo-glow: rgba(212, 194, 8, 0.18);
    --corpo-badge: #201e05;
  }

  body.theme-kangtao {
    --corpo-name: 'KANG TAO SMART-TECH';
    --corpo-pri: #00b4cc;
    --corpo-pri-light: #00f0ff;
    --corpo-sec: #00ffaa;
    --corpo-bg: #020a0e;
    --corpo-panel: #04141c;
    --corpo-border: #035361;
    --corpo-border-subtle: rgba(0, 180, 204, 0.35);
    --corpo-glow: rgba(0, 180, 204, 0.18);
    --corpo-badge: #021f2b;
  }

  body.theme-netwatch {
    --corpo-name: 'NETWATCH BLACKWALL';
    --corpo-pri: #c90064;
    --corpo-pri-light: #ff007f;
    --corpo-sec: #b537ff;
    --corpo-bg: #08000b;
    --corpo-panel: #13001b;
    --corpo-border: #660033;
    --corpo-border-subtle: rgba(201, 0, 100, 0.35);
    --corpo-glow: rgba(201, 0, 100, 0.18);
    --corpo-badge: #22002d;
  }

  body.theme-afterlife {
    --corpo-name: 'AFTERLIFE EDGERUNNERS';
    --corpo-pri: #ccb800;
    --corpo-pri-light: #ffe600;
    --corpo-sec: #00ffcc;
    --corpo-bg: #08090c;
    --corpo-panel: #10121a;
    --corpo-border: #635a02;
    --corpo-border-subtle: rgba(204, 184, 0, 0.35);
    --corpo-glow: rgba(204, 184, 0, 0.18);
    --corpo-badge: #211d04;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background-color: var(--corpo-bg);
    color: #cfd6df;
    font-family: 'Share Tech Mono', 'Consolas', monospace;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 24px;
    background-image: 
      radial-gradient(ellipse at center, rgba(184, 20, 40, 0.04) 0%, transparent 70%),
      linear-gradient(rgba(0, 0, 0, 0.75) 0%, rgba(0, 0, 0, 0.75) 100%);
  }

  .scanlines {
    position: fixed;
    top: 0; left: 0; width: 100%; height: 100%;
    pointer-events: none;
    background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.22) 50%);
    background-size: 100% 3px;
    z-index: 1;
    opacity: 0.6;
  }

  .hud-frame {
    background: var(--corpo-panel);
    border: 1px solid var(--corpo-border);
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.7), 0 0 16px var(--corpo-glow), inset 0 0 30px rgba(0, 0, 0, 0.9);
    max-width: 600px;
    width: 100%;
    position: relative;
    padding: 22px 26px;
    border-radius: 4px;
    z-index: 5;
  }

  .hud-corner {
    position: absolute;
    width: 12px;
    height: 12px;
    pointer-events: none;
  }
  .hud-corner.tl { top: -2px; left: -2px; border-top: 2px solid var(--corpo-pri); border-left: 2px solid var(--corpo-pri); }
  .hud-corner.tr { top: -2px; right: -2px; border-top: 2px solid var(--corpo-pri); border-right: 2px solid var(--corpo-pri); }
  .hud-corner.bl { bottom: -2px; left: -2px; border-bottom: 2px solid var(--corpo-pri); border-left: 2px solid var(--corpo-pri); }
  .hud-corner.br { bottom: -2px; right: -2px; border-bottom: 2px solid var(--corpo-pri); border-right: 2px solid var(--corpo-pri); }

  .hud-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    padding-bottom: 8px;
    margin-bottom: 14px;
    font-size: 11px;
    letter-spacing: 1.2px;
    color: #777;
  }

  .hud-brand {
    color: var(--corpo-pri-light);
    font-weight: bold;
    text-transform: uppercase;
    font-size: 11px;
  }

  .hud-status {
    color: #88929b;
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 10px;
  }

  .status-led {
    width: 6px;
    height: 6px;
    background: var(--corpo-pri);
    border-radius: 50%;
    box-shadow: 0 0 6px var(--corpo-pri);
    animation: blink 1.6s infinite ease-in-out;
  }

  @keyframes blink {
    0%, 100% { opacity: 0.9; }
    50% { opacity: 0.25; }
  }

  h1 {
    font-family: 'Rajdhani', sans-serif;
    font-size: 24px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: var(--corpo-pri-light);
    text-shadow: 0 0 10px var(--corpo-glow);
    margin-bottom: 3px;
    text-align: center;
  }

  .subtitle {
    font-size: 11px;
    color: #888;
    text-align: center;
    letter-spacing: 1.8px;
    margin-bottom: 14px;
    text-transform: uppercase;
  }

  .quote-bar {
    background: rgba(0, 0, 0, 0.45);
    border-left: 2px solid var(--corpo-pri);
    padding: 6px 12px;
    font-size: 11px;
    color: #aaa;
    margin-bottom: 16px;
    font-style: italic;
  }

  .qr-scanner-wrap {
    position: relative;
    width: 272px;
    height: 272px;
    margin: 10px auto 16px auto;
    background: #ffffff;
    border: 1px solid var(--corpo-border);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.6), 0 0 10px var(--corpo-glow);
    display: block;
    padding: 16px;
    box-sizing: border-box;
    border-radius: 3px;
    z-index: 10;
  }

  .qr-reticle {
    position: absolute;
    width: 12px;
    height: 12px;
    pointer-events: none;
  }
  .qr-reticle.tl { top: -3px; left: -3px; border-top: 2px solid var(--corpo-pri); border-left: 2px solid var(--corpo-pri); }
  .qr-reticle.tr { top: -3px; right: -3px; border-top: 2px solid var(--corpo-pri); border-right: 2px solid var(--corpo-pri); }
  .qr-reticle.bl { bottom: -3px; left: -3px; border-bottom: 2px solid var(--corpo-pri); border-left: 2px solid var(--corpo-pri); }
  .qr-reticle.br { bottom: -3px; right: -3px; border-bottom: 2px solid var(--corpo-pri); border-right: 2px solid var(--corpo-pri); }

  #qrcode {
    width: 240px;
    height: 240px;
    display: block;
    margin: 0 auto;
    background: #ffffff;
    position: relative;
  }

  /* CRITICAL: Force canvas hidden so only the <img> created by QRCode is shown */
  #qrcode canvas {
    display: none !important;
  }

  #qrcode img {
    width: 240px !important;
    height: 240px !important;
    max-width: 240px !important;
    max-height: 240px !important;
    aspect-ratio: 1 / 1 !important;
    object-fit: contain !important;
    display: block !important;
    margin: 0 auto !important;
    image-rendering: pixelated;
  }

  .telemetry-row {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
    margin-bottom: 14px;
  }

  .telemetry-card {
    background: var(--corpo-badge);
    border: 1px solid var(--corpo-border);
    padding: 8px 12px;
    border-radius: 3px;
  }

  .telemetry-label {
    font-size: 9px;
    letter-spacing: 1px;
    color: #777;
    text-transform: uppercase;
    margin-bottom: 3px;
  }

  .telemetry-val {
    font-size: 14px;
    font-weight: bold;
    color: #e5e5e5;
    letter-spacing: 1.2px;
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .copy-btn {
    background: transparent;
    border: 1px solid var(--corpo-border);
    color: var(--corpo-pri-light);
    font-family: 'Share Tech Mono', monospace;
    font-size: 9px;
    padding: 2px 7px;
    cursor: pointer;
    text-transform: uppercase;
    transition: all 0.2s;
  }

  .copy-btn:hover {
    background: var(--corpo-pri);
    color: #fff;
  }

  .directive-box {
    background: rgba(0, 0, 0, 0.5);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-left: 3px solid var(--corpo-pri);
    padding: 12px 15px;
    font-size: 11px;
    line-height: 1.6;
    color: #aaa;
    margin-bottom: 12px;
    border-radius: 2px;
  }

  .directive-header {
    font-family: 'Rajdhani', sans-serif;
    font-size: 13px;
    font-weight: bold;
    color: var(--corpo-pri-light);
    letter-spacing: 1.2px;
    text-transform: uppercase;
    margin-bottom: 4px;
  }

  .step-num {
    color: var(--corpo-pri-light);
    font-weight: bold;
  }

  .highlight {
    color: #e0e0e0;
    font-weight: bold;
  }

  .hud-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-top: 1px solid rgba(255, 255, 255, 0.08);
    padding-top: 8px;
    font-size: 9px;
    color: #555;
    letter-spacing: 0.8px;
    text-transform: uppercase;
  }
</style>
</head>
<body class="theme-$corpoKey">
<div class="scanlines"></div>

<div class="hud-frame">
  <div class="hud-corner tl"></div>
  <div class="hud-corner tr"></div>
  <div class="hud-corner bl"></div>
  <div class="hud-corner br"></div>

  <div class="hud-top">
    <div class="hud-brand" id="brandText">$activeBrand</div>
    <div class="hud-status">
      <div class="status-led"></div>
      <span>OPTICAL SCAN READY</span>
    </div>
  </div>

  <h1>ADB WIRELESS PAIRING</h1>
  <div class="subtitle">[ANDROID 11+] MATRIZ NEURAL SEM FIO // QR CODE</div>

  <div class="quote-bar" id="quoteText">
    $activeQuote
  </div>

  <div class="qr-scanner-wrap">
    <div class="qr-reticle tl"></div>
    <div class="qr-reticle tr"></div>
    <div class="qr-reticle bl"></div>
    <div class="qr-reticle br"></div>
    <div id="qrcode"></div>
  </div>

  <div class="telemetry-row">
    <div class="telemetry-card">
      <div class="telemetry-label">// IDENTIFICADOR DE REDE</div>
      <div class="telemetry-val">
        <span>$serviceName</span>
      </div>
    </div>
    <div class="telemetry-card">
      <div class="telemetry-label">// CODIGO PIN (6 DIGITOS)</div>
      <div class="telemetry-val">
        <span id="pairCodeVal">$pairCode</span>
        <button class="copy-btn" onclick="copyCode()" id="copyBtn">COPIAR</button>
      </div>
    </div>
  </div>

  <div class="directive-box">
    <div class="directive-header">DIRECTIVA TATICA NO SMARTPHONE:</div>
    <div><span class="step-num">[01]</span> Conecte o celular e este computador na <span class="highlight">MESMA REDE WI-FI</span>.</div>
    <div><span class="step-num">[02]</span> No celular: <span class="highlight">Configuracoes &gt; Opcoes do desenvolvedor</span>.</div>
    <div><span class="step-num">[03]</span> Ative a chave <span class="highlight">Depuracao sem fio (Wireless debugging)</span>.</div>
    <div><span class="step-num">[04]</span> Toque em <span class="highlight">"Parear dispositivo com codigo QR"</span>.</div>
    <div><span class="step-num">[05]</span> Aponte a camera do telefone para a matriz QR acima!</div>
  </div>

  <div class="hud-footer">
    <span>CYBERDECK OS v39.0 // NIGHT CITY EDITION</span>
    <span>TERMINAL LINK: ACTIVE</span>
  </div>
</div>

<script>
$embeddedJs

var qrText = "$qrPayload";
if (typeof QRCode !== 'undefined') {
  new QRCode(document.getElementById('qrcode'), {
    text: qrText,
    width: 240,
    height: 240,
    colorDark : '#000000',
    colorLight : '#ffffff',
    correctLevel : QRCode.CorrectLevel.M
  });
}

function copyCode() {
  var code = document.getElementById('pairCodeVal').innerText.trim();
  function showSuccess() {
    var btn = document.getElementById('copyBtn');
    btn.innerText = 'COPIADO!';
    btn.style.background = 'var(--corpo-pri)';
    btn.style.color = '#fff';
    setTimeout(function() {
      btn.innerText = 'COPIAR';
      btn.style.background = 'transparent';
      btn.style.color = '';
    }, 2000);
  }
  if (navigator.clipboard && window.isSecureContext) {
    navigator.clipboard.writeText(code).then(showSuccess).catch(function() { fallbackCopy(code); });
  } else {
    fallbackCopy(code);
  }
  function fallbackCopy(text) {
    var textArea = document.createElement("textarea");
    textArea.value = text;
    textArea.style.position = "fixed";
    textArea.style.left = "-9999px";
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    try { document.execCommand('copy'); showSuccess(); } catch (err) {}
    document.body.removeChild(textArea);
  }
}
</script>
</body>
</html>

"@

    Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8
    Write-Host "  [OK] Matriz QR Code neural gerada com sucesso!" -ForegroundColor Green
    Write-Host "  [HUD] Abrindo tela tatica Cyberpunk no seu navegador padrao..." -ForegroundColor Cyan
    Write-Host "  Caminho local: $htmlPath" -ForegroundColor DarkGray
    Write-Host ""
    Start-Process $htmlPath

    Write-Host "  ========================================================================" -ForegroundColor Yellow
    Write-Host "  DADOS DE PAREAMENTO (Exibidos na tela tatica):" -ForegroundColor White
    Write-Host "    - Nome do Servico: $serviceName" -ForegroundColor Cyan
    Write-Host "    - Codigo PIN     : $pairCode" -ForegroundColor Yellow
    Write-Host "  ========================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Instrucoes rapidas no celular:" -ForegroundColor White
    Write-Host "    1. Conecte no mesmo Wi-Fi deste PC." -ForegroundColor DarkGray
    Write-Host "    2. Va em: Opcoes do desenvolvedor > Depuracao sem fio." -ForegroundColor DarkGray
    Write-Host "    3. Toque em 'Parear dispositivo com codigo QR' e aponte a camera." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Se o seu aparelho pedir IP e Porta manual, use o Pareamento por Codigo."' -ForegroundColor Yellow

    if ($AdbPath -and (Test-Path $AdbPath)) {
        Write-Host ""
        Write-Host "  Deseja que o CyberDeck aguarde a conexao automatica do dispositivo agora? [S/N]" -ForegroundColor Cyan
        $aguardar = Read-Host "Opcao"
        if ($aguardar -match "^[sSyY]") {
            Write-Host "`n  Aguardando handshake do aparelho Android (15s)..." -ForegroundColor Yellow
            $start = Get-Date
            $conectou = $false
            while (((Get-Date) - $start).TotalSeconds -lt 15) {
                $devs = & $AdbPath devices 2>$null
                $active = ($devs | Where-Object { $_ -match "\s+device$" -or $_ -match "\s+recovery$" })
                if ($active) {
                    Write-Host "`n  [CONECTADO COM SUCESSO!] Dispositivo pareado detectado no terminal!" -ForegroundColor Green
                    Write-Host '  [LUCY // Edgerunners 1]: "Link neural ativo. Aparelho reconhecido."' -ForegroundColor Cyan
                    $conectou = $true
                    break
                }
                Start-Sleep -Seconds 2
                Write-Host "." -NoNewline -ForegroundColor DarkGray
            }
            if (-not $conectou) {
                Write-Host "`n  [AVISO] Conexao automatica expirou. Se o aparelho pareou, pode verificar no menu principal do ADB." -ForegroundColor Yellow
            }
        }
    }
}

function Show-MobileDebugGuide {
    param([string]$AdbPath = "")
    while ($true) {
        Clear-Host
        Show-BootBanner "[GUIA] COMO ATIVAR DEPURACAO USB E MODO DESENVOLVEDOR"
        Write-Host '  [VIKTOR VEKTOR // CP2077]: "Cada fabricante esconde a porta de acesso do sistema. Vamos abrir a sua."' -ForegroundColor Green
        Write-Host '  [LUCY // Edgerunners 1]: "Digite a marca ou modelo do seu aparelho para ver o passo a passo exato."' -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Modelos suportados com instrucoes personalizadas:" -ForegroundColor DarkGray
        Write-Host "    - Samsung (Galaxy S, A, M, Z, Note, One UI)" -ForegroundColor White
        Write-Host "    - Xiaomi / Redmi / POCO (MIUI e HyperOS)" -ForegroundColor White
        Write-Host "    - Motorola / Lenovo (Moto G, Edge, E, etc.)" -ForegroundColor White
        Write-Host "    - iPhone / iPad (Apple iOS 12 ao iOS 18+)" -ForegroundColor White
        Write-Host "    - Realme / OPPO / OnePlus (Realme UI / ColorOS)" -ForegroundColor White
        Write-Host "    - Google Pixel, Asus (ROG/Zenfone), LG, Sony e Android Geral" -ForegroundColor White
        Write-Host "    - [QR] Pareamento sem fio via QR Code (Android 11+)" -ForegroundColor Yellow
        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host ""
        $modelo = Read-Host "Qual o modelo do seu celular Android ou iPhone? Digite o modelo por favor (ou 0 para voltar)"
        if ([string]::IsNullOrWhiteSpace($modelo) -or $modelo -eq "0") { break }

        $m = $modelo.Trim().ToLower()

        Clear-Host
        Show-BootBanner "[GUIA DE ATIVACAO] RESULTADO PARA: $($modelo.ToUpper())"

        if ($m -match "iphone|apple|ios|ipad") {
            Write-Host "  ========================================================================" -ForegroundColor Magenta
            Write-Host "  [GUIA PASSO A PASSO // IPHONE E IPAD (APPLE IOS)]" -ForegroundColor Magenta
            Write-Host "  ========================================================================" -ForegroundColor Magenta
            Write-Host '  [HANAKO ARASAKA // CP2077]: "O iOS isola aplicativos por sandbox e nao usa ADB."' -ForegroundColor White
            Write-Host "  A comunicacao segura e feita por autorizacao de certificado e 'Modo de Desenvolvedor'." -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "  [PASSO 1 - CONEXAO VIA CABO E CONFIANCA]:" -ForegroundColor Cyan
            Write-Host "    1. Desbloqueie a tela do iPhone com Face ID / Touch ID ou codigo." -ForegroundColor White
            Write-Host "    2. Conecte o cabo Lightning ou USB-C original no iPhone e no PC." -ForegroundColor White
            Write-Host "    3. Na tela do iPhone surgira uma mensagem: 'CONFIAR NESTE COMPUTADOR?'" -ForegroundColor Yellow
            Write-Host "    4. Toque em 'CONFIAR' e digite seu codigo numerico de desbloqueio." -ForegroundColor Green
            Write-Host ""
            Write-Host "  [PASSO 2 - MODO DE DESENVOLVEDOR (IOS 16, 17, 18+)]:" -ForegroundColor Cyan
            Write-Host "    1. Abra o aplicativo 'Ajustes' no iPhone." -ForegroundColor White
            Write-Host "    2. Toque em 'Privacidade e Seguranca'." -ForegroundColor White
            Write-Host "    3. Role ate o final da pagina e toque em 'Modo de Desenvolvedor'." -ForegroundColor White
            Write-Host "    4. Ative a chave seletora e toque em 'Reiniciar'." -ForegroundColor Yellow
            Write-Host "    5. Apos reiniciar, desbloqueie a tela, toque em 'Ativar' e digite a senha." -ForegroundColor Green
            Write-Host ""
            Write-Host "  [SOLUCAO DE PROBLEMAS NO IPHONE]:" -ForegroundColor Red
            Write-Host "    Se a mensagem 'Confiar neste computador' nao aparecer ao plugar o cabo:" -ForegroundColor DarkGray
            Write-Host "    No iPhone: Ajustes > Geral > Transferir ou Redefinir o iPhone > Redefinir >" -ForegroundColor DarkGray
            Write-Host "    Toque em 'Redefinir Localizacao e Privacidade'. Desconecte e reconecte o cabo USB." -ForegroundColor DarkGray
            Write-Host "  ========================================================================" -ForegroundColor Magenta
        }
        elseif ($m -match "samsung|galaxy|one\s*ui|a[0-9]|s[0-9]|m[0-9]|z\s*flip|z\s*fold|note") {
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  [GUIA PASSO A PASSO // SAMSUNG GALAXY (ONE UI)]" -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  1. Abra o aplicativo 'Configuracoes'." -ForegroundColor White
            Write-Host "  2. Role ate o final e toque em 'Sobre o telefone'." -ForegroundColor White
            Write-Host "  3. Toque em 'Informacoes do software'." -ForegroundColor White
            Write-Host "  4. Toque 7 VEZES SEGUIDAS em 'Numero de compilacao'." -ForegroundColor Yellow
            Write-Host "     (Se pedir senha ou padrao de tela, digite-a. Surgira: 'O modo de desenvolvedor foi ativado!')" -ForegroundColor DarkGray
            Write-Host "  5. Volte duas vezes ate a tela principal de 'Configuracoes'." -ForegroundColor White
            Write-Host "  6. No final da lista (abaixo de 'Sobre o telefone'), toque em 'Opcoes do desenvolvedor'." -ForegroundColor White
            Write-Host "  7. Ative a chave 'Depuracao USB' e confirme em 'OK'." -ForegroundColor Green
            Write-Host "  8. Conecte o cabo USB ao computador com a tela desbloqueada." -ForegroundColor White
            Write-Host "  9. Na tela do celular, marque 'Sempre permitir a partir deste computador' e toque em 'Permitir'." -ForegroundColor Green
            Write-Host ""
            Write-Host "  * DICA SAMSUNG ONE UI 6 / 6.1+: Se tiver 'Bloqueador Automatico' (Auto Blocker) ativado em" -ForegroundColor Yellow
            Write-Host "    Configuracoes > Seguranca e Privacidade, desative-o temporariamente para liberar o ADB." -ForegroundColor Yellow
            Write-Host "  ========================================================================" -ForegroundColor Green
        }
        elseif ($m -match "xiaomi|redmi|poco|miui|hyper\s*os|black\s*shark") {
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  [GUIA PASSO A PASSO // XIAOMI, REDMI E POCO (MIUI / HYPEROS)]" -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  1. Abra o aplicativo 'Configuracoes'." -ForegroundColor White
            Write-Host "  2. Toque em 'Sobre o telefone' (logo no topo)." -ForegroundColor White
            Write-Host "  3. Toque 7 VEZES SEGUIDAS em 'Versao do SO' (HyperOS) ou 'Versao da MIUI'." -ForegroundColor Yellow
            Write-Host "     (Surgira a mensagem: 'Voce agora e um desenvolvedor!')" -ForegroundColor DarkGray
            Write-Host "  4. Volte para a tela inicial de 'Configuracoes' e toque em 'Configuracoes adicionais'." -ForegroundColor White
            Write-Host "  5. Toque em 'Opcoes do desenvolvedor'." -ForegroundColor White
            Write-Host "  6. Ative a chave 'Depuracao USB' (aguarde a contagem de 10s da Xiaomi e confirme)." -ForegroundColor Green
            Write-Host "  7. [IMPORTANTE NA XIAOMI] Ative tambem:" -ForegroundColor Yellow
            Write-Host "     - 'Instalar via USB'" -ForegroundColor Cyan
            Write-Host "     - 'Depuracao USB (Configuracoes de Seguranca)'" -ForegroundColor Cyan
            Write-Host "     (Nota: A Xiaomi exige chip SIM inserido e login na Conta Mi para essas duas chaves)." -ForegroundColor DarkGray
            Write-Host "  8. Conecte o cabo USB, marque 'Sempre permitir' e toque em 'OK'." -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
        }
        elseif ($m -match "motorola|moto|lenovo|edge|g[0-9]|e[0-9]") {
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  [GUIA PASSO A PASSO // MOTOROLA (MOTO G, EDGE, E, LENOVO)]" -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  1. Abra o aplicativo 'Configuracoes'." -ForegroundColor White
            Write-Host "  2. Role ate o final e toque em 'Sobre o telefone' (ou 'Sistema > Sobre o telefone')." -ForegroundColor White
            Write-Host "  3. Desca ate o final e toque 7 VEZES SEGUIDAS em 'Numero da versao'." -ForegroundColor Yellow
            Write-Host "  4. Volte para 'Configuracoes > Sistema > Avancado > Opcoes do desenvolvedor'." -ForegroundColor White
            Write-Host "  5. Ative a chave 'Depuracao USB' e confirme em 'OK'." -ForegroundColor Green
            Write-Host "  6. Conecte o cabo USB ao computador." -ForegroundColor White
            Write-Host "  7. Na tela do celular, marque 'Sempre permitir a partir deste computador' e toque em 'Permitir'." -ForegroundColor Green
            Write-Host ""
            Write-Host "  * DICA MOTOROLA: Se nao for detectado, abra a barra de notificacoes e mude de" -ForegroundColor Yellow
            Write-Host "    'Apenas carregando' para 'Transferencia de arquivos (MTP)'." -ForegroundColor Yellow
            Write-Host "  ========================================================================" -ForegroundColor Green
        }
        elseif ($m -match "realme|oppo|oneplus|color\s*os|oxygen") {
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  [GUIA PASSO A PASSO // REALME, OPPO E ONEPLUS (COLOROS / REALME UI)]" -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  1. Abra 'Configuracoes > Sobre o dispositivo > Versao'." -ForegroundColor White
            Write-Host "  2. Toque 7 VEZES SEGUIDAS em 'Numero da versao' (Build number)." -ForegroundColor Yellow
            Write-Host "  3. Volte para 'Configuracoes > Configuracoes adicionais (ou Configuracoes do sistema)'." -ForegroundColor White
            Write-Host "  4. Toque em 'Opcoes do desenvolvedor'." -ForegroundColor White
            Write-Host "  5. Ative a chave 'Depuracao USB' e confirme." -ForegroundColor Green
            Write-Host "  6. Conecte o cabo USB e autorize a chave RSA do computador na tela." -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
        }
        elseif ($m -match "qr|wifi|wi-fi|sem\s*fio") {
            Show-AdbQrCodePairing -AdbPath $AdbPath
            Pause-Cyber
            continue
        }
        else {
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  [GUIA PASSO A PASSO // ANDROID GERAL (PIXEL, ASUS, LG, SONY, ETC.)]" -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
            Write-Host "  1. Abra o aplicativo 'Configuracoes'." -ForegroundColor White
            Write-Host "  2. Toque em 'Sobre o telefone' (ou 'Sistema > Sobre o dispositivo')." -ForegroundColor White
            Write-Host "  3. Toque 7 VEZES SEGUIDAS em 'Numero da versao' ou 'Numero de compilacao'." -ForegroundColor Yellow
            Write-Host "     (Surgira a mensagem de confirmacao de desenvolvedor ativado)" -ForegroundColor DarkGray
            Write-Host "  4. Volte e toque em 'Sistema > Opcoes do desenvolvedor'." -ForegroundColor White
            Write-Host "  5. Ative a chave 'Depuracao USB' e confirme em 'OK'." -ForegroundColor Green
            Write-Host "  6. Conecte o cabo USB ao computador com a tela desbloqueada." -ForegroundColor White
            Write-Host "  7. Marque 'Sempre permitir a partir deste computador' e toque em 'Permitir'." -ForegroundColor Green
            Write-Host "  ========================================================================" -ForegroundColor Green
        }

        # Opcao de QR Code para Android
        if ($m -notmatch "iphone|apple|ios|ipad") {
            Write-Host ""
            Write-Host "  ========================================================================" -ForegroundColor Cyan
            Write-Host "  [DEPURACAO SEM FIO VIA QR CODE - ANDROID 11+]" -ForegroundColor Cyan
            Write-Host "  Disponivel em celulares modernos: conecte sem cabos via Wi-Fi!" -ForegroundColor DarkGray
            Write-Host "  ========================================================================" -ForegroundColor Cyan
            $qrResp = Read-Host "Deseja gerar o QR Code de Pareamento sem Fio na tela agora? [S/N]"
            if ($qrResp -match "^[sS]$") {
                Show-AdbQrCodePairing -AdbPath $AdbPath
            }
        }

        Pause-Cyber
    }
}

function Ensure-AdbConnection {
    param([string]$AdbPath)
    Write-Host "`n========================================================================" -ForegroundColor Cyan
    Write-Host "  [CONEXAO ANDROID DEBUG BRIDGE (ADB)] CABO USB OU ADB SEM FIO (WI-FI)" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host '  [LUCY // Edgerunners 1]: "Nota tecnica: o ADB nativo opera por Cabo USB ou Depuracao sem fio (Wi-Fi/IP).' -ForegroundColor Cyan
    Write-Host '   Bluetooth nao transporta sessao ADB no Android, entao use USB ou pareamento Wi-Fi."' -ForegroundColor White
    Write-Host ""

    $rawDevs = & $AdbPath devices 2>&1
    $online = @()
    foreach ($line in $rawDevs) {
        if ($line -match "^(\S+)\s+device$") { $online += $matches[1] }
        elseif ($line -match "^(\S+)\s+unauthorized$") {
            Write-Host "  [ALERTA] Dispositivo '$($matches[1])' conectado, mas NAO AUTORIZADO!" -ForegroundColor Yellow
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Olhe a tela do celular e toque em PERMITIR DEPURACAO USB!"' -ForegroundColor Green
        }
    }

    if ($online.Count -gt 0) {
        Write-Host "  [OK] Celular Android conectado via ADB: $($online -join ', ')" -ForegroundColor Green
        return $online[0]
    }

    Write-Host "  [AVISO] Nenhum dispositivo Android autorizado detectado no momento." -ForegroundColor Yellow
    Write-Host "  [1] Ja conectei o Cabo USB e aceitei na tela -> Tentar detectar novamente" -ForegroundColor Green
    Write-Host "  [2] Conectar via ADB Sem Fio (Wi-Fi IP:Porta - Android 11+)" -ForegroundColor Cyan
    Write-Host "  [3] Gerar QR Code para Pareamento Wi-Fi na Tela (Android 11+)" -ForegroundColor Yellow
    Write-Host "  [4] Como ativar Depuracao no meu modelo de celular (Guia Interativo)" -ForegroundColor Magenta
    Write-Host "  [0] Continuar sem ADB (Modo Checklist / Auditoria de Rede)" -ForegroundColor DarkGray
    $c = Read-Host "Escolha [0-4]"
    if ($c -eq "3") {
        Show-AdbQrCodePairing -AdbPath $AdbPath
        return (Ensure-AdbConnection -AdbPath $AdbPath)
    } elseif ($c -eq "4") {
        Show-MobileDebugGuide -AdbPath $AdbPath
        return (Ensure-AdbConnection -AdbPath $AdbPath)
    } elseif ($c -eq "1") {
        $null = & $AdbPath kill-server 2>&1
        $null = & $AdbPath start-server 2>&1
        Start-Sleep -Seconds 1
        $raw2 = & $AdbPath devices 2>&1
        foreach ($line in $raw2) {
            if ($line -match "^(\S+)\s+device$") {
                Write-Host "  [OK] Conectado: $($matches[1])" -ForegroundColor Green
                return $matches[1]
            }
        }
        Write-Host '  [REBECCA // Edgerunners 1]: "Ainda nao apareceu! Confere se a Depuracao USB esta ligada nas Opcoes do Desenvolvedor."' -ForegroundColor Red
    } elseif ($c -eq "2") {
        Write-Host "`n  No celular: Configuracoes > Opcoes do desenvolvedor > Depuracao sem fio:" -ForegroundColor White
        $needPair = Read-Host "Precisa parear o codigo primeiro (adb pair)? [S/N]"
        if ($needPair -match "^[sS]$") {
            $pairAddr = (Read-Host "Digite IP:PORTA de pareamento (ex: 192.168.1.50:37123)").Trim()
            $pairCode = (Read-Host "Digite o codigo de 6 digitos").Trim()
            if ($pairAddr -and $pairCode) {
                $pairOut = & $AdbPath pair $pairAddr $pairCode 2>&1
                foreach ($pl in $pairOut) { Write-Host "  $pl" -ForegroundColor DarkGray }
                Start-Sleep -Seconds 1
                # No Android 11+, muitas vezes o mDNS ja conecta automaticamente apos o pareamento
                $autoDevs = & $AdbPath devices 2>&1
                foreach ($line in $autoDevs) {
                    if ($line -match "^(\S+)\s+device$") {
                        Write-Host "  [OK] Conectado automaticamente via Wi-Fi ADB: $($matches[1])" -ForegroundColor Green
                        return $matches[1]
                    }
                }
            }
        }
        $connAddr = (Read-Host "Digite IP:PORTA principal da Depuracao sem fio (ex: 192.168.1.50:41235 | ENTER para pular)").Trim()
        if ($connAddr) {
            $connOut = & $AdbPath connect $connAddr 2>&1
            foreach ($cl in $connOut) { Write-Host "  $cl" -ForegroundColor DarkGray }
            $raw3 = & $AdbPath devices 2>&1
            foreach ($line in $raw3) {
                if ($line -match "^(\S+)\s+device$") {
                    Write-Host "  [OK] Conectado via Wi-Fi ADB: $($matches[1])" -ForegroundColor Green
                    return $matches[1]
                }
            }
        }
    }
    return $null
}

function Register-MobileExitCleanup {
    if ($script:MobileExitHookRegistered) { return }
    $script:MobileExitHookRegistered = $true
    try {
        $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
            try {
                $null = taskkill.exe /F /IM adb.exe /T 2>$null
                $null = taskkill.exe /F /IM fastboot.exe /T 2>$null
                $null = taskkill.exe /F /IM idevice_id.exe /T 2>$null
                $null = taskkill.exe /F /IM ideviceinfo.exe /T 2>$null
                $null = taskkill.exe /F /IM ideviceinstaller.exe /T 2>$null
                $null = taskkill.exe /F /IM idevicepair.exe /T 2>$null
                $null = taskkill.exe /F /IM idevicediagnostics.exe /T 2>$null
                $null = taskkill.exe /F /IM idevicesyslog.exe /T 2>$null
                $null = taskkill.exe /F /IM idevicebackup2.exe /T 2>$null
                $null = taskkill.exe /F /IM iproxy.exe /T 2>$null
                $null = taskkill.exe /F /IM usbmuxd.exe /T 2>$null
            } catch {}
        } -ErrorAction SilentlyContinue
    } catch {}
}

function Stop-MobileBackgroundProcesses {
    param([string]$AdbPath = $null)
    Write-Host "`n  [ENCERRANDO PROCESSOS MOBILE NO WINDOWS] (ADB Android + libimobiledevice iPhone)..." -ForegroundColor Cyan

    $stopped = @()

    # 1) Encerrar servidor ADB de forma limpa antes de matar o processo
    $adbRunning = Get-Process -Name "adb" -ErrorAction SilentlyContinue
    if ($adbRunning) {
        if (-not $AdbPath) { $AdbPath = Resolve-AdbExe }
        if ($AdbPath -and (Test-Path $AdbPath)) {
            try { $null = & $AdbPath kill-server 2>&1 } catch {}
            Start-Sleep -Milliseconds 400
        }
    }

    # 2) Encerrar processos do Android (ADB/Fastboot) e iPhone (libimobiledevice)
    $targetNames = @(
        "adb", "fastboot",
        "idevice_id", "ideviceinfo", "ideviceinstaller",
        "idevicepair", "idevicediagnostics", "idevicesyslog",
        "idevicebackup2", "iproxy", "usbmuxd"
    )
    foreach ($pname in $targetNames) {
        $procs = Get-Process -Name $pname -ErrorAction SilentlyContinue
        if ($procs) {
            foreach ($pr in $procs) {
                try {
                    Stop-Process -Id $pr.Id -Force -ErrorAction Stop
                    $stopped += "$($pr.ProcessName).exe (PID $($pr.Id))"
                } catch {}
            }
        }
    }

    # 3) Garantir que nenhum executavel das pastas portateis fique travando o Pen Drive
    $root = Get-CyberDeckRoot
    $portableDirs = @(
        (Join-Path $root "ADB ANDROID"),
        (Join-Path $root "LIBIMOBILEDEVICE IPHONE")
    )
    try {
        $allProcs = Get-Process -ErrorAction SilentlyContinue
        foreach ($pr in $allProcs) {
            $exePath = $null
            try { $exePath = $pr.Path } catch {}
            if ($exePath) {
                foreach ($pdir in $portableDirs) {
                    if ($exePath.StartsWith($pdir, [System.StringComparison]::OrdinalIgnoreCase)) {
                        try {
                            Stop-Process -Id $pr.Id -Force -ErrorAction Stop
                            $stopped += "$($pr.ProcessName).exe (PID $($pr.Id))"
                        } catch {}
                    }
                }
            }
        }
    } catch {}

    # Garantia extra via taskkill /F /T para processos 32/64 bits ou filhos travados
    $extraExes = @(
        "adb.exe", "fastboot.exe",
        "idevice_id.exe", "ideviceinfo.exe", "ideviceinstaller.exe",
        "idevicepair.exe", "idevicediagnostics.exe", "idevicesyslog.exe",
        "idevicebackup2.exe", "iproxy.exe", "usbmuxd.exe"
    )
    foreach ($ex in $extraExes) {
        $still = Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($ex)) -ErrorAction SilentlyContinue
        if ($still) {
            try { $null = taskkill.exe /F /IM $ex /T 2>&1 } catch {}
            $stopped += "$ex (taskkill /F /T)"
        }
    }

    $stopped = $stopped | Select-Object -Unique
    if ($stopped.Count -gt 0) {
        Write-Host "  [OK] Processos encerrados no Windows: $($stopped -join ', ')" -ForegroundColor Green
        Write-Host '  [LUCY // Edgerunners 1]: "Conexoes ADB/iPhone encerradas e Pen Drive liberado sem processos presos."' -ForegroundColor Cyan
    } else {
        Write-Host "  [OK] Nenhum processo Android/iPhone ficou aberto em segundo plano no Windows." -ForegroundColor Green
    }
    Start-Sleep -Seconds 1
}

function Get-AndroidPackagesSafe {
    param(
        [string]$AdbPath,
        [string]$DeviceId,
        [string]$PmFlag = "-3"
    )
    if (-not $AdbPath -or -not (Test-Path $AdbPath)) { return @() }

    $targetId = $DeviceId
    $devsOut = & $AdbPath devices 2>&1
    $onlineIds = @()
    foreach ($dLine in $devsOut) {
        if ($dLine -match "^(\S+)\s+device$") { $onlineIds += $matches[1].Trim() }
    }

    if ($onlineIds.Count -gt 0) {
        if (-not $targetId -or ($onlineIds -notcontains $targetId)) {
            $targetId = $onlineIds[0]
        }
    }

    $argsList = @()
    if ($targetId) { $argsList += @("-s", $targetId) }
    $argsList += @("shell", "pm", "list", "packages")
    if ($PmFlag) { $argsList += $PmFlag }

    $rawLines = @(& $AdbPath @argsList 2>&1)
    $pkgs = @()
    foreach ($line in $rawLines) {
        $txt = ($line.ToString()).Trim()
        if ($txt -match "(?i)package:(.+)$") {
            $pName = $matches[1].Trim()
            if ($pName) { $pkgs += $pName }
        } elseif ($txt -match "^([a-zA-Z0-9_]+(\.[a-zA-Z0-9_]+)+)$") {
            $pkgs += $matches[1].Trim()
        }
    }
    return @($pkgs | Select-Object -Unique)
}

function Invoke-AndroidCacheCleanup {
    param([string]$AdbPath, [string]$DeviceId)
    Clear-Host
    Show-BootBanner "[11-CACHE] LIMPEZA DE CACHE DE APPS E ARQUIVOS TEMPORARIOS (USB / WI-FI)"
    Write-Host '  [V // CP2077]: "Limpando entulho digital, caches e miniaturas para acelerar o aparelho sem tocar nos seus dados pessoais."' -ForegroundColor Cyan
    Write-Host '  [ALT CUNNINGHAM // CP2077]: "Caches sao arquivos temporarios de navegacao e midia. Suas senhas, fotos e contas permanecem intactas."' -ForegroundColor Green
    Write-Host ""

    if (-not ($AdbPath -and $DeviceId)) {
        Write-Host "  [MODO GUIA // SEM CELULAR CONECTADO NO ADB]" -ForegroundColor Yellow
        Write-Host "  Para limpar caches diretamente pelo PC via cabo USB ou Wi-Fi:" -ForegroundColor White
        Write-Host "    1. Conecte seu aparelho pela Opcao [6] ou [10] do menu Android." -ForegroundColor DarkGray
        Write-Host "  Instrucoes para limpeza manual no aparelho agora:" -ForegroundColor Cyan
        Write-Host "    - No Android: Configuracoes > Armazenamento > Liberar espaco / Lixo." -ForegroundColor White
        Write-Host "    - Em apps pesados (Instagram, TikTok, WhatsApp, Chrome):" -ForegroundColor White
        Write-Host "      Configuracoes > Aplicativos > toque no app > Armazenamento > 'Limpar cache'." -ForegroundColor Yellow
        Write-Host "      (ATENCAO: toque em 'Limpar cache', e NAO em 'Limpar dados')." -ForegroundColor Red
        Pause-Cyber
        return
    }

    while ($true) {
        Write-Host "`n========================================================================" -ForegroundColor Yellow
        Write-Host "  DISPOSITIVO ALVO: $DeviceId" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host "  [1] LIMPEZA GLOBAL DE CACHES DE TODOS OS APPS (pm trim-caches)" -ForegroundColor Green
        Write-Host "      -> Forca o sistema Android a descarregar caches temporarios de todos os apps instalados." -ForegroundColor DarkGray
        Write-Host "  [2] LIMPAR PASTAS DE CACHE E MINIATURAS DA GALERIA (.thumbnails / .cache / temp)" -ForegroundColor Cyan
        Write-Host "      -> Apaga miniaturas antigas de fotos/videos que acumulam gigabytes no armazenamento." -ForegroundColor DarkGray
        Write-Host "  [3] LIMPEZA COMPLETA (Opcao 1 + Opcao 2 em sequencia)" -ForegroundColor Yellow
        Write-Host "  [4] LIMPAR CACHE DE UM APP ESPECIFICO (Abrir tela tatica de armazenamento do app)" -ForegroundColor Magenta
        Write-Host "  [5] LIMPAR MINIATURAS E CACHE DE STATUS DO WHATSAPP (.Statuses)" -ForegroundColor Green
        Write-Host "  [0] Voltar ao Submenu Android" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Yellow
        $ccOp = Read-Host "Escolha a operacao de cache [0-5]"

        if ($ccOp -eq "0") { break }
        elseif ($ccOp -in @("1", "3")) {
            Write-Host "`n  [1] Executando protocolo 'pm trim-caches' no Android..." -ForegroundColor Cyan
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Requisitando descarte de caches volumosos ao StorageManager do Android..."' -ForegroundColor Green
            $trimOut = & $AdbPath -s $DeviceId shell "pm trim-caches 999999999999" 2>&1
            $trimStr = ($trimOut -join " ")
            if ($trimStr -match "Error" -or $trimStr -match "Failure") {
                Write-Host "  [AVISO] pm trim-caches retornou: $trimStr" -ForegroundColor Yellow
            } else {
                Write-Host "  [SUCESSO] pm trim-caches acionado! O kernel do Android descartou os caches inativos." -ForegroundColor Green
            }
            if ($ccOp -ne "3") { Pause-Cyber; continue }
        }

        if ($ccOp -in @("2", "3")) {
            Write-Host "`n  [2] Limpando pastas de miniaturas (.thumbnails), caches de galeria e temporarios..." -ForegroundColor Cyan
            Write-Host '  [CAPRI // Edgerunners 2]: "Excluindo miniaturas residuais e caches em /sdcard/."' -ForegroundColor Cyan
            $null = & $AdbPath -s $DeviceId shell "rm -rf /sdcard/.thumbnails/* /sdcard/DCIM/.thumbnails/* /sdcard/Pictures/.thumbnails/* /sdcard/.cache/* 2>/dev/null; echo 'DONE'" 2>&1
            $null = & $AdbPath -s $DeviceId shell "rm -rf /sdcard/Android/data/*/cache/* 2>/dev/null; echo 'DONE'" 2>&1
            Write-Host "  [OK] Caches de miniaturas (.thumbnails) e caches de midia liberados com sucesso!" -ForegroundColor Green
            Write-Host '  [LUCY // Edgerunners 1]: "Espaco de armazenamento recuperado sem afetar suas fotos originais."' -ForegroundColor Green
            Pause-Cyber
        }
        elseif ($ccOp -eq "4") {
            Write-Host "`n  [4] LIMPAR CACHE DE APP ESPECIFICO" -ForegroundColor Magenta
            Write-Host "  Apps populares comuns:" -ForegroundColor DarkGray
            Write-Host "    - Google Chrome:   com.android.chrome" -ForegroundColor White
            Write-Host "    - Instagram:       com.instagram.android" -ForegroundColor White
            Write-Host "    - WhatsApp:        com.whatsapp" -ForegroundColor White
            Write-Host "    - TikTok:          com.zhiliaoapp.musically" -ForegroundColor White
            Write-Host "    - YouTube:         com.google.android.youtube" -ForegroundColor White
            Write-Host "    - Facebook:        com.facebook.katana" -ForegroundColor White
            Write-Host ""
            $targetApp = (Read-Host "Digite o nome do pacote (ou 0 para cancelar)").Trim()
            if ([string]::IsNullOrWhiteSpace($targetApp) -or $targetApp -eq "0") { continue }
            
            Write-Host "  Abrindo tela direta de 'Armazenamento e Cache' de '$targetApp' na tela do seu celular..." -ForegroundColor Cyan
            & $AdbPath -s $DeviceId shell "am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:$targetApp" 2>&1 | Out-Null
            Write-Host "  [OK] Tela aberta no smartphone! Toque em 'Armazenamento e cache' e depois em 'Limpar cache'." -ForegroundColor Green
            Pause-Cyber
        }
        elseif ($ccOp -eq "5") {
            Write-Host "`n  [5] LIMPAR CACHE DE STATUS E MINIATURAS DO WHATSAPP" -ForegroundColor Green
            Write-Host '  [REBECCA // Edgerunners 1]: "Status visualizados de outras pessoas ficam guardados na memoria ocupando espaco!"' -ForegroundColor Magenta
            $confWa = Read-Host "Deseja apagar os arquivos temporarios de status (.Statuses) do WhatsApp? [S/N]"
            if ($confWa -match "^[sS]") {
                & $AdbPath -s $DeviceId shell "rm -rf /sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses/* /sdcard/WhatsApp/Media/.Statuses/* 2>/dev/null; echo 'DONE'" 2>&1 | Out-Null
                Write-Host "  [OK] Pasta de status temporarios (.Statuses) limpa com sucesso!" -ForegroundColor Green
            } else {
                Write-Host "  [CANCELADO] Nenhuma alteracao feita." -ForegroundColor DarkGray
            }
            Pause-Cyber
        }
    }
}

function Invoke-AndroidNetworkFlush {
    param([string]$AdbPath, [string]$DeviceId)
    Clear-Host
    Show-BootBanner "[12-NET] LIMPEZA DE REDE, FLUSH DNS E DADOS DE NAVEGACAO (USB / WI-FI)"
    Write-Host '  [JUDY ALVAREZ // CP2077]: "Zerando cache DNS, derrubando sockets zumbis e limpando rastros de rede do comunicador."' -ForegroundColor Cyan
    Write-Host '  [SONGBIRD // CP2077]: "Ideal quando sites nao abrem, conexao fica lenta ou apos alterar configuracoes de Wi-Fi/DNS."' -ForegroundColor Magenta
    Write-Host ""

    if (-not ($AdbPath -and $DeviceId)) {
        Write-Host "  [MODO GUIA // SEM CELULAR CONECTADO NO ADB]" -ForegroundColor Yellow
        Write-Host "  Para executar o Flush DNS e limpeza de rede remotamente pelo PC:" -ForegroundColor White
        Write-Host "    1. Conecte o aparelho via cabo USB ou Pareamento Wi-Fi (Opcao [6] ou [10])." -ForegroundColor DarkGray
        Write-Host "  Como fazer o Flush DNS e limpeza manual no Android agora:" -ForegroundColor Cyan
        Write-Host "    - Flush DNS Instantaneo: Ative o Modo Aviao por 10 segundos e desative." -ForegroundColor White
        Write-Host "    - Limpar Historico e Cache de Sites no Chrome:" -ForegroundColor White
        Write-Host "      Abra o Chrome > toque nos 3 pontinhos > 'Limpar dados de navegacao'." -ForegroundColor Yellow
        Write-Host "    - Redefinir Ajustes de Rede: Configuracoes > Gerenciamento Geral > Redefinir > 'Redefinir configuracoes de rede'." -ForegroundColor White
        Pause-Cyber
        return
    }

    $isWifiConn = ($DeviceId -match ":\d+$")

    while ($true) {
        Write-Host "`n========================================================================" -ForegroundColor Yellow
        Write-Host "  DISPOSITIVO ALVO: $DeviceId $(if ($isWifiConn) { '[CONEXAO VIA WI-FI]' } else { '[CONEXAO VIA CABO USB]' })" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host "  [1] EXECUTAR FLUSH DNS NO CELULAR (Limpar cache do resolvedor DNS / netd)" -ForegroundColor Green
        Write-Host "      -> Forca o descarte da tabela de DNS antiga do Android (equivale a /flushdns)." -ForegroundColor DarkGray
        Write-Host "  [2] LIMPAR HISTORICO E DADOS DE NAVEGACAO / SITES (Google Chrome)" -ForegroundColor Cyan
        Write-Host "      -> Abre com 1 clique a tela nativa de 'Limpar dados' do Chrome no celular ou reset via ADB." -ForegroundColor DarkGray
        Write-Host "  [3] CICLO DO SUBSISTEMA DE REDE (Renovacao de sockets e tabela de rotas)" -ForegroundColor Yellow
        Write-Host "      -> Recarrega as rotas de rede sem reiniciar o aparelho." -ForegroundColor DarkGray
        Write-Host "  [4] COMO REDEFINIR CONFIGURACOES DE REDE DE FABRICA (Guia Passo a Passo)" -ForegroundColor Magenta
        Write-Host "  [0] Voltar ao Submenu Android" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Yellow
        $netOp = Read-Host "Escolha a opcao de rede [0-4]"

        if ($netOp -eq "0") { break }
        elseif ($netOp -eq "1") {
            Write-Host "`n  [FLUSH DNS ANDROID] Executando comandos de descarte de DNS no Android..." -ForegroundColor Cyan
            Write-Host '  [ALT CUNNINGHAM // CP2077]: "Requisitando flush de cache no resolver netd e conexoes ativas..."' -ForegroundColor Red

            Write-Host "  -> Limpando cache de resolucao de nomes (ndc resolver)..." -ForegroundColor White
            $null = & $AdbPath -s $DeviceId shell "ndc resolver flushdefaultif 2>/dev/null; ndc resolver cleannetdns 2>/dev/null; echo 'OK'" 2>&1
            
            Write-Host "  -> Requisitando flush-dns ao servico de conectividade..." -ForegroundColor White
            $null = & $AdbPath -s $DeviceId shell "cmd connectivity flush-dns 2>/dev/null; echo 'OK'" 2>&1
            
            Write-Host "  -> Limpando cache de tabelas de rota IP..." -ForegroundColor White
            $null = & $AdbPath -s $DeviceId shell "ip route flush cache 2>/dev/null; echo 'OK'" 2>&1

            Write-Host "  [SUCESSO] Cache DNS do celular descartado com sucesso!" -ForegroundColor Green
            Write-Host '  [JUDY ALVAREZ // CP2077]: "Tabelas de resolucao limpas. O celular consultara os novos IPs nas proximas requisicoes."' -ForegroundColor Cyan
            Pause-Cyber
        }
        elseif ($netOp -eq "2") {
            Write-Host "`n  [LIMPEZA DE NAVEGACAO E SITES // GOOGLE CHROME]" -ForegroundColor Cyan
            Write-Host "  Escolha o modo de limpeza para o navegador:" -ForegroundColor White
            Write-Host "    [1] ABRIR TELA TATICA NO CELULAR: Dispara direto a janela 'Limpar dados de navegacao' do Chrome" -ForegroundColor Green
            Write-Host "        (Permite a voce selecionar no celular: Historico, Cookies ou Cache, e clicar em Limpar)" -ForegroundColor DarkGray
            Write-Host "    [2] RESET COMPLETO VIA ADB: Limpa todo o cache e dados do Chrome (pm clear com.android.chrome)" -ForegroundColor Red
            Write-Host "        (ATENCAO: Redefine o Chrome para recem-instalado. Remove historico, cookies e logins salvos!)" -ForegroundColor Yellow
            Write-Host "    [3] Abrir detalhes de armazenamento de OUTROS navegadores (Samsung Internet, Firefox, Edge)" -ForegroundColor Magenta
            Write-Host "    [0] Cancelar" -ForegroundColor DarkGray
            $chrOp = Read-Host "Opcao [0-3]"

            if ($chrOp -eq "1") {
                Write-Host "  Disparando tela nativa de 'Limpar Dados' no Google Chrome do aparelho..." -ForegroundColor Cyan
                & $AdbPath -s $DeviceId shell "am start -n com.android.chrome/com.google.android.apps.chrome.Main -d 'chrome://settings/clearBrowserData'" 2>&1 | Out-Null
                Write-Host "  [OK] Tela de 'Limpar dados de navegacao' aberta no seu celular!" -ForegroundColor Green
                Write-Host "  -> Selecione o periodo (ex: 'Todo o periodo') e toque no botao azul 'Limpar dados'." -ForegroundColor Yellow
                Pause-Cyber
            }
            elseif ($chrOp -eq "2") {
                Write-Host "`n  [ALERTA DE SEGURANCA] O comando 'pm clear com.android.chrome' vai zerar totalmente o navegador:" -ForegroundColor Red
                Write-Host "    - Apagara o historico de todos os sites visitados" -ForegroundColor Yellow
                Write-Host "    - Apagara cookies e deslogara de sites abertos no Chrome" -ForegroundColor Yellow
                Write-Host "    - Liberara 100% do cache acumulado" -ForegroundColor Green
                $confChr = Read-Host "Deseja REALMENTE executar o reset completo do Chrome no aparelho? [S/N]"
                if ($confChr -match "^[sS]") {
                    Write-Host "  Executando: adb -s $DeviceId shell pm clear com.android.chrome ..." -ForegroundColor Cyan
                    $resClr = & $AdbPath -s $DeviceId shell "pm clear com.android.chrome" 2>&1
                    $clrStr = ($resClr -join " ")
                    if ($clrStr -match "Success") {
                        Write-Host "  [SUCESSO] Google Chrome resetado! Historico, cache e dados zerados." -ForegroundColor Green
                    } else {
                        Write-Host "  Resultado: $clrStr" -ForegroundColor White
                    }
                } else {
                    Write-Host "  [CANCELADO] Nenhuma alteracao feita no Chrome." -ForegroundColor DarkGray
                }
                Pause-Cyber
            }
            elseif ($chrOp -eq "3") {
                Write-Host "  Navegadores suportados:" -ForegroundColor Cyan
                Write-Host "    - Samsung Internet:  com.sec.android.app.sbrowser" -ForegroundColor White
                Write-Host "    - Mozilla Firefox:   org.mozilla.firefox" -ForegroundColor White
                Write-Host "    - Microsoft Edge:    com.microsoft.emmx" -ForegroundColor White
                Write-Host "    - Brave Browser:     com.brave.browser" -ForegroundColor White
                Write-Host "    - Opera Browser:     com.opera.browser" -ForegroundColor White
                $navPkg = (Read-Host "Digite o pacote do navegador (ex: org.mozilla.firefox)").Trim()
                if ($navPkg -and $navPkg -ne "0") {
                    & $AdbPath -s $DeviceId shell "am start -a android.settings.APPLICATION_DETAILS_SETTINGS -d package:$navPkg" 2>&1 | Out-Null
                    Write-Host "  [OK] Configuracoes de '$navPkg' abertas no celular! Toque em 'Armazenamento > Limpar cache'." -ForegroundColor Green
                }
                Pause-Cyber
            }
        }
        elseif ($netOp -eq "3") {
            Write-Host "`n  [CICLO DE SUBSISTEMA DE REDE]" -ForegroundColor Yellow
            if ($isWifiConn) {
                Write-Host "  [AVISO IMPORTANTE - CONEXAO VIA WI-FI DETECTADA]" -ForegroundColor Yellow
                Write-Host "  Como o seu aparelho esta conectado ao ADB via Wi-Fi sem fio ($DeviceId)," -ForegroundColor White
                Write-Host "  desativar o Wi-Fi remotamente derrubaria a sua propria conexao com este computador!" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "  Executando renovacao segura sem desligar o link Wi-Fi:" -ForegroundColor Cyan
                $null = & $AdbPath -s $DeviceId shell "ndc resolver flushdefaultif 2>/dev/null; ip route flush cache 2>/dev/null" 2>&1
                Write-Host "  [OK] Tabelas de rota e cache de sockets liberados de forma segura!" -ForegroundColor Green
            } else {
                Write-Host "  Aparelho conectado via CABO USB: e possivel reiniciar os adaptadores de rede com seguranca." -ForegroundColor Green
                $cicloConf = Read-Host "Deseja alternar suavemente a conexao de rede para recarregar o stack? [S/N]"
                if ($cicloConf -match "^[sS]") {
                    Write-Host "  Ciclando interface Wi-Fi..." -ForegroundColor Cyan
                    $null = & $AdbPath -s $DeviceId shell "svc wifi disable; sleep 1; svc wifi enable" 2>&1
                    Write-Host "  [OK] Wi-Fi reiniciado no aparelho! Nova requisicao DHCP e DNS efetuada." -ForegroundColor Green
                }
            }
            Pause-Cyber
        }
        elseif ($netOp -eq "4") {
            Write-Host "`n========================================================================" -ForegroundColor Magenta
            Write-Host "  [GUIA] COMO REDEFINIR CONFIGURACOES DE REDE DE FABRICA NO ANDROID" -ForegroundColor Magenta
            Write-Host "========================================================================" -ForegroundColor Magenta
            Write-Host "  Essa opcao resolve problemas cronicos de Wi-Fi caindo, dados moveis 4G/5G lentos ou Bluetooth:" -ForegroundColor White
            Write-Host ""
            Write-Host "  [SAMSUNG GALAXY (ONE UI)]:" -ForegroundColor Green
            Write-Host "    1. Abra: Configuracoes > Gerenciamento Geral." -ForegroundColor White
            Write-Host "    2. Toque em: Restaurar (ou Redefinir)." -ForegroundColor White
            Write-Host "    3. Selecione: 'Redefinir configuracoes de rede móvel / Wi-Fi'." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  [XIAOMI / REDMI / POCO (MIUI / HYPEROS)]:" -ForegroundColor Green
            Write-Host "    1. Abra: Configuracoes > Conexao e Compartilhamento." -ForegroundColor White
            Write-Host "    2. Role ate o final e toque em: 'Redefinir Wi-Fi, redes móveis e Bluetooth'." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  [MOTOROLA / PIXEL / ANDROID GERAL]:" -ForegroundColor Green
            Write-Host "    1. Abra: Configuracoes > Sistema > Opcoes de redefinicao." -ForegroundColor White
            Write-Host "    2. Toque em: 'Redefinir Wi-Fi, rede móvel e Bluetooth'." -ForegroundColor Yellow
            Write-Host "========================================================================" -ForegroundColor Magenta
            Pause-Cyber
        }
    }
}

function Show-IphoneCacheGuide {
    Clear-Host
    Show-BootBanner "[GUIA TATICO] LIMPEZA DE CACHE, SAFARI E FLUSH DNS NO IPHONE (IOS)"
    Write-Host '  [HANAKO ARASAKA // CP2077]: "No iOS, a Apple isola cada app em sandbox. Veja as diretrizes para descarregar caches e resetar redes."' -ForegroundColor Magenta
    Write-Host ""
    Write-Host "  [1] FLUSH DNS NO IPHONE (Reset do Resolvedor DNS):" -ForegroundColor Cyan
    Write-Host "    -> METODO RAPIDO (10s): Abra a Central de Controle e ative o 'Modo Aviao'." -ForegroundColor White
    Write-Host "       Aguarde 10 a 15 segundos e desative o Modo Aviao." -ForegroundColor Yellow
    Write-Host "       (Isso encerra todas as conexoes de rede e forca o descarte total do cache DNS!)." -ForegroundColor Green
    Write-Host "    -> METODO DEFINITIVO (Reset de Conexoes de Rede):" -ForegroundColor White
    Write-Host "       Ajustes > Geral > Transferir ou Redefinir o iPhone > Redefinir >" -ForegroundColor DarkGray
    Write-Host "       Toque em: 'Redefinir Ajustes de Rede' (resolve Wi-Fi caindo ou sites nao abrindo)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [2] LIMPAR HISTORICO E CACHE DE SITES NO SAFARI (Liberar Gigabytes):" -ForegroundColor Cyan
    Write-Host "    1. Abra o app 'Ajustes' no iPhone." -ForegroundColor White
    Write-Host "    2. Role ate 'Safari' (ou busque Safari no topo dos Ajustes)." -ForegroundColor White
    Write-Host "    3. Role a tela para baixo e toque em: 'Limpar Historico e Dados dos Sites'." -ForegroundColor Yellow
    Write-Host "    4. Escolha o periodo ('Todo o Historico') e confirme 'Limpar Historico'." -ForegroundColor Green
    Write-Host "       -> DICA EXTRA: Em Ajustes > Safari > Avancado > 'Dados dos Sites'," -ForegroundColor DarkGray
    Write-Host "          voce pode ver quais sites estao ocupando mais megabytes e apagar individualmente." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] COMO LIMPAR O CACHE DE APPS PESADOS (Instagram, TikTok, WhatsApp):" -ForegroundColor Cyan
    Write-Host "    No iPhone nao existe o botao direto 'Limpar cache' nos ajustes gerais," -ForegroundColor DarkGray
    Write-Host "    mas ha dois truques corporativos oficiais:" -ForegroundColor White
    Write-Host "    -> TRUQUE 1 (Descarregar App sem perder dados):" -ForegroundColor Yellow
    Write-Host "       Ajustes > Geral > Armazenamento do iPhone > toque no app (ex: Instagram, TikTok) >" -ForegroundColor White
    Write-Host "       Toque em 'Desinstalar App' (Offload App) e depois em 'Reinstalar App'." -ForegroundColor Green
    Write-Host "       (Isso mantem seus dados, fotos e contas, mas apaga todo o lixo de cache temporario!)." -ForegroundColor Green
    Write-Host "    -> TRUQUE 2 (Limpeza dentro do proprio App):" -ForegroundColor Yellow
    Write-Host "       - No TikTok: Perfil > Menu (3 barras) > Configuracoes > Liberar espaco > Limpar Cache." -ForegroundColor White
    Write-Host "       - No WhatsApp: Configuracoes > Armazenamento e Dados > Gerenciar Armazenamento." -ForegroundColor White
    Write-Host "       - No Telegram: Configuracoes > Dados e Armazenamento > Uso do Armazenamento > Limpar Cache." -ForegroundColor White
    Write-Host "========================================================================" -ForegroundColor Magenta
    Pause-Cyber
}

function Invoke-MobileAndroid {
    Register-MobileExitCleanup
    Clear-Host
    Show-BootBanner "[18-A] SEGURANCA MOBILE // ANDROID (ADB PORTATIL - USB / WI-FI)"
    Write-Host '  [SONGBIRD // CP2077]: "Iniciando protocolo de varredura neural para Android."' -ForegroundColor Magenta
    Write-Host '  [ALT CUNNINGHAM // CP2077]: "Nada sera apagado ou desinstalado sem voce escolher e confirmar."' -ForegroundColor Red

    $adb = Resolve-AdbExe
    $devId = $null
    if (-not $adb -and (-not $script:SkipAdbPrompt)) {
        Write-Host "`n  [AVISO] Executavel 'adb.exe' nao encontrado na pasta 'ADB ANDROID' nem no PC." -ForegroundColor Yellow
        Write-Host '  [CAPRI // Edgerunners 2]: "Posso baixar o ADB portatil direto na pasta ADB ANDROID do seu pen drive para voce nunca mais precisar instalar!"' -ForegroundColor Cyan
        $inst = Read-Host "Deseja baixar o ADB portatil na pasta 'ADB ANDROID' agora? [S/N]"
        if ($inst -match "^[sS]$") {
            $adb = Install-PortableAdb
        } else {
            $script:SkipAdbPrompt = $true
        }
    }

    if ($adb) {
        Write-Host "  [PORTATIL/OK] Usando ADB em: $adb" -ForegroundColor Green
        $devId = Ensure-AdbConnection -AdbPath $adb
    } else {
        Write-Host '  [DOC // Edgerunners 1]: "Sem adb.exe no momento. Seguindo em modo guia (voce pode baixar na opcao 7 quando quiser)."' -ForegroundColor Magenta
    }

    while ($true) {
        $statusConn = if ($adb -and $devId) { "CONECTADO ($devId)" } elseif ($adb) { "ADB PRONTO (Sem celular)" } else { "SEM ADB (Modo Guia)" }
        Write-Host "`n========================================================================" -ForegroundColor Yellow
        Write-Host "  SUBMENU ANDROID // STATUS ADB: $statusConn" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host "  [1] Verificar APPS NOCIVOS (pacotes externos, instaladores e nomes suspeitos)" -ForegroundColor Green
        Write-Host "  [2] Verificar VIRUS, MALWARE, RANSOMWARE, MINERADORES E BOTNETS (CPU/Rede/Admin)" -ForegroundColor Red
        Write-Host "  [3] Verificar ARQUIVOS CRIPTOGRAFADOS MALICIOSOS (fotos/PDFs falsos, .apk, .enc)" -ForegroundColor Yellow
        Write-Host "  [4] Verificar APPS COM PERMISSOES INDEVIDAS (Acessibilidade, Overlay, SMS, Camera)" -ForegroundColor Magenta
        Write-Host "  [5] CAMADAS EXTRAS: Certificados Raiz, VPN/DNS, Portas ADB Abertas e Play Protect" -ForegroundColor Cyan
        Write-Host "  [6] Reconectar / Parear dispositivo Android via ADB (USB ou Wi-Fi)" -ForegroundColor White
        Write-Host "  [7] Baixar / Atualizar ADB Portatil na pasta 'ADB ANDROID' do Pen Drive" -ForegroundColor DarkCyan
        Write-Host "  [8] REMOVER / DESINSTALAR PACOTE (APP) DO ANDROID (com instrucoes)" -ForegroundColor Red
        Write-Host "  [9] MOSTRAR PACOTES NATIVOS / SISTEMA DO ANDROID (bloatware e fabrica)" -ForegroundColor Yellow
        Write-Host "  [10] Como ativar Depuracao USB / Parear via QR Code (Guia por Modelo)" -ForegroundColor Cyan
        Write-Host "  [11] LIMPEZA DE CACHE DE APPS E ARQUIVOS TEMPORARIOS (USB / Wi-Fi)" -ForegroundColor Green
        Write-Host "  [12] LIMPEZA DE REDE, FLUSH DNS E DADOS DE NAVEGACAO / SITES (USB / Wi-Fi)" -ForegroundColor Cyan
        Write-Host "  [0] Sair e encerrar processos Android/iPhone no Windows" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Yellow
        $sub = Read-Host "Escolha uma opcao [0-12]"

        if ($sub -eq "0") { Stop-MobileBackgroundProcesses -AdbPath $adb; break }
        elseif ($sub -eq "10") { Show-MobileDebugGuide -AdbPath $adb }
        elseif ($sub -eq "11") { Invoke-AndroidCacheCleanup -AdbPath $adb -DeviceId $devId }
        elseif ($sub -eq "12") { Invoke-AndroidNetworkFlush -AdbPath $adb -DeviceId $devId }
        elseif ($sub -eq "7") {
            $adb = Install-PortableAdb
            if ($adb) { $devId = Ensure-AdbConnection -AdbPath $adb }
        }
        elseif ($sub -eq "6") {
            if (-not $adb) { $adb = Resolve-AdbExe }
            if ($adb) { $devId = Ensure-AdbConnection -AdbPath $adb }
            else { Write-Host "  [ERRO] adb.exe nao encontrado. Use a opcao [7] para baixar na pasta 'ADB ANDROID'." -ForegroundColor Red }
        }
        elseif ($sub -eq "9") {
            Write-Host "`n========================================================================" -ForegroundColor Yellow
            Write-Host "  [9] PACOTES NATIVOS / DO SISTEMA NO ANDROID (FABRICA & BLOATWARE)" -ForegroundColor Yellow
            Write-Host "========================================================================" -ForegroundColor Yellow
            Write-Host '  [CAPRI // Edgerunners 2]: "Listando pacotes nativos pre-instalados na imagem do Android (pm list packages -s)."' -ForegroundColor Cyan
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Cuidado: pacotes com.android.* sao do nucleo. Prefira auditar bloatware de fabricante/operadora."' -ForegroundColor Green
            if ($adb) {
                $filtroSys = (Read-Host "`nFiltrar por palavra-chave? (ex: miui, xiaomi, samsung, meta, google | ENTER = listar todos)").Trim()
                $sysRaw = @(Get-AndroidPackagesSafe -AdbPath $adb -DeviceId $devId -PmFlag "-s")
                $sysList = @()
                foreach ($pn in $sysRaw) {
                    if (-not $filtroSys -or $pn.ToLower().Contains($filtroSys.ToLower())) {
                        $sysList += $pn
                    }
                }
                Write-Host "  Total de pacotes nativos encontrados: $($sysList.Count)" -ForegroundColor Yellow
                if ($sysList.Count -gt 0) {
                    $sysList | Sort-Object | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
                } else {
                    Write-Host "  [AVISO] Nenhum pacote nativo retornado. Verifique se o celular esta autorizado no ADB (Opcao [6])." -ForegroundColor Yellow
                }
                Write-Host "`n  [DICA]: Para remover algum bloatware da lista acima, use a Opcao [8] do menu Android." -ForegroundColor Cyan
            } else {
                Write-Host "  [MODO GUIA - SEM ADB]: Conecte o Android pela Opcao [6] (USB ou Wi-Fi) para listar os pacotes nativos reais via 'pm list packages -s'." -ForegroundColor Yellow
                Write-Host "  No celular: Configuracoes > Aplicativos > Gerenciar apps > menu (3 pontinhos) > 'Mostrar todos os apps' (exibe os nativos/sistema)." -ForegroundColor White
            }
        }
        elseif ($sub -eq "8") {
            Write-Host "`n========================================================================" -ForegroundColor Red
            Write-Host "  [8] REMOVER / DESINSTALAR PACOTE NO ANDROID" -ForegroundColor Red
            Write-Host "========================================================================" -ForegroundColor Red
            Write-Host '  [REBECCA // Edgerunners 1]: "Achou algum app lixo ou malware? Manda o nome do pacote que a gente arranca fora!"' -ForegroundColor Red
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Confira bem o nome do pacote antes de confirmar para nao remover algo vital."' -ForegroundColor Green

            if ($adb) {
                Write-Host "`n  Deseja listar os pacotes instalados antes de digitar?" -ForegroundColor Cyan
                Write-Host "    [1] Apps de Terceiros (instalados por voce)" -ForegroundColor Green
                Write-Host "    [2] Apps NATIVOS / do Sistema (fabrica / bloatware)" -ForegroundColor Yellow
                Write-Host "    [3] Todos os pacotes (Terceiros + Nativos)" -ForegroundColor White
                Write-Host "    [0] Pular listagem" -ForegroundColor DarkGray
                $verLista = (Read-Host "Escolha [0-3]").Trim()
                if ($verLista -in @("1","2","3")) {
                    $flagPm = if ($verLista -eq "1") { "-3" } elseif ($verLista -eq "2") { "-s" } else { "" }
                    $lblPm = if ($verLista -eq "1") { "de terceiros" } elseif ($verLista -eq "2") { "nativos/sistema" } else { "totais" }
                    $filtro = (Read-Host "Filtrar por palavra-chave? (ex: xiaomi, miui, google, facebook | ENTER = mostrar todos)").Trim()
                    $rawPkgs = @(Get-AndroidPackagesSafe -AdbPath $adb -DeviceId $devId -PmFlag $flagPm)
                    $listaLimpa = @()
                    foreach ($pn in $rawPkgs) {
                        if (-not $filtro -or $pn.ToLower().Contains($filtro.ToLower())) {
                            $listaLimpa += $pn
                        }
                    }
                    Write-Host "  Pacotes $lblPm encontrados ($($listaLimpa.Count)):" -ForegroundColor Cyan
                    if ($listaLimpa.Count -gt 0) {
                        $listaLimpa | Sort-Object | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
                    } else {
                        Write-Host "  [AVISO] Nenhum pacote retornado. Verifique se o celular esta autorizado no ADB (Opcao [6])." -ForegroundColor Yellow
                    }
                }
            }

            Write-Host "`n  DIGITE UM PACOTE PARA REMOVER (ou 0 para cancelar):" -ForegroundColor Yellow
            Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [INSTRUCAO ANDROID - COMO REMOVER UM PACOTE]:" -ForegroundColor Cyan
            Write-Host "    1. Digite o nome exato do pacote (ex: com.exemplo.app) visto na" -ForegroundColor White
            Write-Host "       Opcao [1] ou na lista acima (sem o prefixo 'package:')." -ForegroundColor White
            Write-Host "    2. Com ADB conectado (USB ou Wi-Fi), o script executa 'adb uninstall'" -ForegroundColor White
            Write-Host "       e, se for app pre-instalado/bloatware, oferece remover apenas" -ForegroundColor White
            Write-Host "       para o seu usuario ('pm uninstall --user 0')." -ForegroundColor White
            Write-Host "    3. Se preferir remover MANUALMENTE no celular: Configuracoes >" -ForegroundColor Yellow
            Write-Host "       Aplicativos > Gerenciar apps > toque no app > Desinstalar." -ForegroundColor Yellow
            Write-Host "       (Se o botao estiver bloqueado, desative antes em Seguranca >" -ForegroundColor DarkGray
            Write-Host "       Apps administradores do dispositivo)." -ForegroundColor DarkGray
            Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray

            $pkgTarget = (Read-Host "Pacote Android para remover").Trim()
            $pkgTarget = $pkgTarget -replace '^package:', ''

            if ([string]::IsNullOrWhiteSpace($pkgTarget) -or $pkgTarget -eq "0") {
                Write-Host "  [CANCELADO] Nenhum pacote foi removido." -ForegroundColor DarkGray
                continue
            }

            $blockedCore = @('android','com.android.systemui','com.android.settings','com.android.phone','com.android.providers.settings','com.google.android.gms')
            if ($blockedCore -contains $pkgTarget.ToLower()) {
                Write-Host "  [BLOQUEADO POR SEGURANCA] '$pkgTarget' e um pacote critico do sistema Android e nao deve ser removido!" -ForegroundColor Red
                continue
            }

            if (-not ($adb -and $devId)) {
                Write-Host "  [AVISO] Celular Android nao esta conectado via ADB no momento." -ForegroundColor Yellow
                Write-Host "  Conecte pela Opcao [6] (USB ou Wi-Fi) para remover pelo PC, ou siga a instrucao manual acima." -ForegroundColor White
                continue
            }

            $confRem = Read-Host "Confirma REMOVER o pacote '$pkgTarget' do Android ($devId)? [S/N]"
            if ($confRem -match "^[sS]$") {
                Write-Host "  Executando: adb -s $devId uninstall $pkgTarget ..." -ForegroundColor Cyan
                $outUn = & $adb -s $devId uninstall $pkgTarget 2>&1
                $outStr = ($outUn -join " ")
                Write-Host "  Resultado: $outStr" -ForegroundColor White
                if ($outStr -match "Success") {
                    Write-Host "  [OK] Pacote '$pkgTarget' removido com sucesso do Android!" -ForegroundColor Green
                    Write-Host '  [V // CP2077]: "Alvo neutralizado, choom. Aparelho mais limpo."' -ForegroundColor Cyan
                } else {
                    Write-Host "  [AVISO] A desinstalacao padrao falhou (pode ser app de fabrica/bloatware ou nome incorreto)." -ForegroundColor Yellow
                    $tryU0 = Read-Host "Deseja tentar remover apenas para o usuario atual (pm uninstall -k --user 0 $pkgTarget)? [S/N]"
                    if ($tryU0 -match "^[sS]$") {
                        $outU0 = & $adb -s $devId shell pm uninstall -k --user 0 $pkgTarget 2>&1
                        $outU0Str = ($outU0 -join " ")
                        Write-Host "  Resultado (--user 0): $outU0Str" -ForegroundColor White
                        if ($outU0Str -match "Success") {
                            Write-Host "  [OK] Pacote '$pkgTarget' desativado/removido para o usuario atual!" -ForegroundColor Green
                        } else {
                            Write-Host "  [ERRO] Nao foi possivel remover '$pkgTarget'. Verifique se o nome esta exato ou remova manualmente no aparelho." -ForegroundColor Red
                        }
                    }
                }
            } else {
                Write-Host "  [CANCELADO] Operacao abortada pelo usuario." -ForegroundColor DarkGray
            }
        }
        elseif ($sub -eq "1") {
            Write-Host "`n--- [1] AUDITORIA DE APPS NOCIVOS E FONTES DESCONHECIDAS ---" -ForegroundColor Green
            Write-Host '  [RIVER WARD // NCPD - CP2077]: "Listando aplicativos instalados fora da imagem de fabrica e verificando origem."' -ForegroundColor Yellow
            if ($adb) {
                $thirdParty = @(Get-AndroidPackagesSafe -AdbPath $adb -DeviceId $devId -PmFlag "-3")
                $suspKeywords = @('spy','track','keylog','rat','trojan','hack','miner','coin','xmr','hide','stealth','ngrok','payload','apktool','spynote','ahmyth','cerberus','anubis','hydra')
                $flagged = @()
                foreach ($pkgName in $thirdParty) {
                    foreach ($kw in $suspKeywords) {
                        if ($pkgName.ToLower() -like "*$kw*") {
                            $flagged += $pkgName
                            break
                        }
                    }
                }
                Write-Host "  Total de apps de terceiros encontrados: $($thirdParty.Count)" -ForegroundColor Cyan
                if ($flagged.Count -gt 0) {
                    Write-Host "  [ALERTA] Pacotes com palavras-chave suspeitas detectados:" -ForegroundColor Red
                    $flagged | ForEach-Object { Write-Host "    -> $_" -ForegroundColor Red }
                } else {
                    Write-Host "  [OK] Nenhum pacote com assinatura de nome malicioso conhecido detectado." -ForegroundColor Green
                }
                $showAll = Read-Host "Deseja listar todos os $($thirdParty.Count) pacotes de terceiros instalados para revisar? [S/N]"
                if ($showAll -match "^[sS]$") {
                    $thirdParty | Sort-Object | ForEach-Object { Write-Host "    - $_" -ForegroundColor White }
                }
            } else {
                Write-Host "  [MODO GUIA - SEM ADB]: No Android, abra Configuracoes > Aplicativos > Ver todos os apps e procure apps sem icone ou com nome generico ('System Update', 'WiFi Service')." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "2") {
            Write-Host "`n--- [2] AUDITORIA DE MALWARE, RANSOMWARE, MINERADORES E BOTNETS ---" -ForegroundColor Red
            Write-Host '  [D // Snake Nation - Edgerunners 2]: "Mineradores fritam a CPU em segundo plano; botnets abrem conexoes ocultas."' -ForegroundColor Green
            if ($adb -and $devId) {
                Write-Host "  [A] Top processos consumindo CPU agora (sinal de minerador oculto):" -ForegroundColor Cyan
                & $adb -s $devId shell "top -n 1 -b 2>/dev/null | head -n 18"
                Write-Host "`n  [B] Conexoes de rede ativas (sinal de Botnet / C2):" -ForegroundColor Cyan
                & $adb -s $devId shell "ss -tupn 2>/dev/null || netstat -tun 2>/dev/null | head -n 25"
                Write-Host "`n  [C] Administradores do Dispositivo (Ransomware/Trojans travam a desinstalacao aqui):" -ForegroundColor Yellow
                & $adb -s $devId shell "dumpsys device_policy | grep -i -E 'Admin|ComponentInfo' | head -n 20"
            } else {
                Write-Host "  [MODO GUIA - SEM ADB]: Verifique aquecimento/bateria drenando rapido (minerador) e Configuracoes > Seguranca > Apps administradores do dispositivo." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "3") {
            Write-Host "`n--- [3] ARQUIVOS CRIPTOGRAFADOS MALICIOSOS, FOTOS FALSAS E PDFS SUSPEITOS ---" -ForegroundColor Yellow
            Write-Host '  [TALIA // Edgerunners 2]: "Cacando dupla extensao (foto.jpg.apk, boleto.pdf.exe) e extensoes de ransomware (.enc/.locked)."' -ForegroundColor Red
            if ($adb -and $devId) {
                Write-Host "  Varrendo /sdcard/Download, /sdcard/Documents, /sdcard/DCIM e /sdcard/Pictures..." -ForegroundColor Cyan
                $files = & $adb -s $devId shell "find /sdcard/Download /sdcard/Documents /sdcard/DCIM /sdcard/Pictures -maxdepth 3 -type f 2>/dev/null"
                $badFiles = @()
                foreach ($f in $files) {
                    $fn = $f.Trim()
                    if ($fn -match "\.(apk|exe|bat|sh|scr|vbs|js|jar|dex|so|enc|locked|crypt|crypted|locky|cerber)$" -or $fn -match "\.(pdf|jpg|jpeg|png|mp4|doc|docx)\.(apk|exe|scr|bat|sh|js|enc|locked)$") {
                        $badFiles += $fn
                    }
                }
                if ($badFiles.Count -eq 0) {
                    Write-Host "  [OK] Nenhum arquivo disfarcado, APK solto ou extensao de criptografia suspeita encontrado nas pastas principais." -ForegroundColor Green
                } else {
                    Write-Host "  [ALERTA] Arquivos suspeitos encontrados (NADA foi apagado automaticamente):" -ForegroundColor Red
                    $badFiles | ForEach-Object { Write-Host "    -> $_" -ForegroundColor Yellow }
                    Write-Host '  [LUCY // Edgerunners 1]: "Revise cada caminho acima no gerenciador de arquivos do celular antes de apagar."' -ForegroundColor Cyan
                }
            } else {
                Write-Host "  [MODO GUIA - SEM ADB]: Abra o app 'Meus Arquivos / Files', va em Downloads e procure arquivos terminando em .apk ou com nome duplo (ex: comprovante.pdf.apk)." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "4") {
            Write-Host "`n--- [4] APPS COM PERMISSOES INDEVIDAS (ACESSIBILIDADE, OVERLAY, SMS, CAMERA) ---" -ForegroundColor Magenta
            Write-Host '  [SOLOMON REED // FIA - CP2077]: "Trojans bancarios abusam de Acessibilidade e Sobreposicao de Tela para ler senhas."' -ForegroundColor White
            if ($adb -and $devId) {
                Write-Host "  [A] Servicos de Acessibilidade ativos (CRITICO - confira se reconhece todos):" -ForegroundColor Red
                & $adb -s $devId shell settings get secure enabled_accessibility_services
                Write-Host "`n  [B] Apps com permissao de SOBREPOR OUTROS APPS (SYSTEM_ALERT_WINDOW):" -ForegroundColor Yellow
                & $adb -s $devId shell "cmd appops query-op SYSTEM_ALERT_WINDOW allow 2>/dev/null"
                Write-Host "`n  [C] Apps externos com permissao de INSTALAR OUTROS APPS (REQUEST_INSTALL_PACKAGES):" -ForegroundColor Yellow
                & $adb -s $devId shell "cmd appops query-op REQUEST_INSTALL_PACKAGES allow 2>/dev/null"
                Write-Host "`n  [D] Apps com permissao de LER SMS (READ_SMS):" -ForegroundColor Cyan
                & $adb -s $devId shell "cmd appops query-op READ_SMS allow 2>/dev/null"
            } else {
                Write-Host "  [MODO GUIA - SEM ADB]: Abra Configuracoes > Privacidade > Gerenciador de permissoes e revise Acessibilidade, SMS, Camera e Instalar apps desconhecidos." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "5") {
            Write-Host "`n--- [5] CAMADAS EXTRAS: CERTIFICADOS RAIZ, VPN/DNS, PORTAS ADB E PLAY PROTECT ---" -ForegroundColor Cyan
            Write-Host '  [CAPRI // Edgerunners 2]: "Verificando interceptacao HTTPS (certificados extras), VPN oculta e status do Play Protect."' -ForegroundColor Cyan
            if ($adb -and $devId) {
                Write-Host "  [A] Certificados de usuario instalados (sinal de proxy/interceptacao MITM):" -ForegroundColor Yellow
                & $adb -s $devId shell "ls -la /data/misc/user/0/cacerts-added 2>/dev/null || echo 'Nenhum certificado de usuario extra'"
                Write-Host "`n  [B] Configuracao de DNS Privado e Proxy Global:" -ForegroundColor Cyan
                & $adb -s $devId shell "settings get global private_dns_mode; settings get global private_dns_specifier; settings get global http_proxy"
                Write-Host "`n  [C] Status do Google Play Protect:" -ForegroundColor Green
                & $adb -s $devId shell "settings get global package_verifier_user_consent"
                Write-Host '  [JOHNNY SILVERHAND // CP2077]: "Lembrete: quando terminar, desligue a Depuracao USB/Sem Fio nas Opcoes do Desenvolvedor!"' -ForegroundColor Red
            } else {
                Write-Host "  [MODO GUIA]: Revise Configuracoes > Rede > VPN e DNS Privado, e rode uma verificacao manual no Google Play Protect." -ForegroundColor Yellow
            }
        }
    }
}

function Invoke-MobileIphone {
    Register-MobileExitCleanup
    Clear-Host
    Show-BootBanner "[18-B] SEGURANCA MOBILE // IPHONE (LIBIMOBILEDEVICE PORTATIL + IOS)"
    Write-Host '  [HANAKO ARASAKA // Cyberpunk 2077]: "O iOS isola aplicativos por sandbox e nao usa ADB."' -ForegroundColor White
    Write-Host '  [SONGBIRD // CP2077]: "Usando a pasta portatil LIBIMOBILEDEVICE IPHONE + auditoria de rede e blindagem do iOS."' -ForegroundColor Magenta

    $ipTools = Resolve-IphoneTools
    if (-not $ipTools -and (-not $script:SkipIphonePrompt)) {
        Write-Host "`n  [INFO] Ferramenta portatil 'libimobiledevice' ainda nao baixada na pasta 'LIBIMOBILEDEVICE IPHONE'." -ForegroundColor Yellow
        $instIp = Read-Host "Deseja baixar o libimobiledevice portatil na pasta 'LIBIMOBILEDEVICE IPHONE' agora? [S/N]"
        if ($instIp -match "^[sS]$") {
            $ipTools = Install-PortableIphoneTools
        } else {
            $script:SkipIphonePrompt = $true
        }
    }

    while ($true) {
        $ipStatus = if ($ipTools) { "LIBIMOBILEDEVICE PRONTO ($ipTools)" } else { "MODO GUIA / REDE" }
        Write-Host "`n========================================================================" -ForegroundColor Magenta
        Write-Host "  SUBMENU IPHONE (IOS) // STATUS: $ipStatus" -ForegroundColor Cyan
        Write-Host "========================================================================" -ForegroundColor Magenta
        Write-Host "  [1] Verificar APPS NOCIVOS e Perfis MDM / Gerenciamento Ocultos no iOS" -ForegroundColor Green
        Write-Host "  [2] Verificar VIRUS, MALWARE, SPYWARE, MINERADORES E BOTNETS (Rede/DNS/Lockdown)" -ForegroundColor Red
        Write-Host "  [3] Verificar ARQUIVOS CRIPTOGRAFADOS MALICIOSOS (PDFs falsos / iCloud / Safari)" -ForegroundColor Yellow
        Write-Host "  [4] Verificar APPS COM PERMISSOES INDEVIDAS (Relatorio de Privacidade de Apps)" -ForegroundColor Magenta
        Write-Host "  [5] CAMADAS EXTRAS: Auditar DNS/Gateway da Rede Wi-Fi atual + Lockdown Mode" -ForegroundColor Cyan
        Write-Host "  [6] Detectar iPhone via USB (UDID, Versao iOS e Diagnostico via libimobiledevice)" -ForegroundColor White
        Write-Host "  [7] Baixar / Atualizar Ferramenta Portatil em 'LIBIMOBILEDEVICE IPHONE'" -ForegroundColor DarkCyan
        Write-Host "  [8] REMOVER / DESINSTALAR PACOTE (APP) DO IPHONE (com instrucoes)" -ForegroundColor Red
        Write-Host "  [9] MOSTRAR PACOTES NATIVOS / SISTEMA DO IPHONE (com.apple.*)" -ForegroundColor Yellow
        Write-Host "  [10] Como conectar o iPhone (Tela 'Confiar neste Computador' e Modo Desenvolvedor)" -ForegroundColor Cyan
        Write-Host "  [11] GUIA TATICO: LIMPAR CACHE DE APPS, SAFARI E FLUSH DNS NO IPHONE (IOS)" -ForegroundColor Green
        Write-Host "  [0] Sair e encerrar processos Android/iPhone no Windows" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Magenta
        $sub = Read-Host "Escolha uma opcao [0-11]"

        if ($sub -eq "0") { Stop-MobileBackgroundProcesses; break }
        elseif ($sub -eq "10") { Show-MobileDebugGuide }
        elseif ($sub -eq "11") { Show-IphoneCacheGuide }
        elseif ($sub -eq "7") {
            $ipTools = Install-PortableIphoneTools
        }
        elseif ($sub -eq "9") {
            Write-Host "`n========================================================================" -ForegroundColor Yellow
            Write-Host "  [9] PACOTES NATIVOS / DO SISTEMA NO IPHONE (IOS - com.apple.*)" -ForegroundColor Yellow
            Write-Host "========================================================================" -ForegroundColor Yellow
            Write-Host '  [HANAKO ARASAKA // CP2077]: "Consultando os Bundle IDs nativos pre-instalados no sistema iOS."' -ForegroundColor White
            if (-not $ipTools) { $ipTools = Resolve-IphoneTools }
            $instExe9 = $null
            if ($ipTools) {
                $cand9 = Join-Path $ipTools "ideviceinstaller.exe"
                if (Test-Path $cand9) { $instExe9 = $cand9 }
            }
            if (-not $instExe9) {
                $cmd9 = Get-Command "ideviceinstaller.exe" -ErrorAction SilentlyContinue
                if ($cmd9 -and $cmd9.Source) { $instExe9 = $cmd9.Source }
            }
            if ($instExe9) {
                $ipFilt9 = (Read-Host "`nFiltrar por palavra-chave? (ex: apple, mail, safari | ENTER = listar todos)").Trim()
                Write-Host "  Executando: ideviceinstaller -l -o list_system ..." -ForegroundColor Cyan
                $sysIp = & $instExe9 -l -o list_system 2>&1
                $countIp = 0
                foreach ($l in $sysIp) {
                    if (-not $ipFilt9 -or $l.ToString().ToLower().Contains($ipFilt9.ToLower())) {
                        Write-Host "    $l" -ForegroundColor White
                        $countIp++
                    }
                }
                if ($countIp -eq 0) {
                    Write-Host "  [AVISO] Nenhum pacote retornado. Verifique se o iPhone esta desbloqueado no cabo USB com 'Confiar' aceito." -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [MODO GUIA - SEM ideviceinstaller.exe]: Baixe a pasta portatil na Opcao [7] para listar via cabo USB." -ForegroundColor Yellow
                Write-Host "  Exemplos de pacotes nativos padrao do iOS (Bundle IDs):" -ForegroundColor Cyan
                Write-Host "    - com.apple.mobilesafari  (Safari)" -ForegroundColor White
                Write-Host "    - com.apple.mobilemail    (Mail)" -ForegroundColor White
                Write-Host "    - com.apple.MobileSMS     (Mensagens)" -ForegroundColor White
                Write-Host "    - com.apple.camera        (Camera)" -ForegroundColor White
                Write-Host "    - com.apple.Preferences   (Ajustes)" -ForegroundColor White
                Write-Host "    - com.apple.AppStore      (App Store)" -ForegroundColor White
                Write-Host "    - com.apple.DocumentsApp  (Arquivos)" -ForegroundColor White
                Write-Host "  No iPhone: Ajustes > Geral > Armazenamento do iPhone mostra os apps nativos e de terceiros instalados." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "8") {
            Write-Host "`n========================================================================" -ForegroundColor Red
            Write-Host "  [8] REMOVER / DESINSTALAR PACOTE (BUNDLE ID) NO IPHONE (IOS)" -ForegroundColor Red
            Write-Host "========================================================================" -ForegroundColor Red
            Write-Host '  [TALIA // Edgerunners 2]: "Vamos localizar o Bundle ID do app suspeito no iPhone e remover com seguranca."' -ForegroundColor Red

            if (-not $ipTools) { $ipTools = Resolve-IphoneTools }
            $instExe = $null
            if ($ipTools) {
                $candInst = Join-Path $ipTools "ideviceinstaller.exe"
                if (Test-Path $candInst) { $instExe = $candInst }
            }
            if (-not $instExe) {
                $cmdInst = Get-Command "ideviceinstaller.exe" -ErrorAction SilentlyContinue
                if ($cmdInst -and $cmdInst.Source) { $instExe = $cmdInst.Source }
            }

            if ($instExe) {
                Write-Host "`n  Deseja listar os Bundle IDs no iPhone conectado via USB antes de digitar?" -ForegroundColor Cyan
                Write-Host "    [1] Apps de Usuario (instalados da App Store / externos)" -ForegroundColor Green
                Write-Host "    [2] Apps NATIVOS / do Sistema (com.apple.*)" -ForegroundColor Yellow
                Write-Host "    [3] Todos os apps (Usuario + Nativos)" -ForegroundColor White
                Write-Host "    [0] Pular listagem" -ForegroundColor DarkGray
                $verIpApps = (Read-Host "Escolha [0-3]").Trim()
                if ($verIpApps -in @("1","2","3")) {
                    $ipOpt = if ($verIpApps -eq "1") { "list_user" } elseif ($verIpApps -eq "2") { "list_system" } else { "list_all" }
                    $ipFiltro = (Read-Host "Filtrar por palavra-chave? (ex: apple, safari, mail | ENTER = mostrar todos)").Trim()
                    Write-Host "  Listando Bundle IDs no iPhone (ideviceinstaller -l -o $ipOpt)..." -ForegroundColor Cyan
                    $ipRaw = & $instExe -l -o $ipOpt 2>&1
                    foreach ($line in $ipRaw) {
                        if (-not $ipFiltro -or $line.ToString().ToLower().Contains($ipFiltro.ToLower())) {
                            Write-Host "    $line" -ForegroundColor White
                        }
                    }
                }
            }

            Write-Host "`n  DIGITE UM PACOTE PARA REMOVER (Bundle ID do iPhone | ou 0 para cancelar):" -ForegroundColor Yellow
            Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  [INSTRUCAO IPHONE (iOS) - COMO REMOVER UM PACOTE]:" -ForegroundColor Cyan
            Write-Host "    1. No iPhone, cada app e identificado por um Bundle ID" -ForegroundColor White
            Write-Host "       (ex: com.whatsapp.WhatsApp ou com.empresa.app)." -ForegroundColor White
            Write-Host "    2. Via Cabo USB (com 'ideviceinstaller.exe' na pasta" -ForegroundColor White
            Write-Host "       'LIBIMOBILEDEVICE IPHONE' + iPhone desbloqueado e 'Confiar'" -ForegroundColor White
            Write-Host "       aceito), o script executa 'ideviceinstaller -U <BundleID>'." -ForegroundColor White
            Write-Host "    3. Se preferir remover MANUALMENTE no iPhone:" -ForegroundColor Yellow
            Write-Host "       a) Pressione e segure o icone do app > 'Remover App' > 'Apagar App'." -ForegroundColor Yellow
            Write-Host "       b) Se o app nao deixar apagar (instalado por perfil oculto/MDM)," -ForegroundColor Yellow
            Write-Host "          va em Ajustes > Geral > VPN e Gerenciamento de Dispositivo," -ForegroundColor Yellow
            Write-Host "          remova o perfil suspeito e apague o app em seguida." -ForegroundColor Yellow
            Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray

            $bundleTarget = (Read-Host "Pacote (Bundle ID) iPhone para remover").Trim()
            if ([string]::IsNullOrWhiteSpace($bundleTarget) -or $bundleTarget -eq "0") {
                Write-Host "  [CANCELADO] Nenhum pacote foi removido." -ForegroundColor DarkGray
                continue
            }

            if ($bundleTarget.ToLower().StartsWith("com.apple.")) {
                Write-Host "  [ALERTA] '$bundleTarget' parece ser um app nativo da Apple. Recomenda-se remover apenas manualmente no iOS se desejar." -ForegroundColor Yellow
            }

            if (-not $instExe) {
                Write-Host "  [AVISO] 'ideviceinstaller.exe' nao encontrado na pasta 'LIBIMOBILEDEVICE IPHONE'." -ForegroundColor Yellow
                Write-Host "  Use a Opcao [7] para baixar/atualizar a pasta portatil ou siga a instrucao manual acima no proprio iPhone." -ForegroundColor White
                continue
            }

            $confIp = Read-Host "Confirma REMOVER o pacote '$bundleTarget' do iPhone via USB? [S/N]"
            if ($confIp -match "^[sS]$") {
                Write-Host "  Executando: ideviceinstaller -U $bundleTarget ..." -ForegroundColor Cyan
                $ipOut = & $instExe -U $bundleTarget 2>&1
                foreach ($l in $ipOut) { Write-Host "  $l" -ForegroundColor White }
                if (($ipOut -join " ") -match "Complete|Success") {
                    Write-Host "  [OK] Pacote '$bundleTarget' removido com sucesso do iPhone!" -ForegroundColor Green
                    Write-Host '  [HANAKO ARASAKA // CP2077]: "Remocao concluida sem deixar residuos."' -ForegroundColor White
                } else {
                    Write-Host "  [AVISO] Verifique se o iPhone esta desbloqueado no cabo USB com driver Apple/iTunes ativo e se o Bundle ID esta correto." -ForegroundColor Yellow
                }
            } else {
                Write-Host "  [CANCELADO] Operacao abortada pelo usuario." -ForegroundColor DarkGray
            }
        }
        elseif ($sub -eq "6") {
            Write-Host "`n--- [6] DETECCAO USB DO IPHONE (LIBIMOBILEDEVICE PORTATIL) ---" -ForegroundColor Cyan
            if (-not $ipTools) { $ipTools = Resolve-IphoneTools }
            if ($ipTools) {
                $idExe = Join-Path $ipTools "idevice_id.exe"
                $infoExe = Join-Path $ipTools "ideviceinfo.exe"
                $udids = & $idExe -l 2>&1
                if ($udids -and ($udids -notmatch "ERROR")) {
                    Write-Host "  [OK] iPhone detectado via USB: $($udids -join ', ')" -ForegroundColor Green
                    if (Test-Path $infoExe) {
                        & $infoExe | Select-String -Pattern "DeviceName|ProductType|ProductVersion|BuildVersion|HardwareModel"
                    }
                } else {
                    Write-Host "  [AVISO] Nenhum iPhone detectado via USB. Conecte o cabo, desbloqueie a tela e toque em 'Confiar neste computador'." -ForegroundColor Yellow
                    Write-Host "  (No Windows, o servico Apple Mobile Device / iTunes precisa estar instalado para comunicacao USB)." -ForegroundColor DarkGray
                }
            } else {
                Write-Host "  [AVISO] Ferramenta nao encontrada em 'LIBIMOBILEDEVICE IPHONE'. Use a opcao [7] para baixar." -ForegroundColor Yellow
            }
        }
        elseif ($sub -eq "1") {
            Write-Host "`n--- [1] IPHONE: APPS NOCIVOS E PERFIS MDM OCULTOS ---" -ForegroundColor Green
            Write-Host '  [GORO TAKEMURA // CP2077]: "No iPhone, invasores usam Perfis de Configuracao/MDM para instalar apps fora da App Store."' -ForegroundColor White
            Write-Host "  1. Abra Ajustes > Geral > VPN e Gerenciamento de Dispositivo." -ForegroundColor Yellow
            Write-Host "  2. Se houver qualquer 'Perfil de Configuracao' ou 'Gerenciamento Remoto' que voce nao reconhece (empresa/escola), REMOVA." -ForegroundColor Red
            Write-Host "  3. Abra a Biblioteca de Apps (ultima tela a direita) e revise apps sem icone ou desconhecidos." -ForegroundColor White
        }
        elseif ($sub -eq "2") {
            Write-Host "`n--- [2] IPHONE: SPYWARE, MALWARE, MINERADORES E BOTNETS ---" -ForegroundColor Red
            Write-Host '  [WEAK "KING" KINGSLEY // Edgerunners 2]: "Verificando sinais de trafego suspeito na rede local e guia do iOS."' -ForegroundColor Yellow
            Write-Host "  1. Abra Ajustes > Privacidade e Seguranca > Verificacao de Seguranca (Safety Check) para revogar acessos compartilhados." -ForegroundColor Cyan
            Write-Host "  2. Em Ajustes > Bateria, verifique se algum app desconhecido consome bateria em 'Atividade em Segundo Plano'." -ForegroundColor Yellow
            Write-Host "  3. Atualize o iOS em Ajustes > Geral > Atualizacao de Software (corrige falhas zero-day)." -ForegroundColor Green
        }
        elseif ($sub -eq "3") {
            Write-Host "`n--- [3] IPHONE: PDFS FALSOS, LINKS DE PHISHING E ARQUIVOS SUSPEITOS ---" -ForegroundColor Yellow
            Write-Host '  [JUDY ALVAREZ // CP2077]: "PDFs maliciosos e perfis .mobileconfig disfarcados chegam pelo Safari, WhatsApp e Mail."' -ForegroundColor Cyan
            Write-Host "  1. Abra o app Arquivos > Explorar > Downloads (no iPhone e no iCloud Drive)." -ForegroundColor White
            Write-Host "  2. Procure arquivos com extensao '.mobileconfig', '.ipa', '.zip' estranhos ou PDFs de remetentes desconhecidos." -ForegroundColor Yellow
            Write-Host "  3. Em Ajustes > Safari, ative 'Aviso de Site Fraudulento' e 'Bloquear Pop-ups'." -ForegroundColor Green
        }
        elseif ($sub -eq "4") {
            Write-Host "`n--- [4] IPHONE: APPS PEDINDO PERMISSOES INDEVIDAS ---" -ForegroundColor Magenta
            Write-Host '  [VIKTOR VEKTOR // CP2077]: "Use o Relatorio de Privacidade nativo do iOS para pegar qualquer app bisbilhoteiro."' -ForegroundColor Green
            Write-Host "  1. Abra Ajustes > Privacidade e Seguranca > Relatorio de Privacidade de Apps (ative se estiver desligado)." -ForegroundColor Cyan
            Write-Host "  2. Veja quais apps acessaram Camera, Microfone, Localizacao e Contatos recentemente." -ForegroundColor White
            Write-Host "  3. Em Localizacao, mude apps comuns de 'Sempre' para 'Durante o Uso do App' e desative 'Localizacao Precisa' onde nao precisa." -ForegroundColor Yellow
        }
        elseif ($sub -eq "5") {
            Write-Host "`n--- [5] CAMADAS EXTRAS: AUDITORIA DE DNS DA REDE WI-FI + MODO DE ISOLAMENTO ---" -ForegroundColor Cyan
            Write-Host '  [ALT CUNNINGHAM // CP2077]: "Auditando os servidores DNS ativos nesta rede (que afetam tanto o PC quanto seu celular no Wi-Fi)..."' -ForegroundColor Red
            Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses } | Select-Object InterfaceAlias, ServerAddresses | Format-Table -AutoSize
            Write-Host "  -> No iPhone: Ajustes > Wi-Fi > toque no (i) da sua rede > Configurar DNS: prefira Automatico ou DNS confiavel (1.1.1.1 / 9.9.9.9)." -ForegroundColor Yellow
            Write-Host "  -> Protecao maxima contra spyware: Ajustes > Privacidade e Seguranca > Modo de Isolamento (Lockdown Mode)." -ForegroundColor Green
        }
    }
}

function Invoke-Op18 {
    while ($true) {
        Clear-Host
        Show-BootBanner "[18] SEGURANCA DE CELULARES ANDROID E IPHONE (MODO PORTATIL PEN DRIVE)"
        Write-Host '  [DAVID MARTINEZ // Edgerunners 1]: "Hora de blindar o comunicador de bolso direto do pen drive, sem instalar lixo no PC."' -ForegroundColor Yellow
        Write-Host '  [LUCY // Edgerunners 1]: "Escolha o sistema do aparelho para abrir o protocolo de auditoria."' -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  [1] ANDROID - Auditoria via ADB Portatil (pasta 'ADB ANDROID' - USB / Wi-Fi)" -ForegroundColor Green
        Write-Host "  [2] IPHONE (iOS) - Auditoria via 'LIBIMOBILEDEVICE IPHONE' + Rede e Blindagem" -ForegroundColor Magenta
        Write-Host "  [3] COMO ATIVAR DEPURACAO / MODO DESENVOLVEDOR (Guia Interativo por Marca/Modelo)" -ForegroundColor Cyan
        Write-Host "  [4] PAREAMENTO SEM FIO VIA QR CODE (Android 11+)" -ForegroundColor Yellow
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Yellow
        $plat = Read-Host "Escolha a opcao [0-4]"
        if ($plat -eq "1") { Invoke-MobileAndroid }
        elseif ($plat -eq "2") { Invoke-MobileIphone }
        elseif ($plat -eq "3") { Show-MobileDebugGuide -AdbPath (Resolve-AdbExe) }
        elseif ($plat -eq "4") { Show-AdbQrCodePairing -AdbPath (Resolve-AdbExe); Pause-Cyber }
        elseif ($plat -eq "0") { Stop-MobileBackgroundProcesses; break }
        else { Write-Host '  [SKIPPY // CP2077]: "Opcao invalida. Digite de 0 a 4."' -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}

function Test-BitLockerSupport {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $caption = if ($os) { $os.Caption } else { "Windows" }
    $hasCmd = [bool](Get-Command "Enable-BitLocker" -ErrorAction SilentlyContinue)
    $hasBde = [bool](Get-Command "manage-bde.exe" -ErrorAction SilentlyContinue)
    $isHome = ($caption -match "Home")
    return @{
        Caption   = $caption
        IsHome    = $isHome
        Available = ($hasCmd -and $hasBde -and (-not $isHome))
    }
}

function Resolve-VeraCryptExe {
    $root = Get-CyberDeckRoot
    $candidates = @(
        (Join-Path $root "VERACRYPT PORTATIL\VeraCrypt.exe"),
        (Join-Path $root "VERACRYPT PORTATIL\VeraCrypt-x64.exe"),
        "$env:ProgramFiles\VeraCrypt\VeraCrypt.exe",
        "${env:ProgramFiles(x86)}\VeraCrypt\VeraCrypt.exe"
    )
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }
    $cmd = Get-Command "VeraCrypt.exe" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) { return $cmd.Source }
    return $null
}

function Show-CryptoDrives {
    Write-Host "`n  UNIDADES DETECTADAS NESTE COMPUTADOR:" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
    $vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=2 OR DriveType=3" -ErrorAction SilentlyContinue | Sort-Object DeviceID
    foreach ($v in $vols) {
        $tipo = if ($v.DriveType -eq 2) { "PEN DRIVE / REMOVIVEL" } else { "DISCO INTERNO / FIXO " }
        $tamGB = if ($v.Size) { [math]::Round($v.Size / 1GB, 1) } else { 0 }
        $livGB = if ($v.FreeSpace) { [math]::Round($v.FreeSpace / 1GB, 1) } else { 0 }
        $rotulo = if ($v.VolumeName) { $v.VolumeName } else { "(Sem nome)" }
        $cor = if ($v.DriveType -eq 2) { "Yellow" } else { "White" }
        Write-Host ("  [{0}]  {1}  |  Nome: {2,-18} | {3,6} GB total ({4,6} GB livre)" -f $v.DeviceID, $tipo, $rotulo, $tamGB, $livGB) -ForegroundColor $cor
    }
    Write-Host "  ----------------------------------------------------------------------" -ForegroundColor DarkGray
}

function Save-BitLockerRecoveryBackup {
    param([string]$DriveLetter)
    $keyDir = Get-DesktopDatedDadosDir -SubFolder "CHAVES_RECUPERACAO_BITLOCKER"
    $cleanLetter = $DriveLetter.TrimEnd(':')
    $stamp = Get-Date -Format "dd-MM-yyyy_HHmm"
    $outFile = Join-Path $keyDir "CHAVE_BITLOCKER_Unidade_${cleanLetter}_${stamp}.txt"
    $raw = manage-bde.exe -protectors -get "${cleanLetter}:" 2>&1
    $header = @(
        "========================================================================",
        "  CYBERDECK OS // BACKUP DE CHAVE DE RECUPERACAO BITLOCKER",
        "========================================================================",
        "Unidade:          ${cleanLetter}:",
        "Data/Hora:        $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')",
        "Computador:       $env:COMPUTERNAME",
        "Usuario:          $env:USERNAME",
        "",
        "!!! GUARDE ESTE ARQUIVO EM LOCAL SEGURO (FORA DA UNIDADE CRIPTOGRAFADA) !!!",
        "Se voce esquecer a senha ou trocar de placa-mae, SOMENTE a senha de 48",
        "digitos abaixo consegue recuperar seus arquivos.",
        "========================================================================",
        ""
    )
    Set-Content -Path $outFile -Value ($header + $raw) -Encoding UTF8
    $keyProj = Sync-FileToProjectDados -SourceFile $outFile -SubFolder "CHAVES_RECUPERACAO_BITLOCKER"
    Write-Host "  [OK] Chave de Recuperacao salva na Area de Trabalho: $outFile" -ForegroundColor Green
    if ($keyProj) { Write-Host "  [OK] Copia portatil salva no Projeto (Pen Drive / SSD): $keyProj" -ForegroundColor Cyan }
    Start-Process explorer.exe -ArgumentList "`"$keyDir`""
}

function Invoke-Op19 {
    while ($true) {
        Clear-Host
        Show-BootBanner "[19] CRIPTOGRAFIA DE PEN DRIVES E UNIDADES DE DISCO (BLACKWALL VAULT)"
        $bl = Test-BitLockerSupport
        $vcExe = Resolve-VeraCryptExe

        Write-Host '  [ALT CUNNINGHAM // CP2077]: "Criptografia de disco transforma seus dados em ruido ilegivel sem a chave."' -ForegroundColor Red
        Write-Host '  [SONGBIRD // CP2077]: "Regra de ouro: NUNCA criptografe sem guardar a senha e a Chave de Recuperacao fora do disco!"' -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  Sistema detectado: $($bl.Caption)" -ForegroundColor Cyan
        if ($bl.Available) {
            Write-Host "  Motor BitLocker:   [DISPONIVEL] (Windows Pro/Enterprise/Education)" -ForegroundColor Green
        } else {
            Write-Host "  Motor BitLocker:   [LIMITADO/INDISPONIVEL] (Windows Home nao cria BitLocker completo -> use VeraCrypt [6])" -ForegroundColor Yellow
        }
        if ($vcExe) {
            Write-Host "  Motor VeraCrypt:   [PRONTO] ($vcExe)" -ForegroundColor Green
        } else {
            Write-Host "  Motor VeraCrypt:   [NAO DETECTADO] (Disponivel na opcao [6] - compativel com Windows Home e Linux)" -ForegroundColor DarkGray
        }

        Show-CryptoDrives

        Write-Host "`n========================================================================" -ForegroundColor Magenta
        Write-Host "  ESCOLHA UMA OPERACAO DE CRIPTOGRAFIA:" -ForegroundColor White
        Write-Host "  [1] Ver Status de Criptografia de Todas as Unidades (manage-bde -status)" -ForegroundColor Cyan
        Write-Host "  [2] Criptografar PEN DRIVE / HD EXTERNO com Senha (BitLocker To Go)" -ForegroundColor Yellow
        Write-Host "  [3] Criptografar UNIDADE DE DISCO DO PC (C:, D:, E: via BitLocker)" -ForegroundColor Red
        Write-Host "  [4] Extrair / Salvar Chave de Recuperacao (.txt) de unidade criptografada" -ForegroundColor Green
        Write-Host "  [5] Desbloquear (Unlock) ou Descriptografar (Remover BitLocker) unidade" -ForegroundColor Magenta
        Write-Host "  [6] VeraCrypt (Alternativa Open-Source: Windows Home, Pen Drives e Linux)" -ForegroundColor DarkCyan
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Magenta
        $opC = Read-Host "Opcao [0-6]"

        if ($opC -eq "0") { break }

        elseif ($opC -eq "1") {
            Write-Host "`n--- [1] STATUS ATUAL DE CRIPTOGRAFIA (BITLOCKER) ---" -ForegroundColor Cyan
            try { manage-bde.exe -status } catch { Write-Host "  [AVISO] manage-bde nao disponivel nesta edicao do Windows." -ForegroundColor Yellow }
            Pause-Cyber
        }

        elseif ($opC -eq "2") {
            Write-Host "`n--- [2] CRIPTOGRAFAR PEN DRIVE / HD EXTERNO (BITLOCKER TO GO) ---" -ForegroundColor Yellow
            if (-not $bl.Available) {
                Write-Host '  [VIKTOR VEKTOR // CP2077]: "Esta edicao do Windows (Home) bloqueia criacao de BitLocker To Go."' -ForegroundColor Yellow
                Write-Host '  [CAPRI // Edgerunners 2]: "Use a opcao [6] VeraCrypt para criptografar pen drives em qualquer Windows e ate abrir no Linux!"' -ForegroundColor Cyan
                Pause-Cyber
                continue
            }
            $drv = (Read-Host "Digite APENAS a letra do Pen Drive / HD Externo (ex: E)").Trim().TrimEnd(':').ToUpper()
            if (-not ($drv -match "^[A-Z]$") -or $drv -eq "C") {
                Write-Host "  [CANCELADO] Letra invalida ou unidade C: selecionada (use a opcao [3] para discos do sistema)." -ForegroundColor Red
                Pause-Cyber
                continue
            }
            $volCheck = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${drv}:'" -ErrorAction SilentlyContinue
            if (-not $volCheck) {
                Write-Host "  [ERRO] Unidade ${drv}: nao encontrada." -ForegroundColor Red
                Pause-Cyber
                continue
            }
            Write-Host "`n  [ALERTA] Voce vai criptografar a unidade ${drv}: ($($volCheck.VolumeName))." -ForegroundColor Red
            Write-Host '  [JOHNNY SILVERHAND // CP2077]: "Pensa duas vezes: se perder a senha e a chave de recuperacao, ja era tudo la dentro."' -ForegroundColor Red
            $conf = Read-Host "Tem certeza que deseja criptografar ${drv}:? Digite SIM para confirmar"
            if ($conf -ne "SIM") {
                Write-Host "  [CANCELADO] Operacao abortada pelo usuario." -ForegroundColor DarkGray
                Pause-Cyber
                continue
            }
            $modoEsp = Read-Host "Criptografar [1] Apenas espaco usado (mais rapido) ou [2] Disco inteiro (mais seguro)? [1/2]"
            $pwd1 = Read-Host "Digite a SENHA forte para o Pen Drive ${drv}:" -AsSecureString
            $pwd2 = Read-Host "Confirme a SENHA" -AsSecureString
            $b1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd1))
            $b2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd2))
            if ($b1 -ne $b2 -or [string]::IsNullOrWhiteSpace($b1)) {
                Write-Host "  [ERRO] As senhas nao conferem ou estao vazias. Operacao cancelada." -ForegroundColor Red
                Pause-Cyber
                continue
            }
            try {
                Write-Host "  Ativando BitLocker To Go em ${drv}: (AES-256)..." -ForegroundColor Cyan
                if ($modoEsp -eq "2") {
                    Enable-BitLocker -MountPoint "${drv}:" -EncryptionMethod Aes256 -PasswordProtector -Password $pwd1 -ErrorAction Stop | Out-Null
                } else {
                    Enable-BitLocker -MountPoint "${drv}:" -EncryptionMethod Aes256 -UsedSpaceOnly -PasswordProtector -Password $pwd1 -ErrorAction Stop | Out-Null
                }
                Add-BitLockerKeyProtector -MountPoint "${drv}:" -RecoveryPasswordProtector -ErrorAction SilentlyContinue | Out-Null
                Save-BitLockerRecoveryBackup -DriveLetter $drv
                Write-Host "  [OK] Criptografia iniciada em ${drv}:! Nao remova o pen drive ate atingir 100% (confira na opcao [1])." -ForegroundColor Green
            } catch {
                Write-Host "  [ERRO] Falha ao ativar BitLocker em ${drv}:: $($_.Exception.Message)" -ForegroundColor Red
            }
            Pause-Cyber
        }

        elseif ($opC -eq "3") {
            Write-Host "`n--- [3] CRIPTOGRAFAR UNIDADE DE DISCO DO PC (BITLOCKER) ---" -ForegroundColor Red
            if (-not $bl.Available) {
                Write-Host '  [VIKTOR VEKTOR // CP2077]: "O BitLocker completo exige Windows Pro, Enterprise ou Education."' -ForegroundColor Yellow
                Write-Host '  [CAPRI // Edgerunners 2]: "No Windows Home, voce pode usar a opcao [6] VeraCrypt para cofres e particoes."' -ForegroundColor Cyan
                Pause-Cyber
                continue
            }
            $drv = (Read-Host "Digite a letra da unidade do PC para criptografar (ex: C, D, E)").Trim().TrimEnd(':').ToUpper()
            if (-not ($drv -match "^[A-Z]$")) {
                Write-Host "  [CANCELADO] Letra invalida." -ForegroundColor Red
                Pause-Cyber
                continue
            }
            $volCheck = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='${drv}:'" -ErrorAction SilentlyContinue
            if (-not $volCheck) {
                Write-Host "  [ERRO] Unidade ${drv}: nao encontrada." -ForegroundColor Red
                Pause-Cyber
                continue
            }
            Write-Host "`n  [AVISO CRITICO] Unidade selecionada: ${drv}: ($($volCheck.VolumeName))." -ForegroundColor Red
            Write-Host '  [SOLOMON REED // CP2077]: "A Chave de Recuperacao de 48 digitos sera salva na Area de Trabalho. Copie-a para um pen drive ou nuvem!"' -ForegroundColor Yellow
            $conf = Read-Host "Confirma criptografar a unidade ${drv}:? Digite SIM para continuar"
            if ($conf -ne "SIM") {
                Write-Host "  [CANCELADO] Operacao abortada." -ForegroundColor DarkGray
                Pause-Cyber
                continue
            }
            $modoEsp = Read-Host "Criptografar [1] Apenas espaco usado (mais rapido) ou [2] Disco inteiro? [1/2]"
            try {
                if ($drv -eq "C") {
                    $tpm = Get-Tpm -ErrorAction SilentlyContinue
                    if ($tpm -and $tpm.TpmPresent -and $tpm.TpmReady) {
                        Write-Host "  [OK] Chip TPM detectado e pronto. Ativando BitLocker em C: com TPM + Chave de Recuperacao..." -ForegroundColor Green
                        if ($modoEsp -eq "2") {
                            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -TpmProtector -ErrorAction Stop | Out-Null
                        } else {
                            Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -ErrorAction Stop | Out-Null
                        }
                        Add-BitLockerKeyProtector -MountPoint "C:" -RecoveryPasswordProtector -ErrorAction SilentlyContinue | Out-Null
                        Save-BitLockerRecoveryBackup -DriveLetter "C"
                        Write-Host "  [OK] BitLocker configurado em C:! Reinicie o PC para concluir o teste de hardware e iniciar a criptografia." -ForegroundColor Green
                    } else {
                        Write-Host "  [AVISO] Chip TPM nao esta ativo/pronto nesta placa-mae." -ForegroundColor Yellow
                        Write-Host '  [LUCY // Edgerunners 1]: "Ative o fTPM / Intel PTT na BIOS primeiro, ou use VeraCrypt na opcao [6]."' -ForegroundColor Cyan
                    }
                } else {
                    $pwd1 = Read-Host "Digite uma SENHA forte para proteger a unidade ${drv}:" -AsSecureString
                    $pwd2 = Read-Host "Confirme a SENHA" -AsSecureString
                    $b1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd1))
                    $b2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd2))
                    if ($b1 -ne $b2 -or [string]::IsNullOrWhiteSpace($b1)) {
                        Write-Host "  [ERRO] Senhas nao conferem ou vazias." -ForegroundColor Red
                        Pause-Cyber
                        continue
                    }
                    if ($modoEsp -eq "2") {
                        Enable-BitLocker -MountPoint "${drv}:" -EncryptionMethod XtsAes256 -PasswordProtector -Password $pwd1 -ErrorAction Stop | Out-Null
                    } else {
                        Enable-BitLocker -MountPoint "${drv}:" -EncryptionMethod XtsAes256 -UsedSpaceOnly -PasswordProtector -Password $pwd1 -ErrorAction Stop | Out-Null
                    }
                    Add-BitLockerKeyProtector -MountPoint "${drv}:" -RecoveryPasswordProtector -ErrorAction SilentlyContinue | Out-Null
                    Save-BitLockerRecoveryBackup -DriveLetter $drv
                    Write-Host "  [OK] Criptografia iniciada na unidade ${drv}:!" -ForegroundColor Green
                }
            } catch {
                Write-Host "  [ERRO] Falha ao ativar BitLocker em ${drv}:: $($_.Exception.Message)" -ForegroundColor Red
            }
            Pause-Cyber
        }

        elseif ($opC -eq "4") {
            Write-Host "`n--- [4] EXTRAIR E SALVAR CHAVE DE RECUPERACAO BITLOCKER ---" -ForegroundColor Green
            $drv = (Read-Host "Digite a letra da unidade criptografada (ex: C, D, E)").Trim().TrimEnd(':').ToUpper()
            if ($drv -match "^[A-Z]$") {
                Save-BitLockerRecoveryBackup -DriveLetter $drv
            } else {
                Write-Host "  [ERRO] Letra invalida." -ForegroundColor Red
            }
            Pause-Cyber
        }

        elseif ($opC -eq "5") {
            Write-Host "`n--- [5] DESBLOQUEAR OU DESCRIPTOGRAFAR UNIDADE (BITLOCKER) ---" -ForegroundColor Magenta
            Write-Host "  [A] Desbloquear (Unlock) unidade bloqueada com Senha" -ForegroundColor Cyan
            Write-Host "  [B] Descriptografar completamente (Remover BitLocker da unidade)" -ForegroundColor Yellow
            $subD = Read-Host "Escolha [A/B]"
            $drv = (Read-Host "Digite a letra da unidade (ex: D, E)").Trim().TrimEnd(':').ToUpper()
            if (-not ($drv -match "^[A-Z]$")) { Write-Host "  [ERRO] Letra invalida." -ForegroundColor Red; Pause-Cyber; continue }
            if ($subD -match "^[aA]$") {
                manage-bde.exe -unlock "${drv}:" -Password
            } elseif ($subD -match "^[bB]$") {
                $confOff = Read-Host "Confirma REMOVER a criptografia da unidade ${drv}:? [S/N]"
                if ($confOff -match "^[sS]$") {
                    manage-bde.exe -off "${drv}:"
                    Write-Host "  [OK] Descriptografia iniciada em ${drv}:. Acompanhe o progresso pela opcao [1]." -ForegroundColor Green
                }
            }
            Pause-Cyber
        }

        elseif ($opC -eq "6") {
            Write-Host "`n--- [6] VERACRYPT (OPEN-SOURCE // WINDOWS HOME, PEN DRIVES E LINUX) ---" -ForegroundColor DarkCyan
            Write-Host '  [CAPRI // Edgerunners 2]: "O VeraCrypt cria cofres criptografados (.hc) ou criptografa pen drives inteiros,' -ForegroundColor Cyan
            Write-Host '   funcionando em Windows Home, Windows Pro e ate em sistemas Linux!"' -ForegroundColor White
            $vcDir = Join-Path (Get-CyberDeckRoot) "VERACRYPT PORTATIL"
            if (-not (Test-Path $vcDir)) { New-Item -ItemType Directory -Path $vcDir -Force | Out-Null }
            Write-Host "`n  [1] Abrir VeraCrypt agora (se ja estiver na pasta 'VERACRYPT PORTATIL' ou instalado)" -ForegroundColor Green
            Write-Host "  [2] Instalar VeraCrypt neste PC via Winget (IDRIX.VeraCrypt)" -ForegroundColor Yellow
            Write-Host "  [3] Abrir pagina oficial de download do VeraCrypt (para extrair versao portatil no Pen Drive)" -ForegroundColor Cyan
            Write-Host "  [4] Abrir pasta 'VERACRYPT PORTATIL' do projeto" -ForegroundColor White
            $vcOp = Read-Host "Escolha [1-4]"
            if ($vcOp -eq "1") {
                $vcExeNow = Resolve-VeraCryptExe
                if ($vcExeNow) { Start-Process $vcExeNow }
                else { Write-Host "  [AVISO] VeraCrypt.exe nao encontrado ainda. Use [2] ou [3]." -ForegroundColor Yellow }
            } elseif ($vcOp -eq "2") {
                winget install --id IDRIX.VeraCrypt --accept-source-agreements --accept-package-agreements
            } elseif ($vcOp -eq "3") {
                Write-Host "  Dica: ao rodar o instalador do VeraCrypt, escolha 'Extract' (Extrair) e aponte para:" -ForegroundColor Yellow
                Write-Host "  $vcDir" -ForegroundColor Cyan
                Start-Process "https://veracrypt.fr/en/Downloads.html"
            } elseif ($vcOp -eq "4") {
                Start-Process explorer.exe -ArgumentList "`"$vcDir`""
            }
            Pause-Cyber
        }
    }
}

function Test-PasswordLeakFree {
    Write-Host "`n========================================================================" -ForegroundColor Cyan
    Write-Host "  [1] VERIFICADOR DE SENHAS VAZADAS (100% GRATIS + ANONIMO // HIBP)" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host '  [ALT CUNNINGHAM // CP2077]: "Protocolo k-Anonymity ativo: sua senha NUNCA sai deste PC."' -ForegroundColor Red
    Write-Host '  [LUCY // Edgerunners 1]: "Eu calculo o hash SHA-1 localmente e envio apenas os 5 primeiros caracteres para o Have I Been Pwned."' -ForegroundColor Cyan
    Write-Host ""

    $secPwd = Read-Host "Digite a SENHA que deseja testar (fica oculta na tela | ENTER para cancelar)" -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secPwd)
    $plain = $null
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        if ($bstr -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    }

    if ([string]::IsNullOrEmpty($plain)) {
        Write-Host "  [CANCELADO] Nenhuma senha digitada." -ForegroundColor DarkGray
        return
    }

    # Avaliacao local de forca (sem salvar nada)
    $len = $plain.Length
    $hasUpper = $plain -cmatch '[A-Z]'
    $hasLower = $plain -cmatch '[a-z]'
    $hasNum   = $plain -match '[0-9]'
    $hasSym   = $plain -match '[^a-zA-Z0-9]'
    $score = 0
    if ($len -ge 12) { $score += 2 } elseif ($len -ge 8) { $score += 1 }
    if ($hasUpper) { $score++ }
    if ($hasLower) { $score++ }
    if ($hasNum)   { $score++ }
    if ($hasSym)   { $score++ }

    # Calcular SHA-1 localmente e limpar a senha da memoria em seguida
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($plain)
    $hashBytes = $sha1.ComputeHash($bytes)
    $sha1.Dispose()
    $plain = $null
    [Array]::Clear($bytes, 0, $bytes.Length)

    $hashHex = ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToUpper()
    $prefix = $hashHex.Substring(0, 5)
    $suffix = $hashHex.Substring(5)

    Write-Host "  [ANONIMO] Prefixo enviado ao HIBP: $prefix (os outros 35 caracteres ficam apenas no seu PC)" -ForegroundColor DarkGray
    Write-Host "  Consultando api.pwnedpasswords.com (100% gratuito)..." -ForegroundColor Cyan

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $headers = @{ "Add-Padding" = "true"; "User-Agent" = "CyberDeck-OS-Security-Audit" }
        $resp = Invoke-RestMethod -Uri "https://api.pwnedpasswords.com/range/$prefix" -Headers $headers -TimeoutSec 20 -ErrorAction Stop
        $foundCount = 0
        foreach ($line in ($resp -split "`r?`n")) {
            $parts = $line.Split(':')
            if ($parts.Length -eq 2 -and $parts[0].Trim().ToUpper() -eq $suffix) {
                [int64]$parsed = 0
                if ([int64]::TryParse($parts[1].Trim(), [ref]$parsed)) { $foundCount = $parsed }
                break
            }
        }

        Write-Host "`n------------------------------------------------------------------------" -ForegroundColor Magenta
        if ($foundCount -gt 0) {
            Write-Host "  [ALERTA CRITICO] ESTA SENHA JA VAZOU EM BANCOS DE DADOS!" -ForegroundColor Red
            Write-Host ("  Aparicoes encontradas em vazamentos conhecidos: {0:N0} vez(es)" -f $foundCount) -ForegroundColor Red
            Write-Host '  [JOHNNY SILVERHAND // CP2077]: "Queima essa senha agora, Samurai! Troque em todas as contas onde ela foi usada."' -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] Nenhuma ocorrencia encontrada no banco de senhas vazadas do Have I Been Pwned!" -ForegroundColor Green
            Write-Host '  [V // CP2077]: "Limpa nos bancos de vazamento conhecidos. So nao reutilize a mesma senha em varios sites."' -ForegroundColor Cyan
        }

        $forcaTxt = if ($score -ge 5) { "FORTE ($len caracteres)" } elseif ($score -ge 3) { "MEDIA ($len caracteres)" } else { "FRACA ($len caracteres - prefira 12+ com simbolos)" }
        $forcaCor = if ($score -ge 5) { "Green" } elseif ($score -ge 3) { "Yellow" } else { "Red" }
        Write-Host "  Avaliacao local de complexidade: $forcaTxt" -ForegroundColor $forcaCor
        Write-Host "------------------------------------------------------------------------" -ForegroundColor Magenta
    } catch {
        Write-Host "  [ERRO] Falha ao consultar api.pwnedpasswords.com: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host '  [DOC // Edgerunners 1]: "Verifique sua conexao com a internet e tente novamente."' -ForegroundColor Magenta
    }
}

function Test-EmailLeakFree {
    Write-Host "`n========================================================================" -ForegroundColor Yellow
    Write-Host "  [2] VERIFICADOR DE E-MAILS VAZADOS (100% GRATIS // API + NAVEGADOR)" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Yellow
    Write-Host '  [SONGBIRD // CP2077]: "Vou consultar a API gratuita XposedOrNot direto no terminal e oferecer' -ForegroundColor Magenta
    Write-Host '   atalhos gratuitos para Have I Been Pwned, Mozilla Monitor e DeHashed no navegador."' -ForegroundColor White
    Write-Host ""

    $email = (Read-Host "Digite o E-MAIL para auditar (ou ENTER para cancelar)").Trim()
    if ([string]::IsNullOrWhiteSpace($email) -or ($email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$')) {
        Write-Host "  [CANCELADO] E-mail vazio ou formato invalido." -ForegroundColor DarkGray
        return
    }

    Write-Host "`n  [1/2] Consultando base publica gratuita XposedOrNot para: $email ..." -ForegroundColor Cyan
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $encodedEmail = [System.Uri]::EscapeDataString($email)
        $headers = @{ "User-Agent" = "CyberDeck-OS-Security-Audit" }
        $res = Invoke-RestMethod -Uri "https://api.xposedornot.com/v1/check-email/$encodedEmail" -Headers $headers -TimeoutSec 20 -ErrorAction Stop

        $breaches = @()
        if ($res.breaches) {
            foreach ($grp in $res.breaches) {
                if ($grp -is [System.Array]) { $breaches += $grp }
                else { $breaches += $grp }
            }
        }

        if ($breaches.Count -gt 0) {
            Write-Host "`n  [ALERTA] E-mail encontrado em $($breaches.Count) vazamento(s) conhecido(s)!" -ForegroundColor Red
            Write-Host "  Servicos / Bancos de dados reportados:" -ForegroundColor Yellow
            $breaches | Sort-Object -Unique | ForEach-Object { Write-Host "    -> $_" -ForegroundColor Red }
            Write-Host '  [SOLOMON REED // FIA - CP2077]: "Se ainda usa a mesma senha em algum desses servicos, troque agora e ative 2FA."' -ForegroundColor Yellow
        } else {
            Write-Host "  [OK] Nenhum vazamento listado na consulta gratuita do XposedOrNot!" -ForegroundColor Green
            Write-Host '  [CAPRI // Edgerunners 2]: "Boa noticia! Recomendo ainda cruzar no Have I Been Pwned gratuito abaixo."' -ForegroundColor Cyan
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
        }
        if ($statusCode -eq 404) {
            Write-Host "  [OK] Nenhum vazamento encontrado para '$email' na base gratuita XposedOrNot!" -ForegroundColor Green
            Write-Host '  [V // CP2077]: "Radar limpo nessa base, choom."' -ForegroundColor Cyan
        } else {
            Write-Host "  [AVISO] A API gratuita XposedOrNot nao respondeu agora ($($_.Exception.Message))." -ForegroundColor Yellow
            Write-Host "  Voce pode fazer a verificacao gratuita direto nos sites oficiais abaixo." -ForegroundColor White
        }
    }

    Write-Host "`n  [2/2] VERIFICACAO CRUZADA GRATUITA NO NAVEGADOR (SEM PAGAR API):" -ForegroundColor Cyan
    Write-Host "    [A] Abrir Have I Been Pwned (copia seu e-mail para Ctrl+V)" -ForegroundColor Green
    Write-Host "    [B] Abrir DeHashed (consulta web para investigacao profunda)" -ForegroundColor Yellow
    Write-Host "    [C] Abrir Mozilla Monitor (gratis com conta Mozilla)" -ForegroundColor Magenta
    Write-Host "    [T] Abrir TODOS os 3 sites acima no navegador" -ForegroundColor Cyan
    Write-Host "    [0] Nao abrir navegador agora" -ForegroundColor DarkGray
    $navOp = (Read-Host "Escolha [A/B/C/T/0]").Trim().ToUpper()

    if ($navOp -in @("A","B","C","T")) {
        try { Set-Clipboard -Value $email -ErrorAction SilentlyContinue } catch {}
        Write-Host "  [DICA] Seu e-mail foi copiado para a Area de Transferencia (basta pressionar Ctrl+V no site)." -ForegroundColor Cyan
        if ($navOp -eq "A" -or $navOp -eq "T") { Start-Process "https://haveibeenpwned.com/" }
        if ($navOp -eq "B" -or $navOp -eq "T") { Start-Process "https://dehashed.com/" }
        if ($navOp -eq "C" -or $navOp -eq "T") { Start-Process "https://monitor.mozilla.org/" }
    }
}

function Test-OnlineShieldAudit {
    Write-Host "`n========================================================================" -ForegroundColor Green
    Write-Host "  [3] AUDITORIA DE DNS ANTI-PHISHING E SEGURANCA DE DOMINIO DE E-MAIL" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Green
    Write-Host '  [JUDY ALVAREZ // CP2077]: "Checando se o DNS do seu PC tem protecao contra sites falsos e phishing..."' -ForegroundColor Cyan

    $dnsList = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses }
    $knownSafe = @{
        "9.9.9.9"         = "Quad9 (Bloqueio de Malware/Phishing)"
        "149.112.112.112" = "Quad9 Secundario"
        "94.140.14.14"    = "AdGuard DNS (Bloqueio de Ads/Phishing)"
        "94.140.15.15"    = "AdGuard DNS Secundario"
        "1.1.1.2"         = "Cloudflare Malware Blocking"
        "1.0.0.2"         = "Cloudflare Malware Blocking"
        "1.1.1.1"         = "Cloudflare DNS (Rapido / Privado)"
        "1.0.0.1"         = "Cloudflare DNS Secundario"
        "8.8.8.8"         = "Google Public DNS"
        "8.8.4.4"         = "Google Public DNS"
    }
    foreach ($d in $dnsList) {
        $addrs = $d.ServerAddresses -join ", "
        $notes = @()
        foreach ($ip in $d.ServerAddresses) {
            if ($knownSafe.ContainsKey($ip)) { $notes += $knownSafe[$ip] }
        }
        $tag = if ($notes.Count -gt 0) { " -> " + ($notes -join " | ") } else { " -> DNS da Operadora / Roteador Local" }
        Write-Host ("  Interface: {0,-22} | DNS: {1}{2}" -f $d.InterfaceAlias, $addrs, $tag) -ForegroundColor White
    }

    Write-Host "`n  [OPCIONAL] Verificar protecao anti-falsificacao (SPF/DMARC) de um dominio de e-mail:" -ForegroundColor Yellow
    $dom = (Read-Host "Digite um dominio (ex: gmail.com, outlook.com ou seu dominio | ENTER para pular)").Trim()
    if ($dom) {
        $dom = ($dom -replace '^.*@', '').Trim()
        Write-Host "  Consultando registros SPF e DMARC de '$dom'..." -ForegroundColor Cyan
        $txtRec = Resolve-DnsName -Name $dom -Type TXT -ErrorAction SilentlyContinue | Where-Object { $_.Strings -match "v=spf1" }
        $dmarcRec = Resolve-DnsName -Name "_dmarc.$dom" -Type TXT -ErrorAction SilentlyContinue | Where-Object { $_.Strings -match "v=DMARC1" }
        if ($txtRec) { Write-Host "  [OK] SPF ativo:   $($txtRec[0].Strings -join ' ')" -ForegroundColor Green }
        else { Write-Host "  [AVISO] Nenhum registro SPF encontrado para $dom." -ForegroundColor Yellow }
        if ($dmarcRec) { Write-Host "  [OK] DMARC ativo: $($dmarcRec[0].Strings -join ' ')" -ForegroundColor Green }
        else { Write-Host "  [AVISO] Nenhum registro DMARC encontrado para $dom." -ForegroundColor Yellow }
    }
}

function Show-OnlineProtectionGuide {
    Clear-Host
    Show-BootBanner "[20-G] GUIA DE BLINDAGEM ONLINE (ANTI-VAZAMENTOS E PHISHING)"
    Write-Host '  [VIKTOR VEKTOR // CP2077]: "Descobrir vazamento e metade do trabalho. Aqui esta como blindar suas contas de vez:"' -ForegroundColor Green
    Write-Host ""
    Write-Host "  1. GERENCIADOR DE SENHAS (SENHA UNICA POR SITE):" -ForegroundColor Cyan
    Write-Host "     - Bitwarden (gratis, open-source, sincroniza PC e celular)" -ForegroundColor White
    Write-Host "     - KeePassXC (100% offline e portatil - pode levar o cofre no seu Pen Drive!)" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. AUTENTICACAO EM 2 FATORES (NUNCA USE SMS):" -ForegroundColor Yellow
    Write-Host "     - Troque SMS (vulneravel a golpe de SIM Swap) por apps open-source:" -ForegroundColor White
    Write-Host "       Ente Auth ou Aegis Authenticator, e ative Passkeys onde houver." -ForegroundColor White
    Write-Host ""
    Write-Host "  3. ALIASES DE E-MAIL (ISOLAMENTO DE VAZAMENTOS):" -ForegroundColor Magenta
    Write-Host "     - Use SimpleLogin, Addy.io ou DuckDuckGo Email Protection para cadastros." -ForegroundColor White
    Write-Host "     - Se um site vazar, voce sabe exatamente qual foi e desativa so aquele alias." -ForegroundColor White
    Write-Host ""
    Write-Host "  4. REVOGAR APPS ANTIGOS (OAUTH) E REVISAR SESSOES:" -ForegroundColor Green
    Write-Host "     - Google:    https://myaccount.google.com/security" -ForegroundColor DarkGray
    Write-Host "     - Microsoft: https://account.microsoft.com/security" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [A] Abrir Portal de Seguranca Google | [B] Abrir Portal Microsoft | [0] Voltar" -ForegroundColor Cyan
    $gOp = (Read-Host "Escolha [A/B/0]").Trim().ToUpper()
    if ($gOp -eq "A") { Start-Process "https://myaccount.google.com/security" }
    elseif ($gOp -eq "B") { Start-Process "https://account.microsoft.com/security" }
}


function Resolve-PhotoRecExe {
    $root = Get-CyberDeckRoot
    $candidates = @(
        (Join-Path $root "PROGRAMAS BACKUP\PhotoRec\qphotorec_win.exe"),
        (Join-Path $root "PROGRAMAS BACKUP\PhotoRec\photorec_win.exe")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Resolve-TestDiskExe {
    $root = Get-CyberDeckRoot
    $c = Join-Path $root "PROGRAMAS BACKUP\TestDisk\testdisk_win.exe"
    if (Test-Path $c) { return $c }
    return $null
}

function Install-PortableBackupTools {
    $root = Get-CyberDeckRoot
    $backupRoot = Join-Path $root "PROGRAMAS BACKUP"
    $photoRecDir = Join-Path $backupRoot "PhotoRec"
    $testDiskDir = Join-Path $backupRoot "TestDisk"

    if (-not (Test-Path $photoRecDir)) { New-Item -ItemType Directory -Path $photoRecDir -Force | Out-Null }
    if (-not (Test-Path $testDiskDir)) { New-Item -ItemType Directory -Path $testDiskDir -Force | Out-Null }

    Write-Host "`n  [VIKTOR VEKTOR // CP2077]: `"Baixando ferramentas portateis de recuperacao (PhotoRec & TestDisk)...`"" -ForegroundColor Cyan
    Write-Host "  Destino no Pen Drive / Projeto: $backupRoot" -ForegroundColor Yellow

    $zipTemp = Join-Path $env:TEMP "cyberdeck_testdisk_photorec.zip"
    $extractTemp = Join-Path $env:TEMP "cyberdeck_testdisk_photorec_ext"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $url = "https://www.cgsecurity.org/testdisk-7.2.win64.zip"
        Invoke-DownloadWithProgress -Url $url -OutFile $zipTemp -Label "TestDisk & PhotoRec Portateis (CGSecurity)"
        Write-Host "  [2/2] Extraindo e estruturando 'PhotoRec' e 'TestDisk'..." -ForegroundColor Yellow

        if (Test-Path $extractTemp) { Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue }
        $oldPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Expand-Archive -Path $zipTemp -DestinationPath $extractTemp -Force -ErrorAction Stop
        $ProgressPreference = $oldPref

        $sourceDir = Get-ChildItem -Path $extractTemp -Directory | Select-Object -First 1
        $srcPath = if ($sourceDir) { $sourceDir.FullName } else { $extractTemp }

        # Copia todos os arquivos necessarios para PhotoRec
        Get-ChildItem -Path $srcPath | Where-Object { $_.Name -notmatch "(?i)^testdisk" -and $_.Name -notmatch "(?i)^fidentify" } | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $photoRecDir -Recurse -Force
        }

        # Copia todos os arquivos necessarios para TestDisk
        Get-ChildItem -Path $srcPath | Where-Object { $_.Name -notmatch "(?i)^photorec" -and $_.Name -notmatch "(?i)^qphotorec" } | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $testDiskDir -Recurse -Force
        }

        # Gera guia de sobrevivencia
        $guideFile = Join-Path $backupRoot "COMO_USAR_PHOTOREC_E_TESTDISK.txt"
        $guideContent = @"
========================================================================
CYBERDECK // CENTRAL DE RECUPERACAO DE DADOS (PHOTOREC & TESTDISK)
========================================================================
Estes programas sao 100% portateis e funcionam direto do seu Pen Drive / SSD Externo.

PASTAS:
  1. PhotoRec/
     - qphotorec_win.exe  -> Interface Grafica com janelas (Recomendado para Iniciantes)
     - photorec_win.exe   -> Terminal CLI com recuperacao profunda por assinatura (Carving)
     Destinado a: Recuperar fotos, videos, musicas, documentos apagados ou formatados.

  2. TestDisk/
     - testdisk_win.exe   -> Recuperador de particoes, tabela MBR/GPT e bootloader
     Destinado a: Discos que ficaram 'RAW', particoes perdidas/deletadas, erro de boot.

REGRA DE OURO DA RECUPERACAO:
  NUNCA salve os arquivos recuperados no mesmo disco/pendrive de onde esta recuperando!
  Sempre aponte a pasta de destino para:
  Area de Trabalho: Desktop\DADOS\BACKUP - [DATA]\RECUPERACAO_DADOS_PHOTOREC_TESTDISK
  ou na pasta DADOS do seu proprio Pen Drive CYBERDECK.
========================================================================
"@
        Set-Content -Path $guideFile -Value $guideContent -Encoding UTF8

        Remove-Item -Path $zipTemp -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $extractTemp -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "  [OK] PhotoRec e TestDisk instalados com sucesso em 'PROGRAMAS BACKUP'!" -ForegroundColor Green
        Write-Host '  [DAVID MARTINEZ // Edgerunners]: "Ferramentas portateis prontas no pen drive. Sem instalador, sem rastro."' -ForegroundColor Yellow
        return $true
    } catch {
        Write-Host "`n  [ERRO] Falha ao baixar ou extrair ferramentas: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host '  [CAPRI // Edgerunners 2]: "Voce pode baixar testdisk-7.2.win64.zip manualmente em cgsecurity.org e colocar nas pastas."' -ForegroundColor Magenta
        return $false
    }
}

function Invoke-Op22 {
    while ($true) {
        Clear-Host
        Show-BootBanner "[22] CENTRAL DE BACKUP E RECUPERACAO DE DADOS // PHOTOREC & TESTDISK"
        Write-Host '  [VIKTOR VEKTOR // CP2077]: "Arquivos deletados ou particao corrompida? Vamos puxar de volta do abismo."' -ForegroundColor Green
        Write-Host '  [SONGBIRD // CP2077]: "PhotoRec varre por assinatura de bytes no metal cru; TestDisk restaura o mapa de particoes."' -ForegroundColor Magenta
        Write-Host ""

        $qphoto = Resolve-PhotoRecExe
        $testd  = Resolve-TestDiskExe
        $root   = Get-CyberDeckRoot
        $backupDir = Join-Path $root "PROGRAMAS BACKUP"

        $dadosDesktop = Get-DesktopDatedDadosDir -SubFolder "RECUPERACAO_DADOS_PHOTOREC_TESTDISK"
        $dadosProjeto = Get-CyberDeckDadosDir -SubFolder "RECUPERACAO_DADOS_PHOTOREC_TESTDISK"

        Write-Host "  PASTA DE DESTINO DOS DADOS RECUPERADOS (CONFIGURADA NO SISTEMA):" -ForegroundColor DarkGray
        Write-Host "    >> Area de Trabalho : $dadosDesktop" -ForegroundColor Cyan
        Write-Host "    >> Pen Drive/Projeto: $dadosProjeto" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  STATUS DAS FERRAMENTAS PORTATEIS ('PROGRAMAS BACKUP'):" -ForegroundColor DarkGray
        if ($qphoto) {
            Write-Host "    [OK] PhotoRec / QPhotoRec : PRONTO ($qphoto)" -ForegroundColor Green
        } else {
            Write-Host "    [!]  PhotoRec / QPhotoRec : NAO BAIXADO (Use a opcao [6] para baixar)" -ForegroundColor Yellow
        }
        if ($testd) {
            Write-Host "    [OK] TestDisk             : PRONTO ($testd)" -ForegroundColor Green
        } else {
            Write-Host "    [!]  TestDisk             : NAO BAIXADO (Use a opcao [6] para baixar)" -ForegroundColor Yellow
        }
        Write-Host "========================================================================" -ForegroundColor Yellow
        Write-Host "  [1] EXECUTAR QPHOTOREC (Interface Grafica Visual // Recomendado para Iniciantes)" -ForegroundColor Green
        Write-Host "  [2] EXECUTAR PHOTOREC (Terminal Avancado / Recuperacao Profunda em Modo RAW)" -ForegroundColor Cyan
        Write-Host "  [3] EXECUTAR TESTDISK (Recuperacao de Particoes, Setor de Boot e Tabela MBR/GPT)" -ForegroundColor Yellow
        Write-Host "  [4] ABRIR PASTA DE DADOS RECUPERADOS (Area de Trabalho - Desktop\DADOS)" -ForegroundColor Magenta
        Write-Host "  [5] ABRIR PASTA DADOS NO PEN DRIVE / PROJETO (DADOS\)" -ForegroundColor DarkCyan
        Write-Host "  [6] BAIXAR / REINSTALAR FERRAMENTAS PORTATEIS EM 'PROGRAMAS BACKUP'" -ForegroundColor White
        Write-Host "  [7] GUIA DE PROTOCOLO: Como Recuperar Arquivos e Particoes sem Perder Dados" -ForegroundColor DarkYellow
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Yellow
        $op = Read-Host "Escolha uma opcao [0-7]"

        if ($op -eq "0") { break }
        elseif ($op -eq "1") {
            $qpExe = Join-Path $backupDir "PhotoRec\qphotorec_win.exe"
            if (-not (Test-Path $qpExe)) {
                Write-Host "`n  [AVISO] QPhotoRec nao encontrado. Baixando pacote portatil agora..." -ForegroundColor Yellow
                Install-PortableBackupTools
            }
            if (Test-Path $qpExe) {
                Write-Host "`n  [INICIANDO QPHOTOREC] Interface Grafica Visual..." -ForegroundColor Green
                Write-Host "  Lembrete: Selecione o disco e aponte a pasta de destino para:" -ForegroundColor Yellow
                Write-Host "  $dadosDesktop" -ForegroundColor Cyan
                Start-Process -FilePath $qpExe -Verb RunAs
            } else {
                Write-Host "  [ERRO] Nao foi possivel iniciar o QPhotoRec." -ForegroundColor Red
            }
            Pause-Cyber
        }
        elseif ($op -eq "2") {
            $pExe = Join-Path $backupDir "PhotoRec\photorec_win.exe"
            if (-not (Test-Path $pExe)) {
                Write-Host "`n  [AVISO] PhotoRec nao encontrado. Baixando pacote portatil agora..." -ForegroundColor Yellow
                Install-PortableBackupTools
            }
            if (Test-Path $pExe) {
                Write-Host "`n  [INICIANDO PHOTOREC] Terminal de Recuperacao Profunda..." -ForegroundColor Cyan
                Write-Host "  Lembrete: Aponte a pasta de destino para: $dadosDesktop" -ForegroundColor Yellow
                Start-Process -FilePath $pExe -Verb RunAs
            } else {
                Write-Host "  [ERRO] Nao foi possivel iniciar o PhotoRec." -ForegroundColor Red
            }
            Pause-Cyber
        }
        elseif ($op -eq "3") {
            $tExe = Join-Path $backupDir "TestDisk\testdisk_win.exe"
            if (-not (Test-Path $tExe)) {
                Write-Host "`n  [AVISO] TestDisk nao encontrado. Baixando pacote portatil agora..." -ForegroundColor Yellow
                Install-PortableBackupTools
            }
            if (Test-Path $tExe) {
                Write-Host "`n  [INICIANDO TESTDISK] Reparador de Particoes e Bootloader..." -ForegroundColor Yellow
                Start-Process -FilePath $tExe -Verb RunAs
            } else {
                Write-Host "  [ERRO] Nao foi possivel iniciar o TestDisk." -ForegroundColor Red
            }
            Pause-Cyber
        }
        elseif ($op -eq "4") {
            if (-not (Test-Path $dadosDesktop)) { New-Item -ItemType Directory -Path $dadosDesktop -Force | Out-Null }
            Start-Process explorer.exe -ArgumentList "`"$dadosDesktop`""
        }
        elseif ($op -eq "5") {
            if (-not (Test-Path $dadosProjeto)) { New-Item -ItemType Directory -Path $dadosProjeto -Force | Out-Null }
            Start-Process explorer.exe -ArgumentList "`"$dadosProjeto`""
        }
        elseif ($op -eq "6") {
            Install-PortableBackupTools
            Pause-Cyber
        }
        elseif ($op -eq "7") {
            Clear-Host
            Show-BootBanner "[GUIA] REGRAS DE OURO DA RECUPERACAO DE DADOS"
            Write-Host "  ========================================================================" -ForegroundColor Yellow
            Write-Host "  1. A REGRA NUMERO 1: NUNCA SALVE OS ARQUIVOS NO MESMO DISCO!" -ForegroundColor Red
            Write-Host "     Se voce esta recuperando dados do Pen Drive E:, salve SEMPRE no disco C:" -ForegroundColor White
            Write-Host "     ou na pasta Desktop\DADOS. Se salvar no mesmo pen drive, voce ira sobrescrever" -ForegroundColor White
            Write-Host "     os setores dos arquivos que ainda nao foram recuperados." -ForegroundColor White
            Write-Host ""
            Write-Host "  2. QUANDO USAR O QPHOTOREC (OU PHOTOREC)?" -ForegroundColor Green
            Write-Host "     - Quando fotos, videos, musicas, documentos Word/PDF foram apagados ou formatados." -ForegroundColor White
            Write-Host "     - O PhotoRec le bloco a bloco (carving) ignorando o sistema de arquivos." -ForegroundColor White
            Write-Host "     - O QPhotoRec possui janelas com mouse (muito mais facil para selecionar as fotos)." -ForegroundColor White
            Write-Host ""
            Write-Host "  3. QUANDO USAR O TESTDISK?" -ForegroundColor Cyan
            Write-Host "     - Quando o pen drive ou HD pede para formatar ou aparece em modo 'RAW'." -ForegroundColor White
            Write-Host "     - Quando sumiu uma particao inteira do Windows ou Linux." -ForegroundColor White
            Write-Host "     - O TestDisk reescreve a tabela de particao (MBR/GPT) e recupera sem precisar" -ForegroundColor White
            Write-Host "       copiar arquivo por arquivo." -ForegroundColor White
            Write-Host ""
            Write-Host "  4. LOCALIZACAO PORTATIL NO SEU PEN DRIVE:" -ForegroundColor Magenta
            Write-Host "     As pastas estao na raiz do projeto em 'PROGRAMAS BACKUP\PhotoRec' e 'TestDisk'." -ForegroundColor White
            Write-Host "     Voce pode levar esse pen drive para qualquer computador e executar direto!" -ForegroundColor White
            Write-Host "  ========================================================================" -ForegroundColor Yellow
            Pause-Cyber
        }
    }
}


function Invoke-Op20 {
    while ($true) {
        Clear-Host
        Show-BootBanner "[20] SEGURANCA ONLINE: AUDITORIA DE VAZAMENTOS (100% GRATUITO)"
        Write-Host '  [SONGBIRD // CP2077]: "Modulo de inteligencia contra vazamentos ativo - 100% gratuito, sem chave paga."' -ForegroundColor Magenta
        Write-Host '  [ALT CUNNINGHAM // CP2077]: "Senhas sao testadas via k-Anonymity (nunca trafegam pela rede)."' -ForegroundColor Red
        Write-Host ""
        Write-Host "  [1] Verificar SENHA vazada (100% Gratis + Anonimo via Have I Been Pwned)" -ForegroundColor Cyan
        Write-Host "  [2] Verificar E-MAIL vazado (API gratuita XposedOrNot + HIBP / DeHashed / Monitor)" -ForegroundColor Yellow
        Write-Host "  [3] Auditar DNS Anti-Phishing do PC + Protecao SPF/DMARC de Dominios" -ForegroundColor Green
        Write-Host "  [4] Guia de Blindagem Online (Bitwarden, KeePassXC, 2FA, Aliases e Portais)" -ForegroundColor Magenta
        Write-Host "  [0] Voltar ao Menu Principal" -ForegroundColor DarkGray
        Write-Host "========================================================================" -ForegroundColor Cyan
        $op20 = Read-Host "Escolha uma opcao [0-4]"

        if ($op20 -eq "0") { break }
        elseif ($op20 -eq "1") { Test-PasswordLeakFree; Pause-Cyber }
        elseif ($op20 -eq "2") { Test-EmailLeakFree; Pause-Cyber }
        elseif ($op20 -eq "3") { Test-OnlineShieldAudit; Pause-Cyber }
        elseif ($op20 -eq "4") { Show-OnlineProtectionGuide }
    }
}


Assert-Admin

function Show-CyberDeckNotice {
    param([string]$BordaColor = "Yellow")
    # -- CREDITOS DO AUTOR E PROIBICAO COMERCIAL (OFUSCADOS EM BASE64) --
    $_c1 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Q3JpYWRvciBkbyBDWUJFUi1ERUNLOiBBZG9uaXMgUGVpeG90byAoRGFudGUzMTQ3KSB8IERpc2NvcmQ6IGRhbnRlXzMxNDcgfCBFbWFpbDogc3Vwb3J0ZUBkYW50ZTMxNDcuYW5vbmFkZHkubWU='))
    $_c2 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Q1lCRVItREVDSyBDcmVhdG9yOiBBZG9uaXMgUGVpeG90byAoRGFudGUzMTQ3KSB8IERpc2NvcmQ6IGRhbnRlXzMxNDcgfCBFbWFpbDogc3Vwb3J0ZUBkYW50ZTMxNDcuYW5vbmFkZHkubWU='))
    $_c3 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Q3JlYWRvciBkZWwgQ1lCRVItREVDSzogQWRvbmlzIFBlaXhvdG8gKERhbnRlMzE0NykgfCBEaXNjb3JkOiBkYW50ZV8zMTQ3IHwgRW1haWw6IHN1cG9ydGVAZGFudGUzMTQ3LmFub25hZGR5Lm1l'))
    $_p1 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Q09NRVJDSUFMSVpBQ0FPIEVTVFJJVEFNRU5URSBQUk9JQklEQSB8IEFwZW5hcyBwYXJhIHVzbyBwZXNzb2FsIGUgZWR1Y2FjaW9uYWw='))
    $_p2 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('Q09NTUVSQ0lBTCBVU0UgU1RSSUNUTFkgUFJPSElCSVRFRCB8IEZvciBwZXJzb25hbCBhbmQgZWR1Y2F0aW9uYWwgdXNlIG9ubHk='))
    $_p3 = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('VVNPIENPTUVSQ0lBTCBFU1RSSUNUQU1FTlRFIFBST0hJQklETyB8IFNvbG8gcGFyYSB1c28gcGVyc29uYWwgeSBlZHVjYXRpdm8='))

    Write-Host "========================================================================" -ForegroundColor $BordaColor
    Write-Host "  PT | $_c1" -ForegroundColor Cyan
    Write-Host "  EN | $_c2" -ForegroundColor Cyan
    Write-Host "  ES | $_c3" -ForegroundColor Cyan
    Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PT | !! $_p1" -ForegroundColor Red
    Write-Host "  EN | !! $_p2" -ForegroundColor Red
    Write-Host "  ES | !! $_p3" -ForegroundColor Red
    Write-Host "========================================================================" -ForegroundColor $BordaColor
}

function Select-Corporation {
    while ($true) {
        $Host.UI.RawUI.WindowTitle = "CYBERDECK OS v36.0 // CONEXAO NEURAL (POWERSHELL)"
        Clear-Host
        Show-BootBanner "CYBERDECK OS v36.0 // NIGHT CITY EDITION"
        Show-CyberDeckNotice -BordaColor "Yellow"
        Write-Host ""
        Write-Host "  SELECIONE SEU PROTOCOLO CORPORATIVO / FACCAO:" -ForegroundColor White
        Write-Host "  [1] ARASAKA CORP         - Vermelho/Branco (Saburo, Hanako, Capri)" -ForegroundColor Red
        Write-Host "  [2] MILITECH             - Amarelo Tatico (NUSA, Reed, Songbird)" -ForegroundColor Yellow
        Write-Host "  [3] KANG TAO             - Ciano/Azul (Smart-Tech, Takemura)" -ForegroundColor Cyan
        Write-Host "  [4] NETWATCH / BLACKWALL - Magenta/Ciano (Alt Cunningham)" -ForegroundColor Magenta
        Write-Host "  [5] AFTERLIFE / MERC     - Neon Edgerunners (David, Lucy, Weak & D)" -ForegroundColor Yellow
        Write-Host "  [6] TRAUMA TEAM          - Verde/Branco (Gloria, Viktor)" -ForegroundColor Green
        Write-Host ""
        $c = Read-Host "Escolha sua afiliacao [1-6]"
        $choiceMap = @{
            "1" = @{ Key="arasaka";  Pri="Red";    Sec="White"; Nome="ARASAKA CORPORATION // PROJETO CAPRICORN"; Frase="Saburo & Capri: A ordem nasce do controle." }
            "2" = @{ Key="militech"; Pri="Yellow"; Sec="Gray";  Nome="MILITECH INTERNATIONAL ARMAMENTS // NUSA"; Frase="Solomon Reed: Eficiencia balistica aplicada ao hardware." }
            "3" = @{ Key="kangtao";  Pri="Cyan";   Sec="Blue";  Nome="KANG TAO // DIVISAO SMART-TECH";           Frase="Takemura: Precisao cirurgica." }
            "4" = @{ Key="netwatch"; Pri="Magenta";Sec="Cyan";  Nome="NETWATCH // BARREIRA BLACKWALL";           Frase="Alt Cunningham: Mantenha as IAs hostis fora da rede." }
            "5" = @{ Key="afterlife";Pri="Yellow"; Sec="Cyan";  Nome="AFTERLIFE // EDGERUNNERS OS (2076-2078)";  Frase="Rogue & David: Sem finais felizes em Night City... mas o PC vai voar." }
            "6" = @{ Key="trauma";   Pri="Green";  Sec="White"; Nome="TRAUMA TEAM INTERNATIONAL // PLANO PLATINA";Frase="Gloria & Vik: Sinais vitais do hardware estaveis." }
        }
        if ($choiceMap.ContainsKey($c)) {
            $sel = $choiceMap[$c]
            $global:ActiveCorpoKey = $sel.Key
            $global:tema = $sel
            try {
                Set-Content -Path "$env:TEMP\cyberdeck_active_theme.txt" -Value $sel.Key -Encoding ASCII -Force -ErrorAction SilentlyContinue
            } catch {}
            return $sel
        }
        Write-Host '  [REBECCA // Edgerunners 1]: "Escolhe de 1 a 6, choom!"' -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

Register-MobileExitCleanup
Invoke-CheckUpdateOnBoot
$tema = Select-Corporation

while ($true) {
    $Host.UI.RawUI.WindowTitle = "$($tema.Nome) (PowerShell)"
    Clear-Host
    Write-Host "========================================================================" -ForegroundColor $tema.Pri
    Write-Host "  [$($tema.Nome)]" -ForegroundColor $tema.Pri
    Write-Host "  `"$($tema.Frase)`"" -ForegroundColor DarkGray
    Write-Host "========================================================================" -ForegroundColor $tema.Pri
    Write-Host ""
    Write-Host "  [ATUALIZACOES E DRIVERS]" -ForegroundColor $tema.Sec
    Write-Host "    1. Atualizar todos os programas (Winget)"
    Write-Host "    2. Verificar / Atualizar Placa de Video (NVIDIA / AMD)"
    Write-Host "    3. Gerenciador de Dispositivos: Verificar, Corrigir e Atualizar Drivers"
    Write-Host ""
    Write-Host "  [LIMPEZA DE ICE E INTEGRIDADE NEURAL]" -ForegroundColor $tema.Sec
    Write-Host "    4. Limpar Arquivos Temporarios (Temp)"
    Write-Host "    5. Reparar Windows (DISM + SFC - Anti-Ciberpsicose)"
    Write-Host "    6. Limpar Cache do Windows Update"
    Write-Host "    7. Limpar Cache de Shaders (DirectX / NVIDIA / AMD)"
    Write-Host ""
    Write-Host "  [DESEMPENHO E CROMO (HARDWARE)]" -ForegroundColor $tema.Sec
    Write-Host "    8. Otimizacao Inteligente de Discos (SSD=TRIM / HD=Defrag)"
    Write-Host "    9. Ativar Modo Sandevistan (Energia: Desempenho Maximo)"
    Write-Host "   10. Diagnostico de Cromo: Saude SMART e Bateria"
    Write-Host ""
    Write-Host "  [NETRUNNING, SEGURANCA E PRIVACIDADE]" -ForegroundColor $tema.Sec
    Write-Host "   11. Reset Completo de Rede e DNS (Fugir da NetWatch)"
    Write-Host "   12. Criar Ponto de Restauracao (Mikoshi)"
    Write-Host "   13. Backup da Lista de Programas (Winget Export)"
    Write-Host "   14. Barreira Blackwall: Malware, Backdoors, ngrok, Usuarios e Scans" -ForegroundColor Magenta
    Write-Host "   15. Modo Fantasma: Auditoria Interativa de Telemetria (Desativar/Reativar)" -ForegroundColor Magenta
    Write-Host "   16. Overclock Neural: Otimizacao + Limpeza Regedit/%APPDATA% (Apps Removidos)" -ForegroundColor Magenta
    Write-Host "   17. Backup de Navegadores (Favoritos, Senhas e Perfis)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [SEGURANCA DE CELULARES ANDROID E IPHONE]" -ForegroundColor $tema.Sec
    Write-Host "   18. Auditoria Mobile: Apps Nocivos, Malware/Botnets, Arquivos e Permissoes" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [CRIPTOGRAFIA E COFRE DE DISCOS]" -ForegroundColor $tema.Sec
    Write-Host "   19. Criptografar Pen Drives e Unidades de Disco (BitLocker + VeraCrypt)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [SEGURANCA ONLINE E VAZAMENTO DE DADOS]" -ForegroundColor $tema.Sec
    Write-Host "   20. Auditoria de Vazamentos: Senhas (k-Anonymity), E-mails e Blindagem" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [ATUALIZACOES DO CYBERDECK]" -ForegroundColor $tema.Sec
    Write-Host "   21. Central de Atualizacoes (Baixar Update / Ver O Que Mudou)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  [RECUPERACAO E BACKUP DE DADOS (DADOS / PEN DRIVE)]" -ForegroundColor $tema.Sec
    Write-Host "   22. Recuperacao de Arquivos e Particoes: PhotoRec + TestDisk Portateis" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [PROTOCOLOS ESPECIAIS]" -ForegroundColor $tema.Sec
    Write-Host "   99. Rotina Rapida (1 + 4 + 8)  |  88. Trocar Corporacao  |  0. Sair" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor $tema.Pri
    Show-CyberDeckNotice -BordaColor $tema.Pri
    $op = Read-Host "Escolha uma opcao e pressione ENTER"
    switch ($op) {
        "1"  { Invoke-Op01 }
        "2"  { Invoke-Op02 }
        "3"  { Invoke-Op16 }
        "4"  { Invoke-Op03 }
        "5"  { Invoke-Op04 }
        "6"  { Invoke-Op05 }
        "7"  { Invoke-Op06 }
        "8"  { Invoke-Op07 }
        "9"  { Invoke-Op08 }
        "10" { Invoke-Op09 }
        "11" { Invoke-Op10 }
        "12" { Invoke-Op11 }
        "13" { Invoke-Op12 }
        "14" { Invoke-Op13 }
        "15" { Invoke-Op14 }
        "16" { Invoke-Op15 }
        "17" { Invoke-Op17 }
        "18" { Invoke-Op18 }
        "19" { Invoke-Op19 }
        "20" { Invoke-Op20 }
        "21" { Invoke-MenuAtualizacoes }
        "22" { Invoke-Op22 }
        "99" { Invoke-Op01; Invoke-Op03; Invoke-Op07 }
        "88" { $tema = Select-Corporation }
        "upd" { Invoke-MenuAtualizacoes }
        "UPD" { Invoke-MenuAtualizacoes }
        "log" { Show-ChangelogViewer }
        "LOG" { Show-ChangelogViewer }
        "0"  {
            Clear-Host
            Stop-MobileBackgroundProcesses
            Write-Host '  [JACKIE WELLES // CP2077]: "Nos vemos nas grandes ligas, mano."' -ForegroundColor Yellow
            Write-Host '  [MISTY OLSZEWSKI // CP2077]: "Que as cartas te guiem em Night City."' -ForegroundColor Magenta
            Start-Sleep -Seconds 2
            exit
        }
        default { Write-Host '  [SKIPPY // CP2077]: "Opcao invalida, choom."' -ForegroundColor Red; Start-Sleep -Seconds 1 }
    }
}
