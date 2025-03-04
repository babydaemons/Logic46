//+------------------------------------------------------------------+
//|                                       TradeTransmitterClient.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

string GetEmail()
{
    string path = __FILE__;
    string items[];
    int n = StringSplit(path, '\\', items);
    string email = items[n - 1];
    StringReplace(email, ".mq4", "");
    return email;
}

#define EMAIL GetEmail()

#include "TradeTransmitterClient.mq4"