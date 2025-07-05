# Require admin privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Richiesti privilegi amministrativi. Riavviare lo script come amministratore." -ForegroundColor Red
    exit 1
}

# Creazione punto di ripristino
try {
    $rpDesc = "Pre-Optimizzazione Gaming - " + (Get-Date -Format "yyyyMMddHHmmss")
    Checkpoint-Computer -Description $rpDesc -ErrorAction Stop
    Write-Host "Creato punto di ripristino: $rpDesc" -ForegroundColor Green
} catch {
    Write-Host "Impossibile creare punto di ripristino. Continuo comunque..." -ForegroundColor Yellow
}

function Set-RegistryValue {
    param($path, $name, $value, $type = "DWORD")
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force
}

Write-Host "`n=== APPLICAZIONE IMPOSTAZIONI GAMING ===" -ForegroundColor Cyan

# 1. Algoritmo congestione per bassa latenza
Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider DCTCP -ErrorAction SilentlyContinue

# 2. Parametri TCP aggressivi
Set-NetTCPSetting -SettingName InternetCustom -InitialRto 300 -MinRto 50 -InitialCongestionWindow 16 -ErrorAction SilentlyContinue
Set-NetTCPSetting -SettingName InternetCustom -MaxSynRetransmissions 2 -NonSackRttResiliency disabled -Timestamps disabled -ErrorAction SilentlyContinue

# 3. Disabilita ottimizzazioni dannose per gaming
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing disabled -ErrorAction SilentlyContinue
Get-NetAdapter | Enable-NetAdapterChecksumOffload -ErrorAction SilentlyContinue
Get-NetAdapter | Enable-NetAdapterLso -ErrorAction SilentlyContinue

# 4. Impostazioni interrupt schede di rete
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Buffers" -DisplayValue 512 -ErrorAction SilentlyContinue
}

# 5. Disabilita throttling multimediale
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "AlwaysOn" 0

# 6. Priorità traffico gaming
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" 1
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38

# 7. Ottimizzazioni registro specifiche
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpAckFrequency" 1
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TCPNoDelay" 1
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DisableTaskOffload" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0

# 8. Ottimizzazione MTU
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $adapterName = $_.Name
    netsh interface ipv4 set subinterface "`"$adapterName`"" mtu=1472 store=persistent 2>&1 | Out-Null
}

# 9. Power settings per performance massime
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # Schema "Ultimate Performance"
Get-NetAdapter | ForEach-Object {
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
    Set-NetAdapterPowerManagement -Name $_.Name -AllowComputerToTurnOffDevice $false -ErrorAction SilentlyContinue
}

# 10. Pulizia cache DNS
Clear-DnsClientCache

Write-Host "`nOTTIMIZZAZIONE GAMING COMPLETATA!" -ForegroundColor Green
Write-Host "Riavvio del sistema consigliato per applicare tutte le modifiche" -ForegroundColor Yellow

# Rilevamento bisogno riavvio
$needsReboot = $true
if ($needsReboot) {
    Write-Host "`nRIACCIONE NECESSARIO: Le modifiche richiedono riavvio per efficacia completa" -ForegroundColor Magenta
}