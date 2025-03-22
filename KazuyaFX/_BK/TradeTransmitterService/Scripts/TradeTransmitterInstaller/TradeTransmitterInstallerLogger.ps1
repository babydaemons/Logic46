param (
    [string]$LogFile,
    [string]$Message
)

# タイムスタンプ取得
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# UTF-8エンコードでバイト配列に変換
#$utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($Message)

# バイト配列をUTF-8文字列として復元
#$OutputMessage = [System.Text.Encoding]::UTF8.GetString($utf8Bytes)

# タイムスタンプとともに出力
[System.Console]::ForegroundColor = 'White'
[System.Console]::BackgroundColor = 'DarkRed'
Write-Host "#### $Message" -NoNewline
[System.Console]::ResetColor()
Write-Host "`n" -NoNewline

Add-Content -Path $LogFile -Value "[$timeStamp] $Message" -Encoding utf8
