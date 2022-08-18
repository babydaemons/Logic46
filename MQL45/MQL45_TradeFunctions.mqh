//+------------------------------------------------------------------+
//|                                         MQL45_TradeFunctions.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade MQL45::_MQL45_trader;
ulong MQL45::last_selected_position_ticket;
ulong MQL45::last_selected_order_ticket;
ulong MQL45::last_selected_history_ticket;
int MQL45::positions_total;
int MQL45::orders_total;
string MQL45::order_close_comment;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::OrderCloseComment(string comment)
{
    order_close_comment = comment;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::OrderClose(int ticket, double lots, double price, int slippage, color arrow_color)
{
    bool result = _MQL45_trader.PositionClose(ticket, slippage, order_close_comment);
    return result;
}

/**
 * https://memoja.net/p/9jjrrp5/
 * 指定したシンボルで選択可能なフィル・ポリシーをひとつ返します。
 * 優先度は IOC、FOK、RETURN の順です。
 */
ENUM_ORDER_TYPE_FILLING MQL45::SelectFillPolicy(string symbol)
{
    long modes = SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);
    if ((modes & SYMBOL_FILLING_IOC) != 0) return ORDER_FILLING_IOC;
    if ((modes & SYMBOL_FILLING_FOK) != 0) return ORDER_FILLING_FOK;
    return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::OrderCloseBy(int ticket, int opposite, color arrow_color)
{
    MqlTradeRequest request1 = {};
    MqlTradeRequest request2 = {};
    MqlTradeResult result1 = {};
    MqlTradeResult result2 = {};

    request1.order = ticket;
    request1.action = TRADE_ACTION_CLOSE_BY;
    request2.order = ticket;
    request2.action = TRADE_ACTION_CLOSE_BY;

    if(!::OrderSend(request1, result2)) {
        return(false);
    }
    if(!::OrderSend(request2, result2)) {
        return(false);
    }

    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::OrderDelete(int ticket, color arrow_color)
{
    MqlTradeRequest req = {};
    MqlTradeResult rsp = {};

    req.order = ticket;
    req.action = TRADE_ACTION_REMOVE;

    return(::OrderSend(req, rsp));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::OrderModify(int ticket, double price, double sl, double tp, int expiration, color arrow_color = clrRed)
{
    MqlTradeRequest req = {};
    MqlTradeResult rsp = {};

    bool result = true;
    if (ticket == last_selected_position_ticket) {
        result = _MQL45_trader.PositionModify(ticket, sl, tp);
    }
    else {
        result = _MQL45_trader.OrderModify(ticket, price, sl, tp, ORDER_TIME_GTC, 0);
    }

    return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrderSend(string symbol, int cmd, double volume, double price, int slippage, double sl, double tp, string comment = NULL, int magic = 0, datetime expiration=0, color arrow=clrNONE)
{
    _MQL45_trader.LogLevel(LOG_LEVEL_NO);
    _MQL45_trader.SetExpertMagicNumber(magic);

    bool result = false;
    switch (cmd) {
    case OP_BUY:
        result = _MQL45_trader.Buy(volume, symbol, 0.0, sl, tp, comment);
        break;
    case OP_SELL:
        result = _MQL45_trader.Sell(volume, symbol, 0.0, sl, tp, comment);
        break;
    case OP_BUYLIMIT:
        result = _MQL45_trader.BuyLimit(volume, price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
        break;
    case OP_SELLLIMIT:
        result = _MQL45_trader.SellLimit(volume, price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
        break;
    case OP_BUYSTOP:
        result = _MQL45_trader.BuyStop(volume, price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
        break;
    case OP_SELLSTOP:
        result = _MQL45_trader.SellStop(volume, price, symbol, sl, tp, ORDER_TIME_SPECIFIED, expiration, comment);
        break;
    }

    if (!result) {
        MqlTradeRequest request = {};
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        _MQL45_trader.Request(request);
        double tp_points = (request.tp != 0) ? (request.tp - request.price) / point : 0;;
        double sl_points = (request.sl != 0) ? (request.sl - request.price) / point : 0;;
        Alert(StringFormat("[%s ERROR %d]%s: VOLUME:%.2f / PRICE:%s / TP:(%s)%.0f / SL:(%s)%.0f / STOP_LEVEL:%d",
            EnumToString(request.type), _MQL45_trader.ResultRetcode(), _MQL45_trader.ResultComment(), volume,
            DoubleToString(request.price, digits), DoubleToString(request.tp, digits), tp_points, DoubleToString(request.sl, digits), sl_points,
            (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL)));
        return -1;
    }

    switch (cmd) {
    case OP_BUY:
    case OP_SELL:
        return (int)_MQL45_trader.ResultDeal();
    default:
        return (int)_MQL45_trader.ResultOrder();
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrdersHistoryTotal()
{
    if (!HistorySelect(0, TimeCurrent())) {
        return 0;
    }
    return HistoryOrdersTotal();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrdersTotal()
{
    positions_total = ::PositionsTotal();
    orders_total = ::OrdersTotal();
    return positions_total + orders_total;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::OrderSelect(int index, int select, int mode = MODE_TRADES)
{
    bool result = false;
    last_selected_position_ticket = last_selected_order_ticket = last_selected_history_ticket = 0;
    if (select == SELECT_BY_POS) {
        if (mode == MODE_TRADES && index < positions_total) {
            ulong ticket = ::PositionGetTicket(index);
            if (ticket != 0) {
                result = ::PositionSelectByTicket(ticket);
                if (result) { last_selected_position_ticket = ticket; }
            }
        }
        if (mode == MODE_TRADES && index >= positions_total) {
            ulong ticket = ::OrderGetTicket(index - positions_total);
            if (ticket != 0) {
                result = ::OrderSelect(ticket);
                if (result) { last_selected_order_ticket = ticket; }
            }
        }
        else if (mode == MODE_HISTORY) {
            ulong ticket = ::HistoryOrderGetTicket(index);
            if (ticket != 0) { result = ::HistoryOrderSelect(ticket); }
            if (result) { last_selected_history_ticket = ticket; }
        }
    }
    else if (select == SELECT_BY_TICKET) {
        ulong ticket = index;
        if (mode == MODE_TRADES) {
            result = ::PositionSelectByTicket(ticket);
            if (result) {
                last_selected_position_ticket = ticket;
            }
            else {
                result = ::OrderSelect(ticket);
                if (result) { last_selected_order_ticket = ticket; }
            }
        }
        else if (mode == MODE_HISTORY) {
            result = ::HistoryOrderSelect(ticket);
            if (result) { last_selected_history_ticket = ticket; }
        }
    }
    return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderClosePrice()
{
    double close_price = 0;
    if (last_selected_history_ticket != 0) {
        close_price = ::HistoryOrderGetDouble(last_selected_history_ticket, ORDER_PRICE_CURRENT);
    }
    else if (last_selected_position_ticket != 0) {
        close_price = ::PositionGetDouble(POSITION_PRICE_CURRENT);
    }
    else if (last_selected_order_ticket != 0) {
        close_price = ::OrderGetDouble(ORDER_PRICE_CURRENT);
    }
    return close_price;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime MQL45::OrderCloseTime()
{
    datetime close_time = (datetime)::HistoryOrderGetInteger(last_selected_history_ticket, ORDER_TIME_DONE);
    return close_time;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::OrderComment()
{
    string comment = (last_selected_position_ticket != 0) ? ::PositionGetString(POSITION_COMMENT) : ::OrderGetString(ORDER_COMMENT);
    return comment;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderCommission()
{
    return 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderExpiration()
{
    return 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderLots()
{
    double lots = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_VOLUME) : ::OrderGetDouble(ORDER_VOLUME_CURRENT);
    return lots;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrderMagicNumber()
{
    int magic = (last_selected_position_ticket != 0) ? (int)::PositionGetInteger(POSITION_MAGIC) : (int)::OrderGetInteger(ORDER_MAGIC);
    return magic;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderOpenPrice()
{
    double open_price = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_PRICE_OPEN) : ::OrderGetDouble(ORDER_PRICE_OPEN);
    return open_price;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime MQL45::OrderOpenTime()
{
    datetime open_time = (last_selected_position_ticket != 0) ? (datetime)::PositionGetInteger(POSITION_TIME) : (datetime)::OrderGetInteger(ORDER_TIME_SETUP);
    return open_time;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderProfit()
{
    double profit = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_PROFIT) : 0.0;
    return profit;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderStopLoss()
{
    double sl = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_SL) : OrderGetDouble(ORDER_SL);
    return sl;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderSwap()
{
    double swap = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_SWAP) : 0.0;
    return swap;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::OrderSymbol()
{
    string symbol = (last_selected_position_ticket != 0) ? ::PositionGetString(POSITION_SYMBOL) : ::OrderGetString(ORDER_SYMBOL);
    return symbol;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::OrderTakeProfit()
{
    double tp = (last_selected_position_ticket != 0) ? ::PositionGetDouble(POSITION_TP) : OrderGetDouble(ORDER_TP);
    return tp;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrderTicket()
{
    int ticket = (last_selected_position_ticket != 0) ? (int)::PositionGetInteger(POSITION_TICKET) : (int)::OrderGetInteger(ORDER_TICKET);
    return ticket;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrderType()
{
    int order_type = (last_selected_position_ticket != 0) ? PositionTypeToInteger((ENUM_POSITION_TYPE)::PositionGetInteger(POSITION_TYPE)) : OrderTypeToInteger((ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE));
    return order_type;
}

