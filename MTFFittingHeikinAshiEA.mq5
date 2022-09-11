//+------------------------------------------------------------------+
//|                                                MTFClustering.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#import "MTFFittingEA.dll"

//--- input parameters
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20220830;
sinput int      SLIPPAGE = 10;

#define BARS (24)
#define TIMEFRAMES ArraySize(timeframes)

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"
#include "TrueTrend.mqh"

sinput string PYTHON_MODULE = "python.exe";
sinput string COMMON_DIR = "C:\\Users\\shingo\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files";
sinput string SCRIPT_FILE = "Clustering2.py";

ENUM_TIMEFRAMES timeframes[] = {
    //PERIOD_M5,
    //PERIOD_M15,
    //PERIOD_M30,
    PERIOD_H1,
    //PERIOD_H2,
    PERIOD_H4,
    //PERIOD_H8,
    PERIOD_D1,
    //PERIOD_W1,
};

enum ENUM_VALUE_TYPES {
    TYPE_HEIKIN_ASHI0,
    TYPE_HEIKIN_ASHI1,
    TYPE_HEIKIN_ASHI2,
    //TYPE_CORRELATION,
    //TYPE_PRICE,
    //TYPE_RSI,
    //TYPE_MACD,
    //TYPE_ADX,
    MAX_TYPE
};

const int HIST_BARS = 4 * PeriodSeconds(PERIOD_W1) / PeriodSeconds(timeframes[0]);

//--- the number of indicator buffer for storage Open
#define  HA_OPEN     0
//--- the number of the indicator buffer for storage High
#define  HA_HIGH     1
//--- the number of indicator buffer for storage Low
#define  HA_LOW      2
//--- the number of indicator buffer for storage Close
#define  HA_CLOSE    3

int hHeikinAshi[TIMEFRAMES];
double SL;

MQL45_APPLICATION_START()

vector History[];
vector Profit[];

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
    ActiveLabel::POSITION_X = 360;

    for (int i = 0; i < TIMEFRAMES; ++i) {
        hHeikinAshi[i] = iCustom(Symbol(), timeframes[i], "Examples\\Heiken_Ashi");
    }

    const long DAY = 24 * 3600;
    datetime T0 = (datetime)((TimeCurrent() / DAY) * DAY);
    Clustering(T0);

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    MTFFitting::Execute("taskkill.exe", "/f /im " + PYTHON_MODULE);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    static long prev_minute = 0;
    long current_minute = TimeCurrent() / 60;
    if (current_minute > prev_minute) {
        prev_minute = current_minute;
        TrailingStop();
    }

    static long prev_day = 0;
    long current_day = TimeCurrent() / PeriodSeconds(PERIOD_D1);
    if (current_day > prev_day) {
        prev_day = current_day;
        if (!Clustering(TimeCurrent())) {
            return;
        }
    }

    static long prev_bar = 0;
    long current_bar = TimeCurrent() / PeriodSeconds(timeframes[0]);
    if (current_bar > prev_bar) {
        prev_bar = current_bar;
        Trade();
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void Trade()
{
    if (ArraySize(History) == 0 || ArraySize(Profit) == 0) {
        return;
    }

    vector x0;
    double norm[];
    int K = 0;
    if (!GetVector(TimeCurrent(), BARS, K, x0, norm)) {
        return;
    }

/*
    static double prev_correlation;
    double current_correlation = norm[TYPE_CORRELATION * TIMEFRAMES + 4];
    if (Sgn(prev_correlation) != Sgn(current_correlation)) {
        ClosePositionAll();
    }
    prev_correlation = current_correlation;
*/

    double performance = 0;
    int k_min = 0;
    double d_min = +FLT_MAX;
    for (int k = 0; k < ArraySize(History); ++k) {
        vector h0 = History[k];
        vector d = x0 - h0;
        double d0 = d.Norm(VECTOR_NORM_INF);
        if (d0 < d_min) {
            k_min = k;
            d_min = d0;
        }
    }

    vector p0 = Profit[k_min];
    double p_max = 0;
    int k_max = -1;
    int entry = 0;
    for (int k = 0; k < TIMEFRAMES; ++k) {
        double p = p0[k];
        if (MathAbs(p) > p_max) {
            p_max = MathAbs(p);
            k_max = k;
            entry = p > 0 ? OP_BUY : OP_SELL;
        }
    }

    CloseLimitPosition(entry);

    if (p_max < 500) {
        return;
    }

    SL = norm[0];
    string comment = IntegerToString(PeriodSeconds(timeframes[k_max]) / 3600);
    if (entry == OP_BUY) {
        double sl = NormalizeDouble(Bid - SL, Digits);
        if (!OrderSend(Symbol(), OP_BUY, LOTS, Ask, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrBlue)) {
            Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
        }
    } else if (entry == OP_SELL) {
        double sl = NormalizeDouble(Ask + SL, Digits);
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
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }

        double TRAILING_START = 1.5 * SL;
        double TRAILING_STEP = 0.25 * SL;

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        int digits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
        if (type == OP_BUY && profit_price > TRAILING_START) {
            double sl = NormalizeDouble(price - TRAILING_STEP, digits);
            double tp = 0;
            if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
            }
        } else if (type == OP_SELL && profit_price > TRAILING_START) {
            double sl = NormalizeDouble(price + TRAILING_STEP, digits);
            double tp = 0;
            if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void CloseLimitPosition(int entry)
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

        datetime entry_time = OrderOpenTime();
        if (TimeCurrent() - entry_time < 3600 * StringToInteger(OrderComment())) {
            continue;
        }

        if (OrderType() == entry) {
            continue;
        }

        int ticket = OrderTicket();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        double lots = OrderLots();
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void ClosePositionAll()
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
        OrderCloseComment(StringFormat("%+.0f", OrderProfit() + OrderSwap()));
        if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
int GetPositionCount()
{
    int n = 0;
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
        ++n;
    }
    return n;
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

//+------------------------------------------------------------------+
//| T0より前を最終時刻とするクラスタリングを実行する                 |
//+------------------------------------------------------------------+
bool Clustering(datetime T0)
{
    const int N = BARS;
    const int M = TIMEFRAMES;

    string input_file = Symbol() + "-IN.csv";
    string output_file = Symbol() + "-OUT.csv";
    int file1 = FileOpen(input_file, FILE_WRITE | FILE_SHARE_READ | FILE_COMMON | FILE_TXT | FILE_ANSI);

    datetime t0 = 0;
    int K = 0;
    vector xx;
    int k = GetShift(timeframes[0], K, T0);
    for (int i = 0; i < HIST_BARS; ++i) {
        vector x;
        double norm[];
        datetime t1 = ::iTime(Symbol(), timeframes[0], k + i);
        if (!GetVector(t1, k + i, N + 1, x, norm)) {
            FileClose(file1);
            return false;
        }
        if (xx.Size() > 0 && xx == x) {
            printf("WARNING: vector is same!");
        }
        xx = x;
        WriteLine(file1, x);
    }
    FileFlush(file1);
    FileClose(file1);

    string script_path = COMMON_DIR + "\\" + SCRIPT_FILE;
    string input_path = COMMON_DIR + "\\" + input_file;
    string output_path = COMMON_DIR + "\\" + output_file;
    string args = StringFormat("%s %d %d %s %s", script_path, BARS * MAX_TYPE, TIMEFRAMES, input_path, output_path);
    string result = MTFFitting::Execute(PYTHON_MODULE, args);
    if (result != "") {
        printf(args);
        printf(result);
    }

    int file2 = FileOpen(output_file, FILE_READ | FILE_SHARE_READ | FILE_COMMON | FILE_CSV | FILE_ANSI);
    while (true) {
        string line = FileReadString(file2);
        string x0[];
        const int N0 = StringSplit(line, ',', x0);
        if (N0 == 0) {
            break;
        }
        const int N1 = MAX_TYPE * N * M;
        vector x1(N0);
        for (int i = 0; i < N0; ++i) {
            x1[i] = StringToDouble(x0[i]);
        }
        vector x2(N1);
        for (int i = 0; i < N1; ++i) {
            x2[i] = x1[i];
        }
        vector x3(M);
        for (int i = 0; i < M; ++i) {
            x3[i] = x1[N1 + i];
        }
        Append(History, x2);
        Append(Profit,  x3);
    }
    FileClose(file2);
    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Append(vector& v[], vector& v0)
{
    int n = ArraySize(v);
    ArrayResize(v, n + 1, n);
    v[n] = v0;
}

//+------------------------------------------------------------------+
//| 配列をファイルに書き出す                                         |
//+------------------------------------------------------------------+
void WriteLine(int file, const vector& x)
{
    ulong N = x.Size();
    string line = "";
    for (ulong i = 0; i < N; ++i) {
        line += StringFormat("%.10f", x[i]);
        line += i < N - 1 ? "," : "\n";
    }
    FileWriteString(file, line);
}

//+------------------------------------------------------------------+
//| T0より前を最終時刻とするマルチタイムフレームのベクトルを返す     |
//+------------------------------------------------------------------+
bool GetVector(datetime T0, int K, int N, vector& X, double& norm[])
{
    int p = N > BARS ? TIMEFRAMES : 0;

    int k[];
    ArrayResize(k, TIMEFRAMES);
    for (int i = 0; i < TIMEFRAMES; ++i) {
        k[i] = GetShift(timeframes[i], K >> i, T0);
    }

    for (int type = 0; type < MAX_TYPE; ++type) {
        Expand(norm, TIMEFRAMES);
        for (int i = 0; i < TIMEFRAMES; ++i) {
            vector x;
            if (!GetVector(timeframes[i], i, (ENUM_VALUE_TYPES)type, BARS, k[i] + 1, x, norm[i])) {
                return false;
            }
            Append(X, x);
        }
    }

    if (N > BARS) {
        vector profit(TIMEFRAMES);
        for (int i = 0; i < TIMEFRAMES; ++i) {
            double p1 = ::iOpen(Symbol(), timeframes[i], k[i] + 1);
            double p0 = ::iOpen(Symbol(), timeframes[i], k[i] + 0);
            profit[i] = (p1 - p0) / Point();
        }
        Append(X, profit);
    }

    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Append(vector& X, const vector& x)
{
    ulong N = x.Size();
    ulong M = X.Size();
    X.Resize(M + N, M);
    for (ulong i = 0; i < N; ++i) {
        X[M + i] = x[i];
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Expand(double& array[], int M)
{
    int N = ArraySize(array);
    ArrayResize(array, N + M, N);
}

//+------------------------------------------------------------------+
//| T0より前を最終時刻とする指定されたタイムフレームのベクトルを返す |
//+------------------------------------------------------------------+
bool GetVector(ENUM_TIMEFRAMES tf, int tf_index, ENUM_VALUE_TYPES type, int N, int k, vector& x, double& norm)
{
    x.Resize(N);
    
    if (type == TYPE_HEIKIN_ASHI0) {
        datetime t0 = ::iTime(Symbol(), tf, k + N);
        double open[];
        double close[];
        if (CopyBuffer(hHeikinAshi[tf_index], HA_OPEN, t0, N, open) != N) { return false; }
        if (CopyBuffer(hHeikinAshi[tf_index], HA_CLOSE, t0, N, close) != N) { return false; }
        for (int i = 0; i < N; ++i) {
            x[i] = close[i] - open[i];
        }
        norm = x.Norm(VECTOR_NORM_INF);
        x /= ::iOpen(Symbol(), tf, k + N) / 100;
    }
    if (type == TYPE_HEIKIN_ASHI1) {
        datetime t0 = ::iTime(Symbol(), tf, k + N);
        double high[];
        double close[];
        if (CopyBuffer(hHeikinAshi[tf_index], HA_HIGH, t0, N, high) != N) { return false; }
        if (CopyBuffer(hHeikinAshi[tf_index], HA_CLOSE, t0, N, close) != N) { return false; }
        for (int i = 0; i < N; ++i) {
            x[i] = high[i] - close[i];
        }
        norm = x.Norm(VECTOR_NORM_INF);
        x /= ::iOpen(Symbol(), tf, k + N) / 100;
    }
    if (type == TYPE_HEIKIN_ASHI2) {
        datetime t0 = ::iTime(Symbol(), tf, k + N);
        double low[];
        double open[];
        if (CopyBuffer(hHeikinAshi[tf_index], HA_LOW, t0, N, low) != N) { return false; }
        if (CopyBuffer(hHeikinAshi[tf_index], HA_OPEN, t0, N, open) != N) { return false; }
        for (int i = 0; i < N; ++i) {
            x[i] = open[i] - low[i];
        }
        norm = x.Norm(VECTOR_NORM_INF);
        x /= ::iOpen(Symbol(), tf, k + N) / 100;
    }
/*
    if (type == TYPE_CORRELATION) {
        norm = 0;
        for (int i = 0; i < N; ++i) {
            x[N - i - 1] = iCorrelation(Symbol(), tf, tf_index, BARS, k + i);
            if (x[N - i - 1] == 0) {
                Alert(StringFormat("ERROR: iRSI(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
            norm += x[N - i - 1];
        }
    }
    if (type == TYPE_PRICE) {
        double v[];
        ArrayResize(v, N + 1);
        for (int i = 0; i < N + 1; ++i) {
            v[N - i] = ::iOpen(Symbol(), tf, k + i);
            if (v[N - i] == 0) {
                Alert(StringFormat("ERROR: iOpen(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
        }
        for (int i = 1; i <= N; ++i) {
            x[i - 1] = (v[i] - v[0]) / Point();
        }
    }
    if (type == TYPE_RSI) {
        double v[];
        ArrayResize(v, N + 1);
        for (int i = 0; i < N + 1; ++i) {
            v[N - i] = iRSI(Symbol(), tf, BARS, PRICE_OPEN, k + i);
            if (v[N - i] == 0) {
                Alert(StringFormat("ERROR: iRSI(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
        }
        for (int i = 0; i < N; ++i) {
            x[i] = (v[i] - 50.0) / 50.0;
        }
    }
    if (type == TYPE_MACD) {
        double v[];
        ArrayResize(v, N + 1);
        for (int i = 0; i < N + 1; ++i) {
            v[N - i] = iMACD(Symbol(), tf, 12, 26, 9, PRICE_OPEN, MODE_MAIN, k + i);
            if (v[N - i] == 0) {
                Alert(StringFormat("ERROR: iMACD(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
        }
        for (int i = 0; i < N; ++i) {
            x[i] = v[i];
        }
    }
    if (type == TYPE_ADX) {
        double d1[];
        ArrayResize(d1, N + 1);
        double d0[];
        ArrayResize(d0, N + 1);
        for (int i = 0; i < N + 1; ++i) {
            d1[N - i] = iADX(Symbol(), tf, 14, PRICE_OPEN, MODE_PLUSDI, k + i);
            if (d1[N - i] == 0) {
                Alert(StringFormat("ERROR: iADX(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
            d0[N - i] = iADX(Symbol(), tf, 14, PRICE_OPEN, MODE_MINUSDI, k + i);
            if (d0[N - i] == 0) {
                Alert(StringFormat("ERROR: iADX(%s) FAILD: %d", EnumToString(tf), GetLastError()));
                return false;
            }
        }
        for (int i = 0; i < N; ++i) {
            x[i] = d1[i] - d0[i];
        }
    }
*/

    return true;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(string symbol, ENUM_TIMEFRAMES tf, int tf_index, int N, int k)
{
    datetime t0 = ::iTime(Symbol(), tf, k + N);
    double open[];
    if (CopyBuffer(hHeikinAshi[tf_index], HA_OPEN, t0, N, open) != N) { return 0.0; }

    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = i;
        double y = open[i];
        if (y == 0) { return 0.0; }
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = i - avr_x;
        double y = open[i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//| 指定されたタイムフレーム・時刻より前の時刻を表すシフトを返す     |
//+------------------------------------------------------------------+
int GetShift(ENUM_TIMEFRAMES tf, int K, datetime t0)
{
    int k = K;
    while (true) {
        datetime t = ::iTime(Symbol(), tf, k);
        if (t < t0) {
            break;
        }
        ++k;
    }
    return k;
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
