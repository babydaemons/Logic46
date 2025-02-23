import os
import datetime
import ssl
import time
import subprocess
from util import write_log
from config import CERT_DIR, WIN_ACME_DIR

def update_certificate(log_file):
    """
    win-acmeによる証明書更新を行う関数。
    ※ 実行ファイルのパスやオプションは環境に合わせて調整してください。
    """
    wacs_path = f"{WIN_ACME_DIR}\\wacs.exe"  # win-acmeの実行ファイルのパス
    try:
        # 証明書更新コマンドの例。--renewは更新、必要に応じて他のオプションを追加
        result = subprocess.run([wacs_path, "--renew", "--baseuri", "https://acme-v02.api.letsencrypt.org/"],
                                capture_output=True, text=True, check=True)
        write_log(f"証明書更新完了: {result.stdout}")
    except subprocess.CalledProcessError as e:
        write_log(f"証明書更新に失敗しました: {e.stderr}", is_error=True)
        # 必要に応じてエラーハンドリング（例：再試行やログ出力）を実装

def schedule_reboot():
        now = datetime.datetime.now()
        # Pythonでは月曜が0、日曜が6なので、次の日曜までの日数を計算
        days_ahead = (6 - now.weekday()) % 7
        reboot_time = datetime.datetime.combine(now.date() + datetime.timedelta(days=days_ahead), datetime.time(3, 0))
        # もし当日の3:00を過ぎていたら、次週の日曜に設定
        if reboot_time <= now:
            reboot_time += datetime.timedelta(weeks=1)
        time_to_sleep = (reboot_time - now).total_seconds()
        time.sleep(time_to_sleep)
        # OS再起動直前に証明書更新を実行
        update_certificate()
        # OSの再起動（管理者権限が必要）
        write_log("Windowsを再起動します...")
        os.system("shutdown /r /t 0")
