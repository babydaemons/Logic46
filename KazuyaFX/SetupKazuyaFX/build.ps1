# === ログファイル設定 ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$logFile = "BuildKazuyaFX-$timestamp.log"
Start-Transcript -Path $logFile -Append -Force

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX ビルドスクリプト"
Write-Host "🚀 KazuyaFX インストーラーのビルドを開始します..." -ForegroundColor Cyan

try {
    # === 既存の SetupKazuyaFX.exe を終了する ===
    Write-Host "🔄 SetupKazuyaFX.exe を終了しています..." -ForegroundColor Yellow
    $process = Get-Process -Name "SetupKazuyaFX" -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Name "SetupKazuyaFX" -Force
        Start-Sleep -Seconds 2  # プロセス終了待ち
    }

    # === Chocolatey の確認と修正 ===
    Write-Host "🔍 Chocolatey の状態を確認しています..." -ForegroundColor Yellow
    $chocoVersion = $null
    try {
        $chocoVersion = choco --version 2>$null
    } catch {}

    if ($chocoVersion) {
        Write-Host "✅ Chocolatey はインストール済み ($chocoVersion) です。" -ForegroundColor Green
        Write-Host "🔄 Chocolatey を最新バージョンに更新します..." -ForegroundColor Yellow
        choco upgrade chocolatey -y
    } else {
        Write-Host "⚠️ Chocolatey が見つかりません。インストールを試みます..." -ForegroundColor Red
        if (Test-Path "C:\ProgramData\chocolatey") {
            Write-Host "⚠️ 既存の Chocolatey インストールが破損している可能性があります。" -ForegroundColor Red
            Write-Host "❗ Chocolatey を手動で削除してください: 'Remove-Item -Recurse -Force C:\ProgramData\chocolatey'" -ForegroundColor Red
            exit
        }

        # Chocolatey をインストール
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # 環境変数を手動更新（refreshenv ではなく直接設定）
        $env:Path += ";C:\ProgramData\chocolatey\bin"
    }

    # === PowerShellスクリプトをEXEに変換 ===
    Write-Host "🛠️ PowerShellスクリプトを EXE に変換中..." -ForegroundColor Yellow
    Invoke-PS2EXE .\SetupKazuyaFX.ps1 .\SetupKazuyaFX.exe
    if (-not (Test-Path ".\SetupKazuyaFX.exe")) {
        throw "EXE ファイルの生成に失敗しました。"
    }
    Write-Host "✅ EXE のビルドが完了しました！" -ForegroundColor Green

    # === EXE を実行 ===
    Write-Host "▶️ SetupKazuyaFX.exe を実行します..." -ForegroundColor Yellow
    Start-Process -FilePath ".\SetupKazuyaFX.exe" -NoNewWindow

    Write-Host "🎉 ビルド と 実行が完了しました！ 🎉" -ForegroundColor Cyan

} catch {
    Write-Host "❌ エラーが発生しました: $_" -ForegroundColor Red
    Write-Host "📄 詳細なエラーログは $logFile に記録されています。" -ForegroundColor Red
} finally {
    # === ユーザーに終了操作を促す ===
    Write-Host "⏳ Enterキーを押して終了してください..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Stop-Transcript
}
