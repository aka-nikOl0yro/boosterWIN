@ECHO OFF
REM BFCPEOPTIONSTART
REM Advanced BAT to EXE Converter www.BatToExeConverter.com
REM BFCPEEXE=
REM BFCPEICON=
REM BFCPEICONINDEX=-1
REM BFCPEEMBEDDISPLAY=0
REM BFCPEEMBEDDELETE=1
REM BFCPEADMINEXE=0
REM BFCPEINVISEXE=0
REM BFCPEVERINCLUDE=0
REM BFCPEVERVERSION=1.0.0.0
REM BFCPEVERPRODUCT=Internet Optimizer Pro
REM BFCPEVERDESC=Ottimizzatore di connessione Internet
REM BFCPEVERCOMPANY=Your Company Name
REM BFCPEVERCOPYRIGHT=Copyright © 2023
REM BFCPEWINDOWCENTER=1
REM BFCPEDISABLEQE=0
REM BFCPEWINDOWHEIGHT=30
REM BFCPEWINDOWWIDTH=120
REM BFCPEWTITLE=Internet Optimizer Pro
REM BFCPEEMBED=.\internetboosterPRO.bat
REM BFCPEEMBED=.\immagini\imm1.png
REM BFCPEEMBED=.\src\internet.ps1
REM BFCPEEMBED=.\immagini\tcp1.png
REM BFCPEEMBED=.\immagini\tcp2.png
REM BFCPEOPTIONEND

:: ================================================
:: Verifica privilegi amministrativi
:: ================================================
NET FILE >NUL 2>&1
IF '%ERRORLEVEL%' NEQ '0' (
    ECHO Richiesta privilegi amministrativi...
    PowerShell -Command "Start-Process -Verb RunAs -FilePath '%~s0' -ArgumentList ''"
    EXIT /B
)

:: ================================================
:: Imposta ambiente di lavoro
:: ================================================
PUSHD "%~dp0"

:: ================================================
:: Controllo aggiornamenti Windows
:: ================================================
ECHO Ricerca aggiornamenti Windows in corso...
PowerShell -Command "& { (New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow() }"
TIMEOUT /T 3 /NOBREAK >NUL

:: ================================================
:: Gestione file lock
:: ================================================
IF EXIST "Internet.lock" (
    ECHO Ottimizzazione già in corso...
    START "" "internetboosterPRO.bat"
    EXIT
) ELSE (
    COPY NUL "Internet.lock" >NUL
    ATTRIB +H "Internet.lock"
)

:: ================================================
:: Configurazione Group Policy Editor
:: ================================================
CHOICE /C SN /N /T 15 /D S /M "Configurare le politiche di gruppo? [S]i/[N]o"
IF ERRORLEVEL 2 GOTO SKIP_GPEDIT

IF NOT EXIST "%SystemRoot%\System32\gpedit.msc" (
    ECHO Installazione componente GPEdit...
    START /WAIT "" ".\src\Gpedit.bat"
    IF NOT EXIST "%SystemRoot%\System32\gpedit.msc" (
        ECHO [ERRORE] Installazione GPEdit fallita
        GOTO SKIP_GPEDIT
    )
)

ECHO Configurare come mostrato nell'immagine...
START "" "%SystemRoot%\System32\gpedit.msc"
START "" ".\immagini\imm1.png"
TIMEOUT /T 5 /NOBREAK >NUL

:SKIP_GPEDIT
ECHO Configurazione GPEdit completata.

:: ================================================
:: Ottimizzazione TCP/IP
:: ================================================
SET "MODE=general"
IF EXIST ".\config.ini" (
    findstr /I /C:"MODE=gaming" ".\config.ini" >nul && SET "MODE=gaming"
)

CHOICE /C SN /N /T 15 /D N /M "Avviare TCP optimizer? (non consigliato) [S]i/[N]o"
IF ERRORLEVEL 2 GOTO SKIP_OPTIMIZER

ECHO Configurare con le impostazioni illustrate...
START "" ".\immagini\tcp1.png"
START "" ".\immagini\tcp2.png"
START /WAIT "" ".\src\TCPOptimizer.exe"

:SKIP_OPTIMIZER
ECHO Applicazione impostazioni di rete...
IF "%MODE%"=="gaming" (
    ECHO [MODE GAMING] Applicazione ottimizzazioni low-latency...
    PowerShell -ExecutionPolicy Bypass -File ".\src\gaming.ps1"
) ELSE (
    ECHO [MODE GENERALE] Applicazione ottimizzazioni bilanciate...
    PowerShell -ExecutionPolicy Bypass -File ".\src\general.ps1"
)
:: ================================================
:: Ottimizzazione driver di rete
:: ================================================
CHOICE /C SN /N /T 10 /D S /M "Ottimizzare i driver di rete? [S]i/[N]o"
IF ERRORLEVEL 2 GOTO REBOOT_CHECK
START /WAIT "" "internetboosterPRO.bat"

:: ================================================
:: Gestione riavvio sistema
:: ================================================
:REBOOT_CHECK
CHOICE /C SN /N /T 30 /D N /M "Riavviare il computer per applicare le modifiche? [S]i/[N]o"
IF ERRORLEVEL 2 GOTO CLEANUP
ECHO Riavvio in 60 secondi...
SHUTDOWN /R /T 60 /C "Ottimizzazione connessione Internet completata"

:CLEANUP
DEL "Internet.lock" >NUL 2>&1
EXIT /B