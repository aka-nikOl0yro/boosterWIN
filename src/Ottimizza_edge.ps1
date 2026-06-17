
# Imposta il percorso del registro per le policy di Edge

$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"# Crea la chiave di registro per le policy di Edge (se non esiste già)

New-Item -Path $regPath -Force | Out-Null

# Imposta il valore per abilitare il risparmio energia
Set-ItemProperty -Path $regPath -Name "EfficiencyModeEnabled" -Value 1 -Type DWord


# 1. Avvio rapido -> DISATTIVATO (0)
Set-ItemProperty -Path $regPath -Name "StartupBoostEnabled" -Value 0 -Type DWord

# 2. Continua l'esecuzione di estensioni e app in background -> DISATTIVATO (0)
Set-ItemProperty -Path $regPath -Name "BackgroundModeEnabled" -Value 0 -Type DWord

# 3. Usa l'accelerazione grafica quando disponibile -> ATTIVATO (1)
Set-ItemProperty -Path $regPath -Name "HardwareAccelerationModeEnabled" -Value 1 -Type DWord

# 4. Migliora video -> DISATTIVATO (0)
Set-ItemProperty -Path $regPath -Name "EdgeVideoSuperResolutionEnabled" -Value 0 -Type DWord