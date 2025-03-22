# TradeTransmitterInstaller\TradeTransmitterInstallerUtil.ps1

# 総ステップ数を定義
$TotalSteps = 33

$WorkDir = "C:\Temp"

# ステップカウンターの初期化
$global:StepCounter = $StartProgress

# ログ出力関数の定義
function Write-Log {
    param(
        [string]$Message,
        [string]$LogFile
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $OutputMessage = "($global:StepCounter/$TotalSteps) $Message"
    if ($global:StepCounter -gt 1) {
        Write-Host "`n" -NoNewline
    }
    [System.Console]::ForegroundColor = 'White'
    [System.Console]::BackgroundColor = 'DarkRed'
    Write-Host "#### $OutputMessage" -NoNewline
    [System.Console]::ResetColor()
    Write-Host "`n" -NoNewline
    Add-Content -Path $LogFile -Value "[$timeStamp] $OutputMessage" -Encoding utf8
    $global:StepCounter++
}

# エラーハンドリング関数の定義
function Resolve-Error {
    param (
        [string]$Message,
        [string]$LogFile
    )
    Write-Log "申し訳ございません。エラーが発生しました。 $LogFile を添付して babydaemons@gmail.com までメールしてサポートを求めてください。" $LogFile
    Write-Log "エラー内容: $Message" $LogFile
    if ($Error[0]) {
        Write-Log "スタックトレース: $($Error[0].ScriptStackTrace)" $LogFile
        Write-Log "例外の詳細: $($Error[0].Exception.Message)" $LogFile
    }
    exit 1
}

# ダウンロード用のラッパー関数
function Get-File {
    param (
        [string]$url,
        [string]$outputPath,
        [string]$LogFile
    )

    # 使用するダウンロードツールを切り替える
    $useCurl = $true  # $false にすると Invoke-WebRequest を使用

    if ($useCurl) {
        Write-Log "$url から $outputPath へ取得中..." $LogFile
        & curl.exe -L $url -o $outputPath > $null 2>&1  # 標準出力とエラー出力を抑制
    } else {
        Invoke-WebRequest -Uri $url -OutFile $outputPath -Proxy $null -UseBasicParsing | Tee-Object -FilePath $LogFile -Append
    }

    if (-not (Test-Path $outputPath)) {
        Resolve-Error "$url のダウンロードに失敗しました。" $LogFile
    }
}
