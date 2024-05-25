# -*- coding: utf8 -*-

import numpy as np
import sys
import datetime

from config import Config
from common import create_learning_data

class Predict:
    def __init__(self, config: Config):
        self.config = config

    def execute(self, values, macd05m, signal05m, macd01h, signal01h, requests):
        (x, _) = create_learning_data(values, macd05m, signal05m, macd01h, signal01h, self.config)
        y_predict = self.config.model.predict(x)
        predict_value = (y_predict.ravel())[0]

        timestamp = datetime.datetime.fromtimestamp(requests[4])
        timestamp = timestamp.strftime("%Y-%m-%d %H:%M:%S")
        ask = requests[5] / 1000000.0
        sys.stdout.write("\r")
        sys.stdout.flush() 
        sys.stdout.write(f"\033[F\33[37C : {timestamp} : {ask:.5f} : {predict_value:+.9f}\n")
        sys.stdout.flush() 

        return f"DONE,{predict_value}\n"
