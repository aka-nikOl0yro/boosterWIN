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
REM BFCPEOPTIONEND
@echo off
echo wscript.Quit((msgbox("Aprire InternetOptimizer?",4+32, "")-6) Mod 255) > %temp%\Internetmsg.vbs
echo wscript.Quit((msgbox("Aprire RegistryOptimizer?",4+32, "")-6) Mod 255) > %temp%\Regmsg.vbs
echo wscript.Quit((msgbox("Aprire CCleaner?",4+32, "")-6) Mod 255) > %temp%\CCmsg.vbs

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

start /w %temp%\Regmsg.vbs
if errorlevel 1 goto Internet
start /w .\Reg.bat
timeout 5
:Internet
start /w %temp%\Internetmsg.vbs
if errorlevel 1 goto Clean
start /w .\Internet.bat
timeout 5
:Clean
start /w %temp%\CCmsg.vbs
if errorlevel 1 goto Exit
start /w .\CCleaner.bat
timeout 5
:Exit
echo ottimizzazione completata
echo premere invio
pause > nul
choice /c yn /cs /t 400 /d n /m "riavviare il computer per applicare le modifiche"
if errorlevel 2 (
timeout 2
exit)
if errorlevel 1 shutdown /r -t 40