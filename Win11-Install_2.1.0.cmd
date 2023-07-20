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
if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove || goto installprompt
if /i "%~1"=="install" (goto installprompt) else if /i "%~1"=="remove" goto remove
:installprompt


cls
color 07
title Windows 11 installer for incompatible divices
mode 76, 30
set "mastemp=%SystemRoot%\Temp\__MAS"
if exist "%mastemp%\.*" rmdir /s /q "%mastemp%\" %nul%

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:          This program uses "Skip TPM Check on Dynamic Update V10"
echo:                                  By AveYo
echo:             __________________________________________________      
echo:
echo:                         What would you like to do?
echo:
echo:             [1] Install and skip requirements (Reccomended)
echo:             [2] Install normally
echo:             __________________________________________________      
echo:
echo:             [3] Help
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
choice /C:1230 /N
set _erl=%errorlevel%

if %_erl%==4 exit /b
if %_erl%==3 start https://github.com/Mr-Unknown-74/Windows-11-Installer-for-Incompatible-Devices#readme & goto :installprompt
if %_erl%==2 set "regInst=true" & goto install
if %_erl%==1 goto install 
goto :installprompt


:install
cls
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
        echo.
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

REM Skip install if regular
if "%regInst%"=="true" goto RWininstall

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
exit /b
:WinInstall
cls
echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                 The Windows 11 installer will now start.
echo:             __________________________________________________      
echo:
echo:             Dont worry about your files and how everything is.
echo:                           That will not change.
echo:
echo:       DO NOT PANIC WHEN YOU SEE THAT IT'S INSTALLING WINDOWS SERVER.
echo:               It's actually installing your Windows 11 ISO,
echo:   yet it's tricking it into thinking that it's installing windows server.
echo:            This is because windows server installs like Windows 11,
echo:              but has none of the restrictions seen in windows 11.
echo:
echo:               Go through the install like you regularly would.
echo:                   If you decide to cancel the installation,
echo:               re-run the program to automatically uninstall it.
echo:       ______________________________________________________________
echo.
echo Press any key to open the Windows installer.
pause >nul
start "" "%driveLetter%\setup.exe"
exit /b

:RWininstall
cls
echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                 The Windows 11 installer will now start.
echo:             __________________________________________________      
echo:
echo:             Dont worry about your files and how everything is.
echo:                           That will not change.
echo:       ______________________________________________________________
echo.
echo Press any key to open the Windows installer.
pause >nul
start "" "%driveLetter%\setup.exe"
exit /b

:remove
del /f /q "%Public%\get11.cmd" "%ProgramData%\get11.cmd" >nul 2>nul
reg delete "%IFEO%\SetupHost.exe" /f >nul 2>nul


goto AftUninstall
'@); $0 = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.cmd"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0
:AftUninstall
cls
color 07
title Windows 11 installer for incompatible divices
mode 76, 30
set "mastemp=%SystemRoot%\Temp\__MAS"
if exist "%mastemp%\.*" rmdir /s /q "%mastemp%\" %nul%

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                          Successfully Uninstalled
echo:             __________________________________________________      
echo:
echo:                         What would you like to do?
echo:
echo:             [1] Re-Install
echo:             __________________________________________________      
echo:
echo:             [2] Help
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
choice /C:120 /N
set _erl=%errorlevel%

if %_erl%==3 exit /b
if %_erl%==2 start https://github.com/Mr-Unknown-74/Windows-11-Installer-for-Incompatible-Devices#readme & goto :AftUninstall
if %_erl%==1 goto sos
goto :AftUninstall