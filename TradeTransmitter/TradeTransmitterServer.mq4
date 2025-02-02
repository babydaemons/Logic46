//+------------------------------------------------------------------+
//|                                       TradeTransmitterServer.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  URL = "http://localhost/api/polling/www.fxtrade.co.jp/201916737";    // ポジション情報を受信するのサーバーのURL
input int     RETRY_COUNT_MAX = 5;       // オーダー失敗時のリトライ回数
input int     RETRY_INTERVAL = 50;       // オーダー失敗時のリトライ時間インターバル
input string  SYMBOL_APPEND_SUFFIX = ""; // ポジションコピー時にシンボル名に追加するサフィックス
input double  LOTS_MULTIPLY = 2.0;       // ポジションコピー時のロット数の係数
input int     SLIPPAGE = 30;             // スリッページ(ポイント)

#include "ErrorDescriptionMT4.mqh"
#include "TradeTransmitterServer.mqh"

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
//| コピーするポジションを発注します                                 |
//+------------------------------------------------------------------+
void Entry(string command, string symbol, double lots, int magic_number, string position_id)
{
    lots = RoundLots(symbol, lots);

    color arrow = clrNONE;
    int cmd = 0;
    if (command == "buy") {
        cmd = OP_BUY;
        arrow = clrBlue;
    }
    else {
        cmd = OP_SELL;
        arrow = clrRed;
    }

    symbol += SYMBOL_APPEND_SUFFIX;

    string error_message = "";
    for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
        double price = 0;
        if (command == "buy") {
            price = SymbolInfoDouble(symbol, SYMBOL_ASK);
        } else {
            price = SymbolInfoDouble(symbol, SYMBOL_BID);
        }
        int order_ticket = OrderSend(symbol, cmd, lots, price, SLIPPAGE, 0, 0, position_id, magic_number, 0, arrow);
        if (order_ticket == -1) {
            int error = GetLastError();
            if (error <= 1) {
                return;
            }
            error_message = ErrorDescription(error);
            printf("※エラー: %s", error_message);
            Sleep(RETRY_INTERVAL << times);
            RefreshRates();
        } else {
            return;
        }
    }

    Alert(error_message);
}

//+------------------------------------------------------------------+
//| コピーしたポジションを決済します                                 |
//+------------------------------------------------------------------+
void Exit(string command, string symbol, double lots, int magic_number, string position_id)
{
    color arrow = clrNONE;
    if (command == "buy") {
        arrow = clrBlue;
    } else {
        arrow = clrRed;
    }

    string error_message = "";
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            break;
        }
        if (OrderMagicNumber() != magic_number) {
            continue;
        }
        if (OrderComment() != position_id) {
            continue;
        }
        int ticket = OrderTicket();
        int order_type = OrderType();
        double ordered_lots = OrderLots();
        for (int times = 0; times < RETRY_COUNT_MAX; ++times) {
            double price = 0;
            if (command == "entry") {
                price = SymbolInfoDouble(symbol, SYMBOL_ASK);
            } else {
                price = SymbolInfoDouble(symbol, SYMBOL_BID);
            }
            bool result = (order_type == OP_BUY || order_type == OP_SELL) ?
                            OrderClose(ticket, ordered_lots, price, SLIPPAGE, arrow) :
                            OrderDelete(ticket, arrow);
            if (!result) {
                int error = GetLastError();
                if (error <= 1) {
                    return;
                }
                error_message = ErrorDescription(error);
                printf("※エラー: %s", error_message);
                Sleep(RETRY_INTERVAL << times);
                RefreshRates();
            } else {
                return;
            }
        }

        Alert(error_message);
        return;
    }
}
