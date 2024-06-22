# -*- coding: utf8 -*-

import os
import sys
import traceback
from flask import Flask, jsonify, request
from tensorflow.keras.models import load_model
import learning
import predict

DEBUGGING = True
if DEBUGGING: print(f"プロセスID: {os.getpid()}")

if len(sys.argv) < 2:
    print(f"{sys.argv[0]} model_path")
    exit(1)

model_path = sys.argv[1]

app = Flask(__name__)

class PyForex:
    model = None

    @classmethod
    def execute_learning(cls, contents, predict_columns, columns):
        result, cls.model = learning.execute(contents, predict_columns, columns)
        # モデルを保存
        cls.model.save(model_path)
        return result

    @classmethod
    def execute_predict(cls, contents, predict_columns, columns):
        if cls.model == None:
            cls.model = load_model(model_path)
        result = predict.execute(contents, predict_columns, columns, cls.model)
        return result

@app.route("/learning/<int:predict_columns>/<int:columns>", methods=['POST'])
def execute_learning(predict_columns, columns):
    if 'values' not in request.files:
        return jsonify({"error": "No values uploaded."}), 400
    values = request.files['values']
    try:
        contents = values.read()
        result = PyForex.execute_learning(contents, predict_columns, columns)
        return jsonify(result)
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route("/predict/<int:predict_columns>/<int:columns>", methods=['POST'])
def execute_predict(predict_columns, columns):
    if 'values' not in request.files:
        return jsonify({"error": "No values uploaded."}), 400
    values = request.files['values']
    try:
        contents = values.read()
        result = PyForex.execute_predict(contents, predict_columns, columns)
        return jsonify(result)
    except Exception as e:
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@app.route("/terminate", methods=['GET'])
def terminate():
    exit(0)

if __name__ == '__main__':
    app.run()