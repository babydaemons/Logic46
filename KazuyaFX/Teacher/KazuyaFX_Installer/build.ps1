# === ログファイル設定 ===
$timestamp = Get-Date -Format "yyyyMMdd-HHmm"
$logFile = "BuildKazuyaFX-$timestamp.log"

# === コンソールのタイトルを変更 ===
$host.UI.RawUI.WindowTitle = "KazuyaFX ビルドスクリプト"
Write-Host "**** KazuyaFX インストーラーのビルドを開始します..." -ForegroundColor Cyan

try {
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
    Write-Host "**** ビルドが完了しました。" -ForegroundColor Cyan
}
