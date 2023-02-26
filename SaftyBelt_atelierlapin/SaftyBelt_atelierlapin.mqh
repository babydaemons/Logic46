//+------------------------------------------------------------------+
//|                                       SaftyBelt_atelierlapin.mqh |
//|                                    Copyright 2023, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, atelierlapin."
#property version   "1.00"
#property strict

//#define __DEBUG_INTERVAL 500

const int STDDEV_MINUTES = 240;
const string EXPERT_NAME = "SaftyBelt_atelierlapin";
const int ORDER_RETRY_COUNT = 60;

enum ENUM_PRICE_TYPE {
    PRICE_TYPE_POINT, // ポイント(最小価格単位)
    PRICE_TYPE_PERCENT, // パーセント(%)
};

enum ENUM_ENTRY_TYPE {
    ENTRY_TYPE_LONG_ONLY = 1, // Only Long
    ENTRY_TYPE_SHORT_ONLY = 2, // Only Short
};

sinput string DUMMY00 = "";                                         // 発注設定
sinput ENUM_ENTRY_TYPE ENTRY_TYPE = ENTRY_TYPE_SHORT_ONLY;          // ├エントリー種別
sinput int MAGIC_NUMBER = 12345678;                                 // ├マジックナンバー
sinput double LOTS = 1.00;                                          // ├ロット数
sinput int ORDER_MODIFY_INTERVAL_SECONDS = 60;                      // ├逆指値更新間隔(秒)
sinput ENUM_PRICE_TYPE PRICE_TYPE = PRICE_TYPE_POINT;               // ├価格種別(利確/損切)
input double ENTRY_WIDTH = 600;                                     // ├逆指値注文価格幅
input double TAKE_PROFIT = 3000;                                    // ├利確価格幅(TPなしは0)
input double STOP_LOSS = 2000;                                      // ├損切価格幅(SLなしは0)
sinput int SLIPPAGE = 100;                                          // └スリッページ(ポイント)
sinput string DUMMY20 = "";                                         // 再エントリー設定
input bool ENABLE_RE_ENTRY = true;                                  // ├有効/無効
sinput int RE_ENTRY_DISABLE_MINUTES = 240;                          // └再エントリー禁止時間(分)
sinput string DUMMY30 = "";                                         // 決済中断時刻設定
sinput string DUMMY31 = "【24時間稼働は00:00】";                    // │(決済中断時刻の入力形式)
sinput string CLOSE_TIME = "23:45";                                 // ├決済中断時刻設定(サーバー時刻)
sinput string DUMMY32 = "【24時間稼働は00:00】";                    // │(決済再開時刻の入力形式)
sinput string OPEN_TIME = "01:15";                                  // └決済再開時刻設定(サーバー時刻)
sinput string DUMMY40 = "";                                         // メール送信設定
sinput bool MAIL_ENABLED = true;                                    // └有効/無効
