//+------------------------------------------------------------------+
//|                                                      Logic46.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"

const MQL45_TIMEFRAMES TIMEFRAMES[] = {
    PERIOD_M1,
    PERIOD_M5,
    PERIOD_M15,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4,
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1,
};

enum E_TIMEFRAMES {
    TIMEFRAME_M01,
    TIMEFRAME_M05,
    TIMEFRAME_M15,
    TIMEFRAME_M30,
    TIMEFRAME_H01,
    TIMEFRAME_H04,
    TIMEFRAME_D01,
    TIMEFRAME_W01,
    TIMEFRAME_MN1,
};

//--- input parameters
input string            SYMBOLS = "USDJPYmicro";
input E_TIMEFRAMES      TF = TIMEFRAME_H04;
input int               MA_BARS = 6;
input int               MA_SCAN_BARS = 3;

input int               ADX_BARS = 24;
input int               ADX_SCAN_BARS = 2;
input double            ADX_ENTRY = 20.0;

input double            TRAILING_STEP_PERCENTAGE = 0.1;
input double            STOP_LOSS_RATIO = 2.0;
input double            RISK_REWARD_RATIO = 2.0;

input double            LOT = 1.0;
sinput int              STOP_BALANCE_PERCENTAGE = 25;
sinput int              SLIPPAGE = 10;
sinput int              MAGIC = 20220724;

#define TIMEFRAME TIMEFRAMES[TF]

#define SIGNAL_ARRAY_SIZE 20

class ActiveTrader DERIVERED_MQL45 {
public:
    ActiveTrader() { }

#include "AbstractTrader.mqh"

protected:
    void DoInitialize() { }

    TRADE_TYPE DoTrade(double& lots, string& comment)
    {
        lots = LOT;
        comment = "Trend";

        for (int i = 0; i < MA_SCAN_BARS; ++i) {
            O[i] = iMA(_symbol, TIMEFRAME, MA_BARS, 0, MODE_EMA, PRICE_OPEN, i + 1);
            C[i] = iMA(_symbol, TIMEFRAME, MA_BARS, 0, MODE_EMA, PRICE_OPEN, i);
            B[i] = C[i] - O[i];
        }

        for (int i = 0; i < ADX_SCAN_BARS; ++i) {
            ADX[i] = iADX(_symbol, TIMEFRAME, ADX_BARS, PRICE_OPEN, MODE_MAIN, i);
            PLUSDI[i] = iADX(_symbol, TIMEFRAME, ADX_BARS, PRICE_OPEN, MODE_PLUSDI, i);
            MINUSDI[i] = iADX(_symbol, TIMEFRAME, ADX_BARS, PRICE_OPEN, MODE_MINUSDI, i);
            DI[i] = PLUSDI[i] - MINUSDI[i];
        }

        if (ADX[0] < ADX_ENTRY) {
            return NONE;
        }

        if (IsBuyTrend(C, MA_SCAN_BARS, false)) {
            if (IsBuyTrend(DI, ADX_SCAN_BARS, true)) {
                if (B[0] > 0) {
                    return BUY;
                }
            }
        }

        if (IsSellTrend(C, MA_SCAN_BARS, false)) {
            if (IsSellTrend(DI, ADX_SCAN_BARS, true)) {
                if (B[0] < 0) {
                    return SELL;
                }
            }
        }

        return NONE;
    }

    void PostTrailingStop() { }

    double TrailingStep()
    {
        return 0.5 * (_ask + _bid) * TRAILING_STEP_PERCENTAGE / 100.0;
    }

    double StopLoss()
    {
        return STOP_LOSS_RATIO * TrailingStep();
    }

    double TrailingStart()
    {
        return RISK_REWARD_RATIO * StopLoss();
    }

    double TakeProfit()
    {
        return 0.0;
    }

private:
    double O[SIGNAL_ARRAY_SIZE];
    double C[SIGNAL_ARRAY_SIZE];
    double B[SIGNAL_ARRAY_SIZE];
    double ADX[SIGNAL_ARRAY_SIZE];
    double PLUSDI[SIGNAL_ARRAY_SIZE];
    double MINUSDI[SIGNAL_ARRAY_SIZE];
    double DI[SIGNAL_ARRAY_SIZE];
};

ActiveTrader trader[8];
string Symbols[];
int N;

MQL45_APPLICATION_START()

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    N = StringSplit(SYMBOLS, ';', Symbols);
    for (int i = 0; i < N; ++i) {
        trader[i].Initialize(Symbols[i], PeriodSeconds(PERIOD_M1), PeriodSeconds(TIMEFRAME), STOP_BALANCE_PERCENTAGE,  MAGIC, SLIPPAGE);
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
    for (int i = 0; i < N; ++i) {
        trader[i].TrailingStop();
    }
    for (int i = 0; i < N; ++i) {
        trader[i].Trade();
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

MQL45_APPLICATION_END()
