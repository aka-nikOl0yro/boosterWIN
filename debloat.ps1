#Disable unnecessary scheduled tasks
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
foreach ($task in $tasks) {
    try {
        Disable-ScheduledTask -TaskName $task -TaskPath '\Microsoft\Windows\'
        Write-Host "Scheduled task '$task' disabled."
    }
    catch {
        Write-Host "Scheduled task '$task' could not be disabled. Error: $_"
    }
}

#Uninstall Windows features
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
foreach ($feature in $features) {
    try {
        Uninstall-WindowsFeature -Name $feature -Remove
        Write-Host "Windows feature '$feature' uninstalled."
    }
    catch {
        Write-Host "Windows feature '$feature' could not be uninstalled. Error: $_"
    }
}

#Remove pre-installed bloatware
$apps = @(
    "BingWeather",
    "GetHelp",
    "Getstarted",
    "HelpAndTips",
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
foreach ($app in $apps) {
    try {
        Get-AppxPackage -Name $app | Remove-AppxPackage
        Write-Host "Bloatware '$app' removed."
    }
    catch {
        Write-Host "Bloatware '$app' could not be removed. Error: $_"
    }
}

#Disable Windows Store Auto Update
$WindowsStoreAutoUpdate = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
if (Test-Path $WindowsStoreAutoUpdate) {
    try {
        Set-ItemProperty -Path $WindowsStoreAutoUpdate -Name "AutoDownload" -Value "2"
        Set-ItemProperty -Path $WindowsStoreAutoUpdate -Name "DisableOSUpgrade" -Value "1"
        Write-Host "Disabled Windows Store Auto Update."
    }
    catch {
        Write-Host "Could not disable Windows Store Auto Update. Error: $_"
    }
}

#Disable Telemetry
$TelemetrySettings = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (Test-Path $TelemetrySettings) {
    try {
        Set-ItemProperty -Path $TelemetrySettings -Name "AllowTelemetry" -Value "0"
        Write-Host "Disabled Telemetry."
    }
    catch {
        Write-Host "Could not disable Telemetry. Error: $_"
    }
}

#Disable Sync settings with Microsoft account
$SyncSettings = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync"
if (Test-Path $SyncSettings) {
    try {
        Set-ItemProperty -Path $SyncSettings -Name "DisableSettingSync" -Value "2"
        Write-Host "Disabled Sync settings with Microsoft account."
    }
    catch {
        Write-Host "Could not disable Sync settings with Microsoft account. Error: $_"
    }
}

#Disable Background app access
$BackgroundApps = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (Test-Path $BackgroundApps) {
    try {
        Get-ChildItem -Path $BackgroundApps | ForEach-Object {
            Set-ItemProperty -Path $_.PsPath -Name "Disabled" -Value "1"
            Set-ItemProperty -Path $_.PsPath -Name "DisabledByUser" -Value "1"
        }
        Write-Host "Disabled Background app access."
    }
    catch {
        Write-Host "Could not disable Background app access. Error: $_"
    }
}

#Disable unnecessary services
$services = @(
    "diagnosticshub.standardcollector.service",
    "DiagTrack",
    "dmwappushservice",
    "SysMain",
    "wificx",
    "wifinudmgr",
    "OneDrive"
)
foreach ($service in $services) {
    try {
        Set-Service -Name $service -StartupType Disabled
        Stop-Service -Name $service
        Write-Host "Service '$service' disabled and stopped."
    }
    catch {
        Write-Host "Service '$service' could not be disabled and stopped. Error: $_"
    }
}

#Enable and start Hyper-V services
$HyperVServices = @(
    "vmicheartbeat",
    "vmicguestinterface",
    "vmicshutdown",
    "vmicvmsession",
    "vmicrdv",
    "vmictimesync"
)
foreach ($service in $HyperVServices) {
    try {
        Set-Service -Name $service -StartupType Automatic
        Start-Service -Name $service
        Write-Host "Service '$service' enabled and started."
    }
    catch {
        Write-Host "Service '$service' could not be enabled and started. Error: $_"
    }
}

#Set execution policy to RemoteSigned
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Write-Host "Set execution policy to RemoteSigned."
}
catch {
    Write-Host "Could not set execution policy to RemoteSigned. Error: $_"
}

#Set the wallpaper to 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'
try {
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -Value "C:\Windows\Web\Wallpaper\Windows\img0.jpg"
    Write-Host "Set the wallpaper to 'C:\Windows\Web\Wallpaper\Windows\img0.jpg'."
}
catch {
    Write-Host "Could not set the wallpaper. Error: $_"
}

#Restart the computer to apply changes
try {
    Restart-Computer -Force
    Write-Host "Restarting the computer..."
}
catch {
    Write-Host "Could not restart the computer. Error: $_"
    }
