import os
from sys import exit
import logging
import shutil
from datetime import datetime
import requests
from colorama import Fore, Style, init
from config import APP_NAME, APP_DIR, LOG_DIR, DOWNLOAD_DIR

os.makedirs(APP_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)
os.makedirs(DOWNLOAD_DIR, exist_ok=True)

# 現在時刻を取得
now = datetime.now()
# 指定のフォーマットで文字列に変換
formatted_time = now.strftime("%Y%m%d-%H%M%S")
log_file = f"{APP_DIR}/log/{APP_NAME}-{formatted_time}.log"
ini_path = f"{APP_DIR}/{APP_NAME}.ini"


# Coloramaの初期化
init()

# ログフォーマット設定
LOG_FORMAT_FILE = "[%(asctime)s] %(filename)s(%(lineno)d): %(funcName)s(): [%(levelname)s]: %(message)s"

# ロガーの設定
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# ファイル出力用のハンドラ（詳細なログ、色なし）
file_handler = logging.FileHandler(log_file, encoding="utf-8")
file_handler.setLevel(logging.INFO)
file_handler.setFormatter(logging.Formatter(LOG_FORMAT_FILE))

# ハンドラをロガーに追加
logger.addHandler(file_handler)

def write_log(message, is_error=False):
    """ タイムスタンプ付きのログ出力（コンソールは色付き、ファイルは色なし）"""
    formatted_time = now.strftime("%Y-%m-%d %H:%M:%S")
    console_message = f"[{formatted_time}] {message}"
    if is_error:
        logger.error(message, stacklevel=2)  # 呼び出し元のファイル・行番号を取得
        print(Fore.RED + console_message + Style.RESET_ALL)  # コンソールは赤色
    else:
        logger.info(message, stacklevel=2)  # 呼び出し元のファイル・行番号を取得
        print(Fore.GREEN + console_message + Style.RESET_ALL)  # コンソールは緑色

def download(uri, path):
    try:
        write_log(f"ダウンロード中({uri} ⇒ {path})...")
        with requests.get(uri, stream=True) as r:
            r.raise_for_status()
            with open(path, "wb") as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
    except Exception as err:
        write_log("ダウンロードに失敗しました。", is_error=True)
        exit_on_error()
    write_log("ダウンロードが完了しました。")

def exit_on_error():
    write_log("※プログラムを終了します。続行するには[Enter]を押してください...", is_error=True)
    exit(-1)

def mkdir(dir):
    shutil.rmtree(dir, ignore_errors=True)
    os.makedirs(dir, exist_ok=True)
