@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
cd /d %~dp0

set VER=1.5
set AUTHOR=Pontvieux Cyrille - jrd@enialis.net
set LICENCE=GPL v3+
title install-on-USB v%VER
goto start

:version
  echo install-on-USB v%VER% by %AUTHOR%
  echo Licence : %LICENCE%
  echo -^> Install syslinux that will chainload to grub2 on an USB key using the USB key itself.
  goto :EOF

:usage
  call :version
  echo.
  echo usage: install-on-USB.sh [/?] [/v]
  goto :EOF

:install_syslinux
  setlocal
  set DRIVE=%~1
  set BASEDIR=%~2
  set res=n
  echo Warning: syslinux is about to be installed in %DRIVE%
  set /p res=Do you want to continue? [y/N] 
  if not "%res%" == "y" (
    endlocal
    exit /b 1
  )
  if not exist %DRIVE%\*.live (
    echo Error: You need to put the .live file from the iso into the root of the usb key %DRIVE%
    endlocal
    exit /b 1
  )
  syslinux.exe -m -a %DRIVE%
  if ERRORLEVEL 1 (
    endlocal
    exit /b %errorlevel%
  )
  set relimg=%BASEDIR%grub2-linux.img
  echo DEFAULT grub2 > %DRIVE%\syslinux.cfg
  echo PROMPT 0 >> %DRIVE%\syslinux.cfg
  echo NOESCAPE 1 >> %DRIVE%\syslinux.cfg
  echo TOTALTIMEOUT 1 >> %DRIVE%\syslinux.cfg
  echo ONTIMEOUT grub2 >> %DRIVE%\syslinux.cfg
  echo LABEL grub2 >> %DRIVE%\syslinux.cfg
  echo   SAY Chainloading to grub2... >> %DRIVE%\syslinux.cfg
  echo   LINUX %relimg% >> %DRIVE%\syslinux.cfg
  endlocal
  goto :EOF

:start
  if _%1 == _/v goto version
  if _%1 == _/? goto usage
  set DRIVE=%~d0
  set BASEDIR=%~p0
  set BASEDIR=%BASEDIR:\=/%
  echo Installing syslinux...
  call :install_syslinux "%DRIVE%" "%BASEDIR%"
  if ERRORLEVEL 1 goto end
  echo syslinux+GRUB2 installed successfully!
:end
  pause
