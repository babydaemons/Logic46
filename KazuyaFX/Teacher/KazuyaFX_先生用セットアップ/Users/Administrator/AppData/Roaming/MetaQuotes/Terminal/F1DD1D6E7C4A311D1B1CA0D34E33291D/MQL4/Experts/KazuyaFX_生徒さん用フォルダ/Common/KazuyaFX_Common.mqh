//+------------------------------------------------------------------+
//|                                              KazuyaFX_Common.mqh |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  TRADE_TRANSMITTER_SERVER = "https://qta-kazuyafx.com"; // トレードポジションを受信するサーバー

#include "KazuyaFX_ErrorDescription.mqh"

#define HTTP_ERROR "※※※※※※※※※※※※※※※※※※※※"

const string ERROR_SERVER_NOT_READY =
        "初期化エラー[%d]: 下記のいずれかの問題が発生しました。EAを終了します。\n" +
        " (1) 「生徒さん→先生」連携サーバーが起動していません。先生に確認してください。\n" +
        " (2) 「生徒さん→先生」連携サーバーURLが未設定または誤っていますです。\n" + 
        "      下記の通り設定してください。\n"
        "     ⇒ [ツール(T)] メニュー\n" +
        "        ⇒ [オプション(O)] メニュー\n" +
        "           ⇒ [エキスパートアドバイザー] タブ\n" +
        "              ⇒ WebRequestを許可するURLリスト\n" +
        "                 ⇒ 〈%s〉";

const string ERROR_SERVER_CONNECTION_LOST =
        "通信エラー[%d]: 「生徒さん→先生」連携サーバーが停止しました。EAを終了します。\n" +
        " (1) 「生徒さん→先生」連携サーバーが停止していないか、先生に確認してください。\n" +
        " (2) 「生徒さん→先生」連携サーバーURLが未設定または誤っていますです。\n" + 
        "      下記の通り設定してください。\n"
        "     ⇒ [ツール(T)] メニュー\n" +
        "        ⇒ [オプション(O)] メニュー\n" +
        "           ⇒ [エキスパートアドバイザー] タブ\n" +
        "              ⇒ WebRequestを許可するURLリスト\n" +
        "                 ⇒ 〈%s〉";

const string AUTH_HEADER = "Authorization: Bearer 0163655e13d0e8f87d8c50140024bff3fa16510f1b0103aad40a7c7af2fc48934630a60beea6eddb453a903c106f7972e7fbaeb305adcc2b08e8ff4fb8ad8d17\r\n";

bool STOPPED_BY_HTTP_ERROR = false;

string GetName(string path)
{
    string items[];
    int n = StringSplit(path, '\\', items);
    string name = items[n - 1];
    StringReplace(name, ".mq4", "");
    return name;
}

string GetWebApiUri(string resource) {
    int handle = FileOpen("TRADE_TRANSMITTER_SERVER.txt", FILE_READ | FILE_COMMON);
    if (handle == INVALID_HANDLE) {
        return TRADE_TRANSMITTER_SERVER + resource;
    }
    string server = FileReadString(handle);
    FileClose(handle);
    return server + resource;
}

//+------------------------------------------------------------------+
//| HTTP GET function                                                |
//+------------------------------------------------------------------+
string GetRequest(string uri, int& res, int retry_max, int retry_interval) {
    char data[];
    char result[];
    string result_headers;

    for (int attempt = 0; attempt < retry_max; ++attempt) {
        res = WebRequest("GET", uri, AUTH_HEADER, 1000, data, result, result_headers);
        if (res != -1) break;
        printf("GetLastError(): %d", GetLastError());
        Sleep(retry_interval);
    }

    return CharArrayToString(result);
}

//+------------------------------------------------------------------+
//| HTTP GET function                                                |
//+------------------------------------------------------------------+
string Get(string uri, int& res, int retry_max, int retry_interval) {

    int retry_count = 0;
    string text = "";

    while (true) {
        text = GetRequest(uri, res, retry_max, retry_interval);
        if (res == 200) {
            break;
        }
        if (res == 404 || res == -1) {
            STOPPED_BY_HTTP_ERROR = true;
            return HTTP_ERROR;
        }
        else if (res >= 400) {
            string error_message = StringFormat("HTTP ERROR! [%d] \"%s\" %s", res, Replace(uri, "%40", "@"), ErrorDescription());
            printf(error_message);
            if (retry_count < retry_max - 1) {
                Sleep(retry_interval << retry_count);
                ++retry_count;
                continue;
            }
            return "";
        }
        else if (res > 200) {
            return "";
        }
    }
    return text;
}

//+------------------------------------------------------------------+
//| HTTP POST function                                               |
//+------------------------------------------------------------------+
string PostRequest(string url, string csvLine, int& res, int retry_max, int retry_interval) {
    // --- 送信データを UTF-8 バイト配列へ変換 --------------------------
    uchar body[];
    int len = StringToCharArray(csvLine, body, 0, WHOLE_ARRAY, CP_UTF8);
    --len;
    ArrayResize(body, len);     // NULL終端を除去

    char data[];
    ArrayResize(data, len);
    for (int i = 0; i < len; ++i) {
        data[i] = (char)body[i];
    }

    // HTTPヘッダの設定
    string headers = AUTH_HEADER + "Content-Type: text/csv; charset=utf-8\r\n";

    const int timeout = 1000;
    char   result[];            // 応答ボディ
    string result_headers;      // 応答ヘッダ
    for (int attempt = 0; attempt < retry_max; ++attempt) {
        // --- 呼び出し ------------------------------------------------------
        res = WebRequest("POST",
                url,
                headers,
                timeout,
                data,
                result,
                result_headers);

        // --- 結果確認 ------------------------------------------------------
        if (res != -1) break;
        printf("ERROR: %s", ErrorDescription());
        Sleep(retry_interval);
    }

    // 応答本文を UTF-8 → 文字列へ変換して表示
    string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
    return response;
}

//+------------------------------------------------------------------+
//| HTTP POST function                                               |
//+------------------------------------------------------------------+
string Post(string uri, string jsonData, int& res, int retry_max, int retry_interval) {

    int retry_count = 0;
    string text = "";

    while (true) {
        text = PostRequest(uri, jsonData, res, retry_max, retry_interval);
        if (res == 200) {
            break;
        }
        if (res == 404 || res == -1) {
            STOPPED_BY_HTTP_ERROR = true;
            return HTTP_ERROR;
        }
        else if (res >= 400) {
            string error_message = StringFormat("HTTP ERROR! [%d] \"%s\" %s", res, Replace(uri, "%40", "@"), ErrorDescription());
            printf(error_message);
            if (retry_count < retry_max - 1) {
                Sleep(retry_interval << retry_count);
                ++retry_count;
                continue;
            }
            return "";
        }
        else if (res > 200) {
            return "";
        }
    }
    return text;
}

bool IsServerReady(string endpoint, int& res) {
    string uri = endpoint + "?check=1";
    string status = Get(uri, res, 1, 1000);
    return status == "ready";
}

//+------------------------------------------------------------------+
//| URLエンコード関数                                                 |
//+------------------------------------------------------------------+
string UrlEncode(const string str) {
    string encoded = "";
    uchar uchars[];
    StringToCharArray(str, uchars);
    for (int i = 0; i < ArraySize(uchars) - 1; i++) {
        char c = (char)uchars[i];
        if ((c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c == '-' || c == '_' || c == '.' || c == '~') {
            encoded = StringFormat("%s%c", encoded, c);
        } else {
            encoded = StringFormat("%s%%%02X", encoded, c); // パーセントエンコーディング
        }
    }
    return encoded;
}

//+------------------------------------------------------------------+
//| Base64エンコード関数                                              |
//+------------------------------------------------------------------+
string Base64Encode(const string data) {
    const string base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    string encoded = "";
    int i = 0;
    int pos = 0;
    uchar char_array_3[3] = {};
    uchar char_array_4[4] = {};

    int dataSize = StringLen(data);
    while (dataSize-- >= 0) {
        char_array_3[i++] = (uchar)data[pos++];
        if (i == 3) {
            char_array_4[0] = (uchar)((char_array_3[0] & 0xfc) >> 2);
            char_array_4[1] = (uchar)(((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4));
            char_array_4[2] = (uchar)(((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6));
            char_array_4[3] = (uchar)(char_array_3[2] & 0x3f);

            for (i = 0; i < 4; i++) {
               encoded = StringFormat("%s%c", encoded, base64_chars[char_array_4[i]]);
            }
            i = 0;
        }
    }

    if (i > 0) {
        for (int j = i; j < 3; j++)
            char_array_3[j] = '\0';

        char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
        char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
        char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
        char_array_4[3] = char_array_3[2] & 0x3f;

        for (int j = 0; j < i + 1; j++) {
            encoded = StringFormat("%s%c", encoded, base64_chars[char_array_4[j]]);
        }

        while (i++ < 3) {
            encoded += "=";
        }
    }

    return encoded;
}

//+------------------------------------------------------------------+
//| EA終了関数                                                      |
//+------------------------------------------------------------------+
void ExitEA(string url, string message_format, int res)
{
/*
    string message = StringFormat(message_format, res, url);
    MessageBox(message, "エラー", MB_OK);
    ExpertRemove();
*/
}

//+------------------------------------------------------------------+
//| 文字列置換関数                                                    |
//+------------------------------------------------------------------+
string Replace(string value, string search, string replacement)
{
    StringReplace(value, search, replacement);
    return value;
}

//+------------------------------------------------------------------+
//| 文字列置換関数                                                    |
//+------------------------------------------------------------------+
string RemoveQuote(string value)
{
    StringReplace(value, "\"", "");
    return value;
}
