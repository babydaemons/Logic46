//+------------------------------------------------------------------+
//|                                                    KuChartEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"

enum LONG_PERIOD {
    TF_D01 = PERIOD_D1,
    TF_W01 = PERIOD_W1,
    TF_MN1 = PERIOD_MN1,
};

enum SHORT_PERIOD {
    TF_M05 = PERIOD_M5,
    TF_M15 = PERIOD_M15,
    TF_M30 = PERIOD_M30,
    TF_H01 = PERIOD_H1,
    TF_H04 = PERIOD_H4,
};

input LONG_PERIOD TF1 = TF_D01;
input SHORT_PERIOD TF2 = TF_M05;
input int BB_BARS = 12;
input int TREND_BARS = 12;
input double LOTS = 0.01;
sinput double TRADE_STOP_PERCENTAGE = 10.0;

// 基本の6ペア
sinput string sEURUSD = "EURUSD";
sinput string sUSDJPY = "USDJPY";
sinput string sUSDCHF = "USDCHF";
sinput string sGBPUSD = "GBPUSD";
sinput string sAUDUSD = "AUDUSD";
sinput string sUSDCAD = "USDCAD";
sinput string sNZDUSD = "NZDUSD";

sinput int MAGIC = 20220806;

#define PERIOD1 ((ENUM_TIMEFRAMES)TF1)
#define PERIOD2 ((ENUM_TIMEFRAMES)TF2)

enum SYMBOL_INDEX { EUR, USD, JPY, CHF, GBP, AUD, CAD, NZD, MAX_SYMBOLS };
const string SYMBOL_NAMES[] = { "EUR", "USD", "JPY", "CHF", "GBP", "AUD", "CAD", "NZD" };

struct SYMBOL_INFO {
    SYMBOL_INDEX Index;
    string Name;
    double AV[];
    double Power;
};

MQL45_APPLICATION_START()

double InitMargin;
int T;
string CurrentSymbol;
int CurrentCount;
double PositionLots;
int LastEntryType;
double ExpertAdviserProfit;
datetime LastEntryDate;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    InitMargin = RemainingMargin();
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
    double margin_percentage = 100.0 * RemainingMargin() / InitMargin;
    if (margin_percentage < TRADE_STOP_PERCENTAGE) {
        ExpertRemove();
    }

    static long prev_trailing_bar = 0;
    long current_trailing_bar = TimeCurrent() / PeriodSeconds(PERIOD_M1);
    if (current_trailing_bar > prev_trailing_bar) {
        TrailingStop();
        prev_trailing_bar = current_trailing_bar;
    }

    static long prev_trade_bar = 0;
    long current_trade_bar = TimeCurrent() / PeriodSeconds();
    if (current_trade_bar <= prev_trade_bar) {
        return;
    }
    else {
        prev_trade_bar = current_trade_bar;
    }

    long T0 = ::iTime(Symbol(), PERIOD_H1, 0) - ::iTime(Symbol(), PERIOD_D1, 0);
    if (T0 < 3600) {
        return;
    }

    long T2 = ::iTime(Symbol(), PERIOD1, 0) / PeriodSeconds(PERIOD2);
    long T1 = ::iTime(Symbol(), PERIOD2, 0) / PeriodSeconds(PERIOD2);
    T = (int)(T1 - T2);

    SYMBOL_INFO Symbols[MAX_SYMBOLS];
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        Symbols[i].Index = (SYMBOL_INDEX)i;
        Symbols[i].Name = SYMBOL_NAMES[i];
        ArrayResize(Symbols[i].AV, T);
    }

    for (int t = 0; t < (int)T; ++t) {
        double EURUSD = GetVal(sEURUSD, t, T);
        double USDJPY = GetVal(sUSDJPY, t, T);
        double USDCHF = GetVal(sUSDCHF, t, T);
        double GBPUSD = GetVal(sGBPUSD, t, T);
        double AUDUSD = GetVal(sAUDUSD, t, T);
        double USDCAD = GetVal(sUSDCAD, t, T);
        double NZDUSD = GetVal(sNZDUSD, t, T);

        double EURJPY = GetValM(sEURUSD, sUSDJPY, t, T);
        double EURCHF = GetValM(sEURUSD, sUSDCHF, t, T);
        double EURGBP = GetValD(sEURUSD, sGBPUSD, t, T);
        double CHFJPY = GetValD(sUSDJPY, sUSDCHF, t, T);
        double GBPCHF = GetValM(sGBPUSD, sUSDCHF, t, T);
        double GBPJPY = GetValM(sGBPUSD, sUSDJPY, t, T);
        double AUDCHF = GetValM(sAUDUSD, sUSDCHF, t, T);
        double AUDJPY = GetValM(sAUDUSD, sUSDJPY, t, T);
        double AUDCAD = GetValM(sAUDUSD, sUSDCAD, t, T);
        double EURCAD = GetValM(sEURUSD, sUSDCAD, t, T);
        double GBPCAD = GetValM(sGBPUSD, sUSDCAD, t, T);
        double GBPAUD = GetValD(sGBPUSD, sAUDUSD, t, T);
        double EURAUD = GetValD(sEURUSD, sAUDUSD, t, T);
        double CADCHF = GetValD(sUSDCHF, sUSDCAD, t, T);
        double CADJPY = GetValD(sUSDJPY, sUSDCAD, t, T);

        double AUDNZD = GetValD(sAUDUSD, sNZDUSD, t, T);
        double EURNZD = GetValD(sEURUSD, sNZDUSD, t, T);
        double GBPNZD = GetValD(sGBPUSD, sNZDUSD, t, T);
        double NZDCAD = GetValM(sNZDUSD, sUSDCAD, t, T);
        double NZDCHF = GetValM(sNZDUSD, sUSDCHF, t, T);
        double NZDJPY = GetValM(sNZDUSD, sUSDJPY, t, T);

        Symbols[EUR].AV[t] = ( EURUSD+EURJPY+EURCHF+EURGBP+EURAUD+EURCAD+EURNZD) / MAX_SYMBOLS;
        Symbols[USD].AV[t] = (-EURUSD+USDJPY+USDCHF-GBPUSD-AUDUSD+USDCAD-NZDUSD) / MAX_SYMBOLS;
        Symbols[JPY].AV[t] = (-EURJPY-USDJPY-CHFJPY-GBPJPY-AUDJPY-CADJPY-NZDJPY) / MAX_SYMBOLS;
        Symbols[CHF].AV[t] = (-EURCHF-USDCHF+CHFJPY-GBPCHF-AUDCHF-CADCHF-NZDCHF) / MAX_SYMBOLS;
        Symbols[GBP].AV[t] = (-EURGBP+GBPUSD+GBPCHF+GBPJPY+GBPAUD+GBPCAD+GBPNZD) / MAX_SYMBOLS;

        Symbols[AUD].AV[t] = (-EURAUD+AUDUSD+AUDJPY+AUDCHF-GBPAUD+AUDCAD+AUDNZD) / MAX_SYMBOLS;
        Symbols[CAD].AV[t] = (-EURCAD-USDCAD+CADJPY+CADCHF-GBPCAD-AUDCAD-NZDCAD) / MAX_SYMBOLS;
        Symbols[NZD].AV[t] = (-EURNZD+NZDUSD+NZDJPY+NZDCHF-GBPNZD+NZDCAD-AUDNZD) / MAX_SYMBOLS;
    }

    double MaxPower = -9999999999999.0;
    double MinPower = +9999999999999.0;
    string MaxSymbol;
    string MinSymbol;
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        Symbols[i].Power = iPower(Symbols[i].AV);
        if (Symbols[i].Power > MaxPower) {
            MaxPower = Symbols[i].Power;
            MaxSymbol = Symbols[i].Name;
        }
        if (Symbols[i].Power < MinPower) {
            MinPower = Symbols[i].Power;
            MinSymbol = Symbols[i].Name;
        }
    }

    string symbol = MaxSymbol + MinSymbol;
    int type = OP_BUY;
    double price = MarketInfo(symbol, MODE_ASK);
    int sign = +1;
    if (price == 0) {
        symbol = MinSymbol + MaxSymbol;
        type = OP_SELL;
        price = MarketInfo(symbol, MODE_BID);
        sign = -1;
    }

    double trend0 = sign * iTrend(symbol, PERIOD2, TREND_BARS * 1);
    double trend1 = sign * iTrend(symbol, PERIOD2, TREND_BARS * 2);
    if (price > 0 && trend0 > trend1 && ExpertAdviserProfit >= 0) {
        if (symbol != CurrentSymbol) {
            ClosePositionAll();
            CurrentCount = 0;
        }

        double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        if (0 < margin_level && margin_level < 1500) {
            printf("WARNING: margin level = %.2f%%", margin_level);
        }
        else {
            int digits = (int)MarketInfo(symbol, MODE_DIGITS);
            double BB = iStdDev(symbol, PERIOD2, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);
            double SL = BB;
            double sl = NormalizeDouble(type == OP_BUY ? price - SL : price + SL, digits);
            double lots = MathMax(MathFloor(++CurrentCount * LOTS * 100.0 * RemainingMargin() / InitMargin), LOTS) / 100.0;
            if (!OrderSend(symbol, type, lots, price, 10, sl, 0, DoubleToString(margin_level, 2), MAGIC)) {
                printf("ERROR: OrderSend() FAILED: %d", GetLastError());
            }
            CurrentSymbol = symbol;
        }
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
    double profit = TesterStatistics(STAT_PROFIT);
    double win_ratio = TesterStatistics(STAT_TRADES) > 0 ? TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) : 0.0;
    double draw_down = (100.0 - TesterStatistics(STAT_BALANCE_DDREL_PERCENT)) / 100.0;
    double tester_result = profit * win_ratio * draw_down;
    return tester_result;
}

//+------------------------------------------------------------------+
//| 有効証拠金を返す                                                 |
//+------------------------------------------------------------------+
double RemainingMargin()
{
    return AccountBalance() + AccountCredit() + AccountProfit();
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
        int ticket = OrderTicket();
        double lots = OrderLots();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        if (!OrderClose(ticket, lots, price, 10, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
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
        if (OrderSymbol() != Symbol()) {
            continue;
        }

        string symbol = OrderSymbol();
        double point = MarketInfo(symbol, MODE_POINT);
        int digits = (int)MarketInfo(symbol, MODE_DIGITS);
        double BB = iStdDev(symbol, PERIOD2, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);
        double SL = BB;
        double TRAILING_START = 2.0 * BB;
        double TRAILING_STEP = 0.5 * BB;

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        double stoploss_price = type == OP_BUY ? price - OrderStopLoss() : OrderStopLoss() - price;
        color arrow = type == OP_BUY ? clrRed : clrBlue;
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
    
    GetPositionLots();
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
void GetPositionLots()
{
    PositionLots = 0;
    LastEntryType = 0;
    ExpertAdviserProfit = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        
        datetime entry_date = OrderOpenTime();
        if (entry_date > LastEntryDate) {
            LastEntryDate = entry_date;
        }

        LastEntryType = OrderType() == OP_BUY ? +1 : -1;
        PositionLots += LastEntryType * OrderLots();
        ExpertAdviserProfit += OrderProfit();
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetVal(string sym1, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD2, t1);
    double v2 = ::iOpen(sym1, PERIOD2, t2);

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetValM(string sym1, string sym2, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD2, t1);
    double v2 = ::iOpen(sym1, PERIOD2, t2);

    v1 *= ::iOpen(sym2, PERIOD2, t1);
    v2 *= ::iOpen(sym2, PERIOD2, t2);

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetValD(string sym1, string sym2, int t1, int t2)
{
    double v1 = ::iOpen(sym1, PERIOD2, t1);
    double v2 = ::iOpen(sym1, PERIOD2, t2);
    double v3 = ::iOpen(sym2, PERIOD2, t1);
    double v4 = ::iOpen(sym2, PERIOD2, t2);
    if (v3 == 0) return 0;
    if (v4 == 0) return 0;

    v1 /= v3;
    v2 /= v4;

    if (v2 == 0) return 0;
    return MathLog(v1 / v2) * 1000;
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iPower(const double& value[])
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    int N = ArraySize(value);
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = value[i];
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double power = diff_xy / diff_xx;
    return power;
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(string symbol, ENUM_TIMEFRAMES tf, int N)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    int minutes = PeriodSeconds(tf) / 60;
    for (int i = 0; i < N; ++i) {
        double x = -i * minutes;
        double y = ::iOpen(symbol, tf, i);
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double power = diff_xy / diff_xx;
    return power;
}

MQL45_APPLICATION_END()
