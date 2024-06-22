# -*- coding: utf8 -*-

import struct
import numpy as np

PRICE_05M = 0
PRICE_15M = 1
PRICE_01H = 2
PRICE_04H = 3
MACD_05M = 4
SIGNAL_05M = 5
MACD_15M = 6
SIGNAL_15M = 7
MACD_01H = 8
SIGNAL_01H = 9
MACD_04H = 10
SIGNAL_04H = 11
MAX_VALUE_TYPE = 12

ESC = chr(27)
BEGIN1 = f"{ESC}[31m{ESC}[1m"
BEGIN2 = f"{ESC}[44m{ESC}[1m"
END = f"{ESC}[0m"

DEBUGGING = False

MINUTE_BARS = 1
HOUR_BARS = 12 * MINUTE_BARS
DAY_BARS = 24 * HOUR_BARS

VERBOSE = False

def load_values(contents: bytes):
    array_size = str(len(contents) // 8)
    raw_values = np.array(struct.unpack(array_size + 'd', contents))
    N = len(raw_values) // MAX_VALUE_TYPE
    values = list(range(MAX_VALUE_TYPE))
    for i in range(MAX_VALUE_TYPE):
        n0 = i * N
        n1 = (i + 1) * N
        values[i] = raw_values[n0:n1]
    return values

def create_learning_data(contents, predict_columns:int, columns:int):
    values = load_values(contents)
    if VERBOSE: print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格の変化率を算出中です ━━━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")
    (price_change, y) = create_price_change_data(values, predict_columns, columns)
    if DEBUGGING: print(f"price_change = {price_change.shape}")
    if DEBUGGING: print(f"y = {y.shape}")
    if VERBOSE: print(f"{BEGIN1}⇒  完了{END}")

    if VERBOSE: print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格の変化の傾きを算出中です ━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")
    inclines_bars = 12
    inclines = create_incline_data(values, inclines_bars)
    if DEBUGGING: print(f"inclines = {inclines.shape}")
    if VERBOSE: print(f"{BEGIN1}⇒  完了{END}")

    macd = get_macd_data(values, columns)
    if DEBUGGING: print(f"macd = {macd.shape}")
    if VERBOSE: print(f"{BEGIN1}⇒  完了{END}")

    rows = len(y.ravel())
    price_change = price_change[:rows,:]
    inclines = inclines[:rows,:]
    macd = macd[:rows,:]
    x = np.hstack((price_change, inclines, macd))
    return x, y

def create_price_change_data(values, predict_columns:int, columns:int):
    price_change = list(range(MACD_05M))
    for i in range(MACD_05M):
        price_change[i] = get_price_change(values[i], columns, 5)

    # 価格の配列はMT4/MT5と同様に添字が大きいほうが過去の時間足になる
    prices = (values[PRICE_05M]).ravel()
    prices = prices[:-predict_columns]
    predict = ((prices[predict_columns:] - prices[:-predict_columns]) / prices[:-predict_columns]) * 100.0
    rows = len(predict)
    for i in range(MACD_05M):
        rows = min(rows, price_change[i].shape[0])
    predict = predict[:rows]

    for i in range(MACD_05M):
        price_change[i] = price_change[i][:rows,:]
    price_change = np.hstack((price_change[PRICE_05M], price_change[PRICE_15M], price_change[PRICE_01H], price_change[PRICE_04H]))
    return (price_change, predict)

def get_price_change(values, columns, window_size):
    # 価格の配列はMT4/MT5と同様に添字が大きいほうが過去の時間足になる
    prices = values[:-window_size]
    price_change = ((prices[window_size:] - prices[:-window_size]) / prices[:-window_size]) * 100.0
    if DEBUGGING: print(f"vector = {price_change.shape}")
    if DEBUGGING: print(f"vector = {price_change}")
    return stride_vectors(price_change, columns)

def create_incline_data(values, incline_bars):
    incline = list(range(MACD_05M))
    for i in range(MACD_05M):
        incline[i] = get_incline_data(values[i], incline_bars)

    rows = incline[PRICE_05M].shape[0]
    for i in range(MACD_05M):
        rows = min(rows, incline[i].shape[0])

    incline = np.hstack((incline[PRICE_05M], incline[PRICE_15M], incline[PRICE_01H], incline[PRICE_04H]))
    return incline

def get_incline_data(values, window_size):
    vector = values.ravel()
    if DEBUGGING: print(f"vector = {vector.shape}")

    # 各ベクトルを作成
    y_vectors = np.array([
        values[i:i + window_size]
        for i in range(len(values) - window_size)
    ])
    if DEBUGGING: print(f"y_vectors = {y_vectors.shape}")

    x = np.array([range(window_size)])
    if DEBUGGING: print(f"x = {x}")

    # x ベクトルの長さを取得
    n = len(x.ravel())

    # 各種合計を計算
    sum_x = np.sum(x)
    if DEBUGGING: print(f"sum_x = {sum_x}")
    sum_xx = np.sum(x * x)
    if DEBUGGING: print(f"sum_xx = {sum_xx}")

    # N個のyベクトルに対して最小二乗法の傾きを計算
    sum_y = np.sum(y_vectors, axis=1)
    sum_xy = np.sum(y_vectors * x, axis=1)

    # 傾きの計算
    numerator = n * sum_xy - sum_x * sum_y
    denominator = n * sum_xx - sum_x * sum_x
    m = numerator / denominator
    if DEBUGGING: print(f"m = {m.shape}")
    return stride_vectors(m, window_size)

def stride_vectors(vector, window_size):
    if DEBUGGING: print(f"vector = {vector.shape}")
    if DEBUGGING: print(f"vector = {vector}")
    shape = (len(vector) - window_size + 1, window_size)
    if shape[0] < 0:
        print("ERROR")
    if DEBUGGING: print(f"shape = {shape}")
    strides = (vector.strides[0], vector.strides[0])
    matrix = np.lib.stride_tricks.as_strided(vector, shape=shape, strides=strides)
    if DEBUGGING: print(f"matrix = {matrix.shape}")
    return matrix

def get_macd_data(values, columns:int):
    for i in range(MACD_05M):
        values[MACD_05M + 2 * i] = values[MACD_05M + 2 * i] / values[i] * 100.0
        values[SIGNAL_05M + 2 * i] = values[SIGNAL_05M + 2 * i] / values[i] * 100.0

    for i in range(MACD_05M, MAX_VALUE_TYPE):
        values[i] = stride_vectors(values[i], columns)

    rows = values[MACD_05M].shape[0]
    for i in range(MACD_05M, MAX_VALUE_TYPE):
        rows = min(rows, values[i].shape[0])

    macd = np.hstack((values[MACD_05M], values[SIGNAL_05M], values[MACD_15M], values[SIGNAL_15M], values[MACD_01H], values[MACD_01H], values[MACD_04H], values[MACD_04H]))
    return macd
