# TradeTransmitterInstaller\TradeTransmitterInstaller02.ps1

# メイン処理
param(
    [string]$LogFile,
    [int]$StartProgress
)

# 共通関数を読み込む
. "$PSScriptRoot\TradeTransmitterInstallerUtil.ps1"

# MT4のインストール関数
function Install-MT4 {
    param (
        [string]$LogFile
    )

    Write-Log "FXTF MT4のセットアップファイルをダウンロードしています..." $LogFile
    $setupUrl = "https://www.fxtrade.co.jp/system/download/fxtf4setup.exe"
    $setupPath = "$WorkDir\fxtf4setup.exe"
    Get-File $setupUrl $setupPath $LogFile
    Write-Log "FXTF MT4のセットアップを実行しています。インストールの完了を待っています..." $LogFile
    Start-Process -FilePath $setupPath -Wait

    $mt4InstallTargetDir = "C:\Program Files (x86)\FXTF MT4"
    if (-Not (Test-Path "$mt4InstallTargetDir\terminal.exe")) {
        Resolve-Error "terminal.exe が $mt4InstallTargetDir に見つかりません。インストールが正しく完了していない可能性があります。" $LogFile
    }
    Remove-Item $setupPath -Force

    Write-Log "MQL4\Expertsフォルダを検出しています..." $LogFile
    $metaQuotesDir = "$env:APPDATA\MetaQuotes\Terminal"
    $originFiles = Get-ChildItem -Path $metaQuotesDir -Recurse -Filter "origin.txt" -ErrorAction Stop
    $matchedOriginFile = $originFiles | Where-Object { (Get-Content $_.FullName) -eq $mt4InstallTargetDir } | Select-Object -First 1

    if ($null -eq $matchedOriginFile) {
        Resolve-Error "必要な内容を含むorigin.txt ファイルが見つかりません。" $LogFile
    }

    $expertFolder = Get-ChildItem -Path $metaQuotesDir -Recurse -Directory -ErrorAction Stop | Where-Object { $_.FullName -like "*MQL4\Experts" } | Select-Object -First 1
    if ($null -eq $expertFolder) {
        Resolve-Error "MQL4\Expertsフォルダが見つかりませんでした。" $LogFile
    } else {
        Write-Log "MQL4\Expertsフォルダを検出しました: $($expertFolder.FullName)" $LogFile
    }

    $destinationPath = "$($expertFolder.FullName)\TradeTransmitter"
    return $destinationPath
}

# リポジトリのクローン関数
function Get-Repo {
    param (
        [string]$destinationPath,
        [string]$LogFile
    )

    Write-Log "リポジトリをクローンしています..." $LogFile
    $repoDir = "$WorkDir\Logic46"
    if (Test-Path -Path $repoDir -PathType Container) {
        Remove-Item $repoDir -Recurse -Force
    }

    Set-Location $WorkDir
    git.exe clone https://github.com/babydaemons/Logic46.git
    Write-Log "リポジトリをクローンしました: $repoDir" $LogFile

    $sourcePath = "$repoDir\TradeTransmitter"
    $destinationPath = "$($expertFolder.FullName)\TradeTransmitter"

    Write-Log "TradeTransmitter のファイルを $destinationPath へ移動しています..." $LogFile
    if (Test-Path -Path $destinationPath -PathType Container) {
        Remove-Item $destinationPath -Recurse -Force
    }
    Move-Item -Path $sourcePath -Destination $destinationPath -Force

    Write-Log "TradeTransmitterServer のファイルを $finalDestinationPath へ移動しています..." $LogFile
    $serverSourcePath = "$destinationPath\TradeTransmitterServer"
    $finalDestinationPath = "$WorkDir\TradeTransmitterApp"
    if (Test-Path -Path $repoDir -PathType Container) {
        Remove-Item $repoDir -Recurse -Force
    }

    if (Test-Path -Path $finalDestinationPath -PathType Container) {
        Remove-Item $finalDestinationPath -Recurse -Force
    }

    Move-Item -Path $serverSourcePath -Destination $finalDestinationPath -Force
    if (Test-Path -Path $repoDir -PathType Container) {
        Remove-Item $repoDir -Recurse -Force
    }

    Write-Log "サーバーアプリを公開しています..." $LogFile
    Set-Location "$finalDestinationPath\TradeTransmitterServer"
    dotnet.exe publish -c Release -r win-x64 --self-contained true -o "C:\inetpub\wwwroot\api"
}

try {
    $destinationPath = Install-MT4 -LogFile $LogFile
    Get-Repo -destinationPath $destinationPath -LogFile $LogFile
} catch {
    Resolve-Error $_.Exception.Message $LogFile
}
