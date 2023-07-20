@echo off & title Windows 11 installer for incompatible divices
:sos
cls
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

setlocal enabledelayedexpansion

echo Please select a Windows ISO file.

rem Create a temporary PowerShell script to open the file explorer dialog
set "ps1File=%TEMP%\filechooser.ps1"

echo Add-Type -AssemblyName System.Windows.Forms > "%ps1File%"
echo $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog >> "%ps1File%"
echo $fileBrowser.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*" >> "%ps1File%"
echo $fileBrowser.InitialDirectory = $env:userprofile >> "%ps1File%"
echo $fileBrowser.Title = "Select ISO File" >> "%ps1File%"
echo $fileBrowser.ShowHelp = $true >> "%ps1File%"
echo $fileBrowser.Multiselect = $false >> "%ps1File%"
echo $fileBrowser.CheckFileExists = $true >> "%ps1File%"
echo $fileBrowser.CheckPathExists = $true >> "%ps1File%"
echo $result = $fileBrowser.ShowDialog() >> "%ps1File%"
echo if ($result -eq [System.Windows.Forms.DialogResult]::OK) { Write-Output $fileBrowser.FileName } >> "%ps1File%"

rem Run the PowerShell script and capture the result (selected file path)
for /f "usebackq delims=" %%I in (`powershell -ExecutionPolicy Bypass -File "%ps1File%"`) do (
    set "isoPath=%%I"
)
cls
if "%isoPath%"=="" (
    echo No ISO file was selected... Press any key to exit.
    pause >nul
    exit /b
)

for %%A in ("%isoPath%") do (
    if /i "%%~xA" == ".iso" (
        goto aftisochecks
    ) else (
        echo The selected file is not an ISO file... Press any key to exit.
        pause >nul
        exit /b
    )
)

:aftisochecks

rem dismounts iso file that is potentially mounted
powershell -Command "Dismount-DiskImage -ImagePath '%isoPath%'" >nul

echo Selected ISO file location: "%isoPath%"
echo.

rem Remove the temporary PowerShell script
del "%ps1File%"

rem Loop through drive letters from D to Z
for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z A B C) do (
    rem Check if the drive letter is unused
    if not exist "%%i:\" (
        echo Using drive letter %%i...
        set driveLetter=%%i:
        goto aftdriveletter
        exit /b
    )
)

echo No unused drive letter found... Press any key to exit.
pause >nul
exit /b
:aftdriveletter
set "ps1File=%TEMP%\mount.ps1"

REM Create the PowerShell script
echo $diskImg = Mount-DiskImage -ImagePath "%isoPath%" -NoDriveLetter > "%ps1File%"
echo $volInfo = $diskImg ^| Get-Volume >> "%ps1File%"
echo if ($volInfo -eq $null^) { >> "%ps1File%"
echo     Write-Host "Disk image mounting failed. Check if the file path is correct and if you have administrative privileges." >> "%ps1File%"
echo } else { >> "%ps1File%"
echo     $driveLetter = "%driveLetter%" >> "%ps1File%"
echo     mountvol $driveLetter $volInfo.UniqueId >> "%ps1File%"
echo     Write-Host "Mounted volume with UniqueId $($volInfo.UniqueId) to drive letter $driveLetter" >> "%ps1File%"
echo } >> "%ps1File%"

REM Call the PowerShell script
powershell -ExecutionPolicy Bypass -File "%ps1File%"

REM Delete the PowerShell script
del "%ps1File%"



:sos2
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
if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove2 || goto install2
if /i "%~1"=="install" (goto install2) else if /i "%~1"=="remove" goto remove2
:install2
copy /y "%~f0" "%Public%\get11.cmd" >nul 2>nul
reg add "%IFEO%\SetupHost.exe" /f /v UseFilter /d 1 /t reg_dword >nul
reg add "%IFEO%\SetupHost.exe\0" /f /v FilterFullPath /d "%SystemDrive%\$WINDOWS.~BT\Sources\SetupHost.exe" >nul
reg add "%IFEO%\SetupHost.exe\0" /f /v Debugger /d "%Public%\get11.cmd" >nul
goto WinInstall
:remove2
echo It Looks like an error occurred!
echo Interestingly, it should not be possible for you to get here, unless you were using version 1.1.0.
echo Of course, this is not the original message that showed up here, rather it was "You are not supposed to open this program."
echo In that case you would have had to have this program install, and then run install.cmd, which was merged into this file.
echo Thats why this was originally here. I just felt like not getting rid of it. Not much of a reason why.
echo Just a tinbit of info... Press any key to exit.
pause >nul
exit /b
:WinInstall
echo.
echo This program uses code from "Skip TPM Check on Dynamic Update V10", made by AveYo on github.
echo https://github.com/AveYo/MediaCreationTool.bat/blob/main/bypass11/Skip_TPM_Check_on_Dynamic_Update.cmd
echo ------------------------------------------------------------------------------------------------------------
echo The Windows 11 installer will now start.
echo Dont worry about your files and how everything is. That will not change.
echo DO NOT PANIC WHEN YOU SEE THAT IT IS INSTALLING WINDOWS SERVER.
echo It is actually installing your Windows 11 ISO, but it is tricking it into thinking that it is installing windows server.
echo This is because windows server installs like Windows 11, but has none of the restrictions seen in windows 11.
echo Go through the install like you regularly would.
echo If you decide to cancel that installation, make sure to eject the iso file if its still mounted, and re-run the program to automatically uninstall it.
echo.
timeout /t 10
pause
start "" "%driveLetter%\setup.exe"
exit /b

:remove
del /f /q "%Public%\get11.cmd" "%ProgramData%\get11.cmd" >nul 2>nul
reg delete "%IFEO%\SetupHost.exe" /f >nul 2>nul


goto AftUninstall
'@); $0 = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.cmd"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0
:AftUninstall
echo Successfully Uninstalled.
echo.

setlocal enabledelayedexpansion

set /p choice=Would you like to re-install? (y/n): 
echo.


if "%choice%"=="y" (
    goto sos
) else if "%choice%"=="n" (
    exit /b
) else if "%choice%"=="yes" (
    goto sos
) else if "%choice%"=="no" (
    exit /b
) else if "%choice%"=="Y" (
    goto sos
) else if "%choice%"=="N" (
    exit /b
) else if "%choice%"=="YES" (
    goto sos
) else if "%choice%"=="NO" (
    exit /b
) else (
    echo Invalid choice... Will not re-install. If you want to re-install, re-run the program.
    echo Press any key to exit.
    pause >nul
    exit /b
)