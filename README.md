# BoosterPRO Hub

Interfaccia grafica unificata per ottimizzazione sistema Windows. Sostituisce i precedenti script `.bat` e `.ps1` con un hub centrale a 4 sezioni.

## Requisiti

- **Windows 10 o 11** (build 15063+)
- **PowerShell 5.1+**
- **Eseguire come Amministratore** (gestito automaticamente dal launcher)

## Avvio rapido

**Fare doppio clic su `BoosterPRO.bat`** — gestisce permessi admin, unblocking del file e avvio dell'interfaccia.

> Non lanciare direttamente `BoosterPRO_Start.ps1` — il `.bat` evita problemi di esecuzione policy e profilo PowerShell.

## Sezioni

### 1. REGISTRO (27 tweak)
Tweak di registro raggruppati per categoria:
- **PERFORMANCE**: Kernel timer, multitasking, RAM cleaner, piano prestazioni
- **PRIVACY**: Blocco driver WU, P2P updates, Bing search, suggerimenti, AI/Copilot, stampa
- **GAMING**: Game Bar/DVR (+ elimina popup protocolli), rete gaming, tasti permanenti
- **WINDOWS 11**: Menu classico, ribbon classico, blur blocco, secondi orologio, blocco Edge, bypass TPM
- **NETWORK**: IPv6, client DNS, icone desktop
- **CPU**: TSX Intel, boost Intel, HPET AMD, core parking AMD, unload DLL

**Come usare**: clicca `SKIP` → diventa `OTTIMIZZA` per i tweak desiderati, poi premi `APPLICA TWEAK REGISTRO`. Ogni tweak può essere applicato solo una volta (diventa grigio).

### 2. INTERNET (5 ottimizzazioni)
- **AUTOTUNE**: AutoTuningLevel + CTCP
- **SCALING**: Max connessioni + priorità service provider
- **THROTTLING**: Network Throttling Index
- **NETRESET**: Reset stack TCP/IP (winsock, IP, flushdns, renew) — da abilitare DOPO gli altri tweak
- **ALL**: Applica TUTTO in una volta (AUTOTUNE+SCALING+THROTTLING+NETRESET + extra TCP)

**Utility rapide** (in fondo):
- **EDGE** — applica policy di ottimizzazione Edge (efficiency mode, startup boost off, HW acceleration)
- **WEBVIEW2** — ottimizza WebView2 (limite processi, tracking prevention strict)
- **CLEAN CACHE** — pulisce cache WebView2 di tutte le app

### 3. DEBLOAT (3 sotto-sezioni)
Rimozione app preinstallate:
- **Bloatware Comune** — 16 app Microsoft (News, Skype, Cortana, Solitario, etc.)
- **App Potenzialmente Utili** — 15 app (Note, Fotocamera, Xbox, etc.)
- **Win32 / Altro** — Microsoft Edge e OneDrive

Include log in tempo reale, disabilitazione task telemetria, servizi, SysMain su SSD e riavvio Esplora File.

### 4. SOFTWARE (52 app installabili)
Installa applicazioni tramite **winget**:
- **App Microsoft** — 20 app dallo Store (ID progress)
- **Terze Parti** — 32 app (Firefox, Chrome, Steam, VLC, OBS, VSCode, 7-Zip, etc.)

Lo stato di installazione viene verificato all'avvio della sezione. Le app già installate appaiono in verde e non sono selezionabili. Include log in tempo reale.

## Architettura

```
BoosterPRO.bat              ← Launcher (doppio clic)
BoosterPRO_Start.ps1        ← Hub GUI principale (640 righe)
reg.ps1                     ← Backend tweak registro (999 righe)
src/
  internet.ps1              ← Backend ottimizzazioni rete
  debloat.ps1               ← Backend rimozione bloatware (standalone)
  installer.ps1             ← Backend installazione software (winget)
  free_ram.ps1              ← Script RAM cleaner (eseguito da task pianificato)
  Ottimizza_edge.ps1        ← Policy Edge
  webview_opt.ps1           ← Ottimizzazione WebView2
  Pulisci_chache_webview.ps1 ← Pulizia cache WebView2
  *.png                     ← Loghi (selezionati dinamicamente per colore)
```

Tutti i backend supportano i parametri `-Silent -ApplyOnly @(IDs)` per l'esecuzione headless dall'HUB.

## Note

- Il primo avvio della sezione SOFTWARE esegue `winget list --accept-source-agreements` che potrebbe richiedere qualche secondo
- Dopo l'applicazione dei tweak di registro o rete, **riavviare il sistema** per rendere effettive le modifiche
- Il colore accento dell'interfaccia si adatta automaticamente al tema Windows
- Il logo viene selezionato tra 3 varianti in base alla compatibilità cromatica con l'accento
