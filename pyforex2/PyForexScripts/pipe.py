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
            # パイプからリクエスト64ビット整数値を読み取る
            _, bytes_image = win32file.ReadFile(self.pipe_handle, 6 * 8)
            requests = struct.unpack('6Q', bytes_image)

            command = requests[0]
            price_count = int(requests[1])
            macd05m_rows = int(requests[2])
            macd01h_rows = int(requests[3])
            count = price_count + macd05m_rows + macd05m_rows + macd01h_rows + macd01h_rows

            # パイプから全ての文字を読み取る
            _, bytes_image = win32file.ReadFile(self.pipe_handle, 8 * count)
            buffer = self.load_values(bytes_image)
            offset = 0
            values = buffer[offset:price_count]
            offset += price_count
            macd05m = buffer[offset:(offset + macd05m_rows)]
            offset += macd05m_rows
            signal05m = buffer[offset:(offset + macd05m_rows)]
            offset += macd05m_rows
            macd01h = buffer[offset:(offset + macd01h_rows)]
            offset += macd01h_rows
            signal01h = buffer[offset:(offset + macd01h_rows)]
            offset += macd01h_rows

            method = self.methods[command]
            result = method(values, macd05m, signal05m, macd01h, signal01h, requests)
            if len(result) > 0:
                win32file.WriteFile(self.pipe_handle, result.encode('utf-8'))
