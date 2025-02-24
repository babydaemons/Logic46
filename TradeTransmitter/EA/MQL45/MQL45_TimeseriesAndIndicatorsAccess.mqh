//+------------------------------------------------------------------+
//|                          MQL45_TimeseriesAndIndicatorsAccess.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::iBars(string symbol, int timeframe)
{
    return(::Bars(symbol, IntegerToTimeframe(timeframe)));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::iBarShift(string symbol, int timeframe, datetime time, bool exact=true)
{
    int result = -1;
    datetime time_arr[];
    long min = 0;

    if(time < 0) return(-1);

    if(::CopyTime(symbol, IntegerToTimeframe(timeframe), iTime(symbol, timeframe, 0), time, time_arr) == -1) {
        return(-1);
    }

    if(exact) {
        return(::ArraySize(time_arr) - 1);
    }

    for(int i = 0; i < ::ArraySize(time_arr); i++) {
        if(i > 0) {
            if(::MathAbs(time_arr[i] - time) > min) {
                result = i;
                break;
            }
            min = ::MathAbs(time_arr[i] - time);
        } else {
            min = ::MathAbs(time_arr[i] - time);
        }
    }

    return(result);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iClose(string symbol,int timeframe, int shift)
{
    double close_array[];
    if(::CopyClose(symbol, IntegerToTimeframe(timeframe), shift, 1, close_array) == -1) {
        return(0);
    }
    return(close_array[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iHigh(string symbol,int timeframe, int shift)
{
    double high_array[];
    if(::CopyHigh(symbol, IntegerToTimeframe(timeframe), shift, 1, high_array) == -1) {
        return(0);
    }
    return(high_array[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::iHighest(string symbol, int timeframe, int type, int count, int start)
{
    double price[];
    long volume[];
    ::ArraySetAsSeries(price, true);

    switch(type) {
    case 0: // MODE_OPEN
        ::CopyOpen(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 1: // MODE_LOW
        ::CopyLow(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 2: // MODE_HIGH
        CopyHigh(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 3: // MODE_CLOSE
        ::CopyClose(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 4: // MODE_VOLUME
        ::ArraySetAsSeries(volume, true);
        ::CopyTickVolume(symbol, IntegerToTimeframe(timeframe), start, count, volume);
        return(::ArrayMaximum(volume, 0, count) + start);
    }

    return(::ArrayMaximum(price, 0, count) + start);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iLow(string symbol,int timeframe, int shift)
{
    double low_array[];
    if(::CopyLow(symbol, IntegerToTimeframe(timeframe), shift, 1, low_array) == -1) {
        return(0);
    }
    return(low_array[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::iLowest(string symbol, int timeframe, int type, int count, int start)
{
    double price[];
    long volume[];
    ::ArraySetAsSeries(price, true);

    switch(type) {
    case 0: // MODE_OPEN
        ::CopyOpen(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 1: // MODE_LOW
        ::CopyLow(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 2: // MODE_HIGH
        ::CopyHigh(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 3: // MODE_CLOSE
        ::CopyClose(symbol, IntegerToTimeframe(timeframe), start, count, price);
        break;
    case 4: // MODE_VOLUME
        ::ArraySetAsSeries(volume, true);
        ::CopyTickVolume(symbol, IntegerToTimeframe(timeframe), start, count, volume);
        return(::ArrayMinimum(volume, 0, count) + start);
    }

    return(::ArrayMinimum(price, 0, count) + start);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::iOpen(string symbol, int timeframe, int shift)
{
    double open_array[];
    if(::CopyOpen(symbol, IntegerToTimeframe(timeframe), shift, 1, open_array) == -1) {
        return(0);
    }
    return(open_array[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime MQL45::iTime(string symbol, int timeframe, int shift)
{
    datetime time_array[];
    if(::CopyTime(symbol, IntegerToTimeframe(timeframe), shift, 1, time_array) == -1) {
        return(0);
    }
    return(time_array[0]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long MQL45::iVolume(string symbol, int timeframe, int shift)
{
    long volume_array[];
    if(::CopyTickVolume(symbol, IntegerToTimeframe(timeframe), shift, 1, volume_array) == -1) {
        return(0);
    }
    return(volume_array[0]);
}
