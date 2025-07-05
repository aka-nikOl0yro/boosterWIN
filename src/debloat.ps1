param(
    [switch]$AutoRun,
    [switch]$SelectAll
)

# ================================================
# FUNZIONE MENU INTERATTIVO
# ================================================
function Show-DebloatMenu {
    $options = @(
        [PSCustomObject]@{ 
            Name = "Disable unnecessary scheduled tasks"; 
            Selected = $false; 
            ID = 1 
        },
        [PSCustomObject]@{ 
            Name = "Uninstall Windows features"; 
            Selected = $false; 
            ID = 2 
        },
        [PSCustomObject]@{ 
            Name = "Remove pre-installed bloatware"; 
            Selected = $false; 
            ID = 3 
        },
        [PSCustomObject]@{ 
            Name = "Disable Windows Store Auto Update"; 
            Selected = $false; 
            ID = 4 
        },
        [PSCustomObject]@{ 
            Name = "Disable Telemetry"; 
            Selected = $false; 
            ID = 5 
        },
        [PSCustomObject]@{ 
            Name = "Disable Sync settings with Microsoft account"; 
            Selected = $false; 
            ID = 6 
        },
        [PSCustomObject]@{ 
            Name = "Disable Background app access"; 
            Selected = $false; 
            ID = 7 
        },
        [PSCustomObject]@{ 
            Name = "Disable unnecessary services"; 
            Selected = $false; 
            ID = 8 
        },
        [PSCustomObject]@{ 
            Name = "Enable Hyper-V services (optional)"; 
            Selected = $false; 
            ID = 9 
        },
        [PSCustomObject]@{ 
            Name = "Set execution policy to RemoteSigned"; 
            Selected = $false; 
            ID = 10 
        }
    )

    # Selezione automatica se richiesta
    if ($SelectAll) {
        $options | ForEach-Object { $_.Selected = $true }
        return $options
    }

    # Menu interattivo
    $selectedItems = @()
    $cursorPosition = 0
    $exitKey = [ConsoleKey]::Enter

    while ($true) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "        DEBLOAT WINDOWS - SELEZIONE AZIONI      "
        Write-Host "==============================================="
        Write-Host "Spazio: Seleziona/Deseleziona   Invio: Conferma"
        Write-Host "Esc: Annulla tutto              A: Seleziona Tutto"
        Write-Host "===============================================`n"
        
        for ($i = 0; $i -lt $options.Count; $i++) {
            $prefix = if ($i -eq $cursorPosition) { ">> " } else { "   " }
            $checkbox = if ($options[$i].Selected) { "[X] " } else { "[ ] " }
            Write-Host ("$prefix$checkbox$($options[$i].Name)")
        }

        $key = [Console]::ReadKey($true).Key

        switch ($key) {
            UpArrow { if ($cursorPosition -gt 0) { $cursorPosition-- } }
            DownArrow { if ($cursorPosition -lt ($options.Count - 1)) { $cursorPosition++ } }
            Spacebar {
                $options[$cursorPosition].Selected = -not $options[$cursorPosition].Selected
            }
            A { $options | ForEach-Object { $_.Selected = $true } }
            Escape { return @() }
            Enter { 
                return $options | Where-Object { $_.Selected } 
            }
        }
    }
}

# ================================================
# FUNZIONE SELEZIONE APP DA DISINSTALLARE
# ================================================
function Select-AppsToRemove {
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
    $cursorPosition = 0
    $exitKey = [ConsoleKey]::Enter

    while ($true) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "     SELEZIONE APP DA DISINSTALLARE FORZATAMENTE"
        Write-Host "==============================================="
        Write-Host "Spazio: Seleziona/Deseleziona   Invio: Conferma"
        Write-Host "Esc: Annulla                     A: Seleziona Tutto"
        Write-Host "===============================================`n"
        
        for ($i = 0; $i -lt $apps.Count; $i++) {
            $prefix = if ($i -eq $cursorPosition) { ">> " } else { "   " }
            $checkbox = if ($apps[$i].Selected) { "[X] " } else { "[ ] " }
            $critical = if ($apps[$i].Critical) { "(FORZATA) " } else { "" }
            Write-Host ("$prefix$checkbox$critical$($apps[$i].Name)")
        }

        $key = [Console]::ReadKey($true).Key

        switch ($key) {
            UpArrow { if ($cursorPosition -gt 0) { $cursorPosition-- } }
            DownArrow { if ($cursorPosition -lt ($apps.Count - 1)) { $cursorPosition++ } }
            Spacebar {
                $apps[$cursorPosition].Selected = -not $apps[$cursorPosition].Selected
            }
            A { $apps | ForEach-Object { $_.Selected = $true } }
            Escape { return @() }
            Enter { 
                return $apps | Where-Object { $_.Selected } 
            }
        }
    }
}

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
    $selectedApps = Select-AppsToRemove
    
    if (-not $selectedApps) {
        Write-Host "`nOperazione annullata. Nessuna app selezionata." -ForegroundColor Yellow
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

# Menu principale
if (-not $AutoRun) {
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
        "1" { $selectedActions = Show-DebloatMenu }
        "2" { $selectedActions = Show-DebloatMenu -SelectAll }
        "3" { Remove-PreInstalledBloatware; exit }
        "4" { exit }
        default { exit }
    }
}
else {
    $selectedActions = Show-DebloatMenu -SelectAll
}

if (-not $selectedActions) {
    Write-Host "`nOperazione annullata. Nessuna azione selezionata." -ForegroundColor Yellow
    exit
}

# Esecuzione azioni selezionate
foreach ($action in $selectedActions) {
    switch ($action.ID) {
        1 { Disable-UnnecessaryScheduledTasks }
        2 { Uninstall-WindowsFeatures }
        3 { Remove-PreInstalledBloatware }
        4 { Disable-WindowsStoreAutoUpdate }
        5 { Disable-Telemetry }
        6 { Disable-SyncSettings }
        7 { Disable-BackgroundAppAccess }
        8 { Disable-UnnecessaryServices }
        9 { Enable-HyperVServices }
        10 { Set-ExecutionPolicyRemoteSigned }
    }
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