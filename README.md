# boosterWIN
i've made this project for personal use.

Guida all'Utilizzo dei Menu di Ottimizzazione
Questo documento spiega come utilizzare i menu interattivi presenti negli script di ottimizzazione del sistema.

Menu Principale (PUSHME.bat)
Quando avvii PUSHME.bat come amministratore, visualizzerai questo menu:

***************************************
*      Windows OPTIMIZER PRO v3       *
***************************************

[1] Avvia ottimizzazione completa
[2] Configura modalita ottimizzazione
[3] Esegui solo ottimizzazione Internet
[4] Esegui solo ottimizzazione Registro
[5] Esegui solo CCleaner
[6] Esci

Scelta [1-6]:
Opzioni disponibili:
Ottimizzazione Completa

Esegue tutte le ottimizzazioni in sequenza:
Ottimizzazione del Registro
Ottimizzazione Internet
Pulizia con CCleaner
Al termine, chiede se riavviare il sistema
Configura Modalità Ottimizzazione

Accedi al sottomenu di configurazione
Permette di scegliere tra modalità Gaming o Generale
Ottimizzazione Internet

Avvia solo gli script per ottimizzare la connessione di rete
Utilizza la modalità configurata (Gaming/Generale)
Ottimizzazione Registro

Esegue lo script Reg.ps1 per ottimizzare il registro di sistema
Applica tweak avanzati per prestazioni e stabilità
Pulizia Sistema (CCleaner)

Avvia la pulizia dei file temporanei e cache
Libera spazio su disco
Esci

Termina lo script senza eseguire ottimizzazioni
Menu Configurazione (Sottomenu)
Selezionando l'opzione 2 dal menu principale, accedi a:

****************************************
*   CONFIGURATORE OTTIMIZZAZIONE       *
****************************************

Modalita corrente: 
   general (predefinita)

Scegliere un'opzione:
[1] Imposta modalita GAMING (bassa latenza)
[2] Imposta modalita GENERALE (bilanciata)
[3] Resetta alla configurazione predefinita
[4] Torna al menu principale

Scelta [1-4]:
Opzioni disponibili:
Modalità Gaming

Ottimizzazioni aggressive per bassa latenza
Ideale per gaming e applicazioni real-time
Disabilita effetti visivi e servizi non essenziali
Modalità Generale

Bilanciata tra prestazioni e stabilità
Adatta per uso quotidiano e workstation
Resetta Configurazione

Ripristina le impostazioni predefinite
Elimina il file config.ini
Torna al Menu Principale

Ritorna al menu iniziale senza modifiche
Menu di Ottimizzazione Registro (Reg.ps1)
Quando avvii Reg.ps1 direttamente o tramite il menu principale, visualizzerai:

=== OTTIMIZZAZIONI AVANZATE PER FLUIDITÀ ===
1. Applica ottimizzazioni STANDARD (sicure)
2. Applica ottimizzazioni AGGRESSIVE (solo gaming)
3. Verifica impostazioni
4. Ripristina impostazioni default
Scelta [1-4]:
Opzioni disponibili:
Ottimizzazioni Standard

Modifiche sicure adatte a tutti i sistemi
Migliora prestazioni senza compromettere stabilità
Ottimizzazioni Aggressive

Tweak avanzati per massime prestazioni
Disabilita alcune funzioni di sicurezza
Consigliato solo per sistemi dedicati al gaming
Verifica Impostazioni

Mostra lo stato corrente delle ottimizzazioni
Controlla quali modifiche sono state applicate
Ripristino Default

Annulla tutte le modifiche al registro
Ripristina le impostazioni originali di Windows
Flusso di Utilizzo Tipico
Esegui PUSHME.bat come amministratore
Scegli [2] Configura modalita ottimizzazione
Seleziona [1] Modalita GAMING per ottimizzazioni aggressive
Torna al menu principale con [4]
Scegli [1] Avvia ottimizzazione completa
Al termine, rispondi S per riavviare il sistema
Suggerimenti Avanzati
Accesso Rapido
Puoi eseguire direttamente:

PUSHME.bat 3  # Ottimizza solo Internet
PUSHME.bat 4  # Ottimizza solo il registro
Configurazione Automatica
Crea un file config.ini con contenuto:

MODE=gaming
Monitoraggio Risultati
Dopo l'ottimizzazione, controlla i file di log:

Optimizer_<data>.log per dettagli completi
RegistryBackup_<data>.reg per backup del registro
Ripristino
Per annullare tutte le modifiche:

Esegui Reg.ps1 e scegli l'opzione 4
Importa manualmente il file di backup del registro
