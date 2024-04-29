#!/usr/bin/env python
# -*- coding: utf8 -*-

import numpy as np

import sys
import struct
from datetime import datetime

import pyforex_library.learning

COMMON_FOLDER_PATH = f"{sys.argv[1]}/Files/pyforex";
DATETIMES_PATH = f"{COMMON_FOLDER_PATH}/datetimes.bin"
CLOSE_PRICES_PATH = f"{COMMON_FOLDER_PATH}/close_prices.bin"

##############################################################################################

def load_values(path: str, fmt: str):
    with open(path, "rb") as f:
        byte_image = f.read()
        array_size = str(len(byte_image) // 8)
        values = np.array(struct.unpack(array_size + fmt, byte_image))
    return values

#datetimes = load_values(DATETIMES_PATH, 'q')
values = load_values(CLOSE_PRICES_PATH, 'd')

##############################################################################################

pyforex_library.learning.learning(values)
