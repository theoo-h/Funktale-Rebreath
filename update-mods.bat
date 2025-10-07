REM script by theodev

@echo off
setlocal

echo script to update the project mods (replace it with the current build mods folder)
echo ----------------

echo trying to delete current "mods" folder
echo ----------------

if exist "%cd%\mods" (
    rmdir /s /q "%cd%\mods"
    echo current "mods" folder was succefully deleted.
) else (
    echo there isnt a "mods" folder to delete
)

echo ----------------
set /p build_flag=are you working on "debug" or "release"?: 

if /i "%build_flag%"=="debug" (
    echo build type: debug
) else if /i "%build_flag%"=="release" (
    echo build type: release
) else (
    echo ur answer must be "release" or "debug", closing program
    timeout /t 1 /nobreak >nul
    exit
)
echo ----------------

if not exist "%cd%\export\%build_flag%" (
    echo ur project seems dont have a %build_flag% build. closing program
    timeout /t 1 /nobreak >nul
    exit
)

set /p build_target=on what target are you working on? (for example, windows, android, linux, etc): 

set origin=export/%build_flag%/%build_target%/bin

if not exist "%origin%" (
    echo ur project seems dont have a %build_target% build. closing program
    timeout /t 1 /nobreak >nul
    exit
)

echo ----------------

echo trying to copy build's mods folder to current project repo...

if not exist "%origin%/mods" (
    echo ur project seems dont have a mods folder on the build, closing program
    timeout /t 1 /nobreak >nul
    exit
)

xcopy /e /i "%origin%/mods" "%cd%/mods"

echo the mod folder was copied succefully, closing program...
endlocal
pause