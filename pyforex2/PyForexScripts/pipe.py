# -*- coding: utf8 -*-

import numpy as np

import struct

import win32pipe
import win32file

from common import DEBUGGING

class Pipe:
    def __init__(self, config):
        self.config = config
        self.pipe_handle = None
        self.methods = {}
        # 機械学習のモデル
        self.model = None

    def regist(self, command, method):
        self.methods[command] = method

    def open(self):
        # 名前付きパイプの作成
        pipe_path = f"\\\\.\\pipe\\pyforex_{self.config.pipe_name}"
        if DEBUGGING: print(pipe_path)
        self.pipe_handle = win32pipe.CreateNamedPipe(
            pipe_path,
            win32pipe.PIPE_ACCESS_DUPLEX,
            win32pipe. PIPE_TYPE_BYTE | win32pipe.PIPE_READMODE_BYTE | win32pipe.PIPE_WAIT,
            1, 1, 1024 * 1024, 0, None)
        if DEBUGGING: print(self.pipe_handle)

    def load_values(self, byte_image: bytes):
        array_size = str(len(byte_image) // 8)
        values = np.array(struct.unpack(array_size + 'd', byte_image))
        return values

    def polling(self):
        # バッファの準備
        bytes_image = b''

        # クライアントの接続を待つ
        if DEBUGGING: print(self.pipe_handle)
        win32pipe.ConnectNamedPipe(self.pipe_handle, None)

        # 無限ループ
        while True:
            # パイプから1文字読み取る
            _, byte = win32file.ReadFile(self.pipe_handle, 1)

            # バッファに追加
            bytes_image += byte

            # 改行文字を読んだら
            if byte == b'\n':
                # 文字列へ変換
                request = bytes_image.decode('utf-8').replace("\r", "").replace("\n", "")
                if DEBUGGING: print(request)

                requests = request.split(',')
                command = requests[0]
                price_count = int(requests[1])
                macd05M_count = int(requests[2])
                macd01H_count = int(requests[3])
                count = price_count + macd05M_count + macd05M_count + macd01H_count + macd01H_count

                # パイプから全ての文字を読み取る
                _, bytes_image = win32file.ReadFile(self.pipe_handle, 8 * count)
                buffer = self.load_values(bytes_image)
                offset = 0
                values = buffer[offset:price_count]
                offset += price_count
                macd05M = buffer[offset:(offset + macd05M_count)]
                offset += macd05M_count
                signal05M = buffer[offset:(offset + macd05M_count)]
                offset += macd05M_count
                macd01H = buffer[offset:(offset + macd01H_count)]
                offset += macd01H_count
                signal01H = buffer[offset:(offset + macd01H_count)]
                offset += macd01H_count

                method = self.methods[command]
                result = method(values, macd05M, signal05M, macd01H, signal01H, requests)
                if len(result) > 0:
                    win32file.WriteFile(self.pipe_handle, result.encode('utf-8'))

                # 次の準備
                bytes_image = b''
