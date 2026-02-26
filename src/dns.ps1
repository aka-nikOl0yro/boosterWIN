<#
.SYNOPSIS
    Script DNS Benchmark V2.0
    Testa piu' DNS con ping multipli (mediana), parallelizzati per velocita'.
    Ripristina IPv6 se lo ha disabilitato. Mostra il migliore e lo applica.
#>

# ===================================================================
# === CONTROLLO AMMINISTRATORE ===
# ===================================================================
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERRORE: Esegui come Amministratore!"
    Start-Sleep -Seconds 3
    Exit
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "       BENCHMARK DNS V2.0                   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# ===================================================================
# === 1. SELEZIONE SCHEDA DI RETE ===
# ===================================================================
$AllAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if (!$AllAdapters) { Write-Error "Nessuna scheda di rete attiva trovata."; Exit }

Write-Host "`nSchede di rete trovate:" -ForegroundColor Yellow
$i = 1
foreach ($adapter in $AllAdapters) {
    Write-Host " [$i] $($adapter.Name)"
    $i++
}

$selectedId = 0
do {
    $inputVal = Read-Host "`nScegli il numero della scheda da testare"
    if ($inputVal -match "^\d+$" -and [int]$inputVal -ge 1 -and [int]$inputVal -le $AllAdapters.Count) {
        $selectedId = [int]$inputVal
    } else {
        Write-Host " Scelta non valida, riprova." -ForegroundColor Red
    }
} until ($selectedId -gt 0)

$Interface = $AllAdapters[$selectedId - 1]
Write-Host "`n[OK] Scheda selezionata: $($Interface.Name)" -ForegroundColor Green

# ===================================================================
# === 2. DISABILITA IPv6 TEMPORANEAMENTE (evita delay da 12s) ===
# ===================================================================
$ipv6WasEnabled = $false
try {
    $ipv6Binding = Get-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    if ($ipv6Binding -and $ipv6Binding.Enabled) {
        Disable-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        $ipv6WasEnabled = $true
        Write-Host "[*] IPv6 disabilitato temporaneamente per il benchmark." -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
    }
} catch {}

# ===================================================================
# === 3. LISTA SERVER DA TESTARE ===
# ===================================================================
$Services = @(
    "google.com",
    "1.1.1.1",
    "steampowered.com",
    "riotgames.com",
    "ubisoft.com",
    "ea.com",
    "blizzard.com",
    "twitch.tv",
    "discord.com",
    "ec2.eu-south-1.amazonaws.com",   # AWS MILANO   (Fortnite ITA)
    "ec2.eu-central-1.amazonaws.com", # AWS FRANCOFORTE (EU Main)
    "ec2.eu-west-2.amazonaws.com"     # AWS LONDRA   (EU West)
)

# ===================================================================
# === 4. LISTA DNS DA TESTARE ===
# ===================================================================
$DnsList = @(
    @{ Id=0; Name="Default/ISP"; Primary="Auto";            Secondary="Auto" },
    @{ Id=1; Name="Google";      Primary="8.8.8.8";         Secondary="8.8.4.4" },
    @{ Id=2; Name="Cloudflare";  Primary="1.1.1.1";         Secondary="1.0.0.1" },
    @{ Id=3; Name="OpenDNS";     Primary="208.67.222.222";  Secondary="208.67.220.220" },
    @{ Id=4; Name="Quad9";       Primary="9.9.9.9";         Secondary="149.112.112.112" }
)

# ===================================================================
# === 5. FUNZIONE PING CON MEDIANA (4 ping, prende il valore centrale) ===
# ===================================================================
function Get-PingMedian ($target) {
    $rawOutput = ping.exe -n 4 -w 1000 $target | Out-String
    $matches_all = [regex]::Matches($rawOutput, "(?i)(durata|time)\s*[=<]\s*(?<ms>\d+)ms")
    $latencies = @()
    foreach ($m in $matches_all) { $latencies += [int]$m.Groups['ms'].Value }
    if ($latencies.Count -eq 0) { return 9999 }
    $sorted = $latencies | Sort-Object
    return $sorted[[math]::Floor($sorted.Count / 2)]
}

# ===================================================================
# === 6. LOOP DI TEST ===
# ===================================================================
$Results = @()

foreach ($dns in $DnsList) {
    Write-Host "`n------------------------------------------------"
    Write-Host " TEST: $($dns.Name)" -ForegroundColor Yellow

    # Imposta il DNS
    try {
        if ($dns.Id -eq 0) {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses -ErrorAction Stop
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($dns.Primary, $dns.Secondary) -ErrorAction Stop
        }
    } catch {
        Write-Host " [!] Impossibile impostare il DNS $($dns.Name), salto." -ForegroundColor Red
        continue
    }

    # Svuota cache DNS e attendi propagazione
    Clear-DnsClientCache
    Write-Host " -> DNS applicato, attendo propagazione..." -NoNewline
    Start-Sleep -Seconds 2
    Write-Host " OK."

    # --- Ping paralleli tramite Start-Job ---
    Write-Host " -> Avvio ping paralleli su $($Services.Count) server..." -ForegroundColor DarkGray

    $jobs = foreach ($srv in $Services) {
        $colName = $srv -replace "\..*", ""
        Start-Job -ScriptBlock {
            param($target, $col)
            $raw = ping.exe -n 4 -w 1000 $target | Out-String
            $ms_matches = [regex]::Matches($raw, "(?i)(durata|time)\s*[=<]\s*(?<ms>\d+)ms")
            $latencies = @()
            foreach ($m in $ms_matches) { $latencies += [int]$m.Groups['ms'].Value }
            if ($latencies.Count -eq 0) { return @{ Col=$col; Ms=9999 } }
            $sorted = $latencies | Sort-Object
            $median = $sorted[[math]::Floor($sorted.Count / 2)]
            return @{ Col=$col; Ms=$median }
        } -ArgumentList $srv, $colName
    }

    # Attendi tutti i job e raccogli risultati
    $jobResults = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job -Force

    # Costruisci oggetto risultato ordinato
    $dnsResult = [ordered]@{}
    $dnsResult["Id"]   = $dns.Id
    $dnsResult["Name"] = $dns.Name

    $totalPing = 0
    $count = 0

    foreach ($jr in $jobResults) {
        $col = $jr.Col
        $ms  = $jr.Ms
        if ($ms -lt 9999) {
            Write-Host "    $col : ${ms}ms" -ForegroundColor White
            $dnsResult[$col] = $ms
            $totalPing += $ms
            $count++
        } else {
            Write-Host "    $col : X" -ForegroundColor Red
            $dnsResult[$col] = "X"
        }
    }

    $dnsResult["MEDIA"] = if ($count -gt 0) { [math]::Round($totalPing / $count, 1) } else { 9999 }

    $Results += [PSCustomObject]$dnsResult
}

# ===================================================================
# === 7. RIPRISTINO IPv6 (se era abilitato prima) ===
# ===================================================================
if ($ipv6WasEnabled) {
    try {
        Enable-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Host "`n[*] IPv6 riabilitato." -ForegroundColor DarkGray
    } catch {}
}

# ===================================================================
# === 8. TABELLA FINALE ===
# ===================================================================
$ResultsSorted = $Results | Sort-Object "MEDIA"
$Best = $ResultsSorted[0]

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "         RISULTATI BENCHMARK DNS (ms)        " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
$ResultsSorted | Format-Table -AutoSize

Write-Host "---------------------------------------------"
Write-Host " DNS piu' veloce per te: $($Best.Name) - media $($Best.MEDIA) ms" -ForegroundColor Green
Write-Host "---------------------------------------------"

# ===================================================================
# === 9. SCELTA FINALE ===
# ===================================================================
Write-Host ""
Write-Host " [0]   Default/ISP (reset)"
Write-Host " [1-4] Scegli per ID"
Write-Host " [A]   Applica il migliore ($($Best.Name))"
Write-Host " [X]   Esci senza modifiche"
Write-Host ""

$choice = Read-Host "Scelta"

switch -Regex ($choice.Trim()) {
    "^[0]$" {
        Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses
        Write-Host "[OK] DNS ripristinato al Default/ISP." -ForegroundColor Green
    }
    "^[1-4]$" {
        $picked = $DnsList | Where-Object { $_.Id -eq [int]$choice }
        if ($picked) {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($picked.Primary, $picked.Secondary)
            Write-Host "[OK] DNS impostato: $($picked.Name) ($($picked.Primary))." -ForegroundColor Green
        }
    }
    "^[Aa]$" {
        if ($Best.Id -eq 0) {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses
        } else {
            $picked = $DnsList | Where-Object { $_.Id -eq $Best.Id }
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($picked.Primary, $picked.Secondary)
        }
        Write-Host "[OK] DNS migliore applicato: $($Best.Name) ($($Best.MEDIA) ms)." -ForegroundColor Green
    }
    "^[Xx]$" {
        Write-Host "[*] Nessuna modifica applicata." -ForegroundColor DarkGray
    }
    default {
        Write-Host "[!] Scelta non valida. Nessuna modifica applicata." -ForegroundColor Red
    }
}

Write-Host ""
Read-Host "Premi Invio per chiudere"