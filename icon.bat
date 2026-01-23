@echo off
setlocal

:: --- CONFIGURAZIONE ---
:: Assicurati che questo nome sia ESATTO come il tuo file di pulizia
set "TARGET_FILE=CCleaner.bat"
:: Nome che apparirà sul Desktop
set "SHORTCUT_NAME=CCleander"
:: Icona da usare (Uso quella di Pulizia Disco di Windows)
set "ICON_PATH=%SystemRoot%\System32\cleanmgr.exe"

:: --- CONTROLLO ESISTENZA FILE ---
if not exist "%~dp0%TARGET_FILE%" (
    color 0C
    echo.
    echo ERRORE: Non trovo il file "%TARGET_FILE%"!
    echo Assicurati che questo script e il Cleaner siano nella STESSA cartella.
    echo.
    pause
    exit /b
)

echo Creazione collegamento in corso...

:: --- COMANDO POWERSHELL PER CREARE IL LINK ---
powershell -NoProfile -Command ^
    "$WshShell = New-Object -ComObject WScript.Shell; " ^
    "$DesktopPath = [Environment]::GetFolderPath('Desktop'); " ^
    "$Shortcut = $WshShell.CreateShortcut(\"$DesktopPath\%SHORTCUT_NAME%.lnk\"); " ^
    "$Shortcut.TargetPath = '%~dp0%TARGET_FILE%'; " ^
    "$Shortcut.WorkingDirectory = '%~dp0'; " ^
    "$Shortcut.IconLocation = '%ICON_PATH%,0'; " ^
    "$Shortcut.Description = 'Script di pulizia automatica'; " ^
    "$Shortcut.Save()"

color 0A
echo.
echo [OK] Collegamento creato sul Desktop con icona personalizzata!
echo.
timeout /t 3