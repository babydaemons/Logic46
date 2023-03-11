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

input double LOTS = 0.01; // ロット
input double MIN_LOTS = 0.1; // 最小ロット
input double MAX_LOTS = 10.0; // 最大ロット
input double BALANCE_PER_LOT = 100000.0; // ロット当たりの証拠金
input double ENTRY_OFFSET_HOURS = 8.50; // 仲値決定前の発注時間差分(hour)
input double EXIT_OFFSET_HOURS = 3.50; // 仲値決定後の決済時間差分(hour)
input bool USE_MM = true; // 複利運用
input int SLIPPAGE = 10; // スリッページ
input int MAGIC = 15151515; // マジックナンバー

MQL45_APPLICATION_START()

int ticket;
double lots;
int ENTRY_OFFSET_MINUTES;
int EXIT_OFFSET_MINUTES;
int HOLD_MINUTES;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    ENTRY_OFFSET_MINUTES = (int)(ENTRY_OFFSET_HOURS * 60);
    EXIT_OFFSET_MINUTES = (int)(EXIT_OFFSET_HOURS * 60);
    HOLD_MINUTES = ENTRY_OFFSET_MINUTES + EXIT_OFFSET_MINUTES;
    ticket = 0;
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
    datetime localtime = AutoSummerTime::TimeLocal();
    datetime servertime = TimeCurrent();

    int offset_minutes = 0;
    if (!IsFiveTenDay(localtime, offset_minutes)) {
        return;
    }

    static datetime entrytime = 0;
    if (ticket == 0 && offset_minutes == -ENTRY_OFFSET_MINUTES) {
        if (USE_MM) {
            lots = MathFloor(AccountInfoDouble(ACCOUNT_BALANCE) / BALANCE_PER_LOT) * LOTS;
            lots = MathMin(MathMax(lots, MIN_LOTS), MAX_LOTS);
        }
        else {
            lots = LOTS;
        }
        ticket = OrderSend("USDJPY", OP_BUY, lots, Ask, SLIPPAGE, 0, 0, "", MAGIC, 0, clrBlue);
        entrytime = servertime;
        return;
    }

    if (ticket != 0) {
        MqlDateTime current = {};
        TimeToStruct(servertime, current);
        if ((offset_minutes == +EXIT_OFFSET_MINUTES) || (servertime > entrytime + HOLD_MINUTES * 60) || (current.day_of_week == 5 && current.hour == 23 && current.min == 45)) {
            if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
                return;
            }
            double profit = OrderProfit() + OrderSwap();
            printf("#%d: +%.0f", ticket, profit);
            if (OrderClose(ticket, lots, Bid, SLIPPAGE, clrRed)) {
                ticket = 0;
            }
            return;
        }
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
bool IsFiveTenDay(datetime localtime, int& offset_minutes)
{
    MqlDateTime dt = {};
    TimeToStruct(localtime, dt);
    offset_minutes = (60 * dt.hour + dt.min) - (10 * 60);

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
