Add-Type -AssemblyName System.Windows.Forms

$EA_Path = $($args[0])

# === ログファイル設定 ===
$logFile = "$env:TEMP\KazuyaFX_Installer.log"
$desktop = [Environment]::GetFolderPath("Desktop")

try {
    Start-Transcript -Path $logFile -Append | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show("ログ開始に失敗しました：$_", "KazuyaFX", 0, 48)
}

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX インストーラー"
Write-Host "#### KazuyaFX のインストールを開始します..." -ForegroundColor Yellow

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

function Find-TerminalFolder {
    param (
        [string]$targetText
    )

    $basePath = "$env:APPDATA\\MetaQuotes\\Terminal"

    foreach ($dir in Get-ChildItem -Path $basePath -Directory) {
        $originPath = Join-Path $dir.FullName "origin.txt"
        if (Test-Path $originPath) {
            $content = Get-Content $originPath -Raw
            if ($content.Trim() -eq $targetText) {
                $terminalFolder = $dir.FullName
                Write-Host "#### FXTF MT4のユーザーフォルダが見つかりました: $terminalFolder" -ForegroundColor Cyan
                return $terminalFolder
            }
        }
    }

    # 一致しなかった場合
    $terminalFolder = "$basePath\\F1DD1D6E7C4A311D1B1CA0D34E33291D"
    Write-Host "#### FXTF MT4のユーザーフォルダが見つかりました: $terminalFolder" -ForegroundColor Cyan
    return $terminalFolder
}

function Download-And-Verify-Zip {
    $url = "https://raw.githubusercontent.com/babydaemons/mt4config/main/qta-kazuyafx.com.api.student.zip"
    $zipPath = "$env:TEMP\config.zip"
    $testExtractPath = "$env:TEMP\config_test"
    $maxRetries = 3
    $retryDelaySeconds = 1

    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-Host "#### ZIP をダウンロード中... (試行 $i / $maxRetries)" -ForegroundColor Cyan

            # WebClient を使ってダウンロード
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($url, $zipPath)

            # 展開テスト（ファイル破損確認）
            if (Test-Path $testExtractPath) { Remove-Item $testExtractPath -Recurse -Force }
            Expand-Archive -Path $zipPath -DestinationPath $testExtractPath -Force

            Write-Host "#### ZIP の検証に成功しました。" -ForegroundColor Green
            Remove-Item $testExtractPath -Recurse -Force
            return $true
        } catch {
            Write-Warning "#### ZIP のダウンロードまたは展開に失敗しました: $_"
            if ($i -lt $maxRetries) {
                Write-Host "#### ${retryDelaySeconds}秒後に再試行します..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelaySeconds
            } else {
                Write-Error "#### すべてのリトライで ZIP の検証に失敗しました。"
                return $false
            }
        } finally {
            if ($client) { $client.Dispose() }
        }
    }
}

try {
	# === MT4インストール ===
	Install-MT4

    # Terminalフォルダの検索
    $terminalFolder = Find-TerminalFolder -targetText "C:\Program Files (x86)\FXTF MT4"

    # configの上書き
    if (-not (Download-And-Verify-Zip)) {
        throw "config.zip の取得と検証に失敗したため、処理を中断します。"
    }
        Write-Host "#### FXTF MT4へ先生サーバーの設定を行いました: $terminalFolder" -ForegroundColor Cyan

    $EA_File = Split-Path $fullPath -Leaf $EA_Path
    $EA_Dir = "$terminalFolder\MQL4\Experts\KazuyaFX"
    $target_EA_Path = "$EA_Dir\$EA_File"
    New-Item -ItemType Directory -Path $EA_Dir -Force | Out-Null
    Copy-Item -Path $EA_Path -Destination $EA_Dir -Force
    Write-Host "#### FXTF MT4へ生徒さん用EAのインストールが完了しました: $target_EA_Path" -ForegroundColor Cyan
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
    Copy-Item -Path $logFile -Destination "$desktop\KazuyaFX_Installer.log" -Force
    [System.Windows.Forms.MessageBox]::Show("インストールが完了しました。", "KazuyaFXインストール", 0, 48)
}
