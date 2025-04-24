//+------------------------------------------------------------------+
//|                                           KazuyaFX_TestingEA.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#ifndef EMAIL
input string  EMAIL = "babydaemons@gmail.com"; // メールアドレス
#endif

input string  TRADE_TRANSMITTER_SERVER = "https://babydaemons.jp"; // トレードポジションを受信するサーバー
input string  SYMBOL_REMOVE_SUFFIX = ""; // ポジションコピー時にシンボル名から削除するサフィックス

string GetEmail(string path)
{
    string items[];
    int n = StringSplit(path, '\\', items);
    string email = items[n - 1];
    StringReplace(email, ".mq4", "");
    return email;
}

#include "KazuyaFX_Common.mqh"

#define MAX_POSITION 1024
#define CHECK_INTERVAL 100

//+------------------------------------------------------------------+
//| ポジション全体を表す構造体です                                      |
//+------------------------------------------------------------------+
struct POSITION_LIST {
    int Change[MAX_POSITION];
    int Command[MAX_POSITION];
    int MagicNumber[MAX_POSITION];
    datetime EntryDate[MAX_POSITION];
    int EntryType[MAX_POSITION];
    double EntryPrice[MAX_POSITION];
    string SymbolValue[MAX_POSITION];
    int Tickets[MAX_POSITION];
    double Lots[MAX_POSITION];
    double StopLoss[MAX_POSITION];
    double TakeProfit[MAX_POSITION];
    datetime OpenTime[MAX_POSITION];

    void Clear() {
        ArrayFill(Change, 0, MAX_POSITION, 0);
        ArrayFill(Command, 0, MAX_POSITION, 0);
        ArrayFill(MagicNumber, 0, MAX_POSITION, 0);
        ArrayFill(EntryDate, 0, MAX_POSITION, 0);
        ArrayFill(EntryType, 0, MAX_POSITION, 0);
        ArrayFill(EntryPrice, 0, MAX_POSITION, 0);
        ArrayFill(Tickets, 0, MAX_POSITION, 0);
        for (int i = 0; i < MAX_POSITION; ++i) {
            SymbolValue[i] = "";
        }
        ArrayFill(Lots, 0, MAX_POSITION, 0.0);
        ArrayFill(StopLoss, 0, MAX_POSITION, 0.0);
        ArrayFill(TakeProfit, 0, MAX_POSITION, 0.0);
        ArrayFill(OpenTime, 0, MAX_POSITION, 0);
    }
};

// ポジション全体を表す構造体です
// 添字0と1で交互に現在と前回のポジションの状況を保持します
POSITION_LIST Positions[2];

// ポジション全体を表す構造体配列の添字で
// 0と1のどちらが現在を表すか示すフラグです
bool CurrentIndex;

// 通信用タブ区切りHTTPリクエストに書き出す
// ポジション全体の差分を表す構造体です
POSITION_LIST Output;

// 送信元証券会社のIDです
ulong ClientBrokerID = 0;

// 口座番号です
ulong SenderAccountNumber = AccountInfoInteger(ACCOUNT_LOGIN);

string ENDPOINT = TRADE_TRANSMITTER_SERVER + "/api/student";
string URL;

datetime StartServerTimeEA;

bool Busy = false;

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

    // CHECK_INTERVALミリ秒の周期でポジションコピーを行います
    if (!EventSetMillisecondTimer(CHECK_INTERVAL)) {
        string error_message = "ポジションコピーのインターバルタイマーを設定できませんでした。";
        MessageBox(error_message, "エラー", MB_ICONSTOP | MB_OK);
        return INIT_FAILED;
    }

    // ポジション全体を表す構造体を
    // 添字0と1の両方(現在と前回の両方)を初期化します
    for (int i = 0; i < 2; ++i) {
        Positions[i].Clear();
    }

    // 添字0を現在のポジション状態にします
    CurrentIndex = (bool)0;

#ifdef __DISABLED
    // EA起動時の時刻です
    StartServerTimeEA = TimeCurrent();
#endif

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
    if (Busy) {
        return;
    }

    // CHECK_INTERVALミリ秒の周期でポジション全体の差分をHTTPリクエストで送信します
    Busy = true;
    SendPositions();
    Busy = false;
}

//+------------------------------------------------------------------+
//| ポジション全体の差分をHTTPリクエストで送信します                     |
//+------------------------------------------------------------------+
void SendPositions() {
    // 出力するポジション全体の差分を表す構造体をクリアします
    Output.Clear();

    // 現在のポジション全体の状態を走査します
    // 戻り値 position_count は現在のポジションの総数です
    int current = (int)CurrentIndex;
    int position_count = ScanCurrentPositions(Positions[current]);

    // ポジションの差分を走査します
    int previous = (int)!CurrentIndex;

    // 追加されたポジション全体の状態を走査します
    // 戻り値 added_count は差分の総数です
    int added_count = ScanAddedPositions(Positions[current], Positions[previous], position_count, 0);

    // 削除されたポジション全体の状態を走査します
    // 戻り値 change_count は差分の総数です
    int change_count = ScanRemovedPositions(Positions[current], Positions[previous], position_count, added_count);

    // 現在のポジション状態の添字と前回のポジション状態の添字を入れ替えます
    CurrentIndex = !CurrentIndex;

    // ポジションの差分が0件ならばファイル出力しません
    if (change_count == 0) {
        return;
    }

    // コピーポジション連携用HTTPリクエストで送信します
    SendPositionRequest(change_count);
}


//+------------------------------------------------------------------+
//| 現在のポジション全体の状態を走査します                              |
//+------------------------------------------------------------------+
int ScanCurrentPositions(POSITION_LIST& Current) {
    // 現在のポジション状態を取得する前に
    // 現在の添字が指す配列要素をクリアします
    Current.Clear();

    // 現在のポジション状態を全て取得します
    int position_count = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        // トレード中のポジションを選択します
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }

#ifdef __DISABLED
        // EA起動時よりも過去に建てられたポジションはコピー対象外です
        if (OrderOpenTime() <= StartServerTimeEA) {
            continue;
        }
#endif // __DISABLED

        int buy = 0;
        switch (OrderType()) {
        case OP_BUY:
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
            buy = 1;
            break;
        case OP_SELL:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
            buy = 0;
            break;
        default:
            continue;
        }

        Current.Change[position_count] = INT_MAX;
        Current.Command[position_count] = buy;
        Current.EntryPrice[position_count] = OrderOpenPrice();
        Current.SymbolValue[position_count] = OrderSymbol();
        Current.Tickets[position_count] = OrderTicket();
        Current.Lots[position_count] = OrderLots();
        Current.StopLoss[position_count] = OrderStopLoss();
        Current.TakeProfit[position_count] = OrderTakeProfit();
        Current.OpenTime[position_count] = OrderOpenTime();
        ++position_count;
    }

    return position_count;
}

//+------------------------------------------------------------------+
//| 追加されたポジション全体の状態を走査します                       |
//+------------------------------------------------------------------+
int ScanAddedPositions(POSITION_LIST& Current, POSITION_LIST& Previous, int position_count, int added_count) {
    // 外側のカウンタ current のループで現在のポジション全体をスキャンします
    for (int current = 0; current < position_count; ++current) {
        bool added = true; // ポジション追加フラグ

        // 内側のカウンタ previous のループで前回のポジション全体をスキャンします
        for (int previous = 0; Previous.Tickets[previous] != 0 && previous < MAX_POSITION; ++previous) {
            // チケット番号が一致するとき、
            if (Previous.Tickets[previous] == Current.Tickets[current]) {
                // チケット番号・ストップロス・テイクプロフィットが完全一致なので変化なしです
                added = false;
                break;
            }
        }

        // チケット番号が不一致のとき、ポジション追加です
        if (added) {
            added_count = AppendChangedPosition(Current, 1, added_count, current);
        }
    }

    return added_count;
}

//+------------------------------------------------------------------+
//| 削除されたポジション全体の状態を走査します                       |
//+------------------------------------------------------------------+
int ScanRemovedPositions(POSITION_LIST& Current, POSITION_LIST& Previous, int position_count, int change_count) {
    // 外側のカウンタ previous のループで前回のポジション全体をスキャンします
    for (int previous = 0; Previous.Tickets[previous] != 0 && previous < MAX_POSITION; ++previous) {
        bool removed = true; // ポジション削除フラグ

        // 内側のカウンタ current のループで現在のポジション全体をスキャンします
        for (int current = 0; current < position_count; ++current) {
            // チケット番号が一致したらポジションに変化はありません
            // ポジション修正は ScanAddedPositions() で確認済みです
            if (Previous.Tickets[previous] == Current.Tickets[current]) {
                removed = false;
                break;
            }
        }

        // チケット番号が不一致のとき、ポジション削除です
        if (removed) {
            change_count = AppendChangedPosition(Previous, 0, change_count, previous);
        }
    }

    return change_count;
}

//+------------------------------------------------------------------+
//| 出力する差分情報構造体にポジションの要素を追記します             |
//+------------------------------------------------------------------+
int AppendChangedPosition(POSITION_LIST& Current, int entry, int dst, int src) {
    Output.Change[dst] = entry;
    Output.Command[dst] = Current.Command[src];
    Output.Tickets[dst] = Current.Tickets[src];
    Output.EntryDate[dst] = Current.EntryDate[src];
    Output.EntryType[dst] = Current.EntryType[src];
    Output.EntryPrice[dst] = Current.EntryPrice[src];
    Output.SymbolValue[dst] = Current.SymbolValue[src];
    Output.Lots[dst] = Current.Lots[src];
    Output.StopLoss[dst] = Current.StopLoss[src];
    Output.TakeProfit[dst] = Current.TakeProfit[src];
    return ++dst;
}

//+------------------------------------------------------------------+
//| コピーポジション連携用HTTPリクエストで送信します                 |
//+------------------------------------------------------------------+
void SendPositionRequest(int change_count) {
    for (int i = 0; i < change_count; ++i) {
        string symbol = Output.SymbolValue[i];
        StringReplace(symbol, SYMBOL_REMOVE_SUFFIX, "");
        ExecuteRequest(Output.Change[i], Output.Command[i], symbol, Output.Lots[i], Output.Tickets[i]);
        break;
    }
}

//+------------------------------------------------------------------+
//| ポジションの差分をHTTPリクエストで送信します                     |
//+------------------------------------------------------------------+
void ExecuteRequest(int entry, int buy, string symbol, double lots, int ticket)
{
    string position_id = StringFormat("%08x%08x%08x", ClientBrokerID, SenderAccountNumber, ticket);
    string uri = URL;
    uri += StringFormat("&entry=%d", entry);
    uri += StringFormat("&buy=%d", buy);
    uri += StringFormat("&symbol=%s", symbol);
    uri += StringFormat("&lots=%.2f", lots);
    uri += StringFormat("&position_id=%s", position_id);

    int res = 0;
    string response = Get(uri, res, 4, 1000);

    if (STOPPED_BY_HTTP_ERROR || response == HTTP_ERROR) {
        ExitEA(ENDPOINT, res);
        return;
    }

    printf("Order Request Sended: %s", uri);
}
