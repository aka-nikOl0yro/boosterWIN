@echo off

:: 1. Controllo dei privilegi di amministratore
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Permessi di amministratore confermati.
) else (
    echo [*] Richiesta permessi di amministratore in corso...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. Imposta la cartella di lavoro corrente su quella dello script
cd /d "%~dp0"

dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt
dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt

for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i"
timeout 2

:OPEN
echo aggiona le impostazioni come da immagine
start gpedit.msc
start imm1.png
timeout 30
goto FINE
pause

:FINE
echo gpedit configurato
timeout 15
exit