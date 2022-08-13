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

#include "ActiveLabel.mqh"

enum ENUM_TF {
    TF_M01 = PERIOD_M1,
    TF_M05 = PERIOD_M5,
    TF_M15 = PERIOD_M15,
    TF_M30 = PERIOD_M30,
    TF_H01 = PERIOD_H1,
    TF_H04 = PERIOD_H4,
    TF_D01 = PERIOD_D1,
    TF_W01 = PERIOD_W1,
    TF_MN1 = PERIOD_MN1,
};

input ENUM_TF TF = TF_M05;
input double START_DAYS = 0.125;
input double SORT_RATIO = 16;
input double SCAN_RATIO = 2.5;
input double BB_DAYS = 5;
input double BB_STOPLOSS_RATIO = 1.0;
input double BB_TRAILING_START_RATIO = 0.3;
input double BB_TRAILING_STEP_RATIO = 0.5;
input double LOTS = 0.01;
input double ACCOUNT_TRAILING_RATIO = 0.05;
input double ACCOUNT_TAKEPROFIT_RATIO = 0.80;
input double ACCOUNT_STOPLOSS_RATIO = 0.05;

sinput double TRADE_STOP_PERCENTAGE = 10.0;

sinput int MAGIC = 20220813;
sinput int SLIPPAGE = 10;

#define PERIOD ((ENUM_TIMEFRAMES)TF)
#define START_BARS (int)(24 * 3600 * START_DAYS / PeriodSeconds(PERIOD))
#define SORT_BARS (int)(START_BARS * SORT_RATIO)
#define SCAN_BARS (int)(SORT_BARS * SCAN_RATIO)
#define BB_BARS (int)(24 * 3600 * BB_DAYS / PeriodSeconds(PERIOD))
#define TREND_BARS (int)(24 * 3600 * TREND_DAYS / PeriodSeconds(PERIOD))

enum SYMBOL_INDEX { EUR, USD, JPY, CHF, GBP, AUD, CAD, NZD, MAX_SYMBOLS };
const string SYMBOL_NAMES[] = { "EUR", "USD", "JPY", "CHF", "GBP", "AUD", "CAD", "NZD" };

struct SYMBOL_INFO {
    string Name;
    double Powers[];
    double Power;
    double FirstPower;
    double P;
    double R;
    double S;
    int Sign;

    static void Sort(SYMBOL_INFO& array[]) {
        int array_size = ArraySize(array);
        for (int i = 0; i < array_size - 1; i++){
            for (int j = array_size - 1; j >= i + 1; j--){   //　右から左に操作
                if (Compare(array[j], array[j - 1]) > 0) {
                    SYMBOL_INFO temp = array[j];
                    array[j] = array[j - 1];
                    array[j - 1] = temp;
                }
            }
        }
    }

    static int Compare(const SYMBOL_INFO& Value1, const SYMBOL_INFO& Value2) {
        if (MathAbs(Value1.Power) != MathAbs(Value2.Power)) {
            return MathAbs(Value1.Power) > MathAbs(Value2.Power) ? +1 : -1;
        }
        if (MathAbs(Value1.R) != MathAbs(Value2.R)) {
            return MathAbs(Value1.R) > MathAbs(Value2.R) ? +1 : -1;
        }
        if (MathAbs(Value1.S) != MathAbs(Value2.S)) {
            return MathAbs(Value1.S) > MathAbs(Value2.S) ? +1 : -1;
        }
        if (MathAbs(Value1.P) != MathAbs(Value2.P)) {
            return MathAbs(Value1.P) > MathAbs(Value2.P) ? +1 : -1;
        }
        return 0;
    }

    void Caliculate() {
        P = iTrueTrend(Name, PERIOD, START_BARS, 0);
        R = iCorrelation(Name, PERIOD, SCAN_BARS, 0);
        S = iTrend(Name, PERIOD, SCAN_BARS, 0);

        int n = ArraySize(Powers);
        int N = SORT_BARS;
        if (n < N) {
            ArrayResize(Powers, n + 1, n);
            ++n;
        }
        ArrayCopy(Powers, Powers, 1, 0, n - 1);
        Powers[0] = P * MathAbs(::Sign(P) == ::Sign(R) ? R : 0) * MathAbs(::Sign(P) == ::Sign(S) ? S : 0);
        if (n < N) {
            Power = 0;
            Sign = 0;
            return;
        }
        
        double powers[];
        ArrayResize(powers, N);
        ArrayCopy(powers, Powers);
        ArraySort(powers);
        Power = powers[N / 2];
        if (MathAbs(Power) > 25) {
            Sign = Power > 0 ? +1 : -1;
        }
        else {
            Sign = 0;
        }
    }

    string ToString(int i) {
        return StringFormat("(%02d) %s %+08.3f  %+07.3f  %+05.3f  %+07.3f \n", i + 1, Name, Power, P, R, S);
    }
};

SYMBOL_INFO Symbols[];
int SYMBOLS;

MQL45_APPLICATION_START()

double InitMargin;
string CurrentSymbol;
int CurrentSign;
int CurrentCount;
double PositionLots;
int LastEntryType;
string LastEntrySymbol;
double ExpertAdviserProfit;
double MaxExpertAdviserProfit;
double MinPositionProfit;
datetime LastEntryDate;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    InitMargin = RemainingMargin();

    SYMBOLS = 0;
    for (int i = 0; i < MAX_SYMBOLS; ++i) {
        for (int j = i + 1; j < MAX_SYMBOLS; ++j) {
            string symbol = SYMBOL_NAMES[i] + SYMBOL_NAMES[j];
            double price = MarketInfo(symbol, MODE_ASK);
            if (price == 0.0) {
                symbol = SYMBOL_NAMES[j] + SYMBOL_NAMES[i];
                price = MarketInfo(symbol, MODE_ASK);
            }
            if (price == 0.0) {
                continue;
            }
            ArrayResize(Symbols, SYMBOLS + 1, SYMBOLS);
            Symbols[SYMBOLS].Name = symbol;
            //ArrayResize(Symbols[N].Trend, START_BARS);
            ++SYMBOLS;
        }
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
    double margin_percentage = 100.0 * RemainingMargin() / InitMargin;
    if (margin_percentage < TRADE_STOP_PERCENTAGE) {
        ExpertRemove();
    }

    static long prev_trailing_bar = 0;
    long current_trailing_bar = TimeCurrent() / PeriodSeconds(PERIOD_M1);
    if (current_trailing_bar > prev_trailing_bar) {
        TrailingStop();
        prev_trailing_bar = current_trailing_bar;

        if (PositionLots != 0) {
            //int sign = PositionLots > 0 ? +1 : -1;
            //double trend0 = sign * iTrend(CurrentSymbol, PERIOD, TREND_BARS * 1, 0);
            //double trend1 = sign * iTrend(CurrentSymbol, PERIOD, TREND_BARS * 5, 0);
        
            double TrailingStartProfit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
            if (/*trend0 < 0 &&*/ TrailingStartProfit < ExpertAdviserProfit && ExpertAdviserProfit < ACCOUNT_TAKEPROFIT_RATIO * MaxExpertAdviserProfit) {
                ClosePositionAll(LastEntrySymbol, "takeprofit");
            }
            if (ExpertAdviserProfit < -ACCOUNT_STOPLOSS_RATIO * RemainingMargin()) {
                ClosePositionAll(LastEntrySymbol, "stoploss");
            }
        }
    }

    if (PeriodSeconds(PERIOD) < 24 * 60 * 60) {
        static long prev_trade_bar = 0;
        long current_trade_bar = TimeCurrent() / PeriodSeconds(PERIOD);
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
    }

    for (int i = 0; i < SYMBOLS; ++i) {
        Symbols[i].Caliculate();
    }

    SYMBOL_INFO::Sort(Symbols);

    string symbol = Symbols[0].Name;
    int type = Symbols[0].Sign > 0 ? OP_BUY : OP_SELL;
    int sign = Symbols[0].Sign;

    double BB = iStdDev(symbol, PERIOD, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);

    string comment = TimeToString(TimeCurrent()) + " \n";
    comment += StringFormat("%.0f %+.0f %.2f%% \n", AccountBalance(), AccountProfit(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    comment += StringFormat("%s %+.2f %+.0f \n", symbol, PositionLots, MinPositionProfit);
    for (int i = 0; i < SYMBOLS; ++i) {
        comment += Symbols[i].ToString(i);
    }
    ActiveLabel::Comment(comment);

    if (Sign(Symbols[0].FirstPower) != Sign(Symbols[0].Power)) {
        ClosePositionAll(symbol, StringFormat("[%+.3f/%+.3f]", Symbols[0].FirstPower, Symbols[0].Power));
    }

    if (MinPositionProfit >= 0) {
        double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        if (0 < margin_level && margin_level < 1500) {
            printf("WARNING: margin level = %.2f%%", margin_level);
            return;
        }

        if (symbol != CurrentSymbol && ExpertAdviserProfit < 0) {
            ClosePositionAll(symbol, "symbol");
        }
        if (sign == 0) {
            return;
        }

        int digits = (int)MarketInfo(symbol, MODE_DIGITS);
        double stop_level = MarketInfo(symbol, MODE_STOPLEVEL);
        double point = MarketInfo(symbol, MODE_POINT);
        if (BB == 0) {
            return;
        }
        double price = sign == +1 ? MarketInfo(symbol, MODE_ASK) : MarketInfo(symbol, MODE_BID);

        double spread = MarketInfo(symbol, MODE_ASK) - MarketInfo(symbol, MODE_BID);
        double SL = MathMax(BB_STOPLOSS_RATIO * BB / CurrentCount, stop_level * point) + spread;
        double sl = NormalizeDouble(type == OP_BUY ? price - SL : price + SL, digits);
        double tp = 0;
        double compound_interest = RemainingMargin() / InitMargin;
        double lots = LOTS;
        double power = 0.02 * Symbols[0].Power;
        lots *= MathMax(MathFloor(MathPow(CurrentCount, power) * compound_interest), 1.0);
        string order_comment = StringFormat("%+.3f / %05.0%%", Symbols[0].Power, margin_level);
        if (OrderSend(symbol, type, lots, price, SLIPPAGE, sl, tp, order_comment, MAGIC) == -1) {
            printf("ERROR: OrderSend() FAILED: %d", GetLastError());
        }
        else {
            if (CurrentCount == 1) { Symbols[0].FirstPower = Symbols[0].Power; }
            CurrentSymbol = symbol;
            CurrentSign = sign;
            ++CurrentCount;
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
void ClosePositionAll(string symbol, string reason)
{
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != symbol) {
            continue;
        }
        int ticket = OrderTicket();
        double lots = OrderLots();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        string comment = StringFormat("%s:%s %+.0f %.2f%%", reason, symbol, OrderProfit(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
        OrderCloseComment(comment);
        if (!OrderClose(ticket, lots, price, 10, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
    MaxExpertAdviserProfit = ExpertAdviserProfit = 0;
    CurrentCount = 1;
    CurrentSign = 0;
}

//+------------------------------------------------------------------+
//| トレーリングストップ                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
    static double min_position_profit = 0;

    GetPositionLots();
    if (min_position_profit == MinPositionProfit) { return; }
    min_position_profit = MinPositionProfit;

    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }

        string symbol = OrderSymbol();
        double point = MarketInfo(symbol, MODE_POINT);
        int digits = (int)MarketInfo(symbol, MODE_DIGITS);
        double stop_level = MarketInfo(symbol, MODE_STOPLEVEL);
        double BB = iStdDev(symbol, PERIOD, BB_BARS, 0, MODE_SMA, PRICE_OPEN, 0);
        double SL0 = BB_STOPLOSS_RATIO * BB;
        double TRAILING_START = BB_TRAILING_START_RATIO * SL0;
        double TRAILING_STEP = BB_TRAILING_STEP_RATIO * TRAILING_START;
        double SL = MathMax(TRAILING_STEP, stop_level * point);

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = MarketInfo(symbol, type == OP_BUY ? MODE_BID : MODE_ASK);
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        if (profit_price == 0.0) { continue; }
        double stoploss_price = OrderStopLoss();
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        if (profit_price > TRAILING_START) {
            if (type == OP_BUY) {
                double sl = NormalizeDouble(price - SL, digits);
                double tp = 0;
                if (sl > stoploss_price && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            } else if (type == OP_SELL) {
                double sl = NormalizeDouble(price + SL, digits);
                double tp = 0;
                if (sl < stoploss_price && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
        }
    }
    
    if (ExpertAdviserProfit > MaxExpertAdviserProfit) {
        MaxExpertAdviserProfit = ExpertAdviserProfit;
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
    MinPositionProfit = OrdersTotal() == 0 ? 0.0 : +9999999999999.0;
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

        double lots = OrderLots();
        double profit = OrderProfit();
        double point = MarketInfo(OrderSymbol(), MODE_POINT);
        LastEntryType = OrderType() == OP_BUY ? +1 : -1;
        PositionLots += LastEntryType * lots;
        ExpertAdviserProfit += profit;
        MinPositionProfit = MathMin(0.01 * profit / lots, MinPositionProfit);
        LastEntrySymbol = OrderSymbol();
    }
}

MQL45_APPLICATION_END()

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
/*
double iTrend(const double& value[], int N = 0)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    if (N < 1) { N = ArraySize(value); }
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
    double trend = diff_xy / diff_xx;
    return trend;
}
*/

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(string symbol, ENUM_TIMEFRAMES tf, int N, int shift)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    double y1 = 0;
    int minutes = PeriodSeconds(tf) / 60;
    for (int i = 0; i < N; ++i) {
        double x = -i * minutes;
        double y = ::iOpen(symbol, tf, i + shift);
        if (y == 0.0) { return 0.0; }
        if (i == N - 1) { y1 = y; }
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double trend = diff_xy / diff_xx;
    double spread = SymbolInfoDouble(symbol, SYMBOL_ASK) - SymbolInfoDouble(symbol, SYMBOL_BID);
    return trend / spread * N;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
/*
double iCorrelation(const double& value[], int N = 0)
{
    if (N < 1) { N = ArraySize(value); }
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = value[i];
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = (-i) - avr_x;
        double y = value[i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}
*/

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(string symbol, ENUM_TIMEFRAMES tf, int N, int shift)
{
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = ::iOpen(symbol, tf, i + shift);
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = (-i) - avr_x;
        double y = ::iOpen(symbol, tf, i + shift) - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
/*
double iTrueTrend(const double& value[], int N = 0)
{
    double trend = iTrend(value, N);
    double R = 1;//iCorrelation(value, N);
    return MathAbs(R) * trend;
}
*/

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrueTrend(string symbol, ENUM_TIMEFRAMES tf, int N, int shift)
{
    double trend = iTrend(symbol, tf, N, shift);
    double R = iCorrelation(symbol, tf, N, shift);
    return MathAbs(R) * trend;
}

int Sign(double value)
{
    if (value > 0) { return +1; }
    if (value < 0) { return -1; }
    return 0;
}