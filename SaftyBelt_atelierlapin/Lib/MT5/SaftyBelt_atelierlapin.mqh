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

//+------------------------------------------------------------------+
//| 指定マジックナンバーのポジション損益を返す                       |
//+------------------------------------------------------------------+
double GetPositionProfit(int& buy_ticket, double& buy_profit, int& buy_position_count, int& sell_ticket, double& sell_profit, int& sell_position_count, double& profit_price, double& entry_price) {
    int magic_number = GetMagicNumber();
    int position_count = OrdersTotal();
    double total_profit = 0;
    buy_ticket = sell_ticket = 0;
    buy_profit = sell_profit = 0;
    buy_position_count = sell_position_count = 0;
    profit_price = entry_price = 0;
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
    double current_price = 0;
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

        entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
        current_price = PositionGetDouble(POSITION_PRICE_CURRENT);

        switch ((int)PositionGetInteger(POSITION_TYPE)) {
        case POSITION_TYPE_BUY:
            buy_ticket = (int)ticket;
            buy_profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            total_profit += buy_profit;
            profit_price = +(current_price - entry_price);
            ++buy_position_count;
            break;
        case POSITION_TYPE_SELL:
            sell_ticket = (int)ticket;
            sell_profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            total_profit += sell_profit;
            profit_price = -(current_price - entry_price);
            ++sell_position_count;
            break;
        }
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
    string error_string = "";
    switch (trader.ResultRetcode()) {
    case TRADE_RETCODE_DONE: // "リクエスト完了。"
    case TRADE_RETCODE_TRADE_DISABLED: // "取引が無効化されています。"
    case TRADE_RETCODE_MARKET_CLOSED: // "市場が閉鎖中。"
    case TRADE_RETCODE_NO_MONEY: // "リクエストを完了するのに資金が不充分。"
        return true;
    case TRADE_RETCODE_REQUOTE:
        error_string = "リクオート。";
        break;
    case TRADE_RETCODE_REJECT:
        error_string = "リクエストの拒否。";
        break;
    case TRADE_RETCODE_CANCEL:
        error_string = "トレーダーによるリクエストのキャンセル。";
        break;
    case TRADE_RETCODE_PLACED:
        error_string = "注文が出されました。";
        break;
    case TRADE_RETCODE_DONE_PARTIAL:
        error_string = "リクエストが一部のみ完了。";
        break;
    case TRADE_RETCODE_ERROR:
        error_string = "リクエスト処理エラー。";
        break;
    case TRADE_RETCODE_TIMEOUT:
        error_string = "リクエストが時間切れでキャンセル。";
        break;
    case TRADE_RETCODE_INVALID:
        error_string = "無効なリクエスト。";
        break;
    case TRADE_RETCODE_INVALID_VOLUME:
        error_string = "リクエスト内の無効なボリューム。";
        break;
    case TRADE_RETCODE_INVALID_PRICE:
        error_string = "リクエスト内の無効な価格。";
        break;
    case TRADE_RETCODE_INVALID_STOPS:
        error_string = "リクエスト内の無効なストップ。";
        break;
    case TRADE_RETCODE_PRICE_CHANGED:
        error_string = "価格変更。";
        break;
    case TRADE_RETCODE_PRICE_OFF:
        error_string = "リクエスト処理に必要な相場が不在。";
        break;
    case TRADE_RETCODE_INVALID_EXPIRATION:
        error_string = "リクエスト内の無効な注文有効期限。";
        break;
    case TRADE_RETCODE_ORDER_CHANGED:
        error_string = "注文状態の変化。";
        break;
    case TRADE_RETCODE_TOO_MANY_REQUESTS:
        error_string = "頻繁過ぎるリクエスト。";
        break;
    case TRADE_RETCODE_NO_CHANGES:
        error_string = "リクエストに変更なし。";
        break;
    case TRADE_RETCODE_SERVER_DISABLES_AT:
        error_string = "サーバが自動取引を無効化。";
        break;
    case TRADE_RETCODE_CLIENT_DISABLES_AT:
        error_string = "クライアント端末が自動取引を無効化。";
        break;
    case TRADE_RETCODE_LOCKED:
        error_string = "リクエストが処理のためにロック中。";
        break;
    case TRADE_RETCODE_FROZEN:
        error_string = "注文やポジションが凍結。";
        break;
    case TRADE_RETCODE_INVALID_FILL:
        error_string = "無効な注文充填タイプ。";
        break;
    case TRADE_RETCODE_CONNECTION:
        error_string = "取引サーバに未接続。";
        break;
    case TRADE_RETCODE_ONLY_REAL:
        error_string = "操作は、ライブ口座のみで許可。";
        break;
    case TRADE_RETCODE_LIMIT_ORDERS:
        error_string = "未決注文の数が上限に達しました。";
        break;
    case TRADE_RETCODE_LIMIT_VOLUME:
        error_string = "シンボルの注文やポジションのボリュームが限界に達しました。";
        break;
    case TRADE_RETCODE_INVALID_ORDER:
        error_string = "不正または禁止された注文の種類。";
        break;
    case TRADE_RETCODE_POSITION_CLOSED:
        error_string = "指定されたPOSITION_IDENTIFIER を持つポジションがすでに閉鎖。";
        break;
    case TRADE_RETCODE_INVALID_CLOSE_VOLUME:
        error_string = "決済ボリュームが現在のポジションのボリュームを超過。";
        break;
    case TRADE_RETCODE_CLOSE_ORDER_EXIST:
        error_string = "指定されたポジションの決済注文が既存：反対のポジションを決済しようとしているときにそのポジションの決済注文が既に存在している場合";
        break;
    case TRADE_RETCODE_LIMIT_POSITIONS:
        error_string = "アカウントに同時に存在するポジションの数は、サーバー設定によって制限されます。 限度に達すると、サーバーは出された注文を処理するときにcase TRADE_RETCODE_LIMIT_POSITIONSエラーを返します。 これは、ポジション会計タイプによって異なる動作につながります。";
        break;
    case TRADE_RETCODE_REJECT_CANCEL:
        error_string = "未決注文アクティベーションリクエストは却下され、注文はキャンセルされます。";
        break;
    case TRADE_RETCODE_LONG_ONLY:
        error_string = "銘柄に\"Only long positions are allowed（買いポジションのみ）\" (POSITION_TYPE_BUY)のルールが設定されているため、リクエストは却下されます。";
        break;
    case TRADE_RETCODE_SHORT_ONLY:
        error_string = "銘柄に\"Only short positions are allowed（売りポジションのみ）\" (POSITION_TYPE_SELL)のルールが設定されているため、リクエストは却下されます。";
        break;
    case TRADE_RETCODE_CLOSE_ONLY:
        error_string = "銘柄に\"Only position closing is allowed（ポジション決済のみ）\"のルールが設定されているため、リクエストは却下されます。";
        break;
    case TRADE_RETCODE_FIFO_CLOSE:
        error_string = "取引口座に\"Position closing is allowed only by FIFO rule（FIFOによるポジション決済のみ）\"(ACCOUNT_FIFO_CLOSE=true)のフラグが設定されているため、リクエストは却下されます";
        break;
    case TRADE_RETCODE_HEDGE_PROHIBITED:
        error_string = "口座で「単一の銘柄の反対のポジションは無効にする」ルールが設定されているため、リクエストが拒否されます。たとえば、銘柄に買いポジションがある場合、売りポジションを開いたり、売り指値注文を出すことはできません。このルールは口座がヘッジ勘定の場合 (ACCOUNT_MARGIN_MODE=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)のみ適用されます。";
        break;
    }
    Alert(error_string);
    return true;
}

//+------------------------------------------------------------------+
//| 買いストップ待機注文を出す                                       |
//+------------------------------------------------------------------+
int OrderBuyEntry(double buy_entry, double sl, double tp) {
    trader.LogLevel(LOG_LEVEL_NO);
    trader.SetExpertMagicNumber(MAGIC_NUMBER);
    trader.SetDeviationInPoints(SLIPPAGE);
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
    trader.SetDeviationInPoints(SLIPPAGE);
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
    if (prev_buy_ticket == buy_ticket && prev_buy_entry == buy_entry && prev_buy_sl == sl && prev_buy_tp == tp) {
        return true;
    }

    if (!OrderSelect(buy_ticket)) {
        return false;
    }

    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(buy_ticket, buy_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_buy_ticket = buy_ticket;
            prev_buy_entry = buy_entry;
            prev_buy_sl = sl;
            prev_buy_tp = tp;
            return true;
        }
        if (IsSuppressError()) {
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
    if (prev_sell_ticket == sell_ticket && prev_sell_entry == sell_entry && prev_sell_sl == sl && prev_sell_tp == tp) {
        return true;
    }

    if (!OrderSelect(sell_ticket)) {
        return false;
    }

    for (int i = 1; i <= 10; ++i) {
        bool suceed = trader.OrderModify(sell_ticket, sell_entry, sl, tp, ORDER_TIME_GTC, 0);
        if (suceed) {
            prev_sell_ticket = sell_ticket;
            prev_sell_entry = sell_entry;
            prev_sell_sl = sl;
            prev_sell_tp = tp;
            return true;
        }
        if (IsSuppressError()) {
            return true;
        }
        Alert(StringFormat("ERROR: %s", ErrorDescription()));
        Sleep(i * 100);
    }
    return false;
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
    string type = last_position_type > 0 ? "ロング" : "ショート";
    double price = SymbolInfoDouble(Symbol(), last_position_profit > 0 ? SYMBOL_BID : SYMBOL_ASK);

    string subject = StringFormat("[%s]%s %s決済しました", EXPERT_NAME, Symbol(), type);
    string message = "";
    message += StringFormat("決済価格 %s\n", DoubleToString(price, Digits()));
    message += StringFormat("決済時刻 %s\n", GetTimestamp(last_position_checked));
    message += StringFormat("ロット数 %.2f\n", LOTS);
    message += StringFormat("損益(概算) %s\n", TextObject::FormatComma(last_position_profit, currency_digits));
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
