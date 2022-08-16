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
#include "TrueTrend.mqh"

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

input ENUM_TF TF = TF_H01;
input bool ENABLE_USD = true;
input bool ENABLE_EUR = true;
input bool ENABLE_JPY = true;
input bool ENABLE_GBP = true;
input bool ENABLE_CHF = true;
input bool ENABLE_CAD = true;
input bool ENABLE_AUD = true;
input bool ENABLE_NZD = true;
input double START_DAYS = 0.25;
input double SORT_RATIO = 4.0;
input double SCAN_RATIO = 5.0;
input double POWER_ENTRY = 1.0;
input double BB_DAYS = 5;
input double BB_STOPLOSS_RATIO = 1.0;
input double BB_TRAILING_START_RATIO = 0.3;
input double BB_TRAILING_STEP_RATIO = 0.5;
input double ACCOUNT_TRAILING_RATIO = 0.05;
input double ACCOUNT_TAKEPROFIT_RATIO = 0.50;
input double ACCOUNT_STOPLOSS_RATIO = 0.05;

sinput double LOTS = 0.01;
sinput double TRADE_STOP_PERCENTAGE = 10.0;

sinput int MAGIC = 20220813;
sinput int SLIPPAGE = 10;

#define PERIOD ((ENUM_TIMEFRAMES)TF)
#define START_BARS (int)(24 * 3600 * START_DAYS / PeriodSeconds(PERIOD))
#define SORT_BARS (int)(START_BARS * SORT_RATIO)
#define SCAN_BARS (int)(SORT_BARS * SCAN_RATIO)
#define BB_BARS (int)(24 * 3600 * BB_DAYS / PeriodSeconds(PERIOD))
#define TREND_BARS (int)(24 * 3600 * TREND_DAYS / PeriodSeconds(PERIOD))

string SYMBOL_NAMES[];
#define MAX_SYMBOLS ArraySize(SYMBOL_NAMES)
void ADD_SYMBOL_NAMES(bool enabled, string name)
{
    if (!enabled) { return; }
    ArrayResize(SYMBOL_NAMES, MAX_SYMBOLS + 1, MAX_SYMBOLS);
    SYMBOL_NAMES[MAX_SYMBOLS - 1] = name;
}

class SYMBOL_INFO MQL45_DERIVERED {
public:
    string Name;
    double Powers[];
    double Power;
    double FirstPower;
    double P;
    double R[3];
    double S[3];
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
        if (MathAbs(Value1.R[0]) != MathAbs(Value2.R[0])) {
            return MathAbs(Value1.R[0]) > MathAbs(Value2.R[0]) ? +1 : -1;
        }
        if (MathAbs(Value1.R[1]) != MathAbs(Value2.R[1])) {
            return MathAbs(Value1.R[1]) > MathAbs(Value2.R[1]) ? +1 : -1;
        }
        if (MathAbs(Value1.S[0]) != MathAbs(Value2.S[0])) {
            return MathAbs(Value1.S[0]) > MathAbs(Value2.S[0]) ? +1 : -1;
        }
        if (MathAbs(Value1.S[1]) != MathAbs(Value2.S[1])) {
            return MathAbs(Value1.S[1]) > MathAbs(Value2.S[1]) ? +1 : -1;
        }
        return 0;
    }

    void Caliculate() {
        R[0] = iCorrelation(Name, PERIOD, START_BARS);
        if (R[0] == 0.0) { return; }
        S[0] = iTrend(Name, PERIOD, START_BARS);
        if (S[0] == 0.0) { return; }
        R[1] = iCorrelation(Name, PERIOD, SORT_BARS);
        if (R[1] == 0.0) { return; }
        S[1] = iTrend(Name, PERIOD, SORT_BARS);
        if (S[1] == 0.0) { return; }
        R[2] = iCorrelation(Name, PERIOD, SCAN_BARS);
        if (R[2] == 0.0) { return; }
        S[2] = iTrend(Name, PERIOD, SCAN_BARS);
        if (S[2] == 0.0) { return; }

        int n = ArraySize(Powers);
        int N = SCAN_BARS;
        if (n < N) {
            ArrayResize(Powers, n + 1, n);
            ++n;
        }
        ArrayCopy(Powers, Powers, 1, 0, n - 1);
        if (Sgn(R[0]) == Sgn(R[1]) && Sgn(R[0]) == Sgn(R[2]) && Sgn(R[0]) == Sgn(S[0]) && Sgn(R[0]) == Sgn(S[1]) && Sgn(R[0]) == Sgn(S[2])) {
            //P = R[0] * MathAbs(R[1]) * MathAbs(R[2]) * MathPow(MathAbs(S[0] * S[1] * S[2]), 1.0 / 3.0);
            P = R[2] * MathPow(MathAbs(S[0] * S[1] * S[2]), 1.0 / 3.0);
        }
        else {
            P = 0;
        }
        Powers[0] = P;
        if (n < N) {
            Power = 0;
            Sign = 0;
            return;
        }
        
        Power = iSMA(Powers, N);
        if (Sgn(Power) == Sgn(P)) {
            Power *= MathAbs(R[0]);
        }
        else {
            Power = 0;
        }

        if (MathAbs(Power) > POWER_ENTRY) {
            Sign = Power > 0 ? +1 : -1;
        }
        else {
            Sign = 0;
        }
    }

    string ToString(int i) {
        return StringFormat("(%02d) %s %+06.1f %+04.2f %+04.2f %+04.2f %+06.1f %+06.1f %+06.1f \n", i + 1, Name, Power, R[0], R[1], R[2], S[0], S[1], S[2]);
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

    ADD_SYMBOL_NAMES(ENABLE_USD, "USD");
    ADD_SYMBOL_NAMES(ENABLE_EUR, "EUR");
    ADD_SYMBOL_NAMES(ENABLE_JPY, "JPY");
    ADD_SYMBOL_NAMES(ENABLE_GBP, "GBP");
    ADD_SYMBOL_NAMES(ENABLE_CHF, "CHF");
    ADD_SYMBOL_NAMES(ENABLE_CAD, "CAD");
    ADD_SYMBOL_NAMES(ENABLE_AUD, "AUD");
    ADD_SYMBOL_NAMES(ENABLE_NZD, "NZD");

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
            ++SYMBOLS;
        }
    }

    ActiveLabel::POSITION_X = 550;

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
            double TrailingStartProfit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
            if (TrailingStartProfit < ExpertAdviserProfit && ExpertAdviserProfit < ACCOUNT_TAKEPROFIT_RATIO * MaxExpertAdviserProfit) {
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

    if (symbol != CurrentSymbol) {
        ClosePositionAll(symbol, "symbol");
    }

    if (Sgn(Symbols[0].FirstPower) != Sgn(Symbols[0].Power)) {
        ClosePositionAll(symbol, StringFormat("[%+.3f/%+.3f]", Symbols[0].FirstPower, Symbols[0].Power));
    }

    if (MinPositionProfit >= 0) {
        double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
        if (0 < margin_level && margin_level < 1500) {
            printf("WARNING: margin level = %.2f%%", margin_level);
            return;
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

int Sgn(double value)
{
    if (value > 0) { return +1; }
    if (value < 0) { return -1; }
    return 0;
}