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

    double __open[], __low[], __high[], __close[];
    long __tick_volume[], __real_volume[];
    int __spread[];
    datetime __time[];

    ::CopyOpen(symbol, IntegerToTimeframe(timeframe), 0, count, __open);
    ::CopyLow(symbol, IntegerToTimeframe(timeframe), 0, count, __low);
    ::CopyHigh(symbol, IntegerToTimeframe(timeframe), 0, count, __high);
    ::CopyClose(symbol, IntegerToTimeframe(timeframe), 0, count, __close);
    ::CopyTickVolume(symbol, IntegerToTimeframe(timeframe), 0, count, __tick_volume);
    ::CopyRealVolume(symbol, IntegerToTimeframe(timeframe), 0, count, __real_volume);
    ::CopySpread(symbol, IntegerToTimeframe(timeframe), 0, count, __spread);
    ::CopyTime(symbol, IntegerToTimeframe(timeframe), 0, count, __time);

    ::ArrayResize(rates_array, count);
    for(int i = 0; i < count; i++) {
        rates_array[i].open        = __open[i];
        rates_array[i].low         = __low[i];
        rates_array[i].high        = __high[i];
        rates_array[i].close       = __close[i];
        rates_array[i].tick_volume = __tick_volume[i];
        rates_array[i].real_volume = __real_volume[i];
        rates_array[i].spread      = __spread[i];
        rates_array[i].time        = __time[i];
    }

    return(count);
}
