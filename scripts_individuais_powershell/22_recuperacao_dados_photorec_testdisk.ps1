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


Invoke-Op22
