//+------------------------------------------------------------------+
//|                                                MTFClustering.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#import "KTraderEA.dll"

//--- input parameters
const int       CLUSTERS = 3;
const int       HIST_BARS = 3 * 12;
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20220830;
sinput int      SLIPPAGE = 10;

const int       BARS = 12;

#define TIMEFRAMES ArraySize(timeframes)

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"
#include "TrueTrend.mqh"

const int     CORRELATION_BARS = BARS;
sinput string MODULE = "KTrader.exe";
sinput string COMMON_DIR = "C:\\Users\\shingo\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files";

#define USE_HEIKIN_ASHI
//#define USE_ADX
//#define USE_RSI
//#define USE_MACD
#define USE_CORRELATION

ENUM_TIMEFRAMES timeframes[] = {
    //PERIOD_M1,
    //PERIOD_M2,
    //PERIOD_M3,
    //PERIOD_M4,
/*
    PERIOD_M5,
    PERIOD_M6,
    PERIOD_M12,
    PERIOD_M15,
    PERIOD_M20,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H2,
    PERIOD_H3,
    PERIOD_H4,
    PERIOD_H6,
    PERIOD_H8,
    PERIOD_H12,
*/
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1,
};

#define TRADE_TF_INDEX 2

enum ENUM_VALUE_TYPES {
    TYPE_SD,
#ifdef USE_HEIKIN_ASHI
    TYPE_HEIKIN_ASHI0,
    TYPE_HEIKIN_ASHI1,
    TYPE_HEIKIN_ASHI2,
    TYPE_HEIKIN_ASHI3,
#endif
#ifdef USE_BB_TREND
    TYPE_BB_TREND,
#endif
#ifdef USE_ADX
    TYPE_ADX,
#endif
#ifdef USE_RSI
    TYPE_RSI,
#endif
#ifdef USE_MACD
    TYPE_MACD,
#endif
#ifdef USE_CORRELATION
    TYPE_CORRELATION,
#endif
//TYPE_PRICE,
    MAX_TYPE
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
const int COLUMNS = (MAX_TYPE * BARS * TIMEFRAMES) + TIMEFRAMES;

//--- the number of indicator buffer for storage Open
#define  HA_OPEN     0
//--- the number of the indicator buffer for storage High
#define  HA_HIGH     1
//--- the number of indicator buffer for storage Low
#define  HA_LOW      2
//--- the number of indicator buffer for storage Close
#define  HA_CLOSE    3

double SL;

struct TF_ITEM {
    datetime         t0;
#ifdef USE_SD
    int              hSD;
    double           sd[];
#endif
#ifdef USE_HEIKIN_ASHI
    int              hHeikinAshi;
    double           open[];
    double           high[];
    double           low[];
    double           close[];
#endif
#ifdef USE_BB_TREND
    int              hBB20;
    int              hBB50;
    double           BB20M[];
    double           BB20U[];
    double           BB20L[];
    double           BB50U[];
    double           BB50L[];
#endif
#ifdef USE_ADX
    int              hADX;
    double           DI1[];
    double           DI0[];
#endif
#ifdef USE_RSI
    int              hRSI;
    double           RSI[];
#endif
#ifdef USE_MACD
    int              hMACD;
    double           MACD[];
#endif
};
TF_ITEM TF[TIMEFRAMES];

const int SCAN_BARS = HIST_BARS + BARS;
int scanned_bars;

double Performance;

vector History[];
vector Profit[];

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
    ActiveLabel::POSITION_X = 200;

    for (int i = 0; i < TIMEFRAMES; ++i) {
#ifdef USD_SD
        TF[i].hSD = iStdDev(Symbol(), timeframes[i], 24, 0, MODE_SMA, PRICE_OPEN);
#endif
#ifdef USE_HEIKIN_ASHI
        TF[i].hHeikinAshi = iCustom(Symbol(), timeframes[i], "Examples\\Heiken_Ashi");
#endif
#ifdef USE_BB_TREND
        TF[i].hBB20 = iBands(Symbol(), timeframes[i], 20, 3.0, 0, PRICE_OPEN);
        TF[i].hBB50 = iBands(Symbol(), timeframes[i], 50, 3.0, 0, PRICE_OPEN);
#endif
#ifdef USE_ADX
        TF[i].hADX = ::iADX(Symbol(), timeframes[i], 14);
#endif
#ifdef USE_RSI
        TF[i].hRSI = ::iRSI(Symbol(), timeframes[i], 14, PRICE_OPEN);
#endif
#ifdef USE_MACD
        TF[i].hMACD = ::iMACD(Symbol(), timeframes[i], 9, 26, 9, PRICE_OPEN);
#endif
    }

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    KTrader::Execute("taskkill.exe", "/f /im " + MODULE, true);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime t = TimeCurrent();

    static long prev_bar = 0;
    long current_bar = t / PeriodSeconds(timeframes[TIMEFRAMES - 1]);
    if (current_bar > prev_bar) {
        prev_bar = current_bar;
        ++scanned_bars;
    }

    double lots[2];
    GetPositionCount(lots);

    string msg = "";
    string wdays[] = { "日", "月", "火", "水", "木", "金", "土" };

    msg += TimeToString(t, TIME_DATE) + "(" + wdays[TimeDayOfWeek(t)] + ") " + TimeToString(t, TIME_SECONDS) + "\n";
    msg += StringFormat("%.0f %+.0f %.0f%%\n", AccountBalance(), AccountProfit(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    msg += StringFormat("%s L:%.2f S:%.2f\n", Symbol(), lots[0], lots[1]);
    msg += StringFormat("期待利益：%+.4fbp\n", Performance);
    msg += StringFormat("進捗: %.3f%%\n", 100.0 * scanned_bars / HIST_BARS);
    ActiveLabel::Comment(msg);

    if (scanned_bars < HIST_BARS) {
        return;
    }

    if (RemainingMargin() < 1000) {
        ExpertRemove();
        return;
    }

    if (RemainingBalance() + AccountProfit() < 10000) {
        ClosePositionAll();
    }

    static long prev_minute = 0;
    long current_minute = t / 60;
    if (current_minute > prev_minute) {
        prev_minute = current_minute;
        TrailingStop();
    }

    static long prev_wday = -1;
    long current_wday = TimeDayOfWeek(t);
    static datetime prev_clustering_done = 0;
    datetime clustering_done = t;
    if (current_wday != prev_wday && clustering_done > prev_clustering_done) {
        prev_wday = current_wday;
        if (current_wday == 1) {
            if (Clustering(t)) {
                prev_clustering_done = clustering_done;
                return;
            }
        }
    }

    static long prev_trade = 0;
    long current_trade = TimeCurrent() / PeriodSeconds(PERIOD_H1);
    if (current_trade > prev_trade) {
        prev_trade = current_trade;
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

    iX = 0;
    ArrayResize(X, COLUMNS - TIMEFRAMES);

    int K = 0;
    if (!GetVector(TimeCurrent(), K, BARS)) {
        return;
    }
    vector x0(ArraySize(X));
    for (int i = 0; i < ArraySize(X); ++i) {
        x0[i] = X[i];
    }

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
    Performance = -FLT_MAX;
    int l_max = -1;
    int entry = 0;
    for (int l = 0; l < TIMEFRAMES; ++l) {
        double p = p0[l];
        if (MathAbs(p) > Performance) {
            Performance = MathAbs(p);
            l_max = l;
            entry = p > 0 ? OP_BUY : OP_SELL;
        }
    }

    if (CloseLimitPosition(entry)) {
        return;
    }

    if (AccountInfoDouble(ACCOUNT_PROFIT) < 0) {
        return;
    }

    if (Performance < 0.75) {
        return;
    }

    SL = 100.0 / Ask * 2;
    string comment = IntegerToString(PeriodSeconds(timeframes[l_max]) / 3600);
    if (entry == OP_BUY) {
        double sl = SL > 0 ? NormalizeDouble(Bid - SL, Digits) : 0;
        if (!OrderSend(Symbol(), OP_BUY, LOTS, Ask, SLIPPAGE, sl, 0, comment, MAGIC, 0, clrBlue)) {
            Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
        }
    } else if (entry == OP_SELL) {
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
    int minute = TimeMinute(TimeCurrent());
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }

        int ticket = OrderTicket();
        if ((ticket % 60) != minute) {
            continue;
        }

        double TRAILING_START = SL / 3;

        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        int digits = (int)MarketInfo(OrderSymbol(), MODE_DIGITS);
        if (type == OP_BUY && profit_price > TRAILING_START) {
            double sl = NormalizeDouble(price - SL, digits);
            double tp = 0;
            if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
            }
        } else if (type == OP_SELL && profit_price > TRAILING_START) {
            double sl = NormalizeDouble(price + SL, digits);
            double tp = 0;
            if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                //printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
bool CloseLimitPosition(int entry)
{
    double min_profit = +FLT_MAX;
    int min_ticket = -1;

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

        double profit = OrderProfit();
        if (profit < min_profit) {
            min_profit = profit;
            min_ticket = OrderTicket();
        }
    }

    if (min_ticket != -1 && OrderSelect(min_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        int ticket = OrderTicket();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        double lots = OrderLots();
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
        return true;
    }

    return false;
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
        double profit = OrderProfit() + OrderSwap();
        OrderCloseComment(StringFormat("Account SL %+.0f", profit));
        if (!OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            //printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
int GetPositionCount(double& lots[])
{
    int n = 0;
    lots[0] = lots[1] = 0;
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
        lots[OrderType() == OP_BUY ? 0 : 1] += OrderLots();
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

double X[];
int iTotalX;
int iX;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Append(double x, ENUM_TIMEFRAMES tf, int type)
{
    double M = MathLog10((double)PeriodSeconds(tf) / PeriodSeconds(timeframes[0])) + 1.0;
    double x1 = type > 0 ? x * M : x / M;
    if (MathAbs(x1) > 10000) {
        DebugBreak();
    }
    if (iX >= ArraySize(X)) {
        DebugBreak();
    }
    X[iX++] = x1;
}

//+------------------------------------------------------------------+
//| T0より前を最終時刻とするクラスタリングを実行する                 |
//+------------------------------------------------------------------+
bool Clustering(datetime T0)
{
    const int N = BARS;
    const int M = TIMEFRAMES;
    iTotalX = HIST_BARS * COLUMNS;
    ArrayResize(X, iTotalX);
    iX = 0;

    string input_file = Symbol() + "-IN.bin";
    string output_file = Symbol() + "-OUT.bin";
    int file1 = FileOpen(input_file, FILE_WRITE | FILE_SHARE_READ | FILE_COMMON | FILE_BIN);

    datetime t0 = 0;
    int K = 0;
    int k = GetShift(timeframes[0], K, T0);
    long percentage = 0;
    for (int i = 0; i < HIST_BARS; ++i) {
        datetime t1 = ::iTime(Symbol(), timeframes[0], k + i);
        if (!GetVector(t1, k + i, N + 1)) {
            FileClose(file1);
            return false;
        }
        long current_percentage = 100 * (long)i / (long)HIST_BARS;
        if (current_percentage > percentage) {
            percentage = current_percentage;
            //printf("INFO: creating dataset: %d/%d %d%%", i, HIST_WEEKS, percentage);
        }
    }
    FileWriteArray(file1, X, 0, iX);
    FileClose(file1);
    printf("INFO: saved dataset: %d vectors ---> %d clusters...", HIST_BARS, CLUSTERS);

    string input_path = COMMON_DIR + "\\" + input_file;
    string output_path = COMMON_DIR + "\\" + output_file;
    string args = StringFormat("%d %d %d %s %s", CLUSTERS, COLUMNS, 0, input_path, output_path);
    printf("INFO: %s %s", MODULE, args);
    string result = KTrader::Execute(COMMON_DIR + "\\" + MODULE, args, true);

    int file2 = FileOpen(output_file, FILE_READ | FILE_SHARE_READ | FILE_COMMON | FILE_BIN);
    uint n = 0;
    uint total = (uint)(FileSize(file2) / sizeof(double));
    double x1[];
    ArrayResize(x1, total);
    uint total2 = FileReadArray(file2, x1, 0, total);
    FileClose(file2);
    if (total != total2) {
        printf("ERROR: clustering result load failed: %d / %d", total2, total);
        return false;
    }

    int N1 = COLUMNS - TIMEFRAMES;
    ArrayResize(History, 0);
    ArrayResize(Profit, 0);
    while (n < total) {
        vector x2(N1);
        for (int i = 0; i < N1; ++i) {
            x2[i] = x1[n++];
        }
        Append(History, x2);

        vector x3(M);
        for (int i = 0; i < M; ++i) {
            x3[i] = x1[n++];
        }
        Append(Profit,  x3);
    }
    printf("INFO: loaded %d clusters", ArraySize(Profit));

    return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Append(vector & v[], vector & v0)
{
    int n = ArraySize(v);
    ArrayResize(v, n + 1, n);
    v[n] = v0;
}

//+------------------------------------------------------------------+
//| T0より前を最終時刻とするマルチタイムフレームのベクトルを返す     |
//+------------------------------------------------------------------+
bool GetVector(datetime T0, int K, int N)
{
    int p = N > BARS ? TIMEFRAMES : 0;

    int k[];
    ArrayResize(k, TIMEFRAMES);
    for (int i = TIMEFRAMES - 1; i >= 0; --i) {
        k[i] = GetShift(timeframes[i], K >> i, T0);
    }

    for (int i = TIMEFRAMES - 1; i >= 0; --i) {
        for (int type = 0; type < MAX_TYPE; ++type) {
            if (!GetVector(timeframes[i], i, (ENUM_VALUE_TYPES)type, BARS, k[i] + 1)) {
                return false;
            }
        }
    }

    if (N > BARS) {
        for (int i = 0; i < TIMEFRAMES; ++i) {
            double pC = ::iOpen(Symbol(), timeframes[i], k[i] + 1);
            double pF = ::iOpen(Symbol(), timeframes[i], k[i] + 0);
            Append((pF - pC) / pC * 10000.0, timeframes[0], -1);
        }
    }

    return true;
}

//+------------------------------------------------------------------+
//| T0より前を最終時刻とする指定されたタイムフレームのベクトルを返す |
//+------------------------------------------------------------------+
bool GetVector(ENUM_TIMEFRAMES tf, int tf_index, ENUM_VALUE_TYPES type, int N, int k)
{
    int NN = N + 1;
    const double x0 = ::iOpen(Symbol(), tf, k + NN) / 100;
    if (x0 == 0.0) {
        //printf("ERROR: iOpen(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
        return false;
    }

    datetime t = ::iTime(Symbol(), tf, k + N);
    if (t > TF[tf_index].t0) {
        TF[tf_index].t0 = t;
#ifdef USE_SD
        if (CopyBuffer(TF[tf_index].hSD, MAIN_LINE, t, NN, TF[tf_index].sd) != NN) {
            //printf("ERROR: HA_OPEN(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
#ifdef USE_HEIKIN_ASHI
        if (CopyBuffer(TF[tf_index].hHeikinAshi, HA_OPEN, t, NN, TF[tf_index].open) != NN) {
            //printf("ERROR: HA_OPEN(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hHeikinAshi, HA_HIGH, t, NN, TF[tf_index].high) != NN) {
            //printf("ERROR: HA_HIGH(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hHeikinAshi, HA_LOW, t, NN, TF[tf_index].low) != NN) {
            //printf("ERROR: HA_LOW(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hHeikinAshi, HA_CLOSE, t, NN, TF[tf_index].close) != NN) {
            //printf("ERROR: HA_CLOSE(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
#ifdef USE_BB_TREND
        if (CopyBuffer(TF[tf_index].hBB20, MAIN_LINE, t, NN, TF[tf_index].BB20M) != NN) {
            //printf("ERROR: BB20M(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hBB20, UPPER_LINE, t, NN, TF[tf_index].BB20U) != NN) {
            //printf("ERROR: BB20U(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hBB20, LOWER_LINE, t, NN, TF[tf_index].BB20L) != NN) {
            //printf("ERROR: BB20L(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hBB50, UPPER_LINE, t, NN, TF[tf_index].BB50U) != NN) {
            //printf("ERROR: BB50U(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hBB50, LOWER_LINE, t, NN, TF[tf_index].BB50L) != NN) {
            //printf("ERROR: BB50L(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
#ifdef USE_ADX
        if (CopyBuffer(TF[tf_index].hADX, PLUSDI_LINE, t, NN, TF[tf_index].DI1) != NN) {
            //printf("ERROR: DI1(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (CopyBuffer(TF[tf_index].hADX, MINUSDI_LINE, t, NN, TF[tf_index].DI0) != NN) {
            //printf("ERROR: DI0(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
#ifdef USE_RSI
        if (CopyBuffer(TF[tf_index].hRSI, MAIN_LINE, t, NN, TF[tf_index].RSI) != NN) {
            //printf("ERROR: RSI(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
#ifdef USE_MACD
        if (CopyBuffer(TF[tf_index].hMACD, MAIN_LINE, t, NN, TF[tf_index].MACD) != NN) {
            //printf("ERROR: MACD(%s) FAILD: %d: %d/%d %.2f%%", EnumToString(tf), GetLastError(), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
#endif
    }

#ifdef USE_SD
    if (type == TYPE_SD) {
        if (ArraySize(TF[tf_index].sd) < NN) {
            //printf("ERROR: SD(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            double sdr = TF[tf_index].sd[i] / x0;
            if (sdr < 0 || 10 < sdr) {
                //printf("ERROR: SD(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
                return false;
            }
            Append(sdr, tf);
        }
    }
#endif
#ifdef USE_HEIKIN_ASHI
    if (type == TYPE_HEIKIN_ASHI0) {
        if (ArraySize(TF[tf_index].open) < NN) {
            //printf("ERROR: HA_OPEN(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            Append((TF[tf_index].open[i] - TF[tf_index].open[i - 1]) / x0, tf, +1);
        }
    }

    if (type == TYPE_HEIKIN_ASHI1) {
        if (ArraySize(TF[tf_index].open) < NN) {
            //printf("ERROR: HA_OPEN(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].close) < NN) {
            //printf("ERROR: HA_CLOSE(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            Append((TF[tf_index].close[i] - TF[tf_index].open[i]) / x0, tf, +1);
        }
    }
    if (type == TYPE_HEIKIN_ASHI2) {
        if (ArraySize(TF[tf_index].high) < NN) {
            //printf("ERROR: HA_HIGH(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].close) < NN) {
            //printf("ERROR: HA_CLOSE(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            Append((TF[tf_index].high[i] - TF[tf_index].close[i]) / x0, tf, +1);
        }
    }
    if (type == TYPE_HEIKIN_ASHI3) {
        if (ArraySize(TF[tf_index].open) < NN) {
            //printf("ERROR: HA_OPEN(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].low) < NN) {
            //printf("ERROR: HA_LOW(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            Append((TF[tf_index].open[i] - TF[tf_index].low[i]) / x0, tf, +1);
        }
    }
#endif
#ifdef USE_BB_TREND
    if (type == TYPE_BB_TREND) {
        if (ArraySize(TF[tf_index].BB20M) < NN) {
            //printf("ERROR: BB20M(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].BB20U) < NN) {
            //printf("ERROR: BB20U(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].BB20L) < NN) {
            //printf("ERROR: BB20L(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].BB50U) < NN) {
            //printf("ERROR: BB50U(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].BB50L) < NN) {
            //printf("ERROR: BB50L(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            if (TF[tf_index].BB20M[i] == 0.0) {
                //printf("ERROR: BB20M(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            }
            if (TF[tf_index].BB20U[i] == 0.0) {
                //printf("ERROR: BB20U(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            }
            if (TF[tf_index].BB20L[i] == 0.0) {
                //printf("ERROR: BB20L(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            }
            if (TF[tf_index].BB50U[i] == 0.0) {
                //printf("ERROR: BB50U(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            }
            if (TF[tf_index].BB50L[i] == 0.0) {
                //printf("ERROR: BB50L(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            }
            double Upper = MathAbs(TF[tf_index].BB20U[i] - TF[tf_index].BB50U[i]);
            double Lower = MathAbs(TF[tf_index].BB20L[i] - TF[tf_index].BB50L[i]);
            Append(10000 * (Lower - Upper) / TF[tf_index].BB20M[i], tf);
        }
    }
#endif
#ifdef USE_ADX
    if (type == TYPE_ADX) {
        if (ArraySize(TF[tf_index].DI1) < NN) {
            //printf("ERROR: DI1(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        if (ArraySize(TF[tf_index].DI0) < NN) {
            //printf("ERROR: DI0(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            Append((TF[tf_index].DI1[i] - TF[tf_index].DI0[i]) / 100.0, tf);
        }
    }
#endif
#ifdef USE_RSI
    if (type == TYPE_RSI) {
        if (ArraySize(TF[tf_index].RSI) < NN) {
            //printf("ERROR: RSI(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 1; i < NN; ++i) {
            if (TF[tf_index].RSI[i] < -100 || +100 < TF[tf_index].RSI[i]) {
                //printf("ERROR: RSI(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
                return false;
            }
            Append((TF[tf_index].RSI[i] - 50) / 50, tf);
        }
    }
#endif
#ifdef USE_MACD
    if (type == TYPE_MACD) {
        for (int i = 1; i < NN; ++i) {
            if (TF[tf_index].MACD[i] < -100 || +100 < TF[tf_index].MACD[i]) {
                //printf("ERROR: MACD(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
                return false;
            }
            Append(TF[tf_index].MACD[i] / x0, tf);
        }
    }
#endif
#ifdef USE_CORRELATION
    if (type == TYPE_CORRELATION) {
        datetime t0 = ::iTime(Symbol(), tf, k + N + CORRELATION_BARS);
        double X0[];
        if (CopyOpen(Symbol(), tf, t0, N + CORRELATION_BARS, X0) != N + CORRELATION_BARS) {
            //printf("ERROR: CopyOpen(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }

        double X1[];
        ArrayResize(X1, N);
        int count = KTrader::CopyCorrelation(CORRELATION_BARS, X0, ArraySize(X0), X1, ArraySize(X1));
        if (count != N) {
            //printf("ERROR: CopyCorrelation(%s) FAILD: %d/%d %.2f%%", EnumToString(tf), iX, iTotalX, 100.0 * iX / iTotalX);
            return false;
        }
        for (int i = 0; i < N; ++i) {
            Append(5 * X1[i], tf, +1);
        }
    }
#endif
#ifdef USE_PRICE
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
#endif

    return true;
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
