# Require admin privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Richiesti privilegi amministrativi. Riavviare lo script come amministratore." -ForegroundColor Red
    exit 1
}

# Imposta frequenza minima punti di ripristino (minuti)
$minRestorePointInterval = 60

# Creazione punto di ripristino
try {
    $lastRestorePoint = Get-ComputerRestorePoint -LastStatus 2>$null
    $createRestorePoint = $true
    
    if ($lastRestorePoint) {
        $timeSinceLast = (Get-Date) - $lastRestorePoint.CreationTime
        if ($timeSinceLast.TotalMinutes -lt $minRestorePointInterval) {
            Write-Host "Punto di ripristino recente esistente ($([math]::Floor($timeSinceLast.TotalMinutes)) minuti). Salto la creazione." -ForegroundColor Yellow
            $createRestorePoint = $false
        }
    }
    
    if ($createRestorePoint) {
        $rpDesc = "Pre-Optimizzazione Gaming - " + (Get-Date -Format "yyyyMMddHHmmss")
        Checkpoint-Computer -Description $rpDesc -ErrorAction Stop
        Write-Host "Creato punto di ripristino: $rpDesc" -ForegroundColor Green
    }
} catch {
    Write-Host "Impossibile creare punto di ripristino: $($_.Exception.Message)" -ForegroundColor Yellow
}

function Set-RegistryValue {
    param($path, $name, $value, $type = "DWORD")
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force
}

# Funzione per ottenere adattatori di rete fisici
function Get-PhysicalNetAdapter {
    Get-NetAdapter | Where-Object {
        $_.Name -notmatch 'Bluetooth|Virtual|Hyper-V|Test|Loopback' -and
        $_.InterfaceDescription -notmatch 'Virtual|TAP|Test'
    }
}

# Funzione per disabilitare il risparmio energetico della scheda di rete
function Disable-NetAdapterPowerSaving {
    param($adapterName)
    
    # Metodo 1: Disabilitazione tramite registro
    try {
        $adapterProps = Get-NetAdapterAdvancedProperty -Name $adapterName -ErrorAction Stop
        $adapterGUID = ($adapterProps | Where-Object { $_.RegistryKeyword -eq "InterfaceGuid" }).RegistryValue
        
        if ($adapterGUID) {
            $powerSettingsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$adapterGUID"
            
            # Imposta valori per disabilitare il risparmio energetico
            Set-ItemProperty -Path $powerSettingsPath -Name "PnPCapabilities" -Value 24 -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path $powerSettingsPath -Name "*PowerSave" -Value 0 -Type DWord -ErrorAction Stop
            Set-ItemProperty -Path $powerSettingsPath -Name "EnablePowerManagement" -Value 0 -Type DWord -ErrorAction Stop
            
            return $true
        }
    } catch { echo "Fallback al metodo 2 " }
    
    # Metodo 2: Disabilitazione tramite PowerShell
    try {
        if (Get-Command Set-NetAdapterPowerManagement -ErrorAction SilentlyContinue) {
            Set-NetAdapterPowerManagement -Name $adapterName -AllowComputerToTurnOffDevice "Disabled" -ErrorAction Stop
            return $true
        }
    } catch { echo "Fallback al metodo 3 " }
    
    # Metodo 3: Disabilitazione tramite devcon (strumento Microsoft)
    try {
        $devconPath = Join-Path $env:TEMP "devcon.exe"
        if (-not (Test-Path $devconPath)) {
            # Scarica devcon se non presente
            $sourceUrl = "https://github.com/ayrnx/ayrnx.github.io/raw/main/devcon.exe"
            Invoke-WebRequest -Uri $sourceUrl -OutFile $devconPath -ErrorAction Stop
        }
        
        # Trova l'ID hardware dell'adattatore
        $adapterInfo = Get-NetAdapter -Name $adapterName | Select-Object -ExpandProperty HardwareID
        if ($adapterInfo) {
            & $devconPath disable "@$($adapterInfo[0])" | Out-Null
            & $devconPath setpower "@$($adapterInfo[0])" DISABLE | Out-Null
            return $true
        }
    } catch { echo "Tutti i metodi falliti "}
    
    return $false
}

Write-Host "`n=== APPLICAZIONE IMPOSTAZIONI GAMING ===" -ForegroundColor Cyan

# 1. Algoritmo congestione per bassa latenza
Set-NetTCPSetting -SettingName InternetCustom -CongestionProvider DCTCP -ErrorAction SilentlyContinue

# 2. Parametri TCP aggressivi
Set-NetTCPSetting -SettingName InternetCustom -InitialRto 300 -MinRto 50 -InitialCongestionWindow 16 -ErrorAction SilentlyContinue
Set-NetTCPSetting -SettingName InternetCustom -MaxSynRetransmissions 2 -NonSackRttResiliency disabled -Timestamps disabled -ErrorAction SilentlyContinue

# 3. Disabilita ottimizzazioni dannose per gaming
Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing disabled -ErrorAction SilentlyContinue
Get-PhysicalNetAdapter | Enable-NetAdapterChecksumOffload -ErrorAction SilentlyContinue
Get-PhysicalNetAdapter | Enable-NetAdapterLso -ErrorAction SilentlyContinue

# 4. Impostazioni interrupt schede di rete
Get-PhysicalNetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    try {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -ErrorAction Stop
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Buffers" -DisplayValue 512 -ErrorAction Stop
    } catch {
        Write-Host "Adattatore $($_.Name): impostazioni avanzate non supportate" -ForegroundColor DarkGray
    }
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
Get-PhysicalNetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $adapterName = $_.Name
    try {
        netsh interface ipv4 set subinterface "`"$adapterName`"" mtu=1472 store=persistent | Out-Null
    } catch {
        Write-Host "Impossibile impostare MTU per $adapterName" -ForegroundColor DarkGray
    }
}

# 9. Power settings per performance massime
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # Schema "Ultimate Performance"
Get-PhysicalNetAdapter | ForEach-Object {
    $adapterName = $_.Name
    
    # Disabilita Energy Efficient Ethernet (se supportato)
    try {
        $eeeSupport = Get-NetAdapterAdvancedProperty -Name $adapterName | 
                      Where-Object { $_.DisplayName -like "*Energy Efficient*" }
        
        if ($eeeSupport) {
            Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName $eeeSupport.DisplayName -DisplayValue "Disabled" -ErrorAction Stop
            Write-Host "Disabilitato Energy Efficient Ethernet per $adapterName" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "Energy Efficient Ethernet non supportato per $adapterName" -ForegroundColor DarkGray
    }
    
    # Disabilita risparmio energetico scheda di rete (3 metodi alternativi)
    try {
        $result = Disable-NetAdapterPowerSaving -adapterName $adapterName
        if ($result) {
            Write-Host "Disabilitato risparmio energetico per $adapterName" -ForegroundColor Green
        } else {
            Write-Host "Impossibile disabilitare risparmio energetico per $adapterName" -ForegroundColor DarkGray
        }
    } catch {
        # CORREZIONE: Sintassi corretta per evitare errore di parsing
        Write-Host "Errore disabilitazione risparmio energetico per ${adapterName}: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}

# 10. Disabilita Selective Suspend USB (metodo universale)
try {
    # Metodo 1: Impostazione registro globale
    $usbPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    if (-not (Test-Path $usbPath)) {
        New-Item -Path $usbPath -Force | Out-Null
    }
    Set-ItemProperty -Path $usbPath -Name "DisableSelectiveSuspend" -Value 1 -Type DWord -ErrorAction Stop
    
    # Metodo 2: Comando powercfg aggiuntivo
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    
    Write-Host "Disabilitato Selective Suspend USB" -ForegroundColor Green
} catch {
    Write-Host "Impossibile disabilitare Selective Suspend USB. Errore: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# 11. Pulizia cache DNS
Clear-DnsClientCache

Write-Host "`nOTTIMIZZAZIONE GAMING COMPLETATA!" -ForegroundColor Green
Write-Host "Riavvio del sistema consigliato per applicare tutte le modifiche" -ForegroundColor Yellow

# Rilevamento bisogno riavvio
$needsReboot = $true
if ($needsReboot) {
    Write-Host "`nRIACCIONE NECESSARIO: Le modifiche richiedono riavvio per efficacia completa" -ForegroundColor Magenta
}