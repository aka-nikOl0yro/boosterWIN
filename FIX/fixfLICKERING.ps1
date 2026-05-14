# --- FUNZIONI DI SUPPORTO NECESSARIE ---

# Questa è la funzione che mancava!
function New-RegistryKey {
    param(
        [string]$Path
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    try {
        # Ora questa riga funzionerà perché la funzione sopra esiste
        New-RegistryKey -Path $Path 
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        Write-Host "OK: $Path\$Name -> $Value" -ForegroundColor Green
    }
    catch {
        Write-Warning "ERRORE: Impossibile impostare $Path -> $Name"
        Write-Error $_.Exception.Message
    }
}

# ===================================================================
# === FIX CRITICI PER NITROOS (Input, Focus, Flickering) ===
# ===================================================================

Write-Host "  -> Applicazione Fix Stabilità NitroOS..." -ForegroundColor Cyan

Set-RegValue "HKCU:\Control Panel\Desktop" "AutoEndTasks" 0
#Set-RegValue "HKCU:\Control Panel\Desktop" "HungAppTimeout" 2000
Set-RegValue "HKCU:\Control Panel\Desktop" "MenuShowDelay" 120
Set-RegValue "HKCU:\Control Panel\Desktop" "WaitToKillAppTimeout" 10000
#Set-RegValue "HKCU:\Control Panel\Desktop" "LowLevelHooksTimeout" 2000
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control" "WaitToKillServiceTimeout" 10000
# Write-Host "  -> Ripristino dei timeout predefiniti di Windows (Rimozione ottimizzazioni)..."
# Rimuove il valore LowLevelHooksTimeout se esiste
Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "LowLevelHooksTimeout" -ErrorAction SilentlyContinue
# Rimuove il valore HungAppTimeout se esiste
Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -ErrorAction SilentlyContinue

# ===================================================================