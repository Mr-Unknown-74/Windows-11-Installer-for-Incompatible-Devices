@echo off & title Windows 11 installer for incompatible devices

set "txtPath=%TEMP%\isofilelocation.txt"
set "isoPath="

REM Check if the file exists
if not exist "%txtPath%" (
    goto aftunmountcheck
)

REM Read the second line of the file
set "lineNumber=1"
for /f "usebackq skip=%lineNumber% delims=" %%a in ("%txtPath%") do (
    set "secondLine=%%a"
    goto :readSecondLine
)

:readSecondLine
REM Read the second line again to avoid exiting the loop prematurely
set /a "lineNumber+=1"
for /f "usebackq skip=%lineNumber% delims=" %%a in ("%txtPath%") do (
    set "secondLine=%%a"
    goto :checkSecondLine
)

:checkSecondLine
REM Check if "regInst" is present in the second line
echo %secondLine% | find /i "regInst" > nul
if %errorlevel% equ 0 (
    goto isomountcheck
) else (
    goto aftunmountcheck
)

:isomountcheck
::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)
title Getting Ready - Windows 11 installer for incompatible devices
mode 76, 30

set /p "isoPath=" < "%txtPath%"

set "ps1File=%TEMP%\isomount.ps1"

REM Creating the PowerShell script

echo function Get-AttachedValue { > "%ps1File%"
echo     param ( >> "%ps1File%"
echo         [string]$InputString >> "%ps1File%"
echo     ) >> "%ps1File%"
echo     # Split the input string into lines >> "%ps1File%"
echo     $lines = $InputString -split "`r?`n" >> "%ps1File%"
echo     # Look for the line that contains "Attached:" and get the value after it >> "%ps1File%"
echo     $attachedLine = $lines ^| Where-Object { $_ -match '^^\s*Attached\s*:\s*(.*)$' } >> "%ps1File%"
echo     if ($attachedLine) { >> "%ps1File%"
echo         $attachedValue = $matches[1].Trim() >> "%ps1File%"
echo         return $attachedValue >> "%ps1File%"
echo     } >> "%ps1File%"
echo     return $null >> "%ps1File%"
echo } >> "%ps1File%"
echo $isoInfo = Invoke-Expression -Command '(Get-DiskImage -ImagePath %isoPath%)' ^| Out-String >> "%ps1File%"
echo # Call the function with the example input >> "%ps1File%"
echo $result = Get-AttachedValue -InputString $isoInfo >> "%ps1File%"
echo if ($result) { >> "%ps1File%"
echo     #Nice >> "%ps1File%"
echo } else { >> "%ps1File%"
echo     $result = "Error" >> "%ps1File%"
echo } >> "%ps1File%"
echo $result >> "%ps1File%"

REM Running the PowerShell script and capturing the result
for /f "usebackq delims=" %%i in (`powershell -ExecutionPolicy Bypass -File "%ps1File%"`) do set "result=%%i"

REM Cleaning up the PowerShell script
del "%ps1File%"

REM diciding what to do (unmount, not unmount, or display an error and continue)
if "%result%"=="True" (
    goto unmountiso
) else if "%result%"=="False" (
    del "%TEMP%\isofilelocation.txt"
    goto aftunmountcheck
) else (
    del "%TEMP%\isofilelocation.txt"
    goto aftunmountcheck
)


:unmountiso
title Unmounting - Windows 11 installer for incompatible devices
mode 76, 30
rem dismounts iso file that is potentially mounted
powershell -Command "Dismount-DiskImage -ImagePath '%isoPath%'" >nul
del "%TEMP%\isofilelocation.txt"

goto aftunmount

:aftunmountcheck
:sos
cls
title Getting Ready - Windows 11 installer for incompatible devices
@(set '(=)||' <# lean and mean cmd / powershell hybrid #> @'

::# Get 11 on 'unsupported' PC via Windows Update or mounted ISO (no patching needed)
::# V12: refined method, no Server label; future proofing; tested with 25905 iso, wu and the new wu repair version  

if /i "%~f0" neq "%SystemDrive%\Scripts\get11.cmd" goto setup
powershell -win 1 -nop -c ";"
set CLI=%*& set SOURCES=%SystemDrive%\$WINDOWS.~BT\Sources& set MEDIA=.& set MOD=CLI& set PRE=WUA& set /a VER=11
if not defined CLI (exit /b) else if not exist %SOURCES%\SetupHost.exe (exit /b)
if not exist %SOURCES%\WindowsUpdateBox.exe mklink /h %SOURCES%\WindowsUpdateBox.exe %SOURCES%\SetupHost.exe
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v DisableWUfBSafeguards /d 1 /t reg_dword
reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword
set OPT=/Compat IgnoreWarning /MigrateDrivers All /Telemetry Disable
set /a restart_application=0x800705BB & (call set CLI=%%CLI:%1 =%%)
set /a incorrect_parameter=0x80070057 & (set SRV=%CLI:/Product Client =%)
set /a launch_option_error=0xc190010a & (set SRV=%SRV:/Product Server =%)
for %%W in (%CLI%) do if /i %%W == /PreDownload (set MOD=SRV)
for %%W in (%CLI%) do if /i %%W == /InstallFile (set PRE=ISO& set "MEDIA=") else if not defined MEDIA set "MEDIA=%%~dpW"
if %VER% == 11 for %%W in ("%MEDIA%appraiserres.dll") do if exist %%W if %%~zW == 0 set AlreadyPatched=1 & set /a VER=10
if %VER% == 11 findstr /r "P.r.o.d.u.c.t.V.e.r.s.i.o.n...1.0.\..0.\..2.[2-9]" %SOURCES%\SetupHost.exe >nul 2>nul || set /a VER=10
if %VER% == 11 if not exist "%MEDIA%EI.cfg" (echo;[Channel]>%SOURCES%\EI.cfg & echo;_Default>>%SOURCES%\EI.cfg)
if %VER%_%PRE% == 11_ISO (%SOURCES%\WindowsUpdateBox.exe /Product Server /PreDownload /Quiet %OPT%)
if %VER%_%PRE% == 11_ISO (del /f /q %SOURCES%\appraiserres.dll 2>nul & cd.>%SOURCES%\appraiserres.dll)
if %VER%_%MOD% == 11_SRV (set ARG=%OPT% %SRV% /Product Server)
if %VER%_%MOD% == 11_CLI (set ARG=%OPT% %CLI%)
%SOURCES%\WindowsUpdateBox.exe %ARG%
if %errorlevel% == %restart_application% %SOURCES%\WindowsUpdateBox.exe %ARG%
exit /b

:setup
::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)

::# toggle when launched without arguments, else jump to arguments: "install" or "remove"
set CLI=%*& (set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options)
wmic /namespace:"\\root\subscription" path __EventFilter where Name="Skip TPM Check on Dynamic Update" delete >nul 2>nul & rem v1
reg delete "%IFEO%\vdsldr.exe" /f 2>nul & rem v2 - v5

if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove || goto installprompt
if /i "%~1"=="install" (goto installprompt) else if /i "%~1"=="remove" goto remove
:installprompt


cls
color 07
title Windows 11 installer for incompatible devices
mode 76, 30

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:          Welcome to Windows 11 Installer for Incompatible Devices
echo:
echo:            This program uses code from "MediaCreationTool.bat"
echo:                                  By AveYo
echo:             __________________________________________________      
echo:
echo:                         What would you like to do?
echo:
echo:             [1] Install and skip requirements (recommended)
echo:             [2] Install normally
echo:             [3] Download the latest version of Windows 11
echo:             __________________________________________________   
echo:   
echo:             [4] Advanced menu
echo:             [5] Help
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
choice /C:123450 /N
set _erl=%errorlevel%

if %_erl%==6 exit /b
if %_erl%==5 start https://github.com/Mr-Unknown-74/Windows-11-Installer-for-Incompatible-Devices#readme & goto :installprompt
if %_erl%==4 goto advancedprompt
if %_erl%==3 start https://www.microsoft.com/software-download/windows11 & goto :installprompt
if %_erl%==2 set "regInst=true" & goto install
if %_erl%==1 goto install 
goto :installprompt

:advancedprompt
cls
color 07
title Windows 11 installer for incompatible devices
mode 76, 30

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________   
echo:
echo:                                Advanced Menu
echo:             __________________________________________________   
echo:
echo:                         What would you like to do?
echo:
echo:             [1] Debug menu
echo:             [2] Download select versions of Windows 11 via uup dump
echo:             [3] Go to uupdump.net
echo:
echo:                AS OF THIS CODE'S RELEASE, UUP DUMP IS DOWN.
echo:                 CHOICE 2 WILL NEVER WORK IN THIS VERSION,
echo:                 BUT CHOICE 3 WILL WORK ONCE IT'S BACK UP.
echo:             __________________________________________________   
echo:   
echo:             [4] Help
echo:             [0] Go back
echo:       ______________________________________________________________
echo:
choice /C:12340 /N
set _erl=%errorlevel%

if %_erl%==5 goto installprompt
if %_erl%==4 start https://github.com/Mr-Unknown-74/Windows-11-Installer-for-Incompatible-Devices#readme & goto :advancedprompt
if %_erl%==3 start https://uupdump.net & goto :advancedprompt
if %_erl%==2 cls & echo Unavalible & pause & goto advancedprompt
if %_erl%==1 cls & goto debugprompt
goto :advancedprompt

:debugprompt

cls
color 07
title Windows 11 installer for incompatible devices
mode 76, 30

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________   
echo:
echo:                                 Debug Menu
echo:             __________________________________________________   
echo:
echo:                         What would you like to do?
echo:
echo:             [1] Refresh windows update
echo:             __________________________________________________   
echo:   
echo:             [2] Help
echo:             [0] Go back
echo:       ______________________________________________________________
echo:
choice /C:120 /N
set _erl=%errorlevel%

if %_erl%==3 goto advancedprompt
if %_erl%==2 start https://github.com/Mr-Unknown-74/Windows-11-Installer-for-Incompatible-Devices#readme & goto :debugprompt
if %_erl%==1 goto WINDOWSUPDATEREFRESH
goto :debugprompt

:WINDOWSUPDATEREFRESH
cls
@(set '(=)||' <# lean and mean cmd / ps1 hybrid, can paste into powershell console #> @'


::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)

::# stop pending updates
for /f "tokens=6 delims=[]. " %%b in ('ver') do set /a BUILD=%%b
set KILL=& set UPDATE=windowsupdatebox updateassistant updateassistantcheck windows10upgrade windows10upgraderapp
for %%w in (dism setuphost tiworker usoclient sihclient wuauclt culauncher sedlauncher osrrb ruximics ruximih disktoast eosnotify
  musnotification musnotificationux musnotifyicon monotificationux mousocoreworker %UPDATE%) do call set KILL=/im %%w.exe %%KILL%%
taskkill /f %KILL% 2>nul & dism /cleanup-wim & bitsadmin /reset /allusers
for %%w in (msiserver wuauserv bits usosvc dosvc cryptsvc) do start /min cmd /d /x /c net stop %%w /y
taskkill /f %KILL% /im systemsettings.exe 2>nul & timeout 7 /nobreak >nul
for /f tokens^=3^,5^ delims^=^" %%X in ('tasklist /fo csv /nh /svc /fi "services eq wuauserv"') do (
  taskkill /f /pid %%X & for %%w in (%%Y) do if /i %%w neq wuauserv if /i %%w neq bits if /i %%w neq usosvc net start %%w /y
)

::# clear update logs
set "DATA=%ProgramData%" & set "LOG=%SystemRoot%\Logs\WindowsUpdate" & set "SRC=%SystemDrive%\$WINDOWS.~BT\Sources"
del /f /s /q "%DATA%\USOShared\Logs\*" "%DATA%\USOPrivate\UpdateStore\*" "%DATA%\Microsoft\Network\Downloader\*" >nul 2>nul
powershell -nop -c "try {$null=Get-WindowsUpdateLog -LogPath $env:temp\WU.log -ForceFlush -Confirm:$false -ea 0} catch {}" >nul
rmdir /s /q "%LOG%" "%ProgramFiles%\UNP" "%SystemRoot%\SoftwareDistribution" "%SystemDrive%\Windows.old\Cleanup" >nul 2>nul
if exist %SRC%\setuphost.exe if exist %SRC%\setupprep.exe start "cleanup" /wait %SRC%\setupprep.exe /cleanup /quiet

::# remove forced upgraders and update remediators
call "%SystemRoot%\UpdateAssistant\Windows10Upgrade.exe" /ForceUninstall 2>nul
call "%SystemDrive%\Windows10Upgrade\Windows10UpgraderApp.exe" /ForceUninstall 2>nul
msiexec /X {1BA1133B-1C7A-41A0-8CBF-9B993E63D296} /qn 2>nul && echo;Removed osrss
msiexec /X {8F2D6CEB-BC98-4B69-A5C1-78BED238FE77} /qn 2>nul && echo;Removed rempl, ruxim
msiexec /X {0746492E-47B6-4251-940C-44462DFD74BB} /qn 2>nul && echo;Removed CUAssistant
msiexec /X {76A22428-2400-4521-96AF-7AC4A6174CA5} /qn 2>nul && echo;Removed UpdateAssistant


::# start update services
net start bits /y & net start wuauserv /y & net start usosvc /y 2>nul & start /min UsoClient RefreshSettings
pause
goto :debugprompt
'@); $0 = "$env:temp\windows_update_refresh.bat"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0






:install
title Installing - Windows 11 installer for incompatible devices
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

REM Create temporary iso file path storage for dismounting
echo "%isoPath%"> "%TEMP%\isofilelocation.txt"
if "%regInst%"=="true" echo regInst>> "%TEMP%\isofilelocation.txt"

rem dismounts iso file that is potentially mounted
powershell -Command "Dismount-DiskImage -ImagePath '%isoPath%'" >nul

echo Selected ISO file location: "%isoPath%"
echo.

rem Remove the temporary PowerShell script
del "%ps1File%"

rem Loop through drive letters
for %%i in (D E F G H I J K L M N O P Q R S T U V W X Y Z A B C) do (
    rem Check if the drive letter is unused
    if not exist "%%i:\" (
        rem Check if the drive letter is used by a DVD drive
        fsutil fsinfo drivetype %%i: | find "CD-ROM" >nul
        if errorlevel 1 (
            set "driveLetter=%%i:"
            goto aftdriveletter
        )
    )
)

echo No unused drive letter found... Press any key to exit.
pause >nul
exit /b

:aftdriveletter
echo Using drive letter %driveLetter%...
echo.
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

::# Get 11 on 'unsupported' PC via Windows Update or mounted ISO (no patching needed)
::# V12: refined method, no Server label; future proofing; tested with 25905 iso, wu and the new wu repair version  

if /i "%~f0" neq "%SystemDrive%\Scripts\get11.cmd" goto setup
powershell -win 1 -nop -c ";"
set CLI=%*& set SOURCES=%SystemDrive%\$WINDOWS.~BT\Sources& set MEDIA=.& set MOD=CLI& set PRE=WUA& set /a VER=11
if not defined CLI (exit /b) else if not exist %SOURCES%\SetupHost.exe (exit /b)
if not exist %SOURCES%\WindowsUpdateBox.exe mklink /h %SOURCES%\WindowsUpdateBox.exe %SOURCES%\SetupHost.exe
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /f /v DisableWUfBSafeguards /d 1 /t reg_dword
reg add HKLM\SYSTEM\Setup\MoSetup /f /v AllowUpgradesWithUnsupportedTPMorCPU /d 1 /t reg_dword
set OPT=/Compat IgnoreWarning /MigrateDrivers All /Telemetry Disable
set /a restart_application=0x800705BB & (call set CLI=%%CLI:%1 =%%)
set /a incorrect_parameter=0x80070057 & (set SRV=%CLI:/Product Client =%)
set /a launch_option_error=0xc190010a & (set SRV=%SRV:/Product Server =%)
for %%W in (%CLI%) do if /i %%W == /PreDownload (set MOD=SRV)
for %%W in (%CLI%) do if /i %%W == /InstallFile (set PRE=ISO& set "MEDIA=") else if not defined MEDIA set "MEDIA=%%~dpW"
if %VER% == 11 for %%W in ("%MEDIA%appraiserres.dll") do if exist %%W if %%~zW == 0 set AlreadyPatched=1 & set /a VER=10
if %VER% == 11 findstr /r "P.r.o.d.u.c.t.V.e.r.s.i.o.n...1.0.\..0.\..2.[2-9]" %SOURCES%\SetupHost.exe >nul 2>nul || set /a VER=10
if %VER% == 11 if not exist "%MEDIA%EI.cfg" (echo;[Channel]>%SOURCES%\EI.cfg & echo;_Default>>%SOURCES%\EI.cfg)
if %VER%_%PRE% == 11_ISO (%SOURCES%\WindowsUpdateBox.exe /Product Server /PreDownload /Quiet %OPT%)
if %VER%_%PRE% == 11_ISO (del /f /q %SOURCES%\appraiserres.dll 2>nul & cd.>%SOURCES%\appraiserres.dll)
if %VER%_%MOD% == 11_SRV (set ARG=%OPT% %SRV% /Product Server)
if %VER%_%MOD% == 11_CLI (set ARG=%OPT% %CLI%)
%SOURCES%\WindowsUpdateBox.exe %ARG%
if %errorlevel% == %restart_application% %SOURCES%\WindowsUpdateBox.exe %ARG%
exit /b

:setup
::# elevate with native shell by AveYo
>nul reg add hkcu\software\classes\.Admin\shell\runas\command /f /ve /d "cmd /x /d /r set \"f0=%%2\"& call \"%%2\" %%3"& set _= %*
>nul fltmc|| if "%f0%" neq "%~f0" (cd.>"%temp%\runas.Admin" & start "%~n0" /high "%temp%\runas.Admin" "%~f0" "%_:"=""%" & exit /b)

::# toggle when launched without arguments, else jump to arguments: "install" or "remove"
set CLI=%*& (set IFEO=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options)
wmic /namespace:"\\root\subscription" path __EventFilter where Name="Skip TPM Check on Dynamic Update" delete >nul 2>nul & rem v1
reg delete "%IFEO%\vdsldr.exe" /f 2>nul & rem v2 - v5

if /i "%CLI%"=="" reg query "%IFEO%\SetupHost.exe\0" /v Debugger >nul 2>nul && goto remove2 || goto install2
if /i "%~1"=="install" (goto install2) else if /i "%~1"=="remove" goto remove2
:install2
mkdir %SystemDrive%\Scripts >nul 2>nul & copy /y "%~f0" "%SystemDrive%\Scripts\get11.cmd" >nul 2>nul
reg add "%IFEO%\SetupHost.exe" /f /v UseFilter /d 1 /t reg_dword >nul
reg add "%IFEO%\SetupHost.exe\0" /f /v FilterFullPath /d "%SystemDrive%\$WINDOWS.~BT\Sources\SetupHost.exe" >nul
reg add "%IFEO%\SetupHost.exe\0" /f /v Debugger /d "%SystemDrive%\Scripts\get11.cmd" >nul
goto WinInstall
:remove2
exit /b

REM 
:WinInstall
title Windows 11 installer for incompatible devices
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
echo:                   If you decide to cancel the installation,
echo:               re-run the program to automatically uninstall it.
echo:       ______________________________________________________________
echo.
echo Press any key to open the Windows installer.
pause >nul
start "" "%driveLetter%\setup.exe"
exit /b

:RWininstall
title Windows 11 installer for incompatible devices
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
mode 76, 30
title Uninstalling - Windows 11 installer for incompatible devices
del /f /q "%SystemDrive%\Scripts\get11.cmd" "%Public%\get11.cmd" "%ProgramData%\get11.cmd" >nul 2>nul
reg delete "%IFEO%\SetupHost.exe" /f >nul 2>nul

:isomountcheck2
set "txtPath=%TEMP%\isofilelocation.txt"
set "isoPath="

REM Check if the file exists
if not exist "%txtPath%" (
    REM no? weird.
    goto AftUninstall
)

REM Read the second line of the file
set "lineNumber=1"
for /f "usebackq skip=%lineNumber% delims=" %%a in ("%txtPath%") do (
    set "secondLine=%%a"
    goto :readSecondLine2
)

:readSecondLine2
REM Read the second line again to avoid exiting the loop prematurely
set /a "lineNumber+=1"
for /f "usebackq skip=%lineNumber% delims=" %%a in ("%txtPath%") do (
    set "secondLine=%%a"
    goto :checkSecondLine2
)

:checkSecondLine2
REM Check if "regInst" is present in the second line
echo %secondLine% | find /i "regInst" > nul
if %errorlevel% equ 0 (
    REM this should not happen, but who knows, right?
    goto AftUninstall
) else (
    set /p "isoPath=" < "%txtPath%"
)


set "ps1File=%TEMP%\isomount.ps1"

REM Creating the PowerShell script

echo function Get-AttachedValue { > "%ps1File%"
echo     param ( >> "%ps1File%"
echo         [string]$InputString >> "%ps1File%"
echo     ) >> "%ps1File%"
echo     # Split the input string into lines >> "%ps1File%"
echo     $lines = $InputString -split "`r?`n" >> "%ps1File%"
echo     # Look for the line that contains "Attached:" and get the value after it >> "%ps1File%"
echo     $attachedLine = $lines ^| Where-Object { $_ -match '^^\s*Attached\s*:\s*(.*)$' } >> "%ps1File%"
echo     if ($attachedLine) { >> "%ps1File%"
echo         $attachedValue = $matches[1].Trim() >> "%ps1File%"
echo         return $attachedValue >> "%ps1File%"
echo     } >> "%ps1File%"
echo     return $null >> "%ps1File%"
echo } >> "%ps1File%"
echo $isoInfo = Invoke-Expression -Command '(Get-DiskImage -ImagePath %isoPath%)' ^| Out-String >> "%ps1File%"
echo # Call the function with the example input >> "%ps1File%"
echo $result = Get-AttachedValue -InputString $isoInfo >> "%ps1File%"
echo if ($result) { >> "%ps1File%"
echo     #Nice >> "%ps1File%"
echo } else { >> "%ps1File%"
echo     $result = "Error" >> "%ps1File%"
echo } >> "%ps1File%"
echo $result >> "%ps1File%"

REM Running the PowerShell script and capturing the result
for /f "usebackq delims=" %%i in (`powershell -ExecutionPolicy Bypass -File "%ps1File%"`) do set "result=%%i"

REM Cleaning up the PowerShell script
del "%ps1File%"

REM diciding what to do (unmount, not unmount, or display an error and continue)
if "%result%"=="True" (
    goto umountiso2
) else if "%result%"=="False" (
    goto AftUninstall
    del "%TEMP%\isofilelocation.txt"
) else (
    del "%TEMP%\isofilelocation.txt"
    goto AftUninstall
)

:umountiso2
rem dismounts iso file that is potentially mounted
powershell -Command "Dismount-DiskImage -ImagePath '%isoPath%'" >nul

del "%TEMP%\isofilelocation.txt"

goto AftUninstall2
'@); $0 = "$env:temp\Skip_TPM_Check_on_Dynamic_Update.cmd"; ${(=)||} -split "\r?\n" | out-file $0 -encoding default -force; & $0
:AftUninstall
cls
color 07
title Uninstalled - Windows 11 installer for incompatible devices
mode 76, 30

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



:AftUninstall2
cls
color 07
title Uninstalled - Windows 11 installer for incompatible devices
mode 76, 30

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                  Successfully Uninstalled and Unmounted
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
goto :AftUninstall2



:aftunmount
cls
color 07
title Unmounted - Windows 11 installer for incompatible devices
mode 76, 30

echo:
echo:
echo:
echo:
echo:
echo:       ______________________________________________________________
echo:
echo:                           Successfully Unmounted
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
goto :aftunmount