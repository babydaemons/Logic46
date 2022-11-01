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

#define PERIOD  PERIOD_H4
//--- input parameters
const int       UNIT_BARS = PeriodSeconds(PERIOD_W1) / PeriodSeconds(PERIOD);
const int       SCAN_BARS = 6 * UNIT_BARS;
const int       HIST_BARS = 12 * UNIT_BARS;
const int       CLUSTER_LEVELS = 10;
const double    ENTRY_PERFORMANCE = 0.0075;
const double    ENTRY_LIMIT_MARGIN_LEVEL = 10000.0;
const double    EXIT_LIMIT_MARGIN_LEVEL = 5000.0;
const double    SL_RATIO = 1.0;
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20221022;
sinput int      SLIPPAGE = 10;
const string    COMMON_DIR = "C:\\Users\\shingo\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\";
const string    MODULE_FILE = "XTrader.exe";
const bool      HIDE_CONSOLE = true;
const int       FETCH_BARS = SCAN_BARS + UNIT_BARS;

const int POINT_DIMENSION = 8;
const int VECTOR_DIMENSION = POINT_DIMENSION * (SCAN_BARS + 1);
const int VECTOR_DIMENSION_X = POINT_DIMENSION * SCAN_BARS;
const int VECTOR_DIMENSION_Y = POINT_DIMENSION;
const int XX_Size = VECTOR_DIMENSION * SCAN_BARS * HIST_BARS;

const int CORRELATION_BARS = 12 * PeriodSeconds(PERIOD_MN1) / PeriodSeconds(PERIOD);
const int CORRELATION_FETCH_BARS = (FETCH_BARS + 1) + CORRELATION_BARS + 1;
const double ENTRY_CORRELATION = 0.125;

const static int T0 = SCAN_BARS;
const static int T1 = FETCH_BARS - 1;

double XO[];
double XH[];
double XL[];
double XC[];

double Xo[];
double Xh[];
double Xl[];
double Xc[];

double RO[];
double RH[];
double RL[];
double RC[];

double Ro[];
double Rh[];
double Rl[];
double Rc[];

vector XD[];
vector YD[];

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"

#define BARS 2

int Position;
double Lots[2];
double SL;

double R;
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

    if (XX_Size < 0) {
        printf("Array Size exceed 0x7FFFFFFF: VECTOR_DIMENSION = %d, SCAN_BARS = %d, HIST_BARS = %d", VECTOR_DIMENSION, SCAN_BARS, HIST_BARS);
        return INIT_FAILED;
    }

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
    msg += StringFormat("相関係数 %+.4fpt\n", R);
    msg += StringFormat("期待利益 %+.4fpt\n", Performance);
    msg += StringFormat("%s L:%.2f S:%.2f\n", Symbol(), Lots[0], Lots[1]);
    ActiveLabel::Comment(msg);

    if (RemainingMargin() < 10000) {
        ExpertRemove();
        return;
    }

    static long prev_bar = 0;
    long current_bar = (long)(t - PeriodSeconds(PERIOD_M30)) / PeriodSeconds(PERIOD);
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
    int file1 = FileOpen(input_file, FILE_WRITE | FILE_SHARE_WRITE | FILE_COMMON | FILE_BIN);
    if (file1 == INVALID_HANDLE) {
        printf("ERROR(%d): opening dataset file failed: %s: %d", __LINE__, input_file, GetLastError());
        return false;
    }

    double XX[];
    bool result = CreateDataSetVectors(XX, HIST_BARS, n);
    if (!result) {
        FileClose(file1);
        FileDelete(input_file, FILE_COMMON);
        printf("ERROR(%d): creating dataset failed: %d/%d %.3f%%", __LINE__, n, HIST_BARS, 100.0 * n / HIST_BARS);
        return false;
    }

    FileWriteArray(file1, XX);
    FileClose(file1);
    printf("INFO: saved dataset: %d vectors ---> %d cluster levels...", HIST_BARS, CLUSTER_LEVELS);

    string module_path = COMMON_DIR + MODULE_FILE;
    string args = StringFormat("0 %d %d %d %s %s", CLUSTER_LEVELS, VECTOR_DIMENSION, VECTOR_DIMENSION - VECTOR_DIMENSION_X, COMMON_DIR + input_file, COMMON_DIR + output_file);
    printf("%s %s", module_path, args);
    
    KTrader::Execute(module_path, args, HIDE_CONSOLE);

    int file2 = FileOpen(output_file, FILE_READ | FILE_SHARE_READ | FILE_COMMON | FILE_BIN);
    if (file2 == INVALID_HANDLE) {
        printf("ERROR(%d): opening cluster file failed: %s: %d", __LINE__, output_file, GetLastError());
        return false;
    }
    uint count1 = (uint)(FileSize(file2) / sizeof(double));

    double Y0[];
    ArrayResize(Y0, count1);
    uint count2 = FileReadArray(file2, Y0, 0, count1);
    FileClose(file2);
    if (count1 != count2) {
        printf("ERROR(%d): clustering result load failed: %d / %d", count2, count2);
        return false;
    }

    const int clusters = (int)count1 / VECTOR_DIMENSION;
    ArrayResize(XD, clusters);
    ArrayResize(YD, clusters);

    uint k = 0;
    for (int j = 0; j < clusters; ++j) {
        vector x(VECTOR_DIMENSION_X);
        for (int i = 0; i < VECTOR_DIMENSION_X; ++i) {
            x[i] = Y0[k++];
        }
        XD[j] = x;

        vector y(VECTOR_DIMENSION_Y);
        for (int i = 0; i < VECTOR_DIMENSION_Y; ++i) {
            y[i] = Y0[k++];
        }
        YD[j] = y;
        printf("INFO: cluster #%d: performance = %+.5f", j, y[0]);
    }

    if (CLUSTER_LEVELS > 0) {
        FileDelete(input_file, FILE_COMMON);
        FileDelete(output_file, FILE_COMMON);
    }
    else {
        printf("ERROR: result zero cluster");
        ExpertRemove();
    }

    printf("INFO: loaded %d clusters", ArraySize(XD));
    return true;
}

bool CreateDataSetVectors(double& XX[], int N, int& n)
{
    int k = 0;
    ArrayResize(XX, XX_Size);

    for (n = 0; n < N; ++n) {
        datetime t = ::iTime(Symbol(), Period(), n);
        if (CopyOpen(Symbol(), PERIOD, t, FETCH_BARS, XO) != FETCH_BARS) {
            return false;
        }
        if (CopyHigh(Symbol(), PERIOD, t, FETCH_BARS, XH) != FETCH_BARS) {
            return false;
        }
        if (CopyLow(Symbol(), PERIOD, t, FETCH_BARS, XL) != FETCH_BARS) {
            return false;
        }
        if (CopyClose(Symbol(), PERIOD, t, FETCH_BARS, XC) != FETCH_BARS) {
            return false;
        }

        const double XC0 = XC[SCAN_BARS];
        if (!CreateDataSetValue(XC0, XO, Xo)) {
            return false;
        }
        if (!CreateDataSetValue(XC0, XH, Xh)) {
            return false;
        }
        if (!CreateDataSetValue(XC0, XL, Xl)) {
            return false;
        }
        if (!CreateDataSetValue(XC0, XC, Xc)) {
            return false;
        }

        int count = 0;
        if (CopyOpen(Symbol(), PERIOD, t, CORRELATION_FETCH_BARS, RO) != CORRELATION_FETCH_BARS) {
            return false;
        }
        ArrayResize(Ro, FETCH_BARS);
        if ((count = KTrader::CopyCorrelation(CORRELATION_BARS, RO, CORRELATION_FETCH_BARS, Ro, FETCH_BARS)) != FETCH_BARS) {
            printf("ERROR(%d): CopyCorrelation() = %d", __LINE__, count);
            return false;
        }
        if (CopyHigh(Symbol(), PERIOD, t, CORRELATION_FETCH_BARS, RH) != CORRELATION_FETCH_BARS) {
            return false;
        }
        ArrayResize(Rh, FETCH_BARS);
        if ((count = KTrader::CopyCorrelation(CORRELATION_BARS, RH, CORRELATION_FETCH_BARS, Rh, FETCH_BARS)) != FETCH_BARS) {
            printf("ERROR(%d): CopyCorrelation() = %d", __LINE__, count);
            return false;
        }
        if (CopyLow(Symbol(), PERIOD, t, CORRELATION_FETCH_BARS, RL) != CORRELATION_FETCH_BARS) {
            return false;
        }
        ArrayResize(Rl, FETCH_BARS);
        if ((count = KTrader::CopyCorrelation(CORRELATION_BARS, RL, CORRELATION_FETCH_BARS, Rl, FETCH_BARS)) != FETCH_BARS) {
            printf("ERROR(%d): CopyCorrelation() = %d", __LINE__, count);
            return false;
        }
        if (CopyClose(Symbol(), PERIOD, t, CORRELATION_FETCH_BARS, RC) != CORRELATION_FETCH_BARS) {
            return false;
        }
        ArrayResize(Rc, FETCH_BARS);
        if ((count = KTrader::CopyCorrelation(CORRELATION_BARS, RC, CORRELATION_FETCH_BARS, Rc, FETCH_BARS)) != FETCH_BARS) {
            printf("ERROR(%d): CopyCorrelation() = %d", __LINE__, count);
            return false;
        }
        R = Rc[FETCH_BARS - 1];

        for (int i = 0; i < SCAN_BARS; ++i) {
            XX[k++] = Xo[i];
            XX[k++] = Xh[i];
            XX[k++] = Xl[i];
            XX[k++] = Xc[i];
            XX[k++] = Ro[i];
            XX[k++] = Rh[i];
            XX[k++] = Rl[i];
            XX[k++] = Rc[i];
        }
        int i = FETCH_BARS - 1;
        XX[k++] = Xo[i];
        XX[k++] = Xh[i];
        XX[k++] = Xl[i];
        XX[k++] = Xc[i];
        XX[k++] = Ro[i];
        XX[k++] = Rh[i];
        XX[k++] = Rl[i];
        XX[k++] = Rc[i];
    }

    return true;
}

bool CreateDataSetValue(const double XC0, const double& X[], double& x[])
{
    ArrayResize(x, FETCH_BARS);

    for (int i = T1; i >= 0; --i) {
        if (X[i] == 0.0) {
            return false;
        }
        if (MathAbs(X[i]) > 10000) {
            return false;
        }
        x[i] = 1000.0 * (XC0 - X[i]) / XC0;
    }

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

    vector x(VECTOR_DIMENSION_X);
    for (int i = 0; i < VECTOR_DIMENSION_X; ++i) {
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

    double profit = AccountInfoDouble(ACCOUNT_PROFIT);
/*
    if (profit < 0) {
        return;
    }
*/

    if (MathAbs(Performance) < ENTRY_PERFORMANCE) {
        return;
    }

    if (MathAbs(R) < ENTRY_CORRELATION) {
        return;
    }

    int entry = Performance > 0 && R > 0 ? +1 : Performance < 0 && R < 0 ? -1 : 0;
    static int prev_entry = 0;
    if (entry != 0 && entry != prev_entry) {
        ClosePositionAll(StringFormat("Entry(%+d)", entry));
        prev_entry = entry;
    }

    double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
    if (0.0 < margin_level && margin_level < EXIT_LIMIT_MARGIN_LEVEL) {
        ClosePositionAll(StringFormat("Exit(%+.0f/%.2f%%)", profit, margin_level));
        return;
    }

    if (Sgn(R) != Sgn(entry)) {
        ClosePositionAll(StringFormat("R(%+.3f)", R));
        return;
    }

    if (0.0 < margin_level && margin_level < ENTRY_LIMIT_MARGIN_LEVEL) {
        return;
    }

    SL = SL_RATIO * iStdDev(Symbol(), PERIOD, 3 * PeriodSeconds(PERIOD_MN1) / PeriodSeconds(PERIOD), 0, MODE_SMA, PRICE_CLOSE, 0);
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

        double TRAILING_START = SL * 0.5;
        double TRAILING_STEP0 = TRAILING_START * 0.5;
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
