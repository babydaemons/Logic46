### TradeTransmitterInstaller01.ps1

# メイン処理
param(
    [string]$LogFile,
    [int]$StartProgress
)

# 共通関数を読み込む
. "$PSScriptRoot\TradeTransmitterInstallerUtil.ps1"

# IISのインストールと設定
function Install-IIS {
    param (
        [string]$LogFile
    )

    Write-Log "IISのインストールと設定を開始します..." $LogFile
    Install-WindowsFeature -name Web-Server -IncludeManagementTools

    # インストールする.NET Core Hosting BundleのURL
    $hostingBundleUrl = "https://download.visualstudio.microsoft.com/download/pr/450a6e4e-e4e3-4ed6-86a2-6a6f840e5a51/3629f0822ccc2ce265cf5e88b5b567cb/dotnet-hosting-9.0.1-win.exe"

    # ダウンロード先のパス
    $installerPath = "$WorkDir\dotnet-hosting-installer.exe"

    Write-Log ".NET Core Hosting Bundle をダウンロードしています..." $LogFile
    Get-File $hostingBundleUrl $installerPath $LogFile

    # サイレントインストールの実行
    Write-Log ".NET Core Hosting Bundle をインストールしています..." $LogFile
    Start-Process -FilePath $installerPath -ArgumentList "/quiet" -Wait

    # インストール確認
    Write-Log "インストールされた .NET Core ランタイムのバージョンを確認します..." $LogFile
    & 'C:\Program Files\dotnet\dotnet.exe' --list-runtimes
    Remove-Item $installerPath -Force

    Write-Log "IISを再起動しています..." $LogFile
    iisreset.exe
    Write-Log "IISの再起動が完了しました。" $LogFile

    Write-Log "ファイアウォールの設定を行っています: HTTP(80)ポート..." $LogFile
    New-NetFirewallRule -DisplayName "HTTP Port 80" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow
    Write-Log "ファイアウォールの設定を行っています: HTTPS(443)ポート..." $LogFile
    New-NetFirewallRule -DisplayName "HTTPS Port 443" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow

    Write-Log "IISのバインディングを追加しています: HTTP(80)ポート..." $LogFile
    # IIS管理モジュールをインポート
    Import-Module WebAdministration

    # 変数の設定
    $siteName = "Default Web Site"     # IISのサイト名（変更可）
    $bindingIP = "*"                   # バインディングするIPアドレス（全てのIPに対してバインドする場合は"*"）
    $bindingPort = 80                  # ポート番号（HTTPは80）
    $hostHeader = $env:DOMAIN          # バインディングするドメイン名

    # バインディングが既に存在するか確認
    $existingBinding = Get-WebBinding -Name $siteName -Protocol "http" | Where-Object { $_.bindingInformation -like "*:${bindingPort}:${hostHeader}" }

    if ($existingBinding) {
        Write-Log "既にバインディングが存在します: $hostHeader" $LogFile
    } else {
        # バインディングの追加
        New-WebBinding -Name $siteName -IPAddress $bindingIP -Port $bindingPort -HostHeader $hostHeader -Protocol "http"
        Write-Log "バインディングが追加されました: $hostHeader" $LogFile
    }

    # 確認用に現在のバインディングを表示
    Get-WebBinding -Name $siteName
    Write-Log "IISのバインディング設定が完了しました。" $LogFile
}

function Set-Pool {
    param (
        [string]$LogFile
    )

    # サイトの設定
    $siteName = "api"                          # 任意のサイト名
    $sitePath = "C:\inetpub\wwwroot\$siteName" # ASP.NET Coreアプリの公開フォルダ
    $port = 443  # 使用するポート（80 または 443）
    $appPoolName = "TradeTransmitter"          # アプリケーションプール名（サイト名と同じ）

    # IISマネージャーを起動するためのスナップインを読み込む
    Import-Module WebAdministration

    # アプリケーションプールの作成
    if (-not (Test-Path "IIS:\AppPools\$appPoolName")) {
        Write-Log "アプリケーションプールを作成しています..." $LogFile
        New-WebAppPool -Name $appPoolName
    }

    Write-Log ".NET CLR を無効化しています..." $LogFile
    & "C:\Windows\System32\inetsrv\appcmd.exe" set apppool /apppool.name:$appPoolName /managedRuntimeVersion:

    Write-Log "マネージドパイプラインモードを Integrated に設定しています..." $LogFile
    & "C:\Windows\System32\inetsrv\appcmd.exe" set apppool /apppool.name:$appPoolName /managedPipelineMode:Integrated

    # 既存のサイトを削除（既に同じ名前のサイトがある場合）
    if (Test-Path "IIS:\Sites\$siteName") {
        Write-Log "既存のサイトを削除しています..." $LogFile
        Remove-Website -Name $siteName
    }

    # サイトの作成
    Write-Log "サイト $siteName を作成しています..." $LogFile
    if (-not (Test-Path $sitePath)) {
        New-Item -ItemType Directory -Path $sitePath -Force
    }
    New-Website -Name $siteName -Port $port -PhysicalPath $sitePath -ApplicationPool $appPoolName

    # IISの設定適用
    Write-Log "IISを再起動しています..." $LogFile
    iisreset.exe
    Write-Log "IISのサイト $siteName をポート番号 $port で正常に作成しました。" $LogFile
}

# メイン処理
try {
    Install-IIS $LogFile
    Set-Pool $LogFile
} catch {
    Resolve-Error $_.Exception.Message $LogFile
}
