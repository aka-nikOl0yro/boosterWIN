<#
.SYNOPSIS
    Debloat Windows - GUI v2.3
    Le app non installate appaiono in grigio e non sono selezionabili.
    Tre sezioni: Bloatware comune, App potenzialmente utili, Win32 / Altro.
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

# Build 15063 = Win10 1703 (Creators Update), prima versione con Remove-AppxPackage -AllUsers
$supportsAllUsers = ([System.Environment]::OSVersion.Version.Build -ge 15063)

# ===================================================================
# === LISTE APP  (chiavi con * finale per compatibilita' massima) ===
# ===================================================================
$bloatwareApps = [ordered]@{
    "Microsoft.BingNews*"                     = "Notizie Bing"
    "Microsoft.GetHelp*"                      = "Assistenza"
    "Microsoft.Getstarted*"                   = "Suggerimenti Windows"
    "Microsoft.MicrosoftSolitaireCollection*" = "Solitario"
    "Microsoft.WindowsFeedbackHub*"           = "Hub di Feedback"
    "Microsoft.WindowsMaps*"                  = "Mappe"
    "Microsoft.ZuneMusic*"                    = "Groove Musica"
    "Microsoft.ZuneVideo*"                    = "Film e TV"
    "Microsoft.People*"                       = "Persone"
    "Microsoft.549981C3F5F10*"                = "Cortana"
    "Microsoft.BingWeather*"                  = "Meteo Bing"
    "Microsoft.SkypeApp*"                     = "Skype"
    "Microsoft.YourPhone*"                    = "Collegamento al Telefono (Win10)"
    "MicrosoftCorporationII.YourPhone*"       = "Collegamento al Telefono (Win11)"
    "MicrosoftCorporationII.MicrosoftFamily*" = "Microsoft Family Safety"
    "Microsoft.Clipchamp*"                    = "Clipchamp (Editor Video)"
}

$usefulApps = [ordered]@{
    "Microsoft.MicrosoftStickyNotes*"      = "Sticky Notes"
    "Microsoft.WindowsAlarms*"             = "Sveglie e Orologio"
    "Microsoft.WindowsCamera*"             = "Fotocamera"
    "Microsoft.WindowsSoundRecorder*"      = "Registratore Suoni"
    "Microsoft.Todos*"                     = "Microsoft To Do"
    "Microsoft.OutlookForWindows*"         = "Outlook"
    "MicrosoftTeams*"                      = "Microsoft Teams (Appx/Win11)"
    "Microsoft.Teams*"                     = "Microsoft Teams (Win32/Work)"
    "Microsoft.WindowsCommunicationsApps*" = "Posta e Calendario"
    "MicrosoftCorporationII.QuickAssist*"  = "Assistenza Rapida"
    "Microsoft.Xbox.TCUI*"                 = "Xbox TCUI"
    "Microsoft.XboxApp*"                   = "Xbox App (Win10)"
    "Microsoft.GamingApp*"                 = "Xbox App (Win11)"
    "Microsoft.XboxIdentityProvider*"      = "Xbox Identity Provider"
    "Microsoft.XboxSpeechToTextOverlay*"   = "Xbox Speech Overlay"
    "Microsoft.XboxGameOverlay*"           = "Xbox Game Overlay"
    "Microsoft.XboxGamingOverlay*"         = "Xbox Gaming Overlay (Game Bar)"
}

# ===================================================================
# === FUNZIONE RIMOZIONE APP APPX ===
# ===================================================================
function Remove-AppByName {
    param($appId, $logBox)

    # appId contiene gia' il wildcard finale — nessun avvolgimento extra necessario
    $packages = Get-AppxPackage -Name $appId -AllUsers -ErrorAction SilentlyContinue
    if (-not $packages) {
        $logBox.AppendText("[--] Non installata: $appId`r`n")
        $logBox.ScrollToCaret()
    } else {
        foreach ($package in $packages) {
            # Tenta di chiudere il processo
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

            # Rimozione con fallback per Win10 pre-1703
            $removed = $false
            if ($supportsAllUsers) {
                try {
                    Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop
                    $logBox.AppendText("[OK] Rimossa (AllUsers): $($package.Name)`r`n")
                    $removed = $true
                } catch {}
            }
            if (-not $removed) {
                try {
                    Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop
                    $logBox.AppendText("[OK] Rimossa (utente corrente): $($package.Name)`r`n")
                    $removed = $true
                } catch {
                    $logBox.AppendText("[!!] Impossibile rimuovere: $($package.Name)`r`n")
                }
            }
            $logBox.ScrollToCaret()
            [System.Windows.Forms.Application]::DoEvents()
        }
    }

    # Rimuove anche il pacchetto provisionato (evita reinstallo su nuovi utenti)
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                   Where-Object { $_.DisplayName -like $appId }
    foreach ($prov in $provisioned) {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null
            $logBox.AppendText("[OK] Pacchetto provisionato rimosso: $($prov.DisplayName)`r`n")
        } catch {
            $logBox.AppendText("[!!] Impossibile rimuovere pacchetto provisionato: $($prov.DisplayName)`r`n")
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
# === CONTROLLO INSTALLAZIONE (OTTIMIZZATO) ===
# ===================================================================
# Carica tutto l'inventario una sola volta per velocizzare
$installedPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$allInstalledWin32 = foreach ($path in $regPaths) {
    Get-ItemProperty $path -ErrorAction SilentlyContinue | Select-Object DisplayName, BundleIdentifier, Publisher
}

function Test-AppInstalled ($appId) {
    # 1. Controlla pacchetti Appx
    if ($installedPackages -like $appId) { return $true }

    # 2. Controlla app Win32 nella cache locale del registro
    $found = $allInstalledWin32 | Where-Object {
        $_.DisplayName      -like "*$appId*" -or
        $_.BundleIdentifier -like "*$appId*" -or
        $_.Publisher        -like "*$appId*"
    }
    return [bool]$found
}

$bloatwareStatus = @{}
foreach ($key in $bloatwareApps.Keys) {
    $bloatwareStatus[$key] = Test-AppInstalled $key
}

$usefulStatus = @{}
foreach ($key in $usefulApps.Keys) {
    $usefulStatus[$key] = Test-AppInstalled $key
}

$LoadForm.Close()
$LoadForm.Dispose()

# ===================================================================
# === RILEVAMENTO APP WIN32 ===
# ===================================================================
$edgeInstalled = Test-Path "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"

$oneDriveInstalled = (
    (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") -or
    (Test-Path "$env:SystemRoot\System32\OneDriveSetup.exe") -or
    (Test-Path "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe")
)

# Tag con __ per distinguerli dagli ID Appx
$win32Apps = [ordered]@{
    "__Edge__"     = "Microsoft Edge  [richiede riavvio]"
    "__OneDrive__" = "Microsoft OneDrive"
}
$win32Status = @{
    "__Edge__"     = $edgeInstalled
    "__OneDrive__" = $oneDriveInstalled
}

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

# --- TabControl ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(15, 58)
$TabControl.Size = New-Object System.Drawing.Size(655, 365)
$Form.Controls.Add($TabControl)

# Colori costanti
$colorInstalled      = [System.Drawing.Color]::White
$colorNotInstalled   = [System.Drawing.Color]::FromArgb(220, 220, 220)
$colorInstalledFg    = [System.Drawing.Color]::Black
$colorNotInstalledFg = [System.Drawing.Color]::Gray

# ===================================================================
# === FUNZIONE BUILD LISTVIEW ===
# ===================================================================
function Build-AppListView {
    param($parent, $appDict, $statusDict, $defaultChecked)

    $lv = New-Object System.Windows.Forms.ListView
    $lv.Location = New-Object System.Drawing.Point(5, 30)
    $lv.Size = New-Object System.Drawing.Size(635, 300)
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
        $item.Tag = $key
        $lv.Items.Add($item) | Out-Null
    }

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

# --- Tab Win32 / Altro ---
$TabWin32 = New-Object System.Windows.Forms.TabPage
$TabWin32.Text = "Win32 / Altro"
$TabControl.Controls.Add($TabWin32)

$lblWin32Info = New-Object System.Windows.Forms.Label
$lblWin32Info.Text = "App Win32: la rimozione e' piu' invasiva. Edge richiede riavvio per completarsi."
$lblWin32Info.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblWin32Info.ForeColor = [System.Drawing.Color]::DarkRed
$lblWin32Info.Location = New-Object System.Drawing.Point(5, 5)
$lblWin32Info.AutoSize = $true
$TabWin32.Controls.Add($lblWin32Info)

$LvWin32 = Build-AppListView -parent $TabWin32 -appDict $win32Apps -statusDict $win32Status -defaultChecked $false

# ===================================================================
# === PULSANTI SELEZIONA / DESELEZIONA ===
# ===================================================================
$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = "Seleziona Tutto"
$btnSelAll.Location = New-Object System.Drawing.Point(15, 430)
$btnSelAll.Size = New-Object System.Drawing.Size(130, 30)
$btnSelAll.Add_Click({
    $activeLv = switch ($TabControl.SelectedTab) {
        $TabBloat  { $LvBloat  }
        $TabUseful { $LvUseful }
        $TabWin32  { $LvWin32  }
    }
    $activeStatus = switch ($TabControl.SelectedTab) {
        $TabBloat  { $bloatwareStatus }
        $TabUseful { $usefulStatus    }
        $TabWin32  { $win32Status     }
    }
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
    $activeLv = switch ($TabControl.SelectedTab) {
        $TabBloat  { $LvBloat  }
        $TabUseful { $LvUseful }
        $TabWin32  { $LvWin32  }
    }
    foreach ($item in $activeLv.Items) { $item.Checked = $false }
})
$Form.Controls.Add($btnDeselAll)

# ===================================================================
# === LOG ===
# ===================================================================
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log operazioni:"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblLog.Location = New-Object System.Drawing.Point(15, 470)
$lblLog.AutoSize = $true
$Form.Controls.Add($lblLog)

$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location = New-Object System.Drawing.Point(15, 488)
$LogBox.Size = New-Object System.Drawing.Size(655, 155)
$LogBox.ReadOnly = $true
$LogBox.BackColor = [System.Drawing.Color]::Black
$LogBox.ForeColor = [System.Drawing.Color]::LightGreen
$LogBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$LogBox.ScrollBars = "Vertical"
$Form.Controls.Add($LogBox)

# ===================================================================
# === PULSANTE RIMUOVI ===
# ===================================================================
$btnRimuovi = New-Object System.Windows.Forms.Button
$btnRimuovi.Text = "RIMUOVI SELEZIONATE"
$btnRimuovi.Location = New-Object System.Drawing.Point(430, 422)
$btnRimuovi.Size = New-Object System.Drawing.Size(240, 44)
$btnRimuovi.BackColor = [System.Drawing.Color]::IndianRed
$btnRimuovi.ForeColor = [System.Drawing.Color]::White
$btnRimuovi.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnRimuovi.Add_Click({
    $btnRimuovi.Enabled  = $false
    $btnSelAll.Enabled   = $false
    $btnDeselAll.Enabled = $false

    $selectedBloat = @()
    foreach ($item in $LvBloat.Items) {
        if ($item.Checked) { $selectedBloat += $item.Tag }
    }

    $selectedUseful = @()
    foreach ($item in $LvUseful.Items) {
        if ($item.Checked) { $selectedUseful += $item.Tag }
    }

    # Per Win32 conserviamo il riferimento all'Item (ci serve dopo per aggiornare colore/stato)
    $selectedWin32 = @()
    foreach ($item in $LvWin32.Items) {
        if ($item.Checked) { $selectedWin32 += $item }
    }

    $total = $selectedBloat.Count + $selectedUseful.Count + $selectedWin32.Count
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

    # --- Task telemetria ---
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

    # --- Servizi telemetria ---
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

    # --- SysMain (solo SSD) ---
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

    # --- fotoenable.reg ---
    $regFile = Join-Path $PSScriptRoot "fotoenable.reg"
    if (Test-Path $regFile) {
        try {
            reg.exe import $regFile 2>&1 | Out-Null
            $LogBox.AppendText("[OK] fotoenable.reg importato.`r`n")
        } catch {
            $LogBox.AppendText("[!!] Errore importazione fotoenable.reg`r`n")
        }
    }

    # ===================================================================
    # === WIN32: OneDrive e Edge ===
    # ===================================================================
    foreach ($win32Item in $selectedWin32) {
        switch ($win32Item.Tag) {

            "__OneDrive__" {
                $LogBox.AppendText("`r`n--- Rimozione OneDrive ---`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                $odSuccess = $false
                try {
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    $setup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
                    $setup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
                    if (Test-Path $setup64) {
                        Start-Process -FilePath $setup64 -ArgumentList "/uninstall /silent" -Wait
                        $odSuccess = $true
                    } elseif (Test-Path $setup32) {
                        Start-Process -FilePath $setup32 -ArgumentList "/uninstall /silent" -Wait
                        $odSuccess = $true
                    } else {
                        $LogBox.AppendText("[--] OneDriveSetup.exe non trovato, probabilmente gia' rimosso.`r`n")
                    }
                    Start-Sleep -Seconds 3
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue -Force
                    # HKCR: non e' un PSDrive nativo — usare Registry::HKEY_CLASSES_ROOT\
                    Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force
                    Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force
                    "$env:USERPROFILE\OneDrive", "$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:PROGRAMDATA\Microsoft OneDrive", "C:\OneDriveTemp" | ForEach-Object {
                        if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue }
                    }
                    if ($odSuccess) { $LogBox.AppendText("[OK] OneDrive rimosso.`r`n") }
                } catch {
                    $LogBox.AppendText("[!!] Errore durante rimozione OneDrive: $_`r`n")
                    $odSuccess = $false
                }
                # Aggiorna voce nella lista solo se la rimozione e' andata a buon fine
                if ($odSuccess) {
                    $win32Status["__OneDrive__"] = $false
                    $win32Item.Checked              = $false
                    $win32Item.BackColor            = $colorNotInstalled
                    $win32Item.ForeColor            = $colorNotInstalledFg
                    $win32Item.SubItems[2].Text     = "Non installata"
                }
                $LogBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }

            "__Edge__" {
                $LogBox.AppendText("`r`n--- Rimozione Microsoft Edge ---`r`n")
                [System.Windows.Forms.Application]::DoEvents()
                $edSuccess = $false
                try {
                    $edgeSetup = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1
                    if ($edgeSetup) {
                        Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
                        Start-Sleep -Seconds 2
                        Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait
                        $LogBox.AppendText("[OK] Edge rimosso. Riavvio necessario per completare.`r`n")
                        $edSuccess = $true
                    } else {
                        $LogBox.AppendText("[--] Setup di Edge non trovato, potrebbe essere gia' stato rimosso.`r`n")
                    }
                } catch {
                    $LogBox.AppendText("[!!] Errore durante rimozione Edge: $_`r`n")
                }
                if ($edSuccess) {
                    $win32Status["__Edge__"]    = $false
                    $win32Item.Checked           = $false
                    $win32Item.BackColor         = $colorNotInstalled
                    $win32Item.ForeColor         = $colorNotInstalledFg
                    $win32Item.SubItems[2].Text  = "Non installata"
                }
                $LogBox.ScrollToCaret()
                [System.Windows.Forms.Application]::DoEvents()
            }
        }
    }

    # --- Riavvio Explorer ---
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