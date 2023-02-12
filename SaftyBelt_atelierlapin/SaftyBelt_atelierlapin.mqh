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

enum ENUM_PRICE_TYPE {
    PRICE_TYPE_POINT, // ポイント(最小価格単位)
    PRICE_TYPE_PERCENT, // パーセント(%)
    PRICE_TYPE_STDDEV, // ボリンジャーバンド(σ)
};

sinput string DUMMY00 = "";                             // 発注設定
sinput int MAGIC_NUMBER = 12345678;                     // ├マジックナンバー
sinput int ORDER_MODIFY_INTERVAL_SECONDS = 60;          // ├エントリー更新時間間隔(秒)
sinput int TRAILING_STOP_INTERVAL_SECONDS = 13;         // ├トレーリングストップ更新時間間隔(秒)
sinput int RE_ORDER_DISABLE_MINUTES = 60;               // ├再エントリー禁止時間(分)
sinput ENUM_PRICE_TYPE PRICE_TYPE = PRICE_TYPE_POINT;   // ├価格種別(利確/損切/トレーリングストップ)
input double ENTRY_WIDTH = 1000;                        // ├エントリー待機価格幅
input double TAKE_PROFIT = 4000;                        // ├利確価格幅
input double STOP_LOSS = 3500;                          // ├損切価格幅
input double TRAILING_STOP = 100;                       // ├トレーリングストップ価格幅
input bool ENABLE_LOSE_RE_ENTRY = true;                 // ├負けトレンドの後の再エントリーの許可
sinput double LOTS = 0.01;                              // ├ロット数
sinput int SLIPPAGE = 10;                               // └スリッページ(ポイント)
sinput string DUMMY10 = "";                             // 時刻設定
sinput string DUMMY11 = "【24時間稼働は00:00】";        // │(決済中断時刻の入力形式)
sinput string CLOSE_TIME = "00:00";                     // ├決済中断時刻設定(サーバー時刻)
sinput string DUMMY12 = "【24時間稼働は00:00】";        // │(決済再開時刻の入力形式)
sinput string OPEN_TIME = "00:00";                      // └決済再開時刻設定(サーバー時刻)
sinput string DUMMY20 = "";                             // メール送信設定
sinput bool MAIL_ENABLED = true;                        // ├有効/無効
sinput string MAIL_TO_ADDRESS = "example@example.com";  // └送信先メールアドレス
