//+------------------------------------------------------------------+
//|                                             MQL45_MarketInfo.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::MarketInfo(string symbol, int type)
{
    double margin = 0;
    switch(type) {
    case 1: // MODE_LOW
        return(SymbolInfoDouble(symbol, SYMBOL_LASTLOW));
    case 2: // MODE_HIGH
        return(SymbolInfoDouble(symbol, SYMBOL_LASTHIGH));
    case 5: // MODE_TIME
        return((double)SymbolInfoInteger(symbol, SYMBOL_TIME));
    case 9: // MODE_BID
        return(SymbolInfoDouble(symbol, SYMBOL_BID));
    case 10: // MODE_ASK
        return(SymbolInfoDouble(symbol, SYMBOL_ASK));
    case 11: // MODE_POINT
        return(SymbolInfoDouble(symbol, SYMBOL_POINT));
    case 12: // MODE_DIGITS
        return((double)SymbolInfoInteger(symbol, SYMBOL_DIGITS));
    case 13: // MODE_SPREAD
        return((double)SymbolInfoInteger(symbol, SYMBOL_SPREAD));
    case 14: // MODE_STOPLEVEL
        return((double)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL));
    case 15: // MODE_LOTSIZE
        return(SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE));
    case 16: // MODE_TICKVALUE
        return(SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE));
    case 17: // MODE_TICKSIZE
        return(SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE));
    case 18: // MODE_SWAPLONG
        return(SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG));
    case 19: // MODE_SWAPSHORT
        return(SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT));
    case 20: // MODE_STARTING
        return(0);
    case 21: // MODE_EXPIRATION
        return(0);
    case 22: // MODE_TRADEALLOWED
        return(0);
    case 23: // MODE_MINLOT
        return(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN));
    case 24: // MODE_LOTSTEP
        return(SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP));
    case 25: // MODE_MAXLOT
        return(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX));
    case 26: // MODE_SWAPTYPE
        return((double)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE));
    case 27: // MODE_PROFITCALCMODE
        return((double)SymbolInfoInteger(symbol, SYMBOL_TRADE_CALC_MODE));
    case 28: // MODE_MARGINCALCMODE
        return(0);
    case 29: // MODE_MARGININIT
        return(0);
    case 30: // MODE_MARGINMAINTENANCE
        return(0);
    case 31: // MODE_MARGINHEDGED
        return(0);
    case 32: // MODE_MARGINREQUIRED
        if (!OrderCalcMargin(ORDER_TYPE_BUY, symbol, 1.00, SymbolInfoDouble(symbol, SYMBOL_ASK), margin)) {
            return 0;
        }
        return(margin);
    case 33: // MODE_FREEZELEVEL
        return((double)SymbolInfoInteger(symbol, SYMBOL_TRADE_FREEZE_LEVEL));
    case 34: // MODE_CLOSEBY_ALLOWED
        return(0);
    }
    return(0);
}
