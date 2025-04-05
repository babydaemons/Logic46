[Setup]
AppName=KazuyaFX Server
AppVersion=1.0
DefaultDirName=C:\inetpub\KazuyaFX
DefaultGroupName=KazuyaFX
OutputDir=.
OutputBaseFilename=KazuyaFX_Installer
Compression=lzma
SolidCompression=yes
DisableDirPage=yes

[Files]
Source: "KazuyaFX.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "appsettings.json"; DestDir: "{app}"
Source: "KazuyaFX.ico"; DestDir: "{app}"
Source: "KazuyaFX.staticwebassets.endpoints.json"; DestDir: "{app}"
Source: "KazuyaFX_Setup.ps1"; DestDir: "{app}"

[Run]
Filename: "powershell.exe"; \
  Parameters: "-ExecutionPolicy Bypass -NoProfile -File ""{app}\KazuyaFX_Setup.ps1"""; \
  StatusMsg: "KazuyaFXサーバーを構成中..."; \
  Flags: runascurrentuser waituntilterminated

[Icons]
Name: "{group}\KazuyaFX サーバーインストーラー"; Filename: "{app}\KazuyaFX_Setup.ps1"
