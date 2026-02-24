#Requires -RunAsAdministrator


# ===================================================================
# === CONTROLLO DIRITTI DI AMMINISTRATORE ===
# ===================================================================
function Test-IsAdmin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Warning "Richiesta dei privilegi di amministratore in corso..."
    try {
        $scriptPath = $MyInvocation.MyCommand.Path
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs -ErrorAction Stop
    }
    catch {
        Write-Error "Impossibile riavviare lo script come amministratore. Interruzione."
        Read-Host "Premere Invio per uscire."
    }
    exit
}

# Imposta la directory di lavoro sulla posizione dello script
Push-Location -Path $PSScriptRoot

# ===================================================================
# === VARIABILI PER PROGRESSO ===
# ===================================================================
# Aggiornare se si aggiungono/rimuovono sezioni principali di ottimizzazione
$TOTAL_STEPS = 24 
$CURRENT_STEP = 0

function Write-ProgressMessage {
    param(
        [string]$Message
    )
    $script:CURRENT_STEP++
    Write-Progress -Activity "Applicazione Ottimizzazioni" -Status $Message -PercentComplete (($script:CURRENT_STEP * 100) / $script:TOTAL_STEPS)
}
# ===================================================================
# === FUNZIONE PER IL MENU INTERATTIVO ===
# ===================================================================
function Show-MenuChoice {
    param(
        [string]$Question,
        [string]$Details,
        [bool]$DefaultChoice = $true # $true per 'Si', $false per 'No'
    )

    $title = "Personalizzazione Ottimizzazioni"
    $message = $Question
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Si", "Applica questa ottimizzazione."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Salta questa ottimizzazione."
    $detail = New-Object System.Management.Automation.Host.ChoiceDescription "&Dettagli", "Mostra pro e contro di questa ottimizzazione."
    $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no, $detail)
    $default = if ($DefaultChoice) { 0 } else { 1 }

    while ($true) {
        $decision = $Host.UI.PromptForChoice($title, $message, $choices, $default)
        switch ($decision) {
            0 { return $true }
            1 { return $false }
            2 {
                Clear-Host
                Write-Host "===================================================================" -ForegroundColor Yellow
                Write-Host "DETTAGLI: $($Question -replace '\?','')" -ForegroundColor White
                Write-Host "===================================================================" -ForegroundColor Yellow
                Write-Host $Details -ForegroundColor Cyan
                Write-Host "===================================================================" -ForegroundColor Yellow
                Read-Host "`nPremere Invio per tornare al menu..."
                Clear-Host
            }
        }
    }
}

# ===================================================================
# === MENU DI PERSONALIZZAZIONE ===
# ===================================================================
Clear-Host

# --- AGGIUNTA FONDAMENTALE INIZIO ---
$osInfo = Get-CimInstance Win32_OperatingSystem
$buildNumber = [int]$osInfo.BuildNumber
$isWin11 = $buildNumber -ge 22000
$winVersionName = if ($isWin11) { "Windows 11" } else { "Windows 10" }
# --- AGGIUNTA FONDAMENTALE FINE ---

Write-Host "===================================================================" -ForegroundColor Green
Write-Host "=== MENU DI PERSONALIZZAZIONE DELLE OTTIMIZZAZIONI ===" -ForegroundColor White
Write-Host "=== Sistema Rilevato: $winVersionName ===" -ForegroundColor Yellow 
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "Rispondi 'Si' o 'No' alle seguenti domande per personalizzare lo script."
Write-Host "Per ogni opzione, puoi scegliere 'Dettagli' per visualizzare una descrizione."
Write-Host ""

$Tweaks = @{
    APPLY_WINUPDATE_TWEAK         = Show-MenuChoice -Question "Bloccare l'installazione di DRIVER tramite Windows Update?" -DefaultChoice $true -Details @"
PRO:
- Windows Update scarichera' SOLO patch di sicurezza e aggiornamenti per Defender.
- Impedisce a Windows di sovrascrivere i tuoi driver (GPU, Audio) con versioni generiche o vecchie.
- Mantieni il sistema sicuro senza rischiare instabilita' hardware.
CONTRO:
- Dovrai aggiornare i driver manualmente (es. tramite sito NVIDIA/AMD o sito del produttore).
"@
	APPLY_DISABLE_WUDO            = Show-MenuChoice -Question "Disattivare Ottimizzazione Recapito (P2P Updates)?" -DefaultChoice $true -Details @"
PRO:
- Impedisce a Windows di usare la tua banda per inviare aggiornamenti ad altri PC su Internet.
- Migliora la stabilità della connessione (ping) e riduce l'uso dei dati in background.
CONTRO:
- Se hai più PC in casa, dovranno scaricare gli aggiornamenti singolarmente invece di passarseli tra loro.
"@
    APPLY_BINGSEARCH_TWEAK        = Show-MenuChoice -Question "Disattivare Bing Search e suggerimenti web nel menu Start?" -DefaultChoice $true -Details @"
PRO:
- Rende la ricerca nel menu Start piu' veloce e focalizzata solo sui file locali.
- Aumenta la privacy evitando di inviare le tue ricerche a Microsoft.
- Pulisce l'interfaccia di ricerca da risultati web non richiesti.
CONTRO:
- Perdi la comoda funzionalita' di cercare sul web direttamente dal menu Start.
"@
    APPLY_SUGGESTED_APPS_TWEAK    = Show-MenuChoice -Question "Disattivare app suggerite, annunci e contenuti sponsorizzati?" -DefaultChoice $true -Details @"
PRO:
- Rimuove annunci, app suggerite e 'consigli' dal menu Start e da altre aree di Windows.
- Offre un'esperienza utente piu' pulita e meno invasiva.
CONTRO:
- Potresti non vedere alcuni suggerimenti di app o funzionalita' di Microsoft (molto raro).
"@
APPLY_DISABLE_GAMEBAR         = Show-MenuChoice -Question "Disattivare COMPLETAMENTE la Game Bar e DVR?" -DefaultChoice $false -Details @"
PRO:
- Libera risorse se non registri clip di gioco.
CONTRO:
- [ATTENZIONE] Rompe le funzionalita' Xbox, l'invito agli amici nei giochi e la registrazione clip.
- Se usi il controller Xbox o giochi cross-platform, rispondi NO.
"@
    APPLY_DISABLE_LOCKSCREEN_BLUR = Show-MenuChoice -Question "Disattivare l'effetto sfocatura sulla schermata di blocco?" -DefaultChoice $true -Details @"
PRO:
- Rende l'immagine di sfondo della schermata di login perfettamente nitida.
- Puo' rendere la comparsa della schermata di login leggermente piu' veloce su PC datati.
CONTRO:
- Modifica puramente estetica, si perde l'effetto 'acrilico' di Windows.
"@
    APPLY_TASKBAR_SECONDS         = Show-MenuChoice -Question "Mostrare i secondi nell'orologio della barra delle applicazioni?" -DefaultChoice $true -Details @"
PRO:
- Permette di visualizzare l'ora con precisione al secondo, utile in molti contesti.
CONTRO:
- Causa un consumo di CPU leggermente superiore (impatto quasi nullo su PC moderni).
"@
	APPLY_DISABLE_STICKYKEYS      = Show-MenuChoice -Question "Disattivare scorciatoia 'Tasti Permanenti' (5 volte Shift)?" -DefaultChoice $true -Details @"
PRO:
- Evita che premendo 5 volte SHIFT (comune nei giochi FPS) appaia la finestra di dialogo che interrompe il gioco.
CONTRO:
- Rende più difficile l'attivazione delle funzioni di accessibilità per chi ne ha bisogno.
"@
    APPLY_DISABLE_AI              = Show-MenuChoice -Question "Disattivare le funzionalita' AI (Copilot, Recall, etc.)?" -DefaultChoice $true -Details @"
PRO:
- Migliora la privacy impedendo l'analisi dei dati da parte delle funzioni AI.
- Libera risorse di sistema e rimuove l'icona di Copilot dalla barra delle applicazioni.
CONTRO:
- Perdi l'accesso rapido all'assistente AI Copilot e ad altre future integrazioni AI.
"@
APPLY_RAM_SCHEDULER           = Show-MenuChoice -Question "Installare 'RAM Cleaner' automatico (Task Pianificato)?" -DefaultChoice $true -Details @"
PRO:
- Crea uno script che svuota la 'Working Set' della RAM ogni 5 minuti.
- Mantiene il sistema reattivo liberando memoria da app pesanti (Discord, Spotify, Browser).
- Funziona in background in modo invisibile.
CONTRO:
- Aggiunge un task pianificato al sistema.
"@
    APPLY_MULTITASKING_TWEAK      = Show-MenuChoice -Question "Ottimizzare il Multitasking (Snap Assist, Alt+Tab, Focus)?" -DefaultChoice $true -Details @"
PRO:
- Disabilita i suggerimenti fastidiosi quando sposti le finestre (Snap Assist).
- Alt+Tab mostra SOLO le finestre aperte (niente schede Edge).
- Impedisce alle app in background di rubare il focus mentre scrivi o giochi.
CONTRO:
- Perdi le funzionalita' di layout finestre 'intelligente' di Windows 11.
"@
    APPLY_KERNEL_TWEAKS           = Show-MenuChoice -Question "Applicare ottimizzazioni Kernel avanzate (Timer)?" -DefaultChoice $true -Details @"
PRO:
- Modifiche di basso livello che possono migliorare la reattivita' generale del sistema.
- Ottimizza la sincronizzazione dei timer della CPU (TSC).
CONTRO:
- Essendo modifiche al cuore del sistema, c'e' un rischio (basso) di instabilita' su hardware particolari.
"@
    APPLY_DISABLE_PRINTER         = Show-MenuChoice -Question "Disabilitare il servizio di stampa (Spooler)?" -DefaultChoice $true -Details @"
PRO:
- Libera una piccola quantita' di RAM e risorse CPU se non si usa mai una stampante.
- Chiude potenziali vulnerabilita' di sicurezza legate al servizio Spooler.
CONTRO:
- Impossibile stampare o usare stampanti PDF finche' il servizio non viene riattivato.
"@
    APPLY_GAMING_NET_TWEAKS       = Show-MenuChoice -Question "Applicare ottimizzazioni di rete AVANZATE per gaming (RSC/Interrupt)?" -DefaultChoice $false -Details @"
PRO:
- Riduce la latenza di rete (ping) disabilitando il raggruppamento dei pacchetti (RSC) e la moderazione degli interrupt.
- Puo' rendere l'esperienza di gioco online piu' reattiva.
CONTRO:
- Aumenta leggermente il carico sulla CPU.
- Su alcune schede di rete o connessioni potrebbe non portare benefici o causare instabilita'.
"@
    APPLY_DISABLE_IPV6            = Show-MenuChoice -Question "Disabilitare IPv6 (solo se si hanno problemi di connettivita')?" -DefaultChoice $false -Details @"
PRO:
- Puo' risolvere rari problemi di connettivita' o lentezza su reti che non supportano correttamente IPv6.
CONTRO:
- IPv6 e' il futuro di internet; disabilitarlo e' una soluzione temporanea e non raccomandata a lungo termine.
- Potrebbe causare problemi con alcuni servizi o applicazioni moderne che lo richiedono.
"@
    APPLY_DESKTOP_ICONS           = Show-MenuChoice -Question "Mostrare le icone classiche (Questo PC, Rete) sul desktop?" -DefaultChoice $false -Details @"
PRO:
- Aggiunge collegamenti rapidi a 'Questo PC', 'Rete' e 'Pannello di Controllo' sul desktop.
CONTRO:
- Aggiunge piu' icone sul desktop, che alcuni utenti preferiscono mantenere pulito.
"@
    APPLY_DISABLE_DNSCLIENT       = Show-MenuChoice -Question "Disabilitare il servizio 'Client DNS' (Dnscache) per query DNS dirette?" -DefaultChoice $false -Details @"
PRO:
- Ogni richiesta di rete viene inviata direttamente al server DNS, garantendo risultati sempre 'freschi'.
- Puo' ridurre la latenza in alcuni scenari di gaming e liberare minime risorse.
CONTRO:
- Potrebbe rallentare leggermente la navigazione web generale, poiche' nessuna richiesta viene salvata in cache.
"@
}

# --- Tweak Piano Energetico ---
$isLaptop = (Get-CimInstance -ClassName Win32_SystemEnclosure).ChassisTypes | Where-Object { $_ -in 8, 9, 10, 14 }
if ($isLaptop) {
    $Tweaks.APPLY_ULTIMATE_PERF = Show-MenuChoice -Question "Attivare piano 'Prestazioni Eccellenti' (IMPATTO BATTERIA)?" -DefaultChoice $false -Details @"
PRO:
- E' il piano energetico piu' aggressivo, elimina ogni micro-latenza legata al risparmio energetico della CPU.
- Ideale per gaming competitivo, produzione audio/video e workstation.
CONTRO:
- Aumenta il consumo energetico e il calore prodotto. Su un portatile, riduce drasticamente la durata della batteria.
"@
}
else {
    $Tweaks.APPLY_ULTIMATE_PERF = Show-MenuChoice -Question "Attivare piano energetico 'Prestazioni Eccellenti'?" -DefaultChoice $true -Details @"
PRO:
- E' il piano energetico piu' aggressivo, elimina ogni micro-latenza legata al risparmio energetico della CPU.
- Ideale per gaming competitivo, produzione audio/video e workstation.
CONTRO:
- Aumenta il consumo energetico e il calore prodotto.
"@
}

# --- Tweak Specifici per CPU ---
$cpu = Get-CimInstance Win32_Processor
$cpuManufacturer = $cpu.Manufacturer.Trim()

if ($cpuManufacturer -eq "GenuineIntel") {
    $Tweaks.APPLY_INTEL_TSX_TWEAK = Show-MenuChoice -Question "[CPU INTEL] Disabilitare TSX per sicurezza/stabilita' (avanzato)?" -DefaultChoice $false -Details @"
PRO:
- Aumenta la sicurezza chiudendo una potenziale via per vulnerabilita' hardware.
- Puo' migliorare la stabilita' in alcuni giochi o applicazioni.
CONTRO:
- Si perde un potenziale (spesso minimo) aumento di prestazioni in carichi di lavoro specifici.
"@
    $Tweaks.APPLY_INTEL_BOOST_TWEAK = Show-MenuChoice -Question "[CPU INTEL] Ottimizzare modalita' boost CPU (Aggressiva)?" -DefaultChoice $false -Details @"
PRO:
- Imposta la gestione della frequenza su 'Aggressiva', migliorando la reattivita'.
CONTRO:
- Puo' aumentare leggermente consumi e temperature.
"@
}

if ($cpuManufacturer -eq "AuthenticAMD") {
    $Tweaks.APPLY_AMD_HPET_TWEAK = Show-MenuChoice -Question "[CPU AMD] Disabilitare HPET per ridurre latenza (avanzato)?" -DefaultChoice $false -Details @"
PRO:
- Forza l'uso del timer TSC della CPU, piu' veloce e preciso su architetture Ryzen.
- Puo' ridurre la latenza in giochi e applicazioni sensibili al tempo.
CONTRO:
- Su alcuni rari sistemi potrebbe causare problemi di sincronizzazione o instabilita'.
"@
    $Tweaks.APPLY_AMD_CORE_PARKING_TWEAK = Show-MenuChoice -Question "[CPU AMD] Disabilitare Core Parking (mantiene tutti i core attivi)?" -DefaultChoice $false -Details @"
PRO:
- Mantiene tutti i core della CPU sempre attivi e pronti, riducendo micro-latenze.
CONTRO:
- Aumenta il consumo energetico e le temperature a riposo (idle).
"@
}

# --- Tweak PC Datato ---
$totalRamGB = [Math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
if ($totalRamGB -le 4) {
    $Tweaks.APPLY_UNLOADDLL_TWEAK = Show-MenuChoice -Question "[PC DATATO] Forzare unload delle DLL per liberare RAM (rischioso)?" -DefaultChoice $false -Details @"
PRO:
- Forza Windows a rimuovere dalla RAM le librerie (.DLL) non appena un programma viene chiuso, liberando memoria.
CONTRO:
- [RISCHIOSO] Puo' causare rallentamenti (se le DLL devono essere ricaricate spesso) e instabilita' del sistema.
- Generalmente sconsigliato sui sistemi moderni.
"@
}

if ($isWin11) {
    Write-Host "`n--- Opzioni Specifiche Windows 11 ---" -ForegroundColor Cyan
    
    $Tweaks.APPLY_CLASSIC_CONTEXT_MENU    = Show-MenuChoice -Question "Ripristinare il menu contestuale classico di Windows 10?" -DefaultChoice $true -Details @"
PRO:
- Mostra immediatamente tutte le opzioni disponibili, senza il passaggio 'Mostra altre opzioni'.
- Migliora notevolmente la velocita' di lavoro per gli utenti esperti.
CONTRO:
- Perdi il nuovo menu contestuale di Windows 11, piu' minimale ma meno funzionale.
"@
    
    $Tweaks.APPLY_CLASSIC_RIBBON          = Show-MenuChoice -Question "Attivare l'interfaccia 'ribbon' classica in Esplora File?" -DefaultChoice $true -Details @"
PRO:
- Ripristina la barra multifunzione completa e ricca di funzionalita' di Windows 10.
- Offre accesso diretto a molti piu' comandi rispetto alla nuova barra semplificata.
CONTRO:
- Perdi la nuova barra dei comandi di Windows 11, piu' pulita ma con meno opzioni visibili.
"@
    $Tweaks.APPLY_BLOCK_EDGE_CHAT         = Show-MenuChoice -Question "Bloccare la reinstallazione automatica di Edge e Chat?" -DefaultChoice $true -Details @"
PRO:
- Impedisce a Windows Update di reinstallare forzatamente Microsoft Edge o l'app Chat.
- Utile se si preferisce usare browser o app di messaggistica alternativi.
CONTRO:
- Nessuno, se non si utilizzano questi specifici programmi Microsoft.
"@
    $Tweaks.APPLY_BYPASS_CHECKS           = Show-MenuChoice -Question "Applicare Bypass dei requisiti di sistema (TPM, Secure Boot)?" -DefaultChoice $true -Details @"
PRO:
- Permette di installare o aggiornare Windows 11 su hardware non ufficialmente supportato.
CONTRO:
- Microsoft potrebbe in futuro negare aggiornamenti a sistemi non conformi.
- Si disattivano controlli pensati per migliorare la sicurezza del sistema.
"@
}

Clear-Host

# ===================================================================
# === FUNZIONI HELPER PER APPLICARE TWEAK ===
# ===================================================================
# Funzione per creare la chiave di registro se non esiste
function New-RegistryKey {
    param(
        [string]$Path
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# Funzione per impostare una proprietà del registro
function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    try {
        New-RegistryKey -Path $Path
        # Se il nome è vuoto o (Default), imposta il valore predefinito della chiave
        if ([string]::IsNullOrEmpty($Name) -or $Name -eq "(Default)") {
            Set-Item -Path $Path -Value $Value -Force -ErrorAction Stop
        } else {
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
        }
    }
    catch {
        Write-Warning "Impossibile impostare il valore di registro: $Path -> $Name"
    }
}

# Funzione per gestire i servizi
function Set-ServiceState {
    param(
        [string]$Name,
        [string]$StartupType = "Disabled",
        [bool]$StopService = $true
    )
    try {
        $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
        if ($service) {
            Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
            if ($StopService) {
                Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        Write-Warning "Impossibile configurare il servizio: $Name"
    }
}

# ===================================================================
# === INIZIO ESECUZIONE SCRIPT ===
# ===================================================================

# --- Controllo Esecuzione Precedente ---
$completionFile = "$PSScriptRoot\REG_OPTIMIZER_COMPLETED"
if (Test-Path $completionFile) {
    Write-Warning "Questo script di ottimizzazione e' gia' stato eseguito."
    $continue = Read-Host "Vuoi continuare comunque? (S/N)"
    if ($continue -ne 'S') {
        Write-Host "Uscita dallo script."
        Start-Sleep -Seconds 3
        exit
    }
}

# --- Punto di Ripristino ---
Write-Host "[*] Attivazione e configurazione del Ripristino di Sistema..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\"
    vssadmin resize shadowstorage /on=c: /for=c: /maxsize=10% > $null 2>&1
}
catch {
    Write-Warning "Impossibile configurare il ripristino di sistema."
}

Write-ProgressMessage "Creazione punto di ripristino 'Pre_Ottimizzazione_Registro'..."
Write-Host "[*] Creazione punto di ripristino 'Pre_Ottimizzazione_Registro'..." -ForegroundColor Yellow
Checkpoint-Computer -Description "Pre_Ottimizzazione_Registro" -RestorePointType "MODIFY_SETTINGS"

# ===================================================================
# === APPLICAZIONE TWEAK ===
# ===================================================================
Write-Host "`n[*] Inizio applicazione delle ottimizzazioni selezionate..." -ForegroundColor Green

# --- Privacy e Telemetria ---
if ($Tweaks.APPLY_WINUPDATE_TWEAK) {
    Write-Host "  -> Configurazione Windows Update: SOLO Sicurezza e Defender (Niente Driver)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" 1
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -ErrorAction SilentlyContinue
    Write-ProgressMessage "Configurazione Windows Update."
}

Write-Host "  -> Disattivazione della telemetria e raccolta dati..."
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegValue "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" "AllowTelemetry" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" "AllowBuildPreview" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" "NoGenTicket" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "AITEnable" 0
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" "PreventHandwritingDataSharing" 1
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\TextInput" "AllowLinguisticDataCollection" 0

Get-ScheduledTask -TaskPath "\Microsoft\Windows\Application Experience\" | Where-Object { $_.TaskName -in "Microsoft Compatibility Appraiser", "ProgramDataUpdater" } | Disable-ScheduledTask
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Autochk\" -TaskName "Proxy" | Disable-ScheduledTask
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Where-Object { $_.TaskName -in "Consolidator", "UsbCeip" } | Disable-ScheduledTask
Get-ScheduledTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" | Where-Object { $_.TaskName -in "BthServ" } | Disable-ScheduledTask # Aggiunto da Reg.bat
Get-ScheduledTask -TaskPath "\Microsoft\Windows\DiskDiagnostic\" -TaskName "Microsoft-Windows-DiskDiagnosticDataCollector" | Disable-ScheduledTask
Write-ProgressMessage "Disattivazione Telemetria e Raccolta Dati."

# --- Ottimizzazioni Menu Start ed Esplora File ---
if ($Tweaks.APPLY_BINGSEARCH_TWEAK) {
    Write-Host "  -> Disattivazione di Bing Search e suggerimenti web nel menu Start..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "DisableWebSearch" 1
    Set-RegValue "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1
    Write-ProgressMessage "Disattivazione Bing Search."
}

Write-Host "  -> Disattivazione Highlights di ricerca nel menu Start..."
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "EnableDynamicContentInWSB" 0

if ($Tweaks.APPLY_SUGGESTED_APPS_TWEAK) {
    Write-Host "  -> Disattivazione delle app suggerite, annunci e contenuti sponsorizzati..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "ContentDeliveryAllowed" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "PreInstalledAppsEverEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SystemPaneSuggestionsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-310093Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-314559Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338387Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338388Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338389Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-338393Enabled" 0 # Aggiunto da Reg.bat
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableWindowsConsumerFeatures" 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "RotatingLockScreenOverlayEnabled" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SoftLandingEnabled" 0
    Set-RegValue "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" "DisableThirdPartySuggestions" 1
    Set-RegValue "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" "DisableTailoredExperiencesWithDiagnosticData" 1
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
    Write-ProgressMessage "Disattivazione app suggerite e annunci."
	# Disabilita ID Pubblicità
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0
    # Impedisce ai siti di vedere la lista lingue
    Set-RegValue "HKCU:\Control Panel\International\User Profile" "HttpAcceptLanguageOptOut" 1
    # Disabilita tracking avvio app (migliora Start)
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackProgs" 0
    # Disabilita suggerimenti Impostazioni extra
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353694Enabled" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SubscribedContent-353696Enabled" 0
    
    # Disabilita Geolocalizzazione (Opzionale ma richiesto dal file reg)
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" "String"
    
    Write-ProgressMessage "Privacy e No-Ads applicati."
    # Aggiunte altre chiavi per una pulizia più approfondita, equivalenti a quelle nel file .bat
}

Write-Host "  -> Disattivazione schermata 'Completiamo la configurazione del tuo dispositivo' (OOBE)..."
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0

Write-Host "  -> Disattivazione del servizio 'Connected User Experiences and Telemetry'..."
Set-ServiceState "DiagTrack" "Disabled"

Write-Host "  -> Attivazione visualizzazione estensioni per i tipi di file conosciuti..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0

if ($Tweaks.APPLY_CLASSIC_CONTEXT_MENU) {
    Write-Host "  -> Ripristino del menu contestuale classico di Windows 10..."
    Set-RegValue "HKCU:\SOFTWARE\CLASSES\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "" "" "String"
    Write-ProgressMessage "Ripristino menu contestuale classico."
}

if ($Tweaks.APPLY_CLASSIC_RIBBON) {
    Write-Host "  -> Ripristino dell'interfaccia 'ribbon' classica in Esplora File..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked" "{e2bf9676-5f8f-435c-97eb-11607a5bedf7}" "" "String"
}

if ($Tweaks.APPLY_DESKTOP_ICONS) {
    Write-Host "  -> Visualizzazione delle icone classiche sul desktop..."
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{645FF040-5081-101B-9F08-00AA002F954E}" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" 0
    # Le chiavi per ClassicStartMenu sono ridondanti su Win10/11 ma incluse per completezza
    Get-ChildItem "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -ErrorAction SilentlyContinue | Set-ItemProperty -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -Value 0 -ErrorAction SilentlyContinue
}

Write-Host "  -> Impostazione di Esplora File per aprirsi su 'Questo PC'..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1

Write-Host "  -> Rimozione dell'icona Chat (Microsoft Teams) dalla barra delle applicazioni..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0
Write-ProgressMessage "Ottimizzazioni Menu Start ed Esplora File."

# --- Ottimizzazioni Interfaccia e Usabilità ---
Write-Host "  -> Attivazione cronologia appunti (Win+V) con sincronizzazione manuale..."
Set-RegValue "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1
Set-RegValue "HKCU:\Software\Microsoft\Clipboard" "CloudClipboardAutomaticUpload" 0
Set-RegValue "HKCU:\Software\Microsoft\Clipboard" "EnableCloudClipboard" 1

if ($Tweaks.APPLY_DISABLE_LOCKSCREEN_BLUR) {
    Write-Host "  -> Disattivazione dell'effetto sfocatura sulla schermata di blocco..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "DisableAcrylicBackgroundOnLogon" 1
}
Write-Host "  -> Disattivazione delle domande di sicurezza per gli account locali..." # Aggiunto da Reg.bat
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "NoLocalPasswordResetQuestions" 1 # Aggiunto da Reg.bat

Write-Host "  -> Disattivazione dei Widget (Notizie e interessi)..."
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0

Write-Host "  -> Impostazione del layout del menu Start per mostrare piu' elementi ancorati..." # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_Layout" 1 # Aggiunto da Reg.bat

Write-Host "  -> Mostra le app piu' usate nel menu Start..." # Aggiunto da Reg.bat
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "ShowOrHideMostUsedApps" 1 # Aggiunto da Reg.bat



Write-Host "  -> Disattivazione del messaggio 'Requisiti di sistema non supportati' (watermark)..."
Set-RegValue "HKCU:\Control Panel\UnsupportedHardwareNotificationCache" "SV1" 0
Set-RegValue "HKCU:\Control Panel\UnsupportedHardwareNotificationCache" "SV2" 0

Write-Host "  -> Disattivazione effetti visivi non essenziali per massime prestazioni..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableAeroPeek" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\DWM" "EnableBlurBehind" 0
Set-RegValue "HKCU:\Control Panel\Desktop" "FontSmoothing" "2" "String"
Set-RegValue "HKCU:\Control Panel\Desktop" "DragFullWindows" "1" "String"

Write-ProgressMessage "Ottimizzazioni Interfaccia e Usabilità."
# --- Ottimizzazioni Gaming e Prestazioni ---
if ($Tweaks.APPLY_DISABLE_GAMEBAR) {
Write-Host "  -> Disattivazione di Game Bar, Game DVR e Ottimizzazioni Schermo Intero..."
Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AllowAutoGameMode" 0
Set-RegValue "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 0
Set-RegValue "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" "value" 0
Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehavior" 2
Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_FSEBehaviorMode" 2
Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_DXGIHonorFSEWindowsCompatible" 1
Set-RegValue "HKCU:\System\GameConfigStore" "GameDVR_HonorUserFSEBehaviorMode" 1
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
} 
else {
    Write-Host "  -> Game Bar MANTENUTA attiva (come richiesto)." -ForegroundColor Cyan
}

if ($Tweaks.APPLY_DISABLE_STICKYKEYS) {
    Write-Host "  -> Disattivazione scorciatoia Tasti Permanenti (No more 5x Shift)..."
    # Imposta i flag per disabilitare la richiesta (StickyKeys, ToggleKeys, FilterKeys)
    Set-RegValue "HKCU:\Control Panel\Accessibility\StickyKeys" "Flags" "506" "String"
    Set-RegValue "HKCU:\Control Panel\Accessibility\ToggleKeys" "Flags" "58" "String"
    Set-RegValue "HKCU:\Control Panel\Accessibility\Keyboard Response" "Flags" "122" "String"
}

Write-Host "  -> Aumento della reattivita' di sistema e prioritizzazione GPU per i giochi..."
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 1
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "GPU Priority" 8
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "Scheduling Category" "High" "String"
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" "SFIO Priority" "High" "String"

Write-Host "  -> Disattivazione della Manutenzione Automatica..."
Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" "MaintenanceDisabled" 1

Write-Host "  -> Disattivazione del Power Throttling..."
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" "PowerThrottlingOff" 1

Write-Host "  -> Ottimizzazione dei timeout per migliorare la reattivita' e la velocita' di spegnimento..."
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

Write-Host "  -> Disattivazione notifiche fantasma..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarBadges" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "EnableBalloonTips" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications" "ToastEnabled" 0

Write-Host "  -> Disattivazione del servizio NDU (potenziale memory leak)..."
Set-RegValue "HKLM:\SYSTEM\ControlSet001\Services\Ndu" "Start" 4

Write-Host "  -> Disattivazione della 'Large System Cache'..."
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache" 0

Write-Host "  -> Aggiunta opzioni 'Copia in...' e 'Sposta in...' al menu contestuale..."
Set-RegValue "HKLM:\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" "" "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" "String"
Set-RegValue "HKLM:\SOFTWARE\Classes\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" "" "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" "String"
Write-ProgressMessage "Ottimizzazioni Gaming e Prestazioni."

# --- Ottimizzazioni Varie ---
Write-Host "  -> Disattivazione completa di Cortana..."
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0

Write-Host "  -> Disattivazione della telemetria di Microsoft Office..." # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "accesssolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "olksolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "onenotesolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "pptsolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "projectsolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "publishersolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "visiosolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "wdsolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedapplications" "xlsolution" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" "agave" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" "appaddins" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" "comaddins" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" "documentfiles" 1 # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Policies\microsoft\office\16.0\osm\preventedsolutiontypes" "templatefiles" 1 # Aggiunto da Reg.bat

Write-Host "  -> Rimozione del ritardo all'avvio dei programmi (Startup Delay)..." # Aggiunto da Reg.bat
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 # Aggiunto da Reg.bat

Write-Host "  -> Disattivazione del tracciamento delle app per migliorare le prestazioni di Start/Ricerca..."
Set-RegValue "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" "DisableMFUTracking" 1

Write-Host "  -> Disattivazione di Windows Error Reporting..."
Set-RegValue "HKCU:\Software\Microsoft\Windows\Windows Error Reporting" "Disabled" 1

if ($Tweaks.APPLY_TASKBAR_SECONDS) {
    Write-Host "  -> Abilitazione dei secondi nell'orologio della barra delle applicazioni..."
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSecondsInSystemClock" 1
}
Write-ProgressMessage "Ottimizzazioni Varie e Office."

# --- Tweak Adattivi (Hardware) ---
Write-Host "  -> Applicazione Tweak Adattivi (CPU, Memoria, Rete)..."
if ($cpu.NumberOfCores -ge 6) {
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38
}
elseif ($cpu.NumberOfCores -eq 4) {
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 26
}

if ($totalRamGB -ge 16) {
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "DisablePagingExecutive" 1
}

if ($totalRamGB -gt 4) {
    Write-Host "  -> Ottimizzazione della soglia di divisione di Svchost..."
    # Il valore deve essere in KB. (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory è in byte.
    $svcHostValue = [Math]::Truncate((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1024)
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control" "SvcHostSplitThresholdInKB" $svcHostValue "QWord"
}

if ($Tweaks.APPLY_RAM_SCHEDULER) {
# 1. Preparazione della directory sicura e copia del file
$safePath = "$env:ProgramData\WindowsOptimizer"
if (-not (Test-Path $safePath)) { 
    New-Item -Path $safePath -ItemType Directory -Force | Out-Null 
}

# Assumiamo che "free_ram.ps1" si trovi nella stessa cartella di questo script
$sourceScript = "$PSScriptRoot\src\free_ram.ps1"
$ramScriptPath = "$safePath\free_ram.ps1"

if (Test-Path $sourceScript) {
    Write-Host "Copia di free_ram.ps1 nella directory sicura di sistema..." -ForegroundColor Cyan
    Copy-Item -Path $sourceScript -Destination $ramScriptPath -Force
} else {
    Write-Warning "File free_ram.ps1 non trovato in $PSScriptRoot. Assicurati che sia nella stessa cartella di questo script!"
    exit
}

# 2. Creazione Task Pianificato (Esattamente come i tuoi screenshot)
$taskName = "free_ram"
    
# Azione: ORA PUNTA ALLA CARTELLA SICURA IN PROGRAMDATA
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ramScriptPath`""
    
# Attivazione: ALL'AVVIO
$trigger = New-ScheduledTaskTrigger -AtLogOn
    
# IL TRUCCO: Inseriamo la ripetizione di 10 min direttamente durante la creazione dell'oggetto!
$repetition = New-CimInstance -ClassName MSFT_TaskRepetitionPattern -Namespace "Root\Microsoft\Windows\TaskScheduler" -Property @{ Interval = "PT10M" } -ClientOnly
$trigger.Repetition = $repetition
    
# Condizioni e Impostazioni (Batteria, Durata 3 giorni, Ferma istanze, ecc.)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Days 3)
$settings.Hidden = $true
$settings.AllowDemandStart = $true
$settings.AllowHardTerminate = $true
    
$settings.Compatibility = "Win8" # Va bene anche per win 10 e 11

# Generale (Utente SYSTEM, Privilegi massimi)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Registrazione
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null

Write-Host "Task '$taskName' creato con successo e reso persistente!" -ForegroundColor Green
    Write-ProgressMessage "Installazione RAM Cleaner completata."
}

if ($Tweaks.APPLY_MULTITASKING_TWEAK) {
    Write-Host "  -> Ottimizzazione Multitasking e Focus..."
    
    # Snap Assist e Layout
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "SnapAssist" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "EnableSnapLayouts" 0
    
    # Alt+Tab pulito (Solo finestre, niente tab Edge)
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "MultiTaskingAltTabFilter" 3
    
    # No Aero Shake (Scuotimento finestra)
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DisallowShaking" 1
    
    # Focus Priority (Impedisce furto focus) - 200000ms = 3m circa
    Set-RegValue "HKCU:\Control Panel\Desktop" "ForegroundLockTimeout" 200000
    
    Write-ProgressMessage "Ottimizzazione Multitasking applicata."
}

$systemDrive = Get-PhysicalDisk | Where-Object { $_.DeviceID -match (Get-Partition | Where-Object { $_.DriveLetter -eq 'C' }).DiskNumber }
if ($systemDrive.BusType -eq 'NVMe') {
    Write-Host "  -> Ottimizzazione I/O per disco NVMe..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "IoPageLockLimit" 524288
}

# --- Tweak Aggiuntivi (Rete, Mouse, ecc.) ---
Write-Host "  -> Disabilitazione accelerazione mouse..."
Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSpeed" 0
Set-RegValue "HKCU:\Control Panel\Mouse" "MouseSensitivity" 10
Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold1" 0
Set-RegValue "HKCU:\Control Panel\Mouse" "MouseThreshold2" 0

Write-Host "  -> Ottimizzazione parametri TCP/IP..."
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpWindowSize" 64240 # Aggiunto da Reg.bat
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "DefaultTTL" 64
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "EnableTCPChimney" 0
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "MaxUserPort" 65535
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "TcpTimedWaitDelay" 30
Write-ProgressMessage "Applicazione Tweak Adattivi e Hardware."

if ($Tweaks.APPLY_DISABLE_WUDO) {
    Write-Host "  -> Disattivazione WUDO (Condivisione aggiornamenti P2P)..."
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0
    Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization" "SystemSettingsDownloadMode" 0
	Get-ScheduledTask -TaskPath "\Microsoft\Windows\DeliveryOptimization\" -ErrorAction SilentlyContinue | Disable-ScheduledTask
}

# --- Tweak da Menu (AI, Edge, Bypass, ecc.) ---
if ($Tweaks.APPLY_DISABLE_AI) {
    Write-Host "  -> Disattivazione delle funzionalita' AI (Copilot, Windows AI)..."

    # Le ottimizzazioni di base del registro sono ora gestite dallo script esterno,
    # che esegue una pulizia più approfondita. Queste righe sono commentate
    # per evitare ridondanza, ma possono essere riattivate se necessario.
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
    #Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Edge" "HubsSidebarEnabled" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "DisableAIDataAnalysis" 1
    #Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy" "LetAppsAccessGenerativeAI" 2
    Write-Host "  -> Esecuzione script esterno per la rimozione completa dei componenti AI..."
    try {
        # Scarica lo script, adatta 'takeown /d Y' in 'takeown /d S' per Windows in Italiano ed esegui
        $aiScriptUrl = "https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1"
        $aiScriptContent = Invoke-RestMethod -Uri $aiScriptUrl
        $aiScriptContent = $aiScriptContent -replace '/d Y', '/d S'
		# cpm 2>$null spprmo tutti gli errori
        & ([scriptblock]::Create($aiScriptContent)) -nonInteractive -AllOptions 2>$null
    }
    catch {
        Write-Warning "Impossibile scaricare o eseguire lo script RemoveWindowsAI. Verifica la connessione a internet."
    }

    Write-ProgressMessage "Disattivazione funzionalità AI."
}
if ($Tweaks.APPLY_BLOCK_EDGE_CHAT) {
    Write-Host "  -> Blocco della reinstallazione automatica di Edge e Chat..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" "DoNotUpdateToEdgeWithChromium" 1
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Communications" "ConfigureChatAutoInstall" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" "ChatIcon" 3
}

Write-ProgressMessage "Blocco reinstallazione Edge/Chat."

if ($Tweaks.APPLY_DISABLE_DNSCLIENT) {
    Write-Host "  -> Disabilitazione del servizio 'Client DNS' (Dnscache)..."
    #Set-ServiceState "Dnscache" "Disabled" non Funziona
	Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache" "Start" 4 "DWord"
}

Write-ProgressMessage "Disabilitazione Client DNS."
if ($Tweaks.APPLY_BYPASS_CHECKS) {
    Write-Host "  -> Applicazione Bypass per requisiti di sistema..."
    Set-RegValue "HKLM:\SYSTEM\Setup\LabConfig" "BypassTPMCheck" 1
    Set-RegValue "HKLM:\SYSTEM\Setup\LabConfig" "BypassSecureBootCheck" 1
    Set-RegValue "HKLM:\SYSTEM\Setup\LabConfig" "BypassRAMCheck" 1
    Set-RegValue "HKLM:\SYSTEM\Setup\MoSetup" "AllowUpgradesWithUnsupportedTPMOrCPU" 1
    Write-ProgressMessage "Applicazione Bypass requisiti sistema."
}

if ($Tweaks.APPLY_KERNEL_TWEAKS) {
    Write-Host "  -> Applicazione ottimizzazioni Kernel avanzate..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "GlobalTimerResolutionRequests" 1
    # Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" "HeapSegmentReserve" 1048576
    # Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" "HeapSegmentCommit" 262144
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\ACPI\Parameters" "TscSyncPolicy" 1
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" "DpcWatchdogProfileOffset" 10000
    Write-ProgressMessage "Applicazione ottimizzazioni Kernel."
}

if ($Tweaks.APPLY_GAMING_NET_TWEAKS) {
    Write-Host "  -> Applicazione ottimizzazioni di rete AVANZATE per gaming..."
    Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled -ErrorAction SilentlyContinue
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
    }
    Write-ProgressMessage "Applicazione ottimizzazioni rete gaming."
}

if ($Tweaks.APPLY_DISABLE_IPV6) {
    Write-Host "  -> Disabilitazione di IPv6..."
    Get-NetAdapterBinding -ComponentID ms_tcpip6 | Disable-NetAdapterBinding -PassThru -ErrorAction SilentlyContinue
    Write-ProgressMessage "Disabilitazione IPv6."
}
if ($Tweaks.APPLY_ULTIMATE_PERF) {
    Write-Host "  -> Sblocco e attivazione del piano energetico 'Prestazioni Eccellenti'..."
    $ultimateGuid = "e9a42b02-d5c9-4a9f-a1a9-346d110f6609"
    $planExists = (powercfg /list) -match $ultimateGuid
    
    if (-not $planExists) {
        Write-Host "     Creazione nuovo piano energetico..." -ForegroundColor Cyan
        powercfg -duplicatescheme $ultimateGuid | Out-Null
    } else {
        Write-Host "     Piano energetico gia' presente. Attivazione..." -ForegroundColor Cyan
    }
    powercfg -setactive $ultimateGuid
}

$activePowerSchemeGuid = (powercfg /getactivescheme).Split(" ")[3]

# --- Tweak Specifici CPU (da menu) ---
if ($Tweaks.APPLY_AMD_HPET_TWEAK) {
    Write-Host "  -> [CPU AMD] Disabilitazione di HPET a livello di sistema operativo..."
    bcdedit /set useplatformclock false
}
if ($Tweaks.APPLY_AMD_CORE_PARKING_TWEAK) {
    Write-Host "  -> [CPU AMD] Disabilitazione Core Parking (mantiene tutti i core attivi)..."
    $coreParkingGuid = "0cc5b647-c1df-4637-891a-edc2142377ea"
    powercfg /setacvalueindex $activePowerSchemeGuid "SUB_PROCESSOR" $coreParkingGuid 100
    powercfg /setdcvalueindex $activePowerSchemeGuid "SUB_PROCESSOR" $coreParkingGuid 100
}
if ($Tweaks.APPLY_INTEL_TSX_TWEAK) {
    Write-Host "  -> [CPU INTEL] Disabilitazione delle estensioni TSX..."
    Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" "DisableTsx" 1
}
if ($Tweaks.APPLY_INTEL_BOOST_TWEAK) {
    Write-Host "  -> [CPU INTEL] Impostazione modalita' boost CPU su 'Aggressiva'..."
    $boostModeGuid = "45bcc044-d885-43e2-8605-ee0f443d58b5"
    powercfg /setacvalueindex $activePowerSchemeGuid "SUB_PROCESSOR" $boostModeGuid 2
    powercfg /setdcvalueindex $activePowerSchemeGuid "SUB_PROCESSOR" $boostModeGuid 2
}

# --- Tweak PC Datato (da menu) ---
if ($Tweaks.APPLY_UNLOADDLL_TWEAK) {
    Write-Host "  -> [PC DATATO] Abilitazione forzata dell'unload delle DLL..."
    Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" "AlwaysUnloadDll" 1
}

# --- Disabilitazione Servizi ---
Write-Host "  -> Disabilitazione di servizi non essenziali..."
Set-ServiceState "dmwappushservice" "Disabled"
Set-ServiceState "WerSvc" "Disabled"
Set-ServiceState "RemoteRegistry" "Disabled"
#Set-ServiceState "bthserv" "Disabled"
#Set-ServiceState "WMPNetworkSvc" "Disabled"
#Set-ServiceState "stisvc" "Disabled"
Set-ServiceState "wlidsvc" "Disabled"
if ($Tweaks.APPLY_DISABLE_PRINTER) {
    Write-Host "  -> Disabilitazione del servizio Spooler di stampa..."
    Set-ServiceState "spooler" "Disabled"
}
Write-ProgressMessage "Disabilitazione servizi non essenziali."

# ===================================================================
# === SCRIPT ESTERNI E COMPLETAMENTO ===
# ===================================================================
Write-ProgressMessage "Rimozione Bloatware."
Write-Host "`n[*] Rimozione delle app preinstallate (Bloatware) tramite 'debloat.ps1'..." -ForegroundColor Yellow
try {
    & "$PSScriptRoot\src\debloat.ps1" -ErrorAction Stop
}
catch {
    Write-Warning "Impossibile eseguire lo script 'debloat.ps1'. Potrebbe non esistere o contenere errori."
}



# Write-Host "`n[*] Avvio pulizia file temporanei..." -ForegroundColor Yellow
# Start-Process -FilePath "$PSScriptRoot\CCleaner.bat"
# Write-ProgressMessage "Avvio pulizia file temporanei."

# --- Marcatore di Completamento ---
Set-Content -Path $completionFile -Value "Completed on $(Get-Date)"
Set-ItemProperty -Path $completionFile -Name Attributes -Value ([IO.FileAttributes]::Hidden)

# ===================================================================
# === FINE ===
# ===================================================================
Write-Host "`n===================================================================" -ForegroundColor Green
Write-ProgressMessage "Finalizzazione."
Write-Host "=== OTTIMIZZAZIONE COMPLETATA ===" -ForegroundColor White
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "E' necessario riavviare il sistema per applicare tutte le modifiche." -ForegroundColor Yellow
Restart-Computer -Force -Delay 60 -Message "Riavvio programmato in 60 secondi per completare l'ottimizzazione."

Pop-Location
