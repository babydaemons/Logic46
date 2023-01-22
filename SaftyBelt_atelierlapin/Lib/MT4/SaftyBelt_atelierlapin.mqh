//+------------------------------------------------------------------+
//|                               Lib/MT4/AtelierLapinSettlement.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

#include "../SaftyBeltPanel.mqh"
#include "ErrorDescription.mqh"

//+------------------------------------------------------------------+
//| 指定マジックナンバーの全損益の取得                               |
//+------------------------------------------------------------------+
double GetMagicNumberProfit() {
    int magic_number = GetMagicNumber();
    double profit = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        profit += OrderProfit() + OrderSwap();
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション全決済                           |
//+------------------------------------------------------------------+
void SendOrderCloseAll() {
    int magic_number = GetMagicNumber();
    for (int i = OrdersTotal() - 1; i >= 0 ; --i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }

        UpdateSettlementButton();

        string symbol = OrderSymbol();
        int ticket = OrderTicket();
        double lots = OrderLots();
        int type = OrderType();
        double price = MarketInfo(symbol, type == OP_BUY ? MODE_BID : MODE_ASK);
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        for (int count = 1; count <= 10; ++count) {
            bool succed = OrderClose(ticket, lots, 10, arrow);
            if (succed) {
                break;
            }
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
