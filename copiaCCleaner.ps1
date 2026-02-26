# ===================================================================
# === CCLEANER PERSISTENTE & COLLEGAMENTO DESKTOP ===
# ===================================================================
$safePath = "$env:ProgramData\WindowsOptimizer"
if (-not (Test-Path $safePath)) { 
    New-Item -Path $safePath -ItemType Directory -Force | Out-Null 
}

$sourceCCleaner = "$PSScriptRoot\CCleaner.bat"
$safeCCleaner = "$safePath\CCleaner.bat"

if (Test-Path $sourceCCleaner) {
    $sourceHash = (Get-FileHash "$PSScriptRoot\CCleaner.bat").Hash
	$destHash   = if (Test-Path $safeCCleaner) { (Get-FileHash $safeCCleaner).Hash } else { "" }

	if ($sourceHash -ne $destHash) {
		Write-Host "[*] Aggiornamento CCleaner rilevato, aggiorno la copia..." -ForegroundColor Yellow
		Copy-Item -Path $sourceCCleaner -Destination $safeCCleaner -Force
	} else {
		Write-Host "[OK] CCleaner già aggiornato." -ForegroundColor Green
	}
    
	if (-not (Test-Path "$DesktopPath\CCleaner.lnk")) {
		
    Write-Host "[*] Creazione del collegamento sul Desktop..." -ForegroundColor Cyan
    try {
        # Creazione del collegamento tramite WScript.Shell (traduzione del file icon.bat)
        $WshShell = New-Object -ComObject WScript.Shell
        $DesktopPath = [Environment]::GetFolderPath('Desktop')
        $Shortcut = $WshShell.CreateShortcut("$DesktopPath\CCleaner.lnk")
        
        # Facciamo puntare il collegamento al file SALVATO AL SICURO
        $Shortcut.TargetPath = $safeCCleaner
        $Shortcut.WorkingDirectory = $safePath
        $Shortcut.IconLocation = "$env:SystemRoot\System32\cleanmgr.exe,0"
        $Shortcut.Description = "Script di pulizia automatica"
        $Shortcut.Save()
        
        Write-Host "    -> Collegamento creato con l'icona di Pulizia Disco!" -ForegroundColor Green
    }
    catch {
        Write-Warning "Impossibile creare il collegamento sul desktop."
    }
	}
    

    Write-Host "[*] Avvio pulizia file temporanei..." -ForegroundColor Yellow
    Start-Process -FilePath $safeCCleaner
	
    if (Get-Command Write-ProgressMessage -ErrorAction SilentlyContinue) {
    Write-ProgressMessage "Avvio pulizia file temporanei."
	}
	
} else {
    Write-Warning "File CCleaner.bat non trovato nella cartella sorgente. Salto il passaggio."
}