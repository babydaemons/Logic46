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
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& buy_position_count, int& sell_ticket, double& sell_profit, int& sell_position_count) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double total_profit = 0;
    buy_ticket = sell_ticket = 0;
    buy_profit = sell_profit = 0;
    buy_position_count = sell_position_count = 0;
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
            break;
        case ORDER_TYPE_SELL:
        case ORDER_TYPE_SELL_LIMIT:
        case ORDER_TYPE_SELL_STOP:
        case ORDER_TYPE_SELL_STOP_LIMIT:
            sell_ticket = (int)ticket;
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
            total_profit += buy_profit;
            ++buy_position_count;
            break;
        case POSITION_TYPE_SELL:
            sell_ticket = (int)ticket;
            sell_profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            total_profit += sell_profit;
            ++sell_position_count;
            break;
        }
    }
    return total_profit;
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
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.BuyStop(LOTS, buy_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        Sleep(i * 100);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderSellEntry(double sell_entry) {
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits());
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.SellStop(LOTS, sell_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        Sleep(i * 100);
    }
    return 0;
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
    double sl = NormalizeDouble(buy_entry - STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(buy_entry + TAKE_PROFIT * Point(), Digits());
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(buy_ticket, buy_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_buy_ticket = buy_ticket;
            prev_buy_entry = buy_entry;
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
    static int prev_sell_ticket = 0;
    static double prev_sell_entry = 0;
    if (prev_sell_ticket == sell_ticket && prev_sell_entry == sell_entry) {
        return true;
    }
    double sl = NormalizeDouble(sell_entry + STOP_LOSS * Point(), Digits());
    double tp = NormalizeDouble(sell_entry - TAKE_PROFIT * Point(), Digits());
    if (STOP_LOSS == 0) {
        sl = 0;
    }
    if (TAKE_PROFIT == 0) {
        tp = 0;
    }
    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(sell_ticket, sell_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_sell_ticket = sell_ticket;
            prev_sell_entry = sell_entry;
            return true;
        }
        Sleep(i * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 買いポジションのトレーリングストップを実行する                   |
//+------------------------------------------------------------------+
bool TrailingStopBuyPosition(int buy_ticket, double& position_stop_loss) {
    if (!PositionSelectByTicket(buy_ticket)) {
        return false;
    }
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double profit_price = current_price - PositionGetDouble(POSITION_PRICE_OPEN);
    double profit_point = profit_price / Point();
    position_stop_loss = PositionGetDouble(POSITION_SL);
    if (profit_point < TRAILING_STOP) {
        return true;
    }
    double sl = NormalizeDouble(current_price - STOP_LOSS * Point(), Digits());
    if (PositionGetDouble(POSITION_SL) < sl) {
        position_stop_loss = sl;
        return trader.PositionModify(buy_ticket, sl, PositionGetDouble(POSITION_TP));
    }
    return true;
}

//+------------------------------------------------------------------+
//| 売りポジションのトレーリングストップを実行する                   |
//+------------------------------------------------------------------+
bool TrailingStopSellPosition(int sell_ticket, double& position_stop_loss) {
    if (!PositionSelectByTicket(sell_ticket)) {
        return false;
    }
    double current_price = PositionGetDouble(POSITION_PRICE_CURRENT);
    double profit_price = PositionGetDouble(POSITION_PRICE_OPEN) - current_price;
    double profit_point = profit_price / Point();
    position_stop_loss = PositionGetDouble(POSITION_SL);
    if (profit_point < TRAILING_STOP) {
        return true;
    }
    double sl = NormalizeDouble(current_price + STOP_LOSS * Point(), Digits());
    if (PositionGetDouble(POSITION_SL) > sl) {
        position_stop_loss = sl;
        return trader.PositionModify(sell_ticket, sl, PositionGetDouble(POSITION_TP));
    }
    return true;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteBuyOrder(int buy_ticket) {
    return trader.OrderDelete(buy_ticket);
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteSellOrder(int sell_ticket) {
    return trader.OrderDelete(sell_ticket);
}

//+------------------------------------------------------------------+
//| エントリー約定時の通知メールを送信する                           |
//+------------------------------------------------------------------+
bool SendMailEntry(int ticket) {
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }

    string type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "ロング" : "ショート";

    string subject = StringFormat("[%s]%s %sエントリーしました", EXPERT_NAME, Symbol(), type);
    string message = "";
    message += StringFormat("エントリー価格 %s\n", DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN), Digits()));
    message += StringFormat("エントリー時刻 %s\n", GetTimestamp((datetime)PositionGetInteger(POSITION_TIME)));
    message += StringFormat("ロット数 %.2f\n", PositionGetDouble(POSITION_VOLUME));
    message += StringFormat("必要証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN), 0));
    message += StringFormat("余剰証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 0));
    message += StringFormat("証拠金維持率 %.0f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));

    return SendMail(subject, message);
}

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション全決済                           |
//+------------------------------------------------------------------+
void ClosePositionAll() {
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

//+------------------------------------------------------------------+
//| 指定マジックナンバーの全待機注文の取り消し                       |
//+------------------------------------------------------------------+
void DeleteOrderAll() {
    int magic_number = GetMagicNumber();
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        ulong ticket = OrderGetTicket(i);
        if (OrderGetInteger(ORDER_MAGIC) != magic_number) {
            continue;
        }

        for (int count = 1; count <= 10; ++count) {
            bool succed = trader.OrderDelete(ticket);
            if (succed) {
                break;
            }
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
