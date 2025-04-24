Add-Type -AssemblyName System.Windows.Forms

# === ログファイル設定 ===
$logFile = "$env:TEMP\KazuyaFX_Setup.log"
$desktop = [Environment]::GetFolderPath("Desktop")

try {
    Start-Transcript -Path $logFile -Append | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show("ログ開始に失敗しました：$_", "KazuyaFX", 0, 48)
}

# 管理者権限で実行されているかチェック
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "管理者として再実行します…" -ForegroundColor Yellow
    # PowerShell を同じコンソールで管理者権限に昇格
    $command = "Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command `"& { $([System.IO.File]::ReadAllText('$($MyInvocation.MyCommand.Path)')) }`"' -Verb RunAs"
    Invoke-Expression $command
    Exit
}

# 管理者権限で実行されている場合の処理
Write-Host "管理者権限で実行中..." -ForegroundColor Green

$AppDir = "C:\Windows\Temp\KazuyaFX"
$MetaQuotes = "Users\Administrator\AppData\Roaming\MetaQuotes\Terminal\F1DD1D6E7C4A311D1B1CA0D34E33291D"

& taskkill.exe /IM "nginx.exe" /F 2>&1 | Out-Null
if (Test-Path "C:\KazuyaFX") {
    Remove-Item "C:\KazuyaFX" -Force -Recurse | Out-Null
}
if (Test-Path "C:\$MetaQuotes\MQL4\Experts\KazuyaFX") {
    Remove-Item "C:\$MetaQuotes\MQL4\Experts\KazuyaFX" -Force -Recurse | Out-Null
}
$DomainName = "qta-kazuyafx.com"
$MailAddress = "qta.kazuyafx@gmail.com"

if (Test-Path "$desktop\KazuyaFX_Setup.json") {
    # 読み込み
    $config = Get-Content "$desktop\KazuyaFX_Setup.json" | ConvertFrom-Json
    $DomainName = $config.Certification.DomainName # "qta-kazuyafx.com"
    $MailAddress = $config.Certification.MailAddress # "qta.kazuyafx@gmail.com"
}

Write-Host "#### ドメイン名:     $DomainName" -ForegroundColor Cyan
Write-Host "#### メールアドレス: $MailAddress" -ForegroundColor Cyan

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

function Create-Folder {
    param (
        [string]$FolderPath
    )

    if (!(Test-Path $FolderPath)) {
        New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
        # Write-Host "#### フォルダを作成しました: $FolderPath" -ForegroundColor Cyan
    } else {
        # Write-Host "#### フォルダは既に存在します: $FolderPath" -ForegroundColor Blue
    }
}

$logFile = Get-AvailablelogFile -baseName $logFile
Start-Transcript -Path $logFile -Append -Force | Out-Null

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX インストーラー"
Write-Host "#### KazuyaFX のインストールを開始します..." -ForegroundColor Yellow
#$logDir = "C:\KazuyaFX\logs" #; Create-Folder -FolderPath $logDir
$WebRoot = "C:\KazuyaFX\webroot" #; Create-Folder -FolderPath $WebRoot
$CertDir = "C:\KazuyaFX\certificate" #; Create-Folder -FolderPath $CertDir
$NginxDir = "C:\KazuyaFX\nginx"      #; Create-Folder -FolderPath $NginxDir
#$NginxLogDir = "$NginxDir\logs" #; Create-Folder -FolderPath $NginxLogDir
$WinAcmeDir = "C:\KazuyaFX\win-acme" #; Create-Folder -FolderPath $WinAcmeDir

function Install-MT4 {
    $fxtfExePath = "C:\Program Files (x86)\FXTF MT4\terminal.exe"
    $fxtfInstallerUrl = "https://www.fxtrade.co.jp/system/download/fxtf4setup.exe"
    $fxtfInstallerPath = "$env:TEMP\fxtf4setup.exe"

    Write-Host "#### FXTF MT4 の存在確認..."
    if (Test-Path $fxtfExePath) {
        Write-Host "#### FXTF MT4 はすでにインストール済みです。" -ForegroundColor Cyan
    } else {
        Write-Host "#### FXTF MT4 をダウンロード中..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $fxtfInstallerUrl -OutFile $fxtfInstallerPath
        Write-Host "#### インストーラーを起動します..." -ForegroundColor Cyan
        Start-Process -FilePath $fxtfInstallerPath -Wait
        Remove-Item $fxtfInstallerPath -Force
    }
}

function Stop-Process {
    param (
        [int]$port,
        [string]$logFile
    )

    $maxAttempts = 5
    $attempts = 0

    function Write-Log {
        param ([string]$message)
        Write-Host $message -ForegroundColor Blue
        if ($logFile) {
            $message | Out-File -FilePath $logFile -Append -Encoding UTF8
        }
    }

    while ($attempts -lt $maxAttempts) {
        $attempts++

        $netstatOutput = netstat -ano -p tcp
        $lines = $netstatOutput | Where-Object { $_ -match '^\s*TCP' }

        # ローカルアドレス列だけを見る（第2カラム）
        $matches = $lines | Where-Object {
            $cols = ($_ -split '\s+') 
            $cols.Count -ge 5 -and $cols[1] -match ":$port$"
        }

        if ($matches) {
            Write-Log "#### ポート $port を使用しているアプリがあります。停止します... (試行 $attempts / $maxAttempts)"

            $processIds = $matches | ForEach-Object {
                ($_ -split '\s+')[-1]
            } | Where-Object { $_ -match '^\d+$' } | Sort-Object -Unique

            foreach ($pid in $processIds) {
                if ($pid -eq 0) { continue }

                try {
                    $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
                    $procName = if ($proc) { $proc.ProcessName } else { "<不明>" }

                    Write-Log "---- プロセス名: $procName (PID: $pid) を停止します"

                    $result = & taskkill.exe /PID $pid /F 2>&1

                    if ($result -match "成功") {
                        Write-Log "#### プロセス $pid ($procName) を停止しました。"
                    } elseif ($result -match "理由: これは重要なシステム プロセスです。") {
                        Write-Log "**** システムプロセスのため停止できません: $result"
                        return
                    }

                } catch {
                    Write-Log "!!!! エラーが発生しました: $_"
                }
            }

            return
        } else {
            Write-Log "ポート $port を使用しているアプリはありません。"
            break
        }

        Start-Sleep -Seconds 2
    }

    if ($attempts -ge $maxAttempts) {
        throw "ポート $port を使用しているアプリの停止に失敗しました。手動で確認してください。"
    }
}

function Create-Certificate {
    param (
        [string]$logFile
    )

    Write-Host "#### Let's Encrypt の証明書を取得しています..." -ForegroundColor Cyan
    $winAcmeExe = "$WinAcmeDir\wacs.exe"
    Stop-Transcript | Out-Null
    Start-Process -FilePath $winAcmeExe -ArgumentList "--target manual --host $DomainName --emailaddress $MailAddress --accepttos --store pemFiles --pemfilespath $CertDir --webroot $WebRoot" -NoNewWindow -Wait *>>$logFile 2>&1  # ログファイルに追記（標準エラー出力も含む）
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Let's Encrypt 証明書の取得に失敗しました。"
    }
    Write-Host "#### 証明書の取得が完了しました。" -ForegroundColor Blue

    # 設定内容を変数に格納
    $nginxConfig = @"
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    error_log C:/KazuyaFX/nginx/logs/error.log;

    map @status @loggable {
        ~^200@  0;  # ステータスコードが200ならログを無効化
        default 1;  # それ以外はログを有効化
    }

    access_log C:/KazuyaFX/nginx/logs/access.log combined if=@loggable;

    server {
        listen 443 ssl;
        server_name !!!DomainName!!!;

        # 証明書の設定
        ssl_certificate     C:/KazuyaFX/certificate/!!!DomainName!!!-crt.pem;
        ssl_certificate_key C:/KazuyaFX/certificate/!!!DomainName!!!-key.pem;
        ssl_trusted_certificate C:/KazuyaFX/certificate/!!!DomainName!!!-chain.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        # セキュリティ強化設定
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Content-Type-Options nosniff;
        add_header X-Frame-Options DENY;
        add_header X-XSS-Protection "1; mode=block";

        # 1. Host が !!!DomainName!!! でなければ遮断
        if (@host != "!!!DomainName!!!") {
            return 403;
        }

        # 2. HTTP ヘッダー認証
        set @valid_token 0;

        if (@http_authorization ~* "^Bearer\s+(0163655e13d0e8f87d8c50140024bff3fa16510f1b0103aad40a7c7af2fc48934630a60beea6eddb453a903c106f7972e7fbaeb305adcc2b08e8ff4fb8ad8d17)$") {
            set @valid_token 1;
        }

        if (@valid_token = 0) {
            return 403;
        }

        # 3. 転送先
        location /api/ {
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP @remote_addr;
            proxy_set_header X-Forwarded-For @proxy_add_x_forwarded_for;
        }
    }
}
"@

    # 出力先ファイルのパス
    $outputPath = "$NginxDir\conf\nginx.conf"
    # 設定ファイルを書き出し
    $text = $nginxConfig.Replace("!!!DomainName!!!", $DomainName).Replace("@", "$")
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($outputPath, $text, $utf8NoBom)
    Write-Host "#### nginx.conf が $outputPath に作成されました。" -ForegroundColor Blue
}
    
try {
    Copy-Item -Path "C:\Windows\Temp\Users\Administrator\Desktop\*.*" -Destination "C:\Users\Administrator\Desktop" -Force

    # === MT4インストール ===
	Install-MT4
    Copy-Item -Path "C:\Windows\Temp\$MetaQuotes\config\*.*" -Destination "C:\$MetaQuotes\config" -Force
    Copy-Item -Path "C:\Windows\Temp\$MetaQuotes\MQL4\Experts\KazuyaFX" -Destination "C:\$MetaQuotes\MQL4\Experts\KazuyaFX" -Force -Recurse

    # === ポート80の確認 ===
    Stop-Transcript | Out-Null
    Stop-Process -port 80 -logFile $logFile
    # === ポート443の確認 ===
    Stop-Process -port 443 -logFile $logFile
    Start-Transcript -Path $logFile -Append -Force | Out-Null

    # === ファイアウォール設定 ===
    Write-Host "#### ファイアウォールの 80/443 ポートを開放しています..." -ForegroundColor Cyan
    Stop-Transcript | Out-Null
    netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=TCP localport=80 *>>$logFile 2>&1
    netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=TCP localport=443 *>>$logFile 2>&1
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    Write-Host "#### ファイアウォール設定が完了しました。" -ForegroundColor Blue
    
    Write-Host "#### インストールファイルをコピーしています..." -ForegroundColor Cyan
    Copy-Item -Path $AppDir -Destination "C:\KazuyaFX" -Force -Recurse

    # === Let's Encrypt 証明書の取得 (win-acme) ===
    Create-Certificate -logFile $logFile

    Write-Host "#### インストールが完了しました。" -ForegroundColor Cyan
    [System.Windows.Forms.MessageBox]::Show("インストールが完了しました。", "KazuyaFXインストール", 0, 48)
} catch {
    Write-Host "!!!! エラーが発生しました: $_" -ForegroundColor Cyan
    Write-Host "!!!! 詳細なエラーログは $logFile に記録されています。" -ForegroundColor Cyan
    Write-Host "!!!! Enterキーを押して終了してください..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
} finally {
    # === 確実にトランスクリプトを停止 ===
    # トランスクリプトの処理（エラーチェック）
    if ($global:Transcribing) {
        Stop-Transcript | Out-Null
    }
    Copy-Item -Path $logFile -Destination "$desktop\KazuyaFX_Setup.log" -Force
}
