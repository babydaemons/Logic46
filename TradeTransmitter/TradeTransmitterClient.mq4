//+------------------------------------------------------------------+
//|                                          CopyPositionSederEA.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property version   "1.00"
#property strict

input string  SERVER_NAME = "localhost";    // ポジション情報を送信先のサーバー名
input string  SYMBOL_REMOVE_SUFFIX = "-cd"; // ポジションコピー時にシンボル名から削除するサフィックス
input double  LOTS_MULTIPLY = 1.0;          // ロット数の倍率

#include "ErrorDescriptionMT4.mqh"
#include "TradeTransmitterClient.mqh"
