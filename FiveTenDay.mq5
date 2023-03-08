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
#include "AutoSummerTime.mqh"

input double LOTS = 0.1; // ロット
input double MIN_LOTS = 0.1; // 最小ロット
input double MAX_LOTS = 10.0; // 最大ロット
input double BALANCE_PER_LOT = 100000.0; // ロット当たりの証拠金
input bool USE_MM = true; // 複利運用
input int SLIPPAGE = 10; // スリッページ
input int MAGIC = 15151515; // マジックナンバー

MQL45_APPLICATION_START()

int ticket;
double lots;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    return INIT_SUCCEEDED;
    ticket = 0;
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
    datetime localtime = AutoSummerTime::TimeLocal();

    int hour = 0;
    int minute = 0;
    if (!IsFiveTenDay(localtime, hour, minute)) {
        return;
    }

    if (ticket == 0 && hour == 8 && minute == 30) {
        if (USE_MM) {
            lots = MathFloor(AccountInfoDouble(ACCOUNT_BALANCE) / BALANCE_PER_LOT) * LOTS;
            lots = MathMin(MathMax(lots, MIN_LOTS), MAX_LOTS);
        }
        else {
            lots = LOTS;
        }
        ticket = OrderSend("USDJPY", OP_BUY, lots, Ask, SLIPPAGE, 0, 0, "", MAGIC, 0, clrBlue);
        return;
    }

    if (ticket != 0 && hour == 12 && minute == 30) {
        if (OrderClose(ticket, lots, Bid, SLIPPAGE, clrRed)) {
            ticket = 0;
        }
        return;
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
    return 0;
}

//+------------------------------------------------------------------+
//| ゴトー日かチェックする                                           |
//+------------------------------------------------------------------+
bool IsFiveTenDay(datetime localtime, int& hour, int& minute)
{
    MqlDateTime dt = {};
    TimeToStruct(localtime, dt);
    hour = dt.hour;
    minute = dt.min;

    // https://gemforex.com/media/beginner/510/
    switch (dt.day) {
        case  5:
        case 10:
        case 15:
        case 20:
        case 25:
        case 30:
            return true;
        case  3:
        case  4:
        case  8:
        case  9:
        case 13:
        case 14:
        case 18:
        case 19:
        case 23:
        case 24:
        case 28:
        case 29:
            if (dt.day_of_week == 5) {
                return true;
            }
            break;
    }
    return false;
}

MQL45_APPLICATION_END()
