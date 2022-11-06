//+------------------------------------------------------------------+
//|                                                    TrueTrend.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "TrueTrend.dll"
    double ArrayTrueTrend(const double& value[], int periodseconds, double power, int N);
    double ArrayTrend(const double& value[], int periodseconds, int N);
    double ArrayCorrelation(const double& value[], int periodseconds, int N);
    double iSMA(const double& value[], int N);
#import

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrend(string symbol, ENUM_TIMEFRAMES tf, int N)
{
    double value[];
    int n = CopyOpen(symbol, tf, 0, N, value);
    int periodseconds = PeriodSeconds(tf);
    return ArrayTrend(value, periodseconds, n);
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(string symbol, ENUM_TIMEFRAMES tf, int N)
{
    double value[];
    int n = CopyOpen(symbol, tf, 0, N, value);
    int periodseconds = PeriodSeconds(tf);
    return ArrayCorrelation(value, periodseconds, n);
}

//+------------------------------------------------------------------+
//| 傾きの算出                                                       |
//+------------------------------------------------------------------+
double iTrueTrend(string symbol, ENUM_TIMEFRAMES tf, double power, int N)
{
    double value[];
    int n = CopyOpen(symbol, tf, 0, N, value);
    int periodseconds = PeriodSeconds(tf);
    return ArrayTrueTrend(value, periodseconds, power, n);
}
