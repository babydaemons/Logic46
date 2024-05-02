#!/usr/bin/env python
# -*- coding: utf8 -*-

import numpy as np

import os
import sys
import struct

import pyforex_library.learning

COMMON_FOLDER_PATH = f"{sys.argv[1]}/Files/pyforex"
MODEL_DATA_PATH = f"{COMMON_FOLDER_PATH}/model_data.keras"
LEARNING_DATA_PATH = f"{COMMON_FOLDER_PATH}/learning_data.bin"
PREDICT_DATA_PATH = f"{COMMON_FOLDER_PATH}/predict_data.bin"
PREDICT_RESULT_PATH = f"{COMMON_FOLDER_PATH}/predict_result.txt"

##############################################################################################

def load_values(path: str, fmt: str):
    while True:
        try:
            with open(path, "rb") as f:
                byte_image = f.read()
                array_size = str(len(byte_image) // 8)
                values = np.array(struct.unpack(array_size + fmt, byte_image))
            return values
        except Exception:
            pass

model = None
if os.path.exists(MODEL_DATA_PATH):
    model = pyforex_library.learning.load(MODEL_DATA_PATH)

while True:
    if os.path.exists(LEARNING_DATA_PATH):
        values = load_values(LEARNING_DATA_PATH, 'd')
        model = pyforex_library.learning.learning(values, MODEL_DATA_PATH)
        os.remove(LEARNING_DATA_PATH)

    if os.path.exists(PREDICT_DATA_PATH):
        values = load_values(PREDICT_DATA_PATH, 'd')
        predict_value = pyforex_library.learning.predict(model, values)
        os.remove(PREDICT_DATA_PATH)

        while True:
            try:
                with open(PREDICT_RESULT_PATH, "wt") as f:
                    f.write(f"{predict_value}")
                    break 
            except Exception:
                pass

