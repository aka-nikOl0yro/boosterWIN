# 🚀 boosterWIN

**boosterWIN** è una raccolta di script batch e PowerShell progettati per ottimizzare, pulire e velocizzare i sistemi operativi Windows.

> ⚠️ **Attenzione:** Questi script modificano file di sistema e chiavi di registro. Si consiglia di creare un punto di ripristino del sistema prima di utilizzarli. Utilizza questo software a tuo rischio e pericolo.

## 📂 Contenuto del Repository

Il progetto è suddiviso in diversi moduli per targettizzare aree specifiche del sistema:

| File | Descrizione |
| :--- | :--- |
| **`PUSHME.bat`** | 🟢 **Script Principale**. Il punto di partenza consigliato per eseguire le ottimizzazioni in sequenza. |
| **`CCleaner.bat`** | 🧹 **Pulizia Sistema**. Script per la rimozione di file temporanei, log inutili e altra "spazzatura" per liberare spazio su disco. |
| **`Internet.bat`** | 🌐 **Ottimizzazione Rete**. Script dedicato al miglioramento della connessione internet. |
| **`reg.ps1`** | ⚙️ **Registry Tweaks**. Script PowerShell che applica modifiche al registro di sistema per migliorare le prestazioni e la reattività di Windows. |
| **`icon.bat`** |  Script di utilità per creare un collegamento per il ccleaner. |

## 🛠️ Installazione e Utilizzo

1. **Scarica il progetto:**
   Puoi scaricare l'ultimo relase (consigliato) oppure l'intero repository come file ZIP o clonarlo con Git:
   ```bash
   git clone [https://github.com/aka-nikOl0yro/boosterWIN.git](https://github.com/aka-nikOl0yro/boosterWIN.git)

Esegui come Amministratore: Per funzionare correttamente, la maggior parte di questi script richiede privilegi elevati.

Clicca con il tasto destro sul file che desideri eseguire (es. PUSHME.bat).

Seleziona "Esegui come amministratore".

PowerShell (reg.ps1): Se hai problemi ad eseguire lo script .ps1, potresti dover abilitare l'esecuzione degli script su PowerShell: apri PowerShell come amministratore e digita:

PowerShell
   ```bash
      Set-ExecutionPolicy RemoteSigned

⚠️ Disclaimer
Questo software è fornito "così com'è", senza garanzie di alcun tipo. L'autore non è responsabile per eventuali danni, perdita di dati o malfunzionamenti del sistema derivanti dall'uso di questi script.

Progetto creato da aka-nikOl0yro
