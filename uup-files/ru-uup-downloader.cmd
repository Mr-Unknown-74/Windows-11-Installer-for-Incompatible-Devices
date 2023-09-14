@echo off

rem script:	   @rgadguard and abbodi406

setlocal EnableExtensions
setlocal EnableDelayedExpansion
set "params=%*"
cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/k cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

if not exist "%cd%\bin\wimlib-imagex.exe" goto :ConvertLite

:Info
for /f "tokens=3 delims=: " %%b in ('dism /english /online /Get-Intl ^| find /i "System locale"') do (
	call bin\lang-uup.cmd -en
	if /i %%b==ru-RU call bin\lang-uup.cmd -ru
)
set "file_main=%~n0"
set "aria2=bin\aria2c.exe"
set "rand=%random%"
set "down_temp=%rand%\down"
set "aria2Script=%rand%\aria2_script.txt"
::to be replaced
set "lang_def=en-us"
set "destDir=uup/!BuildInfo!/!lang_def!/amd64"
::to be replaced
mkdir %rand%
%aria2% -x16 -s16 -d"%rand%" -o"aria2_script.txt" "https://uup.rg-adguard.net/api/GetFiles?id=!updateId!&lang=!lang_def!&edition=all&txt=yes"
if %ERRORLEVEL% GTR 0 goto DOWNERR
for %%i in ("%aria2Script%") do (if /i %%~zi LEQ 10 goto ERRAPI)

:Tools
set Lang_en=OFF
set NetFx_en=OFF
set multi_en=OFF
set update_en=OFF
set clean_en=OFF
set esd_en=OFF
set swm_en=OFF
set fix11_en=OFF
set fix11_num=0
set update_num=0
set multu_num=0
set lang_on=1
set apps_en=OFF
set apps_num=0
if !BuildInfo! GEQ 17063.1000 (
	set multu_num=1
	set multi_en=ON
)
if !BuildInfo! GEQ 20348.1 (
    if !BuildInfo! LEQ 20361.1 (
        set multu_num=0
        set lang_on=0
    )
)
if !BuildInfo! GEQ 21990.1 (
	set fix11_num=1
	set fix11_en=ON
)
for /f "tokens=1 skip=2" %%a in ('find /N "Windows10.0-KB" "%aria2Script%"') do (
	set /a update_num=1
)
for /f "tokens=1 skip=2" %%a in ('find /N "Windows11.0-KB" "%aria2Script%"') do (
	set /a update_num=1
)
for /d %%A in (ServerAzureStackHCICor,ServerDatacenter,ServerStandard) do (
	for /f "tokens=1" %%g in ('find /N "out=Server" "%aria2Script%" ^| find /i "%%A"') do (
		set multu_num=0
		set multi_en=OFF
	)
)
for /f "tokens=1 skip=2" %%a in ('find /N ".appx" "%aria2Script%"') do (
	set /a apps_num=1
	set apps_en=ON
)
for /f "tokens=6 delims=[]. " %%G in ('ver') do (
	if %%G LSS 9599 set update_num=0
)
if /i %update_num% neq 0 (set update_en=ON)

:Menu
title %lang_title_menu_multi%...
color 0b
set menu=
cls
echo ===============================================================================
echo %lang_title_menu_multi%:
echo ===============================================================================
echo.
if %lang_on% neq 0 (echo  L. %lang_multi_l% - %Lang_en%)
echo  N. %lang_multi_n% - %NetFx_en%
if %multu_num% neq 0 (echo  M. %lang_multi_m% - %multi_en%)
if %update_num% neq 0 (echo  U. %lang_multi_u% - %update_en%
echo  C. %lang_multi_c% - %clean_en%)
if /i %esd_en%==OFF (echo  S. %lang_multi_s% - %swm_en%)
echo  E. %lang_multi_e% - %esd_en%
if %apps_num% neq 0 (echo  A. %lang_multi_a% - %apps_en%)
if %fix11_num% neq 0 (echo  F. %lang_multi_f% - %fix11_en%)
echo.
echo ===============================================================================
echo %lang_multi_txt_1%
if %Lang_en%==ON (echo %lang_multi_txt_3%) else (echo %lang_multi_txt_2%)
if %swm_en%==ON (
	echo -------------------------------------------------------------------------------
	echo %lang_multi_txt_4%
)
if %apps_en%==ON (
	echo -------------------------------------------------------------------------------
	echo %lang_multi_txt_5%
)
echo ===============================================================================
echo.
set /p menu= ^> %lang_your_selection%: 
if [%menu%]==[] GOTO :DownListLang
set menu=%menu:~0,1%
if /i %menu%==L (if /i %Lang_en%==OFF (set Lang_en=ON) else (set Lang_en=OFF))
if /i %menu%==N (if /i %NetFx_en%==OFF (set NetFx_en=ON) else (set NetFx_en=OFF))
if /i %multu_num% neq 0 (if /i %menu%==M (if /i %multi_en%==OFF (set multi_en=ON) else (set multi_en=OFF)))
if /i %update_num% neq 0 (if /i %menu%==U (if /i %update_en%==OFF (set update_en=ON) else (set update_en=OFF))
if /i %menu%==C (if /i %clean_en%==OFF (set clean_en=ON) else (set clean_en=OFF)))
if /i %menu%==E (if /i %esd_en%==OFF (set esd_en=ON & set swm_en=OFF) else (set esd_en=OFF))
if %apps_en% neq 0 (if /i %menu%==A (if /i %apps_en%==OFF (set apps_en=ON) else (set apps_en=OFF)))
if %fix11_num% neq 0 (if /i %menu%==F (if /i %fix11_en%==OFF (set fix11_en=ON) else (set fix11_en=OFF)))
if /i %esd_en%==OFF (if /i %menu%==S (if /i %swm_en%==OFF (set swm_en=ON) else (set swm_en=OFF)))
GOTO :Menu

:DownListLang
if /i %esd_en%==OFF (if /i %swm_en%==ON (set esd_en==SWM)) else (set esd_en==ESD)
if /i %Lang_en%==OFF GOTO :DownFiles
color 07
%aria2% -x16 -s16 -d"%rand%" -o"lang_list.txt" "https://uup.rg-adguard.net/api/GetLanguage?id=!updateId!&txt=1"
for /f "tokens=1,2,3 delims=|" %%a in ('type "%rand%\lang_list.txt"') do (
	set "lang_ON_%%a=OFF"
	if /i [!lang_def!]==[%%b] set "lang_ON_%%a=DEF"
	set lang_int_%%a=%%c
	set lang_id_%%a=%%b
	set lang_num=%%a
)
title %lang_title_language%...
color 0b
GOTO :LangMenu

:LangMenu
cls
set langs=
echo.
echo ===============================================================================
echo %lang_title_language%:
echo ===============================================================================
echo.
FOR /L %%j IN (1,1,!lang_num!) DO (
	echo !lang_ON_%%j! - %%j. !lang_int_%%j!
)
echo.
echo ===============================================================================
echo %lang_multi_txt_1%
echo %lang_multi_txt_2%
echo ===============================================================================
echo.
set /p langs= ^> %lang_your_selection%: 
if [%langs%]==[] GOTO :DownFiles
set langs=%langs:~0,2%
FOR /L %%j IN (1,1,!lang_num!) DO (
	if %langs%==%%j (
		if /i !lang_ON_%%j!==OFF (
			set "lang_ON_%%j=ON "
		) else (
			if /i !lang_ON_%%j!==DEF (
				set 0=0
			) else (
				set lang_ON_%%j=OFF
			)
		)
	)
)
goto :LangMenu

:DownFiles
color 07
cls
title %lang_titke_download%...
if not exist "%destDir%\good" (
	%aria2% -x16 -s16 -j32 -c -R -d"%destDir%" -i"%aria2Script%"
	if exist "%destDir%\*.aria2" (
	    erase /q /s "%aria2Script%" >NUL 2>&1
	    %aria2% -x16 -s16 -d"%rand%" -o"aria2_script.txt" "https://uup.rg-adguard.net/api/GetFiles?id=!updateId!&lang=!lang_def!&edition=all&txt=yes"
	    GOTO :DownFiles
	)
	echo.>%destDir%\good
)
erase /q /s "%aria2Script%" >NUL 2>&1

if /i %Lang_en%==ON (
	set tt=0
	FOR /L %%j IN (1,1,!lang_num!) DO (
		if /i "!lang_ON_%%j!"=="ON " (
			set /a tt+=1
			if defined lang_id (
				set "lang_id=!lang_id!,!lang_id_%%j!"
			) else (
				set "lang_id=!lang_id_%%j!"
			)
		)
	)
	if !tt! neq 0 (
		%aria2% -x16 -s16 -d"%rand%" -o"aria2_script.txt" "https://uup.rg-adguard.net/api/GetFiles?id=!updateId!&lang=!lang_id!&edition=lang&txt=yes"
		if %ERRORLEVEL% GTR 0 goto DOWNERR
		for %%i in ("%aria2Script%") do (
			if /i %%~zi LEQ 10 goto ERRAPI
		)
		
		%aria2% -x16 -s16 -j8 -c -R -d"%down_temp%" -i"%aria2Script%"
		if %ERRORLEVEL% GTR 0 goto DOWNERR
		erase /q /s "%aria2Script%" >NUL 2>&1
	)
	if !tt!==0 (
		set Lang_en=OFF
	)
)

color 0a
call bin\convert-UUP.cmd %cd%\uup\!BuildInfo!\!lang_def!\amd64 %esd_en%
goto EOF

:ConvertLite
for /f "tokens=3 delims=:. " %%f in ('bitsadmin.exe /CREATE /DOWNLOAD "Download convert_lite" ^| findstr "Created job"') do set GUID=%%f
title Download convert_lite...
bitsadmin /transfer %GUID% /download /priority foreground https://uup.rg-adguard.net/dl/convert_lite.cab "%cd%\convert_lite.cab"
if NOT EXIST convert_lite.cab goto DOWNERR
expand convert_lite.cab -f:* %cd% >nul
del /f /q convert_lite.cab >nul 2>&1
goto :Info

:DOWNERR
color 0c
echo We have encountered an error while downloading files.
erase /q /s "%aria2Script%" >NUL 2>&1
pause
goto EOF

:ERRAPI
color 0c
echo Error getting links to download UUP files.
echo Try again a few minutes later.
erase /q /s "%aria2Script%" >NUL 2>&1
pause
goto EOF

:EOF
