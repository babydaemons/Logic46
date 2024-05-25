# -*- coding: utf8 -*-

import sys
import os
from config import Config
from pipe import Pipe
from learning import Learning
from predict import Predict
from terminate import Terminate

REQUECT_LEARNING = 11111
REQUECT_PREDICT = 22222
REQUECT_TERMINATE = 33333

DEBUGGING = False
if DEBUGGING: print(f"プロセスID: {os.getpid()}")

common_folder_path = sys.argv[1]
pipe_name = sys.argv[2]
predict_minutes = int(sys.argv[3])
bar_count = int(sys.argv[4])

config = Config(common_folder_path, pipe_name, predict_minutes, bar_count)

learning = Learning(config)
predict = Predict(config)
terminate = Terminate(config)

pipe = Pipe(config)
pipe.regist(REQUECT_LEARNING, learning.execute)
pipe.regist(REQUECT_PREDICT, predict.execute)
pipe.regist(REQUECT_TERMINATE, terminate.execute)

pipe.open()
pipe.polling()
