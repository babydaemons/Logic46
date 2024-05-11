import sys

import numpy as np

from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers import Dense, Input
from keras.regularizers import l2
from tensorflow.keras.callbacks import EarlyStopping

##############################################################################################

HOUR_MINUTES = 1
DAY_MINUTES = 24 * HOUR_MINUTES
PREDICT_MINUTES = 4 * HOUR_MINUTES

column_range_hours = range(1, 5 * DAY_MINUTES + 1, HOUR_MINUTES)
column_range_days = range(1, 3 * 24 * DAY_MINUTES + 1, DAY_MINUTES)
column_count = len(column_range_hours) + len(column_range_days)
ROW_COUNT = 250 * DAY_MINUTES

##############################################################################################

def load(model_path):
    model = Sequential()
    model.load(model_path)
    return model

def learning(values, model_path):
    print("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 価格の変化率を算出中です ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝")
    (price_change, predict) = create_price_change_data(values)
    print("⇒  完了")

    print("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 価格の変化の傾きを算出中です ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝")
    inlines = create_incline_data(values, values.shape[0])
    print("⇒  完了")

    print("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 価格予測のモデルを学習中です ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝")
    rows = min(price_change.shape[0], inlines.shape[0])
    price_change = reshape_matrix(price_change, rows)
    inlines = reshape_matrix(inlines, rows)
    X = np.hstack((price_change, inlines))

    ##############################################################################################

    X_ROWS = len(predict.ravel())
    X = X[:X_ROWS, :]

    ##############################################################################################

    y = predict

    ##############################################################################################

    # 訓練データとテストデータに分割
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    ##############################################################################################

    # モデルの構築
    N = X.shape[1]
    model = Sequential()

    # 入力の形状を指定するInputレイヤーを追加
    model.add(Input(shape=(N,)))

    # L2正則化を導入する例
    #model.add(LSTM(units=N>>0, input_shape=[input_dimension], kernel_regularizer=l2(0.01)))
    model.add(Dense(units=N>>0, activation='relu', kernel_regularizer=l2(0.01)))
    model.add(Dense(units=N>>1, activation='relu'))
    model.add(Dense(units=N>>2, activation='relu'))
    model.add(Dense(units=N>>3, activation='relu'))
    #model.add(Dense(units=N>>4, activation='relu'))
    #model.add(Dense(units=N>>5, activation='relu'))
    #model.add(Dense(units=N>>6, activation='relu'))
    #model.add(Dense(units=N>>7, activation='relu'))
    #model.add(Dense(units=N>>8, activation='relu'))
    #model.add(Dense(units=N>>9, activation='relu'))
    #model.add(Dense(units=N>>10, activation='relu'))
    model.add(Dense(units=1, activation='linear'))  # 出力層の活性化関数はlinear

    ##############################################################################################

    # モデルのコンパイル
    model.compile(optimizer='adam', loss='mean_squared_error')  # 平均二乗誤差を損失関数として使用

    ##############################################################################################

    # Early Stoppingコールバックの設定
    early_stopping = EarlyStopping(monitor='val_loss', patience=3, restore_best_weights=True)

    ##############################################################################################

    # モデルの学習
    model.fit(X_train, y_train, epochs=100, batch_size=32, validation_data=(X_test, y_test), callbacks=[early_stopping])
    #model.fit(X_train, y_train, epochs=100, batch_size=32, validation_data=(X_test, y_test))
    print("⇒  完了")

    print("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 価格予測のモデルを検算中です ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝")
    # モデルを保存
    model.save(model_path)

    ##############################################################################################

    # 学習済みモデルを使って再構築
    y_predict = model.predict(X)
    # 再構築誤差の計算
    error = y.ravel() - y_predict.ravel()

    ##############################################################################################

    # 教師データのノルム
    y_norm = np.mean(np.square(y)) ** 0.5

    # 再構築誤差のノルム
    error_norm = np.mean(np.square(error)) ** 0.5

    # 再構築誤差の計算
    reconstruction_error = error_norm / y_norm

    ##############################################################################################

    y = y.ravel()
    y_predict = y_predict.ravel()

    def cosine_similarity(vector1, vector2):
        dot_product = np.dot(vector1, vector2)
        norm_vector1 = np.linalg.norm(vector1)
        norm_vector2 = np.linalg.norm(vector2)
        similarity = dot_product / (norm_vector1 * norm_vector2)
        return similarity

    print(f"Reconstruction Error: {reconstruction_error}, Mean: {np.mean(error)}, Similarity: {cosine_similarity(y, y_predict)}") 
    print("⇒  完了")
    print("＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝ 価格予測を開始します ＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝")
    return model

##############################################################################################

def reshape_matrix(matrix, rows):
    cols = matrix.shape[1]
    vector = matrix.ravel()
    matrix = vector[:(rows*cols)].reshape(rows, cols)
    return matrix
    
##############################################################################################

def get_price_change(values, column_range, span):
    row_count = len(values)
    vector = ((values[:-span] - values[span:]) / values[:-span]) * 100.0 * 60.0 / span
    shape = (row_count, len(column_range))
    strides = (vector.strides[0], vector.strides[0])
    matrix = np.lib.stride_tricks.as_strided(vector, shape=shape, strides=strides)
    return matrix

def create_price_change_data(values):
    price_change_hours = get_price_change(values, column_range_hours, HOUR_MINUTES)
    price_change_days = get_price_change(values, column_range_days, DAY_MINUTES)

    predict = ((values[:-PREDICT_MINUTES] - values[PREDICT_MINUTES:]) / values[:-PREDICT_MINUTES]) * 100.0
    rows = min(price_change_hours.shape[0], price_change_days.shape[0], len(predict))
    predict = predict.ravel()
    predict = predict[:rows].reshape(rows, 1)

    price_change_hours = reshape_matrix(price_change_hours, rows)
    price_change_days = reshape_matrix(price_change_days, rows)

    price_change = np.hstack((price_change_hours, price_change_days))
                             
    return (price_change, predict)

##############################################################################################

def get_incline_data(y, n):
    x = np.array(list(range(n)))
    y = y.T
    # データを行列に変換し、バイアス（切片）を追加する
    X = np.vstack([x, np.ones(len(x))]).T
    # 最小二乗法を使用して直線の係数を計算する
    #print(f"y = {y.shape}")
    #print(f"n = {n}")
    #print(f"X = {X.shape}")
    m, _ = np.linalg.lstsq(X, y, rcond=None)[0]
    return m

def create_incline_data(values, rows):
    N1 = len(column_range_hours)
    N2 = len(column_range_days)

    M0 = 0
    M1 = M0 + N1
    M2 = M1 + N2
    row_count = len(values)
    inlines = np.empty((row_count, M2 + 1))
    
    for i in range(rows):
        # get_volume_change_value関数をベクトル化して、一度に複数のデータポイントを処理する
        hour_indices = np.arange(column_range_hours[0], column_range_hours[N1 - 1] + 1, HOUR_MINUTES)
        day_indices = np.arange(column_range_days[0], column_range_days[N2 - 1] + 1, DAY_MINUTES)
        
        hour_prices = values[hour_indices]
        day_prices = values[day_indices]

        incline_hours = get_incline_data(hour_prices, N1)
        incline_days = get_incline_data(day_prices, N2)

        inlines[i, M0:M1] = incline_hours
        inlines[i, M1:M2] = incline_days

    return inlines

def predict(model, x_values):
    (price_change, _) = create_price_change_data(x_values)

    inlines = create_incline_data(x_values, x_values.shape[0])

    price_change = reshape_matrix(price_change, 1)
    inlines = reshape_matrix(inlines, 1)

    X = np.hstack((price_change, inlines))
    y_predict = model.predict(X)

    return (y_predict.ravel())[0]
