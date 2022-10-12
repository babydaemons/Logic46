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
const int       SCAN_BARS1 = 4 * 20;
const int       SCAN_BARS2 = 8 * 40;
const double    SL_RATIO = 0.16;
sinput double   LOTS = 0.01;
sinput int      MAGIC = 20220830;
sinput int      SLIPPAGE = 10;

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#include "ActiveLabel.mqh"

#define BARS 2

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

double PriceOpen[];

double Lots[2];

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

    GetPositionCount();

    if (CopyOpen(Symbol(), Period(), 0, SCAN_BARS2, PriceOpen) != SCAN_BARS2) {
        return;
    }

    double Correlation1 = iCorrelation(PriceOpen, SCAN_BARS2 - SCAN_BARS1, SCAN_BARS1);
    double Correlation2 = iCorrelation(PriceOpen, 0, SCAN_BARS2);
    double Entry1 = 0;
    if (Correlation1 > 0 && Correlation2 > 0) {
        Entry1 = +1;
    }
    if (Correlation1 < 0 && Correlation2 < 0) {
        Entry1 = -1;
    }

    //double Entry2 = Histgram1[SCAN_BARS1 - 1] > 0 && Histgram2[SCAN_BARS2 - 1] > 0 ? +1 : Histgram1[SCAN_BARS1 - 1] < 0 && Histgram2[SCAN_BARS2 - 1] < 0 ? -1 : 0;

    Entry = Entry1;// == Entry2 ? Entry1 : 0;

    string msg = "";
    string wdays[] = { "日", "月", "火", "水", "木", "金", "土" };
    msg += TimeToString(t, TIME_DATE) + "(" + wdays[TimeDayOfWeek(t)] + ") " + TimeToString(t, TIME_SECONDS) + "\n";
    msg += StringFormat("残高      %s\n", ActiveLabel::FormatComma(AccountBalance(), 0));
    msg += StringFormat("損益      %s\n", ActiveLabel::FormatComma(AccountProfit(), 0));
    msg += StringFormat("証拠金    %s\n", ActiveLabel::FormatComma(RemainingMargin(), 0));
    msg += StringFormat("維持率    %.2f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    msg += StringFormat("相関係数1 %+.3f\n", Correlation1);
    msg += StringFormat("相関係数2 %+.3f\n", Correlation2);
    msg += StringFormat("%s L:%.2f S:%.2f\n", Symbol(), Lots[0], Lots[1]);
    ActiveLabel::Comment(msg);

    if (Sgn(Entry) != Sgn(PrevEntry)) {
        ClosePositionAll(+1, "Entry");
        ClosePositionAll(-1, "Entry");
    }
    PrevEntry = Entry;

    SL = SL_RATIO * Ask;

    if (RemainingMargin() < 10000) {
        ExpertRemove();
        return;
    }

    static long prev_minute = 0;
    long current_minute = t / 60;
    if (current_minute > prev_minute) {
        prev_minute = current_minute;
        TrailingStop();
    }

    static long prev_trade = 0;
    long current_trade = ((long)TimeCurrent() - 60 * 60) / PeriodSeconds(Period());
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
    if (AccountProfit() < 0) {
        return;
    }

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
    GetPositionCount();
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
void GetPositionCount()
{
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
