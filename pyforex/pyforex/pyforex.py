#!/usr/bin/env python
# -*- coding: utf8 -*-

import numpy as np

import sys
import struct

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

# バッファの準備
bytes_image = b''

# 機械学習のモデル
model = None

# クライアントの接続を待つ
win32pipe.ConnectNamedPipe(pipe, None)

# 無限ループ
while True:
    # パイプから1文字読み取る
    _, byte = win32file.ReadFile(pipe, 1)

    # バッファに追加
    bytes_image += byte
    
    # 改行文字を読んだら
    if byte == b'\n':
        # 文字列へ変換
        request = bytes_image.decode('utf-8').replace("\r", "").replace("\n", "")
        #print(line)

        requests = request.split(',')
        command = requests[0]
        length = int(requests[1])

        # パイプから全ての文字を読み取る
        _, bytes_image = win32file.ReadFile(pipe, length)
        values = load_values(bytes_image, 'd')

        if command == "EXECUTE_LEARNING":
            model = pyforex_library.learning.learning(values, MODEL_DATA_PATH)
            with open(RESPONSE_DATA_PATH, "w") as f:
                f.write("DONE\n")

        if command == "EXECUTE_PREDICT":
            timestamp = requests[2]
            ask = requests[3]
            predict_value = pyforex_library.learning.predict(model, values)
            response = f"DONE,{predict_value}"
            win32file.WriteFile(pipe, f"{response}\r\n".encode("utf-8"))
            sys.stdout.write("\r")
            sys.stdout.flush() 
            sys.stdout.write(f"\033[F\33[37C : {timestamp} : {ask} : {predict_value}\n")
            sys.stdout.flush() 

        # 次の準備
        bytes_image = b''
