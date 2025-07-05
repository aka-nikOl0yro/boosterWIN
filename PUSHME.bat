@ECHO OFF
REM BFCPEOPTIONSTART
REM Advanced BAT to EXE Converter www.BatToExeConverter.com
REM ... [altre opzioni] ...
REM BFCPEOPTIONEND

:: ================================================
:: Blocco esecuzioni multiple
:: ================================================
set "LOCKFILE=WindowsOptimizer.lock"
IF EXIST "%LOCKFILE%" (
    ECHO L'ottimizzatore è già in esecuzione!
    ECHO Attendere il completamento dell'operazione corrente...
    TIMEOUT /T 5 >NUL
    EXIT
) ELSE (
    ECHO. > "%LOCKFILE%"
    ATTRIB +H "%LOCKFILE%" >NUL 2>&1
)

:: ================================================
:: Verifica privilegi amministrativi
:: ================================================
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

:: ================================================
:: Ambiente di lavoro
:: ================================================
PUSHD "%~dp0"

:: ================================================
:: Menu principale
:: ================================================
:MAIN_MENU
CLS
ECHO.
ECHO ***************************************
ECHO *      Windows OPTIMIZER PRO v3       *
ECHO ***************************************
ECHO.
ECHO [1] Avvia ottimizzazione completa
ECHO [2] Configura modalita ottimizzazione
ECHO [3] Esegui solo ottimizzazione Internet
ECHO [4] Esegui solo ottimizzazione Registro
ECHO [5] Esegui solo CCleaner
ECHO [6] Esci
ECHO.
CHOICE /C 123456 /N /M "Scelta [1-6]: "

IF ERRORLEVEL 6 GOTO CLEANUP
IF ERRORLEVEL 5 (CALL :RUN_CCLEANER & GOTO MAIN_MENU)
IF ERRORLEVEL 4 (CALL :RUN_REG & GOTO MAIN_MENU)
IF ERRORLEVEL 3 (CALL :RUN_INTERNET & GOTO MAIN_MENU)
IF ERRORLEVEL 2 GOTO CONFIG_MODE
IF ERRORLEVEL 1 GOTO FULL_OPTIMIZATION

:: ================================================
:: Ottimizzazione completa
:: ================================================
:FULL_OPTIMIZATION
CALL :RUN_REG
CALL :RUN_INTERNET
CALL :RUN_CCLEANER
GOTO REBOOT_PROMPT

:: ================================================
:: Configurazione modalita
:: ================================================
:CONFIG_MODE
CLS
ECHO.
ECHO ****************************************
ECHO *   CONFIGURATORE OTTIMIZZAZIONE       *
ECHO ****************************************
ECHO.
ECHO Modalita corrente: 
IF EXIST ".\config.ini" (
    findstr /I /C:"MODE=" ".\config.ini"
) ELSE (
    ECHO general (predefinita)
)
ECHO.
ECHO Scegliere un'opzione:
ECHO [1] Imposta modalita GAMING (bassa latenza)
ECHO [2] Imposta modalita GENERALE (bilanciata)
ECHO [3] Resetta alla configurazione predefinita
ECHO [4] Torna al menu principale
ECHO.
CHOICE /C 1234 /N /M "Scelta [1-4]: "

IF ERRORLEVEL 4 GOTO MAIN_MENU
IF ERRORLEVEL 3 GOTO RESET_CONFIG
IF ERRORLEVEL 2 GOTO SET_GENERAL
IF ERRORLEVEL 1 GOTO SET_GAMING

:SET_GAMING
ECHO MODE=gaming > ".\config.ini"
ECHO Modalita impostata su GAMING!
TIMEOUT /T 2 >NUL
GOTO CONFIG_MODE

:SET_GENERAL
ECHO MODE=general > ".\config.ini"
ECHO Modalita impostata su GENERALE!
TIMEOUT /T 2 >NUL
GOTO CONFIG_MODE

:RESET_CONFIG
DEL ".\config.ini" >NUL 2>&1
ECHO Configurazione resettata a predefinita!
TIMEOUT /T 2 >NUL
GOTO CONFIG_MODE

:: ================================================
:: Esegui ottimizzazione Internet
:: ================================================
:RUN_INTERNET
ECHO.
ECHO === OTTIMIZZAZIONE INTERNET ===
SET "MODE=general"
IF EXIST ".\config.ini" (
    findstr /I /C:"MODE=gaming" ".\config.ini" >nul && SET "MODE=gaming"
)

IF "%MODE%"=="gaming" (
    ECHO [MODE GAMING] Applicazione ottimizzazioni low-latency...
    PowerShell -ExecutionPolicy Bypass -File ".\src\gaming.ps1"
) ELSE (
    ECHO [MODE GENERALE] Applicazione ottimizzazioni bilanciate...
    PowerShell -ExecutionPolicy Bypass -File ".\src\general.ps1"
)
TIMEOUT /T 2 >NUL
EXIT /B

:: ================================================
:: Esegui ottimizzazione Registro
:: ================================================
:RUN_REG
ECHO.
ECHO === OTTIMIZZAZIONE REGISTRO ===

:: Nuovo comando PowerShell
:: PowerShell -ExecutionPolicy Bypass -File ".\Reg.ps1"

:: OPPURE se nella cartella src
PowerShell -ExecutionPolicy Bypass -File ".\src\Reg.ps1"

TIMEOUT /T 2 >NUL
EXIT /B

:: ================================================
:: Esegui CCleaner
:: ================================================
:RUN_CCLEANER
ECHO.
ECHO === PULIZIA SISTEMA ===
start /w .\CCleaner.bat
TIMEOUT /T 2 >NUL
EXIT /B

:: ================================================
:: Prompt riavvio
:: ================================================
:REBOOT_PROMPT
ECHO.
ECHO ***************************************
ECHO *       OTTIMIZZAZIONE COMPLETATA      *
ECHO ***************************************
ECHO.
CHOICE /C SN /N /T 30 /D N /M "Riavviare il computer per applicare le modifiche? [S]i/[N]o"
IF ERRORLEVEL 2 GOTO CLEANUP
ECHO Riavvio in 60 secondi...
SHUTDOWN /R /T 60 /C "Ottimizzazione sistema completata"

:: ================================================
:: Pulizia finale (RIMOZIONE LOCK)
:: ================================================
:CLEANUP
IF EXIST "%LOCKFILE%" (
    ATTRIB -H "%LOCKFILE%" >NUL 2>&1
    DEL "%LOCKFILE%" >NUL 2>&1
)
EXIT