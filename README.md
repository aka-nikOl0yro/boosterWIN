# 🚀 boosterWIN

**boosterWIN** è una raccolta di script Batch e PowerShell progettati per ottimizzare, pulire e velocizzare sistemi Windows 10/11.

> ⚠️ **Attenzione:** Questi script modificano file di sistema, chiavi di registro e impostazioni di rete. Crea un punto di ripristino prima di procedere e utilizza questo software a tuo rischio e pericolo.

---

## 📋 Requisiti

- Windows 10 / Windows 11
- Privilegi di **Amministratore**
- PowerShell 5.1 o superiore

---

## 📂 Struttura del Repository

```
boosterWIN/
├── CCleaner.bat          # Pulizia file temporanei (GUI)
├── Internet.bat          # Ottimizzazione connessione internet
├── avviaReg.bat          # Launcher principale per reg.ps1
├── PUSHME.bat            # Punto di avvio alternativo consigliato
├── copiaCCleaner.ps1     # Installa collegamento al desktop
├── reg.ps1               # Ottimizzazioni registro di sistema
├── src/
│   ├── internet.ps1          # Tweaks avanzati TCP/IP via PowerShell
│   ├── internetboosterPRO.bat # Reset stack di rete (Winsock, IP, DNS)
│   ├── dns.ps1               # Configurazione DNS ottimizzati
│   ├── debloat.ps1           # Rimozione app preinstallate inutili
│   ├── free_ram.ps1          # Liberazione RAM
│   ├── Gpedit.bat            # Installazione/configurazione gpedit.msc
│   └── TCPOptimizer.exe      # SG TCP Optimizer (tool esterno)
├── immagini/
│   ├── imm1.png              # Guida impostazioni Gpedit (QoS)
│   ├── tcp1.png              # Guida TCP Optimizer - General Settings
│   └── tcp2.png              # Guida TCP Optimizer - Advanced Settings
└── FIX/
    ├── fix1.reg        # Fix flickering finestre (post v4.1.5: già incluso in reg.ps1)
    └── fix_login.reg   # Fix accesso account ms
```

---

## 🛠️ Installazione

**Scarica l'ultima release** (consigliato):
> Vai su [Releases](https://github.com/aka-nikOl0yro/boosterWIN/releases) e scarica l'ultimo archivio `.zip`.

Oppure clona il repository:
```bash
git clone https://github.com/aka-nikOl0yro/boosterWIN.git
```

> **Importante:** Estrai tutti i file mantenendo la struttura delle cartelle. Gli script si aspettano di trovare le sottocartelle `src/` e `immagini/` nella stessa directory.

---

## ▶️ Utilizzo

Tutti gli script richiedono di essere eseguiti **come Amministratore**. Il sistema UAC verrà richiesto automaticamente se non si è già in un contesto elevato.

### 1. `PUSHME.bat` / `avviaReg.bat` — Ottimizzazioni Registro
Punto di partenza consigliato. Esegue `reg.ps1` applicando una serie di tweaks al registro di Windows per migliorare reattività e prestazioni. Genera un file `reg.log` con il resoconto di tutte le modifiche apportate.

### 2. `CCleaner.bat` — Pulizia File Temporanei
Apre un'interfaccia grafica (GUI) che:
- Scansiona automaticamente tutti i dischi fissi alla ricerca di cartelle `temp` e `tmp`
- Permette di selezionare/deselezionare le cartelle da pulire per singolo disco
- Elimina solo i file più vecchi di 24 ore (per sicurezza)
- Può svuotare il Cestino di Windows
- Salva la configurazione per le esecuzioni successive

### 3. `Internet.bat` — Ottimizzazione Connessione
Script interattivo che guida l'utente attraverso più fasi di ottimizzazione della rete:

1. **Aggiornamento Windows** — forza la ricerca di aggiornamenti
2. **Gpedit (QoS)** — se disponibile, apre il Group Policy Editor con la guida visiva (`imm1.png`) per impostare la larghezza di banda riservata a **0%** (default 20%)
3. **SG TCP Optimizer** *(opzionale)* — apre il tool con le guide (`tcp1.png`, `tcp2.png`) per applicare i profili custom consigliati
4. **internetboosterPRO** — reset completo dello stack di rete (Winsock, IP, DNS cache)

### 4. `copiaCCleaner.ps1` — Collegamento Desktop
Crea un collegamento sul Desktop a `CCleaner.bat` in modo da poterlo eseguire rapidamente anche dopo aver spostato o rimosso la cartella originale.

---

## 🔧 Impostazioni Consigliate

### Gpedit — QoS Scheduler (`imm1.png`)
Percorso: `Modelli Amministrativi → Rete → Utilità di pianificazione pacchetti QoS → Limita larghezza di banda riservabile`
- Stato: **Attivata**
- Limite larghezza di banda: **0%**

### SG TCP Optimizer — General Settings (`tcp1.png`)
- Connection Speed: massima velocità della tua connessione
- Modify All Network Adapters: ✅
- Choose settings: **Custom**
- TCP Window Auto-Tuning: `normal`
- Windows Scaling heuristics: `disabled`
- Congestion Control Provider: `ctcp`

### SG TCP Optimizer — Advanced Settings (`tcp2.png`)
- NetworkThrottlingIndex: `disabled: ffffffff`
- SystemResponsiveness: `gaming: 0`
- TcpAckFrequency: `disabled: 1`
- TCPNoDelay: `enabled: 1`
- MaxUserPort: `65534`
- TcpTimedWaitDelay: `30`

---

## 🩹 FIX

| Fix | Stato | Descrizione |
|-----|-------|-------------|
| `fix1.reg` | ✅ Integrato in `reg.ps1` dalla v4.1.5 | Risolve il flickering delle finestre introdotto dalla versione 4 |
| `fix_login.reg` | ✅ Integrato in `reg.ps1` dalla v4.1.6 | Risolve il problema che impediva l'accesso all'accuont ms |

---

## ⚠️ Disclaimer

Questo software è fornito **"così com'è"**, senza garanzie di alcun tipo. L'autore non è responsabile per danni, perdita di dati o malfunzionamenti derivanti dall'uso di questi script. Si consiglia di **creare un punto di ripristino del sistema** prima di eseguire qualsiasi script.

---

## 💬 Supporto e Community

Hai trovato un bug o vuoi suggerire una miglioria? Apri una [Issue](https://github.com/aka-nikOl0yro/boosterWIN/issues) oppure entra nel nostro server Discord:


[![Discord](https://img.shields.io/discord/1422660832017518694?label=Discord&logo=discord&style=flat-square&color=5865F2)](https://discord.gg/sStBFCepAm)

---

*Progetto creato da [aka-nikOl0yro](https://github.com/aka-nikOl0yro)*
