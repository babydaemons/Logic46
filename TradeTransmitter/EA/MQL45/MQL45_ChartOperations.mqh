//+------------------------------------------------------------------+
//|                                        MQL45_ChartOperations.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowBarsPerChart()
{
    return((int)ChartGetInteger(0, CHART_VISIBLE_BARS, 0));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::WindowExpertName()
{
    return(MQLInfoString(MQL_PROGRAM_NAME));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowFind(string name)
{
    if((ENUM_PROGRAM_TYPE)MQLInfoInteger(MQL_PROGRAM_TYPE) == PROGRAM_INDICATOR) {
        return(ChartWindowFind());
    } else {
        return(ChartWindowFind(0, name));
    }

    return(-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowFirstVisibleBar()
{
    return((int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR, 0));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowHandle(string symbol, int timeframe)
{
    ENUM_TIMEFRAMES tf = IntegerToTimeframe(timeframe);
    long handle = 0;
    long prev = 0;
    long total = ChartGetInteger(0, CHART_WINDOWS_TOTAL);

    for(int i = 0; i < total; i++) {
        if(i == 0) {
            handle = ChartFirst();
        } else {
            handle = ChartNext(prev);
        }

        if(handle < 0) {
            return(0);
        }

        if(ChartSymbol(handle) == symbol && ChartPeriod(handle) == tf) {
            return((int)handle);
        }
        prev = handle;
    }
    return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::WindowIsVisible(int index)
{
    return((bool)ChartGetInteger(0, CHART_WINDOW_IS_VISIBLE, index));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowOnDropped()
{
    return(ChartWindowOnDropped());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::WindowPriceMax(int index=0)
{
    return(ChartGetDouble(0, CHART_PRICE_MAX, index));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::WindowPriceMin(int index=0)
{
    return(ChartGetDouble(0, CHART_PRICE_MIN, index));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::WindowPriceOnDropped()
{
    return(ChartPriceOnDropped());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::WindowRedraw()
{
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::WindowScreenShot(string filename, int size_x, int size_y, int start_bar=-1, int chart_scale=-1, int chart_mode=-1)
{
    if(chart_scale > 0 && chart_scale <= 5) {
        ChartSetInteger(0, CHART_SCALE, chart_scale);
    }

    switch(chart_mode) {
    case 0:
        ChartSetInteger(0, CHART_MODE, CHART_BARS);
        break;
    case 1:
        ChartSetInteger(0, CHART_MODE, CHART_CANDLES);
        break;
    case 2:
        ChartSetInteger(0, CHART_MODE, CHART_LINE);
        break;
    }

    if(start_bar < 0) {
        return(ChartScreenShot(0, filename, size_x, size_y, ALIGN_RIGHT));
    }

    return(ChartScreenShot(0, filename, size_x, size_y, ALIGN_LEFT));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime MQL45::WindowTimeOnDropped()
{
    return(ChartTimeOnDropped());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowsTotal()
{
    return((int)ChartGetInteger(0, CHART_WINDOWS_TOTAL));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowXOnDropped()
{
    return(ChartXOnDropped());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::WindowYOnDropped()
{
    return(ChartYOnDropped());
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::HideTestIndicators(bool hide)
{
    TesterHideIndicators(hide);
}