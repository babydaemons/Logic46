//+------------------------------------------------------------------+
//|                                                BurstTraderEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input double ENTRY_TREND = 0.01;
input int BARS = 2;
input int BARS_RATIO = 2;
sinput double LOTS = 0.01;
sinput int SLIPPAGE = 10;
sinput int MAGIC = 20221229;

#define BARS1   BARS
#define BARS2   (BARS * BARS_RATIO)

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"

int Ticket = -1;
int Position = 0;

MQL45_APPLICATION_START()

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    double trend1 = iTrend(Symbol(), PERIOD_M1, BARS1);
    double trend2 = iTrend(Symbol(), PERIOD_M1, BARS2);

    if (Ticket > 0) {
        if (Position > 0 && trend2 < 0) {
            if (!OrderClose(Ticket, LOTS, Bid, SLIPPAGE, clrRed)) {
                Alert(StringFormat("Cannot close long position #%d", Ticket));
            }
            else {
                Ticket = 0;
                Position = 0;
                return;
            }
        }
        if (Position < 0 && trend2 > 0) {
            if (!OrderClose(Ticket, LOTS, Bid, SLIPPAGE, clrBlue)) {
                Alert(StringFormat("Cannot close short position #%d", Ticket));
            }
            else {
                Ticket = 0;
                Position = 0;
                return;
            }
        }
    }
    else if (MathAbs(trend1) > ENTRY_TREND) {
        if (trend1 > 0) {
            Ticket = OrderSend(Symbol(), OP_BUY, LOTS, Ask, SLIPPAGE, 0.0, 0.0, "BurstTraderEA", 0, clrBlue);
            if (Ticket == -1) {
                Alert("Cannot open long position");
            }
            else {
                Position = +1;
            }
        }
        else {
            Ticket = OrderSend(Symbol(), OP_SELL, LOTS, Bid, SLIPPAGE, 0.0, 0.0, "BurstTraderEA", 0, clrRed);
            if (Ticket == -1) {
                Alert("Cannot open short position");
            }
            else {
                Position = -1;
            }
        }
        return;
    }
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(string symbol, ENUM_TIMEFRAMES tf, int N) {
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    double y1 = 0;
    int minutes = PeriodSeconds(tf) / 60;
    for (int i = 0; i < N; ++i) {
        double x = -i * minutes;
        double y = ::iOpen(symbol, tf, i);
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
    if (y1 == 0.0) { return 0.0; }
    double trend = diff_xy / diff_xx;
    return trend / y1 * 100;
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

MQL45_APPLICATION_END()
