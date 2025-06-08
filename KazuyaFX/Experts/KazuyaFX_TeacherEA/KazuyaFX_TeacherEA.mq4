//+------------------------------------------------------------------+
//|                                           KazuyaFX_TeacherEA.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

#include "Common/KazuyaFX_Common.mqh"

input int     RETRY_COUNT_MAX = 4;                              // オーダー失敗時のリトライ回数
input int     RETRY_INTERVAL = 250;                             // オーダー失敗時のリトライ時間インターバル
input string  SYMBOL_APPEND_SUFFIX = "";                        // ポジションコピー時にシンボル名に追加するサフィックス
input int     SLIPPAGE = 30;                                    // スリッページ(ポイント)

#define FETCH_INTERVAL 100                                      // オーダー取得時のインターバル

string ENDPOINT;
string URL;

bool TimerEnabled = false;

string EntryProcessedPositionIdList = ",";
string ExitProcessedPositionIdList = ",";

string title = "発注日時,決済日時,通貨ペア,取引数量,損益,生徒さん取引番号,先生取引番号\n";

struct STUDENT {
    string Name;
    double LotMultiply;
    int MagicNumber;
    string FileName;
};

STUDENT Students[];

int GetMagicNumber(string Name) {
    int shift_bytes = 3; // 32bitの整数値を作る: 0オリジンで0～3
    int MagicNumber = 0;
    for (int i = 0; i < StringLen(Name); ++i) {
        uchar byte = (uchar)StringGetChar(Name, i);
        MagicNumber ^= byte << (8 * shift_bytes);
        --shift_bytes;
        if (shift_bytes < 0) {
            shift_bytes = 3;
        }
    }
    MagicNumber &= 0x7FFFFFFF;
    return MagicNumber;
}

bool LoadStudents(string& names) {
    int file = FileOpen("Config\\Students.csv", FILE_ANSI | FILE_READ, '\xFF', CP_UTF8);
    if (file == INVALID_HANDLE) {
        return false;
    }

    int n = 0;
    while (!FileIsEnding(file)) {
        string line = FileReadString(file);
        ArrayResize(Students, n + 1);
        string values[];
        StringSplit(line, ',', values);
        Students[n].Name = values[0];
        Students[n].LotMultiply = StringToDouble(values[1]);
        Students[n].MagicNumber = GetMagicNumber(values[0]);
        Students[n].FileName = values[0] + ".csv";
        bool result = AppendLog(Students[n], title);
        if (!result) {
            FileClose(file);
            return false;
        }
        if (names == "") {
            names = values[0];
        }
        else {
            names += "," + values[0];
        }
        ++n;
    }
    FileClose(file);
    return true;
}

int FindStudentIndex(string name) {
    for (int i = 0; i < ArraySize(Students); ++i) {
        if (Students[i].Name == name) {
            return i;
        }
    }
    return -1;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    ENDPOINT = GetWebApiUri("/api/teacher");

    string names = "";
    bool result = LoadStudents(names);
    if (!result) {
        return INIT_FAILED;
    }
    URL = ENDPOINT + "?names=" + names;

    int res = 0;
    string status = Get(ENDPOINT + "?check=1", res, 2, 50);
    if (status != "ready") {
        ExitEA(ENDPOINT, ERROR_SERVER_NOT_READY, res);
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
            ExitEA(ENDPOINT, ERROR_SERVER_CONNECTION_LOST, res);
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
        int index = FindStudentIndex(name);
        if (index < 0) {
            continue;
        }
        double lots = RoundLots(symbol, StringToDouble(RemoveQuote(field[4])) * Students[index].LotMultiply);
        // 5列目：ポジションID(生徒さんの名前-チケット番号)
        string position_id = StringFormat("%s-%s", Students[index].Name, RemoveQuote(field[5]));
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
            Entry(Students[index], buy, symbol, lots, Students[index].MagicNumber, position_id);
        }
        else {
            Exit(Students[index], buy, symbol, lots, Students[index].MagicNumber, position_id);
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
void Entry(const STUDENT& Student, string buy, string symbol, double lots, int magic_number, string position_id)
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
void Exit(const STUDENT& Student, string buy, string symbol, double lots, int magic_number, string position_id)
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
            bool result = Settlement(Student, order_type, ticket, ordered_lots, price, arrow);
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
bool Settlement(const STUDENT& Student, int order_type, int ticket, double ordered_lots, double price, color arrow)
{
    if (order_type == OP_BUY || order_type == OP_SELL) {
        bool result = OrderClose(ticket, ordered_lots, price, SLIPPAGE, arrow);
        if (!result) {
            return result;
        }
        // "発注日時,決済日時,通貨ペア,取引数量,損益,生徒さん取引番号,先生取引番号\n"
        if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
            printf(ErrorDescription());
            return false;
        }
        string line = "";
        MqlDateTime dt = {};
        TimeToStruct(OrderOpenTime(), dt);
        line += StringFormat("%04d/%02d/%02d %02d:%02d:%02d,",dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
        TimeToStruct(OrderCloseTime(), dt);
        line += StringFormat("%04d/%02d/%02d %02d:%02d:%02d,",dt.year, dt.mon, dt.day, dt.hour, dt.min, dt.sec);
        line += StringFormat("%s,", OrderSymbol());
        line += StringFormat("%.2f,", OrderLots());
        line += StringFormat("%.0f,", OrderProfit() + OrderSwap());
        string student_ticket = OrderComment();
        StringReplace(student_ticket, Student.Name + "-", "");
        line += StringFormat("%s,", student_ticket);
        line += StringFormat("%d\n", ticket);
        AppendLog(Student, line);
        return result;
    }
    else {
        return OrderDelete(ticket, arrow);
    }
}

bool AppendLog(const STUDENT& Student, string message) {
    bool created = false;
    int handle = FileOpen(Student.FileName, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI);
    if (handle == INVALID_HANDLE) {
        // 初回作成（追記ではなく新規書き込み）
        handle = FileOpen(Student.FileName, FILE_WRITE | FILE_TXT | FILE_ANSI);
        created = true;
    }

    if (handle != INVALID_HANDLE) {
        FileSeek(handle, 0, SEEK_END);
        if (created) {
            FileWriteString(handle, title);
        }
        else {
            FileWriteString(handle, message);
        }
        FileClose(handle);
        return true;
    } else {
        MessageBox(Student.FileName + "が開けませんでした: " + ErrorDescription(), "エラー");
        return false;
    }
}
