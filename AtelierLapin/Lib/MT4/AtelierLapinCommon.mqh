//+------------------------------------------------------------------+
//|                                   Lib/MT4/AtelierLapinCommon.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

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
    const int magic_number = GetMagicNumber();
    const int n = OrdersTotal();
    int position_count = 0;
    int tickets[];
    for (int i = 0; i < n; ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        ArrayResize(tickets, position_count + 1);
        tickets[position_count] = OrderTicket();
        ++position_count;
    }

    for (int i = 0; i < position_count; ++i) {
        if (OrderSelect(tickets[i], SELECT_BY_TICKET, MODE_TRADES) == false) continue;

        UpdateSettlementButton();

        double price = 0;
        RefreshRates();
        if (OrderType() == OP_BUY) {
            price = Bid;
        } else if(OrderType() == OP_SELL) {
            price = Ask;
        }

        for (int count = 1; count <= 10; ++count) {
            if (OrderClose(tickets[i], OrderLots(), price, 10, clrNONE) == false) {
                Sleep(count * 100);
            } else {
                break;
            }
        }
    }
}
//+------------------------------------------------------------------+
