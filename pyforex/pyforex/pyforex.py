#!/usr/bin/env python
# -*- coding: utf8 -*-

import numpy as np

import os
import sys
import struct
from datetime import datetime

import pyforex_library.learning

COMMON_FOLDER_PATH = f"{sys.argv[1]}/Files/pyforex"
LEARNING_DATA_PATH = f"{COMMON_FOLDER_PATH}/learning_data.bin"
PREDICT_DATA_PATH = f"{COMMON_FOLDER_PATH}/predict_data.bin"
PREDICT_RESULT_PATH = f"{COMMON_FOLDER_PATH}/predict_result.bin"

##############################################################################################

def load_values(path: str, fmt: str):
    with open(path, "rb") as f:
        byte_image = f.read()
        array_size = str(len(byte_image) // 8)
        values = np.array(struct.unpack(array_size + fmt, byte_image))
    return values

while True:
    if os.path.exists(LEARNING_DATA_PATH):
        values = load_values(LEARNING_DATA_PATH, 'd')
        model = pyforex_library.learning.learning(values)
        os.remove(LEARNING_DATA_PATH)

    if os.path.exists(PREDICT_DATA_PATH):
        values = load_values(PREDICT_DATA_PATH, 'd')
        predict_value = pyforex_library.learning.predict(values)
        os.remove(PREDICT_DATA_PATH)
        with open(PREDICT_RESULT_PATH, "wt") as f:
            f.write(f"{predict_value}")
