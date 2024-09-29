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

input double ENTRY_OFFSET_HOURS = 4.0; // 仲値決定前の発注時間差分(hour)
input double EXIT_OFFSET_HOURS = 6.0; // 仲値決定後の決済時間差分(hour)
input int TREND_SCAN_BARS = 2; // トレンド確認するバーの本数(hour)
input int VOLATILITY_SCAN_BARS = 4; // ボラティリティ確認するバーの本数(hour)
input double STDDEV_VOLATILITY_RATIO = 1.0; // ストップロスを算出する時の標準偏差に対する係数
sinput bool USE_MM = true; // 複利運用するか
sinput double LOTS = 0.01; // ロット数(複利運用時0.00)
sinput double RISK_RATIO_PERCENTAGE = 25.0; // 許容リスクパーセンテージ(%))
sinput double MAX_LOTS = 0.0; // 最大ロット数(0.0で自動設定)
sinput double MIN_MARGIN_LEVEL = 150.0; // 最低証拠金維持率(%)
sinput int SLIPPAGE = 10; // スリッページ
sinput int MAGIC = 15151515; // マジックナンバー

MQL45_APPLICATION_START

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
        double close[];
        if (CopyClose(Symbol(), PERIOD_H1, 0, TREND_SCAN_BARS, close) != TREND_SCAN_BARS) {
            return;
        }
        for (int i = 1; i < TREND_SCAN_BARS; ++i) {
            if (close[i + 0] <= close[i - 1]) {
                return;
            }
        }
        double SL = 0;
        double sl = GetStopLoss(SL);
        if (sl == 0.0) {
            return;
        }
        if (USE_MM) {
            double risk_lots = GrtMaxLotRiskBalance(RISK_RATIO_PERCENTAGE, SL);
            double margin_level_lots = GetMaxLotMarginLevel(MIN_MARGIN_LEVEL, MAX_LOTS);
            lots = MathMin(risk_lots, margin_level_lots);
        }
        else {
            lots = LOTS;
        }
        ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, SLIPPAGE, sl, 0, "", MAGIC, 0, clrBlue);
        entrytime = servertime;
        return;
    }

    static double profit;
    if (ticket != 0) {
        if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
            printf("#%d: +%.0f", ticket, profit);
            ticket = 0;
            return;
        }
        profit = OrderProfit() + OrderSwap();
        MqlDateTime current = {};
        TimeToStruct(servertime, current);
        if ((offset_minutes == +EXIT_OFFSET_MINUTES) || (servertime > entrytime + HOLD_MINUTES * 60) || (current.day_of_week == 5 && current.hour == 23 && current.min == 45)) {
            if (!OrderSelect(ticket, SELECT_BY_TICKET)) {
                return;
            }
            printf("#%d: +%.0f", ticket, profit);
            if (OrderClose(ticket, lots, Bid, SLIPPAGE, clrRed)) {
                ticket = 0;
            }
            return;
        }
        double SL = 0;
        double sl = GetStopLoss(SL);
        if (sl == 0.0) {
            return;
        }
        if (sl > OrderStopLoss() && !OrderModify(ticket, Bid, sl, 0, 0, clrNONE)) {
            printf("OrderModify() ERROR");
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
//| ストップロスを返す                                               |
//+------------------------------------------------------------------+
double GetStopLoss(double& SL)
{
    SL = STDDEV_VOLATILITY_RATIO * iStdDev(Symbol(), PERIOD_H1, VOLATILITY_SCAN_BARS, 0, MODE_SMA, PRICE_CLOSE, 0);
    if (SL == 0.0) {
        return 0.0;
    }
    double sl = MathFloor(SL * MathPow(10, Digits)) / MathPow(10, Digits);
    return sl;
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
//| 許容リスク額に対するロット数を計算する                           |
//| 【参考】 https://fxxy.org/23859.html                             |
//+------------------------------------------------------------------+
double GrtMaxLotRiskBalance(double risk_percentage, double SL) {
    double risk_amount = 0.01 * risk_percentage * AccountInfoDouble(ACCOUNT_BALANCE);
    double risk_lots = MathFloor(((risk_amount / SL) / 100000) * 100) / 100;
    return risk_lots;
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
double GetMaxLotMarginLevel(double min_margin_level, double max_lot)
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

MQL45_APPLICATION_END
