//+------------------------------------------------------------------+
//|                                       TradeTransmitterClient.mq4 |
//|                          Copyright 2025, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input double  LOTS_MULTIPLY = 2.0; // ポジションコピー時のロット数の係数

const string NAME_EXPERT_ADVISER_PATH = __FILE__;
#define NAME GetName(NAME_EXPERT_ADVISER_PATH)

#include "Common/KazuyaFX_TeacherEA.mqh"