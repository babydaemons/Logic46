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
    $response = (Read-Host "#### FXTF MT4 をインストールしますか (Y/N)?").ToLower()
    if ($response -ne "y") {
        return
    }

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
    Write-Host "#### 生徒さん用のEAをインストールするMT4を選択してください" -ForegroundColor Cyan

    $basePath = "$env:APPDATA\\MetaQuotes\\Terminal"

    $targetDirs = New-Object System.Collections.ArrayList

    $index = 1
    foreach ($dir in Get-ChildItem -Path $basePath -Directory) {
        $originPath = Join-Path $dir.FullName "origin.txt"
        if (Test-Path $originPath) {
            $content = (Get-Content $originPath -Raw).Trim()
            if ($content.StartsWith("C:\Program Files (x86)\")) {
                $targetDir = $dir.FullName
                $targetDirs.Add($targetDir) | Out-Null
                $brokerName = ($content.Split("\"))[2]
                Write-Host "($index) $brokerName" -ForegroundColor Green
                $index += 1
            }
        }
    }

    $max = $index - 1
    $resultDir = "$basePath\F1DD1D6E7C4A311D1B1CA0D34E33291D"
    while ($true) {
        $response = Read-Host "#### どの MT4 へインストールしますか (1～$max)?"
        if ([int]::TryParse($response, [ref]$number)) {
            if (1 -ge $number -and $number -gt $max) {
                $resultDir = $targetDirs[$number - 1]
                break
            } else {
                Write-Host "#### 入力エラー: 1～$max の範囲で入力してください: $response" -ForegroundColor Red
            }
        } else {
            Write-Host "#### 入力エラー: 整数で入力してください: $response" -ForegroundColor Red
        }
    }
    return $resultDir
}

function Download-And-Verify-Zip {
    param (
        [string]$terminalFolder
    )
    $url = "https://raw.githubusercontent.com/babydaemons/mt4config/main/qta-kazuyafx.com.api.student.zip"

    $zipPath = Join-Path $env:TEMP "config.zip"
    $testExtractPath = Join-Path $env:TEMP "config_test"
    $maxRetries = 3
    $retryDelaySeconds = 1

    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Write-Host "#### ZIP をダウンロード中... (試行 $i / $maxRetries)" -ForegroundColor Cyan

            # ダウンロード実行
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($url, $zipPath)

            # Null チェックとログ
            if (-not $zipPath) {
                throw "zipPath が null です"
            }
            if (-not (Test-Path $zipPath)) {
                throw "zipPath が存在しません: $zipPath"
            }

            # 展開先フォルダが存在する場合は削除
            if (Test-Path $testExtractPath) {
                Remove-Item $testExtractPath -Recurse -Force
            }

            # 展開テスト
            Expand-Archive -Path $zipPath -DestinationPath $testExtractPath -Force

            Write-Host "#### ZIP の検証に成功しました。" -ForegroundColor Green

            # 一時展開フォルダを削除
            Remove-Item $testExtractPath -Recurse -Force

            Expand-Archive -Path $zipPath -DestinationPath $terminalFolder -Force
            Write-Host "#### FXTF MT4へ先生サーバーの設定を行いました: $terminalFolder" -ForegroundColor Cyan
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
    $terminalFolder = Find-TerminalFolder

    # configの上書き
    if (-not (Download-And-Verify-Zip -terminalFolder $terminalFolder)) {
        throw "config.zip の取得と検証に失敗したため、処理を中断します。"
    }
    
    $EA_Dir = Join-Path  $terminalFolder "MQL4\Experts\KazuyaFX"
    New-Item -ItemType Directory -Path $EA_Dir -Force | Out-Null
    Copy-Item -Path $EA_Path -Destination $EA_Dir -Force
    Write-Host "#### FXTF MT4へ生徒さん用EAのインストールが完了しました: $EA_Dir" -ForegroundColor Cyan
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
