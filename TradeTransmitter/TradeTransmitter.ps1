##########################################################################################
# トレード受信側 IIS（Internet Information Services）の
# インストールスクリプト
##########################################################################################
# Copyright Justine LLC, all right reserved.
##########################################################################################

# ドメイン名ファイルのパスを指定
$domainNamePath = ".\TradeTransmitter-DomainName.txt"
# 証明書ファイルのパスを指定
$pfxKeyPath = ".\TradeTransmitter-Certificate.pfx"
# 証明書ファイルの生パスワードを指定
$plainPassword = "Tr@d?Transm!tterP@ssw0rd"
# 証明書ストアを指定
$certStoreLocation = "cert:\LocalMachine\My"

# ファイルから最初の行を読み込む
$domainName = Get-Content -Path $domainNamePath -TotalCount 1

# 管理者権限が必要かどうか確認する
If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator"))
{
    # 管理者権限で再実行する
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

##########################################################################################
# ステップ1: IIS をインストール
# 管理ツールも含めて IIS をインストール
##########################################################################################
PS C:\Users\Administrator> Install-WindowsFeature Web-Server -IncludeManagementTools

##########################################################################################
# ステップ2: 自己署名証明書の作成
# まず、自己署名証明書を作成します。
##########################################################################################
# 証明書の変数を設定
$cert = New-SelfSignedCertificate -DnsName $domainName -CertStoreLocation $certStoreLocation

# PFXファイルとしてエクスポート（オプション）
$password = ConvertTo-SecureString -String $plainPassword -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath $pfxKeyPath -Password $password

##########################################################################################
# ステップ3: IISに証明書をインポート
# 次に、IISに証明書をインポートします。
##########################################################################################
# PFXファイルをインポート
$password = ConvertTo-SecureString -String $plainPassword -Force -AsPlainText
Import-PfxCertificate -FilePath $pfxKeyPath -CertStoreLocation $certStoreLocation -Password $password

##########################################################################################
# ステップ4: IISサイトに証明書をバインド
# 最後に、IISのサイトに証明書をバインドし、45678番ポートで待ち受けるように設定します。
##########################################################################################
# 証明書のサムプリントを取得
$certThumbprint = (Get-ChildItem -Path $certStoreLocation | Where-Object { $_.DnsNameList -contains $domainName }).Thumbprint

# サイトに証明書をバインド
Import-Module WebAdministration

# 新しいバインドを作成して証明書をバインドする
New-WebBinding -Name "TradeTransmitter Web Site" -Protocol https -Port 45678
Push-Location IIS:\SslBindings
Get-Item cert:\LocalMachine\My\$certThumbprint | New-Item 0.0.0.0!45678
Pop-Location

##########################################################################################
# ステップ5: ファイアウォールの設定
# ファイアウォールで45678番ポートを許可する必要があります。
##########################################################################################
New-NetFirewallRule -DisplayName "Allow HTTPS on Port 45678" -Direction Inbound -Protocol TCP -LocalPort 45678 -Action Allow

Write-Host "処理が完了しました。[Enter]キーを押してください..."
Read-Host