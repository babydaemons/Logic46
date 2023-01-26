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
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& buy_position_count, int& sell_ticket, double& sell_profit, int& sell_position_count) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double profit = 0;
    buy_ticket = sell_ticket = 0;
    buy_profit = sell_profit = 0;
    buy_position_count = sell_position_count = 0;
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
            buy_ticket = OrderTicket();
            buy_profit = OrderProfit() + OrderSwap();
            profit += buy_profit;
            ++buy_position_count;
            break;
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
            buy_ticket = OrderTicket();
            break;
        case OP_SELL:
            sell_ticket = OrderTicket();
            sell_profit = OrderProfit() + OrderSwap();
            profit += sell_profit;
            --sell_position_count;
            break;
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
            sell_ticket = OrderTicket();
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
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_BUYSTOP, LOTS, buy_entry, SLIPPAGE, sl, tp, "SaftyBelt_atelierlapin", MAGIC_NUMBER, 0);
        if (ticket != -1) {
            return ticket;
        }
        printf("ERROR: %s", ErrorDescription());
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
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_SELLSTOP, LOTS, sell_entry, SLIPPAGE, sl, tp, "SaftyBelt_atelierlapin", MAGIC_NUMBER, 0);
        if (ticket != -1) {
            return ticket;
        }
        printf("ERROR: %s", ErrorDescription());
        Sleep(i * 100);
    }
    return -1;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifyBuyOrder(int buy_ticket, double buy_entry) {
    static int prev_buy_ticket = 0;
    static double prev_buy_entry = 0;
    if (prev_buy_ticket == buy_ticket && prev_buy_entry == buy_entry) {
        return true;
    }
    double sl = NormalizeDouble(buy_entry - STOP_LOSS * Point(), Digits);
    double tp = NormalizeDouble(buy_entry + TAKE_PROFIT * Point(), Digits);
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        bool suceed = OrderModify(buy_ticket, buy_entry, sl, tp, 0);
        if (suceed) {
            prev_buy_ticket = buy_ticket;
            prev_buy_entry = buy_entry;
            return true;
        }
        printf("ERROR: %s", ErrorDescription());
        Sleep(i * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifySellOrder(int sell_ticket, double sell_entry) {
    static int prev_sell_ticket = 0;
    static double prev_sell_entry = 0;
    if (prev_sell_ticket == sell_ticket && prev_sell_entry == sell_entry) {
        return true;
    }
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits);
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits);
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        bool suceed = OrderModify(sell_ticket, sell_entry, sl, tp, 0);
        if (suceed) {
            prev_sell_ticket = sell_ticket;
            prev_sell_entry = sell_entry;
            return true;
        }
        printf("ERROR: %s", ErrorDescription());
        Sleep(i * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 買いポジションのトレーリングストップを実行する                   |
//+------------------------------------------------------------------+
bool TrailingStopBuyPosition(int buy_ticket, double& position_stop_loss) {
    if (!OrderSelect(buy_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        return false;
    }
    double profit_price = OrderClosePrice() - OrderOpenPrice();
    double profit_point = profit_price / Point();
    if (profit_point < TRAILING_STOP) {
        return true;
    }
    double sl = NormalizeDouble(OrderClosePrice() - TRAILING_STOP * Point, Digits);
    if (OrderStopLoss() < sl) {
        position_stop_loss = sl;
        return OrderModify(buy_ticket, OrderClosePrice(), sl, OrderTakeProfit(), 0);
    }
    position_stop_loss = OrderStopLoss();
    return true;
}

//+------------------------------------------------------------------+
//| 売りポジションのトレーリングストップを実行する                   |
//+------------------------------------------------------------------+
bool TrailingStopSellPosition(int sell_ticket, double& position_stop_loss) {
    if (!OrderSelect(sell_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        return false;
    }
    double profit_price = OrderOpenPrice() - OrderClosePrice();
    double profit_point = profit_price / Point();
    if (profit_point < TRAILING_STOP) {
        return true;
    }
    double sl = NormalizeDouble(OrderClosePrice() + TRAILING_STOP * Point, Digits);
    if (OrderStopLoss() > sl) {
        position_stop_loss = sl;
        return OrderModify(sell_ticket, OrderClosePrice(), sl, OrderTakeProfit(), 0);
    }
    position_stop_loss = OrderStopLoss();
    return true;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteBuyOrder(int buy_ticket) {
    return OrderDelete(buy_ticket, clrRed);
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteSellOrder(int sell_ticket) {
    return OrderDelete(sell_ticket, clrBlue);
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
//+------------------------------------------------------------------+
