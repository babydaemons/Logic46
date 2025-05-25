//+------------------------------------------------------------------+
//|                                           KazuyaFX_TestingEA.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  NAME = "Shingo"; // 生徒さんの名前
input string  SYMBOL_REMOVE_SUFFIX = ""; // ポジションコピー時にシンボル名から削除するサフィックス

#include "KazuyaFX_Common.mqh"

// 口座番号です
ulong SenderAccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);

string ENDPOINT = TRADE_TRANSMITTER_SERVER + "/api/student";
string URL;

datetime StartServerTimeEA;

int Counter = 0;
int Ticket = 0;
int Position = +1;

string Name = "Shingo";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    ENDPOINT = GetWebApiUri("/api/student");
    URL = ENDPOINT + StringFormat("?name=%s", UrlEncode(Name));

    // 15000ミリ秒の周期でポジションコピーを行います
    if (!EventSetMillisecondTimer(15000)) {
        string error_message = "ポジションコピーのインターバルタイマーを設定できませんでした。";
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| シンボル名の変換を行います                                         |
//+------------------------------------------------------------------+
string ConvertSymbol(string symbol_before) {
    string symbol_after = symbol_before;
    StringReplace(symbol_after, SYMBOL_REMOVE_SUFFIX, "");
    return symbol_after;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // タイマーを破棄します
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    if ((++Counter & 0x00000001) == 0x00000001) {
        ++Ticket;
        ExecuteRequest(1, Position, ConvertSymbol(Symbol()), 0.01 * Ticket, Ticket);
    }
    else {
        ExecuteRequest(0, -Position, ConvertSymbol(Symbol()), 0.01 * Ticket, Ticket);
        Position ^= 1;
    }
}

//+------------------------------------------------------------------+
//| ポジションの差分をHTTPリクエストで送信します                        |
//+------------------------------------------------------------------+
void ExecuteRequest(int entry, int buy, string symbol, double lots, int ticket)
{
    string uri = URL;
    uri += StringFormat("&entry=%d", entry);
    uri += StringFormat("&buy=%d", buy);
    uri += StringFormat("&symbol=%s", symbol);
    uri += StringFormat("&lots=%.2f", lots);
    uri += StringFormat("&ticket=%d", ticket);

    int res = 0;
    string response = Get(uri, res, 4, 1000);

    if (STOPPED_BY_HTTP_ERROR || response == HTTP_ERROR) {
        ExitEA(ENDPOINT, res);
        return;
    }

    printf("Order Request Sended: %s", uri);
}
