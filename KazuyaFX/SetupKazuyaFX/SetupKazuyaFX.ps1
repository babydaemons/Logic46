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

# INIファイル読み込み
function Read-IniFile {
    param (
        [string]$iniPath
    )

    if (-Not (Test-Path $iniPath)) {
        Write-Error "File not found: $iniPath"
        return $null
    }

    $iniContent = Get-Content $iniPath
    $iniData = @{}
    $section = ""

    foreach ($line in $iniContent) {
        if ($line -match "^\s*;|^\s*$") { continue }
        if ($line -match "^\[(.+)\]$") {
            $section = $matches[1]
            $iniData[$section] = @{}
        }
        elseif ($line -match "^(.+?)\s*=\s*(.*)$") {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($section -ne "") {
                $iniData[$section][$key] = $value
            }
        }
    }

    return $iniData
}

# PowerShell で利用できる関数を定義
function Get-File {
    param (
        [string]$Url,
        [string]$OutputPath
    )

    try {
        [FileDownloader]::GetFile($Url, $OutputPath)
        if (Test-Path $OutputPath) {
            Write-Host "#### ダウンロードが完了しました: $OutputPath" -ForegroundColor Blue
        } else {
            throw "ダウンロードしたファイルが見つかりません: $OutputPath"
        }
    } catch {
        throw "エラーが発生しました: $_"
    }
}

function Create-Folder {
    param (
        [string]$FolderPath
    )

    if (!(Test-Path $FolderPath)) {
        New-Item -ItemType Directory -Path $FolderPath -Force | Out-Null
        Write-Host "#### フォルダを作成しました: $FolderPath" -ForegroundColor Cyan
    } else {
        Write-Host "#### フォルダは既に存在します: $FolderPath" -ForegroundColor Blue
    }
}

$logFile = Get-AvailablelogFile -baseName $logFile
Start-Transcript -Path $logFile -Append -Force | Out-Null

$Config = Read-IniFile -iniPath "C:\Users\shingo\Desktop\KazuyaFX.ini"
$DomainName = $Config["KazuyaFX"]["DomainName"]
$MailAddress = $Config["KazuyaFX"]["MailAddress"]

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX インストーラー"
Write-Host "#### KazuyaFX のインストールを開始します..." -ForegroundColor Yellow
$AppDir = "C:\KazuyaFX"
Remove-Item $AppDir -Recurse -Force -Verbose:$false; Create-Folder -FolderPath $AppDir
$ArchiveDir = "$AppDir\archive"; Create-Folder -FolderPath $ArchiveDir
$WebRoot = "$AppDir\webroot"; Create-Folder -FolderPath $WebRoot
$CertDir = "$AppDir\certificate"; Create-Folder -FolderPath $CertDir
$NginxDir = "$AppDir\nginx"; Create-Folder -FolderPath $NginxDir
$NginxLogDir = "$NginxDir\log"; Create-Folder -FolderPath $NginxLogDir
$WinAcmeDir = "$AppDir\win-acme"; Create-Folder -FolderPath $WinAcmeDir

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
            Write-Host "#### ポート $port を使用しているアプリがあります。停止を試みます... (試行 $attempts / $maxAttempts)" -ForegroundColor Cyan
    
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
                            Write-Host "#### プロセス $processId を停止しました。" -ForegroundColor Blue
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

# Nginx のインストール関数
function Install-Nginx {
    param (
        [string]$logFile
    )
    if (Test-Path "$NginxDir\nginx.exe") {
        Write-Host "#### Nginx はインストールされています。" -ForegroundColor Blue
    }

    $nginxUrl = "https://nginx.org/download/nginx-1.27.4.zip"
    if ($nginxUrl) {
        Write-Host "#### 最新の Nginx バージョンURL: $nginxUrl" -ForegroundColor Blue
    } else {
        throw "Nginx バージョンの取得に失敗しました。"
    }

    $zipFilePath = "$ArchiveDir\nginx-1.27.4.zip"
    Get-File -Url $nginxUrl -OutputPath $zipFilePath

    Write-Host "#### Nginx を解凍中..." -ForegroundColor Blue
    Expand-Archive -Path $zipFilePath -DestinationPath $AppDir -Force -Verbose:$false | Out-Null
    Move-Item "$AppDir\nginx-1.27.4\*" $NginxDir -Verbose:$false | Out-Null

    if (Test-Path "$NginxDir\nginx.exe") {
        Write-Host "#### Nginx のインストールに成功しました。" -ForegroundColor Cyan
    } else {
        throw "Nginx 実行ファイルが見つかりません。"
    }
}

# win-acme のインストール関数
function Install-WinAcme {
    param (
        [string]$logFile
    )
    if (Test-Path "$WinAcmeDir\wacs.exe") {
        Write-Host "#### win-acme はインストールされています。" -ForegroundColor Blue
    }

    $winAcmeUrl = "https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.trimmed.zip"
    if ($winAcmeUrl) {
        Write-Host "#### 最新の win-acme バージョンURL: $winAcmeUrl" -ForegroundColor Blue
    } else {
        throw "win-acme バージョンの取得に失敗しました。"
    }

    $zipFilePath = "$ArchiveDir\win-acme.v2.2.9.1701.x64.trimmed.zip"
    Get-File -Url $winAcmeUrl -OutputPath $zipFilePath

    Write-Host "#### win-acme を解凍中..." -ForegroundColor Blue
    Expand-Archive -Path $zipFilePath -DestinationPath $WinAcmeDir -Force -Verbose:$false | Out-Null

    if (Test-Path "$WinAcmeDir\wacs.exe") {
        Write-Host "#### win-acme のインストールに成功しました。" -ForegroundColor Cyan
    } else {
        throw "win-acme 実行ファイルが見つかりません。"
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
server {
    listen 443 ssl;
    server_name $DomainName;

    # 証明書の設定
    ssl_certificate     C:/KazuyaFX/certificate/$DomainName-crt.pem;
    ssl_certificate_key C:/KazuyaFX/certificate/$DomainName-key.pem;
    ssl_trusted_certificate C:/KazuyaFX/certificate/$DomainName-chain.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # セキュリティ強化設定
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    # ① Host が $DomainName でなければ遮断
    if (\$host != "$DomainName") {
        return 403;
    }

    # ② クエリパラメータ apikey のチェック
    set \$valid_apikey 0;
    if (\$arg_apikey = "a17f532eb443b7e6713054ba5839b26b383ee3fd498922fe6ca173b0705dd8369fa1ecd2ef9d8dcd0c529612fee0012fb5431d598918d4dec785e5aad11b281aee76d5438df23a2e8f6cd5a543de93e6bebcab08ff526855aae98cf5085c8b613bdbd8fa5ca45ab58d9cea00e10af19def70cda175c3af75511c187f4b229815") {
        set \$valid_apikey 1;
    }

    if (\$valid_apikey = 0) {
        return 403;
    }

    # ③ 転送先 (apikeyを削除)
    location / {
        set \$query \$request_uri;
        if (\$query ~* "(.*)(\\?|&)apikey=[^&]*(.*)") {
            set \$query \$1\$3;
        }

        proxy_pass http://127.0.0.1:5000\$query;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
"@

    # 出力先ファイルのパス
    $outputPath = "$NginxDir\conf\nginx.conf"
    # 設定ファイルを書き出し
    $nginxConfig | Set-Content -Path $outputPath -Encoding UTF8
    Write-Host "#### nginx.conf が $outputPath に作成されました。" -ForegroundColor Blue
}
    
try {
    # === ポート80の確認 ===
    Stop-Process -logFile $logFile

    # === ファイアウォール設定 ===
    Write-Host "#### ファイアウォールの 80/443 ポートを開放しています..." -ForegroundColor Cyan
    Stop-Transcript | Out-Null
    netsh advfirewall firewall add rule name="Allow HTTP" dir=in action=allow protocol=TCP localport=80 *>>$logFile 2>&1
    netsh advfirewall firewall add rule name="Allow HTTPS" dir=in action=allow protocol=TCP localport=443 *>>$logFile 2>&1
    Start-Transcript -Path $logFile -Append -Force | Out-Null
    Write-Host "#### ファイアウォール設定が完了しました。" -ForegroundColor Blue
    
    # === Nginx のインストール ===
    Install-Nginx -logFile $logFile

    # === Let's Encrypt 証明書の取得アプリ (win-acme) のインストール ===
    Install-WinAcme -logFile $logFile

    # === Let's Encrypt 証明書の取得 (win-acme) ===
    Create-Certificate -logFile $logFile

    # === Nginx サービスとして登録 ===
    Write-Host "#### Nginx を Windows サービスとして登録しています..." -ForegroundColor Cyan
    # サービスの作成（binPath 修正）
    $serviceName = "Nginx for KazuyaFX"
    $exePath = "C:\KazuyaFX\Nginx\Nginx.exe"
    if (!(Get-Service -Name $serviceName -ErrorAction SilentlyContinue)) {
        sc.exe create $serviceName binPath= "$exePath" DisplayName= "KazuyaFX Service" start= auto
        if ($LASTEXITCODE -ne 0) {
            throw "Nginx サービスの登録に失敗しました。"
        }
    }
    Write-Host "#### Nginx サービスが正常に登録・起動されました。" -ForegroundColor Blue

    Write-Host "#### セットアップが完了しました！ " -ForegroundColor Yellow

} catch {
    Write-Host "!!!! エラーが発生しました: $_" -ForegroundColor Red
    Write-Host "!!!! 詳細なエラーログは $logFile に記録されています。" -ForegroundColor Red
} finally {
    # === 確実にトランスクリプトを停止 ===
    # トランスクリプトの処理（エラーチェック）
    if ($global:Transcribing) {
        Stop-Transcript | Out-Null
    }

    # === ユーザーに終了操作を促す ===
    Write-Host "#### Enterキーを押して終了してください..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
