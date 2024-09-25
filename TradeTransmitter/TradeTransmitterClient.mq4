//+------------------------------------------------------------------+
//|                                       TradeTransmitterClient.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  URL = "http://127.0.0.1/api/position/www.fxtrade.co.jp/201916737";    // ポジション情報を送信先のサーバーのURL
input string  SYMBOL_REMOVE_SUFFIX = "-cd"; // ポジションコピー時にシンボル名から削除するサフィックス

#include "ErrorDescriptionMT4.mqh"
#include "TradeTransmitterClient.mqh"
