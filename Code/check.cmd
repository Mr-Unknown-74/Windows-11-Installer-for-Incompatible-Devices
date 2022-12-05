@echo off & title Windows 11 installer for incompatible divices
:sos
@(set '(=)||' <# lean and mean cmd / powershell hybrid #> @'
if /i "%~f0" neq "%Public%\get11.cmd" goto setup
set CLI=%*& set SOURCES=%SystemDrive%\$WINDOWS.~BT\Sources& set MEDIA=.& set /a VER=11
if not defined CLI (exit /b) else if not exist %SOURCES%\SetupHost.exe (exit /b)
if not exist %SOURCES%\SetupCore.exe mklink /h %SOURCES%\SetupCore.exe %SOURCES%\SetupHost.exe >nul
for %%W in (%CLI%) do if /i %%W == /InstallFile (set "MEDIA=") else if not defined MEDIA set "MEDIA=%%~dpW"
powershell -win 1 -nop -c ";"
set /a restart_application=0x800705BB & (call set CLI=%%CLI:%1 =%%)
set /a incorrect_parameter=0x80070057 & (set SRV=%CLI:/Product Client =%)
set /a launch_option_error=0xc190010a & (set SRV=%SRV:/Product Server =%)
if %VER% == 11 for %%W in ("%MEDIA%appraiserres.dll") do if exist %%W if %%~zW == 0 set AlreadyPatched=1 & set /a VER=10
if %VER% == 11 findstr /r "P.r.o.d.u.c.t.V.e.r.s.i.o.n...1.0.\..0.\..2.[256]" %SOURCES%\SetupHost.exe >nul 2>nul || set /a VER=10
if %VER% == 11 if not exist "%MEDIA%EI.cfg" (echo;[Channel]>%SOURCES%\EI.cfg & echo;_Default>>%SOURCES%\EI.cfg) 2>nul
if %VER% == 11 (set CLI=/Product Server /Compat IgnoreWarning /MigrateDrivers All /Telemetry Disable %SRV%)
if %VER% == 11 reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v DisableWUfBSafeguards /d 1 /t reg_dword >nul
if %VER% == 11 reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword >nul
%SOURCES%\SetupCore.exe %CLI%
if %errorlevel% == %restart_application% %SOURCES%\SetupCore.exe %CLI%
exit /b
:setup
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)
for /f "delims=:" %%s in ('echo;prompt $h$s$h:^|cmd /d') do set "|=%%s"&set ">>=\..\c nul&set /p s=%%s%%s%%s%%s%%s%%s%%s<nul&popd"
set "<=pushd "%appdata%"&2>nul findstr /c:\ /a" &set ">=%>>%&echo;" &set "|=%|:~0,1%" &set /p s=\<nul>"%appdata%\c"
set CLI=%*& (set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options)
wmic /namespace:"\\root\subscription" path __EventFilter where Name="Skip TPM Check on Dynamic Update" delete >nul 2>nul & rem v1
reg delete "%IFEO%\vdsldr.exe" /f 2>nul & rem v2 - v5
if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove || goto install
if /i "%~1"=="install" (goto install) else if /i "%~1"=="remove" goto remove
:install
start "" "c:\Win11UpgradeTemp\runcopy.bat"
exit
:remove
del /f /q "%Public%\get11.cmd" "%ProgramData%\get11.cmd" >nul 2>nul
reg delete "%IFEO%\SetupHost.exe" /f >nul 2>nul
@RD /S /Q "c:\Win11UpgradeTemp\"
goto AftUninstall
'@); $0 = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.cmd"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0
:AftUninstall
echo Successfully Uninstalled.
echo.
echo You can start again to re-install.
echo.
pause
exit