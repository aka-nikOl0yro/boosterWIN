<#
.SYNOPSIS
    Debloat Windows - GUI v2.1
    Le app non installate appaiono in grigio e non sono selezionabili.
    Due sezioni separate: Bloatware comune e App potenzialmente utili.
.DESCRIPTION
    Eseguire con privilegi di amministratore.
#>

# ===================================================================
# === CONTROLLO AMMINISTRATORE ===
# ===================================================================
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERRORE: Esegui come Amministratore!"
    Start-Sleep -Seconds 3
    Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===================================================================
# === LISTE APP ===
# ===================================================================
$bloatwareApps = [ordered]@{
    "Microsoft.BingNews"                     = "Notizie Bing"
    "Microsoft.GetHelp"                      = "Assistenza"
    "Microsoft.Getstarted"                   = "Suggerimenti Windows"
    "Microsoft.MicrosoftSolitaireCollection" = "Solitario"
    "Microsoft.WindowsFeedbackHub"           = "Hub di Feedback"
    "Microsoft.WindowsMaps"                  = "Mappe"
    "Microsoft.ZuneMusic"                    = "Groove Musica"
    "Microsoft.ZuneVideo"                    = "Film e TV"
    "Microsoft.People"                       = "Persone"
    "Microsoft.549981C3F5F10"                = "Cortana"
    "Microsoft.BingWeather"                  = "Meteo Bing"
    "Microsoft.SkypeApp"                     = "Skype"
    "Microsoft.YourPhone"                    = "Collegamento al Telefono (Win10)"
    "MicrosoftCorporationII.YourPhone"        = "Collegamento al Telefono (Win11)"
    "MicrosoftCorporationII.MicrosoftFamily" = "Microsoft Family Safety"
    "Microsoft.Clipchamp"                    = "Clipchamp (Editor Video)"
}

$usefulApps = [ordered]@{
    "Microsoft.MicrosoftStickyNotes"      = "Sticky Notes"
    "Microsoft.WindowsAlarms"             = "Sveglie e Orologio"
    "Microsoft.WindowsCamera"             = "Fotocamera"
    "Microsoft.WindowsSoundRecorder"      = "Registratore Suoni"
    "Microsoft.Todos"                     = "Microsoft To Do"
    "Microsoft.OutlookForWindows"         = "Outlook"
    "MicrosoftTeams"                      = "Microsoft Teams (Appx/Win11)"
    "Microsoft.Teams"                     = "Microsoft Teams (Win32/Work)"
    "Microsoft.Teams.Free"                = "Microsoft Teams (Personale)"
    "Microsoft.WindowsCommunicationsApps" = "Posta e Calendario"
    "MicrosoftCorporationII.QuickAssist"  = "Assistenza Rapida"
    "Microsoft.Xbox.TCUI"                 = "Xbox TCUI"
    "Microsoft.XboxApp"                   = "Xbox App (Win10)"
    "Microsoft.GamingApp"                 = "Xbox App (Win11)"
    "Microsoft.XboxIdentityProvider"      = "Xbox Identity Provider"
    "Microsoft.XboxSpeechToTextOverlay"   = "Xbox Speech Overlay"
    "Microsoft.XboxGameOverlay"           = "Xbox Game Overlay"
    "Microsoft.XboxGamingOverlay"         = "Xbox Gaming Overlay (Game Bar)"
}

# ===================================================================
# === FUNZIONE RIMOZIONE APP ===
# ===================================================================
function Remove-AppByName {
    param($appId, $logBox)
    $packages = Get-AppxPackage -Name "*$appId*" -AllUsers -ErrorAction SilentlyContinue
    if (-not $packages) {
        $logBox.AppendText("[--] Non installata: $appId`r`n")
        $logBox.ScrollToCaret()
        return
    }
    foreach ($package in $packages) {
        try {
            $manifestPath = Join-Path $package.InstallLocation 'AppxManifest.xml'
            if (Test-Path $manifestPath) {
                [xml]$manifest = Get-Content -Path $manifestPath -ErrorAction SilentlyContinue
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
            $logBox.AppendText("[OK] Rimossa: $($package.Name)`r`n")
        } catch {
            $logBox.AppendText("[!!] Impossibile rimuovere: $($package.Name)`r`n")
        }
        $logBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }
}

# ===================================================================
# === SCHERMATA DI CARICAMENTO ===
# ===================================================================
$LoadForm = New-Object System.Windows.Forms.Form
$LoadForm.Text = "Debloat Windows"
$LoadForm.Size = New-Object System.Drawing.Size(400, 120)
$LoadForm.StartPosition = "CenterScreen"
$LoadForm.FormBorderStyle = "FixedDialog"
$LoadForm.MaximizeBox = $false
$LoadForm.ControlBox = $false

$lblLoad = New-Object System.Windows.Forms.Label
$lblLoad.Text = "Controllo app installate in corso..."
$lblLoad.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblLoad.Location = New-Object System.Drawing.Point(15, 20)
$lblLoad.AutoSize = $true
$LoadForm.Controls.Add($lblLoad)

$LoadBar = New-Object System.Windows.Forms.ProgressBar
$LoadBar.Location = New-Object System.Drawing.Point(15, 55)
$LoadBar.Size = New-Object System.Drawing.Size(355, 20)
$LoadBar.Style = "Marquee"
$LoadForm.Controls.Add($LoadBar)

$LoadForm.Show()
[System.Windows.Forms.Application]::DoEvents()

# ===================================================================
# === CONTROLLO INSTALLAZIONE (una sola chiamata Get-AppxPackage) ===
# ===================================================================
$installedPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

function Test-AppInstalled ($appId) {
    # 1. Controlla pacchetti Appx
    if (($installedPackages | Where-Object { $_ -like "*$appId*" }).Count -gt 0) { return $true }

    # 2. Controlla app Win32 nel registro (es. Teams, Edge, app installate manualmente)
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    foreach ($path in $regPaths) {
        $found = Get-ItemProperty $path -ErrorAction SilentlyContinue |
                 Where-Object {
                     $_.DisplayName        -like "*$appId*" -or
                     $_.BundleIdentifier   -like "*$appId*" -or
                     $_.Publisher          -like "*$appId*"
                 }
        if ($found) { return $true }
    }
    return $false
}

$bloatwareStatus = @{}
foreach ($key in $bloatwareApps.Keys) {
    $bloatwareStatus[$key] = Test-AppInstalled $key
    [System.Windows.Forms.Application]::DoEvents()
}

$usefulStatus = @{}
foreach ($key in $usefulApps.Keys) {
    $usefulStatus[$key] = Test-AppInstalled $key
    [System.Windows.Forms.Application]::DoEvents()
}

$LoadForm.Close()
$LoadForm.Dispose()

# Rileva se Edge e' installato (Win32, non Appx)
$edgePath = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$edgeInstalled = Test-Path $edgePath

# ===================================================================
# === GUI PRINCIPALE ===
# ===================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Debloat Windows - Selezione App"
$Form.Size = New-Object System.Drawing.Size(700, 690)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Seleziona le app da rimuovere"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(15, 10)
$lblTitle.AutoSize = $true
$Form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Le righe grigie sono app non installate sul sistema - non possono essere selezionate."
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.Location = New-Object System.Drawing.Point(15, 35)
$lblSub.AutoSize = $true
$lblSub.ForeColor = [System.Drawing.Color]::Gray
$Form.Controls.Add($lblSub)

# --- Checkbox Edge (separata perche non e' un pacchetto Appx) ---
$chkEdge = New-Object System.Windows.Forms.CheckBox
$chkEdge.Text = "Rimuovi Microsoft Edge  [Win32 - richiede riavvio]"
$chkEdge.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$chkEdge.Location = New-Object System.Drawing.Point(15, 58)
$chkEdge.Size = New-Object System.Drawing.Size(500, 20)
if ($edgeInstalled) {
    $chkEdge.Checked = $false
    $chkEdge.ForeColor = [System.Drawing.Color]::DarkRed
} else {
    $chkEdge.Checked = $false
    $chkEdge.Enabled = $false
    $chkEdge.ForeColor = [System.Drawing.Color]::Gray
    $chkEdge.Text = "Rimuovi Microsoft Edge  [Non installato]"
}
$Form.Controls.Add($chkEdge)

# --- TabControl ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(15, 82)
$TabControl.Size = New-Object System.Drawing.Size(655, 340)
$Form.Controls.Add($TabControl)

# Colori costanti
$colorInstalled   = [System.Drawing.Color]::White
$colorNotInstalled = [System.Drawing.Color]::FromArgb(220, 220, 220)
$colorInstalledFg  = [System.Drawing.Color]::Black
$colorNotInstalledFg = [System.Drawing.Color]::Gray

# Funzione helper che popola un ListView con le app e il loro stato
function Build-AppListView {
    param($parent, $appDict, $statusDict, $defaultChecked)

    $lv = New-Object System.Windows.Forms.ListView
    $lv.Location = New-Object System.Drawing.Point(5, 30)
    $lv.Size = New-Object System.Drawing.Size(635, 275)
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.CheckBoxes = $true
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lv.Columns.Add("App", 200) | Out-Null
    $lv.Columns.Add("ID Pacchetto", 300) | Out-Null
    $lv.Columns.Add("Stato", 100) | Out-Null

    foreach ($key in $appDict.Keys) {
        $installed = $statusDict[$key]
        $item = New-Object System.Windows.Forms.ListViewItem($appDict[$key])
        $item.SubItems.Add($key) | Out-Null
        if ($installed) {
            $item.SubItems.Add("Installata") | Out-Null
            $item.BackColor = $colorInstalled
            $item.ForeColor = $colorInstalledFg
            $item.Checked   = $defaultChecked
        } else {
            $item.SubItems.Add("Non installata") | Out-Null
            $item.BackColor = $colorNotInstalled
            $item.ForeColor = $colorNotInstalledFg
            $item.Checked   = $false
        }
        $item.Tag = $key  # salva l'ID nell'oggetto per recuperarlo dopo
        $lv.Items.Add($item) | Out-Null
    }

    # Impedisce di spuntare le app non installate
    # Cattura esplicitamente $statusDict nella closure
    $capturedStatus = $statusDict
    $lv.Add_ItemCheck({
        param($s, $e)
        $clickedItem = $s.Items[$e.Index]
        $appKey = $clickedItem.Tag
        if (-not $capturedStatus[$appKey]) {
            $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked
        }
    }.GetNewClosure())

    $parent.Controls.Add($lv)
    return $lv
}

# --- Tab Bloatware ---
$TabBloat = New-Object System.Windows.Forms.TabPage
$TabBloat.Text = "Bloatware Comune"
$TabControl.Controls.Add($TabBloat)

$lblBloatInfo = New-Object System.Windows.Forms.Label
$lblBloatInfo.Text = "Queste app sono generalmente sicure da rimuovere."
$lblBloatInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblBloatInfo.ForeColor = [System.Drawing.Color]::DarkGreen
$lblBloatInfo.Location = New-Object System.Drawing.Point(5, 5)
$lblBloatInfo.AutoSize = $true
$TabBloat.Controls.Add($lblBloatInfo)

$LvBloat = Build-AppListView -parent $TabBloat -appDict $bloatwareApps -statusDict $bloatwareStatus -defaultChecked $true

# --- Tab App Utili ---
$TabUseful = New-Object System.Windows.Forms.TabPage
$TabUseful.Text = "App Potenzialmente Utili"
$TabControl.Controls.Add($TabUseful)

$lblUsefulInfo = New-Object System.Windows.Forms.Label
$lblUsefulInfo.Text = "Attenzione: valuta con cura prima di rimuovere queste app."
$lblUsefulInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblUsefulInfo.ForeColor = [System.Drawing.Color]::DarkOrange
$lblUsefulInfo.Location = New-Object System.Drawing.Point(5, 5)
$lblUsefulInfo.AutoSize = $true
$TabUseful.Controls.Add($lblUsefulInfo)

$LvUseful = Build-AppListView -parent $TabUseful -appDict $usefulApps -statusDict $usefulStatus -defaultChecked $false

# --- Pulsanti Seleziona/Deseleziona Tutto (solo app installate) ---
$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = "Seleziona Tutto"
$btnSelAll.Location = New-Object System.Drawing.Point(15, 430)
$btnSelAll.Size = New-Object System.Drawing.Size(130, 30)
$btnSelAll.Add_Click({
    $activeLv = if ($TabControl.SelectedTab -eq $TabBloat) { $LvBloat } else { $LvUseful }
    $activeStatus = if ($TabControl.SelectedTab -eq $TabBloat) { $bloatwareStatus } else { $usefulStatus }
    foreach ($item in $activeLv.Items) {
        if ($activeStatus[$item.Tag]) { $item.Checked = $true }
    }
})
$Form.Controls.Add($btnSelAll)

$btnDeselAll = New-Object System.Windows.Forms.Button
$btnDeselAll.Text = "Deseleziona Tutto"
$btnDeselAll.Location = New-Object System.Drawing.Point(155, 430)
$btnDeselAll.Size = New-Object System.Drawing.Size(130, 30)
$btnDeselAll.Add_Click({
    $activeLv = if ($TabControl.SelectedTab -eq $TabBloat) { $LvBloat } else { $LvUseful }
    foreach ($item in $activeLv.Items) { $item.Checked = $false }
})
$Form.Controls.Add($btnDeselAll)

# --- Log ---
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log operazioni:"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblLog.Location = New-Object System.Drawing.Point(15, 475)
$lblLog.AutoSize = $true
$Form.Controls.Add($lblLog)

$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location = New-Object System.Drawing.Point(15, 493)
$LogBox.Size = New-Object System.Drawing.Size(655, 145)
$LogBox.ReadOnly = $true
$LogBox.BackColor = [System.Drawing.Color]::Black
$LogBox.ForeColor = [System.Drawing.Color]::LightGreen
$LogBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$LogBox.ScrollBars = "Vertical"
$Form.Controls.Add($LogBox)

# --- Pulsante Rimuovi ---
$btnRimuovi = New-Object System.Windows.Forms.Button
$btnRimuovi.Text = "RIMUOVI SELEZIONATE"
$btnRimuovi.Location = New-Object System.Drawing.Point(430, 423)
$btnRimuovi.Size = New-Object System.Drawing.Size(240, 44)
$btnRimuovi.BackColor = [System.Drawing.Color]::IndianRed
$btnRimuovi.ForeColor = [System.Drawing.Color]::White
$btnRimuovi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRimuovi.Add_Click({
    $btnRimuovi.Enabled = $false
    $btnSelAll.Enabled  = $false
    $btnDeselAll.Enabled = $false

    # Raccoglie app selezionate dalla tab Bloatware
    $selectedBloat = @()
    foreach ($item in $LvBloat.Items) {
        if ($item.Checked) { $selectedBloat += $item.Tag }
    }

    # Raccoglie app selezionate dalla tab Utili
    $selectedUseful = @()
    foreach ($item in $LvUseful.Items) {
        if ($item.Checked) { $selectedUseful += $item.Tag }
    }

    $total = $selectedBloat.Count + $selectedUseful.Count
    if ($total -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nessuna app selezionata.", "Attenzione")
        $btnRimuovi.Enabled  = $true
        $btnSelAll.Enabled   = $true
        $btnDeselAll.Enabled = $true
        return
    }

    $LogBox.AppendText("=== Inizio rimozione: $total app selezionate ===`r`n")
    [System.Windows.Forms.Application]::DoEvents()

    if ($selectedBloat.Count -gt 0) {
        $LogBox.AppendText("`r`n--- Bloatware Comune ---`r`n")
        foreach ($appId in $selectedBloat) { Remove-AppByName -appId $appId -logBox $LogBox }
    }

    if ($selectedUseful.Count -gt 0) {
        $LogBox.AppendText("`r`n--- App Potenzialmente Utili ---`r`n")
        foreach ($appId in $selectedUseful) { Remove-AppByName -appId $appId -logBox $LogBox }
    }

    # Task telemetria
    $LogBox.AppendText("`r`n--- Disabilitazione task telemetria ---`r`n")
    [System.Windows.Forms.Application]::DoEvents()
    $tasks = @(
        "ProgramDataUpdater", "Microsoft-Windows-DiskDiagnosticDataCollector",
        "Microsoft-Windows-WER-Triggered", "RegIdleBackup", "DmClient",
        "TileDataDownloader", "RestartBPT", "DownloadContentTask",
        "AppIDManagement", "Application Crash Telemetry", "Autotune",
        "AitAgent", "XblGameSaveTask", "StartupAppTask",
        "WDI Run Downloader Task", "WinSAT"
    )
    foreach ($task in $tasks) {
        try {
            Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue
            $LogBox.AppendText("[OK] Task disabilitato: $task`r`n")
        } catch {
            $LogBox.AppendText("[--] Task non trovato: $task`r`n")
        }
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Servizi telemetria
    $LogBox.AppendText("`r`n--- Disabilitazione servizi telemetria ---`r`n")
    [System.Windows.Forms.Application]::DoEvents()
    $services = @("diagnosticshub.standardcollector.service", "DiagTrack", "dmwappushservice")
    foreach ($svc in $services) {
        try {
            Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            $LogBox.AppendText("[OK] Servizio disabilitato: $svc`r`n")
        } catch {
            $LogBox.AppendText("[--] Servizio non trovato: $svc`r`n")
        }
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    # SysMain (solo SSD)
    try {
        $systemDrive = Get-PhysicalDisk | Where-Object { $_.DeviceID -match (Get-Partition | Where-Object { $_.DriveLetter -eq 'C' }).DiskNumber }
        if ($systemDrive.MediaType -eq 'SSD') {
            Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop
            Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
            $LogBox.AppendText("[OK] SysMain disabilitato (SSD rilevato).`r`n")
        } else {
            $LogBox.AppendText("[--] SysMain mantenuto attivo (HDD rilevato).`r`n")
        }
    } catch {
        $LogBox.AppendText("[!!] Impossibile determinare tipo disco per SysMain.`r`n")
    }
    $LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()

    # fotoenable.reg
    $regFile = Join-Path $PSScriptRoot "fotoenable.reg"
    if (Test-Path $regFile) {
        try {
            reg.exe import $regFile 2>&1 | Out-Null
            $LogBox.AppendText("[OK] fotoenable.reg importato.`r`n")
        } catch {
            $LogBox.AppendText("[!!] Errore importazione fotoenable.reg`r`n")
        }
    }

    # OneDrive
    $LogBox.AppendText("`r`n--- Rimozione OneDrive ---`r`n")
    [System.Windows.Forms.Application]::DoEvents()
    try {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        $setup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        $setup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
        if (Test-Path $setup64) {
            Start-Process -FilePath $setup64 -ArgumentList "/uninstall /silent /force" -Wait
        } elseif (Test-Path $setup32) {
            Start-Process -FilePath $setup32 -ArgumentList "/uninstall /silent /force" -Wait
        } else {
            $LogBox.AppendText("[--] OneDrive non trovato, probabilmente gia rimosso.`r`n")
        }
        Start-Sleep -Seconds 3
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue -Force
        Remove-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force
        Remove-Item -Path "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force
        "$env:USERPROFILE\OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:PROGRAMDATA\Microsoft OneDrive", "C:\OneDriveTemp" | ForEach-Object {
            if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
        }
        $LogBox.AppendText("[OK] OneDrive rimosso.`r`n")
    } catch {
        $LogBox.AppendText("[!!] Errore durante rimozione OneDrive.`r`n")
    }
    $LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()

    # Edge
    if ($chkEdge.Checked) {
        $LogBox.AppendText("`r`n--- Rimozione Microsoft Edge ---`r`n")
        [System.Windows.Forms.Application]::DoEvents()
        try {
            # Trova il setup di Edge nella cartella di installazione
            $edgeSetup = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
            if ($edgeSetup) {
                Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait
                $LogBox.AppendText("[OK] Edge rimosso. Riavvio necessario per completare.`r`n")
            } else {
                $LogBox.AppendText("[--] Setup di Edge non trovato, potrebbe essere gia stato rimosso.`r`n")
            }
        } catch {
            $LogBox.AppendText("[!!] Errore durante rimozione Edge.`r`n")
        }
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    # Riavvio Explorer
    $LogBox.AppendText("`r`n=== Completato. Riavvio Esplora File... ===`r`n")
    $LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Seconds 1
    Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process "explorer.exe"

    $btnRimuovi.Text = "COMPLETATO"
    $btnRimuovi.BackColor = [System.Drawing.Color]::DarkGreen
    $btnRimuovi.Add_Click({ $Form.Close() })
})
$Form.Controls.Add($btnRimuovi)

[void]$Form.ShowDialog()