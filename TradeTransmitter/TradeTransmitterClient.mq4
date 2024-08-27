//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq4 |
//|                                          Copyright 2023, YUSUKE. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property version   "1.01"
#property strict

input string  SYMBOL_REMOVE_SUFFIX = "-cd"; // ポジションコピー時にシンボル名から削除するサフィックス
input double  LOTS_MULTIPLY = 1.0;          // ロット数の倍率

#include "ErrorDescriptionMT4.mqh"
#include "TradeTransmitterClient.mqh"
