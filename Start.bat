 @echo off
 CLS
 ECHO.


:init
 setlocal DisableDelayedExpansion
 set cmdInvoke=1
 set winSysFolder=System32
 set "batchPath=%~dpnx0"
 rem this works also from cmd shell, other than %~0
 for %%k in (%0) do set batchName=%%~nk
 set "vbsGetPrivileges=%temp%\OEgetPriv_%batchName%.vbs"
 setlocal EnableDelayedExpansion

:checkPrivileges
  NET FILE 1>NUL 2>NUL
  if '%errorlevel%' == '0' ( goto gotPrivileges ) else ( goto getPrivileges )

:getPrivileges
  if '%1'=='ELEV' (echo ELEV & shift /1 & goto gotPrivileges)
  ECHO.


  ECHO Set UAC = CreateObject^("Shell.Application"^) > "%vbsGetPrivileges%"
  ECHO args = "ELEV " >> "%vbsGetPrivileges%"
  ECHO For Each strArg in WScript.Arguments >> "%vbsGetPrivileges%"
  ECHO args = args ^& strArg ^& " "  >> "%vbsGetPrivileges%"
  ECHO Next >> "%vbsGetPrivileges%"
  
  if '%cmdInvoke%'=='1' goto InvokeCmd 

  ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%vbsGetPrivileges%"
  goto ExecElevation

:InvokeCmd
  ECHO args = "/c """ + "!batchPath!" + """ " + args >> "%vbsGetPrivileges%"
  ECHO UAC.ShellExecute "%SystemRoot%\%winSysFolder%\cmd.exe", args, "", "runas", 1 >> "%vbsGetPrivileges%"

:ExecElevation
 "%SystemRoot%\%winSysFolder%\WScript.exe" "%vbsGetPrivileges%" %*
 exit /B

:gotPrivileges
 setlocal & cd /d %~dp0
 if '%1'=='ELEV' (del "%vbsGetPrivileges%" 1>nul 2>nul  &  shift /1)


echo ^@echo off > Code\Win11UpgradeTemp\runcopy.bat
echo cd "%CD%" >> Code\Win11UpgradeTemp\runcopy.bat
echo powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%CD%\extract.ps1\" -_vLUF %_vLUF%'" >> Code\Win11UpgradeTemp\runcopy.bat
echo exit >> Code\Win11UpgradeTemp\runcopy.bat

echo ^@echo off > Code\Win11UpgradeTemp\runsetup.bat
echo cd "%CD%" >> Code\Win11UpgradeTemp\runsetup.bat
echo start "" "%CD%\Code\ISO\Setup.exe" >> Code\Win11UpgradeTemp\runsetup.bat
echo exit >> Code\Win11UpgradeTemp\runsetup.bat

xCopy "%CD%\Code\Win11UpgradeTemp\" "c:\Win11UpgradeTemp\" /E /F /Q

Start "" "%CD%\code\check.cmd"