import ctypes, sys

# 特権昇格用のスクリプト
if not ctypes.windll.shell32.IsUserAnAdmin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
    sys.exit()

# メインスクリプト
import os
import shutil
import subprocess
import sys

# 展開先ディレクトリ
extract_path = "C:/KazuyaFX"
if os.path.exists(extract_path):
    shutil.rmtree(extract_path)

# ZIP ファイルのパス
zip_file = os.path.join(sys._MEIPASS, "KazuyaFX.zip")

# ZIP を展開
if not os.path.exists(extract_path):
    import zipfile
    with zipfile.ZipFile(zip_file, "r") as zip_ref:
        zip_ref.extractall(extract_path)

# インストーラー実行
installer_path = os.path.join(extract_path, "KazuyaFX_Installer.exe")
subprocess.run([installer_path], shell=True)