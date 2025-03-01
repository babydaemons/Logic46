﻿//+------------------------------------------------------------------+
//|                                        Lib/AtlierLapinCommon.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| 指定マジックナンバーの全損益の取得                               |
//+------------------------------------------------------------------+
double GetMagicNumberProfit() {
    ulong magic_number = GetMagicNumber();
    double profit = 0;
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != magic_number) {
            continue;
        }
        profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション全決済                           |
//+------------------------------------------------------------------+
void SendOrderCloseAll() {
    int magic_number = GetMagicNumber();
    for (int i = PositionsTotal() - 1; i >= 0; --i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetInteger(POSITION_MAGIC) != magic_number) {
            continue;
        }

        UpdateSettlementButton();
        for (int count = 1; count <= 10; ++count) {
            bool succed = trader.PositionClose(ticket);
            if (succed) {
                break;
            }
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
//+------------------------------------------------------------------+
