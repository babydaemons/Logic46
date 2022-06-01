//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ArrayCopyRates(MqlRates &rates_array[], string symbol=NULL, int timeframe=0)
{
    int count = ::Bars(symbol, IntegerToTimeframe(timeframe));

    double open[], low[], high[], close[];
    long tick_volume[], real_volume[];
    int spread[];
    datetime time[];

    ::CopyOpen(symbol, IntegerToTimeframe(timeframe), 0, count, open);
    ::CopyLow(symbol, IntegerToTimeframe(timeframe), 0, count, low);
    ::CopyHigh(symbol, IntegerToTimeframe(timeframe), 0, count, high);
    ::CopyClose(symbol, IntegerToTimeframe(timeframe), 0, count, close);
    ::CopyTickVolume(symbol, IntegerToTimeframe(timeframe), 0, count, tick_volume);
    ::CopyRealVolume(symbol, IntegerToTimeframe(timeframe), 0, count, real_volume);
    ::CopySpread(symbol, IntegerToTimeframe(timeframe), 0, count, spread);
    ::CopyTime(symbol, IntegerToTimeframe(timeframe), 0, count, time);

    ::ArrayResize(rates_array, count);
    for(int i = 0; i < count; i++) {
        rates_array[i].open        = open[i];
        rates_array[i].low         = low[i];
        rates_array[i].high        = high[i];
        rates_array[i].close       = close[i];
        rates_array[i].tick_volume = tick_volume[i];
        rates_array[i].real_volume = real_volume[i];
        rates_array[i].spread      = spread[i];
        rates_array[i].time        = time[i];
    }

    return(count);
}
