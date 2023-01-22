//+------------------------------------------------------------------+
//|                               Lib/MT4/AtelierLapinSettlement.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
#include "../SaftyBeltPanel.mqh"
#include "ErrorDescription.mqh"

CTrade trader;

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション損益を返す                       |
//+------------------------------------------------------------------+
double GetPositionProfit() {
    int magic_number = GetMagicNumber();
    int position_count = PositionsTotal();
    double profit = 0;
    for (int i = 0; i < position_count ; ++i) {
        ulong ticket = PositionGetTicket(i);
        if (!PositionSelectByTicket(ticket)) {
            continue;
        }
        if (PositionGetInteger(POSITION_MAGIC) != magic_number) {
            continue;
        }
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) {
            continue;
        }
        profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 売り気配を返す                                                   |
//+------------------------------------------------------------------+
string GetAskPrice() {
    return DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_ASK), Digits());
}

//+------------------------------------------------------------------+
//| 買い気配を返す                                                   |
//+------------------------------------------------------------------+
string GetBidPrice() {
    return DoubleToString(SymbolInfoDouble(Symbol(), SYMBOL_BID), Digits());
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
