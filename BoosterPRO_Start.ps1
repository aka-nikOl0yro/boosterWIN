function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -ErrorAction Stop
    } catch {
        Write-Error "Impossibile riavviare lo script come amministratore. Interruzione."
        Read-Host "Premere Invio per uscire."
    }
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ===================================================================
# === 0. HELPER & FIX ACCENTI ===
# ===================================================================
function Get-Txt {
    param($t)
    if ($null -eq $t) { return "" }
    $t = $t -replace "à", [char]224
    $t = $t -replace "è", [char]232
    $t = $t -replace "ì", [char]236
    $t = $t -replace "ò", [char]242
    $t = $t -replace "ù", [char]249
    $t = $t -replace "È", [char]200
    return $t
}

# ===================================================================
# === 1. LOGICA COLORI & LOGO DINAMICO (RIPRISTINATA) ===
# ===================================================================
try {
    $regColor = [Microsoft.Win32.Registry]::GetValue("HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM", "AccentColor", 0)
    if ($regColor -ne 0) {
        $r = $regColor -band 0xFF; $g = ($regColor -band 0xFF00) -shr 8; $b = ($regColor -band 0xFF0000) -shr 16
        $colorAccent = [System.Drawing.Color]::FromArgb(255, $r, $g, $b)
    } else { $colorAccent = [System.Drawing.Color]::FromArgb(0, 150, 255) }
} catch { $colorAccent = [System.Drawing.Color]::FromArgb(0, 150, 255) }

function Get-LogoColor {
    param($path)
    try {
        $bmp = New-Object System.Drawing.Bitmap($path)
        $sampleColor = $bmp.GetPixel($bmp.Width/2, $bmp.Height/2)
        $bmp.Dispose()
        return $sampleColor
    } catch { return [System.Drawing.Color]::White }
}

function Get-ColorDist {
    param($c1, $c2)
    return [Math]::Sqrt([Math]::Pow($c1.R - $c2.R, 2) + [Math]::Pow($c1.G - $c2.G, 2) + [Math]::Pow($c1.B - $c2.B, 2))
}

$logoFiles = @("$PSScriptRoot\src\LOGHO 1.png", "$PSScriptRoot\src\LOGHO 2.png", "$PSScriptRoot\src\LOGHO 3.png")
$bestLogo = $null
$minDist = 10000
foreach ($file in $logoFiles) {
    if (Test-Path $file) {
        $lColor = Get-LogoColor $file
        $dist = Get-ColorDist $lColor $colorAccent
        if ($dist -lt $minDist) { $minDist = $dist; $bestLogo = $file }
    }
}

$colorBg   = [System.Drawing.Color]::FromArgb(18, 18, 18)
$colorSide = [System.Drawing.Color]::FromArgb(12, 12, 12)
$colorRow  = [System.Drawing.Color]::FromArgb(25, 25, 25)
$colorText = [System.Drawing.Color]::FromArgb(230, 230, 230)

$GlobalState = @{
    SelectedRegistry = New-Object System.Collections.Generic.List[PSObject]
    SelectedInternet = New-Object System.Collections.Generic.List[PSObject]
    AppliedRegistry  = New-Object System.Collections.Generic.List[string]
    AppliedInternet  = New-Object System.Collections.Generic.List[string]
    ListViews        = New-Object System.Collections.Generic.List[System.Windows.Forms.ListView]
    CurrentInfo      = ""
}

# ===================================================================
# === 2. FUNZIONI DI STATO & NAVIGAZIONE ===
# ===================================================================
function Has-UnsavedChanges {
    if ($GlobalState.SelectedRegistry.Count -gt 0) { return $true }
    if ($GlobalState.SelectedInternet.Count -gt 0) { return $true }
    foreach ($lv in $GlobalState.ListViews) {
        if ($lv.CheckedItems.Count -gt 0) { return $true }
    }
    return $false
}

$lblGuide = New-Object System.Windows.Forms.Label
$lblGuide.Text = "Clicca sul pulsante 'SKIP' per selezionare i tweak da applicare"; $lblGuide.ForeColor = [System.Drawing.Color]::Gray; $lblGuide.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)
$lblGuide.AutoSize = $true; $lblGuide.Margin = New-Object System.Windows.Forms.Padding(10, 0, 0, 10)

function Update-UIState {
    param($ApplyBtn)
    $hasChanges = Has-UnsavedChanges
    $lblGuide.Visible = -not $hasChanges
    if ($null -ne $ApplyBtn) {
        if ($hasChanges) {
            $ApplyBtn.Enabled = $true
            $ApplyBtn.Text = $ApplyBtn.Tag.OriginalText
            $ApplyBtn.BackColor = $colorAccent
        }
    }
}

# ===================================================================
# === 3. COSTRUZIONE GUI ===
# ===================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "BoosterPRO Hub - Ultimate Edition"
$Form.Size = New-Object System.Drawing.Size(1000, 850)
$Form.BackColor = $colorBg
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

$RootTable = New-Object System.Windows.Forms.TableLayoutPanel
$RootTable.Dock = "Fill"; $RootTable.ColumnCount = 3
$RootTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 220))) | Out-Null
$RootTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$RootTable.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 0))) | Out-Null
$Form.Controls.Add($RootTable)

# --- SIDEBAR ---
$PanelSide = New-Object System.Windows.Forms.FlowLayoutPanel
$PanelSide.Dock = "Fill"; $PanelSide.BackColor = $colorSide; $PanelSide.FlowDirection = "TopDown"
$RootTable.Controls.Add($PanelSide, 0, 0)

$pbLogo = New-Object System.Windows.Forms.PictureBox
$pbLogo.Size = New-Object System.Drawing.Size(180, 100); $pbLogo.SizeMode = "Zoom"; $pbLogo.Margin = New-Object System.Windows.Forms.Padding(20, 30, 20, 20)
if ($bestLogo) { $pbLogo.Image = [System.Drawing.Image]::FromFile($bestLogo) }
$PanelSide.Controls.Add($pbLogo)

# --- AREA CENTRALE ---
$PanelCenter = New-Object System.Windows.Forms.TableLayoutPanel
$PanelCenter.Dock = "Fill"; $PanelCenter.RowCount = 2
$PanelCenter.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60))) | Out-Null
$PanelCenter.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$RootTable.Controls.Add($PanelCenter, 1, 0)

$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "BOOSTERPRO HUB"; $lblHeader.ForeColor = $colorAccent; $lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$lblHeader.TextAlign = "MiddleCenter"; $lblHeader.Dock = "Fill"
$PanelCenter.Controls.Add($lblHeader, 0, 0)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Appearance = "FlatButtons"; $TabControl.ItemSize = New-Object System.Drawing.Size(0, 1); $TabControl.SizeMode = "Fixed"; $TabControl.Dock = "Fill"
$PanelCenter.Controls.Add($TabControl, 0, 1)

# --- PANNELLO DETTAGLI ---
$PanelDetails = New-Object System.Windows.Forms.Panel
$PanelDetails.Dock = "Fill"; $PanelDetails.BackColor = $colorSide; $PanelDetails.Padding = New-Object System.Windows.Forms.Padding(25)
$RootTable.Controls.Add($PanelDetails, 2, 0)

$txtDetails = New-Object System.Windows.Forms.RichTextBox
$txtDetails.Dock = "Fill"; $txtDetails.BackColor = $colorSide; $txtDetails.ForeColor = $colorText; $txtDetails.BorderStyle = "None"; $txtDetails.ReadOnly = $true; $txtDetails.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$PanelDetails.Controls.Add($txtDetails)

$ToggleInfo = {
    param($Name, $Desc)
    if ($GlobalState.CurrentInfo -eq $Name) {
        $RootTable.ColumnStyles[2].Width = 0; $Form.Width = 1000; $GlobalState.CurrentInfo = ""
    } else {
        $txtDetails.Clear()
        $txtDetails.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold); $txtDetails.SelectionColor = $colorAccent
        $txtDetails.AppendText("$Name`r`n`r`n")
        $txtDetails.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 10); $txtDetails.SelectionColor = $colorText
        $txtDetails.AppendText($Desc)
        $RootTable.ColumnStyles[2].Width = 350; $Form.Width = 1350; $GlobalState.CurrentInfo = $Name
    }
}

# ===================================================================
# === 4. MODULI UI ===
# ===================================================================

function Add-NavBtn {
    param($Text, $Idx)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text; $btn.Size = New-Object System.Drawing.Size(220, 55); $btn.FlatStyle = "Flat"; $btn.FlatAppearance.BorderSize = 0; $btn.ForeColor = [System.Drawing.Color]::Gray; $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.TextAlign = "MiddleLeft"; $btn.Padding = New-Object System.Windows.Forms.Padding(25, 0, 0, 0)
    $btn.Add_Click({
        if (Has-UnsavedChanges) {
            [System.Windows.Forms.MessageBox]::Show("Applica le modifiche prima di cambiare sezione!", "Attenzione", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        $TabControl.SelectedIndex = $Idx
        foreach($c in $PanelSide.Controls) { if($c -is [System.Windows.Forms.Button]) { $c.ForeColor = [System.Drawing.Color]::Gray; $c.BackColor = $colorSide } }
        $this.ForeColor = $colorText; $this.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    }.GetNewClosure())
    $PanelSide.Controls.Add($btn)
}

function Create-ApplyPanel {
    param($ActionText, $ClearCallback)
    $p = New-Object System.Windows.Forms.Panel; $p.Height = 80; $p.Dock = "Bottom"; $p.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)
    $btn = New-Object System.Windows.Forms.Button; $btn.Text = $ActionText; $btn.Dock = "Fill"; $btn.FlatStyle = "Flat"; $btn.BackColor = $colorAccent; $btn.ForeColor = [System.Drawing.Color]::White; $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Tag = @{ OriginalText = $ActionText; IsSimulation = $true }
    $btn.Add_Click({
        if ($this.Tag.IsSimulation) { [System.Windows.Forms.MessageBox]::Show("Operazione completata con successo (Simulazione)", "BoosterPRO") }
        &$ClearCallback $this
        $this.Text = "COMPLETATO"
        $this.Enabled = $false
        $this.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
        Update-UIState $this
    }.GetNewClosure())
    $p.Controls.Add($btn)
    return $p
}

function Create-RealApplyPanel {
    param($ActionText, $ActionCallback)
    $p = New-Object System.Windows.Forms.Panel; $p.Height = 80; $p.Dock = "Bottom"; $p.Padding = New-Object System.Windows.Forms.Padding(20, 15, 20, 15)
    $btn = New-Object System.Windows.Forms.Button; $btn.Text = $ActionText; $btn.Dock = "Fill"; $btn.FlatStyle = "Flat"; $btn.BackColor = $colorAccent; $btn.ForeColor = [System.Drawing.Color]::White; $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btn.Tag = @{ OriginalText = $ActionText }
    $btn.Add_Click({
        $btn.Enabled = $false; $btn.Text = "IN ESECUZIONE..."; [System.Windows.Forms.Application]::DoEvents()
        &$ActionCallback $btn
        $btn.Text = "COMPLETATO"; $btn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
        Update-UIState $btn
    }.GetNewClosure())
    $p.Controls.Add($btn)
    return $p
}

# --- PAGE REGISTRO ---
$tpReg = New-Object System.Windows.Forms.TabPage; $tpReg.BackColor = $colorBg; $TabControl.TabPages.Add($tpReg) | Out-Null
$applyPanelReg = Create-RealApplyPanel "APPLICA TWEAK REGISTRO" {
    param($btn)
    $ids = $GlobalState.SelectedRegistry | ForEach-Object { $_.ID }
    if ($ids.Count -gt 0) {
        $regScript = Join-Path $PSScriptRoot "reg.ps1"
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$regScript`" -Silent -ApplyOnly @($($ids -join ','))"
        Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -Wait -WindowStyle Hidden
    }
    foreach($t in $GlobalState.SelectedRegistry) { $GlobalState.AppliedRegistry.Add($t.ID) }
    $GlobalState.SelectedRegistry.Clear()
    foreach($r in $flowReg.Controls) {
        foreach($c in $r.Controls) { if($c.Text -eq "OTTIMIZZA") { $c.Enabled = $false; $c.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30, 60, 40) } }
    }
}
$tpReg.Controls.Add($applyPanelReg)
$flowReg = New-Object System.Windows.Forms.FlowLayoutPanel; $flowReg.Dock = "Fill"; $flowReg.AutoScroll = $true; $tpReg.Controls.Add($flowReg)
$flowReg.Controls.Add($lblGuide); $flowReg.SetFlowBreak($lblGuide, $true)

# Hardware detection (per filtrare tweak CPU/OS-specifici)
$regCpu = Get-CimInstance Win32_Processor
$regCpuMan = $regCpu.Manufacturer.Trim()
$regRamGB = [Math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$isIntel = $regCpuMan -eq "GenuineIntel"
$isAmd   = $regCpuMan -eq "AuthenticAMD"
$isWin11Reg = (Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 22000

function Get-TweakAvailability($id) {
    switch ($id) {
        "INTEL_TSX"     { return $isIntel }
        "INTEL_BOOST"   { return $isIntel }
        "AMD_HPET"      { return $isAmd }
        "AMD_CORE_PARK" { return $isAmd }
        "UNLOADDLL"     { return $regRamGB -le 4 }
        "CLASSIC_CTX"   { return $isWin11Reg }
        "CLASSIC_RIBBON"{ return $isWin11Reg }
        "BYPASS_CHECK"  { return $isWin11Reg }
        "BLOCK_EDGE"    { return $isWin11Reg }
        default         { return $true }
    }
}

$RegistryTweaks = @(
    # ── PERFORMANCE ──
    [PSCustomObject]@{ ID = "KERNEL";        Name = "Kernel Timer Resolution";          Cat = "PERFORMANCE"; Desc = "PRO:`n- Migliora la reattività generale del sistema.`n- Ottimizza i timer CPU (TSC).`nCONTRO:`n- Rischio minimo di instabilità su hardware particolari." }
    [PSCustomObject]@{ ID = "MULTITASKING";  Name = "Multitasking (Snap/Alt+Tab/Focus)";Cat = "PERFORMANCE"; Desc = "PRO:`n- Disabilita Snap Assist fastidioso.`n- Alt+Tab mostra solo finestre aperte, niente schede Edge.`n- Impedisce alle app in background di rubare il focus.`nCONTRO:`n- Perdi layout finestre intelligente di Windows 11." }
    [PSCustomObject]@{ ID = "RAM_SCHED";     Name = "RAM Cleaner Automatico";           Cat = "PERFORMANCE"; Desc = "PRO:`n- Crea task pianificato che svuota Working Set RAM ogni 5 min.`n- Mantiene il sistema reattivo liberando memoria.`nCONTRO:`n- Aggiunge un task pianificato al sistema." }
    [PSCustomObject]@{ ID = "ULTIMATE_PERF"; Name = "Piano Prestazioni Eccellenti";      Cat = "PERFORMANCE"; Desc = "PRO:`n- Piano energetico piu' aggressivo, elimina micro-latenze CPU.`n- Ideale per gaming, produzione audio/video.`nCONTRO:`n- Aumenta consumo energetico e calore." }
    # ── PRIVACY ──
    [PSCustomObject]@{ ID = "WINUPDATE";     Name = "Blocca Driver Windows Update";      Cat = "PRIVACY";     Desc = "PRO:`n- Windows Update scarica SOLO patch sicurezza e Defender.`n- Impedisce sovrascrittura driver (GPU, Audio) con versioni generiche.`nCONTRO:`n- Dovrai aggiornare driver manualmente." }
    [PSCustomObject]@{ ID = "WUDO";          Name = "Disattiva P2P Updates";             Cat = "PRIVACY";     Desc = "PRO:`n- Impedisce a Windows di usare la tua banda per inviare aggiornamenti ad altri PC.`n- Migliora stabilita' connessione e ping.`nCONTRO:`n- PC nella stessa LAN dovranno scaricare aggiornamenti singolarmente." }
    [PSCustomObject]@{ ID = "BINGSEARCH";    Name = "Disattiva Bing Search";             Cat = "PRIVACY";     Desc = "PRO:`n- Ricerca Start piu' veloce, solo file locali.`n- Aumenta privacy evitando invio ricerche a Microsoft.`nCONTRO:`n- Perdi ricerca web dal menu Start." }
    [PSCustomObject]@{ ID = "SUGGESTED_APPS";Name = "Disattiva App Suggerite/Annunci";   Cat = "PRIVACY";     Desc = "PRO:`n- Rimuove annunci, app suggerite e consigli da Start e altre aree.`n- Esperienza utente piu' pulita.`nCONTRO:`n- Nessuno di rilevante." }
    [PSCustomObject]@{ ID = "AI";            Name = "Disattiva AI/Copilot";              Cat = "PRIVACY";     Desc = "PRO:`n- Migliora privacy impedendo analisi dati da funzioni AI.`n- Libera risorse e rimuove icona Copilot.`nCONTRO:`n- Perdi accesso rapido a Copilot." }
    [PSCustomObject]@{ ID = "PRINTER";       Name = "Disabilita Servizio Stampa";        Cat = "PRIVACY";     Desc = "PRO:`n- Libera RAM e risorse CPU se non usi stampanti.`n- Chiude vulnerabilita' Spooler.`nCONTRO:`n- Impossibile stampare finche' il servizio non viene riattivato." }
    # ── GAMING ──
    [PSCustomObject]@{ ID = "GAMEBAR";       Name = "Disattiva Game Bar/DVR";            Cat = "GAMING";      Desc = "PRO:`n- Libera risorse se non registri clip di gioco.`n- Elimina popup 'Come vuoi aprire questo collegamento?' disabilitando i protocolli ms-gamebar e ms-gamingoverlay.`nCONTRO:`n- Rompe funzionalita' Xbox, invito amici e registrazione clip." }
    [PSCustomObject]@{ ID = "GAMING_NET";    Name = "Rete Avanzata Gaming";              Cat = "GAMING";      Desc = "PRO:`n- Riduce latenza di rete (ping) disabilitando RSC e moderazione interrupt.`nCONTRO:`n- Aumenta leggermente carico CPU." }
    [PSCustomObject]@{ ID = "STICKYKEYS";    Name = "Disattiva Tasti Permanenti";         Cat = "GAMING";      Desc = "PRO:`n- Evita finestra 5xShift nei giochi FPS.`nCONTRO:`n- Rende piu' difficile attivazione accessibilità." }
    # ── WINDOWS 11 ──
    [PSCustomObject]@{ ID = "CLASSIC_CTX";   Name = "Menu Contestuale Classico";         Cat = "WINDOWS 11";  Desc = "PRO:`n- Mostra subito tutte le opzioni senza passaggio Mostra altre opzioni.`nCONTRO:`n- Perdi menu minimale di Windows 11." }
    [PSCustomObject]@{ ID = "CLASSIC_RIBBON";Name = "Ribbon Classico Esplora File";      Cat = "WINDOWS 11";  Desc = "PRO:`n- Ripristina barra multifunzione completa di Windows 10.`nCONTRO:`n- Perdi barra comandi semplificata di Windows 11." }
    [PSCustomObject]@{ ID = "LOCKSCREEN_BLUR";Name = "Disattiva Sfocatura Blocco";       Cat = "WINDOWS 11";  Desc = "PRO:`n- Immagine sfondo login nitida.`n- Leggermente piu' veloce su PC datati.`nCONTRO:`n- Si perde effetto acrilico." }
    [PSCustomObject]@{ ID = "TASKBAR_SEC";   Name = "Secondi Orologio Taskbar";          Cat = "WINDOWS 11";  Desc = "PRO:`n- Visualizza ora con precisione al secondo.`nCONTRO:`n- Consumo CPU leggermente superiore." }
    [PSCustomObject]@{ ID = "BLOCK_EDGE";    Name = "Blocca Reinstallazione Edge";       Cat = "WINDOWS 11";  Desc = "PRO:`n- Impedisce a Windows Update di reinstallare Edge/Chat.`nCONTRO:`n- Nessuno se non usi browser Microsoft." }
    [PSCustomObject]@{ ID = "BYPASS_CHECK";  Name = "Bypass TPM/Secure Boot";            Cat = "WINDOWS 11";  Desc = "PRO:`n- Permette installazione Windows 11 su hardware non supportato.`nCONTRO:`n- Microsoft potrebbe negare aggiornamenti futuri." }
    # ── NETWORK ──
    [PSCustomObject]@{ ID = "IPV6";          Name = "Disabilita IPv6";                   Cat = "NETWORK";     Desc = "PRO:`n- Risolve rari problemi di connettività/lentezza su reti senza IPv6.`nCONTRO:`n- Soluzione temporanea, IPv6 e' il futuro." }
    [PSCustomObject]@{ ID = "DNSCLIENT";     Name = "Disabilita Client DNS";             Cat = "NETWORK";     Desc = "PRO:`n- Query DNS dirette al server, risultati sempre freschi.`nCONTRO:`n- Potrebbe rallentare navigazione web senza cache." }
    [PSCustomObject]@{ ID = "DESKTOP_ICONS"; Name = "Icone Classiche Desktop";           Cat = "NETWORK";     Desc = "PRO:`n- Aggiunge Questo PC, Rete e Pannello di Controllo sul desktop.`nCONTRO:`n- Aggiunge icone sul desktop." }
    # ── CPU ──
    [PSCustomObject]@{ ID = "INTEL_TSX";     Name = "Disabilita TSX (Intel)";            Cat = "CPU";         Desc = "PRO:`n- Aumenta sicurezza chiudendo vulnerabilità hardware.`n- Migliora stabilità in giochi/app.`nCONTRO:`n- Perde potenziale aumento prestazioni." }
    [PSCustomObject]@{ ID = "INTEL_BOOST";   Name = "Boost CPU Aggressivo (Intel)";      Cat = "CPU";         Desc = "PRO:`n- Gestione frequenza aggressiva, migliora reattività.`nCONTRO:`n- Leggero aumento consumi e temperature." }
    [PSCustomObject]@{ ID = "AMD_HPET";      Name = "Disabilita HPET (AMD)";             Cat = "CPU";         Desc = "PRO:`n- Forza timer TSC CPU, piu' veloce su Ryzen.`n- Riduce latenza in giochi.`nCONTRO:`n- Rari problemi di sincronizzazione." }
    [PSCustomObject]@{ ID = "AMD_CORE_PARK"; Name = "Core Parking Off (AMD)";            Cat = "CPU";         Desc = "PRO:`n- Mantiene tutti i core attivi, riduce micro-latenze.`nCONTRO:`n- Aumenta consumi e temperature a riposo." }
    [PSCustomObject]@{ ID = "UNLOADDLL";     Name = "Forza Unload DLL (RAM < 4GB)";      Cat = "CPU";         Desc = "PRO:`n- Forza rimozione DLL dalla RAM appena chiuse.`nCONTRO:`n- Rischioso: puo' causare rallentamenti e instabilita'." }
)

$lastCat = ""
foreach ($t in $RegistryTweaks) {
    if ($t.Cat -ne $lastCat) {
        $lastCat = $t.Cat
        $catRow = New-Object System.Windows.Forms.Panel; $catRow.Size = New-Object System.Drawing.Size(720, 30); $catRow.BackColor = $colorBg; $catRow.Margin = New-Object System.Windows.Forms.Padding(10, 10, 10, 0)
        $catLbl = New-Object System.Windows.Forms.Label; $catLbl.Text = "---  $($t.Cat)  ---"; $catLbl.ForeColor = [System.Drawing.Color]::DimGray; $catLbl.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold); $catLbl.Location = New-Object System.Drawing.Point(20, 8); $catLbl.AutoSize = $true
        $catRow.Controls.Add($catLbl); $flowReg.Controls.Add($catRow)
    }
    $avail = Get-TweakAvailability $t.ID
    $row = New-Object System.Windows.Forms.Panel; $row.Size = New-Object System.Drawing.Size(720, 44); $row.BackColor = if ($avail) { $colorRow } else { [System.Drawing.Color]::FromArgb(18, 18, 18) }; $row.Margin = New-Object System.Windows.Forms.Padding(10, 2, 10, 2)
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $t.Name; $lbl.ForeColor = if ($avail) { $colorText } else { [System.Drawing.Color]::DimGray }; $lbl.Location = New-Object System.Drawing.Point(20, 14); $lbl.AutoSize = $true
    
    $btnD = New-Object System.Windows.Forms.Button; $btnD.Text = "DETTAGLI"; $btnD.Size = New-Object System.Drawing.Size(90, 30); $btnD.Location = New-Object System.Drawing.Point(430, 7); $btnD.FlatStyle = "Flat"; $btnD.ForeColor = $colorAccent; $btnD.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)
    if (-not $avail) { $btnD.Enabled = $false }
    $capturedT = $t
    $btnD.Add_Click({ &$ToggleInfo $capturedT.Name $capturedT.Desc }.GetNewClosure())
    
    $btnS = New-Object System.Windows.Forms.Button; $btnS.Size = New-Object System.Drawing.Size(110, 30); $btnS.Location = New-Object System.Drawing.Point(530, 7); $btnS.FlatStyle = "Flat"
    if ($avail) {
        $btnS.Text = "SKIP"; $btnS.ForeColor = [System.Drawing.Color]::Gray; $btnS.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)
        $btnS.Add_Click({
            if ($this.Text -eq "SKIP") { 
                $this.Text = "OTTIMIZZA"; $this.ForeColor = [System.Drawing.Color]::SeaGreen; $this.FlatAppearance.BorderColor = [System.Drawing.Color]::SeaGreen; $GlobalState.SelectedRegistry.Add($capturedT) 
            } else { 
                $this.Text = "SKIP"; $this.ForeColor = [System.Drawing.Color]::Gray; $this.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60); $GlobalState.SelectedRegistry.Remove($capturedT)
            }
            Update-UIState ($applyPanelReg.Controls[0])
        }.GetNewClosure())
    } else {
        $incompat = "N/A"
        if ($t.ID -eq "UNLOADDLL") { $incompat = "Servono < 4GB RAM" }
        elseif ($t.ID -like "INTEL*") { $incompat = "Solo CPU Intel" }
        elseif ($t.ID -like "AMD*") { $incompat = "Solo CPU AMD" }
        elseif (-not $isWin11Reg) { $incompat = "Solo Win11" }
        $btnS.Text = $incompat; $btnS.Enabled = $false; $btnS.ForeColor = [System.Drawing.Color]::DimGray; $btnS.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(30,30,30)
    }
    
    $row.Controls.Add($lbl); $row.Controls.Add($btnD); $row.Controls.Add($btnS); $flowReg.Controls.Add($row)
}

# --- PAGE INTERNET ---
$tpNet = New-Object System.Windows.Forms.TabPage; $tpNet.BackColor = $colorBg; $TabControl.TabPages.Add($tpNet) | Out-Null
$applyPanelNet = Create-RealApplyPanel "OTTIMIZZA CONNESSIONE" {
    param($btn)
    $ids = $GlobalState.SelectedInternet | ForEach-Object { $_.ID }
    if ($ids.Count -gt 0) {
        $netScript = Join-Path $PSScriptRoot "src\internet.ps1"
        $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$netScript`" -Silent -ApplyOnly @($($ids -join ','))"
        Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -Wait -WindowStyle Hidden
    }
    foreach($t in $GlobalState.SelectedInternet) { $GlobalState.AppliedInternet.Add($t.ID) }
    $GlobalState.SelectedInternet.Clear()
    foreach($r in $flowNet.Controls) {
        foreach($c in $r.Controls) { if($c.Text -eq "ON") { $c.Enabled = $false; $c.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 80, 40) } }
    }
}
$tpNet.Controls.Add($applyPanelNet)
$flowNet = New-Object System.Windows.Forms.FlowLayoutPanel; $flowNet.Dock = "Fill"; $flowNet.AutoScroll = $true; $tpNet.Controls.Add($flowNet)

$InternetTweaks = @(
    [PSCustomObject]@{ ID = "AUTOTUNE";  Name = "TCP AutoTuning + CTCP";     Desc = "PRO:`n- Imposta AutoTuningLevel su normale per banda stabile.`n- Disabilita ScalingHeuristics.`n- Abilita CTCP congestion provider.`nCONTRO:`n- Nessuno." }
    [PSCustomObject]@{ ID = "SCALING";   Name = "Max Connessioni + Priorità"; Desc = "PRO:`n- Aumenta MaxConnectionsPerServer da 6 a 20.`n- Ottimizza priorità ServiceProvider.`nCONTRO:`n- Nessuno." }
    [PSCustomObject]@{ ID = "THROTTLING";Name = "Network Throttling Index";   Desc = "PRO:`n- Riduce NetworkThrottlingIndex a 10 per banda piu' fluida.`nCONTRO:`n- Nessuno." }
    [PSCustomObject]@{ ID = "NETRESET";  Name = "Reset Stack TCP/IP";         Desc = "PRO:`n- Esegue winsock reset, IP reset, flushdns, renew.`n- Risolve molti problemi di connettivita' dopo le modifiche.`nCONTRO:`n- Richiede riavvio per completare il reset.`n- Disconnessione di rete momentanea." }
    [PSCustomObject]@{ ID = "ALL";       Name = "TUTTO (AUTOTUNE+SCALING+THROTTLING+NETRESET+extra)"; Desc = "PRO:`n- Applica OGNI ottimizzazione: AUTOTUNE, SCALING, THROTTLING, NETRESET.`n- Imposta ECN, Timestamps, MTU, MaxUserPort, TcpTimedWaitDelay.`n- Reset completo stack TCP/IP.`nCONTRO:`n- Modifiche estese ai parametri di rete." }
)

foreach ($t in $InternetTweaks) {
    $row = New-Object System.Windows.Forms.Panel; $row.Size = New-Object System.Drawing.Size(720, 60); $row.BackColor = $colorRow; $row.Margin = New-Object System.Windows.Forms.Padding(10, 5, 10, 5)
    $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $t.Name; $lbl.ForeColor = $colorText; $lbl.Location = New-Object System.Drawing.Point(20, 20); $lbl.AutoSize = $true
    $btn = New-Object System.Windows.Forms.Button; $btn.Text = "OFF"; $btn.Size = New-Object System.Drawing.Size(80, 32); $btn.Location = New-Object System.Drawing.Point(580, 14); $btn.FlatStyle = "Flat"; $btn.ForeColor = [System.Drawing.Color]::Gray
    $btn.Add_Click({
        if ($this.Text -eq "OFF") { 
            $this.Text = "ON"; $this.ForeColor = $colorAccent; $this.FlatAppearance.BorderColor = $colorAccent; $GlobalState.SelectedInternet.Add($t) 
        } else { 
            $this.Text = "OFF"; $this.ForeColor = [System.Drawing.Color]::Gray; $this.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60); $GlobalState.SelectedInternet.Remove($t) 
        }
        Update-UIState ($applyPanelNet.Controls[0])
    }.GetNewClosure())
    $row.Controls.Add($lbl); $row.Controls.Add($btn); $flowNet.Controls.Add($row)
}

$PanelNetExt = New-Object System.Windows.Forms.FlowLayoutPanel; $PanelNetExt.Height = 100; $PanelNetExt.Dock = "Bottom"; $PanelNetExt.Padding = New-Object System.Windows.Forms.Padding(20, 5, 20, 5); $tpNet.Controls.Add($PanelNetExt)
$lblExt = New-Object System.Windows.Forms.Label; $lblExt.Text = "UTILITY RAPIDE"; $lblExt.ForeColor = [System.Drawing.Color]::Gray; $lblExt.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold); $lblExt.AutoSize = $true; $PanelNetExt.Controls.Add($lblExt)
$PanelNetExt.SetFlowBreak($lblExt, $true)

$btnEdge = New-Object System.Windows.Forms.Button; $btnEdge.Text = "EDGE"; $btnEdge.Size = New-Object System.Drawing.Size(100, 30); $btnEdge.FlatStyle = "Flat"; $btnEdge.ForeColor = $colorText; $btnEdge.FlatAppearance.BorderColor = $colorAccent
$btnEdge.Add_Click({ Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\src\Ottimizza_edge.ps1`"" -Verb RunAs -WindowStyle Hidden })
$PanelNetExt.Controls.Add($btnEdge)

$btnWebViewOpt = New-Object System.Windows.Forms.Button; $btnWebViewOpt.Text = "WEBVIEW2"; $btnWebViewOpt.Size = New-Object System.Drawing.Size(100, 30); $btnWebViewOpt.FlatStyle = "Flat"; $btnWebViewOpt.ForeColor = $colorText; $btnWebViewOpt.FlatAppearance.BorderColor = $colorAccent
$btnWebViewOpt.Add_Click({ Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\src\webview_opt.ps1`"" -Verb RunAs -WindowStyle Hidden })
$PanelNetExt.Controls.Add($btnWebViewOpt)

$btnWebViewClean = New-Object System.Windows.Forms.Button; $btnWebViewClean.Text = "CLEAN CACHE"; $btnWebViewClean.Size = New-Object System.Drawing.Size(100, 30); $btnWebViewClean.FlatStyle = "Flat"; $btnWebViewClean.ForeColor = $colorText; $btnWebViewClean.FlatAppearance.BorderColor = $colorAccent
$btnWebViewClean.Add_Click({ Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\src\Pulisci_chache_webview.ps1`"" -Verb RunAs -WindowStyle Hidden })
$PanelNetExt.Controls.Add($btnWebViewClean)

# --- PAGE DEBLOAT ---
$tpDebloat = New-Object System.Windows.Forms.TabPage; $tpDebloat.BackColor = $colorBg; $TabControl.TabPages.Add($tpDebloat) | Out-Null

$supportsAllUsers = ([System.Environment]::OSVersion.Version.Build -ge 15063)

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
    "Microsoft.YourPhone*"                    = "Phone Link (Win10)"
    "MicrosoftCorporationII.YourPhone*"       = "Phone Link (Win11)"
    "MicrosoftCorporationII.MicrosoftFamily*" = "Family Safety"
    "Microsoft.Clipchamp*"                    = "Clipchamp"
}
$usefulApps = [ordered]@{
    "Microsoft.MicrosoftStickyNotes*"      = "Sticky Notes"
    "Microsoft.WindowsAlarms*"             = "Sveglie e Orologio"
    "Microsoft.WindowsCamera*"             = "Fotocamera"
    "Microsoft.WindowsSoundRecorder*"      = "Registratore Suoni"
    "Microsoft.Todos*"                     = "Microsoft To Do"
    "Microsoft.OutlookForWindows*"         = "Outlook"
    "Microsoft.WindowsCommunicationsApps*" = "Posta e Calendario"
    "MicrosoftCorporationII.QuickAssist*"  = "Assistenza Rapida"
    "Microsoft.Xbox.TCUI*"                 = "Xbox TCUI"
    "Microsoft.XboxApp*"                   = "Xbox App (Win10)"
    "Microsoft.GamingApp*"                 = "Xbox App (Win11)"
    "Microsoft.XboxIdentityProvider*"      = "Xbox Identity Provider"
    "Microsoft.XboxSpeechToTextOverlay*"   = "Xbox Speech Overlay"
    "Microsoft.XboxGameOverlay*"           = "Xbox Game Overlay"
    "Microsoft.XboxGamingOverlay*"         = "Xbox Gaming Overlay"
}

function Add-RemoveApp {
    param($appId, $logBox)
    $packages = Get-AppxPackage -Name $appId -AllUsers -ErrorAction SilentlyContinue
    if (-not $packages) {
        $logBox.AppendText("[--] Non installata: $appId`r`n")
    } else {
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
            $removed = $false
            if ($supportsAllUsers) {
                try { Remove-AppxPackage -Package $package.PackageFullName -AllUsers -ErrorAction Stop; $logBox.AppendText("[OK] Rimossa: $($package.Name)`r`n"); $removed = $true } catch {}
            }
            if (-not $removed) {
                try { Remove-AppxPackage -Package $package.PackageFullName -ErrorAction Stop; $logBox.AppendText("[OK] Rimossa: $($package.Name)`r`n"); $removed = $true } catch { $logBox.AppendText("[!!] Errore: $($package.Name)`r`n") }
            }
            $logBox.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
        }
    }
    $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $appId }
    foreach ($prov in $provisioned) {
        try { Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop | Out-Null; $logBox.AppendText("[OK] Provisioned rimosso: $($prov.DisplayName)`r`n") } catch { $logBox.AppendText("[!!] Errore provisioned: $($prov.DisplayName)`r`n") }
        $logBox.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
    }
}

$installedPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
function Test-AppInstalled($appId) { return [bool]($installedPackages -like $appId) }

# Build debloat UI
$debloatOuterPanel = New-Object System.Windows.Forms.Panel; $debloatOuterPanel.Dock = "Fill"; $debloatOuterPanel.Padding = New-Object System.Windows.Forms.Padding(0,0,0,0)
$tpDebloat.Controls.Add($debloatOuterPanel)

$nestedTab = New-Object System.Windows.Forms.TabControl; $nestedTab.Dock = "Fill"; $nestedTab.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$debloatOuterPanel.Controls.Add($nestedTab)

$debloatListViews = @{}
$debloatStatus = @{}

function Build-DebloatListView ($parent, $appDict, $defChecked) {
    $tab = New-Object System.Windows.Forms.TabPage; $tab.Text = $parent; $tab.BackColor = $colorBg; $nestedTab.Controls.Add($tab)
    $lv = New-Object System.Windows.Forms.ListView; $lv.Dock = "Fill"; $lv.View = "Details"; $lv.CheckBoxes = $true; $lv.FullRowSelect = $true; $lv.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20); $lv.ForeColor = $colorText; $lv.BorderStyle = "None"
    $lv.Columns.Add("App", 250) | Out-Null; $lv.Columns.Add("ID Pacchetto", 280) | Out-Null; $lv.Columns.Add("Stato", 100) | Out-Null
    $status = @{}
    foreach ($key in $appDict.Keys) {
        $installed = Test-AppInstalled $key
        $status[$key] = $installed
        $item = New-Object System.Windows.Forms.ListViewItem($appDict[$key]); $item.SubItems.Add($key) | Out-Null
        if ($installed) { $item.SubItems.Add("Installata") | Out-Null; $item.Checked = $defChecked; $item.BackColor = [System.Drawing.Color]::FromArgb(20, 50, 20); $item.ForeColor = [System.Drawing.Color]::LightGreen }
        else { $item.SubItems.Add("Non installata") | Out-Null; $item.Checked = $false; $item.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35); $item.ForeColor = [System.Drawing.Color]::Gray }
        $item.Tag = $key; $lv.Items.Add($item) | Out-Null
    }
    $lv.Add_ItemCheck({
        param($s, $e)
        $clicked = $s.Items[$e.Index]
        if ($clicked.BackColor -eq [System.Drawing.Color]::FromArgb(35, 35, 35)) { $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked }
    })
    $tab.Controls.Add($lv)
    return @{ListView = $lv; Status = $status}
}

$bloatResult = Build-DebloatListView "Bloatware Comune" $bloatwareApps $true
$usefulResult = Build-DebloatListView "App Potenzialmente Utili" $usefulApps $false
$win32Result = Build-DebloatListView "Win32 / Altro" @{"__Edge__"="Microsoft Edge  [richiede riavvio]"; "__OneDrive__"="Microsoft OneDrive"} $false

# --- Select/Deselect buttons + Log ---
$debloatBottomPanel = New-Object System.Windows.Forms.Panel; $debloatBottomPanel.Height = 200; $debloatBottomPanel.Dock = "Bottom"; $debloatBottomPanel.BackColor = $colorBg
$tpDebloat.Controls.Add($debloatBottomPanel)

$btnSelAll = New-Object System.Windows.Forms.Button; $btnSelAll.Text = "SELEZIONA TUTTO"; $btnSelAll.Location = New-Object System.Drawing.Point(15, 8); $btnSelAll.Size = New-Object System.Drawing.Size(140, 30); $btnSelAll.FlatStyle = "Flat"; $btnSelAll.ForeColor = $colorAccent; $btnSelAll.FlatAppearance.BorderColor = $colorAccent
$btnDeselAll = New-Object System.Windows.Forms.Button; $btnDeselAll.Text = "DESELEZIONA TUTTO"; $btnDeselAll.Location = New-Object System.Drawing.Point(165, 8); $btnDeselAll.Size = New-Object System.Drawing.Size(140, 30); $btnDeselAll.FlatStyle = "Flat"; $btnDeselAll.ForeColor = [System.Drawing.Color]::Gray; $btnDeselAll.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)

$debloatLog = New-Object System.Windows.Forms.RichTextBox; $debloatLog.Location = New-Object System.Drawing.Point(15, 45); $debloatLog.Size = New-Object System.Drawing.Size(720, 110); $debloatLog.ReadOnly = $true; $debloatLog.BackColor = [System.Drawing.Color]::Black; $debloatLog.ForeColor = [System.Drawing.Color]::LightGreen; $debloatLog.Font = New-Object System.Drawing.Font("Consolas", 9); $debloatLog.ScrollBars = "Vertical"

$btnApplyDebloat = New-Object System.Windows.Forms.Button; $btnApplyDebloat.Text = "RIMUOVI SELEZIONATE"; $btnApplyDebloat.Location = New-Object System.Drawing.Point(490, 8); $btnApplyDebloat.Size = New-Object System.Drawing.Size(245, 32); $btnApplyDebloat.FlatStyle = "Flat"; $btnApplyDebloat.BackColor = $colorAccent; $btnApplyDebloat.ForeColor = [System.Drawing.Color]::White; $btnApplyDebloat.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnApplyDebloat.Add_Click({
    $btnApplyDebloat.Enabled = $false; $btnSelAll.Enabled = $false; $btnDeselAll.Enabled = $false
    $selectedBloat = @(); foreach($item in $bloatResult.ListView.Items) { if($item.Checked) { $selectedBloat += $item.Tag } }
    $selectedUseful = @(); foreach($item in $usefulResult.ListView.Items) { if($item.Checked) { $selectedUseful += $item.Tag } }
    $selectedWin32 = @(); foreach($item in $win32Result.ListView.Items) { if($item.Checked) { $selectedWin32 += $item } }
    $total = $selectedBloat.Count + $selectedUseful.Count + $selectedWin32.Count
    if ($total -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nessuna app selezionata.", "Attenzione"); $btnApplyDebloat.Enabled = $true; $btnSelAll.Enabled = $true; $btnDeselAll.Enabled = $true; return }
    $debloatLog.AppendText("=== Inizio rimozione: $total app selezionate ===`r`n")
    [System.Windows.Forms.Application]::DoEvents()
    if ($selectedBloat.Count -gt 0) { $debloatLog.AppendText("`r`n--- Bloatware Comune ---`r`n"); foreach($id in $selectedBloat) { Add-RemoveApp -appId $id -logBox $debloatLog } }
    if ($selectedUseful.Count -gt 0) { $debloatLog.AppendText("`r`n--- App Potenzialmente Utili ---`r`n"); foreach($id in $selectedUseful) { Add-RemoveApp -appId $id -logBox $debloatLog } }
    # Telemetry tasks
    $debloatLog.AppendText("`r`n--- Disabilitazione task telemetria ---`r`n"); [System.Windows.Forms.Application]::DoEvents()
    $tasks = @("ProgramDataUpdater","Microsoft-Windows-DiskDiagnosticDataCollector","Microsoft-Windows-WER-Triggered","RegIdleBackup","DmClient","TileDataDownloader","RestartBPT","DownloadContentTask","AppIDManagement","Application Crash Telemetry","Autotune","AitAgent","XblGameSaveTask","StartupAppTask","WDI Run Downloader Task","WinSAT")
    foreach ($task in $tasks) { try { Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Disable-ScheduledTask -ErrorAction SilentlyContinue; $debloatLog.AppendText("[OK] Task disabilitato: $task`r`n") } catch { $debloatLog.AppendText("[--] Task non trovato: $task`r`n") }; $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }
    # Telemetry services
    $debloatLog.AppendText("`r`n--- Disabilitazione servizi telemetria ---`r`n"); [System.Windows.Forms.Application]::DoEvents()
    $services = @("diagnosticshub.standardcollector.service","DiagTrack","dmwappushservice")
    foreach ($svc in $services) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue; $debloatLog.AppendText("[OK] Servizio disabilitato: $svc`r`n") } catch { $debloatLog.AppendText("[--] Servizio non trovato: $svc`r`n") }; $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents() }
    # SysMain on SSD
    try { $systemDrive = Get-PhysicalDisk | Where-Object { $_.DeviceID -match (Get-Partition | Where-Object { $_.DriveLetter -eq 'C' }).DiskNumber }; if ($systemDrive.MediaType -eq 'SSD') { Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction Stop; Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue; $debloatLog.AppendText("[OK] SysMain disabilitato (SSD rilevato).`r`n") } else { $debloatLog.AppendText("[--] SysMain mantenuto (HDD rilevato).`r`n") } } catch { $debloatLog.AppendText("[!!] Impossibile determinare tipo disco.`r`n") }; $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
    # fotoenable.reg
    $regFile = Join-Path $PSScriptRoot "src\fotoenable.reg"; if (Test-Path $regFile) { try { reg.exe import $regFile 2>&1 | Out-Null; $debloatLog.AppendText("[OK] fotoenable.reg importato.`r`n") } catch { $debloatLog.AppendText("[!!] Errore fotoenable.reg`r`n") } }
    # Win32 removals
    foreach ($win32Item in $selectedWin32) {
        switch ($win32Item.Tag) {
            "__OneDrive__" {
                $debloatLog.AppendText("`r`n--- Rimozione OneDrive ---`r`n"); [System.Windows.Forms.Application]::DoEvents()
                try { Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; $setup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"; $setup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"; if (Test-Path $setup64) { Start-Process -FilePath $setup64 -ArgumentList "/uninstall /silent" -Wait; $debloatLog.AppendText("[OK] OneDrive rimosso.`r`n") } elseif (Test-Path $setup32) { Start-Process -FilePath $setup32 -ArgumentList "/uninstall /silent" -Wait; $debloatLog.AppendText("[OK] OneDrive rimosso.`r`n") } else { $debloatLog.AppendText("[--] OneDriveSetup.exe non trovato.`r`n") }; Start-Sleep -Seconds 2; Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue; Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue -Force; Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force; Remove-Item -Path "Registry::HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Recurse -ErrorAction SilentlyContinue -Force; "$env:USERPROFILE\OneDrive","$env:LOCALAPPDATA\Microsoft\OneDrive","$env:PROGRAMDATA\Microsoft OneDrive","C:\OneDriveTemp" | ForEach-Object { if (Test-Path $_) { Remove-Item -Path $_ -Recurse -Force -ErrorAction SilentlyContinue } } } catch { $debloatLog.AppendText("[!!] Errore OneDrive: $_`r`n") }; $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
            }
            "__Edge__" {
                $debloatLog.AppendText("`r`n--- Rimozione Microsoft Edge ---`r`n"); [System.Windows.Forms.Application]::DoEvents()
                try { $edgeSetup = Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -Last 1; if ($edgeSetup) { Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 2; Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait; $debloatLog.AppendText("[OK] Edge rimosso. Riavvio necessario.`r`n") } else { $debloatLog.AppendText("[--] Setup Edge non trovato.`r`n") } } catch { $debloatLog.AppendText("[!!] Errore Edge: $_`r`n") }; $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents()
            }
        }
    }
    $debloatLog.AppendText("`r`n=== Completato. Riavvio Esplora File... ===`r`n"); $debloatLog.ScrollToCaret(); [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Seconds 1; Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1; Start-Process "explorer.exe"
    $btnApplyDebloat.Text = "COMPLETATO"; $btnApplyDebloat.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
})
$debloatBottomPanel.Controls.Add($btnSelAll); $debloatBottomPanel.Controls.Add($btnDeselAll); $debloatBottomPanel.Controls.Add($debloatLog); $debloatBottomPanel.Controls.Add($btnApplyDebloat)

$btnSelAll.Add_Click({
    $activeTab = $nestedTab.SelectedTab
    $result = if ($activeTab -eq $nestedTab.TabPages[0]) { $bloatResult } elseif ($activeTab -eq $nestedTab.TabPages[1]) { $usefulResult } else { $win32Result }
    foreach ($item in $result.ListView.Items) { if ($item.ForeColor -ne [System.Drawing.Color]::Gray) { $item.Checked = $true } }
})
$btnDeselAll.Add_Click({
    $activeTab = $nestedTab.SelectedTab
    $result = if ($activeTab -eq $nestedTab.TabPages[0]) { $bloatResult } elseif ($activeTab -eq $nestedTab.TabPages[1]) { $usefulResult } else { $win32Result }
    foreach ($item in $result.ListView.Items) { $item.Checked = $false }
})

# --- PAGE SOFTWARE ---
$tpSoft = New-Object System.Windows.Forms.TabPage; $tpSoft.BackColor = $colorBg; $TabControl.TabPages.Add($tpSoft) | Out-Null

$softOuterPanel = New-Object System.Windows.Forms.Panel; $softOuterPanel.Dock = "Fill"; $softOuterPanel.Padding = New-Object System.Windows.Forms.Padding(0,0,0,0)
$tpSoft.Controls.Add($softOuterPanel)

$softTab = New-Object System.Windows.Forms.TabControl; $softTab.Dock = "Fill"; $softTab.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$softOuterPanel.Controls.Add($softTab)

$microsoftApps = [ordered]@{
    "9WZDNCRFHVFW" = "Notizie Bing"
    "9PKDZBMV1H3T" = "Assistenza (Get Help)"
    "9MSPC6MP8FM4" = "Microsoft Solitario"
    "9NBLGGH4R32N" = "Hub di Feedback"
    "9WZDNCRDTBVB" = "Mappe"
    "9WZDNCRFJ3PT" = "Media Player (ex Groove)"
    "9WZDNCRFJ3P2" = "Film e TV"
    "9NMPJ99VJBWV" = "Phone Link"
    "9WZDNCRFJ3Q2" = "Meteo"
    "9WZDNCRFHVQM" = "Posta e Calendario"
    "9NBLGGH4QGHW" = "Sticky Notes"
    "9WZDNCRFJ3PR" = "Sveglie e Orologio"
    "9WZDNCRFJBBG" = "Fotocamera"
    "9WZDNCRFHWKN" = "Registratore Vocale"
    "9NBLGGH5R558" = "Microsoft To Do"
    "9WZDNCRFJBMP" = "Microsoft Teams"
    "9P7BP5VNWKX5" = "Assistenza Rapida"
    "9MV0B5HZVK9Z" = "Xbox App"
    "9NZKPSTSNW4P" = "Xbox Game Bar"
    "9P1J8S7CCWWT" = "Clipchamp"
}
$thirdPartyApps = [ordered]@{
    "Mozilla.Firefox"                  = "Firefox"
    "Brave.Brave"                      = "Brave Browser"
    "Google.Chrome"                    = "Google Chrome"
    "Cloudflare.Warp"                  = "Cloudflare Warp"
    "Spotify.Spotify"                  = "Spotify"
    "VideoLAN.VLC"                     = "VLC Media Player"
    "AtomixProductions.VirtualDJ"      = "VirtualDJ"
    "9N0866FS04W8"                     = "Dolby Access"
    "Telegram.TelegramDesktop"         = "Telegram"
    "9NKSQGP7F2NH"                     = "WhatsApp"
    "Discord.Discord"                  = "Discord"
    "Ubisoft.Connect"                  = "Ubisoft Connect"
    "ElectronicArts.EADesktop"         = "EA App"
    "Valve.Steam"                      = "Steam"
    "EpicGames.EpicGamesLauncher"      = "Epic Games Launcher"
    "Moonsworth.LunarClient"           = "Lunar Client"
    "Modrinth.ModrinthApp"             = "Modrinth App"
    "LizardByte.Sunshine"              = "Sunshine"
    "ShaulEizikovich.vJoyDeviceDriver" = "vJoy Driver"
    "Tailscale.Tailscale"              = "Tailscale"
    "OBSProject.OBSStudio"             = "OBS Studio"
    "Notepad++.Notepad++"              = "Notepad++"
    "Microsoft.VisualStudioCode"       = "Visual Studio Code"
    "Rufus.Rufus"                      = "Rufus"
    "7zip.7zip"                        = "7-Zip"
    "RARLab.WinRAR"                    = "WinRAR"
    "Rem0o.FanControl"                 = "FanControl"
    "Microsoft.PowerToys"              = "PowerToys"
    "winaero.tweaker"                  = "Winaero Tweaker"
    "Klocman.BulkCrapUninstaller"      = "Bulk Crap Uninstaller"
    "XPFFTQ032PTPHF"                   = "UniGetUI"
    "Oracle.VirtualBox"                = "VirtualBox"
}

# Check winget for installed status
$wingetRaw = try { & winget list --accept-source-agreements 2>&1 | Out-String } catch { "" }
$softStatus = @{}
$allSoftApps = @{}
foreach ($k in $microsoftApps.Keys)  { $allSoftApps[$k] = $microsoftApps[$k] }
foreach ($k in $thirdPartyApps.Keys) { $allSoftApps[$k] = $thirdPartyApps[$k] }
foreach ($key in $allSoftApps.Keys) {
    $idMatch   = $wingetRaw -match [regex]::Escape($key)
    $nameMatch = $wingetRaw -match [regex]::Escape($allSoftApps[$key])
    $softStatus[$key] = ($idMatch -or $nameMatch)
}

$colorAvail    = [System.Drawing.Color]::FromArgb(25, 25, 25)
$colorAvailFg  = $colorText
$colorInst     = [System.Drawing.Color]::FromArgb(20, 50, 20)
$colorInstFg   = [System.Drawing.Color]::LightGreen
$colorUnavail  = [System.Drawing.Color]::FromArgb(35, 35, 35)
$colorUnavailFg= [System.Drawing.Color]::Gray

function Build-SoftListView($parent, $appDict, $infoText) {
    $tab = New-Object System.Windows.Forms.TabPage; $tab.Text = $parent; $tab.BackColor = $colorBg; $softTab.Controls.Add($tab)
    $lv = New-Object System.Windows.Forms.ListView; $lv.Dock = "Fill"; $lv.View = "Details"; $lv.CheckBoxes = $true; $lv.FullRowSelect = $true; $lv.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20); $lv.ForeColor = $colorText; $lv.BorderStyle = "None"
    $lv.Columns.Add("App", 250) | Out-Null; $lv.Columns.Add("ID", 280) | Out-Null; $lv.Columns.Add("Stato", 100) | Out-Null
    foreach ($key in $appDict.Keys) {
        $installed = $softStatus[$key]
        $item = New-Object System.Windows.Forms.ListViewItem($appDict[$key]); $item.SubItems.Add($key) | Out-Null
        if ($installed) { $item.SubItems.Add("Installata") | Out-Null; $item.BackColor = $colorInst; $item.ForeColor = $colorInstFg }
        else { $item.SubItems.Add("Non installata") | Out-Null; $item.BackColor = $colorAvail; $item.ForeColor = $colorAvailFg }
        $item.Tag = $key; $lv.Items.Add($item) | Out-Null
    }
    $lv.Add_ItemCheck({ param($s,$e) if ($s.Items[$e.Index].BackColor -eq $colorInst) { $e.NewValue = [System.Windows.Forms.CheckState]::Unchecked } })
    $tab.Controls.Add($lv)
    return $lv
}
$lvMicrosoft = Build-SoftListView "App Microsoft" $microsoftApps "App Microsoft preinstallate o rimosse da debloat."
$lvThirdParty = Build-SoftListView "Terze Parti" $thirdPartyApps "App di terze parti installabili tramite winget."

# Bottom panel: select/deselect + log + apply
$softBottom = New-Object System.Windows.Forms.Panel; $softBottom.Height = 200; $softBottom.Dock = "Bottom"; $softBottom.BackColor = $colorBg; $tpSoft.Controls.Add($softBottom)

$btnSoftSelAll = New-Object System.Windows.Forms.Button; $btnSoftSelAll.Text = "SELEZIONA TUTTO"; $btnSoftSelAll.Location = New-Object System.Drawing.Point(15, 8); $btnSoftSelAll.Size = New-Object System.Drawing.Size(140, 30); $btnSoftSelAll.FlatStyle = "Flat"; $btnSoftSelAll.ForeColor = $colorAccent; $btnSoftSelAll.FlatAppearance.BorderColor = $colorAccent
$btnSoftDeselAll = New-Object System.Windows.Forms.Button; $btnSoftDeselAll.Text = "DESELEZIONA TUTTO"; $btnSoftDeselAll.Location = New-Object System.Drawing.Point(165, 8); $btnSoftDeselAll.Size = New-Object System.Drawing.Size(140, 30); $btnSoftDeselAll.FlatStyle = "Flat"; $btnSoftDeselAll.ForeColor = [System.Drawing.Color]::Gray; $btnSoftDeselAll.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60,60,60)

$softLog = New-Object System.Windows.Forms.RichTextBox; $softLog.Location = New-Object System.Drawing.Point(15, 45); $softLog.Size = New-Object System.Drawing.Size(720, 110); $softLog.ReadOnly = $true; $softLog.BackColor = [System.Drawing.Color]::Black; $softLog.ForeColor = [System.Drawing.Color]::LightGreen; $softLog.Font = New-Object System.Drawing.Font("Consolas", 9); $softLog.ScrollBars = "Vertical"

$btnApplySoft = New-Object System.Windows.Forms.Button; $btnApplySoft.Text = "INSTALLA SELEZIONATE"; $btnApplySoft.Location = New-Object System.Drawing.Point(490, 8); $btnApplySoft.Size = New-Object System.Drawing.Size(245, 32); $btnApplySoft.FlatStyle = "Flat"; $btnApplySoft.BackColor = $colorAccent; $btnApplySoft.ForeColor = [System.Drawing.Color]::White; $btnApplySoft.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnApplySoft.Add_Click({
    $btnApplySoft.Enabled = $false; $btnSoftSelAll.Enabled = $false; $btnSoftDeselAll.Enabled = $false
    $ids = @()
    foreach ($item in $lvMicrosoft.Items) { if ($item.Checked) { $ids += $item.Tag } }
    foreach ($item in $lvThirdParty.Items) { if ($item.Checked) { $ids += $item.Tag } }
    if ($ids.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Nessuna app selezionata.", "Attenzione"); $btnApplySoft.Enabled = $true; $btnSoftSelAll.Enabled = $true; $btnSoftDeselAll.Enabled = $true; return }
    $softLog.AppendText("=== Inizio installazione: $($ids.Count) app selezionate ===`r`n"); [System.Windows.Forms.Application]::DoEvents()
    $installScript = Join-Path $PSScriptRoot "src\installer.ps1"
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$installScript`" -Silent -ApplyOnly @($($ids -join ','))"
    Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -Wait -WindowStyle Hidden
    $softLog.AppendText("=== Installazione completata. ===`r`n"); $softLog.ScrollToCaret()
    foreach ($item in $lvMicrosoft.Items) { if ($item.Checked) { $item.Checked = $false; if ($item.BackColor -ne $colorInst) { $item.BackColor = $colorInst; $item.ForeColor = $colorInstFg; $item.SubItems[2].Text = "Installata" } } }
    foreach ($item in $lvThirdParty.Items) { if ($item.Checked) { $item.Checked = $false; if ($item.BackColor -ne $colorInst) { $item.BackColor = $colorInst; $item.ForeColor = $colorInstFg; $item.SubItems[2].Text = "Installata" } } }
    $btnApplySoft.Text = "COMPLETATO"; $btnApplySoft.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
})
$softBottom.Controls.Add($btnSoftSelAll); $softBottom.Controls.Add($btnSoftDeselAll); $softBottom.Controls.Add($softLog); $softBottom.Controls.Add($btnApplySoft)

$btnSoftSelAll.Add_Click({
    $activeTab = $softTab.SelectedTab
    $lv = if ($activeTab -eq $softTab.TabPages[0]) { $lvMicrosoft } else { $lvThirdParty }
    foreach ($item in $lv.Items) { if ($item.BackColor -ne $colorInst) { $item.Checked = $true } }
})
$btnSoftDeselAll.Add_Click({
    $activeTab = $softTab.SelectedTab
    $lv = if ($activeTab -eq $softTab.TabPages[0]) { $lvMicrosoft } else { $lvThirdParty }
    foreach ($item in $lv.Items) { $item.Checked = $false }
})


# ===================================================================
# === 5. NAV BUTTONS ===
# ===================================================================
Add-NavBtn "REGISTRO" 0
Add-NavBtn "INTERNET" 1
Add-NavBtn "DEBLOAT" 2
Add-NavBtn "SOFTWARE" 3

$PanelSide.Controls[1].PerformClick() # Avvio su Registro
[void]$Form.ShowDialog()
