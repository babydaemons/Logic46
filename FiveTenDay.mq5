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

input double ENTRY_OFFSET_HOURS = 3.50; // 仲値決定前の発注時間差分(hour)
input double EXIT_OFFSET_HOURS = 3.70; // 仲値決定後の決済時間差分(hour)
sinput bool USE_MM = true; // 複利運用
sinput double LOTS = 0.01; // ロット数
sinput double MAX_LOTS = 0.0; // 最大ロット数(0.0で自動設定)
sinput double MIN_MARGIN_LEVEL = 400.0; // 最低証拠金維持率(%)
sinput int SLIPPAGE = 10; // スリッページ
sinput int MAGIC = 15151515; // マジックナンバー

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
    bool is_five_ten_day = IsFiveTenDay(localtime, offset_minutes);
    static datetime entrytime = 0;
    if (is_five_ten_day && ticket == 0 && offset_minutes == -ENTRY_OFFSET_MINUTES) {
        if (USE_MM) {
            lots = GetMaxLot(MIN_MARGIN_LEVEL, MAX_LOTS);
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

//+------------------------------------------------------------------+
//|【関数】 証拠金維持率に対してのロット数を取得する
//| 
//|【引数】 min_margin_level:証拠金維持率  (200%に設定したい場合、200)
//|         max_lot:最大ロット数を設定する (0設定で、自動取得) 
//|
//|【戻値】 ロット数(1000通貨=0.01) 
//|
//|【参考】 https://fx-prog.com/ea-sorce7/ 
//+------------------------------------------------------------------+
double GetMaxLot(double min_margin_level, double max_lot)
{
    // 最大ロット数確認
    double broker_max_lot = MarketInfo(Symbol(), MODE_MAXLOT);
    double broker_min_lot = MarketInfo(Symbol(), MODE_MINLOT);

    if (max_lot == 0 || max_lot > broker_max_lot) {
        max_lot = broker_max_lot;
    }

    // 口座残高
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);

    // 利用可能金額算出
    double notional_amount = balance / (0.01 * min_margin_level);

    // 必要証拠金(1ロット分)で割る
    double result_lot = notional_amount / MarketInfo(Symbol(), MODE_MARGINREQUIRED);

    // 少数点を0.01単位までにする
    double normalize_lot = MathFloor(result_lot / broker_min_lot) * broker_min_lot;

    // 最大ロット数を超えている場合は、最大ロット数にする
    return MathMin(normalize_lot, max_lot);
}

MQL45_APPLICATION_END()
