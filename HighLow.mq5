//+------------------------------------------------------------------+
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

input int LOT = 1000;
input string INDEX_JP = "JPN225";
input string INDEX_US = "US30";

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
int MARKET_AM_OPEN  = GetSeconds( 9,  0, 0);
int MARKET_AM_CLOSE = GetSeconds(11, 30, 0);
int MARKET_PM_OPEN  = GetSeconds(12, 30, 0);
int MARKET_PM_CLOSE = GetSeconds(15,  0, 0);
int Balance = 25000;
int Position = 0;
double Entry = 0;
int logger = INVALID_HANDLE;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    logger = FileOpen("HighLow.tsv", FILE_WRITE | FILE_SHARE_WRITE | FILE_CSV | FILE_COMMON);
    if (logger == INVALID_HANDLE) {
        printf(ErrorDescription());
        return INIT_FAILED;
    }
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
    if (Position == 0) {
        if (MARKET_AM_OPEN <= t && t < MARKET_AM_CLOSE) {
            Position = GetEntry();
            Entry = SymbolInfoDouble(INDEX_JP, Position == +1 ? SYMBOL_ASK : SYMBOL_BID);
        }
        if (MARKET_PM_OPEN <= t && t < MARKET_PM_CLOSE) {
            Position = GetEntry();
            Entry = SymbolInfoDouble(INDEX_JP, Position == +1 ? SYMBOL_ASK : SYMBOL_BID);
        }
    }
    else {
        if (MARKET_AM_OPEN <= t && t < MARKET_AM_CLOSE) {
            return;
        }
        if (MARKET_PM_OPEN <= t && t < MARKET_PM_CLOSE) {
            return;
        }

        string timestamp = StringFormat("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.mon, d.day, d.hour, d.min, d.sec);
        double Exit = 0;
        if (Position > 0) {
            Exit = SymbolInfoDouble(INDEX_JP, SYMBOL_ASK);
            if (Entry > Exit) {
                Balance += LOT;
            }
            else {
                Balance -= LOT;
            }
        }
        if (Position < 0) {
            Exit = SymbolInfoDouble(INDEX_JP, SYMBOL_ASK);
            if (Entry < Exit) {
                Balance += LOT;
            }
            else {
                Balance -= LOT;
            }
        }
        FileWrite(logger, timestamp, Position, Entry, Exit, Balance);
        Position = 0;
    }
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
int GetEntry()
{
    double dow0[];
    CopyOpen(INDEX_US, PERIOD_D1, 0, 1, dow0);
    double dow1[];
    CopyClose(INDEX_US, PERIOD_D1, 0, 1, dow1);
    //double nk225[];
    //CopyClose(INDEX_JP, PERIOD_H4, 0, 2, dow);
    if (dow0[0] < dow1[0]) {
        return +1;
    }
    else {
        return -1;
    }
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    return Balance;
}
