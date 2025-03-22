### TradeTransmitterInstaller01.ps1

# メイン処理
param(
    [string]$LogFile,
    [int]$StartProgress
)

# 共通関数を読み込む
. "$PSScriptRoot\TradeTransmitterInstallerUtil.ps1"

function Install-PowerScript7 {
    param (
        [string]$LogFile
    )

    if (Test-Path -Path $WorkDir -PathType Container) {
        Remove-Item $WorkDir -Recurse -Force
    }
    New-Item -Path $WorkDir -ItemType Directory

    # GitHub API URL for PowerShell Releases
    $githubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"

    # 最新リリース情報を取得
    Write-Log "PowerScript 7 のインストール元を取得しています..." $LogFile
    $jsonFilePath = "$WorkDir\powershell-release.json"
    Get-File $githubApiUrl $jsonFilePath $LogFile

    # 最新のMSIファイルのURLを取得（x64用）
    $releaseData = Get-Content $jsonFilePath | ConvertFrom-Json
    $assets = $releaseData.assets | Where-Object { $_.name -match "PowerShell-.*-win-x64\.msi$" }

    if ($null -eq $assets) {
        Resolve-Error "MSI インストーラーが見つかりませんでした。" $LogFile
    }

    $msiUrl = $assets.browser_download_url
    $msiFileName = "$WorkDir\PowerShell.msi"
    $logFileName = "$WorkDir\PowerShell.log"

    # MSIファイルをダウンロード
    Get-File $msiUrl $msiFileName $LogFile

    # インストールを開始
    Write-Log "PowerShell 7 のインストールを開始します..." $LogFile
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiFileName`" /quiet /norestart /L* `"$logFileName`"" -Wait
    Get-Content $logFileName | Add-Content -Encoding utf8 $LogFile
    Remove-Item $msiFileName -Force
    Remove-Item $logFileName -Force
    Remove-Item $jsonFilePath -Force

    # インストール確認
    $intalledPath = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $intalledPath) {
        Write-Log "PowerShell 7 のインストールが完了しました。" $LogFile
    } else {
        Resolve-Error "インストールに失敗しました。" $LogFile
    }
}

# メイン処理
try {
    Install-PowerScript7 $LogFile
} catch {
    Resolve-Error $_.Exception.Message $LogFile
}
