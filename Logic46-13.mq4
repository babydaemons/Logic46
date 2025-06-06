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

#include "AutoSummerTime.mqh"
#include "ErrorDescription.mqh"

#define ARRAY_SIZE 64

//--- input parameters
input int       POSIION_MAX_COUNT = 3;      // エントリーを許容するポジションの総数
input double    LOT = 0.1;                  // エントリーするするロットサイズ

input int       MA_BARS = 20;               // MAを算出するバーの本数

input int       FI_BARS = 13;               // FIを算出するバーの本数
input double    FI_ENTRY = 0.0;             // エントリーするFIの下限値

input int       ADX_BARS = 20;              // ADXを算出するバーの本数
input double    ADX_ENTRY = 20.0;           // エントリーするADXの下限値

input int       TRAILING_STEP = 50;         // トレーリングストップ更新幅(0.1pips単位)
input double    TP_MULTIPLY = 3.0;          // トレーリングストップ更新幅(0.1pips単位)に対するTPの倍数
input int       SL_MULTIPLY = 2.0;          // トレーリングストップ更新幅(0.1pips単位)に対するSLの倍数

input int       ENTRY_PREV_SECONDS = 5;     // 終値エントリーのためのローソク足の終わりに先行する秒数
input int       ENTRY_INTERVAL_BARS = 12;   // 前回のエントリーから次のエントリーまで間隔をあけるバーの本数
enum E_ENTRY_DISABLE_TYPE {
    ENTRY_DISABLE_NONE,                     // 追加エントリー禁止なし
    ENTRY_DISABLE_NANPIN,                   // ナンピン禁止
    ENTRY_DISABLE_PYRAMIDDING               // ピラッミッディング禁止
};
input E_ENTRY_DISABLE_TYPE ENTRY_DISABLE_TYPE = ENTRY_DISABLE_NANPIN; // 追加エントリーを禁止する種別(ナンピン/ピラミッディング)
sinput double   STOP_BALANCE_PERCENTAGE = 99.0; // トレードを緊急停止する残高の割合
sinput int      SLIPPAGE = 10;              // 最大スリッページ(0.1pips単位)
sinput int      MAGIC = 20220602;           // マジックナンバー
sinput string   COMMENT = "Logic46";        // エントリー時に取引履歴に残すコメント

const string    LABEL_COMMENT_FONT_NAME = "BIZ UDゴシック"; // フォント名
const color     LABEL_COMMENT_FONT_COLOR = clrYellow;// 文字色
const int       LABEL_COMMENT_FONT_SIZE = 12;  // フォントサイズ
const int       LABEL_COMMENT_LINE_SPACE = 3; // 行間
const int       LABEL_COMMENT_POSITION_X = 9; // オブジェクト群の左側スペース
const int       LABEL_COMMENT_POSITION_Y = 12;// オブジェクト群の上側スペース
const int       LABEL_COMMENT_BLOCK_SHIFT = 0;// 60文字毎のブロックの配置ズレ調整用

const string WEEKDAYS[] = { "日", "月", "火", "水", "木", "金", "土" };

MQL45_APPLICATION_START()

// EA開始時の投資資金
double InitRemaingMargin;

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
    if (IsVisualMode()) {
        LabelComment_DeleteObjects();
    }

    InitRemaingMargin = AccountRemainingMargin();

    TRAILING_START = TRAILING_STEP * TP_MULTIPLY;
    SL = TRAILING_STEP * SL_MULTIPLY;

    EntrySecond1 = PeriodSeconds(Period()) - ENTRY_PREV_SECONDS;
    EntrySecond2 = PeriodSeconds(Period());

    int signal_count = 0;
    if (MA_BARS > 0)  { ++signal_count; }
    if (FI_BARS > 0)  { ++signal_count; }
    if (ADX_BARS > 0) { ++signal_count; }
    SIGNAL_COUNT = signal_count;

    ExecutedEntry = false;

    LabelComment_Initialized = false;

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| 有効証拠金を返す                                                 |
//+------------------------------------------------------------------+
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

//+------------------------------------------------------------------+
//| スプレッドによる統計的トレード可否チェック(Tick Data Suite環境用)|
//+------------------------------------------------------------------+
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
    if (balance_percentage < STOP_BALANCE_PERCENTAGE) {
        printf("EMERGENCY STOP: %.0f", AccountRemainingMargin());
        ExpertRemove();
        return;
    }

    FastestSignalCount = 0;

    datetime T = AutoSummerTime::TimeCurrent();
    Comment0 =  StringFormat("[サーバー時間：%04d/%02d/%02d(%s) %02d:%02d:%02d]\n", TimeYear(T), TimeMonth(T), TimeDay(T), WEEKDAYS[TimeDayOfWeek(T)], TimeHour(T), TimeMinute(T), TimeSeconds(T));
    T = AutoSummerTime::TimeLocal();
    Comment0 += StringFormat("[日本時間　　：%04d/%02d/%02d(%s) %02d:%02d:%02d]\n", TimeYear(T), TimeMonth(T), TimeDay(T), WEEKDAYS[TimeDayOfWeek(T)], TimeHour(T), TimeMinute(T), TimeSeconds(T));
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

    EntrySignal = Condition(Period(), "M05");

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
//| 条件１～条件３の判定                                             |
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

    int signal1 = 0;
    if (MA_BARS > 0) {
        // 条件１のチェック
        signal1 = Condition1(period, name);
    }

    int signal2 = 0;
    if (FI_BARS > 0) {
        // 条件２のチェック
        signal2 = Condition2(period, name);
    }

    int signal3 = 0;
    if (ADX_BARS > 0) {
        // 条件３のチェック
        signal3 = Condition3(period, name);
    }

    // 条件１・条件２・条件３が完全一致ならばエントリーする
    if (Sign(signal1) == Sign(signal2) && Sign(signal1) == Sign(signal3)) {
        return signal1;
    }

    // そうでなければ、エントリーなし
    return 0;
}

//+------------------------------------------------------------------+
//| 条件１：ＭＡの判定                                               |
//+------------------------------------------------------------------+
int Condition1(MQL45_TIMEFRAMES period, string name)
{
    // ＭＡ　：期間＝20、移動平均の種別＝Simple、適用価格＝Close
    double MA[ARRAY_SIZE] = {};
    for (int i = 0; i < 3; ++i) {
        MA[i] = iMA(Symbol(), period, MA_BARS, 0, MODE_SMA, PRICE_CLOSE, i);
    }
    int signal1 = MA[2] < MA[1] ? +1 : MA[2] > MA[1] ? -1 : 0;

    double open  = ::iOpen(Symbol(), period, 0);
    double close = ::iClose(Symbol(), period, 0);

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＜（１つ前の足MA値）・・・MAの線が右肩上がりの状態
    if (signal1 == +1) {
        // 条件２：現行足の始値と終値 ＞ MA　& 陽線（始値 ＜ 終値）であること
        if (open > MA[0] && close > MA[0] && open < close) {
            Comment1 += StringFormat("▲[%s]MA/MA[2]=%s/MA[1]=%s\n", name, ToString(MA[2]), ToString(MA[1]));
            return +1;
        }
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件１：（２つ前の足MA値）＞（１つ前の足MA値）・・・MAの線が右肩下がりの状態
    if (signal1 == -1) {
        // 条件２：現行足の始値と終値 ＜ MA　& 陰線（始値 ＜ 終値）であること
        if (open < MA[0] && close < MA[0] && open > close) {
            Comment1 += StringFormat("▼[%s]MA/MA[2]=%s/MA[1]=%s\n", name, ToString(MA[2]), ToString(MA[1]));
            return -1;
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
    for (int i = 0; i < 1; ++i) {
        FI[i] = iForce(Symbol(), period, FI_BARS, MODE_SMA, PRICE_CLOSE, i);
    }
    int signal1 = FI[0] > +FI_ENTRY ? +1 : FI[0] < -FI_ENTRY ? -1 : 0;

    // 買いエントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＞ 0
    if (signal1 == +1) {
        Comment2 += StringFormat("▲[%s]FI/FI[0]=%+.3f\n", name, FI[0]);
        return +1;
    }

    // 売エントリー条件: 以下の全ての条件が初めて発生したとき
    // 条件３：FI ＜ 0
    if (signal1 == -1) {
        Comment2 += StringFormat("▼[%s]FI/FI[0]=%+.3f\n", name, FI[0]);
        return -1;
    }

    Comment2 += StringFormat("●[%s]FI/FI[0]=%+.3f\n", name, FI[0]);
    return 0;
}

//+------------------------------------------------------------------+
//| 条件３：ＡＤＸの判定                                             |
//+------------------------------------------------------------------+
int Condition3(MQL45_TIMEFRAMES period, string name)
{
    // ＡＤＸ：期間＝20、 適用価格＝Close
    double ADX[ARRAY_SIZE] = {};
    for (int i = 0; i < 2; ++i) {
        ADX[i] = iADX(Symbol(), period, ADX_BARS, PRICE_CLOSE, MODE_MAIN, i + 1);
    }

    // 条件４：ADX ＞ 20
    if (ADX[0] > ADX_ENTRY) {
        int signal1 = ADX[0] > ADX[1] ? +1 : ADX[0] < ADX[1] ? -1 : 0;
        if (signal1 > 0) {
            // 条件５：（２つ前の足ADX値）＝＜（１つ前の足ADX値）・・・ADXの線が右肩上がりの状態
            Comment3 += StringFormat("▲[%s]ADX/ADX[0]=%.3f/ADX[1]=%.3f\n", name, ADX[0], ADX[1]);
            return +1;
        }
        if (signal1 < 0) {
            // 条件５：（２つ前の足ADX値）＝＞（１つ前の足ADX値）・・・ADXの線が右肩下がりの状態
            Comment3 += StringFormat("▼[%s]ADX/ADX[0]=%.3f/ADX[1]=%.3f\n", name, ADX[0], ADX[1]);
            return -1;
        }
        Comment3 += StringFormat("●[%s]ADX/ADX[0]=%.3f/ADX[1]=%.3f\n", name, ADX[0], ADX[1]);
        return 0;
    }
    
    Comment3 += StringFormat("●[%s]ADX/ADX[0]=%.3f/ADX[1]=%.3f\n", name, ADX[0], ADX[1]);
    return 0;
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
    if ((LastSignal < 0 && EntrySignal > 0) || (LastSignal > 0 && EntrySignal < 0)) {
        // 両建て対策のポジションクローズ
        ClosePositionAll("Avoid Cross-Trade");
    }
    LastSignal = ExecuteEntry();
}

//+------------------------------------------------------------------+
//| エントリーの実行                                                 |
//+------------------------------------------------------------------+
int ExecuteEntry()
{
    datetime T0 = AutoSummerTime::TimeCurrent();
    int dayOfYear = TimeDayOfYear(T0);
    if (dayOfYear < 5 || 364 < dayOfYear) {
        CommentE += "※年末年始はエントリー禁止";
        return 0;
    }

    // 共通エントリ条件
    // 1) 月曜日９時から土曜日の朝６時であること
    datetime T1 = AutoSummerTime::TimeLocal();
    datetime secondOfWeek  = AutoSummerTime::TimeSecondOfWeek(TimeDayOfWeek(T1), TimeHour(T1), TimeMinute(T1), TimeSeconds(T1));
    datetime secondOfWeek1 = AutoSummerTime::TimeSecondOfWeek(1, 9, 00, 00);
    int wday = TimeDayOfWeek(secondOfWeek);
    if (secondOfWeek < secondOfWeek1) {
        CommentE += StringFormat("※週の始め(%s)はエントリー禁止", WEEKDAYS[wday]);
        return 0;
    }
    datetime secondOfWeek2 = AutoSummerTime::TimeSecondOfWeek(6, 6, 00, 00);
    if (secondOfWeek2 < secondOfWeek) {
        CommentE += StringFormat("※週の終わり(%s)はエントリー禁止", WEEKDAYS[wday]);
        return 0;
    }

    if (EntrySignal == 0) {
        CommentE += "●シグナル無し→エントリー取り止め";
        return 0;
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

    // 保存したエントリーシグナルが買いなら、ロングエントリー
    if (EntrySignal > 0) {
        double tp = 0;
        double sl = SL > 0 ? NormalizeDouble(Bid - SL * Point(), Digits) : 0;
        color arrow = clrBlue;
        int ticket = OrderSend(Symbol(), OP_BUY, LOT, Ask, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %s", ErrorDescription());
        }
        CommentE += "▲ロングエントリー";
        return +1;
    }

    // 保存したエントリーシグナルが売りなら、ショートエントリー
    if (EntrySignal < 0) {
        double tp = 0;
        double sl = SL > 0 ? NormalizeDouble(Ask + SL * Point(), Digits) : 0;
        color arrow = clrRed;
        int ticket = OrderSend(Symbol(), OP_SELL, LOT, Bid, SLIPPAGE, sl, tp, COMMENT, MAGIC, 0, arrow);
        if (ticket == -1) {
            printf("ERROR: OrderSend() FAILED: %s", ErrorDescription());
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
            printf("ERROR: OrderClose(#%d) FAILED: %s", ticket, ErrorDescription());
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

        int ticket = OrderTicket();
        int type = OrderType();
        double entry = OrderOpenPrice();
        double price = type == OP_BUY ? Bid : Ask;
        double profit_price = type == OP_BUY ? price - entry : entry - price;
        double profit_point = profit_price / Point();
        color arrow = type == OP_BUY ? clrBlue : clrRed;
        if (TRAILING_START > 0 && TRAILING_STEP > 0) {
            if (type == OP_BUY && profit_point > TRAILING_START) {
                double sl = NormalizeDouble(price - TRAILING_STEP * Point(), Digits);
                double tp = 0;
                if (sl > OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %s", ticket, ErrorDescription());
                }
            } else if (type == OP_SELL && profit_point > TRAILING_START) {
                double sl = NormalizeDouble(price + TRAILING_STEP * Point(), Digits);
                double tp = 0;
                if (sl < OrderStopLoss() && !OrderModify(ticket, price, sl, tp, 0, arrow)) {
                    printf("ERROR: OrderModify(#%d) FAILED: %s", ticket, ErrorDescription());
                }
            }
        }
    }
    
    // ポジションが閉じられた可能性があるので、カウントしなおす
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

//+------------------------------------------------------------------+
//| 符号を返す                                                       |
//+------------------------------------------------------------------+
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
            Alert(StringFormat("ObjectSetString(): ERROR %s", ErrorDescription()));
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
