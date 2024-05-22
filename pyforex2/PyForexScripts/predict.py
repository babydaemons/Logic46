# -*- coding: utf8 -*-

import numpy as np
import sys
from config import Config
from common import create_learning_data

class Predict:
    def __init__(self, config: Config):
        self.config = config

    def execute(self, values, requests):
        (x, _) = create_learning_data(values, self.config)
        y_predict = self.config.model.predict(x)
        predict_value = (y_predict.ravel())[0]

        timestamp = requests[2]
        ask = requests[3]
        sys.stdout.write("\r")
        sys.stdout.flush() 
        sys.stdout.write(f"\033[F\33[37C : {timestamp} : {ask} : {predict_value:+.9f}\n")
        sys.stdout.flush() 

        return f"DONE,{predict_value}\n"
