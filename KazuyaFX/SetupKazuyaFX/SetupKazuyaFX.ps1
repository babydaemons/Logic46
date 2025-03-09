# === ログファイル設定 ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "SetupKazuyaFX-$timestamp.log"

# ログファイルが使用中なら、新しいファイル名を作成
function Get-AvailablelogFile {
    param ([string]$baseName)
    $index = 1
    $logFile = $baseName
    while (Test-Path $logFile) {
        $logFile = "$($baseName -replace '\.log$', '')_$index.log"
        $index++
    }
    return $logFile
}

# C# の WebClient を使用してファイルをダウンロードする関数を追加
Add-Type -TypeDefinition @"
using System;
using System.Net;
using System.IO;

public class FileDownloader
{
    public static void GetFile(string url, string outputPath)
    {
        using (WebClient client = new WebClient())
        {
            client.DownloadFile(url, outputPath);
        }
    }
}
"@ -Language CSharp

# PowerShell で利用できる関数を定義
function Get-File {
    param (
        [string]$Url,
        [string]$OutputPath
    )

    try {
        [FileDownloader]::GetFile($Url, $OutputPath)
        Write-Host "ダウンロードが完了しました: $OutputPath" -ForegroundColor Green
    } catch {
        Write-Host "エラーが発生しました: $_" -ForegroundColor Red
    }
}

$logFile = Get-AvailablelogFile -baseName $logFile
Start-Transcript -Path $logFile -Append -Force | Out-Null

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX インストーラー"
Write-Host "#### KazuyaFX のインストールを開始します..." -ForegroundColor Cyan

# win-acme のインストール関数
function Install-WinAcme {
    param (
        [string]$logFile
    )
    $WorkDir = "C:\KazuyaFX\win-acme"
    $winAcmeUrl = "https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.trimmed.zip"

    if ($winAcmeUrl) {
        Write-Host "#### 最新の win-acme バージョンURL: $winAcmeUrl" -ForegroundColor Yellow
    } else {
        throw "win-acme バージョンの取得に失敗しました。"
    }

    $zipFilePath = "$WorkDir\win-acme.zip"
    $winAcmeDir = $WorkDir
    Get-File -Url $winAcmeUrl -OutputPath $zipFilePath

    Write-Host "#### win-acme を解凍中..." -ForegroundColor Yellow
    $null = Expand-Archive -Path $zipFilePath -DestinationPath $winAcmeDir -Force -Verbose:$false
    Remove-Item $zipFilePath -Force

    if (Test-Path "$winAcmeDir\wacs.exe") {
        Write-Host "#### win-acme のインストールに成功しました。" -ForegroundColor Yellow
    } else {
        throw "win-acme 実行ファイルが見つかりません。"
    }
}

function Stop-Process {
    param (
        [string] $logFile
    )

    $port = 80
    $maxAttempts = 5
    $attempts = 0
    
    while ($attempts -lt $maxAttempts) {
        $attempts++
        $processInfo = netstat -ano | Select-String ":$port"
    
        if ($processInfo) {
            Write-Host "#### ポート $port を使用しているアプリがあります。停止を試みます... (試行 $attempts / $maxAttempts)" -ForegroundColor Yellow
    
            # PID を抽出（最後の列にある数値が PID）
            $processIds = $processInfo | ForEach-Object {
                ($_ -split '\s+')[-1]  # 最後の要素が PID
            } | Where-Object { $_ -match '^\d+$' }  # 数値のみ取得
            
            if ($processIds) {
                foreach ($processId in $processIds) {
                    try {
                        # taskkill.exe を使用してプロセスを強制終了
                        $taskkillResult = & taskkill.exe /PID $processId /F 2>&1
    
                        if ($taskkillResult -match "成功") {
                            Write-Host "#### プロセス $processId を停止しました。" -ForegroundColor Green
                        } elseif ($taskkillResult -match "理由: これは重要なシステム プロセスです。Taskkill でこのプロセスを終了できません。") {
                            Write-Host "**** プロセスを停止しました: $taskkillResult" -ForegroundColor Red
                            return
                        } else {
                            Write-Host "!!!! プロセス $processId の停止に失敗しました: $taskkillResult" -ForegroundColor Red
                        }
                    } catch {
                        Write-Host "!!!! エラーが発生しました: $_" -ForegroundColor Red
                    }
                }
                return
            } else {
                Write-Host "!!!! 有効なプロセス ID が見つかりませんでした。" -ForegroundColor Red
            }
    
            Start-Sleep -Seconds 2  # 2秒待機
        } else {
            Write-Host "ポート $port を使用しているアプリはありません。" -ForegroundColor Green
            break  # ループを抜ける
        }
    }
    
    if ($attempts -ge $maxAttempts) {
        throw "ポート $port を使用しているアプリの停止に失敗しました。手動で確認してください。"
    }
}

try {
    # === ポート80の確認 ===
    Stop-Process -logFile $logFile

    # === NGINX のインストール ===
    Write-Host "#### NGINX（ウェブサーバー）をインストールしています..." -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    choco install nginx -y --no-progress *>>$logFile 2>&1  # ログファイルに追記（標準エラー出力も含む）
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "NGINX のインストールに失敗しました。"
    }
    Write-Host "#### NGINX のインストールが完了しました。" -ForegroundColor Green

    # === ファイアウォール設定 ===
    Write-Host "#### ファイアウォールの 80/443 ポートを開放しています..." -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=TCP localport=80 *>>$logFile 2>&1
    netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=TCP localport=443 *>>$logFile 2>&1
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    Write-Host "#### ファイアウォール設定が完了しました。" -ForegroundColor Green

    # === Let's Encrypt 証明書の取得アプリ (win-acme) のインストール ===
    Install-WinAcme -logFile $logFile

    # === Let's Encrypt 証明書の取得 (win-acme) ===
    #Write-Host "#### Let's Encrypt の証明書を取得しています..." -ForegroundColor Yellow
    #Start-Process -FilePath "C:\KazuyaFX\win-acme\wacs.exe" -ArgumentList "--install" -NoNewWindow -Wait
    
    Write-Host "#### Let's Encrypt の証明書を取得しています..." -ForegroundColor Yellow
    $winAcmeExe = "C:\KazuyaFX\win-acme\wacs.exe"
    $domainName = "babydaemons.jp"
    $emailAddress = "babydaemons@gmail.com"
    $certDir = "C:\KazuyaFX\certificate"
    Stop-Transcript | Out-Null
    Start-Process -FilePath $winAcmeExe -ArgumentList "--target manual --host $domainName --emailaddress $emailAddress --accepttos --store pemFiles --pemfilespath $certDir --validation http-01" -NoNewWindow -Wait *>>$logFile 2>&1  # ログファイルに追記（標準エラー出力も含む）
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Let's Encrypt 証明書の取得に失敗しました。"
    }
    Write-Host "#### 証明書の取得が完了しました。" -ForegroundColor Green

    # === NGINX サービスとして登録 ===
    Write-Host "#### NGINX を Windows サービスとして登録しています..." -ForegroundColor Yellow
    Stop-Transcript | Out-Null
    sc create NGINX binPath= "C:\KazuyaFX\nginx\nginx.exe" start= auto *>>$logFile 2>&1
    sc start NGINX *>>$logFile 2>&1
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "NGINX サービスの登録に失敗しました。"
    }
    Write-Host "#### NGINX サービスが正常に登録・起動されました。" -ForegroundColor Green

    Write-Host "#### セットアップが完了しました！ " -ForegroundColor Cyan

} catch {
    Write-Host "!!!! エラーが発生しました: $_" -ForegroundColor Red
    Write-Host "!!!! 詳細なエラーログは $logFile に記録されています。" -ForegroundColor Red
} finally {
    # === 確実にトランスクリプトを停止 ===
    Stop-Transcript | Out-Null

    # === ユーザーに終了操作を促す ===
    Write-Host "#### Enterキーを押して終了してください..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
