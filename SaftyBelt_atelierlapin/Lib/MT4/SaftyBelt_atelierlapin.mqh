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
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& buy_position_count, int& sell_ticket, double& sell_profit, int& sell_position_count, double& profit_price, double& entry_price) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double profit = 0;
    buy_ticket = sell_ticket = 0;
    buy_profit = sell_profit = 0;
    buy_position_count = sell_position_count = 0;
    profit_price = entry_price = 0;
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
        double current_price = OrderClosePrice();
        entry_price = OrderOpenPrice();
        switch (OrderType()) {
        case OP_BUY:
            buy_ticket = OrderTicket();
            buy_profit = OrderProfit() + OrderSwap();
            profit += buy_profit;
            profit_price = +(current_price - entry_price);
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
            profit_price = +(current_price - entry_price);
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
//| 抑制するエラーかチェックする                                     |
//+------------------------------------------------------------------+
bool IsSuppressError(int error) {
    switch (error) {
    case ERR_NO_ERROR: // 0: "エラーはありません。"
    case ERR_NO_RESULT: // 1: "エラーはありません。取引条件(SL/TP)は変更されていません。"
    case ERR_MARKET_CLOSED: // 132: "休場中の可能性があり発注できません。監視・決済中断時刻の設定を確認してください。"
    case ERR_TRADE_DISABLED: // 133: "開設した口座では取引できない通貨ペアが選択されています。"
    case ERR_NOT_ENOUGH_MONEY: // 134: "証拠金が不足しています。"
    case ERR_TRADE_MODIFY_DENIED: // 145: "休場中の可能性があり待機注文修正できません。監視・決済中断時刻の設定を確認してください。"
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderBuyEntry(double buy_entry, double sl, double tp) {
    for (int count = 1; count <= ORDER_RETRY_COUNT; ++count) {
        int ticket = OrderSend(Symbol(), OP_BUYSTOP, LOTS, buy_entry, SLIPPAGE, sl, tp, EXPERT_NAME, MAGIC_NUMBER, 0, clrNONE);
        if (ticket != -1) {
            return ticket;
        }
        int error = GetLastError();
        if (IsSuppressError(error)) {
            return 0;
        }
        switch (error) {
        case ERR_TRADE_NOT_ALLOWED: // 4109: "自動取引が許可されていません。"
            printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
            return 0;
        case ERR_LONGS_NOT_ALLOWED: // 4110: "\"[Expert] - [全般] - [コモン] -[ポジション]\"でロングが許可されていません。"
            enable_entry_type &= ~ENTRY_TYPE_LONG_ONLY;
            return 0;
        }
        printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
        Sleep(count * 100);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderSellEntry(double sell_entry, double sl, double tp) {
    for (int count = 1; count <= ORDER_RETRY_COUNT; ++count) {
        int ticket = OrderSend(Symbol(), OP_SELLSTOP, LOTS, sell_entry, SLIPPAGE, sl, tp, EXPERT_NAME, MAGIC_NUMBER, 0, clrNONE);
        if (ticket != -1) {
            return ticket;
        }
        int error = GetLastError();
        if (IsSuppressError(error)) {
            return 0;
        }
        switch (error) {
        case ERR_TRADE_NOT_ALLOWED: // 4109: "自動取引が許可されていません。"
            printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
            return 0;
        case ERR_SHORTS_NOT_ALLOWED: // 4111: "\"[Expert] - [全般] - [コモン] -[ポジション]\"でショートが許可されていません。"
            enable_entry_type &= ~ENTRY_TYPE_SHORT_ONLY;
            return 0;
        }
        printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
        Sleep(count * 100);
    }
    return 0;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifyBuyOrder(int buy_ticket, double buy_entry, double sl, double tp) {
    if (prev_buy_ticket == buy_ticket && prev_buy_entry == buy_entry && prev_buy_sl == sl && prev_buy_tp == tp) {
        return true;
    }

    for (int count = 1; count <= ORDER_RETRY_COUNT; ++count) {
        bool suceed = OrderModify(buy_ticket, buy_entry, sl, tp, 0, clrNONE);
        int error = GetLastError();
        if (suceed || IsSuppressError(error)) {
            prev_buy_ticket = buy_ticket;
            prev_buy_entry = buy_entry;
            prev_buy_sl = sl;
            prev_buy_tp = tp;
            return true;
        }
        switch (error) {
        case ERR_TRADE_NOT_ALLOWED: // 4109: "自動取引が許可されていません。"
            printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
            return true;
        case ERR_LONGS_NOT_ALLOWED: // 4110: "\"[Expert] - [全般] - [コモン] -[ポジション]\"でロングが許可されていません。"
            enable_entry_type &= ~ENTRY_TYPE_LONG_ONLY;
            return true;
        }
        printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
        Sleep(count * 100);
    }
    return false;
}

//+------------------------------------------------------------------+
//| 売りストップ待機注文を修正する                                   |
//+------------------------------------------------------------------+
bool ModifySellOrder(int sell_ticket, double sell_entry, double sl, double tp) {
    if (prev_sell_ticket == sell_ticket && prev_sell_entry == sell_entry && prev_sell_sl == sl && prev_sell_tp == tp) {
        return true;
    }

    for (int count = 1; count <= ORDER_RETRY_COUNT; ++count) {
        bool suceed = OrderModify(sell_ticket, sell_entry, sl, tp, 0, clrNONE);
        int error = GetLastError();
        if (suceed || IsSuppressError(error)) {
            prev_sell_ticket = sell_ticket;
            prev_sell_entry = sell_entry;
            prev_sell_sl = sl;
            prev_sell_tp = tp;
            return true;
        }
        switch (error) {
        case ERR_TRADE_NOT_ALLOWED: // 4109: "自動取引が許可されていません。"
            printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
            return true;
        case ERR_SHORTS_NOT_ALLOWED: // 4111: "\"[Expert] - [全般] - [コモン] -[ポジション]\"でショートが許可されていません。"
            enable_entry_type &= ~ENTRY_TYPE_SHORT_ONLY;
            return true;
        }
        printf("EA: %s: %s", EXPERT_NAME, ErrorDescription(error));
        Sleep(count * 100);
    }
    return false;
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
    message += StringFormat("口座残高 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_BALANCE), currency_digits));
    message += StringFormat("必要証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN), currency_digits));
    message += StringFormat("余剰証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN_FREE), currency_digits));
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
    message += StringFormat("口座残高 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_BALANCE), currency_digits));
    message += StringFormat("必要証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN), currency_digits));
    message += StringFormat("余剰証拠金 %s\n", TextObject::FormatComma(AccountInfoDouble(ACCOUNT_MARGIN_FREE), currency_digits));
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

        UpdateSettlementButton();

        string symbol = OrderSymbol();
        int ticket = OrderTicket();
        double lots = OrderLots();
        int type = OrderType();
        double price = MarketInfo(symbol, type == OP_BUY ? MODE_BID : MODE_ASK);
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        for (int count = 1; count <= ORDER_RETRY_COUNT; ++count) {
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
            int error = GetLastError();
            if (succed || IsSuppressError(error)) {
                break;
            }
            printf("ERROR: #%d: %s", ticket, ErrorDescription());
            Sleep(100 * count);
        }

        Sleep(100);
    }
}
