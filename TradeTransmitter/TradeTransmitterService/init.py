import os
import subprocess
import zipfile
import requests
from util import download, exit_on_error, mkdir, write_log, log_file
from config import CERT_DIR, WIN_ACME_DIR, WWW_ROOT, CHALLENGE_FOLDER, DOWNLOAD_DIR, FXTF_MT4_URL, FXTF_MT4_PATH

def set_firewall_rules():
    """ファイアウォール設定 (HTTP:80, HTTPS:443の開放)"""
    write_log("ファイアウォールの設定を行っています...")
    try:
        write_log("HTTP(80)ポートの開放を実行しています...")
        subprocess.run(["netsh", "advfirewall", "firewall", "add", "rule", "name=HTTP Port 80", "dir=in", "action=allow", "protocol=TCP", "localport=80"], check=True)
        write_log("HTTPS(443)ポートの開放を実行しています...")
        subprocess.run(["netsh", "advfirewall", "firewall", "add", "rule", "name=HTTPS Port 443", "dir=in", "action=allow", "protocol=TCP", "localport=443"], check=True)
    except subprocess.CalledProcessError as e:
        write_log(f"ファイアウォール設定に失敗しました: {e}", is_error=True)
        exit_on_error()

def install_win_acme():
    """win-acmeをインストール"""
    if os.path.exists(f"{WIN_ACME_DIR}/wacs.exe"):
        write_log("win-acme がインストール済みです。インストール処理をスキップします。")
        return

    write_log("最新の win-acme バージョンを取得中...")
    win_acme_api_url = "https://api.github.com/repos/win-acme/win-acme/releases/latest"
    
    try:
        response = requests.get(win_acme_api_url)
        response.raise_for_status()
        release_info = response.json()
        download_url = next(asset["browser_download_url"] for asset in release_info["assets"] if asset["name"].endswith(".x64.trimmed.zip"))

        mkdir(WIN_ACME_DIR)
        mkdir(CERT_DIR)
        mkdir(WWW_ROOT)
        mkdir(CHALLENGE_FOLDER)
       
        # ダウンロード処理（PowerShellを使用せず、requestsで処理）
        zip_path = os.path.join(DOWNLOAD_DIR, "win-acme.zip")
        download(download_url, zip_path)
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            for file in zip_ref.namelist():
                zip_ref.extract(file, WIN_ACME_DIR)
                write_log(f"展開中です: {file}...")
        write_log("win-acme のインストールが完了しました。")

    except requests.RequestException as e:
        write_log(f"win-acme の取得に失敗しました: {e}", is_error=True)

def resolve_ini_config(ini_path):
    """ INIファイルから設定を取得 """
    try:
        if not os.path.exists(ini_path):
            write_log(f"{ini_path} が見つかりません。", is_error=True)
            exit_on_error()
        
        config = {}
        with open(ini_path, "r", encoding="utf-8") as file:
            for line in file:
                if "=" in line:
                    key, value = line.strip().split("=", 1)
                    config[key.strip().upper()] = value.strip()
        
        if "DOMAIN" not in config:
            write_log(f"ドメイン名が {ini_path} に正しく設定されていません。", is_error=True)
            exit_on_error()

        if "EMAIL" not in config:
            write_log(f"メールアドレスが {ini_path} に正しく設定されていません。", is_error=True)
            exit_on_error()
    except (FileNotFoundError, ValueError) as e:
        write_log(f"エラー: {str(e)}", is_error=True)
        exit_on_error()

    write_log(f"ドメイン名: {config['DOMAIN']}, メールアドレス: {config['EMAIL']} を読み込みました。")
    return config

def get_ssl_certificate(config):
    """ win-acme を使用して SSL 証明書を発行 """
    write_log("win-acme を実行してSSL証明書を発行しています...")
    
    command = [
       f"{WIN_ACME_DIR}\\wacs.exe",
        "--target", "manual",
        "--host", config["DOMAIN"],
        "--emailaddress", config["EMAIL"],
        "--accepttos",
        "--webroot", WWW_ROOT,
        "--store", "pemFiles",
        "--pemfilespath", CERT_DIR
    ]
    
    # リアルタイムで出力を表示
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding="utf-8", text=True)
    output = ""
    for line in process.stdout:
        print(line, end="")
        output += line
    process.wait()

    with open(log_file, "a", encoding="utf-8") as log:
        log.write(output)
    
    if process.returncode == 0:
        write_log("SSL証明書の発行とインストールに成功しました。")
    else:
        write_log("win-acme によるSSL証明書の発行に失敗しました。", is_error=True)
        exit_on_error()
    
    return config

def install_aspcore():
    """ .NET Core Hosting Bundleのインストール """

    # インストールする.NET Core Hosting BundleのURL
    hosting_bundle_url = "https://download.visualstudio.microsoft.com/download/pr/450a6e4e-e4e3-4ed6-86a2-6a6f840e5a51/3629f0822ccc2ce265cf5e88b5b567cb/dotnet-hosting-9.0.1-win.exe"

    # ダウンロード先のパス
    installer_path = f"{DOWNLOAD_DIR}/dotnet-hosting-installer.exe"

    write_log(".NET Core Hosting Bundle をダウンロードしています...")
    download(hosting_bundle_url, installer_path)

    # サイレントインストールの実行
    write_log(".NET Core Hosting Bundle をインストールしています...")
    process = subprocess.Popen([installer_path, "/quiet"])
    process.wait()

    # インストール確認
    write_log("インストールされた .NET Core ランタイムのバージョンを確認します...")
    process = subprocess.Popen(['C:/Program Files/dotnet/dotnet.exe', "--list-runtimes"])
    process.wait()

def start_fxtf_mt4():
    """ FXTF MT4をインストール/起動 """
    if os.path.exists(FXTF_MT4_PATH):
        write_log("FXTF MT4 がインストール済みです。インストール処理をスキップしてMT4を起動します。")
        # Windowsでプロセスを親プロセスから切り離すためのフラグ
        DETACHED_PROCESS = 0x00000008
        try:
            # creationflagsにDETACHED_PROCESSを指定することで、バックグラウンドで起動
            subprocess.Popen([FXTF_MT4_PATH], creationflags=DETACHED_PROCESS, close_fds=True)
            return
        except Exception as e:
            write_log(f"アプリの起動に失敗しました: {e}", is_error=True)
            exit_on_error()

    # インストーラをダウンロード
    installer_path = f"{DOWNLOAD_DIR}/fxtf4setup.exe"
    download(FXTF_MT4_URL, installer_path)

    # setup.exeを起動し、インストール完了まで待機
    write_log("FXTF MT4 のインストールをしています...")
    subprocess.run([installer_path])
    if os.path.exists(FXTF_MT4_PATH):
        write_log("インストールが正常に完了しました。")
    else:
        write_log("インストールしたFXTF MT4が見つかりません。", is_error=True)
        exit_on_error()
