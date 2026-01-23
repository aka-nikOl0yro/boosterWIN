<#
.SYNOPSIS
    Script DNS Benchmark V10 - Tabella Dettagliata
    Mostra i ping ai singoli servizi separatamente.
#>

# --- CONTROLLO AMMINISTRATORE ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERRORE: Esegui come Amministratore!"
    Start-Sleep -Seconds 3
    Exit
}

Clear-Host
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "    BENCHMARK DNS V1.10 " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# --- 1. SELEZIONE SCHEDA ---
$AllAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if (!$AllAdapters) { Write-Error "Nessuna rete."; Exit }

Write-Host "Schede trovate:" -ForegroundColor Yellow
$i = 1
foreach ($adapter in $AllAdapters) {
    Write-Host " [$i] $($adapter.Name)"
    $i++
}

$selectedId = 0
do {
    $inputVal = Read-Host "`nScegli numero scheda (es. 2)"
    if ($inputVal -match "^\d+$" -and [int]$inputVal -ge 1 -and [int]$inputVal -le $AllAdapters.Count) {
        $selectedId = [int]$inputVal
    }
} until ($selectedId -gt 0)

$Interface = $AllAdapters[$selectedId - 1]
Write-Host "Uso: $($Interface.Name)" -ForegroundColor Green

# --- 2. DISABILITA IPv6 (TENTATIVO FIX 12s) ---
try {
    if ((Get-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6).Enabled) {
        Disable-NetAdapterBinding -Name $Interface.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
        Write-Host "IPv6 disabilitato." -ForegroundColor DarkGray
        Start-Sleep -Seconds 2
    }
} catch {}

# --- 3. LISTA SERVIZI COMPLETA ---
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
	"ec2.eu-south-1.amazonaws.com",   # AWS MILANO (Server ITA Fortnite)
    "ec2.eu-central-1.amazonaws.com", # AWS FRANCOFORTE (Server EU Main)
    "ec2.eu-west-2.amazonaws.com"    # AWS LONDRA (Server EU West)
)

# --- 4. LISTA DNS ---
$DnsList = @(
    @{ Id=0; Name="Default";    Primary="Auto";       Secondary="Auto" },
    @{ Id=1; Name="Google";     Primary="8.8.8.8";    Secondary="8.8.4.4" },
    @{ Id=2; Name="Cloudflare"; Primary="1.1.1.1";    Secondary="1.0.0.1" },
    @{ Id=3; Name="OpenDNS";    Primary="208.67.222.222"; Secondary="208.67.220.220" },
    @{ Id=4; Name="Quad9";      Primary="9.9.9.9";    Secondary="149.112.112.112" }
)

$Results = @()

function Get-PingLatency ($target) {
    $rawOutput = ping.exe -n 1 -w 1000 $target | Out-String
    if ($rawOutput -match "(?i)(durata|time)\s*[=<]\s*(?<ms>\d+)ms") { return [int]$Matches['ms'] }
    return 9999
}

# --- 5. LOOP DI TEST ---
foreach ($dns in $DnsList) {
    Write-Host "`n------------------------------------------------"
    Write-Host " TEST: $($dns.Name)" -ForegroundColor Yellow

    # Cambio DNS
    try {
        if ($dns.Id -eq 0) {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses -ErrorAction Stop
        } else {
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($dns.Primary, $dns.Secondary) -ErrorAction Stop
        }
    } catch { continue }

    # Attesa
    Clear-DnsClientCache
    Write-Host " -> Applico DNSs... " -NoNewline
    Start-Sleep -Seconds 2
    Write-Host "OK."

    # Inizializza l'oggetto per i risultati di questo DNS (Uso Ordered per mantenere l'ordine delle colonne)
    $dnsResult = [ordered]@{}
    $dnsResult["Id"] = $dns.Id
    $dnsResult["Name"] = $dns.Name

    $totalPing = 0
    $count = 0

    foreach ($srv in $Services) {
        # Nome colonna breve (rimuove .com, .tv ecc per spazio)
        $colName = $srv -replace "\..*",""
        
        Write-Host " -> Ping $colName... " -NoNewline
        $ms = Get-PingLatency $srv
        
        if ($ms -lt 9999) {
            Write-Host "${ms}ms" -ForegroundColor White
            $dnsResult[$colName] = $ms
            $totalPing += $ms
            $count++
        } else {
            Write-Host "X" -ForegroundColor Red
            $dnsResult[$colName] = "X"
        }
    }

    if ($count -gt 0) { 
        $dnsResult["MEDIA"] = [math]::Round($totalPing / $count, 1)
    } else { 
        $dnsResult["MEDIA"] = 9999 
    }

    # Aggiungi all'array dei risultati convertendo l'hash table in oggetto
    $Results += [PSCustomObject]$dnsResult
}

# --- 6. TABELLA FINALE ---
# Ordina per MEDIA
$ResultsSorted = $Results | Sort-Object "MEDIA"

Clear-Host
Write-Host "=== RISULTATI (ms) ===" -ForegroundColor Cyan
# Format-Table automatico mostrerà tutte le colonne create dinamicamente
$ResultsSorted | Format-Table -AutoSize

if ($ResultsSorted.Count -gt 0) { $Best = $ResultsSorted[0] }

# --- 7. SCELTA ---
Write-Host "---------------------------------------------"
Write-Host " [0] Default/ISP"
Write-Host " [1-4] Scegli ID"
Write-Host " [A] Migliore ($($Best.Name))"
Write-Host " [X] Esci"

$choice = Read-Host "`nScelta"
switch -Regex ($choice) {
    "^[0]$" { Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses; Write-Host "Reset OK." }
    "^[1-4]$" { 
        $p = $DnsList | Where-Object {$_.Id -eq $choice}
        if($p){ Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($p.Primary, $p.Secondary); Write-Host "Impostato $($p.Name)." }
    }
    "^[Aa]$" {
        if($Best.Id -eq 0) { Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ResetServerAddresses }
        else { 
            $p = $DnsList | Where-Object {$_.Id -eq $Best.Id}
            Set-DnsClientServerAddress -InterfaceIndex $Interface.InterfaceIndex -ServerAddresses ($p.Primary, $p.Secondary) 
        }
        Write-Host "Migliore applicato."
    }
}
Read-Host "Premi Invio"