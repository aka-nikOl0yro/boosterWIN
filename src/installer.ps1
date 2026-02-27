<#
.SYNOPSIS
    Installer Windows - GUI v1.0
    Installa app Microsoft e di terze parti tramite winget.
    Se winget non e' installato lo scarica e installa automaticamente.
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

# App Microsoft reinstallabili (quelle rimosse da debloat)
# Gli ID numerici (9XXXX) sono i Product ID del Microsoft Store — gli unici che funzionano
# con winget --source msstore su versioni recenti di Windows.
$microsoftApps = [ordered]@{
    "9WZDNCRFHVFW"   = "Notizie Bing"
    "9PKDZBMV1H3T"   = "Assistenza (Get Help)"
    "9MSPC6MP8FM4"   = "Microsoft Solitario"
    "9NBLGGH4R32N"   = "Hub di Feedback"
    "9WZDNCRDTBVB"   = "Mappe"
    "9WZDNCRFJ3PT"   = "Media Player (ex Groove)"
    "9WZDNCRFJ3P2"   = "Film e TV"
    "9NMPJ99VJBWV"   = "Collegamento al Telefono (Phone Link)"
    "9WZDNCRFJ3Q2"   = "Meteo"
    "9WZDNCRFHVQM"   = "Posta e Calendario"
    "9NBLGGH4QGHW"   = "Sticky Notes"
    "9WZDNCRFJ3PR"   = "Sveglie e Orologio"
    "9WZDNCRFJBBG"   = "Fotocamera"
    "9WZDNCRFHWKN"   = "Registratore Vocale"
    "9NBLGGH5R558"   = "Microsoft To Do"
    "9WZDNCRFJBMP"   = "Microsoft Teams"
    "9P7BP5VNWKX5"   = "Assistenza Rapida (Quick Assist)"
    "9MV0B5HZVK9Z"   = "Xbox App"
    "9NZKPSTSNW4P"   = "Xbox Game Bar"
    "9P1J8S7CCWWT"   = "Clipchamp (Editor Video)"
}

# App di terze parti con ID winget
$thirdPartyApps = [ordered]@{
    "Mozilla.Firefox"              = "Firefox"
    "Brave.Brave"                  = "Brave Browser"
    "Google.Chrome"                = "Google Chrome"
	"Cloudflare.Warp"			   = "Cloudflare Warp"
    "Spotify.Spotify"              = "Spotify"
    "VideoLAN.VLC"                 = "VLC Media Player"
	"AtomixProductions.VirtualDJ"  = "VirtualDJ"
	"9N0866FS04W8"				   = "Dolby Access"
    "Telegram.TelegramDesktop"     = "Telegram"
    "9NKSQGP7F2NH"                 = "WhatsApp"
    "Discord.Discord"              = "Discord"
    "Ubisoft.Connect"              = "Ubisoft Connect"
    "ElectronicArts.EADesktop"     = "EA App"
    "Valve.Steam"                  = "Steam"
    "EpicGames.EpicGamesLauncher"  = "Epic Games Launcher"
	"Moonsworth.LunarClient"	   = "Lunar Client"
	"Modrinth.ModrinthApp"		   = "Modrinth App"
	"LizardByte.Sunshine"		   = "Sunshine"
	"ShaulEizikovich.vJoyDeviceDriver" = "vJoy"
	"Tailscale.Tailscale"		   = "Tailscale"
    "OBSProject.OBSStudio"         = "OBS Studio"
    "Notepad++.Notepad++"          = "Notepad++"
    "Microsoft.VisualStudioCode"   = "Visual Studio Code"
    "Rufus.Rufus"                  = "Rufus"
    "7zip.7zip"                    = "7-Zip"
    "RARLab.WinRAR"                = "WinRAR"
	"Rem0o.FanControl"			   = "FanControl"
    "Microsoft.PowerToys"          = "PowerToys"
	"winaero.tweaker"			   = "Winaero Tweaker"
	"Klocman.BulkCrapUninstaller"  = "BulkCrapUninstaller"
	"XPFFTQ032PTPHF"			   = "UniGetUI"
	"Oracle.VirtualBox"			   = "VirtualBox"
}

# ===================================================================
# === SCHERMATA DI CARICAMENTO - CONTROLLO WINGET ===
# ===================================================================
$LoadForm = New-Object System.Windows.Forms.Form
$LoadForm.Text = "Installer Windows"
$LoadForm.Size = New-Object System.Drawing.Size(450, 140)
$LoadForm.StartPosition = "CenterScreen"
$LoadForm.FormBorderStyle = "FixedDialog"
$LoadForm.MaximizeBox = $false
$LoadForm.ControlBox = $false

$lblLoad = New-Object System.Windows.Forms.Label
$lblLoad.Text = "Controllo winget in corso..."
$lblLoad.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$lblLoad.Location = New-Object System.Drawing.Point(15, 15)
$lblLoad.Size = New-Object System.Drawing.Size(410, 20)
$LoadForm.Controls.Add($lblLoad)

$lblLoadSub = New-Object System.Windows.Forms.Label
$lblLoadSub.Text = ""
$lblLoadSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblLoadSub.ForeColor = [System.Drawing.Color]::Gray
$lblLoadSub.Location = New-Object System.Drawing.Point(15, 38)
$lblLoadSub.Size = New-Object System.Drawing.Size(410, 18)
$LoadForm.Controls.Add($lblLoadSub)

$LoadBar = New-Object System.Windows.Forms.ProgressBar
$LoadBar.Location = New-Object System.Drawing.Point(15, 65)
$LoadBar.Size = New-Object System.Drawing.Size(405, 20)
$LoadBar.Style = "Marquee"
$LoadForm.Controls.Add($LoadBar)

$LoadForm.Show()
[System.Windows.Forms.Application]::DoEvents()

# ===================================================================
# === CONTROLLO E INSTALLAZIONE WINGET ===
# ===================================================================
function Install-Winget {
    param($statusLabel, $subLabel)

    $statusLabel.Text = "Download winget in corso..."
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # Scarica l'ultima release di winget da GitHub (metodo legacy senza Store)
        $apiUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing
        
        # Trova il file .msixbundle
        $msixBundle = $release.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -First 1
        $vcLibs    = $release.assets | Where-Object { $_.name -like "*.appx" -and $_.name -like "*VCLibs*" } | Select-Object -First 1

        if (-not $msixBundle) {
            $subLabel.Text = "Impossibile trovare il pacchetto winget."
            return $false
        }

        $tempDir     = "$env:TEMP\winget_install"
        $msixPath    = "$tempDir\winget.msixbundle"
        $vcLibsPath  = "$tempDir\VCLibs.appx"

        if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }

        # Download VCLibs (dipendenza)
        $subLabel.Text = "Download VCLibs (dipendenza)..."
        [System.Windows.Forms.Application]::DoEvents()
        $vcLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
        Invoke-WebRequest -Uri $vcLibsUrl -OutFile $vcLibsPath -UseBasicParsing

        # Download winget
        $subLabel.Text = "Download $($msixBundle.name)..."
        [System.Windows.Forms.Application]::DoEvents()
        Invoke-WebRequest -Uri $msixBundle.browser_download_url -OutFile $msixPath -UseBasicParsing

        # Installa
        $subLabel.Text = "Installazione winget..."
        [System.Windows.Forms.Application]::DoEvents()
        Add-AppxPackage -Path $vcLibsPath -ErrorAction SilentlyContinue
        Add-AppxPackage -Path $msixPath -ErrorAction Stop

        # Pulizia
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

        $statusLabel.Text = "winget installato correttamente."
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Seconds 2
        return $true
    }
    catch {
        $subLabel.Text = "Errore: $_"
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Seconds 3
        return $false
    }
}

# Controlla se winget e' disponibile
$wingetAvailable = $false
try {
    $wingetVersion = & winget --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $wingetAvailable = $true
        $lblLoad.Text = "winget trovato: $wingetVersion"
        $lblLoadSub.Text = "Controllo app installate..."
        [System.Windows.Forms.Application]::DoEvents()
    }
} catch {}

if (-not $wingetAvailable) {
    $lblLoad.Text = "winget non trovato. Installazione in corso..."
    [System.Windows.Forms.Application]::DoEvents()
    $wingetAvailable = Install-Winget -statusLabel $lblLoad -subLabel $lblLoadSub
    if (-not $wingetAvailable) {
        $LoadForm.Close()
        [System.Windows.Forms.MessageBox]::Show(
            "Impossibile installare winget automaticamente.`nScaricalo manualmente da:`nhttps://github.com/microsoft/winget-cli/releases",
            "Errore winget",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        exit
    }
}

# Recupera app installate tramite winget per evidenziare quelle gia' presenti
$lblLoad.Text = "Controllo app gia' installate..."
[System.Windows.Forms.Application]::DoEvents()

$wingetInstalled = @{}
# Accetta le sorgenti una volta sola per evitare errori
& winget list --accept-source-agreements 2>&1 | Out-Null

# Controlla ogni app singolarmente con --exact: piu' preciso di parsare winget list
$lblLoad.Text = "Controllo app installate (potrebbe richiedere qualche secondo)..."
[System.Windows.Forms.Application]::DoEvents()

$allKeys = @($microsoftApps.Keys) + @($thirdPartyApps.Keys)
foreach ($key in $allKeys) {
    try {
        $check = & winget list --id $key --exact --accept-source-agreements 2>&1 | Out-String
        $wingetInstalled[$key] = ($check -match [regex]::Escape($key))
    } catch {
        $wingetInstalled[$key] = $false
    }
    [System.Windows.Forms.Application]::DoEvents()
}

$LoadForm.Close()
$LoadForm.Dispose()

# ===================================================================
# === GUI PRINCIPALE ===
# ===================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Installer Windows - Installa App"
$Form.Size = New-Object System.Drawing.Size(700, 690)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Seleziona le app da installare"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(15, 10)
$lblTitle.AutoSize = $true
$Form.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Le righe verdi sono gia' installate. Le righe grigie non sono disponibili."
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblSub.Location = New-Object System.Drawing.Point(15, 35)
$lblSub.AutoSize = $true
$lblSub.ForeColor = [System.Drawing.Color]::Gray
$Form.Controls.Add($lblSub)

# --- TabControl ---
$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(15, 60)
$TabControl.Size = New-Object System.Drawing.Size(655, 360)
$Form.Controls.Add($TabControl)

# Colori
$colorNotInstalled   = [System.Drawing.Color]::White
$colorAlreadyInstalled = [System.Drawing.Color]::FromArgb(220, 255, 220)  # verde chiaro
$colorAlreadyInstalledFg = [System.Drawing.Color]::DarkGreen
$colorUnavailable    = [System.Drawing.Color]::FromArgb(220, 220, 220)    # grigio
$colorUnavailableFg  = [System.Drawing.Color]::Gray

# Funzione helper che costruisce un ListView per le app
function Build-InstallerListView {
    param($parent, $appDict, $installedDict, $infoText, $infoColor)

    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = $infoText
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblInfo.ForeColor = $infoColor
    $lblInfo.Location = New-Object System.Drawing.Point(5, 5)
    $lblInfo.AutoSize = $true
    $parent.Controls.Add($lblInfo)

    $lv = New-Object System.Windows.Forms.ListView
    $lv.Location = New-Object System.Drawing.Point(5, 28)
    $lv.Size = New-Object System.Drawing.Size(635, 295)
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.CheckBoxes = $true
    $lv.FullRowSelect = $true
    $lv.GridLines = $true
    $lv.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lv.Columns.Add("App", 200)         | Out-Null
    $lv.Columns.Add("ID Winget", 300)   | Out-Null
    $lv.Columns.Add("Stato", 110)       | Out-Null

    foreach ($key in $appDict.Keys) {
        $alreadyInstalled = $installedDict[$key]
        $item = New-Object System.Windows.Forms.ListViewItem($appDict[$key])
        $item.SubItems.Add($key) | Out-Null

        if ($alreadyInstalled) {
            $item.SubItems.Add("Installata") | Out-Null
            $item.BackColor = $colorAlreadyInstalled
            $item.ForeColor = $colorAlreadyInstalledFg
            $item.Checked   = $false
        } else {
            $item.SubItems.Add("Non installata") | Out-Null
            $item.BackColor = $colorNotInstalled
            $item.ForeColor = [System.Drawing.Color]::Black
            $item.Checked   = $false
        }
        $item.Tag = $key
        $lv.Items.Add($item) | Out-Null
    }

    $parent.Controls.Add($lv)

    # Blocca la selezione di app già installate (sfondo verde)
    $lv.Add_ItemCheck({
        param($sender, $e)
        if ($sender.Items[$e.Index].BackColor -eq $colorAlreadyInstalled) {
            $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked
        }
    })

    return $lv
}

# --- Tab App Microsoft ---
$TabMicrosoft = New-Object System.Windows.Forms.TabPage
$TabMicrosoft.Text = "App Microsoft"
$TabControl.Controls.Add($TabMicrosoft)

$LvMicrosoft = Build-InstallerListView `
    -parent $TabMicrosoft `
    -appDict $microsoftApps `
    -installedDict $wingetInstalled `
    -infoText "App Microsoft preinstallate o rimosse da debloat." `
    -infoColor ([System.Drawing.Color]::DarkBlue)

# --- Tab App Terze Parti ---
$TabThirdParty = New-Object System.Windows.Forms.TabPage
$TabThirdParty.Text = "App Terze Parti"
$TabControl.Controls.Add($TabThirdParty)

$LvThirdParty = Build-InstallerListView `
    -parent $TabThirdParty `
    -appDict $thirdPartyApps `
    -installedDict $wingetInstalled `
    -infoText "Software popolari di terze parti." `
    -infoColor ([System.Drawing.Color]::DarkBlue)

# --- Pulsanti Seleziona/Deseleziona ---
$btnSelAll = New-Object System.Windows.Forms.Button
$btnSelAll.Text = "Seleziona Tutto"
$btnSelAll.Location = New-Object System.Drawing.Point(15, 428)
$btnSelAll.Size = New-Object System.Drawing.Size(130, 30)
$btnSelAll.Add_Click({
    $activeLv = if ($TabControl.SelectedTab -eq $TabMicrosoft) { $LvMicrosoft } else { $LvThirdParty }
    foreach ($item in $activeLv.Items) { $item.Checked = $true }
})
$Form.Controls.Add($btnSelAll)

$btnDeselAll = New-Object System.Windows.Forms.Button
$btnDeselAll.Text = "Deseleziona Tutto"
$btnDeselAll.Location = New-Object System.Drawing.Point(155, 428)
$btnDeselAll.Size = New-Object System.Drawing.Size(130, 30)
$btnDeselAll.Add_Click({
    $activeLv = if ($TabControl.SelectedTab -eq $TabMicrosoft) { $LvMicrosoft } else { $LvThirdParty }
    foreach ($item in $activeLv.Items) { $item.Checked = $false }
})
$Form.Controls.Add($btnDeselAll)

# --- Label Log ---
$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Log operazioni:"
$lblLog.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblLog.Location = New-Object System.Drawing.Point(15, 468)
$lblLog.AutoSize = $true
$Form.Controls.Add($lblLog)

$LogBox = New-Object System.Windows.Forms.RichTextBox
$LogBox.Location = New-Object System.Drawing.Point(15, 486)
$LogBox.Size = New-Object System.Drawing.Size(655, 145)
$LogBox.ReadOnly = $true
$LogBox.BackColor = [System.Drawing.Color]::Black
$LogBox.ForeColor = [System.Drawing.Color]::LightGreen
$LogBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$LogBox.ScrollBars = "Vertical"
$Form.Controls.Add($LogBox)

# --- Pulsante Installa ---
$btnInstalla = New-Object System.Windows.Forms.Button
$btnInstalla.Text = "INSTALLA SELEZIONATE"
$btnInstalla.Location = New-Object System.Drawing.Point(430, 421)
$btnInstalla.Size = New-Object System.Drawing.Size(240, 44)
$btnInstalla.BackColor = [System.Drawing.Color]::SteelBlue
$btnInstalla.ForeColor = [System.Drawing.Color]::White
$btnInstalla.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnInstalla.Add_Click({
    # App con ID numerici Store (9XXXX / XPXXXX) — si installano solo con --source msstore
    # Tutte le Microsoft Apps in $microsoftApps usano ID Store, più WhatsApp tra le terze parti
    $msstoreIds = @(
        "9WZDNCRFHVFW", "9PKDZBMV1H3T", "9MSPC6MP8FM4", "9NBLGGH4R32N",
        "9WZDNCRDTBVB", "9WZDNCRFJ3PT", "9WZDNCRFJ3P2", "9NMPJ99VJBWV",
        "9WZDNCRFJ3Q2", "9WZDNCRFHVQM", "9NBLGGH4QGHW", "9WZDNCRFJ3PR",
        "9WZDNCRFJBBG", "9WZDNCRFHWKN", "9NBLGGH5R558", "9WZDNCRFJBMP",
        "9P7BP5VNWKX5", "9MV0B5HZVK9Z", "9NZKPSTSNW4P", "9P1J8S7CCWWT",
        "9NKSQGP7F2NH"
    )

    $btnInstalla.Enabled = $false
    $btnSelAll.Enabled   = $false
    $btnDeselAll.Enabled = $false

    # Raccoglie le app selezionate da entrambe le tab
    $selectedApps = @()
    foreach ($item in $LvMicrosoft.Items) {
        if ($item.Checked) { $selectedApps += $item.Tag }
    }
    foreach ($item in $LvThirdParty.Items) {
        if ($item.Checked) { $selectedApps += $item.Tag }
    }

    if ($selectedApps.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nessuna app selezionata.", "Attenzione")
        $btnInstalla.Enabled = $true
        $btnSelAll.Enabled   = $true
        $btnDeselAll.Enabled = $true
        return
    }

    # Mappa id -> nome leggibile (costruita una volta sola)
    $allApps = @{}
    foreach ($k in $microsoftApps.Keys)  { $allApps[$k] = $microsoftApps[$k] }
    foreach ($k in $thirdPartyApps.Keys) { $allApps[$k] = $thirdPartyApps[$k] }

    $LogBox.AppendText("=== Inizio installazione: $($selectedApps.Count) app selezionate ===`r`n")
    [System.Windows.Forms.Application]::DoEvents()

    foreach ($appId in $selectedApps) {
        $appName = if ($allApps.ContainsKey($appId)) { $allApps[$appId] } else { $appId }
        $LogBox.AppendText("`r`n-> Installazione: $appName ($appId)...`r`n")
        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()

        try {
            if ($msstoreIds -contains $appId) {
                # ID numerici Store: obbligatorio --source msstore
                $result = & winget install --id $appId --exact --silent --accept-package-agreements --accept-source-agreements --source msstore 2>&1 | Out-String
            } else {
                # Terze parti con ID testuale: winget standard
                $result = & winget install --id $appId --exact --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
            }
            $exitCode = $LASTEXITCODE

            switch ($exitCode) {
                0 {
                    $LogBox.AppendText("[OK] $appName installata con successo.`r`n")
                    foreach ($lv in @($LvMicrosoft, $LvThirdParty)) {
                        foreach ($item in $lv.Items) {
                            if ($item.Tag -eq $appId) {
                                $item.BackColor = $colorAlreadyInstalled
                                $item.ForeColor = $colorAlreadyInstalledFg
                                $item.SubItems[2].Text = "Installata"
                                $item.Checked = $false
                            }
                        }
                    }
                }
                -1978335189 { $LogBox.AppendText("[--] $appName era gia' installata.`r`n") }
                -1978335209 { $LogBox.AppendText("[--] $appName e' gia' all'ultima versione.`r`n") }
                -1978335212 { $LogBox.AppendText("[!!] $appName - Nessun installer compatibile (Windows non supportato o app non disponibile in questa regione).`r`n") }
                -1978335215 { $LogBox.AppendText("[!!] $appName - Pacchetto non trovato nel catalogo winget.`r`n") }
                -1978335210 { $LogBox.AppendText("[!!] $appName - Hash mismatch (pacchetto potenzialmente corrotto, riprova).`r`n") }
                default {
                    $LogBox.AppendText("[!!] Errore installazione $appName (codice: $exitCode).`r`n")
                    $lastLine = ($result -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 1)
                    if ($lastLine) { $LogBox.AppendText("     Info: $($lastLine.Trim())`r`n") }
                }
            }
        } catch {
            $LogBox.AppendText("[!!] Errore imprevisto per $appName`: $_`r`n")
        }

        $LogBox.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    }

    $LogBox.AppendText("`r`n=== Installazione completata. ===`r`n")
    $LogBox.ScrollToCaret()

    $btnInstalla.Text = "COMPLETATO"
    $btnInstalla.BackColor = [System.Drawing.Color]::DarkGreen
    $btnInstalla.Add_Click({ $Form.Close() })
})
$Form.Controls.Add($btnInstalla)

[void]$Form.ShowDialog()