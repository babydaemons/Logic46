//+------------------------------------------------------------------+
//|                                       SaftyBelt_atelierlapin.mqh |
//|                                    Copyright 2023, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, atelierlapin."
#property version   "1.00"
#property strict

//#define __DEBUG_INTERVAL 500

const int STDDEV_MINUTES = 5 * 1440;
const string EXPERT_NAME = "SaftyBelt_atelierlapin";
const int ORDER_RETRY_COUNT = 60;

enum ENUM_PRICE_TYPE {
    PRICE_TYPE_POINT, // ポイント(最小価格単位)
    PRICE_TYPE_PERCENT, // パーセント(%)
    PRICE_TYPE_STDDEV, // ボリンジャーバンド(σ)
};

enum ENUM_ENTRY_TYPE {
    ENTRY_TYPE_LONG_ONLY = 1, // Only Long
    ENTRY_TYPE_SHORT_ONLY = 2, // Only Short
    ENTRY_TYPE_BOTH_LONG_SHORT = 3, // Long & Short
};

sinput string DUMMY00 = "";                                     // 発注設定
sinput ENUM_ENTRY_TYPE ENTRY_TYPE = ENTRY_TYPE_BOTH_LONG_SHORT; // ├エントリー種別
sinput int MAGIC_NUMBER = 12345678;                             // ├マジックナンバー
sinput double LOTS = 0.01;                                      // ├ロット数
sinput int ORDER_MODIFY_INTERVAL_SECONDS = 60;                  // ├逆指値更新間隔(秒)
sinput ENUM_PRICE_TYPE PRICE_TYPE = PRICE_TYPE_POINT;           // ├価格種別(利確/損切/トレーリングストップ)
input double ENTRY_WIDTH = 1000;                                // ├逆指値注文価格幅
input double TAKE_PROFIT = 4000;                                // ├利確価格幅
input double STOP_LOSS = 3500;                                  // ├損切価格幅
sinput int SLIPPAGE = 10;                                       // └スリッページ(ポイント)
sinput string DUMMY10 = "";                                     // トレーリングストップ設定
sinput bool TRAILING_STOP_ENABLE = true;                        // ├有効/無効
sinput int TRAILING_STOP_INTERVAL_SECONDS = 13;                 // ├トレーリングストップ更新時間間隔(秒)
input double TRAILING_STOP = 100;                               // └トレーリングストップ価格幅
sinput string DUMMY20 = "";                                     // 再エントリー設定
input bool ENABLE_RE_ENTRY = true;                              // ├有効/無効
sinput int RE_ENTRY_DISABLE_MINUTES = 60;                       // └再エントリー禁止時間(分)
sinput string DUMMY30 = "";                                     // 決済中断時刻設定
sinput string DUMMY31 = "【24時間稼働は00:00】";                // │(決済中断時刻の入力形式)
sinput string CLOSE_TIME = "00:00";                             // ├決済中断時刻設定(サーバー時刻)
sinput string DUMMY32 = "【24時間稼働は00:00】";                // │(決済再開時刻の入力形式)
sinput string OPEN_TIME = "00:00";                              // └決済再開時刻設定(サーバー時刻)
sinput string DUMMY40 = "";                                     // メール送信設定
sinput bool MAIL_ENABLED = true;                                // └有効/無効
