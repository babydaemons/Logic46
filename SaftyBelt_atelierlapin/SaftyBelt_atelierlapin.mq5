//+------------------------------------------------------------------+
//|                                       SaftyBelt_atelierlapin.mq5 |
//|                                    Copyright 2023, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, atelierlapin."
#property version   "1.00"
#property strict

#define __DEBUG_INTERVAL 10

enum ENUM_PRICE_TYPE {
    PRICE_TYPE_POINT, // ポイント(最小価格単位)
    PRICE_TYPE_PERCENT, // パーセント(%)
    // PRICE_TYPE_STDDEV, // ボリンジャーバンド(σ)
};

sinput string DUMMY00 = "";                             // 発注設定
sinput int MAGIC_NUMBER = 12345678;                     // ├マジックナンバー
sinput int ORDER_MODIFY_INTERVAL_SECONDS = 60;          // ├更新時間間隔(秒)
sinput int RE_ORDER_DISABLE_MINUTES = 60;               // ├再エントリー禁止時間(分)
sinput ENUM_PRICE_TYPE PRICE_TYPE = PRICE_TYPE_POINT;   // ├価格種別(利確/損切/トレーリングストップ)
input double ENTRY_WIDTH = 1000;                        // ├エントリー待機価格幅
input double TAKE_PROFIT = 3000;                        // ├利確価格幅
input double STOP_LOSS = 1000;                          // ├損切価格幅
input double TRAILING_STOP = 1000;                      // ├トレーリングストップ価格幅
sinput double LOTS = 0.01;                              // └ロット数
sinput string DUMMY10 = "";                             // 時刻設定
sinput string DUMMY11 = "【24時間稼働は00:00】";        // │(決済中断時刻の入力形式)
sinput string CLOSE_TIME = "15:00";                     // ├決済中断時刻設定(サーバー時刻)
sinput string DUMMY12 = "【24時間稼働は00:00】";        // │(決済再開時刻の入力形式)
sinput string OPEN_TIME = "01:00";                      // └決済再開時刻設定(サーバー時刻)
sinput string DUMMY20 = "";                             // メール送信設定
sinput bool MAIL_ENABLED = true;                        // ├有効/無効
sinput string MAIL_TO_ADDRESS = "example@example.com";  // ├送信先メールアドレス
sinput string MAIL_FROM_ADDRESS = "example@gmail.com";  // ├送信元Gmailアドレス
sinput string MAIL_APP_NAME = "MT4";                    // ├Gmail指定アプリ名
sinput string MAIL_APP_PASSWORD = "password";           // └Gmailアプリパスワード

#include "Lib/SaftyBeltMain.mqh"
#include "Lib/MT5/SaftyBelt_atelierlapin.mqh"
