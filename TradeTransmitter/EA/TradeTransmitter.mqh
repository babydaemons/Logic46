//+------------------------------------------------------------------+
//|                                             TradeTransmitter.mqh |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#ifdef __MQL5__
    #include "ErrorDescriptionMT5.mqh"
#else
    #include "ErrorDescriptionMT4.mqh"
#endif 

#define API_KEY    "0163655e13d0e8f87d8c50140024bff3fa16510f1b0103aad40a7c7af2fc48934630a60beea6eddb453a903c106f7972e7fbaeb305adcc2b08e8ff4fb8ad8d17"
#define HTTP_ERROR "※※※※※※※※※※※※※※※※※※※※"

bool STOPPED_BY_HTTP_ERROR = false;

//+------------------------------------------------------------------+
//| HTTP GET function                                                |
//+------------------------------------------------------------------+
string Get(string uri, int& res, int retry_max, int retry_interval) {
    char data[];
    char result[];
    string result_headers;
    int retry_count = 0;
    string url_with_key = uri + "&session_id=" + API_KEY;

    while (true) {
        res = WebRequest("GET", url_with_key, NULL, 1000, data, result, result_headers);
        if (res == 200) {
            break;
        }
        if (res == 404 || res == -1) {
            STOPPED_BY_HTTP_ERROR = true;
            return HTTP_ERROR;
        }
        else if (res >= 400) {
            string error_message = StringFormat("HTTP ERROR! [%d] \"%s\" %s", res, Replace(uri, "%40", "@"), ErrorDescription());
            // Alert(error_message);
            printf(error_message);
            if (retry_count < retry_max - 1) {
                Sleep(retry_interval << retry_count);
                ++retry_count;
                continue;
            }
            //string expert_name = GetSourcePath();
            //if (StringFind(expert_name, "Server") != -1) {
            //    MessageBox("エラー: TradeTransmitterClientを終了します", "エラー", MB_OK);
            //    ExpertRemove();
            //}
            //else {
                return "";
            //}
        }
        else if (res > 200) {
            return "";
        }
    }

    int size = ArraySize(result);
    uchar result_data[];
    ArrayResize(result_data, size);
    for (int i = 0; i < size; ++i) {
        result_data[i] = (uchar)result[i];
    }
    string text = CharArrayToString(result_data);
    return text;
}

//+------------------------------------------------------------------+
//| HTTP POST function                                               |
//+------------------------------------------------------------------+
string Post(string uri, string post_string) {
    uchar post_uchars[];
    StringToCharArray(post_string, post_uchars);
    int request_size = ArraySize(post_uchars);

    char data[];
    ArrayResize(data, request_size);
    for (int i = 0; i < request_size; ++i) {
        data[i] = (char)post_uchars[i];
    }
    char result[];
    string result_headers;
    int res = WebRequest("POST", uri, "Content-Type: application/json\r\n", 1000, data, result, result_headers);
    if (res != 200) {
        MessageBox(StringFormat("下記のエラーが発生しました。EAを終了します。\nHTTPレスポンス %d\n%s", res, ErrorDescription()), "エラー", MB_ICONSTOP | MB_OK);
        printf("下記のエラーが発生しました。EAを終了します。HTTPレスポンス:%d \"%s\"", res, ErrorDescription());
        printf(uri);
        printf(post_string);
        ExpertRemove();
    }

    int response_size = ArraySize(result);
    uchar result_data[];
    ArrayResize(result_data, response_size);
    for (int i = 0; i < response_size; ++i) {
        result_data[i] = result[i];
    }
    string text = CharArrayToString(result_data);
    return text;
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
void ExitEA(string url, int res)
{
    string message = StringFormat(
        "エラー[%d]: 下記のいずれかの問題が発生しました。EAを終了します。\n" +
        " (1) 「生徒さん→先生」連携サーバーが起動していません。\n" +
        " (2) 「生徒さん→先生」連携サーバーURLが未設定です。下記の通り設定してください。\n"
        "     ⇒ [ツール(T)] メニュー\n" +
        "        ⇒ [オプション(O)] メニュー\n" +
        "           ⇒ [エキスパートアドバイザー] タブ\n" +
        "              ⇒ WebRequestを許可するURLリスト\n" +
        "                 ⇒ 〈%s〉", res, url);
    MessageBox(message, "エラー", MB_OK);
    ExpertRemove();
}

string Replace(string value, string search, string reolacement)
{
    StringReplace(value, search, reolacement);
    return value;
}