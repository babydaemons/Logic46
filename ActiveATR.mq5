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
//input string            SYMBOLS = "USDJPY;EURUSD;GBPUSD;USDCHF;AUDUSD;EURJPY;GBPJPY;CHFJPY;AUDJPY";
//input string            SYMBOLS = "USDJPY;EURUSD;GBPUSD;USDCHF;AUDUSD";
input string            SYMBOLS = "USDJPY";
input E_TIMEFRAMES      TF = TIMEFRAME_H01;
input double            MIN_MARGIN_LEVEL = 2000.0;
input bool              NANPIN_ENABLED = false;

input int               BAR_SCAN_BARS = 6;

input int               N = 24;
input int               M = 5;
input int               EMA_SCAN_BARS = 6;

input int               ATR_BARS = 30;
input int               ATR_SCAN_BARS = 12;
input double            ATR_TRAILING_RATIO = 1.0;
input double            ATR_STOPLOSS_RATIO = 12.0;
input double            ATR_RISKREWARD_RATIO = 0.5;

input double            ACCOUNT_TRAILING_RATIO = 0.100;
input double            ACCOUNT_TAKEPROFIT_RATIO = 0.650;
input double            ACCOUNT_STOPLOSS_RATIO = 0.050;

input double            LOT = 0.01;
sinput int              STOP_BALANCE_PERCENTAGE = 40;
sinput int              SLIPPAGE = 10;
sinput int              MAGIC = 20220730;

string CommentAll;

#define EMA_BARS1 N
#define EMA_BARS2 (N * M)

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
        if (364 < DayOfYear()) {
            return NONE;
        }

        if (Hour() == 23 || Hour() == 0) {
            return NONE;
        }

        double position_count = MathMax(_position_counts[0], _position_counts[1]) + 1;
        double compound_interest = RemainingMargin() / _init_margin;
        lots = LOT;
        lots *= MathMax(MathFloor(position_count * compound_interest), 1.0);

        close_type = NONE;

        for (int i = 0; i < ATR_SCAN_BARS; ++i) {
            ATR[i] = iATR(_symbol, TIMEFRAME, ATR_BARS, i);
        }
        
        for (int i = 0; i < BAR_SCAN_BARS; ++i) {
            O[i] = ::iOpen(_symbol, TIMEFRAME, i);
            B[i] = ::iClose(_symbol, TIMEFRAME, i + 1) - ::iOpen(_symbol, TIMEFRAME, i + 1);
        }
        
        for (int i = 0; i < EMA_SCAN_BARS + 1; ++i) {
            EMA1[i] = iMA(_symbol, TIMEFRAME, EMA_BARS1, 0, MODE_EMA, PRICE_OPEN, i);
            EMA2[i] = iMA(_symbol, TIMEFRAME, EMA_BARS2, 0, MODE_EMA, PRICE_OPEN, i);
            D1[i] = EMA1[i] - EMA2[i];
        }

        TD1[0] = TD1[1] = 0;
        for (int i = 0; i < EMA_SCAN_BARS + 1; ++i) {
            TD1[0] += D1[i];
            TD1[1] += D1[i + 1];
        }

/*
        TRADE_TYPE type0 = DoTrade0(lots, comment, close_type);
        if (type0 != NONE) {
            return type0;
        }
*/

        TRADE_TYPE type1 = DoTrade1(lots, comment, close_type);
        if (type1 != NONE) {
            return type1;
        }

        TRADE_TYPE type2 = DoTrade2(lots, comment, close_type);
        if (type2 != NONE) {
            return type2;
        }

        TRADE_TYPE type3 = DoTrade3(lots, comment, close_type);
        if (type3 != NONE) {
            return type3;
        }

        TRADE_TYPE type4 = DoTrade4(lots, comment, close_type);
        if (type4 != NONE) {
            return type4;
        }

/*
        TRADE_TYPE type5 = DoTrade5(lots, comment, close_type);
        if (type5 != NONE) {
            return type4;
        }
*/

        return NONE;
    }

    TRADE_TYPE DoTrade0(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsSellTrend(B, BAR_SCAN_BARS) && IsSellStart(EMA1, EMA_SCAN_BARS, false)) {
            comment = "SellChange";
            close_type = NONE;
            return SELL;
        }

        if (IsBuyTrend(B, BAR_SCAN_BARS) && IsBuyStart(EMA1, EMA_SCAN_BARS, false)) {
            comment = "BuyChange";
            close_type = NONE;
            return BUY;
        }

        return NONE;
    }


    TRADE_TYPE DoTrade1(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsEntryEnabled(BUY)) {
            if (D1[1] < 0 && D1[0] > 0) {
                comment = "BuyCross";
                close_type = NONE;
                return BUY;
            }
        }

        if (IsEntryEnabled(SELL)) {
            if (D1[1] > 0 && D1[0] < 0) {
                comment = "SellCross";
                close_type = NONE;
                return SELL;
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade2(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsEntryEnabled(BUY) && O[0] > O[1] && B[0] > 0) {
            if (EMA1[0] > EMA1[1] && EMA2[0] > EMA2[1]) {
                if (TD1[0] > TD1[1]) {
                    if (IsBuyTrend(B, BAR_SCAN_BARS)) {
                        comment = "BuyTrend";
                        close_type = SELL;
                        return BUY;
                    }
                }
            }
        }

        if (IsEntryEnabled(SELL) && O[0] < O[1] && B[0] < 0) {
            if (EMA1[0] < EMA1[1] && EMA2[0] < EMA2[1]) {
                if (TD1[0] < TD1[1]) {
                    if (IsSellTrend(B, BAR_SCAN_BARS)) {
                        comment = "SellTrend";
                        close_type = BUY;
                        return SELL;
                    }
                }
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade3(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsEntryEnabled(BUY) && IsBuyStart(O, BAR_SCAN_BARS, false) && IsBuyTrend(B, BAR_SCAN_BARS) && D1[0] > 0) {
            comment = "Bars";
            close_type = SELL;
            return BUY;
        }

        if (IsEntryEnabled(SELL) && IsSellStart(O, BAR_SCAN_BARS, false) && IsSellTrend(B, BAR_SCAN_BARS) && D1[0] < 0) {
            comment = "Bars";
            close_type = BUY;
            return SELL;
        }

        return NONE;
    }

    TRADE_TYPE DoTrade4(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        if (IsEntryEnabled(BUY) && IsBuyTrend(B, BAR_SCAN_BARS)) {
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
        if (IsEntryEnabled(SELL) && IsBuyTrend(B, BAR_SCAN_BARS)) {
            if (IsSellStart(D1, EMA_SCAN_BARS, true)) {
                comment = "SellStart";
                close_type = BUY;
                return SELL;
            }
            if (IsBuyEnd(D1, EMA_SCAN_BARS, true)) {
                comment = "BuyEnd";
                close_type = BUY;
                return SELL;
            }
        }

        return NONE;
    }

    TRADE_TYPE DoTrade5(double& lots, string& comment, TRADE_TYPE& close_type)
    {
        double min_entry_profit = ACCOUNT_TRAILING_RATIO * RemainingMargin();
        if (IsEntryEnabled(BUY) && _position_profits[BUY] > min_entry_profit) {
            if (IsBuyTrend(D1, EMA_SCAN_BARS)) {
                comment = "BuyDiff";
                close_type = NONE;
                return BUY;
            }
        }
        if (IsEntryEnabled(SELL) && _position_profits[SELL] > min_entry_profit) {
            if (IsSellTrend(D1, EMA_SCAN_BARS)) {
                comment = "SellStart";
                close_type = NONE;
                return SELL;
            }
        }

        return NONE;
    }

    bool IsEntryEnabled(TRADE_TYPE type)
    {
        if (NANPIN_ENABLED) {
            return true;
        }

        TRADE_TYPE type1 = type;
        TRADE_TYPE type2 = type == BUY ? SELL : BUY;
        
        double spread = MarketInfo(_symbol, MODE_SPREAD);
        if (_position_average_profits[type1] >= -spread) {
            return true;
        }
        if (_position_average_profits[type2] <= -spread) {
            return true;
        }
        
        return false;
    }

    void PostTrailingStop()
    {
        double trailing_start_profit = RemainingMargin() * ACCOUNT_TRAILING_RATIO;
        for (int type = BUY; type <= SELL; ++type) {
            if (trailing_start_profit < _position_profits[type] && _position_profits[type] < ACCOUNT_TAKEPROFIT_RATIO * _position_max_profits[type]) {
                CloseAll((TRADE_TYPE)type);
            }
            if (_position_profits[type] < -ACCOUNT_STOPLOSS_RATIO * RemainingMargin()) {
                CloseAll((TRADE_TYPE)type);
            }
        }
        if (_position_average_profits[BUY] != 0 && _position_profits[SELL] != 0) {
            CloseAll(_position_average_profits[BUY] < _position_profits[SELL] ? BUY : SELL);
        }
    }

    double TrailingStep()
    {
        return ATR_TRAILING_RATIO * ATR[0] / _point;
    }

    double StopLoss()
    {
        return ATR_STOPLOSS_RATIO * TrailingStep();
    }

    double TrailingStart()
    {
        return ATR_RISKREWARD_RATIO * StopLoss();
    }

    double TakeProfit()
    {
        return 0.0;
    }

private:
    double ATR[SIGNAL_ARRAY_SIZE];
    double O[SIGNAL_ARRAY_SIZE];
    double B[SIGNAL_ARRAY_SIZE];
    double EMA1[SIGNAL_ARRAY_SIZE];
    double EMA2[SIGNAL_ARRAY_SIZE];
    double D1[SIGNAL_ARRAY_SIZE];
    double TD1[2];
};

ActiveEMA trader[16];
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
        trader[i].Initialize(Symbols[i], PeriodSeconds(PERIOD_M1), PeriodSeconds(TIMEFRAME), MIN_MARGIN_LEVEL, STOP_BALANCE_PERCENTAGE, MAGIC, SLIPPAGE);
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
    Comment(StringFormat("RemainingMargin: %.0f\nMarginLevel: %.2f%%", ActiveEMA::RemainingMargin(), AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)));
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
