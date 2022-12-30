//+------------------------------------------------------------------+
//|                                               ArbitrageOilEA.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>

sinput string SYMBOL1 = "USOUSD";
sinput string SYMBOL2 = "UKOUSD";
input int SPAN = 24 * 200;
input double TP = 5000;
input double SL = 25000;
sinput double LOTS = 1.00;
sinput ulong MAGIC = 20221217;

CTrade trader;

int CountExistPosition(double& profit) {
    int N = PositionsTotal();
    int n = 0;
    profit = 0.0;
    for (int i = 0; i < N; ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
            continue;
        }
        ++n;
        profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return n;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC);

    return(INIT_SUCCEEDED);
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
    double profit;
    int n = CountExistPosition(profit);

    double price1[];
    if (CopyClose(SYMBOL1, Period(), 0, SPAN, price1) != SPAN) {
        return;
    }

    double price2[];
    if (CopyClose(SYMBOL2, Period(), 0, SPAN, price2) != SPAN) {
        return;
    }

    double diff_total = 0.0;
    for (int i = 0; i < SPAN; ++i) {
        diff_total += price1[i] - price2[i];
    }

    double diff_average = diff_total / SPAN;
    double diff = SymbolInfoDouble(SYMBOL1, SYMBOL_ASK) - SymbolInfoDouble(SYMBOL2, SYMBOL_ASK);

    long t = ((long)TimeCurrent() / 60) % (24 * 60);
    const long TIME0 =  3 * 60;
    const long TIME1 = 23 * 60;
    if (t < TIME0 || TIME1 <= t) {
        return;
    }

    if (n == 0) {
        if (diff_average > diff) {
            trader.Sell(LOTS, SYMBOL1);
            trader.Buy(LOTS, SYMBOL2);
        }
        else {
            trader.Sell(LOTS, SYMBOL2);
            trader.Buy(LOTS, SYMBOL1);
        }
    }
    else {
        if (profit > +TP || profit < -SL) {
            int N = PositionsTotal();
            for (int i = N - 1; i >= 0; --i) {
                ulong ticket = PositionGetTicket(i);
                if (PositionGetInteger(POSITION_MAGIC) != MAGIC) {
                    continue;
                }
                trader.PositionClose(ticket);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester() {
    double profit = TesterStatistics(STAT_PROFIT);
    double win_ratio = TesterStatistics(STAT_TRADES) > 0 ? TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) : 0.0;
    double draw_down = (100.0 - TesterStatistics(STAT_BALANCE_DDREL_PERCENT)) / 100.0;
    double tester_result = profit * win_ratio * draw_down;
    return tester_result;
}
