# -*- coding: utf8 -*-

import numpy as np

ESC = chr(27)
BEGIN1 = f"{ESC}[31m{ESC}[1m"
BEGIN2 = f"{ESC}[44m{ESC}[1m"
END = f"{ESC}[0m"

DEBUGGING = False

MINUTE_BARS = 1
HOUR_BARS = 12 * MINUTE_BARS
DAY_BARS = 24 * HOUR_BARS

VERBOSE = False

def create_learning_data(values, macd5m, signal05m, macd01h, signal01h, config):
    if VERBOSE: print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格の変化率を算出中です ━━━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")
    predict_minutes = config.predict_minutes
    (price_change, y) = create_price_change_data(values, config.bar_count, predict_minutes)
    if DEBUGGING: print(f"price_change = {price_change.shape}")
    if DEBUGGING: print(f"y = {y.shape}")
    if VERBOSE: print(f"{BEGIN1}⇒  完了{END}")

    if VERBOSE: print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格の変化の傾きを算出中です ━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")
    inclines_bars = 12
    inclines = create_incline_data(values, config.bar_count, inclines_bars)
    if DEBUGGING: print(f"inclines = {inclines.shape}")
    if VERBOSE: print(f"{BEGIN1}⇒  完了{END}")

    macd5m_rows = len(macd5m)
    macd1h_rows = len(macd01h)
    bar_count = config.bar_count
    column_range_minutes = range(1, bar_count + 1, MINUTE_BARS)
    column_range_hours = range(1, bar_count + 1, HOUR_BARS)
    macd5m = stride_vectors(macd5m, macd5m_rows, column_range_minutes, MINUTE_BARS)
    signal05m = stride_vectors(signal05m, macd5m_rows, column_range_minutes, MINUTE_BARS)
    macd01h = stride_vectors(macd01h.ravel(), macd1h_rows, column_range_hours, HOUR_BARS)
    signal01h = stride_vectors(signal01h.ravel(), macd1h_rows, column_range_hours, HOUR_BARS)

    rows = min(price_change.shape[0], inclines.shape[0], macd5m.shape[0], signal05m.shape[0], macd01h.shape[0], signal01h.shape[0])
    price_change = reshape_matrix(price_change, rows)
    inclines = reshape_matrix(inclines, rows)
    x = np.hstack((price_change, inclines))
    return x, y

def reshape_matrix(matrix, rows):
    cols = matrix.shape[1]
    vector = matrix.ravel()
    matrix = vector[:(rows*cols)].reshape(rows, cols)
    return matrix

def create_price_change_data(values, bar_count, predict_minutes):
    column_range_minutes = range(1, bar_count + 1, MINUTE_BARS)
    column_range_hours = range(1, bar_count + 1, HOUR_BARS)
    column_range_days = range(1, bar_count + 1, DAY_BARS)

    price_change_minutes = get_price_change(values, column_range_minutes, MINUTE_BARS)
    price_change_hours = get_price_change(values, column_range_hours, HOUR_BARS)
    price_change_days = get_price_change(values, column_range_days, DAY_BARS)

    # 価格の配列はMT4/MT5と同様に添字が大きくなると過去データになる
    predict = ((values[predict_minutes:] - values[:-predict_minutes:]) / values[:-predict_minutes]) * 100.0
    rows = min(price_change_minutes.shape[0], price_change_hours.shape[0], price_change_days.shape[0], len(predict))
    predict = predict.ravel()
    predict = predict[:rows].reshape(rows, 1)

    price_change_minutes = reshape_matrix(price_change_minutes, rows)
    price_change_hours = reshape_matrix(price_change_hours, rows)
    price_change_days = reshape_matrix(price_change_days, rows)
    price_change = np.hstack((price_change_minutes, price_change_hours, price_change_days))
    return (price_change, predict)

def get_price_change(values, column_range, span):
    row_count = len(values)
    vector = ((values[:-span] - values[span:]) / values[:-span]) * 100.0 * 60.0 / span
    if DEBUGGING: print(f"vector = {vector.shape}")
    if DEBUGGING: print(f"vector = {vector}")
    return stride_vectors(vector, row_count, column_range, span)

def create_incline_data(values, bar_count, incline_bars):
    column_range_minutes = range(1, bar_count + 1, MINUTE_BARS)
    column_range_hours = range(1, bar_count + 1, HOUR_BARS)
    column_range_days = range(1, bar_count, DAY_BARS)

    incline_minutes = get_incline_data(values, column_range_minutes, incline_bars)
    if DEBUGGING: print(f"incline_minutes = {incline_minutes.shape}")
    incline_hours = get_incline_data(values, column_range_hours, incline_bars)
    if DEBUGGING: print(f"incline_hours = {incline_hours.shape}")
    incline_days = get_incline_data(values, column_range_days, incline_bars)
    if DEBUGGING: print(f"incline_days = {incline_days.shape}")

    rows = min(incline_minutes.shape[0], incline_hours.shape[0], incline_days.shape[0])
    incline_minutes = reshape_matrix(incline_minutes, rows)
    incline_hours = reshape_matrix(incline_hours, rows)
    incline_days = reshape_matrix(incline_days, rows)
    incline = np.hstack((incline_minutes, incline_hours, incline_days))
    return incline

def get_incline_data(values, column_range, window_size):
    vector = values.ravel()
    if DEBUGGING: print(f"vector = {vector.shape}")

    # 各ベクトルを作成
    y_vectors = np.array([
        vector[i:i + window_size]
        for i in range(len(values) - window_size)
    ])
    if DEBUGGING: print(f"y_vectors = {y_vectors.shape}")

    x = np.array([range(window_size)])
    if DEBUGGING: print(f"x = {x}")

    # x ベクトルの長さを取得
    n = len(x)

    # 各種合計を計算
    sum_x = np.sum(x)
    if DEBUGGING: print(f"sum_x = {sum_x}")
    sum_xx = np.sum(x * x)
    if DEBUGGING: print(f"sum_xx = {sum_xx}")

    # N個の y ベクトルに対して最小二乗法の傾きを計算
    sum_y = np.sum(y_vectors, axis=1)
    sum_xy = np.sum(y_vectors * x, axis=1)

    # 傾きの計算
    numerator = n * sum_xy - sum_x * sum_y
    denominator = n * sum_xx - sum_x * sum_x
    m = numerator / denominator
    if DEBUGGING: print(f"m = {m.shape}")

    row_count = len(values)
    return stride_vectors(m, row_count, column_range, window_size)

def stride_vectors(vector, row_count, column_range, span):
    if DEBUGGING: print(f"vector = {vector.shape}")
    if DEBUGGING: print(f"vector = {vector}")
    if DEBUGGING:print(f"row_count = {row_count}")
    shape = (row_count - (2 * span + 2), len(column_range))
    strides = (vector.strides[0], vector.strides[0])
    matrix = np.lib.stride_tricks.as_strided(vector, shape=shape, strides=strides)
    if DEBUGGING: print(f"matrix = {matrix.shape}")
    return matrix