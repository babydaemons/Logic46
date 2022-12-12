//+------------------------------------------------------------------+
//|                               Lib/MT5/AtelierLapinSettlement.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
CTrade trader;

#include "../PanelSettlement.mqh"
#include "AtelierLapinCommon.mqh"
#include "ErrorDescription.mqh"

int ScanPositions(int magic_number) {
    int n = PositionsTotal();
    ClearPositions();
    for (int i = 0; i < n; ++i) {
        string symbol = PositionGetSymbol(i);
        if (PositionGetInteger(POSITION_MAGIC) != (long)magic_number) {
            continue;
        }
        int sign = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? +1 : -1;
        double lots = PositionGetDouble(POSITION_VOLUME);
        double profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
        AddPosition(symbol, sign * lots, profit);
    }
    return SortPositions();
}
