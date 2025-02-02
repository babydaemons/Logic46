﻿//+------------------------------------------------------------------+
//|                                                      Logic46.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "AutoSummerTime5.mqh"
#include "AtelierLapin/Lib/MT5/ErrorDescription.mqh"

input int INIT_LOT = 1000;
input string INDEX_JP = "JPN225";
input string INDEX_US = "US30";
input double THRESHOLD_CHANGE_US = 0.20;
input double THRESHOLD_RSI_JP = 13.0;

//+------------------------------------------------------------------+
//| 経過秒数を返す                                                   |
//+------------------------------------------------------------------+
int GetSeconds(int hour, int minutes, int seconds)
{
    return 60 * (60 * hour + minutes) + seconds;
}

/*
 * 日経225の表示名は「JPN225」
 * 1日取引のみ可能
 * HighLow：1.88倍（ペイアウト率）
 * HighLowスプレッド：2.00倍（ペイアウト率）
 * 取引可能時間「9:00～11：30」「12:30～15:00」
 */
int MARKET_JP_AM_OPEN  = GetSeconds( 9,  0, 0);
int MARKET_JP_AM_CLOSE = GetSeconds(11, 30, 0);
int MARKET_JP_PM_OPEN  = GetSeconds(12, 30, 0);
int MARKET_JP_PM_CLOSE = GetSeconds(15,  0, 0);
int MARKET_US_OPEN     = GetSeconds( 9, 30, 0);
int MARKET_US_CLOSE    = GetSeconds(16,  0, 0);
int Balance = 25000;
int Position = 0;
double Entry_jp = 0;
double Exit_jp = 0;
int logger = INVALID_HANDLE;

double Dow0 = 0;
double Dow1 = 0;
double Signal_us = 0;
double Signal_jp = 0;

int hRSI_jp = INVALID_HANDLE;

double WeeklyProfit[];
double WeeklyBalance[];
int DayOfWeek = -1;
int N = -1;

int LOT = 0;
int InitialBalance = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    if (MQLInfoInteger(MQL_OPTIMIZATION) == 0) {
        logger = FileOpen("HighLow.tsv", FILE_WRITE | FILE_SHARE_WRITE | FILE_CSV | FILE_COMMON);
        if (logger == INVALID_HANDLE) {
            printf(ErrorDescription());
            return INIT_FAILED;
        }
    }
    hRSI_jp = iRSI(INDEX_JP, PERIOD_H1, 5 * 24, PRICE_CLOSE);
    if (hRSI_jp == INVALID_HANDLE) {
        printf(ErrorDescription());
        return INIT_FAILED;
    }
    InitialBalance = Balance;
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    FileClose(logger);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    datetime localtime = AutoSummerTime::TimeLocal();
    MqlDateTime d = {};
    TimeToStruct(localtime, d);
    int t = GetSeconds(d.hour, d.min, d.sec);
    if (DayOfWeek != d.day_of_week) {
        DayOfWeek = d.day_of_week;
        ++N;
        ArrayResize(WeeklyProfit, N + 1);
        ArrayResize(WeeklyBalance, N + 1);
        WeeklyBalance[N] = Balance;
        int m = (int)(10 * Balance / (double)InitialBalance);
        if (m < 10) { m = 10; }
        LOT = m * INIT_LOT / 10;
    }
    if (Position == 0) {
        if (MARKET_JP_AM_OPEN <= t && t < MARKET_JP_AM_CLOSE) {
            Position = GetEntry(true);
            Entry_jp = SymbolInfoDouble(INDEX_JP, Position != -1 ? SYMBOL_ASK : SYMBOL_BID);
            if (Position != 999) {
                Balance -= LOT;
            }
        }
        if (MARKET_JP_PM_OPEN <= t && t < MARKET_JP_PM_CLOSE) {
            Position = GetEntry(false);
            Entry_jp = SymbolInfoDouble(INDEX_JP, Position != -1 ? SYMBOL_ASK : SYMBOL_BID);
            if (Position != 999) {
                Balance -= LOT;
            }
        }
    }
    else {
        if (MARKET_JP_AM_OPEN <= t && t < MARKET_JP_AM_CLOSE) {
            return;
        }
        if (MARKET_JP_PM_OPEN <= t && t < MARKET_JP_PM_CLOSE) {
            return;
        }

        string timestamp = StringFormat("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.mon, d.day, d.hour, d.min, d.sec);
        string result = "L";
        if (Position == +1) {
            Exit_jp = SymbolInfoDouble(INDEX_JP, SYMBOL_ASK);
            if (Entry_jp < Exit_jp) {
                Balance += 2 * LOT;
                result = "W";
                WeeklyProfit[N] += LOT;
            }
            else {
                WeeklyProfit[N] -= LOT;
            }
        }
        else if (Position == -1) {
            Exit_jp = SymbolInfoDouble(INDEX_JP, SYMBOL_BID);
            if (Entry_jp < Exit_jp) {
                Balance += 2 * LOT;
                result = "W";
                WeeklyProfit[N] += LOT;
            }
            else {
                WeeklyProfit[N] -= LOT;
            }
        }
        else {
            Exit_jp = SymbolInfoDouble(INDEX_JP, SYMBOL_ASK);
            result = "-";
        }
        if (logger != INVALID_HANDLE) {
            string signal_us = StringFormat("%+.3f", Signal_us);
            string signal_jp = StringFormat("%+.3f", Signal_jp);
            FileWrite(logger, timestamp, Position, Dow0, Dow1, signal_us, Entry_jp, Exit_jp, signal_jp, LOT, result, Balance);
        }
        Position = 0;
    }
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
int GetEntry(bool is_am_market)
{
    if (is_am_market) {
        double dow0[];
        CopyOpen(INDEX_US, PERIOD_D1, 0, 1, dow0);
        Dow0 = dow0[0];
    
        double dow1[];
        CopyClose(INDEX_US, PERIOD_D1, 0, 1, dow1);
        Dow1 = dow1[0];
    }

    Signal_us = 100.0 * (Dow1 - Dow0) / Dow0;

    double rsi_jp[];
    CopyBuffer(hRSI_jp, MAIN_LINE, 0, 1, rsi_jp);
    Signal_jp = rsi_jp[0] - 50.0;

    if (Signal_us > +THRESHOLD_CHANGE_US && Signal_jp < +THRESHOLD_RSI_JP) {
        return +1;
    }
    if (Signal_us < -THRESHOLD_CHANGE_US && Signal_jp > -THRESHOLD_RSI_JP) {
        return -1;
    }
    return 999;
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    return SharpeRatioWeekly() * Balance;
}

//+------------------------------------------------------------------+
//| https://qiita.com/LitopsQ/items/494be412b3f96d26784b             |
//+------------------------------------------------------------------+
double SharpeRatioWeekly()
{
    ++N;
    double WeeklyEarningRate[];
    ArrayResize(WeeklyEarningRate, N);
    double SumMER = 0;

    for (int i = 0; i < N; ++i) {
        WeeklyEarningRate[i] = WeeklyProfit[i] / WeeklyBalance[i];
        SumMER += WeeklyEarningRate[i];
    }

    double MER_Average = SumMER / N;
    double MER_SD = CalcSD(WeeklyEarningRate);
    double SR = 0;
    if (MER_SD != 0) SR = MER_Average / MER_SD; // ゼロ割を回避
    return SR;
}

double CalcSD(const double& x[])
{
    const int n = ArraySize(x);
    double sum_x = 0;
    for (int i = 0; i < n; ++i) {
        sum_x += x[i];
    }
    const double mu = sum_x / N;
    double sum_xx = 0;
    for (int i = 0; i < n; ++i) {
        const double dx = x[i] - mu;
        sum_xx += dx * dx;
    }
    const double var = sum_xx / n;
    const double sd = MathSqrt(var);
    return sd;
}