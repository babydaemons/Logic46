# === ログファイル設定 ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "SetupKazuyaFX-$timestamp.log"

# ログファイルが使用中なら、新しいファイル名を作成
function Get-AvailableLogFile {
    param ([string]$baseName)
    $index = 1
    $logFile = $baseName
    while (Test-Path $logFile) {
        $logFile = "$($baseName -replace '\.log$', '')_$index.log"
        $index++
    }
    return $logFile
}

$logFile = Get-AvailableLogFile -baseName $logFile
Start-Transcript -Path $logFile -Append -Force | Out-Null

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX インストーラー"
Write-Host "#### KazuyaFX のインストールを開始します..." -ForegroundColor Cyan

try {
    # === ポート80の確認 ===
    Write-Host "#### 他のアプリがポート80を使用していないか確認中..." -ForegroundColor Yellow
    $portCheck = netstat -ano | Select-String ":80"
    if ($portCheck) {
        Write-Host "#### ポート80を使用しているアプリがあります。停止を試みます..." -ForegroundColor Red
        $chechPids = $portCheck -replace '.*LISTENING\s+', ''
        foreach ($chechPid in $chechPids) {
            Stop-Process -Id $chechPid -Force -ErrorAction SilentlyContinue
        }
        Write-Host "#### ポート80を開放しました。" -ForegroundColor Green
    } else {
        Write-Host "#### ポート80は使用されていません。" -ForegroundColor Green
    }

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

    # === Let's Encrypt 証明書の取得 (win-acme) ===
    Write-Host "#### Let's Encrypt の証明書を取得しています..." -ForegroundColor Yellow
    Start-Process -FilePath "C:\KazuyaFX\win-acme\wacs.exe" -ArgumentList "--install" -NoNewWindow -Wait
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
