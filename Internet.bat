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
REM BFCPEVERPRODUCT=Product Name
REM BFCPEVERDESC=Product Description
REM BFCPEVERCOMPANY=Your Company
REM BFCPEVERCOPYRIGHT=Copyright Info
REM BFCPEWINDOWCENTER=1
REM BFCPEDISABLEQE=0
REM BFCPEWINDOWHEIGHT=30
REM BFCPEWINDOWWIDTH=120
REM BFCPEWTITLE=Window Title
REM BFCPEEMBED=C:\Users\ayrni\Desktop\script\boosterPRO\internetboosterPRO.bat
REM BFCPEEMBED=C:\Users\ayrni\Desktop\script\boosterPRO\imm1.png
REM BFCPEEMBED=C:\Users\ayrni\Desktop\script\boosterPRO\internet.ps1
REM BFCPEEMBED=C:\Users\ayrni\Desktop\script\boosterPRO\tcp1.png
REM BFCPEEMBED=C:\Users\ayrni\Desktop\script\boosterPRO\tcp2.png
REM BFCPEOPTIONEND
@echo off
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
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

pushd "%~dp0"

 timeout 1
 echo ricerca di aggiornamenti...
wuauclt.exe /detectnow /updatenow

if exist "Iinternet" (
 start internetboosterPRO.bat
 exit
 ) else (
 type nul>Internet
  attrib +H Internet 
)

:gpedit
timeout 6
IF EXIST C:\Windows\System32\gpedit.msc (
goto choice
) ELSE (
start /w .\src\Gpedit.bat
goto SKIP)
:choice
choice /c yn /cs /t 800 /d n /m "aprire il gpedit?"
if errorlevel 2 goto SKIP
if errorlevel 1 goto OPEN


:OPEN
color 04
echo aggiona le impostazioni come da immagine
start gpedit.msc
start /w .\immagini\imm1.png
goto FINE
pause

:SKIP
echo skipped
goto FINE
pause


:FINE
color 07
echo gpedit configurato
timeout 5 > nul
choice /c yn /cs /t 800 /d n /m "aprire l'optimizer (non consigliato)"
if errorlevel 2 goto SKIP1
if errorlevel 1 goto RUN
:RUN
color 82
echo seleziona 'custom' in basso a destra e aggiorna le impostazioni come da immagini.
echo prima di cambiare pagina clicca su applica, attendi che vengano elaboate le modifiche e scegliere di non riavviare.
echo quindi cambiare sezione
start .\immagini\tcp1.png & .\immagini\tcp2.png
start /w .\src\TCPOptimizer.exe
goto FINE1
:SKIP1
echo running anyway ;)
.\src\internet.ps1
timeout 4 > nul
:FINE1
timeout 5 > nul
color 07
choice /c yn /cs /t 4 /d y /m "procedere con l'ottimizzazione dei driver?"
if errorlevel 2 goto reboot
if errorlevel 1 start /w .\src\internetboosterPRO.bat
:reboot
choice /c yn /cs /t 400 /d n /m "riavviare il computer per applicare le modifiche"
if errorlevel 2 (
timeout 40 > nul
exit)
if errorlevel 1 shutdown /r -t 40
pause