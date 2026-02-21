<#
.SYNOPSIS
    Script per il debloating di Windows, ottimizzato per la massima compatibilità e pulizia.
    Rimuove app preinstallate, disabilita task di telemetria e servizi non essenziali.
.DESCRIPTION
    Eseguire con privilegi di amministratore.
#>

$tasks = @(
    "ProgramDataUpdater",
    "Microsoft-Windows-DiskDiagnosticDataCollector",
    "Microsoft-Windows-WER-Triggered",
    "RegIdleBackup",
    "DmClient",
    "TileDataDownloader",
    "RestartBPT",
    "DownloadContentTask",
    "AppIDManagement",
    "Application Crash Telemetry",
    "Autotune",
    "AitAgent",
    "XblGameSaveTask",
    "StartupAppTask",
    "WDI Run Downloader Task",
    "WinSAT"
)

Write-Host "[*] Disabilitazione dei task pianificati per la telemetria..." -ForegroundColor Yellow
foreach ($task in $tasks) {
    try {
        Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
        Write-Host "  - Task '$task' disabilitato." -ForegroundColor Green
    }
    catch {
        Write-Host "  - Impossibile disabilitare il task '$task'. Potrebbe non esistere. (Errore: $_)" -ForegroundColor Red
    }
}

# ===================================================================
# === RIMOZIONE APP PREINSTALLATE (BLOATWARE) ===
# ===================================================================

# Lista di app considerate bloatware e generalmente sicure da rimuovere
$bloatwareApps = @(
    "Microsoft.BingNews",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.People",
	"Microsoft.549981C3F5F10",                # Cortana
    "Microsoft.BingWeather",  
	"Microsoft.SkypeApp",                     # Skype
    "Microsoft.YourPhone",                    # Collegamento al telefono
    "Microsoft.Todos",                        # Microsoft To Do
	"MicrosoftCorporationII.MicrosoftFamily" # Microsoft Family Safety
)

# Lista di app che alcuni utenti potrebbero trovare utili. Verrà chiesta conferma prima della rimozione.
$potentiallyUsefulApps = @(

    "Microsoft.MicrosoftStickyNotes",         # Sticky Notes
    "Microsoft.WindowsAlarms",                # Sveglie e Orologio
    "Microsoft.WindowsCamera",                # Fotocamera
    "Microsoft.WindowsSoundRecorder",         # Registratore di suoni
    "Microsoft.Todos",                        # Microsoft To Do
    "Microsoft.OutlookForWindows",            # Il nuovo Outlook
    "MicrosoftTeams",                         # Microsoft Teams
    "Microsoft.WindowsCommunicationsApps",    # Posta e Calendario
    "MicrosoftCorporationII.QuickAssist",     # Assistenza rapida
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay"
)

# Rimuove sempre il bloatware comune
Write-Host "`n[*] Rimozione delle App bloatware comuni..." -ForegroundColor Yellow
foreach ($app in $bloatwareApps) {
    
        $packages = Get-AppxPackage -Name "*$app*" -AllUsers -ErrorAction SilentlyContinue
        if ($packages) {
            foreach ($package in $packages) {
                # Tenta di fermare i processi associati al pacchetto prima della rimozione
                try {
                    $manifestPath = Join-Path $package.InstallLocation 'AppxManifest.xml'
                    if (Test-Path $manifestPath) {
                        [xml]$manifest = Get-Content -Path $manifestPath
                        foreach ($application in $manifest.Package.Applications.Application) {
                            if ($application.Executable) {
                                $processName = [System.IO.Path]::GetFileNameWithoutExtension($application.Executable)
                                Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                } catch {} # Ignora errori, il processo potrebbe non essere in esecuzione
				
                try {
                # Usiamo -Package e il nome completo per essere più precisi
                Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                Write-Host "  - Pacchetto $($package.Name) rimosso." -ForegroundColor Green
            }
            catch {
                # Se QUESTO pacchetto specifico fallisce, cattura l'errore qui!
                # Il ciclo non si ferma e passerà al pacchetto successivo.
                Write-Host "  - Impossibile rimuovere il pacchetto $($package.Name). (Errore: $_)" -ForegroundColor DarkGray
            }
        }
        # Quando ha finito di scorrere tutti i pacchetti dell'app, ce lo comunica
        Write-Host "  - Operazione conclusa per l'app '$app'." -ForegroundColor Cyan
    }
}

# Chiede all'utente se vuole rimuovere le app potenzialmente utili
Write-Host ""
$title = "Rimozione App Potenzialmente Utili"
$message = "Vuoi rimuovere anche le app potenzialmente utili (es. Fotocamera, Sticky Notes, Xbox, Posta, Collegamento al Telefono)?"
$choices = [System.Management.Automation.Host.ChoiceDescription[]]@(
    New-Object System.Management.Automation.Host.ChoiceDescription("&Si", "Rimuove le app aggiuntive.")
    New-Object System.Management.Automation.Host.ChoiceDescription("&No", "Mantiene queste app installate.")
)
$decision = $Host.UI.PromptForChoice($title, $message, $choices, 1)

if ($decision -eq 0) {
Write-Host "`n[*] Rimozione delle App potenzialmente utili..." -ForegroundColor Yellow
    foreach ($app in $potentiallyUsefulApps) {
        $packages = Get-AppxPackage -Name "*$app*" -AllUsers -ErrorAction SilentlyContinue
        if ($packages) {
            foreach ($package in $packages) {
                try {
                    $manifestPath = Join-Path $package.InstallLocation 'AppxManifest.xml'
                    if (Test-Path $manifestPath) {
                        [xml]$manifest = Get-Content -Path $manifestPath
                        foreach ($application in $manifest.Package.Applications.Application) {
                            if ($application.Executable) {
                                $processName = [System.IO.Path]::GetFileNameWithoutExtension($application.Executable)
                                Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                } catch {} 
                
                try {
                    Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                    Write-Host "  - Pacchetto $($package.Name) rimosso." -ForegroundColor Green
                } catch {
                    Write-Host "  - Impossibile rimuovere il pacchetto $($package.Name). (Errore: $_)" -ForegroundColor DarkGray
                }
            }
            Write-Host "  - Operazione conclusa per l'app '$app'." -ForegroundColor Cyan
        }
    }
}

$services = @(
    "diagnosticshub.standardcollector.service",
    "DiagTrack",
    "dmwappushservice"
)

Write-Host "`n[*] Disabilitazione dei servizi di telemetria e non essenziali..." -ForegroundColor Yellow
foreach ($service in $services) {
    try {
        Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Write-Host "  - Servizio '$service' disabilitato e interrotto." -ForegroundColor Green
    }
    catch {
        Write-Host "  - Impossibile disabilitare il servizio '$service'. Potrebbe non esistere. (Errore: $_)" -ForegroundColor Red
    }
}

# Disabilitazione condizionale di SysMain (Superfetch) in base al tipo di disco
try {
    $systemDrive = Get-PhysicalDisk | Where-Object { $_.DeviceID -match (Get-Partition | Where-Object { $_.DriveLetter -eq 'C' }).DiskNumber }
    if ($systemDrive.MediaType -eq 'SSD') {
        Write-Host "`n[*] Rilevato SSD come disco di sistema. Disabilitazione di SysMain (Superfetch)..." -ForegroundColor Yellow
        Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop
        Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
        Write-Host "  - Servizio 'SysMain' disabilitato e interrotto." -ForegroundColor Green
    } else {
        Write-Host "`n[*] Rilevato HDD come disco di sistema. Il servizio SysMain (Superfetch) verra' mantenuto attivo." -ForegroundColor Cyan
    }
} catch {
    Write-Host "`n- Impossibile determinare il tipo di disco o gestire il servizio SysMain. (Errore: $_)" -ForegroundColor Red
}

# Importazione file di registro (se esiste)
$regFile = "fotoenable.reg"
if (Test-Path $regFile) {
    Write-Host "`n[*] Importazione del file di registro '$regFile'..." -ForegroundColor Yellow
    try {
        reg.exe import $regFile
        Write-Host "  - File di registro importato con successo." -ForegroundColor Green
    } catch {
        Write-Host "  - Errore durante l'importazione del file di registro. (Errore: $_)" -ForegroundColor Red
    }
}

# ===================================================================
# === RIMOZIONE COMPLETA DI ONEDRIVE ===
# ===================================================================
Write-Host "`n[*] Tentativo di rimozione completa di OneDrive..." -ForegroundColor Yellow

try {
    # 1. Termina tutti i processi di OneDrive
    Write-Host "  - Interruzione dei processi di OneDrive in esecuzione..."
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    taskkill.exe /F /IM OneDrive.exe > $null 2>&1

    # 2. Esegui lo script di disinstallazione di OneDrive
    Write-Host "  - Esecuzione dello script di disinstallazione..."
    $oneDriveSetupPath32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
    $oneDriveSetupPath64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

    if (Test-Path $oneDriveSetupPath64) {
        Start-Process -FilePath $oneDriveSetupPath64 -ArgumentList "/uninstall /silent /force" -Wait
    }
    elseif (Test-Path $oneDriveSetupPath32) {
        Start-Process -FilePath $oneDriveSetupPath32 -ArgumentList "/uninstall /silent /force" -Wait
    }
    else {
        Write-Host "  - OneDriveSetup.exe non trovato. Potrebbe essere gia' stato rimosso." -ForegroundColor Cyan
    }

    # Attendi un istante e termina di nuovo i processi
    Start-Sleep -Seconds 5
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    taskkill.exe /F /IM OneDrive.exe > $null 2>&1

    # 3. Rimuovi le chiavi di registro per l'integrazione con Esplora File e avvio automatico
    Write-Host "  - Rimozione delle chiavi di registro residue..."
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue -Force
    Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force
    Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force

    # 4. Rimuovi le cartelle residue di OneDrive
    Write-Host "  - Rimozione delle cartelle residue..."
    "$env:USERPROFILE\OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:PROGRAMDATA\Microsoft OneDrive", "C:\OneDriveTemp" | ForEach-Object {
        if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
    }
    Write-Host "  - Rimozione di OneDrive completata." -ForegroundColor Green
}
catch {
    Write-Host "  - Si e' verificato un errore durante la rimozione di OneDrive. (Errore: $_)" -ForegroundColor Red
}

Write-Host "`n[OK] Script di debloating completato." -ForegroundColor Cyan


Write-Host "  - Riavvio di Esplora File per aggiornare l'interfaccia..."
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
# Pausa di 1 secondo per dare il tempo a Windows di chiudere bene gli handle aperti
Start-Sleep -Seconds 1 

# Riavvia la shell in modo sicuro
Start-Process "explorer.exe"
