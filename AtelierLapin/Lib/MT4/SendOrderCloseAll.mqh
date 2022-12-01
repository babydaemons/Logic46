//+------------------------------------------------------------------+
//|                                            SendOrderCloseAll.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

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
            Sleep(1000 * count);
        }
        Sleep(500);
    }
}
//+------------------------------------------------------------------+
