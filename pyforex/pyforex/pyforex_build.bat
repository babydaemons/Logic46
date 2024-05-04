rmdir /q/s build
pyinstaller pyforex.py --onefile
taskkill /im pyforex.exe /f
move /y dist\pyforex.exe C:\Users\shingo\AppData\Roaming\MetaQuotes\Terminal\Common\Files\pyforex.exe
