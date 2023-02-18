//+------------------------------------------------------------------+
//|                               Lib/MT4/AtelierLapinSettlement.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

#include "./Trade.mqh"
#include "../SaftyBeltPanel.mqh"
#include "ErrorDescription.mqh"

CTrade trader;
double last_total_lots;

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション損益を返す                       |
//+------------------------------------------------------------------+
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& buy_position_count, int& sell_ticket, double& sell_profit, int& sell_position_count) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double total_profit = last_total_lots = 0;
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
        last_total_lots += OrderGetDouble(ORDER_VOLUME_CURRENT);
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
        last_total_lots += PositionGetDouble(POSITION_VOLUME);
    }
    return total_profit;
}

//+------------------------------------------------------------------+
//| 売り気配/買い気配を返す                                          |
//+------------------------------------------------------------------+
void GetPriceInfo(double& ask, double& bid, double& point, int& digits) {
    ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    point = Point();
    digits = Digits();
}

//+------------------------------------------------------------------+
//| 抑制するエラーかチェックする                                     |
//+------------------------------------------------------------------+
bool IsSuppressError() {
    switch (trader.ResultRetcode()) {
    case TRADE_RETCODE_TRADE_DISABLED:
        return true; // "trade disabled";
    case TRADE_RETCODE_MARKET_CLOSED:
        return true; // "market closed";
    case TRADE_RETCODE_NO_MONEY:
        return true; // "not enough money";
    }
    return false;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderBuyEntry(double buy_entry, double sl, double tp) {
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.BuyStop(LOTS, buy_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        if (IsSuppressError()) {
            return 0;
        }
        Alert(StringFormat("ERROR: %s", ErrorDescription()));
        Sleep(i * 100);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderSellEntry(double sell_entry, double sl, double tp) {
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    for (int i = 1; i <= 10; ++i) {
        if (trader.SellStop(LOTS, sell_entry, Symbol(), sl, tp, ORDER_TIME_GTC, 0, "SaftyBelt_atelierlapin")) {
            return (int)trader.ResultOrder();
        }
        if (IsSuppressError()) {
            return 0;
        }
        Alert(StringFormat("ERROR: %s", ErrorDescription()));
        Sleep(i * 100);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifyBuyOrder(int buy_ticket, double buy_entry, double sl, double tp) {
    if (prev_buy_ticket == buy_ticket && prev_buy_entry == buy_entry) {
        return true;
    }

    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(buy_ticket, buy_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_buy_ticket = buy_ticket;
            prev_buy_entry = buy_entry;
            return true;
        }
        Alert(StringFormat("ERROR: %s", ErrorDescription()));
        Sleep(i * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifySellOrder(int sell_ticket, double sell_entry, double sl, double tp) {
    if (prev_sell_ticket == sell_ticket && prev_sell_entry == sell_entry) {
        return true;
    }

    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(sell_ticket, sell_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_sell_ticket = sell_ticket;
            prev_sell_entry = sell_entry;
            return true;
        }
        Alert(StringFormat("ERROR: %s", ErrorDescription()));
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

    position_stop_loss = PositionGetDouble(POSITION_SL);
    prev_buy_ticket = buy_ticket;

    double sl = 0;
    if (!DoTrailingStopBuyPosition(PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_PRICE_CURRENT), Point(), Digits(), sl)) {
        return true;
    }

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

    position_stop_loss = PositionGetDouble(POSITION_SL);
    prev_sell_ticket = sell_ticket;

    double sl = 0;
    if (!DoTrailingStopSellPosition(PositionGetDouble(POSITION_PRICE_OPEN), PositionGetDouble(POSITION_PRICE_CURRENT), Point(), Digits(), sl)) {
        return true;
    }

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
    message += StringFormat("口座残高 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_BALANCE), 0));
    message += StringFormat("必要証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN), 0));
    message += StringFormat("余剰証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 0));
    message += StringFormat("証拠金維持率 %.0f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));

    return MAIL_ENABLED ? SendMail(subject, message) : true;
}

//+------------------------------------------------------------------+
//| 決済約定時の通知メールを送信する                                 |
//+------------------------------------------------------------------+
bool SendMailExit(int ticket) {
    string type = last_position_type > 0 ? "ロング" : "ショート";
    double price = SymbolInfoDouble(Symbol(), last_position_profit > 0 ? SYMBOL_BID : SYMBOL_ASK);

    string subject = StringFormat("[%s]%s %s決済しました", EXPERT_NAME, Symbol(), type);
    string message = "";
    message += StringFormat("決済価格 %s\n", DoubleToString(price, Digits()));
    message += StringFormat("決済時刻 %s\n", GetTimestamp(last_position_checked));
    message += StringFormat("ロット数 %.2f\n", last_total_lots);
    message += StringFormat("損益 %s\n", TextObject::FormatComma(last_position_profit, 0));
    message += StringFormat("口座残高 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_BALANCE), 0));
    message += StringFormat("必要証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN), 0));
    message += StringFormat("余剰証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 0));
    message += StringFormat("証拠金維持率 %.0f%%\n", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));

    return MAIL_ENABLED ? SendMail(subject, message) : true;
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

            Alert(StringFormat("ERROR: %s", ErrorDescription()));
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
