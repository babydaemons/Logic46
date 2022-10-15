//+------------------------------------------------------------------+
//|                                                MTFClustering.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
const int       BARS = 5 * 6;
const int       MULTPLY = 2;
const double    RISK_REWARD_RATIO = 1.5;
const double    ACCOUNT_SL = 10000;
const double    ACCOUNT_TP = RISK_REWARD_RATIO * ACCOUNT_SL;
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20220830;
sinput int      SLIPPAGE = 10;

const int       BARS1 = BARS;
const int       BARS2 = BARS1 * MULTPLY;
//const int       BARS3 = BARS2 * MULTPLY;

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------
//--- the number of indicator buffer for storage Open
#define  HA_OPEN     0
//--- the number of indicator buffer for storage High
#define  HA_HIGH     1
//--- the number of indicator buffer for storage Low
#define  HA_LOW      2
//--- the number of indicator buffer for storage Close
#define  HA_CLOSE    3
//--- the number of indicator buffer for storage Color
#define  HA_COLOR    4

double SL;

double SD;

double Lots[2];

int Entry;
int PrevEntry;

int hSD1;
//int hSD2;
int hMA2;
int hEMA1;
int hEMA2;
//int hEMA3;

double AccountMaxProfit;

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

    hSD1 = ::iStdDev(Symbol(), Period(), BARS2, 0, MODE_SMA, PRICE_CLOSE);
    //hSD2 = ::iStdDev(Symbol(), Period(), BARS2, 0, MODE_SMA, hSD1);
    hMA2 = ::iMA(Symbol(), Period(), 2 * 12 * BARS2, 0, MODE_SMA, hSD1);
    hEMA1 = iMA(Symbol(), Period(), BARS1, 0, MODE_EMA, PRICE_CLOSE);
    hEMA2 = iMA(Symbol(), Period(), BARS2, 0, MODE_EMA, PRICE_CLOSE);
    //hEMA3 = iMA(Symbol(), Period(), BARS3, 0, MODE_EMA, PRICE_CLOSE);

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
    if (RemainingMargin() < 10000) {
        ExpertRemove();
        return;
    }

    datetime t = TimeCurrent();

    double min_profit;
    double avr_profit;
    double VWAP;
    int position_count = GetPositionCount(min_profit, avr_profit, VWAP);

    double SD1[];
    if (CopyBuffer(hSD1, MAIN_LINE, 0, 1, SD1) != 1) {
        return;
    }
/*
    double SD2[];
    if (CopyBuffer(hSD2, MAIN_LINE, 0, 1, SD2) != 1) {
        return;
    }
*/
    double MA2[];
    if (CopyBuffer(hMA2, MAIN_LINE, 0, 1, MA2) != 1) {
        return;
    }

    const int N = 5 * 6;
    double EMA1[];
    if (CopyBuffer(hEMA1, MAIN_LINE, 0, N + 1, EMA1) != N + 1) {
        return;
    }
    double EMA2[];
    if (CopyBuffer(hEMA2, MAIN_LINE, 0, N + 1, EMA2) != N + 1) {
        return;
    }
/*
    double EMA3[];
    if (CopyBuffer(hEMA3, MAIN_LINE, 0, N + 1, EMA3) != N + 1) {
        return;
    }
*/

    Entry = 0;
    if (EMA1[N] > EMA1[0] && EMA2[N] > EMA2[0] /*&& EMA3[1] > EMA3[0]*/) {
        Entry = +1;
    }
    if (EMA1[N] < EMA1[0] && EMA2[N] < EMA2[0] /*&& EMA3[1] < EMA3[0]*/) {
        Entry = -1;
    }

    SD = 5.0 * SD1[0];

    string msg = "";
    string wdays[] = { "日", "月", "火", "水", "木", "金", "土" };
    msg += TimeToString(t, TIME_DATE) + "(" + wdays[TimeDayOfWeek(t)] + ") " + TimeToString(t, TIME_SECONDS) + "\n";
    msg += StringFormat("残高      %s\n", ActiveLabel::FormatComma(AccountBalance(), 0));
    msg += StringFormat("損益      %s\n", ActiveLabel::FormatComma(AccountProfit(), 0));
    msg += StringFormat("証拠金    %s\n", ActiveLabel::FormatComma(RemainingMargin(), 0));
    msg += StringFormat("維持率    %.2f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    msg += StringFormat("標準偏差  %+.3f\n", 100.0 * (SD1[0] - MA2[0]) / Ask);
    msg += StringFormat("%s L:%.2f S:%.2f\n", Symbol(), Lots[0], Lots[1]);
    ActiveLabel::Comment(msg);

/*
    if (SD1[0] == 0.0) {
        return;
    }
    if (MA2[0] == 0.0) {
        return;
    }
    if (SD1[0] < MA2[0]) {
        //ClosePositionAll(+1, "SDR");
        //ClosePositionAll(-1, "SDR");
        return;
    }
*/

    if (Entry == 0) {
        PrevEntry = Entry;
        return;
    }

    if (Entry != PrevEntry) {
        string reason = StringFormat("Entry(%+d/%+d)", PrevEntry, Entry);
        ClosePositionAll(+1, reason);
        ClosePositionAll(-1, reason);
        PrevEntry = Entry;
    }
/*
    if (Entry != 0) {
        PrevEntry = Entry;
    }
*/

    if (AccountProfit() < -ACCOUNT_SL) {
        ClosePositionAll(+1, "SL");
        ClosePositionAll(-1, "SL");
        return;
    }

    AccountMaxProfit = MathMax(AccountMaxProfit, AccountProfit());
    if (AccountProfit() > +ACCOUNT_TP && AccountProfit() < 0.60 * AccountMaxProfit) {
        string reason = StringFormat("TP(%.0f)", AccountProfit());
        ClosePositionAll(+1, reason);
        ClosePositionAll(-1, reason);
        return;
    }

    if (position_count >= 4 && avr_profit > 0.005 * Ask && min_profit < -avr_profit) {
        ClosePositionAll(+1, "TP2");
        ClosePositionAll(-1, "TP2");
        return;
    }

    if (Entry > 0) {
        if (Bid < VWAP + avr_profit || AccountProfit() < 0) {
            return;
        }
    }
    if (Entry < 0) {
        if (Ask > VWAP - avr_profit || AccountProfit() < 0) {
            return;
        }
    }

    static int prev_position_count = -1;
    if (prev_position_count != position_count) {
        prev_position_count = position_count;
        if (position_count > 0) {
            SL = SD; // / MathSqrt(position_count);
        }
    }

    static long prev_minute = 0;
    long current_minute = t / 60;
    if (current_minute > prev_minute) {
        prev_minute = current_minute;
        TrailingStop();
    }

    int interval = PeriodSeconds(Period()) / 1;
    if (AccountProfit() > ACCOUNT_SL) {
        interval /= 4 * 12;
    }
    long current_bar = (long)(TimeCurrent() - 60 * 60) % interval;
    if (current_bar == 0) {
        Trade();
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void Trade()
{
/*
    if (AccountProfit() < 0) {
        return;
    }
*/

    if (Entry > 0) {
        double sl = SL > 0 ? NormalizeDouble(Bid - SL, Digits) : 0;
        if (!OrderSend(Symbol(), OP_BUY, LOTS, Ask, SLIPPAGE, sl, 0, "", MAGIC, 0, clrBlue)) {
            Alert(StringFormat("ERROR: OrderSend(OP_BUY) FAILED: %d", GetLastError()));
        }
    }
    if (Entry < 0) {
        double sl = SL > 0 ? NormalizeDouble(Ask + SL, Digits) : 0;
        if (!OrderSend(Symbol(), OP_SELL, LOTS, Bid, SLIPPAGE, sl, 0, "", MAGIC, 0, clrRed)) {
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
        if ((ticket % 60) != minute) {
            continue;
        }

        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;

        double TRAILING_START = SL * 1.5;
        double TRAILING_STEP0 = TRAILING_START * 0.5;
        double TRAILING_STEP = 0.5 * profit_price;
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
            else {
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
            else {
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
void ClosePositionAll(double signal, string reason)
{
    int keep_type = signal > 0 ? OP_BUY : OP_SELL;
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
        if (OrderType() != keep_type) {
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
    AccountMaxProfit = -FLT_MAX;
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
int GetPositionCount(double& min_profit, double& avr_profit, double& VWAP)
{
    Lots[0] = Lots[1] = 0;
    
    min_profit = +FLT_MAX;
    avr_profit = 0;
    VWAP = 0;
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
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        min_profit = MathMin(min_profit, profit_price);
        avr_profit += profit_price;
        VWAP += entry;
        Lots[type == OP_BUY ? 0 : 1] += OrderLots();
        ++n;
    }
    if (n > 0) {
        min_profit = 0;
        avr_profit /= n;
        VWAP /= n;
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

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(const double& X[], const double& Y[], int startX, int startY, int M)
{
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < M; ++i) {
        double x = X[startX + i];
        double y = Y[startY + i];
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / M;
    double avr_x = sum_x / M;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < M; ++i) {
        double x = X[startX + i] - avr_x;
        double y = Y[startY + i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(const double& Y[], int startY, int M)
{
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < M; ++i) {
        double x = i;
        double y = Y[startY + i];
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / M;
    double avr_x = sum_x / M;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < M; ++i) {
        double x = i - avr_x;
        double y = Y[startY + i] - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

MQL45_APPLICATION_END()
