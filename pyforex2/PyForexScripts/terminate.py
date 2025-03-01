# -*- coding: utf8 -*-

import sys
from common import BEGIN1, END
from config import Config

class Terminate:
    def __init__(self, config: Config):
        self.config = config

    def execute(self, values, macd05m, signal05m, macd01h, signal01h, _):
        print(f"{BEGIN1}⇒  完了{END}")
        sys.exit(len(values))
