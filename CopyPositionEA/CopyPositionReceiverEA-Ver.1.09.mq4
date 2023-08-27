//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include "ErrorDescriptionMT4.mqh"
#include "CopyPositionReceiverEA.mqh"

//+------------------------------------------------------------------+
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = RoundLots(symbol, lots);

    double price = 0;
    color arrow = clrNONE;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        arrow = clrBlue;
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
        arrow = clrRed;
    }

    int cmd = 0;
    switch (entry_type) {
    case +1:
        cmd = OP_BUY;
        break;
    case +2:
        cmd = OP_BUYLIMIT;
        price = entry_price;
        break;
    case +3:
        cmd = OP_BUYSTOP;
        price = entry_price;
        break;
    case -1:
        cmd = OP_SELL;
        break;
    case -2:
        cmd = OP_SELLLIMIT;
        price = entry_price;
        break;
    case -3:
        cmd = OP_SELLSTOP;
        price = entry_price;
        break;
    default:
        return;
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
        int order_ticket = OrderSend(symbol, cmd, lots, price, SLIPPAGE, 0, 0, comment, magic_number, 0, arrow);
        if (order_ticket == -1) {
            int error = GetLastError();
            if (error <= 1) {
                return;
            }
            error_message = ErrorDescription(error);
            printf("※エラー: %s", error_message);
            Sleep(RETRY_INTERVAL_INIT << times);
        } else {
            return;
        }
    }

    Alert(error_message);
}

//+------------------------------------------------------------------+
//| ロット数を口座の上限・下限に丸めます                             |
//+------------------------------------------------------------------+
double RoundLots(string symbol, double lots)
{
    double rounded_lots = lots;
    double max_lots = MarketInfo(symbol, MODE_MAXLOT);
    if (lots > max_lots) {
        rounded_lots = max_lots;
    }
    double min_lots = MarketInfo(symbol, MODE_MINLOT);
    if (lots < min_lots) {
        rounded_lots = min_lots;
    }
    double lots_step = MarketInfo(symbol, MODE_LOTSTEP);
    if (lots_step == 0.0) {
        lots_step = 0.01;
    }
    double lots_qty = NormalizeDouble(rounded_lots / lots_step, 0);
    return lots_qty * lots_step;
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double stoploss, double takeprofit)
{
    double price = 0;
    color arrow = clrNONE;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
        arrow = clrBlue;
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        arrow = clrRed;
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        int ticket = OrderTicket();
        int order_type = OrderType();
        double lots = OrderLots();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = (order_type == OP_BUY || order_type == OP_SELL) ?
                            OrderClose(ticket, lots, price, SLIPPAGE, arrow) :
                            OrderDelete(ticket, arrow);
            if (!result) {
                int error = GetLastError();
                if (error <= 1) {
                    return;
                }
                error_message = ErrorDescription(error);
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}

//+------------------------------------------------------------------+
//| コピーしたポジションを修正します                                 |
//+------------------------------------------------------------------+
void Modify(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double stoploss, double takeprofit)
{
    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderComment() != comment) {
            continue;
        }
        int ticket = OrderTicket();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = OrderModify(ticket, entry_price, stoploss, takeprofit, 0);
            if (!result) {
                int error = GetLastError();
                if (error <= 1) {
                    return;
                }
                error_message = ErrorDescription(error);
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}
