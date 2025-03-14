//+------------------------------------------------------------------+
//|                                       TradeTransmitterClient.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  EMAIL = "babydaemons@gmail.com"; // メールアドレス
input string  TRADE_TRANSMITTER_SERVER = "https://babydaemons.jp"; // トレードポジションを受信するサーバー
input string  SYMBOL_REMOVE_SUFFIX = "-cd"; // ポジションコピー時にシンボル名から削除するサフィックス

string GetSourcePath()
{
    return __FILE__;
}

#include "TradeTransmitter.mqh"

// 送信元証券会社のIDです
ulong ClientBrokerID = 0;

// 口座番号です
ulong SenderAccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);

string ENDPOINT = TRADE_TRANSMITTER_SERVER + "/push";
string URL;

datetime StartServerTimeEA;

int Counter = 0;
int Ticket = 0;
int Position = +1;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    URL = StringFormat("%s?email=%s&account=%d", ENDPOINT, UrlEncode(EMAIL), SenderAccountNumber);

    int shift_bytes = 3; // 32bitの整数値を作る: 0オリジンで0～3
    for (int i = 0; i < StringLen(EMAIL); ++i) {
        uchar byte = (uchar)StringGetChar(EMAIL, i);
        ClientBrokerID ^= byte << (8 * shift_bytes);
        --shift_bytes;
        if (shift_bytes < 0) {
            shift_bytes = 3;
        }
    }

    // 15000ミリ秒の周期でポジションコピーを行います
    if (!EventSetMillisecondTimer(15000)) {
        string error_message = "ポジションコピーのインターバルタイマーを設定できませんでした。";
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| シンボル名の変換を行います                                       |
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
        ExecuteRequest(+1, +Position, ConvertSymbol(Symbol()), 0.01 * Ticket, Ticket);
    }
    else {
        ExecuteRequest(-1, -Position, ConvertSymbol(Symbol()), 0.01 * Ticket, Ticket);
        Position = -Position;
    }
}

//+------------------------------------------------------------------+
//| ポジションの差分をHTTPリクエストで送信します                     |
//+------------------------------------------------------------------+
void ExecuteRequest(int change, int command, string symbol, double lots, int ticket)
{
    string position_id = StringFormat("%08x%08x%08x", ClientBrokerID, SenderAccountNumber, ticket);
    
    string uri = URL;
    uri += StringFormat("&change=%d", change);
    uri += StringFormat("&command=%d", command);
    uri += StringFormat("&symbol=%s", symbol);
    uri += StringFormat("&lots=%.2f", lots);
    uri += StringFormat("&position_id=%s", position_id);

    int res = 0;
    string response = Get(uri, res, 3, 500);

    if (STOPPED_BY_HTTP_ERROR || response == HTTP_ERROR) {
        ExitEA(ENDPOINT, res);
        return;
    }
}
