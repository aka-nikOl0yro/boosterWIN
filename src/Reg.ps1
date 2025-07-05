# Reg.ps1 - Ottimizzazione avanzata del registro di sistema

# Verifica privilegi amministrativi
function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Blocco esecuzioni multiple
$lockFile = Join-Path $PSScriptRoot "REG.lock"
if (Test-Path $lockFile) {
    Write-Host "Hai già eseguito questo programma. Per uscire chiudi la finestra." -ForegroundColor Yellow
    Write-Host "Premi un tasto per proseguire comunque..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    New-Item -Path $lockFile -ItemType File -Force | Out-Null
    (Get-Item $lockFile).Attributes += "Hidden"
}

# Attivazione Ripristino configurazione sistema
Write-Host "Attivazione Ripristino configurazione sistema..." -ForegroundColor Cyan
Enable-ComputerRestore -Drive "C:\" | Out-Null
vssadmin resize shadowstorage /on=c: /for=c: /maxsize=10% | Out-Null

# Creazione punto di ripristino
Write-Host "Creazione punto di ripristino..." -ForegroundColor Cyan
Checkpoint-Computer -Description "Preottimizzazione" | Out-Null

# Funzione per operazioni sul registro
function Set-RegistryValue($path, $name, $value, $type = "DWORD") {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name $name -Value $value -Type $type -Force
}

# Funzione per scelte utente
function Get-UserChoice($message, $choices = @('S','N'), $default = 'N') {
    $choice = $Host.UI.PromptForChoice("", $message, $choices, [int][array]::IndexOf($choices, $default))
    return $choice -eq 0  # Restituisce $true per la prima scelta
}

# ============= INIZIO OTTIMIZZAZIONI =============

# Disattivazione Windows Update automatico
if (Get-UserChoice -message "Disattivazione Windows Update automatico [S]i/[N]o" -default 'S') {
    Write-Host "Disattivazione Windows Update automatico..." -ForegroundColor Cyan
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoUpdate" 0
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "AUOptions" 2
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1
}

# Disattivazione telemetria
Write-Host "Disattivazione telemetria..." -ForegroundColor Cyan
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" "AllowBuildPreview" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" "NoGenTicket" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 0
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" "PreventHandwritingDataSharing" 1
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" "AllowLinguisticDataCollection" 0

# Disattivazione Bing Search
if (Get-UserChoice -message "Disattivazione Bing Search nel menu Start [S]i/[N]o" -default 'S') {
    Write-Host "Disattivazione Bing Search nel menu Start..." -ForegroundColor Cyan
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
    Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
}

# Disattivazione app suggerite
if (Get-UserChoice -message "Disattivazione delle app suggerite [S]i/[N]o" -default 'S') {
    Write-Host "Disattivazione delle app suggerite..." -ForegroundColor Cyan
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 0
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" 0
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" 0
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEverEnabled" 0
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
    Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" 1
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
    Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" 1
    Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" 1
    Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
}

# Altre ottimizzazioni
Write-Host "Altre ottimizzazioni in corso..." -ForegroundColor Cyan
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1
Set-RegistryValue "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1
Set-RegistryValue "HKCU:\Software\Microsoft\Clipboard" "CloudClipboardAutomaticUpload" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Clipboard" "EnableCloudClipboard" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "NoLocalPasswordResetQuestions" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_Layout" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "ShowOrHideMostUsedApps" 1
Set-RegistryValue "HKCU:\Control Panel\UnsupportedHardwareNotificationCache" "SV1" 0
Set-RegistryValue "HKCU:\Control Panel\UnsupportedHardwareNotificationCache" "SV2" 0

# Ottimizzazioni gaming
Write-Host "Applicazione ottimizzazioni gaming..." -ForegroundColor Cyan
Set-RegistryValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0
Set-RegistryValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" 0
Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" "0" "String"
Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
Set-RegistryValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" "AppCaptureEnabled" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" "8" "String"
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Priority" "2" "String"
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" "String"
Set-RegistryValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" 1

# Ottimizzazioni prestazioni
Write-Host "Ottimizzazioni prestazioni di sistema..." -ForegroundColor Cyan
Set-RegistryValue "HKCU:\Control Panel\Desktop" "AutoEndTasks" "1" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "HungAppTimeout" "1000" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "8" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" "2000" "String"
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" "2000" "String"
Set-RegistryValue "HKLM:\SYSTEM\ControlSet001\Services\Ndu" "Start" 4
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" 819200
Set-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0
Set-RegistryValue "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" "DisableMFUTracking" 1
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\Windows Error Reporting" "Disabled" 1
Set-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1

# Disattivazione effetti visivi
Write-Host "Disattivazione effetti visivi..." -ForegroundColor Cyan
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
Set-RegistryValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableBlurBehind" 0
Set-RegistryValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" "0" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask" "9012038010000000" "Binary"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "FontSmoothing" "2" "String"
Set-RegistryValue "HKCU:\Control Panel\Desktop" "DragFullWindows" "1" "String"

# Impostazioni avanzate
if (Get-UserChoice -message "Mostrare i secondi nell'orologio? [S]i/[N]o" -default 'S') {
    Set-RegistryValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSecondsInSystemClock" 1
}

# Disattivazione servizi non necessari
Write-Host "Disattivazione servizi non necessari..." -ForegroundColor Cyan
Set-Service -Name DiagTrack -StartupType Disabled
Stop-Service -Name DiagTrack -Force
Set-Service -Name dmwappushservice -StartupType Disabled
Set-Service -Name WerSvc -StartupType Disabled
Set-Service -Name RemoteRegistry -StartupType Disabled
Set-Service -Name bthserv -StartupType Disabled
Set-Service -Name WMPNetworkSvc -StartupType Disabled
Set-Service -Name wuauserv -StartupType Disabled

if (Get-UserChoice -message "Disattivare il servizio di stampa? [S]i/[N]o" -default 'S') {
    Set-Service -Name spooler -StartupType Disabled
}

# Rimozione app preinstallate
Write-Host "Rimozione app preinstallate..." -ForegroundColor Cyan
$appsToRemove = @(
    "Microsoft.549981C3F5F10_8wekyb3d8bbwe",
    "Microsoft.BingNews_8wekyb3d8bbwe",
    "Microsoft.BingWeather_8wekyb3d8bbwe",
    "Microsoft.GetHelp_8wekyb3d8bbwe",
    "Microsoft.Getstarted_8wekyb3d8bbwe",
    "Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe",
    "Microsoft.OneDriveSync_8wekyb3d8bbwe",
    "Microsoft.OutlookForWindows_8wekyb3d8bbwe",
    "Microsoft.People_8wekyb3d8bbwe",
    "Microsoft.Todos_8wekyb3d8bbwe",
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",
    "Microsoft.WindowsMaps_8wekyb3d8bbwe",
    "Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe",
    "Microsoft.XboxGameOverlay_8wekyb3d8bbwe",
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",
    "Microsoft.YourPhone_8wekyb3d8bbwe",
    "MicrosoftCorporationII.MicrosoftFamily_8wekyb3d8bbwe",
    "MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe",
    "MicrosoftTeams_8wekyb3d8bbwe",
    "Microsoft.OneDrive",
    "microsoft.windowscommunicationsapps_8wekyb3d8bbwe"
)

foreach ($app in $appsToRemove) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
}

# Esecuzione script di debloat
Write-Host "Esecuzione script di debloat..." -ForegroundColor Cyan
$debloatScript = Join-Path $PSScriptRoot "src\debloat.ps1"
if (Test-Path $debloatScript) {
    & $debloatScript
} else {
    Write-Host "Script debloat.ps1 non trovato!" -ForegroundColor Red
}

# Esecuzione script esterno
Write-Host "Esecuzione script di ottimizzazione..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "https://christitus.com/win" | Invoke-Expression
} catch {
    Write-Host "Errore nell'esecuzione dello script esterno: $_" -ForegroundColor Red
}

# Esecuzione CCleaner
Write-Host "Avvio CCleaner..." -ForegroundColor Cyan
$ccleanerPath = Join-Path $PSScriptRoot "CCleaner.bat"
if (Test-Path $ccleanerPath) {
    Start-Process -FilePath $ccleanerPath -Wait
} else {
    Write-Host "File CCleaner.bat non trovato!" -ForegroundColor Red
}

# Pulizia finale
Write-Host "Ottimizzazione completata con successo!" -ForegroundColor Green
if (Test-Path $lockFile) {
    Remove-Item $lockFile -Force
}

# Riavvio del sistema
if (Get-UserChoice -message "Riavviare il sistema? [S]i/[N]o" -default 'N') {
    Write-Host "Riavvio in 120 secondi..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    Restart-Computer -Force
}