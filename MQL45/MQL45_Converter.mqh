//+------------------------------------------------------------------+
//|                                              MQL45_Converter.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

#ifdef __DEBUG_TIMEFRAMES
#import "user32.dll"
int MessageBoxW(ulong hWnd, string szText, string szCaption,int nType);
#import
#endif /*__DEBUG_TIMEFRAMES*/

double MQL45::Ask;
double MQL45::Bid;
double MQL45::Close[];
double MQL45::High[];
double MQL45::Low[];
double MQL45::Open[];
datetime MQL45::Time[];
long MQL45::Volume[];
int MQL45::Bars;
int MQL45::Digits;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::RefreshRates()
{
    Digits = ::Digits();
    Ask = ::NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), Digits);
    Bid = ::NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), Digits);

    ::ArraySetAsSeries(Close, true);
    ::ArraySetAsSeries(High, true);
    ::ArraySetAsSeries(Low, true);
    ::ArraySetAsSeries(Open, true);
    ::ArraySetAsSeries(Time, true);
    ::ArraySetAsSeries(Volume, true);

    Bars = ::Bars(_Symbol, _Period);

#ifdef MQL45_BARS
    int bars = MQL45_BARS;
#else  /*MQL45_BARS*/
    int bars = Bars;
#endif /*MQL45_BARS*/
    ::CopyClose(_Symbol, _Period, 0, bars, Close);
    ::CopyHigh(_Symbol, _Period, 0, bars, High);
    ::CopyLow(_Symbol, _Period, 0, bars, Low);
    ::CopyOpen(_Symbol, _Period, 0, bars, Open);
    ::CopyTime(_Symbol, _Period, 0, bars, Time);
    ::CopyTickVolume(_Symbol, _Period, 0, bars, Volume);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES MQL45::IntegerToTimeframe(int value)
{
    string errmsg;
    
    switch(value) {
    case 0: return(PERIOD_CURRENT);
    case 1: return(PERIOD_M1);
    case 5: return(PERIOD_M5);
    case 15: return(PERIOD_M15);
    case 30: return(PERIOD_M30);
    case 60: return(PERIOD_H1);
    case 240: return(PERIOD_H4);
    case 1440: return(PERIOD_D1);
    case 10080: return(PERIOD_W1);
    case 43200: return(PERIOD_MN1);
    
    case 2: return(PERIOD_M2);
    case 3: return(PERIOD_M3);
    case 4: return(PERIOD_M4);      
    case 6: return(PERIOD_M6);
    case 10: return(PERIOD_M10);
    case 12: return(PERIOD_M12);
    case 16385: return(PERIOD_H1);
    case 16386: return(PERIOD_H2);
    case 16387: return(PERIOD_H3);
    case 16388: return(PERIOD_H4);
    case 16390: return(PERIOD_H6);
    case 16392: return(PERIOD_H8);
    case 16396: return(PERIOD_H12);
    case 16408: return(PERIOD_D1);
    case 32769: return(PERIOD_W1);
    case 49153: return(PERIOD_MN1);      
    default:
        errmsg = StringFormat("ERROR: %d could not convert ENUM_TIMEFRAME", value);
        Print(errmsg);
#ifdef __DEBUG_TIMEFRAMES
        MessageBoxW(NULL, errmsg, "ERROR", 0);
#else  /*__DEBUG_TIMEFRAMES*/
        Alert(errmsg);
#endif /*__DEBUG_TIMEFRAMES*/
        return(PERIOD_CURRENT);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_APPLIED_PRICE MQL45::IntegerToAppliedPrice(int value)
{
    switch(value) {
    case 0:
        return(PRICE_CLOSE);
    case 1:
        return(PRICE_OPEN);
    case 2:
        return(PRICE_HIGH);
    case 3:
        return(PRICE_LOW);
    case 4:
        return(PRICE_MEDIAN);
    case 5:
        return(PRICE_TYPICAL);
    case 6:
        return(PRICE_WEIGHTED);
    default:
        return(PRICE_CLOSE);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_MA_METHOD MQL45::IntegerToMAMethod(int value)
{
    switch(value) {
    case 0:
        return(MODE_SMA);
    case 1:
        return(MODE_EMA);
    case 2:
        return(MODE_SMMA);
    case 3:
        return(MODE_LWMA);
    default:
        return(MODE_SMA);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_STO_PRICE MQL45::IntegerToStoPrice(int value)
{
    switch(value) {
    case 0:
        return(STO_LOWHIGH);
    case 1:
        return(STO_CLOSECLOSE);
    default:
        return(STO_LOWHIGH);
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE MQL45::IntegerToOrderType(int value)
{
    switch(value) {
    case 0: // OP_BUY
        return(ORDER_TYPE_BUY);
    case 1: // OP_SELL
        return(ORDER_TYPE_SELL);
    case 2: // OP_BUYLIMIT
        return(ORDER_TYPE_BUY_LIMIT);
    case 3: // OP_SELLLIMIT
        return(ORDER_TYPE_SELL_LIMIT);
    case 4: // OP_BUYSTOP
        return(ORDER_TYPE_BUY_STOP);
    case 5: // OP_SELLSTOP
        return(ORDER_TYPE_SELL_STOP);
    }
    return(ORDER_TYPE_BUY);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::OrderTypeToInteger(ENUM_ORDER_TYPE type)
{
    switch(type) {
    case ORDER_TYPE_BUY:
        return(0);
    case ORDER_TYPE_SELL:
        return(1);
    case ORDER_TYPE_BUY_LIMIT:
        return(2);
    case ORDER_TYPE_SELL_LIMIT:
        return(3);
    case ORDER_TYPE_BUY_STOP:
        return(4);
    case ORDER_TYPE_SELL_STOP:
        return(5);
    }
    return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::PositionTypeToInteger(ENUM_POSITION_TYPE type)
{
    switch(type) {
    case POSITION_TYPE_BUY:
        return(0);
    case POSITION_TYPE_SELL:
        return(1);
    }
    return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_OBJECT MQL45::IntegerToObject(int value)
{
    switch(value) {
    case 0:  // OBJ_VLINE
        return(OBJ_VLINE);
    case 1:  // OBJ_HLINE
        return(OBJ_HLINE);
    case 2:  // OBJ_TREND
        return(OBJ_TREND);
    case 3:  // OBJ_TRENDBYANGLE
        return(OBJ_TRENDBYANGLE);
    case 20: // OBJ_CYCLES
        return(OBJ_CYCLES);
    case 5:  // OBJ_CHANNEL
        return(OBJ_CHANNEL);
    case 6:  // OBJ_STDDEVCHANNEL
        return(OBJ_STDDEVCHANNEL);
    case 4:  // OBJ_REGRESSION
        return(OBJ_REGRESSION);
    case 19: // OBJ_PITCHFORK
        return(OBJ_PITCHFORK);
    case 7:  // OBJ_GANNLINE
        return(OBJ_GANNLINE);
    case 8:  // OBJ_GANNFAN
        return(OBJ_GANNFAN);
    case 9:  // OBJ_GANNGRID
        return(OBJ_GANNGRID);
    case 10: // OBJ_FIBO
        return(OBJ_FIBO);
    case 11: // OBJ_FIBOTIMES
        return(OBJ_FIBOTIMES);
    case 12: // OBJ_FIBOFAN
        return(OBJ_FIBOFAN);
    case 13: // OBJ_FIBOARC
        return(OBJ_FIBOARC);
    case 15: // OBJ_FIBOCHANNEL
        return(OBJ_FIBOCHANNEL);
    case 14: // OBJ_EXPANSION
        return(OBJ_EXPANSION);
    case 16: // OBJ_RECTANGLE
        return(OBJ_RECTANGLE);
    case 17: // OBJ_TRIANGLE
        return(OBJ_TRIANGLE);
    case 18: // OBJ_ELLIPSE
        return(OBJ_ELLIPSE);
    case 29: // OBJ_ARROW_THUMB_UP
        return(OBJ_ARROW_THUMB_UP);
    case 30: // OBJ_ARROW_THUMB_DOWN
        return(OBJ_ARROW_THUMB_DOWN);
    case 31: // OBJ_ARROW_UP
        return(OBJ_ARROW_UP);
    case 32: // OBJ_ARROW_DOWN
        return(OBJ_ARROW_DOWN);
    case 33: // OBJ_ARROW_STOP
        return(OBJ_ARROW_STOP);
    case 34: // OBJ_ARROW_CHECK
        return(OBJ_ARROW_CHECK);
    case 35: // OBJ_ARROW_LEFT_PRICE
        return(OBJ_ARROW_LEFT_PRICE);
    case 36: // OBJ_ARROW_RIGHT_PRICE
        return(OBJ_ARROW_RIGHT_PRICE);
    case 37: // OBJ_ARROW_BUY
        return(OBJ_ARROW_BUY);
    case 38: // OBJ_ARROW_SELL
        return(OBJ_ARROW_SELL);
    case 22: // OBJ_ARROW
        return(OBJ_ARROW);
    case 21: // OBJ_TEXT
        return(OBJ_TEXT);
    case 23: // OBJ_LABEL
        return(OBJ_LABEL);
    case 25: // OBJ_BUTTON
        return(OBJ_BUTTON);
    case 26: // OBJ_BITMAP
        return(OBJ_BITMAP);
    case 24: // OBJ_BITMAP_LABEL
        return(OBJ_BITMAP_LABEL);
    case 27: // OBJ_EDIT
        return(OBJ_EDIT);
    case 42: // OBJ_EVENT
        return(OBJ_EVENT);
    case 28: // OBJ_RECTANGLE_LABEL
        return(OBJ_RECTANGLE_LABEL);
    default:
        return(OBJ_ARROW);
    }
}
