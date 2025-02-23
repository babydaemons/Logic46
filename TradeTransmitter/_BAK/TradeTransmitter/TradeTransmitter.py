import threading
from waitress import serve
from app import app

CERT_PATH = "C:/win-acme/fullchain.pem"
KEY_PATH = "C:/win-acme/privkey.pem"

def run_https():
    serve(app, host="0.0.0.0", port=443, ssl_context=(CERT_PATH, KEY_PATH))

def run_http():
    serve(app, host="0.0.0.0", port=80)

# 2つのスレッドで同時に起動
threading.Thread(target=run_https, daemon=True).start()
threading.Thread(target=run_http, daemon=True).start()

# メインスレッドで停止待機
import time
while True:
    time.sleep(3600)
