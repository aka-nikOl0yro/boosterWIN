# Require admin privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Richiesti privilegi amministrativi. Riavviare lo script come amministratore." -ForegroundColor Red
    exit 1
}

# Creazione punto di ripristino
try {
    $rpDesc = "Pre-Ottimizzazione Generale - " + (Get-Date -Format "yyyyMMddHHmmss")
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

Write-Host "`n=== APPLICAZIONE IMPOSTAZIONI GENERALI ===" -ForegroundColor Cyan

# 1. Algoritmo congestione bilanciato
$osVersion = [System.Environment]::OSVersion.Version
$congestionAlgo = if ($osVersion -ge [Version]"10.0.19041") { "bbr2" } else { "ctcp" }
Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider $congestionAlgo -ErrorAction SilentlyContinue

# 2. Parametri TCP ottimizzati
Set-NetTCPSetting -SettingName InternetCustom -AutoTuningLevel normal -ScalingHeuristics disabled -ErrorAction SilentlyContinue
Set-NetTCPSetting -SettingName InternetCustom -InitialRto 1000 -MinRto 150 -InitialCongestionWindow 10 -ErrorAction SilentlyContinue
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing enabled -ReceiveSideScaling enabled -ErrorAction SilentlyContinue

# 3. Ottimizzazioni offload
Get-NetAdapter | Enable-NetAdapterChecksumOffload -ErrorAction SilentlyContinue
Get-NetAdapter | Enable-NetAdapterLso -ErrorAction SilentlyContinue

# 4. Impostazioni registro avanzate
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxUserPort" 65535
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 30
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 10
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 20

# 5. Ottimizzazione MTU
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $adapterName = $_.Name
    netsh interface ipv4 set subinterface "`"$adapterName`"" mtu=1500 store=persistent 2>&1 | Out-Null
}

# 6. Impostazioni DNS
Set-DnsClientGlobalSetting -SuffixSearchList @()
Set-DnsClient -InterfaceAlias * -ConnectionSpecificSuffix "" -RegisterThisConnectionsAddress $true -UseSuffixWhenRegistering $false
Clear-DnsClientCache

# 7. Ottimizzazioni sistema
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\MemoryManagement" "LargeSystemCache" 1
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" "Size" 3
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 26

# 8. Power settings bilanciati
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e  # Schema "Bilanciato"
Get-NetAdapter | ForEach-Object {
    Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
}

# 9. Impostazioni QoS
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 64
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" "Do not use NLA" 1

# 10. Disabilita IPv6 non necessario
Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -notmatch "Loopback" } | ForEach-Object {
    Disable-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
}

Write-Host "`nOTTIMIZZAZIONE GENERALE COMPLETATA!" -ForegroundColor Green
Write-Host "Alcune modifiche richiedono riavvio per efficacia completa" -ForegroundColor Yellow