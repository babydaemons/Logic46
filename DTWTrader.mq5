//+------------------------------------------------------------------+
//|                                                   TSTraderEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#import "KTraderEA.dll"

//--- input parameters
const int       DAY_BARS = PeriodSeconds(PERIOD_D1) / PeriodSeconds(PERIOD_CURRENT);
const int       SCAN_BARS = 10 * DAY_BARS;
const int       HIST_BARS = 2 * 254 * DAY_BARS;
const int       CLUSTER_LEVELS = 8;
const double    ENTRY_PERFORMANCE = 1.00;
const double    ENTRY_LIMIT_MARGIN_LEVEL = 10000.0;
const double    EXIT_LIMIT_MARGIN_LEVEL = 5000.0;
const double    SL_PERCENTAGE = 5.0;
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20221022;
sinput int      SLIPPAGE = 10;
const string    COMMON_DIR = "C:\\Users\\shingo\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\";
const string    MODULE_FILE = "DTWTrader.exe";

const int       FETCH_BARS = SCAN_BARS + 1 * DAY_BARS;

const int DIM = 4 * SCAN_BARS;
const int DIM_X = 4 * (SCAN_BARS - 1);
const int DIM_Y = 4;

vector XD[];
vector YD[];

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"

#define BARS 2

int Position;
double Lots[2];
double SL;

double Performance;
double Entry;
double PrevEntry;

MQL45_APPLICATION_START()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RemainingMargin()
{
    return AccountBalance() + AccountCredit() + AccountProfit();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RemainingBalance()
{
    return AccountBalance() + AccountCredit();
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    ActiveLabel::POSITION_X = 240;
    ActiveLabel::FONT_SIZE = 14;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime t = TimeCurrent();
    static long prev_minute = 0;
    long current_minute = (long)t / PeriodSeconds(PERIOD_M1);
    if (current_minute > prev_minute) {
        TrailingStop();
        prev_minute = current_minute;
    }

    static bool result = false;
    static long prev_day = 0;
    long current_day = (long)t / PeriodSeconds(PERIOD_D1);
    if (current_day > prev_day) {
        if (TimeDayOfWeek(t) == 1) {
            result = Clustering();
        }
        prev_day = current_day;
    }

    GetPositionCount();

    string msg = "";
    string wdays[] = { "日", "月", "火", "水", "木", "金", "土" };
    msg += TimeToString(t, TIME_DATE) + "(" + wdays[TimeDayOfWeek(t)] + ") " + TimeToString(t, TIME_SECONDS) + "\n";
    msg += StringFormat("残高     %s\n", ActiveLabel::FormatComma(AccountBalance(), 0));
    msg += StringFormat("損益     %s\n", ActiveLabel::FormatComma(AccountProfit(), 0));
    msg += StringFormat("証拠金   %s\n", ActiveLabel::FormatComma(RemainingMargin(), 0));
    msg += StringFormat("維持率   %.2f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    msg += StringFormat("期待利益 %+.4fbp\n", Performance);
    msg += StringFormat("%s L:%.2f S:%.2f\n", Symbol(), Lots[0], Lots[1]);
    ActiveLabel::Comment(msg);

    if (RemainingMargin() < 10000) {
        ExpertRemove();
        return;
    }

    static long prev_bar = 0;
    long current_bar = (long)(t - PeriodSeconds(PERIOD_M30)) / PeriodSeconds(PERIOD_CURRENT);
    if (current_bar <= prev_bar) {
        return;
    }
    prev_bar = current_bar;

    if (result) {
        Trade();
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    return 0.0;
}

bool Clustering()
{
    string file_base = GetDataFileBase();
    string input_file = StringFormat(file_base, "IN");
    string output_file = StringFormat(file_base, "OUT");

    int n = 0;
    int file1 = FileOpen(input_file, FILE_WRITE | FILE_COMMON | FILE_BIN);
    if (file1 == INVALID_HANDLE) {
        printf("ERROR(%d): opening dataset file failed: %s: %d", __LINE__, input_file, GetLastError());
        return false;
    }

    double X0[];
    bool result = CreateDataSetVectors(X0, HIST_BARS, n);
    if (!result) {
        FileClose(file1);
        FileDelete(input_file, FILE_COMMON);
        printf("ERROR(%d): creating dataset failed: %d/%d %.3f%%", __LINE__, n, HIST_BARS, 100.0 * n / HIST_BARS);
        return false;
    }

    FileWriteArray(file1, X0);
    FileClose(file1);
    printf("INFO: saved dataset: %d vectors ---> %d cluster levels...", HIST_BARS, CLUSTER_LEVELS);

    string module_path = COMMON_DIR + MODULE_FILE;
    string args = StringFormat("0 %d %d 1 %s %s", CLUSTER_LEVELS, SCAN_BARS, COMMON_DIR + input_file, COMMON_DIR + output_file);
    printf("%s %s", module_path, args);
    
    KTrader::Execute(module_path, args, true);
    FileDelete(input_file, FILE_COMMON);

    int file2 = FileOpen(output_file, FILE_READ | FILE_COMMON | FILE_BIN);
    if (file2 == INVALID_HANDLE) {
        printf("ERROR(%d): opening cluster file failed: %s: %d", __LINE__, output_file, GetLastError());
        return false;
    }
    uint count1 = (uint)(FileSize(file2) / sizeof(double));

    double Y0[];
    ArrayResize(Y0, count1);
    uint count2 = FileReadArray(file2, Y0, 0, count1);
    FileClose(file2);
    FileDelete(output_file, FILE_COMMON);
    if (count1 != count2) {
        printf("ERROR(%d): clustering result load failed: %d / %d", count2, count2);
        return false;
    }

    const int CLUSTERS = (int)count1 / DIM;
    ArrayResize(XD, CLUSTERS);
    ArrayResize(YD, CLUSTERS);

    uint k = 0;
    for (int j = 0; j < CLUSTERS; ++j) {
        vector x(DIM_X);
        for (int i = 0; i < DIM_X; ++i) {
            x[i] = Y0[k++];
        }
        XD[j] = x;

        vector y(DIM_Y);
        for (int i = 0; i < DIM_Y; ++i) {
            y[i] = Y0[k++];
        }
        YD[j] = y;
        printf("INFO: cluster #%d: performance = %+.3f", j, y[0]);
    }

    printf("INFO: loaded %d clusters", ArraySize(XD));
    return true;
}

bool CreateDataSetVectors(double& X0[], int N, int& n)
{
    int k = 0;
    ArrayResize(X0, 4 * SCAN_BARS * N);
    for (n = 0; n < N; ++n) {
        datetime t = ::iTime(Symbol(), Period(), n);
        double XO[];
        if (CopyOpen(Symbol(), Period(), t, FETCH_BARS, XO) != FETCH_BARS) {
            return false;
        }
        double XH[];
        if (CopyHigh(Symbol(), Period(), t, FETCH_BARS, XH) != FETCH_BARS) {
            return false;
        }
        double XL[];
        if (CopyLow(Symbol(), Period(), t, FETCH_BARS, XL) != FETCH_BARS) {
            return false;
        }
        double XC[];
        if (CopyClose(Symbol(), Period(), t, FETCH_BARS, XC) != FETCH_BARS) {
            return false;
        }

        const double XC0 = XC[SCAN_BARS - 1];
        double Xo[];
        if (!CreateDataSetValue(XC0, XO, Xo)) {
            return false;
        }
        double Xh[];
        if (!CreateDataSetValue(XC0, XH, Xh)) {
            return false;
        }
        double Xl[];
        if (!CreateDataSetValue(XC0, XL, Xl)) {
            return false;
        }
        double Xc[];
        if (!CreateDataSetValue(XC0, XC, Xc)) {
            return false;
        }

        for (int i = 0; i < SCAN_BARS; ++i) {
            X0[k++] = Xo[i];
            X0[k++] = Xh[i];
            X0[k++] = Xl[i];
            X0[k++] = Xc[i];
        }
    }

    return true;
}

bool CreateDataSetValue(const double XC0, const double& X[], double& x[])
{
    const static int T0 = SCAN_BARS - 1;
    const static int T1 = FETCH_BARS - 1;

    ArrayResize(x, SCAN_BARS);

    for (int i = T0 - 1; i >= 0; --i) {
        if (X[i] == 0.0) {
            return false;
        }
        x[i] = 1000.0 * (XC0 - X[i]) / X[T0];
    }

    if (X[T1] == 0.0) {
        return false;
    }
    x[SCAN_BARS - 1] = 1000.0 * (X[T1] - XC0) / XC0;
    
    return true;
}

string GetDataFileBase()
{
    string file_base = StringFormat("%s-", Symbol());
    for (int i = 0; i < 128 / 32; ++i) {
        file_base += StringFormat("%08X", (rand() | (rand() << 16) | (rand() >> 16)) ^ (rand() | (rand() << 16) | (rand() >> 16)));
    }
    file_base += "-%s.bin";
    return file_base;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void Trade()
{
    double X[];
    int n = 0;
    if (!CreateDataSetVectors(X, 1, n)) {
        return;
    }

    vector x(DIM_X);
    for (int i = 0; i < DIM_X; ++i) {
        x[i] = X[i];
    }

    int k_min = 0;
    double d_min = +FLT_MAX;
    for (int k = 0; k < ArraySize(XD); ++k) {
        vector xd = XD[k];
        vector dx = x - xd;
        double d0 = dx.Norm(VECTOR_NORM_P);
        if (d0 < d_min) {
            k_min = k;
            d_min = d0;
        }
    }

    vector y = YD[k_min];
    Performance = y[0];
    int entry = Performance > 0 ? +1 : -1;
/*
    static int prev_entry = 0;
    if (entry != 0 && entry != prev_entry) {
        ClosePositionAll(StringFormat("Entry(%+d)", entry));
        prev_entry = entry;
    }
*/

    double profit = AccountInfoDouble(ACCOUNT_PROFIT);
    if (profit < 0) {
        if (entry > 0 && Position > 0) {
            return;
        }
        if (entry < 0 && Position < 0) {
            return;
        }
    }

    double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    if (0.0 < margin_level && margin_level < EXIT_LIMIT_MARGIN_LEVEL) {
        ClosePositionAll(StringFormat("Exit(%+.0f/%.2f%%)", profit, margin_level));
        return;
    }

    if (0.0 < margin_level && margin_level < MathAbs(Position) * ENTRY_LIMIT_MARGIN_LEVEL) {
        if (entry > 0 && Position > 0) {
            return;
        }
        if (entry < 0 && Position < 0) {
            return;
        }
    }

    if (MathAbs(Performance) < ENTRY_PERFORMANCE) {
        return;
    }

    SL = Ask / 100.0 * SL_PERCENTAGE;
    string comment = StringFormat("ExpectedProfit: %+.3f", Performance);
    if (entry > 0) {
        double sl = SL > 0 ? NormalizeDouble(Bid - SL, Digits) : 0;
        if (!OrderSend(Symbol(), OP_BUY, LOTS, Ask, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrBlue)) {
            Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
        }
    } else if (entry < 0) {
        double sl = SL > 0 ? NormalizeDouble(Ask + SL, Digits) : 0;
        if (!OrderSend(Symbol(), OP_SELL, LOTS, Bid, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrRed)) {
            Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
        }
    }
}

//+------------------------------------------------------------------+
//| トレーリングストップ                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
    if (SL == 0.0) {
        return;
    }

    int minute = TimeMinute(TimeCurrent());
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;

        double TRAILING_START = SL * 0.75;
        double TRAILING_STEP0 = TRAILING_START * 0.75;
        double TRAILING_STEP = 0.5 * MathSqrt(profit_price / Point()) * Point();
        if (TRAILING_STEP < TRAILING_STEP0) {
            TRAILING_STEP = TRAILING_STEP0;
        } 
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        int digits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
        if (type == OP_BUY) {
            if (profit_price > TRAILING_START) {
                double sl = NormalizeDouble(price - TRAILING_STEP, digits);
                double tp = 0;
                if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
            else if (OrderStopLoss() < price - SL) {
                double sl = NormalizeDouble(price - SL, digits);
                double tp = 0;
                if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
        } else if (type == OP_SELL) {
            if (profit_price > TRAILING_START) {
                double sl = NormalizeDouble(price + TRAILING_STEP, digits);
                double tp = 0;
                if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
            else if (OrderStopLoss() > price + SL) {
                double sl = NormalizeDouble(price + SL, digits);
                double tp = 0;
                if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void ClosePositionAll(string reason)
{
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }

        int ticket = OrderTicket();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        double lots = OrderLots();
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        double profit = OrderProfit() + OrderSwap();
        OrderCloseComment(reason + StringFormat(": %+.0f", profit));
        if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            //printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
    GetPositionCount();
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
void GetPositionCount()
{
    Position = 0;
    Lots[0] = Lots[1] = 0;
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }
        Lots[OrderType() == OP_BUY ? 0 : 1] += OrderLots();
        Position += OP_BUY ? +1 : -1;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int Sgn(double x)
{
    if (x > 0) {
        return +1;
    }
    if (x < 0) {
        return -1;
    }
    return 0;
}

MQL45_APPLICATION_END()
