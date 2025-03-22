# 共通関数を読み込む
. "$PSScriptRoot\TradeTransmitterInstallerUtil.ps1"

# メイン処理
param(
    [string]$LogFile
)
# インストールする.NET Core Hosting BundleのURL
$hostingBundleUrl = "https://download.visualstudio.microsoft.com/download/pr/450a6e4e-e4e3-4ed6-86a2-6a6f840e5a51/3629f0822ccc2ce265cf5e88b5b567cb/dotnet-hosting-9.0.1-win.exe"

# ダウンロード先のパス
$installerPath = "$PSScriptRoot\dotnet-hosting-installer.exe"

Write-Output "Downloading .NET Core Hosting Bundle..."
Get-File $hostingBundleUrl $installerPath $LogFile

# サイレントインストールの実行
Write-Output "Installing .NET Core Hosting Bundle..."
Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

# IISを再起動
Write-Output "Restarting IIS..."
iisreset

# インストール確認
Write-Output "Checking .NET Core runtime versions installed..."
& 'C:\Program Files\dotnet\dotnet.exe' --list-runtimes
