//+------------------------------------------------------------------+
//|                                                      Logic46.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#ifndef __MQL4__
#define MQL45_BARS 2
#include "MQL45/MQL45.mqh"
#else
#define MQL45_TIMEFRAMES int
#define MQL45_APPLICATION_START()   /*nothing*/
#define MQL45_APPLICATION_END()     /*nothing*/
#define OrderCloseComment(comment)  /*nothing */
#endif

#define ARRAY_SIZE 64

MQL45_TIMEFRAMES PERIOD[ARRAY_SIZE] = {
    PERIOD_M5,
    PERIOD_M15,
    PERIOD_M30,
    PERIOD_H1,
    PERIOD_H4,
    PERIOD_D1,
    PERIOD_W1,
    PERIOD_MN1
};

string NAME[ARRAY_SIZE] = {
    "M05",
    "M15",
    "M30",
    "H01",
    "H04",
    "D01",
    "W01",
    "MN1"
};

enum E_MAX_TIMEFRAME {
    MTF_M05 = 1,
    MTF_M15,
    MTF_M30,
    MTF_H01,
    MTF_H04,
    MTF_D01,
    MTF_W01,
    MTF_MN1,
};

//--- input parameters
input E_MAX_TIMEFRAME MIN_TIMEFRAME = MTF_M05;
input E_MAX_TIMEFRAME MAX_TIMEFRAME = MTF_H01;

input int       POSIION_MAX_COUNT = 3;
input int       SMA_BARS = 6;
input int       SMA_SCAN_BARS = 3;

input int       FI_BARS = 14;
input int       FI_SCAN_BARS = 2;
input double    FI_ENTRY = 0.0;

input int       ADX_BARS = 24;
input int       ADX_SCAN_BARS = 2;
input double    ADX_ENTRY = 20.0;

enum E_ADX_CHECK_TYPE { ADX_DI_ONLY, ADX_BARS_ONLY, ADX_DI_AND_BARS };
input E_ADX_CHECK_TYPE ADX_CHECK_TYPE = ADX_DI_ONLY;

input int       CORRELATION_BARS = 48;
input double    CORRELATION_MIN = 0.6;

input int       INCLINATION_BARS = 36;
input double    INCLINATION_MIN = 0.35;

input int       TR_BARS = 12;
input int       TR_SCAN_BARS = 1;
input int       TR_ENTRY = 10;

input E_MAX_TIMEFRAME TRAILING_TIMEFRAME = MTF_M05;
input int       TRAILING_BARS = 12;
input double    TRAILING_STEP = 0.8;
input double    TP_MULTIPLY = 4.0;
input double    SL_MULTIPLY = 2.8;

enum E_PERFECT_ORDER_TYPE { PERFECT_ORDER_NONE, PERFECT_ORDER_ONLY, PERFECT_ORDER_BOTH };
input E_PERFECT_ORDER_TYPE PERFECT_ORDER_TYPE = PERFECT_ORDER_NONE;

input int       FASTEST_TIMEFRANE_CHECK_PERCENTAGE = 40;
input bool      DISABLE_DUPLICATE_ENTRY = false;

input double    LOT = 0.1;
input int       ENTRY_PREV_SECONDS = 5;
input int       ENTRY_INTERVAL_BARS = 3;
enum E_ENTRY_DISABLE_TYPE { ENTRY_DISABLE_NANPIN = -1, ENTRY_DISABLE_NONE = 0, ENTRY_DISABLE_PYRAMIDDING = +1 };
input E_ENTRY_DISABLE_TYPE ENTRY_DISABLE_TYPE = ENTRY_DISABLE_NANPIN;
sinput double   STOP_BALANCE_PERCENTAGE = 99.0;
sinput int      SLIPPAGE = 10;
sinput int      MAGIC = 20220602;
sinput string   COMMENT = "Logic46";

const string    LABEL_COMMENT_FONT_NAME = "BIZ UDゴシック"; // フォント名
const color     LABEL_COMMENT_FONT_COLOR = clrYellow;// 文字色
const int       LABEL_COMMENT_FONT_SIZE = 10;  // フォントサイズ
const int       LABEL_COMMENT_LINE_SPACE = 2; // 行間
const int       LABEL_COMMENT_POSITION_X = 9; // オブジェクト群の左側スペース
const int       LABEL_COMMENT_POSITION_Y = 12;// オブジェクト群の上側スペース
const int       LABEL_COMMENT_BLOCK_SHIFT = 0;// 60文字毎のブロックの配置ズレ調整用

enum E_ORDER_TYPE {
    ORDER_BUY,
    ORDER_SELL,
    MAX_ORDER_TYPE
};

MQL45_APPLICATION_START()

// EA開始時の投資資金
double InitRemaingMargin;
double StopBalancePercentage;

double TRAILING_START;
double SL;

// エントリーシグナル
int EntrySignal;

int EntrySecond1;
int EntrySecond2;

double ExpertAdviserProfit;
double PositionLots;
datetime LastEntryDate;
int LastEntryType;
int LastEntryCount;
int LastSignal;

int FastestSignalCount;

int SIGNAL_COUNT;

bool IsWideSpread;
bool ExecutedEntry;

// 複数行コメント用のバッファー
string Comment0;
string Comment1;
string Comment2;
string Comment3;
string Comment7;
string Comment8;
string Comment9;
string CommentP;
string CommentE;
bool LabelComment_Initialized;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    InitRemaingMargin = AccountRemainingMargin();
    // StopBalancePercentage = !IsTesting() ? STOP_BALANCE_PERCENTAGE : 75;
    StopBalancePercentage = STOP_BALANCE_PERCENTAGE;

    TRAILING_START = TRAILING_STEP * TP_MULTIPLY;
    SL = TRAILING_STEP * SL_MULTIPLY;

    EntrySecond1 = PeriodSeconds(Period()) - ENTRY_PREV_SECONDS;
    EntrySecond2 = PeriodSeconds(Period());

    int signal_count = 0;
    if (PERFECT_ORDER_TYPE != PERFECT_ORDER_NONE) { ++signal_count; }
    if (SMA_BARS > 0) { ++signal_count; }
    if (FI_BARS > 0)  { ++signal_count; }
    if (ADX_BARS > 0) { ++signal_count; }
    if (TR_BARS > 0)  { ++signal_count; }
    if (CORRELATION_BARS > 0) { ++signal_count; }
    if (INCLINATION_BARS > 0) { ++signal_count; }
    SIGNAL_COUNT = FASTEST_TIMEFRANE_CHECK_PERCENTAGE * signal_count / 100;

    ExecutedEntry = false;

    LabelComment_Initialized = false;

    return INIT_SUCCEEDED;
}

double AccountRemainingMargin()
{
    return AccountBalance() + AccountCredit() + AccountProfit();
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
    // 終値エントリーする機能は無いので、ローソク足の最後の指定秒数になったらエントリーする
    long second = (long)TimeCurrent() % EntrySecond2;
    if (EntrySecond1 < second && second < EntrySecond2) {
        if (!ExecutedEntry) {
            // トレードシグナル算出
            Trade();
            EntryPosition();
            LabelComment(Comment0 + Comment9 + Comment8 + Comment7 + Comment1 + Comment2 + Comment3 + CommentE);
        }
    }
    else {
        ExecutedEntry = false;
    }
}

bool CheckWideSpread()
{
    static int list[];
    static int last_minute = -1;
    static double max_spread = 0;
    const int MAX_SPREAD_COUNT = 1440;

    int minute = 60 * TimeHour(TimeCurrent()) + TimeMinute(TimeCurrent());
    int spread = (int)MarketInfo(Symbol(), MODE_SPREAD);

    if (minute != last_minute) {
        int count = ArraySize(list);
        if (count < MAX_SPREAD_COUNT) {
            ArrayResize(list, count + 1, count);
            ++count;
        }
        ArrayCopy(list, list, 1, 0, count - 1);
        list[0] = spread;
    
        int total_value = 0;
        for (int i = 0; i < count; ++i) {
            total_value += list[i];
        }
        double average = (double)total_value / count;
    
        double total_diff = 0;
        for (int i = 0; i < count; ++i) {
            double diff = list[i] - average;
            total_diff += diff * diff;
        }
        double sd = MathSqrt(total_diff / count);
        max_spread = average + 0.5 * sd;
        last_minute = minute;
    }
    
    Comment0 += StringFormat("■スプレッド：%d / %.3f\n", spread, max_spread);
    return spread > max_spread;
}

//+------------------------------------------------------------------+
//| トレードの実行                                                   |
//+------------------------------------------------------------------+
void Trade()
{
    // 特別条件１
    // EA緊急終了 残高が投資金額の99%を下回った時
    // ex. １ロット１００万円なら９９万円を下回ったとき
    double balance_percentage = InitRemaingMargin != 0 ? 100 * AccountRemainingMargin() / InitRemaingMargin : 0;
    if (balance_percentage < StopBalancePercentage) {
        printf("EMERGENCY STOP: %.0f", AccountRemainingMargin());
        ExpertRemove();
        return;
    }

    FastestSignalCount = 0;

    datetime T = TimeCurrent();
    Comment0 = StringFormat("[%04d/%02d/%02d %02d:%02d:%02d]\n", TimeYear(T), TimeMonth(T), TimeDay(T), TimeHour(T), TimeMinute(T), TimeSeconds(T));
    Comment0 += StringFormat("■口座損益：%+.0f\n", AccountProfit());
    Comment0 += StringFormat("■口座残高：%+.0f\n", AccountBalance() + AccountCredit());

    Comment1 = Comment2 = Comment3 = Comment7 = Comment8 = Comment9 = CommentP = CommentE = "";

    IsWideSpread = CheckWideSpread();

    if (!IsWideSpread) {
        // トレーリングストップ
        TrailingStop();
    }
    else {
        // スプレッド拡大による緊急ポジションクローズ
        ClosePositionAll("Spread is too wide");
    }

    GetPositionLots();
    Comment0 += PositionLots > 0 ?
                        StringFormat("▲ロングポジション：%+.2f\n", PositionLots) :
                        (PositionLots < 0 ? StringFormat("▼ショートポジション：%+.2f\n", PositionLots) : "●ノーポジション\n");

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１（２つ前の足MA値）＜（１つ前の足MA値）・・・MAの線が右肩上がりの状態
    // 条件２現行足の始値と終値 ＞ MA　& 陽線（始値 ＜ 終値）であること
    // 条件３FI ＞ 0
    // 条件４ADX ＞ 20
    // 条件５（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
    // ＊ 上記の５条件全て揃ったら現5分足の終値で買いエントリー
    // ＊ １つのポジションが未決済でも同様の買いサインが出たらさらに10000通貨買う
    // 
    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１（２つ前の足MA値）＞（１つ前の足MA値）・・・MAの線が右肩下がりの状態
    // 条件２現行足の始値と終値 ＜ MA　& 陰線（始値 ＜ 終値）であること
    // 条件３FI ＜ 0
    // 条件４ADX ＞ 20　（ADX値は買いも売りも同条件）
    // 条件５（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
    // ＊ 上記の５条件全て揃ったら現5分足の終値で売りエントリー
    // ＊ １つのポジションが未決済でも同様の買いサインが出たらさらに10000通貨買う

    int summarySignal[MAX_ORDER_TYPE] = {};
    for (int i = MIN_TIMEFRAME - 1; i < MAX_TIMEFRAME; ++i) {
        SummarySignal(Condition(PERIOD[i],  NAME[i]), summarySignal);
    }
    int MIN_SIGNALS = (int)(0.8 * (MAX_TIMEFRAME - MIN_TIMEFRAME + 1));
    EntrySignal = ParseSignal(summarySignal, MIN_SIGNALS);

    double LossLimit = MathAbs(PositionLots) * MarketInfo(Symbol(), MODE_SPREAD) * MarketInfo(Symbol(), MODE_LOTSIZE) * (PositionLots > 0 ? Bid : Ask);
    if (PositionLots != 0 && ExpertAdviserProfit < -LossLimit) {
        // 最後にエントリーした、ロング/ショートの区別と現在のエントリーシグナルが異なればポジションクローズ
        if (EntrySignal > 0 && PositionLots < 0) {
            CommentE += "●ショートポジション含み損で買いシグナル→クローズ\n";
            ClosePositionAll("Short Position Lossed: Buy Signal");
            return;
        }
        if (EntrySignal < 0 && PositionLots > 0) {
            CommentE += "●ロングポジション含み損で売りシグナル→クローズ\n";
            ClosePositionAll("Long Position Lossed: Sell Signal");
            return;
        }
    }
}

//+------------------------------------------------------------------+
//| 全タイムフレームのパーフェクトオーダーの判定                     |
//+------------------------------------------------------------------+
int CheckPerfectOrder()
{
    double SMA[ARRAY_SIZE] = {};
    for (int i = MIN_TIMEFRAME - 1; i < MAX_TIMEFRAME; ++i) {
        SMA[i] = iMA(Symbol(), PERIOD[i], SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, 0);
    }

    int perfect_order = CheckSignalArray(SMA, 0, MAX_TIMEFRAME - MIN_TIMEFRAME + 1);

    if (SMA_SCAN_BARS > 0) {
        for (int i = MIN_TIMEFRAME - 1; i < MAX_TIMEFRAME; ++i) {
            for (int j = 0; j < SMA_SCAN_BARS; ++j) {
                SMA[j] = iMA(Symbol(), PERIOD[i], SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, j);
            }
            int signal = CheckSignalArray(SMA, perfect_order, SMA_SCAN_BARS);
            if (perfect_order != signal) {
                CommentP += "●パーフェクトオーダートレンド不一致\n";
                return 0;
            }
        }
    }

    if (perfect_order == +1) {
        CommentP += "▲パーフェクトオーダー→ロング\n";
        ++FastestSignalCount;
        return +1;
    }
    else if (perfect_order == -1) {
        CommentP += "▼パーフェクトオーダー→ショート\n";
        --FastestSignalCount;
        return -1;
    }
    CommentP += "●パーフェクトオーダートレンド交錯\n";
    return 0;
}

//+------------------------------------------------------------------+
//| シグナル配列値のトレンドの判定                                   |
//+------------------------------------------------------------------+
int CheckSignalArray(const double& value[], int signal, int count)
{
    if (count < 2) {
        return signal;
    }

    bool isLong = true;
    for (int i = 1; i < count; ++i) {
        if (value[i - 1] <= value[i]) {
            isLong = false;
            break;
        }
    }
    if (isLong) {
        return +1;
    }

    bool isShort = true;
    for (int i = 1; i < count; ++i) {
        if (value[i - 1] >= value[i]) {
            isShort = false;
            break;
        }
    }
    if (isShort) {
        return -1;
    }

    return 0;
}

//+------------------------------------------------------------------+
//| 各タイムフレームでの条件１～条件４の判定                         |
//+------------------------------------------------------------------+
int Condition(MQL45_TIMEFRAMES period, string name)
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

    int summarySignal[MAX_ORDER_TYPE] = {};
    
    int signal9 = 0;
    if (CORRELATION_BARS > 0) {
        // 条件９のチェック
        signal9 = Condition9(period, name);
    }

    int signal8 = 0;
    if (INCLINATION_BARS > 0) {
        // 条件８のチェック
        signal8 = Condition8(period, name);
    }

    int signal7 = 0;
    if (TR_BARS > 0) {
        // 条件７のチェック
        signal7 = Condition7(period, name);
    }

    int signal1 = 0;
    if (SMA_BARS > 0) {
        // 条件１のチェック
        signal1 = Condition1(period, name);
    }

    if (FI_BARS > 0) {
        // 条件２のチェック
        SummarySignal(Condition2(period, name), summarySignal);
    }

    if (ADX_BARS > 0) {
        // 条件３のチェック
        SummarySignal(Condition3(period, name), summarySignal);
    }

    int signal = ParseSignal(summarySignal, 1);

    if (CORRELATION_BARS > 0) {
        if (Sign(signal9) != Sign(signal)) {
            return signal = 0;
        }
    }

    if (INCLINATION_BARS > 0) {
        if (Sign(signal8) != Sign(signal)) {
            return signal = 0;
        }
    }
    
    if (TR_BARS > 0) {
        if (Sign(signal7) != Sign(signal)) {
            return signal = 0;
        }
    }
    
    if (SMA_BARS > 0) {
        if (Sign(signal1) != Sign(signal)) {
            return signal = 0;
        }
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| 条件９：相関係数の判定                                           |
//+------------------------------------------------------------------+
int Condition9(MQL45_TIMEFRAMES period, string name)
{
    double R = iCorrelation(Symbol(), period, CORRELATION_BARS, 0);

    if (R > +CORRELATION_MIN) {
        Comment9 += StringFormat("▲[%s]相関係数/上昇トレンド→%+.3f\n", name, R);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
        return +1;
    }
    else if (R < -CORRELATION_MIN) {
        Comment9 += StringFormat("▼[%s]相関係数/下降トレンド→%+.3f\n", name, R);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
        return -1;
    }

    Comment9 += StringFormat("●[%s]相関係数/トレンド無し→%+.3f\n", name, R);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件８：傾きによる変化率の判定                                   |
//+------------------------------------------------------------------+
int Condition8(MQL45_TIMEFRAMES period, string name)
{
    double daily_change = iInclination(Symbol(), period, INCLINATION_BARS, 0);

    if (daily_change > +INCLINATION_MIN) {
        Comment8 += StringFormat("▲[%s]傾きによる変化率/上昇トレンド→%+.3f\n", name, daily_change);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
        return +1;
    }
    else if (daily_change < -INCLINATION_MIN) {
        Comment8 += StringFormat("▼[%s]傾きによる変化率/下降トレンド→%+.3f\n", name, daily_change);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
        return -1;
    }

    Comment8 += StringFormat("●[%s]傾きによる変化率/トレンド無し→%+.3f\n", name, daily_change);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件７：ＴＲの判定                                               |
//+------------------------------------------------------------------+
int Condition7(MQL45_TIMEFRAMES period, string name)
{
    double TR[ARRAY_SIZE] = {};
    int minutes = PeriodSeconds(period) / 60;
    for (int i = 0; i < TR_SCAN_BARS; ++i) {
        TR[i] = iTR(Symbol(), period, TR_BARS, i) / minutes;
    }
    int Signal = Sign(TR[0]);
    int SignalTR = CheckSignalArray(TR, Signal, TR_SCAN_BARS);

    if (TR[0] > +TR_ENTRY && SignalTR > 0) {
        Comment7 += StringFormat("▲[%s]TR/上昇トレンド=%+.0f\n", name, TR[0]);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
        return +1;
    }
    else if (TR[0] < -TR_ENTRY && SignalTR < 0) {
        Comment7 += StringFormat("▼[%s]TR/下降トレンド=%+.0f\n", name, TR[0]);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
        return -1;
    }

    Comment7 += StringFormat("●[%s]TR/トレンド無し=%+.0f\n", name, TR[0]);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件１：ＭＡの判定                                               |
//+------------------------------------------------------------------+
int Condition1(MQL45_TIMEFRAMES period, string name)
{
    // ＭＡ　：期間＝20、移動平均の種別＝Simple、適用価格＝Close
    double MA[ARRAY_SIZE] = {};
    int bars = SMA_SCAN_BARS >= 3 ? SMA_SCAN_BARS : 3;
    for (int i = 0; i < bars; ++i) {
        MA[i] = iMA(Symbol(), period, SMA_BARS, 0, MODE_SMA, PRICE_CLOSE, i);
    }
    int signal1 = MA[2] < MA[1] ? +1 : MA[2] > MA[1] ? -1 : 0;
    int signal2 = CheckSignalArray(MA, signal1, SMA_SCAN_BARS);

    double open  = ::iOpen(Symbol(), period, 0);
    double high  = ::iHigh(Symbol(), period, 0);
    double low   = ::iLow(Symbol(), period, 0);
    double close = ::iClose(Symbol(), period, 0);

    double hige1 = MathAbs(high - MathMax(open, close));
    double hige0 = MathAbs(MathMin(open, close) - low);
    double body  = MathAbs(close - open);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＜（１つ前の足MA値）・・・MAの線が右肩上がりの状態
    if (signal1 == +1 && signal2 == +1) {
        // 条件２：現行足の始値と終値 ＞ MA　& 陽線（始値 ＜ 終値）であること
        if (open > MA[0] && close > MA[0] && open < close) {
            // 追加条件：上髭が実体よりも十分に短いこと＆上髭が下髭よりも短いこと
            if (hige1 < 0.3 * body && hige1 < hige0) {
                Comment1 += StringFormat("▲[%s]MA/MA[2]=%s/MA[1]=%s\n", name, ToString(MA[2]), ToString(MA[1]));
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
                return +1;
            }
        }
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＞（１つ前の足MA値）・・・MAの線が右肩下がりの状態
    if (signal1 == -1 && signal2 == -1) {
        // 条件２：現行足の始値と終値 ＜ MA　& 陰線（始値 ＜ 終値）であること
        if (open < MA[0] && close < MA[0] && open > close) {
            // 追加条件：下髭が実体よりも十分に短いこと＆下髭が上髭よりも短いこと
            if (hige0 < 0.3 * body && hige0 < hige1) {
                Comment1 += StringFormat("▼[%s]MA/MA[2]=%s/MA[1]=%s\n", name, ToString(MA[2]), ToString(MA[1]));
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
                return -1;
            }
        }
    }

    Comment1 += StringFormat("●[%s]MA/MA[2]=%s/MA[1]=%s\n", name, ToString(MA[2]), ToString(MA[1]));
    return 0;
}

//+------------------------------------------------------------------+
//| 条件２：ＦＩの判定                                               |
//+------------------------------------------------------------------+
int Condition2(MQL45_TIMEFRAMES period, string name)
{
    // ＦＩ　：期間＝13、 種別＝Simple、適用価格＝Close
    double FI[ARRAY_SIZE] = {};
    for (int i = 0; i < FI_SCAN_BARS; ++i) {
        FI[i] = iForce(Symbol(), period, FI_BARS, MODE_SMA, PRICE_CLOSE, i);
    }
    int signal1 = FI[0] > +FI_ENTRY ? +1 : FI[0] < -FI_ENTRY ? -1 : 0;
    int signal2 = CheckSignalArray(FI, signal1, FI_SCAN_BARS);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＞ 0
    if (signal1 == +1 && signal2 == +1) {
        Comment2 += StringFormat("▲[%s]FI/FI[0]=%+.3f/FI[1]=%+.3f\n", name, FI[0], FI[1]);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
        return +1;
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＜ 0
    if (signal1 == -1 && signal2 == -1) {
        Comment2 += StringFormat("▼[%s]FI/FI[0]=%+.3f/FI[1]=%+.3f\n", name, FI[0], FI[1]);
        if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
        return -1;
    }

    Comment2 += StringFormat("●[%s]FI/FI[0]=%+.3f/FI[1]=%+.3f\n", name, FI[0], FI[1]);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件３：ＡＤＸの判定                                             |
//+------------------------------------------------------------------+
int Condition3(MQL45_TIMEFRAMES period, string name)
{
    // ＡＤＸ：期間＝20、 適用価格＝Close
    double ADX[ARRAY_SIZE] = {};
    double PLUSDI[ARRAY_SIZE] = {};
    double MINUSDI[ARRAY_SIZE] = {};
    for (int i = 0; i < ADX_SCAN_BARS; ++i) {
        ADX[i] = iADX(Symbol(), period, ADX_BARS, PRICE_CLOSE, MODE_MAIN, i + 1);
        PLUSDI[i] = iADX(Symbol(), period, ADX_BARS, PRICE_CLOSE, MODE_PLUSDI, i + 1);
        MINUSDI[i] = iADX(Symbol(), period, ADX_BARS, PRICE_CLOSE, MODE_MINUSDI, i + 1);
    }

    // 条件４：ADX ＞ 20
    if (ADX[0] > ADX_ENTRY) {
        if (ADX_CHECK_TYPE == ADX_DI_AND_BARS) {
            int signal1 = ADX[0] > ADX[1] ? +1 : ADX[0] < ADX[1] ? -1 : 0;
            int SignalADX = CheckSignalArray(ADX, signal1, ADX_SCAN_BARS);
            int SignalPLUSDI = CheckSignalArray(PLUSDI, signal1, ADX_SCAN_BARS);
            int SignalMINUSDI = CheckSignalArray(MINUSDI, signal1, ADX_SCAN_BARS);
            if (PLUSDI[0] > MINUSDI[0] && SignalPLUSDI > 0 && SignalMINUSDI < 0 && SignalADX > 0) {
                // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
                Comment3 += StringFormat("▲[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
                return +1;
            }
            if (PLUSDI[0] < MINUSDI[0] && SignalPLUSDI < 0 && SignalMINUSDI > 0 && SignalADX < 0) {
                // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
                Comment3 += StringFormat("▼[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
                return -1;
            }
            Comment3 += StringFormat("●[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
            return 0;
        }
        else if (ADX_CHECK_TYPE == ADX_DI_ONLY) {
            int signal1 = PLUSDI[0] > MINUSDI[0] ? +1 : PLUSDI[0] < MINUSDI[0] ? -1 : 0;
            int SignalADX = CheckSignalArray(ADX, signal1, ADX_SCAN_BARS);
            int SignalPLUSDI = CheckSignalArray(PLUSDI, signal1, ADX_SCAN_BARS);
            int SignalMINUSDI = CheckSignalArray(MINUSDI, signal1, ADX_SCAN_BARS);
            if (signal1 > 0 && SignalPLUSDI > 0 && SignalMINUSDI < 0) {
                // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
                Comment3 += StringFormat("▲[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
                return +1;
            }
            if (signal1 < 0 && SignalPLUSDI < 0 && SignalMINUSDI > 0) {
                // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
                Comment3 += StringFormat("▼[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
                return -1;
            }
            Comment3 += StringFormat("●[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
            return 0;
        }
        else if (ADX_CHECK_TYPE == ADX_BARS_ONLY) {
            int signal1 = ADX[0] > ADX[1] ? +1 : ADX[0] < ADX[1] ? -1 : 0;
            int SignalADX = CheckSignalArray(ADX, signal1, ADX_SCAN_BARS);
            if (SignalADX > 0) {
                // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
                Comment3 += StringFormat("▲[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { ++FastestSignalCount; }
                return +1;
            }
            if (SignalADX < 0) {
                // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
                Comment3 += StringFormat("▼[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
                if (period == PERIOD[MIN_TIMEFRAME - 1]) { --FastestSignalCount; }
                return -1;
            }
            Comment3 += StringFormat("●[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
            return 0;
        }
    }
    
    Comment3 += StringFormat("●[%s]ADX/PLUSDI=%.3f/MINUSDI=%.3f\n", name, PLUSDI[0], MINUSDI[0]);
    return 0;
}

//+------------------------------------------------------------------+
//| 相関係数の算出                                                   |
//+------------------------------------------------------------------+
double iCorrelation(string symbol, MQL45_TIMEFRAMES timeframe, int N, int shift)
{
    double sum_y = 0;
    double sum_x = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i;
        double y = ::iOpen(symbol, timeframe, i + shift);
        sum_y += y;
        sum_x += x;
    }
    double avr_y = sum_y / N;
    double avr_x = sum_x / N;

    double sum_xy = 0;
    double sum_xx = 0;
    double sum_yy = 0;
    for (int i = 0; i < N; ++i) {
        double x = (-i) - avr_x;
        double y = ::iOpen(symbol, timeframe, i + shift) - avr_y;
        sum_xy += x * y;
        sum_xx += x * x;
        sum_yy += y * y;
    }

    double r = (sum_xx * sum_yy == 0) ? 0 : sum_xy / MathSqrt(sum_xx * sum_yy);
    return r;
}

//+------------------------------------------------------------------+
//| 傾きによる1日当たりの変化率パーセンテージの算出                  |
//+------------------------------------------------------------------+
double iInclination(string symbol, MQL45_TIMEFRAMES timeframe, int N, int shift)
{
    double sum_xy = 0;
    double sum_xx = 0;
    double sum_x = 0;
    double sum_y = 0;
    for (int i = 0; i < N; ++i) {
        double x = -i * PeriodSeconds(timeframe);
        double y = ::iOpen(symbol, timeframe, i + shift);
        sum_xx += x * x;
        sum_xy += x * y;
        sum_x += x;
        sum_y += y;
    }
    double diff_xy = N * sum_xy - sum_x * sum_y;
    double diff_xx = N * sum_xx - sum_x * sum_x;
    if (diff_xx == 0.0) { return 0.0; }
    double inclination = diff_xy / diff_xx;
    double daily_inclination = inclination * 1440 * 60;
    double daily_change = 100.0 * daily_inclination / (0.5 * (Ask + Bid));
    return daily_change;
}

//+------------------------------------------------------------------+
//| 符号付き最大値True Rangeの算出                                   |
//+------------------------------------------------------------------+
double iTR(string symbol, MQL45_TIMEFRAMES timeframe, int N, int i)
{
    double TR = 0;
    double max_abs = 0;
    for (int k = 0; k < N; ++k) {
        double high0  = ::iHigh(symbol,  timeframe, ::iHighest(symbol, timeframe, MODE_HIGH, N, k + i));
        double low0   = ::iLow(symbol,   timeframe, ::iLowest(symbol,  timeframe, MODE_LOW,  N, k + i));
        double close0 = ::iClose(symbol, timeframe, k + i);
        double close1 = ::iClose(symbol, timeframe, k + i + 1);
        double tr1 = MathAbs(high0 - low0);
        double tr2 = MathAbs(high0 - close1);
        double tr3 = MathAbs(low0 - close1);
        double tr = MathMax(MathMax(tr1, tr2), tr3) * ((close1 < close0) ? +1 : -1);
        if (MathAbs(tr) > max_abs) {
            TR = tr;
            max_abs = MathAbs(tr);
        }
    }

    return TR / Point();
}

//+------------------------------------------------------------------+
//| ポジションエントリー                                             |
//+------------------------------------------------------------------+
void EntryPosition()
{
    if (IsWideSpread) {
        CommentE += "※スプレッド拡大中：エントリー禁止";
        return;
    }

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
    // ＊ １つのポジションが未決済でも同様の買いサインが出たらさらに10000通貨売る
    if (DISABLE_DUPLICATE_ENTRY) {
        if (LastSignal > 0 && EntrySignal > 0) {
            CommentE += "※前回買いシグナル中の買いシグナル";
            return;
        }
        if (LastSignal < 0 && EntrySignal < 0) {
            CommentE += "※前回売りシグナル中の売りシグナル";
            return;
        }
    }
    if ((LastSignal < 0 && EntrySignal > 0) || (LastSignal > 0 && EntrySignal < 0)) {
        // 両建て対策のポジションクローズ
        ClosePositionAll("Avoid Cross-Trade");
    }
    LastSignal = ExecuteEntry();
}

int ExecuteEntry()
{
    int dayOfYear = TimeDayOfYear(TimeCurrent());
    if (dayOfYear < 5 || 364 < dayOfYear) {
        CommentE += "※年末年始はエントリー禁止";
        return 0;
    }

    if (FastestSignalCount <= -SIGNAL_COUNT && FastestSignalCount >= +SIGNAL_COUNT) {
        CommentE += StringFormat("●%sでシグナルが揃っていない：%+d / %d", NAME[MIN_TIMEFRAME - 1], FastestSignalCount, SIGNAL_COUNT);
        return 0; // FastestSignalCount > 0 ? +1 : FastestSignalCount < 0 ? -1 : 0;
    }
    if (EntrySignal == 0) {
        CommentE += "●シグナル無し→エントリー取り止め";
        return 0; // EntrySignal > 0 ? +1 : EntrySignal < 0 ? -1 : 0;
    }

    // 共通エントリ条件
    // 2) 最大取引通貨数30000通貨
    if (MathAbs(PositionLots / LOT) >= POSIION_MAX_COUNT) {
        CommentE += "※ポジション数オーバーエントリー取り止め";
        return EntrySignal > 0 ? +1 : EntrySignal < 0 ? -1 : 0;
    }

    if (ExecutedEntry) {
        CommentE += "※終値でエントリー済み";
        return EntrySignal > 0 ? +1 : EntrySignal < 0 ? -1 : 0;
    }

    // 前回のエントリーから指定の本数間が空いていなければ、エントリー取り止め
    if (TimeCurrent() - LastEntryDate < ENTRY_INTERVAL_BARS * PeriodSeconds(Period())) {
        CommentE += "●前回エントリーから指定時間未経過→エントリー無し";
        return EntrySignal > 0 ? +1 : EntrySignal < 0 ? -1 : 0;
    }

    if (ENTRY_DISABLE_TYPE == ENTRY_DISABLE_NANPIN) {
        if (PositionLots > 0 && ExpertAdviserProfit <= 0 && EntrySignal > 0) {
            CommentE += StringFormat("●口座損益がゼロ以下(%+.0f)→ロングエントリー無し", ExpertAdviserProfit);
            return +1;
        }
        if (PositionLots < 0 && ExpertAdviserProfit <= 0 && EntrySignal < 0) {
            CommentE += StringFormat("●口座損益がゼロ以下(%+.0f)→ショートエントリー無し", ExpertAdviserProfit);
            return -1;
        }
    }
    if (ENTRY_DISABLE_TYPE == ENTRY_DISABLE_PYRAMIDDING) {
        if (PositionLots > 0 && ExpertAdviserProfit >= 0 && EntrySignal > 0) {
            CommentE += StringFormat("●口座損益がゼロ以上(%+.0f)→ロングエントリー無し", ExpertAdviserProfit);
            return +1;
        }
        if (PositionLots < 0 && ExpertAdviserProfit >= 0 && EntrySignal < 0) {
            CommentE += StringFormat("●口座損益がゼロ以上(%+.0f)→ショートエントリー無し", ExpertAdviserProfit);
            return -1;
        }
    }

    double SL1 = ApplyTechnical(SL);

    // 保存したエントリーシグナルが買いなら、ロングエントリー
    if (EntrySignal > 0) {
        double tp = 0;
        double sl = SL1 > 0 ? NormalizeDouble(Bid - SL1 * Point(), Digits) : 0;
        color arrow = clrBlue;
        int ticket = OrderSend(Symbol(), OP_BUY, LOT, Ask, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %d", GetLastError());
        }
        CommentE += "▲ロングエントリー";
        return +1;
    }

    // 保存したエントリーシグナルが売りなら、ショートエントリー
    if (EntrySignal < 0) {
        double tp = 0;
        double sl = SL1 > 0 ? NormalizeDouble(Ask + SL1 * Point(), Digits) : 0;
        color arrow = clrRed;
        int ticket = OrderSend(Symbol(), OP_SELL, LOT, Bid, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %d", GetLastError());
        }
        CommentE += "▼ショートエントリー";
        return -1;
    }

    CommentE += "※内部エラーでエントリー無し";
    return LastSignal;
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
void ClosePositionAll(string comment)
{
    OrderCloseComment(comment);
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

    GetPositionLots();
}

//+------------------------------------------------------------------+
//| トレーリングストップ                                             |
//+------------------------------------------------------------------+
void TrailingStop()
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

        double SL1 = ApplyTechnical(SL);
        double TRAILING_START1 = ApplyTechnical(TRAILING_START);
        double TRAILING_STEP1 = ApplyTechnical(TRAILING_STEP);

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        double profit_point = profit_price / Point();
        double stoploss_price = type == OP_BUY ? price - OrderStopLoss() : OrderStopLoss() - price;
        double stoploss_point = MathMax(stoploss_price / Point(), profit_point * 0.75);
        color arrow = type == OP_BUY ? clrRed : clrBlue;
        if (TRAILING_START1 > 0 && TRAILING_STEP1 > 0) {
            if (type == OP_BUY && profit_point > TRAILING_START1) {
                double sl = NormalizeDouble(price - TRAILING_STEP1 * Point(), Digits);
                double tp = 0;
                if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            } else if (type == OP_SELL && profit_point > TRAILING_START1) {
                double sl = NormalizeDouble(price + TRAILING_STEP1 * Point(), Digits);
                double tp = 0;
                if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %d", ticket, GetLastError());
                }
            }
        }
    }
    
    GetPositionLots();
}

//+------------------------------------------------------------------+
//| ポジション数のカウント                                           |
//+------------------------------------------------------------------+
void GetPositionLots()
{
    PositionLots = 0;
    LastEntryType = 0;
    ExpertAdviserProfit = 0;
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
        if (entry_date > LastEntryDate) {
            LastEntryDate = entry_date;
        }

        LastEntryType = OrderType() == OP_BUY ? +1 : -1;
        PositionLots += LastEntryType * OrderLots();
        ExpertAdviserProfit += OrderProfit();
    }
}

double ApplyTechnical(double value)
{
    if (TRAILING_BARS > 0) {
        static double technical = 0;
        static datetime last_date = 0;
        datetime date = TimeCurrent();
        if (date > last_date) {
            technical = MathAbs(iTR(Symbol(), PERIOD[TRAILING_TIMEFRAME - 1], TRAILING_BARS, 0));
        }
        value *= technical;
    }
    return value;
}

void SummarySignal(int signal, int& summarySignal[])
{
    if (signal > 0) {
        summarySignal[ORDER_BUY] += 1;
    }
    else if (signal < 0) {
        summarySignal[ORDER_SELL] += 1;
    }
}

int ParseSignal(const int& summarySignal[], int minimumSignals)
{
    if (summarySignal[ORDER_BUY] >= minimumSignals && summarySignal[ORDER_SELL] == 0) {
        return +1;
    }
    else if (summarySignal[ORDER_SELL] >= minimumSignals && summarySignal[ORDER_BUY] == 0) {
        return -1;
    }
    return 0;
}

int Sign(double x)
{
    if (x > 0) { return +1; }
    if (x < 0) { return -1; }
    return 0;
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
}

//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
{
    double profit = TesterStatistics(STAT_PROFIT);
    double win_ratio = TesterStatistics(STAT_TRADES) > 0 ? TesterStatistics(STAT_PROFIT_TRADES) / TesterStatistics(STAT_TRADES) : 0.0;
    double draw_down = (100.0 - TesterStatistics(STAT_BALANCE_DDREL_PERCENT)) / 100.0;
    double tester_result = profit * win_ratio * draw_down;
    return tester_result;
}

//+------------------------------------------------------------------+
//| レートの文字列化                                                 |
//+------------------------------------------------------------------+
string ToString(double rate)
{
    return DoubleToString(rate, Digits);
}

//+------------------------------------------------------------------+
//| 改行で区切って処理する                                           |
//+------------------------------------------------------------------+
void LabelComment(string msg)
{
    if (IsTesting() && !IsVisualMode()) {
        return;
    }

    if (!LabelComment_Initialized) {
        LabelComment_DeleteObjects();
    }

    string lines[];
    int count = StringSplit(msg, '\n',lines);
    for (int i = 0; i < ArraySize(lines); ++i) {
        string line = i < count ? lines[i] : " ";
        LabelComment_DrawLine(i, lines[i], LABEL_COMMENT_POSITION_X, LABEL_COMMENT_POSITION_Y + i * (LABEL_COMMENT_FONT_SIZE + LABEL_COMMENT_LINE_SPACE));
    }

    LabelComment_Initialized = true;
}

//+------------------------------------------------------------------+
//| プレフィックスで始まるオブジェクトを全削除する                   |
//+------------------------------------------------------------------+
void LabelComment_DeleteObjects()
{
    for(int i = ObjectsTotal(); i >= 0; i--) {
        string objname = ObjectName(i);
        if (StringFind(objname, "{{LabelComment}}-") >= 0) {
            ObjectDelete(objname);
        }
    }
}

//+------------------------------------------------------------------+
//| 1行ごとにラベルオブジェクトを作成する                            |
//+------------------------------------------------------------------+
void LabelComment_DrawLine(int i, string line, int X, int Y)
{
    string objname = StringFormat("{{LabelComment}}-%08d", i);
    if (!LabelComment_Initialized) {
        ObjectCreate(0, objname, OBJ_LABEL, 0, 0, 0);
        if (!ObjectSetString(0, objname, OBJPROP_FONT, LABEL_COMMENT_FONT_NAME)) {
            Alert(StringFormat("ObjectSetString(): Error %d", GetLastError()));
        }
        ObjectSetInteger(0, objname, OBJPROP_FONTSIZE, LABEL_COMMENT_FONT_SIZE);
        ObjectSetInteger(0, objname, OBJPROP_COLOR, LABEL_COMMENT_FONT_COLOR);
        ObjectSetInteger(0, objname, OBJPROP_CORNER, ANCHOR_RIGHT_UPPER);
        ObjectSetInteger(0, objname, OBJPROP_XDISTANCE, X);
        ObjectSetInteger(0, objname, OBJPROP_YDISTANCE, Y);
    }
    ObjectSetString(0, objname, OBJPROP_TEXT, line);
}

MQL45_APPLICATION_END()
