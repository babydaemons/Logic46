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
//| 指定マジックナンバーのポジション損益を返す                       |
//+------------------------------------------------------------------+
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& sell_ticket, double& sell_profit) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double profit = 0;
    for (int i = 0; i < position_count ; ++i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }
        switch (OrderType()) {
        case OP_BUY:
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
            buy_ticket = OrderTicket();
            buy_profit = OrderProfit() + OrderSwap();
            profit += buy_profit;
            break;
        case OP_SELL:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
            sell_ticket = OrderTicket();
            sell_profit = OrderProfit() + OrderSwap();
            profit += sell_profit;
            break;
        }
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 売り気配/買い気配を返す                                          |
//+------------------------------------------------------------------+
void GetPriceInfo(double& ask, double& bid, double& point, int& digit) {
    ask = Ask;
    bid = Bid;
    point = Point;
    digit = Digits;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderBuyEntry(double buy_entry) {
    double sl = NormalizeDouble(buy_entry - STOP_LOSS * Point(), Digits);
    double tp = NormalizeDouble(buy_entry + TAKE_PROFIT * Point(), Digits);
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_BUYSTOP, LOTS, buy_entry, SLIPPAGE, sl, tp, "SaftyBelt_atelierlapin", MAGIC_NUMBER, 0, clrBlue);
        if (ticket != -1) {
            return ticket;
        }
        Sleep(i * 100);
    }
    return -1;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderSellEntry(double sell_entry) {
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits);
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits);
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_SELLSTOP, LOTS, sell_entry, SLIPPAGE, sl, tp, "SaftyBelt_atelierlapin", MAGIC_NUMBER, 0, clrRed);
        if (ticket != -1) {
            return ticket;
        }
        Sleep(i * 100);
    }
    return -1;
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
