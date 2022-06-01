//+------------------------------------------------------------------+
//|                                        MQL45_StringFunctions.mqh |
//|                                Copyright 2021, babydaemons, Inc. |
//|                                      http://www.babydaemons.info |
//+------------------------------------------------------------------+
#include "MQL45.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::StringTrimLeft(const string text)
{
    string result = text;
    StringTrimLeft(result);
    return(result);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::StringTrimRight(const string text)
{
    string result = text;
    StringTrimRight(result);
    return(result);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ushort MQL45::StringGetChar(string string_value, int pos)
{
    return(StringGetCharacter(string_value, pos));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string MQL45::StringSetChar(string string_var, int pos, ushort value)
{
    string str = string_var;
    StringSetCharacter(str, pos, value);
    return(str);
}
