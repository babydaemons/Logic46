//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq5 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include <Trade/Trade.mqh>
#include "ErrorDescriptionMT5.mqh"
#include "CopyPositionSenderEA.mqh"

CTrade Trader;

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
    for (int i = 0; i < PositionsTotal(); ++i) {
        // トレード中のポジションを選択します
        ulong ticket = PositionGetTicket(i);
        if (ticket == 0) { continue; }

        // EA起動時よりも過去に建てられたポジションはコピー対象外です
        if ((datetime)PositionGetInteger(POSITION_TIME) <= StartServerTimeEA) { continue; }

        int entry_type = 0;
        switch ((int)PositionGetInteger(POSITION_TYPE)) {
        case POSITION_TYPE_BUY:
            entry_type = +1;
            break;
        case POSITION_TYPE_SELL:
            entry_type = -1;
            break;
        default:
            continue;
        }

        Current.Change[position_count] = INT_MAX;
        Current.EntryType[position_count] = entry_type;
        Current.EntryPrice[position_count] = PositionGetDouble(POSITION_PRICE_OPEN);
        Current.SymbolValue[position_count] = PositionGetString(POSITION_SYMBOL);
        Current.Tickets[position_count] = (int)ticket;
        Current.Lots[position_count] = PositionGetDouble(POSITION_VOLUME);
        Current.StopLoss[position_count] = PositionGetDouble(POSITION_SL);
        Current.TakeProfit[position_count] = PositionGetDouble(POSITION_TP);
        Current.OpenTime[position_count] = (datetime)PositionGetInteger(POSITION_TIME);
        ++position_count;
    }

    // 現在の待機中オーダー状態を全て取得します
    for (int i = 0; i < OrdersTotal(); ++i) {
        // トレード中のポジションを選択します
        ulong ticket = OrderGetTicket(i);
        if (ticket == 0) { continue; }

        // EA起動時よりも過去に建てられたポジションはコピー対象外です
        if ((datetime)OrderGetInteger(ORDER_TIME_SETUP) <= StartServerTimeEA) { continue; }

        int entry_type = 0;
        switch ((int)OrderGetInteger(ORDER_TYPE)) {
        case ORDER_TYPE_BUY:
            entry_type = +1;
            break;
        case ORDER_TYPE_BUY_LIMIT:
            entry_type = +2;
            break;
        case ORDER_TYPE_BUY_STOP:
            entry_type = +3;
            break;
        case ORDER_TYPE_SELL:
            entry_type = -1;
            break;
        case ORDER_TYPE_SELL_LIMIT:
            entry_type = -2;
            break;
        case ORDER_TYPE_SELL_STOP:
            entry_type = -3;
            break;
        default:
            continue;
        }

        Current.Change[position_count] = INT_MAX;
        Current.EntryType[position_count] = entry_type;
        Current.EntryPrice[position_count] = OrderGetDouble(ORDER_PRICE_OPEN);
        Current.SymbolValue[position_count] = OrderGetString(ORDER_SYMBOL);
        Current.Tickets[position_count] = (int)ticket;
        Current.Lots[position_count] = OrderGetDouble(ORDER_VOLUME_CURRENT);
        Current.StopLoss[position_count] = OrderGetDouble(ORDER_SL);
        Current.TakeProfit[position_count] = OrderGetDouble(ORDER_TP);
        Current.OpenTime[position_count] = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
        ++position_count;
    }

    return position_count;
}
