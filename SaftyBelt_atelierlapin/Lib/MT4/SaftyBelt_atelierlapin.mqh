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
            ++sell_position_count;
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
int OrderBuyEntry(double buy_entry, double sl, double tp) {
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_BUYSTOP, LOTS, buy_entry, SLIPPAGE, sl, tp, EXPERT_NAME, MAGIC_NUMBER, 0, clrNONE);
        if (ticket != -1) {
            return ticket;
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
    for (int i = 1; i <= 10; ++i) {
        int ticket = OrderSend(Symbol(), OP_SELLSTOP, LOTS, sell_entry, SLIPPAGE, sl, tp, EXPERT_NAME, MAGIC_NUMBER, 0, clrNONE);
        if (ticket != -1) {
            return ticket;
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
        bool suceed = OrderModify(buy_ticket, buy_entry, sl, tp, 0, clrNONE);
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
        bool suceed = OrderModify(sell_ticket, sell_entry, sl, tp, 0, clrNONE);
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
    if (!OrderSelect(buy_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        return false;
    }

    position_stop_loss = OrderStopLoss();
    prev_buy_ticket = buy_ticket;

    double sl = 0;
    if (!DoTrailingStopBuyPosition(OrderOpenPrice(), OrderClosePrice(), Point(), Digits, sl)) {
        return true;
    }

    if (OrderStopLoss() < sl) {
        position_stop_loss = sl;
        return OrderModify(buy_ticket, OrderClosePrice(), sl, OrderTakeProfit(), 0, clrNONE);
    }
    return true;
}

//+------------------------------------------------------------------+
//| 売りポジションのトレーリングストップを実行する                   |
//+------------------------------------------------------------------+
bool TrailingStopSellPosition(int sell_ticket, double& position_stop_loss) {
    if (!OrderSelect(sell_ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        return false;
    }

    position_stop_loss = OrderStopLoss();
    prev_sell_ticket = sell_ticket;

    double sl = 0;
    if (!DoTrailingStopSellPosition(OrderOpenPrice(), OrderClosePrice(), Point(), Digits, sl)) {
        return true;
    }

    if (OrderStopLoss() > sl) {
        position_stop_loss = sl;
        return OrderModify(sell_ticket, OrderClosePrice(), sl, OrderTakeProfit(), 0, clrNONE);
    }
    return true;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteBuyOrder(int buy_ticket) {
    return OrderDelete(buy_ticket, clrNONE);
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を取り消す                                   |
//+------------------------------------------------------------------+
bool DeleteSellOrder(int sell_ticket) {
    return OrderDelete(sell_ticket, clrNONE);
}

//+------------------------------------------------------------------+
//| エントリー約定時の通知メールを送信する                           |
//+------------------------------------------------------------------+
bool SendMailEntry(int ticket) {
    if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES)) {
        return false;
    }

    string type;
    switch (OrderType()) {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
        type = "ロング";
        break;
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
        type = "ショート";
        break;
    }

    string subject = StringFormat("[%s]%s %sエントリーしました", EXPERT_NAME, Symbol(), type);
    string message = "";
    message += StringFormat("エントリー価格 %s\n", DoubleToString(OrderOpenPrice(), Digits));
    message += StringFormat("エントリー時刻 %s\n", GetTimestamp(OrderOpenTime()));
    message += StringFormat("ロット数 %.2f\n", OrderLots());
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
    if (!OrderSelect(ticket, SELECT_BY_TICKET, MODE_HISTORY)) {
        return false;
    }

    string type;
    switch (OrderType()) {
    case OP_BUY:
    case OP_BUYLIMIT:
    case OP_BUYSTOP:
        type = "ロング";
        break;
    case OP_SELL:
    case OP_SELLLIMIT:
    case OP_SELLSTOP:
        type = "ショート";
        break;
    }

    string subject = StringFormat("[%s]%s %s決済しました", EXPERT_NAME, Symbol(), type);
    string message = "";
    message += StringFormat("決済価格 %s\n", DoubleToString(OrderClosePrice(), Digits));
    message += StringFormat("決済時刻 %s\n", GetTimestamp(OrderCloseTime()));
    message += StringFormat("ロット数 %.2f\n", OrderLots());
    message += StringFormat("損益 %s\n", TextObject::FormatComma(OrderProfit(), 0));
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
    for (int i = OrdersTotal() - 1; i >= 0 ; --i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        string symbol = OrderSymbol();
        if (Symbol() != symbol) {
            continue;
        }
        UpdateSettlementButton();

        int ticket = OrderTicket();
        double lots = OrderLots();
        int type = OrderType();
        double price = MarketInfo(symbol, type == OP_BUY ? MODE_BID : MODE_ASK);
        for (int count = 1; count <= 10; ++count) {
            bool succed = OrderClose(ticket, lots, 10, clrNONE);
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
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        string symbol = OrderSymbol();
        if (Symbol() != symbol) {
            continue;
        }
        if (OrderType() == OP_BUY || OrderType() == OP_SELL) {
            continue;
        }

        // https://www.mql5.com/en/forum/119596
        //   1. OrderDelete for pending orders
        //   2. OrderClose for open orders
        int ticket = OrderTicket();
        for (int count = 1; count <= 10; ++count) {
            bool succed = OrderDelete(ticket, clrNONE);
            if (succed) {
                break;
            }
            Alert(StringFormat("ERROR: #%d: %s", ticket, ErrorDescription()));
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
