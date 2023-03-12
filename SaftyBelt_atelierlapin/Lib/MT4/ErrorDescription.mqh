//+------------------------------------------------------------------+
//|                                             ErrorDescription.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property strict

//+------------------------------------------------------------------+
//| 現在発生しているエラーのエラーメッセージを返します。             |
//+------------------------------------------------------------------+
string ErrorDescription() {
    return ErrorDescription(GetLastError());
}

//+------------------------------------------------------------------+
//| エラーコードをエラーメッセージに変換します。                     |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code) {
    string error_string;

    switch (error_code) {
    case ERR_NO_ERROR: // 0
        error_string = "エラーはありません。";
        break;
    case ERR_NO_RESULT: // 1
        error_string = "エラーはありません。取引条件(SL/TP)は変更されていません。";
        break;
    case ERR_COMMON_ERROR: // 2
        error_string = "共通エラー";
        break;
    case ERR_INVALID_TRADE_PARAMETERS: // 3
        error_string = "無効なトレード変数";
        break;
    case ERR_SERVER_BUSY: // 4
        error_string = "トレードサーバがビジー状態";
        break;
    case ERR_OLD_VERSION: // 5
        error_string = "クライアント端末が古いバージョン";
        break;
    case ERR_NO_CONNECTION: // 6
        error_string = "トレードサーバと接続できない";
        break;
    case ERR_NOT_ENOUGH_RIGHTS: // 7
        error_string = "権限が無い";
        break;
    case ERR_TOO_FREQUENT_REQUESTS: // 8
        error_string = "要求が多すぎる";
        break;
    case ERR_MALFUNCTIONAL_TRADE: // 9
        error_string = "不適合な関数によってトレードがなされた";
        break;
    case ERR_ACCOUNT_DISABLED: // 64
        error_string = "アカウント無効化";
        break;
    case ERR_INVALID_ACCOUNT: // 65
        error_string = "無効なアカウント";
        break;
    case ERR_TRADE_TIMEOUT: // 128
        error_string = "トレード時間切れ";
        break;
    case ERR_INVALID_PRICE: // 129
        error_string = "無効な価格値";
        break;
    case ERR_INVALID_STOPS: // 130
        error_string = "無効なストップ値";
        break;
    case ERR_INVALID_TRADE_VOLUME: // 131
        error_string = "無効なロット数";
        break;
    case ERR_MARKET_CLOSED: // 132
        error_string = "休場中の可能性があり発注できません。監視・決済中断時刻の設定を確認してください。";
        break;
    case ERR_TRADE_DISABLED: // 133
        error_string = "開設した口座では取引できない通貨ペアが選択されています。";
        break;
    case ERR_NOT_ENOUGH_MONEY: // 134
        error_string = "証拠金が不足しています。";
        break;
    case ERR_PRICE_CHANGED: // 135
        error_string = "価格値変更";
        break;
    case ERR_OFF_QUOTES: // 136
        error_string = "相場価格から離れている";
        break;
    case ERR_BROKER_BUSY: // 137
        error_string = "仲介側がビジー状態";
        break;
    case ERR_REQUOTE: // 138
        error_string = "再見積り";
        break;
    case ERR_ORDER_LOCKED: // 139
        error_string = "注文がロックされた";
        break;
    case ERR_LONG_POSITIONS_ONLY_ALLOWED: // 140
        error_string = "買いポジションだけ有効";
        break;
    case ERR_TOO_MANY_REQUESTS: // 141
        error_string = "要求が多すぎる";
        break;
    case ERR_TRADE_MODIFY_DENIED: // 145
        error_string = "休場中の可能性があり待機注文修正できません。監視・決済中断時刻の設定を確認してください。";
        break;
    case ERR_TRADE_CONTEXT_BUSY: // 146
        error_string = "トレード状況がビジー状態";
        break;
    case ERR_TRADE_EXPIRATION_DENIED: // 147
        error_string = "仲介側の契約が終了している";
        break;
    case ERR_TRADE_TOO_MANY_ORDERS: // 148
        error_string = "オーダー数が仲介側の限度を超えている";
        break;
    case 149:
        error_string = "hedging is prohibited";
        break;
    case 150:
        error_string = "prohibited by FIFO rules";
        break;

    case ERR_NO_MQLERROR: // 4000
        error_string = "エラーなし";
        break;
    case ERR_WRONG_FUNCTION_POINTER: // 4001
        error_string = "不正な関数ポインタ";
        break;
    case ERR_ARRAY_INDEX_OUT_OF_RANGE: // 4002
        error_string = "配列のサイズを超えたインデックス";
        break;
    case ERR_NO_MEMORY_FOR_CALL_STACK: // 4003
        error_string = "関数呼び出しのスタックメモリが無い";
        break;
    case ERR_RECURSIVE_STACK_OVERFLOW: // 4004
        error_string = "再帰的スタックオーバーフロー";
        break;
    case ERR_NOT_ENOUGH_STACK_FOR_PARAM: // 4005
        error_string = "変数のためのスタックメモリが十分ではない";
        break;
    case ERR_NO_MEMORY_FOR_PARAM_STRING: // 4006
        error_string = "文字列変数のメモリが無い";
        break;
    case ERR_NO_MEMORY_FOR_TEMP_STRING: // 4007
        error_string = "一時文字列のメモリが無い";
        break;
    case ERR_NOT_INITIALIZED_STRING: // 4008
        error_string = "初期化されていない文字列";
        break;
    case ERR_NOT_INITIALIZED_ARRAYSTRING: // 4009
        error_string = "配列中の初期化されていない文字列";
        break;
    case ERR_NO_MEMORY_FOR_ARRAYSTRING: // 4010
        error_string = "文字列配列用のメモリが無い";
        break;
    case ERR_TOO_LONG_STRING: // 4011
        error_string = "長すぎる文字列";
        break;
    case ERR_REMAINDER_FROM_ZERO_DIVIDE: // 4012
        error_string = "0で割った余り";
        break;
    case ERR_ZERO_DIVIDE: // 4013
        error_string = "0での除算";
        break;
    case ERR_UNKNOWN_COMMAND: // 4014
        error_string = "未知の命令";
        break;
    case ERR_WRONG_JUMP: // 4015
        error_string = "不正な変化(エラーは生成されていない)";
        break;
    case ERR_NOT_INITIALIZED_ARRAY: // 4016
        error_string = "配列が初期化されていない";
        break;
    case ERR_DLL_CALLS_NOT_ALLOWED: // 4017
        error_string = "DLLの呼び出しが許可されていない";
        break;
    case ERR_CANNOT_LOAD_LIBRARY: // 4018
        error_string = "ライブラリが読み込めない";
        break;
    case ERR_CANNOT_CALL_FUNCTION: // 4019
        error_string = "関数が呼び出せない";
        break;
    case ERR_EXTERNAL_CALLS_NOT_ALLOWED: // 4020
        error_string = "エキスパート関数の呼び出しが許可されていない";
        break;
    case ERR_NO_MEMORY_FOR_RETURNED_STR: // 4021
        error_string = "関数からの返り値である一時文字列用のメモリが不足している";
        break;
    case ERR_SYSTEM_BUSY: // 4022
        error_string = "システムがビジー状態(エラーは生成されていない)]";
        break;
    case 4023:
        error_string = "dll-function call critical error";
        break;
    case 4024:
        error_string = "internal error";
        break;
    case 4025:
        error_string = "out of memory";
        break;
    case 4026:
        error_string = "invalid pointer";
        break;
    case 4027:
        error_string = "too many formatters in the format function";
        break;
    case 4028:
        error_string = "parameters count is more than formatters count";
        break;
    case 4029:
        error_string = "invalid array";
        break;
    case 4030:
        error_string = "no reply from chart";
        break;
    case ERR_INVALID_FUNCTION_PARAMSCNT: // 4050
        error_string = "関数への引数が無効と見なされた";
        break;
    case ERR_INVALID_FUNCTION_PARAMVALUE: // 4051
        error_string = "関数への引数値が無効";
        break;
    case ERR_STRING_FUNCTION_INTERNAL: // 4052
        error_string = "文字列関数の内部エラー";
        break;
    case ERR_SOME_ARRAY_ERROR: // 4053
        error_string = "エラーのある配列がある";
        break;
    case ERR_INCORRECT_SERIESARRAY_USING: // 4054
        error_string = "正しくない系統配列が使われている";
        break;
    case ERR_CUSTOM_INDICATOR_ERROR: // 4055
        error_string = "カスタムインジケータエラー";
        break;
    case ERR_INCOMPATIBLE_ARRAYS: // 4056
        error_string = "配列の相互性がない";
        break;
    case ERR_GLOBAL_VARIABLES_PROCESSING: // 4057
        error_string = "グローバル変数の処理エラー";
        break;
    case ERR_GLOBAL_VARIABLE_NOT_FOUND: // 4058
        error_string = "グローバル変数が見つからない";
        break;
    case ERR_FUNC_NOT_ALLOWED_IN_TESTING: // 4059
        error_string = "テストモードで使えない関数を使った";
        break;
    case ERR_FUNCTION_NOT_CONFIRMED: // 4060
        error_string = "関数が確認できない";
        break;
    case ERR_SEND_MAIL_ERROR: // 4061
        error_string = "メール送信エラー";
        break;
    case ERR_STRING_PARAMETER_EXPECTED: // 4062
        error_string = "文字列変数を要求している";
        break;
    case ERR_INTEGER_PARAMETER_EXPECTED: // 4063
        error_string = "整数変数を要求している";
        break;
    case ERR_DOUBLE_PARAMETER_EXPECTED: // 4064
        error_string = "浮動小数変数を要求している";
        break;
    case ERR_ARRAY_AS_PARAMETER_EXPECTED: // 4065
        error_string = "配列型変数を要求している";
        break;
    case ERR_HISTORY_WILL_UPDATED: // 4066
        error_string = "更新状態から過去データを要求された";
        break;
    case ERR_TRADE_ERROR: // 4067
        error_string = "トレード関数においてエラーが生じた";
        break;
    case 4068:
        error_string = "resource not found";
        break;
    case 4069:
        error_string = "resource not supported";
        break;
    case 4070:
        error_string = "duplicate resource";
        break;
    case 4071:
        error_string = "cannot initialize custom indicator";
        break;
    case 4072:
        error_string = "cannot load custom indicator";
        break;
    case 4073:
        error_string = "no history data";
        break;
    case 4074:
        error_string = "not enough memory for history data";
        break;
    case 4075:
        error_string = "not enough memory for indicator";
        break;
    case ERR_END_OF_FILE: // 4099
        error_string = "ファイルの終端";
        break;
    case ERR_SOME_FILE_ERROR: // 4100
        error_string = "ファイルエラーがある";
        break;
    case ERR_WRONG_FILE_NAME: // 4101
        error_string = "不正なファイル名";
        break;
    case ERR_TOO_MANY_OPENED_FILES: // 4102
        error_string = "ファイルを開きすぎ";
        break;
    case ERR_CANNOT_OPEN_FILE: // 4103
        error_string = "ファイルが開けない";
        break;
    case ERR_INCOMPATIBLE_FILEACCESS: // 4104
        error_string = "ファイルアクセスに相互性がない";
        break;
    case ERR_NO_ORDER_SELECTED: // 4105
        error_string = "注文が選択されていない";
        break;
    case ERR_UNKNOWN_SYMBOL: // 4106
        error_string = "未知の通貨";
        break;
    case ERR_INVALID_PRICE_PARAM: // 4107
        error_string = "不正な価格値";
        break;
    case ERR_INVALID_TICKET: // 4108
        error_string = "不正なチケット";
        break;
    case ERR_TRADE_NOT_ALLOWED: // 4109
        error_string = "自動取引が許可されていません。";
        break;
    case ERR_LONGS_NOT_ALLOWED: // 4110
        error_string = "\"[Expert] - [全般] - [コモン] -[ポジション]\"でロングが許可されていません。";
        break;
    case ERR_SHORTS_NOT_ALLOWED: // 4111
        error_string = "\"[Expert] - [全般] - [コモン] -[ポジション]\"でショートが許可されていません。";
        break;
    case ERR_OBJECT_ALREADY_EXISTS: // 4200
        error_string = "オブジェクトが既に有る";
        break;
    case ERR_UNKNOWN_OBJECT_PROPERTY: // 4201
        error_string = "未知のオブジェクトプロパティ";
        break;
    case ERR_OBJECT_DOES_NOT_EXIST: // 4202
        error_string = "オブジェクトが存在しない";
        break;
    case ERR_UNKNOWN_OBJECT_TYPE: // 4203
        error_string = "未知のオブジェクト型";
        break;
    case ERR_NO_OBJECT_NAME: // 4204
        error_string = "オブジェクト名がない";
        break;
    case ERR_OBJECT_COORDINATES_ERROR: // 4205
        error_string = "オブジェクトの座標エラー";
        break;
    case ERR_NO_SPECIFIED_SUBWINDOW: // 4206
        error_string = "指定されたウィンドウが無い";
        break;
    case ERR_SOME_OBJECT_ERROR: // 4207
        error_string = "オブジェクト関数内でエラーが起きた";
        break;
    case 4210:
        error_string = "unknown chart property";
        break;
    case 4211:
        error_string = "chart not found";
        break;
    case 4212:
        error_string = "chart subwindow not found";
        break;
    case 4213:
        error_string = "chart indicator not found";
        break;
    case 4220:
        error_string = "symbol select error";
        break;
    case 4250:
        error_string = "notification error";
        break;
    case 4251:
        error_string = "notification parameter error";
        break;
    case 4252:
        error_string = "notifications disabled";
        break;
    case 4253:
        error_string = "notification send too frequent";
        break;
    case 4260:
        error_string = "ftp server is not specified";
        break;
    case 4261:
        error_string = "ftp login is not specified";
        break;
    case 4262:
        error_string = "ftp connect failed";
        break;
    case 4263:
        error_string = "ftp connect closed";
        break;
    case 4264:
        error_string = "ftp change path error";
        break;
    case 4265:
        error_string = "ftp file error";
        break;
    case 4266:
        error_string = "ftp error";
        break;
    case 5001:
        error_string = "too many opened files";
        break;
    case 5002:
        error_string = "wrong file name";
        break;
    case 5003:
        error_string = "too long file name";
        break;
    case 5004:
        error_string = "cannot open file";
        break;
    case 5005:
        error_string = "text file buffer allocation error";
        break;
    case 5006:
        error_string = "cannot delete file";
        break;
    case 5007:
        error_string = "invalid file handle (file closed or was not opened)";
        break;
    case 5008:
        error_string = "wrong file handle (handle index is out of handle table)";
        break;
    case 5009:
        error_string = "file must be opened with FILE_WRITE flag";
        break;
    case 5010:
        error_string = "file must be opened with FILE_READ flag";
        break;
    case 5011:
        error_string = "file must be opened with FILE_BIN flag";
        break;
    case 5012:
        error_string = "file must be opened with FILE_TXT flag";
        break;
    case 5013:
        error_string = "file must be opened with FILE_TXT or FILE_CSV flag";
        break;
    case 5014:
        error_string = "file must be opened with FILE_CSV flag";
        break;
    case 5015:
        error_string = "file read error";
        break;
    case 5016:
        error_string = "file write error";
        break;
    case 5017:
        error_string = "string size must be specified for binary file";
        break;
    case 5018:
        error_string = "incompatible file (for string arrays-TXT, for others-BIN)";
        break;
    case 5019:
        error_string = "file is directory, not file";
        break;
    case 5020:
        error_string = "file does not exist";
        break;
    case 5021:
        error_string = "file cannot be rewritten";
        break;
    case 5022:
        error_string = "wrong directory name";
        break;
    case 5023:
        error_string = "directory does not exist";
        break;
    case 5024:
        error_string = "specified file is not directory";
        break;
    case 5025:
        error_string = "cannot delete directory";
        break;
    case 5026:
        error_string = "cannot clean directory";
        break;
    case 5027:
        error_string = "array resize error";
        break;
    case 5028:
        error_string = "string resize error";
        break;
    case 5029:
        error_string = "structure contains strings or dynamic arrays";
        break;
    default:
        error_string = "未知のエラー";
        break;
    }
    return StringFormat("%s(%d)", error_string, error_code);
}
//+------------------------------------------------------------------+
