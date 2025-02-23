import os
from datetime import datetime
import sqlite3
from flask import Flask, jsonify, request, Response, send_from_directory, abort
from util import write_log
from config import APP_NAME, APP_DIR, CHALLENGE_FOLDER, DB_PATH

app = Flask(__name__)

def get_timestamp():
    # 現在時刻を取得
    now = datetime.now()
    # 指定のフォーマットで文字列に変換
    return now.strftime("%Y-%m-%dT%H:%M:%S")

def init_db():
    """データベースの初期化"""
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS positions (
                email TEXT NOT NULL,
                account INTEGER NOT NULL,
                position_id TEXT NOT NULL,
                change INTEGER NOT NULL,
                command INTEGER NOT NULL,
                symbol TEXT NOT NULL,
                lots NUMBER NOT NULL,
                create_at TEXT NOT NULL,
                delete_at TEXT NULL
            )
        ''')
        conn.commit()

class PositionRequestModel:
    def __init__(self, change, command, symbol, lots, position_id):
        self.change = change
        self.command = command
        self.symbol = symbol
        self.lots = lots
        self.position_id = position_id

    @staticmethod
    def from_dict(params):
        try:
            return PositionRequestModel(
                change=int(params.get("change")),
                command=int(params.get("command")),
                symbol=str(params.get("symbol")),
                lots=float(params.get("lots")),
                position_id=str(params.get("position_id")),
            )
        except (ValueError, TypeError) as err:
            write_log(">>>>>>>>> 受信したポジションデータが不正です: {params}: {err}", is_error=True)
            return None

def insert_position(email, account, position):
    """データベースにポジションを保存"""
    create_at = get_timestamp()
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            INSERT INTO positions (email, account, change, command, symbol, lots, position_id, create_at, delete_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (email, account, position.change, position.command, position.symbol, position.lots, position.position_id, create_at, None))
        conn.commit()

def get_positions(email, account):
    """ポジションデータを取得"""
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT change, command, symbol, lots, position_id FROM positions WHERE email=? AND account=? AND delete_at IS NULL
        ''', (email, account))
        positions = cursor.fetchall()

    return [
        {"change": p[0], "command": p[1], "symbol": p[2], "lots": p[3], "position_id": p[4]}
        for p in positions
    ]

def delete_positions(email, account, position_ids, delete_at):
    """ポジションデータを削除"""
    if not position_ids:
        return

    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        query = '''
            UPDATE positions SET delete_at=? 
            WHERE email=? AND account=? AND position_id IN ({placeholders})
            AND delete_at IS NULL
        '''.replace('{placeholders}', ','.join(['?'] * len(position_ids)))
        cursor.execute(query, [delete_at, email, account] + position_ids)
        conn.commit()

@app.route('/push', methods=['GET'])
def push():
    params = request.args.to_dict()

    try:
        email = params["email"]
        account = int(params["account"])
        position = PositionRequestModel.from_dict(params)

        if not position:
            return jsonify({"error": "Invalid position data"}), 400

        change = "Entry" if position.change == +1 else "Exit"
        command = "Long" if position.command == +1 else "Short"
        request_str = f"生徒さん[{email}], 口座番号[{account}], 売買[{change}], ポジション[{command}], 通貨ペア[{position.symbol}], 売買ロット[{position.lots}], ポジション識別子[{position.position_id}]"
        write_log(f"▷▷▷▷▷▷ {request_str}")
        insert_position(email, account, position)

        return jsonify({"message": request_str}), 200
    except Exception as ex:
        write_log(f"▷▷▷▷▷▷ {ex}", is_error=True)
        return jsonify({"error": str(ex)}), 500

@app.route('/pop', methods=['GET'])
def pop():
    params = request.args.to_dict()

    try:
        email = params["email"]
        account = int(params["account"])
        positions = get_positions(email, account)

        if not positions:
            return Response(status=204)  # 204 No Content を返す

        delete_at = get_timestamp()
        position_ids = [position["position_id"] for position in positions]
        delete_positions(email, account, position_ids, delete_at)

        # XXX Web APIクライアントがMQL4なのでJSONの導入が困難: CSVを返す
        records = f"{len(positions)}\n"
        for position in positions:
            records += f"{email},{account},{position['change']},{position['command']},{position['symbol']},{position['lots']},{position['position_id']}\n"
            change = "Entry" if position['change'] == +1 else "Exit"
            command = "Long" if position['command'] == +1 else "Short"
            record_message = f"生徒さん[{email}], 口座番号[{account}], 売買[{change}], ポジション[{command}], 通貨ペア[{position.symbol}], 売買ロット[{position.lots}], ポジション識別子[{position.position_id}]"
            write_log(f"◀◀◀◀◀◀ {record_message}")

        return Response(records, mimetype="text/csv; charset=utf-8")  # CSVの mimetype を適用

    except Exception as ex:
        write_log(f"◀◀◀◀◀◀ {ex}", is_error=True)
        return Response(f"Internal Server Error: {ex}", status=500, mimetype="application/json")

@app.route('/.well-known/acme-challenge/<filename>')
def acme_challenge(filename):
    # チャレンジフォルダが存在するか確認
    if not os.path.exists(CHALLENGE_FOLDER):
        abort(404)

    # ファイルが存在する場合、返す
    return send_from_directory(CHALLENGE_FOLDER, filename)