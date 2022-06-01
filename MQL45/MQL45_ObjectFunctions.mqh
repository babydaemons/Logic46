//+------------------------------------------------------------------+
//|                                        MQL45_ObjectFunctions.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectCreate(string object_name, ENUM_OBJECT object_type, int sub_window, datetime time1, double price1, datetime time2 = 0, double price2 = 0, datetime time3 = 0, double price3 = 0)
{
    return(ObjectCreate(0, object_name, object_type, sub_window, time1, price1, time2, price2, time3, price3));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectCreate(string object_name, int object_type, int sub_window, datetime time1, double price1, datetime time2 = 0, double price2 = 0, datetime time3 = 0, double price3 = 0)
{
    return(ObjectCreate(0, object_name, IntegerToObject(object_type), sub_window, time1, price1, time2, price2, time3, price3));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::ObjectName(int object_index)
{
    return(ObjectName(0, object_index));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectDelete(string object_name)
{
    return(ObjectDelete(0, object_name));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ObjectsDeleteAll(int sub_window = EMPTY, int object_type = EMPTY)
{
    return(ObjectsDeleteAll(0, sub_window, object_type));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ObjectFind(string object_name)
{
    return(ObjectFind(0, object_name));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectMove(string object_name, int point_index, datetime time, double price)
{
    return(ObjectMove(0, object_name, point_index, time, price));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ObjectsTotal(int type = EMPTY)
{
    return(::ObjectsTotal(0, -1, type));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::ObjectDescription(string object_name)
{
    return(ObjectGetString(0, object_name, OBJPROP_TEXT));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::ObjectGet(string object_name, int index)
{
    switch(index) {
    case 0: // OBJPROP_TIME1
        return((double)ObjectGetInteger(0, object_name, OBJPROP_TIME));
    case 1: // OBJPROP_PRICE1
        return(ObjectGetDouble(0, object_name, OBJPROP_PRICE));
    case 2: // OBJPROP_TIME2
        return((double)ObjectGetInteger(0, object_name, OBJPROP_TIME, 1));
    case 3: // OBJPROP_PRICE2
        return(ObjectGetDouble(0, object_name, OBJPROP_PRICE, 1));
    case 4: // OBJPROP_TIME3
        return((double)ObjectGetInteger(0, object_name, OBJPROP_TIME, 2));
    case 5: // OBJPROP_PRICE3
        return(ObjectGetDouble(0, object_name, OBJPROP_PRICE, 2));
    case 6: // OBJPROP_COLOR
        return((double)ObjectGetInteger(0, object_name, OBJPROP_COLOR));
    case 7: // OBJPROP_STYLE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_STYLE));
    case 8: // OBJPROP_WIDTH
        return((double)ObjectGetInteger(0, object_name, OBJPROP_WIDTH));
    case 9: // OBJPROP_BACK
        return((double)ObjectGetInteger(0, object_name, OBJPROP_BACK));
    case 10: // OBJPROP_RAY
        return((double)ObjectGetInteger(0, object_name, OBJPROP_RAY_RIGHT));
    case 11: // OBJPROP_ELLIPSE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_ELLIPSE));
    case 12: // OBJPROP_SCALE
        return(ObjectGetDouble(0, object_name, OBJPROP_SCALE));
    case 13: // OBJPROP_ANGLE
        return(ObjectGetDouble(0, object_name, OBJPROP_ANGLE));
    case 14: // OBJPROP_ARROWCODE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_ARROWCODE));
    case 15: // OBJPROP_TIMEFRAMES
        return((double)ObjectGetInteger(0, object_name, OBJPROP_TIMEFRAMES));
    case 16: // OBJPROP_DEVIATION
        return(ObjectGetDouble(0, object_name, OBJPROP_DEVIATION));
    case 100: // OBJPROP_FONTSIZE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_FONTSIZE));
    case 101: // OBJPROP_CORNER
        return((double)ObjectGetInteger(0, object_name, OBJPROP_CORNER));
    case 102: // OBJPROP_XDISTANCE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_XDISTANCE));
    case 103: // OBJPROP_YDISTANCE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_YDISTANCE));
    case 200: // OBJPROP_FIBOLEVELS
        return((double)ObjectGetInteger(0, object_name, OBJPROP_LEVELS));
    case 201: // OBJPROP_LEVELCOLOR
        return((double)ObjectGetInteger(0, object_name, OBJPROP_LEVELCOLOR));
    case 202: // OBJPROP_LEVELSTYLE
        return((double)ObjectGetInteger(0, object_name, OBJPROP_LEVELSTYLE));
    case 203: // OBJPROP_LEVELWIDTH
        return((double)ObjectGetInteger(0, object_name, OBJPROP_LEVELWIDTH));
    }
    return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::ObjectGetFiboDescription(string object_name, int index)
{
    return(ObjectGetString(0, object_name, OBJPROP_LEVELTEXT, index));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ObjectGetShiftByValue(string object_name, int value)
{
    datetime time[];
    MqlRates rate[];

    if(ObjectGetTimeByValue(0, object_name, value) < 0) {
        return(-1);
    }

    CopyRates(NULL, PERIOD_CURRENT, 0, 1, rate);
    if(CopyTime(NULL, PERIOD_CURRENT, rate[0].time, ObjectGetTimeByValue(0, object_name, value), time) > 0) {
        return(ArraySize(time) - 1);
    }
    return(-1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MQL45::ObjectGetValueByShift(string object_name, int shift)
{
    MqlRates rate[];
    CopyRates(NULL, PERIOD_CURRENT, shift, 1, rate);
    return(ObjectGetValueByTime(0, object_name, rate[0].time, 0));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectSet(string object_name, int index, double value)
{
    switch(index) {
    case 0: // OBJPROP_TIME1
        return(ObjectSetInteger(0, object_name, OBJPROP_TIME, (int)value));
    case 1: // OBJPROP_PRICE1
        return(ObjectSetDouble(0, object_name, OBJPROP_PRICE, value));
    case 2: // OBJPROP_TIME2
        return(ObjectSetInteger(0, object_name, OBJPROP_TIME, 1, (int)value));
    case 3: // OBJPROP_PRICE2
        return(ObjectSetDouble(0, object_name, OBJPROP_PRICE, 1, value));
    case 4: // OBJPROP_TIME3
        return(ObjectSetInteger(0, object_name, OBJPROP_TIME, 2, (int)value));
    case 5: // OBJPROP_PRICE3
        return(ObjectSetDouble(0, object_name, OBJPROP_PRICE, 2, value));
    case 6: // OBJPROP_COLOR
        return(ObjectSetInteger(0, object_name, OBJPROP_COLOR, (int)value));
    case 7: // OBJPROP_STYLE
        return(ObjectSetInteger(0, object_name, OBJPROP_STYLE, (int)value));
    case 8: // OBJPROP_WIDTH
        return(ObjectSetInteger(0, object_name, OBJPROP_WIDTH, (int)value));
    case 9: // OBJPROP_BACK
        return(ObjectSetInteger(0, object_name, OBJPROP_BACK, (int)value));
    case 10: // OBJPROP_RAY
        return(ObjectSetInteger(0, object_name, OBJPROP_RAY_RIGHT, (int)value));
    case 11: // OBJPROP_ELLIPSE
        return(ObjectSetInteger(0, object_name, OBJPROP_ELLIPSE, (int)value));
    case 12: // OBJPROP_SCALE
        return(ObjectSetDouble(0, object_name, OBJPROP_SCALE, value));
    case 13: // OBJPROP_ANGLE
        return(ObjectSetDouble(0, object_name, OBJPROP_ANGLE, value));
    case 14: // OBJPROP_ARROWCODE
        return(ObjectSetInteger(0, object_name, OBJPROP_ARROWCODE, (int)value));
    case 15: // OBJPROP_TIMEFRAMES
        return(ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, (int)value));
    case 16: // OBJPROP_DEVIATION
        return(ObjectSetDouble(0, object_name, OBJPROP_DEVIATION, value));
    case 100: // OBJPROP_FONTSIZE
        return(ObjectSetInteger(0, object_name, OBJPROP_FONTSIZE, (int)value));
    case 101: // OBJPROP_CORNER
        return(ObjectSetInteger(0, object_name, OBJPROP_CORNER, (int)value));
    case 102: // OBJPROP_XDISTANCE
        return(ObjectSetInteger(0, object_name, OBJPROP_XDISTANCE, (int)value));
    case 103: // OBJPROP_YDISTANCE
        return(ObjectSetInteger(0, object_name, OBJPROP_YDISTANCE, (int)value));
    case 200: // OBJPROP_FIBOLEVELS
        return(ObjectSetInteger(0, object_name, OBJPROP_LEVELS, (int)value));
    case 201: // OBJPROP_LEVELCOLOR
        return(ObjectSetInteger(0, object_name, OBJPROP_LEVELCOLOR, (int)value));
    case 202: // OBJPROP_LEVELSTYLE
        return(ObjectSetInteger(0, object_name, OBJPROP_LEVELSTYLE, (int)value));
    case 203: // OBJPROP_LEVELWIDTH
        return(ObjectSetInteger(0, object_name, OBJPROP_LEVELWIDTH, (int)value));
    }
    return(false);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectSetFiboDescription(string object_name, int index, string text)
{
    return(ObjectSetString(0, object_name, OBJPROP_LEVELTEXT, index, text));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MQL45::ObjectSetText(string object_name, string text, int font_size=0, string font_name=NULL, color text_color=clrNONE)
{
    int type = (int)ObjectGetInteger(0, object_name, OBJPROP_TYPE);

    if(type != OBJ_LABEL && type != OBJ_TEXT) {
        return(false);
    }

    if(StringLen(text) > 0 && font_size > 0) {
        if(!ObjectSetString(0, object_name, OBJPROP_TEXT, text)) {
            return(false);
        }
        if(!ObjectSetInteger(0, object_name, OBJPROP_FONTSIZE, font_size)) {
            return(false);
        }
    }

    if(font_name != NULL) {
        if(!ObjectSetString(0, object_name, OBJPROP_FONT, font_name)) {
            return(false);
        }
    }

    if(text_color != clrNONE) {
        if(!ObjectSetInteger(0, object_name, OBJPROP_COLOR, text_color)) {
            return(false);
        }
    }

    return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int MQL45::ObjectType(string object_name)
{
    return((int)ObjectGetInteger(0, object_name, OBJPROP_TYPE));
}
