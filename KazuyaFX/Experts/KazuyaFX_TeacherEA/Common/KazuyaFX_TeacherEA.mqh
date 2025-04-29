//+------------------------------------------------------------------+
//|                                           KazuyaFX_TeacherEA.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#include "KazuyaFX_Common.mqh"


input string  TRADE_TRANSMITTER_SERVER = "https://qta-kazuyafx.com";    // トレードポジションを受信するサーバー
input int     RETRY_COUNT_MAX = 4;                              // オーダー失敗時のリトライ回数
input int     RETRY_INTERVAL = 250;                             // オーダー失敗時のリトライ時間インターバル
input string  SYMBOL_APPEND_SUFFIX = "";                        // ポジションコピー時にシンボル名に追加するサフィックス
input int     SLIPPAGE = 30;                                    // スリッページ(ポイント)

#define FETCH_INTERVAL 100                                      // オーダー取得時のインターバル

string GetName(string path)
{
    string items[];
    int n = StringSplit(path, '\\', items);
    string name = items[n - 1];
    StringReplace(name, ".mq4", "");
    return name;
}

string ENDPOINT = TRADE_TRANSMITTER_SERVER + "/api/teacher";
string URL = ENDPOINT;

bool TimerEnabled = false;

string EntryProcessedPositionIdList = ",";
string ExitProcessedPositionIdList = ",";

int MagicNumber = 0;

int file = INVALID_HANDLE;
string filename = "";
string title = "発注日時,決済日時,通貨ペア,取引数量,損益\n";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    string name = NAME;
    URL += StringFormat("?name=%s", UrlEncode(name));

    int shift_bytes = 3; // 32bitの整数値を作る: 0オリジンで0～3
    MagicNumber = 0;
    for (int i = 0; i < StringLen(name); ++i) {
        uchar byte = (uchar)StringGetChar(name, i);
        MagicNumber ^= byte << (8 * shift_bytes);
        --shift_bytes;
        if (shift_bytes < 0) {
            shift_bytes = 3;
        }
    }
    MagicNumber &= 0x7FFFFFFF;

    filename = name + ".csv";
    bool result = AppendLog(title);
    if (!result) {
        return INIT_FAILED;
    }

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
    string csv_text = Get(URL, res, 1, 1000);
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
        // 0列目：生徒さんの名前
        string name = RemoveQuote(field[0]);
        // 1列目："1:Entry": ポジション追加 ／ "0:Exit": ポジション削除
        string entry = RemoveQuote(field[1]);
        // 2列目："1:Buy": 買い建て ／ "0:Sell": 売り建て
        string buy = RemoveQuote(field[2]);
        // 3列目：シンボル名
        string symbol = RemoveQuote(field[3]) + SYMBOL_APPEND_SUFFIX;
        // 4列目：ポジションサイズ
        double lots = RoundLots(symbol, StringToDouble(RemoveQuote(field[4])) * LOTS_MULTIPLY);
        // 5列目：ポジションID(生徒さんの名前-チケット番号)
        string position_id = StringFormat("%s-%s", NAME, RemoveQuote(field[5]));
        int ticket = (int)StringToInteger(RemoveQuote(field[5]));
        if (entry == "1") {
            int pos = StringFind(EntryProcessedPositionIdList, "," + position_id + ",");
            if (pos > 0) {
                continue;
            }
            EntryProcessedPositionIdList += position_id + ",";
        }
        else {
            int pos = StringFind(ExitProcessedPositionIdList, "," + position_id + ",");
            if (pos > 0) {
                continue;
            }
            ExitProcessedPositionIdList += position_id + ",";
        }
        if (entry == "1") {
            Entry(buy, symbol, lots, MagicNumber, position_id);
        }
        else {
            Exit(buy, symbol, lots, MagicNumber, position_id);
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
            bool result = Settlement(order_type, ticket, ordered_lots, price, arrow);
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

//+------------------------------------------------------------------+
//| ポジションを決済し、ログファイルに出力します                     |
//+------------------------------------------------------------------+
bool Settlement(int order_type, int ticket, double ordered_lots, double price, color arrow)
{
    if (order_type == OP_BUY || order_type == OP_SELL) {
        bool result = OrderClose(ticket, ordered_lots, price, SLIPPAGE, arrow);
        if (!result) {
            return result;
        }
        // "発注日時,決済日時,通貨ペア,取引数量,損益\n";
        string line = "";
        MqlDateTime dt = {};
        TimeToStruct(OrderOpenTime(), dt);
        line += StringFormat("%04d/%02d/%02d %02d:%02d:%02d,",dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
        TimeToStruct(OrderCloseTime(), dt);
        line += StringFormat("%04d/%02d/%02d %02d:%02d:%02d,",dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
        line += StringFormat("%s,", OrderSymbol());
        line += StringFormat("%.2f,", OrderLots());
        line += StringFormat("%.0f\n",OrderProfit() + OrderSwap());
        AppendLog(line);
        return result;
    }
    else {
        return OrderDelete(ticket, arrow);
    }
}

bool AppendLog(string message) {
    int handle = FileOpen(filename, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
    if (handle == INVALID_HANDLE) {
        // 初回作成（追記ではなく新規書き込み）
        handle = FileOpen(filename, FILE_WRITE | FILE_TXT | FILE_ANSI);
    }

    if (FileSize(handle) == 0 && message != title) {
        FileWriteString(handle, title);
    }

    if (handle != INVALID_HANDLE) {
        FileSeek(handle, 0, SEEK_END);
        FileWriteString(handle, message);
        FileClose(handle);
        return true;
    } else {
        MessageBox(filename + "が開けませんでした: " + ErrorDescription(), "エラー");
        return false;
    }
}
