@echo off
set APP_NAME=TradeTransmitterService
taskkill /f /im "%APP_NAME%.exe" 1>NUL 2>&1

set APP_DIR=C:\%APP_NAME%
if not exist %APP_DIR%\. (
    mkdir %APP_DIR% 1>NUL 2>&1
)

copy /y %APP_NAME%.ini %APP_DIR% 1>NUL 2>&1
copy /y %APP_NAME%.exe %APP_DIR% 1>NUL 2>&1

cd /d %APP_DIR%
%APP_NAME%.exe
pause
