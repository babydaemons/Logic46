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
input string            SYMBOLS = "USDJPY;EURUSD;GBPUSD;AUDUSD;EURJPY;GBPJPY;AUDJPY";
input E_TIMEFRAMES      TF = TIMEFRAME_H04;

input int               BAR_SCAN_BARS = 6;

input int               N = 30;
input int               M = 2;
input int               L = 7;
input int               EMA_SCAN_BARS = 10;

input int               ATR_BARS = 30;
input int               ATR_ENTRY = 20;
input int               ATR_SCAN_BARS = 10;

input double            TRAILING_STEP_PERCENTAGE = 45.0;
input double            STOP_LOSS_RATIO = 10.0;
input double            RISK_REWARD_RATIO = 4.0;

input double            ACCOUNT_TRAILING_RATIO = 0.25;
input double            ACCOUNT_TAKEPROFIT_RATIO = 0.75;

input double            LOT = 0.01;
sinput int              STOP_BALANCE_PERCENTAGE = 25;
sinput int              SLIPPAGE = 10;
sinput int              MAGIC = 20220724;

#define EMA_BARS1 N
#define EMA_BARS2 (N * M)
#define EMA_BARS3 (N * M * L)

#define TIMEFRAME TIMEFRAMES[TF]

#define SIGNAL_ARRAY_SIZE 256

class ActiveEMA DERIVERED_MQL45 {
public:
    ActiveEMA() { }

#include "AbstractTrader.mqh"

protected:
    void DoInitialize()
    {
    }

    TRADE_TYPE DoTrade(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        double position_count = MathMax(_position_counts[0], _position_counts[1]) + 1;
        double compound_interest = RemainingMargin() / _init_margin;
        lots = LOT;
        lots *= MathMax(MathFloor(position_count * compound_interest), 1.0);

        close_type = NONE;

        for (int i = 0; i < BAR_SCAN_BARS; ++i) {
            O[i] = ::iOpen(_symbol, TIMEFRAME, i);
            B[i] = ::iClose(_symbol, TIMEFRAME, i + 1) - ::iOpen(_symbol, TIMEFRAME, i + 1);
        }
        
        for (int i = 0; i < ATR_SCAN_BARS; ++i) {
            ATR[i] = iATR(_symbol, TIMEFRAME, ATR_BARS, i);
        }
        
        for (int i = 0; i < EMA_SCAN_BARS; ++i) {
            EMA1[i] = iMA(_symbol, TIMEFRAME, EMA_BARS1, 0, MODE_EMA, PRICE_OPEN, i);
            EMA2[i] = iMA(_symbol, TIMEFRAME, EMA_BARS2, 0, MODE_EMA, PRICE_OPEN, i);
            EMA3[i] = iMA(_symbol, TIMEFRAME, EMA_BARS3, 0, MODE_EMA, PRICE_OPEN, i * EMA_BARS3);
            D1[i] = EMA1[i] - EMA2[i];
        }

        TRADE_TYPE type1 = DoTrade1(lots, comment, close_type);
        if (type1 != NONE) {
            return type1;
        }
/*
        TRADE_TYPE type2 = DoTrade2(lots, comment, close_type);
        if (type2 != NONE) {
            return type2;
        }
*/
        return NONE;
    }

    TRADE_TYPE DoTrade1(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (_position_average_profits[BUY] >= 0 && O[0] > O[1] && B[0] > 0 && EMA3[0] > EMA3[1] && IsBuyStart(EMA1, EMA_SCAN_BARS, false) && IsBuyStart(EMA2, EMA_SCAN_BARS, false)) {
            if (IsBuyStart(D1, EMA_SCAN_BARS, true)) {
                comment = "BuyStart";
                close_type = SELL;
                return BUY;
            }
            if (IsSellEnd(D1, EMA_SCAN_BARS, true)) {
                comment = "SellEnd";
                close_type = SELL;
                return BUY;
            }
        }

        if (ATR[0] < ATR_ENTRY) {
            return NONE;
        }
        if (!IsBuyStart(ATR, ATR_SCAN_BARS, false)) {
            return NONE;
        }

        if (_position_average_profits[SELL] >= 0 && O[0] < O[1] && B[0] < 0 && EMA3[0] < EMA3[1] && IsSellStart(EMA1, EMA_SCAN_BARS, false) && IsSellStart(EMA2, EMA_SCAN_BARS, false)) {
            if (IsSellStart(D1, EMA_SCAN_BARS, true)) {
                comment = "SellStart";
                close_type = SELL;
                return SELL;
            }
            if (IsBuyEnd(D1, EMA_SCAN_BARS, true)) {
                comment = "BuyEnd";
                close_type = SELL;
                return SELL;
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade2(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsBuyStart(O, BAR_SCAN_BARS, false) && IsBuyTrend(B, BAR_SCAN_BARS)) {
            comment = "Bars";
            close_type = SELL;
            return BUY;
        }

        if (IsSellStart(O, BAR_SCAN_BARS, false) && IsSellTrend(B, BAR_SCAN_BARS)) {
            comment = "Bars";
            close_type = BUY;
            return SELL;
        }

        return NONE;
    }

    void PostTrailingStop()
    {
        double trailing_start_profit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
        for (int type = BUY; type <= SELL; ++type) {
            if (trailing_start_profit < _position_profits[type] && _position_profits[type] < ACCOUNT_TAKEPROFIT_RATIO * _position_max_profits[type]) {
                CloseAll("Take Profit", (TRADE_TYPE)type);
                _position_max_profits[type] = 0;
            }
        }
        if (_position_average_profits[BUY] != 0 && _position_profits[SELL] != 0) {
            CloseAll("Closs", _position_average_profits[BUY] < _position_profits[SELL] ? BUY : SELL);
        }
    }

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
    double B[SIGNAL_ARRAY_SIZE];
    double ATR[SIGNAL_ARRAY_SIZE];
    double EMA1[SIGNAL_ARRAY_SIZE];
    double EMA2[SIGNAL_ARRAY_SIZE];
    double EMA3[SIGNAL_ARRAY_SIZE];
    double D1[SIGNAL_ARRAY_SIZE];
};

ActiveEMA trader[8];
string Symbols[];
int SymbolCount;

MQL45_APPLICATION_START()

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    SymbolCount = StringSplit(SYMBOLS, ';', Symbols);
    for (int i = 0; i < SymbolCount; ++i) {
        trader[i].Initialize(Symbols[i], PeriodSeconds(PERIOD_M1), PeriodSeconds(TIMEFRAME), STOP_BALANCE_PERCENTAGE, MAGIC, SLIPPAGE);
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
    for (int i = 0; i < SymbolCount; ++i) {
        trader[i].TrailingStop();
    }
    for (int i = 0; i < SymbolCount; ++i) {
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
