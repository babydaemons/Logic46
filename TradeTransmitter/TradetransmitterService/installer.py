import os
import sys
import shutil
import subprocess
from util import write_log, exit_on_error
from config import APP_DIR 

def get_current_executable():
    # frozenの場合は sys.executable を、通常のスクリプトの場合は __file__ の絶対パスを返す
    if getattr(sys, 'frozen', False):
        return sys.executable
    else:
        return os.path.abspath(__file__)

def install():
    # 現在の実行ファイルのパスを取得
    src_path = get_current_executable()
    
    # インストール先ディレクトリ（ここでは例としてユーザのAPPDATA配下の"MyApp"フォルダ）
    os.makedirs(APP_DIR, exist_ok=True)
    
    # コピー先のパス。元のファイル名をそのまま使用
    dest_path = os.path.join(APP_DIR, os.path.basename(src_path))
    
    # 既に実行中のファイルとコピー先が異なる場合のみコピーを実施
    if os.path.abspath(src_path) != os.path.abspath(dest_path):
        try:
            write_log(f"インストールしています: {src_path} ⇒ {dest_path}...")
            shutil.copy2(src_path, dest_path)
            ini_src_path = src_path.replace(".exe", ".ini")
            ini_dest_path = dest_path.replace(".exe", ".ini")
            write_log(f"インストールしています: {ini_src_path} ⇒ {ini_dest_path}...")
            shutil.copy2(ini_src_path, ini_dest_path)
        except Exception as e:
            write_log(f"インストールに失敗しました: {e}", is_error=True)
            exit_on_error()
    
    # 新しいプロセスとしてコピー先のプログラムを起動
    try:
        # コマンドライン引数は引き継ぐ（sys.argv[1:]）
        os.chdir(APP_DIR)
        subprocess.Popen([dest_path] + sys.argv[1:], close_fds=True)
    except Exception as e:
        write_log(f"インストールに失敗しました: {e}", is_error=True)
        exit_on_error()
    
    # 現在のプロセスを終了
    sys.exit(0)
