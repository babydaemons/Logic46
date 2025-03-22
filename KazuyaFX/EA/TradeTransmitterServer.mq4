//+------------------------------------------------------------------+
//|                                       TradeTransmitterServer.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#include "TradeTransmitter.mqh"

#ifndef EMAIL
input string  EMAIL = "babydaemons@gmail.com";                  // 生徒さんのメールアドレス
#endif

#ifndef ACCOUNT
input int     ACCOUNT = 201942679;                              // 生徒さんの口座番号
#endif

input string  TRADE_TRANSMITTER_SERVER = "https://babydaemons.jp";    // トレードポジションを受信するサーバー
input int     FETCH_INTERVAL = 100;                             // オーダー取得時のインターバル
input int     RETRY_COUNT_MAX = 4;                              // オーダー失敗時のリトライ回数
input int     RETRY_INTERVAL = 100;                             // オーダー失敗時のリトライ時間インターバル
input string  SYMBOL_APPEND_SUFFIX = "";                        // ポジションコピー時にシンボル名に追加するサフィックス
input double  LOTS_MULTIPLY = 2.0;                              // ポジションコピー時のロット数の係数
input int     SLIPPAGE = 30;                                    // スリッページ(ポイント)

int GetPathValues(string path, string& values[])
{
    string items[];
    int n = StringSplit(path, '\\', items);
    string filename = items[n - 1];
    StringReplace(filename, ".mq4", "");
    return StringSplit(filename, '+', values);
}

string GetEmail(string path)
{
    string values[];
    GetPathValues(path, values);
    return values[0];
}

int GetAccount(string path)
{
    string values[];
    GetPathValues(path, values);
    return (int)StringToInteger(values[1]);
}

string ENDPOINT = TRADE_TRANSMITTER_SERVER + "/api/teacher";
string URL = ENDPOINT;

bool TimerEnabled = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    URL += StringFormat("?email=%s", UrlEncode(EMAIL));
    EventSetMillisecondTimer(FETCH_INTERVAL);
    TimerEnabled = true;
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    if (TimerEnabled) {
        EventKillTimer();
        TimerEnabled = false;
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    int res = 0;
    string csv_text = Get(URL, res, 0, 1000);
    if (STOPPED_BY_HTTP_ERROR || csv_text == HTTP_ERROR) {
        if (TimerEnabled) {
            EventKillTimer();
            TimerEnabled = false;
            ExitEA(ENDPOINT, res);
        }
        ExpertRemove();
        return;
    }
    string lines[];
    int n = StringSplit(csv_text, '\n', lines);
    if (n < 0) {
        return;
    }
    for (int i = 0; i < n - 1; ++i) {
        string field[];
        StringSplit(lines[i], ',', field);
        // タブ区切りファイルの仕様
        // 0列目：メールアドレス
        string email = RemoveQuote(field[0]);
        // 1列目：口座番号
        string accountNumber = RemoveQuote(field[1]);
        // 2列目："1:Entry": ポジション追加 ／ "0:Exit": ポジション削除
        string entry = RemoveQuote(field[2]);
        // 3列目："1:Buy": 買い建て ／ "0:Sell": 売り建て
        string buy = RemoveQuote(field[3]);
        // 4列目：シンボル名
        string symbol = RemoveQuote(field[4]) + SYMBOL_APPEND_SUFFIX;
        // 5列目：ポジションサイズ
        double lots = RoundLots(symbol, StringToDouble(RemoveQuote(field[5])) * LOTS_MULTIPLY);
        // 6列目：ポジションID(送信元証券会社名/口座番号)
        string position_id = RemoveQuote(field[6]);
        // マジックナンバー：口座番号で代用
        int magic_number = (int)StringToInteger(accountNumber);
        if (entry == "1") {
            Entry(buy, symbol, lots, magic_number, position_id);
        }
        else {
            Exit(buy, symbol, lots, magic_number, position_id);
        }
        string send_response = Get(URL + "&position_id=" + position_id, res, 0, 1000);
        if (STOPPED_BY_HTTP_ERROR || send_response == HTTP_ERROR) {
            if (TimerEnabled) {
                EventKillTimer();
                TimerEnabled = false;
                ExitEA(ENDPOINT, res);
            }
            ExpertRemove();
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| ロット数を口座の上限・下限に丸めます                             |
//+------------------------------------------------------------------+
double RoundLots(string symbol, double lots)
{
    double rounded_lots = lots;
    double max_lots = MarketInfo(symbol, MODE_MAXLOT);
    if (lots > max_lots) {
        rounded_lots = max_lots;
    }
    double min_lots = MarketInfo(symbol, MODE_MINLOT);
    if (lots < min_lots) {
        rounded_lots = min_lots;
    }
    double lots_step = MarketInfo(symbol, MODE_LOTSTEP);
    if (lots_step == 0.0) {
        lots_step = 0.01;
    }
    double lots_qty = NormalizeDouble(rounded_lots / lots_step, 0);
    return lots_qty * lots_step;
}

//+------------------------------------------------------------------+
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(string buy, string symbol, double lots, int magic_number, string position_id)
{
    lots = RoundLots(symbol, lots);

    color arrow = clrNONE;
    int cmd = 0;
    if (buy == "1") {
        cmd = OP_BUY;
        arrow = clrBlue;
    }
    else {
        cmd = OP_SELL;
        arrow = clrRed;
    }

    string error_message = "";
    for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
        double price = 0;
        if (buy == "1") {
            price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        } else {
            price = SymbolInfoDouble(symbol, SYMBOL_BID);
        }
        int order_ticket = OrderSend(symbol, cmd, lots, price, SLIPPAGE, 0, 0, position_id, magic_number, 0, arrow);
        if (order_ticket == -1) {
            int error = GetLastError();
            if (error <= 1) {
                return;
            }
            error_message = ErrorDescription(error);
            printf("※エラー: %s", error_message);
            Sleep(RETRY_INTERVAL << times);
            RefreshRates();
        } else {
            return;
        }
    }

    Alert(error_message);
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(string buy, string symbol, double lots, int magic_number, string position_id)
{
    color arrow = clrNONE;
    if (buy == "1") {
        arrow = clrBlue;
    } else {
        arrow = clrRed;
    }

    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        if (OrderComment() != position_id) {
            continue;
        }
        int ticket = OrderTicket();
        int order_type = OrderType();
        double ordered_lots = OrderLots();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            double price = 0;
            if (buy == "1") {
                price = SymbolInfoDouble(symbol, SYMBOL_ASK);
            } else {
                price = SymbolInfoDouble(symbol, SYMBOL_BID);
            }
            bool result = (order_type == OP_BUY || order_type == OP_SELL) ?
                            OrderClose(ticket, ordered_lots, price, SLIPPAGE, arrow) :
                            OrderDelete(ticket, arrow);
            if (!result) {
                int error = GetLastError();
                if (error <= 1) {
                    return;
                }
                error_message = ErrorDescription(error);
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL << times);
                RefreshRates();
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}
