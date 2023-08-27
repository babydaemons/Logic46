//+------------------------------------------------------------------+
//|                                          CopyPositionReciver.mq5 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

#include <Trade/Trade.mqh>
#include "ErrorDescriptionMT5.mqh"
#include "CopyPositionReciverEA.mqh"

CTrade Trader;

//+------------------------------------------------------------------+
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(string sender_broker, int magic_number, int entry_type, double entry_price, string symbol, int sender_ticket, double lots, double stoploss, double takeprofit)
{
    lots = RoundLots(symbol, lots);

    double price = 0;
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    if (entry_type == +1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Buy(lots, symbol, price, stoploss, takeprofit, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -1) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.Sell(lots, symbol, price, stoploss, takeprofit, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyLimit(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -2) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellLimit(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == +3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.BuyStop(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
    }
    else if (entry_type == -3) {
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.SellStop(lots, entry_price, symbol, stoploss, takeprofit, ORDER_TIME_GTC, 0, comment);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
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
    double max_lots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    if (lots > max_lots) {
        rounded_lots = max_lots;
    }
    double min_lots = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    if (lots < min_lots) {
        rounded_lots = min_lots;
    }
    double lots_step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
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
    if (entry_type > 0) {
        price = SymbolInfoDouble(symbol, SYMBOL_BID);
    } else {
        price = SymbolInfoDouble(symbol, SYMBOL_ASK);
    }

    string comment = StringFormat("%s-#%d", sender_broker, sender_ticket);
    string error_message = "";
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        double lots = PositionGetDouble(POSITION_VOLUME);
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionClose(ticket, SLIPPAGE);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        Alert(error_message);
        return;
    }
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        double lots = OrderGetDouble(ORDER_VOLUME_CURRENT);
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderDelete(ticket);
            if (!result) {
                error_message = ErrorDescription();
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
    for (int i = 0; i < PositionsTotal(); ++i) {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.PositionModify(ticket, stoploss, takeprofit);
            if (!result) {
                error_message = ErrorDescription();
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL_INIT << times);
            } else {
                return;
            }
        }
        Alert(error_message);
        return;
    }
    for (int i = 0; i < OrdersTotal(); ++i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetString(ORDER_COMMENT) != comment) {
            continue;
        }
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            bool result = Trader.OrderModify(ticket, entry_price, stoploss, takeprofit, ORDER_TIME_GTC, 0);
            if (!result) {
                error_message = ErrorDescription();
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
