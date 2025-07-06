param()

# ================================================
# FUNZIONI DEBLOAT
# ================================================

function Disable-UnnecessaryScheduledTasks {
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
    
    Write-Host "`nDisabilitazione task pianificati non necessari..."
    foreach ($task in $tasks) {
        try {
            Disable-ScheduledTask -TaskName $task -TaskPath '\Microsoft\Windows\' -ErrorAction Stop
            Write-Host "  [OK] Task disabilitato: $task" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERR] Impossibile disabilitare $task : $_" -ForegroundColor Red
        }
    }
}

function Uninstall-WindowsFeatures {
    $features = @(
        "Microsoft.BingWeather",
        "Microsoft.GetHelp",
        "Microsoft.Getstarted",
        "Microsoft.HelpAndTips",
        "Microsoft.Media.PlayReadyClient.2",
        "Microsoft.MicrosoftSolitaireCollection",
        "Microsoft.MicrosoftStickyNotes",
        "Microsoft.OneConnect",
        "Microsoft.OneSync",
        "Microsoft.SkypeApp",
        "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera",
        "Microsoft.WindowsFeedbackHub",
        "Microsoft.WindowsMaps",
        "Microsoft.WindowsSoundRecorder",
        "Microsoft.WindowsStore",
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo",
        "Microsoft.OneDrive"
    )
    
    Write-Host "`nDisinstallazione funzionalità Windows non necessarie..."
    foreach ($feature in $features) {
        try {
            Get-WindowsCapability -Online -Name "*$feature*" | Remove-WindowsCapability -Online -ErrorAction Stop
            Write-Host "  [OK] Funzionalità rimossa: $feature" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERR] Impossibile rimuovere $feature : $_" -ForegroundColor Red
        }
    }
}

function Remove-PreInstalledBloatware {
    $apps = @(
        [PSCustomObject]@{ Name = "OneDrive"; Pattern = "*OneDrive*"; Critical = $true }
        [PSCustomObject]@{ Name = "Microsoft Teams"; Pattern = "*Teams*"; Critical = $true }
        [PSCustomObject]@{ Name = "Xbox e servizi gaming"; Pattern = "*Xbox*"; Critical = $false }
        [PSCustomObject]@{ Name = "App di notizie e meteo"; Pattern = "*BingNews*;*BingWeather*"; Critical = $false }
        [PSCustomObject]@{ Name = "App di feedback e assistenza"; Pattern = "*FeedbackHub*;*GetHelp*;*Getstarted*"; Critical = $false }
        [PSCustomObject]@{ Name = "Your Phone"; Pattern = "*YourPhone*"; Critical = $false }
        [PSCustomObject]@{ Name = "App di produttività"; Pattern = "*Todos*;*StickyNotes*;*Whiteboard*"; Critical = $false }
        [PSCustomObject]@{ Name = "Media Player"; Pattern = "*ZuneMusic*;*ZuneVideo*"; Critical = $false }
        [PSCustomObject]@{ Name = "Cortana e servizi vocali"; Pattern = "*Cortana*;*549981C3F5F10*"; Critical = $true }
        [PSCustomObject]@{ Name = "TUTTE le app preinstallate"; Pattern = "FULL_REMOVE"; Critical = $true }
    )

    $selectedApps = @()
    Write-Host "`nSelezione app da rimuovere:"
    foreach ($app in $apps) {
        $choice = Read-Host "Vuoi rimuovere $($app.Name)? (s/n)"
        if ($choice -eq 's') {
            $selectedApps += $app
        }
    }

    if (-not $selectedApps) {
        Write-Host "`nNessuna app selezionata per la rimozione." -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nRimozione forzata app selezionate..."
    
    # Gestione OneDrive speciale
    if ($selectedApps.Name -contains "OneDrive") {
        Write-Host "`nDisinstallazione forzata OneDrive..." -ForegroundColor Cyan
        try {
            # Kill OneDrive process
            Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
            
            # Uninstall OneDrive
            if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
                & "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall
            } elseif (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") {
                & "$env:SystemRoot\System32\OneDriveSetup.exe" /uninstall
            }
            
            # Cleanup
            Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:PROGRAMDATA\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            
            # Remove from startup
            Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue
            
            Write-Host "  [OK] OneDrive rimosso completamente" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERR] Disinstallazione OneDrive fallita: $_" -ForegroundColor Red
        }
    }
    
    # Gestione disinstallazione di massa
    $fullRemove = $selectedApps.Name -contains "TUTTE le app preinstallate"
    
    foreach ($app in $selectedApps) {
        if ($app.Name -in @("OneDrive", "TUTTE le app preinstallate")) { continue }
        
        Write-Host "`nDisinstallazione: $($app.Name)..." -ForegroundColor Cyan
        
        if ($app.Pattern -eq "FULL_REMOVE") {
            try {
                Get-AppxPackage -AllUsers | Remove-AppxPackage -ErrorAction Stop
                Get-AppxProvisionedPackage -Online | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
                Write-Host "  [OK] Tutte le app rimosse" -ForegroundColor Green
            }
            catch {
                Write-Host "  [ERR] Rimozione completa fallita: $_" -ForegroundColor Red
            }
        }
        else {
            $patterns = $app.Pattern -split ';'
            foreach ($pattern in $patterns) {
                try {
                    # Remove for current and all users
                    Get-AppxPackage -Name $pattern | Remove-AppxPackage -ErrorAction Stop
                    
                    # Remove provisioned packages
                    Get-AppxProvisionedPackage -Online | 
                        Where-Object DisplayName -Like $pattern | 
                        Remove-AppxProvisionedPackage -Online -ErrorAction Stop
                    
                    Write-Host "  [OK] App rimosse: $pattern" -ForegroundColor Green
                }
                catch {
                    Write-Host "  [ERR] Impossibile rimuovere $pattern : $_" -ForegroundColor Red
                }
            }
            
            # Pulizia aggiuntiva per app specifiche
            switch ($app.Name) {
                "Microsoft Teams" {
                    try {
                        Get-Process -Name Teams -ErrorAction SilentlyContinue | Stop-Process -Force
                        Remove-Item -Path "$env:APPDATA\Microsoft\Teams" -Recurse -Force
                        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Teams" -Recurse -Force
                        Write-Host "  [OK] Cache Teams pulita" -ForegroundColor Green
                    }
                    catch { }
                }
                "Xbox e servizi gaming" {
                    try {
                        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
                        Set-Service -Name XblAuthManager -StartupType Disabled
                        Set-Service -Name XboxNetApiSvc -StartupType Disabled
                        Stop-Service -Name XblAuthManager -Force
                        Stop-Service -Name XboxNetApiSvc -Force
                        Write-Host "  [OK] Servizi Xbox disabilitati" -ForegroundColor Green
                    }
                    catch { }
                }
            }
        }
    }
}

function Disable-WindowsStoreAutoUpdate {
    Write-Host "`nDisabilitazione aggiornamenti automatici Microsoft Store..."
    $WindowsStoreAutoUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
    
    try {
        if (-not (Test-Path $WindowsStoreAutoUpdate)) {
            New-Item -Path $WindowsStoreAutoUpdate -Force | Out-Null
        }
        
        Set-ItemProperty -Path $WindowsStoreAutoUpdate -Name "AutoDownload" -Value 2
        Set-ItemProperty -Path $WindowsStoreAutoUpdate -Name "DisableOSUpgrade" -Value 1
        Write-Host "  [OK] Aggiornamenti automatici disabilitati" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERR] Impossibile disabilitare: $_" -ForegroundColor Red
    }
}

function Disable-Telemetry {
    Write-Host "`nDisabilitazione telemetria..."
    $TelemetrySettings = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    
    try {
        if (-not (Test-Path $TelemetrySettings)) {
            New-Item -Path $TelemetrySettings -Force | Out-Null
        }
        
        Set-ItemProperty -Path $TelemetrySettings -Name "AllowTelemetry" -Value 0
        Write-Host "  [OK] Telemetria disabilitata" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERR] Impossibile disabilitare: $_" -ForegroundColor Red
    }
}

function Disable-SyncSettings {
    Write-Host "`nDisabilitazione sincronizzazione impostazioni..."
    $SyncSettings = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"
    
    try {
        if (-not (Test-Path $SyncSettings)) {
            New-Item -Path $SyncSettings -Force | Out-Null
        }
        
        Set-ItemProperty -Path $SyncSettings -Name "DisableSettingSync" -Value 2
        Set-ItemProperty -Path $SyncSettings -Name "DisableSettingSyncUserOverride" -Value 1
        Write-Host "  [OK] Sincronizzazione disabilitata" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERR] Impossibile disabilitare: $_" -ForegroundColor Red
    }
}

function Disable-BackgroundAppAccess {
    Write-Host "`nDisabilitazione app in background..."
    $BackgroundApps = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    
    try {
        if (-not (Test-Path $BackgroundApps)) {
            New-Item -Path $BackgroundApps -Force | Out-Null
        }
        
        Get-ChildItem -Path $BackgroundApps | ForEach-Object {
            Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Value 1
            Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Value 1
        }
        Write-Host "  [OK] App in background disabilitate" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERR] Impossibile disabilitare: $_" -ForegroundColor Red
    }
}

function Disable-UnnecessaryServices {
    $services = @(
        "diagnosticshub.standardcollector.service",
        "DiagTrack",
        "dmwappushservice",
        "SysMain",
        "wificx",
        "wifinudmgr"
    )
    
    Write-Host "`nDisabilitazione servizi non necessari..."
    foreach ($service in $services) {
        try {
            Set-Service -Name $service -StartupType Disabled -Status Stopped -ErrorAction Stop
            Write-Host "  [OK] Servizio disabilitato: $service" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERR] Impossibile disabilitare $service : $_" -ForegroundColor Red
        }
    }
}

function Enable-HyperVServices {
    $HyperVServices = @(
        "vmicheartbeat",
        "vmicguestinterface",
        "vmicshutdown",
        "vmicvmsession",
        "vmicrdv",
        "vmictimesync"
    )
    
    Write-Host "`nAbilitazione servizi Hyper-V..."
    foreach ($service in $HyperVServices) {
        try {
            Set-Service -Name $service -StartupType Automatic -Status Running -ErrorAction Stop
            Write-Host "  [OK] Servizio abilitato: $service" -ForegroundColor Green
        }
        catch {
            Write-Host "  [ERR] Impossibile abilitare $service : $_" -ForegroundColor Red
        }
    }
}

function Set-ExecutionPolicyRemoteSigned {
    Write-Host "`nImpostazione criteri di esecuzione..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "  [OK] Criteri impostati a RemoteSigned" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERR] Impossibile impostare criteri: $_" -ForegroundColor Red
    }
}

# ================================================
# ESECUZIONE PRINCIPALE
# ================================================

# Verifica privilegi amministrativi
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Richiesta privilegi amministrativi..."
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Definizione azioni disponibili
$actions = @(
    [PSCustomObject]@{ ID=1; Name="Disable unnecessary scheduled tasks"; Function={Disable-UnnecessaryScheduledTasks}; Sensitive=$false }
    [PSCustomObject]@{ ID=2; Name="Uninstall Windows features"; Function={Uninstall-WindowsFeatures}; Sensitive=$true }
    [PSCustomObject]@{ ID=3; Name="Remove pre-installed bloatware"; Function={Remove-PreInstalledBloatware}; Sensitive=$true }
    [PSCustomObject]@{ ID=4; Name="Disable Windows Store Auto Update"; Function={Disable-WindowsStoreAutoUpdate}; Sensitive=$false }
    [PSCustomObject]@{ ID=5; Name="Disable Telemetry"; Function={Disable-Telemetry}; Sensitive=$false }
    [PSCustomObject]@{ ID=6; Name="Disable Sync settings with Microsoft account"; Function={Disable-SyncSettings}; Sensitive=$false }
    [PSCustomObject]@{ ID=7; Name="Disable Background app access"; Function={Disable-BackgroundAppAccess}; Sensitive=$false }
    [PSCustomObject]@{ ID=8; Name="Disable unnecessary services"; Function={Disable-UnnecessaryServices}; Sensitive=$true }
    [PSCustomObject]@{ ID=9; Name="Enable Hyper-V services (optional)"; Function={Enable-HyperVServices}; Sensitive=$true }
    [PSCustomObject]@{ ID=10; Name="Set execution policy to RemoteSigned"; Function={Set-ExecutionPolicyRemoteSigned}; Sensitive=$false }
)

# Menu principale
Write-Host "==============================================="
Write-Host "          DEBLOAT WINDOWS - MENU PRINCIPALE    "
Write-Host "==============================================="
Write-Host "1. Esecuzione guidata (seleziona azioni)"
Write-Host "2. Esecuzione completa (tutte le azioni)"
Write-Host "3. Personalizza disinstallazione app"
Write-Host "4. Esci"
Write-Host "==============================================="

$choice = Read-Host "Scelta [1-4]"
switch ($choice) {
    "1" {
        # Modalità guidata: selezione singole azioni
        $selectedActions = @()
        foreach ($action in $actions) {
            $choiceAction = Read-Host "Vuoi eseguire $($action.Name)? (s/n)"
            if ($choiceAction -eq 's') {
                $selectedActions += $action
            }
        }
    }
    "2" {
        # Modalità completa: tutte le azioni
        $selectedActions = $actions
    }
    "3" {
        # Solo rimozione app
        Remove-PreInstalledBloatware
        exit
    }
    "4" { exit }
    default { exit }
}

if (-not $selectedActions) {
    Write-Host "`nOperazione annullata. Nessuna azione selezionata." -ForegroundColor Yellow
    exit
}

# Esecuzione azioni selezionate
foreach ($action in $selectedActions) {
    # Richiesta conferma per azioni sensibili in modalità completa
    if ($choice -eq "2" -and $action.Sensitive) {
        $confirmation = Read-Host "`nAttenzione: $($action.Name). Continuare? (s/n)"
        if ($confirmation -ne 's') {
            Write-Host "`nSaltata azione: $($action.Name)" -ForegroundColor Yellow
            continue
        }
    }
    
    Write-Host "`nEsecuzione: $($action.Name)..." -ForegroundColor Cyan
    & $action.Function
}

# Riavvio consigliato
Write-Host "`n==============================================="
Write-Host "          OPERAZIONI COMPLETATE CON SUCCESSO     "
Write-Host "==============================================="
Write-Host "Alcune modifiche richiedono il riavvio del sistema"
$choice = Read-Host "Riavviare ora? (s/n)"
if ($choice -eq "s") {
    Write-Host "Riavvio in corso..."
    Start-Process "shutdown.exe" -ArgumentList "/r /t 5 /c ""Riavvio post-ottimizzazione"""
}