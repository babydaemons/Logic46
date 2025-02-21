//+------------------------------------------------------------------+
//|                                       TradeTransmitterClient.mq4 |
//|                          Copyright 2024, Kazuya Quartet Academy. |
//|                                       https://www.fx-kazuya.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Kazuya Quartet Academy."
#property link      "https://www.fx-kazuya.com/"
#property version   "1.00"
#property strict

input string  EMAIL = "babydaemons@gmail.com"; // 証券会社のWebサイトのドメイン名
input string  TRADE_TRANSMITTER_SERVER = "https://babydaemons.jp"; // トレードポジションを受信するサーバー
input string  SYMBOL_REMOVE_SUFFIX = "-cd"; // ポジションコピー時にシンボル名から削除するサフィックス

#include "ErrorDescriptionMT4.mqh"
#include "TradeTransmitterClient.mqh"
