# TradeTransmitterInstaller\TradeTransmitterInstaller02.ps1

# メイン処理
param(
    [string]$LogFile,
    [int]$StartProgress
)

# 共通関数を読み込む
. "$PSScriptRoot\TradeTransmitterInstallerUtil.ps1"

function Test-Installed-WinAcme {
    while ($true) {
        $task = Get-ScheduledTask | Where-Object { $_.TaskName -like "*win-acme renew*" }
        if ($task) {
            break
        }
        Start-Sleep -Milliseconds 100
    }
}

# win-acme のインストール関数
function Install-WinAcme {
    param (
        [string]$LogFile
    )
    Write-Log "最新の win-acme バージョンを取得中..." $LogFile
    $winAcmeApiUrl = "https://api.github.com/repos/win-acme/win-acme/releases/latest"
    $jsonFilePath = "$WorkDir\win-acme-release.json"

    Get-File $winAcmeApiUrl $jsonFilePath $LogFile

    $winAcmeReleaseData = Get-Content $jsonFilePath | ConvertFrom-Json
    Remove-Item $jsonFilePath -Force

    $winAcmeAsset = $winAcmeReleaseData.assets | Where-Object { $_.name -like '*x64.trimmed.zip' } | Select-Object -First 1
    $winAcmeUrl = $winAcmeAsset.browser_download_url

    if ($winAcmeUrl) {
        Write-Log "最新の win-acme バージョンURL: $winAcmeUrl" $LogFile
    } else {
        Resolve-Error "win-acme バージョンの取得に失敗しました。" $LogFile
    }

    $zipFilePath = "$WorkDir\win-acme.zip"
    $winAcmeDir = "C:\win-acme"
    Get-File $winAcmeUrl $zipFilePath $LogFile

    Write-Log "win-acme を解凍中..." $LogFile
    $null = Expand-Archive -Path $zipFilePath -DestinationPath $winAcmeDir -Force -Verbose:$false
    Remove-Item $zipFilePath -Force

    if (Test-Path "$winAcmeDir\wacs.exe") {
        Write-Log "win-acme のインストールに成功しました。" $LogFile
    } else {
        Resolve-Error "win-acme 実行ファイルが見つかりません。" $LogFile
    }

    Write-Log "win-acme を実行してドメイン名を設定します..." $LogFile
    $winAcmeExe = "$winAcmeDir\wacs.exe"
    & $winAcmeExe
}

try {
    Install-WinAcme $LogFile
} catch {
    Resolve-Error $_.Exception.Message $LogFile
}
