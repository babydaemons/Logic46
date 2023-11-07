//+------------------------------------------------------------------+
//|                                                       iLogic.mq4 |
//|                                                     iLogix, LLC. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "iLogix, LLC."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//#define __DEBUG
//#define __MONITOR
//#define __TIMESTAMP

#ifdef __DEBUG
    #ifdef __MQL5__
        #define LOG_HEADER "[MQL5]["
    #else
        #define LOG_HEADER "[MQL4]["
    #endif
    #ifdef __MONITOR
        #import "kernel32.dll"
            void OutputDebugStringW(string message);
        #import
        #define LOGGING(message) OutputDebugStringW(LOG_HEADER + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS) + "] " + (message))
    #else // __MONITOR
        #ifdef __TIMESTAMP
            struct SYSTEMTIME {
                ushort wYear;
                ushort wMonth;
                ushort wDayOfWeek;
                ushort wDay;
                ushort wHour;
                ushort wMinute;
                ushort wSecond;
                ushort wMilliseconds;
            };
            #import "kernel32.dll"
                void GetLocalTime(SYSTEMTIME& date);
            #import
        #endif // __TIMESTAMP

        string log_path;
        int log_file;
        #define LOGGING(message) output_log(message)
        void output_log(string message) {
            FileWrite(log_file, "[" + TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS) + "] " + message);
            if (!FileSeek(log_file, 0, SEEK_END)) {
                MessageBox(StringFormat("Cannot seek log file\n%s\nErrorCode %d", log_path, GetLastError()));
                ExpertRemove();
            }
            FileFlush(log_file);
        }
    #endif
#else
    #define LOGGING(message) /*nothing*/
#endif // __DEBUG


enum ENUM_TRADE_MODE {
    TRADE_MODE_BUY, // BUY (manual judgment)
    TRADE_MODE_SELL, // SELL (manual judgment)
    TRADE_MODE_BUY_SELL, // BUY/SELL (manual judgment)
    TRADE_MODE_AUTO, // AUTO (automatic judgment with T3-RSI)
    TRADE_MODE_AUTO2 // AUTO-2 (automatic judgment with EMA40)
};

//--- input parameters
input int      LOT_COUNT_BUY = 10; // Maximum number of open positions (BUY)
input int      LOT_COUNT_SELL = 10; // Maximum Open Positions (SELL)
input double   LOTS = 0.1; // Number of lots (simple interest)
input uint     SLIPPAGE = 5; // Maximum slippage limit
input double   MAX_SPREAD = 5.5; // Spread limit
input double   COMPOUND_INTEREST = 0.0; // Compound interest function
input double   RISK = 2.0; // Maximum risk
input double   TAKE_PROFIT = 0.0; // Profit taking
input double   STOP_LOSS = 0.0; // Loss cut
input int      STOP_LOSING = 0; // Loss streak automatic stop function
input int      SKIP_ENTRY = 0; // Entry skip function
input ENUM_TRADE_MODE TRADE_MODE = TRADE_MODE_AUTO; // Trend judgment
sinput int     MAGIC = 12345678; // Magic number

#define ORDER_FAIL_RETRY_COUNT 5

enum ENUM_CLOSE_POSITION {
    CLOSE_POSITION_CHECK_TO_EXIT,
    CLOSE_POSITION_TREND_CHANGED,
    CLOSE_POSITION_TOUCHED,
    CLOSE_POSITION_TAKE_PROFIT,
    CLOSE_POSITION_STOP_LOSS,
};

int SL;
int TP;
double SMA2_High1;
double SMA2_Low2;
double EMA40_Close3;
double spread;
int position_count_buy;
int position_count_sell;
datetime t0;
datetime t1;


// No.038	④ T3-RSI.mq4（or "T3-RSI2.ex4"）（カスタムインジケーター： 添付ファイル参照 ）
// No.039	RSI_Period：2
// No.040	T3_Period：8
// No.041	T3_Curvature：0.05（ディフォルト：0.618 から変更）
class T3_RSI {
private:
    double t3Array[];
    double rsiArray[];

    double e1, e2, e3, e4, e5, e6;
    double c1, c2, c3, c4;
    double n, w1, w2, b2, b3;

    int RSI_Period;
    int T3_Period;
    double T3_Curvature;

public:
    T3_RSI(int _RSI_Period = 2, int _T3_Period = 8, double _T3_Curvature = 0.05) {
        RSI_Period = _RSI_Period;
        T3_Period = _T3_Period;
        T3_Curvature = _T3_Curvature;

        e1 = 0;
        e2 = 0;
        e3 = 0;
        e4 = 0;
        e5 = 0;
        e6 = 0;
        c1 = 0;
        c2 = 0;
        c3 = 0;
        c4 = 0;
        n = 0;
        w1 = 0;
        w2 = 0;
        b2 = 0;
        b3 = 0;

        b2 = T3_Curvature * T3_Curvature;
        b3 = b2 * T3_Curvature;
        c1 = -b3;
        c2 = (3 * (b2 + b3));
        c3 = -3 * (2 * b2 + T3_Curvature + b3);
        c4 = (1 + 3 * T3_Curvature + b3 + 3 * b2);
        n = T3_Period;

        if (n < 1) n = 1;
        n = 1 + 0.5 * (n - 1);
        w1 = 2 / (n + 1);
        w2 = 1 - w1;
    }

    void GetValue(double& rsi, double& t3) {
        rsi = iRSI(NULL, 0, T3_Period, PRICE_CLOSE, 0);

        e1 = w1 * rsi + w2 * e1;
        e2 = w1 * e1 + w2 * e2;
        e3 = w1 * e2 + w2 * e3;
        e4 = w1 * e3 + w2 * e4;
        e5 = w1 * e4 + w2 * e5;
        e6 = w1 * e5 + w2 * e6;

        t3 = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3;
    }
};
T3_RSI T3;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Trade();

    // 利益確定と損切りの単位をpipsからポイントへ変換
    SL = (int)MathRound(10 * STOP_LOSS);
    TP = (int)MathRound(10 * TAKE_PROFIT);

#ifdef __DEBUG
    #ifndef __MONITOR
        #ifdef __TIMESTAMP
            SYSTEMTIME date = {};
            GetLocalTime(date);
            log_path = StringFormat("%s-%04d.%02d.%02d-%02d%02d%02d.log",
                            WindowExpertName(), date.wYear, date.wMonth, date.wDay,
                            date.wHour, date.wMinute, date.wSecond);
        #else //  __TIMESTAMP
            log_path = StringFormat("%s.log", WindowExpertName());
        #endif

        log_file = FileOpen(log_path, FILE_WRITE | FILE_SHARE_READ | FILE_TXT | FILE_COMMON);
        if (log_file == INVALID_HANDLE) {
            MessageBox(StringFormat("Cannot write log file\n%s\nErrorCode %d", log_path, GetLastError()));
            ExpertRemove();
        }
        // MessageBox("log file:\n" + log_path);
    #endif // __MONITOR
#endif // __DEBUG

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
#ifdef __DEBUG
    FileClose(log_file);
#endif // __DEBUG
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    Trade();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    Trade();
}

//+------------------------------------------------------------------+
//| トレード結果                                                     |
//+------------------------------------------------------------------+
double OnTester() {
    return 0.0;
}

//+------------------------------------------------------------------+
//| トレード実施                                                     |
//+------------------------------------------------------------------+
void Trade() {
    t1 = TimeCurrent();

    position_count_buy = position_count_sell = 0;
    int order_count = OrdersTotal();
    for (int i = order_count - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        switch (OrderType()) {
        case OP_BUY:
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
            ++position_count_buy;
            break;
        case OP_SELL:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
            ++position_count_sell;
            break;
        }
    }

    // No.109	＊ 終値ではなく、値動きの中（ヒゲ）でMoving Averageにタッチした瞬間がエントリートリガーとなる。
    // No.110	＊「【C】⑬ トレンド判定」の方向に準じてエントリーする。
    // No.111	＊トレンドの判定方法に関しては「【A】①、②、③、④」を参照。
    int trend = JudgeTrend();
    if (trend == 0) {
        return;
    }

    // No.051	⑤ スプレッド制限：5.5
    spread = MarketInfo(Symbol(), MODE_SPREAD);
    if (spread >= 10 * MAX_SPREAD) {
        return;
    }

    //+------------------------------------------------------------------+
    //| No.022	【B】インジケーター設定                                  |
    //+------------------------------------------------------------------+
    // No.023	① Moving Average（MT4ディフォルトインジケーター）
    // No.024	期間：2
    // No.026	移動平均線の種別：Simple
    // No.025	表示移動：0
    // No.027	適用価格：High
    SMA2_High1 = iMA(Symbol(), Period(), 2, 0, MODE_SMA, PRICE_HIGH, 0);
#ifdef __MQL5__
    SMA2_High1 = (High[0] + High[1]) / 2;
#endif

    // No.028	② Moving Average（MT4ディフォルトインジケーター） ＊上記①と同じもの
    // No.029	期間：2
    // No.030	表示移動：0
    // No.031	移動平均線の種別：Simple
    // No.032	適用価格：Low
    SMA2_Low2 = iMA(Symbol(), Period(), 2, 0, MODE_SMA, PRICE_LOW, 0);
#ifdef __MQL5__
    SMA2_Low2 = (Low[0] + Low[1]) / 2;
#endif

    // No.033	③ Moving Average（MT4ディフォルトインジケーター）
    // No.034	期間：40
    // No.035	表示移動：0
    // No.036	移動平均線の種別：Exponential
    // No.037	適用価格：Close
    EMA40_Close3 = iMA(Symbol(), Period(), 40, 0, MODE_EMA, PRICE_CLOSE, 0);

    if (SMA2_High1 < SMA2_Low2) {
        LOGGING(StringFormat("SMA2 FATAL ERROR: High[%.3f] < Low[%.3f]", SMA2_High1, SMA2_Low2));
    }

    if (position_count_sell < LOT_COUNT_SELL || position_count_buy < LOT_COUNT_BUY) {
        ExitTrend(trend);
        Entry(trend);
    }

    string message = StringFormat("Buy:%+.2f, Sel: %.2f, Balance: %.2f, Profit: %.2f, Margin Level: %.2f%%",
                                    position_count_buy * LOTS,
                                    position_count_sell * LOTS,
                                    AccountInfoDouble(ACCOUNT_EQUITY),
                                    AccountInfoDouble(ACCOUNT_PROFIT),
                                    AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
    Comment(message);
}

//+------------------------------------------------------------------+
//| No.108	【E】エントリー                                          |
//+------------------------------------------------------------------+
void Entry(int trend) {
    // No.112	① BUY
    // No.113	上記【B】②のMoving Averageに価格がヒットした時にBUYエントリー。(Low)
    if (trend == +1 && position_count_buy < LOT_COUNT_BUY) {
        if (Ask <= SMA2_Low2) {
            double lots = LOTS;
            LOGGING(StringFormat("EntryLong: Ask = %.3f, Low = %.3f", Ask, SMA2_Low2));
            SafeOrderSend(lots, true);
        }
        return;
    }

    // No.114	② SELL
    // No.115	上記【B】①のMoving Averageに価格がヒットした時にSELLエントリー。(High)
    if (trend == -1 && position_count_sell < LOT_COUNT_SELL) {
        if (Bid >= SMA2_High1) {
            double lots = LOTS;
            LOGGING(StringFormat("EntryShort: Bid = %.3f, High = %.3f", Ask, SMA2_High1));
            SafeOrderSend(lots, false);
        }
        return;
    }
}

//+------------------------------------------------------------------+
//| No.001	【A】トレンド判定                                        |
//+------------------------------------------------------------------+
int JudgeTrend() {
    // No.002	① BUY（手動判定）
    // No.003	トレンド判定を「買い方向」に手動設定。
    // No.004	この状態では「BUY」だけエントリーする。
    if (TRADE_MODE == TRADE_MODE_BUY) {
        return +1;
    }

    // No.005	② SELL（手動判定）
    // No.006	トレンド判定を「売り方向」に手動設定。
    // No.007	この状態では「SELL」だけエントリーする。
    if (TRADE_MODE == TRADE_MODE_SELL) {
        return -1;
    }

    // No.008	③ BUY/SELL（手動判定）
    // No.009	トレンド判定を「買い方向」と「売り方向」に手動設定。
    // No.010	この状態では「BUY」と「SELL」の両方にエントリーするが両建ては行わない。
    // エントリー方法は上記で説明の通り、
    // ①ショートエントリー：価格が上側のMA2 (Low)にヒットした時
    // ②ロングエントリー：価格が下側のMA2 (High) にヒットした時
    // この設定においては、①と②のいずれにヒットした時もエントリーを行うものです。
    if (TRADE_MODE == TRADE_MODE_BUY_SELL) {
        if (Bid <= SMA2_Low2) {
            return -1;
        }
        if (Ask >= SMA2_High1) {
            return +1;
        }
        return 0;
    }

    // No.015-1	④ AUTO（自動判定）
    // No.012	トレンド判定を自動化する。
    // No.013	両建てにならない事を前提に、自動化されたトレンド判定に従って「SELL」も「BUY」もポジションを持つ。
    //          エントリー：「紫のMA」の上なら「LONG」だけ、下なら「SHORT」だけ。(スクリーンショット 2023-08-26 午前12.56.56.png)
    if (TRADE_MODE == TRADE_MODE_AUTO) {
        // No.016	(3) 「【B】④」のインジケーターの、「RSI」が「T3」の「上」に位置している＝『BUYエントリーのみ』
        // No.017	(4) 「【B】④」のインジケーターの、「RSI」が「T3」の「下」に位置している＝『SELLエントリーのみ』
        double rsi = 0;
        double t3 = 0;
        T3.GetValue(rsi, t3);
        if (rsi > t3) {
            if (Bid > EMA40_Close3) {
                return +1;
            }
        }
        if (rsi < t3) {
            if (Ask < EMA40_Close3) {
                return -1;
            }
        }
    }

    // No.013-1	⑤ AUTO-2（自動判定）
    // No.012	トレンド判定を自動化する。
    // No.013	両建てにならない事を前提に、自動化されたトレンド判定に従って「SELL」も「BUY」もポジションを持つ。
    //          エントリー：RSIがT3の上なら「LONG」だけ、下なら「SHORT」だけ。(スクリーンショット 2023-08-26 午前12.56.56.png)
    if (TRADE_MODE == TRADE_MODE_AUTO2) {
        // No.014	(1) 価格が、下記インジケーター「【B】③」の「上」ならアップトレンド＝『BUYエントリーのみ』
        // No.015	(2) 価格が、下記インジケーター「【B】③」の「下」ならダウントレンド＝『SELLエントリーのみ』
        if (Bid > EMA40_Close3) {
            return +1;
        }
        if (Ask < EMA40_Close3) {
            return -1;
        }
    }

    return 0;
}

//+------------------------------------------------------------------+
//| トレンド変換によりポジション決済する                             |
//+------------------------------------------------------------------+
void ExitTrend(int trend) {
    // ロングポジションポジション保有中にダウントレンドに変化：ロングポジションをクローズする
    if (position_count_buy > 0) {
        if (trend == -1) {
            ExitLong(CLOSE_POSITION_TREND_CHANGED);
        }
        else {
            ExitLong(CLOSE_POSITION_CHECK_TO_EXIT);
        }
        return;
    }
    // ショートポジションポジション保有中にダウントレンドに変化：ショートポジションをクローズする
    if (position_count_sell > 0 && trend == +1) {
        if (trend == -1) {
            ExitShort(CLOSE_POSITION_TREND_CHANGED);
        }
        else {
            ExitShort(CLOSE_POSITION_CHECK_TO_EXIT);
        }
    }
}

//+------------------------------------------------------------------+
//| ロングポジションを決済するか判断する                             |
//+------------------------------------------------------------------+
void ExitLong(ENUM_CLOSE_POSITION reason) {
    int order_count = OrdersTotal();

    for (int i = order_count - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        int ticket = OrderTicket();
        double profit = Bid - OrderOpenPrice();
        double lots = OrderLots();
        t0 = OrderOpenTime();

        // No.103-2	→今回のV1は,実践の場において,エントリー方向を『手動』で小豆に切り替えて活用します。
        // No.103-3	→例えば、ロングポジションを保有中（未決済）に、トレード方向を「Short Only」に切り替える事（つまり、ドテンのような）も日常茶飯事になります。
        // No.103-4	→そのような運用においても、正確にポジション・クローズ、そして 間髪入れないエントリー、にも対応出来ると助かります。
        if (reason == CLOSE_POSITION_TREND_CHANGED) {
            SafeOrderClose(ticket, lots, true, profit, CLOSE_POSITION_TREND_CHANGED);
            continue;
        }

        // No.118	① BUYポジションの利益確定
        // No.119	上記【B】①のMoving Averageに価格がヒットした時にポジション決済。(High)
        // No.130	① BUYポジションの損切り
        // No.131	上記【B】①のMoving Averageに価格がヒットした時にポジションを損切り。(High)
        // ⇒黒字なら「利益確定」、赤字なら「損切り」となる。
        if (Ask >= SMA2_High1) {
            SafeOrderClose(ticket, lots, true, profit, CLOSE_POSITION_TOUCHED);
            continue;
        }

        // No.122	③ 上記【C】⑧で利益確定Pipsが指定されている場合
        // No.123	指定されたPips数で利益確定される。
        if (TP != 0 && profit >= +TP) {
            SafeOrderClose(ticket, lots, true, profit, CLOSE_POSITION_TAKE_PROFIT);
            continue;
        }

        // No.134	③ 上記【C】⑨で損切りPipsが指定されている場合
        // No.135	指定されたPips数で利益確定される。
        if (SL != 0 && profit <= -SL) {
            SafeOrderClose(ticket, lots, true, profit, CLOSE_POSITION_STOP_LOSS);
            continue;
        }
    }
}

//+------------------------------------------------------------------+
//| ショートポジションを決済するか判断する                           |
//+------------------------------------------------------------------+
void ExitShort(ENUM_CLOSE_POSITION reason) {
    int order_count = OrdersTotal();

    for (int i = order_count - 1; i >= 0; --i) {
        if (!OrderSelect(i, SELECT_BY_POS)) {
            continue;
        }
        if (OrderMagicNumber() != MAGIC) {
            continue;
        }
        int ticket = OrderTicket();
        double profit = OrderOpenPrice() - Ask;
        double lots = OrderLots();
        t0 = OrderOpenTime();

        // No.103-2	→今回のV1は,実践の場において,エントリー方向を『手動』で小豆に切り替えて活用します。
        // No.103-3	→例えば、ロングポジションを保有中（未決済）に、トレード方向を「Short Only」に切り替える事（つまり、ドテンのような）も日常茶飯事になります。
        // No.103-4	→そのような運用においても、正確にポジション・クローズ、そして 間髪入れないエントリー、にも対応出来ると助かります。
        if (reason == CLOSE_POSITION_TREND_CHANGED) {
            SafeOrderClose(ticket, lots, false, profit, CLOSE_POSITION_TREND_CHANGED);
            continue;
        }

        // No.120	② SELLポジションの利益確定
        // No.121	上記【B】②のMoving Averageに価格がヒットした時にポジション決済。(Low)
        // No.132	② SELLポジションの損切り
        // No.133	上記【B】②のMoving Averageに価格がヒットした時にポジションを損切り。(Low)
        // ⇒黒字なら「利益確定」、赤字なら「損切り」となる。
        if (Bid <= SMA2_Low2) {
            SafeOrderClose(ticket, lots, false, profit, CLOSE_POSITION_TOUCHED);
            continue;
        }

        // No.122	③ 上記【C】⑧で利益確定Pipsが指定されている場合
        // No.123	指定されたPips数で利益確定される。
        if (TP != 0 && profit >= +TP) {
            SafeOrderClose(ticket, lots, false, profit, CLOSE_POSITION_TAKE_PROFIT);
            continue;
        }

        // No.134	③ 上記【C】⑨で損切りPipsが指定されている場合
        // No.135	指定されたPips数で利益確定される。
        if (SL != 0 && profit <= -SL) {
            SafeOrderClose(ticket, lots, false, profit, CLOSE_POSITION_STOP_LOSS);
            continue;
        }
    }
}

//+------------------------------------------------------------------+
//| ポジション発注をリトライありで行う                               |
//+------------------------------------------------------------------+
bool SafeOrderSend(double lots, bool buy) {
    // No.011	④ AUTO（自動判定）
    // No.012	トレンド判定を自動化する。
    // No.013	両建てにならない事を前提に、自動化されたトレンド判定に従って「SELL」も「BUY」もポジションを持つ。
    // No.103-2	→今回のV1は,実践の場において,エントリー方向を『手動』で小豆に切り替えて活用します。
    // No.103-3	→例えば、ロングポジションを保有中（未決済）に、トレード方向を「Short Only」に切り替える事（つまり、ドテンのような）も日常茶飯事になります。
    // No.103-4	→そのような運用においても、正確にポジション・クローズ、そして 間髪入れないエントリー、にも対応出来ると助かります。
    ExitTrend(buy ? +1 : -1);

    int cmd = buy ? OP_BUY : OP_SELL;
    color arrow = buy ? clrBlue : clrRed;

    for (int k = 0; k < ORDER_FAIL_RETRY_COUNT; ++k) {
        RefreshRates();
        double price = buy ? Ask : Bid;
        double sl = 0.0;
        double tp = 0.0;
        if (SL != 0) {
            sl = buy ? NormalizeDouble(Bid - SL * Point(), Digits) : NormalizeDouble(Ask + SL * Point(), Digits);
        }
        if (TP != 0) {
            tp = buy ? NormalizeDouble(Bid + TP * Point(), Digits) : NormalizeDouble(Ask - TP * Point(), Digits);
        }
        int ticket = OrderSend(Symbol(), cmd, lots, price, SLIPPAGE, sl, tp, WindowExpertName(), MAGIC, 0, arrow);
        if (ticket != -1) {
            return true;
        }
        Sleep(100 << k);
    }
    return false;
}

//+------------------------------------------------------------------+
//| ポジション決済をリトライありで行う                               |
//+------------------------------------------------------------------+
bool SafeOrderClose(int ticket, double lots, bool buy, double profit, ENUM_CLOSE_POSITION reason) {
    double price = buy ? Bid : Ask;
    LOGGING(StringFormat("%s(%s): %.3f, profit = %.3f", buy ? "ExitLong" : "ExitShort", EnumToString(reason), price, profit));

    color arrow = buy ? clrBlue : clrRed;
    for (int k = 0; k < ORDER_FAIL_RETRY_COUNT; ++k) {
        RefreshRates();
        if (OrderClose(ticket, lots, price, SLIPPAGE, arrow)) {
            return true;
        }
        Sleep(100 << k);
    }
    return false;
}

