import json
import logging
from flask import Flask, jsonify, request, Response, send_from_directory

# HTTP-01 チャレンジのエンドポイント
CHALLENGE_FOLDER = ".well-known/acme-challenge"

# ポジションデータを保持する辞書（キーは "brokerSite/accountNumber"）
PositionList = {}

# ログ設定
logging.basicConfig(level=logging.ERROR)

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello, HTTPS!"

@app.route(f"/{CHALLENGE_FOLDER}/<path:filename>", methods=["GET"])
def serve_challenge(filename):
    return send_from_directory(CHALLENGE_FOLDER, filename)

class PositionRequestModel:
    def __init__(self, command, type_, symbol, lots, position_id):
        self.Command = command
        self.Type = type_
        self.Symbol = symbol
        self.Lots = lots
        self.PositionId = position_id

    @staticmethod
    def from_dict(data):
        return PositionRequestModel(
            command=data.get("Command"),
            type_=data.get("Type"),
            symbol=data.get("Symbol"),
            lots=data.get("Lots"),
            position_id=data.get("PositionId"),
        )

@app.route('/position/<brokerSite>/<accountNumber>', methods=['GET'])
def position(brokerSite, accountNumber):
    trade = request.args.get('trade', '')

    # HEXデコード処理
    json_str = ''
    try:
        for i in range(len(trade) // 2):
            c1 = trade[2 * i]
            c0 = trade[2 * i + 1]
            hex_value = f"{c1}{c0}"
            json_str += chr(int(hex_value, 16))
    except ValueError as ex:
        logging.error(f">>>>>>>>>> HEXデコードエラー: {ex}")
        return jsonify({"error": "Invalid HEX encoding"}), 400

    # JSONデコード
    try:
        position_data = json.loads(json_str)
        position = PositionRequestModel.from_dict(position_data)

        if not position:
            logging.error(">>>>>>>>> trade is null")
            return jsonify({"error": "trade is null"}), 400

        # データをキューに追加
        key = f"{brokerSite}/{accountNumber}"
        if key not in PositionList:
            PositionList[key] = []

        PositionList[key].append(position)

        # リクエストデータを組み立て
        request_str = f"{brokerSite},{accountNumber},{position.Command},{position.Type},{position.Symbol},{position.Lots},{position.PositionId}"

        logging.error(f">>>>>>>>>> {request_str}")
        return jsonify({"message": request_str}), 200

    except json.JSONDecodeError as ex:
        logging.error(f">>>>>>>>>> JSONデコードエラー: {ex}")
        return jsonify({"error": "Invalid JSON format"}), 400
    except Exception as ex:
        logging.error(f">>>>>>>>>> {ex}")
        return jsonify({"error": str(ex)}), 500

@app.route('/execute_polling/<brokerSite>/<accountNumber>', methods=['GET'])
def execute_polling(brokerSite, accountNumber):
    key = f"{brokerSite}/{accountNumber}"
    
    # ポジションデータがある場合
    if key in PositionList:
        position_list = PositionList[key]
        
        records = f"{len(position_list)}\n"  # 最初にポジション数を記録
        new_queue = []  # 残ったデータを保持するためのリスト
        
        while position_list:
            position = position_list.pop(0)  # キューから1つ取り出す
            request_str = f"{brokerSite},{accountNumber},{position.Command},{position.Type},{position.Symbol},{position.Lots},{position.PositionId}"
            logging.error(f"<<<<<<<<<< {request_str}")
            records += f"{request_str}\n"
        
        # PositionList を更新（キューを空にする）
        PositionList[key] = new_queue

        return Response(records, mimetype="text/plain")
    
    return Response("", mimetype="text/plain")


if __name__ == '__main__':
    app.run(debug=True)
