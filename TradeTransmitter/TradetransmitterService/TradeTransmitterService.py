import threading
from app import app, init_db
from init import set_firewall_rules, install_win_acme, get_ssl_certificate
from startup import schedule_reboot
from config import CERT_DIR, DB_PATH
from util import write_log, ini_path

if __name__ == '__main__':
    # ポート開放
    set_firewall_rules()

    # win-acmeインストール
    install_win_acme()

    # 証明書取得: HTTP-01チャレンジ
    config = get_ssl_certificate(ini_path)

    # OS再起動用のスレッドを開始
    threading.Thread(target=schedule_reboot, daemon=True).start()

    # *.sqlte3を作成
    write_log(f"データベースファイル {DB_PATH} を作成します...")
    init_db()

    # HTTPSサーバーを起動
    write_log("HTTPSプロトコルの受け付けを開始します...")
    domain_name = config["DOMAIN"]
    cert_path = f"{CERT_DIR}/{domain_name}-crt.pem"
    key_path = f"{CERT_DIR}/{domain_name}-key.pem"
    app.run(ssl_context=(cert_path, key_path), host="0.0.0.0", port=443)
