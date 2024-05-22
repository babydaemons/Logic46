# -*- coding: utf8 -*-

import numpy as np
from sklearn.model_selection import train_test_split
from keras.models import Sequential
from keras.layers import Dense, Input
from keras.regularizers import l2
from tensorflow.keras.callbacks import EarlyStopping
from config import Config
from common import create_learning_data, BEGIN1, BEGIN2, END, DEBUGGING

class Learning:
    def __init__(self, config: Config):
        self.config = config
        if DEBUGGING: print(f"Learning: {self.config}")

    def execute(self, values, _):
        (x, y) = create_learning_data(values, self.config)

        print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格予測のモデルを学習中です ━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")

        ##############################################################################################

        x_row_count = len(y.ravel())
        x = x[:x_row_count, :]
        if DEBUGGING: print(f"x = {x.shape}")
        if DEBUGGING: print(f"y = {y.shape}")

        ##############################################################################################

        # 訓練データとテストデータに分割
        x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2, random_state=42)

        ##############################################################################################

        # モデルの構築
        N = x.shape[1]
        model = Sequential()

        # 入力の形状を指定するInputレイヤーを追加
        model.add(Input(shape=(N,)))

        # L2正則化を導入する例 #model.add(LSTM(units=N>>0, input_shape=[input_dimension], kernel_regularizer=l2(0.01)))
        model.add(Dense(units=N>>0, activation='relu', kernel_regularizer=l2(0.01)))
        model.add(Dense(units=N>>1, activation='relu'))
        model.add(Dense(units=N>>2, activation='relu'))
        model.add(Dense(units=N>>3, activation='relu'))
        model.add(Dense(units=1, activation='linear'))  # 出力層の活性化関数はlinear

        ##############################################################################################

        # モデルのコンパイル
        model.compile(optimizer='adam', loss='mean_squared_error')  # 平均二乗誤差を損失関数として使用

        ##############################################################################################

        # Early Stoppingコールバックの設定
        early_stopping = EarlyStopping(monitor='val_loss', patience=3, restore_best_weights=True)

        ##############################################################################################

        # モデルの学習
        model.fit(x_train, y_train, epochs=100, batch_size=32, validation_data=(x_test, y_test), callbacks=[early_stopping])
        #model.fit(x_train, y_train, epochs=100, batch_size=32, validation_data=(x_test, y_test))
        print(f"{BEGIN1}⇒  完了{END}")

        print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格予測のモデルを検算中です ━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")
        # モデルを保存
        model.save(self.config.model_path)
        self.config.save_model(model)

        ##############################################################################################

        # 学習済みモデルを使って再構築
        y_predict = model.predict(x)
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

        print(f"再構築誤差: {reconstruction_error}, 誤差平均: {np.mean(error)}, 類似度: {cosine_similarity(y, y_predict)}") 
        print(f"{BEGIN1}⇒  完了{END}")
        print(f"{BEGIN2}━━━━━━━━━━━━━━━━━━━━━━━━━━ 価格予測を開始します ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{END}")

        return ""