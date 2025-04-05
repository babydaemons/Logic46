Add-Type -AssemblyName System.Windows.Forms

$logFile = "$env:TEMP\KazuyaFX_Setup.log"
$desktop = [Environment]::GetFolderPath("Desktop")

try {
    Start-Transcript -Path $logFile -Append
} catch {
    [System.Windows.Forms.MessageBox]::Show("ログ開始に失敗しました：$_", "KazuyaFX", 0, 48)
}

try {
    # ---------------- パラメータ ----------------
    $siteName = "KazuyaFX"
    $sitePath = "C:\inetpub\KazuyaFX"
    $exeName = "KazuyaFX.exe"
    $port = 5000
    $hostingBundleUrl = "https://download.visualstudio.microsoft.com/download/pr/9d27d05b-dc5b-47a0-bb7e-d68c7a1c0f3f/3c308e3b32e6311072d58b8de88cf2cb/dotnet-hosting-8.0.4-win.exe"

    $fxtfExePath = "C:\Program Files (x86)\FXTF MT4\terminal.exe"
    $fxtfInstallerUrl = "https://www.fxtrade.co.jp/system/download/fxtf4setup.exe"
    $fxtfInstallerPath = "$env:TEMP\fxtf4setup.exe"

    Write-Host "① IISと必要な機能をインストール中..."
    Install-WindowsFeature -Name Web-Server, Web-WebSockets, Web-Mgmt-Console

    Write-Host "② .NET Hosting Bundle をインストール中..."
    $installerPath = "$env:TEMP\dotnet-hosting.exe"
    Invoke-WebRequest -Uri $hostingBundleUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait
    Remove-Item $installerPath

    Write-Host "③ サイトフォルダを作成中..."
    New-Item -Path $sitePath -ItemType Directory -Force | Out-Null

    Write-Host "④ アプリファイルをコピー中..."
    Copy-Item -Path "$PSScriptRoot\$exeName" -Destination $sitePath -Force
    Copy-Item -Path "$PSScriptRoot\KazuyaFX.ico" -Destination $sitePath -Force
    Copy-Item -Path "$PSScriptRoot\appsettings.json" -Destination $sitePath -Force
    Copy-Item -Path "$PSScriptRoot\KazuyaFX.staticwebassets.endpoints.json" -Destination $sitePath -Force

    Write-Host "⑤ web.config を生成中..."
    $webConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified"/>
    </handlers>
    <aspNetCore processPath="$sitePath\$exeName"
                arguments=""
                stdoutLogEnabled="true"
                stdoutLogFile=".\logs\stdout"
                hostingModel="OutOfProcess" />
  </system.webServer>
</configuration>
"@
    $webConfig | Out-File -Encoding UTF8 -FilePath "$sitePath\web.config"

    Write-Host "⑥ アプリケーションプールとサイトを構成中..."
    if (-Not (Get-WebAppPoolState -Name $siteName -ErrorAction SilentlyContinue)) {
        New-WebAppPool -Name $siteName
    }
    Set-ItemProperty IIS:\AppPools\$siteName -Name processModel.identityType -Value "ApplicationPoolIdentity"

    if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
        Remove-Website -Name $siteName
    }
    New-Website -Name $siteName -Port $port -PhysicalPath $sitePath -ApplicationPool $siteName

    Write-Host "⑦ ファイアウォールポートを開放中..."
    New-NetFirewallRule -DisplayName "Allow KazuyaFX HTTP $port" -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow -ErrorAction SilentlyContinue

    Write-Host "⑧ デスクトップにショートカットを作成中..."
    $shortcutPath = Join-Path $desktop "KazuyaFX先生サーバー起動.lnk"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "$sitePath\$exeName"
    $shortcut.WorkingDirectory = $sitePath
    $iconPath = Join-Path $sitePath "KazuyaFX.ico"
    if (Test-Path $iconPath) {
        $shortcut.IconLocation = $iconPath
    }
    $shortcut.Save()

    Write-Host "⑨ FXTF MT4 の存在確認..."
    if (Test-Path $fxtfExePath) {
        Write-Host "FXTF MT4 はすでにインストール済みです。"
    } else {
        Write-Host "FXTF MT4 をダウンロード中..."
        Invoke-WebRequest -Uri $fxtfInstallerUrl -OutFile $fxtfInstallerPath
        Write-Host "インストーラーを起動します..."
        Start-Process -FilePath $fxtfInstallerPath -Wait
        Remove-Item $fxtfInstallerPath -Force
    }

    Write-Host "セットアップ完了！"
}
catch {
    [System.Windows.Forms.MessageBox]::Show("エラーが発生しました：`n$_`nログ: $logFile", "KazuyaFX エラー", 0, 16)
}
finally {
    Stop-Transcript
    try {
        Copy-Item -Path $logFile -Destination "$desktop\KazuyaFX_Setup.log" -Force
    } catch {
        [System.Windows.Forms.MessageBox]::Show("ログのコピーに失敗しました：$_", "KazuyaFX ログ", 0, 48)
    }
}
