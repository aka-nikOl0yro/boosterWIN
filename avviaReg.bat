@echo off
title Avvio Script di Ottimizzazione con Log
color 0A

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

:: 3. Esegue lo script PowerShell registrando tutto in reg.log
echo.
echo [*] Avvio dell'ottimizzazione e registrazione nel file reg.log...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path 'reg.log' -Append; & '.\reg.ps1'; Stop-Transcript"

:: 4. Fine
echo.
echo [!] Esecuzione terminata. Puoi controllare eventuali errori aprendo 'reg.log'.
pause