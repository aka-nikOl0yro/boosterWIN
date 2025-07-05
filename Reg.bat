@echo off
net session >nul 2>&1 
if %errorLevel% == 0 ( 
 if exist "REG" (
 echo Hai già eseguito questo programma. Per uscire chiudi il cmd.
 echo Premi un qualunque tasto per proseguire comunque.....................
 pause > nul
 goto Start
 ) else (
 type nul>REG
 attrib +H REG 
 )
   echo *** OTTIMIZZAZIONE WINDOWS IN CORSO *** 
) else ( 
   echo Attenzione: eseguire lo script con i diritti di amministratore
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
echo Requesting administrative privileges...
goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

pushd "%~dp0"
pause
)

:Start
echo Attivazione Ripristino configurazione sistema
powershell Enable-ComputerRestore -drive C:\ > nul
vssadmin resize shadowstorage /on=c: /for=c: /maxsize=10%% > nul

echo Creazione punto di ripristino
powershell Checkpoint-Computer "Preottimizzazione"

choice /C YN /M "Disattivazione Windows Update automatico" /t 30 /d Y
if %errorlevel% equ 1 (
echo Disattivazione Windows Update automatico
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoRebootWithLoggedOnUsers /t REG_DWORD /d 1 /f > nul
)
echo Disattivazione telemetria
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" /v AllowBuildPreview /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" /v NoGenTicket /t REG_DWORD /d 1 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f > nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" /v AllowLinguisticDataCollection /t REG_DWORD /d 0 /f > nul
schtasks /change /TN "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" /DISABLE > nul
schtasks /change /TN "\Microsoft\Windows\Application Experience\ProgramDataUpdater" /DISABLE > nul
schtasks /change /TN "\Microsoft\Windows\Autochk\Proxy" /DISABLE > nul
schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator" /DISABLE > nul
schtasks /change /TN "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" /DISABLE > nul
schtasks /change /TN "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" /DISABLE > nul

choice /C YN /M "Disattivazione Bing Search nel menu Start" /t 30 /d Y
if %errorlevel% equ 1 (
echo Disattivazione Bing Search nel menu Start
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f > nul
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f > nul
)
echo Disattivazione Highlights di ricerca menu Start
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v EnableDynamicContentInWSB /t REG_DWORD /d 0 /f > nul

choice /C YN /M "Disattivazione delle app suggerite" /t 30 /d Y
if %errorlevel% equ 1 (
echo Disattivazione delle app suggerite
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v PreInstalledAppsEverEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-314559Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableThirdPartySuggestions /t REG_DWORD /d 1 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v RotatingLockScreenOverlayEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SoftLandingEnabled /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v DisableThirdPartySuggestions /t REG_DWORD /d 1 /f > nul
reg add "HKCU\Software\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiencesWithDiagnosticData /t REG_DWORD /d 1 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f > nul
)
echo Disattivazione schermata Completiamo la configurazione del tuo dispositivo
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" /v ScoobeSystemSettingEnabled /t REG_DWORD /d 0 /f > nul

echo Disattivazione Connected User Experiences and Telemetry Service
powershell set-service -Name DiagTrack -StartupType Disabled > nul
powershell stop-service -Name DiagTrack > nul
 
echo Attivazione visualizzazione estensioni file conosciuti
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f > nul

choice /C YN /M "Ripristino menu contestuale classico" /t 30 /d Y
if %errorlevel% equ 1 (
echo Ripristino menu contestuale classico
reg add "HKCU\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /f > nul
)

choice /C YN /M "Attivazione interfaccia ribbon classica in Esplora file" /t 30 /d Y
if %errorlevel% equ 1 (
echo Attivazione interfaccia ribbon classica in Esplora file
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" /v {e2bf9676-5f8f-435c-97eb-11607a5bedf7} /f > nul
)
echo Visualizzazione icone desktop
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0 /f > nul

echo Aprire Questo PC quando si avvia Esplora file
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v LaunchTo /t REG_DWORD /d 1 /f > nul

echo Rimozione icona Microsoft Teams e Chat
reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v com.squirrel.Teams.Teams /f > nul
reg delete HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run /v TeamsMachineInstaller /f > nul
reg add "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\SystemAppData\MicrosoftTeams_8wekyb3d8bbwe\TeamsStartupTask" /v State /t REG_DWORD /d 1 /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f > nul

echo Attivazione cronologia appunti per utente corrente
reg add HKCU\Software\Microsoft\Clipboard /v EnableClipboardHistory /t REG_DWORD /d 1 /f > nul

echo Attivazione sincronizzazione manuale appunti per utente corrente
reg add HKCU\Software\Microsoft\Clipboard /v CloudClipboardAutomaticUpload /t REG_DWORD /d 0 /f > nul
reg add HKCU\Software\Microsoft\Clipboard /v EnableCloudClipboard /t REG_DWORD /d 1 /f > nul

echo Disattivazione le domande di sicurezza alla creazione di nuovi account utente locali
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\System /v NoLocalPasswordResetQuestions /t REG_DWORD /d 1 /f > nul

echo Disattivazione Widget
reg add HKLM\SOFTWARE\Policies\Microsoft\Dsh /v AllowNewsAndInterests /t REG_DWORD /d 0 /f > nul

choice /C YN /M "Disattivazione sfocatura schermata di blocco" /t 30 /d Y
if %errorlevel% equ 1 (
echo Disattivazione sfocatura schermata di blocco (effetto acrilico)
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\System /v DisableAcrylicBackgroundOnLogon /t REG_DWORD /d 1 /f > nul
)
echo Mostra un numero maggiore di elementi ancorati nel menu Start
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v Start_Layout /t REG_DWORD /d 1 /f > nul

echo Mostra le app piu' usate nel menu Start
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer /v ShowOrHideMostUsedApps /t REG_DWORD /d 1 /f > nul

echo Disattivazione messaggio Requisiti di sistema non supportati per i PC che non sono compatibili con Windows 11
reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV1 /t REG_DWORD /d 0 /f > nul
reg add "HKCU\Control Panel\UnsupportedHardwareNotificationCache" /v SV2 /t REG_DWORD /d 0 /f > nul

REM inizio ottimizzazione reg
echo Turn Off Game Mode.
reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\Software\Microsoft\GameBar" /v "AutoGameModeEnabled" /t REG_DWORD /d 0 /f
echo Disables Fullscreen Optimizations, GameDVR and GameBar which is known to cause stutter and low FPS in games. Also fixes most game crashes.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" /v "value" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_SZ /d "0" /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_FSEBehavior" /t REG_DWORD /d 2 /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t REG_DWORD /d 2 /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f
rem echo Unlocks the ability to modify sleeping CPU cores to improve performance and decrease stutter in games.
rem reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\943c8cb6-6f93-4227-ad87-e9a3feec08d1" /v "Attributes" /t REG_DWORD /d 2 /f
echo Improves system responsiveness and network speed.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NetworkThrottlingIndex" /t REG_DWORD /d 4294967295 /f
echo Marginally improves GPU performance and provides more power to games.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_SZ /d "8" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_SZ /d "2" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f
echo Maintenance Disabled.
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v "MaintenanceDisabled" /t REG_DWORD /d "00000001" /f
rem echo Make sure your cores are unparked in regedit.
rem reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v "ValueMax" /t REG_SZ /d "0" /f
rem reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028" /v "ValueMax" /t REG_SZ /d "0" /f
rem reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334029" /v "ValueMax" /t REG_SZ /d "0" /f
rem reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Power\PowerSettings\0012ee47-9041-4b5d-9b77-535fba8b1442\51dea550-bb38-4bc4-991b-eacf37be5ec8" /v "ValueMax" /t REG_SZ /d "0" /f
echo Adds the "Copy To..." "Move To..." ability from Windows 7, when you right click files or folders, for easier file management.
reg add "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" /v "" /t REG_SZ /d "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" /f
reg add "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" /v "" /t REG_SZ /d "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" /f
echo Slightly improves RAM management and overall system speed.
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "AutoEndTasks" /t REG_SZ /d "1" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "1000" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "8" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "2000" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "HungAppTimeout" /t REG_SZ /d "100" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "MenuShowDelay" /t REG_SZ /d "0" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t REG_SZ /d "300" /f
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t REG_SZ /d "1000" /f
echo Speeds up Shut Down time.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "2000" /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t REG_SZ /d "300" /f
echo Resolves a memory leak in windows 10 through Registry.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Ndu" /v "Start" /t REG_DWORD /d 4 /f
echo Split Threshold for Svhost.
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v "SvcHostSplitThresholdInKB" /t REG_DWORD /d 819200 /f
echo Turn off LargeSystemCache
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f

reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v accesssolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v olksolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v onenotesolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v pptsolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v projectsolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v publishersolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v visiosolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v wdsolution /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedapplications" /v xlsolution /t REG_DWORD /d 1 /f
echo DisableOfficeTelemetry
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" /v agave /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" /v appaddins /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" /v comaddins /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" /v documentfiles /t REG_DWORD /d 1 /f
reg add "HKEY_CURRENT_USER\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" /v templatefiles /t REG_DWORD /d 1 /f
echo Disable Cortana
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t "REG_DWORD" /d "00000000" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "BingSearchEnabled" /t "REG_DWORD" /d "00000000" /f > nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "CortanaConsent" /t "REG_DWORD" /d "00000000" /f > nul
echo Disable Xbox Live
reg add "HKLM\SYSTEM\CurrentControlSet\Services\XboxNetApiSvc" /v "Start" /t "REG_DWORD" /d "00000004" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\XblAuthManager" /v "Start" /t "REG_DWORD" /d "00000004" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\XblGameSave" /v "Start" /t "REG_DWORD" /d "00000004" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\XboxGipSvc" /v "Start" /t "REG_DWORD" /d "00000004" /f > nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\xbgm" /v "Start" /t "REG_DWORD" /d "00000004" /f > nul
echo [*] Disattivazione degli effetti visivi in corso...

:: Disattiva trasparenze (Fluent/Acrylic)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f

:: Disattiva Aero Peek e Blur
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableBlurBehind /t REG_DWORD /d 0 /f

:: Disattiva animazioni (menu, tooltip, finestra)
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f

:: Mantieni font smoothing attivo
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f

:: Mantieni DragFullWindows attivo
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f
REM echo Disable mitigations
REM reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettings" /t "REG_DWORD" /d "00000000" /f > nul
REM reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t "REG_DWORD" /d "00000003" /f > nul
REM reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t "REG_DWORD" /d "00000003" /f > nul
REM echo Add_Install to cab_context_menu
REM reg delete "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs" /f > nul
REM reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "DisableTsx" /t "REG_DWORD" /d "00000001" /f > nul
REM reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\MinVmVersionForCpuBasedMitigations" /f > nul
rem echo Disable Power Throttling
rem reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v "PowerThrottlingOff" /t "REG_DWORD" /d "00000001" /f > nul
echo Zero Startup Delay
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t "REG_DWORD" /d "00000000" /f > nul
echo disable Windows App tracking to improve Start and Search Results
reg add "HKEY_CURRENT_USER\Software\Policies\Microsoft\Windows\EdgeUI" /v "DisableMFUTracking" /t REG_DWORD /d 00000001 /f

choice /C YN /M "make the taskbar clock show seconds" /t 30 /d Y
if %errorlevel% equ 1 (
echo This will make the taskbar clock show seconds
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSecondsInSystemClock" /t REG_DWORD /d 00000001 /f
)
echo Disable Windows Error Reporting
reg add "HKEY_CURRENT_USER\Software\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 00000001 /f
echo Disables app suggestions on start
reg add "HKEY_CLASSES_ROOT\CABFolder\Shell\RunAs\Command" /v "@" /t REG_SZ /d "cmd /k dism /online /add-package /packagepath:"%1"" /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 00000001 /f

echo Done.

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\kbdhid\Parameters" /v CrashOnCtrlScroll /t REG_DWORD /d 1 /f
echo :)

rem Disabilita il servizio di telemetria di Windows
sc config DiagTrack start= demand

rem Disabilita il servizio di raccolta dati di Windows
sc config dmwappushservice start= demand

rem Disabilita il servizio di raccolta dati di Microsoft
sc config WerSvc start= demand

choice /C YN /M "Disabilita il servizio di stampa" /t 30 /d Y
if %errorlevel% equ 1 (
rem Disabilita il servizio di stampa
sc config spooler start= demand
)

rem Disabilita il servizio di assistenza remota
sc config RemoteRegistry start= demand

rem Disabilita il servizio di backup
sc config bthserv start= demand

rem Disabilita il servizio di Windows Media Player
sc config WMPNetworkSvc start= demand

rem Disabilita il servizio di sincronizzazione
sc config wuauserv start= demand

PowerShell -Command "Get-AppxPackage -Name Microsoft.549981C3F5F10_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.BingNews_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.BingWeather_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.GetHelp_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.Getstarted_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.OneDriveSync_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.OutlookForWindows_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.People_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.Todos_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.WindowsMaps_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.XboxGameOverlay_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.XboxGamingOverlay_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.YourPhone_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name MicrosoftCorporationII.MicrosoftFamily_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name MicrosoftTeams_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name Microsoft.OneDrive -AllUsers | Remove-AppxPackage"
PowerShell -Command "Get-AppxPackage -Name microsoft.windowscommunicationsapps_8wekyb3d8bbwe -AllUsers | Remove-AppxPackage"
echo Disinstallazione completata



echo Remove Default Apps
powershell.exe -executionpolicy bypass -nologo -noninteractive -file "./src/debloat.ps1"
rem Disabilita il servizio di cloud
sc config wlidsvc start= demand
irm christitus.com/win | iex
echo Disabilitazione dei servizi non importanti completata.
start .\CCleaner.bat
echo riavviare il sistema ...
timeout 7 > nul
echo Riavvio finale in 2 minuti...
shutdown /r /t 120