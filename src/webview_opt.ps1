# Crea gli argomenti per forzare l'Efficiency Mode e limitare i processi per risparmiare RAM
$WebViewOttimizzato = "--enable-features=EfficiencyMode --renderer-process-limit=2"

# Applica la regola a livello di utente
[Environment]::SetEnvironmentVariable("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", $WebViewOttimizzato, "User")

#rollback
#[Environment]::SetEnvironmentVariable("WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS", $null, "User")

# Percorso specifico per le policy di WebView2
$wv2Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\WebView2"

# Crea la chiave se non esiste
New-Item -Path $wv2Path -Force | Out-Null

# Forza l'accelerazione hardware per scaricare la CPU
Set-ItemProperty -Path $wv2Path -Name "HardwareAccelerationModeEnabled" -Value 1 -Type DWord

## 1. Blocca la riproduzione automatica dei contenuti multimediali (0 = Disattivato)
#Set-ItemProperty -Path $wv2Path -Name "AutoplayAllowed" -Value 0 -Type DWord

# 2. Imposta la prevenzione del tracciamento su "Rigida" (3 = Strict)
Set-ItemProperty -Path $wv2Path -Name "TrackingPrevention" -Value 3 -Type DWord