@echo off
title BoosterPRO Hub
color 0A

:: 0. Unblock all scripts in this folder (remove Mark of the Web)
powershell -NoProfile -Command "Get-ChildItem '%~dp0' -Filter '*.ps1' -Recurse | Unblock-File -ErrorAction SilentlyContinue"
powershell -NoProfile -Command "Get-ChildItem '%~dp0' -Filter '*.bat' -Recurse | Unblock-File -ErrorAction SilentlyContinue"

:: 1. Check admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Permessi di amministratore confermati.
) else (
    echo [*] Richiesta permessi di amministratore in corso...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

:: 2. Set working directory
cd /d "%~dp0"

:: 3. Launch GUI
echo [*] Avvio BoosterPRO Hub...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\BoosterPRO_Start.ps1"
echo [!] Chiusura. Premi un tasto per uscire.
pause >nul