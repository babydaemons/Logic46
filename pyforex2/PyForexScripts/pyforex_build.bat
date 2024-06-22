rmdir /q/s build
rmdir /q/s dist
rmdir /q/s pyforex.build
rmdir /q/s pyforex.dist
del "%appdata%\MetaQuotes\Terminal\Common\Files\pyforex\bin\pyforex.exe"
rmdir /q/s "%appdata%\MetaQuotes\Terminal\Common\Files\pyforex\bin\_internal"
pyinstaller pyforex.py
xcopy /y /s dist\pyforex\*.* "%appdata%\MetaQuotes\Terminal\Common\Files\pyforex\bin"
