# 🚀 boosterWIN

**boosterWIN** è una raccolta di script batch e PowerShell progettati per ottimizzare, pulire e velocizzare i sistemi operativi Windows.

> ⚠️ **Attenzione:** Questi script modificano file di sistema e chiavi di registro. Utilizza questo software a tuo rischio e pericolo.

## 📂 Contenuto del Repository

Il progetto è suddiviso in diversi moduli per targettizzare aree specifiche del sistema:

| File | Descrizione |
| :--- | :--- |
| **`PUSHME.bat` o `avviaReg.bat`** | Il punto di partenza consigliato per eseguire le ottimizzazioni piu comodamente. |
| **`CCleaner.bat`** |  Script per la rimozione di file temporanei, log inutili e altra "spazzatura" per liberare spazio su disco. |
|**`copiaCCleaner.ps1`**| Script per salvare lo script per il futuro anche dopo l'eliminazione della cartella creando un collegamento al desktop. |
| **`Internet.bat`** | Script dedicato al miglioramento della stabilità della connessione internet. (non fa miracoli) |
| **`reg.ps1`** | Script PowerShell che applica modifiche al registro di sistema per migliorare le prestazioni e la reattività di Windows. |
| **`FIX folder`** | raccolta dei fix per eventuali problemi comuni causati dallo script. |

## 🛠️ Installazione e Utilizzo

1. **Scarica il progetto:**
   Puoi scaricare l'ultimo relase (consigliato) oppure l'intero repository come file ZIP o clonarlo con Git:
   ```bash
   git clone [https://github.com/aka-nikOl0yro/boosterWIN.git](https://github.com/aka-nikOl0yro/boosterWIN.git)

Esegui come Amministratore: Per funzionare correttamente, la maggior parte di questi script richiede privilegi elevati.

## 📂 FIX

| File | Stato | Descrizione |
| :--- | :--- | :--- |
| **`fix1.reg`** | implementato in reg.ps1 dalla V4.1.5 | sistema il problema di flickering delle finestre prodotto dalla versione 4 |
   
⚠️ Disclaimer
Questo software è fornito "così com'è", senza garanzie di alcun tipo. L'autore non è responsabile per eventuali danni, perdita di dati o malfunzionamenti del sistema derivanti dall'uso di questi script.

# Se noti un problema segnalalo cosi io possa provare a sistemarlo

Progetto creato da aka-nikOl0yro
