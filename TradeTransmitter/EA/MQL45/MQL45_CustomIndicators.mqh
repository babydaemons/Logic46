//+------------------------------------------------------------------+
//|                                       MQL45_CustomIndicators.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::IndicatorDigits(int digits)
{
    IndicatorSetInteger(INDICATOR_DIGITS, digits);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::IndicatorShortName(string name)
{
    IndicatorSetString(INDICATOR_SHORTNAME, name);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexArrow(int index, int code)
{
    PlotIndexSetInteger(index, PLOT_ARROW, code);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexDrawBegin(int index, int begin)
{
    PlotIndexSetInteger(index, PLOT_DRAW_BEGIN, begin);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexEmptyValue(int index, double value)
{
    PlotIndexSetDouble(index, PLOT_EMPTY_VALUE, value);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexLabel(int index, string text)
{
    PlotIndexSetString(index, PLOT_LABEL, text);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexShift(int index, int shift)
{
    PlotIndexSetInteger(index, PLOT_SHIFT, shift);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetIndexStyle(int index, int type, int style = EMPTY, int width = EMPTY, color clr = clrNONE)
{
    if(width > -1) {
        PlotIndexSetInteger(index, PLOT_LINE_WIDTH, width);
    }

    PlotIndexSetInteger(index, PLOT_LINE_COLOR, clr);

    switch(type) {
    case 1:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_SECTION);
        break;
    case 2:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_HISTOGRAM);
        break;
    case 3:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_ARROW);
        break;
    case 4:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_ZIGZAG);
        break;
    case 12:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_NONE);
        break;
    default:
        PlotIndexSetInteger(index, PLOT_DRAW_TYPE, DRAW_LINE);
        break;
    }

    if(style == EMPTY) {
        return;
    }
    switch(style) {
    case 0:
        PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_SOLID);
        break;
    case 1:
        PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_DASH);
        break;
    case 2:
        PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_DOT);
        break;
    case 3:
        PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_DASHDOT);
        break;
    case 4:
        PlotIndexSetInteger(index, PLOT_LINE_STYLE, STYLE_DASHDOTDOT);
        break;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetLevelStyle(int draw_style, int line_width, color clr)
{
    IndicatorSetInteger(INDICATOR_LEVELWIDTH, line_width);
    IndicatorSetInteger(INDICATOR_LEVELCOLOR, clr);

    switch(draw_style) {
    case 0:
        IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_SOLID);
        break;
    case 1:
        IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_DASH);
        break;
    case 2:
        IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_DOT);
        break;
    case 3:
        IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_DASHDOT);
        break;
    case 4:
        IndicatorSetInteger(INDICATOR_LEVELSTYLE, STYLE_DASHDOTDOT);
        break;
    }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MQL45::SetLevelValue(int level, double value)
{
    IndicatorSetDouble(INDICATOR_LEVELVALUE, level, value);
}
