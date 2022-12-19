//+------------------------------------------------------------------+
//|                                     SettleMagic_atelierlapin.mq4 |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, atelierlapin."
#property version   "1.00"
#property strict

sinput int MAGIC_NUMBER = 12345678; // マジックナンバー
sinput int TAKE_PROFIT = 100000; // 利確金額
sinput int STOP_LOSS = 50000; // 損切金額
sinput string DUMMY1 = "【24時間稼働は00:00】"; // ●決済中断時刻設定
sinput string CLOSE_TIME = "15:00"; // 決済中断時刻(サーバー時刻)
sinput string DUMMY2 = "【24時間稼働は00:00】"; // ●決済再開時刻設定
sinput string OPEN_TIME = "01:00"; // 決済再開時刻(サーバー時刻)

#include "Lib/MT5/AtelierLapinSettlement.mqh"
#include "Lib/MainSettlement.mqh"
