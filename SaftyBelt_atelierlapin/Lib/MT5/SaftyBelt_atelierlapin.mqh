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
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& sell_ticket, double& sell_profit) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double profit = 0;
    for (int i = 0; i < position_count ; ++i) {
        ulong ticket = OrderGetTicket(i);
        if (!OrderSelect(ticket)) {
            continue;
        }
        if (OrderGetInteger(ORDER_MAGIC) != magic_number) {
            continue;
        }
        if (OrderGetString(ORDER_SYMBOL) != Symbol()) {
            continue;
        }
        switch ((int)OrderGetInteger(ORDER_TYPE)) {
        case ORDER_TYPE_BUY:
        case ORDER_TYPE_BUY_LIMIT:
        case ORDER_TYPE_BUY_STOP:
        case ORDER_TYPE_BUY_STOP_LIMIT:
            buy_ticket = (int)ticket;
            buy_profit = 0;
            break;
        case ORDER_TYPE_SELL:
        case ORDER_TYPE_SELL_LIMIT:
        case ORDER_TYPE_SELL_STOP:
        case ORDER_TYPE_SELL_STOP_LIMIT:
            sell_ticket = (int)ticket;
            sell_profit = 0;
            break;
        }
    }

    position_count = PositionsTotal();
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
        switch ((int)PositionGetInteger(POSITION_TYPE)) {
        case POSITION_TYPE_BUY:
            buy_ticket = (int)ticket;
            buy_profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            break;
        case POSITION_TYPE_SELL:
            sell_ticket = (int)ticket;
            sell_profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            break;
        }
    }
    return profit;
}

//+------------------------------------------------------------------+
//| 売り気配/買い気配を返す                                          |
//+------------------------------------------------------------------+
void GetPriceInfo(double& ask, double& bid, double& point, int& digit) {
    ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    point = Point();
    digit = Digits();
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderBuyEntry(double buy_entry) {
    double sl = NormalizeDouble(buy_entry - STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(buy_entry + TAKE_PROFIT * Point(), Digits());
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.BuyStop(LOTS, buy_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        Sleep(i * 100);
    }
    return -1;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderSellEntry(double sell_entry) {
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits());
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.SellStop(LOTS, sell_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        Sleep(i * 100);
    }
    return -1;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifyBuyOrder(int buy_ticket, double buy_entry) {
    double sl = NormalizeDouble(buy_entry - STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(buy_entry + TAKE_PROFIT * Point(), Digits());
    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(buy_ticket, buy_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            return true;
        }
        Sleep(i * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifySellOrder(int sell_ticket, double sell_entry) {
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits());
    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(sell_ticket, sell_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            return true;
        }
        Sleep(i * 100);
    }
    return false;
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
