//+------------------------------------------------------------------+
//|                               Lib/MT4/AtelierLapinSettlement.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "../PanelSettlement.mqh"
#include "AtelierLapinCommon.mqh"
#include "ErrorDescription.mqh"

int ScanPositions(int magic_number) {
    int n = OrdersTotal();
    ClearPositions();
    for (int i = 0; i < n; ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        string symbol = OrderSymbol();
        int sign = OrderType() == OP_BUY ? +1 : -1;
        double lots = OrderLots();
        double profit = OrderProfit() + OrderSwap();
        AddPosition(symbol, sign * lots, profit);
    }
    return SortPositions();
}
