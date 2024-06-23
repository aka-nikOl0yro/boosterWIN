@Echo off
echo wscript.Quit((msgbox("eliminare i file temporanei??",4+32, "optimizer")-6) Mod 255) > %temp%\msgbox.vbs
start /wait %temp%\msgbox.vbs
if errorlevel 1 (
echo We have No
) else (
echo Eliminazione dei file temporanei in corso...

del /f /s /q %temp%\*.*
del /f /s /q %windir%\Temp\*.*
del /f /s /q %UserProfile%\AppData\Local\Temp\*.*
del /f /s /q %UserProfile%\AppData\Local\Microsoft\Windows\Temporary Internet Files\*.*
del /f /s /q C:\Windows\prefetch\*.*
del /f /s /q C:\Users\ayrni\AppData\Local\Temp\*.*

echo Eliminazione completata.
)

del %temp%\msgbox.vbs /f /q
timeuot 10
exit

REM winget list
REM winget upgrade list
REM winget upgrade %application%