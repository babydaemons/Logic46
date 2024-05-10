#!/usr/bin/env python
# -*- coding: utf8 -*-

import numpy as np

import sys
import struct
import threading

import win32pipe
import win32file

import pyforex_library.learning

COMMON_FOLDER_PATH = sys.argv[1]
PIPE_NAME = f"pyforex_{sys.argv[2]}"
MODEL_DATA_PATH = f"{COMMON_FOLDER_PATH}\\Files\\pyforex\\model_data.keras"
RESPONSE_DATA_PATH = f"{COMMON_FOLDER_PATH}\\Files\\pyforex\\response_data.txt"

##############################################################################################

def load_values(byte_image: bytes, fmt: str):
    array_size = str(len(byte_image) // 8)
    values = np.array(struct.unpack(array_size + fmt, byte_image))
    return values

##############################################################################################

# 名前付きパイプの作成
pipe_path = f"\\\\.\\pipe\\{PIPE_NAME}"
pipe = win32pipe.CreateNamedPipe(
    pipe_path,
    win32pipe.PIPE_ACCESS_DUPLEX,
    win32pipe. PIPE_TYPE_BYTE | win32pipe.PIPE_READMODE_BYTE | win32pipe.PIPE_WAIT,
    1, 1, 1024 * 1024, 0, None)

# 機械学習のモデル
model = None

# バッファの準備
bytes_image = b''
line = ""

# クライアントの接続を待つ
win32pipe.ConnectNamedPipe(pipe, None)

# Create a lock for controlling access to the named pipe
pipe_lock = threading.Lock()

# 無限ループ
while True:
    # パイプから1文字読み取る
    _, byte = win32file.ReadFile(pipe, 1)

    # バッファに追加
    bytes_image += byte
    print(bytes_image.decode('utf-8').replace("\r", "").replace("\n", ""))
   
    # 改行文字を読んだら
    if byte == b'\n':
        # 文字列へ変換
        requests = bytes_image.decode('utf-8').replace("\r", "").replace("\n", "")

        print(requests)

        requests = requests.split(',')
        request = requests[0]
        length = int(requests[1])

        # パイプから全ての文字を読み取る
        _, bytes_image = win32file.ReadFile(pipe, length)
        values = load_values(bytes_image, 'd')

        if request == "REQUEST_LEARNING":
            model = pyforex_library.learning.learning(values, pipe, MODEL_DATA_PATH)
            win32file.WriteFile(pipe, f"RESPONSE_LEARNING\r\n".encode("utf-8"))

        if request == "REQUEST_PREDICT":
            timestamp = requests[2]
            ask = requests[3]
            predict_value = pyforex_library.learning.predict(model, values, timestamp, ask)
            response = f"DONE,{predict_value}"
            with pipe_lock:
                win32file.WriteFile(pipe, f"RESPONSE_PREDICT,{response}\r\n".encode("utf-8"))
                sys.stdout.write(f"\x1b[F\x1b[35C : {timestamp} : {ask} : {predict_value}\r\n")

    # 次の準備
    bytes_image = b''
    line = ""
