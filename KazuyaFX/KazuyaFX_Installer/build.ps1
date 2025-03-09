# === ログファイル設定 ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$logFile = "BuildKazuyaFX-$timestamp.log"
Start-Transcript -Path $logFile -Append -Force

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX ビルドスクリプト"
Write-Host "**** KazuyaFX インストーラーのビルドを開始します..." -ForegroundColor Cyan

try {
    # === 既存の KazuyaFX_Installer.exe を終了する ===
    Write-Host "**** KazuyaFX_Installer.exe を終了しています..." -ForegroundColor Yellow
    $process = Get-Process -Name "KazuyaFX_Installer" -ErrorAction SilentlyContinue
    if ($process) {
        Stop-Process -Name "KazuyaFX_Installer" -Force
        Start-Sleep -Seconds 2  # プロセス終了待ち
    }

    # === PowerShellスクリプトをEXEに変換 ===
    Write-Host "**** PowerShellスクリプトを EXE に変換中..." -ForegroundColor Yellow
    Invoke-PS2EXE .\KazuyaFX_Installer.ps1 .\KazuyaFX_Installer.exe
    if (-not (Test-Path ".\KazuyaFX_Installer.exe")) {
        throw "EXE ファイルの生成に失敗しました。"
    }
    Write-Host "**** EXE のビルドが完了しました！" -ForegroundColor Green
} catch {
    Write-Host "!!!! エラーが発生しました: $_" -ForegroundColor Red
    Write-Host "!!!! 詳細なエラーログは $logFile に記録されています。" -ForegroundColor Red
} finally {
    # === ユーザーに終了操作を促す ===
    Write-Host "**** ビルドとテストが完了しました。Enterキーを押して終了してください..." -ForegroundColor Cyan
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Stop-Transcript
}
