<# :
@echo off
setlocal
:: 1. CONTROLLO AMMINISTRATORE
FSUTIL dirty query %systemdrive% >nul
if %errorlevel% neq 0 (
    echo Richiesta privilegi di amministratore...
    PowerShell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. SETUP PERCORSO
set "FULL_PATH=%~f0"

:: 3. AVVIO MOTORE
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "$MyPath = '%FULL_PATH%'; Invoke-Expression ($(Get-Content '%FULL_PATH%' | Out-String))"
goto :EOF
#>

# --- INIZIO SCRIPT POWERSHELL ---

$ScriptDir = [System.IO.Path]::GetDirectoryName($MyPath)
$ConfigFile = "$ScriptDir\CleanerConfig.json"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- FUNZIONI UTILI ---

function Get-FileCount {
    param ($DirPath)
    try {
        if (Test-Path $DirPath) {
            return [System.IO.Directory]::GetFiles($DirPath, "*", [System.IO.SearchOption]::AllDirectories).Length
        }
        return 0
    } catch { return 0 }
}

function Get-FolderSize {
    param ($DirPath)
    try {
        if (Test-Path $DirPath) {
            $files = @(Get-ChildItem $DirPath -Recurse -Force -File -ErrorAction SilentlyContinue)
            if ($files.Count -gt 0) {
                $measure = $files | Measure-Object -Property Length -Sum
                return $measure.Sum
            }
        }
        return 0
    } catch { return 0 }
}

function Format-Size {
    param ($Bytes)
    if ($Bytes -lt 1MB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    return "{0:N2} MB" -f ($Bytes / 1MB)
}

function Safe-Save-Config {
    param ($Path, $Data)
    try {
        if (Test-Path $Path) {
            $File = Get-Item $Path -Force
            if ($File.Attributes -match "Hidden") { $File.Attributes = "Normal" }
        }
        $Json = $Data | ConvertTo-Json -Depth 2
        if (-not $Json) { $Json = "[]" }
        $Json | Set-Content -Path $Path -Force
        $File = Get-Item $Path -Force
        $File.Attributes = "Hidden"
        return $true
    } catch { return $false }
}

# Funzione per aggiornare la lista dei Drive nel menu a tendina
function Refresh-Drive-List {
    $cmbDrives.Items.Clear()
    $UniqueDrives = @{}
    
    foreach ($item in $CheckList.Items) {
        # Estrae la radice (es. "C:\")
        $root = [System.IO.Path]::GetPathRoot($item)
        if (-not $UniqueDrives.ContainsKey($root)) {
            $UniqueDrives[$root] = $true
            [void]$cmbDrives.Items.Add($root)
        }
    }
    
    if ($cmbDrives.Items.Count -gt 0) { $cmbDrives.SelectedIndex = 0 }
}

# --- GUI ---
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Ultimate Cleaner v7 (Safety & Drive Control)"
$Form.Size = New-Object System.Drawing.Size(700, 750) # Leggermente più alto
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$lblInfo = New-Object System.Windows.Forms.Label
$lblInfo.Text = "Inizializzazione..."
$lblInfo.AutoSize = $true
$lblInfo.Location = New-Object System.Drawing.Point(15, 10)
$lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$Form.Controls.Add($lblInfo)

# LISTA CARTELLE
$CheckList = New-Object System.Windows.Forms.CheckedListBox
$CheckList.Location = New-Object System.Drawing.Point(15, 40)
$CheckList.Size = New-Object System.Drawing.Size(650, 380)
$CheckList.CheckOnClick = $true
$CheckList.HorizontalScrollbar = $true
$Form.Controls.Add($CheckList)

# --- NUOVO PANNELLO CONTROLLO DRIVE ---
$grpDrive = New-Object System.Windows.Forms.GroupBox
$grpDrive.Text = "Gestione Rapida Unita'"
$grpDrive.Location = New-Object System.Drawing.Point(15, 430)
$grpDrive.Size = New-Object System.Drawing.Size(650, 60)
$Form.Controls.Add($grpDrive)

$lblDrive = New-Object System.Windows.Forms.Label
$lblDrive.Text = "Seleziona Disco:"
$lblDrive.Location = New-Object System.Drawing.Point(15, 25)
$lblDrive.AutoSize = $true
$grpDrive.Controls.Add($lblDrive)

$cmbDrives = New-Object System.Windows.Forms.ComboBox
$cmbDrives.Location = New-Object System.Drawing.Point(110, 22)
$cmbDrives.Width = 80
$cmbDrives.DropDownStyle = "DropDownList"
$grpDrive.Controls.Add($cmbDrives)

$btnSelDrive = New-Object System.Windows.Forms.Button
$btnSelDrive.Text = "Seleziona Tutto"
$btnSelDrive.Location = New-Object System.Drawing.Point(210, 20)
$btnSelDrive.Width = 120
$btnSelDrive.Add_Click({
    $Target = $cmbDrives.SelectedItem
    if ($Target) {
        for ($i=0; $i -lt $CheckList.Items.Count; $i++) {
            if ($CheckList.Items[$i].StartsWith($Target)) { $CheckList.SetItemChecked($i, $true) }
        }
    }
})
$grpDrive.Controls.Add($btnSelDrive)

$btnDeselDrive = New-Object System.Windows.Forms.Button
$btnDeselDrive.Text = "Deseleziona Tutto"
$btnDeselDrive.Location = New-Object System.Drawing.Point(340, 20)
$btnDeselDrive.Width = 120
$btnDeselDrive.Add_Click({
    $Target = $cmbDrives.SelectedItem
    if ($Target) {
        for ($i=0; $i -lt $CheckList.Items.Count; $i++) {
            if ($CheckList.Items[$i].StartsWith($Target)) { $CheckList.SetItemChecked($i, $false) }
        }
    }
})
$grpDrive.Controls.Add($btnDeselDrive)
# --------------------------------------

# Checkbox Cestino
$chkBin = New-Object System.Windows.Forms.CheckBox
$chkBin.Text = "Svuota anche il Cestino di Windows"
$chkBin.Location = New-Object System.Drawing.Point(20, 500)
$chkBin.Size = New-Object System.Drawing.Size(300, 20)
$chkBin.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$chkBin.Checked = $false
$Form.Controls.Add($chkBin)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Pronto."
$lblStatus.AutoSize = $false
$lblStatus.Size = New-Object System.Drawing.Size(650, 20)
$lblStatus.Location = New-Object System.Drawing.Point(15, 530)
$lblStatus.ForeColor = "Gray"
$Form.Controls.Add($lblStatus)

$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Location = New-Object System.Drawing.Point(15, 555)
$ProgressBar.Size = New-Object System.Drawing.Size(650, 25)
$Form.Controls.Add($ProgressBar)

# --- LOGICA RICERCA CON ESCLUSIONE SICURA ---
function Search-With-UI {
    $AllFound = New-Object System.Collections.Generic.List[string]
    $Drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' }
    
    $ProgressBar.Style = "Marquee"
    
    # LISTA NERA AVANZATA (Non entrare mai qui)
    $Blacklist = "WinSxS|Servicing|System Volume Information|\$Recycle.Bin|Windows.old|System32|SysWOW64|ProgramData|Boot|Recovery"

    foreach ($Drive in $Drives) {
        $Stack = New-Object System.Collections.Generic.Stack[string]
        $Stack.Push($Drive.RootDirectory.FullName)
        $Counter = 0

        while ($Stack.Count -gt 0) {
            $CurrentDir = $Stack.Pop()
            $Counter++
            if ($Counter % 50 -eq 0) {
                $lblStatus.Text = "Analisi: $CurrentDir"
                [System.Windows.Forms.Application]::DoEvents()
            }

            try {
                $SubDirs = [System.IO.Directory]::GetDirectories($CurrentDir)
                foreach ($Dir in $SubDirs) {
                    $Name = [System.IO.Path]::GetFileName($Dir)
                    
                    # Se trova cartella TEMP valida
                    if ($Name -eq "temp" -or $Name -eq "tmp") {
                        $AllFound.Add($Dir)
                        [void]$CheckList.Items.Add($Dir, $true)
                    }
                    
                    # Se la cartella NON è nella blacklist, continua a scendere
                    if ($Name -notmatch $Blacklist) { 
                        $Stack.Push($Dir) 
                    }
                }
            } catch { continue }
        }
    }
    
    Refresh-Drive-List
    $ProgressBar.Style = "Blocks"
    $ProgressBar.Value = 0
    $lblStatus.Text = "Trovate $($AllFound.Count) cartelle."
    return $AllFound
}

# --- BOTTONE PULISCI ---
$ButtonClean = New-Object System.Windows.Forms.Button
$ButtonClean.Text = "PULISCI ORA"
$ButtonClean.Location = New-Object System.Drawing.Point(15, 600)
$ButtonClean.Size = New-Object System.Drawing.Size(200, 50)
$ButtonClean.BackColor = "LightGreen"
$ButtonClean.Add_Click({
    $ButtonClean.Enabled = $false
    $CheckList.Enabled = $false
    $grpDrive.Enabled = $false
    $chkBin.Enabled = $false
    
    $ItemsCount = $CheckList.Items.Count
    $TotalBytesFreed = 0
    $TotalDeletedFiles = 0
    $TotalFailedFiles = 0
    $BinMsg = ""

    # SVUOTA CESTINO
    if ($chkBin.Checked) {
        $lblStatus.Text = "Svuotamento Cestino..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            $BinMsg = "`n[OK] Cestino svuotato."
        } catch { $BinMsg = "`n[!] Cestino vuoto o errore." }
    }

    if ($ItemsCount -gt 0) {
        $ProgressBar.Maximum = $ItemsCount
        $NewConfig = @()
        
        for ($i = 0; $i -lt $ItemsCount; $i++) {
            $Path = $CheckList.Items[$i]
            $IsChecked = $CheckList.GetItemChecked($i)
            
            $ProgressBar.Value = $i + 1
            $lblStatus.Text = "Pulizia ($($i+1)/$ItemsCount): $Path"
            [System.Windows.Forms.Application]::DoEvents()

            $NewConfig += [PSCustomObject]@{ Path = $Path; Selected = $IsChecked }

            if ($IsChecked) {
                if (Test-Path $Path) {
                    $SizeBefore = Get-FolderSize $Path
                    $CountBefore = Get-FileCount $Path
                    
                    # Calcola la data limite: elimina solo i file più vecchi di 24 ore (1 giorno)
					$limitDate = (Get-Date).AddDays(-1)

					# Elimina i file in modo sicuro controllando l'età
					Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
						Where-Object { $_.LastWriteTime -lt $limitDate } |
						Remove-Item -Force -ErrorAction SilentlyContinue

					# Pulisce le sottocartelle rimaste vuote
					Get-ChildItem -Path $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue |
						Where-Object { (Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue).Count -eq 0 } |
						Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    
                    $SizeAfter = Get-FolderSize $Path
                    $CountAfter = Get-FileCount $Path
                    
                    if ($SizeBefore -gt $SizeAfter) { $TotalBytesFreed += ($SizeBefore - $SizeAfter) }
                    if ($CountBefore -ge $CountAfter) { $TotalDeletedFiles += ($CountBefore - $CountAfter) }
                    $TotalFailedFiles += $CountAfter
                }
            }
        }
        Safe-Save-Config -Path $ConfigFile -Data $NewConfig
    }
    
    $lblStatus.Text = "Finito."
    $FormattedSize = Format-Size $TotalBytesFreed
    
    [System.Windows.Forms.MessageBox]::Show(
        "Report Pulizia Completo`n-----------------------`n" +
        "[OK] File eliminati: $TotalDeletedFiles`n" +
        "[!]  File in uso: $TotalFailedFiles`n" +
        "[OK] Spazio liberato: $FormattedSize`n" +
        "$BinMsg",
        "Risultato"
    )
    $Form.Close()
})
$Form.Controls.Add($ButtonClean)

# --- BOTTONE NUOVA RICERCA ---
$ButtonReset = New-Object System.Windows.Forms.Button
$ButtonReset.Text = "Nuova Ricerca"
$ButtonReset.Location = New-Object System.Drawing.Point(230, 600)
$ButtonReset.Size = New-Object System.Drawing.Size(150, 50)
$ButtonReset.Add_Click({
    if (Test-Path $ConfigFile) {
        try { (Get-Item $ConfigFile).Attributes = "Normal" } catch {}
        Remove-Item $ConfigFile -Force -ErrorAction SilentlyContinue
    }
    $CheckList.Items.Clear()
    $cmbDrives.Items.Clear()
    $lblInfo.Text = "Ricerca in corso..."
    Start-Sleep -Milliseconds 100
    $dummy = Search-With-UI
    $lblInfo.Text = "Seleziona cartelle da pulire:"
})
$Form.Controls.Add($ButtonReset)

# --- LOAD ---
$Form.Add_Shown({
    $Form.Refresh()
    if (Test-Path $ConfigFile) {
        $lblInfo.Text = "Caricamento config..."
        try {
            $JsonData = Get-Content $ConfigFile | ConvertFrom-Json
            if ($JsonData) {
                foreach ($item in $JsonData) { [void]$CheckList.Items.Add($item.Path, $item.Selected) }
                Refresh-Drive-List
            } else { throw "Vuoto" }
        } catch { $dummy = Search-With-UI }
        $lblInfo.Text = "Configurazione caricata."
    } else {
        $lblInfo.Text = "Prima esecuzione. Ricerca..."
        $dummy = Search-With-UI
        $lblInfo.Text = "Seleziona cartelle da pulire:"
    }
})

[void]$Form.ShowDialog()