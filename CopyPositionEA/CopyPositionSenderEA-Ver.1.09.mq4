//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "ErrorDescriptionMT4.mqh"
#include "CopyPositionSenderEA.mqh"

//+------------------------------------------------------------------+
//| 現在のポジション全体の状態を走査します                           |
//+------------------------------------------------------------------+
int ScanCurrentPositions(POSITION_LIST& Current)
{
    // 現在のポジション状態を取得する前に
    // 現在の添字が指す配列要素をクリアします
    Current.Clear();

    // 現在のポジション状態を全て取得します
    int position_count = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        // トレード中のポジションを選択します
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) { continue; }

        // EA起動時よりも過去に建てられたポジションはコピー対象外です
        if (OrderOpenTime() <= StartServerTimeEA) { continue;}

        int entry_type = 0;
        switch (OrderType()) {
        case OP_BUY:
            entry_type = +1;
            break;
        case OP_BUYLIMIT:
            entry_type = +2;
            break;
        case OP_BUYSTOP:
            entry_type = +3;
            break;
        case OP_SELL:
            entry_type = -1;
            break;
        case OP_SELLLIMIT:
            entry_type = -2;
            break;
        case OP_SELLSTOP:
            entry_type = -3;
            break;
        default:
            continue;
        }

        Current.Change[position_count] = INT_MAX;
        Current.EntryType[position_count] = entry_type;
        Current.EntryPrice[position_count] = OrderOpenPrice();
        Current.SymbolValue[position_count] = OrderSymbol();
        Current.Tickets[position_count] = OrderTicket();
        Current.Lots[position_count] = OrderLots();
        Current.StopLoss[position_count] = OrderStopLoss();
        Current.TakeProfit[position_count] = OrderTakeProfit();
        Current.OpenTime[position_count] = OrderOpenTime();
        ++position_count;
    }

    return position_count;
}
