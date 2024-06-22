# -*- coding: utf8 -*-

import numpy as np

from common import create_learning_data

model = None

def execute(contents, predict_columns:int, columns:int, model):
    (x, y) = create_learning_data(contents, predict_columns, columns)

    y_predict = model.predict(x)
    predict_value = (y_predict.ravel())[0]

    result = { "PredictValue": str(predict_value) }
    return result
