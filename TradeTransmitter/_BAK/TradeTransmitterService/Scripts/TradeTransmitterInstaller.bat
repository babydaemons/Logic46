@echo off
setlocal enabledelayedexpansion

title TradeTransmitterInstaller

set timestamp=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%

set "LOGFILE=%~dp0TradeTransmitterInstaller-%timestamp%.log"
set "DIR=%~dp0TradeTransmitterInstaller"
set "LOGGER=%DIR%\TradeTransmitterInstallerLogger.ps1"
set "INIFILE=%~dp0TradeTransmitterInstaller.ini"

for /f "usebackq tokens=1,2 delims==" %%A in ("%INIFILE%") do (
    set "key=%%A"
    set "value=%%B"
    set "!key!=!value!"
)

set "PATH=%ProgramFiles%\PowerShell\7;%ProgramFiles%\Git\cmd;%PATH%"
set PS5=powershell.exe
set PS7=pwsh.exe
set N=27

%PS5% -ExecutionPolicy Bypass -File "%DIR%\TradeTransmitterInstallerMaxSize.ps1"

%PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -Message "(1/%N%) Git for Windows をインストールしています..."
winget.exe install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements --verbose-logs

%PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -Message "(2/%N%) .NET 9 Desktop Runtime をインストールしています..."
winget.exe install Microsoft.DotNet.DesktopRuntime.9 -e --silent --accept-package-agreements --accept-source-agreements --verbose-logs

%PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -Message "(3/%N%) .NET 9 ASP.NET Core をインストールしています..."
winget.exe install Microsoft.DotNet.AspNetCore.9 -e --silent --accept-package-agreements --accept-source-agreements --verbose-logs

%PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -Message "(4/%N%) .NET 9 SDK をインストールしています..."
winget.exe install --id Microsoft.DotNet.SDK.9 -e --source winget --silent --accept-package-agreements --accept-source-agreements --verbose-logs

%PS5% -ExecutionPolicy Bypass -File "%DIR%\TradeTransmitterInstaller01.ps1" -LogFile "%LOGFILE%" -StartProgress 5
if %errorlevel% neq 0 (
    %PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -TotalSteps 1 -CurrentStep 1 -Message "PowerShell 7 のインストールが失敗しました。"
    pause
    goto :eof
)

%PS7% -ExecutionPolicy Bypass -File "%DIR%\TradeTransmitterInstaller02.ps1" -LogFile "%LOGFILE%" -StartProgress 10
if %errorlevel% neq 0 (
    %PS5% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -TotalSteps 1 -CurrentStep 1 -Message "IISのインストールと設定が失敗しました。"
    pause
    goto :eof
)

%PS7% -ExecutionPolicy Bypass -File "%DIR%\TradeTransmitterInstaller03.ps1" -LogFile "%LOGFILE%" -StartProgress 16
if %errorlevel% neq 0 (
    %PS7% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -TotalSteps 1 -CurrentStep 1 -Message "win-acme のインストールが失敗しました。"
    pause
    goto :eof
)

%PS7% -ExecutionPolicy Bypass -File "%DIR%\TradeTransmitterInstaller04.ps1" -LogFile "%LOGFILE%" -StartProgress 21
if %errorlevel% neq 0 (
    %PS7% -ExecutionPolicy Bypass -File "%LOGGER%" -LogFile "%LOGFILE%" -TotalSteps 1 -CurrentStep 1 -Message "先生用のサーバーアプリ のインストールが失敗しました。"
    pause
    goto :eof
)

pause
:eof
