# -*- coding: utf8 -*-
import os

DEBUGGING = False

class Config:
    def __init__(self, common_directory, pipe_name, predict_minutes, bar_count):
        self.common_directory = common_directory.replace("\\", "/")
        self.pipe_name = pipe_name
        self.model_path = f"{self.common_directory}/Files/pyforex/pyforex-model.keras"
        if DEBUGGING: print(self.model_path)
        self.response_file_path = f"{self.common_directory}/Files/pyforex/response_data.txt"
        if DEBUGGING: print(self.response_file_path)
        self.predict_minutes = predict_minutes
        self.bar_count = bar_count
        self.model = None

    def clear_model(self):
        self.model = None
        if os.path.exists(self.response_file_path):
            os.remove(self.response_file_path)

    def save_model(self, model):
        self.model = model
        with open(self.response_file_path, "w") as f:
            f.write("DONE")
