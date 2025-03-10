//+------------------------------------------------------------------+
//|                                                      Logic46.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//--- input parameters
input int       POSIION_MAX_COUNT = 3;
input int       SMA_BARS = 20;
input int       FI_BARS = 13;
input int       ADX_BARS = 20;
input double    ADX_ENTRY = 20.0;
input bool      ADX_PLUSDI_MINUSDI = false;
input double    LOT = 0.1;
input int       SL = 100;
input int       TRAILING_START = 150;
input int       TRAILING_STOP = 50;
input int       ENTRY_PREV_SECONDS = 3;
input int       ENTRY_INTERVAL_BARS = 3;
sinput double   STOP_BALANCE_PERCENTAGE = 99.0;
sinput int      SLIPPAGE = 10;
sinput bool     USE_BAR_CLOSE_TIMER = false;
sinput int      MAGIC = 20220602;
sinput string   COMMENT = "Logic46";

#ifndef __MQL4__
#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#else
#define MQL45_TIMEFRAMES int
#define MQL45_APPLICATION_START() /*nothing*/
#define MQL45_APPLICATION_END()   /*nothing*/
#endif

MQL45_APPLICATION_START()

// EA開始時の投資資金
double InitBalance;

// エントリーシグナル
int EntrySignal;

// 現在のローソク足の添字
int T;

// 条件１のシグナル
int Signal1;

// 条件２のシグナル
int Signal2;

// 条件３のシグナル
int Signal3;

int PositionCount;
datetime LastEntryDate;
int LastEntryType;
int LastEntryCount;

// 複数行コメント用のバッファー
string CommentBuffer;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    InitBalance = AccountBalance() + AccountCredit();
    EntrySignal = 0;
    T = USE_BAR_CLOSE_TIMER ? 0 : 1;
    Signal1 = Signal2 = Signal3 = 0;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // 特別条件１
    // EA緊急終了 残高が投資金額の99%を下回った時
    // ex. １ロット１００万円なら９９万円を下回ったとき
    double balance_percentage = InitBalance != 0 ? 100 * (AccountBalance() + AccountCredit()) / InitBalance : 0;
    if (balance_percentage < STOP_BALANCE_PERCENTAGE) {
        ExpertRemove();
        return;
    }

    // 損失ポジションのクローズ
    ClosePosition();

    // バー始値制限処理
    bool isNewBar = IsNewBar();

    PositionCount = GetPositionCount(LastEntryDate, LastEntryType);

    if (isNewBar) {
        CommentBuffer = PositionCount > 0 ? StringFormat("▲ロングポジション：%d\n", +PositionCount) : (PositionCount < 0 ? StringFormat("▼ショートポジション：%d\n", -PositionCount) : "●ノーポジション\n");

        // トレード実行
        Trade();

        CommentBuffer += StringFormat("口座損益：%+.0f\n", AccountProfit());
        CommentBuffer += StringFormat("口座残高：%+.0f\n", AccountBalance() + AccountCredit());
        Comment(CommentBuffer);
    }
}

//+------------------------------------------------------------------+
//| トレードの実行                                                   |
//+------------------------------------------------------------------+
void Trade()
{
    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＜（１つ前の足MA値）・・・MAの線が右肩上がりの状態
    // 条件２：現行足の始値と終値 ＞ MA　& 陽線（始値 ＜ 終値）であること
    // 条件３：FI ＞ 0
    // 条件４：ADX ＞ 20
    // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
    // ＊ 上記の５条件全て揃ったら現5分足の終値で買いエントリー
    // ＊ １つのポジションが未決済でも同様の買いサインが出たらさらに10000通貨買う
    // 
    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＞（１つ前の足MA値）・・・MAの線が右肩下がりの状態
    // 条件２：現行足の始値と終値 ＜ MA　& 陰線（始値 ＜ 終値）であること
    // 条件３：FI ＜ 0
    // 条件４：ADX ＞ 20　（ADX値は買いも売りも同条件）
    // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
    // ＊ 上記の５条件全て揃ったら現5分足の終値で売りエントリー
    // ＊ １つのポジションが未決済でも同様の買いサインが出たらさらに10000通貨買う

    // 条件１のチェック
    Signal1 = Condition1();

    // 条件２のチェック
    Signal2 = Condition2();

    // 条件３のチェック
    Signal3 = Condition3();

    if (Signal1 == 0) {
        return;
    }
    // 条件２のチェック：条件１と異なるシグナルなら、判定処理中断
    if (Signal2 != Signal1) {
        return;
    }
    // 条件３のチェック：条件１と異なるシグナルなら、判定処理中断
    if (Signal3 != Signal1) {
        return;
    }

    // 現在のローソク足で初めてシグナルが発生したら、終値でエントリー
    if (EntrySignal == 0) {
        // 最後にエントリーした、ロング/ショートの区別と現在のエントリーシグナルが異なればポジションクローズ
        if (EntrySignal == -LastEntryType) {
            ClosePosition();
            LastEntryDate = 0;
            LastEntryType = 0;
        }

        // 共通エントリ条件
        // 2) 最大取引通貨数：30000通貨
        if (MathAbs(PositionCount) >= POSIION_MAX_COUNT) {
            return;
        }

        // 前回のエントリーから指定の本数間が空いていなければ、エントリー取り止め
        if (TimeCurrent() - LastEntryDate < ENTRY_INTERVAL_BARS * PeriodSeconds()) {
            return;
        }

        // チェックした３条件の結果をエントリーシグナルに保存
        EntrySignal = Signal1;

        if (USE_BAR_CLOSE_TIMER) {
            // 終値エントリーするためのタイマーの待ち時間（秒数）
            int timer_interval = PeriodSeconds() - TimeSeconds(TimeCurrent()) - ENTRY_PREV_SECONDS;
            if (timer_interval > ENTRY_PREV_SECONDS) {
                // 待ち時間がパラメーター設定の終値までのローソク足の残り時間より長い場合、タイマーを設定
                EventSetTimer(timer_interval);
            }
            else {
                // 待ち時間がパラメーター設定の終値までのローソク足の残り時間より短い場合、即エントリーを実行
                EntryPosition();
            }
        }
        else {
            EntryPosition();
        }
    }
    else if (EntrySignal != Signal1) {
        // 終値エントリー実行のためのタイマーを無効化
        EventKillTimer();
        
        // エントリーシグナルをクリア
        EntrySignal = 0;
    }
}

//+------------------------------------------------------------------+
//| 条件１：ＭＡの判定                                               |
//+------------------------------------------------------------------+
int Condition1()
{
    // ＭＡ　：期間＝20、移動平均の種別＝Simple、適用価格＝Close
    double MA2 = iMA(Symbol(), Period(), SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, T + 2);
    double MA1 = iMA(Symbol(), Period(), SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, T + 1);
    double MA0 = iMA(Symbol(), Period(), SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, T + 0);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＜（１つ前の足MA値）・・・MAの線が右肩上がりの状態
    if (MA2 < MA1) {
        // 条件２：現行足の始値と終値 ＞ MA　& 陽線（始値 ＜ 終値）であること
        if (Open[T + 0] > MA0 && Close[T + 0] > MA0 && Close[T + 0] > Open[T + 0]) {
            CommentBuffer += StringFormat("▲条件1：MAロングエントリー条件成立／MA2=%s／MA1=%s\n", ToString(MA2), ToString(MA1));
            return +1;
        }
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＞（１つ前の足MA値）・・・MAの線が右肩下がりの状態
    if (MA2 > MA1) {
        // 条件２：現行足の始値と終値 ＜ MA　& 陰線（始値 ＜ 終値）であること
        if (Open[T + 0] < MA0 && Close[T + 0] < MA0 && Close[T + 0] < Open[T + 0]) {
            CommentBuffer += StringFormat("▼条件1：MAショートエントリー条件成立／MA2=%s／MA1=%s\n", ToString(MA2), ToString(MA1));
            return -1;
        }
    }

    CommentBuffer += StringFormat("●条件1：MA条件不成立／MA2=%s／MA1=%s\n", ToString(MA2), ToString(MA1));
    return 0;
}

//+------------------------------------------------------------------+
//| 条件２：ＦＩの判定                                               |
//+------------------------------------------------------------------+
int Condition2()
{
    // ＦＩ　：期間＝13、 種別＝Simple、適用価格＝Close
    double FI = iForce(Symbol(), Period(), FI_BARS, MODE_SMA, PRICE_CLOSE, T + 1);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＞ 0
    if (FI > 0) {
        CommentBuffer += StringFormat("▲条件2：FIロングエントリー条件不成立／FI=%+.3f\n", FI);
        return +1;
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＜ 0
    if (FI < 0) {
        CommentBuffer += StringFormat("▼条件2：FIショートエントリー条件成立／FI=%+.3f\n", FI);
        return -1;
    }

    CommentBuffer += StringFormat("●条件2：FI条件不成立／FI=%+.3f\n", FI);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件３：ＡＤＸの判定                                             |
//+------------------------------------------------------------------+
int Condition3()
{
    // ＡＤＸ：期間＝20、 適用価格＝Close
    double ADX2 = iADX(Symbol(), Period(), ADX_BARS, PRICE_CLOSE, MODE_MAIN, T + 2);
    double ADX1 = iADX(Symbol(), Period(), ADX_BARS, PRICE_CLOSE, MODE_MAIN, T + 1);

    double PLUSDI = iADX(Symbol(), Period(), ADX_BARS, PRICE_CLOSE, MODE_PLUSDI, T + 1);
    double MINUSDI = iADX(Symbol(), Period(), ADX_BARS, PRICE_CLOSE, MODE_MINUSDI, T + 1);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件４：ADX ＞ 20
    if (ADX1 > ADX_ENTRY) {
        if (!ADX_PLUSDI_MINUSDI) {
            // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
            if (ADX2 <= ADX1) {
                CommentBuffer += StringFormat("▲条件3：ADXロングエントリー条件成立／ADX1=%.3f／ADX2=%.3f\n", ADX1, ADX2);
                return +1;
            }
        }
        else {
            if (PLUSDI > MINUSDI) {
                CommentBuffer += StringFormat("▲条件3：ADXロングエントリー条件成立／ADX1=%.3f／ADX2=%.3f／PLUSDI=%.3f／MINUSDI=%.3f\n", ADX1, ADX2, PLUSDI, MINUSDI);
                return +1;
            }
        }
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件４：ADX ＞ 20　（ADX値は買いも売りも同条件）
    if (ADX1 > ADX_ENTRY) {
        if (!ADX_PLUSDI_MINUSDI) {
            // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
            if (ADX2 >= ADX1) {
                CommentBuffer += StringFormat("▼条件3：ADXショートエントリー条件不成立／ADX1=%.3f／ADX2=%.3f\n", ADX1, ADX2);
                return -1;
            }
        }
        else {
            if (PLUSDI < MINUSDI) {
                CommentBuffer += StringFormat("▼条件3：ADXショートエントリー条件不成立／ADX1=%.3f／ADX2=%.3f／PLUSDI=%.3f／MINUSDI=%.3f\n", ADX1, ADX2, PLUSDI, MINUSDI);
                return -1;
            }
        }
    }

    CommentBuffer += StringFormat("●条件3：ADX条件不成立／ADX1=%.3f／ADX2=%.3f\n", ADX1, ADX2);
    return 0;
}

//+------------------------------------------------------------------+
//| ポジションエントリー                                             |
//+------------------------------------------------------------------+
void EntryPosition()
{
    CommentBuffer += StringFormat("%s3条件成立：%sエントリー", Signal1 == +1 ? "▲" : "▼", Signal1 == +1 ? "ロング" : "ショート");

    // 保存したエントリーシグナルが買いなら、ロングエントリー
    if (EntrySignal == +1) {
        double tp = 0;
        double sl = NormalizeDouble(Bid - SL * Point(), Digits);
        color arrow = clrBlue;
        int ticket = OrderSend(Symbol(), OP_BUY, LOT, Ask, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %d", GetLastError());
        }
    }

    // 保存したエントリーシグナルが売りなら、ショートエントリー
    if (EntrySignal == -1) {
        double tp = 0;
        double sl = NormalizeDouble(Ask + SL * Point(), Digits);
        color arrow = clrRed;
        int ticket = OrderSend(Symbol(), OP_SELL, LOT, Bid, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %d", GetLastError());
        }
    }

    // エントリーシグナルのクリア
    EntrySignal = 0;
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void ClosePositionAll()
{
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }
        
        int ticket = OrderTicket();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        if (!OrderClose(ticket, LOT, price, SLIPPAGE, arrow)) {
            printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| ポジションクローズ                                               |
//+------------------------------------------------------------------+
void ClosePosition()
{
    for (int i = OrdersTotal() - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }
        
        int ticket = OrderTicket();
        double entry = OrderOpenPrice();
        double price = OrderType() == OP_BUY ? Bid : Ask;
        double profit_price = OrderType() == OP_BUY ? price - entry : entry - price;
        double profit_point = profit_price / Point();
        double stoploss_price = OrderType() == OP_BUY ? price - OrderStopLoss() : OrderStopLoss() - price;
        double stoploss_point = stoploss_price / Point();
        color arrow = OrderType() == OP_BUY ? clrRed : clrBlue;
        if (profit_point < -SL) {
            if (!OrderClose(ticket, LOT, price, SLIPPAGE, arrow)) {
                printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
            }
        }
        else if (stoploss_point > TRAILING_START) {
            double sl = NormalizeDouble(OrderType() == OP_BUY ? price - TRAILING_STOP * Point() : price + TRAILING_STOP * Point(), Digits);
            double tp = 0;
            if (!OrderModify(ticket, price, sl, tp, 0, arrow)) {
                printf("ERROR: OrderClose(#%d) FAILED: %d", ticket, GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
int GetPositionCount(datetime& last_entry_date, int& last_entry_type)
{
    int n = 0;
    last_entry_date = 0;
    for (int i = 0; i < OrdersTotal(); ++i) {
        if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        if (OrderSymbol() != Symbol()) {
            continue;
        }
        
        datetime entry_date = OrderOpenTime();
        if (entry_date > last_entry_date) {
            last_entry_date = entry_date;
        }

        last_entry_type = OrderType() == OP_BUY ? +1 : -1;

        n += OrderType() == OP_BUY ? +1 : -1;
    }
    return n;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    // ポジションエントリー
    EntryPosition();
    
    // タイマーの無効化
    EventKillTimer();
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    return 0.0;
}

//+------------------------------------------------------------------+
//| 新規バーのチェック                                               |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime _time = 0;  // バーの時刻
    datetime time = iTime(Symbol(), Period(), 0);
    static ulong _ticktime = 0; // ティックタイム
    ulong tickTime = GetMicrosecondCount();  // IsNewBar()のためティックタイム更新 

    if (_time != time) { // 新規バーのティック
        _time = time;
        _ticktime = tickTime;
        return true;
    }
    else if (_ticktime != tickTime) { // 新規バー以外のティック
        return false;
    }
    return false;
}

//+------------------------------------------------------------------+
//| レートの文字列化                                                 |
//+------------------------------------------------------------------+
string ToString(double rate)
{
    return DoubleToString(rate, Digits);
}

MQL45_APPLICATION_END()
